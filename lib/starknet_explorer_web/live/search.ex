defmodule StarknetExplorerWeb.SearchLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Data
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Message

  def render(assigns) do
    ~H"""
    <div id="searchbar-wrapper" phx-hook="SearchBar">
      <form id="placeholder-form" class="normal-form pl-32" phx-click="open-search">
        <input
          type="text"
          name="search-input"
          placeholder="Search"
          class="px-5 text-normal"
          readonly
        />
        <img src={~p"/images/search.svg"} class="absolute top-1/2 right-4 transform -translate-y-1/2"/>
      </form>
      <div id="search-overlay" class={"fixed inset-0 z-50 overflow-y-hidden #{if @opened, do: '', else: 'hidden'}"}>
        <div class="fixed inset-0 transition-opacity bg-zinc-400/25 backdrop-blur-sm 
          dark:bg-black/60 opacity-100 z-20 overflow-hidden" phx-click="close-search">
        </div>
        <div id="nav-search-bar" class="max-w-3xl lg:w-full w-3/4 mx-auto relative z-40 top-20">
          <div class="xl:w-full">
            <form class="normal-form" phx-change="update-input" phx-submit="search">
              <div class={"relative z-20"}>
                <div class="absolute top-1/2 left-4 transform -translate-y-1/2 flex items-enter">
                  <%= if @loading do %>
                    <img class="w-5 h-auto" src={~p"/images/loading-blocks.svg"} />
                  <% else %>
                    <button type="submit">
                      <img class="w-5 h-auto" src={~p"/images/search.svg"} />
                    </button>
                  <% end %>
                </div>
                <.input
                  type="text"
                  name="search-input"
                  value={@query}
                  id="searchHook"
                  class={"py-3 pl-12 pr-5 #{if @show_result_box && !@loading, do: '!rounded-b-none', else: ''}"}
                  placeholder="Search Blocks (coming soon: Transactions, Classes, Messages, Contracts and Events)"
                  phx-debounce="500"
                />
                <div class="py-1 px-2 bg-gray-800 rounded-md text-sm text-gray-300 absolute top-1/2 right-4 -translate-y-1/2">
                  ESC
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, session, socket) do
    new_assigns = [query: "", loading: false, matches: [], errors: [], opened: false, show_result_box: false]

    socket =
      socket
      |> assign(new_assigns)
      |> assign_new(:network, fn -> session["network"] end)

    {:ok, socket, layout: false}
  end

  def handle_event("open-search", _, socket) do
    socket = assign(socket, opened: true)
    {:noreply, push_event(socket, "focus", %{id: "searchHook"})}
  end

  def handle_event("close-search", _, socket) do
    socket = assign(socket, opened: false, query: "", loading: false, show_result_box: false)
    {:noreply, socket}
  end

  def handle_event("update-input", %{"search-input" => query}, socket) do
    send(self(), {:search, query})
    {:noreply, assign(socket, query: query, result: "Searching...", loading: true, show_result_box: true, matches: [])}
  end

  def handle_event("search", %{"search-input" => query}, socket) when byte_size(query) <= 100 do
    send(self(), {:search, query})
    {:noreply, assign(socket, query: query, result: "Searching...", loading: true, show_result_box: true, matches: [])}
  end

  def handle_info({:search, query}, socket) do
    query = String.trim(query)

    navigate_fun =
      if String.length(query) > 0 do
        case try_search(query, socket.assigns.network) do
          {:tx, _tx} ->
            fn -> assign(socket, tx: query, result: "Found", loading: false) end

          {:block, block} ->
            fn -> assign(socket, block: block, result: "Found", loading: false) end

          {:message, _message} ->
            fn -> assign(socket, message: query, result: "Found", loading: false) end

          :noquery ->
            fn ->
              assign(socket, result: "No results found", loading: false)
            end
        end
      else
        fn -> 
          assign(socket, result: "", loading: false, show_result_box: false)
        end
      end

    {:noreply, navigate_fun.()}
  end

  defp try_search(query, network) do
    case infer_query(query) do
      :hex -> try_by_hash(query, network)
      {:number, number} -> try_by_number(number, network)
      :noquery -> :noquery
    end
  end

  def try_by_number(number, network) do
    case Data.block_by_partial_number(number, network) do
      {:ok, blocks = [_ | _]} -> {:block, List.first(blocks)}
      _ -> :noquery
    end
  end

  def try_by_hash(hash, network) do
    case Data.transaction_by_partial_hash(hash) do
      {:ok, transaction} ->
        {:tx, transaction}

      {:error, _} ->
        case Data.block_by_partial_hash(hash, network) do
          {:ok, blocks = [_ | _]} ->
            {:block, List.first(blocks)}

          _ ->
            case Message.get_by_partial_hash(hash, network) do
              {:ok, _message} -> {:message, hash}
              _ -> :noquery
            end
        end
    end
  end

  defp infer_query(_query = <<"0x", _rest::binary>>), do: :hex

  defp infer_query(query) do
    case Integer.parse(query) do
      {parsed, ""} -> {:number, parsed}
      _ -> :noquery
    end
  end

  defp get_number(%StarknetExplorer.Block{number: number}), do: "#{number}"
  defp get_number(_), do: ""

  defp get_hash(%StarknetExplorer.Block{hash: hash}), do: "#{hash}"
  defp get_hash(%StarknetExplorer.Transaction{hash: hash}), do: "#{hash}"
  defp get_hash(%StarknetExplorer.Message{message_hash: hash}), do: "#{hash}"
  defp get_hash(_), do: ""
end
