local CombatInput = require(script.CombatInput)
local HUD = require(script.HUD)
local LockOn = require(script.LockOn)

HUD.start()
LockOn.start()
CombatInput.start(LockOn)
