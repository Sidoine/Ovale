--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- This addon tracks the player's active spells, talents, and glyphs.

local OVALE, Ovale = ...
local OvaleSpellBook = Ovale:NewModule("OvaleSpellBook", "AceEvent-3.0")
Ovale.OvaleSpellBook = OvaleSpellBook

--<private-static-properties>
-- Profiling set-up.
local Profiler = Ovale.Profiler
local profiler = nil
do
	local group = OvaleSpellBook:GetName()
	Profiler:RegisterProfilingGroup(group)
	profiler = Profiler:GetProfilingGroup(group)
end

local L = Ovale.L
local OvaleOptions = Ovale.OvaleOptions
local OvaleDebug = Ovale.OvaleDebug

-- Forward declarations for module dependencies.
local OvaleData = nil
local OvalePower = nil
local OvaleState = nil

local ipairs = ipairs
local pairs = pairs
local strmatch = string.match
local tinsert = table.insert
local tonumber = tonumber
local tostring = tostring
local tsort = table.sort
local wipe = table.wipe
local API_GetActiveSpecGroup = GetActiveSpecGroup
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
local API_IsHarmfulSpell = IsHarmfulSpell
local API_IsHelpfulSpell = IsHelpfulSpell
local API_IsSpellInRange = IsSpellInRange
local API_IsUsableSpell = IsUsableSpell
local API_UnitHealth = UnitHealth
local API_UnitHealthMax = UnitHealthMax
local BOOKTYPE_PET = BOOKTYPE_PET
local BOOKTYPE_SPELL = BOOKTYPE_SPELL
local NUM_TALENT_COLUMNS = NUM_TALENT_COLUMNS

local MAX_NUM_TALENTS = MAX_NUM_TALENTS or 21
local MAX_NUM_TALENT_TIERS = MAX_NUM_TALENT_TIERS or 7

local OVALE_SPELLBOOK_DEBUG = "spellbook"
do
	OvaleDebug:RegisterDebugOption(OVALE_SPELLBOOK_DEBUG, L["Spellbook changes"], L["Debug spellbook changes"])
end

do
	local actions = {
		glyph = {
			name = L["List player glyphs"],
			type = "execute",
			func = function() OvaleSpellBook:DebugGlyphs() end,
		},
		spell = {
			name = L["List player spells"],
			type = "execute",
			func = function() OvaleSpellBook:DebugSpells() end,
		},
		talent = {
			name = L["List talents"],
			type = "execute",
			func = function() OvaleSpellBook:DebugTalents() end,
		},
	}
	-- Insert actions into OvaleOptions.
	for k, v in pairs(actions) do
		OvaleOptions.options.args.actions.args[k] = v
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
function OvaleSpellBook:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvalePower = Ovale.OvalePower
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
	self:RegisterEvent("PLAYER_ALIVE", "Update")
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
	Ovale:DebugPrintf(OVALE_SPELLBOOK_DEBUG, "Updating talents.")
	wipe(self.talent)
	wipe(self.talentPoints)

	local activeTalentGroup = API_GetActiveSpecGroup()
	for i = 1, MAX_NUM_TALENT_TIERS do
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
					Ovale:DebugPrintf(OVALE_SPELLBOOK_DEBUG, "    Talent %s (%d) is %s.", name, index, selected and "enabled" or "disabled")
				end
			end
		end
	end
	self:SendMessage("Ovale_TalentsChanged")
end

-- Update the player's glyphs by scanning the glyph socket tab for the active specialization.
function OvaleSpellBook:UpdateGlyphs()
	Ovale:DebugPrintf(OVALE_SPELLBOOK_DEBUG, "Updating glyphs.")
	wipe(self.glyph)

	for i = 1, API_GetNumGlyphSockets() do
		local enabled, _, _, glyphSpell, _ = API_GetGlyphSocketInfo(i)
		if enabled and glyphSpell then
			local name = self:GetSpellName(glyphSpell)
			self.glyph[glyphSpell] = name
			Ovale:DebugPrintf(OVALE_SPELLBOOK_DEBUG, "    Glyph socket %d has %s (%d).", i, name, glyphSpell)
		else
			Ovale:DebugPrintf(OVALE_SPELLBOOK_DEBUG, "    Glyph socket %d is empty.", i)
		end
	end
	self:SendMessage("Ovale_GlyphsChanged")
end

function OvaleSpellBook:UpdateSpells()
	wipe(self.spell)
	wipe(self.spellbookId[BOOKTYPE_PET])
	wipe(self.spellbookId[BOOKTYPE_SPELL])
	wipe(self.isHarmful)
	wipe(self.isHelpful)

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
	Ovale:DebugPrintf(OVALE_SPELLBOOK_DEBUG, "Updating '%s' spellbook starting at offset %d.", bookType, offset)
	for index = offset + 1, offset + numSpells do
		local skillType, spellId = API_GetSpellBookItemInfo(index, bookType)
		if skillType == "SPELL" or skillType == "PETACTION" then
			-- Use GetSpellLink() in case this spellbook item was replaced by another spell,
			-- i.e., through talents or Symbiosis.
			local spellLink = API_GetSpellLink(index, bookType)
			if spellLink then
				local _, _, linkData, spellName = ParseHyperlink(spellLink)
				local id = tonumber(linkData)
				Ovale:DebugPrintf(OVALE_SPELLBOOK_DEBUG, "    %s (%d) is at offset %d.", spellName, id, index)
				self.spell[id] = spellName
				self.isHarmful[id] = API_IsHarmfulSpell(index, bookType)
				self.isHelpful[id] = API_IsHelpfulSpell(index, bookType)
				self.spellbookId[bookType][id] = index
				if spellId and id ~= spellId then
					Ovale:DebugPrintf(OVALE_SPELLBOOK_DEBUG, "    %s (%d) is at offset %d.", spellName, spellId, index)
					self.spell[spellId] = spellName
					self.isHarmful[spellId] = self.isHarmful[id]
					self.isHelpful[spellId] = self.isHelpful[id]
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
						Ovale:DebugPrintf(OVALE_SPELLBOOK_DEBUG, "    %s (%d) is at offset %d.", spellName, id, index)
						self.spell[id] = spellName
						self.isHarmful[id] = API_IsHarmfulSpell(spellName)
						self.isHelpful[id] = API_IsHelpfulSpell(spellName)
						-- Flyout spells have no spellbook index.
						self.spellbookId[bookType][id] = nil
						if id ~= overrideId then
							Ovale:DebugPrintf(OVALE_SPELLBOOK_DEBUG, "    %s (%d) is at offset %d.", spellName, overrideId, index)
							self.spell[overrideId] = spellName
							self.isHarmful[overrideId] = self.isHarmful[id]
							self.isHelpful[overrideId] = self.isHelpful[id]
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

-- Returns whether a spell can be used against hostile units.
function OvaleSpellBook:IsHarmfulSpell(spellId)
	return (spellId and self.isHarmful[spellId])
end

-- Returns whether a spell can be used on the player or friendly units.
function OvaleSpellBook:IsHelpfulSpell(spellId)
	return (spellId and self.isHelpful[spellId])
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

-- Returns whether the unit is within range of the spell.
function OvaleSpellBook:IsSpellInRange(spellId, unitId)
	local index, bookType = self:GetSpellBookIndex(spellId)
	if index and bookType then
		return API_IsSpellInRange(index, bookType, unitId)
	else
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
	else
		local name = self:GetSpellName(spellId)
		return API_IsUsableSpell(name)
	end
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
statePrototype.IsUsableSpell = function(state, spellId, target)
	profiler.Start("OvaleSpellBook_state_IsUsableSpell")
	local isUsable = OvaleSpellBook:IsKnownSpell(spellId)
	local noMana = false
	-- Verify that the spell may be cast given restrictions specified in SpellInfo().
	local si = OvaleData.spellInfo[spellId]
	if si then
		-- Flagged as not usable in the spell information.
		if isUsable and si.unusable == 1 then
			Ovale:Logf("Spell ID '%s' is flagged as unusable.", spellId)
			isUsable = false
		end
		-- Stance.
		if isUsable and si.stance then
			isUsable = false
			if state:IsStance(si.stance) then
				isUsable = true
			end
			local result = isUsable and "pass" or "FAIL"
			Ovale:Logf("Spell ID '%s' requires the player to be in stance '%s': %s.", spellId, si.stance, result)
		end
		-- Stealthed.
		if isUsable and si.stealthed == 1 then
			isUsable = false
			-- Look for a buff that allows this ability to ignore the stealth requirements.
			if si.buff_no_stealthed then
				local aura = state:GetAura("player", si.buff_no_stealthed)
				if state:IsActiveAura(aura) then
					isUsable = true
				end
			end
			if not isUsable then
				local aura = state:GetAura("player", "stealthed_buff", "HELPFUL", true)
				if state:IsActiveAura(aura) then
					isUsable = true
				end
			end
			local result = isUsable and "pass" or "FAIL"
			Ovale:Logf("Spell ID '%s' requires the player to be stealthed: %s.", spellId, result)
		end
		-- Target health percent (execute range).
		if isUsable and si.target_health_pct then
			isUsable = false
			-- Look for a buff that allows this ability to ignore the health percent restriction.
			if si.buff_no_target_health_pct then
				local aura = state:GetAura("player", si.buff_no_target_health_pct)
				if state:IsActiveAura(aura) then
					isUsable = true
				end
			end
			if not isUsable then
				local healthPercent = API_UnitHealth(target) / API_UnitHealthMax(target) * 100
				if healthPercent < si.target_health_pct then
					isUsable = true
				end
			end
			local result = isUsable and "pass" or "FAIL"
			Ovale:Logf("Spell ID '%s' requires the target's health to be less than %f%%: %s.", spellId, si.target_health_pct, result)
		end
		-- Secondary resources, e.g., chi, focus, rage, etc.
		if isUsable and si.combo then
			isUsable = false
			-- Spell requires combo points.
			local cost = state:ComboPointCost(spellId)
			if cost > 0 then
				if state.combo >= cost then
					isUsable = true
				else
					noMana = true
				end
			else
				isUsable = true
			end
			local result = isUsable and "pass" or "FAIL"
			Ovale:Logf("Spell ID '%s' requires at least %d combo points: %s.", spellId, cost, result)
		end
		for powerType in pairs(OvalePower.SECONDARY_POWER) do
			if not isUsable then break end
			if si[powerType] then
				-- Spell requires a secondary resource.
				isUsable = false
				local cost = state:PowerCost(spellId, powerType)
				if cost > 0 then
					if state[powerType] >= cost then
						isUsable = true
					else
						noMana = true
					end
				else
					isUsable = true
				end
				local result = isUsable and "pass" or "FAIL"
				Ovale:Logf("Spell ID '%s' requires at least %d %s: %s.", spellId, cost, powerType, result)
			end
		end
	else
		isUsable, noMana = OvaleSpellBook:IsUsableSpell(spellId, target)
	end
	profiler.Stop("OvaleSpellBook_state_IsUsableSpell")
	return isUsable, noMana
end
--</state-methods>
