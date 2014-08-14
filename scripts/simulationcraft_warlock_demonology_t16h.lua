local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Warlock_Demonology_T16H"
	local desc = "[5.4] SimulationCraft: Warlock_Demonology_T16H"
	local code = [[
# Based on SimulationCraft profile "Warlock_Demonology_T16H".
#	class=warlock
#	spec=demonology
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#VZ!....10
#	pet=felguard

Include(ovale_common)
Include(ovale_warlock_spells)

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

AddFunction DemonologyPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier_buff any=1) Spell(dark_intent)
	#summon_pet,if=!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down
	if { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and pet.Present(no) Spell(summon_felguard)
	#snapshot_stats
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
	if Talent(grimoire_of_sacrifice_talent) and pet.Present() Spell(grimoire_of_sacrifice)
	#service_pet,if=talent.grimoire_of_service.enabled
	if Talent(grimoire_of_service_talent) Spell(grimoire_felguard)
	#jade_serpent_potion
	UsePotionIntellect()
}

AddFunction DemonologyDefaultActions
{
	#curse_of_the_elements,if=debuff.magic_vulnerability.down
	if target.DebuffExpires(magic_vulnerability_debuff any=1) Spell(curse_of_the_elements)
	#use_item,name=gloves_of_the_horned_nightmare
	UseItemActions()
	#jade_serpent_potion,if=buff.bloodlust.react|target.health.pct<=20
	if BuffPresent(burst_haste_buff any=1) or target.HealthPercent() <= 20 UsePotionIntellect()
	#berserking
	Spell(berserking)
	#dark_soul,if=!talent.archimondes_darkness.enabled|(talent.archimondes_darkness.enabled&(charges=2|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react|target.health.pct<=10))
	if not Talent(archimondes_darkness_talent) or Talent(archimondes_darkness_talent) and { Charges(dark_soul_knowledge) == 2 or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_stacking_proc_intellect_buff) or target.HealthPercent() <= 10 } Spell(dark_soul_knowledge)
	#service_pet,if=talent.grimoire_of_service.enabled
	if Talent(grimoire_of_service_talent) Spell(grimoire_felguard)
	#felguard:felstorm
	if pet.Present() and pet.CreatureFamily(Felguard) Spell(felguard_felstorm)
	#wrathguard:wrathstorm
	if pet.Present() and pet.CreatureFamily(Wrathguard) Spell(wrathguard_wrathstorm)
	#run_action_list,name=aoe,if=active_enemies>4
	if Enemies() > 4 DemonologyAoeActions()
	#summon_doomguard
	Spell(summon_doomguard)
	#doom,cycle_targets=1,if=buff.metamorphosis.up&(ticks_remain<=1|(ticks_remain+1<n_ticks&buff.dark_soul.up)|(ticks_remain<=add_ticks%2&stat.spell_power>spell_power))&target.time_to_die>=30&miss_react
	if BuffPresent(metamorphosis_buff) and { target.TicksRemaining(doom_debuff) < 2 or target.TicksRemaining(doom_debuff) + 1 < target.Ticks(doom_debuff) and BuffPresent(dark_soul_knowledge_buff) or target.TicksRemaining(doom_debuff) <= TicksAdded(doom_debuff) / 2 and Spellpower() > target.DebuffSpellpower(doom_debuff) } and target.TimeToDie() >= 30 and True(miss_react) Spell(doom)
	#cancel_metamorphosis,if=buff.metamorphosis.up&buff.dark_soul.down&demonic_fury<=650&target.time_to_die>30&(cooldown.metamorphosis.remains<4|demonic_fury<=300)&!(action.hand_of_guldan.in_flight&dot.shadowflame.remains)
	if BuffPresent(metamorphosis_buff) and BuffExpires(dark_soul_knowledge_buff) and DemonicFury() <= 650 and target.TimeToDie() > 30 and { SpellCooldown(metamorphosis) < 4 or DemonicFury() <= 300 } and not { InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) } Texture(spell_shadow_demonform text=cancel)
	#soul_fire,if=buff.metamorphosis.up&buff.molten_core.react&(buff.dark_soul.remains<action.shadow_bolt.cast_time|buff.dark_soul.remains>cast_time)
	if BuffPresent(metamorphosis_buff) and BuffPresent(molten_core_buff) and { BuffRemaining(dark_soul_knowledge_buff) < CastTime(shadow_bolt) or BuffRemaining(dark_soul_knowledge_buff) > CastTime(soul_fire) } Spell(soul_fire)
	#touch_of_chaos,if=buff.metamorphosis.up
	if BuffPresent(metamorphosis_buff) Spell(touch_of_chaos)
	#metamorphosis,if=(buff.dark_soul.up&buff.dark_soul.remains<demonic_fury%32)|demonic_fury>=950|demonic_fury%32>target.time_to_die|(action.hand_of_guldan.in_flight&dot.shadowflame.remains)
	if { BuffPresent(dark_soul_knowledge_buff) and BuffRemaining(dark_soul_knowledge_buff) < DemonicFury() / 32 or DemonicFury() >= 950 or DemonicFury() / 32 > target.TimeToDie() or InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) } and not Stance(warlock_metamorphosis) Spell(metamorphosis)
	#corruption,cycle_targets=1,if=!ticking&target.time_to_die>=6&miss_react
	if not target.DebuffPresent(corruption_debuff) and target.TimeToDie() >= 6 and True(miss_react) Spell(corruption)
	#corruption,cycle_targets=1,if=spell_power<stat.spell_power&ticks_remain<=add_ticks%2&target.time_to_die>=6&miss_react
	if target.DebuffSpellpower(corruption_debuff) < Spellpower() and target.TicksRemaining(corruption_debuff) <= TicksAdded(corruption_debuff) / 2 and target.TimeToDie() >= 6 and True(miss_react) Spell(corruption)
	#hand_of_guldan,if=!in_flight&dot.shadowflame.remains<travel_time+action.shadow_bolt.cast_time&(charges=2|dot.shadowflame.remains>travel_time|(charges=1&recharge_time<4))
	if not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < 0.5 + CastTime(shadow_bolt) and { Charges(hand_of_guldan) == 2 or target.DebuffRemaining(shadowflame_debuff) > 0.5 or Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 } Spell(hand_of_guldan)
	#soul_fire,if=buff.molten_core.react&(buff.dark_soul.remains<action.shadow_bolt.cast_time|buff.dark_soul.remains>cast_time)&(buff.molten_core.react>9|target.health.pct<=28)
	if BuffPresent(molten_core_buff) and { BuffRemaining(dark_soul_knowledge_buff) < CastTime(shadow_bolt) or BuffRemaining(dark_soul_knowledge_buff) > CastTime(soul_fire) } and { BuffStacks(molten_core_buff) > 9 or target.HealthPercent() <= 28 } Spell(soul_fire)
	#life_tap,if=mana.pct<60
	if ManaPercent() < 60 Spell(life_tap)
	#shadow_bolt
	Spell(shadow_bolt)
	#fel_flame,moving=1
	if Speed() > 0 Spell(fel_flame)
	#life_tap
	Spell(life_tap)
}

AddFunction DemonologyAoeActions
{
	#summon_infernal
	Spell(summon_infernal)
	#cancel_metamorphosis,if=buff.metamorphosis.up&dot.corruption.remains>10&demonic_fury<=650&buff.dark_soul.down&!dot.immolation_aura.ticking
	if BuffPresent(metamorphosis_buff) and target.DebuffRemaining(corruption_debuff) > 10 and DemonicFury() <= 650 and BuffExpires(dark_soul_knowledge_buff) and not target.DebuffPresent(immolation_aura_debuff) Texture(spell_shadow_demonform text=cancel)
	#immolation_aura,if=buff.metamorphosis.up
	if BuffPresent(metamorphosis_buff) Spell(immolation_aura)
	#void_ray,if=buff.metamorphosis.up&dot.corruption.remains<10
	if BuffPresent(metamorphosis_buff) and target.DebuffRemaining(corruption_debuff) < 10 Spell(void_ray)
	#doom,cycle_targets=1,if=buff.metamorphosis.up&(!ticking|remains<tick_time|(ticks_remain+1<n_ticks&buff.dark_soul.up))&target.time_to_die>=30&miss_react
	if BuffPresent(metamorphosis_buff) and { not target.DebuffPresent(doom_debuff) or target.DebuffRemaining(doom_debuff) < target.TickTime(doom_debuff) or target.TicksRemaining(doom_debuff) + 1 < target.Ticks(doom_debuff) and BuffPresent(dark_soul_knowledge_buff) } and target.TimeToDie() >= 30 and True(miss_react) Spell(doom)
	#void_ray,if=buff.metamorphosis.up
	if BuffPresent(metamorphosis_buff) Spell(void_ray)
	#corruption,cycle_targets=1,if=!ticking&target.time_to_die>30&miss_react
	if not target.DebuffPresent(corruption_debuff) and target.TimeToDie() > 30 and True(miss_react) Spell(corruption)
	#hand_of_guldan
	Spell(hand_of_guldan)
	#metamorphosis,if=dot.corruption.remains<10|buff.dark_soul.up|demonic_fury>=950|demonic_fury%32>target.time_to_die
	if { target.DebuffRemaining(corruption_debuff) < 10 or BuffPresent(dark_soul_knowledge_buff) or DemonicFury() >= 950 or DemonicFury() / 32 > target.TimeToDie() } and not Stance(warlock_metamorphosis) Spell(metamorphosis)
	#hellfire,chain=1,interrupt=1
	Spell(hellfire)
	#life_tap
	Spell(life_tap)
}

AddIcon specialization=demonology help=main enemies=1
{
	if InCombat(no) DemonologyPrecombatActions()
	DemonologyDefaultActions()
}

AddIcon specialization=demonology help=aoe
{
	if InCombat(no) DemonologyPrecombatActions()
	DemonologyDefaultActions()
}

### Required symbols
# archimondes_darkness_talent
# berserking
# corruption
# corruption_debuff
# curse_of_the_elements
# dark_intent
# dark_soul_knowledge
# dark_soul_knowledge_buff
# doom
# doom_debuff
# fel_flame
# felguard_felstorm
# grimoire_felguard
# grimoire_of_sacrifice
# grimoire_of_sacrifice_buff
# grimoire_of_sacrifice_talent
# grimoire_of_service_talent
# hand_of_guldan
# hellfire
# immolation_aura
# immolation_aura_debuff
# jade_serpent_potion
# life_tap
# metamorphosis
# metamorphosis_buff
# molten_core_buff
# shadow_bolt
# shadowflame_debuff
# soul_fire
# summon_doomguard
# summon_felguard
# summon_infernal
# touch_of_chaos
# trinket_proc_intellect_buff
# trinket_stacking_proc_intellect_buff
# void_ray
# wrathguard_wrathstorm
]]
	OvaleScripts:RegisterScript("WARLOCK", name, desc, code, "reference")
end
