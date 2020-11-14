local __exports = LibStub:NewLibrary("ovale/ioc", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local OvaleClass = __Ovale.OvaleClass
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScriptsClass = __Scripts.OvaleScriptsClass
local __Options = LibStub:GetLibrary("ovale/Options")
local OvaleOptionsClass = __Options.OvaleOptionsClass
local __statesPaperDoll = LibStub:GetLibrary("ovale/states/PaperDoll")
local OvalePaperDollClass = __statesPaperDoll.OvalePaperDollClass
local __ActionBar = LibStub:GetLibrary("ovale/ActionBar")
local OvaleActionBarClass = __ActionBar.OvaleActionBarClass
local __AST = LibStub:GetLibrary("ovale/AST")
local OvaleASTClass = __AST.OvaleASTClass
local __statesAura = LibStub:GetLibrary("ovale/states/Aura")
local OvaleAuraClass = __statesAura.OvaleAuraClass
local __statesAzeriteArmor = LibStub:GetLibrary("ovale/states/AzeriteArmor")
local OvaleAzeriteArmor = __statesAzeriteArmor.OvaleAzeriteArmor
local __statesAzeriteEssence = LibStub:GetLibrary("ovale/states/AzeriteEssence")
local OvaleAzeriteEssenceClass = __statesAzeriteEssence.OvaleAzeriteEssenceClass
local __BaseState = LibStub:GetLibrary("ovale/BaseState")
local BaseState = __BaseState.BaseState
local __BestAction = LibStub:GetLibrary("ovale/BestAction")
local OvaleBestActionClass = __BestAction.OvaleBestActionClass
local __statesBossMod = LibStub:GetLibrary("ovale/states/BossMod")
local OvaleBossModClass = __statesBossMod.OvaleBossModClass
local __Compile = LibStub:GetLibrary("ovale/Compile")
local OvaleCompileClass = __Compile.OvaleCompileClass
local __Condition = LibStub:GetLibrary("ovale/Condition")
local OvaleConditionClass = __Condition.OvaleConditionClass
local __statesCooldown = LibStub:GetLibrary("ovale/states/Cooldown")
local OvaleCooldownClass = __statesCooldown.OvaleCooldownClass
local __statesDamageTaken = LibStub:GetLibrary("ovale/states/DamageTaken")
local OvaleDamageTakenClass = __statesDamageTaken.OvaleDamageTakenClass
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleDataClass = __Data.OvaleDataClass
local __DataBroker = LibStub:GetLibrary("ovale/DataBroker")
local OvaleDataBrokerClass = __DataBroker.OvaleDataBrokerClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebugClass = __Debug.OvaleDebugClass
local __statesDemonHunterDemonic = LibStub:GetLibrary("ovale/states/DemonHunterDemonic")
local OvaleDemonHunterDemonicClass = __statesDemonHunterDemonic.OvaleDemonHunterDemonicClass
local __statesDemonHunterSoulFragments = LibStub:GetLibrary("ovale/states/DemonHunterSoulFragments")
local OvaleDemonHunterSoulFragmentsClass = __statesDemonHunterSoulFragments.OvaleDemonHunterSoulFragmentsClass
local __statesDemonHunterSigils = LibStub:GetLibrary("ovale/states/DemonHunterSigils")
local OvaleSigilClass = __statesDemonHunterSigils.OvaleSigilClass
local __statesEnemies = LibStub:GetLibrary("ovale/states/Enemies")
local OvaleEnemiesClass = __statesEnemies.OvaleEnemiesClass
local __Equipment = LibStub:GetLibrary("ovale/Equipment")
local OvaleEquipmentClass = __Equipment.OvaleEquipmentClass
local __Frame = LibStub:GetLibrary("ovale/Frame")
local OvaleFrameModuleClass = __Frame.OvaleFrameModuleClass
local __statesFuture = LibStub:GetLibrary("ovale/states/Future")
local OvaleFutureClass = __statesFuture.OvaleFutureClass
local __GUID = LibStub:GetLibrary("ovale/GUID")
local OvaleGUIDClass = __GUID.OvaleGUIDClass
local __statesHealth = LibStub:GetLibrary("ovale/states/Health")
local OvaleHealthClass = __statesHealth.OvaleHealthClass
local __statesLastSpell = LibStub:GetLibrary("ovale/states/LastSpell")
local LastSpell = __statesLastSpell.LastSpell
local __statesLossOfControl = LibStub:GetLibrary("ovale/states/LossOfControl")
local OvaleLossOfControlClass = __statesLossOfControl.OvaleLossOfControlClass
local __statesPower = LibStub:GetLibrary("ovale/states/Power")
local OvalePowerClass = __statesPower.OvalePowerClass
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfilerClass = __Profiler.OvaleProfilerClass
local __Recount = LibStub:GetLibrary("ovale/Recount")
local OvaleRecountClass = __Recount.OvaleRecountClass
local __statesRunes = LibStub:GetLibrary("ovale/states/Runes")
local OvaleRunesClass = __statesRunes.OvaleRunesClass
local __Score = LibStub:GetLibrary("ovale/Score")
local OvaleScoreClass = __Score.OvaleScoreClass
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBookClass = __SpellBook.OvaleSpellBookClass
local __statesSpellDamage = LibStub:GetLibrary("ovale/states/SpellDamage")
local OvaleSpellDamageClass = __statesSpellDamage.OvaleSpellDamageClass
local __SpellFlash = LibStub:GetLibrary("ovale/SpellFlash")
local OvaleSpellFlashClass = __SpellFlash.OvaleSpellFlashClass
local __Spells = LibStub:GetLibrary("ovale/Spells")
local OvaleSpellsClass = __Spells.OvaleSpellsClass
local __statesStagger = LibStub:GetLibrary("ovale/states/Stagger")
local OvaleStaggerClass = __statesStagger.OvaleStaggerClass
local __statesStance = LibStub:GetLibrary("ovale/states/Stance")
local OvaleStanceClass = __statesStance.OvaleStanceClass
local __State = LibStub:GetLibrary("ovale/State")
local OvaleStateClass = __State.OvaleStateClass
local __statesTotem = LibStub:GetLibrary("ovale/states/Totem")
local OvaleTotemClass = __statesTotem.OvaleTotemClass
local __statesVariables = LibStub:GetLibrary("ovale/states/Variables")
local Variables = __statesVariables.Variables
local __Version = LibStub:GetLibrary("ovale/Version")
local OvaleVersionClass = __Version.OvaleVersionClass
local __statesWarlock = LibStub:GetLibrary("ovale/states/Warlock")
local OvaleWarlockClass = __statesWarlock.OvaleWarlockClass
local __conditions = LibStub:GetLibrary("ovale/conditions")
local OvaleConditions = __conditions.OvaleConditions
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
local __Requirement = LibStub:GetLibrary("ovale/Requirement")
local OvaleRequirement = __Requirement.OvaleRequirement
local __statescombat = LibStub:GetLibrary("ovale/states/combat")
local OvaleCombatClass = __statescombat.OvaleCombatClass
local __statescovenant = LibStub:GetLibrary("ovale/states/covenant")
local Covenant = __statescovenant.Covenant
local __statesruneforge = LibStub:GetLibrary("ovale/states/runeforge")
local Runeforge = __statesruneforge.Runeforge
local __statesconduit = LibStub:GetLibrary("ovale/states/conduit")
local Conduit = __statesconduit.Conduit
__exports.IoC = __class(nil, {
    constructor = function(self)
        self.ovale = OvaleClass()
        self.options = OvaleOptionsClass(self.ovale)
        self.debug = OvaleDebugClass(self.ovale, self.options)
        self.profiler = OvaleProfilerClass(self.options, self.ovale)
        self.equipment = OvaleEquipmentClass(self.ovale, self.debug, self.profiler)
        self.lastSpell = LastSpell()
        self.paperDoll = OvalePaperDollClass(self.equipment, self.ovale, self.debug, self.profiler, self.lastSpell)
        self.baseState = BaseState()
        self.condition = OvaleConditionClass()
        self.guid = OvaleGUIDClass(self.ovale, self.debug, self.condition)
        self.requirement = OvaleRequirement(self.baseState, self.guid)
        self.data = OvaleDataClass(self.baseState, self.guid, self.requirement)
        self.spellBook = OvaleSpellBookClass(self.ovale, self.debug, self.data)
        self.cooldown = OvaleCooldownClass(self.paperDoll, self.data, self.lastSpell, self.ovale, self.debug, self.profiler, self.spellBook, self.requirement)
        self.demonHunterSigils = OvaleSigilClass(self.paperDoll, self.ovale, self.spellBook)
        self.state = OvaleStateClass()
        self.aura = OvaleAuraClass(self.state, self.paperDoll, self.baseState, self.data, self.guid, self.lastSpell, self.options, self.debug, self.ovale, self.profiler, self.spellBook, self.requirement)
        self.stance = OvaleStanceClass(self.debug, self.ovale, self.profiler, self.data, self.requirement)
        self.enemies = OvaleEnemiesClass(self.guid, self.ovale, self.profiler, self.debug)
        self.future = OvaleFutureClass(self.data, self.aura, self.paperDoll, self.baseState, self.cooldown, self.state, self.guid, self.lastSpell, self.ovale, self.debug, self.profiler, self.stance, self.requirement, self.spellBook)
        self.health = OvaleHealthClass(self.guid, self.baseState, self.ovale, self.options, self.debug, self.profiler, self.requirement)
        self.lossOfControl = OvaleLossOfControlClass(self.ovale, self.debug, self.requirement)
        self.azeriteEssence = OvaleAzeriteEssenceClass(self.ovale, self.debug)
        self.azeriteArmor = OvaleAzeriteArmor(self.equipment, self.ovale, self.debug)
        local combat = OvaleCombatClass(self.ovale, self.debug, self.spellBook, self.requirement)
        self.scripts = OvaleScriptsClass(self.ovale, self.options, self.paperDoll, self.debug)
        self.ast = OvaleASTClass(self.condition, self.debug, self.profiler, self.scripts, self.spellBook)
        self.score = OvaleScoreClass(self.ovale, self.future, self.debug, self.spellBook, combat)
        self.compile = OvaleCompileClass(self.azeriteArmor, self.equipment, self.ast, self.condition, self.cooldown, self.paperDoll, self.data, self.profiler, self.debug, self.options, self.ovale, self.score, self.spellBook, self.stance)
        self.power = OvalePowerClass(self.debug, self.ovale, self.profiler, self.data, self.future, self.baseState, self.aura, self.paperDoll, self.requirement, self.spellBook, combat)
        self.stagger = OvaleStaggerClass(self.ovale, combat, self.baseState, self.aura, self.health)
        self.spellFlash = OvaleSpellFlashClass(self.options, self.ovale, combat, self.data, self.spellBook, self.stance)
        self.totem = OvaleTotemClass(self.ovale, self.state, self.profiler, self.data, self.future, self.aura, self.spellBook, self.debug)
        self.variables = Variables(combat, self.baseState, self.debug)
        self.warlock = OvaleWarlockClass(self.ovale, self.aura, self.paperDoll, self.spellBook, self.future, self.power)
        self.version = OvaleVersionClass(self.ovale, self.options, self.debug)
        self.damageTaken = OvaleDamageTakenClass(self.ovale, self.profiler, self.debug)
        self.spellDamage = OvaleSpellDamageClass(self.ovale, self.profiler)
        self.demonHunterSoulFragments = OvaleDemonHunterSoulFragmentsClass(self.aura, self.ovale, self.requirement, self.paperDoll)
        self.runes = OvaleRunesClass(self.ovale, self.debug, self.profiler, self.data, self.power, self.paperDoll)
        self.actionBar = OvaleActionBarClass(self.debug, self.ovale, self.profiler, self.spellBook)
        self.spells = OvaleSpellsClass(self.spellBook, self.ovale, self.debug, self.profiler, self.data, self.requirement)
        self.bestAction = OvaleBestActionClass(self.equipment, self.actionBar, self.data, self.cooldown, self.state, self.baseState, self.paperDoll, self.compile, self.condition, self.ovale, self.guid, self.power, self.future, self.spellBook, self.profiler, self.debug, self.variables, self.runes, self.spells)
        self.frame = OvaleFrameModuleClass(self.state, self.compile, self.future, self.baseState, self.enemies, self.ovale, self.options, self.debug, self.guid, self.spellFlash, self.spellBook, self.bestAction, combat)
        self.dataBroker = OvaleDataBrokerClass(self.paperDoll, self.frame, self.options, self.ovale, self.debug, self.scripts, self.version)
        self.unparser = Unparser(self.debug)
        self.emiter = Emiter(self.debug, self.ast, self.data, self.unparser)
        self.parser = Parser(self.debug)
        self.splitter = Splitter(self.ast, self.debug, self.data)
        self.bossMod = OvaleBossModClass(self.ovale, self.debug, self.profiler, combat)
        self.demonHunterDemonic = OvaleDemonHunterDemonicClass(self.aura, self.ovale, self.debug)
        self.generator = Generator(self.ast, self.data)
        self.simulationCraft = OvaleSimulationCraftClass(self.options, self.data, self.emiter, self.ast, self.parser, self.unparser, self.debug, self.compile, self.splitter, self.generator, self.ovale)
        self.recount = OvaleRecountClass(self.ovale, self.score)
        local covenant = Covenant(self.ovale, self.debug)
        local runeforge = Runeforge(self.debug)
        local conduit = Conduit(self.debug)
        self.conditions = OvaleConditions(self.condition, self.data, self.compile, self.paperDoll, self.azeriteArmor, self.azeriteEssence, self.aura, self.baseState, self.cooldown, self.future, self.spellBook, self.frame, self.guid, self.damageTaken, self.power, self.enemies, self.variables, self.lastSpell, self.equipment, self.health, self.options, self.spellDamage, self.totem, self.demonHunterSigils, self.demonHunterSoulFragments, self.bestAction, self.runes, self.stance, self.bossMod, self.spells)
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
        self.stagger:registerConditions(self.condition)
        self.lossOfControl:registerConditions(self.condition)
    end,
})
