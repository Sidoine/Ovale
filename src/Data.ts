import { OvaleGUIDClass } from "./GUID";
import { OvaleRequirement } from "./Requirement";
import { type, ipairs, pairs, tonumber, wipe, truthy, LuaArray, LuaObj, kpairs } from "@wowts/lua";
import { find } from "@wowts/string";
import { BaseState } from "./BaseState";
import { isLuaArray, isString } from "./tools";
import { HasteType } from "./PaperDoll";
import { Powers } from "./Power";
import { OvaleClass } from "./Ovale";

const BLOODELF_CLASSES: LuaObj<boolean> = {
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
    ["WARRIOR"]: true
}
const PANDAREN_CLASSES: LuaObj<boolean> = {
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
    ["WARRIOR"]: true
}
const TAUREN_CLASSES: LuaObj<boolean> = {
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
    ["WARRIOR"]: true
}
const STAT_NAMES: LuaArray<string> = {
    1: "agility",
    2: "bonus_armor",
    3: "critical_strike",
    4: "haste",
    5: "intellect",
    6: "mastery",
    7: "spirit",
    8: "spellpower",
    9: "strength",
    10: "versatility"
}
const STAT_SHORTNAME: LuaObj<string> = {
    agility: "agi",
    critical_strike: "crit",
    intellect: "int",
    strength: "str",
    spirit: "spi"
}
const STAT_USE_NAMES: LuaArray<string> = {
    1: "trinket_proc",
    2: "trinket_stacking_proc",
    3: "trinket_stacking_stat",
    4: "trinket_stat",
    5: "trinket_stack_proc"
}

type SpellData = number | string | LuaArray<number | string>;
type Requirements = LuaObj<LuaArray<string>>;

type AuraList = { [key: number]: SpellData;[key: string]: SpellData; };

export interface AuraByType {
    HARMFUL: AuraList;
    HELPFUL: AuraList;
}

export type AuraType = keyof AuraByType;

interface Auras
{
    damage: AuraByType;
    pet: AuraByType;
    target: AuraByType;
    player: AuraByType;
}

//type Auras = LuaObj<LuaObj<LuaArray<SpellData>>>;

/** Any <number> in SpellInfo or SpellRequire can include:
 *      `add_${property}`
 *      `${property}_percent`
 */
export interface SpellInfo extends Powers {
    //[key:string]: LuaObj<Requirements> | number | string | LuaArray<string> | LuaArray<number> | Auras;
    require: {[key in keyof SpellInfo]?: Requirements };
    // Aura
    aura?: Auras;
    duration?:number;   
    add_duration_combopoints?:number;
    tick?:number;
    stacking?:number;
    max_stacks?:number;
    stat?:string | LuaArray<string>;
    buff?:number | LuaArray<number>;
    // Cooldown
    gcd?: number;
    shared_cd?:number;
    cd?: number;
    charge_cd?: number;
    forcecd?:number;
    buff_cd?:number; // Internal cooldown, rename?
    buff_cdr?:number; // Cooldown reduction TODO
    // Haste
    haste?:HasteType;
    cd_haste?:string;
    gcd_haste?:HasteType;
    // Damage Calculations
    bonusmainhand?:number;
    bonusoffhand?:number;
    bonuscp?: number;
    bonusap?: number;
    bonusapcp?:number;
    bonussp?:number;
    damage?: number;
    base?:number; // base damage
    physical?:number;
    // Icon
    tag?:string;
    texture?:string;
    // Spells
    replaced_by?:number;
    max_travel_time?:number;
    travel_time?:number;
    canStopChannelling?:number;
    channel?:number;
    unusable?:number;
    to_stance?:number;
    // Totems
    totem?:number;
    buff_totem?:number;
    max_totems?:number;
    // (custom) Counter
    inccounter?:number;
    resetcounter?:number;
    /** Power
     * ${powerType}: number; // Cost of a spell.  ${powerType} = energy, focus, rage, etc.
     */
    runes?:number;
    interrupt?: number;
    add_duration?:number;
    add_cd?:number;
    // nocd?:number;
    // flash?:boolean;
    // target?:string;
    // soundtime?:number;
    // enemies?:number;
    offgcd?: number;
    casttime?: number;
    health?: number;
}

const tempTokens: LuaArray<string> = {};

export class OvaleDataClass {
    STAT_NAMES = STAT_NAMES;
    STAT_SHORTNAME = STAT_SHORTNAME;
    STAT_USE_NAMES = STAT_USE_NAMES;
    BLOODELF_CLASSES = BLOODELF_CLASSES;
    PANDAREN_CLASSES = PANDAREN_CLASSES;
    TAUREN_CLASSES = TAUREN_CLASSES;
    itemInfo: LuaArray<SpellInfo> = {}
    itemList: LuaObj<LuaArray<number>> = {}
    spellInfo: LuaObj<SpellInfo> = {}
    buffSpellList: LuaObj<LuaArray<boolean>> = {
        attack_power_multiplier_buff: {
            [6673]: true,
            [19506]: true,
            [57330]: true
        },
        critical_strike_buff: {
            [1459]: true,
            [24604]: true,
            [24932]: true,
            [61316]: true,
            [90309]: true,
            [90363]: true,
            [97229]: true,
            [116781]: true,
            [126309]: true,
            [126373]: true,
            [128997]: true,
            [160052]: true,
            [160200]: true
        },
        haste_buff: {
            [49868]: true,
            [55610]: true,
            [113742]: true,
            [128432]: true,
            [135678]: true,
            [160003]: true,
            [160074]: true,
            [160203]: true
        },
        mastery_buff: {
            [19740]: true,
            [24907]: true,
            [93435]: true,
            [116956]: true,
            [128997]: true,
            [155522]: true,
            [160073]: true,
            [160198]: true
        },
        spell_power_multiplier_buff: {
            [1459]: true,
            [61316]: true,
            [90364]: true,
            [109773]: true,
            [126309]: true,
            [128433]: true,
            [160205]: true
        },
        stamina_buff: {
            [469]: true,
            [21562]: true,
            [50256]: true,
            [90364]: true,
            [160003]: true,
            [160014]: true,
            [166928]: true,
            [160199]: true
        },
        str_agi_int_buff: {
            [1126]: true,
            [20217]: true,
            [90363]: true,
            [115921]: true,
            [116781]: true,
            [159988]: true,
            [160017]: true,
            [160077]: true,
            [160206]: true
        },
        versatility_buff: {
            [1126]: true,
            [35290]: true,
            [50518]: true,
            [55610]: true,
            [57386]: true,
            [159735]: true,
            [160045]: true,
            [160077]: true,
            [167187]: true,
            [167188]: true,
            [172967]: true
        },
        bleed_debuff: {
            [1079]: true,
            [16511]: true,
            [33745]: true,
            [77758]: true,
            [113344]: true,
            [115767]: true,
            [122233]: true,
            [154953]: true,
            [155722]: true
        },
        healing_reduced_debuff: {
            [8680]: true,
            [54680]: true,
            [115625]: true,
            [115804]: true
        },
        stealthed_buff: {
            [1784]: true,
            [5215]: true,
            [11327]: true,
            [24450]: true,
            [58984]: true,
            [90328]: true,
            [102543]: true,
            [148523]: true,
            [115191]: true,
            [115192]: true,
            [115193]: true,
            [185422]: true
        },
        burst_haste_buff: {
            [2825]: true,
            [32182]: true,
            [80353]: true,
            [90355]: true
        },
        burst_haste_debuff: {
            [57723]: true,
            [57724]: true,
            [80354]: true,
            [95809]: true
        },
        raid_movement_buff: {
            [106898]: true
        }
    }
    constructor(private baseState: BaseState, private ovaleGuid: OvaleGUIDClass, private ovale: OvaleClass, private requirement: OvaleRequirement) {
        for (const [, useName] of pairs(STAT_USE_NAMES)) {
            let name;
            for (const [, statName] of pairs(STAT_NAMES)) {
                name = `${useName}_${statName}_buff`;
                this.buffSpellList[name] = {}
                let shortName = STAT_SHORTNAME[statName];
                if (shortName) {
                    name = `${useName}_${shortName}_buff`;
                    this.buffSpellList[name] = {}
                }
            }
            name = `${useName}_any_buff`;
            this.buffSpellList[name] = {}
        }

        {
            for (const [name] of pairs(this.buffSpellList)) {
                this.DEFAULT_SPELL_LIST[name] = true;
            }
        }        
    }

    DEFAULT_SPELL_LIST: LuaObj<boolean> = {}
    
    Reset() {
        wipe(this.itemInfo);
        wipe(this.spellInfo);
        for (const [k, v] of pairs(this.buffSpellList)) {
            if (!this.DEFAULT_SPELL_LIST[k]) {
                wipe(v);
                delete this.buffSpellList[k];
            } else if (truthy(find(k, "^trinket_"))) {
                wipe(v);
            }
        }
    }
    SpellInfo(spellId: number) {
        let si = this.spellInfo[spellId];
        if (!si) {
            si = {
                aura: {
                    player: {
                        HELPFUL: {},
                        HARMFUL: {}
                    },
                    target: {
                        HELPFUL: {},
                        HARMFUL: {}
                    },
                    pet: {
                        HELPFUL: {},
                        HARMFUL: {}
                    },
                    damage: {
                        HELPFUL: {},
                        HARMFUL: {}
                    }
                },
                require: {}
            }
            this.spellInfo[spellId] = si;
        }
        return si;
    }
    GetSpellInfo(spellId: number) {
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
    ItemInfo(itemId: number) {
        let ii = this.itemInfo[itemId];
        if (!ii) {
            ii = {
                require: {}
            }
            this.itemInfo[itemId] = ii;
        }
        return ii;
    }
    GetItemTagInfo(spellId: number): [string, boolean] {
        return ["cd", false];
    }
    GetSpellTagInfo(spellId: number): [string, boolean] {
        let tag:string | undefined = "main";
        let invokesGCD = true;
        let si = this.spellInfo[spellId];
        if (si) {
            invokesGCD = !si.gcd || si.gcd > 0;
            tag = si.tag;
            if (!tag) {
                let cd = si.cd;
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
    
    CheckSpellAuraData(auraId: number | string, spellData: SpellData, atTime: number, guid: string | undefined): [boolean, string | number, number | undefined] {
        guid = guid || this.ovaleGuid.UnitGUID("player");
        let index, value: string | number, data;
        let spellDataArray: LuaArray<string | number> | undefined = undefined;
        if (isLuaArray(spellData)) {
            spellDataArray = spellData;
            value = spellData[1];
            index = 2;
        } else {
            value = spellData;
        }
        if (value == "count") {
            let N;
            if (index) {
                N = spellDataArray![index];
                index = index + 1;
            }
            if (N) {
                data = tonumber(N);
            } else {
                this.ovale.OneTimeMessage("Warning: '%d' has '%s' missing final stack count.", auraId, value);
            }
        } else if (value == "extend") {
            let seconds;
            if (index) {
                seconds = spellDataArray![index];
                index = index + 1;
            }
            if (seconds) {
                data = tonumber(seconds);
            } else {
                this.ovale.OneTimeMessage("Warning: '%d' has '%s' missing duration.", auraId, value);
            }
        } else {
            let asNumber = tonumber(value);
            value = asNumber || value;
        }
        let verified = true;
        if (index) {
            [verified] = this.requirement.CheckRequirements(<number>auraId, atTime, spellDataArray!, index, guid);
        }
        return [verified, value, data];
    }

    CheckSpellInfo(spellId: number, atTime: number, targetGUID: string | undefined): [boolean, string?] {
        targetGUID = targetGUID || this.ovaleGuid.UnitGUID(this.baseState.next.defaultTarget || "target");
        let verified = true;
        let requirement: string | undefined;
        for (const [name, handler] of pairs(this.requirement.nowRequirements)) {
            let value = this.GetSpellInfoProperty(spellId, atTime, <any>name, targetGUID);
            if (value) {
                if (!isString(value) && isLuaArray<string>(value)) {
                    [verified, requirement] = handler(spellId, atTime, name, value, 1, targetGUID);
                }
                else {
                    tempTokens[1] = <string>value;
                    [verified, requirement] = handler(spellId, atTime, name, tempTokens, 1, targetGUID);
                }
                if (!verified) {
                    break;
                }
            }
        }
        return [verified, requirement];
    }
    GetItemInfoProperty(itemId: number, atTime: number, property: keyof SpellInfo) {
        const targetGUID = this.ovaleGuid.UnitGUID("player");
        let ii = this.ItemInfo(itemId);
        let value = ii && ii[property];
        let requirements = ii && ii.require[property];
        if (requirements) {
            for (const [v, rArray] of pairs(requirements)) {
                if (isLuaArray(rArray)) {
                    for (const [, requirement] of ipairs<any>(rArray)) {
                        let verified = this.requirement.CheckRequirements(itemId, atTime, requirement, 1, targetGUID);
                        if (verified) {
                            value = tonumber(v) || v;
                            break;
                        }
                    }
                }
            }
        }
        return value;
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
    GetSpellInfoProperty<T extends keyof SpellInfo>(spellId: number, atTime: number, property:T, targetGUID: string|undefined): SpellInfo[T] {
        targetGUID = targetGUID || this.ovaleGuid.UnitGUID(this.baseState.next.defaultTarget || "target");
        let si = this.spellInfo[spellId];
        let value = si && si[property];
        let requirements = si && si.require[property];
        if (requirements) {
            for (const [v, rArray] of kpairs(requirements)) {
                if (isLuaArray(rArray)) {
                    for (const [, requirement] of ipairs<any>(rArray)) {
                        let verified = this.requirement.CheckRequirements(spellId, atTime, requirement, 1, targetGUID);
                        if (verified) {
                            (<any>value) = tonumber(v) || v;
                            break;
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
    GetSpellInfoPropertyNumber(spellId: number, atTime: number|undefined, property:keyof SpellInfo, targetGUID: string|undefined, splitRatio?: boolean): number[] {
        targetGUID = targetGUID || this.ovaleGuid.UnitGUID(this.baseState.next.defaultTarget || "target");
        let si = this.spellInfo[spellId];
        
        let ratioParam = `${property}_percent` as keyof SpellInfo;
        let ratio = si && <number>si[ratioParam];
        if (ratio) {
            ratio = ratio / 100;
        } else {
            ratio = 1;
        }
        if (atTime) {  
            let ratioRequirements = si && si.require[ratioParam];
            if (ratioRequirements) {
                for (const [v, rArray] of pairs(ratioRequirements)) {
                    if (isLuaArray(rArray)) {
                        for (const [, requirement] of ipairs<any>(rArray)) {
                            let verified = this.requirement.CheckRequirements(spellId, atTime, requirement, 1, targetGUID);
                            if (verified) {
                                if (ratio != 0) {
                                    ratio = ratio * ((tonumber(v) / 100) || 1);
                                } else {
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        let value = si && <number>si[property] || 0;
        if (ratio != 0) {
            let addParam = `add_${property}` as keyof SpellInfo;
            let addProperty = si && <number>si[addParam];
            if (addProperty) {
                value = value + addProperty;
            }
            if (atTime) {
                let addRequirements = si && si.require[addParam];
                if (addRequirements) {
                    for (const [v, rArray] of pairs(addRequirements)) {
                        if (isLuaArray(rArray)) {
                            for (const [, requirement] of ipairs<any>(rArray)) {
                                let verified = this.requirement.CheckRequirements(spellId, atTime, requirement, 1, targetGUID);
                                if (verified) {
                                    value = value + (tonumber(v) || 0);
                                }
                            }
                        }
                    }
                }
            }
            
        } else { // If ratio is 0, value must be 0.
            value = 0;
        }
        if (splitRatio) {
            return [value, ratio];
        }
        return [value * ratio];
    }

    GetDamage(spellId: number, attackpower: number, spellpower: number, mainHandWeaponDPS: number, offHandWeaponDPS: number, combopoints: number): number | undefined {
        let si = this.spellInfo[spellId];
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
