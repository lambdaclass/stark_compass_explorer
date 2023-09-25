defmodule StarknetExplorer.Blockchain.UpdaterWorker do
  require Logger
  use GenServer
  alias StarknetExplorer.TransactionReceipt
  alias StarknetExplorer.Rpc
  alias StarknetExplorer.Block
  alias StarknetExplorer.Gateway
  alias StarknetExplorer.Repo
  alias StarknetExplorer.Blockchain.UpdaterWorker
  defstruct [:network]

  @fetch_timer :timer.seconds(String.to_integer(System.get_env("UPDATER_FETCH_TIMER", "2"), 10))
  @limit 10

  def start_link([network: _network, name: name] = arg) do
    GenServer.start_link(__MODULE__, arg, name: name)
  end

  ## Callbacks

  @impl true
  def init([network: network, name: _name] = _args) do
    state = %UpdaterWorker{
      network: network
    }

    Process.send_after(self(), :update, @fetch_timer)
    Logger.info("Updater enabled")
    {:ok, state}
  end

  @impl true
  def handle_info(:update, state = %UpdaterWorker{network: network}) do
    Logger.info("Updating...")
    # Get whatever we need to update.
    # Blocks:
    #   - if gas_fee or resources empty -> try update
    #   - if status not "accepted on l1" -> try update
    # Transaction receipt:
    #   - if status not "accepted on l1" OR "reverted" -> try update
    #   - If transaction.status != "reverted" and transaction.receipt == None -> try update

    # REVISIT:
    # LAST THREE CAN BE MERGED.
    # IF A BLOCK IS FINALIZED -> TX SHOULD BE FINALIZED STATUS -> RECEIPT SHOULD EXIST OR NOT

    #   - if gas_fee or resources empty -> try update
    StarknetExplorer.Block.get_with_missing_gas_fees_or_resources(@limit, network)
    |> tasks_for_fee_fetching(network)
    |> Task.await_many()
    |> Enum.map(&do_db_update_fee_and_resources(&1, network))

    #   - if status not "accepted on l1" -> try update
    # We are retrieving from oldest to newest.
    StarknetExplorer.Block.get_with_not_finalized_blocks(@limit, network)
    |> tasks_for_not_finalized_blocks(network)
    # |> Task.await_many()
    |> Enum.map(&do_db_update_block_status(&1, network))

    #   - if status not "accepted on l1" OR "reverted" -> try update
    StarknetExplorer.TransactionReceipt.get_status_not_finalized(@limit, network)
    |> tasks_for_not_finalized_transactions(network)
    |> Task.await_many()
    |> Enum.map(&do_db_update_transaction_status(&1, network))

    # - If transaction.receipt == None -> try update
    StarknetExplorer.Transaction.get_missing_tx_receipt(@limit, network)
    |> tasks_for_unexisting_receipts(network)
    |> Task.await_many()
    |> Enum.map(&do_db_insert_receipts(&1, network))

    Process.send_after(self(), :update, @fetch_timer)
    {:noreply, state}
  end

  defp tasks_for_unexisting_receipts(transactions, network) do
    Enum.map(transactions, &transaction_receipts_fetch_task(&1, network))
  end

  defp transaction_receipts_fetch_task(transaction = %StarknetExplorer.Transaction{}, network) do
    Task.async(fn -> Rpc.get_transaction_receipt(transaction.hash, network) end)
  end

  defp do_db_insert_receipts(
         {:ok, tx_receipt},
         network
       ) do
    TransactionReceipt.from_rpc_tx(tx_receipt |> Map.put("network", network)) |> Repo.insert()
  end

  defp do_db_insert_receipts({{:error, reason}, _tx_hash}, _network) do
    Logger.error("Transaction receipt fetch failed with error: #{reason}")
  end

  defp tasks_for_not_finalized_transactions(transactions, network) do
    Enum.map(transactions, &transaction_fetch_task(&1, network))
  end

  defp transaction_fetch_task(transaction = %StarknetExplorer.TransactionReceipt{}, network) do
    Task.async(fn ->
      {Rpc.get_transaction_receipt(transaction.transaction_hash, network),
       transaction.transaction_hash}
    end)
  end

  defp do_db_update_transaction_status(
         {{:ok,
           %{"finality_status" => finality_status, "execution_status" => execution_status} =
             _status}, tx_hash},
         network
       ) do
    TransactionReceipt.update_transaction_status(
      tx_hash,
      finality_status,
      execution_status,
      network
    )
  end

  defp do_db_update_transaction_status({{:error, reason}, _tx_hash}, _network) do
    Logger.error("Transaction status fetch failed with error: #{reason["message"]}")
  end

  defp tasks_for_not_finalized_blocks(blocks, network) do
    Enum.map(blocks, fn block -> Rpc.get_block_by_number(block.number, network) end)
  end

  defp do_db_update_block_status(
         {:ok, %{"block_number" => block_number, "status" => status} = _block},
         network
       ) do
    Block.update_block_status(block_number, status, network)
  end

  defp do_db_update_block_status({:error, reason}, _network) do
    Logger.error("Block fetch failed with error: #{reason}")
  end

  defp tasks_for_fee_fetching(blocks, network) when is_list(blocks) do
    Enum.map(blocks, &fee_fetch_task(&1, network))
  end

  defp fee_fetch_task(block = %StarknetExplorer.Block{}, network) do
    Task.async(fn -> fetch_gas_fee_and_resources(block, network) end)
  end

  defp fetch_gas_fee_and_resources(block = %StarknetExplorer.Block{}, network) do
    case Gateway.fetch_block(block.number, network) do
      {:ok, gateway_block = %{"gas_price" => gas_price}} ->
        execution_resources =
          StarknetExplorer.BlockUtils.calculate_gateway_block_steps(gateway_block)

        {:ok, gas_price, execution_resources, block.number}

      err ->
        {err, block.number}
    end
  end

  defp do_db_update_fee_and_resources(
         {:ok, gas_price, execution_resources, block_number},
         network
       ) do
    Block.update_block_gas_and_resources(block_number, gas_price, execution_resources, network)
  end

  defp do_db_update_fee_and_resources({{:error, reason}, block_number}, network) do
    Logger.error(
      "Error fetching gas for block #{block_number}: #{inspect(reason)}, in network #{network}"
    )
  end
end
