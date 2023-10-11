defmodule StarknetExplorerWeb.TransactionLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.CoreComponents
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.{Data, Message, Events, Gateway}

  defp transaction_header(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row justify-between mb-5 lg:mb-0">
      <h2>Transaction</h2>
      <div class="font-normal text-gray-400 mt-2 lg:mt-0">
        <%= assigns.block_timestamp
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
      <span class="networkSelected capitalize"><%= assigns.transaction_view %></span>
      <span class="absolute inset-y-0 right-5 transform translate-1/2 flex items-center">
        <img class="transform rotate-90 w-5 h-5" src={~p"/images/dropdown.svg"} />
      </span>
    </div>
    <div class="options hidden">
      <div
        class={"option #{if assigns.transaction_view == "overview", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="overview"
      >
        Overview
      </div>
      <div
        class={"option #{if assigns.transaction_view == "events", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="events"
      >
        Events
        <%= if @rerender? != nil do %>
          ( <%= @events_count %> )
        <% end %>
      </div>
      <div
        class={"option #{if assigns.transaction_view == "message_logs", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="message_logs"
      >
        Message Logs
        <%= if @rerender? != nil do %>
          ( <%= @messages_count %> )
        <% end %>
      </div>
      <%= if @internal_calls != nil  and @transaction_receipt.execution_status != "REVERTED" do %>
        <div
          class={"option #{if assigns.transaction_view == "internal_calls", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"}"}
          phx-click="select-view"
          ,
          phx-value-view="internal_calls"
        >
          Internal Calls
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <%= if @render_header do %>
        <%= transaction_header(assigns) %>
      <% end %>
      <%= if @render_info do %>
        <%= render_info(assigns) %>
      <% end %>
    </div>
    """
  end

  # TODO:
  # find a way to pass ID of copy container so that it isn't the same although you reuse the elements
  def render_info(%{transaction: nil, transaction_receipt: nil} = assigns) do
    ~H"""

    """
  end

  def render_info(%{transaction_view: "events"} = assigns) do
    ~H"""
    <div class="table-th !pt-7 grid-5">
      <div>Identifier</div>
      <div>Block Number</div>
      <div>Name</div>
      <div>From Address</div>
      <div>Age</div>
    </div>
    <%= for event <- @events do %>
      <div class="custom-list-item grid-5">
        <div>
          <div class="list-h">Identifier</div>
          <div class="block-data">
            <div class="hash flex">
              <a href={Utils.network_path(@network, "events/#{event.id}")} class="text-hover-link">
                <%= event.id |> Utils.shorten_block_hash() %>
              </a>
              <CoreComponents.copy_button text={event.id} />
            </div>
          </div>
        </div>
        <div>
          <div class="list-h">Block Number</div>
          <div>
            <span>
              <a href={Utils.network_path(@network, "blocks/#{event.block_number}")} class="type">
                <span><%= to_string(event.block_number) %></span>
              </a>
            </span>
          </div>
        </div>
        <div>
          <div class="list-h">Name</div>
          <div>
            <%= if !String.starts_with?(event.name, "0x") do %>
              <div class={"info-label #{String.downcase(event.name)}"}><%= event.name %></div>
            <% else %>
              <div class="block-data">
                <div class="hash flex">
                  <%= event.name |> Utils.shorten_block_hash() %>
                  <CoreComponents.copy_button text={event.name} />
                </div>
              </div>
            <% end %>
          </div>
        </div>
        <div class="list-h">From Address</div>
        <div class="block-data">
          <div class="hash flex">
            <%= event.from_address |> Utils.shorten_block_hash() %>
            <CoreComponents.copy_button text={event.from_address} />
          </div>
        </div>
        <div>
          <div class="list-h">Age</div>
          <div><%= Utils.get_block_age_from_timestamp(event.age) %></div>
        </div>
      </div>
    <% end %>
    """
  end

  def render_info(%{transaction_view: "message_logs"} = assigns) do
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
            <div class="block-data">
              <div class="hash flex">
                <a
                  href={Utils.network_path(@network, "messages/#{message.message_hash}")}
                  class="text-hover-link"
                >
                  <%= message.message_hash |> Utils.shorten_block_hash() %>
                  <CoreComponents.copy_button text={message.message_hash} />
                </a>
              </div>
            </div>
          </div>
          <div>
            <div class="list-h">Direction</div>
            <%= if Message.is_l2_to_l1(message.type) do %>
              <div>
                <span class="info-label blue-label">L2</span>→<span class="info-label green-label">L1</span>
              </div>
            <% else %>
              <div>
                <span class="info-label green-label">L1</span>→<span class="info-label blue-label">L2</span>
              </div>
            <% end %>
          </div>
          <div>
            <div class="list-h">Type</div>
            <div class={"type #{String.downcase(String.replace(Message.friendly_message_type(message.type), " ", "-"))}"}>
              <%= Message.friendly_message_type(message.type) %>
            </div>
          </div>
          <div>
            <div class="list-h">From Address</div>
            <div class="block-data">
              <div class="hash flex">
                <%= Utils.shorten_block_hash(message.from_address) %>
                <CoreComponents.copy_button text={message.from_address} />
              </div>
            </div>
          </div>
          <div>
            <div class="list-h">To Address</div>
            <div class="block-data">
              <div class="hash flex">
                <%= Utils.shorten_block_hash(message.to_address) %>
                <CoreComponents.copy_button text={message.to_address} />
              </div>
            </div>
          </div>
          <div>
            <div class="list-h">Transaction Hash</div>
            <div class="block-data">
              <div class="hash flex">
                <a
                  href={Utils.network_path(@network, "transactions/#{message.transaction_hash}")}
                  class="text-hover-link"
                >
                  <%= message.transaction_hash |> Utils.shorten_block_hash() %>
                </a>
                <CoreComponents.copy_button text={message.transaction_hash} />
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def render_info(%{transaction_view: "internal_calls"} = assigns) do
    ~H"""
    <div class="table-block">
      <div class="grid-5 table-th">
        <div>Identifier</div>
        <div>Transaction Hash</div>
        <div>Type</div>
        <div>Name</div>
        <div>Contract Address</div>
      </div>
      <%= for {index, call} <- @internal_calls do %>
        <div class="grid-5 custom-list-item">
          <div>
            <div class="list-h">Identifier</div>
            <div>
              <%= "#{@transaction.hash}_#{call.scope}_#{index}" |> Utils.shorten_block_hash() %>
            </div>
          </div>
          <div>
            <div class="list-h">Transaction Hash</div>
            <div class="hash flex">
              <a
                href={Utils.network_path(@network, "transactions/#{@transaction.hash}")}
                class="text-hover-link"
              >
                <%= @transaction.hash
                |> Utils.shorten_block_hash() %>
              </a>
              <CoreComponents.copy_button text={@transaction.hash} />
            </div>
          </div>
          <div>
            <div class="list-h">Type</div>
            <div>
              <%= if call.call_type=="CALL" do %>
                <span class="green-label"><%= call.call_type %></span>
              <% else %>
                <span class="red-label"><%= call.call_type %></span>
              <% end %>
            </div>
          </div>
          <div>
            <div class="list-h">Name</div>
            <div><span class="blue-label"><%= call.selector_name %></span></div>
          </div>
          <div class="block-data">
            <div class="hash flex">
              <%= call.contract_address
              |> Utils.shorten_block_hash() %>
              <CoreComponents.copy_button text={call.contract_address} />
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # TODO:
  # Do not hardcode the following:
  # Call data
  # Execution resources
  def render_info(%{transaction_view: "overview"} = assigns) do
    ~H"""
    <div class="grid-4 custom-list-item">
      <div class="block-label">Transaction Hash</div>
      <div class="block-data co-span-3">
        <div class="hash flex">
          <%= @transaction.hash %>
          <CoreComponents.copy_button text={@transaction.hash} />
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Transaction Type</div>
      <div class="col-span-3">
        <span class={"type #{String.downcase(String.replace(@transaction.type, " ", "-"))}"}>
          <%= @transaction.type %>
        </span>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Status</div>
      <div class="col-span-3">
        <%= if @transaction_receipt.execution_status == "REVERTED" do %>
          <span class="orange-label">
            REVERTED
          </span>
        <% else %>
          <span class={"info-label #{String.downcase(String.replace(@transaction_receipt.finality_status, " ", "-"))}"}>
            <%= @transaction_receipt.finality_status %>
          </span>
        <% end %>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Block Number</div>
      <div class="col-span-3">
        <span>
          <a
            href={Utils.network_path(@network, "blocks/#{@transaction_receipt.block_hash}")}
            class="type"
          >
            <span><%= @transaction_receipt.block_number %></span>
          </a>
        </span>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Block Hash</div>
      <div class="block-data col-span-3">
        <div class="hash flex">
          <a
            href={Utils.network_path(@network, "blocks/#{@transaction_receipt.block_hash}")}
            class="text-hover-link"
          >
            <%= @transaction_receipt.block_hash %>
          </a>
          <CoreComponents.copy_button text={@transaction_receipt.block_hash} />
        </div>
      </div>
    </div>
    <%= if @transaction.sender_address do %>
      <div class="grid-4 custom-list-item">
        <div class="block-label">Sender Address</div>
        <div class="block-data col-span-3">
          <div class="hash flex">
            <%= @transaction.sender_address |> Utils.shorten_block_hash() %>
            <CoreComponents.copy_button text={@transaction.sender_address} />
          </div>
        </div>
      </div>
    <% end %>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Actual Fee</div>
      <div class="col-span-3">
        <span class="info-label cash-label">
          <%= @transaction_receipt.actual_fee %> ETH
        </span>
      </div>
    </div>
    <%= if @transaction.sender_address do %>
      <div class="grid-4 custom-list-item">
        <div class="block-label">Max Fee</div>
        <div class="col-span-3">
          <span class="info-label gray-label">
            <%= @transaction.max_fee %> ETH
          </span>
        </div>
      </div>
    <% end %>

    <div class="grid-4 custom-list-item">
      <div class="block-label">Nonce</div>
      <div class="col-span-3">
        <%= if @transaction.nonce,
          do: @transaction.nonce |> String.replace("0x", "") |> String.to_integer(16),
          else: 0 %>
      </div>
    </div>
    <div class="custom-list-item">
      <div class="block-label !mt-8 !mb-5">
        Input Data
      </div>
      <%= if @rerender? != nil do %>
        <div class="col-span-full">
          <%= if @input_data != nil do %>
            <%= for input <- @input_data do %>
              <%= unless is_nil(input.call) do %>
                <div class="inner-block custom-list !p-0">
                  <div
                    id={"#{input.call.name}"}
                    class="w-full bg-black/20 p-5 !flex items-start justify-between hover:bg-black/10"
                    phx-hook="ShowTableData"
                  >
                    <div class="flex items-center gap-0.5 flex-wrap">
                      <span>call</span>
                      <span class="text-se-pink ml-1"><%= input.call.name %></span>
                      (<.intersperse :let={arg} enum={input.call.args}>
                        <:separator><span class="mr-2">,</span></:separator>
                        <span class="text-blue-400"><%= arg.name %></span>
                      </.intersperse>) <span class="text-blue-400 mx-1">-></span>
                      <div class="hash">
                        <%= input.selector %>
                        <CoreComponents.copy_button text={input.selector} />
                      </div>
                    </div>
                    <div class="arrow-button transition-all duration-200 shrink-0">
                      <img class="transform -rotate-90" src={~p"/images/chevron.svg"} />
                    </div>
                  </div>
                  <div class="w-full bg-[#1e1e2b]/25 p-5">
                    <%= for arg <- input.call.args do %>
                      <div class="custom-list-item">
                        <div class="pb-5">
                          <div class="list-h">Input</div>
                          <div>
                            <%= arg.name %>
                          </div>
                        </div>
                        <div class="col-span-2 pb-5">
                          <div class="list-h">Type</div>
                          <div class="w-full overflow-x-auto">
                            <%= arg.type %>
                          </div>
                        </div>
                        <div class="col-span-2 pb-5">
                          <div class="list-h">Value</div>
                          <div class="hash flex">
                            <%= Utils.format_arg_value(arg) %>
                            <CoreComponents.copy_button text={Utils.format_arg_value(arg)} />
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% else %>
                <div class="w-full bg-black/20 p-5 mt-5">
                  Not Supported <span class="text-se-pink">...</span>(...)
                  <span class="text-blue-400">-></span> <%= input.selector %>
                </div>
              <% end %>
            <% end %>
          <% else %>
            <div class="w-full bg-black/20 p-5 mt-5">
              Not Supported <span class="text-se-pink">...</span>(...)
            </div>
          <% end %>
        </div>
      <% else %>
        <div class="w-full bg-black/20 p-5 mt-5">
          Loading
        </div>
      <% end %>
    </div>
    <div class="custom-list-item">
      <div class="py-5 text-gray-500 !flex-row gap-5">Signature</div>
      <div class="inner-block my-5">
        <div class="w-full grid-8 table-th">
          <div>Index</div>
          <div class="col-span-7">Value</div>
        </div>
        <%= unless is_nil(@transaction.signature) do %>
          <%= for {signature, index} <- Enum.with_index(@transaction.signature) do %>
            <div class="w-full grid-8 custom-list-item">
              <div>
                <div class="list-h">Index</div>
                <div class="break-all"><%= index %></div>
              </div>
              <div class="col-span-7">
                <div class="list-h">Value</div>
                <div class="block-data">
                  <div class="hash flex">
                    <%= signature |> Utils.shorten_block_hash() %>
                    <CoreComponents.copy_button text={signature} />
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    <%= if @rerender? != nil do %>
      <div class="pt-3 mb-3">
        <div class="mb-5 text-gray-500 md:text-white !flex-row gap-5">
          <span>Execution Resources</span>
        </div>
        <div class="flex flex-col lg:flex-row items-center gap-5 px-5 md:p-0">
          <div class="flex flex-col justify-center items-center gap-2">
            <span class="blue-label py-1 px-2 rounded-lg">STEPS</span> <%= "#{@transaction_receipt.execution_resources["n_steps"]}" %>
          </div>
          <div class="flex flex-col justify-center items-center gap-2">
            <span class="green-label py-1 px-2 rounded-lg">MEMORY HOLES</span> <%= "#{@transaction_receipt.execution_resources["n_memory_holes"]}" %>
          </div>
          <%= for {builtin_name , instance_counter} <- @transaction_receipt.execution_resources["builtin_instance_counter"] do %>
            <div class="flex flex-col justify-center items-center gap-2">
              <span class={Utils.builtin_color(builtin_name)}>
                <%= Utils.builtin_name(builtin_name) %>
              </span>
              <%= instance_counter %>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  def render_info(assigns) do
    ~H"""

    """
  end

  @impl true
  def mount(%{"transaction_hash" => transaction_hash} = _params, _session, socket) do
    if connected?(socket) do
      mount_connected(socket, transaction_hash)
    else
      {:ok,
       assign(socket, render_header: false, render_info: false, transaction_view: "overview")}
    end
  end

  def mount_connected(socket, transaction_hash) do
    {:ok, transaction = %{receipt: receipt}} =
      Data.transaction(transaction_hash, socket.assigns.network)

    {:ok, %{:timestamp => block_timestamp}} =
      Data.block_by_hash(receipt.block_hash, socket.assigns.network)

    # change fee formatting
    actual_fee = Utils.hex_wei_to_eth(transaction.receipt.actual_fee)

    transaction =
      case transaction.type do
        "L1_HANDLER" ->
          transaction

        _ ->
          max_fee = Utils.hex_wei_to_eth(transaction.max_fee)
          transaction |> Map.put(:max_fee, max_fee)
      end

    execution_resources = %{
      "builtin_instance_counter" => %{},
      "n_memory_holes" => "-",
      "n_steps" => "-"
    }

    receipt =
      transaction.receipt
      |> Map.put(:execution_resources, execution_resources)
      |> Map.put(:actual_fee, actual_fee)

    assigns = [
      transaction: transaction,
      transaction_receipt: receipt,
      transaction_hash: transaction_hash,
      internal_calls: %{},
      transaction_view: "overview",
      block_timestamp: block_timestamp,
      render_header: true,
      render_info: true,
      events: [],
      messages: [],
      rerender?: nil
    ]

    Process.send_after(self(), :load_additional_info, 100)
    socket = assign(socket, assigns)
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("select-view", %{"view" => "internal_calls"}, socket) do
    internal_calls =
      case socket.assigns.transaction_receipt.execution_status != "REVERTED" &&
             Application.get_env(:starknet_explorer, :enable_gateway_data) do
        true -> Data.internal_calls(socket.assigns.transaction, socket.assigns.network)
        _ -> nil
      end

    assigns = [
      internal_calls: internal_calls,
      internal_calls_count: length(Map.keys(internal_calls)),
      rerender?: true,
      transaction_view: "internal_calls"
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("select-view", %{"view" => view}, socket) do
    socket = assign(socket, :transaction_view, view)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:load_internal_calls, socket) do
    internal_calls =
      case socket.assigns.transaction_receipt.execution_status != "REVERTED" &&
             Application.get_env(:starknet_explorer, :enable_gateway_data) do
        true -> Data.internal_calls(socket.assigns.transaction, socket.assigns.network)
        _ -> nil
      end

    assigns = [
      internal_calls: internal_calls,
      internal_calls_count: length(Map.keys(internal_calls)),
      rerender?: true
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_info(:load_additional_info, socket) do
    events = Events.get_by_tx_hash(socket.assigns.transaction_hash, socket.assigns.network)

    messages_sent =
      (Message.from_transaction_receipt(socket.assigns.transaction_receipt) ++
         [Message.from_transaction(socket.assigns.transaction)])
      |> Enum.reject(&is_nil/1)

    execution_resources =
      case Application.get_env(:starknet_explorer, :enable_gateway_data) do
        true ->
          case Gateway.get_transaction_receipt(
                 socket.assigns.transaction_hash,
                 socket.assigns.network
               ) do
            {:ok, %{"execution_resources" => execution_resources} = _receipt} ->
              execution_resources

            {:ok, _} ->
              # This means that the transactions is reverted
              %{
                "builtin_instance_counter" => %{},
                "n_memory_holes" => "-",
                "n_steps" => "-"
              }
          end

        false ->
          %{
            "builtin_instance_counter" => %{},
            "n_memory_holes" => "-",
            "n_steps" => "-"
          }
      end

    receipt =
      socket.assigns.transaction_receipt
      |> Map.put(:execution_resources, execution_resources)

    input_data =
      try do
        StarknetExplorer.Calldata.parse_calldata(
          socket.assigns.transaction,
          %{"block_number" => receipt.block_number},
          socket.assigns.network
        )
      rescue
        _ -> nil
      end

    assigns =
      [
        events: events,
        events_count: length(events),
        messages: messages_sent,
        messages_count: length(messages_sent),
        transaction_receipt: receipt,
        rerender?: true,
        input_data: input_data
      ]

    {:noreply, assign(socket, assigns)}
  end
end
