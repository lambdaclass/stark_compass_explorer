defmodule StarknetExplorer.Cache.BlockWarmer do
  require Logger
  use Cachex.Warmer
  alias StarknetExplorer.Rpc
  @interval :timer.seconds(10)
  def interval, do: @interval

  def execute(%{network: network})
      when network in [:mainnet, :testnet, :testnet2] do
    Logger.debug("Warming cache for #{network}")
    # Try/Rescue is not really an elixir/erlang thing to do, but
    # I think this is the most simple way to do this, since
    # this process can crash the whole application on startup.
    try do
      # Fetch the highest block number,
      # invalidate cache so that we're sure that
      # we're using fresh data.
      {:ok, latest_block = %{"block_number" => latest_block_num, "block_hash" => latest_hash}} =
        Rpc.get_latest_block_no_cache(network)

      # Request blocks that fall in the range
      # between latest and 20 behind, because that's
      # what we mostly show on the home page.
      block_requests =
        Enum.map(max(latest_block_num - 20, 0)..max(latest_block_num - 1, 0), fn block_num ->
          {:ok, block = %{"transactions" => transactions}} =
            Rpc.get_block_by_number(block_num, network)

          tx_by_hash =
            transactions
            |> Enum.map(fn tx = %{"transaction_hash" => hash} -> {hash, tx} end)

          # Cache each block transaction
          Cachex.put_many(:tx_cache, tx_by_hash)

          block
        end)

      # Create block_hash -> block and block_number -> block key-value
      # pairs to be able to fetch them from the cache either by hash or
      # number, surely there's a way to not repeat the same block
      # and have some kind of multi-key but this works for now.
      blocks_by_hash =
        block_requests
        |> Enum.map(fn block = %{"block_hash" => hash} -> {hash, block} end)

      blocks_by_number =
        block_requests
        |> Enum.map(fn block = %{"block_number" => number} -> {number, block} end)

      # The latest block can also be queried by
      # using "latest" so we use that as a key.
      latest_block_by_hash_and_number = [
        {latest_block_num, latest_block},
        {latest_hash, latest_block},
        {"latest", latest_block}
      ]

      # Finally, this return value
      # is what cachex stores.
      blocks = latest_block_by_hash_and_number ++ blocks_by_number ++ blocks_by_hash
      {:ok, blocks}
    rescue
      err ->
        Logger.error(
          "Cache warming failed for #{network} with: #{inspect(err)}, retrying in #{@interval / 1000} seconds..."
        )

        :ignore
    end
  end
end
