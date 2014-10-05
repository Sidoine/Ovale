--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

--[[
	This addon tracks Eclipse energy information on druids.
--]]

local _, Ovale = ...
local OvaleEclipse = Ovale:NewModule("OvaleEclipse", "AceEvent-3.0")
Ovale.OvaleEclipse = OvaleEclipse

--<private-static-properties>
-- Profiling set-up.
local Profiler = Ovale.Profiler
local profiler = nil
do
	local group = OvaleEclipse:GetName()
	Profiler:RegisterProfilingGroup(group)
	profiler = Profiler:GetProfilingGroup(group)
end

-- Forward declarations for module dependencies.
local OvaleAura = nil
local OvaleData = nil
local OvaleFuture = nil
local OvaleSpellBook = nil
local OvaleState = nil

local floor = math.floor
local API_GetEclipseDirection = GetEclipseDirection
local API_UnitClass = UnitClass
local API_UnitGUID = UnitGUID
local API_UnitPower = UnitPower
local SPELL_POWER_ECLIPSE = SPELL_POWER_ECLIPSE

local OVALE_ECLIPSE_DEBUG = "eclipse"

-- Player's GUID.
local self_guid = nil
-- Player's class.
local _, self_class = API_UnitClass("player")
-- Table of functions to update spellcast information to register with OvaleFuture.
local self_updateSpellcastInfo = {}

local LUNAR_ECLIPSE = ECLIPSE_BAR_LUNAR_BUFF_ID
local SOLAR_ECLIPSE = ECLIPSE_BAR_SOLAR_BUFF_ID
-- Nature's Grace: You gain 15% spell haste for 15 seconds each time you trigger an Eclipse.
local NATURES_GRACE = 16886
local CELESTIAL_ALIGNMENT = 112071
local DREAM_OF_CENARIUS = 145151
local DREAM_OF_CENARIUS_TALENT = 17
local EUPHORIA = 81062
local MOONKIN_FORM = 24858
local STARFALL = 48505
--</private-static-properties>

--<public-static-properties>
-- Direction that the eclipse status is moving: -1 = "lunar", 0 = "none", 1 = "solar".
OvaleEclipse.eclipse = 0
OvaleEclipse.eclipseDirection = 0
--<public-static-properties>

--<private-static-methods>
-- Manage Eclipsed damage multiplier information.
local function GetDamageMultiplier(spellId, snapshot, auraObject)
	auraObject = auraObject or OvaleAura
	local damageMultiplier = 1
	local si = OvaleData.spellInfo[spellId]

	if si and (si.arcane == 1 or si.nature == 1) then
		-- Update the damage multiplier for Moonkin Form 10% bonus to Arcane and Nature damage.
		local moonkinForm = auraObject:GetAura("player", MOONKIN_FORM, "HELPFUL", true)
		if auraObject:IsActiveAura(moonkinForm) then
			damageMultiplier = damageMultiplier * 1.1
		end

		-- Update the damage multiplier for Eclipse bonus to Arcane and Nature damage.
		local aura
		if si.arcane == 1 then
			aura = auraObject:GetAura("player", LUNAR_ECLIPSE, "HELPFUL", true)
		end
		if not auraObject:IsActiveAura(aura) and si.nature == 1 then
			aura = auraObject:GetAura("player", SOLAR_ECLIPSE, "HELPFUL", true)
		end
		if not auraObject:IsActiveAura(aura) then
			aura = auraObject:GetAura("player", CELESTIAL_ALIGNMENT, "HELPFUL", true)
		end
		if auraObject:IsActiveAura(aura) then
			local eclipseEffect = aura.value1
			local masteryEffect = snapshot.masteryEffect or 0
			eclipseEffect = eclipseEffect - floor(masteryEffect) + masteryEffect
			damageMultiplier = damageMultiplier * (1 + eclipseEffect / 100)
		end
	end
	return damageMultiplier
end

do
	self_updateSpellcastInfo.GetDamageMultiplier = GetDamageMultiplier
end
--</private-static-methods>

--<public-static-methods>
function OvaleEclipse:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
	OvaleData = Ovale.OvaleData
	OvaleFuture = Ovale.OvaleFuture
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleState = Ovale.OvaleState
end

function OvaleEclipse:OnEnable()
	if self_class == "DRUID" then
		self_guid = API_UnitGUID("player")
		self:RegisterMessage("Ovale_SpecializationChanged")
	end
end

function OvaleEclipse:OnDisable()
	if self_class == "DRUID" then
		self:UnregisterMessage("Ovale_SpecializationChanged")
	end
end

function OvaleEclipse:Ovale_SpecializationChanged(event, specialization, previousSpecialization)
	if specialization == "balance" then
		self:Update()
		self:RegisterEvent("ECLIPSE_DIRECTION_CHANGE", "UpdateEclipseDirection")
		self:RegisterEvent("UNIT_POWER")
		self:RegisterEvent("UNIT_POWER_FREQUENT", "UNIT_POWER")
		self:RegisterMessage("Ovale_StanceChanged", "Update")
		self:RegisterMessage("Ovale_AuraAdded")
		OvaleState:RegisterState(self, self.statePrototype)
		OvaleFuture:RegisterSpellcastInfo(self_updateSpellcastInfo)
	else
		OvaleState:UnregisterState(self)
		OvaleFuture:UnregisterSpellcastInfo(self_updateSpellcastInfo)
		self:UnregisterEvent("ECLIPSE_DIRECTION_CHANGE")
		self:UnregisterEvent("UNIT_POWER")
		self:UnregisterEvent("UNIT_POWER_FREQUENT")
		self:UnregisterMessage("Ovale_AuraAdded")
		self:UnregisterMessage("Ovale_StanceChanged")
	end
end

function OvaleEclipse:UNIT_POWER(event, unitId, powerToken)
	if unitId == "player" and powerToken == "ECLIPSE" then
		self:Update()
	end
end

function OvaleEclipse:Ovale_AuraAdded(event, timestamp, guid, spellId, caster)
	if guid == self_guid then
		if spellId == LUNAR_ECLIPSE or spellId == SOLAR_ECLIPSE then
			self:UpdateEclipseDirection()
		end
	end
end

function OvaleEclipse:Update()
	self:UpdateEclipse()
	self:UpdateEclipseDirection()
end

function OvaleEclipse:UpdateEclipse()
	profiler.Start("OvaleEclipse_UpdateEclipse")
	self.eclipse = API_UnitPower("player", SPELL_POWER_ECLIPSE)
	profiler.Stop("OvaleEclipse_UpdateEclipse")
end

function OvaleEclipse:UpdateEclipseDirection()
	profiler.Start("OvaleEclipse_UpdateEclipseDirection")
	local direction = API_GetEclipseDirection()
	if direction == "moon" then
		self.eclipseDirection = -1
	elseif direction == "sun" then
		self.eclipseDirection = 1
	else -- if direction == "none" then
		if self.eclipse < 0 then
			self.eclipseDirection = -1
		elseif self.eclipse > 0 then
			self.eclipseDirection = 1
		else -- if self.eclipse == 0 then
			self.eclipseDirection = 0
		end
	end
	profiler.Stop("OvaleEclipse_UpdateEclipseDirection")
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.

	AFTER: OvalePower
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleEclipse.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleEclipse.statePrototype
--</private-static-properties>

--<state-properties>
-- Direction in which the Eclipse bar is moving.
statePrototype.eclipseDirection = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleEclipse:InitializeState(state)
	state.eclipseDirection = 0
end

-- Reset the state to the current conditions.
function OvaleEclipse:ResetState(state)
	profiler.Start("OvaleEclipse_ResetState")
	state.eclipseDirection = self.eclipseDirection
	profiler.Stop("OvaleEclipse_ResetState")
end

-- Apply the effects of the spell at the start of the spellcast.
function OvaleEclipse:ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast)
	profiler.Start("OvaleEclipse_ApplySpellStartCast")
	-- Channeled spells cost resources at the start of the channel.
	if isChanneled then
		state:ApplyEclipseEnergy(spellId, startCast, spellcast.snapshot)
	end
	profiler.Stop("OvaleEclipse_ApplySpellStartCast")
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleEclipse:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast)
	profiler.Start("OvaleEclipse_ApplySpellAfterCast")
	-- Instant or cast-time spells cost resources at the end of the spellcast.
	if not isChanneled then
		state:ApplyEclipseEnergy(spellId, endCast, spellcast.snapshot)
	end
	profiler.Stop("OvaleEclipse_ApplySpellAfterCast")
end
--</public-static-methods>

--<state-methods>
-- Update the state of the simulator for the eclipse energy gained by casting the given spell.
statePrototype.ApplyEclipseEnergy = function(state, spellId, atTime, snapshot)
	profiler.Start("OvaleEclipse_ApplyEclipseEnergy")
	if spellId == CELESTIAL_ALIGNMENT then
		local aura = state:AddAuraToGUID(self_guid, spellId, self_guid, "HELPFUL", atTime, atTime + 15, snapshot)
		aura.value1 = state:EclipseBonusDamage(atTime, snapshot)
		-- Celestial Alignment grants the spell effects of both Lunar and Solar Eclipse and
		-- also resets the total Eclipse energy to zero.
		state:AddEclipse(LUNAR_ECLIPSE, atTime, snapshot)
		state:AddEclipse(SOLAR_ECLIPSE, atTime, snapshot)
		state.eclipse = 0
		-- Remove any current Eclipse state.
		state:RemoveEclipse(LUNAR_ECLIPSE, atTime)
		state:RemoveEclipse(SOLAR_ECLIPSE, atTime)
	else
		local si = OvaleData.spellInfo[spellId]
		if si and si.eclipse then
			local power = state.eclipse
			local direction = state.eclipseDirection
			local energy = state:EclipseEnergy(spellId)

			-- Celestial Alignment prevents gaining Eclipse energy during its duration.
			local aura = state:GetAura("player", CELESTIAL_ALIGNMENT, "HELPFUL", true)
			if state:IsActiveAura(aura) then
				energy = 0
			end
			-- Only adjust the total Eclipse energy if the spell adds Eclipse energy in the current direction.
			if (direction <= 0 and energy < 0) or (direction >= 0 and energy > 0) then
				Ovale:Logf("[%s] Eclipse %d -> %d", OVALE_ECLIPSE_DEBUG, power, power + energy)
				power = power + energy

				-- Crossing zero energy removes the corresponding Eclipse state.
				if direction < 0 and power <= 0 then
					state:RemoveEclipse(SOLAR_ECLIPSE, atTime)
				elseif direction > 0 and power >= 0 then
					state:RemoveEclipse(LUNAR_ECLIPSE, atTime)
				end

				-- Clamp Eclipse energy to min/max values and note that an Eclipse state will be reached.
				if power <= -100 then
					power = -100
					direction = 1
					state:AddEclipse(LUNAR_ECLIPSE, atTime, snapshot)
				elseif power >= 100 then
					power = 100
					direction = -1
					state:AddEclipse(SOLAR_ECLIPSE, atTime, snapshot)
				end
			end

			state.eclipse = power
			state.eclipseDirection = direction
		end
	end
	profiler.Stop("OvaleEclipse_ApplyEclipseEnergy")
end

statePrototype.EclipseEnergy = function(state, spellId)
	local eclipseEnergy = 0
	local si = OvaleData.spellInfo[spellId]
	if si and si.eclipse then
		local energy = si.eclipse
		--[[
			eclipse = 0 means that the spell generates no Eclipse energy.
			eclipse < 0 means that the spell generates Lunar energy.
			eclipse > 0 means that the spell generates Solar energy.
		--]]
		if energy ~= "0" then
			-- If there is no Eclipse direction yet, then start moving in the direction generated
			-- by the energy of the spellcast.
			local direction = state.eclipseDirection
			if direction == 0 then
				direction = (energy < 0) and -1 or 1
			end
			-- If "eclipsedir" is set, then the spell adds energy in the current direction.
			if si.eclipsedir then
				energy = energy * direction
			end
			-- Euphoria: While not in an Eclipse state, your spells generate double the normal
			-- amount of Solar or Lunar energy.
			if OvaleSpellBook:IsKnownSpell(EUPHORIA) then
				local lunar = state:GetAura("player", LUNAR_ECLIPSE, "HELPFUL", true)
				local solar = state:GetAura("player", SOLAR_ECLIPSE, "HELPFUL", true)
				if not state:IsActiveAura(lunar) and not state:IsActiveAura(solar) then
					energy = energy * 2
				end
			end
			eclipseEnergy = energy
		end
	end
	return eclipseEnergy
end

statePrototype.EclipseBonusDamage = function(state, atTime, snapshot)
	-- Base Eclipse bonus (percent) to damage.
	local bonus = 15
	-- Add in mastery bonus to Eclipse damage.
	bonus = bonus + snapshot.masteryEffect
	-- Add in bonus from Dream of Cenarius.
	if OvaleSpellBook:GetTalentPoints(DREAM_OF_CENARIUS_TALENT) > 0 then
		local aura = state:GetAura("player", DREAM_OF_CENARIUS, "HELPFUL", true)
		if state:IsActiveAura(aura, atTime) then
			bonus = bonus + 25
		end
	end
	return bonus
end

statePrototype.AddEclipse = function(state, eclipseId, atTime, snapshot)
	if eclipseId == LUNAR_ECLIPSE or eclipseId == SOLAR_ECLIPSE then
		local eclipseName = (eclipseId == LUNAR_ECLIPSE) and "Lunar" or "Solar"
		Ovale:Logf("[%s] Adding %s Eclipse (%d) at %f", OVALE_ECLIPSE_DEBUG, eclipseName, eclipseId, atTime)
		local aura = state:AddAuraToGUID(self_guid, eclipseId, self_guid, "HELPFUL", atTime, math.huge, snapshot)
		-- Set the value of the Eclipse aura to the Eclipse's bonus damage.
		aura.value1 = state:EclipseBonusDamage(atTime, snapshot)
		-- Reaching Eclipse state grants Nature's Grace.
		state:AddAuraToGUID(self_guid, NATURES_GRACE, self_guid, "HELPFUL", atTime, atTime + 15, snapshot)
		-- Reaching Lunar Eclipse resets the cooldown of Starfall.
		if eclipseId == LUNAR_ECLIPSE then
			state:ResetSpellCooldown(STARFALL, atTime)
		end
	end
end

statePrototype.RemoveEclipse = function(state, eclipseId, atTime)
	if eclipseId == LUNAR_ECLIPSE or eclipseId == SOLAR_ECLIPSE then
		state:RemoveAuraOnGUID(self_guid, eclipseId, "HELPFUL", true, atTime)
	end
end
--</state-methods>
