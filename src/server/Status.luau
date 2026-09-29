-- Tracks per-character action state (busy, staggered, invulnerable) on the server.
-- Busy and Staggered are mirrored to attributes on the model so clients can read them.
local Status = {}

local states = setmetatable({}, { __mode = "k" })

local function get(model)
	local state = states[model]
	if not state then
		state = {
			baseSpeed = 16,
			busySpeed = 0,
			busyUntil = 0,
			staggerUntil = 0,
			invulnerableUntil = 0,
			actionId = 0,
		}
		states[model] = state
	end
	return state
end

local function refresh(model)
	local state = get(model)
	local now = os.clock()
	local staggered = now < state.staggerUntil
	local busy = now < state.busyUntil

	model:SetAttribute("Staggered", staggered)
	model:SetAttribute("Busy", busy)

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = if staggered then 0 elseif busy then state.busySpeed else state.baseSpeed
	end
end

local function refreshAfter(model, duration)
	task.delay(duration + 0.02, refresh, model)
end

function Status.setBaseSpeed(model, speed)
	get(model).baseSpeed = speed
	refresh(model)
end

-- Starts an action that locks the character for `duration`. Returns an id that stops
-- being current if the action is interrupted.
function Status.startAction(model, duration, moveSpeed)
	local state = get(model)
	state.actionId += 1
	state.busyUntil = os.clock() + duration
	state.busySpeed = moveSpeed
	refresh(model)
	refreshAfter(model, duration)
	return state.actionId
end

function Status.isCurrentAction(model, actionId)
	return get(model).actionId == actionId and not Status.isStaggered(model)
end

function Status.isBusy(model)
	return os.clock() < get(model).busyUntil
end

function Status.isStaggered(model)
	return os.clock() < get(model).staggerUntil
end

function Status.stagger(model, duration)
	local state = get(model)
	state.actionId += 1
	state.busyUntil = 0
	state.staggerUntil = math.max(state.staggerUntil, os.clock() + duration)
	refresh(model)
	refreshAfter(model, duration)
end

function Status.setInvulnerable(model, duration)
	get(model).invulnerableUntil = os.clock() + duration
end

function Status.isInvulnerable(model)
	return os.clock() < get(model).invulnerableUntil
end

return Status
