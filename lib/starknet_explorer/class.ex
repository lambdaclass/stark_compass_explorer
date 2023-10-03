defmodule StarknetExplorer.Class do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias StarknetExplorer.{Repo, Rpc}

  @primary_key {:class_hash, :string, autogenerate: false}

  @required_fields [
    :class_hash,
    :version,
    :network
  ]

  @fields @required_fields ++
            [
              :name,
              :type,
              :declared_by_contract_address,
              :declared_at_transaction_hash,
              :timestamp,
              :entry_points_by_type,
              :abi,
              :program,
              :sierra_program
            ]

  schema "classes" do
    field :name, :string
    field :type, :string
    field :declared_by_contract_address, :string
    field :declared_at_transaction_hash, :string
    field :timestamp, :integer
    field :version, :string
    field :abi, {:array, :map}
    field :entry_points_by_type, :map
    field :program, :string
    field :sierra_program, {:array, :string}
    field :network, Ecto.Enum, values: [:mainnet, :testnet, :testnet2]
    timestamps()
  end

  def changeset(class, params) do
    class
    |> cast(params, @fields)
    |> foreign_key_constraint(:declared_by_contract_address)
    |> foreign_key_constraint(:declared_at_transaction_hash)
    |> validate_required(@required_fields)
  end

  def insert(class) do
    %StarknetExplorer.Class{}
    |> changeset(class)
    |> Repo.insert(on_conflict: :nothing)
  end

  def get_by_hash(class_hash, network) do
    query =
      from class in StarknetExplorer.Class,
        where: class.class_hash == ^class_hash and class.network == ^network,
        limit: 1

    Repo.one(query)
  end

  def latest_n_messages(network, n \\ 20) do
    query =
      from class in StarknetExplorer.Class,
        order_by: [desc: class.timestamp],
        where: class.network == ^network,
        limit: ^n

    Repo.all(query)
  end

  def from_rpc_class(rpc_class) do
    struct(%__MODULE__{}, rpc_class |> StarknetExplorerWeb.Utils.atomize_keys())
  end

  def get_version(nil) do
    "0"
  end

  def get_version(value) do
    value
  end

  def get_abi(abi) when is_binary(abi) do
    Jason.decode!(abi)
  end

  def get_abi(abi) do
    abi
  end

  def fetch_from_rpc(block = %{"transactions" => transactions}, network) do
    transactions
    |> Enum.filter(&(&1["type"] == "DECLARE"))
    |> Enum.chunk_every(75)
    |> Enum.flat_map(fn chunk ->
      tasks =
        Enum.map(chunk, fn _tx = %{"class_hash" => class_hash} ->
          Task.async(fn ->
            {:ok, class} =
              Rpc.get_class(%{"block_number" => block["number"]}, class_hash, network)

            class
            |> Map.put("class_hash", class_hash)
            # Transaction and block data must be retrieved from first class declaration.
            # we cannot assure it's the first one at this point
            #
            # |> Map.put("declared_at_transaction_hash", tx["hash"])
            # |> Map.put("declared_by_contract_address", tx["sender_address"])
            # |> Map.put("timestamp", block["timestamp"])
            |> Map.put("abi", get_abi(class["abi"]))
            |> Map.put("version", get_version(class["contract_class_version"]))
            |> Map.put("network", network)
          end)
        end)

      Enum.map(tasks, &Task.await(&1, 7500))
    end)
  end
end
