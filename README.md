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
    - [WARNING ⚠️](#warning-️)
  - [Using Stark Compass with PostgreSQL](#using-stark-compass-with-postgresql)
  - [Remaining Tasks](#remaining-tasks)
    - [Short/Mid Term Goals:](#shortmid-term-goals)
    - [Long Term Goals:](#long-term-goals)
  - [Contributing](#contributing)
    - [Get in Touch](#get-in-touch)

## Requirements
- SQLite
- Erlang 25
- Elixir 1.15, compiled with OTP 25
- Docker (optional)
- PostgreSQL (optional)

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

The State Synchronization System facilitates the population of the database with data obtained through RPC. This system is accompanied by a utility tool known as the StateSyncSystem, which serves three fundamental tasks:

1. **Listening for New Blocks**: Upon application initialization, the StateSyncSystem constantly monitors the RPC for the latest block. At regular intervals, it attempts to retrieve any newly available blocks from the RPC. If a block is not already stored in the database, the system will insert it.

2. **Fetching Previous Blocks**: Upon application startup, the system identifies the lowest block number currently stored in the database (if any) or, alternatively, uses the latest block from the RPC as a starting point. It then initiates a process that, at regular intervals, retrieves earlier blocks in a reverse chronological order, continuing until it reaches block 0.

3. **Updating Unfinished Blocks and Transactions**: If the finality status of a block or a transaction remains unattained, the system periodically attempts to update the database by checking for any available updates.

To activate this synchronization process, you can configure the following environment variables before launching the explorer:

```bash
export ENABLE_MAINNET_SYNC=true
export ENABLE_TESTNET_SYNC=true
export ENABLE_TESTNET2_SYNC=true
```

It's worth noting that you have the flexibility to select which networks you want to synchronize by adjusting these environment variables.

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

## Remaining Tasks

### Short/Mid Term Goals:

- **Preserve Leading Zeros in Hash Storage**: Ensure that leading zeros are not removed when storing hashes in the database, or adapt the Search Bar to accommodate missing leading zeros.
- **Customizable Branding**: Allow for the customization of logos, favicons, and navbar text.
- **Enhance Integration**: Ensure easy integration with other projects and data sources without reliance on the feeder gateway.

### Long Term Goals:

- **Optimize Trace Data Handling**: Eliminate the need to access the feeder gateway for trace data by either storing trace data internally or recording internal calls.
- **Analytics**: Show statistics like TVL, historical data, plots, etc.

## Contributing

We appreciate your interest in contributing to the Stark Compass Explorer! Your contributions can help make this project even better. 

PRs are more than welcome if you want to collaborate to the project. If you don't know how to implement a feature, you are still welcome to create an issue!

### Get in Touch

If you have any questions, suggestions, or if you'd like to contribute in any way, please feel free to reach out to us:

- **Telegram**: [Lambda Starknet](https://t.me/LambdaStarkNet)
- **GitHub Issues**: [Open an Issue](https://github.com/lambdaclass/stark_compass_explorer/issues)
