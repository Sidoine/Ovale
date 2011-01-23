Ovale.defaut["ROGUE"] =
[[
#Abilities
Define(ADRENALINERUSH 13750)
	SpellInfo(ADRENALINERUSH cd=180)
	SpellAddBuff(ADRENALINERUSH ADRENALINERUSH=15)
Define(AMBUSH 8676)
	SpellInfo(AMBUSH combo=2 mana=60)
Define(BACKSTAB 53)
	SpellInfo(BACKSTAB combo=1)
Define(BLADEFLURRY 13877)
	SpellAddBuff(BLADEFLURRY BLADEFLURRY=15 cd=30)
Define(CLOACKOFSHADOWS 31224)
	SpellInfo(CLOACKOFSHADOWS cd=90)
Define(COLDBLOOD 14177)
	SpellInfo(COLDBLOOD cd=120)
Define(ENVENOM 32645)
	SpellInfo(ENVENOM combo=-5)
Define(EVISCERATE 2098)
	SpellInfo(EVISCERATE combo=-5)
Define(HEMORRHAGE 16511)
	SpellInfo(HEMORRHAGE combo=1)
Define(KILLINGSPREE 51690)
	SpellInfo(KILLINGSPREE cd=120)
	SpellAddBuff(KILLINGSPREE KILLINGSPREE=2)
Define(GARROTE 703)
	SpellAddTargetDebuff(GARROTE GARROTE=18)
Define(MUTILATE 1329)
	SpellInfo(MUTILATE combo=1)
Define(PREMEDITATION 14183)
	SpellInfo(PREMEDITATION cd=20)
Define(PREPARATION 14185)
	SpellInfo(PREPARATION cd=300)
Define(REVEALINGSTRIKE 84617)
	SpellInfo(REVEALINGSTRIKE combo=1)
	SpellAddTargetDebuff(REVEALINGSTRIKE REVEALINGSTRIKE=15)
Define(RUPTURE 1943)
	SpellInfo(RUPTURE combo=-5)
	SpellAddTargetDebuff(RUPTURE RUPTURE=8)
Define(SINISTERSTRIKE 1752)
	SpellInfo(SINISTERSTRIKE combo=1)
Define(SHADOWDANCE 51713)
	SpellInfo(SHADOWDANCE cd=60)
	SpellAddBuff(SHADOWDANCE SHADOWDANCE=6)
Define(SHADOWSTEP 36554)
	SpellInfo(SHADOWSTEP cd=20)
	SpellAddBuff(SHADOWSTEP SHADOWSTEPBUFF=10)
Define(SLICEANDDICE 5171)
	SpellInfo(SLICEANDDICE combo=-5)
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

#Items
Define(INSTANTPOISON 43231)
Define(DEADLYPOISON 43233)

#Talents
Define(TALENTCUTTOTHECHASE 2070)

ScoreSpells(SLICEANDDICE HUNGERFORBLOOD ENVENOM RUPTURE EVISCERATE MUTILATE SINISTERSTRIKE)

AddIcon help=main mastery=1
{
	unless InCombat()
	{
		if WeaponEnchantExpires(mainhand 400) Item(INSTANTPOISON)
		if WeaponEnchantExpires(offhand 400) Item(DEADLYPOISON)
	}
	
	if BuffPresent(STEALTHED) Spell(GARROTE)
	unless BuffPresent(SLICEANDDICE) if ComboPoints(more 0)	Spell(SLICEANDDICE)
	if TargetDebuffExpires(VENDETTA) and TargetDeadIn(more 20) Spell(VENDETTA)
	
	if ComboPoints(more 3)
	{
		#rupture,if=!ticking&combo_points>=4&target.time_to_die>15&buff.slice_and_dice.remains>6
		if TargetDebuffExpires(RUPTURE 0 mine=1) and TargetDeadIn(more 15) and BuffPresent(SLICEANDDICE 6)
			Spell(RUPTURE)
		#envenom,if=combo_points>=4&buff.envenom.down
		#envenom,if=combo_points>=4&energy>90
		if BuffExpires(ENVENOM 0) or Mana(more 89) Spell(ENVENOM)
	}
	
	#envenom,if=combo_points>=2&buff.slice_and_dice.remains<2
	if TalentPoints(TALENTCUTTOTHECHASE more 0) and ComboPoints(more 1) and BuffExpires(SLICEANDDICE 2)
		Spell(ENVENOM)
	
	if ComboPoints(less 4)
	{
		#backstab,if=combo_points<4&target.health_pct<35
		if TargetLifePercent(less 35) Spell(BACKSTAB)
		Spell(MUTILATE)
	}
}

AddIcon help=cd mastery=1
{
	if Mana(less 70) Spell(COLDBLOOD)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
	if Mana(more 50) Spell(VANISH)
}

AddIcon help=main mastery=2
{
	unless InCombat()
	{
		if WeaponEnchantExpires(mainhand 400) Item(INSTANTPOISON)
		if WeaponEnchantExpires(offhand 400) Item(DEADLYPOISON)
	}

	#slice_and_dice,if=buff.slice_and_dice.down&time<4
	#slice_and_dice,if=buff.slice_and_dice.remains<2&combo_points>=3
	if {BuffExpires(SLICEANDDICE 0) and ComboPoints(more 0)} or {BuffExpires(SLICEANDDICE 2) and ComboPoints(more 2)}
		Spell(SLICEANDDICE)
	
	#rupture,if=!ticking&combo_points=5&target.time_to_die>10
	if ComboPoints(more 4) and TargetDebuffExpires(RUPTURE 0 mine=1) and TargetDeadIn(more 10) Spell(RUPTURE)
	#eviscerate,if=combo_points=5&buff.slice_and_dice.remains>7&dot.rupture.remains>6
	if ComboPoints(more 4) and BuffPresent(SLICEANDDICE 7) and TargetDebuffPresent(RUPTURE 6 mine=1) Spell(EVISCERATE)
	#eviscerate,if=combo_points>=4&buff.slice_and_dice.remains>4&energy>40&dot.rupture.remains>5
	if ComboPoints(more 3) and BuffPresent(SLICEANDDICE 4) and Mana(more 40) and TargetDebuffPresent(RUPTURE 5 mine=1)
		Spell(EVISCERATE)
	#eviscerate,if=combo_points=5&target.time_to_die<10
	if ComboPoints(more 4) and TargetDeadIn(less 10) Spell(EVISCERATE)
	#revealing_strike,if=combo_points=4&buff.slice_and_dice.remains>8
	if ComboPoints(equal 4) and BuffPresent(SLICEANDDICE 8) Spell(REVEALINGSTRIKE)
	#sinister_strike,if=combo_points<5
	if ComboPoints(less 5) Spell(SINISTERSTRIKE)
}

AddIcon help=cd mastery=2
{
	#adrenaline_rush,if=energy<20
	unless BuffPresent(KILLINGSPREE) if Mana(less 20) Spell(ADRENALINERUSH)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddIcon help=aoe mastery=2
{
	Spell(BLADEFLURRY)
	unless BuffPresent(ADRENALINERUSH) Spell(KILLINGSPREE)
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
		Spell(PREMEDITATION)
		Spell(GARROTE)
		#ambush,if=combo_points<=2
		if ComboPoints(less 3) Spell(AMBUSH)
	}
	
	#slice_and_dice,if=buff.slice_and_dice.remains<2
	if BuffExpires(SLICEANDDICE 2) and ComboPoints(more 0) Spell(SLICEANDDICE)
	#rupture,if=combo_points=5&!ticking
	if ComboPoints(more 4) and TargetDebuffExpires(RUPTURE 0 mine=1) Spell(RUPTURE)
	#recuperate,if=combo_points=5&dot.rupture.remains>8&buff.slice_and_dice.remains>8
	#eviscerate,if=combo_points=5&dot.rupture.remains>1
	if ComboPoints(more 4) and TargetDebuffPresent(RUPTURE 1 main=1) Spell(EVISCERATE)
	#eviscerate,if=combo_points>=4&buff.shadow_dance.up
	if ComboPoints(more 3) and BuffPresent(SHADOWDANCE) Spell(EVISCERATE)
	#backstab,if=combo_points<4
	if ComboPoints(less 4) Spell(BACKSTAB)
	#backstab,if=cooldown.honor_among_thieves.remains>1.75
	#TODO: need a rogue to test how to know when the last combo point was gained
	Spell(BACKSTAB)
}

AddIcon help=cd mastery=3
{
	#shadow_dance,if=time>10&energy>75&combo_points<=1&cooldown.shadowstep.remains<=0
	if Mana(more 75) and ComboPoints(less 2) and Spell(SHADOWSTEP) Spell(SHADOWDANCE)
	#vanish,if=time>10&energy>60&combo_points<=1&cooldown.shadowstep.remains<=0&!buff.shadow_dance.up
	if Mana(more 60) and ComboPoints(less 2) and Spell(SHADOWSTEP) and BuffExpires(SHADOWDANCE 0) Spell(VANISH)
	#actions+=/shadowstep,if=buff.stealthed.up|buff.shadow_dance.up
	if BuffPresent(STEALTH) or BuffPresent(SHADOWDANCE) or BuffPresent(VANISHBUFF) Spell(SHADOWSTEP)
	#preparation,if=cooldown.vanish.remains>60
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