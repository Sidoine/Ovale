--[[--------------------------------------------------------------------
    Copyright (C) 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

--[[
	Every time a new function is entered and exited, debugprofilestop() is called and the time between
	the two timestamps is calculated and attributed to that function.
--]]

local OVALE, Ovale = ...
local OvaleProfiler = Ovale:NewModule("OvaleProfiler")
Ovale.OvaleProfiler = OvaleProfiler

--<private-static-properties>
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = Ovale.L
local LibTextDump = LibStub("LibTextDump-1.0")
local OvaleOptions = Ovale.OvaleOptions

local debugprofilestop = debugprofilestop
local format = string.format
local ipairs = ipairs
local next = next
local pairs = pairs
local tconcat = table.concat
local tinsert = table.insert
local tsort = table.sort
local wipe = wipe
local API_GetTime = GetTime

local self_timestamp = debugprofilestop()
local self_stack = {}
local self_stackSize = 0
local self_timeSpent = {}
local self_timesInvoked = {}

-- LibTextDump-1.0 object for profiling output.
local self_profilingOutput = nil

do
	local actions = {
		profiling = {
			name = L["Profiling"],
			type = "execute",
			func = function()
				local appName = OvaleProfiler:GetName()
				AceConfigDialog:SetDefaultSize(appName, 800, 550)
				AceConfigDialog:Open(appName)
			end,
		},
	}
	-- Insert actions into OvaleOptions.
	for k, v in pairs(actions) do
		OvaleOptions.options.args.actions.args[k] = v
	end
	-- Add a global data type for debug options.
	OvaleOptions.defaultDB.global = OvaleOptions.defaultDB.global or {}
	OvaleOptions.defaultDB.global.profiler = {}
	OvaleOptions:RegisterOptions(OvaleProfiler)
end
--</private-static-properties>

--<public-static-properties>
OvaleProfiler.options = {
	name = OVALE .. " " .. L["Profiling"],
	type = "group",
	args = {
		profiling = {
			name = L["Profiling"],
			type = "group",
			args = {
				modules = {
					name = L["Modules"],
					type = "group",
					inline = true,
					order = 10,
					args = {},
					get = function(info)
						local name = info[#info]
						local value = Ovale.db.global.profiler[name]
						return (value ~= nil)
					end,
					set = function(info, value)
						value = value or nil
						local name = info[#info]
						Ovale.db.global.profiler[name] = value
						if value then
							OvaleProfiler:EnableProfiling(name)
						else
							OvaleProfiler:DisableProfiling(name)
						end
					end,
				},
				reset = {
					name = L["Reset"],
					desc = L["Reset the profiling statistics."],
					type = "execute",
					order = 20,
					func = function() OvaleProfiler:ResetProfiling() end,
				},
				show = {
					name = L["Show"],
					desc = L["Show the profiling statistics."],
					type = "execute",
					order = 30,
					func = function()
						self_profilingOutput:Clear()
						local s = OvaleProfiler:GetProfilingInfo()
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
--</public-static-properties>

--<private-static-methods>
local function DoNothing()
	-- no-op
end

local function StartProfiling(_, tag)
	local newTimestamp = debugprofilestop()

	-- Attribute the time spent up to this call to the previous function.
	if self_stackSize > 0 then
		local delta = newTimestamp - self_timestamp
		local previous = self_stack[self_stackSize]
		local timeSpent = self_timeSpent[previous] or 0
		timeSpent = timeSpent + delta
		self_timeSpent[previous] = timeSpent
	end

	-- Add the current function to the call stack.
	self_timestamp = newTimestamp
	self_stackSize = self_stackSize + 1
	self_stack[self_stackSize] = tag
	do
		local timesInvoked = self_timesInvoked[tag] or 0
		timesInvoked = timesInvoked + 1
		self_timesInvoked[tag] = timesInvoked
	end
end

local function StopProfiling(_, tag)
	if self_stackSize > 0 then
		local currentTag = self_stack[self_stackSize]
		if currentTag == tag then
			local newTimestamp = debugprofilestop()
			local delta = newTimestamp - self_timestamp
			local timeSpent = self_timeSpent[currentTag] or 0
			timeSpent = timeSpent + delta
			self_timeSpent[currentTag] = timeSpent
			self_timestamp = newTimestamp
			self_stackSize = self_stackSize - 1
		end
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleProfiler:OnInitialize()
	local appName = self:GetName()
	AceConfig:RegisterOptionsTable(appName, self.options)
	AceConfigDialog:AddToBlizOptions(appName, L["Profiling"], OVALE)
end

function OvaleProfiler:OnEnable()
	if not self_profilingOutput then
		self_profilingOutput = LibTextDump:New(OVALE .. " - " .. L["Profiling"], 750, 500)
	end
end

function OvaleProfiler:OnDisable()
	self_profilingOutput:Clear()
end

function OvaleProfiler:RegisterProfiling(addon, name)
	name = name or addon:GetName()
	self.options.args.profiling.args.modules.args[name] = {
		name = name,
		desc = format(L["Enable profiling for the %s module."], name),
		type = "toggle",
	}
	self:DisableProfiling(name)
end

function OvaleProfiler:EnableProfiling(name)
	local addon = Ovale[name]
	if addon then
		addon.StartProfiling = StartProfiling
		addon.StopProfiling = StopProfiling
	end
end

function OvaleProfiler:DisableProfiling(name)
	local addon = Ovale[name]
	if addon then
		addon.StartProfiling = DoNothing
		addon.StopProfiling = DoNothing
	end
end

function OvaleProfiler:ResetProfiling()
	for tag in pairs(self_timeSpent) do
		self_timeSpent[tag] = nil
	end
	for tag in pairs(self_timesInvoked) do
		self_timesInvoked[tag] = nil
	end
end

do
	local array = {}

	function OvaleProfiler:GetProfilingInfo()
		if next(self_timeSpent) then
			-- Calculate the width needed to print out the times invoked.
			local width = 1
			do
				local tenPower = 10
				for _, timesInvoked in pairs(self_timesInvoked) do
					while timesInvoked > tenPower do
						width = width + 1
						tenPower = tenPower * 10
					end
				end
			end

			wipe(array)
			local formatString = format("    %%08.3fms: %%0%dd (%%05f) x %%s", width)
			for tag, timeSpent in pairs(self_timeSpent) do
				local timesInvoked = self_timesInvoked[tag]
				tinsert(array, format(formatString, timeSpent, timesInvoked, timeSpent / timesInvoked, tag))
			end
			if next(array) then
				tsort(array)
				local now = API_GetTime()
				tinsert(array, 1, format("Profiling statistics at %f:", now))
				return tconcat(array, "\n")
			end
		end
	end
end

function OvaleProfiler:DebuggingInfo()
	Ovale:Print("Profiler stack size = %d", self_stackSize)
	local index = self_stackSize
	while index > 0 and self_stackSize - index < 10 do
		local tag = self_stack[index]
		Ovale:Print("    [%d] %s", index, tag)
		index = index - 1
	end
end
--</public-static-methods>
