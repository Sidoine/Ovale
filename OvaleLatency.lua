--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleLatency = Ovale:NewModule("OvaleLatency", "AceEvent-3.0")
Ovale.OvaleLatency = OvaleLatency

--<private-static-properties>
local select = select
local API_GetNetStats = GetNetStats

-- The spell requests that have been sent to the server and are awaiting a reply.
-- self_sentSpellcast[lineId] = GetTime() timestamp
local self_sentSpellcast = {}

local self_lastUpdateTime = nil
local self_latency = nil
--</private-static-properties>

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
	if unit == "player" and self_sentSpellcast[lineId] then
		--[[
			Assume an event loop looks like:

				client --SENT--> server (processing) --CHANNEL_START/START/SUCCEEDED--> client

			By taking the difference between the SENT and CHANNEL_START/START/SUCCEEDED events,
			we are assuming that the processing time on the server is negligible compared to the
			network latency.  As a result, this will always over-estimate the true latency.
		]]--
		local latency = Ovale.now - self_sentSpellcast[lineId]
		if latency > 0 then
			self_latency = latency
			self_lastUpdateTime = Ovale.now
		end
		self_sentSpellcast[lineId] = nil
	end
end

function OvaleLatency:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target, lineId)
	if unit == "player" then
		-- Note starting time for latency calculation.
		self_sentSpellcast[lineId] = Ovale.now
	end
end

function OvaleLatency:GetLatency()
	-- If we haven't cast a spell in a while, then get the average world roundtrip latency
	-- using GetNetStats().
	if not self_latency or not self_lastUpdateTime or Ovale.now - self_lastUpdateTime > 10 then
		self_latency = select(4, API_GetNetStats()) / 1000
	end
	return self_latency
end
--</public-static-methods>
