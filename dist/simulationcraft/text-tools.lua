local __exports = LibStub:NewLibrary("ovale/simulationcraft/text-tools", 90000)
if not __exports then return end
local tonumber = tonumber
local setmetatable = setmetatable
local rawset = rawset
local type = type
local tostring = tostring
local pairs = pairs
local format = string.format
local gsub = string.gsub
local upper = string.upper
local lower = string.lower
local match = string.match
local __toolsPool = LibStub:GetLibrary("ovale/tools/Pool")
local OvalePool = __toolsPool.OvalePool
__exports.INDENT = {}
do
    __exports.INDENT[0] = ""
    local metatable = {
        __index = function(tbl, key)
            local _key = tonumber(key)
            if _key > 0 then
                local s = tbl[_key - 1] .. "	"
                rawset(tbl, key, s)
                return s
            end
            return __exports.INDENT[0]
        end

    }
    setmetatable(__exports.INDENT, metatable)
end
__exports.print_r = function(data)
    local buffer = ""
    local padder = "  "
    local max = 10
local function _repeat(str, num)
        local output = ""
        for i = 0, num, 1 do
            output = output .. str
        end
        return output
    end
local function _dumpvar(d, depth)
        if depth > max then
            return 
        end
        local t = type(d)
        local str = (d ~= nil and tostring(d)) or ""
        if t == "table" then
            buffer = buffer .. format(" (%s) {\n", str)
            for k, v in pairs(d) do
                buffer = buffer .. format(" %s [%s] =>", _repeat(padder, depth + 1), k)
                _dumpvar(v, depth + 1)
            end
            buffer = buffer .. format(" %s }\n", _repeat(padder, depth))
        elseif t == "number" then
            buffer = buffer .. format(" (%s) %d\n", t, str)
        else
            buffer = buffer .. format(" (%s) %s\n", t, str)
        end
    end
    _dumpvar(data, 0)
    return buffer
end
__exports.self_outputPool = OvalePool("OvaleSimulationCraft_outputPool")
local function CamelCaseHelper(first, ...)
    return upper(first) .. lower(...)
end
__exports.CamelCase = function(s)
    local tc = gsub(s, "(%a)(%w*)", CamelCaseHelper)
    return gsub(tc, "[%s_]", "")
end
__exports.LowerSpecialization = function(annotation)
    return lower(annotation.specialization)
end
__exports.OvaleFunctionName = function(name, annotation)
    local functionName = lower(name .. "actions")
    if annotation.specialization then
        functionName = __exports.LowerSpecialization(annotation) .. functionName
    end
    return functionName
end
__exports.OvaleTaggedFunctionName = function(name, tag)
    local bodyName, conditionName
    local prefix, suffix = match(name, "([a-z]%w+)(actions)$")
    if prefix and suffix then
        bodyName = lower(prefix .. tag .. suffix)
        conditionName = lower(prefix .. tag .. "postconditions")
    end
    return bodyName, conditionName
end
