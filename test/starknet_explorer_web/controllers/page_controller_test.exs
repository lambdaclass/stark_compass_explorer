defmodule StarknetExplorerWeb.PageControllerTest do
  use StarknetExplorerWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 302)
  end
end
