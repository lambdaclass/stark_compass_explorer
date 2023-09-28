defmodule StarknetExplorerWeb.SearchLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Data
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Message

  def render(assigns) do
    ~H"""
    <div class="xl:w-full">
      <form class="normal-form" phx-change="update-input" phx-submit="search">
        <.input
          phx-change="update-input"
          type="text"
          name="search-input"
          value={@query}
          phx-hook="SearchHook"
          id="searchHook"
          class="search-hook"
          placeholder="Search Blocks, Transactions, Classes, Messages, Contracts or Events"
        />
        <button class="absolute top-1/2 right-2 transform -translate-y-1/2" type="submit">
          <img src={~p"/images/search.svg"} />
        </button>
        <div
          id="dropdownInformation"
          class="hidden absolute mt-3 z-10 bg-container rounded-lg shadow w-full  mx-auto dark:bg-container dark:divide-gray-600"
        >
          <div class="px-4 py-3 text-sm text-gray-900 dark:text-white">
            <%= if assigns[:block] do %>
              Blocks
            <% else %>
              <%= assigns[:result] %>
            <% end %>
            <div>
              <ul
                class="py-2 text-sm text-gray-700 dark:text-gray-200"
                aria-labelledby="dropdownInformationButton"
              >
                <li>
                  <div class="cursor-pointer flex flex-row justify-start items-start block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white">
                    <div class="text-hover-blue">
                      <img class="inline-block" src={~p"/images/box.svg"} />
                      <div id="redirect-link" class="py-1 inline-block">
                        <%= if assigns[:result] == "Found" do %>
                          <%= live_redirect(
                            get_number(assigns[:block]),
                            to: ~p"/#{@network}/blocks/#{get_hash(assigns[:block])}",
                            class: "text-hover-blue",
                            id: "number-redirect-link",
                            title: get_hash(assigns[:block])
                          ) %> - <%= live_redirect(
                            Utils.shorten_block_hash(get_hash(assigns[:block])),
                            to: ~p"/#{@network}/blocks/#{get_hash(assigns[:block])}",
                            class: "text-hover-blue",
                            id: "hash-redirect-link",
                            title: get_hash(assigns[:block])
                          ) %>
                        <% else %>
                          <%= assigns[:result] %>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </form>
    </div>
    """
  end

  def mount(_params, session, socket) do
    new_assigns = [query: "", loading: false, matches: [], errors: []]

    socket =
      socket
      |> assign(new_assigns)
      |> assign_new(:network, fn -> session["network"] end)

    {:ok, socket, layout: false}
  end

  def handle_event("update-input", %{"search-input" => query}, socket) do
    send(self(), {:search, query})
    {:noreply, assign(socket, query: query, result: "Searching...", loading: true, matches: [])}
  end

  def handle_event("search", %{"search-input" => query}, socket) when byte_size(query) <= 100 do
    send(self(), {:search, query})
    {:noreply, assign(socket, query: query, result: "Searching...", loading: true, matches: [])}
  end

  def handle_info({:search, query}, socket) do
    query = String.trim(query)

    navigate_fun =
      if String.length(query) > 0 do
        case try_search(query, socket.assigns.network) do
          {:tx, _tx} ->
            fn -> assign(socket, tx: query) end

          {:block, block} ->
            fn -> assign(socket, block: block, result: "Found") end

          {:message, _message} ->
            fn -> assign(socket, message: query) end

          :noquery ->
            fn ->
              assign(socket, result: "No results found")
            end
        end
      else
        fn -> socket end
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
      {:ok, blocks} -> {:block, List.first(blocks)}
      {:error, _} -> :noquery
    end
  end

  def try_by_hash(hash, network) do
    case Data.transaction_by_partial_hash(hash) do
      {:ok, transaction} ->
        {:tx, transaction}

      {:error, _} ->
        case Data.block_by_partial_hash(hash, network) do
          {:ok, blocks} ->
            {:block, List.first(blocks)}

          {:error, _} ->
            case Message.get_by_partial_hash(hash, network) do
              {:ok, _message} -> {:message, hash}
              {:error, err} -> {:noquery, err}
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
