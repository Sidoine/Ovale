import { readFileSync, writeFileSync } from "fs";

const simc_path = "../../simc";
const dbc_extract3 = `${simc_path}/dbc_extract3`;
const version = "9.0.2.36165";
const json = readFileSync(`${dbc_extract3}/formats/${version}.json`, {
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
            return "any";
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
        let fields: string[] = [];
        for (let i = 1; i <= field.elements; i++) {
            fields.push(`    ${field.field}_${i}: ${outputType(field)}`);
        }
        return fields.join(";\n");
    }
    return `   ${field.field}: ${outputType(field)}`;
}

function outputDbc(name: string, dbc: Dbc) {
    return `export interface ${name} {
${dbc.fields.every((x) => x.field !== "id") ? "   id: number," : ""}
${dbc.fields.map(outputField).join(";\n")},
${dbc.parent ? "   parent_id: number," : ""}
}`;
}

const result = Object.entries(data)
    .map(([x, dbc]) => outputDbc(x, dbc))
    .join("\n\n");
writeFileSync("./src/utils/types.ts", result, { encoding: "utf8" });
