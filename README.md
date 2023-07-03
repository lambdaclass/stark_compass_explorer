# StarknetExplorer

## Requirements

- Erlang/OTP 25
- Elixir 1.15, compiled with OTP 25

## Local development

To run it locally, you'll need an [Infura](https://www.infura.io/) account and API key. With that done, set the following environment variable with said API key:

```
export INFURA_API_KEY=your_api_key
```

then do

```
make run
```

This will setup a web app in `localhost:4000`.
