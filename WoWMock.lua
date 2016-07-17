--[[--------------------------------------------------------------------
    Copyright (c) 2013, 2014 Johnny C. Lam.

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation files
    (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge,
    publish, distribute, sublicense, and/or sell copies of the Software,
    and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
    BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
    ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
--]]--------------------------------------------------------------------

--[[--------------------------------------------------------------------
	This file implements parts of the WoW API for development and
	unit-testing.

	This file is not meant to be loaded into the addon.  It should be
	used only outside of the WoW environment, such as when loaded by a
	standalone Lua 5.1 interpreter.
--]]--------------------------------------------------------------------

-- Globally-accessible module table.
-- GLOBALS: WoWMock
WoWMock = {}

--<private-static-properties>
local _G = _G
local getmetatable = getmetatable
local io = io
local ipairs = ipairs
local loadstring = loadstring
local next = next
local pairs = pairs
local print = print
local rawget = rawget
local rawset = rawset
local select = select
local setfenv = setfenv
local setmetatable = setmetatable
local string = string
local table = table
local tostring = tostring
local type = type
local unpack = unpack

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

-- Forward declaration of LibStub.
local LibStub = nil

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
		local mod = lib:NewAddon(string.format("%s_%s", addon.name, name))
		mod.moduleName = name
		-- Mix in default module prototype
		if addon.modulePrototype then
			for k, v in pairs(addon.modulePrototype) do
				mod[k] = v
			end
		end
		-- Embed methods from named libraries.
		for _, libName in ipairs(args) do
			local library = LibStub(libName)
			if library then
				for k, v in pairs(library) do
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

	lib.GetAddon = function(library, name)
		library.addons = library.addons or {}
		return library.addons[name]
	end

	lib.Fire = function(event, ...)
		for _, addon in ipairs(lib.initializationQueue) do
			if event == "ADDON_LOADED" and addon.OnInitialize then
				--print("Firing", event, addon.name)
				addon:OnInitialize()
			elseif event == "PLAYER_LOGIN" and addon.OnEnable then
				--print("Firing", event, addon.name)
				addon:OnEnable()
			elseif addon.SendMessage then
				addon:SendMessage(event, ...)
			end
		end
	end

	lib.IterateAddons = function(library)
		return pairs(library.addons)
	end

	lib.NewAddon = function(library, name, ...)
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
			local library = LibStub(libName)
			if library then
				for k, v in pairs(library) do
					addon[k] = v
				end
			end
		end
		addon.name = name
		library.addons = library.addons or {}
		library.addons[name] = addon
		lib.initializationQueue[#lib.initializationQueue + 1] = addon
		return addon
	end
end

-- AceComm-3.0-9A-Fa-f
local AceComm = nil
do
	local lib = {}
	AceComm = lib
	lib.RegisterComm = DoNothing
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

	lib.Print = function(library, ...)
		print(...)
	end

	lib.Printf = function(library, ...)
		print(string.format(...))
	end
end

-- AceDB-3.0
local AceDB = nil
do
	local lib = {}
	AceDB = lib

	lib.New = function(library, name, template)
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

	lib.RegisterEvent = function(library, event, handler, arg)
		eventHandler[library] = eventHandler[library] or {}
		eventHandler[library][event] = { handler, arg }
	end

	lib.RegisterMessage = lib.RegisterEvent

	lib.SendMessage = function(library, event, ...)
		local handler, arg
		local tbl = eventHandler[library] and eventHandler[library][event]
		if tbl then
			handler, arg = tbl[1], tbl[2]
			if type(handler) == "string" then
				handler = library[handler]
				arg = library
			end
		else
			handler = library[event]
			arg = library
		end
		if handler then
			--print("Firing", event, library.name)
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

	lib.Create = function(library, widgetType)
		local constructor = widgetFactory[widgetType]
		if constructor then
			return constructor()
		end
	end

	lib.RegisterAsContainer = function(library, widget)
		container[widget] = true
		widget.AddChild = DoNothing
		widget.ReleaseChildren = DoNothing
	end

	lib.RegisterWidgetType = function(library, name, constructor, version)
		widgetFactory[name] = constructor
	end
end

-- AceLocale-3.0
local AceLocale = nil
do
	local lib = {}
	AceLocale = lib

	lib.GetLocale = function(library, name)
		local L
		if library.locale and library.locale[name] then
			L = library.locale[name]
		else
			L = library:NewLocale(name, nil)
		end
		return L
	end

	lib.NewLocale = function(library, name, locale)
		local L = setmetatable({}, KeysAreMissingValuesMetatable)
		library.locale = library.locale or {}
		library.locale[name] = L
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

	lib.New = function(library, obj)
		obj.Fire = library.Fire
		return obj
	end

	lib.Fire = function(library, ...) end
end

-- LibBabble-CreatureType-3.0
local LibBabbleCreatureType = nil
do
	local lib = {}
	LibBabbleCreatureType = lib

	lib.GetLookupTable = function(library)
		local tbl = library.lookupTable or setmetatable({}, KeysAreMissingValuesMetatable)
		library.lookupTable = tbl
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
do
	local lib = {}
	LibStub = lib
	lib.libs = {}
	lib.minors = {}
	lib.minor = 1

	lib.libs = {
		["AceAddon-3.0"] = AceAddon,
		["AceComm-3.0"] = AceComm,
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
		__call = function(library, name, flag)
			return library:GetLibrary(name, flag)
		end,
	}

	lib.GetLibrary = function(library, name, flag)
		return library.library[name]
	end

	lib.NewLibrary = function(library, name, major, minor)
		local newLib = {}
		library.library[name] = newLib
		return newLib
	end

	setmetatable(lib, mt)
end
--</private-static-properties>

--<public-static-properties>
--[[----------------------
	FrameXML/ChatFrame
--]]----------------------

WoWMock.DEFAULT_CHAT_FRAME = {
	AddMessage = function(frame, text, red, green, blue, alpha)
		-- Strip out color UI escape sequences.
		text = string.gsub(text, "|c[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]", "")
		text = string.gsub(text, "|r", "")
		print(text)
	end
}

--[[----------------------
	FrameXML/Constants
--]]----------------------

-- Inventory slots
WoWMock.INVSLOT_AMMO		= 0
WoWMock.INVSLOT_HEAD		= 1
WoWMock.INVSLOT_NECK		= 2
WoWMock.INVSLOT_SHOULDER	= 3
WoWMock.INVSLOT_BODY		= 4
WoWMock.INVSLOT_CHEST		= 5
WoWMock.INVSLOT_WAIST		= 6
WoWMock.INVSLOT_LEGS		= 7
WoWMock.INVSLOT_FEET		= 8
WoWMock.INVSLOT_WRIST		= 9
WoWMock.INVSLOT_HAND		= 10
WoWMock.INVSLOT_FINGER1		= 11
WoWMock.INVSLOT_FINGER2		= 12
WoWMock.INVSLOT_TRINKET1	= 13
WoWMock.INVSLOT_TRINKET2	= 14
WoWMock.INVSLOT_BACK		= 15
WoWMock.INVSLOT_MAINHAND	= 16
WoWMock.INVSLOT_OFFHAND		= 17
WoWMock.INVSLOT_RANGED		= 18
WoWMock.INVSLOT_TABARD		= 19
WoWMock.INVSLOT_FIRST_EQUIPPED = WoWMock.INVSLOT_HEAD
WoWMock.INVSLOT_LAST_EQUIPPED = WoWMock.INVSLOT_TABARD

-- Power Types
WoWMock.SPELL_POWER_MANA			= 0
WoWMock.SPELL_POWER_RAGE			= 1
WoWMock.SPELL_POWER_FOCUS			= 2
WoWMock.SPELL_POWER_ENERGY			= 3
--WoWMock.SPELL_POWER_CHI			= 4		-- This is obsolete now.
WoWMock.SPELL_POWER_RUNES			= 5
WoWMock.SPELL_POWER_RUNIC_POWER		= 6
WoWMock.SPELL_POWER_SOUL_SHARDS		= 7
WoWMock.SPELL_POWER_ECLIPSE			= 8
WoWMock.SPELL_POWER_HOLY_POWER		= 9
WoWMock.SPELL_POWER_ALTERNATE_POWER	= 10
WoWMock.SPELL_POWER_DARK_FORCE		= 11
WoWMock.SPELL_POWER_CHI				= 12
WoWMock.SPELL_POWER_SHADOW_ORBS		= 13
WoWMock.SPELL_POWER_BURNING_EMBERS	= 14
WoWMock.SPELL_POWER_DEMONIC_FURY	= 15

WoWMock.RAID_CLASS_COLORS = {
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

WoWMock.ITEM_LEVEL = "Item Level %d"

--[[---------------------------
	FrameXML/SpellBookFrame
--]]---------------------------

WoWMock.BOOKTYPE_SPELL = "spell"
WoWMock.BOOKTYPE_PET = "pet"

--[[----------------------------
	FrameXML/TalentFrameBase
--]]----------------------------

WoWMock.MAX_TALENT_TIERS = 7
WoWMock.NUM_TALENT_COLUMNS = 3

--[[--------------------------------------------------------------------
	debugprofilestop() is a non-standard Lua function that returns the
	current time in milliseconds.

	This is a trivial implementation to just get the Profiler module
	working.
--]]--------------------------------------------------------------------
WoWMock.debugprofilestop = ZeroFunction

WoWMock.hooksecurefunc = function(table, functionName, hookFunc)
end

--[[--------------------------------------------------------------------
	strjoin() is a non-standard Lua function that joins a list of
	strings together using the given separator.
--]]--------------------------------------------------------------------
WoWMock.strjoin = function(sep, ...)
	local t = { ... }
	return table.concat(t, sep)
end

WoWMock.strmatch = string.match

--[[--------------------------------------------------------------------
	strsplit() is a non-standard Lua function that splits a string and
	returns multiple return values for each substring delimited by the
	named delimiter character.

	This implementation is taken verbatim from:
		http://lua-users.org/wiki/SplitJoin
--]]--------------------------------------------------------------------
WoWMock.strsplit = function(delim, str, maxNb)
	-- Fix up '.' character class.
	delim = string.gsub(delim, "%.", "%%.")
	-- Eliminate bad cases...
	if string.find(str, delim) == nil then
		return str
	end
	if maxNb == nil or maxNb < 1 then
		maxNb = 0    -- No limit
	end
	local result = {}
	local pat = "(.-)" .. delim .. "()"
	local nb = 0
	local lastPos
	for part, pos in string.gfind(str, pat) do
		nb = nb + 1
		result[nb] = part
		lastPos = pos
		if nb == maxNb then break end
	end
	-- Handle the last field
	if nb ~= maxNb then
		result[nb + 1] = string.sub(str, lastPos)
	end
	return unpack(result)
end

--[[--------------------------------------------------------------------
	tostringall() is a non-standard Lua function that returns a list of
	each argument converted to a string.
--]]--------------------------------------------------------------------
WoWMock.tostringall = function(...)
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
WoWMock.wipe = function(t)
	for k in pairs(t) do
		t[k] = nil
	end
end

WoWMock.C_Timer = {
	After = function(duration, callback) end	
}

--[[-------------------------------------------------
	Fake Blizzard API functions for unit testing.
--]]-------------------------------------------------

WoWMock.mock = {}

WoWMock.mock["CreateFrame"] = [[
	do
		local function DoNothing() end
		local function ZeroFunction() return 0 end

		function CreateFrame(...)
			local frame = {
				ClearAllPoints = DoNothing,
				CreateFontString = function(...) return CreateFrame() end,
				CreateTexture = function(...) return CreateFrame() end,
				EnableMouse = DoNothing,
				GetScript = function(event) return nil end,
				Hide = DoNothing,
				IsVisible = DoNothing,
				NumLines = ZeroFunction,
				SetAllPoints = DoNothing,
				SetAlpha = DoNothing,
				SetFrameStrata = DoNothing,
				SetHeight = DoNothing,
				SetInventoryItem = DoNothing,
				SetJustifyH = DoNothing,
				SetJustifyV = DoNothing,
				SetMovable = DoNothing,
				SetOwner = DoNothing,
				SetPoint = DoNothing,
				SetScript = DoNothing,
				SetText = DoNothing,
				SetTexture = DoNothing,
				SetWidth = DoNothing,
				RegisterEvent = DoNothing,
				UnregisterAllEvents = DoNothing
			}
			return frame
		end
	end
]]

WoWMock.mock["GetActiveSpecGroup"] = [[
	function GetActiveSpecGroup()
		-- Always in the primary specialization.
		return 1
	end
]]

WoWMock.mock["GetActionInfo"] = [[
	function GetActionInfo(slot)
		-- Action bar is always empty.
		return nil
	end
]]

WoWMock.mock["GetAuctionItemSubClasses"] = [[
	function GetAuctionItemSubClasses(classIndex)
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
]]

WoWMock.mock["GetBindingKey"] = [[
	function GetBindingKey(name)
		-- No keybinds are assigned.
		return nil
	end
]]

WoWMock.mock["GetBonusBarIndex"] = [[
	function GetBonusBarIndex()
		return 8
	end
]]

WoWMock.mock["GetBuildInfo"] = [[
	function GetBuildInfo()
		return "7.0.0", "12345", "Oct 25 2020", 70000
	end
]]

WoWMock.mock["GetCurrentRegion"] = [[
	function GetCurrentRegion()
		return 3
	end
]]

WoWMock.mock["GetGlyphSocketInfo"] = [[
	function GetGlyphSocketInfo(socket, talentGroup)
		-- No glyphs.
		return nil
	end
]]

WoWMock.mock["GetInventoryItemGems"] = [[
	function GetInventoryItemGems(slot)
		-- Player is always completely un-gemmed.
		return nil
	end
]]

WoWMock.mock["GetInventoryItemID"] = [[
	function GetInventoryItemID(unitId, slot)
		-- All units are naked.
		return nil
	end
]]

WoWMock.mock["GetItemInfo"] = [[
	function GetItemInfo(item)
		if type(item) == "number" then
			item = string.format("Item Name Of %d", item)
		end
		return item
	end
]]

WoWMock.mock["GetLocale"] = [[
	function GetLocale()
		return "enUS"
	end
]]

WoWMock.mock["GetNumGlyphSockets"] = [[
	function GetNumGlyphSockets()
		-- 3 x Major + 3 x Minor
		return 6
	end
]]

WoWMock.mock["GetNumShapeshiftForms"] = ZeroFunction

WoWMock.mock["GetPowerRegen"] = [[
	function GetPowerRegen()
		return 0, 0
	end
]]

WoWMock.mock["GetRealmName"] = [[
	function GetRealmName()
		return "Elune"
	end
]]

WoWMock.mock["GetRuneCooldown"] = [[
	function GetRuneCooldown(slot)
		-- The rune is always ready.
		return 0, 10, true
	end
]]

WoWMock.mock["GetRuneType"] = [[
	function GetRuneType(slot)
		-- Everything is a death rune.
		return 4
	end
]]

WoWMock.mock["GetShapeshiftForm"] = [[
	function GetShapeshiftForm()
		-- Always in humanoid form.
		return 0
	end
]]

WoWMock.mock["GetSpecialization"] = [[
	local WOWMOCK_CLASS_SPECIALIZATION = {
		DEATHKNIGHT = { blood = 1, frost = 2, unholy = 3 },
		DRUID = { balance = 1, feral = 2, guardian = 3, restoration = 4 },
		HUNTER = { beast_mastery = 1, marksmanship = 2, survival = 3 },
		MAGE = { arcane = 1, fire = 2, frost = 3 },
		MONK = { brewmaster = 1, mistweaver = 2, windwalker = 3 },
		PALADIN = { holy = 1, protection = 2, retribution = 3 },
		PRIEST = { discipline = 1, holy = 2, shadow = 3 },
		ROGUE = { assassination = 1, combat = 2, subtlety = 3 },
		SHAMAN = { elemental = 1, enhancement = 2, restoration = 3 },
		WARLOCK = { affliction = 1, demonology = 2, destruction = 3 },
		WARRIOR = { arms = 1, fury = 2, protection = 3 },
	}

	function GetSpecialization()
		local specialization
		local class = UnitClass()
		local wowMockSpec = WOWMOCK_CONFIG.specialization
		if wowMockSpec then
			if type(wowMockSpec) == "number" then
				specialization = wowMockSpec
			else
				specialization = WOWMOCK_CLASS_SPECIALIZATION[class][WOWMOCK_CONFIG.specialization]
			end
		end
		specialization = specialization or 1
		return specialization
	end
]]

WoWMock.mock["GetSpellInfo"] = [[
	function GetSpellInfo(spell)
		if type(spell) == "number" then
			spell = string.format("Spell Name of %d", spell)
		end
		return spell
	end
]]

WoWMock.mock["GetSpellTabInfo"] = [[
	function GetSpellTabInfo(index)
		-- No spells in the spellbook.
		return nil
	end
]]

WoWMock.mock["GetTalentInfo"] = [[
	function GetTalentInfo(row, column, activeTalentGroup)
		-- No talents.
		return 123, "A Talent", nil, 0, nil
	end
]]

WoWMock.mock["GetTime"] = [[
	function GetTime()
		return 1234
	end
]]

WoWMock.mock["HasPetSpells"] = [[
	function HasPetSpells()
		-- No pet spells.
		return false
	end
]]

WoWMock.mock["InterfaceOptions_AddCategory"] = [[
	function InterfaceOptions_AddCategory(category)
	end
]]

WoWMock.mock["RegisterAddonMessagePrefix"] = DoNothing
WoWMock.mock["RegisterStateDriver"] = DoNothing

WoWMock.UnitAura = function(unitId)
	-- No auras on any unit.
	return nil
end

WoWMock.mock["SlashCmdList"] = [[
	SlashCmdList = {}
]]

WoWMock.mock["UnitClass"] = [[
	function UnitClass()
		local class = WOWMOCK_CONFIG.class or "DEATHKNIGHT"
		return class, class
	end
]]

WoWMock.mock["UnitFactionGroup"] = [[
	function UnitFactionGroup(unitId)
		return "Horde", "Horde"
	end
]]

WoWMock.mock["UnitGUID"] = [[
	function UnitGUID(unitId)
		local guid = WOWMOCK_CONFIG.guid or 0
		return guid
	end
]]

WoWMock.mock["UnitLevel"] = [[
	function UnitLevel()
		local level = WOWMOCK_CONFIG.level or 100
		return level
	end
]]

WoWMock.mock["UnitName"] = [[
	function UnitName()
		local name = WOWMOCK_CONFIG.name or "AwesomePlayer"
		return name
	end
]]

WoWMock.mock["UnitRace"] = [[
	function UnitRace()
		return "Night Elf", "NightElf"
	end
]]

WoWMock.mock["UnitPower"] = [[
	function UnitPower(unitId, powerType)
		-- Always no resources on any unit.
		return 0
	end
]]

WoWMock.mock["UnitPowerMax"] = [[
	function UnitPowerMax(unitId, powerType)
		-- Resources are from 0 to 100.
		return 100
	end
]]

WoWMock.mock["UnitPowerType"] = [[
	function UnitPowerType(unitId)
		-- Every unit is a mana user.
		return WoWMock.SPELL_POWER_MANA, "MANA"
	end
]]

-- Unit stat functions for a naked toon.
WoWMock.GetCombatRating = ZeroFunction
WoWMock.GetCritChance = ZeroFunction
WoWMock.GetMastery = ZeroFunction
WoWMock.GetMasteryEffect = ZeroFunction
WoWMock.GetMeleeHaste = ZeroFunction
WoWMock.GetRangedCritChance = ZeroFunction
WoWMock.GetRangedHaste = ZeroFunction
WoWMock.GetSpellBonusDamage = ZeroFunction
WoWMock.GetSpellBonusHealing = ZeroFunction
WoWMock.GetSpellCritChance = ZeroFunction
WoWMock.UnitAttackPower = function(unitId) return 0, 0, 0 end
WoWMock.UnitAttackSpeed = function(unitId) return 0, 0 end
WoWMock.UnitDamage = function(unitId) return 0, 0, 0, 0, 0, 0, 0 end
WoWMock.UnitRangedAttackPower = WoWMock.UnitAttackPower
WoWMock.UnitSpellHaste = ZeroFunction
WoWMock.UnitStat = ZeroFunction

WoWMock.bit = {
	band = DoNothing,
	bor = DoNothing,
}

WoWMock.LibStub = LibStub
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
			print(string.format("Warning: '%s' not found.", filename))
		end
		return false
	end
end
--</private-static-methods>

--<public-static-methods>
-- Create a new sandbox environment.
function WoWMock:NewSandbox(config, mock)
	mock = mock or {}
	local sandbox = DeepCopy(mock)

	-- Save configuration to sandbox as "WOWMOCK_CONFIG" property.
	config = config or {}
	local WOWMOCK_CONFIG = DeepCopy(config)
	sandbox.WOWMOCK_CONFIG = WOWMOCK_CONFIG

	-- Redirect all direct references into _G into the sandbox instead.
	sandbox._G = sandbox

	-- Any missing symbols in the sandbox are inherited from the global environment.
	setmetatable(sandbox, { __index = _G })

	-- Export all of the WoWMock symbols into the sandbox, taking care not to
	-- overwrite explicitly defined mocks.
	for key, value in pairs(self) do
		if key == "NewSandbox" then
			-- skip
		elseif key == "mock" then
			for k, v in pairs(value) do
				if not rawget(sandbox, k) then
					if type(v) == "string" then
						--print("Loading symbol (loadstring)", k)
						local func = loadstring(v)
						setfenv(func, sandbox)
						func()
					elseif type(v) == "function" then
						--print("Loading symbol (function)", k)
						sandbox[k] = v
					end
				end
			end
		else
			--print("Loading symbol (direct)", key)
			if not rawget(sandbox, key) then
				sandbox[key] = DeepCopy(value)
			end
		end
	end

	-- Sandbox configuration defaults.
	if not WOWMOCK_CONFIG.addonName then
		sandbox:SetAddonName("Addon Name")
	end

	return sandbox
end

-- Set the name of the addon for all files.
function WoWMock:SetAddonName(name)
	self.WOWMOCK_CONFIG.addonName = name
end

-- Execute the given function within the sandbox environment.
function WoWMock:Execute(func)
	setfenv(func, self)
	return func()
end

-- Fire an event in the sandbox.
function WoWMock:Fire(event)
	local lib = self.LibStub("AceAddon-3.0")
	if lib then
		lib.Fire(event)
	end
end

--[[--------------------------------------------------------------------
	LoadAddOnFile() dispatches to the proper method to load the file
	based on the file extension.
--]]--------------------------------------------------------------------
function WoWMock:LoadAddonFile(filename, directory, verbose)
	local s = directory and (directory .. filename) or filename
	directory, filename = string.match(s, "^(.+/)([^/]+[.][%w]+)$")
	if not directory then
		filename = s
	end
	if string.find(filename, "[.]lua$") then
		return self:LoadLua(filename, directory, verbose)
	elseif string.find(filename, "[.]toc$") then
		return self:LoadTOC(filename, directory, verbose)
	elseif string.find(filename, "[.]xml$") then
		return self:LoadXML(filename, directory, verbose)
	end
end

--[[--------------------------------------------------------------------
	LoadAddonFile() does the equivalent of dofile(), but munges the WoW
	addon file line that uses ... to get the file arguments.
--]]--------------------------------------------------------------------
function WoWMock:LoadLua(filename, directory, verbose)
	local f = filename
	if directory then
		filename = directory .. filename
	end
	if verbose then
		print(string.format("Loading Lua: %s", filename))
	end

	local ok = FileExists(filename, nil, verbose)
	if ok then
		local list = { }
		for line in io.lines(filename) do
			local varName = string.match(line, "^local%s+([%w_]+)%s*,[%w%s_,]*=%s*[.][.][.]%s*$")
			if varName then
				line = string.format("local %s = %q", varName, self.WOWMOCK_CONFIG.addonName)
			end
			if (#list == 0) then
				line = '--[[' .. filename .. ']]' .. line
			end
			table.insert(list, line)
		end

		local fileString = table.concat(list, "\n")
		local func = loadstring(fileString)
		if func then
			setfenv(func, self)
			func()
		else
			print(string.format("Error loading '%s'.", filename))
			ok = false
		end
	end
	return ok
end

--[[--------------------------------------------------------------------
	LoadTOC() loads all of the addon's files listed in the TOC file.
--]]--------------------------------------------------------------------
function WoWMock:LoadTOC(filename, directory, verbose)
	local addonName = string.sub(filename, 1, -5)
	if directory then
		filename = directory .. filename
	end
	if verbose then
		print(string.format("Loading TOC: %s", filename))
	end

	local ok = FileExists(filename, nil, verbose)
	if ok then
		-- Set the addon name from the name of the TOC file.
		self:SetAddonName(addonName)

		local list = {}
		for line in io.lines(filename) do
			line = string.gsub(line, "\\", "/")
			local t = {}
			t.directory, t.file = string.match(line, "^([^#]+/)([^/]+[.][%w]+)$")
			if t.directory then
				if directory then
					t.directory = directory .. t.directory
				end
			else
				t.directory = directory
				t.file = string.match(line, "^[%w_]+[.][%w]+$")
			end
			if t.file then
				table.insert(list, t)
			end
		end
		for _, t in ipairs(list) do
			if string.find(t.file, "[.]lua$") then
				ok = ok and self:LoadLua(t.file, t.directory, verbose)
			elseif string.find(t.file, "[.]xml$") then
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
function WoWMock:LoadXML(filename, directory, verbose)
	if directory then
		filename = directory .. filename
	end
	if verbose then
		print(string.format("Loading XML: %s", filename))
	end

	local ok = FileExists(filename, nil, verbose)
	if ok then
		local list = {}
		for line in io.lines(filename) do
			local s = string.match(line, '<Script[%s]+file="([^"]+)"')
			if not s then
				 s = string.match(line, '<Include[%s]+file="([^"]+)"')
			end
			if s then
				s = string.gsub(s, "\\", "/")
				local t = {}
				t.directory, t.file = string.match(s, "^(.+/)([^/]+[.][%w]+)$")
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
				if string.find(t.file, "[.]lua$") then
					ok = ok and self:LoadLua(t.file, t.directory, verbose)
				elseif string.find(t.file, "[.]xml$") then
					ok = ok and self:LoadXML(t.file, t.directory, verbose)
				end
				if not ok then
					break
				end
			end
		end
	end
	return ok
end
--</public-static-methods>
