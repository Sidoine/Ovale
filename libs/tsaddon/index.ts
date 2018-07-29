import { Constructor, Library } from "@wowts/tslib";
import { CreateFrame, UIFrame, IsLoggedIn } from "@wowts/wow-mock";
import { LuaArray, ipairs, lualength } from "@wowts/lua";

export interface AceModule {
    GetName?(): string;
    OnInitialize?(): void;
}

export interface Addon {
    NewModule(name: string) : Constructor<AceModule>;
    NewModule<T>(name: string, dep1: Library<T>) : Constructor<AceModule & T>;
    NewModule<T, U>(name: string, dep1: Library<T>, dep2: Library<U>) : Constructor<AceModule & T & U>;
    NewModule<T, U, V>(name: string, dep1: Library<T>, dep2: Library<U>, dep3: Library<V>): Constructor<AceModule & T & U & V>;
    NewModule<T, U, V, W>(name: string, dep1: Library<T>, dep2: Library<U>, dep3: Library<V>, dep4: Library<W>): Constructor<AceModule & T & U & V & W>;

    NewModuleWithBase<T>(name: string, base: Constructor<T>) : Constructor<AceModule & T>;
    NewModuleWithBase<T, U>(name: string, base: Constructor<T>, dep2: Library<U>) : Constructor<AceModule & T & U>;
    NewModuleWithBase<T, U, V>(name: string, base: Constructor<T>, dep2: Library<U>, dep3: Library<V>): Constructor<AceModule & T & U & V>;
    NewModuleWithBase<T, U, V, W>(name: string, base: Constructor<T>, dep2: Library<U>, dep3: Library<V>, dep4: Library<W>): Constructor<AceModule & T & U & V & W>;

    GetName():string;
    OnInitialize?():void;
}

/** Creates a new addon
 * @param name Must be the add-on name, as defined in the .toc file
 * @param depency A dependency
 */
export function NewAddon(name: string): Constructor<Addon>;
export function NewAddon<T>(name: string, dep1:Library<T>): Constructor<Addon & T>;
export function NewAddon<T, U>(name: string, dep1:Library<T>, dep2: Library<U>): Constructor<Addon & T & U>
export function NewAddon<T, U>(name: string, dep1?:Library<T>, dep2?: Library<U>): Constructor<Addon & T & U> | Constructor<Addon & T> | Constructor<Addon> {
    const BaseClass = class {
        private modules: LuaArray<AceModule> = {};

        constructor(...args:any[]) {
            const frame = CreateFrame("Frame", "tslibframe");
            frame.RegisterEvent("ADDON_LOADED");
            frame.RegisterEvent("PLAYER_LOGIN");
            let loaded = false;
            let logged = IsLoggedIn();
            let initialized = false;
            frame.SetScript("OnEvent", (frame: UIFrame, event: string, addon: string) => {
                if (event === "PLAYER_LOGIN") logged = true;
                if (event === "ADDON_LOADED" && addon === name) loaded = true;
                if (loaded && logged && !initialized) {
                    initialized = true;
                    this.OnInitialize();
                    for (const [,module] of ipairs(this.modules)) {
                        if (module.OnInitialize) {
                            module.OnInitialize();
                        }
                    }
                }
            })
        }
        OnInitialize(){}
        NewModule<T, U, V, W>(name: string, dep1?: Library<T>, dep2?: Library<U>, dep3?: Library<V>, dep4?: Library<W>) {
            const addon = this;
            const BaseModule = class {
                constructor() {
                    addon.modules[lualength(addon.modules) + 1] = this;
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

        NewModuleWithBase<U, V, W>(name: string, base: Constructor<{}>, dep2?: Library<U>, dep3?: Library<V>, dep4?: Library<W>) {
            const addon = this;
            const BaseModule = class extends base {
                constructor(...__args:any[]) {
                    super(__args);
                    addon.modules[lualength(addon.modules) + 1] = this;
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
