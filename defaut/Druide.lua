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

AddCheckBox(multi L(AOE))
AddCheckBox(mangle SpellName(MANGLECAT))
AddCheckBox(demo SpellName(DEMOROAR))
AddCheckBox(lucioles SpellName(FAERIEFIRE))
AddCheckBox(wrath SpellName(WRATH))

ScoreSpells(FAERIEFERAL DEMOROAR MANGLEBEAR LACERATE SAVAGEROAR RIP 
		TIGERSFURY MANGLECAT RAKE SHRED FEROCIOUSBITE INSECTSWARM MOONFIRE
		WRATH STARFIRE)
		
SpellInfo(MAUL toggle=1)

AddIcon
{
	if Stance(1) # bear
	{
		if CheckBoxOn(lucioles) and TargetDebuffExpires(FAERIEFERAL 2)
			Spell(FAERIEFERAL)

		if CheckBoxOn(demo) and TargetDebuffExpires(DEMOROAR 2)
			Spell(DEMOROAR)

		Spell(MANGLEBEAR)

		if Mana(more 10) and TargetDebuffExpires(LACERATE 4 stacks=5)
			Spell(LACERATE)

		if CheckBoxOn(multi)
			Spell(SWIPE)    
	}

	if Stance(3) # cat
	{
		if ComboPoints(more 0) and BuffExpires(SAVAGEROAR 2) Spell(SAVAGEROAR)
	
		if CheckBoxOn(lucioles) and	TargetDebuffExpires(FAERIEFERAL 2)
			Spell(FAERIEFERAL)
		
		if ComboPoints(more 4) and Mana(more 70)
		{
			if BuffExpires(SAVAGEROAR 5) Spell(SAVAGEROAR)
			if TargetDebuffExpires(RIP 0 mine=1) Spell(RIP)
		}    
		
		if {3s between BuffExpires(SAVAGEROAR 0) and TargetDebuffExpires(RIP 0)} and ComboPoints(more 2)
			Spell(SAVAGEROAR)
		
		if ComboPoints(less 5)
		{
			if Mana(less 30) Spell(TIGERSFURY)
			if TargetDebuffExpires(MANGLECAT 0 mine=1) and CheckBoxOn(mangle)
				Spell(MANGLECAT)
			if TargetDebuffExpires(RAKE 0 mine=1) 
				Spell(RAKE)
			Spell(SHRED)
		}

		if BuffPresent(CLEARCASTING) Spell(SHRED)
		
		if ComboPoints(more 4) and BuffPresent(SAVAGEROAR 8) and TargetDebuffPresent(RIP 8 mine=1)
			Spell(FEROCIOUSBITE)
	}

	unless Stance(1) or Stance(3)
	{
		if CheckBoxOn(lucioles) and TargetDebuffExpires(FAERIEFIRE 2)
			Spell(FAERIEFIRE)

		if TargetDebuffExpires(INSECTSWARM 0 mine=1)
			Spell(INSECTSWARM)  
		if TargetDebuffExpires(MOONFIRE 0 mine=1)
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

AddIcon
{
  if Stance(1)
  {  
       Spell(MAUL)
  }
}

AddIcon
{
	unless Stance(1) or Stance(3) Spell(STARFALL)
	Spell(FORCEOFNATURE)
	Spell(BERSERK)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

]]
