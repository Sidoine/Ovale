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
	SpellAddTargetDebuff(COLOSSUSSMASH COLOSSUSSMASH=6 SUNDERARMORDEBUFF=30)
Define(COMMANDINGSHOUT 469)
	SpellInfo(COMMANDINGSHOUT cd=30)
	SpellAddBuff(COMMANDINGSHOUT COMMANDINGSHOUT=120)
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
Define(EXECUTIONER 90806)
Define(SUNDERARMORDEBUFF 58567)
Define(RENDDEBUFF 94009)
Define(INCITE 86627)
Define(BATTLETRANCE 12964)
Define(SLAUGHTER 84584)
Define(THUNDERSTRUCK 87096)
Define(VICTORIOUS 32216)
Define(ENRAGEWRECKINGCREW 57519)

#Talents
Define(SLAMTALENT 2233)
Define(SUDDENDEATH 52437)
Define(TITANSGRIPTALENT 9658)
Define(EXECUTIONERTALENT 9644)

#Glyphs
Define(GLYPHOFBERSERKERRAGE 58096)

AddCheckBox(aoe L(AOE) default)
AddCheckBox(demo SpellName(DEMOSHOUT))
AddCheckBox(sunder SpellName(SUNDERARMOR) default)
AddCheckBox(dancing SpellName(BERSERKERSTANCE) default mastery=1)
AddCheckBox(leap SpellName(HEROICLEAP) mastery=1)
AddCheckBox(leap SpellName(HEROICLEAP) mastery=2)
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
	if TargetDebuffExpires(SUNDERARMORDEBUFF 3 stacks=2) and CheckBoxOn(sunder) and TargetDebuffExpires(lowerarmor 2 mine=0) Spell(SUNDERARMOR nored=1)

	if CheckBoxOn(dancing)
	{
		#/stance,choose=berserker,if=buff.taste_for_blood.down&dot.rend.remains>0&rage<=75,use_off_gcd=1
		if Stance(1) and BuffExpires(TASTEFORBLOOD 0) and {TargetDebuffPresent(RENDDEBUFF mine=1) or TargetDeadIn(less 15)} and Mana(less 76) 
			Spell(BERSERKERSTANCE)
		#/stance,choose=battle,if=dot.rend.remains=0,use_off_gcd=1
		if Stance(3) and TargetDebuffExpires(RENDDEBUFF 0 mine=1) and TargetDeadIn(more 15)
			Spell(BATTLESTANCE)
	}

	#/rend,if=!ticking
	if TargetDebuffExpires(RENDDEBUFF mine=1) and TargetDeadIn(more 10) Spell(REND)
	#/mortal_strike,if=target.health_pct>20
	if TargetLifePercent(more 20) Spell(MORTALSTRIKE)
	#/colossus_smash,if=buff.colossus_smash.down
	if TargetDebuffExpires(COLOSSUSSMASH mine=1) Spell(COLOSSUSSMASH)
	if TalentPoints(EXECUTIONERTALENT more 0)
	{
		#/execute,if=buff.executioner_talent.remains<1.5
		if BuffExpires(EXECUTIONER 1.5) and TargetLifePercent(less 20) Spell(EXECUTE)
	}
	
	#/mortal_strike,if=target.health_pct<=20&(buff.colossus_smash.down|dot.rend.remains<3|buff.wrecking_crew.down|rage<=25|rage>=35)
	if TargetLifePercent(less 20) and {TargetDebuffExpires(COLOSSUSSMASH mine=1) or
		TargetDebuffExpires(REND 3 mine=1) or BuffExpires(ENRAGEWRECKINGCREW) or Mana(less 26) or Mana(more 34)}
		Spell(MORTALSTRIKE)
	#/execute,if=rage>90
	if Mana(more 90) and TargetLifePercent(less 20) Spell(EXECUTE)
	
	if CheckBoxOn(dancing)
	{
		#/stance,choose=battle,if=target.health_pct>20&(buff.taste_for_blood.up|buff.overpower.up)&rage<=75&cooldown.mortal_strike.remains>=1.5,use_off_gcd=1
		if TargetLifePercent(more 20) and BuffPresent(TASTEFORBLOOD) and Mana(less 76) and {spell(MORTALSTRIKE) > 1.5}
			Spell(BATTLESTANCE)
	}
	#/overpower,if=buff.taste_for_blood.up|buff.overpower.up
	if BuffPresent(TASTEFORBLOOD) Spell(OVERPOWER)
	#/overpower
	Spell(OVERPOWER usable=1)
	#/execute
	if TargetLifePercent(less 20) Spell(EXECUTE)
	#/colossus_smash,if=buff.colossus_smash.remains<=1.5
	if TargetDebuffExpires(COLOSSUSSMASH 1.5 mine=1)
		Spell(COLOSSUSSMASH)
	#/slam,if=rage>=35|buff.battle_trance.up&buff.inner_rage.down
	if Mana(more 34) or {BuffPresent(BATTLETRANCE) and BuffExpires(INNERRAGE)} Spell(SLAM)
	#/battle_shout,if=rage<60
	if Mana(less 60) Spell(BATTLESHOUT)
}

AddIcon help=offgcd mastery=1
{
	if target.IsInterruptible() Spell(PUMMEL)
	
	#/heroic_leap,use_off_gcd=1,if=buff.colossus_smash.up
	if CheckBoxOn(leap) and TargetDebuffPresent(COLOSSUSSMASH) Spell(HEROICLEAP)
	
	#/berserker_rage,if=buff.deadly_calm.down&cooldown.deadly_calm.remains>1.5&rage<=95,use_off_gcd=1
	if Glyph(GLYPHOFBERSERKERRAGE) and BuffExpires(DEADLYCALM) and {spell(DEADLYCALM)>1.5} and Mana(less 96) Spell(BERSERKERRAGE)
	#/deadly_calm,use_off_gcd=1
	Spell(DEADLYCALM)
	#/inner_rage,if=buff.deadly_calm.down&cooldown.deadly_calm.remains>15,use_off_gcd=1
	if BuffExpires(DEADLYCALM) and {spell(DEADLYCALM)>15} Spell(INNERRAGE)
	
	#/heroic_strike,if=buff.deadly_calm.up,use_off_gcd=1
	if BuffPresent(DEADLYCALM) Spell(HEROICSTRIKE)
	
	if ArmorSetParts(T13 more 1)
	{
		#/heroic_strike,if=target.health_pct>20&rage>85,use_off_gcd=1";
		if TargetLifePercent(more 20) and Mana(more 85) Spell(HEROICSTRIKE)
		#/heroic_strike,if=rage>75&buff.inner_rage.up,use_off_gcd=1
        if Mana(more 75) and BuffPresent(INNERRAGE) Spell(HEROICSTRIKE)
		#/heroic_strike,if=buff.incite.up&(target.health_pct>20|(target.health_pct<=20&buff.battle_trance.up)),use_off_gcd=1";
		if BuffPresent(INCITE) and {TargetLifePercent(more 20) or {TargetLifePercent(less 20) and BuffPresent(BATTLETRANCE)}}
			Spell(HEROICSTRIKE)
		#/heroic_strike,if=buff.inner_rage.up&target.health_pct>20&(rage>40|buff.battle_trance.up),use_off_gcd=1
		if BuffPresent(INNERRAGE) and TargetLifePercent(more 20) and {Mana(more 40) or BuffPresent(BATTLETRANCE)}
			Spell(HEROICSTRIKE)
		#/heroic_strike,if=buff.inner_rage.up&target.health_pct<=20&(rage>=50|buff.battle_trance.up),use_off_gcd=1
		if BuffPresent(INNERRAGE) and TargetLifePercent(less 20) and {Mana(more 49) or BuffPresent(BATTLETRANCE)}
			Spell(HEROICSTRIKE)
	}
	if ArmorSetParts(T13 equal 0)
	{
		#/heroic_strike,if=target.health_pct>20&rage>95,use_off_gcd=1";
		if TargetLifePercent(more 20) and Mana(more 95) Spell(HEROICSTRIKE)
        #/heroic_strike,if=rage>85&buff.inner_rage.up,use_off_gcd=1";
		if Mana(more 85) and BuffPresent(INNERRAGE) Spell(HEROICSTRIKE)
        #/heroic_strike,if=buff.incite.up&(target.health_pct>20|(target.health_pct<=20&buff.battle_trance.up)),use_off_gcd=1";
		if BuffPresent(INCITE) and {TargetLifePercent(more 20) or {TargetLifePercent(less 20) and BuffPresent(BATTLETRANCE)}}
			Spell(HEROICSTRIKE)
        #/heroic_strike,if=buff.inner_rage.up&target.health_pct>20&(rage>50|buff.battle_trance.up),use_off_gcd=1";
		if BuffPresent(INNERRAGE) and TargetLifePercent(more 20) and {Mana(more 50) or BuffPresent(BATTLETRANCE)}
			Spell(HEROICSTRIKE)
        #/heroic_strike,if=buff.inner_rage.up&target.health_pct<=20&(rage>=60|buff.battle_trance.up),use_off_gcd=1";
		if BuffPresent(INNERRAGE) and TargetLifePercent(less 20) and {Mana(more 59) or BuffPresent(BATTLETRANCE)}
			Spell(HEROICSTRIKE)
	}
}

AddIcon help=aoe mastery=1 checkboxon=aoe
{
	#/sweeping_strikes,if=target.adds>0
	Spell(SWEEPINGSTRIKES)
	#/bladestorm,if=target.adds>0&!buff.deadly_calm.up&!buff.sweeping_strikes.up
	if BuffExpires(SWEEPINGSTRIKES) and BuffExpires(DEADLYCALM) Spell(BLADESTORM)
	if Stance(3) Spell(WHIRLWIND)
	Spell(CLEAVE)
	if Stance(1) Spell(THUNDERCLAP)
}

AddIcon help=cd mastery=1
{
	#/recklessness,if=target.health_pct>90|target.health_pct<=20,use_off_gcd=1
	if {TargetLifePercent(more 20) and TargetDeadIn(more 320)} or TargetLifePercent(less 20)
	{
		#/recklessness,if=((target.health_pct>20&target.time_to_die>320)|target.health_pct<=20)
		Spell(RECKLESSNESS)
	}
    Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=2
{
	if List(shout command) and {Mana(less 20) or BuffExpires(stamina 3)} Spell(COMMANDINGSHOUT nored=1)
    if List(shout battle) and {Mana(less 20) or BuffExpires(strengthagility 3)} Spell(BATTLESHOUT nored=1)
	if TargetClassification(worldboss) and CheckBoxOn(demo) and TargetDebuffExpires(lowerphysicaldamage 2) Spell(DEMOSHOUT nored=1)
	if TargetDebuffExpires(SUNDERARMORDEBUFF 3 stacks=2) and CheckBoxOn(sunder) and TargetDebuffExpires(lowerarmor 2 mine=0) Spell(SUNDERARMOR nored=1)
	
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
		if BuffExpires(enrage 0) and Mana(more 15) and
			1s before Spell(RAGINGBLOW) Spell(BERSERKERRAGE)
		#/raging_blow
		if BuffPresent(enrage)
			Spell(RAGINGBLOW)
	}
	#/slam,if=buff.bloodsurge.react
	if BuffPresent(BLOODSURGE) Spell(SLAM)	
	#/execute,if=rage>=50
	if Mana(more 49) and TargetLifePercent(less 20) Spell(EXECUTE)
	if TalentPoints(TITANSGRIPTALENT less 1)
	{
		#/berserker_rage,if=!(buff.death_wish.up|buff.enrage.up|buff.unholy_frenzy.up)&rage>15&cooldown.raging_blow.remains<1
		if BuffExpires(enrage 0) and Mana(more 15) and
			1s before Spell(RAGINGBLOW) Spell(BERSERKERRAGE)
		#/raging_blow
		if BuffPresent(enrage)
			Spell(RAGINGBLOW)
	}
	
	if BuffPresent(VICTORIOUS) Spell(VICTORYRUSH)
	#/battle_shout,if=rage<70
	if Mana(less 70) Spell(BATTLESHOUT priority=2)
}

AddIcon help=offgcd mastery=2
{
	if target.IsInterruptible() Spell(PUMMEL)
	#/heroic_leap,use_off_gcd=1,if=buff.colossus_smash.up
	if CheckBoxOn(leap) and TargetDebuffPresent(COLOSSUSSMASH) Spell(HEROICLEAP)
	#/heroic_strike,if=((rage>=85&target.health_pct>=20)|buff.battle_trance.up|((buff.incite.up|buff.colossus_smash.up)&((rage>=50&target.health_pct>=20)|(rage>=75&target.health_pct<20))))
	if {Mana(more 84) and TargetLifePercent(more 20)} or BuffPresent(BATTLETRANCE) or 
			{{BuffPresent(INCITE) or TargetDebuffPresent(COLOSSUSSMASH mine=1)} and {{Mana(more 49) and TargetLifePercent(more 20)} or {Mana(more 74) and TargetLifePercent(less 20)}}}
		Spell(HEROICSTRIKE)
}

AddIcon help=aoe mastery=2 checkboxon=aoe
{
	#/whirlwind,if=target.adds>0
	Spell(WHIRLWIND)
	#/cleave,if=target.adds>0
	Spell(CLEAVE) 
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

# Protection warrior rotation from EJ for 4.2:
# http://elitistjerks.com/f81/t110315-cataclysm_protection_warrior/#post1813079
AddIcon help=main mastery=3
{
	if Stance(3) Spell(DEFENSIVESTANCE)
	if List(shout command) and {Mana(less 20) or BuffExpires(stamina 3)} Spell(COMMANDINGSHOUT nored=1)
	if List(shout battle) and {Mana(less 20) or BuffExpires(strengthagility 3)} Spell(BATTLESHOUT nored=1)

	if LifePercent(less 75) and BuffPresent(VICTORIOUS) Spell(VICTORYRUSH usable=1)

	if CheckBoxOn(sunder) and TargetDebuffExpires(SUNDERARMORDEBUFF 3 stacks=3) and TargetDebuffExpires(lowerarmor 2 mine=0) Spell(DEVASTATE)

	if 1s before Spell(SHIELDSLAM) Spell(SHIELDSLAM usable=1)

	if CheckBoxOn(demo) and TargetDebuffExpires(lowerphysicaldamage 4) Spell(DEMOSHOUT)
	if TargetDebuffExpires(meleeslow 2) Spell(THUNDERCLAP)

	Spell(VICTORYRUSH usable=1)
	Spell(REVENGE usable=1)

	# A single Rend application is only worth using on a 30%-bleed debuffed single target if it ticks at
	# least four times. Unbuffed, it must tick all six times. Never refresh an existing Rend -- always
	# wait for it to run its full duration or else you lose the initial application tick.
	#
	unless TargetDebuffPresent(RENDDEBUFF mine=1) {
		if TargetDebuffPresent(bleed) and TargetDeadIn(more 9) or TargetDeadIn(more 15) {
			Spell(REND)
		}
	}
	Spell(DEVASTATE)
}

AddIcon help=offgcd mastery=3
{
	if target.IsInterruptible() Spell(PUMMEL)
	if Mana(more 44) Spell(HEROICSTRIKE)
	if Mana(more 80) Spell(INNERRAGE)
}

AddIcon help=aoe mastery=3 checkboxon=aoe
{
	if TargetDebuffExpires(RENDDEBUFF mine=1) Spell(REND)
	Spell(THUNDERCLAP)
	Spell(SHOCKWAVE)
	Spell(CLEAVE)
}

AddIcon help=cd mastery=3
{
	if Stance(2)
	{
		Spell(SHIELDBLOCK usable=1)
		Spell(SHIELDWALL usable=1)
		Spell(LASTSTAND)
	}
	if Stance(1) Spell(RECKLESSNESS)
    Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}


]]
