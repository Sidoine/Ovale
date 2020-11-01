local __exports = LibStub:NewLibrary("ovale/states/covenant", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local C_Covenants = C_Covenants
local __Condition = LibStub:GetLibrary("ovale/Condition")
local ReturnBoolean = __Condition.ReturnBoolean
local ipairs = ipairs
local unpack = unpack
local concat = table.concat
local insert = table.insert
__exports.Covenant = __class(nil, {
    constructor = function(self, ovale, debug)
        self.debugOptions = {
            type = "group",
            name = "Covenants",
            args = {
                covenants = {
                    type = "input",
                    name = "Covenants",
                    multiline = 25,
                    width = "full",
                    get = function()
                        local ids = C_Covenants.GetCovenantIDs()
                        local output = {}
                        for _, v in ipairs(ids) do
                            local covenant = C_Covenants.GetCovenantData(v)
                            if covenant then
                                insert(output, covenant.name .. ": " .. covenant.ID)
                            end
                        end
                        return concat(output, "\n")
                    end
                }
            }
        }
        self.onInitialize = function()
            self.module:RegisterEvent("COVENANT_CHOSEN", self.onCovenantChosen)
            self.covenantId = C_Covenants.GetActiveCovenantID()
        end
        self.onDisable = function()
            self.module:UnregisterEvent("COVENANT_CHOSEN")
        end
        self.onCovenantChosen = function(_, covenantId)
            self.covenantId = covenantId
        end
        self.isCovenant = function(positionalParameters)
            local covenantId = unpack(positionalParameters)
            return ReturnBoolean(self.covenantId == covenantId)
        end
        self.module = ovale:createModule("Covenant", self.onInitialize, self.onDisable, aceEvent)
        debug.defaultOptions.args["covenant"] = self.debugOptions
    end,
    registerConditions = function(self, condition)
        condition:RegisterCondition("iscovenant", false, self.isCovenant)
    end,
})
