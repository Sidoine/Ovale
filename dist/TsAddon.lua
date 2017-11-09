local __addonName, __addon = ...
            __addon.require("./TsAddon", {}, function(__exports)
__exports.NewAddon = function(name, dependency)
    local BaseClass = __addon.__class(nil, {
        NewModule = function(self, name, dep1, dep2, dep3)
            local BaseModule = __addon.__class(nil, {
                GetName = function(self)
                    return name
                end,
            })
            if dep1 then
                if dep2 then
                    if dep3 then
                        return dep1:Embed(dep2:Embed(dep3:Embed(BaseModule)))
                    end
                    return dep1:Embed(dep2:Embed(BaseModule))
                end
                return dep1:Embed(BaseModule)
            end
            return BaseModule
        end,
        GetName = function(self)
            return name
        end,
        Print = function(self, message, parameters)
        end,
    })
    return dependency:Embed(BaseClass)
end
end)
