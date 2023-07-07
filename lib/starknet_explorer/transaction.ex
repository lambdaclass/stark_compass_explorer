defmodule StarknetExplorer.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @l1_handler_tx_fields [
    :hash,
    :version,
    :type,
    :nonce,
    :contract_address,
    :entry_point_selector,
    :calldata
  ]

  @invoke_tx_fields [
    :calldata,
    :contract_address,
    :entry_point_selector,
    :hash,
    :max_fee,
    :nonce,
    :signature,
    :type,
    :version
  ]

  @invoke_v1_tx_fields [
    :calldata,
    :sender_address,
    :entry_point_selector,
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
    :type,
    :version
  ]

  @fields @l1_handler_tx_fields ++
            @invoke_tx_fields ++
            @declare_tx_fields ++ @deploy_contract_tx_fields ++ @deploy_account_tx_fields

  @primary_key {:hash, :string, []}
  schema "transactions" do
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
    belongs_to :block, StarknetExplorer.Block, foreign_key: :block_number
    timestamps()
  end

  def changeset(tx, attrs) do
    attrs = rename_rpc_fields(attrs)

    tx
    |> cast(
      attrs,
      @fields
    )
    |> validate_according_to_tx_type(attrs)
    |> unique_constraint(:hash)
  end

  defp rename_rpc_fields(rpc_tx = %{"transaction_hash" => th}) do
    rpc_tx |> Map.put("hash", th)
  end

  defp validate_according_to_tx_type(changeset, _tx = %{"type" => "INVOKE", "version" => "0x1"}) do
    changeset
    |> validate_required(@invoke_v1_tx_fields)
  end

  defp validate_according_to_tx_type(changeset, _tx = %{"type" => "INVOKE"}) do
    changeset
    |> validate_required(@invoke_tx_fields)
  end

  defp validate_according_to_tx_type(changeset, tx = %{"type" => "DEPLOY", "max_fee" => _}) do
    changeset
    |> validate_required(@deploy_account_tx_fields)
  end

  defp validate_according_to_tx_type(changeset, tx = %{"type" => "DEPLOY"}) do
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
end
