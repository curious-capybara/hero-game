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

  describe "random_spawn_position/1" do
    test "return position hero can move to", %{map: map} do
      position = GameMap.random_spawn_position(map)
      assert GameMap.can_move_to?(map, position)
    end
  end

  describe "attack_aoe/2" do
    test "return all adjacent fields", %{map: map} do
      assert GameMap.attack_aoe(map, {3, 3}) == [
               {2, 2},
               {3, 2},
               {4, 2},
               {2, 3},
               {3, 3},
               {4, 3},
               {2, 4},
               {3, 4},
               {4, 4}
             ]
    end

    test "don't return out of bounds tiles", %{map: map} do
      assert GameMap.attack_aoe(map, {4, 4}) == [{3, 3}, {4, 3}, {3, 4}, {4, 4}]
    end

    test "don't return wall tiles", %{map: map} do
      assert GameMap.attack_aoe(map, {1, 2}) == [
               {2, 1},
               {0, 2},
               {1, 2},
               {2, 2},
               {0, 3},
               {1, 3},
               {2, 3}
             ]
    end
  end
end
