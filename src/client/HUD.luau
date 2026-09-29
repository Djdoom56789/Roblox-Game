-- Health, mana, and stamina bars (top-left) and the equipped spell slot (bottom-left).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local SpellBook = require(Shared.SpellBook)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local HUD = {}

local FILL_TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
local CHIP_TWEEN = TweenInfo.new(0.45, Enum.EasingStyle.Quad)
local CHIP_DELAY = 0.45

-- A bar with a trailing "chip" that shows recently lost value, like Elden Ring.
local function makeBar(parent, order, width, color, labelText)
	local back = UI.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(width, 14),
		BackgroundColor3 = UI.Colors.Panel,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Parent = parent,
	}, { UI.stroke(UI.Colors.Border, 1.5) })

	local chip = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UI.Colors.Chip,
		BorderSizePixel = 0,
		Parent = back,
	})
	local fill = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = back,
	}, {
		UI.new("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)),
			Rotation = 90,
		}),
	})
	UI.label({
		Text = labelText,
		FontFace = UI.TitleFont,
		TextSize = 13,
		TextColor3 = UI.Colors.Text,
		TextTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(6, 0),
		Size = UDim2.new(1, -6, 1, 0),
		ZIndex = 3,
		Parent = back,
	})

	local bar = { fill = fill, chip = chip, ratio = 1, token = 0 }

	function bar.set(value, maxValue)
		local ratio = if maxValue > 0 then math.clamp(value / maxValue, 0, 1) else 0
		local previous = bar.ratio
		bar.ratio = ratio
		TweenService:Create(fill, FILL_TWEEN, { Size = UDim2.fromScale(ratio, 1) }):Play()

		if ratio >= previous then
			chip.Size = UDim2.fromScale(ratio, 1)
			return
		end
		bar.token += 1
		local token = bar.token
		task.delay(CHIP_DELAY, function()
			if bar.token == token then
				TweenService:Create(chip, CHIP_TWEEN, { Size = UDim2.fromScale(bar.ratio, 1) }):Play()
			end
		end)
	end

	return bar
end

local function bindAttributeBar(bar, resource)
	local function update()
		bar.set(player:GetAttribute(resource) or 0, player:GetAttribute("Max" .. resource) or 0)
	end
	player:GetAttributeChangedSignal(resource):Connect(update)
	player:GetAttributeChangedSignal("Max" .. resource):Connect(update)
	update()
end

local function makeSpellSlot(gui)
	local root = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 24, 1, -24),
		Size = UDim2.fromOffset(320, 84),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	local slot = UI.new("Frame", {
		Size = UDim2.fromOffset(84, 84),
		BackgroundColor3 = UI.Colors.Panel,
		BackgroundTransparency = 0.1,
		Parent = root,
	}, { UI.corner(UDim.new(0, 6)), UI.stroke(UI.Colors.Border, 2) })
	local scale = UI.new("UIScale", { Parent = slot })

	local icon = UI.label({
		Text = "",
		FontFace = UI.TitleFont,
		TextSize = 44,
		Size = UDim2.fromScale(1, 1),
		Parent = slot,
	})
	local cooldown = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = slot,
	}, { UI.corner(UDim.new(0, 6)) })
	local cooldownText = UI.label({
		Text = "",
		FontFace = UI.TitleFont,
		TextSize = 26,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
		Parent = slot,
	})

	local name = UI.label({
		FontFace = UI.TitleFont,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(98, 6),
		Size = UDim2.fromOffset(220, 28),
		Parent = root,
	})
	local detail = UI.label({
		TextSize = 13,
		TextColor3 = UI.Colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(98, 36),
		Size = UDim2.fromOffset(220, 18),
		Parent = root,
	})
	UI.label({
		Text = "[E] Cast   [Hold G] Spells   [1-4] Quick equip",
		TextSize = 12,
		TextColor3 = UI.Colors.Muted,
		TextTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(98, 58),
		Size = UDim2.fromOffset(260, 18),
		Parent = root,
	})

	local function refresh()
		local spellName = player:GetAttribute("EquippedSpell")
		local spell = spellName and Config.Spells[spellName]
		if not spell then
			icon.Text = "–"
			icon.TextColor3 = UI.Colors.Muted
			name.Text = "No spell"
			detail.Text = "Read a spell scroll to learn magic"
			return
		end
		icon.Text = spell.Icon
		icon.TextColor3 = spell.Color
		name.Text = spell.DisplayName
		detail.Text = spell.Mana .. " mana"
		scale.Scale = 1.15
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	player:GetAttributeChangedSignal("EquippedSpell"):Connect(refresh)
	refresh()

	RunService.RenderStepped:Connect(function()
		local spellName = player:GetAttribute("EquippedSpell")
		local spell = spellName and Config.Spells[spellName]
		if not spell then
			cooldown.Size = UDim2.fromScale(1, 0)
			cooldownText.Text = ""
			return
		end
		local remaining = SpellBook.getCooldownRemaining(player, spellName)
		cooldown.Size = UDim2.fromScale(1, math.clamp(remaining / spell.Cooldown, 0, 1))
		cooldownText.Text = if remaining > 0.95 then tostring(math.ceil(remaining)) else ""
		local enoughMana = (player:GetAttribute("Mana") or 0) >= spell.Mana
		icon.TextTransparency = if enoughMana then 0 else 0.6
	end)
end

function HUD.start()
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Health, false)

	local gui = UI.new("ScreenGui", {
		Name = "CombatHUD",
		ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	})

	local bars = UI.new("Frame", {
		Position = UDim2.fromOffset(24, 20),
		Size = UDim2.fromOffset(340, 60),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local health = makeBar(bars, 1, 320, UI.Colors.Health, "HP")
	local mana = makeBar(bars, 2, 260, UI.Colors.Mana, "MP")
	local stamina = makeBar(bars, 3, 240, UI.Colors.Stamina, "ST")

	bindAttributeBar(mana, "Mana")
	bindAttributeBar(stamina, "Stamina")

	local function bindCharacter(character)
		local humanoid = character:WaitForChild("Humanoid")
		local function update()
			health.set(humanoid.Health, humanoid.MaxHealth)
		end
		humanoid.HealthChanged:Connect(update)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
		update()
	end
	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		task.spawn(bindCharacter, player.Character)
	end

	makeSpellSlot(gui)
end

return HUD
