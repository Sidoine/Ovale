local __exports = LibStub:NewLibrary("ovale/custom/index", 80201)
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
local registerDeathKnightBloodXeltor = __ovale_deathknight.registerDeathKnightBloodXeltor
local registerDeathKnightFrostXeltor = __ovale_deathknight.registerDeathKnightFrostXeltor
local registerDeathKnightUnholyXeltor = __ovale_deathknight.registerDeathKnightUnholyXeltor
local registerDemonHunterHavocXeltor = __ovale_demonhunter.registerDemonHunterHavocXeltor
local registerDemonHunterVengeanceXeltor = __ovale_demonhunter.registerDemonHunterVengeanceXeltor
local registerDruidCommonXeltor = __ovale_druid.registerDruidCommonXeltor
local registerDruidBalanceXeltor = __ovale_druid.registerDruidBalanceXeltor
local registerDruidFeralXeltor = __ovale_druid.registerDruidFeralXeltor
local registerDruidGuardianXeltor = __ovale_druid.registerDruidGuardianXeltor
local registerDruidRestorationXeltor = __ovale_druid.registerDruidRestorationXeltor
local registerHunterBeastMasteryXeltor = __ovale_hunter.registerHunterBeastMasteryXeltor
local registerHunterMarksmanshipXeltor = __ovale_hunter.registerHunterMarksmanshipXeltor
local registerHunterSurvivalXeltor = __ovale_hunter.registerHunterSurvivalXeltor
local registerMageFireXeltor = __ovale_mage.registerMageFireXeltor
local registerMageFrostXeltor = __ovale_mage.registerMageFrostXeltor
local registerMageArcaneXeltor = __ovale_mage.registerMageArcaneXeltor
local registerMonkBrewmasterXeltor = __ovale_monk.registerMonkBrewmasterXeltor
local registerMonkMistweaverXeltor = __ovale_monk.registerMonkMistweaverXeltor
local registerMonkWindwalkerXeltor = __ovale_monk.registerMonkWindwalkerXeltor
local registerPaladinProtectionXeltor = __ovale_paladin.registerPaladinProtectionXeltor
local registerPaladinRetributionXeltor = __ovale_paladin.registerPaladinRetributionXeltor
local registerPriestDisciplineXeltor = __ovale_priest.registerPriestDisciplineXeltor
local registerPriestShadowXeltor = __ovale_priest.registerPriestShadowXeltor
local registerRogueAssassinationXeltor = __ovale_rogue.registerRogueAssassinationXeltor
local registerRogueOutlawXeltor = __ovale_rogue.registerRogueOutlawXeltor
local registerRogueSubtletyXeltor = __ovale_rogue.registerRogueSubtletyXeltor
local registerShamanElementalXeltor = __ovale_shaman.registerShamanElementalXeltor
local registerShamanEnhancementXeltor = __ovale_shaman.registerShamanEnhancementXeltor
local registerShamanRestorationXeltor = __ovale_shaman.registerShamanRestorationXeltor
local registerWarlockAfflictionXeltor = __ovale_warlock.registerWarlockAfflictionXeltor
local registerWarlockDemonologyXeltor = __ovale_warlock.registerWarlockDemonologyXeltor
local registerWarlockDestructionXeltor = __ovale_warlock.registerWarlockDestructionXeltor
local registerWarriorArmsXeltor = __ovale_warrior.registerWarriorArmsXeltor
local registerWarriorFuryXeltor = __ovale_warrior.registerWarriorFuryXeltor
local registerWarriorProtectionXeltor = __ovale_warrior.registerWarriorProtectionXeltor
-- Helpers
-- local registerDeathKnightBloodHelper = __ovale_deathknight.registerDeathKnightBloodHelper
-- local registerDeathKnightFrostHelper = __ovale_deathknight.registerDeathKnightFrostHelper
-- local registerDeathKnightUnholyHelper = __ovale_deathknight.registerDeathKnightUnholyHelper
-- local registerDemonHunterHavocHelper = __ovale_demonhunter.registerDemonHunterHavocHelper
-- local registerDemonHunterVengeanceHelper = __ovale_demonhunter.registerDemonHunterVengeanceHelper
-- local registerDruidCommonHelper = __ovale_druid.registerDruidCommonHelper
-- local registerDruidBalanceHelper = __ovale_druid.registerDruidBalanceHelper
-- local registerDruidFeralHelper = __ovale_druid.registerDruidFeralHelper
-- local registerDruidGuardianHelper = __ovale_druid.registerDruidGuardianHelper
-- local registerDruidRestorationHelper = __ovale_druid.registerDruidRestorationHelper
-- local registerHunterBeastMasteryHelper = __ovale_hunter.registerHunterBeastMasteryHelper
-- local registerHunterMarksmanshipHelper = __ovale_hunter.registerHunterMarksmanshipHelper
-- local registerHunterSurvivalHelper = __ovale_hunter.registerHunterSurvivalHelper
-- local registerMageFireHelper = __ovale_mage.registerMageFireHelper
-- local registerMageFrostHelper = __ovale_mage.registerMageFrostHelper
-- local registerMageArcaneHelper = __ovale_mage.registerMageArcaneHelper
-- local registerMonkBrewmasterHelper = __ovale_monk.registerMonkBrewmasterHelper
-- local registerMonkMistweaverHelper = __ovale_monk.registerMonkMistweaverHelper
-- local registerMonkWindwalkerHelper = __ovale_monk.registerMonkWindwalkerHelper
-- local registerPaladinProtectionHelper = __ovale_paladin.registerPaladinProtectionHelper
-- local registerPaladinRetributionHelper = __ovale_paladin.registerPaladinRetributionHelper
-- local registerPriestDisciplineHelper = __ovale_priest.registerPriestDisciplineHelper
-- local registerPriestShadowHelper = __ovale_priest.registerPriestShadowHelper
-- local registerRogueAssassinationHelper = __ovale_rogue.registerRogueAssassinationHelper
-- local registerRogueOutlawHelper = __ovale_rogue.registerRogueOutlawHelper
-- local registerRogueSubtletyHelper = __ovale_rogue.registerRogueSubtletyHelper
-- local registerShamanElementalHelper = __ovale_shaman.registerShamanElementalHelper
-- local registerShamanEnhancementHelper = __ovale_shaman.registerShamanEnhancementHelper
-- local registerShamanRestorationHelper = __ovale_shaman.registerShamanRestorationHelper
-- local registerWarlockAfflictionHelper = __ovale_warlock.registerWarlockAfflictionHelper
-- local registerWarlockDemonologyHelper = __ovale_warlock.registerWarlockDemonologyHelper
-- local registerWarlockDestructionHelper = __ovale_warlock.registerWarlockDestructionHelper
-- local registerWarriorArmsHelper = __ovale_warrior.registerWarriorArmsHelper
-- local registerWarriorFuryHelper = __ovale_warrior.registerWarriorFuryHelper
-- local registerWarriorProtectionHelper = __ovale_warrior.registerWarriorProtectionHelper
__exports.registerScripts = function(ovaleScripts)
	registerDeathKnightBloodXeltor(ovaleScripts)
	registerDeathKnightFrostXeltor(ovaleScripts)
	registerDeathKnightUnholyXeltor(ovaleScripts)
	registerDemonHunterHavocXeltor(ovaleScripts)
	registerDemonHunterVengeanceXeltor(ovaleScripts)
	registerDruidCommonXeltor(ovaleScripts)
	registerDruidBalanceXeltor(ovaleScripts)
	registerDruidFeralXeltor(ovaleScripts)
	registerDruidGuardianXeltor(ovaleScripts)
	registerDruidRestorationXeltor(ovaleScripts)
	registerHunterBeastMasteryXeltor(ovaleScripts)
	registerHunterMarksmanshipXeltor(ovaleScripts)
	registerHunterSurvivalXeltor(ovaleScripts)
	registerMageFireXeltor(ovaleScripts)
	registerMageFrostXeltor(ovaleScripts)
	registerMageArcaneXeltor(ovaleScripts)
	registerMonkBrewmasterXeltor(ovaleScripts)
	registerMonkMistweaverXeltor(ovaleScripts)
	registerMonkWindwalkerXeltor(ovaleScripts)
	registerPaladinProtectionXeltor(ovaleScripts)
	registerPaladinRetributionXeltor(ovaleScripts)
	registerPriestDisciplineXeltor(ovaleScripts)
	registerPriestShadowXeltor(ovaleScripts)
	registerRogueAssassinationXeltor(ovaleScripts)
	registerRogueOutlawXeltor(ovaleScripts)
	registerRogueSubtletyXeltor(ovaleScripts)
	registerShamanElementalXeltor(ovaleScripts)
	registerShamanEnhancementXeltor(ovaleScripts)
	registerShamanRestorationXeltor(ovaleScripts)
	registerWarlockAfflictionXeltor(ovaleScripts)
	registerWarlockDemonologyXeltor(ovaleScripts)
	registerWarlockDestructionXeltor(ovaleScripts)
	registerWarriorArmsXeltor(ovaleScripts)
	registerWarriorFuryXeltor(ovaleScripts)
	registerWarriorProtectionXeltor(ovaleScripts)
end
-- __exports.registerScripts = function(ovaleScripts)
	-- -- Helpers
	-- registerDeathKnightBloodHelper(ovaleScripts)
	-- registerDeathKnightFrostHelper(ovaleScripts)
	-- registerDeathKnightUnholyHelper(ovaleScripts)
	-- registerDemonHunterHavocHelper(ovaleScripts)
	-- registerDemonHunterVengeanceHelper(ovaleScripts)
	-- registerDruidCommonHelper(ovaleScripts)
	-- registerDruidBalanceHelper(ovaleScripts)
	-- registerDruidFeralHelper(ovaleScripts)
	-- registerDruidGuardianHelper(ovaleScripts)
	-- registerDruidRestorationHelper(ovaleScripts)
	-- registerHunterBeastMasteryHelper(ovaleScripts)
	-- registerHunterMarksmanshipHelper(ovaleScripts)
	-- registerHunterSurvivalHelper(ovaleScripts)
	-- registerMageFireHelper(ovaleScripts)
	-- registerMageFrostHelper(ovaleScripts)
	-- registerMageArcaneHelper(ovaleScripts)
	-- registerMonkBrewmasterHelper(ovaleScripts)
	-- registerMonkMistweaverHelper(ovaleScripts)
	-- registerMonkWindwalkerHelper(ovaleScripts)
	-- registerPaladinProtectionHelper(ovaleScripts)
	-- registerPaladinRetributionHelper(ovaleScripts)
	-- registerPriestDisciplineHelper(ovaleScripts)
	-- registerPriestShadowHelper(ovaleScripts)
	-- registerRogueAssassinationHelper(ovaleScripts)
	-- registerRogueOutlawHelper(ovaleScripts)
	-- registerRogueSubtletyHelper(ovaleScripts)
	-- registerShamanElementalHelper(ovaleScripts)
	-- registerShamanEnhancementHelper(ovaleScripts)
	-- registerShamanRestorationHelper(ovaleScripts)
	-- registerWarlockAfflictionHelper(ovaleScripts)
	-- registerWarlockDemonologyHelper(ovaleScripts)
	-- registerWarlockDestructionHelper(ovaleScripts)
	-- registerWarriorArmsHelper(ovaleScripts)
	-- registerWarriorFuryHelper(ovaleScripts)
	-- registerWarriorProtectionHelper(ovaleScripts)
-- end
