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
-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleGUID = nil
local OvalePaperDoll = nil
local OvaleStance = nil
local OvaleState = nil

local API_UnitHealth = UnitHealth
local API_UnitHealthMax = UnitHealthMax
local API_UnitClass = UnitClass

-- Player's class.
local self_class = select(2, API_UnitClass("player"))
--</private-static-properties>

--<public-static-methods>
function OvaleCooldown:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvaleGUID = Ovale.OvaleGUID
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvaleStance = Ovale.OvaleStance
	OvaleState = Ovale.OvaleState
end

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
OvaleCooldown.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleCooldown.statePrototype
--</private-static-properties>

--<state-properties>
statePrototype.cd = nil
--</state-properties>

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
	end
end

-- Release state resources prior to removing from the simulator.
function OvaleCooldown:CleanState(state)
	for spellId, cd in pairs(state.cd) do
		for k in pairs(cd) do
			cd[k] = nil
		end
		state.cd[spellId] = nil
	end
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleCooldown:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast)
	local si = OvaleData.spellInfo[spellId]
	if si then
		local cd = state:GetCD(spellId)
		if cd then
			cd.start = isChanneled and startCast or endCast
			cd.duration = si.cd or 0
			cd.enable = 1

			-- Test for no cooldown.
			if nocd then
				cd.duration = 0
			else
				-- There is no cooldown if the buff named by "buffnocd" parameter is present.
				if si.buffnocd then
					local aura = state:GetAura("player", si.buffnocd)
					if state:IsActiveAura(aura) then
						Ovale:Logf("buffnocd stacks = %s, start = %s, ending = %s, startCast = %f", aura.stacks, aura.start, aura.ending, startCast)
						if aura.start <= startCast and startCast < aura.ending then
							cd.duration = 0
						end
					end
				end

				-- There is no cooldown if the target's health percent is below what's specified
				-- with the "targetlifenocd" parameter.
				local target = OvaleGUID:GetUnitId(targetGUID)
				if target and si.targetlifenocd then
					local healthPercent = API_UnitHealth(target) / API_UnitHealthMax(target) * 100
					if healthPercent < si.targetlifenocd then
						cd.duration = 0
					end
				end
			end

			-- Adjust cooldown duration if it is affected by haste: "cd_haste=melee" or "cd_haste=spell".
			if cd.duration > 0 and si.cd_haste then
				if si.cd_haste == "melee" then
					cd.duration = cd.duration / state:GetMeleeHasteMultiplier(spellcast.snapshot)
				elseif si.cd_haste == "spell" then
					cd.duration = cd.duration / state:GetSpellHasteMultiplier(spellcast.snapshot)
				end
			end

			Ovale:Logf("Spell %d cooldown info: start=%f, duration=%f", spellId, cd.start, cd.duration)
		end
	end
end
--</public-static-methods>

--<state-methods>
-- Return the table holding the simulator's cooldown information for the given spell.
statePrototype.GetCD = function(state, spellId)
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
statePrototype.GetSpellCooldown = function(state, spellId)
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
statePrototype.ResetSpellCooldown = function(state, spellId, atTime)
	if atTime >= state.currentTime then
		local start, duration, enable = state:GetSpellCooldown(spellId)
		if start + duration > state.currentTime then
			local cd = state:GetCD(spellId)
			if cd then
				cd.start = state.currentTime
				cd.duration = atTime - state.currentTime
				cd.enable = 1
			end
		end
	end
end
--</state-methods>
