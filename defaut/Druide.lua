Ovale.defaut["DRUID"] =
[[
Define(FAERIEFIRE 770)
Define(FAERIEFERAL 16857)
Define(MANGLEBEAR 33878)
Define(DEMOROAR 99)
Define(SWIPE 779)
Define(LACERATE 33745)
Define(MAUL 6807)
Define(RIP 1079)
Define(MANGLECAT 33876)
Define(SHRED 5221)
Define(INSECTSWARM 27013)
Define(MOONFIRE 8921)
Define(STARFIRE 2912)
Define(WRATH 5176)
Define(ECLIPSESTARFIRE 48518)
Define(ECLIPSEWRATH 48517)
Define(TIGERSFURY 5217)
Define(FORCEOFNATURE 33831)
Define(RAKE 59886)
Define(SAVAGEROAR 52610)
Define(FEROCIOUSBITE 22568)
Define(BERSERK 50334)
Define(CLEARCASTING 16870)
Define(CLAW 16827)
Define(STARFALL 48505)
Define(TRAUMA 46856)
Define(GLYPHOFSHRED 54815)
Define(GLYPHOFRIP 54818)

AddCheckBox(multi L(AOE))
AddCheckBox(mangle SpellName(MANGLECAT) default)
AddCheckBox(demo SpellName(DEMOROAR) default)
AddCheckBox(lucioles SpellName(FAERIEFIRE) default)
AddCheckBox(wrath SpellName(WRATH))
AddCheckBox(shred SpellName(SHRED) default)

ScoreSpells(FAERIEFERAL DEMOROAR MANGLEBEAR LACERATE SAVAGEROAR RIP 
		TIGERSFURY MANGLECAT RAKE SHRED FEROCIOUSBITE INSECTSWARM MOONFIRE
		WRATH STARFIRE)
		
SpellInfo(MAUL toggle=1)
SpellAddTargetDebuff(FAERIEFERAL FAERIEFERAL=300)
SpellAddTargetDebuff(FAERIEFIRE FAERIEFIRE=300)
SpellAddTargetDebuff(DEMOROAR DEMOROAR=30)
SpellAddBuff(SAVAGEROAR SAVAGEROAR=14)
SpellAddTargetDebuff(RIP RIP=12)
SpellAddTargetDebuff(MANGLECAT MANGLECAT=12)
SpellAddTargetDebuff(RAKE RAKE=9)
SpellAddTargetDebuff(INSECTSWARM INSECTSWARM=12)
SpellAddTargetDebuff(MOONFIRE MOONFIRE=12)
SpellInfo(TIGERSFURY cd=30)
SpellInfo(BERSERK cd=180)
SpellInfo(FORCEOFNATURE cd=180)
SpellInfo(MANGLECAT combo=1)
SpellInfo(RAKE combo=1)
SpellInfo(SHRED combo=1)
SpellInfo(SAVAGEROAR combo=-5)
SpellInfo(RIP combo=-5 duration=12)
SpellInfo(FEROCIOUSBITE combo=-5)
SpellInfo(RIP glyph=GLYPHOFSHRED addduration=6)
SpellInfo(RIP glyph=GLYPHOFRIP addduration=4)

AddIcon help=main
{
	if Stance(1) # bear
	{
		Spell(MANGLEBEAR)
		
		if Mana(more 10) and TargetDebuffExpires(LACERATE 4 stacks=5)
			Spell(LACERATE)

		if CheckBoxOn(lucioles) and TargetDebuffExpires(FAERIEFERAL 2)
			Spell(FAERIEFERAL)

		if CheckBoxOn(demo) and TargetDebuffExpires(DEMOROAR 2)
			Spell(DEMOROAR)

		if CheckBoxOn(multi)
			Spell(SWIPE)    
	}

	if Stance(3) # cat
	{
		if ComboPoints(more 0) and BuffExpires(SAVAGEROAR 2) Spell(SAVAGEROAR)
	
		if CheckBoxOn(lucioles) and	TargetDebuffExpires(FAERIEFERAL 2) and TargetDeadIn(more 15)
			Spell(FAERIEFERAL)
		
		unless BuffPresent(BERSERK) if Mana(less 40) Spell(TIGERSFURY)
			
		if ComboPoints(more 0) and BuffExpires(SAVAGEROAR 1) Spell(SAVAGEROAR)
		
		if ComboPoints(more 4)
		{
			if BuffExpires(SAVAGEROAR 6) and Mana(more 70) and TargetDebuffPresent(RIP 5 mine=1) Spell(SAVAGEROAR)
			if TargetDebuffExpires(RIP 0 mine=1) and TargetDeadIn(more 6) Spell(RIP)
		
			if Mana(more 34)
			{
				unless BuffPresent(BERSERK) and {BuffExpires(SAVAGEROAR 8) or TargetDebuffExpires(RIP 10 mine=1)}
					Spell(FEROCIOUSBITE)
				if TargetDeadIn(less 7)
					Spell(FEROCIOUSBITE)
			}
		}
		
		if TargetDebuffExpires(MANGLECAT 0) and TargetDebuffExpires(MANGLEBEAR 0) and TargetDebuffExpires(TRAUMA 0) and CheckBoxOn(mangle)
			Spell(MANGLECAT)
		if TargetDebuffExpires(RAKE 0 mine=1) and Mana(more 34) and TargetDeadIn(more 10)
			Spell(RAKE)
	
		if CheckBoxOn(shred)
		{
			if Mana(more 69) or BuffPresent(CLEARCASTING) or TargetDeadIn(less 10) or BuffPresent(BERSERK) 
					Spell(SHRED)
			if ComboPoints(less 5) and TargetDebuffExpires(RIP 3 mine=1) Spell(SHRED)
		}
	}

	unless Stance(1) or Stance(3)
	{
		if CheckBoxOn(lucioles) and TargetDebuffExpires(FAERIEFIRE 2) and TargetDeadIn(more 15)
			Spell(FAERIEFIRE)

		if TargetDebuffExpires(INSECTSWARM 0 mine=1) and TargetDeadIn(more 6)
			Spell(INSECTSWARM)  
		if TargetDebuffExpires(MOONFIRE 0 mine=1) and TargetDeadIn(more 6)
			Spell(MOONFIRE)

		if BuffPresent(ECLIPSEWRATH)
			Spell(WRATH)
		if BuffPresent(ECLIPSESTARFIRE)
			Spell(STARFIRE)

		if CheckBoxOff(wrath)
		{
			if BuffGain(ECLIPSEWRATH 30) Spell(STARFIRE)
			Spell(WRATH)
		}
		if CheckBoxOn(wrath)
		{
			if BuffGain(ECLIPSESTARFIRE 30) Spell(WRATH)
			Spell(STARFIRE)
		}
	}
}

AddIcon help=offgcd
{
  if Stance(1)
  {  
       Spell(MAUL)
  }
}

AddIcon help=cd
{
	unless Stance(1) or Stance(3) Spell(STARFALL)
	Spell(FORCEOFNATURE)
	Spell(BERSERK)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

]]
