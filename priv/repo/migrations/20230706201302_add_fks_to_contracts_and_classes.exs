defmodule StarknetExplorer.Repo.Migrations.AddFksToContractsAndClasses do
  use Ecto.Migration

  def change do
    alter table("classes") do
      add :declared_by,
          references("contracts",
            on_delete: :delete_all,
            column: :address,
            name: :declared_by_address,
            prefix: nil,
            type: :string
          )
    end

    alter table("contracts") do
      add :deployed_by_address,
        references("contracts",
          on_delete: :delete_all,
          column: :address,
          name: :deployed_by_address,
          prefix: nil,
          type: :string
        ),
        null: true

      add :contract_class_hash,
        references("classes",
          on_delete: :delete_all,
          column: :hash,
          name: :contract_class_hash,
          prefix: nil,
          type: :string
        )
    end
  end
end
