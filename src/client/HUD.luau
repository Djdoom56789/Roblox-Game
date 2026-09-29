-- Health and stamina bars in the top-left corner.
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

local HUD = {}

local function makeBar(parent, y, width, color)
	local back = Instance.new("Frame")
	back.Size = UDim2.fromOffset(width, 12)
	back.Position = UDim2.fromOffset(24, y)
	back.BackgroundColor3 = Color3.fromRGB(18, 16, 16)
	back.BorderSizePixel = 0
	back.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 100, 60)
	stroke.Thickness = 1
	stroke.Parent = back

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = back

	return fill
end

local function setFill(fill, value, maxValue)
	local ratio = if maxValue > 0 then math.clamp(value / maxValue, 0, 1) else 0
	fill.Size = UDim2.fromScale(ratio, 1)
end

function HUD.start()
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Health, false)

	local gui = Instance.new("ScreenGui")
	gui.Name = "CombatHUD"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local healthFill = makeBar(gui, 24, 320, Color3.fromRGB(150, 24, 24))
	local staminaFill = makeBar(gui, 44, 240, Color3.fromRGB(46, 130, 64))

	local function updateStamina()
		setFill(staminaFill, player:GetAttribute("Stamina") or 0, player:GetAttribute("MaxStamina") or 0)
	end
	player:GetAttributeChangedSignal("Stamina"):Connect(updateStamina)
	player:GetAttributeChangedSignal("MaxStamina"):Connect(updateStamina)
	updateStamina()

	local function bindCharacter(character)
		local humanoid = character:WaitForChild("Humanoid")
		local function updateHealth()
			setFill(healthFill, humanoid.Health, humanoid.MaxHealth)
		end
		humanoid.HealthChanged:Connect(updateHealth)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
		updateHealth()
	end
	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		task.spawn(bindCharacter, player.Character)
	end
end

return HUD
