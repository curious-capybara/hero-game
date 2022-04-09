defmodule GameWebWeb.GameLive do
  use Phoenix.LiveView

  def mount(params, %{}, socket) do
    name = params["name"]
    {:ok, pid} = Game.connect_player(name)
    player = Game.player_info(pid)
    map = Game.get_map()

    Process.send_after(self(), :refresh, 500)

    socket =
      socket
      |> assign(map: map, player_pid: pid)
      |> refresh_players()

    {:ok, socket}
  end

  def render(assigns) do
    Phoenix.View.render(GameWebWeb.PageView, "game.html", assigns)
  end

  def handle_event("move_right", _, socket) do
    move(:right, socket)
  end

  def handle_event("move_left", _, socket) do
    move(:left, socket)
  end

  def handle_event("move_up", _, socket) do
    move(:up, socket)
  end

  def handle_event("move_down", _, socket) do
    move(:down, socket)
  end

  def handle_event("attack", _, socket) do
    pid = socket.assigns.player_pid
    GenServer.cast(pid, :attack)
    {:noreply, socket}
  end

  def handle_info(:refresh, socket) do
    Process.send_after(self(), :refresh, 500)
    {:noreply, refresh_players(socket)}
  end

  defp move(dir, socket) do
    pid = socket.assigns.player_pid
    GenServer.cast(pid, {:move, dir})
    {:noreply, refresh_players(socket)}
  end

  defp refresh_players(socket) do
    player = Game.player_info(socket.assigns.player_pid)
    heroes = Game.all_heroes()
    assign(socket, heroes: heroes, player: player)
  end
end
