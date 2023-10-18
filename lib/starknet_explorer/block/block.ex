defmodule StarknetExplorer.Block do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias StarknetExplorer.Events
  alias StarknetExplorer.{Repo, Transaction, Block, Message}
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.TransactionReceipt, as: Receipt
  require Logger
  @networks [:mainnet, :testnet, :testnet2]
  @cast_fields [
    :number,
    :status,
    :hash,
    :parent_hash,
    :new_root,
    :timestamp,
    :sequencer_address,
    :gas_fee_in_wei,
    :execution_resources,
    :network,
    :state_updated
  ]

  @required_fields [
    :number,
    :status,
    :hash,
    :parent_hash,
    :new_root,
    :timestamp,
    :network
  ]

  @primary_key {:number, :integer, []}
  schema "blocks" do
    field :status, :string
    field :hash, :string
    field :parent_hash, :string
    field :new_root, :string
    field :timestamp, :integer
    field :sequencer_address, :string, default: ""
    field :gas_fee_in_wei, :string
    field :execution_resources, :integer
    field :network, Ecto.Enum, values: @networks
    field :state_updated, :boolean, default: false

    has_many :transactions, StarknetExplorer.Transaction,
      foreign_key: :block_number,
      references: :number

    timestamps()
  end

  def changeset(block = %__MODULE__{}, attrs) do
    block
    |> cast(attrs, @cast_fields)
  end

  def changeset_with_validations(block = %__MODULE__{}, attrs) do
    block
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
  end

  @doc """
  Given a block from the RPC response, our block from SQL, and transactions receipts
  update them into the DB.
  """
  def update_from_rpc_response(
        block_from_sql,
        _block_from_rpc = %{
          "status" => status,
          "gas_fee_in_wei" => gas_fee_in_wei,
          "execution_resources" => execution_resources
        },
        receipts
      ) do
    tx_receipts =
      Enum.map(receipts, fn {tx_hash, rpc_receipt} ->
        sql_receipt =
          Enum.find(block_from_sql.transactions, fn tx ->
            tx.receipt.transaction_hash == tx_hash
          end).receipt

        {sql_receipt, rpc_receipt}
      end)

    {contracts, classes} =
      if not block_from_sql.state_updated do
        # Here, i want to create the changesets for the contracts and classes in the state update.
        # Then, use those changesets to update the contracts and classes in the database through the Block.insert_from_rpc_response method.

        # The classes changeset should be created using the "declared_classes" and "deprecated_declared_classes" from the "state_diff" field in the state_update.
        # Also, we need to add the "network" field to the changeset and the version field, using "Cairo 1.0" for the "declared_classes" and "Cairo 0" for the "deprecated_declared_classes".
        {:ok, state_update} =
          StarknetExplorer.Rpc.get_state_update(
            %{"block_number" => block_from_sql.number},
            block_from_sql.network
          )

        deployed_contracts =
          Enum.map(state_update["state_diff"]["deployed_contracts"], fn contract ->
            StarknetExplorer.Contract.changeset(%StarknetExplorer.Contract{}, %{
              "timestamp" => block_from_sql.timestamp,
              "nonce" => "0",
              "network" => block_from_sql.network,
              "class_hash" => contract["class_hash"],
              "address" => contract["address"]
            })

            # Missing fields:
            # field :deployed_by_address, :string -> Look for a workaround
            # field :version, :string -> Extract from class.
            # field :balance, :string -> IDK
            # field :type, :string -> IDK.
            # belongs_to :deployed_at_transaction, StarknetExplorer.Transaction, references: :hash -> Look for a workaround
          end)

        declared_classes_changeset =
          Enum.reduce(block_from_sql.transactions, [], fn tx, acc ->
            if tx.type == "DECLARE" do
              acc ++
                [
                  StarknetExplorer.Class.changeset(%StarknetExplorer.Class{}, %{
                    "timestamp" => block_from_sql.timestamp,
                    "network" => block_from_sql.network,
                    "hash" => tx.class_hash,
                    "version" => tx.version,
                    "declared_at_transaction" => tx.hash,
                    "declared_by_address" => tx.sender_address
                  })
                ]
            else
              acc
            end
          end)

        {deployed_contracts, declared_classes_changeset}
      else
        {[], []}
      end

    StarknetExplorer.Repo.transaction(fn ->
      block_changeset =
        Ecto.Changeset.change(block_from_sql,
          status: status,
          gas_fee_in_wei: gas_fee_in_wei,
          execution_resources: execution_resources,
          state_updated: true
        )

      Repo.update!(block_changeset)

      Enum.each(tx_receipts, fn {tx_receipt, rpc_tx_receipt} ->
        tx_receipt_changeset =
          Ecto.Changeset.change(tx_receipt,
            actual_fee: rpc_tx_receipt["actual_fee"],
            finality_status: rpc_tx_receipt["finality_status"],
            execution_status: rpc_tx_receipt["execution_status"]
          )

        Repo.update!(tx_receipt_changeset)

        Enum.each(classes, fn changeset ->
          {:ok, _} = Repo.insert(changeset)
        end)

        Enum.each(contracts, fn changeset ->
          {:ok, _} = Repo.insert(changeset)
        end)
      end)
    end)
  end

  @doc """
  Given a block from the RPC response, and transactions receipts
  insert them into the DB.
  If the insertion was made, return a tuple of the form:
  {
    :ok,
    amount_blocks, # The amount of blocks inserted.
    amount_transaction, # The amount of transactions inserted.
    amount_events, # The amount of events inserted.
    amount_messages, # The amount of messages inserted.
  }
  If an error occurs, returns:
  {
    :err,
    err # The error.
  }
  """
  def insert_from_rpc_response(block = %{"transactions" => txs}, receipts, network)
      when is_map(block) do
    # This is a bit awful, and I'm sure Ecto/Elixir
    # has a better way of doing this.
    # I rename some fields from the RPC response to
    # match the fields in the schema.
    block =
      block
      |> rename_rpc_fields
      |> Map.put("network", network)
      |> Map.put("state_updated", true)

    events_from_rpc =
      block["hash"]
      |> Events.fetch_from_rpc(network)

    events =
      events_from_rpc
      |> Enum.with_index(fn %{"keys" => keys} = event, index ->
        event
        |> Map.put("network", network)
        |> Map.put("age", block["timestamp"])
        |> Map.put("index_in_block", index)
        |> Map.put("block_number", block["number"])
        |> Map.put("name", Events.get_event_name(event, network))
        |> Map.put("name_hashed", List.first(keys))
      end)

    # Here, i want to create the changesets for the contracts and classes in the state update.
    # Then, use those changesets to update the contracts and classes in the database through the Block.insert_from_rpc_response method.

    # The classes changeset should be created using the "declared_classes" and "deprecated_declared_classes" from the "state_diff" field in the state_update.
    # Also, we need to add the "network" field to the changeset and the version field, using "Cairo 1.0" for the "declared_classes" and "Cairo 0" for the "deprecated_declared_classes".
    {:ok, state_update} =
      StarknetExplorer.Rpc.get_state_update(%{"block_number" => block["number"]}, network)

    deployed_contracts =
      Enum.map(state_update["state_diff"]["deployed_contracts"], fn contract ->
        StarknetExplorer.Contract.changeset(%StarknetExplorer.Contract{}, %{
          "timestamp" => block["timestamp"],
          "nonce" => "0",
          "network" => network,
          "class_hash" => contract["class_hash"],
          "address" => contract["address"]
        })

        # Missing fields:
        # field :deployed_by_address, :string -> Look for a workaround
        # field :version, :string -> Extract from class.
        # field :balance, :string -> IDK
        # field :type, :string -> IDK.
        # belongs_to :deployed_at_transaction, StarknetExplorer.Transaction, references: :hash -> Look for a workaround
      end)

    declared_classes_changeset =
      Enum.reduce(block["transactions"], [], fn tx, acc ->
        if tx["type"] == "DECLARE" do
          acc ++
            [
              StarknetExplorer.Class.changeset(%StarknetExplorer.Class{}, %{
                "timestamp" => block["timestamp"],
                "network" => network,
                "hash" => tx["class_hash"],
                "version" => tx["version"],
                "declared_at_transaction" => tx["hash"],
                "declared_by_address" => tx["sender_address"]
              })
            ]
        else
          acc
        end
      end)

    transaction_result =
      StarknetExplorer.Repo.transaction(fn ->
        block_changeset = Block.changeset_with_validations(%Block{}, block)

        {:ok, block} = Repo.insert(block_changeset)

        _txs_changeset =
          Enum.map(txs, fn tx ->
            tx = tx |> Map.put("network", network)

            inserted_tx =
              Ecto.build_assoc(block, :transactions, tx)
              |> Transaction.changeset(tx)
              |> Repo.insert!()

            receipt = receipts[inserted_tx.hash] |> Map.put("network", network)

            receipt =
              receipt
              |> Map.put("timestamp", block.timestamp)
              |> Map.put("block_hash", block.hash)
              |> Map.put("block_number", block.number)

            Ecto.build_assoc(inserted_tx, :receipt, receipt)
            |> Receipt.changeset(receipt)
            |> Repo.insert!()

            Message.insert_from_transaction_receipt(receipt, network)
            Message.insert_from_transaction(inserted_tx, block.timestamp, network)
          end)

        Enum.each(declared_classes_changeset, fn changeset ->
          {:ok, _} = Repo.insert(changeset)
        end)

        Enum.each(deployed_contracts, fn changeset ->
          {:ok, _} = Repo.insert(changeset)
        end)

        Enum.each(events, fn event -> {:ok, _event} = Events.insert(event) end)
      end)

    amount_messages =
      Enum.reduce(receipts, 0, fn {_tx_hash, receipt}, acc ->
        acc + length(receipt["messages_sent"])
      end) +
        Enum.reduce(txs, 0, fn tx, acc ->
          if tx["type"] == "L1_HANDLER" do
            acc + 1
          else
            acc
          end
        end)

    case transaction_result do
      {:ok, _} ->
        {:ok, 1, length(txs), length(events), amount_messages}

      {:error, err} ->
        Logger.error("Error inserting block: #{inspect(err)}")
        :error
    end
  end

  def from_rpc_block(rpc_block, network) do
    rpc_block =
      rpc_block |> rename_rpc_fields |> Map.put("network", network) |> Utils.atomize_keys()

    struct(__MODULE__, rpc_block)
  end

  @doc """
  This function will return the lowest continuous block starting from the highest one
  stored so far. Note this is not the same as the lowest block. Example:

  If we have stored the blocks [5, 6, 20, 21, 22], this returns `20`, not `5`.
  We are using this for the block fetcher logic, where we want to go downwards in order.
  The problem is a block with a lower number could be added by someone visiting a details
  page for a block, so we need to account for that.
  """
  def get_lowest_block_number(network) do
    Repo.query(
      "SELECT  number - 1
    FROM    blocks block
    WHERE   NOT EXISTS
            (
            SELECT  NULL
            FROM    blocks mi
            WHERE   mi.number = block.number - 1 AND mi.network = $1
            ) AND block.network = $1
    ORDER BY number DESC
    LIMIT 1",
      [network]
    )
  end

  @doc """
  Returns the highest block number stored in the DB.
  """
  def block_height(network) do
    query =
      from(b in Block,
        where: b.network == ^network,
        order_by: [desc: b.number],
        limit: 1
      )

    Repo.one(query)
  end

  @doc """
  Returns the highest block number fetched from the RPC.
  """
  def highest_fetched_block_number(network) do
    query =
      from b in "blocks",
        select: [:number],
        order_by: [desc: b.number],
        limit: 1,
        where: b.network == ^network

    case Repo.all(query) do
      [] -> 0
      [%{number: number}] -> number
    end
  end

  @doc """
  Returns the n latests blocks
  """
  def latest_n_blocks(n \\ 20, network) do
    query =
      from b in Block,
        order_by: [desc: b.number],
        limit: ^n,
        where: b.network == ^network

    Repo.all(query)
  end

  @doc """
  Returns amount blocks starting at block number up_to
  """
  def latest_blocks_with_txs(amount, network) do
    query =
      from b in Block,
        order_by: [desc: b.number],
        where: b.network == ^network,
        limit: ^amount

    query
    |> Repo.all()
    |> Repo.preload(:transactions)
  end

  @doc """
  Returns amount blocks starting at block number up_to
  """
  def latest_blocks(amount, network) do
    query =
      from b in Block,
        order_by: [desc: b.number],
        where: b.network == ^network,
        limit: ^amount

    query
    |> Repo.all()
  end

  def rename_rpc_fields(rpc_block) do
    rpc_block
    |> Map.new(fn
      {"block_hash", hash} ->
        {"hash", hash}

      {"block_number", number} ->
        {"number", number}

      {"transactions", transactions} ->
        {"transactions", Enum.map(transactions, &Transaction.rename_rpc_fields/1)}

      {k, v} ->
        {k, v}
    end)
  end

  def get_by_hash(hash, network, preload_transactions \\ true) do
    query =
      from b in Block,
        where: b.hash == ^hash and b.network == ^network

    case preload_transactions do
      true ->
        Repo.one(query)
        |> Repo.preload(:transactions)

      false ->
        Repo.one(query)
    end
  end

  def get_by_partial_hash(hash, network) do
    query =
      from b in Block,
        order_by: [desc: b.hash],
        where: b.hash == ^hash and b.network == ^network,
        limit: 25

    Repo.all(query)
  end

  def get_by_num(num, network, preload_transactions \\ true) do
    query =
      from b in Block,
        where: b.number == ^num and b.network == ^network

    # These try catches are to guard against people sending big numbers that
    # make postgres raise because the number doesn't fit.
    case preload_transactions do
      true ->
        try do
          Repo.one(query)
          |> Repo.preload(:transactions)
        rescue
          _ ->
            nil
        end

      false ->
        try do
          Repo.one(query)
        rescue
          _ ->
            nil
        end
    end
  end

  def get_by_number_with_receipts_preload(num, network) do
    query =
      from b in Block,
        where: b.number == ^num and b.network == ^network,
        preload: [transactions: :receipt]

    Repo.one(query)
    |> Repo.preload(:transactions)
  end

  def get_by_partial_num(num, network) do
    query =
      from b in Block,
        where: ^num == b.number and b.network == ^network

    Repo.all(query)
  end

  def get_by_height(height, network) when is_integer(height) do
    query =
      from b in Block,
        where: b.number == ^height and b.network == ^network

    Repo.one(query)
  end

  def get_lowest_not_completed_block(network) do
    query =
      from b in Block,
        where:
          b.status != "ACCEPTED_ON_L1" or is_nil(b.gas_fee_in_wei) or b.gas_fee_in_wei == "" or
            is_nil(b.execution_resources) or b.state_updated == false,
        where: b.network == ^network,
        limit: 1,
        order_by: [asc: b.number]

    Repo.one(query)
  end

  def get_with_not_finalized_blocks(limit \\ 10, network) do
    query =
      from b in Block,
        where: b.status != "ACCEPTED_ON_L1",
        where: b.network == ^network,
        limit: ^limit,
        order_by: [asc: :number]

    Repo.all(query)
  end

  def get_with_missing_gas_fees_or_resources(limit \\ 10, network) do
    query =
      from b in Block,
        where:
          is_nil(b.gas_fee_in_wei) or b.gas_fee_in_wei == "" or is_nil(b.execution_resources),
        where: b.network == ^network,
        limit: ^limit

    Repo.all(query)
  end

  def paginate_blocks(params, network) do
    Block
    |> where([b], b.network == ^network)
    |> order_by(desc: :number)
    |> Repo.paginate(params)
  end

  def update_block_gas_and_resources(block_number, gas_fee, execution_resources, network)
      when is_number(block_number) do
    query =
      from b in Block,
        where: b.number == ^block_number and b.network == ^network

    Repo.update_all(query,
      set: [gas_fee_in_wei: gas_fee, execution_resources: execution_resources]
    )
  end

  def update_block_status(block_number, status, network) do
    query =
      from b in Block,
        where: b.number == ^block_number and b.network == ^network

    Repo.update_all(query,
      set: [status: status]
    )
  end
end
