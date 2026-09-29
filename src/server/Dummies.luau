-- Spawns training dummies near the spawn point for testing combat.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local Status = require(script.Parent.Status)

local SPACING = 10
local DISTANCE_FROM_SPAWN = 25

local Dummies = {}

local function spawnDummy(cframe)
	local dummy = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
	dummy.Name = "Training Dummy"

	local humanoid = dummy:FindFirstChildOfClass("Humanoid")
	humanoid.MaxHealth = Config.Dummy.Health
	humanoid.Health = Config.Dummy.Health

	dummy:SetAttribute("MaxPoise", Config.Dummy.MaxPoise)
	CollectionService:AddTag(dummy, "Targetable")

	dummy:PivotTo(cframe)
	dummy.Parent = workspace
	Status.setBaseSpeed(dummy, 0)

	humanoid.Died:Connect(function()
		task.wait(Config.Dummy.RespawnTime)
		dummy:Destroy()
		spawnDummy(cframe)
	end)
end

function Dummies.start()
	local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local origin = if spawnLocation then spawnLocation.Position else Vector3.zero
	local center = origin + Vector3.new(0, 4, -DISTANCE_FROM_SPAWN)

	for i = 1, Config.Dummy.Count do
		local offset = (i - (Config.Dummy.Count + 1) / 2) * SPACING
		local position = center + Vector3.new(offset, 0, 0)
		local facing = Vector3.new(origin.X, position.Y, origin.Z)
		spawnDummy(CFrame.lookAt(position, facing))
	end
end

return Dummies
