--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleData = Ovale:NewModule("OvaleData", "AceEvent-3.0")
Ovale.OvaleData = OvaleData

--<private-static-properties>
local OvalePaperDoll = Ovale.OvalePaperDoll
local OvaleStance = Ovale.OvaleStance

local floor = math.floor
local ipairs = ipairs
local pairs = pairs
local tinsert = table.insert
local tonumber = tonumber
local tostring = tostring
local tsort = table.sort
local wipe = table.wipe
local API_GetNumGlyphSockets = GetNumGlyphSockets
local API_GetGlyphSocketInfo = GetGlyphSocketInfo
local API_GetSpellCooldown = GetSpellCooldown
local API_GetSpellBookItemInfo = GetSpellBookItemInfo
local API_GetSpellBookItemName = GetSpellBookItemName
local API_GetSpellInfo = GetSpellInfo
local API_GetSpellTabInfo = GetSpellTabInfo
local API_GetTalentInfo = GetTalentInfo
local API_HasPetSpells = HasPetSpells
local BOOKTYPE_SPELL, BOOKTYPE_PET = BOOKTYPE_SPELL, BOOKTYPE_PET
local SPELL_POWER_ALTERNATE_POWER = SPELL_POWER_ALTERNATE_POWER
local SPELL_POWER_BURNING_EMBERS = SPELL_POWER_BURNING_EMBERS
local SPELL_POWER_CHI = SPELL_POWER_CHI
local SPELL_POWER_DEMONIC_FURY = SPELL_POWER_DEMONIC_FURY
local SPELL_POWER_ECLIPSE = SPELL_POWER_ECLIPSE
local SPELL_POWER_ENERGY = SPELL_POWER_ENERGY
local SPELL_POWER_FOCUS = SPELL_POWER_FOCUS
local SPELL_POWER_HOLY_POWER = SPELL_POWER_HOLY_POWER
local SPELL_POWER_MANA = SPELL_POWER_MANA
local SPELL_POWER_RAGE = SPELL_POWER_RAGE
local SPELL_POWER_RUNIC_POWER = SPELL_POWER_RUNIC_POWER
local SPELL_POWER_SHADOW_ORBS = SPELL_POWER_SHADOW_ORBS
local SPELL_POWER_SOUL_SHARDS = SPELL_POWER_SOUL_SHARDS

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
OvaleData.spellList = {}
OvaleData.itemList = {}
--allows to fill the player talent tables on first use
OvaleData.listeTalentsRemplie = false
--key: talentId / value: points in this talent
OvaleData.pointsTalent = {}
--key: talentId / value: talent name (not used)
OvaleData.talentIdToName = {}
--key: talent name / value: talent id
OvaleData.talentNameToId = {}
--active glyphs: self.glyphs[glyphId] is true if the given glyphId is active
OvaleData.glyphs = {}
--spell info from the current script (by spellId)
OvaleData.spellInfo = {}
--spells that count for scoring
OvaleData.scoreSpell = {}

OvaleData.power =
{
	mana = { id = SPELL_POWER_MANA, mini = 0 },
	rage = { id = SPELL_POWER_RAGE, mini = 0, maxi = 100 },
	focus = { id = SPELL_POWER_FOCUS, mini = 0, maxi = 100 },
	energy = { id = SPELL_POWER_ENERGY, mini = 0, maxi = 100 },
	runicpower = { id = SPELL_POWER_RUNIC_POWER, mini = 0, maxi = 100 },
	shards = { id = SPELL_POWER_SOUL_SHARDS, mini = 0 },
	eclipse = { id = SPELL_POWER_ECLIPSE, mini = -100, maxi = 100 },
	holy = { id = SPELL_POWER_HOLY_POWER, mini = 0, maxi = 5 },
	alternate = { id = SPELL_POWER_ALTERNATE_POWER, mini = 0 },
	chi = { id = SPELL_POWER_CHI, mini = 0, maxi = 4 },
	shadoworbs = { id = SPELL_POWER_SHADOW_ORBS, mini = 0, maxi = 3 },
	burningembers = { id = SPELL_POWER_BURNING_EMBERS, mini = 0, segments = true },
	demonicfury = { id = SPELL_POWER_DEMONIC_FURY, mini = 0 }
}
OvaleData.secondaryPower = {"rage", "focus", "shards", "holy", "chi", "shadoworbs", "burningembers", "demonicfury"}
OvaleData.powerType = {}

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
function OvaleData:OnInitialize()
	for k,v in pairs(self.power) do
		self.powerType[v.id] = k
	end
end

function OvaleData:OnEnable()
	self:RegisterEvent("CHARACTER_POINTS_CHANGED", "RemplirListeTalents")
	self:RegisterEvent("GLYPH_ADDED", "UpdateGlyphs")
	self:RegisterEvent("GLYPH_DISABLED", "UpdateGlyphs")
	self:RegisterEvent("GLYPH_ENABLED", "UpdateGlyphs")
	self:RegisterEvent("GLYPH_REMOVED", "UpdateGlyphs")
	self:RegisterEvent("GLYPH_UPDATED", "UpdateGlyphs")
	self:RegisterEvent("PLAYER_ALIVE", "Update")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "RemplirListeTalents")
	self:RegisterEvent("SPELLS_CHANGED", "FillSpellList")
	self:RegisterEvent("UNIT_PET", "FillPetSpellList")
end

function OvaleData:OnDisable()
	self:UnregisterEvent("CHARACTER_POINTS_CHANGED")
	self:UnregisterEvent("GLYPH_ADDED")
	self:UnregisterEvent("GLYPH_DISABLED")
	self:UnregisterEvent("GLYPH_ENABLED")
	self:UnregisterEvent("GLYPH_REMOVED")
	self:UnregisterEvent("GLYPH_UPDATED")
	self:UnregisterEvent("PLAYER_ALIVE")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_TALENT_UPDATE")
	self:UnregisterEvent("SPELLS_CHANGED")
	self:UnregisterEvent("UNIT_PET")
end

function OvaleData:Update()
	self:RemplirListeTalents()
	self:UpdateGlyphs()
	self:FillSpellList()
end

function OvaleData:GetSpellName(spellId)
	if not spellId then return nil end
	return self.spellList[spellId] or API_GetSpellInfo(spellId)
end

function OvaleData:FillPetSpellList()
	--TODO pas moyen d'avoir le nombre de skills pour le pet
	local book=BOOKTYPE_PET
	local numSpells, _ = API_HasPetSpells()
	if not numSpells then return end
	local i=1
	while i <= numSpells do
		local skillType, spellId = API_GetSpellBookItemInfo(i, book)
		if skillType~="FUTURESPELL" and spellId then
			local spellName = API_GetSpellBookItemName(i, book)
			self.spellList[spellId] = spellName
		end
		i = i + 1
	end
end

function OvaleData:FillSpellList()
	self.spellList = {}
	
	--TODO pas moyen d'avoir le nombre de skills pour le pet
	local book=BOOKTYPE_SPELL
	local name, texture, offset, numSpells, isGuild = API_GetSpellTabInfo(2)
	
	numSpells = numSpells + offset
	
	local i=1
	while i <= numSpells do
		local skillType, spellId = API_GetSpellBookItemInfo(i, book)
		if skillType~="FUTURESPELL" and spellId then
			local spellName = API_GetSpellBookItemName(i, book)
			self.spellList[spellId] = spellName
		end
		i = i + 1
	end
	self:FillPetSpellList()
	self:SendMessage("Ovale_SpellsChanged")
end

function OvaleData:RemplirListeTalents()
	local talentId = 1
	local talentsChanged = false
	while true do
		local name, texture, tier, column, selected, available = API_GetTalentInfo(talentId)
		if not name then
			break
		end
		talentId = tonumber(talentId)
		self.talentIdToName[talentId] = name
		self.talentNameToId[name] = talentId
		if selected then
			self.pointsTalent[talentId] = 1
		else
			self.pointsTalent[talentId] = 0
		end		
		self.listeTalentsRemplie = true
		talentsChanged = true
		talentId = talentId + 1
	end
	if talentsChanged then
		self:SendMessage("Ovale_TalentsChanged")
	end
end

function OvaleData:GetTalentPoints(talentId)
	if not self.listeTalentsRemplie then
		self:RemplirListeTalents()
	end
	return self.pointsTalent[talentId]
end

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

function OvaleData:UpdateGlyphs()
	wipe(self.glyphs)
	for i = 1, API_GetNumGlyphSockets() do
		local enabled, _, _, glyphSpell, _ = API_GetGlyphSocketInfo(i)
		if enabled and glyphSpell then
			self.glyphs[glyphSpell] = true
		end
	end
	self:SendMessage("Ovale_GlyphsChanged")
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

function OvaleData:GetGCD(spellId)
	if spellId and self.spellInfo[spellId] then
		local si = self.spellInfo[spellId]
		if si.haste then
			local cd = si.gcd or 1.5
			if si.haste == "melee" then
				cd = cd / OvalePaperDoll:GetMeleeHasteMultiplier()
			elseif si.haste == "spell" then
				cd = cd / OvalePaperDoll:GetSpellHasteMultiplier()
			end
			if cd < 1 then
				cd = 1
			end
			return cd
		elseif si.gcd then
			return si.gcd
		end
	end
	
	-- Default value
	local class = OvalePaperDoll.class
	if class == "DEATHKNIGHT" or class == "ROGUE"
		or (class == "MONK"
			and (OvaleStance:IsStance("monk_stance_of_the_sturdy_ox")
				or OvaleStance:IsStance("monk_stance_of_the_fierce_tiger")))
		or (class == "DRUID" and OvaleStance:IsStance("druid_cat_form")) then
		return 1.0
	elseif class == "MAGE" or class == "WARLOCK" or class == "PRIEST" or
			(class == "DRUID" and not OvaleStance:IsStance("druid_bear_form")) then
		local cd = 1.5 / OvalePaperDoll:GetSpellHasteMultiplier()
		if cd < 1 then
			cd = 1
		end
		return cd
	else
		return 1.5
	end
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

-- Returns the duration, tick length, and number of ticks of an aura.
function OvaleData:GetDuration(spellId, combo, holy)
	local si
	if type(spellId) == "number" then
		si = self.spellInfo[spellId]
	elseif OvaleData.buffSpellList[spellId] then
		for auraId in pairs(OvaleData.buffSpellList[spellId]) do
			si = self.spellInfo[auraId]
			if si then
				spellId = auraId
				break
			end
		end
	end
	if si and si.duration then
		local duration = si.duration
		combo = combo or 0
		holy = holy or 1
		if si.adddurationcp then
			duration = duration + si.adddurationcp * combo
		end
		if si.adddurationholy then
			duration = duration + si.adddurationholy * (holy - 1)
		end
		if si.tick then	-- DoT
			--DoT duration is tick * numberOfTicks.
			local tick = self:GetTickLength(spellId)
			local numTicks = floor(duration / tick + 0.5)
			duration = tick * numTicks
			return duration, tick, numTicks
		end
		return duration
	else
		return nil
	end
end

function OvaleData:GetTickLength(spellId)
	local si
	if type(spellId) == "number" then
		si = self.spellInfo[spellId]
	elseif OvaleData.buffSpellList[spellId] then
		for auraId in pairs(OvaleData.buffSpellList[spellId]) do
			si = self.spellInfo[auraId]
			if si then break end
		end
	end
	if si then
		local tick = si.tick or 3
		local hasteMultiplier = 1
		if si.haste then
			if si.haste == "spell" then
				hasteMultiplier = OvalePaperDoll:GetSpellHasteMultiplier()
			elseif si.haste == "melee" then
				hasteMultiplier = OvalePaperDoll:GetMeleeHasteMultiplier()
			end
			return tick / hasteMultiplier
		else
			return tick
		end
	else
		return nil
	end
end

-- Print out the list of active glyphs in alphabetical order.
function OvaleData:DebugGlyphs()
	local array = {}
	for glyphId in pairs(self.glyphs) do
		tinsert(array, self:GetSpellName(glyphId) .. ": " .. glyphId)
	end
	tsort(array)
	for _, v in ipairs(array) do
		Ovale:Print(v)
	end
end

-- Print out the list of known spells in alphabetical order.
function OvaleData:DebugSpellList()
	local array = {}
	for k, v in pairs(self.spellList) do
		tinsert(array, v .. ": " .. k)
	end
	tsort(array)
	for _, v in ipairs(array) do
		Ovale:Print(v)
	end
end

-- Print out the list of talents in alphabetical order.
function OvaleData:DebugTalents()
	local array = {}
	for name, id in pairs(self.talentNameToId) do
		tinsert(array, name .. " = " .. id)
	end
	tsort(array)
	for _, v in ipairs(array) do
		Ovale:Print(v)
	end
end
--</public-static-methods>
