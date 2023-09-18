defmodule StarknetExplorer.Calldata do
  alias StarknetExplorer.Rpc

  @implementation_selector "0x3a0ed1f62da1d3048614c2c1feb566f041c8467eb00fb8294776a9179dc1643"
  @implementation_hash_selector "0x1d15dd5e6cac14c959221a0b45927b113a91fcfffa4c7bbab19b28d345467df"

  def parse_calldata(%{type: "INVOKE"} = tx, block_id, network) do
    version =
      case tx.contract do
        nil -> nil
        contract -> contract[:contract_class_version]
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
        fn input, {acc_current, acc_calldata} ->
          {fn_input, calldata_rest} = as_fn_input(input, acc_calldata)
          {[fn_input | acc_current], calldata_rest}
        end
      )

    Enum.reverse(result)
  end

  def as_fn_input(input, calldata) do
    {value, calldata_rest} = get_value_for_type(input["type"], calldata)
    {%{:name => input["name"], :type => input["type"], :value => value}, calldata_rest}
  end

  def get_value_for_type("Uint256", [value1, value2 | rest]) do
    {[value2, value1], rest}
  end

  def get_value_for_type(_, [value | rest]) do
    {value, rest}
  end

  def felt_to_int(<<"0x", hexa_value::binary>>) do
    {value, _} = Integer.parse(hexa_value, 16)
    value
  end

  def get_input_data(block_id, address, selector, network) do
    case Rpc.get_class_at(block_id, address, network) do
      {:ok, class} ->
        cond do
          has_selector?(class, @implementation_selector) ->
            {:ok, [implementation_address]} =
              Rpc.call(block_id, address, @implementation_selector, network)

            get_input_data(block_id, implementation_address, selector, network)

          has_selector?(class, @implementation_hash_selector) ->
            {:ok, [implementation_hash]} =
              Rpc.call(block_id, address, @implementation_hash_selector, network)

            get_input_data_for_hash(block_id, implementation_hash, selector, network)

          true ->
            find_by_selector(class, selector)
        end

      {:error, error} ->
        error |> IO.inspect()
        nil
    end
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
    Enum.find(
      abi,
      fn elem ->
        elem["name"] |> keccak() == selector
      end
    )
  end

  def has_selector?(class, selector) do
    Enum.any?(
      class["entry_points_by_type"]["EXTERNAL"],
      fn elem ->
        elem["selector"] == selector
      end
    )
  end
end
