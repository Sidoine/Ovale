// A tool to extract the interfaces from the DBC files
// Outputed to src/utils/importsimc/types.ts
// Will be used by the importsimc tool

import { execSync } from "child_process";
import { readFileSync, writeFileSync } from "fs";
import { chdir, cwd, exit } from "process";

const simcPath = process.argv[2];
if (!simcPath) {
    console.error("usage: yarn dbc ../simc");
    exit(1);
}
const dbcExtract3 = `${simcPath}/dbc_extract3`;
// TODO get last versions
const version = "9.1.0.39497";
const lastFormat = "9.1.0.38783";

const currentDir = cwd();
chdir(dbcExtract3);
execSync(
    `py -3 dbc_extract.py -p ../casc_extract/wow/${version}/DBFilesClient -b ${version} --hotfix=cache/live/DBCache.bin -t csv SpellShapeshift > SpellShapeshift.csv`
);
chdir(currentDir);

const json = readFileSync(`${dbcExtract3}/formats/${lastFormat}.json`, {
    encoding: "utf8",
});

interface DbcField {
    data_type: "f" | "F" | "S" | "i" | "H" | "h" | "I" | "B" | "s" | "b";
    field: string;
    ref?: string;
    elements?: number;
}

interface Dbc {
    parent?: string;
    fields: DbcField[];
}

const data = JSON.parse(json) as Record<string, Dbc>;

function outputType(field: DbcField) {
    switch (field.data_type) {
        case "B":
        case "b":
            return "unknown";
        case "H":
        case "h":
        case "F":
        case "f":
        case "I":
        case "i":
            return "number";
        case "s":
        case "S":
            return "string";
    }
}

function outputField(field: DbcField) {
    if (field.elements) {
        const fields: string[] = [];
        for (let i = 1; i <= field.elements; i++) {
            fields.push(`    ${field.field}_${i}: ${outputType(field)}`);
        }
        return fields.join(";\n");
    }
    return `    ${field.field}: ${outputType(field)}`;
}

function outputDbc(name: string, dbc: Dbc) {
    return `export interface ${name} {
${
    dbc.fields.every((x) => x.field !== "id") ? "    id: number;\n" : ""
}${dbc.fields.map(outputField).join(";\n")};
${dbc.parent ? "    parent_id: number;\n" : ""}}`;
}

const result = Object.entries(data)
    .map(([x, dbc]) => outputDbc(x, dbc))
    .join("\n\n");
writeFileSync("./src/utils/importsimc/types.ts", result, { encoding: "utf8" });
