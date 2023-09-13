defmodule StarknetExplorer.Repo.Migrations.AddNetworkFieldBlocksAndTransactions do
  use Ecto.Migration

  def change do
    ~c"""
    blocks
    transactions
    transaction_receipts
    """

    alter table("blocks") do
      add :network, :string, null: false
    end

    alter table("transactions") do
      add :network, :string, null: false
    end

    alter table("transaction_receipts") do
      add :network, :string, null: false
    end
  end
end
