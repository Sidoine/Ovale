import {
    SpellData,
    PowerType,
    SpellPowerData,
    SpellAttributes,
    EffectType,
    isFriendlyTarget,
    ItemData,
    TalentData,
    SpellAttribute,
} from "./importspells";
import { writeFileSync } from "fs";
import { SpellInfo } from "../../engine/data";
import { PowerType as OvalePowerType } from "../../states/Power";
import { debug } from "console";

export interface CustomAura {
    id: number;
    stacks: number;
}

export interface CustomAuras {
    player?: CustomAura[];
    target?: CustomAura[];
}

export interface CustomSpellDataIf {
    conditions?: string;
    spellInfo?: SpellInfo;
}

export interface CustomSpellHasTalent {
    condition: "hastalent";
    talent: TalentData;
}

export interface CustomSpellSealthed {
    condition: "stealthed";
}

export interface CustomSpellSpecialization {
    condition: "specialization";
    specializationName: string;
}

export type CustomSpellRequireCondition =
    | CustomSpellHasTalent
    | CustomSpellSpecialization
    | CustomSpellSealthed;

export interface CustomSpellRequire {
    property: keyof SpellInfo;
    value: string | number;
    not?: boolean;
    conditions: CustomSpellRequireCondition[];
}

export interface CustomSpellData {
    id: number;
    identifier: string;
    desc?: string;
    tooltip?: string;
    spellInfo: SpellInfo;
    auras?: CustomAuras;
    customSpellInfo?: SpellInfo;
    nextRank?: number;
    require: CustomSpellRequire[];
}

function getPowerName(power: PowerType): OvalePowerType | "runes" | "health" {
    switch (power) {
        case PowerType.POWER_ASTRAL_POWER:
            return "lunarpower";
        case PowerType.POWER_CHI:
            return "chi";
        case PowerType.POWER_COMBO_POINT:
            return "combopoints";
        case PowerType.POWER_ENERGY:
            return "energy";
        case PowerType.POWER_FOCUS:
            return "focus";
        case PowerType.POWER_FURY:
            return "fury";
        case PowerType.POWER_HEALTH:
            return "health";
        case PowerType.POWER_HOLY_POWER:
            return "holypower";
        case PowerType.POWER_INSANITY:
            return "insanity";
        case PowerType.POWER_MAELSTROM:
            return "maelstrom";
        case PowerType.POWER_MANA:
            return "mana";
        case PowerType.POWER_PAIN:
            return "pain";
        case PowerType.POWER_RAGE:
            return "rage";
        case PowerType.POWER_RUNE:
            return "runes";
        case PowerType.POWER_RUNIC_POWER:
            return "runicpower";
        case PowerType.POWER_SOUL_SHARDS:
            return "soulshards";
        case PowerType.POWER_ARCANE_CHARGES:
            return "arcanecharges";
        default:
            throw Error(`Unknown power type ${power}`);
    }
}

function getPowerDataValue(
    powerData: SpellPowerData,
    property: keyof SpellPowerData
) {
    return getPowerValue(powerData.power_type, powerData[property]);
}

function getPowerValue(powerType: PowerType, cost: number) {
    let divisor = 1;
    switch (powerType) {
        case PowerType.POWER_MANA:
            divisor = 100;
            break;
        case PowerType.POWER_RAGE:
        case PowerType.POWER_RUNIC_POWER:
        case PowerType.POWER_BURNING_EMBER:
        case PowerType.POWER_ASTRAL_POWER:
        case PowerType.POWER_PAIN:
        case PowerType.POWER_SOUL_SHARDS:
            divisor = 10;
            break;
        case PowerType.POWER_INSANITY:
            divisor = 100;
            break;
        //case PowerType.POWER_DEMONIC_FURY:
        // return percentage ? 0.1 : 1.0;
    }
    return cost / divisor;
}

function hasAttribute(spell: SpellData, attribute: SpellAttributes) {
    const i = Math.floor(attribute / 32);
    const bit = attribute % 32;
    return (spell.attributes[i] & (1 << bit)) > 0;
}

function getConditions(spell: SpellData) {
    let conditions: CustomSpellRequireCondition[] = [];
    if (spell.talent) {
        for (const talent of spell.talent) {
            conditions.push({
                condition: "hastalent",
                talent,
            });
        }
    }
    if (spell.specializations) {
        for (const specializationName of spell.specializations) {
            conditions.push({
                condition: "specialization",
                specializationName,
            });
        }
    }
    return conditions;
}

export function convertFromSpellData(
    spell: SpellData,
    spellDataById: Map<number, SpellData>
) {
    const spellInfo: SpellInfo = { require: {} };
    if (spell.spellPowers) {
        for (const power of spell.spellPowers) {
            const powerName = getPowerName(power.power_type);
            if (power.cost) {
                spellInfo[powerName] = getPowerDataValue(power, "cost");
            }
            if (power.cost_max) {
                spellInfo[`max_${powerName}` as `max_${OvalePowerType}`] =
                    getPowerDataValue(power, "cost_max");
            }
        }
    }
    if (spell.cooldown) {
        spellInfo.cd = spell.cooldown / 1000;
    }
    if (spell.charge_cooldown) {
        spellInfo.cd = spell.charge_cooldown / 1000;
    }
    if (spell.duration && spell.duration > 0) {
        spellInfo.duration = spell.duration / 1000;
    }
    if (
        hasAttribute(spell, SpellAttributes.SX_CHANNELED) ||
        hasAttribute(spell, SpellAttributes.SX_CHANNELED_2)
    ) {
        spellInfo.channel = spell.duration / 1000;
    }

    const require: CustomSpellRequire[] = [];

    if (
        hasAttribute(spell, SpellAttributes.SX_REQ_STEALTH) ||
        spell.shapeshifts?.some((x) => x.flags_1 === 536870912)
    ) {
        require.push({
            conditions: [{ condition: "stealthed" }],
            property: "unusable",
            value: 1,
            not: true,
        });
    }

    if (spell.max_stack) {
        spellInfo.max_stacks = spell.max_stack;
    }

    if (spell.gcd !== 1500) {
        spellInfo.gcd = spell.gcd / 1000;
        if (spell.gcd === 0) {
            spellInfo.offgcd = 1;
        }
    }

    let tick = 0;
    if (spell.spellEffects) {
        for (const effect of spell.spellEffects) {
            if (effect.type === EffectType.E_ENERGIZE) {
                spellInfo[getPowerName(effect.misc_value)] = -getPowerValue(
                    effect.misc_value,
                    effect.base_value
                );
            } else if (effect.type === EffectType.E_INTERRUPT_CAST) {
                spellInfo.interrupt = 1;
            }
            if (effect.amplitude > 0) {
                tick = effect.amplitude / 1000;
            }
        }
    }
    if (tick > 0) {
        spellInfo.tick = tick;
    }

    if (
        spell.spellAttributes.includes(SpellAttribute.Passive) &&
        !spell.identifier.endsWith("buff")
    )
        spellInfo.unusable = 1;

    let buffAdded = false;
    let debuffAdded = false;
    if (spell.name === "Arcane Intellect") {
        debug;
    }
    const playerAuras: CustomAura[] = [];
    const targetAuras: CustomAura[] = [];
    if (spell.spellEffects && !spell.triggered_by) {
        for (const effect of spell.spellEffects) {
            if (effect.trigger_spell_id) {
                const triggeredSpell = spellDataById.get(
                    effect.trigger_spell_id
                );
                if (!triggeredSpell) continue;
                if (
                    hasAttribute(triggeredSpell, SpellAttributes.SX_HIDDEN) ||
                    !triggeredSpell.tooltip
                )
                    continue;

                if (isFriendlyTarget(effect.targeting_1)) {
                    if (
                        playerAuras.every(
                            (x) => x.id !== effect.trigger_spell_id
                        )
                    )
                        playerAuras.push({
                            id: effect.trigger_spell_id,
                            stacks: 1,
                        });
                } else {
                    if (
                        targetAuras.every(
                            (x) => x.id !== effect.trigger_spell_id
                        )
                    )
                        targetAuras.push({
                            id: effect.trigger_spell_id,
                            stacks: 1,
                        });
                }
            } else if (
                effect.type === EffectType.E_APPLY_AURA &&
                spell.tooltip
            ) {
                if (isFriendlyTarget(effect.targeting_1)) {
                    if (!buffAdded) {
                        buffAdded = true;
                        playerAuras.push({ id: spell.id, stacks: 1 });
                    }
                } else if (!debuffAdded) {
                    debuffAdded = true;
                    targetAuras.push({ id: spell.id, stacks: 1 });
                }
            }
        }
    }

    if (!buffAdded && !debuffAdded && spell.tooltip && !spell.triggered_by) {
        playerAuras.push({ id: spell.id, stacks: 1 });
    }

    const auras: CustomAuras = {};
    if (playerAuras.length > 0) auras.player = playerAuras;
    if (targetAuras.length > 0) auras.target = targetAuras;

    if (spell.talent || spell.specializationName.length > 0) {
        const conditions = getConditions(spell);
        if (conditions.some((x) => x.condition !== "specialization")) {
            require.push({
                conditions,
                property: "unusable",
                value: 1,
                not: true,
            });
        }
    }

    if (spell.replaced_by) {
        for (const replacedById of spell.replaced_by) {
            const replacedBy = spellDataById.get(replacedById);
            if (!replacedBy) throw Error(`Spell ${replacedById} not found`);
            const conditions = getConditions(replacedBy);
            if (conditions.length === 0) {
                throw Error(
                    `Unknown replace condition in ${replacedBy.name} [${replacedBy.id}]`
                );
            }

            require.push({
                conditions,
                property: "replaced_by",
                value: replacedBy.identifier,
            });
        }
    }

    const customSpellData: CustomSpellData = {
        id: spell.id,
        identifier: spell.identifier,
        desc: spell.desc,
        spellInfo: spellInfo,
        auras: auras,
        tooltip: spell.tooltip ? spell.tooltip : undefined,
        nextRank: spell.nextRank ? spell.nextRank.id : undefined,
        require,
    };
    return customSpellData;
}

export interface CustomItemData {
    id: number;
    identifier: string;
    itemInfo: SpellInfo;
}

export function convertFromItemData(
    itemData: ItemData,
    spellDataById: Map<number, SpellData>
) {
    const itemInfo: SpellInfo = { require: {} };
    for (const effect of itemData.itemEffects) {
        if (effect.cooldown_duration > 0)
            itemInfo.cd = effect.cooldown_duration / 1000;
        if (effect.cooldown_group_duration > 0)
            itemInfo.cd = effect.cooldown_group_duration / 1000;
        if (effect.cooldown_group > 0)
            itemInfo.shared_cd = `item_cd_${effect.cooldown_group}`;
        if (effect.spell_id) {
            const spell = spellDataById.get(effect.spell_id);
            if (spell) {
                if (spell.cooldown > 0) {
                    itemInfo.cd = spell.cooldown / 1000;
                }
                if (spell.internal_cooldown > 0) {
                    itemInfo.icd = spell.internal_cooldown / 1000;
                }
                if (spell.rppm > 0) {
                    itemInfo.rppm = spell.rppm;
                }
            }
            itemInfo.proc = effect.spell_id;
        }
    }

    const customItemData: CustomItemData = {
        id: itemData.id,
        identifier: itemData.identifier,
        itemInfo,
    };
    return customItemData;
}

export function writeCustomSpell(
    spells: SpellData[],
    className: string,
    spellDataById: Map<number, SpellData>
) {
    const customSpells: { [k: string]: CustomSpellData } = {};
    const spellIdentifiers: string[] = [];
    // Write custom spell info
    for (const spell of spells) {
        customSpells[spell.identifier] = convertFromSpellData(
            spell,
            spellDataById
        );
        spellIdentifiers.push(spell.identifier);
    }

    const output = `import { CustomSpellData} from "../customspell";
export type SpellIdentifiers = "${spellIdentifiers.join('" | "')}";
export const customSpellData: { [k in SpellIdentifiers]: CustomSpellData } = 
${JSON.stringify(customSpells, undefined, 4)}
;`;

    writeFileSync(`src/utils/override/${className.toLowerCase()}.ts`, output, {
        encoding: "utf8",
    });
}
