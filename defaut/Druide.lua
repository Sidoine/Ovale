Ovale.defaut["DRUID"] =
[[
Define(BARKSKIN 22812)
Define(BERSERK 50334) #cat+bear cd buff
	SpellInfo(BERSERK cd=180)
Define(CLAW 16827) #cat no positionning
	SpellInfo(CLAW combo=1)
Define(DEMOROAR 99) #bear
	SpellAddTargetDebuff(DEMOROAR DEMOROAR=30)
Define(ENRAGE 5229) #bear
Define(FAERIEFIRE 770) #moonkin
	SpellAddTargetDebuff(FAERIEFIRE FAERIEFIREDEBUFF=300)
Define(FAERIEFERAL 16857) #bear+cat
	SpellAddTargetDebuff(FAERIEFERAL FAERIEFIREDEBUFF=300)
Define(FEROCIOUSBITE 22568) #cat finish 35-70 mana
	SpellInfo(FEROCIOUSBITE combo=-5 mana=70)
Define(FORCEOFNATURE 33831) #moonkin cd
	SpellInfo(FORCEOFNATURE cd=180)
Define(FRENZIEDREGENERATION 22842) #bear
Define(INNERVATE 29166)
Define(INSECTSWARM 5570) #moonkin
	SpellAddTargetDebuff(INSECTSWARM INSECTSWARM=12)
Define(LACERATE 33745) #bear bleed*3
Define(MANGLECAT 33876) #cat bleed+debuff
	SpellInfo(MANGLECAT combo=1)
	SpellAddTargetDebuff(MANGLECAT MANGLECAT=12)
Define(MANGLEBEAR 33878) #bear bleed+debuff
Define(MAUL 6807) #bear
Define(MOONFIRE 8921) #moonkin
	SpellAddTargetDebuff(MOONFIRE MOONFIRE=12)
Define(PULVERIZE 80313) #bear after lacerate*3
Define(RAKE 1822) #cat bleed
	SpellInfo(RAKE combo=1)
	SpellAddTargetDebuff(RAKE RAKE=9)
Define(RAVAGE 6785) #cat behind+(prowling or stampede)
	SpellInfo(RAVAGE combo=1)
	SpellAddBuff(RAVAGE STAMPEDE=0)
Define(RIP 1079) #cat bleed
	SpellInfo(RIP combo=-5 duration=12 resetcounter=ripshreds)
	SpellInfo(RIP glyph=GLYPHOFSHRED addduration=6)
	SpellInfo(RIP glyph=GLYPHOFRIP addduration=4)
	SpellAddTargetDebuff(RIP RIP=12)
Define(SAVAGEROAR 52610) #cat damage buff
	SpellInfo(SAVAGEROAR combo=-5)
	SpellAddBuff(SAVAGEROAR SAVAGEROAR=14)
Define(SHRED 5221) #cat behind
	SpellInfo(SHRED combo=1 inccounter=ripshreds)
Define(STARFALL 48505) #moonkin cd aoe
Define(STARFIRE 2912) #moonkin
	SpellInfo(STARFIRE eclipse=20)
Define(STARSURGE 78674) #moonkin 15 lunar+solar
	SpellInfo(STARSURGE cd=15 starsurge=15)
Define(SUNFIRE 93402)
	SpellAddTargetDebuff(SUNFIRE SUNFIRE=18)
Define(SURVIVALINSTINCTS 61336) #cat+bear surv cd
Define(SWIPEBEAR 779) #bear aoe
	SpellInfo(SWIPEBEAR cd=6)
Define(SWIPECAT 62078) #cat aoe
Define(THRASH 77758) #bear aoe bleed
Define(TIGERSFURY 5217) #cat buff
	SpellInfo(TIGERSFURY cd=30)
Define(TYPHOON 50516)
Define(WRATH 5176) #moonkin
	SpellInfo(WRATH eclipse=-13)

#Glyphs
Define(GLYPHOFSHRED 54815)

#Buff
Define(CLEARCASTING 16870)
Define(ECLIPSELUNAR 48518) #Increased by wrath
Define(ECLIPSESOLAR 48517) #Increased by starfire
Define(SHOOTINGSTARS 93400)
Define(STAMPEDE 81022)
Define(FAERIEFIREDEBUFF 91565)
Define(STRENGTHOFTHEPANTHER 90166) #feral T11 4-pieces bonus

AddCheckBox(multi L(AOE))
AddCheckBox(lucioles SpellName(FAERIEFIRE) default)
AddCheckBox(wrath SpellName(WRATH) mastery=1)
AddCheckBox(mangle SpellName(MANGLECAT) default mastery=2)
AddCheckBox(demo SpellName(DEMOROAR) default mastery=2)
AddCheckBox(shred SpellName(SHRED) default mastery=2)

ScoreSpells(FAERIEFERAL DEMOROAR MANGLEBEAR LACERATE SAVAGEROAR RIP 
		MANGLECAT RAKE SHRED FEROCIOUSBITE INSECTSWARM MOONFIRE
		WRATH STARFIRE STARSURGE SUNFIRE PULVERIZE MAUL
		CLAW)

AddIcon help=main mastery=1
{
	#Contributed by Grabielz
	if CheckBoxOn(lucioles) and TargetDebuffExpires(FAERIEFIRE 3 mine=1 stacks=3) and TargetDebuffExpires(lowerarmor 2 mine=0) and TargetDeadIn(more 15)
		Spell(FAERIEFIRE nored=1)

	if Speed(more 0)
	{
		Spell(TYPHOON)
		if BuffPresent(SHOOTINGSTARS) Spell(STARSURGE)
		if TargetDebuffExpires(INSECTSWARM 4 mine=1) and TargetDeadIn(more 6)
			Spell(INSECTSWARM)
		if BuffPresent(ECLIPSESOLAR)
			Spell(SUNFIRE)
		Spell(MOONFIRE)
	}

	if TargetDebuffExpires(MOONFIRE 1 mine=1) and TargetDebuffExpires(SUNFIRE 1 mine=1) and TargetDeadIn(more 6)
	{
		if BuffPresent(ECLIPSESOLAR)
			Spell(SUNFIRE nored=1)
		Spell(MOONFIRE nored=1)
	}
	
	if TargetDebuffExpires(INSECTSWARM 1 mine=1) and TargetDeadIn(more 6)
		Spell(INSECTSWARM nored=1)  
		
	if TargetDebuffExpires(INSECTSWARM 3 mine=1) and TargetDeadIn(more 6) and BuffPresent(ECLIPSESOLAR) and Eclipse(less 16)
		Spell(INSECTSWARM nored=1)  
		
	Spell(STARSURGE)
	
	if BuffPresent(ECLIPSELUNAR) or Eclipse(equal -100)
	{
		Spell(STARFIRE)
	}
	
	if BuffPresent(ECLIPSESOLAR) or Eclipse(equal 100)
	{
		Spell(WRATH)
	}

	if TargetDebuffExpires(INSECTSWARM 0 mine=1) and TargetDeadIn(more 6)
		Spell(INSECTSWARM)  


	if {Eclipse(equal 0) and CheckBoxOn(wrath)} or Eclipse(less 0)
		Spell(WRATH)
	
	if {Eclipse(equal 0) and CheckBoxOff(wrath)} or Eclipse(more 0)
		Spell(STARFIRE)
}

AddIcon help=cd mastery=1
{
	Spell(FORCEOFNATURE)
    Spell(STARFALL)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}
		
AddIcon help=main mastery=2
{
	if Stance(1) # bear
	{
		unless TargetDebuffExpires(LACERATE 4) and TargetDebuffPresent(bleed)
			Spell(MANGLEBEAR)
		
		if Mana(more 10) and TargetDebuffExpires(LACERATE 4 stacks=3)
			Spell(LACERATE)
			
		if TargetDebuffPresent(LACERATE stacks=3)
			Spell(PULVERIZE)

		if CheckBoxOn(lucioles) and TargetDebuffExpires(lowerarmor 2 mine=0) and TargetDebuffExpires(FAERIEFIREDEBUFF 3 stacks=3)
			Spell(FAERIEFERAL)

		if CheckBoxOn(demo) and TargetDebuffExpires(lowerphysicaldamage 2)
			Spell(DEMOROAR)

		if Mana(more 50) Spell(MAUL)
		if CheckBoxOn(multi)
		{
			Spell(THRASH)
			Spell(SWIPEBEAR)
		}
		Spell(MANGLEBEAR)
		Spell(LACERATE)		
	}

	if Stance(3) # cat
	{
		#tigers_fury,if=energy<=26
		if Mana(less 27) Spell(TIGERSFURY)
	
		#mangle_cat,if=set_bonus.tier11_4pc_melee&(buff.t11_4pc_melee.stack<3|buff.t11_4pc_melee.remains<3)
		if ArmorSetParts(T11 more 3) and BuffExpires(STRENGTHOFTHEPANTHER 3 stacks=3) Spell(MANGLECAT)
		
		#faerie_fire_feral,if=debuff.faerie_fire.stack<3|!(debuff.sunder_armor.up|debuff.expose_armor.up)
		if CheckBoxOn(lucioles) and	TargetDebuffExpires(lowerarmor 2 mine=0) and TargetDebuffExpires(FAERIEFIREDEBUFF 3 stacks=3) and TargetDeadIn(more 15)
			Spell(FAERIEFERAL)
		
		#mangle_cat,if=debuff.mangle.remains<=2&(!debuff.mangle.up|debuff.mangle.remains>=0.0)
		if TargetDebuffExpires(bleed 0) and CheckBoxOn(mangle)
			Spell(MANGLECAT)
			
		#ravage,if=buff.stampede_cat.up&buff.stampede_cat.remains<=1
		if BuffPresent(STAMPEDE) and BuffExpires(STAMPEDE 1) Spell(RAVAGE)
		
		#berserk,if=time_to_max_energy>=2.0&!buff.tigers_fury.up&cooldown.tigers_fury.remains>15
		if 2s before Mana(more 99) and BuffExpires(TIGERSFURY) and 15s before Spell(TIGERSFURY) Spell(BERSERK)
		
		#ferocious_bite,if=buff.combo_points.stack>=1&dot.rip.ticking&dot.rip.remains<=1&target.health_pct<=25
		if ComboPoints(more 0) and TargetDebuffPresent(RIP mine=1) and TargetDebuffExpires(RIP 1 mine=1) and TargetLifePercent(less 25)
			Spell(FEROCIOUSBITE)
		
		#ferocious_bite,if=buff.combo_points.stack>=5&dot.rip.ticking&target.health_pct<=25
		if ComboPoints(more 4) and TargetDebuffPresent(RIP mine=1) and TargetLifePercent(less 25)
			Spell(FEROCIOUSBITE)
		
		#rip,if=buff.combo_points.stack>=5&target.time_to_die>=6&dot.rip.remains<2.0&(buff.berserk.up|dot.rip.remains<=cooldown.tigers_fury.remains)
		if ComboPoints(more 4) and TargetDeadIn(more 6) and TargetDebuffExpires(RIP 2 mine=1) and 
				{BuffPresent(BERSERK) or {target.debuffExpires(RIP mine=1)<spell(TIGERSFURY)}}
			Spell(RIP)
			
		#rake,if=target.time_to_die>=8.5&buff.tigers_fury.up&dot.rake.remains<9.0&(!dot.rake.ticking|dot.rake.multiplier<multiplier)
		#not sure what this multiplier is
		if TargetDeadIn(more 8.5) and BuffPresent(TIGERSFURY) and TargetDebuffExpires(RAKE 0 mine=1)
			Spell(RAKE)
		#rake,if=target.time_to_die>=dot.rake.remains&dot.rake.remains<3.0&(buff.berserk.up|energy>=71|(cooldown.tigers_fury.remains+0.8)>=dot.rake.remains)
		if {target.timeToDie()>target.debuffExpires(RAKE mine=1)} and TargetDebuffExpires(RAKE 3 mine=1) and {BuffPresent(BERSERK) or Mana(more 70) or
				{{spell(TIGERSFURY)+0.8}>target.debuffExpires(RAKE mine=1)}}
			Spell(RAKE)
		
		#shred,if=buff.omen_of_clarity.react
		if BuffPresent(CLEARCASTING) Spell(SHRED)
		
		#savage_roar,if=buff.combo_points.stack>=1&buff.savage_roar.remains<=1
		if ComboPoints(more 0) and BuffExpires(SAVAGEROAR 1) Spell(SAVAGEROAR)
		
		#savage_roar,if=target.time_to_die>=9&buff.combo_points.stack>=5&dot.rip.ticking&dot.rip.remains<=12&@(dot.rip.remains-buff.savage_roar.remains)<=3
		if TargetDeadIn(more 9) and ComboPoints(more 4) and TargetDebuffPresent(RIP mine=1) and TargetDebuffExpires(RIP 12 mine=1)
				and {{target.debuffExpires(RIP mine=1) - buffExpires(SAVAGEROAR)}<3}
			Spell(SAVAGEROAR)
		
		#ferocious_bite,if=(target.time_to_die<=4&buff.combo_points.stack>=5)|target.time_to_die<=1
		if {TargetDeadIn(less 4) and ComboPoints(more 4)} or TargetDeadIn(less 1) Spell(FEROCIOUSBITE)
		#ferocious_bite,if=level>80&buff.combo_points.stack>=5&dot.rip.remains>=14.0&buff.savage_roar.remains>=10.0
		if ComboPoints(more 4) and TargetDebuffPresent(RIP 14 mine=1) and BuffPresent(SAVAGEROAR 10) Spell(FEROCIOUSBITE)
		#shred,extend_rip=1,if=dot.rip.ticking&dot.rip.remains<=4&target.health_pct>25
		if Glyph(GLYPHOFSHRED) and Counter(ripshreds less 3) and TargetDebuffPresent(RIP mine=1) and TargetDebuffExpires(RIP 4 mine=1) and TargetLifePercent(more 25) Spell(SHRED)

		#ravage,if=buff.stampede_cat.up&!buff.omen_of_clarity.react&buff.tigers_fury.up
		if BuffPresent(STAMPEDE) and BuffExpires(CLEARCASTING) and BuffPresent(TIGERSFURY) Spell(RAVAGE)
		#mangle_cat,if=set_bonus.tier11_4pc_melee&buff.t11_4pc_melee.stack<3
		if ArmorSetParts(T11 more 3) and BuffExpires(STRENGTHOFTHEPANTHER 0 stacks=3) Spell(MANGLECAT)
		
		#shred,if=buff.combo_points.stack<=4&dot.rake.remains>3.0&dot.rip.remains>3.0&(time_to_max_energy<=2.0|(buff.berserk.up&energy>=20))
		if ComboPoints(less 5) and TargetDebuffPresent(RAKE 3 mine=1) and TargetDebuffPresent(RIP 3 mine=1) and {2s before Mana(more 99) or {BuffPresent(BERSERK) and Mana(more 20)}}
			Spell(SHRED)
		#shred,if=cooldown.tigers_fury.remains<=3.0
		if 3s before Spell(TIGERSFURY) Spell(SHRED)
		#shred,if=target.time_to_die<=dot.rake.duration
		if target.timeToDie()<target.debuffExpires(RAKE mine=1) Spell(SHRED)
		#shred,if=buff.combo_points.stack=0&(buff.savage_roar.remains<=2.0|dot.rake.remains>=5.0)
		if ComboPoints(less 1) and {BuffExpires(SAVAGEROAR 2) or TargetDebuffPresent(RAKE 5 mine=1)} Spell(SHRED)
		#shred,if=!dot.rip.ticking|time_to_max_energy<=1.0
		if TargetDebuffExpires(RIP 0 mine=1) or 1s before Mana(more 99) Spell(SHRED)
	}
}

AddIcon help=cd mastery=2
{
	#unless BuffPresent(TIGERSFURY) Spell(BERSERK)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

]]
