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
import { ovaleSpecializationName } from "../states/PaperDoll";

const mainIoC = new IoC();
registerScripts(mainIoC.scripts);
setMockOptions({ silentMessageFrame: true });

function checkNoMessage() {
    const messages: string[] = [];
    for (let i = 0; i < DEFAULT_CHAT_FRAME.GetNumMessages(); i++) {
        const message = DEFAULT_CHAT_FRAME.GetMessageInfo(i);

        // These spells does not exist in SC
        if (
            message.indexOf("Unknown spell with ID 296208") < 0 &&
            message.indexOf("Unknown spell with ID 51514") < 0 &&
            message.indexOf("Unknown spell with ID 280776") < 0
        ) {
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

const testedScripts = new Map<string, boolean>();

function integrationTest(name: string) {
    DEFAULT_CHAT_FRAME.Clear();
    testedScripts.set(name, true);
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
        const specializations = ovaleSpecializationName[className];
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
    expect(ioc.condition.hasAny()).toBeTruthy();
    const ast = ioc.compile.compileScript(name);
    checkNoMessage();
    expect(ast).toBeDefined();
    ioc.compile.evaluateScript(ast, true);
    checkNoMessage();
    const icons = ioc.compile.getIconNodes();
    expect(icons).toBeDefined();
    ioc.state.initializeState();
    ioc.bestAction.startNewAction();
    expect(lualength(icons)).toBeGreaterThan(0);

    for (const [, icon] of ipairs(icons)) {
        const result = ioc.bestAction.getAction(
            icon,
            ioc.baseState.currentTime
        );
        assertDefined(result);
        // TODO need filled spellbook     assertIs(result.type, "action");
    }
    checkNoMessage();
}
test("sc_t27_death_knight_blood", () =>
    integrationTest("sc_t27_death_knight_blood"));
test("sc_t27_death_knight_frost", () =>
    integrationTest("sc_t27_death_knight_frost"));
test("sc_t27_death_knight_frost_2h", () =>
    integrationTest("sc_t27_death_knight_frost_2h"));
test("sc_t27_death_knight_frost_breath", () =>
    integrationTest("sc_t27_death_knight_frost_breath"));
test("sc_t27_death_knight_frost_icecap", () =>
    integrationTest("sc_t27_death_knight_frost_icecap"));
test("sc_t27_death_knight_unholy", () =>
    integrationTest("sc_t27_death_knight_unholy"));
test("sc_t27_demon_hunter_havoc", () =>
    integrationTest("sc_t27_demon_hunter_havoc"));
test("sc_t27_demon_hunter_havoc_momentum", () =>
    integrationTest("sc_t27_demon_hunter_havoc_momentum"));
test("sc_t27_demon_hunter_vengeance", () =>
    integrationTest("sc_t27_demon_hunter_vengeance"));
test("sc_t27_druid_balance", () => integrationTest("sc_t27_druid_balance"));
test("sc_t27_druid_feral", () => integrationTest("sc_t27_druid_feral"));
test("sc_t27_druid_feral_owlweave", () =>
    integrationTest("sc_t27_druid_feral_owlweave"));
test("sc_t27_druid_guardian", () => integrationTest("sc_t27_druid_guardian"));
test("sc_t27_druid_guardian_venthyr", () =>
    integrationTest("sc_t27_druid_guardian_venthyr"));
test("sc_t27_hunter_beast_mastery", () =>
    integrationTest("sc_t27_hunter_beast_mastery"));
test("sc_t27_hunter_marksmanship", () =>
    integrationTest("sc_t27_hunter_marksmanship"));
test("sc_t27_hunter_survival", () => integrationTest("sc_t27_hunter_survival"));
test("sc_t27_mage_arcane", () => integrationTest("sc_t27_mage_arcane"));
test("sc_t27_mage_arcane_kyrian", () =>
    integrationTest("sc_t27_mage_arcane_kyrian"));
test("sc_t27_mage_fire", () => integrationTest("sc_t27_mage_fire"));
test("sc_t27_mage_frost", () => integrationTest("sc_t27_mage_frost"));
test("sc_t27_monk_brewmaster", () => integrationTest("sc_t27_monk_brewmaster"));
test("sc_t27_monk_windwalker", () => integrationTest("sc_t27_monk_windwalker"));
test("sc_t27_monk_windwalker_necrolord", () =>
    integrationTest("sc_t27_monk_windwalker_necrolord"));
test("sc_t27_monk_windwalker_night_fae", () =>
    integrationTest("sc_t27_monk_windwalker_night_fae"));
test("sc_t27_monk_windwalker_venthyr", () =>
    integrationTest("sc_t27_monk_windwalker_venthyr"));
test("sc_t27_paladin_holy", () => integrationTest("sc_t27_paladin_holy"));
test("sc_t27_paladin_protection", () =>
    integrationTest("sc_t27_paladin_protection"));
test("sc_t27_paladin_retribution", () =>
    integrationTest("sc_t27_paladin_retribution"));
test("sc_t27_priest_discipline", () =>
    integrationTest("sc_t27_priest_discipline"));
test("sc_t27_priest_shadow", () => integrationTest("sc_t27_priest_shadow"));
test("sc_t27_priest_shadow_kyrian", () =>
    integrationTest("sc_t27_priest_shadow_kyrian"));
test("sc_t27_priest_shadow_necrolord", () =>
    integrationTest("sc_t27_priest_shadow_necrolord"));
test("sc_t27_priest_shadow_venthyr", () =>
    integrationTest("sc_t27_priest_shadow_venthyr"));
test("sc_t27_rogue_assassination", () =>
    integrationTest("sc_t27_rogue_assassination"));
test("sc_t27_rogue_outlaw", () => integrationTest("sc_t27_rogue_outlaw"));
test("sc_t27_rogue_subtlety", () => integrationTest("sc_t27_rogue_subtlety"));
test("sc_t27_shaman_elemental", () =>
    integrationTest("sc_t27_shaman_elemental"));
test("sc_t27_shaman_elemental_kyrian", () =>
    integrationTest("sc_t27_shaman_elemental_kyrian"));
test("sc_t27_shaman_elemental_necrolord", () =>
    integrationTest("sc_t27_shaman_elemental_necrolord"));
test("sc_t27_shaman_elemental_venthyr", () =>
    integrationTest("sc_t27_shaman_elemental_venthyr"));
test("sc_t27_shaman_enhancement", () =>
    integrationTest("sc_t27_shaman_enhancement"));
test("sc_t27_shaman_enhancement_sorg", () =>
    integrationTest("sc_t27_shaman_enhancement_sorg"));
test("sc_t27_shaman_enhancement_vdw", () =>
    integrationTest("sc_t27_shaman_enhancement_vdw"));
test("sc_t27_shaman_restoration", () =>
    integrationTest("sc_t27_shaman_restoration"));
test("sc_t27_warlock_affliction", () =>
    integrationTest("sc_t27_warlock_affliction"));
test("sc_t27_warlock_demonology", () =>
    integrationTest("sc_t27_warlock_demonology"));
test("sc_t27_warlock_demonology_necrolord", () =>
    integrationTest("sc_t27_warlock_demonology_necrolord"));
test("sc_t27_warlock_destruction", () =>
    integrationTest("sc_t27_warlock_destruction"));
test("sc_t27_warrior_arms", () => integrationTest("sc_t27_warrior_arms"));
test("sc_t27_warrior_fury", () => integrationTest("sc_t27_warrior_fury"));
test("sc_t27_warrior_protection", () =>
    integrationTest("sc_t27_warrior_protection"));
test("All scripts are tested", () => {
    const missingScripts: string[] = [];
    for (const [name, script] of pairs(mainIoC.scripts.script)) {
        if (!script.className || script.type !== "script" || name === "custom")
            continue;
        if (!testedScripts.has(name)) missingScripts.push(name);
    }

    const code = missingScripts
        .map((x) => `test('${x}', () => integrationTest('${x}'))`)
        .join("\n");
    expect(code).toBe("");
});
