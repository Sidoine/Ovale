local __exports = LibStub:NewLibrary("ovale/scripts/ovale_mage", 80300)
if not __exports then return end
__exports.registerMage = function(OvaleScripts)
    do
        local name = "sc_t25_mage_arcane"
        local desc = "[9.0] Simulationcraft: T25_Mage_Arcane"
        local code = [[
# Based on SimulationCraft profile "T25_Mage_Arcane".
#	class=mage
#	spec=arcane
#	talents=2032021

Include(ovale_common)
Include(ovale_mage_spells)
### Arcane icons.

AddCheckBox(opt_mage_arcane_aoe l(aoe) default specialization=arcane)
]]
        OvaleScripts:RegisterScript("MAGE", "arcane", name, desc, code, "script")
    end
    do
        local name = "sc_t25_mage_fire"
        local desc = "[9.0] Simulationcraft: T25_Mage_Fire"
        local code = [[
# Based on SimulationCraft profile "T25_Mage_Fire".
#	class=mage
#	spec=fire
#	talents=3031022

Include(ovale_common)
Include(ovale_mage_spells)
### Fire icons.

AddCheckBox(opt_mage_fire_aoe l(aoe) default specialization=fire)
]]
        OvaleScripts:RegisterScript("MAGE", "fire", name, desc, code, "script")
    end
    do
        local name = "sc_t25_mage_frost"
        local desc = "[9.0] Simulationcraft: T25_Mage_Frost"
        local code = [[
# Based on SimulationCraft profile "T25_Mage_Frost".
#	class=mage
#	spec=frost
#	talents=1011023

Include(ovale_common)
Include(ovale_mage_spells)
### Frost icons.

AddCheckBox(opt_mage_frost_aoe l(aoe) default specialization=frost)
]]
        OvaleScripts:RegisterScript("MAGE", "frost", name, desc, code, "script")
    end
end
