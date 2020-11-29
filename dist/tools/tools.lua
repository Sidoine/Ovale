local __exports = LibStub:NewLibrary("ovale/tools/tools", 90000)
if not __exports then return end
local type = type
local pairs = pairs
local strjoin = strjoin
local tostring = tostring
local tostringall = tostringall
local wipe = wipe
local select = select
local len = string.len
local find = string.find
local format = string.format
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
__exports.isString = function(s)
    return type(s) == "string"
end
__exports.isNumber = function(s)
    return type(s) == "number"
end
__exports.isBoolean = function(s)
    return type(s) == "boolean"
end
__exports.isLuaArray = function(a)
    return type(a) == "table"
end
__exports.checkToken = function(type, token)
    return type[token]
end
__exports.oneTimeMessages = {}
__exports.MakeString = function(s, ...)
    if s and len(s) > 0 then
        if ... and select("#", ...) > 0 then
            if find(s, "%%%.%d") or find(s, "%%[%w]") then
                s = format(s, tostringall(...))
            else
                s = strjoin(" ", s, tostringall(...))
            end
        else
            return s
        end
    else
        s = tostring(nil)
    end
    return s
end
__exports.Print = function(pattern, ...)
    local s = __exports.MakeString(pattern, ...)
    DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99Ovale|r: %s", s))
end
__exports.OneTimeMessage = function(pattern, ...)
    local s = __exports.MakeString(pattern, ...)
    if  not __exports.oneTimeMessages[s] then
        __exports.oneTimeMessages[s] = true
    end
end
__exports.ClearOneTimeMessages = function()
    wipe(__exports.oneTimeMessages)
end
__exports.PrintOneTimeMessages = function()
    for s in pairs(__exports.oneTimeMessages) do
        if __exports.oneTimeMessages[s] ~= "printed" then
            __exports.Print(s)
            __exports.oneTimeMessages[s] = "printed"
        end
    end
end
