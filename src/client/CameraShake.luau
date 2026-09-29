-- Small camera shake for hit feedback. Runs after the camera updates each frame.
local RunService = game:GetService("RunService")

local CameraShake = {}

local MAX_OFFSET = 0.35
local MAX_ROTATION = math.rad(1.2)
local DECAY_PER_SECOND = 4

local intensity = 0
local random = Random.new()

function CameraShake.shake(amount)
	intensity = math.max(intensity, amount)
end

function CameraShake.start()
	RunService:BindToRenderStep("CameraShake", Enum.RenderPriority.Camera.Value + 2, function(deltaTime)
		if intensity <= 0 then
			return
		end
		local camera = workspace.CurrentCamera
		local function jitter()
			return random:NextNumber(-1, 1) * intensity
		end
		camera.CFrame *= CFrame.new(jitter() * MAX_OFFSET, jitter() * MAX_OFFSET, 0)
			* CFrame.Angles(jitter() * MAX_ROTATION, jitter() * MAX_ROTATION, 0)
		intensity = math.max(0, intensity - DECAY_PER_SECOND * deltaTime)
	end)
end

return CameraShake
