defmodule StarknetExplorer.Data do
  alias StarknetExplorer.{Rpc, Transaction, Block, TransactionReceipt, Calldata}

  @implementation_selector "0x3a0ed1f62da1d3048614c2c1feb566f041c8467eb00fb8294776a9179dc1643"
  @implementation_hash_selector "0x1d15dd5e6cac14c959221a0b45927b113a91fcfffa4c7bbab19b28d345467df"

  @doc """
  Fetch `block_amount` blocks (defaults to 15), first
  look them up in the db, if not found check the RPC
  provider.
  """
  def many_blocks(network, block_amount \\ 15) do
    block_number = StarknetExplorer.Data.latest_block_number(network)
    blocks = Block.latest_blocks_with_txs(block_amount, block_number)
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

          Block.from_rpc_block(block)
        end)
    end
  end

  @doc """
  Fetch a block by its hash, first look up in
  the db, if not found, fetch from the RPC provider
  """
  def block_by_hash(hash, network) do
    case Block.get_by_hash(hash) do
      nil ->
        {:ok, block} = Rpc.get_block_by_hash(hash, network)

        block = Block.from_rpc_block(block)
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
    case Block.get_by_num(number) do
      nil ->
        {:ok, block} = Rpc.get_block_by_number(number, network)

        block = Block.from_rpc_block(block)
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
      # if receipts are not found in the db, split the txs in chunks and get receipts by RPC
      [] ->
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

        {:ok, all_receipts}

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

  def full_transaction(tx_hash, network) do
    tx =
      case Transaction.get_by_hash_with_receipt(tx_hash) do
        nil ->
          {:ok, tx} = Rpc.get_transaction(tx_hash, network)
          {:ok, receipt} = Rpc.get_transaction_receipt(tx_hash, network)

          block_id =
            if receipt["block_number"],
              do: %{"block_number" => receipt["block_number"]},
              else: "latest"

          {:ok, contract} =
            Rpc.get_class_at(block_id, tx["sender_address"], network)

          calldata =
            Calldata.from_plain_calldata(tx["calldata"], contract["contract_class_version"])

          input_data =
            Enum.map(
              calldata,
              fn call ->
                input = get_input_data(block_id, call.address, call.selector, network)
                Map.put(call, :call, Calldata.as_fn_call(input, call.calldata))
              end
            )

          tx
          |> Transaction.from_rpc_tx()
          |> Map.put(:receipt, receipt |> StarknetExplorerWeb.Utils.atomize_keys())
          |> Map.put(:input_data, input_data)

        tx ->
          tx
      end

    {:ok, tx}
  end

  def get_input_data(block_id, address, selector, network) do
    case Rpc.get_class_at(block_id, address, network) do
      {:ok, class} ->
        cond do
          has_selector?(class, @implementation_selector) ->
            {:ok, [implementation_address]} =
              Rpc.call(block_id, address, @implementation_selector, network)

            get_input_data(block_id, implementation_address, selector, network)

          has_selector?(class, @implementation_hash_selector) ->
            {:ok, [implementation_hash]} =
              Rpc.call(block_id, address, @implementation_hash_selector, network)

            get_input_data_for_hash(block_id, implementation_hash, selector, network)

          true ->
            Enum.find(
              class["abi"],
              fn elem ->
                elem["name"] |> Calldata.keccak() == selector
              end
            )
        end

      {:error, error} ->
        error |> IO.inspect()
        nil
    end
  end

  def get_input_data_for_hash(block_id, class_hash, selector, network) do
    case Rpc.get_class(block_id, class_hash, network) do
      {:ok, class} ->
        Enum.find(
          class["abi"],
          fn elem ->
            elem["name"] |> Calldata.keccak() == selector
          end
        )

      {:error, error} ->
        error |> IO.inspect()
        nil
    end
  end

  def has_selector?(class, selector) do
    Enum.any?(
      class["entry_points_by_type"]["EXTERNAL"],
      fn elem ->
        elem["selector"] == selector
      end
    )
  end

  def get_block_events_paginated(block_hash, pagination, network) do
    {:ok, events} = Rpc.get_block_events_paginated(block_hash, pagination, network)

    events
  end
end
