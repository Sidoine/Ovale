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
Define(DEATHANDDECAY 43265)
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
	SpellAddBuff(HOWLINGBLAST FREEZINGFOG=0)
	SpellAddTargetDebuff(HOWLINGBLAST FROSTFEVER=15 glyph=GLYPHHOWLINGBLAST)
Define(ICEBOUNDFORTITUDE 48792)
	SpellAddBuff(ICEBOUNDFORTITUDE ICEBOUNDFORTITUDE=18)
Define(ICYTOUCH 45477)
	SpellInfo(ICYTOUCH frost=-1)
	SpellAddTargetDebuff(ICYTOUCH FROSTFEVER=15)
	SpellAddBuff(ICYTOUCH FREEZINGFOG=0)
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
Define(FREEZINGFOG 59052)
Define(FROSTFEVER 55095)
	SpellInfo(FROSTFEVER duration=15)
Define(KILLINGMACHINE 51124)
Define(SHADOWINFUSION 91342)
Define(SUDDENDOOM 81340)
Define(RUNICCORRUPTION 51459)

AddCheckBox(horn SpellName(HORNOFWINTER))
AddCheckBox(scarlet SpellName(SCARLETFEVER) mastery=1 default)
AddCheckBox(dnd SpellName(DEATHANDDECAY) mastery=3 default)

ScoreSpells(HOWLINGBLAST HEARTSTRIKE BLOODSTRIKE DEATHSTRIKE SCOURGESTRIKE OBLITERATE HEARTSTRIKE 
				PESTILENCE ICYTOUCH PLAGUESTRIKE FROSTSTRIKE DEATHCOIL)

AddIcon help=main mastery=1
{

	if BuffExpires(strengthagility 2) and CheckBoxOn(horn) Spell(HORNOFWINTER)
	if TargetDebuffExpires(lowerphysicaldamage) and CheckBoxOn(scarlet) and TargetClassification(worldboss)
		if Runes(blood 1) or BuffPresent(BLOODSWARM) Spell(BLOODBOIL)
	if TargetDebuffExpires(BLOODPLAGUE 0 mine=1) and TargetDebuffExpires(FROSTFEVER 0 mine=1) Spell(OUTBREAK)
	Spell(RUNESTRIKE usable=1)
	Spell(DANCINGRUNEWEAPON usable=1)
	
	if Runes(unholy 1 frost 1) and {BuffExpires(BLOODSHIELD) or TargetTargetIsPlayer(no)} Spell(DEATHSTRIKE)
	if Runes(blood 1) Spell(HEARTSTRIKE)
	
	if Mana(more 39) Spell(DEATHCOIL usable=1)
	unless Runes(blood 1) Spell(BLOODTAP usable=1 priority=2)
	if CheckBoxOn(horn) Spell(HORNOFWINTER priority=2)
}

AddIcon help=aoe mastery=1
{
	if BuffExpires(strengthagility 2) and CheckBoxOn(horn) Spell(HORNOFWINTER)

	if Runes(unholy 1) Spell(DEATHANDDECAY usable=1)
	
	if TargetDebuffExpires(BLOODPLAGUE 0 mine=1) and TargetDebuffExpires(FROSTFEVER 0 mine=1) Spell(OUTBREAK)
	if TargetDebuffExpires(FROSTFEVER 0 mine=1) and Runes(frost 1) Spell(ICYTOUCH)
	if TargetDebuffExpires(BLOODPLAGUE 0 mine=1) and Runes(unholy 1) Spell(PLAGUESTRIKE)

	if {OtherDebuffPresent(BLOODPLAGUE) or OtherDebuffPresent(FROSTFEVER)} and {TargetDebuffPresent(BLOODPLAGUE) or TargetDebuffPresent(FROSTFEVER)}
		if Runes(blood 1) or BuffPresent(BLOODSWARM) Spell(BLOODBOIL usable=1)
	if TargetDebuffPresent(BLOODPLAGUE) and TargetDebuffPresent(FROSTFEVER) 
	{
		if Runes(blood 1)
			unless OtherDebuffPresent(BLOODPLAGUE) and OtherDebuffPresent(FROSTFEVER)
				Spell(PESTILENCE usable=1)
		Spell(RUNESTRIKE usable=1)
		if Runes(unholy 1 frost 1) Spell(DEATHSTRIKE)
		if Runes(blood 1) Spell(HEARTSTRIKE)
	}
	Spell(RUNESTRIKE usable=1)
	if Mana(more 39) Spell(DEATHCOIL usable=1)
}

AddIcon help=cd mastery=1
{
	unless BuffPresent(BONESHIELD) Spell(BONESHIELD)
	unless TotemPresent(ghoul) Spell(RAISEDEAD)
	if TotemPresent(ghoul) and LifePercent(less 61) and Mana(more 39) Spell(DEATHPACT) 
	Spell(VAMPIRICBLOOD)
	Spell(RUNETAP)
	Spell(UNBREAKABLEARMOR)
	Spell(ICEBOUNDFORTITUDE)
}

AddIcon help=main mastery=2
{	
	if BuffExpires(strengthagility 2) and CheckBoxOn(horn) Spell(HORNOFWINTER)
	
	#/outbreak,if=dot.frost_fever.remains<=2|dot.blood_plague.remains<=2
	if TargetDebuffExpires(BLOODPLAGUE 2 mine=1) and TargetDebuffExpires(FROSTFEVER 2 mine=1) Spell(OUTBREAK)
	#/howling_blast,if=dot.frost_fever.remains<=2
	if TargetDebuffExpires(FROSTFEVER 2 mine=1) and Runes(frost 1)
	{
		#/howling_blast,if=dot.frost_fever.remains<=2
		if Glyph(GLYPHHOWLINGBLAST) Spell(HOWLINGBLAST)
		unless Glyph(GLYPHHOWLINGBLAST) Spell(ICYTOUCH)
	}
	
	#/plague_strike,if=dot.blood_plague.remains<=2
	if TargetDebuffExpires(BLOODPLAGUE 2 mine=1) and Runes(unholy 1) Spell(PLAGUESTRIKE)
	#/obliterate,if=frost=2&unholy=2
	#/obliterate,if=death=2
	if Runes(unholy 2 frost 2 nodeath=1) or Runes(death 2) Spell(OBLITERATE)
	#/obliterate,if=buff.killing_machine.react
	if BuffPresent(KILLINGMACHINE) and Runes(unholy 1 frost 1) Spell(OBLITERATE)
	#/blood_tap
	unless Runes(frost 1 unholy 1) Spell(BLOODTAP priority=2)
	#/blood_strike,if=blood=2
	if Runes(blood 2) Spell(BLOODSTRIKE)
	#/frost_strike,if=runic_power>=90
	if Mana(more 89) Spell(FROSTSTRIKE)
	#/howling_blast,if=buff.rime.react
	if BuffPresent(FREEZINGFOG) Spell(HOWLINGBLAST)
	#/obliterate
	if Runes(unholy 1 frost 1) Spell(OBLITERATE)
	#/blood_strike
	if Runes(blood 1) Spell(BLOODSTRIKE)
	#/frost_strike
	Spell(FROSTSTRIKE usable=1)
	#/empower_rune_weapon
	Spell(EMPOWERRUNEWEAPON priority=2)
	#/horn_of_winter
	if CheckBoxOn(horn) Spell(HORNOFWINTER priority=2)
}

AddIcon help=aoe mastery=2
{
	if Runes(unholy 1 frost 1) Spell(HOWLINGBLAST)
	if Runes(unholy 1) Spell(DEATHANDDECAY usable=1)
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

AddIcon help=cd mastery=2
{
	#/pillar_of_frost
	if Runes(frost 1) Spell(PILLAROFFROST)
	#/raise_dead,time>=15
	unless TotemPresent(ghoul) if TimeInCombat(more 15) Spell(RAISEDEAD priority=2)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

#Contributed by vitos
AddIcon help=main mastery=3
{
	if BuffExpires(strengthagility 2) and CheckBoxOn(horn) Spell(HORNOFWINTER)
	#/outbreak,if=dot.frost_fever.remains<=2|dot.blood_plague.remains<=2
	if TargetDebuffExpires(BLOODPLAGUE é mine=1) and TargetDebuffExpires(FROSTFEVER 2 mine=1) Spell(OUTBREAK)
	#/icy_touch,if=dot.frost_fever.remains<3
	if TargetDebuffExpires(FROSTFEVER 3 mine=1) and Runes(frost 1) Spell(ICYTOUCH)
	#/plague_strike,if=dot.blood_plague.remains<3
	if TargetDebuffExpires(BLOODPLAGUE 3 mine=1) and Runes(unholy 1) Spell(PLAGUESTRIKE)
	#/dark_transformation
	if Runes(unholy 1) and pet.BuffPresent(SHADOWINFUSION stacks=5) Spell(DARKTRANSFORMATION)
	#/death_and_decay,if=death=4
	#/death_and_decay,if=unholy=2
	if Runes(death 4) or Runes(unholy 2) if CheckBoxOn(dnd) Spell(DEATHANDDECAY)
	#/scourge_strike,if=death=4
    #/scourge_strike,if=unholy=2	
	if Runes(death 4) or Runes(unholy 2) Spell(SCOURGESTRIKE)
	#/festering_strike,if=blood=2&frost=2
	if Runes(blood 2 frost 2 nodeath=1) Spell(FESTERINGSTRIKE)
	unless BuffPresent(RUNICCORRUPTION mine=1)
	{
		#/death_coil,if=runic_power>90
		if Mana(more 90) Spell(DEATHCOIL usable=1)
		#/death_coil,if=buff.sudden_doom.react
		if BuffPresent(SUDDENDOOM) Spell(DEATHCOIL usable=1)
	}        
	#/death_and_decay
	if Runes(unholy 1) and CheckBoxOn(dnd) Spell(DEATHANDDECAY)
	#/scourge_strike
	if Runes(unholy 1) Spell(SCOURGESTRIKE)
	#/festering_strike
	if Runes(blood 1 frost 1 nodeath=1) Spell(FESTERINGSTRIKE)
	#/death_coil
	if Mana(more 54) Spell(DEATHCOIL usable=1)
	#/blood_tap,if=unholy=0&inactive_death=1
	unless Runes(unholy 1) Spell(BLOODTAP priority=2)
	#/empower_rune_weapon,if=unholy=0
	unless Runes(unholy 1) Spell(EMPOWERRUNEWEAPON priority=2)
	#/horn_of_winter
	Spell(HORNOFWINTER)
}

AddIcon help=aoe mastery=3
{
	if Runes(unholy 1) Spell(DEATHANDDECAY usable=1)
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

AddIcon help=cd mastery=3
{
	if PetPresent(no) Spell(RAISEDEAD)
	Spell(SUMMONGARGOYLE)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
	Spell(ARMYOFTHEDEAD)
}

]]