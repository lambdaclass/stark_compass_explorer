defmodule StarknetExplorer.Repo.Migrations.AddBlockNumberToContractsAndClasses do
  use Ecto.Migration

  def change do
    alter table(:contracts) do
      add :block_number, :integer
    end

    alter table(:classes) do
      add :block_number, :integer
    end
  end
end
