local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_priest"
	local desc = "[6.0] Ovale: Rotations (Shadow)"
	local code = [[
# Priest rotation functions based on SimulationCraft.

###
### Shadow
###
# Based on SimulationCraft profile "Priest_Shadow_T17M_COP".
#	class=priest
#	spec=shadow
#	talents=1133131
#	glyphs=mind_flay/fade/sha

AddCheckBox(opt_interrupt L(interrupt) default specialization=shadow)
AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=shadow)

AddFunction ShadowUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction ShadowInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		Spell(silence)
		if not target.Classification(worldboss)
		{
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			Spell(war_stomp)
		}
	}
}

### actions.default

AddFunction ShadowDefaultMainActions
{
	#shadowform,if=!buff.shadowform.up
	if not BuffPresent(shadowform_buff) Spell(shadowform)
	#call_action_list,name=pvp_dispersion,if=set_bonus.pvp_2pc
	if ArmorSetBonus(PVP 2) ShadowPvpDispersionMainActions()
	#call_action_list,name=decision
	ShadowDecisionMainActions()
}

AddFunction ShadowDefaultShortCdActions
{
	unless not BuffPresent(shadowform_buff) and Spell(shadowform)
	{
		#call_action_list,name=pvp_dispersion,if=set_bonus.pvp_2pc
		if ArmorSetBonus(PVP 2) ShadowPvpDispersionShortCdActions()

		unless ArmorSetBonus(PVP 2) and ShadowPvpDispersionShortCdPostConditions()
		{
			#call_action_list,name=decision
			ShadowDecisionShortCdActions()
		}
	}
}

AddFunction ShadowDefaultCdActions
{
	unless not BuffPresent(shadowform_buff) and Spell(shadowform)
	{
		#silence
		ShadowInterruptActions()
		#potion,name=draenic_intellect,if=buff.bloodlust.react|target.time_to_die<=40
		if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 40 ShadowUsePotionIntellect()
		#power_infusion,if=talent.power_infusion.enabled
		if Talent(power_infusion_talent) Spell(power_infusion)
		#blood_fury
		Spell(blood_fury_sp)
		#berserking
		Spell(berserking)
		#arcane_torrent
		Spell(arcane_torrent_mana)
		#call_action_list,name=pvp_dispersion,if=set_bonus.pvp_2pc
		if ArmorSetBonus(PVP 2) ShadowPvpDispersionCdActions()

		unless ArmorSetBonus(PVP 2) and ShadowPvpDispersionCdPostConditions()
		{
			#call_action_list,name=decision
			ShadowDecisionCdActions()
		}
	}
}

### actions.cop

AddFunction ShadowCopMainActions
{
	#devouring_plague,if=shadow_orb=5&primary_target=0&!target.dot.devouring_plague_dot.ticking&target.time_to_die>=(gcd*4*7%6),cycle_targets=1
	if ShadowOrbs() == 5 and 1 == 0 and not target.DebuffPresent(devouring_plague_dot_debuff) and target.TimeToDie() >= GCD() * 4 * 7 / 6 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5&!target.dot.devouring_plague_dot.ticking
	if ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_dot_debuff) Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5&primary_target=0&target.time_to_die>=(gcd*4*7%6)&(cooldown.mind_blast.remains<=gcd|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20)),cycle_targets=1
	if ShadowOrbs() == 5 and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5&(cooldown.mind_blast.remains<=gcd|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))
	if ShadowOrbs() == 5 and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } Spell(devouring_plague)
	#devouring_plague,if=primary_target=0&buff.mental_instinct.remains<gcd&buff.mental_instinct.remains>(gcd*0.7)&buff.mental_instinct.remains,cycle_targets=1
	if 1 == 0 and BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) Spell(devouring_plague)
	#devouring_plague,if=buff.mental_instinct.remains<gcd&buff.mental_instinct.remains>(gcd*0.7)&buff.mental_instinct.remains
	if BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&!set_bonus.tier17_2pc&!set_bonus.tier17_4pc&(cooldown.mind_blast.remains<=gcd|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))&primary_target=0&target.time_to_die>=(gcd*4*7%6),cycle_targets=1
	if ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&!set_bonus.tier17_2pc&!set_bonus.tier17_4pc&(cooldown.mind_blast.remains<=gcd|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))
	if ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&set_bonus.tier17_2pc&!set_bonus.tier17_4pc&(cooldown.mind_blast.remains<=gcd*2|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))&primary_target=0&target.time_to_die>=(gcd*4*7%6),cycle_targets=1
	if ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() * 2 or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&set_bonus.tier17_2pc&!set_bonus.tier17_4pc&(cooldown.mind_blast.remains<=gcd*2|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))
	if ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() * 2 or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } Spell(devouring_plague)
	#mind_blast,if=mind_harvest=0,cycle_targets=1
	if target.MindHarvest() == 0 Spell(mind_blast)
	#mind_blast,if=cooldown_react
	if not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#shadow_word_death,if=natural_shadow_word_death_range&!target.dot.shadow_word_pain.ticking&!target.dot.vampiric_touch.ticking,cycle_targets=1
	if target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) Spell(shadow_word_death)
	#shadow_word_death,if=natural_shadow_word_death_range,cycle_targets=1
	if target.HealthPercent() < 20 Spell(shadow_word_death)
	#shadow_word_pain,if=remains<(18*0.3)&target.time_to_die>(18*0.75)&miss_react&!ticking&active_enemies<=5&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) and Enemies() <= 5 and 1 == 0 Spell(shadow_word_pain)
	#vampiric_touch,if=remains<(15*0.3+cast_time)&target.time_to_die>(15*0.75+cast_time)&miss_react&active_enemies<=5&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and 1 == 0 Spell(vampiric_touch)
	#mind_spike,if=active_enemies<=4&buff.surge_of_darkness.react
	if Enemies() <= 4 and BuffPresent(surge_of_darkness_buff) Spell(mind_spike)
	#mind_sear,if=active_enemies>=8,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() >= 8 Spell(mind_sear)
	#mind_spike,if=target.dot.devouring_plague_tick.remains&target.dot.devouring_plague_tick.remains<cast_time
	if target.DebuffRemaining(devouring_plague_debuff) and target.DebuffRemaining(devouring_plague_debuff) < CastTime(mind_spike) Spell(mind_spike)
	#mind_flay,if=target.dot.devouring_plague_tick.ticks_remain>1&active_enemies=1,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if target.TicksRemaining(devouring_plague_debuff) > 1 and Enemies() == 1 Spell(mind_flay)
	#mind_spike
	Spell(mind_spike)
	#shadow_word_death,moving=1,if=!target.dot.shadow_word_pain.ticking&!target.dot.vampiric_touch.ticking,cycle_targets=1
	if Speed() > 0 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) Spell(shadow_word_death)
	#shadow_word_death,moving=1,if=movement.remains>=1*gcd
	if Speed() > 0 and 0 >= 1 * GCD() Spell(shadow_word_death)
	#power_word_shield,moving=1,if=talent.body_and_soul.enabled&movement.distance>=25
	if Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 Spell(power_word_shield)
	#devouring_plague,moving=1
	if Speed() > 0 Spell(devouring_plague)
}

AddFunction ShadowCopShortCdActions
{
	unless ShadowOrbs() == 5 and 1 == 0 and not target.DebuffPresent(devouring_plague_dot_debuff) and target.TimeToDie() >= GCD() * 4 * 7 / 6 and Spell(devouring_plague) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_dot_debuff) and Spell(devouring_plague) or ShadowOrbs() == 5 and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or ShadowOrbs() == 5 and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or 1 == 0 and BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 and Spell(devouring_plague) or ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() * 2 or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 and Spell(devouring_plague) or ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() * 2 or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or target.MindHarvest() == 0 and Spell(mind_blast) or not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or target.HealthPercent() < 20 and Spell(shadow_word_death)
	{
		#halo,if=talent.halo.enabled&target.distance<=30&target.distance>=17
		if Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo_caster)
		#cascade,if=talent.cascade.enabled&(active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11
		if Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade_caster)
		#divine_star,if=talent.divine_star.enabled&active_enemies>3&target.distance<=24
		if Talent(divine_star_talent) and Enemies() > 3 and target.Distance() <= 24 Spell(divine_star_caster)

		unless DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) and Enemies() <= 5 and 1 == 0 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and 1 == 0 and Spell(vampiric_touch)
		{
			#divine_star,if=talent.divine_star.enabled&active_enemies=3&target.distance<=24
			if Talent(divine_star_talent) and Enemies() == 3 and target.Distance() <= 24 Spell(divine_star_caster)

			unless Enemies() <= 4 and BuffPresent(surge_of_darkness_buff) and Spell(mind_spike) or Enemies() >= 8 and Spell(mind_sear) or target.DebuffRemaining(devouring_plague_debuff) and target.DebuffRemaining(devouring_plague_debuff) < CastTime(mind_spike) and Spell(mind_spike) or target.TicksRemaining(devouring_plague_debuff) > 1 and Enemies() == 1 and Spell(mind_flay) or Spell(mind_spike) or Speed() > 0 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield)
			{
				#halo,moving=1,if=talent.halo.enabled&target.distance<=30
				if Speed() > 0 and Talent(halo_talent) and target.Distance() <= 30 Spell(halo_caster)
				#divine_star,if=talent.divine_star.enabled&target.distance<=28,moving=1
				if Talent(divine_star_talent) and target.Distance() <= 28 and Speed() > 0 Spell(divine_star_caster)
				#cascade,if=talent.cascade.enabled&target.distance<=40,moving=1
				if Talent(cascade_talent) and target.Distance() <= 40 and Speed() > 0 Spell(cascade_caster)
			}
		}
	}
}

AddFunction ShadowCopShortCdPostConditions
{
	ShadowOrbs() == 5 and 1 == 0 and not target.DebuffPresent(devouring_plague_dot_debuff) and target.TimeToDie() >= GCD() * 4 * 7 / 6 and Spell(devouring_plague) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_dot_debuff) and Spell(devouring_plague) or ShadowOrbs() == 5 and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or ShadowOrbs() == 5 and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or 1 == 0 and BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 and Spell(devouring_plague) or ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() * 2 or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 and Spell(devouring_plague) or ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() * 2 or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or target.MindHarvest() == 0 and Spell(mind_blast) or not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or target.HealthPercent() < 20 and Spell(shadow_word_death) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) and Enemies() <= 5 and 1 == 0 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and 1 == 0 and Spell(vampiric_touch) or Enemies() <= 4 and BuffPresent(surge_of_darkness_buff) and Spell(mind_spike) or Enemies() >= 8 and Spell(mind_sear) or target.DebuffRemaining(devouring_plague_debuff) and target.DebuffRemaining(devouring_plague_debuff) < CastTime(mind_spike) and Spell(mind_spike) or target.TicksRemaining(devouring_plague_debuff) > 1 and Enemies() == 1 and Spell(mind_flay) or Spell(mind_spike) or Speed() > 0 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield) or Speed() > 0 and Spell(devouring_plague)
}

AddFunction ShadowCopCdActions
{
	unless ShadowOrbs() == 5 and 1 == 0 and not target.DebuffPresent(devouring_plague_dot_debuff) and target.TimeToDie() >= GCD() * 4 * 7 / 6 and Spell(devouring_plague) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_dot_debuff) and Spell(devouring_plague) or ShadowOrbs() == 5 and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or ShadowOrbs() == 5 and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or 1 == 0 and BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 and Spell(devouring_plague) or ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() * 2 or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 and Spell(devouring_plague) or ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() * 2 or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or target.MindHarvest() == 0 and Spell(mind_blast) or not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or target.HealthPercent() < 20 and Spell(shadow_word_death)
	{
		#mindbender,if=talent.mindbender.enabled
		if Talent(mindbender_talent) Spell(mindbender)
		#shadowfiend,if=!talent.mindbender.enabled
		if not Talent(mindbender_talent) Spell(shadowfiend)
	}
}

AddFunction ShadowCopCdPostConditions
{
	ShadowOrbs() == 5 and 1 == 0 and not target.DebuffPresent(devouring_plague_dot_debuff) and target.TimeToDie() >= GCD() * 4 * 7 / 6 and Spell(devouring_plague) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_dot_debuff) and Spell(devouring_plague) or ShadowOrbs() == 5 and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or ShadowOrbs() == 5 and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or 1 == 0 and BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 and Spell(devouring_plague) or ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() * 2 or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and 1 == 0 and target.TimeToDie() >= GCD() * 4 * 7 / 6 and Spell(devouring_plague) or ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= GCD() * 2 or SpellCooldown(shadow_word_death) <= GCD() and target.HealthPercent() < 20 } and Spell(devouring_plague) or target.MindHarvest() == 0 and Spell(mind_blast) or not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or target.HealthPercent() < 20 and Spell(shadow_word_death) or Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 and Spell(halo_caster) or Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 and Spell(cascade_caster) or Talent(divine_star_talent) and Enemies() > 3 and target.Distance() <= 24 and Spell(divine_star_caster) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) and Enemies() <= 5 and 1 == 0 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and 1 == 0 and Spell(vampiric_touch) or Talent(divine_star_talent) and Enemies() == 3 and target.Distance() <= 24 and Spell(divine_star_caster) or Enemies() <= 4 and BuffPresent(surge_of_darkness_buff) and Spell(mind_spike) or Enemies() >= 8 and Spell(mind_sear) or target.DebuffRemaining(devouring_plague_debuff) and target.DebuffRemaining(devouring_plague_debuff) < CastTime(mind_spike) and Spell(mind_spike) or target.TicksRemaining(devouring_plague_debuff) > 1 and Enemies() == 1 and Spell(mind_flay) or Spell(mind_spike) or Speed() > 0 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield) or Speed() > 0 and Talent(halo_talent) and target.Distance() <= 30 and Spell(halo_caster) or Talent(divine_star_talent) and target.Distance() <= 28 and Speed() > 0 and Spell(divine_star_caster) or Talent(cascade_talent) and target.Distance() <= 40 and Speed() > 0 and Spell(cascade_caster) or Speed() > 0 and Spell(devouring_plague)
}

### actions.cop_dotweave

AddFunction ShadowCopDotweaveMainActions
{
	#devouring_plague,if=target.dot.vampiric_touch.ticking&target.dot.shadow_word_pain.ticking&shadow_orb=5&cooldown_react
	if target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and ShadowOrbs() == 5 and not SpellCooldown(devouring_plague) > 0 Spell(devouring_plague)
	#devouring_plague,if=buff.mental_instinct.remains<gcd&buff.mental_instinct.remains>(gcd*0.7)&buff.mental_instinct.remains
	if BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) Spell(devouring_plague)
	#devouring_plague,if=(target.dot.vampiric_touch.ticking&target.dot.shadow_word_pain.ticking&!buff.shadow_word_insanity.remains&cooldown.mind_blast.remains>0.4*gcd)
	if target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and not BuffPresent(shadow_word_insanity_buff) and SpellCooldown(mind_blast) > 0.4 * GCD() Spell(devouring_plague)
	#shadow_word_death,if=natural_shadow_word_death_range&!target.dot.shadow_word_pain.ticking&!target.dot.vampiric_touch.ticking,cycle_targets=1
	if target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) Spell(shadow_word_death)
	#shadow_word_death,if=natural_shadow_word_death_range,cycle_targets=1
	if target.HealthPercent() < 20 Spell(shadow_word_death)
	#mind_blast,if=glyph.mind_harvest.enabled&mind_harvest=0&shadow_orb<=2,cycle_targets=1
	if Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 Spell(mind_blast)
	#mind_blast,if=shadow_orb<=4&cooldown_react
	if ShadowOrbs() <= 4 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#searing_insanity,if=buff.shadow_word_insanity.remains<0.5*gcd&active_enemies>=3&cooldown.mind_blast.remains>0.5*gcd,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(searing_insanity)
	#searing_insanity,if=active_enemies>=3&cooldown.mind_blast.remains>0.5*gcd,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(searing_insanity)
	#shadow_word_pain,if=shadow_orb=4&set_bonus.tier17_2pc&!target.dot.shadow_word_pain.ticking&!target.dot.devouring_plague.ticking&cooldown.mind_blast.remains<gcd&cooldown.mind_blast.remains>0
	if ShadowOrbs() == 4 and ArmorSetBonus(T17 2) and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(devouring_plague_debuff) and SpellCooldown(mind_blast) < GCD() and SpellCooldown(mind_blast) > 0 Spell(shadow_word_pain)
	#shadow_word_pain,if=shadow_orb=5&!target.dot.devouring_plague.ticking&!target.dot.shadow_word_pain.ticking
	if ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_debuff) and not target.DebuffPresent(shadow_word_pain_debuff) Spell(shadow_word_pain)
	#vampiric_touch,if=shadow_orb=5&!target.dot.devouring_plague.ticking&!target.dot.vampiric_touch.ticking
	if ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_debuff) and not target.DebuffPresent(vampiric_touch_debuff) Spell(vampiric_touch)
	#insanity,if=buff.shadow_word_insanity.remains,chain=1,interrupt_if=cooldown.mind_blast.remains<=0.1
	if BuffPresent(shadow_word_insanity_buff) Spell(insanity)
	#shadow_word_pain,if=shadow_orb>=2&target.dot.shadow_word_pain.remains>=6&cooldown.mind_blast.remains>0.5*gcd&target.dot.vampiric_touch.remains&buff.bloodlust.up&!set_bonus.tier17_2pc
	if ShadowOrbs() >= 2 and target.DebuffRemaining(shadow_word_pain_debuff) >= 6 and SpellCooldown(mind_blast) > 0.5 * GCD() and target.DebuffRemaining(vampiric_touch_debuff) and BuffPresent(burst_haste_buff any=1) and not ArmorSetBonus(T17 2) Spell(shadow_word_pain)
	#vampiric_touch,if=shadow_orb>=2&target.dot.vampiric_touch.remains>=5&cooldown.mind_blast.remains>0.5*gcd&buff.bloodlust.up&!set_bonus.tier17_2pc
	if ShadowOrbs() >= 2 and target.DebuffRemaining(vampiric_touch_debuff) >= 5 and SpellCooldown(mind_blast) > 0.5 * GCD() and BuffPresent(burst_haste_buff any=1) and not ArmorSetBonus(T17 2) Spell(vampiric_touch)
	#shadow_word_pain,if=primary_target=0&!ticking,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and 1 == 0 and not target.DebuffPresent(shadow_word_pain_debuff) Spell(shadow_word_pain)
	#vampiric_touch,if=primary_target=0&!ticking,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and 1 == 0 and not target.DebuffPresent(vampiric_touch_debuff) Spell(vampiric_touch)
	#shadow_word_pain,if=primary_target=0&(!ticking|remains<=18*0.3)&target.time_to_die>(18*0.75),cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and 1 == 0 and { not target.DebuffPresent(shadow_word_pain_debuff) or target.DebuffRemaining(shadow_word_pain_debuff) <= 18 * 0.3 } and target.TimeToDie() > 18 * 0.75 Spell(shadow_word_pain)
	#vampiric_touch,if=primary_target=0&(!ticking|remains<=15*0.3+cast_time)&target.time_to_die>(15*0.75+cast_time),cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and 1 == 0 and { not target.DebuffPresent(vampiric_touch_debuff) or target.DebuffRemaining(vampiric_touch_debuff) <= 15 * 0.3 + CastTime(vampiric_touch) } and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) Spell(vampiric_touch)
	#mind_sear,if=active_enemies>=8,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() >= 8 Spell(mind_sear)
	#mind_spike
	Spell(mind_spike)
	#shadow_word_death,moving=1,if=!target.dot.shadow_word_pain.ticking&!target.dot.vampiric_touch.ticking,cycle_targets=1
	if Speed() > 0 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) Spell(shadow_word_death)
	#shadow_word_death,moving=1,if=movement.remains>=1*gcd
	if Speed() > 0 and 0 >= 1 * GCD() Spell(shadow_word_death)
	#power_word_shield,moving=1,if=talent.body_and_soul.enabled&movement.distance>=25
	if Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 Spell(power_word_shield)
	#devouring_plague,moving=1
	if Speed() > 0 Spell(devouring_plague)
	#shadow_word_pain,if=primary_target=0,moving=1,cycle_targets=1
	if Speed() > 0 and 1 == 0 Spell(shadow_word_pain)
}

AddFunction ShadowCopDotweaveShortCdActions
{
	unless target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and ShadowOrbs() == 5 and not SpellCooldown(devouring_plague) > 0 and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and not BuffPresent(shadow_word_insanity_buff) and SpellCooldown(mind_blast) > 0.4 * GCD() and Spell(devouring_plague) or target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or target.HealthPercent() < 20 and Spell(shadow_word_death) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 and Spell(mind_blast) or ShadowOrbs() <= 4 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or ShadowOrbs() == 4 and ArmorSetBonus(T17 2) and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(devouring_plague_debuff) and SpellCooldown(mind_blast) < GCD() and SpellCooldown(mind_blast) > 0 and Spell(shadow_word_pain) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_debuff) and not target.DebuffPresent(shadow_word_pain_debuff) and Spell(shadow_word_pain) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(vampiric_touch) or BuffPresent(shadow_word_insanity_buff) and Spell(insanity) or ShadowOrbs() >= 2 and target.DebuffRemaining(shadow_word_pain_debuff) >= 6 and SpellCooldown(mind_blast) > 0.5 * GCD() and target.DebuffRemaining(vampiric_touch_debuff) and BuffPresent(burst_haste_buff any=1) and not ArmorSetBonus(T17 2) and Spell(shadow_word_pain) or ShadowOrbs() >= 2 and target.DebuffRemaining(vampiric_touch_debuff) >= 5 and SpellCooldown(mind_blast) > 0.5 * GCD() and BuffPresent(burst_haste_buff any=1) and not ArmorSetBonus(T17 2) and Spell(vampiric_touch)
	{
		#halo,if=cooldown.mind_blast.remains>0.5*gcd&talent.halo.enabled&target.distance<=30&target.distance>=17
		if SpellCooldown(mind_blast) > 0.5 * GCD() and Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo_caster)
		#cascade,if=cooldown.mind_blast.remains>0.5*gcd&talent.cascade.enabled&((active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11)
		if SpellCooldown(mind_blast) > 0.5 * GCD() and Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade_caster)
		#divine_star,if=talent.divine_star.enabled&cooldown.mind_blast.remains>0.5*gcd&active_enemies>3&target.distance<=24
		if Talent(divine_star_talent) and SpellCooldown(mind_blast) > 0.5 * GCD() and Enemies() > 3 and target.Distance() <= 24 Spell(divine_star_caster)

		unless DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and 1 == 0 and not target.DebuffPresent(shadow_word_pain_debuff) and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and 1 == 0 and not target.DebuffPresent(vampiric_touch_debuff) and Spell(vampiric_touch)
		{
			#divine_star,if=talent.divine_star.enabled&cooldown.mind_blast.remains>0.5*gcd&active_enemies=3&target.distance<=24
			if Talent(divine_star_talent) and SpellCooldown(mind_blast) > 0.5 * GCD() and Enemies() == 3 and target.Distance() <= 24 Spell(divine_star_caster)

			unless DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and 1 == 0 and { not target.DebuffPresent(shadow_word_pain_debuff) or target.DebuffRemaining(shadow_word_pain_debuff) <= 18 * 0.3 } and target.TimeToDie() > 18 * 0.75 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and 1 == 0 and { not target.DebuffPresent(vampiric_touch_debuff) or target.DebuffRemaining(vampiric_touch_debuff) <= 15 * 0.3 + CastTime(vampiric_touch) } and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and Spell(vampiric_touch) or Enemies() >= 8 and Spell(mind_sear) or Spell(mind_spike) or Speed() > 0 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield)
			{
				#halo,if=talent.halo.enabled&target.distance<=30,moving=1
				if Talent(halo_talent) and target.Distance() <= 30 and Speed() > 0 Spell(halo_caster)
				#divine_star,if=talent.divine_star.enabled&target.distance<=28,moving=1
				if Talent(divine_star_talent) and target.Distance() <= 28 and Speed() > 0 Spell(divine_star_caster)
				#cascade,if=talent.cascade.enabled&target.distance<=40,moving=1
				if Talent(cascade_talent) and target.Distance() <= 40 and Speed() > 0 Spell(cascade_caster)
			}
		}
	}
}

AddFunction ShadowCopDotweaveShortCdPostConditions
{
	target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and ShadowOrbs() == 5 and not SpellCooldown(devouring_plague) > 0 and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and not BuffPresent(shadow_word_insanity_buff) and SpellCooldown(mind_blast) > 0.4 * GCD() and Spell(devouring_plague) or target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or target.HealthPercent() < 20 and Spell(shadow_word_death) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 and Spell(mind_blast) or ShadowOrbs() <= 4 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or ShadowOrbs() == 4 and ArmorSetBonus(T17 2) and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(devouring_plague_debuff) and SpellCooldown(mind_blast) < GCD() and SpellCooldown(mind_blast) > 0 and Spell(shadow_word_pain) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_debuff) and not target.DebuffPresent(shadow_word_pain_debuff) and Spell(shadow_word_pain) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(vampiric_touch) or BuffPresent(shadow_word_insanity_buff) and Spell(insanity) or ShadowOrbs() >= 2 and target.DebuffRemaining(shadow_word_pain_debuff) >= 6 and SpellCooldown(mind_blast) > 0.5 * GCD() and target.DebuffRemaining(vampiric_touch_debuff) and BuffPresent(burst_haste_buff any=1) and not ArmorSetBonus(T17 2) and Spell(shadow_word_pain) or ShadowOrbs() >= 2 and target.DebuffRemaining(vampiric_touch_debuff) >= 5 and SpellCooldown(mind_blast) > 0.5 * GCD() and BuffPresent(burst_haste_buff any=1) and not ArmorSetBonus(T17 2) and Spell(vampiric_touch) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and 1 == 0 and not target.DebuffPresent(shadow_word_pain_debuff) and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and 1 == 0 and not target.DebuffPresent(vampiric_touch_debuff) and Spell(vampiric_touch) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and 1 == 0 and { not target.DebuffPresent(shadow_word_pain_debuff) or target.DebuffRemaining(shadow_word_pain_debuff) <= 18 * 0.3 } and target.TimeToDie() > 18 * 0.75 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and 1 == 0 and { not target.DebuffPresent(vampiric_touch_debuff) or target.DebuffRemaining(vampiric_touch_debuff) <= 15 * 0.3 + CastTime(vampiric_touch) } and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and Spell(vampiric_touch) or Enemies() >= 8 and Spell(mind_sear) or Spell(mind_spike) or Speed() > 0 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield) or Speed() > 0 and Spell(devouring_plague) or Speed() > 0 and 1 == 0 and Spell(shadow_word_pain)
}

AddFunction ShadowCopDotweaveCdActions
{
	unless target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and ShadowOrbs() == 5 and not SpellCooldown(devouring_plague) > 0 and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and not BuffPresent(shadow_word_insanity_buff) and SpellCooldown(mind_blast) > 0.4 * GCD() and Spell(devouring_plague) or target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or target.HealthPercent() < 20 and Spell(shadow_word_death) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 and Spell(mind_blast) or ShadowOrbs() <= 4 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity)
	{
		#shadowfiend,if=!talent.mindbender.enabled&!buff.shadow_word_insanity.remains
		if not Talent(mindbender_talent) and not BuffPresent(shadow_word_insanity_buff) Spell(shadowfiend)
		#mindbender,if=talent.mindbender.enabled&!buff.shadow_word_insanity.remains
		if Talent(mindbender_talent) and not BuffPresent(shadow_word_insanity_buff) Spell(mindbender)
	}
}

AddFunction ShadowCopDotweaveCdPostConditions
{
	target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and ShadowOrbs() == 5 and not SpellCooldown(devouring_plague) > 0 and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and not BuffPresent(shadow_word_insanity_buff) and SpellCooldown(mind_blast) > 0.4 * GCD() and Spell(devouring_plague) or target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or target.HealthPercent() < 20 and Spell(shadow_word_death) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 and Spell(mind_blast) or ShadowOrbs() <= 4 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or ShadowOrbs() == 4 and ArmorSetBonus(T17 2) and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(devouring_plague_debuff) and SpellCooldown(mind_blast) < GCD() and SpellCooldown(mind_blast) > 0 and Spell(shadow_word_pain) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_debuff) and not target.DebuffPresent(shadow_word_pain_debuff) and Spell(shadow_word_pain) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(vampiric_touch) or BuffPresent(shadow_word_insanity_buff) and Spell(insanity) or ShadowOrbs() >= 2 and target.DebuffRemaining(shadow_word_pain_debuff) >= 6 and SpellCooldown(mind_blast) > 0.5 * GCD() and target.DebuffRemaining(vampiric_touch_debuff) and BuffPresent(burst_haste_buff any=1) and not ArmorSetBonus(T17 2) and Spell(shadow_word_pain) or ShadowOrbs() >= 2 and target.DebuffRemaining(vampiric_touch_debuff) >= 5 and SpellCooldown(mind_blast) > 0.5 * GCD() and BuffPresent(burst_haste_buff any=1) and not ArmorSetBonus(T17 2) and Spell(vampiric_touch) or SpellCooldown(mind_blast) > 0.5 * GCD() and Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 and Spell(halo_caster) or SpellCooldown(mind_blast) > 0.5 * GCD() and Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 and Spell(cascade_caster) or Talent(divine_star_talent) and SpellCooldown(mind_blast) > 0.5 * GCD() and Enemies() > 3 and target.Distance() <= 24 and Spell(divine_star_caster) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and 1 == 0 and not target.DebuffPresent(shadow_word_pain_debuff) and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and 1 == 0 and not target.DebuffPresent(vampiric_touch_debuff) and Spell(vampiric_touch) or Talent(divine_star_talent) and SpellCooldown(mind_blast) > 0.5 * GCD() and Enemies() == 3 and target.Distance() <= 24 and Spell(divine_star_caster) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and 1 == 0 and { not target.DebuffPresent(shadow_word_pain_debuff) or target.DebuffRemaining(shadow_word_pain_debuff) <= 18 * 0.3 } and target.TimeToDie() > 18 * 0.75 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and 1 == 0 and { not target.DebuffPresent(vampiric_touch_debuff) or target.DebuffRemaining(vampiric_touch_debuff) <= 15 * 0.3 + CastTime(vampiric_touch) } and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and Spell(vampiric_touch) or Enemies() >= 8 and Spell(mind_sear) or Spell(mind_spike) or Speed() > 0 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield) or Talent(halo_talent) and target.Distance() <= 30 and Speed() > 0 and Spell(halo_caster) or Talent(divine_star_talent) and target.Distance() <= 28 and Speed() > 0 and Spell(divine_star_caster) or Talent(cascade_talent) and target.Distance() <= 40 and Speed() > 0 and Spell(cascade_caster) or Speed() > 0 and Spell(devouring_plague) or Speed() > 0 and 1 == 0 and Spell(shadow_word_pain)
}

### actions.cop_mfi

AddFunction ShadowCopMfiMainActions
{
	#devouring_plague,if=shadow_orb=5
	if ShadowOrbs() == 5 Spell(devouring_plague)
	#devouring_plague,if=buff.mental_instinct.remains<(gcd*1.7)&buff.mental_instinct.remains>(gcd*0.7)&buff.mental_instinct.remains
	if BuffRemaining(mental_instinct_buff) < GCD() * 1.7 and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) Spell(devouring_plague)
	#mind_blast,if=glyph.mind_harvest.enabled&mind_harvest=0,cycle_targets=1
	if Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 Spell(mind_blast)
	#mind_blast,if=active_enemies<=5&cooldown_react
	if Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#shadow_word_death,if=natural_shadow_word_death_range&!target.dot.shadow_word_pain.ticking&!target.dot.vampiric_touch.ticking,cycle_targets=1
	if target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) Spell(shadow_word_death)
	#shadow_word_death,if=natural_shadow_word_death_range,cycle_targets=1
	if target.HealthPercent() < 20 Spell(shadow_word_death)
	#devouring_plague,if=shadow_orb>=3&!set_bonus.tier17_2pc&!set_bonus.tier17_4pc&(cooldown.mind_blast.remains<gcd|(natural_shadow_word_death_range&cooldown.shadow_word_death.remains<gcd)),cycle_targets=1
	if ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) < GCD() or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&set_bonus.tier17_2pc&!set_bonus.tier17_4pc&(cooldown.mind_blast.remains<=2|(natural_shadow_word_death_range&cooldown.shadow_word_death.remains<gcd)),cycle_targets=1
	if ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } Spell(devouring_plague)
	#searing_insanity,if=buff.shadow_word_insanity.remains<0.5*gcd&active_enemies>=3&cooldown.mind_blast.remains>0.5*gcd,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(searing_insanity)
	#searing_insanity,if=active_enemies>=3&cooldown.mind_blast.remains>0.5*gcd,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(searing_insanity)
	#shadow_word_pain,if=remains<(18*0.3)&target.time_to_die>(18*0.75)&miss_react&active_enemies<=5&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Enemies() <= 5 and 1 == 0 Spell(shadow_word_pain)
	#vampiric_touch,if=remains<(15*0.3+cast_time)&target.time_to_die>(15*0.75+cast_time)&miss_react&active_enemies<=5&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and 1 == 0 Spell(vampiric_touch)
	#insanity,if=buff.shadow_word_insanity.remains<0.5*gcd&active_enemies<=2,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|(cooldown.shadow_word_death.remains<=0.1&target.health.pct<20))
	if BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 Spell(insanity)
	#insanity,if=active_enemies<=2,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|(cooldown.shadow_word_death.remains<=0.1&target.health.pct<20))
	if Enemies() <= 2 Spell(insanity)
	#mind_sear,if=active_enemies>=8,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() >= 8 Spell(mind_sear)
	#mind_spike
	Spell(mind_spike)
	#shadow_word_death,moving=1,if=!target.dot.shadow_word_pain.ticking&!target.dot.vampiric_touch.ticking,cycle_targets=1
	if Speed() > 0 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) Spell(shadow_word_death)
	#shadow_word_death,moving=1,if=movement.remains>=1*gcd
	if Speed() > 0 and 0 >= 1 * GCD() Spell(shadow_word_death)
	#power_word_shield,moving=1,if=talent.body_and_soul.enabled&movement.distance>=25
	if Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 Spell(power_word_shield)
	#devouring_plague,moving=1
	if Speed() > 0 Spell(devouring_plague)
	#shadow_word_pain,if=primary_target=0,moving=1,cycle_targets=1
	if Speed() > 0 and 1 == 0 Spell(shadow_word_pain)
}

AddFunction ShadowCopMfiShortCdActions
{
	unless ShadowOrbs() == 5 and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() * 1.7 and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and Spell(mind_blast) or Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or target.HealthPercent() < 20 and Spell(shadow_word_death) or ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) < GCD() or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Enemies() <= 5 and 1 == 0 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and 1 == 0 and Spell(vampiric_touch) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 and Spell(insanity) or Enemies() <= 2 and Spell(insanity)
	{
		#halo,if=talent.halo.enabled&target.distance<=30&target.distance>=17
		if Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo_caster)
		#cascade,if=talent.cascade.enabled&((active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11)
		if Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade_caster)
		#divine_star,if=talent.divine_star.enabled&active_enemies>2&target.distance<=24
		if Talent(divine_star_talent) and Enemies() > 2 and target.Distance() <= 24 Spell(divine_star_caster)

		unless Enemies() >= 8 and Spell(mind_sear) or Spell(mind_spike) or Speed() > 0 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield)
		{
			#halo,if=talent.halo.enabled&target.distance<=30,moving=1
			if Talent(halo_talent) and target.Distance() <= 30 and Speed() > 0 Spell(halo_caster)
			#divine_star,if=talent.divine_star.enabled&target.distance<=28,moving=1
			if Talent(divine_star_talent) and target.Distance() <= 28 and Speed() > 0 Spell(divine_star_caster)
			#cascade,if=talent.cascade.enabled&target.distance<=40,moving=1
			if Talent(cascade_talent) and target.Distance() <= 40 and Speed() > 0 Spell(cascade_caster)
		}
	}
}

AddFunction ShadowCopMfiShortCdPostConditions
{
	ShadowOrbs() == 5 and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() * 1.7 and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and Spell(mind_blast) or Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or target.HealthPercent() < 20 and Spell(shadow_word_death) or ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) < GCD() or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Enemies() <= 5 and 1 == 0 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and 1 == 0 and Spell(vampiric_touch) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 and Spell(insanity) or Enemies() <= 2 and Spell(insanity) or Enemies() >= 8 and Spell(mind_sear) or Spell(mind_spike) or Speed() > 0 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield) or Speed() > 0 and Spell(devouring_plague) or Speed() > 0 and 1 == 0 and Spell(shadow_word_pain)
}

AddFunction ShadowCopMfiCdActions
{
	unless ShadowOrbs() == 5 and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() * 1.7 and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and Spell(mind_blast) or Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or target.HealthPercent() < 20 and Spell(shadow_word_death) or ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) < GCD() or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity)
	{
		#mindbender,if=talent.mindbender.enabled
		if Talent(mindbender_talent) Spell(mindbender)
		#shadowfiend,if=!talent.mindbender.enabled
		if not Talent(mindbender_talent) Spell(shadowfiend)
	}
}

AddFunction ShadowCopMfiCdPostConditions
{
	ShadowOrbs() == 5 and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() * 1.7 and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and Spell(mind_blast) or Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or target.HealthPercent() < 20 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or target.HealthPercent() < 20 and Spell(shadow_word_death) or ShadowOrbs() >= 3 and not ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) < GCD() or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) and not ArmorSetBonus(T17 4) and { SpellCooldown(mind_blast) <= 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Enemies() <= 5 and 1 == 0 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and 1 == 0 and Spell(vampiric_touch) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 and Spell(insanity) or Enemies() <= 2 and Spell(insanity) or Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 and Spell(halo_caster) or Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 and Spell(cascade_caster) or Talent(divine_star_talent) and Enemies() > 2 and target.Distance() <= 24 and Spell(divine_star_caster) or Enemies() >= 8 and Spell(mind_sear) or Spell(mind_spike) or Speed() > 0 and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(shadow_word_death) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield) or Talent(halo_talent) and target.Distance() <= 30 and Speed() > 0 and Spell(halo_caster) or Talent(divine_star_talent) and target.Distance() <= 28 and Speed() > 0 and Spell(divine_star_caster) or Talent(cascade_talent) and target.Distance() <= 40 and Speed() > 0 and Spell(cascade_caster) or Speed() > 0 and Spell(devouring_plague) or Speed() > 0 and 1 == 0 and Spell(shadow_word_pain)
}

### actions.decision

AddFunction ShadowDecisionMainActions
{
	#call_action_list,name=main,if=!talent.clarity_of_power.enabled&!talent.void_entropy.enabled
	if not Talent(clarity_of_power_talent) and not Talent(void_entropy_talent) ShadowMainMainActions()
	#call_action_list,name=vent,if=talent.void_entropy.enabled&!talent.clarity_of_power.enabled&!talent.auspicious_spirits.enabled
	if Talent(void_entropy_talent) and not Talent(clarity_of_power_talent) and not Talent(auspicious_spirits_talent) ShadowVentMainActions()
	#call_action_list,name=cop,if=talent.clarity_of_power.enabled&!talent.insanity.enabled
	if Talent(clarity_of_power_talent) and not Talent(insanity_talent) ShadowCopMainActions()
	#call_action_list,name=cop_dotweave,if=talent.clarity_of_power.enabled&talent.insanity.enabled&target.health.pct>20&active_enemies<=5
	if Talent(clarity_of_power_talent) and Talent(insanity_talent) and target.HealthPercent() > 20 and Enemies() <= 5 ShadowCopDotweaveMainActions()
	#call_action_list,name=cop_mfi,if=talent.clarity_of_power.enabled&talent.insanity.enabled
	if Talent(clarity_of_power_talent) and Talent(insanity_talent) ShadowCopMfiMainActions()
}

AddFunction ShadowDecisionShortCdActions
{
	#call_action_list,name=main,if=!talent.clarity_of_power.enabled&!talent.void_entropy.enabled
	if not Talent(clarity_of_power_talent) and not Talent(void_entropy_talent) ShadowMainShortCdActions()

	unless not Talent(clarity_of_power_talent) and not Talent(void_entropy_talent) and ShadowMainShortCdPostConditions()
	{
		#call_action_list,name=vent,if=talent.void_entropy.enabled&!talent.clarity_of_power.enabled&!talent.auspicious_spirits.enabled
		if Talent(void_entropy_talent) and not Talent(clarity_of_power_talent) and not Talent(auspicious_spirits_talent) ShadowVentShortCdActions()

		unless Talent(void_entropy_talent) and not Talent(clarity_of_power_talent) and not Talent(auspicious_spirits_talent) and ShadowVentShortCdPostConditions()
		{
			#call_action_list,name=cop,if=talent.clarity_of_power.enabled&!talent.insanity.enabled
			if Talent(clarity_of_power_talent) and not Talent(insanity_talent) ShadowCopShortCdActions()

			unless Talent(clarity_of_power_talent) and not Talent(insanity_talent) and ShadowCopShortCdPostConditions()
			{
				#call_action_list,name=cop_dotweave,if=talent.clarity_of_power.enabled&talent.insanity.enabled&target.health.pct>20&active_enemies<=5
				if Talent(clarity_of_power_talent) and Talent(insanity_talent) and target.HealthPercent() > 20 and Enemies() <= 5 ShadowCopDotweaveShortCdActions()

				unless Talent(clarity_of_power_talent) and Talent(insanity_talent) and target.HealthPercent() > 20 and Enemies() <= 5 and ShadowCopDotweaveShortCdPostConditions()
				{
					#call_action_list,name=cop_mfi,if=talent.clarity_of_power.enabled&talent.insanity.enabled
					if Talent(clarity_of_power_talent) and Talent(insanity_talent) ShadowCopMfiShortCdActions()
				}
			}
		}
	}
}

AddFunction ShadowDecisionShortCdPostConditions
{
	not Talent(clarity_of_power_talent) and not Talent(void_entropy_talent) and ShadowMainShortCdPostConditions() or Talent(void_entropy_talent) and not Talent(clarity_of_power_talent) and not Talent(auspicious_spirits_talent) and ShadowVentShortCdPostConditions() or Talent(clarity_of_power_talent) and not Talent(insanity_talent) and ShadowCopShortCdPostConditions() or Talent(clarity_of_power_talent) and Talent(insanity_talent) and target.HealthPercent() > 20 and Enemies() <= 5 and ShadowCopDotweaveShortCdPostConditions() or Talent(clarity_of_power_talent) and Talent(insanity_talent) and ShadowCopMfiShortCdPostConditions()
}

AddFunction ShadowDecisionCdActions
{
	#call_action_list,name=main,if=!talent.clarity_of_power.enabled&!talent.void_entropy.enabled
	if not Talent(clarity_of_power_talent) and not Talent(void_entropy_talent) ShadowMainCdActions()

	unless not Talent(clarity_of_power_talent) and not Talent(void_entropy_talent) and ShadowMainCdPostConditions()
	{
		#call_action_list,name=vent,if=talent.void_entropy.enabled&!talent.clarity_of_power.enabled&!talent.auspicious_spirits.enabled
		if Talent(void_entropy_talent) and not Talent(clarity_of_power_talent) and not Talent(auspicious_spirits_talent) ShadowVentCdActions()

		unless Talent(void_entropy_talent) and not Talent(clarity_of_power_talent) and not Talent(auspicious_spirits_talent) and ShadowVentCdPostConditions()
		{
			#call_action_list,name=cop,if=talent.clarity_of_power.enabled&!talent.insanity.enabled
			if Talent(clarity_of_power_talent) and not Talent(insanity_talent) ShadowCopCdActions()

			unless Talent(clarity_of_power_talent) and not Talent(insanity_talent) and ShadowCopCdPostConditions()
			{
				#call_action_list,name=cop_dotweave,if=talent.clarity_of_power.enabled&talent.insanity.enabled&target.health.pct>20&active_enemies<=5
				if Talent(clarity_of_power_talent) and Talent(insanity_talent) and target.HealthPercent() > 20 and Enemies() <= 5 ShadowCopDotweaveCdActions()

				unless Talent(clarity_of_power_talent) and Talent(insanity_talent) and target.HealthPercent() > 20 and Enemies() <= 5 and ShadowCopDotweaveCdPostConditions()
				{
					#call_action_list,name=cop_mfi,if=talent.clarity_of_power.enabled&talent.insanity.enabled
					if Talent(clarity_of_power_talent) and Talent(insanity_talent) ShadowCopMfiCdActions()
				}
			}
		}
	}
}

AddFunction ShadowDecisionCdPostConditions
{
	not Talent(clarity_of_power_talent) and not Talent(void_entropy_talent) and ShadowMainCdPostConditions() or Talent(void_entropy_talent) and not Talent(clarity_of_power_talent) and not Talent(auspicious_spirits_talent) and ShadowVentCdPostConditions() or Talent(clarity_of_power_talent) and not Talent(insanity_talent) and ShadowCopCdPostConditions() or Talent(clarity_of_power_talent) and Talent(insanity_talent) and target.HealthPercent() > 20 and Enemies() <= 5 and ShadowCopDotweaveCdPostConditions() or Talent(clarity_of_power_talent) and Talent(insanity_talent) and ShadowCopMfiCdPostConditions()
}

### actions.main

AddFunction ShadowMainMainActions
{
	#shadow_word_death,if=natural_shadow_word_death_range&shadow_orb<=4,cycle_targets=1
	if target.HealthPercent() < 20 and ShadowOrbs() <= 4 Spell(shadow_word_death)
	#mind_blast,if=glyph.mind_harvest.enabled&shadow_orb<=2&active_enemies<=5&cooldown_react
	if Glyph(glyph_of_mind_harvest) and ShadowOrbs() <= 2 and Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#devouring_plague,if=shadow_orb=5&!target.dot.devouring_plague_dot.ticking&(talent.surge_of_darkness.enabled|set_bonus.tier17_4pc),cycle_targets=1
	if ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_dot_debuff) and { Talent(surge_of_darkness_talent) or ArmorSetBonus(T17 4) } Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5
	if ShadowOrbs() == 5 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&talent.auspicious_spirits.enabled&shadowy_apparitions_in_flight>=3
	if ShadowOrbs() >= 3 and Talent(auspicious_spirits_talent) and 1 >= 3 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=4&talent.auspicious_spirits.enabled&shadowy_apparitions_in_flight>=2
	if ShadowOrbs() >= 4 and Talent(auspicious_spirits_talent) and 1 >= 2 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&buff.mental_instinct.remains<gcd&buff.mental_instinct.remains>(gcd*0.7)&buff.mental_instinct.remains
	if ShadowOrbs() >= 3 and BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=4&talent.auspicious_spirits.enabled&((cooldown.mind_blast.remains<gcd&!set_bonus.tier17_2pc)|(natural_shadow_word_death_range&cooldown.shadow_word_death.remains<gcd))&!target.dot.devouring_plague_tick.ticking&talent.surge_of_darkness.enabled,cycle_targets=1
	if ShadowOrbs() >= 4 and Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and not target.DebuffPresent(devouring_plague_debuff) and Talent(surge_of_darkness_talent) Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=4&talent.auspicious_spirits.enabled&((cooldown.mind_blast.remains<gcd&!set_bonus.tier17_2pc)|(target.health.pct<20&cooldown.shadow_word_death.remains<gcd))
	if ShadowOrbs() >= 4 and Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&!talent.auspicious_spirits.enabled&((cooldown.mind_blast.remains<gcd&!set_bonus.tier17_2pc)|(natural_shadow_word_death_range&cooldown.shadow_word_death.remains<gcd))&!target.dot.devouring_plague_tick.ticking&talent.surge_of_darkness.enabled,cycle_targets=1
	if ShadowOrbs() >= 3 and not Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and not target.DebuffPresent(devouring_plague_debuff) and Talent(surge_of_darkness_talent) Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&!talent.auspicious_spirits.enabled&((cooldown.mind_blast.remains<gcd&!set_bonus.tier17_2pc)|(target.health.pct<20&cooldown.shadow_word_death.remains<gcd))
	if ShadowOrbs() >= 3 and not Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } Spell(devouring_plague)
	#mind_blast,if=glyph.mind_harvest.enabled&mind_harvest=0,cycle_targets=1
	if Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 Spell(mind_blast)
	#mind_blast,if=talent.auspicious_spirits.enabled&active_enemies<=4&cooldown_react
	if Talent(auspicious_spirits_talent) and Enemies() <= 4 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#shadow_word_pain,if=talent.auspicious_spirits.enabled&remains<(18*0.3)&target.time_to_die>(18*0.75)&miss_react,cycle_targets=1,max_cycle_targets=7
	if DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 7 and Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) Spell(shadow_word_pain)
	#mind_blast,if=cooldown_react
	if not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#searing_insanity,if=buff.shadow_word_insanity.remains<0.5*gcd&active_enemies>=3&cooldown.mind_blast.remains>0.5*gcd,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(searing_insanity)
	#searing_insanity,if=active_enemies>=3&cooldown.mind_blast.remains>0.5*gcd,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(searing_insanity)
	#insanity,if=buff.shadow_word_insanity.remains<0.5*gcd&active_enemies<=2,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1|shadow_orb=5)
	if BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 Spell(insanity)
	#insanity,chain=1,if=active_enemies<=2,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1|shadow_orb=5)
	if Enemies() <= 2 Spell(insanity)
	#shadow_word_pain,if=!talent.auspicious_spirits.enabled&remains<(18*0.3)&target.time_to_die>(18*0.75)&miss_react&active_enemies<=5,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and not Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Enemies() <= 5 Spell(shadow_word_pain)
	#vampiric_touch,if=remains<(15*0.3+cast_time)&target.time_to_die>(15*0.75+cast_time)&miss_react&active_enemies<=5,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 Spell(vampiric_touch)
	#devouring_plague,if=!talent.void_entropy.enabled&shadow_orb>=3&ticks_remain<=1
	if not Talent(void_entropy_talent) and ShadowOrbs() >= 3 and target.TicksRemaining(devouring_plague_debuff) < 2 Spell(devouring_plague)
	#mind_spike,if=active_enemies<=5&buff.surge_of_darkness.react=3
	if Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 3 Spell(mind_spike)
	#wait,sec=cooldown.shadow_word_death.remains,if=natural_shadow_word_death_range&cooldown.shadow_word_death.remains<0.5&active_enemies<=1,cycle_targets=1
	unless target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 0.5 and Enemies() <= 1 and SpellCooldown(shadow_word_death) > 0
	{
		#wait,sec=cooldown.mind_blast.remains,if=cooldown.mind_blast.remains<0.5&cooldown.mind_blast.remains&active_enemies<=1
		unless SpellCooldown(mind_blast) < 0.5 and SpellCooldown(mind_blast) > 0 and Enemies() <= 1 and SpellCooldown(mind_blast) > 0
		{
			#mind_spike,if=buff.surge_of_darkness.react&active_enemies<=5
			if BuffPresent(surge_of_darkness_buff) and Enemies() <= 5 Spell(mind_spike)
			#mind_sear,chain=1,if=active_enemies>=4,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1|shadow_orb=5)
			if Enemies() >= 4 Spell(mind_sear)
			#shadow_word_pain,if=shadow_orb>=2&ticks_remain<=3&target.time_to_die>(18*0.75)&talent.insanity.enabled
			if ShadowOrbs() >= 2 and target.TicksRemaining(shadow_word_pain_debuff) < 4 and target.TimeToDie() > 18 * 0.75 and Talent(insanity_talent) Spell(shadow_word_pain)
			#vampiric_touch,if=shadow_orb>=2&ticks_remain<=3.5&target.time_to_die>(15*0.75+cast_time)&talent.insanity.enabled
			if ShadowOrbs() >= 2 and target.TicksRemaining(vampiric_touch_debuff) < 4.5 and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and Talent(insanity_talent) Spell(vampiric_touch)
			#mind_flay,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1|shadow_orb=5)
			Spell(mind_flay)
			#shadow_word_death,moving=1,if=movement.remains>=1*gcd
			if Speed() > 0 and 0 >= 1 * GCD() Spell(shadow_word_death)
			#power_word_shield,moving=1,if=talent.body_and_soul.enabled&movement.distance>=25
			if Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 Spell(power_word_shield)
			#shadow_word_pain,moving=1,cycle_targets=1
			if Speed() > 0 Spell(shadow_word_pain)
		}
	}
}

AddFunction ShadowMainShortCdActions
{
	unless target.HealthPercent() < 20 and ShadowOrbs() <= 4 and Spell(shadow_word_death) or Glyph(glyph_of_mind_harvest) and ShadowOrbs() <= 2 and Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_dot_debuff) and { Talent(surge_of_darkness_talent) or ArmorSetBonus(T17 4) } and Spell(devouring_plague) or ShadowOrbs() == 5 and Spell(devouring_plague) or ShadowOrbs() >= 3 and Talent(auspicious_spirits_talent) and 1 >= 3 and Spell(devouring_plague) or ShadowOrbs() >= 4 and Talent(auspicious_spirits_talent) and 1 >= 2 and Spell(devouring_plague) or ShadowOrbs() >= 3 and BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or ShadowOrbs() >= 4 and Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and not target.DebuffPresent(devouring_plague_debuff) and Talent(surge_of_darkness_talent) and Spell(devouring_plague) or ShadowOrbs() >= 4 and Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or ShadowOrbs() >= 3 and not Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and not target.DebuffPresent(devouring_plague_debuff) and Talent(surge_of_darkness_talent) and Spell(devouring_plague) or ShadowOrbs() >= 3 and not Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and Spell(mind_blast) or Talent(auspicious_spirits_talent) and Enemies() <= 4 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 7 and Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Spell(shadow_word_pain) or not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 and Spell(insanity) or Enemies() <= 2 and Spell(insanity)
	{
		#halo,if=talent.halo.enabled&target.distance<=30&active_enemies>2
		if Talent(halo_talent) and target.Distance() <= 30 and Enemies() > 2 Spell(halo_caster)
		#cascade,if=talent.cascade.enabled&active_enemies>2&target.distance<=40
		if Talent(cascade_talent) and Enemies() > 2 and target.Distance() <= 40 Spell(cascade_caster)
		#divine_star,if=talent.divine_star.enabled&active_enemies>4&target.distance<=24
		if Talent(divine_star_talent) and Enemies() > 4 and target.Distance() <= 24 Spell(divine_star_caster)

		unless DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and not Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Enemies() <= 5 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and Spell(vampiric_touch) or not Talent(void_entropy_talent) and ShadowOrbs() >= 3 and target.TicksRemaining(devouring_plague_debuff) < 2 and Spell(devouring_plague) or Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 3 and Spell(mind_spike)
		{
			#halo,if=talent.halo.enabled&target.distance<=30&target.distance>=17
			if Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo_caster)
			#cascade,if=talent.cascade.enabled&(active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11
			if Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade_caster)
			#divine_star,if=talent.divine_star.enabled&(active_enemies>1&target.distance<=24)
			if Talent(divine_star_talent) and Enemies() > 1 and target.Distance() <= 24 Spell(divine_star_caster)
			#wait,sec=cooldown.shadow_word_death.remains,if=natural_shadow_word_death_range&cooldown.shadow_word_death.remains<0.5&active_enemies<=1,cycle_targets=1
			unless target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 0.5 and Enemies() <= 1 and SpellCooldown(shadow_word_death) > 0
			{
				#wait,sec=cooldown.mind_blast.remains,if=cooldown.mind_blast.remains<0.5&cooldown.mind_blast.remains&active_enemies<=1
				unless SpellCooldown(mind_blast) < 0.5 and SpellCooldown(mind_blast) > 0 and Enemies() <= 1 and SpellCooldown(mind_blast) > 0
				{
					unless BuffPresent(surge_of_darkness_buff) and Enemies() <= 5 and Spell(mind_spike)
					{
						#divine_star,if=talent.divine_star.enabled&target.distance<=28&active_enemies>1
						if Talent(divine_star_talent) and target.Distance() <= 28 and Enemies() > 1 Spell(divine_star_caster)

						unless Enemies() >= 4 and Spell(mind_sear) or ShadowOrbs() >= 2 and target.TicksRemaining(shadow_word_pain_debuff) < 4 and target.TimeToDie() > 18 * 0.75 and Talent(insanity_talent) and Spell(shadow_word_pain) or ShadowOrbs() >= 2 and target.TicksRemaining(vampiric_touch_debuff) < 4.5 and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and Talent(insanity_talent) and Spell(vampiric_touch) or Spell(mind_flay) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield)
						{
							#halo,if=talent.halo.enabled&target.distance<=30,moving=1
							if Talent(halo_talent) and target.Distance() <= 30 and Speed() > 0 Spell(halo_caster)
							#divine_star,moving=1,if=talent.divine_star.enabled&target.distance<=28
							if Speed() > 0 and Talent(divine_star_talent) and target.Distance() <= 28 Spell(divine_star_caster)
							#cascade,moving=1,if=talent.cascade.enabled&target.distance<=40
							if Speed() > 0 and Talent(cascade_talent) and target.Distance() <= 40 Spell(cascade_caster)
						}
					}
				}
			}
		}
	}
}

AddFunction ShadowMainShortCdPostConditions
{
	target.HealthPercent() < 20 and ShadowOrbs() <= 4 and Spell(shadow_word_death) or Glyph(glyph_of_mind_harvest) and ShadowOrbs() <= 2 and Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_dot_debuff) and { Talent(surge_of_darkness_talent) or ArmorSetBonus(T17 4) } and Spell(devouring_plague) or ShadowOrbs() == 5 and Spell(devouring_plague) or ShadowOrbs() >= 3 and Talent(auspicious_spirits_talent) and 1 >= 3 and Spell(devouring_plague) or ShadowOrbs() >= 4 and Talent(auspicious_spirits_talent) and 1 >= 2 and Spell(devouring_plague) or ShadowOrbs() >= 3 and BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or ShadowOrbs() >= 4 and Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and not target.DebuffPresent(devouring_plague_debuff) and Talent(surge_of_darkness_talent) and Spell(devouring_plague) or ShadowOrbs() >= 4 and Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or ShadowOrbs() >= 3 and not Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and not target.DebuffPresent(devouring_plague_debuff) and Talent(surge_of_darkness_talent) and Spell(devouring_plague) or ShadowOrbs() >= 3 and not Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and Spell(mind_blast) or Talent(auspicious_spirits_talent) and Enemies() <= 4 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 7 and Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Spell(shadow_word_pain) or not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 and Spell(insanity) or Enemies() <= 2 and Spell(insanity) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and not Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Enemies() <= 5 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and Spell(vampiric_touch) or not Talent(void_entropy_talent) and ShadowOrbs() >= 3 and target.TicksRemaining(devouring_plague_debuff) < 2 and Spell(devouring_plague) or Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 3 and Spell(mind_spike) or not { target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 0.5 and Enemies() <= 1 and SpellCooldown(shadow_word_death) > 0 } and not { SpellCooldown(mind_blast) < 0.5 and SpellCooldown(mind_blast) > 0 and Enemies() <= 1 and SpellCooldown(mind_blast) > 0 } and { BuffPresent(surge_of_darkness_buff) and Enemies() <= 5 and Spell(mind_spike) or Enemies() >= 4 and Spell(mind_sear) or ShadowOrbs() >= 2 and target.TicksRemaining(shadow_word_pain_debuff) < 4 and target.TimeToDie() > 18 * 0.75 and Talent(insanity_talent) and Spell(shadow_word_pain) or ShadowOrbs() >= 2 and target.TicksRemaining(vampiric_touch_debuff) < 4.5 and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and Talent(insanity_talent) and Spell(vampiric_touch) or Spell(mind_flay) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield) or Speed() > 0 and Spell(shadow_word_pain) }
}

AddFunction ShadowMainCdActions
{
	#mindbender,if=talent.mindbender.enabled
	if Talent(mindbender_talent) Spell(mindbender)
	#shadowfiend,if=!talent.mindbender.enabled
	if not Talent(mindbender_talent) Spell(shadowfiend)
}

AddFunction ShadowMainCdPostConditions
{
	target.HealthPercent() < 20 and ShadowOrbs() <= 4 and Spell(shadow_word_death) or Glyph(glyph_of_mind_harvest) and ShadowOrbs() <= 2 and Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_dot_debuff) and { Talent(surge_of_darkness_talent) or ArmorSetBonus(T17 4) } and Spell(devouring_plague) or ShadowOrbs() == 5 and Spell(devouring_plague) or ShadowOrbs() >= 3 and Talent(auspicious_spirits_talent) and 1 >= 3 and Spell(devouring_plague) or ShadowOrbs() >= 4 and Talent(auspicious_spirits_talent) and 1 >= 2 and Spell(devouring_plague) or ShadowOrbs() >= 3 and BuffRemaining(mental_instinct_buff) < GCD() and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or ShadowOrbs() >= 4 and Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and not target.DebuffPresent(devouring_plague_debuff) and Talent(surge_of_darkness_talent) and Spell(devouring_plague) or ShadowOrbs() >= 4 and Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or ShadowOrbs() >= 3 and not Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and not target.DebuffPresent(devouring_plague_debuff) and Talent(surge_of_darkness_talent) and Spell(devouring_plague) or ShadowOrbs() >= 3 and not Talent(auspicious_spirits_talent) and { SpellCooldown(mind_blast) < GCD() and not ArmorSetBonus(T17 2) or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() } and Spell(devouring_plague) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and Spell(mind_blast) or Talent(auspicious_spirits_talent) and Enemies() <= 4 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 7 and Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Spell(shadow_word_pain) or not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 and Spell(insanity) or Enemies() <= 2 and Spell(insanity) or Talent(halo_talent) and target.Distance() <= 30 and Enemies() > 2 and Spell(halo_caster) or Talent(cascade_talent) and Enemies() > 2 and target.Distance() <= 40 and Spell(cascade_caster) or Talent(divine_star_talent) and Enemies() > 4 and target.Distance() <= 24 and Spell(divine_star_caster) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and not Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Enemies() <= 5 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and Spell(vampiric_touch) or not Talent(void_entropy_talent) and ShadowOrbs() >= 3 and target.TicksRemaining(devouring_plague_debuff) < 2 and Spell(devouring_plague) or Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 3 and Spell(mind_spike) or Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 and Spell(halo_caster) or Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 and Spell(cascade_caster) or Talent(divine_star_talent) and Enemies() > 1 and target.Distance() <= 24 and Spell(divine_star_caster) or not { target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 0.5 and Enemies() <= 1 and SpellCooldown(shadow_word_death) > 0 } and not { SpellCooldown(mind_blast) < 0.5 and SpellCooldown(mind_blast) > 0 and Enemies() <= 1 and SpellCooldown(mind_blast) > 0 } and { BuffPresent(surge_of_darkness_buff) and Enemies() <= 5 and Spell(mind_spike) or Talent(divine_star_talent) and target.Distance() <= 28 and Enemies() > 1 and Spell(divine_star_caster) or Enemies() >= 4 and Spell(mind_sear) or ShadowOrbs() >= 2 and target.TicksRemaining(shadow_word_pain_debuff) < 4 and target.TimeToDie() > 18 * 0.75 and Talent(insanity_talent) and Spell(shadow_word_pain) or ShadowOrbs() >= 2 and target.TicksRemaining(vampiric_touch_debuff) < 4.5 and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and Talent(insanity_talent) and Spell(vampiric_touch) or Spell(mind_flay) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield) or Talent(halo_talent) and target.Distance() <= 30 and Speed() > 0 and Spell(halo_caster) or Speed() > 0 and Talent(divine_star_talent) and target.Distance() <= 28 and Spell(divine_star_caster) or Speed() > 0 and Talent(cascade_talent) and target.Distance() <= 40 and Spell(cascade_caster) or Speed() > 0 and Spell(shadow_word_pain) }
}

### actions.precombat

AddFunction ShadowPrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=blackrock_barbecue,if=talent.auspicious_spirits.enabled
	#food,type=frosty_stew,if=talent.void_entropy.enabled
	#food,type=sleeper_surprise,if=talent.clarity_of_power.enabled
	#power_word_fortitude,if=!aura.stamina.up
	if not BuffPresent(stamina_buff any=1) Spell(power_word_fortitude)
	#shadowform,if=!buff.shadowform.up
	if not BuffPresent(shadowform_buff) Spell(shadowform)
	#mind_spike,if=talent.clarity_of_power.enabled
	if Talent(clarity_of_power_talent) Spell(mind_spike)
	#vampiric_touch,if=!talent.clarity_of_power.enabled
	if not Talent(clarity_of_power_talent) Spell(vampiric_touch)
}

AddFunction ShadowPrecombatShortCdPostConditions
{
	not BuffPresent(stamina_buff any=1) and Spell(power_word_fortitude) or not BuffPresent(shadowform_buff) and Spell(shadowform) or Talent(clarity_of_power_talent) and Spell(mind_spike) or not Talent(clarity_of_power_talent) and Spell(vampiric_touch)
}

AddFunction ShadowPrecombatCdActions
{
	unless not BuffPresent(stamina_buff any=1) and Spell(power_word_fortitude) or not BuffPresent(shadowform_buff) and Spell(shadowform)
	{
		#snapshot_stats
		#potion,name=draenic_intellect
		ShadowUsePotionIntellect()
	}
}

AddFunction ShadowPrecombatCdPostConditions
{
	not BuffPresent(stamina_buff any=1) and Spell(power_word_fortitude) or not BuffPresent(shadowform_buff) and Spell(shadowform) or Talent(clarity_of_power_talent) and Spell(mind_spike) or not Talent(clarity_of_power_talent) and Spell(vampiric_touch)
}

### actions.pvp_dispersion

AddFunction ShadowPvpDispersionMainActions
{
	#call_action_list,name=decision,if=cooldown.dispersion.remains>0
	if SpellCooldown(dispersion) > 0 ShadowDecisionMainActions()
	#call_action_list,name=decision
	ShadowDecisionMainActions()
}

AddFunction ShadowPvpDispersionShortCdActions
{
	#call_action_list,name=decision,if=cooldown.dispersion.remains>0
	if SpellCooldown(dispersion) > 0 ShadowDecisionShortCdActions()

	unless SpellCooldown(dispersion) > 0 and ShadowDecisionShortCdPostConditions()
	{
		#call_action_list,name=decision
		ShadowDecisionShortCdActions()
	}
}

AddFunction ShadowPvpDispersionShortCdPostConditions
{
	SpellCooldown(dispersion) > 0 and ShadowDecisionShortCdPostConditions() or ShadowDecisionShortCdPostConditions()
}

AddFunction ShadowPvpDispersionCdActions
{
	#call_action_list,name=decision,if=cooldown.dispersion.remains>0
	if SpellCooldown(dispersion) > 0 ShadowDecisionCdActions()

	unless SpellCooldown(dispersion) > 0 and ShadowDecisionCdPostConditions()
	{
		#dispersion,interrupt=1
		Spell(dispersion)
		#call_action_list,name=decision
		ShadowDecisionCdActions()
	}
}

AddFunction ShadowPvpDispersionCdPostConditions
{
	SpellCooldown(dispersion) > 0 and ShadowDecisionCdPostConditions() or ShadowDecisionCdPostConditions()
}

### actions.vent

AddFunction ShadowVentMainActions
{
	#void_entropy,if=shadow_orb=3&!ticking&target.time_to_die>60&active_enemies=1
	if ShadowOrbs() == 3 and not target.DebuffPresent(void_entropy_debuff) and target.TimeToDie() > 60 and Enemies() == 1 Spell(void_entropy)
	#void_entropy,if=!dot.void_entropy.ticking&shadow_orb=5&active_enemies>=1&target.time_to_die>60,cycle_targets=1,max_cycle_targets=6
	if DebuffCountOnAny(void_entropy_debuff) < Enemies() and DebuffCountOnAny(void_entropy_debuff) <= 6 and not target.DebuffPresent(void_entropy_debuff) and ShadowOrbs() == 5 and Enemies() >= 1 and target.TimeToDie() > 60 Spell(void_entropy)
	#devouring_plague,if=shadow_orb=5&dot.void_entropy.ticking&dot.void_entropy.remains<=gcd*2&cooldown_react&active_enemies=1
	if ShadowOrbs() == 5 and target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) <= GCD() * 2 and not SpellCooldown(devouring_plague) > 0 and Enemies() == 1 Spell(devouring_plague)
	#devouring_plague,if=dot.void_entropy.ticking&dot.void_entropy.remains<=gcd*2&cooldown_react&active_enemies>1,cycle_targets=1
	if target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) <= GCD() * 2 and not SpellCooldown(devouring_plague) > 0 and Enemies() > 1 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5&dot.void_entropy.remains<5&active_enemies>1,cycle_targets=1
	if ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 5 and Enemies() > 1 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5&dot.void_entropy.remains<10&active_enemies>2,cycle_targets=1
	if ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 10 and Enemies() > 2 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5&dot.void_entropy.remains<15&active_enemies>3,cycle_targets=1
	if ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 15 and Enemies() > 3 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5&dot.void_entropy.remains<20&active_enemies>4,cycle_targets=1
	if ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 20 and Enemies() > 4 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5&dot.void_entropy.remains&(cooldown.mind_blast.remains<=gcd*2|(natural_shadow_word_death_range&cooldown.shadow_word_death.remains<=gcd*2))&active_enemies=1
	if ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) and { SpellCooldown(mind_blast) <= GCD() * 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) <= GCD() * 2 } and Enemies() == 1 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5&dot.void_entropy.remains&(cooldown.mind_blast.remains<=gcd*2|(natural_shadow_word_death_range&cooldown.shadow_word_death.remains<=gcd*2))&active_enemies>1,cycle_targets=1
	if ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) and { SpellCooldown(mind_blast) <= GCD() * 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) <= GCD() * 2 } and Enemies() > 1 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&dot.void_entropy.ticking&active_enemies=1&buff.mental_instinct.remains<(gcd*1.4)&buff.mental_instinct.remains>(gcd*0.7)&buff.mental_instinct.remains
	if ShadowOrbs() >= 3 and target.DebuffPresent(void_entropy_debuff) and Enemies() == 1 and BuffRemaining(mental_instinct_buff) < GCD() * 1.4 and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) Spell(devouring_plague)
	#mind_blast,if=glyph.mind_harvest.enabled&mind_harvest=0&shadow_orb<=2,cycle_targets=1
	if Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 Spell(mind_blast)
	#devouring_plague,if=glyph.mind_harvest.enabled&mind_harvest=0&shadow_orb>=3,cycle_targets=1
	if Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() >= 3 Spell(devouring_plague)
	#mind_blast,if=active_enemies<=10&cooldown_react&shadow_orb<=4
	if Enemies() <= 10 and not SpellCooldown(mind_blast) > 0 and ShadowOrbs() <= 4 Spell(mind_blast)
	#shadow_word_death,if=natural_shadow_word_death_range&cooldown_react&shadow_orb<=4,cycle_targets=1
	if target.HealthPercent() < 20 and not SpellCooldown(shadow_word_death) > 0 and ShadowOrbs() <= 4 Spell(shadow_word_death)
	#searing_insanity,if=buff.shadow_word_insanity.remains<0.5*gcd&active_enemies>=3&cooldown.mind_blast.remains>0.5*gcd,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(searing_insanity)
	#searing_insanity,if=active_enemies>=3&cooldown.mind_blast.remains>0.5*gcd,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(searing_insanity)
	#shadow_word_pain,if=shadow_orb=4&remains<(18*0.50)&set_bonus.tier17_2pc&cooldown.mind_blast.remains<1.2*gcd&cooldown.mind_blast.remains>0.2*gcd
	if ShadowOrbs() == 4 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.5 and ArmorSetBonus(T17 2) and SpellCooldown(mind_blast) < 1.2 * GCD() and SpellCooldown(mind_blast) > 0.2 * GCD() Spell(shadow_word_pain)
	#insanity,if=buff.shadow_word_insanity.remains<0.5*gcd&active_enemies<=3&cooldown.mind_blast.remains>0.5*gcd,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(insanity)
	#insanity,chain=1,if=active_enemies<=3&cooldown.mind_blast.remains>0.5*gcd,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() <= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(insanity)
	#mind_spike,if=active_enemies<=5&buff.surge_of_darkness.react=3
	if Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 3 Spell(mind_spike)
	#shadow_word_pain,if=remains<(18*0.3)&target.time_to_die>(18*0.75)&miss_react,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) Spell(shadow_word_pain)
	#vampiric_touch,if=remains<(15*0.3+cast_time)&target.time_to_die>(15*0.75+cast_time)&miss_react,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) Spell(vampiric_touch)
	#mind_spike,if=active_enemies<=5&buff.surge_of_darkness.react&cooldown.mind_blast.remains>0.5*gcd
	if Enemies() <= 5 and BuffPresent(surge_of_darkness_buff) and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(mind_spike)
	#mind_sear,chain=1,if=active_enemies>=3&cooldown.mind_blast.remains>0.5*gcd,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(mind_sear)
	#mind_flay,if=cooldown.mind_blast.remains>0.5*gcd,interrupt=1,chain=1
	if SpellCooldown(mind_blast) > 0.5 * GCD() Spell(mind_flay)
	#shadow_word_death,moving=1,if=movement.remains>=1*gcd
	if Speed() > 0 and 0 >= 1 * GCD() Spell(shadow_word_death)
	#power_word_shield,moving=1,if=talent.body_and_soul.enabled&movement.distance>=25
	if Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 Spell(power_word_shield)
	#shadow_word_pain,moving=1,cycle_targets=1
	if Speed() > 0 Spell(shadow_word_pain)
}

AddFunction ShadowVentShortCdActions
{
	unless ShadowOrbs() == 3 and not target.DebuffPresent(void_entropy_debuff) and target.TimeToDie() > 60 and Enemies() == 1 and Spell(void_entropy) or DebuffCountOnAny(void_entropy_debuff) < Enemies() and DebuffCountOnAny(void_entropy_debuff) <= 6 and not target.DebuffPresent(void_entropy_debuff) and ShadowOrbs() == 5 and Enemies() >= 1 and target.TimeToDie() > 60 and Spell(void_entropy) or ShadowOrbs() == 5 and target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) <= GCD() * 2 and not SpellCooldown(devouring_plague) > 0 and Enemies() == 1 and Spell(devouring_plague) or target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) <= GCD() * 2 and not SpellCooldown(devouring_plague) > 0 and Enemies() > 1 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 5 and Enemies() > 1 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 10 and Enemies() > 2 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 15 and Enemies() > 3 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 20 and Enemies() > 4 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) and { SpellCooldown(mind_blast) <= GCD() * 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) <= GCD() * 2 } and Enemies() == 1 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) and { SpellCooldown(mind_blast) <= GCD() * 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) <= GCD() * 2 } and Enemies() > 1 and Spell(devouring_plague) or ShadowOrbs() >= 3 and target.DebuffPresent(void_entropy_debuff) and Enemies() == 1 and BuffRemaining(mental_instinct_buff) < GCD() * 1.4 and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague)
	{
		#halo,if=talent.halo.enabled&target.distance<=30&active_enemies>=4
		if Talent(halo_talent) and target.Distance() <= 30 and Enemies() >= 4 Spell(halo_caster)

		unless Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 and Spell(mind_blast) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() >= 3 and Spell(devouring_plague) or Enemies() <= 10 and not SpellCooldown(mind_blast) > 0 and ShadowOrbs() <= 4 and Spell(mind_blast) or target.HealthPercent() < 20 and not SpellCooldown(shadow_word_death) > 0 and ShadowOrbs() <= 4 and Spell(shadow_word_death) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or ShadowOrbs() == 4 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.5 and ArmorSetBonus(T17 2) and SpellCooldown(mind_blast) < 1.2 * GCD() and SpellCooldown(mind_blast) > 0.2 * GCD() and Spell(shadow_word_pain) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(insanity) or Enemies() <= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(insanity) or Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 3 and Spell(mind_spike) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Spell(vampiric_touch)
		{
			#halo,if=talent.halo.enabled&target.distance<=30&cooldown.mind_blast.remains>0.5*gcd
			if Talent(halo_talent) and target.Distance() <= 30 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(halo_caster)
			#cascade,if=talent.cascade.enabled&target.distance<=40&cooldown.mind_blast.remains>0.5*gcd
			if Talent(cascade_talent) and target.Distance() <= 40 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(cascade_caster)
			#divine_star,if=talent.divine_star.enabled&active_enemies>4&target.distance<=24&cooldown.mind_blast.remains>0.5*gcd
			if Talent(divine_star_talent) and Enemies() > 4 and target.Distance() <= 24 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(divine_star_caster)

			unless Enemies() <= 5 and BuffPresent(surge_of_darkness_buff) and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(mind_spike) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(mind_sear) or SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(mind_flay) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield)
			{
				#halo,if=talent.halo.enabled&target.distance<=30,moving=1
				if Talent(halo_talent) and target.Distance() <= 30 and Speed() > 0 Spell(halo_caster)
				#divine_star,moving=1,if=talent.divine_star.enabled&target.distance<=28
				if Speed() > 0 and Talent(divine_star_talent) and target.Distance() <= 28 Spell(divine_star_caster)
				#cascade,moving=1,if=talent.cascade.enabled&target.distance<=40
				if Speed() > 0 and Talent(cascade_talent) and target.Distance() <= 40 Spell(cascade_caster)
			}
		}
	}
}

AddFunction ShadowVentShortCdPostConditions
{
	ShadowOrbs() == 3 and not target.DebuffPresent(void_entropy_debuff) and target.TimeToDie() > 60 and Enemies() == 1 and Spell(void_entropy) or DebuffCountOnAny(void_entropy_debuff) < Enemies() and DebuffCountOnAny(void_entropy_debuff) <= 6 and not target.DebuffPresent(void_entropy_debuff) and ShadowOrbs() == 5 and Enemies() >= 1 and target.TimeToDie() > 60 and Spell(void_entropy) or ShadowOrbs() == 5 and target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) <= GCD() * 2 and not SpellCooldown(devouring_plague) > 0 and Enemies() == 1 and Spell(devouring_plague) or target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) <= GCD() * 2 and not SpellCooldown(devouring_plague) > 0 and Enemies() > 1 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 5 and Enemies() > 1 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 10 and Enemies() > 2 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 15 and Enemies() > 3 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 20 and Enemies() > 4 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) and { SpellCooldown(mind_blast) <= GCD() * 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) <= GCD() * 2 } and Enemies() == 1 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) and { SpellCooldown(mind_blast) <= GCD() * 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) <= GCD() * 2 } and Enemies() > 1 and Spell(devouring_plague) or ShadowOrbs() >= 3 and target.DebuffPresent(void_entropy_debuff) and Enemies() == 1 and BuffRemaining(mental_instinct_buff) < GCD() * 1.4 and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 and Spell(mind_blast) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() >= 3 and Spell(devouring_plague) or Enemies() <= 10 and not SpellCooldown(mind_blast) > 0 and ShadowOrbs() <= 4 and Spell(mind_blast) or target.HealthPercent() < 20 and not SpellCooldown(shadow_word_death) > 0 and ShadowOrbs() <= 4 and Spell(shadow_word_death) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or ShadowOrbs() == 4 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.5 and ArmorSetBonus(T17 2) and SpellCooldown(mind_blast) < 1.2 * GCD() and SpellCooldown(mind_blast) > 0.2 * GCD() and Spell(shadow_word_pain) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(insanity) or Enemies() <= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(insanity) or Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 3 and Spell(mind_spike) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Spell(vampiric_touch) or Enemies() <= 5 and BuffPresent(surge_of_darkness_buff) and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(mind_spike) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(mind_sear) or SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(mind_flay) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield) or Speed() > 0 and Spell(shadow_word_pain)
}

AddFunction ShadowVentCdActions
{
	unless ShadowOrbs() == 3 and not target.DebuffPresent(void_entropy_debuff) and target.TimeToDie() > 60 and Enemies() == 1 and Spell(void_entropy) or DebuffCountOnAny(void_entropy_debuff) < Enemies() and DebuffCountOnAny(void_entropy_debuff) <= 6 and not target.DebuffPresent(void_entropy_debuff) and ShadowOrbs() == 5 and Enemies() >= 1 and target.TimeToDie() > 60 and Spell(void_entropy) or ShadowOrbs() == 5 and target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) <= GCD() * 2 and not SpellCooldown(devouring_plague) > 0 and Enemies() == 1 and Spell(devouring_plague) or target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) <= GCD() * 2 and not SpellCooldown(devouring_plague) > 0 and Enemies() > 1 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 5 and Enemies() > 1 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 10 and Enemies() > 2 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 15 and Enemies() > 3 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 20 and Enemies() > 4 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) and { SpellCooldown(mind_blast) <= GCD() * 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) <= GCD() * 2 } and Enemies() == 1 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) and { SpellCooldown(mind_blast) <= GCD() * 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) <= GCD() * 2 } and Enemies() > 1 and Spell(devouring_plague) or ShadowOrbs() >= 3 and target.DebuffPresent(void_entropy_debuff) and Enemies() == 1 and BuffRemaining(mental_instinct_buff) < GCD() * 1.4 and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague)
	{
		#mindbender,if=talent.mindbender.enabled&cooldown.mind_blast.remains>=gcd
		if Talent(mindbender_talent) and SpellCooldown(mind_blast) >= GCD() Spell(mindbender)
		#shadowfiend,if=!talent.mindbender.enabled&cooldown.mind_blast.remains>=gcd
		if not Talent(mindbender_talent) and SpellCooldown(mind_blast) >= GCD() Spell(shadowfiend)
	}
}

AddFunction ShadowVentCdPostConditions
{
	ShadowOrbs() == 3 and not target.DebuffPresent(void_entropy_debuff) and target.TimeToDie() > 60 and Enemies() == 1 and Spell(void_entropy) or DebuffCountOnAny(void_entropy_debuff) < Enemies() and DebuffCountOnAny(void_entropy_debuff) <= 6 and not target.DebuffPresent(void_entropy_debuff) and ShadowOrbs() == 5 and Enemies() >= 1 and target.TimeToDie() > 60 and Spell(void_entropy) or ShadowOrbs() == 5 and target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) <= GCD() * 2 and not SpellCooldown(devouring_plague) > 0 and Enemies() == 1 and Spell(devouring_plague) or target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) <= GCD() * 2 and not SpellCooldown(devouring_plague) > 0 and Enemies() > 1 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 5 and Enemies() > 1 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 10 and Enemies() > 2 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 15 and Enemies() > 3 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 20 and Enemies() > 4 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) and { SpellCooldown(mind_blast) <= GCD() * 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) <= GCD() * 2 } and Enemies() == 1 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) and { SpellCooldown(mind_blast) <= GCD() * 2 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) <= GCD() * 2 } and Enemies() > 1 and Spell(devouring_plague) or ShadowOrbs() >= 3 and target.DebuffPresent(void_entropy_debuff) and Enemies() == 1 and BuffRemaining(mental_instinct_buff) < GCD() * 1.4 and BuffRemaining(mental_instinct_buff) > GCD() * 0.7 and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or Talent(halo_talent) and target.Distance() <= 30 and Enemies() >= 4 and Spell(halo_caster) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 and Spell(mind_blast) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() >= 3 and Spell(devouring_plague) or Enemies() <= 10 and not SpellCooldown(mind_blast) > 0 and ShadowOrbs() <= 4 and Spell(mind_blast) or target.HealthPercent() < 20 and not SpellCooldown(shadow_word_death) > 0 and ShadowOrbs() <= 4 and Spell(shadow_word_death) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(searing_insanity) or ShadowOrbs() == 4 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.5 and ArmorSetBonus(T17 2) and SpellCooldown(mind_blast) < 1.2 * GCD() and SpellCooldown(mind_blast) > 0.2 * GCD() and Spell(shadow_word_pain) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(insanity) or Enemies() <= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(insanity) or Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 3 and Spell(mind_spike) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and target.TimeToDie() > 18 * 0.75 and True(miss_react) and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and target.TimeToDie() > 15 * 0.75 + CastTime(vampiric_touch) and True(miss_react) and Spell(vampiric_touch) or Talent(halo_talent) and target.Distance() <= 30 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(halo_caster) or Talent(cascade_talent) and target.Distance() <= 40 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(cascade_caster) or Talent(divine_star_talent) and Enemies() > 4 and target.Distance() <= 24 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(divine_star_caster) or Enemies() <= 5 and BuffPresent(surge_of_darkness_buff) and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(mind_spike) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(mind_sear) or SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(mind_flay) or Speed() > 0 and 0 >= 1 * GCD() and Spell(shadow_word_death) or Speed() > 0 and Talent(body_and_soul_talent) and 0 >= 25 and Spell(power_word_shield) or Talent(halo_talent) and target.Distance() <= 30 and Speed() > 0 and Spell(halo_caster) or Speed() > 0 and Talent(divine_star_talent) and target.Distance() <= 28 and Spell(divine_star_caster) or Speed() > 0 and Talent(cascade_talent) and target.Distance() <= 40 and Spell(cascade_caster) or Speed() > 0 and Spell(shadow_word_pain)
}
]]
	OvaleScripts:RegisterScript("PRIEST", name, desc, code, "include")
end

do
	local name = "Ovale"	-- The default script.
	local desc = "[6.0] Ovale: Shadow"
	local code = [[
# Ovale priest script based on SimulationCraft.

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_priest_spells)
Include(ovale_priest)

### Shadow icons.

AddCheckBox(opt_priest_shadow_aoe L(AOE) default specialization=shadow)

AddIcon checkbox=!opt_priest_shadow_aoe enemies=1 help=shortcd specialization=shadow
{
	unless not InCombat() and ShadowPrecombatShortCdPostConditions()
	{
		ShadowDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_priest_shadow_aoe help=shortcd specialization=shadow
{
	unless not InCombat() and ShadowPrecombatShortCdPostConditions()
	{
		ShadowDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=shadow
{
	if not InCombat() ShadowPrecombatMainActions()
	ShadowDefaultMainActions()
}

AddIcon checkbox=opt_priest_shadow_aoe help=aoe specialization=shadow
{
	if not InCombat() ShadowPrecombatMainActions()
	ShadowDefaultMainActions()
}

AddIcon checkbox=!opt_priest_shadow_aoe enemies=1 help=cd specialization=shadow
{
	if not InCombat() ShadowPrecombatCdActions()
	unless not InCombat() and ShadowPrecombatCdPostConditions()
	{
		ShadowDefaultCdActions()
	}
}

AddIcon checkbox=opt_priest_shadow_aoe help=cd specialization=shadow
{
	if not InCombat() ShadowPrecombatCdActions()
	unless not InCombat() and ShadowPrecombatCdPostConditions()
	{
		ShadowDefaultCdActions()
	}
}
]]
	OvaleScripts:RegisterScript("PRIEST", name, desc, code, "script")
end
