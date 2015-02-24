local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_druid_feral_t17m"
	local desc = "[6.1] SimulationCraft: Druid_Feral_T17M"
	local code = [[
# Based on SimulationCraft profile "Druid_Feral_T17M".
#	class=druid
#	spec=feral
#	talents=3002002
#	glyphs=savage_roar

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=feral)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=feral)
AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default specialization=feral)

AddFunction FeralUsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction FeralUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction FeralGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred)
	{
		if target.InRange(wild_charge) Spell(wild_charge)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction FeralInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(skull_bash) Spell(skull_bash)
		if not target.Classification(worldboss)
		{
			if target.InRange(mighty_bash) Spell(mighty_bash)
			Spell(typhoon)
			if target.InRange(maim) Spell(maim)
			Spell(war_stomp)
		}
	}
}

### actions.default

AddFunction FeralDefaultMainActions
{
	#cat_form
	Spell(cat_form)
	#rake,if=buff.prowl.up|buff.shadowmeld.up
	if BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) Spell(rake)
	#ferocious_bite,cycle_targets=1,if=dot.rip.ticking&dot.rip.remains<3&target.health.pct<25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.HealthPercent() < 25 Spell(ferocious_bite)
	#healing_touch,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&(combo_points>=4|buff.predatory_swiftness.remains<1.5)
	if Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and { ComboPoints() >= 4 or BuffRemaining(predatory_swiftness_buff) < 1.5 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.down
	if BuffExpires(savage_roar_buff) Spell(savage_roar)
	#pool_resource,for_next=1
	#thrash_cat,cycle_targets=1,if=remains<4.5&(active_enemies>=2&set_bonus.tier17_2pc|active_enemies>=4)
	if target.DebuffRemaining(thrash_cat_debuff) < 4.5 and { Enemies() >= 2 and ArmorSetBonus(T17 2) or Enemies() >= 4 } Spell(thrash_cat)
	unless target.DebuffRemaining(thrash_cat_debuff) < 4.5 and { Enemies() >= 2 and ArmorSetBonus(T17 2) or Enemies() >= 4 } and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
	{
		#call_action_list,name=finisher,if=combo_points=5
		if ComboPoints() == 5 FeralFinisherMainActions()
		#savage_roar,if=buff.savage_roar.remains<gcd
		if BuffRemaining(savage_roar_buff) < GCD() Spell(savage_roar)
		#call_action_list,name=maintain,if=combo_points<5
		if ComboPoints() < 5 FeralMaintainMainActions()
		#pool_resource,for_next=1
		#thrash_cat,cycle_targets=1,if=remains<4.5&active_enemies>=2
		if target.DebuffRemaining(thrash_cat_debuff) < 4.5 and Enemies() >= 2 Spell(thrash_cat)
		unless target.DebuffRemaining(thrash_cat_debuff) < 4.5 and Enemies() >= 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
		{
			#call_action_list,name=generator,if=combo_points<5
			if ComboPoints() < 5 FeralGeneratorMainActions()
		}
	}
}

AddFunction FeralDefaultShortCdActions
{
	unless Spell(cat_form)
	{
		#wild_charge
		FeralGetInMeleeRange()
		#displacer_beast,if=movement.distance>10
		if 0 > 10 Spell(displacer_beast)
		#dash,if=movement.distance&buff.displacer_beast.down&buff.wild_charge_movement.down
		if 0 and BuffExpires(displacer_beast_buff) and True(wild_charge_movement_down) Spell(dash)

		unless { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
		{
			#auto_attack
			FeralGetInMeleeRange()
			#force_of_nature,if=charges=3|trinket.proc.all.react|target.time_to_die<20
			if Charges(force_of_nature_melee) == 3 or BuffPresent(trinket_proc_any_buff) or target.TimeToDie() < 20 Spell(force_of_nature_melee)
			#tigers_fury,if=(!buff.omen_of_clarity.react&energy.max-energy>=60)|energy.max-energy>=80
			if not BuffPresent(omen_of_clarity_melee_buff) and MaxEnergy() - Energy() >= 60 or MaxEnergy() - Energy() >= 80 Spell(tigers_fury)
		}
	}
}

AddFunction FeralDefaultCdActions
{
	unless Spell(cat_form) or 0 > 10 and Spell(displacer_beast) or 0 and BuffExpires(displacer_beast_buff) and True(wild_charge_movement_down) and Spell(dash) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
	{
		#skull_bash
		FeralInterruptActions()
		#berserk,sync=tigers_fury,if=buff.king_of_the_jungle.up|!talent.incarnation.enabled
		if { not BuffPresent(omen_of_clarity_melee_buff) and MaxEnergy() - Energy() >= 60 or MaxEnergy() - Energy() >= 80 } and Spell(tigers_fury) and { BuffPresent(king_of_the_jungle_buff) or not Talent(incarnation_talent) } Spell(berserk_cat)
		#use_item,slot=trinket1,if=(prev.tigers_fury&(target.time_to_die>trinket.stat.any.cooldown|target.time_to_die<45))|prev.berserk|(buff.king_of_the_jungle.up&time<10)
		if PreviousSpell(tigers_fury) and { target.TimeToDie() > BuffCooldownDuration(trinket_stat_any_buff) or target.TimeToDie() < 45 } or PreviousSpell(berserk_cat) or BuffPresent(king_of_the_jungle_buff) and TimeInCombat() < 10 FeralUseItemActions()
		#potion,name=draenic_agility,if=(buff.berserk.remains>10&(target.time_to_die<180|(trinket.proc.all.react&target.health.pct<25)))|target.time_to_die<=40
		if BuffRemaining(berserk_cat_buff) > 10 and { target.TimeToDie() < 180 or BuffPresent(trinket_proc_any_buff) and target.HealthPercent() < 25 } or target.TimeToDie() <= 40 FeralUsePotionAgility()
		#blood_fury,sync=tigers_fury
		if { not BuffPresent(omen_of_clarity_melee_buff) and MaxEnergy() - Energy() >= 60 or MaxEnergy() - Energy() >= 80 } and Spell(tigers_fury) Spell(blood_fury_apsp)
		#berserking,sync=tigers_fury
		if { not BuffPresent(omen_of_clarity_melee_buff) and MaxEnergy() - Energy() >= 60 or MaxEnergy() - Energy() >= 80 } and Spell(tigers_fury) Spell(berserking)
		#arcane_torrent,sync=tigers_fury
		if { not BuffPresent(omen_of_clarity_melee_buff) and MaxEnergy() - Energy() >= 60 or MaxEnergy() - Energy() >= 80 } and Spell(tigers_fury) Spell(arcane_torrent_energy)
		#incarnation,if=cooldown.berserk.remains<10&energy.time_to_max>1
		if SpellCooldown(berserk_cat) < 10 and TimeToMaxEnergy() > 1 Spell(incarnation_melee)
		#shadowmeld,if=dot.rake.remains<4.5&energy>=35&dot.rake.pmultiplier<2&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(!talent.incarnation.enabled|cooldown.incarnation.remains>15)&!buff.king_of_the_jungle.up
		if target.DebuffRemaining(rake_debuff) < 4.5 and Energy() >= 35 and target.DebuffPersistentMultiplier(rake_debuff) < 2 and { BuffPresent(bloodtalons_buff) or not Talent(bloodtalons_talent) } and { not Talent(incarnation_talent) or SpellCooldown(incarnation_melee) > 15 } and not BuffPresent(king_of_the_jungle_buff) Spell(shadowmeld)
	}
}

### actions.finisher

AddFunction FeralFinisherMainActions
{
	#ferocious_bite,cycle_targets=1,max_energy=1,if=target.health.pct<25&dot.rip.ticking
	if Energy() >= EnergyCost(ferocious_bite max=1) and target.HealthPercent() < 25 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
	#rip,cycle_targets=1,if=remains<7.2&persistent_multiplier>dot.rip.pmultiplier&target.time_to_die-remains>18
	if target.DebuffRemaining(rip_debuff) < 7.2 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() - target.DebuffRemaining(rip_debuff) > 18 Spell(rip)
	#rip,cycle_targets=1,if=remains<7.2&persistent_multiplier=dot.rip.pmultiplier&(energy.time_to_max<=1|!talent.bloodtalons.enabled)&target.time_to_die-remains>18
	if target.DebuffRemaining(rip_debuff) < 7.2 and PersistentMultiplier(rip_debuff) == target.DebuffPersistentMultiplier(rip_debuff) and { TimeToMaxEnergy() <= 1 or not Talent(bloodtalons_talent) } and target.TimeToDie() - target.DebuffRemaining(rip_debuff) > 18 Spell(rip)
	#rip,cycle_targets=1,if=remains<2&target.time_to_die-remains>18
	if target.DebuffRemaining(rip_debuff) < 2 and target.TimeToDie() - target.DebuffRemaining(rip_debuff) > 18 Spell(rip)
	#savage_roar,if=(energy.time_to_max<=1|buff.berserk.up|cooldown.tigers_fury.remains<3)&buff.savage_roar.remains<12.6
	if { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) or SpellCooldown(tigers_fury) < 3 } and BuffRemaining(savage_roar_buff) < 12.6 Spell(savage_roar)
	#ferocious_bite,max_energy=1,if=(energy.time_to_max<=1|buff.berserk.up|cooldown.tigers_fury.remains<3)
	if Energy() >= EnergyCost(ferocious_bite max=1) and { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) or SpellCooldown(tigers_fury) < 3 } Spell(ferocious_bite)
}

### actions.generator

AddFunction FeralGeneratorMainActions
{
	#swipe,if=active_enemies>=3
	if Enemies() >= 3 Spell(swipe)
	#shred,if=active_enemies<3
	if Enemies() < 3 Spell(shred)
}

### actions.maintain

AddFunction FeralMaintainMainActions
{
	#rake,cycle_targets=1,if=remains<3&((target.time_to_die-remains>3&active_enemies<3)|target.time_to_die-remains>6)
	if target.DebuffRemaining(rake_debuff) < 3 and { target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 3 and Enemies() < 3 or target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 6 } Spell(rake)
	#rake,cycle_targets=1,if=remains<4.5&(persistent_multiplier>=dot.rake.pmultiplier|(talent.bloodtalons.enabled&(buff.bloodtalons.up|!buff.predatory_swiftness.up)))&((target.time_to_die-remains>3&active_enemies<3)|target.time_to_die-remains>6)
	if target.DebuffRemaining(rake_debuff) < 4.5 and { PersistentMultiplier(rake_debuff) >= target.DebuffPersistentMultiplier(rake_debuff) or Talent(bloodtalons_talent) and { BuffPresent(bloodtalons_buff) or not BuffPresent(predatory_swiftness_buff) } } and { target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 3 and Enemies() < 3 or target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 6 } Spell(rake)
	#moonfire_cat,cycle_targets=1,if=remains<4.2&active_enemies<=5&target.time_to_die-remains>tick_time*5
	if target.DebuffRemaining(moonfire_cat_debuff) < 4.2 and Enemies() <= 5 and target.TimeToDie() - target.DebuffRemaining(moonfire_cat_debuff) > target.TickTime(moonfire_cat_debuff) * 5 Spell(moonfire_cat)
	#rake,cycle_targets=1,if=persistent_multiplier>dot.rake.pmultiplier&active_enemies=1&((target.time_to_die-remains>3&active_enemies<3)|target.time_to_die-remains>6)
	if PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) and Enemies() == 1 and { target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 3 and Enemies() < 3 or target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 6 } Spell(rake)
}

### actions.precombat

AddFunction FeralPrecombatMainActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=pickled_eel
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#healing_touch,if=talent.bloodtalons.enabled&buff.bloodtalons.remains<20
	if Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 20 Spell(healing_touch)
	#cat_form
	Spell(cat_form)
	#prowl
	Spell(prowl)
}

AddFunction FeralPrecombatShortCdPostConditions
{
	not BuffPresent(str_agi_int_buff any=1) and Spell(mark_of_the_wild) or Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 20 and Spell(healing_touch) or Spell(cat_form) or Spell(prowl)
}

AddFunction FeralPrecombatCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) and Spell(mark_of_the_wild) or Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 20 and Spell(healing_touch) or Spell(cat_form) or Spell(prowl)
	{
		#snapshot_stats
		#potion,name=draenic_agility
		FeralUsePotionAgility()
	}
}

AddFunction FeralPrecombatCdPostConditions
{
	not BuffPresent(str_agi_int_buff any=1) and Spell(mark_of_the_wild) or Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 20 and Spell(healing_touch) or Spell(cat_form) or Spell(prowl)
}

### Feral icons.

AddCheckBox(opt_druid_feral_aoe L(AOE) default specialization=feral)

AddIcon checkbox=!opt_druid_feral_aoe enemies=1 help=shortcd specialization=feral
{
	unless not InCombat() and FeralPrecombatShortCdPostConditions()
	{
		FeralDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_druid_feral_aoe help=shortcd specialization=feral
{
	unless not InCombat() and FeralPrecombatShortCdPostConditions()
	{
		FeralDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=feral
{
	if not InCombat() FeralPrecombatMainActions()
	FeralDefaultMainActions()
}

AddIcon checkbox=opt_druid_feral_aoe help=aoe specialization=feral
{
	if not InCombat() FeralPrecombatMainActions()
	FeralDefaultMainActions()
}

AddIcon checkbox=!opt_druid_feral_aoe enemies=1 help=cd specialization=feral
{
	if not InCombat() FeralPrecombatCdActions()
	unless not InCombat() and FeralPrecombatCdPostConditions()
	{
		FeralDefaultCdActions()
	}
}

AddIcon checkbox=opt_druid_feral_aoe help=cd specialization=feral
{
	if not InCombat() FeralPrecombatCdActions()
	unless not InCombat() and FeralPrecombatCdPostConditions()
	{
		FeralDefaultCdActions()
	}
}

### Required symbols
# arcane_torrent_energy
# berserk_cat
# berserk_cat_buff
# berserking
# blood_fury_apsp
# bloodtalons_buff
# bloodtalons_talent
# cat_form
# dash
# displacer_beast
# displacer_beast_buff
# draenic_agility_potion
# ferocious_bite
# force_of_nature_melee
# healing_touch
# incarnation_melee
# incarnation_talent
# king_of_the_jungle_buff
# maim
# mangle
# mark_of_the_wild
# mighty_bash
# moonfire_cat
# moonfire_cat_debuff
# omen_of_clarity_melee_buff
# predatory_swiftness_buff
# prowl
# prowl_buff
# rake
# rake_debuff
# rip
# rip_debuff
# savage_roar
# savage_roar_buff
# shadowmeld
# shadowmeld_buff
# shred
# skull_bash
# swipe
# thrash_cat
# thrash_cat_debuff
# tigers_fury
# typhoon
# war_stomp
# wild_charge
# wild_charge_bear
# wild_charge_cat
]]
	OvaleScripts:RegisterScript("DRUID", "feral", name, desc, code, "script")
end
