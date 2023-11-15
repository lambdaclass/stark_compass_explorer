defmodule StarknetExplorer.Repo.Migrations.AddTypeToClasses do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      add :type, {:array, :string}
      add :type_updated, :boolean, default: false
    end

    alter table(:contracts) do
      remove :type
      add :type, {:array, :string}
    end
  end
end
