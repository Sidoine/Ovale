import { AceDatabase } from "@wowts/ace_db-3.0";
import { LuaArray } from "@wowts/lua";
import { huge } from "@wowts/math";
import { AstNode, AstNodeSnapshot, NodeType } from "../engine/ast";
import { IoC } from "../ioc";
import { registerScripts } from "../scripts";
import { assertDefined } from "../tests/helpers";
import { newFromArgs, newTimeSpan } from "../tools/TimeSpan";
import { OvaleDb } from "../ui/Options";

interface IconDump {
    atTime: number;
    serial: number;
    index: number;
    script: string;
    nodes: Record<
        string,
        { result: AstNodeSnapshot; asString: null | string; type: NodeType }
    >;
    result: AstNodeSnapshot;
}

function fixSnapshot(snapshot: AstNodeSnapshot) {
    if (snapshot.timeSpan[1] !== undefined)
        snapshot.timeSpan = newFromArgs(
            ...((snapshot.timeSpan as unknown) as number[])
        );
    else snapshot.timeSpan = newTimeSpan();
}

export function executeDump(
    json: string
): [AstNodeSnapshot | undefined, IconDump, LuaArray<AstNode>, string] {
    json = json.replace(/\binf\b/g, huge.toString());
    const iconDump = JSON.parse(json) as IconDump;
    const ioc = new IoC();
    registerScripts(ioc.scripts);
    ioc.options.db = { global: { debug: {}, profiler: {} } } as AceDatabase &
        OvaleDb;
    const script = ioc.compile.CompileScript(iconDump.script);
    ioc.baseState.ResetState = () => {};
    ioc.debug.DoTrace(false);
    assertDefined(script);
    ioc.compile.EvaluateScript();
    const iconNodes = ioc.compile.GetIconNodes();
    const iconNode = iconNodes[iconDump.index];
    assertDefined(iconNode);
    ioc.baseState.currentTime = iconDump.atTime;
    const nodeList = script.annotation.nodeList;
    for (const [k, v] of Object.entries(iconDump.nodes)) {
        const result = v.result;
        fixSnapshot(result);
        const nodeId = parseInt(k);
        const node = nodeList[nodeId];
        const nodeResult = nodeList[nodeId].result;
        Object.assign(nodeResult, result);

        if (
            node.type !== "action" &&
            node.type !== "function" &&
            node.type !== "typed_function"
        ) {
            nodeResult.serial = 0;
        }
    }
    ioc.runner.self_serial = iconDump.serial - 1;
    const [result] = ioc.frame.frame.getIconAction(iconNode);
    fixSnapshot(iconDump.result);
    const log = (ioc.debug.traceLog as any).lines
        .join("\n")
        .replace(/1\.7976931348623157e\+308/g, "inf");
    return [result, iconDump, nodeList, log];
}
