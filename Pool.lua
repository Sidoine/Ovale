--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- Simple resource pool.
local OVALE, Ovale = ...
local OvalePool = {}
Ovale.OvalePool = OvalePool

--<private-static-properties>
-- Profiling set-up.
local OvaleProfiler = Ovale.OvaleProfiler

local assert = assert
local setmetatable = setmetatable
local tinsert = table.insert
local tostring = tostring
local tremove = table.remove
local wipe = wipe

-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvalePool, "OvalePool")
--</private-static-properties>

--<public-static-properties>
OvalePool.name = "OvalePool"
OvalePool.pool = nil
OvalePool.size = 0
OvalePool.unused = 0
OvalePool.__index = OvalePool
--</public-static-properties>

--<public-static-methods>
do
	-- Class constructor
	setmetatable(OvalePool, { __call = function(self, ...) return self:NewPool(...) end })
end

function OvalePool:NewPool(name)
	name = name or self.name
	local obj = setmetatable({ name = name }, self)
	obj:Drain()
	return obj
end

function OvalePool:Get()
	OvalePool:StartProfiling(self.name)
	assert(self.pool)
	local item = tremove(self.pool)
	if item then
		self.unused = self.unused - 1
	else
		self.size = self.size + 1
		item = {}
	end
	OvalePool:StopProfiling(self.name)
	return item
end

function OvalePool:Release(item)
	OvalePool:StartProfiling(self.name)
	assert(self.pool)
	self:Clean(item)
	wipe(item)
	tinsert(self.pool, item)
	self.unused = self.unused + 1
	OvalePool:StopProfiling(self.name)
end

function OvalePool:Clean(item)
	-- virtual function; override as needed.
end

function OvalePool:Drain()
	OvalePool:StartProfiling(self.name)
	self.pool = {}
	self.size = self.size - self.unused
	self.unused = 0
	OvalePool:StopProfiling(self.name)
end

function OvalePool:DebuggingInfo()
	Ovale:Print("Pool %s has size %d with %d item(s).", tostring(self.name), self.size, self.unused)
end
--</public-static-methods>
