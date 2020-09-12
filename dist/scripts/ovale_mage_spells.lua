local __exports = LibStub:NewLibrary("ovale/scripts/ovale_mage_spells", 80300)
if not __exports then return end
__exports.registerMageSpells = function(OvaleScripts)
    local name = "ovale_mage_spells"
    local desc = "[9.0] Ovale: Mage spells"
    local code = [[    ]]
    OvaleScripts:RegisterScript("MAGE", nil, name, desc, code, "include")
end
