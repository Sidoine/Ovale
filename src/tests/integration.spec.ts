import test, { ExecutionContext } from "ava";
import { IoC } from "../ioc";
import { pairs, ipairs, lualength } from "@wowts/lua";
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

function checkNoMessage(t: ExecutionContext<unknown>) {
    const messages: string[] = [];
    for (let i = 0; i < DEFAULT_CHAT_FRAME.GetNumMessages(); i++) {
        const message = DEFAULT_CHAT_FRAME.GetMessageInfo(i);

        // The scripts are not up to date
        if (message.indexOf("Unknown spell list") < 0) {
            messages.push(message);
        }
    }
    t.deepEqual(messages, []);
}

for (const [name, script] of pairs(mainIoC.scripts.script)) {
    if (!script.className || script.type !== "script") continue;
    const className = script.className;
    const specialization = script.specialization;
    //if (name !== "sc_t25_warrior_fury") continue;

    test(`Test ${name} script`, (t) => {
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
        t.truthy(ioc.condition.HasAny());
        const ast = ioc.compile.CompileScript(name);
        checkNoMessage(t);
        t.truthy(ast);
        ioc.compile.EvaluateScript(ast, true);
        checkNoMessage(t);
        const icons = ioc.compile.GetIconNodes();
        t.truthy(icons);
        ioc.state.InitializeState();
        ioc.bestAction.StartNewAction();
        if (
            name === "sc_t25_mage_frost" ||
            name === "sc_t25_mage_fire" ||
            name === "sc_t25_mage_arcane" ||
            name == "sc_t25_death_knight_unholy"
        ) {
            t.is(lualength(icons), 0);
        } else {
            t.truthy(lualength(icons));
        }
        for (const [, icon] of ipairs(icons)) {
            const [timeSpan] = ioc.bestAction.GetAction(
                icon,
                ioc.baseState.current.currentTime
            );
            t.truthy(timeSpan);
        }
        checkNoMessage(t);
    });
}
