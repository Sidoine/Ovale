import { readdirSync, readFileSync, writeFileSync } from "fs";
import { join, parse, normalize, dirname } from "path";
import { LocalizationStrings } from "../ui/localization/definition";

const basePath = "src/ui/localization/source";
const dir = readdirSync(basePath);
for (const file of dir) {
    const path = join(basePath, file);
    const data = readFileSync(path, { encoding: "utf8" });
    if (data) {
        const { name } = parse(file);
        const json: LocalizationStrings = JSON.parse(data);
        const functionName = name.replace("-", "").toUpperCase();
        const text = `import { LocalizationStrings } from "./definition";

export function set${functionName}(L: LocalizationStrings) {
    ${Object.entries(json)
        .map(([key, value]) => `L.${key} = \`${value}\`;\n`)
        .join("")}
}`;
        const output = normalize(`${dirname(path)}/../${name}.ts`);
        writeFileSync(output, text, { encoding: "utf8" });
    }
}
