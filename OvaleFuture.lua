--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

-- The travelling missiles or spells that have been cast but whose effects were not still not applied

local _, Ovale = ...
OvaleFuture = Ovale:NewModule("OvaleFuture", "AceEvent-3.0")

--<private-static-properties>
local ipairs = ipairs
local pairs = pairs
local select = select
local strfind = string.find
local tremove = table.remove

local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local UnitBuff = UnitBuff
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitGUID = UnitGUID

-- The spells that the player is casting or has cast but are still in-flight toward their targets.
local lastSpell = {}
--</private-static-properties>

--<public-static-properties>
--spell counter (see Counter function)
OvaleFuture.counter = {}
OvaleFuture.lastSpellId = nil
--the attack power of the last spell
OvaleFuture.lastSpellAP = {}
OvaleFuture.lastSpellSP = {}
OvaleFuture.lastSpellDM = {}
OvaleFuture.lastSpellCombo = {}
OvaleFuture.lastSpellMastery = {}
OvaleFuture.playerGUID = nil
OvaleFuture.nextSpellTarget = nil
OvaleFuture.nextSpellLineID = nil
-- Debugging: spell ID to trace
OvaleFuture.traceSpellId = nil
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
		local startTime, endTime = select(5, UnitChannelInfo("player"))
		if self.traceSpellId and self.traceSpellId == spellId then
			Ovale:Print(event.. ": " ..GetTime().. " " ..name.. " (" ..spellId.. "), lineId = " ..lineId)
			Ovale:Print("    startTime = " ..startTime.. ", endTime = " ..endTime)
		end
		self:AddSpellToList(spellId, lineId, startTime/1000, endTime/1000, true, false)
	end
end

function OvaleFuture:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		if self.traceSpellId and self.traceSpellId == spellId then
			Ovale:Print(event.. ": " ..GetTime().. " " ..name.. " (" ..spellId.. "), lineId = " ..lineId)
		end
		self:RemoveSpellFromList(spellId, lineId)
	end
end

--Called when a spell started its cast
function OvaleFuture:UNIT_SPELLCAST_START(event, unit, name, rank, lineId, spellId)
	if unit=="player" then
		local startTime, endTime = select(5, UnitCastingInfo("player"))
		if self.traceSpellId and self.traceSpellId == spellId then
			Ovale:Print(event.. ": " ..GetTime().. " " ..name.. " (" ..spellId.. "), lineId = " ..lineId)
			Ovale:Print("    startTime = " ..startTime.. ", endTime = " ..endTime)
		end
		self:AddSpellToList(spellId, lineId, startTime/1000, endTime/1000, false, false)
	end
end

--Called if the player interrupted early his cast
--The spell is removed from the lastSpell table
function OvaleFuture:UNIT_SPELLCAST_INTERRUPTED(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		if self.traceSpellId and self.traceSpellId == spellId then
			Ovale:Print(event.. ": " ..GetTime().. " " ..name.. " (" ..spellId.. "), lineId = " ..lineId)
		end
		self:RemoveSpellFromList(spellId, lineId)
	end
end

function OvaleFuture:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target, lineId)
	if unit == "player" then
		local targetGUID 
		--The UNIT_TARGET event may come a bit late
		if target == UnitName("target") then
			targetGUID = UnitGUID("target")
		else
			targetGUID = OvaleGUID.nameToGUID[target]
		end
		self.nextSpellTarget = targetGUID
		self.nextSpellLineID = lineId
		if self.traceSpellId and self.traceSpellId == spellId then
			Ovale:Print(event.. ": " ..GetTime().. " " ..name.. " (" ..spellId.. "), lineId = " ..lineId)
			Ovale:Print("    targetGUID = " ..targetGUID)
		end
		for i,v in ipairs(lastSpell) do
			if v.lineId == lineId then
				v.target = targetGUID
			end
		end
	end
end

function OvaleFuture:UNIT_SPELLCAST_SUCCEEDED(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		if self.traceSpellId and self.traceSpellId == spellId then
			Ovale:Print(event.. ": " ..GetTime().. " " ..name.. " (" ..spellId.. "), lineId = " ..lineId)
		end
		for i,v in ipairs(lastSpell) do
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
		--if strfind(event, "SPELL") == 1 then
		--	local spellId, spellName = select(12, ...)
		--	Ovale:Print(event .. " " ..spellName .. " " ..GetTime())
		--end
			-- local spellId, spellName = select(12, ...)
			-- for i,v in ipairs(lastSpell) do
			
			-- end
		--end
		
		if 
				strfind(event, "SPELL_AURA_APPLIED")==1
				or strfind(event, "SPELL_AURA_REFRESH")==1
				or strfind(event, "SPELL_DAMAGE")==1 
				or strfind(event, "SPELL_MISSED") == 1 
				or strfind(event, "SPELL_CAST_SUCCESS") == 1
				or strfind(event, "SPELL_CAST_FAILED") == 1 then
			local spellId, spellName = select(12, ...)
			if self.traceSpellId and self.traceSpellId == spellId then
				Ovale:Print(event.. ": " ..GetTime().. " " ..spellName.. " (" ..spellId.. ")")
			end
			for i,v in ipairs(lastSpell) do
				if (v.spellId == spellId or v.auraSpellId == spellId) and v.allowRemove then
					if not v.channeled and (v.removeOnSuccess or 
								strfind(event, "SPELL_CAST_SUCCESS") ~= 1) then
						if self.traceSpellId and self.traceSpellId == spellId then
							local spellName = OvaleData.spellList[spellId] or GetSpellInfo(spellId)
							Ovale:Print("    Spell landed: " ..GetTime().. " " ..spellName.. " (" ..spellId.. ")")
						end
						tremove(lastSpell, i)
						Ovale.refreshNeeded["player"] = true
					end 
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
		-- Ovale:Print("found lineId " .. lineId .. " target is " .. self.nextSpellTarget)
		newSpell.target = self.nextSpellTarget
	else
		newSpell.target = UnitGUID("target")
	end
	if self.traceSpellId and self.traceSpellId == spellId then
		local spellName = OvaleData.spellList[spellId] or GetSpellInfo(spellId)
		Ovale:Print("    AddSpellToList: " ..GetTime().. " " ..spellName.. " (" ..spellId.. "), lineId = " ..lineId)
		Ovale:Print("        startTime = " ..startTime.. ", endTime = " ..endTime)
		Ovale:Print("        target = " ..newSpell.target.. (channeled and "(channeled)" or "") .. (allowRemove and "(allowRemove)" or ""))
	end

	self.lastSpellId = spellId
	self.lastSpellAP[spellId] = OvalePaperDoll.attackPower
	self.lastSpellSP[spellId] = OvalePaperDoll.spellBonusDamage
	self.lastSpellDM[spellId] = OvaleAura:GetDamageMultiplier(spellId)
	self.lastSpellMastery[spellId] = OvalePaperDoll.masteryEffect
	lastSpell[#lastSpell+1] = newSpell
	
	local si = OvaleData.spellInfo[spellId]
	if si then
		if si.combo == 0 then
			-- This spell is a CP-finisher, so save the number of CPs used.
			local comboPoints = OvaleComboPoints.combo
			if comboPoints > 0 then
				self.lastSpellCombo[spellId] = comboPoints
			end
		end

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

		if si.buffnocd and UnitBuff("player", GetSpellInfo(si.buffnocd)) then
			newSpell.nocd = true
		else
			newSpell.nocd = false
		end

		--Increase or reset the counter that is used by the Counter function
		if si.resetcounter then
			self.counter[si.resetcounter] = 0
		end
		if si.inccounter then
			local cname = si.inccounter
			if not self.counter[cname] then
				self.counter[cname] = 0
			end
			self.counter[cname] = self.counter[cname] + 1
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
	for i,v in ipairs(lastSpell) do
		if v.lineId == lineId then
			if self.traceSpellId and self.traceSpellId == spellId then
				local spellName = OvaleData.spellList[spellId] or GetSpellInfo(spellId)
				Ovale:Print("    RemoveSpellFromList: " ..GetTime().. " " ..spellName.. " (" ..spellId.. ")")
			end
			tremove(lastSpell, i)
			break
		end
	end
	Ovale.refreshNeeded["player"] = true
end

--[[-----------------------------------------------------------------------
	Iterator for spells that are being cast or are in flight.

	The iterator returns:
		spellId: ID of the spell
		lineId: spell counter (see documentation for UNIT_SPELLCAST_START)
		startCast: the time the spell started being cast
		endCast: the time the spell cast will end
		nextCast: the time the next spell can be cast
		nocd: true if the spell has no cooldown
		target: the target of the spell (can be nil)
--]]-----------------------------------------------------------------------
function OvaleFuture:InFlightSpells(now)
	local index = 0
	local cast, si
	return function()
		while true do
			index = index + 1
			if index > #lastSpell then return end

			cast = lastSpell[index]
			si = OvaleData.spellInfo[cast.spellId]
			-- skip over spells that are toggles for other spells
			if not (si and si.toggle) then
				Ovale:Log("now = " .. now .. " spellId = " .. cast.spellId .. " endCast = " .. cast.stop)
				if now - cast.stop < 5 then
					return cast.spellId, cast.lineId, cast.start, cast.stop, cast.stop, cast.nocd, cast.target
				else
					tremove(lastSpell, index)
					-- Decrement current index since item was removed and rest of items shifted up.
					index = index - 1
				end
				break
			end
		end
	end
end

function OvaleFuture:InFlight(spellId)
	for i,v in ipairs(lastSpell) do
		if v.spellId == spellId then
			return true
		end
	end
	return false
end

function OvaleFuture:Debug()
	if next(lastSpell) then
		Ovale:Print("Spells in flight:")
	else
		Ovale:Print("No spells in flight!")
	end
	for spellId, lineId in self:InFlightSpells(GetTime()) do
		local spellName = OvaleData.spellList[spellId] or GetSpellInfo(spellId)
		Ovale:Print("    " ..spellName.. " (" ..spellId.. "), lineId = " ..tostring(lineId))
	end
end
--</public-static-methods>
