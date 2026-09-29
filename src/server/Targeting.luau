-- Finds characters that an attacker is allowed to hit.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local Targeting = {}

-- Returns the character model (a Model with a Humanoid) that `part` belongs to.
function Targeting.getModel(part)
	local model = part:FindFirstAncestorWhichIsA("Model")
	while model and not model:FindFirstChildOfClass("Humanoid") do
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return model
end

function Targeting.canHit(attacker, model)
	if model == attacker or not CollectionService:HasTag(model, "Targetable") then
		return false
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	local bothPlayers = Players:GetPlayerFromCharacter(model) and Players:GetPlayerFromCharacter(attacker)
	return Config.Combat.PvP or not bothPlayers
end

local function collect(attacker, parts)
	local found = {}
	for _, part in parts do
		local model = Targeting.getModel(part)
		if model and not found[model] and Targeting.canHit(attacker, model) then
			found[model] = true
		end
	end
	return found
end

local function overlapParams(attacker)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { attacker }
	return params
end

-- Both return a set: { [model] = true }.
function Targeting.inBox(attacker, cframe, size)
	return collect(attacker, workspace:GetPartBoundsInBox(cframe, size, overlapParams(attacker)))
end

function Targeting.inRadius(attacker, position, radius)
	return collect(attacker, workspace:GetPartBoundsInRadius(position, radius, overlapParams(attacker)))
end

return Targeting
