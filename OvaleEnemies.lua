-- Gather information about ennemies

OvaleEnemies = LibStub("AceAddon-3.0"):NewAddon("OvaleEnemies", "AceEvent-3.0")

--<public-static-properties>
OvaleEnemies.numberOfEnemies = 0
OvaleEnemies.enemies = {}
--</public-static-properties>

--<public-static-methods>
-- Events
function OvaleEnemies:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function OvaleEnemies:OnDisable()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
end

function OvaleEnemies:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local time, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)

	if event == "UNIT_DIED" then
		for k,v in pairs(self.enemies) do
			if k==destGUID then
				self.enemies[v] = nil
				self.numberOfEnemies = self.numberOfEnemies - 1
				Ovale.refreshNeeded["player"] = true
				--Ovale:Print("enemy die")
			end
		end
	elseif sourceFlags and not self.enemies[sourceGUID] and bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE)>0 
				and bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0 and
			destFlags and bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
		self.enemies[sourceGUID] = true
		--Ovale:Print("new ennemy source=".. sourceName)
		self.numberOfEnemies = self.numberOfEnemies + 1
		Ovale.refreshNeeded["player"] = true
	elseif destGUID and not self.enemies[destGUID] and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE)>0 
				and bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0 and
			sourceFlags and bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
		self.enemies[destGUID] = true
		--Ovale:Print("new ennemy dest=".. destName)
		self.numberOfEnemies = self.numberOfEnemies + 1
		Ovale.refreshNeeded["player"] = true
	end
end

function OvaleEnemies:PLAYER_REGEN_DISABLED()
	if self.numberOfEnemies then
		self.numberOfEnemies = 0
		self.enemies = {}
	end
end

function OvaleEnemies:GetNumberOfEnemies()
	if not self.numberOfEnemies then
		self.numberOfEnemies = 0
	end
	return self.numberOfEnemies
end
--</public-static-methods>

