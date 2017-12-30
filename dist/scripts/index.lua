local __exports = LibStub:NewLibrary("ovale/scripts/index", 10000)
if not __exports then return end
local __ovale_common = LibStub:GetLibrary("ovale/scripts/ovale_common")
local scommon = __ovale_common.register
local __ovale_deathknight_spells = LibStub:GetLibrary("ovale/scripts/ovale_deathknight_spells")
local sdk = __ovale_deathknight_spells.register
local __ovale_demonhunter_spells = LibStub:GetLibrary("ovale/scripts/ovale_demonhunter_spells")
local sdh = __ovale_demonhunter_spells.register
local __ovale_druid_spells = LibStub:GetLibrary("ovale/scripts/ovale_druid_spells")
local sdr = __ovale_druid_spells.register
local __ovale_hunter_spells = LibStub:GetLibrary("ovale/scripts/ovale_hunter_spells")
local sh = __ovale_hunter_spells.register
local __ovale_mage_spells = LibStub:GetLibrary("ovale/scripts/ovale_mage_spells")
local sm = __ovale_mage_spells.register
local __ovale_monk_spells = LibStub:GetLibrary("ovale/scripts/ovale_monk_spells")
local smk = __ovale_monk_spells.register
local __ovale_paladin_spells = LibStub:GetLibrary("ovale/scripts/ovale_paladin_spells")
local sp = __ovale_paladin_spells.register
local __ovale_priest_spells = LibStub:GetLibrary("ovale/scripts/ovale_priest_spells")
local spr = __ovale_priest_spells.register
local __ovale_rogue_spells = LibStub:GetLibrary("ovale/scripts/ovale_rogue_spells")
local sr = __ovale_rogue_spells.register
local __ovale_shaman_spells = LibStub:GetLibrary("ovale/scripts/ovale_shaman_spells")
local ss = __ovale_shaman_spells.register
local __ovale_warlock_spells = LibStub:GetLibrary("ovale/scripts/ovale_warlock_spells")
local swl = __ovale_warlock_spells.register
local __ovale_warrior_spells = LibStub:GetLibrary("ovale/scripts/ovale_warrior_spells")
local swr = __ovale_warrior_spells.register
local __ovale_trinkets_mop = LibStub:GetLibrary("ovale/scripts/ovale_trinkets_mop")
local tm = __ovale_trinkets_mop.register
local __ovale_trinkets_wod = LibStub:GetLibrary("ovale/scripts/ovale_trinkets_wod")
local tw = __ovale_trinkets_wod.register
__exports.registerScripts = function()
    scommon()
    sdk()
    sdh()
    sdr()
    sh()
    sm()
    smk()
    sp()
    spr()
    sr()
    ss()
    swl()
    swr()
    tm()
    tw()
end
