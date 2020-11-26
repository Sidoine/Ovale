import { test, expect, beforeAll } from "@jest/globals";
import { Mock, It } from "typemoq";
import { OvaleASTClass } from "./AST";
import { OvaleConditionClass } from "./Condition";
import { OvaleDebugClass, Tracer } from "./Debug";
import { OvaleProfilerClass, Profiler } from "./Profiler";
import { OvaleScriptsClass } from "./Scripts";
import { OvaleSpellBookClass } from "./SpellBook";
import { format } from "@wowts/string";

const context = {
    ovaleConditionMock: Mock.ofType<OvaleConditionClass>(),
    ovaleDebugMock: Mock.ofType<OvaleDebugClass>(),
    ovaleProfilerMock: Mock.ofType<OvaleProfilerClass>(),
    ovaleScriptsMock: Mock.ofType<OvaleScriptsClass>(),
    ovaleSpellbookMock: Mock.ofType<OvaleSpellBookClass>(),
    tracerMock: Mock.ofType<Tracer>(),
};

function assertDefined<T>(a: T | undefined): asserts a is T {
    expect(a).toBeDefined();
}

function assertIs<T extends string>(a: string, b: T): asserts a is T {
    expect(a).toBe(b);
}

beforeAll(() => {
    const tracer = context.tracerMock;
    tracer
        .setup((x) => x.Warning(It.isAnyString()))
        .callback((x) => {
            throw Error(x);
        });
    tracer
        .setup((x) => x.Warning(It.isAnyString(), It.isAny()))
        .callback((x, y) => {
            throw Error(format(x, y));
        });
    tracer
        .setup((x) => x.Error(It.isAny()))
        .callback((x) => expect(x).toBeUndefined());
    context.ovaleDebugMock
        .setup((x) => x.create(It.isAnyString()))
        .returns(() => tracer.object);
    context.ovaleProfilerMock
        .setup((x) => x.create(It.isAny()))
        .returns(() => Mock.ofType<Profiler>().object);
});

function makeAst() {
    return {
        ast: new OvaleASTClass(
            context.ovaleConditionMock.object,
            context.ovaleDebugMock.object,
            context.ovaleProfilerMock.object,
            context.ovaleScriptsMock.object,
            context.ovaleSpellbookMock.object
        ),
        astAnnotation: { definition: {}, nodeList: {} },
    };
}

test("ast: parse Define", () => {
    // Act
    const { ast, astAnnotation } = makeAst();
    const [astNode, nodeList, annotation] = ast.ParseCode(
        "script",
        `Define(test 18)`,
        {},
        astAnnotation
    );

    // Assert
    assertDefined(astNode);
    assertDefined(nodeList);
    assertDefined(annotation);
    assertDefined(annotation.definition);
    expect(annotation.definition["test"]).toBe(18);
});

test("ast: parse SpellInfo", () => {
    // Act
    const { ast, astAnnotation } = makeAst();
    const [astNode, nodeList, annotation] = ast.ParseCode(
        "script",
        "SpellInfo(123 cd=30 rage=10)",
        {},
        astAnnotation
    );

    // Assert
    assertDefined(astNode);
    assertDefined(nodeList);
    assertDefined(annotation);
    assertIs(astNode.type, "script");
    const spellInfoNode = astNode.child[1];
    assertIs(spellInfoNode.type, "spell_info");
    expect(spellInfoNode.spellId).toBe(123);
    const cd = spellInfoNode.rawNamedParams.cd;
    assertDefined(cd);
    assertIs(cd.type, "value");
    expect(cd.value).toBe(30);
    const rage = spellInfoNode.rawNamedParams.rage;
    assertDefined(rage);
    assertIs(rage.type, "value");
    expect(rage.value).toBe(10);
});

test("ast: parse expression with a if with SpellInfo", () => {
    // Act
    const { ast, astAnnotation } = makeAst();
    const [astNode, nodeList, annotation] = ast.ParseCode(
        "icon",
        "AddIcon { if Talent(12) Spell(115) }",
        {},
        astAnnotation
    );

    // Assert
    assertDefined(astNode);
    assertDefined(nodeList);
    assertDefined(annotation);
    // t.is(astNode!.asString, "AddIcon\n{\n if talent(12) spell(115)\n}");
    assertIs(astNode.type, "icon");
    const group = astNode.child[1];
    assertIs(group.type, "group");
    const ifNode = group.child[1];
    assertIs(ifNode.type, "if");
    const talentNode = ifNode.child[1];
    assertIs(talentNode.type, "custom_function");
    expect(talentNode.name).toBe("talent");
    const spellNode = ifNode.child[2];
    assertIs(spellNode.type, "action");
    expect(spellNode.name).toBe("spell");
    const spellid = spellNode.rawPositionalParams[1];
    assertDefined(spellid);
    assertIs(spellid.type, "value");
    expect(spellid.value).toBe(115);
});

test("ast: dedupe nodes", () => {
    // Act
    const { ast } = makeAst();
    const astNode = ast.parseScript(
        "AddIcon { if BuffPresent(12) Spell(15) if BuffPresent(12) Spell(16) }"
    );

    // Assert
    assertDefined(astNode);
    assertIs(astNode.type, "script");
    const icon = astNode.child[1];
    assertIs(icon.type, "icon");
    const group = icon.child[1];
    assertIs(group.type, "group");
    const firstChild = group.child[1];
    assertIs(firstChild.type, "if");
    const secondChild = group.child[2];
    assertIs(secondChild.type, "if");
    expect(firstChild.child[1]).toBe(secondChild.child[1]);
});

test("ast: itemrequire", () => {
    // Act
    const { ast, astAnnotation } = makeAst();
    const [astNode, nodeList, annotation] = ast.ParseCode(
        "script",
        "ItemRequire(coagulated_nightwell_residue unusable buff set=1 enabled=(not buffpresent(nightwell_energy_buff)))",
        {},
        astAnnotation
    );

    // Assert
    assertDefined(astNode);
    assertDefined(nodeList);
    assertDefined(annotation);
    assertIs(astNode.type, "script");
    const itemRequire = astNode.child[1];
    assertIs(itemRequire.type, "itemrequire");
    expect(itemRequire.property).toBe("unusable");
});

test("ast: addcheckbox", () => {
    // Act
    const { ast, astAnnotation } = makeAst();
    const [astNode] = ast.ParseCode(
        "script",
        "AddCheckBox(opt_interrupt l(interrupt) default enabled=(specialization(blood)))",
        {},
        astAnnotation
    );

    // Assert
    assertDefined(astNode);
});

test("ast: spellaura", () => {
    // Act
    const { ast, astAnnotation } = makeAst();
    const [astNode] = ast.ParseCode(
        "script",
        "SpellAddBuff(bloodthirst bloodthirst_buff set=1)",
        {},
        astAnnotation
    );

    // Assert
    assertDefined(astNode);
});

test("if in {}", () => {
    const { ast, astAnnotation } = makeAst();
    const [astNode] = ast.ParseCode(
        "expression",
        `if { if 0 == 30 and equippedruneforge(disciplinary_command_runeforge) 50 } == 30 10`,
        {},
        astAnnotation
    );
    // Assert
    assertDefined(astNode);
    assertIs(astNode.type, "if");
});
