local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.4] Ovale: Shadow"
	local code = [[
# Ovale shadow script based on SimulationCraft.

Include(ovale_items)
Include(ovale_racials)
Include(ovale_priest_spells)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

###
### Shadow
###
# Based on SimulationCraft profile "Priest_Shadow_T16H".
#	class=priest
#	spec=shadow
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Xb!002202
#	glyphs=inner_sanctum/mind_flay/dark_archangel/shadowy_friends/shadow_ravens

AddFunction ShadowDefaultActions
{
	#shadowform
	if not Stance(priest_shadowform) Spell(shadowform)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=1&active_enemies<=5
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 1 Spell(shadow_word_death usable=1)
	#devouring_plague,if=shadow_orb=3&(cooldown.mind_blast.remains<1.5|target.health.pct<20&cooldown.shadow_word_death.remains<1.5)
	if ShadowOrbs() == 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } Spell(devouring_plague)
	#mind_blast,if=active_enemies<=5&cooldown_react
	Spell(mind_blast)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=0&active_enemies<=5
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 0 Spell(shadow_word_death usable=1)
	#mind_flay_insanity,if=target.dot.devouring_plague_tick.ticks_remain=1,chain=1
	if target.DebuffPresent(devouring_plague_debuff) and target.TicksRemain(devouring_plague_debuff) == 1 Spell(mind_flay)
	#mind_flay_insanity,interrupt=1,chain=1,if=active_enemies<=5
	if target.DebuffPresent(devouring_plague_debuff) Spell(mind_flay)
	#shadow_word_pain,cycle_targets=1,max_cycle_targets=5,if=miss_react&!ticking
	if True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) Spell(shadow_word_pain)
	#vampiric_touch,cycle_targets=1,max_cycle_targets=5,if=remains<cast_time&miss_react
	if target.DebuffRemains(vampiric_touch_debuff) < CastTime(vampiric_touch) and True(miss_react) Spell(vampiric_touch)
	#shadow_word_pain,cycle_targets=1,max_cycle_targets=5,if=miss_react&ticks_remain<=1
	if True(miss_react) and target.TicksRemain(shadow_word_pain_debuff) <= 1 Spell(shadow_word_pain)
	#vampiric_touch,cycle_targets=1,max_cycle_targets=5,if=remains<cast_time+tick_time&miss_react
	if target.DebuffRemains(vampiric_touch_debuff) < CastTime(vampiric_touch) + target.TickTime(vampiric_touch_debuff) and True(miss_react) Spell(vampiric_touch)
	#devouring_plague,if=shadow_orb=3&ticks_remain<=1
	if ShadowOrbs() == 3 and target.TicksRemain(devouring_plague_debuff) <= 1 Spell(devouring_plague)
	#mind_spike,if=active_enemies<=5&buff.surge_of_darkness.react=2
	if BuffStacks(surge_of_darkness_buff) == 2 Spell(mind_spike)
	#cascade_damage,if=talent.cascade.enabled
	if TalentPoints(cascade_talent) Spell(cascade_damage)
	#wait,sec=cooldown.shadow_word_death.remains,if=target.health.pct<20&cooldown.shadow_word_death.remains<0.5&active_enemies<=1
	if target.HealthPercent() < 20 Spell(shadow_word_death wait=0.5)
	#wait,sec=cooldown.mind_blast.remains,if=cooldown.mind_blast.remains<0.5&active_enemies<=1
	Spell(mind_blast wait=0.5)
	#mind_spike,if=buff.surge_of_darkness.react&active_enemies<=5
	if BuffPresent(surge_of_darkness_buff) Spell(mind_spike)
	#mind_flay,chain=1,interrupt=1
	Spell(mind_flay)
}

AddFunction ShadowDefaultMovingActions
{
	#shadowform
	if not Stance(priest_shadowform) Spell(shadowform)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=1&active_enemies<=5
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 1 and Enemies() <= 5 Spell(shadow_word_death usable=1)
	#devouring_plague,if=shadow_orb=3&(cooldown.mind_blast.remains<1.5|target.health.pct<20&cooldown.shadow_word_death.remains<1.5)
	if ShadowOrbs() == 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } Spell(devouring_plague)
	#shadow_word_death,if=buff.shadow_word_death_reset_cooldown.stack=0&active_enemies<=5
	if BuffStacks(shadow_word_death_reset_cooldown_buff) == 0 and Enemies() <= 5 Spell(shadow_word_death usable=1)
	#shadow_word_pain,cycle_targets=1,max_cycle_targets=5,if=miss_react&!ticking
	if True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) Spell(shadow_word_pain)
	#shadow_word_pain,cycle_targets=1,max_cycle_targets=5,if=miss_react&ticks_remain<=1
	if True(miss_react) and target.TicksRemain(shadow_word_pain_debuff) <= 1 Spell(shadow_word_pain)
	#devouring_plague,if=shadow_orb=3&ticks_remain<=1
	if ShadowOrbs() == 3 and target.TicksRemain(devouring_plague_debuff) <= 1 Spell(devouring_plague)
	#mind_spike,if=active_enemies<=5&buff.surge_of_darkness.react=2
	if Enemies() <= 5 and BuffStacks(surge_of_darkness_buff) == 2 Spell(mind_spike)
	#cascade_damage,if=talent.cascade.enabled
	if TalentPoints(cascade_talent) Spell(cascade_damage)
	#wait,sec=cooldown.shadow_word_death.remains,if=target.health.pct<20&cooldown.shadow_word_death.remains<0.5&active_enemies<=1
	if target.HealthPercent() < 20 Spell(shadow_word_death wait=0.5 usable=1)
	#mind_spike,if=buff.surge_of_darkness.react&active_enemies<=5
	if BuffPresent(surge_of_darkness_buff) and Enemies() <= 5 Spell(mind_spike)
	#shadow_word_death,moving=1
	Spell(shadow_word_death usable=1)
	#mind_blast,moving=1,if=buff.divine_insight_shadow.react&cooldown_react
	if BuffPresent(divine_insight_shadow_buff) and Spell(mind_blast) Spell(mind_blast)
	#shadow_word_pain,moving=1
	Spell(shadow_word_pain)
}

AddFunction ShadowDefaultShortCdActions
{
	unless { BuffStacks(shadow_word_death_reset_cooldown_buff) == 1 Spell(shadow_word_death usable=1) }
		or { ShadowOrbs() == 3 and { SpellCooldown(mind_blast) < 1.5 or target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 1.5 } }
		or Spell(mind_blast)
		or { BuffStacks(shadow_word_death_reset_cooldown_buff) == 0 and Spell(shadow_word_death usable=1) }
		or { target.DebuffPresent(devouring_plague_debuff) and target.TicksRemain(devouring_plague_debuff) == 1 }
		or target.DebuffPresent(devouring_plague_debuff)
		or { True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) }
		or { target.DebuffRemains(vampiric_touch_debuff) < CastTime(vampiric_touch) and True(miss_react) }
		or { True(miss_react) and target.TicksRemain(shadow_word_pain_debuff) <= 1 }
		or target.DebuffRemains(vampiric_touch_debuff) < CastTime(vampiric_touch) + target.TickTime(vampiric_touch_debuff) and True(miss_react) Spell(vampiric_touch)
		or { ShadowOrbs() == 3 and target.TicksRemain(devouring_plague_debuff) <= 1 }
		or { BuffStacks(surge_of_darkness_buff) == 2 }
	{
		#halo,if=talent.halo.enabled
		if TalentPoints(halo_talent) Spell(halo)
		#divine_star,if=talent.divine_star.enabled
		if TalentPoints(divine_star_talent) Spell(divine_star)

		unless { target.HealthPercent() < 20 and SpellCooldown(shadow_word_death) < 0.5 and Enemies() <= 1 }
			or { SpellCooldown(mind_blast) < 0.5 and Enemies() <= 1 }
			or { BuffPresent(surge_of_darkness_buff) and Enemies() <= 5 }
		{
			#mind_sear,chain=1,interrupt=1,if=active_enemies>=3
			if Enemies() >= 3 Spell(mind_sear)
		}
	}
}

AddFunction ShadowDefaultCdActions
{
	unless not Stance(priest_shadowform)
	{
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
	}
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
}

AddFunction ShadowPrecombatCdActions
{
	#jade_serpent_potion
	UsePotionIntellect()
}

### Feral Icons

AddIcon mastery=shadow size=small checkboxon=opt_icons_left
{
	if TalentPoints(desperate_prayer_talent) Spell(desperate_prayer)
	Spell(dispersion)
}

AddIcon mastery=shadow size=small checkboxon=opt_icons_left
{
	Spell(vampiric_embrace)
	Spell(hymn_of_hope)
}

AddIcon mastery=shadow help=shortcd
{
	ShadowDefaultShortCdActions()
}

AddIcon mastery=shadow help=main
{
	if InCombat(no) ShadowPrecombatActions()
	ShadowDefaultActions()
}

AddIcon mastery=shadow help=moving
{
	if InCombat(no) ShadowPrecombatActions()
	ShadowDefaultMovingActions()
}

AddIcon mastery=shadow help=cd
{
	if InCombat(no) ShadowPrecombatCdActions()
	Interrupt()
	UseRacialInterruptActions()
	ShadowDefaultCdActions()
}

AddIcon mastery=shadow size=small checkboxon=opt_icons_right
{
	Spell(mass_dispel)
}

AddIcon mastery=shadow size=small checkboxon=opt_icons_right
{
	UseItemActions()
}
]]

	OvaleScripts:RegisterScript("PRIEST", name, desc, code)
end
