-- Gives characters a placeholder greatsword. Clients animate it (see client/Animations).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local Weapon = {}

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

	local length = Config.Weapon.Length
	local blade = Instance.new("Part")
	blade.Name = "Greatsword"
	blade.Size = Vector3.new(0.3, 1.2, length)
	blade.Color = Color3.fromRGB(58, 56, 60)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.CanQuery = false
	blade.CanTouch = false
	blade.Massless = true

	local hilt = Instance.new("Part")
	hilt.Name = "Hilt"
	hilt.Size = Vector3.new(0.4, 1.8, 0.3)
	hilt.Color = Color3.fromRGB(40, 30, 24)
	hilt.Material = Enum.Material.Wood
	hilt.CanCollide = false
	hilt.CanQuery = false
	hilt.CanTouch = false
	hilt.Massless = true
	hilt.CFrame = blade.CFrame * CFrame.new(0, 0, length / 2 - 1.2)

	local hiltWeld = Instance.new("WeldConstraint")
	hiltWeld.Part0 = blade
	hiltWeld.Part1 = hilt
	hiltWeld.Parent = hilt
	hilt.Parent = blade

	local grip = Instance.new("Weld")
	grip.Name = "Grip"
	grip.Part0 = hand
	grip.Part1 = blade
	grip.C0 = Config.Weapon.GripOffset * CFrame.Angles(math.rad(Config.Weapon.RestAngle), 0, 0)
	grip.C1 = CFrame.new(0, 0, length / 2 - 0.6)
	grip.Parent = blade

	blade.Parent = character
end

return Weapon
