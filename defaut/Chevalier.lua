Ovale.defaut["DEATHKNIGHT"] = [[
#Abilities
Define(ARMYOFTHEDEAD 42650)
	SpellInfo(ARMYOFTHEDEAD cd=600)
Define(BLOODBOIL 48721)
Define(BLOODPRESENCE 48263)
Define(BLOODSTRIKE 45902)
	SpellInfo(BLOODSTRIKE blood=-1)
Define(BLOODTAP 45529)
Define(BONESHIELD 49222) #blood
	SpellAddBuff(BONESHIELD BONESHIELD=300)
Define(DANCINGRUNEWEAPON 49028) #blood
Define(DARKTRANSFORMATION 63560) #unholy
Define(DEATHANDECAY 43265)
Define(DEATHCOIL 47541)
Define(DEATHSTRIKE 49998)
	SpellInfo(DEATHSTRIKE unholy=-1 frost=-1)
Define(EMPOWERRUNEWEAPON 47568)
Define(FESTERINGSTRIKE 85948) #1 frost 1 blood
Define(FROSTPRESENCE 48266)
Define(FROSTSTRIKE 49143) #frost
	SpellInfo(FROSTSTRIKE mana=40)
Define(HEARTSTRIKE 55050) #blood
	SpellInfo(HEARTSTRIKE blood=-1)
Define(HORNOFWINTER 57330)
	SpellInfo(HORNOFWINTER cd=20)
Define(HOWLINGBLAST 49184) #frost
	SpellInfo(HOWLINGBLAST frost=-1 cd=8)
	SpellAddTargetDebuff(HOWLINGBLAST FROSTFEVER=15 glyph=GLYPHHOWLINGBLAST)
Define(ICEBOUNDFORTITUDE 48792)
	SpellAddBuff(ICEBOUNDFORTITUDE ICEBOUNDFORTITUDE=18)
Define(ICYTOUCH 45477)
	SpellInfo(ICYTOUCH frost=-1)
	SpellAddTargetDebuff(ICYTOUCH FROSTFEVER=15)
Define(OBLITERATE 49020)
	SpellInfo(OBLITERATE unholy=-1 frost=-1)
Define(OUTBREAK 77575)
Define(PESTILENCE 50842)
Define(PILLAROFFROST 51271) #frost
Define(PLAGUESTRIKE 45462)
	SpellInfo(PLAGUESTRIKE unholy=-1)
	SpellAddTargetDebuff(PLAGUESTRIKE BLOODPLAGUE=15)
Define(RAISEDEAD 46584)
Define(RUNESTRIKE 56815)
	SpellInfo(RUNESTRIKE mana=20)
Define(RUNETAP 48982) #blood
	SpellInfo(RUNETAP blood=-1)
Define(SCOURGESTRIKE 55090) #unholy
	SpellInfo(SCOURGESTRIKE unholy=-1)
Define(SUMMONGARGOYLE 49206) #unholy
	SpellInfo(SUMMONGARGOYLE cd=180)
Define(UNHOLYBLIGHT 49194)
Define(UNHOLYFRENZY 49016)
	SpellInfo(UNHOLYFRENZY cd=300)
Define(UNHOLYPRESENCE 48265)
Define(VAMPIRICBLOOD 55233) #blood
	SpellInfo(VAMPIRICBLOOD blood=-1)

#Talents
#Define(TALENTDEATSTRIKE 2259)
#Define(TALENTFROSTSTRIKE 1975)
#Define(TALENTHEARTSTRIKE 1957)
#Define(TALENTBLOODYSTRIKES 2015)

#Glyphs
Define(GLYPHDISEASE 63334)
Define(GLYPHHOWLINGBLAST 63335)


#Buffs and debuffs
Define(BLOODPLAGUE 59879)
Define(FROSTFEVER 59921)
Define(KILLINGMACHINE 51124)

AddCheckBox(rolldes SpellName(GLYPHDISEASE) default glyph=GLYPHDISEASE)

ScoreSpells(HOWLINGBLAST HEARTSTRIKE BLOODSTRIKE DEATHSTRIKE SCOURGESTRIKE OBLITERATE HEARTSTRIKE 
				PESTILENCE ICYTOUCH PLAGUESTRIKE FROSTSTRIKE DEATHCOIL)

AddIcon help=main mastery=1
{
	Spell(DANCINGRUNEWEAPON usable=1)

	if BuffExpires(strengthagility 2) Spell(HORNOFWINTER)
	
	if CheckBoxOn(rolldes) and Glyph(GLYPHDISEASE) 
		and TargetDebuffPresent(FROSTFEVER mine=1) and TargetDebuffPresent(BLOODPLAGUE mine=1) and
		{TargetDebuffExpires(FROSTFEVER 3 mine=1) or TargetDebuffExpires(BLOODPLAGUE 3 mine=1)}
			Spell(PESTILENCE)
			
	if TargetDebuffPresent(FROSTFEVER mine=1) and TargetDebuffPresent(BLOODPLAGUE mine=1)
	{
		if Runes(blood 1) and {CheckBoxOff(rolldes) or Runes(blood 2)} Spell(HEARTSTRIKE)
		if Runes(unholy 1 nodeath=1) and Runes(frost 1 nodeath=1) Spell(DEATHSTRIKE)
	}

	if TargetDebuffExpires(FROSTFEVER 0 mine=1) and Runes(frost 1) Spell(ICYTOUCH)
	if TargetDebuffExpires(BLOODPLAGUE 0 mine=1) and Runes(unholy 1) Spell(PLAGUESTRIKE)
	
	if PetPresent(no) Spell(RAISEDEAD)
	Spell(RUNESTRIKE usable=1)
	if Mana(more 39) Spell(DEATHCOIL usable=1)
	Spell(HORNOFWINTER priority=2)
}

AddIcon help=main mastery=2
{	
	if BuffExpires(strengthagility 2) Spell(HORNOFWINTER)
	
	if CheckBoxOn(rolldes) and Glyph(GLYPHDISEASE) 
		and TargetDebuffPresent(FROSTFEVER mine=1) and TargetDebuffPresent(BLOODPLAGUE mine=1) and
		{TargetDebuffExpires(FROSTFEVER 3 mine=1) or TargetDebuffExpires(BLOODPLAGUE 3 mine=1)}
			Spell(PESTILENCE)

	if BuffPresent(KILLINGMACHINE) Spell(FROSTSTRIKE usable=1)

	if TargetDebuffPresent(FROSTFEVER mine=1) and TargetDebuffPresent(BLOODPLAGUE mine=1)
	{
		if Runes(unholy 1 nodeath=1) and Runes(frost 1 nodeath=1) Spell(OBLITERATE)
		if Runes(blood 1) and {CheckBoxOff(rolldes) or Runes(blood 2)} Spell(BLOODSTRIKE)
	}
	
	if TargetDebuffExpires(FROSTFEVER 0 mine=1) and Runes(frost 1)
	{
		if Glyph(GLYPHHOWLINGBLAST) Spell(HOWLINGBLAST)
		unless Glyph(GLYPHHOWLINGBLAST) Spell(ICYTOUCH)
	}
	if TargetDebuffExpires(BLOODPLAGUE 0 mine=1) and Runes(unholy 1) Spell(PLAGUESTRIKE)
	Spell(FROSTSTRIKE usable=1)
	if PetPresent(no) Spell(RAISEDEAD)
	Spell(HORNOFWINTER priority=2)
	unless Runes(frost 1) and Runes(unholy 1) Spell(BLOODTAP)
	if Runes(blood 2 nodeath=1)
	{
		Spell(HEARTSTRIKE priority=2)
		Spell(BLOODSTRIKE priority=2)
	}
}

AddIcon help=main mastery=3
{
	if BuffExpires(strengthagility 2) Spell(HORNOFWINTER)
	
	if CheckBoxOn(rolldes) and Glyph(GLYPHDISEASE) 
		and TargetDebuffPresent(FROSTFEVER mine=1) and TargetDebuffPresent(BLOODPLAGUE mine=1) and
		{TargetDebuffExpires(FROSTFEVER 3 mine=1) or TargetDebuffExpires(BLOODPLAGUE 3 mine=1)}
			Spell(PESTILENCE)

			if TargetDebuffPresent(FROSTFEVER mine=1) and TargetDebuffPresent(BLOODPLAGUE mine=1)
	{
		if Runes(unholy 1) and Runes(frost 1)
			Spell(SCOURGESTRIKE)
		if Runes(unholy 1 nodeath=1) and Runes(frost 1 nodeath=1) Spell(OBLITERATE)
		if Runes(blood 1) and {CheckBoxOff(rolldes) or Runes(blood 2)} Spell(BLOODSTRIKE)
	}
	if TargetDebuffExpires(FROSTFEVER 0 mine=1) and Runes(frost 1) Spell(ICYTOUCH)
	if TargetDebuffExpires(BLOODPLAGUE 0 mine=1) and Runes(unholy 1) Spell(PLAGUESTRIKE)
	
	if PetPresent(no) Spell(RAISEDEAD)
	if Mana(more 39) Spell(DEATHCOIL usable=1)
	
	Spell(HORNOFWINTER priority=2)
	unless Runes(frost 1) and Runes(unholy 1) Spell(BLOODTAP)
	if Runes(blood 2 nodeath=1)
	{
		Spell(HEARTSTRIKE priority=2)
		Spell(BLOODSTRIKE priority=2)
	}
}

AddIcon help=aoe
{
	if Runes(unholy 1) and Runes(frost 1) Spell(HOWLINGBLAST)
	if TargetDebuffPresent(BLOODPLAGUE) or TargetDebuffPresent(FROSTFEVER)
		Spell(PESTILENCE usable=1)
	Spell(DEATHANDECAY usable=1)
	Spell(BLOODBOIL usable=1)
}

AddIcon help=cd
{
	unless BuffPresent(BONESHIELD) Spell(BONESHIELD)
	if BuffPresent(BLOODPRESENCE)
	{
		Spell(VAMPIRICBLOOD)
		Spell(RUNETAP)
		Spell(UNBREAKABLEARMOR)
		Spell(ICEBOUNDFORTITUDE)
	}
	Spell(SUMMONGARGOYLE)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
	Spell(ARMYOFTHEDEAD)
}

]]