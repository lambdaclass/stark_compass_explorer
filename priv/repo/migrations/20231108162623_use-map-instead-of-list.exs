defmodule :"Elixir.StarknetExplorer.Repo.Migrations.Use-map-instead-of-list" do
  use Ecto.Migration

  def change do
    alter table(:transaction_receipts) do
      modify :execution_resources, :map
    end
  end
end
