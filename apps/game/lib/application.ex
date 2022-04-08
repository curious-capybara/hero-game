defmodule Game.Application do
  use Application

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Game.PlayersSupervisor},
      {Registry, keys: :unique, name: Game.PlayerNamesRegistry},
      {Registry, keys: :duplicate, name: Game.StateRegistry}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
