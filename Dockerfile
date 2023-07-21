FROM elixir:1.14.5-otp-25 as builder

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain=1.70
ENV PATH="/root/.cargo/bin:${PATH}"

# Install wasm-pack
RUN curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh

ENV MIX_ENV=prod

WORKDIR /explorer
COPY . .

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix archive.install --force hex phx_new
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile
RUN mix assets.setup
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
