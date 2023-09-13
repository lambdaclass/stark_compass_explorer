defmodule StarknetExplorerWeb.Utils do
  require Logger
  alias StarknetExplorer.DateUtils

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
    shorten_block_hash(value)
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
end
