Ovale.defaut["MAGE"]=
[[
#Contributed by Hinalover
#Spells
Define(ARCANEBARRAGE 44425) #arcane instant
	SpellInfo(ARCANEBARRAGE cd=4)
    SpellAddDebuff(ARCANEBARRAGE ARCANEBLASTDEBUFF=0)
Define(ARCANEBLAST 30451) #arcane stacks*4 cost increased
    SpellAddDebuff(ARCANEBLAST ARCANEBLASTDEBUFF=10)
Define(ARCANEMISSILES 5143) #arcane channel
    SpellAddDebuff(ARCANEMISSILES ARCANEBLASTDEBUFF=0 ARCANEMISSILEBUFF=0)
Define(ARCANEPOWER 12042) #arcane cd
    SpellInfo(ARCANEPOWER cd=84)
	SpellAddBuff(ARCANEPOWER ARCANEPOWER=15)
Define(COLDSNAP 11958) #frost reset cd
    SpellInfo(COLDSNAP cd=384)
Define(COMBUSTION 11129) #fire cd consume dot
    SpellInfo(COMBUSTION cd=120)
Define(CONJUREMANAGEM 759)
	SpellInfo(CONJUREMANAGEM cd=10) #fake
Define(COUNTERSPELL 2139)
    SpellInfo(COUNTERSPELL cd=24)
Define(DEEPFREEZE 44572) #frost instant
	SpellInfo(DEEPFREEZE cd=30)
    SpellAddBuff(DEEPFREEZE FINGERSOFFROST=-1)
Define(EVOCATION 12051)
    SpellInfo(EVOCATION cd=240)
Define(FIREBLAST 2136) #fire instant
	SpellInfo(FIREBLAST cd=8)
Define(FIREBALL 133) #fire 2.5
Define(FLAMEORB 82731)
    SpellInfo(FLAMEORB cd=60)
Define(FROSTBOLT 116) #frost
Define(FROSTFIREBOLT 44614) #frost+fire
	SpellAddTargetDebuff(FROSTFIREBOLT FROSTFIREBOLT=9)
    SpellAddBuff(FROSTFIREBOLT BRAINFREEZE=-1 FINGERSOFFROST=-1)
Define(ICEARMOR 7302)
	SpellAddBuff(ICEARMOR ICEARMOR=1800)
Define(ICELANCE 30455) #frost instant
    SpellAddBuff(ICELANCE FINGERSOFFROST=-1)
Define(ICYVEINS 12472) #frost cd
    SpellInfo(ICYVEINS cd=144)
Define(LIVINGBOMB 44457) #fire dot
    SpellAddTargetDebuff(LIVINGBOMB LIVINGBOMB=12)
Define(MAGEARMOR 6117)
	SpellAddBuff(MAGEARMOR MAGEARMOR=1800)
Define(MIRRORIMAGE 55342)
    SpellInfo(MIRRORIMAGE cd=180)
Define(MOLTENARMOR 30482)
	SpellAddBuff(MOLTENARMOR MOLTENARMOR=1800)
Define(PYROBLAST 11366) #fire dot
    SpellAddTargetDebuff(PYROBLAST PYROBLAST=12)
    SpellAddBuff(PYROBLAST HOTSTREAK=0)
Define(PYROBLASTBANG 92315)
	SpellAddTargetDebuff(PYROBLASTBANG PYROBLASTBANG=12)
	SpellAddBuff(PYROBLASTBANG HOTSTREAK=0)
Define(SCORCH 2948) #fire 1.5 (cast while moving with firestarter talent)
Define(SPELLSTEAL 30449)
Define(SUMMONWATERELEMENTAL 31687) #frost pet
    SpellInfo(SUMMONWATERELEMENTAL cd=180)

Define(PETFREEZE 33395) #Frost pet freeze ability
    SpellInfo(PETFREEZE cd=25)
	SpellAddBuff(PETFREEZE FINGERSOFFROST=2)
	
#Buff
Define(BRAINFREEZE 57761) #frost (instant fireball/frostfire bolt)
Define(FINGERSOFFROST 44544) #frost boost ice lance/deep freeze
	SpellInfo(FINGERSOFFROST duration=14)
Define(HOTSTREAK 48108) #fire instant pyroblast
Define(ARCANEBLASTDEBUFF 36032)
Define(ARCANEMISSILEBUFF 79683)
Define(PRESENCEOFMIND 12043) #arcane next spell instant
Define(CLEARCASTING 12536)

#Item
Define(MANAGEMITEM 36799)
Define(VOLCANICPOTION 58091)

#Debuff
Define(IGNITE 12654)
Define(CRITICALMASS 22959)
Define(SHADOWANDFLAME 17800)

#Talent
Define(FIRESTARTERTALENT 11431)
Define(CRITICALMASSTALENT 10541)
Define(IMPROVEDSCORCH 10547)

#Glyphs
Define(GLYPHOFFROSTFIRE 61205)
Define(GLYPHOFFROSTBOLT 56370)

ScoreSpells(SCORCH PYROBLAST LIVINGBOMB FROSTFIREBOLT FIREBALL SUMMONWATERELEMENTAL PETFREEZE FROSTBOLT ARCANEBLAST ARCANEMISSILES ARCANEBARRAGE
            DEEPFREEZE ICELANCE)

AddIcon help=main mastery=1
{
    unless InCombat() if BuffExpires(MAGEARMOR 400) and BuffExpires(MOLTENARMOR 400) and BuffExpires(ICEARMOR 400) Spell(MAGEARMOR)
    
	#/arcane_blast,if=target.time_to_die<40&mana_pct>5
	if TargetDeadIn(less 40) and ManaPercent(more 5) Spell(ARCANEBLAST)
	#/arcane_blast,if=cooldown.evocation.remains<30&mana_pct>26
	if {spell(EVOCATION)<30} and ManaPercent(more 26) Spell(ARCANEBLAST)
	#/evocation,if=target.time_to_die>=31
	if TargetDeadIn(more 31) Spell(EVOCATION)
	#/sequence,name=conserve:arcane_blast:arcane_blast:arcane_blast:arcane_blast,if=!buff.bloodlust.up
	unless DebuffPresent(ARCANEBLASTDEBUFF stacks=4) or BuffPresent(heroism) or ManaPercent(less 26)
		Spell(ARCANEBLAST)
	if BuffPresent(ARCANEMISSILEBUFF) Spell(ARCANEMISSILES)
    #/arcane_barrage,if=buff.arcane_blast.stack>0; // when AM hasn't procced
	Spell(ARCANEBARRAGE)
    if Speed(more 0) 
	{
		Spell(ARCANEBARRAGE)
		Spell(FIREBLAST)
		Spell(ICELANCE)
	}
	Spell(ARCANEBLAST)
}

AddIcon help=cd mastery=1
{
    if TargetBuffStealable(yes) Spell(SPELLSTEAL)
    if TargetIsInterruptible(yes) Spell(COUNTERSPELL)
	
	#/conjure_mana_gem,if=cooldown.evocation.remains<44&target.time_to_die>20&mana_gem_charges=0
	if ItemCount(MANAGEMITEM less 1 charges=1) and {spell(EVOCATION)<44} and TargetDeadIn(more 20)
		Spell(CONJUREMANAGEM)
	#if=(cooldown.evocation.remains<30&buff.arcane_blast.stack=4)|cooldown.evocation.remains>90|target.time_to_die<40
	if {{spell(EVOCATION)<30} and DebuffPresent(ARCANEBLASTDEBUFF stacks=4)} or {spell(EVOCATION)>90} or TargetDeadIn(less 40)
	{
		Item(Trinket0Slot usable=1)
		Item(Trinket1Slot usable=1)
		#if ItemCount(VOLCANICPOTION more 0) Item(VOLCANICPOTION)
	}
	
	if {{spell(EVOCATION)<30} and DebuffPresent(ARCANEBLASTDEBUFF stacks=4)} or TargetDeadIn(less 40)
	{
		#action_list_str += "/arcane_power,if=(cooldown.evocation.remains<30&buff.arcane_blast.stack=4)|target.time_to_die<40";
		Spell(ARCANEPOWER)
		#action_list_str += "/mana_gem,if=(cooldown.evocation.remains<30&buff.arcane_blast.stack=4)|target.time_to_die<40";
		if ManaPercent(less 85) Item(MANAGEMITEM)
	}
	
	if ManaPercent(less 10) Item(MANAGEMITEM)
	
    #action_list_str += "/mirror_image,if=buff.arcane_power.up|(cooldown.arcane_power.remains>20&target.time_to_die>15)";
    if BuffPresent(ARCANEPOWER) or {{spell(ARCANEPOWER)>0} and TargetDeadIn(more 15)} Spell(MIRRORIMAGE)
	#/flame_orb,if=target.time_to_die>=10
    if TargetDeadIn(more 10) Spell(FLAMEORB)
	#/presence_of_mind,arcane_blast
    Spell(PRESENCEOFMIND)
}

AddIcon help=main mastery=2
{
    unless InCombat() if BuffExpires(MAGEARMOR 400) and BuffExpires(MOLTENARMOR 400) and BuffExpires(ICEARMOR 400) Spell(MOLTENARMOR)
	#/scorch,debuff=1
    if TalentPoints(CRITICALMASSTALENT more 0) and TargetDebuffExpires(magicalcrittaken 0) Spell(SCORCH)
	#/combustion,if=dot.living_bomb.ticking&dot.ignite.ticking&dot.pyroblast.ticking
    if TargetDebuffPresent(LIVINGBOMB mine=1) and TargetDebuffPresent(IGNITE mine=1) and 
		{TargetDebuffPresent(PYROBLAST mine=1) or TargetDebuffPresent(PYROBLASTBANG mine=1)}
        Spell(COMBUSTION)
	#/living_bomb,if=!ticking
    if TargetDebuffExpires(LIVINGBOMB 0 mine=1) and TargetDeadIn(more 12) Spell(LIVINGBOMB)
	#/pyroblast_hs,if=buff.hot_streak.react
    if BuffPresent(HOTSTREAK) Spell(PYROBLAST)
	#/mage_armor,if=mana_pct<5
	if BuffExpires(MAGEARMOR 0) and ManaPercent(less 5) Spell(MAGEARMOR)
    if TalentPoints(FIRESTARTERTALENT more 0) and Speed(more 0) Spell(SCORCH)
	#/frostfire_bolt
    if Glyph(GLYPHOFFROSTFIRE) Spell(FROSTFIREBOLT usable=1)
	#/fireball
	Spell(FIREBALL usable=1)
    Spell(SCORCH)
}

AddIcon help=cd mastery=2
{
	if TargetBuffStealable(yes) Spell(SPELLSTEAL)
    if TargetIsInterruptible(yes) Spell(COUNTERSPELL)
    
	#if BuffPresent(heroism) or TargetDeadIn(less 40) Item(VOLCANICPOTION)
    #/mana_gem,if=mana_deficit>12500
    if ManaPercent(less 85) Item(MANAGEMITEM)
	#/mirror_image,if=target.time_to_die>=25
	if TargetDeadIn(more 24) Spell(MIRRORIMAGE)
    #/flame_orb,if=target.time_to_die>=12
    if TargetDeadIn(more 11) Spell(FLAMEORB)
    Item(Trinket0Slot usable=1)
    Item(Trinket1Slot usable=1)
}

AddIcon help=main mastery=3
{
    unless InCombat() if BuffExpires(MAGEARMOR 400) and BuffExpires(MOLTENARMOR 400) and BuffExpires(ICEARMOR 400) Spell(MOLTENARMOR)
	if BuffPresent(MAGEARMOR) and ManaPercent(more 45) Spell(MOLTENARMOR)
	
    if PetPresent(no) Spell(SUMMONWATERELEMENTAL)
	
	#/deep_freeze
    Spell(DEEPFREEZE usable=1)
	#/frostfire_bolt,if=buff.brain_freeze.react
    if BuffPresent(BRAINFREEZE) {Spell(FROSTFIREBOLT) Spell(FIREBALL)}
	#/ice_lance,if=buff.fingers_of_frost.stack>1
    if BuffPresent(FINGERSOFFROST stacks=2) Spell(ICELANCE)
	#/ice_lance,if=buff.fingers_of_frost.react&pet.water_elemental.cooldown.freeze.remains<gcd
    unless BuffPresent(FINGERSOFFROST) Spell(PETFREEZE)
	#/mage_armor,if=(mana_pct*12)<target.time_to_die
    if Glyph(GLYPHOFFROSTBOLT) and BuffPresent(MOLTENARMOR) and {{manaPercent()*12} < target.timeToDie()} Spell(MAGEARMOR)
	#/mage_armor,if=(mana_pct*15)<target.time_to_die
	if Glyph(GLYPHOFFROSTBOLT no) and BuffPresent(MOLTENARMOR) and {{manaPercent()*15} < target.timeToDie()} Spell(MAGEARMOR)
	#/evocation,if=mana_pct<5&target.time_to_die>60
    if ManaPercent(less 5) and TargetDeadIn(more 60) Spell(EVOCATION)
	#/ice_lance,moving=1
    if Speed(more 0) Spell(ICELANCE)
	#/fire_blast,moving=1
    if Speed(more 0) Spell(FIREBLAST)
	#/frostbolt
	if Glyph(GLYPHOFFROSTBOLT) Spell(FROSTBOLT)
    if Glyph(GLYPHOFFROSTBOLT no)
	{
		#/frostbolt,if=!cooldown.early_frost.remains
		if castTime(FROSTBOLT) < timeWithHaste(1.5) Spell(FROSTBOLT)
		#/frostfire_bolt
		Spell(FROSTFIREBOLT)
		Spell(FROSTBOLT)
	}
}

AddIcon help=cd mastery=3
{
    #if BuffPresent(heroism) or TargetDeadIn(less 40) Item(VOLCANICPOTION)
    if TargetBuffStealable(yes) Spell(SPELLSTEAL)
    if TargetIsInterruptible(yes) Spell(COUNTERSPELL)
	
	#/mana_gem,if=mana_deficit>12500
    if ManaPercent(less 85) Item(MANAGEMITEM)
	#/cold_snap,if=cooldown.deep_freeze.remains>15&cooldown.frostfire_orb.remains>30&cooldown.icy_veins.remains>30
    unless 15s before Spell(DEEPFREEZE) or 30s before Spell(FLAMEORB) or 30s before Spell(ICYVEINS) Spell(COLDSNAP)
	#/frostfire_orb,if=target.time_to_die>=12
    if TargetDeadIn(more 11) Spell(FLAMEORB)
	#/mirror_image,if=target.time_to_die>=25
    if TargetDeadIn(more 24) Spell(MIRRORIMAGE)
	#/icy_veins,if=buff.icy_veins.down&buff.bloodlust.down
    if BuffExpires(ICYVEINS 0) and BuffExpires(heroism 0) Spell(ICYVEINS)
    Item(Trinket0Slot usable=1)
    Item(Trinket1Slot usable=1)
}

]]