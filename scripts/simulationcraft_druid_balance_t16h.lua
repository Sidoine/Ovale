local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Druid_Balance_T16H"
	local desc = "[5.4] SimulationCraft: Druid_Balance_T16H" 
	local code = [[
# Based on SimulationCraft profile "Druid_Balance_T16H".
#	class=druid
#	spec=balance
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Ua!.0.1.0

Include(ovale_common)
Include(ovale_druid_common)

AddFunction BalanceDefaultActions
{
	#jade_serpent_potion,if=buff.bloodlust.react|target.time_to_die<=40|buff.celestial_alignment.up
	if BuffPresent(burst_haste any=1) or target.TimeToDie() <= 40 or BuffPresent(celestial_alignment_buff) UsePotionIntellect()
	#starfall,if=!buff.starfall.up
	if not BuffPresent(starfall_buff) Spell(starfall)
	#force_of_nature,if=talent.force_of_nature.enabled
	if TalentPoints(force_of_nature_talent) Spell(force_of_nature_caster)
	#berserking,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) Spell(berserking)
	#use_item,slot=hands,if=buff.celestial_alignment.up|cooldown.celestial_alignment.remains>30
	if BuffPresent(celestial_alignment_buff) or SpellCooldown(celestial_alignment) > 30 UseItemActions()
	#wild_mushroom_detonate,moving=0,if=buff.wild_mushroom.stack>0&buff.solar_eclipse.up
	if WildMushroomCount() > 0 and BuffPresent(solar_eclipse_buff) Spell(wild_mushroom_detonate)
	#natures_swiftness,if=talent.dream_of_cenarius.enabled
	if TalentPoints(dream_of_cenarius_talent) Spell(natures_swiftness)
	#healing_touch,if=talent.dream_of_cenarius.enabled&!buff.dream_of_cenarius.up&mana.pct>25
	if TalentPoints(dream_of_cenarius_talent) and not BuffPresent(dream_of_cenarius_caster_buff) and ManaPercent() > 25 Spell(healing_touch)
	#incarnation,if=talent.incarnation.enabled&(buff.lunar_eclipse.up|buff.solar_eclipse.up)
	if TalentPoints(incarnation_talent) and { BuffPresent(lunar_eclipse_buff) or BuffPresent(solar_eclipse_buff) } Spell(incarnation)
	#celestial_alignment,if=(!buff.lunar_eclipse.up&!buff.solar_eclipse.up)&(buff.chosen_of_elune.up|!talent.incarnation.enabled|cooldown.incarnation.remains>10)
	if { not BuffPresent(lunar_eclipse_buff) and not BuffPresent(solar_eclipse_buff) } and { BuffPresent(chosen_of_elune_buff) or not TalentPoints(incarnation_talent) or SpellCooldown(incarnation) > 10 } Spell(celestial_alignment)
	#natures_vigil,if=talent.natures_vigil.enabled
	if TalentPoints(natures_vigil_talent) Spell(natures_vigil)
	#starsurge,if=buff.shooting_stars.react&(active_enemies<5|!buff.solar_eclipse.up)
	if BuffPresent(shooting_stars_buff) and { Enemies() < 5 or not BuffPresent(solar_eclipse_buff) } Spell(starsurge)
	#moonfire,cycle_targets=1,if=buff.lunar_eclipse.up&(remains<(buff.natures_grace.remains-2+2*set_bonus.tier14_4pc_caster))
	if BuffPresent(lunar_eclipse_buff) and { target.DebuffRemains(moonfire_debuff) < { BuffRemains(natures_grace_buff) -2 + 2 * ArmorSetBonus(T14_caster 4) } } Spell(moonfire)
	#sunfire,cycle_targets=1,if=buff.solar_eclipse.up&(remains<(buff.natures_grace.remains-2+2*set_bonus.tier14_4pc_caster))
	if BuffPresent(solar_eclipse_buff) and { target.DebuffRemains(sunfire_debuff) < { BuffRemains(natures_grace_buff) -2 + 2 * ArmorSetBonus(T14_caster 4) } } Spell(sunfire)
	#hurricane,if=active_enemies>4&buff.solar_eclipse.up&buff.natures_grace.up
	if Enemies() > 4 and BuffPresent(solar_eclipse_buff) and BuffPresent(natures_grace_buff) Spell(hurricane)
	#moonfire,cycle_targets=1,if=active_enemies<5&(remains<(buff.natures_grace.remains-2+2*set_bonus.tier14_4pc_caster))
	if Enemies() < 5 and { target.DebuffRemains(moonfire_debuff) < { BuffRemains(natures_grace_buff) -2 + 2 * ArmorSetBonus(T14_caster 4) } } Spell(moonfire)
	#sunfire,cycle_targets=1,if=active_enemies<5&(remains<(buff.natures_grace.remains-2+2*set_bonus.tier14_4pc_caster))
	if Enemies() < 5 and { target.DebuffRemains(sunfire_debuff) < { BuffRemains(natures_grace_buff) -2 + 2 * ArmorSetBonus(T14_caster 4) } } Spell(sunfire)
	#hurricane,if=active_enemies>5&buff.solar_eclipse.up&mana.pct>25
	if Enemies() > 5 and BuffPresent(solar_eclipse_buff) and ManaPercent() > 25 Spell(hurricane)
	#moonfire,cycle_targets=1,if=buff.lunar_eclipse.up&ticks_remain<2
	if BuffPresent(lunar_eclipse_buff) and target.TicksRemain(moonfire_debuff) < 2 Spell(moonfire)
	#sunfire,cycle_targets=1,if=buff.solar_eclipse.up&ticks_remain<2
	if BuffPresent(solar_eclipse_buff) and target.TicksRemain(sunfire_debuff) < 2 Spell(sunfire)
	#hurricane,if=active_enemies>4&buff.solar_eclipse.up&mana.pct>25
	if Enemies() > 4 and BuffPresent(solar_eclipse_buff) and ManaPercent() > 25 Spell(hurricane)
	#starsurge,if=cooldown_react
	if Spell(starsurge) Spell(starsurge)
	#starfire,if=buff.celestial_alignment.up&cast_time<buff.celestial_alignment.remains
	if BuffPresent(celestial_alignment_buff) and CastTime(starfire) < BuffRemains(celestial_alignment_buff) Spell(starfire)
	#wrath,if=buff.celestial_alignment.up&cast_time<buff.celestial_alignment.remains
	if BuffPresent(celestial_alignment_buff) and CastTime(wrath) < BuffRemains(celestial_alignment_buff) Spell(wrath)
	#starfire,if=eclipse_dir=1|(eclipse_dir=0&eclipse>0)
	if EclipseDir() == 1 or { EclipseDir() == 0 and Eclipse() > 0 } Spell(starfire)
	#wrath,if=eclipse_dir=-1|(eclipse_dir=0&eclipse<=0)
	if EclipseDir() == -1 or { EclipseDir() == 0 and Eclipse() <= 0 } Spell(wrath)
	#moonfire,moving=1,cycle_targets=1,if=ticks_remain<2
	if Speed() > 0 and target.TicksRemain(moonfire_debuff) < 2 Spell(moonfire)
	#sunfire,moving=1,cycle_targets=1,if=ticks_remain<2
	if Speed() > 0 and target.TicksRemain(sunfire_debuff) < 2 Spell(sunfire)
	#wild_mushroom,moving=1,if=buff.wild_mushroom.stack<buff.wild_mushroom.max_stack
	if Speed() > 0 and WildMushroomCount() < 3 Spell(wild_mushroom_caster)
	#starsurge,moving=1,if=buff.shooting_stars.react
	if Speed() > 0 and BuffPresent(shooting_stars_buff) Spell(starsurge)
	#moonfire,moving=1,if=buff.lunar_eclipse.up
	if Speed() > 0 and BuffPresent(lunar_eclipse_buff) Spell(moonfire)
	#sunfire,moving=1
	if Speed() > 0 Spell(sunfire)
}

AddIcon mastery=balance help=main
{
	BalanceDefaultActions()
}

### Required symbols
# berserking
# celestial_alignment
# celestial_alignment_buff
# chosen_of_elune_buff
# dream_of_cenarius_caster_buff
# dream_of_cenarius_talent
# force_of_nature_caster
# force_of_nature_talent
# healing_touch
# hurricane
# incarnation
# incarnation_talent
# jade_serpent_potion
# lunar_eclipse_buff
# moonfire
# moonfire_debuff
# natures_grace_buff
# natures_swiftness
# natures_vigil
# natures_vigil_talent
# shooting_stars_buff
# solar_eclipse_buff
# starfall
# starfall_buff
# starfire
# starsurge
# sunfire
# sunfire_debuff
# wild_mushroom_caster
# wild_mushroom_detonate
# wrath
]]
	OvaleScripts:RegisterScript("DRUID", name, desc, code, "reference")
end
