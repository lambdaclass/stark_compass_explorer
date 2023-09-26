defmodule StarknetExplorer.BlockUtils do
  alias StarknetExplorer.{Rpc, Block}

  def fetch_and_store(block_height, network) do
    with false <- already_stored?(block_height, network),
         {:ok, block = %{"block_number" => block_number}} <- fetch_block(block_height, network),
         :ok <- store_block(block, network) do
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

  def store_block(block = %{"block_number" => block_number}, network) do
    with {:ok, receipts} <- receipts_for_block(block, network) do
      block =
        block
        |> Map.put("network", network)

      block =
        case Application.get_env(:starknet_explorer, :enable_gateway_data) do
          true ->
            {:ok, gateway_block = %{"gas_price" => gas_price}} =
              StarknetExplorer.Gateway.fetch_block(block_number, network)

            block
            |> Map.put("gas_fee_in_wei", gas_price)
            |> Map.put("execution_resources", calculate_gateway_block_steps(gateway_block))

          _ ->
            block
            |> Map.put("gas_fee_in_wei", "0")
            |> Map.put("execution_resources", 0)
        end

      Block.insert_from_rpc_response(block, receipts, network)
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
  def block_height(network) do
    case Block.block_height(network) do
      nil ->
        {:ok, block_height} = Rpc.get_block_height_no_cache(network)
        block_height

      block_height ->
        block_height
    end
  end

  @doc """
  Get the lowest block number from DB.
  If any block is present in the DB, use RPC.
  """
  def get_lowest_block_number(network) do
    case Block.get_lowest_block_number(network) do
      nil ->
        {:ok, block_number} = Rpc.get_block_height_no_cache(network)
        block_number

      block_number ->
        block_number
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

  def calculate_gateway_block_steps(_gateway_block = %{"transaction_receipts" => receipts}) do
    receipts
    |> get_steps_from_gateway_receipts
    |> Enum.sum()
  end

  defp get_steps_from_gateway_receipts(receipts) do
    receipts
    |> Enum.map(fn
      %{"execution_resources" => %{"n_steps" => steps}} -> steps
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end
end
