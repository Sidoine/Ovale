-- The travelling missiles or spells that have been cast but whose effects were not still not applied

OvaleFuture = LibStub("AceAddon-3.0"):NewAddon("OvaleFuture", "AceEvent-3.0")

--<public-static-properties>
--spell counter (see Counter function)
OvaleFuture.counter = {}
--the spells that the player has casted but that did not reach their target
--the result is computed by the simulator, allowing to ignore lag or missile travel time
OvaleFuture.lastSpell = {}
--the attack power of the last spell
OvaleFuture.lastSpellAP = {}
OvaleFuture.lastSpellSP = {}
OvaleFuture.lastSpellDM = {}
OvaleFuture.playerGUID = nil
OvaleFuture.nextSpellTarget = nil
OvaleFuture.nextSpellLineID = nil
--</public-static-properties>

-- Events
--<public-static-methods>
function OvaleFuture:OnEnable()
	self.playerGUID = UnitGUID("player")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
end

function OvaleFuture:OnDisable()
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    self:UnregisterEvent("UNIT_SPELLCAST_START")
	self:UnregisterEvent("UNIT_SPELLCAST_SENT")
end


function OvaleFuture:UNIT_SPELLCAST_CHANNEL_START(event, unit, name, rank, lineId, spellId)
	if unit=="player" then
		--Ovale:Print("UNIT_SPELLCAST_CHANNEL_START "..event.." name="..name.." lineId="..lineId.." spellId="..spellId .. " " .. GetTime())
		local _,_,_,_,startTime, endTime = UnitChannelInfo("player")
		--Ovale:Print("startTime = " ..startTime.." endTime = "..endTime)
		self:AddSpellToList(spellId, lineId, startTime/1000, endTime/1000, true, false)
	end
end

function OvaleFuture:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		--Ovale:Print("UNIT_SPELLCAST_CHANNEL_STOP "..event.." name="..name.." lineId="..lineId.." spellId="..spellId)
		self:RemoveSpellFromList(spellId, lineId)
	end
end

--Called when a spell started its cast
function OvaleFuture:UNIT_SPELLCAST_START(event, unit, name, rank, lineId, spellId)
	--Ovale:Print("UNIT_SPELLCAST_START "..event.." name="..name.." lineId="..lineId.." spellId="..spellId .. " time=" .. GetTime())
	if unit=="player" then
		local _,_,_,_,startTime,endTime = UnitCastingInfo("player")
		--local spell, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellId)
		--local startTime =  GetTime()
		--self:AddSpellToList(spellId, lineId, startTime, startTime + castTime/1000)
		self:AddSpellToList(spellId, lineId, startTime/1000, endTime/1000, false, false)
	end
end

--Called if the player interrupted early his cast
--The spell is removed from the lastSpell table
function OvaleFuture:UNIT_SPELLCAST_INTERRUPTED(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		--Ovale:Print("UNIT_SPELLCAST_INTERRUPTED "..event.." name="..name.." lineId="..lineId.." spellId="..spellId.. " time="..GetTime())
		self:RemoveSpellFromList(spellId, lineId)
	end
end

function OvaleFuture:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target, lineId)
	if unit == "player" then
		local targetGUID = OvaleGUID.nameToGUID[target]
		self.nextSpellTarget = targetGUID
		self.nextSpellLineID = lineId
		--Ovale:Print(target)
		for i,v in ipairs(self.lastSpell) do
			if v.lineId == lineId then
				v.target = targetGUID
			end
		end
	end
end

function OvaleFuture:UNIT_SPELLCAST_SUCCEEDED(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		--Ovale:Print("UNIT_SPELLCAST_SUCCEEDED "..event.." name="..name.." lineId="..lineId.." spellId="..spellId.. " time="..GetTime())
		for i,v in ipairs(self.lastSpell) do
			if v.lineId == lineId then
				--Already added in UNIT_SPELLCAST_START
				v.allowRemove = true
				return
			end
		end
		if not UnitChannelInfo("player") then
			--A UNIT_SPELLCAST_SUCCEEDED is received when channeling a spell, with a different lineId!
			local now = GetTime()
			self:AddSpellToList(spellId, lineId, now, now, false, true)
		end
	end
end

function OvaleFuture:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local time, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)

	--[[
	Sequence of events:
	- casting a spell that damages
	SPELL_CAST_START
	SPELL_DAMAGE
	- casting a spell that misses
	SPELL_CAST_START
	SPELL_MISSED
	- casting a spell then interrupting it
	SPELL_CAST_START
	SPELL_CAST_FAILED
	- casting an instant damaging spell
	SPELL_CAST_SUCCESS
	SPELL_DAMAGE
	- chanelling a damaging spell
	SPELL_CAST_SUCCESS
	SPELL_AURA_APPLIED
	SPELL_PERIODIC_DAMAGE
	SPELL_PERIODIC_DAMAGE
	SPELL_PERIODIC_DAMAGE
	(interruption does not generate an event)
	- refreshing a buff
	SPELL_AURA_REFRESH
	SPELL_CAST_SUCCESS
	- removing a buff
	SPELL_AURA_REMOVED
	- casting a buff
	SPELL_AURA_APPLIED
	SPELL_CAST_SUCCESS
	-casting a DOT that misses
	SPELL_CAST_SUCCESS
	SPELL_MISSED
	- casting a DOT that damages
	SPELL_CAST_SUCESS
	SPELL_AURA_APPLIED
	SPELL_PERIODIC_DAMAGE
	SPELL_PERIODIC_DAMAGE]]
	
	if sourceGUID == self.playerGUID then
		--Called when a missile reached or missed its target
		--Update lastSpell accordingly
		--Do not use SPELL_CAST_SUCCESS because it is sent when the missile has not reached the target
		
			--Ovale:Print("SPELL_CAST_START " .. GetTime())
		--if string.find(event, "SPELL") == 1 then
		--	local spellId, spellName = select(12, ...)
		--	Ovale:Print(event .. " " ..spellName .. " " ..GetTime())
		--end
			-- local spellId, spellName = select(12, ...)
			-- for i,v in ipairs(self.lastSpell) do
			
			-- end
		--end
		
		if 
				string.find(event, "SPELL_AURA_APPLIED")==1
				or string.find(event, "SPELL_AURA_REFRESH")==1
				or string.find(event, "SPELL_DAMAGE")==1 
				or string.find(event, "SPELL_MISSED") == 1 
				or string.find(event, "SPELL_CAST_SUCCESS") == 1
				or string.find(event, "SPELL_CAST_FAILED") == 1 then
			local spellId, spellName = select(12, ...)
			for i,v in ipairs(self.lastSpell) do
				if (v.spellId == spellId or v.auraSpellId == spellId) and v.allowRemove then
					if not v.channeled and (v.removeOnSuccess or 
								string.find(event, "SPELL_CAST_SUCCESS") ~= 1) then
						table.remove(self.lastSpell, i)
						Ovale.refreshNeeded["player"] = true
						--Ovale:Print("LOG_EVENT on supprime "..spellId.." a "..GetTime())
					end
					--Ovale:Print(UnitDebuff("target", "Etreinte de l'ombre"))
					break
				end
			end
		end
	end

end

function OvaleFuture:AddSpellToList(spellId, lineId, startTime, endTime, channeled, allowRemove)
	local newSpell = {}
	newSpell.spellId = spellId
	newSpell.lineId = lineId
	newSpell.start = startTime
	newSpell.stop = endTime
	newSpell.channeled = channeled
	newSpell.allowRemove = allowRemove
	--TODO unable to know what is the real target
	if lineId == self.nextSpellLineID and self.nextSpellTarget then
		newSpell.target = self.nextSpellTarget
	else
		newSpell.target = UnitGUID("target")
	end
		
	self.lastSpellAP[spellId] = UnitAttackPower("player")
	self.lastSpellSP[spellId] = GetSpellBonusDamage(2)
	self.lastSpellDM[spellId] = OvaleAura.damageMultiplier
	self.lastSpell[#self.lastSpell+1] = newSpell
	--Ovale:Print("on ajoute "..spellId..": ".. newSpell.start.." to "..newSpell.stop.." ("..OvaleState.maintenant..")" ..#self.lastSpell .. " " ..newSpell.target)
	
	if OvaleData.spellInfo[spellId] then
		local si = OvaleData.spellInfo[spellId]
		
		if si.aura then
			for target, targetInfo in pairs(si.aura) do
				for filter, filterInfo in pairs(targetInfo) do
					for auraSpellId, spellData in pairs(filterInfo) do
						if spellData and spellData ~= "refresh" and spellData > 0 then
							newSpell.auraSpellId = auraSpellId
							if target == "player" then
								newSpell.removeOnSuccess = true
							end
							break
						end
					end
				end
			end
		end
		
		--Ovale:Print("spellInfo found")
		if si and si.buffnocd and UnitBuff("player", GetSpellInfo(si.buffnocd)) then
			newSpell.nocd = true
		else
			newSpell.nocd = false
		end
		--Increase or reset the counter that is used by the Counter function
		if si.resetcounter then
			self.counter[si.resetcounter] = 0
			--Ovale:Print("reset counter "..si.resetcounter)
		end
		if si.inccounter then
			local cname = si.inccounter
			if not self.counter[cname] then
				self.counter[cname] = 0
			end
			self.counter[cname] = self.counter[cname] + 1
			--Ovale:Print("inc counter "..cname.." to "..self.counter[cname])
		end
	else
		newSpell.removeOnSuccess = true
	end
	
	if Ovale.enCombat then
		--Ovale:Print(tostring(OvaleData.scoreSpell[spellId]))
		if (not OvaleData.spellInfo[spellId] or not OvaleData.spellInfo[spellId].toggle) and OvaleData.scoreSpell[spellId] then
			--Compute the player score
			local scored = Ovale.frame:GetScore(spellId)
			--Ovale:Print("Scored "..scored)
			if scored~=nil then
				Ovale.score = Ovale.score + scored
				Ovale.maxScore = Ovale.maxScore + 1
				Ovale:SendScoreToDamageMeter(UnitName("player"), OvaleAura.playerGUID, scored, 1)
			end
		end
	end
	Ovale.refreshNeeded["player"] = true
end


function OvaleFuture:RemoveSpellFromList(spellId, lineId)
	for i,v in ipairs(self.lastSpell) do
		if v.lineId == lineId then
			table.remove(self.lastSpell, i)
			--Ovale:Print("RemoveSpellFromList on supprime "..spellId)
			break
		end
	end
	Ovale.refreshNeeded["player"] = true
end

-- Apply the effects of travelling spells
function OvaleFuture:Apply()
	for i,v in ipairs(self.lastSpell) do
		if not OvaleData.spellInfo[v.spellId] or not OvaleData.spellInfo[v.spellId].toggle then
			--[[local spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo("player")
			if spell and spell == v.name and startTime/1000 - v.start < 0.5 and v.stop~=endTime/1000 then
				print("ancien = "..v.stop)
				v.stop = endTime/1000
				print("changement de v.stop en "..v.stop.." "..v.start)
			end]]
			Ovale:Log("OvaleState.maintenant = " ..OvaleState.maintenant.." spellId="..v.spellId.." v.stop="..v.stop)
			if OvaleState.maintenant - v.stop < 5 then
				OvaleState:AddSpellToStack(v.spellId, v.start, v.stop, v.stop, v.nocd, v.target)
			else
				--Ovale:Print("Removing obsolete "..v.spellId)
				table.remove(self.lastSpell, i)
			end
		end
	end
end
--</public-static-methods>
