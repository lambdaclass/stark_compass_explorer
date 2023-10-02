defmodule StarknetExplorerWeb.TestingLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  @impl true
  def mount(_, _, socket) do
    # :timer.sleep(1000)
    {:ok, socket}
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
      <br>
      <br>
      <br>
      <%= render_info(assigns) %>
    </div>
    """
  end
  defp block_detail_header(assigns) do
    ~H"""
      <div
        phx-click="select-view"
        ,
        phx-value-view="1"
      >
        Overview
      </div>
      <div
        phx-click="select-view"
        ,
        phx-value-view="2"
      >
        Transactions
      </div>
      <div
        phx-click="select-view"
        ,
        phx-value-view="3"
      >
        Message Logs
      </div>
      <div
        phx-click="select-view"
        ,
        phx-value-view="4"
        ,
      >
        Events
      </div>
    """
  end

  def handle_event(_event, %{"view" => view}, socket) do
    assigns = [
      view: view
    ]
    {:noreply, assign(socket, assigns)}
  end

  def render_info(assigns = %{view: view}) do
    ~H"""
      <%= view %>
    """
  end

  def render_info(assigns) do
    ~H"""
      -
    """
  end
end
