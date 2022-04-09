defmodule Game.HeroTest do
  use ExUnit.Case, async: true

  alias Game.Hero

  describe "start_link/2" do
    setup :gen_server_deps

    test "set the name", %{opts: opts} do
      {:ok, pid} = Hero.start_link(:john, opts)
      hero = :sys.get_state(pid)
      assert hero.name == :john
    end

    test "register as alive", %{opts: opts} do
      {:ok, pid} = Hero.start_link(:john, opts)
      [{^pid, _hero}] = get_alive(opts)
    end

    test "set position", %{opts: opts} do
      {:ok, pid} = Hero.start_link(:john, opts)
      hero = :sys.get_state(pid)
      refute is_nil(hero.position)
    end
  end

  describe "handle :die" do
    setup :gen_server_deps

    test "remove only itself from registry of alive heroes", %{opts: opts} do
      {:ok, pid1} = Hero.start_link(:john, opts)
      {:ok, pid2} = Hero.start_link(:jane, opts)
      assert length(get_alive(opts)) == 2

      GenServer.cast(pid2, :die)
      :sys.get_state(pid2)

      [{pid, hero}] = get_alive(opts)
      assert pid == pid1
      assert hero.name == :john
    end

    test "set hero state to dead", %{opts: opts} do
      {:ok, pid} = Hero.start_link(:john, opts)
      GenServer.cast(pid, :die)
      hero = :sys.get_state(pid)
      refute hero.alive?
    end
  end

  describe "move/2" do
    test "move to a free tile changes position" do
      hero = %Hero{name: :josh, position: {2, 2}, alive?: true}
      moved_hero = Hero.move(hero, :right)
      assert moved_hero.position == {3, 2}
    end

    test "move to the wall does not change position" do
      hero = %Hero{name: :josh, position: {0, 0}, alive?: true}
      moved_hero = Hero.move(hero, :up)
      assert moved_hero.position == {0, 0}
    end
  end

  describe "handle :move" do
    setup :gen_server_deps

    test "update position", %{opts: opts} do
      {:ok, pid} = Hero.start_link(:john, opts)
      hero = :sys.get_state(pid)

      # we need to find a direction that actually changes hero position
      direction_changing_position =
        [:left, :right, :up, :down]
        |> Enum.map(fn dir -> {dir, Hero.move(hero, dir).position} end)
        |> Enum.filter(fn {_, pos} -> pos != hero.position end)
        |> Enum.map(fn {dir, _} -> dir end)
        |> List.first()

      GenServer.cast(pid, {:move, direction_changing_position})
      hero_after_move = :sys.get_state(pid)

      assert hero.position != hero_after_move.position
    end
  end

  defp get_alive(opts) do
    Registry.lookup(opts[:state_registry], :alive)
  end

  defp gen_server_deps(_ctx) do
    names_registry_name = UUID.uuid1() |> String.to_atom()
    {:ok, _pid} = start_supervised({Registry, keys: :unique, name: names_registry_name})
    state_registry_name = UUID.uuid1() |> String.to_atom()
    {:ok, _pid} = start_supervised({Registry, keys: :duplicate, name: state_registry_name})
    {:ok, %{opts: [names_registry: names_registry_name, state_registry: state_registry_name]}}
  end
end
