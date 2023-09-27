defmodule StarknetExplorer.InternalCall do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias StarknetExplorer.{Repo, Gateway}

  @primary_key {:id, :binary_id, autogenerate: true}
  @fields [
    :contract_address,
    :calldata,
    :type,
    :transaction_hash,
    :function_selector,
    :network
  ]

  schema "internal_calls" do
    field :contract_address, :string
    field :transaction_hash, :string
    field :function_selector, :string
    field :calldata, {:array, :string}

    field :type, :string

    field :network, Ecto.Enum, values: [:mainnet, :testnet, :testnet2]
    # belongs_to :transaction, Transaction, foreign_key: :transaction_hash, references: :hash
    timestamps()
  end

  def changeset(call, params) do
    call
    |> cast(params, @fields)
    |> foreign_key_constraint(:transaction_hash)
    |> validate_required(@fields)
  end

  def get_by_tx_hash(tx_hash, network) do
    query =
      from call in StarknetExplorer.InternalCall,
        where: call.transaction_hash == ^tx_hash and call.network == ^network

    Repo.all(query)
  end

  def fetch_by_transaction_hash(tx_hash, network) do
    {:ok, trace} = Gateway.trace_transaction(tx_hash, network)

    function_calls =
      trace["function_invocation"]
      |> StarknetExplorerWeb.Utils.atomize_keys()
      |> flatten_internal_calls(0)

    functions_data_cache =
      function_calls
      |> Enum.map(fn call ->
        call
        |> Map.put(:network, network)
        |> Map.put(:calldata, call.calldata)
        |> Map.put(:contract_address, call.contract_address)
        |> Map.put(:function_selector, call.selector)
        |> Map.put(:type, call.call_type)
        |> Map.put(:transaction_hash, tx_hash)
      end)
  end

  def flatten_internal_calls(%{internal_calls: inner_list_of_calls} = outer_map, height)
      when is_list(inner_list_of_calls) do
    outer_details = [
      %{
        call_type: outer_map.call_type,
        contract_address: outer_map.contract_address,
        caller_address: outer_map.caller_address,
        calldata: outer_map.calldata,
        selector: Map.get(outer_map, :selector),
        scope: height
      }
    ]

    inner_details = Enum.flat_map(inner_list_of_calls, &flatten_internal_calls(&1, height + 1))
    outer_details ++ inner_details
  end

  def flatten_internal_calls(%{internal_calls: []} = _outer_map, _height) do
    []
  end

  def flatten_internal_calls(_list, _height) do
    []
  end
end
