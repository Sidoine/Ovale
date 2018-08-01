import { Constructor, Library } from "@wowts/tslib";
export interface AceModule {
    GetName?(): string;
    OnInitialize?(): void;
}
export interface Addon {
    NewModule(name: string): Constructor<AceModule>;
    NewModule<T>(name: string, dep1: Library<T>): Constructor<AceModule & T>;
    NewModule<T, U>(name: string, dep1: Library<T>, dep2: Library<U>): Constructor<AceModule & T & U>;
    NewModule<T, U, V>(name: string, dep1: Library<T>, dep2: Library<U>, dep3: Library<V>): Constructor<AceModule & T & U & V>;
    NewModule<T, U, V, W>(name: string, dep1: Library<T>, dep2: Library<U>, dep3: Library<V>, dep4: Library<W>): Constructor<AceModule & T & U & V & W>;
    NewModuleWithBase<T>(name: string, base: Constructor<T>): Constructor<AceModule & T>;
    NewModuleWithBase<T, U>(name: string, base: Constructor<T>, dep2: Library<U>): Constructor<AceModule & T & U>;
    NewModuleWithBase<T, U, V>(name: string, base: Constructor<T>, dep2: Library<U>, dep3: Library<V>): Constructor<AceModule & T & U & V>;
    NewModuleWithBase<T, U, V, W>(name: string, base: Constructor<T>, dep2: Library<U>, dep3: Library<V>, dep4: Library<W>): Constructor<AceModule & T & U & V & W>;
    GetName(): string;
    OnInitialize?(): void;
}
/** Creates a new addon
 * @param name Must be the add-on name, as defined in the .toc file
 * @param depency A dependency
 */
export declare function NewAddon(name: string): Constructor<Addon>;
export declare function NewAddon<T>(name: string, dep1: Library<T>): Constructor<Addon & T>;
export declare function NewAddon<T, U>(name: string, dep1: Library<T>, dep2: Library<U>): Constructor<Addon & T & U>;
