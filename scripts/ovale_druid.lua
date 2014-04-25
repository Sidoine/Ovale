local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.4] Ovale: Balance, Feral"
	local code = [[
# Ovale druid script based on SimulationCraft.
#	Last updated: 2014-04-24

Include(ovale_items)
Include(ovale_racials)
Include(ovale_druid_spells)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

###
### Balance
###
# Based on SimulationCraft profile "Druid_Balance_T16H".
#	class=druid
#	spec=balance
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Ua!.0.1.0

AddFunction BalanceDefaultActions
{
	#healing_touch,if=talent.dream_of_cenarius.enabled&!buff.dream_of_cenarius.up&mana.pct>25
	if TalentPoints(dream_of_cenarius_talent) and not BuffPresent(dream_of_cenarius_caster_buff) and ManaPercent() > 25 Spell(healing_touch)
	#starsurge,if=buff.shooting_stars.react&(active_enemies<5|!buff.solar_eclipse.up)
	if BuffPresent(shooting_stars_buff) and not BuffPresent(solar_eclipse_buff) Spell(starsurge)
	#moonfire,cycle_targets=1,if=buff.lunar_eclipse.up&(remains<(buff.natures_grace.remains-2+2*set_bonus.tier14_4pc_caster))
	if BuffPresent(lunar_eclipse_buff) and { target.DebuffRemains(moonfire_debuff) < { BuffRemains(natures_grace_buff) -2 + 2 * ArmorSetBonus(T14_caster 4) } } Spell(moonfire)
	#sunfire,cycle_targets=1,if=buff.solar_eclipse.up&(remains<(buff.natures_grace.remains-2+2*set_bonus.tier14_4pc_caster))
	if BuffPresent(solar_eclipse_buff) and { target.DebuffRemains(sunfire_debuff) < { BuffRemains(natures_grace_buff) -2 + 2 * ArmorSetBonus(T14_caster 4) } } Spell(sunfire)
	#moonfire,cycle_targets=1,if=active_enemies<5&(remains<(buff.natures_grace.remains-2+2*set_bonus.tier14_4pc_caster))
	if target.DebuffRemains(moonfire_debuff) < { BuffRemains(natures_grace_buff) -2 + 2 * ArmorSetBonus(T14_caster 4) } Spell(moonfire)
	#sunfire,cycle_targets=1,if=active_enemies<5&(remains<(buff.natures_grace.remains-2+2*set_bonus.tier14_4pc_caster))
	if target.DebuffRemains(sunfire_debuff) < { BuffRemains(natures_grace_buff) -2 + 2 * ArmorSetBonus(T14_caster 4) } Spell(sunfire)
	#moonfire,cycle_targets=1,if=buff.lunar_eclipse.up&ticks_remain<2
	if BuffPresent(lunar_eclipse_buff) and target.TicksRemain(moonfire_debuff) < 2 Spell(moonfire)
	#sunfire,cycle_targets=1,if=buff.solar_eclipse.up&ticks_remain<2
	if BuffPresent(solar_eclipse_buff) and target.TicksRemain(sunfire_debuff) < 2 Spell(sunfire)
	#starsurge,if=cooldown_react
	if Spell(starsurge) Spell(starsurge)
	#starfire,if=buff.celestial_alignment.up&cast_time<buff.celestial_alignment.remains
	if BuffPresent(celestial_alignment_buff) and CastTime(starfire) < BuffRemains(celestial_alignment_buff) Spell(starfire)
	#wrath,if=buff.celestial_alignment.up&cast_time<buff.celestial_alignment.remains
	if BuffPresent(celestial_alignment_buff) and CastTime(wrath) < BuffRemains(celestial_alignment_buff) Spell(wrath)
	#starfire,if=eclipse_dir=1|(eclipse_dir=0&eclipse>0)
	if EclipseDir() == 1 or { EclipseDir() == 0 and Eclipse() > 0 } Spell(starfire)
	#wrath,if=eclipse_dir=-1|(eclipse_dir=0&eclipse<=0)
	if EclipseDir() < 0 or { EclipseDir() == 0 and Eclipse() <= 0 } Spell(wrath)
}

AddFunction BalanceDefaultMovingActions
{
	#starsurge,if=buff.shooting_stars.react&(active_enemies<5|!buff.solar_eclipse.up)
	if BuffPresent(shooting_stars_buff) and not BuffPresent(solar_eclipse_buff) Spell(starsurge)
	#moonfire,cycle_targets=1,if=buff.lunar_eclipse.up&(remains<(buff.natures_grace.remains-2+2*set_bonus.tier14_4pc_caster))
	if BuffPresent(lunar_eclipse_buff) and { target.DebuffRemains(moonfire_debuff) < { BuffRemains(natures_grace_buff) -2 + 2 * ArmorSetBonus(T14_caster 4) } } Spell(moonfire)
	#sunfire,cycle_targets=1,if=buff.solar_eclipse.up&(remains<(buff.natures_grace.remains-2+2*set_bonus.tier14_4pc_caster))
	if BuffPresent(solar_eclipse_buff) and { target.DebuffRemains(sunfire_debuff) < { BuffRemains(natures_grace_buff) -2 + 2 * ArmorSetBonus(T14_caster 4) } } Spell(sunfire)
	#moonfire,cycle_targets=1,if=active_enemies<5&(remains<(buff.natures_grace.remains-2+2*set_bonus.tier14_4pc_caster))
	if target.DebuffRemains(moonfire_debuff) < { BuffRemains(natures_grace_buff) -2 + 2 * ArmorSetBonus(T14_caster 4) } Spell(moonfire)
	#sunfire,cycle_targets=1,if=active_enemies<5&(remains<(buff.natures_grace.remains-2+2*set_bonus.tier14_4pc_caster))
	if target.DebuffRemains(sunfire_debuff) < { BuffRemains(natures_grace_buff) -2 + 2 * ArmorSetBonus(T14_caster 4) } Spell(sunfire)
	#moonfire,cycle_targets=1,if=buff.lunar_eclipse.up&ticks_remain<2
	if BuffPresent(lunar_eclipse_buff) and target.TicksRemain(moonfire_debuff) < 2 Spell(moonfire)
	#sunfire,cycle_targets=1,if=buff.solar_eclipse.up&ticks_remain<2
	if BuffPresent(solar_eclipse_buff) and target.TicksRemain(sunfire_debuff) < 2 Spell(sunfire)
	#moonfire,moving=1,cycle_targets=1,if=ticks_remain<2
	if target.TicksRemain(moonfire_debuff) < 2 Spell(moonfire)
	#sunfire,moving=1,cycle_targets=1,if=ticks_remain<2
	if target.TicksRemain(sunfire_debuff) < 2 Spell(sunfire)
	#wild_mushroom,moving=1,if=buff.wild_mushroom.stack<buff.wild_mushroom.max_stack
	if WildMushroomCount() < 3 Spell(wild_mushroom_caster)
	#starsurge,moving=1,if=buff.shooting_stars.react
	if BuffPresent(shooting_stars_buff) Spell(starsurge)
	#moonfire,moving=1,if=buff.lunar_eclipse.up
	if BuffPresent(lunar_eclipse_buff) Spell(moonfire)
	#sunfire,moving=1
	Spell(sunfire)
}

AddFunction BalanceHurricaneActions
{
	unless { TalentPoints(dream_of_cenarius_talent) and not BuffPresent(dream_of_cenarius_caster_buff) and ManaPercent() > 25 and Spell(healing_touch) }
	{
		#hurricane,if=active_enemies>4&buff.solar_eclipse.up&buff.natures_grace.up
		if BuffPresent(solar_eclipse_buff) and BuffPresent(natures_grace_buff) Spell(hurricane)
		#hurricane,if=active_enemies>5&buff.solar_eclipse.up&mana.pct>25
		if BuffPresent(solar_eclipse_buff) and ManaPercent() > 25 Spell(hurricane)
	}
}

AddFunction BalanceDefaultShortCdActions
{
	#starfall,if=!buff.starfall.up
	if not BuffPresent(starfall_buff) Spell(starfall)
	#force_of_nature,if=talent.force_of_nature.enabled
	if TalentPoints(force_of_nature_talent) Spell(force_of_nature_caster)
}

AddFunction BalanceDefaultCdActions
{
	#jade_serpent_potion,if=buff.bloodlust.react|target.time_to_die<=40|buff.celestial_alignment.up
	if BuffPresent(burst_haste any=1) or target.TimeToDie() <= 40 or BuffPresent(celestial_alignment_buff) UsePotionIntellect()

	unless { not BuffPresent(starfall_buff) and Spell(starfall) }
	{
		#berserking,if=buff.celestial_alignment.up
		if BuffPresent(celestial_alignment_buff) Spell(berserking)
		#use_item,slot=hands,if=buff.celestial_alignment.up|cooldown.celestial_alignment.remains>30
		if BuffPresent(celestial_alignment_buff) or SpellCooldown(celestial_alignment) > 30 UseItemActions()
		#wild_mushroom_detonate,moving=0,if=buff.wild_mushroom.stack>0&buff.solar_eclipse.up
		if WildMushroomCount() > 0 and BuffPresent(solar_eclipse_buff) Spell(wild_mushroom_detonate)
		#natures_swiftness,if=talent.dream_of_cenarius.enabled
		if TalentPoints(dream_of_cenarius_talent) Spell(natures_swiftness)

		unless { TalentPoints(dream_of_cenarius_talent) and not BuffPresent(dream_of_cenarius_caster_buff) and ManaPercent() > 25 and Spell(healing_touch) }
		{
			#incarnation,if=talent.incarnation.enabled&(buff.lunar_eclipse.up|buff.solar_eclipse.up)
			if TalentPoints(incarnation_talent) and { BuffPresent(lunar_eclipse_buff) or BuffPresent(solar_eclipse_buff) } Spell(incarnation)
			#celestial_alignment,if=(!buff.lunar_eclipse.up&!buff.solar_eclipse.up)&(buff.chosen_of_elune.up|!talent.incarnation.enabled|cooldown.incarnation.remains>10)
			if { not BuffPresent(lunar_eclipse_buff) and not BuffPresent(solar_eclipse_buff) } and { BuffPresent(chosen_of_elune_buff) or not TalentPoints(incarnation_talent) or SpellCooldown(incarnation) > 10 } Spell(celestial_alignment)
			#natures_vigil,if=talent.natures_vigil.enabled
			if TalentPoints(natures_vigil_talent) Spell(natures_vigil)
		}
	}
}

AddFunction BalancePrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int any=1) Spell(mark_of_the_wild)
	#wild_mushroom,if=buff.wild_mushroom.stack<buff.wild_mushroom.max_stack
	if WildMushroomCount() < 3 Spell(wild_mushroom_caster)
	#healing_touch,if=!buff.dream_of_cenarius.up&talent.dream_of_cenarius.enabled
	if not BuffPresent(dream_of_cenarius_caster_buff) and TalentPoints(dream_of_cenarius_talent) Spell(healing_touch)
	#moonkin_form
	if not Stance(druid_moonkin_form) Spell(moonkin_form)
	# Snapshot raid buffed stats before combat begins and pre-potting is done.
	#snapshot_stats
}

AddFunction BalancePrecombatCdActions
{
	#jade_serpent_potion
	UsePotionIntellect()
}

### Balance Icons

AddIcon mastery=balance help=cd size=small checkboxon=opt_icons_left
{
	Spell(barkskin)
	Spell(survival_instincts)
	Spell(might_of_ursoc)
	if TalentPoints(renewal_talent) Spell(renewal)
	if TalentPoints(cenarion_ward_talent) Spell(cenarion_ward)
	Spell(tranquility)
}

AddIcon mastery=balance size=small checkboxon=opt_icons_left
{
	#wild_mushroom_detonate,moving=0,if=buff.wild_mushroom.stack>0&buff.solar_eclipse.up
	if WildMushroomCount() > 0 and BuffPresent(solar_eclipse_buff) Spell(wild_mushroom_detonate)
}

AddIcon mastery=balance help=shortcd
{
	if not Stance(druid_moonkin_form) Spell(moonkin_form)

	BalanceDefaultShortCdActions()
	BalanceHurricaneActions()
}

AddIcon mastery=balance help=main
{
	if InCombat(no) BalancePrecombatActions()
	BalanceDefaultActions()
}

AddIcon mastery=balance help=moving
{
	if InCombat(no) BalancePrecombatActions()
	BalanceDefaultMovingActions()
}

AddIcon mastery=balance help=cd
{
	BalanceInterrupt()
	BalanceDefaultCdActions()
}

AddIcon mastery=balance help=cd size=small checkboxon=opt_icons_right
{
	if TalentPoints(heart_of_the_wild_talent) Spell(heart_of_the_wild)
	if TalentPoints(natures_vigil_talent) Spell(natures_vigil)
}

AddIcon mastery=balance help=cd size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

###
### Feral
###
# Based on SimulationCraft profile "Druid_Feral_T16H_Adv_Rotation".
#	class=druid
#	spec=feral
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#UZ!...2.1
#	glyphs=savagery/cat_form

AddFunction FeralFillerActions
{
	#ravage
	Spell(ravage usable=1)
	#rake,if=target.time_to_die-dot.rake.remains>3&action.rake.tick_damage*(dot.rake.ticks_remain+1)-dot.rake.tick_dmg*dot.rake.ticks_remain>action.mangle_cat.hit_damage
	if target.TimeToDie() - target.DebuffRemains(rake_debuff) > 3 and target.Damage(rake_debuff) * { target.TicksRemain(rake_debuff) + 1 } - target.LastEstimatedDamage(rake_debuff) * target.TicksRemain(rake_debuff) > target.Damage(mangle_cat) Spell(rake)
	#shred,if=(buff.omen_of_clarity.react|buff.berserk.up|energy.regen>=15)&buff.king_of_the_jungle.down
	if { BuffPresent(omen_of_clarity_buff) or BuffPresent(berserk_cat_buff) or EnergyRegen() >= 15 } and BuffExpires(king_of_the_jungle_buff) Spell(shred)
	#mangle_cat,if=buff.king_of_the_jungle.down
	if BuffExpires(king_of_the_jungle_buff) Spell(mangle_cat)
}

AddFunction FeralBasicActions
{
	#auto_attack
	#force_of_nature,if=charges=3|trinket.proc.agility.react|(buff.rune_of_reorigination.react&buff.rune_of_reorigination.remains<1)|target.time_to_die<20
	if Charges(force_of_nature_melee) == 3 or BuffPresent(trinket_proc_agility_buff) or { BuffPresent(rune_of_reorigination_buff) and BuffRemains(rune_of_reorigination_buff) < 1 } or target.TimeToDie() < 20 Spell(force_of_nature_melee)
	#ferocious_bite,if=dot.rip.ticking&dot.rip.remains<=3&target.health.pct<=25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemains(rip_debuff) <= 3 and target.HealthPercent() <= 25 Spell(ferocious_bite)
	#faerie_fire,if=debuff.weakened_armor.stack<3
	if target.DebuffStacks(weakened_armor_debuff any=1) < 3 Spell(faerie_fire)
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if TalentPoints(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemains(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.remains<3
	if BuffRemains(savage_roar_buff) < 3 SavageRoar()
	#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
	if Energy() <= 35 and not BuffPresent(omen_of_clarity_buff) Spell(tigers_fury)
	#rip,if=combo_points>=5&target.health.pct<=25&action.rip.tick_damage%dot.rip.tick_dmg>=1.15
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 1.15 Spell(rip)
	#ferocious_bite,if=combo_points>=5&target.health.pct<=25&dot.rip.ticking
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
	#rip,if=combo_points>=5&dot.rip.remains<2
	if ComboPoints() >= 5 and target.DebuffRemains(rip_debuff) < 2 Spell(rip)
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3
	if BuffPresent(omen_of_clarity_buff) and target.DebuffRemains(thrash_cat_debuff) < 3 Spell(thrash_cat)
	#rake,cycle_targets=1,if=dot.rake.remains<3|action.rake.tick_damage>dot.rake.tick_dmg
	if target.DebuffRemains(rake_debuff) < 3 or target.Damage(rake_debuff) > target.LastEstimatedDamage(rake_debuff) Spell(rake)
	#pool_resource,for_next=1
	#thrash_cat,if=dot.thrash_cat.remains<3&(dot.rip.remains>=8&buff.savage_roar.remains>=12|buff.berserk.up|combo_points>=5)
	if Energy() >= EnergyCost(thrash_cat) and target.DebuffRemains(thrash_cat_debuff) < 3 and { target.DebuffRemains(rip_debuff) >= 8 and BuffRemains(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } wait Spell(thrash_cat)
	#pool_resource,if=combo_points>=5&!(energy.time_to_max<=1|(buff.berserk.up&energy>=25)|(buff.feral_rage.up&buff.feral_rage.remains<=1))&dot.rip.ticking
	unless ComboPoints() >= 5 and not { TimeToMaxEnergy() <= 1 or { BuffPresent(berserk_cat_buff) and Energy() >= 25 } or { BuffPresent(feral_rage_buff) and BuffRemains(feral_rage_buff) <= 1 } } and target.DebuffPresent(rip_debuff)
	{
		#ferocious_bite,if=combo_points>=5&dot.rip.ticking
		if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
		#run_action_list,name=filler,if=buff.omen_of_clarity.react
		if BuffPresent(omen_of_clarity_buff) FeralFillerActions()
		#run_action_list,name=filler,if=buff.feral_fury.react
		if BuffPresent(feral_fury_buff) FeralFillerActions()
		#run_action_list,name=filler,if=(combo_points<5&dot.rip.remains<3.0)|(combo_points=0&buff.savage_roar.remains<2)
		if { ComboPoints() < 5 and target.DebuffRemains(rip_debuff) < 3 } or { ComboPoints() == 0 and BuffRemains(savage_roar_buff) < 2 } FeralFillerActions()
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

AddFunction FeralBasicPredictiveActions
{
	#auto_attack
	#force_of_nature,if=charges=3|trinket.proc.agility.react|(buff.rune_of_reorigination.react&buff.rune_of_reorigination.remains<1)|target.time_to_die<20
	if Charges(force_of_nature_melee) == 3 or BuffPresent(trinket_proc_agility_buff) or { BuffPresent(rune_of_reorigination_buff) and BuffRemains(rune_of_reorigination_buff) < 1 } or target.TimeToDie() < 20 Spell(force_of_nature_melee)
	#ferocious_bite,if=dot.rip.ticking&dot.rip.remains<=3&target.health.pct<=25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemains(rip_debuff) <= 3 and target.HealthPercent() <= 25 Spell(ferocious_bite)
	#faerie_fire,if=debuff.weakened_armor.stack<3
	if target.DebuffStacks(weakened_armor_debuff any=1) < 3 Spell(faerie_fire)
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if TalentPoints(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemains(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.remains<3
	if BuffRemains(savage_roar_buff) < 3 SavageRoar()
	#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
	if Energy() <= 35 and not BuffPresent(omen_of_clarity_buff) Spell(tigers_fury)
	#rip,if=combo_points>=5&target.health.pct<=25&action.rip.tick_damage%dot.rip.tick_dmg>=1.15
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 1.15 Spell(rip)
	#ferocious_bite,if=combo_points>=5&target.health.pct<=25&dot.rip.ticking
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
	#rip,if=combo_points>=5&dot.rip.remains<2
	if ComboPoints() >= 5 and target.DebuffRemains(rip_debuff) < 2 Spell(rip)
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3
	if BuffPresent(omen_of_clarity_buff) and target.DebuffRemains(thrash_cat_debuff) < 3 Spell(thrash_cat)
	#rake,cycle_targets=1,if=dot.rake.remains<3|action.rake.tick_damage>dot.rake.tick_dmg
	if target.DebuffRemains(rake_debuff) < 3 or target.Damage(rake_debuff) > target.LastEstimatedDamage(rake_debuff) Spell(rake)
	#pool_resource,for_next=1
	#thrash_cat,if=dot.thrash_cat.remains<3&(dot.rip.remains>=8&buff.savage_roar.remains>=12|buff.berserk.up|combo_points>=5)
	if Energy() >= EnergyCost(thrash_cat) and target.DebuffRemains(thrash_cat_debuff) < 3 and { target.DebuffRemains(rip_debuff) >= 8 and BuffRemains(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } wait Spell(thrash_cat)
	#pool_resource,if=combo_points>=5&!(energy.time_to_max<=1|(buff.berserk.up&energy>=25)|(buff.feral_rage.up&buff.feral_rage.remains<=1))&dot.rip.ticking
	unless ComboPoints() >= 5 and not { TimeToMaxEnergy() <= 1 or { BuffPresent(berserk_cat_buff) and Energy() >= 25 } or { BuffPresent(feral_rage_buff) and BuffRemains(feral_rage_buff) <= 1 } } and target.DebuffPresent(rip_debuff)
	{
		#ferocious_bite,if=combo_points>=5&dot.rip.ticking
		if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
	}
}

AddFunction FeralBasicCdActions
{
	#skull_bash_cat
	FeralInterrupt()

	unless { target.DebuffPresent(rip_debuff) and target.DebuffRemains(rip_debuff) <= 3 and target.HealthPercent() <= 25 and Spell(ferocious_bite) }
		or { target.DebuffStacks(weakened_armor_debuff any=1) < 3 and Spell(faerie_fire) }
		or { TalentPoints(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemains(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } and Spell(healing_touch) }
		or { BuffRemains(savage_roar_buff) < 3 and SavageRoar() }
	{
		#virmens_bite_potion,if=(target.health.pct<30&buff.berserk.up)|target.time_to_die<=40
		if { target.HealthPercent() < 30 and BuffPresent(berserk_cat_buff) } or target.TimeToDie() <= 40 UsePotionAgility()

		# Synchronize display with Tiger's Fury buff in main actions.
		if { Energy() <= 35 and not BuffPresent(omen_of_clarity_buff) } or BuffPresent(tigers_fury_buff)
		{
			#berserk,if=buff.tigers_fury.up
			Spell(berserk_cat)
			#use_item,slot=hands,if=buff.tigers_fury.up
			UseItemActions()
			#berserking,if=buff.tigers_fury.up
			UseRacialActions()
		}
	}
}

AddFunction FeralAoeActions
{
	#auto_attack
	#faerie_fire,cycle_targets=1,if=debuff.weakened_armor.stack<3
	if target.DebuffStacks(weakened_armor_debuff any=1) < 3 Spell(faerie_fire)
	#savage_roar,if=buff.savage_roar.down|(buff.savage_roar.remains<3&combo_points>0)
	if BuffExpires(savage_roar_buff) or { BuffRemains(savage_roar_buff) < 3 and ComboPoints() > 0 } SavageRoar()
	#use_item,slot=hands,if=buff.tigers_fury.up
	#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
	if Energy() <= 35 and not BuffPresent(omen_of_clarity_buff) Spell(tigers_fury)
	#berserk,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) Spell(berserk_cat)
	#pool_resource,for_next=1
	#thrash_cat,if=buff.rune_of_reorigination.up
	if Energy() >= EnergyCost(thrash_cat) and BuffPresent(rune_of_reorigination_buff) wait Spell(thrash_cat)
	#pool_resource,wait=0.1,for_next=1
	#thrash_cat,if=dot.thrash_cat.remains<3|(buff.tigers_fury.up&dot.thrash_cat.remains<9)
	if Energy() >= EnergyCost(thrash_cat) and target.DebuffRemains(thrash_cat_debuff) < 3 or { BuffPresent(tigers_fury_buff) and target.DebuffRemains(thrash_cat_debuff) < 9 } wait Spell(thrash_cat)
	#savage_roar,if=buff.savage_roar.remains<9&combo_points>=5
	if BuffRemains(savage_roar_buff) < 9 and ComboPoints() >= 5 SavageRoar()
	#rip,if=combo_points>=5
	if ComboPoints() >= 5 Spell(rip)
	#rake,cycle_targets=1,if=(active_enemies<8|buff.rune_of_reorigination.up)&dot.rake.remains<3&target.time_to_die>=15
	if { Enemies() < 8 or BuffPresent(rune_of_reorigination_buff) } and target.DebuffRemains(rake_debuff) < 3 and target.TimeToDie() >= 15 Spell(rake)
	#swipe_cat,if=buff.savage_roar.remains<=5
	if BuffRemains(savage_roar_buff) <= 5 Spell(swipe_cat)
	#swipe_cat,if=buff.tigers_fury.up|buff.berserk.up
	if BuffPresent(tigers_fury_buff) or BuffPresent(berserk_cat_buff) Spell(swipe_cat)
	#swipe_cat,if=cooldown.tigers_fury.remains<3
	if SpellCooldown(tigers_fury) < 3 Spell(swipe_cat)
	#swipe_cat,if=buff.omen_of_clarity.react
	if BuffPresent(omen_of_clarity_buff) Spell(swipe_cat)
	#swipe_cat,if=energy.time_to_max<=1
	if TimeToMaxEnergy() <= 1 Spell(swipe_cat)
}

AddFunction FeralPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int any=1) Spell(mark_of_the_wild)
	#healing_touch,if=!buff.dream_of_cenarius.up&talent.dream_of_cenarius.enabled
	if not BuffPresent(dream_of_cenarius_melee_buff) and TalentPoints(dream_of_cenarius_talent) Spell(healing_touch)
	#cat_form
	if not Stance(druid_cat_form) Spell(cat_form)
	#savage_roar
	SavageRoar()
	#stealth
	if Stealthed(no) Spell(prowl)
	#snapshot_stats
}

AddFunction FeralPrecombatCdActions
{
	#virmens_bite_potion
	UsePotionAgility()
}

AddFunction FeralAdvancedActions
{
	#auto_attack
	#force_of_nature,if=charges=3|(buff.rune_of_reorigination.react&buff.rune_of_reorigination.remains<1)|(buff.vicious.react&buff.vicious.remains<1)|target.time_to_die<20
	if Charges(force_of_nature_melee) == 3 or { BuffPresent(rune_of_reorigination_buff) and BuffRemains(rune_of_reorigination_buff) < 1 } or { BuffPresent(trinket_proc_agility_buff) and BuffRemains(trinket_proc_agility_buff) < 1 } or target.TimeToDie() < 20 Spell(force_of_nature_melee)
	#ravage,if=buff.stealthed.up
	if Stealthed() Spell(ravage)
	#ferocious_bite,if=dot.rip.ticking&dot.rip.remains<=3&target.health.pct<=25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemains(rip_debuff) <= 3 and target.HealthPercent() <= 25 Spell(ferocious_bite)
	#faerie_fire,if=debuff.weakened_armor.stack<3
	if target.DebuffStacks(weakened_armor_debuff any=1) < 3 Spell(faerie_fire)
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if TalentPoints(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemains(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.down
	if BuffExpires(savage_roar_buff) SavageRoar()
	#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
	if Energy() <= 35 and not BuffPresent(omen_of_clarity_buff) Spell(tigers_fury)
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3&target.time_to_die>=6
	if BuffPresent(omen_of_clarity_buff) and target.DebuffRemains(thrash_cat_debuff) < 3 and target.TimeToDie() >= 6 Spell(thrash_cat)
	#ferocious_bite,if=target.time_to_die<=1&combo_points>=3
	if target.TimeToDie() <= 1 and ComboPoints() >= 3 Spell(ferocious_bite)
	#savage_roar,if=buff.savage_roar.remains<=3&combo_points>0&target.health.pct<25
	if BuffRemains(savage_roar_buff) <= 3 and ComboPoints() > 0 and target.HealthPercent() < 25 SavageRoar()
	#rip,if=combo_points>=5&action.rip.tick_damage%dot.rip.tick_dmg>=1.15&target.time_to_die>30
	if ComboPoints() >= 5 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 1.15 and target.TimeToDie() > 30 Spell(rip)
	#rip,if=combo_points>=4&action.rip.tick_damage%dot.rip.tick_dmg>=0.95&target.time_to_die>30&buff.rune_of_reorigination.up&buff.rune_of_reorigination.remains<=1.5
	if ComboPoints() >= 4 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 0.95 and target.TimeToDie() > 30 and BuffPresent(rune_of_reorigination_buff) and BuffRemains(rune_of_reorigination_buff) <= 1.5 Spell(rip)
	#pool_resource,if=combo_points>=5&target.health.pct<=25&dot.rip.ticking&!(energy>=50|(buff.berserk.up&energy>=25))
	unless ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.DebuffPresent(rip_debuff) and not { Energy() >= 50 or { BuffPresent(berserk_cat_buff) and Energy() >= 25 } }
	{
		#ferocious_bite,if=combo_points>=5&dot.rip.ticking&target.health.pct<=25
		if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) and target.HealthPercent() <= 25 Spell(ferocious_bite)
		#rip,if=combo_points>=5&target.time_to_die>=6&dot.rip.remains<2&(buff.berserk.up|dot.rip.remains+1.9<=cooldown.tigers_fury.remains)
		if ComboPoints() >= 5 and target.TimeToDie() >= 6 and target.DebuffRemains(rip_debuff) < 2 and { BuffPresent(berserk_cat_buff) or target.DebuffRemains(rip_debuff) + 1.9 <= SpellCooldown(tigers_fury) } Spell(rip)
		#savage_roar,if=buff.savage_roar.remains<=3&combo_points>0&buff.savage_roar.remains+2>dot.rip.remains
		if BuffRemains(savage_roar_buff) <= 3 and ComboPoints() > 0 and BuffRemains(savage_roar_buff) + 2 > target.DebuffRemains(rip_debuff) SavageRoar()
		#savage_roar,if=buff.savage_roar.remains<=6&combo_points>=5&buff.savage_roar.remains+2<=dot.rip.remains&dot.rip.ticking
		if BuffRemains(savage_roar_buff) <= 6 and ComboPoints() >= 5 and BuffRemains(savage_roar_buff) + 2 <= target.DebuffRemains(rip_debuff) and target.DebuffPresent(rip_debuff) SavageRoar()
		#savage_roar,if=buff.savage_roar.remains<=12&combo_points>=5&energy.time_to_max<=1&buff.savage_roar.remains<=dot.rip.remains+6&dot.rip.ticking
		if BuffRemains(savage_roar_buff) <= 12 and ComboPoints() >= 5 and TimeToMaxEnergy() <= 1 and BuffRemains(savage_roar_buff) <= target.DebuffRemains(rip_debuff) + 6 and target.DebuffPresent(rip_debuff) SavageRoar()
		#rake,if=buff.rune_of_reorigination.up&dot.rake.remains<9&buff.rune_of_reorigination.remains<=1.5
		if BuffPresent(rune_of_reorigination_buff) and target.DebuffRemains(rake_debuff) < 9 and BuffRemains(rune_of_reorigination_buff) <= 1.5 Spell(rake)
		#rake,cycle_targets=1,if=target.time_to_die-dot.rake.remains>3&(action.rake.tick_damage>dot.rake.tick_dmg|(dot.rake.remains<3&action.rake.tick_damage%dot.rake.tick_dmg>=0.75))
		if target.TimeToDie() - target.DebuffRemains(rake_debuff) > 3 and { target.Damage(rake_debuff) > target.LastEstimatedDamage(rake_debuff) or { target.DebuffRemains(rake_debuff) < 3 and target.Damage(rake_debuff) / target.LastEstimatedDamage(rake_debuff) >= 0.75 } } Spell(rake)
		#pool_resource,for_next=1
		#thrash_cat,if=target.time_to_die>=6&dot.thrash_cat.remains<3&(dot.rip.remains>=8&buff.savage_roar.remains>=12|buff.berserk.up|combo_points>=5)&dot.rip.ticking
		if Energy() >= EnergyCost(thrash_cat) and target.TimeToDie() >= 6 and target.DebuffRemains(thrash_cat_debuff) < 3 and { target.DebuffRemains(rip_debuff) >= 8 and BuffRemains(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } and target.DebuffPresent(rip_debuff) wait Spell(thrash_cat)
		#pool_resource,for_next=1
		#thrash_cat,if=target.time_to_die>=6&dot.thrash_cat.remains<9&buff.rune_of_reorigination.up&buff.rune_of_reorigination.remains<=1.5&dot.rip.ticking
		if target.TimeToDie() >= 6 and target.DebuffRemains(thrash_cat_debuff) < 9 and BuffPresent(rune_of_reorigination_buff) and BuffRemains(rune_of_reorigination_buff) <= 1.5 and target.DebuffPresent(rip_debuff) wait Spell(thrash_cat)
		#pool_resource,if=combo_points>=5&!(energy.time_to_max<=1|(buff.berserk.up&energy>=25)|(buff.feral_rage.up&buff.feral_rage.remains<=1))&dot.rip.ticking
		unless ComboPoints() >= 5 and not { TimeToMaxEnergy() <= 1 or { BuffPresent(berserk_cat_buff) and Energy() >= 25 } or { BuffPresent(feral_rage_buff) and BuffRemains(feral_rage_buff) <= 1 } } and target.DebuffPresent(rip_debuff)
		{
			#ferocious_bite,if=combo_points>=5&dot.rip.ticking
			if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
			#run_action_list,name=filler,if=buff.omen_of_clarity.react
			if BuffPresent(omen_of_clarity_buff) FeralFillerActions()
			#run_action_list,name=filler,if=buff.feral_fury.react
			if BuffPresent(feral_fury_buff) FeralFillerActions()
			#run_action_list,name=filler,if=(combo_points<5&dot.rip.remains<3.0)|(combo_points=0&buff.savage_roar.remains<2)
			if { ComboPoints() < 5 and target.DebuffRemains(rip_debuff) < 3 } or { ComboPoints() == 0 and BuffRemains(savage_roar_buff) < 2 } FeralFillerActions()
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

AddFunction FeralAdvancedPredictiveActions
{
	#auto_attack
	#force_of_nature,if=charges=3|(buff.rune_of_reorigination.react&buff.rune_of_reorigination.remains<1)|(buff.vicious.react&buff.vicious.remains<1)|target.time_to_die<20
	if Charges(force_of_nature_melee) == 3 or { BuffPresent(rune_of_reorigination_buff) and BuffRemains(rune_of_reorigination_buff) < 1 } or { BuffPresent(trinket_proc_agility_buff) and BuffRemains(trinket_proc_agility_buff) < 1 } or target.TimeToDie() < 20 Spell(force_of_nature_melee)
	#ravage,if=buff.stealthed.up
	if Stealthed() Spell(ravage)
	#ferocious_bite,if=dot.rip.ticking&dot.rip.remains<=3&target.health.pct<=25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemains(rip_debuff) <= 3 and target.HealthPercent() <= 25 Spell(ferocious_bite)
	#faerie_fire,if=debuff.weakened_armor.stack<3
	if target.DebuffStacks(weakened_armor_debuff any=1) < 3 Spell(faerie_fire)
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if TalentPoints(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemains(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.down
	if BuffExpires(savage_roar_buff) SavageRoar()
	#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
	if Energy() <= 35 and not BuffPresent(omen_of_clarity_buff) Spell(tigers_fury)
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3&target.time_to_die>=6
	if BuffPresent(omen_of_clarity_buff) and target.DebuffRemains(thrash_cat_debuff) < 3 and target.TimeToDie() >= 6 Spell(thrash_cat)
	#ferocious_bite,if=target.time_to_die<=1&combo_points>=3
	if target.TimeToDie() <= 1 and ComboPoints() >= 3 Spell(ferocious_bite)
	#savage_roar,if=buff.savage_roar.remains<=3&combo_points>0&target.health.pct<25
	if BuffRemains(savage_roar_buff) <= 3 and ComboPoints() > 0 and target.HealthPercent() < 25 SavageRoar()
	#rip,if=combo_points>=5&action.rip.tick_damage%dot.rip.tick_dmg>=1.15&target.time_to_die>30
	if ComboPoints() >= 5 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 1.15 and target.TimeToDie() > 30 Spell(rip)
	#rip,if=combo_points>=4&action.rip.tick_damage%dot.rip.tick_dmg>=0.95&target.time_to_die>30&buff.rune_of_reorigination.up&buff.rune_of_reorigination.remains<=1.5
	if ComboPoints() >= 4 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 0.95 and target.TimeToDie() > 30 and BuffPresent(rune_of_reorigination_buff) and BuffRemains(rune_of_reorigination_buff) <= 1.5 Spell(rip)
	#pool_resource,if=combo_points>=5&target.health.pct<=25&dot.rip.ticking&!(energy>=50|(buff.berserk.up&energy>=25))
	unless ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.DebuffPresent(rip_debuff) and not { Energy() >= 50 or { BuffPresent(berserk_cat_buff) and Energy() >= 25 } }
	{
		#ferocious_bite,if=combo_points>=5&dot.rip.ticking&target.health.pct<=25
		if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) and target.HealthPercent() <= 25 Spell(ferocious_bite)
		#rip,if=combo_points>=5&target.time_to_die>=6&dot.rip.remains<2&(buff.berserk.up|dot.rip.remains+1.9<=cooldown.tigers_fury.remains)
		if ComboPoints() >= 5 and target.TimeToDie() >= 6 and target.DebuffRemains(rip_debuff) < 2 and { BuffPresent(berserk_cat_buff) or target.DebuffRemains(rip_debuff) + 1.9 <= SpellCooldown(tigers_fury) } Spell(rip)
		#savage_roar,if=buff.savage_roar.remains<=3&combo_points>0&buff.savage_roar.remains+2>dot.rip.remains
		if BuffRemains(savage_roar_buff) <= 3 and ComboPoints() > 0 and BuffRemains(savage_roar_buff) + 2 > target.DebuffRemains(rip_debuff) SavageRoar()
		#savage_roar,if=buff.savage_roar.remains<=6&combo_points>=5&buff.savage_roar.remains+2<=dot.rip.remains&dot.rip.ticking
		if BuffRemains(savage_roar_buff) <= 6 and ComboPoints() >= 5 and BuffRemains(savage_roar_buff) + 2 <= target.DebuffRemains(rip_debuff) and target.DebuffPresent(rip_debuff) SavageRoar()
		#savage_roar,if=buff.savage_roar.remains<=12&combo_points>=5&energy.time_to_max<=1&buff.savage_roar.remains<=dot.rip.remains+6&dot.rip.ticking
		if BuffRemains(savage_roar_buff) <= 12 and ComboPoints() >= 5 and TimeToMaxEnergy() <= 1 and BuffRemains(savage_roar_buff) <= target.DebuffRemains(rip_debuff) + 6 and target.DebuffPresent(rip_debuff) SavageRoar()
		#rake,if=buff.rune_of_reorigination.up&dot.rake.remains<9&buff.rune_of_reorigination.remains<=1.5
		if BuffPresent(rune_of_reorigination_buff) and target.DebuffRemains(rake_debuff) < 9 and BuffRemains(rune_of_reorigination_buff) <= 1.5 Spell(rake)
		#rake,cycle_targets=1,if=target.time_to_die-dot.rake.remains>3&(action.rake.tick_damage>dot.rake.tick_dmg|(dot.rake.remains<3&action.rake.tick_damage%dot.rake.tick_dmg>=0.75))
		if target.TimeToDie() - target.DebuffRemains(rake_debuff) > 3 and { target.Damage(rake_debuff) > target.LastEstimatedDamage(rake_debuff) or { target.DebuffRemains(rake_debuff) < 3 and target.Damage(rake_debuff) / target.LastEstimatedDamage(rake_debuff) >= 0.75 } } Spell(rake)
		#pool_resource,for_next=1
		#thrash_cat,if=target.time_to_die>=6&dot.thrash_cat.remains<3&(dot.rip.remains>=8&buff.savage_roar.remains>=12|buff.berserk.up|combo_points>=5)&dot.rip.ticking
		if Energy() >= EnergyCost(thrash_cat) and target.TimeToDie() >= 6 and target.DebuffRemains(thrash_cat_debuff) < 3 and { target.DebuffRemains(rip_debuff) >= 8 and BuffRemains(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } and target.DebuffPresent(rip_debuff) wait Spell(thrash_cat)
		#pool_resource,for_next=1
		#thrash_cat,if=target.time_to_die>=6&dot.thrash_cat.remains<9&buff.rune_of_reorigination.up&buff.rune_of_reorigination.remains<=1.5&dot.rip.ticking
		if target.TimeToDie() >= 6 and target.DebuffRemains(thrash_cat_debuff) < 9 and BuffPresent(rune_of_reorigination_buff) and BuffRemains(rune_of_reorigination_buff) <= 1.5 and target.DebuffPresent(rip_debuff) wait Spell(thrash_cat)
		#pool_resource,if=combo_points>=5&!(energy.time_to_max<=1|(buff.berserk.up&energy>=25)|(buff.feral_rage.up&buff.feral_rage.remains<=1))&dot.rip.ticking
		unless ComboPoints() >= 5 and not { TimeToMaxEnergy() <= 1 or { BuffPresent(berserk_cat_buff) and Energy() >= 25 } or { BuffPresent(feral_rage_buff) and BuffRemains(feral_rage_buff) <= 1 } } and target.DebuffPresent(rip_debuff)
		{
			#ferocious_bite,if=combo_points>=5&dot.rip.ticking
			if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
		}
	}
}

AddFunction FeralAdvancedCdActions
{
	#skull_bash_cat
	FeralInterrupt()
	#berserking
	Spell(berserking)
	unless { Stealthed() and Spell(ravage) }
		or { target.DebuffPresent(rip_debuff) and target.DebuffRemains(rip_debuff) <= 3 and target.HealthPercent() <= 25 and Spell(ferocious_bite) }
		or { target.DebuffStacks(weakened_armor_debuff any=1) < 3 and Spell(faerie_fire) }
		or { TalentPoints(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemains(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } and Spell(healing_touch) }
		or { BuffExpires(savage_roar_buff) and SavageRoar() }
	{
		# Synchronize display with Tiger's Fury buff in main actions.
		if target.TimeToDie() < 18 and SpellCooldown(tigers_fury) > 6 Spell(berserk_cat)
		if { Energy() <= 35 and not BuffPresent(omen_of_clarity_buff) } or BuffPresent(tigers_fury_buff)
		{
			#berserk,if=buff.tigers_fury.up|(target.time_to_die<18&cooldown.tigers_fury.remains>6)
			Spell(berserk_cat)
			#use_item,slot=hands,if=buff.tigers_fury.up
			UseItemActions()
		}

		unless { BuffPresent(omen_of_clarity_buff) and target.DebuffRemains(thrash_cat_debuff) < 3 and target.TimeToDie() >= 6 and Spell(thrash_cat) }
			or { target.TimeToDie() <= 1 and ComboPoints() >= 3 or Spell(ferocious_bite) }
			or { BuffRemains(savage_roar_buff) <= 3 and ComboPoints() > 0 and target.HealthPercent() < 25 and SavageRoar() }
		{
			#virmens_bite_potion,if=(combo_points>=5&(target.time_to_die*(target.health.pct-25)%target.health.pct)<15&buff.rune_of_reorigination.up)|target.time_to_die<=40
			if { ComboPoints() >= 5 and { target.TimeToDie() * { target.HealthPercent() -25 } / target.HealthPercent() } < 15 and BuffPresent(rune_of_reorigination_buff) } or target.TimeToDie() <= 40 UsePotionAgility()
		}
	}
}

AddListItem(opt_feral_rotation basic "Use basic rotation" default mastery=feral)
AddListItem(opt_feral_rotation advanced "Use advanced rotation" mastery=feral)

### Feral Icons

AddIcon mastery=feral help=cd size=small checkboxon=opt_icons_left
{
	Spell(barkskin)
	Spell(survival_instincts)
	Spell(might_of_ursoc)
	if TalentPoints(renewal_talent) Spell(renewal)
	if TalentPoints(cenarion_ward_talent) Spell(cenarion_ward)
	Spell(tranquility)
}

AddIcon mastery=feral size=small checkboxon=opt_icons_left
{
	if TalentPoints(displacer_beast_talent) Spell(displacer_beast)
	if TalentPoints(wild_charge_talent)
	{
		if Stance(druid_bear_form) and target.InRange(wild_charge_bear) and not target.InRange(mangle_bear) Spell(wild_charge_bear)
		if Stance(druid_cat_form) and target.InRange(wild_charge_cat) and not target.InRange(mangle_cat) Spell(wild_charge_cat)
		if target.InRange(wild_charge) Spell(wild_charge)
	}
	Spell(dash)
}

AddIcon mastery=feral help=main
{
	if InCombat(no) FeralPrecombatActions()
	if not target.InRange(mangle_cat) Texture(ability_druid_catformattack)
	if List(opt_feral_rotation basic) FeralBasicActions()
	if List(opt_feral_rotation advanced) FeralAdvancedActions()
}

AddIcon mastery=feral help=main
{
	if InCombat(no) FeralPrecombatActions()
	if not target.InRange(mangle_cat) Texture(ability_druid_catformattack)
	if List(opt_feral_rotation basic) FeralBasicPredictiveActions()
	if List(opt_feral_rotation advanced) FeralAdvancedPredictiveActions()
}

AddIcon mastery=feral help=aoe checkboxon=opt_aoe
{
	if InCombat(no) FeralPrecombatActions()
	FeralAoeActions()
}

AddIcon mastery=feral help=cd
{
	if List(opt_feral_rotation basic) FeralBasicCdActions()
	if List(opt_feral_rotation advanced) FeralAdvancedCdActions()
}

AddIcon mastery=feral help=cd size=small checkboxon=opt_icons_right
{
	if TalentPoints(heart_of_the_wild_talent) Spell(heart_of_the_wild)
	if TalentPoints(natures_vigil_talent) Spell(natures_vigil)
}

AddIcon mastery=feral help=cd size=small checkboxon=opt_icons_right
{
	UseItemActions()
}
]]

	OvaleScripts:RegisterScript("DRUID", name, desc, code)
end
