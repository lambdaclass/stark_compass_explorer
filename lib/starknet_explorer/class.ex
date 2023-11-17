defmodule StarknetExplorer.Class do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias StarknetExplorer.{Repo, Rpc}

  @types %{
    "ERC20_snake_case" => [
      "0x216b05c387bab9ac31918a3e61672f4618601f3c598a2f3f2710f37053e1ea4",
      "0x4c4fb1ab068f6039d5780c68dd0fa2f8742cceb3426d19667778ca7f3518a9",
      "0x1557182e4359a1f0c6301278e8f5b35a776ab58d39892581e357578fb287836",
      "0x35a73cd311a05d46deda634c5ee045db92f811b4e74bca4437fcb5302b7af33",
      "0x1e888a1026b19c8c0b57c72d63ed1737106aa10034105b980ba117bd0c29fe1",
      "0x83afd3f4caedc6eebf44246fe54e38c95e3179a5ec9ea81740eca5b482d12e",
      "0x3704ffe8fba161be0e994951751a5033b1462b918ff785c0a636be718dfdb68",
      "0x219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c"
    ],
    "ERC20_camel_case" => [
      "0x216b05c387bab9ac31918a3e61672f4618601f3c598a2f3f2710f37053e1ea4",
      "0x4c4fb1ab068f6039d5780c68dd0fa2f8742cceb3426d19667778ca7f3518a9",
      "0x1e888a1026b19c8c0b57c72d63ed1737106aa10034105b980ba117bd0c29fe1",
      "0x83afd3f4caedc6eebf44246fe54e38c95e3179a5ec9ea81740eca5b482d12e",
      "0x219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c",
      "0x80aa9fdbfaf9615e4afc7f5f722e265daca5ccc655360fa5ccacf9c267936d",
      "0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e",
      "0x41b033f4a31df8067c24d1e9b550a2ce75fd4a29e1147af9752174f0e6cb20"
    ],
    "Account" => [
      "0x162da33a4585851fe8d3af3c2a9c60b557814e221e0d4f30ff0b2189d9c7775",
      "0x15d40a3d6ca2ac30f4031e42be28da9b056fef9bb7357ac5e85627ee876e5ad"
    ],
    "Proxy" => ["0x0", "0x21691762da057c1b71f851f9b709e0c143628acf6e0cbc9735411a65663d747"],
    "ERC721_camel_case" => [
      "0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e",
      "0x2962ba17806af798afa6eaf4aa8c93a9fb60a3e305045b6eea33435086cae9",
      "0x19d59d013d4aa1a8b1ce4c8299086f070733b453c02d0dc46e735edc04d6444",
      "0x41b033f4a31df8067c24d1e9b550a2ce75fd4a29e1147af9752174f0e6cb20",
      "0x219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c",
      "0xb180e2fe9f14914416216da76338ac0beb980443725c802af615f8431fdb1e",
      "0x2d4c8ea4c8fb9f571d1f6f9b7692fff8e5ceaf73b1df98e7da8c1109b39ae9a",
      "0x21cdf9aedfed41bc4485ae779fda471feca12075d9127a0fc70ac6b3b3d9c30",
      "0x19d59d013d4aa1a8b1ce4c8299086f070733b453c02d0dc46e735edc04d6444"
    ],
    "ERC721_snake_case" => [
      "0x35a73cd311a05d46deda634c5ee045db92f811b4e74bca4437fcb5302b7af33",
      "0x3552df12bdc6089cf963c40c4cf56fbfd4bd14680c244d1c5494c2790f1ea5c",
      "0x16f0218b33b5cf273196787d7cf139a9ad13d58e6674dcdce722b3bf8389863",
      "0x3704ffe8fba161be0e994951751a5033b1462b918ff785c0a636be718dfdb68",
      "0x219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c",
      "0x309065f1424d76d4a4ace2ff671391d59536e0297409434908d38673290a749",
      "0xd86ca3d41635e20c180181046b11abcf19e1bdef3dcaa4c180300ccca1813f",
      "0x2aa3ea196f9b8a4f65613b67fcf185e69d8faa9601a3382871d15b3060e30dd",
      "0x16f0218b33b5cf273196787d7cf139a9ad13d58e6674dcdce722b3bf8389863"
    ]
  }

  @networks [:mainnet, :testnet]

  @fields [
    :declared_by_address,
    :declared_at_transaction,
    :timestamp,
    :version,
    :network,
    :hash,
    :block_number,
    :type,
    :type_updated
  ]

  @required [
    :hash,
    :network
  ]

  @primary_key false
  schema "classes" do
    field :hash, :string, primary_key: true
    field :network, Ecto.Enum, values: @networks, primary_key: true
    field :timestamp, :integer
    field :declared_by_address, :string
    field :version, :string
    field :declared_at_transaction, :string
    field :block_number, :integer
    field :type, {:array, :string}
    field :type_updated, :boolean, default: false

    timestamps()
  end

  def changeset(schema, params) do
    schema
    |> cast(params, @fields)
    |> validate_required(@required)
    |> unique_constraint([:hash, :network], name: :classes_pkey)
  end

  def insert(params) do
    %StarknetExplorer.Class{}
    |> changeset(params)
    |> Repo.insert()
  end

  def get_page(params, network) do
    StarknetExplorer.Class
    |> where([p], p.network == ^network)
    |> order_by(desc: :timestamp)
    |> Repo.paginate(params)
  end

  def get_by_hash(hash, network) do
    StarknetExplorer.Class
    |> where([p], p.hash == ^hash and p.network == ^network)
    |> limit(1)
    |> Repo.one()
  end

  def get_out_of_date_class(network) do
    StarknetExplorer.Class
    |> where([p], p.network == ^network and p.type_updated == false)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Updates the class type of the class with the given hash.
  """
  # We can use this function in the Updater process of the StateSyncStystem.
  def update_class_type_from_rpc(class) do
    types = get_types_for_class(class.hash, class.network)

    Ecto.Changeset.change(class, type: types, type_updated: true)
    |> Repo.update()
  end

  @doc """
  Compares the selectors of the class with our list of known selectors for each type.
  Returns a list with the name of every interface that the class implements.
  """
  # We can add to the StateSyncSystem even though we know that it is an expensive operation because it is not normal
  # for Classes to be declared in all blocks, but rather, on average, one class is declared every 10 blocks.
  # In particular, we can use this function for the Fetcher and the Listener.
  def get_types_for_class(class_hash, network) do
    # Class type can be one of two possible types:
    # 1. Deprecated Contract Class. Which has: program, abi and entry_points_by_type. The abi field here is an struct.
    # 2. Contract Class. Which has: sierra_program, contract_class_version, entry_points_by_type and abi. The abi field here is a string.

    # For those type that we need to check for some specific functions selectors, we need to check entrypoint_by_type and entry_points_by_type
    # respectively, since the ABI.
    # The other ones, we have to options:
    # 1. Check the abi field, which is a struct for deprecated contract classes and a string for contract classes. But this option might
    # fail sometimes since it is not guaranteed that the ABI will be present in the class.
    # 2. Check the entry points, and match with the selectors that we are looking for. This option is more reliable, since this field is
    # always present in the class, but it is more expensive since we need to check all the entry points.

    # I want to generate a list of the class selectors:
    # For both contract classes the selectors are under the "entry_points_by_type" field.
    # So, I can use directly:
    # ```
    # class_type["entry_points_by_type"]["EXTERNAL"]
    # ```
    # This provides a list of maps, where each map has the following structure:
    # `{"selector" => selector, ...}`
    # So, I can use the following code to get the list of selectors:
    # ```
    # class_type["entry_points_by_type"]["EXTERNAL"]
    # |> Enum.map(fn x -> x["selector"] end)
    # ```

    {:ok, class_type} = Rpc.get_class("latest", class_hash, network)

    selectors =
      class_type
      |> Map.get("entry_points_by_type", %{"EXTERNAL" => []})
      |> Map.get("EXTERNAL", [])
      |> Enum.concat(class_type["entry_points_by_type"]["L1_HANDLER"])
      |> Enum.map(fn x -> x["selector"] end)

    Enum.reduce(@types, [], fn {type, selectors_to_check}, acc ->
      acc ++
        if Enum.all?(selectors_to_check, fn selector -> Enum.member?(selectors, selector) end),
          do: [type_name(type)],
          else: []
    end)
    |> Enum.uniq()
  end

  defp type_name("ERC20_camel_case"), do: "ERC20"
  defp type_name("ERC20_snake_case"), do: "ERC20"
  defp type_name("ERC721_camel_case"), do: "ERC721"
  defp type_name("ERC721_snake_case"), do: "ERC721"
  defp type_name(type), do: type
end
