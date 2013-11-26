--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- Simple resource pool.
local _, Ovale = ...
local OvalePool = {}
Ovale.OvalePool = OvalePool

--<private-static-properties>
local assert = assert
local setmetatable = setmetatable
local tinsert = table.insert
local tostring = tostring
local tremove = table.remove
local wipe = table.wipe
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
	assert(self.pool)
	local item = tremove(self.pool)
	if item then
		self.unused = self.unused - 1
	else
		self.size = self.size + 1
		item = {}
	end
	return item
end

function OvalePool:Release(item)
	assert(self.pool)
	self:Clean(item)
	wipe(item)
	tinsert(self.pool, item)
	self.unused = self.unused + 1
end

function OvalePool:GetReference(item)
	return item
end

function OvalePool:ReleaseReference(item)
	-- no-op
end

function OvalePool:Clean(item)
	-- virtual function; override as needed.
end

function OvalePool:Drain()
	self.pool = {}
	self.size = self.size - self.unused
	self.unused = 0
end

function OvalePool:Debug()
	Ovale:FormatPrint("Pool %s has size %d with %d item(s).", tostring(self.name), self.size, self.unused)
end
--</public-static-methods>
