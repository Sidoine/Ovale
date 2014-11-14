local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Warlock_Destruction_T17M"
	local desc = "[6.0] SimulationCraft: Warlock_Destruction_T17M"
	local code = [[
# Based on SimulationCraft profile "Warlock_Destruction_T17M".
#	class=warlock
#	spec=destruction
#	talents=0000133
#	pet=felhunter

Include(ovale_common)
Include(ovale_warlock_spells)

AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default)

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction DestructionDefaultActions
{
	#potion,name=draenic_intellect,if=buff.bloodlust.react|target.health.pct<=20
	if BuffPresent(burst_haste_buff any=1) or target.HealthPercent() <= 20 UsePotionIntellect()
	#berserking
	Spell(berserking)
	#blood_fury
	Spell(blood_fury_sp)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#mannoroths_fury
	Spell(mannoroths_fury)
	#dark_soul,if=!talent.archimondes_darkness.enabled|(talent.archimondes_darkness.enabled&(charges=2|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react>6|target.health.pct<=10))
	if not Talent(archimondes_darkness_talent) or Talent(archimondes_darkness_talent) and { Charges(dark_soul_instability) == 2 or BuffPresent(trinket_proc_intellect_buff) or BuffStacks(trinket_stacking_proc_intellect_buff) > 6 or target.HealthPercent() <= 10 } Spell(dark_soul_instability)
	#service_pet,if=talent.grimoire_of_service.enabled
	if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)
	#summon_doomguard,if=!talent.demonic_servitude.enabled&active_enemies<5
	if not Talent(demonic_servitude_talent) and Enemies() < 5 Spell(summon_doomguard)
	#summon_infernal,if=!talent.demonic_servitude.enabled&active_enemies>=5
	if not Talent(demonic_servitude_talent) and Enemies() >= 5 Spell(summon_infernal)
	#run_action_list,name=single_target,if=active_enemies<4
	if Enemies() < 4 DestructionSingleTargetActions()
	#run_action_list,name=aoe,if=active_enemies>=4
	if Enemies() >= 4 DestructionAoeActions()
}

AddFunction DestructionAoeActions
{
	#rain_of_fire,if=remains<=tick_time
	if target.DebuffRemaining(rain_of_fire_debuff) <= target.TickTime(rain_of_fire_debuff) Spell(rain_of_fire)
	#havoc,target=2
	Spell(havoc)
	#shadowburn,if=buff.havoc.remains
	if BuffPresent(havoc_buff) Spell(shadowburn)
	#chaos_bolt,if=buff.havoc.remains>cast_time&buff.havoc.stack>=3
	if BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and BuffStacks(havoc_buff) >= 3 Spell(chaos_bolt)
	#cataclysm
	Spell(cataclysm)
	#fire_and_brimstone,if=buff.fire_and_brimstone.down
	if BuffExpires(fire_and_brimstone_buff) Spell(fire_and_brimstone)
	#immolate,if=buff.fire_and_brimstone.up&!dot.immolate.ticking
	if BuffPresent(fire_and_brimstone_buff) and not target.DebuffPresent(immolate_debuff) Spell(immolate)
	#conflagrate,if=buff.fire_and_brimstone.up&charges=2
	if BuffPresent(fire_and_brimstone_buff) and Charges(conflagrate) == 2 Spell(conflagrate)
	#immolate,if=buff.fire_and_brimstone.up&dot.immolate.remains<=(dot.immolate.duration*0.3)
	if BuffPresent(fire_and_brimstone_buff) and target.DebuffRemaining(immolate_debuff) <= target.DebuffDuration(immolate_debuff) * 0.3 Spell(immolate)
	#chaos_bolt,if=!talent.charred_remains.enabled&active_enemies=4
	if not Talent(charred_remains_talent) and Enemies() == 4 Spell(chaos_bolt)
	#chaos_bolt,if=talent.charred_remains.enabled&buff.fire_and_brimstone.up&burning_ember>=2.5
	if Talent(charred_remains_talent) and BuffPresent(fire_and_brimstone_buff) and BurningEmbers() / 10 >= 2.5 Spell(chaos_bolt)
	#incinerate
	Spell(incinerate)
}

AddFunction DestructionPrecombatActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=blackrock_barbecue
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier_buff any=1) Spell(dark_intent)
	#summon_pet,if=!talent.demonic_servitude.enabled&(!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down)
	if not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() Spell(summon_felhunter)
	#summon_doomguard,if=talent.demonic_servitude.enabled&active_enemies<5
	if Talent(demonic_servitude_talent) and Enemies() < 5 Spell(summon_doomguard)
	#summon_infernal,if=talent.demonic_servitude.enabled&active_enemies>=5
	if Talent(demonic_servitude_talent) and Enemies() >= 5 Spell(summon_infernal)
	#snapshot_stats
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled&!talent.demonic_servitude.enabled
	if Talent(grimoire_of_sacrifice_talent) and not Talent(demonic_servitude_talent) and pet.Present() Spell(grimoire_of_sacrifice)
	#service_pet,if=talent.grimoire_of_service.enabled
	if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)
	#potion,name=draenic_intellect
	UsePotionIntellect()
	#incinerate
	Spell(incinerate)
}

AddFunction DestructionSingleTargetActions
{
	#havoc,target=2
	Spell(havoc)
	#Shadowburn,if=talent.charred_remains.enabled&(burning_ember>=2.5|buff.dark_soul.up|target.time_to_die<10)
	if Talent(charred_remains_talent) and { BurningEmbers() / 10 >= 2.5 or BuffPresent(dark_soul_instability_buff) or target.TimeToDie() < 10 } Spell(Shadowburn)
	#immolate,cycle_targets=1,if=remains<=cast_time&(cooldown.cataclysm.remains>cast_time|!talent.cataclysm.enabled)
	if target.DebuffRemaining(immolate_debuff) <= CastTime(immolate) and { SpellCooldown(cataclysm) > CastTime(immolate) or not Talent(cataclysm_talent) } Spell(immolate)
	#rain_of_fire,if=!ticking
	if not target.DebuffPresent(rain_of_fire_debuff) Spell(rain_of_fire)
	#shadowburn,if=buff.havoc.remains
	if BuffPresent(havoc_buff) Spell(shadowburn)
	#chaos_bolt,if=buff.havoc.remains>cast_time&buff.havoc.stack>=3
	if BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and BuffStacks(havoc_buff) >= 3 Spell(chaos_bolt)
	#conflagrate,if=charges=2
	if Charges(conflagrate) == 2 Spell(conflagrate)
	#cataclysm
	Spell(cataclysm)
	#chaos_bolt,if=talent.charred_remains.enabled&active_enemies>1&target.health.pct>20
	if Talent(charred_remains_talent) and Enemies() > 1 and target.HealthPercent() > 20 Spell(chaos_bolt)
	#chaos_bolt,if=talent.charred_remains.enabled&buff.backdraft.stack<3&burning_ember>=2.5
	if Talent(charred_remains_talent) and BuffStacks(backdraft_buff) < 3 and BurningEmbers() / 10 >= 2.5 Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&(burning_ember>=3.5|buff.dark_soul.up|(burning_ember>=3&buff.ember_master.react)|target.time_to_die<20)
	if BuffStacks(backdraft_buff) < 3 and { BurningEmbers() / 10 >= 3.5 or BuffPresent(dark_soul_instability_buff) or BurningEmbers() / 10 >= 3 and BuffPresent(ember_master_buff) or target.TimeToDie() < 20 } Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&set_bonus.tier17_2pc=1&burning_ember>=2.5
	if BuffStacks(backdraft_buff) < 3 and ArmorSetBonus(T17 2) == 1 and BurningEmbers() / 10 >= 2.5 Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&buff.archmages_greater_incandescence_int.react&buff.archmages_greater_incandescence_int.remains>cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffPresent(archmages_greater_incandescence_int_buff) and BuffRemaining(archmages_greater_incandescence_int_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.proc.intellect.react&trinket.proc.intellect.remains>cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.stacking_proc.intellect.react>7&trinket.stacking_proc.intellect.remains>=cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffStacks(trinket_stacking_proc_intellect_buff) > 7 and BuffRemaining(trinket_stacking_proc_intellect_buff) >= CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.proc.crit.react&trinket.proc.crit.remains>cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_crit_buff) and BuffRemaining(trinket_proc_crit_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.stacking_proc.multistrike.react>=8&trinket.stacking_proc.multistrike.remains>=cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffStacks(trinket_stacking_proc_multistrike_buff) >= 8 and BuffRemaining(trinket_stacking_proc_multistrike_buff) >= CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.proc.multistrike.react&trinket.proc.multistrike.remains>cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_multistrike_buff) and BuffRemaining(trinket_proc_multistrike_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.proc.versatility.react&trinket.proc.versatility.remains>cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_versatility_buff) and BuffRemaining(trinket_proc_versatility_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.proc.mastery.react&trinket.proc.mastery.remains>cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_mastery_buff) and BuffRemaining(trinket_proc_mastery_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#immolate,cycle_targets=1,if=remains<=(duration*0.3)
	if target.DebuffRemaining(immolate_debuff) <= BaseDuration(immolate_debuff) * 0.3 Spell(immolate)
	#conflagrate
	Spell(conflagrate)
	#incinerate,if=talent.charred_remains.enabled
	if Talent(charred_remains_talent) Spell(incinerate)
	#incinerate,if=buff.backdraft.up|mana>=48800
	if BuffPresent(backdraft_buff) or Mana() >= 48800 Spell(incinerate)
}

AddIcon specialization=destruction help=main enemies=1
{
	if not InCombat() DestructionPrecombatActions()
	DestructionDefaultActions()
}

AddIcon specialization=destruction help=aoe
{
	if not InCombat() DestructionPrecombatActions()
	DestructionDefaultActions()
}

### Required symbols
# Shadowburn
# arcane_torrent_mana
# archimondes_darkness_talent
# archmages_greater_incandescence_int_buff
# backdraft_buff
# berserking
# blood_fury_sp
# cataclysm
# cataclysm_talent
# chaos_bolt
# charred_remains_talent
# conflagrate
# dark_intent
# dark_soul_instability
# dark_soul_instability_buff
# demonic_servitude_talent
# draenic_intellect_potion
# ember_master_buff
# fire_and_brimstone
# fire_and_brimstone_buff
# grimoire_felhunter
# grimoire_of_sacrifice
# grimoire_of_sacrifice_buff
# grimoire_of_sacrifice_talent
# grimoire_of_service_talent
# havoc
# havoc_buff
# immolate
# immolate_debuff
# incinerate
# mannoroths_fury
# rain_of_fire
# rain_of_fire_debuff
# shadowburn
# summon_doomguard
# summon_felhunter
# summon_infernal
]]
	OvaleScripts:RegisterScript("WARLOCK", name, desc, code, "reference")
end
