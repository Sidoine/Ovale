local __exports = LibStub:NewLibrary("ovale/scripts/ovale_common", 80300)
if not __exports then return end
__exports.registerCommon = function(OvaleScripts)
    local name = "ovale_common"
    local desc = "[9.0] Ovale: Common spell definitions"
    local code = [[

# Essences
Define(concentrated_flame_burn_debuff 295368)
SpellInfo(concentrated_flame_burn_debuff duration=6)

# Covenants
Define(kyrian 1)
Define(venthyr 2)
Define(night_fae 3)
Define(necrolord 4)

]]
    OvaleScripts:RegisterScript(nil, nil, name, desc, code, "include")
end
