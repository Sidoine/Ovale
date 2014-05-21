local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Leafkiller"
	local desc = "[5.4] Leafkiller: Feral, Guardian"
	local code = [[
# Leafkiller's Feral/Guardian druid script, maintained by ShmooDude and aggixx.
# Support/Discussion thread: http://fluiddruid.net/forum/viewtopic.php?f=3&t=857
# 11/03/13 version 5.4.3.1
#   Fixed rake filler comparison
# 10/24/13 version 5.4.3.0
#   Took asValue=1 off {Ability}EnergySafetyMargin functions as they're used in portions of the script that need timestates
#   Fixed TimeTilEnergyForMangle
#   Added upto 0.9 for buff safety margin.
# 10/19/13 version 5.4.3.0
#   Fixed rest of SoO trinket spell IDs
#   Updated damage calculation functions to use asValue=1 so they're treated as constants
#   Switched functions that only contained a number to use Define instead
#   Changed logic of bleed prediction functions to be true when the buff is expiring instead of isn't and removed unnecessary energy check
#   Changed many comparisons to use one node evaluations whenever possible
#   Made cat abilities remove clearcasting buff when used and updated HasEnergyFor functions to check for clearcasting
#   Switched to BuffAmount() function whenever possible to pull trinket proc values directly from buffs.
#   Made AoE rotation use same filler conditions as Main rotation
#   Removed mangle specific filler line
#   Wrapped crit and mastery into their own functions
#   Fixed crit to allow 100% crit vs higher level enemies
# 10/03/13 version 5.4.2.1
#   Fixed rake bug
#   Added check to ensure you'll have energy to use thrash at the end of a rune before suggesting it
#   Reenabled bleed ratio prediction but added a mangle specific filler line that occurs shortly after the traditional filler line so something shows up till Ovale bug is fixed
#   Update FoN logic
#   Fix Haromm's spell ID
# 9/28/13 version 5.4.2.0
#   Temporarily disabled bleed ratio prediction on filler rake until ovale fix can be implemented
#   Removed some unnecessary conditionals from FillerActions
#   Removed Tiger's Fury condition in TimeTilEnergyForAbility functions
#   Reverted to manually calculating the energy cost and TimeTilEnergy for abilities due to weirdness with omen of clarity
# 9/26/13 version 5.4.1.0
#   Only overwrite Rake at the end of a rune if its ratio is >75
#   Changed potion logic to use the new TimeToHealthPercent() function
# 9/25/13 version 5.4.0.4
#   Allowed Ferocious Bite to be used at TimeToDie <=16 without rip present
#   Added crit suppression for damage calculations
#   Added 20% Rip damage buff
# 9/24/13 version 5.4.0.3
#   Changed Rip to use Last functions instead of target.Debuff functions to fix Rip extension bug
#   Added Potion logic
# 9/18/13 version 5.4.0.2
#   Switched to execute range Rip logic if TimeToDie <=16
#   Thrash as filler if the initial hit out damages (per energy) Swipe for AoE rotation
#   Added Energy based considerations for when to suggest applying an end of rune bleed
#   Added Thrash clipping at end of Rune to normal rotation
# 9/13/13 version 5.4.0.1
#   Fixed Incarnation
#   Added Nature's Vigil for CD usage
#   Modified Berserk check box description to "Suggest Long DPS cooldown(s)"
#   Added an AoE rotation for cat
#   Moved Bear AoE to its own box to match cat
#   Modified checkboxes to have spec specific, more detailed descriptions where appropriate and for consistency
#   Changed Big Cat Predictive box to show when on instead of off for consistency
#   Changed Bear Small Rage Usage Boxes to be enabled with the same checkbox as Cat Small Predictive Box
#   Allowed Small Rage Usage Boxes to coexist with left cooldown boxes
#   Cleaned up icon tooltip information
# 9/09/13 version 5.4.0.0
#   Added Feral Rage and Feral Fury buffs and logic
#   Changed Nature's Swiftness to Ysera's Gift
#   Updated FoN logic
# 9/06/13 version 5.4.0.0
#   Added SoO trinkets to buff prediction
#   Removed waiting on TF for Rip
#   Only use fillers during TF for DoC
#   Modified DoC Filler line to be less aggressive at building CPs
#   Added Energy check for fillers
# 9/05/13 version 5.4.0.0
#   Added end of Rune logic for Thrash and Rip
#   Added <12 second SR logic, lowered the priority of FB and increased energy pooling for non-berserk FB
#   Changed fillers to be used at 1.25 seconds from energy cap instead of 1.0.
# 9/02/13 version 5.4.0.0
#   Fixed Savage Roar refresh logic
#   Removed line for HotW+SotF that prevented energy pooling
# 8/29/13 version 5.4.0.0
#   Defined buffs and ItemLists for new SoO trinkets
#   Removed old FoN code, added FoN usage logic to "extraCD" box
#   Changed BAD_JUJU and SOUL_CHARM to 10 second durations
#   Updated DoC damage modifier to 1.30
#   Added DoC as a damage buff to some damage-dealing abilities


############################
## Define Spells, Buffs, Items, Talents ##
############################

# Shared spells
Define(BARKSKIN 22812)
	SpellInfo(BARKSKIN cd=60)
Define(FERAL_SPIRIT 110807)
	SpellInfo(FERAL_SPIRIT cd=120)
Define(HEALING_TOUCH 5185)
Define(MARK_OF_THE_WILD 1126)
	SpellInfo(MARK_OF_THE_WILD duration=3600)
	SpellAddBuff(MARK_OF_THE_WILD MARK_OF_THE_WILD=1)
Define(SYMBIOSIS 110309)
	SpellAddBuff(SYMBIOSIS SYMBIOSIS=1)
Define(WRATH 5176)
Define(HURRICANE 16914)
  SpellInfo(HURRICANE haste=spell channel=9 )

# Shared buffs
Define(DREAM_OF_CENARIUS 145152)
	SpellInfo(DREAM_OF_CENARIUS duration=30 maxstacks=2)
Define(NATURES_VIGIL 124974)
	SpellInfo(NATURES_VIGIL cd=180)
	SpellAddBuff(NATURES_VIGIL NATURES_VIGIL=1)
Define(PREDATORY_SWIFTNESS 69369)
	SpellAddBuff(PREDATORY_SWIFTNESS PREDATORY_SWIFTNESS=1)
Define(PRIMAL_FURY 16961)
Define(TRICKS 57933)
	SpellAddBuff(TRICKS TRICKS=1)
Define(WEAKENED_ARMOR 113746)
	SpellInfo(WEAKENED_ARMOR duration=30 maxstacks=3)
Define(WEAKENED_BLOWS 115798)
	SpellInfo(WEAKENED_BLOWS duration=30)
Define(CLEARCASTING 135700)
Define(FERAL_FURY 144865)
	SpellInfo(FERAL_FURY duration=6)
Define(FERAL_RAGE 146874)
	SpellInfo(FERAL_RAGE duration=12)

# Trinket, Potion and Weapon Enchant buffs
Define(ROR_CRIT 139117)
	SpellInfo(ROR_CRIT duration=10)
Define(ROR_MASTERY 139120)
	SpellInfo(ROR_MASTERY duration=10)
Define(ROR_HASTE 139121)
	SpellInfo(ROR_HASTE duration=10)
	SpellList(ROR ROR_CRIT ROR_MASTERY ROR_HASTE)
Define(DANCING_STEEL 120032)
	SpellInfo(DANCING_STEEL duration=12)
Define(SOUL_CHARM 138756)
	SpellInfo(SOUL_CHARM duration=10)
Define(BLADES 138737)
Define(BAD_JUJU 138939)
	SpellInfo(BAD_JUJU duration=10)
Define(VICIOUS_TALISMAN 138700)
	SpellInfo(VICIOUS_TALISMAN duration=20)
Define(ASSURANCE_OF_CONSEQUENCE 146308)
	SpellInfo(ASSURANCE_OF_CONSEQUENCE duration=20)
Define(HAROMMS_TALISMAN 148903)
	SpellInfo(HAROMMS_TALISMAN duration=10)
Define(SIGIL_OF_RAMPAGE 148896)
	SpellInfo(SIGIL_OF_RAMPAGE duration=15)
Define(TICKING_EBON_DETONATOR 146310)
	SpellInfo(TICKING_EBON_DETONATOR duration=10)
Define(RESTLESS_AGILITY 146310)
Define(VIRMENS_BITE 105697)

# Shared items
ItemList(ROR_ITEM 94532 95802 96174 96546 96918)
ItemList(SOUL_CHARM_ITEM 96741 96369 95997 94512 95625)
ItemList(BAD_JUJU_ITEM 96781 96409 96037 94523 95665)
ItemList(VICIOUS_TALISMAN_ITEM 94511)
ItemList(ASSURANCE_OF_CONSEQUENCE_ITEM 104974 104725 102292 105223 104476 105472)
ItemList(HAROMMS_TALISMAN_ITEM 105029 104780 102301 105278 104531 105527)
ItemList(SIGIL_OF_RAMPAGE_ITEM 105082 104833 102302 105331 104584 105580)
ItemList(TICKING_EBON_DETONATOR_ITEM 105114 104865 102311 105363 104616 105612)
Define(VIRMENS_BITE_ITEM 76089)

# Talents
Define(YSERAS_GIFT_TALENT 4)
Define(RENEWAL_TALENT 5)
Define(CENARION_WARD_TALENT 6)
Define(FAERIE_SWARM_TALENT 7)
Define(TYPHOON_TALENT 9)
Define(SOUL_OF_THE_FOREST 10)
Define(INCARNATION_TALENT 11)
Define(FORCE_OF_NATURE_TALENT 12)
Define(MIGHTY_BASH_TALENT 15)
Define(HEART_OF_THE_WILD_TALENT 16)
Define(DREAM_OF_CENARIUS_TALENT 17)
Define(NATURES_VIGIL_TALENT 18)

# Talent spells
Define(CENARION_WARD 102351)
	SpellInfo(CENARION_WARD cd=30)
Define(FORCE_OF_NATURE 106737)
	SpellInfo(FORCE_OF_NATURE duration=15 cd=60)
Define(HEART_OF_THE_WILD 108292)
	SpellInfo(HEART_OF_THE_WILD cd=360)
	SpellAddBuff(HEART_OF_THE_WILD HEART_OF_THE_WILD=1)
Define(INCARNATION 106731)
	SpellInfo(INCARNATION cd=180)
Define(MIGHTY_BASH 5211)
	SpellInfo(MIGHTY_BASH cd=50)
Define(RENEWAL 108238)
	SpellInfo(RENEWAL cd=120)
Define(TYPHOON 132469)
	SpellInfo(TYPHOON cd=20)
Define(WILD_CHARGE 102401)
	SpellInfo(WILD_CHARGE cd=15)

#Glyphs
Define(GLYPH_OF_SHRED 114234)
Define(GLYPH_OF_SAVAGERY 127540)

# Shared spells
Define(FAERIE_FERAL 770)
	SpellInfo(FAERIE_FERAL duration=300 cd=6)
	SpellAddTargetDebuff(FAERIE_FERAL FAERIE_FERAL=1 WEAKENED_ARMOR=3)
Define(FAERIE_SWARM 102355)
	SpellInfo(FAERIE_SWARM duration=300 cd=6)
	SpellAddTargetDebuff(FAERIE_SWARM FAERIE_SWARM=1 WEAKENED_ARMOR=3)

# Cat spells
Define(BERSERK_CAT 106951) #cat cd buff
	SpellInfo(BERSERK_CAT duration=15 cd=180)
	SpellAddBuff(BERSERK_CAT BERSERK_CAT=1)
Define(CAT_FORM 768)
	SpellAddBuff(CAT_FORM CAT_FORM=1)
Define(FEROCIOUS_BITE 22568) #cat finish 25-50 energy
	SpellInfo(FEROCIOUS_BITE combo=finisher)
	SpellDamageBuff(FEROCIOUS_BITE DREAM_OF_CENARIUS=1.30)
		SpellAddBuff(FEROCIOUS_BITE CLEARCASTING=0)
Define(INCARNATION_CAT 102543)
	SpellInfo(INCARNATION_CAT duration=30 cd=180)
Define(MAIM 22570) #cat interrupt
	SpellInfo(MAIM cd=10 combo=finisher)
	SpellDamageBuff(MAIM DREAM_OF_CENARIUS=1.30)
		SpellAddBuff(MAIM CLEARCASTING=0)
Define(MANGLE_CAT 33876) #cat bleed+debuff
	SpellInfo(MANGLE_CAT inccounter=ripshreds combo=1)
	SpellInfo(MANGLE_CAT critcombo=1 if_spell=PRIMAL_FURY)
	SpellDamageBuff(MANGLE_CAT DREAM_OF_CENARIUS=1.30)
	SpellDamageBuff(MANGLE_CAT FERAL_FURY=1.5)
		SpellAddBuff(MANGLE_CAT CLEARCASTING=0)
Define(RAKE 1822) #cat bleed
	SpellInfo(RAKE combo=1 duration=15 tick=3)
	SpellInfo(RAKE base=99 bonusap=0.3)
	SpellInfo(RAKE critcombo=1 if_spell=PRIMAL_FURY)
	SpellAddTargetDebuff(RAKE RAKE=1)
	SpellDamageBuff(RAKE DREAM_OF_CENARIUS=1.30)
		SpellAddBuff(RAKE CLEARCASTING=0)
Define(RAVAGE 6785)
	SpellInfo(RAVAGE inccounter=ripshreds combo=1)
	SpellInfo(RAVAGE critcombo=1 if_spell=PRIMAL_FURY)
	SpellDamageBuff(RAVAGE DREAM_OF_CENARIUS=1.30)
	SpellDamageBuff(RAVAGE FERAL_FURY=1.5)
		SpellAddBuff(RAVAGE CLEARCASTING=0)
Define(RAVAGE_BANG 102545)
	SpellInfo(RAVAGE_BANG inccounter=ripshreds combo=1)
	SpellInfo(RAVAGE_BANG critcombo=1 if_spell=PRIMAL_FURY)
	SpellDamageBuff(RAVAGE_BANG DREAM_OF_CENARIUS=1.30)
	SpellDamageBuff(RAVAGE_BANG FERAL_FURY=1.5)
		SpellAddBuff(RAVAGE_BANG CLEARCASTING=0)
Define(RIP 1079) #cat bleed
	SpellInfo(RIP resetcounter=ripshreds duration=16 tick=2 combo=finisher)
	SpellAddTargetDebuff(RIP RIP=1)
	SpellDamageBuff(RIP DREAM_OF_CENARIUS=1.30)
	SpellAddBuff(RIP DREAM_OF_CENARIUS=1)
		SpellAddBuff(RIP CLEARCASTING=0)
Define(SAVAGE_ROAR_OLD 52610)
	SpellInfo(SAVAGE_ROAR_OLD duration=18 combo=finisher)
	SpellAddBuff(SAVAGE_ROAR_OLD SAVAGE_ROAR_OLD=1)
Define(SAVAGE_ROAR_GLYPHED 127538)
	SpellInfo(SAVAGE_ROAR_GLYPHED duration=12 combo=finisher min_combo=0)
	SpellAddBuff(SAVAGE_ROAR_GLYPHED SAVAGE_ROAR_GLYPHED=1)
	SpellList(SAVAGE_ROAR 52610 127538)
Define(SHRED 5221) #cat behind
	SpellInfo(SHRED inccounter=ripshreds combo=1)
	SpellInfo(SHRED critcombo=1 if_spell=PRIMAL_FURY)
	SpellDamageBuff(SHRED DREAM_OF_CENARIUS=1.30)
	SpellDamageBuff(SHRED FERAL_FURY=1.5)
		SpellAddBuff(SHRED CLEARCASTING=0)
Define(SHRED_BANG 114236)
	SpellInfo(SHRED_BANG inccounter=ripshreds combo=1)
	SpellInfo(SHRED_BANG critcombo=1 if_spell=PRIMAL_FURY)
	SpellDamageBuff(SHRED_BANG DREAM_OF_CENARIUS=1.30)
	SpellDamageBuff(SHRED_BANG FERAL_FURY=1.5)
		SpellAddBuff(SHRED_BANG CLEARCASTING=0)
Define(STAMPEDE 81022)
	SpellAddBuff(STAMPEDE STAMPEDE=1)
Define(SKULL_BASH_CAT 80965) #cat interrupt
	SpellInfo(SKULL_BASH_CAT cd=15)
Define(THRASH_CAT 106830)
	SpellInfo(THRASH_CAT duration=15 tick=3)
	SpellAddTargetDebuff(THRASH_CAT THRASH_CAT=1 WEAKENED_BLOWS=1)
	SpellDamageBuff(THRASH_CAT DREAM_OF_CENARIUS=1.30)
		SpellAddBuff(THRASH_CAT CLEARCASTING=0)
Define(SWIPE_CAT 62078)
	SpellInfo(SWIPE_CAT combo=1)
	SpellDamageBuff(SWIPE_CAT DREAM_OF_CENARIUS=1.30)
	SpellDamageBuff(SWIPE_CAT FERAL_FURY=1.5)
		SpellAddBuff(SWIPE_CAT CLEARCASTING=0)
Define(TIGERS_FURY 5217) #cat buff
	SpellInfo(TIGERS_FURY duration=6 cd=30)
	SpellAddBuff(TIGERS_FURY TIGERS_FURY=1)

# Bear spells
Define(BEAR_FORM 5487)
	SpellAddBuff(BEAR_FORM BEAR_FORM=1)
Define(BERSERK_BEAR 106952) #cat+bear cd buff
	SpellInfo(BERSERK_BEAR duration=10 cd=180 )
	SpellAddBuff(BERSERK_BEAR BERSERK_BEAR=1)
Define(ENRAGE 5229)
Define(FRENZIED_REGEN 22842)
Define(INCARNATION_BEAR 102558)
	SpellInfo(INCARNATION_BEAR duration=30 cd=180 )
Define(LACERATE 33745)
Define(MANGLE_BEAR 33878)
	SpellInfo(MANGLE_BEAR cd=3 buffnocd=INCARNATION_BEAR buffnocd=BERSERK_BEAR)
Define(MAUL 6807)
Define(MIGHT_OF_URSOC 106922)
Define(SAVAGE_DEFENSE 62606)
Define(SURVIVAL_INSTINCTS 61336)
Define(SWIPE_BEAR 779)
Define(THRASH_BEAR 77758)
Define(TOOTH_AND_CLAW 135286)
	SpellAddBuff(TOOTH_AND_CLAW TOOTH_AND_CLAW=1)
Define(TOOTH_AND_CLAW_DEBUFF 135601)
	SpellAddTargetDebuff(TOOTH_AND_CLAW_DEBUFF TOOTH_AND_CLAW_DEBUFF=1)

###############
## Define Settings ##
###############

AddCheckBox(cooldownsL "Left: DPS CD Boxes" default mastery=2)
AddCheckBox(cooldownsL "Left: Defensive CD Boxes" default mastery=3)
AddCheckBox(cooldownsR "Right: Bleed/SR Remain Boxes" default mastery=2)
AddCheckBox(cooldownsR "Right: Defensive CD Boxes" default mastery=3)
AddCheckBox(altpredictive "Left: Small Predictive Box" mastery=2)
AddCheckBox(altpredictive "Left: Small Rage Usage Boxes" mastery=3)
# AddCheckBox(bearaoe "Bear AoE Rotation") # Removed; AoE rotation is now its own box
AddCheckBox(showaoe "Right: AoE Rotation" default)
AddCheckBox(cooldownsRatio "Left: Rake/Rip Ratio Boxes" mastery=2)
AddCheckBox(cooldownsRatio "Don't change in Guardian" mastery=3)
AddCheckBox(lucioles SpellName(FAERIE_FERAL) default mastery=2)
AddCheckBox(berserk "Suggest Long DPS CD(s)" default mastery=2)
AddCheckBox(infront "Frontal attack" mastery=2)
AddCheckBox(predictive "Right: Big Predictive Box" mastery=2 default)
AddCheckBox(predictive "Right: Big Rage Usage Box" mastery=3 default)
# AddCheckBox(nvbounce "Use healing CDs for damage" mastery=2) # Currently unused
AddCheckBox(potion "Suggest Virmen's Bite Potion" mastery=2)
AddListItem(expbuffsafetymargin point0 "0.0 seconds" mastery=2)
AddListItem(expbuffsafetymargin point1 "0.1 seconds" mastery=2)
AddListItem(expbuffsafetymargin point2 "0.2 seconds" mastery=2)
AddListItem(expbuffsafetymargin point3 "0.3 seconds" mastery=2)
AddListItem(expbuffsafetymargin point4 "0.4 seconds" mastery=2)
AddListItem(expbuffsafetymargin point5 "0.5 seconds" mastery=2 default)
AddListItem(expbuffsafetymargin point6 "0.6 seconds" mastery=2)
AddListItem(expbuffsafetymargin point7 "0.7 seconds" mastery=2)
AddListItem(expbuffsafetymargin point8 "0.8 seconds" mastery=2)
AddListItem(expbuffsafetymargin point9 "0.9 seconds" mastery=2)

################
# Static Variables
################
Define(HeartOfTheWildAgiModifier 1.06)
Define(LeatherSpecAgiModifier 1.05)
Define(StatsBuffBonus 0.05)
Define(RakeBaseDamage 99)
Define(RakeDamagePerAttackPower 0.3)
Define(RipBaseDamage 136)
Define(RipDamagePerComboPoint 384)
Define(RipDamagePerComboPointAttackPower 0.05808)
Define(ThrashHitBaseDamage 1232)
Define(ThrashHitDamagePerAttackPower 0.191)
Define(SwipeCatWeaponDamageMultiplier 4.8)
Define(FerociousBiteBaseDamage 500)
Define(FerociousBiteDamagePerComboPoint 762)
Define(FerociousBiteDamagePerComboPointAttackPower 0.196)
Define(FerociousBiteCritChanceBonus 0.25)
Define(MangleCatBaseDamage 78)
Define(MangleCatWeaponDamageMultiplier 5)
Define(RavageBaseDamage 78)
Define(RavageWeaponDamageMultiplier 9.5)
Define(RavageCritChanceBonus 0.50)
Define(CritPerAttackPower 251904)
AddFunction LevelBasedCritSuppression asValue=1 { if target.RelativeLevel() >0 target.RelativeLevel()/100 0 }
AddFunction ExpiringBuffSafetyMargin asValue=1
{
	if List(expbuffsafetymargin point0) 0.0
	if List(expbuffsafetymargin point1) 0.1
	if List(expbuffsafetymargin point2) 0.2
	if List(expbuffsafetymargin point3) 0.3
	if List(expbuffsafetymargin point4) 0.4
	if List(expbuffsafetymargin point5) 0.5
	if List(expbuffsafetymargin point6) 0.6
	if List(expbuffsafetymargin point7) 0.7
	if List(expbuffsafetymargin point8) 0.8
	if List(expbuffsafetymargin point9) 0.9
	0.5
}

################
# Trinket/Proc values
################
Define(TigersFuryMultiplier 1.15)
Define(RuneMultiplier 2) # Not the actual amount like the rest, but given the power of the rune buff the script should still function properly
Define(DancingSteelAttackPower 3300)
AddFunction SoulCharmAttackPower asValue=1
{
	BuffAmount(BLADES)*2
}
AddFunction BadJujuAttackPower asValue=1
{
	if HasTrinket(96781) 18864 # Heroic TF 2/2 upgrade
	if HasTrinket(96409) 17840 # Heroic 2/2 upgrade
	if HasTrinket(96037) 16712 # Normal TF 2/2 upgrade
	if HasTrinket(94523) 15806 # Normal 2/2 upgrade
	if HasTrinket(95665) 13118 # LFR 2/2 upgrade
}
AddFunction ViciousTalismanAttackPower asValue=1
{
	17600 # 2/2 upgrade
}
AddFunction AssuranceOfConsequenceAttackPower asValue=1
{
	BuffAmount(ASSURANCE_OF_CONSEQUENCE)*2
}
AddFunction HarommsTalismanAttackPower asValue=1
{
	if HasTrinket(105527) 30248 # Heroic WF 2/2 upgrade
	if HasTrinket(104531) 28606 # Heroic 2/2 upgrade
	if HasTrinket(105278) 26798 # Normal WF 2/2 upgrade
	if HasTrinket(102301) 25342 # Normal 2/2 upgrade
	if HasTrinket(104780) 22452 # Flex 2/2 upgrade
	if HasTrinket(105029) 20074 # LFR 2/2 upgrade
}
AddFunction SigilOfRampageAttackPower asValue=1
{
	BuffAmount(SIGIL_OF_RAMPAGE)*2
}
AddFunction TickingEbonDetonatorAttackPower asValue=1
{
	if HasTrinket(105612) 2750 # Heroic WF 2/2 upgrade
	if HasTrinket(104616) 2600 # Heroic 2/2 upgrade
	if HasTrinket(105363) 2436 # Normal WF 2/2 upgrade
	if HasTrinket(102311) 2304 # Normal 2/2 upgrade
	if HasTrinket(104865) 2042 # Flex 2/2 upgrade
	if HasTrinket(105114) 1826 # LFR 2/2 upgrade
}

################
# Energy related functions
################
AddFunction EnergyForThrash asValue=1 { if BuffPresent(BERSERK_CAT) 25 50 }
AddFunction EnergyForRake asValue=1 { if BuffPresent(BERSERK_CAT) 18 35 }
AddFunction EnergyForRip asValue=1 { if BuffPresent(BERSERK_CAT) 15 30 }
AddFunction EnergyForMangle asValue=1 { if BuffPresent(BERSERK_CAT) 18 35 }
AddFunction EnergyForShred asValue=1 { if BuffPresent(BERSERK_CAT) 20 40 }
AddFunction EnergyForRavage asValue=1 { if BuffPresent(BERSERK_CAT) 23 45 }
AddFunction EnergyForFerociousBite asValue=1 { if BuffPresent(BERSERK_CAT) 25 50 }
AddFunction HasEnergyForThrash { Energy() >= EnergyForThrash() or BuffPresent(CLEARCASTING) }
AddFunction HasEnergyForRake { Energy() >= EnergyForRake() or BuffPresent(CLEARCASTING) }
AddFunction HasEnergyForRip { Energy() >= EnergyForRip() or BuffPresent(CLEARCASTING) }
AddFunction HasEnergyForMangle { Energy() >= EnergyForMangle() or BuffPresent(CLEARCASTING) }
AddFunction HasEnergyForShred { Energy() >= EnergyForShred() or BuffPresent(CLEARCASTING) }
AddFunction HasEnergyForFerociousBite { Energy() >= EnergyForFerociousBite() or BuffPresent(CLEARCASTING) }
AddFunction HasEnergyForRavage { Energy() >= EnergyForRavage() or BuffPresent(CLEARCASTING) }

################
# Armor and Mastery Functions
################
AddFunction ArmorReduction asValue=1
{
	if target.DebuffPresent(WEAKENED_ARMOR any=1)
	{
		if target.Level(less 1) 0.679
		0.698
	}
	if target.Level(less 1) 0.651
	0.671
}
AddFunction CurrentMasteryMultiplier asValue=1 { 1+Mastery()/100 }

################
# Crit Chance Functions
################
AddFunction CurrentCritChanceRaw asValue=1 { 1+MeleeCritChance(unlimited=1)/100-LevelBasedCritSuppression() }
AddFunction CurrentCritChanceMultiplier asValue=1
{
	if CurrentCritChanceRaw() > 2
		2
	CurrentCritChanceRaw()
}
AddFunction RakeDebuffCritChanceRaw asValue=1 { 1+target.DebuffMeleeCritChance(RAKE unlimited=1)/100-LevelBasedCritSuppression() }
AddFunction RakeDebuffCritChanceMultiplier asValue=1
{
	if RakeDebuffCritChanceRaw() > 2
		2
	RakeDebuffCritChanceRaw()
}
AddFunction RipDebuffCritChanceRaw asValue=1 { 1+target.DebuffMeleeCritChance(RIP unlimited=1)/100-LevelBasedCritSuppression() }
AddFunction RipDebuffCritChanceMultiplier asValue=1
{
	if RipDebuffCritChanceRaw() > 2
		2
	RipDebuffCritChanceRaw()
}
AddFunction FerociousBiteCritChanceRaw asValue=1 { FerociousBiteCritChanceBonus+CurrentCritChanceMultiplier() }
AddFunction FerociousBiteCritChanceMultiplier asValue=1
{
	if FerociousBiteCritChanceRaw() > 2
		2
	FerociousBiteCritChanceRaw()
}
AddFunction RavageCritChanceRaw asValue=1 { RavageCritChanceBonus+CurrentCritChanceMultiplier() }
AddFunction RavageCritChanceMultiplier asValue=1
{
	if target.HealthPercent(atLeast 80)
	{
		if RavageCritChanceRaw() > 2
			2
		RavageCritChanceRaw()
	}
	CurrentCritChanceMultiplier()
}


################
# Time till energy for abilities functions (must come before Rune functions)
# Moved energy check from functions to main code to fix predictive algorithm bug within ovale
# Always use an energy check when utilizing these functions or you will have a disappearing icon problem
# Example:
# if HasEnergyForRake() and target.DebuffRemains(RAKE less 3)
#     or not HasEnergyForRake() and target.DebuffRemains(RAKE) < 3 + TimeTilEnergyForRake()
################
AddFunction TimeTilEnergyForThrash
{
	if HasEnergyForThrash()
		0
	{ EnergyForThrash() - Energy() } / EnergyRegen()
}
AddFunction TimeTilEnergyForRake
{
	if HasEnergyForRake()
		0
	{ EnergyForRake() - Energy() } / EnergyRegen()
}
AddFunction TimeTilEnergyForRip
{
	if HasEnergyForRip()
		0
	{ EnergyForRip() - Energy() } / EnergyRegen()
}
AddFunction TimeTilEnergyForMangle
{
	if HasEnergyForMangle()
		0
	{ EnergyForMangle() - Energy() } / EnergyRegen()
}
AddFunction ThrashEnergySafetyMargin { TimeTilEnergyForThrash()+ExpiringBuffSafetyMargin() }
AddFunction RakeEnergySafetyMargin { TimeTilEnergyForRake()+ExpiringBuffSafetyMargin() }
AddFunction RipEnergySafetyMargin { TimeTilEnergyForRip()+ExpiringBuffSafetyMargin() }

################
# Cooldown check functions
################
AddFunction RakeCooldownSafetyMargin { SpellCooldown(RAKE)+ExpiringBuffSafetyMargin() }
AddFunction RipCooldownSafetyMargin { SpellCooldown(RIP)+ExpiringBuffSafetyMargin() }

################
# Buff Calculation assistance functions
################
AddFunction AttackPowerToCrit asValue=1 { 1/CritPerAttackPower/{1+0.1*BuffStacks(attack_power_multiplier any=1)} }
AddFunction PrimordiusStats asValue=1 { {1 + 0.05 * DebuffStacks(136184)} * {1 - 0.1 * DebuffStacks(136185)} } # Thick and Fragile bones
AddFunction StatsMultiplier asValue=1 # Leatherwearer, Heart of the Wild, Mark of the Wild/Blessing of Kings, Primordius Buffs
{
	if TalentPoints(HEART_OF_THE_WILD)
		LeatherSpecAgiModifier * HeartOfTheWildAgiModifier * {1 + StatsBuffBonus * BuffStacks(str_agi_int any=1)} * PrimordiusStats()
	LeatherSpecAgiModifier * {1 + StatsBuffBonus * BuffStacks(str_agi_int any=1)} * PrimordiusStats()
}
AddFunction DancingSteelAttackPowerIncrease asValue=1 { DancingSteelAttackPower*StatsMultiplier() }
AddFunction SoulCharmAttackPowerIncrease asValue=1 { SoulCharmAttackPower()*StatsMultiplier() }
AddFunction BadJujuAttackPowerIncrease asValue=1 { BadJujuAttackPower()*StatsMultiplier() }
AddFunction ViciousTalismanAttackPowerIncrease asValue=1 { ViciousTalismanAttackPower()*StatsMultiplier() }
AddFunction AssuranceOfConsequenceAttackPowerIncrease asValue=1 { AssuranceOfConsequenceAttackPower()*StatsMultiplier() }
AddFunction HarommsTalismanAttackPowerIncrease asValue=1 { HarommsTalismanAttackPower()*StatsMultiplier() }
AddFunction SigilOfRampageAttackPowerIncrease asValue=1 { SigilOfRampageAttackPower()*StatsMultiplier() }
AddFunction TickingEbonDetonatorAttackPowerIncrease asValue=1 { TickingEbonDetonatorAttackPower()*BuffStacks(RESTLESS_AGILITY)*StatsMultiplier() }


################
# Rake Buff related functions; Checks to ensure you can use a Rake before a buff expires
################
AddFunction RuneRakeExpiresBeforeUsable asValue=1
{
	BuffRemains(ROR_MASTERY) < RakeCooldownSafetyMargin()
		or BuffRemains(ROR_MASTERY) < RakeEnergySafetyMargin()
}
AddFunction RuneExpiresRakeMultiplier asValue=1
{
	if BuffPresent(ROR_MASTERY) and RuneRakeExpiresBeforeUsable() RuneMultiplier 1
}
AddFunction TigersFuryRakeExpiresBeforeUsable asValue=1
{
	BuffRemains(TIGERS_FURY) < RakeCooldownSafetyMargin()
		or BuffRemains(TIGERS_FURY) < RakeEnergySafetyMargin()
}
AddFunction TigersFuryExpiresRakeMultiplier asValue=1
{
	if BuffPresent(TIGERS_FURY) and TigersFuryRakeExpiresBeforeUsable() TigersFuryMultiplier 1
}
AddFunction DancingSteelRakeExpiresBeforeUsable asValue=1
{
	BuffRemains(DANCING_STEEL any=1) < RakeCooldownSafetyMargin()
		or BuffRemains(DANCING_STEEL any=1) < RakeEnergySafetyMargin()
}
AddFunction DancingSteelExpiresRakeAttackPower asValue=1
{
	if BuffPresent(DANCING_STEEL any=1) and DancingSteelRakeExpiresBeforeUsable() DancingSteelAttackPowerIncrease() 0
}
AddFunction SoulCharmRakeExpiresBeforeUsable asValue=1
{
	BuffRemains(SOUL_CHARM any=1) < RakeCooldownSafetyMargin()
		or BuffRemains(SOUL_CHARM any=1) < RakeEnergySafetyMargin()
}
AddFunction SoulCharmExpiresRakeAttackPower asValue=1
{
	if BuffPresent(SOUL_CHARM any=1) and SoulCharmRakeExpiresBeforeUsable() SoulCharmAttackPowerIncrease() 0
}
AddFunction BadJujuRakeExpiresBeforeUsable asValue=1
{
	BuffRemains(BAD_JUJU any=1) < RakeCooldownSafetyMargin()
		or BuffRemains(BAD_JUJU any=1) < RakeEnergySafetyMargin()
}
AddFunction BadJujuExpiresRakeAttackPower asValue=1
{
	if BuffPresent(BAD_JUJU any=1) and BadJujuRakeExpiresBeforeUsable() BadJujuAttackPowerIncrease() 0
}
AddFunction ViciousTalismanRakeExpiresBeforeUsable asValue=1
{
	BuffRemains(VICIOUS_TALISMAN any=1) < RakeCooldownSafetyMargin()
		or BuffRemains(VICIOUS_TALISMAN any=1) < RakeEnergySafetyMargin()
}
AddFunction ViciousTalismanExpiresRakeAttackPower asValue=1
{
	if BuffPresent(VICIOUS_TALISMAN any=1) and ViciousTalismanRakeExpiresBeforeUsable() ViciousTalismanAttackPowerIncrease() 0
}
AddFunction AssuranceOfConsequenceRakeExpiresBeforeUsable asValue=1
{
	BuffRemains(ASSURANCE_OF_CONSEQUENCE any=1) < RakeCooldownSafetyMargin()
		or BuffRemains(ASSURANCE_OF_CONSEQUENCE any=1) < RakeEnergySafetyMargin()
}
AddFunction AssuranceOfConsequenceExpiresRakeAttackPower asValue=1
{
	if BuffPresent(ASSURANCE_OF_CONSEQUENCE any=1) and AssuranceOfConsequenceRakeExpiresBeforeUsable() AssuranceOfConsequenceAttackPowerIncrease() 0
}
AddFunction HarommsTalismanRakeExpiresBeforeUsable asValue=1
{
	BuffRemains(HAROMMS_TALISMAN any=1) < RakeCooldownSafetyMargin()
		or BuffRemains(HAROMMS_TALISMAN any=1) < RakeEnergySafetyMargin()
}
AddFunction HarommsTalismanExpiresRakeAttackPower asValue=1
{
	if BuffPresent(HAROMMS_TALISMAN any=1) and HarommsTalismanRakeExpiresBeforeUsable() HarommsTalismanAttackPowerIncrease() 0
}
AddFunction SigilOfRampageRakeExpiresBeforeUsable asValue=1
{
	BuffRemains(SIGIL_OF_RAMPAGE any=1) < RakeCooldownSafetyMargin()
		or BuffRemains(SIGIL_OF_RAMPAGE any=1) < RakeEnergySafetyMargin()
}
AddFunction SigilOfRampageExpiresRakeAttackPower asValue=1
{
	if BuffPresent(SIGIL_OF_RAMPAGE any=1) and SigilOfRampageRakeExpiresBeforeUsable() SigilOfRampageAttackPowerIncrease() 0
}
AddFunction TickingEbonDetonatorRakeExpiresBeforeUsable asValue=1
{
	BuffRemains(SIGIL_OF_RAMPAGE any=1) < RakeCooldownSafetyMargin()
		or BuffRemains(SIGIL_OF_RAMPAGE any=1) < RakeEnergySafetyMargin()
}
AddFunction TickingEbonDetonatorExpiresRakeAttackPower asValue=1
{
	if BuffPresent(TICKING_EBON_DETONATOR any=1)
	{
		if TickingEbonDetonatorRakeExpiresBeforeUsable() TickingEbonDetonatorAttackPowerIncrease()
		TickingEbonDetonatorAttackPower()
	}
		0
}

################
# Rip Buff related functions; Checks to ensure you can use a Rip before a buff expires
################
AddFunction RuneRipExpiresBeforeUsable asValue=1
{
	BuffRemains(ROR_MASTERY) < RipCooldownSafetyMargin()
		or BuffRemains(ROR_MASTERY) < RipEnergySafetyMargin()
}
AddFunction RuneExpiresRipMultiplier asValue=1
{
	if BuffPresent(ROR_MASTERY) and RuneRipExpiresBeforeUsable() RuneMultiplier 1
}
AddFunction TigersFuryRipExpiresBeforeUsable asValue=1
{
	BuffRemains(TIGERS_FURY) < RipCooldownSafetyMargin()
		or BuffRemains(TIGERS_FURY) < RipEnergySafetyMargin()
}
AddFunction TigersFuryExpiresRipMultiplier asValue=1
{
	if BuffPresent(TIGERS_FURY) and TigersFuryRipExpiresBeforeUsable() TigersFuryMultiplier 1
}
AddFunction DancingSteelRipExpiresBeforeUsable asValue=1
{
	BuffRemains(DANCING_STEEL any=1) < RipCooldownSafetyMargin()
		or BuffRemains(DANCING_STEEL any=1) < RipEnergySafetyMargin()
}
AddFunction DancingSteelExpiresRipAttackPower asValue=1
{
	if BuffPresent(DANCING_STEEL any=1) and DancingSteelRipExpiresBeforeUsable() DancingSteelAttackPowerIncrease() 0
}
AddFunction SoulCharmRipExpiresBeforeUsable asValue=1
{
	BuffRemains(SOUL_CHARM any=1) < RipCooldownSafetyMargin()
		or BuffRemains(SOUL_CHARM any=1) < RipEnergySafetyMargin()
}
AddFunction SoulCharmExpiresRipAttackPower asValue=1
{
	if BuffPresent(SOUL_CHARM any=1) and SoulCharmRipExpiresBeforeUsable() SoulCharmAttackPowerIncrease() 0
}
AddFunction BadJujuRipExpiresBeforeUsable asValue=1
{
	BuffRemains(BAD_JUJU any=1) < RipCooldownSafetyMargin()
		or BuffRemains(BAD_JUJU any=1) < RipEnergySafetyMargin()
}
AddFunction BadJujuExpiresRipAttackPower asValue=1
{
	if BuffPresent(BAD_JUJU any=1) and BadJujuRipExpiresBeforeUsable() BadJujuAttackPowerIncrease() 0
}
AddFunction ViciousTalismanRipExpiresBeforeUsable asValue=1
{
	BuffRemains(VICIOUS_TALISMAN any=1) < RipCooldownSafetyMargin()
		or BuffRemains(VICIOUS_TALISMAN any=1) < RipEnergySafetyMargin()
}
AddFunction ViciousTalismanExpiresRipAttackPower asValue=1
{
	if BuffPresent(VICIOUS_TALISMAN any=1) and ViciousTalismanRipExpiresBeforeUsable() ViciousTalismanAttackPowerIncrease() 0
}
AddFunction AssuranceOfConsequenceRipExpiresBeforeUsable asValue=1
{
	BuffRemains(ASSURANCE_OF_CONSEQUENCE any=1) < RipCooldownSafetyMargin()
		or BuffRemains(ASSURANCE_OF_CONSEQUENCE any=1) < RipEnergySafetyMargin()
}
AddFunction AssuranceOfConsequenceExpiresRipAttackPower asValue=1
{
	if BuffPresent(ASSURANCE_OF_CONSEQUENCE any=1) and AssuranceOfConsequenceRipExpiresBeforeUsable() AssuranceOfConsequenceAttackPowerIncrease() 0
}
AddFunction HarommsTalismanRipExpiresBeforeUsable asValue=1
{
	BuffRemains(HAROMMS_TALISMAN any=1) < RipCooldownSafetyMargin()
		or BuffRemains(HAROMMS_TALISMAN any=1) < RipEnergySafetyMargin()
}
AddFunction HarommsTalismanExpiresRipAttackPower asValue=1
{
	if BuffPresent(HAROMMS_TALISMAN any=1) and HarommsTalismanRipExpiresBeforeUsable() HarommsTalismanAttackPowerIncrease() 0
}
AddFunction SigilOfRampageRipExpiresBeforeUsable asValue=1
{
	BuffRemains(SIGIL_OF_RAMPAGE any=1) < RipCooldownSafetyMargin()
		or BuffRemains(SIGIL_OF_RAMPAGE any=1) < RipEnergySafetyMargin()
}
AddFunction SigilOfRampageExpiresRipAttackPower asValue=1
{
	if BuffPresent(SIGIL_OF_RAMPAGE any=1) and SigilOfRampageRipExpiresBeforeUsable() SigilOfRampageAttackPowerIncrease() 0
}
AddFunction TickingEbonDetonatorRipExpiresBeforeUsable asValue=1
{
	BuffRemains(SIGIL_OF_RAMPAGE any=1) < RipCooldownSafetyMargin()
		or BuffRemains(SIGIL_OF_RAMPAGE any=1) < RipEnergySafetyMargin()
}
AddFunction TickingEbonDetonatorExpiresRipAttackPower asValue=1
{
	if BuffPresent(TICKING_EBON_DETONATOR any=1)
	{
		if TickingEbonDetonatorRipExpiresBeforeUsable() TickingEbonDetonatorAttackPowerIncrease()
		TickingEbonDetonatorAttackPower()
	}
	0
}

################
# Rake Damage functions
################
AddFunction RakeTickDamage asValue=1 # Switched to raw numbers in place of Damage(RAKE) for 5.3.4+ compatibility
{
	{RakeBaseDamage + AttackPower()*RakeDamagePerAttackPower} * DamageMultiplier(RAKE) * CurrentCritChanceMultiplier() * CurrentMasteryMultiplier()
}
AddFunction LastRakeTickDamage asValue=1
{
	{RakeBaseDamage + target.DebuffAttackPower(RAKE)*RakeDamagePerAttackPower} * target.DebuffDamageMultiplier(RAKE) * RakeDebuffCritChanceMultiplier() * {1+target.DebuffMastery(RAKE)/100}
}
AddFunction TotalRakeMultiplier asValue=1
{
	RuneExpiresRakeMultiplier()*TigersFuryExpiresRakeMultiplier()
}
AddFunction TotalRakeAttackPower asValue=1
{
	DancingSteelExpiresRakeAttackPower() +
	SoulCharmExpiresRakeAttackPower() +
	BadJujuExpiresRakeAttackPower() +
	ViciousTalismanExpiresRakeAttackPower() +
	AssuranceOfConsequenceExpiresRakeAttackPower() +
	HarommsTalismanExpiresRakeAttackPower() +
	SigilOfRampageExpiresRakeAttackPower() +
	TickingEbonDetonatorExpiresRakeAttackPower()
}
AddFunction FutureRakeTickDamage asValue=1
{
	{RakeBaseDamage + {AttackPower() - TotalRakeAttackPower()} * RakeDamagePerAttackPower}
	* DamageMultiplier(RAKE) / TotalRakeMultiplier()
	* {CurrentCritChanceMultiplier() - TotalRakeAttackPower()*AttackPowerToCrit()}
	* CurrentMasteryMultiplier()
}
AddFunction RakeRatio asValue=1
{
	if TargetDebuffPresent(RAKE) 100 * FutureRakeTickDamage()/LastRakeTickDamage()
	100.0
}

################
# Rip Damage functions
################
AddFunction RipTickDamage asValue=1
{
	{RipBaseDamage + {{RipDamagePerComboPoint + {RipDamagePerComboPointAttackPower * AttackPower()}} * ComboPoints()}} * DamageMultiplier(RIP) * CurrentCritChanceMultiplier() * CurrentMasteryMultiplier()
}
AddFunction LastRipTickDamage asValue=1
{
	{RipBaseDamage + {{RipDamagePerComboPoint + {RipDamagePerComboPointAttackPower * target.DebuffAttackPower(RIP)}} * target.DebuffComboPoints(RIP)}} * target.DebuffDamageMultiplier(RIP) * RipDebuffCritChanceMultiplier() * {1 + target.DebuffMastery(RIP)/100}
}
AddFunction TotalRipMultiplier asValue=1
{
	RuneExpiresRipMultiplier()*TigersFuryExpiresRipMultiplier()
}
AddFunction TotalRipAttackPower asValue=1
{
	DancingSteelExpiresRipAttackPower() +
	SoulCharmExpiresRipAttackPower() +
	BadJujuExpiresRipAttackPower() +
	ViciousTalismanExpiresRipAttackPower() +
	AssuranceOfConsequenceExpiresRipAttackPower() +
	HarommsTalismanExpiresRipAttackPower() +
	SigilOfRampageExpiresRipAttackPower() +
	TickingEbonDetonatorExpiresRipAttackPower()
}
AddFunction FutureRipTickDamage asValue=1
{
	{RipBaseDamage + {{RipDamagePerComboPoint + {RipDamagePerComboPointAttackPower * {AttackPower() - TotalRipAttackPower()}}} * ComboPoints()}}
	* DamageMultiplier(RIP) / TotalRipMultiplier()
	* {CurrentCritChanceMultiplier() - TotalRipAttackPower()*AttackPowerToCrit()}
	* CurrentMasteryMultiplier()
}
AddFunction RipDamageTillDead asValue=1
{
	# The damage from Rip that is cast under the current conditions and lasting till target is dead.
	# Multiply the damage per tick with the number of ticks that can fit into the time to die.
	FutureRipTickDamage() * {target.TimeToDie() / 2}
}
AddFunction ExistingRipDamageTillDead asValue=1
{
	# The damage from Rip that is already on the target and lasting till target is dead.
	if target.DebuffPresent(RIP)
	{
		# Multiply the damage per tick with the number of ticks that can fit into the time to die.
		LastRipTickDamage() * {target.TimeToDie() / 2}
	}
	0
}
AddFunction RipRatio asValue=1
{
	if TargetDebuffPresent(RIP) 100 * FutureRipTickDamage()/LastRipTickDamage()
	100.0
}

################
# Ability damage functions
################
AddFunction FerociousBiteDamage asValue=1 # Switched to raw numbers in place of Damage(FEROCIOUS_BITE) for 5.3.4+ compatibility
{
	{FerociousBiteBaseDamage + {FerociousBiteDamagePerComboPoint + FerociousBiteDamagePerComboPointAttackPower * AttackPower()} * ComboPoints()} * DamageMultiplier(FEROCIOUS_BITE) * FerociousBiteCritChanceMultiplier() * 2 * ArmorReduction()
}
AddFunction MangleCatDamage asValue=1
{
	{MangleCatBaseDamage + WeaponDamage()} * MangleCatWeaponDamageMultiplier * DamageMultiplier(MANGLE_CAT) * CurrentCritChanceMultiplier() * ArmorReduction()
}
AddFunction ShredDamage asValue=1
{
	MangleCatDamage()*1.2
}
AddFunction ThrashCatHitDamage asValue=1
{
	{ThrashHitBaseDamage + AttackPower()} * ThrashHitDamagePerAttackPower * DamageMultiplier(THRASH_CAT) * CurrentCritChanceMultiplier() * CurrentMasteryMultiplier()
}
AddFunction SwipeCatDamage asValue=1
{
	WeaponDamage() * MangleCatWeaponDamageMultiplier * DamageMultiplier(MANGLE_CAT) * CurrentCritChanceMultiplier() * ArmorReduction()
}
AddFunction RavageDamage asValue=1
{
	{RavageBaseDamage + WeaponDamage()} * RavageWeaponDamageMultiplier * DamageMultiplier(RAVAGE) * RavageCritChanceMultiplier() * ArmorReduction()
}

################
# Misc functions
################
AddFunction FaerieFire
{
	if TalentPoints(FAERIE_SWARM_TALENT) Spell(FAERIE_SWARM)
	unless TalentPoints(FAERIE_SWARM_TALENT) Spell(FAERIE_FERAL)
}
AddFunction SavageRoar
{
	if Glyph(GLYPH_OF_SAVAGERY) Spell(SAVAGE_ROAR_GLYPHED)
	if Glyph(GLYPH_OF_SAVAGERY no) and ComboPoints(more 0) Spell(SAVAGE_ROAR_OLD)
}
AddFunction UsePotion
{
	#virmens_bite_potion
	Item(virmens_bite_potion)
}
AddFunction TreantTimeThreshold
{
	1+{Charges(FORCE_OF_NATURE)-1}*0.33
}

#############################
## Feral rotation functions (Mastery=2) ##
#############################

AddFunction NotInCombat
{
	unless InCombat() {
		if BuffExpires(str_agi_int 400 any=1) Spell(MARK_OF_THE_WILD)
		if BuffExpires(DREAM_OF_CENARIUS) and TalentPoints(DREAM_OF_CENARIUS_TALENT) Spell(HEALING_TOUCH)
		unless Stance(3) Spell(CAT_FORM)
		if Glyph(GLYPH_OF_SAVAGERY) and ComboPoints(atMost 0) {
			if BuffRemains(SAVAGE_ROAR_GLYPHED less 12) and TimeToMaxEnergy() < BuffRemains(SAVAGE_ROAR_GLYPHED)-11.5
			or BuffRemains(SAVAGE_ROAR_GLYPHED less 9) and TimeToMaxEnergy() < BuffRemains(SAVAGE_ROAR_GLYPHED)-8.5
			or BuffRemains(SAVAGE_ROAR_GLYPHED less 6) and TimeToMaxEnergy() < BuffRemains(SAVAGE_ROAR_GLYPHED)-5.5
			or BuffRemains(SAVAGE_ROAR_GLYPHED less 3) and TimeToMaxEnergy() < BuffRemains(SAVAGE_ROAR_GLYPHED)-2.5
			or BuffExpires(SAVAGE_ROAR_GLYPHED)
			{
				SavageRoar()
			}
		}
		if TalentPoints(FORCE_OF_NATURE_TALENT) Spell(FORCE_OF_NATURE)
	}
}

AddFunction SpareGcdCooldowns {
	# Spirit Wolves goes here when symbiosis is supported appropriately.
}

AddFunction HealingTouch
{
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if TalentPoints(DREAM_OF_CENARIUS_TALENT) and BuffPresent(PREDATORY_SWIFTNESS) and BuffExpires(DREAM_OF_CENARIUS_DAMAGE) and
		{BuffRemains(PREDATORY_SWIFTNESS atMost 1.5) or ComboPoints(atLeast 4)}
	{
		Spell(HEALING_TOUCH)
	}
}

AddFunction SavageRoarOrWeakenedArmorMissing
{
	#savage_roar,if=buff.savage_roar.down
	if BuffExpires(SAVAGE_ROAR) SavageRoar()

	#faerie_fire,if=debuff.weakened_armor.stack<3
	if target.DebuffStacks(WEAKENED_ARMOR any=1 less 3) and CheckBoxOn(lucioles) FaerieFire()
}

AddFunction RangeCheck
{
	#range check
	unless target.InRange(MANGLE_CAT) Texture(ability_druid_catformattack)
}

AddFunction DpsCooldownLogic
{
	#incarnation,if=energy<=35&!buff.omen_of_clarity.react&cooldown.tigers_fury.remains=0&cooldown.berserk.remains=0
	#use_item,slot=hands,if=buff.tigers_fury.up
	#tigers_fury,if=(energy<=35&!buff.omen_of_clarity.react)|buff.king_of_the_jungle.up
	#berserk,if=buff.tigers_fury.up|(target.time_to_die<15&cooldown.tigers_fury.remains>6)
	if {{Energy(atMost 35) and BuffExpires(CLEARCASTING)} or BuffPresent(INCARNATION_CAT)} and Spell(TIGERS_FURY)
	{
		if CheckBoxOn(berserk) and Spell(BERSERK_CAT)
		{
			if not TalentPoints(INCARNATION_TALENT) or BuffPresent(INCARNATION_CAT) Spell(BERSERK_CAT)
			if TalentPoints(INCARNATION_TALENT) wait Spell(INCARNATION) #wait is necessary otherwise it suggests TF for about a half second before suggesting Incarnation
		}
		unless BuffPresent(BERSERK_CAT) Spell(TIGERS_FURY)
	}
	if CheckBoxOn(berserk)
	{
		if TalentPoints(INCARNATION_TALENT) and BuffPresent(BERSERK_CAT) Spell(INCARNATION_CAT)
		if TalentPoints(NATURES_VIGIL_TALENT) and {BuffPresent(BERSERK_CAT) or SpellCooldown(BERSERK_CAT more 88)} Spell(NATURES_VIGIL)
	}

}

AddFunction ExecuteRangeRipFerociousBiteLogic
{
	#ferocious_bite,if=combo_points>=1&dot.rip.ticking&dot.rip.remains<=3&target.health.pct<=25
	if target.HealthPercent(atMost 25) and ComboPoints(more 0)
		and target.DebuffPresent(RIP) and target.DebuffRemains(RIP less 4) # is 4 instead of 3 because the remaining time on rip can be inaccurate upto 2 seconds
	{
		Spell(FEROCIOUS_BITE)
	}

	#thrash_cat,if=target.time_to_die>=6&buff.omen_of_clarity.react&dot.thrash_cat.remains<3
	if target.TimeToDie(atLeast 9) and BuffPresent(CLEARCASTING)
		and target.DebuffRemains(THRASH_CAT less 3)
		{
		Spell(THRASH_CAT)
	}

	#ferocious_bite,if=target.time_to_die<=1&combo_points>=3
	if target.TimeToDie(atMost 1) and ComboPoints(atLeast 3) Spell(FEROCIOUS_BITE)

	#savage_roar,if=buff.savage_roar.remains<=3&combo_points>0&target.health.pct<25
	if BuffRemains(SAVAGE_ROAR less 3) and ComboPoints(more 0) and target.HealthPercent(atMost 25)
	{
		SavageRoar()
	}

	if ComboPoints(atLeast 5)
	{
		if CheckBoxOn(potions) and target.Classification(worldboss) and ItemCount(VIRMENS_BITE_ITEM more 0)
		{
			if TimeToHealthPercent(25 atMost 15)
			{
				#virmens_bite_potion,if=combo_points>=5&$(time_til_bitw)<15&$(rip_ratio)>=1.15&buff.dream_of_cenarius_damage.up
				if not HasTrinket(ROR_ITEM) and ComboPoints(atLeast 5) and {BuffPresent(DREAM_OF_CENARIUS) or not TalentPoints(DREAM_OF_CENARIUS_TALENT)} and RipRatio() >=115 Item(VIRMENS_BITE_ITEM)

				#virmens_bite_potion,if=combo_points>=5&$(time_til_bitw)<15&buff.rune_of_reorigination.up&buff.dream_of_cenarius_damage.up
				if HasTrinket(ROR_ITEM) and ComboPoints(atLeast 5) and {BuffPresent(DREAM_OF_CENARIUS) or not TalentPoints(DREAM_OF_CENARIUS_TALENT)} and BuffPresent(ROR_MASTERY) Item(VIRMENS_BITE_ITEM)
			}
			#virmens_bite_potion,if=target.time_to_die<=40
			if target.TimeToDie(atMost 40) Item(VIRMENS_BITE_ITEM)
		}

		#rip,if=combo_points>=5&(tick_damage*(1+crit_pct_current)-tick_dmg*(1+crit_pct))*target.time_to_die%2>=action.ferocious_bite.hit_damage*(1+action.ferocious_bite.crit_pct_current)*2&target.health.pct<=25
		if RipDamageTillDead() > ExistingRipDamageTillDead() + FerociousBiteDamage() and {target.HealthPercent(atMost 25) or target.TimeToDie(atMost 16)}
		{
			Spell(RIP)
		}

		#pool_resource,wait=0.25,if=combo_points>=5&dot.rip.ticking&target.health.pct<=25&((energy<50&buff.berserk.down)|(energy<25&buff.berserk.remains>1))
		#ferocious_bite,if=combo_points>=5&dot.rip.ticking&target.health.pct<=25
		if target.DebuffPresent(RIP) and target.HealthPercent(atMost 25)
		{
			if not HasEnergyForFerociousBite() SpareGcdCooldowns()
			wait if HasEnergyForFerociousBite() Spell(FEROCIOUS_BITE)
		}
	}
}

AddFunction RipLogic
{
	if target.HealthPercent(more 25) and target.TimeToDie(more 16)
	{
		#rip,if=combo_points>=5&$(rip_ratio)>=1.15
		if ComboPoints(atLeast 5) and RipRatio() >= 115
		{
			Spell(RIP)
		}

		#rip,if=combo_points>=5&target.time_to_die>=6&dot.rip.remains<2
		if ComboPoints(atLeast 5)
						and     {{HasEnergyForRip() and target.DebuffRemains(RIP less 2)}
			or {not HasEnergyForRip() and target.DebuffRemains(RIP) <2+TimeTilEnergyForRip()}}
		{
			Spell(RIP)
		}

		#rip,if=combo_points>=5&action.rip.tick_damage%dot.rip.tick_dmg>=1.15
		if BuffPresent(ROR_MASTERY) and RipRatio() >= 95 and ComboPoints(atLeast 4)
			and {{HasEnergyForRip() and BuffRemains(ROR_MASTERY atMost 1.5) and BuffRemains(ROR_MASTERY) > ExpiringBuffSafetyMargin()}
			or {not HasEnergyForRip() and BuffRemains(ROR_MASTERY) <=1.5 + TimeTilEnergyForRip() and BuffRemains(ROR_MASTERY) > RipEnergySafetyMargin() and TimeTilEnergyForRip() < BuffRemains(ROR_MASTERY) - ExpiringBuffSafetyMargin()}}
		{
			Spell(RIP)
		}
   }
}

AddFunction SavageRoarRefreshLogic
{
	#savage_roar,if=buff.savage_roar.remains<3&combo_points>0&buff.savage_roar.remains+2>dot.rip.remains
	if BuffRemains(SAVAGE_ROAR less 3) and ComboPoints(more 0) and BuffRemains(SAVAGE_ROAR) +2 > target.DebuffRemains(RIP)
	{
		SavageRoar()
	}

	#savage_roar,if=buff.savage_roar.remains<6&combo_points>=5&buff.savage_roar.remains+2<=dot.rip.remains&dot.rip.ticking
	if BuffRemains(SAVAGE_ROAR less 6) and ComboPoints(atLeast 5) and BuffRemains(SAVAGE_ROAR) +2 <= target.DebuffRemains(RIP) and target.DebuffPresent(RIP)
	{
		SavageRoar()
	}

	#savage_roar,if=buff.savage_roar.remains<12&combo_points>=5&energy.time_to_max<=1.25&buff.savage_roar.remains<=dot.rip.remains+6&dot.rip.ticking
	if BuffRemains(SAVAGE_ROAR less 12) and ComboPoints(atLeast 5) and TimeToMaxEnergy(atMost 1.25) and BuffRemains(SAVAGE_ROAR) <= target.DebuffRemains(RIP) +6
	{
		SavageRoar()
	}
}

AddFunction RakeLogic
{
	if target.TimeToDie() - target.DebuffRemains(RAKE) >3
	{
		#rake,if=target.time_to_die-dot.rake.remains>3&buff.rune_of_reorigination.up&dot.rake.remains<9&(buff.rune_of_reorigination.remains<=1.5)
		if BuffPresent(ROR_MASTERY) and RakeRatio() > 75
			and {{HasEnergyForRake() and target.DebuffRemains(RAKE less 9) and BuffRemains(ROR_MASTERY atMost 1.5)
								and ExpiringBuffSafetyMargin() < BuffRemains(ROR_MASTERY)}
			or {not HasEnergyForRake() and target.DebuffRemains(RAKE) <9 + TimeTilEnergyForRake() and BuffRemains(ROR_MASTERY) <=1.5 + TimeTilEnergyForRake()
								and RakeEnergySafetyMargin() < BuffRemains(ROR_MASTERY) and TimeTilEnergyForRake() < BuffRemains(ROR_MASTERY) - ExpiringBuffSafetyMargin()}}
		{
			Spell(RAKE)
		}

		#rake,if=target.time_to_die-dot.rake.remains>3&(action.rake.tick_damage>dot.rake.tick_dmg*1.12|(dot.rake.remains<3&action.rake.tick_damage%dot.rake.tick_dmg>=0.75))
		if RakeRatio() > 75
						and {{HasEnergyForRake() and target.DebuffRemains(RAKE less 3)}
			or {not HasEnergyForRake() and target.DebuffRemains(RAKE) < 3 + TimeTilEnergyForRake()}}
				{
			Spell(RAKE)
		}
		if RakeRatio() > 112
		{
			Spell(RAKE)
		}

		#rake if its about to fall off.  Simcraft doesn't require this line but ovale does for the prediction box.
		if {HasEnergyForRake() and target.DebuffRemains(RAKE) < 0.001}
			or {not HasEnergyForRake() and target.DebuffRemains(RAKE) < 0.001 + TimeTilEnergyForRake()}
		{
			Spell(RAKE)
		}
	}
}

AddFunction ThrashLogic
{
	#pool_resource,wait=0.25,for_next=1
	#thrash_cat,if=target.time_to_die>=6&dot.thrash_cat.remains<3&(dot.rip.remains>=8&buff.savage_roar.remains>=12|buff.berserk.up|combo_points>=5)&dot.rip.ticking
	if {HasEnergyForThrash()
		and target.DebuffRemains(THRASH_CAT less 3)
		and target.TimeToDie(atLeast 9)
		and {{target.DebuffRemains(RIP atLeast 8) and BuffRemains(SAVAGE_ROAR atLeast 12)}
			or BuffPresent(BERSERK_CAT) or ComboPoints(atLeast 5)}}
	or {not HasEnergyForThrash()
		and target.DebuffRemains(THRASH_CAT) < 3 + TimeTilEnergyForThrash()
		and target.TimeToDie() >=9 + TimeTilEnergyForThrash()
		and {{target.DebuffRemains(RIP) >=8 + TimeTilEnergyForThrash() and BuffRemains(SAVAGE_ROAR) >=12 + TimeTilEnergyForThrash()}
			or BuffPresent(BERSERK_CAT) or ComboPoints(atLeast 5)}}
	{
		if TimeTilEnergyForThrash() >=1.5 SpareGcdCooldowns()
		Spell(THRASH_CAT)
	}

	#pool_resource,for_next=1
	#thrash_cat,if=target.time_to_die>=6&dot.thrash_cat.remains<9&buff.rune_of_reorigination.up&buff.rune_of_reorigination.remains<=1.5&dot.rip.ticking
	if BuffPresent(ROR_MASTERY) and target.DebuffPresent(RIP)
		and {{HasEnergyForThrash()
						and ExpiringBuffSafetyMargin() < BuffRemains(ROR_MASTERY)
			and target.DebuffRemains(THRASH_CAT less 9) and BuffRemains(ROR_MASTERY atMost 1.5)
			and target.TimeToDie(atLeast 9)}
		or {not HasEnergyForThrash()
						and ThrashEnergySafetyMargin() < BuffRemains(ROR_MASTERY)
			and target.DebuffRemains(THRASH_CAT) < 9 + TimeTilEnergyForThrash()
						and BuffRemains(ROR_MASTERY) <=1.5 + TimeTilEnergyForThrash()
						and TimeTilEnergyForThrash() <= BuffRemains(ROR_MASTERY) + ExpiringBuffSafetyMargin()
			and target.TimeToDie() >=9 + TimeTilEnergyForThrash()}}
	{
		if TimeTilEnergyForThrash() >=1.5 SpareGcdCooldowns()
		Spell(THRASH_CAT)
	}
}

AddFunction FerociousBiteWaitConditions { TimeToMaxEnergy(atMost 1.25) or {{target.DebuffExpires(RIP) or BuffPresent(BERSERK_CAT) or SpellCooldown(TIGERS_FURY atMost 1.5)} and HasEnergyForFerociousBite()} or {BuffPresent(FERAL_RAGE) and BuffRemains(FERAL_RAGE atMost 1.25)} }
AddFunction NonExcuteRangeFerociousBiteLogic
{
	#pool_resource,if=combo_points>=5&!(energy.time_to_max<=1.25|(buff.feral_rage.up&buff.feral_rage.remains<1)|(energy>=50&cooldown.tigers_fury.remains<=1.5)|(buff.berserk.up&energy>=25))&dot.rip.ticking
	#ferocious_bite,if=combo_points>=5&dot.rip.ticking
	if ComboPoints(atLeast 5) and {target.DebuffPresent(RIP) or target.TimeToDie(atMost 16)} and BuffPresent(SAVAGE_ROAR)
	{
		if not FerociousBiteWaitConditions() SpareGcdCooldowns()
		wait if FerociousBiteWaitConditions() Spell(FEROCIOUS_BITE)
	}
}
AddFunction RakeTargetNotDieing asValue=1 { FutureRakeTickDamage() * {target.TicksRemain(RAKE)+1} - LastRakeTickDamage() * target.TicksRemain(RAKE) }
AddFunction RakeTargetIsDieing asValue=1 { FutureRakeTickDamage() * {target.TimeToDie()/3+1} - LastRakeTickDamage() * target.TimeToDie()/3 }
AddFunction FillerActions
{
	#rake,if=target.time_to_die-dot.rake.remains>3&action.rake.tick_damage*(dot.rake.ticks_remain+1)-dot.rake.tick_dmg*dot.rake.ticks_remain>action.mangle_cat.hit_damage
	if target.TimeToDie() - target.DebuffRemains(RAKE) >=3 and RakeTargetNotDieing() >= MangleCatDamage()
	{
		Spell(RAKE)
	}
	#rake,if=target.time_to_die-dot.rake.remains<=3&action.rake.tick_damage*(target.time_to_die%3+1)-dot.rake.tick_dmg*target.time_to_die%3>action.mangle_cat.hit_damage
	if target.TimeToDie() - target.DebuffRemains(RAKE) <3 and RakeTargetIsDieing() >= MangleCatDamage()
	{
		Spell(RAKE)
	}
	#ravage
	if BuffPresent(INCARNATION_CAT) Spell(RAVAGE)

	#actions.filler+=/shred,if=(buff.omen_of_clarity.react|buff.berserk.up|energy.regen>=15)&buff.king_of_the_jungle.down
	if BuffPresent(CLEARCASTING) Spell(SHRED)
	if BuffPresent(BERSERK_CAT) or EnergyRegen(atLeast 15)
	and {not CheckBoxOn(infront)
		or {Glyph(GLYPH_OF_SHRED) and {BuffPresent(TIGERS_FURY) or BuffPresent(BERSERK_CAT)}}}
		Spell(SHRED)

	#actions.filler+=/mangle_cat,if=buff.king_of_the_jungle.down
	Spell(MANGLE_CAT)
}

AddFunction AoeFillerActions
{
	if ThrashCatHitDamage() > SwipeCatDamage() * 1.11
		and {{HasEnergyForThrash() and ExpiringBuffSafetyMargin() < BuffRemains(ROR_MASTERY)}
		or {not HasEnergyForThrash() and ThrashEnergySafetyMargin() < BuffRemains(ROR_MASTERY)}}
	{
		Spell(THRASH_CAT)
	}
	Spell(SWIPE_CAT)
}


# Feral rotation

AddFunction MainActions
{
	HealingTouch()

	SavageRoarOrWeakenedArmorMissing()

	RangeCheck()

	DpsCooldownLogic()

	#Also includes Clearcasting Thrash and end of fight Ferocious Bite
	ExecuteRangeRipFerociousBiteLogic()

	RipLogic()

	SavageRoarRefreshLogic()

	RakeLogic()

	ThrashLogic()

	NonExcuteRangeFerociousBiteLogic()
}

AddFunction FillerConditions
{
	#run_action_list,name=filler,if=buff.omen_of_clarity.react
	BuffPresent(CLEARCASTING)
	#run_action_list,name=filler,if=buff.feral_fury.react
	or {BuffPresent(FERAL_FURY) and BuffRemains(FERAL_FURY) > TimeTilEnergyForMangle()}
	#run_action_list,name=filler,if=(combo_points<5&dot.rip.remains<3)|(combo_points=0&buff.savage_roar.remains<2)
	or {not ComboPoints(atLeast 5) and target.DebuffRemains(RIP less 3)}
		or {ComboPoints(atMost 0) and BuffRemains(SAVAGE_ROAR less 2)}
	#run_action_list,name=filler,if=target.time_to_die<=8.5
	or target.TimeToDie(atMost 8.5)
	#run_action_list,name=filler,if=(talent.dream_of_cenarius.enabled&buff.tigers_fury.up)|buff.berserk.up
	or {TalentPoints(DREAM_OF_CENARIUS_TALENT) and BuffPresent(TIGERS_FURY)}
		or BuffPresent(BERSERK_CAT)
	#run_action_list,name=filler,if=cooldown.tigers_fury.remains<=3
	or SpellCooldown(TIGERS_FURY atMost 3)
	#run_action_list,name=filler,if=talent.dream_of_cenarius.enabled&combo_points<=3&buff.predatory_swiftness.remains<(5.5-combo_points)&buff.predatory_swiftness.up
	or {TalentPoints(DREAM_OF_CENARIUS_TALENT) and BuffPresent(PREDATORY_SWIFTNESS) and BuffRemains(PREDATORY_SWIFTNESS) <= {5.5-ComboPoints()} and ComboPoints(less 4)}
	#run_action_list,name=filler,if=energy.time_to_max<=1
	or TimeToMaxEnergy(atMost 1.25)
}

AddFunction AoeActions
{
	HealingTouch()

	SavageRoarOrWeakenedArmorMissing()

	RangeCheck()

	DpsCooldownLogic()

	ExecuteRangeRipFerociousBiteLogic()

	if TalentPoints(DREAM_OF_CENARIUS_TALENT) or TalentPoints(SOUL_OF_THE_FOREST_TALENT) or Enemies(atMost 6)
	{
		RipLogic()
	}

	SavageRoarRefreshLogic()

	#pool_resource,for_next=1
	#thrash_cat,if=dot.thrash_cat.remains<3
	if {HasEnergyForThrash()
		and target.DebuffRemains(THRASH_CAT less 3)}
	or {not HasEnergyForThrash()
		and target.DebuffRemains(THRASH_CAT) < 3 + TimeTilEnergyForThrash()}
	{
		if TimeTilEnergyForThrash() >=1.5 SpareGcdCooldowns()
		Spell(THRASH_CAT)
	}

	if target.TimeToDie() - target.DebuffRemains(RAKE) >15
	{
		#rake,if=buff.rune_of_reorigination.up&active_enemies<=8&dot.rake.remains<3&target.time_to_die>=15&action.rake.tick_damage%dot.rake.tick_dmg>=0.75
		if BuffPresent(ROR_MASTERY) and RakeRatio() >75 and Enemies(atMost 8)
			and {{HasEnergyForRake() and target.DebuffRemains(RAKE less 3) and ExpiringBuffSafetyMargin() < BuffRemains(ROR_MASTERY)}
			or {not HasEnergyForRake() and target.DebuffRemains(RAKE) < 3 + TimeTilEnergyForRake() and RakeEnergySafetyMargin() < BuffRemains(ROR_MASTERY) and TimeTilEnergyForRake() <= BuffRemains(ROR_MASTERY) + ExpiringBuffSafetyMargin()}}
		{
			Spell(RAKE)
		}

		if Enemies(atMost 4)
		{
			#rake,if=active_enemies<=4&dot.rake.remains<3&target.time_to_die>=15&action.rake.tick_damage%dot.rake.tick_dmg>=0.75
			if RakeRatio() >75
				and {{HasEnergyForRake() and target.DebuffRemains(RAKE less 3)}
				or {not HasEnergyForRake() and target.DebuffRemains(RAKE) < 3 + TimeTilEnergyForRake()}}
			{
				Spell(RAKE)
			}
			#rake if its about to fall off.  Simcraft doesn't require this line but ovale does for the prediction box.
			if {HasEnergyForRake() and target.DebuffRemains(RAKE less 0.001)}
				or {not HasEnergyForRake() and target.DebuffRemains(RAKE) < 0.001 + TimeTilEnergyForRake()}
			{
				Spell(RAKE)
			}
		}
	}

	#ferocious_bite,if=combo_points>=5&dot.rip.ticking&talent.dream_of_cenarius.enabled&talent.soul_of_the_forest.enabled&buff.berserk.up
	if TalentPoints(DREAM_OF_CENARIUS_TALENT) and TalentPoints(SOUL_OF_THE_FOREST_TALENT) and BuffPresent(BERSERK_CAT)
	{
		Spell(FEROCIOUS_BITE)
	}

}

AddFunction Prediction
{
	if Stance(3) {
		MainActions()
	}
	if Stance(1) {
		if BuffPresent(HEART_OF_THE_WILD) Spell(FRENZIED_REGEN)
		unless BuffPresent(HEART_OF_THE_WILD) Spell(CAT_FORM)
	}
	if Stance(0) {
		if BuffPresent(HEART_OF_THE_WILD) {
			if BuffExpires(HEART_OF_THE_WILD) Texture(spell_holy_blessingofagility)
		}
		unless BuffPresent(HEART_OF_THE_WILD) Spell(CAT_FORM)
	}
	if Stance(4) or Stance(2) Spell(CAT_FORM)
}

#####################
## Feral icons (Mastery=2) ##
#####################

AddIcon help=Rake_Ratio size=small mastery=2 checkboxon=cooldownsRatio
{
	RakeRatio()
}

AddIcon help=Rip_Ratio size=small mastery=2 checkboxon=cooldownsRatio
{
	RipRatio()
}

#AddIcon help=Interrupts_and_Wild_Charge size=small mastery=2 checkboxon=cooldownsL {
#    if target.InRange(SKULL_BASH_CAT) Spell(SKULL_BASH_CAT)
#    unless target.Classification(worldboss)
#    {
#        if TalentPoints(MIGHTY_BASH_TALENT) and target.InRange(MIGHTY_BASH) Spell(MIGHTY_BASH)
#        if TalentPoints(TYPHOON_TALENT) and target.InRange(SKULL_BASH_CAT) Spell(TYPHOON)
#        if ComboPoints(more 0) and target.InRange(MAIM) Spell(MAIM)
#    }
#    Spell(WILD_CHARGE)
#}

AddIcon size=small mastery=2 checkboxon=cooldownsL {
	Spell(TIGERS_FURY)
}
AddIcon help=Berserk size=small mastery=2 checkboxon=cooldownsL { # Berserk Icon
	if BuffPresent(TIGERS_FURY) Spell(BERSERK_CAT)
	if Spell(BERSERK_CAT) Texture(Ability_mount_polarbear_white)
}


# Predictive rotation
AddIcon help=Predictive size=small mastery=2 checkboxon=altpredictive {
	Prediction()
}

AddIcon help=Talent_Cooldowns size=small mastery=2 checkboxon=altpredictive {
	if TalentPoints(FORCE_OF_NATURE_TALENT)
	{
		if Charges(FORCE_OF_NATURE) ==3 or {Charges(FORCE_OF_NATURE) ==2 and SpellChargeCooldown(FORCE_OF_NATURE) <=1} Spell(FORCE_OF_NATURE)
		if BuffPresent(TICKING_EBON_DETONATOR)
		   or {BuffPresent(SOUL_CHARM) and BuffRemains(SOUL_CHARM) <= TreantTimeThreshold()}
		   or {BuffPresent(ROR_MASTERY) and BuffRemains(ROR_MASTERY) <= TreantTimeThreshold()}
		   or {BuffPresent(BAD_JUJU) and BuffRemains(BAD_JUJU) <= TreantTimeThreshold()}
		   or {BuffPresent(VICIOUS_TALISMAN) and BuffRemains(VICIOUS_TALISMAN) <= TreantTimeThreshold()}
		   or {BuffPresent(ASSURANCE_OF_CONSEQUENCE) and BuffRemains(ASSURANCE_OF_CONSEQUENCE) <= TreantTimeThreshold()}
		   or {BuffPresent(HAROMMS_TALISMAN) and BuffRemains(HAROMMS_TALISMAN) <= TreantTimeThreshold()}
		   or {BuffPresent(SIGIL_OF_RAMPAGE)  and BuffRemains(SIGIL_OF_RAMPAGE) <= TreantTimeThreshold()}
		{
			Spell(FORCE_OF_NATURE)
		}
	}
	unless TalentPoints(FORCE_OF_NATURE_TALENT)
	{
		if TalentPoints(HEART_OF_THE_WILD_TALENT) Spell(HEART_OF_THE_WILD)
		if TalentPoints(DREAM_OF_CENARIUS_TALENT)
		{
			if TalentPoints(CENARION_WARD_TALENT) Spell(CENARION_WARD)
			if TalentPoints(RENEWAL_TALENT) Spell(RENEWAL)
		}
		if TalentPoints(NATURES_VIGIL_TALENT) Spell(NATURES_VIGIL)
	}
}

# Main rotation
AddIcon help=main mastery=2 {
	NotInCombat()
	if Stance(3)
	{
		MainActions()
		if FillerConditions() FillerActions()
		SpareGcdCooldowns()
	}
	if Stance(1)
	{
		if BuffPresent(HEART_OF_THE_WILD)
			BearMain()
		unless BuffPresent(HEART_OF_THE_WILD) Spell(CAT_FORM)
	}
	if Stance(0)
	{
		if BuffPresent(HEART_OF_THE_WILD)
		{
			if CastTime(WRATH) <BuffRemains(HEART_OF_THE_WILD) Spell(WRATH)
			Spell(CAT_FORM)
		}
		unless BuffPresent(HEART_OF_THE_WILD) Spell(CAT_FORM)
	}
	if Stance(4) or Stance(2) Spell(CAT_FORM)
}

# Predictive rotation
AddIcon help=Predictive mastery=2 checkboxon=predictive {
	Prediction()
}

AddIcon help=aoe mastery=2 checkboxon=showaoe
{
	NotInCombat()
	if Stance(3)
	{
		AoeActions()
		if FillerConditions() AoeFillerActions()
		SpareGcdCooldowns()
	}
	if Stance(1)
	{
		if BuffPresent(HEART_OF_THE_WILD)
			BearMainAOE()
		unless BuffPresent(HEART_OF_THE_WILD) Spell(CAT_FORM)
	}
	if Stance(0)
	{
		if BuffRemains(HEART_OF_THE_WILD) > GCD()
			Spell(HURRICANE)
		Spell(CAT_FORM)
	}
	if Stance(4) or Stance(2) Spell(CAT_FORM)
}

AddIcon help=Savage_Roar size=small mastery=2 checkboxon=cooldownsR { # Savage Roar
	if BuffExpires(SAVAGE_ROAR) Texture(ability_druid_skinteeth)
}
AddIcon help=Rip size=small mastery=2 checkboxon=cooldownsR { # Rip
	if TargetDebuffExpires(RIP) Texture(ability_ghoulfrenzy)
}
AddIcon help=Rake size=small mastery=2 checkboxon=cooldownsR { # Rake
	if TargetDebuffExpires(RAKE) Texture(ability_druid_disembowel)
}
AddIcon help=Thrash size=small mastery=2 checkboxon=cooldownsR { # Thrash
	if TargetDebuffExpires(THRASH_CAT) Texture(spell_druid_thrash)
}

################################
## Guardian rotation functions (Mastery=3) ##
################################

AddFunction BearMain {
	if Threat() <100 and target.DebuffPresent(LACERATE) and target.DebuffRemains(LACERATE less 2) Spell(LACERATE)
	if Threat() <100 and BuffPresent(INCARNATION_BEAR) and target.DebuffRemains(THRASH_BEAR less 2) Spell(THRASH_BEAR)

	Spell(MANGLE_BEAR)

	# Debuff maintenance.
	if target.DebuffRemains(WEAKENED_BLOWS any=1 atMost 3) Spell(THRASH_BEAR)
	if target.DebuffRemains(WEAKENED_ARMOR any=1 atMost 3) or target.DebuffStacks(WEAKENED_ARMOR any=1 less 3)
	{
		FaerieFire()
	}

	Spell(LACERATE)
	if target.DebuffPresent(THRASH_BEAR 6) FaerieFire()
	Spell(THRASH_BEAR)
}

AddFunction BearMainAOE {
	Spell(MANGLE_BEAR)
	Spell(THRASH_BEAR)
	Spell(SWIPE_BEAR)
}

#######################
## Guardian icons (Mastery=3) ##
#######################

AddIcon help=Rake size=small mastery=3 checkboxon=cooldownsRatio
{
	# Offset the guardian icons if the user has bleed ratios enabled
}

AddIcon help=Rip size=small mastery=3 checkboxon=cooldownsRatio
{
	# Offset the guardian icons if the user has bleed ratios enabled
}

AddIcon size=small mastery=3 checkboxon=cooldownsL {
	Spell(BARKSKIN)
}

AddIcon size=small mastery=3 checkboxon=cooldownsL {
	if TalentPoints(RENEWAL_TALENT) Spell(RENEWAL)
	if TalentPoints(CENARION_WARD_TALENT) Spell(CENARION_WARD)
}

AddIcon mastery=3 size=small checkboxon=altpredictive {
	if Rage(less 11) Spell(ENRAGE useable=1)
	Spell(SAVAGE_DEFENSE usable=1)
	Spell(FRENZIED_REGEN)
}

AddIcon mastery=3 size=small checkboxon=altpredictive {
	if BuffPresent(TOOTH_AND_CLAW) and target.DebuffExpires(TOOTH_AND_CLAW_DEBUFF) Spell(TOOTH_AND_CLAW)
	unless BuffPresent(TOOTH_AND_CLAW) and target.DebuffExpires(TOOTH_AND_CLAW_DEBUFF) Spell(MAUL)
}

# Main rotation
AddIcon help=main mastery=3 {
	if InCombat(no) and BuffRemains(str_agi_int any=1 less 400) Spell(MARK_OF_THE_WILD)
	unless Stance(1) Spell(BEAR_FORM)

	BearMain()
}

AddIcon mastery=3 checkboxon=predictive {
	if Rage(less 11) Spell(ENRAGE useable=1)
	Spell(SAVAGE_DEFENSE usable=1)
	Spell(FRENZIED_REGEN)
}

AddIcon help=aoe mastery=3 checkboxon=showaoe {
	if InCombat(no) and BuffRemains(str_agi_int any=1 less 400) Spell(MARK_OF_THE_WILD)
	unless Stance(1) Spell(BEAR_FORM)

	BearMainAOE()
}
AddIcon size=small mastery=3 checkboxon=cooldownsR {
	Spell(SURVIVAL_INSTINCTS)
}

AddIcon size=small mastery=3 checkboxon=cooldownsR {
	Spell(MIGHT_OF_URSOC)
}

AddIcon size=small mastery=3 checkboxon=cooldownsR {
	if TalentPoints(INCARNATION_TALENT) Spell(INCARNATION_BEAR)
	if TalentPoints(FORCE_OF_NATURE_TALENT) Spell(FORCE_OF_NATURE)
}
AddIcon size=small mastery=3 checkboxon=cooldownsR {
	Spell(BERSERK_BEAR)
}
]]

	OvaleScripts:RegisterScript("DRUID", name, desc, code, "script")
end
