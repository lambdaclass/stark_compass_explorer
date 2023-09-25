defmodule StarknetExplorer.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias StarknetExplorer.{Transaction, Repo, TransactionReceipt}

  @l1_handler_tx_fields [
    :hash,
    :version,
    :type,
    :nonce,
    :contract_address,
    :entry_point_selector,
    :calldata
  ]

  @invoke_v0_tx_fields [
    :calldata,
    :contract_address,
    :entry_point_selector,
    :hash,
    :max_fee,
    :signature,
    :type,
    :version
  ]

  @invoke_v1_tx_fields [
    :calldata,
    :sender_address,
    :hash,
    :max_fee,
    :nonce,
    :signature,
    :type,
    :version
  ]

  @declare_tx_fields [
    :class_hash,
    :hash,
    :max_fee,
    :nonce,
    :sender_address,
    :signature,
    :type,
    :version
  ]

  @deploy_contract_tx_fields [
    :type,
    :hash,
    :class_hash,
    :contract_address_salt,
    :constructor_calldata,
    :version
  ]

  @deploy_account_tx_fields [
    :class_hash,
    :constructor_calldata,
    :contract_address_salt,
    :hash,
    :max_fee,
    :nonce,
    :signature,
    :type,
    :version
  ]

  @fields @l1_handler_tx_fields ++
            @invoke_v0_tx_fields ++
            @declare_tx_fields ++
            @deploy_contract_tx_fields ++
            @deploy_account_tx_fields ++
            [:network]

  @networks [:mainnet, :testnet, :testnet2]

  schema "transactions" do
    field :hash, :string
    field :constructor_calldata, {:array, :string}
    field :class_hash, :string
    field :type, :string
    field :max_fee, :string
    field :version, :string
    field :signature, {:array, :string}
    field :nonce, :string
    field :contract_address, :string
    field :contract_class, :string
    field :contract_address_salt, :string
    field :compiled_class_hash, :string
    field :entry_point_selector, :string
    field :chain_id, :string
    field :sender_address, :string
    field :calldata, {:array, :string}
    field :network, Ecto.Enum, values: @networks
    belongs_to :block, StarknetExplorer.Block, foreign_key: :block_number, references: :hash
    has_one :receipt, TransactionReceipt
    timestamps()
  end

  def changeset(tx, attrs = %{"transaction_hash" => hash}) do
    attrs = rename_rpc_fields(attrs)

    tx
    |> cast(
      attrs,
      @fields
    )
    |> Ecto.Changeset.change(%{hash: hash})
    |> unique_constraint([:hash])
    |> validate_according_to_tx_type(attrs)
  end

  def from_rpc_tx(rpc_tx) do
    struct(%__MODULE__{}, rpc_tx |> rename_rpc_fields |> StarknetExplorerWeb.Utils.atomize_keys())
  end

  def get_by_hash(hash) do
    query =
      from tx in Transaction,
        where: tx.hash == ^hash

    Repo.one(query)
  end

  def get_missing_tx_receipt(limit \\ 10, network) do
    query =
      from t in Transaction,
        left_join: rc in assoc(t, :receipt),
        where: t.network == ^network and is_nil(rc),
        limit: ^limit

    Repo.all(query)
  end

  def get_by_hash_with_receipt(hash) do
    query =
      from tx in Transaction,
        where: tx.hash == ^hash

    case Repo.one(query) do
      nil ->
        nil

      tx ->
        Repo.preload(tx, :receipt)
    end
  end

  def rename_rpc_fields(rpc_tx = %{"transaction_hash" => th}) do
    rpc_tx
    |> Map.delete("transaction_hash")
    |> Map.put("hash", th)
  end

  defp validate_according_to_tx_type(changeset, _tx = %{"type" => "INVOKE", "version" => "0x1"}) do
    changeset
    |> validate_required(@invoke_v1_tx_fields)
  end

  defp validate_according_to_tx_type(changeset, _tx = %{"type" => "INVOKE"}) do
    changeset
    |> validate_required(@invoke_v0_tx_fields)
  end

  defp validate_according_to_tx_type(changeset, _tx = %{"type" => "DEPLOY", "max_fee" => _}) do
    changeset
    |> validate_required(@deploy_account_tx_fields)
  end

  defp validate_according_to_tx_type(changeset, _tx = %{"type" => "DEPLOY_ACCOUNT"}) do
    changeset
    |> validate_required(@deploy_account_tx_fields)
  end

  defp validate_according_to_tx_type(changeset, _tx = %{"type" => "DEPLOY"}) do
    changeset
    |> validate_required(@deploy_contract_tx_fields)
  end

  defp validate_according_to_tx_type(changeset, _tx = %{"type" => "DECLARE"}) do
    changeset
    |> validate_required(@declare_tx_fields)
  end

  defp validate_according_to_tx_type(changeset, _tx = %{"type" => "L1_HANDLER"}) do
    changeset
    |> validate_required(@l1_handler_tx_fields)
  end

  def get_total_count(network \\ :mainnet) do
    Repo.one(
      from t in StarknetExplorer.Transaction,
        where: t.network == ^network,
        select: count(t.hash)
    )
  end
end
