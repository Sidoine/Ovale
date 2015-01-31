--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleLatency = Ovale:NewModule("OvaleLatency", "AceEvent-3.0")
Ovale.OvaleLatency = OvaleLatency

--<private-static-properties>
local API_GetNetStats = GetNetStats
local API_GetTime = GetTime
--</private-static-properties>

--<public-static-properties>
-- The spell requests that have been sent to the server and are awaiting a reply.
-- spellcast[lineId] = GetTime() timestamp
OvaleLatency.spellcast = {}
OvaleLatency.lastUpdateTime = nil
OvaleLatency.latency = nil
--</public-static-properties>

--<public-static-methods>
function OvaleLatency:OnEnable()
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "UpdateLatency")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_START", "UpdateLatency")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "UpdateLatency")
end

function OvaleLatency:OnDisable()
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:UnregisterEvent("UNIT_SPELLCAST_SENT")
	self:UnregisterEvent("UNIT_SPELLCAST_START")
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Event handler for UNIT_SPELLCAST_* events that updates the current roundtrip latency.
function OvaleLatency:UpdateLatency(event, unit, name, rank, lineId, spellId)
	if unit == "player" and self.spellcast[lineId] then
		--[[
			Assume an event loop looks like:

				client --SENT--> server (processing) --CHANNEL_START/START/SUCCEEDED--> client

			By taking the difference between the SENT and CHANNEL_START/START/SUCCEEDED events,
			we are assuming that the processing time on the server is negligible compared to the
			network latency.  As a result, this will always over-estimate the true latency.
		]]--
		local now = API_GetTime()
		local latency = now - self.spellcast[lineId]
		if latency > 0 then
			self.latency = latency
			self.lastUpdateTime = now
		end
		self.spellcast[lineId] = nil
		Ovale.refreshNeeded.player = true
	end
end

function OvaleLatency:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target, lineId)
	if unit == "player" then
		-- Note starting time for latency calculation.
		self.spellcast[lineId] = API_GetTime()
	end
end

function OvaleLatency:GetLatency()
	-- If we haven't cast a spell in a while, then get the average world roundtrip latency
	-- using GetNetStats().
	local now = API_GetTime()
	if not self.latency or not self.lastUpdateTime or now - self.lastUpdateTime > 10 then
		local _, _, _, latency = API_GetNetStats()
		self.latency = latency / 1000
	end
	return self.latency
end
--</public-static-methods>
