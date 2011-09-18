Ovale.defaut["HUNTER"] =
[[
#Spells
Define(AIMEDSHOT 19434)
	SpellInfo(AIMEDSHOT resetcounter=ss mana=50)
	SpellAddBuff(AIMEDSHOT FIRE=0)
Define(ARCANESHOT 3044)
	SpellInfo(ARCANESHOT resetcounter=ss mana=25)
Define(ASPECTOFTHEFOX 82661)
	SpellAddBuff(ASPECTOFTHEFOX ASPECTOFTHEFOX=1000)
Define(ASPECTOFTHEHAWK 13165)
	SpellAddBuff(ASPECTOFTHEHAWK ASPECTOFTHEHAWK=1000)
Define(BESTIALWRATH 19574)
	SpellInfo(BESTIALWRATH cd=120)
	SpellAddBuff(BESTIALWRATH BESTIALWRATH=10)
Define(BLACKARROW 3674)
	SpellInfo(BLACKARROW cd=30 mana=35)
	SpellAddTargetDebuff(BLACKARROW BLACKARROW=15)
Define(CALLOFTHEWILD 53434)
	SpellInfo(CALLOFTHEWILD cd=300)
	SpellAddBuff(CALLOFTHEWILD CALLOFTHEWILD=20)
Define(CHIMERASHOT 53209)
	SpellInfo(CHIMERASHOT cd=10 resetcounter=ss mana=50)
	SpellAddTargetDebuff(CHIMERASHOT SERPENTSTING=refresh)
Define(COBRASHOT 77767)
	SpellInfo(COBRASHOT mana=-9)
	SpellAddTargetDebuff(COBRASHOT SERPENTSTING=refresh)
Define(EXPLOSIVESHOT 53301)
	SpellInfo(EXPLOSIVESHOT cd=6 mana=50 buffnocd=LOCKANDLOAD)
	SpellAddTargetDebuff(EXPLOSIVESHOT EXPLOSIVESHOT=2)
	SpellAddBuff(EXPLOSIVESHOT LOCKANDLOAD=-1)
Define(FERVOR 82726)
	SpellInfo(FERVOR mana=-50 cd=120)
Define(FOCUSFIRE 82692)
	SpellInfo(FOCUSFIRE cd=15)
	SpellAddBuff(FOCUSFIRE FOCUSFIRE=15)
Define(KILLCOMMAND 34026)
	SpellInfo(KILLCOMMAND cd=6 mana=40 resetcounter=ss)
Define(KILLSHOT 53351)
	SpellInfo(KILLSHOT cd=10 resetcounter=ss)
Define(HUNTERSMARK 1130)
	SpellAddTargetDebuff(HUNTERSMARK HUNTERSMARK=300)
Define(MULTISHOT 2643)
	SpellInfo(MULTISHOT mana=40)
Define(RAPIDFIRE 3045)
	SpellAddBuff(RAPIDFIRE RAPIDFIRE=15)
	SpellInfo(RAPIDFIRE cd=300 resetcounter=ss)
Define(READINESS 23989)
	SpellInfo(READINESS cd=180)
Define(SERPENTSTING 1978)
	SpellInfo(SERPENTSTING resetcounter=ss duration=15 mana=25)
	SpellAddTargetDebuff(SERPENTSTING SERPENTSTING=15)
Define(STEADYSHOT 56641)
	SpellInfo(STEADYSHOT inccounter=ss mana=-9)
Define(SILENCINGSHOT 34490)
	SpellInfo(SILENCINGSHOT cd=20 resetcounter=ss)

#Pet spells
Define(GROWL 2649)
	
#Buffs
Define(LOCKANDLOAD 56453)
Define(FRENZYEFFECT 19615)
Define(MARKEDFORDEATH 88691)
Define(FIRE 82926)
Define(BEASTWITHIN 34692)

#Glyphs
Define(GLYPHOFARCANESHOT 56841)

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
	if TargetInRange(GROWL) and Mana(more 39) Spell(KILLCOMMAND)
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
	Spell(CALLOFTHEWILD usable=1)
	#/focus_fire,five_stacks=1,if=!buff.beast_within.up
	if pet.BuffPresent(FRENZYEFFECT stacks=5) and BuffExpires(BEASTWITHIN 0) Spell(FOCUSFIRE)
}

AddIcon help=cd mastery=1
{
	unless BuffPresent(ASPECTOFTHEHAWK) or BuffPresent(ASPECTOFTHEFOX) Spell(ASPECTOFTHEHAWK)
	if TargetDebuffExpires(HUNTERSMARK 2) and TargetDebuffExpires(MARKEDFORDEATH 0) and TargetDeadIn(more 20) Spell(HUNTERSMARK nored=1)
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
	
	#/serpent_sting,if=!ticking&target.health_pct<=90
    if Mana(more 24) and TargetDebuffExpires(SERPENTSTING 0 mine=1) and TargetDeadIn(more 8) #and TargetLifePercent(less 90) 
			Spell(SERPENTSTING)
	#/chimera_shot,if=target.health_pct<=90
	if Mana(more 49) #and TargetLifePercent(less 90) 
		Spell(CHIMERASHOT)
	#/steady_shot,if=buff.pre_improved_steady_shot.up&buff.improved_steady_shot.remains<3
	if Mana(less 40) or Counter(ss equal 1) Spell(STEADYSHOT)
	#/kill_shot
	if TargetLifePercent(less 20) Spell(KILLSHOT)
	#/aimed_shot,if=buff.master_marksman_fire.react
	if BuffPresent(FIRE) Spell(AIMEDSHOT)
	if Glyph(GLYPHOFARCANESHOT)
	{
		#/aimed_shot,if=target.health_pct>80|buff.rapid_fire.up|buff.bloodlust.up
		if TargetLifePercent(more 90) or 
			BuffPresent(RAPIDFIRE) or BuffPresent(heroism) if Mana(more 49) Spell(AIMEDSHOT)
        #/arcane_shot,if=(focus>=66|cooldown.chimera_shot.remains>=5)&(target.health_pct<90&!buff.rapid_fire.up&!buff.bloodlust.up)
		if {Mana(more 65) or spell(CHIMERASHOT)>5} and {TargetLifePercent(less 90) and 
					BuffExpires(RAPIDFIRE) and BuffExpires(heroism)}
			if Mana(more 24) Spell(ARCANESHOT)
	}
	unless Glyph(GLYPHOFARCANESHOT)
	{
		#/aimed_shot,if=cooldown.chimera_shot.remains>5|focus>=80|buff.rapid_fire.up|buff.bloodlust.up|target.health_pct>90
		if {spell(CHIMERASHOT)>5} or Mana(more 79) or BuffPresent(RAPIDFIRE) or BuffPresent(heroism) #or TargetLifePercent(more 90)
			if Mana(more 49) Spell(AIMEDSHOT)
	}
	#/steady_shot
	Spell(STEADYSHOT)
}

AddIcon help=cd mastery=2
{
	unless BuffPresent(ASPECTOFTHEHAWK) or BuffPresent(ASPECTOFTHEFOX) Spell(ASPECTOFTHEHAWK)
	if TargetDebuffExpires(HUNTERSMARK 2) and TargetDebuffExpires(MARKEDFORDEATH 0) and TargetDeadIn(more 20) Spell(HUNTERSMARK nored=1)
	#/rapid_fire,if=!buff.bloodlust.up|target.time_to_die<=30
	unless BuffPresent(heroism) or BuffPresent(RAPIDFIRE) Spell(RAPIDFIRE)
	#/readiness,wait_for_rapid_fire=1
	if BuffPresent(RAPIDFIRE) Spell(READINESS)
	Spell(CALLOFTHEWILD usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=3
{
 	if CheckBoxOn(multi)
	{
		#/multi_shot,if=target.adds>5
		if Mana(more 56) Spell(MULTISHOT)
		#/cobra_shot,if=target.adds>5
		Spell(STEADYSHOT)
	}

	#/serpent_sting,if=!ticking
	if Mana(more 24) and TargetDebuffExpires(SERPENTSTING 0 mine=1) and TargetDeadIn(more 8) Spell(SERPENTSTING)
	#/explosive_shot,if=!ticking&!in_flight
    if TargetDebuffExpires(EXPLOSIVESHOT 0 mine=1) Spell(EXPLOSIVESHOT)
	#/black_arrow,if=!ticking
    if Mana(more 35) and TargetDebuffExpires(BLACKARROW 0 mine=1) Spell(BLACKARROW)
	#/kill_shot
    if TargetLifePercent(less 20) Spell(KILLSHOT)
	#/arcane_shot,if=focus>=70&buff.lock_and_load.down
    if Mana(more 69) and BuffExpires(LOCKANDLOAD) Spell(ARCANESHOT)
	#/cobra_shot
    Spell(COBRASHOT) 
	Spell(STEADYSHOT)
}


AddIcon help=cd mastery=3
{
	unless BuffPresent(ASPECTOFTHEHAWK) or BuffPresent(ASPECTOFTHEFOX) Spell(ASPECTOFTHEHAWK)
	if TargetDebuffExpires(HUNTERSMARK 2) and TargetDebuffExpires(MARKEDFORDEATH 0) and TargetDeadIn(more 20) Spell(HUNTERSMARK nored=1)
	Spell(CALLOFTHEWILD usable=1)
	unless BuffPresent(heroism) Spell(RAPIDFIRE)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}
]]
