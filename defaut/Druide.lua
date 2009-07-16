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

AddCheckBox(multi L(AOE))
AddCheckBox(blood L(Blood))
AddCheckBox(demo SpellName(DEMOROAR))
AddCheckBox(lucioles SpellName(FAERIEFIRE))
AddCheckBox(wrath SpellName(WRATH))

AddIcon
{
	if Stance(1) # bear
	{
		if CheckBoxOn(lucioles) and TargetDebuffExpires(FAERIEFERAL 2)
			Spell(FAERIEFERAL)

		if CheckBoxOn(demo) and TargetDebuffExpires(DEMOROAR 2)
			Spell(DEMOROAR)

		Spell(MANGLEBEAR)

		if CheckBoxOn(blood) and Mana(more 10) and TargetDebuffExpires(LACERATE 4 stacks=5)
			Spell(LACERATE)

		if CheckBoxOn(multi)
			Spell(SWIPE)    
	}

	if Stance(3) # cat
	{
		if ComboPoints(more 0) and BuffExpires(SAVAGEROAR 2) Spell(SAVAGEROAR)
	
		if CheckBoxOn(lucioles) and	TargetDebuffExpires(FAERIEFERAL 2)
			Spell(FAERIEFERAL)

    	if TargetDebuffExpires(RAKE 0) Spell(RAKE)
	
		if ComboPoints(more 4) and Mana(more 70)
		{
			if BuffExpires(SAVAGEROAR 5) Spell(SAVAGEROAR)
			if TargetDebuffExpires(RIP 0) Spell(RIP)
			Spell(FEROCIOUSBITE)
		}
    
		if ComboPoints(less 5)
		{
			if Mana(less 40) Spell(TIGERSFURY)
			if TargetDebuffExpires(MANGLECAT 0)
				Spell(MANGLECAT)
			Spell(SHRED)
		}
	}

	unless Stance(1) or Stance(3)
	{
		if CheckBoxOn(lucioles) and TargetDebuffExpires(FAERIEFIRE 2)
			Spell(FAERIEFIRE)

		if TargetDebuffExpires(INSECTSWARM 0)
			Spell(INSECTSWARM)  
		if TargetDebuffExpires(MOONFIRE 0)
			Spell(MOONFIRE)

		if CheckBoxOff(wrath)
		{
			if BuffPresent(ECLIPSEWRATH)
				Spell(WRATH)
			Spell(STARFIRE)
		}
		if CheckBoxOn(wrath)
		{
			if BuffPresent(ECLIPSESTARFIRE)
				Spell(STARFIRE)
			Spell(WRATH)
		}
	}
}

AddIcon
{
  if Stance(1)
  {  
       Spell(MAUL doNotRepeat=1)
  }
}

AddIcon
{
	Spell(FORCEOFNATURE)
	Spell(BERSERK)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

]]
