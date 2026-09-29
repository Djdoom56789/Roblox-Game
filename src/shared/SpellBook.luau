-- Reads a player's known spells and cooldowns from the attributes the server sets.
local Config = require(script.Parent.Config)

local SpellBook = {}

-- Returns known spell names in Config.SpellOrder order.
function SpellBook.getKnown(player)
	local known = {}
	for name in string.gmatch(player:GetAttribute("KnownSpells") or "", "[^,]+") do
		known[name] = true
	end
	local list = {}
	for _, name in Config.SpellOrder do
		if known[name] then
			table.insert(list, name)
		end
	end
	return list
end

function SpellBook.knows(player, spellName)
	return table.find(SpellBook.getKnown(player), spellName) ~= nil
end

function SpellBook.getCooldownRemaining(player, spellName)
	local readyAt = player:GetAttribute("Cooldown_" .. spellName)
	if not readyAt then
		return 0
	end
	return math.max(0, readyAt - workspace:GetServerTimeNow())
end

return SpellBook
