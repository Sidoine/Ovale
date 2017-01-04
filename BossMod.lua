local OVALE, Ovale = ...
local OvaleBossMod = Ovale:NewModule("OvaleBossMod")
Ovale.OvaleBossMod = OvaleBossMod

local API_GetNumGroupMembers = GetNumGroupMembers
local API_IsInGroup = IsInGroup
local API_IsInInstance = IsInInstance
local API_IsInRaid = IsInRaid
local API_UnitExists = UnitExists
local API_UnitLevel = UnitLevel
local BigWigsLoader = BigWigsLoader
local DBM = DBM

local OvaleDebug = Ovale.OvaleDebug
local OvaleProfiler = Ovale.OvaleProfiler

OvaleDebug:RegisterDebugging(OvaleBossMod)
OvaleProfiler:RegisterProfiling(OvaleBossMod)

function OvaleBossMod:OnInitialize()
	OvaleBossMod.EngagedDBM = nil
	OvaleBossMod.EngagedBigWigs = nil
end

function OvaleBossMod:OnEnable()
	-- hook into DBM if DBM is loaded
	if DBM then
		hooksecurefunc(DBM, "StartCombat", function(DBM, mod, delay, event, ...)
			if event ~= "TIMER_RECOVERY" then
				OvaleBossMod.EngagedDBM = mod
			end
		end)
		hooksecurefunc(DBM, "EndCombat", function(DBM, mod)
			OvaleBossMod.EngagedDBM = nil
		end)
	end
	if BigWigsLoader then
		BigWigsLoader.RegisterMessage(owner, "BigWigs_OnBossEngage", function(_, mod, diff)
			OvaleBossMod.EngagedBigWigs = mod
		end)
		BigWigsLoader.RegisterMessage(owner, "BigWigs_OnBossDisable", function(_, mod)
			OvaleBossMod.EngagedBigWigs = nil
		end)
	end
end

function OvaleBossMod:OnDisable()
	
end

function OvaleBossMod:IsBossEngaged(state)
	-- return false when we're not in combat, no reason to check
	if not state.inCombat then
		return false
	end
	
	local dbmEngaged = (DBM ~= nil and OvaleBossMod.EngagedDBM ~= nil and OvaleBossMod.EngagedDBM.inCombat) -- DBM
	local bigWigsEngaged = (BigWigsLoader ~= nil and OvaleBossMod.EngagedBigWigs ~= nil and OvaleBossMod.EngagedBigWigs.isEngaged)-- Bigwigs
	local neitherEngaged = (DBM == nil and BigWigsLoader == nil and OvaleBossMod:ScanTargets()) -- neither
	
	if dbmEngaged then
		self:Debug("DBM Engaged: [id=%s]", OvaleBossMod.EngagedDBM.id)
	end
	if bigWigsEngaged then
		self:Debug("BigWigs Engaged: [displayName=%s]", OvaleBossMod.EngagedBigWigs.displayName)
	end
	
	return dbmEngaged or bigWigsEngaged or neitherEngaged
end

function OvaleBossMod:ScanTargets()
	self:StartProfiling("OvaleBossMod:ScanTargets")
	local function RecursiveScanTargets(target, depth)
		local isWorldBoss = false
		local dep = depth or 1

		local isWorldBoss = target ~= nil and API_UnitExists(target) and API_UnitLevel(target) < 0
		if isWorldBoss then
			self:Debug("%s is worldboss (%s)", target, UnitName(target))
		end
		-- we don't want to loop indefinately, basically we just want to go until <unit>targettarget
		return isWorldBoss or (dep <= 3 and RecursiveScanTargets(target .. "target", dep + 1))
	end
	
	local bossEngaged = false
	-- scan for boss1, boss2, boss3, boss4 unitids
	bossEngaged = bossEngaged or API_UnitExists("boss1") or API_UnitExists("boss2") or API_UnitExists("boss3") or API_UnitExists("boss4")

	-- scan targets for worldbosses
	bossEngaged = bossEngaged 
		or RecursiveScanTargets("target") 
		or RecursiveScanTargets("pet") 
		or RecursiveScanTargets("focus") 
		or RecursiveScanTargets("focuspet") 
		or RecursiveScanTargets("mouseover") 
		or RecursiveScanTargets("mouseoverpet")
	
	-- what is we're in a party or a raid?
	if not bossEngaged then
		if (API_IsInInstance() and API_IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 1) then
			for i=1,API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) do
				bossEngaged = bossEngaged or RecursiveScanTargets("party"..i) or RecursiveScanTargets("party"..i.."pet")
			end
		end
		if (not API_IsInInstance() and API_IsInGroup(LE_PARTY_CATEGORY_HOME) and API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1) then
			for i=1,API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) do
				bossEngaged = bossEngaged or RecursiveScanTargets("party"..i) or RecursiveScanTargets("party"..i.."pet")
			end
		end
		if (API_IsInInstance() and API_IsInRaid(LE_PARTY_CATEGORY_INSTANCE) and API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 1) then
			for i=1,API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) do
				bossEngaged = bossEngaged or RecursiveScanTargets("raid"..i) or RecursiveScanTargets("raid"..i.."pet")
			end
		end
		if (not API_IsInInstance() and API_IsInRaid(LE_PARTY_CATEGORY_HOME) and API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1) then
			for i=1,API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) do
				bossEngaged = bossEngaged or RecursiveScanTargets("raid"..i) or RecursiveScanTargets("raid"..i.."pet")
			end
		end
	end
	
	self:StopProfiling("OvaleBossMod:ScanTargets")
	return bossEngaged
end