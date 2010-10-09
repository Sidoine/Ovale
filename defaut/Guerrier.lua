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
Define(COLOSSSUSSMASH 86346)
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
	SpellAddTargetDebuff(DEVASTATE SUNDERARMOR=30)
Define(EXECUTE 5308)
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
	SpellAddTargetDebuff(REND REND=15)
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
	SpellAddTargetDebuff(SUNDERARMOR SUNDERARMOR=30)
Define(SWEEPINGSTRIKES 12328)
Define(THUNDERCLAP 6343)
	SpellAddTargetDebuff(THUNDERCLAP THUNDERCLAP=30)
Define(VICTORYRUSH 34428)
Define(WHIRLWIND 1680)
	SpellInfo(WHIRLWIND cd=8)

#Buffs
Define(BLOODSURGE 46916)
Define(TASTEFORBLOOD 56636)
Define(ENRAGE 14202)

#Talents
Define(SLAMTALENT 2233)
Define(SUDDENDEATH 52437)

AddCheckBox(multi L(AOE))
AddCheckBox(demo SpellName(DEMOSHOUT))
AddCheckBox(sunder SpellName(SUNDERARMOR) default)
AddListItem(shout none L(None))
AddListItem(shout battle SpellName(BATTLESHOUT))
AddListItem(shout command SpellName(COMMANDINGSHOUT))

ScoreSpells(WHIRLWIND BLOODTHIRST SLAM REND MORTALSTRIKE EXECUTE SHIELDSLAM REVENGE)

AddIcon help=main mastery=1
{
	if List(shout command) and {Mana(less 20) or BuffExpires(stamina 3)} Spell(COMMANDINGSHOUT nored=1)
    if List(shout battle) and {Mana(less 20) or BuffExpires(strengthagility 3)} Spell(BATTLESHOUT nored=1)
	if TargetClassification(worldboss) and CheckBoxOn(demo) and TargetDebuffExpires(lowerphysicaldamage 2) Spell(DEMOSHOUT nored=1)
	if TargetDebuffExpires(SUNDERARMOR 2 stacks=3) and CheckBoxOn(sunder) and TargetDebuffExpires(lowerarmor 2) Spell(SUNDERARMOR nored=1)

	if Mana(less 20) Spell(DEADLYCALM)
	if TargetDebuffExpires(REND) Spell(REND)
	if CheckBoxOn(multi) Spell(BLADESTORM)
	Spell(COLOSSUSSMASH)
	Spell(MORTALSTRIKE)
	Spell(OVERPOWER usable=1)
	if CheckBoxOn(multi) Spell(CLEAVE)
    if TargetLifePercent(less 20) Spell(EXECUTE)
	if Mana(more 60) Spell(HEROICSTRIKE)
	Spell(SLAM)
}

AddIcon help=cd mastery=1
{
    Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=2
{
	if List(shout command) and {Mana(less 20) or BuffExpires(stamina 3)} Spell(COMMANDINGSHOUT nored=1)
    if List(shout battle) and {Mana(less 20) or BuffExpires(strengthagility 3)} Spell(BATTLESHOUT nored=1)
	if TargetClassification(worldboss) and CheckBoxOn(demo) and TargetDebuffExpires(lowerphysicaldamage 2) Spell(DEMOSHOUT nored=1)
	if TargetDebuffExpires(SUNDERARMOR 2 stacks=3) and CheckBoxOn(sunder) and TargetDebuffExpires(lowerarmor 2) Spell(SUNDERARMOR nored=1)
	
	if CheckBoxOn(multi) Spell(WHIRLWIND)
	Spell(COLOSSUSSMASH)
	Spell(RAGINGBLOW usable=1)
    Spell(BLOODTHIRST)
    Spell(VICTORYRUSH usable=1)
	if BuffPresent(BLOODSURGE) Spell(SLAM)
    if TargetLifePercent(less 20) Spell(EXECUTE)
	if CheckBoxOn(multi) Spell(CLEAVE)
	if Mana(more 60) Spell(HEROICSTRIKE)
	if BuffExpires(DEATHWISH) and BuffExpires(RECKLESSNESS) and BuffExpires(ENRAGE) Spell(BERSERKERRAGE)
}

AddIcon help=cd mastery=2
{
	Spell(DEATHWISH)
	Spell(RECKLESSNESS)
    Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=3
{
	if List(shout command) and {Mana(less 20) or BuffExpires(stamina 3)} Spell(COMMANDINGSHOUT nored=1)
    if List(shout battle) and {Mana(less 20) or BuffExpires(strengthagility 3)} Spell(BATTLESHOUT nored=1)
	if TargetClassification(worldboss) and CheckBoxOn(demo) and TargetDebuffExpires(lowerphysicaldamage 2) Spell(DEMOSHOUT nored=1)

	if CheckBoxOn(multi)
	{
		if TargetDebuffExpires(REND mine=1) Spell(REND)
		Spell(THUNDERCLAP)
		Spell(SHOCKWAVE)
		Spell(CLEAVE)
	}
	Spell(SHIELDSLAM)
	if Mana(more 60) and CheckBoxOff(multi) Spell(HEROICSTRIKE)
	Spell(REVENGE usable=1)
	if TargetDebuffExpires(meleeslow) Spell(THUNDERCLAP)
	Spell(VICTORYRUSH usable=1)
	Spell(DEVASTATE)
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
