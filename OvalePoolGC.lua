--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- This module wraps the standard Lua garbage collector using the Pool interface.
local _, Ovale = ...
local OvalePoolGC = {}
Ovale.OvalePoolGC = OvalePoolGC

--<public-static-properties>
OvalePoolGC.name = "OvalePoolGC"
OvalePoolGC.pool = nil
OvalePoolGC.size = 0
OvalePoolGC.unused = 0
--</public-static-properties>

--<public-static-methods>
function OvalePoolGC:NewPool(name)
	obj = { name = name }
	setmetatable(obj, { __index = self })
	obj:Reset()
	return obj
end

function OvalePoolGC:Get()
	-- Keep running count of total number of tables allocated.
	self.size = self.size + 1
	return {}
end

-- The Release and Drain methods are no-ops.
function OvalePoolGC:Release(item) end
function OvalePoolGC:Drain() end

function OvalePoolGC:Reset()
	self.size = 0
	self.unused = 0
end

function OvalePoolGC:Debug()
	Ovale:FormatPrint("Pool %s has size %d.", self.name, self.size)
end
--</public-static-methods>
