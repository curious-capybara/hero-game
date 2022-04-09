defmodule GameWebWeb.GameLive do
  use Phoenix.LiveView

  def mount(params, %{}, socket) do
    name = params["name"]
    {:ok, pid} = Game.connect_player(name)
    player = Game.player_info(pid)
    map = Game.get_map()
    {:ok, assign(socket, player: player, map: map, player_pid: pid)}
  end

  def render(assigns) do
    Phoenix.View.render(GameWebWeb.PageView, "game.html", assigns)
  end

  def handle_event("move_right", _, socket) do
    player = move(:right, socket)
    {:noreply, assign(socket, :player, player)}
  end

  def handle_event("move_left", _, socket) do
    player = move(:left, socket)
    {:noreply, assign(socket, :player, player)}
  end

  def handle_event("move_up", _, socket) do
    player = move(:up, socket)
    {:noreply, assign(socket, :player, player)}
  end

  def handle_event("move_down", _, socket) do
    player = move(:down, socket)
    {:noreply, assign(socket, :player, player)}
  end

  def handle_event("attack", _, socket) do
    pid = socket.assigns.player_pid
    GenServer.cast(pid, :attack)
    {:noreply, socket}
  end

  defp move(dir, socket) do
    pid = socket.assigns.player_pid
    GenServer.cast(pid, {:move, dir})
    Game.player_info(pid)
  end
end
