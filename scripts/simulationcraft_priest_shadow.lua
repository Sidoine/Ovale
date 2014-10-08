local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Priest_Shadow_T16M"
	local desc = "[6.0.2] SimulationCraft: Priest_Shadow_T16M"
	local code = [[
# Based on SimulationCraft profile "Priest_Shadow_T16M".
#	class=priest
#	spec=shadow
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Xb!002202.
#	glyphs=mind_flay/fade/sha

Include(ovale_common)
Include(ovale_priest_spells)

AddCheckBox(opt_potion_intellect ItemName(jade_serpent_potion) default)

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(jade_serpent_potion usable=1)
}

AddFunction ShadowCopActions
{
	#devouring_plague,if=shadow_orb>=3&(cooldown.mind_blast.remains<=gcd*1.0|cooldown.shadow_word_death.remains<=gcd*1.0)&primary_target=0,cycle_targets=1
	if ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) <= GCD() * 1 or SpellCooldown(shadow_word_death) <= GCD() * 1 } and 0 == 0 Spell(devouring_plague)
	#devouring_plague,if=shadow_orb>=3&(cooldown.mind_blast.remains<=gcd*1.0|cooldown.shadow_word_death.remains<=gcd*1.0)
	if ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) <= GCD() * 1 or SpellCooldown(shadow_word_death) <= GCD() * 1 } Spell(devouring_plague)
	#mind_blast,if=mind_harvest=0,cycle_targets=1
	if 0 == 0 Spell(mind_blast)
	#mind_blast,if=active_enemies<=5&cooldown_react
	if Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=1,cycle_targets=1
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 1 Spell(shadow_word_death)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=0,cycle_targets=1
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 0 Spell(shadow_word_death)
	#mindbender,if=talent.mindbender.enabled
	if Talent(mindbender_talent) Spell(mindbender)
	#shadowfiend,if=!talent.mindbender.enabled
	if not Talent(mindbender_talent) Spell(shadowfiend)
	#halo,if=talent.halo.enabled&target.distance<=30&target.distance>=17
	if Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo)
	#cascade,if=talent.cascade.enabled&((active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11)
	if Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade)
	#divine_star,if=talent.divine_star.enabled&(active_enemies>1|target.distance<=24)
	if Talent(divine_star_talent) and { Enemies() > 1 or target.Distance() <= 24 } Spell(divine_star)
	#shadow_word_pain,if=miss_react&!ticking&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) and 0 == 0 Spell(shadow_word_pain)
	#vampiric_touch,if=remains<cast_time&miss_react&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) <= Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < CastTime(vampiric_touch) and True(miss_react) and 0 == 0 Spell(vampiric_touch)
	#mind_sear,if=active_enemies>=3,chain=1,interrupt=1
	if Enemies() >= 3 Spell(mind_sear)
	#mind_spike,if=active_enemies<=8&buff.surge_of_darkness.react
	if Enemies() <= 8 and BuffPresent(surge_of_darkness_buff) Spell(mind_spike)
	#mind_sear,if=active_enemies>=3,chain=1,interrupt=1
	if Enemies() >= 3 Spell(mind_sear)
	#mind_flay,if=target.dot.devouring_plague_tick.ticks_remain>1&active_enemies=1,chain=1,interrupt=1
	if target.TicksRemaining(devouring_plague_debuff) > 1 and Enemies() == 1 Spell(mind_flay)
	#mind_spike
	Spell(mind_spike)
	#shadow_word_death,moving=1
	if Speed() > 0 Spell(shadow_word_death)
	#mind_blast,if=buff.shadowy_insight.react&cooldown_react,moving=1
	if BuffPresent(shadowy_insight_buff) and not SpellCooldown(mind_blast) > 0 and Speed() > 0 Spell(mind_blast)
	#halo,moving=1,if=talent.halo.enabled&target.distance<=30
	if Speed() > 0 and Talent(halo_talent) and target.Distance() <= 30 Spell(halo)
	#divine_star,if=talent.divine_star.enabled&target.distance<=28,moving=1
	if Talent(divine_star_talent) and target.Distance() <= 28 and Speed() > 0 Spell(divine_star)
	#cascade,if=talent.cascade.enabled&target.distance<=40,moving=1
	if Talent(cascade_talent) and target.Distance() <= 40 and Speed() > 0 Spell(cascade)
	#shadow_word_pain,if=primary_target=0,moving=1,cycle_targets=1
	if Speed() > 0 and 0 == 0 Spell(shadow_word_pain)
}

AddFunction ShadowDefaultActions
{
	#shadowform,if=!buff.shadowform.up
	if not BuffPresent(shadowform_buff) and not Stance(priest_shadowform) Spell(shadowform)
	#potion,name=jade_serpent,if=buff.bloodlust.react|target.time_to_die<=40
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
	if ArmorSetBonus(PVP 2) ShadowPvpDispersionActions()
	#call_action_list,name=decision
	ShadowDecisionActions()
}

AddFunction ShadowCopAdvancedMfiActions
{
	#mind_blast,if=mind_harvest=0,cycle_targets=1
	if 0 == 0 Spell(mind_blast)
	#mind_blast,if=active_enemies<=5&cooldown_react
	if Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=1,cycle_targets=1
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 1 Spell(shadow_word_death)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=0,cycle_targets=1
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 0 Spell(shadow_word_death)
	#mindbender,if=talent.mindbender.enabled
	if Talent(mindbender_talent) Spell(mindbender)
	#shadowfiend,if=!talent.mindbender.enabled
	if not Talent(mindbender_talent) Spell(shadowfiend)
	#halo,if=talent.halo.enabled&target.distance<=30&target.distance>=17
	if Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo)
	#cascade,if=talent.cascade.enabled&((active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11)
	if Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade)
	#divine_star,if=talent.divine_star.enabled&(active_enemies>1|target.distance<=24)
	if Talent(divine_star_talent) and { Enemies() > 1 or target.Distance() <= 24 } Spell(divine_star)
	#shadow_word_pain,if=remains<(18*0.3)&miss_react&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and True(miss_react) and 0 == 0 Spell(shadow_word_pain)
	#vampiric_touch,if=remains<(15*0.3+cast_time)&miss_react&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) <= Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and True(miss_react) and 0 == 0 Spell(vampiric_touch)
	#mind_sear,if=active_enemies>=6,chain=1,interrupt=1
	if Enemies() >= 6 Spell(mind_sear)
	#mind_spike
	Spell(mind_spike)
	#shadow_word_death,moving=1
	if Speed() > 0 Spell(shadow_word_death)
	#mind_blast,if=buff.shadowy_insight.react&cooldown_react,moving=1
	if BuffPresent(shadowy_insight_buff) and not SpellCooldown(mind_blast) > 0 and Speed() > 0 Spell(mind_blast)
	#halo,if=talent.halo.enabled&target.distance<=30,moving=1
	if Talent(halo_talent) and target.Distance() <= 30 and Speed() > 0 Spell(halo)
	#divine_star,if=talent.divine_star.enabled&target.distance<=28,moving=1
	if Talent(divine_star_talent) and target.Distance() <= 28 and Speed() > 0 Spell(divine_star)
	#cascade,if=talent.cascade.enabled&target.distance<=40,moving=1
	if Talent(cascade_talent) and target.Distance() <= 40 and Speed() > 0 Spell(cascade)
	#shadow_word_pain,if=primary_target=0,moving=1,cycle_targets=1
	if Speed() > 0 and 0 == 0 Spell(shadow_word_pain)
}

AddFunction ShadowDecisionActions
{
	#call_action_list,name=cop_advanced_mfi_dots,if=target.health.pct>=20&(shadow_orb>=4|target.dot.shadow_word_pain.ticking|target.dot.vampiric_touch.ticking|target.dot.devouring_plague.ticking)&talent.clarity_of_power.enabled&talent.insanity.enabled&active_enemies<=2
	if target.HealthPercent() >= 20 and { ShadowOrbs() >= 4 or target.DebuffPresent(shadow_word_pain_debuff) or target.DebuffPresent(vampiric_touch_debuff) or target.DebuffPresent(devouring_plague_debuff) } and Talent(clarity_of_power_talent) and Talent(insanity_talent) and Enemies() <= 2 ShadowCopAdvancedMfiDotsActions()
	#call_action_list,name=cop_advanced_mfi,if=target.health.pct>=20&talent.clarity_of_power.enabled&talent.insanity.enabled&active_enemies<=2
	if target.HealthPercent() >= 20 and Talent(clarity_of_power_talent) and Talent(insanity_talent) and Enemies() <= 2 ShadowCopAdvancedMfiActions()
	#call_action_list,name=cop_mfi,if=talent.clarity_of_power.enabled&talent.insanity.enabled&active_enemies<=2
	if Talent(clarity_of_power_talent) and Talent(insanity_talent) and Enemies() <= 2 ShadowCopMfiActions()
	#call_action_list,name=cop,if=talent.clarity_of_power.enabled&(active_enemies<=2|target.health.pct<20)
	if Talent(clarity_of_power_talent) and { Enemies() <= 2 or target.HealthPercent() < 20 } ShadowCopActions()
	#call_action_list,name=main
	ShadowMainActions()
}

AddFunction ShadowCopAdvancedMfiDotsActions
{
	#mind_spike,if=(target.dot.shadow_word_pain.ticking&target.dot.shadow_word_pain.remains<gcd*0.5)|(target.dot.vampiric_touch.ticking&target.dot.vampiric_touch.remains<gcd*0.5)
	if target.DebuffPresent(shadow_word_pain_debuff) and target.DebuffRemaining(shadow_word_pain_debuff) < GCD() * 0.5 or target.DebuffPresent(vampiric_touch_debuff) and target.DebuffRemaining(vampiric_touch_debuff) < GCD() * 0.5 Spell(mind_spike)
	#shadow_word_pain,if=!ticking&miss_react&!target.dot.vampiric_touch.ticking
	if not target.DebuffPresent(shadow_word_pain_debuff) and True(miss_react) and not target.DebuffPresent(vampiric_touch_debuff) Spell(shadow_word_pain)
	#vampiric_touch,if=!ticking&miss_react
	if not target.DebuffPresent(vampiric_touch_debuff) and True(miss_react) Spell(vampiric_touch)
	#mind_blast
	Spell(mind_blast)
	#devouring_plague,if=shadow_orb>=3&target.dot.shadow_word_pain.ticking&target.dot.vampiric_touch.ticking
	if ShadowOrbs() >= 3 and target.DebuffPresent(shadow_word_pain_debuff) and target.DebuffPresent(vampiric_touch_debuff) Spell(devouring_plague)
	#insanity,if=buff.shadow_word_insanity.remains<0.5*gcd&active_enemies<=2,chain=1
	if BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 Spell(insanity)
	#insanity,if=active_enemies<=2,interrupt=1,chain=1
	if Enemies() <= 2 Spell(insanity)
	#mind_spike,if=(target.dot.shadow_word_pain.ticking&target.dot.shadow_word_pain.remains<gcd*2)|(target.dot.vampiric_touch.ticking&target.dot.vampiric_touch.remains<gcd*2)
	if target.DebuffPresent(shadow_word_pain_debuff) and target.DebuffRemaining(shadow_word_pain_debuff) < GCD() * 2 or target.DebuffPresent(vampiric_touch_debuff) and target.DebuffRemaining(vampiric_touch_debuff) < GCD() * 2 Spell(mind_spike)
	#mind_flay,chain=1,interrupt=1
	Spell(mind_flay)
}

AddFunction ShadowMainActions
{
	#mindbender,if=talent.mindbender.enabled
	if Talent(mindbender_talent) Spell(mindbender)
	#shadowfiend,if=!talent.mindbender.enabled
	if not Talent(mindbender_talent) Spell(shadowfiend)
	#void_entropy,if=talent.void_entropy.enabled&shadow_orb>=3&miss_react&!ticking&target.time_to_die>60&cooldown.mind_blast.remains<=gcd*2,cycle_targets=1,max_cycle_targets=3
	if DebuffCountOnAny(void_entropy_debuff) <= Enemies() and DebuffCountOnAny(void_entropy_debuff) <= 3 and Talent(void_entropy_talent) and ShadowOrbs() >= 3 and True(miss_react) and not target.DebuffPresent(void_entropy_debuff) and target.TimeToDie() > 60 and SpellCooldown(mind_blast) <= GCD() * 2 Spell(void_entropy)
	#devouring_plague,if=talent.void_entropy.enabled&shadow_orb>=3&dot.void_entropy.ticking&dot.void_entropy.remains<10,cycle_targets=1,max_cycle_targets=3
	if DebuffCountOnAny(devouring_plague_debuff) <= Enemies() and DebuffCountOnAny(devouring_plague_debuff) <= 3 and Talent(void_entropy_talent) and ShadowOrbs() >= 3 and target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) < 10 Spell(devouring_plague)
	#devouring_plague,if=talent.void_entropy.enabled&shadow_orb>=3&dot.void_entropy.ticking&dot.void_entropy.remains<20,cycle_targets=1,max_cycle_targets=3
	if DebuffCountOnAny(devouring_plague_debuff) <= Enemies() and DebuffCountOnAny(devouring_plague_debuff) <= 3 and Talent(void_entropy_talent) and ShadowOrbs() >= 3 and target.DebuffPresent(void_entropy_debuff) and target.DebuffRemaining(void_entropy_debuff) < 20 Spell(devouring_plague)
	#devouring_plague,if=talent.void_entropy.enabled&shadow_orb=5
	if Talent(void_entropy_talent) and ShadowOrbs() == 5 Spell(devouring_plague)
	#devouring_plague,if=!talent.void_entropy.enabled&shadow_orb>=4&!target.dot.devouring_plague_tick.ticking&talent.surge_of_darkness.enabled,cycle_targets=1
	if not Talent(void_entropy_talent) and ShadowOrbs() >= 4 and not target.DebuffPresent(devouring_plague_debuff) and Talent(surge_of_darkness_talent) Spell(devouring_plague)
	#devouring_plague,if=!talent.void_entropy.enabled&((shadow_orb>=4)|(shadow_orb>=3&set_bonus.tier17_2pc))
	if not Talent(void_entropy_talent) and { ShadowOrbs() >= 4 or ShadowOrbs() >= 3 and ArmorSetBonus(T17 2) } Spell(devouring_plague)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=1,cycle_targets=1
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 1 Spell(shadow_word_death)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=0,cycle_targets=1
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 0 Spell(shadow_word_death)
	#mind_blast,if=!glyph.mind_harvest.enabled&active_enemies<=5&cooldown_react
	if not Glyph(glyph_of_mind_harvest) and Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#devouring_plague,if=!talent.void_entropy.enabled&shadow_orb>=3&(cooldown.mind_blast.remains<1.5|target.health.pct<20&cooldown.shadow_word_death.remains<1.5)&!target.dot.devouring_plague_tick.ticking&talent.surge_of_darkness.enabled,cycle_targets=1
	if not Talent(void_entropy_talent) and ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } and not target.DebuffPresent(devouring_plague_debuff) and Talent(surge_of_darkness_talent) Spell(devouring_plague)
	#devouring_plague,if=!talent.void_entropy.enabled&shadow_orb>=3&(cooldown.mind_blast.remains<1.5|target.health.pct<20&cooldown.shadow_word_death.remains<1.5)
	if not Talent(void_entropy_talent) and ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } Spell(devouring_plague)
	#mind_blast,if=glyph.mind_harvest.enabled&mind_harvest=0,cycle_targets=1
	if Glyph(glyph_of_mind_harvest) and 0 == 0 Spell(mind_blast)
	#mind_blast,if=active_enemies<=5&cooldown_react
	if Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#insanity,if=buff.shadow_word_insanity.remains<0.5*gcd&active_enemies<=2,chain=1
	if BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 Spell(insanity)
	#insanity,interrupt=1,chain=1,if=active_enemies<=2
	if Enemies() <= 2 Spell(insanity)
	#halo,if=talent.halo.enabled&target.distance<=30&active_enemies>2
	if Talent(halo_talent) and target.Distance() <= 30 and Enemies() > 2 Spell(halo)
	#cascade,if=talent.cascade.enabled&active_enemies>2&target.distance<=40
	if Talent(cascade_talent) and Enemies() > 2 and target.Distance() <= 40 Spell(cascade)
	#divine_star,if=talent.divine_star.enabled&active_enemies>4&target.distance<=24
	if Talent(divine_star_talent) and Enemies() > 4 and target.Distance() <= 24 Spell(divine_star)
	#shadow_word_pain,if=talent.auspicious_spirits.enabled&remains<(18*0.3)&miss_react,cycle_targets=1
	if Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and True(miss_react) Spell(shadow_word_pain)
	#shadow_word_pain,if=!talent.auspicious_spirits.enabled&remains<(18*0.3)&miss_react,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and not Talent(auspicious_spirits_talent) and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and True(miss_react) Spell(shadow_word_pain)
	#vampiric_touch,if=remains<(15*0.3+cast_time)&miss_react,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) <= Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and True(miss_react) Spell(vampiric_touch)
	#devouring_plague,if=!talent.void_entropy.enabled&shadow_orb>=3&ticks_remain<=1
	if not Talent(void_entropy_talent) and ShadowOrbs() >= 3 and target.TicksRemaining(devouring_plague_debuff) < 2 Spell(devouring_plague)
	#mind_spike,if=active_enemies<=5&buff.surge_of_darkness.react=3
	if Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 3 Spell(mind_spike)
	#halo,if=talent.halo.enabled&target.distance<=30&target.distance>=17
	if Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo)
	#cascade,if=talent.cascade.enabled&((active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11)
	if Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade)
	#divine_star,if=talent.divine_star.enabled&(active_enemies>1|target.distance<=24)
	if Talent(divine_star_talent) and { Enemies() > 1 or target.Distance() <= 24 } Spell(divine_star)
	#wait,sec=cooldown.shadow_word_death.remains,if=target.health.pct<20&cooldown.shadow_word_death.remains&cooldown.shadow_word_death.remains<0.5&active_enemies<=1
	unless target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) and SpellCooldown(shadow_word_death) < 0.5 and Enemies() <= 1 and SpellCooldown(shadow_word_death) > 0
	{
		#wait,sec=cooldown.mind_blast.remains,if=cooldown.mind_blast.remains<0.5&cooldown.mind_blast.remains&active_enemies<=1
		unless SpellCooldown(mind_blast) < 0.5 and SpellCooldown(mind_blast) and Enemies() <= 1 and SpellCooldown(mind_blast) > 0
		{
			#mind_spike,if=buff.surge_of_darkness.react&active_enemies<=5
			if BuffPresent(surge_of_darkness_buff) and Enemies() <= 5 Spell(mind_spike)
			#divine_star,if=talent.divine_star.enabled&target.distance<=28&active_enemies>1
			if Talent(divine_star_talent) and target.Distance() <= 28 and Enemies() > 1 Spell(divine_star)
			#mind_sear,chain=1,interrupt=1,if=active_enemies>=4
			if Enemies() >= 4 Spell(mind_sear)
			#shadow_word_pain,if=shadow_orb>=2&ticks_remain<=3&talent.insanity.enabled
			if ShadowOrbs() >= 2 and target.TicksRemaining(shadow_word_pain_debuff) < 4 and Talent(insanity_talent) Spell(shadow_word_pain)
			#vampiric_touch,if=shadow_orb>=2&ticks_remain<=3.5&talent.insanity.enabled
			if ShadowOrbs() >= 2 and target.TicksRemaining(vampiric_touch_debuff) < 4.5 and Talent(insanity_talent) Spell(vampiric_touch)
			#mind_flay,chain=1,interrupt=1
			Spell(mind_flay)
			#shadow_word_death,moving=1
			if Speed() > 0 Spell(shadow_word_death)
			#mind_blast,moving=1,if=buff.shadowy_insight.react&cooldown_react
			if Speed() > 0 and BuffPresent(shadowy_insight_buff) and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
			#divine_star,moving=1,if=talent.divine_star.enabled&target.distance<=28
			if Speed() > 0 and Talent(divine_star_talent) and target.Distance() <= 28 Spell(divine_star)
			#cascade,moving=1,if=talent.cascade.enabled&target.distance<=40
			if Speed() > 0 and Talent(cascade_talent) and target.Distance() <= 40 Spell(cascade)
			#shadow_word_pain,moving=1,cycle_targets=1
			if Speed() > 0 Spell(shadow_word_pain)
		}
	}
}

AddFunction ShadowPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#power_word_fortitude,if=!aura.stamina.up
	if not BuffPresent(stamina_buff any=1) Spell(power_word_fortitude)
	#shadowform,if=!buff.shadowform.up
	if not BuffPresent(shadowform_buff) and not Stance(priest_shadowform) Spell(shadowform)
	#snapshot_stats
	#potion,name=jade_serpent
	UsePotionIntellect()
	#mind_blast
	Spell(mind_blast)
}

AddFunction ShadowPvpDispersionActions
{
	#call_action_list,name=decision,if=cooldown.dispersion.remains>0
	if SpellCooldown(dispersion) > 0 ShadowDecisionActions()
	#dispersion,interrupt=1
	Spell(dispersion)
	#call_action_list,name=decision
	ShadowDecisionActions()
}

AddFunction ShadowCopMfiActions
{
	#devouring_plague,if=shadow_orb=5
	if ShadowOrbs() == 5 Spell(devouring_plague)
	#mind_blast,if=mind_harvest=0,cycle_targets=1
	if 0 == 0 Spell(mind_blast)
	#mind_blast,if=active_enemies<=5&cooldown_react
	if Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=1,cycle_targets=1
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 1 Spell(shadow_word_death)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=0,cycle_targets=1
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 0 Spell(shadow_word_death)
	#devouring_plague,if=shadow_orb>=3&(cooldown.mind_blast.remains<1.5|target.health.pct<20&cooldown.shadow_word_death.remains<1.5)
	if ShadowOrbs() >= 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } Spell(devouring_plague)
	#mindbender,if=talent.mindbender.enabled
	if Talent(mindbender_talent) Spell(mindbender)
	#shadowfiend,if=!talent.mindbender.enabled
	if not Talent(mindbender_talent) Spell(shadowfiend)
	#insanity,if=buff.shadow_word_insanity.remains<0.5*gcd&active_enemies<=2,chain=1
	if BuffRemaining(shadow_word_insanity_buff) < 0.5 * GCD() and Enemies() <= 2 Spell(insanity)
	#insanity,if=active_enemies<=2,interrupt=1,chain=1
	if Enemies() <= 2 Spell(insanity)
	#halo,if=talent.halo.enabled&target.distance<=30&target.distance>=17
	if Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo)
	#cascade,if=talent.cascade.enabled&((active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11)
	if Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade)
	#divine_star,if=talent.divine_star.enabled&(active_enemies>1|target.distance<=24)
	if Talent(divine_star_talent) and { Enemies() > 1 or target.Distance() <= 24 } Spell(divine_star)
	#shadow_word_pain,if=remains<(18*0.3)&miss_react&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and target.DebuffRemaining(shadow_word_pain_debuff) < 18 * 0.3 and True(miss_react) and 0 == 0 Spell(shadow_word_pain)
	#vampiric_touch,if=remains<(15*0.3+cast_time)&miss_react&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if DebuffCountOnAny(vampiric_touch_debuff) <= Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < 15 * 0.3 + CastTime(vampiric_touch) and True(miss_react) and 0 == 0 Spell(vampiric_touch)
	#mind_sear,if=active_enemies>=6,chain=1,interrupt=1
	if Enemies() >= 6 Spell(mind_sear)
	#mind_spike
	Spell(mind_spike)
	#shadow_word_death,moving=1
	if Speed() > 0 Spell(shadow_word_death)
	#mind_blast,if=buff.shadowy_insight.react&cooldown_react,moving=1
	if BuffPresent(shadowy_insight_buff) and not SpellCooldown(mind_blast) > 0 and Speed() > 0 Spell(mind_blast)
	#halo,if=talent.halo.enabled&target.distance<=30,moving=1
	if Talent(halo_talent) and target.Distance() <= 30 and Speed() > 0 Spell(halo)
	#divine_star,if=talent.divine_star.enabled&target.distance<=28,moving=1
	if Talent(divine_star_talent) and target.Distance() <= 28 and Speed() > 0 Spell(divine_star)
	#cascade,if=talent.cascade.enabled&target.distance<=40,moving=1
	if Talent(cascade_talent) and target.Distance() <= 40 and Speed() > 0 Spell(cascade)
	#shadow_word_pain,if=primary_target=0,moving=1,cycle_targets=1
	if Speed() > 0 and 0 == 0 Spell(shadow_word_pain)
}

AddIcon specialization=shadow help=main enemies=1
{
	if InCombat(no) ShadowPrecombatActions()
	ShadowDefaultActions()
}

AddIcon specialization=shadow help=aoe
{
	if InCombat(no) ShadowPrecombatActions()
	ShadowDefaultActions()
}

### Required symbols
# arcane_torrent_mana
# auspicious_spirits_talent
# berserking
# blood_fury_sp
# cascade
# cascade_talent
# clarity_of_power_talent
# devouring_plague
# devouring_plague_debuff
# dispersion
# divine_star
# divine_star_talent
# glyph_of_mind_harvest
# halo
# halo_talent
# insanity
# insanity_talent
# jade_serpent_potion
# mind_blast
# mind_flay
# mind_sear
# mind_spike
# mindbender
# mindbender_talent
# power_infusion
# power_infusion_talent
# power_word_fortitude
# shadow_word_death
# shadow_word_death_reset_cooldown_buff
# shadow_word_insanity_buff
# shadow_word_pain
# shadow_word_pain_debuff
# shadowfiend
# shadowform
# shadowform_buff
# shadowy_insight_buff
# surge_of_darkness_buff
# surge_of_darkness_talent
# vampiric_touch
# vampiric_touch_debuff
# void_entropy
# void_entropy_debuff
# void_entropy_talent
]]
	OvaleScripts:RegisterScript("PRIEST", name, desc, code, "reference")
end
