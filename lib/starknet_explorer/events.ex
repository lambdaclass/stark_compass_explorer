defmodule StarknetExplorer.Events do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias StarknetExplorer.Events
  alias StarknetExplorer.Data
  alias StarknetExplorer.Repo
  alias StarknetExplorer.Rpc
  alias StarknetExplorerWeb.Utils
  @primary_key {:id, :string, autogenerate: false}
  @fields [
    :name,
    :from_address,
    :age,
    :name_hashed,
    :data,
    :index_in_block,
    :block_number,
    :transaction_hash,
    :network
  ]

  @common_event_hash_to_name %{
    "0x99cd8bde557814842a3121e8ddfd433a539b8c9f14bf31ebf108d12e6196e9" => "Transfer",
    "0x134692b230b9e1ffa39098904722134159652b09c5bc41d88d6698779d228ff" => "Approval",
    "0x1390fd803c110ac71730ece1decfc34eb1d0088e295d4f1b125dda1e0c5b9ff" => "OwnershipTransferred",
    "0x3774b0545aabb37c45c1eddc6a7dae57de498aae6d5e3589e362d4b4323a533" => "governor_nominated",
    "0x19b0b96cb0e0029733092527bca81129db5f327c064199b31ed8a9f857fdee3" => "nomination_cancelled",
    "0x3b7aa6f257721ed65dae25f8a1ee350b92d02cd59a9dcfb1fc4e8887be194ec" => "governor_removed",
    "0x4595132f9b33b7077ebf2e7f3eb746a8e0a6d5c337c71cd8f9bf46cac3cfd7" => "governance_accepted",
    "0x2e8a4ec40a36a027111fafdb6a46746ff1b0125d5067fbaebd8b5f227185a1e" => "implementation_added",
    "0x3ef46b1f8c5c94765c1d63fb24422442ea26f49289a18ba89c4138ebf450f6c" =>
      "implementation_removed",
    "0x1205ec81562fc65c367136bd2fe1c0fff2d1986f70e4ba365e5dd747bd08753" =>
      "implementation_upgraded",
    "0x2c6e1be7705f64cd4ec61d51a0c8e64ceed5e787198bd3291469fb870578922" =>
      "implementation_finalized",
    "0x2db340e6c609371026731f47050d3976552c89b4fbb012941663841c59d1af3" => "Upgraded",
    "0x120650e571756796b93f65826a80b3511d4f3a06808e82cb37407903b09d995" => "AdminChanged",
    "0xe316f0d9d2a3affa97de1d99bb2aac0538e2666d0d8545545ead241ef0ccab" => "Swap",
    "0xe14a408baf7f453312eec68e9b7d728ec5337fbdf671f917ee8c80f3255232" => "Sync",
    "0x5ad857f66a5b55f1301ff1ed7e098ac6d4433148f0b72ebc4a2945ab85ad53" => "transaction_executed",
    "0x10c19bef19acd19b2c9f4caa40fd47c9fbe1d9f91324d44dcd36be2dae96784" => "account_created",
    "0x243e1de00e8a6bc1dfa3e950e6ade24c52e4a25de4dee7fb5affe918ad1e744" => "Burn",
    "0x34e55c1cd55f1338241b50d352f0e91c7e4ffad0e4271d64eb347589ebdfd16" => "Mint"
  }

  @common_event_hashes Map.keys(@common_event_hash_to_name)
  @condition_to_match 15
  @continuation_tokens ["0", "1000", "2000", "3000", "4000"]
  @chunk_size 1000

  # Defines the separator used to distinguish between modules and event names in Cairo0 events.
  # In Cairo0 events, event names may include module information in the format:
  # `Module1::SubModule::EventName`
  @event_module_separator "::"

  schema "events" do
    # belongs_to :transaction_hash, Transaction, references: :hash
    # belongs_to :block, Block, references: :number
    field :block_number, :integer
    field :name, :string
    field :from_address, :string
    field :age, :integer
    field :name_hashed, :string
    field :data, {:array, :string}
    field :index_in_block, :integer
    field :transaction_hash, :string
    field :network, Ecto.Enum, values: [:mainnet, :testnet, :testnet2]
    timestamps()
  end

  def changeset(schema, %{"keys" => [name_hashed | _]} = params, network) do
    schema
    |> cast(params, @fields)
    |> cast(
      %{
        id:
          Integer.to_string(params["block_number"]) <>
            "_" <> Integer.to_string(params["index_in_block"])
      },
      [:id]
    )
    |> cast(%{index_in_block: params["index_in_block"]}, [:index_in_block])
    |> cast(%{name: get_event_name(params, network)}, [:name])
    |> cast(%{name_hashed: name_hashed}, [:name_hashed])
    |> foreign_key_constraint(:block_number)
    |> foreign_key_constraint(:transaction_hash)
    |> unique_constraint(:id)
    |> validate_required(@fields)
  end

  def insert(event, relative_idx, continuation_token, network, block) do
    %StarknetExplorer.Events{}
    |> changeset(
      event
      |> Map.put("index_in_block", relative_idx + String.to_integer(continuation_token))
      |> Map.put("age", block.timestamp)
      |> Map.put("block_number", block.number)
      |> Map.put("network", network),
      network
    )
    |> Repo.insert()
  end

  defp _get_event_name(abi, event_name_hashed) when is_list(abi) do
    abi
    |> Enum.filter(fn abi_entry -> abi_entry["type"] == "event" end)
    |> Map.new(fn abi_event ->
      {abi_event["name"]
       |> String.split(@event_module_separator)
       |> List.last()
       |> ExKeccak.hash_256()
       |> Base.encode16(case: :lower)
       |> StarknetExplorer.Utils.last_n_characters(@condition_to_match),
       List.last(String.split(abi_event["name"], @event_module_separator))}
    end)
    |> Map.get(
      StarknetExplorer.Utils.last_n_characters(event_name_hashed, @condition_to_match),
      Utils.shorten_block_hash(event_name_hashed)
    )
  end

  defp _get_event_name(abi, event_name_hashed) do
    abi
    |> Jason.decode!()
    |> _get_event_name(event_name_hashed)
  end

  def get_event_name(%{"keys" => [event_name_hashed | _]} = _event, _network)
      when event_name_hashed in @common_event_hashes,
      do: @common_event_hash_to_name[event_name_hashed]

  def get_event_name(%{"keys" => [event_name_hashed | _]} = event, network) do
    Data.get_class_at(event["block_number"], event["from_address"], network)
    |> Map.get("abi")
    |> _get_event_name(event_name_hashed)
  end

  def paginate_events(params, block_number, network) do
    Events
    |> where([p], p.block_number == ^block_number and p.network == ^network)
    |> order_by(asc: :index_in_block)
    |> Repo.paginate(params)
  end

  def store_events_from_rpc(block, network) do
    Enum.map(@continuation_tokens, fn continuation_token ->
      case Rpc.get_block_events_paginated(
             block.hash,
             %{
               "chunk_size" => @chunk_size,
               "continuation_token" => continuation_token
             },
             network
           ) do
        {:ok, events} ->
          events["events"]
          |> Enum.with_index(&insert(&1, &2, continuation_token, network, block))

          events

        # This means that we fetch all the events from a block.
        {:error, %{"code" => 33}} ->
          :ok

        err ->
          err
      end
    end)
  end
end
