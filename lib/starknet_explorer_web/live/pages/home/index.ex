defmodule StarknetExplorerWeb.HomeLive.Index do
  use StarknetExplorerWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
      Hello world!
    """
  end
end
