defmodule StarknetExplorer.Repo.Migrations.ReplaceBlockPk do
  use Ecto.Migration

  def change do
    # Remove the existing primary key constraint
    execute("ALTER TABLE blocks DROP CONSTRAINT blocks_pkey CASCADE")

    # Set the "hash" column as the new primary key
    alter table(:blocks) do
      modify :number, :integer, primary_key: false
    end

    # Add a new composite primary key using a tuple with two columns
    execute("ALTER TABLE blocks ADD PRIMARY KEY (number, network)")
  end
end
