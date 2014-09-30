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
Include(ovale_druid_spells)

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

AddFunction BalanceDefaultActions
{
	#jade_serpent_potion,if=trinket.stat.intellect.up
	if BuffPresent(trinket_stat_intellect_buff) UsePotionIntellect()
	#starfall,if=!buff.starfall.up
	if not BuffPresent(starfall_buff) Spell(starfall)
	#force_of_nature,if=talent.force_of_nature.enabled
	if Talent(force_of_nature_talent) Spell(force_of_nature_caster)
	#berserking,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) Spell(berserking)
	#use_item,slot=hands,if=buff.celestial_alignment.up|cooldown.celestial_alignment.remains>30
	if BuffPresent(celestial_alignment_buff) or SpellCooldown(celestial_alignment) > 30 UseItemActions()
	#wild_mushroom_detonate,moving=0,if=buff.wild_mushroom.stack>0&buff.solar_eclipse.up
	if WildMushroomCount() > 0 and BuffPresent(solar_eclipse_buff) Spell(wild_mushroom_detonate)
	#natures_swiftness,if=talent.dream_of_cenarius.enabled
	if Talent(dream_of_cenarius_talent) Spell(natures_swiftness)
	#healing_touch,if=talent.dream_of_cenarius.enabled&!buff.dream_of_cenarius.up&mana.pct>25
	if Talent(dream_of_cenarius_talent) and not BuffPresent(dream_of_cenarius_caster_buff) and ManaPercent() > 25 Spell(healing_touch)
	#incarnation,if=talent.incarnation.enabled&trinket.stat.intellect.up
	if Talent(incarnation_talent) and BuffPresent(trinket_stat_intellect_buff) Spell(incarnation_caster)
	#celestial_alignment,if=trinket.stat.intellect.up
	if BuffPresent(trinket_stat_intellect_buff) Spell(celestial_alignment)
	#natures_vigil,if=talent.natures_vigil.enabled
	if Talent(natures_vigil_talent) Spell(natures_vigil)
	#starsurge
	Spell(starsurge)
	#moonfire,cycle_targets=1,if=dot.moonfire.remains<1|action.moonfire.tick_damage%dot.moonfire.tick_dmg>=1.3
	if target.DebuffRemaining(moonfire_debuff) < 1 or target.Damage(moonfire_debuff) / target.LastEstimatedDamage(moonfire_debuff) >= 1.3 Spell(moonfire)
	#sunfire,cycle_targets=1,if=dot.sunfire.remains<1|action.sunfire.tick_damage%dot.sunfire.tick_dmg>=1.3
	if target.DebuffRemaining(sunfire_debuff) < 1 or target.Damage(sunfire_debuff) / target.LastEstimatedDamage(sunfire_debuff) >= 1.3 Spell(sunfire)
	#hurricane,if=active_enemies>4&buff.solar_eclipse.up&buff.natures_grace.up
	if Enemies() > 4 and BuffPresent(solar_eclipse_buff) and BuffPresent(natures_grace_buff) Spell(hurricane)
	#starfire,if=buff.celestial_alignment.up|eclipse_dir=1|(eclipse_dir=0&eclipse<=0)
	if BuffPresent(celestial_alignment_buff) or EclipseDir() == 1 or EclipseDir() == 0 and Eclipse() <= 0 Spell(starfire)
	#wrath,if=eclipse_dir=-1|(eclipse_dir=0&eclipse<=0)
	if EclipseDir() == -1 or EclipseDir() == 0 and Eclipse() <= 0 Spell(wrath)
	#hurricane,if=active_enemies>5&buff.solar_eclipse.up&mana.pct>25
	if Enemies() > 5 and BuffPresent(solar_eclipse_buff) and ManaPercent() > 25 Spell(hurricane)
	#starsurge,if=cooldown_react
	if not SpellCooldown(starsurge) > 0 Spell(starsurge)
}

AddFunction BalancePrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#wild_mushroom,if=buff.wild_mushroom.stack<buff.wild_mushroom.max_stack
	if WildMushroomCount() < 3 Spell(wild_mushroom_caster)
	#healing_touch,if=!buff.dream_of_cenarius.up&talent.dream_of_cenarius.enabled
	if not BuffPresent(dream_of_cenarius_caster_buff) and Talent(dream_of_cenarius_talent) Spell(healing_touch)
	#moonkin_form
	if not Stance(druid_moonkin_form) Spell(moonkin_form)
	#snapshot_stats
	#jade_serpent_potion
	UsePotionIntellect()
}

AddIcon specialization=balance help=main enemies=1
{
	if InCombat(no) BalancePrecombatActions()
	BalanceDefaultActions()
}

AddIcon specialization=balance help=aoe
{
	if InCombat(no) BalancePrecombatActions()
	BalanceDefaultActions()
}

### Required symbols
# berserking
# celestial_alignment
# celestial_alignment_buff
# dream_of_cenarius_caster_buff
# dream_of_cenarius_talent
# force_of_nature_caster
# force_of_nature_talent
# healing_touch
# hurricane
# incarnation_caster
# incarnation_talent
# jade_serpent_potion
# mark_of_the_wild
# moonfire
# moonfire_debuff
# moonkin_form
# natures_grace_buff
# natures_swiftness
# natures_vigil
# natures_vigil_talent
# solar_eclipse_buff
# starfall
# starfall_buff
# starfire
# starsurge
# sunfire
# sunfire_debuff
# trinket_stat_intellect_buff
# wild_mushroom_caster
# wild_mushroom_detonate
# wrath
]]
	OvaleScripts:RegisterScript("DRUID", name, desc, code, "reference")
end
