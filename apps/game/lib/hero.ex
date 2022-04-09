defmodule Game.Hero do
  use GenServer

  alias __MODULE__

  @names_registry Game.PlayerNamesRegistry
  @state_registry Game.StateRegistry

  @enforce_keys [:name, :position, :alive?]
  defstruct [:name, :position, :alive?, :names_registry, :state_registry]

  def start_link(name, opts \\ []) do
    names_registry = Keyword.get(opts, :names_registry, @names_registry)
    process_name = via_tuple(name, names_registry)
    GenServer.start_link(__MODULE__, Keyword.put(opts, :name, name), name: process_name)
  end

  @impl true
  def init(opts) do
    state_registry = Keyword.get(opts, :state_registry, @state_registry)

    hero = %Hero{
      name: Keyword.get(opts, :name),
      position: get_spawn_position(),
      alive?: true,
      state_registry: state_registry
    }

    Registry.register(state_registry, :alive, hero)
    {:ok, hero}
  end

  @impl true
  def handle_cast(:die, hero) do
    Registry.unregister(hero.state_registry, :alive)
    {:noreply, %Hero{hero | alive?: false}}
  end

  defp via_tuple(name, registry) do
    {:via, Registry, {registry, name}}
  end

  defp get_spawn_position do
    Game.GameMap.get()
    |> Game.GameMap.random_spawn_position()
  end
end
