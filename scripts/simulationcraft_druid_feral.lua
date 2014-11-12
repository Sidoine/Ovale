local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Druid_Feral_T17M"
	local desc = "[6.0] SimulationCraft: Druid_Feral_T17M"
	local code = [[
# Based on SimulationCraft profile "Druid_Feral_T17M".
#	class=druid
#	spec=feral
#	talents=3002002
#	glyphs=savage_roar

Include(ovale_common)
Include(ovale_druid_spells)

AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction GetInMeleeRange
{
	if Stance(druid_bear_form) and not target.InRange(mangle) or Stance(druid_cat_form) and not target.InRange(shred)
	{
		if target.InRange(wild_charge) Spell(wild_charge)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
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

AddFunction FeralDefaultActions
{
	#cat_form
	Spell(cat_form)
	#wild_charge
	if target.InRange(wild_charge) Spell(wild_charge)
	#displacer_beast,if=movement.distance>10
	if 0 > 10 Spell(displacer_beast)
	#dash,if=movement.distance&buff.displacer_beast.down&buff.wild_charge_movement.down
	if 0 and BuffExpires(displacer_beast_buff) and True(wild_charge_movement_down) Spell(dash)
	#rake,if=buff.prowl.up|buff.shadowmeld.up
	if BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) Spell(rake)
	#auto_attack
	#skull_bash
	InterruptActions()
	#force_of_nature,if=charges=3|trinket.proc.all.react|target.time_to_die<20
	if Charges(force_of_nature_melee) == 3 or BuffPresent(trinket_proc_any_buff) or target.TimeToDie() < 20 Spell(force_of_nature_melee)
	#potion,name=draenic_agility,if=target.time_to_die<=40
	if target.TimeToDie() <= 40 UsePotionAgility()
	#use_item,slot=trinket1,sync=tigers_fury
	if not SpellCooldown(tigers_fury) > 0 UseItemActions()
	#blood_fury,sync=tigers_fury
	if not SpellCooldown(tigers_fury) > 0 Spell(blood_fury_apsp)
	#berserking,sync=tigers_fury
	if not SpellCooldown(tigers_fury) > 0 Spell(berserking)
	#arcane_torrent,sync=tigers_fury
	if not SpellCooldown(tigers_fury) > 0 Spell(arcane_torrent_energy)
	#tigers_fury,if=(!buff.omen_of_clarity.react&energy.max-energy>=60)|energy.max-energy>=80
	if not BuffPresent(omen_of_clarity_melee_buff) and MaxEnergy() - Energy() >= 60 or MaxEnergy() - Energy() >= 80 Spell(tigers_fury)
	#incarnation,if=cooldown.berserk.remains<10&energy.time_to_max>1
	if SpellCooldown(berserk_cat) < 10 and TimeToMaxEnergy() > 1 Spell(incarnation_melee)
	#potion,name=draenic_agility,sync=berserk,if=target.health.pct<25
	if target.HealthPercent() < 25 and not SpellCooldown(berserk_cat) > 0 UsePotionAgility()
	#berserk,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) Spell(berserk_cat)
	#shadowmeld,if=dot.rake.remains<4.5&energy>=35&dot.rake.pmultiplier<2&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(!talent.incarnation.enabled|cooldown.incarnation.remains>15)&!buff.king_of_the_jungle.up
	if target.DebuffRemaining(rake_debuff) < 4.5 and Energy() >= 35 and target.DebuffDamageMultiplier(rake_debuff) < 2 and { BuffPresent(bloodtalons_buff) or not Talent(bloodtalons_talent) } and { not Talent(incarnation_talent) or SpellCooldown(incarnation_melee) > 15 } and not BuffPresent(king_of_the_jungle_buff) Spell(shadowmeld)
	#ferocious_bite,cycle_targets=1,if=dot.rip.ticking&dot.rip.remains<3&target.health.pct<25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.HealthPercent() < 25 Spell(ferocious_bite)
	#healing_touch,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&(combo_points>=4|buff.predatory_swiftness.remains<1.5)
	if Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and { ComboPoints() >= 4 or BuffRemaining(predatory_swiftness_buff) < 1.5 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.remains<3
	if BuffRemaining(savage_roar_buff) < 3 Spell(savage_roar)
	#thrash_cat,cycle_targets=1,if=buff.omen_of_clarity.react&remains<4.5&active_enemies>1
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemaining(thrash_cat_debuff) < 4.5 and Enemies() > 1 Spell(thrash_cat)
	#thrash_cat,cycle_targets=1,if=!talent.bloodtalons.enabled&combo_points=5&remains<4.5&buff.omen_of_clarity.react
	if not Talent(bloodtalons_talent) and ComboPoints() == 5 and target.DebuffRemaining(thrash_cat_debuff) < 4.5 and BuffPresent(omen_of_clarity_melee_buff) Spell(thrash_cat)
	#pool_resource,for_next=1
	#thrash_cat,cycle_targets=1,if=remains<4.5&active_enemies>1
	if target.DebuffRemaining(thrash_cat_debuff) < 4.5 and Enemies() > 1 Spell(thrash_cat)
	unless target.DebuffRemaining(thrash_cat_debuff) < 4.5 and Enemies() > 1 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
	{
		#call_action_list,name=finisher,if=combo_points=5
		if ComboPoints() == 5 FeralFinisherActions()
		#call_action_list,name=maintain
		FeralMaintainActions()
		#call_action_list,name=generator,if=combo_points<5
		if ComboPoints() < 5 FeralGeneratorActions()
	}
}

AddFunction FeralFinisherActions
{
	#ferocious_bite,cycle_targets=1,max_energy=1,if=target.health.pct<25&dot.rip.ticking
	if Energy() >= EnergyCost(ferocious_bite max=1) and target.HealthPercent() < 25 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
	#rip,cycle_targets=1,if=remains<3&target.time_to_die-remains>18
	if target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() - target.DebuffRemaining(rip_debuff) > 18 Spell(rip)
	#rip,cycle_targets=1,if=remains<7.2&persistent_multiplier>dot.rip.pmultiplier&target.time_to_die-remains>18
	if target.DebuffRemaining(rip_debuff) < 7.2 and DamageMultiplier(rip) > target.DebuffDamageMultiplier(rip_debuff) and target.TimeToDie() - target.DebuffRemaining(rip_debuff) > 18 Spell(rip)
	#savage_roar,if=(energy.time_to_max<=1|buff.berserk.up|cooldown.tigers_fury.remains<3)&buff.savage_roar.remains<12.6
	if { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) or SpellCooldown(tigers_fury) < 3 } and BuffRemaining(savage_roar_buff) < 12.6 Spell(savage_roar)
	#ferocious_bite,max_energy=1,if=(energy.time_to_max<=1|buff.berserk.up|cooldown.tigers_fury.remains<3)
	if Energy() >= EnergyCost(ferocious_bite max=1) and { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) or SpellCooldown(tigers_fury) < 3 } Spell(ferocious_bite)
}

AddFunction FeralGeneratorActions
{
	#swipe,if=active_enemies>=3
	if Enemies() >= 3 Spell(swipe)
	#shred,if=active_enemies<3
	if Enemies() < 3 Spell(shred)
}

AddFunction FeralMaintainActions
{
	#rake,cycle_targets=1,if=!talent.bloodtalons.enabled&remains<3&combo_points<5&((target.time_to_die-remains>3&active_enemies<3)|target.time_to_die-remains>6)
	if not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < 3 and ComboPoints() < 5 and { target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 3 and Enemies() < 3 or target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 6 } Spell(rake)
	#rake,cycle_targets=1,if=!talent.bloodtalons.enabled&remains<4.5&combo_points<5&persistent_multiplier>dot.rake.pmultiplier&((target.time_to_die-remains>3&active_enemies<3)|target.time_to_die-remains>6)
	if not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < 4.5 and ComboPoints() < 5 and DamageMultiplier(rake) > target.DebuffDamageMultiplier(rake_debuff) and { target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 3 and Enemies() < 3 or target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 6 } Spell(rake)
	#rake,cycle_targets=1,if=talent.bloodtalons.enabled&remains<4.5&combo_points<5&(!buff.predatory_swiftness.up|buff.bloodtalons.up|persistent_multiplier>dot.rake.pmultiplier)&((target.time_to_die-remains>3&active_enemies<3)|target.time_to_die-remains>6)
	if Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < 4.5 and ComboPoints() < 5 and { not BuffPresent(predatory_swiftness_buff) or BuffPresent(bloodtalons_buff) or DamageMultiplier(rake) > target.DebuffDamageMultiplier(rake_debuff) } and { target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 3 and Enemies() < 3 or target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 6 } Spell(rake)
	#thrash_cat,cycle_targets=1,if=talent.bloodtalons.enabled&combo_points=5&remains<4.5&buff.omen_of_clarity.react
	if Talent(bloodtalons_talent) and ComboPoints() == 5 and target.DebuffRemaining(thrash_cat_debuff) < 4.5 and BuffPresent(omen_of_clarity_melee_buff) Spell(thrash_cat)
	#moonfire_cat,cycle_targets=1,if=combo_points<5&remains<4.2&active_enemies<6&target.time_to_die-remains>tick_time*5
	if ComboPoints() < 5 and target.DebuffRemaining(moonfire_cat_debuff) < 4.2 and Enemies() < 6 and target.TimeToDie() - target.DebuffRemaining(moonfire_cat_debuff) > target.TickTime(moonfire_cat_debuff) * 5 Spell(moonfire_cat)
	#rake,cycle_targets=1,if=persistent_multiplier>dot.rake.pmultiplier&combo_points<5&active_enemies=1
	if DamageMultiplier(rake) > target.DebuffDamageMultiplier(rake_debuff) and ComboPoints() < 5 and Enemies() == 1 Spell(rake)
}

AddFunction FeralPrecombatActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=blackrock_barbecue
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#healing_touch,if=talent.bloodtalons.enabled
	if Talent(bloodtalons_talent) Spell(healing_touch)
	#cat_form
	Spell(cat_form)
	#prowl
	if BuffExpires(stealthed_buff any=1) Spell(prowl)
	#snapshot_stats
	#potion,name=draenic_agility
	UsePotionAgility()
}

AddIcon specialization=feral help=main enemies=1
{
	if not InCombat() FeralPrecombatActions()
	FeralDefaultActions()
}

AddIcon specialization=feral help=aoe
{
	if not InCombat() FeralPrecombatActions()
	FeralDefaultActions()
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
# tigers_fury_buff
# typhoon
# war_stomp
# wild_charge
# wild_charge_bear
# wild_charge_cat
]]
	OvaleScripts:RegisterScript("DRUID", name, desc, code, "reference")
end
