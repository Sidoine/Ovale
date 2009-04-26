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
Define(PESTILENCE 50842)
Define(ICYTOUCH 45477)
Define(PLAGUESTRIKE 45462)
Define(HEARTSTRIKE 55050)
Define(DEATHSTRIKE 49998)
Define(TALENTDEATSTRIKE 2259)
Define(TALENTFROSTSTRIKE 1975)
Define(TALENTHEARTSTRIKE 1957)
Define(TALENTBLOODYSTRIKES 2015)
Define(SCOURGESTRIKE 55090)
Define(DEATHCOIL 52375)
Define(ARMYOFTHEDEAD 42650)
Define(DANCINGRUNEWEAPON 49028)
Define(FROSTSTRIKE 49143)
Define(HYSTERIA 49016)
Define(SUMMONGARGOYLE 49206)

AddIcon
{
	if Runes(unholy 1) and Runes(frost 1) Spell(HOWLINGBLAST)
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
		if Runes(unholy 1) and Runes(frost 1)
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
	if TargetDebuffExpires(FROSTFEVER 0 mine=1) and Runes(frost 1)
		Spell(ICYTOUCH)
	if TargetDebuffExpires(BLOODPLAGUE 0 mine=1) and Runes(unholy 1)
		Spell(PLAGUESTRIKE)
	Spell(FROSTSTRIKE usable=1)
	Spell(DEATHCOIL usable=1)
}

AddIcon
{
	if TargetDebuffPresent(BLOODPLAGUE) or TargetDebuffPresent(FROSTFEVER)
		Spell(PESTILENCE usable=1)
	Spell(DEATHANDECAY usable=1)
	Spell(BLOODBOIL usable=1)
}

AddIcon size=small
{
	if BuffPresent(FROSTPRESENCE)
	{
		Spell(RUNESTRIKE usable=1)
	}
}

AddIcon size=small
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
		Spell(DANCINGRUNEWEAPON)
	}
	Spell(ARMYOFTHEDEAD)
}

]]