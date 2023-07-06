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
