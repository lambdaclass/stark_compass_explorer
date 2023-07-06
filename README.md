# StarknetExplorer

## Requirements

- Docker
- Erlang/OTP 25
- Elixir 1.15, compiled with OTP 25

## Local development

To run it locally, you'll need an [Infura](https://www.infura.io/) account and API key. With that done, set the following environment variable with said API key:

```
export INFURA_API_KEY=your_api_key
```

then do

```
make setup run
```

This will start postgres, create the database and start a web app in `localhost:4000`.

From now on, if you want to restart the app, you can just do:
```
make run
```

To stop postgres:
```
make stop-db
```
