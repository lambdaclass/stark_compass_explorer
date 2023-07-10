defmodule StarknetExplorer.TransactionReceipt do
  use Ecto.Schema
  import Ecto.Changeset
  alias StarknetExplorer.{Transaction, TransactionReceipt}

  @required_receipt_fields [
    :type,
    :status,
    :block_number,
    :block_hash,
    :block_number,
    :actual_fee
  ]

  @invoke_tx_receipt_fields @required_receipt_fields
  @declare_tx_fields @required_receipt_fields ++ [:contract_address]
  @deploy_tx_fields @required_receipt_fields ++ [:contract_address]
  @deploy_account_tx_fields @required_receipt_fields ++ [:status]
  @pending_deploy_fields @required_receipt_fields ++ [:contract_address]

  schema "transaction_receipts" do
    belongs_to :transaction, Transaction
    field :type, :string
    field :actual_fee, :string
    field :status, :string
    field :block_hash, :string
    field :block_number, :integer
    field :messages_sent, {:array, :map}
    field :messages, {:array, :map}
    field :events, {:array, :map}
    field :contract_address
    timestamps()
  end

  def changeset(receipt, attrs) do
    receipt
    |> cast(
      attrs,
      @required_receipt_fields ++ [:contract_address, :status, :messages, :messages_sent, :events]
    )
    |> validate_according_to_type(attrs)

    # |> foreign_key_constraint(:transaction_id)
    # |> unique_constraint([:id])
    # |> dbg
  end

  # TODO: Use the proper changeset function
  def changeset_for_assoc(attrs = %{"transaction_hash" => hash}) do
    %TransactionReceipt{}
    |> Ecto.Changeset.change()
    |> cast(
      attrs,
      @required_receipt_fields ++ [:contract_address, :status, :messages, :messages_sent, :events]
    )
    |> validate_according_to_type(attrs)
    |> unique_constraint(:receipt)
  end

  defp validate_according_to_type(changeset, _tx = %{"type" => "INVOKE"}) do
    changeset
    |> validate_required(@invoke_tx_receipt_fields)
  end

  defp validate_according_to_type(changeset, _tx = %{"type" => "L1_HANDLER"}) do
    changeset
    |> validate_required(@declare_tx_fields)
  end

  defp validate_according_to_type(changeset, _tx = %{"type" => "DECLARE"}) do
    changeset
    |> validate_required(@declare_tx_fields)
  end

  defp validate_according_to_type(changeset, _tx = %{"type" => "DEPLOY"}) do
    changeset
    |> validate_required(@deploy_tx_fields)
  end

  defp validate_according_to_type(changeset, _tx = %{"type" => "DEPLOY_ACCOUNT"}) do
    changeset
    |> validate_required(@deploy_account_tx_fields)
  end
end
