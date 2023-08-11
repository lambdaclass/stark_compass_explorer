FROM elixir:1.14.5-otp-25 as builder

ENV MIX_ENV=prod

WORKDIR /explorer
COPY . .

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get 
RUN mix assets.deploy
RUN mix phx.digest
RUN mix compile
RUN mix release
RUN mix phx.gen.release

FROM elixir:1.14.5-otp-25
ENV MIX_ENV=prod

WORKDIR /explorer

COPY --from=builder /explorer/_build/$MIX_ENV/rel/starknet_explorer .

EXPOSE 4000

CMD ["/explorer/bin/starknet_explorer", "start"]
