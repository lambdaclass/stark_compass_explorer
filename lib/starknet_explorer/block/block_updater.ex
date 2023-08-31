defmodule StarknetExplorer.BlockUpdater do
  alias StarknetExplorer.{Block, Gateway}
  use GenServer
  require Logger
  @update_interval :timer.seconds(5)
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(_args) do
    state = %{}
    Logger.info("starting block updater")
    Process.send_after(self(), :update_gas_fee, 100)
    {:ok, state}
  end

  def handle_info(:update_gas_fee, state) do
    Logger.info("Updating gas fees")

    case StarknetExplorer.Block.get_with_missing_gas_fees(10) do
      [] ->
        Process.send_after(self(), :stop, 100)

      blocks_without_gas_fees ->
        blocks_without_gas_fees
        |> tasks_for_fee_fetching
        |> Task.await_many()
        |> Enum.map(&do_db_update/1)

        Process.send_after(self(), :stop, @update_interval)
    end

    {:noreply, state}
  end

  def handle_info(:stop, state) do
    {:stop, :normal, state}
  end

  defp tasks_for_fee_fetching(blocks) when is_list(blocks) do
    Enum.map(blocks, &fee_fetch_task/1)
  end

  defp fee_fetch_task(block = %Block{}) do
    Task.async(fn -> fetch_gas_fee(block) end)
  end

  defp fetch_gas_fee(block = %Block{}) do
    case Gateway.block_gas_fee_in_wei(block.number) do
      {:ok, gas_price} ->
        {:ok, gas_price, block.number}

      err ->
        {err, block.number}
    end
  end

  defp do_db_update({:ok, gas_price, block_number}) do
    Block.update_gas_fee_for_block(block_number, gas_price)
  end

  defp do_db_update({{:error, reason}, block_number}) do
    Logger.error("Error fetching gas for block #{block_number}: #{inspect(reason)}")
  end
end
