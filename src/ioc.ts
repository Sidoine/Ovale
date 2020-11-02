import { OvaleClass } from "./Ovale";
import { OvaleScriptsClass } from "./Scripts";
import { OvaleOptionsClass } from "./Options";
import { OvalePaperDollClass } from "./states/PaperDoll";
import { OvaleActionBarClass } from "./ActionBar";
import { OvaleASTClass } from "./AST";
import { OvaleAuraClass } from "./states/Aura";
import { OvaleAzeriteArmor } from "./states/AzeriteArmor";
import { OvaleAzeriteEssenceClass } from "./states/AzeriteEssence";
import { BaseState } from "./BaseState";
import { OvaleBestActionClass } from "./BestAction";
import { OvaleBossModClass } from "./states/BossMod";
import { OvaleCompileClass } from "./Compile";
import { OvaleConditionClass } from "./Condition";
import { OvaleCooldownClass } from "./states/Cooldown";
import { OvaleDamageTakenClass } from "./states/DamageTaken";
import { OvaleDataClass } from "./Data";
import { OvaleDataBrokerClass } from "./DataBroker";
import { OvaleDebugClass } from "./Debug";
import { OvaleDemonHunterDemonicClass } from "./states/DemonHunterDemonic";
import { OvaleDemonHunterSoulFragmentsClass } from "./states/DemonHunterSoulFragments";
import { OvaleSigilClass } from "./states/DemonHunterSigils";
import { OvaleEnemiesClass } from "./states/Enemies";
import { OvaleEquipmentClass } from "./Equipment";
import { OvaleFrameModuleClass } from "./Frame";
import { OvaleFutureClass } from "./Future";
import { OvaleGUIDClass } from "./GUID";
import { OvaleHealthClass } from "./states/Health";
import { LastSpell } from "./LastSpell";
import { OvaleLossOfControlClass } from "./states/LossOfControl";
import { OvalePowerClass } from "./states/Power";
import { OvaleProfilerClass } from "./Profiler";
import { OvaleRecountClass } from "./Recount";
import { OvaleRunesClass } from "./states/Runes";
import { OvaleScoreClass } from "./Score";
import { OvaleSpellBookClass } from "./SpellBook";
import { OvaleSpellDamageClass } from "./states/SpellDamage";
import { OvaleSpellFlashClass } from "./SpellFlash";
import { OvaleSpellsClass } from "./Spells";
import { OvaleStaggerClass } from "./states/Stagger";
import { OvaleStanceClass } from "./states/Stance";
import { OvaleStateClass } from "./State";
import { OvaleTotemClass } from "./states/Totem";
import { Variables } from "./states/Variables";
import { OvaleVersionClass } from "./Version";
import { OvaleWarlockClass } from "./states/Warlock";
import { OvaleConditions } from "./conditions";
import { OvaleSimulationCraftClass } from "./simulationcraft/SimulationCraft";
import { Emiter } from "./simulationcraft/emiter";
import { Parser } from "./simulationcraft/parser";
import { Generator } from "./simulationcraft/generator";
import { Unparser } from "./simulationcraft/unparser";
import { Splitter } from "./simulationcraft/splitter";
import { OvaleRequirement } from "./Requirement";
import { OvaleCombatClass } from "./states/combat";
import { Covenant } from "./states/covenant";
import { Runeforge } from "./states/runeforge";
import { Conduit } from "./states/conduit";

/** Used to emulate IoC for integration tests */
export class IoC {
    public actionBar: OvaleActionBarClass;
    public ast: OvaleASTClass;
    public aura: OvaleAuraClass;
    public azeriteArmor: OvaleAzeriteArmor;
    public azeriteEssence: OvaleAzeriteEssenceClass;
    public baseState: BaseState;
    public bestAction: OvaleBestActionClass;
    public bossMod: OvaleBossModClass;
    public compile: OvaleCompileClass;
    public condition: OvaleConditionClass;
    public conditions: OvaleConditions;
    public cooldown: OvaleCooldownClass;
    public damageTaken: OvaleDamageTakenClass;
    public data: OvaleDataClass;
    public dataBroker: OvaleDataBrokerClass;
    public debug: OvaleDebugClass;
    public demonHunterDemonic: OvaleDemonHunterDemonicClass;
    public demonHunterSigils: OvaleSigilClass;
    public demonHunterSoulFragments: OvaleDemonHunterSoulFragmentsClass;
    public enemies: OvaleEnemiesClass;
    public equipment: OvaleEquipmentClass;
    public frame: OvaleFrameModuleClass;
    public future: OvaleFutureClass;
    public guid: OvaleGUIDClass;
    public health: OvaleHealthClass;
    public lastSpell: LastSpell;
    public lossOfControl: OvaleLossOfControlClass;
    public options: OvaleOptionsClass;
    public ovale: OvaleClass;
    public paperDoll: OvalePaperDollClass;
    public power: OvalePowerClass;
    public profiler: OvaleProfilerClass;
    public recount: OvaleRecountClass;
    public requirement: OvaleRequirement;
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

    constructor() {
        // TODO créer configuration avec la partie GUI et rajouter une méthode register à appeler ici comme pour les states
        this.ovale = new OvaleClass();
        this.options = new OvaleOptionsClass(this.ovale);
        this.debug = new OvaleDebugClass(this.ovale, this.options);
        this.profiler = new OvaleProfilerClass(this.options, this.ovale);
        this.equipment = new OvaleEquipmentClass(
            this.ovale,
            this.debug,
            this.profiler
        );
        this.lastSpell = new LastSpell();
        this.paperDoll = new OvalePaperDollClass(
            this.equipment,
            this.ovale,
            this.debug,
            this.profiler,
            this.lastSpell
        );
        this.baseState = new BaseState();
        this.condition = new OvaleConditionClass(this.baseState);
        this.guid = new OvaleGUIDClass(this.ovale, this.debug, this.condition);
        this.requirement = new OvaleRequirement(this.baseState, this.guid);
        this.data = new OvaleDataClass(
            this.baseState,
            this.guid,
            this.requirement
        );
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
            this.debug,
            this.profiler,
            this.spellBook,
            this.requirement
        );
        this.demonHunterSigils = new OvaleSigilClass(
            this.paperDoll,
            this.ovale,
            this.spellBook
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
            this.profiler,
            this.spellBook,
            this.requirement
        );
        this.stance = new OvaleStanceClass(
            this.debug,
            this.ovale,
            this.profiler,
            this.data,
            this.requirement
        );
        this.enemies = new OvaleEnemiesClass(
            this.guid,
            this.ovale,
            this.profiler,
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
            this.profiler,
            this.stance,
            this.requirement,
            this.spellBook
        );
        this.health = new OvaleHealthClass(
            this.guid,
            this.baseState,
            this.ovale,
            this.options,
            this.debug,
            this.profiler,
            this.requirement
        );
        this.lossOfControl = new OvaleLossOfControlClass(
            this.ovale,
            this.debug,
            this.requirement
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
        const combat = new OvaleCombatClass(
            this.ovale,
            this.debug,
            this.spellBook,
            this.requirement
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
            this.profiler,
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
            this.equipment,
            this.ast,
            this.condition,
            this.cooldown,
            this.paperDoll,
            this.data,
            this.profiler,
            this.debug,
            this.options,
            this.ovale,
            this.score,
            this.spellBook,
            this.stance
        );
        this.power = new OvalePowerClass(
            this.debug,
            this.ovale,
            this.profiler,
            this.data,
            this.future,
            this.baseState,
            this.aura,
            this.paperDoll,
            this.requirement,
            this.spellBook,
            combat
        );
        this.stagger = new OvaleStaggerClass(this.ovale, combat);
        this.spellFlash = new OvaleSpellFlashClass(
            this.options,
            this.ovale,
            combat,
            this.data,
            this.spellBook,
            this.stance
        );
        this.totem = new OvaleTotemClass(
            this.ovale,
            this.state,
            this.profiler,
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
            this.spellBook
        );
        this.version = new OvaleVersionClass(
            this.ovale,
            this.options,
            this.debug
        );
        this.damageTaken = new OvaleDamageTakenClass(
            this.ovale,
            this.profiler,
            this.debug
        );
        this.spellDamage = new OvaleSpellDamageClass(this.ovale, this.profiler);
        this.demonHunterSoulFragments = new OvaleDemonHunterSoulFragmentsClass(
            this.aura,
            this.ovale,
            this.requirement,
            this.paperDoll
        );
        this.runes = new OvaleRunesClass(
            this.ovale,
            this.debug,
            this.profiler,
            this.data,
            this.power,
            this.paperDoll
        );
        this.actionBar = new OvaleActionBarClass(
            this.debug,
            this.ovale,
            this.profiler,
            this.spellBook
        );
        this.spells = new OvaleSpellsClass(
            this.spellBook,
            this.ovale,
            this.debug,
            this.profiler,
            this.data,
            this.requirement
        );
        this.bestAction = new OvaleBestActionClass(
            this.equipment,
            this.actionBar,
            this.data,
            this.cooldown,
            this.state,
            this.baseState,
            this.paperDoll,
            this.compile,
            this.condition,
            this.ovale,
            this.guid,
            this.power,
            this.future,
            this.spellBook,
            this.profiler,
            this.debug,
            this.variables,
            this.runes,
            this.spells
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
            this.guid,
            this.spellFlash,
            this.spellBook,
            this.bestAction,
            combat
        );
        this.dataBroker = new OvaleDataBrokerClass(
            this.paperDoll,
            this.frame,
            this.options,
            this.ovale,
            this.debug,
            this.scripts,
            this.version
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
        this.bossMod = new OvaleBossModClass(
            this.ovale,
            this.debug,
            this.profiler,
            combat
        );
        this.demonHunterDemonic = new OvaleDemonHunterDemonicClass(
            this.aura,
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
            this.ovale
        );
        this.recount = new OvaleRecountClass(this.ovale, this.score);
        const covenant = new Covenant(this.ovale, this.debug);
        const runeforge = new Runeforge(this.debug);
        const conduit = new Conduit(this.debug);
        this.conditions = new OvaleConditions(
            this.condition,
            this.data,
            this.compile,
            this.paperDoll,
            this.azeriteArmor,
            this.azeriteEssence,
            this.aura,
            this.baseState,
            this.cooldown,
            this.future,
            this.spellBook,
            this.frame,
            this.guid,
            this.damageTaken,
            this.warlock,
            this.power,
            this.enemies,
            this.variables,
            this.lastSpell,
            this.equipment,
            this.health,
            this.options,
            this.lossOfControl,
            this.spellDamage,
            this.stagger,
            this.totem,
            this.demonHunterSigils,
            this.demonHunterSoulFragments,
            this.bestAction,
            this.runes,
            this.stance,
            this.bossMod,
            this.spells
        );

        // States
        this.state.RegisterState(this.cooldown);
        this.state.RegisterState(this.paperDoll);
        this.state.RegisterState(this.baseState);
        this.state.RegisterState(this.demonHunterSigils);
        this.state.RegisterState(this.enemies);
        this.state.RegisterState(this.future);
        this.state.RegisterState(this.health);
        this.state.RegisterState(this.lossOfControl);
        this.state.RegisterState(this.power);
        this.state.RegisterState(this.stagger);
        this.state.RegisterState(this.stance);
        this.state.RegisterState(this.totem);
        this.state.RegisterState(this.variables);
        this.state.RegisterState(this.warlock);
        this.state.RegisterState(this.runes);
        this.state.RegisterState(combat);

        // Conditions
        runeforge.registerConditions(this.condition);
        covenant.registerConditions(this.condition);
        combat.registerConditions(this.condition);
        conduit.registerConditions(this.condition);
    }
}
