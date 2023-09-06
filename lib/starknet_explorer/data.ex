defmodule StarknetExplorer.Data do
  alias StarknetExplorer.{Rpc, Transaction, Block, TransactionReceipt}

  @doc """
  Fetch `block_amount` blocks (defaults to 15), first
  look them up in the db, if not found check the RPC
  provider.
  """
  def many_blocks(network, block_amount \\ 15) do
    block_number = StarknetExplorer.Data.latest_block_number(network)
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

  @doc """
  Fetch a block by its hash, first look up in
  the db, if not found, fetch from the RPC provider
  """
  def block_by_hash(hash, network) do
    case Block.get_by_hash(hash) do
      nil ->
        {:ok, block} = Rpc.get_block_by_hash(hash, network)
        {:ok, Block.from_rpc_block(block)}

      block ->
        {:ok, block}
    end
  end

  @doc """
  Fetch a block by number, first look up in
  the db, if not found, fetch from the RPC provider
  """
  def block_by_number(number, network) do
    case Block.get_by_num(number) do
      nil ->
        {:ok, block} = Rpc.get_block_by_number(number, network)
        {:ok, Block.from_rpc_block(block)}

      block ->
        {:ok, block}
    end
  end

  @doc """
  Fetch transactions receipts by block hash
  """
  def receipts_by_block_hash(block_hash) do
    case TransactionReceipt.get_by_block_hash(block_hash) do
      receipts ->
        {:ok, receipts}
    end
  end

  @doc """
  delete
  """
  def test_receipt() do
    case TransactionReceipt.get_by_transaction_hash(
           "0x02b0821a222884de8bb0d2d35fd5369e721c253453c89e6bd08143117543602f"
         ) do
      receipts ->
        {:ok, receipts}
    end
  end

  def latest_block_number(network) do
    {:ok, _latest_block = %{"block_number" => block_number}} =
      Rpc.get_latest_block_no_cache(network)

    block_number
  end

  def latest_block_with_transactions(network) do
    {:ok, block} = Rpc.get_block_by_number(latest_block_number(network), network)

    [block]
  end

  def transaction(tx_hash, network) do
    tx =
      case Transaction.get_by_hash_with_receipt(tx_hash) do
        nil ->
          {:ok, tx} = Rpc.get_transaction(tx_hash, network)
          {:ok, receipt} = Rpc.get_transaction_receipt(tx_hash, network)

          tx
          |> Transaction.from_rpc_tx()
          |> Map.put(:receipt, receipt |> StarknetExplorerWeb.Utils.atomize_keys())

        tx ->
          tx
      end

    {:ok, tx}
  end
end
