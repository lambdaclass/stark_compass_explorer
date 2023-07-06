defmodule StarknetExplorer.Repo.Migrations.Transactions do
  use Ecto.Migration

  def change do
    create table("transactions", primary_key: false) do
      add :block_number,
          references("blocks",
            on_delete: :delete_all,
            column: :number,
            name: :block_number,
            prefix: nil,
            type: :integer
          )

      add :calldata, {:array, :string}
      add :chain_id, {:array, :string}
      add :class_hash, :string
      add :constructor_calldata, :string
      add :contract_address, :string
      add :contract_address_salt, :string
      add :contract_class, :string
      add :compiled_class_hash, :string
      add :sender_address, :string
      add :entry_point_selector, :string
      add :hash, :string, primary_key: true
      add :max_fee, :string
      add :nonce, :string
      add :signature, {:array, :string}
      add :type, :string
      add :version, :string
      timestamps()
    end

    create unique_index("transactions", [:hash])
  end
end
