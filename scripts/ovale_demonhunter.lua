local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "icyveins_demonhunter_vengeance"
	local desc = "[7.0] Icy-Veins: DemonHunter Vengeance"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_demonhunter_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=vengeance)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=vengeance)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=vengeance)

AddFunction VengeancePlayDefensively
{
	CheckBoxOn(opt_demonhunter_vengeance_defensive) or HealthPercent() <= 35 or IncomingDamage(5) >= MaxHealth() * 0.5
}

AddFunction VengeancePlayOffensively
{
	not VengeancePlayDefensively()
}

AddFunction VengeanceHealMe
{
	if (HealthPercent() < 70) Spell(fel_devastation)
	if (HealthPercent() < 70) Spell(soul_cleave)
	if (IncomingDamage(5) >= MaxHealth() * 0.5) Spell(soul_cleave)
}

AddFunction VengeanceInfernalStrike
{
	(not Talent(flame_crash_talent) or VengeanceSigilOfFlame()) and
	(	
		(SpellCharges(infernal_strike) >= SpellMaxCharges(infernal_strike)) or 
		(SpellCharges(infernal_strike) == SpellMaxCharges(infernal_strike)-1 and SpellChargeCooldown(infernal_strike)<=2*GCD())
	)
}

AddFunction VengeanceSigilOfFlame
{
	(not SigilCharging(flame) and target.DebuffRemaining(sigil_of_flame_debuff) <= 2-Talent(quickened_sigils_talent))
}

AddFunction VengeanceRangeCheck
{
	if (CheckBoxOn(opt_melee_range) and not target.InRange(fracture))
	{
		if (target.InRange(felblade)) Spell(felblade)
		if (target.Distance(more 5) and (target.Distance(less 30) or (target.Distance(less 40) and Talent(abyssal_strike_talent)))) Spell(infernal_strike text=range)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction VengeanceDefaultShortCDActions
{
	if ((VengeancePlayOffensively() and (BuffExpires(demon_spikes) or not Talent(razor_spikes_talent))) or VengeancePlayDefensively()) Spell(soul_barrier)
	
	if (IncomingDamage(5 physical=1) > 0 and BuffRemaining(demon_spikes_buff)<2*BaseDuration(demon_spikes_buff))
	{
		if (Charges(demon_spikes) == 0 and PainDeficit() >= 60*(1+0.2*BuffPresent(blade_turning_buff))) Spell(demonic_infusion)
		if (VengeancePlayDefensively() or Talent(razor_spikes_talent)) Spell(demon_spikes)
		if (Charges(demon_spikes count=0) >= 1.8) Spell(demon_spikes)
	}
	
	VengeanceRangeCheck()
}

AddFunction VengeanceDefaultMainActions
{
	VengeanceHealMe()
	
	# Razor spikes are up
	if (VengeancePlayOffensively() and Talent(razor_spikes_talent) and not BuffExpires(demon_spikes_buff))
	{
		Spell(fracture)
		if not Talent(fracture_talent) Spell(soul_cleave)
		Spell(shear)
	}
	
	# Fiery demise
	if (not target.DebuffExpires(fiery_demise_debuff))
	{
		Spell(soul_carver)
		if (PainDeficit() > 10*(1+0.2*BuffPresent(blade_turning_buff))) Spell(immolation_aura)
		Spell(fel_devastation)
		if (PainDeficit() > 20*(1+0.2*BuffPresent(blade_turning_buff))) Spell(felblade)
		if (SoulFragments() >= 5-Talent(fracture_talent)) Spell(spirit_bomb)
		if (VengeanceSigilOfFlame()) Spell(sigil_of_flame)
		if (VengeanceInfernalStrike()) Spell(infernal_strike)
		Spell(fel_eruption)
	}
	
	# Regular rotation
	if (target.TimeToDie() > 5) Spell(soul_carver)
	if (VengeancePlayOffensively() and (not HasArtifactTrait(fiery_demise) or SpellCooldownDuration(fel_devastation) < SpellCooldown(fiery_brand))) Spell(fel_devastation)
	if (Pain() >= 70) Spell(fracture)
	if (Pain() >= 70) Spell(soul_cleave)
	if (target.DebuffRefreshable(frailty_debuff) or (VengeancePlayOffensively() and SoulFragments() >= 5-Talent(fracture_talent))) Spell(spirit_bomb)
	if (PainDeficit() > 10*(1+0.2*BuffPresent(blade_turning_buff))) Spell(immolation_aura)
	if (PainDeficit() > 20*(1+0.2*BuffPresent(blade_turning_buff))) Spell(felblade)
	Spell(fel_eruption)
	if (VengeanceSigilOfFlame()) Spell(sigil_of_flame)
	if (VengeanceInfernalStrike()) Spell(infernal_strike)
	Spell(shear)
}

AddFunction VengeanceDefaultAoEActions
{
	VengeanceHealMe()
	
	if (VengeancePlayOffensively() and Talent(razor_spikes_talent) and not BuffExpires(demon_spikes_buff)) Spell(soul_cleave)
	if (target.TimeToDie() > 5) Spell(soul_carver)
	if (VengeancePlayOffensively()) Spell(fel_devastation)
	if (VengeancePlayDefensively() and target.DebuffRefreshable(frailty_debuff) or SoulFragments() >= 5-Talent(fracture_talent)) Spell(spirit_bomb)
	if (Pain() >= 70) Spell(fracture)
	if (Pain() >= 70) Spell(soul_cleave)
	if (VengeanceInfernalStrike()) Spell(infernal_strike)
	if (Talent(burning_alive_talent) and target.TimeToDie() >= 8) Spell(fiery_brand)
	if (PainDeficit() >= 20*(1+0.2*BuffPresent(blade_turning_buff))) Spell(immolation_aura)
	if (PainDeficit() >= 20*(1+0.2*BuffPresent(blade_turning_buff))) Spell(felblade)
	if (VengeanceSigilOfFlame()) Spell(sigil_of_flame)
	Spell(fel_eruption)
	Spell(shear)
}

AddFunction VengeanceDefaultCdActions
{
	VengeanceInterruptActions()
	if IncomingDamage(1.5 magic=1) > 0 Spell(empower_wards)
	if (HasEquippedItem(shifting_cosmic_sliver)) Spell(metamorphosis_veng)
	Spell(fiery_brand)
	Item(Trinket0Slot text=13 usable=1)
	Item(Trinket1Slot text=14 usable=1)
	if BuffExpires(metamorphosis_veng_buff) Spell(metamorphosis_veng)
	if CheckBoxOn(opt_use_consumables) Item(unbending_potion usable=1)
}

AddFunction VengeanceInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(consume_magic) Spell(consume_magic)
		if not target.Classification(worldboss) and not SigilCharging(silence misery chains)
		{
			if target.Distance(less 8) Spell(arcane_torrent_dh)
			Spell(fel_eruption)
			if (target.RemainingCastTime() >= (2 - Talent(quickened_sigils_talent) + GCDRemaining()))
			{
				Spell(sigil_of_silence)
				Spell(sigil_of_misery)
				Spell(sigil_of_chains)
			}
			if target.CreatureType(Demon Humanoid Beast) Spell(imprison)
		}
	}
}

AddCheckBox(opt_demonhunter_vengeance_defensive L("Play Defensively") default specialization=vengeance)
AddCheckBox(opt_demonhunter_vengeance_aoe L(AOE) default specialization=vengeance)

AddIcon help=shortcd specialization=vengeance
{
	VengeanceDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=vengeance
{
	VengeanceDefaultMainActions()
}

AddIcon checkbox=opt_demonhunter_vengeance_aoe help=aoe specialization=vengeance
{
	VengeanceDefaultAoEActions()
}

AddIcon help=cd specialization=vengeance
{
	#if not InCombat() VengeancePrecombatCdActions()
	VengeanceDefaultCdActions()
}
	]]
	OvaleScripts:RegisterScript("DEMONHUNTER", "vengeance", name, desc, code, "script")
end

-- THE REST OF THIS FILE IS AUTOMATICALLY GENERATED.
-- ANY CHANGES MADE BELOW THIS POINT WILL BE LOST.

do
	local name = "simulationcraft_demon_hunter_havoc_t19p"
	local desc = "[7.0] SimulationCraft: Demon_Hunter_Havoc_T19P"
	local code = [[
# Based on SimulationCraft profile "Demon_Hunter_Havoc_T19P".
#	class=demonhunter
#	spec=havoc
#	talents=2220311

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_demonhunter_spells)


AddFunction pooling_for_meta
{
	not Talent(demonic_talent) and SpellCooldown(metamorphosis_havoc) < 6 and FuryDeficit() > 30 and { not waiting_for_nemesis() or SpellCooldown(nemesis) < 10 } and { not waiting_for_chaos_blades() or SpellCooldown(chaos_blades) < 6 }
}

AddFunction pooling_for_chaos_strike
{
	Talent(chaos_cleave_talent) and FuryDeficit() > 40 and not False(raid_event_adds_exists) and 600 < 2 * GCD()
}

AddFunction waiting_for_chaos_blades
{
	not { not Talent(chaos_blades_talent) or Talent(chaos_blades_talent) and SpellCooldown(chaos_blades) == 0 or SpellCooldown(chaos_blades) > target.TimeToDie() or SpellCooldown(chaos_blades) > 60 }
}

AddFunction pooling_for_blade_dance
{
	blade_dance() and Fury() - 40 < 35 - TalentPoints(first_blood_talent) * 20 and Enemies() >= 3 + TalentPoints(chaos_cleave_talent) * 3
}

AddFunction waiting_for_nemesis
{
	not { not Talent(nemesis_talent) or Talent(nemesis_talent) and SpellCooldown(nemesis) == 0 or SpellCooldown(nemesis) > target.TimeToDie() or SpellCooldown(nemesis) > 60 }
}

AddFunction blade_dance
{
	Talent(first_blood_talent) or ArmorSetBonus(T20 2) or Enemies() >= 3 + TalentPoints(chaos_cleave_talent) * 3
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=havoc)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=havoc)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=havoc)
AddCheckBox(opt_meta_only_during_boss L(meta_only_during_boss) default specialization=havoc)
AddCheckBox(opt_fel_rush SpellName(fel_rush) default specialization=havoc)
AddCheckBox(opt_vengeful_retreat SpellName(vengeful_retreat) default specialization=havoc)

AddFunction HavocInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
	{
		if target.InRange(consume_magic) and target.IsInterruptible() Spell(consume_magic)
		if target.InRange(fel_eruption) and not target.Classification(worldboss) Spell(fel_eruption)
		if target.Distance(less 8) and target.IsInterruptible() Spell(arcane_torrent_dh)
		if target.Distance(less 8) and not target.Classification(worldboss) Spell(chaos_nova)
		if target.InRange(imprison) and not target.Classification(worldboss) and target.CreatureType(Demon Humanoid Beast) Spell(imprison)
	}
}

AddFunction HavocUseItemActions
{
	Item(Trinket0Slot text=13 usable=1)
	Item(Trinket1Slot text=14 usable=1)
}

AddFunction HavocGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(chaos_strike)
	{
		if target.InRange(felblade) Spell(felblade)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

### actions.default

AddFunction HavocDefaultMainActions
{
	#call_action_list,name=cooldown,if=gcd.remains=0
	if not GCDRemaining() > 0 HavocCooldownMainActions()

	unless not GCDRemaining() > 0 and HavocCooldownMainPostConditions()
	{
		#run_action_list,name=demonic,if=talent.demonic.enabled&talent.demonic_appetite.enabled&talent.blind_fury.enabled
		if Talent(demonic_talent) and Talent(demonic_appetite_talent) and Talent(blind_fury_talent) HavocDemonicMainActions()

		unless Talent(demonic_talent) and Talent(demonic_appetite_talent) and Talent(blind_fury_talent) and HavocDemonicMainPostConditions()
		{
			#run_action_list,name=normal
			HavocNormalMainActions()
		}
	}
}

AddFunction HavocDefaultMainPostConditions
{
	not GCDRemaining() > 0 and HavocCooldownMainPostConditions() or Talent(demonic_talent) and Talent(demonic_appetite_talent) and Talent(blind_fury_talent) and HavocDemonicMainPostConditions() or HavocNormalMainPostConditions()
}

AddFunction HavocDefaultShortCdActions
{
	#auto_attack
	HavocGetInMeleeRange()
	#call_action_list,name=cooldown,if=gcd.remains=0
	if not GCDRemaining() > 0 HavocCooldownShortCdActions()

	unless not GCDRemaining() > 0 and HavocCooldownShortCdPostConditions()
	{
		#run_action_list,name=demonic,if=talent.demonic.enabled&talent.demonic_appetite.enabled&talent.blind_fury.enabled
		if Talent(demonic_talent) and Talent(demonic_appetite_talent) and Talent(blind_fury_talent) HavocDemonicShortCdActions()

		unless Talent(demonic_talent) and Talent(demonic_appetite_talent) and Talent(blind_fury_talent) and HavocDemonicShortCdPostConditions()
		{
			#run_action_list,name=normal
			HavocNormalShortCdActions()
		}
	}
}

AddFunction HavocDefaultShortCdPostConditions
{
	not GCDRemaining() > 0 and HavocCooldownShortCdPostConditions() or Talent(demonic_talent) and Talent(demonic_appetite_talent) and Talent(blind_fury_talent) and HavocDemonicShortCdPostConditions() or HavocNormalShortCdPostConditions()
}

AddFunction HavocDefaultCdActions
{
	#variable,name=waiting_for_nemesis,value=!(!talent.nemesis.enabled|cooldown.nemesis.ready|cooldown.nemesis.remains>target.time_to_die|cooldown.nemesis.remains>60)
	#variable,name=waiting_for_chaos_blades,value=!(!talent.chaos_blades.enabled|cooldown.chaos_blades.ready|cooldown.chaos_blades.remains>target.time_to_die|cooldown.chaos_blades.remains>60)
	#variable,name=pooling_for_meta,value=!talent.demonic.enabled&cooldown.metamorphosis.remains<6&fury.deficit>30&(!variable.waiting_for_nemesis|cooldown.nemesis.remains<10)&(!variable.waiting_for_chaos_blades|cooldown.chaos_blades.remains<6)
	#variable,name=blade_dance,value=talent.first_blood.enabled|set_bonus.tier20_2pc|spell_targets.blade_dance1>=3+(talent.chaos_cleave.enabled*3)
	#variable,name=pooling_for_blade_dance,value=variable.blade_dance&fury-40<35-talent.first_blood.enabled*20&(spell_targets.blade_dance1>=3+(talent.chaos_cleave.enabled*3))
	#variable,name=pooling_for_chaos_strike,value=talent.chaos_cleave.enabled&fury.deficit>40&!raid_event.adds.up&raid_event.adds.in<2*gcd
	#consume_magic
	HavocInterruptActions()
	#call_action_list,name=cooldown,if=gcd.remains=0
	if not GCDRemaining() > 0 HavocCooldownCdActions()

	unless not GCDRemaining() > 0 and HavocCooldownCdPostConditions()
	{
		#run_action_list,name=demonic,if=talent.demonic.enabled&talent.demonic_appetite.enabled&talent.blind_fury.enabled
		if Talent(demonic_talent) and Talent(demonic_appetite_talent) and Talent(blind_fury_talent) HavocDemonicCdActions()

		unless Talent(demonic_talent) and Talent(demonic_appetite_talent) and Talent(blind_fury_talent) and HavocDemonicCdPostConditions()
		{
			#run_action_list,name=normal
			HavocNormalCdActions()
		}
	}
}

AddFunction HavocDefaultCdPostConditions
{
	not GCDRemaining() > 0 and HavocCooldownCdPostConditions() or Talent(demonic_talent) and Talent(demonic_appetite_talent) and Talent(blind_fury_talent) and HavocDemonicCdPostConditions() or HavocNormalCdPostConditions()
}

### actions.cooldown

AddFunction HavocCooldownMainActions
{
}

AddFunction HavocCooldownMainPostConditions
{
}

AddFunction HavocCooldownShortCdActions
{
}

AddFunction HavocCooldownShortCdPostConditions
{
}

AddFunction HavocCooldownCdActions
{
	#metamorphosis,if=!(talent.demonic.enabled|variable.pooling_for_meta|variable.waiting_for_nemesis|variable.waiting_for_chaos_blades)|target.time_to_die<25
	if { not { Talent(demonic_talent) or pooling_for_meta() or waiting_for_nemesis() or waiting_for_chaos_blades() } or target.TimeToDie() < 25 } and { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } Spell(metamorphosis_havoc)
	#metamorphosis,if=talent.demonic.enabled&buff.metamorphosis.up&fury<40
	if Talent(demonic_talent) and BuffPresent(metamorphosis_havoc_buff) and Fury() < 40 and { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } Spell(metamorphosis_havoc)
	#nemesis,target_if=min:target.time_to_die,if=raid_event.adds.exists&debuff.nemesis.down&(active_enemies>desired_targets|raid_event.adds.in>60)
	if False(raid_event_adds_exists) and target.DebuffExpires(nemesis_debuff) and { Enemies() > Enemies(tagged=1) or 600 > 60 } Spell(nemesis)
	#nemesis,if=!raid_event.adds.exists&(buff.chaos_blades.up|buff.metamorphosis.up|cooldown.metamorphosis.adjusted_remains<20|target.time_to_die<=60)
	if not False(raid_event_adds_exists) and { BuffPresent(chaos_blades_buff) or BuffPresent(metamorphosis_havoc_buff) or SpellCooldown(metamorphosis_havoc) < 20 or target.TimeToDie() <= 60 } Spell(nemesis)
	#chaos_blades,if=buff.metamorphosis.up|cooldown.metamorphosis.adjusted_remains>60|target.time_to_die<=12
	if BuffPresent(metamorphosis_havoc_buff) or SpellCooldown(metamorphosis_havoc) > 60 or target.TimeToDie() <= 12 Spell(chaos_blades)
	#use_item,slot=trinket2,if=!buff.metamorphosis.up&(!talent.first_blood.enabled|!cooldown.blade_dance.ready)&(!talent.nemesis.enabled|cooldown.nemesis.remains>30|target.time_to_die<cooldown.nemesis.remains+3)
	if not BuffPresent(metamorphosis_havoc_buff) and { not Talent(first_blood_talent) or not SpellCooldown(blade_dance) == 0 } and { not Talent(nemesis_talent) or SpellCooldown(nemesis) > 30 or target.TimeToDie() < SpellCooldown(nemesis) + 3 } HavocUseItemActions()
	#potion,name=old_war,if=buff.metamorphosis.remains>25|target.time_to_die<30
	if { BuffRemaining(metamorphosis_havoc_buff) > 25 or target.TimeToDie() < 30 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war_potion usable=1)
}

AddFunction HavocCooldownCdPostConditions
{
}

### actions.demonic

AddFunction HavocDemonicMainActions
{
	#pick_up_fragment,if=fury.deficit>=35&cooldown.eye_beam.remains>5
	if FuryDeficit() >= 35 and SpellCooldown(eye_beam) > 5 Spell(pick_up_fragment)
	#vengeful_retreat,if=(talent.prepared.enabled|talent.momentum.enabled)&buff.prepared.down&buff.momentum.down
	if { Talent(prepared_talent) or Talent(momentum_talent) } and BuffExpires(prepared_buff) and BuffExpires(momentum_buff) and CheckBoxOn(opt_vengeful_retreat) Spell(vengeful_retreat)
	#fel_rush,if=(talent.momentum.enabled|talent.fel_mastery.enabled)&(!talent.momentum.enabled|(charges=2|cooldown.vengeful_retreat.remains>4)&buff.momentum.down)&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
	if { Talent(momentum_talent) or Talent(fel_mastery_talent) } and { not Talent(momentum_talent) or { Charges(fel_rush) == 2 or SpellCooldown(vengeful_retreat) > 4 } and BuffExpires(momentum_buff) } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
	#throw_glaive,if=talent.bloodlet.enabled&(!talent.momentum.enabled|buff.momentum.up)&charges=2
	if Talent(bloodlet_talent) and { not Talent(momentum_talent) or BuffPresent(momentum_buff) } and Charges(throw_glaive_havoc) == 2 Spell(throw_glaive_havoc)
	#death_sweep,if=variable.blade_dance
	if blade_dance() Spell(death_sweep)
	#fel_eruption
	Spell(fel_eruption)
	#fury_of_the_illidari,if=(active_enemies>desired_targets)|(raid_event.adds.in>55&(!talent.momentum.enabled|buff.momentum.up))
	if Enemies() > Enemies(tagged=1) or 600 > 55 and { not Talent(momentum_talent) or BuffPresent(momentum_buff) } Spell(fury_of_the_illidari)
	#blade_dance,if=variable.blade_dance&cooldown.eye_beam.remains>5&!cooldown.metamorphosis.ready
	if blade_dance() and SpellCooldown(eye_beam) > 5 and not { { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } and SpellCooldown(metamorphosis_havoc) == 0 } Spell(blade_dance)
	#throw_glaive,if=talent.bloodlet.enabled&spell_targets>=2&(!talent.master_of_the_glaive.enabled|!talent.momentum.enabled|buff.momentum.up)&(spell_targets>=3|raid_event.adds.in>recharge_time+cooldown)
	if Talent(bloodlet_talent) and Enemies() >= 2 and { not Talent(master_of_the_glaive_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) } and { Enemies() >= 3 or 600 > SpellChargeCooldown(throw_glaive_havoc) + SpellCooldown(throw_glaive_havoc) } Spell(throw_glaive_havoc)
	#eye_beam,if=spell_targets.eye_beam_tick>desired_targets|!buff.metamorphosis.extended_by_demonic
	if Enemies() > Enemies(tagged=1) or not { not BuffExpires(extended_by_demonic_buff) } Spell(eye_beam)
	#annihilation,if=(!talent.momentum.enabled|buff.momentum.up|fury.deficit<30+buff.prepared.up*8|buff.metamorphosis.remains<5)&!variable.pooling_for_blade_dance
	if { not Talent(momentum_talent) or BuffPresent(momentum_buff) or FuryDeficit() < 30 + BuffPresent(prepared_buff) * 8 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() Spell(annihilation)
	#throw_glaive,if=talent.bloodlet.enabled&(!talent.master_of_the_glaive.enabled|!talent.momentum.enabled|buff.momentum.up)&raid_event.adds.in>recharge_time+cooldown
	if Talent(bloodlet_talent) and { not Talent(master_of_the_glaive_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) } and 600 > SpellChargeCooldown(throw_glaive_havoc) + SpellCooldown(throw_glaive_havoc) Spell(throw_glaive_havoc)
	#chaos_strike,if=(!talent.momentum.enabled|buff.momentum.up|fury.deficit<30+buff.prepared.up*8)&!variable.pooling_for_chaos_strike&!variable.pooling_for_meta&!variable.pooling_for_blade_dance
	if { not Talent(momentum_talent) or BuffPresent(momentum_buff) or FuryDeficit() < 30 + BuffPresent(prepared_buff) * 8 } and not pooling_for_chaos_strike() and not pooling_for_meta() and not pooling_for_blade_dance() Spell(chaos_strike)
	#fel_rush,if=!talent.momentum.enabled&buff.metamorphosis.down&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
	if not Talent(momentum_talent) and BuffExpires(metamorphosis_havoc_buff) and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
	#demons_bite
	Spell(demons_bite)
	#throw_glaive,if=buff.out_of_range.up
	if not target.InRange() Spell(throw_glaive_havoc)
	#fel_rush,if=movement.distance>15|(buff.out_of_range.up&!talent.momentum.enabled)
	if { target.Distance() > 15 or not target.InRange() and not Talent(momentum_talent) } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
	#vengeful_retreat,if=movement.distance>15
	if target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) Spell(vengeful_retreat)
}

AddFunction HavocDemonicMainPostConditions
{
}

AddFunction HavocDemonicShortCdActions
{
}

AddFunction HavocDemonicShortCdPostConditions
{
	FuryDeficit() >= 35 and SpellCooldown(eye_beam) > 5 and Spell(pick_up_fragment) or { Talent(prepared_talent) or Talent(momentum_talent) } and BuffExpires(prepared_buff) and BuffExpires(momentum_buff) and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or { Talent(momentum_talent) or Talent(fel_mastery_talent) } and { not Talent(momentum_talent) or { Charges(fel_rush) == 2 or SpellCooldown(vengeful_retreat) > 4 } and BuffExpires(momentum_buff) } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Talent(bloodlet_talent) and { not Talent(momentum_talent) or BuffPresent(momentum_buff) } and Charges(throw_glaive_havoc) == 2 and Spell(throw_glaive_havoc) or blade_dance() and Spell(death_sweep) or Spell(fel_eruption) or { Enemies() > Enemies(tagged=1) or 600 > 55 and { not Talent(momentum_talent) or BuffPresent(momentum_buff) } } and Spell(fury_of_the_illidari) or blade_dance() and SpellCooldown(eye_beam) > 5 and not { { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } and SpellCooldown(metamorphosis_havoc) == 0 } and Spell(blade_dance) or Talent(bloodlet_talent) and Enemies() >= 2 and { not Talent(master_of_the_glaive_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) } and { Enemies() >= 3 or 600 > SpellChargeCooldown(throw_glaive_havoc) + SpellCooldown(throw_glaive_havoc) } and Spell(throw_glaive_havoc) or { Enemies() > Enemies(tagged=1) or not { not BuffExpires(extended_by_demonic_buff) } } and Spell(eye_beam) or { not Talent(momentum_talent) or BuffPresent(momentum_buff) or FuryDeficit() < 30 + BuffPresent(prepared_buff) * 8 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and Spell(annihilation) or Talent(bloodlet_talent) and { not Talent(master_of_the_glaive_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) } and 600 > SpellChargeCooldown(throw_glaive_havoc) + SpellCooldown(throw_glaive_havoc) and Spell(throw_glaive_havoc) or { not Talent(momentum_talent) or BuffPresent(momentum_buff) or FuryDeficit() < 30 + BuffPresent(prepared_buff) * 8 } and not pooling_for_chaos_strike() and not pooling_for_meta() and not pooling_for_blade_dance() and Spell(chaos_strike) or not Talent(momentum_talent) and BuffExpires(metamorphosis_havoc_buff) and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Spell(demons_bite) or not target.InRange() and Spell(throw_glaive_havoc) or { target.Distance() > 15 or not target.InRange() and not Talent(momentum_talent) } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat)
}

AddFunction HavocDemonicCdActions
{
}

AddFunction HavocDemonicCdPostConditions
{
	FuryDeficit() >= 35 and SpellCooldown(eye_beam) > 5 and Spell(pick_up_fragment) or { Talent(prepared_talent) or Talent(momentum_talent) } and BuffExpires(prepared_buff) and BuffExpires(momentum_buff) and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or { Talent(momentum_talent) or Talent(fel_mastery_talent) } and { not Talent(momentum_talent) or { Charges(fel_rush) == 2 or SpellCooldown(vengeful_retreat) > 4 } and BuffExpires(momentum_buff) } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Talent(bloodlet_talent) and { not Talent(momentum_talent) or BuffPresent(momentum_buff) } and Charges(throw_glaive_havoc) == 2 and Spell(throw_glaive_havoc) or blade_dance() and Spell(death_sweep) or Spell(fel_eruption) or { Enemies() > Enemies(tagged=1) or 600 > 55 and { not Talent(momentum_talent) or BuffPresent(momentum_buff) } } and Spell(fury_of_the_illidari) or blade_dance() and SpellCooldown(eye_beam) > 5 and not { { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } and SpellCooldown(metamorphosis_havoc) == 0 } and Spell(blade_dance) or Talent(bloodlet_talent) and Enemies() >= 2 and { not Talent(master_of_the_glaive_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) } and { Enemies() >= 3 or 600 > SpellChargeCooldown(throw_glaive_havoc) + SpellCooldown(throw_glaive_havoc) } and Spell(throw_glaive_havoc) or { Enemies() > Enemies(tagged=1) or not { not BuffExpires(extended_by_demonic_buff) } } and Spell(eye_beam) or { not Talent(momentum_talent) or BuffPresent(momentum_buff) or FuryDeficit() < 30 + BuffPresent(prepared_buff) * 8 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and Spell(annihilation) or Talent(bloodlet_talent) and { not Talent(master_of_the_glaive_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) } and 600 > SpellChargeCooldown(throw_glaive_havoc) + SpellCooldown(throw_glaive_havoc) and Spell(throw_glaive_havoc) or { not Talent(momentum_talent) or BuffPresent(momentum_buff) or FuryDeficit() < 30 + BuffPresent(prepared_buff) * 8 } and not pooling_for_chaos_strike() and not pooling_for_meta() and not pooling_for_blade_dance() and Spell(chaos_strike) or not Talent(momentum_talent) and BuffExpires(metamorphosis_havoc_buff) and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Spell(demons_bite) or not target.InRange() and Spell(throw_glaive_havoc) or { target.Distance() > 15 or not target.InRange() and not Talent(momentum_talent) } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat)
}

### actions.normal

AddFunction HavocNormalMainActions
{
	#pick_up_fragment,if=talent.demonic_appetite.enabled&fury.deficit>=35
	if Talent(demonic_appetite_talent) and FuryDeficit() >= 35 Spell(pick_up_fragment)
	#vengeful_retreat,if=(talent.prepared.enabled|talent.momentum.enabled)&buff.prepared.down&buff.momentum.down
	if { Talent(prepared_talent) or Talent(momentum_talent) } and BuffExpires(prepared_buff) and BuffExpires(momentum_buff) and CheckBoxOn(opt_vengeful_retreat) Spell(vengeful_retreat)
	#fel_rush,if=(talent.momentum.enabled|talent.fel_mastery.enabled)&(!talent.momentum.enabled|(charges=2|cooldown.vengeful_retreat.remains>4)&buff.momentum.down)&(!talent.fel_mastery.enabled|fury.deficit>=25)&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
	if { Talent(momentum_talent) or Talent(fel_mastery_talent) } and { not Talent(momentum_talent) or { Charges(fel_rush) == 2 or SpellCooldown(vengeful_retreat) > 4 } and BuffExpires(momentum_buff) } and { not Talent(fel_mastery_talent) or FuryDeficit() >= 25 } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
	#fel_barrage,if=(charges=max_charges)&(buff.momentum.up|!talent.momentum.enabled)&(active_enemies>desired_targets|raid_event.adds.in>30)
	if Charges(fel_barrage) == SpellMaxCharges(fel_barrage) and { BuffPresent(momentum_buff) or not Talent(momentum_talent) } and { Enemies() > Enemies(tagged=1) or 600 > 30 } Spell(fel_barrage)
	#throw_glaive,if=talent.bloodlet.enabled&(!talent.momentum.enabled|buff.momentum.up)&charges=2
	if Talent(bloodlet_talent) and { not Talent(momentum_talent) or BuffPresent(momentum_buff) } and Charges(throw_glaive_havoc) == 2 Spell(throw_glaive_havoc)
	#felblade,if=fury<15&(cooldown.death_sweep.remains<2*gcd|cooldown.blade_dance.remains<2*gcd)
	if Fury() < 15 and { SpellCooldown(death_sweep) < 2 * GCD() or SpellCooldown(blade_dance) < 2 * GCD() } Spell(felblade)
	#death_sweep,if=variable.blade_dance
	if blade_dance() Spell(death_sweep)
	#fel_rush,if=charges=2&!talent.momentum.enabled&!talent.fel_mastery.enabled
	if Charges(fel_rush) == 2 and not Talent(momentum_talent) and not Talent(fel_mastery_talent) and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
	#fel_eruption
	Spell(fel_eruption)
	#fury_of_the_illidari,if=(active_enemies>desired_targets)|(raid_event.adds.in>55&(!talent.momentum.enabled|buff.momentum.up)&(!talent.chaos_blades.enabled|buff.chaos_blades.up|cooldown.chaos_blades.remains>30|target.time_to_die<cooldown.chaos_blades.remains))
	if Enemies() > Enemies(tagged=1) or 600 > 55 and { not Talent(momentum_talent) or BuffPresent(momentum_buff) } and { not Talent(chaos_blades_talent) or BuffPresent(chaos_blades_buff) or SpellCooldown(chaos_blades) > 30 or target.TimeToDie() < SpellCooldown(chaos_blades) } Spell(fury_of_the_illidari)
	#blade_dance,if=variable.blade_dance&(!cooldown.metamorphosis.ready)
	if blade_dance() and not { { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } and SpellCooldown(metamorphosis_havoc) == 0 } Spell(blade_dance)
	#throw_glaive,if=talent.bloodlet.enabled&spell_targets>=2&(!talent.master_of_the_glaive.enabled|!talent.momentum.enabled|buff.momentum.up)&(spell_targets>=3|raid_event.adds.in>recharge_time+cooldown)
	if Talent(bloodlet_talent) and Enemies() >= 2 and { not Talent(master_of_the_glaive_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) } and { Enemies() >= 3 or 600 > SpellChargeCooldown(throw_glaive_havoc) + SpellCooldown(throw_glaive_havoc) } Spell(throw_glaive_havoc)
	#felblade,if=fury.deficit>=30+buff.prepared.up*8
	if FuryDeficit() >= 30 + BuffPresent(prepared_buff) * 8 Spell(felblade)
	#eye_beam,if=talent.blind_fury.enabled&(spell_targets.eye_beam_tick>desired_targets|fury.deficit>=35)
	if Talent(blind_fury_talent) and { Enemies() > Enemies(tagged=1) or FuryDeficit() >= 35 } Spell(eye_beam)
	#annihilation,if=(talent.demon_blades.enabled|!talent.momentum.enabled|buff.momentum.up|fury.deficit<30+buff.prepared.up*8|buff.metamorphosis.remains<5)&!variable.pooling_for_blade_dance
	if { Talent(demon_blades_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) or FuryDeficit() < 30 + BuffPresent(prepared_buff) * 8 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() Spell(annihilation)
	#throw_glaive,if=talent.bloodlet.enabled&(!talent.master_of_the_glaive.enabled|!talent.momentum.enabled|buff.momentum.up)&raid_event.adds.in>recharge_time+cooldown
	if Talent(bloodlet_talent) and { not Talent(master_of_the_glaive_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) } and 600 > SpellChargeCooldown(throw_glaive_havoc) + SpellCooldown(throw_glaive_havoc) Spell(throw_glaive_havoc)
	#eye_beam,if=!talent.blind_fury.enabled&(spell_targets.eye_beam_tick>desired_targets|(!set_bonus.tier19_4pc&raid_event.adds.in>45&!variable.pooling_for_meta&buff.metamorphosis.down&(artifact.anguish_of_the_deceiver.enabled|active_enemies>1)&!talent.chaos_cleave.enabled))
	if not Talent(blind_fury_talent) and { Enemies() > Enemies(tagged=1) or not ArmorSetBonus(T19 4) and 600 > 45 and not pooling_for_meta() and BuffExpires(metamorphosis_havoc_buff) and { HasArtifactTrait(anguish_of_the_deceiver) or Enemies() > 1 } and not Talent(chaos_cleave_talent) } Spell(eye_beam)
	#throw_glaive,if=buff.metamorphosis.down&spell_targets>=2
	if BuffExpires(metamorphosis_havoc_buff) and Enemies() >= 2 Spell(throw_glaive_havoc)
	#chaos_strike,if=(talent.demon_blades.enabled|!talent.momentum.enabled|buff.momentum.up|fury.deficit<30+buff.prepared.up*8)&!variable.pooling_for_chaos_strike&!variable.pooling_for_meta&!variable.pooling_for_blade_dance
	if { Talent(demon_blades_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) or FuryDeficit() < 30 + BuffPresent(prepared_buff) * 8 } and not pooling_for_chaos_strike() and not pooling_for_meta() and not pooling_for_blade_dance() Spell(chaos_strike)
	#fel_barrage,if=(charges=max_charges-1)&buff.metamorphosis.down&(buff.momentum.up|!talent.momentum.enabled)&(active_enemies>desired_targets|raid_event.adds.in>30)
	if Charges(fel_barrage) == SpellMaxCharges(fel_barrage) - 1 and BuffExpires(metamorphosis_havoc_buff) and { BuffPresent(momentum_buff) or not Talent(momentum_talent) } and { Enemies() > Enemies(tagged=1) or 600 > 30 } Spell(fel_barrage)
	#fel_rush,if=!talent.momentum.enabled&raid_event.movement.in>charges*10&(talent.demon_blades.enabled|buff.metamorphosis.down)
	if not Talent(momentum_talent) and 600 > Charges(fel_rush) * 10 and { Talent(demon_blades_talent) or BuffExpires(metamorphosis_havoc_buff) } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
	#demons_bite
	Spell(demons_bite)
	#throw_glaive,if=buff.out_of_range.up
	if not target.InRange() Spell(throw_glaive_havoc)
	#felblade,if=movement.distance|buff.out_of_range.up
	if target.Distance() or not target.InRange() Spell(felblade)
	#fel_rush,if=movement.distance>15|(buff.out_of_range.up&!talent.momentum.enabled)
	if { target.Distance() > 15 or not target.InRange() and not Talent(momentum_talent) } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
	#vengeful_retreat,if=movement.distance>15
	if target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) Spell(vengeful_retreat)
	#throw_glaive,if=!talent.bloodlet.enabled
	if not Talent(bloodlet_talent) Spell(throw_glaive_havoc)
}

AddFunction HavocNormalMainPostConditions
{
}

AddFunction HavocNormalShortCdActions
{
}

AddFunction HavocNormalShortCdPostConditions
{
	Talent(demonic_appetite_talent) and FuryDeficit() >= 35 and Spell(pick_up_fragment) or { Talent(prepared_talent) or Talent(momentum_talent) } and BuffExpires(prepared_buff) and BuffExpires(momentum_buff) and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or { Talent(momentum_talent) or Talent(fel_mastery_talent) } and { not Talent(momentum_talent) or { Charges(fel_rush) == 2 or SpellCooldown(vengeful_retreat) > 4 } and BuffExpires(momentum_buff) } and { not Talent(fel_mastery_talent) or FuryDeficit() >= 25 } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Charges(fel_barrage) == SpellMaxCharges(fel_barrage) and { BuffPresent(momentum_buff) or not Talent(momentum_talent) } and { Enemies() > Enemies(tagged=1) or 600 > 30 } and Spell(fel_barrage) or Talent(bloodlet_talent) and { not Talent(momentum_talent) or BuffPresent(momentum_buff) } and Charges(throw_glaive_havoc) == 2 and Spell(throw_glaive_havoc) or Fury() < 15 and { SpellCooldown(death_sweep) < 2 * GCD() or SpellCooldown(blade_dance) < 2 * GCD() } and Spell(felblade) or blade_dance() and Spell(death_sweep) or Charges(fel_rush) == 2 and not Talent(momentum_talent) and not Talent(fel_mastery_talent) and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Spell(fel_eruption) or { Enemies() > Enemies(tagged=1) or 600 > 55 and { not Talent(momentum_talent) or BuffPresent(momentum_buff) } and { not Talent(chaos_blades_talent) or BuffPresent(chaos_blades_buff) or SpellCooldown(chaos_blades) > 30 or target.TimeToDie() < SpellCooldown(chaos_blades) } } and Spell(fury_of_the_illidari) or blade_dance() and not { { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } and SpellCooldown(metamorphosis_havoc) == 0 } and Spell(blade_dance) or Talent(bloodlet_talent) and Enemies() >= 2 and { not Talent(master_of_the_glaive_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) } and { Enemies() >= 3 or 600 > SpellChargeCooldown(throw_glaive_havoc) + SpellCooldown(throw_glaive_havoc) } and Spell(throw_glaive_havoc) or FuryDeficit() >= 30 + BuffPresent(prepared_buff) * 8 and Spell(felblade) or Talent(blind_fury_talent) and { Enemies() > Enemies(tagged=1) or FuryDeficit() >= 35 } and Spell(eye_beam) or { Talent(demon_blades_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) or FuryDeficit() < 30 + BuffPresent(prepared_buff) * 8 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and Spell(annihilation) or Talent(bloodlet_talent) and { not Talent(master_of_the_glaive_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) } and 600 > SpellChargeCooldown(throw_glaive_havoc) + SpellCooldown(throw_glaive_havoc) and Spell(throw_glaive_havoc) or not Talent(blind_fury_talent) and { Enemies() > Enemies(tagged=1) or not ArmorSetBonus(T19 4) and 600 > 45 and not pooling_for_meta() and BuffExpires(metamorphosis_havoc_buff) and { HasArtifactTrait(anguish_of_the_deceiver) or Enemies() > 1 } and not Talent(chaos_cleave_talent) } and Spell(eye_beam) or BuffExpires(metamorphosis_havoc_buff) and Enemies() >= 2 and Spell(throw_glaive_havoc) or { Talent(demon_blades_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) or FuryDeficit() < 30 + BuffPresent(prepared_buff) * 8 } and not pooling_for_chaos_strike() and not pooling_for_meta() and not pooling_for_blade_dance() and Spell(chaos_strike) or Charges(fel_barrage) == SpellMaxCharges(fel_barrage) - 1 and BuffExpires(metamorphosis_havoc_buff) and { BuffPresent(momentum_buff) or not Talent(momentum_talent) } and { Enemies() > Enemies(tagged=1) or 600 > 30 } and Spell(fel_barrage) or not Talent(momentum_talent) and 600 > Charges(fel_rush) * 10 and { Talent(demon_blades_talent) or BuffExpires(metamorphosis_havoc_buff) } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Spell(demons_bite) or not target.InRange() and Spell(throw_glaive_havoc) or { target.Distance() or not target.InRange() } and Spell(felblade) or { target.Distance() > 15 or not target.InRange() and not Talent(momentum_talent) } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or not Talent(bloodlet_talent) and Spell(throw_glaive_havoc)
}

AddFunction HavocNormalCdActions
{
}

AddFunction HavocNormalCdPostConditions
{
	Talent(demonic_appetite_talent) and FuryDeficit() >= 35 and Spell(pick_up_fragment) or { Talent(prepared_talent) or Talent(momentum_talent) } and BuffExpires(prepared_buff) and BuffExpires(momentum_buff) and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or { Talent(momentum_talent) or Talent(fel_mastery_talent) } and { not Talent(momentum_talent) or { Charges(fel_rush) == 2 or SpellCooldown(vengeful_retreat) > 4 } and BuffExpires(momentum_buff) } and { not Talent(fel_mastery_talent) or FuryDeficit() >= 25 } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Charges(fel_barrage) == SpellMaxCharges(fel_barrage) and { BuffPresent(momentum_buff) or not Talent(momentum_talent) } and { Enemies() > Enemies(tagged=1) or 600 > 30 } and Spell(fel_barrage) or Talent(bloodlet_talent) and { not Talent(momentum_talent) or BuffPresent(momentum_buff) } and Charges(throw_glaive_havoc) == 2 and Spell(throw_glaive_havoc) or Fury() < 15 and { SpellCooldown(death_sweep) < 2 * GCD() or SpellCooldown(blade_dance) < 2 * GCD() } and Spell(felblade) or blade_dance() and Spell(death_sweep) or Charges(fel_rush) == 2 and not Talent(momentum_talent) and not Talent(fel_mastery_talent) and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Spell(fel_eruption) or { Enemies() > Enemies(tagged=1) or 600 > 55 and { not Talent(momentum_talent) or BuffPresent(momentum_buff) } and { not Talent(chaos_blades_talent) or BuffPresent(chaos_blades_buff) or SpellCooldown(chaos_blades) > 30 or target.TimeToDie() < SpellCooldown(chaos_blades) } } and Spell(fury_of_the_illidari) or blade_dance() and not { { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } and SpellCooldown(metamorphosis_havoc) == 0 } and Spell(blade_dance) or Talent(bloodlet_talent) and Enemies() >= 2 and { not Talent(master_of_the_glaive_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) } and { Enemies() >= 3 or 600 > SpellChargeCooldown(throw_glaive_havoc) + SpellCooldown(throw_glaive_havoc) } and Spell(throw_glaive_havoc) or FuryDeficit() >= 30 + BuffPresent(prepared_buff) * 8 and Spell(felblade) or Talent(blind_fury_talent) and { Enemies() > Enemies(tagged=1) or FuryDeficit() >= 35 } and Spell(eye_beam) or { Talent(demon_blades_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) or FuryDeficit() < 30 + BuffPresent(prepared_buff) * 8 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and Spell(annihilation) or Talent(bloodlet_talent) and { not Talent(master_of_the_glaive_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) } and 600 > SpellChargeCooldown(throw_glaive_havoc) + SpellCooldown(throw_glaive_havoc) and Spell(throw_glaive_havoc) or not Talent(blind_fury_talent) and { Enemies() > Enemies(tagged=1) or not ArmorSetBonus(T19 4) and 600 > 45 and not pooling_for_meta() and BuffExpires(metamorphosis_havoc_buff) and { HasArtifactTrait(anguish_of_the_deceiver) or Enemies() > 1 } and not Talent(chaos_cleave_talent) } and Spell(eye_beam) or BuffExpires(metamorphosis_havoc_buff) and Enemies() >= 2 and Spell(throw_glaive_havoc) or { Talent(demon_blades_talent) or not Talent(momentum_talent) or BuffPresent(momentum_buff) or FuryDeficit() < 30 + BuffPresent(prepared_buff) * 8 } and not pooling_for_chaos_strike() and not pooling_for_meta() and not pooling_for_blade_dance() and Spell(chaos_strike) or Charges(fel_barrage) == SpellMaxCharges(fel_barrage) - 1 and BuffExpires(metamorphosis_havoc_buff) and { BuffPresent(momentum_buff) or not Talent(momentum_talent) } and { Enemies() > Enemies(tagged=1) or 600 > 30 } and Spell(fel_barrage) or not Talent(momentum_talent) and 600 > Charges(fel_rush) * 10 and { Talent(demon_blades_talent) or BuffExpires(metamorphosis_havoc_buff) } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Spell(demons_bite) or not target.InRange() and Spell(throw_glaive_havoc) or { target.Distance() or not target.InRange() } and Spell(felblade) or { target.Distance() > 15 or not target.InRange() and not Talent(momentum_talent) } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or not Talent(bloodlet_talent) and Spell(throw_glaive_havoc)
}

### actions.precombat

AddFunction HavocPrecombatMainActions
{
}

AddFunction HavocPrecombatMainPostConditions
{
}

AddFunction HavocPrecombatShortCdActions
{
}

AddFunction HavocPrecombatShortCdPostConditions
{
}

AddFunction HavocPrecombatCdActions
{
	#flask,type=flask_of_the_seventh_demon
	#food,type=lavish_suramar_feast,if=!equipped.majordomos_dinner_bell
	#food,type=nightborne_delicacy_platter,if=equipped.majordomos_dinner_bell
	#augmentation,type=defiled
	#snapshot_stats
	#potion,name=old_war
	if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war_potion usable=1)
	#metamorphosis,if=!(talent.demon_reborn.enabled&talent.demonic.enabled)
	if not { Talent(demon_reborn_talent) and Talent(demonic_talent) } and { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } Spell(metamorphosis_havoc)
}

AddFunction HavocPrecombatCdPostConditions
{
}

### Havoc icons.

AddCheckBox(opt_demonhunter_havoc_aoe L(AOE) default specialization=havoc)

AddIcon checkbox=!opt_demonhunter_havoc_aoe enemies=1 help=shortcd specialization=havoc
{
	if not InCombat() HavocPrecombatShortCdActions()
	unless not InCombat() and HavocPrecombatShortCdPostConditions()
	{
		HavocDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_demonhunter_havoc_aoe help=shortcd specialization=havoc
{
	if not InCombat() HavocPrecombatShortCdActions()
	unless not InCombat() and HavocPrecombatShortCdPostConditions()
	{
		HavocDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=havoc
{
	if not InCombat() HavocPrecombatMainActions()
	unless not InCombat() and HavocPrecombatMainPostConditions()
	{
		HavocDefaultMainActions()
	}
}

AddIcon checkbox=opt_demonhunter_havoc_aoe help=aoe specialization=havoc
{
	if not InCombat() HavocPrecombatMainActions()
	unless not InCombat() and HavocPrecombatMainPostConditions()
	{
		HavocDefaultMainActions()
	}
}

AddIcon checkbox=!opt_demonhunter_havoc_aoe enemies=1 help=cd specialization=havoc
{
	if not InCombat() HavocPrecombatCdActions()
	unless not InCombat() and HavocPrecombatCdPostConditions()
	{
		HavocDefaultCdActions()
	}
}

AddIcon checkbox=opt_demonhunter_havoc_aoe help=cd specialization=havoc
{
	if not InCombat() HavocPrecombatCdActions()
	unless not InCombat() and HavocPrecombatCdPostConditions()
	{
		HavocDefaultCdActions()
	}
}

### Required symbols
# anguish_of_the_deceiver
# annihilation
# arcane_torrent_dh
# blade_dance
# blind_fury_talent
# bloodlet_talent
# chaos_blades
# chaos_blades_buff
# chaos_blades_talent
# chaos_cleave_talent
# chaos_nova
# chaos_strike
# consume_magic
# death_sweep
# demon_blades_talent
# demon_reborn_talent
# demonic_appetite_talent
# demonic_talent
# demons_bite
# eye_beam
# fel_barrage
# fel_eruption
# fel_mastery_talent
# fel_rush
# felblade
# first_blood_talent
# fury_of_the_illidari
# imprison
# master_of_the_glaive_talent
# metamorphosis_havoc
# metamorphosis_havoc_buff
# momentum_buff
# momentum_talent
# nemesis
# nemesis_debuff
# nemesis_talent
# old_war_potion
# pick_up_fragment
# prepared_buff
# prepared_talent
# throw_glaive_havoc
# vengeful_retreat
]]
	OvaleScripts:RegisterScript("DEMONHUNTER", "havoc", name, desc, code, "script")
end

do
	local name = "simulationcraft_demon_hunter_vengeance_t19p"
	local desc = "[7.0] SimulationCraft: Demon_Hunter_Vengeance_T19P"
	local code = [[
# Based on SimulationCraft profile "Demon_Hunter_Vengeance_T19P".
#	class=demonhunter
#	spec=vengeance
#	talents=3323313

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_demonhunter_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=vengeance)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=vengeance)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=vengeance)

AddFunction VengeanceInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
	{
		if target.InRange(consume_magic) and target.IsInterruptible() Spell(consume_magic)
		if target.InRange(fel_eruption) and not target.Classification(worldboss) Spell(fel_eruption)
		if target.Distance(less 8) and target.IsInterruptible() Spell(arcane_torrent_dh)
		if target.IsInterruptible() and not target.Classification(worldboss) and not SigilCharging(silence misery chains) and target.RemainingCastTime() >= 2 - Talent(quickened_sigils_talent) + GCDRemaining() Spell(sigil_of_silence)
		if not target.Classification(worldboss) and not SigilCharging(silence misery chains) and target.RemainingCastTime() >= 2 - Talent(quickened_sigils_talent) + GCDRemaining() Spell(sigil_of_misery)
		if not target.Classification(worldboss) and not SigilCharging(silence misery chains) and target.RemainingCastTime() >= 2 - Talent(quickened_sigils_talent) + GCDRemaining() Spell(sigil_of_chains)
		if target.InRange(imprison) and not target.Classification(worldboss) and target.CreatureType(Demon Humanoid Beast) Spell(imprison)
	}
}

AddFunction VengeanceUseItemActions
{
	Item(Trinket0Slot text=13 usable=1)
	Item(Trinket1Slot text=14 usable=1)
}

AddFunction VengeanceGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(shear) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.default

AddFunction VengeanceDefaultMainActions
{
	#infernal_strike,if=!sigil_placed&!in_flight&remains-travel_time-delay<0.3*duration&artifact.fiery_demise.enabled&dot.fiery_brand.ticking
	if not SigilCharging(flame) and not InFlightToTarget(infernal_strike) and target.DebuffRemaining(infernal_strike_debuff) - TravelTime(infernal_strike) - 0 < 0.3 * BaseDuration(infernal_strike_debuff) and HasArtifactTrait(fiery_demise) and target.DebuffPresent(fiery_brand_debuff) Spell(infernal_strike)
	#infernal_strike,if=!sigil_placed&!in_flight&remains-travel_time-delay<0.3*duration&(!artifact.fiery_demise.enabled|(max_charges-charges_fractional)*recharge_time<cooldown.fiery_brand.remains+5)&(cooldown.sigil_of_flame.remains>7|charges=2)
	if not SigilCharging(flame) and not InFlightToTarget(infernal_strike) and target.DebuffRemaining(infernal_strike_debuff) - TravelTime(infernal_strike) - 0 < 0.3 * BaseDuration(infernal_strike_debuff) and { not HasArtifactTrait(fiery_demise) or { SpellMaxCharges(infernal_strike) - Charges(infernal_strike count=0) } * SpellChargeCooldown(infernal_strike) < SpellCooldown(fiery_brand) + 5 } and { SpellCooldown(sigil_of_flame) > 7 or Charges(infernal_strike) == 2 } Spell(infernal_strike)
	#spirit_bomb,if=debuff.frailty.down
	if target.DebuffExpires(frailty_debuff) Spell(spirit_bomb)
	#soul_carver,if=dot.fiery_brand.ticking
	if target.DebuffPresent(fiery_brand_debuff) Spell(soul_carver)
	#immolation_aura,if=pain<=80
	if Pain() <= 80 Spell(immolation_aura)
	#felblade,if=pain<=70
	if Pain() <= 70 Spell(felblade)
	#soul_barrier
	Spell(soul_barrier)
	#soul_cleave,if=soul_fragments=5
	if SoulFragments() == 5 Spell(soul_cleave)
	#soul_cleave,if=incoming_damage_5s>=health.max*0.70
	if IncomingDamage(5) >= MaxHealth() * 0.7 Spell(soul_cleave)
	#fel_eruption
	Spell(fel_eruption)
	#sigil_of_flame,if=remains-delay<=0.3*duration
	if target.DebuffRemaining(sigil_of_flame_debuff) - 0 <= 0.3 * BaseDuration(sigil_of_flame_debuff) Spell(sigil_of_flame)
	#fracture,if=pain>=80&soul_fragments<4&incoming_damage_4s<=health.max*0.20
	if Pain() >= 80 and SoulFragments() < 4 and IncomingDamage(4) <= MaxHealth() * 0.2 Spell(fracture)
	#soul_cleave,if=pain>=80
	if Pain() >= 80 Spell(soul_cleave)
	#shear
	Spell(shear)
}

AddFunction VengeanceDefaultMainPostConditions
{
}

AddFunction VengeanceDefaultShortCdActions
{
	#auto_attack
	VengeanceGetInMeleeRange()
	#demon_spikes,if=charges=2|buff.demon_spikes.down&!dot.fiery_brand.ticking&buff.metamorphosis.down
	if Charges(demon_spikes) == 2 or BuffExpires(demon_spikes_buff) and not target.DebuffPresent(fiery_brand_debuff) and BuffExpires(metamorphosis_veng_buff) Spell(demon_spikes)

	unless not SigilCharging(flame) and not InFlightToTarget(infernal_strike) and target.DebuffRemaining(infernal_strike_debuff) - TravelTime(infernal_strike) - 0 < 0.3 * BaseDuration(infernal_strike_debuff) and HasArtifactTrait(fiery_demise) and target.DebuffPresent(fiery_brand_debuff) and Spell(infernal_strike) or not SigilCharging(flame) and not InFlightToTarget(infernal_strike) and target.DebuffRemaining(infernal_strike_debuff) - TravelTime(infernal_strike) - 0 < 0.3 * BaseDuration(infernal_strike_debuff) and { not HasArtifactTrait(fiery_demise) or { SpellMaxCharges(infernal_strike) - Charges(infernal_strike count=0) } * SpellChargeCooldown(infernal_strike) < SpellCooldown(fiery_brand) + 5 } and { SpellCooldown(sigil_of_flame) > 7 or Charges(infernal_strike) == 2 } and Spell(infernal_strike) or target.DebuffExpires(frailty_debuff) and Spell(spirit_bomb) or target.DebuffPresent(fiery_brand_debuff) and Spell(soul_carver) or Pain() <= 80 and Spell(immolation_aura) or Pain() <= 70 and Spell(felblade) or Spell(soul_barrier) or SoulFragments() == 5 and Spell(soul_cleave)
	{
		#fel_devastation,if=incoming_damage_5s>health.max*0.70
		if IncomingDamage(5) > MaxHealth() * 0.7 Spell(fel_devastation)
	}
}

AddFunction VengeanceDefaultShortCdPostConditions
{
	not SigilCharging(flame) and not InFlightToTarget(infernal_strike) and target.DebuffRemaining(infernal_strike_debuff) - TravelTime(infernal_strike) - 0 < 0.3 * BaseDuration(infernal_strike_debuff) and HasArtifactTrait(fiery_demise) and target.DebuffPresent(fiery_brand_debuff) and Spell(infernal_strike) or not SigilCharging(flame) and not InFlightToTarget(infernal_strike) and target.DebuffRemaining(infernal_strike_debuff) - TravelTime(infernal_strike) - 0 < 0.3 * BaseDuration(infernal_strike_debuff) and { not HasArtifactTrait(fiery_demise) or { SpellMaxCharges(infernal_strike) - Charges(infernal_strike count=0) } * SpellChargeCooldown(infernal_strike) < SpellCooldown(fiery_brand) + 5 } and { SpellCooldown(sigil_of_flame) > 7 or Charges(infernal_strike) == 2 } and Spell(infernal_strike) or target.DebuffExpires(frailty_debuff) and Spell(spirit_bomb) or target.DebuffPresent(fiery_brand_debuff) and Spell(soul_carver) or Pain() <= 80 and Spell(immolation_aura) or Pain() <= 70 and Spell(felblade) or Spell(soul_barrier) or SoulFragments() == 5 and Spell(soul_cleave) or IncomingDamage(5) >= MaxHealth() * 0.7 and Spell(soul_cleave) or Spell(fel_eruption) or target.DebuffRemaining(sigil_of_flame_debuff) - 0 <= 0.3 * BaseDuration(sigil_of_flame_debuff) and Spell(sigil_of_flame) or Pain() >= 80 and SoulFragments() < 4 and IncomingDamage(4) <= MaxHealth() * 0.2 and Spell(fracture) or Pain() >= 80 and Spell(soul_cleave) or Spell(shear)
}

AddFunction VengeanceDefaultCdActions
{
	#consume_magic
	VengeanceInterruptActions()
	#use_item,slot=trinket2
	VengeanceUseItemActions()
	#fiery_brand,if=buff.demon_spikes.down&buff.metamorphosis.down
	if BuffExpires(demon_spikes_buff) and BuffExpires(metamorphosis_veng_buff) Spell(fiery_brand)

	unless { Charges(demon_spikes) == 2 or BuffExpires(demon_spikes_buff) and not target.DebuffPresent(fiery_brand_debuff) and BuffExpires(metamorphosis_veng_buff) } and Spell(demon_spikes)
	{
		#empower_wards,if=debuff.casting.up
		if target.IsInterruptible() Spell(empower_wards)

		unless not SigilCharging(flame) and not InFlightToTarget(infernal_strike) and target.DebuffRemaining(infernal_strike_debuff) - TravelTime(infernal_strike) - 0 < 0.3 * BaseDuration(infernal_strike_debuff) and HasArtifactTrait(fiery_demise) and target.DebuffPresent(fiery_brand_debuff) and Spell(infernal_strike) or not SigilCharging(flame) and not InFlightToTarget(infernal_strike) and target.DebuffRemaining(infernal_strike_debuff) - TravelTime(infernal_strike) - 0 < 0.3 * BaseDuration(infernal_strike_debuff) and { not HasArtifactTrait(fiery_demise) or { SpellMaxCharges(infernal_strike) - Charges(infernal_strike count=0) } * SpellChargeCooldown(infernal_strike) < SpellCooldown(fiery_brand) + 5 } and { SpellCooldown(sigil_of_flame) > 7 or Charges(infernal_strike) == 2 } and Spell(infernal_strike) or target.DebuffExpires(frailty_debuff) and Spell(spirit_bomb) or target.DebuffPresent(fiery_brand_debuff) and Spell(soul_carver) or Pain() <= 80 and Spell(immolation_aura) or Pain() <= 70 and Spell(felblade) or Spell(soul_barrier) or SoulFragments() == 5 and Spell(soul_cleave)
		{
			#metamorphosis,if=buff.demon_spikes.down&!dot.fiery_brand.ticking&buff.metamorphosis.down&incoming_damage_5s>health.max*0.70
			if BuffExpires(demon_spikes_buff) and not target.DebuffPresent(fiery_brand_debuff) and BuffExpires(metamorphosis_veng_buff) and IncomingDamage(5) > MaxHealth() * 0.7 Spell(metamorphosis_veng)
		}
	}
}

AddFunction VengeanceDefaultCdPostConditions
{
	{ Charges(demon_spikes) == 2 or BuffExpires(demon_spikes_buff) and not target.DebuffPresent(fiery_brand_debuff) and BuffExpires(metamorphosis_veng_buff) } and Spell(demon_spikes) or not SigilCharging(flame) and not InFlightToTarget(infernal_strike) and target.DebuffRemaining(infernal_strike_debuff) - TravelTime(infernal_strike) - 0 < 0.3 * BaseDuration(infernal_strike_debuff) and HasArtifactTrait(fiery_demise) and target.DebuffPresent(fiery_brand_debuff) and Spell(infernal_strike) or not SigilCharging(flame) and not InFlightToTarget(infernal_strike) and target.DebuffRemaining(infernal_strike_debuff) - TravelTime(infernal_strike) - 0 < 0.3 * BaseDuration(infernal_strike_debuff) and { not HasArtifactTrait(fiery_demise) or { SpellMaxCharges(infernal_strike) - Charges(infernal_strike count=0) } * SpellChargeCooldown(infernal_strike) < SpellCooldown(fiery_brand) + 5 } and { SpellCooldown(sigil_of_flame) > 7 or Charges(infernal_strike) == 2 } and Spell(infernal_strike) or target.DebuffExpires(frailty_debuff) and Spell(spirit_bomb) or target.DebuffPresent(fiery_brand_debuff) and Spell(soul_carver) or Pain() <= 80 and Spell(immolation_aura) or Pain() <= 70 and Spell(felblade) or Spell(soul_barrier) or SoulFragments() == 5 and Spell(soul_cleave) or IncomingDamage(5) > MaxHealth() * 0.7 and Spell(fel_devastation) or IncomingDamage(5) >= MaxHealth() * 0.7 and Spell(soul_cleave) or Spell(fel_eruption) or target.DebuffRemaining(sigil_of_flame_debuff) - 0 <= 0.3 * BaseDuration(sigil_of_flame_debuff) and Spell(sigil_of_flame) or Pain() >= 80 and SoulFragments() < 4 and IncomingDamage(4) <= MaxHealth() * 0.2 and Spell(fracture) or Pain() >= 80 and Spell(soul_cleave) or Spell(shear)
}

### actions.precombat

AddFunction VengeancePrecombatMainActions
{
}

AddFunction VengeancePrecombatMainPostConditions
{
}

AddFunction VengeancePrecombatShortCdActions
{
}

AddFunction VengeancePrecombatShortCdPostConditions
{
}

AddFunction VengeancePrecombatCdActions
{
	#flask,type=flask_of_the_seventh_demon
	#food,type=nightborne_delicacy_platter
	#augmentation,type=defiled
	#snapshot_stats
	#potion,name=unbending_potion
	if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(unbending_potion usable=1)
}

AddFunction VengeancePrecombatCdPostConditions
{
}

### Vengeance icons.

AddCheckBox(opt_demonhunter_vengeance_aoe L(AOE) default specialization=vengeance)

AddIcon checkbox=!opt_demonhunter_vengeance_aoe enemies=1 help=shortcd specialization=vengeance
{
	if not InCombat() VengeancePrecombatShortCdActions()
	unless not InCombat() and VengeancePrecombatShortCdPostConditions()
	{
		VengeanceDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_demonhunter_vengeance_aoe help=shortcd specialization=vengeance
{
	if not InCombat() VengeancePrecombatShortCdActions()
	unless not InCombat() and VengeancePrecombatShortCdPostConditions()
	{
		VengeanceDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=vengeance
{
	if not InCombat() VengeancePrecombatMainActions()
	unless not InCombat() and VengeancePrecombatMainPostConditions()
	{
		VengeanceDefaultMainActions()
	}
}

AddIcon checkbox=opt_demonhunter_vengeance_aoe help=aoe specialization=vengeance
{
	if not InCombat() VengeancePrecombatMainActions()
	unless not InCombat() and VengeancePrecombatMainPostConditions()
	{
		VengeanceDefaultMainActions()
	}
}

AddIcon checkbox=!opt_demonhunter_vengeance_aoe enemies=1 help=cd specialization=vengeance
{
	if not InCombat() VengeancePrecombatCdActions()
	unless not InCombat() and VengeancePrecombatCdPostConditions()
	{
		VengeanceDefaultCdActions()
	}
}

AddIcon checkbox=opt_demonhunter_vengeance_aoe help=cd specialization=vengeance
{
	if not InCombat() VengeancePrecombatCdActions()
	unless not InCombat() and VengeancePrecombatCdPostConditions()
	{
		VengeanceDefaultCdActions()
	}
}

### Required symbols
# arcane_torrent_dh
# consume_magic
# demon_spikes
# demon_spikes_buff
# empower_wards
# fel_devastation
# fel_eruption
# felblade
# fiery_brand
# fiery_brand_debuff
# fiery_demise
# fracture
# frailty_debuff
# immolation_aura
# imprison
# infernal_strike
# infernal_strike_debuff
# metamorphosis_veng
# metamorphosis_veng_buff
# shear
# sigil_of_chains
# sigil_of_flame
# sigil_of_flame_debuff
# sigil_of_misery
# sigil_of_silence
# soul_barrier
# soul_carver
# soul_cleave
# spirit_bomb
# unbending_potion
]]
	OvaleScripts:RegisterScript("DEMONHUNTER", "vengeance", name, desc, code, "script")
end
