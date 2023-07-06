defmodule StarknetExplorer.BlockFetcher.Test do
  alias StarknetExplorer.{BlockFetcher, Block, Rpc, Repo}
  use StarknetExplorer.DataCase

  test "Fetch some blocks during 10 seconds, check db is ok" do
    {:ok, pid} = BlockFetcher.start_link([])
    Process.send_after(pid, :stop, 10_000)
    Process.sleep(10_000)
    block_height = Block.highest_fetched_block_number()

    for i <- 1..block_height do
      {:ok, %{"block_hash" => hash, "block_number" => number}} = Rpc.get_block_by_number(i)
      db_block = Repo.one!(from b in Block, where: b.number == ^i)
      assert hash == db_block.hash
      assert number == db_block.number
    end
  end
end
