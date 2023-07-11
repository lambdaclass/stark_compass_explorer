# StarknetExplorer
![image](https://github.com/lambdaclass/starknet_explorer/assets/569014/4f3f5795-33ac-4592-8ba8-804df964016a)

## Requirements

- Docker
- Erlang/OTP 25
- Elixir 1.15, compiled with OTP 25

## Local development

To run it locally, you'll need to set the RPC API url of the network. If you're using a provider like Infura, this will look something like this:

```
https://starknet-mainnet.infura.io/v3/your_api_key
```

Set the following environment variable with the url mentioned above

```
export RPC_API_HOST=your_rpc_hostname
```

then do

```
make setup run
```

This will start postgres, create the database and start a web app in `localhost:4000`.
For local development, you can seed the db with

```
make seed
```

From now on, if you want to restart the app, you can just do:
```
make run
```

To stop postgres:
```
make stop-db
```
