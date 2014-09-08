local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Warlock_Destruction_T16H"
	local desc = "[5.4] SimulationCraft: Warlock_Destruction_T16H"
	local code = [[
# Based on SimulationCraft profile "Warlock_Destruction_T16H".
#	class=warlock
#	spec=destruction
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Vb!....20
#	pet=felhunter

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

AddFunction DestructionPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier_buff any=1) Spell(dark_intent)
	#summon_pet,if=!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down
	if { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and pet.Present(no) Spell(summon_felhunter)
	#snapshot_stats
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
	if Talent(grimoire_of_sacrifice_talent) and pet.Present() Spell(grimoire_of_sacrifice)
	#service_pet,if=talent.grimoire_of_service.enabled
	if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)
	#jade_serpent_potion
	UsePotionIntellect()
}

AddFunction DestructionDefaultActions
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
	if not Talent(archimondes_darkness_talent) or Talent(archimondes_darkness_talent) and { Charges(dark_soul_instability) == 2 or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_stacking_proc_intellect_buff) or target.HealthPercent() <= 10 } Spell(dark_soul_instability)
	#service_pet,if=talent.grimoire_of_service.enabled
	if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)
	#run_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 DestructionAoeActions()
	#summon_doomguard
	Spell(summon_doomguard)
	#rain_of_fire,if=!ticking&!in_flight&active_enemies>1
	if not target.DebuffPresent(rain_of_fire_aftermath_debuff) and not InFlightToTarget(rain_of_fire_aftermath) and Enemies() > 1 Spell(rain_of_fire_aftermath)
	#havoc,target=2,if=active_enemies>1
	if Enemies() > 1 Spell(havoc)
	#shadowburn,if=ember_react&(burning_ember>3.5|mana.pct<=20|target.time_to_die<20|buff.havoc.stack>=1|trinket.proc.intellect.react|(trinket.stacking_proc.intellect.remains<cast_time*4&trinket.stacking_proc.intellect.remains>cast_time))
	if BurningEmbers() >= 10 and { BurningEmbers() / 10 > 3.5 or ManaPercent() <= 20 or target.TimeToDie() < 20 or DebuffStacksOnAny(havoc_debuff) >= 1 or BuffPresent(trinket_proc_intellect_buff) or BuffRemaining(trinket_stacking_proc_intellect_buff) < CastTime(shadowburn) * 4 and BuffRemaining(trinket_stacking_proc_intellect_buff) > CastTime(shadowburn) } and target.HealthPercent() < 20 Spell(shadowburn)
	#immolate,cycle_targets=1,if=n_ticks*crit_pct_current>3*dot.immolate.ticks_remain*dot.immolate.crit_pct&miss_react
	if target.Ticks(immolate_debuff) * SpellCritChance() > 3 * target.TicksRemaining(immolate_debuff) * target.DebuffSpellCritChance(immolate_debuff) and True(miss_react) Spell(immolate)
	#conflagrate,if=charges=2&buff.havoc.stack=0
	if Charges(conflagrate) == 2 and DebuffStacksOnAny(havoc_debuff) == 0 Spell(conflagrate)
	#rain_of_fire,if=!ticking&!in_flight,moving=1
	if not target.DebuffPresent(rain_of_fire_aftermath_debuff) and not InFlightToTarget(rain_of_fire_aftermath) and Speed() > 0 Spell(rain_of_fire_aftermath)
	#chaos_bolt,if=ember_react&target.health.pct>20&(buff.backdraft.stack<3|level<86|(active_enemies>1&action.incinerate.cast_time<1))&(burning_ember>(4.5-active_enemies)|buff.skull_banner.remains>cast_time|(trinket.proc.intellect.react&trinket.proc.intellect.remains>cast_time)|(trinket.stacking_proc.intellect.remains<cast_time*2.5&trinket.stacking_proc.intellect.remains>cast_time))
	if BurningEmbers() >= 10 and target.HealthPercent() > 20 and { BuffStacks(backdraft_buff) < 3 or Level() < 86 or Enemies() > 1 and CastTime(incinerate) < 1 } and { BurningEmbers() / 10 > 4.5 - Enemies() or BuffRemaining(skull_banner_buff any=1) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) or BuffRemaining(trinket_stacking_proc_intellect_buff) < CastTime(chaos_bolt) * 2.5 and BuffRemaining(trinket_stacking_proc_intellect_buff) > CastTime(chaos_bolt) } Spell(chaos_bolt)
	#chaos_bolt,if=ember_react&target.health.pct>20&(buff.havoc.stack=3&buff.havoc.remains>cast_time)
	if BurningEmbers() >= 10 and target.HealthPercent() > 20 and DebuffStacksOnAny(havoc_debuff) == 3 and DebuffRemainingOnAny(havoc_debuff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#conflagrate
	Spell(conflagrate)
	#incinerate
	Spell(incinerate)
	#fel_flame,moving=1
	if Speed() > 0 Spell(fel_flame)
}

AddFunction DestructionAoeActions
{
	#summon_infernal
	Spell(summon_infernal)
	#rain_of_fire,if=!ticking&!in_flight
	if not target.DebuffPresent(rain_of_fire_aftermath_debuff) and not InFlightToTarget(rain_of_fire_aftermath) Spell(rain_of_fire_aftermath)
	#fire_and_brimstone,if=ember_react&buff.fire_and_brimstone.down
	if BurningEmbers() >= 10 and BuffExpires(fire_and_brimstone_buff) Spell(fire_and_brimstone)
	#immolate,if=buff.fire_and_brimstone.up&!ticking
	if BuffPresent(fire_and_brimstone_buff) and not target.DebuffPresent(immolate_debuff) Spell(immolate)
	#conflagrate,if=buff.fire_and_brimstone.up
	if BuffPresent(fire_and_brimstone_buff) Spell(conflagrate)
	#incinerate,if=buff.fire_and_brimstone.up
	if BuffPresent(fire_and_brimstone_buff) Spell(incinerate)
	#incinerate
	Spell(incinerate)
}

AddIcon specialization=destruction help=main enemies=1
{
	if InCombat(no) DestructionPrecombatActions()
	DestructionDefaultActions()
}

AddIcon specialization=destruction help=aoe
{
	if InCombat(no) DestructionPrecombatActions()
	DestructionDefaultActions()
}

### Required symbols
# archimondes_darkness_talent
# backdraft_buff
# berserking
# chaos_bolt
# conflagrate
# curse_of_the_elements
# dark_intent
# dark_soul_instability
# fel_flame
# fire_and_brimstone
# fire_and_brimstone_buff
# grimoire_felhunter
# grimoire_of_sacrifice
# grimoire_of_sacrifice_buff
# grimoire_of_sacrifice_talent
# grimoire_of_service_talent
# havoc
# havoc_debuff
# immolate
# immolate_debuff
# incinerate
# jade_serpent_potion
# rain_of_fire_aftermath
# rain_of_fire_aftermath_debuff
# shadowburn
# summon_doomguard
# summon_felhunter
# summon_infernal
# trinket_proc_intellect_buff
# trinket_stacking_proc_intellect_buff
]]
	OvaleScripts:RegisterScript("WARLOCK", name, desc, code, "reference")
end
