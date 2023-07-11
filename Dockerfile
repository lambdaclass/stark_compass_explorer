FROM hexpm/elixir:1.15.2-erlang-26.0.2-debian-bullseye-20230612-slim

# should be overwritten inline/docker-compose
ENV RPC_API_HOST="http://localhost:4000"
ENV DATABASE_URL="ecto://postgres:postgres@localhost:5432/starknet_explorer_dev"

RUN mix local.hex --force \
    && mix archive.install --force hex phx_new \
    && apt-get update \
    && curl -sL https://deb.nodesource.com/setup_lts.x | bash \
    && apt-get install -y apt-utils \
    && apt-get install -y nodejs \
    && apt-get install -y build-essential \
    && apt-get install -y inotify-tools \
    && mix local.rebar --force

COPY . .

RUN mix local.hex --force
RUN mix deps.get

CMD mix ecto.create && mix ecto.migrate && mix phx.server

