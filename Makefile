.PHONY: usage run setup deps-get db stop-db setup-wasm-prover

usage:
	@echo "Usage:"
	@echo "    run   : Starts the Elixir backend server."
	@echo "    setup : Sets up everything necessary to build and run the explorer."
	@echo "    deps  : Gets code dependencies."
	@echo "    db    : Runs the database creation and migration steps."

run:
	iex -S mix phx.server

setup: deps db juno-setup

deps:
	mix deps.get

db:
	mix ecto.create
	mix ecto.migrate

juno-setup:
	mkdir -p ./juno_files
