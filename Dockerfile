FROM hexpm/elixir:1.15.2-erlang-26.0.2-debian-bullseye-20230612-slim

# should be overwritten inline/docker-compose
ENV RPC_API_HOST="http://localhost:4000"
ENV DATABASE_URL="ecto://postgres:postgres@localhost:5432/starknet_explorer_dev"

RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

COPY . .

RUN mix local.hex --force
RUN mix deps.get

CMD mix phx.server

