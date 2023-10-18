defmodule :"Elixir.StarknetExplorer.Repo.Migrations.Replace-contracts-and-classes-pk" do
  use Ecto.Migration

  def change do
    execute("ALTER TABLE contracts DROP CONSTRAINT contracts_pkey")
    execute("ALTER TABLE contracts ADD PRIMARY KEY (address, network)")

    execute("ALTER TABLE classes DROP CONSTRAINT classes_pkey")
    execute("ALTER TABLE classes ADD PRIMARY KEY (hash, network)")
  end
end
