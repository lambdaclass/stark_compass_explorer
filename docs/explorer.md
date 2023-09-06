# Madara Explorer 
## Project 
### Project goals
The goal is to be able to fully visualize Blockchain data from a
webpage, while being open source. You should be able to plug in your
own RPC provider (be it a provider like infura, or a full-node like
Juno or Pathfinder), and be able to have a running instance.
"Visualizing blockchain data" means displaying block, class, contract
and transaction count and details. We currently have part of this, but
the rest is a mocked (i.e. hardcoded) display of the things we want to
show.
### Explorer data
#### What we have
Everything that can be fetched from the [0.4.0 RPC provider spec](https://playground.open-rpc.org/?uiSchema%5BappBar%5D%5Bui:splitView%5D=false&schemaUrl=https://raw.githubusercontent.com/starkware-libs/starknet-specs/master/api/starknet_api_openrpc.json&uiSchema%5BappBar%5D%5Bui:input%5D=false&uiSchema%5BappBar%5D%5Bui:darkMode%5D=true&uiSchema%5BappBar%5D%5Bui:examplesDropdown%5D=false) 
is not mocked, mostly Blocks and their transactions plus some
details. We're also calculating Transactions per second to show them on the index page.
#### What we're missing
Currently, the RPC provider spec is missing information that could be
useful to show everything we want.  On the webpage side, we took the
time to flag what's not real with a "mocked" tag.  A considerable part
of this information can be retreived from Starknet's Gateway. Eg:
Asking said gateway for a block also answers about state diffs,
deployed contracts and so on. So, what we're missing is:
- [Contract classes](https://docs.starknet.io/documentation/architecture_and_concepts/Smart_Contracts/contract-classes/) 
  and deployed contracts (how many there are, their addresses, their code)
  There are a couple of ways on how we think we can get information about contracts.
  1. Ask the gateway for it, while we wait for the RPC spec to catch up.
  2. Check each transaction transaction receipt and get contract information from it.
  3. RPC call starknet_getStateUpdate might be useful.
- Code executed on a transaction (a transaction receipt might throw some light into this),
  this is also related to knowing a contract code + address.
- Amount of [events](https://docs.starknet.io/documentation/architecture_and_concepts/Smart_Contracts/starknet-events/).
- Amount of L2->L1 Messages (L2->L1 messages are part of a transaction receipt).
- Amount of L1->L2 Messages.
### Explorer data
As a way to have a cache and a full view into the network's data,
we're building a sqlite database. Currently it has tables for blocks,
transactions and transaction receipts. The responsibility to fill this database 
is split into two:
1. A process (BlockListener module) listens for height updates and fetches a new block, when available.
   A thing to keep in mind here is that the startup of this process is optional, it must be enabled
   through the `ENABLE_LISTENER` env var.
2. A function (`BlockFetcher.fetch_in_range/1`), that can fetch blocks in a given range.
   This is useful for fetching blocks in batches and check that our db schemas are correct,
   since there are multiple versions of transactions around.
Mind you, this processes are only for mainnet, although doing the same
for other networks is a matter of changing a function call.
If an explorer view (eg. a block detail) wants to show something, it will first
try to fetch it from the database, else it will try to use the RPC provider.
This logic is in the `StarknetExplorer.Data` and `StarknetExplorer.Rpc` modules.
## Pages
The structure of the project is a classic Phoenix + Liveview application,
each view is under the ../lib/live/ folder.
## Minor considerations
- Early on, we relied only on RPC calls, so we used a cache to speed things up.
  There is an active cache for blocks (`StarknetExplorer.Cache.BlockWarmer`) and
  2 passive ones for transactions and requests. One set of these starts for each network,
  when the explorer starts. 
