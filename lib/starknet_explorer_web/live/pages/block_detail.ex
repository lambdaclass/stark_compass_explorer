defmodule StarknetExplorerWeb.BlockDetailLive do
  require Logger
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Data
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.BlockUtils
  alias StarknetExplorer.S3
  alias StarknetExplorer.Message
  alias StarknetExplorer.Gateway
  alias StarknetExplorer.Events

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
      class="dropdown relative bg-[#232331] p-5 mb-2 rounded-md lg:hidden"
      phx-hook="Dropdown"
    >
      <span class="networkSelected capitalize"><%= assigns.view %></span>
      <span class="absolute inset-y-0 right-5 transform translate-1/2 flex items-center">
        <img class="transform rotate-90 w-5 h-5" src={~p"/images/dropdown.svg"} />
      </span>
    </div>
    <div class="options hidden">
      <div
        class={"option #{if assigns.view == "overview", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
        phx-click="select-view"
        ,
        phx-value-view="overview"
      >
        Overview
      </div>
      <div
        class={"option #{if assigns.view == "transactions", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
        phx-click="select-view"
        ,
        phx-value-view="transactions"
      >
        Transactions
      </div>
      <div
        class={"option #{if assigns.view == "messages", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
        phx-click="select-view"
        ,
        phx-value-view="messages"
      >
        Message Logs
      </div>
      <div
        class={"option #{if assigns.view == "events", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
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

    {:ok, receipts} = Data.receipts_by_block(block, socket.assigns.network)

    # add receipts to each transaction inside the block
    block = %{
      block
      | transactions:
          Enum.map(block.transactions, fn tx ->
            %{tx | receipt: Enum.find(receipts, nil, fn r -> r.transaction_hash == tx.hash end)}
          end)
    }

    # note: most transactions receipt do not contain messages
    l1_to_l2_messages =
      block.transactions |> Enum.map(&Message.from_transaction/1) |> Enum.reject(&is_nil/1)

    messages =
      (receipts |> Enum.flat_map(&Message.from_transaction_receipt/1)) ++ l1_to_l2_messages

    assigns = [
      gas_price: Utils.hex_wei_to_eth(block.gas_fee_in_wei),
      execution_resources: block.execution_resources,
      block: block,
      messages: messages,
      view: "overview",
      verification: "Pending",
      enable_verification: Application.get_env(:starknet_explorer, :enable_block_verification),
      block_age: Utils.get_block_age(block)
    ]

    case Application.get_env(:starknet_explorer, :enable_gateway_data) do
      #      true ->
      #       Process.send_after(self(), :get_gateway_information, 200)

      _ ->
        :skip
    end

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_info(:get_gateway_information, socket = %Phoenix.LiveView.Socket{}) do
    {gas_assign, resources_assign} =
      case Gateway.fetch_block(socket.assigns.block.number, socket.assigns.network) do
        {:ok, block = %{"gas_price" => gas_price}} ->
          execution_resources = BlockUtils.calculate_gateway_block_steps(block)
          gas_price = Utils.hex_wei_to_eth(gas_price)

          {gas_price, execution_resources}

        {:ok, err} ->
          Logger.error(err)
          {"Unavailable", "Unavailable"}

        {:error, _} ->
          {"Unavailable", "Unavailable"}
      end

    socket =
      socket
      |> assign(:gas_price, gas_assign)
      |> assign(:execution_resources, resources_assign)

    {:noreply, socket}
  end

  def handle_event("inc_events", _value, socket) do
    new_page_number = socket.assigns.page.page_number + 1

    page =
      Events.paginate_events(
        %{page: new_page_number},
        socket.assigns.block.number,
        socket.assigns.network
      )

    assigns = [
      page: page,
      view: "events"
    ]

    {:noreply, assign(socket, assigns)}
  end

  def handle_event("dec_events", _value, socket) do
    new_page_number = socket.assigns.page.page_number - 1

    page =
      Events.paginate_events(
        %{page: new_page_number},
        socket.assigns.block.number,
        socket.assigns.network
      )

    assigns = [
      page: page,
      view: "events"
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event(
        "select-view",
        %{"view" => "events"},
        socket
      ) do
    page =
      Events.paginate_events(
        %{page: 0},
        socket.assigns.block.number,
        socket.assigns.network
      )

    assigns = [
      view: "events",
      page: page
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
    <div class="grid-6 table-th !pt-7">
      <div>Hash</div>
      <div>Type</div>
      <div>Version</div>
      <div>Status</div>
      <div>Address</div>
      <div>Age</div>
    </div>
    <%= for transaction = %{hash: hash, type: type, version: version, sender_address: sender_address} <- @block.transactions do %>
      <div class="grid-6 custom-list-item">
        <div>
          <div class="list-h">Hash</div>
          <div
            class="flex gap-2 items-center copy-container"
            id={"copy-transaction-hash-#{hash}"}
            phx-hook="Copy"
          >
            <div class="relative">
              <div class="break-all text-hover-blue">
                <a href={Utils.network_path(@network, "transactions/#{hash}")} class="text-hover-blue">
                  <span><%= Utils.shorten_block_hash(hash) %></span>
                </a>
              </div>
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
              <!-- TODO: add more statuses -->
              <%= type %>
            </span>
          </div>
        </div>
        <div>
          <div class="list-h">Version</div>
          <div><%= version %></div>
        </div>
        <div>
          <div class="list-h">Status</div>
          <span class={"#{if transaction.receipt.finality_status == "ACCEPTED_ON_L2", do: "green-label"} #{if transaction.receipt.finality_status == "ACCEPTED_ON_L1", do: "blue-label"} #{if transaction.receipt.finality_status == "PENDING", do: "pink-label"}"}>
            <%= transaction.receipt.finality_status %>
          </span>
        </div>
        <div>
          <div class="list-h">Address</div>
          <div
            class="flex gap-2 items-center copy-container"
            id={"copy-transaction-hash-#{sender_address}"}
            phx-hook="Copy"
          >
            <div class="relative">
              <div class="break-all text-hover-blue">
                <%= Utils.shorten_block_hash(sender_address) %>
              </div>
              <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                <div class="relative">
                  <img
                    class="copy-btn copy-text w-4 h-4"
                    src={~p"/images/copy.svg"}
                    data-text={sender_address}
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
        <div>
          <div class="list-h">Age</div>
          <div><%= Utils.get_block_age(@block) %></div>
        </div>
      </div>
    <% end %>
    """
  end

  def render_info(assigns = %{block: _, view: "messages"}) do
    ~H"""
    <div class="table-block">
      <div class="grid-6 table-th">
        <div>Message Hash</div>
        <div>Direction</div>
        <div>Type</div>
        <div>From Address</div>
        <div>To Address</div>
        <div>Transaction Hash</div>
      </div>
      <%= for message <- @messages do %>
        <div class="grid-6 custom-list-item">
          <div>
            <div class="list-h">Message Hash</div>
            <div
              class="flex gap-2 items-center copy-container"
              id={"copy-transaction-hash-#{message.message_hash}"}
              phx-hook="Copy"
            >
              <div class="relative">
                <div class="break-all text-hover-blue">
                  <a
                    href={Utils.network_path(@network, "messages/#{message.message_hash}")}
                    class="text-hover-blue"
                  >
                    <span><%= message.message_hash |> Utils.shorten_block_hash() %></span>
                  </a>
                </div>
                <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                  <div class="relative">
                    <img
                      class="copy-btn copy-text w-4 h-4"
                      src={~p"/images/copy.svg"}
                      data-text={message.message_hash}
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
          <div>
            <div class="list-h">Direction</div>
            <%= if Message.is_l2_to_l1(message.type) do %>
              <div><span class="green-label">L2</span>→<span class="blue-label">L1</span></div>
            <% else %>
              <div><span class="blue-label">L1</span>→<span class="green-label">L2</span></div>
            <% end %>
          </div>
          <div>
            <div class="list-h">Type</div>
            <div>
              <%= Message.friendly_message_type(message.type) %>
            </div>
          </div>
          <div>
            <div class="list-h">From Address</div>
            <div
              class="flex gap-2 items-center copy-container"
              id={"copy-transaction-hash-#{message.from_address}"}
              phx-hook="Copy"
            >
              <div class="relative">
                <div class="break-all">
                  <%= if Message.is_l2_to_l1(message.type) do %>
                    <%= Utils.shorten_block_hash(message.from_address) %>
                  <% else %>
                    <%= Utils.shorten_block_hash(message.from_address) %>
                  <% end %>
                </div>
                <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                  <div class="relative">
                    <img
                      class="copy-btn copy-text w-4 h-4"
                      src={~p"/images/copy.svg"}
                      data-text={message.from_address}
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
          <div>
            <div class="list-h">To Address</div>
            <div
              class="flex gap-2 items-center copy-container"
              id={"copy-transaction-hash-#{message.to_address}"}
              phx-hook="Copy"
            >
              <div class="relative">
                <div class="break-all">
                  <%= if Message.is_l2_to_l1(message.type) do %>
                    <%= Utils.shorten_block_hash(message.to_address) %>
                  <% else %>
                    <%= Utils.shorten_block_hash(message.to_address) %>
                  <% end %>
                </div>
                <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                  <div class="relative">
                    <img
                      class="copy-btn copy-text w-4 h-4"
                      src={~p"/images/copy.svg"}
                      data-text={message.to_address}
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
          <div>
            <div class="list-h">Transaction Hash</div>
            <div
              class="flex gap-2 items-center copy-container"
              id={"copy-transaction-hash-#{message.transaction_hash}"}
              phx-hook="Copy"
            >
              <div class="relative">
                <div class="break-all text-hover-blue">
                  <a
                    href={Utils.network_path(@network, "transactions/#{message.transaction_hash}")}
                    class="text-hover-blue"
                  >
                    <span><%= message.transaction_hash |> Utils.shorten_block_hash() %></span>
                  </a>
                </div>
                <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                  <div class="relative">
                    <img
                      class="copy-btn copy-text w-4 h-4"
                      src={~p"/images/copy.svg"}
                      data-text={message.transaction_hash}
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
        </div>
      <% end %>
    </div>
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
    <div class="grid-4 custom-list-item lg:border-transparent">
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
    <%= if Application.get_env(:starknet_explorer, :enable_gateway_data) do %>
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
              <%= @gas_price %> ETH
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
    <% end %>
    """
  end

  def render_info(assigns = %{block: _block, view: "events"}) do
    ~H"""
    <div class="table-th !pt-7 grid-6">
      <div>Identifier</div>
      <div>Block Number</div>
      <div>Transaction Hash</div>
      <div>Name</div>
      <div>From Address</div>
      <div>Age</div>
    </div>
    <%= for event <- @page.entries do %>
      <div class="custom-list-item grid-6">
        <div>
          <div class="list-h">Identifier</div>
          <div
            class="flex gap-2 items-center copy-container"
            id={"copy-transaction-hash-#{event.id}"}
            phx-hook="Copy"
          >
            <div class="relative">
              <div class="break-all text-hover-blue">
                <a href={Utils.network_path(@network, "events/#{event.id}")} class="text-hover-blue">
                  <span><%= event.id %></span>
                </a>
              </div>
              <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                <div class="relative">
                  <img
                    class="copy-btn copy-text w-4 h-4"
                    src={~p"/images/copy.svg"}
                    data-text={event.id}
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
        <div>
          <div class="list-h">Block Number</div>
          <div>
            <span class="blue-label">
              <a href={Utils.network_path(@network, "/blocks/#{@block.hash}")} class="text-hover-blue">
                <span><%= to_string(@block.number) %></span>
              </a>
            </span>
          </div>
        </div>
        <div>
          <div class="list-h">Transaction Hash</div>
          <div>
            <a
              href={Utils.network_path(@network, "/transactions/#{event.transaction_hash}")}
              class="text-hover-blue"
            >
              <span><%= event.transaction_hash |> Utils.shorten_block_hash() %></span>
            </a>
          </div>
        </div>
        <div>
          <div class="list-h">Name</div>
          <div>
            <%= if !String.starts_with?(event.name, "0x") do %>
              <%= event.name %>
            <% else %>
              <div
                class="flex gap-2 items-center copy-container"
                id={"copy-transaction-hash-#{event.name}"}
                phx-hook="Copy"
              >
                <div class="relative">
                  <div class="break-all">
                    <span><%= event.name |> Utils.shorten_block_hash() %></span>
                  </div>
                  <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                    <div class="relative">
                      <img
                        class="copy-btn copy-text w-4 h-4"
                        src={~p"/images/copy.svg"}
                        data-text={event.name}
                      />
                      <img
                        class="copy-check absolute top-0 left-0 w-4 h-4 opacity-0 pointer-events-none"
                        src={~p"/images/check-square.svg"}
                      />
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
        <div class="list-h">From Address</div>
        <div>
          <div
            class="flex gap-2 items-center copy-container"
            id={"copy-from-addr-#{event.id}"}
            phx-hook="Copy"
          >
            <div class="relative">
              <a
                href={Utils.network_path(@network, "/contracts/#{event.from_address}")}
                class="text-hover-blue"
              >
                <span><%= event.from_address |> Utils.shorten_block_hash() %></span>
              </a>
              <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                <div class="relative">
                  <img
                    class="copy-btn copy-text w-4 h-4"
                    src={~p"/images/copy.svg"}
                    data-text={event.from_address}
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
        <div>
          <div class="list-h">Age</div>
          <div><%= @block_age %></div>
        </div>
      </div>
    <% end %>
    <div>
      <%= if @page.page_number != 1 do %>
        <button phx-click="dec_events">Previous</button>
      <% end %>
      Showing from <%= (@page.page_number - 1) * @page.page_size %> to <%= (@page.page_number - 1) *
        @page.page_size + @page.page_size %>
      <%= if @page.page_number != @page.total_pages do %>
        <button phx-click="inc_events">Next</button>
      <% end %>
    </div>
    """
  end
end
