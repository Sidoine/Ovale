import { AstNode, isAstNodeWithChildren, OvaleASTClass } from "../engine/AST";
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
import { Annotation, OPTIONAL_SKILLS, Profile } from "./definitions";
import {
    LowerSpecialization,
    OvaleFunctionName,
    OvaleTaggedFunctionName,
    self_outputPool,
} from "./text-tools";
import { format } from "@wowts/string";
import { OvaleDataClass } from "../engine/Data";

const self_functionDefined: LuaObj<boolean> = {};
const self_functionUsed: LuaObj<boolean> = {};

function isNode(n: any): n is AstNode {
    return type(n) == "table";
}

function PreOrderTraversalMark(node: AstNode) {
    if (node.type == "custom_function") {
        self_functionUsed[node.name] = true;
    } else {
        if (node.type == "add_function") {
            self_functionDefined[node.name] = true;
        }
        if (isAstNodeWithChildren(node)) {
            for (const [, childNode] of ipairs(node.child)) {
                PreOrderTraversalMark(childNode);
            }
        }
    }
}
export function Mark(node: AstNode) {
    wipe(self_functionDefined);
    wipe(self_functionUsed);
    PreOrderTraversalMark(node);
}
function SweepComments(childNodes: LuaArray<AstNode>, index: number) {
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
export function Sweep(node: AstNode): [boolean, boolean | AstNode] {
    let isChanged: boolean;
    let isSwept: boolean | AstNode;
    [isChanged, isSwept] = [false, false];
    if (node.type == "add_function") {
    } else if (
        node.type == "custom_function" &&
        !self_functionDefined[node.name]
    ) {
        [isChanged, isSwept] = [true, true];
    } else if (node.type == "group" || node.type == "script") {
        const child = node.child;
        let index = lualength(child);
        while (index > 0) {
            const childNode = child[index];
            const [changed, swept] = Sweep(childNode);
            if (isNode(swept)) {
                if (swept.type == "group") {
                    // Directly insert a replacement group's statements in place of the replaced node.
                    remove(child, index);
                    for (let k = lualength(swept.child); k >= 1; k += -1) {
                        insert(child, index, swept.child[k]);
                    }
                    if (node.type == "group") {
                        const count = SweepComments(child, index);
                        index = index - count;
                    }
                } else {
                    child[index] = swept;
                }
            } else if (swept) {
                remove(child, index);
                if (node.type == "group") {
                    const count = SweepComments(child, index);
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
        [isChanged, isSwept] = Sweep(node.child[1]);
    } else if (node.type == "if") {
        [isChanged, isSwept] = Sweep(node.child[2]);
    } else if (node.type == "logical") {
        if (node.expressionType == "binary") {
            const [lhsNode, rhsNode] = [node.child[1], node.child[2]];
            for (const [index, childNode] of ipairs(node.child)) {
                const [changed, swept] = Sweep(childNode);
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
        let [changed, swept] = Sweep(node.child[2]);
        if (isNode(swept)) {
            node.child[2] = swept;
            isSwept = false;
        } else if (swept) {
            isSwept = swept;
        } else {
            [changed, swept] = Sweep(node.child[1]);
            if (isNode(swept)) {
                node.child[1] = swept;
                isSwept = false;
            } else if (swept) {
                isSwept = node.child[2];
            }
        }
        isChanged = isChanged || changed || !!isSwept;
    } else if (node.type == "simc_wait") {
        [isChanged, isSwept] = Sweep(node.child[1]);
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

    private InsertInterruptFunction(
        child: LuaArray<AstNode>,
        annotation: Annotation,
        interrupts: LuaArray<Spell>
    ) {
        const nodeList = annotation.astAnnotation.nodeList;
        const camelSpecialization = LowerSpecialization(annotation);
        const spells = interrupts || {};
        sort(spells, function (a, b) {
            return tonumber(a.order || 0) >= tonumber(b.order || 0);
        });
        const lines: LuaArray<string> = {};
        for (const [, spell] of pairs(spells)) {
            annotation.AddSymbol(spell.name);
            if (spell.addSymbol != undefined) {
                for (const [, v] of pairs(spell.addSymbol)) {
                    annotation.AddSymbol(v);
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
        const [node] = this.ovaleAst.ParseCode(
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

    public InsertInterruptFunctions(
        child: LuaArray<AstNode>,
        annotation: Annotation
    ) {
        const interrupts = {};
        const className = annotation.classId;

        if (this.ovaleData.PANDAREN_CLASSES[className]) {
            insert(interrupts, {
                name: "quaking_palm",
                stun: 1,
                order: 98,
            });
        }
        if (this.ovaleData.TAUREN_CLASSES[className]) {
            insert(interrupts, {
                name: "war_stomp",
                stun: 1,
                order: 99,
                range: "target.Distance(less 5)",
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
                    range: "target.Distance(less 12)",
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
                    range: "target.Distance(less 8)",
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
                    range: "target.Distance(less 10)",
                });
            }
            insert(interrupts, {
                name: "typhoon",
                knockback: 1,
                order: 110,
                range: "target.Distance(less 15)",
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
                range: "target.Distance(less 5)",
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
                    range: "target.Distance(less 10)",
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
                    name: "between_the_eyes",
                    stun: 1,
                    order: 30,
                    extraCondition: "ComboPoints() >= 1",
                });
                insert(interrupts, {
                    name: "gouge",
                    incapacitate: 1,
                    order: 100,
                });
            }
            if (
                annotation.specialization == "assassination" ||
                annotation.specialization == "subtlety"
            ) {
                insert(interrupts, {
                    name: "kidney_shot",
                    stun: 1,
                    order: 30,
                    extraCondition: "ComboPoints() >= 1",
                });
            }
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
                    range: "target.Distance(less 5)",
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
                range: "target.Distance(less 10)",
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
            this.InsertInterruptFunction(child, annotation, interrupts);
        }
        return lualength(interrupts);
    }
    public InsertSupportingFunctions(
        child: LuaArray<AstNode>,
        annotation: Annotation
    ) {
        let count = 0;
        const nodeList = annotation.astAnnotation.nodeList;
        const camelSpecialization = LowerSpecialization(annotation);
        if (annotation.melee == "DEATHKNIGHT") {
            const fmt = `
                AddFunction %sGetInMeleeRange
                {
                    if CheckBoxOn(opt_melee_range) and not target.InRange(death_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.AddSymbol("death_strike");
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
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.AddSymbol("chaos_strike");
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
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.AddSymbol("shear");
                count = count + 1;
            }
        }
        if (annotation.melee == "DRUID") {
            const fmt = `
                AddFunction %sGetInMeleeRange
                {
                    if CheckBoxOn(opt_melee_range) and Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred)
                    {
                        if target.InRange(wild_charge) Spell(wild_charge)
                        Texture(misc_arrowlup help=L(not_in_melee_range))
                    }
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.AddSymbol("mangle");
                annotation.AddSymbol("shred");
                annotation.AddSymbol("wild_charge");
                annotation.AddSymbol("wild_charge_bear");
                annotation.AddSymbol("wild_charge_cat");
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
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.AddSymbol("raptor_strike");
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
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.AddSymbol("revive_pet");
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
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.AddSymbol("tiger_palm");
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
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node) {
                insert(child, 1, node);
                annotation.AddSymbol("crusader_strike");
                annotation.AddSymbol("holy_shock");
                annotation.AddSymbol("judgment");
                count = count + 1;
            }
        }
        if (annotation.time_to_hpg_melee == "PALADIN") {
            const code = `
                AddFunction RetributionTimeToHPG
                {
                    SpellCooldown(crusader_strike hammer_of_wrath hammer_of_wrath_empowered judgment usable=1)
                }
            `;
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node) {
                insert(child, 1, node);
                annotation.AddSymbol("crusader_strike");
                annotation.AddSymbol("hammer_of_wrath");
                annotation.AddSymbol("judgment");
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
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            insert(child, 1, node);
            annotation.AddSymbol("crusader_strike");
            annotation.AddSymbol("holy_wrath");
            annotation.AddSymbol("judgment");
            annotation.AddSymbol("sanctified_wrath_talent");
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
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type == "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.AddSymbol("rebuke");
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
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.AddSymbol("kick");
                annotation.AddSymbol("shadowstep");
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
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.AddSymbol("feral_lunge");
                annotation.AddSymbol("stormstrike");
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
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "cd";
                annotation.AddSymbol("bloodlust");
                annotation.AddSymbol("heroism");
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
                        if SpellCharges(%s) == 0 and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
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
            const [node] = this.ovaleAst.ParseCode(
                "add_function",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (node && node.type === "add_function") {
                insert(child, 1, node);
                annotation.functionTag[node.name] = "shortcd";
                annotation.AddSymbol(charge);
                annotation.AddSymbol("heroic_leap");
                annotation.AddSymbol("pummel");
                count = count + 1;
            }
        }
        if (annotation.use_item) {
            const fmt = `
                AddFunction %sUseItemActions
                {
                    Item(Trinket0Slot usable=1 text=13)
                    Item(Trinket1Slot usable=1 text=14)
                }
            `;
            const code = format(fmt, camelSpecialization);
            const [node] = this.ovaleAst.ParseCode(
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

    private AddOptionalSkillCheckBox(
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
        const [node] = this.ovaleAst.ParseCode(
            "checkbox",
            code,
            nodeList,
            annotation.astAnnotation
        );
        insert(child, 1, node);
        annotation.AddSymbol(skill);
        return 1;
    }

    public InsertSupportingControls(
        child: LuaArray<AstNode>,
        annotation: Annotation
    ) {
        let count = 0;
        for (const [skill, data] of pairs(OPTIONAL_SKILLS)) {
            count =
                count +
                this.AddOptionalSkillCheckBox(
                    child,
                    annotation,
                    data,
                    <keyof typeof OPTIONAL_SKILLS>skill
                );
        }
        const nodeList = annotation.astAnnotation.nodeList;
        const ifSpecialization = `enabled=(specialization(${annotation.specialization}))`;
        if (annotation.using_apl && next(annotation.using_apl)) {
            for (const [name] of pairs(annotation.using_apl)) {
                if (name != "normal") {
                    const fmt = `
                        AddListItem(opt_using_apl %s "%s APL")
                    `;
                    const code = format(fmt, name, name);
                    const [node] = this.ovaleAst.ParseCode(
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
                const [node] = this.ovaleAst.ParseCode(
                    "list_item",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                insert(child, 1, node);
            }
        }
        if (annotation.options) {
            for (const [v] of pairs(annotation.options)) {
                const fmt = `
                    AddCheckBox(${v} L(${v}) default %s)
                `;
                const code = format(fmt, ifSpecialization);
                const [node] = this.ovaleAst.ParseCode(
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
            const [node] = this.ovaleAst.ParseCode(
                "checkbox",
                code,
                nodeList,
                annotation.astAnnotation
            );
            insert(child, 1, node);
            annotation.AddSymbol(legendaryRing);
            count = count + 1;
        }
        if (annotation.opt_use_consumables) {
            const fmt = `
                AddCheckBox(opt_use_consumables L(opt_use_consumables) default %s)
            `;
            const code = format(fmt, ifSpecialization);
            const [node] = this.ovaleAst.ParseCode(
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
            const [node] = this.ovaleAst.ParseCode(
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
            const [node] = this.ovaleAst.ParseCode(
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
            const [node] = this.ovaleAst.ParseCode(
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
    public InsertVariables(child: LuaArray<AstNode>, annotation: Annotation) {
        for (const [, v] of pairs(annotation.variable)) {
            insert(child, 1, v);
        }
    }
    public GenerateIconBody(tag: string, profile: Profile) {
        const annotation = profile.annotation;
        const precombatName = OvaleFunctionName("precombat", annotation);
        const defaultName = OvaleFunctionName("_default", annotation);
        const [precombatBodyName] = OvaleTaggedFunctionName(precombatName, tag);
        const [defaultBodyName] = OvaleTaggedFunctionName(defaultName, tag);
        let mainBodyCode;
        if (annotation.using_apl && next(annotation.using_apl)) {
            const output = self_outputPool.Get();
            output[lualength(output) + 1] = format(
                "if List(opt_using_apl normal) %s()",
                defaultBodyName
            );
            for (const [name] of pairs(annotation.using_apl)) {
                const aplName = OvaleFunctionName(<string>name, annotation);
                const [aplBodyName] = OvaleTaggedFunctionName(aplName, tag);
                output[lualength(output) + 1] = format(
                    "if List(opt_using_apl %s) %s()",
                    name,
                    aplBodyName
                );
            }
            mainBodyCode = concat(output, "\n");
            self_outputPool.Release(output);
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
