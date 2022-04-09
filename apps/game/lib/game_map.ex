defmodule Game.GameMap do
  @moduledoc """
  Represents a map on which the game takes place. A redundant "game" part in the name
  is to avoid confusion with built-in Elixir's Map module.
  """

  use Agent

  alias __MODULE__

  @type t :: %__MODULE__{}
  @typep position :: {integer(), integer()}

  @enforce_keys [:width, :height, :walls]
  defstruct [:width, :height, :walls]

  @doc """
  Starts an Agent with hardcoded map
  """
  def start_link(_) do
    map =
      new(10, 10)
      |> add_wall({0, 1})
      |> add_wall({0, 2})
      |> add_wall({0, 3})
      |> add_wall({3, 3})
      |> add_wall({9, 8})

    Agent.start_link(fn -> map end, name: __MODULE__)
  end

  @doc """
  Returns a map from the Agent.
  """
  def get do
    Agent.get(__MODULE__, & &1)
  end

  @doc """
  Creates a new empty map with given width and height.
  """
  @spec new(integer(), integer()) :: GameMap.t()
  def new(width, height) do
    %GameMap{width: width, height: height, walls: []}
  end

  @doc """
  Marks a given tile as a wall.
  """
  @spec add_wall(GameMap.t(), position()) :: GameMap.t()
  def add_wall(map, position) do
    %GameMap{map | walls: [position | map.walls]}
  end

  @doc """
  Checks if the position is a valid one for the hero to move to.

  NOTE: Perhaps it should return :ok | {:error, :out_of_bounds} | {:error, :wall} ?
  Can we use it for something?
  """
  @spec can_move_to?(GameMap.t(), position()) :: boolean()
  def can_move_to?(map, {x, y} = position) do
    cond do
      x < 0 or y < 0 or x >= map.width or y >= map.height -> false
      position in map.walls -> false
      true -> true
    end
  end

  @doc """
  Finds a suitable position to spawn a hero.
  By "suitable" we mean non-wall. There can be other heores in this tile.
  """
  @spec random_spawn_position(GameMap.t()) :: position()
  def random_spawn_position(map) do
    x = :rand.uniform(map.width) - 1
    y = :rand.uniform(map.height) - 1

    if can_move_to?(map, {x, y}),
      do: {x, y},
      else: random_spawn_position(map)
  end
end
