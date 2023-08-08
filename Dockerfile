FROM elixir:1.14.5-otp-25 as builder

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain=1.69
ENV PATH="/root/.cargo/bin:${PATH}"

# Install wasm-pack
RUN curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh

# Install nodejs v16.20.0
RUN arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/x64/) && \
    wget https://nodejs.org/dist/v16.20.0/node-v16.20.0-linux-${arch}.tar.gz && \
    tar -xzvf node-v16.20.0-linux-${arch}.tar.gz && \
    cp -r node-v16.20.0-linux-${arch}/* /usr/local/

ENV MIX_ENV=prod

WORKDIR /explorer
COPY . .
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix archive.install --force hex phx_new
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile
RUN mix assets.setup
RUN mix assets.build
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
