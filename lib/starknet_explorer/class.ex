defmodule StarknetExplorer.Class do
  use Ecto.Schema
  alias StarknetExplorer.Repo
  import Ecto.Changeset
  import Ecto.Query

  @required [
    :block_number,
    :declared_at,
    :class_json,
    :hash
  ]

  @allowed [
             :abi,
             :sierra_program,
             :version,
             :declared_at_tx,
             :declared_by
           ] ++ @required

  @primary_key {:hash, :string, []}
  schema "classes" do
    field :abi, :binary
    field :sierra_program, :binary
    field :declared_at, :integer
    field :version, :string
    field :class_json, :binary

    belongs_to :block, StarknetExplorer.Block, foreign_key: :block_number

    belongs_to :declared_by_address, StarknetExplorer.Contract,
      foreign_key: :declared_by,
      type: :string

    belongs_to :declared_at_tx_hash, StarknetExplorer.Transaction,
      references: :hash,
      foreign_key: :declared_at_tx,
      type: :string

    timestamps()
  end

  def changeset(contract, attrs) do
    contract
    |> cast(
      attrs,
      @allowed
    )
    |> assoc_constraint(:block)
    |> assoc_constraint(:declared_by_address)
    |> assoc_constraint(:declared_at_tx_hash)
    |> validate_required(@required)
    |> unique_constraint(:hash, name: :classes_pkey)
  end

  @doc """
  Given a state_update from the RPC response, insert it into the database.
  """
  def insert_from_rpc_response(class) do
    # Store the original response, in case we need it
    # in the future, as a binary blob.
    original_json = :erlang.term_to_binary(class)
    sierra_program = Jason.encode!(class["sierra_program"]) |> :erlang.term_to_binary()
    abi = Jason.encode!(class["abi"]) |> :erlang.term_to_binary()

    changeset =
      changeset(
        %__MODULE__{},
        class
        |> Map.put("class_json", original_json)
        |> Map.put("sierra_program", sierra_program)
        |> Map.put("abi", abi)
      )

    case Repo.insert(changeset) do
      {:ok, _} ->
        :ok

      {:error, failed} ->
        :error
    end
  end

  def get_by_hash(hash), do: Repo.get_by(__MODULE__, hash: hash)

  def list_all(), do: Repo.all(__MODULE__)

  def list(limit \\ 20),
    do: Repo.all(from c in __MODULE__, limit: ^limit, order_by: c.inserted_at)
end
