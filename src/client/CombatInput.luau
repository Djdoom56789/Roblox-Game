-- Reads combat input, buffers presses made while busy, and performs the dodge movement.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

local CombatInput = {}

-- Local estimate of when the current action ends, so we don't wait for the
-- server's Busy attribute to replicate before accepting the next press.
local busyUntil = 0
local bufferedAction = nil
local bufferedAt = 0

local function actionDuration(action)
	if action == "Dodge" then
		return Config.Dodge.Duration + Config.Dodge.Recovery
	end
	local attack = Config.Attacks[action]
	return attack.Windup + attack.Active + attack.Recovery
end

local function actionForInput(input)
	for action, binds in Config.Keybinds do
		for _, bind in binds do
			if input.KeyCode == bind or input.UserInputType == bind then
				return action
			end
		end
	end
	return nil
end

local function canAct()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	if os.clock() < busyUntil or character:GetAttribute("Staggered") then
		return false
	end
	return (player:GetAttribute("Stamina") or 0) > 0
end

local function performDodge()
	local character = player.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local direction = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
	if direction.Magnitude < 0.1 then
		direction = -root.CFrame.LookVector -- no movement input: backstep
		direction = Vector3.new(direction.X, 0, direction.Z)
	end

	local attachment = root:FindFirstChild("RootAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "RootAttachment"
		attachment.Parent = root
	end

	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	velocity.MaxAxesForce = Vector3.new(1e6, 0, 1e6)
	velocity.VectorVelocity = direction.Unit * Config.Dodge.Speed
	velocity.Parent = root
	Debris:AddItem(velocity, Config.Dodge.Duration)
end

local function perform(action)
	busyUntil = os.clock() + actionDuration(action)
	if action == "Dodge" then
		performDodge()
	end
	Remotes.CombatAction:FireServer(action)
end

local function request(action)
	if canAct() then
		perform(action)
	else
		bufferedAction = action
		bufferedAt = os.clock()
	end
end

function CombatInput.start(LockOn)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		local action = actionForInput(input)
		if action == "LockOn" then
			LockOn.toggle()
		elseif action then
			request(action)
		end
	end)

	RunService.Heartbeat:Connect(function()
		if not bufferedAction then
			return
		end
		if os.clock() - bufferedAt > Config.Combat.InputBuffer then
			bufferedAction = nil
		elseif canAct() then
			local action = bufferedAction
			bufferedAction = nil
			perform(action)
		end
	end)

	player.CharacterAdded:Connect(function()
		busyUntil = 0
		bufferedAction = nil
	end)
end

return CombatInput
