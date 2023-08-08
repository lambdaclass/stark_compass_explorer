.PHONY: run setup deps-get db stop-db setup-wasm-prover setup-assets start-db create-db

run:
	iex -S mix phx.server

setup: submodule deps-get start-db setup-assets create-db

submodule: 
	git submodule init
	git submodule update
	cd lambdaworks_stark_platinum && git checkout b2fdd2c115dbf3049097f8c2f99a7097fbc5e5fb
setup-assets:
	mix assets.setup
	mix assets.build

start-db:
	docker-compose up -d postgres pgadmin

create-db:
	mix ecto.create
	mix ecto.migrate

stop-db:
	docker-compose down

deps-get:
	git submodule init
	git submodule update
	mix deps.get

db_container := $(shell docker ps -aqf name=starknet_explorer_dev_db)
seed: db
	cat ./priv/repo/seed.sql | docker exec -i $(db_container) psql -U postgres -d starknet_explorer_dev
create-seed: db
	docker exec -i $(db_container) pg_dump --column-inserts --data-only -d starknet_explorer_dev -U postgres > ./priv/repo/seed.sql

juno:
	mkdir -p ./juno_files
	docker-compose up juno
