defmodule StarknetExplorer.Repo.Migrations.ChangeBlocksPk do
  use Ecto.Migration

  def change do
    execute("ALTER TABLE blocks DROP CONSTRAINT blocks_pkey")
    execute("ALTER TABLE blocks ADD PRIMARY KEY (block_number, network)")

    [:transactions, :events]
    |> Enum.each(fn table ->
      execute("ALTER TABLE #{table} DROP CONSTRAINT #{table}_block_number_fkey")

      execute("""
        ALTER TABLE #{table}
        ADD CONSTRAINT #{table}_block_number_network_fkey
        FOREIGN KEY (block_number, network)
        REFERENCES blocks(block_number, network)
      """)
    end)
  end
end
