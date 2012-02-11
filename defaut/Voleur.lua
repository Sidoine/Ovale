Ovale.defaut["ROGUE"] =
[[
#Abilities
Define(ADRENALINERUSH 13750)
	SpellInfo(ADRENALINERUSH cd=180)
	SpellAddBuff(ADRENALINERUSH ADRENALINERUSH=15)
Define(AMBUSH 8676)
	SpellInfo(AMBUSH combo=2 mana=60)
Define(BACKSTAB 53)
	SpellInfo(BACKSTAB combo=1 mana=60)
Define(BLADEFLURRY 13877)
	SpellAddBuff(BLADEFLURRY BLADEFLURRY=1000 cd=10)
Define(CLOACKOFSHADOWS 31224)
	SpellInfo(CLOACKOFSHADOWS cd=90)
Define(COLDBLOOD 14177)
	SpellInfo(COLDBLOOD cd=120)
	SpellAddBuff(COLDBLOOD COLDBLOOD=100)
Define(ENVENOM 32645)
	SpellInfo(ENVENOM combo=-5)
	SpellAddBuff(ENVENOM ENVENOM=5 mana=35)
Define(EVISCERATE 2098)
	SpellInfo(EVISCERATE combo=-5 mana=35)
Define(HEMORRHAGE 16511)
	SpellInfo(HEMORRHAGE combo=1 mana=35)
	SpellAddTargetDebuff(HEMORRHAGE HEMORRHAGE=60)
Define(KICK 1766)
Define(KILLINGSPREE 51690)
	SpellInfo(KILLINGSPREE cd=120)
	SpellAddBuff(KILLINGSPREE KILLINGSPREE=2)
Define(GARROTE 703)
	SpellInfo(GARROTE combo=1 mana=45)
	SpellAddTargetDebuff(GARROTE GARROTE=18)
Define(MUTILATE 1329)
	SpellInfo(MUTILATE combo=1 mana=60)
Define(PREMEDITATION 14183)
	SpellInfo(PREMEDITATION cd=20 combo=2)
Define(PREPARATION 14185)
	SpellInfo(PREPARATION cd=300)
Define(RECUPERATE 73651)
	SpellInfo(RECUPERATE combo=-5 mana=30)
	SpellAddBuff(RECUPERATE RECUPERATE=30)
Define(REVEALINGSTRIKE 84617)
	SpellInfo(REVEALINGSTRIKE combo=1 mana=40)
	SpellAddTargetDebuff(REVEALINGSTRIKE REVEALINGSTRIKE=15)
Define(RUPTURE 1943)
	SpellInfo(RUPTURE combo=-5 mana=25)
	SpellAddTargetDebuff(RUPTURE RUPTURE=8)
Define(SINISTERSTRIKE 1752)
	SpellInfo(SINISTERSTRIKE combo=1 mana=45)
Define(SHADOWDANCE 51713)
	SpellInfo(SHADOWDANCE cd=60)
	SpellAddBuff(SHADOWDANCE SHADOWDANCE=6)
Define(SHADOWSTEP 36554)
	SpellInfo(SHADOWSTEP cd=20)
	SpellAddBuff(SHADOWSTEP SHADOWSTEPBUFF=10)
Define(SLICEANDDICE 5171)
	SpellInfo(SLICEANDDICE combo=-5 mana=25)
	SpellAddBuff(SLICEANDDICE SLICEANDDICE=10)
Define(STEALTH 1784)
Define(TRICKSOFTHETRADE 57934)
	SpellInfo(TRICKSOFTHETRADE cd=30)
Define(VANISH 1856)
	SpellInfo(VANISH cd=180)
	SpellAddBuff(VANISH VANISHBUFF=3)
Define(VENDETTA 79140)
	SpellInfo(VENDETTA cd=120)
	SpellAddTargetDebuff(VENDETTA VENDETTA=30)
	
#Buffs
Define(SHADOWSTEPBUFF 36563)	
Define(VANISHBUFF 11327)
Define(SHALLOWINSIGHT 84745)
Define(MODERATEINSIGHT 84746)
Define(OVERKILL 58426)
Define(MASTEROFSUBTLETY 31223)
Define(FINDWEAKNESS 91023)
SpellList(DEEPINSIGHT 84745 84746 84747)

#Items
Define(INSTANTPOISON 6947)
Define(DEADLYPOISON 2892)

#Talents
Define(TALENTCUTTOTHECHASE 2070)
Define(TALENTENERGETICRECOVERY 11665)
Define(TALENTHEMORRHAGE 681)


ScoreSpells(SLICEANDDICE HUNGERFORBLOOD ENVENOM RUPTURE EVISCERATE MUTILATE SINISTERSTRIKE)

AddIcon help=main mastery=1
{
	unless InCombat()
	{
		if WeaponEnchantExpires(mainhand 300) Item(INSTANTPOISON)
		if WeaponEnchantExpires(offhand 300) Item(DEADLYPOISON)
	}

	#actions+=/garrote
	if BuffPresent(STEALTH) Spell(GARROTE)

	#actions+=/slice_and_dice,if=buff.slice_and_dice.down
	unless BuffPresent(SLICEANDDICE) if ComboPoints(more 0)	Spell(SLICEANDDICE)

	#/rupture,if=!ticking&time<6
	if TargetDebuffExpires(RUPTURE mine=1) and TimeInCombat(less 6) and ComboPoints(more 0) Spell(RUPTURE)
	#/vendetta
	if TargetDebuffExpires(VENDETTA) and TargetDeadIn(more 20) Spell(VENDETTA)
	
	#actions+=/rupture,if=!ticking&buff.slice_and_dice.remains>6
	if TargetDebuffExpires(RUPTURE 0 mine=1) and BuffPresent(SLICEANDDICE 6) and ComboPoints(more 0)
		Spell(RUPTURE)

	#actions+=/cold_blood,sync=envenom ??
	#if ComboPoints(more 4) and BuffPresent(SLICEANDDICE 6) and TargedDebuffPresent(RUPTURE 5)
	#	Spell(COLDBLOOD)

	#/envenom,if=combo_points>=4&buff.envenom.down
	#/envenom,if=combo_points>=4&energy>90
	if ComboPoints(more 3) and {BuffExpires(ENVENOM) or Mana(more 89)} Spell(ENVENOM)
	#/envenom,if=combo_points>=2&buff.slice_and_dice.remains<3
	if TalentPoints(TALENTCUTTOTHECHASE more 0) and ComboPoints(more 1) and BuffExpires(SLICEANDDICE 3) Spell(ENVENOM)
	
	#/backstab,if=combo_points<5&target.health_pct<35
	if ComboPoints(less 5) and TargetLifePercent(less 35) Spell(BACKSTAB)
	#/mutilate,if=combo_points<4&target.health_pct>=35
	if ComboPoints(less 4) and TargetLifePercent(more 35) Spell(MUTILATE)
	
}

AddIcon help=cd mastery=1
{
	#actions+=/kick
	if TargetIsInterruptible(yes) and TargetInRange(KICK) Spell(KICK)
	if Mana(less 70) Spell(COLDBLOOD)
	#actions+=/vanish,if=time>30&energy>50
	if {spell(VANISH)>30} and Mana(more 50) unless BuffPresent(OVERKILL) Spell(VANISH)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=2
{
	unless InCombat()
	{
		if WeaponEnchantExpires(mainhand 300) Item(INSTANTPOISON)
		if WeaponEnchantExpires(offhand 300) Item(DEADLYPOISON)
	}

	#slice_and_dice,if=buff.slice_and_dice.down
	#slice_and_dice,if=buff.slice_and_dice.remains<2
	if BuffExpires(SLICEANDDICE 2) and ComboPoints(more 0)
		Spell(SLICEANDDICE)

	#killing_spree,if=energy<35&buff.slice_and_dice.remains>4&buff.adrenaline_rush.down
	if Mana(less 35) and BuffPresent(SLICEANDDICE 4) and BuffExpires(ADRENALINERUSH) 
		Spell(KILLINGSPREE)

	#adrenaline_rush,if=energy<35
	unless BuffPresent(KILLINGSPREE) if Mana(less 35) Spell(ADRENALINERUSH)

	#eviscerate,if=combo_points=5&buff.bandits_guile.stack>=12
	if ComboPoints(more 4) and BuffPresent(SLICEANDDICE 4) and BuffPresent(DEEPINSIGHT 12)
		Spell(EVISCERATE)

	#rupture,if=!ticking&combo_points=5&target.time_to_die>10
	if TargetDebuffExpires(RUPTURE 0 mine=1) and ComboPoints(more 4) and TargetDeadIn(more 10)
		Spell(RUPTURE)

	#eviscerate,if=combo_points=5
	if ComboPoints(equal 5) Spell(EVISCERATE)

	#revealing_strike,if=combo_points=4&buff.revealing_strike.down
	if ComboPoints(equal 4) and TargetDebuffExpires(REVEALINGSTRIKE 0 mine=1) Spell(REVEALINGSTRIKE)

	#sinister_strike,if=combo_points<5
	if ComboPoints(less 5) Spell(SINISTERSTRIKE)
}

AddIcon help=aoe mastery=2
{
	unless BuffPresent(BLADEFLURRY) Spell(BLADEFLURRY)
	if BuffPresent(DEEPINSIGHT)
	{
		unless BuffPresent(ADRENALINERUSH) Spell(KILLINGSPREE)
	}
}

AddIcon help=cd mastery=2
{
	#actions+=/kick
	if TargetIsInterruptible(yes) and TargetInRange(KICK) Spell(KICK)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=3
{
	unless InCombat()
	{
		if WeaponEnchantExpires(mainhand 400) Item(INSTANTPOISON)
		if WeaponEnchantExpires(offhand 400) Item(DEADLYPOISON)
	}

	if BuffPresent(STEALTH) or BuffPresent(VANISHBUFF)
	{
		#/premeditation,if=(combo_points<=3&cooldown.honor_among_thieves.remains>1.75)|combo_points<=2
		if ComboPoints(less 3) Spell(PREMEDITATION)
		#Spell(GARROTE)
		#/ambush,if=combo_points<=4
		if ComboPoints(less 5) Spell(AMBUSH)
	}
	
	#/slice_and_dice,if=buff.slice_and_dice.remains<3&combo_points=5
	if BuffExpires(SLICEANDDICE 3) and ComboPoints(more 4) Spell(SLICEANDDICE)
	#/rupture,if=combo_points=5&!ticking
	if ComboPoints(more 4) and TargetDebuffExpires(RUPTURE 0 mine=1) Spell(RUPTURE)
	#/recuperate,if=combo_points=5&remains<3
	if TalentPoints(TALENTENERGETICRECOVERY more 2) and ComboPoints(more 4) and BuffExpires(RECUPERATE 3) Spell(RECUPERATE)
	#/eviscerate,if=combo_points=5&dot.rupture.remains>1
	if ComboPoints(more 4) and TargetDebuffPresent(RUPTURE 1 mine=1) Spell(EVISCERATE)
	
	if TalentPoints(TALENTHEMORRHAGE more 0)
	{
		#/hemorrhage,if=combo_points<4&energy>40&dot.hemorrhage.remains<4";
		if ComboPoints(less 4) and Mana(more 40) and TargetDebuffExpires(HEMORRHAGE 4 mine=1) Spell(HEMORRHAGE)
        #/hemorrhage,if=combo_points<5&energy>80&dot.hemorrhage.remains<4";
		if ComboPoints(less 5) and Mana(more 80) and TargetDebuffExpires(HEMORRHAGE 4 mine=1) Spell(HEMORRHAGE)
	}
		
	#/backstab,if=combo_points<4&energy>40&energy<80";
	if ComboPoints(less 4) and Mana(more 40) Spell(BACKSTAB)
	#/backstab,if=combo_points<5&energy>80
	if ComboPoints(less 5) and Mana(more 80) Spell(BACKSTAB)
}

AddIcon help=cd mastery=3
{
	#actions+=/kick
	if TargetIsInterruptible(yes) and TargetInRange(KICK) Spell(KICK)
	
	#/shadow_dance,if=energy>85&combo_points<5&buff.stealthed.down
	if Mana(more 84) and ComboPoints(less 5) and BuffExpires(STEALTH) Spell(SHADOWDANCE)
	#/vanish,if=time>10&energy>60&combo_points<=1&cooldown.shadowstep.remains<=0&!buff.shadow_dance.up
	#/vanish,if=time>10&energy>60&combo_points<=1&cooldown.shadowstep.remains<=0&!buff.shadow_dance.up&!buff.master_of_subtlety.up&!buff.find_weakness.up
	if TimeInCombat(more 10) and Mana(more 60) and ComboPoints(less 2) and Spell(SHADOWSTEP) and BuffExpires(SHADOWDANCE) and BuffExpires(MASTEROFSUBTLETY) and TargetDebuffExpires(FINDWEAKNESS mine=1)
			Spell(VANISH)
	#/shadowstep,if=buff.stealthed.up|buff.shadow_dance.up
	if BuffPresent(STEALTH) or BuffPresent(SHADOWDANCE) or BuffPresent(VANISHBUFF) Spell(SHADOWSTEP)
	#/preparation,if=cooldown.vanish.remains>60
	unless 60s before Spell(VANISH) Spell(PREPARATION)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon size=small
{
	Spell(TRICKSOFTHETRADE)
}

AddIcon size=small
{
	Spell(CLOACKOFSHADOWS)
}

]]