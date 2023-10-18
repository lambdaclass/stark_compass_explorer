defmodule StarknetExplorer.Repo.Migrations.DropIndex do
  use Ecto.Migration

  def change do
    if System.get_env("DB_TYPE") == "postgresql" do
      execute("DROP INDEX contract_class_hash_index;")
    end
  end
end
