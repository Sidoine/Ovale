--[[--------------------------------------------------------------------
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]----------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleDebug = Ovale:NewModule("OvaleDebug")
Ovale.OvaleDebug = OvaleDebug

--<private-static-properties>
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = Ovale.L
local OvaleOptions = Ovale.OvaleOptions

local gmatch = string.gmatch
local gsub = string.gsub
local next = next
local pairs = pairs
local select = select
local strlen = string.len
local tconcat = table.concat
local tonumber = tonumber
local type = type
local wipe = table.wipe
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime

-- Flags used by debugging print functions.
-- If "bug" flag is set, then the next frame refresh is traced.
local self_bug = false
-- If "traced" flag is set, then the public "trace" property is toggled before the next frame refresh.
local self_traced = false
-- Table of lines output using Log() or Logf() methods.
local self_traceLog = {}
-- Maximum length of the trace log.
local OVALE_TRACELOG_MAXLINES = 4096	-- 2^14

local self_options = {}
do
	local actions = {
		debug = {
			name = L["Debug"],
			type = "execute",
			func = function()
				local appName = OvaleDebug:GetName()
				AceConfigDialog:SetDefaultSize(appName, 800, 550)
				AceConfigDialog:Open(appName)
			end,
		},
	}
	-- Add a global data type for debug options.
	OvaleOptions.defaultDB.global = OvaleOptions.defaultDB.global or {}
	OvaleOptions.defaultDB.global.debug = {}
	-- Insert actions into OvaleOptions.
	for k, v in pairs(actions) do
		OvaleOptions.options.args.actions.args[k] = v
	end
end
--</private-static-properties>

--<public-static-properties>
-- Flag to activate tracing the function calls for the next frame refresh.
OvaleDebug.trace = false
--</public-static-properties>

--<public-static-methods>
function OvaleDebug:OnInitialize()
	self:CreateOptions()
end

function OvaleDebug:RegisterDebugOption(option, name, description)
	self_options[option] = {
		name = name,
		desc = description or name,
		type = "toggle",
	}
end

function OvaleDebug:ResetTrace()
	self.trace = false
	self_traced = false
	self_bug = false
end

function OvaleDebug:UpdateTrace()
	-- If trace flag is set here, then flag that we just traced one frame.
	if self.trace then
		self_traced = true
	end
	-- If there was a bug, then enable trace on the next frame.
	if self_bug then
		self.trace = true
	end
	-- Toggle trace flag so we don't endlessly trace successive frames.
	if self.trace and self_traced then
		self_traced = false
		self.trace = false
	end
end

function OvaleDebug:DebugPrint(flag, ...)
	local global = Ovale.db.global
	if global and global.debug and global.debug[flag] then
		Ovale:Print("[" .. flag .. "]", ...)
	end
end

function OvaleDebug:DebugPrintf(flag, ...)
	local global = Ovale.db.global
	if global and global.debug and global.debug[flag] then
		local addTimestamp = select(1, ...)
		if type(addTimestamp) == "boolean" or type(addTimestamp) == "nil" then
			if addTimestamp then
				local now = API_GetTime()
				Ovale:Printf("[%s] @%f %s", flag, now, Ovale:Format(select(2, ...)))
			else
				Ovale:Printf("[%s] %s", flag, Ovale:Format(select(2, ...)))
			end
		else
			Ovale:Printf("[%s] %s", flag, Ovale:Format(...))
		end
	end
end

function OvaleDebug:Error(...)
	Ovale:Print("Fatal error: ", ...)
	self_bug = true
end

function OvaleDebug:Errorf(...)
	Ovale:Printf("Fatal error: %s", Ovale:Format(...))
	self_bug = true
end

function OvaleDebug:Log(...)
	if self.trace then
		local N = #self_traceLog
		if N < OVALE_TRACELOG_MAXLINES - 1 then
			local output = { ... }
			self_traceLog[N + 1] = tconcat(output, "\t")
		elseif N == OVALE_TRACELOG_MAXLINES - 1 then
			self_traceLog[N + 1] = "WARNING: Maximum length of trace log has been reached."
		end
	end
end

function OvaleDebug:Logf(...)
	local N = #self_traceLog
	if self.trace then
		if N < OVALE_TRACELOG_MAXLINES - 1 then
			self_traceLog[N + 1] = Ovale:Format(...)
		elseif N == OVALE_TRACELOG_MAXLINES - 1 then
			self_traceLog[N + 1] = "WARNING: Maximum length of trace log has been reached."
		end
	end
end

function OvaleDebug:CreateOptions()
	local options = {
		name = "Debug",
		type = "group",
		args = {
			toggles = {
				name = L["Options"],
				type = "group",
				order = 10,
				args = self_options,
				get = function(info)
					local value = Ovale.db.global.debug[info[#info]]
					return (value ~= nil)
				end,
				set = function(info, value)
					value = value or nil
					Ovale.db.global.debug[info[#info]] = value
				end,
			},
			trace = {
				name = L["Trace"],
				type = "group",
				order = 20,
				args = {
					trace = {
						order = 10,
						type = "execute",
						name = L["Trace"],
						desc = L["Trace the next frame update."],
						func = function()
							wipe(self_traceLog)
							self.trace = true
							self:Logf("=== Trace @%f", API_GetTime())
						end,
					},
					traceSpellId = {
						order = 20,
						type = "input",
						name = L["Trace spellcast"],
						desc = L["Names or spell IDs of spellcasts to watch, separated by semicolons."],
						get = function(info)
							local OvaleFuture = Ovale.OvaleFuture
							if OvaleFuture then
								local t = OvaleFuture.traceSpellList or {}
								local s = ""
								for k, v in pairs(t) do
									if type(v) == "boolean" then
										if strlen(s) == 0 then
											s = k
										else
											s = s .. "; " .. k
										end
									end
								end
								return s
							else
								return ""
							end
						end,
						set = function(info, value)
							local OvaleFuture = Ovale.OvaleFuture
							if OvaleFuture then
								local t = {}
								for s in gmatch(value, "[^;]+") do
									-- strip leading and trailing whitespace
									s = gsub(s, "^%s*", "")
									s = gsub(s, "%s*$", "")
									if strlen(s) > 0 then
										local v = tonumber(s)
										if v then
											s = API_GetSpellInfo(v)
											if s then
												t[v] = true
												t[s] = v
											end
										else
											t[s] = true
										end
									end
								end
								if next(t) then
									OvaleFuture.traceSpellList = t
								else
									OvaleFuture.traceSpellList = nil
								end
							end
						end,
					},
				},
			},
			traceLog = {
				name = L["Trace Log"],
				type = "group",
				order = 30,
				args = {
					traceLog = {
						name = L["Trace Log"],
						type = "input",
						multiline = 25,
						width = "full",
						get = function()
							return tconcat(self_traceLog, "\n")
						end,
					},
				},
			},
		},
	}
	local appName = self:GetName()
	AceConfig:RegisterOptionsTable(appName, options)
	AceConfigDialog:AddToBlizOptions(appName, L["Debug"], OVALE)
end
--</public-static-methods>
