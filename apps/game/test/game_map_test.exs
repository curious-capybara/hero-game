defmodule Game.GameMapTest do
  use ExUnit.Case, async: true

  alias Game.GameMap

  setup do
    map =
      GameMap.new(5, 5)
      |> GameMap.add_wall({0, 1})
      |> GameMap.add_wall({1, 1})

    {:ok, %{map: map}}
  end

  describe "can_move_to?/2" do
    test "cannot move out of bounds", %{map: map} do
      refute GameMap.can_move_to?(map, {-1, 1})
      refute GameMap.can_move_to?(map, {1, -1})
      refute GameMap.can_move_to?(map, {1, 5})
      refute GameMap.can_move_to?(map, {7, 2})
    end

    test "cannot move onto the wall", %{map: map} do
      refute GameMap.can_move_to?(map, {0, 1})
    end

    test "can move to a free tile", %{map: map} do
      assert GameMap.can_move_to?(map, {2, 2})
    end
  end

  describe "random_spawn_location/1" do
    test "return location hero can move to", %{map: map} do
      location = GameMap.random_spawn_location(map)
      assert GameMap.can_move_to?(map, location)
    end
  end
end
