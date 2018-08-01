local __exports = LibStub:NewLibrary("tslib", 10001)
if not __exports then return end
local setmetatable = setmetatable
__exports.newClass = function(base, prototype)
    local c = prototype
    if base then
        if  not base.constructor then
            base.constructor = function()
            end
        end
    else
        if  not c.constructor then
            c.constructor = function()
            end
        end
    end
    c.__index = c
    setmetatable(c, {
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:constructor(...)
            return self
        end,
        __index = base
    })
    return c
end
