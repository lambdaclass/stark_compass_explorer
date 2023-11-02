defmodule StarknetExplorer.Repo.Migrations.AddBlockHasContractsAndClasses do
  use Ecto.Migration

  def change do
    alter table(:blocks) do
      add :has_contracts_and_classes, :boolean, default: false
    end
  end
end
