defmodule :"Elixir.StarknetExplorer.Repo.Migrations.Add-state-updated-field-in-blocks" do
  use Ecto.Migration

  def change do
    alter table("blocks") do
      add :state_updated, :boolean
    end
  end
end
