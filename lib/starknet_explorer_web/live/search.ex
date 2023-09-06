defmodule StarknetExplorerWeb.SearchLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Data

  def render(assigns) do
    ~H"""
    <form phx-change="update-input" phx-submit="search">
      <.input
        phx-change="update-input"
        type="text"
        name="search-input"
        value={@query}
        placeholder="Search Blocks, Transactions, Classes, Messages, Contracts or Events"
      />
      <button class="absolute top-1/2 right-2 transform -translate-y-1/2" type="submit">
        <img src={~p"/images/search.svg"} />
      </button>
    </form>
    """
  end

  def mount(_params, session, socket) do
    new_assigns = [query: "", loading: false, matches: [], errors: []]

    socket =
      socket
      |> assign(new_assigns)
      |> assign_new(:network, fn -> session["network"] end)

    {:ok, socket}
  end

  def handle_event("update-input", %{"search-input" => query}, socket) do
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

        {:block, _block} ->
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
          {:error, _} -> :noquery
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
