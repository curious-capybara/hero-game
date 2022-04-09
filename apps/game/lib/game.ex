defmodule Game do
  @players_supervisor Game.PlayersSupervisor
  @registry Game.PlayerNamesRegistry

  @doc """
  Connect a player identified by a name to a game. If the name is already used, it connects
  to existing player.
  """
  @spec connect_player(String.t()) :: {:ok, pid()}
  def connect_player(name, opts \\ []) do
    name =
    name
    |> maybe_generate()
          |> String.to_atom()

    registry = Keyword.get(opts, :names_registry, @registry)

    case Registry.lookup(registry, name) do
      [{pid, _}] -> {:ok, pid}
      [] -> start_child(name, opts)
    end
  end

  defp maybe_generate("") do
    base =
    ["Dick", "Elrond", "Janet", "Geralt"]
    |> Enum.random()

    number = :rand.uniform(1000)

    connector = Enum.random(["_", "", "-", "@"])

    "#{base}#{connector}#{number}"
  end

  defp maybe_generate(name), do: name

  defp start_child(name, opts) do
    supervisor = Keyword.get(opts, :supervisor, @players_supervisor)

    DynamicSupervisor.start_child(supervisor, %{
      id: Game.Hero,
      start: {Game.Hero, :start_link, [name, opts]}
    })
  end

  def player_info(pid) do
    GenServer.call(pid, :get)
  end

  def all_heroes do
    Registry.lookup(Game.StateRegistry, :heroes)
    |> Enum.map(fn {pid, _} -> GenServer.call(pid, :get) end)
  end

  def get_map do
    Game.GameMap.get()
  end
end
