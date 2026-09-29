-- Locks the camera and character onto the target closest to the center of the screen.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local player = Players.LocalPlayer

local LockOn = {}

local target = nil
local indicator = nil

local function getRoot(model)
	return model and model:FindFirstChild("HumanoidRootPart")
end

local function isAlive(model)
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function findTarget()
	local character = player.Character
	local root = getRoot(character)
	if not root then
		return nil
	end

	local camera = workspace.CurrentCamera
	local center = camera.ViewportSize / 2
	local best, bestScore = nil, math.huge

	for _, model in CollectionService:GetTagged("Targetable") do
		local targetRoot = getRoot(model)
		local isPlayer = Players:GetPlayerFromCharacter(model) ~= nil
		if model ~= character and targetRoot and isAlive(model) and (Config.Combat.PvP or not isPlayer) then
			local distance = (targetRoot.Position - root.Position).Magnitude
			local screenPoint, onScreen = camera:WorldToViewportPoint(targetRoot.Position)
			if onScreen and distance <= Config.LockOn.Range then
				local score = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude + distance * 2
				if score < bestScore then
					best, bestScore = model, score
				end
			end
		end
	end
	return best
end

local function makeIndicator(targetRoot)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(14, 14)
	billboard.AlwaysOnTop = true
	billboard.Adornee = targetRoot

	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromScale(1, 1)
	dot.BackgroundColor3 = Color3.fromRGB(235, 220, 180)
	dot.BorderSizePixel = 0
	dot.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = dot

	billboard.Parent = player:WaitForChild("PlayerGui")
	return billboard
end

function LockOn.unlock()
	target = nil
	if indicator then
		indicator:Destroy()
		indicator = nil
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = true
	end
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

function LockOn.lock(model)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	LockOn.unlock()
	target = model
	indicator = makeIndicator(getRoot(model))
	humanoid.AutoRotate = false
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
end

function LockOn.toggle()
	if target then
		LockOn.unlock()
		return
	end
	local model = findTarget()
	if model then
		LockOn.lock(model)
	end
end

function LockOn.getTarget()
	return target
end

local function update(deltaTime)
	if not target then
		return
	end

	local root = getRoot(player.Character)
	local targetRoot = getRoot(target)
	if not root or not targetRoot or not isAlive(player.Character) or not isAlive(target) then
		LockOn.unlock()
		return
	end

	local offset = targetRoot.Position - root.Position
	local flatOffset = Vector3.new(offset.X, 0, offset.Z)
	if offset.Magnitude > Config.LockOn.BreakRange then
		LockOn.unlock()
		return
	end
	if flatOffset.Magnitude < 0.1 then
		return
	end

	-- Keep the character facing the target.
	local direction = flatOffset.Unit
	root.CFrame = CFrame.lookAt(root.Position, root.Position + direction)

	-- Place the camera behind the character, looking between it and the target.
	local camera = workspace.CurrentCamera
	local cameraPosition = root.Position
		- direction * Config.LockOn.CameraDistance
		+ Vector3.new(0, Config.LockOn.CameraHeight, 0)
	local focus = (root.Position + targetRoot.Position) / 2
	local goal = CFrame.lookAt(cameraPosition, focus)
	camera.CFrame = camera.CFrame:Lerp(goal, math.min(1, deltaTime * 12))
end

function LockOn.start()
	RunService:BindToRenderStep("LockOn", Enum.RenderPriority.Camera.Value + 1, update)
	player.CharacterAdded:Connect(LockOn.unlock)
end

return LockOn
