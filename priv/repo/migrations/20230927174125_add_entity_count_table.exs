defmodule StarknetExplorer.Repo.Migrations.AddEntityCountTable do
  use Ecto.Migration

  def change do
    create table("counts", primary_key: false) do
      add :blocks, :integer
      add :transactions, :integer
      add :messages, :integer
      add :events, :integer
      add :network, :string, primary_key: true, null: false
    end
  end
end
