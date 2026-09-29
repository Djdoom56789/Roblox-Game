-- Center-screen banners ("Spell Learned") and the death screen.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local Notifications = {}

local gui

-- A dark band across the screen that fades at the edges.
local function makeBand(height, positionY)
	local band = UI.new("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, positionY),
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Parent = gui,
	}, {
		UI.new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, 0),
				NumberSequenceKeypoint.new(0.7, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
	return band
end

local function fadeTo(band, transparency, duration)
	local tween = TweenService:Create(band, TweenInfo.new(duration, Enum.EasingStyle.Sine), {
		GroupTransparency = transparency,
	})
	tween:Play()
	return tween
end

function Notifications.banner(title, subtitle, color)
	local band = makeBand(120, 0.3)
	UI.label({
		Text = string.upper(title),
		FontFace = UI.TitleFont,
		TextSize = 22,
		TextColor3 = UI.Colors.Gold,
		Position = UDim2.fromScale(0, 0.12),
		Size = UDim2.new(1, 0, 0, 30),
		Parent = band,
	})
	UI.label({
		Text = subtitle,
		FontFace = UI.TitleFont,
		TextSize = 48,
		TextColor3 = color or UI.Colors.Text,
		Position = UDim2.fromScale(0, 0.4),
		Size = UDim2.new(1, 0, 0, 56),
		Parent = band,
	})

	fadeTo(band, 0, 0.4)
	task.delay(2.4, function()
		fadeTo(band, 1, 0.7).Completed:Once(function()
			band:Destroy()
		end)
	end)
end

local function showDeathScreen()
	local band = makeBand(160, 0.5)
	band.Name = "DeathScreen"
	UI.label({
		Text = "YOU DIED",
		FontFace = UI.TitleFont,
		TextSize = 84,
		TextColor3 = Color3.fromRGB(170, 25, 25),
		Size = UDim2.fromScale(1, 1),
		Parent = band,
	})
	fadeTo(band, 0, 1.5)
end

local function bindCharacter(character)
	local existing = gui:FindFirstChild("DeathScreen")
	if existing then
		existing:Destroy()
	end
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(showDeathScreen)
end

function Notifications.start()
	gui = UI.new("ScreenGui", {
		Name = "Notifications",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,
		Parent = player:WaitForChild("PlayerGui"),
	})

	Remotes.Notify.OnClientEvent:Connect(Notifications.banner)

	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		task.spawn(bindCharacter, player.Character)
	end
end

return Notifications
