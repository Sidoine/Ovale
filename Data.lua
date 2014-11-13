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
local OvaleState = nil

local format = string.format
local gmatch = string.gmatch
local type = type
local pairs = pairs
local tonumber = tonumber
local INFINITY = math.huge

-- Registered "run-time requirement" handlers: self_requirement[name] = handler
-- Handler is invoked as handler(state, name, tokenIterator, target).
local self_requirement = {}

local STAT_NAMES = { "agility", "bonus_armor", "crit", "haste", "intellect", "mastery", "multistrike", "spirit", "spellpower", "strength", "versatility" }
local TRINKET_USE_NAMES = { "proc", "stacking_proc", "stacking_stat", "stat" }
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

	-- Trinket buffs
	trinket_proc_agility_buff = {
--		[126554] = true, -- Bottle of Infinite Stars
		[126690] = true, -- PvP agility trinket (on-use)
		[126707] = true, -- PvP agility trinket (proc)
		[126708] = true, -- PvP agility trinket (proc)
--		[128984] = true, -- Relic of Xuen (agility)
--		[138699] = true, -- Vicious Talisman of the Shado-Pan Assault
--		[138938] = true, -- Bad Juju
		[146308] = true, -- Assurance of Consequence
		[146310] = true, -- Ticking Ebon Detonator
		[148896] = true, -- Sigil of Rampage
		[148903] = true, -- Haromm's Talisman
		[177597] = true, -- Lucky Double-Sided Coin (on-use)
	},
	trinket_proc_bonus_armor_buff = {
		[176873] = true, -- Tablet of Turnbuckle Teamwork (on-use)
		[177055] = true, -- Evergaze Arcane Eidolon
	},
	trinket_proc_crit_buff = {
--		[138963] = true, -- Unerring Vision of Lei-Shen
		[162916] = true, -- Skull of War
		[162918] = true, -- Knight's Badge
		[162920] = true, -- Sandman's Pouch
		[165532] = true, -- Bonemaw's Big Toe (on-use)
		[165532] = true, -- Voidmender's Shadowgem (on-use)
		[176979] = true, -- Immaculate Living Mushroom
		[176983] = true, -- Stoneheart Idol
		[177041] = true, -- Tectus' Beating Heart
		[177047] = true, -- Goren Soul Repository
	},
	trinket_proc_haste_buff = {
		[165531] = true, -- Fleshrender's Meathook (on-use)
		[165821] = true, -- Munificent Bonds of Fury
		[165821] = true, -- Spores of Alacrity
		[165821] = true, -- Witherbark's Branch
		[176875] = true, -- Shards of Nothing (on-use)
		[176879] = true, -- Emblem of Caustic Healing (on-use)
		[176882] = true, -- Turbulent Focusing Crystal (on-use)
		[176885] = true, -- Turbulent Seal of Defiance (on-use)
		[176938] = true, -- Formidable Relic of Blood
		[176944] = true, -- Formidable Censer of Faith
		[176981] = true, -- Furyheart Talisman
		[177036] = true, -- Meaty Dragonspine Trophy
		[177052] = true, -- Darmac's Unstable Talisman
	},
	trinket_proc_intellect_buff = {
--		[126577] = true, -- Light of the Cosmos
		[126683] = true, -- PvP intellect trinket (on-use)
		[126705] = true, -- PvP intellect trinket (proc)
--		[128985] = true, -- Relic of Yu'lon
--		[136082] = true, -- Shock-Charger/Static-Caster's Medallion
--		[138898] = true, -- Breath of the Hydra
--		[139133] = true, -- Cha-Ye's Essence of Brilliance (assume 20% crit chance)
		[146046] = true, -- Purified Bindings of Immerseus
		[148897] = true, -- Frenzied Crystal of Rage
		[148906] = true, -- Kardris' Toxic Totem
	},
	trinket_proc_mastery_buff = {
		[165485] = true, -- Kihra's Adrenaline Injector (on-use)
		[165535] = true, -- Kyrak's Vileblood Serum (on-use)
		[165535] = true, -- Tharbek's Lucky Pebble
		[165825] = true, -- Munificent Censer of Tranquility
		[165825] = true, -- Xeri'tac's Unhatched Egg Sac
		[165835] = true, -- Munificent Emblem of Terror
		[176876] = true, -- Pol's Blinded Eye (on-use)
		[176883] = true, -- Turbulent Vial of Toxin (on-use)
		[176884] = true, -- Turbulent Relic of Mendacity (on-use)
		[176940] = true, -- Formidable Jar of Doom
		[176942] = true, -- Formidable Orb of Putrescence
		[177044] = true, -- Horn of Screaming Spirits
		[177057] = true, -- Blast Furnace Door
	},
	trinket_proc_multistrike_buff = {
		[165542] = true, -- Gor'ashan's Lodestone Spike (on-use)
		[165838] = true, -- Coagulated Genesaur Blood
		[176874] = true, -- Vial of Convulsive Shadows
		[176878] = true, -- Beating Heart of the Mountain (on-use)
		[176881] = true, -- Turbulent Emblem (on-use)
		[176936] = true, -- Formidable Fang
		[176987] = true, -- Blackheart Enforcer's Medallion
		[177039] = true, -- Scales of Doom
		[177064] = true, -- Elementalist's Shielding Talisman
	},
	trinket_proc_spellpower_buff = {
		[177594] = true, -- Copeland's Clarity (on-use)
	},
	trinket_proc_spirit_buff = {
		[162914] = true, -- Winged Hourglass
		[177062] = true, -- Ironspike Chew Toy
	},
	trinket_proc_strength_buff = {
--		[126582] = true, -- Lei Shen's Final Orders
		[126679] = true, -- PvP strength trinket (on-use)
		[126700] = true, -- PvP strength trinket (proc)
		[126702] = true, -- PvP strength trinket (proc)
--		[128986] = true, -- Relic of Xuen (strength)
--		[138702] = true, -- Brutal Talisman of the Shado-Pan Assault
		[146245] = true, -- Evil Eye of Galakras
		[146250] = true, -- Thok's Tail Tip
		[148899] = true, -- Fusion-Fire Core
		[177189] = true, -- Scabbard of Kyanos
	},
	trinket_proc_versatility_buff = {
		[165534] = true, -- Enforcer's Stun Grenade (on-use)
		[165543] = true, -- Emberscale Talisman (on-use)
		[165543] = true, -- Ragewing's Firefang (on-use)
		[165840] = true, -- Leaf of the Ancient Protectors
		[165840] = true, -- Munificent Orb of Ice
		[165840] = true, -- Munificent Soul of Compassion
		[176976] = true, -- Mote of the Mountain
	},
	trinket_stacking_proc_agility_buff = {
--		[138756] = true, -- Renataki's Soul Charm
	},
	trinket_stacking_proc_crit_buff = {
		[146285] = true, -- Skeer's Bloodsoaked Talisman
		[177071] = true, -- Humming Blackiron Trigger
	},
	trinket_stacking_proc_haste_buff = {
		[177090] = true, -- Auto-Repairing Autoclave
		[177104] = true, -- Battering Talisman
	},
	trinket_stacking_proc_intellect_buff = {
--		[138786] = true, -- Wushoolay's Final Choice
		[146184] = true, -- Black Blood of Y'Shaarj
	},
	trinket_stacking_proc_multistrike_buff = {
		[177085] = true, -- Blackiron Micro Crucible
		[177098] = true, -- Forgemaster's Insignia
	},
	trinket_stacking_proc_strength_buff = {
--		[138759] = true, -- Fabled Feather of Ji-Kun
--		[138870] = true, -- Primordius' Talisman of Rage
	},
}
-- Spell list aliases.
do
	local list = OvaleData.buffSpellList

	-- Create default, empty lists for "trinket_(proc|stacking_proc|stacking_stat|stat)_<stat>_buff".
	for _, useName in pairs(TRINKET_USE_NAMES) do
		for _, statName in pairs(STAT_NAMES) do
			local name = format("trinket_%s_%s_buff", useName, statName)
			list[name] = list[name] or {}
		end
	end

	-- Default aliases from "trinket_(stacking_stat|stat)_<stat>_buff" to "trinket_(stacking_proc|proc)_<stat>_buff".
	for _, statName in pairs(STAT_NAMES) do
		local name = format("trinket_stacking_stat_%s_buff", statName)
		local alias = format("trinket_stacking_proc_%s_buff", statName)
		list[name] = list[name] or list[alias]
	end
	for _, statName in pairs(STAT_NAMES) do
		local name = format("trinket_stat_%s_buff", statName)
		local alias = format("trinket_proc_%s_buff", statName)
		list[name] = list[name] or list[alias]
	end

	-- Create lists for "trinket_(proc|stacking_proc|stacking_stat|stat)_any_buff".
	for _, useName in pairs(TRINKET_USE_NAMES) do
		local name = format("trinket_%s_any_buff", useName)
		list[name] = list[name] or {}
		for _, statName in pairs(STAT_NAMES) do
			local alias = format("trinket_%s_%s_buff", useName, statName)
			if list[alias] then
				for spellId in pairs(list[alias]) do
					list[name][spellId] = true
				end
			end
		end
	end

	-- Deprecated: spell list aliases.
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

--<private-static-methods>
--</private-static-methods>

--<public-static-methods>
function OvaleData:OnInitialize()
	-- Resolve module dependencies.
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

-- Check "run-time" requirements specified in SpellRequire().
-- NOTE: Mirrored in statePrototype below.
function OvaleData:CheckRequirements(spellId, tokenIterator, target)
	local name = tokenIterator()
	if name then
		self:Log("Checking requirements:")
		local verified = true
		local requirement = name
		while verified and name do
			local handler = self_requirement[name]
			if handler then
				local method, arg = handler[1], handler[2]
				-- Check for inherited/mirrored method first (for statePrototype).
				if self[method] then
					verified, requirement = self[method](self, spellId, name, tokenIterator, target)
				else
					verified, requirement = arg[method](arg, spellId, name, tokenIterator, target)
				end
				name = tokenIterator()
			else
				Ovale:OneTimeMessage("Warning: requirement '%s' has no registered handler; FAILING requirement.", name)
				verified = false
			end
		end
		return verified, requirement
	end
	return true
end

-- Check "run-time" requirements specified in SpellInfo().
-- NOTE: Mirrored in statePrototype below.
function OvaleData:CheckSpellInfo(spellId, target)
	local verified = true
	local requirement
	for name, handler in pairs(self_requirement) do
		local value = self:GetSpellInfoProperty(spellId, name, target)
		if value then
			local method, arg = handler[1], handler[2]
			-- Check for inherited/mirrored method first (for statePrototype).
			if self[method] then
				verified, requirement = self[method](self, spellId, name, gmatch(value, ".+"), target)
			else
				verified, requirement = arg[method](arg, spellId, name, gmatch(value, ".+"), target)
			end
			if not verified then
				break
			end
		end
	end
	return verified, requirement
end

-- Get SpellInfo property with run-time checks as specified in SpellRequire().
-- NOTE: Mirrored in statePrototype below.
function OvaleData:GetSpellInfoProperty(spellId, property, target)
	local si = OvaleData.spellInfo[spellId]
	local value = si and si[property]
	local requirements = si and si.require[property]
	if requirements then
		for v, requirement in pairs(requirements) do
			local tokenIterator = gmatch(requirement, "[^,]+")
			target = target or "target"
			local verified = self:CheckRequirements(spellId, tokenIterator, target)
			if verified then
				value = tonumber(v) or v
				break
			end
		end
	end
	return value
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
statePrototype.CheckSpellInfo = OvaleData.CheckSpellInfo
statePrototype.GetSpellInfoProperty = OvaleData.GetSpellInfoProperty
--</state-methods>
