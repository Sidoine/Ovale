"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const wow_mock_1 = require("@wowts/wow-mock");
const lua_1 = require("@wowts/lua");
function NewAddon(name, dep1, dep2) {
    const BaseClass = class {
        constructor(...args) {
            this.modules = {};
            const frame = wow_mock_1.CreateFrame("Frame", "tslibframe");
            frame.RegisterEvent("ADDON_LOADED");
            frame.RegisterEvent("PLAYER_LOGIN");
            let loaded = false;
            let logged = wow_mock_1.IsLoggedIn();
            let initialized = false;
            frame.SetScript("OnEvent", (frame, event, addon) => {
                if (event === "PLAYER_LOGIN")
                    logged = true;
                if (event === "ADDON_LOADED" && addon === name)
                    loaded = true;
                if (loaded && logged && !initialized) {
                    initialized = true;
                    this.OnInitialize();
                    for (const [, module] of lua_1.ipairs(this.modules)) {
                        if (module.OnInitialize) {
                            module.OnInitialize();
                        }
                    }
                }
            });
        }
        OnInitialize() { }
        NewModule(name, dep1, dep2, dep3, dep4) {
            const addon = this;
            const BaseModule = class {
                constructor() {
                    addon.modules[lua_1.lualength(addon.modules) + 1] = this;
                }
                GetName() {
                    return name;
                }
            };
            if (dep1) {
                if (dep2) {
                    if (dep3) {
                        if (dep4) {
                            return dep1.Embed(dep2.Embed(dep3.Embed(dep4.Embed(BaseModule))));
                        }
                        return dep1.Embed(dep2.Embed(dep3.Embed(BaseModule)));
                    }
                    return dep1.Embed(dep2.Embed(BaseModule));
                }
                return dep1.Embed(BaseModule);
            }
            return BaseModule;
        }
        NewModuleWithBase(name, base, dep2, dep3, dep4) {
            const addon = this;
            const BaseModule = class extends base {
                constructor(...__args) {
                    super(__args);
                    addon.modules[lua_1.lualength(addon.modules) + 1] = this;
                }
                GetName() {
                    return name;
                }
            };
            if (dep2) {
                if (dep3) {
                    if (dep4) {
                        return dep2.Embed(dep3.Embed(dep4.Embed(BaseModule)));
                    }
                    return dep2.Embed(dep3.Embed(BaseModule));
                }
                return dep2.Embed(BaseModule);
            }
            return BaseModule;
        }
        GetName() {
            return name;
        }
    };
    if (dep1) {
        if (dep2) {
            return dep2.Embed(dep1.Embed(BaseClass));
        }
        return dep1.Embed(BaseClass);
    }
    return BaseClass;
}
exports.NewAddon = NewAddon;
