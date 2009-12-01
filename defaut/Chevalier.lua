Ovale.defaut["DEATHKNIGHT"] = [[
Define(FROSTPRESENCE 48263)
Define(RUNESTRIKE 56815)
Define(BONESHIELD 49222)
Define(ICEBOUNDFORTITUDE 48792)
Define(UNBREAKABLEARMOR 51271)
Define(DEATHANDECAY 43265)
Define(HOWLINGBLAST 49184)
Define(OBLITERATE 49020)
Define(BLOODSTRIKE 45902)
Define(BLOODBOIL 48721)
Define(BLOODPLAGUE 59879)
Define(FROSTFEVER 59921)
Define(PESTILENCE 50842)a
Define(ICYTOUCH 45477)
Define(PLAGUESTRIKE 45462)
Define(HEARTSTRIKE 55050)
Define(DEATHSTRIKE 49998)
Define(TALENTDEATSTRIKE 2259)
Define(TALENTFROSTSTRIKE 1975)
Define(TALENTHEARTSTRIKE 1957)
Define(TALENTBLOODYSTRIKES 2015)
Define(SCOURGESTRIKE 55090)
Define(DEATHCOIL 47541)
Define(ARMYOFTHEDEAD 42650)
Define(DANCINGRUNEWEAPON 49028)
Define(FROSTSTRIKE 49143)
Define(HYSTERIA 49016)
Define(SUMMONGARGOYLE 49206)
Define(GLYPHDISEASE 63334)
Define(GLYPHHOWLINGBLAST 63961)
Define(ABOMINATIONMIGHT 53136)
Define(TALENTABOMINATIONMIGHT 2105)
Define(RAISEDEAD 46584)
Define(HORNOFWINTER 57330)

AddCheckBox(rolldes SpellName(GLYPHDISEASE))

SpellAddTargetDebuff(ICYTOUCH FROSTFEVER=15)
SpellAddTargetDebuff(PLAGUESTRIKE BLOODPLAGUE=15)
SpellInfo(ICYTOUCH frost=-1 forcecd=DEATHCOIL)
SpellInfo(PLAGUESTRIKE unholy=-1 forcecd=DEATHCOIL)
SpellInfo(DEATHSTRIKE unholy=-1 frost=-1 forcecd=DEATHCOIL)
SpellInfo(HEARTSTRIKE blood=-1 forcecd=DEATHCOIL)
SpellInfo(HOWLINGBLAST frost=-1 cd=8)
SpellInfo(BLOODSTRIKE blood=-1 forcecd=DEATHCOIL)
SpellInfo(SCOURGESTRIKE unholy=-1 frost=-1 forcecd=DEATHCOIL)
SpellInfo(OBLITERATE unholy=-1 frost=-1 forcecd=DEATHCOIL)

ScoreSpells(HOWLINGBLAST HEARTSTRIKE BLOODSTRIKE DEATHSTRIKE SCOURGESTRIKE OBLITERATE HEARTSTRIKE 
				PESTILENCE ICYTOUCH PLAGUESTRIKE FROSTSTRIKE DEATHCOIL RAISEDEAD)

AddIcon help=main
{
	Spell(DANCINGRUNEWEAPON usable=1)

	if BuffExpires(HORNOFWINTER 2) Spell(HORNOFWINTER)
	
	if CheckBoxOn(rolldes) and Glyph(GLYPHDISEASE) 
		and TargetDebuffPresent(FROSTFEVER mine=1) and TargetDebuffPresent(BLOODPLAGUE mine=1) and
		{TargetDebuffExpires(FROSTFEVER 3 mine=1) or TargetDebuffExpires(BLOODPLAGUE 3 mine=1)}
			Spell(PESTILENCE)
	
	if TargetDebuffPresent(FROSTFEVER mine=1) and TargetDebuffPresent(BLOODPLAGUE mine=1)
	{
		if TalentPoints(TALENTBLOODYSTRIKES more 0)
		{
			if Runes(blood 1)
			{	
				Spell(HEARTSTRIKE)
				Spell(BLOODSTRIKE)
			}
		}
		if Runes(unholy 1 nodeath=1) and Runes(frost 1 nodeath=1)
		{
			if TalentPoints(TALENTDEATSTRIKE more 0) Spell(DEATHSTRIKE)
			Spell(SCOURGESTRIKE)
			Spell(OBLITERATE)
			Spell(DEATHSTRIKE)
		}
		if Runes(blood 1)
		{
			Spell(HEARTSTRIKE)
			Spell(BLOODSTRIKE)
		}
	}
	
	if CheckBoxOn(rolldes) and TalentPoints(TALENTABOMINATIONMIGHT more 0) and BuffExpires(ABOMINATIONMIGHT 0)
		Spell(DEATHSTRIKE)
		
	if TargetDebuffExpires(FROSTFEVER 0 mine=1) and Runes(frost 1)
	{
		if Glyph(GLYPHHOWLINGBLAST) Spell(HOWLINGBLAST)
		Spell(ICYTOUCH)
	}
	
	if TargetDebuffExpires(BLOODPLAGUE 0 mine=1) and Runes(unholy 1)
		Spell(PLAGUESTRIKE)
	
	if BuffPresent(FROSTPRESENCE)
		Spell(RUNESTRIKE usable=1)
	
	Spell(FROSTSTRIKE usable=1)
	if PetPresent(no) Spell(RAISEDEAD)
	Spell(DEATHCOIL usable=1)
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
	Spell(BONESHIELD)
	if BuffPresent(FROSTPRESENCE)
	{
		Spell(UNBREAKABLEARMOR)
		Spell(ICEBOUNDFORTITUDE)
	}
	unless BuffPresent(FROSTPRESENCE)
	{
		Spell(SUMMONGARGOYLE)	
		Spell(HYSTERIA)
	}
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
	Spell(ARMYOFTHEDEAD)
}

]]