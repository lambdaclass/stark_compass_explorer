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

    case StarknetExplorer.Block.get_with_missing_gas_fees_or_resources(10) do
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
    Task.async(fn -> fetch_gas_fee_and_resources(block) end)
  end

  defp fetch_gas_fee_and_resources(block = %Block{}) do
    case Gateway.fetch_block(block.number) do
      {:ok, gateway_block = %{"gas_price" => gas_price}} ->
        execution_resources =
          StarknetExplorer.BlockUtils.calculate_gateway_block_steps(gateway_block)

        {:ok, gas_price, execution_resources, block.number}

      err ->
        {err, block.number}
    end
  end

  defp do_db_update({:ok, gas_price, execution_resources, block_number}) do
    Block.update_block_gas_and_resources(block_number, gas_price, execution_resources)
  end

  defp do_db_update({{:error, reason}, block_number}) do
    Logger.error("Error fetching gas for block #{block_number}: #{inspect(reason)}")
  end
end
