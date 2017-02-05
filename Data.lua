--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleData = Ovale:NewModule("OvaleData")
Ovale.OvaleData = OvaleData

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleGUID = nil
local OvalePaperDoll = nil
local OvaleState = nil

local format = string.format
local type = type
local pairs = pairs
local strfind = string.find
local tonumber = tonumber
local wipe = wipe
local INFINITY = math.huge

-- Registered "run-time requirement" handlers: self_requirement[name] = handler
-- Handler is invoked as handler(state, name, tokens, index, targetGUID).
local self_requirement = {}

local STAT_NAMES = { "agility", "bonus_armor", "critical_strike", "haste", "intellect", "mastery", "multistrike", "spirit", "spellpower", "strength", "versatility" }
local STAT_SHORTNAME = {
	agility = "agi",
	critical_strike = "crit",
	intellect = "int",
	strength = "str",
	spirit = "spi",
}
local STAT_USE_NAMES = { "trinket_proc", "trinket_stacking_proc", "trinket_stacking_stat", "trinket_stat" }
--<private-static-properties>

--<public-static-properties>
-- Export stat tables.
OvaleData.STAT_NAMES = STAT_NAMES
OvaleData.STAT_SHORTNAME = STAT_SHORTNAME
OvaleData.STAT_USE_NAMES = STAT_USE_NAMES

-- Item information from the current script (by item ID).
OvaleData.itemInfo = {}
-- Item lists.
OvaleData.itemList = {}
-- Spell information from the current script (by spell ID).
OvaleData.spellInfo = {}
-- Spell lists.
OvaleData.buffSpellList = {
	-- Debuffs
	fear_debuff = {
		[  5246] = true, -- Intimidating Shout
		[  5484] = true, -- Howl of terror
		[  5782] = true, -- Fear
		[  8122] = true, -- Psychic scream
	},
	incapacitate_debuff = {
		[  6770] = true, -- Sap
		[ 12540] = true, -- Gouge
		[ 20066] = true, -- Repentance
		[137460] = true, -- Incapacitated
	},
	root_debuff = {
		[   122] = true, -- Frost Nova
		[   339] = true, -- Entangling Roots
	},
	stun_debuff = {
		[   408] = true, -- Kidney Shot
		[   853] = true, -- Hammer of Justice
		[  1833] = true, -- Cheap Shot
		[  5211] = true, -- Mighty Bash
		[ 46968] = true, -- Shockwave
	},

	-- Raid buffs
	attack_power_multiplier_buff = {
		[  6673] = true, -- Battle Shout (warrior)
		[ 19506] = true, -- Trueshot Aura (hunter)
		[ 57330] = true, -- Horn of Winter (death knight)
	},
	critical_strike_buff = {
		[  1459] = true, -- Arcane Brillance (mage)
		[ 24604] = true, -- Furious Howl (wolf)
		[ 24932] = true, -- Leader of the Pack (feral druid)
		[ 61316] = true, -- Dalaran Brilliance (mage)
		[ 90309] = true, -- Terrifying Roar (devilsaur)
		[ 90363] = true, -- Embrace of the Shale Spider (shale spider)
		[ 97229] = true, -- Bellowing Roar (hydra)
		[116781] = true, -- Legacy of the White Tiger (bremaster/windwalker monk)
		[126309] = true, -- Still Water (water strider)
		[126373] = true, -- Fearless Roar (quilen)
		[128997] = true, -- Spirit Beast Blessing (spirit beast)
		[160052] = true, -- Strength of the Pack (raptor)
		[160200] = true, -- Lone Wolf: Ferocity of the Raptor (hunter)
	},
	haste_buff = {
		[ 49868] = true, -- Mind Quickening (shadow priest)
		[ 55610] = true, -- Unholy Aura (frost/unholy death knight)
		[113742] = true, -- Swiftblade's Cunning (rogue)
		[128432] = true, -- Cackling Howl (hyena)
		[135678] = true, -- Energizing Spores (sporebat)
		[160003] = true, -- Savage Vigor (rylak)
		[160074] = true, -- Speed of the Swarm (wasp)
		[160203] = true, -- Lone Wolf: Haste of the Hyena (hunter)
	},
	mastery_buff = {
		[ 19740] = true, -- Blessing of Might (paladin)
		[ 24907] = true, -- Moonkin aura (balance druid)
		[ 93435] = true, -- Roar of Courage (cat)
		[116956] = true, -- Grace of Air (shaman)
		[128997] = true, -- Spirit Beast Blessing (spirit beast)
		[155522] = true, -- Power of the Grave (blood death knight)
		[160073] = true, -- Plainswalking (tallstrider)
		[160198] = true, -- Lone Wolf: Grace of the Cat (hunter)
	},
	multistrike_buff = {
		[ 24844] = true, -- Breath of the Winds (wind serpent)
		[ 34889] = true, -- Spry Attacks (dragonhawk)
		[ 49868] = true, -- Mind Quickening (shadow priest)
		[ 57386] = true, -- Wild Strength (clefthoof)
		[ 58604] = true, -- Double Bite (core hound)
		[109773] = true, -- Dark Intent (warlock)
		[113742] = true, -- Swiftblade's Cunning (rogue)
		[166916] = true, -- Windflurry (windwalker monks)
		[172968] = true, -- Lone Wolf: Quickness of the Dragonhawk (hunter)
	},
	spell_power_multiplier_buff = {
		[  1459] = true, -- Arcane Brilliance (mage)
		[ 61316] = true, -- Dalaran Brilliance (mage)
		[ 90364] = true, -- Qiraji Fortitude (silithid)
		[109773] = true, -- Dark Intent (warlock)
		[126309] = true, -- Still Water (water strider)
		[128433] = true, -- Serpent's Cunning (serpent)
		[160205] = true, -- Lone Wolf: Wisdom of the Serpent (hunter)
	},
	stamina_buff = {
		[   469] = true, -- Commanding Shout (warrior)
		[ 21562] = true, -- Power Word: Fortitude (priest)
		[ 50256] = true, -- Invigorating Roar (bear)
		[ 90364] = true, -- Qiraji Fortitude (silithid)
		[160003] = true, -- Savage Vigor (rylak)
		[160014] = true, -- Sturdiness (goat)
		[166928] = true, -- Blood Pact (warlock)
		[160199] = true, -- Lone Wolf: Fortitude of the Bear (hunter)
	},
	str_agi_int_buff = {
		[  1126] = true, -- Mark of the Wild (druid)
		[ 20217] = true, -- Blessing of Kings (paladin)
		[ 90363] = true, -- Embrace of the Shale Spider (shale spider)
		[115921] = true, -- Legacy of the Emperor (mistweaver monk)
		[116781] = true, -- Legacy of the White Tiger (brewmaster/windwalker monk)
		[159988] = true, -- Bark of the Wild (dog, riverbeast)
		[160017] = true, -- Blessing of Kongs (gorilla)
		[160077] = true, -- Strength of the Earth (worm)
		[160206] = true, -- Lone Wolf: Power of the Primates (hunter)
	},
	versatility_buff = {
		[  1126] = true, -- Mark of the Wild (druid)
		[ 35290] = true, -- Indomitable (boar)
		[ 50518] = true, -- Chitinous Armor (ravager)
		[ 55610] = true, -- Unholy Aura (frost/unholy death knight)
		[ 57386] = true, -- Wild Strength (clefthoof)
		[159735] = true, -- Tenacity (bird of prey)
		[160045] = true, -- Defensive Quills (porcupine)
		[160077] = true, -- Strength of the Earth (worm)
		[167187] = true, -- Sanctity Aura (retribution paladins)
		[167188] = true, -- Inspiring Presence (arms/fury warriors)
		[172967] = true, -- Lone Wolf: Versatility of the Ravager (hunter)
	},

	-- Target debuffs
	bleed_debuff = {
		[  1079] = true, -- Rip (feral druid)
		[ 16511] = true, -- Hemorrhage (subtlety rogue)
		[ 33745] = true, -- Lacerate (guardian druid)
		[ 77758] = true, -- Thrash (druid)
		[113344] = true, -- Bloodbath (warrior)
		[115767] = true, -- Deep Wounds (warrior)
		[122233] = true, -- Crimson Tempest (rogue)
		[154953] = true, -- Internal Bleeding (rogue)
		[155722] = true, -- Rake (cat druid)
	},
	healing_reduced_debuff = {
		[  8680] = true, -- Wound Poison (rogue)
		[ 54680] = true, -- Monstrous Bite (devilsaur)
		[115625] = true, -- Mortal Cleave (wrathguard)
		[115804] = true, -- Mortal Wounds (arms/fury warriors, windwalker monk, warlock, carrion bird, scorpid)
	},

	-- Target buffs
	stealthed_buff = {
		[  1784] = true, -- Stealth
		[  5215] = true, -- Prowl
		[ 11327] = true, -- Vanish
		[ 24450] = true, -- Prowl (cat)
		[ 58984] = true, -- Shadowmeld
		[ 90328] = true, -- Spirit Walk (spirit beast)
		[102543] = true, -- Incarnation: King of the Jungle (feral druid); not truly "stealth" but functions like it for spell usage.
		[148523] = true, -- Jade Mist
		[115191] = true, -- Stealth (Subterfuge-talented rogue)
		[115192] = true, -- Subterfuge (rogue); not truly "stealth" but functions like it for spell usage.
		[115193] = true, -- Vanish (Subterfuge-talented rogue)
		[185422] = true, -- Shadow Dance (subtlety rogue); not truly "stealth" but functions like it for spell usage.
	},

	-- Raid buffs (short term)
	burst_haste_buff = {
		[  2825] = true, -- Bloodlust (Horde shaman)
		[ 32182] = true, -- Heroism (Alliance shaman)
		[ 80353] = true, -- Time Warp (mage)
		[ 90355] = true, -- Ancient Hysteria (core hound, nether ray)
	},
	burst_haste_debuff = {
		[ 57723] = true, -- Exhaustion (Heroism)
		[ 57724] = true, -- Sated (Bloodlust)
		[ 80354] = true, -- Temporal Displacement (Time Warp)
		[ 95809] = true, -- Insanity (Ancient Hysteria)
	},
	raid_movement_buff = {
		[106898] = true, -- Stampeding Roar
	},
}
-- Add trinket lists to buffSpellList.
do
	for _, useName in pairs(STAT_USE_NAMES) do
		local name
		for _, statName in pairs(STAT_NAMES) do
			name = useName .. "_" .. statName .. "_buff"
			OvaleData.buffSpellList[name] = {}
			local shortName = STAT_SHORTNAME[statName]
			if shortName then
				name = useName .. "_" .. shortName .. "_buff"
				OvaleData.buffSpellList[name] = {}
			end
		end
		name = useName .. "_any_buff"
		OvaleData.buffSpellList[name] = {}
	end
end

-- Create table of default spell lists.
OvaleData.DEFAULT_SPELL_LIST = {}
do
	for name in pairs(OvaleData.buffSpellList) do
		OvaleData.DEFAULT_SPELL_LIST[name] = true
	end
end

-- Unused public property to suppress lint warnings.
--OvaleData.defaultTarget = nil
--</public-static-properties>

--<public-static-methods>
function OvaleData:OnInitialize()
	-- Resolve module dependencies.
	OvaleGUID = Ovale.OvaleGUID
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvaleState = Ovale.OvaleState

end

function OvaleData:OnEnable()
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvaleData:OnDisable()
	OvaleState:UnregisterState(self)
end

function OvaleData:RegisterRequirement(name, method, arg)
	self_requirement[name] = { method, arg }
end

function OvaleData:UnregisterRequirement(name)
	self_requirement[name] = nil
end

function OvaleData:Reset()
	wipe(self.itemInfo)
	wipe(self.spellInfo)
	for k, v in pairs(self.buffSpellList) do
		if not self.DEFAULT_SPELL_LIST[k] then
			-- Remove all non-default spell lists.
			wipe(v)
			self.buffSpellList[k] = nil
		elseif strfind(k, "^trinket_") then
			-- Clear all trinket lists.
			wipe(v)
		end
	end
end

--[[
	Return the exact spell info table for the given spell, creating a new table entry if necessary.
	This method should only be used by modules that need to directly manipulate the table without
	incurring the overhead of function calls.
--]]
function OvaleData:SpellInfo(spellId)
	local si = self.spellInfo[spellId]
	if not si then
		si = {
			aura = {
				-- Auras applied by this spell on the player.
				player = {},
				-- Auras applied by this spell on its target.
				target = {},
				-- Auras applied by this spell on the player's pet.
				pet = {},
				-- Auras granting extra damage multipliers for this spell.
				damage = {},
			},
			require = {},
		}
		self.spellInfo[spellId] = si
	end
	return si
end

function OvaleData:GetSpellInfo(spellId)
	if type(spellId) == "number" then
		return self.spellInfo[spellId]
	elseif self.buffSpellList[spellId] then
		for auraId in pairs(self.buffSpellList[spellId]) do
			if self.spellInfo[auraId] then
				return self.spellInfo[auraId]
			end
		end
	end
end

function OvaleData:ItemInfo(itemId)
	local ii = self.itemInfo[itemId]
	if not ii then
		ii = {
			require = {},
		}
		self.itemInfo[itemId] = ii
	end
	return ii
end

-- Returns the tag for the item and whether the item invokes the GCD.
function OvaleData:GetItemTagInfo(spellId)
	-- Assume all items are on a long cooldown and do not invoke the GCD.
	return "cd", false
end

-- Returns the tag for the spell and whether the spell invokes the GCD.
function OvaleData:GetSpellTagInfo(spellId)
	local tag = "main"
	local invokesGCD = true

	local si = self.spellInfo[spellId]
	if si then
		invokesGCD = not si.gcd or si.gcd > 0
		tag = si.tag
		if not tag then
			local cd = si.cd
			if cd then
				if cd > 90 then
					tag = "cd"
				elseif cd > 29 or not invokesGCD then
					tag = "shortcd"
				end
			elseif not invokesGCD then
				tag = "shortcd"
			end
			si.tag = tag
		end
		tag = tag or "main"
	end
	return tag, invokesGCD
end

-- Check "run-time" requirements specified in SpellRequire().
-- NOTE: Mirrored in statePrototype below.

-- TODO: find a better way to pass spellId or itemId as the first param
--       reason: OvaleData:GetItemInfoProperty also calls CheckRequirements but with itemId as first param
function OvaleData:CheckRequirements(spellId, atTime, tokens, index, targetGUID)
	targetGUID = targetGUID or OvaleGUID:UnitGUID(self.defaultTarget or "target")
	local name = tokens[index]
	index = index + 1
	if name then
		self:Log("Checking requirements:")
		local verified = true
		local requirement = name
		while verified and name do
			local handler = self_requirement[name]
			if handler then
				local method = handler[1]
				local arg = self[method] and self or handler[2]
				verified, requirement, index = arg[method](arg, spellId, atTime, name, tokens, index, targetGUID)
				name = tokens[index]
				index = index + 1
			else
				Ovale:OneTimeMessage("Warning: requirement '%s' has no registered handler; FAILING requirement.", name)
				verified = false
			end
		end
		return verified, requirement, index
	end
	return true
end

--[[
	For spell aura lists described by SpellAddBuff(), etc., use the following interpretation:
		auraId=count,N		N is number of stacks to be set
		auraId=extend,N		aura is extended by N seconds, no change to stacks
		auraId=refresh		aura is refreshed, no change to stacks
		auraId=refresh_keep_snapshot
							aura is refreshed and the snapshot is carried over from the previous aura.
		auraId=toggle		aura is toggled on or off by the spell.
		auraId=N, N > 0		N is number of stacks added
		auraId=0			aura is removed
		auraId=N, N < 0		N is number of stacks of aura removed

	NOTE: Mirrored in statePrototype below.
--]]
function OvaleData:CheckSpellAuraData(auraId, spellData, atTime, guid)
	guid = guid or OvaleGUID:UnitGUID("player")
	local index, value, data
	if type(spellData) == "table" then
		-- Comma-separated value.
		value = spellData[1]
		index = 2
	else
		value = spellData
	end
	if value == "count" then
		-- Advance past the number of stacks of the aura.
		local N
		if index then
			N = spellData[index]
			index = index + 1
		end
		if N then
			data = tonumber(N)
		else
			Ovale:OneTimeMessage("Warning: '%d' has '%s' missing final stack count.", auraId, value)
		end
	elseif value == "extend" then
		-- Advance past the number of seconds to extend the aura.
		local seconds
		if index then
			seconds = spellData[index]
			index = index + 1
		end
		if seconds then
			data = tonumber(seconds)
		else
			Ovale:OneTimeMessage("Warning: '%d' has '%s' missing duration.", auraId, value)
		end
	else
		local asNumber = tonumber(value)
		value = asNumber or value
	end
	-- Verify any run-time requirements for this aura.
	local verified = true
	if index then
		verified = self:CheckRequirements(auraId, atTime, spellData, index, guid)
	end
	return verified, value, data
end

-- Check "run-time" requirements specified in SpellInfo().
-- NOTE: Mirrored in statePrototype below.
function OvaleData:CheckSpellInfo(spellId, atTime, targetGUID)
	targetGUID = targetGUID or OvaleGUID:UnitGUID(self.defaultTarget or "target")
	local verified = true
	local requirement
	for name, handler in pairs(self_requirement) do
		local value = self:GetSpellInfoProperty(spellId, atTime, name, targetGUID)
		if value then
			local method, arg = handler[1], handler[2]
			-- Check for inherited/mirrored method first (for statePrototype).
			arg = self[method] and self or arg
			local index = (type(value) == "table") and 1 or nil
			verified, requirement = arg[method](arg, spellId, atTime, name, value, index, targetGUID)
			if not verified then
				break
			end
		end
	end
	return verified, requirement
end

function OvaleData:GetItemInfoProperty(itemId, atTime, property)
	targetGUID = OvaleGUID:UnitGUID("player")
	local ii = OvaleData:ItemInfo(itemId)
	local value = ii and ii[property]

	local requirements = ii and ii.require[property]
	if requirements then
		for v, requirement in pairs(requirements) do
			local verified = self:CheckRequirements(itemId, atTime, requirement, 1, targetGUID)
			if verified then
				value = tonumber(v) or v
				break
			end
		end
	end

	return value 
end
-- Get SpellInfo property with run-time checks as specified in SpellRequire().
-- NOTE: Mirrored in statePrototype below.
function OvaleData:GetSpellInfoProperty(spellId, atTime, property, targetGUID)
	targetGUID = targetGUID or OvaleGUID:UnitGUID(self.defaultTarget or "target")
	local si = OvaleData.spellInfo[spellId]
	local value = si and si[property]

	local requirements = si and si.require[property]
	if requirements then
		for v, requirement in pairs(requirements) do
			local verified = self:CheckRequirements(spellId, atTime, requirement, 1, targetGUID)
			if verified then
				value = tonumber(v) or v
				break
			end
		end
	end

	if not value or not tonumber(value) then return value end

	local ratio = si and si[property .. "_percent"]
	if ratio then
		ratio = ratio / 100
	else
		ratio = 1
	end
	
	local multipliers = si and si.require[property .. '_percent']
	if multipliers then
		for v, requirement in pairs(multipliers) do
			local verified = self:CheckRequirements(spellId, atTime, requirement, 1, targetGUID)
			if verified then
				ratio = ratio * (tonumber(v) or v) / 100
			end
		end
	end

	return value * ratio
end

--Compute the damage of the given spell.
function OvaleData:GetDamage(spellId, attackpower, spellpower, mainHandWeaponDamage, offHandWeaponDamage, combo)
	local si = self.spellInfo[spellId]
	if not si then
		return nil
	end
	local damage = si.base or 0
	attackpower = attackpower or 0
	spellpower = spellpower or 0
	mainHandWeaponDamage = mainHandWeaponDamage or 0
	offHandWeaponDamage = offHandWeaponDamage or 0
	combo = combo or 0
	if si.bonusmainhand then
		damage = damage + si.bonusmainhand * mainHandWeaponDamage
	end
	if si.bonusoffhand then
		damage = damage + si.bonusoffhand * offHandWeaponDamage
	end
	if si.bonuscp then
		damage = damage + si.bonuscp * combo
	end
	if si.bonusap then
		damage = damage + si.bonusap * attackpower
	end
	if si.bonusapcp then
		damage = damage + si.bonusapcp * attackpower * combo
	end
	if si.bonussp then
		damage = damage + si.bonussp * spellpower
	end
	return damage
end

-- Returns the base duration of an aura.
function OvaleData:GetBaseDuration(auraId, spellcast)
	local combo = spellcast and spellcast.combo
	local holy = spellcast and spellcast.holy
	local duration = INFINITY
	local si = OvaleData.spellInfo[auraId]
	if si and si.duration then
		duration = si.duration
		if si.addduration then
			duration = duration + si.addduration
		end
		if si.adddurationcp and combo then
			duration = duration + si.adddurationcp * combo
		end
		if si.adddurationholy and holy then
			duration = duration + si.adddurationholy * (holy - 1)
		end
	end
	return duration
end

-- Returns the length in seconds of a tick of the periodic aura.
function OvaleData:GetTickLength(auraId, snapshot)
	local tick = 3
	local si = OvaleData.spellInfo[auraId]
	if si then
		tick = si.tick or tick
		local hasteMultiplier = OvalePaperDoll:GetHasteMultiplier(si.haste, snapshot)
		tick = tick / hasteMultiplier
	end
	return tick
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleData.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleData.statePrototype
--</private-static-properties>

--<state-methods>
-- Mirrored methods.
statePrototype.CheckRequirements = OvaleData.CheckRequirements
statePrototype.CheckSpellAuraData = OvaleData.CheckSpellAuraData
statePrototype.CheckSpellInfo = OvaleData.CheckSpellInfo
statePrototype.GetItemInfoProperty = OvaleData.GetItemInfoProperty
statePrototype.GetSpellInfoProperty = OvaleData.GetSpellInfoProperty
--</state-methods>
