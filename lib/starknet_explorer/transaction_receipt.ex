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

  @networks [:mainnet, :testnet, :sepolia]

  @fields @invoke_tx_receipt_fields ++
            @l1_receipt_handler ++
            @declare_tx_receipt ++ @deploy_account_tx_receipt ++ [:network, :execution_resources]
  @primary_key {:transaction_hash, :string, []}
  schema "transaction_receipts" do
    belongs_to :transaction, Transaction, references: :hash
    field :type, :string
    field :actual_fee, :map
    field :finality_status, :string
    field :execution_status, :string
    field :block_hash, :string
    field :block_number, :integer
    field :messages_sent, {:array, :map}
    field :events, {:array, :map}
    field :contract_address
    field :network, Ecto.Enum, values: @networks
    field :execution_resources, :map
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

  def get_status_not_finalized(block_number, network) do
    query =
      from t in TransactionReceipt,
        where: t.finality_status != "ACCEPTED_ON_L1" and t.execution_status == "SUCCEEDED",
        # TODO add index in block_number.
        where: t.network == ^network and t.block_number == ^block_number

    Repo.all(query)
  end

  def update_transaction_status(tx_hash, finality_status, execution_status, network) do
    query =
      from t in TransactionReceipt,
        where: t.transaction_hash == ^tx_hash and t.network == ^network

    Repo.update_all(query,
      set: [execution_status: execution_status, finality_status: finality_status]
    )
  end

  def update_execution_resources(receipt, execution_resources) do
    receipt_updated = Ecto.Changeset.change(receipt, execution_resources: execution_resources)
    Repo.update(receipt_updated)
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
