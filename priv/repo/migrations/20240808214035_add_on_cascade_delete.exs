defmodule StarknetExplorer.Repo.Migrations.AddOnCascadeDelete do
  use Ecto.Migration

  def change do
    if System.get_env("DB_TYPE") == "postgresql" do
      execute "
      ALTER TABLE transactions
        DROP CONSTRAINT transactions_blocks_fk,
        ADD CONSTRAINT transactions_blocks_fk
          FOREIGN KEY (block_number, network)
          REFERENCES blocks(number, network)
          ON DELETE CASCADE",
              "
      ALTER TABLE transactions
        DROP CONSTRAINT transactions_blocks_fk,
        ADD CONSTRAINT transactions_blocks_fk
          FOREIGN KEY (block_number, network)
          REFERENCES blocks(number, network)"

      execute "
      ALTER TABLE events
        DROP CONSTRAINT events_blocks_fk,
        ADD CONSTRAINT events_blocks_fk
          FOREIGN KEY (block_number, network)
          REFERENCES blocks(number, network)
          ON DELETE CASCADE",
              "
      ALTER TABLE events
        DROP CONSTRAINT events_blocks_fk,
        ADD CONSTRAINT events_blocks_fk
          FOREIGN KEY (block_number, network)
          REFERENCES blocks(number, network)"

      execute "
      ALTER TABLE transaction_receipts
        DROP CONSTRAINT transaction_receipts_transaction_id_fkey,
        ADD CONSTRAINT transaction_receipts_transactions_fk
          FOREIGN KEY (transaction_hash)
          REFERENCES transactions(hash)
          ON DELETE CASCADE",
              "
      ALTER TABLE transaction_receipts
        DROP CONSTRAINT transaction_receipts_transactions_fk,
        ADD CONSTRAINT transaction_receipts_transaction_id_fkey
          FOREIGN KEY (transaction_id)
          REFERENCES transactions(hash)"

      execute "
      ALTER TABLE messages
        ADD CONSTRAINT messages_transactions_fk
          FOREIGN KEY (transaction_hash)
          REFERENCES transactions(hash)
          ON DELETE CASCADE",
              "
      ALTER TABLE messages
        DROP CONSTRAINT messages_transactions_fk"
    end
  end
end
