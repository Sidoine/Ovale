Ovale.defaut["SHAMAN"] =
[[
Define(BLOODLUST 2825)
Define(CHAINLIGHTNING 421)
	SpellInfo(CHAINLIGHTNING cd=6)
	SpellAddBuff(CHAINLIGHTNING MAELSTROMWEAPON=0)
Define(EARTHQUAKE 61882)
Define(EARTHSHOCK 8042)
	SpellInfo(EARTHSHOCK cd=6 sharedcd=shock)
Define(ELEMENTALMASTERY 16166)
Define(FERALSPIRIT 51533)
Define(FIRENOVA 1535)
	SpellInfo(FIRENOVA cd=10)
Define(FLAMESHOCK 8050)
	SpellInfo(FLAMESHOCK cd=6 sharedcd=shock)
	SpellAddTargetDebuff(FLAMESHOCK FLAMESHOCK=18)
Define(FLAMETHONGWEAPON 8024)
Define(FROSTSHOCK 8056)
Define(FROSTBANDWEAPON 8033)
Define(HEROISM 32182)
Define(LAVABURST 51505)
	SpellInfo(LAVABURST cd=8)
Define(LAVALASH 60103)
	SpellInfo(LAVALASH cd=6)
Define(LIGHTNINGBOLT 403)
	SpellAddBuff(LIGHTNINGBOLT MAELSTROMWEAPON=0)
Define(LIGHTNINGSHIELD 324)
	SpellAddBuff(LIGHTNINGSHIELD LIGHTNINGSHIELD=600)
Define(PRIMALSTRIKE 73899)
Define(ROCKBITERWEAPON 8017)
Define(SHAMANISTICRAGE 30823)
Define(SPIRITWALKERSGRACE 79206)
Define(STORMSTRIKE 17364)
	SpellInfo(STORMSTRIKE cd=8)
Define(THUNDERSTORM 51490)
Define(UNLEASHELEMENTS 73680)
Define(WATERSHIELD 52127)
	SpellAddBuff(WATERSHIELD WATERSHIELD=600)
Define(WINDSHEAR 57994)
Define(WINDFURYWEAPON 8232)

#Buff
Define(MAELSTROMWEAPON 53817)
Define(UNLEASHWIND 73681)

#Fire
Define(FIREELEMENTALTOTEM 2894)
Define(MAGMATOTEM 8190)
	SpellInfo(MAGMATOTEM cd=20)
Define(SEARINGTOTEM 3599)
Define(FLAMETHONGTOTEM 8227)

Define(TOTEMOFWRATH 30706)
#Water
Define(HEALINGSTREAMTOTEM 5394)
Define(MANASPRINGTOTEM 5675)
Define(TOTEMOFTRANQUILMIND 87718)
#Air
Define(GROUNDINGTOTEM 8177)
Define(WINDFURYTOTEM 8512)
Define(WRATHOFAIRTOTEM 3738)
#Earth
Define(STONECLAWTOTEM 5730)
Define(STONESKINTOTEM 8071)
Define(STRENGTHOFEARTHTOTEM 8075)
Define(TREMORTOTEM 8143)

ScoreSpells(LIGHTNINGSHIELD CHAINLIGHTNING FLAMESHOCK LAVABURST EARTHSHOCK LIGHTNINGBOLT
			STORMSTRIKE LAVALASH)

AddCheckBox(aoe L(AOE))
AddCheckBox(chain SpellName(CHAINLIGHTNING) default mastery=1)

AddIcon help=main mastery=1
{
	unless InCombat()
	{
		if WeaponEnchantExpires(mainhand 400) Spell(FLAMETHONG)
	}
	if BuffExpires(LIGHTNINGSHIELD 2) Spell(LIGHTNINGSHIELD)
#	if CheckBoxOn(aoe)
#	{
#		if TotemExpires(fire) Spell(MAGMATOTEM)
#		unless TotemExpires(fire) Spell(FIRENOVA)
#		if ManaPercent(less 90) Spell(THUNDERSTORM)
#	}
	if TargetDebuffExpires(FLAMESHOCK 0 mine=1) Spell(FLAMESHOCK)
	unless TargetDebuffExpires(FLAMESHOCK 1.6 haste=spell mine=1) Spell(LAVABURST)
	if BuffPresent(LIGHTNINGSHIELD stacks=9) Spell(EARTHSHOCK)
	if TotemExpires(fire) Spell(SEARINGTOTEM)
	if CheckBoxOn(aoe) Spell(CHAINLIGHTNING)
#	Spell(UNLEASHELEMENTS)
	
#	if CheckBoxOn(chain) and CastTime(LIGHTNINGBOLT more 1.5) and at least 0s from Spell(LAVABURST) until EndCastTime(CHAINLIGHTNING)
#			Spell(CHAINLIGHTNING)

	Spell(LIGHTNINGBOLT)
}

AddIcon help=main mastery=2
{
	unless InCombat()
	{
		if WeaponEnchantExpires(mainhand 400) Spell(WINDFURYWEAPON)
		if WeaponEnchantExpires(offhand 400) Spell(FLAMETHONGWEAPON)
	}
	
	if BuffExpires(LIGHTNINGSHIELD) Spell(LIGHTNINGSHIELD)
	
	if CheckBoxOn(aoe)
	{
		if BuffPresent(MAELSTROMWEAPON stacks=5) Spell(CHAINLIGHTNING)
		if TotemExpires(fire) Spell(MAGMATOTEM)
		if TotemPresent(fire) Spell(FIRENOVA)
		Spell(LAVALASH)
		if BuffPresent(MAELSTROMWEAPON stacks=4) Spell(CHAINLIGHTNING)
		Spell(UNLEASHELEMENTS)
		if TargetDebuffExpires(FLAMESHOCK 0 mine=1) Spell(FLAMESHOCK)
		Spell(EARTHSHOCK)
		Spell(STORMSTRIKE)
		Spell(FIRENOVA)
		if BuffPresent(MAELSTROMWEAPON stacks=2) Spell(CHAINLIGHTNING)
		Spell(LAVABURST)
	}
	
	if CheckBoxOff(aoe)
	{
		if BuffPresent(MAELSTROMWEAPON stacks=5) Spell(LIGHTNINGBOLT)
		if TotemExpires(fire) Spell(SEARINGTOTEM)
		Spell(LAVALASH)
		if BuffPresent(MAELSTROMWEAPON stacks=4) Spell(LIGHTNINGBOLT)
		Spell(UNLEASHELEMENTS)
		if TargetDebuffExpires(FLAMESHOCK 0 mine=1) Spell(FLAMESHOCK)
		Spell(EARTHSHOCK)
		Spell(STORMSTRIKE)
		Spell(FIRENOVA)
		if BuffPresent(MAELSTROMWEAPON stacks=2) Spell(LIGHTNINGBOLT)
		Spell(LAVABURST)
	}
		
	Spell(SHAMANISTICRAGE priority=2)
	Spell(FERALSPIRIT priority=2)
}

AddIcon help=cd
{
	Spell(ELEMENTALMASTERY)
	Spell(FERALSPIRIT)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
	Spell(FIREELEMENTALTOTEM)
}

AddIcon size=small help=mana
{
	if ManaPercent(less 25)
		Spell(SHAMANISTICRAGE)
	if ManaPercent(less 50)
		Spell(THUNDERSTORM)
}

AddIcon size=small
{
	Spell(HEROISM)
	Spell(BLOODLUST)	
}

]]