local __exports = LibStub:NewLibrary("ovale/scripts/index", 80300)
if not __exports then return end
local __ovale_common = LibStub:GetLibrary("ovale/scripts/ovale_common")
local registerCommon = __ovale_common.registerCommon
local __ovale_deathknight_spells = LibStub:GetLibrary("ovale/scripts/ovale_deathknight_spells")
local registerDeathKnightSpells = __ovale_deathknight_spells.registerDeathKnightSpells
local __ovale_deathknight = LibStub:GetLibrary("ovale/scripts/ovale_deathknight")
local registerDeathKnight = __ovale_deathknight.registerDeathKnight
local __ovale_demonhunter = LibStub:GetLibrary("ovale/scripts/ovale_demonhunter")
local registerDemonHunter = __ovale_demonhunter.registerDemonHunter
local __ovale_druid = LibStub:GetLibrary("ovale/scripts/ovale_druid")
local registerDruid = __ovale_druid.registerDruid
local __ovale_hunter = LibStub:GetLibrary("ovale/scripts/ovale_hunter")
local registerHunter = __ovale_hunter.registerHunter
local __ovale_mage = LibStub:GetLibrary("ovale/scripts/ovale_mage")
local registerMage = __ovale_mage.registerMage
local __ovale_monk = LibStub:GetLibrary("ovale/scripts/ovale_monk")
local registerMonk = __ovale_monk.registerMonk
local __ovale_paladin = LibStub:GetLibrary("ovale/scripts/ovale_paladin")
local registerPaladin = __ovale_paladin.registerPaladin
local __ovale_priest = LibStub:GetLibrary("ovale/scripts/ovale_priest")
local registerPriest = __ovale_priest.registerPriest
local __ovale_rogue = LibStub:GetLibrary("ovale/scripts/ovale_rogue")
local registerRogue = __ovale_rogue.registerRogue
local __ovale_shaman = LibStub:GetLibrary("ovale/scripts/ovale_shaman")
local registerShaman = __ovale_shaman.registerShaman
local __ovale_warlock = LibStub:GetLibrary("ovale/scripts/ovale_warlock")
local registerWarlock = __ovale_warlock.registerWarlock
local __ovale_warrior = LibStub:GetLibrary("ovale/scripts/ovale_warrior")
local registerWarrior = __ovale_warrior.registerWarrior
local __ovale_demonhunter_spells = LibStub:GetLibrary("ovale/scripts/ovale_demonhunter_spells")
local registerDemonHunterSpells = __ovale_demonhunter_spells.registerDemonHunterSpells
local __ovale_trinkets_wod = LibStub:GetLibrary("ovale/scripts/ovale_trinkets_wod")
local registerWodTrinkets = __ovale_trinkets_wod.registerWodTrinkets
local __ovale_druid_spells = LibStub:GetLibrary("ovale/scripts/ovale_druid_spells")
local registerDruidSpells = __ovale_druid_spells.registerDruidSpells
local __ovale_hunter_spells = LibStub:GetLibrary("ovale/scripts/ovale_hunter_spells")
local registerHunterSpells = __ovale_hunter_spells.registerHunterSpells
local __ovale_mage_spells = LibStub:GetLibrary("ovale/scripts/ovale_mage_spells")
local registerMageSpells = __ovale_mage_spells.registerMageSpells
local __ovale_monk_spells = LibStub:GetLibrary("ovale/scripts/ovale_monk_spells")
local registerMonkSpells = __ovale_monk_spells.registerMonkSpells
local __ovale_paladin_spells = LibStub:GetLibrary("ovale/scripts/ovale_paladin_spells")
local registerPaladinSpells = __ovale_paladin_spells.registerPaladinSpells
local __ovale_priest_spells = LibStub:GetLibrary("ovale/scripts/ovale_priest_spells")
local registerPriestSpells = __ovale_priest_spells.registerPriestSpells
local __ovale_rogue_spells = LibStub:GetLibrary("ovale/scripts/ovale_rogue_spells")
local registerRogueSpells = __ovale_rogue_spells.registerRogueSpells
local __ovale_shaman_spells = LibStub:GetLibrary("ovale/scripts/ovale_shaman_spells")
local registerShamanSpells = __ovale_shaman_spells.registerShamanSpells
local __ovale_warlock_spells = LibStub:GetLibrary("ovale/scripts/ovale_warlock_spells")
local registerWarlockSpells = __ovale_warlock_spells.registerWarlockSpells
local __ovale_warrior_spells = LibStub:GetLibrary("ovale/scripts/ovale_warrior_spells")
local registerWarriorSpells = __ovale_warrior_spells.registerWarriorSpells
local __ovale_trinkets_mop = LibStub:GetLibrary("ovale/scripts/ovale_trinkets_mop")
local registerMopTrinkets = __ovale_trinkets_mop.registerMopTrinkets
__exports.registerScripts = function(ovaleScripts)
    registerCommon(ovaleScripts)
    registerDeathKnightSpells(ovaleScripts)
    registerDemonHunterSpells(ovaleScripts)
    registerDruidSpells(ovaleScripts)
    registerHunterSpells(ovaleScripts)
    registerMageSpells(ovaleScripts)
    registerMonkSpells(ovaleScripts)
    registerPaladinSpells(ovaleScripts)
    registerPriestSpells(ovaleScripts)
    registerRogueSpells(ovaleScripts)
    registerShamanSpells(ovaleScripts)
    registerWarlockSpells(ovaleScripts)
    registerWarriorSpells(ovaleScripts)
    registerMopTrinkets(ovaleScripts)
    registerWodTrinkets(ovaleScripts)
    registerDeathKnight(ovaleScripts)
    registerDemonHunter(ovaleScripts)
    registerDruid(ovaleScripts)
    registerHunter(ovaleScripts)
    registerMage(ovaleScripts)
    registerMonk(ovaleScripts)
    registerPaladin(ovaleScripts)
    registerPriest(ovaleScripts)
    registerRogue(ovaleScripts)
    registerShaman(ovaleScripts)
    registerWarlock(ovaleScripts)
    registerWarrior(ovaleScripts)
end
