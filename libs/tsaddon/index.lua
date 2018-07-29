local __exports = LibStub:NewLibrary("tsaddon", 10102)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local CreateFrame = CreateFrame
local IsLoggedIn = IsLoggedIn
local ipairs = ipairs
__exports.NewAddon = function(name, dep1, dep2)
    local BaseClass = __class(nil, {
        constructor = function(self, args)
            self.modules = {}
            local frame = CreateFrame("Frame", "tslibframe")
            frame:RegisterEvent("ADDON_LOADED")
            frame:RegisterEvent("PLAYER_LOGIN")
            local loaded = false
            local logged = IsLoggedIn()
            local initialized = false
            frame:SetScript("OnEvent", function(frame, event, addon)
                if event == "PLAYER_LOGIN" then
                    logged = true
                end
                if event == "ADDON_LOADED" and addon == name then
                    loaded = true
                end
                if loaded and logged and  not initialized then
                    initialized = true
                    self:OnInitialize()
                    for _, module in ipairs(self.modules) do
                        if module.OnInitialize then
                            module:OnInitialize()
                        end
                    end
                end
            end)
        end,
        OnInitialize = function(self)
        end,
        NewModule = function(self, name, dep1, dep2, dep3, dep4)
            local addon = self
            local BaseModule = __class(nil, {
                constructor = function(self)
                    addon.modules[#addon.modules + 1] = self
                end,
                GetName = function(self)
                    return name
                end,
            })
            if dep1 then
                if dep2 then
                    if dep3 then
                        if dep4 then
                            return dep1:Embed(dep2:Embed(dep3:Embed(dep4:Embed(BaseModule))))
                        end
                        return dep1:Embed(dep2:Embed(dep3:Embed(BaseModule)))
                    end
                    return dep1:Embed(dep2:Embed(BaseModule))
                end
                return dep1:Embed(BaseModule)
            end
            return BaseModule
        end,
        NewModuleWithBase = function(self, name, base, dep2, dep3, dep4)
            local addon = self
            local BaseModule = __class(base, {
                constructor = function(self, ...)
                    base.constructor(self, ...)
                    addon.modules[#addon.modules + 1] = self
                end,
                GetName = function(self)
                    return name
                end,
            })
            if dep2 then
                if dep3 then
                    if dep4 then
                        return dep2:Embed(dep3:Embed(dep4:Embed(BaseModule)))
                    end
                    return dep2:Embed(dep3:Embed(BaseModule))
                end
                return dep2:Embed(BaseModule)
            end
            return BaseModule
        end,
        GetName = function(self)
            return name
        end,
    })
    if dep1 then
        if dep2 then
            return dep2:Embed(dep1:Embed(BaseClass))
        end
        return dep1:Embed(BaseClass)
    end
    return BaseClass
end
