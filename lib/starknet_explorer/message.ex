defmodule StarknetExplorer.Message do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias StarknetExplorer.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @fields [
    :from_address,
    :to_address,
    :payload,
    :type,
    :transaction_hash,
    :message_hash,
    :timestamp,
    :network
  ]

  schema "messages" do
    field :from_address, :string
    field :transaction_hash, :string
    field :message_hash, :string
    field :to_address, :string
    field :payload, {:array, :string}
    field :timestamp, :integer

    field :type, Ecto.Enum,
      values: [
        :l2_to_l1_executed_on_l2,
        :l2_to_l1_logged_on_l1,
        :l2_to_l1_consumed_on_l1,
        :l1_to_l2_logged_on_l1,
        :l1_to_l2_executed_on_l2,
        :l1_to_l2_consumed_on_l1,
        :l1_to_l2_cancellation_started_on_l1,
        :l1_to_l2_cancelled_on_l1
      ]

    field :network, Ecto.Enum, values: [:mainnet, :testnet, :testnet2]
    # belongs_to :transaction, Transaction, foreign_key: :transaction_hash, references: :hash
    timestamps()
  end

  def changeset(message, params) do
    message
    |> cast(params, @fields)
    |> foreign_key_constraint(:transaction_hash)
    |> validate_required(@fields)
  end

  def insert_from_transaction_receipt(receipt, network) do
    receipt
    |> StarknetExplorerWeb.Utils.atomize_keys()
    |> from_transaction_receipt()
    |> Enum.map(fn message ->
      %StarknetExplorer.Message{}
      |> changeset(
        message
        |> Map.put(:network, network)
        |> Map.put(:timestamp, receipt["timestamp"])
        |> Map.put(:transaction_hash, receipt["transaction_hash"])
      )
      |> Repo.insert!(returning: false)
    end)
  end

  def get_by_hash(message_hash, network) do
    query =
      from msg in StarknetExplorer.Message,
        where: msg.message_hash == ^message_hash and msg.network == ^network,
        limit: 1

    Repo.one(query)
  end

  def latest_n_messages(network, n \\ 20) do
    query =
      from msg in StarknetExplorer.Message,
        order_by: [desc: msg.timestamp],
        where: msg.network == ^network,
        limit: ^n

    Repo.all(query)
  end

  def paginate_messages(params, network) do
    query =
      from msg in StarknetExplorer.Message,
        order_by: [desc: msg.timestamp],
        where: msg.network == ^network

    Repo.paginate(query, params)
  end

  def get_total_count(network) do
    from(msg in __MODULE__, where: msg.network == ^network, select: count())
    |> Repo.one()
  end

  def insert_from_transaction(transaction, timestamp, network) do
    message =
      transaction
      |> from_transaction()

    case message do
      nil ->
        :skip

      message ->
        changeset(
          %StarknetExplorer.Message{},
          message |> Map.put(:timestamp, timestamp) |> Map.put(:network, network)
        )
        |> Repo.insert!(returning: false)
    end
  end

  @spec from_transaction_receipt(atom | %{:messages_sent => any, optional(any) => any}) :: list
  def from_transaction_receipt(receipt) do
    Enum.map(receipt.messages_sent, fn message ->
      message = message |> StarknetExplorerWeb.Utils.atomize_keys()

      hash_input =
        Abi.encode_packed_mixed([
          message.from_address,
          message.to_address,
          length(message.payload),
          message.payload
        ])

      keccak_message_hash = Base.encode16(ExKeccak.hash_256(hash_input))

      %{
        transaction_hash: receipt.transaction_hash,
        from_address: message.from_address,
        to_address: message.to_address,
        payload: message.payload,
        type: :l2_to_l1_executed_on_l2,
        message_hash: String.downcase("0x" <> keccak_message_hash)
      }
    end)
  end

  # messages from L1 to L2 have to be derived from transactions
  def from_transaction(transaction) do
    case transaction.type do
      "L1_HANDLER" ->
        %{calldata: [from_address | payload] = transaction.calldata}

        hash_input =
          Abi.encode_packed_mixed([
            from_address,
            transaction.contract_address,
            transaction.nonce,
            transaction.entry_point_selector,
            length(payload),
            payload
          ])

        %{
          transaction_hash: transaction.hash,
          from_address: from_address,
          to_address: transaction.contract_address,
          payload: payload,
          type: :l1_to_l2_executed_on_l2,
          message_hash: String.downcase("0x" <> Base.encode16(ExKeccak.hash_256(hash_input)))
        }

      _ ->
        nil
    end
  end

  def friendly_message_type(:l2_to_l1_executed_on_l2), do: "Sent on L2"
  def friendly_message_type(:l1_to_l2_executed_on_l2), do: "Consumed on L2"
  # TODO: Add message type names
  def friendly_message_type(_), do: "-"

  def is_l2_to_l1(:l2_to_l1_executed_on_l2), do: true
  def is_l2_to_l1(:l2_to_l1_logged_on_l1), do: true
  def is_l2_to_l1(:l2_to_l1_consumed_on_l1), do: true
  def is_l2_to_l1(_), do: false
end
