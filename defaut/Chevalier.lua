Ovale.defaut["DEATHKNIGHT"] = [[
#Abilities
Define(ARMYOFTHEDEAD 42650)
	SpellInfo(ARMYOFTHEDEAD cd=600)
Define(BLOODBOIL 48721)
	SpellAddTargetDebuff(BLOODBOIL SCARLETFEVER=30)
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
Define(DEATHPACT 48743)
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
Define(GLYPHHOWLINGBLAST 63335)

#Buffs and debuffs
Define(BLOODSHIELD 77535)
Define(BLOODSWARM 81141)
Define(SCARLETFEVER 81130)
Define(BLOODPLAGUE 55078)
	SpellInfo(BLOODPLAGUE duration=15)
Define(FROSTFEVER 55095)
	SpellInfo(FROSTFEVER duration=15)
Define(KILLINGMACHINE 51124)
Define(SHADOWINFUSION 91342)
Define(SUDDENDOOM 81340)

AddCheckBox(horn SpellName(HORNOFWINTER))
AddCheckBox(scarlet SpellName(SCARLETFEVER) mastery=1 default)

ScoreSpells(HOWLINGBLAST HEARTSTRIKE BLOODSTRIKE DEATHSTRIKE SCOURGESTRIKE OBLITERATE HEARTSTRIKE 
				PESTILENCE ICYTOUCH PLAGUESTRIKE FROSTSTRIKE DEATHCOIL)

AddIcon help=main mastery=1
{
	Spell(DANCINGRUNEWEAPON usable=1)

	if BuffExpires(strengthagility 2) and CheckBoxOn(horn) Spell(HORNOFWINTER)
	if TargetDebuffExpires(lowerphysicaldamage) and CheckBoxOn(scarlet) and TargetClassification(worldboss)
		if Runes(blood 1) or BuffPresent(BLOODSWARM) Spell(BLOODBOIL)
	Spell(RUNESTRIKE usable=1)
	
	if Runes(unholy 1 frost 1) and {BuffExpires(BLOODSHIELD) or TargetTargetIsPlayer(no)} Spell(DEATHSTRIKE)
	if Runes(blood 1) Spell(HEARTSTRIKE)
	
	if Mana(more 39) Spell(DEATHCOIL usable=1)
	unless Runes(blood 1) Spell(BLOODTAP usable=1 priority=2)
	if CheckBoxOn(horn) Spell(HORNOFWINTER priority=2)
}

AddIcon help=aoe mastery=1
{
	if BuffExpires(strengthagility 2) and CheckBoxOn(horn) Spell(HORNOFWINTER)
	Spell(RUNESTRIKE usable=1)

	if Runes(unholy 1) Spell(DEATHANDECAY usable=1)
	
	if TargetDebuffExpires(FROSTFEVER 0 mine=1) and Runes(frost 1) Spell(ICYTOUCH)
	if TargetDebuffExpires(BLOODPLAGUE 0 mine=1) and Runes(unholy 1) Spell(PLAGUESTRIKE)

	if {OtherDebuffPresent(BLOODPLAGUE) or OtherDebuffPresent(FROSTFEVER)} and {TargetDebuffPresent(BLOODPLAGUE) or TargetDebuffPresent(FROSTFEVER)}
		if Runes(blood 1) or BuffPresent(BLOODSWARM) Spell(BLOODBOIL usable=1)
	if TargetDebuffPresent(BLOODPLAGUE) and TargetDebuffPresent(FROSTFEVER) 
	{
		if Runes(blood 1)
			unless OtherDebuffPresent(BLOODPLAGUE) and OtherDebuffPresent(FROSTFEVER)
				Spell(PESTILENCE usable=1)
		if Runes(unholy 1 frost 1) Spell(DEATHSTRIKE)
		if Runes(blood 1) Spell(HEARTSTRIKE)
	}
	
	if Mana(more 39) Spell(DEATHCOIL usable=1)
}

AddIcon help=main mastery=2
{	
	if BuffExpires(strengthagility 2) and CheckBoxOn(horn) Spell(HORNOFWINTER)
	
	if BuffPresent(KILLINGMACHINE) Spell(FROSTSTRIKE usable=1)

	if TargetDebuffPresent(FROSTFEVER mine=1) and TargetDebuffPresent(BLOODPLAGUE mine=1)
	{
        if Runes(unholy 1 frost 1 nodeath=1) Spell(OBLITERATE)
		if Runes(blood 1) Spell(BLOODSTRIKE)
	}
	
	if TargetDebuffExpires(FROSTFEVER 0 mine=1) and Runes(frost 1)
	{
		if Glyph(GLYPHHOWLINGBLAST) Spell(HOWLINGBLAST)
		unless Glyph(GLYPHHOWLINGBLAST) Spell(ICYTOUCH)
	}
	if TargetDebuffExpires(BLOODPLAGUE 0 mine=1) and Runes(unholy 1) Spell(PLAGUESTRIKE)
	Spell(FROSTSTRIKE usable=1)
	if PetPresent(no) Spell(RAISEDEAD)
	if CheckBoxOn(horn) Spell(HORNOFWINTER priority=2)
	unless Runes(frost 1 unholy 1) Spell(BLOODTAP)
	if Runes(blood 2 nodeath=1)
	{
		Spell(HEARTSTRIKE priority=2)
		Spell(BLOODSTRIKE priority=2)
	}
}

AddIcon help=aoe mastery=2
{
	if Runes(unholy 1 frost 1) Spell(HOWLINGBLAST)
	if Runes(unholy 1) Spell(DEATHANDECAY usable=1)
	if Runes(blood 1)
	{
		if TargetDebuffPresent(BLOODPLAGUE) and TargetDebuffPresent(FROSTFEVER)
			unless OtherDebuffPresent(BLOODPLAGUE) and OtherDebuffPresent(FROSTFEVER)
				Spell(PESTILENCE usable=1)
		if {TargetDebuffPresent(BLOODPLAGUE) or TargetDebuffPresent(FROSTFEVER)} 
				and {OtherDebuffPresent(BLOODPLAGUE) or OtherDebuffPresent(FROSTFEVER)}
			Spell(BLOODBOIL usable=1)
	}
}

AddIcon help=main mastery=3
{
	if BuffExpires(strengthagility 2) and CheckBoxOn(horn) Spell(HORNOFWINTER)
	if PetPresent(no) Spell(RAISEDEAD)
	
	if TargetDebuffPresent(FROSTFEVER mine=1) and TargetDebuffPresent(BLOODPLAGUE mine=1)
	{
		if Runes(unholy 1) and TargetBuffPresent(SHADOWINFUSION stacks=5 target=pet) Spell(DARKTRANSFORMATION)
		if BuffPresent(SUDDENDOOM mine=1) Spell(DEATHCOIL usable=1)
		if Mana(more 90) Spell(DEATHCOIL usable=1)
		if Runes(unholy 1) Spell(SCOURGESTRIKE)
        if Runes(blood 1 frost 1 nodeath=1) Spell(FESTERINGSTRIKE)
	}
	if TargetDebuffExpires(FROSTFEVER 0 mine=1) and Runes(frost 1) Spell(ICYTOUCH)
	if TargetDebuffExpires(BLOODPLAGUE 0 mine=1) and Runes(unholy 1) Spell(PLAGUESTRIKE)
	
	if Mana(more 34) Spell(DEATHCOIL usable=1)
	
	if CheckBoxOn(horn) Spell(HORNOFWINTER priority=2)
}

AddIcon help=aoe mastery=3
{
	if Runes(unholy 1) Spell(DEATHANDECAY usable=1)
	if Runes(blood 1)
	{
		if TargetDebuffPresent(BLOODPLAGUE) and TargetDebuffPresent(FROSTFEVER)
			unless OtherDebuffPresent(BLOODPLAGUE) and OtherDebuffPresent(FROSTFEVER)
				Spell(PESTILENCE usable=1)
		if {TargetDebuffPresent(BLOODPLAGUE) or TargetDebuffPresent(FROSTFEVER)} 
				and {OtherDebuffPresent(BLOODPLAGUE) or OtherDebuffPresent(FROSTFEVER)}
			Spell(BLOODBOIL usable=1)
	}
}

AddIcon help=cd
{
	unless BuffPresent(BONESHIELD) Spell(BONESHIELD)
	if BuffPresent(BLOODPRESENCE)
	{
		if TotemPresent(ghoul) and LifePercent(less 61) and Mana(more 39) Spell(DEATHPACT) 
		Spell(VAMPIRICBLOOD)
		Spell(RUNETAP)
		Spell(UNBREAKABLEARMOR)
		Spell(ICEBOUNDFORTITUDE)
	}
	if PetPresent(no) Spell(RAISEDEAD)
	Spell(SUMMONGARGOYLE)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
	Spell(ARMYOFTHEDEAD)
}

]]