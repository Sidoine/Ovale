import { test } from "ava";
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
    t.is(result.actionList[1].child[1].child.if.type, "compare");
    t.is(result.actionList[1].child[1].child.if.operator, ">=");
    t.is(result.actionList[1].child[1].child.if.child[2].type, "number");
    t.is(result.actionList[1].child[1].child.if.child[2].value, 0.1);
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

test("parse cycle_targets", t => {
    // Arrange
    const code = `deathknight="test"
    spec=blood
    level=120
actions=/chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&talent.grimoire_of_supremacy.enabled`;

    // Act
    const result = OvaleSimulationCraft.ParseProfile(code);

    // Assert
    t.is(OvaleDebug.warning, undefined);
    t.is(result.actionList[1].type, "action_list");
    t.is(result.actionList[1].child[1].type, "action");
    t.is(result.actionList[1].child[1].child.if.type, "logical");
    t.is(result.actionList[1].child[1].child.if.operator, "&");
})