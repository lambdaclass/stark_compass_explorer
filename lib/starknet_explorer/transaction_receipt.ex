defmodule StarknetExplorer.TransactionReceipt do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias StarknetExplorer.{Transaction, TransactionReceipt, Repo}

  @invoke_tx_receipt_fields [
    :type,
    :transaction_hash,
    :actual_fee,
    :finality_status,
    :execution_status,
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
    :finality_status,
    :execution_status,
    :block_hash,
    :block_number,
    :messages_sent,
    :events
  ]

  @declare_tx_receipt [
    :type,
    :transaction_hash,
    :actual_fee,
    :finality_status,
    :execution_status,
    :block_hash,
    :block_number,
    :messages_sent,
    :events
  ]

  @deploy_tx_receipt [
    :transaction_hash,
    :actual_fee,
    :finality_status,
    :execution_status,
    :block_hash,
    :messages_sent,
    :events,
    :type,
    :contract_address
  ]

  @deploy_account_tx_receipt [
    :transaction_hash,
    :actual_fee,
    :finality_status,
    :execution_status,
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

  @networks [:mainnet, :testnet, :testnet2]

  @fields @invoke_tx_receipt_fields ++
            @l1_receipt_handler ++ @declare_tx_receipt ++ @deploy_account_tx_receipt ++ [:network]
  schema "transaction_receipts" do
    belongs_to :transaction, Transaction
    field :transaction_hash
    field :type, :string
    field :actual_fee, :string
    field :finality_status, :string
    field :execution_status, :string
    field :block_hash, :string
    field :block_number, :integer
    field :messages_sent, {:array, :map}
    field :events, {:array, :map}
    field :contract_address
    field :network, Ecto.Enum, values: @networks
    timestamps()
  end

  def changeset(receipt, attrs) do
    receipt
    |> cast(
      attrs,
      @fields
    )
    |> validate_according_to_type(attrs)
  end

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

  def get_by_transaction_hash(tx_hash) do
    query =
      from tr in TransactionReceipt,
        where: tr.transaction_hash == ^tx_hash

    Repo.one(query)
  end

  def get_by_block_hash(block_hash) do
    query =
      from tr in TransactionReceipt,
        where: tr.block_hash == ^block_hash

    Repo.all(query)
  end

  def from_rpc_tx(rpc_receipt) do
    struct(%__MODULE__{}, rpc_receipt |> StarknetExplorerWeb.Utils.atomize_keys())
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
