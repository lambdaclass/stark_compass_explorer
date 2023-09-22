defmodule StarknetExplorer.BlockUpdater do
  alias StarknetExplorer.BlockUpdater
  defstruct [:network]
  alias StarknetExplorer.{Block, Gateway}
  use GenServer
  require Logger
  @update_interval :timer.seconds(5)
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(network: network) do
    state = %BlockUpdater{
      network: network
    }

    case Application.get_env(:starknet_explorer, :enable_gateway_data) do
      true ->
        Logger.info("starting block updater")
        Process.send_after(self(), :update_gas_fee, 100)

      _ ->
        :skip
    end

    {:ok, state}
  end

  def handle_info(
        :update_gas_fee,
        %BlockUpdater{
          network: network
        } = state
      ) do
    Logger.info("Updating gas fees")

    case StarknetExplorer.Block.get_with_missing_gas_fees_or_resources(10, network) do
      [] ->
        Process.send_after(self(), :stop, 100)

      blocks_without_gas_fees ->
        blocks_without_gas_fees
        |> tasks_for_fee_fetching(network)
        |> Task.await_many()
        |> Enum.map(&do_db_update(&1, network))

        Process.send_after(self(), :stop, @update_interval)
    end

    {:noreply, state}
  end

  def handle_info(:stop, state) do
    {:stop, :normal, state}
  end

  defp tasks_for_fee_fetching(blocks, network) when is_list(blocks) do
    Enum.map(blocks, &fee_fetch_task(&1, network))
  end

  defp fee_fetch_task(block = %Block{}, network) do
    Task.async(fn -> fetch_gas_fee_and_resources(block, network) end)
  end

  defp fetch_gas_fee_and_resources(block = %Block{}, network) do
    case Gateway.fetch_block(block.number, network) do
      {:ok, gateway_block = %{"gas_price" => gas_price}} ->
        execution_resources =
          StarknetExplorer.BlockUtils.calculate_gateway_block_steps(gateway_block)

        {:ok, gas_price, execution_resources, block.number}

      err ->
        {err, block.number}
    end
  end

  defp do_db_update({:ok, gas_price, execution_resources, block_number}, network) do
    Block.update_block_gas_and_resources(block_number, gas_price, execution_resources, network)
  end

  defp do_db_update({{:error, reason}, block_number}, network) do
    Logger.error(
      "Error fetching gas for block #{block_number}: #{inspect(reason)}, in network #{network}"
    )
  end
end
