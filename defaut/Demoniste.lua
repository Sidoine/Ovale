Ovale.defaut["WARLOCK"]=
[[
Define(BANEOFAGONY 980)
	Spellinfo(BANEOFAGONY duration=24)
	SpellAddTargetDebuff(BANEOFAGONY BANEOFAGONY=24)
Define(BANEOFDOOM 603)
	SpellInfo(BANEOFDOOM duration=60)
	SpellAddTargetDebuff(BANEOFDOOM BANEOFDOOM=60)
Define(BANEOFHAVOC 80240)
	SpellAddTargetDebuff(BANEOFHAVOC BANEOFHAVOC=300)
Define(CHAOSBOLT 50796)
	SpellInfo(CHAOSBOLT cd=12)
Define(CONFLAGRATE 17962)
	SpellInfo(CONFLAGRATE cd=10)
Define(CORRUPTION 172)
	SpellAddTargetDebuff(CORRUPTION CORRUPTION=18)
Define(CURSEELEMENTS 1490)
	SpellAddTargetDebuff(CURSEELEMENTS CURSEELEMENTS=300)
Define(CURSETONGUES 1714)
	SpellAddTargetDebuff(CURSETONGUES CURSETONGUES=30)
Define(CURSEWEAKNESS 702)
	SpellAddTargetDebuff(CURSEWEAKNESS CURSEWEAKNESS=120)
Define(DARKINTENT 80398)
Define(DEATHCOIL 6789)
	SpellInfo(DEATHCOIL cd=120)
Define(DEMONARMOR 687)
	SpellAddBuff(DEMONARMOR DEMONARMOR=1000)
Define(DEMONICEMPOWERMENT 47193)
	SpellInfo(DEMONICEMPOWERMENT cd=60)
Define(DEMONSOUL 77801)
	SpellInfo(DEMONSOUL cd=120)
Define(DRAINLIFE 689)
	SpellInfo(DRAINLIFE canStopChannelling=3)
	SpellAddTargetDebuff(DRAINLIFE DRAINLIFE=3)
	SpellAddBuff(DRAINLIFE SOULBURN=0)
Define(DRAINSOUL 1120)
	SpellInfo(DRAINSOUL canStopChannelling=5)
	SpellAddTargetDebuff(DRAINSOUL DRAINSOUL=15)
Define(FELARMOR 28176)
	SpellAddBuff(FELARMOR FELARMOR=1000)
Define(FELFLAME 77799)
	SpellAddTargetDebuff(FELFLAME IMMOLATE=refresh UNSTABLEAFFLICTION=refresh)
Define(HANDOFGULDAN 71521)
	SpellInfo(HANDOFGULDAN cd=12)
	SpellAddTargetDebuff(HANDOFGULDAN IMMOLATE=refresh)
Define(HAUNT 48181)
	SpellInfo(HAUNT cd=8)
	SpellAddBuff(HAUNT HAUNT=12)
Define(IMMOLATE 348)
	SpellInfo(IMMOLATE duration=15)
	SpellAddTargetDebuff(IMMOLATE IMMOLATE=15)
	SpellAddBuff(IMMOLATE MOLTENCORE=-1)
Define(IMMOLATIONAURA 50589)
	SpellInfo(IMMOLATIONAURA cd=30)
	SpellAddBuff(IMMOLATIONAURA IMMOLATIONAURA=15)
Define(INCINERATE 29722)
	SpellAddBuff(INCINERATE MOLTENCORE=-1)
Define(LIFETAP 1454)
	SpellInfo(LIFETAP cd=10) #fake
Define(METAMORPHOSIS 47241)
	SpellInfo(METAMORPHOSIS cd=180)
	SpellAddBuff(METAMORPHOSIS METAMORPHOSIS=30)
Define(SEARINGPAIN 5676)
Define(SEEDOFCORRUPTION 27243)
	SpellAddTargetDebuff(SEEDOFCORRUPTION SEEDOFCORRUPTION=18)
Define(SHADOWBOLT 686)
	SpellAddTargetDebuff(SHADOWBOLT SHADOWEMBRACE=12 SHADOWANDFLAMEDEBUFF=30)
Define(SHADOWBURN 17877)
	SpellInfo(SHADOWBURN cd=15)
Define(SHADOWFLAME 47897)
	SpellInfo(SHADOWFLAME cd=12)
Define(SOULFIRE 6353)
	SpellAddBuff(SOULFIRE IMPROVEDSOULFIREBUFF=15 SOULBURN=0)
Define(SOULBURN 74434)
	SpellInfo(SOULBURN cd=45)
	SpellAddBuff(SOULBURN SOULBURN=15)
Define(SUMMONINFERNAL 1122)
	SpellInfo(SUMMONINFERNAL cd=600)
Define(SUMMONDOOMGUARD 18540)
	SpellInfo(SUMMONDOOMGUARD cd=600)
Define(SUMMONFELGUARD 30146)
	SpellInfo(SUMMONFELGUARD cd=600) #fake
Define(SUMMONFELHUNTER 691)
	SpellInfo(SUMMONFELHUNTER cd=600) #fake
Define(SUMMONIMP 688)
	SpellInfo(SUMMONIMP cd=600) #fake
Define(SUMMONSUCCUBUS 712)
	SpellInfo(SUMMONSUCCUBUS cd=600) #fake
Define(UNSTABLEAFFLICTION 30108)
	SpellInfo(UNSTABLEAFFLICTION duration=15)
	SpellAddTargetDebuff(UNSTABLEAFFLICTION UNSTABLEAFFLICTION=15)

#Pet spells
Define(FELSTORM 89751)

#Buff
Define(DECIMATION 63167)
Define(MOLTENCORE 71165)
Define(EMPOWEREDIMP 47283)
Define(IMPROVEDSOULFIREBUFF 85383)
Define(SHADOWTRANCE 17941)
Define(SHADOWANDFLAMEDEBUFF 17800)
Define(DEMONSOULFELGUARD 79462)

#Talent	
Define(IMPROVEDSOULFIRE 10940)
Define(SHADOWANDFLAMETALENT 10936)
Define(BANETALENT 10938)
Define(EMBERSTORMTALENT 11181)

#Glyph
Define(GLYPHOFLASHOFPAIN 70947)
Define(GLYPHOFIMP 56248)
Define(GLYPHOFCORRUPTION 56218)

AddListItem(curse elements SpellName(CURSEELEMENTS))
AddListItem(curse tongues SpellName(CURSETONGUES))
AddListItem(curse weakness SpellName(CURSEWEAKNESS))
AddListItem(curse none L(None) default)
AddListItem(bane agony SpellName(BANEOFAGONY))
AddListItem(bane doom SpellName(BANEOFDOOM) default)
AddListItem(bane havoc SpellName(BANEOFHAVOC) mastery=3)
AddCheckBox(shadowflame SpellName(SHADOWFLAME) default)
AddCheckBox(petswap SpellName(SUMMONFELGUARD) mastery=2)

ScoreSpells(CURSEELEMENTS SHADOWBOLT HAUNT UNSTABLEAFFLICTION IMMOLATE CONFLAGRATE CURSEWEAKNESS
	BANEOFAGONY CORRUPTION SOULFIRE DRAINSOUL INCINERATE SHADOWBOLT CHAOSBOLT)

AddIcon help=main mastery=1
{
	if InCombat(no) and BuffExpires(FELARMOR 400) Spell(FELARMOR)

	if List(curse elements) and TargetDebuffExpires(magicaldamagetaken 0) and TargetDeadIn(more 8) Spell(CURSEELEMENTS)
	if List(curse weakness) and TargetDebuffExpires(CURSEWEAKNESS 2) and TargetDeadIn(more 8) Spell(CURSEWEAKNESS)

	#unless Glyph(GLYPHOFLASHOFPAIN) Spell(DEMONSOUL)
	#/corruption,if=(!ticking|remains<tick_time)&miss_reac
	if TargetDebuffExpires(CORRUPTION 3 haste=spell mine=1) and TargetDebuffExpires(SEEDOFCORRUPTION 0 mine=1) Spell(CORRUPTION)
	#/unstable_affliction,if=(!ticking|remains<(cast_time+tick_time))&target.time_to_die>=5&miss_react
	if TargetDebuffExpires(UNSTABLEAFFLICTION 4.5 mine=1 haste=spell) and TargetDeadIn(more 5) Spell(UNSTABLEAFFLICTION)
	#/bane_of_doom,if=target.time_to_die>15&!ticking&miss_react
	if TargetDebuffExpires(BANEOFDOOM 0 mine=1) and TargetDebuffExpires(BANEOFAGONY 0 mine=1)
	{
		if List(bane doom) and TargetDeadIn(more 15) Spell(BANEOFDOOM)
		if TargetDeadIn(more 10) Spell(BANEOFAGONY)
	}
	#/haunt
	Spell(HAUNT)
	#/fel_flame,if=buff.tier11_4pc_caster.react&dot.unstable_affliction.remains<8
	if ArmorSetParts(T11 more 3) and TargetDebuffExpires(UNSTABLEAFFLICTION 8) Spell(FELFLAME)
	#/drain_soul,interrupt=1,if=target.health_pct<=25
	if TargetLifePercent(less 25) Spell(DRAINSOUL)
	#/shadowflame
	if CheckBoxOn(shadowflame) Spell(SHADOWFLAME)
	
	if TalentPoints(BANETALENT more 2)
	{
		#/life_tap,mana_percentage<=35
		if ManaPercent(less 35) and LifePercent(more 75) Spell(LIFETAP)
		if TalentPoints(EMBERSTORMTALENT more 0) and TalentPoints(IMPROVEDSOULFIRE more 0)
		{
			#/soul_fire,if=buff.improved_soul_fire.cooldown_remains<(cast_time+travel_time)&buff.bloodlust.down&!in_flight
			if BuffExpires(IMPROVEDSOULFIREBUFF 4) and BuffExpires(heroism) Spell(SOULFIRE)
		}
		if TalentPoints(EMBERSTORMTALENT less 1) or TalentPoints(IMPROVEDSOULFIRE less 1)
		{
			#/soul_fire,if=buff.soulburn.up
			if BuffPresent(SOULBURN) Spell(SOULFIRE)
		}
		#if Glyph(GLYPHOFLASHOFPAIN) Spell(DEMONSOUL)
		Spell(SHADOWBOLT)
	}
	if TalentPoints(BANETALENT less 3)
	{
		#/demon_soul,if=buff.shadow_trance.react
		#if BuffPresent(SHADOWTRANCE) Spell(DEMONSOUL)
		#/shadow_bolt,if=buff.shadow_trance.react
		if BuffPresent(SHADOWTRANCE) Spell(SHADOWBOLT)
		#/life_tap,mana_percentage<=5
		if ManaPercent(less 5) and LifePercent(more 75) Spell(LIFETAP)
		if TalentPoints(IMPROVEDSOULFIRE more 0)
		{
			#/soul_fire,if=buff.improved_soul_fire.cooldown_remains<(cast_time+travel_time)&buff.bloodlust.down&!in_flight
			if TalentPoints(EMBERSTORMTALENT more 0) if BuffExpires(IMPROVEDSOULFIREBUFF 4) and BuffExpires(heroism) Spell(SOULFIRE)
			#/soul_fire,if=buff.soulburn.up
			if TalentPoints(EMBERSTORMTALENT less 1) if BuffPresent(SOULBURN) Spell(SOULFIRE)
		}
		#/drain_life,interrupt=1
		Spell(DRAINLIFE)
	}
}

AddIcon help=cd mastery=1
{
	#/summon_infernal
	Spell(DEMONSOUL)
	Spell(SUMMONDOOMGUARD)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=2
{	
	if InCombat(no) and BuffExpires(FELARMOR 400) Spell(FELARMOR)

	if List(curse elements) and TargetDebuffExpires(magicaldamagetaken 2) and TargetDeadIn(more 8) Spell(CURSEELEMENTS)
	if List(curse weakness) and TargetDebuffExpires(CURSEWEAKNESS 2) and TargetDeadIn(more 8) Spell(CURSEWEAKNESS)

	
	#/immolate,if=!ticking&target.time_to_die>=4&miss_react
	if TargetDebuffExpires(IMMOLATE 2 mine=1 haste=spell) and TargetDeadIn(more 4) Spell(IMMOLATE)
	
	#/bane_of_doom,if=(!ticking|(buff.metamorphosis.up&remains<45))&target.time_to_die>=15&miss_react
	if {TargetDebuffExpires(BANEOFDOOM 0 mine=1) or {BuffPresent(METAMORPHOSIS) and TargetDebuffExpires(BANEOFDOOM 45 mine=1)}} and TargetDebuffExpires(BANEOFAGONY 0 mine=1)
	{
		if List(bane doom) and TargetDeadIn(more 15) Spell(BANEOFDOOM)
		if TargetDeadIn(more 10) Spell(BANEOFAGONY)
	}
	#/corruption,if=(remains<tick_time|!ticking)&target.time_to_die>=6&miss_react
	if TargetDebuffExpires(CORRUPTION 2 mine=1 haste=spell) and TargetDebuffExpires(SEEDOFCORRUPTION 0 mine=1) and TargetDeadIn(more 6) Spell(CORRUPTION)
	#/fel_flame,if=buff.tier11_4pc_caster.react
	if ArmorSetParts(T11 more 3) Spell(FELFLAME)
	#/shadowflame
	if CheckBoxOn(shadowflame) and TargetInRange(DEATHCOIL) Spell(SHADOWFLAME)
	#/hand_of_guldan
	if TargetDebuffPresent(IMMOLATE) Spell(HANDOFGULDAN)
	#/immolation,if=buff.metamorphosis.remains>10
	if BuffPresent(METAMORPHOSIS 10) and TargetInRange(DEATHCOIL) Spell(IMMOLATIONAURA)
	#if ( glyphs.corruption -> ok() ) action_list_str += "/shadow_bolt,if=buff.shadow_trance.react";
	if Glyph(GLYPHOFCORRUPTION) and BuffPresent(SHADOWTRANCE) Spell(SHADOWBOLT)
	#/incinerate,if=buff.molten_core.react
	if BuffPresent(MOLTENCORE) Spell(INCINERATE)
	#/soul_fire,if=buff.decimation.up
	if BuffPresent(DECIMATION) Spell(SOULFIRE)
	#/life_tap,if=mana_pct<=30&buff.bloodlust.down&buff.metamorphosis.down&buff.demon_soul_felguard.down
	if ManaPercent(less 30) and BuffExpires(heroism) and BuffExpires(METAMORPHOSIS) and BuffExpires(DEMONSOULFELGUARD) and LifePercent(more 75) Spell(LIFETAP)
	if TalentPoints(BANETALENT more 0) Spell(SHADOWBOLT)
	Spell(INCINERATE)
}

AddIcon help=cd mastery=2
{
	#/summon_felguard,if=cooldown.demon_soul.remains<5&cooldown.metamorphosis.remains<5&!pet.felguard.active
	if CheckBoxOn(petswap) and {spell(DEMONSOUL)<5} and {spell(METAMORPHOSIS)<5} unless pet.CreatureFamily(Felguard) Spell(SUMMONFELGUARD)
	#/metamorphosis,if=pet.felguard.active
	if pet.Present() and pet.CreatureFamily(Felguard) Spell(METAMORPHOSIS)
	#/demon_soul,if=buff.metamorphosis.up
	if BuffPresent(METAMORPHOSIS) Spell(DEMONSOUL)
	#/summon_doomguard,if=time>10
	if TimeInCombat(more 10) Spell(SUMMONDOOMGUARD)
	#/felguard:felstorm
	if pet.Present() and pet.CreatureFamily(Felguard) Spell(FELSTORM)
	if CheckBoxOn(petswap)
	{
		#/soulburn,if=pet.felguard.active&!pet.felguard.dot.felstorm.ticking
		if pet.CreatureFamily(Felguard) and pet.BuffExpires(FELSTORM) Spell(SOULBURN)
		#/summon_felhunter,if=!pet.felguard.dot.felstorm.ticking&pet.felguard.active
		if pet.BuffExpires(FELSTORM) and pet.CreatureFamily(Felguard) Spell(SUMMONFELHUNTER)
	}
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}
	
AddIcon help=main mastery=3
{
	if InCombat(no) and BuffExpires(FELARMOR 400) Spell(FELARMOR)
	
	if List(curse elements) and TargetDebuffExpires(magicaldamagetaken 2) and TargetDeadIn(more 8) Spell(CURSEELEMENTS)
	if List(curse weakness) and TargetDebuffExpires(CURSEWEAKNESS 2) and TargetDeadIn(more 8) Spell(CURSEWEAKNESS)

	#/soul_fire,if=buff.soulburn.up
	if BuffPresent(SOULBURN) Spell(SOULFIRE)
	#/fel_flame,if=buff.tier11_4pc_caster.react&dot.immolate.remains<8
	if ArmorSetParts(T11 more 3) and TargetDebuffExpires(IMMOLATE 8 mine=1) Spell(FELFLAME)
	#/immolate,if=(remains<cast_time+gcd|!ticking)&target.time_to_die>=4&miss_react
	if TargetDebuffExpires(IMMOLATE 2 mine=1 haste=spell) and TargetDeadIn(more 4) Spell(IMMOLATE)
	#/conflagrate
	if 1s after TargetDebuffPresent(IMMOLATE mine=1) Spell(CONFLAGRATE)
	#/immolate,if=buff.bloodlust.react&buff.bloodlust.remains>32&cooldown.conflagrate.remains<=3&remains<12
	if BuffPresent(heroism 32) and {spell(CONFLAGRATE)<3} and TargetDebuffExpires(IMMOLATE 12 mine=1) Spell(IMMOLATE)
	#/bane_of_doom,if=!ticking&target.time_to_die>=15&miss_react
	if TargetDebuffExpires(BANEOFDOOM 0 mine=1) and TargetDebuffExpires(BANEOFAGONY 0 mine=1)
	{
		if List(bane doom) and TargetDeadIn(more 15) Spell(BANEOFDOOM)
		if TargetDeadIn(more 10) unless List(bane havoc) Spell(BANEOFAGONY)
	}
	#/corruption,if=(!ticking|dot.corruption.remains<tick_time)&miss_react
	if TargetDebuffExpires(CORRUPTION 2 mine=1 haste=spell) and TargetDebuffExpires(SEEDOFCORRUPTION 0 mine=1) and TargetDeadIn(more 9) Spell(CORRUPTION)
	#/shadowflame
	if CheckBoxOn(shadowflame) Spell(SHADOWFLAME)
	#/chaos_bolt,if=cast_time>0.9
	if {castTime(CHAOSBOLT) > 0.9} Spell(CHAOSBOLT)
	if TalentPoints(IMPROVEDSOULFIRE more 0)
	{
		#((buff.empowered_imp.react&buff.empowered_imp.remains<(buff.improved_soul_fire.remains+action.soul_fire.travel_time))
		if BuffPresent(EMPOWEREDIMP) and {buffExpires(EMPOWEREDIMP) < {buffExpires(IMPROVEDSOULFIREBUFF) + 1}}
			Spell(SOULFIRE)
		#|buff.improved_soul_fire.remains<(cast_time+travel_time+action.incinerate.cast_time+gcd))
		if buffExpires(IMPROVEDSOULFIREBUFF)< {castTime(SOULFIRE)+ 1 +castTime(INCINERATE)+timeWithHaste(1.5)} 
			Spell(SOULFIRE)
	}
	#/shadowburn
	Spell(SHADOWBURN usable=1)
    Spell(INCINERATE)
}

AddIcon help=cd mastery=3
{
	Spell(DEMONSOUL)
	if BuffPresent(heroism) Spell(SUMMONDOOMGUARD)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon size=small
{
	if SoulShards(more 0) Spell(SOULBURN usable=1)
}

AddIcon size=small mastery=1
{
    unless PetPresent()
    {
        if Glyph(GLYPHOFLASHOFPAIN) Spell(SUMMONSUCCUBUS)
        if Glyph(GLYPHOFIMP) Spell(SUMMONIMP)
		Spell(SUMMONFELHUNTER)
    }
}

AddIcon size=small mastery=2
{
    unless PetPresent()
	{
		if Glyph(GLYPHOFLASHOFPAIN) Spell(SUMMONSUCCUBUS)
        if Glyph(GLYPHOFIMP) Spell(SUMMONIMP)
		Spell(SUMMONFELGUARD)
	}
}

AddIcon size=small mastery=3
{
    unless PetPresent() Spell(SUMMONIMP)
}

]]
