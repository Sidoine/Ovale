local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_warlock_destruction_t17m"
	local desc = "[6.1] SimulationCraft: Warlock_Destruction_T17M"
	local code = [[
# Based on SimulationCraft profile "Warlock_Destruction_T17M".
#	class=warlock
#	spec=destruction
#	talents=0000311
#	pet=felhunter

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)

AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=destruction)

AddFunction DestructionUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

### actions.default

AddFunction DestructionDefaultMainActions
{
	#run_action_list,name=single_target,if=active_enemies<6&(!talent.charred_remains.enabled|active_enemies<4)
	if Enemies() < 6 and { not Talent(charred_remains_talent) or Enemies() < 4 } DestructionSingleTargetMainActions()
	#run_action_list,name=aoe,if=active_enemies>=6|(talent.charred_remains.enabled&active_enemies>=4)
	if Enemies() >= 6 or Talent(charred_remains_talent) and Enemies() >= 4 DestructionAoeMainActions()
}

AddFunction DestructionDefaultShortCdActions
{
	#mannoroths_fury
	Spell(mannoroths_fury)
	#service_pet,if=talent.grimoire_of_service.enabled&(target.time_to_die>120|target.time_to_die<20|(buff.dark_soul.remains&target.health.pct<20))
	if Talent(grimoire_of_service_talent) and { target.TimeToDie() > 120 or target.TimeToDie() < 20 or BuffPresent(dark_soul_instability_buff) and target.HealthPercent() < 20 } Spell(grimoire_felhunter)
	#run_action_list,name=single_target,if=active_enemies<6&(!talent.charred_remains.enabled|active_enemies<4)
	if Enemies() < 6 and { not Talent(charred_remains_talent) or Enemies() < 4 } DestructionSingleTargetShortCdActions()

	unless Enemies() < 6 and { not Talent(charred_remains_talent) or Enemies() < 4 } and DestructionSingleTargetShortCdPostConditions()
	{
		#run_action_list,name=aoe,if=active_enemies>=6|(talent.charred_remains.enabled&active_enemies>=4)
		if Enemies() >= 6 or Talent(charred_remains_talent) and Enemies() >= 4 DestructionAoeShortCdActions()
	}
}

AddFunction DestructionDefaultCdActions
{
	#potion,name=draenic_intellect,if=buff.bloodlust.react&buff.dark_soul.remains>10|target.time_to_die<=25|buff.dark_soul.remains>10
	if BuffPresent(burst_haste_buff any=1) and BuffRemaining(dark_soul_instability_buff) > 10 or target.TimeToDie() <= 25 or BuffRemaining(dark_soul_instability_buff) > 10 DestructionUsePotionIntellect()
	#berserking
	Spell(berserking)
	#blood_fury
	Spell(blood_fury_sp)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#dark_soul,if=!talent.archimondes_darkness.enabled|(talent.archimondes_darkness.enabled&(charges=2|trinket.proc.any.react|trinket.stacking_any.intellect.react>6|target.time_to_die<40))
	if not Talent(archimondes_darkness_talent) or Talent(archimondes_darkness_talent) and { Charges(dark_soul_instability) == 2 or BuffPresent(trinket_proc_any_buff) or BuffStacks(trinket_stacking_any_intellect_buff) > 6 or target.TimeToDie() < 40 } Spell(dark_soul_instability)

	unless Talent(grimoire_of_service_talent) and { target.TimeToDie() > 120 or target.TimeToDie() < 20 or BuffPresent(dark_soul_instability_buff) and target.HealthPercent() < 20 } and Spell(grimoire_felhunter)
	{
		#summon_doomguard,if=!talent.demonic_servitude.enabled&active_enemies<9
		if not Talent(demonic_servitude_talent) and Enemies() < 9 Spell(summon_doomguard)
		#summon_infernal,if=!talent.demonic_servitude.enabled&active_enemies>=9
		if not Talent(demonic_servitude_talent) and Enemies() >= 9 Spell(summon_infernal)
	}
}

### actions.aoe

AddFunction DestructionAoeMainActions
{
	#rain_of_fire,if=!talent.charred_remains.enabled&remains<=tick_time
	if not Talent(charred_remains_talent) and target.DebuffRemaining(rain_of_fire_debuff) <= target.TickTime(rain_of_fire_debuff) Spell(rain_of_fire)
	#shadowburn,if=!talent.charred_remains.enabled&buff.havoc.remains
	if not Talent(charred_remains_talent) and BuffPresent(havoc_buff) Spell(shadowburn)
	#chaos_bolt,if=!talent.charred_remains.enabled&buff.havoc.remains>cast_time&buff.havoc.stack>=3
	if not Talent(charred_remains_talent) and BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and BuffStacks(havoc_buff) >= 3 Spell(chaos_bolt)
	#immolate,if=buff.fire_and_brimstone.up&!dot.immolate.ticking
	if BuffPresent(fire_and_brimstone_buff) and not target.DebuffPresent(immolate_debuff) Spell(immolate)
	#conflagrate,if=buff.fire_and_brimstone.up&charges=2
	if BuffPresent(fire_and_brimstone_buff) and Charges(conflagrate) == 2 Spell(conflagrate)
	#immolate,if=buff.fire_and_brimstone.up&dot.immolate.remains<=(dot.immolate.duration*0.3)
	if BuffPresent(fire_and_brimstone_buff) and target.DebuffRemaining(immolate_debuff) <= target.DebuffDuration(immolate_debuff) * 0.3 Spell(immolate)
	#chaos_bolt,if=talent.charred_remains.enabled&buff.fire_and_brimstone.up
	if Talent(charred_remains_talent) and BuffPresent(fire_and_brimstone_buff) Spell(chaos_bolt)
	#incinerate
	Spell(incinerate)
}

AddFunction DestructionAoeShortCdActions
{
	unless not Talent(charred_remains_talent) and target.DebuffRemaining(rain_of_fire_debuff) <= target.TickTime(rain_of_fire_debuff) and Spell(rain_of_fire)
	{
		#havoc,target=2,if=(!talent.charred_remains.enabled|buff.fire_and_brimstone.down)
		if { not Talent(charred_remains_talent) or BuffExpires(fire_and_brimstone_buff) } and Enemies() > 1 Spell(havoc text=other)

		unless not Talent(charred_remains_talent) and BuffPresent(havoc_buff) and Spell(shadowburn) or not Talent(charred_remains_talent) and BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and BuffStacks(havoc_buff) >= 3 and Spell(chaos_bolt)
		{
			#kiljaedens_cunning,if=(talent.cataclysm.enabled&!cooldown.cataclysm.remains)
			if Talent(cataclysm_talent) and not SpellCooldown(cataclysm) > 0 Spell(kiljaedens_cunning)
			#kiljaedens_cunning,moving=1,if=!talent.cataclysm.enabled
			if Speed() > 0 and not Talent(cataclysm_talent) Spell(kiljaedens_cunning)
			#cataclysm
			Spell(cataclysm)
			#fire_and_brimstone,if=buff.fire_and_brimstone.down
			if BuffExpires(fire_and_brimstone_buff) Spell(fire_and_brimstone)
		}
	}
}

### actions.precombat

AddFunction DestructionPrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=pickled_eel
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier_buff any=1) Spell(dark_intent)
	#snapshot_stats
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled&!talent.demonic_servitude.enabled
	if Talent(grimoire_of_sacrifice_talent) and not Talent(demonic_servitude_talent) and pet.Present() Spell(grimoire_of_sacrifice)
	#incinerate
	Spell(incinerate)
}

AddFunction DestructionPrecombatShortCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent)
	{
		#summon_pet,if=!talent.demonic_servitude.enabled&(!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down)
		if not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() Spell(summon_felhunter)
		#service_pet,if=talent.grimoire_of_service.enabled
		if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)
	}
}

AddFunction DestructionPrecombatShortCdPostConditions
{
	not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or Spell(incinerate)
}

AddFunction DestructionPrecombatCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() and Spell(summon_felhunter)
	{
		#summon_doomguard,if=talent.demonic_servitude.enabled&active_enemies<9
		if Talent(demonic_servitude_talent) and Enemies() < 9 Spell(summon_doomguard)
		#summon_infernal,if=talent.demonic_servitude.enabled&active_enemies>=9
		if Talent(demonic_servitude_talent) and Enemies() >= 9 Spell(summon_infernal)

		unless Talent(grimoire_of_service_talent) and Spell(grimoire_felhunter)
		{
			#potion,name=draenic_intellect
			DestructionUsePotionIntellect()
		}
	}
}

AddFunction DestructionPrecombatCdPostConditions
{
	not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() and Spell(summon_felhunter) or Talent(grimoire_of_service_talent) and Spell(grimoire_felhunter) or Spell(incinerate)
}

### actions.single_target

AddFunction DestructionSingleTargetMainActions
{
	#shadowburn,if=talent.charred_remains.enabled&(burning_ember>=2.5|buff.dark_soul.up|target.time_to_die<10)
	if Talent(charred_remains_talent) and { BurningEmbers() / 10 >= 2.5 or BuffPresent(dark_soul_instability_buff) or target.TimeToDie() < 10 } Spell(shadowburn)
	#immolate,cycle_targets=1,if=remains<=cast_time&(cooldown.cataclysm.remains>cast_time|!talent.cataclysm.enabled)
	if target.DebuffRemaining(immolate_debuff) <= CastTime(immolate) and { SpellCooldown(cataclysm) > CastTime(immolate) or not Talent(cataclysm_talent) } Spell(immolate)
	#shadowburn,if=buff.havoc.remains
	if BuffPresent(havoc_buff) Spell(shadowburn)
	#chaos_bolt,if=buff.havoc.remains>cast_time&buff.havoc.stack>=3
	if BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and BuffStacks(havoc_buff) >= 3 Spell(chaos_bolt)
	#conflagrate,if=charges=2
	if Charges(conflagrate) == 2 Spell(conflagrate)
	#rain_of_fire,if=remains<=tick_time&(active_enemies>4|(buff.mannoroths_fury.up&active_enemies>2))
	if target.DebuffRemaining(rain_of_fire_debuff) <= target.TickTime(rain_of_fire_debuff) and { Enemies() > 4 or BuffPresent(mannoroths_fury_buff) and Enemies() > 2 } Spell(rain_of_fire)
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
	#incinerate
	Spell(incinerate)
}

AddFunction DestructionSingleTargetShortCdActions
{
	#havoc,target=2
	if Enemies() > 1 Spell(havoc text=other)

	unless Talent(charred_remains_talent) and { BurningEmbers() / 10 >= 2.5 or BuffPresent(dark_soul_instability_buff) or target.TimeToDie() < 10 } and Spell(shadowburn)
	{
		#kiljaedens_cunning,if=(talent.cataclysm.enabled&!cooldown.cataclysm.remains)
		if Talent(cataclysm_talent) and not SpellCooldown(cataclysm) > 0 Spell(kiljaedens_cunning)
		#kiljaedens_cunning,moving=1,if=!talent.cataclysm.enabled
		if Speed() > 0 and not Talent(cataclysm_talent) Spell(kiljaedens_cunning)
		#cataclysm,if=active_enemies>1
		if Enemies() > 1 Spell(cataclysm)
		#fire_and_brimstone,if=buff.fire_and_brimstone.down&dot.immolate.remains<=action.immolate.cast_time&(cooldown.cataclysm.remains>action.immolate.cast_time|!talent.cataclysm.enabled)&active_enemies>4
		if BuffExpires(fire_and_brimstone_buff) and target.DebuffRemaining(immolate_debuff) <= CastTime(immolate) and { SpellCooldown(cataclysm) > CastTime(immolate) or not Talent(cataclysm_talent) } and Enemies() > 4 Spell(fire_and_brimstone)

		unless target.DebuffRemaining(immolate_debuff) <= CastTime(immolate) and { SpellCooldown(cataclysm) > CastTime(immolate) or not Talent(cataclysm_talent) } and Spell(immolate) or BuffPresent(havoc_buff) and Spell(shadowburn) or BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and BuffStacks(havoc_buff) >= 3 and Spell(chaos_bolt) or Charges(conflagrate) == 2 and Spell(conflagrate)
		{
			#cataclysm
			Spell(cataclysm)

			unless target.DebuffRemaining(rain_of_fire_debuff) <= target.TickTime(rain_of_fire_debuff) and { Enemies() > 4 or BuffPresent(mannoroths_fury_buff) and Enemies() > 2 } and Spell(rain_of_fire) or Talent(charred_remains_talent) and Enemies() > 1 and target.HealthPercent() > 20 and Spell(chaos_bolt) or Talent(charred_remains_talent) and BuffStacks(backdraft_buff) < 3 and BurningEmbers() / 10 >= 2.5 and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and { BurningEmbers() / 10 >= 3.5 or BuffPresent(dark_soul_instability_buff) or BurningEmbers() / 10 >= 3 and BuffPresent(ember_master_buff) or target.TimeToDie() < 20 } and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and ArmorSetBonus(T17 2) == 1 and BurningEmbers() / 10 >= 2.5 and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(archmages_greater_incandescence_int_buff) and BuffRemaining(archmages_greater_incandescence_int_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffStacks(trinket_stacking_proc_intellect_buff) > 7 and BuffRemaining(trinket_stacking_proc_intellect_buff) >= CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_crit_buff) and BuffRemaining(trinket_proc_crit_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffStacks(trinket_stacking_proc_multistrike_buff) >= 8 and BuffRemaining(trinket_stacking_proc_multistrike_buff) >= CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_multistrike_buff) and BuffRemaining(trinket_proc_multistrike_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_versatility_buff) and BuffRemaining(trinket_proc_versatility_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_mastery_buff) and BuffRemaining(trinket_proc_mastery_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt)
			{
				#fire_and_brimstone,if=buff.fire_and_brimstone.down&dot.immolate.remains<=(dot.immolate.duration*0.3)&active_enemies>4
				if BuffExpires(fire_and_brimstone_buff) and target.DebuffRemaining(immolate_debuff) <= target.DebuffDuration(immolate_debuff) * 0.3 and Enemies() > 4 Spell(fire_and_brimstone)
			}
		}
	}
}

AddFunction DestructionSingleTargetShortCdPostConditions
{
	Talent(charred_remains_talent) and { BurningEmbers() / 10 >= 2.5 or BuffPresent(dark_soul_instability_buff) or target.TimeToDie() < 10 } and Spell(shadowburn) or target.DebuffRemaining(immolate_debuff) <= CastTime(immolate) and { SpellCooldown(cataclysm) > CastTime(immolate) or not Talent(cataclysm_talent) } and Spell(immolate) or BuffPresent(havoc_buff) and Spell(shadowburn) or BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and BuffStacks(havoc_buff) >= 3 and Spell(chaos_bolt) or Charges(conflagrate) == 2 and Spell(conflagrate) or target.DebuffRemaining(rain_of_fire_debuff) <= target.TickTime(rain_of_fire_debuff) and { Enemies() > 4 or BuffPresent(mannoroths_fury_buff) and Enemies() > 2 } and Spell(rain_of_fire) or Talent(charred_remains_talent) and Enemies() > 1 and target.HealthPercent() > 20 and Spell(chaos_bolt) or Talent(charred_remains_talent) and BuffStacks(backdraft_buff) < 3 and BurningEmbers() / 10 >= 2.5 and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and { BurningEmbers() / 10 >= 3.5 or BuffPresent(dark_soul_instability_buff) or BurningEmbers() / 10 >= 3 and BuffPresent(ember_master_buff) or target.TimeToDie() < 20 } and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and ArmorSetBonus(T17 2) == 1 and BurningEmbers() / 10 >= 2.5 and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(archmages_greater_incandescence_int_buff) and BuffRemaining(archmages_greater_incandescence_int_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffStacks(trinket_stacking_proc_intellect_buff) > 7 and BuffRemaining(trinket_stacking_proc_intellect_buff) >= CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_crit_buff) and BuffRemaining(trinket_proc_crit_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffStacks(trinket_stacking_proc_multistrike_buff) >= 8 and BuffRemaining(trinket_stacking_proc_multistrike_buff) >= CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_multistrike_buff) and BuffRemaining(trinket_proc_multistrike_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_versatility_buff) and BuffRemaining(trinket_proc_versatility_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_mastery_buff) and BuffRemaining(trinket_proc_mastery_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or target.DebuffRemaining(immolate_debuff) <= BaseDuration(immolate_debuff) * 0.3 and Spell(immolate) or Spell(conflagrate) or Spell(incinerate)
}

### Destruction icons.

AddCheckBox(opt_warlock_destruction_aoe L(AOE) default specialization=destruction)

AddIcon checkbox=!opt_warlock_destruction_aoe enemies=1 help=shortcd specialization=destruction
{
	if not InCombat() DestructionPrecombatShortCdActions()
	unless not InCombat() and DestructionPrecombatShortCdPostConditions()
	{
		DestructionDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_warlock_destruction_aoe help=shortcd specialization=destruction
{
	if not InCombat() DestructionPrecombatShortCdActions()
	unless not InCombat() and DestructionPrecombatShortCdPostConditions()
	{
		DestructionDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=destruction
{
	if not InCombat() DestructionPrecombatMainActions()
	DestructionDefaultMainActions()
}

AddIcon checkbox=opt_warlock_destruction_aoe help=aoe specialization=destruction
{
	if not InCombat() DestructionPrecombatMainActions()
	DestructionDefaultMainActions()
}

AddIcon checkbox=!opt_warlock_destruction_aoe enemies=1 help=cd specialization=destruction
{
	if not InCombat() DestructionPrecombatCdActions()
	unless not InCombat() and DestructionPrecombatCdPostConditions()
	{
		DestructionDefaultCdActions()
	}
}

AddIcon checkbox=opt_warlock_destruction_aoe help=cd specialization=destruction
{
	if not InCombat() DestructionPrecombatCdActions()
	unless not InCombat() and DestructionPrecombatCdPostConditions()
	{
		DestructionDefaultCdActions()
	}
}

### Required symbols
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
# kiljaedens_cunning
# mannoroths_fury
# mannoroths_fury_buff
# rain_of_fire
# rain_of_fire_debuff
# shadowburn
# summon_doomguard
# summon_felhunter
# summon_infernal
# trinket_stacking_any_intellect_buff
]]
	OvaleScripts:RegisterScript("WARLOCK", "destruction", name, desc, code, "script")
end
