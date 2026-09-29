-- Radial spell wheel. Hold the wheel key, point toward a spell with the mouse or
-- stick (or click it), and release to equip it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local SpellBook = require(Shared.SpellBook)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local RADIUS = 160
local SLOT_SIZE = 88
local DEADZONE = 40
local OPEN_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE_TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
local HOVER_TWEEN = TweenInfo.new(0.1, Enum.EasingStyle.Quad)

local SpellWheel = {}

local gui, overlay, container, scale
local centerName, centerDescription, centerCost
local slots = {}
local isOpen = false
local hovered = nil
local stickDirection = Vector2.zero

function SpellWheel.isOpen()
	return isOpen
end

local function isWheelInput(input)
	for _, bind in Config.Keybinds.SpellWheel do
		if input.KeyCode == bind or input.UserInputType == bind then
			return true
		end
	end
	return false
end

local function setHovered(spellName)
	hovered = spellName
	local equipped = player:GetAttribute("EquippedSpell")

	for name, slot in slots do
		local active = name == spellName
		TweenService:Create(slot.button, HOVER_TWEEN, {
			Size = UDim2.fromOffset(if active then SLOT_SIZE + 16 else SLOT_SIZE, if active then SLOT_SIZE + 16 else SLOT_SIZE),
			BackgroundColor3 = if active then Color3.fromRGB(40, 34, 30) else UI.Colors.Panel,
		}):Play()
		slot.stroke.Thickness = if active then 3 else 1.5
		slot.stroke.Color = if active or name == equipped then Config.Spells[name].Color else UI.Colors.Border
	end

	local spell = spellName and Config.Spells[spellName]
	if spell then
		centerName.Text = spell.DisplayName
		centerName.TextColor3 = spell.Color
		centerDescription.Text = spell.Description
		centerCost.Text = spell.Mana .. " mana  ·  " .. spell.Cooldown .. "s"
	else
		centerName.Text = "No spells"
		centerName.TextColor3 = UI.Colors.Muted
		centerDescription.Text = "Find spell scrolls to learn magic."
		centerCost.Text = ""
	end
end

local function equip(spellName)
	if spellName and spellName ~= player:GetAttribute("EquippedSpell") then
		Remotes.CombatAction:FireServer("Equip", spellName)
	end
end

local function close(confirm)
	if not isOpen then
		return
	end
	isOpen = false
	if confirm then
		equip(hovered)
	end
	TweenService:Create(scale, CLOSE_TWEEN, { Scale = 0.85 }):Play()
	TweenService:Create(overlay, CLOSE_TWEEN, { BackgroundTransparency = 1 }):Play()
	task.delay(CLOSE_TWEEN.Time, function()
		if not isOpen then
			gui.Enabled = false
		end
	end)
end

local function rebuildSlots()
	for _, slot in slots do
		slot.button:Destroy()
	end
	slots = {}

	local known = SpellBook.getKnown(player)
	for i, spellName in known do
		local spell = Config.Spells[spellName]
		local angle = math.rad(-90 + (i - 1) * 360 / #known)
		local stroke = UI.stroke(UI.Colors.Border, 1.5)

		local button = UI.new("TextButton", {
			Text = "",
			AutoButtonColor = false,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.cos(angle) * RADIUS, 0.5, math.sin(angle) * RADIUS),
			Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
			BackgroundColor3 = UI.Colors.Panel,
			BackgroundTransparency = 0.05,
			Parent = container,
		}, { UI.corner(UDim.new(1, 0)), stroke })

		UI.label({
			Text = spell.Icon,
			FontFace = UI.TitleFont,
			TextSize = 40,
			TextColor3 = spell.Color,
			Size = UDim2.fromScale(1, 0.8),
			Parent = button,
		})
		UI.label({
			Text = tostring(i),
			TextSize = 12,
			TextColor3 = UI.Colors.Muted,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.fromOffset(20, 14),
			Parent = button,
		})

		button.MouseEnter:Connect(function()
			setHovered(spellName)
		end)
		button.Activated:Connect(function()
			hovered = spellName
			close(true)
		end)

		slots[spellName] = { button = button, stroke = stroke, angle = angle }
	end
end

local function open()
	if isOpen then
		return
	end
	isOpen = true
	stickDirection = Vector2.zero
	rebuildSlots()

	local equipped = player:GetAttribute("EquippedSpell")
	setHovered(if equipped and slots[equipped] then equipped else SpellBook.getKnown(player)[1])

	gui.Enabled = true
	scale.Scale = 0.85
	overlay.BackgroundTransparency = 1
	TweenService:Create(scale, OPEN_TWEEN, { Scale = 1 }):Play()
	TweenService:Create(overlay, OPEN_TWEEN, { BackgroundTransparency = 0.45 }):Play()
end

-- Picks the slot whose angle is closest to where the mouse or stick is pointing.
local function updatePointer()
	if not isOpen or next(slots) == nil then
		return
	end

	local direction = stickDirection
	if direction.Magnitude < 0.5 then
		local center = workspace.CurrentCamera.ViewportSize / 2
		direction = UserInputService:GetMouseLocation() - center
		if direction.Magnitude < DEADZONE then
			return
		end
	end

	local pointerAngle = math.atan2(direction.Y, direction.X)
	local best, bestDifference = nil, math.huge
	for name, slot in slots do
		local difference = math.abs(math.atan2(math.sin(pointerAngle - slot.angle), math.cos(pointerAngle - slot.angle)))
		if difference < bestDifference then
			best, bestDifference = name, difference
		end
	end
	if best ~= hovered then
		setHovered(best)
	end
end

local function build()
	gui = UI.new("ScreenGui", {
		Name = "SpellWheel",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 5,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})

	overlay = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Active = true, -- swallow clicks so they don't attack
		Parent = gui,
	})

	container = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(RADIUS * 2 + SLOT_SIZE, RADIUS * 2 + SLOT_SIZE),
		BackgroundTransparency = 1,
		Parent = overlay,
	})
	scale = UI.new("UIScale", { Parent = container })

	UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(RADIUS * 2, RADIUS * 2),
		BackgroundTransparency = 1,
		Parent = container,
	}, { UI.corner(UDim.new(1, 0)), UI.stroke(UI.Colors.Border, 1.5, 0.5) })

	local center = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(190, 190),
		BackgroundColor3 = UI.Colors.Panel,
		BackgroundTransparency = 0.1,
		Parent = container,
	}, { UI.corner(UDim.new(1, 0)), UI.stroke(UI.Colors.Border, 2) })

	centerName = UI.label({
		FontFace = UI.TitleFont,
		TextSize = 26,
		Position = UDim2.new(0, 16, 0, 34),
		Size = UDim2.new(1, -32, 0, 30),
		TextScaled = false,
		Parent = center,
	})
	centerDescription = UI.label({
		TextSize = 12,
		TextColor3 = UI.Colors.Text,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.new(0, 22, 0, 70),
		Size = UDim2.new(1, -44, 0, 64),
		Parent = center,
	})
	centerCost = UI.label({
		TextSize = 12,
		TextColor3 = UI.Colors.Mana,
		Position = UDim2.new(0, 16, 1, -44),
		Size = UDim2.new(1, -32, 0, 16),
		Parent = center,
	})
end

function SpellWheel.start()
	build()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and isWheelInput(input) then
			open()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isWheelInput(input) then
			close(true)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if isOpen and input.KeyCode == Enum.KeyCode.Thumbstick2 then
			stickDirection = Vector2.new(input.Position.X, -input.Position.Y)
		end
	end)

	RunService.RenderStepped:Connect(updatePointer)
	player.CharacterAdded:Connect(function()
		close(false)
	end)
end

return SpellWheel
