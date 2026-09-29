-- Applies damage and poise damage. Breaking a target's poise staggers it.
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local Status = require(script.Parent.Status)

local Damage = {}

local poiseStates = setmetatable({}, { __mode = "k" })

local function flash(model)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.4
	highlight.OutlineTransparency = 1
	highlight.Parent = model
	Debris:AddItem(highlight, 0.12)
end

local function damagePoise(model, amount)
	local maxPoise = model:GetAttribute("MaxPoise") or Config.Player.MaxPoise
	local now = os.clock()
	local state = poiseStates[model]
	if not state or now - state.lastHit > Config.Poise.RegenDelay then
		state = { poise = maxPoise, lastHit = now }
		poiseStates[model] = state
	end

	state.poise -= amount
	state.lastHit = now
	if state.poise <= 0 then
		state.poise = maxPoise
		Status.stagger(model, Config.Poise.StaggerDuration)
	end
end

-- Returns true if the hit landed.
function Damage.apply(target, amount, poiseDamage)
	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	if Status.isInvulnerable(target) then
		return false
	end

	humanoid:TakeDamage(amount)
	damagePoise(target, poiseDamage)
	flash(target)
	return true
end

return Damage
