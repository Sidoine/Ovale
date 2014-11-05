--[[--------------------------------------------------------------------
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]----------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleDebug = Ovale:NewModule("OvaleDebug", "AceTimer-3.0")
Ovale.OvaleDebug = OvaleDebug

--<private-static-properties>
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = Ovale.L
local LibTextDump = LibStub("LibTextDump-1.0")
local OvaleOptions = Ovale.OvaleOptions

-- Forward declarations for module dependencies.
local Profiler = nil

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

-- Flag for whether profiling is enabled.
local self_isProfilingEnabled = false
-- LibTextDump-1.0 object for profiling output.
local self_profilingOutput = nil

-- Flags used by debugging print functions.
-- If "bug" flag is set, then the next frame refresh is traced.
local self_bug = false
-- If "traced" flag is set, then the public "trace" property is toggled before the next frame refresh.
local self_traced = false
-- LibTextDump-1.0 object for output from Log() or Logf() methods.
local self_traceLog = nil
-- Maximum length of the trace log.
local OVALE_TRACELOG_MAXLINES = 4096	-- 2^14

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
OvaleDebug.options = {
	name = "Debug",
	type = "group",
	args = {
		toggles = {
			name = L["Options"],
			type = "group",
			order = 10,
			args = {},
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
						self_traceLog:Clear()
						OvaleDebug.trace = true
						OvaleDebug:Logf("=== Trace @%f", API_GetTime())
						OvaleDebug:ScheduleTimer("DisplayTraceLog", 0.5)
					end,
				},
				traceLog = {
					order = 20,
					type = "execute",
					name = L["Show Trace Log"],
					func = function()
						OvaleDebug:DisplayTraceLog()
					end,
				},
				traceSpellId = {
					order = 30,
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
		profiling = {
			name = L["Profiling"],
			type = "group",
			order = 30,
			args = {
				enable = {
					name = L["Enable"],
					desc = L["Enables gathering profiling statistics."],
					type = "toggle",
					width = "full",
					order = 10,
					get = function(info) return self_isProfilingEnabled end,
					set = function(info, value)
						if self_isProfilingEnabled then
							Profiler:Disable()
							self_isProfilingEnabled = false
						else
							Profiler:Enable()
							self_isProfilingEnabled = true
						end
					end,
				},
				reset = {
					name = L["Reset"],
					desc = L["Reset the profiling statistics."],
					type = "execute",
					order = 20,
					func = function() Profiler:Reset() end,
				},
				show = {
					name = L["Show"],
					desc = L["Show the profiling statistics."],
					type = "execute",
					order = 30,
					func = function()
						self_profilingOutput:Clear()
						local s = Profiler:Info()
						if s then
							self_profilingOutput:AddLine(s)
							self_profilingOutput:Display()
						end
					end,
				},
			},
		},
	},
}

-- Flag to activate tracing the function calls for the next frame refresh.
OvaleDebug.trace = false
--</public-static-properties>

--<public-static-methods>
function OvaleDebug:OnInitialize()
	-- Resolve module dependencies.
	Profiler = Ovale.Profiler

	local appName = self:GetName()
	AceConfig:RegisterOptionsTable(appName, self.options)
	AceConfigDialog:AddToBlizOptions(appName, L["Debug"], OVALE)
end

function OvaleDebug:OnEnable()
	self_profilingOutput = LibTextDump:New(OVALE .. " - " .. L["Profiling"], 750, 500)
	self_traceLog = LibTextDump:New(OVALE .. " - " .. L["Trace Log"], 750, 500)
end

function OvaleDebug:RegisterDebugOption(option, name, description)
	self.options.args.toggles.args[option] = {
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
		local N = self_traceLog:Lines()
		if N < OVALE_TRACELOG_MAXLINES - 1 then
			local output = { ... }
			self_traceLog:AddLine(tconcat(output, "\t"))
		elseif N == OVALE_TRACELOG_MAXLINES - 1 then
			self_traceLog:AddLine("WARNING: Maximum length of trace log has been reached.")
		end
	end
end

function OvaleDebug:Logf(...)
	if self.trace then
		local N = self_traceLog:Lines()
		if N < OVALE_TRACELOG_MAXLINES - 1 then
			self_traceLog:AddLine(Ovale:Format(...))
		elseif N == OVALE_TRACELOG_MAXLINES - 1 then
			self_traceLog:AddLine("WARNING: Maximum length of trace log has been reached.")
		end
	end
end

function OvaleDebug:DisplayTraceLog()
	if self_traceLog:Lines() == 0 then
		self_traceLog:AddLine("Trace log is empty.")
	end
	self_traceLog:Display()
end
--</public-static-methods>
