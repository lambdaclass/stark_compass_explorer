defmodule StarknetExplorer.Calldata do
  alias StarknetExplorer.Rpc

  @implementation_selectors [
    "0x3a0ed1f62da1d3048614c2c1feb566f041c8467eb00fb8294776a9179dc1643",
    "0x1d15dd5e6cac14c959221a0b45927b113a91fcfffa4c7bbab19b28d345467df",
    "0x1f01da52d973fb13ba47dbc8e4ca94015dc4e581e2cc20b2050e87b0a743fae",
    "0x21691762da057c1b71f851f9b709e0c143628acf6e0cbc9735411a65663d747"
  ]

  def parse_calldata(%{type: "INVOKE"} = tx, block_id, network) do
    calldata =
      from_plain_calldata(tx.calldata, tx.version)

    Enum.map(
      calldata,
      fn call ->
        functions_data = get_functions_data(block_id, call.address, network)
        {function, structs} = get_input_data(functions_data, call.selector)

        Map.put(call, :call, as_fn_call(function, call.calldata, structs))
      end
    )
  end

  def parse_calldata(_tx, _block_id, _network) do
    nil
  end

  def from_plain_calldata([array_len | rest], "0x0") do
    {calls, [_calldata_length | calldata]} =
      List.foldl(
        Enum.to_list(1..felt_to_int(array_len)),
        {[], rest},
        fn _, {acc_current, acc_rest} ->
          {new, new_rest} = get_call_header_v0(acc_rest)
          {[new | acc_current], new_rest}
        end
      )

    calls
    |> Enum.reverse()
    |> Enum.map(fn call ->
      %{call | :calldata => Enum.slice(calldata, call.data_offset, call.data_len)}
    end)
  end

  def from_plain_calldata([array_len | rest], "0x1") do
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

  def as_fn_call(nil, _calldata, _structs) do
    nil
  end

  def as_fn_call(function, calldata, structs) do
    {inputs, _} = as_fn_inputs(function["inputs"], calldata, structs)
    %{:name => function["name"], :args => inputs}
  end

  def as_fn_inputs(inputs, calldata, structs) do
    {result, rest} =
      List.foldl(
        inputs,
        {[], calldata},
        fn input, {so_far, acc_calldata} ->
          {fn_input, calldata_rest} = as_fn_input(input, so_far, acc_calldata, structs)
          {[fn_input | so_far], calldata_rest}
        end
      )

    {Enum.reverse(result), rest}
  end

  def as_fn_input(input, so_far, calldata, structs) do
    {value, calldata_rest} = get_value_for_type(input, so_far, calldata, structs)
    {%{:name => input["name"], :type => input["type"], :value => value}, calldata_rest}
  end

  def get_value_for_type(
        %{"type" => "core::array::Array::<" <> inner_type},
        _so_far,
        [
          array_length | rest
        ],
        structs
      ) do
    inner_type = String.replace_suffix(inner_type, ">", "")
    get_multiple_values_for_type(felt_to_int(array_length), inner_type, rest, structs)
  end

  def get_value_for_type(%{"type" => type, "name" => name}, so_far, calldata, structs) do
    case String.ends_with?(type, "*") do
      true ->
        type = String.replace_suffix(type, "*", "")
        get_multiple_values_for_type(get_array_len(name, so_far), type, calldata, structs)

      _ ->
        get_value_for_single_type(type, calldata, structs)
    end
  end

  def get_value_for_single_type("Uint256", [value1, value2 | rest], _structs) do
    {[value2, value1], rest}
  end

  def get_value_for_single_type("core::integer::u256", [value1, value2 | rest], _structs) do
    {[value2, value1], rest}
  end

  def get_value_for_single_type(type, [value | rest], structs) do
    case Map.get(structs, type) do
      nil ->
        {value, rest}

      %{"members" => members} ->
        get_value_for_complex_type(members, [value | rest], structs)
    end
  end

  def get_multiple_values_for_type(0, _type, list, _structs) do
    {[], list}
  end

  def get_multiple_values_for_type(n, type, list, structs) do
    {value, rest} = get_value_for_single_type(type, list, structs)
    {values, final_rest} = get_multiple_values_for_type(n - 1, type, rest, structs)
    {[value | values], final_rest}
  end

  def get_value_for_complex_type(members, list, structs) do
    as_fn_inputs(members, list, structs)
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

  def get_functions_data(block_id, address, network) do
    case Rpc.get_class_at(block_id, address, network) do
      {:ok, class} ->
        selectors = get_selectors(class)

        implementation_selector =
          Enum.find(
            @implementation_selectors,
            fn elem ->
              MapSet.member?(selectors, elem)
            end
          )

        implementation_data =
          case implementation_selector do
            nil ->
              nil

            _ ->
              {:ok, [implementation_address_or_hash]} =
                Rpc.call(block_id, address, implementation_selector, network)

              case Rpc.get_class(block_id, implementation_address_or_hash, network) do
                {:ok, class} ->
                  process_class_data(class, implementation_address_or_hash, :hash)

                {:error, _error} ->
                  {:ok, class} =
                    Rpc.get_class_at(block_id, implementation_address_or_hash, network)

                  process_class_data(class, implementation_address_or_hash, :address)
              end
          end

        %{
          :main => process_class_data(class, address, :address),
          :implementation => implementation_data
        }

      {:error, error} ->
        error |> IO.inspect()
        nil
    end
  end

  def process_class_data(class, id, id_type) do
    class = normalize_abi(class)
    {functions, structs} = functions_by_selector(class)

    %{
      :id => id,
      :id_type => id_type,
      :class => class,
      :functions_by_selector => functions,
      :structs_by_name => structs
    }
  end

  def get_input_data(functions_data, selector) do
    {functions, structs} =
      case functions_data.implementation do
        nil ->
          {functions_data.main.functions_by_selector, functions_data.main.structs_by_name}

        implementation ->
          {implementation.functions_by_selector, implementation.structs_by_name}
      end

    {functions[selector], structs}
  end

  def get_selectors(class) do
    List.foldl(
      class["entry_points_by_type"]["EXTERNAL"],
      MapSet.new(),
      fn elem, acc ->
        MapSet.put(acc, elem["selector"])
      end
    )
  end

  def functions_by_selector(class) do
    functions_by_selector_and_version(class.abi, class["contract_class_version"])
  end

  def functions_by_selector_and_version(abi, nil) do
    abi
    |> List.foldl(
      {%{}, %{}},
      fn
        elem = %{"type" => "function"}, {fn_acc, struct_acc} ->
          {Map.put(fn_acc, elem["name"] |> keccak(), elem), struct_acc}

        elem = %{"type" => "struct"}, {fn_acc, struct_acc} ->
          {fn_acc, Map.put(struct_acc, elem["name"], elem)}

        _elem, {fn_acc, struct_acc} ->
          {fn_acc, struct_acc}
      end
    )
  end

  # we assume contract_class_version 0.1.0
  def functions_by_selector_and_version(abi, _contract_class_version) do
    abi
    |> List.foldl(
      {%{}, %{}},
      fn
        elem = %{"type" => "interface"}, {fn_acc, struct_acc} ->
          {List.foldl(elem["items"], fn_acc, &Map.put(&2, &1["name"] |> keccak(), &1)),
           struct_acc}

        elem = %{"type" => "struct"}, {fn_acc, struct_acc} ->
          {fn_acc, Map.put(struct_acc, elem["name"], elem)}

        _elem, {fn_acc, struct_acc} ->
          {fn_acc, struct_acc}
      end
    )
  end

  def normalize_abi(class) do
    abi =
      case class["abi"] do
        abi when is_binary(abi) ->
          Jason.decode!(abi)

        abi ->
          abi
      end

    class
    |> Map.delete("abi")
    |> Map.put(:abi, abi)
  end
end
