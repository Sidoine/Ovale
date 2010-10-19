Ovale.defaut["PALADIN"] = 
[[
Define(AVENGERSSHIELD 31935)
Define(AVENGINGWRATH 31884)
	SpellInfo(AVENGINGWRATH cd=180)
Define(CONSECRATE 26573)
	SpellInfo(CONSECRATE cd=8)
Define(CRUSADERSTRIKE 35395)
	SpellInfo(CRUSADERSTRIKE cd=4)
Define(DIVINEFAVOR 31842)
	SpellInfo(DIVINEFAVOR cd=180)
Define(DIVINEPLEA 54428)
	SpellInfo(DIVINEPLEA cd=60)
	SpellAddBuff(DIVINEPLEA DIVINEPLEA=15)
Define(DIVINEPROTECTION 498)
Define(DIVINESTORM 53385)
Define(EXORCISM 879)
	SpellAddBuff(EXORCISM THEARTOFWAR=0)
Define(HAMMEROFWRATH 24275)
	SpellInfo(HAMMEROFWRATH cd=6)
Define(HAMMEROFTHERIGHTEOUS 53595)
	SpellInfo(HAMMEROFTHERIGHTEOUS cd=6)
Define(HOLYSHOCK 20473)
	SpellInfo(HOLYSHOCK cd=6)
Define(HOLYWRATH 2812)
	SpellInfo(HOLYWRATH cd=30)
Define(INQUISITION 84963)
Define(JUDGEMENT 20271)
Define(RIGHTEOUSFURY 25780)
Define(SEALRIGHTEOUSNESS 20154)
	SpellAddBuff(SEALRIGHTEOUSNESS SEALRIGHTEOUSNESS=1800)
Define(SEALOFTRUTH 31801)
	SpellAddBuff(SEALOFTRUTH SEALOFTRUTH=1800)
Define(SHIELDOFTHERIGHTEOUS 53600)
	SpellInfo(SHIELDOFTHERIGHTEOUS cd=6)
Define(TEMPLARSVERDICT 85256)
Define(ZEALOTRY 85696)

#Buff
Define(THEARTOFWAR 59578)
Define(JUDGEMENTSOFTHEPURE 53655)
Define(HANDOFLIGHT 90174)

ScoreSpells(SHIELDOFTHERIGHTEOUS JUDGEMENT AVENGERSSHIELD HAMMEROFTHERIGHTEOUS CONSECRATE HOLYWRATH
	ZEALOTRY  INQUISITION TEMPLARSVERDICT DIVINESTORM EXORCISM HAMMEROFWRATH JUDGEMENT CRUSADERSTRIKE)

AddCheckBox(aoe L(AOE))

AddIcon help=main mastery=1
{
	if HolyPower(more 0) and BuffExpires(INQUISITION) Spell(INQUISITION)
	if ManaPercent(less 90) Spell(DIVINEPLEA)
	if BuffExpires(JUDGEMENTSOFTHEPURE 2) Spell(JUDGEMENT)
	Spell(HOLYSHOCK)
	Spell(EXORCISM)
}

AddIcon help=cd mastery=1
{
	Spell(AVENGINGWRATH)
	Spell(DIVINEFAVOR)
	Item(Trinket0Slot usable=1)
    Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=2
{
	if BuffExpires(RIGHTEOUSFURY) Spell(RIGHTEOUSFURY)
	unless InCombat() if BuffExpires(SEALRIGHTEOUSNESS 400) and BuffExpires(SEALOFTRUTH 400) Spell(SEALOFTRUTH)
	
	if CheckBoxOn(aoe)
	{
		Spell(HAMMEROFTHERIGHTEOUS)
		if HolyPower(more 0) and BuffExpires(INQUISITION) Spell(INQUISITION)
		Spell(HOLYWRATH)
		Spell(CONSECRATE)
	}
	if CheckBoxOff(aoe)
	{
		if HolyPower(more 2) Spell(SHIELDOFTHERIGHTEOUS)
		Spell(CRUSADERSTRIKE)
	}
	Spell(JUDGEMENT)
	Spell(HOLYWRATH)
	Spell(AVENGERSSHIELD)
}

AddIcon help=cd mastery=2
{
	Spell(AVENGINGWRATH)
	Spell(DIVINEPROTECTION)
    Item(Trinket0Slot usable=1)
    Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=3
{
	unless InCombat()
	{
		if BuffExpires(SEALRIGHTEOUSNESS 400) and BuffExpires(SEALOFTRUTH 400) Spell(SEALOFTRUTH)
	}
    
	if HolyPower(more 2) and BuffExpires(HANDOFLIGHT) and TargetDeadIn(more 20) Spell(ZEALOTRY)
    if {HolyPower(more 0) or BuffPresent(HANDOFLIGHT)} and BuffExpires(INQUISITION) Spell(INQUISITION)
	if  HolyPower(more 2) or BuffPresent(HANDOFLIGHT)
	{
		if CheckBoxOff(aoe)  Spell(TEMPLARSVERDICT)
		if CheckBoxOn(aoe) Spell(DIVINESTORM)
	}
    Spell(CRUSADERSTRIKE)
    unless 0.5s before Spell(CRUSADERSTRIKE)
	{
   		if TargetLifePercent(less 20) or BuffPresent(AVENGINGWRATH) Spell(HAMMEROFWRATH)
   		if BuffPresent(THEARTOFWAR) Spell(EXORCISM)
   		Spell(JUDGEMENT)   
   		Spell(HOLYWRATH)
	}
    if CheckBoxOn(aoe) Spell(CONSECRATE)
}

AddIcon help=cd mastery=3
{
	Spell(AVENGINGWRATH)
    Item(Trinket0Slot usable=1)
    Item(Trinket1Slot usable=1)
}
]]
