Ovale.defaut["PALADIN"] = 
[[
Define(AVENGERSSHIELD 31935)
	SpellInfo(AVENGERSSHIELD cd=15)
Define(AVENGINGWRATH 31884)
	SpellInfo(AVENGINGWRATH cd=180)
	SpellAddBuff(AVENGINGWRATH AVENGINGWRATH=20)
Define(CONSECRATE 26573)
	SpellInfo(CONSECRATE cd=8)
Define(CRUSADERSTRIKE 35395)
	SpellInfo(CRUSADERSTRIKE cd=4 holy=1)
Define(DIVINEFAVOR 31842)
	SpellInfo(DIVINEFAVOR cd=180)
	SpellAddBuff(DIVINEFAVOR DIVINEFAVOR=20)
Define(DIVINEPLEA 54428)
	SpellInfo(DIVINEPLEA cd=120)
	SpellAddBuff(DIVINEPLEA DIVINEPLEA=9)
Define(DIVINEPROTECTION 498)
	SpellInfo(DIVINEPROTECTION cd=60)
	SpellAddBuff(DIVINEPROTECTION DIVINEPROTECTION=10)
Define(DIVINESTORM 53385)
	SpellInfo(DIVINESTORM cd=4.5)
Define(EXORCISM 879)
	SpellAddBuff(EXORCISM THEARTOFWAR=0)
Define(FLASHOFLIGHT 19750)
Define(GUARDIANOFANCIENTKINGS 86150)
	SpellInfo(GUARDIANOFANCIENTKINGS cd=300)
Define(HAMMEROFWRATH 24275)
	SpellInfo(HAMMEROFWRATH cd=6)
Define(HAMMEROFTHERIGHTEOUS 53595)
	SpellInfo(HAMMEROFTHERIGHTEOUS cd=4.5 holy=1)
Define(HOLYLIGHT 635)
Define(HOLYRADIANCE 82327)
	SpellInfo(HOLYRADIANCE holy=1)
Define(HOLYSHIELD 20925)
	SpellInfo(HOLYSHIELD  cd=30)
	SpellAddBuff(HOLYSHIELD HOLYSHIELD=10)
Define(HOLYSHOCK 20473)
	SpellInfo(HOLYSHOCK cd=6)
Define(HOLYWRATH 2812)
	SpellInfo(HOLYWRATH cd=15)
Define(INQUISITION 84963)
	SpellInfo(INQUISITION holy=-3)
	SpellAddBuff(INQUISITION INQUISITION=12 DIVINEPURPOSE=0)
Define(JUDGEMENT 20271)
	SpellInfo(JUDGEMENT cd=8)
	SpellInfo(JUDGEMENT holy=1 itemset=T13 itemcount=2)
	SpellAddBuff(JUDGEMENT 53657 talent=TALENTJUDGEMENTSOFTHEPURE)
Define(LIGHTOFDAWN 85222)
	SpellInfo(LIGHTOFDAWN holy=-3)
Define(REBUKE 96231)
	SpellInfo(REBUKE cd=10)
Define(RIGHTEOUSFURY 25780)
Define(SEALOFINSIGHT 20165)
	SpellAddBuff(SEALOFINSIGHT SEALOFINSIGHT=1800)
Define(SEALRIGHTEOUSNESS 20154)
	SpellAddBuff(SEALRIGHTEOUSNESS SEALRIGHTEOUSNESS=1800)
Define(SEALOFTRUTH 31801)
	SpellAddBuff(SEALOFTRUTH SEALOFTRUTH=1800)
Define(SHIELDOFTHERIGHTEOUS 53600)
	SpellInfo(SHIELDOFTHERIGHTEOUS cd=6 holy=-3)
	SpellAddBuff(SHIELDOFTHERIGHTEOUS DIVINEPURPOSE=0)
Define(TEMPLARSVERDICT 85256)
	SpellInfo(TEMPLARSVERDICT holy=-3)
	SpellAddBuff(TEMPLARSVERDICT DIVINEPURPOSE=0)
Define(WORDOFGLORY 85673)
	SpellInfo(WORDOFGLORY holy=-3)
Define(ZEALOTRY 85696)
	SpellInfo(ZEALOTRY cd=120)
	SpellAddBuff(ZEALOTRY ZEALOTRY=20)

#Buff
Define(THEARTOFWAR 59578)
Define(DIVINEPURPOSE 90174)
Define(INFUSIONOFLIGHT 54149)
Define(SACREDDUTY 85433)
Define(GRANDCRUSADER 85416)
SpellList(JUDGEMENTSOFTHEPURE 53655 53656 53657)

Define(TALENTJUDGEMENTSOFTHEPURE 10127)

ScoreSpells(SHIELDOFTHERIGHTEOUS JUDGEMENT AVENGERSSHIELD HAMMEROFTHERIGHTEOUS CONSECRATE HOLYWRATH
	ZEALOTRY  INQUISITION TEMPLARSVERDICT DIVINESTORM EXORCISM HAMMEROFWRATH JUDGEMENT CRUSADERSTRIKE)

AddCheckBox(aoe L(AOE))

AddIcon help=main mastery=1
{
	unless InCombat()
	{
		if BuffExpires(SEALOFINSIGHT 400) Spell(SEALOFINSIGHT)
	}
 
	if HolyPower(more 2) Spell(WORDOFGLORY)
	Spell(HOLYSHOCK)
	Spell(JUDGEMENT)
	if TargetInRange(CRUSADERSTRIKE) Spell(CRUSADERSTRIKE)
	if BuffPresent(INFUSIONOFLIGHT) Spell(FLASHOFLIGHT)
	Spell(HOLYLIGHT priority=2)
}

AddIcon help=aoe mastery=1
{
	if HolyPower(more 2) Spell(LIGHTOFDAWN)
	Spell(HOLYRADIANCE)
}

AddIcon help=cd mastery=1
{
	Spell(AVENGINGWRATH)
	Spell(DIVINEFAVOR)
	Item(Trinket0Slot usable=1)
    Item(Trinket1Slot usable=1)
	Spell(GUARDIANOFANCIENTKINGS)
}

AddIcon help=mana size=small mastery=1
{
	if ManaPercent(less 88) Spell(DIVINEPLEA priority=2)
}

AddIcon help=main mastery=2
{
	if BuffExpires(RIGHTEOUSFURY) Spell(RIGHTEOUSFURY)
	unless InCombat() if BuffExpires(SEALRIGHTEOUSNESS 400) and BuffExpires(SEALOFTRUTH 400) Spell(SEALOFTRUTH)
	
	#shield_of_the_righteous,if=holy_power=3&(buff.sacred_duty.up|buff.inquisition.up)
	if HolyPower(more 2) and {BuffPresent(SACREDDUTY) or BuffPresent(INQUISITION)} Spell(SHIELDOFTHERIGHTEOUS)
	#judgement,if=holy_power=3
	if HolyPower(more 2) Spell(JUDGEMENT)
	#inquisition,if=holy_power=3&(buff.inquisition.down|buff.inquisition.remains<5)
	if HolyPower(more 2) and BuffExpires(INQUISITION 5) Spell(INQUISITION)
	#divine_plea,if=holy_power<2
	if HolyPower(less 2) Spell(DIVINEPLEA)
	#avengers_shield,if=buff.grand_crusader.up&holy_power<3
	if BuffPresent(GRANDCRUSADER) and HolyPower(less 3) Spell(AVENGERSSHIELD)
	#judgement,if=buff.judgements_of_the_pure.down
	if BuffExpires(JUDGEMENTSOFTHEPURE) Spell(JUDGEMENT)
	#crusader_strike,if=holy_power<3
	if HolyPower(less 3) Spell(CRUSADERSTRIKE)
	#hammer_of_wrath
	if TargetLifePercent(less 20) Spell(HAMMEROFWRATH)
	#avengers_shield,if=cooldown.crusader_strike.remains>=0.2
	if spell(CRUSADERSTRIKE)>0.2 Spell(AVENGERSSHIELD)
	#judgement
	Spell(JUDGEMENT)
	#consecration
	Spell(CONSECRATE)
	#holy_wrath
	Spell(HOLYWRATH)
	#divine_plea,if=holy_power<1
	if HolyPower(less 1) Spell(DIVINEPLEA)
}

AddIcon help=offgcd mastery=2
{
	if target.IsInterruptible() Spell(REBUKE)
}

AddIcon help=aoe mastery=2
{
	if HolyPower(more 0) and BuffExpires(INQUISITION 0) Spell(INQUISITION)
	Spell(HAMMEROFTHERIGHTEOUS)
	Spell(CONSECRATE)
	Spell(HOLYWRATH)
}

AddIcon help=cd mastery=2
{
	if HolyPower(more 2) Spell(WORDOFGLORY)
	Spell(HOLYSHIELD)
	Spell(GUARDIANOFANCIENTKINGS)
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
    
	#judgement,if=buff.judgements_of_the_pure.down
	if BuffExpires(JUDGEMENTSOFTHEPURE 0) Spell(JUDGEMENT)
	#crusader_strike,if=holy_power<3
	if HolyPower(less 3) Spell(CRUSADERSTRIKE)
	#judgement,if=buff.zealotry.down&holy_power<3
	if BuffExpires(ZEALOTRY) and HolyPower(less 3) Spell(JUDGEMENT)
	#inquisition,if=(buff.inquisition.down|buff.inquisition.remains<=2)&(holy_power>=3|buff.divine_purpose.react)
	if BuffExpires(INQUISITION 2) and {HolyPower(equal 3) or BuffPresent(DIVINEPURPOSE)} Spell(INQUISITION)
	#templars_verdict,if=buff.divine_purpose.react
	if BuffPresent(DIVINEPURPOSE) Spell(TEMPLARSVERDICT)
	#templars_verdict,if=holy_power=3
	if HolyPower(more 2) Spell(TEMPLARSVERDICT)
	#exorcism,if=buff.the_art_of_war.react
	if BuffPresent(THEARTOFWAR) Spell(EXORCISM)
	#hammer_of_wrath
	if TargetLifePercent(less 20) or BuffPresent(AVENGINGWRATH) Spell(HAMMEROFWRATH)
	#judgement,if=set_bonus.tier13_2pc_melee&buff.zealotry.up&holy_power<3
	if ArmorSetParts(T13 more 1) and BuffPresent(ZEALOTRY) and HolyPower(less 3) Spell(JUDGEMENT)
	#wait,sec=0.1,if=cooldown.crusader_strike.remains<0.5
	if spell(CRUSADERSTRIKE) > 0.5
	{
		#holy_wrath
		Spell(HOLYWRATH)
		#divine_plea
		Spell(DIVINEPLEA)
	}
}

AddIcon help=offgcd mastery=3
{
	if target.IsInterruptible() Spell(REBUKE)
}

AddIcon help=aoe mastery=3 checkboxon=aoe
{
	Spell(DIVINESTORM)
	#consecration
	Spell(CONSECRATE)
}

AddIcon help=cd mastery=3
{
    #/guardian_of_ancient_kings,if=cooldown.zealotry.remains<10
	if spell(ZEALOTRY)<10 Spell(GUARDIANOFANCIENTKINGS)
	#/zealotry,if=cooldown.guardian_of_ancient_kings.remains>0&cooldown.guardian_of_ancient_kings.remains<292
	if {spell(GUARDIANOFANCIENTKINGS)>0} and {spell(GUARDIANOFANCIENTKINGS)<292} Spell(ZEALOTRY)
	#/avenging_wrath,if=buff.zealotry.up
	if BuffPresent(ZEALOTRY)
		Spell(AVENGINGWRATH)
	Item(Trinket0Slot usable=1)
    Item(Trinket1Slot usable=1)
}
]]
