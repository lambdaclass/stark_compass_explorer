defmodule :"Elixir.StarknetExplorer.Repo.Migrations.Remove-original-json-fields" do
  use Ecto.Migration

  def change do
    alter table("blocks") do
      remove :original_json
    end
    alter table("transaction_receipts") do
      remove :original_json
    end
  end
end
