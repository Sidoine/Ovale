local __scriptsindex = LibStub:GetLibrary("ovale/scripts/index")
local registerScripts = __scriptsindex.registerScripts
local __CooldownState = LibStub:GetLibrary("ovale/CooldownState")
local CooldownState = __CooldownState.CooldownState
local __Cooldown = LibStub:GetLibrary("ovale/Cooldown")
local OvaleCooldownClass = __Cooldown.OvaleCooldownClass
local __State = LibStub:GetLibrary("ovale/State")
local OvaleStateClass = __State.OvaleStateClass
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDollClass = __PaperDoll.OvalePaperDollClass
local __Equipment = LibStub:GetLibrary("ovale/Equipment")
local OvaleEquipmentClass = __Equipment.OvaleEquipmentClass
local __BaseState = LibStub:GetLibrary("ovale/BaseState")
local BaseState = __BaseState.BaseState
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleDataClass = __Data.OvaleDataClass
local __DemonHunterSigils = LibStub:GetLibrary("ovale/DemonHunterSigils")
local OvaleSigilClass = __DemonHunterSigils.OvaleSigilClass
local __DemonHunterSoulFragments = LibStub:GetLibrary("ovale/DemonHunterSoulFragments")
local DemonHunterSoulFragmentsState = __DemonHunterSoulFragments.DemonHunterSoulFragmentsState
local __Enemies = LibStub:GetLibrary("ovale/Enemies")
local OvaleEnemiesClass = __Enemies.OvaleEnemiesClass
local __Future = LibStub:GetLibrary("ovale/Future")
local OvaleFutureClass = __Future.OvaleFutureClass
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAuraClass = __Aura.OvaleAuraClass
local __GUID = LibStub:GetLibrary("ovale/GUID")
local OvaleGUIDClass = __GUID.OvaleGUIDClass
local __Health = LibStub:GetLibrary("ovale/Health")
local OvaleHealthClass = __Health.OvaleHealthClass
local __LastSpell = LibStub:GetLibrary("ovale/LastSpell")
local LastSpell = __LastSpell.LastSpell
local __LossOfControl = LibStub:GetLibrary("ovale/LossOfControl")
local OvaleLossOfControlClass = __LossOfControl.OvaleLossOfControlClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local OvaleClass = __Ovale.OvaleClass
registerScripts()
local ovale = OvaleClass()
local ovaleEquipement = OvaleEquipmentClass()
local ovalePaperDoll = OvalePaperDollClass(ovaleEquipement)
local baseState = BaseState()
local ovaleGuid = OvaleGUIDClass()
local ovaleData = OvaleDataClass(baseState, ovaleGuid)
local lastSpell = LastSpell()
local cooldown = OvaleCooldownClass(ovalePaperDoll, ovaleData, lastSpell)
local cooldownState = CooldownState(cooldown)
local ovaleSigil = OvaleSigilClass(ovalePaperDoll)
local demonHunterSoulFragmentsState = DemonHunterSoulFragmentsState()
local ovaleEnemies = OvaleEnemiesClass(ovaleGuid)
local state = OvaleStateClass()
local ovaleAura = OvaleAuraClass(state, ovalePaperDoll, baseState, ovaleData, ovaleGuid, lastSpell)
local ovaleCooldown = OvaleCooldownClass(ovalePaperDoll, ovaleData, lastSpell)
local ovaleFuture = OvaleFutureClass(ovaleData, ovaleAura, ovalePaperDoll, baseState, ovaleCooldown, state, ovaleGuid, lastSpell)
local ovaleHealth = OvaleHealthClass(ovaleGuid, baseState)
local ovaleLossOfControl = OvaleLossOfControlClass()
state:RegisterState(cooldownState)
state:RegisterState(ovalePaperDoll)
state:RegisterState(baseState)
state:RegisterState(ovaleSigil)
state:RegisterState(demonHunterSoulFragmentsState)
state:RegisterState(ovaleEnemies)
state:RegisterState(ovaleFuture)
state:RegisterState(ovaleHealth)
state:RegisterState(ovaleLossOfControl)
