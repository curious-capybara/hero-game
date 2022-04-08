defmodule Game do
  @players_supervisor Game.PlayersSupervisor
  @registry Game.PlayerNamesRegistry

  @doc """
  Connect a player identified by a name to a game. If the name is already used, it connects
  to existing player.
  TODO: If no name given, generate one randomly.
  """
  @spec connect_player(String.t()) :: {:ok, pid()} | {:error, :not_found}
  def connect_player(name, opts \\ []) do
    name = String.to_atom(name)
    registry = Keyword.get(opts, :names_registry, @registry)

    case Registry.lookup(registry, name) do
      [{pid, _}] -> {:ok, pid}
      [] -> start_child(name, opts)
    end
  end

  defp start_child(name, opts) do
    supervisor = Keyword.get(opts, :supervisor, @players_supervisor)

    DynamicSupervisor.start_child(supervisor, %{
      id: Game.Hero,
      start: {Game.Hero, :start_link, [name, opts]}
    })
  end
end
