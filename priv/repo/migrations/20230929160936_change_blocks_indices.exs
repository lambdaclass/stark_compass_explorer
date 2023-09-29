defmodule StarknetExplorer.Repo.Migrations.ChangeBlocksIndices do
  use Ecto.Migration

  def change do
    if System.get_env("DB_TYPE") == "postgresql" do
      execute("drop index blocks_number_index;")
      execute("create index blocks_number_index on blocks (number);")
    end
  end
end
