.PHONY: run setup

run: setup
	iex -S mix phx.server

setup:
	mix deps.get
