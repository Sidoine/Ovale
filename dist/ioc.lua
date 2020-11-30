local __exports = LibStub:NewLibrary("ovale/ioc", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local OvaleClass = __Ovale.OvaleClass
local __enginescripts = LibStub:GetLibrary("ovale/engine/scripts")
local OvaleScriptsClass = __enginescripts.OvaleScriptsClass
local __uiOptions = LibStub:GetLibrary("ovale/ui/Options")
local OvaleOptionsClass = __uiOptions.OvaleOptionsClass
local __statesPaperDoll = LibStub:GetLibrary("ovale/states/PaperDoll")
local OvalePaperDollClass = __statesPaperDoll.OvalePaperDollClass
local __engineactionbar = LibStub:GetLibrary("ovale/engine/action-bar")
local OvaleActionBarClass = __engineactionbar.OvaleActionBarClass
local __engineast = LibStub:GetLibrary("ovale/engine/ast")
local OvaleASTClass = __engineast.OvaleASTClass
local __statesAura = LibStub:GetLibrary("ovale/states/Aura")
local OvaleAuraClass = __statesAura.OvaleAuraClass
local __statesAzeriteArmor = LibStub:GetLibrary("ovale/states/AzeriteArmor")
local OvaleAzeriteArmor = __statesAzeriteArmor.OvaleAzeriteArmor
local __statesAzeriteEssence = LibStub:GetLibrary("ovale/states/AzeriteEssence")
local OvaleAzeriteEssenceClass = __statesAzeriteEssence.OvaleAzeriteEssenceClass
local __statesBaseState = LibStub:GetLibrary("ovale/states/BaseState")
local BaseState = __statesBaseState.BaseState
local __enginebestaction = LibStub:GetLibrary("ovale/engine/best-action")
local OvaleBestActionClass = __enginebestaction.OvaleBestActionClass
local __statesBossMod = LibStub:GetLibrary("ovale/states/BossMod")
local OvaleBossModClass = __statesBossMod.OvaleBossModClass
local __enginecompile = LibStub:GetLibrary("ovale/engine/compile")
local OvaleCompileClass = __enginecompile.OvaleCompileClass
local __enginecondition = LibStub:GetLibrary("ovale/engine/condition")
local OvaleConditionClass = __enginecondition.OvaleConditionClass
local __statesCooldown = LibStub:GetLibrary("ovale/states/Cooldown")
local OvaleCooldownClass = __statesCooldown.OvaleCooldownClass
local __statesDamageTaken = LibStub:GetLibrary("ovale/states/DamageTaken")
local OvaleDamageTakenClass = __statesDamageTaken.OvaleDamageTakenClass
local __enginedata = LibStub:GetLibrary("ovale/engine/data")
local OvaleDataClass = __enginedata.OvaleDataClass
local __uiDataBroker = LibStub:GetLibrary("ovale/ui/DataBroker")
local OvaleDataBrokerClass = __uiDataBroker.OvaleDataBrokerClass
local __enginedebug = LibStub:GetLibrary("ovale/engine/debug")
local OvaleDebugClass = __enginedebug.OvaleDebugClass
local __statesDemonHunterDemonic = LibStub:GetLibrary("ovale/states/DemonHunterDemonic")
local OvaleDemonHunterDemonicClass = __statesDemonHunterDemonic.OvaleDemonHunterDemonicClass
local __statesDemonHunterSoulFragments = LibStub:GetLibrary("ovale/states/DemonHunterSoulFragments")
local OvaleDemonHunterSoulFragmentsClass = __statesDemonHunterSoulFragments.OvaleDemonHunterSoulFragmentsClass
local __statesDemonHunterSigils = LibStub:GetLibrary("ovale/states/DemonHunterSigils")
local OvaleSigilClass = __statesDemonHunterSigils.OvaleSigilClass
local __statesEnemies = LibStub:GetLibrary("ovale/states/Enemies")
local OvaleEnemiesClass = __statesEnemies.OvaleEnemiesClass
local __statesEquipment = LibStub:GetLibrary("ovale/states/Equipment")
local OvaleEquipmentClass = __statesEquipment.OvaleEquipmentClass
local __uiFrame = LibStub:GetLibrary("ovale/ui/Frame")
local OvaleFrameModuleClass = __uiFrame.OvaleFrameModuleClass
local __statesFuture = LibStub:GetLibrary("ovale/states/Future")
local OvaleFutureClass = __statesFuture.OvaleFutureClass
local __engineguid = LibStub:GetLibrary("ovale/engine/guid")
local OvaleGUIDClass = __engineguid.OvaleGUIDClass
local __statesHealth = LibStub:GetLibrary("ovale/states/Health")
local OvaleHealthClass = __statesHealth.OvaleHealthClass
local __statesLastSpell = LibStub:GetLibrary("ovale/states/LastSpell")
local LastSpell = __statesLastSpell.LastSpell
local __statesLossOfControl = LibStub:GetLibrary("ovale/states/LossOfControl")
local OvaleLossOfControlClass = __statesLossOfControl.OvaleLossOfControlClass
local __statesPower = LibStub:GetLibrary("ovale/states/Power")
local OvalePowerClass = __statesPower.OvalePowerClass
local __engineprofiler = LibStub:GetLibrary("ovale/engine/profiler")
local OvaleProfilerClass = __engineprofiler.OvaleProfilerClass
local __uiRecount = LibStub:GetLibrary("ovale/ui/Recount")
local OvaleRecountClass = __uiRecount.OvaleRecountClass
local __statesRunes = LibStub:GetLibrary("ovale/states/Runes")
local OvaleRunesClass = __statesRunes.OvaleRunesClass
local __uiScore = LibStub:GetLibrary("ovale/ui/Score")
local OvaleScoreClass = __uiScore.OvaleScoreClass
local __statesSpellBook = LibStub:GetLibrary("ovale/states/SpellBook")
local OvaleSpellBookClass = __statesSpellBook.OvaleSpellBookClass
local __statesSpellDamage = LibStub:GetLibrary("ovale/states/SpellDamage")
local OvaleSpellDamageClass = __statesSpellDamage.OvaleSpellDamageClass
local __uiSpellFlash = LibStub:GetLibrary("ovale/ui/SpellFlash")
local OvaleSpellFlashClass = __uiSpellFlash.OvaleSpellFlashClass
local __statesSpells = LibStub:GetLibrary("ovale/states/Spells")
local OvaleSpellsClass = __statesSpells.OvaleSpellsClass
local __statesStagger = LibStub:GetLibrary("ovale/states/Stagger")
local OvaleStaggerClass = __statesStagger.OvaleStaggerClass
local __statesStance = LibStub:GetLibrary("ovale/states/Stance")
local OvaleStanceClass = __statesStance.OvaleStanceClass
local __enginestate = LibStub:GetLibrary("ovale/engine/state")
local OvaleStateClass = __enginestate.OvaleStateClass
local __statesTotem = LibStub:GetLibrary("ovale/states/Totem")
local OvaleTotemClass = __statesTotem.OvaleTotemClass
local __statesVariables = LibStub:GetLibrary("ovale/states/Variables")
local Variables = __statesVariables.Variables
local __uiVersion = LibStub:GetLibrary("ovale/ui/Version")
local OvaleVersionClass = __uiVersion.OvaleVersionClass
local __statesWarlock = LibStub:GetLibrary("ovale/states/Warlock")
local OvaleWarlockClass = __statesWarlock.OvaleWarlockClass
local __statesconditions = LibStub:GetLibrary("ovale/states/conditions")
local OvaleConditions = __statesconditions.OvaleConditions
local __simulationcraftSimulationCraft = LibStub:GetLibrary("ovale/simulationcraft/SimulationCraft")
local OvaleSimulationCraftClass = __simulationcraftSimulationCraft.OvaleSimulationCraftClass
local __simulationcraftemiter = LibStub:GetLibrary("ovale/simulationcraft/emiter")
local Emiter = __simulationcraftemiter.Emiter
local __simulationcraftparser = LibStub:GetLibrary("ovale/simulationcraft/parser")
local Parser = __simulationcraftparser.Parser
local __simulationcraftgenerator = LibStub:GetLibrary("ovale/simulationcraft/generator")
local Generator = __simulationcraftgenerator.Generator
local __simulationcraftunparser = LibStub:GetLibrary("ovale/simulationcraft/unparser")
local Unparser = __simulationcraftunparser.Unparser
local __simulationcraftsplitter = LibStub:GetLibrary("ovale/simulationcraft/splitter")
local Splitter = __simulationcraftsplitter.Splitter
local __statescombat = LibStub:GetLibrary("ovale/states/combat")
local OvaleCombatClass = __statescombat.OvaleCombatClass
local __statescovenant = LibStub:GetLibrary("ovale/states/covenant")
local Covenant = __statescovenant.Covenant
local __statesruneforge = LibStub:GetLibrary("ovale/states/runeforge")
local Runeforge = __statesruneforge.Runeforge
local __statesconduit = LibStub:GetLibrary("ovale/states/conduit")
local Conduit = __statesconduit.Conduit
local __enginerunner = LibStub:GetLibrary("ovale/engine/runner")
local Runner = __enginerunner.Runner
local __enginecontrols = LibStub:GetLibrary("ovale/engine/controls")
local Controls = __enginecontrols.Controls
__exports.IoC = __class(nil, {
    constructor = function(self)
        self.ovale = OvaleClass()
        self.options = OvaleOptionsClass(self.ovale)
        self.debug = OvaleDebugClass(self.ovale, self.options)
        self.profiler = OvaleProfilerClass(self.options, self.ovale)
        self.lastSpell = LastSpell()
        self.baseState = BaseState()
        self.condition = OvaleConditionClass(self.baseState)
        local controls = Controls()
        local runner = Runner(self.profiler, self.debug, self.baseState, self.condition)
        self.data = OvaleDataClass(runner)
        self.equipment = OvaleEquipmentClass(self.ovale, self.debug, self.profiler, self.data)
        self.paperDoll = OvalePaperDollClass(self.equipment, self.ovale, self.debug, self.profiler, self.lastSpell)
        self.guid = OvaleGUIDClass(self.ovale, self.debug, self.condition)
        self.spellBook = OvaleSpellBookClass(self.ovale, self.debug, self.data)
        self.cooldown = OvaleCooldownClass(self.paperDoll, self.data, self.lastSpell, self.ovale, self.debug, self.profiler, self.spellBook)
        self.demonHunterSigils = OvaleSigilClass(self.paperDoll, self.ovale, self.spellBook)
        self.state = OvaleStateClass()
        self.aura = OvaleAuraClass(self.state, self.paperDoll, self.baseState, self.data, self.guid, self.lastSpell, self.options, self.debug, self.ovale, self.profiler, self.spellBook)
        self.stance = OvaleStanceClass(self.debug, self.ovale, self.profiler, self.data)
        self.enemies = OvaleEnemiesClass(self.guid, self.ovale, self.profiler, self.debug)
        self.future = OvaleFutureClass(self.data, self.aura, self.paperDoll, self.baseState, self.cooldown, self.state, self.guid, self.lastSpell, self.ovale, self.debug, self.profiler, self.stance, self.spellBook, runner)
        self.health = OvaleHealthClass(self.guid, self.ovale, self.options, self.debug, self.profiler)
        self.lossOfControl = OvaleLossOfControlClass(self.ovale, self.debug)
        self.azeriteEssence = OvaleAzeriteEssenceClass(self.ovale, self.debug)
        self.azeriteArmor = OvaleAzeriteArmor(self.equipment, self.ovale, self.debug)
        local combat = OvaleCombatClass(self.ovale, self.debug, self.spellBook)
        self.scripts = OvaleScriptsClass(self.ovale, self.options, self.paperDoll, self.debug)
        self.ast = OvaleASTClass(self.condition, self.debug, self.profiler, self.scripts, self.spellBook)
        self.score = OvaleScoreClass(self.ovale, self.future, self.debug, self.spellBook, combat)
        self.compile = OvaleCompileClass(self.azeriteArmor, self.ast, self.condition, self.cooldown, self.paperDoll, self.data, self.profiler, self.debug, self.options, self.ovale, self.score, self.spellBook, controls)
        self.power = OvalePowerClass(self.debug, self.ovale, self.profiler, self.data, self.future, self.baseState, self.paperDoll, self.spellBook, combat)
        self.stagger = OvaleStaggerClass(self.ovale, combat, self.baseState, self.aura, self.health)
        self.spellFlash = OvaleSpellFlashClass(self.options, self.ovale, combat, self.data, self.spellBook, self.stance)
        self.totem = OvaleTotemClass(self.ovale, self.state, self.profiler, self.data, self.future, self.aura, self.spellBook, self.debug)
        self.variables = Variables(combat, self.baseState, self.debug)
        self.warlock = OvaleWarlockClass(self.ovale, self.aura, self.paperDoll, self.spellBook, self.future, self.power)
        self.version = OvaleVersionClass(self.ovale, self.options, self.debug)
        self.damageTaken = OvaleDamageTakenClass(self.ovale, self.profiler, self.debug)
        self.spellDamage = OvaleSpellDamageClass(self.ovale, self.profiler)
        self.demonHunterSoulFragments = OvaleDemonHunterSoulFragmentsClass(self.aura, self.ovale, self.paperDoll)
        self.runes = OvaleRunesClass(self.ovale, self.debug, self.profiler, self.data, self.power, self.paperDoll)
        self.actionBar = OvaleActionBarClass(self.debug, self.ovale, self.profiler, self.spellBook)
        self.spells = OvaleSpellsClass(self.spellBook, self.ovale, self.debug, self.profiler, self.data, self.power)
        self.bestAction = OvaleBestActionClass(self.equipment, self.actionBar, self.data, self.cooldown, self.state, self.ovale, self.guid, self.power, self.future, self.spellBook, self.profiler, self.debug, self.variables, self.runes, self.spells, runner)
        self.frame = OvaleFrameModuleClass(self.state, self.compile, self.future, self.baseState, self.enemies, self.ovale, self.options, self.debug, self.spellFlash, self.spellBook, self.bestAction, combat, runner, controls)
        self.dataBroker = OvaleDataBrokerClass(self.paperDoll, self.frame, self.options, self.ovale, self.debug, self.scripts, self.version)
        self.unparser = Unparser(self.debug)
        self.emiter = Emiter(self.debug, self.ast, self.data, self.unparser)
        self.parser = Parser(self.debug)
        self.splitter = Splitter(self.ast, self.debug, self.data)
        self.bossMod = OvaleBossModClass(self.ovale, self.debug, self.profiler, combat)
        self.demonHunterDemonic = OvaleDemonHunterDemonicClass(self.aura, self.ovale, self.debug)
        self.generator = Generator(self.ast, self.data)
        self.simulationCraft = OvaleSimulationCraftClass(self.options, self.data, self.emiter, self.ast, self.parser, self.unparser, self.debug, self.compile, self.splitter, self.generator, self.ovale, controls)
        self.recount = OvaleRecountClass(self.ovale, self.score)
        local covenant = Covenant(self.ovale, self.debug)
        local runeforge = Runeforge(self.debug)
        local conduit = Conduit(self.debug)
        self.conditions = OvaleConditions(self.condition, self.data, self.paperDoll, self.azeriteEssence, self.aura, self.baseState, self.cooldown, self.future, self.spellBook, self.frame, self.guid, self.damageTaken, self.power, self.enemies, self.lastSpell, self.health, self.options, self.lossOfControl, self.spellDamage, self.totem, self.demonHunterSigils, self.demonHunterSoulFragments, self.runes, self.bossMod, self.spells)
        self.state:RegisterState(self.cooldown)
        self.state:RegisterState(self.paperDoll)
        self.state:RegisterState(self.baseState)
        self.state:RegisterState(self.demonHunterSigils)
        self.state:RegisterState(self.enemies)
        self.state:RegisterState(self.future)
        self.state:RegisterState(self.health)
        self.state:RegisterState(self.lossOfControl)
        self.state:RegisterState(self.power)
        self.state:RegisterState(self.stagger)
        self.state:RegisterState(self.stance)
        self.state:RegisterState(self.totem)
        self.state:RegisterState(self.variables)
        self.state:RegisterState(self.warlock)
        self.state:RegisterState(self.runes)
        self.state:RegisterState(combat)
        runeforge:registerConditions(self.condition)
        covenant:registerConditions(self.condition)
        combat:registerConditions(self.condition)
        conduit:registerConditions(self.condition)
        self.warlock:registerConditions(self.condition)
        self.aura:registerConditions(self.condition)
        self.future:registerConditions(self.condition)
        self.paperDoll:registerConditions(self.condition)
        self.equipment:registerConditions(self.condition)
        self.azeriteArmor:registerConditions(self.condition)
        self.stagger:registerConditions(self.condition)
        self.stance:registerConditions(self.condition)
    end,
})
