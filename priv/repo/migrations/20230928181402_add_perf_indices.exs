defmodule StarknetExplorer.Repo.Migrations.AddPerfIndices do
  use Ecto.Migration

  def change do
    create index("transaction_receipts", [:block_hash])
    create index("transaction_receipts", [:transaction_hash])
    create index("transactions", [:block_number])
    create index("events", [:block_number])
  end
end
