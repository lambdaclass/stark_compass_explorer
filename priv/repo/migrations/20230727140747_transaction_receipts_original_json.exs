defmodule StarknetExplorer.Repo.Migrations.TransactionReceiptsOriginalJson do
  use Ecto.Migration

  def change do
    alter table("transaction_receipts") do
      add :original_json, :binary
    end
  end
end
