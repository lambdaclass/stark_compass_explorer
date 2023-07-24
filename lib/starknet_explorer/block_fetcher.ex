defmodule StarknetExplorer.BlockFetcher do
  use GenServer
  require Logger
  alias StarknetExplorer.{Rpc, BlockFetcher, Block, Class, Contract, NIF}
  alias StarknetExplorer.TransactionReceipt, as: Receipt
  defstruct [:block_height, :latest_block_fetched]
  @fetch_interval 300
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_opts) do
    state = %BlockFetcher{
      # The actual chain block-height
      block_height: fetch_block_height(),
      # Highest block number stored on the DB
      latest_block_fetched: StarknetExplorer.Block.highest_fetched_block_number()
    }

    Process.send_after(self(), :fetch_and_store, @fetch_interval)
    {:ok, state}
  end

  @impl true
  def handle_info(:fetch_and_store, state = %BlockFetcher{}) do
    # Try to fetch the new height, else keep the current one.
    curr_height =
      case fetch_block_height() do
        height when is_integer(height) -> height
        _ -> state.block_height
      end

    # If the db is 10 blocks behind,
    # fetch a new block, else do nothing.
    if curr_height + 10 >= state.latest_block_fetched do
      case fetch_block(state.latest_block_fetched + 1) do
        {:ok, block = %{"block_number" => new_block_number, "transactions" => transactions}} ->
          receipts =
            transactions
            |> Map.new(fn %{"transaction_hash" => tx_hash} ->
              {:ok, receipt} = Rpc.get_transaction_receipt(tx_hash)
              {tx_hash, receipt}
            end)

          :ok = Block.insert_from_rpc_response(block, receipts)

          Enum.each(transactions, fn tx -> process_transaction(tx, block) end)

          Process.send_after(self(), :fetch_and_store, @fetch_interval)
          {:noreply, %{state | block_height: curr_height, latest_block_fetched: new_block_number}}

        :error ->
          {:noreply, state}
      end
    end
  end

  @impl true
  def handle_info(:stop, _) do
    Logger.info("Stopping BlockFetcher")
    {:stop, :normal, :ok}
  end

  # TODO: Early on DECLARE transactions did not exist, they were DEPLOY ones.
  # We need to take that into account

  # Contracts:
  # If it's the first time we see the class hash, it's a declare, othwise deploy
  defp process_transaction(transaction = %{"type" => "DEPLOY_ACCOUNT"}, block) do
    %{
      "class_hash" => class_hash,
      "transaction_hash" => tx_hash,
      "block_number" => block_number,
      "contract_address_salt" => salt,
      "constructor_call_data" => call_data
    } =
      transaction

    :ok =
      case Class.get_by_hash(class_hash) do
        nil ->
          build_class_info_and_insert(class_hash, block, transaction)

        _ ->
          :ok
      end

    contract_address = NIF.contract_address(tx_hash, salt, class_hash, call_data)

    Contract.changeset(%Contract{address: contract_address}, %{
      # TODO: Fetch this balance properly
      eth_balance: 0,
      deployed_at: tx_hash,
      deployed_at_tx: tx_hash,
      type: "ACCOUNT",
      # Deployed by 'itself'
      deployed_by: nil,
      version: nil
    })
  end

  defp process_transaction(transaction = %{"type" => "DECLARE"}, block) do
    %{"class_hash" => class_hash, "block_number" => block_number} = transaction
    build_class_info_and_insert(class_hash, transaction, block)
  end

  defp process_transaction(_, _), do: :nothing

  defp build_class_info_and_insert(
         class_hash,
         block = %{"block_number" => new_block_number},
         transaction
       ) do
    {:ok, class} =
      Rpc.get_class(new_block_number, class_hash)

    class =
      Map.put(class, "hash", class_hash)
      |> Map.put("block_number", new_block_number)
      |> Map.put("declared_at", block["timestamp"])
      |> Map.put("declared_at_tx", transaction["transaction_hash"])
      |> Map.put("version", class["contract_class_version"])

    # TODO: Uncomment this line when we have contracts
    # |> Map.put("declared_by", transaction["sender_address"])

    Class.insert_from_rpc_response(class)
  end

  defp fetch_block_height() do
    case Rpc.get_block_height() do
      {:ok, height} ->
        height

      {:error, _} ->
        Logger.error("[#{DateTime.utc_now()}] Could not update block height from RPC module")
    end
  end

  defp fetch_block(number) when is_integer(number) do
    case Rpc.get_block_by_number(number) do
      {:ok, block} ->
        {:ok, block}

      {:error, _} ->
        Logger.error("Could not fetch block #{number} from RPC module")
        :error
    end
  end
end
