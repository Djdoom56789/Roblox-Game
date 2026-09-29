-- Spell effects. CombatService validates mana, cooldowns, and cast time, then calls
-- Magic.cast once the cast finishes.
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local Damage = require(script.Parent.Damage)
local Status = require(script.Parent.Status)
local Targeting = require(script.Parent.Targeting)

local Magic = {}

local effectsFolder = Instance.new("Folder")
effectsFolder.Name = "SpellEffects"
effectsFolder.Parent = workspace

local function effectPart(properties)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	for key, value in properties do
		part[key] = value
	end
	part.Parent = effectsFolder
	return part
end

local function fade(part, duration, goal)
	goal = goal or {}
	goal.Transparency = 1
	TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
	Debris:AddItem(part, duration)
end

local function flash(position, color, size)
	local sphere = effectPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * (size * 0.3),
		Position = position,
		Color = color,
		Transparency = 0.2,
	})
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = size * 2
	light.Brightness = 4
	light.Parent = sphere
	fade(sphere, 0.35, { Size = Vector3.one * size })
end

-- Excludes characters and effects so ground checks land on the map.
local function worldParams(extra)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = CollectionService:GetTagged("Targetable")
	table.insert(exclude, effectsFolder)
	if extra then
		table.insert(exclude, extra)
	end
	params.FilterDescendantsInstances = exclude
	return params
end

local function groundPoint(position)
	local result = workspace:Raycast(position + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0), worldParams())
	return if result then result.Position else position
end

local function clampToRange(origin, point, range)
	local offset = point - origin
	if offset.Magnitude > range then
		return origin + offset.Unit * range
	end
	return point
end

local function damageArea(caster, position, radius, spell)
	local hitAny = false
	for target in Targeting.inRadius(caster, position, radius) do
		if Damage.apply(target, spell.Damage, spell.PoiseDamage) then
			hitAny = true
		end
	end
	return hitAny
end

local spells = {}

function spells.Zoltraak(caster, root, aimPoint, spell, onHit)
	local origin = root.Position + Vector3.new(0, 1.5, 0) + root.CFrame.LookVector * 1.5
	local direction = aimPoint - origin
	if direction.Magnitude < 1 then
		direction = root.CFrame.LookVector
	end
	direction = direction.Unit * spell.Range

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { caster, effectsFolder }

	local result = workspace:Spherecast(origin, 1, direction, params)
	local endPoint = if result then result.Position else origin + direction
	if result then
		local target = Targeting.getModel(result.Instance)
		if target and Targeting.canHit(caster, target) and Damage.apply(target, spell.Damage, spell.PoiseDamage) then
			onHit(0.5)
		end
	end

	local length = (endPoint - origin).Magnitude
	local beam = effectPart({
		Size = Vector3.new(0.7, 0.7, length),
		CFrame = CFrame.lookAt(origin, endPoint) * CFrame.new(0, 0, -length / 2),
		Color = spell.Color,
		Transparency = 0.1,
	})
	fade(beam, 0.3, { Size = Vector3.new(0.05, 0.05, length) })
	flash(origin, spell.Color, 3)
	flash(endPoint, spell.Color, 5)
end

function spells.Judradjim(caster, root, aimPoint, spell, onHit)
	local target = groundPoint(clampToRange(root.Position, aimPoint, spell.Range))

	local ring = effectPart({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, spell.Radius * 2, spell.Radius * 2),
		CFrame = CFrame.new(target) * CFrame.Angles(0, 0, math.rad(90)),
		Color = spell.Color,
		Transparency = 0.8,
	})
	TweenService:Create(ring, TweenInfo.new(spell.Delay), { Transparency = 0.35 }):Play()

	task.delay(spell.Delay, function()
		ring:Destroy()
		local bolt = effectPart({
			Size = Vector3.new(1.5, 80, 1.5),
			Position = target + Vector3.new(0, 40, 0),
			Color = Color3.fromRGB(255, 250, 220),
		})
		fade(bolt, 0.4, { Size = Vector3.new(0.1, 80, 0.1) })
		flash(target, spell.Color, spell.Radius * 2)
		if damageArea(caster, target, spell.Radius, spell) then
			onHit(0.9)
		end
	end)
end

function spells.Catastravia(caster, root, aimPoint, spell, onHit)
	local center = groundPoint(clampToRange(root.Position, aimPoint, spell.Range))
	local random = Random.new()

	for i = 1, spell.Arrows do
		task.delay((i - 1) * spell.Duration / spell.Arrows, function()
			local angle = random:NextNumber(0, math.pi * 2)
			local distance = math.sqrt(random:NextNumber()) * spell.Radius
			local landing = groundPoint(center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance))
			local start = landing + Vector3.new(random:NextNumber(-8, 8), 45, random:NextNumber(-8, 8))

			local arrow = effectPart({
				Size = Vector3.new(0.3, 0.3, 5),
				CFrame = CFrame.lookAt(start, landing),
				Color = spell.Color,
			})
			local fall = TweenService:Create(arrow, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
				CFrame = CFrame.lookAt(landing, landing + (landing - start)),
			})
			fall:Play()
			fall.Completed:Once(function()
				arrow:Destroy()
				flash(landing, spell.Color, spell.ArrowRadius * 2)
				if damageArea(caster, landing, spell.ArrowRadius, spell) then
					onHit(0.3)
				end
			end)
		end)
	end
end

function spells.Barrier(caster, root, _aimPoint, spell)
	Status.setInvulnerable(caster, spell.Duration)

	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.one * 9
	sphere.Material = Enum.Material.ForceField
	sphere.Color = spell.Color
	sphere.CanCollide = false
	sphere.CanQuery = false
	sphere.CanTouch = false
	sphere.Massless = true
	sphere.CastShadow = false
	sphere.CFrame = root.CFrame

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = sphere
	weld.Parent = sphere
	sphere.Parent = caster
	Debris:AddItem(sphere, spell.Duration)
end

function Magic.cast(spellName, caster, root, aimPoint, onHit)
	local effect = spells[spellName]
	if effect then
		effect(caster, root, aimPoint, Config.Spells[spellName], onHit)
	end
end

return Magic
