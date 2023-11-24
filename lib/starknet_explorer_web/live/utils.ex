defmodule StarknetExplorerWeb.Utils do
  require Logger
  alias StarknetExplorer.DateUtils
  use StarknetExplorerWeb, :verified_routes

  def hex_to_integer(hex_value) do
    hex_value
    |> String.trim_leading("0x")
    |> String.to_integer(16)
  end

  def shorten_block_hash(nil), do: ""

  def shorten_block_hash(block_hash) do
    case String.length(block_hash) do
      n when n < 6 -> block_hash
      _ -> "#{String.slice(block_hash, 0, 6)}...#{String.slice(block_hash, -4, 4)}"
    end
  end

  def get_block_age(%{timestamp: timestamp}) do
    get_block_age_from_timestamp(timestamp)
  end

  def get_block_age(%{"timestamp" => timestamp}) do
    get_block_age_from_timestamp(timestamp)
  end

  def get_block_age_from_timestamp(nil), do: ""

  def get_block_age_from_timestamp(timestamp) do
    %{minutes: minutes, hours: hours, days: days} = DateUtils.calculate_time_difference(timestamp)

    case days do
      0 ->
        case hours do
          0 -> "#{minutes} min"
          _ -> "#{hours} h"
        end

      _ ->
        "#{days} d"
    end
  end

  # 1 eth = 10^18 wei
  @wei_to_eth_constant Decimal.new("1.0E+18")
  def hex_wei_to_eth(<<"0x", wei_base_16::binary>>) do
    wei_base_16
    |> String.to_integer(16)
    |> Decimal.new()
    |> Decimal.div(@wei_to_eth_constant)
    |> Decimal.to_string(:normal)
    |> String.trim_trailing("0")
    |> String.replace_suffix(".", ".0")
  end

  def hex_wei_to_eth("0") do
    "0.0"
  end

  def hex_wei_to_eth(_) do
    "-"
  end

  def atomize_keys(map) when is_map(map) do
    map
    |> Map.new(fn
      {key, val} when is_binary(key) -> {String.to_atom(key), atomize_keys(val)}
      # Default case for atoms
      {key, val} when is_atom(key) -> {key, val}
    end)
  end

  def atomize_keys(list) when is_list(list) do
    list
    |> Enum.map(fn list_elem -> atomize_keys(list_elem) end)
  end

  def atomize_keys(not_a_map), do: not_a_map

  def format_arg_value(%{:type => "felt", :value => value}) do
    value
  end

  def format_arg_value(%{:type => "core::felt252", :value => value}) do
    value
  end

  def format_arg_value(%{
        :type => "core::starknet::contract_address::ContractAddress",
        :value => value
      }) do
    value
  end

  def format_arg_value(%{
        :type => "Uint256",
        :value => [<<"0x", high::binary>>, <<"0x", low::binary>>]
      }) do
    "0x" <>
      ((String.to_integer(high, 16) * 2 ** 252 + String.to_integer(low, 16))
       |> Integer.to_string(16)
       |> String.downcase())
  end

  def format_arg_value(%{
        :type => "core::integer::u256",
        :value => [<<"0x", high::binary>>, <<"0x", low::binary>>]
      }) do
    "0x" <>
      ((String.to_integer(high, 16) * 2 ** 252 + String.to_integer(low, 16))
       |> Integer.to_string(16)
       |> String.downcase())
  end

  def format_arg_value(%{
        :value => value
      })
      when is_map(value) or is_list(value) do
    value
    |> Jason.encode!()
    |> Jason.Formatter.pretty_print()
  end

  def format_arg_value(%{:type => type, :value => value}) do
    case String.ends_with?(type, "*") do
      true ->
        type = String.replace_suffix(type, "*", "")

        value
        |> Enum.map(&format_arg_value(%{:type => type, :value => &1}))
        |> Jason.encode!()
        |> Jason.Formatter.pretty_print()

      _ ->
        value
    end
  end

  @doc """
  iex> builtin_name("range_check_builtin")
  RANGE CHECK BUILTIN
  """
  def builtin_name(builtin_name) do
    builtin_name
    |> String.replace("_", " ")
    |> String.upcase()
  end

  def builtin_color(builtin_name) do
    case builtin_name do
      "pedersen_builtin" -> "orange-label"
      "range_check_builtin" -> "pink-label"
      "keccak_builtin" -> "red-label"
      "bitwise_builtin" -> "blue-label"
      "ecdsa_builtin" -> "purple-label"
      "ec_op_builtin" -> "green-label"
      "poseidon_builtin" -> "orange-label"
      _ -> "green-label"
    end
  end

  # This case is for mainnet
  def network_path(:mainnet), do: "/"
  def network_path(:testnet), do: "/testnet/"

  def network_path(:mainnet, remaining_path) do
    "/#{remaining_path}"
  end

  def network_path(:testnet, remaining_path) do
    "/testnet/#{remaining_path}"
  end

  def format_version(<<"0x", hex_val::binary>>), do: "Cairo " <> hex_val
  def format_version(nil), do: "-"
  def format_version(version), do: version
end
