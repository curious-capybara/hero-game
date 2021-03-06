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

    test "register in general heroes registry", %{opts: opts} do
      {:ok, pid} = Hero.start_link(:john, opts)
      [{^pid, _hero}] = get_all_heroes(opts)
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

    test "don't remove from all heroes registry", %{opts: opts} do
      {:ok, pid} = Hero.start_link(:john, opts)
      GenServer.cast(pid, :die)
      [{^pid, _}] = get_all_heroes(opts)
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

  describe "affected_by_attack?/3" do
    test "return true when hero in affected area" do
      hero = %Hero{name: :joshua, position: {1, 1}, alive?: true}
      assert Hero.affected_by_attack?(hero, :jane, [{0, 1}, {1, 1}, {2, 2}])
    end

    test "return false when hero outside of affected area" do
      hero = %Hero{name: :joshua, position: {2, 3}, alive?: true}
      refute Hero.affected_by_attack?(hero, :jane, [{0, 1}, {1, 1}, {2, 2}])
    end

    test "return false when hero is already dead" do
      hero = %Hero{name: :joshua, position: {1, 1}, alive?: false}
      refute Hero.affected_by_attack?(hero, :jane, [{0, 1}, {1, 1}, {2, 2}])
    end

    test "return false when hero is an attacker" do
      hero = %Hero{name: :joshua, position: {1, 1}, alive?: true}
      refute Hero.affected_by_attack?(hero, :joshua, [{0, 1}, {1, 1}, {2, 2}])
    end
  end

  describe "handle :attack" do
    setup :gen_server_deps

    test "kills adjacent heroes", %{opts: opts} do
      {:ok, pid1} = Hero.start_link(:john, opts)
      force_position(pid1, {1, 1})
      {:ok, pid2} = Hero.start_link(:jane, opts)
      force_position(pid2, {0, 0})
      {:ok, pid3} = Hero.start_link(:george, opts)
      force_position(pid3, {1, 2})

      GenServer.cast(pid1, :attack)
      assert :sys.get_state(pid1).alive?
      assert wait_until_dead(pid2)
      assert wait_until_dead(pid3)
    end
  end

  describe "handle :respawn" do
    setup :gen_server_deps

    setup(%{opts: opts}) do
      hero = %Hero{
        name: :joshua,
        position: {1, 1},
        alive?: false,
        state_registry: opts[:state_registry]
      }

      {:ok, %{hero: hero}}
    end

    test "set the hero as alive", %{hero: hero} do
      {:noreply, hero} = Hero.handle_info(:respawn, hero)
      assert hero.alive?
    end

    test "assign new position", %{hero: hero} do
      hero = Map.put(hero, :position, {1000, 1000})

      {:noreply, hero} = Hero.handle_info(:respawn, hero)
      {x, y} = hero.position
      assert x < 10
      assert y < 10
    end

    test "puts the hero back in alive registry", %{hero: hero} do
      {:noreply, hero} = Hero.handle_info(:respawn, hero)
      [{_pid, hero_in_registry}] = Registry.lookup(hero.state_registry, :alive)
      assert hero == hero_in_registry
    end
  end

  defp get_alive(opts) do
    Registry.lookup(opts[:state_registry], :alive)
  end

  defp get_all_heroes(opts) do
    Registry.lookup(opts[:state_registry], :heroes)
  end

  defp gen_server_deps(_ctx) do
    names_registry_name = UUID.uuid1() |> String.to_atom()
    {:ok, _pid} = start_supervised({Registry, keys: :unique, name: names_registry_name})
    state_registry_name = UUID.uuid1() |> String.to_atom()
    {:ok, _pid} = start_supervised({Registry, keys: :duplicate, name: state_registry_name})
    {:ok, %{opts: [names_registry: names_registry_name, state_registry: state_registry_name]}}
  end

  def force_position(pid, position) do
    :sys.replace_state(pid, fn hero -> %Hero{hero | position: position} end)
  end

  # Quite dumb helper method to wait for the hero to be dead
  def wait_until_dead(pid, times \\ 10) do
    Stream.unfold(times, fn attempts_left ->
      cond do
        attempts_left == 0 ->
          false

        :sys.get_state(pid).alive? ->
          :timer.sleep(1)
          {:ok, attempts_left - 1}

        true ->
          true
      end
    end)
  end
end
