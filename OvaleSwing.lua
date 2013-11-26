--[[--------------------------------------------------------------------
	Copyright (C) 2006-2007 Nymbia

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program; if not, write to the Free Software Foundation, Inc.,
	51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

	Modified for Ovale.

    Copyright (C) 2009, 2011, 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleSwing = Ovale:NewModule("OvaleSwing", "AceEvent-3.0")
Ovale.OvaleSwing = OvaleSwing

--<private-static-properties>
local math_abs = math.abs
local unpack = unpack
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local API_IsDualWielding = IsDualWielding
local API_UnitAttackSpeed = UnitAttackSpeed
local API_UnitGUID = UnitGUID
local API_UnitRangedDamage = UnitRangedDamage
local BOOKTYPE_SPELL = BOOKTYPE_SPELL

-- Player's GUID.
local self_guid = nil

local OVALE_AUTOSHOT_NAME = API_GetSpellInfo(75)
local OVALE_RESET_SPELLS = {}
local OVALE_DELAY_SPELLS = {
	[API_GetSpellInfo(1464)] = true, -- Slam
}
local OVALE_RESET_AUTOSHOT_SPELLS = {}
--</private-static-properties>

--<public-static-properties>
OvaleSwing.ohNext = nil
OvaleSwing.dual = false
OvaleSwing.starttime = nil
OvaleSwing.duration = nil
OvaleSwing.ohStartTime = nil
OvaleSwing.ohDuration = nil
OvaleSwing.delay = nil
OvaleSwing.startdelay = nil
OvaleSwing.swingmode = nil
--</public-static-properties>

--<public-static-methods>
function OvaleSwing:OnEnable()
	self_guid = API_UnitGUID("player")
	self.ohNext = false
	-- fired when autoattack is enabled/disabled.
	self:RegisterEvent("PLAYER_ENTER_COMBAT")
	self:RegisterEvent("PLAYER_LEAVE_COMBAT")
	-- fired when autoshot (or autowand) is enabled/disabled
	self:RegisterEvent("START_AUTOREPEAT_SPELL")
	self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
	
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	
	self:RegisterEvent("UNIT_ATTACK")
end

function OvaleSwing:OnDisable()
end

function OvaleSwing:PLAYER_ENTER_COMBAT()
	self.dual = API_IsDualWielding()
	--print("Enter combat")
end

function OvaleSwing:PLAYER_LEAVE_COMBAT()
	self.ohNext = false
	self.ohStartTime = nil
	self.ohDuration = nil
	self.duration = nil
	self.starttime = nil
	self.delay = 0
end

function OvaleSwing:START_AUTOREPEAT_SPELL()
end

function OvaleSwing:STOP_AUTOREPEAT_SPELL()
end

function OvaleSwing:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventName, srcGUID, srcName, srcFlags, dstName, dstGUID, dstFlags, ...)
	if srcGUID == self_guid then
		if eventName == "SWING_DAMAGE" or eventName == "SWING_MISSED" then
			local now = API_GetTime()
			self:MeleeSwing(now)
		end
	end
end

function OvaleSwing:UNIT_SPELLCAST_START(event, unit, spell)
	if OVALE_DELAY_SPELLS[spell] and unit=="player" then
		self.startdelay = API_GetTime()
		local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = API_GetSpellInfo(spell)
		self.delay = castTime
	end
end

function OvaleSwing:UNIT_SPELLCAST_INTERRUPTED(event, unit, spell)
	if unit == "player" and OVALE_DELAY_SPELLS[spell] and self.startdelay then
		local now = API_GetTime()
		self.delay = now - self.startdelay
	end
end

function OvaleSwing:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell)
	if unit == "player" then
		local now = API_GetTime()
		if OVALE_RESET_SPELLS[spell] then
			self:MeleeSwing(now)
		end
		if OVALE_DELAY_SPELLS[spell] and self.startdelay then
			self.delay = now - self.startdelay
		end
		if spell == OVALE_AUTOSHOT_NAME then
			self:Shoot()
		end
		if OVALE_RESET_AUTOSHOT_SPELLS[spell] then
			self:Shoot()
		end
	end
end

function OvaleSwing:UNIT_ATTACK(event, unit)
	--[[if unit == 'player' then
		if not self.swingmode then
			return
		elseif self.swingmode == 0 then
			self.duration = API_UnitAttackSpeed('player')
		else
			self.duration = API_UnitRangedDamage('player')
		end
	end]]
end

function OvaleSwing:MeleeSwing(timestamp)
	if self.dual and self.ohNext then
		--[[if self.ohDuration then
			local prediction = self.ohDuration+self.ohStartTime+self.delay
			print("Prediction oh = "  .. prediction .. " diff=" .. (timestamp-prediction))
		end]]
		self.ohDuration = API_UnitAttackSpeed('player')
		self.ohStartTime = timestamp
		--print("MeleeSwing oh = " .. self.ohStartTime)
		self.ohNext = false
	else
		--[[if self.duration then
			local prediction = self.duration+self.starttime+self.delay
			print("Prediction mh = " .. prediction .. " diff=" .. (timestamp-prediction))
		end]]
		self.duration = API_UnitAttackSpeed('player')
		self.starttime = timestamp
		--print("MeleeSwing mh = " .. self.starttime)
		self.ohNext = true
		if self.ohStartTime == nil then
			self.ohStartTime = self.starttime - self.duration/2
			self.ohDuration = self.duration
		end
	end
	self.delay = 0
end

function OvaleSwing:Shoot()
	--[[if self.duration then
		print("Prediction = " ..(self.duration+self.starttime))
	end]]
	self.duration = API_UnitRangedDamage('player')
	self.starttime = API_GetTime()
	--print("Shoot " .. self.starttime)
end

function OvaleSwing:GetLast(which)
	if not self.duration then
		return nil
	end
	if which == "main" then
		return self.starttime
	elseif which == "off" then
		return self.ohStartTime
	else
		if self.dual and self.ohNext then
			return self.starttime
		else
			return self.ohStartTime
		end
	end
end

function OvaleSwing:GetNext(which)
	if not self.duration then
		return nil
	end
	if which == "main" then
		return self.duration + self.starttime + self.delay
	elseif which == "off" then
		return self.ohDuration + self.ohStartTime + self.delay
	else
		if self.dual and self.ohNext then
			return self.ohDuration + self.ohStartTime + self.delay
		else
			return self.duration + self.starttime + self.delay
		end
	end
end
--</public-static-methods>
