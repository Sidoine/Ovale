local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_druid"
	local desc = "[5.4] Ovale: Balance, Feral, Guardian, Restoration"
	local code = [[
# Ovale druid script based on SimulationCraft.

Include(ovale_common)
Include(ovale_druid_common)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

###
### Balance
###

### Elitist Jerks rotation functions.

AddCheckBox(opt_elitist_jerks_balance_rotation "Elitist Jerks Balance Rotation" default specialization=balance)

AddFunction BalanceIsNearEclipseState
{
	# True if we're one cast away from reaching the next Eclipse.
	   { EclipseDir() < 0 and BuffExpires(shooting_stars_buff) and Eclipse() + 100 <= 30 }
	or { EclipseDir() < 0 and BuffPresent(shooting_stars_buff) and Eclipse() + 100 <= 40 }
	or { EclipseDir() > 0 and 100 - Eclipse() <= 40 }
}

AddFunction BalanceElitistJerksDotActions
{
	# If both DoTs need to be applied or refreshed, apply the non-Eclipsed DoT first to gain Lunar Shower for the application of the Eclipsed DoT.
	if target.TicksRemain(moonfire_debuff) < 2 and target.TicksRemain(sunfire_debuff) < 2
	{
		if BuffPresent(lunar_eclipse_buff) Spell(sunfire)
		if BuffPresent(solar_eclipse_buff) Spell(moonfire)
	}

	# Apply the Eclipsed DoT when entering the corresponding Eclipse state.
	if BuffPresent(lunar_eclipse_buff) and target.DebuffRemains(moonfire_debuff) < { BuffRemains(natures_grace_buff) - 2 + 2 * ArmorSetBonus(T14_caster 4) } Spell(moonfire)
	if BuffPresent(solar_eclipse_buff) and target.DebuffRemains(sunfire_debuff) < { BuffRemains(natures_grace_buff) - 2 + 2 * ArmorSetBonus(T14_caster 4) } Spell(sunfire)

	# Apply the Eclipsed DoT if it fell off during the Eclipse state.
	if BuffPresent(lunar_eclipse_buff) and target.TicksRemain(moonfire_debuff) < 2 Spell(moonfire)
	if BuffPresent(solar_eclipse_buff) and target.TicksRemain(sunfire_debuff) < 2 Spell(sunfire)

	# Apply the non-Eclipsed DoT only when it is about to expire (on the last tick) and we are not about to enter a new Eclipse state.
	if not BalanceIsNearEclipseState()
	{
		if BuffExpires(lunar_eclipse_buff) and target.TicksRemain(moonfire_debuff) < 2 Spell(moonfire)
		if BuffExpires(solar_eclipse_buff) and target.TicksRemain(sunfire_debuff) < 2 Spell(sunfire)
	}

	# Simplistic logic for refreshing DoTs early to snapshot powerful buff effects.
	if Level() >= 90 and target.DebuffPresent(moonfire_debuff) and Damage(moonfire_debuff) / LastEstimatedDamage(moonfire_debuff) > 1.15 Spell(moonfire)
	if Level() >= 90 and target.DebuffPresent(sunfire_debuff) and Damage(sunfire_debuff) / LastEstimatedDamage(sunfire_debuff) > 1.15 Spell(sunfire)
}

# Minimize the time spent outside of Eclipse by only casting Starsurge at the appropriate times:
#	* The Shooting Stars buff is about to expire.
#	* During Lunar Eclipse unless it pushes you out of Eclipse during Starfall.
#	* When outside Lunar Eclipse and moving toward Solar Eclipse.
#	* The first time Starsurge is available during Solar Eclipse.
#	* The second time Starsurge is available during Solar Eclipse only at 5 Eclipse energy.
#	* When outside Solar Eclipse and moving toward Lunar Eclipse.
#
AddFunction BalanceElitistJerksStarsurgeCondition
{
	   { BuffPresent(shooting_stars_buff) and BuffRemains(shooting_stars_buff) < 2 }
	or { BuffPresent(lunar_eclipse_buff) and 0 - Eclipse() > 20 }
	or { BuffPresent(lunar_eclipse_buff) and 0 - Eclipse() <= 20 and BuffPresent(shooting_stars_buff) and BuffExpires(starfall_buff) }
	or { BuffPresent(lunar_eclipse_buff) and 0 - Eclipse() <= 20 and BuffExpires(shooting_stars_buff) and BuffRemains(starfall_buff) < CastTime(starsurge) }
	or { BuffExpires(lunar_eclipse_buff) and EclipseDir() >= 0 }
	or { BuffPresent(solar_eclipse_buff) and { Eclipse(asValue=1) - 10 } % 15 == 0 }
	or { BuffPresent(solar_eclipse_buff) and Eclipse() == 5 }
	or { BuffExpires(solar_eclipse_buff) and EclipseDir() <= 0 }
}

# Only suggest Starfire at the appropriate times:
#	* During Lunar Eclipse unless it pushes you out of Eclipse during Starfall.
#	* When outside Lunar Eclipse and moving toward Solar Eclipse.
#
AddFunction BalanceElitistJerksStarfireCondition
{
	   { BuffPresent(lunar_eclipse_buff) and 0 - Eclipse() > 20 }
	or { BuffPresent(lunar_eclipse_buff) and 0 - Eclipse() <= 20 and BuffRemains(starfall_buff) < CastTime(starfire) }
	or { BuffExpires(lunar_eclipse_buff) and EclipseDir() >= 0 }
}

AddFunction BalanceElitistJerksMainActions
{
	# Proc Dream of Cenarius with Healing Touch if one cast away from reaching Eclipse.
	if TalentPoints(dream_of_cenarius_talent) and BuffExpires(dream_of_cenarius_caster_buff) and BalanceIsNearEclipseState() Spell(healing_touch)
	# Cast instant-cast Starsurge.
	if BuffPresent(shooting_stars_buff) and BalanceElitistJerksStarsurgeCondition() Spell(starsurge)
	# Apply and maintain Moonfire and Sunfire on the target.
	BalanceElitistJerksDotActions()
	# Proc Dream of Cenarius with Healing Touch after refreshing DoTs if outside of major CD buffs.
	if TalentPoints(dream_of_cenarius_talent) and BuffExpires(dream_of_cenarius_caster_buff) and BuffExpires(celestial_alignment) and BuffExpires(chosen_of_elune_buff) Spell(healing_touch)
	# Cast Starsurge on cooldown.
	if BalanceElitistJerksStarsurgeCondition() Spell(starsurge)
	# Spam Starfire during Celestial Alignment.
	if BuffPresent(celestial_alignment_buff) and CastTime(starfire) < BuffRemains(celestial_alignment_buff) Spell(starfire)
	# Cast Wrath as Celestial Alignment is expiring if the cast will finish before the buff expires.
	if BuffPresent(celestial_alignment_buff) and CastTime(wrath) < BuffRemains(celestial_alignment_buff) Spell(wrath)
	# Cast Starfire if moving toward Solar Eclipse (only if it won't affect Eclipsed Starfall).
	if EclipseDir() > 0 and BalanceElitistJerksStarfireCondition() Spell(starfire)
	# Filler
	Spell(wrath)
}

AddFunction BalanceElitistJerksMovingActions
{
	# Cast instant-cast Starsurge.
	if BuffPresent(shooting_stars_buff) and BalanceElitistJerksStarsurgeCondition() Spell(starsurge)
	# Apply and maintain Moonfire and Sunfire on the target.
	BalanceElitistJerksDotActions()
	if WildMushroomCount() < 3 Spell(wild_mushroom_caster)
	if BuffPresent(solar_eclipse_buff) Spell(sunfire)
	Spell(moonfire)
}

AddFunction BalanceElitistJerksCdActions
{
	if BuffPresent(burst_haste any=1) or target.TimeToDie() <= 40 or BuffPresent(celestial_alignment_buff) UsePotionIntellect()
	if BuffPresent(celestial_alignment_buff) Spell(berserking)
	if BuffPresent(celestial_alignment_buff) or SpellCooldown(celestial_alignment) > 30 UseItemActions()
	if TalentPoints(natures_vigil_talent) and BuffPresent(celestial_alignment_buff) or BuffPresent(chosen_of_elune_buff) Spell(natures_vigil)

	unless { TalentPoints(dream_of_cenarius_talent) and BuffExpires(dream_of_cenarius_caster_buff) and BalanceIsNearEclipseState() }
	{
		if TalentPoints(incarnation_talent) and { BuffPresent(lunar_eclipse_buff) or BuffPresent(solar_eclipse_buff) } and BuffPresent(natures_grace_buff) Spell(incarnation)
		if { BuffExpires(lunar_eclipse_buff) and BuffExpires(solar_eclipse_buff) } and { BuffPresent(chosen_of_elune_buff) or not TalentPoints(incarnation_talent) or SpellCooldown(incarnation) > 10 } Spell(celestial_alignment)
	}
}

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

AddFunction BalanceAoeActions
{
	#wild_mushroom_detonate,moving=0,if=buff.wild_mushroom.stack>0&buff.solar_eclipse.up
	if WildMushroomCount() > 0 and BuffPresent(solar_eclipse_buff) Spell(wild_mushroom_detonate)
	#hurricane,if=active_enemies>4&buff.solar_eclipse.up&buff.natures_grace.up
	if BuffPresent(solar_eclipse_buff) and BuffPresent(natures_grace_buff) Spell(hurricane)
	#hurricane,if=active_enemies>5&buff.solar_eclipse.up&mana.pct>25
	if BuffPresent(solar_eclipse_buff) and ManaPercent() > 25 Spell(hurricane)
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
	#healing_touch,if=!buff.dream_of_cenarius.up&talent.dream_of_cenarius.enabled
	if not BuffPresent(dream_of_cenarius_caster_buff) and TalentPoints(dream_of_cenarius_talent) Spell(healing_touch)
	#moonkin_form
	if not Stance(druid_moonkin_form) Spell(moonkin_form)
	# Snapshot raid buffed stats before combat begins and pre-potting is done.
	#snapshot_stats
}

AddFunction BalancePrecombatMovingActions
{
	#wild_mushroom,if=buff.wild_mushroom.stack<buff.wild_mushroom.max_stack
	if WildMushroomCount() < 3 Spell(wild_mushroom_caster)
}

AddFunction BalancePrecombatCdActions
{
	#jade_serpent_potion
	UsePotionIntellect()
}

### Balance Icons

AddIcon specialization=balance size=small checkbox=opt_icons_left
{
	Spell(barkskin)
	Spell(survival_instincts)
	Spell(might_of_ursoc)
	if TalentPoints(renewal_talent) Spell(renewal)
	if TalentPoints(cenarion_ward_talent) Spell(cenarion_ward)
	Spell(tranquility)
}

AddIcon specialization=balance size=small checkbox=opt_icons_left
{
	#wild_mushroom_detonate,moving=0,if=buff.wild_mushroom.stack>0&buff.solar_eclipse.up
	if WildMushroomCount() > 0 and BuffPresent(solar_eclipse_buff) Spell(wild_mushroom_detonate)
}

AddIcon specialization=balance help=shortcd
{
	if not Stance(druid_moonkin_form) Spell(moonkin_form)

	BalanceDefaultShortCdActions()
	BalanceAoeActions()
}

AddIcon specialization=balance help=main
{
	if InCombat(no) BalancePrecombatActions()
	if CheckBoxOn(opt_elitist_jerks_balance_rotation) BalanceElitistJerksMainActions()
	if CheckBoxOff(opt_elitist_jerks_balance_rotation) BalanceDefaultActions()
}

AddIcon specialization=balance help=moving
{
	if InCombat(no) BalancePrecombatMovingActions()
	if CheckBoxOn(opt_elitist_jerks_balance_rotation) BalanceElitistJerksMovingActions()
	if CheckBoxOff(opt_elitist_jerks_balance_rotation) BalanceDefaultMovingActions()
}

AddIcon specialization=balance help=cd
{
	BalanceInterrupt()
	if CheckBoxOn(opt_elitist_jerks_balance_rotation) BalanceElitistJerksCdActions()
	if CheckBoxOff(opt_elitist_jerks_balance_rotation) BalanceDefaultCdActions()
}

AddIcon specialization=balance size=small checkbox=opt_icons_right
{
	if TalentPoints(heart_of_the_wild_talent) Spell(heart_of_the_wild_caster)
	if TalentPoints(natures_vigil_talent) Spell(natures_vigil)
}

AddIcon specialization=balance size=small checkbox=opt_icons_right
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

AddCheckBox(opt_weakened_armor_debuff SpellName(weakened_armor_debuff) default specialization=feral)

AddFunction FeralFillerActions
{
	#ravage
	Spell(ravage usable=1)
	#rake,if=target.time_to_die-dot.rake.remains>3&action.rake.tick_damage*(dot.rake.ticks_remain+1)-dot.rake.tick_dmg*dot.rake.ticks_remain>action.mangle_cat.hit_damage
	if target.TimeToDie() - target.DebuffRemains(rake_debuff) > 3 and target.Damage(rake_debuff) * { target.TicksRemain(rake_debuff) + 1 } - target.LastEstimatedDamage(rake_debuff) * target.TicksRemain(rake_debuff) > target.Damage(mangle_cat) Spell(rake)
	#shred,if=(buff.omen_of_clarity.react|buff.berserk.up|energy.regen>=15)&buff.king_of_the_jungle.down
	if { BuffPresent(omen_of_clarity_melee_buff) or BuffPresent(berserk_cat_buff) or EnergyRegen() >= 15 } and BuffExpires(king_of_the_jungle_buff) Spell(shred)
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
	if CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 Spell(faerie_fire)
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if TalentPoints(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemains(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.remains<3
	if BuffRemains(savage_roar_buff) < 3 SavageRoar()
	#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
	if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
	#rip,if=combo_points>=5&target.health.pct<=25&action.rip.tick_damage%dot.rip.tick_dmg>=1.15
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 1.15 Spell(rip)
	#ferocious_bite,if=combo_points>=5&target.health.pct<=25&dot.rip.ticking
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
	#rip,if=combo_points>=5&dot.rip.remains<2
	if ComboPoints() >= 5 and target.DebuffRemains(rip_debuff) < 2 Spell(rip)
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemains(thrash_cat_debuff) < 3 Spell(thrash_cat)
	#rake,cycle_targets=1,if=dot.rake.remains<3|action.rake.tick_damage>dot.rake.tick_dmg
	if target.DebuffRemains(rake_debuff) < 3 or target.Damage(rake_debuff) > target.LastEstimatedDamage(rake_debuff) Spell(rake)
	#pool_resource,for_next=1
	#thrash_cat,if=dot.thrash_cat.remains<3&(dot.rip.remains>=8&buff.savage_roar.remains>=12|buff.berserk.up|combo_points>=5)
	if target.DebuffRemains(thrash_cat_debuff) < 3 and { target.DebuffRemains(rip_debuff) >= 8 and BuffRemains(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } wait Spell(thrash_cat)
	#pool_resource,if=combo_points>=5&!(energy.time_to_max<=1|(buff.berserk.up&energy>=25)|(buff.feral_rage.up&buff.feral_rage.remains<=1))&dot.rip.ticking
	unless ComboPoints() >= 5 and not { TimeToMaxEnergy() <= 1 or { BuffPresent(berserk_cat_buff) and Energy() >= 25 } or { BuffPresent(feral_rage_buff) and BuffRemains(feral_rage_buff) <= 1 } } and target.DebuffPresent(rip_debuff)
	{
		#ferocious_bite,if=combo_points>=5&dot.rip.ticking
		if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
		#run_action_list,name=filler,if=buff.omen_of_clarity.react
		if BuffPresent(omen_of_clarity_melee_buff) FeralFillerActions()
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
	if CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 Spell(faerie_fire)
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if TalentPoints(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemains(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.remains<3
	if BuffRemains(savage_roar_buff) < 3 SavageRoar()
	#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
	if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
	#rip,if=combo_points>=5&target.health.pct<=25&action.rip.tick_damage%dot.rip.tick_dmg>=1.15
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 1.15 Spell(rip)
	#ferocious_bite,if=combo_points>=5&target.health.pct<=25&dot.rip.ticking
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
	#rip,if=combo_points>=5&dot.rip.remains<2
	if ComboPoints() >= 5 and target.DebuffRemains(rip_debuff) < 2 Spell(rip)
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemains(thrash_cat_debuff) < 3 Spell(thrash_cat)
	#rake,cycle_targets=1,if=dot.rake.remains<3|action.rake.tick_damage>dot.rake.tick_dmg
	if target.DebuffRemains(rake_debuff) < 3 or target.Damage(rake_debuff) > target.LastEstimatedDamage(rake_debuff) Spell(rake)
	#pool_resource,for_next=1
	#thrash_cat,if=dot.thrash_cat.remains<3&(dot.rip.remains>=8&buff.savage_roar.remains>=12|buff.berserk.up|combo_points>=5)
	if target.DebuffRemains(thrash_cat_debuff) < 3 and { target.DebuffRemains(rip_debuff) >= 8 and BuffRemains(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } wait Spell(thrash_cat)
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
		or { CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 and Spell(faerie_fire) }
		or { TalentPoints(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemains(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } and Spell(healing_touch) }
		or { BuffRemains(savage_roar_buff) < 3 and SavageRoar() }
	{
		#virmens_bite_potion,if=(target.health.pct<30&buff.berserk.up)|target.time_to_die<=40
		if { target.HealthPercent() < 30 and BuffPresent(berserk_cat_buff) } or target.TimeToDie() <= 40 UsePotionAgility()

		# Synchronize display with Tiger's Fury buff in main actions.
		if { Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) } or BuffPresent(tigers_fury_buff)
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
	if CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 Spell(faerie_fire)
	#savage_roar,if=buff.savage_roar.down|(buff.savage_roar.remains<3&combo_points>0)
	if BuffExpires(savage_roar_buff) or { BuffRemains(savage_roar_buff) < 3 and ComboPoints() > 0 } SavageRoar()
	#use_item,slot=hands,if=buff.tigers_fury.up
	#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
	if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
	#berserk,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) Spell(berserk_cat)
	#pool_resource,for_next=1
	#thrash_cat,if=buff.rune_of_reorigination.up
	if BuffPresent(rune_of_reorigination_buff) wait Spell(thrash_cat)
	#pool_resource,wait=0.1,for_next=1
	#thrash_cat,if=dot.thrash_cat.remains<3|(buff.tigers_fury.up&dot.thrash_cat.remains<9)
	if target.DebuffRemains(thrash_cat_debuff) < 3 or { BuffPresent(tigers_fury_buff) and target.DebuffRemains(thrash_cat_debuff) < 9 } wait Spell(thrash_cat)
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
	if BuffPresent(omen_of_clarity_melee_buff) Spell(swipe_cat)
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
	if CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 Spell(faerie_fire)
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if TalentPoints(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemains(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.down
	if BuffExpires(savage_roar_buff) SavageRoar()
	#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
	if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3&target.time_to_die>=6
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemains(thrash_cat_debuff) < 3 and target.TimeToDie() >= 6 Spell(thrash_cat)
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
		if target.TimeToDie() >= 6 and target.DebuffRemains(thrash_cat_debuff) < 3 and { target.DebuffRemains(rip_debuff) >= 8 and BuffRemains(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } and target.DebuffPresent(rip_debuff) wait Spell(thrash_cat)
		#pool_resource,for_next=1
		#thrash_cat,if=target.time_to_die>=6&dot.thrash_cat.remains<9&buff.rune_of_reorigination.up&buff.rune_of_reorigination.remains<=1.5&dot.rip.ticking
		if target.TimeToDie() >= 6 and target.DebuffRemains(thrash_cat_debuff) < 9 and BuffPresent(rune_of_reorigination_buff) and BuffRemains(rune_of_reorigination_buff) <= 1.5 and target.DebuffPresent(rip_debuff) wait Spell(thrash_cat)
		#pool_resource,if=combo_points>=5&!(energy.time_to_max<=1|(buff.berserk.up&energy>=25)|(buff.feral_rage.up&buff.feral_rage.remains<=1))&dot.rip.ticking
		unless ComboPoints() >= 5 and not { TimeToMaxEnergy() <= 1 or { BuffPresent(berserk_cat_buff) and Energy() >= 25 } or { BuffPresent(feral_rage_buff) and BuffRemains(feral_rage_buff) <= 1 } } and target.DebuffPresent(rip_debuff)
		{
			#ferocious_bite,if=combo_points>=5&dot.rip.ticking
			if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
			#run_action_list,name=filler,if=buff.omen_of_clarity.react
			if BuffPresent(omen_of_clarity_melee_buff) FeralFillerActions()
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
	if CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 Spell(faerie_fire)
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if TalentPoints(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemains(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.down
	if BuffExpires(savage_roar_buff) SavageRoar()
	#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
	if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3&target.time_to_die>=6
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemains(thrash_cat_debuff) < 3 and target.TimeToDie() >= 6 Spell(thrash_cat)
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
		if target.TimeToDie() >= 6 and target.DebuffRemains(thrash_cat_debuff) < 3 and { target.DebuffRemains(rip_debuff) >= 8 and BuffRemains(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } and target.DebuffPresent(rip_debuff) wait Spell(thrash_cat)
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
		or { CheckBoxOn(opt_weakened_armor_debuff) and target.DebuffStacks(weakened_armor_debuff any=1) < 3 and Spell(faerie_fire) }
		or { TalentPoints(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemains(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } and Spell(healing_touch) }
		or { BuffExpires(savage_roar_buff) and SavageRoar() }
	{
		# Synchronize display with Tiger's Fury buff in main actions.
		if target.TimeToDie() < 18 and SpellCooldown(tigers_fury) > 6 Spell(berserk_cat)
		if { Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) } or BuffPresent(tigers_fury_buff)
		{
			#berserk,if=buff.tigers_fury.up|(target.time_to_die<18&cooldown.tigers_fury.remains>6)
			Spell(berserk_cat)
			#use_item,slot=hands,if=buff.tigers_fury.up
			UseItemActions()
		}

		unless { BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemains(thrash_cat_debuff) < 3 and target.TimeToDie() >= 6 and Spell(thrash_cat) }
			or { target.TimeToDie() <= 1 and ComboPoints() >= 3 or Spell(ferocious_bite) }
			or { BuffRemains(savage_roar_buff) <= 3 and ComboPoints() > 0 and target.HealthPercent() < 25 and SavageRoar() }
		{
			#virmens_bite_potion,if=(combo_points>=5&(target.time_to_die*(target.health.pct-25)%target.health.pct)<15&buff.rune_of_reorigination.up)|target.time_to_die<=40
			if { ComboPoints() >= 5 and { target.TimeToDie() * { target.HealthPercent() -25 } / target.HealthPercent() } < 15 and BuffPresent(rune_of_reorigination_buff) } or target.TimeToDie() <= 40 UsePotionAgility()
		}
	}
}

AddListItem(opt_feral_rotation basic "Use basic rotation" default specialization=feral)
AddListItem(opt_feral_rotation advanced "Use advanced rotation" specialization=feral)

### Feral Icons

AddIcon specialization=feral size=small checkbox=opt_icons_left
{
	Spell(barkskin)
	Spell(survival_instincts)
	Spell(might_of_ursoc)
	if TalentPoints(renewal_talent) Spell(renewal)
	if TalentPoints(cenarion_ward_talent) Spell(cenarion_ward)
	Spell(tranquility)
}

AddIcon specialization=feral size=small checkbox=opt_icons_left
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

AddIcon specialization=feral help=main
{
	if InCombat(no) FeralPrecombatActions()
	if not target.InRange(mangle_cat) Texture(ability_druid_catformattack help=NotInMeleeRange)
	if List(opt_feral_rotation basic) FeralBasicActions()
	if List(opt_feral_rotation advanced) FeralAdvancedActions()
}

AddIcon specialization=feral help=main
{
	if InCombat(no) FeralPrecombatActions()
	if not target.InRange(mangle_cat) Texture(ability_druid_catformattack help=NotInMeleeRange)
	if List(opt_feral_rotation basic) FeralBasicPredictiveActions()
	if List(opt_feral_rotation advanced) FeralAdvancedPredictiveActions()
}

AddIcon specialization=feral help=aoe checkbox=opt_aoe
{
	if InCombat(no) FeralPrecombatActions()
	FeralAoeActions()
}

AddIcon specialization=feral help=cd
{
	if List(opt_feral_rotation basic) FeralBasicCdActions()
	if List(opt_feral_rotation advanced) FeralAdvancedCdActions()
}

AddIcon specialization=feral size=small checkbox=opt_icons_right
{
	if TalentPoints(heart_of_the_wild_talent) Spell(heart_of_the_wild_melee)
	if TalentPoints(natures_vigil_talent) Spell(natures_vigil)
}

AddIcon specialization=feral size=small checkbox=opt_icons_right
{
	UseItemActions()
}

###
### Guardian
###

AddFunction GuardianAoeActions
{
	# AoE rotation: Mangle > Thrash > Swipe
	if target.DebuffRemains(thrash_bear_debuff) < 3 Spell(thrash_bear)
	Spell(mangle_bear)
	Spell(thrash_bear)
	Spell(swipe_bear)
}

AddFunction GuardianMainActions
{
	#thrash_bear,if=debuff.weakened_blows.remains<3
	if target.DebuffRemains(weakened_blows_debuff any=1) < 3 Spell(thrash_bear)
	#lacerate,if=((dot.lacerate.remains<3)|(buff.lacerate.stack<3&dot.thrash_bear.remains>3))&(buff.son_of_ursoc.up|buff.berserk.up)
	if { target.DebuffRemains(lacerate_debuff) < 3 or { target.DebuffStacks(lacerate_debuff) < 3 and target.DebuffRemains(thrash_bear_debuff) > 3 } } and { BuffPresent(son_of_ursoc_buff) or BuffPresent(berserk_bear_buff) } Spell(lacerate)
	#faerie_fire,if=debuff.weakened_armor.stack<3
	if target.DebuffStacks(weakened_armor_debuff any=1) < 3 FaerieFire()
	#thrash_bear,if=dot.thrash_bear.remains<3&(buff.son_of_ursoc.up|buff.berserk.up)
	if target.DebuffRemains(thrash_bear_debuff) < 3 and { BuffPresent(son_of_ursoc_buff) or BuffPresent(berserk_bear_buff) } Spell(thrash_bear)
	#mangle_bear
	#wait,sec=cooldown.mangle_bear.remains,if=cooldown.mangle_bear.remains<=0.5
	Spell(mangle_bear wait=0.5)
	#cenarion_ward,if=talent.cenarion_ward.enabled
	if TalentPoints(cenarion_ward_talent) Spell(cenarion_ward)
	if BuffPresent(dream_of_cenarius_tank_buff) Spell(healing_touch)
	#lacerate,if=dot.lacerate.remains<3|buff.lacerate.stack<3
	if target.DebuffRemains(lacerate_debuff) < 3 or target.DebuffStacks(lacerate_debuff) < 3 Spell(lacerate)
	#thrash_bear,if=dot.thrash_bear.remains<2
	if target.DebuffRemains(thrash_bear_debuff) < 2 Spell(thrash_bear)
	#lacerate
	Spell(lacerate)
	#faerie_fire,if=dot.thrash_bear.remains>6
	if target.DebuffRemains(thrash_bear_debuff) > 6 FaerieFire()
	#thrash_bear
	Spell(thrash_bear)
	FaerieFire()
}

AddFunction GuardianShortCdActions
{
	#frenzied_regeneration,if=health.pct<100&action.savage_defense.charges=0&incoming_damage_5>0.2*health.max
	if HealthPercent() < 100 and Charges(savage_defense) < 1 and IncomingDamage(5) > 0.2 * MaxHealth() Spell(frenzied_regeneration)
	#frenzied_regeneration,if=health.pct<100&action.savage_defense.charges>0&incoming_damage_5>0.4*health.max
	if HealthPercent() < 100 and Charges(savage_defense) > 0 and IncomingDamage(5) > 0.4 * MaxHealth() Spell(frenzied_regeneration)
	#savage_defense
	Spell(savage_defense)
	#maul,if=buff.tooth_and_claw.react&buff.tooth_and_claw_absorb.down
	if BuffPresent(tooth_and_claw_buff) and target.DebuffExpires(tooth_and_claw_debuff) Spell(maul)
}

AddFunction GuardianCdActions
{
	GuardianInterrupt()
	if Rage() < 11 Spell(enrage)
	if HealthPercent() < 25
	{
		if BuffExpires(son_of_ursoc) Spell(berserk_bear)
		if TalentPoints(incarnation_talent) and BuffExpires(berserk_bear_buff) Spell(incarnation)
	}
	if BuffExpires(burst_haste any=1) Spell(berserking)
	if BuffExpires(son_of_ursoc) Spell(berserk_bear)
	if TalentPoints(incarnation_talent) and BuffExpires(berserk_bear) Spell(incarnation)
}

AddFunction GuardianPrecombatActions
{
	if BuffRemains(str_agi_int any=1) < 600 Spell(mark_of_the_wild)
	if not Stance(druid_bear_form) Spell(bear_form)
}

### Guardian icons.

AddIcon specialization=guardian size=small checkbox=opt_icons_left
{
	Spell(might_of_ursoc)
}

AddIcon specialization=guardian size=small checkbox=opt_icons_left
{
	Spell(barkskin)
	if TalentPoints(force_of_nature_talent) Spell(force_of_nature_tank)
	Spell(survival_instincts)
}

AddIcon specialization=guardian help=shortcd
{
	GuardianShortCdActions()
}

AddIcon specialization=guardian help=main
{
	if InCombat(no) GuardianPrecombatActions()
	GuardianMainActions()
}

AddIcon specialization=guardian help=aoe checkbox=aoe
{
	GuardianAoeActions()
}

AddIcon specialization=guardian help=cd
{
	GuardianCdActions()
}

AddIcon specialization=guardian size=small checkbox=opt_icons_right
{
	#renewal,if=talent.renewal.enabled&incoming_damage_5>0.8*health.max
	if TalentPoints(renewal_talent) and IncomingDamage(5) > 0.8 * MaxHealth() Spell(renewal)
}

AddIcon specialization=guardian size=small checkbox=opt_icons_right
{
	UseItemActions()
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
	if BuffRemains(harmony_buff) < 6
	{
		if BuffCountOnAny(rejuvenation_buff) > 0 or BuffCountOnAny(regrowth_buff) > 0 Swiftmend()
		Spell(nourish)
	}

	# Keep one Lifebloom stack up on the raid.
	if BuffRemainsOnAny(lifebloom_buff stacks=3) < 4 Spell(lifebloom)

	# Cast Cenarion Ward on cooldown, usually on the tank.
	if TalentPoints(cenarion_ward_talent) Spell(cenarion_ward)
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
	if TalentPoints(force_of_nature_talent) Spell(force_of_nature_heal)
	if TalentPoints(incarnation_talent) Spell(incarnation)
	if TalentPoints(heart_of_the_wild_talent) Spell(heart_of_the_wild_heal)
	if TalentPoints(natures_vigil_talent) Spell(natures_vigil)
}

AddFunction RestorationPrecombatActions
{
	if BuffRemains(str_agi_int any=1) < 600 Spell(mark_of_the_wild)
}

### Restoration icons.

AddIcon specialization=restoration size=small checkbox=opt_icons_left
{
	Spell(barkskin)
	Spell(might_of_ursoc)
	Spell(survival_instincts)
}

AddIcon specialization=restoration size=small checkbox=opt_icons_left
{
	#innervate,if=mana.pct<90
	if ManaPercent() < 90 Spell(innervate)
	Spell(tranquility)
	if TalentPoints(natures_vigil_talent) Spell(natures_vigil)
}

AddIcon specialization=restoration help=shortcd
{
	RestorationShortCdActions()
}

AddIcon specialization=restoration help=main
{
	if InCombat(no) RestorationPrecombatActions()
	RestorationMainActions()
}

AddIcon specialization=restoration help=aoe checkbox=opt_aoe
{
	RestorationAoeActions()
}

AddIcon specialization=restoration help=cd
{
	RestorationInterrupt()
	RestorationCdActions()
}

AddIcon specialization=restoration size=small checkbox=opt_icons_right
{
	Spell(ironbark)
	Spell(natures_swiftness)
}

AddIcon specialization=restoration size=small checkbox=opt_icons_right
{
	UseItemActions()
}
]]

	OvaleScripts:RegisterScript("DRUID", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("DRUID", "Ovale", desc, code, "script")
end
