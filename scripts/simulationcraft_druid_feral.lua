local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Druid_Feral_T16M"
	local desc = "[6.0] SimulationCraft: Druid_Feral_T16M"
	local code = [[
# Based on SimulationCraft profile "Druid_Feral_T16M".
#	class=druid
#	spec=feral
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#UZ!...0...
#	glyphs=savage_roar

Include(ovale_common)
Include(ovale_druid_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction GetInMeleeRange
{
	if Stance(druid_bear_form) and not target.InRange(mangle)
	{
		if target.InRange(wild_charge_bear) Spell(wild_charge_bear)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
	if Stance(druid_cat_form) and not target.InRange(shred)
	{
		if target.InRange(wild_charge_cat) Spell(wild_charge_cat)
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

AddFunction FeralPrecombatActions
{
	#flask,type=winds
	#food,type=seafood_magnifique_feast
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#cat_form
	Spell(cat_form)
	#prowl
	if BuffExpires(stealthed_buff any=1) Spell(prowl)
	#snapshot_stats
	#potion,name=tolvir
	UsePotionAgility()
}

AddFunction FeralDefaultActions
{
	#rake,if=buff.prowl.up|buff.shadowmeld.up
	if BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) Spell(rake)
	#auto_attack
	#skull_bash
	InterruptActions()
	#force_of_nature,if=charges=3|trinket.proc.all.react|target.time_to_die<20
	if Charges(force_of_nature_melee) == 3 or BuffPresent(trinket_proc_any_buff) or target.TimeToDie() < 20 Spell(force_of_nature_melee)
	#potion,name=tolvir,if=target.time_to_die<=40
	if target.TimeToDie() <= 40 UsePotionAgility()
	#blood_fury,sync=tigers_fury
	if not SpellCooldown(tigers_fury) > 0 Spell(blood_fury_apsp)
	#berserking,sync=tigers_fury
	if not SpellCooldown(tigers_fury) > 0 Spell(berserking)
	#arcane_torrent,sync=tigers_fury
	if not SpellCooldown(tigers_fury) > 0 Spell(arcane_torrent_energy)
	#incarnation,sync=tigers_fury
	if not SpellCooldown(tigers_fury) > 0 Spell(incarnation_melee)
	#tigers_fury,if=(!buff.omen_of_clarity.react&energy.max-energy>=60)|energy.max-energy>=80
	if not BuffPresent(omen_of_clarity_melee_buff) and MaxEnergy() - Energy() >= 60 or MaxEnergy() - Energy() >= 80 Spell(tigers_fury)
	#potion,name=tolvir,sync=berserk,if=target.health.pct<25
	if target.HealthPercent() < 25 and not SpellCooldown(berserk_cat) > 0 UsePotionAgility()
	#berserk,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) Spell(berserk_cat)
	#shadowmeld,if=dot.rake.remains<4.5&energy>=35&dot.rake.pmultiplier<2&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(!talent.incarnation.enabled|cooldown.incarnation.remains>15)
	if target.DebuffRemaining(rake_debuff) < 4.5 and Energy() >= 35 and target.DebuffDamageMultiplier(rake_debuff) < 2 and { BuffPresent(bloodtalons_buff) or not Talent(bloodtalons_talent) } and { not Talent(incarnation_talent) or SpellCooldown(incarnation_melee) > 15 } Spell(shadowmeld)
	#ferocious_bite,cycle_targets=1,if=dot.rip.ticking&dot.rip.remains<3&target.health.pct<25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.HealthPercent() < 25 Spell(ferocious_bite)
	#healing_touch,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&(combo_points>=4|buff.predatory_swiftness.remains<1.5)
	if Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and { ComboPoints() >= 4 or BuffRemaining(predatory_swiftness_buff) < 1.5 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.remains<3
	if BuffRemaining(savage_roar_buff) < 3 Spell(savage_roar)
	#thrash_cat,if=buff.omen_of_clarity.react&remains<4.5&active_enemies>1
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemaining(thrash_cat_debuff) < 4.5 and Enemies() > 1 Spell(thrash_cat)
	#thrash_cat,if=!talent.bloodtalons.enabled&combo_points=5&remains<4.5&buff.omen_of_clarity.react
	if not Talent(bloodtalons_talent) and ComboPoints() == 5 and target.DebuffRemaining(thrash_cat_debuff) < 4.5 and BuffPresent(omen_of_clarity_melee_buff) Spell(thrash_cat)
	#call_action_list,name=finisher,if=combo_points=5
	if ComboPoints() == 5 FeralFinisherActions()
	#call_action_list,name=maintain
	FeralMaintainActions()
	#call_action_list,name=generator,if=combo_points<5
	if ComboPoints() < 5 FeralGeneratorActions()
}

AddFunction FeralMaintainActions
{
	#rake,cycle_targets=1,if=!talent.bloodtalons.enabled&remains<3&combo_points<5
	if not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < 3 and ComboPoints() < 5 Spell(rake)
	#rake,cycle_targets=1,if=!talent.bloodtalons.enabled&remains<4.5&combo_points<5&persistent_multiplier>dot.rake.pmultiplier
	if not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < 4.5 and ComboPoints() < 5 and DamageMultiplier(rake) > target.DebuffDamageMultiplier(rake_debuff) Spell(rake)
	#rake,cycle_targets=1,if=talent.bloodtalons.enabled&remains<4.5&combo_points<5&(!buff.predatory_swiftness.up|buff.bloodtalons.up|persistent_multiplier>dot.rake.pmultiplier)
	if Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < 4.5 and ComboPoints() < 5 and { not BuffPresent(predatory_swiftness_buff) or BuffPresent(bloodtalons_buff) or DamageMultiplier(rake) > target.DebuffDamageMultiplier(rake_debuff) } Spell(rake)
	#thrash_cat,if=talent.bloodtalons.enabled&combo_points=5&remains<4.5&buff.omen_of_clarity.react
	if Talent(bloodtalons_talent) and ComboPoints() == 5 and target.DebuffRemaining(thrash_cat_debuff) < 4.5 and BuffPresent(omen_of_clarity_melee_buff) Spell(thrash_cat)
	#pool_resource,for_next=1
	#thrash_cat,if=remains<4.5&active_enemies>1
	if target.DebuffRemaining(thrash_cat_debuff) < 4.5 and Enemies() > 1 Spell(thrash_cat)
	unless target.DebuffRemaining(thrash_cat_debuff) < 4.5 and Enemies() > 1 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
	{
		#moonfire_cat,cycle_targets=1,if=combo_points<5&remains<4.2&active_enemies<=10
		if ComboPoints() < 5 and target.DebuffRemaining(moonfire_cat_debuff) < 4.2 and Enemies() <= 10 Spell(moonfire_cat)
		#rake,cycle_targets=1,if=persistent_multiplier>dot.rake.pmultiplier&combo_points<5
		if DamageMultiplier(rake) > target.DebuffDamageMultiplier(rake_debuff) and ComboPoints() < 5 Spell(rake)
	}
}

AddFunction FeralGeneratorActions
{
	#swipe,if=active_enemies>=3
	if Enemies() >= 3 Spell(swipe)
	#shred,if=active_enemies<3
	if Enemies() < 3 Spell(shred)
}

AddFunction FeralFinisherActions
{
	#ferocious_bite,cycle_targets=1,if=target.health.pct<25&dot.rip.ticking&energy>=max_fb_energy
	if target.HealthPercent() < 25 and target.DebuffPresent(rip_debuff) and Energy() >= EnergyCost(ferocious_bite max=1) Spell(ferocious_bite)
	#rip,cycle_targets=1,if=remains<3
	if target.DebuffRemaining(rip_debuff) < 3 Spell(rip)
	#rip,cycle_targets=1,if=remains<7.2&persistent_multiplier>dot.rip.pmultiplier
	if target.DebuffRemaining(rip_debuff) < 7.2 and DamageMultiplier(rip) > target.DebuffDamageMultiplier(rip_debuff) Spell(rip)
	#savage_roar,if=(energy.time_to_max<=1|buff.berserk.up|cooldown.tigers_fury.remains<3)&buff.savage_roar.remains<12.6
	if { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) or SpellCooldown(tigers_fury) < 3 } and BuffRemaining(savage_roar_buff) < 12.6 Spell(savage_roar)
	#ferocious_bite,if=(energy.time_to_max<=1|buff.berserk.up|(cooldown.tigers_fury.remains<3&energy>=max_fb_energy))
	if TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) or SpellCooldown(tigers_fury) < 3 and Energy() >= EnergyCost(ferocious_bite max=1) Spell(ferocious_bite)
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
# ferocious_bite
# force_of_nature_melee
# healing_touch
# incarnation_melee
# incarnation_talent
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
# virmens_bite_potion
# war_stomp
# wild_charge_bear
# wild_charge_cat
]]
	OvaleScripts:RegisterScript("DRUID", name, desc, code, "reference")
end
