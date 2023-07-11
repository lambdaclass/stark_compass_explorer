FROM hexpm/elixir:1.14.5-erlang-24.3.4.13-debian-bullseye-20230612-slim as builder

# should be overwritten inline/docker-compose
ENV RPC_API_HOST="http://localhost:4000"

RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

COPY . .

RUN mix local.hex --force
RUN mix deps.get

RUN mix ecto.create
RUN mix ecto.migrate

CMD make run

