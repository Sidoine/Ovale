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
Define(HUNTERSMARK 53338)
Define(BLACKARROW 3674)
Define(LOCKANDLOAD 56453)
Define(TALENTEXPLOSIVESHOT 2145)

AddCheckBox(multi SpellName(MULTISHOT))

AddIcon
{
	if TargetDebuffExpires(HUNTERSMARK 0) Spell(HUNTERSMARK)
	if TargetDebuffExpires(BLACKARROW 0 mine=1) Spell(BLACKARROW)
	if TargetDebuffExpires(SERPENTSTING 0 mine=1) Spell(SERPENTSTING)
	if TargetDebuffExpires(EXPLOSIVESHOT 0 mine=1) Spell(EXPLOSIVESHOT)
	Spell(AIMEDSHOT)
	if CheckBoxOn(multi) Spell(MULTISHOT)
	unless TalentPoints(TALENTEXPLOSIVESHOT more 0) Spell(ARCANESHOT)
	if TargetLifePercent(less 20) Spell(KILLSHOT)
	if TargetDebuffExpires(HUNTERSMARK 2) Spell(HUNTERSMARK)
	unless TargetDebuffPresent(EXPLOSIVESHOT mine=1) and {2s before Spell(EXPLOSIVESHOT)} Spell(STEADYSHOT)
}

AddIcon
{
	Spell(BESTIALWRATH usable=1)
	Spell(KILLCOMMAND usable=1)
	Spell(RAPIDFIRE)
}
]]