defmodule StarknetExplorerWeb.SearchLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Data
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Message
  alias StarknetExplorer.Events

  def render(assigns) do
    ~H"""
    <div id="searchbar-wrapper" phx-hook="SearchBar" class="w-full mr-2 lg:mr-0 flex justify-end">
      <form
        id="placeholder-form"
        class="normal-form !my-0 lg:!max-w-sm !m-0 lg:shrink-0 min-w-[10rem]"
        phx-click="open-search"
      >
        <img
          alt="Search bar icon"
          src={~p"/images/search.svg"}
          class="absolute top-1/2 left-4 transform -translate-y-1/2 w-5 h-auto"
        />
        <input
          type="text"
          placeholder="Search (cmd+K or ctrl+K)"
          class="pl-12 pr-5 py-3 text-normal w-full text-sm"
          readonly
        />
      </form>
      <div
        id="search-overlay"
        class={"fixed inset-0 z-50 overflow-y-hidden transition-opacity duration-100 ease-in #{if @opened, do: '', else: 'opacity-0 pointer-events-none'}"}
      >
        <div
          class="fixed inset-0 bg-zinc-400/25 backdrop-blur-sm
          dark:bg-black/60 opacity-100 z-20 overflow-hidden"
          phx-click="close-search"
        >
        </div>
        <div id="nav-search-bar" class="px-5 max-w-3xl w-full mx-auto relative z-40 top-5 lg:top-20">
          <div class="relative xl:w-full">
            <form class="normal-form" phx-change="update-input" phx-submit="search">
              <div class="relative z-20">
                <div class="absolute top-1/2 left-4 transform -translate-y-1/2 flex items-enter">
                  <%= if @loading do %>
                    <img alt="Loading blocks" class="w-5 h-auto" src={~p"/images/loading-blocks.svg"} />
                  <% else %>
                    <button type="submit">
                      <img alt="Submit request" class="w-5 h-auto" src={~p"/images/search.svg"} />
                    </button>
                  <% end %>
                </div>
                <.input
                  type="text"
                  name="search-input"
                  value={@query}
                  id="search-input"
                  class={"py-3 pl-12 pr-5 #{if @show_result_box && !@loading, do: '!rounded-b-none', else: ''}"}
                  placeholder="Search Blocks, Transactions, Classes, Contracts, Messages and Events"
                  phx-debounce="500"
                />
                <div class="py-1 px-2 bg-gray-800 rounded-md text-sm text-gray-300 absolute top-1/2 right-4 -translate-y-1/2">
                  ESC
                </div>
              </div>
            </form>
            <%= if @show_result_box && !@loading do %>
              <div
                id="dropdownInformation"
                class={"#{if @show_result_box, do: '', else: 'hidden'} lg:absolute px-5 pt-6 -translate-y-5 z-10 bg-container rounded-lg shadow w-full mx-auto dark:bg-container dark:divide-gray-600 border border-zinc-700 focus:border-zinc-400"}
              >
                <div class="py-3 text-sm text-gray-900 dark:text-white">
                  <%= case assigns[:result] do %>
                    <% "" -> %>
                    <% "Searching..." -> %>
                    <% "No results found" -> %>
                      <div class="flex flex-col gap-2 items-center py-4">
                        <img alt="Empty results" class="w-5 h-auto" src={~p"/images/search-w.svg"} />
                        No results found
                      </div>
                    <% _ -> %>
                      <%= assigns[:result] %>
                      <div>
                        <ul
                          class="py-2 text-sm text-gray-700 dark:text-gray-200"
                          aria-labelledby="dropdownInformationButton"
                        >
                          <li>
                            <a
                              href={Utils.network_path(@network, @path)}
                              class="text-hover-blue"
                              id="number-redirect-link"
                              title={get_hash(@result_item)}
                            >
                              <div class="cursor-pointer flex flex-row justify-start items-start block px-4 py-2 rounded-md border-2 border-zinc-700 bg-[#21212d] hover:border-brand">
                                <div class="font-mono flex items-center gap-4 py-2">
                                  <%= case assigns[:result] do %>
                                    <% "Block" -> %>
                                      <img
                                        alt="Blocks logo"
                                        class="shrink-0 inline-block w-6 h-auto"
                                        src={~p"/images/box.svg"}
                                      />
                                      <div>
                                        <div>
                                          <%= get_number(@result_item) %>
                                        </div>
                                        <div class="hash text-zinc-400">
                                          <%= get_hash(@result_item) %>
                                        </div>
                                      </div>
                                    <% "Message" -> %>
                                      <img
                                        alt="Messages logo"
                                        class="shrink-0 inline-block w-6 h-auto"
                                        src={~p"/images/message.svg"}
                                      />
                                      <div class="hash">
                                        <%= @result_item %>
                                      </div>
                                    <% "Transaction" -> %>
                                      <img
                                        alt="Transactions logo"
                                        class="shrink-0 inline-block w-5 h-auto"
                                        src={~p"/images/transaction.svg"}
                                      />
                                      <div class="hash">
                                        <%= @result_item %>
                                      </div>
                                    <% "Event" -> %>
                                      <img
                                        alt="Events logo"
                                        class="shrink-0 inline-block w-5 h-auto"
                                        src={~p"/images/calendar.svg"}
                                      />
                                      <div class="hash">
                                        <%= @result_item %>
                                      </div>
                                    <% "Class" -> %>
                                      <img
                                        alt="Class logo"
                                        class="shrink-0 inline-block w-5 h-auto"
                                        src={~p"/images/code.svg"}
                                      />
                                      <div class="hash">
                                        <%= @result_item %>
                                      </div>
                                    <% "Contract" -> %>
                                      <img
                                        alt="Contracts logo"
                                        class="shrink-0 inline-block w-5 h-auto"
                                        src={~p"/images/file.svg"}
                                      />
                                      <div class="hash">
                                        <%= @result_item %>
                                      </div>
                                  <% end %>
                                </div>
                              </div>
                            </a>
                          </li>
                        </ul>
                      </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, session, socket) do
    new_assigns = [
      query: "",
      loading: false,
      matches: [],
      errors: [],
      opened: false,
      show_result_box: false
    ]

    socket =
      socket
      |> assign(new_assigns)
      |> assign_new(:network, fn -> session["network"] end)

    {:ok, socket, layout: false}
  end

  def handle_event("open-search", _, socket) do
    socket = assign(socket, opened: true)
    {:noreply, push_event(socket, "focus", %{id: "search-input"})}
  end

  def handle_event("close-search", _, socket) do
    socket = assign(socket, opened: false, query: "", loading: false, show_result_box: false)
    {:noreply, socket}
  end

  def handle_event("update-input", %{"search-input" => query}, socket) do
    send(self(), {:search, query})

    {:noreply,
     assign(socket,
       query: query,
       result: "Searching...",
       loading: true,
       show_result_box: true,
       matches: []
     )}
  end

  def handle_event("search", %{"search-input" => query}, socket) when byte_size(query) <= 100 do
    send(self(), {:search, query})

    {:noreply,
     assign(socket,
       query: query,
       result: "Searching...",
       loading: true,
       show_result_box: true,
       matches: []
     )}
  end

  def handle_info({:search, query}, socket) do
    query = String.trim(query)

    navigate_fun =
      if String.length(query) > 0 do
        case try_search(query, socket.assigns.network) do
          {:contract, _} ->
            fn ->
              assign(socket,
                result_item: query,
                result: "Contract",
                loading: false,
                path: "contracts/#{query |> StarknetExplorer.Utils.trim_leading_zeroes()}"
              )
            end

          {:class, _class} ->
            fn ->
              assign(socket,
                result_item: query,
                result: "Class",
                loading: false,
                path: "classes/#{query |> StarknetExplorer.Utils.trim_leading_zeroes()}"
              )
            end

          {:tx, _tx} ->
            fn ->
              assign(socket,
                result_item: query,
                result: "Transaction",
                loading: false,
                path: "transactions/#{query |> StarknetExplorer.Utils.trim_leading_zeroes()}"
              )
            end

          {:block, block} ->
            fn ->
              assign(socket,
                result_item: block,
                result: "Block",
                loading: false,
                path: "blocks/#{get_hash(block |> StarknetExplorer.Utils.trim_leading_zeroes())}"
              )
            end

          {:message, message} ->
            fn ->
              assign(socket,
                result_item: message.message_hash,
                result: "Message",
                loading: false,
                path: "messages/#{message.message_hash}"
              )
            end

          {:event, event} ->
            fn ->
              assign(socket,
                result_item: event.id,
                result: "Event",
                loading: false,
                path: "events/#{event.id}"
              )
            end

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
      :hex -> try_by_hash(query |> StarknetExplorer.Utils.trim_leading_zeroes(), network)
      {:number, number} -> try_by_number(number, network)
      :uuid -> try_by_uuid(query, network)
      :noquery -> :noquery
    end
  end

  def try_by_uuid(uuid, network) do
    case Events.get_by_id(uuid, network) do
      event = %StarknetExplorer.Events{} ->
        {:event, event}

      _ ->
        :noquery
    end
  end

  def try_by_number(number, network) do
    case Data.block_by_partial_number(number, network) do
      {:ok, blocks = [_ | _]} -> {:block, List.first(blocks)}
      _ -> :noquery
    end
  end

  def try_by_hash(hash, network) do
    case Data.transaction_by_partial_hash(hash, network) do
      {:ok, transaction} ->
        {:tx, transaction}

      _ ->
        case StarknetExplorer.Contract.get_by_address(hash, network) do
          %StarknetExplorer.Contract{} = contract ->
            {:contract, contract}

          _ ->
            case StarknetExplorer.Class.get_by_hash(hash, network) do
              %StarknetExplorer.Class{} = class ->
                {:class, class}

              _ ->
                case Data.block_by_partial_hash(hash, network) do
                  {:ok, blocks = [_ | _]} ->
                    {:block, List.first(blocks)}

                  _ ->
                    case Message.get_by_partial_hash(hash, network) do
                      [message | _] ->
                        {:message, message}

                      _ ->
                        :noquery
                    end
                end
            end
        end
    end
  end

  defp infer_query(_query = <<"0x", _rest::binary>>), do: :hex

  defp infer_query(query) do
    case Integer.parse(query) do
      {parsed, ""} ->
        {:number, parsed}

      _ ->
        case match?({:ok, _}, Ecto.UUID.dump(query)) do
          true -> :uuid
          _ -> :noquery
        end
    end
  end

  defp get_number(%StarknetExplorer.Block{number: number}), do: "#{number}"
  defp get_number(_), do: ""

  defp get_hash(%StarknetExplorer.Block{hash: hash}), do: "#{hash}"
  defp get_hash(%StarknetExplorer.Message{message_hash: hash}), do: "#{hash}"
  defp get_hash(nil), do: ""
  defp get_hash(""), do: ""
  defp get_hash(hash), do: "#{hash}"
end
