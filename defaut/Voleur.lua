Ovale.defaut["ROGUE"] =
[[
#Abilities
Define(ADRENALINERUSH 13750)
	SpellInfo(ADRENALINERUSH cd=180)
	SpellAddBuff(ADRENALINERUSH ADRENALINERUSH=15)
Define(BACKSTAB 53)
	SpellInfo(BACKSTAB combo=1)
Define(BLADEFLURRY 13877)
	SpellAddBuff(BLADEFLURRY BLADEFLURRY=15 cd=30)
Define(CLOACKOFSHADOWS 31224)
	SpellInfo(CLOACKOFSHADOWS cd=90)
Define(COLDBLOOD 14177)
	SpellInfo(COLDBLOOD cd=120)
Define(ENVENOM 32645)
	SpellInfo(ENVENOM combo=-5)
Define(EVISCERATE 2098)
	SpellInfo(EVISCERATE combo=-5)
Define(HEMORRHAGE 16511)
	SpellInfo(HEMORRHAGE combo=1)
Define(KILLINGSPREE 51690)
	SpellInfo(KILLINGSPREE cd=120)
	SpellAddBuff(KILLINGSPREE KILLINGSPREE=2)
Define(GARROTE 703)
	SpellAddTargetDebuff(GARROTE GARROTE=18)
Define(MUTILATE 1329)
	SpellInfo(MUTILATE combo=1)
Define(PREPARATION 14185)
	SpellInfo(PREPARATION cd=300)
Define(REVEALINGSTRIKE 84617)
	SpellInfo(REVEALINGSTRIKE combo=1)
	SpellAddTargetDebuff(REVEALINGSTRIKE REVEALINGSTRIKE=15)
Define(RUPTURE 1943)
	SpellInfo(RUPTURE combo=-5)
	SpellAddTargetDebuff(RUPTURE RUPTURE=8)
Define(SINISTERSTRIKE 1752)
	SpellInfo(SINISTERSTRIKE combo=1)
Define(SLICEANDDICE 5171)
	SpellInfo(SLICEANDDICE combo=-5)
	SpellAddBuff(SLICEANDDICE SLICEANDDICE=10)
Define(TRICKSOFTHETRADE 57934)
	SpellInfo(TRICKSOFTHETRADE cd=30)
Define(VENDETTA 79140)
	SpellInfo(VENDETTA cd=120)
	SpellAddTargetDebuff(VENDETTA VENDETTA=30)
	
#Talents
Define(TALENTCUTTOTHECHASE 2070)

ScoreSpells(SLICEANDDICE HUNGERFORBLOOD ENVENOM RUPTURE EVISCERATE MUTILATE SINISTERSTRIKE)

AddIcon help=main mastery=1
{
	unless BuffPresent(SLICEANDDICE) if ComboPoints(more 0)	Spell(SLICEANDDICE)
	if TargetDebuffExpires(VENDETTA) and TargetDeadIn(more 20) Spell(VENDETTA)
	
	if ComboPoints(more 3) and Mana(more 69)
	{
		if BuffExpires(SLICEANDDICE 12) 
		{
			if TalentPoints(TALENTCUTTOTHECHASE more 0)
				Spell(ENVENOM)
			Spell(SLICEANDDICE)
		}
		if TargetDebuffExpires(RUPTURE 0) and TargetDeadIn(more 6)
			Spell(RUPTURE)
		Spell(ENVENOM)
	}
	if ComboPoints(less 4)
	{
		if TargetLifePercent(less 35) Spell(BACKSTAB)
		Spell(MUTILATE)
	}
}

AddIcon help=main mastery=2
{
	unless BuffPresent(SLICEANDDICE) if ComboPoints(more 0)	Spell(SLICEANDDICE)
	
	if TargetDebuffPresent(REVEALINGSTRIKE) and Mana(more 69)
	{
		if BuffExpires(SLICEANDDICE 12) Spell(SLICEANDDICE)
		
		if TargetDebuffExpires(RUPTURE 0) and TargetDeadIn(more 6)
			Spell(RUPTURE)
		Spell(EVISCERATE)
	}
	
	if ComboPoints(more 3) Spell(REVEALINGSTRIKE)	
	if ComboPoints(less 4) Spell(SINISTERSTRIKE)
}

AddIcon help=main mastery=3
{
	unless BuffPresent(SLICEANDDICE) if ComboPoints(more 0)	Spell(SLICEANDDICE)
	
	if ComboPoints(more 4) and Mana(more 69)
	{
		if BuffExpires(SLICEANDDICE 12) Spell(SLICEANDDICE)
		
		if TargetDebuffExpires(RUPTURE 0) and TargetDeadIn(more 6)
			Spell(RUPTURE)
		Spell(EVISCERATE)
	}
	
	if ComboPoints(less 4)
	{
		if TargetDebuffExpires(bleed 0) Spell(HEMORRHAGE)
		Spell(BACKSTAB)
	}
}

AddIcon help=cd
{
	unless BuffPresent(KILLINGSPREE) Spell(ADRENALINERUSH)
	unless BuffPresent(ADRENALINERUSH) Spell(KILLINGSPREE)
	Spell(BLADEFLURRY)
	if Mana(less 70) Spell(COLDBLOOD)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
	Spell(PREPARATION)
}

AddIcon size=small
{
	Spell(TRICKSOFTHETRADE)
}

AddIcon size=small
{
	Spell(CLOACKOFSHADOWS)
}

]]