local __exports = LibStub:NewLibrary("ovale/SpellBook", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local wipe = wipe
local match = string.match
local gsub = string.gsub
local concat = table.concat
local insert = table.insert
local sort = table.sort
local GetActiveSpecGroup = GetActiveSpecGroup
local GetFlyoutInfo = GetFlyoutInfo
local GetFlyoutSlotInfo = GetFlyoutSlotInfo
local GetSpellBookItemInfo = GetSpellBookItemInfo
local GetSpellInfo = GetSpellInfo
local GetSpellLink = GetSpellLink
local GetSpellTabInfo = GetSpellTabInfo
local GetSpellTexture = GetSpellTexture
local GetTalentInfo = GetTalentInfo
local HasPetSpells = HasPetSpells
local IsHarmfulSpell = IsHarmfulSpell
local IsHelpfulSpell = IsHelpfulSpell
local BOOKTYPE_PET = BOOKTYPE_PET
local BOOKTYPE_SPELL = BOOKTYPE_SPELL
local MAX_TALENT_TIERS = MAX_TALENT_TIERS
local NUM_TALENT_COLUMNS = NUM_TALENT_COLUMNS
local MAX_NUM_TALENTS = NUM_TALENT_COLUMNS * MAX_TALENT_TIERS
do
    local debugOptions = {
        spellbook = {
            name = L["Spellbook"],
            type = "group",
            args = {
                spellbook = {
                    name = L["Spellbook"],
                    type = "input",
                    multiline = 25,
                    width = "full",
                    get = function(info)
                        return __exports.OvaleSpellBook:DebugSpells()
                    end

                }
            }
        },
        talent = {
            name = L["Talents"],
            type = "group",
            args = {
                talent = {
                    name = L["Talents"],
                    type = "input",
                    multiline = 25,
                    width = "full",
                    get = function(info)
                        return __exports.OvaleSpellBook:DebugTalents()
                    end

                }
            }
        }
    }
    for k, v in pairs(debugOptions) do
        OvaleDebug.options.args[k] = v
    end
end
local ParseHyperlink = function(hyperlink)
    local color, linkType, linkData, text = match(hyperlink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d*):?%d?|?h?%[?([^%[%]]*)%]?|?h?|?r?")
    return color, linkType, linkData, text
end

local OutputTableValues = function(output, tbl)
    local array = {}
    for k, v in pairs(tbl) do
        insert(array, tostring(v) .. ": " .. tostring(k))
    end
    sort(array)
    for _, v in ipairs(array) do
        output[#output + 1] = v
    end
end

local output = {}
local OvaleSpellBookBase = OvaleProfiler:RegisterProfiling(OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleSpellBook", aceEvent)))
local OvaleSpellBookClass = __class(OvaleSpellBookBase, {
    OnInitialize = function(self)
        self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "Update")
        self:RegisterEvent("CHARACTER_POINTS_CHANGED", "UpdateTalents")
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
        self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateTalents")
        self:RegisterEvent("SPELLS_CHANGED", "UpdateSpells")
        self:RegisterEvent("UNIT_PET")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
        self:UnregisterEvent("CHARACTER_POINTS_CHANGED")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("PLAYER_TALENT_UPDATE")
        self:UnregisterEvent("SPELLS_CHANGED")
        self:UnregisterEvent("UNIT_PET")
    end,
    UNIT_PET = function(self, unitId)
        if unitId == "player" then
            self:UpdateSpells()
        end
    end,
    Update = function(self)
        self:UpdateTalents()
        self:UpdateSpells()
        self.ready = true
    end,
    UpdateTalents = function(self)
        self:Debug("Updating talents.")
        wipe(self.talent)
        wipe(self.talentPoints)
        local activeTalentGroup = GetActiveSpecGroup()
        for i = 1, MAX_TALENT_TIERS, 1 do
            for j = 1, NUM_TALENT_COLUMNS, 1 do
                local talentId, name, _, selected, _, _, _, _, _, _, selectedByLegendary = GetTalentInfo(i, j, activeTalentGroup)
                if talentId then
                    local combinedSelected = selected or selectedByLegendary
                    local index = 3 * (i - 1) + j
                    if index <= MAX_NUM_TALENTS then
                        self.talent[index] = name
                        if combinedSelected then
                            self.talentPoints[index] = 1
                        else
                            self.talentPoints[index] = 0
                        end
                        self:Debug("    Talent %s (%d) is %s.", name, index, combinedSelected and "enabled" or "disabled")
                    end
                end
            end
        end
        Ovale:needRefresh()
        self:SendMessage("Ovale_TalentsChanged")
    end,
    UpdateSpells = function(self)
        wipe(self.spell)
        wipe(self.spellbookId[BOOKTYPE_PET])
        wipe(self.spellbookId[BOOKTYPE_SPELL])
        wipe(self.isHarmful)
        wipe(self.isHelpful)
        wipe(self.texture)
        for tab = 1, 2, 1 do
            local name, _, offset, numSpells = GetSpellTabInfo(tab)
            if name then
                self:ScanSpellBook(BOOKTYPE_SPELL, numSpells, offset)
            end
        end
        local numPetSpells = HasPetSpells()
        if numPetSpells then
            self:ScanSpellBook(BOOKTYPE_PET, numPetSpells)
        end
        Ovale:needRefresh()
        self:SendMessage("Ovale_SpellsChanged")
    end,
    ScanSpellBook = function(self, bookType, numSpells, offset)
        offset = offset or 0
        self:Debug("Updating '%s' spellbook starting at offset %d.", bookType, offset)
        for index = offset + 1, offset + numSpells, 1 do
            local skillType, spellId = GetSpellBookItemInfo(index, bookType)
            if skillType == "SPELL" or skillType == "PETACTION" then
                local spellLink = GetSpellLink(index, bookType)
                if spellLink then
                    local _, _, linkData, spellName = ParseHyperlink(spellLink)
                    local id = tonumber(linkData)
                    local name = GetSpellInfo(id)
                    self.spell[id] = name
                    self.isHarmful[id] = IsHarmfulSpell(index, bookType)
                    self.isHelpful[id] = IsHelpfulSpell(index, bookType)
                    self.texture[id] = GetSpellTexture(index, bookType)
                    self.spellbookId[bookType][id] = index
                    self:Debug("    %s (%d) is at offset %d (%s).", name, id, index, gsub(spellLink, "|", "_"))
                    if spellId and id ~= spellId then
                        local name
                        if skillType == "PETACTION" and spellName then
                            name = spellName
                        else
                            name = GetSpellInfo(spellId)
                        end
                        self.spell[spellId] = name
                        self.isHarmful[spellId] = self.isHarmful[id]
                        self.isHelpful[spellId] = self.isHelpful[id]
                        self.texture[spellId] = self.texture[id]
                        self.spellbookId[bookType][spellId] = index
                        self:Debug("    %s (%d) is at offset %d.", name, spellId, index)
                    end
                end
            elseif skillType == "FLYOUT" then
                local flyoutId = spellId
                local _, _, numSlots, isKnown = GetFlyoutInfo(flyoutId)
                if numSlots > 0 and isKnown then
                    for flyoutIndex = 1, numSlots, 1 do
                        local id, overrideId, isKnown, spellName = GetFlyoutSlotInfo(flyoutId, flyoutIndex)
                        if isKnown then
                            local name = GetSpellInfo(id)
                            self.spell[id] = name
                            self.isHarmful[id] = IsHarmfulSpell(spellName)
                            self.isHelpful[id] = IsHelpfulSpell(spellName)
                            self.texture[id] = GetSpellTexture(index, bookType)
                            self.spellbookId[bookType][id] = nil
                            self:Debug("    %s (%d) is at offset %d.", name, id, index)
                            if id ~= overrideId then
                                local name = GetSpellInfo(overrideId)
                                self.spell[overrideId] = name
                                self.isHarmful[overrideId] = self.isHarmful[id]
                                self.isHelpful[overrideId] = self.isHelpful[id]
                                self.texture[overrideId] = self.texture[id]
                                self.spellbookId[bookType][overrideId] = nil
                                self:Debug("    %s (%d) is at offset %d.", name, overrideId, index)
                            end
                        end
                    end
                end
            elseif skillType == "FUTURESPELL" then
            elseif  not skillType then
                break
            end
        end
    end,
    GetCastTime = function(self, spellId)
        if spellId then
            local name, _, _, castTime = self:GetSpellInfo(spellId)
            if name then
                if castTime then
                    castTime = castTime / 1000
                else
                    castTime = 0
                end
            else
                castTime = nil
            end
            return castTime
        end
    end,
    GetSpellInfo = function(self, spellId)
        local index, bookType = self:GetSpellBookIndex(spellId)
        if index and bookType then
            return GetSpellInfo(index, bookType)
        else
            return GetSpellInfo(spellId)
        end
    end,
    GetSpellName = function(self, spellId)
        if spellId then
            local spellName = self.spell[spellId]
            if  not spellName then
                spellName = self:GetSpellInfo(spellId)
            end
            return spellName
        end
    end,
    GetSpellTexture = function(self, spellId)
        return self.texture[spellId]
    end,
    GetTalentPoints = function(self, talentId)
        local points = 0
        if talentId and self.talentPoints[talentId] then
            points = self.talentPoints[talentId]
        end
        return points
    end,
    AddSpell = function(self, spellId, name)
        if spellId and name then
            self:Debug("Adding spell %s (%d)", name, spellId)
            self.spell[spellId] = name
        end
    end,
    IsHarmfulSpell = function(self, spellId)
        return (spellId and self.isHarmful[spellId]) and true or false
    end,
    IsHelpfulSpell = function(self, spellId)
        return (spellId and self.isHelpful[spellId]) and true or false
    end,
    IsKnownSpell = function(self, spellId)
        return (spellId and self.spell[spellId]) and true or false
    end,
    IsKnownTalent = function(self, talentId)
        return (talentId and self.talentPoints[talentId]) and true or false
    end,
    GetSpellBookIndex = function(self, spellId)
        local bookType = BOOKTYPE_SPELL
        while true do
            local index = self.spellbookId[bookType][spellId]
            if index then
                return index, bookType
            elseif bookType == BOOKTYPE_SPELL then
                bookType = BOOKTYPE_PET
            else
                break
            end
        end
        return nil, nil
    end,
    IsPetSpell = function(self, spellId)
        local _, bookType = self:GetSpellBookIndex(spellId)
        return bookType == BOOKTYPE_PET
    end,
    DebugSpells = function(self)
        wipe(output)
        OutputTableValues(output, self.spell)
        local total = 0
        for _ in pairs(self.spell) do
            total = total + 1
        end
        output[#output + 1] = "Total spells: " .. total
        return concat(output, "\n")
    end,
    DebugTalents = function(self)
        wipe(output)
        OutputTableValues(output, self.talent)
        return concat(output, "\n")
    end,
    constructor = function(self, ...)
        OvaleSpellBookBase.constructor(self, ...)
        self.ready = false
        self.spell = {}
        self.spellbookId = {
            [BOOKTYPE_PET] = {},
            [BOOKTYPE_SPELL] = {}
        }
        self.isHarmful = {}
        self.isHelpful = {}
        self.texture = {}
        self.talent = {}
        self.talentPoints = {}
    end
})
__exports.OvaleSpellBook = OvaleSpellBookClass()
