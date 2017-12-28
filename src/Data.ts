import { Ovale } from "./Ovale";
import { OvaleGUID } from "./GUID";
import { OvaleDebug } from "./Debug";
import { nowRequirements, CheckRequirements } from "./Requirement";
import { type, pairs, tonumber, wipe, truthy, LuaArray, LuaObj } from "@wowts/lua";
import { find } from "@wowts/string";
import { floor, ceil } from "@wowts/math";
import { baseState } from "./BaseState";
import { isNumber, isLuaArray, isString } from "./tools";

let OvaleDataBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleData"));

let BLOODELF_CLASSES: LuaObj<boolean> = {
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
let PANDAREN_CLASSES: LuaObj<boolean> = {
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
let TAUREN_CLASSES: LuaObj<boolean> = {
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
let STAT_NAMES: LuaArray<string> = {
    1: "agility",
    2: "bonus_armor",
    3: "critical_strike",
    4: "haste",
    5: "intellect",
    6: "mastery",
    7: "multistrike",
    8: "spirit",
    9: "spellpower",
    10: "strength",
    11: "versatility"
}
let STAT_SHORTNAME: LuaObj<string> = {
    agility: "agi",
    critical_strike: "crit",
    intellect: "int",
    strength: "str",
    spirit: "spi"
}
let STAT_USE_NAMES: LuaArray<string> = {
    1: "trinket_proc",
    2: "trinket_stacking_proc",
    3: "trinket_stacking_stat",
    4: "trinket_stat",
    5: "trinket_stack_proc"
}

type Requirements = LuaObj<LuaArray<string>>;

export interface SpellInfo {
    [key:string]: LuaObj<Requirements> | number | string | LuaArray<string> | LuaArray<number>;
    require: LuaObj<Requirements>;
    aura?: {
        player: LuaObj<{}>;
        target: LuaObj<{}>;
        pet: LuaObj<{}>;
        damage: LuaObj<{}>;
    };
    gcd?: number;
    tag?:string;
    cd?: number;
    base?:number;
    bonusmainhand?:number;
    bonusoffhand?:number;
    bonuscp?: number;
    bonusap?: number;
    bonusapcp?:number;
    bonussp?:number;
    damage?: number;
    sharedcd?:number;
    stacking?:number;
    forcecd?:number;
    addcd?:number;
    max_travel_time?:number;
    physical?:number;
    travel_time?:number;
    buff_cd?:number;
    buff_cdr?:number;
    haste?:string;
    canStopChannelling?:number;
    channel?:number;
    replace?:number;
    texture?:string;
    runes?:number;
    totem?:number;
    buff_totem?:number;
    max_totems?:number;
    addduration?:number;
    max_stacks?:number;
    maxstacks?:number;
    stat?:string | LuaArray<string>;
    buff?:number | LuaArray<number>;
    combo?:number | "finisher";
    mincombo?:number;
    min_combo?:number;
    maxcombo?:number;
    max_combo?:number;
    temp_combo?:number;
    buff_combo?:number;
    buff_combo_amount?:number;
    adddurationcp?:number;
    adddurationholy?:number;
    tick?:number;
    duration?:number;
    inccounter?:number;
    refund_combo?:number | "cost";
    to_stance?:number;
    unusable?:number;
    cd_haste?:string;
    gcd_haste?:number;
    resetcounter?:number;
}


const tempTokens: LuaArray<string> = {};

class OvaleDataClass extends OvaleDataBase {
    STAT_NAMES = STAT_NAMES;
    STAT_SHORTNAME = STAT_SHORTNAME;
    STAT_USE_NAMES = STAT_USE_NAMES;
    BLOODELF_CLASSES = BLOODELF_CLASSES;
    PANDAREN_CLASSES = PANDAREN_CLASSES;
    TAUREN_CLASSES = TAUREN_CLASSES;
    itemInfo: LuaArray<SpellInfo> = {}
    itemList = {}
    spellInfo: LuaObj<SpellInfo> = {}
    buffSpellList: LuaObj<LuaArray<boolean>> = {
        fear_debuff: {
            [5246]: true,
            [5484]: true,
            [5782]: true,
            [8122]: true
        },
        incapacitate_debuff: {
            [6770]: true,
            [12540]: true,
            [20066]: true,
            [137460]: true
        },
        root_debuff: {
            [122]: true,
            [339]: true
        },
        stun_debuff: {
            [408]: true,
            [853]: true,
            [1833]: true,
            [5211]: true,
            [46968]: true
        },
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
        multistrike_buff: {
            [24844]: true,
            [34889]: true,
            [49868]: true,
            [57386]: true,
            [58604]: true,
            [109773]: true,
            [113742]: true,
            [166916]: true,
            [172968]: true
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
    constructor() {
        super();
        for (const [, useName] of pairs(STAT_USE_NAMES)) {
            let name;
            for (const [, statName] of pairs(STAT_NAMES)) {
                name = `${useName}_${statName}_buff`;
                this.buffSpellList[name] = {
                }
                let shortName = STAT_SHORTNAME[statName];
                if (shortName) {
                    name = `${useName}_${shortName}_buff`;
                    this.buffSpellList[name] = {
                    }
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
                this.buffSpellList[k] = undefined;
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
                    },
                    target: {
                    },
                    pet: {
                    },
                    damage: {
                    }
                },
                require: {
                }
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
                require: {
                }
            }
            this.itemInfo[itemId] = ii;
        }
        return ii;
    }
    GetItemTagInfo(spellId: number): [string, boolean] {
        return ["cd", false];
    }
    GetSpellTagInfo(spellId: number): [string, boolean] {
        let tag = "main";
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
    
    CheckSpellAuraData(auraId: number | string, spellData, atTime: number, guid: string) {
        guid = guid || OvaleGUID.UnitGUID("player");
        let index, value, data;
        if (type(spellData) == "table") {
            value = spellData[1];
            index = 2;
        } else {
            value = spellData;
        }
        if (value == "count") {
            let N;
            if (index) {
                N = spellData[index];
                index = index + 1;
            }
            if (N) {
                data = tonumber(N);
            } else {
                Ovale.OneTimeMessage("Warning: '%d' has '%s' missing final stack count.", auraId, value);
            }
        } else if (value == "extend") {
            let seconds;
            if (index) {
                seconds = spellData[index];
                index = index + 1;
            }
            if (seconds) {
                data = tonumber(seconds);
            } else {
                Ovale.OneTimeMessage("Warning: '%d' has '%s' missing duration.", auraId, value);
            }
        } else {
            let asNumber = tonumber(value);
            value = asNumber || value;
        }
        let verified = true;
        if (index) {
            [verified] = CheckRequirements(<number>auraId, atTime, spellData, index, guid);
        }
        return [verified, value, data];
    }

    CheckSpellInfo(spellId: number, atTime: number, targetGUID: string) {
        targetGUID = targetGUID || OvaleGUID.UnitGUID(baseState.next.defaultTarget || "target");
        let verified = true;
        let requirement;
        for (const [name, handler] of pairs(nowRequirements)) {
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
        const targetGUID = OvaleGUID.UnitGUID("player");
        let ii = this.ItemInfo(itemId);
        let value = ii && ii[property];
        let requirements = ii && ii.require[property];
        if (requirements) {
            for (const [v, requirement] of pairs(requirements)) {
                let verified = CheckRequirements(itemId, atTime, requirement, 1, targetGUID);
                if (verified) {
                    value = tonumber(v) || v;
                    break;
                }
            }
        }
        return value;
    }
    //GetSpellInfoProperty(spellId, atTime, property:"gcd"|"duration"|"combo"|"inccounter"|"resetcounter", targetGUID):number;
    GetSpellInfoProperty<T extends keyof SpellInfo>(spellId: number, atTime: number, property:T, targetGUID: string|undefined): SpellInfo[T] {
        targetGUID = targetGUID || OvaleGUID.UnitGUID(baseState.next.defaultTarget || "target");
        let si = this.spellInfo[spellId];
        let value = si && si[property];
        let requirements = si && si.require[property];
        if (requirements) {
            for (const [v, requirement] of pairs(requirements)) {
                let verified = CheckRequirements(spellId, atTime, requirement, 1, targetGUID);
                if (verified) {
                    value = tonumber(v) || v;
                    break;
                }
            }
        }

        if (value && isNumber(value)){
            let num = value;
            let addpower = si && <number>si[`add${property}`];
            if (addpower) {
                num = num + addpower;
            }
            let ratio = si && <number>si[`${property}_percent`];
            if (ratio) {
                ratio = ratio / 100;
            } else {
                ratio = 1;
            }
            let multipliers = si && si.require[`${property}_percent`];
            if (multipliers) {
                for (const [v, requirement] of pairs(multipliers)) {
                    let verified = CheckRequirements(spellId, atTime, requirement, 1, targetGUID);
                    if (verified) {
                        ratio = ratio * (tonumber(v) || 0) / 100;
                    }
                }
            }
            let actual = (num > 0 && floor(num * ratio)) || ceil(num * ratio);
            return actual;
        }
        return value;
    }

    GetDamage(spellId: number, attackpower: number, spellpower: number, mainHandWeaponDamage: number, offHandWeaponDamage: number, combo: number) {
        let si = this.spellInfo[spellId];
        if (!si) {
            return undefined;
        }
        let damage = si.base || 0;
        attackpower = attackpower || 0;
        spellpower = spellpower || 0;
        mainHandWeaponDamage = mainHandWeaponDamage || 0;
        offHandWeaponDamage = offHandWeaponDamage || 0;
        combo = combo || 0;
        if (si.bonusmainhand) {
            damage = damage + si.bonusmainhand * mainHandWeaponDamage;
        }
        if (si.bonusoffhand) {
            damage = damage + si.bonusoffhand * offHandWeaponDamage;
        }
        if (si.bonuscp) {
            damage = damage + si.bonuscp * combo;
        }
        if (si.bonusap) {
            damage = damage + si.bonusap * attackpower;
        }
        if (si.bonusapcp) {
            damage = damage + si.bonusapcp * attackpower * combo;
        }
        if (si.bonussp) {
            damage = damage + si.bonussp * spellpower;
        }
        return damage;
    }
}

export const OvaleData = new OvaleDataClass();