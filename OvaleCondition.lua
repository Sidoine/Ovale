OvaleCondition = {}

--<private-static-properties>

local LBCT = LibStub("LibBabble-CreatureType-3.0"):GetLookupTable()
local LRC = LibStub("LibRangeCheck-2.0", true)
local runes = {}
local runesCD = {}
		
local runeType = 
{
	blood = 1,
	unholy = 2,
	frost = 3,
	death = 4
}	

local totemType =
{
	ghoul = 1,
	fire = 1,
	earth = 2,
	water = 3,
	air = 4
}

local lastSaved = {}
local savedHealth = {}
local targetGUID = {}
local lastSPD = {}

--</private-static-properties>

--<private-static-methods>
local function isDebuffInList(list)
	local i=1;
	while (true) do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId =  UnitDebuff("player", i);
		if (not name) then
			break
		end
		if (list[spellId]) then
			return true
		end
		i = i +1
	end
	return false
end

local function avecHate(temps, hate)
	if not temps then
		temps = 0
	end
	if (not hate) then
		return temps
	elseif (hate == "spell") then
		return temps/OvaleAura.spellHaste
	elseif (hate == "melee") then
		return temps/OvaleAura.meleeHaste
	else
		return temps
	end
end

local function compare(a, comparison, b)
	if not comparison then
		return 0, nil, a, 0, 0 -- this is not a compare, returns the value a
	elseif comparison == "more" then
		if (not b or (a~=nil and a>b)) then
			return 0
		else
			return nil
		end
	elseif comparison == "equal" then
		if b == a then
			return 0
		else
			return nil
		end
	elseif comparison == "less" then
		if (not a or (b~=nil and a<b)) then
			return 0
		else
			return nil
		end
	else
		Ovale:Error("unknown compare term "..comparison.." (should be more, equal, or less)")
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
		return "player"
	elseif condition == "target" then
		return OvaleCondition.defaultTarget
	else	
		return condition
	end
end

local function addTime(time1, duration)
	if not time1 then
		return nil
	else
		return time1 + duration
	end
end

--Return time2-time1
local function diffTime(time1, time2)
	if not time1 then
		return 0
	end
	if not time2 then
		return nil
	end
	return time2 - time1
end

local function addOrSubTime(time1, operator, duration)
	if operator == "more" then
		return addTime(time1, -duration)
	else
		return addTime(time1, duration)
	end
end

local function nilstring(text)
	if text == nil then
		return "nil"
	else
		return text
	end
end

-- Get the expiration time of a debuff
-- that can be on any unit except the target
-- Returns the first to expires, the last to expires
-- Returns nil if the debuff is not present
local function getOtherAura(spellId, suppTime, excludingTarget)
	if excludingTarget then
		excludingTarget = UnitGUID(excludingTarget)
	end
	return OvaleState:GetExpirationTimeOnAnyTarget(spellId, excludingTarget)
end

local function GetRuneCount(type, death)
	local ret = 0
	local atTime = nil
	local rate = nil
	type = runeType[type]
	for i=1,6 do
		local rune = OvaleState.state.rune[i]
		if rune and (rune.type == type or (rune.type == 4 and death==1)) then
			if rune.cd > OvaleState.currentTime then
				onCd = true
				if not atTime or rune.cd < atTime then
					atTime = rune.cd
					rate = 1/rune.duration
				end
			else
				ret = ret + 1
			end
		end
	end
	if atTime then
		return ret + 1, atTime, rate
	else
		return ret, 0, 0
	end
end

local function GetRune(condition)
	local nombre = 0
	local nombreCD = 0
	local maxCD = nil
	
	for i=1,4 do
		runes[i] = 0
		runesCD[i] = 0
	end
	
	local k=1
	while true do
		local type = runeType[condition[k*2-1]]
		if not type then
			break
		end
		local howMany = condition[k*2]
		runes[type] = runes[type] + howMany
		k = k + 1 
	end
	
	for i=1,6 do
		local rune = OvaleState.state.rune[i]
		if rune then
			if runes[rune.type] > 0 then
				runes[rune.type] = runes[rune.type] - 1
				if rune.cd > runesCD[rune.type] then
					runesCD[rune.type] = rune.cd
				end
			elseif rune.cd < runesCD[rune.type] then
				runesCD[rune.type] = rune.cd
			end
		end
	end
	
	if not condition.nodeath then
		for i=1,6 do
			local rune = OvaleState.state.rune[i]
			if rune and rune.type == 4 then
				for j=1,3 do
					if runes[j]>0 then
						runes[j] = runes[j] - 1
						if rune.cd > runesCD[j] then
							runesCD[j] = rune.cd
						end
						break
					elseif rune.cd < runesCD[j] then
						runesCD[j] = rune.cd
						break
					end
				end
			end
		end
	end
	
	for i=1,4 do
		if runes[i]> 0 then
			return nil
		end
		if not maxCD or runesCD[i]>maxCD then
			maxCD = runesCD[i]
		end
	end
	return maxCD
end

local lastEnergyValue = nil
local lastEnergyTime

local function testValue(comparator, limit, value, atTime, rate)
	if not value or not atTime then
		return nil
	elseif not comparator then
		return 0, nil, value, atTime, rate
	else
		if rate == 0 then
			if comparator == "more" then
				if value > limit then return 0 else return nil end
			elseif comparator == "less" then
				if value < limit then return 0 else return nil end
			else
				Ovale:Error("Unknown operator "..comparator)
			end
		elseif comparator == "more" then
			return (limit-value)/rate + atTime
		elseif comparator == "less" then
			return 0, (limit-value)/rate + atTime
		else
			Ovale:Error("Unknown operator "..comparator)
		end
	end
end

-- Recherche un aura sur la cible et récupère sa durée et le nombre de stacks
-- return start, ending, stacks
local function GetTargetAura(condition, target)
	if (not target) then
		target=condition.target
		if (not target) then
			target="target"
		end
	end
	local stacks = condition.stacks
	if not stacks then
		stacks = 1
	end
	local spellId = condition[1]
	
	local mine = true
	if condition.any then
		mine = false
	end
	
	local aura
	if type(spellId) == "number" then
		aura = OvaleState:GetAura(target, spellId, mine)
	elseif OvaleData.buffSpellList[spellId] then
		for k,v in pairs(OvaleData.buffSpellList[spellId]) do
			local newAura = OvaleState:GetAura(target, v, mine)
			if newAura and (not aura or newAura.stacks>aura.stacks) then
				aura = newAura
			end
		end
	elseif spellId == "Magic" or spellId == "Disease" or spellId=="Curse" or spellId=="Poison" then
		aura = OvaleState:GetAura(target, spellId, mine)
	else
		Ovale:Error("unknown buff "..spellId)
		return 0,0,0
	end
	
	if not aura then
		Ovale:Log("Aura "..spellId.." not found")
		return 0,0,0
	end	
	
	if Ovale.trace then
		Ovale:Print("GetTargetAura = start=".. nilstring(aura.start) .. " end="..nilstring(aura.ending).." stacks=" ..nilstring(aura.stacks).."/"..stacks)
	end
		
	if (not condition.mine or (aura.mine and condition.mine==1) or (not aura.mine and condition.mine==0)) and aura.stacks>=stacks then
		local ending
		if condition.forceduration then
			if OvaleData.spellInfo[spellId] and OvaleData.spellInfo[spellId].duration then
				ending = aura.start + OvaleData.spellInfo[spellId].duration
			else
				ending = aura.start + condition.forceduration
			end
		else
			ending = aura.ending
		end
		return aura.start, ending, aura.stacks
	else
		return 0,0,0
	end
end

local function getTargetDead(target)
	local second = math.floor(OvaleState.maintenant)
	if targetGUID[target] ~=UnitGUID(target) then
		lastSaved[target] = nil
		targetGUID[target] = UnitGUID(target)
		savedHealth[target] = {}
	end
	local newHealth = UnitHealth(target)
	if newHealth then
		Ovale:Log("newHealth = " .. newHealth)
	end
	if UnitHealthMax(target)==1 then
		Ovale:Log("Dummy, return in the future")
		return OvaleState.currentTime + 3600
	end
	if second~=lastSaved[target] and targetGUID[target] then
		lastSaved[target] = second
		local mod10 = second % 10
		local prevHealth = savedHealth[target][mod10]
		savedHealth[target][mod10] = newHealth
		if prevHealth and prevHealth>newHealth then
			lastSPD[target] = 10/(prevHealth-newHealth)
			if lastSPD[target] > 0 then
				Ovale:Log("dps = " .. (1/lastSPD[target]))
			end
		end
	end
	if not lastSPD[target] or lastSPD[target]<=0 then
		return nil
	end
	-- Rough estimation
	local duration = newHealth * lastSPD[target]
	if duration < 10000 then
		return OvaleState.maintenant + duration
	else
		return nil
	end
end

local function isSameSpell(spellIdA, spellIdB, spellNameB)
	if spellIdB then
		return spellIdA == spellIdB
	elseif spellIdA and spellNameB then
		return GetSpellInfo(spellIdA) == spellNameB
	else
		return false
	end
end
--</private-static-methods>

--<public-static-properties>
OvaleCondition.conditions=
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
	-- Get how many armor set parts are equiped by the player
	-- 1 : set name
	-- returns : bool or number
	armorsetparts = function(condition)
		local nombre = 0
		if OvaleEquipement.nombre[condition[1]] then
			nombre = OvaleEquipement.nombre[condition[1]]
		end
		return compare(nombre, condition[2], condition[3])
	end,
	-- Get the attack power
	-- returns : bool or number
	attackpower = function(condition)
		local base, posBuff, negBuff = UnitAttackPower("player")
		return compare(base + posBuff + negBuff, condition[1], condition[2])
	end,
	buffcount = function(condition)
		return OvaleState:GetExpirationTimeOnAnyTarget(condition[1]), 0, 0
	end,
	-- Get the aura total duration (not only the remaining time)
	-- 1 : spell id
	-- returns : bool or number
	-- alias: debuffduration
	buffduration = function(condition)
		local start, ending = GetTargetAura(condition, getTarget(condition.target))
		return compare(diffTime(start, ending), condition[2], condition[3])
	end,
	-- Test if a buff will expire on the player after a given time
	-- 1 : aura spell id
	-- 2 : expiration time 
	-- returns : bool
	-- alias: debuffexpires
	buffexpires = function(condition)
		local start, ending = GetTargetAura(condition, getTarget(condition.target))
		local timeBefore = avecHate(condition[2], condition.haste)
		if Ovale.trace then
			Ovale:Print("timeBefore = " .. nilstring(timeBefore))
			Ovale:Print("start = " .. nilstring(ending))
		end
		return addTime(ending, -timeBefore)
	end,
	-- Get the aura remaining time
	-- 1 : aura spell id
	-- returns : number
	-- alias: debuffremains
	buffremains = function(condition)
		local start, ending = GetTargetAura(condition, getTarget(condition.target))
		if ending then
			return start, ending, ending - start, start, -1
		else
			return nil
		end
	end,
	-- Returns the time elapsed since the last buff gain
	-- TODO won't work because the aura is not kept in cache
	-- 1 : aura spell id
	-- returns : number
	-- alias: debuffgain
	buffgain = function(condition)
		Ovale:Error("not implemented")
		if true then return nil end
		local spellId = condition[1]
		if not spellId then Ovale:Error("buffgain parameter spellId is not optional"); return end
		local target = getTarget(condition.target)
		local aura = OvaleState:GetAura(target,spellId,true)
		if not aura then
			return 0, nil, 0, 0, 1
		end
		local timeGain = aura.gain
		if not timeGain then
			return 0, nil, 0, 0, 1
		end
		return 0, nil, 0, timeGain, 1
	end,
	-- Test if a buff is active
	-- 1 : the buff spell id
	-- stacks : minimum number of stacks
	-- returns : bool
	-- alias: debuffpresent
	buffpresent = function(condition)
		local start, ending = GetTargetAura(condition, getTarget(condition.target))
		local timeBefore = avecHate(condition[2], condition.haste)
		return start, addTime(ending, -timeBefore)
	end,
	-- Get a buff stack size
	-- 1: the buff spell id
	-- returns: number
	-- alias: debuffstacks
	buffstacks = function(condition)
		local start, ending, stacks = GetTargetAura(condition, getTarget(condition.target))
		return start, ending, stacks, 0, 0
	end,
	-- Is there a stealable buff on the target?
	-- returns: bool
	buffstealable = function(condition)
		return OvaleAura:GetStealable(getTarget(condition.target))
	end,
	-- Get many burning embers count
	-- returns: bool or number
	burningembers = function(condition)
		return testValue(condition[1], condition[2], OvaleState.state.burningembers, OvaleState.currentTime, OvaleState.powerRate.burningembers)
	end,
	-- Check if the player can cast (cooldown is down)
	-- 1: spellId
	-- returns: bool
	cancast = function(condition)
		local name, rank, icon, cost, isFunnel, powerType, castTime = OvaleData:GetSpellInfoOrNil(condition[1])
		local actionCooldownStart, actionCooldownDuration, actionEnable = OvaleData:GetComputedSpellCD(condition[1])
		local startCast = actionCooldownStart + actionCooldownDuration
		if startCast<OvaleState.currentTime then
			startCast = OvaleState.currentTime
		end
		--TODO why + castTime?
		return startCast + castTime/1000
	end,
	-- Is the target casting a spell?
	-- 1: the spell id, spell name, spell list, "harmful", or "helpful"
	-- returns: bool
	casting = function(condition)
		local casting
		local target = getTarget(condition.target)
		local spellId = condition[1]
		local start, ending, castSpellId, castSpellName, _
		if target == "player" then
			start = OvaleState.startCast
			ending = OvaleState.endCast
			castSpellId = OvaleState.currentSpellId
		else
			castSpellName, _, _, _, start, ending = UnitCastingInfo(target)
			if not castSpellName then
				castSpellName, _, _, _, start, ending = UnitChannelInfo(target)
			end
		end
		if not castSpellId and not castSpellName then
			return nil
		end
		if not spellId then
			return start, ending
		elseif type(spellId) == "number" then
			if isSameSpell(spellId, castSpellId, castSpellName) then
				return start, ending
			else
				return nil
			end
		elseif OvaleData.buffSpellList[spellId] then
			local found = false
			for k,v in pairs(OvaleData.buffSpellList[spellId]) do
				if isSameSpell(v, castSpellId, castSpellName) then
					return start, ending
				end
			end
			return nil
		elseif spellId == "harmful" then
			if not castSpellName then
				castSpellName = GetSpellInfo(castSpellId)
			end
			if IsHarmfulSpell(castSpellName) then
				return start, ending
			else
				return nil
			end
		elseif spellId == "helpful" then
			if not castSpellName then
				castSpellName = GetSpellInfo(castSpellId)
			end
			if IsHelpfulSpell(castSpellName) then
				return start, ending
			else
				return nil
			end
		end
	end,
	-- Get the spell casting time
	-- 1: the spell id
	-- returns: bool or number
	casttime = function(condition)
		local name, rank, icon, cost, isFunnel, powerType, castTime = OvaleData:GetSpellInfoOrNil(condition[1])
		if Ovale.trace then
			Ovale:Print("castTime/1000 = " .. (castTime/1000) .. " " .. condition[2] .. " " .. condition[3])
		end
		return compare(castTime/1000, condition[2], condition[3])
	end,
	-- Test if a list of checkboxes is off
	-- 1,... : the checkboxes names
	-- returns: bool
	checkboxoff = function(condition)
		for k,v in pairs(condition) do
			if (Ovale:IsChecked(v)) then
				return nil
			end
		end
		return 0
	end,
	-- Test if a list of checkboxes is on
	-- 1,... : the checkboxes names
	-- returns: bool
	checkboxon = function(condition)
		for k,v in pairs(condition) do
			if (not Ovale:IsChecked(v)) then
				return nil
			end
		end
		return 0
	end,
	-- Get the chi
	chi = function(condition)
		return testValue(condition[1], condition[2], OvaleState.state.chi, OvaleState.currentTime, OvaleState.powerRate.chi)
	end,
	-- Check the class of the target
	-- 1: the class to check
	-- returns: bool
	class = function(condition)
		local loc, noloc = UnitClass(getTarget(condition.target))
		return testbool(noloc == condition[1], condition[2])
	end,
	-- Test the target classification
	-- 1 : normal, elite, or worldboss
	-- returns: bool
	classification = function(condition)
		local classification
		local target = getTarget(condition.target)
		if UnitLevel(target)==-1 then
			classification = "worldboss"
		else
			classification = UnitClassification(target);
			if (classification == "rareelite") then
				classification = "elite"
			elseif (classification == "rare") then
				classification = "normal"
			end
		end
		
		return testbool(condition[1]==classification, condition[2])
	end,
	-- Test how many combo points a feral druid or a rogue has
	-- returns: bool or number
	combopoints = function(condition)
		return compare(OvaleState.state.combo, condition[1], condition[2])
	end,
	-- Get a counter value
	-- 1: the counter name
	-- returns: bool or number
	counter = function(condition)
		return compare(OvaleState:GetCounterValue(condition[1]), condition[2], condition[3])
	end,
	-- Check the target creature family
	-- 1: the family
	-- returns: bool
	creaturefamily = function(condition)
		return testbool(UnitCreatureFamily(getTarget(condition.target)) == LBCT[condition[1]], condition[2])
	end,
	-- Check the target has any of the creature type 
	-- 1,...: a creature type
	-- returns: bool
	creaturetype = function(condition)
		local creatureType = UnitCreatureType(getTarget(condition.target))
		for _,v in pairs(condition) do
			if (creatureType == LBCT[v]) then
				return 0
			end
		end
		return nil
	end,
	-- Get a spell damage
	-- 1: spell id
	-- returns: number
	damage = function(condition)
		local spellInfo = OvaleData:GetSpellInfo(condition[1])
		if not spellInfo then
			return nil
		end
		local ret = (spellInfo.base or 0)
		if spellInfo.bonuscp then
			ret = ret + (OvaleState.state.combo * spellInfo.bonuscp)
		end
		if spellInfo.bonusholy then
			ret = ret + (OvaleState.state.holy * spellInfo.bonusholy)
		end
		if spellInfo.bonusap then
			ret = ret + spellInfo.bonusap * UnitAttackPower("player")
		end
		if spellInfo.bonusapcp then
			ret = ret + spellInfo.bonusapcp * UnitAttackPower("player") * OvaleState.state.combo
		end
		if spellInfo.bonusapholy then
			ret = ret + spellInfo.bonusapholy * UnitAttackPower("player") * OvaleState.state.holy
		end
		if spellInfo.bonussp then
			ret = ret + spellInfo.bonussp * GetSpellBonusDamage(2)
		end
		if spellInfo.bonusspholy then
			ret = ret + spellInfo.bonusspholy * GetSpellBonusDamage(2) * OvaleState.state.holy
		end
		return 0, nil, ret * OvaleAura.damageMultiplier, 0, 0
	end,
	-- Get the current damage multiplier
	-- TODO: use OvaleState
	-- returns: number
	damagemultiplier = function(condition)
		local ret = OvaleAura.damageMultiplier
		if condition[1] then
			local si = OvaleData:GetSpellInfo(condition[1])
			if si and si.combo == 0 then
				ret = ret * OvaleState.state.combo
			end
		end
		return 0, nil, ret, 0, 0
	end,
	-- Get the remaining time until the target is dead
	-- returns: bool or number
	deadin = function(condition)
		return testValue(condition[1], condition[2], 0, getTargetDead(getTarget(condition.target)), -1)
	end,
	-- Get the demonic fury
	-- returns: bool or number
	demonicfury = function(condition)
		return testValue(condition[1], condition[2], OvaleState.state.demonicfury, OvaleState.currentTime, OvaleState.powerRate.demonicfury)
	end,
	-- Get the distance to the target
	-- returns: bool or number
	distance = function(condition)
		if LRC then
			return compare(LRC:GetRange(getTarget(condition.target)), condition[1], condition[2])
		else
			return nil
		end
	end,
	--Compare to eclipse power. <0 lunar, >0 solar
	-- returns: bool or number
	eclipse = function(condition)
		return compare(OvaleState.state.eclipse, condition[1], condition[2])
	end,
	eclipsedir = function(condition)
		return compare(OvaleState:GetEclipseDir(), condition[1], condition[2])
	end,
	-- Get the effective mana (e.g. if spell cost is divided by two, will returns the mana multiplied by two)
	-- TODO: not working
	-- returns: bool or number
	effectivemana = function(condition)
		return testValue(condition[1], condition[2], OvaleState.state.mana, OvaleState.currentTime, OvaleState.powerRate.mana)
	end,
	-- Get the number of enemies
	-- returns: bool or number
	enemies = function(condition)
		return compare(OvaleEnemies:GetNumberOfEnemies(), condition[1], condition[2])
	end,
	-- Get the energy
	-- returns: bool or number
	energy = function(condition)
		return testValue(condition[1], condition[2], OvaleState.state.energy, OvaleState.currentTime, OvaleState.powerRate.energy)
	end,
	-- Checks if the target exists
	-- returns: bool
	exists = function(condition)
		return testbool(UnitExists(getTarget(condition.target)) == 1, condition[1])
	end,
	["false"] = function(condition)
		return nil
	end,
	-- Get the focus
	-- returns: bool or number
	focus = function(condition)
		return testValue(condition[1], condition[2], OvaleState.state.focus, OvaleState.currentTime, OvaleState.powerRate.focus)
	end,
	-- Get the global countdown
	-- returns: bool or number
	gcd = function(condition)
		return compare(OvaleState.gcd, condition[1], condition[2])
	end,
	-- Check if a glyph is active
	-- 1: the glyph spell id
	-- returns: bool
	glyph = function(condition)
		local present = false
		for i = 1, GetNumGlyphSockets() do
			local enabled, glypType, glyphTooltipIndex, glyphSpellID = GetGlyphSocketInfo(i)
			if (glyphSpellID == condition[1]) then
				present = true
				break
			end
		end
		return testbool(present, condition[2])
	end,
	-- Check if the player has full control of his character
	-- returns: bool
	hasfullcontrol = function(condition)
		return testbool(HasFullControl(), condition[1])
	end,
	-- Check if a shield is equipped
	-- returns: bool
	hasshield = function(condition)
		local _,_,id = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("SecondaryHandSlot")) or "","(item:%d+:%d+:%d+:%d+)")
		if (not id) then
			return testbool(false, condition[1])
		end
		
		local _,_,_,_,_,_,_,_,itemLoc = GetItemInfo(id)
		return testbool(itemLoc=="INVTYPE_SHIELD", condition[1])
	end,
	-- Get the holy power
	-- returns: bool or number
	holypower = function(condition)
		return compare(OvaleState.state.holy, condition[1], condition[2])
	end,
	-- Check if the player is in combat
	-- returns: bool
	incombat = function(condition)
		return testbool(Ovale.enCombat, condition[1])
	end,
	-- Check if the spell is flying to the target
	-- 1: spell id
	-- returns: bool
	inflighttotarget = function(condition)
		return testbool(OvaleFuture:InFlight(condition[1] or OvaleState.currentSpellId == condition[1]), condition[2])
	end,
	-- Check if the target is in the spell range
	-- 1: spell id
	-- returns: bool
	inrange = function(condition)
		--TODO is IsSpellInRange using spell id now?
		local spellName = GetSpellInfo(condition[1])
		return testbool(IsSpellInRange(spellName,getTarget(condition.target))==1,condition[2])
	end,
	-- Get an item cooldown time
	itemcooldown = function(condition)
		local actionCooldownStart, actionCooldownDuration, actionEnable = GetItemCooldown(condition[1])
		return 0, nil, actionCooldownDuration, actionCooldownStart, -1
	end,
	-- Get an item count
	-- returns: bool or number
	itemcount = function(condition)
		return compare(GetItemCount(condition[1]), condition[2], condition[3])
	end,
	-- Get an item charges
	-- returns: bool or number
	itemcharges = function(condition)
		return compare(GetItemCount(condition[1], false, true), condition[2], condition[3])
	end,
	-- Check if the player is feared
	-- returns: bool
	isfeared = function(condition)
		local fearSpellList = OvaleData:GetFearSpellList()
		return testbool(not HasFullControl() and isDebuffInList(fearSpellList), condition[1])
	end,
	-- Check if the target is a friend
	-- returns: bool
	isfriend = function(condition)
		return testbool(UnitIsFriend("player", getTarget(condition.target)), condition[1])
	end,
	-- Check if the player is incapacited
	-- returns: bool
	isincapacitated = function(condition)
		local incapacitateSpellList = OvaleData:GetIncapacitateSpellList()
		return testbool(not HasFullControl() and isDebuffInList(incapacitateSpellList), condition[1])
	end,
	-- Check if the target is interruptible
	-- returns: bool
	isinterruptible = function(condition)
		local target = getTarget(condition.target)
		local spell, rank, name, icon, start, ending, isTradeSkill, castID, protected = UnitCastingInfo(target)
		if not spell then
			spell, rank, name, icon, start, ending, isTradeSkill, protected = UnitChannelInfo(target)
		end
		return testbool(protected ~= nil and not protected, condition[1])
	end,
	-- Check if the player is rooted
	-- returns: bool
	isrooted = function(condition)
		local rootSpellList = OvaleData:GetRootSpellList()
		return testbool(isDebuffInList(rootSpellList), condition[1])
	end,
	-- Check if the player is stunned
	-- returns: bool
	isstunned = function(condition)
		local stunSpellList = OvaleData:GetStunSpellList()
		return testbool(not HasFullControl() and isDebuffInList(stunSpellList), condition[1])
	end,
	-- Get the last spell damage value
	-- 1: the spell id
	-- returns: number or bool
	lastspelldamage = function(condition)
		local spellId = condition[1]
		if not OvaleSpellDamage:Get(spellId) then
			return nil
		end
		return compare(OvaleSpellDamage:Get(spellId), condition[2], condition[3])
	end,
	-- Get the last spell damage multiplier
	-- 1: the spell id
	-- returns: number or bool
	lastspelldamagemultiplier = function(condition)
		return compare(OvaleFuture.lastSpellDM[condition[1]], condition[2], condition[3])
	end,
	-- Get the last spell attack power
	-- 1: the spell id
	-- returns: number or bool
	lastspellattackpower = function(condition)
		return compare(OvaleFuture.lastSpellAP[condition[1]], condition[2], condition[3])
	end,
	-- Get the last spell spell power
	-- 1: the spell id
	-- returns: number or bool
	lastspellspellpower = function(condition)
		return compare(OvaleFuture.lastSpellSP[condition[1]], condition[2], condition[3])
	end,
	-- Get the time elasped since the last swing
	-- 1: main or off
	-- returns: number
	lastswing = function(condition)
		return 0, nil, 0, OvaleSwing:GetLast(condition[1]), 1
	end,
	-- Get the target level
	-- returns: bool or number
	level = function(condition)
		return compare(UnitLevel(getTarget(condition.target)), condition[1], condition[2])
	end,
	-- Get the target hit points
	-- returns: bool or number
	life = function(condition)
		local target = getTarget(condition.target)
		return compare(UnitHealth(target), condition[1], condition[2])
	end,
	-- Get the target missing hit points
	-- returns: bool or number
	lifemissing = function(condition)
		local target = getTarget(condition.target)
		return compare(UnitHealthMax(target)-UnitHealth(target), condition[1], condition[2])
	end,
	-- Get the target health percent
	-- returns: bool or number
	lifepercent = function(condition)
		--TODO: use prediction based on the DPS on the target
		local target = getTarget(condition.target)
		if UnitHealthMax(target) == nil or UnitHealthMax(target) == 0 then
			return nil
		end
		return compare(100*UnitHealth(target)/UnitHealthMax(target), condition[1], condition[2])
	end,
	-- Test if a list item is selected
	-- 1 : the list name
	-- 2 : the item name
	-- returns: bool
	list = function(condition)
		if (condition[1]) then
			if (Ovale:GetListValue(condition[1]) == condition[2]) then
				return 0
			end
		end
		return nil
	end,
	-- Get the target mana
	-- returns: bool or number
	mana = function(condition)
		local target = getTarget(condition.target)
		if target == "player" then
			return testValue(condition[1], condition[2], OvaleState.state.mana, OvaleState.currentTime, OvaleState.powerRate.mana)
		else
			return compare(UnitPower(target), condition[1], condition[2])
		end
	end,
	-- Get the target current mana percent
	-- return: bool or number
	manapercent = function(condition)
		local target = getTarget(condition.target)
		local powerMax = UnitPowerMax(target, 0)
		if not powerMax or powerMax == 0 then
			return nil
		end
		if target == "player "then
			local conversion = 100/powerMax
			return testValue(condition[1], condition[2], OvaleState.state.mana * conversion, OvaleState.currentTime, OvaleState.powerRate.mana * conversion)
		else
			return compare(UnitPower(target, 0)*100/powerMax, condition[1], condition[2])
		end
	end,
	-- Get the target maximum health
	-- return: bool or number
	maxhealth = function(condition)
		local target = getTarget(condition.target)
		return compare(UnitMaxHealth(target), condition[1], condition[2])
	end,
	-- Get the target maximum mana
	-- return: bool or number
	maxmana = function(condition)
		return compare(UnitPowerMax(getTarget(condition.target)), condition[1], condition[2])
	end,
	-- Get the time until the next swing
	-- 1: main or off
	-- return: number
	nextswing = function(condition)
		return 0, nil, 0, OvaleSwing:GetNext(condition[1]), 0, -1
	end,
	-- Get the time until the next tick
	-- 1: spell id
	-- return: number
	nexttick = function(condition)
		local start, ending = GetTargetAura(condition, getTarget(condition.target))
		local si = OvaleData.spellInfo[condition[1]]
		if not si or not si.duration then
			return nil
		end
		local ticks = floor(OvaleAura.spellHaste * (si.duration/(si.tick or 3)) + 0.5)
		local tickLength = (ending - start) / ticks
		local tickTime = start + tickLength
		for i=1,ticks do
			if OvaleState.currentTime<=tickTime then
				break
			end
			tickTime = tickTime + tickLength
		end
		return 0, nil, tickTime, 0, -1
	end,
	-- Check if the aura is not on any other unit than the current target
	-- 1: spell id
	-- return: bool
	-- alias: otherauraexpires
	otherdebuffexpires = function(condition)
		local minTime, maxTime = getOtherAura(condition[1], condition[3], "target")
		if minTime then
			local timeBefore = condition[2] or 0
			return minTime - timeBefore, nil
		end
		return 0, nil
	end,
	-- Check if the aura is present on any other unit than the current target
	-- return: bool
	-- alias: otheraurapresent
	otherdebuffpresent = function(condition)
		local minTime, maxTime = getOtherAura(condition[1], condition[3], "target")
		if maxTime and maxTime>0 then
			local timeBefore = condition[2] or 0
			return 0, addTime(maxTime, -timeBefore)
		end
		return nil
	end,
	-- Get the maximum aura remaining duration on any target
	-- return: number
	otherauraremains = function(condition)
		local minTime, maxTime = getOtherAura(condition[1])
		return 0, nil, 0, maxTime, -1 
	end,
	-- Check if the unit is present and alive
	-- return: bool
	present = function(condition)
		local present = UnitExists(getTarget(condition.target)) and not UnitIsDead(getTarget(condition.target))
		return testbool(present, condition[1])
	end,
	-- Check what was the previous spell cast
	-- 1: the spell to check
	-- return: bool
	previousspell = function(condition)
		return testbool(condition[1] == OvaleState.lastSpellId, condition[2])
	end,
	-- Check if the pet is present and alive
	-- return: bool
	petpresent = function(condition)
		local present = UnitExists("pet") and not UnitIsDead("pet")
		return testbool(present, condition[1])
	end,
	-- Get the rage
	-- return: bool or number
	rage = function(condition)
		return testValue(condition[1], condition[2], OvaleState.state.rage, OvaleState.currentTime, OvaleState.powerRate.rage)
	end,
	-- Get [target level]-[player level]
	-- return: number or bool
	relativelevel = function(condition)
		local difference
		local target = getTarget(condition.target)
		if UnitLevel(target) == -1 then
			difference = 3
		else
			difference = UnitLevel(target) - UnitLevel("player")
		end
		return compare(difference, condition[1], condition[2])
	end,
	-- Get the remaining cast time
	remainingcasttime = function(condition)
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(getTarget(condition.target))
		if not endTime then
			return nil
		end
		return 0, nil, 0, endTime/1000, -1
	end,
	-- Check if the runes are ready
	-- 1: frost, death, unholy, or blood
	-- 2: rune number
	-- ...
	-- nodeath: if 1, death runes are not allowed
	-- return: bool
	runes = function(condition)
		return GetRune(condition)
	end,
	-- Get the number of runes
	-- 1: frost, death, unholy, or blood
	-- death: if 1, death runes are allowed
	-- return: bool
	runecount = function(condition)
		return 0, nil, GetRuneCount(condition[1], condition.death)
	end,
	-- Get the remaining cooldown until the runes are ready
	-- 1: frost, death, unholy, or blood
	-- 2: rune number
	-- ...
	-- nodeath: if 1, death runes are not allowed
	-- return: number
	runescooldown = function(condition)
		local ret = GetRune(condition)
		if not ret then
			return nil
		end
		if ret < OvaleState.maintenant then
			ret = OvaleState.maintenant
		end
		return 0, nil, 0, ret, -1
	end,
	-- Get the runic power
	-- returns: bool or number
	runicpower = function(condition)
		return testValue(condition[1], condition[2], OvaleState.state.runicpower, OvaleState.currentTime, OvaleState.powerRate.runicpower)
	end,
	-- Get the shadow orbs count
	-- returns: bool or number
	shadoworbs = function(condition)
		return testValue(condition[1], condition[2], OvaleState.state.shadoworbs, OvaleState.currentTime, OvaleState.powerRate.shadoworbs)
	end,
	-- Get the number of soul shards
	-- return: number or bool
	soulshards = function(condition)
		return compare(OvaleState.state.shards, condition[1], condition[2])
	end,
	-- Get the unit speed (100 is runing speed)
	-- return: number or bool
	speed = function(condition)
		return compare(GetUnitSpeed(getTarget(condition.target))*100/7, condition[1], condition[2])
	end,
	-- Check if the spell is usable
	spellusable = function(condition)
		return testbool(IsUsableSpell(spellId), condition[1], condition[2])
	end,
	-- Get the spell cooldown
	-- 1: spell ID
	-- return: number
	spellcooldown = function(condition)
		if type(condition[1]) == "string" then
			local sharedCd = OvaleState.state.cd[condition[1]]
			if sharedCd then
				return 0, nil, sharedCD.duration, sharedCD.start, -1
			else
				return nil
			end
		elseif not OvaleData.spellList[condition[1]] then
			return 0, nil, 0, OvaleState.currentTime + 3600, -1
		else
			local actionCooldownStart, actionCooldownDuration, actionEnable = OvaleData:GetComputedSpellCD(condition[1])
			return 0, nil, actionCooldownDuration, actionCooldownStart, -1
		end
	end,
	-- Get the spell power
	-- return: number or bool
	spellpower = function(condition)
		return compare(GetSpellBonusDamage(2), condition[1], condition[2])
	end,
	-- Test if the player is in a given stance
	-- 1 : the stance
	-- return: bool
	stance = function(condition)
		if (GetShapeshiftForm() == condition[1]) then
			return 0
		else
			return nil
		end
	end,
	-- Check if the player is stealthed
	-- return: bool
	stealthed = function(condition)
		return testbool(IsStealthed(), condition[1])
	end,
	-- Get the number of talents points (1 or 0)
	-- 1 : the talent identifier (1 is the first talent in the first row, 2, the second, etc.) (use /script print(OvaleData.talentNameToId["Talent name"]) to retreive)
	-- return: number or bool
	talentpoints = function(condition)
		return compare(OvaleData:GetTalentPoints(condition[1]), condition[2], condition[3])
	end,
	-- Test if the unit target is the player (or is not)
	-- return: bool
	targetisplayer = function(condition)
		return testbool(UnitIsUnit("player",getTarget(condition.target).."target"), condition[1])
	end,
	-- Get the threat value (0 to 100)
	-- return: number
	threat = function(condition)
		local isTanking, status, threatpct = UnitDetailedThreatSituation("player", getTarget(condition.target))
		return compare(threatpct, condition[1], condition[2])
	end,
	-- Get the number of ticks of a DOT
	-- 1: spell Id
	-- return: bool or number
	ticks = function(condition)
		local si = OvaleData.spellInfo[condition[1]]
		if not si or not si.duration then return nil end
		local baseTickTime = si.tick or 3
		local haste = OvaleAura.spellHaste
		local d = si.duration
		local t = floor(( baseTickTime * haste ) + 0.5 )
		local n = d/t
		local num
		-- banker's rounding
		if n - 0.5 == floor(n) and floor(n) % 2 == 0 then
			num = ceil(n - 0.5)
		else
			num = floor(n + 0.5)
		end
		return compare(num, condition[2], condition[3])
	end,
	-- Get the remaining number of ticks
	-- 1: spell Id
	-- return: bool or number
	ticksremain = function(condition)
		local start, ending = GetTargetAura(condition, getTarget(condition.target))
		local si = OvaleData.spellInfo[condition[1]]
		if not si or not si.duration then
			return nil
		end
		local ticks = floor(OvaleAura.spellHaste * (si.duration/(si.tick or 3)) + 0.5)
		local tickLength = (ending - start) / ticks
		local tickTime = start + tickLength
		local remain = ticks - 1
		for i=1,ticks do
			if OvaleState.currentTime<=tickTime then
				break
			end
			tickTime = tickTime + tickLength
			remain = remain - 1
		end
		return start, ending, remain, tickTime, -1/tickLength
	end,
	-- Get the duration of a tick
	-- 1: spell id
	-- return: number or bool
	ticktime = function(condition)
		--TODO not correct
		local si = OvaleData.spellInfo[condition[1]]
		if not si then return nil end
		return compare(avecHate(si.tick or 3, "spell"), condition[2], condition[3])
	end,
	-- Get the time in combat
	-- return: number or bool
	timeincombat = function(condition)
		return testValue(condition[1], condition[2], 0, Ovale.combatStartTime, 1)
	end,
	-- Get the time until the unit dies
	-- return: number
	timetodie = function(condition)
		return 0, nil, 0, getTargetDead(getTarget(condition.target)), -1
	end,
	-- Get the energy
	-- returns: bool or number
	-- TODO: temp, need to allow function calls in functions call to do things link TimeTo(Energy() == 100) which would be TimeTo(Equal(Energy(), 100))
	timetomaxenergy = function(condition)
		local t = OvaleState.currentTime + OvaleState.powerRate.energy * (100 - OvaleState.state.energy)
		return 0, nil, 0, t, -1
	end,
	-- Multiply a time by the current spell haste
	-- 1: the time
	-- return: number
	timewithhaste = function(condition)
		return 0, nil, avecHate(condition[1], "spell"),0,0
	end,
	-- Check if a totem is not there
	-- 1: the totem
	-- return: bool
	totemexpires = function(condition)
		if type(condition[1]) ~= "number" then
			condition[1] = totemType[condition[1]]
		end
		
		local haveTotem, totemName, startTime, duration = GetTotemInfo(condition[1])
		if not startTime then
			return 0
		end
		if (condition.totem and OvaleData:GetSpellInfoOrNil(condition.totem)~=totemName) then
			return 0
		end
		return addTime(startTime + duration, -(condition[2] or 0))
	end,
	-- Check if a totem is present
	-- 1: the totem
	-- return: bool
	totempresent = function(condition)
		if type(condition[1]) ~= "number" then
			condition[1] = totemType[condition[1]]
		end

		local haveTotem, totemName, startTime, duration = GetTotemInfo(condition[1])
		if not startTime then
			return nil
		end
		if (condition.totem and OvaleData:GetSpellInfoOrNil(condition.totem)~=totemName) then
			return nil
		end
		return startTime, startTime + duration
	end,
	-- Check if a tracking is enabled
	-- 1: the spell id
	-- return bool
	tracking = function(condition)
		local what = OvaleData:GetSpellInfoOrNil(condition[1])
		local numTrackingTypes = GetNumTrackingTypes()
		local present = false
		for i=1,numTrackingTypes do
			local name, texture, active = GetTrackingInfo(i)
			if name == what then
				present = (active == 1)
				break
			end
		end
		return testbool(present, condition[2])
	end,
	["true"] = function(condition)
		return 0, nil
	end,
	-- Check if a weapon enchant is not present
	-- 1: mainhand or offhand
	-- [2]: the maximum time the weapon enchant should be present
	-- return bool
	weaponenchantexpires = function(condition)
		local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()
		if (condition[1] == "mainhand") then
			if (not hasMainHandEnchant) then
				return 0
			end
			mainHandExpiration = mainHandExpiration/1000
			if ((condition[2] or 0) >= mainHandExpiration) then
				return 0
			else
				return OvaleState.maintenant + mainHandExpiration - condition[2]
			end
		else
			if (not hasOffHandEnchant) then
				return 0
			end
			offHandExpiration = offHandExpiration/1000
			if ((condition[2] or 0) >= offHandExpiration) then
				return 0
			else
				return OvaleState.maintenant + offHandExpiration - condition[2]
			end
		end
	end,
}

OvaleCondition.conditions.health = OvaleCondition.conditions.life
OvaleCondition.conditions.healthpercent = OvaleCondition.conditions.lifepercent
OvaleCondition.conditions.healthmissing = OvaleCondition.conditions.lifemissing
OvaleCondition.conditions.debuffcount = OvaleCondition.conditions.buffcount
OvaleCondition.conditions.debuffexpires = OvaleCondition.conditions.buffexpires
OvaleCondition.conditions.debuffpresent = OvaleCondition.conditions.buffpresent
OvaleCondition.conditions.debuffgain = OvaleCondition.conditions.buffgain
OvaleCondition.conditions.debuffduration = OvaleCondition.conditions.buffduration
OvaleCondition.conditions.debuffremains = OvaleCondition.conditions.buffremains
OvaleCondition.conditions.debuffstacks = OvaleCondition.conditions.buffstacks
OvaleCondition.conditions.otherauraexpires = OvaleCondition.conditions.otherdebuffexpires
OvaleCondition.conditions.otheraurapresent = OvaleCondition.conditions.otherdebuffpresent
OvaleCondition.defaultTarget = "target"

--</public-static-properties>
