FROM elixir:1.14.5-otp-25 as builder

ENV MIX_ENV=prod

WORKDIR /explorer
COPY . .

RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix archive.install --force hex phx_new \
    && mix deps.get --only $MIX_ENV \
    && mix deps.compile \
    && mix assets.deploy \
    && mix phx.digest \
    && mix compile \
    && mix release \
    && mix phx.gen.release

FROM elixir:1.14.5-otp-25
ENV MIX_ENV=prod

WORKDIR /explorer

COPY --from=builder /explorer/_build/$MIX_ENV/rel/starknet_explorer .

EXPOSE 4000

CMD ["/explorer/bin/starknet_explorer", "start"]
