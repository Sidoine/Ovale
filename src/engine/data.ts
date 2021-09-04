import {
    type,
    ipairs,
    pairs,
    wipe,
    truthy,
    LuaArray,
    LuaObj,
} from "@wowts/lua";
import { find } from "@wowts/string";
import { isNumber, oneTimeMessage } from "../tools/tools";
import { HasteType } from "../states/PaperDoll";
import { PowerType } from "../states/Power";
import { GetSpellInfo, SpellId } from "@wowts/wow-mock";
import {
    AstItemRequireNode,
    AstSpellAuraListNode,
    AstSpellRequireNode,
} from "./ast";
import { Runner } from "./runner";
import { OptionUiAll } from "../ui/acegui-helpers";
import { concat, insert } from "@wowts/table";
import { DebugTools } from "./debug";

const bloodelfClasses: LuaObj<boolean> = {
    ["DEATHKNIGHT"]: true,
    ["DEMONHUNTER"]: true,
    ["DRUID"]: false,
    ["HUNTER"]: true,
    ["MAGE"]: true,
    ["MONK"]: true,
    ["PALADIN"]: true,
    ["PRIEST"]: true,
    ["ROGUE"]: true,
    ["SHAMAN"]: false,
    ["WARLOCK"]: true,
    ["WARRIOR"]: true,
};
const pandarenClasses: LuaObj<boolean> = {
    ["DEATHKNIGHT"]: false,
    ["DEMONHUNTER"]: false,
    ["DRUID"]: false,
    ["HUNTER"]: true,
    ["MAGE"]: true,
    ["MONK"]: true,
    ["PALADIN"]: false,
    ["PRIEST"]: true,
    ["ROGUE"]: true,
    ["SHAMAN"]: true,
    ["WARLOCK"]: false,
    ["WARRIOR"]: true,
};
const taurenClasses: LuaObj<boolean> = {
    ["DEATHKNIGHT"]: true,
    ["DEMONHUNTER"]: false,
    ["DRUID"]: true,
    ["HUNTER"]: true,
    ["MAGE"]: false,
    ["MONK"]: true,
    ["PALADIN"]: true,
    ["PRIEST"]: true,
    ["ROGUE"]: false,
    ["SHAMAN"]: true,
    ["WARLOCK"]: false,
    ["WARRIOR"]: true,
};
const statNames: LuaArray<string> = {
    1: "agility",
    2: "bonus_armor",
    3: "critical_strike",
    4: "haste",
    5: "intellect",
    6: "mastery",
    7: "spirit",
    8: "spellpower",
    9: "strength",
    10: "versatility",
};
const startShortNames: LuaObj<string> = {
    agility: "agi",
    critical_strike: "crit",
    intellect: "int",
    strength: "str",
    spirit: "spi",
};
const statUseNames: LuaArray<string> = {
    1: "trinket_proc",
    2: "trinket_stacking_proc",
    3: "trinket_stacking_stat",
    4: "trinket_stat",
    5: "trinket_stack_proc",
};

type SpellAuraInfo = AstSpellAuraListNode;

type SpellAddAurasById = {
    [key: number]: SpellAuraInfo;
    [key: string]: SpellAuraInfo;
};

export interface SpellAddAurasByType {
    HARMFUL: SpellAddAurasById;
    HELPFUL: SpellAddAurasById;
}

export type AuraType = keyof SpellAddAurasByType;

export interface SpellAddAuras {
    damage: SpellAddAurasByType;
    pet: SpellAddAurasByType;
    target: SpellAddAurasByType;
    player: SpellAddAurasByType;
}

//type Auras = LuaObj<LuaObj<LuaArray<SpellData>>>;

export type SpellInfoProperty = keyof SpellInfoValues;

type SpellInfoPowerValues = {
    [K in PowerType]?: number;
};

type SpellInfoPowerSetValues = {
    [K in PowerType as `set_${K}`]?: number;
};

type SpellInfoPowerMaxValues = {
    [K in PowerType as `max_${K}`]?: number;
};

type SpellInfoPowerRefundValues = {
    [K in PowerType as `refund_${K}`]?: number | "cost";
};

export interface SpellInfoValues
    extends SpellInfoPowerValues,
        SpellInfoPowerSetValues,
        SpellInfoPowerMaxValues,
        SpellInfoPowerRefundValues {
    duration?: number;
    add_duration_combopoints?: number;
    half_duration?: number;
    tick?: number;
    stacking?: number;
    max_stacks?: number;
    // stat?: string | LuaArray<string>;
    // buff?: number | LuaArray<number>;
    // Cooldown
    gcd?: number;
    shared_cd?: string;
    cd?: number;
    /** Internal cooldown (mainly on items) */
    icd?: number;
    rppm?: number;
    charge_cd?: number;
    forcecd?: number;
    buff_cd?: number; // Internal cooldown, rename?
    buff_cdr?: number; // Cooldown reduction TODO
    // Haste
    haste?: HasteType;
    cd_haste?: string;
    gcd_haste?: HasteType;
    // Damage Calculations
    bonusmainhand?: number;
    bonusoffhand?: number;
    bonuscp?: number;
    bonusap?: number;
    bonusapcp?: number;
    bonussp?: number;
    damage?: number;
    base?: number; // base damage
    physical?: number;
    // Icon
    tag?: string;
    texture?: string;
    // Spells
    replaced_by?: number;
    max_travel_time?: number;
    travel_time?: number;
    canStopChannelling?: number;
    channel?: number;
    unusable?: number;
    to_stance?: number;
    // Totems
    totem?: number;
    buff_totem?: number;
    max_totems?: number;
    // (custom) Counter
    inccounter?: number;
    resetcounter?: number;
    runes?: number;
    interrupt?: number;
    add_duration?: number;
    add_cd?: number;
    // flash?:boolean;
    // target?:string;
    // soundtime?:number;
    // enemies?:number;
    offgcd?: number;
    casttime?: number;
    health?: number;

    addlist?: string;
    dummy_replace?: string;
    learn?: number;
    pertrait?: number;
    proc?: number;
    effect?: "HELPFUL" | "HARMFUL";
}

export type SpellInfoNumberProperty = {
    [k in keyof Required<SpellInfoValues>]: Required<SpellInfoValues>[k] extends number
        ? k
        : never;
}[keyof SpellInfoValues];

export interface SpellInfo extends SpellInfoValues {
    //[key:string]: LuaObj<Requirements> | number | string | LuaArray<string> | LuaArray<number> | Auras;
    require: {
        [k in SpellInfoProperty]?: LuaArray<
            AstSpellRequireNode | AstItemRequireNode
        >;
    };
    // Aura
    aura?: SpellAddAuras;
}

interface SpellDebug {
    auraSeen?: boolean;
    spellCast?: boolean;
    auraAsked?: boolean;
    spellAsked?: boolean;
}

export class OvaleDataClass {
    statNames = statNames;
    shortNames = startShortNames;
    statUseNames = statUseNames;
    bloodElfClasses = bloodelfClasses;
    pandarenClasses = pandarenClasses;
    taurenClasses = taurenClasses;
    itemInfo: LuaArray<SpellInfo> = {};
    itemList: LuaObj<LuaArray<number>> = {};
    spellInfo: LuaObj<SpellInfo> = {};
    private spellDebug: LuaObj<Record<number, SpellDebug>> = {};

    private debugOptions: LuaObj<OptionUiAll> = {
        data: {
            name: "Data",
            type: "group",
            args: {
                spells: {
                    name: "Spell data",
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: (info: LuaArray<string>) => {
                        const array: LuaArray<string> = {};
                        const properties: LuaArray<string> = {};
                        for (const [spellName, spellNameDebug] of pairs(
                            this.spellDebug
                        )) {
                            let display = false;
                            for (const [, spellDebug] of pairs(
                                spellNameDebug
                            )) {
                                if (
                                    spellDebug.auraAsked ||
                                    spellDebug.spellAsked
                                ) {
                                    display = true;
                                    break;
                                }
                            }
                            if (display) {
                                insert(array, `${spellName}:`);

                                for (const [spellId, spellDebug] of pairs(
                                    spellNameDebug
                                )) {
                                    wipe(properties);
                                    if (spellDebug.auraAsked)
                                        insert(properties, "aura asked");
                                    if (spellDebug.auraSeen)
                                        insert(properties, "aura seen");
                                    if (spellDebug.spellAsked)
                                        insert(properties, "spell asked");
                                    if (spellDebug.spellCast)
                                        insert(properties, "spell cast");
                                    insert(
                                        array,
                                        `  ${spellId}: ${concat(
                                            properties,
                                            ", "
                                        )}`
                                    );
                                }
                            }
                        }
                        return concat(array, "\n");
                    },
                },
            },
        },
    };

    buffSpellList: LuaObj<LuaArray<boolean>> = {
        attack_power_multiplier_buff: {
            [SpellId.battle_shout]: true,
        },
        critical_strike_buff: {
            [SpellId.arcane_intellect]: true,
        },
        haste_buff: {},
        mastery_buff: {},
        spell_power_multiplier_buff: {
            [SpellId.arcane_intellect]: true,
        },
        stamina_buff: {
            [SpellId.power_word_fortitude]: true,
        },
        str_agi_int_buff: {},
        versatility_buff: {},
        bleed_debuff: {
            [SpellId.bloodbath_debuff]: true,
            [SpellId.crimson_tempest]: true,
            [SpellId.deep_wounds_debuff]: true,
            [SpellId.garrote]: true,
            [SpellId.internal_bleeding_debuff]: true,
            [SpellId.rake_debuff]: true,
            [SpellId.rend]: true,
            [SpellId.rip]: true,
            [SpellId.rupture]: true,
            [SpellId.thrash_debuff]: true,
            [SpellId.serrated_bone_spike]: true,
        },
        healing_reduced_debuff: {
            [8680]: true, // Wound Poison debuff
            [SpellId.mortal_wounds_debuff]: true,
        },
        stealthed_buff: {
            [SpellId.incarnation_king_of_the_jungle]: true,
            [SpellId.prowl]: true,
            [SpellId.shadowmeld]: true,
            [SpellId.shadow_dance_buff]: true,
            [SpellId.stealth]: true,
            [SpellId.subterfuge_buff]: true,
            [SpellId.vanish]: true,
            [11327]: true, // Vanish buff
            [115191]: true, // Stealth (Subterfuge)
            [115193]: true, // Vanish buff
            [347037]: true, // Sepsis debuff
        },
        rogue_stealthed_buff: {
            [SpellId.stealth]: true,
            [SpellId.shadow_dance_buff]: true,
            [SpellId.subterfuge_buff]: true,
            [SpellId.vanish]: true,
            [11327]: true, // Vanish buff
            [115191]: true, // Stealth (Subterfuge)
            [115193]: true, // Vanish buff
            [347037]: true, // Sepsis debuff
        },
        mantle_stealthed_buff: {
            [SpellId.stealth]: true,
            [SpellId.vanish]: true,
            [11327]: true, // Vanish buff
            [115193]: true, // Vanish buff
        },
        burst_haste_buff: {
            [SpellId.bloodlust]: true,
            [SpellId.drums_of_deathly_ferocity]: true,
            [SpellId.drums_of_fury]: true,
            [SpellId.drums_of_rage]: true,
            [SpellId.drums_of_the_maelstrom]: true,
            [SpellId.drums_of_the_mountain]: true,
            [SpellId.heroism]: true,
            [SpellId.primal_rage_pet]: true,
            [SpellId.time_warp]: true,
        },
        burst_haste_debuff: {
            [SpellId.exhaustion_debuff]: true,
            [SpellId.sated_debuff]: true,
            [SpellId.temporal_displacement_debuff]: true,
        },
        raid_movement_buff: {
            [SpellId.stampeding_roar]: true,
            [SpellId.wind_rush_buff]: true,
        },
        roll_the_bones_buff: {
            [SpellId.broadside_buff]: true,
            [SpellId.buried_treasure_buff]: true,
            [SpellId.grand_melee_buff]: true,
            [SpellId.ruthless_precision_buff]: true,
            [SpellId.skull_and_crossbones_buff]: true,
            [SpellId.true_bearing_buff]: true,
        },
        lethal_poison_buff: {
            [SpellId.deadly_poison]: true,
            [SpellId.instant_poison]: true,
            [SpellId.wound_poison]: true,
        },
        non_lethal_poison_buff: {
            [SpellId.crippling_poison]: true,
            [SpellId.numbing_poison]: true,
        },
    };
    constructor(private runner: Runner, ovaleDebug: DebugTools) {
        for (const [, useName] of pairs(statUseNames)) {
            let name;
            for (const [, statName] of pairs(statNames)) {
                name = `${useName}_${statName}_buff`;
                this.buffSpellList[name] = {};
                const shortName = startShortNames[statName];
                if (shortName) {
                    name = `${useName}_${shortName}_buff`;
                    this.buffSpellList[name] = {};
                }
            }
            name = `${useName}_any_buff`;
            this.buffSpellList[name] = {};
        }

        {
            for (const [name] of pairs(this.buffSpellList)) {
                this.defaultSpellLists[name] = true;
            }
        }

        for (const [k, v] of pairs(this.debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }
    }

    private getSpellDebug(spellId: number) {
        let [spellName] = GetSpellInfo(spellId);
        if (!spellName) spellName = "unknown";

        let spellDebugName = this.spellDebug[spellName];
        if (!spellDebugName) {
            spellDebugName = {};
            this.spellDebug[spellName] = spellDebugName;
        }
        let spellDebug = spellDebugName[spellId];
        if (!spellDebug) {
            spellDebug = {};
            spellDebugName[spellId] = spellDebug;
        }
        return spellDebug;
    }

    registerSpellCast(spellId: number) {
        this.getSpellDebug(spellId).spellCast = true;
    }

    registerAuraSeen(spellId: number) {
        this.getSpellDebug(spellId).auraSeen = true;
    }

    registerAuraAsked(spellId: number) {
        this.getSpellDebug(spellId).auraAsked = true;
    }

    registerSpellAsked(spellId: number) {
        this.getSpellDebug(spellId).spellAsked = true;
    }

    defaultSpellLists: LuaObj<boolean> = {};

    reset() {
        wipe(this.itemInfo);
        wipe(this.spellInfo);
        for (const [k, v] of pairs(this.buffSpellList)) {
            if (!this.defaultSpellLists[k]) {
                wipe(v);
                delete this.buffSpellList[k];
            } else if (truthy(find(k, "^trinket_"))) {
                wipe(v);
            }
        }
    }
    getSpellInfo(spellId: number) {
        let si = this.spellInfo[spellId];
        if (!si) {
            si = {
                aura: {
                    player: {
                        HELPFUL: {},
                        HARMFUL: {},
                    },
                    target: {
                        HELPFUL: {},
                        HARMFUL: {},
                    },
                    pet: {
                        HELPFUL: {},
                        HARMFUL: {},
                    },
                    damage: {
                        HELPFUL: {},
                        HARMFUL: {},
                    },
                },
                require: {},
            };
            this.spellInfo[spellId] = si;
        }
        return si;
    }
    getSpellOrListInfo(spellId: number | string) {
        if (type(spellId) == "number") {
            return this.spellInfo[spellId];
        } else if (this.buffSpellList[spellId]) {
            for (const [auraId] of pairs(this.buffSpellList[spellId])) {
                if (this.spellInfo[auraId]) {
                    return this.spellInfo[auraId];
                }
            }
        }
    }
    getItemInfo(itemId: number) {
        let ii = this.itemInfo[itemId];
        if (!ii) {
            ii = {
                require: {},
            };
            this.itemInfo[itemId] = ii;
        }
        return ii;
    }
    getItemTagInfo(spellId: number | string): [string, boolean] {
        return ["cd", false];
    }
    getSpellTagInfo(spellId: number | string): [string, boolean] {
        let tag: string | undefined = "main";
        let invokesGCD = true;
        const si = this.spellInfo[spellId];
        if (si) {
            invokesGCD = !si.gcd || si.gcd > 0;
            tag = si.tag;
            if (!tag) {
                const cd = si.cd;
                if (cd) {
                    if (cd > 90) {
                        tag = "cd";
                    } else if (cd > 29 || !invokesGCD) {
                        tag = "shortcd";
                    }
                } else if (!invokesGCD) {
                    tag = "shortcd";
                }
                si.tag = tag;
            }
            tag = tag || "main";
        }
        return [tag, invokesGCD];
    }

    checkSpellAuraData(
        auraId: number | string,
        spellData: SpellAuraInfo,
        atTime: number,
        guid: string | undefined
    ) {
        const [, named] = this.runner.computeParameters(spellData, atTime);
        return named;
    }

    // CheckSpellInfo(
    //     spellId: number,
    //     atTime: number,
    //     targetGUID: string | undefined
    // ): [boolean, string?] {
    //     targetGUID =
    //         targetGUID ||
    //         this.ovaleGuid.UnitGUID(
    //             this.baseState.next.defaultTarget || "target"
    //         );
    //     let verified = true;
    //     let requirement: string | undefined;
    //     for (const [name, handler] of pairs(this.requirement.nowRequirements)) {
    //         let value = this.GetSpellInfoProperty(
    //             spellId,
    //             atTime,
    //             <any>name,
    //             targetGUID
    //         );
    //         if (value) {
    //             if (!isString(value) && isLuaArray<string>(value)) {
    //                 [verified, requirement] = handler(
    //                     spellId,
    //                     atTime,
    //                     name,
    //                     value,
    //                     1,
    //                     targetGUID
    //                 );
    //             } else {
    //                 tempTokens[1] = <string>value;
    //                 [verified, requirement] = handler(
    //                     spellId,
    //                     atTime,
    //                     name,
    //                     tempTokens,
    //                     1,
    //                     targetGUID
    //                 );
    //             }
    //             if (!verified) {
    //                 break;
    //             }
    //         }
    //     }
    //     return [verified, requirement];
    // }
    getItemInfoProperty(
        itemId: number,
        atTime: number,
        property: SpellInfoProperty
    ) {
        const ii = this.getItemInfo(itemId);
        if (ii) {
            return this.getProperty(ii, atTime, property);
        }
        return undefined;
    }
    //GetSpellInfoProperty(spellId, atTime, property:"gcd"|"duration"|"combopoints"|"inccounter"|"resetcounter", targetGUID):number;
    /**
     *
     * @param spellId
     * @param atTime
     * @param property
     * @param targetGUID
     * @param noCalculation Checks only SpellInfo and SpellRequire for the property itself.  No `add_${property}` or `${property}_percent`
     * @returns value or [value, ratio]
     */
    getSpellInfoProperty<T extends SpellInfoProperty>(
        spellId: number,
        atTime: number | undefined,
        property: T,
        targetGUID: string | undefined
    ): SpellInfo[T] {
        const si = this.spellInfo[spellId];
        if (si) {
            return this.getProperty(si, atTime, property);
        }

        return undefined;
    }

    public getProperty<T extends SpellInfoProperty>(
        si: SpellInfo,
        atTime: number | undefined,
        property: T
    ): SpellInfo[T] {
        let value = si[property];
        if (atTime) {
            const requirements:
                | LuaArray<AstSpellRequireNode | AstItemRequireNode>
                | undefined = si.require[property];
            if (requirements) {
                for (const [_, requirement] of ipairs(requirements)) {
                    const [, named] = this.runner.computeParameters(
                        requirement,
                        atTime
                    );
                    if (named.enabled === undefined || named.enabled) {
                        if (named.set !== undefined)
                            value = named.set as SpellInfo[T];

                        if (
                            named.add !== undefined &&
                            isNumber(value) &&
                            isNumber(named.add)
                        ) {
                            value = (value + named.add) as SpellInfo[T];
                        }

                        if (
                            named.percent !== undefined &&
                            isNumber(value) &&
                            isNumber(named.percent)
                        ) {
                            value = ((value * named.percent) /
                                100) as SpellInfo[T];
                        }
                    }
                }
            }
        }
        return value;
    }

    /**
     *
     * @param spellId
     * @param atTime If undefined, will not check SpellRequire
     * @param property
     * @param targetGUID
     * @param splitRatio Split the value and ratio into separate return values instead of multiplying them together
     * @returns value or [value, ratio]
     */
    getSpellInfoPropertyNumber(
        spellId: number,
        atTime: number | undefined,
        property: SpellInfoNumberProperty,
        targetGUID: string | undefined,
        splitRatio?: boolean
    ): number[] {
        const si = this.spellInfo[spellId];
        if (!si) return [];

        const ratioParam = `${property}_percent` as SpellInfoNumberProperty; // TODO TS 4.1
        let ratio = this.getProperty(si, atTime, ratioParam);
        if (ratio !== undefined) {
            ratio = ratio / 100;
        } else {
            ratio = 1;
        }

        let value = this.getProperty(si, atTime, property);

        if (ratio != 0 && value !== undefined) {
            const addParam = `add_${property}` as SpellInfoNumberProperty; // TODO TS 4.1
            const addProperty = this.getProperty(si, atTime, addParam);
            if (addProperty) {
                value = value + addProperty;
            }
        } else {
            // If ratio is 0, value must be 0.
            value = 0;
        }
        if (splitRatio) {
            return [value, ratio];
        }
        return [value * ratio];
    }

    resolveSpell(
        spellId: number,
        atTime: number | undefined,
        targetGUID: string | undefined
    ): number | undefined {
        const maxGuard = 20;
        let guard = 0;
        let nextId;
        let id: number | undefined = spellId;
        while (id && guard < maxGuard) {
            guard += 1;
            nextId = id;
            id = this.getSpellInfoProperty(
                nextId,
                atTime,
                "replaced_by",
                targetGUID
            );
        }
        if (guard >= maxGuard) {
            oneTimeMessage(
                `Recursive 'replaced_by' chain for spell ID '${spellId}'.`
            );
        }
        return nextId;
    }

    getDamage(
        spellId: number,
        attackpower: number,
        spellpower: number,
        mainHandWeaponDPS: number,
        offHandWeaponDPS: number,
        combopoints: number
    ): number | undefined {
        const si = this.spellInfo[spellId];
        if (!si) {
            return undefined;
        }
        let damage = si.base || 0;
        attackpower = attackpower || 0;
        spellpower = spellpower || 0;
        mainHandWeaponDPS = mainHandWeaponDPS || 0;
        offHandWeaponDPS = offHandWeaponDPS || 0;
        combopoints = combopoints || 0;
        if (si.bonusmainhand) {
            damage = damage + si.bonusmainhand * mainHandWeaponDPS;
        }
        if (si.bonusoffhand) {
            damage = damage + si.bonusoffhand * offHandWeaponDPS;
        }
        if (si.bonuscp) {
            damage = damage + si.bonuscp * combopoints;
        }
        if (si.bonusap) {
            damage = damage + si.bonusap * attackpower;
        }
        if (si.bonusapcp) {
            damage = damage + si.bonusapcp * attackpower * combopoints;
        }
        if (si.bonussp) {
            damage = damage + si.bonussp * spellpower;
        }
        return damage;
    }
}
