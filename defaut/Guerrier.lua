Ovale.defaut["WARRIOR"] =
[[
#Spells
Define(BATTLESHOUT 6673)
	SpellAddBuff(BATTLESHOUT BATTLESHOUT=120)
Define(BATTLESTANCE 2457)
Define(BERSERKERRAGE 18499)
Define(BERSERKERSTANCE 2458)
Define(BLADESTORM 46924)
Define(BLOODTHIRST 23881)
	SpellInfo(BLOODTHIRST cd=3)
Define(CHARGE 100)
Define(CLEAVE 845)
	SpellInfo(CLEAVE cd=3)
Define(COLOSSUSSMASH 86346)
	SpellInfo(COLOSSSUSSMASH cd=20)
Define(COMMANDINGSHOUT 469)
	SpellAddBuff(COMMANDINGSHOUT cd=60 COMMANDINGSHOUT=120)
Define(CONCUSSIONBLOW 12809)
Define(DEADLYCALM 85730)
Define(DEATHWISH 12292)
	SpellInfo(DEATHWISH cd=180)
Define(DEFENSIVESTANCE 71)
Define(DEMOSHOUT 1160)
	SpellAddTargetDebuff(DEMOSHOUT DEMOSHOUT=45)
Define(DEVASTATE 20243)
	SpellAddTargetDebuff(DEVASTATE SUNDERARMORDEBUFF=30)
Define(EXECUTE 5308)
	SpellAddBuff(EXECUTE EXECUTIONER=9)
Define(HEROICLEAP 6544)
Define(HEROICSTRIKE 78)
	SpellInfo(HEROICSTRIKE cd=3)
Define(HEROICTHROW 57755)
Define(HEROICFURY 60970)
Define(INTERCEPT 20252)
Define(INTERVENE 3411)
Define(LASTSTAND 12975)
Define(MORTALSTRIKE 12294)
	SpellInfo(MORTALSTRIKE cd=4.5)
Define(OVERPOWER 7384)
	SpellInfo(OVERPOWER cd=1)
Define(PUMMEL 6552)
Define(RAGINGBLOW 85288)
	SpellInfo(RAGINGBLOW cd=6)
Define(RECKLESSNESS 1719)
Define(REND 772)
	SpellAddTargetDebuff(REND RENDDEBUFF=15)
Define(RETALIATION 20230)
Define(REVENGE 6572)
	SpellInfo(REVENGE cd=5)
Define(SHATTERINGTHROW 64382)
Define(SHIELDBASH 72)
Define(SHIELDBLOCK 2565)
Define(SHIELDWALL 871)
Define(SHIELDSLAM 23922)
	SpellInfo(SHIELDSLAM cd=6)
Define(SHOCKWAVE 46968)
Define(SLAM 1464)
	SpellAddBuff(SLAM BLOODSURGE=-1)
Define(STRIKE 88161)
	SpellInfo(STRIKE cd=3)
Define(SUNDERARMOR 7386)
	SpellAddTargetDebuff(SUNDERARMOR SUNDERARMORDEBUFF=30)
Define(SWEEPINGSTRIKES 12328)
Define(THUNDERCLAP 6343)
	SpellAddTargetDebuff(THUNDERCLAP THUNDERCLAP=30)
Define(VICTORYRUSH 34428)
Define(WHIRLWIND 1680)
	SpellInfo(WHIRLWIND cd=8)

#Buffs
Define(BLOODSURGE 46916)
Define(TASTEFORBLOOD 60503)
Define(ENRAGE 14202)
Define(EXECUTIONER 90806)
Define(SUNDERARMORDEBUFF 58567)
Define(RENDDEBUFF 94009)
Define(INCITE 86627)
Define(BATTLETRANCE 12964)
Define(SLAUGHTER 84584)

#Talents
Define(SLAMTALENT 2233)
Define(SUDDENDEATH 52437)

AddCheckBox(multi L(AOE))
AddCheckBox(demo SpellName(DEMOSHOUT))
AddCheckBox(sunder SpellName(SUNDERARMOR) default)
AddListItem(shout none L(None))
AddListItem(shout battle SpellName(BATTLESHOUT) default)
AddListItem(shout command SpellName(COMMANDINGSHOUT))

ScoreSpells(DEADLYCALM COLOSSUSSMASH RAGINGBLOW OVERPOWER VICTORYRUSH BLOODTHIRST SLAM REND MORTALSTRIKE EXECUTE SHIELDSLAM REVENGE
				DEVASTATE)

AddIcon help=main mastery=1
{
	if List(shout command) and {Mana(less 20) or BuffExpires(stamina 3)} Spell(COMMANDINGSHOUT nored=1)
    if List(shout battle) and {Mana(less 20) or BuffExpires(strengthagility 3)} Spell(BATTLESHOUT nored=1)
	if TargetClassification(worldboss) and CheckBoxOn(demo) and TargetDebuffExpires(lowerphysicaldamage 2) Spell(DEMOSHOUT nored=1)
	if TargetDebuffExpires(SUNDERARMORDEBUFF 3 stacks=3) and CheckBoxOn(sunder) and TargetDebuffExpires(lowerarmor 2 mine=0) Spell(SUNDERARMOR nored=1)

	if Mana(less 20) Spell(DEADLYCALM)
	if CheckBoxOn(multi)
	{
		Spell(SWEEPINGSTRIKES)
		if BuffExpires(SWEEPINGSTRIKES) and BuffExpires(DEADLYCALM) Spell(BLADESTORM)
		Spell(CLEAVE)
	}
	if BuffExpires(TASTEFORBLOOD 1.5) and BuffPresent(TASTEFORBLOOD) Spell(OVERPOWER)
	if TargetDebuffExpires(RENDDEBUFF) Spell(REND)
	Spell(COLOSSUSSMASH)
	Spell(MORTALSTRIKE)
	#overpower,if=!buff.lambs_to_the_slaughter.up&rage>35&target.health_pct<20
	if BuffExpires(SLAUGHTER 0) and Mana(more 35) and TargetLifePercent(less 20)
		Spell(OVERPOWER usable=1)
    if TargetLifePercent(less 20) Spell(EXECUTE)
	Spell(OVERPOWER usable=1)
	unless 1.5s before Spell(MORTALSTRIKE) Spell(SLAM)
}

AddIcon help=main mastery=2
{
	if List(shout command) and {Mana(less 20) or BuffExpires(stamina 3)} Spell(COMMANDINGSHOUT nored=1)
    if List(shout battle) and {Mana(less 20) or BuffExpires(strengthagility 3)} Spell(BATTLESHOUT nored=1)
	if TargetClassification(worldboss) and CheckBoxOn(demo) and TargetDebuffExpires(lowerphysicaldamage 2) Spell(DEMOSHOUT nored=1)
	if TargetDebuffExpires(SUNDERARMORDEBUFF 3 stacks=3) and CheckBoxOn(sunder) and TargetDebuffExpires(lowerarmor 2 mine=0) Spell(SUNDERARMOR nored=1)
	
	if BuffExpires(EXECUTIONER 1.5 stacks=5) and TargetLifePercent(less 20) Spell(EXECUTE)
	
	if CheckBoxOn(multi) Spell(WHIRLWIND)
	Spell(COLOSSUSSMASH)
	if TargetDebuffPresent(COLOSSUSSMASH mine=1) and TargetLifePercent(less 20) Spell(EXECUTE)
	if BuffExpires(DEATHWISH 0) and BuffExpires(RECKLESSNESS 0) and BuffExpires(ENRAGE 0) and Mana(less 15) and
		1s before Spell(RAGINGBLOW) Spell(BERSERKERRAGE)
	if {BuffPresent(DEATHWISH) or BuffPresent(RECKLESSNESS) or BuffPresent(ENRAGE) or BuffPresent(BERSERKERRAGE)}
		and TargetLifePercent(more 20) Spell(RAGINGBLOW)
	
    Spell(BLOODTHIRST)
	if TargetLifePercent(less 20) Spell(EXECUTE)
	Spell(VICTORYRUSH usable=1)
	if BuffPresent(BLOODSURGE) Spell(SLAM)
}


AddIcon help=main mastery=3
{
	if List(shout command) and {Mana(less 20) or BuffExpires(stamina 3)} Spell(COMMANDINGSHOUT nored=1)
    if List(shout battle) and {Mana(less 20) or BuffExpires(strengthagility 3)} Spell(BATTLESHOUT nored=1)
	if TargetClassification(worldboss) and CheckBoxOn(demo) and TargetDebuffExpires(lowerphysicaldamage 2) Spell(DEMOSHOUT nored=1)

	if LifePercent(less 75) Spell(VICTORYRUSH usable=1)
	if CheckBoxOn(multi)
	{
		if TargetDebuffExpires(RENDDEBUFF mine=1) Spell(REND)
		Spell(THUNDERCLAP)
		Spell(SHOCKWAVE)
	}
	Spell(SHIELDSLAM)
	Spell(REVENGE usable=1)
	if TargetDebuffExpires(meleeslow) Spell(THUNDERCLAP)
	Spell(VICTORYRUSH usable=1)
	Spell(DEVASTATE)
}

AddIcon help=offgcd mastery=1
{
	if target.IsInterruptible() Spell(PUMMEL)
	if CheckBoxOn(multi) Spell(CLEAVE) 
	if Mana(more 65) or BuffPresent(DEADLYCALM) or BuffPresent(INCITE) or BuffPresent(BATTLETRANCE)
		Spell(HEROICSTRIKE)
}

AddIcon help=offgcd mastery=2
{
	if target.IsInterruptible() Spell(PUMMEL)
	if CheckBoxOn(multi) Spell(CLEAVE) 
	if {Mana(more 60) or BuffPresent(BATTLETRANCE) or BuffPresent(INCITE)} and TargetLifePercent(more 20)
		Spell(HEROICSTRIKE)
}

AddIcon help=offgcd mastery=3
{
	if target.IsInterruptible() Spell(SHIELDBASH)
	if CheckBoxOn(multi) Spell(CLEAVE)
	if Mana(more 60) Spell(HEROICSTRIKE)
}

AddIcon help=cd mastery=1
{
    Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=cd mastery=2
{
	Spell(DEATHWISH)
	Spell(RECKLESSNESS)
    Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=cd mastery=3
{
	Spell(SHIELDBLOCK)
	Spell(SHIELDWALL)
	Spell(LASTSTAND)
    Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}


]]
