// A tool to extract the interfaces from the DBC files
// Outputed to src/utils/importsimc/types.ts
// Will be used by the importsimc tool

import { execSync } from "child_process";
import { opendirSync, readFileSync, writeFileSync } from "fs";
import { chdir, cwd, exit } from "process";

const doExtract = process.argv[2] !== "--skip-extract";
const simcPath = (doExtract && process.argv[2]) || process.argv[3];
if (!simcPath) {
    console.error("usage: yarn dbc [--skip-extract] ../simc");
    exit(1);
}

function getLatestVersion(path: string) {
    const dir = opendirSync(path);
    let version: string | undefined;
    let buildVersion: number | undefined;
    let dirent = dir.readSync();
    while (dirent) {
        const name = dirent.name;
        // name must be of the form "N.M.n.m"
        if (name.match(/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)) {
            const components = name.match(/\.[0-9]+/g);
            if (components) {
                const index = components.length - 1;
                const build = Number(components[index].substring(1));
                if (buildVersion === undefined || buildVersion < build) {
                    buildVersion = build;
                    version = name;
                }
            }
        }
        dirent = dir.readSync();
    }
    dir.closeSync();
    return version;
}

const cascExtract = `${simcPath}/casc_extract`;
const version = getLatestVersion(`${cascExtract}/wow`);
if (!version) {
    console.error(`error: ${cascExtract}/wow version directory not found`);
    exit(2);
}
const currentDir = cwd();
const dbcExtract3 = `${simcPath}/dbc_extract3`;
if (doExtract) {
    chdir(dbcExtract3);
    execSync(
        `py -3 dbc_extract.py -p ${cascExtract}/wow/${version}/DBFilesClient -b ${version} --hotfix=cache/live/DBCache.bin -t csv SpellShapeshift > SpellShapeshift.csv`
    );
    chdir(currentDir);
}

let lastFormatJson = getLatestVersion(`${dbcExtract3}/formats`);
if (!lastFormatJson) {
    console.error(`error: ${dbcExtract3}/format version directory not found`);
    exit(2);
}
const json = readFileSync(`${dbcExtract3}/formats/${lastFormatJson}`, {
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
