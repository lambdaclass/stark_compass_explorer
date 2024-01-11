defmodule StarknetExplorerWeb.TransactionLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.CoreComponents
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.{Data, Message, Events, TransactionReceipt, Rpc}

  @common_selectors_to_name %{
    "0x15d40a3d6ca2ac30f4031e42be28da9b056fef9bb7357ac5e85627ee876e5ad" => "__execute__",
    "0x83afd3f4caedc6eebf44246fe54e38c95e3179a5ec9ea81740eca5b482d12e" => "transfer",
    "0x2f0b3c5710379609eb5495f1ecd348cb28167711b73609fe565a72734550354" => "mint",
    "0x32a99297e1d12a9b91d4f90d5dd4b160d93c84a9e3b4daa916fec14ec852e05" => "transaction",
    "0x219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c" => "approve",
    "0x1171593aa5bdadda4d6b0efde6cc94ee7649c3163d5efeb19da6c16d63a2a63" => "multi_route_swap",
    "0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e" => "balanceOf",
    "0x41b033f4a31df8067c24d1e9b550a2ce75fd4a29e1147af9752174f0e6cb20" => "transferFrom",
    "0x260bb04cf90403013190e77d7e75f3d40d3d307180364da33c63ff53061d4e8" => "feeInfo",
    "0x15543c3708653cda9d418b4ccd3be11368e40636c10c44b18cfe756b6d88b29" => "swap",
    "0x168652c307c1e813ca11cfb3a601f1cf3b22452021a5052d8b05f1f1f8a3e92" => "lock",
    "0x399c6d7581cbb37d2e578d3097bfdd3323e05447f1fd7670b6c3a3fb9d9ff79" => "locked",
    "0x25ef2564dc27d90f0cd3ffbe419481249901a2c185139533c6cded38ae979b3" => "swap_after_lock",
    "0x63ecb4395e589622a41a66715a0eac930abc9f0b92c0b1dcda630adfb2bf2d" => "get_pool_price",
    "0xc73f681176fc7b3f9693986fd7b14581e8d540519e27400e88b8713932be01" => "deposit",
    "0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77" => "withdraw",
    "0x19ea78dfeefee473cead0f17e6cea7018f57abbf524110c3d3a369b248c7ce0" => "publicMint",
    "0x28ffe4ff0f226a9107253e17a904099aa4f63a02a5621de0576e5aa71bc5194" => "constructor",
    "0x2d757788a8d8d6f21d1cd40bce38a8222d70654214e96ff95d8086e684fbee5" => "handle_deposit",
    "0x151e58b29179122a728eab07c8847e5baf5802379c5db3a7d57a8263a7bd1d" => "permissionedMint"
  }

  @common_selectors Map.keys(@common_selectors_to_name)

  defp display_internal_calls?(internal_calls, transaction_receipt, socket) do
    not is_nil(internal_calls) and transaction_receipt.execution_status != "REVERTED" and
      connected?(socket) and transaction_receipt.type != "DECLARE" and
      not is_nil(transaction_receipt.execution_resources)
  end

  defp tab_name("overview"), do: "Overview"
  defp tab_name("events"), do: "Events"
  defp tab_name("message_logs"), do: "Message Logs"
  defp tab_name("internal_calls"), do: "Internal Calls"
  defp tab_name(name), do: name

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
      <span class="networkSelected capitalize"><%= tab_name(assigns.transaction_view) %></span>
      <span class="absolute inset-y-0 right-5 transform translate-1/2 flex items-center">
        <img alt="Dropdown menu" class="transform rotate-90 w-5 h-5" src={~p"/images/dropdown.svg"} />
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
      <%= if display_internal_calls?(@internal_calls, @transaction_receipt, @socket) do %>
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
            <a
              href={Utils.network_path(@network, "contracts/#{event.from_address}")}
              class="text-hover-link"
            >
              <%= event.from_address |> Utils.shorten_block_hash() %>
            </a>
            <CoreComponents.copy_button text={event.from_address} />
          </div>
        </div>
        <div>
          <div class="list-h">Age</div>
          <div class="flex items-center gap-2">
            <%= Utils.get_block_age_from_timestamp(event.age) %>
            <CoreComponents.tooltip
              id="event-timestamp-tooltip"
              text={"#{event.age
                        |> DateTime.from_unix()
                        |> then(fn {:ok, time} -> time end)
                        |> Calendar.strftime("%c")} UTC"}
              class="translate-y-px"
            />
          </div>
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
                <a
                  href={Utils.network_path(@network, "contracts/#{message.from_address}")}
                  class="text-hover-link"
                >
                  <%= Utils.shorten_block_hash(message.from_address) %>
                </a>
                <CoreComponents.copy_button text={message.from_address} />
              </div>
            </div>
          </div>
          <div>
            <div class="list-h">To Address</div>
            <div class="block-data">
              <div class="hash flex">
                <a
                  href={Utils.network_path(@network, "contracts/#{message.to_address}")}
                  class="text-hover-link"
                >
                  <%= Utils.shorten_block_hash(message.to_address) %>
                </a>
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
      <div class="grid-3 table-th">
        <div>Type</div>
        <div>Name</div>
        <div>Contract Address</div>
      </div>
      <%= render_internal_call(@trace, assigns) %>
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
          <%= Utils.hex_wei_to_eth(@transaction_receipt.actual_fee["amount"]) %> ETH
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
                      <img alt="Chevron" class="transform -rotate-90" src={~p"/images/chevron.svg"} />
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
                  <span class="text-blue-400">-></span>
                  <div class="hash">
                    <%= input.selector %>
                    <CoreComponents.copy_button text={input.selector} />
                  </div>
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
    <%= if is_nil(@transaction_receipt.execution_resources) do %>
      <div class="pt-3 mb-3">
        <div class="mb-5 text-gray-500 md:text-white !flex-row gap-5">
          <span>Execution Resources</span>
        </div>
        <div class="flex flex-col lg:flex-row items-center gap-5 px-5 md:p-0">
          The node doesn't support execution resources.
        </div>
      </div>
    <% else %>
      <div class="pt-3 mb-3">
        <div class="mb-5 text-gray-500 md:text-white !flex-row gap-5">
          <span>Execution Resources</span>
        </div>
        <div class="flex flex-col lg:flex-row items-center gap-5 px-5 md:p-0">
          <div class="flex flex-col justify-center items-center gap-2">
            <span class="blue-label py-1 px-2 rounded-lg">STEPS</span> <%= "#{Utils.hex_to_integer(@transaction_receipt.execution_resources["steps"])}" %>
          </div>
          <div class="flex flex-col justify-center items-center gap-2">
            <span class="green-label py-1 px-2 rounded-lg">MEMORY HOLES</span> <%= "#{Utils.hex_to_integer(@transaction_receipt.execution_resources["memory_holes"])}" %>
          </div>
          <%= for {builtin_name, resources} <- @transaction_receipt.execution_resources do %>
            <%= if String.ends_with?(builtin_name, "_applications") and resources != "0x0" do %>
              <% temp_name = String.trim_trailing(builtin_name, "_applications") %>
              <div class="flex flex-col justify-center items-center gap-2">
                <span class={"#{Utils.builtin_color(temp_name)} py-1 px-2 rounded-lg"}>
                  <%= Utils.builtin_name(temp_name) %>
                </span>
                <%= Utils.hex_to_integer(resources) %>
              </div>
            <% end %>
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

  def prettify_call_name(name) when name in @common_selectors, do: @common_selectors_to_name[name]
  def prettify_call_name(hash = <<"0x", _rest::binary>>), do: Utils.shorten_block_hash(hash)
  def prettify_call_name(name), do: name

  def render_internal_call(nil, _assigns), do: ""
  def render_internal_call([], _assigns), do: ""

  def render_internal_call(call, assigns) do
    assigns = assign(assigns, :call, call)

    ~H"""
    <div class="grid-3 custom-list-item">
      <div>
        <div class="list-h">Type</div>
        <div>
          <%= if @call["call_type"] =="CALL" do %>
            <span class="green-label"><%= @call["call_type"] %></span>
          <% else %>
            <span class="red-label"><%= @call["call_type"] %></span>
          <% end %>
        </div>
      </div>
      <div class="block-data">
        <div class="list-h">Name</div>
        <div class="hash flex">
          <span class="blue-label">
            <%= prettify_call_name(@call["entry_point_selector"]) %>
          </span>
          <CoreComponents.copy_button text={@call["entry_point_selector"]} />
        </div>
      </div>
      <div class="block-data">
        <div class="hash flex">
          <%= @call["contract_address"]
          |> Utils.shorten_block_hash() %>
          <CoreComponents.copy_button text={@call["contract_address"]} />
        </div>
      </div>
    </div>
    <%= for internal_call <- @call["calls"] do %>
      <%= render_internal_call(internal_call, assigns) %>
    <% end %>
    """
  end

  @impl true
  def mount(%{"transaction_hash" => transaction_hash} = _params, _session, socket) do
    {:ok, transaction = %{receipt: receipt}} =
      Data.transaction(transaction_hash, socket.assigns.network)

    receipt =
      if not is_nil(receipt.execution_resources) and
           Map.has_key?(receipt.execution_resources, "steps") do
        receipt
      else
        {:ok, new_receipt} = Rpc.get_transaction_receipt(transaction_hash, socket.assigns.network)

        {:ok, new_receipt} =
          TransactionReceipt.update_execution_resources(
            receipt,
            new_receipt["execution_resources"]
          )

        new_receipt
      end

    {:ok, %{:timestamp => block_timestamp}} =
      Data.block_by_hash(receipt.block_hash, socket.assigns.network)

    transaction =
      case transaction.type do
        "L1_HANDLER" ->
          transaction

        _ ->
          max_fee = Utils.hex_wei_to_eth(transaction.max_fee)
          transaction |> Map.put(:max_fee, max_fee)
      end

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
    {:ok, trace} =
      Rpc.get_transaction_trace(socket.assigns.transaction.hash, socket.assigns.network)

    trace =
      case Map.get(trace, "type") do
        "INVOKE" ->
          trace["execute_invocation"]

        "DEPLOY_ACCOUNT" ->
          trace["constructor_invocation"]

        "L1_HANDLER" ->
          trace["function_invocation"]
      end

    assigns = [
      trace: trace,
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
  def handle_info(:load_additional_info, socket) do
    events =
      Events.get_by_tx_hash(socket.assigns.transaction_hash, socket.assigns.network)

    messages_sent =
      (Message.from_transaction_receipt(socket.assigns.transaction_receipt) ++
         [Message.from_transaction(socket.assigns.transaction)])
      |> Enum.reject(&is_nil/1)

    input_data =
      try do
        StarknetExplorer.Calldata.parse_calldata(
          socket.assigns.transaction,
          %{"block_number" => socket.assigns.transaction_receipt.block_number},
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
        transaction_receipt: socket.assigns.transaction_receipt,
        rerender?: true,
        input_data: input_data
      ]

    {:noreply, assign(socket, assigns)}
  end
end
