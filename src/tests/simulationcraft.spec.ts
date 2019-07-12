import test from "ava";
import { OvaleSimulationCraft } from "../SimulationCraft";
import { OvaleDebug } from "../Debug";

test("parse decimal number", t => {
    // Arrange
    const code = `deathknight="test"
spec=blood
level=120
actions=/potion,if=buff.test.stack>=0.1`;

    // Act
    const result = OvaleSimulationCraft.ParseProfile(code);

    // Assert
    t.is(result.actionList[1].type, "action_list");
    t.is(result.actionList[1].child[1].type, "action");
    t.is(result.actionList[1].child[1].modifiers.if.type, "compare");
    t.is(result.actionList[1].child[1].modifiers.if.operator, ">=");
    t.is(result.actionList[1].child[1].modifiers.if.child[2].type, "number");
    t.is(result.actionList[1].child[1].modifiers.if.child[2].value, 0.1);
});

test("parse sequence", t => {
    // Arrange
    const code = `deathknight="test"
    spec=blood
    level=120
actions=/sequence,if=talent.wake_of_ashes.enabled&talent.crusade.enabled&talent.execution_sentence.enabled&!talent.hammer_of_wrath.enabled,name=wake_opener_ES_CS:shield_of_vengeance:blade_of_justice:judgment:crusade:templars_verdict:wake_of_ashes:templars_verdict:crusader_strike:execution_sentence`
    
    // Act
    const result = OvaleSimulationCraft.ParseProfile(code);

    // Assert
    t.is(OvaleDebug.warning, undefined);
    t.not(result, undefined);
})

// test("parse cycle_targets", t => {
//     // Arrange
//     const code = `deathknight="test"
//     spec=blood
//     level=120
// actions=/chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&talent.grimoire_of_supremacy.enabled`;
//     OvaleScripts.RegisterScript("DEATHKNIGHT", "blood", "ovale_common", "", "Define(chaos_bolt 1) Define(havoc_debuff 2) Define(grimoire_of_supremacy 3)", "include");
//     OvaleScripts.RegisterScript("DEATHKNIGHT", "blood", "ovale_trinkets_mop", "", "Define(mind_freeze 5) Define(war_stomp 6)", "include");
//     OvaleScripts.RegisterScript("DEATHKNIGHT", "blood", "ovale_trinkets_wod", "", "Define(asphyxiate 10)", "include");
//     OvaleScripts.RegisterScript("DEATHKNIGHT", "blood", "ovale_deathknight_spells", "", "Define(grimoire_of_supremacy_talent 4)", "include");
    
//     // Act
//     const profile = OvaleSimulationCraft.ParseProfile(code);
//     t.not(profile, undefined);
//     const result = OvaleSimulationCraft.Emit(profile);
    
//     // Assert
//     t.regex(result, /if not target\.DebuffPresent\(havoc_debuff\) and Talent\(grimoire_of_supremacy_talent\) Spell\(chaos_bolt\)/);
//     t.regex(result, /if not { not target\.DebuffPresent\(havoc_debuff\) and Talent\(grimoire_of_supremacy_talent\) } Spell\(chaos_bolt text=cycle\)/);
// })
