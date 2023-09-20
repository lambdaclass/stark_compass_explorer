defmodule StarknetExplorer.Calldata do
  alias StarknetExplorer.Rpc

  @implementation_selectors [
    "0x3a0ed1f62da1d3048614c2c1feb566f041c8467eb00fb8294776a9179dc1643",
    "0x1d15dd5e6cac14c959221a0b45927b113a91fcfffa4c7bbab19b28d345467df",
    "0x1f01da52d973fb13ba47dbc8e4ca94015dc4e581e2cc20b2050e87b0a743fae"
  ]

  def parse_calldata(%{type: "INVOKE"} = tx, block_id, network) do
    version =
      case tx.contract do
        nil -> nil
        contract -> contract["contract_class_version"]
      end

    calldata =
      from_plain_calldata(tx.calldata, version)

    Enum.map(
      calldata,
      fn call ->
        input = get_input_data(block_id, call.address, call.selector, network)
        Map.put(call, :call, as_fn_call(input, call.calldata))
      end
    )
  end

  def parse_calldata(_tx, _block_id, _network) do
    nil
  end

  def from_plain_calldata([array_len | rest], nil) do
    {calls, [_calldata_length | calldata]} =
      List.foldl(
        Enum.to_list(1..felt_to_int(array_len)),
        {[], rest},
        fn _, {acc_current, acc_rest} ->
          {new, new_rest} = get_call_header_v0(acc_rest)
          {[new | acc_current], new_rest}
        end
      )

    Enum.map(
      Enum.reverse(calls),
      fn call ->
        %{call | :calldata => Enum.slice(calldata, call.data_offset, call.data_len)}
      end
    )
  end

  # we assume contract_class_version 0.1.0
  def from_plain_calldata([array_len | rest], _contract_class_version) do
    {calls, _} =
      List.foldl(
        Enum.to_list(1..felt_to_int(array_len)),
        {[], rest},
        fn _, {acc_current, acc_rest} ->
          {new, new_rest} = get_call_header_v1(acc_rest)
          {[new | acc_current], new_rest}
        end
      )

    Enum.reverse(calls)
  end

  def get_call_header_v0([to, selector, data_offset, data_len | rest]) do
    {%{
       :address => to,
       :selector => selector,
       :data_offset => felt_to_int(data_offset),
       :data_len => felt_to_int(data_len),
       :calldata => []
     }, rest}
  end

  def get_call_header_v1([to, selector, data_len | rest]) do
    data_length = felt_to_int(data_len)
    {calldata, rest} = Enum.split(rest, data_length)

    {%{
       :address => to,
       :selector => selector,
       :data_len => felt_to_int(data_len),
       :calldata => calldata
     }, rest}
  end

  def keccak(value) do
    <<_::6, result::250>> = ExKeccak.hash_256(value)
    ("0x" <> Integer.to_string(result, 16)) |> String.downcase()
  end

  def as_fn_call(nil, _calldata) do
    nil
  end

  def as_fn_call(input, calldata) do
    %{:name => input["name"], :args => as_fn_inputs(input["inputs"], calldata)}
  end

  def as_fn_inputs(inputs, calldata) do
    {result, _} =
      List.foldl(
        inputs,
        {[], calldata},
        fn input, {so_far, acc_calldata} ->
          {fn_input, calldata_rest} = as_fn_input(input, so_far, acc_calldata)
          {[fn_input | so_far], calldata_rest}
        end
      )

    Enum.reverse(result)
  end

  def as_fn_input(input, so_far, calldata) do
    {value, calldata_rest} = get_value_for_type(input, so_far, calldata)
    {%{:name => input["name"], :type => input["type"], :value => value}, calldata_rest}
  end

  def get_value_for_type(%{"type" => "core::array::Array::<" <> inner_type}, _so_far, [
        array_length | rest
      ]) do
    inner_type = String.replace_suffix(inner_type, ">", "") |> IO.inspect()
    get_multiple_values_for_type(felt_to_int(array_length), inner_type, rest)
  end

  def get_value_for_type(%{"type" => type, "name" => name}, so_far, calldata) do
    case String.ends_with?(type, "*") do
      true ->
        type = String.replace_suffix(type, "*", "!")
        get_multiple_values_for_type(get_array_len(name, so_far), type, calldata)

      _ ->
        get_value_for_single_type(type, calldata)
    end
  end

  def get_value_for_single_type("Uint256", [value1, value2 | rest]) do
    {[value2, value1], rest}
  end

  def get_value_for_single_type("core::integer::u256", [value1, value2 | rest]) do
    {[value2, value1], rest}
  end

  def get_value_for_single_type(_, [value | rest]) do
    {value, rest}
  end

  def get_multiple_values_for_type(0, _type, list) do
    {[], list}
  end

  def get_multiple_values_for_type(n, type, list) do
    {value, rest} = get_value_for_single_type(type, list)
    {values, final_rest} = get_multiple_values_for_type(n - 1, type, rest)
    {[value | values], final_rest}
  end

  def get_array_len(name, input_data) do
    Enum.find(
      input_data,
      fn %{:name => input_name} ->
        name <> "_len" == input_name
      end
    )
    |> Map.get(:value)
    |> felt_to_int
  end

  def felt_to_int(<<"0x", hexa_value::binary>>) do
    {value, _} = Integer.parse(hexa_value, 16)
    value
  end

  def get_input_data(block_id, address, selector, network) do
    case Rpc.get_class_at(block_id, address, network) do
      {:ok, class} ->
        selectors = parse_class(class)

        implementation_selector =
          Enum.find(
            @implementation_selectors,
            fn elem ->
              MapSet.member?(selectors, elem)
            end
          )

        case implementation_selector do
          nil ->
            find_by_selector(class, selector)

          _ ->
            {:ok, [implementation_address_or_hash]} =
              Rpc.call(block_id, address, implementation_selector, network)

            case Rpc.get_class(block_id, implementation_address_or_hash, network) do
              {:ok, class} ->
                find_by_selector(class, selector)

              {:error, _error} ->
                {:ok, class} = Rpc.get_class_at(block_id, implementation_address_or_hash, network)
                find_by_selector(class, selector)
            end
        end

      {:error, error} ->
        error |> IO.inspect()
        nil
    end
  end

  def parse_class(class) do
    List.foldl(
      class["entry_points_by_type"]["EXTERNAL"],
      MapSet.new(),
      fn elem, acc ->
        MapSet.put(acc, elem["selector"])
      end
    )
  end

  def get_input_data_for_hash(block_id, class_hash, selector, network) do
    case Rpc.get_class(block_id, class_hash, network) do
      {:ok, class} ->
        find_by_selector(class, selector)

      {:error, error} ->
        error |> IO.inspect()
        nil
    end
  end

  def find_by_selector(class, selector) do
    abi =
      case class["abi"] do
        abi when is_binary(abi) ->
          Jason.decode!(abi)

        abi ->
          abi
      end

    find_by_selector_and_version(abi, class["contract_class_version"], selector)
  end

  def find_by_selector_and_version(abi, nil, selector) do
    Enum.find(
      abi,
      fn elem ->
        elem["name"] |> keccak() == selector
      end
    )
  end

  # we assume contract_class_version 0.1.0
  def find_by_selector_and_version(abi, _contract_class_version, selector) do
    abi
    |> Enum.map(& &1["items"])
    |> Enum.filter(& &1)
    |> Enum.concat()
    |> Enum.find(&(&1["name"] |> keccak() == selector))
  end
end
