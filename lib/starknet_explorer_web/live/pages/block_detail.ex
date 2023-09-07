defmodule StarknetExplorerWeb.BlockDetailLive do
  require Logger
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Data
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.BlockUtils
  alias StarknetExplorer.S3
  alias StarknetExplorer.Gateway

  @chunk_size 30

  @common_event_hash_to_name %{
    "0x99cd8bde557814842a3121e8ddfd433a539b8c9f14bf31ebf108d12e6196e9" => "Transfer",
    "0x134692b230b9e1ffa39098904722134159652b09c5bc41d88d6698779d228ff" => "Approval",
    "0x1390fd803c110ac71730ece1decfc34eb1d0088e295d4f1b125dda1e0c5b9ff" => "OwnershipTransferred",
    "0x3774b0545aabb37c45c1eddc6a7dae57de498aae6d5e3589e362d4b4323a533" => "governor_nominated",
    "0x19b0b96cb0e0029733092527bca81129db5f327c064199b31ed8a9f857fdee3" => "nomination_cancelled",
    "0x3b7aa6f257721ed65dae25f8a1ee350b92d02cd59a9dcfb1fc4e8887be194ec" => "governor_removed",
    "0x4595132f9b33b7077ebf2e7f3eb746a8e0a6d5c337c71cd8f9bf46cac3cfd7" => "governance_accepted",
    "0x2e8a4ec40a36a027111fafdb6a46746ff1b0125d5067fbaebd8b5f227185a1e" => "implementation_added",
    "0x3ef46b1f8c5c94765c1d63fb24422442ea26f49289a18ba89c4138ebf450f6c" =>
      "implementation_removed",
    "0x1205ec81562fc65c367136bd2fe1c0fff2d1986f70e4ba365e5dd747bd08753" =>
      "implementation_upgraded",
    "0x2c6e1be7705f64cd4ec61d51a0c8e64ceed5e787198bd3291469fb870578922" =>
      "implementation_finalized",
    "0x2db340e6c609371026731f47050d3976552c89b4fbb012941663841c59d1af3" => "Upgraded",
    "0x120650e571756796b93f65826a80b3511d4f3a06808e82cb37407903b09d995" => "AdminChanged",
    "0xe316f0d9d2a3affa97de1d99bb2aac0538e2666d0d8545545ead241ef0ccab" => "Swap",
    "0xe14a408baf7f453312eec68e9b7d728ec5337fbdf671f917ee8c80f3255232" => "Sync",
    "0x5ad857f66a5b55f1301ff1ed7e098ac6d4433148f0b72ebc4a2945ab85ad53" => "transaction_executed",
    "0x10c19bef19acd19b2c9f4caa40fd47c9fbe1d9f91324d44dcd36be2dae96784" => "account_created",
    "0x243e1de00e8a6bc1dfa3e950e6ade24c52e4a25de4dee7fb5affe918ad1e744" => "Burn",
    "0x34e55c1cd55f1338241b50d352f0e91c7e4ffad0e4271d64eb347589ebdfd16" => "Mint"
  }

  @common_event_hashes Map.keys(@common_event_hash_to_name)

  defp num_or_hash(<<"0x", _rest::binary>>), do: :hash
  defp num_or_hash(_num), do: :num

  defp get_block_proof(block_hash) do
    try do
      case Application.get_env(:starknet_explorer, :prover_storage) do
        "s3" ->
          response = S3.get_object!("#{block_hash}" <> "-proof")
          :erlang.binary_to_list(response.body)

        _ ->
          proofs_dir = Application.get_env(:starknet_explorer, :proofs_root_dir)

          case File.read(Path.join(proofs_dir, "#{block_hash}" <> "-proof")) do
            {:ok, content} ->
              :erlang.binary_to_list(content)

            _ ->
              Logger.info("Failed to read binary file #{block_hash}-proof.")
              :not_found
          end
      end
    rescue
      _ ->
        :not_found
    end
  end

  defp get_block_public_inputs(block_hash) do
    try do
      case Application.get_env(:starknet_explorer, :prover_storage) do
        "s3" ->
          response = S3.get_object!("#{block_hash}" <> "-public_inputs")
          :erlang.binary_to_list(response.body)

        _ ->
          proofs_dir = Application.get_env(:starknet_explorer, :proofs_root_dir)

          case File.read(Path.join(proofs_dir, "#{block_hash}" <> "-public_inputs")) do
            {:ok, content} ->
              :erlang.binary_to_list(content)

            _ ->
              Logger.info("Failed to read binary file #{block_hash}-public_inputs.")
              :not_found
          end
      end
    rescue
      _ ->
        :not_found
    end
  end

  defp block_detail_header(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row justify-between mb-5 lg:mb-0">
      <h2>Block <span class="font-semibold">#<%= @block.number %></span></h2>
      <div class="text-gray-400">
        <%= @block.timestamp
        |> DateTime.from_unix()
        |> then(fn {:ok, time} -> time end)
        |> Calendar.strftime("%c") %> UTC
      </div>
    </div>
    <div
      id="dropdown"
      class="dropdown relative bg-[#232331] p-5 mb-5 rounded-md lg:hidden"
      phx-hook="Dropdown"
    >
      <span class="networkSelected capitalize"><%= assigns.view %></span>
      <span class="absolute inset-y-0 right-5 transform translate-1/2 flex items-center">
        <img class="transform rotate-90 w-5 h-5" src={~p"/images/dropdown.svg"} />
      </span>
    </div>
    <div class="options hidden">
      <div
        class={"option #{if assigns.view == "overview", do: "lg:!border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="overview"
      >
        Overview
      </div>
      <div
        class={"option #{if assigns.view == "transactions", do: "lg:!border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="transactions"
      >
        Transactions
      </div>
      <div
        class={"option #{if assigns.view == "events", do: "lg:!border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="events"
        ,
      >
        Events
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params = %{"number_or_hash" => param}, _session, socket) do
    {:ok, block} =
      case num_or_hash(param) do
        :hash ->
          Data.block_by_hash(param, socket.assigns.network)

        :num ->
          {num, ""} = Integer.parse(param)
          Data.block_by_number(num, socket.assigns.network)
      end

    assigns = [
      gas_price: "Loading...",
      execution_resources: "Loading",
      block: block,
      view: "overview",
      verification: "Pending",
      enable_verification: Application.get_env(:starknet_explorer, :enable_block_verification),
      block_age: Utils.get_block_age(block)
    ]

    Process.send_after(self(), :get_gateway_information, 200)
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_info(:get_gateway_information, socket = %Phoenix.LiveView.Socket{}) do
    {gas_assign, resources_assign} =
      case Gateway.fetch_block(socket.assigns.block.number) do
        {:ok, block = %{"gas_price" => gas_price}} ->
          execution_resources = BlockUtils.calculate_gateway_block_steps(block)
          {gas_price, execution_resources}

        {:error, _} ->
          {"Unavailable", "Unavailable"}
      end

    socket =
      socket
      |> assign(:gas_price, gas_assign)
      |> assign(:execution_resources, resources_assign)

    {:noreply, socket}
  end

  defp get_previous_continuation_token(token) when token < @chunk_size, do: 0
  defp get_previous_continuation_token(token), do: token - @chunk_size

  defp get_event_name(%{"keys" => [event_name_hashed | _]} = _event, _network)
       when event_name_hashed in @common_event_hashes,
       do: @common_event_hash_to_name[event_name_hashed]

  defp get_event_name(%{"keys" => [event_name_hashed | _]} = _event, _network) do
    # Data.get_class_at(event["block_number"], event["from_address"], network)
    # |> Map.get("abi")
    # |> Enum.filter(fn abi_entry -> abi_entry["type"] == "event" end)
    # |> IO.inspect()
    # |> Enum.map(&get_event_name_in_common(&1))
    Utils.shorten_block_hash(event_name_hashed)
  end

  def handle_event("inc_events", _value, socket) do
    continuation_token = Map.get(socket.assigns, :idx_first, 0) + @chunk_size

    events =
      Data.get_block_events_paginated(
        socket.assigns.block.hash,
        %{
          "chunk_size" => @chunk_size,
          "continuation_token" => Integer.to_string(continuation_token)
        },
        socket.assigns.network
      )["events"]

    assigns = [
      events: events,
      view: "events",
      idx_first: continuation_token,
      idx_last: length(events) + continuation_token
    ]

    {:noreply, assign(socket, assigns)}
  end

  def handle_event("dec_events", _value, socket) do
    continuation_token =
      get_previous_continuation_token(Map.get(socket.assigns, :idx_first, @chunk_size))

    events =
      Data.get_block_events_paginated(
        socket.assigns.block.hash,
        %{
          "chunk_size" => @chunk_size,
          "continuation_token" => Integer.to_string(continuation_token)
        },
        socket.assigns.network
      )["events"]

    assigns = [
      events: events,
      view: "events",
      idx_first: continuation_token,
      idx_last: length(events) + continuation_token
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event(
        "select-view",
        %{"view" => "events"},
        socket
      ) do
    events =
      Data.get_block_events_paginated(
        socket.assigns.block.hash,
        %{"chunk_size" => @chunk_size},
        socket.assigns.network
      )

    assigns = [
      events: events["events"],
      view: "events",
      idx_first: 0,
      idx_last: @chunk_size,
      chunk_size: @chunk_size
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("select-view", %{"view" => view}, socket) do
    socket = assign(socket, :view, view)
    {:noreply, socket}
  end

  @impl true
  def handle_event("get-block-proof", %{"block_hash" => block_hash}, socket) do
    proof = get_block_proof(block_hash)
    public_inputs = get_block_public_inputs(block_hash)
    {:reply, %{public_inputs: public_inputs, proof: proof}, socket}
  end

  @impl true
  def handle_event("block-verified", %{"result" => result}, socket) do
    verification =
      case result do
        true ->
          "Verified"

        false ->
          "Failed"
      end

    {
      :noreply,
      assign(socket, verification: verification)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash,
      session: %{"network" => @network}
    ) %>
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <%= block_detail_header(assigns) %>
      <%= render_info(assigns) %>
    </div>
    """
  end

  def render_info(assigns = %{block: _, view: "transactions"}) do
    ~H"""
    <div class="grid-3 table-th !pt-7 border-t border-gray-700">
      <div>Hash</div>
      <div>Type</div>
      <div>Version</div>
    </div>
    <%= for _transaction = %{"transaction_hash" => hash, "type" => type, "version" => version} <- @block.transactions do %>
      <div class="grid-3 custom-list-item">
        <div>
          <div class="list-h">Hash</div>
          <div
            class="flex gap-2 items-center copy-container"
            id={"copy-transaction-hash-#{hash}"}
            phx-hook="Copy"
          >
            <div class="relative">
              <div class="break-all text-hover-blue"><%= Utils.shorten_block_hash(hash) %></div>
              <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                <div class="relative">
                  <img class="copy-btn copy-text w-4 h-4" src={~p"/images/copy.svg"} data-text={hash} />
                  <img
                    class="copy-check absolute top-0 left-0 w-4 h-4 opacity-0 pointer-events-none"
                    src={~p"/images/check-square.svg"}
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
        <div>
          <div class="list-h">Type</div>
          <div>
            <span class={"#{if type == "INVOKE", do: "violet-label", else: "lilac-label"}"}>
              <%= type %>
            </span>
          </div>
        </div>
        <div>
          <div class="list-h">Version</div>
          <div><%= version %></div>
        </div>
      </div>
    <% end %>
    """
  end

  # TODO:
  # Do not hardcode:
  # - Total Execeution Resources
  # - Gas Price
  def render_info(assigns = %{block: _block, view: "overview", enable_verification: _}) do
    ~H"""
    <%= if @enable_verification do %>
      <div class="grid-4 custom-list-item">
        <div class="block-label">
          Local Verification
        </div>
        <div class="col-span-3">
          <div class="flex flex-col lg:flex-row items-start lg:items-center gap-2">
            <span
              id="block_verifier"
              class={"#{if @verification == "Pending", do: "pink-label"} #{if @verification == "Verified", do: "green-label"} #{if @verification == "Failed", do: "violet-label"}"}
              data-hash={@block.hash}
              phx-hook="BlockVerifier"
            >
              <%= @verification %>
            </span>
          </div>
        </div>
      </div>
    <% end %>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Block Hash</div>
      <div
        class="copy-container col-span-3 text-hover-blue"
        id={"copy-block-hash-#{@block.number}"}
        phx-hook="Copy"
      >
        <div class="relative">
          <%= Utils.shorten_block_hash(@block.hash) %>
          <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
            <div class="relative">
              <img
                class="copy-btn copy-text w-4 h-4"
                src={~p"/images/copy.svg"}
                data-text={@block.hash}
              />
              <img
                class="copy-check absolute top-0 left-0 w-4 h-4 opacity-0 pointer-events-none"
                src={~p"/images/check-square.svg"}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Block Status</div>
      <div class="col-span-3">
        <span class={"#{if @block.status == "ACCEPTED_ON_L2", do: "green-label"} #{if @block.status == "ACCEPTED_ON_L1", do: "blue-label"} #{if @block.status == "PENDING", do: "pink-label"}"}>
          <%= @block.status %>
        </span>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">State Root</div>
      <div class="copy-container col-span-3" id={"copy-block-root-#{@block.number}"} phx-hook="Copy">
        <div class="relative">
          <%= Utils.shorten_block_hash(@block.new_root) %>
          <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
            <div class="relative">
              <img
                class="copy-btn copy-text w-4 h-4"
                src={~p"/images/copy.svg"}
                data-text={@block.new_root}
              />
              <img
                class="copy-check absolute top-0 left-0 w-4 h-4 opacity-0 pointer-events-none"
                src={~p"/images/check-square.svg"}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Parent Hash</div>
      <div class="copy-container col-span-3" id={"copy-block-parent-#{@block.number}"} phx-hook="Copy">
        <div class="relative">
          <%= Utils.shorten_block_hash(@block.parent_hash) %>
          <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
            <div class="relative">
              <img
                class="copy-btn copy-text w-4 h-4"
                src={~p"/images/copy.svg"}
                data-text={@block.parent_hash}
              />
              <img
                class="copy-check absolute top-0 left-0 w-4 h-4 opacity-0 pointer-events-none"
                src={~p"/images/check-square.svg"}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">
        Sequencer Address
      </div>
      <div
        class="copy-container col-span-3 text-hover-blue"
        id={"copy-block-sequencer-#{@block.number}"}
        phx-hook="Copy"
      >
        <div class="relative">
          <%= Utils.shorten_block_hash(@block.sequencer_address) %>
          <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
            <div class="relative">
              <img
                class="copy-btn copy-text w-4 h-4"
                src={~p"/images/copy.svg"}
                data-text={@block.sequencer_address}
              />
              <img
                class="copy-check absolute top-0 left-0 w-4 h-4 opacity-0 pointer-events-none"
                src={~p"/images/check-square.svg"}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">
        Gas Price
      </div>
      <div class="col-span-3">
        <div class="flex flex-col lg:flex-row items-start lg:items-center gap-2">
          <div
            class="break-all bg-se-cash-green/10 text-se-cash-green rounded-full px-4 py-1"
            phx-update="replace"
            id="gas-price"
          >
            <%= "#{@gas_price} ETH" %>
          </div>
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">
        Total execution resources
      </div>
      <div class="col-span-3">
        <div class="flex flex-col lg:flex-row items-start lg:items-center gap-2">
          <%= "#{@execution_resources} steps" %>
        </div>
      </div>
    </div>
    """
  end

  def render_info(assigns = %{block: _block, view: "events"}) do
    ~H"""
    <div class="table-th !pt-7 border-t border-gray-700 grid-6">
      <div>Identifier</div>
      <div>Block Number</div>
      <div>Transaction Hash</div>
      <div>Name</div>
      <div>From Address</div>
      <div>Age</div>
    </div>
    <%= for {idx, event = %{"block_number" => block_number, "from_address" => from_address, "transaction_hash" => tx_hash}} <- Enum.with_index(@events, fn element, index -> {index, element} end) do %>
      <div class="custom-list-item grid-6">
        <div>
          <div class="list-h">Identifier</div>
          <% identifier =
            Integer.to_string(block_number) <> "_" <> Integer.to_string(idx + @idx_first) %>
          <%= live_redirect(
            identifier,
            to: ~p"/#{@network}/events/#{identifier}",
            class: "text-hover-blue"
          ) %>
          <div></div>
        </div>
        <div>
          <div class="list-h">Block Number</div>
          <div>
            <span class="blue-label">
              <%= live_redirect(to_string(block_number),
                to: ~p"/#{@network}/blocks/#{@block.hash}"
              ) %>
            </span>
          </div>
        </div>
        <div>
          <div class="list-h">Transaction Hash</div>
          <div>
            <%= live_redirect(tx_hash |> Utils.shorten_block_hash(),
              to: ~p"/#{@network}/transactions/#{tx_hash}"
            ) %>
          </div>
        </div>
        <div>
          <div class="list-h">Name</div>
          <div>
            <%= get_event_name(event, @network) %>
          </div>
        </div>
        <div class="list-h">From Address</div>
        <div>
          <%= live_redirect(from_address |> Utils.shorten_block_hash(),
            to: ~p"/#{@network}/contracts/#{from_address}"
          ) %>
        </div>
        <div>
          <div class="list-h">Age</div>
          <div><%= @block_age %></div>
        </div>
      </div>
    <% end %>
    <div>
      <%= if @idx_first != 0 do %>
        <button phx-click="dec_events">Previous</button>
      <% end %>
      Showing from <%= @idx_first %> to <%= @idx_last %>
      <%= if length(@events) >= @chunk_size do %>
        <button phx-click="inc_events">Next</button>
      <% end %>
    </div>
    """
  end
end
