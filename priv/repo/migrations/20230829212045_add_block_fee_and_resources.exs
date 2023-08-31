defmodule StarknetExplorer.Repo.Migrations.AddBlockFeeAndResources do
  use Ecto.Migration

  def change do
    alter table :blocks do
      add :gas_fee_in_wei, :string, null: true
      add :execution_resources, :integer, null: true
    end
  end
end
