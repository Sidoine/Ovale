import { registerScripts } from "./scripts/index";
import { CooldownState } from "./CooldownState";
import { OvaleCooldownClass } from "./Cooldown";
import { OvaleStateClass } from "./State";
import { OvalePaperDollClass } from "./PaperDoll";
import { OvaleEquipmentClass } from "./Equipment";
import { BaseState } from "./BaseState";
import { OvaleDataClass } from "./Data";
import { OvaleSigilClass } from "./DemonHunterSigils";
import { DemonHunterSoulFragmentsState } from "./DemonHunterSoulFragments";
import { OvaleEnemiesClass } from "./Enemies";
import { OvaleFutureClass } from "./Future";
import { OvaleAuraClass } from "./Aura";
import { OvaleGUIDClass } from "./GUID";
import { OvaleHealthClass } from "./Health";
import { LastSpell } from "./LastSpell";
import { OvaleLossOfControlClass } from "./LossOfControl";
import { OvaleClass } from "./Ovale";
import { OvaleDebugClass } from "./Debug";
import { OvaleOptionsClass } from "./Options";
import { OvaleProfilerClass } from "./Profiler";
import { OvaleScoreClass } from "./Score";
import { OvaleFrameModuleClass } from "./Frame";
import { OvaleCompileClass } from "./Compile";
import { OvaleAzeriteEssenceClass } from "./AzeriteEssence";
import { OvaleAzeriteArmor } from "./AzeriteArmor";
import { OvaleASTClass } from "./AST";
import { OvaleConditionClass } from "./Condition";
import { OvaleDataBrokerClass } from "./DataBroker";
import { OvaleScriptsClass } from "./Scripts";
import { OvaleSpellBookClass } from "./SpellBook";
import { OvaleSpellFlashClass } from "./SpellFlash";

registerScripts();

const ovale = new OvaleClass();
// TODO créer configuration avec la partie GUI et rajouter une méthode register à appeler ici comme pour les states
const ovaleOptions = new OvaleOptionsClass(ovale);
const ovaleDebug = new OvaleDebugClass(ovale, ovaleOptions);
const ovaleProfiler = new OvaleProfilerClass(ovaleOptions, ovale);
const ovaleEquipement = new OvaleEquipmentClass(ovale, ovaleDebug, ovaleProfiler);
const lastSpell = new LastSpell();
const ovalePaperDoll = new OvalePaperDollClass(ovaleEquipement, ovale, ovaleDebug, ovaleProfiler, lastSpell);
const baseState = new BaseState();
const ovaleGuid = new OvaleGUIDClass(ovale, ovaleDebug);
const ovaleData = new OvaleDataClass(baseState, ovaleGuid, ovale);
const ovaleSpellBook = new OvaleSpellBookClass(ovale, ovaleDebug);
const cooldown = new OvaleCooldownClass(ovalePaperDoll, ovaleData, lastSpell, ovale, ovaleDebug, ovaleProfiler, ovaleSpellBook);
const cooldownState = new CooldownState(cooldown, ovaleProfiler, ovaleDebug);
const ovaleSigil = new OvaleSigilClass(ovalePaperDoll, ovale, ovaleSpellBook);
const demonHunterSoulFragmentsState = new DemonHunterSoulFragmentsState();
const ovaleEnemies = new OvaleEnemiesClass(ovaleGuid, ovale, ovaleProfiler, ovaleDebug);
const state = new OvaleStateClass();
const ovaleAura = new OvaleAuraClass(state, ovalePaperDoll, baseState, ovaleData, ovaleGuid, lastSpell, ovaleOptions, ovaleDebug, ovale, ovaleProfiler, ovaleSpellBook);
const ovaleCooldown = new OvaleCooldownClass(ovalePaperDoll, ovaleData, lastSpell, ovale, ovaleDebug, ovaleProfiler, ovaleSpellBook);
const ovaleFuture = new OvaleFutureClass(ovaleData, ovaleAura, ovalePaperDoll, baseState, ovaleCooldown, state, ovaleGuid, lastSpell, ovale, ovaleDebug, ovaleProfiler);
const ovaleHealth = new OvaleHealthClass(ovaleGuid, baseState, ovale, ovaleOptions, ovaleDebug, ovaleProfiler);
const ovaleLossOfControl = new OvaleLossOfControlClass(ovale, ovaleDebug);
const ovaleAzeriteEssence = new OvaleAzeriteEssenceClass(ovale, ovaleDebug);
const ovaleAzeriteArmor = new OvaleAzeriteArmor(ovaleEquipement, ovale, ovaleDebug);
const ovaleCondition = new OvaleConditionClass(baseState);
const ovaleScripts = new OvaleScriptsClass(ovale, ovaleOptions, ovalePaperDoll);
const ovaleAst = new OvaleASTClass(ovaleCondition, ovaleDebug, ovaleProfiler, ovaleScripts, ovaleSpellBook);
const ovaleScore = new OvaleScoreClass(ovale, ovaleFuture, ovaleDebug, ovaleSpellBook);
const ovaleCompile = new OvaleCompileClass(ovaleAzeriteArmor, ovaleEquipement, ovaleAst, ovaleCondition, ovaleCooldown, ovalePaperDoll, ovaleData, ovaleProfiler, ovaleDebug, ovaleOptions, ovale, ovaleScore, ovaleSpellBook);
const ovaleSpellFlash = new OvaleSpellFlashClass(ovaleOptions, ovale, ovaleFuture, ovaleData, ovaleSpellBook);
const ovaleFrameModule = new OvaleFrameModuleClass(state, ovaleCompile, ovaleFuture, baseState, ovaleEnemies, ovale, ovaleOptions, ovaleDebug, ovaleGuid, ovaleSpellFlash);

// TODO
new OvaleDataBrokerClass(ovalePaperDoll, ovaleFrameModule, ovaleOptions, ovale, ovaleDebug, ovaleScripts);


state.RegisterState(cooldownState);
state.RegisterState(ovalePaperDoll);
state.RegisterState(baseState);
state.RegisterState(ovaleSigil);
state.RegisterState(demonHunterSoulFragmentsState);
state.RegisterState(ovaleEnemies);
state.RegisterState(ovaleFuture);
state.RegisterState(ovaleHealth);
state.RegisterState(ovaleLossOfControl);

// TODO OvaleDataBrokerClass