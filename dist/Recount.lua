local __exports = LibStub:NewLibrary("ovale/Recount", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Score = LibStub:GetLibrary("ovale/Score")
local OvaleScore = __Score.OvaleScore
local AceLocale = LibStub:GetLibrary("AceLocale-3.0", true)
local Recount = LibStub:GetLibrary("recount", true)
local setmetatable = setmetatable
local GameTooltip = GameTooltip
local OvaleRecountBase = Ovale.NewModule("OvaleRecount")
local DataModes = function(self, data, num)
    if  not data then
        return 0, 0
    end
    local fight = data.Fights[Recount.db.profile.CurDataSet]
    local score
    if fight and fight.Ovale and fight.OvaleMax then
        score = fight.Ovale * 1000 / fight.OvaleMax
    else
        score = 0
    end
    if num == 1 then
        return score
    end
    return score, nil
end

local TooltipFuncs = function(self, name)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(name)
end

local OvaleRecountClass = __class(OvaleRecountBase, {
    OnInitialize = function(self)
        if Recount then
            local aceLocale = AceLocale and AceLocale:GetLocale("Recount", true)
            if  not aceLocale then
                aceLocale = setmetatable({}, {
                    __index = function(t, k)
                        t[k] = k
                        return k
                    end

                })
            end
            Recount:AddModeTooltip(Ovale.GetName(), DataModes, TooltipFuncs, nil, nil, nil, nil)
            OvaleScore:RegisterDamageMeter("OvaleRecount", self, "ReceiveScore")
        end
    end,
    OnDisable = function(self)
        OvaleScore:UnregisterDamageMeter("OvaleRecount")
    end,
    ReceiveScore = function(self, name, guid, scored, scoreMax)
        if Recount then
            local source = Recount.db2.combatants[name]
            if source then
                Recount:AddAmount(source, Ovale.GetName(), scored)
                Recount:AddAmount(source, Ovale.GetName() .. "Max", scoreMax)
            end
        end
    end,
})
