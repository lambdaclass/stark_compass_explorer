defmodule StarknetExplorerWeb.BlockDetailLive do
  require Logger
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.CoreComponents
  alias StarknetExplorer.Data
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.S3
  alias StarknetExplorer.Message
  alias StarknetExplorer.Transaction
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

  defp block_transactions_receipt(socket) do
    if Map.get(socket.assigns, :receipts) == nil do
      {:ok, receipts} = Data.receipts_by_block(socket.assigns.block, socket.assigns.network)

      receipts
      |> Map.new(fn receipt ->
        {receipt.transaction_hash, receipt}
      end)
    else
      socket.assigns.receipts
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
      <h2>Block</h2>
      <div class="text-gray-400">
        <%= if @view != "loading" do %>
          <%= @block.timestamp
          |> DateTime.from_unix()
          |> then(fn {:ok, time} -> time end)
          |> Calendar.strftime("%c") %> UTC
        <% else %>
          Loading
        <% end %>
      </div>
    </div>
    <div
      id="dropdown"
      class="dropdown relative bg-[#232331] p-5 mb-2 rounded-md lg:hidden"
      phx-hook="Dropdown"
    >
      <span class="networkSelected capitalize"><%= assigns.view %></span>
      <span class="absolute inset-y-0 right-5 transform translate-1/2 flex items-center">
        <img
          alt="Dropdown menu of block detail screens"
          class="transform rotate-90 w-5 h-5"
          src={~p"/images/dropdown.svg"}
        />
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
      <%= if @tabs? do %>
        <div
          class={"option #{if assigns.view == "transactions", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
          phx-click="select-view"
          ,
          phx-value-view="transactions"
        >
          Transactions (<%= @transactions_count %>)
        </div>
        <div
          class={"option #{if assigns.view == "messages", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
          phx-click="select-view"
          ,
          phx-value-view="messages"
        >
          Message Logs (<%= @messages_count %>)
        </div>
        <div
          class={"option #{if assigns.view == "events", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
          phx-click="select-view"
          ,
          phx-value-view="events"
          ,
        >
          Events (<%= @events_count %>)
        </div>
      <% end %>
      <%= if !@tabs? do %>
        <span>
          <div class="option not-active lg:border-b-transparent text-gray-400" }>
            Loading tabs...
          </div>
        </span>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params = %{"number_or_hash" => param}, _session, socket) do
    {type, param} =
      case num_or_hash(param) do
        :hash ->
          {:hash, param}

        :num ->
          {num, ""} = Integer.parse(param)
          {:num, num}
      end

    {:ok, block} =
      case :timer.tc(fn ->
             Enum.find(
               StarknetExplorer.IndexCache.latest_blocks(socket.assigns.network),
               fn block ->
                 block.number == param or block.hash == param
               end
             )
           end) do
        {time, block} = {_, %StarknetExplorer.Block{}} ->
          Logger.debug(
            "[Block Detail] Found block #{block.number} in cache in #{time} microseconds"
          )

          {:ok, block}

        {time, _} ->
          case type do
            :hash ->
              {query_time, res} =
                :timer.tc(fn -> Data.block_by_hash(param, socket.assigns.network, false) end)

              Logger.debug(
                "[Block Detail] Fetched block #{param} in #{query_time} microseconds, query took #{time} microseconds, using :hash"
              )

              res

            :num ->
              {query_time, res} =
                :timer.tc(fn -> Data.block_by_number(param, socket.assigns.network, false) end)

              Logger.debug(
                "[Block Detail] Fetched block #{param} in #{query_time} microseconds, query took #{time} microsecond, using :num"
              )

              res
          end
      end

    socket = assign(socket, :block, block)

    extra_assings =
      if connected?(socket) do
        transactions = block_transactions(socket)

        # note: most transactions receipt do not contain messages
        l1_to_l2_messages =
          transactions |> Enum.map(&Message.from_transaction/1) |> Enum.reject(&is_nil/1)

        messages =
          (transactions
           |> Enum.map(fn tx -> tx.receipt end)
           |> Enum.flat_map(&Message.from_transaction_receipt/1)) ++ l1_to_l2_messages

        [
          transactions_count: length(transactions),
          messages_count: length(messages),
          events_count: Events.get_count_by_block(block.number, socket.assigns.network),
          transactions: transactions,
          messages: messages
        ]
      else
        []
      end

    assigns =
      [
        gas_price: Utils.hex_wei_to_eth(block.gas_fee_in_wei),
        execution_resources: block.execution_resources,
        block: block,
        view: "overview",
        verification: "Pending",
        block_age: Utils.get_block_age(block),
        tabs?: connected?(socket),
        active_pagination_id: ""
      ] ++ extra_assings

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event(
        "change-page",
        %{"page-number-input" => page_number},
        socket
      ) do
    assigns =
      case socket.assigns.view do
        "transactions" ->
          filter = Map.get(socket.assigns, :tx_filter, "ALL")

          page =
            Transaction.paginate_txs_by_block_number(
              %{page: page_number},
              socket.assigns.block.number,
              socket.assigns.network,
              filter
            )

          [
            page: page
          ]

        "events" ->
          page =
            Events.paginate_events(
              %{page: page_number},
              socket.assigns.block.number,
              socket.assigns.network
            )

          [
            page: page
          ]

        _ ->
          []
      end

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event(
        "select-filter",
        %{"filter" => filter},
        socket
      ) do
    page =
      Transaction.paginate_txs_by_block_number(
        %{page: 0},
        socket.assigns.block.number,
        socket.assigns.network,
        filter
      )

    assigns = [
      view: "transactions",
      page: page,
      receipts: block_transactions_receipt(socket),
      tx_filter: filter
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event(
        "change-page",
        %{"page-number-input" => page_number},
        socket
      ) do
    assigns =
      case socket.assigns.view do
        "transactions" ->
          filter = Map.get(socket.assigns, :tx_filter, "ALL")

          page =
            Transaction.paginate_txs_by_block_number(
              %{page: page_number},
              socket.assigns.block.number,
              socket.assigns.network,
              filter
            )

          [
            page: page
          ]

        "events" ->
          page =
            Events.paginate_events(
              %{page: page_number},
              socket.assigns.block.number,
              socket.assigns.network
            )

          [
            page: page
          ]

        _ ->
          []
      end

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event(
        "select-filter",
        %{"filter" => filter},
        socket
      ) do
    page =
      Transaction.paginate_txs_by_block_number(
        %{page: 0},
        socket.assigns.block.number,
        socket.assigns.network,
        filter
      )

    assigns = [
      view: "transactions",
      page: page,
      receipts: block_transactions_receipt(socket),
      tx_filter: filter
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event(
        "select-view",
        %{"view" => "messages"},
        socket
      ) do
    assigns = [
      view: "messages"
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event(
        "select-view",
        %{"view" => "transactions"},
        socket
      ) do
    filter = Map.get(socket.assigns, :tx_filter, "ALL")

    page =
      Transaction.paginate_txs_by_block_number(
        %{page: 0},
        socket.assigns.block.number,
        socket.assigns.network,
        filter
      )

    assigns = [
      view: "transactions",
      page: page,
      receipts: block_transactions_receipt(socket),
      tx_filter: "ALL"
    ]

    {:noreply, assign(socket, assigns)}
  end

  def handle_event("dec_txs", _value, socket) do
    new_page_number = socket.assigns.page.page_number - 1

    page =
      Transaction.paginate_txs_by_block_number(
        %{page: new_page_number},
        socket.assigns.block.number,
        socket.assigns.network
      )

    assigns = [
      page: page,
      view: "transactions",
      receipts: block_transactions_receipt(socket)
    ]

    {:noreply, assign(socket, assigns)}
  end

  def handle_event("inc_txs", _value, socket) do
    new_page_number = socket.assigns.page.page_number + 1

    page =
      Transaction.paginate_txs_by_block_number(
        %{page: new_page_number},
        socket.assigns.block.number,
        socket.assigns.network
      )

    assigns = [
      page: page,
      view: "transactions",
      receipts: block_transactions_receipt(socket)
    ]

    {:noreply, assign(socket, assigns)}
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
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <%= block_detail_header(assigns) %>
      <%= if @view == "transactions", do: render_tx_filter(assigns) %>
      <%= render_info(assigns) %>
    </div>
    """
  end

  def render_tx_filter(assigns) do
    ~H"""
    <div>
      <div>
        <div
          id="dropdown"
          class="dropdown relative bg-[#232331] p-5 mb-2 rounded-md lg:hidden"
          phx-hook="Dropdown"
        >
          <span class="networkSelected capitalize"><%= assigns.tx_filter %></span>
          <span class="absolute inset-y-0 right-5 transform translate-1/2 flex items-center">
            <img
              alt="Dropdown menu of transaction types"
              class="transform rotate-90 w-5 h-5"
              src={~p"/images/dropdown.svg"}
            />
          </span>
        </div>
        <div>
          <div class="options hidden">
            <div
              class={"option #{if Map.get(assigns, :tx_filter) == "ALL", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
              phx-click="select-filter"
              ,
              phx-value-filter="ALL"
            >
              All
            </div>
            <%= if @tabs? do %>
              <div
                class={"option #{if Map.get(assigns, :tx_filter) == "INVOKE", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
                phx-click="select-filter"
                ,
                phx-value-filter="INVOKE"
              >
                Invoke
              </div>
              <div
                class={"option #{if Map.get(assigns, :tx_filter) == "DEPLOY_ACCOUNT", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
                phx-click="select-filter"
                ,
                phx-value-filter="DEPLOY_ACCOUNT"
              >
                Deploy Account
              </div>
              <div
                class={"option #{if Map.get(assigns, :tx_filter) == "DEPLOY", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
                phx-click="select-filter"
                ,
                phx-value-filter="DEPLOY"
              >
                Deploy
              </div>
              <div
                class={"option #{if Map.get(assigns, :tx_filter) == "DECLARE", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
                phx-click="select-filter"
                ,
                phx-value-filter="DECLARE"
                ,
              >
                Declare
              </div>
            <% end %>
            <div
              class={"option #{if Map.get(assigns, :tx_filter) == "L1_HANDLER", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
              phx-click="select-filter"
              ,
              phx-value-filter="L1_HANDLER"
              ,
            >
              L1 Handler
            </div>
          </div>
        </div>
      </div>
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
    <%= for %{hash: hash, type: type, version: version, sender_address: sender_address} <- @page.entries do %>
      <div class="grid-6 custom-list-item">
        <div>
          <div class="list-h">Hash</div>
          <div class="block-data">
            <div class="hash flex">
              <a href={Utils.network_path(@network, "transactions/#{hash}")} class="text-hover-link">
                <span><%= Utils.shorten_block_hash(hash) %></span>
              </a>
              <CoreComponents.copy_button text={hash} />
            </div>
          </div>
        </div>
        <div>
          <div class="list-h">Type</div>
          <div>
            <span class={"type #{String.downcase(type)}"}>
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
          <% finality_status = @receipts[hash].finality_status %>
          <span class={"info-label #{String.downcase(finality_status)}"}>
            <%= finality_status %>
          </span>
        </div>
        <div>
          <div class="list-h">Address</div>
          <div class="flex gap-2 items-center copy-container" id={"copy-addr-#{hash}"} phx-hook="Copy">
            <div class="relative">
              <div class="break-all text-hover-blue">
                <%= Utils.shorten_block_hash(sender_address || "-") %>
              </div>
              <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                <div class="relative">
                  <img
                    alt="Copy button logo"
                    class="copy-btn copy-text w-4 h-4"
                    src={~p"/images/copy.svg"}
                    data-text={sender_address || "-"}
                  />
                  <img
                    alt="Copied checkmark logo"
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
          <div><%= Utils.get_block_age_from_timestamp(@block.timestamp) %></div>
        </div>
      </div>
    <% end %>
    <div class="mt-2">
      <CoreComponents.pagination_links
        id="txs"
        page={@page}
        prev="dec_txs"
        next="inc_txs"
        active_pagination_id={@active_pagination_id}
      />
    </div>
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
      <%= for {message, index} <- Enum.with_index(@messages) do %>
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
                </a>
                <CoreComponents.copy_button text={message.message_hash} />
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
            <% message_type = Message.friendly_message_type(message.type) %>
            <div class={"type #{String.downcase(String.replace(message_type, " ", "-"))}"}>
              <%= message_type %>
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
            <div
              class="flex gap-2 items-center copy-container"
              id={"copy-tx-hash-#{index}"}
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
                      alt="Copy button logo"
                      class="copy-btn copy-text w-4 h-4"
                      src={~p"/images/copy.svg"}
                      data-text={message.transaction_hash}
                    />
                    <img
                      alt="Copied checkmark logo"
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

  def render_info(assigns = %{block: _block, view: "overview"}) do
    ~H"""
    <div class="grid-4 custom-list-item">
      <div class="block-label">Block Number</div>
      <div class="type">
        <a href={Utils.network_path(@network, "blocks/#{@block.hash}")} class="text-hover-link">
          <%= @block.number %>
        </a>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Block Hash</div>
      <div class="block-data col-span-3">
        <div class="hash flex">
          <a href={Utils.network_path(@network, "blocks/#{@block.hash}")} class="text-hover-link">
            <%= @block.hash %>
          </a>
          <CoreComponents.copy_button text={@block.hash} />
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Block Status</div>
      <div class="col-span-3">
        <span class={"info-label #{String.downcase(@block.status)}"}>
          <%= @block.status %>
        </span>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">State Root</div>
      <div class="block-data col-span-3">
        <div class="hash flex">
          <%= @block.new_root %>
          <CoreComponents.copy_button text={@block.new_root} />
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Parent Hash</div>
      <div class="block-data col-span-3">
        <div class="hash flex">
          <a
            href={Utils.network_path(@network, "blocks/#{@block.parent_hash}")}
            class="text-hover-link"
          >
            <%= @block.parent_hash %>
          </a>
          <CoreComponents.copy_button text={@block.parent_hash} />
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">
        Sequencer Address
      </div>
      <div class="block-data col-span-3">
        <div class="hash flex">
          <%= @block.sequencer_address %>
          <CoreComponents.copy_button text={@block.sequencer_address} />
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
    <div class="table-th !pt-7 grid-5">
      <div>Identifier</div>
      <div>Transaction Hash</div>
      <div>Name</div>
      <div>From Address</div>
      <div>Age</div>
    </div>
    <%= for event <- @page.entries do %>
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
          <div class="list-h">Transaction Hash</div>
          <div class="block-data">
            <div class="hash flex">
              <a
                href={Utils.network_path(@network, "transactions/#{event.transaction_hash}")}
                class="text-hover-link"
              >
                <%= event.transaction_hash |> Utils.shorten_block_hash() %>
              </a>
              <CoreComponents.copy_button text={event.transaction_hash} />
            </div>
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
          <div><%= @block_age %></div>
        </div>
      </div>
    <% end %>
    <CoreComponents.pagination_links
      id="events"
      page={@page}
      prev="dec_events"
      next="inc_events"
      active_pagination_id={@active_pagination_id}
    />
    """
  end

  defp block_transactions(socket) do
    if Map.get(socket.assigns, :transactions) == nil do
      {:ok, receipts} = Data.receipts_by_block(socket.assigns.block, socket.assigns.network)

      Data.transactions_by_block_number(socket.assigns.block.number, socket.assigns.network)
      |> Enum.map(fn tx ->
        %{tx | receipt: Enum.find(receipts, nil, fn r -> r.transaction_hash == tx.hash end)}
      end)
    else
      socket.assigns.transactions
    end
  end
end
