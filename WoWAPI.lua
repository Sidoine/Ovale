--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

--[[--------------------------------------------------------------------
	This file implements parts of the WoW API for development and
	unit-testing.

	This file is not meant to be loaded into the addon.  It should be
	used only outside of the WoW environment, such as when loaded by a
	standalone Lua 5.1 interpreter.
--]]--------------------------------------------------------------------

-- Globally-accessible module table.
WoWAPI = {}

--<private-static-properties>
local format = string.format
local getmetatable = getmetatable
local gsub = string.gsub
local ipairs = ipairs
local loadstring = loadstring
local next = next
local pairs = pairs
local print = print
local rawset = rawset
local select = select
local setmetatable = setmetatable
local strfind = string.find
local strgfind = string.gfind
local strmatch = string.match
local strsub = string.sub
local type = type
local unpack = unpack

local self_state = {}
local self_privateSymbol = {
	["ExportSymbols"] = true,
	["Fire"] = true,
	["Initialize"] = true,
	["LoadAddonFile"] = true,
	["LoadLua"] = true,
	["LoadTOC"] = true,
	["LoadXML"] = true,
}

-- Metatable to provide __index method to tables so that if the requested key
-- is missing from the table, then a new key is inserted with the value being
-- the same as the missing key.
local KeysAreMissingValuesMetatable = {
	__index = function(t, k)
		rawset(t, k, k)
		return k
	end,
}
--</private-static-properties>

--<private-static-methods>
local function DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function DoNothing()
	-- No op.
end

local function ZeroFunction()
	return 0
end
--</private-static-methods>

--<private-static-properties>
--[[--------------------------------
	Fake library implementations.
--]]--------------------------------

-- AceAddon-3.0
local AceAddon = nil
do
	local lib = {}
	AceAddon = lib

	lib.initializationQueue = {}

	local prototype = {}

	prototype.GetModule = function(addon, name)
		addon.modules = addon.modules or {}
		return addon.modules[name]
	end

	prototype.GetName = function(addon)
		return addon.moduleName or addon.name
	end

	prototype.IterateModules = function(addon)
		return pairs(addon.modules)
	end

	prototype.NewModule = function(addon, name, ...)
		local args = { ... }
		local mod = lib:NewAddon(format("%s_%s", addon.name, name))
		mod.moduleName = name
		-- Mix in default module prototype
		if addon.modulePrototype then
			for k, v in pairs(addon.modulePrototype) do
				mod[k] = v
			end
		end
		-- Embed methods from named libraries.
		for _, libName in ipairs(args) do
			local lib = WoWAPI.LibStub(libName)
			if lib then
				for k, v in pairs(lib) do
					mod[k] = v
				end
			end
		end
		addon.modules = addon.modules or {}
		addon.modules[name] = mod
		return mod
	end

	prototype.SetDefaultModulePrototype = function(addon, proto)
		addon.modulePrototype = proto
	end

	lib.GetAddon = function(lib, name)
		lib.addons = lib.addons or {}
		return lib.addons[name]
	end

	lib.Fire = function(lib, event, ...)
		for _, addon in ipairs(lib.initializationQueue) do
			if event == "ADDON_LOADED" and addon.OnInitialize then
				addon:OnInitialize()
			elseif event == "PLAYER_LOGIN" and addon.OnEnable then
				addon:OnEnable()
			elseif addon.SendMessage then
				addon:SendMessage(event, ...)
			end
		end
	end

	lib.IterateAddons = function(lib)
		return pairs(lib.addons)
	end

	lib.NewAddon = function(lib, name, ...)
		local addon
		local args
		if type(name) == "nil" then
			addon = {}
			name = ...
			args = { select(2, ...) }
		elseif type(name) == "table" then
			addon = name
			name = ...
			args = { select(2, ...) }
		else
			addon = {}
			args = { ... }
		end
		-- Copy addon prototype.
		for k, v in pairs(prototype) do
			addon[k] = v
		end
		-- Embed methods from named libraries.
		for _, libName in ipairs(args) do
			local lib = WoWAPI.LibStub(libName)
			if lib then
				for k, v in pairs(lib) do
					addon[k] = v
				end
			end
		end
		addon.name = name
		lib.addons = lib.addons or {}
		lib.addons[name] = addon
		lib.initializationQueue[#lib.initializationQueue + 1] = addon
		return addon
	end
end

-- AceConfig-3.0
local AceConfig = nil
do
	local lib = {}
	AceConfig = lib
	lib.RegisterOptionsTable = DoNothing
end

-- AceConfigDialog-3.0
local AceConfigDialog = nil
do
	local lib = {}
	AceConfigDialog = lib
	lib.AddToBlizOptions = DoNothing
end

-- AceConsole-3.0
local AceConsole = nil
do
	local lib = {}
	AceConsole = lib

	lib.Print = function(lib, ...)
		print(...)
	end

	lib.Printf = function(lib, ...)
		print(format(...))
	end
end

-- AceDB-3.0
local AceDB = nil
do
	local lib = {}
	AceDB = lib

	lib.New = function(lib, name, template)
		template = template or {}
		local db = DeepCopy(template)
		db.RegisterCallback = DoNothing
		db.RegisterDefaults = DoNothing
		return db
	end
end

-- AceDBOptions-3.0
local AceDBOptions = nil
do
	local lib = {}
	AceDBOptions = lib
	lib.GetOptionsTable = DoNothing
end

-- AceEvent-3.0
local AceEvent = nil
do
	local lib = {}
	AceEvent = lib

	local eventHandler = {}

	lib.RegisterEvent = function(lib, event, handler, arg)
		eventHandler[lib] = eventHandler[lib] or {}
		eventHandler[lib][event] = { handler, arg }
	end

	lib.RegisterMessage = lib.RegisterEvent

	lib.SendMessage = function(lib, event, ...)
		local handler, arg
		local tbl = eventHandler[lib] and eventHandler[lib][event]
		if tbl then
			handler, arg = tbl[1], tbl[2]
			if type(handler) == "string" then
				handler = lib[handler]
				arg = lib
			end
		else
			handler = lib[event]
			arg = lib
		end
		if handler then
			if arg then
				handler(arg, event, ...)
			else
				handler(event, ...)
			end
		end
	end
end

-- AceGUI-3.0
local AceGUI = nil
do
	local lib = {}
	AceGUI = lib

	local widgetFactory = {}
	local container = {}

	lib.Create = function(lib, widgetType)
		local constructor = widgetFactory[widgetType]
		if constructor then
			return constructor()
		end
	end

	lib.RegisterAsContainer = function(lib, widget)
		container[widget] = true
		widget.AddChild = DoNothing
		widget.ReleaseChildren = DoNothing
	end

	lib.RegisterWidgetType = function(lib, name, constructor, version)
		widgetFactory[name] = constructor
	end
end

-- AceLocale-3.0
local AceLocale = nil
do
	local lib = {}
	AceLocale = lib

	lib.GetLocale = function(lib, name)
		local L
		if lib.locale and lib.locale[name] then
			L = lib.locale[name]
		else
			L = lib:NewLocale(name, nil)
		end
		return L
	end

	lib.NewLocale = function(lib, name, locale)
		local L = setmetatable({}, KeysAreMissingValuesMetatable)
		lib.locale = lib.locale or {}
		lib.locale[name] = L
		return L
	end
end

-- AceTimer-3.0
local AceTimer = nil
do
	local lib = {}
	AceTimer = lib
	lib.ScheduleRepeatingTimer = DoNothing
end

-- CallbackHandler-1.0
local CallbackHandler = nil
do
	local lib = {}
	CallbackHandler = lib

	lib.New = function(lib, obj)
		obj.Fire = lib.Fire
		return obj
	end

	lib.Fire = function(lib, ...) end
end

-- LibBabble-CreatureType-3.0
local LibBabbleCreatureType = nil
do
	local lib = {}
	LibBabbleCreatureType = lib

	lib.GetLookupTable = function(lib)
		local tbl = lib.lookupTable or setmetatable({}, KeysAreMissingValuesMetatable)
		lib.lookupTable = tbl
		return tbl
	end
end

-- LibTextDump-1.0
local LibTextDump = nil
do
	local lib = {}
	LibTextDump = lib
	lib.New = DoNothing
end

-- LibStub
local LibStub = nil
do
	local lib = {}
	LibStub = lib

	lib.library = {
		["AceAddon-3.0"] = AceAddon,
		["AceConfig-3.0"] = AceConfig,
		["AceConfigDialog-3.0"] = AceConfigDialog,
		["AceConsole-3.0"] = AceConsole,
		["AceDB-3.0"] = AceDB,
		["AceDBOptions-3.0"] = AceDBOptions,
		["AceEvent-3.0"] = AceEvent,
		["AceGUI-3.0"] = AceGUI,
		["AceLocale-3.0"] = AceLocale,
		["AceTimer-3.0"] = AceTimer,
		["CallbackHandler-1.0"] = CallbackHandler,
		["LibBabble-CreatureType-3.0"] = LibBabbleCreatureType,
		["LibTextDump-1.0"] = LibTextDump,
	}

	local mt = {
		__call = function(lib, name, flag)
			return lib:GetLibrary(name, flag)
		end,
	}

	lib.GetLibrary = function(lib, name, flag)
		return lib.library[name]
	end

	lib.NewLibrary = function(lib, name, major, minor)
		local newLib = {}
		lib.library[name] = newLib
		return newLib
	end

	setmetatable(lib, mt)
end
--</private-static-properties>

--<public-static-properties>
--[[----------------------
	FrameXML/ChatFrame
--]]----------------------

WoWAPI.DEFAULT_CHAT_FRAME = {
	AddMessage = function(frame, text, red, green, blue, alpha)
		-- Strip out color UI escape sequences.
		text = gsub(text, "|c[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]", "")
		text = gsub(text, "|r", "")
		print(text)
	end
}

--[[----------------------
	FrameXML/Constants
--]]----------------------

-- Inventory slots
WoWAPI.INVSLOT_AMMO		= 0
WoWAPI.INVSLOT_HEAD		= 1
WoWAPI.INVSLOT_NECK		= 2
WoWAPI.INVSLOT_SHOULDER	= 3
WoWAPI.INVSLOT_BODY		= 4
WoWAPI.INVSLOT_CHEST	= 5
WoWAPI.INVSLOT_WAIST	= 6
WoWAPI.INVSLOT_LEGS		= 7
WoWAPI.INVSLOT_FEET		= 8
WoWAPI.INVSLOT_WRIST	= 9
WoWAPI.INVSLOT_HAND		= 10
WoWAPI.INVSLOT_FINGER1	= 11
WoWAPI.INVSLOT_FINGER2	= 12
WoWAPI.INVSLOT_TRINKET1	= 13
WoWAPI.INVSLOT_TRINKET2	= 14
WoWAPI.INVSLOT_BACK		= 15
WoWAPI.INVSLOT_MAINHAND	= 16
WoWAPI.INVSLOT_OFFHAND	= 17
WoWAPI.INVSLOT_RANGED	= 18
WoWAPI.INVSLOT_TABARD	= 19
WoWAPI.INVSLOT_FIRST_EQUIPPED = WoWAPI.INVSLOT_HEAD
WoWAPI.INVSLOT_LAST_EQUIPPED = WoWAPI.INVSLOT_TABARD

-- Power Types
WoWAPI.SPELL_POWER_MANA				= 0
WoWAPI.SPELL_POWER_RAGE				= 1
WoWAPI.SPELL_POWER_FOCUS			= 2
WoWAPI.SPELL_POWER_ENERGY			= 3
--WoWAPI.SPELL_POWER_CHI			= 4		-- This is obsolete now.
WoWAPI.SPELL_POWER_RUNES			= 5
WoWAPI.SPELL_POWER_RUNIC_POWER		= 6
WoWAPI.SPELL_POWER_SOUL_SHARDS		= 7
WoWAPI.SPELL_POWER_ECLIPSE			= 8
WoWAPI.SPELL_POWER_HOLY_POWER		= 9
WoWAPI.SPELL_POWER_ALTERNATE_POWER	= 10
WoWAPI.SPELL_POWER_DARK_FORCE		= 11
WoWAPI.SPELL_POWER_CHI				= 12
WoWAPI.SPELL_POWER_SHADOW_ORBS		= 13
WoWAPI.SPELL_POWER_BURNING_EMBERS	= 14
WoWAPI.SPELL_POWER_DEMONIC_FURY		= 15

WoWAPI.RAID_CLASS_COLORS = {
	["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = "ffabd473" },
	["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79, colorStr = "ff9482c9" },
	["PRIEST"] = { r = 1.0, g = 1.0, b = 1.0, colorStr = "ffffffff" },
	["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba" },
	["MAGE"] = { r = 0.41, g = 0.8, b = 0.94, colorStr = "ff69ccf0" },
	["ROGUE"] = { r = 1.0, g = 0.96, b = 0.41, colorStr = "fffff569" },
	["DRUID"] = { r = 1.0, g = 0.49, b = 0.04, colorStr = "ffff7d0a" },
	["SHAMAN"] = { r = 0.0, g = 0.44, b = 0.87, colorStr = "ff0070de" },
	["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e" },
	["DEATHKNIGHT"] = { r = 0.77, g = 0.12 , b = 0.23, colorStr = "ffc41f3b" },
	["MONK"] = { r = 0.0, g = 1.00 , b = 0.59, colorStr = "ff00ff96" },
}

--[[--------------------------
	FrameXML/GlobalStrings
--]]--------------------------

WoWAPI.ITEM_LEVEL = "Item Level %d"

--[[---------------------------
	FrameXML/SpellBookFrame
--]]---------------------------

WoWAPI.BOOKTYPE_SPELL = "spell"
WoWAPI.BOOKTYPE_PET = "pet"

--[[----------------------------
	FrameXML/TalentFrameBase
--]]----------------------------

WoWAPI.MAX_TALENT_TIERS = 7
WoWAPI.NUM_TALENT_COLUMNS = 3

--[[--------------------------------------------------------------------
	debugprofilestop() is a non-standard Lua function that returns the
	current time in milliseconds.

	This is a trivial implementation to just get the Profiler module
	working.
--]]--------------------------------------------------------------------
WoWAPI.debugprofilestop = ZeroFunction

--[[--------------------------------------------------------------------
	strsplit() is a non-standard Lua function that splits a string and
	returns multiple return values for each substring delimited by the
	named delimiter character.

	This implementation is taken verbatim from:
		http://lua-users.org/wiki/SplitJoin
--]]--------------------------------------------------------------------
WoWAPI.strsplit = function(delim, str, maxNb)
	-- Fix up '.' character class.
	delim = gsub(delim, "%.", "%%.")
	-- Eliminate bad cases...
	if strfind(str, delim) == nil then
		return str
	end
	if maxNb == nil or maxNb < 1 then
		maxNb = 0    -- No limit
	end
	local result = {}
	local pat = "(.-)" .. delim .. "()"
	local nb = 0
	local lastPos
	for part, pos in strgfind(str, pat) do
		nb = nb + 1
		result[nb] = part
		lastPos = pos
		if nb == maxNb then break end
	end
	-- Handle the last field
	if nb ~= maxNb then
		result[nb + 1] = strsub(str, lastPos)
	end
	return unpack(result)
end

--[[--------------------------------------------------------------------
	tostringall() is a non-standard Lua function that returns a list of
	each argument converted to a string.
--]]--------------------------------------------------------------------
WoWAPI.tostringall = function(...)
	local array = { ... }
	local N = select("#", ...)
	for i = 1, N do
		array[N] = tostring(array[N])
	end
	return unpack(array)
end

--[[--------------------------------------------------------------------
	wipe() is a non-standard Lua function that clears the contents of a
	table and leaves the table pointer intact.
--]]--------------------------------------------------------------------
WoWAPI.wipe = function(t)
	for k in pairs(t) do
		t[k] = nil
	end
end

--[[-------------------------------------------------
	Fake Blizzard API functions for unit testing.
--]]-------------------------------------------------

WoWAPI.CreateFrame = function(...)
	local frame = {
		CreateTexture = function(...) return WoWAPI.CreateFrame() end,
		EnableMouse = DoNothing,
		Hide = DoNothing,
		IsVisible = DoNothing,
		NumLines = ZeroFunction,
		SetAllPoints = DoNothing,
		SetAlpha = DoNothing,
		SetFrameStrata = DoNothing,
		SetHeight = DoNothing,
		SetInventoryItem = DoNothing,
		SetMovable = DoNothing,
		SetOwner = DoNothing,
		SetPoint = DoNothing,
		SetScript = DoNothing,
		SetTexture = DoNothing,
		SetWidth = DoNothing,
	}
	return frame
end

WoWAPI.GetActiveSpecGroup = function()
	-- Always in the primary specialization.
	return 1
end

WoWAPI.GetActionInfo = function(slot)
	-- Action bar is always empty.
	return nil
end

WoWAPI.GetAuctionItemSubClasses = function(classIndex)
	return
		"One-Handed Axes",
		"Two-Handed Axes",
		"Bows",
		"Guns",
		"One-Handed Maces",
		"Two-Handed Maces",
		"Polearms",
		"One-Handed Swords",
		"Two-Handed Swords",
		"Staves",
		"Fist Weapons",
		"Miscellaneous",
		"Daggers",
		"Thrown",
		"Crossbows",
		"Wands",
		"Fishing Poles"
end

-- No keybinds are assigned.
WoWAPI.GetBindingKey = function(name)
	return nil
end

WoWAPI.GetBonusBarIndex = function()
	return 8
end

WoWAPI.GetGlyphSocketInfo = function(socket, talentGroup)
	-- No glyphs.
	return nil
end

WoWAPI.GetInventoryItemGems = function(slot)
	-- Player is always completely un-gemmed.
	return nil
end

WoWAPI.GetInventoryItemID = function(unitId, slot)
	-- All units are naked.
	return nil
end

WoWAPI.GetItemInfo = function(item)
	if type(item) == "number" then
		item = format("Item Name Of %d", item)
	end
	return item
end

WoWAPI.GetLocale = function()
	return "enUS"
end

WoWAPI.GetNumGlyphSockets = function()
	-- 3 x Major + 3 x Minor
	return 6
end

WoWAPI.GetNumShapeshiftForms = ZeroFunction

WoWAPI.GetPowerRegen = function()
	return 0, 0
end

WoWAPI.GetShapeshiftForm = function()
	-- Always in humanoid form.
	return 0
end

WoWAPI.GetSpecialization = function()
	local specialization = self_state.specialization or 1
	return specialization
end

WoWAPI.GetSpellInfo = function(spell)
	if type(spell) == "number" then
		spell = format("Spell Name Of %d", spell)
	end
	return spell
end

WoWAPI.GetSpellTabInfo = function(index)
	-- No spells in the spellbook.
	return nil
end

WoWAPI.GetTalentInfo = function(row, column, activeTalentGroup)
	-- No talents.
	return 123, "A Talent", nil, 0, nil
end

WoWAPI.GetTime = function()
	return 1234
end

WoWAPI.HasPetSpells = function()
	-- No pet spells.
	return false
end

WoWAPI.RegisterAddonMessagePrefix = function(prefixString) end
WoWAPI.RegisterStateDriver = function(frame, stateId, conditional) end

WoWAPI.UnitAura = function(unitId)
	-- No auras on any unit.
	return nil
end

WoWAPI.UnitClass = function()
	local class = self_state.class
	return class, class
end

WoWAPI.UnitGUID = function(unitId)
	local guid = self_state.guid or 0
	return guid
end

WoWAPI.UnitLevel = function()
	return self_state.level
end

WoWAPI.UnitName = function()
	local name = self_state.name or "AwesomePlayer"
	return name
end

WoWAPI.UnitPower = function(unitId, powerType)
	-- Always no resources on any unit.
	return 0
end

WoWAPI.UnitPowerMax = function(unitId, powerType)
	-- Resources are from 0 to 100.
	return 100
end

WoWAPI.UnitPowerType = function(unitId)
	-- Every unit is a mana user.
	return WoWAPI.SPELL_POWER_MANA, "MANA"
end

-- Unit stat functions for a naked toon.
WoWAPI.GetCombatRating = ZeroFunction
WoWAPI.GetCritChance = ZeroFunction
WoWAPI.GetMastery = ZeroFunction
WoWAPI.GetMasteryEffect = ZeroFunction
WoWAPI.GetMeleeHaste = ZeroFunction
WoWAPI.GetRangedCritChance = ZeroFunction
WoWAPI.GetRangedHaste = ZeroFunction
WoWAPI.GetSpellBonusDamage = ZeroFunction
WoWAPI.GetSpellBonusHealing = ZeroFunction
WoWAPI.GetSpellCritChance = ZeroFunction
WoWAPI.UnitAttackPower = function(unitId) return 0, 0, 0 end
WoWAPI.UnitAttackSpeed = function(unitId) return 0, 0 end
WoWAPI.UnitDamage = function(unitId) return 0, 0, 0, 0, 0, 0, 0 end
WoWAPI.UnitRangedAttackPower = WoWAPI.UnitAttackPower
WoWAPI.UnitSpellHaste = ZeroFunction
WoWAPI.UnitStat = ZeroFunction

WoWAPI.bit = {
	band = DoNothing,
	bor = DoNothing,
}

WoWAPI.LibStub = LibStub
--</public-static-properties>

--<private-static-methods>
local function FileExists(filename, directory, verbose)
	if directory then
		filename = directory .. filename
	end
	local fh = io.open(filename, "r")
	if fh then
		fh:close()
		return true
	else
		if verbose then
			print(format("Warning: '%s' not found.", filename))
		end
		return false
	end
end
--</private-static-methods>

--<public-static-methods>
function WoWAPI:Initialize(addonName, state)
	state = state or {}
	for k, v in pairs(state) do
		self_state[k] = v
	end
	self_state.addonName = addonName
end

-- Export symbols to the given namespace, taking care not to overwrite existing symbols.
function WoWAPI:ExportSymbols(namespace)
	-- Default to adding symbols to the global namespace.
	namespace = namespace or _G
	for k, v in pairs(self) do
		if not self_privateSymbol[k] then
			namespace[k] = namespace[k] or v
		end
	end
end

function WoWAPI:Fire(event)
	local lib = self.LibStub("AceAddon-3.0")
	if lib then
		lib:Fire(event)
	end
end

--[[--------------------------------------------------------------------
	LoadAddOnFile() dispatches to the proper method to load the file
	based on the file extension.
--]]--------------------------------------------------------------------
function WoWAPI:LoadAddonFile(filename, directory, verbose)
	local s = directory and (directory .. filename) or filename
	directory, filename = strmatch(s, "^(.+/)([^/]+[.][%w]+)$")
	if not directory then
		filename = s
	end
	if strfind(filename, "[.]lua$") then
		return self:LoadLua(filename, directory, verbose)
	elseif strfind(filename, "[.]toc$") then
		return self:LoadTOC(filename, directory, verbose)
	elseif strfind(filename, "[.]xml$") then
		return self:LoadXML(filename, directory, verbose)
	end
end

--[[--------------------------------------------------------------------
	LoadAddonFile() does the equivalent of dofile(), but munges the WoW
	addon file line that uses ... to get the file arguments.
--]]--------------------------------------------------------------------
function WoWAPI:LoadLua(filename, directory, verbose)
	if directory then
		filename = directory .. filename
	end
	if verbose then
		print(format("Loading Lua: %s", filename))
	end

	local ok = FileExists(filename, nil, verbose)
	if ok then
		local list = {}
		for line in io.lines(filename) do
			local varName = strmatch(line, "^local%s+([%w_]+)%s*,[%w%s_,]*=%s*[.][.][.]%s*$")
			if varName then
				line = format("local %s = %q", varName, self_state.addonName)
			end
			table.insert(list, line)
		end

		local fileString = table.concat(list, "\n")
		local func = loadstring(fileString)
		if func then
			func()
		else
			print(format("Error loading '%s'.", filename))
			ok = false
		end
	end
	return ok
end

--[[--------------------------------------------------------------------
	LoadTOC() loads all of the addon's files listed in the TOC file.
--]]--------------------------------------------------------------------
function WoWAPI:LoadTOC(filename, directory, verbose)
	if directory then
		filename = directory .. filename
	end
	if verbose then
		print(format("Loading TOC: %s", filename))
	end

	local ok = FileExists(filename, nil, verbose)
	if ok then
		local list = {}
		for line in io.lines(filename) do
			line = gsub(line, "\\", "/")
			local t = {}
			t.directory, t.file = strmatch(line, "^([^#]+/)([^/]+[.][%w]+)$")
			if t.directory then
				if directory then
					t.directory = directory .. t.directory
				end
			else
				t.directory = directory
				t.file = strmatch(line, "^[%w_]+[.][%w]+$")
			end
			if t.file then
				table.insert(list, t)
			end
		end
		for _, t in ipairs(list) do
			if strfind(t.file, "[.]lua$") then
				ok = ok and self:LoadLua(t.file, t.directory, verbose)
			elseif strfind(t.file, "[.]xml$") then
				ok = ok and self:LoadXML(t.file, t.directory, verbose)
			end
			if not ok then
				break
			end
		end
	end
	return ok
end

--[[--------------------------------------------------------------------
	LoadXML() loads all of the addon's Lua files listed in the XML file.
--]]--------------------------------------------------------------------
function WoWAPI:LoadXML(filename, directory, verbose)
	if directory then
		filename = directory .. filename
	end
	if verbose then
		print(format("Loading XML: %s", filename))
	end

	local ok = FileExists(filename, nil, verbose)
	if ok then
		local list = {}
		for line in io.lines(filename) do
			local s = strmatch(line, '<Script[%s]+file="([^"]+)"')
			if s then
				s = gsub(s, "\\", "/")
				local t = {}
				t.directory, t.file = strmatch(s, "^(.+/)([^/]+[.][%w]+)$")
				if t.directory then
					if directory then
						t.directory = directory .. t.directory
					end
				else
					t.directory = directory
					t.file = s
				end
				if t.file then
					table.insert(list, t)
				end
			end
		end
		for _, t in ipairs(list) do
			if FileExists(t.file, t.directory, verbose) then
				if strfind(t.file, "[.]lua$") then
					ok = ok and self:LoadLua(t.file, t.directory, verbose)
					if not ok then
						break
					end
				end
			end
		end
	end
	return ok
end
--</public-static-methods>
