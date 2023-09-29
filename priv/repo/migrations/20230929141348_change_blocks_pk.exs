defmodule StarknetExplorer.Repo.Migrations.ChangeBlocksPk do
  use Ecto.Migration

  def change do
    execute("alter table transactions drop constraint block_number;")
    execute("alter table blocks drop constraint blocks_pkey;")
    execute("alter table blocks add primary key (number, network);")
    execute("alter table transactions add constraint transactions_blocks_fk foreign key (block_number, network) references blocks (number, network);")
    execute("alter table events add constraint events_blocks_fk foreign key (block_number, network) references blocks (number, network);")
  end
end
