-- Procedural animations built by tweening R15 joints and the greatsword grip.
-- The server sets an "Action" attribute ("<animation>#<id>") on a character when it
-- starts an action, and every client plays the matching animation locally.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local Animations = {}

local baseC0 = setmetatable({}, { __mode = "k" })
local playTokens = setmetatable({}, { __mode = "k" })

-- Poses give joint rotations in degrees as { x, y, z }, plus a blade pitch for Sword.
-- Shoulders: +x raises the arm forward, +z swings the right arm out (left arm in).
-- Waist: -x leans forward, +y twists left. Joints left out of a pose return to rest.
local function attack(windup, strike, timing)
	return {
		{ at = 0, duration = timing.Windup, pose = windup, style = Enum.EasingStyle.Quad },
		{ at = timing.Windup, duration = timing.Active, pose = strike, style = Enum.EasingStyle.Quart },
		{ at = timing.Windup + timing.Active, duration = timing.Recovery, pose = {}, style = Enum.EasingStyle.Sine },
	}
end

local function cast(raised, spell, release)
	local keyframes = {
		{ at = 0, duration = spell.CastTime, pose = raised, style = Enum.EasingStyle.Quad },
	}
	if release then
		table.insert(keyframes, { at = spell.CastTime, duration = 0.12, pose = release, style = Enum.EasingStyle.Quart })
	end
	table.insert(keyframes, {
		at = spell.CastTime + spell.Recovery * 0.5,
		duration = spell.Recovery * 0.5 + 0.1,
		pose = {},
		style = Enum.EasingStyle.Sine,
	})
	return keyframes
end

local function buildAnimations()
	local light = Config.Attacks.Light
	local heavy = Config.Attacks.Heavy
	local dodge = Config.Dodge
	local spells = Config.Spells

	return {
		Light1 = attack(
			{ RightShoulder = { 150, 0, 20 }, LeftShoulder = { 40, 0, 0 }, Waist = { 8, -25, 0 }, Sword = 60 },
			{ RightShoulder = { 30, 0, -10 }, LeftShoulder = { 20, 0, 0 }, Waist = { -15, 25, 0 }, Sword = -75 },
			light
		),
		Light2 = attack(
			{ RightShoulder = { 90, 0, -60 }, Waist = { 0, 30, 0 }, Sword = 20 },
			{ RightShoulder = { 90, 0, 60 }, Waist = { -5, -30, 0 }, Sword = -10 },
			light
		),
		Light3 = attack(
			{ RightShoulder = { 170, 0, 0 }, LeftShoulder = { 160, 0, 0 }, Waist = { 10, 0, 0 }, Sword = 110 },
			{ RightShoulder = { 20, 0, 0 }, LeftShoulder = { 20, 0, 0 }, Waist = { -25, 0, 0 }, Sword = -80 },
			light
		),
		Heavy = attack(
			{ RightShoulder = { 175, 0, 0 }, LeftShoulder = { 165, 0, 0 }, Waist = { 15, -10, 0 }, Sword = 120 },
			{ RightShoulder = { -5, 0, 0 }, LeftShoulder = { -5, 0, 0 }, Waist = { -35, 0, 0 }, Sword = -90 },
			heavy
		),
		Dodge = {
			{
				at = 0,
				duration = 0.1,
				pose = { Waist = { -40, 0, 0 }, RightShoulder = { -30, 0, 0 }, LeftShoulder = { -30, 0, 0 } },
				style = Enum.EasingStyle.Quad,
			},
			{ at = dodge.Duration, duration = 0.2, pose = {}, style = Enum.EasingStyle.Sine },
		},
		Stagger = {
			{
				at = 0,
				duration = 0.12,
				pose = { Waist = { 22, 0, 0 }, RightShoulder = { -20, 0, 15 }, LeftShoulder = { -20, 0, -15 } },
				style = Enum.EasingStyle.Back,
			},
			{ at = Config.Poise.StaggerDuration - 0.25, duration = 0.25, pose = {}, style = Enum.EasingStyle.Sine },
		},
		["Cast:Zoltraak"] = cast({ LeftShoulder = { 90, 0, 0 }, Waist = { 0, -25, 0 } }, spells.Zoltraak),
		["Cast:Judradjim"] = cast(
			{ LeftShoulder = { 175, 0, 0 }, Waist = { 10, 0, 0 } },
			spells.Judradjim,
			{ LeftShoulder = { 95, 0, 0 }, Waist = { -10, 0, 0 } }
		),
		["Cast:Catastravia"] = cast(
			{ RightShoulder = { 160, 0, 25 }, LeftShoulder = { 160, 0, -25 }, Waist = { 12, 0, 0 } },
			spells.Catastravia
		),
		["Cast:Barrier"] = cast(
			{ RightShoulder = { 80, 0, 30 }, LeftShoulder = { 80, 0, -30 } },
			spells.Barrier
		),
	}
end

local ANIMATIONS = buildAnimations()

local function getJoints(model)
	local upperTorso = model:FindFirstChild("UpperTorso")
	local rightArm = model:FindFirstChild("RightUpperArm")
	local leftArm = model:FindFirstChild("LeftUpperArm")
	local sword = model:FindFirstChild("Greatsword")
	local joints = {
		Waist = upperTorso and upperTorso:FindFirstChild("Waist"),
		RightShoulder = rightArm and rightArm:FindFirstChild("RightShoulder"),
		LeftShoulder = leftArm and leftArm:FindFirstChild("LeftShoulder"),
		Sword = sword and sword:FindFirstChild("Grip"),
	}
	for name, joint in joints do
		if name ~= "Sword" and not baseC0[joint] then
			baseC0[joint] = joint.C0
		end
	end
	return joints
end

local function targetC0(joint, jointName, pose)
	if jointName == "Sword" then
		local pitch = pose or Config.Weapon.RestAngle
		return Config.Weapon.GripOffset * CFrame.Angles(math.rad(pitch), 0, 0)
	end
	local angles = pose or { 0, 0, 0 }
	return baseC0[joint] * CFrame.Angles(math.rad(angles[1]), math.rad(angles[2]), math.rad(angles[3]))
end

function Animations.play(model, animationName)
	local keyframes = ANIMATIONS[animationName]
	if not keyframes then
		return
	end

	local token = (playTokens[model] or 0) + 1
	playTokens[model] = token
	local joints = getJoints(model)

	for _, keyframe in keyframes do
		task.delay(keyframe.at, function()
			if playTokens[model] ~= token then
				return
			end
			local info = TweenInfo.new(math.max(keyframe.duration, 0.03), keyframe.style, Enum.EasingDirection.Out)
			for jointName, joint in joints do
				if joint.Parent then
					TweenService:Create(joint, info, { C0 = targetC0(joint, jointName, keyframe.pose[jointName]) }):Play()
				end
			end
		end)
	end
end

local function watchCharacter(model)
	model:GetAttributeChangedSignal("Action"):Connect(function()
		local name = string.match(model:GetAttribute("Action") or "", "^(.-)#")
		if name then
			Animations.play(model, name)
		end
	end)
end

-- Spell scrolls float and spin on their pedestals.
local scrolls = {}

local function watchScroll(model)
	local parts = {}
	for _, name in { "Scroll", "Seal" } do
		local part = model:WaitForChild(name, 10)
		if part then
			parts[part] = part.CFrame
		end
	end
	scrolls[model] = parts
end

local function animateScrolls()
	local t = os.clock()
	for model, parts in scrolls do
		if not model.Parent then
			scrolls[model] = nil
			continue
		end
		local offset = CFrame.new(0, math.sin(t * 2) * 0.3, 0) * CFrame.Angles(0, t * 0.8, 0)
		for part, base in parts do
			part.CFrame = CFrame.new(base.Position) * offset * base.Rotation
		end
	end
end

function Animations.start()
	CollectionService:GetInstanceAddedSignal("Targetable"):Connect(watchCharacter)
	for _, model in CollectionService:GetTagged("Targetable") do
		watchCharacter(model)
	end

	CollectionService:GetInstanceAddedSignal("SpellScroll"):Connect(function(model)
		task.spawn(watchScroll, model)
	end)
	for _, model in CollectionService:GetTagged("SpellScroll") do
		task.spawn(watchScroll, model)
	end
	RunService.RenderStepped:Connect(animateScrolls)
end

return Animations
