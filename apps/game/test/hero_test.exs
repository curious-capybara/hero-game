defmodule Game.HeroTest do
  use ExUnit.Case, async: true

  alias Game.Hero

  setup do
    names_registry_name = UUID.uuid1() |> String.to_atom()
    {:ok, _pid} = start_supervised({Registry, keys: :unique, name: names_registry_name})
    state_registry_name = UUID.uuid1() |> String.to_atom()
    {:ok, _pid} = start_supervised({Registry, keys: :duplicate, name: state_registry_name})
    {:ok, %{opts: [names_registry: names_registry_name, state_registry: state_registry_name]}}
  end

  describe "start_link/2" do
    test "set the name", %{opts: opts} do
      {:ok, pid} = Hero.start_link(:john, opts)
      hero = :sys.get_state(pid)
      assert hero.name == :john
    end

    test "register as alive", %{opts: opts} do
      {:ok, pid} = Hero.start_link(:john, opts)
      [{^pid, _hero}] = Registry.lookup(opts[:state_registry], :alive)
    end
  end

  describe "handle :die" do
    test "remove only itself from registry of alive heroes", %{opts: opts} do
      {:ok, pid1} = Hero.start_link(:john, opts)
      {:ok, pid2} = Hero.start_link(:jane, opts)
      assert length(Registry.lookup(opts[:state_registry], :alive)) == 2

      GenServer.cast(pid2, :die)
      :sys.get_state(pid2)

      assert length(Registry.lookup(opts[:state_registry], :alive)) == 1
      [{pid, hero}] = Registry.lookup(opts[:state_registry], :alive)
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
end
