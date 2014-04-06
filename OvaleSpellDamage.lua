--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- Add-on that registers how many damage made the last spell cast by the player

local _, Ovale = ...
local OvaleSpellDamage = Ovale:NewModule("OvaleSpellDamage", "AceEvent-3.0")
Ovale.OvaleSpellDamage = OvaleSpellDamage

--<private-static-properties>
local API_UnitGUID = UnitGUID

local CLEU_DAMAGE_EVENT = {
	SPELL_DAMAGE = true,
	SPELL_PERIODIC_AURA = true,
}

-- Player's GUID.
local self_guid = nil
--</private-static-properties>

--<public-static-properties>
OvaleSpellDamage.value = {}
--</public-static-properties>

--<public-static-methods>
function OvaleSpellDamage:OnEnable()
	self_guid = API_UnitGUID("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function OvaleSpellDamage:OnDisable()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function OvaleSpellDamage:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23 = ...

	if sourceGUID == self_guid then
		if CLEU_DAMAGE_EVENT[cleuEvent] then
			local spellId, amount = arg12, arg15
			self.value[spellId] = amount
		end
	end
end

function OvaleSpellDamage:Get(spellId)
	return self.value[spellId]
end
--</public-static-methods>
