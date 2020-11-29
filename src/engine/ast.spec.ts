import { test, expect, beforeAll } from "@jest/globals";
import { Mock, It } from "typemoq";
import { OvaleASTClass } from "./ast";
import { OvaleConditionClass } from "./condition";
import { OvaleDebugClass, Tracer } from "./debug";
import { OvaleProfilerClass, Profiler } from "./profiler";
import { OvaleScriptsClass } from "./scripts";
import { OvaleSpellBookClass } from "../states/SpellBook";
import { format } from "@wowts/string";
import { assertDefined, assertIs } from "../tests/helpers";

const context = {
    ovaleConditionMock: Mock.ofType<OvaleConditionClass>(),
    ovaleDebugMock: Mock.ofType<OvaleDebugClass>(),
    ovaleProfilerMock: Mock.ofType<OvaleProfilerClass>(),
    ovaleScriptsMock: Mock.ofType<OvaleScriptsClass>(),
    ovaleSpellbookMock: Mock.ofType<OvaleSpellBookClass>(),
    tracerMock: Mock.ofType<Tracer>(),
};

beforeAll(() => {
    const tracer = context.tracerMock;
    tracer
        .setup((x) => x.Warning(It.isAnyString()))
        .callback((x) => {
            expect(format(x)).toBeUndefined();
        });
    tracer
        .setup((x) => x.Warning(It.isAnyString(), It.isAny()))
        .callback((x, y) => {
            expect(format(x, y)).toBeUndefined();
        });
    tracer
        .setup((x) => x.Warning(It.isAnyString(), It.isAny(), It.isAny()))
        .callback((x, y, z) => {
            expect(format(x, y, z)).toBeUndefined();
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
    // Arrange
    const { ast, astAnnotation } = makeAst();

    // Act
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

test("typed condition with only position parameters", () => {
    // Arrange
    context.ovaleConditionMock
        .setup((x) => x.getInfos("test"))
        .returns(() => ({
            func: () => [0, 12, "a"],
            namedParameters: {},
            parameters: {
                1: { type: "string", name: "a", optional: true },
                2: { type: "number", name: "b", optional: true },
            },
            returnValue: { name: "return", type: "string" },
        }));
    const { ast, astAnnotation } = makeAst();

    // Act
    const [astNode] = ast.ParseCode(
        "expression",
        `test("example" 12)`,
        {},
        astAnnotation
    );

    // Assert
    assertDefined(astNode);
    assertIs(astNode.type, "typed_function");
    expect(astNode.name).toBe("test");
    expect(astNode.rawNamedParams).toEqual({});
    assertDefined(astNode.rawPositionalParams[1]);
    assertIs(astNode.rawPositionalParams[1].type, "string");
    assertDefined(astNode.rawPositionalParams[2]);
    assertIs(astNode.rawPositionalParams[2].type, "value");
    expect(astNode.asString).toBe('test("example" 12)');
});

test("typed condition with only named parameters", () => {
    // Arrange
    context.ovaleConditionMock
        .setup((x) => x.getInfos("test"))
        .returns(() => ({
            func: () => [0, 12, "a"],
            namedParameters: { a: 1, b: 2 },
            parameters: {
                1: { type: "string", name: "a", optional: true },
                2: { type: "number", name: "b", optional: true },
            },
            returnValue: { name: "return", type: "string" },
        }));
    const { ast, astAnnotation } = makeAst();

    // Act
    const [astNode] = ast.ParseCode(
        "expression",
        `test(b=12 a="example")`,
        {},
        astAnnotation
    );

    // Assert
    assertDefined(astNode);
    assertIs(astNode.type, "typed_function");
    expect(astNode.name).toBe("test");
    assertDefined(astNode.rawPositionalParams[1]);
    assertIs(astNode.rawPositionalParams[1].type, "string");
    expect(astNode.rawPositionalParams[1].value).toBe("example");
    assertDefined(astNode.rawPositionalParams[2]);
    assertIs(astNode.rawPositionalParams[2].type, "value");
    expect(astNode.rawPositionalParams[2].value).toBe(12);
    expect(astNode.asString).toEqual('test("example" 12)');
});

test("typed condition with parameters with default values", () => {
    // Arrange
    context.ovaleConditionMock
        .setup((x) => x.getInfos("test"))
        .returns(() => ({
            func: () => [0, 12, "a"],
            namedParameters: {},
            parameters: {
                1: {
                    type: "string",
                    name: "a",
                    optional: true,
                    defaultValue: "test",
                },
                2: {
                    type: "string",
                    name: "a",
                    optional: true,
                },
                3: {
                    type: "number",
                    name: "b",
                    optional: true,
                    defaultValue: 14,
                },
                4: {
                    type: "boolean",
                    name: "c",
                    optional: true,
                    defaultValue: true,
                },
            },
            returnValue: { name: "return", type: "string" },
        }));
    const { ast, astAnnotation } = makeAst();

    // Act
    const [astNode] = ast.ParseCode("expression", `test()`, {}, astAnnotation);

    // Assert
    assertDefined(astNode);
    assertIs(astNode.type, "typed_function");
    expect(astNode.name).toBe("test");
    assertDefined(astNode.rawPositionalParams[1]);
    assertIs(astNode.rawPositionalParams[1].type, "string");
    expect(astNode.rawPositionalParams[1].value).toBe("test");
    assertDefined(astNode.rawPositionalParams[3]);
    assertIs(astNode.rawPositionalParams[3].type, "value");
    expect(astNode.rawPositionalParams[3].value).toBe(14);
    assertDefined(astNode.rawPositionalParams[4]);
    assertIs(astNode.rawPositionalParams[4].type, "boolean");
    expect(astNode.rawPositionalParams[4].value).toBe(true);
    expect(astNode.asString).toEqual("test()");
});

test("boolean node", () => {
    // Arrange
    const { ast, astAnnotation } = makeAst();

    // Act
    const [astNode] = ast.ParseCode(
        "expression",
        `if true or false 18`,
        {},
        astAnnotation
    );

    // Assert
    assertDefined(astNode);
    assertIs(astNode.type, "if");
    assertDefined(astNode.child[1]);
    assertIs(astNode.child[1].type, "logical");
    expect(astNode.child[1].operator).toEqual("or");
    const left = astNode.child[1].child[1];
    assertDefined(left);
    assertIs(left.type, "boolean");
    expect(left.value).toBe(true);
    const right = astNode.child[1].child[2];
    assertDefined(right);
    assertIs(right.type, "boolean");
    expect(right.value).toBe(false);
});

test("unparse typed function with optional parameters", () => {
    // Arrange
    context.ovaleConditionMock
        .setup((x) => x.getInfos("test"))
        .returns(() => ({
            func: () => [0, 12, "a"],
            namedParameters: { a: 1, b: 2, c: 3 },
            parameters: {
                1: {
                    type: "string",
                    name: "a",
                    optional: true,
                    defaultValue: "test",
                },
                2: {
                    type: "number",
                    name: "b",
                    optional: true,
                    defaultValue: 14,
                },
                3: {
                    type: "boolean",
                    name: "c",
                    optional: true,
                    defaultValue: true,
                },
            },
            returnValue: { name: "return", type: "string" },
        }));
    const { ast, astAnnotation } = makeAst();

    // Act
    const [astNode] = ast.ParseCode(
        "expression",
        `test(b=15)`,
        {},
        astAnnotation
    );

    // Assert
    assertDefined(astNode);
    assertIs(astNode.type, "typed_function");
    expect(astNode.asString).toBe("test(b=15)");
});
