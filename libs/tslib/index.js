"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const lua_1 = require("@wowts/lua");
function newClass(base, prototype) {
    const c = prototype;
    if (base) {
        if (!base.constructor) {
            base.constructor = () => { };
        }
    }
    else {
        if (!c.constructor) {
            c.constructor = () => { };
        }
    }
    c.__index = c;
    lua_1.setmetatable(c, {
        // tslint:disable-next-line:variable-name
        __call: (cls, ...__args) => {
            const self = lua_1.setmetatable({}, cls);
            self.constructor(...__args);
            return self;
        },
        __index: base,
    });
    return c;
}
exports.newClass = newClass;
