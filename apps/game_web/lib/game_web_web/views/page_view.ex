defmodule GameWebWeb.PageView do
  use GameWebWeb, :view

  def tiles(map, player) do
    rows_range = (map.height-1)..0
    cols_range = 0..(map.width-1)
    Enum.map(rows_range, fn y ->
      Enum.map(cols_range, fn x ->
        {type, label} = cond do
          {x, y} == player.position -> {"player", player.name}
          {x, y} in map.walls -> {"wall", nil}
          true -> {"empty", nil}
        end
        {{x, y}, type, label}
      end)
    end)
  end
end
