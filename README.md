# Heroes

A simple multiplayer game.

# Running locally

``` sh
cd apps/game_web
mix phx.server
```

# Testing

``` sh
mix test
```

# Releasing

To build a release:

```sh
MIX_ENV=prod mix release game_web
```

Running a release locally:

``` sh
export SECRET_KEY_BASE="$(mix phx.gen.secret)"
PHX_HOST=localhost PHX_SERVER=true _build/prod/rel/game_web/bin/game_web start
```
