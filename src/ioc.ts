import { OvaleClass } from "./Ovale";
import { OvaleScriptsClass } from "./engine/scripts";
import { OvaleOptionsClass } from "./ui/Options";
import { OvalePaperDollClass } from "./states/PaperDoll";
import { OvaleActionBarClass } from "./engine/action-bar";
import { CombatLogEvent } from "./engine/combat-log-event";
import { OvaleASTClass } from "./engine/ast";
import { OvaleAuraClass } from "./states/Aura";
import { OvaleAzeriteArmor } from "./states/AzeriteArmor";
import { OvaleAzeriteEssenceClass } from "./states/AzeriteEssence";
import { BaseState } from "./states/BaseState";
import { OvaleBestActionClass } from "./engine/best-action";
import { Bloodtalons } from "./states/bloodtalons";
import { OvaleBossModClass } from "./states/BossMod";
import { OvaleCompileClass } from "./engine/compile";
import { OvaleConditionClass } from "./engine/condition";
import { OvaleCooldownClass } from "./states/Cooldown";
import { OvaleDamageTakenClass } from "./states/DamageTaken";
import { OvaleDataClass } from "./engine/data";
import { OvaleDataBrokerClass } from "./ui/DataBroker";
import { DebugTools } from "./engine/debug";
import { OvaleDemonHunterDemonicClass } from "./states/DemonHunterDemonic";
import { OvaleDemonHunterSoulFragmentsClass } from "./states/DemonHunterSoulFragments";
import { OvaleSigilClass } from "./states/DemonHunterSigils";
import { Eclipse } from "./states/eclipse";
import { OvaleEnemiesClass } from "./states/Enemies";
import { OvaleEquipmentClass } from "./states/Equipment";
import { OvaleFrameModuleClass } from "./ui/Frame";
import { OvaleFutureClass } from "./states/Future";
import { Guids } from "./engine/guid";
import { OvaleHealthClass } from "./states/Health";
import { LastSpell } from "./states/LastSpell";
import { OvaleLossOfControlClass } from "./states/LossOfControl";
import { OvalePowerClass } from "./states/Power";
import { OvaleRecountClass } from "./ui/Recount";
import { OvaleRunesClass } from "./states/Runes";
import { OvaleScoreClass } from "./ui/Score";
import { OvaleSpellBookClass } from "./states/SpellBook";
import { OvaleSpellDamageClass } from "./states/SpellDamage";
import { OvaleSpellFlashClass } from "./ui/SpellFlash";
import { OvaleSpellsClass } from "./states/Spells";
import { OvaleStaggerClass } from "./states/Stagger";
import { OvaleStanceClass } from "./states/Stance";
import { OvaleStateClass } from "./engine/state";
import { OvaleTotemClass } from "./states/Totem";
import { Variables } from "./states/Variables";
import { OvaleVersionClass } from "./ui/Version";
import { OvaleWarlockClass } from "./states/Warlock";
import { OvaleConditions } from "./states/conditions";
import { OvaleSimulationCraftClass } from "./simulationcraft/SimulationCraft";
import { Emiter } from "./simulationcraft/emiter";
import { Parser } from "./simulationcraft/parser";
import { Generator } from "./simulationcraft/generator";
import { Unparser } from "./simulationcraft/unparser";
import { Splitter } from "./simulationcraft/splitter";
import { OvaleCombatClass } from "./states/combat";
import { Covenant } from "./states/covenant";
import { Runeforge } from "./states/runeforge";
import { Soulbind } from "./states/soulbind";
import { Runner } from "./engine/runner";
import { Controls } from "./engine/controls";
import { SpellActivationGlow } from "./states/spellactivationglow";

/** Used to emulate IoC for integration tests */
export class IoC {
    public actionBar: OvaleActionBarClass;
    public ast: OvaleASTClass;
    public aura: OvaleAuraClass;
    public azeriteArmor: OvaleAzeriteArmor;
    public azeriteEssence: OvaleAzeriteEssenceClass;
    public baseState: BaseState;
    public bestAction: OvaleBestActionClass;
    public bloodtalons: Bloodtalons;
    public bossMod: OvaleBossModClass;
    public combatLogEvent: CombatLogEvent;
    public compile: OvaleCompileClass;
    public condition: OvaleConditionClass;
    public conditions: OvaleConditions;
    public cooldown: OvaleCooldownClass;
    public damageTaken: OvaleDamageTakenClass;
    public data: OvaleDataClass;
    public dataBroker: OvaleDataBrokerClass;
    public debug: DebugTools;
    public demonHunterDemonic: OvaleDemonHunterDemonicClass;
    public demonHunterSigils: OvaleSigilClass;
    public demonHunterSoulFragments: OvaleDemonHunterSoulFragmentsClass;
    public eclipse: Eclipse;
    public enemies: OvaleEnemiesClass;
    public equipment: OvaleEquipmentClass;
    public frame: OvaleFrameModuleClass;
    public future: OvaleFutureClass;
    public guid: Guids;
    public health: OvaleHealthClass;
    public lastSpell: LastSpell;
    public lossOfControl: OvaleLossOfControlClass;
    public options: OvaleOptionsClass;
    public ovale: OvaleClass;
    public paperDoll: OvalePaperDollClass;
    public power: OvalePowerClass;
    public recount: OvaleRecountClass;
    public runes: OvaleRunesClass;
    public score: OvaleScoreClass;
    public scripts: OvaleScriptsClass;
    private emiter: Emiter;
    private parser: Parser;
    private generator: Generator;
    private unparser: Unparser;
    private splitter: Splitter;
    public simulationCraft: OvaleSimulationCraftClass;
    public spellBook: OvaleSpellBookClass;
    public spellDamage: OvaleSpellDamageClass;
    public spellFlash: OvaleSpellFlashClass;
    public spells: OvaleSpellsClass;
    public stagger: OvaleStaggerClass;
    public stance: OvaleStanceClass;
    public state: OvaleStateClass;
    public totem: OvaleTotemClass;
    public variables: Variables;
    public version: OvaleVersionClass;
    public warlock: OvaleWarlockClass;
    public runner: Runner;
    public spellActivationGlow: SpellActivationGlow;

    constructor() {
        // TODO créer configuration avec la partie GUI et rajouter une méthode register à appeler ici comme pour les states
        this.ovale = new OvaleClass();
        this.options = new OvaleOptionsClass(this.ovale);
        this.debug = new DebugTools(this.ovale, this.options);
        this.lastSpell = new LastSpell();
        this.baseState = new BaseState();
        this.condition = new OvaleConditionClass(this.baseState);
        const controls = new Controls();
        const runner = new Runner(this.debug, this.baseState, this.condition);
        this.data = new OvaleDataClass(runner, this.debug);
        this.combatLogEvent = new CombatLogEvent(this.ovale, this.debug);
        this.guid = new Guids(this.ovale, this.debug);
        this.equipment = new OvaleEquipmentClass(
            this.ovale,
            this.debug,
            this.data
        );
        this.paperDoll = new OvalePaperDollClass(
            this.equipment,
            this.ovale,
            this.debug
        );
        const covenant = new Covenant(this.ovale, this.debug);
        const runeforge = new Runeforge(this.ovale, this.debug, this.equipment);
        const soulbind = new Soulbind(this.ovale, this.debug);
        this.spellBook = new OvaleSpellBookClass(
            this.ovale,
            this.debug,
            this.data
        );
        this.cooldown = new OvaleCooldownClass(
            this.paperDoll,
            this.data,
            this.lastSpell,
            this.ovale,
            this.debug
        );
        this.demonHunterSigils = new OvaleSigilClass(
            this.ovale,
            this.debug,
            this.paperDoll,
            this.spellBook
        );
        const combat = new OvaleCombatClass(
            this.ovale,
            this.debug,
            this.spellBook
        );
        this.power = new OvalePowerClass(
            this.debug,
            this.ovale,
            this.data,
            this.baseState,
            this.spellBook,
            combat
        );
        this.state = new OvaleStateClass();
        this.aura = new OvaleAuraClass(
            this.state,
            this.paperDoll,
            this.baseState,
            this.data,
            this.guid,
            this.lastSpell,
            this.options,
            this.debug,
            this.ovale,
            this.spellBook,
            this.power,
            this.combatLogEvent
        );
        this.bloodtalons = new Bloodtalons(
            this.ovale,
            this.debug,
            this.aura,
            this.paperDoll,
            this.spellBook
        );
        this.eclipse = new Eclipse(
            this.ovale,
            this.debug,
            this.aura,
            combat,
            this.paperDoll,
            this.spellBook
        );
        this.stance = new OvaleStanceClass(this.debug, this.ovale, this.data);
        this.enemies = new OvaleEnemiesClass(
            this.guid,
            this.combatLogEvent,
            this.ovale,
            this.debug
        );
        this.future = new OvaleFutureClass(
            this.data,
            this.aura,
            this.paperDoll,
            this.baseState,
            this.cooldown,
            this.state,
            this.guid,
            this.lastSpell,
            this.ovale,
            this.debug,
            this.stance,
            this.spellBook,
            this.combatLogEvent,
            runner
        );
        this.health = new OvaleHealthClass(
            this.guid,
            this.ovale,
            this.options,
            this.debug,
            this.combatLogEvent
        );
        this.lossOfControl = new OvaleLossOfControlClass(
            this.ovale,
            this.debug
        );
        this.azeriteEssence = new OvaleAzeriteEssenceClass(
            this.ovale,
            this.debug
        );
        this.azeriteArmor = new OvaleAzeriteArmor(
            this.equipment,
            this.ovale,
            this.debug
        );
        this.scripts = new OvaleScriptsClass(
            this.ovale,
            this.options,
            this.paperDoll,
            this.debug
        );
        this.ast = new OvaleASTClass(
            this.condition,
            this.debug,
            this.scripts,
            this.spellBook
        );
        this.score = new OvaleScoreClass(
            this.ovale,
            this.future,
            this.debug,
            this.spellBook,
            combat
        );
        this.compile = new OvaleCompileClass(
            this.azeriteArmor,
            this.ast,
            this.condition,
            this.cooldown,
            this.data,
            this.debug,
            this.ovale,
            this.score,
            this.spellBook,
            controls,
            this.scripts
        );
        this.stagger = new OvaleStaggerClass(
            this.ovale,
            this.debug,
            this.aura,
            this.health,
            this.paperDoll,
            this.combatLogEvent
        );
        this.actionBar = new OvaleActionBarClass(
            this.debug,
            this.ovale,
            this.spellBook
        );
        this.spellFlash = new OvaleSpellFlashClass(
            this.options,
            this.ovale,
            combat,
            this.actionBar
        );
        this.totem = new OvaleTotemClass(
            this.ovale,
            this.state,
            this.data,
            this.future,
            this.aura,
            this.spellBook,
            this.debug
        );
        this.variables = new Variables(combat, this.baseState, this.debug);
        this.warlock = new OvaleWarlockClass(
            this.ovale,
            this.aura,
            this.paperDoll,
            this.spellBook,
            this.future,
            this.power,
            this.combatLogEvent
        );
        this.version = new OvaleVersionClass(
            this.ovale,
            this.options,
            this.debug
        );
        this.damageTaken = new OvaleDamageTakenClass(
            this.ovale,
            this.debug,
            this.combatLogEvent
        );
        this.spellDamage = new OvaleSpellDamageClass(
            this.ovale,
            this.combatLogEvent
        );
        this.demonHunterSoulFragments = new OvaleDemonHunterSoulFragmentsClass(
            this.ovale,
            this.debug,
            this.aura,
            this.combatLogEvent,
            this.paperDoll
        );
        this.runes = new OvaleRunesClass(
            this.ovale,
            this.debug,
            this.data,
            this.power,
            this.paperDoll
        );
        this.spellActivationGlow = new SpellActivationGlow(
            this.ovale,
            this.debug
        );
        this.spells = new OvaleSpellsClass(
            this.spellBook,
            this.ovale,
            this.debug,
            this.data,
            this.power,
            this.runes,
            this.spellActivationGlow
        );
        this.bestAction = new OvaleBestActionClass(
            this.equipment,
            this.actionBar,
            this.data,
            this.cooldown,
            this.ovale,
            this.guid,
            this.future,
            this.spellBook,
            this.debug,
            this.variables,
            this.spells,
            runner
        );
        this.frame = new OvaleFrameModuleClass(
            this.state,
            this.compile,
            this.future,
            this.baseState,
            this.enemies,
            this.ovale,
            this.options,
            this.debug,
            this.spellFlash,
            this.spellBook,
            this.bestAction,
            combat,
            runner,
            controls,
            this.scripts,
            this.actionBar,
            this.guid
        );
        this.dataBroker = new OvaleDataBrokerClass(
            this.paperDoll,
            this.frame,
            this.options,
            this.ovale,
            this.debug,
            this.scripts
        );
        this.unparser = new Unparser(this.debug);
        this.emiter = new Emiter(
            this.debug,
            this.ast,
            this.data,
            this.unparser
        );
        this.parser = new Parser(this.debug);
        this.splitter = new Splitter(this.ast, this.debug, this.data);
        this.bossMod = new OvaleBossModClass(this.ovale, this.debug, combat);
        this.demonHunterDemonic = new OvaleDemonHunterDemonicClass(
            this.aura,
            this.paperDoll,
            this.spellBook,
            this.ovale,
            this.debug
        );
        this.generator = new Generator(this.ast, this.data);
        this.simulationCraft = new OvaleSimulationCraftClass(
            this.options,
            this.data,
            this.emiter,
            this.ast,
            this.parser,
            this.unparser,
            this.debug,
            this.compile,
            this.splitter,
            this.generator,
            this.ovale,
            controls
        );
        this.recount = new OvaleRecountClass(this.ovale, this.score);
        this.conditions = new OvaleConditions(
            this.condition,
            this.data,
            this.paperDoll,
            this.azeriteEssence,
            this.aura,
            this.baseState,
            this.bloodtalons,
            this.cooldown,
            this.future,
            this.spellBook,
            this.frame,
            this.guid,
            this.damageTaken,
            this.power,
            this.enemies,
            this.lastSpell,
            this.health,
            this.options,
            this.lossOfControl,
            this.spellDamage,
            this.totem,
            this.demonHunterSigils,
            this.demonHunterSoulFragments,
            this.runes,
            this.bossMod,
            this.spells
        );

        this.runner = runner;

        // States
        this.state.registerState(this.cooldown);
        this.state.registerState(this.paperDoll);
        this.state.registerState(this.baseState);
        this.state.registerState(this.bloodtalons);
        this.state.registerState(this.demonHunterDemonic);
        this.state.registerState(this.demonHunterSigils);
        this.state.registerState(this.demonHunterSoulFragments);
        this.state.registerState(this.eclipse);
        this.state.registerState(this.enemies);
        this.state.registerState(this.future);
        this.state.registerState(this.health);
        this.state.registerState(this.lossOfControl);
        this.state.registerState(this.power);
        this.state.registerState(this.stance);
        this.state.registerState(this.totem);
        this.state.registerState(this.variables);
        this.state.registerState(this.warlock);
        this.state.registerState(this.runes);
        this.state.registerState(combat);

        // Conditions
        runeforge.registerConditions(this.condition);
        covenant.registerConditions(this.condition);
        combat.registerConditions(this.condition);
        soulbind.registerConditions(this.condition);
        this.warlock.registerConditions(this.condition);
        this.aura.registerConditions(this.condition);
        this.eclipse.registerConditions(this.condition);
        this.future.registerConditions(this.condition);
        this.paperDoll.registerConditions(this.condition);
        this.equipment.registerConditions(this.condition);
        this.azeriteArmor.registerConditions(this.condition);
        this.stagger.registerConditions(this.condition);
        this.stance.registerConditions(this.condition);
        this.spellActivationGlow.registerConditions(this.condition);
    }
}
