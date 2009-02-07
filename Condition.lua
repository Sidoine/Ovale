local LBCT = LibStub("LibBabble-CreatureType-3.0"):GetLookupTable()

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
	if (condition == "yes") then
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

Ovale.conditions=
{
	-- Test if a white hit just occured
	-- 1 : maximum time after a white hit
	AfterWhiteHit = function(condition)
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
	end,
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
		local buffName = Ovale:GetSpellInfoOrNil(condition[1])
		local i=1;
		while (true) do
			local name, rank, icon, count, debuffType, duration, expirationTime, isMine, isStealable =  UnitBuff("player", i);
			if (not name) then
				break
			end
			if (name == buffName) then
				local timeLeft = expirationTime - Ovale.maintenant
				local timeBefore = avecHate(condition[2], condition.haste)
				if (timeLeft<timeBefore) then
					return 0
				else
					return timeLeft-timeBefore
				end
			end
			i = i + 1;
		end
		return 0
	end,
	-- Test if a buff is active
	-- 1 : the buff spell id
	-- stacks : minimum number of stacks
	BuffPresent = function(condition)
		if (not condition[1]) then
			return nil
		end
		local buffName, buffRank, buffIcon = Ovale:GetSpellInfoOrNil(condition[1])
		i=1;
		while (true) do
			local name, rank, icon, count, debuffType, duration, expirationTime, isMine, isStealable =  UnitBuff("player", i);
			if (not name) then
				break
			end
			if (name == buffName and icon==buffIcon) then
				if (condition.stacks) then
					if (count>=condition.stacks) then
						return 0
					else
						return nil
					end
				else 
					return 0
				end
			end
			i = i + 1;
		end
		return nil
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
		local points = GetComboPoints("player")
		return compare(points, condition[1], condition[2])
	end,
	HasShield = function(condition)
		local _,_,id = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("SecondaryHandSlot")) or "","(item:%d+:%d+:%d+:%d+)")
		if (not id) then
			return nil
		end
		
		local _,_,_,_,_,_,_,_,itemLoc = GetItemInfo(id)
		if (itemLoc=="INVTYPE_SHIELD") then
			return 0
		else
			return nil
		end
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
		return compare(UnitPower("player"), condition[1], condition[2])
	end,
	-- Test if any player pet is present (or not)
	-- 1 : "yes" or "no"
	PetPresent = function(condition)
		local present = UnitExists("pet") and not UnitIsDead("pet")
		return testbool(present, condition[1])
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
	-- Test if a debuff will expire on the target after a given time, or if there is less than the
	-- given number of stacks (if stackable)
	-- 1 : buff spell id
	-- 2 : expiration time 
	-- stacks : how many stacks
	-- mine : 1 means that if the debuff is not ours, the debuff is ignored
	TargetDebuffExpires = function(condition)
		local debuffName = Ovale:GetSpellInfoOrNil(condition[1])
		i=1;
		while (true) do
			local name, rank, icon, count, debuffType, duration, expirationTime, isMine, isStealable =  UnitDebuff("target", i);
			if (not name) then
				break
			end
			if (not condition.mine or isMine) then
				if (name == debuffName) then
					local timeLeft = expirationTime - Ovale.maintenant
					local tempsMax = avecHate(condition[2], condition.haste)
					if (timeLeft<tempsMax) then
						return 0
					elseif (count~=0 and condition.stacks and count<condition.stacks) then
						return 0
					else
						return timeLeft-tempsMax
					end
				end
			end
			i = i + 1;
		end
		return 0
	end,
	-- Test if a debuff is present on the target
	-- 1 : debuff spell id
	-- stacks : how many stacks
	-- mine : 1 means that the debuff must be yours
	TargetDebuffPresent = function(condition)
		local debuffName = Ovale:GetSpellInfoOrNil(condition[1])
		i=1;
		while (true) do
			local name, rank, icon, count, debuffType, duration, expirationTime, isMine, isStealable =  UnitDebuff("target", i);
			if (not name) then
				break
			end
			if (not condition.mine or isMine) then
				if (name == debuffName) then
					local timeLeft = expirationTime - Ovale.maintenant
					if (count~=0 and condition.stacks) then
						if (count<condition.stacks) then
							return nil
						else
							return 0
						end
					else
						return 0
					end
				end
			end
			i = i + 1;
		end
		return 0
	end,
	-- Test if the target life is bellow/above a given value in percent
	-- 1 : "less" or "more"
	-- 2 : the limit, in percents
	TargetLifePercent = function(condition)
		return compare(UnitHealth("target")/UnitHealthMax("target"), condition[1], condition[2]/100)
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
	end
}