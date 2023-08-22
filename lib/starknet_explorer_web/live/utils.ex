defmodule StarknetExplorerWeb.Utils do
  require Logger
  alias StarknetExplorer.Rpc
  alias StarknetExplorer.DateUtils
  alias StarknetExplorer.Transaction
  alias StarknetExplorer.{Block, Transaction, TransactionReceipt}

  def shorten_block_hash(nil), do: ""

  def shorten_block_hash(block_hash) do
    "#{String.slice(block_hash, 0, 6)}...#{String.slice(block_hash, -4, 4)}"
  end

  def get_latest_block_with_transactions(network) do
    {:ok, block} = Rpc.get_block_by_number(get_latest_block_number(network), network)

    [block]
  end

  def get_transaction(tx_hash, network) do
    tx =
      case Transaction.get_by_hash_with_receipt(tx_hash) do
        nil ->
          {:ok, tx} = Rpc.get_transaction(tx_hash, network)
          {:ok, receipt} = Rpc.get_transaction_receipt(tx_hash, network)

          tx
          |> Transaction.from_rpc_tx()
          |> Map.put(:receipt, receipt |> atomize_keys)

        tx ->
          tx
      end

    {:ok, tx}
  end

  def get_latest_block_number(network) do
    {:ok, _latest_block = %{"block_number" => block_number}} =
      Rpc.get_latest_block_no_cache(network)

    block_number
  end

  def list_blocks(network, block_amount \\ 15) do
    block_number = get_latest_block_number(network)
    blocks = Block.latest_blocks_with_txs(block_amount, block_number)
    every_block_is_in_the_db = length(blocks) == block_amount

    case blocks do
      blocks when every_block_is_in_the_db ->
        blocks

      _ ->
        upper = block_number
        lower = block_number - block_amount

        upper..lower
        |> Enum.map(fn block_number ->
          {:ok, block} = Rpc.get_block_by_number(block_number, network)

          Block.from_rpc_block(block)
        end)
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
