defmodule GameTest do
  use ExUnit.Case
  doctest Game

  describe "connect_player/1" do
    setup do
      supervisor_name = UUID.uuid1() |> String.to_atom()
      registry_name = UUID.uuid1() |> String.to_atom()
      {:ok, _pid} = start_supervised({Registry, keys: :unique, name: registry_name})

      {:ok, _pid} =
        start_supervised({DynamicSupervisor, name: supervisor_name, strategy: :one_for_one})

      {:ok, opts: [names_registry: registry_name, supervisor: supervisor_name]}
    end

    test "spawn a new player process", %{opts: opts} do
      assert DynamicSupervisor.count_children(opts[:supervisor]) == %{active: 0, specs: 0, supervisors: 0, workers: 0}
      name = UUID.uuid1()
      Game.connect_player(name, opts)
      assert DynamicSupervisor.count_children(opts[:supervisor]) == %{active: 1, specs: 1, supervisors: 0, workers: 1}
    end

    test "give a player a random name if empty given", %{opts: opts} do
      {:ok, pid} = Game.connect_player("", opts)
      hero = :sys.get_state(pid)
      refute hero.name == ""
      refute is_nil(hero.name)
    end

    test "don't spawn a new player process when name is already used", %{opts: opts} do
      name = UUID.uuid1()
      Game.connect_player(name, opts)
      assert DynamicSupervisor.count_children(opts[:supervisor]) == %{active: 1, specs: 1, supervisors: 0, workers: 1}
      Game.connect_player(name, opts)
      assert DynamicSupervisor.count_children(opts[:supervisor]) == %{active: 1, specs: 1, supervisors: 0, workers: 1}
    end

    test "return same pid when connecting to existing player", %{opts: opts} do
      name = UUID.uuid1()
      {:ok, pid} = Game.connect_player(name, opts)
      assert {:ok, ^pid} = Game.connect_player(name, opts)
    end
  end
end
