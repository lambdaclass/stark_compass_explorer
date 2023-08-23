defmodule StarknetExplorerWeb.Utils do
  require Logger
  alias StarknetExplorer.Rpc
  alias StarknetExplorer.DateUtils
  alias StarknetExplorer.Block

  def shorten_block_hash(nil), do: ""

  def shorten_block_hash(block_hash) do
    "#{String.slice(block_hash, 0, 6)}...#{String.slice(block_hash, -4, 4)}"
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

  def atomize_keys(map) when is_map(map) do
    map
    |> Map.new(fn {key, val} when is_binary(key) ->
      {String.to_atom(key), atomize_keys(val)}
    end)
  end

  def atomize_keys(list) when is_list(list) do
    list
    |> Enum.map(fn list_elem -> atomize_keys(list_elem) end)
  end

  def atomize_keys(not_a_map), do: not_a_map
end
