local __exports = LibStub:NewLibrary("ovale/tools", 80000)
if not __exports then return end
local type = type
__exports.isString = function(s)
    return type(s) == "string"
end
__exports.isNumber = function(s)
    return type(s) == "number"
end
__exports.isLuaArray = function(a)
    return type(a) == "table"
end
__exports.checkToken = function(type, token)
    return type[token]
end
