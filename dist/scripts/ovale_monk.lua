local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "icyveins_monk_brewmaster"
    local desc = "[7.3.2] Icy-Veins: Monk Brewmaster"
    local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=brewmaster)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=brewmaster)
AddCheckBox(opt_monk_bm_aoe L(AOE) default specialization=brewmaster)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=brewmaster)

AddFunction BrewmasterHealMe
{
	unless(DebuffPresent(healing_immunity_debuff)) 
	{
		if (HealthPercent() < 35) 
		{
			Spell(healing_elixir)
			Spell(expel_harm)
		}
		if (HealthPercent() <= 100 - (15 * 2.6)) Spell(healing_elixir)
		if (HealthPercent() < 35) UseHealthPotions()
	}
}

AddFunction StaggerPercentage
{
	StaggerRemaining() / MaxHealth() * 100
}

AddFunction BrewmasterRangeCheck
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction BrewMasterIronskinMin
{
	if(DebuffRemaining(any_stagger_debuff) > BaseDuration(ironskin_brew_buff)) BaseDuration(ironskin_brew_buff)
	DebuffRemaining(any_stagger_debuff)
}

AddFunction BrewmasterDefaultShortCDActions
{
	# keep ISB up always when taking dmg
	if BuffRemaining(ironskin_brew_buff) < BrewMasterIronskinMin() Spell(ironskin_brew text=min)
	
	# keep stagger below 100% (or 30% when BOB is up)
	if (StaggerPercentage() >= 100 or (StaggerPercentage() >= 30 and Talent(black_ox_brew_talent) and SpellCooldown(black_ox_brew) <= 0)) Spell(purifying_brew)
	# use black_ox_brew when at 0 charges and low energy (or in an emergency)
	if ((SpellCharges(purifying_brew) == 0) and (Energy() < 40 or StaggerPercentage() >= 60 or BuffRemaining(ironskin_brew_buff) < BrewMasterIronskinMin())) Spell(black_ox_brew)

	# heal mean
	BrewmasterHealMe()
	# range check
	BrewmasterRangeCheck()

	unless StaggerPercentage() > 100 or BrewmasterHealMe()
	{
		# purify heavy stagger when we have enough ISB
		if (StaggerPercentage() >= 60 and (BuffRemaining(ironskin_brew_buff) >= 2*BaseDuration(ironskin_brew_buff))) Spell(purifying_brew)

		# always bank 1 charge (or bank 2 with light_brewing)
		unless (SpellCharges(ironskin_brew count=0) <= SpellData(ironskin_brew charges)-2)
		{
			# never be at (almost) max charges 
			unless (SpellFullRecharge(ironskin_brew) > 3)
			{
				if (BuffRemaining(ironskin_brew_buff) < 2*BaseDuration(ironskin_brew_buff)) Spell(ironskin_brew text=max)
				if (StaggerPercentage() > 30 or Talent(special_delivery_talent)) Spell(purifying_brew text=max)
			}
			
			# keep brew-stache rolling
			if (IncomingDamage(4 physical=1)>0 and HasArtifactTrait(brew_stache_trait) and BuffExpires(brew_stache_buff)) 
			{
				if (BuffRemaining(ironskin_brew_buff) < 2*BaseDuration(ironskin_brew_buff)) Spell(ironskin_brew text=stache)
				if (StaggerPercentage() > 30) Spell(purifying_brew text=stache)
			}
			# purify stagger when talent elusive dance 
			if (Talent(elusive_dance_talent) and BuffExpires(elusive_dance_buff)) Spell(purifying_brew)
		}
	}
}

#
# Single-Target
#

AddFunction BrewmasterDefaultMainActions
{
	if Talent(blackout_combo_talent) BrewmasterBlackoutComboMainActions()
	unless Talent(blackout_combo_talent) 
	{
		Spell(keg_smash)
		Spell(blackout_strike)
		if (target.DebuffPresent(keg_smash_debuff)) Spell(breath_of_fire)
		if (BuffRefreshable(rushing_jade_wind_buff)) Spell(rushing_jade_wind)
		if (EnergyDeficit() <= 35 or (Talent(black_ox_talent) and SpellCooldown(black_ox_brew) <= 0)) Spell(tiger_palm)
		Spell(chi_burst)
		Spell(chi_wave)
		Spell(exploding_keg)
	}
}

AddFunction BrewmasterBlackoutComboMainActions
{
	if(not BuffPresent(blackout_combo_buff) or SpellCharges(ironskin_brew) == 0) Spell(keg_smash)
	if(not BuffPresent(blackout_combo_buff)) Spell(blackout_strike)
	if(BuffPresent(blackout_combo_buff)) Spell(tiger_palm)
	
	unless BuffPresent(blackout_combo_buff)
	{
		if target.DebuffPresent(keg_smash_debuff) Spell(breath_of_fire)
		if BuffRefreshable(rushing_jade_wind_buff) Spell(rushing_jade_wind)
		Spell(chi_burst)
		Spell(chi_wave)
		Spell(exploding_keg)
	}
}

#
# AOE
#

AddFunction BrewmasterDefaultAoEActions
{
	if(Talent(blackout_combo_talent) and not BuffPresent(blackout_combo_buff)) Spell(blackout_strike)
	Spell(exploding_keg)
	Spell(keg_smash)
	Spell(chi_burst)
	Spell(chi_wave)
	if (target.DebuffPresent(keg_smash_debuff) and (not HasEquippedItem(salsalabims_lost_tunic) or not BuffPresent(blackout_combo_buff))) Spell(breath_of_fire)
	if (BuffRefreshable(rushing_jade_wind_buff)) Spell(rushing_jade_wind)
	if (EnergyDeficit() <= 35 or (Talent(black_ox_talent) and SpellCooldown(black_ox_brew) <= 0)) Spell(tiger_palm)
	if (not BuffPresent(blackout_combo_buff)) Spell(blackout_strike)	
}

AddFunction BrewmasterBlackoutComboAoEActions
{
	if(not BuffPresent(blackout_combo_buff)) Spell(blackout_strike)
	if(BuffPresent(blackout_combo_buff)) 
	{
		Spell(keg_smash)
		Spell(breath_of_fire)
		Spell(tiger_palm)
	}
	
	unless (BuffPresent(blackout_combo_buff)) 
	{
		Spell(exploding_keg)
		Spell(rushing_jade_wind)
		Spell(chi_burst)
		Spell(chi_wave)
		if EnergyDeficit() <= 35 Spell(tiger_palm)
	}
}

AddFunction BrewmasterDefaultCdActions 
{
	BrewmasterInterruptActions()
	if not PetPresent(name=Niuzao) Spell(invoke_niuzao)
	if (HasEquippedItem(firestone_walkers)) Spell(fortifying_brew)
	if (HasEquippedItem(shifting_cosmic_sliver)) Spell(fortifying_brew)
	if (HasEquippedItem(fundamental_observation)) Spell(zen_meditation text=FO)
	Item(Trinket0Slot usable=1 text=13)
	Item(Trinket1Slot usable=1 text=14)
	Spell(fortifying_brew)
	Spell(dampen_harm)
	if CheckBoxOn(opt_use_consumables) Item(unbending_potion usable=1)
	Spell(zen_meditation)
	UseRacialSurvivalActions()
}

AddFunction BrewmasterInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
	{
		if target.InRange(spear_hand_strike) and target.IsInterruptible() Spell(spear_hand_strike)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(leg_sweep)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
		if target.InRange(paralysis) and not target.Classification(worldboss) Spell(paralysis)
	}
}

AddIcon help=shortcd specialization=brewmaster
{
	BrewmasterDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=brewmaster
{
	BrewmasterDefaultMainActions()
}

AddIcon checkbox=opt_monk_bm_aoe help=aoe specialization=brewmaster
{
	BrewmasterDefaultAoEActions()
}

AddIcon help=cd specialization=brewmaster
{
	BrewmasterDefaultCdActions()
}
]]
    OvaleScripts:RegisterScript("MONK", "brewmaster", name, desc, code, "script")
end
do
    local name = "sc_monk_windwalker_pr"
    local desc = "[8.0] Simulationcraft: Monk_Windwalker_PreRaid"
    local code = [[
# Based on SimulationCraft profile "PR_Monk_Windwalker".
#    class=monk
#    spec=windwalker
#    talents=3022032

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=windwalker)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=windwalker)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=windwalker)
AddCheckBox(opt_touch_of_death_on_elite_only L(touch_of_death_on_elite_only) default specialization=windwalker)
AddCheckBox(opt_touch_of_karma SpellName(touch_of_karma) specialization=windwalker)
AddCheckBox(opt_chi_burst SpellName(chi_burst) default specialization=windwalker)
AddCheckBox(opt_storm_earth_and_fire SpellName(storm_earth_and_fire) specialization=windwalker)

AddFunction WindwalkerInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(spear_hand_strike) and target.IsInterruptible() Spell(spear_hand_strike)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(leg_sweep)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(paralysis) and not target.Classification(worldboss) Spell(paralysis)
 }
}

AddFunction WindwalkerUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction WindwalkerGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.default

AddFunction WindwalkerDefaultMainActions
{
 #touch_of_death,if=target.time_to_die<=9
 if target.TimeToDie() <= 9 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } Spell(touch_of_death)
 #call_action_list,name=serenity,if=(talent.serenity.enabled&cooldown.serenity.remains<=0)|buff.serenity.up
 if Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) WindwalkerSerenityMainActions()

 unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and WindwalkerSerenityMainPostConditions()
 {
  #call_action_list,name=sef,if=!talent.serenity.enabled&(buff.storm_earth_and_fire.up|cooldown.storm_earth_and_fire.charges=2)
  if not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } WindwalkerSefMainActions()

  unless not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefMainPostConditions()
  {
   #call_action_list,name=sef,if=(!talent.serenity.enabled&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=25|cooldown.touch_of_death.remains>112
   if not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 WindwalkerSefMainActions()

   unless { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and WindwalkerSefMainPostConditions()
   {
    #call_action_list,name=sef,if=(!talent.serenity.enabled&!equipped.drinking_horn_cover&cooldown.fists_of_fury.remains<=6&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=15|cooldown.touch_of_death.remains>112&cooldown.storm_earth_and_fire.charges=1
    if not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefMainActions()

    unless { not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefMainPostConditions()
    {
     #call_action_list,name=sef,if=(!talent.serenity.enabled&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=25|cooldown.touch_of_death.remains>112&cooldown.storm_earth_and_fire.charges=1
     if not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefMainActions()

     unless { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefMainPostConditions()
     {
      #call_action_list,name=aoe,if=active_enemies>3
      if Enemies() > 3 WindwalkerAoeMainActions()

      unless Enemies() > 3 and WindwalkerAoeMainPostConditions()
      {
       #call_action_list,name=st,if=active_enemies<=3
       if Enemies() <= 3 WindwalkerStMainActions()
      }
     }
    }
   }
  }
 }
}

AddFunction WindwalkerDefaultMainPostConditions
{
 { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and WindwalkerSerenityMainPostConditions() or not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefMainPostConditions() or { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and WindwalkerSefMainPostConditions() or { not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefMainPostConditions() or { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefMainPostConditions() or Enemies() > 3 and WindwalkerAoeMainPostConditions() or Enemies() <= 3 and WindwalkerStMainPostConditions()
}

AddFunction WindwalkerDefaultShortCdActions
{
 #auto_attack
 WindwalkerGetInMeleeRange()

 unless target.TimeToDie() <= 9 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death)
 {
  #call_action_list,name=serenity,if=(talent.serenity.enabled&cooldown.serenity.remains<=0)|buff.serenity.up
  if Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) WindwalkerSerenityShortCdActions()

  unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and WindwalkerSerenityShortCdPostConditions()
  {
   #call_action_list,name=sef,if=!talent.serenity.enabled&(buff.storm_earth_and_fire.up|cooldown.storm_earth_and_fire.charges=2)
   if not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } WindwalkerSefShortCdActions()

   unless not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefShortCdPostConditions()
   {
    #call_action_list,name=sef,if=(!talent.serenity.enabled&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=25|cooldown.touch_of_death.remains>112
    if not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 WindwalkerSefShortCdActions()

    unless { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and WindwalkerSefShortCdPostConditions()
    {
     #call_action_list,name=sef,if=(!talent.serenity.enabled&!equipped.drinking_horn_cover&cooldown.fists_of_fury.remains<=6&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=15|cooldown.touch_of_death.remains>112&cooldown.storm_earth_and_fire.charges=1
     if not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefShortCdActions()

     unless { not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefShortCdPostConditions()
     {
      #call_action_list,name=sef,if=(!talent.serenity.enabled&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=25|cooldown.touch_of_death.remains>112&cooldown.storm_earth_and_fire.charges=1
      if not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefShortCdActions()

      unless { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefShortCdPostConditions()
      {
       #call_action_list,name=aoe,if=active_enemies>3
       if Enemies() > 3 WindwalkerAoeShortCdActions()

       unless Enemies() > 3 and WindwalkerAoeShortCdPostConditions()
       {
        #call_action_list,name=st,if=active_enemies<=3
        if Enemies() <= 3 WindwalkerStShortCdActions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction WindwalkerDefaultShortCdPostConditions
{
 target.TimeToDie() <= 9 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death) or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and WindwalkerSerenityShortCdPostConditions() or not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefShortCdPostConditions() or { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and WindwalkerSefShortCdPostConditions() or { not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefShortCdPostConditions() or { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefShortCdPostConditions() or Enemies() > 3 and WindwalkerAoeShortCdPostConditions() or Enemies() <= 3 and WindwalkerStShortCdPostConditions()
}

AddFunction WindwalkerDefaultCdActions
{
 #spear_hand_strike,if=target.debuff.casting.react
 if target.IsInterruptible() WindwalkerInterruptActions()
 #touch_of_karma,interval=90,pct_health=0.5,if=!talent.Good_Karma.enabled,interval=90,pct_health=0.5
 if not Talent(good_karma_talent) and CheckBoxOn(opt_touch_of_karma) Spell(touch_of_karma)
 #touch_of_karma,interval=90,pct_health=1.0
 if CheckBoxOn(opt_touch_of_karma) Spell(touch_of_karma)
 #potion,if=buff.serenity.up|buff.storm_earth_and_fire.up|(!talent.serenity.enabled&trinket.proc.agility.react)|buff.bloodlust.react|target.time_to_die<=60
 if { BuffPresent(serenity_buff) or BuffPresent(storm_earth_and_fire_buff) or not Talent(serenity_talent) and BuffPresent(trinket_proc_agility_buff) or BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)

 unless target.TimeToDie() <= 9 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death)
 {
  #call_action_list,name=serenity,if=(talent.serenity.enabled&cooldown.serenity.remains<=0)|buff.serenity.up
  if Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) WindwalkerSerenityCdActions()

  unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and WindwalkerSerenityCdPostConditions()
  {
   #call_action_list,name=sef,if=!talent.serenity.enabled&(buff.storm_earth_and_fire.up|cooldown.storm_earth_and_fire.charges=2)
   if not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } WindwalkerSefCdActions()

   unless not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefCdPostConditions()
   {
    #call_action_list,name=sef,if=(!talent.serenity.enabled&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=25|cooldown.touch_of_death.remains>112
    if not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 WindwalkerSefCdActions()

    unless { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and WindwalkerSefCdPostConditions()
    {
     #call_action_list,name=sef,if=(!talent.serenity.enabled&!equipped.drinking_horn_cover&cooldown.fists_of_fury.remains<=6&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=15|cooldown.touch_of_death.remains>112&cooldown.storm_earth_and_fire.charges=1
     if not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefCdActions()

     unless { not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefCdPostConditions()
     {
      #call_action_list,name=sef,if=(!talent.serenity.enabled&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=25|cooldown.touch_of_death.remains>112&cooldown.storm_earth_and_fire.charges=1
      if not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefCdActions()

      unless { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefCdPostConditions()
      {
       #call_action_list,name=aoe,if=active_enemies>3
       if Enemies() > 3 WindwalkerAoeCdActions()

       unless Enemies() > 3 and WindwalkerAoeCdPostConditions()
       {
        #call_action_list,name=st,if=active_enemies<=3
        if Enemies() <= 3 WindwalkerStCdActions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction WindwalkerDefaultCdPostConditions
{
 target.TimeToDie() <= 9 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death) or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and WindwalkerSerenityCdPostConditions() or not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefCdPostConditions() or { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and WindwalkerSefCdPostConditions() or { not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefCdPostConditions() or { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefCdPostConditions() or Enemies() > 3 and WindwalkerAoeCdPostConditions() or Enemies() <= 3 and WindwalkerStCdPostConditions()
}

### actions.aoe

AddFunction WindwalkerAoeMainActions
{
 #call_action_list,name=cd
 WindwalkerCdMainActions()

 unless WindwalkerCdMainPostConditions()
 {
  #energizing_elixir,if=!prev_gcd.1.tiger_palm&chi<=1&(cooldown.rising_sun_kick.remains=0|(talent.fist_of_the_white_tiger.enabled&cooldown.fist_of_the_white_tiger.remains=0)|energy<50)
  if not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and { not SpellCooldown(rising_sun_kick) > 0 or Talent(fist_of_the_white_tiger_talent) and not SpellCooldown(fist_of_the_white_tiger) > 0 or Energy() < 50 } Spell(energizing_elixir)
  #fists_of_fury,if=talent.serenity.enabled&!equipped.drinking_horn_cover&cooldown.serenity.remains>=5&energy.time_to_max>2
  if Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(serenity) >= 5 and TimeToMaxEnergy() > 2 Spell(fists_of_fury)
  #fists_of_fury,if=talent.serenity.enabled&equipped.drinking_horn_cover&(cooldown.serenity.remains>=15|cooldown.serenity.remains<=4)&energy.time_to_max>2
  if Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover_item) and { SpellCooldown(serenity) >= 15 or SpellCooldown(serenity) <= 4 } and TimeToMaxEnergy() > 2 Spell(fists_of_fury)
  #fists_of_fury,if=!talent.serenity.enabled&energy.time_to_max>2
  if not Talent(serenity_talent) and TimeToMaxEnergy() > 2 Spell(fists_of_fury)
  #fists_of_fury,if=cooldown.rising_sun_kick.remains>=3.5&chi<=5
  if SpellCooldown(rising_sun_kick) >= 3.5 and Chi() <= 5 Spell(fists_of_fury)
  #whirling_dragon_punch
  if SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 Spell(whirling_dragon_punch)
  #rising_sun_kick,target_if=cooldown.whirling_dragon_punch.remains>=gcd&!prev_gcd.1.rising_sun_kick&cooldown.fists_of_fury.remains>gcd
  if SpellCooldown(whirling_dragon_punch) >= GCD() and not PreviousGCDSpell(rising_sun_kick) and SpellCooldown(fists_of_fury) > GCD() Spell(rising_sun_kick)
  #chi_burst,if=chi<=3&(cooldown.rising_sun_kick.remains>=5|cooldown.whirling_dragon_punch.remains>=5)&energy.time_to_max>1
  if Chi() <= 3 and { SpellCooldown(rising_sun_kick) >= 5 or SpellCooldown(whirling_dragon_punch) >= 5 } and TimeToMaxEnergy() > 1 and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
  #chi_burst
  if CheckBoxOn(opt_chi_burst) Spell(chi_burst)
  #spinning_crane_kick,if=(active_enemies>=3|(buff.bok_proc.up&chi.max-chi>=0))&!prev_gcd.1.spinning_crane_kick&set_bonus.tier21_4pc
  if { Enemies() >= 3 or BuffPresent(blackout_kick_buff) and MaxChi() - Chi() >= 0 } and not PreviousGCDSpell(spinning_crane_kick) and ArmorSetBonus(T21 4) Spell(spinning_crane_kick)
  #spinning_crane_kick,if=active_enemies>=3&!prev_gcd.1.spinning_crane_kick
  if Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) Spell(spinning_crane_kick)
  #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&chi.max-chi>=1&set_bonus.tier21_4pc&(!set_bonus.tier19_2pc|talent.serenity.enabled)
  if not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and { not ArmorSetBonus(T19 2) or Talent(serenity_talent) } Spell(blackout_kick)
  #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(chi>1|buff.bok_proc.up|(talent.energizing_elixir.enabled&cooldown.energizing_elixir.remains<cooldown.fists_of_fury.remains))&((cooldown.rising_sun_kick.remains>1&(!talent.fist_of_the_white_tiger.enabled|cooldown.fist_of_the_white_tiger.remains>1)|chi>4)&(cooldown.fists_of_fury.remains>1|chi>2)|prev_gcd.1.tiger_palm)&!prev_gcd.1.blackout_kick
  if { Chi() > 1 or BuffPresent(blackout_kick_buff) or Talent(energizing_elixir_talent) and SpellCooldown(energizing_elixir) < SpellCooldown(fists_of_fury) } and { { SpellCooldown(rising_sun_kick) > 1 and { not Talent(fist_of_the_white_tiger_talent) or SpellCooldown(fist_of_the_white_tiger) > 1 } or Chi() > 4 } and { SpellCooldown(fists_of_fury) > 1 or Chi() > 2 } or PreviousGCDSpell(tiger_palm) } and not PreviousGCDSpell(blackout_kick) Spell(blackout_kick)
  #crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=19&energy.time_to_max>3
  if HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 Spell(crackling_jade_lightning)
  #crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=14&cooldown.serenity.remains<13&talent.serenity.enabled&energy.time_to_max>3
  if HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 Spell(crackling_jade_lightning)
  #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&chi.max-chi>=1&set_bonus.tier21_4pc&buff.bok_proc.up
  if not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) Spell(blackout_kick)
  #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&(chi.max-chi>=2|energy.time_to_max<3)
  if not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 3 } Spell(tiger_palm)
  #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&energy.time_to_max<=1&chi.max-chi>=2
  if not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and TimeToMaxEnergy() <= 1 and MaxChi() - Chi() >= 2 Spell(tiger_palm)
  #chi_wave,if=chi<=3&(cooldown.rising_sun_kick.remains>=5|cooldown.whirling_dragon_punch.remains>=5)&energy.time_to_max>1
  if Chi() <= 3 and { SpellCooldown(rising_sun_kick) >= 5 or SpellCooldown(whirling_dragon_punch) >= 5 } and TimeToMaxEnergy() > 1 Spell(chi_wave)
  #chi_wave
  Spell(chi_wave)
 }
}

AddFunction WindwalkerAoeMainPostConditions
{
 WindwalkerCdMainPostConditions()
}

AddFunction WindwalkerAoeShortCdActions
{
 #call_action_list,name=cd
 WindwalkerCdShortCdActions()
}

AddFunction WindwalkerAoeShortCdPostConditions
{
 WindwalkerCdShortCdPostConditions() or not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and { not SpellCooldown(rising_sun_kick) > 0 or Talent(fist_of_the_white_tiger_talent) and not SpellCooldown(fist_of_the_white_tiger) > 0 or Energy() < 50 } and Spell(energizing_elixir) or Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(serenity) >= 5 and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover_item) and { SpellCooldown(serenity) >= 15 or SpellCooldown(serenity) <= 4 } and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or not Talent(serenity_talent) and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or SpellCooldown(rising_sun_kick) >= 3.5 and Chi() <= 5 and Spell(fists_of_fury) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or SpellCooldown(whirling_dragon_punch) >= GCD() and not PreviousGCDSpell(rising_sun_kick) and SpellCooldown(fists_of_fury) > GCD() and Spell(rising_sun_kick) or Chi() <= 3 and { SpellCooldown(rising_sun_kick) >= 5 or SpellCooldown(whirling_dragon_punch) >= 5 } and TimeToMaxEnergy() > 1 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or { Enemies() >= 3 or BuffPresent(blackout_kick_buff) and MaxChi() - Chi() >= 0 } and not PreviousGCDSpell(spinning_crane_kick) and ArmorSetBonus(T21 4) and Spell(spinning_crane_kick) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and { not ArmorSetBonus(T19 2) or Talent(serenity_talent) } and Spell(blackout_kick) or { Chi() > 1 or BuffPresent(blackout_kick_buff) or Talent(energizing_elixir_talent) and SpellCooldown(energizing_elixir) < SpellCooldown(fists_of_fury) } and { { SpellCooldown(rising_sun_kick) > 1 and { not Talent(fist_of_the_white_tiger_talent) or SpellCooldown(fist_of_the_white_tiger) > 1 } or Chi() > 4 } and { SpellCooldown(fists_of_fury) > 1 or Chi() > 2 } or PreviousGCDSpell(tiger_palm) } and not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) and Spell(blackout_kick) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 3 } and Spell(tiger_palm) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and TimeToMaxEnergy() <= 1 and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or Chi() <= 3 and { SpellCooldown(rising_sun_kick) >= 5 or SpellCooldown(whirling_dragon_punch) >= 5 } and TimeToMaxEnergy() > 1 and Spell(chi_wave) or Spell(chi_wave)
}

AddFunction WindwalkerAoeCdActions
{
 #call_action_list,name=cd
 WindwalkerCdCdActions()

 unless WindwalkerCdCdPostConditions() or not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and { not SpellCooldown(rising_sun_kick) > 0 or Talent(fist_of_the_white_tiger_talent) and not SpellCooldown(fist_of_the_white_tiger) > 0 or Energy() < 50 } and Spell(energizing_elixir)
 {
  #arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
  if MaxChi() - Chi() >= 1 and TimeToMaxEnergy() >= 0.5 Spell(arcane_torrent_chi)
 }
}

AddFunction WindwalkerAoeCdPostConditions
{
 WindwalkerCdCdPostConditions() or not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and { not SpellCooldown(rising_sun_kick) > 0 or Talent(fist_of_the_white_tiger_talent) and not SpellCooldown(fist_of_the_white_tiger) > 0 or Energy() < 50 } and Spell(energizing_elixir) or Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(serenity) >= 5 and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover_item) and { SpellCooldown(serenity) >= 15 or SpellCooldown(serenity) <= 4 } and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or not Talent(serenity_talent) and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or SpellCooldown(rising_sun_kick) >= 3.5 and Chi() <= 5 and Spell(fists_of_fury) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or SpellCooldown(whirling_dragon_punch) >= GCD() and not PreviousGCDSpell(rising_sun_kick) and SpellCooldown(fists_of_fury) > GCD() and Spell(rising_sun_kick) or Chi() <= 3 and { SpellCooldown(rising_sun_kick) >= 5 or SpellCooldown(whirling_dragon_punch) >= 5 } and TimeToMaxEnergy() > 1 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or { Enemies() >= 3 or BuffPresent(blackout_kick_buff) and MaxChi() - Chi() >= 0 } and not PreviousGCDSpell(spinning_crane_kick) and ArmorSetBonus(T21 4) and Spell(spinning_crane_kick) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and { not ArmorSetBonus(T19 2) or Talent(serenity_talent) } and Spell(blackout_kick) or { Chi() > 1 or BuffPresent(blackout_kick_buff) or Talent(energizing_elixir_talent) and SpellCooldown(energizing_elixir) < SpellCooldown(fists_of_fury) } and { { SpellCooldown(rising_sun_kick) > 1 and { not Talent(fist_of_the_white_tiger_talent) or SpellCooldown(fist_of_the_white_tiger) > 1 } or Chi() > 4 } and { SpellCooldown(fists_of_fury) > 1 or Chi() > 2 } or PreviousGCDSpell(tiger_palm) } and not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) and Spell(blackout_kick) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 3 } and Spell(tiger_palm) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and TimeToMaxEnergy() <= 1 and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or Chi() <= 3 and { SpellCooldown(rising_sun_kick) >= 5 or SpellCooldown(whirling_dragon_punch) >= 5 } and TimeToMaxEnergy() > 1 and Spell(chi_wave) or Spell(chi_wave)
}

### actions.cd

AddFunction WindwalkerCdMainActions
{
 #invoke_xuen_the_white_tiger
 Spell(invoke_xuen_the_white_tiger)
 #touch_of_death,target_if=min:dot.touch_of_death.remains,if=equipped.hidden_masters_forbidden_touch&!prev_gcd.1.touch_of_death
 if HasEquippedItem(hidden_masters_forbidden_touch_item) and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } Spell(touch_of_death)
 #touch_of_death,target_if=min:dot.touch_of_death.remains,if=((talent.serenity.enabled&cooldown.serenity.remains<=1)&cooldown.fists_of_fury.remains<=4)&cooldown.rising_sun_kick.remains<7&!prev_gcd.1.touch_of_death
 if Talent(serenity_talent) and SpellCooldown(serenity) <= 1 and SpellCooldown(fists_of_fury) <= 4 and SpellCooldown(rising_sun_kick) < 7 and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } Spell(touch_of_death)
 #touch_of_death,target_if=min:dot.touch_of_death.remains,if=((!talent.serenity.enabled&cooldown.storm_earth_and_fire.remains<=1)|chi>=2)&cooldown.fists_of_fury.remains<=4&cooldown.rising_sun_kick.remains<7&!prev_gcd.1.touch_of_death
 if { not Talent(serenity_talent) and SpellCooldown(storm_earth_and_fire) <= 1 or Chi() >= 2 } and SpellCooldown(fists_of_fury) <= 4 and SpellCooldown(rising_sun_kick) < 7 and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } Spell(touch_of_death)
}

AddFunction WindwalkerCdMainPostConditions
{
}

AddFunction WindwalkerCdShortCdActions
{
}

AddFunction WindwalkerCdShortCdPostConditions
{
 Spell(invoke_xuen_the_white_tiger) or HasEquippedItem(hidden_masters_forbidden_touch_item) and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death) or Talent(serenity_talent) and SpellCooldown(serenity) <= 1 and SpellCooldown(fists_of_fury) <= 4 and SpellCooldown(rising_sun_kick) < 7 and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death) or { not Talent(serenity_talent) and SpellCooldown(storm_earth_and_fire) <= 1 or Chi() >= 2 } and SpellCooldown(fists_of_fury) <= 4 and SpellCooldown(rising_sun_kick) < 7 and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death)
}

AddFunction WindwalkerCdCdActions
{
 unless Spell(invoke_xuen_the_white_tiger)
 {
  #use_item,name=lustrous_golden_plumage
  WindwalkerUseItemActions()
  #blood_fury
  Spell(blood_fury_apsp)
  #berserking
  Spell(berserking)
  #arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
  if MaxChi() - Chi() >= 1 and TimeToMaxEnergy() >= 0.5 Spell(arcane_torrent_chi)
  #lights_judgment
  Spell(lights_judgment)
  #fireblood
  Spell(fireblood)
  #ancestral_call
  Spell(ancestral_call)
 }
}

AddFunction WindwalkerCdCdPostConditions
{
 Spell(invoke_xuen_the_white_tiger) or HasEquippedItem(hidden_masters_forbidden_touch_item) and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death) or Talent(serenity_talent) and SpellCooldown(serenity) <= 1 and SpellCooldown(fists_of_fury) <= 4 and SpellCooldown(rising_sun_kick) < 7 and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death) or { not Talent(serenity_talent) and SpellCooldown(storm_earth_and_fire) <= 1 or Chi() >= 2 } and SpellCooldown(fists_of_fury) <= 4 and SpellCooldown(rising_sun_kick) < 7 and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death)
}

### actions.precombat

AddFunction WindwalkerPrecombatMainActions
{
 #chi_burst
 if CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #chi_wave
 Spell(chi_wave)
}

AddFunction WindwalkerPrecombatMainPostConditions
{
}

AddFunction WindwalkerPrecombatShortCdActions
{
}

AddFunction WindwalkerPrecombatShortCdPostConditions
{
 CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

AddFunction WindwalkerPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
}

AddFunction WindwalkerPrecombatCdPostConditions
{
 CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

### actions.sef

AddFunction WindwalkerSefMainActions
{
 #tiger_palm,target_if=debuff.mark_of_the_crane.down,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&energy=energy.max&chi<1
 if not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and target.DebuffExpires(mark_of_the_crane_debuff) Spell(tiger_palm)
 #call_action_list,name=cd
 WindwalkerCdMainActions()

 unless WindwalkerCdMainPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3
  if Enemies() > 3 WindwalkerAoeMainActions()

  unless Enemies() > 3 and WindwalkerAoeMainPostConditions()
  {
   #call_action_list,name=st,if=active_enemies<=3
   if Enemies() <= 3 WindwalkerStMainActions()
  }
 }
}

AddFunction WindwalkerSefMainPostConditions
{
 WindwalkerCdMainPostConditions() or Enemies() > 3 and WindwalkerAoeMainPostConditions() or Enemies() <= 3 and WindwalkerStMainPostConditions()
}

AddFunction WindwalkerSefShortCdActions
{
 unless not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and target.DebuffExpires(mark_of_the_crane_debuff) and Spell(tiger_palm)
 {
  #call_action_list,name=cd
  WindwalkerCdShortCdActions()

  unless WindwalkerCdShortCdPostConditions()
  {
   #call_action_list,name=aoe,if=active_enemies>3
   if Enemies() > 3 WindwalkerAoeShortCdActions()

   unless Enemies() > 3 and WindwalkerAoeShortCdPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<=3
    if Enemies() <= 3 WindwalkerStShortCdActions()
   }
  }
 }
}

AddFunction WindwalkerSefShortCdPostConditions
{
 not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and target.DebuffExpires(mark_of_the_crane_debuff) and Spell(tiger_palm) or WindwalkerCdShortCdPostConditions() or Enemies() > 3 and WindwalkerAoeShortCdPostConditions() or Enemies() <= 3 and WindwalkerStShortCdPostConditions()
}

AddFunction WindwalkerSefCdActions
{
 unless not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and target.DebuffExpires(mark_of_the_crane_debuff) and Spell(tiger_palm)
 {
  #call_action_list,name=cd
  WindwalkerCdCdActions()

  unless WindwalkerCdCdPostConditions()
  {
   #storm_earth_and_fire,if=!buff.storm_earth_and_fire.up
   if not BuffPresent(storm_earth_and_fire_buff) and CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff) Spell(storm_earth_and_fire)
   #call_action_list,name=aoe,if=active_enemies>3
   if Enemies() > 3 WindwalkerAoeCdActions()

   unless Enemies() > 3 and WindwalkerAoeCdPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<=3
    if Enemies() <= 3 WindwalkerStCdActions()
   }
  }
 }
}

AddFunction WindwalkerSefCdPostConditions
{
 not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and target.DebuffExpires(mark_of_the_crane_debuff) and Spell(tiger_palm) or WindwalkerCdCdPostConditions() or Enemies() > 3 and WindwalkerAoeCdPostConditions() or Enemies() <= 3 and WindwalkerStCdPostConditions()
}

### actions.serenity

AddFunction WindwalkerSerenityMainActions
{
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&energy=energy.max&chi<1&!buff.serenity.up
 if not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) Spell(tiger_palm)
 #call_action_list,name=cd
 WindwalkerCdMainActions()

 unless WindwalkerCdMainPostConditions()
 {
  #rushing_jade_wind,if=talent.rushing_jade_wind.enabled&!prev_gcd.1.rushing_jade_wind&buff.rushing_jade_wind.down
  if Talent(rushing_jade_wind_talent) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and BuffExpires(rushing_jade_wind_windwalker_buff) Spell(rushing_jade_wind_windwalker)
  #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains
  Spell(rising_sun_kick)
  #fists_of_fury,if=prev_gcd.1.rising_sun_kick&prev_gcd.2.serenity
  if PreviousGCDSpell(rising_sun_kick) and PreviousGCDSpell(serenity count=2) Spell(fists_of_fury)
  #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains
  Spell(rising_sun_kick)
  #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&cooldown.rising_sun_kick.remains>=2&cooldown.fists_of_fury.remains>=2
  if not PreviousGCDSpell(blackout_kick) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 Spell(blackout_kick)
  #fists_of_fury,if=((!equipped.drinking_horn_cover|buff.bloodlust.up|buff.serenity.remains<1)&(cooldown.rising_sun_kick.remains>1|active_enemies>1)),interrupt=1
  if { not HasEquippedItem(drinking_horn_cover_item) or BuffPresent(burst_haste_buff any=1) or BuffRemaining(serenity_buff) < 1 } and { SpellCooldown(rising_sun_kick) > 1 or Enemies() > 1 } Spell(fists_of_fury)
  #spinning_crane_kick,if=active_enemies>=3&!prev_gcd.1.spinning_crane_kick
  if Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) Spell(spinning_crane_kick)
  #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies>=3
  if Enemies() >= 3 Spell(rising_sun_kick)
  #spinning_crane_kick,if=!prev_gcd.1.spinning_crane_kick
  if not PreviousGCDSpell(spinning_crane_kick) Spell(spinning_crane_kick)
  #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick
  if not PreviousGCDSpell(blackout_kick) Spell(blackout_kick)
 }
}

AddFunction WindwalkerSerenityMainPostConditions
{
 WindwalkerCdMainPostConditions()
}

AddFunction WindwalkerSerenityShortCdActions
{
 #fist_of_the_white_tiger,if=buff.bloodlust.up&!buff.serenity.up
 if BuffPresent(burst_haste_buff any=1) and not BuffPresent(serenity_buff) Spell(fist_of_the_white_tiger)

 unless not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) and Spell(tiger_palm)
 {
  #call_action_list,name=cd
  WindwalkerCdShortCdActions()

  unless WindwalkerCdShortCdPostConditions() or Talent(rushing_jade_wind_talent) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and BuffExpires(rushing_jade_wind_windwalker_buff) and Spell(rushing_jade_wind_windwalker)
  {
   #serenity
   Spell(serenity)
  }
 }
}

AddFunction WindwalkerSerenityShortCdPostConditions
{
 not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) and Spell(tiger_palm) or WindwalkerCdShortCdPostConditions() or Talent(rushing_jade_wind_talent) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and BuffExpires(rushing_jade_wind_windwalker_buff) and Spell(rushing_jade_wind_windwalker) or Spell(rising_sun_kick) or PreviousGCDSpell(rising_sun_kick) and PreviousGCDSpell(serenity count=2) and Spell(fists_of_fury) or Spell(rising_sun_kick) or not PreviousGCDSpell(blackout_kick) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 and Spell(blackout_kick) or { not HasEquippedItem(drinking_horn_cover_item) or BuffPresent(burst_haste_buff any=1) or BuffRemaining(serenity_buff) < 1 } and { SpellCooldown(rising_sun_kick) > 1 or Enemies() > 1 } and Spell(fists_of_fury) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or Enemies() >= 3 and Spell(rising_sun_kick) or not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick)
}

AddFunction WindwalkerSerenityCdActions
{
 unless BuffPresent(burst_haste_buff any=1) and not BuffPresent(serenity_buff) and Spell(fist_of_the_white_tiger) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) and Spell(tiger_palm)
 {
  #call_action_list,name=cd
  WindwalkerCdCdActions()
 }
}

AddFunction WindwalkerSerenityCdPostConditions
{
 BuffPresent(burst_haste_buff any=1) and not BuffPresent(serenity_buff) and Spell(fist_of_the_white_tiger) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) and Spell(tiger_palm) or WindwalkerCdCdPostConditions() or Talent(rushing_jade_wind_talent) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and BuffExpires(rushing_jade_wind_windwalker_buff) and Spell(rushing_jade_wind_windwalker) or Spell(serenity) or Spell(rising_sun_kick) or PreviousGCDSpell(rising_sun_kick) and PreviousGCDSpell(serenity count=2) and Spell(fists_of_fury) or Spell(rising_sun_kick) or not PreviousGCDSpell(blackout_kick) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 and Spell(blackout_kick) or { not HasEquippedItem(drinking_horn_cover_item) or BuffPresent(burst_haste_buff any=1) or BuffRemaining(serenity_buff) < 1 } and { SpellCooldown(rising_sun_kick) > 1 or Enemies() > 1 } and Spell(fists_of_fury) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or Enemies() >= 3 and Spell(rising_sun_kick) or not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick)
}

### actions.st

AddFunction WindwalkerStMainActions
{
 #invoke_xuen_the_white_tiger
 Spell(invoke_xuen_the_white_tiger)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down&!prev_gcd.1.rushing_jade_wind
 if BuffExpires(rushing_jade_wind_windwalker_buff) and not PreviousGCDSpell(rushing_jade_wind_windwalker) Spell(rushing_jade_wind_windwalker)
 #energizing_elixir,if=!prev_gcd.1.tiger_palm
 if not PreviousGCDSpell(tiger_palm) Spell(energizing_elixir)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&chi.max-chi>=1&set_bonus.tier21_4pc&buff.bok_proc.up
 if not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) Spell(blackout_kick)
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&energy.time_to_max<=1&chi.max-chi>=2&!buff.serenity.up
 if not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and TimeToMaxEnergy() <= 1 and MaxChi() - Chi() >= 2 and not BuffPresent(serenity_buff) Spell(tiger_palm)
 #whirling_dragon_punch
 if SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 Spell(whirling_dragon_punch)
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=((chi>=3&energy>=40)|chi>=5)&(talent.serenity.enabled|cooldown.serenity.remains>=6)
 if { Chi() >= 3 and Energy() >= 40 or Chi() >= 5 } and { Talent(serenity_talent) or SpellCooldown(serenity) >= 6 } Spell(rising_sun_kick)
 #fists_of_fury,if=talent.serenity.enabled&!equipped.drinking_horn_cover&cooldown.serenity.remains>=5&energy.time_to_max>2
 if Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(serenity) >= 5 and TimeToMaxEnergy() > 2 Spell(fists_of_fury)
 #fists_of_fury,if=talent.serenity.enabled&equipped.drinking_horn_cover&(cooldown.serenity.remains>=15|cooldown.serenity.remains<=4)&energy.time_to_max>2
 if Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover_item) and { SpellCooldown(serenity) >= 15 or SpellCooldown(serenity) <= 4 } and TimeToMaxEnergy() > 2 Spell(fists_of_fury)
 #fists_of_fury,if=!talent.serenity.enabled
 if not Talent(serenity_talent) Spell(fists_of_fury)
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=cooldown.serenity.remains>=5|(!talent.serenity.enabled)
 if SpellCooldown(serenity) >= 5 or not Talent(serenity_talent) Spell(rising_sun_kick)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&chi.max-chi>=1
 if not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 Spell(blackout_kick)
 #crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=19&energy.time_to_max>3
 if HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 Spell(crackling_jade_lightning)
 #crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=14&cooldown.serenity.remains<13&talent.serenity.enabled&energy.time_to_max>3
 if HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 Spell(crackling_jade_lightning)
 #blackout_kick,if=!prev_gcd.1.blackout_kick
 if not PreviousGCDSpell(blackout_kick) Spell(blackout_kick)
 #chi_wave
 Spell(chi_wave)
 #chi_burst,if=energy.time_to_max>1&talent.serenity.enabled
 if TimeToMaxEnergy() > 1 and Talent(serenity_talent) and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&(chi.max-chi>=2|energy.time_to_max<3)&!buff.serenity.up
 if not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 3 } and not BuffPresent(serenity_buff) Spell(tiger_palm)
 #chi_burst,if=chi.max-chi>=3&energy.time_to_max>1&!talent.serenity.enabled
 if MaxChi() - Chi() >= 3 and TimeToMaxEnergy() > 1 and not Talent(serenity_talent) and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
}

AddFunction WindwalkerStMainPostConditions
{
}

AddFunction WindwalkerStShortCdActions
{
 unless Spell(invoke_xuen_the_white_tiger) or BuffExpires(rushing_jade_wind_windwalker_buff) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and Spell(rushing_jade_wind_windwalker) or not PreviousGCDSpell(tiger_palm) and Spell(energizing_elixir) or not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) and Spell(blackout_kick) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and TimeToMaxEnergy() <= 1 and MaxChi() - Chi() >= 2 and not BuffPresent(serenity_buff) and Spell(tiger_palm)
 {
  #fist_of_the_white_tiger,if=chi.max-chi>=3
  if MaxChi() - Chi() >= 3 Spell(fist_of_the_white_tiger)
 }
}

AddFunction WindwalkerStShortCdPostConditions
{
 Spell(invoke_xuen_the_white_tiger) or BuffExpires(rushing_jade_wind_windwalker_buff) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and Spell(rushing_jade_wind_windwalker) or not PreviousGCDSpell(tiger_palm) and Spell(energizing_elixir) or not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) and Spell(blackout_kick) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and TimeToMaxEnergy() <= 1 and MaxChi() - Chi() >= 2 and not BuffPresent(serenity_buff) and Spell(tiger_palm) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or { Chi() >= 3 and Energy() >= 40 or Chi() >= 5 } and { Talent(serenity_talent) or SpellCooldown(serenity) >= 6 } and Spell(rising_sun_kick) or Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(serenity) >= 5 and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover_item) and { SpellCooldown(serenity) >= 15 or SpellCooldown(serenity) <= 4 } and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or not Talent(serenity_talent) and Spell(fists_of_fury) or { SpellCooldown(serenity) >= 5 or not Talent(serenity_talent) } and Spell(rising_sun_kick) or not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and Spell(blackout_kick) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick) or Spell(chi_wave) or TimeToMaxEnergy() > 1 and Talent(serenity_talent) and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 3 } and not BuffPresent(serenity_buff) and Spell(tiger_palm) or MaxChi() - Chi() >= 3 and TimeToMaxEnergy() > 1 and not Talent(serenity_talent) and CheckBoxOn(opt_chi_burst) and Spell(chi_burst)
}

AddFunction WindwalkerStCdActions
{
 unless Spell(invoke_xuen_the_white_tiger)
 {
  #storm_earth_and_fire,if=!buff.storm_earth_and_fire.up
  if not BuffPresent(storm_earth_and_fire_buff) and CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff) Spell(storm_earth_and_fire)
 }
}

AddFunction WindwalkerStCdPostConditions
{
 Spell(invoke_xuen_the_white_tiger) or BuffExpires(rushing_jade_wind_windwalker_buff) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and Spell(rushing_jade_wind_windwalker) or not PreviousGCDSpell(tiger_palm) and Spell(energizing_elixir) or not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) and Spell(blackout_kick) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and TimeToMaxEnergy() <= 1 and MaxChi() - Chi() >= 2 and not BuffPresent(serenity_buff) and Spell(tiger_palm) or MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or { Chi() >= 3 and Energy() >= 40 or Chi() >= 5 } and { Talent(serenity_talent) or SpellCooldown(serenity) >= 6 } and Spell(rising_sun_kick) or Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(serenity) >= 5 and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover_item) and { SpellCooldown(serenity) >= 15 or SpellCooldown(serenity) <= 4 } and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or not Talent(serenity_talent) and Spell(fists_of_fury) or { SpellCooldown(serenity) >= 5 or not Talent(serenity_talent) } and Spell(rising_sun_kick) or not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and Spell(blackout_kick) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick) or Spell(chi_wave) or TimeToMaxEnergy() > 1 and Talent(serenity_talent) and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 3 } and not BuffPresent(serenity_buff) and Spell(tiger_palm) or MaxChi() - Chi() >= 3 and TimeToMaxEnergy() > 1 and not Talent(serenity_talent) and CheckBoxOn(opt_chi_burst) and Spell(chi_burst)
}

### Windwalker icons.

AddCheckBox(opt_monk_windwalker_aoe L(AOE) default specialization=windwalker)

AddIcon checkbox=!opt_monk_windwalker_aoe enemies=1 help=shortcd specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatShortCdActions()
 unless not InCombat() and WindwalkerPrecombatShortCdPostConditions()
 {
  WindwalkerDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_monk_windwalker_aoe help=shortcd specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatShortCdActions()
 unless not InCombat() and WindwalkerPrecombatShortCdPostConditions()
 {
  WindwalkerDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatMainActions()
 unless not InCombat() and WindwalkerPrecombatMainPostConditions()
 {
  WindwalkerDefaultMainActions()
 }
}

AddIcon checkbox=opt_monk_windwalker_aoe help=aoe specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatMainActions()
 unless not InCombat() and WindwalkerPrecombatMainPostConditions()
 {
  WindwalkerDefaultMainActions()
 }
}

AddIcon checkbox=!opt_monk_windwalker_aoe enemies=1 help=cd specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatCdActions()
 unless not InCombat() and WindwalkerPrecombatCdPostConditions()
 {
  WindwalkerDefaultCdActions()
 }
}

AddIcon checkbox=opt_monk_windwalker_aoe help=cd specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatCdActions()
 unless not InCombat() and WindwalkerPrecombatCdPostConditions()
 {
  WindwalkerDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# arcane_torrent_chi
# battle_potion_of_agility
# berserking
# blackout_kick
# blackout_kick_buff
# blood_fury_apsp
# chi_burst
# chi_wave
# crackling_jade_lightning
# drinking_horn_cover_item
# energizing_elixir
# energizing_elixir_talent
# fireblood
# fist_of_the_white_tiger
# fist_of_the_white_tiger_talent
# fists_of_fury
# good_karma_talent
# hidden_masters_forbidden_touch_buff
# hidden_masters_forbidden_touch_item
# invoke_xuen_the_white_tiger
# leg_sweep
# lights_judgment
# mark_of_the_crane_debuff
# paralysis
# quaking_palm
# rising_sun_kick
# rushing_jade_wind_talent
# rushing_jade_wind_windwalker
# rushing_jade_wind_windwalker_buff
# serenity
# serenity_buff
# serenity_talent
# spear_hand_strike
# spinning_crane_kick
# storm_earth_and_fire
# storm_earth_and_fire_buff
# the_emperors_capacitor_buff
# the_emperors_capacitor_item
# tiger_palm
# touch_of_death
# touch_of_karma
# war_stomp
# whirling_dragon_punch
        
]]
    OvaleScripts:RegisterScript("MONK", "windwalker", name, desc, code, "script")
end
do
    local name = "sc_monk_brewmaster_pr"
    local desc = "[8.0] Simulationcraft: Monk_Brewmaster_PreRaid"
    local code = [[
# Based on SimulationCraft profile "PR_Monk_Brewmaster".
#    class=monk
#    spec=brewmaster
#    talents=2020033

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=brewmaster)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=brewmaster)
AddCheckBox(opt_chi_burst SpellName(chi_burst) default specialization=brewmaster)

AddFunction BrewmasterUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction BrewmasterGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.default

AddFunction BrewmasterDefaultMainActions
{
 #invoke_niuzao_the_black_ox,if=target.time_to_die>45
 if target.TimeToDie() > 45 Spell(invoke_niuzao_the_black_ox)
 #black_ox_brew,if=incoming_damage_1500ms&stagger.heavy&cooldown.brews.charges_fractional<=0.75
 if IncomingDamage(1.5) > 0 and DebuffPresent(heavy_stagger_debuff) and SpellCharges(ironskin_brew count=0) <= 0.75 Spell(black_ox_brew)
 #black_ox_brew,if=(energy+(energy.regen*cooldown.keg_smash.remains))<40&buff.blackout_combo.down&cooldown.keg_smash.up
 if Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) < 40 and BuffExpires(blackout_combo_buff) and not SpellCooldown(keg_smash) > 0 Spell(black_ox_brew)
 #keg_smash,if=spell_targets>=3
 if Enemies() >= 3 Spell(keg_smash)
 #tiger_palm,if=buff.blackout_combo.up
 if BuffPresent(blackout_combo_buff) Spell(tiger_palm)
 #keg_smash
 Spell(keg_smash)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down
 if BuffExpires(rushing_jade_wind_buff) Spell(rushing_jade_wind)
 #blackout_strike
 Spell(blackout_strike)
 #breath_of_fire,if=buff.blackout_combo.down&(buff.bloodlust.down|(buff.bloodlust.up&&dot.breath_of_fire_dot.refreshable))
 if BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_debuff) } Spell(breath_of_fire)
 #chi_burst
 if CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #chi_wave
 Spell(chi_wave)
 #tiger_palm,if=!talent.blackout_combo.enabled&cooldown.keg_smash.remains>gcd&(energy+(energy.regen*(cooldown.keg_smash.remains+gcd)))>=55
 if not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 55 Spell(tiger_palm)
}

AddFunction BrewmasterDefaultMainPostConditions
{
}

AddFunction BrewmasterDefaultShortCdActions
{
 #auto_attack
 BrewmasterGetInMeleeRange()

 unless target.TimeToDie() > 45 and Spell(invoke_niuzao_the_black_ox)
 {
  #purifying_brew,if=stagger.heavy|(stagger.moderate&cooldown.brews.charges_fractional>=cooldown.brews.max_charges-0.5&buff.ironskin_brew.remains>=buff.ironskin_brew.duration*2.5)
  if DebuffPresent(heavy_stagger_debuff) or DebuffPresent(moderate_stagger_debuff) and SpellCharges(ironskin_brew count=0) >= SpellMaxCharges(ironskin_brew) - 0.5 and BuffRemaining(ironskin_brew_buff) >= BaseDuration(ironskin_brew_buff) * 2.5 Spell(purifying_brew)
  #ironskin_brew,if=buff.blackout_combo.down&cooldown.brews.charges_fractional>=cooldown.brews.max_charges-1.0-(1+buff.ironskin_brew.remains<=buff.ironskin_brew.duration*0.5)&buff.ironskin_brew.remains<=buff.ironskin_brew.duration*2
  if BuffExpires(blackout_combo_buff) and SpellCharges(ironskin_brew count=0) >= SpellMaxCharges(ironskin_brew) - 1 - { 1 + BuffRemaining(ironskin_brew_buff) <= BaseDuration(ironskin_brew_buff) * 0.5 } and BuffRemaining(ironskin_brew_buff) <= BaseDuration(ironskin_brew_buff) * 2 Spell(ironskin_brew)
 }
}

AddFunction BrewmasterDefaultShortCdPostConditions
{
 target.TimeToDie() > 45 and Spell(invoke_niuzao_the_black_ox) or IncomingDamage(1.5) > 0 and DebuffPresent(heavy_stagger_debuff) and SpellCharges(ironskin_brew count=0) <= 0.75 and Spell(black_ox_brew) or Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) < 40 and BuffExpires(blackout_combo_buff) and not SpellCooldown(keg_smash) > 0 and Spell(black_ox_brew) or Enemies() >= 3 and Spell(keg_smash) or BuffPresent(blackout_combo_buff) and Spell(tiger_palm) or Spell(keg_smash) or BuffExpires(rushing_jade_wind_buff) and Spell(rushing_jade_wind) or Spell(blackout_strike) or BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_debuff) } and Spell(breath_of_fire) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave) or not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 55 and Spell(tiger_palm)
}

AddFunction BrewmasterDefaultCdActions
{
 #gift_of_the_ox
 #dampen_harm,if=incoming_damage_1500ms&buff.fortifying_brew.down
 if IncomingDamage(1.5) > 0 and BuffExpires(fortifying_brew_buff) Spell(dampen_harm)
 #fortifying_brew,if=incoming_damage_1500ms&(buff.dampen_harm.down|buff.diffuse_magic.down)
 if IncomingDamage(1.5) > 0 and { BuffExpires(dampen_harm_buff) or BuffExpires(diffuse_magic_buff) } Spell(fortifying_brew)
 #use_item,name=lustrous_golden_plumage
 BrewmasterUseItemActions()
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #blood_fury
 Spell(blood_fury_apsp)
 #berserking
 Spell(berserking)
 #lights_judgment
 Spell(lights_judgment)
 #fireblood
 Spell(fireblood)
 #ancestral_call
 Spell(ancestral_call)

 unless target.TimeToDie() > 45 and Spell(invoke_niuzao_the_black_ox) or IncomingDamage(1.5) > 0 and DebuffPresent(heavy_stagger_debuff) and SpellCharges(ironskin_brew count=0) <= 0.75 and Spell(black_ox_brew) or Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) < 40 and BuffExpires(blackout_combo_buff) and not SpellCooldown(keg_smash) > 0 and Spell(black_ox_brew)
 {
  #arcane_torrent,if=energy<31
  if Energy() < 31 Spell(arcane_torrent_chi)
 }
}

AddFunction BrewmasterDefaultCdPostConditions
{
 target.TimeToDie() > 45 and Spell(invoke_niuzao_the_black_ox) or IncomingDamage(1.5) > 0 and DebuffPresent(heavy_stagger_debuff) and SpellCharges(ironskin_brew count=0) <= 0.75 and Spell(black_ox_brew) or Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) < 40 and BuffExpires(blackout_combo_buff) and not SpellCooldown(keg_smash) > 0 and Spell(black_ox_brew) or Enemies() >= 3 and Spell(keg_smash) or BuffPresent(blackout_combo_buff) and Spell(tiger_palm) or Spell(keg_smash) or BuffExpires(rushing_jade_wind_buff) and Spell(rushing_jade_wind) or Spell(blackout_strike) or BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_debuff) } and Spell(breath_of_fire) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave) or not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 55 and Spell(tiger_palm)
}

### actions.precombat

AddFunction BrewmasterPrecombatMainActions
{
 #chi_burst
 if CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #chi_wave
 Spell(chi_wave)
}

AddFunction BrewmasterPrecombatMainPostConditions
{
}

AddFunction BrewmasterPrecombatShortCdActions
{
}

AddFunction BrewmasterPrecombatShortCdPostConditions
{
 CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

AddFunction BrewmasterPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
}

AddFunction BrewmasterPrecombatCdPostConditions
{
 CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

### Brewmaster icons.

AddCheckBox(opt_monk_brewmaster_aoe L(AOE) default specialization=brewmaster)

AddIcon checkbox=!opt_monk_brewmaster_aoe enemies=1 help=shortcd specialization=brewmaster
{
 if not InCombat() BrewmasterPrecombatShortCdActions()
 unless not InCombat() and BrewmasterPrecombatShortCdPostConditions()
 {
  BrewmasterDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_monk_brewmaster_aoe help=shortcd specialization=brewmaster
{
 if not InCombat() BrewmasterPrecombatShortCdActions()
 unless not InCombat() and BrewmasterPrecombatShortCdPostConditions()
 {
  BrewmasterDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=brewmaster
{
 if not InCombat() BrewmasterPrecombatMainActions()
 unless not InCombat() and BrewmasterPrecombatMainPostConditions()
 {
  BrewmasterDefaultMainActions()
 }
}

AddIcon checkbox=opt_monk_brewmaster_aoe help=aoe specialization=brewmaster
{
 if not InCombat() BrewmasterPrecombatMainActions()
 unless not InCombat() and BrewmasterPrecombatMainPostConditions()
 {
  BrewmasterDefaultMainActions()
 }
}

AddIcon checkbox=!opt_monk_brewmaster_aoe enemies=1 help=cd specialization=brewmaster
{
 if not InCombat() BrewmasterPrecombatCdActions()
 unless not InCombat() and BrewmasterPrecombatCdPostConditions()
 {
  BrewmasterDefaultCdActions()
 }
}

AddIcon checkbox=opt_monk_brewmaster_aoe help=cd specialization=brewmaster
{
 if not InCombat() BrewmasterPrecombatCdActions()
 unless not InCombat() and BrewmasterPrecombatCdPostConditions()
 {
  BrewmasterDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# arcane_torrent_chi
# battle_potion_of_agility
# berserking
# black_ox_brew
# blackout_combo_buff
# blackout_combo_talent
# blackout_strike
# blood_fury_apsp
# breath_of_fire
# breath_of_fire_debuff
# chi_burst
# chi_wave
# dampen_harm
# dampen_harm_buff
# diffuse_magic_buff
# fireblood
# fortifying_brew
# fortifying_brew_buff
# heavy_stagger_debuff
# invoke_niuzao_the_black_ox
# ironskin_brew
# ironskin_brew_buff
# keg_smash
# lights_judgment
# moderate_stagger_debuff
# purifying_brew
# rushing_jade_wind
# rushing_jade_wind_buff
# tiger_palm

]]
    OvaleScripts:RegisterScript("MONK", "brewmaster", name, desc, code, "script")
end
