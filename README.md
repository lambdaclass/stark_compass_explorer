# StarkCompass
![image](./priv/static/images/explorer_preview.png)

- [StarkCompass](#starkcompass)
  - [Requirements](#requirements)
  - [Local development](#local-development)
    - [Setup](#setup)
    - [RPC Provider](#rpc-provider)
    - [RPC with Juno](#rpc-with-juno)
    - [Up and running](#up-and-running)
  - [State Synchronization System](#state-synchronization-system)
    - [BlockchainListener](#blockchainlistener)
    - [BlockchainFetcher](#blockchainfetcher)
    - [BlockchainUpdater](#blockchainupdater)
    - [WARNING ⚠️](#warning-️)
  - [Using Stark Compass with PostgreSQL](#using-stark-compass-with-postgresql)

## Requirements
- SQLite
- Erlang 25
- Elixir 1.15, compiled with OTP 25
- Docker (optional)

## Local development

If you run `make` it will print out the available targets: 
```
% make            
Usage:
    run   : Starts the Elixir backend server.
    setup : Sets up everything necessary to build and run the explorer.
    deps  : Gets code dependencies.
    db    : Runs the database creation and migration steps.
```

### Setup
Once you have the requirements installed and set up, you can proceed to building and running the project. 

```bash
make setup
```

### RPC Provider

You now have the choice of connecting the explorer to an RPC API provider of your choice, e.g. Infura with an API key, or by running your own Juno node. 

To run it locally, you'll need to set the RPC API url of the network. If you're using a provider like Infura, this will look something like this: `https://starknet-mainnet.infura.io/v3/your_api_key`

Set the following environment variables:

```bash
export RPC_API_HOST=your_rpc_hostname
export TESTNET_RPC_API_HOST=testnet_rpc_hostname
export TESTNET_2_RPC_API_HOST=testnet_2_rpc_hostname
```

Some of the desired data related to Starknet is not currently available through the RPC standard. Because of this, the explorer also gets information through the feeder gateway API. In order to enable this functionality, the variable `ENABLE_GATEWAY_DATA` needs to be set to `true` (if nothing is set, it will default to `false`). Note that this is only pertinent to the Starknet networks and not other particular networks that are compatible with the RPC standard.

```bash
export ENABLE_GATEWAY_DATA=true
``````

### RPC with Juno

```bash
docker-compose up juno
```

You'll need a Mainnet Ethereum RPC provider for this to
work, set with the env variable `$ETH_NODE_URL`, mind you
it must be a websocket url.

### Up and running
If you're on MacOS, you already have SQLite.
On Linux, your distro's repo will most certainly have a package for it.
With a working RPC set and sqlite installed, start the explorer with

```bash
make setup run
```

This will setup the explorer start it on `localhost:4000`.

From now on, if you want to restart the app, you can just do:

```bash
make run
```

## State Synchronization System

You can fill the database with RPC provided data with 3 tools we provide:

### BlockchainListener

Which will store any new blocks, transactions, transaction receipts, events and
messages. When starting the application, the Listener will hit the RPC to get the current block height,
and will start fetching from that block.
To enable this process, before starting the explorer, set this env var:

```bash
export ENABLE_LISTENER="true"
```

When using the `dev` and `test` environments, it will only listen for `mainnet` blocks.
In `prod` it will use all three networks (`mainnet`, `testnet`, `tesnet2`).

### BlockchainFetcher
Which will store any new blocks, transactions, transaction receipts, events and
messages. When starting the application, the Fetcher will hit the RPC to get the current block height and
will fetch from that block backwards, until the block 0 is reached.

To enable this process, before starting the explorer, set this env var:

```bash
export ENABLE_FETCHER="true"
```
When using the `dev` and `test` environments, it will only fetch for `mainnet` blocks.
In `prod` it will use all three networks (`mainnet`, `testnet`, `tesnet2`).


### BlockchainUpdater

The updater will look in the DB for any entity whose status is not finalized, and will try to update the status for those entries by hitting the RPC and check if the status needs an update.
It looks for update for:
- Block with status different than `"ACCEPTED_ON_L1"`.
- Transaction with status different than `"ACCEPTED_ON_L1"` or `"REVERTED"`.

To enable this process, before starting the explorer, set this env var:

```bash
export ENABLE_UPDATER="true"
```
When using the `dev` and `test` environments, it will only update `mainnet` blocks.
In `prod` it will use all three networks (`mainnet`, `testnet`, `tesnet2`).

### WARNING ⚠️

There are 3 things to keep in mind here:
1. Amount of requests:
   If you have any constraint on how many requests you can make: keep an eye on that,
   because the State Synchronization System can do a lot of requests per second.
2. Disk Usage: We're still measuring it, but we expect it to be considerable 
   after running it for a couple of days.
3. If you are going to sync a large amount of blocks, we *strongly* suggest to use PostgreSQL instead of SQLite. You can check how to swap the DB in [this section](#using-stark-compass-with-postgresql).

The db file will be stored under `/priv/repo`.

## Using Stark Compass with PostgreSQL

If you want to handle multiple concurrent connections and a more scalable application, you may consider using PostgreSQL.

Stark Compass provides support for that, you can set the credentials to the PostgreSQL DB in the `runtime.exs` and set the environment variable `DB_TYPE` to `postgresql`.

```bash
export DB_TYPE=postgresql
```

If you previously compiled the application without the flag, you need to clean the dependencies and then compile again:

```bash
mix deps.clean --all
mix deps.get
```

A Docker image of PostgreSQL is provided in the `docker-compose.yml` file, you can get the service up and running with the command:

```bash
docker-compose up postgres
```
