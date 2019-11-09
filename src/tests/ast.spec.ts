import test, { TestInterface } from "ava";
import { Mock, It, IMock } from "typemoq";
import { OvaleASTClass, AstAnnotation } from "../AST";
import { OvaleConditionClass } from "../Condition";
import { OvaleDebugClass, Tracer } from "../Debug";
import { OvaleProfilerClass, Profiler } from "../Profiler";
import { OvaleScriptsClass } from "../Scripts";
import { OvaleSpellBookClass } from "../SpellBook";
import { format } from "@wowts/string";

interface Context {
    ovaleConditionMock: IMock<OvaleConditionClass>;
    ovaleDebugMock: IMock<OvaleDebugClass>;
    ovaleProfilerMock: IMock<OvaleProfilerClass>;
    ovaleScriptsMock: IMock<OvaleScriptsClass>;
    ovaleSpellbookMock: IMock<OvaleSpellBookClass>;
    ast: OvaleASTClass;
    tracerMock: IMock<Tracer>;
    annotation: AstAnnotation;
}

const t = test as TestInterface<Context>;

t.beforeEach(t => {
    t.context.ovaleConditionMock = Mock.ofType<OvaleConditionClass>();
    t.context.ovaleDebugMock = Mock.ofType<OvaleDebugClass>();
    const tracer = Mock.ofType<Tracer>();
    tracer.setup(x => x.Warning(It.isAnyString())).callback(x => {throw Error(x)});
    tracer.setup(x => x.Warning(It.isAnyString(), It.isAny())).callback((x,y) => {throw Error(format(x, y))});
    tracer.setup(x => x.Error(It.isAny())).callback(x => t.fail(x));
    t.context.tracerMock = tracer;
    t.context.ovaleDebugMock.setup(x => x.create(It.isAnyString())).returns(() => (tracer.object));
    t.context.ovaleProfilerMock = Mock.ofType<OvaleProfilerClass>();
    t.context.ovaleProfilerMock.setup(x => x.create(It.isAny())).returns(() => Mock.ofType<Profiler>().object);
    t.context.ovaleScriptsMock = Mock.ofType<OvaleScriptsClass>();
    t.context.ovaleSpellbookMock = Mock.ofType<OvaleSpellBookClass>();
    t.context.ast = new OvaleASTClass(
        t.context.ovaleConditionMock.object, 
        t.context.ovaleDebugMock.object,
        t.context.ovaleProfilerMock.object,
        t.context.ovaleScriptsMock.object,
        t.context.ovaleSpellbookMock.object);
    t.context.annotation = { definition: {}, nodeList: {} };
});


t("ast: parse Define", t => {
    // Act
    const [astNode, nodeList, annotation ] = t.context.ast.ParseCode("script", `Define(test 18)`, {}, t.context.annotation);

    // Assert
    t.truthy(astNode);
    t.truthy(nodeList);
    t.truthy(annotation!.definition);
    t.is(annotation!.definition["test"], 18);
});

t("ast: parse SpellInfo", t => {
    // Act
    const [astNode, nodeList, annotation] = t.context.ast.ParseCode("script", "SpellInfo(123 cd=30 rage=10)", {}, t.context.annotation);

    // Assert
    t.truthy(astNode);
    t.truthy(nodeList);
    t.truthy(annotation);
    t.is(astNode!.type, "script");
    const spellInfoNode = astNode!.child[1];
    t.is(spellInfoNode.type, "spell_info");
    t.is(spellInfoNode.spellId, 123);
    t.is(spellInfoNode.rawNamedParams.cd!.type, "value");
    t.is(spellInfoNode.rawNamedParams.cd!.value, 30);
    t.is(spellInfoNode.rawNamedParams.rage!.type, "value");
    t.is(spellInfoNode.rawNamedParams.rage!.value, 10);
});

t("ast: parse expression with a if with SpellInfo", t => {
    // Act
    const [astNode, nodeList, annotation] = t.context.ast.ParseCode("icon", "AddIcon { if Talent(12) Spell(115) }", {}, t.context.annotation);
    
    // Assert
    t.truthy(astNode);
    t.truthy(nodeList);
    t.truthy(annotation);
    t.is(astNode!.asString, "AddIcon\n{\n if talent(12) spell(115)\n}");
    t.is(astNode!.type, "icon");
    const group = astNode!.child[1];
    t.is(group.type, "group");
    const ifNode = group.child[1];
    t.is(ifNode.type, "if");
    const talentNode = ifNode.child[1];
    t.is(talentNode.type, "custom_function");
    t.is(talentNode.func, "Talent");
    const spellNode = ifNode.child[2];
    t.is(spellNode.type, "action");
    t.is(spellNode.func, "spell");
    t.is(spellNode.rawPositionalParams[1].value, 115);
});

t("ast: dedupe nodes", t => {
    // Act
    const astNode = t.context.ast.parseScript("AddIcon { if BuffPresent(12) Spell(15) if BuffPresent(12) Spell(16) }");

    // Assert
    t.truthy(astNode);
    t.is(astNode!.type, "script");
    const icon = astNode!.child[1];
    t.is(icon.type, "icon");
    const group = icon.child[1];
    t.is(group.type, "group");
    const firstChild = group.child[1];
    t.is(firstChild.type, "if");
    const secondChild = group.child[2];
    t.is(secondChild.type, "if");
    t.true(firstChild.child[1] === secondChild.child[1]);
});