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

--<public-static-properties>
OvalePool.name = "OvalePool"
OvalePool.pool = nil
OvalePool.size = 0
OvalePool.unused = 0
--</public-static-properties>

--<public-static-methods>
function OvalePool:NewPool(name)
	obj = { name = name, pool = {}, size = 0, unused = 0 }
	setmetatable(obj, { __index = self })
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
	wipe(item)
	tinsert(self.pool, item)
	self.unused = self.unused + 1
end

function OvalePool:Drain()
	assert(self.pool)
	while true do
		if not tremove(self.pool) then
			break
		end
	end
	self.size = self.size - self.unused
	self.unused = 0
end

function OvalePool:Debug()
	Ovale:FormatPrint("Pool %s has size %d with %d item(s).", self.name, self.size, self.unused)
end
--</public-static-methods>
