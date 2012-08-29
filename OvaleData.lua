OvaleData = LibStub("AceAddon-3.0"):NewAddon("OvaleData", "AceEvent-3.0")

--<public-static-properties>
OvaleData.spellList = {}
OvaleData.firstInit = false
OvaleData.className = nil
--allows to fill the player talent tables on first use
OvaleData.listeTalentsRemplie = false
--key: talentId / value: points in this talent
OvaleData.pointsTalent = {}
--key: talentId / value: talent name (not used)
OvaleData.talentIdToName = {}
--key: talent name / value: talent id
OvaleData.talentNameToId = {}
--spell info from the current script (by spellId)
OvaleData.spellInfo = {}
--spells that count for scoring
OvaleData.scoreSpell = {}

OvaleData.power =
{
	mana = {id=0, mini=0},
	rage = {id=1, mini=0, maxi=100},
	focus ={id=2, mini=0, maxi=100},
	energy = {id=3, mini=0, maxi=100},
	runicpower = {id=6, mini=0, maxi=100},
	shards = {id=7, mini=0, maxi=3},
	eclipse = {id=8, mini=-100, maxi=100},
	holy = {id=9, mini=0, maxi=5},
	chi = {id=12, mini=0, maxi=4 }, 
	shadoworbs = {id=13, mini=0, maxi=3},
	burningembers = {id=14, mini=0},
	demonicfury = {id=15, mini=0}
}
OvaleData.secondaryPower = {"focus", "shards", "holy", "chi", "shadoworbs", "burningembers", "demonicfury"}
OvaleData.powerType = {}

-- List haste buff that does not appear in the character sheet and that are not raid wide buffs
OvaleData.selfHasteBuff =
{
	[53657] = 9, -- Judgement of the pure
	[49016] = 20 -- Unholy Frenzy
}

-- List temporary damage multiplier
OvaleData.selfDamageBuff =
{
	[5217] = 1.15, -- Tiger's fury
	[57933] = 1.15 -- Tricks of the trade
}

OvaleData.buffSpellList =
{
	fear =
	{
		5782, -- Fear
		5484, -- Howl of terror
		5246, -- Intimidating Shout 
		8122, -- Psychic scream
	},
	root =
	{
		23694, -- Improved Hamstring
		339, -- Entangling Roots
		122, -- Frost Nova
		47168, -- Improved Wing Clip
	},
	incapacitate = 
	{
		6770, -- Sap
		12540, -- Gouge
		20066, -- Repentance
	},
	stun = 
	{
		5211, -- Bash
		44415, -- Blackout
		6409, -- Cheap Shot
		22427, -- Concussion Blow
		853, -- Hammer of Justice
		408, -- Kidney Shot
		46968, -- Shockwave
	},
	
	str_agi_int =
	{
		20217, -- Blessing of Kings
		1126, -- Mark of the Wild
		-- Monk
	},
	stamina =
	{
		21562, -- Power Word: Fortitude
		469, -- Commanding Shout
		6307, -- Blood Pact
		90364 -- Qiraji Fortitude
	},
	attack_power_multiplier=
	{
		6673, -- Battle Shout
		57330, -- Horn of Winter
		-- Hunter?
	},
	spell_power_multiplier = 
	{
		109773,  -- Dark Intent
		-- Shaman?
		1459 -- Arcane Brillance
	},
	melee_haste =
	{
	  -- Frost and Unholy death knights, any rogue, Enhancement shaman
	},
	spell_haste = 
	{
		24907, -- Moonkin aura
		49868, -- Mind Quickening
		-- Elemental  shaman
	},
	critical_strike =
	{
		--Guardian and Feral druids, any hunter, any mage
		1459 -- Arcane Brillance
	},
	mastery =
	{
		93435, --Roar of Courage (Cat, Spirit Beast)
		116956, -- Grace of Air
		19740 -- Blessing of Might
	},
	-- weakened_armor
	physical_vulnerability=
	{
		55749, -- Physical Vulnaribility
		55749, -- Acid Spit (Worm)
		50518, -- Ravage (Ravager)
	},
	magic_vulnerability=
	{
		93068, -- Master Poisoner 
		1490, -- Curse of the Elements
		34889, --Fire Breath (Dragonhawk)
		24844 --Lightning Breath (Wind serpent)
	},
	lower_physical_damage=
	{
		115798, -- Weakened blows
		26017, -- Vindication
		50256, --Demoralizing Roar (Bear)
		24423, -- Demoralizing Screech (Carrion Bird)
	},
	cast_slow =
	{
		1714, --Curse of Tongues
        58604, --Lava Breath (Core Hound)
        50274, --Spore Cloud (Sporebat)
        5761, --Mind-numbing Poison
        73975, --Necrotic Strike
        31589 --Slow
	},
	healing_reduced =
	{
		--Arms or Fury warrior, any rogue, any hunter
	},
	heroism=
	{
		2825, --Bloodlust
		32182, --Heroism
		80353, --Time warp
		90355 -- Ancient Hysteria (Core Hound)
	},
	enrage =
	{
		--TODO update
		49016, -- Unholy Frenzy
		18499, -- Berserker Rage
		12292, -- Death Wish
		12880, -- Enrage (rank 1)
		14201, -- Enrage (rank 2)
		14202, -- Enrage (rank 3)
		5229, -- Enrage (Bear)
        52610, -- Savage Roar (Cat)
        76691, -- Vengeance (All Tank Specs)
	},
	ranged_vulnerability =
	{
		1130, -- Hunter's Mark
	},
}
OvaleData.buffSpellList.bloodlust = OvaleData.buffSpellList.heroism
--</public-static-properties>

--<private-static-properties>
local fearSpellList = nil
local stunSpellList = nil
local incapacitateSpellList = nil
local rootSpellList = nil
--</private-static-properties>

--<public-static-methods>
function OvaleData:OnEnable()
	for k,v in pairs(self.power) do
		self.powerType[v.id] = k
	end
	
	self:FirstInit()
    self:RegisterEvent("PLAYER_TALENT_UPDATE")
    self:RegisterEvent("CHARACTER_POINTS_CHANGED")
	self:RegisterEvent("SPELLS_CHANGED")
	self:RegisterEvent("UNIT_PET")
end

function OvaleData:OnDisable()
	self:UnregisterEvent("UNIT_PET")
    self:UnregisterEvent("SPELLS_CHANGED")
    self:UnregisterEvent("PLAYER_TALENT_UPDATE")
    self:UnregisterEvent("CHARACTER_POINTS_CHANGED")
end

function OvaleData:CHARACTER_POINTS_CHANGED()
	self:RemplirListeTalents()
--	Ovale:Print("CHARACTER_POINTS_CHANGED")
end

function OvaleData:PLAYER_TALENT_UPDATE()
	self:RemplirListeTalents()
--	Ovale:Print("PLAYER_TALENT_UPDATE")
end

function OvaleData:UNIT_PET()
	self:FillPetSpellList()
end

--The user learnt a new spell
function OvaleData:SPELLS_CHANGED()
	self:FillSpellList()
	Ovale.needCompile = true
end

function OvaleData:GetRootSpellList()
	if rootSpellList then
		return rootSpellList
	end
	rootSpellList = {}
	for k, v in pairs(self.buffSpellList.fear) do
		rootSpellList[v] = true
	end
	return rootSpellList
end

function OvaleData:GetStunSpellList()
	if stunSpellList then
		return stunSpellList
	end
	stunSpellList = {}
	for k, v in pairs(self.buffSpellList.stun) do
		stunListList[v] = true
	end
	return stunSpellList
end

function OvaleData:GetIncapacitateSpellList()
	if incapacitateSpellList then
		return incapacitateSpellList
	end
	incapacitateSpellList = {}
	for k, v in pairs(self.buffSpellList.incapacitate) do
		incapacitateSpellList[v] = true
	end
	return incapacitateSpellList
end

function OvaleData:GetFearSpellList()
	if fearSpellList then
		return fearSpellList
	end
	fearSpellList = {}
	for k, v in pairs(self.buffSpellList.fear) do
		fearSpellList[v] = true
	end
	return fearSpellList
end


function OvaleData:GetSpellInfoOrNil(spell)
	if (spell) then
		return GetSpellInfo(spell)
	else
		return nil
	end
end

function OvaleData:FillPetSpellList()
	--TODO pas moyen d'avoir le nombre de skills pour le pet
	local book=BOOKTYPE_PET
	local numSpells, _ = HasPetSpells()
	if not numSpells then return end
	local i=1
	while i <= numSpells do
		local skillType, spellId = GetSpellBookItemInfo(i, book)
		if skillType~="FUTURESPELL" and spellId then
			local spellName = GetSpellBookItemName(i, book)
			self.spellList[spellId] = spellName
		end
		i = i + 1
	end
end

function OvaleData:FillSpellList()
	self.spellList = {}
	
	--TODO pas moyen d'avoir le nombre de skills pour le pet
	local book=BOOKTYPE_SPELL
	local name, texture, offset, numSpells, isGuild = GetSpellTabInfo(2)
	
	numSpells = numSpells + offset
	
	local i=1
	while i <= numSpells do
		local skillType, spellId = GetSpellBookItemInfo(i, book)
		if skillType~="FUTURESPELL" and spellId then
			local spellName = GetSpellBookItemName(i, book)
			self.spellList[spellId] = spellName
		end
		i = i + 1
	end
	self:FillPetSpellList()
end

function OvaleData:RemplirListeTalents()
	local talentId = 1
	while true do
		local name, texture, tier, column, selected, available = GetTalentInfo(talentId)
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
		Ovale.needCompile = true
		talentId = talentId + 1
	end
end

function OvaleData:FirstInit()
	if self.firstInit then
		return
	end
	
	self.firstInit = true

	local playerClass, englishClass = UnitClass("player")
	self.className = englishClass
	
	self:RemplirListeTalents()
	self:FillSpellList()
end

function OvaleData:GetTalentPoints(talentId)
	if not self.listeTalentsRemplie then
		self:RemplirListeTalents()
	end
	return self.pointsTalent[talentId]
end

function OvaleData:GetSpellInfo(spellId)
	if (not self.spellInfo[spellId]) then
		self.spellInfo[spellId] = { aura = {player = {}, target = {}} }
	end
	return self.spellInfo[spellId]
end

function OvaleData:ResetSpellInfo()
	self.spellInfo = {}
end

function OvaleData:GetGCD(spellId)
	if spellId and self.spellInfo[spellId] then
		if self.spellInfo[spellId].haste == "spell" then
			local cd = self.spellInfo[spellId].gcd
			if not cd then
				cd = 1.5
			end
			cd = cd / OvaleAura.spellHaste
			if (cd<1) then
				cd = 1
			end
			return cd
		elseif self.spellInfo[spellId].gcd then
			return self.spellInfo[spellId].gcd
		end			
	end
	
	-- Default value
	if self.className == "ROGUE" or (self.className == "DRUID" and GetShapeshiftForm(true) == 3) then
		return 1.0
	elseif self.className == "MAGE" or self.className == "WARLOCK" or self.className == "PRIEST" or
			(self.className == "DRUID" and GetShapeshiftForm(true) ~= 1) then
		local cd = 1.5 / OvaleAura.spellHaste
		if (cd<1) then
			cd = 1
		end
		return cd
	else
		return 1.5
	end
end


--Compute the spell Cooldown
function OvaleData:GetComputedSpellCD(spellId)
	local actionCooldownStart, actionCooldownDuration, actionEnable
	local cd = OvaleState:GetCD(spellId)
	if cd and cd.start then
		actionCooldownStart = cd.start
		actionCooldownDuration = cd.duration
		actionEnable = cd.enable
	else
		actionCooldownStart, actionCooldownDuration, actionEnable = GetSpellCooldown(spellId)
		-- Les chevaliers de la mort ont des infos fausses sur le CD quand ils n'ont plus les runes
		-- On force à 1,5s ou 1s en présence impie
		-- TODO: is it still the case in MoP?
		if self.className=="DEATHKNIGHT" and actionCooldownDuration==10 and
				(not self.spellInfo[spellId] or self.spellInfo[spellId].cd~=10) then
			local impie = GetSpellInfo(48265)
			if impie and UnitBuff("player", impie) then
				actionCooldownDuration=1
			else
				actionCooldownDuration=1.5
			end
		end
		if self.spellInfo[spellId] and self.spellInfo[spellId].forcecd then
			actionCooldownStart, actionCooldownDuration = GetSpellCooldown(self.spellInfo[spellId].forcecd)
		end
	end
	return actionCooldownStart, actionCooldownDuration, actionEnable
end
--</public-static-methods>
