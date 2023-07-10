defmodule StarknetExplorer.BlockFetcher.Test do
  alias StarknetExplorer.{BlockFetcher, Block, Rpc, Repo}
  use StarknetExplorer.DataCase

  test "Fetch some blocks during 15 seconds, check db" do
    {:ok, pid} = BlockFetcher.start_link([])
    Process.send_after(pid, :stop, 15_000)
    Process.sleep(15_000)
    block_height = Block.highest_fetched_block_number()

    # For each fetched block, check we're
    # storing everything correctly.
    for i <- 1..block_height do
      {:ok, rpc_json = %{"block_hash" => hash, "block_number" => number, "transactions" => txs}} =
        Rpc.get_block_by_number(i)

      # Check the block's hash and number is correct
      db_block = Repo.one!(from b in Block, where: b.number == ^i) |> Repo.preload(:transactions)
      assert hash == db_block.hash
      assert number == db_block.number

      # Check stored json is correct
      db_json = Repo.one!(from b in Block, select: b.original_json, where: b.number == ^i)
      assert rpc_json == db_json |> :erlang.binary_to_term()

      # Check the block's transactions and receipts are correct
      for tx = %{"transaction_hash" => tx_hash} <- txs do
        db_tx =
          db_block.transactions
          |> Enum.find(fn db_tx -> db_tx.hash == tx_hash end)

        for {key, value} when key not in ["transaction_hash"] <- tx do
          key_atom = String.to_existing_atom(key)
          assert value == Map.get(db_tx, key_atom)
        end

        db_receipt =
          db_tx
          |> Repo.preload(:receipt)
          |> then(fn tx -> tx.receipt end)

        {:ok, receipt} =
          tx_hash
          |> Rpc.get_transaction_receipt()

        for {key, value} when key not in ["transaction_hash"] <- receipt do
          key_atom = String.to_existing_atom(key)
          assert value == Map.get(db_receipt, String.to_existing_atom(key))
        end
      end
    end
  end
end
