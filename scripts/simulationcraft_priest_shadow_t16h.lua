local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Priest_Shadow_T16H"
	local desc = "[5.4] SimulationCraft: Priest_Shadow_T16H" 
	local code = [[
# Based on SimulationCraft profile "Priest_Shadow_T16H".
#	class=priest
#	spec=shadow
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Xb!002202
#	glyphs=inner_sanctum/mind_flay/dark_archangel/shadowy_friends/shadow_ravens

Include(ovale_items)
Include(ovale_racials)
Include(ovale_priest_spells)

AddFunction ShadowDefaultActions
{
	#shadowform
	if not Stance(priest_shadowform) Spell(shadowform)
	#use_item,slot=hands
	UseItemActions()
	#jade_serpent_potion,if=buff.bloodlust.react|target.time_to_die<=40
	if BuffPresent(burst_haste any=1) or target.TimeToDie() <= 40 UsePotionIntellect()
	#mindbender,if=talent.mindbender.enabled
	if TalentPoints(mindbender_talent) Spell(mindbender)
	#shadowfiend,if=!talent.mindbender.enabled
	if not TalentPoints(mindbender_talent) Spell(shadowfiend)
	#power_infusion,if=talent.power_infusion.enabled
	if TalentPoints(power_infusion_talent) Spell(power_infusion)
	#blood_fury
	Spell(blood_fury)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=1&active_enemies<=5
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 1 and Enemies() <= 5 Spell(shadow_word_death usable=1)
	#devouring_plague,if=shadow_orb=3&(cooldown.mind_blast.remains<1.5|target.health.pct<20&cooldown.shadow_word_death.remains<1.5)
	if ShadowOrbs() == 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } Spell(devouring_plague)
	#mind_blast,if=active_enemies<=5&cooldown_react
	if Enemies() <= 5 and Spell(mind_blast) Spell(mind_blast)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=0&active_enemies<=5
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 0 and Enemies() <= 5 Spell(shadow_word_death usable=1)
	#mind_flay_insanity,if=target.dot.devouring_plague_tick.ticks_remain=1,chain=1
	if TalentPoints(solace_and_insanity_talent) and target.DebuffPresent(devouring_plague_debuff) and target.TicksRemain(devouring_plague_debuff) == 1 Spell(mind_flay)
	#mind_flay_insanity,interrupt=1,chain=1,if=active_enemies<=5
	if TalentPoints(solace_and_insanity_talent) and target.DebuffPresent(devouring_plague_debuff) and Enemies() <= 5 Spell(mind_flay)
	#shadow_word_pain,cycle_targets=1,max_cycle_targets=5,if=miss_react&!ticking
	if True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 Spell(shadow_word_pain)
	#vampiric_touch,cycle_targets=1,max_cycle_targets=5,if=remains<cast_time&miss_react
	if target.DebuffRemains(vampiric_touch_debuff) < CastTime(vampiric_touch) and True(miss_react) and DebuffCountOnAny(vampiric_touch_debuff) <= 5 Spell(vampiric_touch)
	#shadow_word_pain,cycle_targets=1,max_cycle_targets=5,if=miss_react&ticks_remain<=1
	if True(miss_react) and target.TicksRemain(shadow_word_pain_debuff) <= 1 and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 Spell(shadow_word_pain)
	#vampiric_touch,cycle_targets=1,max_cycle_targets=5,if=remains<cast_time+tick_time&miss_react
	if target.DebuffRemains(vampiric_touch_debuff) < CastTime(vampiric_touch) + target.TickTime(vampiric_touch_debuff) and True(miss_react) and DebuffCountOnAny(vampiric_touch_debuff) <= 5 Spell(vampiric_touch)
	#vampiric_embrace,if=shadow_orb=3&health.pct<=40
	if ShadowOrbs() == 3 and HealthPercent() <= 40 Spell(vampiric_embrace)
	#devouring_plague,if=shadow_orb=3&ticks_remain<=1
	if ShadowOrbs() == 3 and target.TicksRemain(devouring_plague_debuff) <= 1 Spell(devouring_plague)
	#mind_spike,if=active_enemies<=5&buff.surge_of_darkness.react=2
	if Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 2 Spell(mind_spike)
	#halo,if=talent.halo.enabled&target.distance<=30&target.distance>=17
	if TalentPoints(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo)
	#cascade_damage,if=talent.cascade.enabled&(active_enemies>1|(target.distance>=25&stat.mastery_rating<15000)|target.distance>=28)&target.distance<=40&target.distance>=11
	if TalentPoints(cascade_talent) and { Enemies() > 1 or { target.Distance() >= 25 and MasteryRating() < 15000 } or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade_damage)
	#divine_star,if=talent.divine_star.enabled&(active_enemies>1|stat.mastery_rating<3500)&target.distance<=24
	if TalentPoints(divine_star_talent) and { Enemies() > 1 or MasteryRating() < 3500 } and target.Distance() <= 24 Spell(divine_star)
	#wait,sec=cooldown.shadow_word_death.remains,if=target.health.pct<20&cooldown.shadow_word_death.remains<0.5&active_enemies<=1
	if target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 0.5 and Enemies() <= 1 wait Spell(shadow_word_death)
	#wait,sec=cooldown.mind_blast.remains,if=cooldown.mind_blast.remains<0.5&active_enemies<=1
	if SpellCooldown(mind_blast) < 0.5 and Enemies() <= 1 wait Spell(mind_blast)
	#mind_spike,if=buff.surge_of_darkness.react&active_enemies<=5
	if BuffStacks(surge_of_darkness_buff) and Enemies() <= 5 Spell(mind_spike)
	#mind_sear,chain=1,interrupt=1,if=active_enemies>=3
	if Enemies() >= 3 Spell(mind_sear)
	#mind_flay,chain=1,interrupt=1
	Spell(mind_flay)
	#shadow_word_death,moving=1
	if Speed() > 0 Spell(shadow_word_death usable=1)
	#mind_blast,moving=1,if=buff.divine_insight_shadow.react&cooldown_react
	if Speed() > 0 and BuffPresent(divine_insight_shadow_buff) and Spell(mind_blast) Spell(mind_blast)
	#divine_star,moving=1,if=talent.divine_star.enabled&target.distance<=28
	if Speed() > 0 and TalentPoints(divine_star_talent) and target.Distance() <= 28 Spell(divine_star)
	#cascade_damage,moving=1,if=talent.cascade.enabled&target.distance<=40
	if Speed() > 0 and TalentPoints(cascade_talent) and target.Distance() <= 40 Spell(cascade_damage)
	#shadow_word_pain,moving=1
	if Speed() > 0 Spell(shadow_word_pain)
	#dispersion
	Spell(dispersion)
}

AddFunction ShadowPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#power_word_fortitude,if=!aura.stamina.up
	if not BuffPresent(stamina any=1) Spell(power_word_fortitude)
	#inner_fire
	if BuffExpires(inner_fire_buff) Spell(inner_fire)
	#shadowform
	if not Stance(priest_shadowform) Spell(shadowform)
	#snapshot_stats
	#jade_serpent_potion
	UsePotionIntellect()
}

AddIcon mastery=shadow help=main
{
	if InCombat(no) ShadowPrecombatActions()
	ShadowDefaultActions()
}

### Required symbols
# arcane_torrent_mana
# berserking
# blood_fury
# cascade_damage
# cascade_talent
# devouring_plague
# devouring_plague_debuff
# dispersion
# divine_insight_shadow_buff
# divine_star
# divine_star_talent
# halo
# halo_talent
# inner_fire
# inner_fire_buff
# jade_serpent_potion
# mind_blast
# mind_flay
# mind_flay_insanity
# mind_sear
# mind_spike
# mindbender
# mindbender_talent
# power_infusion
# power_infusion_talent
# power_word_fortitude
# shadow_word_death
# shadow_word_death_reset_cooldown_buff
# shadow_word_pain
# shadow_word_pain_debuff
# shadowfiend
# shadowform
# solace_and_insanity_talent
# stamina
# surge_of_darkness_buff
# vampiric_embrace
# vampiric_touch
# vampiric_touch_debuff
]]
	OvaleScripts:RegisterScript("PRIEST", name, desc, code, "reference")
end