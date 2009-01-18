Ovale.defaut["HUNTER"] =
[[
Define(SERPENTSTING 1978)
Define(ARCANESHOT 3044)
Define(AIMEDSHOT 19434)
Define(MULTISHOT 2643)
Define(STEADYSHOT 56641)
Define(EXPLOSIVESHOT 53301)
Define(KILLSHOT 53351)
Define(RAPIDFIRE 3045)
Define(KILLCOMMAND 34026)
Define(BESTIALWRATH 19574)

AddCheckBox(multi SpellName(MULTISHOT))

AddIcon
{
	if TargetDebuffExpires(SERPENTSTING 0) Spell(SERPENTSTING)
	Spell(ARCANESHOT)
	#Spell(AIMEDSHOT)
	if CheckBoxOn(multi) Spell(MULTISHOT)
	Spell(EXPLOSIVESHOT)
	if TargetLifePercent(less 20) Spell(KILLSHOT)
	Spell(STEADYSHOT)
}

AddIcon
{
	Spell(BESTIALWRATH usable=1)
	Spell(KILLCOMMAND usable=1)
	Spell(RAPIDFIRE)
}
]]