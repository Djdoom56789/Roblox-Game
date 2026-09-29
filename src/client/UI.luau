-- Shared styling helpers for the game's UI.
local UI = {}

UI.Colors = {
	Panel = Color3.fromRGB(14, 12, 12),
	Border = Color3.fromRGB(120, 100, 60),
	Gold = Color3.fromRGB(215, 190, 130),
	Text = Color3.fromRGB(235, 228, 210),
	Muted = Color3.fromRGB(150, 142, 128),
	Health = Color3.fromRGB(165, 28, 28),
	Mana = Color3.fromRGB(52, 92, 205),
	Stamina = Color3.fromRGB(52, 142, 70),
	Chip = Color3.fromRGB(235, 205, 120),
}

UI.TitleFont = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Regular)
UI.BodyFont = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Regular)

function UI.new(className, properties, children)
	local instance = Instance.new(className)
	for key, value in properties or {} do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	if properties and properties.Parent then
		instance.Parent = properties.Parent
	end
	return instance
end

function UI.corner(radius)
	return UI.new("UICorner", { CornerRadius = radius or UDim.new(0, 4) })
end

function UI.stroke(color, thickness, transparency)
	return UI.new("UIStroke", {
		Color = color or UI.Colors.Border,
		Thickness = thickness or 1.5,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function UI.label(properties)
	properties.BackgroundTransparency = 1
	properties.FontFace = properties.FontFace or UI.BodyFont
	properties.TextColor3 = properties.TextColor3 or UI.Colors.Text
	return UI.new("TextLabel", properties)
end

return UI
