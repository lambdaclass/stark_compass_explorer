.PHONY: run setup deps-get db stop-db

run:
	iex -S mix phx.server

setup: deps-get db

db:
	docker-compose up -d
	mix ecto.create
	mix ecto.migrate

stop-db:
	docker-compose down

deps-get:
	mix deps.get

db_container := $(shell docker ps -aqf name=starknet_explorer_dev_db)
seed: db
	cat ./priv/repo/seed.sql | docker exec -i $(db_container) psql -U postgres -d starknet_explorer_dev
create-seed: db
	docker exec -i $(db_container) pg_dump --column-inserts --data-only -d starknet_explorer_dev -U postgres > ./priv/repo/seed.sql
