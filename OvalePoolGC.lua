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

--<private-static-properties>
local setmetatable = setmetatable
local tostring = tostring
--</private-static-properties>

--<public-static-properties>
OvalePoolGC.name = "OvalePoolGC"
OvalePoolGC.size = 0
OvalePoolGC.__index = OvalePoolGC
--</public-static-properties>

--<private-static-methods>
do
	local function NewPool(...)
		local obj = setmetatable({ name = ... }, OvalePoolGC)
		obj:Reset()
		return obj
	end
	setmetatable(OvalePoolGC, { __call = function(_, ...) return NewPool(...) end })
end
--</private-static-methods>

--<public-static-methods>
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
end

function OvalePoolGC:Debug()
	Ovale:FormatPrint("Pool %s has size %d.", tostring(self.name), self.size)
end
--</public-static-methods>
