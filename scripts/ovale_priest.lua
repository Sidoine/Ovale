local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_priest"
	local desc = "[6.0] Ovale: Rotations (Shadow)"
	local code = [[
# Priest rotation functions based on SimulationCraft.

Include(ovale_common)
Include(ovale_priest_spells)

AddCheckBox(opt_interrupt L(interrupt) default)
AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=shadow)
AddCheckBox(opt_potion_mana ItemName(draenic_mana_potion) default specialization=discipline)
AddCheckBox(opt_potion_mana ItemName(draenic_mana_potion) default specialization=holy)

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction InterruptActions
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

###
### Shadow
###
# Based on SimulationCraft profile "Priest_Shadow_T17M_COP".
#	class=priest
#	spec=shadow
#	talents=1133131
#	glyphs=mind_flay/fade/sha

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
		#call_action_list,name=decision
		ShadowDecisionShortCdActions()
	}
}

AddFunction ShadowDefaultCdActions
{
	unless not BuffPresent(shadowform_buff) and Spell(shadowform)
	{
		#silence
		InterruptActions()
		#potion,name=draenic_intellect,if=buff.bloodlust.react|target.time_to_die<=40
		if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 40 UsePotionIntellect()
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
		#call_action_list,name=decision
		ShadowDecisionCdActions()
	}
}

### actions.cop

AddFunction ShadowCopMainActions
{
	#devouring_plague,if=shadow_orb>=3&(cooldown.mind_blast.remains<=gcd*1.0|(cooldown.shadow_word_death.remains<=gcd*1.0&target.health.pct<20))&primary_target=0,cycle_targets=1
	if ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) <= GCD() * 1 or SpellCooldown(shadow_word_death) <= GCD() * 1 and target.HealthPercent() < 20 } and 1 == 0 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&(cooldown.mind_blast.remains<=gcd*1.0|(cooldown.shadow_word_death.remains<=gcd*1.0&target.health.pct<20))
	if ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) <= GCD() * 1 or SpellCooldown(shadow_word_death) <= GCD() * 1 and target.HealthPercent() < 20 } Spell(devouring_plague)
	#mind_blast,if=mind_harvest=0,cycle_targets=1
	if target.MindHarvest() == 0 Spell(mind_blast)
	#mind_blast,if=active_enemies<=5&cooldown_react
	if Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#shadow_word_death,if=target.health.pct<20,cycle_targets=1
	if target.HealthPercent() < 20 Spell(shadow_word_death)
	#shadow_word_pain,if=miss_react&!ticking&active_enemies<=5&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) and Enemies() <= 5 and 1 == 0 Spell(shadow_word_pain)
	#vampiric_touch,if=remains<cast_time&miss_react&active_enemies<=5&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and 1 == 0 Spell(vampiric_touch)
	#mind_sear,if=active_enemies>=5,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() >= 5 Spell(mind_sear)
	#mind_spike,if=active_enemies<=4&buff.surge_of_darkness.react
	if Enemies() <= 4 and BuffPresent(surge_of_darkness_buff) Spell(mind_spike)
	#mind_sear,if=active_enemies>=3,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() >= 3 Spell(mind_sear)
	#mind_flay,if=target.dot.devouring_plague_tick.ticks_remain>1&active_enemies=1,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if target.TicksRemaining(devouring_plague_debuff) > 1 and Enemies() == 1 Spell(mind_flay)
	#mind_spike
	Spell(mind_spike)
	#shadow_word_death,moving=1
	if Speed() > 0 Spell(shadow_word_death)
	#mind_blast,if=buff.shadowy_insight.react&cooldown_react,moving=1
	if BuffPresent(shadowy_insight_buff) and not SpellCooldown(mind_blast) > 0 and Speed() > 0 Spell(mind_blast)
	#shadow_word_pain,if=primary_target=0,moving=1,cycle_targets=1
	if Speed() > 0 and 1 == 0 Spell(shadow_word_pain)
}

AddFunction ShadowCopShortCdActions
{
	unless ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) <= GCD() * 1 or SpellCooldown(shadow_word_death) <= GCD() * 1 and target.HealthPercent() < 20 } and 1 == 0 and Spell(devouring_plague) or ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) <= GCD() * 1 or SpellCooldown(shadow_word_death) <= GCD() * 1 and target.HealthPercent() < 20 } and Spell(devouring_plague) or target.MindHarvest() == 0 and Spell(mind_blast) or Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or target.HealthPercent() < 20 and Spell(shadow_word_death)
	{
		#halo,if=talent.halo.enabled&target.distance<=30&target.distance>=17
		if Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo_caster)
		#cascade,if=talent.cascade.enabled&(active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11
		if Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade_caster)
		#divine_star,if=talent.divine_star.enabled&active_enemies>3&target.distance<=24
		if Talent(divine_star_talent) and Enemies() > 3 and target.Distance() <= 24 Spell(divine_star_caster)

		unless DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) and Enemies() <= 5 and 1 == 0 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and 1 == 0 and Spell(vampiric_touch)
		{
			#divine_star,if=talent.divine_star.enabled&active_enemies=3&target.distance<=24
			if Talent(divine_star_talent) and Enemies() == 3 and target.Distance() <= 24 Spell(divine_star_caster)

			unless Enemies() >= 5 and Spell(mind_sear) or Enemies() <= 4 and BuffPresent(surge_of_darkness_buff) and Spell(mind_spike) or Enemies() >= 3 and Spell(mind_sear) or target.TicksRemaining(devouring_plague_debuff) > 1 and Enemies() == 1 and Spell(mind_flay) or Spell(mind_spike) or Speed() > 0 and Spell(shadow_word_death) or BuffPresent(shadowy_insight_buff) and not SpellCooldown(mind_blast) > 0 and Speed() > 0 and Spell(mind_blast)
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

AddFunction ShadowCopCdActions
{
	unless ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) <= GCD() * 1 or SpellCooldown(shadow_word_death) <= GCD() * 1 and target.HealthPercent() < 20 } and 1 == 0 and Spell(devouring_plague) or ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) <= GCD() * 1 or SpellCooldown(shadow_word_death) <= GCD() * 1 and target.HealthPercent() < 20 } and Spell(devouring_plague) or target.MindHarvest() == 0 and Spell(mind_blast) or Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or target.HealthPercent() < 20 and Spell(shadow_word_death)
	{
		#mindbender,if=talent.mindbender.enabled
		if Talent(mindbender_talent) Spell(mindbender)
		#shadowfiend,if=!talent.mindbender.enabled
		if not Talent(mindbender_talent) Spell(shadowfiend)
	}
}

### actions.cop_dotweave

AddFunction ShadowCopDotweaveMainActions
{
	#devouring_plague,if=target.dot.vampiric_touch.ticking&target.dot.shadow_word_pain.ticking&shadow_orb=5&cooldown_react
	if target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and ShadowOrbs() == 5 and not SpellCooldown(devouring_plague) > 0 Spell(devouring_plague)
	#devouring_plague,if=(buff.mental_instinct.remains<gcd&buff.mental_instinct.remains)
	if BuffRemaining(mental_instinct_buff) < GCD() and BuffPresent(mental_instinct_buff) Spell(devouring_plague)
	#devouring_plague,if=(target.dot.vampiric_touch.ticking&target.dot.shadow_word_pain.ticking&!buff.shadow_word_insanity.remains&cooldown.mind_blast.remains>0.4*gcd)
	if target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and not BuffPresent(shadow_word_insanity_buff) and SpellCooldown(mind_blast) > 0.4 * GCD() Spell(devouring_plague)
	#mind_blast,if=glyph.mind_harvest.enabled&mind_harvest=0&shadow_orb<=2,cycle_targets=1
	if Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 Spell(mind_blast)
	#mind_blast,if=shadow_orb<=4&cooldown_react
	if ShadowOrbs() <= 4 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#shadow_word_pain,if=shadow_orb=4&set_bonus.tier17_2pc&!target.dot.shadow_word_pain.ticking&!target.dot.devouring_plague.ticking&cooldown.mind_blast.remains<1.2*gcd&cooldown.mind_blast.remains>0.2*gcd
	if ShadowOrbs() == 4 and ArmorSetBonus(T17 2) and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(devouring_plague_debuff) and SpellCooldown(mind_blast) < 1.2 * GCD() and SpellCooldown(mind_blast) > 0.2 * GCD() Spell(shadow_word_pain)
	#shadow_word_pain,if=shadow_orb=5&!target.dot.devouring_plague.ticking&!target.dot.shadow_word_pain.ticking
	if ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_debuff) and not target.DebuffPresent(shadow_word_pain_debuff) Spell(shadow_word_pain)
	#vampiric_touch,if=shadow_orb=5&!target.dot.devouring_plague.ticking&!target.dot.vampiric_touch.ticking
	if ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_debuff) and not target.DebuffPresent(vampiric_touch_debuff) Spell(vampiric_touch)
	#insanity,if=buff.shadow_word_insanity.remains,chain=1,interrupt_if=cooldown.mind_blast.remains<=0.1
	if BuffPresent(shadow_word_insanity_buff) and BuffPresent(shadow_word_insanity_buff) Spell(insanity)
	#shadow_word_pain,if=shadow_orb>=2&target.dot.shadow_word_pain.remains>=6&cooldown.mind_blast.remains>0.5*gcd&target.dot.vampiric_touch.remains&buff.bloodlust.up&!set_bonus.tier17_2pc
	if ShadowOrbs() >= 2 and target.DebuffRemaining(shadow_word_pain_debuff) >= 6 and SpellCooldown(mind_blast) > 0.5 * GCD() and target.DebuffRemaining(vampiric_touch_debuff) and BuffPresent(burst_haste_buff any=1) and not ArmorSetBonus(T17 2) Spell(shadow_word_pain)
	#vampiric_touch,if=shadow_orb>=2&target.dot.vampiric_touch.remains>=5&cooldown.mind_blast.remains>0.5*gcd&buff.bloodlust.up&!set_bonus.tier17_2pc
	if ShadowOrbs() >= 2 and target.DebuffRemaining(vampiric_touch_debuff) >= 5 and SpellCooldown(mind_blast) > 0.5 * GCD() and BuffPresent(burst_haste_buff any=1) and not ArmorSetBonus(T17 2) Spell(vampiric_touch)
	#shadow_word_pain,if=primary_target=0&!ticking,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and 1 == 0 and not target.DebuffPresent(shadow_word_pain_debuff) Spell(shadow_word_pain)
	#vampiric_touch,if=primary_target=0&!ticking,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and 1 == 0 and not target.DebuffPresent(vampiric_touch_debuff) Spell(vampiric_touch)
	#shadow_word_pain,if=primary_target=0&(!ticking|remains<=18*0.3),cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and 1 == 0 and { not target.DebuffPresent(shadow_word_pain_debuff) or target.DebuffRemaining(shadow_word_pain_debuff) <= 18 * 0.3 } Spell(shadow_word_pain)
	#vampiric_touch,if=primary_target=0&(!ticking|remains<=15*0.3),cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and 1 == 0 and { not target.DebuffPresent(vampiric_touch_debuff) or target.DebuffRemaining(vampiric_touch_debuff) <= 15 * 0.3 } Spell(vampiric_touch)
	#mind_spike,if=buff.shadow_word_insanity.remains<=gcd&buff.bloodlust.up&!target.dot.shadow_word_pain.remains&!target.dot.vampiric_touch.remains
	if BuffRemaining(shadow_word_insanity_buff) <= GCD() and BuffPresent(burst_haste_buff any=1) and not target.DebuffRemaining(shadow_word_pain_debuff) and not target.DebuffRemaining(vampiric_touch_debuff) Spell(mind_spike)
	#mind_spike,if=((target.dot.shadow_word_pain.remains&!target.dot.vampiric_touch.remains)|(!target.dot.shadow_word_pain.remains&target.dot.vampiric_touch.remains))&shadow_orb<=2&cooldown.mind_blast.remains>0.5*gcd
	if { target.DebuffRemaining(shadow_word_pain_debuff) and not target.DebuffRemaining(vampiric_touch_debuff) or not target.DebuffRemaining(shadow_word_pain_debuff) and target.DebuffRemaining(vampiric_touch_debuff) } and ShadowOrbs() <= 2 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(mind_spike)
	#mind_flay,if=set_bonus.tier17_2pc&target.dot.shadow_word_pain.remains&target.dot.vampiric_touch.remains&cooldown.mind_blast.remains>0.9*gcd,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if ArmorSetBonus(T17 2) and target.DebuffRemaining(shadow_word_pain_debuff) and target.DebuffRemaining(vampiric_touch_debuff) and SpellCooldown(mind_blast) > 0.9 * GCD() Spell(mind_flay)
	#mind_spike
	Spell(mind_spike)
	#shadow_word_death,moving=1
	if Speed() > 0 Spell(shadow_word_death)
	#shadow_word_pain,moving=1
	if Speed() > 0 Spell(shadow_word_pain)
}

AddFunction ShadowCopDotweaveShortCdActions
{
	unless target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and ShadowOrbs() == 5 and not SpellCooldown(devouring_plague) > 0 and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and not BuffPresent(shadow_word_insanity_buff) and SpellCooldown(mind_blast) > 0.4 * GCD() and Spell(devouring_plague) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 and Spell(mind_blast) or ShadowOrbs() <= 4 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or ShadowOrbs() == 4 and ArmorSetBonus(T17 2) and not target.DebuffPresent(shadow_word_pain_debuff) and not target.DebuffPresent(devouring_plague_debuff) and SpellCooldown(mind_blast) < 1.2 * GCD() and SpellCooldown(mind_blast) > 0.2 * GCD() and Spell(shadow_word_pain) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_debuff) and not target.DebuffPresent(shadow_word_pain_debuff) and Spell(shadow_word_pain) or ShadowOrbs() == 5 and not target.DebuffPresent(devouring_plague_debuff) and not target.DebuffPresent(vampiric_touch_debuff) and Spell(vampiric_touch) or BuffPresent(shadow_word_insanity_buff) and BuffPresent(shadow_word_insanity_buff) and Spell(insanity) or ShadowOrbs() >= 2 and target.DebuffRemaining(shadow_word_pain_debuff) >= 6 and SpellCooldown(mind_blast) > 0.5 * GCD() and target.DebuffRemaining(vampiric_touch_debuff) and BuffPresent(burst_haste_buff any=1) and not ArmorSetBonus(T17 2) and Spell(shadow_word_pain) or ShadowOrbs() >= 2 and target.DebuffRemaining(vampiric_touch_debuff) >= 5 and SpellCooldown(mind_blast) > 0.5 * GCD() and BuffPresent(burst_haste_buff any=1) and not ArmorSetBonus(T17 2) and Spell(vampiric_touch)
	{
		#halo,if=cooldown.mind_blast.remains>0.5*gcd&talent.halo.enabled&target.distance<=30&target.distance>=17
		if SpellCooldown(mind_blast) > 0.5 * GCD() and Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo_caster)
		#cascade,if=cooldown.mind_blast.remains>0.5*gcd&talent.cascade.enabled&(active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11
		if SpellCooldown(mind_blast) > 0.5 * GCD() and Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade_caster)
		#divine_star,if=talent.divine_star.enabled&cooldown.mind_blast.remains>0.5*gcd&active_enemies>3&target.distance<=24
		if Talent(divine_star_talent) and SpellCooldown(mind_blast) > 0.5 * GCD() and Enemies() > 3 and target.Distance() <= 24 Spell(divine_star_caster)

		unless DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and 1 == 0 and not target.DebuffPresent(shadow_word_pain_debuff) and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and 1 == 0 and not target.DebuffPresent(vampiric_touch_debuff) and Spell(vampiric_touch)
		{
			#divine_star,if=talent.divine_star.enabled&cooldown.mind_blast.remains>0.5*gcd&active_enemies=3&target.distance<=24
			if Talent(divine_star_talent) and SpellCooldown(mind_blast) > 0.5 * GCD() and Enemies() == 3 and target.Distance() <= 24 Spell(divine_star_caster)

			unless DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and 1 == 0 and { not target.DebuffPresent(shadow_word_pain_debuff) or target.DebuffRemaining(shadow_word_pain_debuff) <= 18 * 0.3 } and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and 1 == 0 and { not target.DebuffPresent(vampiric_touch_debuff) or target.DebuffRemaining(vampiric_touch_debuff) <= 15 * 0.3 } and Spell(vampiric_touch) or BuffRemaining(shadow_word_insanity_buff) <= GCD() and BuffPresent(burst_haste_buff any=1) and not target.DebuffRemaining(shadow_word_pain_debuff) and not target.DebuffRemaining(vampiric_touch_debuff) and Spell(mind_spike) or { target.DebuffRemaining(shadow_word_pain_debuff) and not target.DebuffRemaining(vampiric_touch_debuff) or not target.DebuffRemaining(shadow_word_pain_debuff) and target.DebuffRemaining(vampiric_touch_debuff) } and ShadowOrbs() <= 2 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(mind_spike) or ArmorSetBonus(T17 2) and target.DebuffRemaining(shadow_word_pain_debuff) and target.DebuffRemaining(vampiric_touch_debuff) and SpellCooldown(mind_blast) > 0.9 * GCD() and Spell(mind_flay) or Spell(mind_spike) or Speed() > 0 and Spell(shadow_word_death)
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

AddFunction ShadowCopDotweaveCdActions
{
	unless target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and ShadowOrbs() == 5 and not SpellCooldown(devouring_plague) > 0 and Spell(devouring_plague) or BuffRemaining(mental_instinct_buff) < GCD() and BuffPresent(mental_instinct_buff) and Spell(devouring_plague) or target.DebuffPresent(vampiric_touch_debuff) and target.DebuffPresent(shadow_word_pain_debuff) and not BuffPresent(shadow_word_insanity_buff) and SpellCooldown(mind_blast) > 0.4 * GCD() and Spell(devouring_plague) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 and Spell(mind_blast) or ShadowOrbs() <= 4 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast)
	{
		#shadowfiend,if=!talent.mindbender.enabled&!buff.shadow_word_insanity.remains
		if not Talent(mindbender_talent) and not BuffPresent(shadow_word_insanity_buff) Spell(shadowfiend)
		#mindbender,if=talent.mindbender.enabled&!buff.shadow_word_insanity.remains
		if Talent(mindbender_talent) and not BuffPresent(shadow_word_insanity_buff) Spell(mindbender)
	}
}

### actions.cop_mfi

AddFunction ShadowCopMfiMainActions
{
	#devouring_plague,if=shadow_orb=5
	if ShadowOrbs() == 5 Spell(devouring_plague)
	#mind_blast,if=glyph.mind_harvest.enabled&mind_harvest=0,cycle_targets=1
	if Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 Spell(mind_blast)
	#mind_blast,if=active_enemies<=5&cooldown_react
	if Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#shadow_word_death,if=target.health.pct<20,cycle_targets=1
	if target.HealthPercent() < 20 Spell(shadow_word_death)
	#devouring_plague,if=shadow_orb>=3&(cooldown.mind_blast.remains<gcd*1.0|target.health.pct<20&cooldown.shadow_word_death.remains<gcd*1.0)
	if ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) < GCD() * 1 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() * 1 } Spell(devouring_plague)
	#shadow_word_pain,if=remains<(18*0.3)&miss_react&active_enemies<=5&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and True(miss_react) and Enemies() <= 5 and 1 == 0 Spell(shadow_word_pain)
	#vampiric_touch,if=remains<(15*0.3+cast_time)&miss_react&active_enemies<=5&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and 1 == 0 Spell(vampiric_touch)
	#insanity,if=buff.shadow_word_insanity.remains<0.5*gcd&active_enemies<=2,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|(cooldown.shadow_word_death.remains<=0.1&target.health.pct<20))
	if BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 and BuffPresent(shadow_word_insanity_buff) Spell(insanity)
	#insanity,if=active_enemies<=2,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|(cooldown.shadow_word_death.remains<=0.1&target.health.pct<20))
	if Enemies() <= 2 and BuffPresent(shadow_word_insanity_buff) Spell(insanity)
	#mind_sear,if=active_enemies>=6,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() >= 6 Spell(mind_sear)
	#mind_spike
	Spell(mind_spike)
	#shadow_word_death,moving=1
	if Speed() > 0 Spell(shadow_word_death)
	#mind_blast,if=buff.shadowy_insight.react&cooldown_react,moving=1
	if BuffPresent(shadowy_insight_buff) and not SpellCooldown(mind_blast) > 0 and Speed() > 0 Spell(mind_blast)
	#shadow_word_pain,if=primary_target=0,moving=1,cycle_targets=1
	if Speed() > 0 and 1 == 0 Spell(shadow_word_pain)
}

AddFunction ShadowCopMfiShortCdActions
{
	unless ShadowOrbs() == 5 and Spell(devouring_plague) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and Spell(mind_blast) or Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or target.HealthPercent() < 20 and Spell(shadow_word_death) or ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) < GCD() * 1 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() * 1 } and Spell(devouring_plague) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and True(miss_react) and Enemies() <= 5 and 1 == 0 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and 1 == 0 and Spell(vampiric_touch) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 and BuffPresent(shadow_word_insanity_buff) and Spell(insanity) or Enemies() <= 2 and BuffPresent(shadow_word_insanity_buff) and Spell(insanity)
	{
		#halo,if=talent.halo.enabled&target.distance<=30&target.distance>=17
		if Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo_caster)
		#cascade,if=talent.cascade.enabled&(active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11
		if Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade_caster)
		#divine_star,if=talent.divine_star.enabled&(active_enemies>2&target.distance<=24)
		if Talent(divine_star_talent) and Enemies() > 2 and target.Distance() <= 24 Spell(divine_star_caster)

		unless Enemies() >= 6 and Spell(mind_sear) or Spell(mind_spike) or Speed() > 0 and Spell(shadow_word_death) or BuffPresent(shadowy_insight_buff) and not SpellCooldown(mind_blast) > 0 and Speed() > 0 and Spell(mind_blast)
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

AddFunction ShadowCopMfiCdActions
{
	unless ShadowOrbs() == 5 and Spell(devouring_plague) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and Spell(mind_blast) or Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or target.HealthPercent() < 20 and Spell(shadow_word_death) or ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) < GCD() * 1 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < GCD() * 1 } and Spell(devouring_plague)
	{
		#mindbender,if=talent.mindbender.enabled
		if Talent(mindbender_talent) Spell(mindbender)
		#shadowfiend,if=!talent.mindbender.enabled
		if not Talent(mindbender_talent) Spell(shadowfiend)
	}
}

### actions.decision

AddFunction ShadowDecisionMainActions
{
	#call_action_list,name=cop_dotweave,if=talent.clarity_of_power.enabled&talent.insanity.enabled&target.health.pct>20&active_enemies<=5
	if Talent(clarity_of_power_talent) and Talent(insanity_talent) and target.HealthPercent() > 20 and Enemies() <= 5 ShadowCopDotweaveMainActions()
	#call_action_list,name=cop_mfi,if=talent.clarity_of_power.enabled&talent.insanity.enabled&target.health.pct<=20
	if Talent(clarity_of_power_talent) and Talent(insanity_talent) and target.HealthPercent() <= 20 ShadowCopMfiMainActions()
	#call_action_list,name=cop,if=talent.clarity_of_power.enabled
	if Talent(clarity_of_power_talent) ShadowCopMainActions()
	#call_action_list,name=vent,if=talent.void_entropy.enabled
	if Talent(void_entropy_talent) ShadowVentMainActions()
	#call_action_list,name=main
	ShadowMainMainActions()
}

AddFunction ShadowDecisionShortCdActions
{
	#call_action_list,name=cop_dotweave,if=talent.clarity_of_power.enabled&talent.insanity.enabled&target.health.pct>20&active_enemies<=5
	if Talent(clarity_of_power_talent) and Talent(insanity_talent) and target.HealthPercent() > 20 and Enemies() <= 5 ShadowCopDotweaveShortCdActions()
	#call_action_list,name=cop_mfi,if=talent.clarity_of_power.enabled&talent.insanity.enabled&target.health.pct<=20
	if Talent(clarity_of_power_talent) and Talent(insanity_talent) and target.HealthPercent() <= 20 ShadowCopMfiShortCdActions()
	#call_action_list,name=cop,if=talent.clarity_of_power.enabled
	if Talent(clarity_of_power_talent) ShadowCopShortCdActions()
	#call_action_list,name=vent,if=talent.void_entropy.enabled
	if Talent(void_entropy_talent) ShadowVentShortCdActions()
	#call_action_list,name=main
	ShadowMainShortCdActions()
}

AddFunction ShadowDecisionCdActions
{
	#call_action_list,name=cop_dotweave,if=talent.clarity_of_power.enabled&talent.insanity.enabled&target.health.pct>20&active_enemies<=5
	if Talent(clarity_of_power_talent) and Talent(insanity_talent) and target.HealthPercent() > 20 and Enemies() <= 5 ShadowCopDotweaveCdActions()
	#call_action_list,name=cop_mfi,if=talent.clarity_of_power.enabled&talent.insanity.enabled&target.health.pct<=20
	if Talent(clarity_of_power_talent) and Talent(insanity_talent) and target.HealthPercent() <= 20 ShadowCopMfiCdActions()
	#call_action_list,name=cop,if=talent.clarity_of_power.enabled
	if Talent(clarity_of_power_talent) ShadowCopCdActions()
	#call_action_list,name=vent,if=talent.void_entropy.enabled
	if Talent(void_entropy_talent) ShadowVentCdActions()
	#call_action_list,name=main
	ShadowMainCdActions()
}

### actions.main

AddFunction ShadowMainMainActions
{
	#shadow_word_death,if=target.health.pct<20&shadow_orb<=4,cycle_targets=1
	if target.HealthPercent() < 20 and ShadowOrbs() <= 4 Spell(shadow_word_death)
	#mind_blast,if=glyph.mind_harvest.enabled&shadow_orb<=2&active_enemies<=5&cooldown_react
	if Glyph(glyph_of_mind_harvest) and ShadowOrbs() <= 2 and Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#devouring_plague,if=shadow_orb=5&talent.surge_of_darkness.enabled,cycle_targets=1
	if ShadowOrbs() == 5 and Talent(surge_of_darkness_talent) Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5
	if ShadowOrbs() == 5 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&(cooldown.mind_blast.remains<1.5|target.health.pct<20&cooldown.shadow_word_death.remains<1.5)&!target.dot.devouring_plague_tick.ticking&talent.surge_of_darkness.enabled,cycle_targets=1
	if ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } and not target.DebuffPresent(devouring_plague_debuff) and Talent(surge_of_darkness_talent) Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&(cooldown.mind_blast.remains<1.5|target.health.pct<20&cooldown.shadow_word_death.remains<1.5)
	if ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } Spell(devouring_plague)
	#mind_blast,if=glyph.mind_harvest.enabled&mind_harvest=0,cycle_targets=1
	if Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 Spell(mind_blast)
	#mind_blast,if=active_enemies<=5&cooldown_react
	if Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#insanity,if=buff.shadow_word_insanity.remains<0.5*gcd&active_enemies<=2,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1|shadow_orb=5)
	if BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 and BuffPresent(shadow_word_insanity_buff) Spell(insanity)
	#insanity,chain=1,if=active_enemies<=2,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1|shadow_orb=5)
	if Enemies() <= 2 and BuffPresent(shadow_word_insanity_buff) Spell(insanity)
	#shadow_word_pain,if=talent.auspicious_spirits.enabled&remains<(18*0.3)&miss_react,cycle_targets=1
	if Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and True(miss_react) Spell(shadow_word_pain)
	#shadow_word_pain,if=!talent.auspicious_spirits.enabled&remains<(18*0.3)&miss_react&active_enemies<=5,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and not Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and True(miss_react) and Enemies() <= 5 Spell(shadow_word_pain)
	#vampiric_touch,if=remains<(15*0.3+cast_time)&miss_react&active_enemies<=5,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 Spell(vampiric_touch)
	#devouring_plague,if=!talent.void_entropy.enabled&shadow_orb>=3&ticks_remain<=1
	if not Talent(void_entropy_talent) and ShadowOrbs() >= 3 and target.TicksRemaining(devouring_plague_debuff) < 2 Spell(devouring_plague)
	#mind_spike,if=active_enemies<=5&buff.surge_of_darkness.react=3
	if Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 3 Spell(mind_spike)
	#wait,sec=cooldown.shadow_word_death.remains,if=target.health.pct<20&cooldown.shadow_word_death.remains&cooldown.shadow_word_death.remains<0.5&active_enemies<=1
	unless target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) > 0 and SpellCooldown(shadow_word_death) < 0.5 and Enemies() <= 1 and SpellCooldown(shadow_word_death) > 0
	{
		#wait,sec=cooldown.mind_blast.remains,if=cooldown.mind_blast.remains<0.5&cooldown.mind_blast.remains&active_enemies<=1
		unless SpellCooldown(mind_blast) < 0.5 and SpellCooldown(mind_blast) > 0 and Enemies() <= 1 and SpellCooldown(mind_blast) > 0
		{
			#mind_spike,if=buff.surge_of_darkness.react&active_enemies<=5
			if BuffPresent(surge_of_darkness_buff) and Enemies() <= 5 Spell(mind_spike)
			#mind_sear,chain=1,if=active_enemies>=4,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1|shadow_orb=5)
			if Enemies() >= 4 Spell(mind_sear)
			#shadow_word_pain,if=shadow_orb>=2&ticks_remain<=3&talent.insanity.enabled
			if ShadowOrbs() >= 2 and target.TicksRemaining(shadow_word_pain_debuff) < 4 and Talent(insanity_talent) Spell(shadow_word_pain)
			#vampiric_touch,if=shadow_orb>=2&ticks_remain<=3.5&talent.insanity.enabled
			if ShadowOrbs() >= 2 and target.TicksRemaining(vampiric_touch_debuff) < 4.5 and Talent(insanity_talent) Spell(vampiric_touch)
			#mind_flay,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1|shadow_orb=5)
			Spell(mind_flay)
			#mind_blast,moving=1,if=buff.shadowy_insight.react&cooldown_react
			if Speed() > 0 and BuffPresent(shadowy_insight_buff) and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
			#shadow_word_death,moving=1
			if Speed() > 0 Spell(shadow_word_death)
			#shadow_word_pain,moving=1,cycle_targets=1
			if Speed() > 0 Spell(shadow_word_pain)
		}
	}
}

AddFunction ShadowMainShortCdActions
{
	unless target.HealthPercent() < 20 and ShadowOrbs() <= 4 and Spell(shadow_word_death) or Glyph(glyph_of_mind_harvest) and ShadowOrbs() <= 2 and Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or ShadowOrbs() == 5 and Talent(surge_of_darkness_talent) and Spell(devouring_plague) or ShadowOrbs() == 5 and Spell(devouring_plague) or ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } and not target.DebuffPresent(devouring_plague_debuff) and Talent(surge_of_darkness_talent) and Spell(devouring_plague) or ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } and Spell(devouring_plague) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and Spell(mind_blast) or Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 and BuffPresent(shadow_word_insanity_buff) and Spell(insanity) or Enemies() <= 2 and BuffPresent(shadow_word_insanity_buff) and Spell(insanity)
	{
		#halo,if=talent.halo.enabled&target.distance<=30&active_enemies>2
		if Talent(halo_talent) and target.Distance() <= 30 and Enemies() > 2 Spell(halo_caster)
		#cascade,if=talent.cascade.enabled&active_enemies>2&target.distance<=40
		if Talent(cascade_talent) and Enemies() > 2 and target.Distance() <= 40 Spell(cascade_caster)
		#divine_star,if=talent.divine_star.enabled&active_enemies>4&target.distance<=24
		if Talent(divine_star_talent) and Enemies() > 4 and target.Distance() <= 24 Spell(divine_star_caster)

		unless Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and True(miss_react) and Spell(shadow_word_pain) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and not Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and True(miss_react) and Enemies() <= 5 and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and True(miss_react) and Enemies() <= 5 and Spell(vampiric_touch) or not Talent(void_entropy_talent) and ShadowOrbs() >= 3 and target.TicksRemaining(devouring_plague_debuff) < 2 and Spell(devouring_plague) or Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 3 and Spell(mind_spike)
		{
			#halo,if=talent.halo.enabled&target.distance<=30&target.distance>=17
			if Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo_caster)
			#cascade,if=talent.cascade.enabled&(active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11
			if Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade_caster)
			#divine_star,if=talent.divine_star.enabled&active_enemies>1&target.distance<=24
			if Talent(divine_star_talent) and Enemies() > 1 and target.Distance() <= 24 Spell(divine_star_caster)
			#wait,sec=cooldown.shadow_word_death.remains,if=target.health.pct<20&cooldown.shadow_word_death.remains&cooldown.shadow_word_death.remains<0.5&active_enemies<=1
			unless target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) > 0 and SpellCooldown(shadow_word_death) < 0.5 and Enemies() <= 1 and SpellCooldown(shadow_word_death) > 0
			{
				#wait,sec=cooldown.mind_blast.remains,if=cooldown.mind_blast.remains<0.5&cooldown.mind_blast.remains&active_enemies<=1
				unless SpellCooldown(mind_blast) < 0.5 and SpellCooldown(mind_blast) > 0 and Enemies() <= 1 and SpellCooldown(mind_blast) > 0
				{
					unless BuffPresent(surge_of_darkness_buff) and Enemies() <= 5 and Spell(mind_spike)
					{
						#divine_star,if=talent.divine_star.enabled&target.distance<=28&active_enemies>1
						if Talent(divine_star_talent) and target.Distance() <= 28 and Enemies() > 1 Spell(divine_star_caster)

						unless Enemies() >= 4 and Spell(mind_sear) or ShadowOrbs() >= 2 and target.TicksRemaining(shadow_word_pain_debuff) < 4 and Talent(insanity_talent) and Spell(shadow_word_pain) or ShadowOrbs() >= 2 and target.TicksRemaining(vampiric_touch_debuff) < 4.5 and Talent(insanity_talent) and Spell(vampiric_touch) or Spell(mind_flay) or Speed() > 0 and BuffPresent(shadowy_insight_buff) and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast)
						{
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

AddFunction ShadowMainCdActions
{
	#mindbender,if=talent.mindbender.enabled
	if Talent(mindbender_talent) Spell(mindbender)
	#shadowfiend,if=!talent.mindbender.enabled
	if not Talent(mindbender_talent) Spell(shadowfiend)
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

AddFunction ShadowPrecombatCdActions
{
	unless not BuffPresent(stamina_buff any=1) and Spell(power_word_fortitude) or not BuffPresent(shadowform_buff) and Spell(shadowform)
	{
		#snapshot_stats
		#potion,name=draenic_intellect
		UsePotionIntellect()
	}
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
	#call_action_list,name=decision
	ShadowDecisionShortCdActions()
}

AddFunction ShadowPvpDispersionCdActions
{
	#call_action_list,name=decision,if=cooldown.dispersion.remains>0
	if SpellCooldown(dispersion) > 0 ShadowDecisionCdActions()
	#dispersion,interrupt=1
	Spell(dispersion)
	#call_action_list,name=decision
	ShadowDecisionCdActions()
}

### actions.vent

AddFunction ShadowVentMainActions
{
	#void_entropy,if=shadow_orb=3&!ticking&target.time_to_die>60&active_enemies=1
	if ShadowOrbs() == 3 and not target.DebuffPresent(void_entropy_debuff) and target.TimeToDie() > 60 and Enemies() == 1 Spell(void_entropy)
	#void_entropy,if=!dot.void_entropy.ticking&shadow_orb=5&active_enemies>=1&target.time_to_die>60,cycle_targets=1,max_cycle_targets=(60%(cooldown.mind_blast.duration*3*spell_haste))
	if DebuffCountOnAny(void_entropy_debuff) < Enemies() and DebuffCountOnAny(void_entropy_debuff) <= 60 / { SpellCooldownDuration(mind_blast) * 3 * 100 / { 100 + SpellHaste() } } and not target.DebuffPresent(void_entropy_debuff) and ShadowOrbs() == 5 and Enemies() >= 1 and target.TimeToDie() > 60 Spell(void_entropy)
	#devouring_plague,if=dot.void_entropy.ticking&dot.void_entropy.remains<=gcd*2&cooldown_react,cycle_targets=1
	if target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) <= GCD() * 2 and not SpellCooldown(devouring_plague) > 0 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5&dot.void_entropy.remains<10,cycle_targets=1
	if ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 10 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5&dot.void_entropy.remains<20,cycle_targets=1
	if ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 20 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb=5&dot.void_entropy.remains,cycle_targets=1
	if ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) Spell(devouring_plague)
	#mind_blast,if=glyph.mind_harvest.enabled&mind_harvest=0&shadow_orb<=2,cycle_targets=1
	if Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 Spell(mind_blast)
	#devouring_plague,if=glyph.mind_harvest.enabled&mind_harvest=0&shadow_orb>=3,cycle_targets=1
	if Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() >= 3 Spell(devouring_plague)
	#mind_blast,if=active_enemies<=10&cooldown_react&shadow_orb<=4
	if Enemies() <= 10 and not SpellCooldown(mind_blast) > 0 and ShadowOrbs() <= 4 Spell(mind_blast)
	#shadow_word_death,if=target.health.pct<20&cooldown_react&shadow_orb<=4,cycle_targets=1
	if target.HealthPercent() < 20 and not SpellCooldown(shadow_word_death) > 0 and ShadowOrbs() <= 4 Spell(shadow_word_death)
	#shadow_word_pain,if=shadow_orb=4&remains<(18*0.50)&set_bonus.tier17_2pc&cooldown.mind_blast.remains<1.2*gcd&cooldown.mind_blast.remains>0.2*gcd
	if ShadowOrbs() == 4 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.5 and ArmorSetBonus(T17 2) and SpellCooldown(mind_blast) < 1.2 * GCD() and SpellCooldown(mind_blast) > 0.2 * GCD() Spell(shadow_word_pain)
	#insanity,if=buff.shadow_word_insanity.remains<0.5*gcd&active_enemies<=3&cooldown.mind_blast.remains>0.5*gcd,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and BuffPresent(shadow_word_insanity_buff) Spell(insanity)
	#insanity,chain=1,if=active_enemies<=3&cooldown.mind_blast.remains>0.5*gcd,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() <= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and BuffPresent(shadow_word_insanity_buff) Spell(insanity)
	#mind_spike,if=active_enemies<=5&buff.surge_of_darkness.react=3
	if Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 3 Spell(mind_spike)
	#shadow_word_pain,if=remains<(18*0.35)&miss_react,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.35 and True(miss_react) Spell(shadow_word_pain)
	#vampiric_touch,if=remains<(15*0.35)&miss_react,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.35 and True(miss_react) Spell(vampiric_touch)
	#mind_spike,if=active_enemies<=5&buff.surge_of_darkness.react&cooldown.mind_blast.remains>0.5*gcd
	if Enemies() <= 5 and BuffPresent(surge_of_darkness_buff) and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(mind_spike)
	#mind_sear,chain=1,if=active_enemies>=3&cooldown.mind_blast.remains>0.5*gcd,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(mind_sear)
	#mind_flay,if=cooldown.mind_blast.remains>0.5*gcd,interrupt=1,chain=1
	if SpellCooldown(mind_blast) > 0.5 * GCD() Spell(mind_flay)
	#shadow_word_death,moving=1
	if Speed() > 0 Spell(shadow_word_death)
	#mind_blast,moving=1,if=buff.shadowy_insight.react&cooldown_react
	if Speed() > 0 and BuffPresent(shadowy_insight_buff) and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#shadow_word_pain,moving=1,cycle_targets=1
	if Speed() > 0 Spell(shadow_word_pain)
}

AddFunction ShadowVentShortCdActions
{
	unless ShadowOrbs() == 3 and not target.DebuffPresent(void_entropy_debuff) and target.TimeToDie() > 60 and Enemies() == 1 and Spell(void_entropy) or DebuffCountOnAny(void_entropy_debuff) < Enemies() and DebuffCountOnAny(void_entropy_debuff) <= 60 / { SpellCooldownDuration(mind_blast) * 3 * 100 / { 100 + SpellHaste() } } and not target.DebuffPresent(void_entropy_debuff) and ShadowOrbs() == 5 and Enemies() >= 1 and target.TimeToDie() > 60 and Spell(void_entropy) or target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) <= GCD() * 2 and not SpellCooldown(devouring_plague) > 0 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 10 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) < 20 and Spell(devouring_plague) or ShadowOrbs() == 5 and target.DebuffRemaining(void_entropy_debuff) and Spell(devouring_plague)
	{
		#halo,if=talent.halo.enabled&target.distance<=30&active_enemies>=4
		if Talent(halo_talent) and target.Distance() <= 30 and Enemies() >= 4 Spell(halo_caster)

		unless Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() <= 2 and Spell(mind_blast) or Glyph(glyph_of_mind_harvest) and target.MindHarvest() == 0 and ShadowOrbs() >= 3 and Spell(devouring_plague) or Enemies() <= 10 and not SpellCooldown(mind_blast) > 0 and ShadowOrbs() <= 4 and Spell(mind_blast) or target.HealthPercent() < 20 and not SpellCooldown(shadow_word_death) > 0 and ShadowOrbs() <= 4 and Spell(shadow_word_death) or ShadowOrbs() == 4 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.5 and ArmorSetBonus(T17 2) and SpellCooldown(mind_blast) < 1.2 * GCD() and SpellCooldown(mind_blast) > 0.2 * GCD() and Spell(shadow_word_pain) or BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and BuffPresent(shadow_word_insanity_buff) and Spell(insanity) or Enemies() <= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and BuffPresent(shadow_word_insanity_buff) and Spell(insanity) or Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 3 and Spell(mind_spike) or DebuffCountOnAny(shadow_word_pain_debuff) < Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.35 and True(miss_react) and Spell(shadow_word_pain) or DebuffCountOnAny(vampiric_touch_debuff) < Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.35 and True(miss_react) and Spell(vampiric_touch)
		{
			#halo,if=talent.halo.enabled&target.distance<=30&cooldown.mind_blast.remains>0.5*gcd
			if Talent(halo_talent) and target.Distance() <= 30 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(halo_caster)
			#cascade,if=talent.cascade.enabled&target.distance<=40&cooldown.mind_blast.remains>0.5*gcd
			if Talent(cascade_talent) and target.Distance() <= 40 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(cascade_caster)
			#divine_star,if=talent.divine_star.enabled&active_enemies>4&target.distance<=24&cooldown.mind_blast.remains>0.5*gcd
			if Talent(divine_star_talent) and Enemies() > 4 and target.Distance() <= 24 and SpellCooldown(mind_blast) > 0.5 * GCD() Spell(divine_star_caster)

			unless Enemies() <= 5 and BuffPresent(surge_of_darkness_buff) and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(mind_spike) or Enemies() >= 3 and SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(mind_sear) or SpellCooldown(mind_blast) > 0.5 * GCD() and Spell(mind_flay) or Speed() > 0 and Spell(shadow_word_death) or Speed() > 0 and BuffPresent(shadowy_insight_buff) and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast)
			{
				#divine_star,moving=1,if=talent.divine_star.enabled&target.distance<=28
				if Speed() > 0 and Talent(divine_star_talent) and target.Distance() <= 28 Spell(divine_star_caster)
				#cascade,moving=1,if=talent.cascade.enabled&target.distance<=40
				if Speed() > 0 and Talent(cascade_talent) and target.Distance() <= 40 Spell(cascade_caster)
			}
		}
	}
}

AddFunction ShadowVentCdActions
{
	#mindbender,if=talent.mindbender.enabled&cooldown.mind_blast.remains>=gcd
	if Talent(mindbender_talent) and SpellCooldown(mind_blast) >= GCD() Spell(mindbender)
	#shadowfiend,if=!talent.mindbender.enabled&cooldown.mind_blast.remains>=gcd
	if not Talent(mindbender_talent) and SpellCooldown(mind_blast) >= GCD() Spell(shadowfiend)
}
]]
	OvaleScripts:RegisterScript("PRIEST", name, desc, code, "include")
end

do
	local name = "Ovale"	-- The default script.
	local desc = "[6.0] Ovale: Shadow"
	local code = [[
# Ovale priest script based on SimulationCraft.

# Priest rotation functions.
Include(ovale_priest)

### Shadow icons.
AddCheckBox(opt_priest_shadow_aoe L(AOE) specialization=shadow default)

AddIcon specialization=shadow help=shortcd enemies=1 checkbox=!opt_priest_shadow_aoe
{
	ShadowDefaultShortCdActions()
}

AddIcon specialization=shadow help=shortcd checkbox=opt_priest_shadow_aoe
{
	ShadowDefaultShortCdActions()
}

AddIcon specialization=shadow help=main enemies=1
{
	if not InCombat() ShadowPrecombatMainActions()
	ShadowDefaultMainActions()
}

AddIcon specialization=shadow help=aoe checkbox=opt_priest_shadow_aoe
{
	if not InCombat() ShadowPrecombatMainActions()
	ShadowDefaultMainActions()
}

AddIcon specialization=shadow help=cd enemies=1 checkbox=!opt_priest_shadow_aoe
{
	if not InCombat() ShadowPrecombatCdActions()
	ShadowDefaultCdActions()
}

AddIcon specialization=shadow help=cd checkbox=opt_priest_shadow_aoe
{
	if not InCombat() ShadowPrecombatCdActions()
	ShadowDefaultCdActions()
}
]]
	OvaleScripts:RegisterScript("PRIEST", name, desc, code, "script")
end
