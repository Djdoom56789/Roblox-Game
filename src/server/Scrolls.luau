-- Places a spell scroll on a pedestal for each spell. Reading one teaches the spell.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local SpellBook = require(Shared.SpellBook)

local SPACING = 7
local OFFSET_FROM_SPAWN = Vector3.new(22, 0, 0)

local Scrolls = {}

local function learn(player, spellName)
	local spell = Config.Spells[spellName]
	if SpellBook.knows(player, spellName) then
		Remotes.Notify:FireClient(player, "Already Known", spell.DisplayName, spell.Color)
		return
	end

	local known = player:GetAttribute("KnownSpells")
	player:SetAttribute("KnownSpells", if known and known ~= "" then known .. "," .. spellName else spellName)
	if not player:GetAttribute("EquippedSpell") then
		player:SetAttribute("EquippedSpell", spellName)
	end
	Remotes.Notify:FireClient(player, "Spell Learned", spell.DisplayName, spell.Color)
end

local function anchoredPart(properties)
	local part = Instance.new("Part")
	part.Anchored = true
	for key, value in properties do
		part[key] = value
	end
	return part
end

local function createScroll(spellName, groundPosition)
	local spell = Config.Spells[spellName]

	local model = Instance.new("Model")
	model.Name = spell.DisplayName .. " Scroll"

	local pedestal = anchoredPart({
		Name = "Pedestal",
		Size = Vector3.new(3, 3, 3),
		Position = groundPosition + Vector3.new(0, 1.5, 0),
		Color = Color3.fromRGB(60, 58, 62),
		Material = Enum.Material.Slate,
		Parent = model,
	})

	local scrollCFrame = pedestal.CFrame * CFrame.new(0, 3, 0)
	local scroll = anchoredPart({
		Name = "Scroll",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.4, 0.6, 0.6),
		CFrame = scrollCFrame,
		Color = Color3.fromRGB(225, 205, 160),
		Material = Enum.Material.Fabric,
		CanCollide = false,
		Parent = model,
	})
	anchoredPart({
		Name = "Seal",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 0.68, 0.68),
		CFrame = scrollCFrame,
		Color = spell.Color,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = model,
	})

	local light = Instance.new("PointLight")
	light.Color = spell.Color
	light.Range = 10
	light.Brightness = 2
	light.Parent = scroll

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Read"
	prompt.ObjectText = spell.DisplayName .. " Scroll"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = pedestal
	prompt.Triggered:Connect(function(player)
		learn(player, spellName)
	end)

	model.PrimaryPart = pedestal
	CollectionService:AddTag(model, "SpellScroll")
	model.Parent = workspace
end

function Scrolls.start()
	local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local origin = if spawnLocation then spawnLocation.Position else Vector3.zero

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = CollectionService:GetTagged("Targetable")

	local count = #Config.SpellOrder
	for i, spellName in Config.SpellOrder do
		local offset = (i - (count + 1) / 2) * SPACING
		local position = origin + OFFSET_FROM_SPAWN + Vector3.new(0, 0, offset)
		local result = workspace:Raycast(position + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0), params)
		createScroll(spellName, if result then result.Position else position)
	end
end

return Scrolls
