defmodule StarknetExplorerWeb.Utils do
  alias StarknetExplorer.Rpc
  alias StarknetExplorer.DateUtils

  def shorten_block_hash(nil), do: ""

  def shorten_block_hash(block_hash) do
    "#{String.slice(block_hash, 0, 6)}...#{String.slice(block_hash, -4, 4)}"
  end

  def get_latest_block_with_transactions(network) do
    {:ok, block} = Rpc.get_block_by_number(get_latest_block_number(network), network)

    [block]
  end

  def get_latest_block_number(network) do
    {:ok, _latest_block = %{"block_number" => block_number}} =
      Rpc.get_latest_block_no_cache(network)

    block_number
  end

  def list_blocks(network) do
    block_number = get_latest_block_number(network)
    Enum.reverse(list_blocks(block_number, 15, [], network))
  end

  def list_blocks(_block_number, 0, acc, _) do
    acc
  end

  def list_blocks(block_number, _remaining, acc, _) when block_number < 0 do
    acc
  end

  def list_blocks(block_number, remaining, acc, network) do
    {:ok, block} = Rpc.get_block_by_number(block_number, network)
    prev_block_number = block_number - 1
    list_blocks(prev_block_number, remaining - 1, [block | acc], network)
  end

  def get_block_age(block) do
    get_block_age_from_timestamp(block["timestamp"])
  end

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
end
