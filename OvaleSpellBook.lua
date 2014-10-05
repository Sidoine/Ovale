--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- This addon tracks the player's active spells, talents, and glyphs.

local _, Ovale = ...
local OvaleSpellBook = Ovale:NewModule("OvaleSpellBook", "AceEvent-3.0")
Ovale.OvaleSpellBook = OvaleSpellBook

--<private-static-properties>
local ipairs = ipairs
local pairs = pairs
local strmatch = string.match
local tinsert = table.insert
local tonumber = tonumber
local tostring = tostring
local tsort = table.sort
local wipe = table.wipe
local API_GetFlyoutInfo = GetFlyoutInfo
local API_GetFlyoutSlotInfo = GetFlyoutSlotInfo
local API_GetGlyphSocketInfo = GetGlyphSocketInfo
local API_GetNumGlyphSockets = GetNumGlyphSockets
local API_GetSpellBookItemInfo = GetSpellBookItemInfo
local API_GetSpellInfo = GetSpellInfo
local API_GetSpellLink = GetSpellLink
local API_GetSpellTabInfo = GetSpellTabInfo
local API_GetTalentInfo = GetTalentInfo
local API_HasPetSpells = HasPetSpells
local API_IsSpellOverlayed = IsSpellOverlayed
local API_IsUsableSpell = IsUsableSpell
local BOOKTYPE_PET = BOOKTYPE_PET
local BOOKTYPE_SPELL = BOOKTYPE_SPELL
--</private-static-properties>

--<public-static-properties>
-- Whether the spellbook information is ready for use by other modules.
OvaleSpellBook.ready = false
-- self.spell[spellId] = spellName
OvaleSpellBook.spell = {}
-- self.talent[talentId] = talentName
OvaleSpellBook.talent = {}
-- self.talentPoints[talentId] = 0 or 1
OvaleSpellBook.talentPoints = {}
-- self.glyph[glyphSpellId] = glyphName
OvaleSpellBook.glyph = {}
--</public-static-properties>

--<private-static-methods>
local function ParseHyperlink(hyperlink)
	local color, linkType, linkData, text = strmatch(hyperlink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
	return color, linkType, linkData, text
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
		self:UpdateSpells()
	end
end

function OvaleSpellBook:Update()
	self:UpdateTalents()
	self:UpdateGlyphs()
	self:UpdateSpells()
	self.ready = true
end

-- Update the player's talents by scanning the talent tab for the active specialization.
-- Store the number of points assigned to each talent.
function OvaleSpellBook:UpdateTalents()
	wipe(self.talent)
	wipe(self.talentPoints)

	local i = 1
	while true do
		local name, _, _, _, selected, _ = API_GetTalentInfo(i)
		if not name then break end
		self.talent[i] = name
		if selected then
			self.talentPoints[i] = 1
		else
			self.talentPoints[i] = 0
		end
		i = i + 1
	end
	self:SendMessage("Ovale_TalentsChanged")
end

-- Update the player's glyphs by scanning the glyph socket tab for the active specialization.
function OvaleSpellBook:UpdateGlyphs()
	wipe(self.glyph)

	for i = 1, API_GetNumGlyphSockets() do
		local enabled, _, _, glyphSpell, _ = API_GetGlyphSocketInfo(i)
		if enabled and glyphSpell then
			self.glyph[glyphSpell] = API_GetSpellInfo(glyphSpell)
		end
	end
	self:SendMessage("Ovale_GlyphsChanged")
end

function OvaleSpellBook:UpdateSpells()
	wipe(self.spell)

	-- Scan the first two tabs of the player's spellbook.
	for tab = 1, 2 do
		local name, _, offset, numSpells = API_GetSpellTabInfo(tab)
		if name then
			self:ScanSpellBook(BOOKTYPE_SPELL, numSpells, offset)
		end
	end

	-- Scan the pet's spellbook.
	local numPetSpells, petToken = API_HasPetSpells()
	if numPetSpells then
		self:ScanSpellBook(BOOKTYPE_PET, numPetSpells)
	end

	self:SendMessage("Ovale_SpellsChanged")
end

-- Scan a spellbook and populate self.spell table.
function OvaleSpellBook:ScanSpellBook(bookType, numSpells, offset)
	offset = offset or 0
	for index = offset + 1, offset + numSpells do
		local skillType, spellId = API_GetSpellBookItemInfo(index, bookType)
		if skillType == "SPELL" or skillType == "PETACTION" then
			-- Use GetSpellLink() in case this spellbook item was replaced by another spell,
			-- i.e., through talents or Symbiosis.
			local spellLink = API_GetSpellLink(index, bookType)
			if spellLink then
				local _, _, linkData, spellName = ParseHyperlink(spellLink)
				self.spell[tonumber(linkData)] = spellName
				if spellId then
					self.spell[spellId] = spellName
				end
			end
		elseif skillType == "FLYOUT" then
			local flyoutId = spellId
			local _, _, numSlots, isKnown = API_GetFlyoutInfo(flyoutId)
			if numSlots > 0 and isKnown then
				for flyoutIndex = 1, numSlots do
					local id, overrideId, isKnown, spellName = API_GetFlyoutSlotInfo(flyoutId, flyoutIndex)
					if isKnown then
						self.spell[id] = spellName
						self.spell[overrideId] = spellName
					end
				end
			end
		-- elseif skillType == "FUTURESPELL" then
		--	no-op
		elseif not skillType then
			break
		end
	end
end

function OvaleSpellBook:GetSpellName(spellId)
	if spellId then
		local name = self.spell[spellId]
		if not name then
			name = API_GetSpellInfo(spellId)
		end
		return name
	end
end

function OvaleSpellBook:GetTalentPoints(talentId)
	local points = 0
	if talentId and self.talentPoints[talentId] then
		points = self.talentPoints[talentId]
	end
	return points
end

function OvaleSpellBook:AddSpell(spellId, name)
	if spellId and name then
		self.spell[spellId] = name
	end
end

-- Returns true if the given glyph spell Id is an active glyph in the player's glyph tab.
function OvaleSpellBook:IsActiveGlyph(glyphId)
	if glyphId and self.glyph[glyphId] then
		return true
	else
		return false
	end
end

-- Returns true if the given spellId is found in the player's list of known spells.
function OvaleSpellBook:IsKnownSpell(spellId)
	if spellId and self.spell[spellId] then
		return true
	else
		return false
	end
end

-- Returns true if the given talentId is found in the player's talent tree.
function OvaleSpellBook:IsKnownTalent(talentId)
	if talentId and self.talentPoints[talentId] then
		return true
	else
		return false
	end
end

-- Returns true if the given spell ID is usable.  A spell is *not* usable if:
--     The player lacks required mana or reagents.
--     Reactive conditions haven't been met.
-- XXX Use IsSpellOverlayed() to catch instances where a spell becomes usable due
-- XXX to a proc but the proc replaces the spell in the spellbook, e.g.,
-- XXX "Aimed Shot" --> "Aimed Shot!".
function OvaleSpellBook:IsUsableSpell(spellId)
	local spellName = self:GetSpellName(spellId)
	local result = API_IsUsableSpell(spellName) or API_IsSpellOverlayed(spellId)
	if not result then
		-- Catch case where the name in the spellbook does not match the GetSpellInfo() name,
		-- e.g., druid's Incarnation.
		local name = API_GetSpellInfo(spellId)
		if name ~= spellName then
			result = API_IsUsableSpell(name)
		end
	end
	return result
end

-- Print out the list of active glyphs in alphabetical order.
function OvaleSpellBook:DebugGlyphs()
	PrintTableValues(self.glyph)
end

-- Print out the list of known spells in alphabetical order.
function OvaleSpellBook:DebugSpells()
	PrintTableValues(self.spell)
	local total = 0
	for _ in pairs(self.spell) do
		total = total + 1
	end
	Ovale:FormatPrint("Total spells: %d", total)
end

-- Print out the list of talents in alphabetical order.
function OvaleSpellBook:DebugTalents()
	PrintTableValues(self.talent)
end
--</public-static-methods>
