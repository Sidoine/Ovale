local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "ovale_warlock_demonology"
    local desc = "[7.0] Ovale Demonology Warlock"
    local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)

AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=demonology)
AddCheckBox(opt_legendary_ring_intellect ItemName(legendary_ring_intellect) default specialization=demonology)

AddFunction DemonologyUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

### actions.default

AddFunction DemonologyDefaultMainActions
{
	if Talent(soul_harvest_talent) and not SpellCooldown(soul_harvest) > 0 and not target.DebuffRemaining(doom_debuff) Spell(doom)
	if Talent(impending_doom_talent) and target.DebuffRemaining(doom_debuff) <= CastTime(hand_of_guldan) Spell(doom)
	Spell(call_dreadstalkers)
	Spell(demonic_empowerment)
	if SoulShards() >= 4 Spell(hand_of_guldan)
	if Talent(impending_doom_talent) and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 Spell(doom)
	Spell(demonbolt)
	Spell(shadow_bolt)
	Spell(life_tap)
}

AddFunction DemonologyDefaultShortCdActions
{
	Spell(service_felguard)
}

AddFunction DemonologyDefaultCdActions
{
	if CheckBoxOn(opt_legendary_ring_intellect) Item(legendary_ring_intellect usable=1)
	Spell(berserking)
	Spell(blood_fury_sp)
	Spell(arcane_torrent_mana)
	if BuffPresent(nithramus_buff) DemonologyUsePotionIntellect()

	unless Spell(service_felguard)
	{
		if not Talent(grimoire_of_supremacy_talent) and Enemies() < 3 Spell(summon_doomguard)
		if not Talent(grimoire_of_supremacy_talent) and Enemies() >= 3 Spell(summon_infernal)
		if target.DebuffRemaining(doom_debuff) Spell(soul_harvest)
	}
}

### actions.precombat

AddFunction DemonologyPrecombatMainActions
{
}

AddFunction DemonologyPrecombatShortCdActions
{
	if not Talent(grimoire_of_supremacy_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(demonic_power_buff) } and not pet.Present() Spell(summon_felguard)
}

AddFunction DemonologyPrecombatShortCdPostConditions
{
	Spell(demonic_empowerment)
}

AddFunction DemonologyPrecombatCdActions
{
	unless not Talent(grimoire_of_supremacy_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(demonic_power_buff) } and not pet.Present() and Spell(summon_felguard)
	{
		if Talent(grimoire_of_supremacy_talent) and Enemies() < 3 Spell(summon_doomguard)
		if Talent(grimoire_of_supremacy_talent) and Enemies() >= 3 Spell(summon_infernal)
		DemonologyUsePotionIntellect()
	}
}

AddFunction DemonologyPrecombatCdPostConditions
{
	not Talent(grimoire_of_supremacy_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(demonic_power_buff) } and not pet.Present() and Spell(summon_felguard) or Spell(demonic_empowerment)
}

### Demonology icons.

AddCheckBox(opt_warlock_demonology_aoe L(AOE) default specialization=demonology)

AddIcon checkbox=!opt_warlock_demonology_aoe enemies=1 help=shortcd specialization=demonology
{
	if not InCombat() DemonologyPrecombatShortCdActions()
	unless not InCombat() and DemonologyPrecombatShortCdPostConditions()
	{
		DemonologyDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_warlock_demonology_aoe help=shortcd specialization=demonology
{
	if not InCombat() DemonologyPrecombatShortCdActions()
	unless not InCombat() and DemonologyPrecombatShortCdPostConditions()
	{
		DemonologyDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=demonology
{
	if not InCombat() DemonologyPrecombatMainActions()
	DemonologyDefaultMainActions()
}

AddIcon checkbox=opt_warlock_demonology_aoe help=aoe specialization=demonology
{
	if not InCombat() DemonologyPrecombatMainActions()
	DemonologyDefaultMainActions()
}

AddIcon checkbox=!opt_warlock_demonology_aoe enemies=1 help=cd specialization=demonology
{
	if not InCombat() DemonologyPrecombatCdActions()
	unless not InCombat() and DemonologyPrecombatCdPostConditions()
	{
		DemonologyDefaultCdActions()
	}
}

AddIcon checkbox=opt_warlock_demonology_aoe help=cd specialization=demonology
{
	if not InCombat() DemonologyPrecombatCdActions()
	unless not InCombat() and DemonologyPrecombatCdPostConditions()
	{
		DemonologyDefaultCdActions()
	}
}

	]]
    OvaleScripts:RegisterScript("WARLOCK", "demonology", name, desc, code, "script")
end
do
    local name = "sc_warlock_destruction_t19"
    local desc = "[7.0] Simulationcraft: Warlock_Destruction_T19"
    local code = [[
# Based on SimulationCraft profile "Warlock_Destruction_T19P".
#	class=warlock
#	spec=destruction
#	talents=2203022
#	pet=imp

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)
### Destruction icons.

AddCheckBox(opt_warlock_destruction_aoe L(AOE) default specialization=destruction)
]]
    OvaleScripts:RegisterScript("WARLOCK", "destruction", name, desc, code, "script")
end
do
    local name = "sc_warlock_affliction_t19"
    local desc = "[7.0] Simulationcraft: Warlock_Affliction_T19"
    local code = [[
# Based on SimulationCraft profile "Warlock_Affliction_T19P".
#	class=warlock
#	spec=affliction
#	talents=3101011
#	pet=felhunter

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)

AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=affliction)

### actions.writhe

AddFunction AfflictionWritheMainActions
{
 #reap_souls,if=!buff.deadwind_harvester.remains&time>5&(buff.tormented_souls.react>=5|target.time_to_die<=buff.tormented_souls.react*(5+1.5*equipped.144364)+(buff.deadwind_harvester.remains*(5+1.5*equipped.144364)%12*(5+1.5*equipped.144364)))
 if not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 5 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } Spell(reap_souls)
 #reap_souls,if=!buff.deadwind_harvester.remains&time>5&(buff.soul_harvest.remains>=(5+1.5*equipped.144364)&buff.active_uas.stack>1|buff.concordance_of_the_legionfall.react|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react|trinket.proc.mastery.react|trinket.stacking_proc.mastery.react|trinket.proc.crit.react|trinket.stacking_proc.crit.react|trinket.proc.versatility.react|trinket.stacking_proc.versatility.react|trinket.proc.spell_power.react|trinket.stacking_proc.spell_power.react)
 if not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffRemaining(soul_harvest_buff) >= 5 + 1 * HasEquippedItem(144364) and target.DebuffStacks(unstable_affliction_debuff) > 1 or BuffPresent(concordance_of_the_legionfall_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_stacking_proc_intellect_buff) or BuffPresent(trinket_proc_mastery_buff) or BuffPresent(trinket_stacking_proc_mastery_buff) or BuffPresent(trinket_proc_crit_buff) or BuffPresent(trinket_stacking_proc_crit_buff) or BuffPresent(trinket_proc_versatility_buff) or BuffPresent(trinket_stacking_proc_versatility_buff) or BuffPresent(trinket_proc_spell_power_buff) or BuffPresent(trinket_stacking_proc_spell_power_buff) } Spell(reap_souls)
 #agony,if=remains<=tick_time+gcd
 if target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() Spell(agony)
 #agony,cycle_targets=1,max_cycle_targets=5,target_if=sim.target!=target&talent.soul_harvest.enabled&cooldown.soul_harvest.remains<cast_time*6&remains<=duration*0.3&target.time_to_die>=remains&time_to_die>tick_time*3
 if DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 5 and False(target_is_sim_target) and Talent(soul_harvest_talent) and SpellCooldown(soul_harvest) < CastTime(agony) * 6 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 Spell(agony)
 #agony,cycle_targets=1,max_cycle_targets=3,target_if=sim.target!=target&remains<=tick_time+gcd&time_to_die>tick_time*3
 if DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 3 and False(target_is_sim_target) and target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and target.TimeToDie() > target.TickTime(agony_debuff) * 3 Spell(agony)
 #seed_of_corruption,if=talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption>=3&soul_shard=5
 if Talent(sow_the_seeds_talent) and Enemies() >= 3 and SoulShards() == 5 Spell(seed_of_corruption)
 #unstable_affliction,if=soul_shard=5|(time_to_die<=((duration+cast_time)*soul_shard))
 if SoulShards() == 5 or target.TimeToDie() <= { BaseDuration(unstable_affliction_debuff) + CastTime(unstable_affliction) } * SoulShards() Spell(unstable_affliction)
 #drain_soul,cycle_targets=1,if=target.time_to_die<=gcd*2&soul_shard<5
 if target.TimeToDie() <= GCD() * 2 and SoulShards() < 5 Spell(drain_soul)
 #life_tap,if=talent.empowered_life_tap.enabled&buff.empowered_life_tap.remains<=gcd
 if Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() Spell(life_tap)
 #siphon_life,cycle_targets=1,if=remains<=tick_time+gcd&time_to_die>tick_time*2
 if target.DebuffRemaining(siphon_life_debuff) <= target.TickTime(siphon_life_debuff) + GCD() and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 2 Spell(siphon_life)
 #corruption,cycle_targets=1,if=remains<=tick_time+gcd&((spell_targets.seed_of_corruption<3&talent.sow_the_seeds.enabled)|spell_targets.seed_of_corruption<5)&time_to_die>tick_time*2
 if target.DebuffRemaining(corruption_debuff) <= target.TickTime(corruption_debuff) + GCD() and { Enemies() < 3 and Talent(sow_the_seeds_talent) or Enemies() < 5 } and target.TimeToDie() > target.TickTime(corruption_debuff) * 2 Spell(corruption)
 #life_tap,if=mana.pct<40&(buff.active_uas.stack<1|!buff.deadwind_harvester.remains)
 if ManaPercent() < 40 and { target.DebuffStacks(unstable_affliction_debuff) < 1 or not BuffPresent(deadwind_harvester_buff) } Spell(life_tap)
 #reap_souls,if=(buff.deadwind_harvester.remains+buff.tormented_souls.react*(5+equipped.144364))>=(12*(5+1.5*equipped.144364))
 if BuffRemaining(deadwind_harvester_buff) + BuffStacks(tormented_souls_buff) * { 5 + HasEquippedItem(144364) } >= 12 * { 5 + 1 * HasEquippedItem(144364) } Spell(reap_souls)
 #seed_of_corruption,if=(talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption>=3)|(spell_targets.seed_of_corruption>3&dot.corruption.refreshable)
 if Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() > 3 and target.DebuffRefreshable(corruption_debuff) Spell(seed_of_corruption)
 #unstable_affliction,if=talent.contagion.enabled&dot.unstable_affliction_1.remains<cast_time&dot.unstable_affliction_2.remains<cast_time&dot.unstable_affliction_3.remains<cast_time&dot.unstable_affliction_4.remains<cast_time&dot.unstable_affliction_5.remains<cast_time
 if Talent(contagion_talent) and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) Spell(unstable_affliction)
 #unstable_affliction,cycle_targets=1,target_if=buff.deadwind_harvester.remains>=duration+cast_time&dot.unstable_affliction_1.remains<cast_time&dot.unstable_affliction_2.remains<cast_time&dot.unstable_affliction_3.remains<cast_time&dot.unstable_affliction_4.remains<cast_time&dot.unstable_affliction_5.remains<cast_time
 if BuffRemaining(deadwind_harvester_buff) >= BaseDuration(unstable_affliction_debuff) + CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) Spell(unstable_affliction)
 #unstable_affliction,if=buff.deadwind_harvester.remains>tick_time*2&(!talent.contagion.enabled|soul_shard>1|buff.soul_harvest.remains)&(dot.unstable_affliction_1.ticking+dot.unstable_affliction_2.ticking+dot.unstable_affliction_3.ticking+dot.unstable_affliction_4.ticking+dot.unstable_affliction_5.ticking<5)
 if BuffRemaining(deadwind_harvester_buff) > target.TickTime(unstable_affliction_debuff) * 2 and { not Talent(contagion_talent) or SoulShards() > 1 or BuffPresent(soul_harvest_buff) } and target.DebuffPresent(unstable_affliction_debuff) + target.DebuffPresent(unstable_affliction_debuff) + target.DebuffPresent(unstable_affliction_debuff) + target.DebuffPresent(unstable_affliction_debuff) + target.DebuffPresent(unstable_affliction_debuff) < 5 Spell(unstable_affliction)
 #reap_souls,if=!buff.deadwind_harvester.remains&buff.active_uas.stack>1
 if not BuffPresent(deadwind_harvester_buff) and target.DebuffStacks(unstable_affliction_debuff) > 1 Spell(reap_souls)
 #reap_souls,if=!buff.deadwind_harvester.remains&prev_gcd.1.unstable_affliction&buff.tormented_souls.react>1
 if not BuffPresent(deadwind_harvester_buff) and PreviousGCDSpell(unstable_affliction) and BuffStacks(tormented_souls_buff) > 1 Spell(reap_souls)
 #life_tap,if=talent.empowered_life_tap.enabled&buff.empowered_life_tap.remains<duration*0.3&(!buff.deadwind_harvester.remains|buff.active_uas.stack<1)
 if Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) < BaseDuration(empowered_life_tap_buff) * 0 and { not BuffPresent(deadwind_harvester_buff) or target.DebuffStacks(unstable_affliction_debuff) < 1 } Spell(life_tap)
 #agony,if=refreshable&time_to_die>=remains
 if target.Refreshable(agony_debuff) and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) Spell(agony)
 #siphon_life,if=refreshable&time_to_die>=remains
 if target.Refreshable(siphon_life_debuff) and target.TimeToDie() >= target.DebuffRemaining(siphon_life_debuff) Spell(siphon_life)
 #corruption,if=refreshable&time_to_die>=remains
 if target.Refreshable(corruption_debuff) and target.TimeToDie() >= target.DebuffRemaining(corruption_debuff) Spell(corruption)
 #agony,cycle_targets=1,target_if=sim.target!=target&time_to_die>tick_time*3&!buff.deadwind_harvester.remains&refreshable&time_to_die>tick_time*3
 if False(target_is_sim_target) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and not BuffPresent(deadwind_harvester_buff) and target.Refreshable(agony_debuff) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 Spell(agony)
 #siphon_life,cycle_targets=1,target_if=sim.target!=target&time_to_die>tick_time*3&!buff.deadwind_harvester.remains&refreshable&time_to_die>tick_time*3
 if False(target_is_sim_target) and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 3 and not BuffPresent(deadwind_harvester_buff) and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 3 Spell(siphon_life)
 #corruption,cycle_targets=1,target_if=sim.target!=target&time_to_die>tick_time*3&!buff.deadwind_harvester.remains&refreshable&time_to_die>tick_time*3
 if False(target_is_sim_target) and target.TimeToDie() > target.TickTime(corruption_debuff) * 3 and not BuffPresent(deadwind_harvester_buff) and target.Refreshable(corruption_debuff) and target.TimeToDie() > target.TickTime(corruption_debuff) * 3 Spell(corruption)
 #life_tap,if=mana.pct<=10
 if ManaPercent() <= 10 Spell(life_tap)
 #life_tap,if=prev_gcd.1.life_tap&buff.active_uas.stack=0&mana.pct<50
 if PreviousGCDSpell(life_tap) and target.DebuffStacks(unstable_affliction_debuff) == 0 and ManaPercent() < 50 Spell(life_tap)
 #drain_soul,chain=1,interrupt=1
 Spell(drain_soul)
 #life_tap,moving=1,if=mana.pct<80
 if Speed() > 0 and ManaPercent() < 80 Spell(life_tap)
 #agony,moving=1,cycle_targets=1,if=remains<=duration-(3*tick_time)
 if Speed() > 0 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) - 3 * target.TickTime(agony_debuff) Spell(agony)
 #siphon_life,moving=1,cycle_targets=1,if=remains<=duration-(3*tick_time)
 if Speed() > 0 and target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) - 3 * target.TickTime(siphon_life_debuff) Spell(siphon_life)
 #corruption,moving=1,cycle_targets=1,if=remains<=duration-(3*tick_time)
 if Speed() > 0 and target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) - 3 * target.TickTime(corruption_debuff) Spell(corruption)
 #life_tap,moving=0
 if not Speed() > 0 Spell(life_tap)
}

AddFunction AfflictionWritheMainPostConditions
{
}

AddFunction AfflictionWritheShortCdActions
{
 unless not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 5 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } and Spell(reap_souls) or not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffRemaining(soul_harvest_buff) >= 5 + 1 * HasEquippedItem(144364) and target.DebuffStacks(unstable_affliction_debuff) > 1 or BuffPresent(concordance_of_the_legionfall_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_stacking_proc_intellect_buff) or BuffPresent(trinket_proc_mastery_buff) or BuffPresent(trinket_stacking_proc_mastery_buff) or BuffPresent(trinket_proc_crit_buff) or BuffPresent(trinket_stacking_proc_crit_buff) or BuffPresent(trinket_proc_versatility_buff) or BuffPresent(trinket_stacking_proc_versatility_buff) or BuffPresent(trinket_proc_spell_power_buff) or BuffPresent(trinket_stacking_proc_spell_power_buff) } and Spell(reap_souls) or target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 5 and False(target_is_sim_target) and Talent(soul_harvest_talent) and SpellCooldown(soul_harvest) < CastTime(agony) * 6 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 3 and False(target_is_sim_target) and target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or Talent(sow_the_seeds_talent) and Enemies() >= 3 and SoulShards() == 5 and Spell(seed_of_corruption) or { SoulShards() == 5 or target.TimeToDie() <= { BaseDuration(unstable_affliction_debuff) + CastTime(unstable_affliction) } * SoulShards() } and Spell(unstable_affliction) or target.TimeToDie() <= GCD() * 2 and SoulShards() < 5 and Spell(drain_soul) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap)
 {
  #service_pet,if=dot.corruption.remains&dot.agony.remains
  if target.DebuffRemaining(corruption_debuff) and target.DebuffRemaining(agony_debuff) Spell(service_felhunter)

  unless target.DebuffRemaining(siphon_life_debuff) <= target.TickTime(siphon_life_debuff) + GCD() and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 2 and Spell(siphon_life) or target.DebuffRemaining(corruption_debuff) <= target.TickTime(corruption_debuff) + GCD() and { Enemies() < 3 and Talent(sow_the_seeds_talent) or Enemies() < 5 } and target.TimeToDie() > target.TickTime(corruption_debuff) * 2 and Spell(corruption) or ManaPercent() < 40 and { target.DebuffStacks(unstable_affliction_debuff) < 1 or not BuffPresent(deadwind_harvester_buff) } and Spell(life_tap) or BuffRemaining(deadwind_harvester_buff) + BuffStacks(tormented_souls_buff) * { 5 + HasEquippedItem(144364) } >= 12 * { 5 + 1 * HasEquippedItem(144364) } and Spell(reap_souls)
  {
   #phantom_singularity
   Spell(phantom_singularity)
  }
 }
}

AddFunction AfflictionWritheShortCdPostConditions
{
 not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 5 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } and Spell(reap_souls) or not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffRemaining(soul_harvest_buff) >= 5 + 1 * HasEquippedItem(144364) and target.DebuffStacks(unstable_affliction_debuff) > 1 or BuffPresent(concordance_of_the_legionfall_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_stacking_proc_intellect_buff) or BuffPresent(trinket_proc_mastery_buff) or BuffPresent(trinket_stacking_proc_mastery_buff) or BuffPresent(trinket_proc_crit_buff) or BuffPresent(trinket_stacking_proc_crit_buff) or BuffPresent(trinket_proc_versatility_buff) or BuffPresent(trinket_stacking_proc_versatility_buff) or BuffPresent(trinket_proc_spell_power_buff) or BuffPresent(trinket_stacking_proc_spell_power_buff) } and Spell(reap_souls) or target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 5 and False(target_is_sim_target) and Talent(soul_harvest_talent) and SpellCooldown(soul_harvest) < CastTime(agony) * 6 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 3 and False(target_is_sim_target) and target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or Talent(sow_the_seeds_talent) and Enemies() >= 3 and SoulShards() == 5 and Spell(seed_of_corruption) or { SoulShards() == 5 or target.TimeToDie() <= { BaseDuration(unstable_affliction_debuff) + CastTime(unstable_affliction) } * SoulShards() } and Spell(unstable_affliction) or target.TimeToDie() <= GCD() * 2 and SoulShards() < 5 and Spell(drain_soul) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap) or target.DebuffRemaining(siphon_life_debuff) <= target.TickTime(siphon_life_debuff) + GCD() and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 2 and Spell(siphon_life) or target.DebuffRemaining(corruption_debuff) <= target.TickTime(corruption_debuff) + GCD() and { Enemies() < 3 and Talent(sow_the_seeds_talent) or Enemies() < 5 } and target.TimeToDie() > target.TickTime(corruption_debuff) * 2 and Spell(corruption) or ManaPercent() < 40 and { target.DebuffStacks(unstable_affliction_debuff) < 1 or not BuffPresent(deadwind_harvester_buff) } and Spell(life_tap) or BuffRemaining(deadwind_harvester_buff) + BuffStacks(tormented_souls_buff) * { 5 + HasEquippedItem(144364) } >= 12 * { 5 + 1 * HasEquippedItem(144364) } and Spell(reap_souls) or { Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() > 3 and target.DebuffRefreshable(corruption_debuff) } and Spell(seed_of_corruption) or Talent(contagion_talent) and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) and Spell(unstable_affliction) or BuffRemaining(deadwind_harvester_buff) >= BaseDuration(unstable_affliction_debuff) + CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) and Spell(unstable_affliction) or BuffRemaining(deadwind_harvester_buff) > target.TickTime(unstable_affliction_debuff) * 2 and { not Talent(contagion_talent) or SoulShards() > 1 or BuffPresent(soul_harvest_buff) } and target.DebuffPresent(unstable_affliction_debuff) + target.DebuffPresent(unstable_affliction_debuff) + target.DebuffPresent(unstable_affliction_debuff) + target.DebuffPresent(unstable_affliction_debuff) + target.DebuffPresent(unstable_affliction_debuff) < 5 and Spell(unstable_affliction) or not BuffPresent(deadwind_harvester_buff) and target.DebuffStacks(unstable_affliction_debuff) > 1 and Spell(reap_souls) or not BuffPresent(deadwind_harvester_buff) and PreviousGCDSpell(unstable_affliction) and BuffStacks(tormented_souls_buff) > 1 and Spell(reap_souls) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) < BaseDuration(empowered_life_tap_buff) * 0 and { not BuffPresent(deadwind_harvester_buff) or target.DebuffStacks(unstable_affliction_debuff) < 1 } and Spell(life_tap) or target.Refreshable(agony_debuff) and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and Spell(agony) or target.Refreshable(siphon_life_debuff) and target.TimeToDie() >= target.DebuffRemaining(siphon_life_debuff) and Spell(siphon_life) or target.Refreshable(corruption_debuff) and target.TimeToDie() >= target.DebuffRemaining(corruption_debuff) and Spell(corruption) or False(target_is_sim_target) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and not BuffPresent(deadwind_harvester_buff) and target.Refreshable(agony_debuff) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or False(target_is_sim_target) and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 3 and not BuffPresent(deadwind_harvester_buff) and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 3 and Spell(siphon_life) or False(target_is_sim_target) and target.TimeToDie() > target.TickTime(corruption_debuff) * 3 and not BuffPresent(deadwind_harvester_buff) and target.Refreshable(corruption_debuff) and target.TimeToDie() > target.TickTime(corruption_debuff) * 3 and Spell(corruption) or ManaPercent() <= 10 and Spell(life_tap) or PreviousGCDSpell(life_tap) and target.DebuffStacks(unstable_affliction_debuff) == 0 and ManaPercent() < 50 and Spell(life_tap) or Spell(drain_soul) or Speed() > 0 and ManaPercent() < 80 and Spell(life_tap) or Speed() > 0 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) - 3 * target.TickTime(agony_debuff) and Spell(agony) or Speed() > 0 and target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) - 3 * target.TickTime(siphon_life_debuff) and Spell(siphon_life) or Speed() > 0 and target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) - 3 * target.TickTime(corruption_debuff) and Spell(corruption) or not Speed() > 0 and Spell(life_tap)
}

AddFunction AfflictionWritheCdActions
{
 unless not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 5 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } and Spell(reap_souls) or not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffRemaining(soul_harvest_buff) >= 5 + 1 * HasEquippedItem(144364) and target.DebuffStacks(unstable_affliction_debuff) > 1 or BuffPresent(concordance_of_the_legionfall_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_stacking_proc_intellect_buff) or BuffPresent(trinket_proc_mastery_buff) or BuffPresent(trinket_stacking_proc_mastery_buff) or BuffPresent(trinket_proc_crit_buff) or BuffPresent(trinket_stacking_proc_crit_buff) or BuffPresent(trinket_proc_versatility_buff) or BuffPresent(trinket_stacking_proc_versatility_buff) or BuffPresent(trinket_proc_spell_power_buff) or BuffPresent(trinket_stacking_proc_spell_power_buff) } and Spell(reap_souls) or target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 5 and False(target_is_sim_target) and Talent(soul_harvest_talent) and SpellCooldown(soul_harvest) < CastTime(agony) * 6 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 3 and False(target_is_sim_target) and target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or Talent(sow_the_seeds_talent) and Enemies() >= 3 and SoulShards() == 5 and Spell(seed_of_corruption) or { SoulShards() == 5 or target.TimeToDie() <= { BaseDuration(unstable_affliction_debuff) + CastTime(unstable_affliction) } * SoulShards() } and Spell(unstable_affliction) or target.TimeToDie() <= GCD() * 2 and SoulShards() < 5 and Spell(drain_soul) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap) or target.DebuffRemaining(corruption_debuff) and target.DebuffRemaining(agony_debuff) and Spell(service_felhunter)
 {
  #summon_doomguard,if=!talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal<=2&(target.time_to_die>180|target.health.pct<=20|target.time_to_die<30)
  if not Talent(grimoire_of_supremacy_talent) and Enemies() <= 2 and { target.TimeToDie() > 180 or target.HealthPercent() <= 20 or target.TimeToDie() < 30 } Spell(summon_doomguard)
  #summon_infernal,if=!talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal>2
  if not Talent(grimoire_of_supremacy_talent) and Enemies() > 2 Spell(summon_infernal)
  #summon_doomguard,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal=1&equipped.132379&!cooldown.sindorei_spite_icd.remains
  if Talent(grimoire_of_supremacy_talent) and Enemies() == 1 and HasEquippedItem(132379) and not SpellCooldown(sindorei_spite_icd) > 0 Spell(summon_doomguard)
  #summon_infernal,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal>1&equipped.132379&!cooldown.sindorei_spite_icd.remains
  if Talent(grimoire_of_supremacy_talent) and Enemies() > 1 and HasEquippedItem(132379) and not SpellCooldown(sindorei_spite_icd) > 0 Spell(summon_infernal)
  #berserking,if=prev_gcd.1.unstable_affliction|buff.soul_harvest.remains>=10
  if PreviousGCDSpell(unstable_affliction) or BuffRemaining(soul_harvest_buff) >= 10 Spell(berserking)
  #blood_fury
  Spell(blood_fury_sp)
  #soul_harvest,if=sim.target=target&buff.soul_harvest.remains<=8&(buff.active_uas.stack>=2|active_enemies>3)&(!talent.deaths_embrace.enabled|time_to_die>120|time_to_die<30)
  if True(target_is_sim_target) and BuffRemaining(soul_harvest_buff) <= 8 and { target.DebuffStacks(unstable_affliction_debuff) >= 2 or Enemies() > 3 } and { not Talent(deaths_embrace_talent) or target.TimeToDie() > 120 or target.TimeToDie() < 30 } Spell(soul_harvest)
  #potion,if=target.time_to_die<=70
  if target.TimeToDie() <= 70 and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
  #potion,if=(!talent.soul_harvest.enabled|buff.soul_harvest.remains>12)&(trinket.proc.any.react|trinket.stack_proc.any.react|buff.active_uas.stack>=2)
  if { not Talent(soul_harvest_talent) or BuffRemaining(soul_harvest_buff) > 12 } and { BuffPresent(trinket_proc_any_buff) or BuffPresent(trinket_stack_proc_any_buff) or target.DebuffStacks(unstable_affliction_debuff) >= 2 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 }
}

AddFunction AfflictionWritheCdPostConditions
{
 not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 5 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } and Spell(reap_souls) or not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffRemaining(soul_harvest_buff) >= 5 + 1 * HasEquippedItem(144364) and target.DebuffStacks(unstable_affliction_debuff) > 1 or BuffPresent(concordance_of_the_legionfall_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_stacking_proc_intellect_buff) or BuffPresent(trinket_proc_mastery_buff) or BuffPresent(trinket_stacking_proc_mastery_buff) or BuffPresent(trinket_proc_crit_buff) or BuffPresent(trinket_stacking_proc_crit_buff) or BuffPresent(trinket_proc_versatility_buff) or BuffPresent(trinket_stacking_proc_versatility_buff) or BuffPresent(trinket_proc_spell_power_buff) or BuffPresent(trinket_stacking_proc_spell_power_buff) } and Spell(reap_souls) or target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 5 and False(target_is_sim_target) and Talent(soul_harvest_talent) and SpellCooldown(soul_harvest) < CastTime(agony) * 6 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 3 and False(target_is_sim_target) and target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or Talent(sow_the_seeds_talent) and Enemies() >= 3 and SoulShards() == 5 and Spell(seed_of_corruption) or { SoulShards() == 5 or target.TimeToDie() <= { BaseDuration(unstable_affliction_debuff) + CastTime(unstable_affliction) } * SoulShards() } and Spell(unstable_affliction) or target.TimeToDie() <= GCD() * 2 and SoulShards() < 5 and Spell(drain_soul) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap) or target.DebuffRemaining(corruption_debuff) and target.DebuffRemaining(agony_debuff) and Spell(service_felhunter) or target.DebuffRemaining(siphon_life_debuff) <= target.TickTime(siphon_life_debuff) + GCD() and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 2 and Spell(siphon_life) or target.DebuffRemaining(corruption_debuff) <= target.TickTime(corruption_debuff) + GCD() and { Enemies() < 3 and Talent(sow_the_seeds_talent) or Enemies() < 5 } and target.TimeToDie() > target.TickTime(corruption_debuff) * 2 and Spell(corruption) or ManaPercent() < 40 and { target.DebuffStacks(unstable_affliction_debuff) < 1 or not BuffPresent(deadwind_harvester_buff) } and Spell(life_tap) or BuffRemaining(deadwind_harvester_buff) + BuffStacks(tormented_souls_buff) * { 5 + HasEquippedItem(144364) } >= 12 * { 5 + 1 * HasEquippedItem(144364) } and Spell(reap_souls) or Spell(phantom_singularity) or { Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() > 3 and target.DebuffRefreshable(corruption_debuff) } and Spell(seed_of_corruption) or Talent(contagion_talent) and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) and Spell(unstable_affliction) or BuffRemaining(deadwind_harvester_buff) >= BaseDuration(unstable_affliction_debuff) + CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) and Spell(unstable_affliction) or BuffRemaining(deadwind_harvester_buff) > target.TickTime(unstable_affliction_debuff) * 2 and { not Talent(contagion_talent) or SoulShards() > 1 or BuffPresent(soul_harvest_buff) } and target.DebuffPresent(unstable_affliction_debuff) + target.DebuffPresent(unstable_affliction_debuff) + target.DebuffPresent(unstable_affliction_debuff) + target.DebuffPresent(unstable_affliction_debuff) + target.DebuffPresent(unstable_affliction_debuff) < 5 and Spell(unstable_affliction) or not BuffPresent(deadwind_harvester_buff) and target.DebuffStacks(unstable_affliction_debuff) > 1 and Spell(reap_souls) or not BuffPresent(deadwind_harvester_buff) and PreviousGCDSpell(unstable_affliction) and BuffStacks(tormented_souls_buff) > 1 and Spell(reap_souls) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) < BaseDuration(empowered_life_tap_buff) * 0 and { not BuffPresent(deadwind_harvester_buff) or target.DebuffStacks(unstable_affliction_debuff) < 1 } and Spell(life_tap) or target.Refreshable(agony_debuff) and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and Spell(agony) or target.Refreshable(siphon_life_debuff) and target.TimeToDie() >= target.DebuffRemaining(siphon_life_debuff) and Spell(siphon_life) or target.Refreshable(corruption_debuff) and target.TimeToDie() >= target.DebuffRemaining(corruption_debuff) and Spell(corruption) or False(target_is_sim_target) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and not BuffPresent(deadwind_harvester_buff) and target.Refreshable(agony_debuff) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or False(target_is_sim_target) and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 3 and not BuffPresent(deadwind_harvester_buff) and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 3 and Spell(siphon_life) or False(target_is_sim_target) and target.TimeToDie() > target.TickTime(corruption_debuff) * 3 and not BuffPresent(deadwind_harvester_buff) and target.Refreshable(corruption_debuff) and target.TimeToDie() > target.TickTime(corruption_debuff) * 3 and Spell(corruption) or ManaPercent() <= 10 and Spell(life_tap) or PreviousGCDSpell(life_tap) and target.DebuffStacks(unstable_affliction_debuff) == 0 and ManaPercent() < 50 and Spell(life_tap) or Spell(drain_soul) or Speed() > 0 and ManaPercent() < 80 and Spell(life_tap) or Speed() > 0 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) - 3 * target.TickTime(agony_debuff) and Spell(agony) or Speed() > 0 and target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) - 3 * target.TickTime(siphon_life_debuff) and Spell(siphon_life) or Speed() > 0 and target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) - 3 * target.TickTime(corruption_debuff) and Spell(corruption) or not Speed() > 0 and Spell(life_tap)
}

### actions.precombat

AddFunction AfflictionPrecombatMainActions
{
 #snapshot_stats
 #grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
 if Talent(grimoire_of_sacrifice_talent) and pet.Present() Spell(grimoire_of_sacrifice)
 #life_tap,if=talent.empowered_life_tap.enabled&!buff.empowered_life_tap.remains
 if Talent(empowered_life_tap_talent) and not BuffPresent(empowered_life_tap_buff) Spell(life_tap)
}

AddFunction AfflictionPrecombatMainPostConditions
{
}

AddFunction AfflictionPrecombatShortCdActions
{
 #flask
 #food
 #augmentation
 #summon_pet,if=!talent.grimoire_of_supremacy.enabled&(!talent.grimoire_of_sacrifice.enabled|buff.demonic_power.down)
 if not Talent(grimoire_of_supremacy_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(demonic_power_buff) } and not pet.Present() Spell(summon_felhunter)
}

AddFunction AfflictionPrecombatShortCdPostConditions
{
 Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice) or Talent(empowered_life_tap_talent) and not BuffPresent(empowered_life_tap_buff) and Spell(life_tap)
}

AddFunction AfflictionPrecombatCdActions
{
 unless not Talent(grimoire_of_supremacy_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(demonic_power_buff) } and not pet.Present() and Spell(summon_felhunter)
 {
  #summon_infernal,if=talent.grimoire_of_supremacy.enabled&artifact.lord_of_flames.rank>0
  if Talent(grimoire_of_supremacy_talent) and ArtifactTraitRank(lord_of_flames) > 0 Spell(summon_infernal)
  #summon_infernal,if=talent.grimoire_of_supremacy.enabled&active_enemies>1
  if Talent(grimoire_of_supremacy_talent) and Enemies() > 1 Spell(summon_infernal)
  #summon_doomguard,if=talent.grimoire_of_supremacy.enabled&active_enemies=1&artifact.lord_of_flames.rank=0
  if Talent(grimoire_of_supremacy_talent) and Enemies() == 1 and ArtifactTraitRank(lord_of_flames) == 0 Spell(summon_doomguard)

  unless Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice) or Talent(empowered_life_tap_talent) and not BuffPresent(empowered_life_tap_buff) and Spell(life_tap)
  {
   #potion
   if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
  }
 }
}

AddFunction AfflictionPrecombatCdPostConditions
{
 not Talent(grimoire_of_supremacy_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(demonic_power_buff) } and not pet.Present() and Spell(summon_felhunter) or Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice) or Talent(empowered_life_tap_talent) and not BuffPresent(empowered_life_tap_buff) and Spell(life_tap)
}

### actions.mg

AddFunction AfflictionMgMainActions
{
 #reap_souls,if=!buff.deadwind_harvester.remains&time>5&((buff.tormented_souls.react>=4+active_enemies|buff.tormented_souls.react>=9)|target.time_to_die<=buff.tormented_souls.react*(5+1.5*equipped.144364)+(buff.deadwind_harvester.remains*(5+1.5*equipped.144364)%12*(5+1.5*equipped.144364)))
 if not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 4 + Enemies() or BuffStacks(tormented_souls_buff) >= 9 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } Spell(reap_souls)
 #agony,cycle_targets=1,max_cycle_targets=5,target_if=sim.target!=target&talent.soul_harvest.enabled&cooldown.soul_harvest.remains<cast_time*6&remains<=duration*0.3&target.time_to_die>=remains&time_to_die>tick_time*3
 if DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 5 and False(target_is_sim_target) and Talent(soul_harvest_talent) and SpellCooldown(soul_harvest) < CastTime(agony) * 6 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 Spell(agony)
 #agony,cycle_targets=1,max_cycle_targets=4,if=remains<=(tick_time+gcd)
 if DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 4 and target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() Spell(agony)
 #seed_of_corruption,if=talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption>=3&soul_shard=5
 if Talent(sow_the_seeds_talent) and Enemies() >= 3 and SoulShards() == 5 Spell(seed_of_corruption)
 #unstable_affliction,if=target=sim.target&soul_shard=5
 if True(target_is_sim_target) and SoulShards() == 5 Spell(unstable_affliction)
 #drain_soul,cycle_targets=1,if=target.time_to_die<gcd*2&soul_shard<5
 if target.TimeToDie() < GCD() * 2 and SoulShards() < 5 Spell(drain_soul)
 #life_tap,if=talent.empowered_life_tap.enabled&buff.empowered_life_tap.remains<=gcd
 if Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() Spell(life_tap)
 #siphon_life,cycle_targets=1,if=remains<=(tick_time+gcd)&target.time_to_die>tick_time*3
 if target.DebuffRemaining(siphon_life_debuff) <= target.TickTime(siphon_life_debuff) + GCD() and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 3 Spell(siphon_life)
 #corruption,cycle_targets=1,if=(!talent.sow_the_seeds.enabled|spell_targets.seed_of_corruption<3)&spell_targets.seed_of_corruption<5&remains<=(tick_time+gcd)&target.time_to_die>tick_time*3
 if { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and target.DebuffRemaining(corruption_debuff) <= target.TickTime(corruption_debuff) + GCD() and target.TimeToDie() > target.TickTime(corruption_debuff) * 3 Spell(corruption)
 #agony,cycle_targets=1,if=remains<=(duration*0.3)&target.time_to_die>=remains&(buff.active_uas.stack=0|prev_gcd.1.agony)
 if target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and { target.DebuffStacks(unstable_affliction_debuff) == 0 or PreviousGCDSpell(agony) } Spell(agony)
 #siphon_life,cycle_targets=1,if=remains<=(duration*0.3)&target.time_to_die>=remains&(buff.active_uas.stack=0|prev_gcd.1.siphon_life)
 if target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(siphon_life_debuff) and { target.DebuffStacks(unstable_affliction_debuff) == 0 or PreviousGCDSpell(siphon_life) } Spell(siphon_life)
 #corruption,cycle_targets=1,if=(!talent.sow_the_seeds.enabled|spell_targets.seed_of_corruption<3)&spell_targets.seed_of_corruption<5&remains<=(duration*0.3)&target.time_to_die>=remains&(buff.active_uas.stack=0|prev_gcd.1.corruption)
 if { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(corruption_debuff) and { target.DebuffStacks(unstable_affliction_debuff) == 0 or PreviousGCDSpell(corruption) } Spell(corruption)
 #life_tap,if=talent.empowered_life_tap.enabled&buff.empowered_life_tap.remains<duration*0.3|talent.malefic_grasp.enabled&target.time_to_die>15&mana.pct<10
 if Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) < BaseDuration(empowered_life_tap_buff) * 0 or Talent(malefic_grasp_talent) and target.TimeToDie() > 15 and ManaPercent() < 10 Spell(life_tap)
 #seed_of_corruption,if=(talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption>=3)|(spell_targets.seed_of_corruption>=5&dot.corruption.remains<=cast_time+travel_time)
 if Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() >= 5 and target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TravelTime(seed_of_corruption) Spell(seed_of_corruption)
 #unstable_affliction,if=target=sim.target&target.time_to_die<30
 if True(target_is_sim_target) and target.TimeToDie() < 30 Spell(unstable_affliction)
 #unstable_affliction,if=target=sim.target&active_enemies>1&soul_shard>=4
 if True(target_is_sim_target) and Enemies() > 1 and SoulShards() >= 4 Spell(unstable_affliction)
 #unstable_affliction,if=target=sim.target&(buff.active_uas.stack=0|(!prev_gcd.3.unstable_affliction&prev_gcd.1.unstable_affliction))&dot.agony.remains>cast_time+(6.5*spell_haste)
 if True(target_is_sim_target) and { target.DebuffStacks(unstable_affliction_debuff) == 0 or not PreviousGCDSpell(unstable_affliction count=3) and PreviousGCDSpell(unstable_affliction) } and target.DebuffRemaining(agony_debuff) > CastTime(unstable_affliction) + 6 * { 100 / { 100 + SpellCastSpeedPercent() } } Spell(unstable_affliction)
 #reap_souls,if=buff.deadwind_harvester.remains<dot.unstable_affliction_1.remains|buff.deadwind_harvester.remains<dot.unstable_affliction_2.remains|buff.deadwind_harvester.remains<dot.unstable_affliction_3.remains|buff.deadwind_harvester.remains<dot.unstable_affliction_4.remains|buff.deadwind_harvester.remains<dot.unstable_affliction_5.remains&buff.active_uas.stack>1
 if BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 1 } or BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 2 } or BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 3 } or BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 4 } or BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 5 } and target.DebuffStacks(unstable_affliction_debuff) > 1 Spell(reap_souls)
 #life_tap,if=mana.pct<=10
 if ManaPercent() <= 10 Spell(life_tap)
 #life_tap,if=prev_gcd.1.life_tap&buff.active_uas.stack=0&mana.pct<50
 if PreviousGCDSpell(life_tap) and target.DebuffStacks(unstable_affliction_debuff) == 0 and ManaPercent() < 50 Spell(life_tap)
 #drain_soul,chain=1,interrupt=1
 Spell(drain_soul)
 #life_tap,moving=1,if=mana.pct<80
 if Speed() > 0 and ManaPercent() < 80 Spell(life_tap)
 #agony,moving=1,cycle_targets=1,if=remains<duration-(3*tick_time)
 if Speed() > 0 and target.DebuffRemaining(agony_debuff) < BaseDuration(agony_debuff) - 3 * target.TickTime(agony_debuff) Spell(agony)
 #siphon_life,moving=1,cycle_targets=1,if=remains<duration-(3*tick_time)
 if Speed() > 0 and target.DebuffRemaining(siphon_life_debuff) < BaseDuration(siphon_life_debuff) - 3 * target.TickTime(siphon_life_debuff) Spell(siphon_life)
 #corruption,moving=1,cycle_targets=1,if=remains<duration-(3*tick_time)
 if Speed() > 0 and target.DebuffRemaining(corruption_debuff) < BaseDuration(corruption_debuff) - 3 * target.TickTime(corruption_debuff) Spell(corruption)
 #life_tap,moving=0
 if not Speed() > 0 Spell(life_tap)
}

AddFunction AfflictionMgMainPostConditions
{
}

AddFunction AfflictionMgShortCdActions
{
 unless not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 4 + Enemies() or BuffStacks(tormented_souls_buff) >= 9 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } and Spell(reap_souls) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 5 and False(target_is_sim_target) and Talent(soul_harvest_talent) and SpellCooldown(soul_harvest) < CastTime(agony) * 6 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 4 and target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and Spell(agony) or Talent(sow_the_seeds_talent) and Enemies() >= 3 and SoulShards() == 5 and Spell(seed_of_corruption) or True(target_is_sim_target) and SoulShards() == 5 and Spell(unstable_affliction) or target.TimeToDie() < GCD() * 2 and SoulShards() < 5 and Spell(drain_soul) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap)
 {
  #service_pet,if=dot.corruption.remains&dot.agony.remains
  if target.DebuffRemaining(corruption_debuff) and target.DebuffRemaining(agony_debuff) Spell(service_felhunter)

  unless target.DebuffRemaining(siphon_life_debuff) <= target.TickTime(siphon_life_debuff) + GCD() and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 3 and Spell(siphon_life) or { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and target.DebuffRemaining(corruption_debuff) <= target.TickTime(corruption_debuff) + GCD() and target.TimeToDie() > target.TickTime(corruption_debuff) * 3 and Spell(corruption)
  {
   #phantom_singularity
   Spell(phantom_singularity)
  }
 }
}

AddFunction AfflictionMgShortCdPostConditions
{
 not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 4 + Enemies() or BuffStacks(tormented_souls_buff) >= 9 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } and Spell(reap_souls) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 5 and False(target_is_sim_target) and Talent(soul_harvest_talent) and SpellCooldown(soul_harvest) < CastTime(agony) * 6 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 4 and target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and Spell(agony) or Talent(sow_the_seeds_talent) and Enemies() >= 3 and SoulShards() == 5 and Spell(seed_of_corruption) or True(target_is_sim_target) and SoulShards() == 5 and Spell(unstable_affliction) or target.TimeToDie() < GCD() * 2 and SoulShards() < 5 and Spell(drain_soul) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap) or target.DebuffRemaining(siphon_life_debuff) <= target.TickTime(siphon_life_debuff) + GCD() and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 3 and Spell(siphon_life) or { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and target.DebuffRemaining(corruption_debuff) <= target.TickTime(corruption_debuff) + GCD() and target.TimeToDie() > target.TickTime(corruption_debuff) * 3 and Spell(corruption) or target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and { target.DebuffStacks(unstable_affliction_debuff) == 0 or PreviousGCDSpell(agony) } and Spell(agony) or target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(siphon_life_debuff) and { target.DebuffStacks(unstable_affliction_debuff) == 0 or PreviousGCDSpell(siphon_life) } and Spell(siphon_life) or { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(corruption_debuff) and { target.DebuffStacks(unstable_affliction_debuff) == 0 or PreviousGCDSpell(corruption) } and Spell(corruption) or { Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) < BaseDuration(empowered_life_tap_buff) * 0 or Talent(malefic_grasp_talent) and target.TimeToDie() > 15 and ManaPercent() < 10 } and Spell(life_tap) or { Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() >= 5 and target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TravelTime(seed_of_corruption) } and Spell(seed_of_corruption) or True(target_is_sim_target) and target.TimeToDie() < 30 and Spell(unstable_affliction) or True(target_is_sim_target) and Enemies() > 1 and SoulShards() >= 4 and Spell(unstable_affliction) or True(target_is_sim_target) and { target.DebuffStacks(unstable_affliction_debuff) == 0 or not PreviousGCDSpell(unstable_affliction count=3) and PreviousGCDSpell(unstable_affliction) } and target.DebuffRemaining(agony_debuff) > CastTime(unstable_affliction) + 6 * { 100 / { 100 + SpellCastSpeedPercent() } } and Spell(unstable_affliction) or { BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 1 } or BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 2 } or BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 3 } or BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 4 } or BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 5 } and target.DebuffStacks(unstable_affliction_debuff) > 1 } and Spell(reap_souls) or ManaPercent() <= 10 and Spell(life_tap) or PreviousGCDSpell(life_tap) and target.DebuffStacks(unstable_affliction_debuff) == 0 and ManaPercent() < 50 and Spell(life_tap) or Spell(drain_soul) or Speed() > 0 and ManaPercent() < 80 and Spell(life_tap) or Speed() > 0 and target.DebuffRemaining(agony_debuff) < BaseDuration(agony_debuff) - 3 * target.TickTime(agony_debuff) and Spell(agony) or Speed() > 0 and target.DebuffRemaining(siphon_life_debuff) < BaseDuration(siphon_life_debuff) - 3 * target.TickTime(siphon_life_debuff) and Spell(siphon_life) or Speed() > 0 and target.DebuffRemaining(corruption_debuff) < BaseDuration(corruption_debuff) - 3 * target.TickTime(corruption_debuff) and Spell(corruption) or not Speed() > 0 and Spell(life_tap)
}

AddFunction AfflictionMgCdActions
{
 unless not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 4 + Enemies() or BuffStacks(tormented_souls_buff) >= 9 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } and Spell(reap_souls) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 5 and False(target_is_sim_target) and Talent(soul_harvest_talent) and SpellCooldown(soul_harvest) < CastTime(agony) * 6 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 4 and target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and Spell(agony) or Talent(sow_the_seeds_talent) and Enemies() >= 3 and SoulShards() == 5 and Spell(seed_of_corruption) or True(target_is_sim_target) and SoulShards() == 5 and Spell(unstable_affliction) or target.TimeToDie() < GCD() * 2 and SoulShards() < 5 and Spell(drain_soul) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap) or target.DebuffRemaining(corruption_debuff) and target.DebuffRemaining(agony_debuff) and Spell(service_felhunter)
 {
  #summon_doomguard,if=!talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal<=2&(target.time_to_die>180|target.health.pct<=20|target.time_to_die<30)
  if not Talent(grimoire_of_supremacy_talent) and Enemies() <= 2 and { target.TimeToDie() > 180 or target.HealthPercent() <= 20 or target.TimeToDie() < 30 } Spell(summon_doomguard)
  #summon_infernal,if=!talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal>2
  if not Talent(grimoire_of_supremacy_talent) and Enemies() > 2 Spell(summon_infernal)
  #summon_doomguard,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal=1&equipped.132379&!cooldown.sindorei_spite_icd.remains
  if Talent(grimoire_of_supremacy_talent) and Enemies() == 1 and HasEquippedItem(132379) and not SpellCooldown(sindorei_spite_icd) > 0 Spell(summon_doomguard)
  #summon_infernal,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal>1&equipped.132379&!cooldown.sindorei_spite_icd.remains
  if Talent(grimoire_of_supremacy_talent) and Enemies() > 1 and HasEquippedItem(132379) and not SpellCooldown(sindorei_spite_icd) > 0 Spell(summon_infernal)
  #berserking,if=prev_gcd.1.unstable_affliction|buff.soul_harvest.remains>=10
  if PreviousGCDSpell(unstable_affliction) or BuffRemaining(soul_harvest_buff) >= 10 Spell(berserking)
  #blood_fury
  Spell(blood_fury_sp)

  unless target.DebuffRemaining(siphon_life_debuff) <= target.TickTime(siphon_life_debuff) + GCD() and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 3 and Spell(siphon_life) or { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and target.DebuffRemaining(corruption_debuff) <= target.TickTime(corruption_debuff) + GCD() and target.TimeToDie() > target.TickTime(corruption_debuff) * 3 and Spell(corruption) or Spell(phantom_singularity)
  {
   #soul_harvest,if=buff.active_uas.stack>1&buff.soul_harvest.remains<=8&sim.target=target&(!talent.deaths_embrace.enabled|target.time_to_die>=136|target.time_to_die<=40)
   if target.DebuffStacks(unstable_affliction_debuff) > 1 and BuffRemaining(soul_harvest_buff) <= 8 and True(target_is_sim_target) and { not Talent(deaths_embrace_talent) or target.TimeToDie() >= 136 or target.TimeToDie() <= 40 } Spell(soul_harvest)
   #potion,if=target.time_to_die<=70
   if target.TimeToDie() <= 70 and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
   #potion,if=(!talent.soul_harvest.enabled|buff.soul_harvest.remains>12)&buff.active_uas.stack>=2
   if { not Talent(soul_harvest_talent) or BuffRemaining(soul_harvest_buff) > 12 } and target.DebuffStacks(unstable_affliction_debuff) >= 2 and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
  }
 }
}

AddFunction AfflictionMgCdPostConditions
{
 not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 4 + Enemies() or BuffStacks(tormented_souls_buff) >= 9 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } and Spell(reap_souls) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 5 and False(target_is_sim_target) and Talent(soul_harvest_talent) and SpellCooldown(soul_harvest) < CastTime(agony) * 6 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and target.TimeToDie() > target.TickTime(agony_debuff) * 3 and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 4 and target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and Spell(agony) or Talent(sow_the_seeds_talent) and Enemies() >= 3 and SoulShards() == 5 and Spell(seed_of_corruption) or True(target_is_sim_target) and SoulShards() == 5 and Spell(unstable_affliction) or target.TimeToDie() < GCD() * 2 and SoulShards() < 5 and Spell(drain_soul) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap) or target.DebuffRemaining(corruption_debuff) and target.DebuffRemaining(agony_debuff) and Spell(service_felhunter) or target.DebuffRemaining(siphon_life_debuff) <= target.TickTime(siphon_life_debuff) + GCD() and target.TimeToDie() > target.TickTime(siphon_life_debuff) * 3 and Spell(siphon_life) or { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and target.DebuffRemaining(corruption_debuff) <= target.TickTime(corruption_debuff) + GCD() and target.TimeToDie() > target.TickTime(corruption_debuff) * 3 and Spell(corruption) or Spell(phantom_singularity) or target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and { target.DebuffStacks(unstable_affliction_debuff) == 0 or PreviousGCDSpell(agony) } and Spell(agony) or target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(siphon_life_debuff) and { target.DebuffStacks(unstable_affliction_debuff) == 0 or PreviousGCDSpell(siphon_life) } and Spell(siphon_life) or { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(corruption_debuff) and { target.DebuffStacks(unstable_affliction_debuff) == 0 or PreviousGCDSpell(corruption) } and Spell(corruption) or { Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) < BaseDuration(empowered_life_tap_buff) * 0 or Talent(malefic_grasp_talent) and target.TimeToDie() > 15 and ManaPercent() < 10 } and Spell(life_tap) or { Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() >= 5 and target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TravelTime(seed_of_corruption) } and Spell(seed_of_corruption) or True(target_is_sim_target) and target.TimeToDie() < 30 and Spell(unstable_affliction) or True(target_is_sim_target) and Enemies() > 1 and SoulShards() >= 4 and Spell(unstable_affliction) or True(target_is_sim_target) and { target.DebuffStacks(unstable_affliction_debuff) == 0 or not PreviousGCDSpell(unstable_affliction count=3) and PreviousGCDSpell(unstable_affliction) } and target.DebuffRemaining(agony_debuff) > CastTime(unstable_affliction) + 6 * { 100 / { 100 + SpellCastSpeedPercent() } } and Spell(unstable_affliction) or { BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 1 } or BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 2 } or BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 3 } or BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 4 } or BuffRemaining(deadwind_harvester_buff) < { target.DebuffStacks(unstable_affliction_debuff) >= 5 } and target.DebuffStacks(unstable_affliction_debuff) > 1 } and Spell(reap_souls) or ManaPercent() <= 10 and Spell(life_tap) or PreviousGCDSpell(life_tap) and target.DebuffStacks(unstable_affliction_debuff) == 0 and ManaPercent() < 50 and Spell(life_tap) or Spell(drain_soul) or Speed() > 0 and ManaPercent() < 80 and Spell(life_tap) or Speed() > 0 and target.DebuffRemaining(agony_debuff) < BaseDuration(agony_debuff) - 3 * target.TickTime(agony_debuff) and Spell(agony) or Speed() > 0 and target.DebuffRemaining(siphon_life_debuff) < BaseDuration(siphon_life_debuff) - 3 * target.TickTime(siphon_life_debuff) and Spell(siphon_life) or Speed() > 0 and target.DebuffRemaining(corruption_debuff) < BaseDuration(corruption_debuff) - 3 * target.TickTime(corruption_debuff) and Spell(corruption) or not Speed() > 0 and Spell(life_tap)
}

### actions.haunt

AddFunction AfflictionHauntMainActions
{
 #reap_souls,if=!buff.deadwind_harvester.remains&time>5&(buff.tormented_souls.react>=5|target.time_to_die<=buff.tormented_souls.react*(5+1.5*equipped.144364)+(buff.deadwind_harvester.remains*(5+1.5*equipped.144364)%12*(5+1.5*equipped.144364)))
 if not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 5 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } Spell(reap_souls)
 #reap_souls,if=debuff.haunt.remains&!buff.deadwind_harvester.remains
 if target.DebuffPresent(haunt_debuff) and not BuffPresent(deadwind_harvester_buff) Spell(reap_souls)
 #reap_souls,if=active_enemies>1&!buff.deadwind_harvester.remains&time>5&soul_shard>0&((talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption>=3)|spell_targets.seed_of_corruption>=5)
 if Enemies() > 1 and not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and SoulShards() > 0 and { Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() >= 5 } Spell(reap_souls)
 #agony,cycle_targets=1,if=remains<=tick_time+gcd
 if target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() Spell(agony)
 #drain_soul,cycle_targets=1,if=target.time_to_die<=gcd*2&soul_shard<5
 if target.TimeToDie() <= GCD() * 2 and SoulShards() < 5 Spell(drain_soul)
 #siphon_life,cycle_targets=1,if=remains<=tick_time+gcd
 if target.DebuffRemaining(siphon_life_debuff) <= target.TickTime(siphon_life_debuff) + GCD() Spell(siphon_life)
 #corruption,cycle_targets=1,if=remains<=tick_time+gcd&(spell_targets.seed_of_corruption<3&talent.sow_the_seeds.enabled|spell_targets.seed_of_corruption<5)
 if target.DebuffRemaining(corruption_debuff) <= target.TickTime(corruption_debuff) + GCD() and { Enemies() < 3 and Talent(sow_the_seeds_talent) or Enemies() < 5 } Spell(corruption)
 #reap_souls,if=(buff.deadwind_harvester.remains+buff.tormented_souls.react*(5+equipped.144364))>=(12*(5+1.5*equipped.144364))
 if BuffRemaining(deadwind_harvester_buff) + BuffStacks(tormented_souls_buff) * { 5 + HasEquippedItem(144364) } >= 12 * { 5 + 1 * HasEquippedItem(144364) } Spell(reap_souls)
 #life_tap,if=talent.empowered_life_tap.enabled&buff.empowered_life_tap.remains<=gcd
 if Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() Spell(life_tap)
 #haunt
 Spell(haunt)
 #agony,cycle_targets=1,if=remains<=duration*0.3&target.time_to_die>=remains
 if target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) Spell(agony)
 #life_tap,if=talent.empowered_life_tap.enabled&buff.empowered_life_tap.remains<duration*0.3|talent.malefic_grasp.enabled&target.time_to_die>15&mana.pct<10
 if Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) < BaseDuration(empowered_life_tap_buff) * 0 or Talent(malefic_grasp_talent) and target.TimeToDie() > 15 and ManaPercent() < 10 Spell(life_tap)
 #siphon_life,if=remains<=duration*0.3&target.time_to_die>=remains
 if target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(siphon_life_debuff) Spell(siphon_life)
 #siphon_life,cycle_targets=1,if=remains<=duration*0.3&target.time_to_die>=remains&debuff.haunt.remains>=action.unstable_affliction_1.tick_time*6&debuff.haunt.remains>=action.unstable_affliction_1.tick_time*4
 if target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(siphon_life_debuff) and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 6 and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 4 Spell(siphon_life)
 #seed_of_corruption,if=talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption>=3|spell_targets.seed_of_corruption>=5|spell_targets.seed_of_corruption>=3&dot.corruption.remains<=cast_time+travel_time
 if Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() >= 5 or Enemies() >= 3 and target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TravelTime(seed_of_corruption) Spell(seed_of_corruption)
 #corruption,if=remains<=duration*0.3&target.time_to_die>=remains
 if target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(corruption_debuff) Spell(corruption)
 #corruption,cycle_targets=1,if=remains<=duration*0.3&target.time_to_die>=remains&debuff.haunt.remains>=action.unstable_affliction_1.tick_time*6&debuff.haunt.remains>=action.unstable_affliction_1.tick_time*4
 if target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(corruption_debuff) and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 6 and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 4 Spell(corruption)
 #unstable_affliction,if=(!talent.sow_the_seeds.enabled|spell_targets.seed_of_corruption<3)&spell_targets.seed_of_corruption<5&((soul_shard>=4&!talent.contagion.enabled)|soul_shard>=5|target.time_to_die<30)
 if { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and { SoulShards() >= 4 and not Talent(contagion_talent) or SoulShards() >= 5 or target.TimeToDie() < 30 } Spell(unstable_affliction)
 #unstable_affliction,cycle_targets=1,if=active_enemies>1&(!talent.sow_the_seeds.enabled|spell_targets.seed_of_corruption<3)&soul_shard>=4&talent.contagion.enabled&cooldown.haunt.remains<15&dot.unstable_affliction_1.remains<cast_time&dot.unstable_affliction_2.remains<cast_time&dot.unstable_affliction_3.remains<cast_time&dot.unstable_affliction_4.remains<cast_time&dot.unstable_affliction_5.remains<cast_time
 if Enemies() > 1 and { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and SoulShards() >= 4 and Talent(contagion_talent) and SpellCooldown(haunt) < 15 and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) Spell(unstable_affliction)
 #unstable_affliction,cycle_targets=1,if=active_enemies>1&(!talent.sow_the_seeds.enabled|spell_targets.seed_of_corruption<3)&(equipped.132381|equipped.132457)&cooldown.haunt.remains<15&dot.unstable_affliction_1.remains<cast_time&dot.unstable_affliction_2.remains<cast_time&dot.unstable_affliction_3.remains<cast_time&dot.unstable_affliction_4.remains<cast_time&dot.unstable_affliction_5.remains<cast_time
 if Enemies() > 1 and { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and { HasEquippedItem(132381) or HasEquippedItem(132457) } and SpellCooldown(haunt) < 15 and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) Spell(unstable_affliction)
 #unstable_affliction,if=(!talent.sow_the_seeds.enabled|spell_targets.seed_of_corruption<3)&spell_targets.seed_of_corruption<5&talent.contagion.enabled&soul_shard>=4&dot.unstable_affliction_1.remains<cast_time&dot.unstable_affliction_2.remains<cast_time&dot.unstable_affliction_3.remains<cast_time&dot.unstable_affliction_4.remains<cast_time&dot.unstable_affliction_5.remains<cast_time
 if { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and Talent(contagion_talent) and SoulShards() >= 4 and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) Spell(unstable_affliction)
 #unstable_affliction,if=(!talent.sow_the_seeds.enabled|spell_targets.seed_of_corruption<3)&spell_targets.seed_of_corruption<5&debuff.haunt.remains>=action.unstable_affliction_1.tick_time*2
 if { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 2 Spell(unstable_affliction)
 #reap_souls,if=!buff.deadwind_harvester.remains&(buff.active_uas.stack>1|(prev_gcd.1.unstable_affliction&buff.tormented_souls.react>1))
 if not BuffPresent(deadwind_harvester_buff) and { target.DebuffStacks(unstable_affliction_debuff) > 1 or PreviousGCDSpell(unstable_affliction) and BuffStacks(tormented_souls_buff) > 1 } Spell(reap_souls)
 #life_tap,if=mana.pct<=10
 if ManaPercent() <= 10 Spell(life_tap)
 #life_tap,if=prev_gcd.1.life_tap&buff.active_uas.stack=0&mana.pct<50
 if PreviousGCDSpell(life_tap) and target.DebuffStacks(unstable_affliction_debuff) == 0 and ManaPercent() < 50 Spell(life_tap)
 #drain_soul,chain=1,interrupt=1
 Spell(drain_soul)
 #life_tap,moving=1,if=mana.pct<80
 if Speed() > 0 and ManaPercent() < 80 Spell(life_tap)
 #agony,moving=1,cycle_targets=1,if=remains<=duration-(3*tick_time)
 if Speed() > 0 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) - 3 * target.TickTime(agony_debuff) Spell(agony)
 #siphon_life,moving=1,cycle_targets=1,if=remains<=duration-(3*tick_time)
 if Speed() > 0 and target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) - 3 * target.TickTime(siphon_life_debuff) Spell(siphon_life)
 #corruption,moving=1,cycle_targets=1,if=remains<=duration-(3*tick_time)
 if Speed() > 0 and target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) - 3 * target.TickTime(corruption_debuff) Spell(corruption)
 #life_tap,moving=0
 if not Speed() > 0 Spell(life_tap)
}

AddFunction AfflictionHauntMainPostConditions
{
}

AddFunction AfflictionHauntShortCdActions
{
 unless not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 5 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } and Spell(reap_souls) or target.DebuffPresent(haunt_debuff) and not BuffPresent(deadwind_harvester_buff) and Spell(reap_souls) or Enemies() > 1 and not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and SoulShards() > 0 and { Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() >= 5 } and Spell(reap_souls) or target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and Spell(agony) or target.TimeToDie() <= GCD() * 2 and SoulShards() < 5 and Spell(drain_soul)
 {
  #service_pet,if=dot.corruption.remains&dot.agony.remains
  if target.DebuffRemaining(corruption_debuff) and target.DebuffRemaining(agony_debuff) Spell(service_felhunter)

  unless target.DebuffRemaining(siphon_life_debuff) <= target.TickTime(siphon_life_debuff) + GCD() and Spell(siphon_life) or target.DebuffRemaining(corruption_debuff) <= target.TickTime(corruption_debuff) + GCD() and { Enemies() < 3 and Talent(sow_the_seeds_talent) or Enemies() < 5 } and Spell(corruption) or BuffRemaining(deadwind_harvester_buff) + BuffStacks(tormented_souls_buff) * { 5 + HasEquippedItem(144364) } >= 12 * { 5 + 1 * HasEquippedItem(144364) } and Spell(reap_souls) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap)
  {
   #phantom_singularity
   Spell(phantom_singularity)
  }
 }
}

AddFunction AfflictionHauntShortCdPostConditions
{
 not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 5 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } and Spell(reap_souls) or target.DebuffPresent(haunt_debuff) and not BuffPresent(deadwind_harvester_buff) and Spell(reap_souls) or Enemies() > 1 and not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and SoulShards() > 0 and { Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() >= 5 } and Spell(reap_souls) or target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and Spell(agony) or target.TimeToDie() <= GCD() * 2 and SoulShards() < 5 and Spell(drain_soul) or target.DebuffRemaining(siphon_life_debuff) <= target.TickTime(siphon_life_debuff) + GCD() and Spell(siphon_life) or target.DebuffRemaining(corruption_debuff) <= target.TickTime(corruption_debuff) + GCD() and { Enemies() < 3 and Talent(sow_the_seeds_talent) or Enemies() < 5 } and Spell(corruption) or BuffRemaining(deadwind_harvester_buff) + BuffStacks(tormented_souls_buff) * { 5 + HasEquippedItem(144364) } >= 12 * { 5 + 1 * HasEquippedItem(144364) } and Spell(reap_souls) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap) or Spell(haunt) or target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and Spell(agony) or { Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) < BaseDuration(empowered_life_tap_buff) * 0 or Talent(malefic_grasp_talent) and target.TimeToDie() > 15 and ManaPercent() < 10 } and Spell(life_tap) or target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(siphon_life_debuff) and Spell(siphon_life) or target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(siphon_life_debuff) and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 6 and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 4 and Spell(siphon_life) or { Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() >= 5 or Enemies() >= 3 and target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TravelTime(seed_of_corruption) } and Spell(seed_of_corruption) or target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(corruption_debuff) and Spell(corruption) or target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(corruption_debuff) and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 6 and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 4 and Spell(corruption) or { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and { SoulShards() >= 4 and not Talent(contagion_talent) or SoulShards() >= 5 or target.TimeToDie() < 30 } and Spell(unstable_affliction) or Enemies() > 1 and { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and SoulShards() >= 4 and Talent(contagion_talent) and SpellCooldown(haunt) < 15 and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) and Spell(unstable_affliction) or Enemies() > 1 and { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and { HasEquippedItem(132381) or HasEquippedItem(132457) } and SpellCooldown(haunt) < 15 and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) and Spell(unstable_affliction) or { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and Talent(contagion_talent) and SoulShards() >= 4 and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) and Spell(unstable_affliction) or { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 2 and Spell(unstable_affliction) or not BuffPresent(deadwind_harvester_buff) and { target.DebuffStacks(unstable_affliction_debuff) > 1 or PreviousGCDSpell(unstable_affliction) and BuffStacks(tormented_souls_buff) > 1 } and Spell(reap_souls) or ManaPercent() <= 10 and Spell(life_tap) or PreviousGCDSpell(life_tap) and target.DebuffStacks(unstable_affliction_debuff) == 0 and ManaPercent() < 50 and Spell(life_tap) or Spell(drain_soul) or Speed() > 0 and ManaPercent() < 80 and Spell(life_tap) or Speed() > 0 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) - 3 * target.TickTime(agony_debuff) and Spell(agony) or Speed() > 0 and target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) - 3 * target.TickTime(siphon_life_debuff) and Spell(siphon_life) or Speed() > 0 and target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) - 3 * target.TickTime(corruption_debuff) and Spell(corruption) or not Speed() > 0 and Spell(life_tap)
}

AddFunction AfflictionHauntCdActions
{
 unless not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 5 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } and Spell(reap_souls) or target.DebuffPresent(haunt_debuff) and not BuffPresent(deadwind_harvester_buff) and Spell(reap_souls) or Enemies() > 1 and not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and SoulShards() > 0 and { Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() >= 5 } and Spell(reap_souls) or target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and Spell(agony) or target.TimeToDie() <= GCD() * 2 and SoulShards() < 5 and Spell(drain_soul) or target.DebuffRemaining(corruption_debuff) and target.DebuffRemaining(agony_debuff) and Spell(service_felhunter)
 {
  #summon_doomguard,if=!talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal<=2&(target.time_to_die>180|target.health.pct<=20|target.time_to_die<30)
  if not Talent(grimoire_of_supremacy_talent) and Enemies() <= 2 and { target.TimeToDie() > 180 or target.HealthPercent() <= 20 or target.TimeToDie() < 30 } Spell(summon_doomguard)
  #summon_infernal,if=!talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal>2
  if not Talent(grimoire_of_supremacy_talent) and Enemies() > 2 Spell(summon_infernal)
  #summon_doomguard,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal=1&equipped.132379&!cooldown.sindorei_spite_icd.remains
  if Talent(grimoire_of_supremacy_talent) and Enemies() == 1 and HasEquippedItem(132379) and not SpellCooldown(sindorei_spite_icd) > 0 Spell(summon_doomguard)
  #summon_infernal,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal>1&equipped.132379&!cooldown.sindorei_spite_icd.remains
  if Talent(grimoire_of_supremacy_talent) and Enemies() > 1 and HasEquippedItem(132379) and not SpellCooldown(sindorei_spite_icd) > 0 Spell(summon_infernal)
  #berserking,if=prev_gcd.1.unstable_affliction|buff.soul_harvest.remains>=10
  if PreviousGCDSpell(unstable_affliction) or BuffRemaining(soul_harvest_buff) >= 10 Spell(berserking)
  #blood_fury
  Spell(blood_fury_sp)
  #soul_harvest,if=buff.soul_harvest.remains<=8&buff.active_uas.stack>=1
  if BuffRemaining(soul_harvest_buff) <= 8 and target.DebuffStacks(unstable_affliction_debuff) >= 1 Spell(soul_harvest)
  #potion,if=!talent.soul_harvest.enabled&(trinket.proc.any.react|trinket.stack_proc.any.react|target.time_to_die<=70|buff.active_uas.stack>2)
  if not Talent(soul_harvest_talent) and { BuffPresent(trinket_proc_any_buff) or BuffPresent(trinket_stack_proc_any_buff) or target.TimeToDie() <= 70 or target.DebuffStacks(unstable_affliction_debuff) > 2 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
  #potion,if=talent.soul_harvest.enabled&buff.soul_harvest.remains&(trinket.proc.any.react|trinket.stack_proc.any.react|target.time_to_die<=70|!cooldown.haunt.remains|buff.active_uas.stack>2)
  if Talent(soul_harvest_talent) and BuffPresent(soul_harvest_buff) and { BuffPresent(trinket_proc_any_buff) or BuffPresent(trinket_stack_proc_any_buff) or target.TimeToDie() <= 70 or not SpellCooldown(haunt) > 0 or target.DebuffStacks(unstable_affliction_debuff) > 2 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 }
}

AddFunction AfflictionHauntCdPostConditions
{
 not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and { BuffStacks(tormented_souls_buff) >= 5 or target.TimeToDie() <= BuffStacks(tormented_souls_buff) * { 5 + 1 * HasEquippedItem(144364) } + BuffRemaining(deadwind_harvester_buff) * { 5 + 1 * HasEquippedItem(144364) } / 12 * { 5 + 1 * HasEquippedItem(144364) } } and Spell(reap_souls) or target.DebuffPresent(haunt_debuff) and not BuffPresent(deadwind_harvester_buff) and Spell(reap_souls) or Enemies() > 1 and not BuffPresent(deadwind_harvester_buff) and TimeInCombat() > 5 and SoulShards() > 0 and { Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() >= 5 } and Spell(reap_souls) or target.DebuffRemaining(agony_debuff) <= target.TickTime(agony_debuff) + GCD() and Spell(agony) or target.TimeToDie() <= GCD() * 2 and SoulShards() < 5 and Spell(drain_soul) or target.DebuffRemaining(corruption_debuff) and target.DebuffRemaining(agony_debuff) and Spell(service_felhunter) or target.DebuffRemaining(siphon_life_debuff) <= target.TickTime(siphon_life_debuff) + GCD() and Spell(siphon_life) or target.DebuffRemaining(corruption_debuff) <= target.TickTime(corruption_debuff) + GCD() and { Enemies() < 3 and Talent(sow_the_seeds_talent) or Enemies() < 5 } and Spell(corruption) or BuffRemaining(deadwind_harvester_buff) + BuffStacks(tormented_souls_buff) * { 5 + HasEquippedItem(144364) } >= 12 * { 5 + 1 * HasEquippedItem(144364) } and Spell(reap_souls) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap) or Spell(phantom_singularity) or Spell(haunt) or target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(agony_debuff) and Spell(agony) or { Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) < BaseDuration(empowered_life_tap_buff) * 0 or Talent(malefic_grasp_talent) and target.TimeToDie() > 15 and ManaPercent() < 10 } and Spell(life_tap) or target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(siphon_life_debuff) and Spell(siphon_life) or target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(siphon_life_debuff) and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 6 and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 4 and Spell(siphon_life) or { Talent(sow_the_seeds_talent) and Enemies() >= 3 or Enemies() >= 5 or Enemies() >= 3 and target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TravelTime(seed_of_corruption) } and Spell(seed_of_corruption) or target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(corruption_debuff) and Spell(corruption) or target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) * 0 and target.TimeToDie() >= target.DebuffRemaining(corruption_debuff) and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 6 and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 4 and Spell(corruption) or { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and { SoulShards() >= 4 and not Talent(contagion_talent) or SoulShards() >= 5 or target.TimeToDie() < 30 } and Spell(unstable_affliction) or Enemies() > 1 and { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and SoulShards() >= 4 and Talent(contagion_talent) and SpellCooldown(haunt) < 15 and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) and Spell(unstable_affliction) or Enemies() > 1 and { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and { HasEquippedItem(132381) or HasEquippedItem(132457) } and SpellCooldown(haunt) < 15 and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) and Spell(unstable_affliction) or { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and Talent(contagion_talent) and SoulShards() >= 4 and target.DebuffStacks(unstable_affliction_debuff) >= 1 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 2 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 3 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 4 < CastTime(unstable_affliction) and target.DebuffStacks(unstable_affliction_debuff) >= 5 < CastTime(unstable_affliction) and Spell(unstable_affliction) or { not Talent(sow_the_seeds_talent) or Enemies() < 3 } and Enemies() < 5 and target.DebuffRemaining(haunt_debuff) >= target.TickTime(unstable_affliction_debuff) * 2 and Spell(unstable_affliction) or not BuffPresent(deadwind_harvester_buff) and { target.DebuffStacks(unstable_affliction_debuff) > 1 or PreviousGCDSpell(unstable_affliction) and BuffStacks(tormented_souls_buff) > 1 } and Spell(reap_souls) or ManaPercent() <= 10 and Spell(life_tap) or PreviousGCDSpell(life_tap) and target.DebuffStacks(unstable_affliction_debuff) == 0 and ManaPercent() < 50 and Spell(life_tap) or Spell(drain_soul) or Speed() > 0 and ManaPercent() < 80 and Spell(life_tap) or Speed() > 0 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) - 3 * target.TickTime(agony_debuff) and Spell(agony) or Speed() > 0 and target.DebuffRemaining(siphon_life_debuff) <= BaseDuration(siphon_life_debuff) - 3 * target.TickTime(siphon_life_debuff) and Spell(siphon_life) or Speed() > 0 and target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) - 3 * target.TickTime(corruption_debuff) and Spell(corruption) or not Speed() > 0 and Spell(life_tap)
}

### actions.default

AddFunction AfflictionDefaultMainActions
{
 #call_action_list,name=mg,if=talent.malefic_grasp.enabled
 if Talent(malefic_grasp_talent) AfflictionMgMainActions()

 unless Talent(malefic_grasp_talent) and AfflictionMgMainPostConditions()
 {
  #call_action_list,name=writhe,if=talent.writhe_in_agony.enabled
  if Talent(writhe_in_agony_talent) AfflictionWritheMainActions()

  unless Talent(writhe_in_agony_talent) and AfflictionWritheMainPostConditions()
  {
   #call_action_list,name=haunt,if=talent.haunt.enabled
   if Talent(haunt_talent) AfflictionHauntMainActions()
  }
 }
}

AddFunction AfflictionDefaultMainPostConditions
{
 Talent(malefic_grasp_talent) and AfflictionMgMainPostConditions() or Talent(writhe_in_agony_talent) and AfflictionWritheMainPostConditions() or Talent(haunt_talent) and AfflictionHauntMainPostConditions()
}

AddFunction AfflictionDefaultShortCdActions
{
 #call_action_list,name=mg,if=talent.malefic_grasp.enabled
 if Talent(malefic_grasp_talent) AfflictionMgShortCdActions()

 unless Talent(malefic_grasp_talent) and AfflictionMgShortCdPostConditions()
 {
  #call_action_list,name=writhe,if=talent.writhe_in_agony.enabled
  if Talent(writhe_in_agony_talent) AfflictionWritheShortCdActions()

  unless Talent(writhe_in_agony_talent) and AfflictionWritheShortCdPostConditions()
  {
   #call_action_list,name=haunt,if=talent.haunt.enabled
   if Talent(haunt_talent) AfflictionHauntShortCdActions()
  }
 }
}

AddFunction AfflictionDefaultShortCdPostConditions
{
 Talent(malefic_grasp_talent) and AfflictionMgShortCdPostConditions() or Talent(writhe_in_agony_talent) and AfflictionWritheShortCdPostConditions() or Talent(haunt_talent) and AfflictionHauntShortCdPostConditions()
}

AddFunction AfflictionDefaultCdActions
{
 #call_action_list,name=mg,if=talent.malefic_grasp.enabled
 if Talent(malefic_grasp_talent) AfflictionMgCdActions()

 unless Talent(malefic_grasp_talent) and AfflictionMgCdPostConditions()
 {
  #call_action_list,name=writhe,if=talent.writhe_in_agony.enabled
  if Talent(writhe_in_agony_talent) AfflictionWritheCdActions()

  unless Talent(writhe_in_agony_talent) and AfflictionWritheCdPostConditions()
  {
   #call_action_list,name=haunt,if=talent.haunt.enabled
   if Talent(haunt_talent) AfflictionHauntCdActions()
  }
 }
}

AddFunction AfflictionDefaultCdPostConditions
{
 Talent(malefic_grasp_talent) and AfflictionMgCdPostConditions() or Talent(writhe_in_agony_talent) and AfflictionWritheCdPostConditions() or Talent(haunt_talent) and AfflictionHauntCdPostConditions()
}

### Affliction icons.

AddCheckBox(opt_warlock_affliction_aoe L(AOE) default specialization=affliction)

AddIcon checkbox=!opt_warlock_affliction_aoe enemies=1 help=shortcd specialization=affliction
{
 if not InCombat() AfflictionPrecombatShortCdActions()
 unless not InCombat() and AfflictionPrecombatShortCdPostConditions()
 {
  AfflictionDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_warlock_affliction_aoe help=shortcd specialization=affliction
{
 if not InCombat() AfflictionPrecombatShortCdActions()
 unless not InCombat() and AfflictionPrecombatShortCdPostConditions()
 {
  AfflictionDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=affliction
{
 if not InCombat() AfflictionPrecombatMainActions()
 unless not InCombat() and AfflictionPrecombatMainPostConditions()
 {
  AfflictionDefaultMainActions()
 }
}

AddIcon checkbox=opt_warlock_affliction_aoe help=aoe specialization=affliction
{
 if not InCombat() AfflictionPrecombatMainActions()
 unless not InCombat() and AfflictionPrecombatMainPostConditions()
 {
  AfflictionDefaultMainActions()
 }
}

AddIcon checkbox=!opt_warlock_affliction_aoe enemies=1 help=cd specialization=affliction
{
 if not InCombat() AfflictionPrecombatCdActions()
 unless not InCombat() and AfflictionPrecombatCdPostConditions()
 {
  AfflictionDefaultCdActions()
 }
}

AddIcon checkbox=opt_warlock_affliction_aoe help=cd specialization=affliction
{
 if not InCombat() AfflictionPrecombatCdActions()
 unless not InCombat() and AfflictionPrecombatCdPostConditions()
 {
  AfflictionDefaultCdActions()
 }
}

### Required symbols
# reap_souls
# deadwind_harvester_buff
# tormented_souls_buff
# 144364
# soul_harvest_buff
# concordance_of_the_legionfall_buff
# trinket_proc_spell_power_buff
# trinket_stacking_proc_spell_power_buff
# agony
# agony_debuff
# soul_harvest_talent
# soul_harvest
# seed_of_corruption
# sow_the_seeds_talent
# unstable_affliction
# unstable_affliction_debuff
# drain_soul
# life_tap
# empowered_life_tap_talent
# empowered_life_tap_buff
# service_felhunter
# corruption_debuff
# summon_doomguard
# grimoire_of_supremacy_talent
# summon_infernal
# 132379
# sindorei_spite_icd
# berserking
# blood_fury_sp
# deaths_embrace_talent
# prolonged_power_potion
# siphon_life
# siphon_life_debuff
# corruption
# phantom_singularity
# contagion_talent
# summon_felhunter
# grimoire_of_sacrifice_talent
# demonic_power_buff
# lord_of_flames
# grimoire_of_sacrifice
# malefic_grasp_talent
# haunt_debuff
# haunt
# 132381
# 132457
# writhe_in_agony_talent
# haunt_talent
]]
    OvaleScripts:RegisterScript("WARLOCK", "affliction", name, desc, code, "script")
end
do
    local name = "sc_warlock_demonology_t19"
    local desc = "[7.0] Simulationcraft: Warlock_Demonology_T19"
    local code = [[
# Based on SimulationCraft profile "Warlock_Demonology_T19P".
#	class=warlock
#	spec=demonology
#	talents=3201022
#	pet=felguard

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)


AddFunction no_de2
{
 3min() and 0 > 0 or 3min() and NotDeDemons(wild_imp) > 0 or 3min() and NotDeDemons(dreadstalker) > 0 or 0 > 0 and NotDeDemons(dreadstalker) > 0 or 0 > 0 and NotDeDemons(wild_imp) > 0 or NotDeDemons(dreadstalker) > 0 and NotDeDemons(wild_imp) > 0 or PreviousGCDSpell(hand_of_guldan) and no_de1()
}

AddFunction no_de1
{
 NotDeDemons(dreadstalker) > 0 or NotDeDemons(darkglare) > 0 or NotDeDemons(doomguard) > 0 or NotDeDemons(infernal) > 0 or 0 > 0
}

AddFunction _3min
{
 NotDeDemons(doomguard) > 0 or NotDeDemons(infernal) > 0
}

AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=demonology)

AddFunction DemonologyUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.precombat

AddFunction DemonologyPrecombatMainActions
{
 #demonic_empowerment
 Spell(demonic_empowerment)
 #demonbolt
 Spell(demonbolt)
 #shadow_bolt
 Spell(shadow_bolt)
}

AddFunction DemonologyPrecombatMainPostConditions
{
}

AddFunction DemonologyPrecombatShortCdActions
{
 #flask
 #food
 #augmentation
 #summon_pet,if=!talent.grimoire_of_supremacy.enabled&(!talent.grimoire_of_sacrifice.enabled|buff.demonic_power.down)
 if not Talent(grimoire_of_supremacy_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(demonic_power_buff) } and not pet.Present() Spell(summon_felguard)
}

AddFunction DemonologyPrecombatShortCdPostConditions
{
 Spell(demonic_empowerment) or Spell(demonbolt) or Spell(shadow_bolt)
}

AddFunction DemonologyPrecombatCdActions
{
 unless not Talent(grimoire_of_supremacy_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(demonic_power_buff) } and not pet.Present() and Spell(summon_felguard)
 {
  #summon_infernal,if=talent.grimoire_of_supremacy.enabled&artifact.lord_of_flames.rank>0
  if Talent(grimoire_of_supremacy_talent) and ArtifactTraitRank(lord_of_flames) > 0 Spell(summon_infernal)
  #summon_infernal,if=talent.grimoire_of_supremacy.enabled&active_enemies>1
  if Talent(grimoire_of_supremacy_talent) and Enemies() > 1 Spell(summon_infernal)
  #summon_doomguard,if=talent.grimoire_of_supremacy.enabled&active_enemies=1&artifact.lord_of_flames.rank=0
  if Talent(grimoire_of_supremacy_talent) and Enemies() == 1 and ArtifactTraitRank(lord_of_flames) == 0 Spell(summon_doomguard)
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 }
}

AddFunction DemonologyPrecombatCdPostConditions
{
 not Talent(grimoire_of_supremacy_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(demonic_power_buff) } and not pet.Present() and Spell(summon_felguard) or Spell(demonic_empowerment) or Spell(demonbolt) or Spell(shadow_bolt)
}

### actions.default

AddFunction DemonologyDefaultMainActions
{
 #implosion,if=wild_imp_remaining_duration<=action.shadow_bolt.execute_time&(buff.demonic_synergy.remains|talent.soul_conduit.enabled|(!talent.soul_conduit.enabled&spell_targets.implosion>1)|wild_imp_count<=4)
 if DemonDuration(wild_imp) <= ExecuteTime(shadow_bolt) and { BuffPresent(demonic_synergy_buff) or Talent(soul_conduit_talent) or not Talent(soul_conduit_talent) and Enemies() > 1 or Demons(wild_imp) <= 4 } Spell(implosion)
 #variable,name=3min,value=doomguard_no_de>0|infernal_no_de>0
 #variable,name=no_de1,value=dreadstalker_no_de>0|darkglare_no_de>0|doomguard_no_de>0|infernal_no_de>0|service_no_de>0
 #variable,name=no_de2,value=(variable.3min&service_no_de>0)|(variable.3min&wild_imp_no_de>0)|(variable.3min&dreadstalker_no_de>0)|(service_no_de>0&dreadstalker_no_de>0)|(service_no_de>0&wild_imp_no_de>0)|(dreadstalker_no_de>0&wild_imp_no_de>0)|(prev_gcd.1.hand_of_guldan&variable.no_de1)
 #implosion,if=prev_gcd.1.hand_of_guldan&((wild_imp_remaining_duration<=3&buff.demonic_synergy.remains)|(wild_imp_remaining_duration<=4&spell_targets.implosion>2))
 if PreviousGCDSpell(hand_of_guldan) and { DemonDuration(wild_imp) <= 3 and BuffPresent(demonic_synergy_buff) or DemonDuration(wild_imp) <= 4 and Enemies() > 2 } Spell(implosion)
 #shadowflame,if=(debuff.shadowflame.stack>0&remains<action.shadow_bolt.cast_time+travel_time)&spell_targets.demonwrath<5
 if target.DebuffStacks(shadowflame_debuff) > 0 and target.DebuffRemaining(shadowflame_debuff) < CastTime(shadow_bolt) + TravelTime(shadowflame) and Enemies() < 5 Spell(shadowflame)
 #call_dreadstalkers,if=((!talent.summon_darkglare.enabled|talent.power_trip.enabled)&(spell_targets.implosion<3|!talent.implosion.enabled))&!(soul_shard=5&buff.demonic_calling.remains)
 if { not Talent(summon_darkglare_talent) or Talent(power_trip_talent) } and { Enemies() < 3 or not Talent(implosion_talent) } and not { SoulShards() == 5 and BuffPresent(demonic_calling_buff) } Spell(call_dreadstalkers)
 #doom,cycle_targets=1,if=(!talent.hand_of_doom.enabled&target.time_to_die>duration&(!ticking|remains<duration*0.3))&!(variable.no_de1|prev_gcd.1.hand_of_guldan)
 if not Talent(hand_of_doom_talent) and target.TimeToDie() > BaseDuration(doom_debuff) and { not target.DebuffPresent(doom_debuff) or target.DebuffRemaining(doom_debuff) < BaseDuration(doom_debuff) * 0 } and not { no_de1() or PreviousGCDSpell(hand_of_guldan) } Spell(doom)
 #shadowflame,if=(charges=2&soul_shard<5)&spell_targets.demonwrath<5&!variable.no_de1
 if Charges(shadowflame) == 2 and SoulShards() < 5 and Enemies() < 5 and not no_de1() Spell(shadowflame)
 #shadow_bolt,if=buff.shadowy_inspiration.remains&soul_shard<5&!prev_gcd.1.doom&!variable.no_de2
 if BuffPresent(shadowy_inspiration_buff) and SoulShards() < 5 and not PreviousGCDSpell(doom) and not no_de2() Spell(shadow_bolt)
 #summon_darkglare,if=prev_gcd.1.hand_of_guldan|prev_gcd.1.call_dreadstalkers|talent.power_trip.enabled
 if PreviousGCDSpell(hand_of_guldan) or PreviousGCDSpell(call_dreadstalkers) or Talent(power_trip_talent) Spell(summon_darkglare)
 #summon_darkglare,if=cooldown.call_dreadstalkers.remains>5&soul_shard<3
 if SpellCooldown(call_dreadstalkers) > 5 and SoulShards() < 3 Spell(summon_darkglare)
 #summon_darkglare,if=cooldown.call_dreadstalkers.remains<=action.summon_darkglare.cast_time&(soul_shard>=3|soul_shard>=1&buff.demonic_calling.react)
 if SpellCooldown(call_dreadstalkers) <= CastTime(summon_darkglare) and { SoulShards() >= 3 or SoulShards() >= 1 and BuffPresent(demonic_calling_buff) } Spell(summon_darkglare)
 #call_dreadstalkers,if=talent.summon_darkglare.enabled&(spell_targets.implosion<3|!talent.implosion.enabled)&(cooldown.summon_darkglare.remains>2|prev_gcd.1.summon_darkglare|cooldown.summon_darkglare.remains<=action.call_dreadstalkers.cast_time&soul_shard>=3|cooldown.summon_darkglare.remains<=action.call_dreadstalkers.cast_time&soul_shard>=1&buff.demonic_calling.react)
 if Talent(summon_darkglare_talent) and { Enemies() < 3 or not Talent(implosion_talent) } and { SpellCooldown(summon_darkglare) > 2 or PreviousGCDSpell(summon_darkglare) or SpellCooldown(summon_darkglare) <= CastTime(call_dreadstalkers) and SoulShards() >= 3 or SpellCooldown(summon_darkglare) <= CastTime(call_dreadstalkers) and SoulShards() >= 1 and BuffPresent(demonic_calling_buff) } Spell(call_dreadstalkers)
 #hand_of_guldan,if=soul_shard>=4&(((!(variable.no_de1|prev_gcd.1.hand_of_guldan)&(pet_count>=13&!talent.shadowy_inspiration.enabled|pet_count>=6&talent.shadowy_inspiration.enabled))|!variable.no_de2|soul_shard=5)&talent.power_trip.enabled)
 if SoulShards() >= 4 and { not { no_de1() or PreviousGCDSpell(hand_of_guldan) } and { Demons() >= 13 and not Talent(shadowy_inspiration_talent) or Demons() >= 6 and Talent(shadowy_inspiration_talent) } or not no_de2() or SoulShards() == 5 } and Talent(power_trip_talent) Spell(hand_of_guldan)
 #hand_of_guldan,if=(soul_shard>=3&prev_gcd.1.call_dreadstalkers&!artifact.thalkiels_ascendance.rank)|soul_shard>=5|(soul_shard>=4&cooldown.summon_darkglare.remains>2)
 if SoulShards() >= 3 and PreviousGCDSpell(call_dreadstalkers) and not ArtifactTraitRank(thalkiels_ascendance) or SoulShards() >= 5 or SoulShards() >= 4 and SpellCooldown(summon_darkglare) > 2 Spell(hand_of_guldan)
 #demonic_empowerment,if=(((talent.power_trip.enabled&(!talent.implosion.enabled|spell_targets.demonwrath<=1))|!talent.implosion.enabled|(talent.implosion.enabled&!talent.soul_conduit.enabled&spell_targets.demonwrath<=3))&(wild_imp_no_de>3|prev_gcd.1.hand_of_guldan))|(prev_gcd.1.hand_of_guldan&wild_imp_no_de=0&wild_imp_remaining_duration<=0)|(prev_gcd.1.implosion&wild_imp_no_de>0)
 if { Talent(power_trip_talent) and { not Talent(implosion_talent) or Enemies() <= 1 } or not Talent(implosion_talent) or Talent(implosion_talent) and not Talent(soul_conduit_talent) and Enemies() <= 3 } and { NotDeDemons(wild_imp) > 3 or PreviousGCDSpell(hand_of_guldan) } or PreviousGCDSpell(hand_of_guldan) and NotDeDemons(wild_imp) == 0 and DemonDuration(wild_imp) <= 0 or PreviousGCDSpell(implosion) and NotDeDemons(wild_imp) > 0 Spell(demonic_empowerment)
 #demonic_empowerment,if=variable.no_de1|prev_gcd.1.hand_of_guldan
 if no_de1() or PreviousGCDSpell(hand_of_guldan) Spell(demonic_empowerment)
 #shadowflame,if=charges=2&spell_targets.demonwrath<5
 if Charges(shadowflame) == 2 and Enemies() < 5 Spell(shadowflame)
 #life_tap,if=mana.pct<=15|(mana.pct<=65&((cooldown.call_dreadstalkers.remains<=0.75&soul_shard>=2)|((cooldown.call_dreadstalkers.remains<gcd*2)&(cooldown.summon_doomguard.remains<=0.75|cooldown.service_pet.remains<=0.75)&soul_shard>=3)))
 if ManaPercent() <= 15 or ManaPercent() <= 65 and { SpellCooldown(call_dreadstalkers) <= 0 and SoulShards() >= 2 or SpellCooldown(call_dreadstalkers) < GCD() * 2 and { SpellCooldown(summon_doomguard) <= 0 or SpellCooldown(service_pet) <= 0 } and SoulShards() >= 3 } Spell(life_tap)
 #demonwrath,chain=1,interrupt=1,if=spell_targets.demonwrath>=3
 if Enemies() >= 3 Spell(demonwrath)
 #demonwrath,moving=1,chain=1,interrupt=1
 if Speed() > 0 Spell(demonwrath)
 #demonbolt
 Spell(demonbolt)
 #shadow_bolt,if=buff.shadowy_inspiration.remains
 if BuffPresent(shadowy_inspiration_buff) Spell(shadow_bolt)
 #demonic_empowerment,if=artifact.thalkiels_ascendance.rank&talent.power_trip.enabled&!talent.demonbolt.enabled&talent.shadowy_inspiration.enabled
 if ArtifactTraitRank(thalkiels_ascendance) and Talent(power_trip_talent) and not Talent(demonbolt_talent) and Talent(shadowy_inspiration_talent) Spell(demonic_empowerment)
 #shadow_bolt
 Spell(shadow_bolt)
 #life_tap
 Spell(life_tap)
}

AddFunction DemonologyDefaultMainPostConditions
{
}

AddFunction DemonologyDefaultShortCdActions
{
 unless DemonDuration(wild_imp) <= ExecuteTime(shadow_bolt) and { BuffPresent(demonic_synergy_buff) or Talent(soul_conduit_talent) or not Talent(soul_conduit_talent) and Enemies() > 1 or Demons(wild_imp) <= 4 } and Spell(implosion) or PreviousGCDSpell(hand_of_guldan) and { DemonDuration(wild_imp) <= 3 and BuffPresent(demonic_synergy_buff) or DemonDuration(wild_imp) <= 4 and Enemies() > 2 } and Spell(implosion) or target.DebuffStacks(shadowflame_debuff) > 0 and target.DebuffRemaining(shadowflame_debuff) < CastTime(shadow_bolt) + TravelTime(shadowflame) and Enemies() < 5 and Spell(shadowflame) or { not Talent(summon_darkglare_talent) or Talent(power_trip_talent) } and { Enemies() < 3 or not Talent(implosion_talent) } and not { SoulShards() == 5 and BuffPresent(demonic_calling_buff) } and Spell(call_dreadstalkers) or not Talent(hand_of_doom_talent) and target.TimeToDie() > BaseDuration(doom_debuff) and { not target.DebuffPresent(doom_debuff) or target.DebuffRemaining(doom_debuff) < BaseDuration(doom_debuff) * 0 } and not { no_de1() or PreviousGCDSpell(hand_of_guldan) } and Spell(doom) or Charges(shadowflame) == 2 and SoulShards() < 5 and Enemies() < 5 and not no_de1() and Spell(shadowflame)
 {
  #service_pet
  Spell(service_felguard)

  unless BuffPresent(shadowy_inspiration_buff) and SoulShards() < 5 and not PreviousGCDSpell(doom) and not no_de2() and Spell(shadow_bolt) or { PreviousGCDSpell(hand_of_guldan) or PreviousGCDSpell(call_dreadstalkers) or Talent(power_trip_talent) } and Spell(summon_darkglare) or SpellCooldown(call_dreadstalkers) > 5 and SoulShards() < 3 and Spell(summon_darkglare) or SpellCooldown(call_dreadstalkers) <= CastTime(summon_darkglare) and { SoulShards() >= 3 or SoulShards() >= 1 and BuffPresent(demonic_calling_buff) } and Spell(summon_darkglare) or Talent(summon_darkglare_talent) and { Enemies() < 3 or not Talent(implosion_talent) } and { SpellCooldown(summon_darkglare) > 2 or PreviousGCDSpell(summon_darkglare) or SpellCooldown(summon_darkglare) <= CastTime(call_dreadstalkers) and SoulShards() >= 3 or SpellCooldown(summon_darkglare) <= CastTime(call_dreadstalkers) and SoulShards() >= 1 and BuffPresent(demonic_calling_buff) } and Spell(call_dreadstalkers) or SoulShards() >= 4 and { not { no_de1() or PreviousGCDSpell(hand_of_guldan) } and { Demons() >= 13 and not Talent(shadowy_inspiration_talent) or Demons() >= 6 and Talent(shadowy_inspiration_talent) } or not no_de2() or SoulShards() == 5 } and Talent(power_trip_talent) and Spell(hand_of_guldan) or { SoulShards() >= 3 and PreviousGCDSpell(call_dreadstalkers) and not ArtifactTraitRank(thalkiels_ascendance) or SoulShards() >= 5 or SoulShards() >= 4 and SpellCooldown(summon_darkglare) > 2 } and Spell(hand_of_guldan) or { { Talent(power_trip_talent) and { not Talent(implosion_talent) or Enemies() <= 1 } or not Talent(implosion_talent) or Talent(implosion_talent) and not Talent(soul_conduit_talent) and Enemies() <= 3 } and { NotDeDemons(wild_imp) > 3 or PreviousGCDSpell(hand_of_guldan) } or PreviousGCDSpell(hand_of_guldan) and NotDeDemons(wild_imp) == 0 and DemonDuration(wild_imp) <= 0 or PreviousGCDSpell(implosion) and NotDeDemons(wild_imp) > 0 } and Spell(demonic_empowerment) or { no_de1() or PreviousGCDSpell(hand_of_guldan) } and Spell(demonic_empowerment) or Charges(shadowflame) == 2 and Enemies() < 5 and Spell(shadowflame)
  {
   #thalkiels_consumption,if=(dreadstalker_remaining_duration>execute_time|talent.implosion.enabled&spell_targets.implosion>=3)&wild_imp_count>3&wild_imp_remaining_duration>execute_time
   if { DemonDuration(dreadstalker) > ExecuteTime(thalkiels_consumption) or Talent(implosion_talent) and Enemies() >= 3 } and Demons(wild_imp) > 3 and DemonDuration(wild_imp) > ExecuteTime(thalkiels_consumption) Spell(thalkiels_consumption)
  }
 }
}

AddFunction DemonologyDefaultShortCdPostConditions
{
 DemonDuration(wild_imp) <= ExecuteTime(shadow_bolt) and { BuffPresent(demonic_synergy_buff) or Talent(soul_conduit_talent) or not Talent(soul_conduit_talent) and Enemies() > 1 or Demons(wild_imp) <= 4 } and Spell(implosion) or PreviousGCDSpell(hand_of_guldan) and { DemonDuration(wild_imp) <= 3 and BuffPresent(demonic_synergy_buff) or DemonDuration(wild_imp) <= 4 and Enemies() > 2 } and Spell(implosion) or target.DebuffStacks(shadowflame_debuff) > 0 and target.DebuffRemaining(shadowflame_debuff) < CastTime(shadow_bolt) + TravelTime(shadowflame) and Enemies() < 5 and Spell(shadowflame) or { not Talent(summon_darkglare_talent) or Talent(power_trip_talent) } and { Enemies() < 3 or not Talent(implosion_talent) } and not { SoulShards() == 5 and BuffPresent(demonic_calling_buff) } and Spell(call_dreadstalkers) or not Talent(hand_of_doom_talent) and target.TimeToDie() > BaseDuration(doom_debuff) and { not target.DebuffPresent(doom_debuff) or target.DebuffRemaining(doom_debuff) < BaseDuration(doom_debuff) * 0 } and not { no_de1() or PreviousGCDSpell(hand_of_guldan) } and Spell(doom) or Charges(shadowflame) == 2 and SoulShards() < 5 and Enemies() < 5 and not no_de1() and Spell(shadowflame) or BuffPresent(shadowy_inspiration_buff) and SoulShards() < 5 and not PreviousGCDSpell(doom) and not no_de2() and Spell(shadow_bolt) or { PreviousGCDSpell(hand_of_guldan) or PreviousGCDSpell(call_dreadstalkers) or Talent(power_trip_talent) } and Spell(summon_darkglare) or SpellCooldown(call_dreadstalkers) > 5 and SoulShards() < 3 and Spell(summon_darkglare) or SpellCooldown(call_dreadstalkers) <= CastTime(summon_darkglare) and { SoulShards() >= 3 or SoulShards() >= 1 and BuffPresent(demonic_calling_buff) } and Spell(summon_darkglare) or Talent(summon_darkglare_talent) and { Enemies() < 3 or not Talent(implosion_talent) } and { SpellCooldown(summon_darkglare) > 2 or PreviousGCDSpell(summon_darkglare) or SpellCooldown(summon_darkglare) <= CastTime(call_dreadstalkers) and SoulShards() >= 3 or SpellCooldown(summon_darkglare) <= CastTime(call_dreadstalkers) and SoulShards() >= 1 and BuffPresent(demonic_calling_buff) } and Spell(call_dreadstalkers) or SoulShards() >= 4 and { not { no_de1() or PreviousGCDSpell(hand_of_guldan) } and { Demons() >= 13 and not Talent(shadowy_inspiration_talent) or Demons() >= 6 and Talent(shadowy_inspiration_talent) } or not no_de2() or SoulShards() == 5 } and Talent(power_trip_talent) and Spell(hand_of_guldan) or { SoulShards() >= 3 and PreviousGCDSpell(call_dreadstalkers) and not ArtifactTraitRank(thalkiels_ascendance) or SoulShards() >= 5 or SoulShards() >= 4 and SpellCooldown(summon_darkglare) > 2 } and Spell(hand_of_guldan) or { { Talent(power_trip_talent) and { not Talent(implosion_talent) or Enemies() <= 1 } or not Talent(implosion_talent) or Talent(implosion_talent) and not Talent(soul_conduit_talent) and Enemies() <= 3 } and { NotDeDemons(wild_imp) > 3 or PreviousGCDSpell(hand_of_guldan) } or PreviousGCDSpell(hand_of_guldan) and NotDeDemons(wild_imp) == 0 and DemonDuration(wild_imp) <= 0 or PreviousGCDSpell(implosion) and NotDeDemons(wild_imp) > 0 } and Spell(demonic_empowerment) or { no_de1() or PreviousGCDSpell(hand_of_guldan) } and Spell(demonic_empowerment) or Charges(shadowflame) == 2 and Enemies() < 5 and Spell(shadowflame) or { ManaPercent() <= 15 or ManaPercent() <= 65 and { SpellCooldown(call_dreadstalkers) <= 0 and SoulShards() >= 2 or SpellCooldown(call_dreadstalkers) < GCD() * 2 and { SpellCooldown(summon_doomguard) <= 0 or SpellCooldown(service_pet) <= 0 } and SoulShards() >= 3 } } and Spell(life_tap) or Enemies() >= 3 and Spell(demonwrath) or Speed() > 0 and Spell(demonwrath) or Spell(demonbolt) or BuffPresent(shadowy_inspiration_buff) and Spell(shadow_bolt) or ArtifactTraitRank(thalkiels_ascendance) and Talent(power_trip_talent) and not Talent(demonbolt_talent) and Talent(shadowy_inspiration_talent) and Spell(demonic_empowerment) or Spell(shadow_bolt) or Spell(life_tap)
}

AddFunction DemonologyDefaultCdActions
{
 unless DemonDuration(wild_imp) <= ExecuteTime(shadow_bolt) and { BuffPresent(demonic_synergy_buff) or Talent(soul_conduit_talent) or not Talent(soul_conduit_talent) and Enemies() > 1 or Demons(wild_imp) <= 4 } and Spell(implosion) or PreviousGCDSpell(hand_of_guldan) and { DemonDuration(wild_imp) <= 3 and BuffPresent(demonic_synergy_buff) or DemonDuration(wild_imp) <= 4 and Enemies() > 2 } and Spell(implosion) or target.DebuffStacks(shadowflame_debuff) > 0 and target.DebuffRemaining(shadowflame_debuff) < CastTime(shadow_bolt) + TravelTime(shadowflame) and Enemies() < 5 and Spell(shadowflame)
 {
  #summon_infernal,if=(!talent.grimoire_of_supremacy.enabled&spell_targets.infernal_awakening>2)&equipped.132369
  if not Talent(grimoire_of_supremacy_talent) and Enemies() > 2 and HasEquippedItem(132369) Spell(summon_infernal)
  #summon_doomguard,if=!talent.grimoire_of_supremacy.enabled&spell_targets.infernal_awakening<=2&equipped.132369
  if not Talent(grimoire_of_supremacy_talent) and Enemies() <= 2 and HasEquippedItem(132369) Spell(summon_doomguard)

  unless { not Talent(summon_darkglare_talent) or Talent(power_trip_talent) } and { Enemies() < 3 or not Talent(implosion_talent) } and not { SoulShards() == 5 and BuffPresent(demonic_calling_buff) } and Spell(call_dreadstalkers) or not Talent(hand_of_doom_talent) and target.TimeToDie() > BaseDuration(doom_debuff) and { not target.DebuffPresent(doom_debuff) or target.DebuffRemaining(doom_debuff) < BaseDuration(doom_debuff) * 0 } and not { no_de1() or PreviousGCDSpell(hand_of_guldan) } and Spell(doom) or Charges(shadowflame) == 2 and SoulShards() < 5 and Enemies() < 5 and not no_de1() and Spell(shadowflame) or Spell(service_felguard)
  {
   #summon_doomguard,if=!talent.grimoire_of_supremacy.enabled&spell_targets.infernal_awakening<=2&(target.time_to_die>180|target.health.pct<=20|target.time_to_die<30)
   if not Talent(grimoire_of_supremacy_talent) and Enemies() <= 2 and { target.TimeToDie() > 180 or target.HealthPercent() <= 20 or target.TimeToDie() < 30 } Spell(summon_doomguard)
   #summon_infernal,if=!talent.grimoire_of_supremacy.enabled&spell_targets.infernal_awakening>2
   if not Talent(grimoire_of_supremacy_talent) and Enemies() > 2 Spell(summon_infernal)
   #summon_doomguard,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal=1&equipped.132379&!cooldown.sindorei_spite_icd.remains
   if Talent(grimoire_of_supremacy_talent) and Enemies() == 1 and HasEquippedItem(132379) and not SpellCooldown(sindorei_spite_icd) > 0 Spell(summon_doomguard)
   #summon_infernal,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal>1&equipped.132379&!cooldown.sindorei_spite_icd.remains
   if Talent(grimoire_of_supremacy_talent) and Enemies() > 1 and HasEquippedItem(132379) and not SpellCooldown(sindorei_spite_icd) > 0 Spell(summon_infernal)

   unless BuffPresent(shadowy_inspiration_buff) and SoulShards() < 5 and not PreviousGCDSpell(doom) and not no_de2() and Spell(shadow_bolt) or { PreviousGCDSpell(hand_of_guldan) or PreviousGCDSpell(call_dreadstalkers) or Talent(power_trip_talent) } and Spell(summon_darkglare) or SpellCooldown(call_dreadstalkers) > 5 and SoulShards() < 3 and Spell(summon_darkglare) or SpellCooldown(call_dreadstalkers) <= CastTime(summon_darkglare) and { SoulShards() >= 3 or SoulShards() >= 1 and BuffPresent(demonic_calling_buff) } and Spell(summon_darkglare) or Talent(summon_darkglare_talent) and { Enemies() < 3 or not Talent(implosion_talent) } and { SpellCooldown(summon_darkglare) > 2 or PreviousGCDSpell(summon_darkglare) or SpellCooldown(summon_darkglare) <= CastTime(call_dreadstalkers) and SoulShards() >= 3 or SpellCooldown(summon_darkglare) <= CastTime(call_dreadstalkers) and SoulShards() >= 1 and BuffPresent(demonic_calling_buff) } and Spell(call_dreadstalkers) or SoulShards() >= 4 and { not { no_de1() or PreviousGCDSpell(hand_of_guldan) } and { Demons() >= 13 and not Talent(shadowy_inspiration_talent) or Demons() >= 6 and Talent(shadowy_inspiration_talent) } or not no_de2() or SoulShards() == 5 } and Talent(power_trip_talent) and Spell(hand_of_guldan) or { SoulShards() >= 3 and PreviousGCDSpell(call_dreadstalkers) and not ArtifactTraitRank(thalkiels_ascendance) or SoulShards() >= 5 or SoulShards() >= 4 and SpellCooldown(summon_darkglare) > 2 } and Spell(hand_of_guldan) or { { Talent(power_trip_talent) and { not Talent(implosion_talent) or Enemies() <= 1 } or not Talent(implosion_talent) or Talent(implosion_talent) and not Talent(soul_conduit_talent) and Enemies() <= 3 } and { NotDeDemons(wild_imp) > 3 or PreviousGCDSpell(hand_of_guldan) } or PreviousGCDSpell(hand_of_guldan) and NotDeDemons(wild_imp) == 0 and DemonDuration(wild_imp) <= 0 or PreviousGCDSpell(implosion) and NotDeDemons(wild_imp) > 0 } and Spell(demonic_empowerment) or { no_de1() or PreviousGCDSpell(hand_of_guldan) } and Spell(demonic_empowerment)
   {
    #use_items
    DemonologyUseItemActions()
    #berserking
    Spell(berserking)
    #blood_fury
    Spell(blood_fury_sp)
    #soul_harvest,if=!buff.soul_harvest.remains
    if not BuffPresent(soul_harvest_buff) Spell(soul_harvest)
    #potion,name=prolonged_power,if=buff.soul_harvest.remains|target.time_to_die<=70|trinket.proc.any.react
    if { BuffPresent(soul_harvest_buff) or target.TimeToDie() <= 70 or BuffPresent(trinket_proc_any_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
   }
  }
 }
}

AddFunction DemonologyDefaultCdPostConditions
{
 DemonDuration(wild_imp) <= ExecuteTime(shadow_bolt) and { BuffPresent(demonic_synergy_buff) or Talent(soul_conduit_talent) or not Talent(soul_conduit_talent) and Enemies() > 1 or Demons(wild_imp) <= 4 } and Spell(implosion) or PreviousGCDSpell(hand_of_guldan) and { DemonDuration(wild_imp) <= 3 and BuffPresent(demonic_synergy_buff) or DemonDuration(wild_imp) <= 4 and Enemies() > 2 } and Spell(implosion) or target.DebuffStacks(shadowflame_debuff) > 0 and target.DebuffRemaining(shadowflame_debuff) < CastTime(shadow_bolt) + TravelTime(shadowflame) and Enemies() < 5 and Spell(shadowflame) or { not Talent(summon_darkglare_talent) or Talent(power_trip_talent) } and { Enemies() < 3 or not Talent(implosion_talent) } and not { SoulShards() == 5 and BuffPresent(demonic_calling_buff) } and Spell(call_dreadstalkers) or not Talent(hand_of_doom_talent) and target.TimeToDie() > BaseDuration(doom_debuff) and { not target.DebuffPresent(doom_debuff) or target.DebuffRemaining(doom_debuff) < BaseDuration(doom_debuff) * 0 } and not { no_de1() or PreviousGCDSpell(hand_of_guldan) } and Spell(doom) or Charges(shadowflame) == 2 and SoulShards() < 5 and Enemies() < 5 and not no_de1() and Spell(shadowflame) or Spell(service_felguard) or BuffPresent(shadowy_inspiration_buff) and SoulShards() < 5 and not PreviousGCDSpell(doom) and not no_de2() and Spell(shadow_bolt) or { PreviousGCDSpell(hand_of_guldan) or PreviousGCDSpell(call_dreadstalkers) or Talent(power_trip_talent) } and Spell(summon_darkglare) or SpellCooldown(call_dreadstalkers) > 5 and SoulShards() < 3 and Spell(summon_darkglare) or SpellCooldown(call_dreadstalkers) <= CastTime(summon_darkglare) and { SoulShards() >= 3 or SoulShards() >= 1 and BuffPresent(demonic_calling_buff) } and Spell(summon_darkglare) or Talent(summon_darkglare_talent) and { Enemies() < 3 or not Talent(implosion_talent) } and { SpellCooldown(summon_darkglare) > 2 or PreviousGCDSpell(summon_darkglare) or SpellCooldown(summon_darkglare) <= CastTime(call_dreadstalkers) and SoulShards() >= 3 or SpellCooldown(summon_darkglare) <= CastTime(call_dreadstalkers) and SoulShards() >= 1 and BuffPresent(demonic_calling_buff) } and Spell(call_dreadstalkers) or SoulShards() >= 4 and { not { no_de1() or PreviousGCDSpell(hand_of_guldan) } and { Demons() >= 13 and not Talent(shadowy_inspiration_talent) or Demons() >= 6 and Talent(shadowy_inspiration_talent) } or not no_de2() or SoulShards() == 5 } and Talent(power_trip_talent) and Spell(hand_of_guldan) or { SoulShards() >= 3 and PreviousGCDSpell(call_dreadstalkers) and not ArtifactTraitRank(thalkiels_ascendance) or SoulShards() >= 5 or SoulShards() >= 4 and SpellCooldown(summon_darkglare) > 2 } and Spell(hand_of_guldan) or { { Talent(power_trip_talent) and { not Talent(implosion_talent) or Enemies() <= 1 } or not Talent(implosion_talent) or Talent(implosion_talent) and not Talent(soul_conduit_talent) and Enemies() <= 3 } and { NotDeDemons(wild_imp) > 3 or PreviousGCDSpell(hand_of_guldan) } or PreviousGCDSpell(hand_of_guldan) and NotDeDemons(wild_imp) == 0 and DemonDuration(wild_imp) <= 0 or PreviousGCDSpell(implosion) and NotDeDemons(wild_imp) > 0 } and Spell(demonic_empowerment) or { no_de1() or PreviousGCDSpell(hand_of_guldan) } and Spell(demonic_empowerment) or Charges(shadowflame) == 2 and Enemies() < 5 and Spell(shadowflame) or { DemonDuration(dreadstalker) > ExecuteTime(thalkiels_consumption) or Talent(implosion_talent) and Enemies() >= 3 } and Demons(wild_imp) > 3 and DemonDuration(wild_imp) > ExecuteTime(thalkiels_consumption) and Spell(thalkiels_consumption) or { ManaPercent() <= 15 or ManaPercent() <= 65 and { SpellCooldown(call_dreadstalkers) <= 0 and SoulShards() >= 2 or SpellCooldown(call_dreadstalkers) < GCD() * 2 and { SpellCooldown(summon_doomguard) <= 0 or SpellCooldown(service_pet) <= 0 } and SoulShards() >= 3 } } and Spell(life_tap) or Enemies() >= 3 and Spell(demonwrath) or Speed() > 0 and Spell(demonwrath) or Spell(demonbolt) or BuffPresent(shadowy_inspiration_buff) and Spell(shadow_bolt) or ArtifactTraitRank(thalkiels_ascendance) and Talent(power_trip_talent) and not Talent(demonbolt_talent) and Talent(shadowy_inspiration_talent) and Spell(demonic_empowerment) or Spell(shadow_bolt) or Spell(life_tap)
}

### Demonology icons.

AddCheckBox(opt_warlock_demonology_aoe L(AOE) default specialization=demonology)

AddIcon checkbox=!opt_warlock_demonology_aoe enemies=1 help=shortcd specialization=demonology
{
 if not InCombat() DemonologyPrecombatShortCdActions()
 unless not InCombat() and DemonologyPrecombatShortCdPostConditions()
 {
  DemonologyDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_warlock_demonology_aoe help=shortcd specialization=demonology
{
 if not InCombat() DemonologyPrecombatShortCdActions()
 unless not InCombat() and DemonologyPrecombatShortCdPostConditions()
 {
  DemonologyDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=demonology
{
 if not InCombat() DemonologyPrecombatMainActions()
 unless not InCombat() and DemonologyPrecombatMainPostConditions()
 {
  DemonologyDefaultMainActions()
 }
}

AddIcon checkbox=opt_warlock_demonology_aoe help=aoe specialization=demonology
{
 if not InCombat() DemonologyPrecombatMainActions()
 unless not InCombat() and DemonologyPrecombatMainPostConditions()
 {
  DemonologyDefaultMainActions()
 }
}

AddIcon checkbox=!opt_warlock_demonology_aoe enemies=1 help=cd specialization=demonology
{
 if not InCombat() DemonologyPrecombatCdActions()
 unless not InCombat() and DemonologyPrecombatCdPostConditions()
 {
  DemonologyDefaultCdActions()
 }
}

AddIcon checkbox=opt_warlock_demonology_aoe help=cd specialization=demonology
{
 if not InCombat() DemonologyPrecombatCdActions()
 unless not InCombat() and DemonologyPrecombatCdPostConditions()
 {
  DemonologyDefaultCdActions()
 }
}

### Required symbols
# summon_felguard
# grimoire_of_supremacy_talent
# grimoire_of_sacrifice_talent
# demonic_power_buff
# summon_infernal
# lord_of_flames
# summon_doomguard
# prolonged_power_potion
# demonic_empowerment
# demonbolt
# shadow_bolt
# implosion
# demonic_synergy_buff
# soul_conduit_talent
# hand_of_guldan
# shadowflame
# shadowflame_debuff
# 132369
# call_dreadstalkers
# summon_darkglare_talent
# power_trip_talent
# implosion_talent
# demonic_calling_buff
# doom
# hand_of_doom_talent
# doom_debuff
# service_felguard
# 132379
# sindorei_spite_icd
# shadowy_inspiration_buff
# summon_darkglare
# shadowy_inspiration_talent
# thalkiels_ascendance
# berserking
# blood_fury_sp
# soul_harvest
# soul_harvest_buff
# thalkiels_consumption
# life_tap
# service_pet
# demonwrath
# demonbolt_talent
]]
    OvaleScripts:RegisterScript("WARLOCK", "demonology", name, desc, code, "script")
end
do
    local name = "sc_warlock_destruction_t19"
    local desc = "[7.0] Simulationcraft: Warlock_Destruction_T19"
    local code = [[
# Based on SimulationCraft profile "Warlock_Destruction_T19P".
#	class=warlock
#	spec=destruction
#	talents=2203022
#	pet=imp

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)

AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=destruction)

AddFunction DestructionUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.precombat

AddFunction DestructionPrecombatMainActions
{
 #snapshot_stats
 #grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
 if Talent(grimoire_of_sacrifice_talent) and pet.Present() Spell(grimoire_of_sacrifice)
 #life_tap,if=talent.empowered_life_tap.enabled&!buff.empowered_life_tap.remains
 if Talent(empowered_life_tap_talent) and not BuffPresent(empowered_life_tap_buff) Spell(life_tap)
 #chaos_bolt
 Spell(chaos_bolt)
}

AddFunction DestructionPrecombatMainPostConditions
{
}

AddFunction DestructionPrecombatShortCdActions
{
 #flask
 #food
 #augmentation
 #summon_pet,if=!talent.grimoire_of_supremacy.enabled&(!talent.grimoire_of_sacrifice.enabled|buff.demonic_power.down)
 if not Talent(grimoire_of_supremacy_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(demonic_power_buff) } and not pet.Present() Spell(summon_imp)
}

AddFunction DestructionPrecombatShortCdPostConditions
{
 Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice) or Talent(empowered_life_tap_talent) and not BuffPresent(empowered_life_tap_buff) and Spell(life_tap) or Spell(chaos_bolt)
}

AddFunction DestructionPrecombatCdActions
{
 unless not Talent(grimoire_of_supremacy_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(demonic_power_buff) } and not pet.Present() and Spell(summon_imp)
 {
  #summon_infernal,if=talent.grimoire_of_supremacy.enabled&artifact.lord_of_flames.rank>0
  if Talent(grimoire_of_supremacy_talent) and ArtifactTraitRank(lord_of_flames) > 0 Spell(summon_infernal)
  #summon_infernal,if=talent.grimoire_of_supremacy.enabled&active_enemies>1
  if Talent(grimoire_of_supremacy_talent) and Enemies() > 1 Spell(summon_infernal)
  #summon_doomguard,if=talent.grimoire_of_supremacy.enabled&active_enemies=1&artifact.lord_of_flames.rank=0
  if Talent(grimoire_of_supremacy_talent) and Enemies() == 1 and ArtifactTraitRank(lord_of_flames) == 0 Spell(summon_doomguard)

  unless Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice) or Talent(empowered_life_tap_talent) and not BuffPresent(empowered_life_tap_buff) and Spell(life_tap)
  {
   #potion
   if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
  }
 }
}

AddFunction DestructionPrecombatCdPostConditions
{
 not Talent(grimoire_of_supremacy_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(demonic_power_buff) } and not pet.Present() and Spell(summon_imp) or Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice) or Talent(empowered_life_tap_talent) and not BuffPresent(empowered_life_tap_buff) and Spell(life_tap) or Spell(chaos_bolt)
}

### actions.default

AddFunction DestructionDefaultMainActions
{
 #immolate,cycle_targets=1,if=active_enemies=2&talent.roaring_blaze.enabled&!cooldown.havoc.remains&dot.immolate.remains<=buff.active_havoc.duration
 if Enemies() == 2 and Talent(roaring_blaze_talent) and not SpellCooldown(havoc) > 0 and target.DebuffRemaining(immolate_debuff) <= BaseDuration(havoc_buff) Spell(immolate)
 #immolate,if=(active_enemies<5|!talent.fire_and_brimstone.enabled)&remains<=tick_time
 if { Enemies() < 5 or not Talent(fire_and_brimstone_talent) } and target.DebuffRemaining(immolate_debuff) <= target.TickTime(immolate_debuff) Spell(immolate)
 #immolate,cycle_targets=1,if=(active_enemies<5|!talent.fire_and_brimstone.enabled)&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>=action.immolate.cast_time*active_enemies)&active_enemies>1&remains<=tick_time&(!talent.roaring_blaze.enabled|(!debuff.roaring_blaze.remains&action.conflagrate.charges<2+set_bonus.tier19_4pc))
 if { Enemies() < 5 or not Talent(fire_and_brimstone_talent) } and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) >= CastTime(immolate) * Enemies() } and Enemies() > 1 and target.DebuffRemaining(immolate_debuff) <= target.TickTime(immolate_debuff) and { not Talent(roaring_blaze_talent) or not target.DebuffPresent(roaring_blaze_debuff) and Charges(conflagrate) < 2 + ArmorSetBonus(T19 4) } Spell(immolate)
 #immolate,if=talent.roaring_blaze.enabled&remains<=duration&!debuff.roaring_blaze.remains&target.time_to_die>10&(action.conflagrate.charges=2+set_bonus.tier19_4pc|(action.conflagrate.charges>=1+set_bonus.tier19_4pc&action.conflagrate.recharge_time<cast_time+gcd)|target.time_to_die<24)
 if Talent(roaring_blaze_talent) and target.DebuffRemaining(immolate_debuff) <= BaseDuration(immolate_debuff) and not target.DebuffPresent(roaring_blaze_debuff) and target.TimeToDie() > 10 and { Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) or Charges(conflagrate) >= 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < CastTime(immolate) + GCD() or target.TimeToDie() < 24 } Spell(immolate)
 #shadowburn,if=buff.conflagration_of_chaos.remains<=action.chaos_bolt.cast_time
 if BuffRemaining(conflagration_of_chaos_buff) <= CastTime(chaos_bolt) Spell(shadowburn)
 #shadowburn,if=(charges=1+set_bonus.tier19_4pc&recharge_time<action.chaos_bolt.cast_time|charges=2+set_bonus.tier19_4pc)&soul_shard<5
 if { Charges(shadowburn) == 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(shadowburn) < CastTime(chaos_bolt) or Charges(shadowburn) == 2 + ArmorSetBonus(T19 4) } and SoulShards() < 5 Spell(shadowburn)
 #conflagrate,if=talent.roaring_blaze.enabled&(charges=2+set_bonus.tier19_4pc|(charges>=1+set_bonus.tier19_4pc&recharge_time<gcd)|target.time_to_die<24)
 if Talent(roaring_blaze_talent) and { Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) or Charges(conflagrate) >= 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < GCD() or target.TimeToDie() < 24 } Spell(conflagrate)
 #conflagrate,if=talent.roaring_blaze.enabled&debuff.roaring_blaze.stack>0&dot.immolate.remains>dot.immolate.duration*0.3&(active_enemies=1|soul_shard<3)&soul_shard<5
 if Talent(roaring_blaze_talent) and target.DebuffStacks(roaring_blaze_debuff) > 0 and target.DebuffRemaining(immolate_debuff) > target.DebuffDuration(immolate_debuff) * 0 and { Enemies() == 1 or SoulShards() < 3 } and SoulShards() < 5 Spell(conflagrate)
 #conflagrate,if=!talent.roaring_blaze.enabled&buff.backdraft.stack<3&buff.conflagration_of_chaos.remains<=action.chaos_bolt.cast_time
 if not Talent(roaring_blaze_talent) and BuffStacks(backdraft_buff) < 3 and BuffRemaining(conflagration_of_chaos_buff) <= CastTime(chaos_bolt) Spell(conflagrate)
 #conflagrate,if=!talent.roaring_blaze.enabled&buff.backdraft.stack<3&(charges=1+set_bonus.tier19_4pc&recharge_time<action.chaos_bolt.cast_time|charges=2+set_bonus.tier19_4pc)&soul_shard<5
 if not Talent(roaring_blaze_talent) and BuffStacks(backdraft_buff) < 3 and { Charges(conflagrate) == 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < CastTime(chaos_bolt) or Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) } and SoulShards() < 5 Spell(conflagrate)
 #life_tap,if=talent.empowered_life_tap.enabled&buff.empowered_life_tap.remains<=gcd
 if Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() Spell(life_tap)
 #chaos_bolt,if=active_enemies<4&buff.active_havoc.remains>cast_time
 if Enemies() < 4 and BuffRemaining(havoc_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
 #channel_demonfire,if=dot.immolate.remains>cast_time&(active_enemies=1|buff.active_havoc.remains<action.chaos_bolt.cast_time)
 if target.DebuffRemaining(immolate_debuff) > CastTime(channel_demonfire) and { Enemies() == 1 or BuffRemaining(havoc_buff) < CastTime(chaos_bolt) } Spell(channel_demonfire)
 #rain_of_fire,if=active_enemies>=3
 if Enemies() >= 3 Spell(rain_of_fire)
 #rain_of_fire,if=active_enemies>=6&talent.wreak_havoc.enabled
 if Enemies() >= 6 and Talent(wreak_havoc_talent) Spell(rain_of_fire)
 #life_tap,if=talent.empowered_life_tap.enabled&buff.empowered_life_tap.remains<duration*0.3
 if Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) < BaseDuration(empowered_life_tap_buff) * 0 Spell(life_tap)
 #chaos_bolt,if=active_enemies<3&target.time_to_die<=10
 if Enemies() < 3 and target.TimeToDie() <= 10 Spell(chaos_bolt)
 #chaos_bolt,if=active_enemies<3&(cooldown.havoc.remains>12&cooldown.havoc.remains|active_enemies=1|soul_shard>=5-spell_targets.infernal_awakening*0.5)&(soul_shard>=5-spell_targets.infernal_awakening*0.5|buff.soul_harvest.remains>cast_time|buff.concordance_of_the_legionfall.remains>cast_time)
 if Enemies() < 3 and { SpellCooldown(havoc) > 12 and SpellCooldown(havoc) > 0 or Enemies() == 1 or SoulShards() >= 5 - Enemies() * 0 } and { SoulShards() >= 5 - Enemies() * 0 or BuffRemaining(soul_harvest_buff) > CastTime(chaos_bolt) or BuffRemaining(concordance_of_the_legionfall_buff) > CastTime(chaos_bolt) } Spell(chaos_bolt)
 #chaos_bolt,if=active_enemies<3&(cooldown.havoc.remains>12&cooldown.havoc.remains|active_enemies=1|soul_shard>=5-spell_targets.infernal_awakening*0.5)&(trinket.proc.mastery.react&trinket.proc.mastery.remains>cast_time|trinket.proc.crit.react&trinket.proc.crit.remains>cast_time|trinket.proc.versatility.react&trinket.proc.versatility.remains>cast_time|trinket.proc.intellect.react&trinket.proc.intellect.remains>cast_time|trinket.proc.spell_power.react&trinket.proc.spell_power.remains>cast_time)
 if Enemies() < 3 and { SpellCooldown(havoc) > 12 and SpellCooldown(havoc) > 0 or Enemies() == 1 or SoulShards() >= 5 - Enemies() * 0 } and { BuffPresent(trinket_proc_mastery_buff) and BuffRemaining(trinket_proc_mastery_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_crit_buff) and BuffRemaining(trinket_proc_crit_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_versatility_buff) and BuffRemaining(trinket_proc_versatility_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_spell_power_buff) and BuffRemaining(trinket_proc_spell_power_buff) > CastTime(chaos_bolt) } Spell(chaos_bolt)
 #chaos_bolt,if=active_enemies<3&(cooldown.havoc.remains>12&cooldown.havoc.remains|active_enemies=1|soul_shard>=5-spell_targets.infernal_awakening*0.5)&(trinket.stacking_proc.mastery.react&trinket.stacking_proc.mastery.remains>cast_time|trinket.stacking_proc.crit.react&trinket.stacking_proc.crit.remains>cast_time|trinket.stacking_proc.versatility.react&trinket.stacking_proc.versatility.remains>cast_time|trinket.stacking_proc.intellect.react&trinket.stacking_proc.intellect.remains>cast_time|trinket.stacking_proc.spell_power.react&trinket.stacking_proc.spell_power.remains>cast_time)
 if Enemies() < 3 and { SpellCooldown(havoc) > 12 and SpellCooldown(havoc) > 0 or Enemies() == 1 or SoulShards() >= 5 - Enemies() * 0 } and { BuffPresent(trinket_stacking_proc_mastery_buff) and BuffRemaining(trinket_stacking_proc_mastery_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_crit_buff) and BuffRemaining(trinket_stacking_proc_crit_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_versatility_buff) and BuffRemaining(trinket_stacking_proc_versatility_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_intellect_buff) and BuffRemaining(trinket_stacking_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_spell_power_buff) and BuffRemaining(trinket_stacking_proc_spell_power_buff) > CastTime(chaos_bolt) } Spell(chaos_bolt)
 #shadowburn
 Spell(shadowburn)
 #conflagrate,if=!talent.roaring_blaze.enabled&buff.backdraft.stack<3
 if not Talent(roaring_blaze_talent) and BuffStacks(backdraft_buff) < 3 Spell(conflagrate)
 #immolate,cycle_targets=1,if=(active_enemies<5|!talent.fire_and_brimstone.enabled)&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>=action.immolate.cast_time*active_enemies)&!talent.roaring_blaze.enabled&remains<=duration*0.3
 if { Enemies() < 5 or not Talent(fire_and_brimstone_talent) } and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) >= CastTime(immolate) * Enemies() } and not Talent(roaring_blaze_talent) and target.DebuffRemaining(immolate_debuff) <= BaseDuration(immolate_debuff) * 0 Spell(immolate)
 #incinerate
 Spell(incinerate)
 #life_tap
 Spell(life_tap)
}

AddFunction DestructionDefaultMainPostConditions
{
}

AddFunction DestructionDefaultShortCdActions
{
 unless Enemies() == 2 and Talent(roaring_blaze_talent) and not SpellCooldown(havoc) > 0 and target.DebuffRemaining(immolate_debuff) <= BaseDuration(havoc_buff) and Spell(immolate)
 {
  #havoc,target=2,if=active_enemies>1&(active_enemies<4|talent.wreak_havoc.enabled&active_enemies<6)&!debuff.havoc.remains
  if Enemies() > 1 and { Enemies() < 4 or Talent(wreak_havoc_talent) and Enemies() < 6 } and not target.DebuffPresent(havoc_debuff) and Enemies() > 1 Spell(havoc text=other)
  #dimensional_rift,if=charges=3
  if Charges(dimensional_rift) == 3 Spell(dimensional_rift)
  #cataclysm,if=spell_targets.cataclysm>=3
  if Enemies() >= 3 Spell(cataclysm)

  unless { Enemies() < 5 or not Talent(fire_and_brimstone_talent) } and target.DebuffRemaining(immolate_debuff) <= target.TickTime(immolate_debuff) and Spell(immolate) or { Enemies() < 5 or not Talent(fire_and_brimstone_talent) } and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) >= CastTime(immolate) * Enemies() } and Enemies() > 1 and target.DebuffRemaining(immolate_debuff) <= target.TickTime(immolate_debuff) and { not Talent(roaring_blaze_talent) or not target.DebuffPresent(roaring_blaze_debuff) and Charges(conflagrate) < 2 + ArmorSetBonus(T19 4) } and Spell(immolate) or Talent(roaring_blaze_talent) and target.DebuffRemaining(immolate_debuff) <= BaseDuration(immolate_debuff) and not target.DebuffPresent(roaring_blaze_debuff) and target.TimeToDie() > 10 and { Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) or Charges(conflagrate) >= 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < CastTime(immolate) + GCD() or target.TimeToDie() < 24 } and Spell(immolate) or BuffRemaining(conflagration_of_chaos_buff) <= CastTime(chaos_bolt) and Spell(shadowburn) or { Charges(shadowburn) == 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(shadowburn) < CastTime(chaos_bolt) or Charges(shadowburn) == 2 + ArmorSetBonus(T19 4) } and SoulShards() < 5 and Spell(shadowburn) or Talent(roaring_blaze_talent) and { Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) or Charges(conflagrate) >= 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < GCD() or target.TimeToDie() < 24 } and Spell(conflagrate) or Talent(roaring_blaze_talent) and target.DebuffStacks(roaring_blaze_debuff) > 0 and target.DebuffRemaining(immolate_debuff) > target.DebuffDuration(immolate_debuff) * 0 and { Enemies() == 1 or SoulShards() < 3 } and SoulShards() < 5 and Spell(conflagrate) or not Talent(roaring_blaze_talent) and BuffStacks(backdraft_buff) < 3 and BuffRemaining(conflagration_of_chaos_buff) <= CastTime(chaos_bolt) and Spell(conflagrate) or not Talent(roaring_blaze_talent) and BuffStacks(backdraft_buff) < 3 and { Charges(conflagrate) == 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < CastTime(chaos_bolt) or Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) } and SoulShards() < 5 and Spell(conflagrate) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap)
  {
   #dimensional_rift,if=equipped.144369&!buff.lessons_of_spacetime.remains&((!talent.grimoire_of_supremacy.enabled&!cooldown.summon_doomguard.remains)|(talent.grimoire_of_service.enabled&!cooldown.service_pet.remains)|(talent.soul_harvest.enabled&!cooldown.soul_harvest.remains))
   if HasEquippedItem(144369) and not BuffPresent(lessons_of_spacetime_buff) and { not Talent(grimoire_of_supremacy_talent) and not SpellCooldown(summon_doomguard) > 0 or Talent(grimoire_of_service_talent) and not SpellCooldown(service_pet) > 0 or Talent(soul_harvest_talent) and not SpellCooldown(soul_harvest) > 0 } Spell(dimensional_rift)
   #service_pet
   Spell(service_imp)

   unless Enemies() < 4 and BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or target.DebuffRemaining(immolate_debuff) > CastTime(channel_demonfire) and { Enemies() == 1 or BuffRemaining(havoc_buff) < CastTime(chaos_bolt) } and Spell(channel_demonfire) or Enemies() >= 3 and Spell(rain_of_fire) or Enemies() >= 6 and Talent(wreak_havoc_talent) and Spell(rain_of_fire)
   {
    #dimensional_rift,if=target.time_to_die<=32|!equipped.144369|charges>1|(!equipped.144369&(!talent.grimoire_of_service.enabled|recharge_time<cooldown.service_pet.remains)&(!talent.soul_harvest.enabled|recharge_time<cooldown.soul_harvest.remains)&(!talent.grimoire_of_supremacy.enabled|recharge_time<cooldown.summon_doomguard.remains))
    if target.TimeToDie() <= 32 or not HasEquippedItem(144369) or Charges(dimensional_rift) > 1 or not HasEquippedItem(144369) and { not Talent(grimoire_of_service_talent) or SpellChargeCooldown(dimensional_rift) < SpellCooldown(service_pet) } and { not Talent(soul_harvest_talent) or SpellChargeCooldown(dimensional_rift) < SpellCooldown(soul_harvest) } and { not Talent(grimoire_of_supremacy_talent) or SpellChargeCooldown(dimensional_rift) < SpellCooldown(summon_doomguard) } Spell(dimensional_rift)

    unless Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) < BaseDuration(empowered_life_tap_buff) * 0 and Spell(life_tap)
    {
     #cataclysm
     Spell(cataclysm)
    }
   }
  }
 }
}

AddFunction DestructionDefaultShortCdPostConditions
{
 Enemies() == 2 and Talent(roaring_blaze_talent) and not SpellCooldown(havoc) > 0 and target.DebuffRemaining(immolate_debuff) <= BaseDuration(havoc_buff) and Spell(immolate) or { Enemies() < 5 or not Talent(fire_and_brimstone_talent) } and target.DebuffRemaining(immolate_debuff) <= target.TickTime(immolate_debuff) and Spell(immolate) or { Enemies() < 5 or not Talent(fire_and_brimstone_talent) } and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) >= CastTime(immolate) * Enemies() } and Enemies() > 1 and target.DebuffRemaining(immolate_debuff) <= target.TickTime(immolate_debuff) and { not Talent(roaring_blaze_talent) or not target.DebuffPresent(roaring_blaze_debuff) and Charges(conflagrate) < 2 + ArmorSetBonus(T19 4) } and Spell(immolate) or Talent(roaring_blaze_talent) and target.DebuffRemaining(immolate_debuff) <= BaseDuration(immolate_debuff) and not target.DebuffPresent(roaring_blaze_debuff) and target.TimeToDie() > 10 and { Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) or Charges(conflagrate) >= 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < CastTime(immolate) + GCD() or target.TimeToDie() < 24 } and Spell(immolate) or BuffRemaining(conflagration_of_chaos_buff) <= CastTime(chaos_bolt) and Spell(shadowburn) or { Charges(shadowburn) == 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(shadowburn) < CastTime(chaos_bolt) or Charges(shadowburn) == 2 + ArmorSetBonus(T19 4) } and SoulShards() < 5 and Spell(shadowburn) or Talent(roaring_blaze_talent) and { Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) or Charges(conflagrate) >= 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < GCD() or target.TimeToDie() < 24 } and Spell(conflagrate) or Talent(roaring_blaze_talent) and target.DebuffStacks(roaring_blaze_debuff) > 0 and target.DebuffRemaining(immolate_debuff) > target.DebuffDuration(immolate_debuff) * 0 and { Enemies() == 1 or SoulShards() < 3 } and SoulShards() < 5 and Spell(conflagrate) or not Talent(roaring_blaze_talent) and BuffStacks(backdraft_buff) < 3 and BuffRemaining(conflagration_of_chaos_buff) <= CastTime(chaos_bolt) and Spell(conflagrate) or not Talent(roaring_blaze_talent) and BuffStacks(backdraft_buff) < 3 and { Charges(conflagrate) == 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < CastTime(chaos_bolt) or Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) } and SoulShards() < 5 and Spell(conflagrate) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap) or Enemies() < 4 and BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or target.DebuffRemaining(immolate_debuff) > CastTime(channel_demonfire) and { Enemies() == 1 or BuffRemaining(havoc_buff) < CastTime(chaos_bolt) } and Spell(channel_demonfire) or Enemies() >= 3 and Spell(rain_of_fire) or Enemies() >= 6 and Talent(wreak_havoc_talent) and Spell(rain_of_fire) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) < BaseDuration(empowered_life_tap_buff) * 0 and Spell(life_tap) or Enemies() < 3 and target.TimeToDie() <= 10 and Spell(chaos_bolt) or Enemies() < 3 and { SpellCooldown(havoc) > 12 and SpellCooldown(havoc) > 0 or Enemies() == 1 or SoulShards() >= 5 - Enemies() * 0 } and { SoulShards() >= 5 - Enemies() * 0 or BuffRemaining(soul_harvest_buff) > CastTime(chaos_bolt) or BuffRemaining(concordance_of_the_legionfall_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or Enemies() < 3 and { SpellCooldown(havoc) > 12 and SpellCooldown(havoc) > 0 or Enemies() == 1 or SoulShards() >= 5 - Enemies() * 0 } and { BuffPresent(trinket_proc_mastery_buff) and BuffRemaining(trinket_proc_mastery_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_crit_buff) and BuffRemaining(trinket_proc_crit_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_versatility_buff) and BuffRemaining(trinket_proc_versatility_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_spell_power_buff) and BuffRemaining(trinket_proc_spell_power_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or Enemies() < 3 and { SpellCooldown(havoc) > 12 and SpellCooldown(havoc) > 0 or Enemies() == 1 or SoulShards() >= 5 - Enemies() * 0 } and { BuffPresent(trinket_stacking_proc_mastery_buff) and BuffRemaining(trinket_stacking_proc_mastery_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_crit_buff) and BuffRemaining(trinket_stacking_proc_crit_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_versatility_buff) and BuffRemaining(trinket_stacking_proc_versatility_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_intellect_buff) and BuffRemaining(trinket_stacking_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_spell_power_buff) and BuffRemaining(trinket_stacking_proc_spell_power_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or Spell(shadowburn) or not Talent(roaring_blaze_talent) and BuffStacks(backdraft_buff) < 3 and Spell(conflagrate) or { Enemies() < 5 or not Talent(fire_and_brimstone_talent) } and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) >= CastTime(immolate) * Enemies() } and not Talent(roaring_blaze_talent) and target.DebuffRemaining(immolate_debuff) <= BaseDuration(immolate_debuff) * 0 and Spell(immolate) or Spell(incinerate) or Spell(life_tap)
}

AddFunction DestructionDefaultCdActions
{
 unless Enemies() == 2 and Talent(roaring_blaze_talent) and not SpellCooldown(havoc) > 0 and target.DebuffRemaining(immolate_debuff) <= BaseDuration(havoc_buff) and Spell(immolate) or Enemies() > 1 and { Enemies() < 4 or Talent(wreak_havoc_talent) and Enemies() < 6 } and not target.DebuffPresent(havoc_debuff) and Enemies() > 1 and Spell(havoc text=other) or Charges(dimensional_rift) == 3 and Spell(dimensional_rift) or Enemies() >= 3 and Spell(cataclysm) or { Enemies() < 5 or not Talent(fire_and_brimstone_talent) } and target.DebuffRemaining(immolate_debuff) <= target.TickTime(immolate_debuff) and Spell(immolate) or { Enemies() < 5 or not Talent(fire_and_brimstone_talent) } and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) >= CastTime(immolate) * Enemies() } and Enemies() > 1 and target.DebuffRemaining(immolate_debuff) <= target.TickTime(immolate_debuff) and { not Talent(roaring_blaze_talent) or not target.DebuffPresent(roaring_blaze_debuff) and Charges(conflagrate) < 2 + ArmorSetBonus(T19 4) } and Spell(immolate) or Talent(roaring_blaze_talent) and target.DebuffRemaining(immolate_debuff) <= BaseDuration(immolate_debuff) and not target.DebuffPresent(roaring_blaze_debuff) and target.TimeToDie() > 10 and { Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) or Charges(conflagrate) >= 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < CastTime(immolate) + GCD() or target.TimeToDie() < 24 } and Spell(immolate)
 {
  #berserking
  Spell(berserking)
  #blood_fury
  Spell(blood_fury_sp)
  #use_items
  DestructionUseItemActions()
  #potion,name=deadly_grace,if=(buff.soul_harvest.remains|trinket.proc.any.react|target.time_to_die<=45)
  if { BuffPresent(soul_harvest_buff) or BuffPresent(trinket_proc_any_buff) or target.TimeToDie() <= 45 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(deadly_grace_potion usable=1)

  unless BuffRemaining(conflagration_of_chaos_buff) <= CastTime(chaos_bolt) and Spell(shadowburn) or { Charges(shadowburn) == 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(shadowburn) < CastTime(chaos_bolt) or Charges(shadowburn) == 2 + ArmorSetBonus(T19 4) } and SoulShards() < 5 and Spell(shadowburn) or Talent(roaring_blaze_talent) and { Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) or Charges(conflagrate) >= 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < GCD() or target.TimeToDie() < 24 } and Spell(conflagrate) or Talent(roaring_blaze_talent) and target.DebuffStacks(roaring_blaze_debuff) > 0 and target.DebuffRemaining(immolate_debuff) > target.DebuffDuration(immolate_debuff) * 0 and { Enemies() == 1 or SoulShards() < 3 } and SoulShards() < 5 and Spell(conflagrate) or not Talent(roaring_blaze_talent) and BuffStacks(backdraft_buff) < 3 and BuffRemaining(conflagration_of_chaos_buff) <= CastTime(chaos_bolt) and Spell(conflagrate) or not Talent(roaring_blaze_talent) and BuffStacks(backdraft_buff) < 3 and { Charges(conflagrate) == 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < CastTime(chaos_bolt) or Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) } and SoulShards() < 5 and Spell(conflagrate) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap) or HasEquippedItem(144369) and not BuffPresent(lessons_of_spacetime_buff) and { not Talent(grimoire_of_supremacy_talent) and not SpellCooldown(summon_doomguard) > 0 or Talent(grimoire_of_service_talent) and not SpellCooldown(service_pet) > 0 or Talent(soul_harvest_talent) and not SpellCooldown(soul_harvest) > 0 } and Spell(dimensional_rift) or Spell(service_imp)
  {
   #summon_infernal,if=artifact.lord_of_flames.rank>0&!buff.lord_of_flames.remains
   if ArtifactTraitRank(lord_of_flames) > 0 and not BuffPresent(lord_of_flames_buff) Spell(summon_infernal)
   #summon_doomguard,if=!talent.grimoire_of_supremacy.enabled&spell_targets.infernal_awakening<=2&(target.time_to_die>180|target.health.pct<=20|target.time_to_die<30)
   if not Talent(grimoire_of_supremacy_talent) and Enemies() <= 2 and { target.TimeToDie() > 180 or target.HealthPercent() <= 20 or target.TimeToDie() < 30 } Spell(summon_doomguard)
   #summon_infernal,if=!talent.grimoire_of_supremacy.enabled&spell_targets.infernal_awakening>2
   if not Talent(grimoire_of_supremacy_talent) and Enemies() > 2 Spell(summon_infernal)
   #summon_doomguard,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal=1&artifact.lord_of_flames.rank>0&buff.lord_of_flames.remains&!pet.doomguard.active
   if Talent(grimoire_of_supremacy_talent) and Enemies() == 1 and ArtifactTraitRank(lord_of_flames) > 0 and BuffPresent(lord_of_flames_buff) and not pet.Present() Spell(summon_doomguard)
   #summon_doomguard,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal=1&equipped.132379&!cooldown.sindorei_spite_icd.remains
   if Talent(grimoire_of_supremacy_talent) and Enemies() == 1 and HasEquippedItem(132379) and not SpellCooldown(sindorei_spite_icd) > 0 Spell(summon_doomguard)
   #summon_infernal,if=talent.grimoire_of_supremacy.enabled&spell_targets.summon_infernal>1&equipped.132379&!cooldown.sindorei_spite_icd.remains
   if Talent(grimoire_of_supremacy_talent) and Enemies() > 1 and HasEquippedItem(132379) and not SpellCooldown(sindorei_spite_icd) > 0 Spell(summon_infernal)
   #soul_harvest,if=!buff.soul_harvest.remains
   if not BuffPresent(soul_harvest_buff) Spell(soul_harvest)
  }
 }
}

AddFunction DestructionDefaultCdPostConditions
{
 Enemies() == 2 and Talent(roaring_blaze_talent) and not SpellCooldown(havoc) > 0 and target.DebuffRemaining(immolate_debuff) <= BaseDuration(havoc_buff) and Spell(immolate) or Enemies() > 1 and { Enemies() < 4 or Talent(wreak_havoc_talent) and Enemies() < 6 } and not target.DebuffPresent(havoc_debuff) and Enemies() > 1 and Spell(havoc text=other) or Charges(dimensional_rift) == 3 and Spell(dimensional_rift) or Enemies() >= 3 and Spell(cataclysm) or { Enemies() < 5 or not Talent(fire_and_brimstone_talent) } and target.DebuffRemaining(immolate_debuff) <= target.TickTime(immolate_debuff) and Spell(immolate) or { Enemies() < 5 or not Talent(fire_and_brimstone_talent) } and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) >= CastTime(immolate) * Enemies() } and Enemies() > 1 and target.DebuffRemaining(immolate_debuff) <= target.TickTime(immolate_debuff) and { not Talent(roaring_blaze_talent) or not target.DebuffPresent(roaring_blaze_debuff) and Charges(conflagrate) < 2 + ArmorSetBonus(T19 4) } and Spell(immolate) or Talent(roaring_blaze_talent) and target.DebuffRemaining(immolate_debuff) <= BaseDuration(immolate_debuff) and not target.DebuffPresent(roaring_blaze_debuff) and target.TimeToDie() > 10 and { Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) or Charges(conflagrate) >= 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < CastTime(immolate) + GCD() or target.TimeToDie() < 24 } and Spell(immolate) or BuffRemaining(conflagration_of_chaos_buff) <= CastTime(chaos_bolt) and Spell(shadowburn) or { Charges(shadowburn) == 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(shadowburn) < CastTime(chaos_bolt) or Charges(shadowburn) == 2 + ArmorSetBonus(T19 4) } and SoulShards() < 5 and Spell(shadowburn) or Talent(roaring_blaze_talent) and { Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) or Charges(conflagrate) >= 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < GCD() or target.TimeToDie() < 24 } and Spell(conflagrate) or Talent(roaring_blaze_talent) and target.DebuffStacks(roaring_blaze_debuff) > 0 and target.DebuffRemaining(immolate_debuff) > target.DebuffDuration(immolate_debuff) * 0 and { Enemies() == 1 or SoulShards() < 3 } and SoulShards() < 5 and Spell(conflagrate) or not Talent(roaring_blaze_talent) and BuffStacks(backdraft_buff) < 3 and BuffRemaining(conflagration_of_chaos_buff) <= CastTime(chaos_bolt) and Spell(conflagrate) or not Talent(roaring_blaze_talent) and BuffStacks(backdraft_buff) < 3 and { Charges(conflagrate) == 1 + ArmorSetBonus(T19 4) and SpellChargeCooldown(conflagrate) < CastTime(chaos_bolt) or Charges(conflagrate) == 2 + ArmorSetBonus(T19 4) } and SoulShards() < 5 and Spell(conflagrate) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) <= GCD() and Spell(life_tap) or HasEquippedItem(144369) and not BuffPresent(lessons_of_spacetime_buff) and { not Talent(grimoire_of_supremacy_talent) and not SpellCooldown(summon_doomguard) > 0 or Talent(grimoire_of_service_talent) and not SpellCooldown(service_pet) > 0 or Talent(soul_harvest_talent) and not SpellCooldown(soul_harvest) > 0 } and Spell(dimensional_rift) or Spell(service_imp) or Enemies() < 4 and BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or target.DebuffRemaining(immolate_debuff) > CastTime(channel_demonfire) and { Enemies() == 1 or BuffRemaining(havoc_buff) < CastTime(chaos_bolt) } and Spell(channel_demonfire) or Enemies() >= 3 and Spell(rain_of_fire) or Enemies() >= 6 and Talent(wreak_havoc_talent) and Spell(rain_of_fire) or { target.TimeToDie() <= 32 or not HasEquippedItem(144369) or Charges(dimensional_rift) > 1 or not HasEquippedItem(144369) and { not Talent(grimoire_of_service_talent) or SpellChargeCooldown(dimensional_rift) < SpellCooldown(service_pet) } and { not Talent(soul_harvest_talent) or SpellChargeCooldown(dimensional_rift) < SpellCooldown(soul_harvest) } and { not Talent(grimoire_of_supremacy_talent) or SpellChargeCooldown(dimensional_rift) < SpellCooldown(summon_doomguard) } } and Spell(dimensional_rift) or Talent(empowered_life_tap_talent) and BuffRemaining(empowered_life_tap_buff) < BaseDuration(empowered_life_tap_buff) * 0 and Spell(life_tap) or Spell(cataclysm) or Enemies() < 3 and target.TimeToDie() <= 10 and Spell(chaos_bolt) or Enemies() < 3 and { SpellCooldown(havoc) > 12 and SpellCooldown(havoc) > 0 or Enemies() == 1 or SoulShards() >= 5 - Enemies() * 0 } and { SoulShards() >= 5 - Enemies() * 0 or BuffRemaining(soul_harvest_buff) > CastTime(chaos_bolt) or BuffRemaining(concordance_of_the_legionfall_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or Enemies() < 3 and { SpellCooldown(havoc) > 12 and SpellCooldown(havoc) > 0 or Enemies() == 1 or SoulShards() >= 5 - Enemies() * 0 } and { BuffPresent(trinket_proc_mastery_buff) and BuffRemaining(trinket_proc_mastery_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_crit_buff) and BuffRemaining(trinket_proc_crit_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_versatility_buff) and BuffRemaining(trinket_proc_versatility_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_spell_power_buff) and BuffRemaining(trinket_proc_spell_power_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or Enemies() < 3 and { SpellCooldown(havoc) > 12 and SpellCooldown(havoc) > 0 or Enemies() == 1 or SoulShards() >= 5 - Enemies() * 0 } and { BuffPresent(trinket_stacking_proc_mastery_buff) and BuffRemaining(trinket_stacking_proc_mastery_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_crit_buff) and BuffRemaining(trinket_stacking_proc_crit_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_versatility_buff) and BuffRemaining(trinket_stacking_proc_versatility_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_intellect_buff) and BuffRemaining(trinket_stacking_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_spell_power_buff) and BuffRemaining(trinket_stacking_proc_spell_power_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or Spell(shadowburn) or not Talent(roaring_blaze_talent) and BuffStacks(backdraft_buff) < 3 and Spell(conflagrate) or { Enemies() < 5 or not Talent(fire_and_brimstone_talent) } and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) >= CastTime(immolate) * Enemies() } and not Talent(roaring_blaze_talent) and target.DebuffRemaining(immolate_debuff) <= BaseDuration(immolate_debuff) * 0 and Spell(immolate) or Spell(incinerate) or Spell(life_tap)
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
 unless not InCombat() and DestructionPrecombatMainPostConditions()
 {
  DestructionDefaultMainActions()
 }
}

AddIcon checkbox=opt_warlock_destruction_aoe help=aoe specialization=destruction
{
 if not InCombat() DestructionPrecombatMainActions()
 unless not InCombat() and DestructionPrecombatMainPostConditions()
 {
  DestructionDefaultMainActions()
 }
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
# summon_imp
# grimoire_of_supremacy_talent
# grimoire_of_sacrifice_talent
# demonic_power_buff
# summon_infernal
# lord_of_flames
# summon_doomguard
# grimoire_of_sacrifice
# life_tap
# empowered_life_tap_talent
# empowered_life_tap_buff
# prolonged_power_potion
# chaos_bolt
# immolate
# roaring_blaze_talent
# havoc
# immolate_debuff
# havoc_buff
# wreak_havoc_talent
# havoc_debuff
# dimensional_rift
# cataclysm
# fire_and_brimstone_talent
# cataclysm_talent
# roaring_blaze_debuff
# conflagrate
# berserking
# blood_fury_sp
# deadly_grace_potion
# soul_harvest_buff
# shadowburn
# conflagration_of_chaos_buff
# backdraft_buff
# 144369
# lessons_of_spacetime_buff
# grimoire_of_service_talent
# service_pet
# soul_harvest_talent
# soul_harvest
# service_imp
# lord_of_flames_buff
# doomguard
# 132379
# sindorei_spite_icd
# channel_demonfire
# rain_of_fire
# concordance_of_the_legionfall_buff
# trinket_proc_spell_power_buff
# trinket_stacking_proc_spell_power_buff
# incinerate
]]
    OvaleScripts:RegisterScript("WARLOCK", "destruction", name, desc, code, "script")
end
