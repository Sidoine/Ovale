local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_priest"
	local desc = "[5.4.8] Ovale: Shadow"
	local code = [[
# Ovale shadow script based on SimulationCraft.

Include(ovale_common)
Include(ovale_priest_spells)

AddCheckBox(opt_potion_intellect ItemName(jade_serpent_potion) default)

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(jade_serpent_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction InterruptActions
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		Spell(silence)
		if target.Classification(worldboss no)
		{
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

###
### Shadow
###
# Based on SimulationCraft profile "Priest_Shadow_T16H".
#	class=priest
#	spec=shadow
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Xb!002202
#	glyphs=inner_sanctum/mind_flay/dark_archangel/shadowy_friends/shadow_ravens

# ActionList: ShadowPrecombatActions --> main, moving, shortcd, cd

AddFunction ShadowPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#power_word_fortitude,if=!aura.stamina.up
	if not BuffPresent(stamina_buff any=1) Spell(power_word_fortitude)
	#inner_fire
	if BuffExpires(inner_fire_buff) Spell(inner_fire)
	#shadowform
	if not Stance(priest_shadowform) Spell(shadowform)
	#snapshot_stats
}

AddFunction ShadowPrecombatMovingActions
{
	ShadowPrecombatActions()
}

AddFunction ShadowPrecombatShortCdActions {}

AddFunction ShadowPrecombatCdActions
{
	unless not BuffPresent(stamina_buff any=1) and Spell(power_word_fortitude)
		or BuffExpires(inner_fire_buff) and Spell(inner_fire)
		or not Stance(priest_shadowform) and Spell(shadowform)
	{
		#jade_serpent_potion
		UsePotionIntellect()
	}
}

# ActionList: ShadowDefaultActions --> main, moving, shortcd, cd

AddFunction ShadowDefaultActions
{
	#shadowform
	if not Stance(priest_shadowform) Spell(shadowform)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=1&active_enemies<=5
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 1 and Enemies() <= 5 and { Glyph(glyph_of_shadow_word_death) or target.HealthPercent() < 20 } Spell(shadow_word_death)
	#devouring_plague,if=shadow_orb=3&(cooldown.mind_blast.remains<1.5|target.health.pct<20&cooldown.shadow_word_death.remains<1.5)
	if ShadowOrbs() == 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } Spell(devouring_plague)
	#mind_blast,if=active_enemies<=5&cooldown_react
	if Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=0&active_enemies<=5
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 0 and Enemies() <= 5 and { Glyph(glyph_of_shadow_word_death) or target.HealthPercent() < 20 } Spell(shadow_word_death)
	#mind_flay_insanity,if=target.dot.devouring_plague_tick.ticks_remain=1,chain=1
	if target.TicksRemaining(devouring_plague_debuff) < 2 and Talent(solace_and_insanity_talent) and target.DebuffPresent(devouring_plague_debuff) Spell(mind_flay)
	#mind_flay_insanity,interrupt=1,chain=1,if=active_enemies<=5
	if Enemies() <= 5 and Talent(solace_and_insanity_talent) and target.DebuffPresent(devouring_plague_debuff) Spell(mind_flay)
	#shadow_word_pain,cycle_targets=1,max_cycle_targets=5,if=miss_react&!ticking
	if DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) Spell(shadow_word_pain)
	#vampiric_touch,cycle_targets=1,max_cycle_targets=5,if=remains<cast_time&miss_react
	if DebuffCountOnAny(vampiric_touch_debuff) <= Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < CastTime(vampiric_touch) and True(miss_react) Spell(vampiric_touch)
	#shadow_word_pain,cycle_targets=1,max_cycle_targets=5,if=miss_react&ticks_remain<=1
	if DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and True(miss_react) and target.TicksRemaining(shadow_word_pain_debuff) < 2 Spell(shadow_word_pain)
	#vampiric_touch,cycle_targets=1,max_cycle_targets=5,if=remains<cast_time+tick_time&miss_react
	if DebuffCountOnAny(vampiric_touch_debuff) <= Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < CastTime(vampiric_touch) + target.TickTime(vampiric_touch_debuff) and True(miss_react) Spell(vampiric_touch)
	#devouring_plague,if=shadow_orb=3&ticks_remain<=1
	if ShadowOrbs() == 3 and target.TicksRemaining(devouring_plague_debuff) < 2 Spell(devouring_plague)
	#mind_spike,if=active_enemies<=5&buff.surge_of_darkness.react=2
	if Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 2 Spell(mind_spike)
	#wait,sec=cooldown.shadow_word_death.remains,if=target.health.pct<20&cooldown.shadow_word_death.remains<0.5&active_enemies<=1
	unless target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 0.5 and Enemies() <= 1 and SpellCooldown(shadow_word_death) > 0
	{
		#wait,sec=cooldown.mind_blast.remains,if=cooldown.mind_blast.remains<0.5&active_enemies<=1
		unless SpellCooldown(mind_blast) < 0.5 and Enemies() <= 1 and SpellCooldown(mind_blast) > 0
		{
			#mind_spike,if=buff.surge_of_darkness.react&active_enemies<=5
			if BuffPresent(surge_of_darkness_buff) and Enemies() <= 5 Spell(mind_spike)
			#mind_sear,chain=1,interrupt=1,if=active_enemies>=3
			if Enemies() >= 3 Spell(mind_sear)
			#mind_flay,chain=1,interrupt=1
			Spell(mind_flay)
			#shadow_word_death,moving=1
			if Speed() > 0 and { Glyph(glyph_of_shadow_word_death) or target.HealthPercent() < 20 } Spell(shadow_word_death)
			#mind_blast,moving=1,if=buff.divine_insight_shadow.react&cooldown_react
			if Speed() > 0 and BuffPresent(divine_insight_shadow_buff) and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
			#shadow_word_pain,moving=1
			if Speed() > 0 Spell(shadow_word_pain)
			#dispersion
			Spell(dispersion)
		}
	}
}

AddFunction ShadowDefaultMovingActions
{
	#shadowform
	if not Stance(priest_shadowform) Spell(shadowform)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=1&active_enemies<=5
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 1 and Enemies() <= 5 and { Glyph(glyph_of_shadow_word_death) or target.HealthPercent() < 20 } Spell(shadow_word_death)
	#devouring_plague,if=shadow_orb=3&(cooldown.mind_blast.remains<1.5|target.health.pct<20&cooldown.shadow_word_death.remains<1.5)
	if ShadowOrbs() == 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } Spell(devouring_plague)
	#mind_blast,if=active_enemies<=5&cooldown_react
	if Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and BuffPresent(divine_insight_shadow_buff) Spell(mind_blast)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=0&active_enemies<=5
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 0 and Enemies() <= 5 and { Glyph(glyph_of_shadow_word_death) or target.HealthPercent() < 20 } Spell(shadow_word_death)
	#shadow_word_pain,cycle_targets=1,max_cycle_targets=5,if=miss_react&!ticking
	if DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) Spell(shadow_word_pain)
	#shadow_word_pain,cycle_targets=1,max_cycle_targets=5,if=miss_react&ticks_remain<=1
	if DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and True(miss_react) and target.TicksRemaining(shadow_word_pain_debuff) < 2 Spell(shadow_word_pain)
	#devouring_plague,if=shadow_orb=3&ticks_remain<=1
	if ShadowOrbs() == 3 and target.TicksRemaining(devouring_plague_debuff) < 2 Spell(devouring_plague)
	#mind_spike,if=active_enemies<=5&buff.surge_of_darkness.react=2
	if Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 2 Spell(mind_spike)
	#wait,sec=cooldown.shadow_word_death.remains,if=target.health.pct<20&cooldown.shadow_word_death.remains<0.5&active_enemies<=1
	unless target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 0.5 and Enemies() <= 1 and SpellCooldown(shadow_word_death) > 0
	{
		#wait,sec=cooldown.mind_blast.remains,if=cooldown.mind_blast.remains<0.5&active_enemies<=1
		unless SpellCooldown(mind_blast) < 0.5 and Enemies() <= 1 and SpellCooldown(mind_blast) > 0
		{
			#mind_spike,if=buff.surge_of_darkness.react&active_enemies<=5
			if BuffPresent(surge_of_darkness_buff) and Enemies() <= 5 Spell(mind_spike)
			#shadow_word_death,moving=1
			if Speed() > 0 and { Glyph(glyph_of_shadow_word_death) or target.HealthPercent() < 20 } Spell(shadow_word_death)
			#mind_blast,moving=1,if=buff.divine_insight_shadow.react&cooldown_react
			if Speed() > 0 and BuffPresent(divine_insight_shadow_buff) and not SpellCooldown(mind_blast) > 0 Spell(mind_blast)
			#shadow_word_pain,moving=1
			if Speed() > 0 Spell(shadow_word_pain)
			#dispersion
			Spell(dispersion)
		}
	}
}

AddFunction ShadowDefaultShortCdActions
{
	unless not Stance(priest_shadowform) and Spell(shadowform)
		or BuffStacks(shadow_word_death_reset_cooldown_buff) == 1 and Enemies() <= 5 and { Glyph(glyph_of_shadow_word_death) or target.HealthPercent() < 20 } and Spell(shadow_word_death)
		or ShadowOrbs() == 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } and Spell(devouring_plague)
		or Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast)
		or BuffStacks(shadow_word_death_reset_cooldown_buff) == 0 and Enemies() <= 5 and { Glyph(glyph_of_shadow_word_death) or target.HealthPercent() < 20 } and Spell(shadow_word_death)
		or target.TicksRemaining(devouring_plague_debuff) < 2 and Talent(solace_and_insanity_talent) and target.DebuffPresent(devouring_plague_debuff) and Spell(mind_flay)
		or Enemies() <= 5 and Talent(solace_and_insanity_talent) and target.DebuffPresent(devouring_plague_debuff) and Spell(mind_flay)
		or DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) and Spell(shadow_word_pain)
		or DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < CastTime(vampiric_touch) and True(miss_react) and Spell(vampiric_touch)
		or DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and True(miss_react) and target.TicksRemaining(shadow_word_pain_debuff) < 2 and Spell(shadow_word_pain)
		or DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < CastTime(vampiric_touch) + target.TickTime(vampiric_touch_debuff) and True(miss_react) and Spell(vampiric_touch)
		or ShadowOrbs() == 3 and target.TicksRemaining(devouring_plague_debuff) < 2 and Spell(devouring_plague)
		or Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 2 and Spell(mind_spike)
	{
		#halo,if=talent.halo.enabled&target.distance<=30&target.distance>=17
		if Talent(halo_talent) and target.Distance() <= 30 and target.Distance() >= 17 Spell(halo)
		#cascade_damage,if=talent.cascade.enabled&(active_enemies>1|(target.distance>=25&stat.mastery_rating<15000)|target.distance>=28)&target.distance<=40&target.distance>=11
		if Talent(cascade_talent) and { Enemies() > 1 or target.Distance() >= 25 and MasteryRating() < 15000 or target.Distance() >= 28 } and target.Distance() <= 40 and target.Distance() >= 11 Spell(cascade_damage)
		#divine_star,if=talent.divine_star.enabled&(active_enemies>1|stat.mastery_rating<3500)&target.distance<=24
		if Talent(divine_star_talent) and { Enemies() > 1 or MasteryRating() < 3500 } and target.Distance() <= 24 Spell(divine_star)
		#wait,sec=cooldown.shadow_word_death.remains,if=target.health.pct<20&cooldown.shadow_word_death.remains<0.5&active_enemies<=1
		unless target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 0.5 and Enemies() <= 1 and SpellCooldown(shadow_word_death) > 0
		{
			#wait,sec=cooldown.mind_blast.remains,if=cooldown.mind_blast.remains<0.5&active_enemies<=1
			unless SpellCooldown(mind_blast) < 0.5 and Enemies() <= 1 and SpellCooldown(mind_blast) > 0
			{
				unless BuffPresent(surge_of_darkness_buff) and Enemies() <= 5 and Spell(mind_spike)
					or Enemies() >= 3 and Spell(mind_sear)
					or Spell(mind_flay)
					or Speed() > 0 and { Glyph(glyph_of_shadow_word_death) or target.HealthPercent() < 20 } and Spell(shadow_word_death)
					or Speed() > 0 and BuffPresent(divine_insight_shadow_buff) and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast)
				{
					#divine_star,moving=1,if=talent.divine_star.enabled&target.distance<=28
					if Speed() > 0 and Talent(divine_star_talent) and target.Distance() <= 28 Spell(divine_star)
					#cascade_damage,moving=1,if=talent.cascade.enabled&target.distance<=40
					if Speed() > 0 and Talent(cascade_talent) and target.Distance() <= 40 Spell(cascade_damage)
				}
			}
		}
	}
}

AddFunction ShadowDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()

	unless not Stance(priest_shadowform) and Spell(shadowform)
	{
		#use_item,slot=hands
		UseItemActions()
		#jade_serpent_potion,if=buff.bloodlust.react|target.time_to_die<=40
		if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 40 UsePotionIntellect()
		#mindbender,if=talent.mindbender.enabled
		if Talent(mindbender_talent) Spell(mindbender)
		#shadowfiend,if=!talent.mindbender.enabled
		if Talent(mindbender_talent no) Spell(shadowfiend)
		#power_infusion,if=talent.power_infusion.enabled
		if Talent(power_infusion_talent) Spell(power_infusion)
		#blood_fury
		Spell(blood_fury_sp)
		#berserking
		Spell(berserking)
		#arcane_torrent
		Spell(arcane_torrent_mana)

		unless BuffStacks(shadow_word_death_reset_cooldown_buff) == 1 and Enemies() <= 5 and { Glyph(glyph_of_shadow_word_death) or target.HealthPercent() < 20 } and Spell(shadow_word_death)
			or ShadowOrbs() == 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } and Spell(devouring_plague)
			or Enemies() <= 5 and not SpellCooldown(mind_blast) > 0 and Spell(mind_blast)
			or BuffStacks(shadow_word_death_reset_cooldown_buff) == 0 and Enemies() <= 5 and { Glyph(glyph_of_shadow_word_death) or target.HealthPercent() < 20 } and Spell(shadow_word_death)
			or target.TicksRemaining(devouring_plague_debuff) < 2 and Talent(solace_and_insanity_talent) and target.DebuffPresent(devouring_plague_debuff) and Spell(mind_flay)
			or Enemies() <= 5 and Talent(solace_and_insanity_talent) and target.DebuffPresent(devouring_plague_debuff) and Spell(mind_flay)
			or DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) and Spell(shadow_word_pain)
			or DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < CastTime(vampiric_touch) and True(miss_react) and Spell(vampiric_touch)
			or DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and True(miss_react) and target.TicksRemaining(shadow_word_pain_debuff) < 2 and Spell(shadow_word_pain)
			or DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(vampiric_touch_debuff) <= 5 and target.DebuffRemaining(vampiric_touch_debuff) < CastTime(vampiric_touch) + target.TickTime(vampiric_touch_debuff) and True(miss_react) and Spell(vampiric_touch)
		{
			if ShadowOrbs() == 3 and HealthPercent() <= 40 Spell(vampiric_embrace)
		}
	}
}

### Shadow icons
AddCheckBox(opt_priest_shadow "Show Shadow icons" specialization=shadow default)
AddCheckBox(opt_priest_shadow_aoe L(AOE) specialization=shadow default)

AddIcon specialization=shadow help=shortcd enemies=1 checkbox=opt_priest_shadow checkbox=!opt_priest_shadow_aoe
{
	if InCombat(no) ShadowPrecombatShortCdActions()
	ShadowDefaultShortCdActions()
}

AddIcon specialization=shadow help=shortcd checkbox=opt_priest_shadow checkbox=opt_priest_shadow_aoe
{
	if InCombat(no) ShadowPrecombatShortCdActions()
	ShadowDefaultShortCdActions()
}

AddIcon specialization=shadow help=main enemies=1 checkbox=opt_priest_shadow
{
	if InCombat(no) ShadowPrecombatActions()
	ShadowDefaultActions()
}

AddIcon specialization=shadow help=moving enemies=1 checkbox=opt_priest_shadow checkbox=!opt_priest_shadow_aoe
{
	if InCombat(no) ShadowPrecombatMovingActions()
	ShadowDefaultMovingActions()
}

AddIcon specialization=shadow help=aoe checkbox=opt_priest_shadow checkbox=opt_priest_shadow_aoe
{
	if InCombat(no) ShadowPrecombatActions()
	ShadowDefaultActions()
}

AddIcon specialization=shadow help=cd enemies=1 checkbox=opt_priest_shadow checkbox=!opt_priest_shadow_aoe
{
	if InCombat(no) ShadowPrecombatCdActions()
	ShadowDefaultCdActions()
}

AddIcon specialization=shadow help=cd checkbox=opt_priest_shadow checkbox=opt_priest_shadow_aoe
{
	if InCombat(no) ShadowPrecombatCdActions()
	ShadowDefaultCdActions()
}
]]

	OvaleScripts:RegisterScript("PRIEST", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("PRIEST", "Ovale", desc, code, "script")
end
