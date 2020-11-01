local __exports = LibStub:NewLibrary("ovale/states/runeforge", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local ipairs = ipairs
local unpack = unpack
local concat = table.concat
local insert = table.insert
local C_LegendaryCrafting = C_LegendaryCrafting
local __Condition = LibStub:GetLibrary("ovale/Condition")
local ReturnBoolean = __Condition.ReturnBoolean
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
        self.equipedRuneForge = function(positionalParameters)
            local powerId = unpack(positionalParameters)
            local runeforgePower = C_LegendaryCrafting.GetRuneforgePowerInfo(powerId)
            return ReturnBoolean(runeforgePower.state == undefined)
        end
        debug.defaultOptions.args["covenant"] = self.debugOptions
    end,
    registerConditions = function(self, condition)
        condition:RegisterCondition("equippedruneforge", false, self.equipedRuneForge)
    end,
})
