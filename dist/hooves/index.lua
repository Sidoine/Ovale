local __exports = LibStub:NewLibrary("ovale/hooves/index", 80201)
if not __exports then return end
local __ovale_deathknight = LibStub:GetLibrary("ovale/scripts/ovale_deathknight")
local __ovale_demonhunter = LibStub:GetLibrary("ovale/scripts/ovale_demonhunter")
local __ovale_druid = LibStub:GetLibrary("ovale/scripts/ovale_druid")
local __ovale_hunter = LibStub:GetLibrary("ovale/scripts/ovale_hunter")
local __ovale_mage = LibStub:GetLibrary("ovale/scripts/ovale_mage")
local __ovale_monk = LibStub:GetLibrary("ovale/scripts/ovale_monk")
local __ovale_paladin = LibStub:GetLibrary("ovale/scripts/ovale_paladin")
local __ovale_priest = LibStub:GetLibrary("ovale/scripts/ovale_priest")
local __ovale_rogue = LibStub:GetLibrary("ovale/scripts/ovale_rogue")
local __ovale_shaman = LibStub:GetLibrary("ovale/scripts/ovale_shaman")
local __ovale_warlock = LibStub:GetLibrary("ovale/scripts/ovale_warlock")
local __ovale_warrior = LibStub:GetLibrary("ovale/scripts/ovale_warrior")

-- For every script create a new entry here.
-- Example:
-- local registerDruidFeralHooves = __ovale_druid.registerDruidFeralHooves
local registerDruidGuardianHooves = __ovale_druid.registerDruidGuardianHooves
local registerDruidFeralToast = __ovale_druid.registerDruidFeralToast
local registerMonkBrewmasterHooves = __ovale_monk.registerMonkBrewmasterHooves
local registerWarriorProtectionHooves = __ovale_warrior.registerWarriorProtectionHooves
local registerPaladinProtectionHooves = __ovale_paladin.registerPaladinProtectionHooves
local registerPaladinRetributionHooves = __ovale_paladin.registerPaladinRetributionHooves
local registerRogueOutlawHooves = __ovale_rogue.registerRogueOutlawHooves
local registerDemonHunterHavocHooves = __ovale_demonhunter.registerDemonHunterHavocHooves
__exports.registerScripts = function(ovaleScripts)
	registerMonkBrewmasterHooves(ovaleScripts)
	registerDruidFeralToast(ovaleScripts)
	registerDruidGuardianHooves(ovaleScripts)
	registerWarriorProtectionHooves(ovaleScripts)
	registerPaladinProtectionHooves(ovaleScripts)
	registerPaladinRetributionHooves(ovaleScripts)
	registerRogueOutlawHooves(ovaleScripts)
	registerDemonHunterHavocHooves(ovaleScripts)
	-- For each created register link it here to ovaleScripts.
	-- Example:
	-- registerDruidFeralHooves(ovaleScripts)
end
