--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleData = Ovale:NewModule("OvaleData")
Ovale.OvaleData = OvaleData

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvalePaperDoll = nil
--<private-static-properties>

--<public-static-properties>
OvaleData.itemList = {}
--spell info from the current script (by spellId)
OvaleData.spellInfo = {}

OvaleData.buffSpellList =
{
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
		[160052] = true, -- Strength of the Pack (raptor)
	},
	haste_buff = {
		[ 49868] = true, -- Mind Quickening (shadow priest)
		[ 55610] = true, -- Unholy Aura (frost/unholy death knight)
		[113742] = true, -- Swiftblade's Cunning (rogue)
		[128432] = true, -- Cackling Howl (hyena)
		[135678] = true, -- Energizing Spores (sporebat)
		[160003] = true, -- Savage Vigor (rylak)
		[160074] = true, -- Speed of the Swarm (wasp)
	},
	mastery_buff = {
		[ 19740] = true, -- Blessing of Might (paladin)
		[ 24907] = true, -- Moonkin aura (balance druid)
		[ 93435] = true, -- Roar of Courage (cat)
		[116956] = true, -- Grace of Air (shaman)
		[128997] = true, -- Spirit Beast Blessing (spirit beast)
		[155522] = true, -- Power of the Grave (blood death knight)
		[160073] = true, -- Plainswalking (tallstrider)
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
	},
	spell_power_multiplier_buff = {
		[  1459] = true, -- Arcane Brilliance (mage)
		[ 61316] = true, -- Dalaran Brilliance (mage)
		[ 90364] = true, -- Qiraji Fortitude (silithid)
		[109773] = true, -- Dark Intent (warlock)
		[126309] = true, -- Still Water (water strider)
		[128433] = true, -- Serpent's Cunning (serpent)
	},
	stamina_buff = {
		[   469] = true, -- Commanding Shout (warrior)
		[ 21562] = true, -- Power Word: Fortitude (priest)
		[ 50256] = true, -- Invigorating Roar (bear)
		[ 90364] = true, -- Qiraji Fortitude (silithid)
		[160003] = true, -- Savage Vigor (rylak)
		[160014] = true, -- Sturdiness (goat)
		[166928] = true, -- Blood Pact (warlock)
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
		[115804] = true, -- Mortal Wounds (arms/fury warriors, windwalker monk, warlock, carrion bird, scorpid)
	},

	-- Target buffs
	enrage_buff = {
		[ 12880] = true, -- Enrage (warrior)
		[ 18499] = true, -- Berserker Rage (warrior)
	},
	stealthed_buff = {
		[  1784] = true, -- Stealth
		[  5215] = true, -- Prowl
		[ 11327] = true, -- Vanish
		[ 24450] = true, -- Prowl (cat)
		[ 51713] = true, -- Shadow Dance (subtlety rogue); not truly "stealth" but functions like it for spell usage.
		[ 58984] = true, -- Shadowmeld
		[ 90328] = true, -- Spirit Walk (spirit beast)
		[102543] = true, -- Incarnation: King of the Jungle (feral druid); not truly "stealth" but functions like it for spell usage.
		[148523] = true, -- Jade Mist
		[115191] = true, -- Stealth (Subterfuge-talented rogue)
		[115192] = true, -- Subterfuge (rogue); not truly "stealth" but functions like it for spell usage.
		[115193] = true, -- Vanish (Subterfuge-talented rogue)
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
-- Deprecated: spell list aliases
do
	local list = OvaleData.buffSpellList
	list.attack_power_multiplier	= list.attack_power_multiplier_buff
	list.bleed						= list.bleed_debuff
	list.bloodlust					= list.burst_haste_buff
	list.bloodlust_aura				= list.burst_haste_buff
	list.burst_haste				= list.burst_haste_buff
	list.cast_slow					= list.cast_slow_debuff
	list.critical_strike			= list.critical_strike_buff
	list.enrage						= list.enrage_buff
	list.fear						= list.fear_debuff
	list.healing_reduced			= list.healing_reduced_debuff
	list.heroism					= list.burst_haste_buff
	list.heroism_aura				= list.burst_haste_buff
	list.incapacitate				= list.incapacitate_debuff
	list.lower_physical_damage		= list.lower_physical_damage_debuff
	list.magic_vulnerability		= list.magic_vulnerability_debuff
	list.mastery					= list.mastery_buff
	list.melee_haste				= list.attack_speed_buff
	list.physical_vulnerability		= list.physical_vulnerability_debuff
	list.raid_movement				= list.raid_movement_buff
	list.ranged_vulnerability		= list.ranged_vulnerability_debuff
	list.root						= list.root_debuff
	list.spell_haste				= list.spell_haste_buff
	list.spell_power_multiplier		= list.spell_power_multiplier_buff
	list.stamina					= list.stamina_buff
	list.str_agi_int				= list.str_agi_int_buff
	list.stun						= list.stun_debuff
end
--</public-static-properties>

--<public-static-methods>
function OvaleData:OnInitialize()
	-- Resolve module dependencies.
	OvalePaperDoll = Ovale.OvalePaperDoll
end

function OvaleData:ResetSpellInfo()
	self.spellInfo = {}
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
				-- Auras granting extra damage multipliers for this spell.
				damage = {},
			},
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
	local combo, holy = spellcast.combo, spellcast.holy
	local duration = math.huge
	local si = OvaleData.spellInfo[auraId]
	if si and si.duration then
		duration = si.duration
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
		local hasteMultiplier = 1
		if si.haste then
			if si.haste == "spell" then
				hasteMultiplier = OvalePaperDoll:GetSpellHasteMultiplier(snapshot)
			elseif si.haste == "melee" then
				hasteMultiplier = OvalePaperDoll:GetMeleeHasteMultiplier(snapshot)
			end
			tick = tick / hasteMultiplier
		end
	end
	return tick
end
--</public-static-methods>
