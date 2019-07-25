import test from "ava";
import { IoC } from "../ioc";
import { pairs } from "@wowts/lua";
import { eventDispatcher } from "@wowts/wow-mock";
import { oneTimeMessages } from "../Ovale";

const ioc = new IoC();

for (const [name, script] of pairs(ioc.scripts.script)) {
    if (!script.className || script.type !== "script") continue;

    test(`Test ${name} script`, t => {

        ioc.debug.warning = undefined;
        ioc.debug.bug = undefined;
        ioc.ovale.playerGUID = "player";
        ioc.ovale.playerClass = script.className;
        eventDispatcher.DispatchEvent("ADDON_LOADED", "Ovale");
        eventDispatcher.DispatchEvent("PLAYER_ENTERING_WORLD", "Ovale");
        t.truthy(ioc.condition.HasAny());
        const ast = ioc.compile.CompileScript(name);
        t.is(ioc.debug.bug, undefined);
        t.truthy(ast);
        ioc.compile.EvaluateScript(ast, true);
        t.is(ioc.debug.bug, undefined);
        t.is(ioc.debug.warning, undefined);
        t.truthy(ioc.compile.GetIconNodes());
        for (const k in oneTimeMessages) {
            t.falsy(k);
        }
    });
}
