local __exports = LibStub:NewLibrary("ovale/scripts/ovale_common", 80300)
if not __exports then return end
__exports.registerCommon = function(OvaleScripts)
    local name = "ovale_common"
    local desc = "[9.0] Ovale: Common spell definitions"
    local code = [[

]]
    OvaleScripts:RegisterScript(nil, nil, name, desc, code, "include")
end
