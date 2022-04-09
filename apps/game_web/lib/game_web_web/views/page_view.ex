defmodule GameWebWeb.PageView do
  use GameWebWeb, :view

  def tiles(map, player, heroes) do
    rows_range = (map.height-1)..0
    cols_range = 0..(map.width-1)
    Enum.map(rows_range, fn y ->
      Enum.map(cols_range, fn x ->
        player_position? = {x, y} == player.position
        hero = if !player_position?, do: Enum.find(heroes, & &1.position == {x, y})

        {type, label} = cond do
          player_position? and player.alive? -> {"player", player.name}
          player_position? -> {"player-dead", player.name}
          not is_nil(hero) and hero.alive? -> {"enemy", hero.name}
          not is_nil(hero) -> {"enemy-dead", hero.name}
          {x, y} in map.walls -> {"wall", nil}
          true -> {"empty", nil}
        end
        {{x, y}, type, label}
      end)
    end)
  end
end
