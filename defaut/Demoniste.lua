Ovale.defaut["WARLOCK"]=
[[
Define(BANEOFAGONY 980)
	SpellAddTargetDebuff(BANEOFAGONY BANEOFAGONY=24)
Define(BANEOFDOOM 603)
	SpellAddTargetDebuff(BANEOFDOOM BANEOFDOOM=60)
Define(BANEOFHAVOC 80240)
Define(CHAOSBOLT 50796)
	SpellInfo(CHAOSBOLT cd=12)
Define(CONFLAGRATE 17962)
	SpellInfo(CONFLAGRATE cd=10)
Define(CORRUPTION 172)
	SpellAddTargetDebuff(CORRUPTION CORRUPTION=18)
Define(CURSEELEMENTS 1490)
	SpellAddTargetDebuff(CURSEELEMENTS CURSEELEMENTS=300)
Define(CURSETONGUES 1714)
Define(CURSEWEAKNESS 702)
Define(DARKINTENT 80398)
Define(DEATHCOIL 6789)
Define(DEMONARMOR 687)
Define(DEMONICEMPOWERMENT 47193)
Define(DEMONSOUL 77801)
Define(DRAINLIFE 689)
Define(DRAINSOUL 1120)
	SpellInfo(DRAINSOUL canStopChannelling=5)
Define(FELARMOR 28176)
Define(FELFLAME 77799)
Define(HANDOFGULDAN 71521)
	SpellInfo(HANDOFGULDAN cd=12)
	SpellAddTargetDebuff(HANDOFGULDAN IMMOLATE=refresh)
Define(HAUNT 48181)
	SpellInfo(HAUNT cd=8)
Define(IMMOLATE 348)
	SpellInfo(IMMOLATE duration=15)
	SpellAddTargetDebuff(IMMOLATE IMMOLATE=15)
	SpellAddBuff(IMMOLATE MOLTENCORE=-1)
Define(INCINERATE 29722)
	SpellAddBuff(INCINERATE MOLTENCORE=-1)
Define(LIFETAP 1454)
Define(METAMORPHOSIS 47241)
Define(SEARINGPAIN 5676)
Define(SEEDOFCORRUPTION 27243)
Define(SHADOWBOLT 686)
	SpellAddTargetDebuff(SHADOWBOLT SHADOWEMBRACE=12)
Define(SHADOWBURN 17877)
Define(SOULFIRE 6353)
	SpellAddBuff(SOULFIRE IMPROVEDSOULFIREBUFF=15)
Define(SOULBURN 74434)
	SpellInfo(SOULBURN cd=45)
	SpellAddBuff(SOULBURN SOULBURN=15)
Define(SUMMONINFERNAL 1122)
Define(SUMMONDOOMGUARD 18540)
Define(SUMMONFELGUARD 30146)
Define(SUMMONFELHUNTER 691)
Define(SUMMONIMP 688)
Define(SUMMONSUCCUBUS 712)
Define(UNSTABLEAFFLICTION 30108)
	SpellAddTargetDebuff(UNSTABLEAFFLICTION UNSTABLEAFFLICTION=15)


#Buff
Define(DECIMATION 63167)
Define(MOLTENCORE 71165)
Define(EMPOWEREDIMP 47283)
Define(IMPROVEDSOULFIREBUFF 85383)
Define(SHADOWTRANCE 17941)

#Talent	
Define(IMPROVEDSOULFIRE 11197)
	
AddListItem(curse elements SpellName(CURSEELEMENTS))
AddListItem(curse tongues SpellName(CURSETONGUES))
AddListItem(curse weakness SpellName(CURSEWEAKNESS))
AddListItem(curse none L(None) default)
AddListItem(bane agony SpellName(BANEOFAGONY))
AddListItem(bane doom SpellName(BANEOFDOOM) default)
AddListItem(bane havoc SpellName(BANEOFHAVOC) mastery=3)
AddListItem(afflic shadow SpellName(SHADOWBOLT) default mastery=1)
AddListItem(afflic drain SpellName(DRAINLIFE) mastery=1)

ScoreSpells(CURSEELEMENTS SHADOWBOLT HAUNT UNSTABLEAFFLICTION IMMOLATE CONFLAGRATE CURSEWEAKNESS
	BANEOFAGONY CORRUPTION SOULFIRE DRAINSOUL INCINERATE SHADOWBOLT CHAOSBOLT)

AddIcon help=main mastery=1
{
	if InCombat(no) and BuffExpires(FELARMOR 400) Spell(FELARMOR)

	if List(curse elements) and TargetDebuffExpires(magicaldamagetaken 0) and TargetDeadIn(more 8) Spell(CURSEELEMENTS)
	if List(curse weakness) and TargetDebuffExpires(CURSEWEAKNESS 2) and TargetDeadIn(more 8) Spell(CURSEWEAKNESS)

	if TargetDebuffExpires(HAUNT 1.5 mine=1) Spell(HAUNT)
	if TargetDebuffExpires(BANEOFDOOM 0 mine=1) and TargetDebuffExpires(BANEOFAGONY 0 mine=1)
	{
		if List(bane doom) and TargetDeadIn(more 20) Spell(BANEOFDOOM)
		if TargetDeadIn(more 10) Spell(BANEOFAGONY)
	}
	if TargetDebuffExpires(CORRUPTION 2 mine=1) and TargetDebuffExpires(SEEDOFCORRUPTION 0 mine=1) and TargetDeadIn(more 9) Spell(CORRUPTION)
	if TargetDebuffExpires(UNSTABLEAFFLICTION 1.5 mine=1 haste=spell) and TargetDeadIn(more 8) Spell(UNSTABLEAFFLICTION)
	if TargetLifePercent(less 25) Spell(DRAINSOUL)
	if List(afflic drain) and BuffPresent(SHADOWTRANCE) Spell(SHADOWBOLT)
    if List(afflic shadow) Spell(SHADOWBOLT)
    if List(afflic drain) Spell(DRAINLIFE)
}

AddIcon help=cd mastery=1
{
	if BuffPresent(heroism) Spell(SUMMONFELGUARD)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=2
{	
	if InCombat(no) and BuffExpires(FELARMOR 400) Spell(FELARMOR)

	if List(curse elements) and TargetDebuffExpires(magicaldamagetaken 2) and TargetDeadIn(more 8) Spell(CURSEELEMENTS)
	if List(curse weakness) and TargetDebuffExpires(CURSEWEAKNESS 2) and TargetDeadIn(more 8) Spell(CURSEWEAKNESS)

	if TargetDebuffPresent(IMMOLATE) Spell(HANDOFGULDAN)
	if BuffPresent(METAMORPHOSIS) Spell(SOULBURN)
	if BuffPresent(SOULBURN) Spell(SOULFIRE)
	if TargetDebuffExpires(IMMOLATE 2 mine=1 haste=spell) and TargetDeadIn(more 4) Spell(IMMOLATE)
	if TargetDebuffExpires(BANEOFDOOM 5 mine=1) and TargetDebuffExpires(BANEOFAGONY 0 mine=1)
	{
		if List(bane doom) and TargetDeadIn(more 15) Spell(BANEOFDOOM)
		if TargetDeadIn(more 10) Spell(BANEOFAGONY)
	}
	Spell(HANDOFGULDAN)
	if BuffPresent(METAMORPHOSIS 10) and BuffExpires(METAMORPHOSIS 16) Spell(IMMOLATE)
	if TargetDebuffExpires(CORRUPTION 2 mine=1) and TargetDebuffExpires(SEEDOFCORRUPTION 0 mine=1) and TargetDeadIn(more 9) Spell(CORRUPTION)
	if BuffPresent(MOLTENCORE) Spell(INCINERATE)
	if BuffPresent(DECIMATION) Spell(SOULFIRE)
	
	Spell(SHADOWBOLT)
}

AddIcon help=cd mastery=2
{
	Spell(METAMORPHOSIS)
	if BuffPresent(METAMORPHOSIS) Spell(SUMMONINFERNAL)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}
	
AddIcon help=main mastery=3
{
	if InCombat(no) and BuffExpires(FELARMOR 400) Spell(FELARMOR)
	
	if List(curse elements) and TargetDebuffExpires(magicaldamagetaken 2) and TargetDeadIn(more 8) Spell(CURSEELEMENTS)
	if List(curse weakness) and TargetDebuffExpires(CURSEWEAKNESS 2) and TargetDeadIn(more 8) Spell(CURSEWEAKNESS)

	if TalentPoints(IMPROVEDSOULFIRE more 0) and TargetLifePercent(more 80) and
			BuffExpires(IMPROVEDSOULFIREBUFF) Spell(SOULFIRE)
	if TargetDebuffExpires(BANEOFDOOM 0 mine=1) and TargetDebuffExpires(BANEOFAGONY 0 mine=1)
	{
		if List(bane doom) and TargetDeadIn(more 20) Spell(BANEOFDOOM)
		if TargetDeadIn(more 10) unless List(cure havoc) Spell(BANEOFAGONY)
	}
	if TargetDebuffExpires(IMMOLATE 2 mine=1 haste=spell) and TargetDeadIn(more 3) Spell(IMMOLATE)
	if 1s after TargetDebuffPresent(IMMOLATE mine=1) Spell(CONFLAGRATE)
	if TargetDebuffExpires(CORRUPTION 2 mine=1) and TargetDebuffExpires(SEEDOFCORRUPTION 0 mine=1) and TargetDeadIn(more 9) Spell(CORRUPTION)
	Spell(CHAOSBOLT)
	if BuffPresent(EMPOWEREDIMP) or BuffPresent(SOULBURN) Spell(SOULFIRE)
	Spell(INCINERATE)
}

AddIcon help=cd mastery=3
{
	if BuffPresent(heroism) Spell(SUMMONFELGUARD)
	Spell(DEMONSOUL)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon size=small
{
	Spell(SOULBURN usable=1)
}

AddIcon size=small mastery=1
{
    unless PetPresent()
    {
        if List(afflic shadow) Spell(SUMMONSUCCUBUS)
        if List(afflic drain) Spell(SUMMONIMP)
    }
}

AddIcon size=small mastery=2
{
    unless PetPresent() Spell(SUMMONFELGUARD)
}

AddIcon size=small mastery=3
{
    unless PetPresent() Spell(SUMMONIMP)
}
]]
