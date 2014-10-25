local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_druid"
	local desc = "[6.0.2] Ovale: Feral, Guardian"
	local code = [[
# Ovale druid script based on SimulationCraft.

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

###
### Feral
###
# Based on SimulationCraft profile "Druid_Feral_T16M".
#	class=druid
#	spec=feral
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#UZ!...0...
#	glyphs=savage_roar

# ActionList: FeralDefaultActions --> main, predict, shortcd, cd

AddFunction FeralDefaultActions
{
	FeralDefaultPredictActions()
	#pool_resource,for_next=1
	#thrash_cat,if=remains<=duration*0.3&active_enemies>1
	unless target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() > 1 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
	{
		#rake,cycle_targets=1,if=persistent_multiplier>dot.rake.pmultiplier&combo_points<5
		if DamageMultiplier(rake) > target.DebuffDamageMultiplier(rake_debuff) and ComboPoints() < 5 Spell(rake)
		#swipe,if=combo_points<5&active_enemies>=3
		if ComboPoints() < 5 and Enemies() >= 3 Spell(swipe)
		#shred,if=combo_points<5&active_enemies<3
		if ComboPoints() < 5 and Enemies() < 3 Spell(shred)
	}
}

AddFunction FeralDefaultPredictActions
{
	#rake,if=buff.prowl.up|buff.shadowmeld.up
	if BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) Spell(rake)
	#auto_attack
	#ferocious_bite,cycle_targets=1,if=dot.rip.ticking&dot.rip.remains<=3&target.health.pct<25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) <= 3 and target.HealthPercent() < 25 Spell(ferocious_bite)
	#healing_touch,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&(combo_points>=4|buff.predatory_swiftness.remains<1.5)
	if Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and { ComboPoints() >= 4 or BuffRemaining(predatory_swiftness_buff) < 1.5 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.remains<3
	if BuffRemaining(savage_roar_buff) < 3 Spell(savage_roar)
	#thrash_cat,if=buff.omen_of_clarity.react&remains<=duration*0.3&active_enemies>1
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() > 1 Spell(thrash_cat)
	#ferocious_bite,cycle_targets=1,if=combo_points=5&target.health.pct<25&dot.rip.ticking&energy>=max_fb_energy
	if ComboPoints() == 5 and target.HealthPercent() < 25 and target.DebuffPresent(rip_debuff) and Energy() >= EnergyCost(ferocious_bite max=1) Spell(ferocious_bite)
	#rip,cycle_targets=1,if=combo_points=5&remains<=3
	if ComboPoints() == 5 and target.DebuffRemaining(rip_debuff) <= 3 Spell(rip)
	#rip,cycle_targets=1,if=combo_points=5&remains<=duration*0.3&persistent_multiplier>dot.rip.pmultiplier
	if ComboPoints() == 5 and target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 and DamageMultiplier(rip) > target.DebuffDamageMultiplier(rip_debuff) Spell(rip)
	#savage_roar,if=combo_points=5&(energy.time_to_max<=1|buff.berserk.up|cooldown.tigers_fury.remains<3)&buff.savage_roar.remains<42*0.3
	if ComboPoints() == 5 and { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) or SpellCooldown(tigers_fury) < 3 } and BuffRemaining(savage_roar_buff) < 42 * 0.3 Spell(savage_roar)
	#ferocious_bite,if=combo_points=5&(energy.time_to_max<=1|buff.berserk.up|(cooldown.tigers_fury.remains<3&energy>=max_fb_energy))
	if ComboPoints() == 5 and { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) or SpellCooldown(tigers_fury) < 3 and Energy() >= EnergyCost(ferocious_bite max=1) } Spell(ferocious_bite)
	#rake,cycle_targets=1,if=remains<=3&combo_points<5
	if target.DebuffRemaining(rake_debuff) <= 3 and ComboPoints() < 5 Spell(rake)
	#rake,cycle_targets=1,if=remains<=duration*0.3&combo_points<5&persistent_multiplier>dot.rake.pmultiplier
	if target.DebuffRemaining(rake_debuff) <= BaseDuration(rake_debuff) * 0.3 and ComboPoints() < 5 and DamageMultiplier(rake) > target.DebuffDamageMultiplier(rake_debuff) Spell(rake)
	#thrash_cat,if=combo_points=5&buff.omen_of_clarity.react
	if ComboPoints() == 5 and BuffPresent(omen_of_clarity_melee_buff) Spell(thrash_cat)
	#pool_resource,for_next=1
	#thrash_cat,if=remains<=duration*0.3&active_enemies>1
	if target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() > 1 Spell(thrash_cat)
}

AddFunction FeralDefaultShortCdActions
{
	# CHANGE: Get within melee range of the target.
	GetInMeleeRange()
	unless { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
	#force_of_nature,if=charges=3|trinket.proc.all.react|target.time_to_die<20
	if Charges(force_of_nature_melee) == 3 or BuffPresent(trinket_proc_agility_buff) or target.TimeToDie() < 20 Spell(force_of_nature_melee)
	#tigers_fury,if=(!buff.omen_of_clarity.react&energy.max-energy>=60)|energy.max-energy>=80
	if not BuffPresent(omen_of_clarity_melee_buff) and MaxEnergy() - Energy() >= 60 or MaxEnergy() - Energy() >= 80 Spell(tigers_fury)
}

# CHANGE: Helper function for Tiger's Fury sync condition.
AddFunction FeralTigersFurySyncCondition
{
	#tigers_fury,if=(!buff.omen_of_clarity.react&energy.max-energy>=60)|energy.max-energy>=80
	BuffPresent(tigers_fury_buff) or { not BuffPresent(omen_of_clarity_melee_buff) and MaxEnergy() - Energy() >= 60 or MaxEnergy() - Energy() >= 80 } and not SpellCooldown(tigers_fury) > 0
}

AddFunction FeralDefaultCdActions
{
	unless { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
	{
		InterruptActions()
		#potion,name=tolvir,if=target.time_to_die<=40
		if target.TimeToDie() <= 40 UsePotionAgility()
		# CHANGE: Synchronize abilities that are used with Tiger's Fury using Tiger Fury's conditions.
		#tigers_fury,if=(!buff.omen_of_clarity.react&energy.max-energy>=60)|energy.max-energy>=80
		#blood_fury,sync=tigers_fury
		#if not SpellCooldown(tigers_fury) > 0 Spell(blood_fury_apsp)
		if FeralTigersFurySyncCondition() Spell(blood_fury_apsp)
		#berserking,sync=tigers_fury
		#if not SpellCooldown(tigers_fury) > 0 Spell(berserking)
		if FeralTigersFurySyncCondition() Spell(berserking)
		#arcane_torrent,sync=tigers_fury
		#if not SpellCooldown(tigers_fury) > 0 Spell(arcane_torrent_energy)
		if FeralTigersFurySyncCondition() Spell(arcane_torrent_energy)
		#incarnation,sync=tigers_fury
		#if not SpellCooldown(tigers_fury) > 0 Spell(incarnation_melee)
		if FeralTigersFurySyncCondition() Spell(incarnation_melee)
		#potion,name=tolvir,sync=berserk,if=target.health.pct<25
		#if target.HealthPercent() < 25 and not SpellCooldown(berserk_cat) > 0 UsePotionAgility()
		if target.HealthPercent() < 25 and { BuffPresent(berserk_cat_buff) or FeralTigersFurySyncCondition() and SpellCooldown(berserk_cat) > 0 } UsePotionAgility()
		#berserk,if=buff.tigers_fury.up
		#if BuffPresent(tigers_fury_buff) Spell(berserk_cat)
		if FeralTigersFurySyncCondition() Spell(berserk_cat)
		#shadowmeld,if=(buff.bloodtalons.up|!talent.bloodtalons.enabled)&dot.rake.remains<0.3*dot.rake.duration
		if { BuffPresent(bloodtalons_buff) or not Talent(bloodtalons_talent) } and target.DebuffRemaining(rake_debuff) < 0.3 * target.DebuffDuration(rake_debuff) Spell(shadowmeld)
	}
}

# ActionList: FeralPrecombatActions --> main, predict, shortcd, main

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
}

AddFunction FeralPrecombatPredictActions {}

AddFunction FeralPrecombatShortCdActions {}

AddFunction FeralPrecombatCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) and Spell(mark_of_the_wild)
		or Spell(cat_form)
		or BuffExpires(stealthed_buff any=1) Spell(prowl)
	{
		#potion,name=tolvir
		UsePotionAgility()
	}
}

### Feral Icons
AddCheckBox(opt_druid_feral_aoe L(AOE) specialization=feral default)

AddIcon specialization=feral help=shortcd enemies=1 checkbox=!opt_druid_feral_aoe
{
	if InCombat(no) FeralPrecombatShortCdActions()
	FeralDefaultShortCdActions()
}

AddIcon specialization=feral help=shortcd checkbox=opt_druid_feral_aoe
{
	if InCombat(no) FeralPrecombatShortCdActions()
	FeralDefaultShortCdActions()
}

AddIcon specialization=feral help=main enemies=1
{
	if InCombat(no) FeralPrecombatActions()
	FeralDefaultActions()
}

AddIcon specialization=feral help=predict enemies=1 checkbox=!opt_druid_feral_aoe
{
	if InCombat(no) FeralPrecombatPredictActions()
	FeralDefaultPredictActions()
}

AddIcon specialization=feral help=aoe checkbox=opt_druid_feral_aoe
{
	if InCombat(no) FeralPrecombatActions()
	FeralDefaultActions()
}

AddIcon specialization=feral help=cd enemies=1 checkbox=!opt_druid_feral_aoe
{
	if InCombat(no) FeralPrecombatCdActions()
	FeralDefaultCdActions()
}

AddIcon specialization=feral help=cd checkbox=opt_druid_feral_aoe
{
	if InCombat(no) FeralPrecombatCdActions()
	FeralDefaultCdActions()
}

###
### Guardian
###
# Based on SimulationCraft profile "Druid_Guardian_T16M".
#	class=druid
#	spec=guardian
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Ub!.1.0.1.
#	glyphs=maul

# ActionList: GuardianDefaultActions --> main, shortcd, cd

AddFunction GuardianDefaultActions
{
	#auto_attack
	#cenarion_ward
	Spell(cenarion_ward)
	#lacerate,cycle_targets=1,if=dot.lacerate.ticking&dot.lacerate.remains<2
	if target.DebuffPresent(lacerate_debuff) and target.DebuffRemaining(lacerate_debuff) < 2 Spell(lacerate)
	#mangle,if=active_enemies<4
	if Enemies() < 4 Spell(mangle)
	#thrash_bear,if=dot.thrash_bear.remains<1
	if target.DebuffRemaining(thrash_bear_debuff) < 1 Spell(thrash_bear)
	#healing_touch,if=buff.dream_of_cenarius.react&health.pct<10
	if BuffPresent(dream_of_cenarius_tank_buff) and HealthPercent() < 10 Spell(healing_touch)
	#thrash_bear,if=active_enemies>4
	if Enemies() > 4 Spell(thrash_bear)
	#lacerate,cycle_targets=1,if=!dot.lacerate.ticking
	if not target.DebuffPresent(lacerate_debuff) Spell(lacerate)
	#lacerate,cycle_targets=1,if=dot.lacerate.stack<3
	if target.DebuffStacks(lacerate_debuff) < 3 Spell(lacerate)
	#thrash_bear,if=active_enemies>1
	if Enemies() > 1 Spell(thrash_bear)
	#lacerate
	Spell(lacerate)
}

AddFunction GuardianDefaultShortCdActions
{
	# CHANGE: Get within melee range of the target.
	GetInMeleeRange()
	#savage_defense,if=buff.savage_defense.down
	if BuffExpires(savage_defense_buff) Spell(savage_defense)
	#frenzied_regeneration,if=health.pct<40
	if HealthPercent() < 40 Spell(frenzied_regeneration)
	#maul
	Spell(maul)
	#force_of_nature,if=charges=3|trinket.proc.all.react|target.time_to_die<20
	if Charges(force_of_nature_tank) == 3 or BuffPresent(trinket_proc_agility_buff) or target.TimeToDie() < 20 Spell(force_of_nature_tank)
}

AddFunction GuardianDefaultCdActions
{
	# CHANGE: Interrupt as the highest priority cooldown action.
	#skull_bash
	InterruptActions()
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_energy)
	#potion,name=tolvir,if=buff.berserking.up|buff.berserk.up
	if BuffPresent(berserking_buff) or BuffPresent(berserk_bear_buff) UsePotionAgility()
	#barkskin
	Spell(barkskin)
	#survival_instincts,if=health.pct<50
	if HealthPercent() < 50 Spell(survival_instincts)
	#berserk,if=dot.thrash_bear.remains>10&dot.lacerate.stack=3&dot.lacerate.remains>10&buff.son_of_ursoc.down
	if target.DebuffRemaining(thrash_bear_debuff) > 10 and target.DebuffStacks(lacerate_debuff) == 3 and target.DebuffRemaining(lacerate_debuff) > 10 and BuffExpires(son_of_ursoc_buff) Spell(berserk_bear)
	#renewal,if=health.pct<30
	if HealthPercent() < 30 Spell(renewal)
	#natures_vigil
	Spell(natures_vigil)
	#heart_of_the_wild
	Spell(heart_of_the_wild_tank)
}

# ActionList: GuardianPrecombatActions --> main, shortcd, cd

AddFunction GuardianPrecombatActions
{
	#flask,type=winds
	#food,type=seafood_magnifique_feast
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#bear_form
	Spell(bear_form)
	#snapshot_stats
	# CHANGE: Only cast Rejuvenation if the existing buff is already half gone.
	#rejuvenation
	#if SpellKnown(enhanced_rejuvenation) Spell(rejuvenation)
	if SpellKnown(enhanced_rejuvenation) and BuffRemaining(rejuvenation_buff) < 6 Spell(rejuvenation)
	#cenarion_ward
	Spell(cenarion_ward)
}

AddFunction GuardianPrecombatShortCdActions {}

AddFunction GuardianPrecombatCdActions {}

### Guardian icons.
AddCheckBox(opt_druid_guardian_aoe L(AOE) specialization=guardian default)

AddIcon specialization=guardian help=shortcd enemies=1 checkbox=!opt_druid_guardian_aoe
{
	if InCombat(no) GuardianPrecombatShortCdActions()
	GuardianDefaultShortCdActions()
}

AddIcon specialization=guardian help=shortcd checkbox=opt_druid_guardian_aoe
{
	if InCombat(no) GuardianPrecombatShortCdActions()
	GuardianDefaultShortCdActions()
}

AddIcon specialization=guardian help=main enemies=1
{
	if InCombat(no) GuardianPrecombatActions()
	GuardianDefaultActions()
}

AddIcon specialization=guardian help=aoe checkbox=opt_druid_guardian_aoe
{
	if InCombat(no) GuardianPrecombatActions()
	GuardianDefaultActions()
}

AddIcon specialization=guardian help=cd enemies=1 checkbox=!opt_druid_guardian_aoe
{
	if InCombat(no) GuardianPrecombatCdActions()
	GuardianDefaultCdActions()
}

AddIcon specialization=guardian help=cd checkbox=opt_druid_guardian_aoe
{
	if InCombat(no) GuardianPrecombatCdActions()
	GuardianDefaultCdActions()
}
]]

	OvaleScripts:RegisterScript("DRUID", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("DRUID", "Ovale", desc, code, "script")
end
