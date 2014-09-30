local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_druid"
	local desc = "[5.4.8] Ovale: Balance, Feral, Guardian, Restoration"
	local code = [[
# Ovale druid script based on SimulationCraft.

Include(ovale_common)
Include(ovale_druid_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default specialization=feral)
AddCheckBox(opt_potion_intellect ItemName(jade_serpent_potion) default specialization=balance)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(jade_serpent_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction InterruptActions
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if Stance(druid_bear_form) and target.InRange(skull_bash_bear) Spell(skull_bash_bear)
		if Stance(druid_cat_form) and target.InRange(skull_bash_cat) Spell(skull_bash_cat)
		if target.Classification(worldboss no)
		{
			if Talent(mighty_bash_talent) and target.InRange(mighty_bash) Spell(mighty_bash)
			if Talent(typhoon_talent) and target.InRange(skull_bash_cat) Spell(typhoon)
			if Stance(druid_cat_form) and ComboPoints() > 0 and target.InRange(maim) Spell(maim)
			Spell(solar_beam)
		}
	}
}

AddFunction FaerieFire
{
	if Talent(faerie_swarm_talent) Spell(faerie_swarm)
	if Talent(faerie_swarm_talent no) Spell(faerie_fire)
}

AddFunction SavageRoar
{
	if Glyph(glyph_of_savagery) Spell(savage_roar_glyphed)
	if Glyph(glyph_of_savagery no) and ComboPoints() > 0 Spell(savage_roar)
}

###
### Balance
###
# Based on SimulationCraft profile "Druid_Balance_T16H".
#	class=druid
#	spec=balance
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Ua!.0.1.0

# ActionList: BalanceDefaultActions --> main, shortcd, cd

AddFunction BalanceDefaultActions
{
	#healing_touch,if=talent.dream_of_cenarius.enabled&!buff.dream_of_cenarius.up&mana.pct>25
	if Talent(dream_of_cenarius_talent) and not BuffPresent(dream_of_cenarius_caster_buff) and ManaPercent() > 25 Spell(healing_touch)
	#starsurge
	Spell(starsurge)
	#moonfire,cycle_targets=1,if=dot.moonfire.remains<1|action.moonfire.tick_damage%dot.moonfire.tick_dmg>=1.3
	if target.DebuffRemaining(moonfire_debuff) < 1 or target.Damage(moonfire_debuff) / target.LastEstimatedDamage(moonfire_debuff) >= 1.3 Spell(moonfire)
	#sunfire,cycle_targets=1,if=dot.sunfire.remains<1|action.sunfire.tick_damage%dot.sunfire.tick_dmg>=1.3
	if target.DebuffRemaining(sunfire_debuff) < 1 or target.Damage(sunfire_debuff) / target.LastEstimatedDamage(sunfire_debuff) >= 1.3 Spell(sunfire)
	#hurricane,if=active_enemies>4&buff.solar_eclipse.up&buff.natures_grace.up
	if Enemies() > 4 and BuffPresent(solar_eclipse_buff) and BuffPresent(natures_grace_buff) Spell(hurricane)
	#starfire,if=buff.celestial_alignment.up|eclipse_dir=1|(eclipse_dir=0&eclipse<=0)
	if BuffPresent(celestial_alignment_buff) or EclipseDir() == 1 or EclipseDir() == 0 and Eclipse() <= 0 Spell(starfire)
	#wrath,if=eclipse_dir=-1|(eclipse_dir=0&eclipse<=0)
	if EclipseDir() == -1 or EclipseDir() == 0 and Eclipse() <= 0 Spell(wrath)
	#hurricane,if=active_enemies>5&buff.solar_eclipse.up&mana.pct>25
	if Enemies() > 5 and BuffPresent(solar_eclipse_buff) and ManaPercent() > 25 Spell(hurricane)
	#starsurge,if=cooldown_react
	if not SpellCooldown(starsurge) > 0 Spell(starsurge)
}

AddFunction BalanceDefaultShortCdActions
{
	#starfall,if=!buff.starfall.up
	if not BuffPresent(starfall_buff) Spell(starfall)
	#force_of_nature,if=talent.force_of_nature.enabled
	if Talent(force_of_nature_talent) Spell(force_of_nature_caster)
	#wild_mushroom_detonate,moving=0,if=buff.wild_mushroom.stack>0&buff.solar_eclipse.up
	if WildMushroomCount() > 0 and BuffPresent(solar_eclipse_buff) Spell(wild_mushroom_detonate)

	unless Talent(dream_of_cenarius_talent) and not BuffPresent(dream_of_cenarius_caster_buff) and ManaPercent() > 25 and Spell(healing_touch)
	{
		#natures_vigil,if=talent.natures_vigil.enabled
		if Talent(natures_vigil_talent) Spell(natures_vigil)
	}
}

AddFunction BalanceDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()

	#jade_serpent_potion,if=trinket.stat.intellect.up
	if BuffPresent(trinket_stat_intellect_buff) UsePotionIntellect()
	#berserking,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) Spell(berserking)
	#use_item,slot=hands,if=buff.celestial_alignment.up|cooldown.celestial_alignment.remains>30
	if BuffPresent(celestial_alignment_buff) or SpellCooldown(celestial_alignment) > 30 UseItemActions()
	#natures_swiftness,if=talent.dream_of_cenarius.enabled
	if Talent(dream_of_cenarius_talent) Spell(natures_swiftness)

	unless Talent(dream_of_cenarius_talent) and not BuffPresent(dream_of_cenarius_caster_buff) and ManaPercent() > 25 and Spell(healing_touch)
	{
		#incarnation,if=talent.incarnation.enabled&trinket.stat.intellect.up
		# CHANGE: Incarnation should only be cast if in Lunar or Solar Eclipse.
		# CHANGE: Only delay Incarnation if the trinket proc will be up soon.
		#if Talent(incarnation_talent) and BuffPresent(trinket_stat_intellect_buff) Spell(incarnation_caster)
		if Talent(incarnation_talent) and { BuffPresent(lunar_eclipse_buff) or BuffPresent(solar_eclipse_buff) } and { BuffPresent(trinket_stat_intellect_buff) or BuffCooldown(trinket_stat_intellect_buff) > 15 } Spell(incarnation_caster)
		#celestial_alignment,if=trinket.stat.intellect.up
		# CHANGE: Celestial Alignment should only be cast if not in Lunar or Solar Eclipse.
		# CHANGE: Only delay Celestial Alignment if the trinket proc will be up soon.
		#if BuffPresent(trinket_stat_intellect_buff) Spell(celestial_alignment)
		if BuffExpires(lunar_eclipse_buff) and BuffExpires(solar_eclipse_buff) and { BuffPresent(trinket_stat_intellect_buff) or BuffCooldown(trinket_stat_intellect_buff) > 15 } Spell(celestial_alignment)
	}
}

# ActionList: BalancePrecombatActions --> main, shortcd, cd

AddFunction BalancePrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#healing_touch,if=!buff.dream_of_cenarius.up&talent.dream_of_cenarius.enabled
	if not BuffPresent(dream_of_cenarius_caster_buff) and Talent(dream_of_cenarius_talent) Spell(healing_touch)
	#moonkin_form
	if not Stance(druid_moonkin_form) Spell(moonkin_form)
	#snapshot_stats
}

AddFunction BalancePrecombatShortCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) and Spell(mark_of_the_wild)
	{
		#wild_mushroom,if=buff.wild_mushroom.stack<buff.wild_mushroom.max_stack
		if WildMushroomCount() < 3 Spell(wild_mushroom_caster)
	}
}

AddFunction BalancePrecombatCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
		or WildMushroomCount() < 3 and Spell(wild_mushroom_caster)
		or not BuffPresent(dream_of_cenarius_caster_buff) and Talent(dream_of_cenarius_talent) and Spell(healing_touch)
		or not Stance(druid_moonkin_form) and Spell(moonkin_form)
	{
		#jade_serpent_potion
		UsePotionIntellect()
	}
}

### Balance Icons
AddCheckBox(opt_druid_balance "Show Balance icons" specialization=balance default)
AddCheckBox(opt_druid_balance_aoe L(AOE) specialization=balance default)

AddIcon specialization=balance help=shortcd enemies=1 checkbox=opt_druid_balance checkbox=!opt_druid_balance_aoe
{
	if InCombat(no) BalancePrecombatShortCdActions()
	BalanceDefaultShortCdActions()
}

AddIcon specialization=balance help=shortcd checkbox=opt_druid_balance checkbox=opt_druid_balance_aoe
{
	if InCombat(no) BalancePrecombatShortCdActions()
	BalanceDefaultShortCdActions()
}

AddIcon specialization=balance help=main enemies=1 checkbox=opt_druid_balance
{
	if InCombat(no) BalancePrecombatActions()
	BalanceDefaultActions()
}

AddIcon specialization=balance help=aoe checkbox=opt_druid_balance checkbox=opt_druid_balance_aoe
{
	if InCombat(no) BalancePrecombatActions()
	BalanceDefaultActions()
}

AddIcon specialization=balance help=cd enemies=1 checkbox=opt_druid_balance checkbox=!opt_druid_balance_aoe
{
	if InCombat(no) BalancePrecombatCdActions()
	BalanceDefaultCdActions()
}

AddIcon specialization=balance help=cd checkbox=opt_druid_balance checkbox=opt_druid_balance_aoe
{
	if InCombat(no) BalancePrecombatCdActions()
	BalanceDefaultCdActions()
}

###
### Feral
###
# Based on SimulationCraft profile "Druid_Feral_T16H".
#	class=druid
#	spec=feral
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#UZ!...2.1
#	glyphs=savagery/cat_form

AddCheckBox(opt_weakened_armor_debuff SpellName(weakened_armor_debuff) default specialization=feral)
AddListItem(opt_feral_rotation basic "Use basic rotation" default specialization=feral)
AddListItem(opt_feral_rotation advanced "Use advanced rotation" specialization=feral)

# ActionList: FeralBasicActions --> main, predict, shortcd, cd

AddFunction FeralBasicActions
{
	#swap_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FeralAoeActions()
	#auto_attack
	#ferocious_bite,if=dot.rip.ticking&dot.rip.remains<=3&target.health.pct<=25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) <= 3 and target.HealthPercent() <= 25 Spell(ferocious_bite)
	#faerie_fire,if=debuff.weakened_armor.stack<3
	if CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 FaerieFire()
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if Talent(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemaining(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.remains<3
	if BuffRemaining(savage_roar_buff) < 3 SavageRoar()
	#rip,if=combo_points>=5&target.health.pct<=25&action.rip.tick_damage%dot.rip.tick_dmg>=1.15
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 1.15 Spell(rip)
	#ferocious_bite,if=combo_points>=5&target.health.pct<=25&dot.rip.ticking
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
	#rip,if=combo_points>=5&dot.rip.remains<2
	if ComboPoints() >= 5 and target.DebuffRemaining(rip_debuff) < 2 Spell(rip)
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemaining(thrash_cat_debuff) < 3 Spell(thrash_cat)
	#rake,cycle_targets=1,if=dot.rake.remains<3|action.rake.tick_damage>dot.rake.tick_dmg
	if target.DebuffRemaining(rake_debuff) < 3 or target.Damage(rake_debuff) > target.LastEstimatedDamage(rake_debuff) Spell(rake)
	#pool_resource,for_next=1
	#thrash_cat,if=dot.thrash_cat.remains<3&(dot.rip.remains>=8&buff.savage_roar.remains>=12|buff.berserk.up|combo_points>=5)
	if target.DebuffRemaining(thrash_cat_debuff) < 3 and { target.DebuffRemaining(rip_debuff) >= 8 and BuffRemaining(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } Spell(thrash_cat)
	unless target.DebuffRemaining(thrash_cat_debuff) < 3 and { target.DebuffRemaining(rip_debuff) >= 8 and BuffRemaining(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } and not SpellCooldown(thrash_cat) > 0
	{
		#pool_resource,if=combo_points>=5&!(energy.time_to_max<=1|(buff.berserk.up&energy>=25)|(buff.feral_rage.up&buff.feral_rage.remains<=1))&dot.rip.ticking
		unless ComboPoints() >= 5 and not { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) and Energy() >= 25 or BuffPresent(feral_rage_buff) and BuffRemaining(feral_rage_buff) <= 1 } and target.DebuffPresent(rip_debuff)
		{
			#ferocious_bite,if=combo_points>=5&dot.rip.ticking
			if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
			#run_action_list,name=filler,if=buff.omen_of_clarity.react
			if BuffPresent(omen_of_clarity_melee_buff) FeralFillerActions()
			#run_action_list,name=filler,if=buff.feral_fury.react
			if BuffPresent(feral_fury_buff) FeralFillerActions()
			#run_action_list,name=filler,if=(combo_points<5&dot.rip.remains<3.0)|(combo_points=0&buff.savage_roar.remains<2)
			if ComboPoints() < 5 and target.DebuffRemaining(rip_debuff) < 3 or ComboPoints() == 0 and BuffRemaining(savage_roar_buff) < 2 FeralFillerActions()
			#run_action_list,name=filler,if=target.time_to_die<=8.5
			if target.TimeToDie() <= 8.5 FeralFillerActions()
			#run_action_list,name=filler,if=buff.tigers_fury.up|buff.berserk.up
			if BuffPresent(tigers_fury_buff) or BuffPresent(berserk_cat_buff) FeralFillerActions()
			#run_action_list,name=filler,if=cooldown.tigers_fury.remains<=3
			if SpellCooldown(tigers_fury) <= 3 FeralFillerActions()
			#run_action_list,name=filler,if=energy.time_to_max<=1.0
			if TimeToMaxEnergy() <= 1 FeralFillerActions()
		}
	}
}

AddFunction FeralBasicPredictActions
{
	#swap_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FeralAoePredictActions()
	#auto_attack
	#ferocious_bite,if=dot.rip.ticking&dot.rip.remains<=3&target.health.pct<=25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) <= 3 and target.HealthPercent() <= 25 Spell(ferocious_bite)
	#faerie_fire,if=debuff.weakened_armor.stack<3
	if CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 FaerieFire()
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if Talent(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemaining(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.remains<3
	if BuffRemaining(savage_roar_buff) < 3 SavageRoar()
	#rip,if=combo_points>=5&target.health.pct<=25&action.rip.tick_damage%dot.rip.tick_dmg>=1.15
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 1.15 Spell(rip)
	#ferocious_bite,if=combo_points>=5&target.health.pct<=25&dot.rip.ticking
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
	#rip,if=combo_points>=5&dot.rip.remains<2
	if ComboPoints() >= 5 and target.DebuffRemaining(rip_debuff) < 2 Spell(rip)
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemaining(thrash_cat_debuff) < 3 Spell(thrash_cat)
	#rake,cycle_targets=1,if=dot.rake.remains<3|action.rake.tick_damage>dot.rake.tick_dmg
	if target.DebuffRemaining(rake_debuff) < 3 or target.Damage(rake_debuff) > target.LastEstimatedDamage(rake_debuff) Spell(rake)
	#pool_resource,for_next=1
	#thrash_cat,if=dot.thrash_cat.remains<3&(dot.rip.remains>=8&buff.savage_roar.remains>=12|buff.berserk.up|combo_points>=5)
	if target.DebuffRemaining(thrash_cat_debuff) < 3 and { target.DebuffRemaining(rip_debuff) >= 8 and BuffRemaining(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } Spell(thrash_cat)
	unless target.DebuffRemaining(thrash_cat_debuff) < 3 and { target.DebuffRemaining(rip_debuff) >= 8 and BuffRemaining(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } and not SpellCooldown(thrash_cat) > 0
	{
		#pool_resource,if=combo_points>=5&!(energy.time_to_max<=1|(buff.berserk.up&energy>=25)|(buff.feral_rage.up&buff.feral_rage.remains<=1))&dot.rip.ticking
		unless ComboPoints() >= 5 and not { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) and Energy() >= 25 or BuffPresent(feral_rage_buff) and BuffRemaining(feral_rage_buff) <= 1 } and target.DebuffPresent(rip_debuff)
		{
			#ferocious_bite,if=combo_points>=5&dot.rip.ticking
			if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
		}
	}
}

AddFunction FeralBasicShortCdActions
{
	# CHANGE: Display "up arrow" texture if not in melee range of target.
	if not target.InRange(mangle_cat) Texture(misc_arrowlup help=L(not_in_melee_range))

	#swap_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FeralAoeShortCdActions()
	#force_of_nature,if=charges=3|trinket.proc.agility.react|(buff.rune_of_reorigination.react&buff.rune_of_reorigination.remains<1)|target.time_to_die<20
	if Charges(force_of_nature_melee) == 3 or BuffPresent(trinket_proc_agility_buff) or BuffPresent(rune_of_reorigination_buff) and BuffRemaining(rune_of_reorigination_buff) < 1 or target.TimeToDie() < 20 Spell(force_of_nature_melee)

	unless target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) <= 3 and target.HealthPercent() <= 25 and Spell(ferocious_bite)
		or CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 and FaerieFire()
		or Talent(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemaining(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } and Spell(healing_touch)
		or BuffRemaining(savage_roar_buff) < 3 and SavageRoar()
	{
		#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
		#if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
	}
}

AddFunction FeralBasicCdActions
{
	#swap_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FeralAoeCdActions()
	#skull_bash_cat
	InterruptActions()

	unless target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) <= 3 and target.HealthPercent() <= 25 and Spell(ferocious_bite)
		or CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 and FaerieFire()
		or Talent(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemaining(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } and Spell(healing_touch)
		or BuffRemaining(savage_roar_buff) < 3 and SavageRoar()
	{
		#virmens_bite_potion,if=(target.health.pct<30&buff.berserk.up)|target.time_to_die<=40
		if target.HealthPercent() < 30 and BuffPresent(berserk_cat_buff) or target.TimeToDie() <= 40 UsePotionAgility()
		# CHANGE: Synchronize abilities that are used with Tiger's Fury using Tiger Fury's conditions.
		#         Don't include Berserk since Tiger's Fury can't be triggered while Berserk is active.
		#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
		#if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
		#berserk,if=buff.tigers_fury.up
		if BuffPresent(tigers_fury_buff) Spell(berserk_cat)
		#use_item,slot=hands,if=buff.tigers_fury.up
		if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) and Spell(tigers_fury) or BuffPresent(tigers_fury_buff) UseItemActions()
		#blood_fury,if=buff.tigers_fury.up
		if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) and Spell(tigers_fury) or BuffPresent(tigers_fury_buff) Spell(blood_fury_apsp)
		#berserking,if=buff.tigers_fury.up
		if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) and Spell(tigers_fury) or BuffPresent(tigers_fury_buff) Spell(berserking)
		#arcane_torrent,if=buff.tigers_fury.up
		if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) and Spell(tigers_fury) or BuffPresent(tigers_fury_buff) Spell(arcane_torrent_energy)
	}
}

# ActionList: FeralDefaultActions --> main, predict, shortcd, cd

AddFunction FeralDefaultActions
{
	if List(opt_feral_rotation basic) FeralBasicActions()
	if List(opt_feral_rotation advanced) FeralAdvancedActions()
}

AddFunction FeralDefaultPredictActions
{
	if List(opt_feral_rotation basic) FeralBasicPredictActions()
	if List(opt_feral_rotation advanced) FeralAdvancedPredictActions()
}

AddFunction FeralDefaultShortCdActions
{
	if List(opt_feral_rotation basic) FeralBasicShortCdActions()
	if List(opt_feral_rotation advanced) FeralAdvancedShortCdActions()
}

AddFunction FeralDefaultCdActions
{
	if List(opt_feral_rotation basic) FeralBasicCdActions()
	if List(opt_feral_rotation advanced) FeralAdvancedCdActions()
}

# ActionList: FeralAdvancedActions --> main, predict, shortcd, cd

AddFunction FeralAdvancedActions
{
	#swap_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FeralAoeActions()
	#auto_attack
	#ravage,if=buff.stealthed.up
	if BuffPresent(stealthed_buff any=1) Spell(ravage)
	#ferocious_bite,if=dot.rip.ticking&dot.rip.remains<=3&target.health.pct<=25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) <= 3 and target.HealthPercent() <= 25 Spell(ferocious_bite)
	#faerie_fire,if=debuff.weakened_armor.stack<3
	if CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 FaerieFire()
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if Talent(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemaining(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.down
	if BuffExpires(savage_roar_buff) SavageRoar()
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3&target.time_to_die>=6
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemaining(thrash_cat_debuff) < 3 and target.TimeToDie() >= 6 Spell(thrash_cat)
	#ferocious_bite,if=target.time_to_die<=1&combo_points>=3
	if target.TimeToDie() <= 1 and ComboPoints() >= 3 Spell(ferocious_bite)
	#savage_roar,if=buff.savage_roar.remains<=3&combo_points>0&target.health.pct<25
	if BuffRemaining(savage_roar_buff) <= 3 and ComboPoints() > 0 and target.HealthPercent() < 25 SavageRoar()
	#rip,if=combo_points>=5&action.rip.tick_damage%dot.rip.tick_dmg>=1.15&target.time_to_die>30
	if ComboPoints() >= 5 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 1.15 and target.TimeToDie() > 30 Spell(rip)
	#rip,if=combo_points>=4&action.rip.tick_damage%dot.rip.tick_dmg>=0.95&target.time_to_die>30&buff.rune_of_reorigination.up&buff.rune_of_reorigination.remains<=1.5
	if ComboPoints() >= 4 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 0.95 and target.TimeToDie() > 30 and BuffPresent(rune_of_reorigination_buff) and BuffRemaining(rune_of_reorigination_buff) <= 1.5 Spell(rip)
	#pool_resource,if=combo_points>=5&target.health.pct<=25&dot.rip.ticking&!(energy>=50|(buff.berserk.up&energy>=25))
	unless ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.DebuffPresent(rip_debuff) and not { Energy() >= 50 or BuffPresent(berserk_cat_buff) and Energy() >= 25 }
	{
		#ferocious_bite,if=combo_points>=5&dot.rip.ticking&target.health.pct<=25
		if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) and target.HealthPercent() <= 25 Spell(ferocious_bite)
		#rip,if=combo_points>=5&target.time_to_die>=6&dot.rip.remains<2&(buff.berserk.up|dot.rip.remains+1.9<=cooldown.tigers_fury.remains)
		if ComboPoints() >= 5 and target.TimeToDie() >= 6 and target.DebuffRemaining(rip_debuff) < 2 and { BuffPresent(berserk_cat_buff) or target.DebuffRemaining(rip_debuff) + 1.9 <= SpellCooldown(tigers_fury) } Spell(rip)
		#savage_roar,if=buff.savage_roar.remains<=3&combo_points>0&buff.savage_roar.remains+2>dot.rip.remains
		if BuffRemaining(savage_roar_buff) <= 3 and ComboPoints() > 0 and BuffRemaining(savage_roar_buff) + 2 > target.DebuffRemaining(rip_debuff) SavageRoar()
		#savage_roar,if=buff.savage_roar.remains<=6&combo_points>=5&buff.savage_roar.remains+2<=dot.rip.remains&dot.rip.ticking
		if BuffRemaining(savage_roar_buff) <= 6 and ComboPoints() >= 5 and BuffRemaining(savage_roar_buff) + 2 <= target.DebuffRemaining(rip_debuff) and target.DebuffPresent(rip_debuff) SavageRoar()
		#savage_roar,if=buff.savage_roar.remains<=12&combo_points>=5&energy.time_to_max<=1&buff.savage_roar.remains<=dot.rip.remains+6&dot.rip.ticking
		if BuffRemaining(savage_roar_buff) <= 12 and ComboPoints() >= 5 and TimeToMaxEnergy() <= 1 and BuffRemaining(savage_roar_buff) <= target.DebuffRemaining(rip_debuff) + 6 and target.DebuffPresent(rip_debuff) SavageRoar()
		#rake,if=buff.rune_of_reorigination.up&dot.rake.remains<9&buff.rune_of_reorigination.remains<=1.5
		if BuffPresent(rune_of_reorigination_buff) and target.DebuffRemaining(rake_debuff) < 9 and BuffRemaining(rune_of_reorigination_buff) <= 1.5 Spell(rake)
		#rake,cycle_targets=1,if=target.time_to_die-dot.rake.remains>3&(action.rake.tick_damage>dot.rake.tick_dmg|(dot.rake.remains<3&action.rake.tick_damage%dot.rake.tick_dmg>=0.75))
		if target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 3 and { target.Damage(rake_debuff) > target.LastEstimatedDamage(rake_debuff) or target.DebuffRemaining(rake_debuff) < 3 and target.Damage(rake_debuff) / target.LastEstimatedDamage(rake_debuff) >= 0.75 } Spell(rake)
		#pool_resource,for_next=1
		#thrash_cat,if=target.time_to_die>=6&dot.thrash_cat.remains<3&(dot.rip.remains>=8&buff.savage_roar.remains>=12|buff.berserk.up|combo_points>=5)&dot.rip.ticking
		if target.TimeToDie() >= 6 and target.DebuffRemaining(thrash_cat_debuff) < 3 and { target.DebuffRemaining(rip_debuff) >= 8 and BuffRemaining(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } and target.DebuffPresent(rip_debuff) Spell(thrash_cat)
		unless target.TimeToDie() >= 6 and target.DebuffRemaining(thrash_cat_debuff) < 3 and { target.DebuffRemaining(rip_debuff) >= 8 and BuffRemaining(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } and target.DebuffPresent(rip_debuff) and not SpellCooldown(thrash_cat) > 0
		{
			#pool_resource,for_next=1
			#thrash_cat,if=target.time_to_die>=6&dot.thrash_cat.remains<9&buff.rune_of_reorigination.up&buff.rune_of_reorigination.remains<=1.5&dot.rip.ticking
			if target.TimeToDie() >= 6 and target.DebuffRemaining(thrash_cat_debuff) < 9 and BuffPresent(rune_of_reorigination_buff) and BuffRemaining(rune_of_reorigination_buff) <= 1.5 and target.DebuffPresent(rip_debuff) Spell(thrash_cat)
			unless target.TimeToDie() >= 6 and target.DebuffRemaining(thrash_cat_debuff) < 9 and BuffPresent(rune_of_reorigination_buff) and BuffRemaining(rune_of_reorigination_buff) <= 1.5 and target.DebuffPresent(rip_debuff) and not SpellCooldown(thrash_cat) > 0
			{
				#pool_resource,if=combo_points>=5&!(energy.time_to_max<=1|(buff.berserk.up&energy>=25)|(buff.feral_rage.up&buff.feral_rage.remains<=1))&dot.rip.ticking
				unless ComboPoints() >= 5 and not { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) and Energy() >= 25 or BuffPresent(feral_rage_buff) and BuffRemaining(feral_rage_buff) <= 1 } and target.DebuffPresent(rip_debuff)
				{
					#ferocious_bite,if=combo_points>=5&dot.rip.ticking
					if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
					#run_action_list,name=filler,if=buff.omen_of_clarity.react
					if BuffPresent(omen_of_clarity_melee_buff) FeralFillerActions()
					#run_action_list,name=filler,if=buff.feral_fury.react
					if BuffPresent(feral_fury_buff) FeralFillerActions()
					#run_action_list,name=filler,if=(combo_points<5&dot.rip.remains<3.0)|(combo_points=0&buff.savage_roar.remains<2)
					if ComboPoints() < 5 and target.DebuffRemaining(rip_debuff) < 3 or ComboPoints() == 0 and BuffRemaining(savage_roar_buff) < 2 FeralFillerActions()
					#run_action_list,name=filler,if=target.time_to_die<=8.5
					if target.TimeToDie() <= 8.5 FeralFillerActions()
					#run_action_list,name=filler,if=buff.tigers_fury.up|buff.berserk.up
					if BuffPresent(tigers_fury_buff) or BuffPresent(berserk_cat_buff) FeralFillerActions()
					#run_action_list,name=filler,if=cooldown.tigers_fury.remains<=3
					if SpellCooldown(tigers_fury) <= 3 FeralFillerActions()
					#run_action_list,name=filler,if=energy.time_to_max<=1.0
					if TimeToMaxEnergy() <= 1 FeralFillerActions()
				}
			}
		}
	}
}

AddFunction FeralAdvancedPredictActions
{
	#swap_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FeralAoePredictActions()
	#auto_attack
	#ravage,if=buff.stealthed.up
	if BuffPresent(stealthed_buff any=1) Spell(ravage)
	#ferocious_bite,if=dot.rip.ticking&dot.rip.remains<=3&target.health.pct<=25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) <= 3 and target.HealthPercent() <= 25 Spell(ferocious_bite)
	#faerie_fire,if=debuff.weakened_armor.stack<3
	if CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 FaerieFire()
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if Talent(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemaining(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.down
	if BuffExpires(savage_roar_buff) SavageRoar()
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3&target.time_to_die>=6
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemaining(thrash_cat_debuff) < 3 and target.TimeToDie() >= 6 Spell(thrash_cat)
	#ferocious_bite,if=target.time_to_die<=1&combo_points>=3
	if target.TimeToDie() <= 1 and ComboPoints() >= 3 Spell(ferocious_bite)
	#savage_roar,if=buff.savage_roar.remains<=3&combo_points>0&target.health.pct<25
	if BuffRemaining(savage_roar_buff) <= 3 and ComboPoints() > 0 and target.HealthPercent() < 25 SavageRoar()
	#rip,if=combo_points>=5&action.rip.tick_damage%dot.rip.tick_dmg>=1.15&target.time_to_die>30
	if ComboPoints() >= 5 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 1.15 and target.TimeToDie() > 30 Spell(rip)
	#rip,if=combo_points>=4&action.rip.tick_damage%dot.rip.tick_dmg>=0.95&target.time_to_die>30&buff.rune_of_reorigination.up&buff.rune_of_reorigination.remains<=1.5
	if ComboPoints() >= 4 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 0.95 and target.TimeToDie() > 30 and BuffPresent(rune_of_reorigination_buff) and BuffRemaining(rune_of_reorigination_buff) <= 1.5 Spell(rip)
	#pool_resource,if=combo_points>=5&target.health.pct<=25&dot.rip.ticking&!(energy>=50|(buff.berserk.up&energy>=25))
	unless ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.DebuffPresent(rip_debuff) and not { Energy() >= 50 or BuffPresent(berserk_cat_buff) and Energy() >= 25 }
	{
		#ferocious_bite,if=combo_points>=5&dot.rip.ticking&target.health.pct<=25
		if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) and target.HealthPercent() <= 25 Spell(ferocious_bite)
		#rip,if=combo_points>=5&target.time_to_die>=6&dot.rip.remains<2&(buff.berserk.up|dot.rip.remains+1.9<=cooldown.tigers_fury.remains)
		if ComboPoints() >= 5 and target.TimeToDie() >= 6 and target.DebuffRemaining(rip_debuff) < 2 and { BuffPresent(berserk_cat_buff) or target.DebuffRemaining(rip_debuff) + 1.9 <= SpellCooldown(tigers_fury) } Spell(rip)
		#savage_roar,if=buff.savage_roar.remains<=3&combo_points>0&buff.savage_roar.remains+2>dot.rip.remains
		if BuffRemaining(savage_roar_buff) <= 3 and ComboPoints() > 0 and BuffRemaining(savage_roar_buff) + 2 > target.DebuffRemaining(rip_debuff) SavageRoar()
		#savage_roar,if=buff.savage_roar.remains<=6&combo_points>=5&buff.savage_roar.remains+2<=dot.rip.remains&dot.rip.ticking
		if BuffRemaining(savage_roar_buff) <= 6 and ComboPoints() >= 5 and BuffRemaining(savage_roar_buff) + 2 <= target.DebuffRemaining(rip_debuff) and target.DebuffPresent(rip_debuff) SavageRoar()
		#savage_roar,if=buff.savage_roar.remains<=12&combo_points>=5&energy.time_to_max<=1&buff.savage_roar.remains<=dot.rip.remains+6&dot.rip.ticking
		if BuffRemaining(savage_roar_buff) <= 12 and ComboPoints() >= 5 and TimeToMaxEnergy() <= 1 and BuffRemaining(savage_roar_buff) <= target.DebuffRemaining(rip_debuff) + 6 and target.DebuffPresent(rip_debuff) SavageRoar()
		#rake,if=buff.rune_of_reorigination.up&dot.rake.remains<9&buff.rune_of_reorigination.remains<=1.5
		if BuffPresent(rune_of_reorigination_buff) and target.DebuffRemaining(rake_debuff) < 9 and BuffRemaining(rune_of_reorigination_buff) <= 1.5 Spell(rake)
		#rake,cycle_targets=1,if=target.time_to_die-dot.rake.remains>3&(action.rake.tick_damage>dot.rake.tick_dmg|(dot.rake.remains<3&action.rake.tick_damage%dot.rake.tick_dmg>=0.75))
		if target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 3 and { target.Damage(rake_debuff) > target.LastEstimatedDamage(rake_debuff) or target.DebuffRemaining(rake_debuff) < 3 and target.Damage(rake_debuff) / target.LastEstimatedDamage(rake_debuff) >= 0.75 } Spell(rake)
		#pool_resource,for_next=1
		#thrash_cat,if=target.time_to_die>=6&dot.thrash_cat.remains<3&(dot.rip.remains>=8&buff.savage_roar.remains>=12|buff.berserk.up|combo_points>=5)&dot.rip.ticking
		if target.TimeToDie() >= 6 and target.DebuffRemaining(thrash_cat_debuff) < 3 and { target.DebuffRemaining(rip_debuff) >= 8 and BuffRemaining(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } and target.DebuffPresent(rip_debuff) Spell(thrash_cat)
		unless target.TimeToDie() >= 6 and target.DebuffRemaining(thrash_cat_debuff) < 3 and { target.DebuffRemaining(rip_debuff) >= 8 and BuffRemaining(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } and target.DebuffPresent(rip_debuff) and not SpellCooldown(thrash_cat) > 0
		{
			#pool_resource,for_next=1
			#thrash_cat,if=target.time_to_die>=6&dot.thrash_cat.remains<9&buff.rune_of_reorigination.up&buff.rune_of_reorigination.remains<=1.5&dot.rip.ticking
			if target.TimeToDie() >= 6 and target.DebuffRemaining(thrash_cat_debuff) < 9 and BuffPresent(rune_of_reorigination_buff) and BuffRemaining(rune_of_reorigination_buff) <= 1.5 and target.DebuffPresent(rip_debuff) Spell(thrash_cat)
			unless target.TimeToDie() >= 6 and target.DebuffRemaining(thrash_cat_debuff) < 9 and BuffPresent(rune_of_reorigination_buff) and BuffRemaining(rune_of_reorigination_buff) <= 1.5 and target.DebuffPresent(rip_debuff) and not SpellCooldown(thrash_cat) > 0
			{
				#pool_resource,if=combo_points>=5&!(energy.time_to_max<=1|(buff.berserk.up&energy>=25)|(buff.feral_rage.up&buff.feral_rage.remains<=1))&dot.rip.ticking
				unless ComboPoints() >= 5 and not { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) and Energy() >= 25 or BuffPresent(feral_rage_buff) and BuffRemaining(feral_rage_buff) <= 1 } and target.DebuffPresent(rip_debuff)
				{
					#ferocious_bite,if=combo_points>=5&dot.rip.ticking
					if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
				}
			}
		}
	}
}

AddFunction FeralAdvancedShortCdActions
{
	# CHANGE: Display "up arrow" texture if not in melee range of target.
	if not target.InRange(mangle_cat) Texture(misc_arrowlup help=L(not_in_melee_range))

	#swap_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FeralAoeShortCdActions()
	#force_of_nature,if=charges=3|(buff.rune_of_reorigination.react&buff.rune_of_reorigination.remains<1)|(buff.vicious.react&buff.vicious.remains<1)|target.time_to_die<20
	if Charges(force_of_nature_melee) == 3 or BuffPresent(rune_of_reorigination_buff) and BuffRemaining(rune_of_reorigination_buff) < 1 or BuffPresent(trinket_proc_agility_buff) and BuffRemaining(trinket_proc_agility_buff) < 1 or target.TimeToDie() < 20 Spell(force_of_nature_melee)

	unless BuffPresent(stealthed_buff any=1) and Spell(ravage)
		or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) <= 3 and target.HealthPercent() <= 25 and Spell(ferocious_bite)
		or CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 and FaerieFire()
		or Talent(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemaining(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } and Spell(healing_touch)
		or BuffExpires(savage_roar_buff) and SavageRoar()
	{
		#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
		if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
	}
}

AddFunction FeralAdvancedCdActions
{
	#swap_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FeralAoeCdActions()
	#skull_bash_cat
	InterruptActions()
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_energy)

	unless BuffPresent(stealthed_buff any=1) and Spell(ravage)
		or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) <= 3 and target.HealthPercent() <= 25 and Spell(ferocious_bite)
		or CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 and FaerieFire()
		or Talent(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemaining(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } and Spell(healing_touch)
		or BuffExpires(savage_roar_buff) and SavageRoar()
	{
		# CHANGE: Synchronize abilities that are used with Tiger's Fury using Tiger Fury's conditions.
		#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
		#if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
		#berserk,if=buff.tigers_fury.up|(target.time_to_die<18&cooldown.tigers_fury.remains>6)
		if BuffPresent(tigers_fury_buff) or target.TimeToDie() < 18 and SpellCooldown(tigers_fury) > 6 Spell(berserk_cat)
		#use_item,slot=hands,if=buff.tigers_fury.up
		if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) and Spell(tigers_fury) or BuffPresent(tigers_fury_buff) UseItemActions()

		unless BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemaining(thrash_cat_debuff) < 3 and target.TimeToDie() >= 6 and Spell(thrash_cat)
			or target.TimeToDie() <= 1 and ComboPoints() >= 3 and Spell(ferocious_bite)
			or BuffRemaining(savage_roar_buff) <= 3 and ComboPoints() > 0 and target.HealthPercent() < 25 and SavageRoar()
		{
			#virmens_bite_potion,if=(combo_points>=5&(target.time_to_die*(target.health.pct-25)%target.health.pct)<15&buff.rune_of_reorigination.up)|target.time_to_die<=40
			if ComboPoints() >= 5 and target.TimeToDie() * { target.HealthPercent() - 25 } / target.HealthPercent() < 15 and BuffPresent(rune_of_reorigination_buff) or target.TimeToDie() <= 40 UsePotionAgility()
		}
	}
}

# ActionList: FeralPrecombatActions --> main, predict, shortcd, cd

AddFunction FeralPrecombatActions
{
	FeralPrecombatPredictActions()
}

AddFunction FeralPrecombatPredictActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#healing_touch,if=!buff.dream_of_cenarius.up&talent.dream_of_cenarius.enabled
	if not BuffPresent(dream_of_cenarius_melee_buff) and Talent(dream_of_cenarius_talent) Spell(healing_touch)
	#cat_form
	if not Stance(druid_cat_form) Spell(cat_form)
	#savage_roar
	if not TimeToMaxEnergy() > 0 SavageRoar()
	#stealth
	if BuffExpires(stealthed_buff) Spell(prowl)
	#snapshot_stats
}

AddFunction FeralPrecombatShortCdActions {}

AddFunction FeralPrecombatCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) and Spell(mark_of_the_wild)
		or not BuffPresent(dream_of_cenarius_melee_buff) and Talent(dream_of_cenarius_talent) and Spell(healing_touch)
		or not Stance(druid_cat_form) and Spell(cat_form)
		or not TimeToMaxEnergy() > 0 and SavageRoar()
		or BuffExpires(stealthed_buff) and Spell(prowl)
	{
		#virmens_bite_potion
		UsePotionAgility()
	}
}

# ActionList: FeralAoeActions --> main, predict, shortcd, cd

AddFunction FeralAoeActions
{
	#swap_action_list,name=default,if=active_enemies<5
	if Enemies() < 5 FeralDefaultActions()
	#auto_attack
	#faerie_fire,cycle_targets=1,if=debuff.weakened_armor.stack<3
	if CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 FaerieFire()
	#savage_roar,if=buff.savage_roar.down|(buff.savage_roar.remains<3&combo_points>0)
	if BuffExpires(savage_roar_buff) or BuffRemaining(savage_roar_buff) < 3 and ComboPoints() > 0 SavageRoar()
	#pool_resource,for_next=1
	#thrash_cat,if=buff.rune_of_reorigination.up
	if BuffPresent(rune_of_reorigination_buff) Spell(thrash_cat)
	unless BuffPresent(rune_of_reorigination_buff) and not SpellCooldown(thrash_cat) > 0
	{
		#pool_resource,wait=0.1,for_next=1
		#thrash_cat,if=dot.thrash_cat.remains<3|(buff.tigers_fury.up&dot.thrash_cat.remains<9)
		if target.DebuffRemaining(thrash_cat_debuff) < 3 or BuffPresent(tigers_fury_buff) and target.DebuffRemaining(thrash_cat_debuff) < 9 Spell(thrash_cat)
		unless { target.DebuffRemaining(thrash_cat_debuff) < 3 or BuffPresent(tigers_fury_buff) and target.DebuffRemaining(thrash_cat_debuff) < 9 } and not SpellCooldown(thrash_cat) > 0
		{
			#savage_roar,if=buff.savage_roar.remains<9&combo_points>=5
			if BuffRemaining(savage_roar_buff) < 9 and ComboPoints() >= 5 SavageRoar()
			#rip,if=combo_points>=5
			if ComboPoints() >= 5 Spell(rip)
			#rake,cycle_targets=1,if=(active_enemies<8|buff.rune_of_reorigination.up)&dot.rake.remains<3&target.time_to_die>=15
			if { Enemies() < 8 or BuffPresent(rune_of_reorigination_buff) } and target.DebuffRemaining(rake_debuff) < 3 and target.TimeToDie() >= 15 Spell(rake)
			#swipe_cat,if=buff.savage_roar.remains<=5
			if BuffRemaining(savage_roar_buff) <= 5 Spell(swipe_cat)
			#swipe_cat,if=buff.tigers_fury.up|buff.berserk.up
			if BuffPresent(tigers_fury_buff) or BuffPresent(berserk_cat_buff) Spell(swipe_cat)
			#swipe_cat,if=cooldown.tigers_fury.remains<3
			if SpellCooldown(tigers_fury) < 3 Spell(swipe_cat)
			#swipe_cat,if=buff.omen_of_clarity.react
			if BuffPresent(omen_of_clarity_melee_buff) Spell(swipe_cat)
			#swipe_cat,if=energy.time_to_max<=1
			if TimeToMaxEnergy() <= 1 Spell(swipe_cat)
		}
	}
}

AddFunction FeralAoePredictActions
{
	#swap_action_list,name=default,if=active_enemies<5
	if Enemies() < 5 FeralDefaultActions()
	#auto_attack
	#faerie_fire,cycle_targets=1,if=debuff.weakened_armor.stack<3
	if CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 FaerieFire()
	#savage_roar,if=buff.savage_roar.down|(buff.savage_roar.remains<3&combo_points>0)
	if BuffExpires(savage_roar_buff) or BuffRemaining(savage_roar_buff) < 3 and ComboPoints() > 0 SavageRoar()
	#pool_resource,for_next=1
	#thrash_cat,if=buff.rune_of_reorigination.up
	if BuffPresent(rune_of_reorigination_buff) Spell(thrash_cat)
	unless BuffPresent(rune_of_reorigination_buff) and not SpellCooldown(thrash_cat) > 0
	{
		#pool_resource,wait=0.1,for_next=1
		#thrash_cat,if=dot.thrash_cat.remains<3|(buff.tigers_fury.up&dot.thrash_cat.remains<9)
		if target.DebuffRemaining(thrash_cat_debuff) < 3 or BuffPresent(tigers_fury_buff) and target.DebuffRemaining(thrash_cat_debuff) < 9 Spell(thrash_cat)
		unless { target.DebuffRemaining(thrash_cat_debuff) < 3 or BuffPresent(tigers_fury_buff) and target.DebuffRemaining(thrash_cat_debuff) < 9 } and not SpellCooldown(thrash_cat) > 0
		{
			#savage_roar,if=buff.savage_roar.remains<9&combo_points>=5
			if BuffRemaining(savage_roar_buff) < 9 and ComboPoints() >= 5 SavageRoar()
			#rip,if=combo_points>=5
			if ComboPoints() >= 5 Spell(rip)
			#rake,cycle_targets=1,if=(active_enemies<8|buff.rune_of_reorigination.up)&dot.rake.remains<3&target.time_to_die>=15
			if { Enemies() < 8 or BuffPresent(rune_of_reorigination_buff) } and target.DebuffRemaining(rake_debuff) < 3 and target.TimeToDie() >= 15 Spell(rake)
		}
	}
}

AddFunction FeralAoeShortCdActions
{
	#swap_action_list,name=default,if=active_enemies<5
	if Enemies() < 5 FeralDefaultCdActions()
	unless CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 and FaerieFire()
		or { BuffExpires(savage_roar_buff) or BuffRemaining(savage_roar_buff) < 3 and ComboPoints() > 0 } and SavageRoar()
	{
		#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
		if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
	}
}

AddFunction FeralAoeCdActions
{
	#swap_action_list,name=default,if=active_enemies<5
	if Enemies() < 5 FeralDefaultCdActions()
	unless CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 and FaerieFire()
		or { BuffExpires(savage_roar_buff) or BuffRemaining(savage_roar_buff) < 3 and ComboPoints() > 0 } and SavageRoar()
	{
		# CHANGE: Synchronize abilities that are used with Tiger's Fury using Tiger Fury's conditions.
		#use_item,slot=hands,if=buff.tigers_fury.up
		if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) and Spell(tigers_fury) or BuffPresent(tigers_fury_buff) UseItemActions()
		#blood_fury,if=buff.tigers_fury.up
		if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) and Spell(tigers_fury) or BuffPresent(tigers_fury_buff) Spell(blood_fury_apsp)
		#berserking,if=buff.tigers_fury.up
		if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) and Spell(tigers_fury) or BuffPresent(tigers_fury_buff) Spell(berserking)
		#arcane_torrent,if=buff.tigers_fury.up
		if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) and Spell(tigers_fury) or BuffPresent(tigers_fury_buff) Spell(arcane_torrent_energy)
		#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
		#if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
		#berserk,if=buff.tigers_fury.up
		if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) and Spell(tigers_fury) or BuffPresent(tigers_fury_buff) Spell(berserk_cat)
	}
}

# ActionList: FeralFillerActions --> main

AddFunction FeralFillerActions
{
	#ravage
	if BuffPresent(stealthed_buff any=1) Spell(ravage)
	#rake,if=target.time_to_die-dot.rake.remains>3&action.rake.tick_damage*(dot.rake.ticks_remain+1)-dot.rake.tick_dmg*dot.rake.ticks_remain>action.mangle_cat.hit_damage
	if target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 3 and target.Damage(rake_debuff) * { target.TicksRemaining(rake_debuff) + 1 } - target.LastEstimatedDamage(rake_debuff) * target.TicksRemaining(rake_debuff) > Damage(mangle_cat) Spell(rake)
	#shred,if=(buff.omen_of_clarity.react|buff.berserk.up|energy.regen>=15)&buff.king_of_the_jungle.down
	if { BuffPresent(omen_of_clarity_melee_buff) or BuffPresent(berserk_cat_buff) or EnergyRegen() >= 15 } and BuffExpires(king_of_the_jungle_buff) Spell(shred)
	#mangle_cat,if=buff.king_of_the_jungle.down
	if BuffExpires(king_of_the_jungle_buff) Spell(mangle_cat)
}

### Feral Icons
AddCheckBox(opt_druid_feral "Show Feral icons" specialization=feral default)
AddCheckBox(opt_druid_feral_aoe L(AOE) specialization=feral default)

AddIcon specialization=feral help=shortcd enemies=1 checkbox=opt_druid_feral checkbox=!opt_druid_feral_aoe
{
	if InCombat(no) FeralPrecombatShortCdActions()
	FeralDefaultShortCdActions()
}

AddIcon specialization=feral help=shortcd checkbox=opt_druid_feral checkbox=opt_druid_feral_aoe
{
	if InCombat(no) FeralPrecombatShortCdActions()
	FeralDefaultShortCdActions()
}

AddIcon specialization=feral help=main enemies=1 checkbox=opt_druid_feral
{
	if InCombat(no) FeralPrecombatActions()
	FeralDefaultActions()
}

AddIcon specialization=feral help=predict enemies=1 checkbox=opt_druid_feral checkbox=!opt_druid_feral_aoe
{
	if InCombat(no) FeralPrecombatPredictActions()
	FeralDefaultPredictActions()
}

AddIcon specialization=feral help=aoe checkbox=opt_druid_feral checkbox=opt_druid_feral_aoe
{
	if InCombat(no) FeralPrecombatActions()
	FeralDefaultActions()
}

AddIcon specialization=feral help=cd enemies=1 checkbox=opt_druid_feral checkbox=!opt_druid_feral_aoe
{
	if InCombat(no) FeralPrecombatCdActions()
	FeralDefaultCdActions()
}

AddIcon specialization=feral help=cd checkbox=opt_druid_feral checkbox=opt_druid_feral_aoe
{
	if InCombat(no) FeralPrecombatCdActions()
	FeralDefaultCdActions()
}

###
### Guardian
###

# ActionList: GuardianDefaultActions --> main, shortcd, cd

AddFunction GuardianDefaultActions
{
	#auto_attack
	#thrash_bear,if=debuff.weakened_blows.remains<3
	if target.DebuffRemaining(weakened_blows_debuff any=1) < 3 Spell(thrash_bear)
	#lacerate,if=((dot.lacerate.remains<3)|(buff.lacerate.stack<3&dot.thrash_bear.remains>3))&(buff.son_of_ursoc.up|buff.berserk.up)
	if { target.DebuffRemaining(lacerate_debuff) < 3 or { target.DebuffStacks(lacerate_debuff) < 3 and target.DebuffRemaining(thrash_bear_debuff) > 3 } } and { BuffPresent(son_of_ursoc_buff) or BuffPresent(berserk_bear_buff) } Spell(lacerate)
	#faerie_fire,if=debuff.weakened_armor.stack<3
	if target.DebuffStacks(weakened_armor_debuff any=1) < 3 FaerieFire()
	#thrash_bear,if=dot.thrash_bear.remains<3&(buff.son_of_ursoc.up|buff.berserk.up)
	if target.DebuffRemaining(thrash_bear_debuff) < 3 and { BuffPresent(son_of_ursoc_buff) or BuffPresent(berserk_bear_buff) } Spell(thrash_bear)
	#mangle_bear
	Spell(mangle_bear)
	# CHANGE: Cast Enrage when necessary to gain 20 rage at the cost of 1 GCD.
	if Rage() < 11 Spell(enrage)
	#wait,sec=cooldown.mangle_bear.remains,if=cooldown.mangle_bear.remains<=0.5
	unless SpellCooldown(mangle_bear) > 0 and SpellCooldown(mangle_bear) <= 0.5
	{
		#cenarion_ward,if=talent.cenarion_ward.enabled
		if Talent(cenarion_ward_talent) Spell(cenarion_ward)
		if BuffPresent(dream_of_cenarius_tank_buff) Spell(healing_touch)
		#lacerate,if=dot.lacerate.remains<3|buff.lacerate.stack<3
		if target.DebuffRemaining(lacerate_debuff) < 3 or target.DebuffStacks(lacerate_debuff) < 3 Spell(lacerate)
		#thrash_bear,if=dot.thrash_bear.remains<2
		if target.DebuffRemaining(thrash_bear_debuff) < 2 Spell(thrash_bear)
		#lacerate
		Spell(lacerate)
		#faerie_fire,if=dot.thrash_bear.remains>6
		if target.DebuffRemaining(thrash_bear_debuff) > 6 FaerieFire()
		#thrash_bear
		Spell(thrash_bear)
		FaerieFire()
	}
}

AddFunction GuardianDefaultShortCdActions
{
	#frenzied_regeneration,if=health.pct<100&action.savage_defense.charges=0&incoming_damage_5>0.2*health.max
	if HealthPercent() < 100 and Charges(savage_defense) < 1 and IncomingDamage(5) > 0.2 * MaxHealth() Spell(frenzied_regeneration)
	#frenzied_regeneration,if=health.pct<100&action.savage_defense.charges>0&incoming_damage_5>0.4*health.max
	if HealthPercent() < 100 and Charges(savage_defense) > 0 and IncomingDamage(5) > 0.4 * MaxHealth() Spell(frenzied_regeneration)
	#savage_defense
	Spell(savage_defense)
	#barkskin
	Spell(barkskin)
	#maul,if=buff.tooth_and_claw.react&buff.tooth_and_claw_absorb.down
	if BuffPresent(tooth_and_claw_buff) and target.DebuffExpires(tooth_and_claw_debuff) Spell(maul)

	unless { target.DebuffRemaining(lacerate_debuff) < 3 or { target.DebuffStacks(lacerate_debuff) < 3 and target.DebuffRemaining(thrash_bear_debuff) > 3 } } and { BuffPresent(son_of_ursoc_buff) or BuffPresent(berserk_bear_buff) } and Spell(lacerate)
		or target.DebuffStacks(weakened_armor_debuff any=1) < 3 and FaerieFire()
		or target.DebuffRemaining(thrash_bear_debuff) < 3 and { BuffPresent(son_of_ursoc_buff) or BuffPresent(berserk_bear_buff) } and Spell(thrash_bear)
		or Spell(mangle_bear)
	{
		#wait,sec=cooldown.mangle_bear.remains,if=cooldown.mangle_bear.remains<=0.5
		unless SpellCooldown(mangle_bear) > 0 and SpellCooldown(mangle_bear) <= 0.5
		{
			#cenarion_ward,if=talent.cenarion_ward.enabled
			if Talent(cenarion_ward_talent) Spell(cenarion_ward)
		}
	}
}

AddFunction GuardianDefaultCdActions
{
	#skull_bash_bear
	InterruptActions()
	# CHANGE: Don't overlap burst haste effects so we can extend the period of higher rage generation.
	#berserking
	#Spell(berserking)
	if BuffExpires(burst_haste_buff any=1) Spell(berserking)
	#renewal,if=talent.renewal.enabled&incoming_damage_5>0.8*health.max
	if Talent(renewal_talent) and IncomingDamage(5) > 0.8 * MaxHealth() Spell(renewal)
	#natures_vigil,if=talent.natures_vigil.enabled&(!talent.incarnation.enabled|buff.son_of_ursoc.up|cooldown.incarnation.remains)
	if Talent(natures_vigil_talent) and { Talent(incarnation_talent no) or BuffPresent(son_of_ursoc_buff) or SpellCooldown(incarnation_tank) > 0 } Spell(natures_vigil)

	# CHANGE: Add bear DPS cooldown abilities.
	if HealthPercent() < 50
	{
		if BuffExpires(son_of_ursoc_buff) Spell(berserk_bear)
		if Talent(incarnation_talent) and BuffExpires(berserk_bear_buff) Spell(incarnation_tank)
	}
}

# ActionList: GuardianDefaultActions --> main, shortcd, cd

AddFunction GuardianPrecombatActions
{
	#elixir,type=mad_hozen
	#elixir,type=mantid
	#food,type=chun_tian_spring_rolls
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int any=1) Spell(mark_of_the_wild)
	#bear_form
	if not Stance(druid_bear_form) Spell(bear_form)
	#enrage
	Spell(enrage)
}

AddFunction GuardianPrecombatShortCdActions {}

AddFunction GuardianPrecombatCdActions {}

### Guardian icons.
AddCheckBox(opt_druid_guardian "Show Guardian icons" specialization=guardian default)
AddCheckBox(opt_druid_guardian_aoe L(AOE) specialization=guardian default)

AddIcon specialization=guardian help=shortcd enemies=1 checkbox=opt_druid_guardian checkbox=!opt_druid_guardian_aoe
{
	if InCombat(no) GuardianPrecombatShortCdActions()
	GuardianDefaultShortCdActions()
}

AddIcon specialization=guardian help=shortcd checkbox=opt_druid_guardian checkbox=opt_druid_guardian_aoe
{
	if InCombat(no) GuardianPrecombatShortCdActions()
	GuardianDefaultShortCdActions()
}

AddIcon specialization=guardian help=main enemies=1 checkbox=opt_druid_guardian
{
	if InCombat(no) GuardianPrecombatActions()
	GuardianDefaultActions()
}

AddIcon specialization=guardian help=aoe checkbox=opt_druid_guardian checkbox=opt_druid_guardian_aoe
{
	if InCombat(no) GuardianPrecombatActions()

	# AoE rotation: Mangle > Thrash > Swipe
	if target.DebuffRemaining(thrash_bear_debuff) < 3 Spell(thrash_bear)
	Spell(mangle_bear)
	Spell(thrash_bear)
	Spell(swipe_bear)
}

AddIcon specialization=guardian help=cd enemies=1 checkbox=opt_druid_guardian checkbox=!opt_druid_guardian_aoe
{
	if InCombat(no) GuardianPrecombatCdActions()
	GuardianDefaultCdActions()
}

AddIcon specialization=guardian help=cd checkbox=opt_druid_guardian checkbox=opt_druid_guardian_aoe
{
	if InCombat(no) GuardianPrecombatCdActions()
	GuardianDefaultCdActions()
}

###
### Restoration
###

# Swiftmend requires either a Rejuvenation or Regrowth HoT to be on the target before
# it is usable, but we want to show Swiftmend as usable if the cooldown is up.
#
AddFunction Swiftmend
{
	if not SpellCooldown(swiftmend) > 0 Texture(inv_relics_idolofrejuvenation help=Swiftmend)
}

AddFunction RestorationMainActions
{
	if WildMushroomCount() < 1 Spell(wild_mushroom_heal)

	# Cast instant/mana-free Healing Touch or Regrowth.
	if BuffStacks(sage_mender_buff) == 5 Spell(healing_touch)
	if BuffPresent(omen_of_clarity_heal_buff)
	{
		if Glyph(glyph_of_regrowth) Spell(regrowth)
		Spell(healing_touch)
	}
	if BuffPresent(natures_swiftness_buff) Spell(healing_touch)

	# Maintain 100% uptime on Harmony mastery buff.
	if BuffRemaining(harmony_buff) < 6
	{
		if BuffCountOnAny(rejuvenation_buff) > 0 or BuffCountOnAny(regrowth_buff) > 0 Swiftmend()
		Spell(nourish)
	}

	# Keep one Lifebloom stack up on the raid.
	if BuffRemainingOnAny(lifebloom_buff stacks=3) < 4 Spell(lifebloom)

	#innervate,if=mana.pct<90
	if ManaPercent() < 90 Spell(innervate)

	# Cast Cenarion Ward on cooldown, usually on the tank.
	if Talent(cenarion_ward_talent) Spell(cenarion_ward)
}

AddFunction RestorationAoeActions
{
	if BuffPresent(tree_of_life_buff)
	{
		Spell(wild_growth)
		if BuffPresent(omen_of_clarity_heal_buff) Spell(regrowth)
	}

	if BuffExpires(tree_of_life_buff)
	{
		Spell(wild_growth)
		if not Glyph(glyph_of_efflorescence) Swiftmend()
		if BuffCountOnAny(rejuvenation_buff) > 4 Spell(genesis)
	}
}

AddFunction RestorationShortCdActions
{
	if WildMushroomIsCharged() Spell(wild_mushroom_bloom)
}

AddFunction RestorationCdActions
{
	InterruptActions()
	if Talent(force_of_nature_talent) Spell(force_of_nature_heal)
	if Talent(incarnation_talent) Spell(incarnation_heal)
	if Talent(heart_of_the_wild_talent) Spell(heart_of_the_wild_heal)
	if Talent(natures_vigil_talent) Spell(natures_vigil)
}

AddFunction RestorationPrecombatActions
{
	if BuffRemaining(str_agi_int any=1) < 600 Spell(mark_of_the_wild)
}

### Restoration icons.
AddCheckBox(opt_druid_restoration "Show Restoration icons" specialization=restoration default)
AddCheckBox(opt_druid_restoration_aoe L(AOE) specialization=restoration default)

AddIcon specialization=restoration help=shortcd checkbox=opt_druid_restoration
{
	RestorationShortCdActions()
}

AddIcon specialization=restoration help=main checkbox=opt_druid_restoration
{
	if InCombat(no) RestorationPrecombatActions()
	RestorationMainActions()
}

AddIcon specialization=restoration help=aoe checkbox=opt_druid_restoration checkbox=opt_druid_restoration_aoe
{
	RestorationAoeActions()
}

AddIcon specialization=restoration help=cd checkbox=opt_druid_restoration
{
	RestorationCdActions()
}
]]

	OvaleScripts:RegisterScript("DRUID", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("DRUID", "Ovale", desc, code, "script")
end
