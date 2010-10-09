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
	SpellAddTargetDebuff(FAERIEFIRE FAERIEFIRE=300)
Define(FAERIEFERAL 16857) #bear+cat
	SpellAddTargetDebuff(FAERIEFERAL FAERIEFERAL=300)
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
Define(RIP 1079) #cat bleed
	SpellInfo(RIP combo=-5 duration=12)
	SpellInfo(RIP glyph=GLYPHOFSHRED addduration=6)
	SpellInfo(RIP glyph=GLYPHOFRIP addduration=4)
	SpellAddTargetDebuff(RIP RIP=12)
Define(SAVAGEROAR 52610) #cat damage buff
	SpellInfo(SAVAGEROAR combo=-5)
	SpellAddBuff(SAVAGEROAR SAVAGEROAR=14)
Define(SHRED 5221) #cat behind
	SpellInfo(SHRED combo=1)
Define(STARFALL 48505) #moonkin cd aoe
Define(STARFIRE 2912) #moonkin
	SpellInfo(STARFIRE eclipse=20)
Define(STARSURGE 78674) #moonkin 15 lunar+solar
	SpellInfo(STARSURGE cd=15 starsurge=15)
Define(SUNFIRE 93402)
	SpellAddTargetDebuff(SUNFIRE SUNFIRE=18)
Define(SURVIVALINSTINCTS 61336) #cat+bear surv cd
Define(SWIPEBEAR 779) #bear aoe
Define(SWIPECAT 62078) #cat aoe
Define(TRASH 77758) #bear aoe bleed
Define(TIGERSFURY 5217) #cat buff
	SpellInfo(TIGERSFURY cd=30)
Define(WRATH 5176) #moonkin
	SpellInfo(WRATH eclipse=-13)

#Glyphs
Define(GLYPHOFSHRED 54815)
Define(GLYPHOFRIP 54818)

#Buff
Define(CLEARCASTING 16870)
Define(ECLIPSELUNAR 48518) #Increased by wrath
Define(ECLIPSESOLAR 48517) #Increased by starfire
Define(SHOOTINGSTARS 93400)

AddCheckBox(multi L(AOE))
AddCheckBox(lucioles SpellName(FAERIEFIRE) default)
AddCheckBox(wrath SpellName(WRATH) mastery=1)
AddCheckBox(mangle SpellName(MANGLECAT) default mastery=2)
AddCheckBox(demo SpellName(DEMOROAR) default mastery=2)
AddCheckBox(shred SpellName(SHRED) default mastery=2)

ScoreSpells(FAERIEFERAL DEMOROAR MANGLEBEAR LACERATE SAVAGEROAR RIP 
		MANGLECAT RAKE SHRED FEROCIOUSBITE INSECTSWARM MOONFIRE
		WRATH STARFIRE)

AddIcon help=main mastery=1
{
	if CheckBoxOn(lucioles) and TargetDebuffExpires(lowerarmor 2) and TargetDeadIn(more 15)
		Spell(FAERIEFIRE)

	if Speed(more 0)
	{
		if BuffPresent(SHOOTINGSTARS) Spell(STARSURGE)
		Spell(MOONFIRE)
	}

	if BuffPresent(SHOOTINGSTARS) and BuffExpires(SHOOTINGSTARS 3) Spell(STARSURGE)
	
	if BuffPresent(ECLIPSELUNAR) or Eclipse(equal -100)
	{
		if TargetDebuffExpires(MOONFIRE 0 mine=1) and TargetDeadIn(more 6)
			Spell(MOONFIRE)
		Spell(STARFIRE)
	}
	
	if BuffPresent(ECLIPSESOLAR) or Eclipse(equal 100)
	{
		if TargetDebuffExpires(INSECTSWARM 0 mine=1) and TargetDeadIn(more 6)
			Spell(INSECTSWARM)  
		if TargetDebuffExpires(SUNFIRE 0 mine=1) and TargetDeadIn(more 6)
			Spell(SUNFIRE)  
		Spell(WRATH)
	}

	if TargetDebuffExpires(INSECTSWARM 0 mine=1) and TargetDeadIn(more 6)
		Spell(INSECTSWARM)  

	if TargetDebuffExpires(MOONFIRE 0 mine=1) and TargetDeadIn(more 6)
		Spell(MOONFIRE)

	Spell(STARSURGE)
		
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

		if CheckBoxOn(lucioles) and TargetDebuffExpires(lowerarmor 2)
			Spell(FAERIEFERAL)

		if CheckBoxOn(demo) and TargetDebuffExpires(lowerphysicaldamage 2)
			Spell(DEMOROAR)

		if Mana(more 50) Spell(MAUL)
		if CheckBoxOn(multi)
			Spell(SWIPEBEAR)    
	}

	if Stance(3) # cat
	{
		if ComboPoints(more 0) and BuffExpires(SAVAGEROAR 2) Spell(SAVAGEROAR priority=4)
	
		if CheckBoxOn(lucioles) and	TargetDebuffExpires(lowerarmor 2) and TargetDeadIn(more 15)
			Spell(FAERIEFERAL)

		#De-synchronize Roar and Rip
		if ComboPoints(more 2) and BuffExpires(SAVAGEROAR 6) and less than 6s between BuffExpires(SAVAGEROAR) and TargetDebuffExpires(RIP mine=1 forceduration=22) 
		{
			unless TargetDebuffExpires(RIP 6 mine=1) Spell(SAVAGEROAR priority=4)
		}

		#Extends Rip with shred if glyph
		if Glyph(GLYPHOFRIP) and TargetDebuffPresent(RIP mine=1) and TargetDebuffExpires(RIP 4 mine=1) and Counter(ripshreds less 3) Spell(SHRED)

		if ComboPoints(more 4)
		{
			if TargetDeadIn(less 7) Spell(FEROCIOUSBITE priority=4)
			if TargetDebuffExpires(RIP 0 mine=1) Spell(RIP priority=4)
			if TargetDebuffPresent(RIP 10 mine=1) and BuffPresent(SAVAGEROAR 6)
			{
				if BuffExpires(BERSERK 0) or {BuffPresent(BERSERK) and Mana(less 20)}
					Spell(FEROCIOUSBITE)
			}
		}
		
		if TargetDebuffExpires(bleed 0) and CheckBoxOn(mangle)
			Spell(MANGLECAT)
		if TargetDebuffExpires(RAKE 0 mine=1) and TargetDeadIn(more 10)
			Spell(RAKE)
	
		if CheckBoxOn(shred)
		{
			if Mana(more 69) Spell(SHRED priority=2)
			if BuffPresent(CLEARCASTING) or TargetDeadIn(less 10) or BuffPresent(BERSERK) 
					Spell(SHRED)
			if ComboPoints(less 5) and TargetDebuffExpires(RIP 3 mine=1) Spell(SHRED)
			if ComboPoints(less 1) and BuffExpires(SAVAGEROAR 2) Spell(SHRED)
		}
		if CheckBoxOff(shred) Spell(CLAW)
	}
}

AddIcon help=cd mastery=2
{
	Spell(BERSERK)
	unless BuffPresent(BERSERK) if Mana(less 40) Spell(TIGERSFURY)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

]]
