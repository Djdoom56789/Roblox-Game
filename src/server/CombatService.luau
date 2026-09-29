-- Server-authoritative combat: validates attack, dodge, and spell requests, spends
-- stamina and mana, runs hitboxes, and regenerates stamina and mana.
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local SpellBook = require(Shared.SpellBook)
local Damage = require(script.Parent.Damage)
local Magic = require(script.Parent.Magic)
local Status = require(script.Parent.Status)
local Targeting = require(script.Parent.Targeting)
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

local function isFree(character)
	return not Status.isBusy(character) and not Status.isStaggered(character)
end

local function hasStamina(player)
	return (player:GetAttribute("Stamina") or 0) > 0
end

local function spend(player, state, resource, amount)
	local value = player:GetAttribute(resource) or 0
	player:SetAttribute(resource, math.max(0, value - amount))
	state["last" .. resource .. "Use"] = os.clock()
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

local function attack(player, kind)
	local state = playerStates[player]
	local character, humanoid, root = getLivingCharacter(player)
	local attackConfig = Config.Attacks[kind]
	if not state or not character or not isFree(character) or not hasStamina(player) then
		return
	end

	local multiplier = 1
	local animation = kind
	if kind == "Light" then
		local combo = attackConfig.ComboMultipliers
		state.comboIndex = if os.clock() <= state.comboDeadline then state.comboIndex % #combo + 1 else 1
		multiplier = combo[state.comboIndex]
		animation = "Light" .. state.comboIndex
	else
		state.comboIndex = 0
	end

	spend(player, state, "Stamina", attackConfig.Stamina)

	local duration = attackConfig.Windup + attackConfig.Active + attackConfig.Recovery
	state.comboDeadline = os.clock() + duration + (attackConfig.ComboWindow or 0)

	local actionId = Status.startAction(character, duration, attackConfig.MoveSpeed, animation)
	local function isCurrent()
		return Status.isCurrentAction(character, actionId) and humanoid.Health > 0
	end

	task.delay(attackConfig.Windup, function()
		local alreadyHit = {}
		for _ = 1, HITBOX_STEPS do
			if not isCurrent() then
				return
			end
			local cframe = root.CFrame * CFrame.new(0, 0, -attackConfig.Range / 2)
			local size = Vector3.new(attackConfig.Width, 6, attackConfig.Range)
			if Config.Debug.ShowHitboxes then
				showHitbox(cframe, size)
			end
			for target in Targeting.inBox(character, cframe, size) do
				if not alreadyHit[target] then
					alreadyHit[target] = true
					if Damage.apply(target, attackConfig.Damage * multiplier, attackConfig.PoiseDamage) then
						Remotes.HitConfirm:FireClient(player, if kind == "Heavy" then 0.8 else 0.4)
					end
				end
			end
			task.wait(attackConfig.Active / HITBOX_STEPS)
		end
	end)
end

local function dodge(player)
	local state = playerStates[player]
	local character = getLivingCharacter(player)
	if not state or not character or not isFree(character) or not hasStamina(player) then
		return
	end

	local dodgeConfig = Config.Dodge
	spend(player, state, "Stamina", dodgeConfig.Stamina)
	Status.startAction(character, dodgeConfig.Duration + dodgeConfig.Recovery, Config.Player.WalkSpeed, "Dodge")
	Status.setInvulnerable(character, dodgeConfig.InvulnerableTime)
end

local function cast(player, aimPoint)
	local state = playerStates[player]
	local character, humanoid, root = getLivingCharacter(player)
	local spellName = player:GetAttribute("EquippedSpell")
	local spell = spellName and Config.Spells[spellName]
	if not state or not character or not spell or typeof(aimPoint) ~= "Vector3" then
		return
	end
	if not isFree(character) or not SpellBook.knows(player, spellName) then
		return
	end
	if (player:GetAttribute("Mana") or 0) < spell.Mana or SpellBook.getCooldownRemaining(player, spellName) > 0 then
		return
	end

	spend(player, state, "Mana", spell.Mana)
	player:SetAttribute("Cooldown_" .. spellName, workspace:GetServerTimeNow() + spell.Cooldown)

	local actionId =
		Status.startAction(character, spell.CastTime + spell.Recovery, spell.MoveSpeed, "Cast:" .. spellName)

	task.delay(spell.CastTime, function()
		if not Status.isCurrentAction(character, actionId) or humanoid.Health <= 0 then
			return
		end
		Magic.cast(spellName, character, root, aimPoint, function(intensity)
			Remotes.HitConfirm:FireClient(player, intensity)
		end)
	end)
end

local function equip(player, spellName)
	if typeof(spellName) == "string" and SpellBook.knows(player, spellName) then
		player:SetAttribute("EquippedSpell", spellName)
	end
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.MaxHealth = Config.Player.MaxHealth
	humanoid.Health = Config.Player.MaxHealth

	player:SetAttribute("MaxStamina", Config.Player.MaxStamina)
	player:SetAttribute("Stamina", Config.Player.MaxStamina)
	player:SetAttribute("MaxMana", Config.Player.MaxMana)
	player:SetAttribute("Mana", Config.Player.MaxMana)

	character:SetAttribute("MaxPoise", Config.Player.MaxPoise)
	Status.setBaseSpeed(character, Config.Player.WalkSpeed)
	CollectionService:AddTag(character, "Targetable")

	Weapon.equip(character)
end

local function onPlayerAdded(player)
	playerStates[player] = {
		lastStaminaUse = 0,
		lastManaUse = 0,
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

local function regenerate(player, resource, lastUse, perSecond, delay, deltaTime)
	local value = player:GetAttribute(resource)
	local maxValue = player:GetAttribute("Max" .. resource)
	if value and maxValue and value < maxValue and os.clock() - lastUse >= delay then
		player:SetAttribute(resource, math.min(maxValue, value + perSecond * deltaTime))
	end
end

local function onHeartbeat(deltaTime)
	local playerConfig = Config.Player
	for player, state in playerStates do
		local character = player.Character
		if character then
			if not Status.isBusy(character) then
				regenerate(
					player,
					"Stamina",
					state.lastStaminaUse,
					playerConfig.StaminaRegenPerSecond,
					playerConfig.StaminaRegenDelay,
					deltaTime
				)
			end
			regenerate(
				player,
				"Mana",
				state.lastManaUse,
				playerConfig.ManaRegenPerSecond,
				playerConfig.ManaRegenDelay,
				deltaTime
			)
		end
	end
end

function CombatService.start()
	Remotes.CombatAction.OnServerEvent:Connect(function(player, action, payload)
		if action == "Light" or action == "Heavy" then
			attack(player, action)
		elseif action == "Dodge" then
			dodge(player)
		elseif action == "Cast" then
			cast(player, payload)
		elseif action == "Equip" then
			equip(player, payload)
		end
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		playerStates[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	RunService.Heartbeat:Connect(onHeartbeat)
end

return CombatService
