defmodule Game.Hero do
  use GenServer

  alias __MODULE__
  alias Game.GameMap

  @names_registry Game.PlayerNamesRegistry
  @state_registry Game.StateRegistry

  @enforce_keys [:name, :position, :alive?]
  defstruct [:name, :position, :alive?, :names_registry, :state_registry]

  @type t :: %__MODULE__{}

  def start_link(name, opts \\ []) do
    names_registry = Keyword.get(opts, :names_registry, @names_registry)
    process_name = via_tuple(name, names_registry)
    GenServer.start_link(__MODULE__, Keyword.put(opts, :name, name), name: process_name)
  end

  @impl true
  def init(opts) do
    state_registry = Keyword.get(opts, :state_registry, @state_registry)
    names_registry = Keyword.get(opts, :names_registry, @names_registry)

    hero = %Hero{
      name: Keyword.get(opts, :name),
      position: get_spawn_position(),
      alive?: true,
      state_registry: state_registry,
      names_registry: names_registry
    }

    Registry.register(state_registry, :alive, hero)
    {:ok, hero}
  end

  @impl true
  def handle_call(:get, _from, hero) do
    {:reply, hero, hero}
  end

  @impl true
  def handle_cast(:die, hero) do
    Registry.unregister(hero.state_registry, :alive)
    Process.send_after(self(), :respawn, 1000 * 5)
    {:noreply, %Hero{hero | alive?: false}}
  end

  @impl true
  def handle_cast({:move, direction}, hero) do
    {:noreply, Hero.move(hero, direction)}
  end

  @impl true
  def handle_cast(:attack, hero) do
    affected_positions = GameMap.attack_aoe(GameMap.get(), hero.position)

    Registry.dispatch(hero.state_registry, :alive, fn heroes ->
      for {pid, _} <- heroes do
        GenServer.cast(pid, {:attack_performed, hero.name, affected_positions})
      end
    end)

    {:noreply, hero}
  end

  @impl true
  def handle_cast({:attack_performed, attacker_name, affected_positions}, hero) do
    if Hero.affected_by_attack?(hero, attacker_name, affected_positions),
      do: GenServer.cast(self(), :die)

    {:noreply, hero}
  end

  @impl true
  def handle_info(:respawn, hero) do
    hero = %Hero{hero | position: get_spawn_position(), alive?: true}
    Registry.register(hero.state_registry, :alive, hero)
    {:noreply, hero}
  end

  @doc """
  Moves a hero in a given direction. If it's not possible to move in a given direction
  because of map boundaries or obstacles, returns a hero with original position (not an error).
  """
  @spec move(Hero.t(), atom()) :: Hero.t()
  def move(hero, direction) do
    {x, y} = hero.position

    new_position =
      case direction do
        :left -> {x - 1, y}
        :right -> {x + 1, y}
        :up -> {x, y + 1}
        :down -> {x, y - 1}
      end

    if GameMap.get() |> GameMap.can_move_to?(new_position),
      do: %Hero{hero | position: new_position},
      else: hero
  end

  @doc """
  Checks if the hero if affected by a current attack
  """
  @spec affected_by_attack?(Hero.t(), atom(), list({integer(), integer()})) :: boolean()
  def affected_by_attack?(hero, attacker_name, affected_positions) do
    cond do
      not hero.alive? -> false
      hero.name == attacker_name -> false
      hero.position in affected_positions -> true
      true -> false
    end
  end

  defp via_tuple(name, registry) do
    {:via, Registry, {registry, name}}
  end

  defp get_spawn_position do
    GameMap.get()
    |> GameMap.random_spawn_position()
  end
end
