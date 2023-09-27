defmodule StarknetExplorer.Repo.Migrations.CreateInternalCalls do
  use Ecto.Migration

  def change do
    create table(:internal_calls) do
      add :transaction_hash, :string
      add :type, :string
      add :function_selector, :string
      add :contract_address, :string
      add :calldata, {:array, :string}

      timestamps()
    end
  end
end
