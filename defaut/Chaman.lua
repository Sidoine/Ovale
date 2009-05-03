Ovale.defaut["SHAMAN"] =
[[
Define(CHAINLIGHTNING 421)
Define(LIGHTNINGBOLT 403)
Define(LAVABURST 51505)
Define(WATERSHIELD 52127)
Define(FLAMESHOCK 8050)
Define(FLAMETHONG 8024)
Define(EARTHSHOCK 8042)
Define(STORMSTRIKE 17364)
Define(LAVALASH 60103)
Define(LIGHTNINGSHIELD 324)
Define(MAELSTROMWEAPON 53817)
Define(ELEMENTALMASTERY 16166)
Define(SHAMANISTICRAGE 30823)
Define(THUNDERSTORM 51490)
Define(FERALSPIRIT 51533)

AddCheckBox(chain SpellName(CHAINLIGHTNING))
AddCheckBox(melee L(Melee))

AddIcon
{
	unless CheckBoxOn(melee)
	{
	#	if BuffExpires(FLAMETHONG 2) Spell(FLAMETHONG)
		if BuffExpires(WATERSHIELD 2) Spell(WATERSHIELD)
		if TargetDebuffExpires(FLAMESHOCK 0) Spell(FLAMESHOCK)
		Spell(LAVABURST doNotRepeat=1)
		if CheckBoxOn(chain) Spell(CHAINLIGHTNING doNotRepeat=1)
		Spell(LIGHTNINGBOLT)
	}
	if CheckBoxOn(melee)
	{
		if TargetDebuffExpires(FLAMESHOCK 0) Spell(FLAMESHOCK)
		if TargetDebuffPresent(FLAMESHOCK 5) Spell(EARTHSHOCK)
		if BuffExpires(LIGHTNINGSHIELD 0) Spell(LIGHTNINGSHIELD)
		Spell(STORMSTRIKE)
		Spell(LAVALASH)
		if CheckBoxOn(chain) and BuffPresent(MAELSTROMWEAPON stacks=5) Spell(CHAINLIGHTNING doNotRepeat=1)
		if BuffPresent(MAELSTROMWEAPON stacks=5) Spell(LIGHTNINGBOLT doNotRepeat=1)
	}
}

AddIcon
{
	Spell(ELEMENTALMASTERY)
	Spell(FERALSPIRIT)
}

AddIcon size=small
{
	if ManaPercent(less 25)
		Spell(SHAMANISTICRAGE)
	if ManaPercent(less 50)
		Spell(THUNDERSTORM)
}
]]