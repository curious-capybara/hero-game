defmodule GameWebWeb.PageController do
  use GameWebWeb, :controller

  def index(conn, _params) do
    Registry.keys(Game.PlayerNamesRegistry, self())
    Registry.lookup(Game.StateRegistry, :alive) |> IO.inspect
    render(conn, "index.html")
  end

  def game(conn, params) do
    name = params["name"]
    {:ok, pid} = Game.connect_player(name)
    player = Game.player_info(pid)
    map = Game.get_map()
    render(conn, "game.html", player: player, map: map)
  end
end
