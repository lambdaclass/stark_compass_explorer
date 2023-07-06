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
      add :deployed_by,
          references("contracts",
            on_delete: :delete_all,
            column: :address,
            name: :deployed_by_address,
            prefix: nil,
            type: :string
          )

      add :class_hash,
          references("classes",
            on_delete: :delete_all,
            column: :hash,
            name: :class_hash,
            prefix: nil,
            type: :string
          )
    end
  end
end
