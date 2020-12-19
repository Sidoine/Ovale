import { SpellInfoProperty } from "../../engine/data";
import {
    CustomAura,
    CustomAuras,
    CustomItemData,
    CustomSpellData,
} from "./customspell";
import { DbcData, SpellData } from "./importspells";

function getTooltip(spell: CustomSpellData | SpellData) {
    return spell.tooltip && spell.tooltip.replace(/[$\\{}%]/g, "");
}

export function getDesc(spell: CustomSpellData | SpellData) {
    return spell.desc && spell.desc.replace(/[$\\{}%]/g, "");
}

function getBuffDefinition(
    spellData: DbcData,
    identifier: string,
    target: keyof CustomAuras,
    customAura: CustomAura
) {
    const spell = spellData.spellDataById.get(customAura.id);
    if (!spell) return `# Unknown spell id ${customAura.id}`;
    let ret = "";
    if (spell.tooltip) {
        ret = `  # ${getTooltip(spell)}\n`;
    }
    if (target === "player") {
        return `${ret}  SpellAddBuff(${identifier} ${spell.identifier} add=${customAura.stacks})`;
    }
    return `${ret}  SpellAddTargetDebuff(${identifier} ${spell.identifier} add=${customAura.stacks})`;
}

export function getDefinition(
    spellData: DbcData,
    identifier: string,
    customSpellData: CustomSpellData,
    talentIds: number[],
    spellIds: number[]
) {
    let output = customSpellData.desc ? `# ${getDesc(customSpellData)}\n` : "";
    if (customSpellData.nextRank) {
        const nextRank = spellData.spellDataById.get(customSpellData.nextRank);
        if (nextRank && nextRank.desc) {
            output += `# ${nextRank.rank_str}: ${getDesc(nextRank)}\n`;
        }
    }

    output += `  SpellInfo(${identifier}`;
    for (const key in customSpellData.spellInfo) {
        if (key === "require") continue;
        output += ` ${key}=${
            customSpellData.spellInfo[key as SpellInfoProperty]
        }`;
    }

    output += `)\n`;

    for (const require of customSpellData.require) {
        let parameter;
        if (require.talentId) {
            parameter = spellData.talentsById.get(require.talentId)?.identifier;
            talentIds.push(require.talentId);
        } else if (require.specializationName) {
            parameter = require.specializationName.join(" ");
        }
        output += `  SpellRequire(${customSpellData.identifier} ${
            require.property
        } set=${require.value} enabled=(${require.not ? "not " : ""}${
            require.condition
        }(${parameter ?? ""})))\n`;
    }

    const auras = customSpellData.auras;
    if (auras) {
        for (const key in auras) {
            const k = key as keyof CustomAuras;
            const aura = auras[k];
            if (aura) {
                output += aura
                    .filter((x) => spellIds.indexOf(x.id) >= 0)
                    .map((x) => getBuffDefinition(spellData, identifier, k, x))
                    .join("\n");
                output += "\n";
            }
        }
    }
    return output;
}

export function getItemProps(itemData: CustomItemData) {
    let output = "";
    for (const key in itemData.itemInfo) {
        if (key === "require") continue;
        output += ` ${key}=${itemData.itemInfo[key as SpellInfoProperty]}`;
    }
    return output;
}

export function getItemDefinition(itemData: CustomItemData) {
    let output = getItemProps(itemData);
    if (output.length > 0) {
        return `    ItemInfo(${itemData.identifier}${output})`;
    }
    return undefined;
}
