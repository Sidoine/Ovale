--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- This addon tracks the player's active spells, talents, and glyphs.

local OVALE, Ovale = ...
local OvaleSpellBook = Ovale:NewModule("OvaleSpellBook", "AceEvent-3.0")
Ovale.OvaleSpellBook = OvaleSpellBook

--<private-static-properties>
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleCooldown = nil
local OvaleData = nil
local OvalePower = nil
local OvaleRunes = nil
local OvaleState = nil

local ipairs = ipairs
local pairs = pairs
local strmatch = string.match
local tconcat = table.concat
local tinsert = table.insert
local tonumber = tonumber
local tostring = tostring
local tsort = table.sort
local type = type
local wipe = wipe
local API_GetActiveSpecGroup = GetActiveSpecGroup
local API_GetFlyoutInfo = GetFlyoutInfo
local API_GetFlyoutSlotInfo = GetFlyoutSlotInfo
local API_GetGlyphSocketInfo = GetGlyphSocketInfo
local API_GetNumGlyphSockets = GetNumGlyphSockets
local API_GetSpellBookItemInfo = GetSpellBookItemInfo
local API_GetSpellInfo = GetSpellInfo
local API_GetSpellLink = GetSpellLink
local API_GetSpellTabInfo = GetSpellTabInfo
local API_GetSpellTexture = GetSpellTexture
local API_GetTalentInfo = GetTalentInfo
local API_HasPetSpells = HasPetSpells
local API_IsHarmfulSpell = IsHarmfulSpell
local API_IsHelpfulSpell = IsHelpfulSpell
local API_IsSpellInRange = IsSpellInRange
local API_IsUsableSpell = IsUsableSpell
local BOOKTYPE_PET = BOOKTYPE_PET
local BOOKTYPE_SPELL = BOOKTYPE_SPELL
local MAX_TALENT_TIERS = MAX_TALENT_TIERS
local NUM_TALENT_COLUMNS = NUM_TALENT_COLUMNS
local MAX_NUM_TALENTS = NUM_TALENT_COLUMNS * MAX_TALENT_TIERS

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvaleSpellBook)
-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleSpellBook)

do
	local debugOptions = {
		glyph = {
			name = L["Glyphs"],
			type = "group",
			args = {
				glyph = {
					name = L["Glyphs"],
					type = "input",
					multiline = 25,
					width = "full",
					get = function(info) return OvaleSpellBook:DebugGlyphs() end,
				},
			},
		},
		spellbook = {
			name = L["Spellbook"],
			type = "group",
			args = {
				spellbook = {
					name = L["Spellbook"],
					type = "input",
					multiline = 25,
					width = "full",
					get = function(info) return OvaleSpellBook:DebugSpells() end,
				},
			},
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
					get = function(info) return OvaleSpellBook:DebugTalents() end,
				},
			},
		},
	}
	-- Insert debug options into OvaleDebug.
	for k, v in pairs(debugOptions) do
		OvaleDebug.options.args[k] = v
	end
end
--</private-static-properties>

--<public-static-properties>
-- Whether the spellbook information is ready for use by other modules.
OvaleSpellBook.ready = false
-- self.spell[spellId] = spellName
OvaleSpellBook.spell = {}
-- self.spellbookId[bookType][spellId] = index of spell in the spellbook
OvaleSpellBook.spellbookId = {
	[BOOKTYPE_PET] = {},
	[BOOKTYPE_SPELL] = {},
}
-- self.isHarmful[spellId] = true/false
OvaleSpellBook.isHarmful = {}
-- self.isHelpful[spellId] = true/false
OvaleSpellBook.isHelpful = {}
-- self.texture[spellId] = path to texture
OvaleSpellBook.texture = {}
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

local function OutputTableValues(output, tbl)
	local array = {}
	for k, v in pairs(tbl) do
		tinsert(array, tostring(v) .. ": " .. tostring(k))
	end
	tsort(array)
	for _, v in ipairs(array) do
		output[#output + 1] = v
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleSpellBook:OnInitialize()
	-- Resolve module dependencies.
	OvaleCooldown = Ovale.OvaleCooldown
	OvaleData = Ovale.OvaleData
	OvalePower = Ovale.OvalePower
	OvaleRunes = Ovale.OvaleRunes
	OvaleState = Ovale.OvaleState
end

function OvaleSpellBook:OnEnable()
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "Update")
	self:RegisterEvent("CHARACTER_POINTS_CHANGED", "UpdateTalents")
	self:RegisterEvent("GLYPH_ADDED", "UpdateGlyphs")
	self:RegisterEvent("GLYPH_DISABLED", "UpdateGlyphs")
	self:RegisterEvent("GLYPH_ENABLED", "UpdateGlyphs")
	self:RegisterEvent("GLYPH_REMOVED", "UpdateGlyphs")
	self:RegisterEvent("GLYPH_UPDATED", "UpdateGlyphs")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateTalents")
	self:RegisterEvent("SPELLS_CHANGED", "UpdateSpells")
	self:RegisterEvent("UNIT_PET")
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvaleSpellBook:OnDisable()
	OvaleState:UnregisterState(self)
	self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:UnregisterEvent("CHARACTER_POINTS_CHANGED")
	self:UnregisterEvent("GLYPH_ADDED")
	self:UnregisterEvent("GLYPH_DISABLED")
	self:UnregisterEvent("GLYPH_ENABLED")
	self:UnregisterEvent("GLYPH_REMOVED")
	self:UnregisterEvent("GLYPH_UPDATED")
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
	self:Debug("Updating talents.")
	wipe(self.talent)
	wipe(self.talentPoints)

	local activeTalentGroup = API_GetActiveSpecGroup()
	for i = 1, MAX_TALENT_TIERS do
		for j = 1, NUM_TALENT_COLUMNS do
			local talentId, name, _, selected, _ = API_GetTalentInfo(i, j, activeTalentGroup)
			if talentId then
				local index = 3 * (i - 1) + j
				if index <= MAX_NUM_TALENTS then
					self.talent[index] = name
					if selected then
						self.talentPoints[index] = 1
					else
						self.talentPoints[index] = 0
					end
					self:Debug("    Talent %s (%d) is %s.", name, index, selected and "enabled" or "disabled")
				end
			end
		end
	end
	Ovale.refreshNeeded.player = true
	self:SendMessage("Ovale_TalentsChanged")
end

-- Update the player's glyphs by scanning the glyph socket tab for the active specialization.
function OvaleSpellBook:UpdateGlyphs()
	self:Debug("Updating glyphs.")
	wipe(self.glyph)

	for i = 1, API_GetNumGlyphSockets() do
		local enabled, _, _, glyphSpell, _ = API_GetGlyphSocketInfo(i)
		if enabled and glyphSpell then
			local name = self:GetSpellName(glyphSpell)
			self.glyph[glyphSpell] = name
			self:Debug("    Glyph socket %d has %s (%d).", i, name, glyphSpell)
		else
			self:Debug("    Glyph socket %d is empty.", i)
		end
	end
	Ovale.refreshNeeded.player = true
	self:SendMessage("Ovale_GlyphsChanged")
end

function OvaleSpellBook:UpdateSpells()
	wipe(self.spell)
	wipe(self.spellbookId[BOOKTYPE_PET])
	wipe(self.spellbookId[BOOKTYPE_SPELL])
	wipe(self.isHarmful)
	wipe(self.isHelpful)
	wipe(self.texture)

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

	Ovale.refreshNeeded.player = true
	self:SendMessage("Ovale_SpellsChanged")
end

-- Scan a spellbook and populate self.spell table.
function OvaleSpellBook:ScanSpellBook(bookType, numSpells, offset)
	offset = offset or 0
	self:Debug("Updating '%s' spellbook starting at offset %d.", bookType, offset)
	for index = offset + 1, offset + numSpells do
		local skillType, spellId = API_GetSpellBookItemInfo(index, bookType)
		if skillType == "SPELL" or skillType == "PETACTION" then
			-- Use GetSpellLink() in case this spellbook item was replaced by another spell,
			-- i.e., through talents or Symbiosis.
			local spellLink = API_GetSpellLink(index, bookType)
			if spellLink then
				local _, _, linkData, spellName = ParseHyperlink(spellLink)
				local id = tonumber(linkData)
				self:Debug("    %s (%d) is at offset %d.", spellName, id, index)
				self.spell[id] = spellName
				self.isHarmful[id] = API_IsHarmfulSpell(index, bookType)
				self.isHelpful[id] = API_IsHelpfulSpell(index, bookType)
				self.texture[id] = API_GetSpellTexture(index, bookType)
				self.spellbookId[bookType][id] = index
				if spellId and id ~= spellId then
					self:Debug("    %s (%d) is at offset %d.", spellName, spellId, index)
					self.spell[spellId] = spellName
					self.isHarmful[spellId] = self.isHarmful[id]
					self.isHelpful[spellId] = self.isHelpful[id]
					self.texture[spellId] = self.texture[id]
					self.spellbookId[bookType][spellId] = index
				end
			end
		elseif skillType == "FLYOUT" then
			local flyoutId = spellId
			local _, _, numSlots, isKnown = API_GetFlyoutInfo(flyoutId)
			if numSlots > 0 and isKnown then
				for flyoutIndex = 1, numSlots do
					local id, overrideId, isKnown, spellName = API_GetFlyoutSlotInfo(flyoutId, flyoutIndex)
					if isKnown then
						self:Debug("    %s (%d) is at offset %d.", spellName, id, index)
						self.spell[id] = spellName
						self.isHarmful[id] = API_IsHarmfulSpell(spellName)
						self.isHelpful[id] = API_IsHelpfulSpell(spellName)
						self.texture[id] = API_GetSpellTexture(index, bookType)
						-- Flyout spells have no spellbook index.
						self.spellbookId[bookType][id] = nil
						if id ~= overrideId then
							self:Debug("    %s (%d) is at offset %d.", spellName, overrideId, index)
							self.spell[overrideId] = spellName
							self.isHarmful[overrideId] = self.isHarmful[id]
							self.isHelpful[overrideId] = self.isHelpful[id]
							self.texture[overrideId] = self.texture[id]
							-- Flyout spells have no spellbook index.
							self.spellbookId[bookType][overrideId] = nil
						end
					end
				end
			end
		elseif skillType == "FUTURESPELL" then
			--	no-op
		elseif not skillType then
			break
		end
	end
end

-- Returns the cast time of a spell in seconds.
function OvaleSpellBook:GetCastTime(spellId)
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
end

function OvaleSpellBook:GetSpellInfo(spellId)
	local index, bookType = self:GetSpellBookIndex(spellId)
	if index and bookType then
		return API_GetSpellInfo(index, bookType)
	else
		return API_GetSpellInfo(spellId)
	end
end

function OvaleSpellBook:GetSpellName(spellId)
	if spellId then
		local spellName = self.spell[spellId]
		if not spellName then
			spellName = self:GetSpellInfo(spellId)
		end
		return spellName
	end
end

function OvaleSpellBook:GetSpellTexture(spellId)
	return self.texture[spellId]
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
	return (glyphId and self.glyph[glyphId]) and true or false
end

-- Returns whether a spell can be used against hostile units.
function OvaleSpellBook:IsHarmfulSpell(spellId)
	return (spellId and self.isHarmful[spellId]) and true or false
end

-- Returns whether a spell can be used on the player or friendly units.
function OvaleSpellBook:IsHelpfulSpell(spellId)
	return (spellId and self.isHelpful[spellId]) and true or false
end

-- Returns true if the given spellId is found in the player's list of known spells.
function OvaleSpellBook:IsKnownSpell(spellId)
	return (spellId and self.spell[spellId]) and true or false
end

-- Returns true if the given talentId is found in the player's talent tree.
function OvaleSpellBook:IsKnownTalent(talentId)
	return (talentId and self.talentPoints[talentId]) and true or false
end

-- Returns the index in the spellbook of the given spell.
function OvaleSpellBook:GetSpellBookIndex(spellId)
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
end

-- Returns whether a spell is a pet spell.
function OvaleSpellBook:IsPetSpell(spellId)
	local index, bookType = self:GetSpellBookIndex(spellId)
	return bookType == BOOKTYPE_PET
end

-- Returns whether the unit is within range of the spell.
function OvaleSpellBook:IsSpellInRange(spellId, unitId)
	local index, bookType = self:GetSpellBookIndex(spellId)
	if index and bookType then
		return API_IsSpellInRange(index, bookType, unitId)
	elseif self:IsKnownSpell(spellId) then
		local name = self:GetSpellName(spellId)
		return API_IsSpellInRange(name, unitId)
	end
end

-- Returns true if the given spell ID is usable.  A spell is *not* usable if:
--     The player lacks required mana or reagents.
--     Reactive conditions haven't been met.
function OvaleSpellBook:IsUsableSpell(spellId)
	local index, bookType = self:GetSpellBookIndex(spellId)
	if index and bookType then
		return API_IsUsableSpell(index, bookType)
	elseif self:IsKnownSpell(spellId) then
		local name = self:GetSpellName(spellId)
		return API_IsUsableSpell(name)
	end
end

-- Print out the list of active glyphs in alphabetical order.
do
	local output = {}

	function OvaleSpellBook:DebugGlyphs()
		wipe(output)
		OutputTableValues(output, self.glyph)
		return tconcat(output, "\n")
	end

	-- Print out the list of known spells in alphabetical order.
	function OvaleSpellBook:DebugSpells()
		wipe(output)
		OutputTableValues(output, self.spell)
		local total = 0
		for _ in pairs(self.spell) do
			total = total + 1
		end
		output[#output + 1] = "Total spells: " .. total
		return tconcat(output, "\n")
	end

	-- Print out the list of talents in alphabetical order.
	function OvaleSpellBook:DebugTalents()
		wipe(output)
		OutputTableValues(output, self.talent)
		return tconcat(output, "\n")
	end
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleSpellBook.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleSpellBook.statePrototype
--</private-static-properties>

--<state-methods>
statePrototype.IsUsableSpell = function(state, spellId, atTime, target)
	OvaleSpellBook:StartProfiling("OvaleSpellBook_state_IsUsableSpell")
	if type(atTime) == "string" and not target then
		atTime, target = nil, atTime
	end
	atTime = atTime or state.currentTime

	local isUsable = OvaleSpellBook:IsKnownSpell(spellId)
	local noMana = false
	-- Verify that the spell may be cast given restrictions specified in SpellInfo().
	local si = OvaleData.spellInfo[spellId]
	if si then
		-- Flagged as not usable in the spell information.
		if isUsable then
			local unusable = state:GetSpellInfoProperty(spellId, atTime, "unusable", target)
			if unusable == 1 then
				state:Log("Spell ID '%s' is flagged as unusable.", spellId)
				isUsable = false
			end
		end
		-- Verify all requirements with registered handlers.
		if isUsable then
			local requirement
			isUsable, requirement = state:CheckSpellInfo(spellId, atTime, target)
			if not isUsable then
				-- Set noMana if the failed requirement is for a primary (poolable) power type.
				if OvalePower.PRIMARY_POWER[requirement] then
					noMana = true
				end
				if noMana then
					state:Log("Spell ID '%s' does not have enough %s.", spellId, requirement)
				else
					state:Log("Spell ID '%s' failed '%s' requirements.", spellId, requirement)
				end
			end
		end
	else
		isUsable, noMana = OvaleSpellBook:IsUsableSpell(spellId)
	end
	OvaleSpellBook:StopProfiling("OvaleSpellBook_state_IsUsableSpell")
	return isUsable, noMana
end

-- Get the number of seconds before the spell is ready to be cast, either due to cooldown or resources.
statePrototype.GetTimeToSpell = function(state, spellId, atTime, target)
	if type(atTime) == "string" and not target then
		atTime, target = nil, atTime
	end
	atTime = atTime or state.currentTime

	local timeToSpell = 0
	-- Cooldown.
	do
		local start, duration = state:GetSpellCooldown(spellId)
		local seconds = (duration > 0) and (start + duration - atTime) or 0
		if timeToSpell < seconds then
			timeToSpell = seconds
		end
	end
	-- Pooled resource.
	do
		local seconds = state:TimeToPower(spellId, atTime, target)
		if timeToSpell < seconds then
			timeToSpell = seconds
		end
	end
	-- Death knight runes.
	do
		local blood = state:GetSpellInfoProperty(spellId, atTime, "blood", target)
		local unholy = state:GetSpellInfoProperty(spellId, atTime, "unholy", target)
		local frost = state:GetSpellInfoProperty(spellId, atTime, "frost", target)
		local death = state:GetSpellInfoProperty(spellId, atTime, "death", target)
		if blood or unholy or frost or death then
			local seconds = state:GetRunesCooldown(blood, unholy, frost, death, atTime)
			if timeToSpell < seconds then
				timeToSpell = seconds
			end
		end
	end
	return timeToSpell
end
--</state-methods>
