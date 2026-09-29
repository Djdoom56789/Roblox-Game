-- Reads combat input, buffers presses made while busy, performs the dodge movement,
-- and aims spells.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local SpellBook = require(Shared.SpellBook)

local player = Players.LocalPlayer

local CombatInput = {}

local lockOn, spellWheel

-- Local estimate of when the current action ends, so we don't wait for the
-- server's Busy attribute to replicate before accepting the next press.
local busyUntil = 0
local bufferedAction = nil
local bufferedAt = 0

local function getEquippedSpell()
	local spellName = player:GetAttribute("EquippedSpell")
	return spellName, spellName and Config.Spells[spellName]
end

local function actionDuration(action)
	if action == "Cast" then
		local _, spell = getEquippedSpell()
		return spell.CastTime + spell.Recovery
	elseif action == "Dodge" then
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

local function canAct(action)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	if os.clock() < busyUntil or character:GetAttribute("Staggered") then
		return false
	end
	if action == "Cast" then
		local spellName, spell = getEquippedSpell()
		return spell ~= nil
			and (player:GetAttribute("Mana") or 0) >= spell.Mana
			and SpellBook.getCooldownRemaining(player, spellName) <= 0
	end
	return (player:GetAttribute("Stamina") or 0) > 0
end

-- Aims at the locked-on target, otherwise at whatever is under the mouse
-- (or the screen center on gamepad).
local function getAimPoint()
	local target = lockOn.getTarget()
	local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
	if targetRoot then
		return targetRoot.Position
	end

	local camera = workspace.CurrentCamera
	local screenPoint = if UserInputService.GamepadEnabled
			and UserInputService:GetLastInputType().Name:match("^Gamepad")
		then camera.ViewportSize / 2
		else UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(screenPoint.X, screenPoint.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, workspace:FindFirstChild("SpellEffects") }
	local result = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	return if result then result.Position else ray.Origin + ray.Direction * 500
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
	Remotes.CombatAction:FireServer(action, if action == "Cast" then getAimPoint() else nil)
end

local function request(action)
	if action == "Cast" and not getEquippedSpell() then
		return
	end
	if canAct(action) then
		perform(action)
	else
		bufferedAction = action
		bufferedAt = os.clock()
	end
end

local function quickEquip(input)
	local index = table.find(Config.QuickSlotKeys, input.KeyCode)
	local spellName = index and SpellBook.getKnown(player)[index]
	if spellName then
		Remotes.CombatAction:FireServer("Equip", spellName)
	end
end

function CombatInput.start(LockOn, SpellWheel, CameraShake)
	lockOn, spellWheel = LockOn, SpellWheel

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or spellWheel.isOpen() then
			return
		end
		local action = actionForInput(input)
		if action == "LockOn" then
			lockOn.toggle()
		elseif action and action ~= "SpellWheel" then
			request(action)
		else
			quickEquip(input)
		end
	end)

	Remotes.HitConfirm.OnClientEvent:Connect(CameraShake.shake)

	RunService.Heartbeat:Connect(function()
		if not bufferedAction then
			return
		end
		if os.clock() - bufferedAt > Config.Combat.InputBuffer then
			bufferedAction = nil
		elseif canAct(bufferedAction) then
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
