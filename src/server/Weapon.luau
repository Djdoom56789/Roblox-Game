-- Gives characters a placeholder greatsword and swings it with simple weld tweens
-- until real animations are made.
local TweenService = game:GetService("TweenService")

local Weapon = {}

local BLADE_LENGTH = 7
local GRIP = CFrame.new(0, -0.25, 0)

-- Pitch of the blade relative to the hand, in degrees. Negative points the tip down.
local POSES = {
	Rest = -30,
	LightRaise = 60,
	HeavyRaise = 110,
	Strike = -75,
}

local function pose(degrees)
	return GRIP * CFrame.Angles(math.rad(degrees), 0, 0)
end

function Weapon.equip(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	local handName = if humanoid.RigType == Enum.HumanoidRigType.R15 then "RightHand" else "Right Arm"
	local hand = character:WaitForChild(handName, 10)
	if not hand then
		return
	end

	local blade = Instance.new("Part")
	blade.Name = "Greatsword"
	blade.Size = Vector3.new(0.3, 1.2, BLADE_LENGTH)
	blade.Color = Color3.fromRGB(58, 56, 60)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.CanQuery = false
	blade.CanTouch = false
	blade.Massless = true

	local weld = Instance.new("Weld")
	weld.Name = "Grip"
	weld.Part0 = hand
	weld.Part1 = blade
	weld.C0 = pose(POSES.Rest)
	weld.C1 = CFrame.new(0, 0, BLADE_LENGTH / 2 - 0.6)
	weld.Parent = blade

	blade.Parent = character
end

function Weapon.swing(character, kind, attack, isCurrent)
	local blade = character:FindFirstChild("Greatsword")
	local weld = blade and blade:FindFirstChild("Grip")
	if not weld then
		return
	end

	local function tweenTo(degrees, duration, style)
		TweenService:Create(weld, TweenInfo.new(duration, style), { C0 = pose(degrees) }):Play()
	end

	local raise = if kind == "Heavy" then POSES.HeavyRaise else POSES.LightRaise
	tweenTo(raise, attack.Windup, Enum.EasingStyle.Quad)

	task.delay(attack.Windup, function()
		if not isCurrent() then
			tweenTo(POSES.Rest, 0.2, Enum.EasingStyle.Quad)
			return
		end
		tweenTo(POSES.Strike, attack.Active, Enum.EasingStyle.Quart)
		task.delay(attack.Active, function()
			tweenTo(POSES.Rest, attack.Recovery, Enum.EasingStyle.Sine)
		end)
	end)
end

return Weapon
