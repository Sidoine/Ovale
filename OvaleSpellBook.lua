--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- This addon tracks the player's active spells, talents, and glyphs.

local _, Ovale = ...
local OvaleSpellBook = Ovale:NewModule("OvaleSpellBook", "AceEvent-3.0")
Ovale.OvaleSpellBook = OvaleSpellBook

--<private-static-properties>
local ipairs = ipairs
local pairs = pairs
local strfind = string.find
local tinsert = table.insert
local tonumber = tonumber
local tostring = tostring
local tsort = table.sort
local wipe = table.wipe
local API_GetNumGlyphSockets = GetNumGlyphSockets
local API_GetGlyphSocketInfo = GetGlyphSocketInfo
local API_GetSpellBookItemInfo = GetSpellBookItemInfo
local API_GetSpellInfo = GetSpellInfo
local API_GetSpellLink = GetSpellLink
local API_GetSpellTabInfo = GetSpellTabInfo
local API_GetTalentInfo = GetTalentInfo
local API_HasPetSpells = HasPetSpells
local BOOKTYPE_PET = BOOKTYPE_PET
local BOOKTYPE_SPELL = BOOKTYPE_SPELL

-- spell[spellId] = spellName
self_spell = {}
-- talent[talentId] = talentName
self_talent = {}
-- talentPoints[talentId] = 0 or 1
self_talentPoints = {}
-- glyph[glyphSpellId] = glyphName
self_glyph = {}
--</private-static-properties>

--<private-static-methods>
-- Return the four components of a hyperlink: color, linktype, linkdata, text.
local function ParseHyperlink(hyperlink)
	return select(3, strfind(hyperlink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+)|?h?%[?([^%[%]]*)%]?|?h?|?r?"))
end

local function PrintTableValues(tbl)
	local array = {}
	for k, v in pairs(tbl) do
		tinsert(array, tostring(v) .. ": " .. tostring(k))
	end
	tsort(array)
	for _, v in ipairs(array) do
		Ovale:Print(v)
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleSpellBook:OnEnable()
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "Update")
	self:RegisterEvent("CHARACTER_POINTS_CHANGED", "UpdateTalents")
	self:RegisterEvent("GLYPH_ADDED", "UpdateGlyphs")
	self:RegisterEvent("GLYPH_DISABLED", "UpdateGlyphs")
	self:RegisterEvent("GLYPH_ENABLED", "UpdateGlyphs")
	self:RegisterEvent("GLYPH_REMOVED", "UpdateGlyphs")
	self:RegisterEvent("GLYPH_UPDATED", "UpdateGlyphs")
	self:RegisterEvent("PLAYER_ALIVE", "Update")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateTalents")
	self:RegisterEvent("SPELLS_CHANGED", "UpdateSpells")
	self:RegisterEvent("UNIT_PET")
end

function OvaleSpellBook:OnDisable()
	self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:UnregisterEvent("CHARACTER_POINTS_CHANGED")
	self:UnregisterEvent("GLYPH_ADDED")
	self:UnregisterEvent("GLYPH_DISABLED")
	self:UnregisterEvent("GLYPH_ENABLED")
	self:UnregisterEvent("GLYPH_REMOVED")
	self:UnregisterEvent("GLYPH_UPDATED")
	self:UnregisterEvent("PLAYER_ALIVE")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_TALENT_UPDATE")
	self:UnregisterEvent("SPELLS_CHANGED")
	self:UnregisterEvent("UNIT_PET")
end

-- Update spells if the player's pet is summoned or dismissed.
function OvaleSpellBook:UNIT_PET(unitId)
	if unitId == "player" then
		UpdateSpells()
	end
end

function OvaleSpellBook:Update()
	self:UpdateTalents()
	self:UpdateGlyphs()
	self:UpdateSpells()
end

-- Update the player's talents by scanning the talent tab for the active specialization.
-- Store the number of points assigned to each talent.
function OvaleSpellBook:UpdateTalents()
	wipe(self_talent)
	wipe(self_talentPoints)

	local i = 1
	while true do
		local name, _, _, _, selected, _ = API_GetTalentInfo(i)
		if not name then break end
		self_talent[i] = name
		if selected then
			self_talentPoints[i] = 1
		else
			self_talentPoints[i] = 0
		end
		i = i + 1
	end
	self:SendMessage("Ovale_TalentsChanged")
end

-- Update the player's glyphs by scanning the glyph socket tab for the active specialization.
function OvaleSpellBook:UpdateGlyphs()
	wipe(self_glyph)

	for i = 1, API_GetNumGlyphSockets() do
		local enabled, _, _, glyphSpell, _ = API_GetGlyphSocketInfo(i)
		if enabled and glyphSpell then
			self_glyph[glyphSpell] = API_GetSpellInfo(glyphSpell)
		end
	end
	self:SendMessage("Ovale_GlyphsChanged")
end

-- Update the player's spells by scanning the first two tabs of the spellbook.
function OvaleSpellBook:UpdateSpells()
	wipe(self_spell)

	local name, _, offset, numSpells = API_GetSpellTabInfo(2)
	if name then
		for i = 1, offset + numSpells do
			local skillType, spellId = API_GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
			if spellId and skillType ~= "FUTURESPELL" and skillType ~= "FLYOUT" then
				-- Use GetSpellLink() in case this spellbook item was replaced by another spell,
				-- i.e., through talents or Symbiosis.
				local spellLink = API_GetSpellLink(i, BOOKTYPE_SPELL)
				if spellLink then
					local linkdata, spellName = select(3, ParseHyperlink(spellLink))
					self_spell[tonumber(linkdata)] = spellName
					self_spell[spellId] = spellName
				end
			end
		end
	end
	self:UpdatePetSpells()
	self:SendMessage("Ovale_SpellsChanged")
end

-- Update the player's pet spells by scanning the pet spellbook.
function OvaleSpellBook:UpdatePetSpells()
	local hasPetSpells = API_HasPetSpells()
	if hasPetSpells then
		local i = 1
		while true do
			local skillType, spellId = API_GetSpellBookItemInfo(i, BOOKTYPE_PET)
			if not spellId then break end
			if skillType ~= "FUTURESPELL" and skillType ~= "FLYOUT" then
				-- Use GetSpellLink() in case this spellbook item was replaced by another spell.
				local spellLink = API_GetSpellLink(i, BOOKTYPE_PET)
				if spellLink then
					local linkdata, spellName = select(3, ParseHyperlink(spellLink))
					self_spell[tonumber(linkdata)] = spellName
					self_spell[spellId] = spellName
				end
			end
			i = i + 1
		end
	end
end

function OvaleSpellBook:GetSpellName(spellId)
	if spellId then
		local name = self_spell[spellId]
		if not name then
			name = API_GetSpellInfo(spellId)
		end
		return name
	end
end

function OvaleSpellBook:GetTalentPoints(talentId)
	local points = 0
	if talentId and self_talentPoints[talentId] then
		points = self_talentPoints[talentId]
	end
	return points
end

function OvaleSpellBook:AddSpell(spellId, name)
	if spellId and name then
		self_spell[spellId] = name
	end
end

-- Returns true if the given glyph spell Id is an active glyph in the player's glyph tab.
function OvaleSpellBook:IsActiveGlyph(glyphId)
	if glyphId and self_glyph[glyphId] then
		return true
	else
		return false
	end
end

-- Returns true if the given spellId is found in the player's list of known spells.
function OvaleSpellBook:IsKnownSpell(spellId)
	if spellId and self_spell[spellId] then
		return true
	else
		return false
	end
end

-- Returns true if the given talentId is found in the player's talent tree.
function OvaleSpellBook:IsKnownTalent(talentId)
	if talentId and self_talentPoints[talentId] then
		return true
	else
		return false
	end
end

-- Print out the list of active glyphs in alphabetical order.
function OvaleSpellBook:DebugGlyphs()
	PrintTableValues(self_glyph)
end

-- Print out the list of known spells in alphabetical order.
function OvaleSpellBook:DebugSpells()
	PrintTableValues(self_spell)
end

-- Print out the list of talents in alphabetical order.
function OvaleSpellBook:DebugTalents()
	PrintTableValues(self_talent)
end
--</public-static-methods>