local __exports = LibStub:NewLibrary("ovale/SpellBook", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
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
local __tools = LibStub:GetLibrary("ovale/tools")
local isNumber = __tools.isNumber
local MAX_NUM_TALENTS = NUM_TALENT_COLUMNS * MAX_TALENT_TIERS
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
__exports.OvaleSpellBookClass = __class(nil, {
    constructor = function(self, ovale, ovaleDebug, ovaleData)
        self.ovale = ovale
        self.ovaleData = ovaleData
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
        self.OnInitialize = function()
            self.module:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", self.Update)
            self.module:RegisterEvent("CHARACTER_POINTS_CHANGED", self.UpdateTalents)
            self.module:RegisterEvent("PLAYER_ENTERING_WORLD", self.Update)
            self.module:RegisterEvent("PLAYER_TALENT_UPDATE", self.UpdateTalents)
            self.module:RegisterEvent("SPELLS_CHANGED", self.UpdateSpells)
            self.module:RegisterEvent("UNIT_PET", self.UNIT_PET)
        end
        self.OnDisable = function()
            self.module:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
            self.module:UnregisterEvent("CHARACTER_POINTS_CHANGED")
            self.module:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self.module:UnregisterEvent("PLAYER_TALENT_UPDATE")
            self.module:UnregisterEvent("SPELLS_CHANGED")
            self.module:UnregisterEvent("UNIT_PET")
        end
        self.UNIT_PET = function(unitId)
            if unitId == "player" then
                self.UpdateSpells()
            end
        end
        self.Update = function()
            self.UpdateTalents()
            self.UpdateSpells()
            self.ready = true
        end
        self.UpdateTalents = function()
            self.tracer:Debug("Updating talents.")
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
                            self.tracer:Debug("    Talent %s (%d) is %s.", name, index, combinedSelected and "enabled" or "disabled")
                        end
                    end
                end
            end
            self.ovale:needRefresh()
            self.module:SendMessage("Ovale_TalentsChanged")
        end
        self.UpdateSpells = function()
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
            self.ovale:needRefresh()
            self.module:SendMessage("Ovale_SpellsChanged")
        end
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
                            return self:DebugSpells()
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
                            return self:DebugTalents()
                        end
                    }
                }
            }
        }
        for k, v in pairs(debugOptions) do
            ovaleDebug.defaultOptions.args[k] = v
        end
        self.module = ovale:createModule("OvaleSpellBook", self.OnInitialize, self.OnDisable, aceEvent)
        self.tracer = ovaleDebug:create(self.module:GetName())
    end,
    ScanSpellBook = function(self, bookType, numSpells, offset)
        offset = offset or 0
        self.tracer:Debug("Updating '%s' spellbook starting at offset %d.", bookType, offset)
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
                    self.tracer:Debug("    %s (%d) is at offset %d (%s).", name, id, index, gsub(spellLink, "|", "_"))
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
                        self.tracer:Debug("    %s (%d) is at offset %d.", name, spellId, index)
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
                            self.tracer:Debug("    %s (%d) is at offset %d.", name, id, index)
                            if id ~= overrideId then
                                local name = GetSpellInfo(overrideId)
                                self.spell[overrideId] = name
                                self.isHarmful[overrideId] = self.isHarmful[id]
                                self.isHelpful[overrideId] = self.isHelpful[id]
                                self.texture[overrideId] = self.texture[id]
                                self.spellbookId[bookType][overrideId] = nil
                                self.tracer:Debug("    %s (%d) is at offset %d.", name, overrideId, index)
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
            self.tracer:Debug("Adding spell %s (%d)", name, spellId)
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
    getKnownSpellId = function(self, spell)
        if isNumber(spell) then
            return spell
        end
        local spells = self.ovaleData.buffSpellList[spell]
        if  not spells then
            self.ovale:OneTimeMessage("Unknown spell list " .. spell)
            return nil
        end
        for spellId in pairs(spells) do
            if self.spell[spellId] then
                return spellId
            end
        end
        return nil
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
})
