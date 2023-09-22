defmodule StarknetExplorer.Data do
  require Logger

  alias StarknetExplorer.{
    Rpc,
    Transaction,
    Message,
    Events,
    Block,
    TransactionReceipt,
    Calldata,
    Gateway
  }

  alias StarknetExplorerWeb.Utils

  @common_event_hash_to_name %{
    "0x99cd8bde557814842a3121e8ddfd433a539b8c9f14bf31ebf108d12e6196e9" => "Transfer",
    "0x134692b230b9e1ffa39098904722134159652b09c5bc41d88d6698779d228ff" => "Approval",
    "0x1390fd803c110ac71730ece1decfc34eb1d0088e295d4f1b125dda1e0c5b9ff" => "OwnershipTransferred",
    "0x3774b0545aabb37c45c1eddc6a7dae57de498aae6d5e3589e362d4b4323a533" => "governor_nominated",
    "0x19b0b96cb0e0029733092527bca81129db5f327c064199b31ed8a9f857fdee3" => "nomination_cancelled",
    "0x3b7aa6f257721ed65dae25f8a1ee350b92d02cd59a9dcfb1fc4e8887be194ec" => "governor_removed",
    "0x4595132f9b33b7077ebf2e7f3eb746a8e0a6d5c337c71cd8f9bf46cac3cfd7" => "governance_accepted",
    "0x2e8a4ec40a36a027111fafdb6a46746ff1b0125d5067fbaebd8b5f227185a1e" => "implementation_added",
    "0x3ef46b1f8c5c94765c1d63fb24422442ea26f49289a18ba89c4138ebf450f6c" =>
      "implementation_removed",
    "0x1205ec81562fc65c367136bd2fe1c0fff2d1986f70e4ba365e5dd747bd08753" =>
      "implementation_upgraded",
    "0x2c6e1be7705f64cd4ec61d51a0c8e64ceed5e787198bd3291469fb870578922" =>
      "implementation_finalized",
    "0x2db340e6c609371026731f47050d3976552c89b4fbb012941663841c59d1af3" => "Upgraded",
    "0x120650e571756796b93f65826a80b3511d4f3a06808e82cb37407903b09d995" => "AdminChanged",
    "0xe316f0d9d2a3affa97de1d99bb2aac0538e2666d0d8545545ead241ef0ccab" => "Swap",
    "0xe14a408baf7f453312eec68e9b7d728ec5337fbdf671f917ee8c80f3255232" => "Sync",
    "0x5ad857f66a5b55f1301ff1ed7e098ac6d4433148f0b72ebc4a2945ab85ad53" => "transaction_executed",
    "0x10c19bef19acd19b2c9f4caa40fd47c9fbe1d9f91324d44dcd36be2dae96784" => "account_created",
    "0x243e1de00e8a6bc1dfa3e950e6ade24c52e4a25de4dee7fb5affe918ad1e744" => "Burn",
    "0x34e55c1cd55f1338241b50d352f0e91c7e4ffad0e4271d64eb347589ebdfd16" => "Mint"
  }

  @common_event_hashes Map.keys(@common_event_hash_to_name)
  @condition_to_match 15

  # Defines the separator used to distinguish between modules and event names in Cairo0 events.
  # In Cairo0 events, event names may include module information in the format:
  # `Module1::SubModule::EventName`
  @event_module_separator "::"

  @doc """
  Fetch `block_amount` blocks (defaults to 15), first
  look them up in the db, if not found check the RPC
  provider.
  """
  def many_blocks(network, block_amount \\ 15) do
    block_number = StarknetExplorer.Data.latest_block_number(network)
    blocks = Block.latest_blocks_with_txs(block_amount, block_number, network)
    every_block_is_in_the_db = length(blocks) == block_amount

    case blocks do
      blocks when every_block_is_in_the_db ->
        blocks

      _ ->
        upper = block_number
        lower = block_number - block_amount

        upper..lower
        |> Enum.map(fn block_number ->
          {:ok, block} = Rpc.get_block_by_number(block_number, network)

          Block.from_rpc_block(block, network)
        end)
    end
  end

  @doc """
  Fetch a block by its hash, first look up in
  the db, if not found, fetch from the RPC provider
  """
  def block_by_hash(hash, network) do
    case Block.get_by_hash(hash, network) do
      nil ->
        {:ok, block} = Rpc.get_block_by_hash(hash, network)
        StarknetExplorer.BlockUtils.store_block(block, network)

        block = Block.from_rpc_block(block, network)
        {:ok, block}

      block ->
        {:ok, block}
    end
  end

  @doc """
  Fetch a block by number, first look up in
  the db, if not found, fetch from the RPC provider
  """
  def block_by_number(number, network) do
    case Block.get_by_num(number, network) do
      nil ->
        {:ok, block} = Rpc.get_block_by_number(number, network)
        StarknetExplorer.BlockUtils.store_block(block, network)

        block = Block.from_rpc_block(block, network)
        {:ok, block}

      block ->
        {:ok, block}
    end
  end

  @doc """
  Fetch transactions receipts by block
  """
  def receipts_by_block(block, network) do
    case TransactionReceipt.get_by_block_hash(block.hash) do
      # TODO: remove case; it should not happen anymore because on block retrieval we are also storing related data on db
      # if receipts are not found in the db, split the txs in chunks and get receipts by RPC
      [] ->
        Logger.warning(
          "The block should have been saved with all related txs and receipts earlier"
        )

        all_receipts =
          block.transactions
          |> Enum.chunk_every(50)
          |> Enum.flat_map(fn chunk ->
            tasks =
              Enum.map(chunk, fn x ->
                Task.async(fn ->
                  {:ok, receipt} = Rpc.get_transaction_receipt(x.hash, network)

                  # if we try to create a %StarknetExplorer.TransactionReceipt, this fails because it will not be linked to any transaction struct
                  receipt
                  |> StarknetExplorerWeb.Utils.atomize_keys()
                end)
              end)

            Enum.map(tasks, &Task.await(&1, 10000))
          end)

        {:ok, Map.new(all_receipts)}

      receipts ->
        {:ok, receipts}
    end
  end

  def latest_block_number(network) do
    {:ok, _latest_block = %{"block_number" => block_number}} =
      Rpc.get_latest_block_no_cache(network)

    block_number
  end

  def latest_block_with_transactions(network) do
    {:ok, block} = Rpc.get_block_by_number(latest_block_number(network), network)

    [block]
  end

  def transaction(tx_hash, network) do
    tx =
      case Transaction.get_by_hash_with_receipt(tx_hash) do
        nil ->
          {:ok, tx} = Rpc.get_transaction(tx_hash, network)
          {:ok, receipt} = Rpc.get_transaction_receipt(tx_hash, network)

          tx
          |> Transaction.from_rpc_tx()
          |> Map.put(:receipt, receipt |> StarknetExplorerWeb.Utils.atomize_keys())

        tx ->
          tx
      end

    {:ok, tx}
  end

  # This behavior is modified for testing porpouses.
  # def get_block_events_paginated(block, pagination, network) do
  #   # If the entries are empty, means that the events was not fetch yet.
  #   with %Scrivener.Page{entries: []} <- Events.paginate_events(pagination, block.number, network) do
  #     :ok = Events.store_events_from_rpc(block, network)
  #     get_block_events_paginated(block, pagination, network)
  #   else
  #     page -> page
  #   end
  # end
  def get_block_events_paginated(block_hash, pagination, network) do
    {:ok, events} = Rpc.get_block_events_paginated(block_hash, pagination, network)

    events
  end

  def get_events(params, network) do
    Rpc.get_events(params, network)
  end

  def full_transaction(tx_hash, network) do
    {:ok, tx} = transaction(tx_hash, network)
    receipt = tx.receipt

    block_id =
      if Map.has_key?(receipt, :block_number),
        do: %{"block_number" => receipt.block_number},
        else: "latest"

    contract =
      case Rpc.get_class_at(block_id, tx.sender_address, network) do
        {:ok, contract} ->
          contract

        _ ->
          nil
      end

    tx = tx |> Map.put(:contract, contract)

    input_data = Calldata.parse_calldata(tx, block_id, network)

    {:ok, tx |> Map.put(:input_data, input_data)}
  end

  def get_class_at(block_number, contract_address, network) do
    {:ok, class_hash} =
      Rpc.get_class_at(%{"block_number" => block_number}, contract_address, network)

    class_hash
  end

  defp last_n_characters(input_string) do
    # Calculate the starting index
    start_index = String.length(input_string) - @condition_to_match

    # Keep the last N characters
    String.slice(input_string, start_index..-1)
  end

  defp _get_event_name(abi, event_name_hashed) when is_list(abi) do
    abi
    |> Enum.filter(fn abi_entry -> abi_entry["type"] == "event" end)
    |> Map.new(fn abi_event ->
      {abi_event["name"]
       |> String.split(@event_module_separator)
       |> List.last()
       |> ExKeccak.hash_256()
       |> Base.encode16(case: :lower)
       |> last_n_characters(),
       List.last(String.split(abi_event["name"], @event_module_separator))}
    end)
    |> Map.get(
      last_n_characters(event_name_hashed),
      Utils.shorten_block_hash(event_name_hashed)
    )
  end

  defp _get_event_name(abi, event_name_hashed) do
    abi
    |> Jason.decode!()
    |> _get_event_name(event_name_hashed)
  end

  def get_event_name(%{keys: [event_name_hashed | _]} = _event, _network)
      when event_name_hashed in @common_event_hashes,
      do: @common_event_hash_to_name[event_name_hashed]

  def get_event_name(%{keys: [event_name_hashed | _]} = event, network) do
    get_class_at(event["block_number"], event["from_address"], network)
    |> Map.get("abi")
    |> _get_event_name(event_name_hashed)
  end

  def get_event_name(%{"keys" => [event_name_hashed | _]} = _event, _network)
      when event_name_hashed in @common_event_hashes,
      do: @common_event_hash_to_name[event_name_hashed]

  def get_event_name(%{"keys" => [event_name_hashed | _]} = event, network) do
    get_class_at(event["block_number"], event["from_address"], network)
    |> Map.get("abi")
    |> _get_event_name(event_name_hashed)
  end

  def internal_calls(tx, network) do
    {:ok, trace} = Gateway.trace_transaction(tx.hash, network)

    trace["function_invocation"]
    |> StarknetExplorerWeb.Utils.atomize_keys()
    |> flatten_internal_calls(0)
    |> Enum.with_index()
    |> Enum.map(fn {call_data, index} ->
      # TODO: this can be optimized because we are going out to the Rpc/DB for every call, but contracts might be repeated
      # (like in the case of CALL and DELEGATE call types) so those can be coalesced

      functions_data = Calldata.get_functions_data("latest", call_data.contract_address, network)
      {input_data, _structs} = Calldata.get_input_data(functions_data, call_data.selector)

      call_data =
        Map.put(
          call_data,
          :selector_name,
          input_data["name"] || default_internal_call_name(tx.type)
        )

      {index, call_data}
    end)
    |> Map.new()
  end

  defp default_internal_call_name(tx_type) do
    case tx_type do
      "L1_HANDLER" -> "handle_deposit"
      "DEPLOY_ACCOUNT" -> "constructor"
      _ -> "__execute__"
    end
  end

  defp flatten_internal_calls(%{internal_calls: inner_list_of_calls} = outer_map, height)
       when is_list(inner_list_of_calls) do
    outer_details = [
      %{
        call_type: outer_map.call_type,
        contract_address: outer_map.contract_address,
        caller_address: outer_map.caller_address,
        selector: Map.get(outer_map, :selector),
        scope: height
      }
    ]

    inner_details = Enum.flat_map(inner_list_of_calls, &flatten_internal_calls(&1, height + 1))

    outer_details ++ inner_details
  end

  defp flatten_internal_calls(%{internal_calls: []} = _outer_map, _height) do
    []
  end

  defp flatten_internal_calls(list, _height) when is_list(list) do
    []
  end

  def get_entity_count() do
    Map.new()
    |> Map.put(:message_count, Message.get_total_count())
    |> Map.put(:events_count, Events.get_total_count())
    |> Map.put(:transaction_count, Transaction.get_total_count())
  end
end
