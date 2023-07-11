.PHONY: run setup deps-get db stop-db

run:
	iex -S mix phx.server

setup: deps-get db

db:
	export DATABASE_URL="ecto://postgres:postgres@localhost:5432/starknet_explorer_dev"
	docker-compose up -d postgres pgadmin
	mix ecto.create
	mix ecto.migrate

stop-db:
	docker-compose down

deps-get:
	mix deps.get
