FROM hexpm/elixir:1.15.4-erlang-24.3.4.13-debian-bullseye-20230612 AS builder

ENV MIX_ENV=prod

WORKDIR /explorer
COPY . .

RUN apt update && apt install -y git

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get 
RUN mix assets.deploy
RUN mix phx.digest
RUN mix compile
RUN mix release
RUN mix phx.gen.release

FROM elixir:1.15.4-otp-24
ENV MIX_ENV=prod

WORKDIR /explorer

COPY --from=builder /explorer/_build/$MIX_ENV/rel/starknet_explorer .

EXPOSE 4000

CMD ["sh", "-c", "/explorer/bin/starknet_explorer eval 'StarknetExplorer.Release.migrate' && /explorer/bin/starknet_explorer start"]
