defmodule StarknetExplorer.TransactionReceipt do
  use Ecto.Schema
  import Ecto.Changeset
  alias StarknetExplorer.{Transaction, TransactionReceipt}

  @invoke_tx_receipt_fields [
    :type,
    :transaction_hash,
    :actual_fee,
    :status,
    :messages_sent,
    :events,
    :block_hash,
    :block_number,
    :messages_sent,
    :events
  ]

  @l1_receipt_handler [
    :type,
    :transaction_hash,
    :actual_fee,
    :status,
    :block_hash,
    :block_number,
    :messages_sent,
    :events
  ]

  @declare_tx_receipt [
    :type,
    :transaction_hash,
    :actual_fee,
    :status,
    :block_hash,
    :block_number,
    :messages_sent,
    :events
  ]

  @deploy_tx_receipt [
    :transaction_hash,
    :actual_fee,
    :status,
    :block_hash,
    :messages_sent,
    :events,
    :type,
    :contract_address
  ]

  @deploy_account_tx_receipt [
    :transaction_hash,
    :actual_fee,
    :status,
    :block_hash,
    :block_number,
    :messages_sent,
    :events,
    :type,
    :contract_address
  ]

  # @pending_receipt [
  #   :transaction_hash,
  #   :actual_fee,
  #   :type,
  #   :messages_sent,
  #   :events,
  #   :contract_address
  # ]

  # @pending_deploy_receipt [
  #   :transaction_hash,
  #   :type,
  #   :actual_fee,
  #   :messages_sent,
  #   :events,
  #   :contract_address
  # ]

  @fields @invoke_tx_receipt_fields ++
            @l1_receipt_handler ++ @declare_tx_receipt ++ @deploy_account_tx_receipt
  schema "transaction_receipts" do
    belongs_to :transaction, Transaction
    field :transaction_hash
    field :type, :string
    field :actual_fee, :string
    field :status, :string
    field :block_hash, :string
    field :block_number, :integer
    field :messages_sent, {:array, :map}
    field :events, {:array, :map}
    field :contract_address
    timestamps()
  end

  def changeset(receipt, attrs) do
    receipt
    |> cast(
      attrs,
      @fields
    )
    |> validate_according_to_type(attrs)

    # |> foreign_key_constraint(:transaction_id)
    # |> unique_constraint([:id])
    # |> dbg
  end

  def get_by_tx_hash(tx_hash), do: Repo.get_by(__MODULE__, transaction_hash: tx_hash)

  # TODO: Use the proper changeset function
  def changeset_for_assoc(attrs = %{"transaction_hash" => _}) do
    %TransactionReceipt{}
    |> Ecto.Changeset.change()
    |> cast(
      attrs,
      @fields
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
    |> validate_required(@l1_receipt_handler)
  end

  defp validate_according_to_type(changeset, _tx = %{"type" => "DECLARE"}) do
    changeset
    |> validate_required(@declare_tx_receipt)
  end

  defp validate_according_to_type(changeset, _tx = %{"type" => "DEPLOY"}) do
    changeset
    |> validate_required(@deploy_tx_receipt)
  end

  defp validate_according_to_type(changeset, _tx = %{"type" => "DEPLOY_ACCOUNT"}) do
    changeset
    |> validate_required(@deploy_account_tx_receipt)
  end
end
