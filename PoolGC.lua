--[[--------------------------------------------------------------------
    Copyright (C) 2013 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- This module wraps the standard Lua garbage collector using the Pool interface.
local OVALE, Ovale = ...
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

function OvalePoolGC:Clean(item)
	-- virtual function; override as needed.
end

function OvalePoolGC:Drain()
	self.size = 0
end

function OvalePoolGC:DebuggingInfo()
	Ovale:Print("Pool %s has size %d.", tostring(self.name), self.size)
end
--</public-static-methods>
