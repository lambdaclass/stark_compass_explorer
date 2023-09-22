defmodule StarknetExplorerWeb.SearchLive do
  alias Expo.Messages
  alias Expo.Message
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Data

  def render(assigns) do
    ~H"""
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
      <button class=" absolute top-1/2 right-2 transform -translate-y-1/2" type="submit">
        <img src={~p"/images/search.svg"} />
      </button>
    </form>
    <div id="dropdownInformation" class="hidden z-10 bg-container divide-y divide-gray-100 rounded-lg shadow w-full max-w-7xl mx-auto dark:bg-[#232331] dark:divide-gray-600">
      <div>
      <div class="px-4 py-3 text-sm text-gray-900 dark:text-white">
        <div>Block</div>
      </div>
      <ul class="py-2 text-sm text-gray-700 dark:text-gray-200" aria-labelledby="dropdownInformationButton">
        <li>
          <a href="#" class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white">Dashboard</a>
        </li>
      </ul>
      </div>
</div>
    """
  end

  def mount(_params, session, socket) do
    new_assigns = [query: "", block: {}, loading: false, matches: [], errors: []]

    socket =
      socket
      |> assign(new_assigns)
      |> assign_new(:network, fn -> session["network"] end)
    {:ok, socket}
  end

  def handle_event("update-input", %{"search-input" => query}, socket) do
    block = case try_search(query, socket.assigns.network) do
      {:block, block} ->
      #fn -> push_navigate(socket, to: ~p"/#{socket.assigns.network}/blocks/#{query}") end
      IO.inspect(block.number)
      assign(socket, block: block)

    end
    {:noreply, assign(socket, :query, query)}
  end

  def handle_event("search", %{"search-input" => query}, socket) when byte_size(query) <= 100 do
    send(self(), {:search, query})
    {:noreply, assign(socket, query: query, result: "Searching...", loading: true, matches: [])}
  end

  def handle_info({:search, query}, socket) do
    query = String.trim(query)
    navigate_fun =
      case try_search(query, socket.assigns.network) do
        {:tx, _tx} ->
          fn ->
            push_navigate(socket, to: ~p"/#{socket.assigns.network}/transactions/#{query}")
          end

        {:block, block} ->
          #fn -> push_navigate(socket, to: ~p"/#{socket.assigns.network}/blocks/#{query}") end
          fn -> assign(socket, tag: block) end

        {:message, _message} ->
          fn -> push_navigate(socket, to: ~p"/#{socket.assigns.network}/blocks/#{query}") end
        :noquery ->
          fn ->
            socket
            |> put_flash(:error, "No results found")
            |> push_navigate(to: "/#{socket.assigns.network}")
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
    case Data.block_by_number(number, network) do
      {:ok, _block} -> {:block, number}
      {:error, _} -> :noquery
    end
  end

  def try_by_hash(hash, network) do
    case Data.transaction(hash, network) do
      {:ok, _transaction} ->
        {:tx, hash}
      {:error, _} ->
        case Data.block_by_hash(hash, network) do
          {:ok, block} -> {:block, block}
          {:error, _} ->
            case Message.get_by_hash(hash, network) do
              {:ok, _message} -> {:message, hash}
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
end
