defmodule StarknetExplorer.Repo.Migrations.CreateInternalCalls do
  use Ecto.Migration

  def change do
    create table(:internal_calls, primary_key: false) do
      references("transactions",
        on_delete: :delete_all,
        column: :transaction_hash,
        name: :transaction,
        prefix: nil,
        type: :string
      )

      add :transaction_hash, :string
      add :type, :string
      add :function_selector, :string
      add :contract_address, :string
      add :calldata, {:array, :string}
      add :network, :string
      add :id, :uuid, primary_key: true

      timestamps()
    end

    create index("internal_calls", [:transaction_hash])
    create unique_index("internal_calls", [:id])
  end
end
