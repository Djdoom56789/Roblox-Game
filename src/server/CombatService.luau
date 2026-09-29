-- Server-authoritative combat: validates attack and dodge requests, spends stamina,
-- runs hitboxes, and regenerates stamina.
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Damage = require(script.Parent.Damage)
local Status = require(script.Parent.Status)
local Weapon = require(script.Parent.Weapon)

local HITBOX_STEPS = 3

local CombatService = {}

local playerStates = {}

local function getLivingCharacter(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return nil
	end
	return character, humanoid, root
end

local function canAct(player, character)
	if Status.isBusy(character) or Status.isStaggered(character) then
		return false
	end
	return (player:GetAttribute("Stamina") or 0) > 0
end

local function spendStamina(player, state, amount)
	local stamina = player:GetAttribute("Stamina") or 0
	player:SetAttribute("Stamina", math.max(0, stamina - amount))
	state.lastStaminaUse = os.clock()
end

local function findCharacterModel(part)
	local model = part:FindFirstAncestorWhichIsA("Model")
	while model and not model:FindFirstChildOfClass("Humanoid") do
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return model
end

local function showHitbox(cframe, size)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(200, 30, 30)
	part.Transparency = 0.75
	part.CFrame = cframe
	part.Size = size
	part.Parent = workspace
	Debris:AddItem(part, 0.1)
end

local function findTargets(character, root, attack)
	local cframe = root.CFrame * CFrame.new(0, 0, -attack.Range / 2)
	local size = Vector3.new(attack.Width, 6, attack.Range)
	if Config.Debug.ShowHitboxes then
		showHitbox(cframe, size)
	end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local targets = {}
	for _, part in workspace:GetPartBoundsInBox(cframe, size, params) do
		local model = findCharacterModel(part)
		if model and not targets[model] and CollectionService:HasTag(model, "Targetable") then
			local isPlayer = Players:GetPlayerFromCharacter(model) ~= nil
			if Config.Combat.PvP or not isPlayer then
				targets[model] = true
			end
		end
	end
	return targets
end

local function attack(player, kind)
	local state = playerStates[player]
	local character, humanoid, root = getLivingCharacter(player)
	local attackConfig = Config.Attacks[kind]
	if not state or not character or not canAct(player, character) then
		return
	end

	local multiplier = 1
	if kind == "Light" then
		local combo = attackConfig.ComboMultipliers
		state.comboIndex = if os.clock() <= state.comboDeadline then state.comboIndex % #combo + 1 else 1
		multiplier = combo[state.comboIndex]
	else
		state.comboIndex = 0
	end

	spendStamina(player, state, attackConfig.Stamina)

	local duration = attackConfig.Windup + attackConfig.Active + attackConfig.Recovery
	state.comboDeadline = os.clock() + duration + (attackConfig.ComboWindow or 0)

	local actionId = Status.startAction(character, duration, attackConfig.MoveSpeed)
	local function isCurrent()
		return Status.isCurrentAction(character, actionId) and humanoid.Health > 0
	end

	Weapon.swing(character, kind, attackConfig, isCurrent)

	task.delay(attackConfig.Windup, function()
		local alreadyHit = {}
		for _ = 1, HITBOX_STEPS do
			if not isCurrent() then
				return
			end
			for target in findTargets(character, root, attackConfig) do
				if not alreadyHit[target] then
					alreadyHit[target] = true
					Damage.apply(target, attackConfig.Damage * multiplier, attackConfig.PoiseDamage)
				end
			end
			task.wait(attackConfig.Active / HITBOX_STEPS)
		end
	end)
end

local function dodge(player)
	local state = playerStates[player]
	local character = getLivingCharacter(player)
	if not state or not character or not canAct(player, character) then
		return
	end

	local dodgeConfig = Config.Dodge
	spendStamina(player, state, dodgeConfig.Stamina)
	Status.startAction(character, dodgeConfig.Duration + dodgeConfig.Recovery, Config.Player.WalkSpeed)
	Status.setInvulnerable(character, dodgeConfig.InvulnerableTime)
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.MaxHealth = Config.Player.MaxHealth
	humanoid.Health = Config.Player.MaxHealth

	player:SetAttribute("MaxStamina", Config.Player.MaxStamina)
	player:SetAttribute("Stamina", Config.Player.MaxStamina)

	character:SetAttribute("MaxPoise", Config.Player.MaxPoise)
	Status.setBaseSpeed(character, Config.Player.WalkSpeed)
	CollectionService:AddTag(character, "Targetable")

	Weapon.equip(character)
end

local function onPlayerAdded(player)
	playerStates[player] = {
		lastStaminaUse = 0,
		comboIndex = 0,
		comboDeadline = 0,
	}
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

local function regenerateStamina(deltaTime)
	local now = os.clock()
	for player, state in playerStates do
		local character = player.Character
		local stamina = player:GetAttribute("Stamina")
		local maxStamina = player:GetAttribute("MaxStamina")
		if character and stamina and maxStamina and stamina < maxStamina then
			if now - state.lastStaminaUse >= Config.Player.StaminaRegenDelay and not Status.isBusy(character) then
				local regen = Config.Player.StaminaRegenPerSecond * deltaTime
				player:SetAttribute("Stamina", math.min(maxStamina, stamina + regen))
			end
		end
	end
end

function CombatService.start()
	Remotes.CombatAction.OnServerEvent:Connect(function(player, action)
		if action == "Light" or action == "Heavy" then
			attack(player, action)
		elseif action == "Dodge" then
			dodge(player)
		end
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		playerStates[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	RunService.Heartbeat:Connect(regenerateStamina)
end

return CombatService
