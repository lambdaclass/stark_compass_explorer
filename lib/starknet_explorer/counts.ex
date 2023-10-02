defmodule StarknetExplorer.Counts do
  use Ecto.Schema
  import Ecto.Query
  alias StarknetExplorer.Events
  alias StarknetExplorer.Message
  alias StarknetExplorer.Transaction
  alias StarknetExplorer.{Counts, BlockUtils}
  alias StarknetExplorer.Repo

  @primary_key {:network, :string, autogenerate: false}
  schema "counts" do
    field :blocks, :integer
    field :transactions, :integer
    field :messages, :integer
    field :events, :integer
  end

  def get(network) when is_atom(network) do
    from(count in __MODULE__, where: count.network == ^Atom.to_string(network))
    |> Repo.one()
  end

  def get(network) do
    from(count in __MODULE__, where: count.network == ^network)
    |> Repo.one()
  end

  def insert_or_update(
        network,
        amount_blocks,
        amount_transactions,
        amount_events,
        amount_messages
      ) do
    %Counts{blocks: blocks, transactions: transactions, messages: messages, events: events} =
      count =
      case Repo.get_by(Counts, network: Atom.to_string(network)) do
        # Count exists, let's use it
        %Counts{} = count ->
          count

        # Count not found, we build one
        nil ->
          %Counts{
            network: Atom.to_string(network),
            blocks: 0,
            transactions: 0,
            messages: 0,
            events: 0
          }
      end

    count
    |> Ecto.Changeset.change(
      blocks: blocks + amount_blocks,
      transactions: transactions + amount_transactions,
      messages: messages + amount_messages,
      events: events + amount_events
    )
    |> Repo.insert_or_update()
  end

  def insert_or_update(network) do
    {:ok, blocks} = BlockUtils.block_height(network)
    transactions = Transaction.get_total_count(network)
    messages = Message.get_total_count(network)
    events = Events.get_total_count(network)

    case Repo.get_by(Counts, network: Atom.to_string(network)) do
      # Count exists, let's use it
      %Counts{} = count ->
        count

      # Count not found, we build one
      nil ->
        %Counts{
          network: Atom.to_string(network)
        }
    end
    |> Ecto.Changeset.change(
      blocks: blocks,
      transactions: transactions,
      messages: messages,
      events: events
    )
    |> Repo.insert_or_update()
  end
end
