Ovale.defaut["WARRIOR"] =
[[
#Spells
Define(BATTLESHOUT 6673)
	SpellInfo(BATTLESHOUT cd=30)
	SpellAddBuff(BATTLESHOUT BATTLESHOUT=120)
Define(BATTLESTANCE 2457)
Define(BERSERKERRAGE 18499)
	SpellInfo(BERSERKERRAGE cd=30)
Define(BERSERKERSTANCE 2458)
Define(BLADESTORM 46924)
	SpellInfo(BLADESTORM cd=90)
Define(BLOODTHIRST 23881)
	SpellInfo(BLOODTHIRST cd=3)
Define(CHARGE 100)
	SpellInfo(CHARGE cd=15)
Define(CLEAVE 845)
	SpellInfo(CLEAVE cd=3)
Define(COLOSSUSSMASH 86346)
	SpellInfo(COLOSSUSSMASH cd=20)
	SpellAddTargetDebuff(COLOSSUSSMASH COLOSSUSSMASH=6)
Define(COMMANDINGSHOUT 469)
	SpellInfo(COMMANDINGSHOUT cd=30)
	SpellAddBuff(COMMANDINGSHOUT cd=60 COMMANDINGSHOUT=120)
Define(CONCUSSIONBLOW 12809)
	SpellInfo(CONCUSSIONBLOW cd=30)
Define(DEADLYCALM 85730)
	SpellInfo(DEADLYCALM cd=120)
	SpellAddBuff(DEADLYCALM DEADLYCALM=10)
Define(DEATHWISH 12292)
	SpellInfo(DEATHWISH cd=180)
	SpellAddBuff(DEATHWISH DEATHWISH=30)
Define(DEFENSIVESTANCE 71)
Define(DEMOSHOUT 1160)
	SpellAddTargetDebuff(DEMOSHOUT DEMOSHOUT=45)
Define(DEVASTATE 20243)
	SpellAddTargetDebuff(DEVASTATE SUNDERARMORDEBUFF=30)
Define(EXECUTE 5308)
	SpellAddBuff(EXECUTE EXECUTIONER=9)
Define(HEROICLEAP 6544)
	SpellInfo(HEROICLEAP cd=60)
Define(HEROICSTRIKE 78)
	SpellInfo(HEROICSTRIKE cd=3)
Define(HEROICTHROW 57755)
	SpellInfo(HEROICTHROW cd=60)
Define(HEROICFURY 60970)
	SpellInfo(HEROICFURY cd=60)
Define(INNERRAGE 1134)
	SpellInfo(INNERRAGE cd=30)
	SpellAddBuff(INNERRAGE INNERRAGE=15)
Define(INTERCEPT 20252)
	SpellInfo(INTERCEPT cd=30)
Define(INTERVENE 3411)
	SpellInfo(INTERVENE cd=30)
Define(LASTSTAND 12975)
	SpellInfo(LASTSTAND cd=180)
Define(MORTALSTRIKE 12294)
	SpellInfo(MORTALSTRIKE cd=4.5)
Define(OVERPOWER 7384)
	SpellInfo(OVERPOWER cd=1)
	SpellAddBuff(OVERPOWER TASTEFORBLOOD=0)
Define(PUMMEL 6552)
	SpellInfo(PUMMEL cd=10)
Define(RAGINGBLOW 85288)
	SpellInfo(RAGINGBLOW cd=6)
Define(RECKLESSNESS 1719)
	SpellInfo(RECKLESSNESS cd=300)
	SpellAddBuff(RECKLESSNESS RECKLESSNESS=12)
Define(REND 772)
	SpellAddTargetDebuff(REND RENDDEBUFF=15)
Define(RETALIATION 20230)
	SpellInfo(RETALIATION cd=300)
	SpellAddBuff(RETALIATION RETALIATION=12)
Define(REVENGE 6572)
	SpellInfo(REVENGE cd=5)
Define(SHATTERINGTHROW 64382)
	SpellInfo(SHATTERINGTHROW cd=300)
	SpellAddTargetDebuff(SHATTERINGTHROW SHATTERINGTHROW=10)
Define(SHIELDBASH 72)
	SpellInfo(SHIELDBASH cd=12)
Define(SHIELDBLOCK 2565)
	SpellInfo(SHIELDBLOCK cd=60)
	SpellAddBuff(SHIELDBLOCK SHIELDBLOCK=10)
Define(SHIELDWALL 871)
	SpellInfo(SHIELDWALL cd=300)
	SpellAddBuff(SHIELDWALL SHIELDWALL=12)
Define(SHIELDSLAM 23922)
	SpellInfo(SHIELDSLAM cd=6)
Define(SHOCKWAVE 46968)
	SpellInfo(SHOCKWAVE cd=20)
	SpellAddBuff(SHOCKWAVE THUNDERSTRUCK=0)
Define(SLAM 1464)
	SpellAddBuff(SLAM BLOODSURGE=-1)
Define(STRIKE 88161)
	SpellInfo(STRIKE cd=3)
Define(SUNDERARMOR 7386)
	SpellAddTargetDebuff(SUNDERARMOR SUNDERARMORDEBUFF=30)
Define(SWEEPINGSTRIKES 12328)
	SpellInfo(SWEEPINGSTRIKES cd=60)
Define(THUNDERCLAP 6343)
	SpellInfo(THUNDERCLAP cd=6)
	SpellAddTargetDebuff(THUNDERCLAP THUNDERCLAP=30)
Define(VICTORYRUSH 34428)
	SpellAddBuff(VICTORYRUSH VICTORIOUS=0)
Define(WHIRLWIND 1680)
	SpellInfo(WHIRLWIND cd=10)

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
Define(THUNDERSTRUCK 87096)
Define(VICTORIOUS 32216)

#Talents
Define(SLAMTALENT 2233)
Define(SUDDENDEATH 52437)
Define(TITANSGRIPTALENT 9658)

#Glyphs
Define(GLYPHOFBERSERKERRAGE 58096)

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

	#/stance,choose=battle,if=(cooldown.recklessness.remains>0&rage<=50)
	if Stance(3) and Mana(less 50) unless Spell(RECKLESSNESS) Spell(BATTLESTANCE)
	#/berserker_rage,if=!buff.deadly_calm.up&rage<70
	if Glyph(GLYPHOFBERSERKERRAGE) and BuffExpires(DEADLYCALM) and Mana(less 71) Spell(BERSERKERRAGE)
	#/deadly_calm,if=rage<30&((target.health_pct>20&target.time_to_die>130)|(target.health_pct<=20&buff.recklessness.up))
	if Mana(less 30) and {{TargetLifePercent(more 20) and TargetDeadIn(more 130)} or {TargetLifePercent(less 20) and BuffPresent(RECKLESSNESS)}} Spell(DEADLYCALM)
	
	if CheckBoxOn(multi)
	{
		#/sweeping_strikes,if=target.adds>0
		Spell(SWEEPINGSTRIKES)
		#/bladestorm,if=target.adds>0&!buff.deadly_calm.up&!buff.sweeping_strikes.up
		if BuffExpires(SWEEPINGSTRIKES) and BuffExpires(DEADLYCALM) Spell(BLADESTORM)
	}
	#/inner_rage,if=!buff.deadly_calm.up&rage>80&cooldown.deadly_calm.remains>15
	if BuffExpires(DEADLYCALM) and Mana(more 80) and {spell(DEADLYCALM)>15} Spell(INNERRAGE)
	#/overpower,if=buff.taste_for_blood.remains<=1.5
	if BuffExpires(TASTEFORBLOOD 1.5) and BuffPresent(TASTEFORBLOOD) Spell(OVERPOWER)
	#/mortal_strike,if=target.health_pct>20|rage>=30
	if TargetLifePercent(more 20) or Mana(more 29) Spell(MORTALSTRIKE)
	#/execute,if=buff.battle_trance.up
	if BuffPresent(BATTLETRANCE) and TargetLifePercent(less 20) Spell(EXECUTE)
	#/rend,if=!ticking
	if TargetDebuffExpires(RENDDEBUFF) Spell(REND)
	#/colossus_smash,if=buff.colossus_smash.remains<0.5
	if BuffExpires(COLOSSUSSMASH 0.5) Spell(COLOSSUSSMASH)
	#/execute,if=(buff.deadly_calm.up|buff.recklessness.up)
	if BuffPresent(DEADLYCALM) or BuffPresent(RECKLESSNESS) if TargetLifePercent(less 20) Spell(EXECUTE)
	#/mortal_strike
	Spell(MORTALSTRIKE)
	#/overpower
	Spell(OVERPOWER usable=1)
	#/execute
	if TargetLifePercent(less 20) Spell(EXECUTE)
	#/slam,if=(cooldown.mortal_strike.remains>=1.5&(rage>=35|swing.mh.remains<1.1|buff.deadly_calm.up|buff.colossus_smash.up))|(cooldown.mortal_strike.remains>=1.2&buff.colossus_smash.remains>0.5&rage>=35)
	if {{spell(MORTALSTRIKE)>1.5} and {Mana(more 34) or NextSwing(main 1.1) or BuffPresent(DEADLYCALM) or BuffPresent(COLOSSUSSMASH)}} or {spell(MORTALSTRIKE)>1.2 and BuffPresent(COLOSSUSSMASH 0.5) and Mana(more 34)}
		Spell(SLAM)
	#/battle_shout,if=rage<20
	if Mana(less 20) Spell(BATTLESHOUT priority=2)
}

AddIcon help=offgcd mastery=1
{
	if target.IsInterruptible() Spell(PUMMEL)
	if CheckBoxOn(multi) Spell(CLEAVE)
	#/heroic_strike,if=(rage>70|buff.deadly_calm.up|buff.incite.up|buff.battle_trance.up)
	if Mana(more 70) or BuffPresent(DEADLYCALM) or BuffPresent(INCITE) or BuffPresent(BATTLETRANCE)
		Spell(HEROICSTRIKE)
}

AddIcon help=cd mastery=1
{
	if {TargetLifePercent(more 20) and TargetDeadIn(more 320)} or TargetLifePercent(less 20)
	{
		#/stance,choose=berserker,if=cooldown.recklessness.remains=0&rage<=50&((target.health_pct>20&target.time_to_die>320)|target.health_pct<=20)
		if Stance(1) and Spell(RECKLESSNESS) and Mana(less 50) Spell(BERSERKERSTANCE)
		#/recklessness,if=((target.health_pct>20&target.time_to_die>320)|target.health_pct<=20)
		if Stance(3) Spell(RECKLESSNESS)
	}
    Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=2
{
	if List(shout command) and {Mana(less 20) or BuffExpires(stamina 3)} Spell(COMMANDINGSHOUT nored=1)
    if List(shout battle) and {Mana(less 20) or BuffExpires(strengthagility 3)} Spell(BATTLESHOUT nored=1)
	if TargetClassification(worldboss) and CheckBoxOn(demo) and TargetDebuffExpires(lowerphysicaldamage 2) Spell(DEMOSHOUT nored=1)
	if TargetDebuffExpires(SUNDERARMORDEBUFF 3 stacks=3) and CheckBoxOn(sunder) and TargetDebuffExpires(lowerarmor 2 mine=0) Spell(SUNDERARMOR nored=1)
	
	#/whirlwind,if=target.adds>0
	if CheckBoxOn(multi) Spell(WHIRLWIND)
	#/execute,if=buff.executioner_talent.remains<1.5
	if BuffExpires(EXECUTIONER 1.5) and TargetLifePercent(less 20) Spell(EXECUTE)
	#/colossus_smash
	Spell(COLOSSUSSMASH)
	#/execute,if=buff.executioner_talent.stack<5
	if BuffExpires(EXECUTIONER 0 stacks=5) and TargetLifePercent(less 20) Spell(EXECUTE)
	#/bloodthirst
	Spell(BLOODTHIRST)
	if TalentPoints(TITANSGRIPTALENT more 0)
	{
		#/berserker_rage,if=!(buff.death_wish.up|buff.enrage.up|buff.unholy_frenzy.up)&rage>15&cooldown.raging_blow.remains<1
		if BuffExpires(DEATHWISH 0) and BuffExpires(RECKLESSNESS 0) and BuffExpires(ENRAGE 0) and Mana(less 15) and
			1s before Spell(RAGINGBLOW) Spell(BERSERKERRAGE)
		#/raging_blow
		if BuffPresent(DEATHWISH) or BuffPresent(RECKLESSNESS) or BuffPresent(ENRAGE) or BuffPresent(BERSERKERRAGE)
			Spell(RAGINGBLOW)
	}
	#/slam,if=buff.bloodsurge.react
	if BuffPresent(BLOODSURGE) Spell(SLAM)	
	#/execute,if=rage>=50
	if Mana(more 49) and TargetLifePercent(less 20) Spell(EXECUTE)
	if TalentPoints(TITANSGRIPTALENT less 1)
	{
		#/berserker_rage,if=!(buff.death_wish.up|buff.enrage.up|buff.unholy_frenzy.up)&rage>15&cooldown.raging_blow.remains<1
		if BuffExpires(DEATHWISH 0) and BuffExpires(RECKLESSNESS 0) and BuffExpires(ENRAGE 0) and Mana(less 15) and
			1s before Spell(RAGINGBLOW) Spell(BERSERKERRAGE)
		#/raging_blow
		if BuffPresent(DEATHWISH) or BuffPresent(RECKLESSNESS) or BuffPresent(ENRAGE) or BuffPresent(BERSERKERRAGE)
			Spell(RAGINGBLOW)
	}
	
	if BuffPresent(VICTORIOUS) Spell(VICTORYRUSH)
	#/battle_shout,if=rage<70
	if Mana(less 70) Spell(BATTLESHOUT priority=2)
}

AddIcon help=offgcd mastery=2
{
	if target.IsInterruptible() Spell(PUMMEL)
	#/cleave,if=target.adds>0
	if CheckBoxOn(multi) Spell(CLEAVE) 
	#/heroic_strike,if=((rage>85&target.health_pct>=20)|buff.battle_trance.up|((buff.incite.up|buff.colossus_smash.up)&((rage>=50&target.health_pct>=20)|(rage>=75&target.health_pct<20))))
	if {Mana(more 85) and TargetLifePercent(more 20)} or BuffPresent(BATTLETRANCE) or 
			{{BuffPresent(INCITE) or BuffPresent(COLOSSUSSMASH)} and {{Mana(more 49) and TargetLifePercent(more 20)} or {Mana(more 74) and TargetLifePercent(less 20)}}}
		Spell(HEROICSTRIKE)
}

AddIcon help=cd mastery=2
{
	#/recklessness
	Spell(RECKLESSNESS)
	#/death_wish
	Spell(DEATHWISH)
    Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=3
{
	if List(shout command) and {Mana(less 20) or BuffExpires(stamina 3)} Spell(COMMANDINGSHOUT nored=1)
    if List(shout battle) and {Mana(less 20) or BuffExpires(strengthagility 3)} Spell(BATTLESHOUT nored=1)
	if CheckBoxOn(demo) and TargetDebuffExpires(lowerphysicaldamage 2) Spell(DEMOSHOUT nored=1)

	if LifePercent(less 75) and BuffPresent(VICTORIOUS) Spell(VICTORYRUSH usable=1)
	if CheckBoxOn(multi)
	{
		if TargetDebuffExpires(RENDDEBUFF mine=1) Spell(REND)
		Spell(THUNDERCLAP)
		Spell(SHOCKWAVE)
	}
	Spell(REVENGE usable=1)
	#if BuffPresent(THUNDERSTRUCK) Spell(SHOCKWAVE)
	Spell(SHIELDSLAM)
	if TargetDebuffExpires(meleeslow) Spell(THUNDERCLAP)
	Spell(VICTORYRUSH usable=1)
	Spell(DEVASTATE)
}

AddIcon help=offgcd mastery=3
{
	if target.IsInterruptible() Spell(SHIELDBASH)
	if CheckBoxOn(multi) Spell(CLEAVE)
	if Mana(more 35) Spell(HEROICSTRIKE)
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
