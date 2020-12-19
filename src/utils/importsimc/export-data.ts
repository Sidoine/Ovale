import { writeFileSync } from "fs";
import { DbcData } from "./importspells";

export function exportData(dbc: DbcData) {
    const lines = [
        `import { LuaArray } from "@wowts/lua";
interface ConduitData {
    ranks: LuaArray<number>;
}`,
    ];
    lines.push("export const conduits: LuaArray<ConduitData> = {");
    for (const [id, conduit] of dbc.conduitById.entries()) {
        lines.push(`[${id}]: {`);
        lines.push(`   ranks: {`);
        for (const rank of conduit.ranks) {
            lines.push(`      [${rank.rank}]: ${rank.value},`);
        }
        lines.push(`   },`);
        lines.push(`},`);
    }
    lines.push("};");
    writeFileSync("src/engine/dbc.ts", lines.join("\n"), { encoding: "utf8" });
}
