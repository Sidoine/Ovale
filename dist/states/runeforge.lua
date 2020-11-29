local __exports = LibStub:NewLibrary("ovale/states/runeforge", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local ipairs = ipairs
local tonumber = tonumber
local unpack = unpack
local concat = table.concat
local insert = table.insert
local C_LegendaryCrafting = C_LegendaryCrafting
local __engineCondition = LibStub:GetLibrary("ovale/engine/Condition")
local ReturnBoolean = __engineCondition.ReturnBoolean
local __toolstools = LibStub:GetLibrary("ovale/tools/tools")
local isNumber = __toolstools.isNumber
local OneTimeMessage = __toolstools.OneTimeMessage
__exports.Runeforge = __class(nil, {
    constructor = function(self, debug)
        self.debugOptions = {
            type = "group",
            name = "Runeforges",
            args = {
                runeforge = {
                    type = "input",
                    name = "Runeforges",
                    multiline = 25,
                    width = "full",
                    get = function()
                        local ids = C_LegendaryCrafting.GetRuneforgePowers(nil)
                        local output = {}
                        for _, v in ipairs(ids) do
                            local runeforgePower = C_LegendaryCrafting.GetRuneforgePowerInfo(v)
                            if runeforgePower then
                                insert(output, v .. ": " .. runeforgePower.name)
                            end
                        end
                        return concat(output, "\n")
                    end
                }
            }
        }
        self.equippedRuneforge = function(positionalParameters)
            local powerId = unpack(positionalParameters)
            if  not isNumber(powerId) then
                OneTimeMessage(powerId .. " is not defined in EquippedRuneforge")
                return 
            end
            local runeforgePower = C_LegendaryCrafting.GetRuneforgePowerInfo(tonumber(powerId))
            return ReturnBoolean(runeforgePower.state == 0)
        end
        debug.defaultOptions.args["runeforge"] = self.debugOptions
    end,
    registerConditions = function(self, condition)
        condition:RegisterCondition("equippedruneforge", false, self.equippedRuneforge)
    end,
})
