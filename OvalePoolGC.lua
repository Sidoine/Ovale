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

--<public-static-methods>
do
	-- Class constructor
	setmetatable(OvalePoolGC, { __call = function(self, ...) return self:NewPool(...) end })
end

function OvalePoolGC:NewPool(name)
	name = name or self.name
	return setmetatable({ name = name }, self)
end

function OvalePoolGC:Get()
	-- Keep running count of total number of tables allocated.
	self.size = self.size + 1
	return {}
end

function OvalePoolGC:Release(item)
	self:Clean(item)
end

function OvalePoolGC:GetReference(item)
	return item
end

function OvalePoolGC:ReleaseReference(item)
	-- no-op
end

function OvalePoolGC:Clean(item)
	-- virtual function; override as needed.
end

function OvalePoolGC:Drain()
	self.size = 0
end

function OvalePoolGC:Debug()
	Ovale:FormatPrint("Pool %s has size %d.", tostring(self.name), self.size)
end
--</public-static-methods>
