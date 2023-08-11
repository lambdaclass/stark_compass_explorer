# StarknetExplorer
![image](./priv/static/images/explorer_preview.png)

## Requirements

- SQLite
- Erlang 25
- Elixir 1.15, compiled with OTP 25
- Docker (optional)

## Local development

### RPC Provider
To run it locally, you'll need to set the RPC API url of the network. If you're using a provider like Infura, this will look something like this:

```
https://starknet-mainnet.infura.io/v3/your_api_key
```

Set the following environment variable with the url mentioned above

```
export RPC_API_HOST=your_rpc_hostname
```

### RPC with Juno
You can also use the docker provided juno with
```
make juno
```
You'll need a Mainnet Ethereum RPC provider for this to
work, set with the env variable `$ETH_NODE_URL`, mind you
it must be a websocket url.

### Up and running
If you're on MacOS, you already have SQLite.
On Linux, your distro's repo will most certainly have a package for it.
With a working RPC set and sqlite installed, start the explorer with
```
make setup run
```

This will setup the explorer start it on `localhost:4000`.

From now on, if you want to restart the app, you can just do:
```
make run
```
