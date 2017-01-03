local OVALE, Ovale = ...
local DBM = DBM
local OvaleBossMod = Ovale:NewModule("OvaleBossMod")
Ovale.OvaleBossMod = OvaleBossMod

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
		BigWigsLoader.RegisterMessage(owner, "BigWigs_OnBossEngage", function(_, module, diff)
			OvaleBossMod.EngagedBigWigs = module
		end)
		BigWigsLoader.RegisterMessage(owner, "BigWigs_OnBossDisable", function(_, module)
			OvaleBossMod.EngagedBigWigs = nil
		end)
	end
end

function OvaleBossMod:OnDisable()
	
end

function OvaleBossMod:HasBossMod()
	return DBM ~= nil or BigWigsLoader ~= nil
end

function OvaleBossMod:IsBossEngaged()
	return OvaleBossMod:HasBossMod() and OvaleBossMod.EngagedDBM ~= nil and OvaleBossMod.EngagedDBM.inCombat and true -- DBM
		or OvaleBossMod:HasBossMod() and OvaleBossMod.EngagedBigWigs ~= nil and OvaleBossMod.EngagedBigWigs.isEngaged and true -- Bigwigs
		or false -- neither
end