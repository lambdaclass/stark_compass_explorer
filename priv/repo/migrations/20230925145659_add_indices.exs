defmodule StarknetExplorer.Repo.Migrations.AddIndices do
  use Ecto.Migration

  def change do
    create index("blocks", [:timestamp])
    create index("events", [:transaction_hash])
    create index("messages", [:timestamp])
  end
end
