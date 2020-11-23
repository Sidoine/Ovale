import { test, expect } from "@jest/globals";
import { IoC } from "../ioc";
import { ipairs, lualength, pairs } from "@wowts/lua";
import {
    eventDispatcher,
    DEFAULT_CHAT_FRAME,
    fakePlayer,
    setMockOptions,
} from "@wowts/wow-mock";
import { registerScripts } from "../scripts/index";
import { OVALE_SPECIALIZATION_NAME } from "../states/PaperDoll";

const mainIoC = new IoC();
registerScripts(mainIoC.scripts);
setMockOptions({ silentMessageFrame: true });

function checkNoMessage() {
    const messages: string[] = [];
    for (let i = 0; i < DEFAULT_CHAT_FRAME.GetNumMessages(); i++) {
        const message = DEFAULT_CHAT_FRAME.GetMessageInfo(i);

        // The scripts are not up to date
        if (message.indexOf("Unknown spell list") < 0) {
            messages.push(message);
        }
    }
    expect(messages).toEqual([]);
}
function assertDefined<T>(a: T | undefined): asserts a is T {
    expect(a).toBeDefined();
}

// function assertIs<T extends string>(a: string, b: T): asserts a is T {
//     expect(a).toBe(b);
// }

function integrationTest(name: string) {
    const script = mainIoC.scripts.script[name];
    const className = script.className;
    const specialization = script.specialization;
    assertDefined(className);
    assertDefined(specialization);
    const ioc = new IoC();
    registerScripts(ioc.scripts);
    ioc.debug.warning = undefined;
    ioc.debug.bug = undefined;
    fakePlayer.classId = className;
    if (specialization) {
        const specializations = OVALE_SPECIALIZATION_NAME[className];
        if (specializations[1] === specialization) {
            fakePlayer.specializationIndex = 1;
        } else if (specializations[2] === specialization) {
            fakePlayer.specializationIndex = 2;
        } else if (specializations[3] === specialization) {
            fakePlayer.specializationIndex = 3;
        } else if (specializations[4] === specialization) {
            fakePlayer.specializationIndex = 4;
        }
    }

    eventDispatcher.DispatchEvent("ADDON_LOADED", "Ovale");
    eventDispatcher.DispatchEvent("PLAYER_ENTERING_WORLD", "Ovale");
    eventDispatcher.DispatchEvent("SPELLS_CHANGED", "Ovale");
    expect(ioc.condition.HasAny()).toBeTruthy();
    const ast = ioc.compile.CompileScript(name);
    checkNoMessage();
    expect(ast).toBeDefined();
    ioc.compile.EvaluateScript(ast, true);
    checkNoMessage();
    const icons = ioc.compile.GetIconNodes();
    expect(icons).toBeDefined();
    ioc.state.InitializeState();
    ioc.bestAction.StartNewAction();
    expect(lualength(icons)).toBeGreaterThan(0);

    for (const [, icon] of ipairs(icons)) {
        const result = ioc.bestAction.GetAction(
            icon,
            ioc.baseState.current.currentTime
        );
        assertDefined(result);
        // TODO need filled spellbook     assertIs(result.type, "action");
    }
    checkNoMessage();
}

// test("sc_t25_warrior_fury", () => {
//     integrationTest("sc_t25_warrior_fury");
// });

for (const [name, script] of pairs(mainIoC.scripts.script)) {
    if (!script.className || script.type !== "script") continue;

    test(`Test ${name} script`, () => {
        integrationTest(name);
    });
}
