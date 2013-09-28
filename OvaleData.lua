--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleData = {}
Ovale.OvaleData = OvaleData

--<private-static-properties>
local API_GetSpellCooldown = GetSpellCooldown

-- Auras that are refreshed by spells that don't trigger a new snapshot.
self_buffNoSnapshotSpellList =
{
	-- Rip (druid)
	[1079] =
	{
		[5221] = true,		-- Shred
		[6785] = true,		-- Ravage
		[22568] = true,		-- Ferocious Bite (target below 25%)
		[33876] = true,		-- Mangle
		[102545] = true,	-- Ravage!
		[114236] = true,	-- Shred!
	},
	-- Blood Plague (death knight)
	[55078] =
	{
		[85948] = true,		-- Festering Strike (unholy)
	},
	-- Frost Fever (death knight)
	[55095] =
	{
		[85948] = true,		-- Festering Strike (unholy)
	},
}
--</private-static-properties>

--<public-static-properties>
OvaleData.itemList = {}
--spell info from the current script (by spellId)
OvaleData.spellInfo = {}
--spells that count for scoring
OvaleData.scoreSpell = {}

OvaleData.buffSpellList =
{
	-- Debuffs
	fear =
	{
		[5782] = true, -- Fear
		[5484] = true, -- Howl of terror
		[5246] = true, -- Intimidating Shout
		[8122] = true, -- Psychic scream
	},
	incapacitate =
	{
		[6770] = true, -- Sap
		[12540] = true, -- Gouge
		[20066] = true, -- Repentance
	},
	root =
	{
		[23694] = true, -- Improved Hamstring
		[339] = true, -- Entangling Roots
		[122] = true, -- Frost Nova
		[47168] = true, -- Improved Wing Clip
	},
	stun = 
	{
		[5211] = true, -- Bash
		[44415] = true, -- Blackout
		[6409] = true, -- Cheap Shot
		[22427] = true, -- Concussion Blow
		[853] = true, -- Hammer of Justice
		[408] = true, -- Kidney Shot
		[46968] = true, -- Shockwave
	},

	-- Raid buffs
	attack_power_multiplier=
	{
		[6673] = true, -- Battle Shout (warrior)
		[19506] = true, -- Trueshot Aura (hunter)
		[57330] = true, -- Horn of Winter (death knight)
	},
	critical_strike =
	{
		[1459] = true, -- Arcane Brillance (mage)
		[24604] = true, -- Furious Howl (wolf)
		[24932] = true, -- Leader of the Pack (feral & guardian druids)
		[61316] = true, -- Dalaran Brilliance (mage)
		[90309] = true, -- Terrifying Roar (devilsaur)
		[97229] = true, -- Bellowing Roar (hydra)
		[116781] = true, -- Legacy of the White Tiger (windwalker monk)
		[126309] = true, -- Still Water (waterstrider)
		[126373] = true, -- Fearless Roar (quilen)
	},
	mastery =
	{
		[19740] = true, -- Blessing of Might (paladin)
		[93435] = true, -- Roar of Courage (cat)
		[116956] = true, -- Grace of Air (shaman)
		[128997] = true, -- Spirit Beast Blessing (spirit beast)
	},
	melee_haste =
	{
		[30809] = true, -- Unleashed Rage (enhancement shaman)
		[55610] = true, -- Unholy Aura (frost & unholy death knights)
		[113742] = true, -- Swiftblade's Cunning (rogue)
		[128432] = true, -- Cackling Howl (hyena)
		[128433] = true, -- Serpent's Swiftness (serpent)
	},
	spell_power_multiplier = 
	{
		[1459] = true, -- Arcane Brillancen (mage)
		[61316] = true, -- Dalaran Brilliance (mage)
		[77747] = true, -- Burning Wrath (shaman)
		[109773] = true,  -- Dark Intent (warlock)
		[126309] = true, -- Still Water (waterstrider)
	},
	stamina =
	{
		[469] = true, -- Commanding Shout (warrior)
		[21562] = true, -- Power Word: Fortitude (priest)
		[90364] = true, -- Qiraji Fortitude (silithid)
		[109773] = true,  -- Dark Intent (warlock)
	},
	str_agi_int =
	{
		[1126] = true, -- Mark of the Wild (druid)
		[20217] = true, -- Blessing of Kings (paladin)
		[90363] = true, -- Embrace of the Shale Spider (shale spider)
		[117666] = true, -- Legacy of the Emporer (monk)
	},
	spell_haste = 
	{
		[24907] = true, -- Moonkin aura (balance druid)
		[49868] = true, -- Mind Quickening (shadow priest)
		[51470] = true, -- Elemental Oath (elemental shaman)
		[135678] = true, -- Energizing Spores (sporebat)
	},

	-- Target debuffs
	bleed =
	{
		[1079] = true, -- Rip (feral druid)
		[1822] = true, -- Rake (cat druid)
		[9007] = true, -- Pounce Bleed (cat druid)
		[33745] = true, -- Lacerate (bear druid)
		[63468] = true, -- Piercing Shots (marksmanship hunter)
		[77758] = true, -- Thrash (bear druid)
		[103830] = true, -- Thrash (cat druid)
		[113344] = true, -- Bloodbath (warrior)
		[115767] = true, -- Deep Wounds (warrior)
		[120699] = true, -- Lynx Rush (hunter)
		[122233] = true, -- Crimson Tempest (rogue)
	},
	cast_slow =
	{
		[5760] = true, -- Mind-numbing Poison (rogue)
		[31589] = true, -- Slow (arcane mage)
		[50274] = true, -- Spore Cloud (sporebat)
		[58604] = true, -- Lava Breath (core hound)
		[73975] = true, -- Necrotic Strike (death knight)
		[90315] = true, -- Tailspin (fox)
		[109466] = true, -- Curse of Enfeeblement (warlock)
		[126406] = true, -- Trample (goat)
	},
	healing_reduced =
	{
		[8680] = true, -- Wound Poison (rogue)
		[54680] = true, -- Monstrous Bite (devilsaur)
		[82654] = true, -- Widow Venom (hunter)
		[115804] = true, -- Mortal Wounds (arms & fury warriors, windwalker monk, warlock)
	},
	lower_physical_damage=
	{
		[24423] = true, -- Demoralizing Screech (carrion bird)
		[50256] = true, -- Demoralizing Roar (bear)
		[115798] = true, -- Weakened Blows (all tank specs, feral druid, retribution paladin, shaman, warlock, warrior)
	},
	magic_vulnerability=
	{
		[1490] = true, -- Curse of the Elements (warlock)
		[24844] = true, -- Lightning Breath (wind serpent)
		[34889] = true, -- Fire Breath (dragonhawk)
		[93068] = true, -- Master Poisoner (rogue)
		[104225] = true, -- Soulburn: Curse of the Elements (warlock)
		[116202] = true, -- Aura of the Elements (warlock)
	},
	physical_vulnerability=
	{
		[35290] = true, -- Gore (boar)
		[50518] = true, -- Ravage (ravager)
		[55749] = true, -- Acid Spit (worm)
		[57386] = true, -- Stampede (rhino)
		[81326] = true, -- Physical Vulnerability (frost & unholy death knights, retribution paladin, arms & fury warriors)
	},
	ranged_vulnerability =
	{
		[1130] = true, -- Hunter's Mark
	},

	-- Target buffs
	enrage =
	{
		[12292] = true, -- Bloodbath (warrior)
		[12880] = true, -- Enrage (warrior)
		[18499] = true, -- Berserker Rage (warrior)
		[49016] = true, -- Unholy Frenzy (death knight)
		[76691] = true, -- Vengeance (all tank specs)
		[132365] = true, -- Vengeance (all tank specs)
	},

	-- Raid buffs (short term)
	burst_haste =
	{
		[2825] = true, --Bloodlust (Horde shaman)
		[32182] = true, --Heroism (Alliance shaman)
		[80353] = true, --Time Warp (mage)
		[90355] = true, -- Ancient Hysteria (core hound)
	},
	burst_haste_debuff =
	{
		[57723] = true, -- Exhaustion (Heroism)
		[57724] = true, -- Sated (Bloodlust)
		[80354] = true, -- Temporal Displacement (Time Warp)
		[95809] = true, -- Insanity (Ancient Hysteria)
	},
	raid_movement =
	{
		[106898] = true, -- Stampeding Roar
	}
}
OvaleData.buffSpellList.bloodlust_aura = OvaleData.buffSpellList.burst_haste
OvaleData.buffSpellList.bloodlust = OvaleData.buffSpellList.burst_haste
OvaleData.buffSpellList.heroism_aura = OvaleData.buffSpellList.burst_haste
OvaleData.buffSpellList.heroism = OvaleData.buffSpellList.burst_haste
--</public-static-properties>

--<public-static-methods>
function OvaleData:GetSpellInfo(spellId)
	if (not self.spellInfo[spellId]) then
		self.spellInfo[spellId] =
		{
			aura = {player = {}, target = {}},
			damageAura = {},
		}
	end
	return self.spellInfo[spellId]
end

function OvaleData:ResetSpellInfo()
	self.spellInfo = {}
end

-- Returns true if spellId triggers a fresh snapshot for auraSpellId.
-- TODO: Handle spreading DoTs (Inferno Blast, etc.) and Soul Swap effects.
function OvaleData:NeedNewSnapshot(auraSpellId, spellId)
	-- Don't snapshot if the aura was applied by an action that shouldn't cause the aura to re-snapshot.
	if self_buffNoSnapshotSpellList[auraSpellId] and self_buffNoSnapshotSpellList[auraSpellId][spellId] then
		return false
	end
	return true
end

--Compute the spell Cooldown
function OvaleData:GetSpellCD(spellId)
	local actionCooldownStart, actionCooldownDuration, actionEnable = API_GetSpellCooldown(spellId)
	if self.spellInfo[spellId] and self.spellInfo[spellId].forcecd then
		actionCooldownStart, actionCooldownDuration = API_GetSpellCooldown(self.spellInfo[spellId].forcecd)
	end
	return actionCooldownStart, actionCooldownDuration, actionEnable
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
--</public-static-methods>
