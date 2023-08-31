defmodule StarknetExplorer.BlockUtils do
  alias StarknetExplorer.{Rpc, Block}

  def fetch_and_store(block_height) do
    with false <- already_stored?(block_height),
         {:ok, block = %{"block_number" => block_number}} <- fetch_block(block_height),
         :ok <- store_block(block) do
      {:ok, block_number}
    else
      true ->
        {:ok, block_height}

      error ->
        {:error, error}
    end
  end

  defp already_stored?(block_height) do
    not is_nil(Block.get_by_height(block_height))
  end

  def store_block(block = %{"block_number" => block_number}) do
    with {:ok, receipts} <- receipts_for_block(block),
         {:ok, gas_price} <- StarknetExplorer.Gateway.block_gas_fee_in_wei(block_number) do
      block = Map.put(block, "gas_fee_in_wei", gas_price)
      Block.insert_from_rpc_response(block, receipts)
    end
  end

  defp receipts_for_block(_block = %{"transactions" => transactions}) do
    receipts =
      transactions
      |> Map.new(fn %{"transaction_hash" => tx_hash} ->
        {:ok, receipt} = Rpc.get_transaction_receipt(tx_hash, :mainnet)
        {tx_hash, receipt}
      end)

    {:ok, receipts}
  end

  def block_height() do
    case Rpc.get_block_height_no_cache(:mainnet) do
      {:ok, height} ->
        height

      err = {:error, _} ->
        err
    end
  end

  def fetch_block(number) when is_integer(number) do
    case Rpc.get_block_by_number(number, :mainnet) do
      {:ok, block} ->
        {:ok, block}

      {:error, _} ->
        :error
    end
  end
end
