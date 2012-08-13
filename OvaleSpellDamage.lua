-- Add-on that registers how many damage made the last spell cast by the player

OvaleSpellDamage = LibStub("AceAddon-3.0"):NewAddon("OvaleSpellDamage", "AceEvent-3.0")

--<public-static-properties>
OvaleSpellDamage.value = {}
OvaleSpellDamage.playerGUID = nil
--</public-static-properties>

-- Events
--<public-static-methods>
function OvaleSpellDamage:OnEnable()
	self.playerGUID = UnitGUID("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function OvaleSpellDamage:OnDisable()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function OvaleSpellDamage:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local time, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)

	if sourceGUID == self.playerGUID then
		if string.find(event, "SPELL_PERIODIC_DAMAGE")==1 or string.find(event, "SPELL_DAMAGE")==1 then
			local spellId, spellName, spellSchool, amount = select(12, ...)
			self.value[spellId] = amount
		end
	end
end

function OvaleSpellDamage:Get(spellId)
	return self.value[spellId]
end
--</public-static-methods>
