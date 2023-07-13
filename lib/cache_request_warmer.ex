defmodule StarknetExplorer.Cache.BlockWarmer do
  use Cachex.Warmer
  alias StarknetExplorer.Rpc

  def interval do
    :timer.seconds(60)
  end

  def execute(_) do
    {:ok, block = %{"block_number" => block_num}} =
      Rpc.get_latest_block() 

    block_requests =
      Enum.map((block_num - 20)..(block_num - 1), fn block_num ->
        {:ok, block = %{"transactions" => transactions}} = Rpc.get_block_by_number(block_num)
        block
        # tx_by_hash =
        #   transactions
        #   |> Enum.map(fn tx = %{"transaction_hash" => hash} -> {hash, tx} end)

        # Cachex.put_many(:tx_cache, tx_by_hash)
      end)

    blocks_by_hash =
      block_requests
      |> Enum.map(fn block = %{"block_hash" => hash} -> {hash, block} end)
      |> IO.inspect(label: BlocksByHash)

    blocks_by_number =
      block_requests
      |> Enum.map(fn block = %{"block_number" => number} -> {number, block} end)
      |> IO.inspect(label: BlocksByNumber)

    IO.inspect("Before returning")
    {:ok, blocks_by_number ++ blocks_by_hash}
  end
end
