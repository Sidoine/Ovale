import { writeFileSync } from "fs";
import { DbcData } from "./importspells";

export function writeToWowmock(spellData: DbcData) {
    let spellInfos = `export const spellInfos:{[k: number]: { name: string, castTime: number, minRange: number, maxRange: number }} = {\n`;
    for (const [spellId, data] of spellData.spellDataById) {
        spellInfos += ` 	[${spellId}]: { name: "${data.name}", castTime: ${data.cast_time}, minRange: ${data.min_range}, maxRange: ${data.max_range}},\n`;
    }
    spellInfos += "};";
    spellInfos += `export const enum SpellId {
        ${Array.from(spellData.spellDataById.values())
            .filter(
                (x) =>
                    !x.identifier.match(/_unused/) &&
                    !x.identifier.match(/_(\d)$/)
            )
            .map((x) => ` 	${x.identifier} = ${x.id},`)
            .join("\n")}
}
`;
    writeFileSync("../wow-mock/src/spells.ts", spellInfos, {
        encoding: "utf8",
    });

    const talentInfos = `export const enum TalentId {
${Array.from(spellData.talentsById.values())
    .map((x) => ` 	${x.identifier} = ${x.id},`)
    .join("\n")}
}

export const enum TalentIndex {
${Array.from(spellData.talentsById.values())
    .map((x) => `    ${x.identifier} = ${x.talentId},`)
    .join("\n")}
}
`;

    writeFileSync("../wow-mock/src/talents.ts", talentInfos, {
        encoding: "utf8",
    });
}
