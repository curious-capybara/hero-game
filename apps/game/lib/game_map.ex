defmodule Game.GameMap do
  @moduledoc """
  Represents a map on which the game takes place. A redundant "game" part in the name
  is to avoid confusion with built-in Elixir's Map module.
  """

  alias __MODULE__

  @type t :: %__MODULE__{}
  @typep position :: {integer(), integer()}

  @enforce_keys [:width, :height, :walls]
  defstruct [:width, :height, :walls]

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
  Finds a suitable location to spawn a hero.
  By "suitable" we mean non-wall. There can be other heores in this tile.
  """
  @spec random_spawn_location(GameMap.t()) :: position()
  def random_spawn_location(map) do
    x = :rand.uniform(map.width) - 1
    y = :rand.uniform(map.height) - 1

    if can_move_to?(map, {x, y}),
      do: {x, y},
      else: random_spawn_location(map)
  end
end
