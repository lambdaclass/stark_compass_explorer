defmodule StarknetExplorer.Block do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias StarknetExplorer.{Repo, Transaction}
  require Logger
  @primary_key {:number, :integer, []}
  schema "blocks" do
    field :status, :string
    field :hash, :string
    field :parent_hash, :string
    field :new_root, :string
    field :timestamp, :integer
    field :sequencer_address, :string
    field :original_json, :binary
    has_many :transactions, StarknetExplorer.Transaction
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

  def list(), do: Repo.all(__MODULE__)

  @doc """
  Given a block from the RPC response, insert it into the database.
  """
  def insert_from_rpc_response(block = %{"transactions" => txs}) when is_map(block) do
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

    # Validate each transaction before inserting
    # the block into postgres. I think
    # this can be done with cast_assoc.
    transactions =
      txs
      |> Enum.map(fn tx ->
        Transaction.changeset(%Transaction{}, Map.put(tx, "block_number", block["number"]))
      end)

    changeset = changeset(%StarknetExplorer.Block{transactions: transactions}, block)

    case Repo.insert(changeset) do
      {:ok, _} ->
        :ok

      {:error, error} ->
        Logger.error("Failed to insert block: #{inspect(error)}")
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
end
