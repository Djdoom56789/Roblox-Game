# Roblox-Game

A dark fantasy action RPG for Roblox, synced into Studio with [Rojo](https://rojo.space).

## Setup

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in this folder.
2. Install the Rojo plugin in Roblox Studio.
3. Run `rojo serve` and click **Connect** in the Studio plugin.

## Layout

| Folder        | Syncs to                                        |
| ------------- | ----------------------------------------------- |
| `src/server`  | `ServerScriptService.Server`                    |
| `src/client`  | `StarterPlayer.StarterPlayerScripts.Client`     |
| `src/shared`  | `ReplicatedStorage.Shared`                      |
