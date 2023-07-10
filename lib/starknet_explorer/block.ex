defmodule StarknetExplorer.Block do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias StarknetExplorer.{Repo, Transaction, Block}
  alias StarknetExplorer.TransactionReceipt, as: Receipt
  require Logger
  @primary_key {:number, :integer, []}
  schema "blocks" do
    field :status, :string
    field :hash, :string
    field :parent_hash, :string
    field :new_root, :string
    field :timestamp, :integer
    field :sequencer_address, :string
    field :original_json, :binary, load_in_query: false
    has_many :transactions, StarknetExplorer.Transaction, foreign_key: :block_number
    timestamps()
  end

  def changeset(block = %__MODULE__{}, attrs) do
    block
    |> cast(attrs, [
      :number,
      :status,
      :hash,
      :parent_hash,
      :new_root,
      :timestamp,
      :sequencer_address,
      # :transactions
      :original_json
    ])
    |> validate_required([
      :number,
      :status,
      :hash,
      :parent_hash,
      :new_root,
      :timestamp,
      :sequencer_address,
      :original_json
    ])
    |> unique_constraint(:number)
    |> unique_constraint(:hash)
  end

  @doc """
  Given a block from the RPC response, insert it into the database.
  """
  def insert_from_rpc_response(block = %{"transactions" => txs}, receipts) when is_map(block) do
    # Store the original response, in case we need it
    # in the future, as a binary blob.
    original_json = :erlang.term_to_binary(block)

    # This is a bit awful, and I'm sure Ecto/Elixir
    # has a better way of doing this.
    # I rename some fields from the RPC response to
    # match the fields in the schema.
    block =
      block
      |> Map.new(fn
        {"block_hash", hash} -> {"hash", hash}
        {"block_number", number} -> {"number", number}
        {k, v} -> {k, v}
      end)
      |> Map.put("original_json", original_json)

    transaction_result =
      StarknetExplorer.Repo.transaction(fn ->
        block_changeset = Block.changeset(%Block{original_json: original_json}, block)

        {:ok, block} = Repo.insert(block_changeset)

        _txs_changeset =
          Enum.map(txs, fn tx ->
            tx =
              Ecto.build_assoc(block, :transactions, tx)
              |> Transaction.changeset(tx)
              |> Repo.insert!()

            Ecto.build_assoc(tx, :receipt, receipts[tx.hash])
            |> Receipt.changeset(receipts[tx.hash])
            |> Repo.insert!()
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

  @doc """
  Returns the highest block number fetched from the RPC.
  """
  def highest_fetched_block_number() do
    query =
      from b in "blocks",
        select: [:number],
        order_by: [desc: b.number],
        limit: 1

    case Repo.all(query) do
      [] -> 0
      [%{number: number}] -> number
    end
  end

  @doc """
  Returns the n latests blocks
  """
  def latest_n_blocks(n \\ 20) do
    query =
      from b in Block,
        order_by: [desc: b.number],
        limit: ^n

    Repo.all(query)
  end

  @doc """
  Returns the n latests blocks
  """
  def latest_n_blocks_with_txs(n \\ 20) do
    query =
      from b in Block,
        order_by: [desc: b.number],
        limit: ^n

    Repo.all(query) |> Repo.preload(:transactions)
  end
end
