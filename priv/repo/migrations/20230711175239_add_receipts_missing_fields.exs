defmodule StarknetExplorer.Repo.Migrations.AddReceiptsMissingFields do
  use Ecto.Migration

  def change do
    alter table("transaction_receipts") do
      add :transaction_hash, :string
      remove :messages
    end
  end
end
