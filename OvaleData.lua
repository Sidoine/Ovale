OvaleData = LibStub("AceAddon-3.0"):NewAddon("OvaleData", "AceEvent-3.0")

--<public-static-properties>
OvaleData.spellList = {}
OvaleData.firstInit = false
OvaleData.className = nil
OvaleData.spellInfo = {}
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
	strengthagility=
	{
		6673, -- Battle Shout
		8076, -- Strength of Earth
		57330, -- Horn of Winter
		93435 --Roar of Courage (Cat, Spirit Beast)
	},
	stamina =
	{
		79105, -- Power Word: Fortitude
		469, -- Commanding Shout
		6307, -- Blood Pact
		90364 -- Qiraji Fortitude
	},
	lowerarmor=
	{
		58567, -- Sunder Armor (x3)
		8647, -- Expose Armor
		91565, -- Faerie Fire (x3)
		35387, --Corrosive Spit (x3 Serpent)
		50498 --Tear Armor (x3 Raptor)
	},
	magicaldamagetaken=
	{
		65142, -- Ebon Plague
		60433, -- Earth and Moon
		93068, -- Master Poisoner 
		1490, -- Curse of the Elements
		85547, -- Jinx 1
		86105, -- Jinx 2
		34889, --Fire Breath (Dragonhawk)
		24844 --Lightning Breath (Wind serpent)
	},
	magicalcrittaken=
    {
        17800, -- Shadow and Flame
        22959 -- Critical Mass
    },
	physicaldamagetaken=
	{
		30069, -- Blood Frenzy (rank 1)
		30070, -- Blood Frenzy (rank 2)
		81327, -- Brittle Bones (rank 1)
		81328, -- Brittle Bones (rank 2)
		58684, -- Savage Combat (rank 1)
		58683, -- Savage Combat (rank 2)
		55749, -- Acid Spit (Worm)
		50518, -- Ravage (Ravager)
	},
	lowerphysicaldamage=
	{
		99, -- Demoralizing Roar
		702, -- Curse of Weakness
		1160, -- Demoralizing Shout
		26017, -- Vindication
		81130, -- Scarlet Fever
		50256, --Demoralizing Roar (Bear)
		24423, -- Demoralizing Screech (Carrion Bird)
	},
	meleeslow=
	{
		55095, --Icy Touch
		58179, --Infected Wounds rank 1
		58180, --Infected Wounds rank 2
		68055, --Judgments of the just
		6343, --Thunderclap
		8042, --Earth Shock
		54404, --Dust Cloud (Tallstrider)
		90315, -- Tailspin (Fox)
	},
	castslow =
	{
		1714, --Curse of Tongues
        58604, --Lava Breath (Core Hound)
        50274, --Spore Cloud (Sporebat)
        5761, --Mind-numbing Poison
        73975, --Necrotic Strike
        31589 --Slow
	},
	bleed=
	{
		33876, --Mangle cat
		33878, --Mangle bear
		46856, -- Trauma rank 1
		46857, -- Trauma rank 2
		16511, --Hemorrhage
		50271, --Tendon Rip (Hyena)
		35290 --Gore (Boar)
	},
	heroism=
	{
		2825, --Bloodlust
		32182, --Heroism
		80353, --Time warp
		90355 -- Ancient Hysteria (Core Hound)
	},
	meleehaste =
	{
		8515, -- Windfury
		55610, -- Improved Icy Talons
		53290 -- Hunting Party
	},
	spellhaste = 
	{
		24907, -- Moonkin aura
		2895, -- Wrath of Air Totem
		49868 -- Mind Quickening
	},
	enrage =
	{
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
	criticalstrike =
	{
		51740, -- Elemental Oath
		51698, -- Honor Among Thieves (rank 1)
		51700, -- Honor Among Thieves (rank 2)
		51701, -- Honor Among Thieves (rank 3)
		17007, -- Leader of the Pack
		29801, -- Rampage
		24604, -- Furious Howl (Wolf)
		90309, -- Terrifying Roar (Devilsaur)
	}
}
--</public-static-properties>

--<private-static-properties>
local fearSpellList = nil
local stunSpellList = nil
local incapacitateSpellList = nil
local rootSpellList = nil
--</private-static-properties>

--<public-static-methods>
function OvaleData:OnEnable()
	self:FirstInit()
    self:RegisterEvent("PLAYER_TALENT_UPDATE")
    self:RegisterEvent("CHARACTER_POINTS_CHANGED")
	self:RegisterEvent("SPELLS_CHANGED")
end

function OvaleData:OnDisable()
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

function OvaleData:FillSpellList()
	self.spellList = {}
	local book=BOOKTYPE_SPELL
	while true do
		local i=1
		while true do
			local skillType, spellId = GetSpellBookItemInfo(i, book)
			if not spellId then
				break
			end
			if skillType~="FUTURESPELL" then
				local spellName = GetSpellBookItemName(i, book)
				self.spellList[spellId] = spellName
			end
			i = i + 1
		end
		if book==BOOKTYPE_SPELL then
			book = BOOKTYPE_PET
		else
			break
		end
	end
end

function OvaleData:RemplirListeTalents()
	local numTabs = GetNumTalentTabs();
	for t=1, numTabs do
		local numTalents = GetNumTalents(t);
		for i=1, numTalents do
			local nameTalent, icon, tier, column, currRank, maxRank = GetTalentInfo(t,i);
			local link = GetTalentLink(t,i)
			if link then
				local a, b, talentId = string.find(link, "talent:(%d+)");
				talentId = tonumber(talentId)
				self.talentIdToName[talentId] = nameTalent
				self.talentNameToId[nameTalent] = talentId
				self.pointsTalent[talentId] = currRank
				self.listeTalentsRemplie = true
				Ovale.needCompile = true
			end
		end
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
