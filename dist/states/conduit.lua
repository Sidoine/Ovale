local __exports = LibStub:NewLibrary("ovale/states/conduit", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local unpack = unpack
local C_Soulbinds = C_Soulbinds
local __enginecondition = LibStub:GetLibrary("ovale/engine/condition")
local ReturnBoolean = __enginecondition.ReturnBoolean
local ReturnConstant = __enginecondition.ReturnConstant
__exports.Conduit = __class(nil, {
    constructor = function(self, debug)
        self.debugOptions = {
            type = "group",
            name = "Conduits",
            args = {
                conduits = {
                    type = "input",
                    name = "Conduits",
                    multiline = 25,
                    width = "full",
                    get = function()
                        return ""
                    end
                }
            }
        }
        self.conduit = function(positionalParameters)
            local conduitId = unpack(positionalParameters)
            local soulbindID = C_Soulbinds.GetActiveSoulbindID()
            return ReturnBoolean(C_Soulbinds.IsConduitInstalledInSoulbind(soulbindID, conduitId))
        end
        self.conduitRank = function(positionalParameters)
            local conduitId = unpack(positionalParameters)
            local data = C_Soulbinds.GetConduitCollectionData(conduitId)
            if  not data then
                return 
            end
            return ReturnConstant(data.conduitRank)
        end
        self.enabledSoulbind = function(positionalParameters)
            local soulbindId = unpack(positionalParameters)
            return ReturnBoolean(C_Soulbinds.GetActiveSoulbindID() == soulbindId)
        end
        debug.defaultOptions.args["covenant"] = self.debugOptions
    end,
    registerConditions = function(self, condition)
        condition:RegisterCondition("conduit", false, self.conduit)
        condition:RegisterCondition("conduitrank", false, self.conduitRank)
        condition:RegisterCondition("enabledsoulbind", false, self.enabledSoulbind)
    end,
})
