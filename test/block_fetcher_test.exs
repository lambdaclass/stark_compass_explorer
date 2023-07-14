defmodule StarknetExplorer.BlockFetcher.Test do
  alias StarknetExplorer.{BlockFetcher, Block, Rpc, Repo}
  use StarknetExplorer.DataCase

  test "Fetch some blocks from nothing during 15 seconds, check db" do
    {:ok, pid} = BlockFetcher.start_link([])
    Process.send_after(pid, :stop, 15_000)
    Process.sleep(15_000)

    check_fetched_blocks_and_txs_are_valid_from_height(1, Block.highest_fetched_block_number())
  end

  @tag timeout: 120_000
  test "Fetch blocks from 40 blocks below the chain's height " do
    {:ok, block_height} = Rpc.get_block_height()
    lower_block_limit = block_height - 40

    # Introduce a fake block to make the BlockFetcher
    # start from this height.
    Repo.insert!(%Block{
      number: lower_block_limit,
      status: "FAKEBLOCK",
      hash: "",
      parent_hash: "",
      new_root: "",
      timestamp: DateTime.utc_now() |> DateTime.to_unix(),
      sequencer_address: "",
      original_json: ""
    })

    {:ok, pid} = BlockFetcher.start_link([])
    Process.send_after(pid, :stop, 50_000)
    Process.sleep(50_000)

    check_fetched_blocks_and_txs_are_valid_from_height(
      lower_block_limit + 1,
      Block.highest_fetched_block_number()
    )
  end

  defp check_fetched_blocks_and_txs_are_valid_from_height(from_height, to_height) do
    # For each fetched block, check we're
    # storing everything correctly.
    for i <- from_height..to_height do
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
          assert value == Map.get(db_tx, key_atom, "#{key_atom} is missing")
        end

        db_receipt =
          db_tx
          |> Repo.preload(:receipt)
          |> then(fn tx -> tx.receipt end)

        {:ok, receipt} =
          tx_hash
          |> Rpc.get_transaction_receipt()

        for {key, value} when key not in ["transaction_hash"] <- receipt do
          assert value ==
            Map.get(db_receipt, String.to_existing_atom(key), "#{key_atom} is missing")
        end
      end
    end
  end
end
