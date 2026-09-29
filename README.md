# Roblox-Game

A dark fantasy action RPG for Roblox inspired by Elden Ring, Berserk, and Frieren, synced into Studio with [Rojo](https://rojo.space).

## Setup

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in this folder.
2. Install the Rojo plugin in Roblox Studio.
3. Run `rojo serve` and click **Connect** in the Studio plugin.

## Controls

| Action                  | Keyboard / mouse      | Gamepad |
| ----------------------- | --------------------- | ------- |
| Light attack (3-hit combo) | Left click         | R1      |
| Heavy attack            | F                     | R2      |
| Dodge roll              | Q                     | B       |
| Lock on / off           | Tab or middle click   | R3      |

Rebind these in `src/shared/Config.luau` under `Config.Keybinds`. All combat numbers
(damage, stamina costs, timings, poise) live in the same file.

## Combat

- **Stamina** powers attacks and dodges. You can act as long as you have any left.
- **Dodge** gives a short window of invincibility. Dodging with no movement input backsteps.
- **Poise**: heavy hits break poise faster. Breaking poise staggers the target.
- **Health** does not regenerate.
- **Training dummies** spawn in front of the spawn point and respawn after dying.
- Red boxes show attack hitboxes while `Config.Debug.ShowHitboxes` is on.
- PvP is off by default (`Config.Combat.PvP`).

The greatsword is a placeholder part swung with simple tweens until real animations exist.

## Layout

| Folder        | Syncs to                                        |
| ------------- | ----------------------------------------------- |
| `src/server`  | `ServerScriptService.Server`                    |
| `src/client`  | `StarterPlayer.StarterPlayerScripts.Client`     |
| `src/shared`  | `ReplicatedStorage.Shared`                      |
| `src/character` | `StarterPlayer.StarterCharacterScripts`       |
