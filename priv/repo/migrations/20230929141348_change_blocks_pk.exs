defmodule StarknetExplorer.Repo.Migrations.ChangeBlocksPk do
  use Ecto.Migration

  def change do
    execute("ALTER TABLE blocks DROP CONSTRAINT blocks_pkey CASCADE")
    execute("ALTER TABLE blocks ADD PRIMARY KEY (number, network)")

    [:transactions, :events]
    |> Enum.each(fn table ->
      execute("ALTER TABLE #{table} DROP CONSTRAINT #{table}_number_fkey CASCADE")

      execute("""
        ALTER TABLE #{table}
        ADD CONSTRAINT #{table}_block_number_network_fkey
        FOREIGN KEY (number, network)
        REFERENCES blocks(number, network)
      """)
    end)
  end
end
