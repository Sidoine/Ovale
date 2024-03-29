import { AstNode, isAstNodeWithChildren, OvaleASTClass } from "../engine/ast";
import {
    type,
    LuaObj,
    ipairs,
    wipe,
    LuaArray,
    lualength,
    tonumber,
    pairs,
    next,
} from "@wowts/lua";
import { remove, insert, sort, concat } from "@wowts/table";
import { Annotation, optionalSkills, Profile } from "./definitions";
import {
    toLowerSpecialization,
    toOvaleFunctionName,
    toOvaleTaggedFunctionName,
    outputPool,
} from "./text-tools";
import { format } from "@wowts/string";
import { OvaleDataClass } from "../engine/data";

const maxDesiredTargets = 3;

const definedFunctions: LuaObj<boolean> = {};
const usedFunctions: LuaObj<boolean> = {};

function isNode(n: any): n is AstNode {
    return type(n) == "table";
}

function preOrderTraversalMark(node: AstNode) {
    if (node.type == "custom_function") {
        usedFunctions[node.name] = true;
    } else {
        if (node.type == "add_function") {
            definedFunctions[node.name] = true;
        }
        if (isAstNodeWithChildren(node)) {
            for (const [, childNode] of ipairs(node.child)) {
                preOrderTraversalMark(childNode);
            }
        }
    }
}
export function markNode(node: AstNode) {
    wipe(definedFunctions);
    wipe(usedFunctions);
    preOrderTraversalMark(node);
}
function sweepComments(childNodes: LuaArray<AstNode>, index: number) {
    let count = 0;
    for (let k = index - 1; k >= 1; k += -1) {
        if (childNodes[k].type == "comment") {
            remove(childNodes, k);
            count = count + 1;
        } else {
            break;
        }
    }
    return count;
}

// Sweep (remove) all usages of functions that are empty or unused.
export function sweepNode(node: AstNode): [boolean, boolean | AstNode] {
    let isChanged: boolean;
    let isSwept: boolean | AstNode;
    [isChanged, isSwept] = [false, false];
    if (node.type == "custom_function" && !definedFunctions[node.name]) {
        [isChanged, isSwept] = [true, true];
    } else if (node.type == "group" || node.type == "script") {
        const child = node.child;
        let index = lualength(child);
        while (index > 0) {
            const childNode = child[index];
            const [changed, swept] = sweepNode(childNode);
            if (isNode(swept)) {
                if (swept.type == "group") {
                    // Directly insert a replacement group's statements in place of the replaced node.
                    remove(child, index);
                    for (let k = lualength(swept.child); k >= 1; k += -1) {
                        insert(child, index, swept.child[k]);
                    }
                    if (node.type == "group") {
                        const count = sweepComments(child, index);
                        index = index - count;
                    }
                } else {
                    child[index] = swept;
                }
            } else if (swept) {
                remove(child, index);
                if (node.type == "group") {
                    const count = sweepComments(child, index);
                    index = index - count;
                }
            }
            isChanged = isChanged || changed || !!swept;
            index = index - 1;
        }
        // Remove blank lines at the top of groups and scripts.
        if (node.type == "group" || node.type == "script") {
            let childNode = child[1];
            while (
                childNode &&
                childNode.type == "comment" &&
                (!childNode.comment || childNode.comment == "")
            ) {
                isChanged = true;
                remove(child, 1);
                childNode = child[1];
            }
        }
        isSwept = isSwept || lualength(child) == 0;
        isChanged = isChanged || !!isSwept;
    } else if (node.type == "icon") {
        [isChanged, isSwept] = sweepNode(node.child[1]);
    } else if (node.type == "if") {
        [isChanged, isSwept] = sweepNode(node.child[2]);
    } else if (node.type == "logical") {
        if (node.expressionType == "binary") {
            const [lhsNode, rhsNode] = [node.child[1], node.child[2]];
            for (const [index, childNode] of ipairs(node.child)) {
                const [changed, swept] = sweepNode(childNode);
                if (isNode(swept)) {
                    node.child[index] = swept;
                } else if (swept) {
                    if (node.operator == "or") {
                        isSwept = (childNode == lhsNode && rhsNode) || lhsNode;
                    } else {
                        isSwept = isSwept || swept;
                    }
                    break;
                }
                if (changed) {
                    isChanged = isChanged || changed;
                    break;
                }
            }
            isChanged = isChanged || !!isSwept;
        }
    } else if (node.type == "unless") {
        let [changed, swept] = sweepNode(node.child[2]);
        if (isNode(swept)) {
            node.child[2] = swept;
            isSwept = false;
        } else if (swept) {
            isSwept = swept;
        } else {
            [changed, swept] = sweepNode(node.child[1]);
            if (isNode(swept)) {
                node.child[1] = swept;
                isSwept = false;
            } else if (swept) {
                isSwept = node.child[2];
            }
        }
        isChanged = isChanged || changed || !!isSwept;
    } else if (node.type == "simc_wait") {
        [isChanged, isSwept] = sweepNode(node.child[1]);
    }
    return [isChanged, isSwept];
}

interface Spell {
    order: number;
    name: string;
    interrupt?: number;
    worksOnBoss?: number;
    range?: string;
    stun?: number;
    addSymbol?: LuaObj<any>;
    extraCondition?: string;
}

export class Generator {
    constructor(
        private ovaleAst: OvaleASTClass,
        private ovaleData: OvaleDataClass
    ) {}

    private insertInterruptFunction(
        child: LuaArray<AstNode>,
        annotation: Annotation,
        interrupts: LuaArray<Spell>
    ) {
        const nodeList = annotation.astAnnotation.nodeList;
        const camelSpecialization = toLowerSpecialization(annotation);
        const spells = interrupts || {};
        sort(spells, function (a, b) {
            return tonumber(a.order || 0) >= tonumber(b.order || 0);
        });
        const lines: LuaArray<string> = {};
        for (const [, spell] of pairs(spells)) {
            annotation.addSymbol(spell.name);
            if (spell.addSymbol != undefined) {
                for (const [, v] of pairs(spell.addSymbol)) {
                    annotation.addSymbol(v);
                }
            }
            const conditions: LuaArray<string> = {};
            if (spell.range == undefined) {
                insert(conditions, format("target.InRange(%s)", spell.name));
            } else if (spell.range != "") {
                insert(conditions, spell.range);
            }
            if (spell.interrupt == 1) {
                insert(conditions, "target.IsInterruptible()");
            }
            if (spell.worksOnBoss == 0 || spell.worksOnBoss == undefined) {
                insert(conditions, "not target.Classification(worldboss)");
            }
            if (spell.extraCondition != undefined) {
                insert(conditions, spell.extraCondition);
            }
            let line = "";
            if (lualength(conditions) > 0) {
                line = `${line}if ${concat(conditions, " and ")} `;
            }
            line = `${line}${format("Spell(%s)", spell.name)}`;
            insert(lines, line);
        }
        const fmt = `
            AddFunction %sInterruptActions
            {
                if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
                {
                    %s
                }
            }
        `;
        const code = format(fmt, camelSpecialization, concat(lines, "\n"));
        const [node] = this.ovaleAst.parseCode(
            "add_function",
            code,
            nodeList,
            annotation.astAnnotation
        );
        if (node && node.type === "add_function") {
            insert(child, 1, node);
            annotation.functionTag[node.name] = "cd";
        }
    }

    public insertInterruptFunctions(
        child: LuaArray<AstNode>,
        annotation: Annotation
    ) {
        const interrupts = {};
        const className = annotation.classId;

        if (this.ovaleData.pandarenClasses[className]) {
            insert(interrupts, {
                name: "quaking_palm",
                stun: 1,
                order: 98,
            });
        }
        if (this.ovaleData.taurenClasses[className]) {
            insert(interrupts, {
                name: "war_stomp",
                stun: 1,
                order: 99,
                range: "target.Distance() < 5",
            });
        }

        if (annotation.mind_freeze == "DEATHKNIGHT") {
            insert(interrupts, {
                name: "mind_freeze",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10,
            });
            if (
                annotation.specialization == "blood" ||
                annotation.specialization == "unholy"
            ) {
                insert(interrupts, {
                    name: "asphyxiate",
                    stun: 1,
                    order: 20,
                });
            }
            if (annotation.specialization == "frost") {
                insert(interrupts, {
                    name: "blinding_sleet",
                    disorient: 1,
                    range: "target.Distance() < 12",
                    order: 20,
                });
            }
        }
        if (annotation.disrupt == "DEMONHUNTER") {
            insert(interrupts, {
                name: "disrupt",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10,
            });
            insert(interrupts, {
                name: "imprison",
                cc: 1,
                extraCondition: "target.CreatureType(Demon Humanoid Beast)",
                order: 999,
            });
            if (annotation.specialization == "havoc") {
                insert(interrupts, {
                    name: "chaos_nova",
                    stun: 1,
                    range: "target.Distance() < 8",
                    order: 100,
                });
                insert(interrupts, {
                    name: "fel_eruption",
                    stun: 1,
                    order: 20,
                });
            }
            if (annotation.specialization == "vengeance") {
                insert(interrupts, {
                    name: "sigil_of_silence",
                    interrupt: 1,
                    order: 110,
                    range: "",
                    extraCondition:
                        "not SigilCharging(silence misery chains) and (target.RemainingCastTime() >= (2 - Talent(quickened_sigils_talent) + GCDRemaining()))",
                });
                insert(interrupts, {
                    name: "sigil_of_misery",
                    disorient: 1,
                    order: 120,
                    range: "",
                    extraCondition:
                        "not SigilCharging(silence misery chains) and (target.RemainingCastTime() >= (2 - Talent(quickened_sigils_talent) + GCDRemaining()))",
                });
                insert(interrupts, {
                    name: "sigil_of_chains",
                    pull: 1,
                    order: 130,
                    range: "",
                    extraCondition:
                        "not SigilCharging(silence misery chains) and (target.RemainingCastTime() >= (2 - Talent(quickened_sigils_talent) + GCDRemaining()))",
                });
            }
        }
        if (
            annotation.skull_bash == "DRUID" ||
            annotation.solar_beam == "DRUID"
        ) {
            if (
                annotation.specialization == "guardian" ||
                annotation.specialization == "feral"
            ) {
                insert(interrupts, {
                    name: "skull_bash",
                    interrupt: 1,
                    worksOnBoss: 1,
                    order: 10,
                });
            }
            if (annotation.specialization == "balance") {
                insert(interrupts, {
                    name: "solar_beam",
                    interrupt: 1,
                    worksOnBoss: 1,
                    order: 10,
                });
            }
            insert(interrupts, {
                name: "mighty_bash",
                stun: 1,
                order: 20,
            });
            if (annotation.specialization == "guardian") {
                insert(interrupts, {
                    name: "incapacitating_roar",
                    incapacitate: 1,
                    order: 30,
                    range: "target.Distance() < 10",
                });
            }
            insert(interrupts, {
                name: "typhoon",
                knockback: 1,
                order: 110,
                range: "target.Distance() < 15",
            });
            if (annotation.specialization == "feral") {
                insert(interrupts, {
                    name: "maim",
                    stun: 1,
                    order: 40,
                });
            }
        }
        if (annotation.counter_shot == "HUNTER") {
            insert(interrupts, {
                name: "counter_shot",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10,
            });
        }
        if (annotation.muzzle == "HUNTER") {
            insert(interrupts, {
                name: "muzzle",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10,
            });
        }
        if (annotation.counterspell == "MAGE") {
            insert(interrupts, {
                name: "counterspell",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10,
            });
        }
        if (annotation.spear_hand_strike == "MONK") {
            insert(interrupts, {
                name: "spear_hand_strike",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10,
            });
            insert(interrupts, {
                name: "paralysis",
                cc: 1,
                order: 999,
            });
            insert(interrupts, {
                name: "leg_sweep",
                stun: 1,
                order: 30,
                range: "target.Distance() < 5",
            });
        }
        if (annotation.rebuke == "PALADIN") {
            insert(interrupts, {
                name: "rebuke",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10,
            });
            insert(interrupts, {
                name: "hammer_of_justice",
                stun: 1,
                order: 20,
            });
            if (annotation.specialization == "protection") {
                insert(interrupts, {
                    name: "avengers_shield",
                    interrupt: 1,
                    worksOnBoss: 1,
                    order: 15,
                });
                insert(interrupts, {
                    name: "blinding_light",
                    disorient: 1,
                    order: 50,
                    range: "target.Distance() < 10",
                });
            }
        }
        if (annotation.silence == "PRIEST") {
            insert(interrupts, {
                name: "silence",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10,
            });
            insert(interrupts, {
                name: "mind_bomb",
                stun: 1,
                order: 30,
                extraCondition: "target.RemainingCastTime() > 2",
            });
        }
        if (annotation.kick == "ROGUE") {
            insert(interrupts, {
                name: "kick",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10,
            });
            insert(interrupts, {
                name: "cheap_shot",
                stun: 1,
                order: 20,
            });
            if (annotation.specialization == "outlaw") {
                insert(interrupts, {
                    name: "gouge",
                    incapacitate: 1,
                    order: 100,
                });
            }
            insert(interrupts, {
                name: "kidney_shot",
                stun: 1,
                order: 30,
            });
        }
        if (annotation.wind_shear == "SHAMAN") {
            insert(interrupts, {
                name: "wind_shear",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10,
            });
            if (annotation.specialization == "enhancement") {
                insert(interrupts, {
                    name: "sundering",
                    knockback: 1,
                    order: 20,
                    range: "target.Distance() < 5",
                });
            }
            insert(interrupts, {
                name: "capacitor_totem",
                stun: 1,
                order: 30,
                range: "",
                extraCondition: "target.RemainingCastTime() > 2",
            });
            insert(interrupts, {
                name: "hex",
                cc: 1,
                order: 100,
                extraCondition:
                    "target.RemainingCastTime() > CastTime(hex) + GCDRemaining() and target.CreatureType(Humanoid Beast)",
            });
        }
        if (annotation.interrupt == "WARLOCK") {
            insert(interrupts, {
                name: "spell_lock",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10,
            });
            if (annotation.specialization == "demonology") {
                insert(interrupts, {
                    name: "axe_toss",
                    interrupt: 1,
                    worksOnBoss: 1,
                    order: 20,
                });
            }
            insert(interrupts, {
                name: "shadowfury",
                stun: 1,
                order: 100,
                range: 35,
                extraCondition:
                    "target.RemainingCastTime() > CastTime(shadowfury) + GCDRemaining()",
            });
            insert(interrupts, {
                name: "banish",
                cc: 1,
                order: 200,
                range: 30,
                extraCondition:
                    "target.RemainingCastTime() > CastTime(banish) + GCDRemaining()",
            });
            insert(interrupts, {
                name: "seduction",
                cc: 1,
                order: 300,
                extraCondition:
                    "target.RemainingCastTime() > CastTime(seduction) + GCDRemaining()",
            });
        }
        if (annotation.pummel == "WARRIOR") {
            insert(interrupts, {
                name: "pummel",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10,
            });
            insert(interrupts, {
                name: "shockwave",
                stun: 1,
                worksOnBoss: 0,
                order: 20,
                range: "target.Distance() < 10",
            });
            insert(interrupts, {
                name: "storm_bolt",
                stun: 1,
                worksOnBoss: 0,
                order: 20,
            });
            insert(interrupts, {
                name: "intimidating_shout",
                incapacitate: 1,
                worksOnBoss: 0,
                order: 100,
            });
        }
        if (lualength(interrupts) > 0) {
            this.insertInterruptFunction(child, annotation, interrupts);
        }
        return lualength(interrupts);
    }
    public insertSupportingFunctions(
        child: LuaArray<AstNode>,
        annotation: Annotation
    ) {
        let count = 0;
        const nodeList = annotation.astAnnotation.nodeList;
        const camelSpecialization = toLowerSpecialization(annotation);
        const lowerSpecialization = toLowerSpecialization(annotation);
        if (annotation.desired_targets) {
            const lines: LuaArray<string> = {};
            for (let k = maxDesiredTargets; k > 1; k += -1) {
                insert(
                    lines,
                    `if List(opt_${lowerSpecialization}_desired_targets desired_targets_${k}) ${k}`
                );
            }
            insert(lines, "1");
            const fmt = `
                AddFunction %sDesiredTargets
                {
                    %s
                }
            `;
            const code = format(fmt, camelSpecialization, concat(lines, "\n"));
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node) {
                insert(child, 1, node);
                count = count + 1;
            }
        }
        if (annotation.melee == "DEATHKNIGHT") {
            const fmt = `
                AddFunction %sGetInMeleeRange
                {
                    if CheckBoxOn(opt_melee_range) and not target.InRange(death_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.addSymbol("death_strike");
                count = count + 1;
            }
        }
        if (
            annotation.melee == "DEMONHUNTER" &&
            annotation.specialization == "havoc"
        ) {
            const fmt = `
                AddFunction %sGetInMeleeRange
                {
                    if CheckBoxOn(opt_melee_range) and not target.InRange(chaos_strike) 
                    {
                        if target.InRange(felblade) Spell(felblade)
                        Texture(misc_arrowlup help=L(not_in_melee_range))
                    }
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.addSymbol("chaos_strike");
                count = count + 1;
            }
        }
        if (
            annotation.melee == "DEMONHUNTER" &&
            annotation.specialization == "vengeance"
        ) {
            const fmt = `
                AddFunction %sGetInMeleeRange
                {
                    if CheckBoxOn(opt_melee_range) and not target.InRange(shear) Texture(misc_arrowlup help=L(not_in_melee_range))
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.addSymbol("shear");
                count = count + 1;
            }
        }
        if (annotation.melee == "DRUID") {
            const fmt = `
                AddFunction %sGetInMeleeRange
                {
                    if CheckBoxOn(opt_melee_range)
                    {
                        if Stance(druid_bear_form) and not target.InRange(mangle)
                        {
                            if target.InRange(wild_charge_bear) Spell(wild_charge_bear)
                            Texture(misc_arrowlup help=L(not_in_melee_range))
                        }
                        if (Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah)) and not target.InRange(shred)
                        {
                            if target.InRange(wild_charge_cat) Spell(wild_charge_cat)
                            Texture(misc_arrowlup help=L(not_in_melee_range))
                        }
                    }
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.addSymbol("mangle");
                annotation.addSymbol("shred");
                annotation.addSymbol("wild_charge_bear");
                annotation.addSymbol("wild_charge_cat");
                count = count + 1;
            }
        }
        if (annotation.melee == "HUNTER") {
            const fmt = `
                AddFunction %sGetInMeleeRange
                {
                    if CheckBoxOn(opt_melee_range) and not target.InRange(raptor_strike)
                    {
                        Texture(misc_arrowlup help=L(not_in_melee_range))
                    }
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.addSymbol("raptor_strike");
                count = count + 1;
            }
        }
        if (annotation.summon_pet == "HUNTER") {
            let fmt;
            fmt = `
                AddFunction %sSummonPet
                {
                    if not pet.Present() and not pet.IsDead() and not PreviousSpell(revive_pet) Texture(ability_hunter_beastcall help=L(summon_pet))
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.addSymbol("revive_pet");
                count = count + 1;
            }
        }
        if (annotation.melee == "MONK") {
            const fmt = `
                AddFunction %sGetInMeleeRange
                {
                    if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.addSymbol("tiger_palm");
                count = count + 1;
            }
        }
        if (annotation.time_to_hpg_heal == "PALADIN") {
            const code = `
                AddFunction HolyTimeToHPG
                {
                    SpellCooldown(crusader_strike holy_shock judgment)
                }
            `;
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node) {
                insert(child, 1, node);
                annotation.addSymbol("crusader_strike");
                annotation.addSymbol("holy_shock");
                annotation.addSymbol("judgment");
                count = count + 1;
            }
        }
        if (annotation.time_to_hpg_melee == "PALADIN") {
            const code = `
                AddFunction RetributionTimeToHPG
                {
                    SpellCooldown(crusader_strike hammer_of_wrath judgment usable=1)
                }
            `;
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node) {
                insert(child, 1, node);
                annotation.addSymbol("crusader_strike");
                annotation.addSymbol("hammer_of_wrath");
                annotation.addSymbol("judgment");
                count = count + 1;
            }
        }
        if (annotation.time_to_hpg_tank == "PALADIN") {
            const code = `
                AddFunction ProtectionTimeToHPG
                {
                    if Talent(sanctified_wrath_talent) SpellCooldown(crusader_strike holy_wrath judgment)
                    if not Talent(sanctified_wrath_talent) SpellCooldown(crusader_strike judgment)
                }
            `;
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            insert(child, 1, node);
            annotation.addSymbol("crusader_strike");
            annotation.addSymbol("holy_wrath");
            annotation.addSymbol("judgment");
            annotation.addSymbol("sanctified_wrath_talent");
            count = count + 1;
        }
        if (annotation.melee == "PALADIN") {
            const fmt = `
                AddFunction %sGetInMeleeRange
                {
                    if CheckBoxOn(opt_melee_range) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type == "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.addSymbol("rebuke");
                count = count + 1;
            }
        }
        if (annotation.melee == "ROGUE") {
            const fmt = `
                AddFunction %sGetInMeleeRange
                {
                    if CheckBoxOn(opt_melee_range) and not target.InRange(kick)
                    {
                        Spell(shadowstep)
                        Texture(misc_arrowlup help=L(not_in_melee_range))
                    }
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.addSymbol("kick");
                annotation.addSymbol("shadowstep");
                count = count + 1;
            }
        }
        if (annotation.melee == "SHAMAN") {
            const fmt = `
                AddFunction %sGetInMeleeRange
                {
                    if CheckBoxOn(opt_melee_range) and not target.InRange(stormstrike) 
                    {
                        if target.InRange(feral_lunge) Spell(feral_lunge)
                        Texture(misc_arrowlup help=L(not_in_melee_range))
                    }
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.addSymbol("feral_lunge");
                annotation.addSymbol("stormstrike");
                count = count + 1;
            }
        }
        if (annotation.bloodlust == "SHAMAN") {
            const fmt = `
                AddFunction %sBloodlust
                {
                    if CheckBoxOn(opt_bloodlust) and DebuffExpires(burst_haste_debuff any=1)
                    {
                        Spell(bloodlust)
                        Spell(heroism)
                    }
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "cd";
                annotation.addSymbol("bloodlust");
                annotation.addSymbol("heroism");
                count = count + 1;
            }
        }
        if (annotation.melee == "WARRIOR") {
            const fmt = `
                AddFunction %sGetInMeleeRange
                {
                    if CheckBoxOn(opt_melee_range) and not InFlightToTarget(%s) and not InFlightToTarget(heroic_leap) and not target.InRange(pummel)
                    {
                        if target.InRange(%s) Spell(%s)
                        if SpellCharges(%s) == 0 and target.Distance() >= 8 and target.Distance() <= 40 Spell(heroic_leap)
                        Texture(misc_arrowlup help=L(not_in_melee_range))
                    }
                }
            `;
            let charge = "charge";
            if (annotation.specialization == "protection") {
                charge = "intercept";
            }
            const code = format(
                fmt,
                camelSpecialization,
                charge,
                charge,
                charge,
                charge
            );
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.addSymbol(charge);
                annotation.addSymbol("heroic_leap");
                annotation.addSymbol("pummel");
                count = count + 1;
            }
        }
        if (annotation.use_item) {
            const fmt = `
                AddFunction %sUseItemActions
                {
                    Item("trinket0Slot" usable=1 text=13)
                    Item("trinket1Slot" usable=1 text=14)
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "cd";
                count = count + 1;
            }
        }
        return count;
    }

    private addOptionalSkillCheckBox(
        child: LuaArray<AstNode>,
        annotation: Annotation,
        data: any,
        skill: keyof Annotation
    ) {
        const nodeList = annotation.astAnnotation.nodeList;
        if (data.class != annotation[skill]) {
            return 0;
        }
        let defaultText;
        if (data.default) {
            defaultText = " default";
        } else {
            defaultText = "";
        }
        const fmt = `
            AddCheckBox(opt_%s SpellName(%s)%s enabled=(specialization(%s)))
        `;
        const code = format(
            fmt,
            skill,
            skill,
            defaultText,
            annotation.specialization
        );
        const [node] = this.ovaleAst.parseCode(
            "checkbox",
            code,
            nodeList,
            annotation.astAnnotation
        );
        insert(child, 1, node);
        annotation.addSymbol(skill);
        return 1;
    }

    public insertSupportingControls(
        child: LuaArray<AstNode>,
        annotation: Annotation
    ) {
        let count = 0;
        for (const [skill, data] of pairs(optionalSkills)) {
            count =
                count +
                this.addOptionalSkillCheckBox(
                    child,
                    annotation,
                    data,
                    <keyof typeof optionalSkills>skill
                );
        }
        const nodeList = annotation.astAnnotation.nodeList;
        const lowerSpecialization = toLowerSpecialization(annotation);
        const ifSpecialization = `enabled=(specialization(${annotation.specialization}))`;
        if (annotation.using_apl && next(annotation.using_apl)) {
            for (const [name] of pairs(annotation.using_apl)) {
                if (name != "normal") {
                    const fmt = `
                        AddListItem(opt_using_apl %s "%s APL")
                    `;
                    const code = format(fmt, name, name);
                    const [node] = this.ovaleAst.parseCode(
                        "list_item",
                        code,
                        nodeList,
                        annotation.astAnnotation
                    );
                    insert(child, 1, node);
                }
            }
            {
                const code = `
                    AddListItem(opt_using_apl normal L(normal_apl) default)
                `;
                const [node] = this.ovaleAst.parseCode(
                    "list_item",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                insert(child, 1, node);
            }
        }
        if (annotation.desired_targets) {
            for (let k = maxDesiredTargets; k > 0; k += -1) {
                const fmt = "AddListItem(%s %s %s %s%s)";
                const code = format(
                    fmt,
                    `opt_${lowerSpecialization}_desired_targets`,
                    `desired_targets_${k}`,
                    `"Desired targets: ${k}"`,
                    (k == 1 && "default ") || "",
                    ifSpecialization
                );
                const [node] = this.ovaleAst.parseCode(
                    "list_item",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                insert(child, 1, node);
                count = count + 1;
            }
        }
        if (annotation.options) {
            for (const [v] of pairs(annotation.options)) {
                const fmt = `
                    AddCheckBox(${v} L(${v}) default %s)
                `;
                const code = format(fmt, ifSpecialization);
                const [node] = this.ovaleAst.parseCode(
                    "checkbox",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                insert(child, 1, node);
                count = count + 1;
            }
        }
        if (annotation.use_legendary_ring) {
            const legendaryRing = annotation.use_legendary_ring;
            const fmt = `
                AddCheckBox(opt_%s ItemName(%s) default %s)
            `;
            const code = format(
                fmt,
                legendaryRing,
                legendaryRing,
                ifSpecialization
            );
            const [node] = this.ovaleAst.parseCode(
                "checkbox",
                code,
                nodeList,
                annotation.astAnnotation
            );
            insert(child, 1, node);
            annotation.addSymbol(legendaryRing);
            count = count + 1;
        }
        if (annotation.opt_use_consumables) {
            const fmt = `
                AddCheckBox(opt_use_consumables L(opt_use_consumables) default %s)
            `;
            const code = format(fmt, ifSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "checkbox",
                code,
                nodeList,
                annotation.astAnnotation
            );
            insert(child, 1, node);
            count = count + 1;
        }
        if (annotation.melee) {
            const fmt = `
                AddCheckBox(opt_melee_range L(not_in_melee_range) %s)
            `;
            const code = format(fmt, ifSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "checkbox",
                code,
                nodeList,
                annotation.astAnnotation
            );
            insert(child, 1, node);
            count = count + 1;
        }
        if (annotation.interrupt) {
            const fmt = `
                AddCheckBox(opt_interrupt L(interrupt) default %s)
            `;
            const code = format(fmt, ifSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "checkbox",
                code,
                nodeList,
                annotation.astAnnotation
            );
            insert(child, 1, node);
            count = count + 1;
        }
        if (annotation.opt_priority_rotation) {
            const fmt = `
                AddCheckBox(opt_priority_rotation L(opt_priority_rotation) default %s)
            `;
            const code = format(fmt, ifSpecialization);
            const [node] = this.ovaleAst.parseCode(
                "checkbox",
                code,
                nodeList,
                annotation.astAnnotation
            );
            insert(child, 1, node);
            count = count + 1;
        }
        return count;
    }
    public insertVariables(child: LuaArray<AstNode>, annotation: Annotation) {
        for (const [, v] of pairs(annotation.variable)) {
            insert(child, 1, v);
        }
    }
    public generateIconBody(tag: string, profile: Profile) {
        const annotation = profile.annotation;
        const precombatName = toOvaleFunctionName("precombat", annotation);
        const defaultName = toOvaleFunctionName("_default", annotation);
        const [precombatBodyName] = toOvaleTaggedFunctionName(
            precombatName,
            tag
        );
        const [defaultBodyName] = toOvaleTaggedFunctionName(defaultName, tag);
        let mainBodyCode;
        if (annotation.using_apl && next(annotation.using_apl)) {
            const output = outputPool.get();
            output[lualength(output) + 1] = format(
                "if List(opt_using_apl normal) %s()",
                defaultBodyName
            );
            for (const [name] of pairs(annotation.using_apl)) {
                const aplName = toOvaleFunctionName(<string>name, annotation);
                const [aplBodyName] = toOvaleTaggedFunctionName(aplName, tag);
                output[lualength(output) + 1] = format(
                    "if List(opt_using_apl %s) %s()",
                    name,
                    aplBodyName
                );
            }
            mainBodyCode = concat(output, "\n");
            outputPool.release(output);
        } else {
            mainBodyCode = `${defaultBodyName}()`;
        }
        let code;
        if (profile["actions.precombat"]) {
            const fmt = `
                if not InCombat() %s()
                %s
            `;
            code = format(fmt, precombatBodyName, mainBodyCode);
        } else {
            code = mainBodyCode;
        }
        return code;
    }
}
