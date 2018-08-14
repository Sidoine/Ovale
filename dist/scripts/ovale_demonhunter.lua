local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts

do
	local name = "icyveins_demonhunter_vengeance"
	local desc = "[8.0.1] Icy-Veins: DemonHunter Vengeance"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_demonhunter_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=vengeance)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=vengeance)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=vengeance)
AddCheckBox(opt_infernal_strike SpellName(infernal_strike) default specialization=vengeance)

AddFunction VengeanceHealMeShortCd
{
    unless(DebuffPresent(healing_immunity_debuff)) 
	{
 		if (HealthPercent() < 35) UseHealthPotions()
	}
}
AddFunction VengeanceHealMeMain
{
	unless(DebuffPresent(healing_immunity_debuff)) 
	{
		if (HealthPercent() < 70) Spell(fel_devastation)
		if (HealthPercent() < 50) 
        {
            if (SoulFragments() >= 4 and Enemies()>=3) Spell(spirit_bomb)
            Spell(soul_cleave)
        }
	}
}

AddFunction VengeanceInfernalStrike
{
	CheckBoxOn(opt_infernal_strike) and (not Talent(flame_crash_talent) or VengeanceSigilOfFlame()) and (SpellFullRecharge(infernal_strike) <= 3)
}

AddFunction VengeanceSigilOfFlame
{
	(not SigilCharging(flame) and target.DebuffRemaining(sigil_of_flame_debuff) <= 2-Talent(quickened_sigils_talent))
}

AddFunction VengeanceRangeCheck
{
	if (CheckBoxOn(opt_melee_range) and not target.InRange(shear))
	{
		if (target.InRange(felblade)) Spell(felblade)
		if (CheckBoxOn(opt_infernal_strike) and (target.Distance(more 5) and (target.Distance() < 30+10*Talent(abyssal_strike_talent)))) Spell(infernal_strike text=range)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction VengeanceDefaultShortCDActions
{
    VengeanceHealMeShortCd()
    Spell(soul_barrier)
	
	if (IncomingDamage(5 physical=1) > 0 and (BuffExpires(metamorphosis_veng_buff) or SpellCharges(demon_spikes) == SpellMaxCharges(demon_spikes) or Talent(razor_spikes_talent)))
	{
		if (BuffRemaining(demon_spikes_buff)<2*BaseDuration(demon_spikes_buff)) Spell(demon_spikes)
	}
	
	VengeanceRangeCheck()
}

AddFunction VengeanceDefaultMainActions
{
    VengeanceHealMeMain()
    if (VengeanceInfernalStrike()) Spell(infernal_strike)
    
    # fiery demise
    if (not target.DebuffExpires(fiery_demise_debuff))
    {
        if (SoulFragments() >= 4) Spell(spirit_bomb)
        Spell(immolation_aura)
        Spell(sigil_of_flame)
        Spell(fel_devastation)
        Spell(felblade)
        Spell(fel_eruption)
    }
    
    # Razor spikes are up
	if (Talent(razor_spikes_talent) and not BuffExpires(demon_spikes_buff))
	{
		#if (Enemies() > 1 or Pain()>=50) Spell(soul_cleave)
        #Spell(fracture)
        #if not BuffExpires(metamorphosis_veng_buff) Spell(shear)
	}
    
    if (SoulFragments() >= 4) Spell(spirit_bomb)
    if (Talent(fracture_talent) and PainDeficit() >= 25) Spell(fracture)
    if (PainDeficit() >= 10) Spell(immolation_aura)
    if (not (PreviousGCDSpell(shear) or PreviousGCDSpell(fracture)) and (SoulFragments() >= 4 or PainDeficit() < 20)) Spell(soul_cleave)
    if (VengeanceSigilOfFlame()) Spell(sigil_of_flame)
    if (not Talent(fracture_talent) and PainDeficit() >= 10) Spell(shear)
    Spell(throw_glaive_veng)
}

AddFunction VengeanceDefaultCdActions
{
	VengeanceInterruptActions()
    Item(Trinket0Slot text=13 usable=1)
	Item(Trinket1Slot text=14 usable=1)
	if (BuffExpires(metamorphosis_veng_buff) and target.DebuffExpires(fiery_brand_debuff)) 
    {
        if (HasEquippedItem(shifting_cosmic_sliver) or ArmorSetBonus(T21 4)) Spell(metamorphosis_veng)
        Spell(fiery_brand)
        Spell(metamorphosis_veng)
        if CheckBoxOn(opt_use_consumables) Item(unbending_potion usable=1)
    }
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
	VengeanceDefaultMainActions()
}

AddIcon help=cd specialization=vengeance
{
	#if not InCombat() VengeancePrecombatCdActions()
	VengeanceDefaultCdActions()
}
	]]
	OvaleScripts:RegisterScript("DEMONHUNTER", "vengeance", name, desc, code, "script")
end
do
    local name = "sc_demon_hunter_havoc_t21"
    local desc = "[8.0] Simulationcraft: Demon_Hunter_Havoc_T21"
    local code = [[
# Based on SimulationCraft profile "T21_Demon_Hunter_Havoc".
#    class=demonhunter
#    spec=havoc
#    talents=3210223

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_demonhunter_spells)


AddFunction pooling_for_meta
{
 not Talent(demonic_talent) and SpellCooldown(metamorphosis_havoc) < 6 and FuryDeficit() > 30 and { not waiting_for_nemesis() or SpellCooldown(nemesis) < 10 }
}

AddFunction waiting_for_momentum
{
 Talent(momentum_talent) and not BuffPresent(momentum_buff)
}

AddFunction waiting_for_dark_slash
{
 Talent(dark_slash_talent) and not pooling_for_blade_dance() and not pooling_for_meta() and not SpellCooldown(dark_slash) > 0
}

AddFunction pooling_for_blade_dance
{
 blade_dance() and Fury() < 75 - TalentPoints(first_blood_talent) * 20
}

AddFunction waiting_for_nemesis
{
 not { not Talent(nemesis_talent) or Talent(nemesis_talent) and SpellCooldown(nemesis) == 0 or SpellCooldown(nemesis) > target.TimeToDie() or SpellCooldown(nemesis) > 60 }
}

AddFunction blade_dance
{
 Talent(first_blood_talent) or ArmorSetBonus(T20 4) or Enemies() >= 3 - TalentPoints(trail_of_ruin_talent)
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
  if target.InRange(disrupt) and target.IsInterruptible() Spell(disrupt)
  if target.InRange(fel_eruption) and not target.Classification(worldboss) Spell(fel_eruption)
  if target.Distance(less 8) and not target.Classification(worldboss) Spell(chaos_nova)
  if target.InRange(imprison) and not target.Classification(worldboss) and target.CreatureType(Demon Humanoid Beast) Spell(imprison)
 }
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
  #pick_up_fragment,if=fury.deficit>=35
  if FuryDeficit() >= 35 Spell(pick_up_fragment)
  #call_action_list,name=dark_slash,if=talent.dark_slash.enabled&(variable.waiting_for_dark_slash|debuff.dark_slash.up)
  if Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } HavocDarkSlashMainActions()

  unless Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } and HavocDarkSlashMainPostConditions()
  {
   #run_action_list,name=demonic,if=talent.demonic.enabled
   if Talent(demonic_talent) HavocDemonicMainActions()

   unless Talent(demonic_talent) and HavocDemonicMainPostConditions()
   {
    #run_action_list,name=normal
    HavocNormalMainActions()
   }
  }
 }
}

AddFunction HavocDefaultMainPostConditions
{
 not GCDRemaining() > 0 and HavocCooldownMainPostConditions() or Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } and HavocDarkSlashMainPostConditions() or Talent(demonic_talent) and HavocDemonicMainPostConditions() or HavocNormalMainPostConditions()
}

AddFunction HavocDefaultShortCdActions
{
 #auto_attack
 HavocGetInMeleeRange()
 #call_action_list,name=cooldown,if=gcd.remains=0
 if not GCDRemaining() > 0 HavocCooldownShortCdActions()

 unless not GCDRemaining() > 0 and HavocCooldownShortCdPostConditions() or FuryDeficit() >= 35 and Spell(pick_up_fragment)
 {
  #call_action_list,name=dark_slash,if=talent.dark_slash.enabled&(variable.waiting_for_dark_slash|debuff.dark_slash.up)
  if Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } HavocDarkSlashShortCdActions()

  unless Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } and HavocDarkSlashShortCdPostConditions()
  {
   #run_action_list,name=demonic,if=talent.demonic.enabled
   if Talent(demonic_talent) HavocDemonicShortCdActions()

   unless Talent(demonic_talent) and HavocDemonicShortCdPostConditions()
   {
    #run_action_list,name=normal
    HavocNormalShortCdActions()
   }
  }
 }
}

AddFunction HavocDefaultShortCdPostConditions
{
 not GCDRemaining() > 0 and HavocCooldownShortCdPostConditions() or FuryDeficit() >= 35 and Spell(pick_up_fragment) or Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } and HavocDarkSlashShortCdPostConditions() or Talent(demonic_talent) and HavocDemonicShortCdPostConditions() or HavocNormalShortCdPostConditions()
}

AddFunction HavocDefaultCdActions
{
 #variable,name=blade_dance,value=talent.first_blood.enabled|set_bonus.tier20_4pc|spell_targets.blade_dance1>=(3-talent.trail_of_ruin.enabled)
 #variable,name=waiting_for_nemesis,value=!(!talent.nemesis.enabled|cooldown.nemesis.ready|cooldown.nemesis.remains>target.time_to_die|cooldown.nemesis.remains>60)
 #variable,name=pooling_for_meta,value=!talent.demonic.enabled&cooldown.metamorphosis.remains<6&fury.deficit>30&(!variable.waiting_for_nemesis|cooldown.nemesis.remains<10)
 #variable,name=pooling_for_blade_dance,value=variable.blade_dance&(fury<75-talent.first_blood.enabled*20)
 #variable,name=waiting_for_dark_slash,value=talent.dark_slash.enabled&!variable.pooling_for_blade_dance&!variable.pooling_for_meta&cooldown.dark_slash.up
 #variable,name=waiting_for_momentum,value=talent.momentum.enabled&!buff.momentum.up
 #disrupt
 HavocInterruptActions()
 #call_action_list,name=cooldown,if=gcd.remains=0
 if not GCDRemaining() > 0 HavocCooldownCdActions()

 unless not GCDRemaining() > 0 and HavocCooldownCdPostConditions() or FuryDeficit() >= 35 and Spell(pick_up_fragment)
 {
  #call_action_list,name=dark_slash,if=talent.dark_slash.enabled&(variable.waiting_for_dark_slash|debuff.dark_slash.up)
  if Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } HavocDarkSlashCdActions()

  unless Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } and HavocDarkSlashCdPostConditions()
  {
   #run_action_list,name=demonic,if=talent.demonic.enabled
   if Talent(demonic_talent) HavocDemonicCdActions()

   unless Talent(demonic_talent) and HavocDemonicCdPostConditions()
   {
    #run_action_list,name=normal
    HavocNormalCdActions()
   }
  }
 }
}

AddFunction HavocDefaultCdPostConditions
{
 not GCDRemaining() > 0 and HavocCooldownCdPostConditions() or FuryDeficit() >= 35 and Spell(pick_up_fragment) or Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } and HavocDarkSlashCdPostConditions() or Talent(demonic_talent) and HavocDemonicCdPostConditions() or HavocNormalCdPostConditions()
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
 #metamorphosis,if=!(talent.demonic.enabled|variable.pooling_for_meta|variable.waiting_for_nemesis)|target.time_to_die<25
 if { not { Talent(demonic_talent) or pooling_for_meta() or waiting_for_nemesis() } or target.TimeToDie() < 25 } and { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } Spell(metamorphosis_havoc)
 #metamorphosis,if=talent.demonic.enabled&buff.metamorphosis.up
 if Talent(demonic_talent) and BuffPresent(metamorphosis_havoc_buff) and { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } Spell(metamorphosis_havoc)
 #nemesis,target_if=min:target.time_to_die,if=raid_event.adds.exists&debuff.nemesis.down&(active_enemies>desired_targets|raid_event.adds.in>60)
 if False(raid_event_adds_exists) and target.DebuffExpires(nemesis_debuff) and { Enemies() > Enemies(tagged=1) or 600 > 60 } Spell(nemesis)
 #nemesis,if=!raid_event.adds.exists
 if not False(raid_event_adds_exists) Spell(nemesis)
 #potion,if=buff.metamorphosis.remains>25|target.time_to_die<60
 if { BuffRemaining(metamorphosis_havoc_buff) > 25 or target.TimeToDie() < 60 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
}

AddFunction HavocCooldownCdPostConditions
{
}

### actions.dark_slash

AddFunction HavocDarkSlashMainActions
{
 #dark_slash,if=fury>=80&(!variable.blade_dance|!cooldown.blade_dance.ready)
 if Fury() >= 80 and { not blade_dance() or not SpellCooldown(blade_dance) == 0 } Spell(dark_slash)
 #annihilation,if=debuff.dark_slash.up
 if target.DebuffPresent(dark_slash_debuff) Spell(annihilation)
 #chaos_strike,if=debuff.dark_slash.up
 if target.DebuffPresent(dark_slash_debuff) Spell(chaos_strike)
}

AddFunction HavocDarkSlashMainPostConditions
{
}

AddFunction HavocDarkSlashShortCdActions
{
}

AddFunction HavocDarkSlashShortCdPostConditions
{
 Fury() >= 80 and { not blade_dance() or not SpellCooldown(blade_dance) == 0 } and Spell(dark_slash) or target.DebuffPresent(dark_slash_debuff) and Spell(annihilation) or target.DebuffPresent(dark_slash_debuff) and Spell(chaos_strike)
}

AddFunction HavocDarkSlashCdActions
{
}

AddFunction HavocDarkSlashCdPostConditions
{
 Fury() >= 80 and { not blade_dance() or not SpellCooldown(blade_dance) == 0 } and Spell(dark_slash) or target.DebuffPresent(dark_slash_debuff) and Spell(annihilation) or target.DebuffPresent(dark_slash_debuff) and Spell(chaos_strike)
}

### actions.demonic

AddFunction HavocDemonicMainActions
{
 #fel_barrage,if=active_enemies>desired_targets|raid_event.adds.in>30
 if Enemies() > Enemies(tagged=1) or 600 > 30 Spell(fel_barrage)
 #death_sweep,if=variable.blade_dance
 if blade_dance() Spell(death_sweep)
 #blade_dance,if=variable.blade_dance&cooldown.eye_beam.remains>5&!cooldown.metamorphosis.ready
 if blade_dance() and SpellCooldown(eye_beam) > 5 and not { { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } and SpellCooldown(metamorphosis_havoc) == 0 } Spell(blade_dance)
 #felblade,if=fury<40|(buff.metamorphosis.down&fury.deficit>=40)
 if Fury() < 40 or BuffExpires(metamorphosis_havoc_buff) and FuryDeficit() >= 40 Spell(felblade)
 #annihilation,if=(talent.blind_fury.enabled|fury.deficit<30|buff.metamorphosis.remains<5)&!variable.pooling_for_blade_dance
 if { Talent(blind_fury_talent) or FuryDeficit() < 30 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() Spell(annihilation)
 #chaos_strike,if=(talent.blind_fury.enabled|fury.deficit<30)&!variable.pooling_for_meta&!variable.pooling_for_blade_dance
 if { Talent(blind_fury_talent) or FuryDeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() Spell(chaos_strike)
 #fel_rush,if=talent.demon_blades.enabled&!cooldown.eye_beam.ready&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
 if Talent(demon_blades_talent) and not SpellCooldown(eye_beam) == 0 and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
 #demons_bite
 Spell(demons_bite)
 #throw_glaive,if=buff.out_of_range.up
 if not target.InRange() Spell(throw_glaive_havoc)
 #fel_rush,if=movement.distance>15|buff.out_of_range.up
 if { target.Distance() > 15 or not target.InRange() } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
 #vengeful_retreat,if=movement.distance>15
 if target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) Spell(vengeful_retreat)
 #throw_glaive,if=talent.demon_blades.enabled
 if Talent(demon_blades_talent) Spell(throw_glaive_havoc)
}

AddFunction HavocDemonicMainPostConditions
{
}

AddFunction HavocDemonicShortCdActions
{
 unless { Enemies() > Enemies(tagged=1) or 600 > 30 } and Spell(fel_barrage) or blade_dance() and Spell(death_sweep) or blade_dance() and SpellCooldown(eye_beam) > 5 and not { { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } and SpellCooldown(metamorphosis_havoc) == 0 } and Spell(blade_dance)
 {
  #immolation_aura
  Spell(immolation_aura_havoc)

  unless { Fury() < 40 or BuffExpires(metamorphosis_havoc_buff) and FuryDeficit() >= 40 } and Spell(felblade)
  {
   #eye_beam,if=(!talent.blind_fury.enabled|fury.deficit>=70)&(!buff.metamorphosis.extended_by_demonic|(set_bonus.tier21_4pc&buff.metamorphosis.remains>16))
   if { not Talent(blind_fury_talent) or FuryDeficit() >= 70 } and { not { not BuffExpires(extended_by_demonic_buff) } or ArmorSetBonus(T21 4) and BuffRemaining(metamorphosis_havoc_buff) > 16 } Spell(eye_beam)
  }
 }
}

AddFunction HavocDemonicShortCdPostConditions
{
 { Enemies() > Enemies(tagged=1) or 600 > 30 } and Spell(fel_barrage) or blade_dance() and Spell(death_sweep) or blade_dance() and SpellCooldown(eye_beam) > 5 and not { { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } and SpellCooldown(metamorphosis_havoc) == 0 } and Spell(blade_dance) or { Fury() < 40 or BuffExpires(metamorphosis_havoc_buff) and FuryDeficit() >= 40 } and Spell(felblade) or { Talent(blind_fury_talent) or FuryDeficit() < 30 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and Spell(annihilation) or { Talent(blind_fury_talent) or FuryDeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and Spell(chaos_strike) or Talent(demon_blades_talent) and not SpellCooldown(eye_beam) == 0 and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Spell(demons_bite) or not target.InRange() and Spell(throw_glaive_havoc) or { target.Distance() > 15 or not target.InRange() } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or Talent(demon_blades_talent) and Spell(throw_glaive_havoc)
}

AddFunction HavocDemonicCdActions
{
}

AddFunction HavocDemonicCdPostConditions
{
 { Enemies() > Enemies(tagged=1) or 600 > 30 } and Spell(fel_barrage) or blade_dance() and Spell(death_sweep) or blade_dance() and SpellCooldown(eye_beam) > 5 and not { { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } and SpellCooldown(metamorphosis_havoc) == 0 } and Spell(blade_dance) or Spell(immolation_aura_havoc) or { Fury() < 40 or BuffExpires(metamorphosis_havoc_buff) and FuryDeficit() >= 40 } and Spell(felblade) or { not Talent(blind_fury_talent) or FuryDeficit() >= 70 } and { not { not BuffExpires(extended_by_demonic_buff) } or ArmorSetBonus(T21 4) and BuffRemaining(metamorphosis_havoc_buff) > 16 } and Spell(eye_beam) or { Talent(blind_fury_talent) or FuryDeficit() < 30 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and Spell(annihilation) or { Talent(blind_fury_talent) or FuryDeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and Spell(chaos_strike) or Talent(demon_blades_talent) and not SpellCooldown(eye_beam) == 0 and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Spell(demons_bite) or not target.InRange() and Spell(throw_glaive_havoc) or { target.Distance() > 15 or not target.InRange() } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or Talent(demon_blades_talent) and Spell(throw_glaive_havoc)
}

### actions.normal

AddFunction HavocNormalMainActions
{
 #vengeful_retreat,if=talent.momentum.enabled&buff.prepared.down
 if Talent(momentum_talent) and BuffExpires(prepared_buff) and CheckBoxOn(opt_vengeful_retreat) Spell(vengeful_retreat)
 #fel_rush,if=(variable.waiting_for_momentum|talent.fel_mastery.enabled)&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
 if { waiting_for_momentum() or Talent(fel_mastery_talent) } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
 #fel_barrage,if=!variable.waiting_for_momentum&(active_enemies>desired_targets|raid_event.adds.in>30)
 if not waiting_for_momentum() and { Enemies() > Enemies(tagged=1) or 600 > 30 } Spell(fel_barrage)
 #death_sweep,if=variable.blade_dance
 if blade_dance() Spell(death_sweep)
 #blade_dance,if=variable.blade_dance
 if blade_dance() Spell(blade_dance)
 #felblade,if=fury.deficit>=40
 if FuryDeficit() >= 40 Spell(felblade)
 #annihilation,if=(talent.demon_blades.enabled|!variable.waiting_for_momentum|fury.deficit<30|buff.metamorphosis.remains<5)&!variable.pooling_for_blade_dance&!variable.waiting_for_dark_slash
 if { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and not waiting_for_dark_slash() Spell(annihilation)
 #chaos_strike,if=(talent.demon_blades.enabled|!variable.waiting_for_momentum|fury.deficit<30)&!variable.pooling_for_meta&!variable.pooling_for_blade_dance&!variable.waiting_for_dark_slash
 if { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and not waiting_for_dark_slash() Spell(chaos_strike)
 #demons_bite
 Spell(demons_bite)
 #fel_rush,if=!talent.momentum.enabled&raid_event.movement.in>charges*10&talent.demon_blades.enabled
 if not Talent(momentum_talent) and 600 > Charges(fel_rush) * 10 and Talent(demon_blades_talent) and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
 #felblade,if=movement.distance>15|buff.out_of_range.up
 if target.Distance() > 15 or not target.InRange() Spell(felblade)
 #fel_rush,if=movement.distance>15|(buff.out_of_range.up&!talent.momentum.enabled)
 if { target.Distance() > 15 or not target.InRange() and not Talent(momentum_talent) } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
 #vengeful_retreat,if=movement.distance>15
 if target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) Spell(vengeful_retreat)
 #throw_glaive,if=talent.demon_blades.enabled
 if Talent(demon_blades_talent) Spell(throw_glaive_havoc)
}

AddFunction HavocNormalMainPostConditions
{
}

AddFunction HavocNormalShortCdActions
{
 unless Talent(momentum_talent) and BuffExpires(prepared_buff) and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or { waiting_for_momentum() or Talent(fel_mastery_talent) } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or not waiting_for_momentum() and { Enemies() > Enemies(tagged=1) or 600 > 30 } and Spell(fel_barrage)
 {
  #immolation_aura
  Spell(immolation_aura_havoc)
  #eye_beam,if=active_enemies>1&(!raid_event.adds.exists|raid_event.adds.up)&!variable.waiting_for_momentum
  if Enemies() > 1 and { not False(raid_event_adds_exists) or False(raid_event_adds_exists) } and not waiting_for_momentum() Spell(eye_beam)

  unless blade_dance() and Spell(death_sweep) or blade_dance() and Spell(blade_dance) or FuryDeficit() >= 40 and Spell(felblade)
  {
   #eye_beam,if=!talent.blind_fury.enabled&!variable.waiting_for_dark_slash&raid_event.adds.in>cooldown
   if not Talent(blind_fury_talent) and not waiting_for_dark_slash() and 600 > SpellCooldown(eye_beam) Spell(eye_beam)

   unless { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and not waiting_for_dark_slash() and Spell(annihilation) or { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and not waiting_for_dark_slash() and Spell(chaos_strike)
   {
    #eye_beam,if=talent.blind_fury.enabled&raid_event.adds.in>cooldown
    if Talent(blind_fury_talent) and 600 > SpellCooldown(eye_beam) Spell(eye_beam)
   }
  }
 }
}

AddFunction HavocNormalShortCdPostConditions
{
 Talent(momentum_talent) and BuffExpires(prepared_buff) and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or { waiting_for_momentum() or Talent(fel_mastery_talent) } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or not waiting_for_momentum() and { Enemies() > Enemies(tagged=1) or 600 > 30 } and Spell(fel_barrage) or blade_dance() and Spell(death_sweep) or blade_dance() and Spell(blade_dance) or FuryDeficit() >= 40 and Spell(felblade) or { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and not waiting_for_dark_slash() and Spell(annihilation) or { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and not waiting_for_dark_slash() and Spell(chaos_strike) or Spell(demons_bite) or not Talent(momentum_talent) and 600 > Charges(fel_rush) * 10 and Talent(demon_blades_talent) and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or { target.Distance() > 15 or not target.InRange() } and Spell(felblade) or { target.Distance() > 15 or not target.InRange() and not Talent(momentum_talent) } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or Talent(demon_blades_talent) and Spell(throw_glaive_havoc)
}

AddFunction HavocNormalCdActions
{
}

AddFunction HavocNormalCdPostConditions
{
 Talent(momentum_talent) and BuffExpires(prepared_buff) and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or { waiting_for_momentum() or Talent(fel_mastery_talent) } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or not waiting_for_momentum() and { Enemies() > Enemies(tagged=1) or 600 > 30 } and Spell(fel_barrage) or Spell(immolation_aura_havoc) or Enemies() > 1 and { not False(raid_event_adds_exists) or False(raid_event_adds_exists) } and not waiting_for_momentum() and Spell(eye_beam) or blade_dance() and Spell(death_sweep) or blade_dance() and Spell(blade_dance) or FuryDeficit() >= 40 and Spell(felblade) or not Talent(blind_fury_talent) and not waiting_for_dark_slash() and 600 > SpellCooldown(eye_beam) and Spell(eye_beam) or { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and not waiting_for_dark_slash() and Spell(annihilation) or { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and not waiting_for_dark_slash() and Spell(chaos_strike) or Talent(blind_fury_talent) and 600 > SpellCooldown(eye_beam) and Spell(eye_beam) or Spell(demons_bite) or not Talent(momentum_talent) and 600 > Charges(fel_rush) * 10 and Talent(demon_blades_talent) and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or { target.Distance() > 15 or not target.InRange() } and Spell(felblade) or { target.Distance() > 15 or not target.InRange() and not Talent(momentum_talent) } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or Talent(demon_blades_talent) and Spell(throw_glaive_havoc)
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
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 #metamorphosis
 if not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() Spell(metamorphosis_havoc)
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
# first_blood_talent
# trail_of_ruin_talent
# nemesis_talent
# nemesis
# demonic_talent
# metamorphosis_havoc
# dark_slash_talent
# dark_slash
# momentum_talent
# momentum_buff
# pick_up_fragment
# dark_slash_debuff
# metamorphosis_havoc_buff
# nemesis_debuff
# prolonged_power_potion
# blade_dance
# annihilation
# chaos_strike
# fel_barrage
# death_sweep
# eye_beam
# immolation_aura_havoc
# felblade
# blind_fury_talent
# fel_rush
# demon_blades_talent
# demons_bite
# throw_glaive_havoc
# vengeful_retreat
# prepared_buff
# fel_mastery_talent
# disrupt
# fel_eruption
# arcane_torrent_dh
# chaos_nova
# imprison

]]
    OvaleScripts:RegisterScript("DEMONHUNTER", "havoc", name, desc, code, "script")
end
do
    local name = "sc_demon_hunter_vengeance_t21"
    local desc = "[8.0] Simulationcraft: Demon_Hunter_Vengeance_T21"
    local code = [[
# Based on SimulationCraft profile "T21_Demon_Hunter_Vengeance".
#    class=demonhunter
#    spec=vengeance
#    talents=1213121

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
  if target.InRange(disrupt) and target.IsInterruptible() Spell(disrupt)
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
 #call_action_list,name=brand,if=talent.charred_flesh.enabled
 if Talent(charred_flesh_talent) VengeanceBrandMainActions()

 unless Talent(charred_flesh_talent) and VengeanceBrandMainPostConditions()
 {
  #call_action_list,name=defensives
  VengeanceDefensivesMainActions()

  unless VengeanceDefensivesMainPostConditions()
  {
   #call_action_list,name=normal
   VengeanceNormalMainActions()
  }
 }
}

AddFunction VengeanceDefaultMainPostConditions
{
 Talent(charred_flesh_talent) and VengeanceBrandMainPostConditions() or VengeanceDefensivesMainPostConditions() or VengeanceNormalMainPostConditions()
}

AddFunction VengeanceDefaultShortCdActions
{
 #auto_attack
 VengeanceGetInMeleeRange()
 #call_action_list,name=brand,if=talent.charred_flesh.enabled
 if Talent(charred_flesh_talent) VengeanceBrandShortCdActions()

 unless Talent(charred_flesh_talent) and VengeanceBrandShortCdPostConditions()
 {
  #call_action_list,name=defensives
  VengeanceDefensivesShortCdActions()

  unless VengeanceDefensivesShortCdPostConditions()
  {
   #call_action_list,name=normal
   VengeanceNormalShortCdActions()
  }
 }
}

AddFunction VengeanceDefaultShortCdPostConditions
{
 Talent(charred_flesh_talent) and VengeanceBrandShortCdPostConditions() or VengeanceDefensivesShortCdPostConditions() or VengeanceNormalShortCdPostConditions()
}

AddFunction VengeanceDefaultCdActions
{
 #disrupt
 VengeanceInterruptActions()
 #use_item,slot=trinket1
 VengeanceUseItemActions()
 #call_action_list,name=brand,if=talent.charred_flesh.enabled
 if Talent(charred_flesh_talent) VengeanceBrandCdActions()

 unless Talent(charred_flesh_talent) and VengeanceBrandCdPostConditions()
 {
  #call_action_list,name=defensives
  VengeanceDefensivesCdActions()

  unless VengeanceDefensivesCdPostConditions()
  {
   #call_action_list,name=normal
   VengeanceNormalCdActions()
  }
 }
}

AddFunction VengeanceDefaultCdPostConditions
{
 Talent(charred_flesh_talent) and VengeanceBrandCdPostConditions() or VengeanceDefensivesCdPostConditions() or VengeanceNormalCdPostConditions()
}

### actions.brand

AddFunction VengeanceBrandMainActions
{
 #sigil_of_flame,if=cooldown.fiery_brand.remains<2
 if SpellCooldown(fiery_brand) < 2 Spell(sigil_of_flame)
 #infernal_strike,if=cooldown.fiery_brand.remains=0
 if not SpellCooldown(fiery_brand) > 0 Spell(infernal_strike)
 #immolation_aura,if=dot.fiery_brand.ticking
 if target.DebuffPresent(fiery_brand_debuff) Spell(immolation_aura)
 #infernal_strike,if=dot.fiery_brand.ticking
 if target.DebuffPresent(fiery_brand_debuff) Spell(infernal_strike)
 #sigil_of_flame,if=dot.fiery_brand.ticking
 if target.DebuffPresent(fiery_brand_debuff) Spell(sigil_of_flame)
}

AddFunction VengeanceBrandMainPostConditions
{
}

AddFunction VengeanceBrandShortCdActions
{
 unless SpellCooldown(fiery_brand) < 2 and Spell(sigil_of_flame) or not SpellCooldown(fiery_brand) > 0 and Spell(infernal_strike)
 {
  #fiery_brand
  Spell(fiery_brand)

  unless target.DebuffPresent(fiery_brand_debuff) and Spell(immolation_aura)
  {
   #fel_devastation,if=dot.fiery_brand.ticking
   if target.DebuffPresent(fiery_brand_debuff) Spell(fel_devastation)
  }
 }
}

AddFunction VengeanceBrandShortCdPostConditions
{
 SpellCooldown(fiery_brand) < 2 and Spell(sigil_of_flame) or not SpellCooldown(fiery_brand) > 0 and Spell(infernal_strike) or target.DebuffPresent(fiery_brand_debuff) and Spell(immolation_aura) or target.DebuffPresent(fiery_brand_debuff) and Spell(infernal_strike) or target.DebuffPresent(fiery_brand_debuff) and Spell(sigil_of_flame)
}

AddFunction VengeanceBrandCdActions
{
}

AddFunction VengeanceBrandCdPostConditions
{
 SpellCooldown(fiery_brand) < 2 and Spell(sigil_of_flame) or not SpellCooldown(fiery_brand) > 0 and Spell(infernal_strike) or target.DebuffPresent(fiery_brand_debuff) and Spell(immolation_aura) or target.DebuffPresent(fiery_brand_debuff) and Spell(fel_devastation) or target.DebuffPresent(fiery_brand_debuff) and Spell(infernal_strike) or target.DebuffPresent(fiery_brand_debuff) and Spell(sigil_of_flame)
}

### actions.defensives

AddFunction VengeanceDefensivesMainActions
{
}

AddFunction VengeanceDefensivesMainPostConditions
{
}

AddFunction VengeanceDefensivesShortCdActions
{
 #demon_spikes
 Spell(demon_spikes)
 #fiery_brand
 Spell(fiery_brand)
}

AddFunction VengeanceDefensivesShortCdPostConditions
{
}

AddFunction VengeanceDefensivesCdActions
{
 #metamorphosis
 Spell(metamorphosis_veng)
}

AddFunction VengeanceDefensivesCdPostConditions
{
}

### actions.normal

AddFunction VengeanceNormalMainActions
{
 #infernal_strike
 Spell(infernal_strike)
 #spirit_bomb,if=soul_fragments>=4
 if SoulFragments() >= 4 Spell(spirit_bomb)
 #immolation_aura,if=pain<=90
 if Pain() <= 90 Spell(immolation_aura)
 #felblade,if=pain<=70
 if Pain() <= 70 Spell(felblade)
 #soul_cleave,if=talent.spirit_bomb.enabled&talent.fracture.enabled&soul_fragments=0&cooldown.fracture.charges_fractional<1.75
 if Talent(spirit_bomb_talent) and Talent(fracture_talent) and SoulFragments() == 0 and SpellCharges(fracture count=0) < 1.75 Spell(soul_cleave)
 #fracture,if=soul_fragments<=3
 if SoulFragments() <= 3 Spell(fracture)
 #soul_cleave,if=!talent.spirit_bomb.enabled
 if not Talent(spirit_bomb_talent) Spell(soul_cleave)
 #soul_cleave,if=talent.spirit_bomb.enabled&soul_fragments=0
 if Talent(spirit_bomb_talent) and SoulFragments() == 0 Spell(soul_cleave)
 #sigil_of_flame
 Spell(sigil_of_flame)
 #shear
 Spell(shear)
 #throw_glaive
 Spell(throw_glaive_veng)
}

AddFunction VengeanceNormalMainPostConditions
{
}

AddFunction VengeanceNormalShortCdActions
{
 unless Spell(infernal_strike) or SoulFragments() >= 4 and Spell(spirit_bomb) or Pain() <= 90 and Spell(immolation_aura) or Pain() <= 70 and Spell(felblade) or Talent(spirit_bomb_talent) and Talent(fracture_talent) and SoulFragments() == 0 and SpellCharges(fracture count=0) < 1.75 and Spell(soul_cleave) or SoulFragments() <= 3 and Spell(fracture)
 {
  #fel_devastation
  Spell(fel_devastation)
 }
}

AddFunction VengeanceNormalShortCdPostConditions
{
 Spell(infernal_strike) or SoulFragments() >= 4 and Spell(spirit_bomb) or Pain() <= 90 and Spell(immolation_aura) or Pain() <= 70 and Spell(felblade) or Talent(spirit_bomb_talent) and Talent(fracture_talent) and SoulFragments() == 0 and SpellCharges(fracture count=0) < 1.75 and Spell(soul_cleave) or SoulFragments() <= 3 and Spell(fracture) or not Talent(spirit_bomb_talent) and Spell(soul_cleave) or Talent(spirit_bomb_talent) and SoulFragments() == 0 and Spell(soul_cleave) or Spell(sigil_of_flame) or Spell(shear) or Spell(throw_glaive_veng)
}

AddFunction VengeanceNormalCdActions
{
}

AddFunction VengeanceNormalCdPostConditions
{
 Spell(infernal_strike) or SoulFragments() >= 4 and Spell(spirit_bomb) or Pain() <= 90 and Spell(immolation_aura) or Pain() <= 70 and Spell(felblade) or Talent(spirit_bomb_talent) and Talent(fracture_talent) and SoulFragments() == 0 and SpellCharges(fracture count=0) < 1.75 and Spell(soul_cleave) or SoulFragments() <= 3 and Spell(fracture) or Spell(fel_devastation) or not Talent(spirit_bomb_talent) and Spell(soul_cleave) or Talent(spirit_bomb_talent) and SoulFragments() == 0 and Spell(soul_cleave) or Spell(sigil_of_flame) or Spell(shear) or Spell(throw_glaive_veng)
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
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
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
# charred_flesh_talent
# sigil_of_flame
# fiery_brand
# infernal_strike
# immolation_aura
# fiery_brand_debuff
# fel_devastation
# demon_spikes
# metamorphosis_veng
# spirit_bomb
# felblade
# soul_cleave
# spirit_bomb_talent
# fracture_talent
# fracture
# shear
# throw_glaive_veng
# unbending_potion
# disrupt
# arcane_torrent_dh
# sigil_of_silence
# sigil_of_misery
# sigil_of_chains
# imprison

]]
    OvaleScripts:RegisterScript("DEMONHUNTER", "vengeance", name, desc, code, "script")
end
