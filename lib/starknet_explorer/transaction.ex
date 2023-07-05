defmodule StarknetExplorer.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:hash, :string, []}
  @invoke_tx_fields [
    :type,
    :hash,
    :calldata,
    :contract_address,
    :entry_point_selector,
    :signature,
    :max_fee,
    :nonce,
    :version
  ]

  @declare_tx_fields [
    :type,
    :hash,
    :chain_id,
    :contract_class,
    :compiled_class_hash,
    :sender_address,
    :signature
  ]
  @deploy_tx_fields [
    :type,
    :hash,
    :class_hash,
    :contract_address_salt,
    :version
  ]
  @primary_key {:hash, :string, []}
  schema "transactions" do
    field :constructor_calldata, :string
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
    belongs_to :block, StarknetExplorer.Block, foreign_key: :block_number
    timestamps()
  end

  def changeset(tx, attrs) do
    attrs = rename_rpc_fields(attrs)

    tx
    |> cast(
      attrs,
      @invoke_tx_fields ++
      @deploy_tx_fields ++
      @declare_tx_fields
    )
    |> validate_according_to_tx_type(attrs)
    |> unique_constraint(:hash)
  end

  defp rename_rpc_fields(rpc_tx = %{"transaction_hash" => th}) do
    rpc_tx |> Map.put("hash", th)
  end

  defp validate_according_to_tx_type(changeset, _tx = %{"type" => "INVOKE"}) do
    changeset
    |> validate_required(@invoke_tx_fields)
  end

  defp validate_according_to_tx_type(changeset, tx = %{"type" => "DEPLOY"}) do
    changeset
    |> validate_required(@deploy_tx_fields)
  end

  defp validate_according_to_tx_type(changeset, _tx = %{"type" => "DECLARE"}) do
    changeset
    |> validate_required(@declare_tx_fields)
  end
end
