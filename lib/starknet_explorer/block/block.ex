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
    :network
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

    has_many :transactions, StarknetExplorer.Transaction,
      foreign_key: :block_number,
      references: :number

    timestamps()
  end

  def changeset(block = %__MODULE__{}, attrs) do
    block
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:number)
    |> unique_constraint(:hash)
  end

  @doc """
  Given a block from the RPC response, and transactions receipts
  insert them into the DB.
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

    events =
      block["hash"]
      |> Events.fetch_from_rpc(network)
      |> Enum.with_index(fn %{"keys" => keys} = event, index ->
        event
        |> Map.put("network", network)
        |> Map.put("age", block["timestamp"])
        |> Map.put("index_in_block", index)
        |> Map.put("block_number", block["number"])
        |> Map.put("name", Events.get_event_name(event, network))
        |> Map.put("name_hashed", List.first(keys))
      end)

    transaction_result =
      StarknetExplorer.Repo.transaction(fn ->
        block_changeset = Block.changeset(%Block{}, block)

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

        Enum.each(events, fn event ->
          IO.inspect(event)
          {:ok, _event} = Events.insert(event)
        end)
      end)

    case transaction_result do
      {:ok, _} ->
        :ok

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

  def get_by_hash(hash, network) do
    query =
      from b in Block,
        where: b.hash == ^hash and b.network == ^network

    Repo.one(query)
    |> Repo.preload(:transactions)
  end

  def get_by_num(num, network) do
    query =
      from b in Block,
        where: b.number == ^num and b.network == ^network

    Repo.one(query)
    |> Repo.preload(:transactions)
  end

  def get_by_height(height, network) when is_integer(height) do
    query =
      from b in Block,
        where: b.number == ^height and b.network == ^network

    Repo.one(query)
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

  def update_block_gas_and_resources(block_number, gas_fee, execution_resources, network)
      when is_number(block_number) do
    query =
      from b in Block,
        where: b.number == ^block_number and b.network == ^network

    Repo.update_all(query,
      set: [gas_fee_in_wei: gas_fee, execution_resources: execution_resources]
    )
  end
end
