Ovale.defaut["HUNTER"] =
[[
#Spells
Define(AIMEDSHOT 19434)
	SpellInfo(AIMEDSHOT resetcounter=ss)
Define(ARCANESHOT 3044)
	SpellInfo(ARCANESHOT resetcounter=ss)
Define(ASPECTOFTHEFOX 82661)
Define(ASPECTOFTHEHAWK 13165)
Define(BESTIALWRATH 19574)
	SpellInfo(BESTIALWRATH cd=120)
Define(BLACKARROW 3674)
	SpellInfo(BLACKARROW cd=26)
	SpellAddTargetDebuff(BLACKARROW BLACKARROW=15)
Define(CALLOFTHEWILD 53434)
Define(CHIMERASHOT 53209)
	SpellInfo(CHIMERASHOT cd=10 resetcounter=ss)
Define(COBRASHOT 77767)
Define(EXPLOSIVESHOT 53301)
	SpellInfo(EXPLOSIVESHOT cd=6 buffnocd=LOCKANDLOAD)
	SpellAddTargetDebuff(EXPLOSIVESHOT EXPLOSIVESHOT=2)
	SpellAddBuff(EXPLOSIVESHOT LOCKANDLOAD=-1)
Define(FERVOR 82726)
	Spellinfo(FERVOR mana=-50)
Define(FOCUSFIRE 82692)
Define(KILLCOMMAND 34026)
	SpellInfo(KILLCOMMAND cd=6 resetcounter=ss)
Define(KILLSHOT 53351)
	SpellInfo(KILLSHOT cd=15 resetcounter=ss)
Define(HUNTERSMARK 1130)
	SpellAddTargetDebuff(HUNTERSMARK HUNTERSMARK=300)
Define(MULTISHOT 2643)
Define(RAPIDFIRE 3045)
	SpellAddBuff(RAPIDFIRE RAPIDFIRE=10)
	SpellInfo(RAPIDFIRE cd=300 resetcounter=ss)
Define(READINESS 23989)
Define(SERPENTSTING 1978)
	SpellInfo(SERPENTSTING resetcounter=ss)
	SpellAddTargetDebuff(SERPENTSTING SERPENTSTING=15)
Define(STEADYSHOT 56641)
	SpellInfo(STEADYSHOT inccounter=ss mana=-9)
Define(SILENCINGSHOT 34490)
	SpellInfo(SILENCINGSHOT resetcounter=ss)

#Pet spells
Define(GROWL 2649)
	
#Buffs
Define(LOCKANDLOAD 56453)
Define(FRENZYEFFECT 19615)
Define(MARKEDFORDEATH 88691)
Define(FIRE 82926)
Define(BEASTWITHIN 34692)

AddCheckBox(multi SpellName(MULTISHOT))
ScoreSpells(FOCUSFIRE KILLCOMMAND ARCANESHOT KILLSHOT STEADYSHOT SERPENTSTING
			CHIMERASHOT AIMEDSHOT
			BLACKARROW EXPLOSIVESHOT)

AddIcon help=main mastery=1
{
	if CheckBoxOn(multi)
	{
		#/multi_shot,if=target.adds>5
		if Mana(more 56) Spell(MULTISHOT)
		#/cobra_shot,if=target.adds>5
		Spell(COBRASHOT)
		Spell(STEADYSHOT)
	}
	#/serpent_sting,if=!ticking
	if Mana(more 24) and TargetDebuffExpires(SERPENTSTING 0 mine=1) and TargetDeadIn(more 8) Spell(SERPENTSTING)
	#/kill_shot
	if TargetLifePercent(less 20) Spell(KILLSHOT)
	#/kill_command
	if TargetInRange(GROWL) Spell(KILLCOMMAND)
	#/fervor,if=focus<=20
	if Mana(less 20) Spell(FERVOR)
	#/arcane_shot,if=focus>=90|buff.beast_within.up
	if Mana(more 90) or BuffPresent(BEASTWITHIN) Spell(ARCANESHOT)
	#/cobra_shot
	Spell(COBRASHOT)
	Spell(STEADYSHOT)
}

AddIcon help=offgcd mastery=1
{
	#/focus_fire,five_stacks=1,if=!buff.beast_within.up
	if pet.BuffPresent(FRENZYEFFECT stacks=5) and BuffExpires(BEASTWITHIN 0) Spell(FOCUSFIRE)
}

AddIcon help=cd mastery=1
{
	unless BuffPresent(ASPECTOFTHEHAWK) or BuffPresent(ASPECTOFTHEFOX) Spell(ASPECTOFTHEHAWK)
	#/bestial_wrath,if=focus>60
	if Mana(more 60) Spell(BESTIALWRATH usable=1)
	#/rapid_fire,if=!buff.bloodlust.up&!buff.beast_within.up
	if BuffExpires(heroism 0) and BuffExpires(BEASTWITHIN 0) Spell(RAPIDFIRE)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=2
{
	if CheckBoxOn(multi)
	{
		#/multi_shot,if=target.adds>5
		if Mana(more 56) Spell(MULTISHOT)
		#/cobra_shot,if=target.adds>5
		Spell(STEADYSHOT)
	}
	
	#/serpent_sting,if=!ticking&target.health_pct<=80
    if Mana(more 24) and TargetDebuffExpires(SERPENTSTING 0 mine=1) and TargetDeadIn(more 8) and TargetLifePercent(less 90) Spell(SERPENTSTING)
	if TargetDebuffPresent(SERPENTSTING) and Mana(more 49) Spell(CHIMERASHOT)
    if TargetLifePercent(less 20) Spell(KILLSHOT)
	if BuffPresent(FIRE) Spell(AIMEDSHOT)
    if Mana(less 40) or Counter(ss equal 1) Spell(STEADYSHOT)
    if CheckBoxOn(multi) Spell(MULTISHOT)
    unless 1.6s before Spell(CHIMERASHOT) Spell(ARCANESHOT)
    if Mana(more 66) Spell(ARCANESHOT)
    unless 0.25s before Spell(CHIMERASHOT) Spell(STEADYSHOT)
}

AddIcon help=cd mastery=1
{
	unless BuffPresent(ASPECTOFTHEHAWK) or BuffPresent(ASPECTOFTHEFOX) Spell(ASPECTOFTHEHAWK)
	#/rapid_fire
	Spell(RAPIDFIRE)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=3
{
    if Mana(more 24) and TargetDebuffExpires(SERPENTSTING 0 mine=1) and TargetDeadIn(more 8) Spell(SERPENTSTING)
    if TargetDebuffExpires(EXPLOSIVESHOT 0 mine=1) Spell(EXPLOSIVESHOT)
    if Mana(more 35) and TargetDebuffExpires(BLACKARROW 0 mine=1) Spell(BLACKARROW)
    if TargetLifePercent(less 20) Spell(KILLSHOT)
    if Mana(more 70) and BuffExpires(LOCKANDLOAD) 
	{
		if CheckBoxOn(multi) Spell(MULTISHOT)
		Spell(ARCANESHOT)
	}
    Spell(COBRASHOT) 
	Spell(STEADYSHOT)
}


AddIcon help=cd mastery=3
{
	unless BuffPresent(ASPECTOFTHEHAWK) or BuffPresent(ASPECTOFTHEFOX) Spell(ASPECTOFTHEHAWK)
	if TargetDebuffExpires(HUNTERSMARK 2) and TargetDebuffExpires(MARKEDFORDEATH 0) and TargetDeadIn(more 20) Spell(HUNTERSMARK nored=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
	Spell(CALLOFTHEWILD usable=1)
	unless BuffPresent(heroism) Spell(RAPIDFIRE)
	Spell(READINESS)
}
]]
