--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleCooldown = Ovale:NewModule("OvaleCooldown")
Ovale.OvaleCooldown = OvaleCooldown

--<private-static-properties>
local OvaleData = Ovale.OvaleData
local OvalePaperDoll = Ovale.OvalePaperDoll
local OvaleStance = Ovale.OvaleStance
local OvaleState = Ovale.OvaleState

local API_UnitHealth = UnitHealth
local API_UnitHealthMax = UnitHealthMax
local API_UnitClass = UnitClass

-- Player's class.
local self_class = select(2, API_UnitClass("player"))
--</private-static-properties>

--<public-static-methods>
function OvaleCooldown:OnEnable()
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvaleCooldown:OnDisable()
	OvaleState:UnregisterState(self)
end

-- Return the GCD after the given spellId is cast.
-- If no spellId is given, then returns the GCD after a "yellow-hit" ability has been cast.
function OvaleCooldown:GetGCD(spellId)
	-- Base global cooldown.
	local isCaster = false
	if self_class == "DEATHKNIGHT" then
		cd = 1.0
	elseif self_class == "DRUID" and OvaleStance:IsStance("druid_cat_form") then
		cd = 1.0
	elseif self_class == "MONK" then
		cd = 1.0
	elseif self_class == "ROGUE" then
		cd = 1.0
	else
		isCaster = true
		cd = 1.5
	end

	-- Use SpellInfo() information if available.
	if spellId and OvaleData.spellInfo[spellId] then
		local si = OvaleData.spellInfo[spellId]
		if si.gcd then
			cd = si.gcd
		end
		if si.haste then
			if si.haste == "melee" then
				cd = cd / OvalePaperDoll:GetMeleeHasteMultiplier()
			elseif si.haste == "spell" then
				cd = cd / OvalePaperDoll:GetSpellHasteMultiplier()
			end
		end
	elseif isCaster then
		cd = cd / OvalePaperDoll:GetSpellHasteMultiplier()
	end

	-- Clamp GCD at 1s.
	cd = (cd > 1) and cd or 1
	return cd
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleCooldown.statePrototype = {
	cd = nil,
}
--</public-static-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleCooldown:InitializeState(state)
	state.cd = {}
end

-- Reset the state to the current conditions.
function OvaleCooldown:ResetState(state)
	for _, cd in pairs(state.cd) do
		cd.start = nil
		cd.duration = nil
		cd.enable = 0
		cd.toggled = nil
	end
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleCooldown:ApplySpellOnPlayer(state, spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
	-- If the spellcast has already ended, then the effects on the player have already occurred.
	if endCast <= OvaleState.now then
		return
	end

	local si = OvaleData.spellInfo[spellId]
	if si then
		local cd = state:GetCD(spellId)
		if cd then
			cd.start = startCast
			cd.duration = si.cd or 0

			-- Test for no cooldown.
			if nocd then
				cd.duration = 0
			else
				-- There is no cooldown if the buff named by "buffnocd" parameter is present.
				if si.buffnocd then
					local start, ending, stacks = state:GetAura("player", si.buffnocd)
					if start and stacks and stacks > 0 then
						Ovale:Logf("buffnocd stacks = %s, start = %s, ending = %s, startCast = %f", stacks, start, ending, startCast)
						-- XXX Shouldn't this be (not ending or ending > endCast)?
						-- XXX The spellcast needs to finish before the buff expires.
						if start <= startCast and (not ending or ending > startCast) then
							cd.duration = 0
						end
					end
				end

				-- There is no cooldown if the target's health percent is below what's specified
				-- with the "targetlifenocd" parameter.
				if si.targetlifenocd then
					local healthPercent = API_UnitHealth("target") / API_UnitHealthMax("target") * 100
					if healthPercent < si.targetlifenocd then
						cd.duration = 0
					end
				end
			end

			-- Adjust cooldown duration if it is affected by haste: "cd_haste=melee" or "cd_haste=spell".
			if cd.duration > 0 and si.cd_haste then
				if si.cd_haste == "melee" then
					cd.duration = cd.duration / OvalePaperDoll:GetMeleeHasteMultiplier()
				elseif si.cd_haste == "spell" then
					cd.duration = cd.duration / OvalePaperDoll:GetSpellHasteMultiplier()
				end
			end

			cd.enable = 1
			if si.toggle then
				cd.toggled = 1
			end
			Ovale:Logf("Spell %d cooldown info: start=%f, duration=%f", spellId, cd.start, cd.duration)
		end
	end
end
--</public-static-methods>

-- Mix-in methods for simulator state.
do
	local statePrototype = OvaleCooldown.statePrototype

	-- Return the table holding the simulator's cooldown information for the given spell.
	function statePrototype:GetCD(spellId)
		local state = self
		if spellId then
			local si = OvaleData.spellInfo[spellId]
			if si and si.cd then
				local cdname = si.sharedcd and si.sharedcd or spellId
				if not state.cd[cdname] then
					state.cd[cdname] = {}
				end
				return state.cd[cdname]
			end
		end
		return nil
	end

	-- Return the cooldown for the spell in the simulator.
	function statePrototype:GetSpellCooldown(spellId)
		local state = self
		local start, duration, enable
		local cd = state:GetCD(spellId)
		if cd and cd.start then
			start = cd.start
			duration = cd.duration
			enable = cd.enable
		else
			start, duration, enable = OvaleData:GetSpellCooldown(spellId)
		end
		return start, duration, enable
	end

	-- Force the cooldown of a spell to reset at the specified time.
	function statePrototype:ResetSpellCooldown(spellId, atTime)
		local state = self
		if atTime >= OvaleState.currentTime then
			local cd = state:GetCD(spellId)
			cd.start = OvaleState.currentTime
			cd.duration = atTime - OvaleState.currentTime
			cd.enable = 1
		end
	end
end
