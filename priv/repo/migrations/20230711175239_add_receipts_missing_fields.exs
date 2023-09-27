defmodule StarknetExplorer.Repo.Migrations.AddReceiptsMissingFields do
  use Ecto.Migration

  def change do
    alter table("transaction_receipts") do
      remove :messages
    end
  end
end
