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

__exports.registerScripts = function(ovaleScripts)
	-- For each created register link it here to ovaleScripts.
	-- Example:
	-- registerDruidFeralHooves(ovaleScripts)
end
