--[[--------------------------------------------------------------------
    Copyright (C) 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

--[[
	Every time a new function is entered and exited, debugprofilestop() is called and the time between
	the two timestamps is calculated and attributed to that function.
--]]

local _, Ovale = ...
local Profiler = {}
Ovale.Profiler = Profiler

--<private-static-properties>
local debugprofilestop = debugprofilestop
local format = string.format
local tinsert = table.insert
local tsort = table.sort
local API_GetTime = GetTime

local self_timestamp = debugprofilestop()
local self_stack = {}
local self_stackSize = 0
local self_timeSpent = {}
local self_timesInvoked = {}

-- Profiling methods collections, indexed by group.
local self_profiler = {}
--</private-static-properties>

--<private-static-methods>
local function DoNothing()
	-- no-op
end

local function StartProfiler(tag)
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

local function StopProfiler(tag)
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
function Profiler:RegisterProfilingGroup(group, enableFunction, disableFunction)
	local profiler = self_profiler[group] or {}
	profiler.Enable = enableFunction
	profiler.Disable = disableFunction
	self_profiler[group] = profiler
	self:Disable(group, false)
end

function Profiler:GetProfilingGroup(group)
	return self_profiler[group]
end

function Profiler:Enable(group, isVerbose)
	if group then
		local profiler = self_profiler[group]
		if profiler then
			if isVerbose then
				Ovale:FormatPrint("Profiling for %s is enabled.", group)
			end
			if profiler.Enable then
				profiler.Enable()
			end
			profiler.Start = StartProfiler
			profiler.Stop = StopProfiler
		end
	else
		for group, profiler in pairs(self_profiler) do
			if isVerbose then
				Ovale:FormatPrint("Profiling for %s is enabled.", group)
			end
			if profiler.Enable then
				profiler.Enable()
			end
			profiler.Start = StartProfiler
			profiler.Stop = StopProfiler
		end
	end
end

function Profiler:Disable(group, isVerbose)
	if group then
		local profiler = self_profiler[group]
		if profiler then
			if isVerbose then
				Ovale:FormatPrint("Profiling for %s is disabled.", group)
			end
			if profiler.Disable then
				profiler.Disable()
			end
			profiler.Start = DoNothing
			profiler.Stop = DoNothing
		end
	else
		for group, profiler in pairs(self_profiler) do
			if isVerbose then
				Ovale:FormatPrint("Profiling for %s is disabled.", group)
			end
			if profiler.Disable then
				profiler.Disable()
			end
			profiler.Start = DoNothing
			profiler.Stop = DoNothing
		end
	end
end

function Profiler:Reset()
	for tag in pairs(self_timeSpent) do
		self_timeSpent[tag] = nil
	end
	for tag in pairs(self_timesInvoked) do
		self_timesInvoked[tag] = nil
	end
end

do
	local array = {}

	function Profiler:Info()
		if next(self_timeSpent) then
			local now = API_GetTime()
			Ovale:FormatPrint("Profiling statistics at %f:", now)

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
				for _, v in ipairs(array) do
					Ovale:Print(v)
				end
			end
		end
	end
end

function Profiler:Wrap(group, tag, functionPtr)
	local profiler = self_profiler[group]
	local helper = function(...)
		profiler.Stop(tag)
		return ...
	end
	local wrapper = function(...)
		profiler.Start(tag)
		return helper(functionPtr(...))
	end
	return wrapper
end

function Profiler:Debug()
	Ovale:FormatPrint("Profiler stack size = %d", self_stackSize)
	local index = self_stackSize
	while index > 0 and self_stackSize - index < 10 do
		local tag = self_stack[index]
		Ovale:FormatPrint("    [%d] %s", index, tag)
		index = index - 1
	end
end
--</public-static-methods>
