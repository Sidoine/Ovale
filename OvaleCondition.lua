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
	if (comparison == "more") then
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
local function getOtherAura(spellId, suppTime)
	return OvaleState:GetExpirationTimeOnAnyTarget(spellId)
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

local function GetManaAndRate(withBerserker)
	local _,className = UnitClass("player")
	local current = OvaleState.state.mana
	if current~=lastEnergyValue then
		lastEnergyValue = current
		lastEnergyTime = OvaleState.currentTime
	end
	
	local rate
	
	if className == "ROGUE" or (className == "DRUID" and GetShapeshiftForm(true) == 3) then
		rate = 10 * OvaleAura.meleeHaste
		if (className == "ROGUE") then
			local rush = OvaleState:GetAura("player", 13750)
			if rush and rush.stacks>0 then
				rate = rate * 2
			end
		elseif withBerserker then
			local berserk = OvaleState:GetAura("player", 50334)
			if berserk and berserk.stacks>0 then
				mana = mana/2
			end
		end
	elseif className == "HUNTER" then
		rate = 4 * OvaleAura.meleeHaste
	else
		rate = 0
	end
	
	return lastEnergyValue, lastEnergyTime, rate
end

local function GetManaTime(mana, withBerserker)
	local lastEnergyValue, lastEnergyTime, rate = GetManaAndRate(withBerserker)
	
	if rate > 0 then
		local limit = math.ceil((mana - lastEnergyValue) / rate + lastEnergyTime)
		return limit
	else
		if OvaleState.state.mana>=mana then
			return OvaleState.currentTime-1
		else
			return nil
		end	
	end
end


-- Recherche un aura sur la cible et récupère sa durée et le nombre de stacks
-- return start, ending, stacks
local function GetTargetAura(condition, filter, target)
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
	
	local mine = (condition.mine == 1)
	
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
		Ovale:Print("ERROR: unknown buff "..spellId)
		Ovale.bug = true
		return 0,0
	end
	
	if not aura then
		return 0,0
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
		return aura.start, ending
	else
		return 0,0
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
		return nil
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
	-- Test how many armor set parts are equiped by the player
	-- 1 : set number
	-- 2 : "more" or "less"
	-- 3 : limit 
	ArmorSetParts = function(condition)
		local nombre = 0
		if OvaleEquipement.nombre[condition[1]] then
			nombre = OvaleEquipement.nombre[condition[1]]
		end
		return compare(nombre, condition[2], condition[3])
	end,
	attackPower = function(condition)
		local base, posBuff, negBuff = UnitAttackPower("player")
		return base + posBuff + negBuff, 0, 0 
	end,
	BuffDuration = function(condition)
		--local name, rank, icon, count, debuffType, duration = UnitBuff("player", OvaleData:GetSpellInfoOrNil(condition[1]))
		--if not name then
--			return nil
	--	end
		local start, ending = GetTargetAura(condition, "HELPFUL", getTarget(condition.target))
		return compare(diffTime(start, ending), condition[2], condition[3])
	end,
	-- Test if a buff will expire on the player after a given time
	-- 1 : buff spell id
	-- 2 : expiration time 
	BuffExpires = function(condition)
		local start, ending = GetTargetAura(condition, "HELPFUL", getTarget(condition.target))
		local timeBefore = avecHate(condition[2], condition.haste)
		if Ovale.trace then
			Ovale:Print("timeBefore = " .. nilstring(timeBefore))
			Ovale:Print("start = " .. nilstring(ending))
		end
		return addTime(ending, -timeBefore)
	end,
	buffExpires = function(condition)
		local start, ending = GetTargetAura(condition, "HELPFUL", getTarget(condition.target))
		if ending then
			return ending - start, start, -1
		else
			return nil
		end
	end,
	-- Test if a time has elapsed since the last buff gain
	-- 1 : buff spell id
	-- 2 : time since the buff gain
	BuffGain = function(condition)
		local spellId = condition[1]
		local target = getTarget(condition.target)
		if spellId then
			local aura = OvaleState:GetAura(target,spellId)
			if not aura then
				return 0
			end
			local timeGain = aura.gain
			if not timeGain then
				timeGain = 0
			end
			
			return timeGain + condition[2]
		end
		return 0
	end,
	-- Test if a buff is active
	-- 1 : the buff spell id
	-- stacks : minimum number of stacks
	BuffPresent = function(condition)
		local start, ending = GetTargetAura(condition, "HELPFUL", getTarget(condition.target))
		local timeBefore = avecHate(condition[2], condition.haste)
		return start, addTime(ending, -timeBefore)
	end,
	BuffStealable = function(condition)
		local i = 1
		local stealable = false
		local target = getTarget(condition.target)
		while true do
			local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable = UnitBuff(target, i)
			if not name then
				break
			end
			if isStealable then
				stealable = true
				break
			end
			i = i + 1
		end
		return testbool(stealable, condition[1])
	end,
	Casting = function(condition)
		if OvaleState.currentSpellId == condition[1] then
			return OvaleState.startCast, OvaleState.endCast
		else
			return nil
		end
	end,
	CastTime = function(condition)
		local name, rank, icon, cost, isFunnel, powerType, castTime = OvaleData:GetSpellInfoOrNil(condition[1])
		if Ovale.trace then
			Ovale:Print("castTime/1000 = " .. (castTime/1000) .. " " .. condition[2] .. " " .. condition[3])
		end
		return compare(castTime/1000, condition[2], condition[3])
	end,
	castTime = function(condition)
		local name, rank, icon, cost, isFunnel, powerType, castTime = OvaleData:GetSpellInfoOrNil(condition[1])
		return castTime/1000, 0, 0
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
	Class = function(condition)
		local loc, noloc = UnitClass(getTarget(condition.target))
		return testbool(noloc == condition[1], condition[2])
	end,
	-- Test the target classification
	-- 1 : normal, elite, or worldboss
	Classification = function(condition)
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
		
		if (condition[1]==classification) then
			return 0
		else
			return nil
		end
	end,
	-- Test how many combo points a feral druid or a rogue has
	-- 1 : "less" or "more"
	-- 2 : the limit
	ComboPoints = function(condition)
		local points = OvaleState.state.combo
		return compare(points, condition[1], condition[2])
	end,
	comboPoints = function(condition)
		return OvaleState.state.combo, 0, 0
	end,
	Counter = function(condition)
		return compare(OvaleState:GetCounterValue(condition[1]), condition[2], condition[3])
	end,
	counter = function(condition)
		return OvaleState:GetCounterValue(condition[1]), 0, 0
	end,
	CreatureFamily = function(condition)
		return testbool(UnitCreatureFamily(getTarget(condition.target)) == LBCT[condition[1]], condition[2])
	end,
	CreatureType = function(condition)
		for _,v in pairs(condition) do
			if (UnitCreatureType(getTarget(condition.target)) == LBCT[v]) then
				return 0
			end
		end
		return nil
	end,
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
		return ret * OvaleAura.damageMultiplier, 0, 0
	end,
	damageMultiplier = function(condition)
		return OvaleAura.damageMultiplier, 0, 0
	end,
	DeadIn = function(condition)
		local deadAt = getTargetDead(getTarget(condition.target))
		if condition[1] == "more" then
			return 0, addTime(deadAt, -condition[2])
		else
			return addTime(deadAt, -condition[2]), nil
		end
	end,
	deadIn = function(condition)
		return getTargetDead(getTarget(condition.target)), 0, -1
	end,
	-- Test if a debuff will expire on the target after a given time, or if there is less than the
	-- given number of stacks (if stackable)
	-- 1 : buff spell id
	-- 2 : expiration time 
	-- stacks : how many stacks
	-- mine : 1 means that if the debuff is not ours, the debuff is ignored
	DebuffExpires = function(condition)
		local start, ending = GetTargetAura(condition, "HARMFUL", getTarget(condition.target))
		local tempsMax = avecHate(condition[2], condition.haste)
		return addTime(ending, -tempsMax)
	end,
	debuffExpires = function(condition)
		local start, ending = GetTargetAura(condition, "HARMFUL", getTarget(condition.target))
		if ending then
			return ending - start, start, -1
		else
			return nil
		end
	end,
	DebuffPresent = function(condition)
		local start, ending = GetTargetAura(condition, "HARMFUL", getTarget(condition.target))
		local timeBefore = avecHate(condition[2], condition.haste)
		return start, addTime(ending, -timeBefore)
	end,
	Distance = function(condition)
		if LRC then
			local target = getTarget(condition.target)
			local minRange, maxRange = LRC:GetRange(target)
			if maxRange == nil or minRange == nil then
				return nil
			end
			if condition[1] == "more" then
				if condition[2]~=nil and maxRange>condition[2] then
					return 0
				else
					return nil
				end
			else
				if condition[2]~=nil and minRange<condition[2] then
					return 0
				else
					return nil
				end
			end
		end
	end,
	distance = function(condition)
		if LRC then
			return LRC:GetRange(getTarget(condition.target))
		else
			return nil
		end		
	end,
	--Compare to eclipse power. <0 lunar, >0 solar
	Eclipse = function(condition)
		return compare(OvaleState.state.eclipse, condition[1], condition[2])
	end,
	eclipse = function(condition)
		return OvaleState.state.eclipse
	end,
	EffectiveMana = function(condition)
		local limit = GetManaTime(condition[2], true)
		if condition[1]=="more" then
			return limit, nil
		else
			return 0,limit
		end
	end,
	effectiveMana = function(condition)
		return GetManaAndRate(true)
	end,
	EndCastTime = function(condition)
		local name, rank, icon, cost, isFunnel, powerType, castTime = OvaleData:GetSpellInfoOrNil(condition[1])
		local actionCooldownStart, actionCooldownDuration, actionEnable = OvaleData:GetComputedSpellCD(condition[1])
		local startCast = actionCooldownStart + actionCooldownDuration
		if startCast<OvaleState.currentTime then
			startCast = OvaleState.currentTime
		end
		return startCast + castTime/1000
	end,
	enemies = function(condition)
		return OvaleEnemies:GetNumberOfEnemies(), 0, 0
	end,
	Exists = function(condition)
		return testbool(UnitExists(getTarget(condition.target)) == 1, condition[1])
	end,
	Glyph = function(condition)
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
	HolyPower = function(condition)
		return compare(OvaleState.state.holy, condition[1], condition[2])
	end,
	holyPower = function(condition)
		return OvaleState.state.holy, 0, 0
	end,
	InCombat = function(condition)
		return testbool(Ovale.enCombat, condition[1])
	end,
	InRange = function(condition)
		local spellName = GetSpellInfo(condition[1])
		return testbool(IsSpellInRange(spellName,getTarget(condition.target))==1,condition[2])
	end,
	item = function(condition)
		local actionCooldownStart, actionCooldownDuration, actionEnable = GetItemCooldown(condition[1])
		return actionCooldownDuration, actionCooldownStart, -1
	end,
	ItemCount = function(condition)
		if condition.charges == 1 then
			return compare(GetItemCount(condition[1], false, true), condition[2], condition[3])
		else
			return compare(GetItemCount(condition[1]), condition[2], condition[3])
		end
	end,
	itemCount = function(condition)
		if condition.charges == 1 then
			return GetItemCount(condition[1], false, true), 0, 0
		else
			return GetItemCount(condition[1]), 0, 0
		end
	end,
	IsCasting = function(condition)
		local casting
		local target = getTarget(condition.target)
		local spellId = condition.spell
		if not spellId then
			return testbool(UnitCastingInfo(target) or UnitChannelInfo(target), condition[1])
		elseif type(spellId) == "number" then
			local spellName = GetSpellInfo(spellId)
			return testbool(UnitCastingInfo(target)==spellName or UnitChannelInfo(target) == spellName, condition[1])
		elseif OvaleData.buffSpellList[spellId] then
			local castSpellName = UnitCastingInfo(target) or UnitChannelInfo(target)
			local found = false
			for k,v in pairs(OvaleData.buffSpellList[spellId]) do
				local spellName = GetSpellInfo(v)
				if spellName == castSpellName then
					found = true
					break
				end
			end
			return testbool(found, condition[1])
		elseif spellId == "harmful" then
			local castSpellName = UnitCastingInfo(target) or UnitChannelInfo(target)
			return testbool(castSpellName and IsHarmfulSpell(castSpellName), condition[1])
		elseif spellId == "helpful" then
			local castSpellName = UnitCastingInfo(target) or UnitChannelInfo(target)
			return testbool(castSpellName and IsHelpfulSpell(castSpellName), condition[1])
		end
	end,
	IsFeared = function(condition)
		local fearSpellList = OvaleData:GetFearSpellList()
		return testbool(not HasFullControl() and isDebuffInList(fearSpellList), condition[1])
	end,
	IsFriend = function(condition)
		return testbool(UnitIsFriend("player", getTarget(condition.target)), condition[1])
	end,
	IsIncapacitated = function(condition)
		local incapacitateSpellList = OvaleData:GetIncapacitateSpellList()
		return testbool(not HasFullControl() and isDebuffInList(incapacitateSpellList), condition[1])
	end,
	IsInterruptible = function(condition)
		local target = getTarget(condition.target)
		local spell, rank, name, icon, start, ending, isTradeSkill, castID, protected = UnitCastingInfo(target)
		if not spell then
			spell, rank, name, icon, start, ending, isTradeSkill, protected = UnitChannelInfo(target)
		end
		return testbool(protected ~= nil and not protected, condition[1])
	end,
	IsRooted = function(condition)
		local rootSpellList = OvaleData:GetRootSpellList()
		return testbool(isDebuffInList(rootSpellList), condition[1])
	end,
	IsStunned = function(condition)
		local stunSpellList = OvaleData:GetStunSpellList()
		return testbool(not HasFullControl() and isDebuffInList(stunSpellList), condition[1])
	end,
	LastSpellDamage = function(condition)
		local spellId = condition[1]
		if not OvaleSpellDamage:Get(spellId) then
			return nil
		end
		return compare(OvaleSpellDamage:Get(spellId), condition[2], condition[3])
	end,
	lastSpellDamage = function(condition)
		return OvaleSpellDamage:Get(condition[1])
	end,
	lastSpellDamageMultiplier = function(condition)
		return OvaleFuture.lastSpellDM[condition[1]], 0, 0
	end,
	lastSpellAttackPower = function(condition)
		return OvaleFuture.lastSpellAP[condition[1]], 0, 0 
	end,
	lastSpellSpellPower = function(condition)
		return OvaleFuture.lastSpellSP[condition[1]], 0, 0 
	end,
	LastSwing = function(condition)
		local ret = OvaleSwing:GetLast(condition[1])
		if condition[2] and ret then
			ret = ret + condition[2]
		end
		return 0, ret
	end,
	lastSwing = function(condition)
		return OvaleState.currentTime - OvaleSwing:GetLast(condition[1]), 0, 1
	end,
	-- Compare with the player level
	-- 1 : "less" or "more"
	-- 2 : the limit
	Level = function(condition)
		return compare(UnitLevel(getTarget(condition.target)), condition[1], condition[2])
	end,
	level = function(condition)
		return UnitLevel(condition.target)
	end,
	Life = function(condition)
		local target = getTarget(condition.target)
		return compare(UnitHealth(target), condition[1], condition[2])
	end,
	life = function(condition)
		local target = getTarget(condition.target)
		return UnitHealth(target), 0, 0
	end,
	LifeMissing = function(condition)
		local target = getTarget(condition.target)
		return compare(UnitHealthMax(target)-UnitHealth(target), condition[1], condition[2])
	end,
	lifeMissing = function(condition)
		local target = getTarget(condition.target)
		return UnitHealthMax(target)-UnitHealth(target), 0, 0
	end,
	-- Test if the player life is bellow/above a given value in percent
	-- 1 : "less" or "more"
	-- 2 : the limit, in percent
	LifePercent = function(condition)
		local target = getTarget(condition.target)
		if UnitHealthMax(target) == nil or UnitHealthMax(target) == 0 then
			return nil
		end
		return compare(UnitHealth(target)/UnitHealthMax(target), condition[1], condition[2]/100)
	end,
	lifePercent = function(condition)
		local target = getTarget(condition.target)
		if UnitHealthMax(target) == nil or UnitHealthMax(target) == 0 then
			return nil
		end
		return 100 * UnitHealth(target)/UnitHealthMax(target), 0, 0
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
		local target = getTarget(condition.target)
		if target == "player" then
			local limit = GetManaTime(condition[2], false)
			if condition[1]=="more" then
				return limit, nil
			else
				return 0,limit
			end
		else
			return compare(UnitPower(target), condition[1], condition[2])
		end
	end,
	mana = function(condition)
		return GetManaAndRate(false)
	end,
	ManaPercent = function(condition)
		local target = getTarget(condition.target)
		if UnitPowerMax(target) == 0 then
			return nil
		end
		return compare(UnitPower(target)/UnitPowerMax(target), condition[1], condition[2]/100)
	end,
	manaPercent = function(condition)
		local target = getTarget(condition.target)
		if UnitPowerMax(target) == 0 then
			return nil
		end
		local value, t, rate = GetManaAndRate(false)
		local conversion = 100/UnitPowerMax(target)
		return value * conversion, t, rate * conversion
	end,
	MaxHealth = function(condition)
		local target = getTarget(condition.target)
		return compare(UnitMaxHealth(target), condition[1], condition[2])
	end,
	maxHealth = function(condition)
		return UnitMaxHealth(getTarget(condition.target)), 0, 0
	end,
	maxMana = function(condition)
		return UnitPowerMax(getTarget(condition.target)), 0, 0
	end,
	NextSwing = function(condition)
		local ret = OvaleSwing:GetNext(condition[1])
		if condition[2] and ret then
			ret = ret - condition[2]
		end
		return ret
	end,
	nextSwing = function(condition)
		return OvaleSwing:GetNext(condition[1]) - OvaleState.currentTime, 0, -1
	end,
	nextTick = function(condition)
		local start, ending = GetTargetAura(condition, "HARMFUL", getTarget(condition.target))
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
		return tickTime, 0, -1
	end,
	OtherDebuffExpires = function(condition)
		local minTime, maxTime = getOtherAura(condition[1], condition[3])
		if minTime then
			local timeBefore = condition[2] or 0
			return minTime - timeBefore, nil
		end
		return 0, nil
	end,
	OtherDebuffPresent = function(condition)
		local minTime, maxTime = getOtherAura(condition[1], condition[3])
		if maxTime and maxTime>0 then
			local timeBefore = condition[2] or 0
			return 0, addTime(maxTime, -timeBefore)
		end
		return nil
	end,
	OtherAuraExpires = OtherDebuffExpires,
	OtherAuraPresent = OtherDebuffPresent,
	otherAura = function(condition)
		local minTime, maxTime = getOtherAura(condition[1])
		return 0, maxTime, -1 
	end,
	Present = function(condition)
		local present = UnitExists(getTarget(condition.target)) and not UnitIsDead(getTarget(condition.target))
		return testbool(present, condition[1])
	end,
	-- Test if any player pet is present (or not)
	-- 1 : "yes" or "no"
	PetPresent = function(condition)
		local present = UnitExists("pet") and not UnitIsDead("pet")
		return testbool(present, condition[1])
	end,
	-- Test the target level difference with the player
	-- 1 : "less" or "more"
	-- 2 : [target level]-[player level] limit
	RelativeLevel = function(condition)
		local difference
		local target = getTarget(condition.target)
		if UnitLevel(target) == -1 then
			difference = 3
		else
			difference = UnitLevel(target) - UnitLevel("player")
		end

		return compare(difference, condition[1], condition[2])
	end,
	remainingCastTime = function(condition)
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(getTarget(condition.target))
		if not endTime then
			return nil
		end
		return 0, endTime/1000, -1
	end,
	Runes = function(condition)
		return GetRune(condition)
	end,
	runes = function(condition)
		local ret = GetRune(condition)
		if not ret then
			return nil
		end
		if ret < OvaleState.maintenant then
			ret = OvaleState.maintenant
		end
		return 0, ret, -1
	end,
	SoulShards = function(condition)
		return compare(OvaleState.state.shard, condition[1], condition[2])
	end,
	soulShards = function(condition)
		return OvaleState.state.shard
	end,
	Speed = function(condition)
		return compare(GetUnitSpeed(getTarget(condition.target))*100/7, condition[1], condition[2])
	end,
	speed = function(condition)
		return GetUnitSpeed(getTarget(condition.target))*100/7
	end,
	spell = function(condition)
		local actionCooldownStart, actionCooldownDuration, actionEnable = OvaleData:GetComputedSpellCD(condition[1])
		return actionCooldownDuration, actionCooldownStart, -1
	end,
	spellPower = function(condition)
		return GetSpellBonusDamage(2), 0, 0
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
	Stealthed = function(condition)
		return testbool(IsStealthed(), condition[1])
	end,
	-- Test how many talent points has been spent in a talent
	-- 1 : the talent identifier (use /script print(OvaleData.talentNameToId["Talent name"]) to retreive)
	-- 2 : "more" or "less"
	-- 3 : the limit
	TalentPoints = function(condition)
		return compare(OvaleData:GetTalentPoints(condition[1]), condition[2], condition[3])
	end,
	talentPoints = function(condition)
		return OvaleData:GetTalentPoints(condition[1]), 0, 0
	end,
	-- Test if the target's target is the player (or is not)
	-- 1 : "yes" (it should be the player) or "no"
	TargetIsPlayer = function(condition)
		return testbool(UnitIsUnit("player",getTarget(condition.target).."target"), condition[1])
	end,
	Threat = function(condition)
		local isTanking, status, threatpct = UnitDetailedThreatSituation("player", getTarget(condition.target))
		return compare(threatpct, condition[1], condition[2])
	end,
	threat = function(condition)
		local isTanking, status, threatpct = UnitDetailedThreatSituation("player", getTarget(condition.target))
		return threatpct
	end,
	TimeInCombat = function(condition)
		if not Ovale.combatStartTime then
			return nil
		elseif condition[1] == "more" then
			return Ovale.combatStartTime + condition[2]
		else
			return 0, Ovale.combatStartTime + condition[2]
		end
	end,
	timeInCombat = function(condition)
		return OvaleState.maintenant - Ovale.combatStartTime, OvaleState.maintenant, 1
	end,
	timeToDie = function(condition)
		return 0, getTargetDead(getTarget(condition.target)), -1
	end,
	timeWithHaste = function(condition)
		return avecHate(condition[1], "spell"),0,0
	end,
	TotemExpires = function(condition)
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
	TotemPresent = function(condition)
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
	Tracking = function(condition)
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
	WeaponEnchantExpires = function(condition)
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
OvaleCondition.conditions.Health = OvaleCondition.conditions.Life
OvaleCondition.conditions.healthPercent = OvaleCondition.conditions.lifePercent
OvaleCondition.conditions.HealthPercent = OvaleCondition.conditions.LifePercent
OvaleCondition.conditions.HealthMissing = OvaleCondition.conditions.LifeMissing
OvaleCondition.defaultTarget = "target"

--</public-static-properties>
