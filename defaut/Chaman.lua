Ovale.defaut["SHAMAN"] =
[[
Define(CHAINLIGHTNING 421)
Define(LIGHTNINGBOLT 548)
Define(LAVABURST 51505)
Define(WATERSHIELD 52127)
Define(FLAMESHOCK 8050)
Define(FLAMETHONG 8024)
Define(WINDFURYWEAPON 8232)
Define(EARTHSHOCK 8042)
Define(STORMSTRIKE 17364)
Define(LAVALASH 60103)
Define(LIGHTNINGSHIELD 324)
Define(MAELSTROMWEAPON 53817)
Define(ELEMENTALMASTERY 16166)
Define(SHAMANISTICRAGE 30823)
Define(THUNDERSTORM 51490)
Define(FERALSPIRIT 51533)
Define(HEROISM 32182)
Define(BLOODLUST 2825)
Define(TALENTFLURRY 602)
Define(FIRENOVA 1535)

#Fire
Define(TOTEMOFWRATH 30706)
Define(FIREELEMENTALTOTEM 2894)
Define(FLAMETONGTOTEM 8227)
Define(FROSTRESISTANCETOTEM 8181)
Define(MAGMATOTEM 8190)
Define(SEARINGTOTEM 3599)
#Water
Define(CLEANSINGTOTEM 8170)
Define(FIRERESISTANCETOTEM 8184)
Define(HEALINGSTREAMTOTEM 5394)
Define(MANASPRINGTOTEM 5675)
#Air
Define(GROUNDINGTOTEM 8177)
Define(NATURERESISTANCETOTEM 10595)
Define(WINDFURYTOTEM 8512)
Define(WRATHOFAIRTOTEM 3738)
#Earth
Define(STONESKINTOTEM 8071)
Define(STRENGTHOFEARTHTOTEM 8075)
Define(TREMORTOTEM 8143)

AddCheckBox(aoe L(AOE))
AddCheckBox(chain SpellName(CHAINLIGHTNING) default)
AddCheckBox(firenova SpellName(MAGMATOTEM))

SpellInfo(LAVABURST cd=8)
SpellInfo(CHAINLIGHTNING cd=6)
SpellAddBuff(LIGHTNINGBOLT MAELSTROMWEAPON=0)
SpellAddBuff(CHAINLIGHTNING MAELSTROMWEAPON=0)
SpellAddTargetDebuff(FLAMESHOCK FLAMESHOCK=18)
ScoreSpells(WATERSHIELD FLAMESHOCK LAVABURST CHAINLIGHTNING LIGHTNINGBOLT LAVALASH EARTHSHOCK LIGHTNINGSHIELD
	STORMSTRIKE)
SpellInfo(EARTHSHOCK cd=6 sharedcd=shock)
SpellInfo(FLAMESHOCK cd=6 sharedcd=shock)
SpellAddBuff(LIGHTNINGSHIELD LIGHTNINGSHIELD=600)
SpellAddBuff(WATERSHIELD WATERSHIELD=600)
SpellInfo(LAVALASH cd=6)
SpellInfo(STORMSTRIKE cd=8)
SpellInfo(FIRENOVA cd=10)
SpellInfo(MAGMATOTEM cd=20)

AddIcon help=main
{
	unless TalentPoints(TALENTFLURRY more 0)
	{
		if WeaponEnchantExpires(mainhand 2) Spell(FLAMETHONG)
		if BuffExpires(WATERSHIELD 2) Spell(WATERSHIELD)
		if CheckBoxOn(firenova)
		{
			if TotemExpires(fire) Spell(MAGMATOTEM)
			unless TotemExpires(fire) Spell(FIRENOVA)
			if ManaPercent(less 90) Spell(THUNDERSTORM)
		}
		if CheckBoxOn(aoe) Spell(CHAINLIGHTNING)
		if TargetDebuffExpires(FLAMESHOCK 0 mine=1) Spell(FLAMESHOCK)
		unless TargetDebuffExpires(FLAMESHOCK 1.6 haste=spell mine=1) Spell(LAVABURST)
		
		if CheckBoxOn(chain) and 1.4s before Spell(LAVABURST) and CastTime(LIGHTNINGBOLT more 1.5)
				Spell(CHAINLIGHTNING)
		Spell(LIGHTNINGBOLT)
	}
	if TalentPoints(TALENTFLURRY more 0)
	{
		if WeaponEnchantExpires(mainhand 2) Spell(WINDFURYWEAPON)
		if WeaponEnchantExpires(offhand 2) Spell(FLAMETHONG)
		
		if CheckBoxOn(aoe) and BuffPresent(MAELSTROMWEAPON stacks=5) Spell(CHAINLIGHTNING)
		if BuffPresent(MAELSTROMWEAPON stacks=5) Spell(LIGHTNINGBOLT)
		if TargetDebuffPresent(STORMSTRIKE) Spell(EARTHSHOCK)
		Spell(STORMSTRIKE)
		Spell(EARTHSHOCK)
		if CheckBoxOn(firenova)
		{
			if TotemExpires(fire) Spell(MAGMATOTEM)
			unless TotemExpires(fire) Spell(FIRENOVA)
		}
		if BuffExpires(LIGHTNINGSHIELD 0) Spell(LIGHTNINGSHIELD)
		Spell(LAVALASH)
		if CheckBoxOn(aoe) and BuffPresent(MAELSTROMWEAPON stacks=3) Spell(CHAINLIGHTNING priority=2)
		if BuffPresent(MAELSTROMWEAPON stacks=3) Spell(LIGHTNINGBOLT priority=2)
	}
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