defmodule StarknetExplorer.Repo.Migrations.Block do
  use Ecto.Migration

  def change do
    create table("blocks", primary_key: false) do
      add :number, :integer, primary_key: true, null: false
      add :status, :string, null: false
      add :hash, :string, null: false
      add :parent_hash, :string, null: false
      add :new_root, :string, null: false
      add :timestamp, :integer, null: false
      add :sequencer_address, :string, null: false
      add :original_json, :binary, null: false
      timestamps()
    end
    create unique_index("blocks", [:number])
  end
end
