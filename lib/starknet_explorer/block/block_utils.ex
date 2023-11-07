defmodule StarknetExplorer.BlockUtils do
  alias StarknetExplorer.{Rpc, Block}
  alias StarknetExplorer.IndexCache

  def fetch_store_and_cache(block_height, network) do
    with false <- already_stored?(block_height, network),
         {:ok, block} <- fetch_block(block_height, network),
         {:ok, block_number} <- store_block(block, network),
         :ok <- IndexCache.add_block(block_number, network) do
      {:ok, block_number}
    else
      true ->
        {:ok, :already_stored}

      error ->
        {:error, error}
    end
  end

  def fetch_and_store(block_height, network) do
    with false <- already_stored?(block_height, network),
         {:ok, block = %{"block_number" => block_number}} <- fetch_block(block_height, network),
         {:ok, _} <- store_block(block, network) do
      {:ok, block_number}
    else
      true ->
        {:ok, block_height}

      error ->
        {:error, error}
    end
  end

  def fetch_and_update(block_height, network) do
    with block_from_sql <- Block.get_by_number_with_receipts_preload(block_height, network),
         {:ok, block_from_rpc = %{"block_number" => block_number}} <-
           fetch_block(block_height, network),
         {:ok, _update} <- update_block_and_transactions(block_from_sql, block_from_rpc, network) do
      {:ok, block_number}
    else
      true ->
        {:ok, block_height}

      error ->
        {:error, error}
    end
  end

  defp already_stored?(block_height, network) do
    not is_nil(Block.get_by_num(block_height, network))
  end

  def update_block_and_transactions(
        block_from_sql,
        block_from_rpc,
        network
      ) do
    with {:ok, receipts} <- receipts_for_block(block_from_rpc, network) do
      block_from_rpc =
        block_from_rpc
        |> Map.put("network", network)
        |> Map.put("gas_fee_in_wei", block_from_rpc["l1_gas_price"]["price_in_wei"])
        |> Map.put("execution_resources", calculate_block_steps_from_receipts(receipts))

      Block.update_from_rpc_response(block_from_sql, block_from_rpc, receipts)
    end
  end

  def store_block(block = %{"block_number" => block_number}, network) do
    with {:ok, receipts} <- receipts_for_block(block, network) do
      block =
        block
        |> Map.put("network", network)
        |> Map.put("gas_fee_in_wei", block["l1_gas_price"]["price_in_wei"])
        |> Map.put("execution_resources", calculate_block_steps_from_receipts(receipts))

      {:ok, amount_blocks, amount_txs, amount_events, amount_messages} =
        Block.insert_from_rpc_response(block, receipts, network)

      {:ok, _} =
        StarknetExplorer.Counts.insert_or_update(
          network,
          amount_blocks,
          amount_txs,
          amount_events,
          amount_messages
        )

      {:ok, block_number}
    end
  end

  defp receipts_for_block(_block = %{"transactions" => transactions}, network) do
    receipts =
      transactions
      |> Enum.chunk_every(75)
      |> Enum.flat_map(fn chunk ->
        tasks =
          Enum.map(chunk, fn %{"transaction_hash" => tx_hash} ->
            Task.async(fn ->
              {:ok, receipt} = Rpc.get_transaction_receipt(tx_hash, network)

              {tx_hash, receipt |> Map.put("network", network)}
            end)
          end)

        Enum.map(tasks, &Task.await(&1, 7500))
      end)

    {:ok, Map.new(receipts)}
  end

  def block_height_rpc(network) do
    case Rpc.get_block_height_no_cache(network) do
      {:ok, height} ->
        height

      err = {:error, _} ->
        err
    end
  end

  @doc """
  Get block height from DB.
  If any block is present in the DB, use RPC.
  """
  def block_height(network) when is_atom(network) do
    case Block.block_height(Atom.to_string(network)) do
      %Block{} = block ->
        {:ok, block.number}

      _else ->
        Rpc.get_block_height_no_cache(network)
    end
  end

  @doc """
  Get the lowest block number from DB.
  If any block is present in the DB, use RPC.
  """
  def get_lowest_block_number(network) when is_atom(network) do
    case Block.get_lowest_block_number(Atom.to_string(network)) do
      {:ok, %Postgrex.Result{rows: [[block_number]]}} ->
        {:ok, block_number}

      {:ok, %Exqlite.Result{rows: [[block_number]]}} ->
        {:ok, block_number}

      _else ->
        Rpc.get_block_height_no_cache(network)
    end
  end

  @doc """
  Get the lowest uncompleted block number from DB.
  If any block is present in the DB, use RPC.
  A block can be uncompleted if:
  - Missing execution resources & fee
  - block status != "ACCEPTED_ON_L1"
  """
  def get_lowest_not_completed_block(network) when is_atom(network) do
    case Block.get_lowest_not_completed_block(Atom.to_string(network)) do
      %Block{} = block ->
        {:ok, block.number}

      _else ->
        Rpc.get_block_height_no_cache(network)
    end
  end

  def fetch_block(number, network) when is_integer(number) do
    case Rpc.get_block_by_number(number, network) do
      {:ok, block} ->
        {:ok, block}

      {:error, _} ->
        :error
    end
  end

  def calculate_block_steps_from_receipts(receipts) do
    receipts
    |> get_steps_from_receipts
    |> Enum.sum()
  end

  defp get_steps_from_receipts(receipts) do
    receipts
    |> Map.values()
    |> Enum.map(fn
      %{"execution_resources" => %{"steps" => steps}} ->
        steps
        |> StarknetExplorerWeb.Utils.hex_to_integer()

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
  end
end
