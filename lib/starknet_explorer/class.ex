defmodule StarknetExplorer.Class do
  use Ecto.Schema
  alias StarknetExplorer.Repo
  import Ecto.Changeset

  @required [
    :block_number,
    :declared_at,
    :state_update_json,
    :hash
  ]

  @allowed [
             :abi,
             :sierra_program,
             :version
           ] ++ @required

  @primary_key {:hash, :string, []}
  schema "classes" do
    field :abi, :binary
    field :sierra_program, :binary
    field :declared_at, :integer
    field :version, :string
    field :state_update_json, :binary

    belongs_to :block, StarknetExplorer.Block, foreign_key: :block_number
    belongs_to :declared_by_address, StarknetExplorer.Contract, foreign_key: :declared_by

    belongs_to :declared_at_tx_hash, StarknetExplorer.Transaction,
      references: :hash,
      foreign_key: :declared_at_tx

    timestamps()
  end

  def changeset(contract, attrs) do
    contract
    |> cast(
      attrs,
      @allowed
    )
    |> assoc_constraint(:declared_by_address)
    |> assoc_constraint(:declared_at_tx_hash)
    |> validate_required(@required)
    |> unique_constraint(:hash)
  end

  # %{
  #   "block_hash" => "0x3ce9a44efa4249b7ce0fd98086e0c85e1950c294b12582f24044270f0606865",
  #   "new_root" => "0x60158cfc93d9f014637621b22055110feecc6eb9467d7db27df7f9b1c83e6db",
  #   "old_root" => "0x5cc14198af572e9446025dc096032c37acb8359e1ad8ddda671898ca65038d0",
  #   "state_diff" => %{
  #     "declared_classes" => [],
  #     "deployed_contracts" => [],
  #     "deprecated_declared_classes" => [],
  #     "nonces" => [],
  #     "replaced_classes" => [],
  #     "storage_diffs" => [
  #       %{
  #         "address" => "0x600014b24fa27caea849fda508691415c309d58c3d0c3f5f6a727c21c74651c",
  #         "storage_entries" => [
  #           %{
  #             "key" => "0x69e9637622f5264264216c56d845da3c86fe82c18264b7d739e882fa43b6323",
  #             "value" => "0x5554b3ea0e3041484fae5365dd8422b1ea348f48c9291994b88c408a7c8314d"
  #           }
  #         ]
  #       },
  #       %{
  #         "address" => "0x774febac9831e5ba1900937affd369c15ea5dc6f61ffd445d0cce7f794017a3",
  #         "storage_entries" => [
  #           %{
  #             "key" => "0x6e8d9eacb3a354f994389ceb900e9252911878571cf8bae0cbcbcc7ff558cb9",
  #             "value" => "0x7c7"
  #           }
  #         ]
  #       },
  #       %{
  #         "address" => "0x7e2690e57ac0706d29ca3084013fb75a3bd5de4277ea6545ee42dba6264b88b",
  #         "storage_entries" => [
  #           %{
  #             "key" => "0x6e8d9eacb3a354f994389ceb900e9252911878571cf8bae0cbcbcc7ff558cb9",
  #             "value" => "0x7e5"
  #           }
  #         ]
  #       }
  #     ]
  #   }
  # }

  @doc """
  Given a state_update from the RPC response, insert it into the database.
  """
  def insert_from_rpc_response(state_updates) do
    for state_update <- state_updates do
      # Store the original response, in case we need it
      # in the future, as a binary blob.
      original_json = :erlang.term_to_binary(state_update)
      sierra_program = Jason.encode!(state_update["sierra_program"]) |> :erlang.term_to_binary()
      abi = Jason.encode!(state_update["abi"]) |> :erlang.term_to_binary()

      changeset =
        changeset(
          %__MODULE__{},
          state_update
          |> Map.put("state_update_json", original_json)
          |> Map.put("sierra_program", sierra_program)
          |> Map.put("abi", abi)
        )

      {:ok, _} = Repo.insert(changeset)
    end

    :ok
  end

  def list(), do: Repo.all(__MODULE__)
end
