local LBCT = LibStub("LibBabble-CreatureType-3.0"):GetLookupTable()

local runeType = 
{
	blood = 1,
	unholy = 2,
	frost = 3,
	death = 4
}	

local totemType =
{
	fire = 1,
	earth = 2,
	water = 3,
	air = 4
}

local fearSpellIdList = 
{
	5782, -- Fear
	5484, -- Howl of terror
	5246, -- Intimidating Shout 
	8122, -- Psychic scream
}
local fearSpellList = nil

local stunSpellIdList =
{
	5211, -- Bash
	44415, -- Blackout
	6409, -- Cheap Shot
	22427, -- Concussion Blow
	853, -- Hammer of Justice
	408, -- Kidney Shot
	12798, -- Revenge Stun
	46968, -- Shockwave
}
local stunSpellList = nil

local incapacitateSpellIdList =
{
	6770, -- Sap
	12540, -- Gouge
	20066, -- Repentance
}
local incapacitateSpellList = nil

local rootSpellIdList =
{
	23694, -- Improved Hamstring
	339, -- Entangling Roots
	122, -- Frost Nova
	47168, -- Improved Wing Clip
}
local rootSpellList = nil

local function buildRootSpellList()
	if (rootSpellList) then
		return
	end
	rootSpellList = {}
	for k, v in pairs(rootSpellIdList) do
		rootSpellList[Ovale:GetSpellInfoOrNil(v)] = true
	end
end

local function buildStunSpellList()
	if (stunSpellList) then
		return
	end
	stunSpellList = {}
	for k, v in pairs(stunSpellIdList) do
		stunListList[Ovale:GetSpellInfoOrNil(v)] = true
	end
end

local function buildIncapacitateSpellList()
	if (incapacitateSpellList) then
		return
	end
	incapacitateSpellList = {}
	for k, v in pairs(incapacitateSpellIdList) do
		incapacitateSpellList[Ovale:GetSpellInfoOrNil(v)] = true
	end
end

local function buildFearSpellList()
	if (fearSpellList) then
		return
	end
	fearSpellList = {}
	for k, v in pairs(fearSpellIdList) do
		fearSpellList[Ovale:GetSpellInfoOrNil(v)] = true
	end
end

local function isDebuffInList(list)
	local i=1;
	while (true) do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable =  UnitDebuff("player", i);
		if (not name) then
			break
		end
		if (list[name]) then
			return true
		end
		i = i +1
	end
	return false
end

local function avecHate(temps, hate)
	if (not hate) then
		return temps
	elseif (hate == "spell") then
		return temps/(1+Ovale.spellHaste/100)
	elseif (hate == "melee") then
		return temps/(1+Ovale.meleeHaste/100)
	else
		return temps
	end
end

local function compare(a, comparison, b)
	if (comparison == "more") then
		if (not b or (a~=nil and a>b)) then
			return 0
		else
			return nil
		end
	else 
		if (not a or (b~=nil and a<b)) then
			return 0
		else
			return nil
		end
	end
end

local function testbool(a, condition)
	if (condition == "yes" or not condition) then
		if (a) then
			return 0
		else
			return nil
		end
	else
		if (not a) then
			return 0
		else
			return nil
		end
	end
end

local function getTarget(condition)
	if (not condition) then
		return "target"
	else
		return condition
	end
end

local function GetTargetAura(condition, filter, target)
	if (not target) then
		target=condition.target
		if (not target) then
			target="target"
		end
	end
	local spellId = condition[1]
	local auraName, auraRank, auraIcon = Ovale:GetSpellInfoOrNil(spellId)
	local i=1;
	local timeLeft = nil
	local stacksLeft = nil
	while (true) do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable =  UnitAura(target, i, filter);
		if (not name) then
			break
		end
		if (not condition.mine or unitCaster=="player") then
			if (name == auraName and icon == auraIcon) then
				timeLeft = expirationTime - Ovale.maintenant
				stacksLeft = count
				break
			end
		end
		i = i + 1;
	end
	
	if spellId then
		for k=1,Ovale.spellStack.length do
			local newSpell = Ovale.spellStack[k]
			if (newSpell.info and newSpell.info[target] and newSpell.info[target][filter] and newSpell.info[target][filter][spellId]) then
				local duration = newSpell.info[target][filter][spellId]
				if duration>0 then
					if (not timeLeft or timeLeft < newSpell.attenteFinCast) then
						stacksLeft = 1
					else
						stacksLeft = stacksLeft + 1
					end
					timeLeft = duration + newSpell.attenteFinCast
				else
					timeLeft = nil
				end
			end
		end
	end
	return timeLeft, stacksLeft
end

local lastSaved
local savedHealth
local targetGUID
local lastSPD=0.0001

local function getTargetDead()
	local second = math.floor(Ovale.maintenant)
	if targetGUID~=UnitGUID("target") then
		lastSaved = nil
		targetGUID = UnitGUID("target")
		savedHealth = {}
	end
	local newHealth = UnitHealth("target")
	if second~=lastSaved and targetGUID then
		lastSaved = second
		local mod10 = second % 10
		local prevHealth = savedHealth[mod10]
		savedHealth[mod10] = newHealth
		if prevHealth>newHealth then
			lastSPD = 10/(prevHealth-newHealth)
--			print("dps = " .. (1/lastSPD))
		end
	end
	-- Rough estimation
	return newHealth * lastSPD
end

Ovale.conditions=
{
	-- Test if a white hit just occured
	-- 1 : maximum time after a white hit
	-- Not useful anymore. No widely used spell reset swing timer anyway
	--[[AfterWhiteHit = function(condition)
		local debut = OvaleSwing.starttime
		local fin = OvaleSwing.duration + debut
		local maintenant = GetTime()
		if (maintenant-debut<condition[1]) then
			return 0
		elseif (maintenant<fin-0.1) then
			return fin-maintenant
		else 
			return 0.1
		end 
	end,]]
	-- Test how many armor set parts are equiped by the player
	-- 1 : set number
	-- 2 : "more" or "less"
	-- 3 : limit 
	ArmorSetParts = function(condition)
		local nombre = 0
		if (OvaleEquipement.nombre[condition[1]]) then
			nombre = OvaleEquipement.nombre[condition[1]]
		end
		return compare(nombre, condition[2], condition[3])
	end,
	-- Test if a buff will expire on the player after a given time
	-- 1 : buff spell id
	-- 2 : expiration time 
	BuffExpires = function(condition)
		local timeLeft, stacksLeft = GetTargetAura(condition, "HELPFUL", "player")
		local timeBefore = avecHate(condition[2], condition.haste)
		if (not timeLeft or timeLeft<timeBefore) then
			return 0
		else
			return timeLeft-timeBefore
		end
	end,
	-- Test if a time has elapsed since the last buff gain
	-- 1 : buff spell id
	-- 2 : time since the buff gain
	BuffGain = function(condition)
		local spell, rank, icon = Ovale:GetSpellInfoOrNil(condition[1])
		if (spell) then
			if (not Ovale.buff[spell]) then
				return 0
			end
			local timeGain = Ovale.buff[spell].gain
			if (not timeGain or (Ovale.maintenant > timeGain + condition[2]) or Ovale.buff[spell].icon~=icon) then
				return 0
			else
				return timeGain + condition[2] - Ovale.maintenant
			end
		end
		return nil
	end,
	-- Test if a buff is active
	-- 1 : the buff spell id
	-- stacks : minimum number of stacks
	BuffPresent = function(condition)
		local timeLeft, stacksLeft = GetTargetAura(condition, "HELPFUL", "player")
		
		return testbool(timeLeft and (not condition.stacks or stacksLeft>=condition.stacks),condition[2])
	end,
	Casting = function(condition)
		local spell = UnitCastingInfo("player")
		if (not spell) then
			return nil
		end
		if (Ovale:GetSpellInfoOrNil(condition[1])==spell) then
			return 0
		else
			return nil
		end
	end,
	-- Test if a list of checkboxes is off
	-- 1,... : the checkboxes names
	CheckBoxOff = function(condition)
		for k,v in pairs(condition) do
			if (Ovale:IsChecked(v)) then
				return nil
			end
		end
		return 0
	end,
	-- Test if a list of checkboxes is on
	-- 1,... : the checkboxes names
	CheckBoxOn = function(condition)
		for k,v in pairs(condition) do
			if (not Ovale:IsChecked(v)) then
				return nil
			end
		end
		return 0
	end,
	-- Test how many combo points a feral druid or a rogue has
	-- 1 : "less" or "more"
	-- 2 : the limit
	ComboPoints = function(condition)
		local points = Ovale.state.combo
		return compare(points, condition[1], condition[2])
	end,
	DebuffExpires = function(condition)
		local timeLeft, stacksLeft = GetTargetAura(condition, "HARMFUL", "player")
		local tempsMax = avecHate(condition[2], condition.haste)
		if (not timeLeft or timeLeft<tempsMax) then
			return 0
		elseif (stacksLeft~=0 and condition.stacks and stacksLeft<condition.stacks) then
			return 0
		else
			return timeLeft-tempsMax
		end
	end,
	DebuffPresent = function(condition)
		local timeLeft, stacksLeft = GetTargetAura(condition, "HARMFUL", "player")
		
		if (timeLeft and (not condition.stacks or stacksLeft>=condition.stacks)) then
			return 0
		else
			return nil
		end
	end,
	Glyph = function(condition)
		local present = false
		for i = 1, GetNumGlyphSockets() do
			local enalbled, glypType, glyphSpellID = GetGlyphSocketInfo(i)
			if (glyphSpellID == condition[1]) then
				present = true
				break
			end
		end
		return testbool(present, condition[2])
	end,
	HasFullControl = function(condition)
		return testbool(HasFullControl(), condition[1])
	end,
	HasShield = function(condition)
		local _,_,id = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("SecondaryHandSlot")) or "","(item:%d+:%d+:%d+:%d+)")
		if (not id) then
			return testbool(false, condition[1])
		end
		
		local _,_,_,_,_,_,_,_,itemLoc = GetItemInfo(id)
		return testbool(itemLoc=="INVTYPE_SHIELD", condition[1])
	end,
	ItemCount = function(condition)
		return compare(GetItemCount(condition[1]), condition[2], condition[3])
	end,
	IsFeared = function(condition)
		buildFearSpellList()
		return testbool(not HasFullControl() and isDebuffInList(fearSpellList), condition[1])
	end,
	IsIncapacitated = function(condition)
		buildIncapacitateSpellList()
		return testbool(not HasFullControl() and isDebuffInList(incapacitateSpellList), condition[1])
	end,
	IsRooted = function(condition)
		buildRootSpellList()
		return testbool(isDebuffInList(rootSpellList), condition[1])
	end,
	IsStunned = function(condition)
		buildStunSpellList()
		return testbool(not HasFullControl() and isDebuffInList(stunSpellList), condition[1])
	end,
	-- Compare with the player level
	-- 1 : "less" or "more"
	-- 2 : the limit
	Level = function(condition)
		return compare(UnitLevel("player"), condition[1], condition[2])
	end,
	-- Test if the player life is bellow/above a given value in percent
	-- 1 : "less" or "more"
	-- 2 : the limit, in percent
	LifePercent = function(condition)
		return compare(UnitHealth("player")/UnitHealthMax("player"), condition[1], condition[2]/100)
	end,
	-- Test if a list item is selected
	-- 1 : the list name
	-- 2 : the item name
	List = function(condition)
		if (condition[1]) then
			if (Ovale:GetListValue(condition[1]) == condition[2]) then
				return 0
			end
		end
		return nil
	end,
	-- Test if the player mana is above/bellow a given value
	-- 1 : "less" or "more"
	-- 2 : the mana/energy/rage... limit
	Mana = function(condition)
		if (condition[1] == "more") then
			local _,className = UnitClass("player")
			if (className == "ROGUE" or (className == "DRUID" and GetShapeshiftForm(true) == 3)) then
				local current = UnitPower("player")
				if (current > condition[2]) then
					return 0
				else
					local rate= 10
					if (className == "ROGUE") then
						local i=1
						local rush = Ovale:GetSpellInfoOrNil(13750)
						while (true) do
							local name = UnitBuff("player", i)
							if (not name) then
								break
							end
							if (name == rush) then
								rate = rate * 2
								break
							end
							i = i + 1
						end
					end
					return (condition[2] - current) / rate
				end
			end
		end
		return compare(UnitPower("player"), condition[1], condition[2])
	end,
	ManaPercent = function(condition)
		return compare(UnitPower("player")/UnitPowerMax("player"), condition[1], condition[2]/100)
	end,
	OtherDebuffExpires = function(condition)
		Ovale:EnableOtherDebuffs()
		local otherDebuff = Ovale.otherDebuffs[GetSpellInfo(condition[1])]
		if otherDebuff then
			local timeBefore = condition[2] or 0
			local maxTime = condition[3] or 10
			local minTime
			for k,v in pairs(otherDebuff) do
				local diff = v - Ovale.maintenant
				if diff<-maxTime then
					-- Ovale:Print("enlève obsolète sur "..k)
					otherDebuff[k] = nil
				elseif k~=UnitGUID("target") and (not minTime or diff<minTime) then
					minTime = diff
				end
			end
			if not minTime then
				return nil
			end
			minTime = minTime - timeBefore
			if minTime<0 then
				minTime = 0
			end
			return minTime
		end
	end,
	OtherDebuffPresent = function(condition)
		Ovale:EnableOtherDebuffs()
		local otherDebuff = Ovale.otherDebuffs[GetSpellInfo(condition[1])]
		if otherDebuff then
			for target,expireTime in pairs(otherDebuff) do
				if target~=UnitGUID("target") and expireTime>Ovale.maintenant then
					return 0
				end
			end
		end
		return nil
	end,
	-- Test if any player pet is present (or not)
	-- 1 : "yes" or "no"
	PetPresent = function(condition)
		local present = UnitExists("pet") and not UnitIsDead("pet")
		return testbool(present, condition[1])
	end,
	Runes = function(condition)
		local type = runeType[condition[1]]
		local nombre = 0
		local nombreCD = 0
		local maxCD = nil
		local minCD = nil
		for i=1,6 do
			local rune = Ovale.state.rune[i]
			if rune.type == type or (rune.type == 4 and not condition.nodeath) then
				if (rune.cd == 0) then
					nombre = nombre + 1
				else
					nombreCD = nombreCD + 1
					if (maxCD == nil or rune.cd>maxCD) then
						maxCD = rune.cd
					end
					if (minCD == nil or rune.cd<minCD) then
						minCD = rune.cd
					end
				end
			end
		end
		local wanted = condition[2]
		if (nombre >= wanted) then
			return 0
		elseif (nombre + nombreCD < wanted) then
			return nil
		elseif (wanted == nombre + 1) then
			return minCD
		else
			-- Il ne peut y avoir que deux runes sur CD de toute façon
			return maxCD
		end
	end,
	-- Test if the player is in a given stance
	-- 1 : the stance
	Stance = function(condition)
		if (GetShapeshiftForm(true) == condition[1]) then
			return 0
		else
			return nil
		end
	end,
	-- Test how many talent points has been spent in a talent
	-- 1 : the talent identifier (use /script print(Ovale.talentNameToId["Talent name"]) to retreive)
	-- 2 : "more" or "less"
	-- 3 : the limit
	TalentPoints = function(condition)
		if (not Ovale.listeTalentsRemplie) then
			Ovale:RemplirListeTalents()
			return nil
		end
		return compare(Ovale.pointsTalent[condition[1]], condition[2], condition[3])
	end,
	-- Test if a buff is present on the target
	-- 1 : buff spell id
	-- stacks : how many stacks
	TargetBuffPresent = function(condition)
		local timeLeft, stacksLeft = GetTargetAura(condition, "HELPFUL")
		local tempsMin = avecHate(condition[2], condition.haste)
		
		if (timeLeft and (condition[2]==nil or timeLeft>tempsMin)) then
			if (stacksLeft~=0 and condition.stacks and stacksLeft<condition.stacks) then
				return nil
			else
				return 0
			end
		else
			return nil
		end
	end,
	TargetClass = function(condition)
		local loc, noloc = UnitClass("target")
		return testbool(noloc == condition[1], condition[2])
	end,
	-- Test the target classification
	-- 1 : normal, elite, or worldboss
	TargetClassification = function(condition)
		local classification = UnitClassification("target");
		if (classification == "rareelite") then
			classification = "elite"
		elseif (classification == "rare") then
			classification = "normal"
		end

		if (condition[1]==classification) then
			return 0
		else
			return nil
		end
	end,
	TargetCreatureType = function(condition)
		for _,v in pairs(condition) do
			if (UnitCreatureType("target") == LBCT[v]) then
				return 0
			end
		end
		return nil
	end,
	TargetDeadIn = function(condition)
		return compare(getTargetDead(), condition[1], condition[2])
	end,
	-- Test if a debuff will expire on the target after a given time, or if there is less than the
	-- given number of stacks (if stackable)
	-- 1 : buff spell id
	-- 2 : expiration time 
	-- stacks : how many stacks
	-- mine : 1 means that if the debuff is not ours, the debuff is ignored
	TargetDebuffExpires = function(condition)
		local timeLeft, stacksLeft = GetTargetAura(condition, "HARMFUL")
		local tempsMax = avecHate(condition[2], condition.haste)
		if (not timeLeft or timeLeft<tempsMax) then
			return 0
		elseif (stacksLeft~=0 and condition.stacks and stacksLeft<condition.stacks) then
			return 0
		else
			return timeLeft-tempsMax
		end
	end,
	-- Test if a debuff is present on the target
	-- 1 : debuff spell id
	-- stacks : how many stacks
	-- mine : 1 means that the debuff must be yours
	TargetDebuffPresent = function(condition)
		local timeLeft, stacksLeft = GetTargetAura(condition, "HARMFUL")
		local tempsMin = avecHate(condition[2], condition.haste)
		
		if (timeLeft and (condition[2]==nil or timeLeft>tempsMin)) then
			if (stacksLeft~=0 and condition.stacks and stacksLeft<condition.stacks) then
				return nil
			else
				return 0
			end
		else
			return nil
		end
	end,
	TargetInRange = function(condition)
		return testbool(IsSpellInRange(Ovale:GetSpellInfoOrNil(condition[1]),getTarget(condition.target))==1,condition[2])
	end,
	TargetIsCasting = function(condition)
		return testbool(UnitCastingInfo(getTarget(condition.target)), condition[1])
	end,
	TargetLife = function(condition)
		local target = getTarget(condition.target)
		return compare(UnitHealth(target), condition[1], condition[2])
	end,
	-- Test if the target life is bellow/above a given value in percent
	-- 1 : "less" or "more"
	-- 2 : the limit, in percents
	TargetLifePercent = function(condition)
		local target = getTarget(condition.target)
		return compare(UnitHealth(target)/UnitHealthMax(target), condition[1], condition[2]/100)
	end,
	TargetMana = function(condition)
		local target = getTarget(condition.target)
		return compare(UnitPower(target), condition[1], condition[2])
	end,
	-- Test the target level difference with the player
	-- 1 : "less" or "more"
	-- 2 : [target level]-[player level] limit
	TargetRelativeLevel = function(condition)
		local difference
		if (UnitLevel("target") == -1) then
			difference = 3
		else
			difference = UnitLevel("target") - UnitLevel("player")
		end

		return compare(difference, condition[1], condition[2])
	end,
	-- Test if the target's target is the player (or is not)
	-- 1 : "yes" (it should be the player) or "no"
	TargetTargetIsPlayer = function(condition)
		return testbool(UnitIsUnit("player","targettarget"), condition[1])
	end,
	TotemExpires = function(condition)
		local haveTotem, totemName, startTime, duration = GetTotemInfo(totemType[condition[1]])
		if (totemName==nil) then
			return 0
		end
		if (condition.totem and Ovale:GetSpellInfoOrNil(condition.totem)~=totemName) then
			return 0
		end
		local timeLeft = duration - (Ovale.maintenant - startTime)
		if (condition[2] and timeLeft<condition[2]) then
			return 0
		else
			return timeLeft
		end
	end,
	WeaponEnchantExpires = function(condition)
		local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()
		if (condition[1] == "mainhand") then
			if (not hasMainHandEnchant) then
				return 0
			end
			mainHandExpiration = mainHandExpiration/1000
			if (condition[2] >= mainHandExpiration) then
				return 0
			else
				return mainHandExpiration - condition[2]
			end
		else
			if (not hasOffHandEnchant) then
				return 0
			end
			offHandExpiration = offHandExpiration/1000
			if (condition[2] >= offHandExpiration) then
				return 0
			else
				return offHandExpiration - condition[2]
			end
		end
	end,
}