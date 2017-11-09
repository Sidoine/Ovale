local _addonName, _addon = ...

define(_addonName, _addon, "index", {}, function (__exports, addon)

local getActionInfo = {}
local API_GetActionInfo = GetActionInfo
local function TsGetActionInfo(slot)
	local actionType, id, subType = API_GetActionInfo(slot)
	getActionInfo.actionType = actionType
	getActionInfo.id = id
	getActionInfo.subType = subType
	return getActionInfo
end

local getMacroItem = {}
local API_GetMacroItem = GetMacroItem
local function TsGetMacroItem(macro)
	local item, link = API_GetMacroItem
	getMacroItem.item = item
	getMacroItem.link = link
	return getMacroItem
end

local getMacroSpell = {}
local API_GetMacroSpell = GetMacroSpell
local function TsGetMacroSpell(macro)
	local name, rank, id = API_GetMacroSpell(macro)
	getMacroSpell.name = name
	getMacroSpell.rank = rank
	getMacroSpell.id = id
	return getMacroSpell
end

local API_strmatch = strmatch
local function TsStrMatch(string, pattern, initpos)
	local ret = {strmatch(string, pattern, initpos)}
	return ret
end

local API_gmatch = gmatch
local function Tsgmatch(string, pattern)

end

local getSpellInfo = {}
local API_GetSpellInfo = GetSpellInfo
local function TsGetSpellInfo(id)
	local name, rank, fileId, castTime, minRange, maxRange, spellId = GetSpellInfo(id)
	getSpellInfo.name = name;
	getSpellInfo.rank = rank;
	getSpellInfo.fileId = fileId;
	getSpellInfo.castTime = castTime;
	getSpellInfo.minRange = minRange;
	getSpellInfo.maxRange = maxRange;
	getSpellInfo.spellId = spellId
	return getSpellInfo;
end

local typeof = function(x)
	local t = type(x)
	if t == 'table' then return 'object'
	else return t; end
end

return {
	GetActionInfo = TsGetActionInfo,
	GetActionText = GetActionText,
	GetBindingKey = GetBindingKey,
	GetBonusBarIndex = GetBonusBarIndex,
	GetMacroItem = TsGetMacroItem,
	GetMacroSpell = TsGetMacroSpell,
	GetSpellInfo = TsGetSpellInfo,
	GetTime = GetTime,
	
	assert = assert,
	debugprofilestop = debugprofilestop,
	format = format,
	gmatch = Tsgmatch,
	gsub = gsub,
	INFINITY = math.huge,
	ipairs = ipairs,
	len = function(table) return #table end,
	next = next,
	print = print,
	setmetatable = setmetatable,
	sort = sort,
	strlen = strlen,
	strmatch = TsStrMatch, 
	strmatch = strmatch,
	strupper = strupper,
	tconcat = table.concat,
	tinsert = tinsert,
	tonumber = tonumber,
	tostring = tostring,
	tremove = tremove,
	type = typeof,
	wipe = wipe,

	DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME,
	InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
}

end