local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "icyveins_monk_brewmaster"
	local desc = "[7.0] Icy-Veins: Monk Brewmaster"
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
	if (HealthPercent() < 35) Spell(healing_elixir)
	if (HealthPercent() < 35) Spell(expel_harm)
	if (HealthPercent() <= 100 - (15 * 2.6)) Spell(healing_elixir)
}

AddFunction StaggerPercentage
{
	StaggerRemaining() / MaxHealth() * 100
}

AddFunction BrewmasterRangeCheck
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction BrewmasterDefaultShortCDActions
{
	# keep ISB up always when taking dmg
	if BuffRemaining(ironskin_brew_buff) < DebuffRemaining(any_stagger_debuff) Spell(ironskin_brew text=min)
	
	# keep stagger below 100%
	if (StaggerPercentage() > 100) Spell(purifying_brew)
	# use black_ox_brew when at 0 charges and low energy (or in an emergency)
	if ((SpellCharges(purifying_brew) == 0) and (Energy() < 30 or StaggerPercentage() > 75)) Spell(black_ox_brew)
	# heal me
	BrewmasterHealMe()
	
	# range check
	BrewmasterRangeCheck()

	unless StaggerPercentage() > 100 or BrewmasterHealMe()
	{
		# purify heavy stagger when we have enough ISB
		if (StaggerPercentage() > 60 and (BuffRemaining(ironskin_brew_buff) >= 2*BaseDuration(ironskin_brew_buff))) Spell(purifying_brew)
		
		# always keep 1 charge unless black_ox_brew is coming off cd
		if (SpellCharges(ironskin_brew) >= 2)
		{
			# never be at (almost) max charges 
			if ((SpellCharges(ironskin_brew count=0) >= SpellMaxCharges(ironskin_brew)-0.2))
			{
				if (BuffRemaining(ironskin_brew_buff) < 2*BaseDuration(ironskin_brew_buff)) Spell(ironskin_brew text=max)
				if (StaggerPercentage() > 30 or Talent(special_delivery_talent)) Spell(purifying_brew text=max)
			}
			
			if(StaggerRemaining() > 0)
			{
				# keep brew-stache rolling
				if (IncomingDamage(3 physical=1)>0 and HasArtifactTrait(brew_stache_trait) and BuffExpires(brew_stache_buff)) 
				{
					if (BuffRemaining(ironskin_brew_buff) < 2*BaseDuration(ironskin_brew_buff)) Spell(ironskin_brew text=stache)
					if (StaggerPercentage() > 30) Spell(purifying_brew text=stache)
				}
				# keep up ironskin_brew_buff
				if (BuffRemaining(ironskin_brew_buff) < BaseDuration(ironskin_brew_buff)) Spell(ironskin_brew)
				# purify stagger when talent elusive dance 
				if (Talent(elusive_dance_talent) and BuffExpires(elusive_dance_buff)) Spell(purifying_brew)
			}
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
		if (EnergyDeficit() <= 35) Spell(tiger_palm)
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
	if (EnergyDeficit() <= 35) Spell(tiger_palm)
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
		if target.Distance(less 8) and target.IsInterruptible() Spell(arcane_torrent_chi)
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

-- THE REST OF THIS FILE IS AUTOMATICALLY GENERATED.
-- ANY CHANGES MADE BELOW THIS POINT WILL BE LOST.

do
	local name = "simulationcraft_monk_windwalker_t19p"
	local desc = "[7.0] SimulationCraft: Monk_Windwalker_T19P"
	local code = [[
# Based on SimulationCraft profile "Monk_Windwalker_T19P".
#	class=monk
#	spec=windwalker
#	talents=3010033

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=windwalker)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=windwalker)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=windwalker)
AddCheckBox(opt_touch_of_death_on_elite_only L(touch_of_death_on_elite_only) default specialization=windwalker)
AddCheckBox(opt_touch_of_karma SpellName(touch_of_karma) specialization=windwalker)
AddCheckBox(opt_storm_earth_and_fire SpellName(storm_earth_and_fire) specialization=windwalker)
AddCheckBox(opt_chi_burst SpellName(chi_burst) default specialization=windwalker)

AddFunction WindwalkerInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
	{
		if target.InRange(spear_hand_strike) and target.IsInterruptible() Spell(spear_hand_strike)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(leg_sweep)
		if target.Distance(less 8) and target.IsInterruptible() Spell(arcane_torrent_chi)
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
	#call_action_list,name=serenity_opener,if=((talent.serenity.enabled&cooldown.serenity.remains<=0)|buff.serenity.up)&buff.bloodlust.up&active_enemies<2&set_bonus.tier20_4pc&set_bonus.tier19_2pc&equipped.drinking_horn_cover&(equipped.katsuos_eclipse|race.blood_elf|talent.power_strikes.enabled)
	if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and BuffPresent(burst_haste_buff any=1) and Enemies() < 2 and ArmorSetBonus(T20 4) and ArmorSetBonus(T19 2) and HasEquippedItem(drinking_horn_cover) and { HasEquippedItem(katsuos_eclipse) or Race(BloodElf) or Talent(power_strikes_talent) } WindwalkerSerenityOpenerMainActions()

	unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and BuffPresent(burst_haste_buff any=1) and Enemies() < 2 and ArmorSetBonus(T20 4) and ArmorSetBonus(T19 2) and HasEquippedItem(drinking_horn_cover) and { HasEquippedItem(katsuos_eclipse) or Race(BloodElf) or Talent(power_strikes_talent) } and WindwalkerSerenityOpenerMainPostConditions()
	{
		#call_action_list,name=serenity,if=(talent.serenity.enabled&cooldown.serenity.remains<=0)|(buff.serenity.up&time>20)
		if Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) and TimeInCombat() > 20 WindwalkerSerenityMainActions()

		unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) and TimeInCombat() > 20 } and WindwalkerSerenityMainPostConditions()
		{
			#call_action_list,name=sef,if=!talent.serenity.enabled&(buff.storm_earth_and_fire.up|cooldown.storm_earth_and_fire.charges=2)
			if not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } WindwalkerSefMainActions()

			unless not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefMainPostConditions()
			{
				#call_action_list,name=sef,if=!talent.serenity.enabled&equipped.drinking_horn_cover&(cooldown.strike_of_the_windlord.remains<=18&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1|target.time_to_die<=25|cooldown.touch_of_death.remains>112)&cooldown.storm_earth_and_fire.charges=1
				if not Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 18 and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefMainActions()

				unless not Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 18 and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 and WindwalkerSefMainPostConditions()
				{
					#call_action_list,name=sef,if=!talent.serenity.enabled&!equipped.drinking_horn_cover&(cooldown.strike_of_the_windlord.remains<=14&cooldown.fists_of_fury.remains<=6&chi>=3&cooldown.rising_sun_kick.remains<=1|target.time_to_die<=15|cooldown.touch_of_death.remains>112)&cooldown.storm_earth_and_fire.charges=1
					if not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefMainActions()

					unless not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 and WindwalkerSefMainPostConditions()
					{
						#call_action_list,name=st
						WindwalkerStMainActions()
					}
				}
			}
		}
	}
}

AddFunction WindwalkerDefaultMainPostConditions
{
	{ Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and BuffPresent(burst_haste_buff any=1) and Enemies() < 2 and ArmorSetBonus(T20 4) and ArmorSetBonus(T19 2) and HasEquippedItem(drinking_horn_cover) and { HasEquippedItem(katsuos_eclipse) or Race(BloodElf) or Talent(power_strikes_talent) } and WindwalkerSerenityOpenerMainPostConditions() or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) and TimeInCombat() > 20 } and WindwalkerSerenityMainPostConditions() or not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefMainPostConditions() or not Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 18 and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 and WindwalkerSefMainPostConditions() or not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 and WindwalkerSefMainPostConditions() or WindwalkerStMainPostConditions()
}

AddFunction WindwalkerDefaultShortCdActions
{
	#auto_attack
	WindwalkerGetInMeleeRange()

	unless target.TimeToDie() <= 9 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death)
	{
		#call_action_list,name=serenity_opener,if=((talent.serenity.enabled&cooldown.serenity.remains<=0)|buff.serenity.up)&buff.bloodlust.up&active_enemies<2&set_bonus.tier20_4pc&set_bonus.tier19_2pc&equipped.drinking_horn_cover&(equipped.katsuos_eclipse|race.blood_elf|talent.power_strikes.enabled)
		if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and BuffPresent(burst_haste_buff any=1) and Enemies() < 2 and ArmorSetBonus(T20 4) and ArmorSetBonus(T19 2) and HasEquippedItem(drinking_horn_cover) and { HasEquippedItem(katsuos_eclipse) or Race(BloodElf) or Talent(power_strikes_talent) } WindwalkerSerenityOpenerShortCdActions()

		unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and BuffPresent(burst_haste_buff any=1) and Enemies() < 2 and ArmorSetBonus(T20 4) and ArmorSetBonus(T19 2) and HasEquippedItem(drinking_horn_cover) and { HasEquippedItem(katsuos_eclipse) or Race(BloodElf) or Talent(power_strikes_talent) } and WindwalkerSerenityOpenerShortCdPostConditions()
		{
			#call_action_list,name=serenity,if=(talent.serenity.enabled&cooldown.serenity.remains<=0)|(buff.serenity.up&time>20)
			if Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) and TimeInCombat() > 20 WindwalkerSerenityShortCdActions()

			unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) and TimeInCombat() > 20 } and WindwalkerSerenityShortCdPostConditions()
			{
				#call_action_list,name=sef,if=!talent.serenity.enabled&(buff.storm_earth_and_fire.up|cooldown.storm_earth_and_fire.charges=2)
				if not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } WindwalkerSefShortCdActions()

				unless not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefShortCdPostConditions()
				{
					#call_action_list,name=sef,if=!talent.serenity.enabled&equipped.drinking_horn_cover&(cooldown.strike_of_the_windlord.remains<=18&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1|target.time_to_die<=25|cooldown.touch_of_death.remains>112)&cooldown.storm_earth_and_fire.charges=1
					if not Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 18 and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefShortCdActions()

					unless not Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 18 and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 and WindwalkerSefShortCdPostConditions()
					{
						#call_action_list,name=sef,if=!talent.serenity.enabled&!equipped.drinking_horn_cover&(cooldown.strike_of_the_windlord.remains<=14&cooldown.fists_of_fury.remains<=6&chi>=3&cooldown.rising_sun_kick.remains<=1|target.time_to_die<=15|cooldown.touch_of_death.remains>112)&cooldown.storm_earth_and_fire.charges=1
						if not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefShortCdActions()

						unless not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 and WindwalkerSefShortCdPostConditions()
						{
							#call_action_list,name=st
							WindwalkerStShortCdActions()
						}
					}
				}
			}
		}
	}
}

AddFunction WindwalkerDefaultShortCdPostConditions
{
	target.TimeToDie() <= 9 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death) or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and BuffPresent(burst_haste_buff any=1) and Enemies() < 2 and ArmorSetBonus(T20 4) and ArmorSetBonus(T19 2) and HasEquippedItem(drinking_horn_cover) and { HasEquippedItem(katsuos_eclipse) or Race(BloodElf) or Talent(power_strikes_talent) } and WindwalkerSerenityOpenerShortCdPostConditions() or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) and TimeInCombat() > 20 } and WindwalkerSerenityShortCdPostConditions() or not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefShortCdPostConditions() or not Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 18 and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 and WindwalkerSefShortCdPostConditions() or not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 and WindwalkerSefShortCdPostConditions() or WindwalkerStShortCdPostConditions()
}

AddFunction WindwalkerDefaultCdActions
{
	#spear_hand_strike,if=target.debuff.casting.react
	if target.IsInterruptible() WindwalkerInterruptActions()
	#touch_of_karma,interval=90,pct_health=0.5
	if CheckBoxOn(opt_touch_of_karma) Spell(touch_of_karma)
	#potion,if=buff.serenity.up|buff.storm_earth_and_fire.up|(!talent.serenity.enabled&trinket.proc.agility.react)|buff.bloodlust.react|target.time_to_die<=60
	if { BuffPresent(serenity_buff) or BuffPresent(storm_earth_and_fire_buff) or not Talent(serenity_talent) and BuffPresent(trinket_proc_agility_buff) or BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)

	unless target.TimeToDie() <= 9 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death)
	{
		#call_action_list,name=serenity_opener,if=((talent.serenity.enabled&cooldown.serenity.remains<=0)|buff.serenity.up)&buff.bloodlust.up&active_enemies<2&set_bonus.tier20_4pc&set_bonus.tier19_2pc&equipped.drinking_horn_cover&(equipped.katsuos_eclipse|race.blood_elf|talent.power_strikes.enabled)
		if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and BuffPresent(burst_haste_buff any=1) and Enemies() < 2 and ArmorSetBonus(T20 4) and ArmorSetBonus(T19 2) and HasEquippedItem(drinking_horn_cover) and { HasEquippedItem(katsuos_eclipse) or Race(BloodElf) or Talent(power_strikes_talent) } WindwalkerSerenityOpenerCdActions()

		unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and BuffPresent(burst_haste_buff any=1) and Enemies() < 2 and ArmorSetBonus(T20 4) and ArmorSetBonus(T19 2) and HasEquippedItem(drinking_horn_cover) and { HasEquippedItem(katsuos_eclipse) or Race(BloodElf) or Talent(power_strikes_talent) } and WindwalkerSerenityOpenerCdPostConditions()
		{
			#call_action_list,name=serenity,if=(talent.serenity.enabled&cooldown.serenity.remains<=0)|(buff.serenity.up&time>20)
			if Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) and TimeInCombat() > 20 WindwalkerSerenityCdActions()

			unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) and TimeInCombat() > 20 } and WindwalkerSerenityCdPostConditions()
			{
				#call_action_list,name=sef,if=!talent.serenity.enabled&(buff.storm_earth_and_fire.up|cooldown.storm_earth_and_fire.charges=2)
				if not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } WindwalkerSefCdActions()

				unless not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefCdPostConditions()
				{
					#call_action_list,name=sef,if=!talent.serenity.enabled&equipped.drinking_horn_cover&(cooldown.strike_of_the_windlord.remains<=18&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1|target.time_to_die<=25|cooldown.touch_of_death.remains>112)&cooldown.storm_earth_and_fire.charges=1
					if not Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 18 and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefCdActions()

					unless not Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 18 and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 and WindwalkerSefCdPostConditions()
					{
						#call_action_list,name=sef,if=!talent.serenity.enabled&!equipped.drinking_horn_cover&(cooldown.strike_of_the_windlord.remains<=14&cooldown.fists_of_fury.remains<=6&chi>=3&cooldown.rising_sun_kick.remains<=1|target.time_to_die<=15|cooldown.touch_of_death.remains>112)&cooldown.storm_earth_and_fire.charges=1
						if not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefCdActions()

						unless not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 and WindwalkerSefCdPostConditions()
						{
							#call_action_list,name=st
							WindwalkerStCdActions()
						}
					}
				}
			}
		}
	}
}

AddFunction WindwalkerDefaultCdPostConditions
{
	target.TimeToDie() <= 9 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death) or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) } and BuffPresent(burst_haste_buff any=1) and Enemies() < 2 and ArmorSetBonus(T20 4) and ArmorSetBonus(T19 2) and HasEquippedItem(drinking_horn_cover) and { HasEquippedItem(katsuos_eclipse) or Race(BloodElf) or Talent(power_strikes_talent) } and WindwalkerSerenityOpenerCdPostConditions() or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or BuffPresent(serenity_buff) and TimeInCombat() > 20 } and WindwalkerSerenityCdPostConditions() or not Talent(serenity_talent) and { BuffPresent(storm_earth_and_fire_buff) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefCdPostConditions() or not Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 18 and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 and WindwalkerSefCdPostConditions() or not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover) and { SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 } and SpellCharges(storm_earth_and_fire) == 1 and WindwalkerSefCdPostConditions() or WindwalkerStCdPostConditions()
}

### actions.cd

AddFunction WindwalkerCdMainActions
{
	#touch_of_death,cycle_targets=1,max_cycle_targets=2,if=!artifact.gale_burst.enabled&equipped.hidden_masters_forbidden_touch&!prev_gcd.1.touch_of_death
	if DebuffCountOnAny(touch_of_death_debuff) < Enemies() and DebuffCountOnAny(touch_of_death_debuff) <= 2 and not HasArtifactTrait(gale_burst) and HasEquippedItem(hidden_masters_forbidden_touch) and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } Spell(touch_of_death)
	#touch_of_death,if=!artifact.gale_burst.enabled&!equipped.hidden_masters_forbidden_touch
	if not HasArtifactTrait(gale_burst) and not HasEquippedItem(hidden_masters_forbidden_touch) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } Spell(touch_of_death)
	#touch_of_death,cycle_targets=1,max_cycle_targets=2,if=artifact.gale_burst.enabled&((talent.serenity.enabled&cooldown.serenity.remains<=1)|chi>=2)&(cooldown.strike_of_the_windlord.remains<8|cooldown.fists_of_fury.remains<=4)&cooldown.rising_sun_kick.remains<7&!prev_gcd.1.touch_of_death
	if DebuffCountOnAny(touch_of_death_debuff) < Enemies() and DebuffCountOnAny(touch_of_death_debuff) <= 2 and HasArtifactTrait(gale_burst) and { Talent(serenity_talent) and SpellCooldown(serenity) <= 1 or Chi() >= 2 } and { SpellCooldown(strike_of_the_windlord) < 8 or SpellCooldown(fists_of_fury) <= 4 } and SpellCooldown(rising_sun_kick) < 7 and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } Spell(touch_of_death)
}

AddFunction WindwalkerCdMainPostConditions
{
}

AddFunction WindwalkerCdShortCdActions
{
}

AddFunction WindwalkerCdShortCdPostConditions
{
	DebuffCountOnAny(touch_of_death_debuff) < Enemies() and DebuffCountOnAny(touch_of_death_debuff) <= 2 and not HasArtifactTrait(gale_burst) and HasEquippedItem(hidden_masters_forbidden_touch) and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death) or not HasArtifactTrait(gale_burst) and not HasEquippedItem(hidden_masters_forbidden_touch) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death) or DebuffCountOnAny(touch_of_death_debuff) < Enemies() and DebuffCountOnAny(touch_of_death_debuff) <= 2 and HasArtifactTrait(gale_burst) and { Talent(serenity_talent) and SpellCooldown(serenity) <= 1 or Chi() >= 2 } and { SpellCooldown(strike_of_the_windlord) < 8 or SpellCooldown(fists_of_fury) <= 4 } and SpellCooldown(rising_sun_kick) < 7 and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death)
}

AddFunction WindwalkerCdCdActions
{
	#invoke_xuen_the_white_tiger
	Spell(invoke_xuen_the_white_tiger)
	#use_item,name=specter_of_betrayal,if=(cooldown.serenity.remains>10|buff.serenity.up)|!talent.serenity.enabled
	if SpellCooldown(serenity) > 10 or BuffPresent(serenity_buff) or not Talent(serenity_talent) WindwalkerUseItemActions()
	#use_item,name=vial_of_ceaseless_toxins,if=(buff.serenity.up&!equipped.specter_of_betrayal)|(equipped.specter_of_betrayal&(time<5|cooldown.serenity.remains<=8))|!talent.serenity.enabled|target.time_to_die<=cooldown.serenity.remains
	if BuffPresent(serenity_buff) and not HasEquippedItem(specter_of_betrayal) or HasEquippedItem(specter_of_betrayal) and { TimeInCombat() < 5 or SpellCooldown(serenity) <= 8 } or not Talent(serenity_talent) or target.TimeToDie() <= SpellCooldown(serenity) WindwalkerUseItemActions()
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
	if MaxChi() - Chi() >= 1 and TimeToMaxEnergy() >= 0.5 Spell(arcane_torrent_chi)
}

AddFunction WindwalkerCdCdPostConditions
{
	DebuffCountOnAny(touch_of_death_debuff) < Enemies() and DebuffCountOnAny(touch_of_death_debuff) <= 2 and not HasArtifactTrait(gale_burst) and HasEquippedItem(hidden_masters_forbidden_touch) and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death) or not HasArtifactTrait(gale_burst) and not HasEquippedItem(hidden_masters_forbidden_touch) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death) or DebuffCountOnAny(touch_of_death_debuff) < Enemies() and DebuffCountOnAny(touch_of_death_debuff) <= 2 and HasArtifactTrait(gale_burst) and { Talent(serenity_talent) and SpellCooldown(serenity) <= 1 or Chi() >= 2 } and { SpellCooldown(strike_of_the_windlord) < 8 or SpellCooldown(fists_of_fury) <= 4 } and SpellCooldown(rising_sun_kick) < 7 and not PreviousGCDSpell(touch_of_death) and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } and Spell(touch_of_death)
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
	if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
}

AddFunction WindwalkerPrecombatCdPostConditions
{
	CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

### actions.sef

AddFunction WindwalkerSefMainActions
{
	#tiger_palm,cycle_targets=1,if=!prev_gcd.1.tiger_palm&energy=energy.max&chi<1
	if not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 Spell(tiger_palm)
	#call_action_list,name=cd
	WindwalkerCdMainActions()

	unless WindwalkerCdMainPostConditions()
	{
		#call_action_list,name=st
		WindwalkerStMainActions()
	}
}

AddFunction WindwalkerSefMainPostConditions
{
	WindwalkerCdMainPostConditions() or WindwalkerStMainPostConditions()
}

AddFunction WindwalkerSefShortCdActions
{
	unless not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and Spell(tiger_palm)
	{
		#call_action_list,name=cd
		WindwalkerCdShortCdActions()

		unless WindwalkerCdShortCdPostConditions()
		{
			#call_action_list,name=st
			WindwalkerStShortCdActions()
		}
	}
}

AddFunction WindwalkerSefShortCdPostConditions
{
	not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and Spell(tiger_palm) or WindwalkerCdShortCdPostConditions() or WindwalkerStShortCdPostConditions()
}

AddFunction WindwalkerSefCdActions
{
	unless not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and Spell(tiger_palm)
	{
		#arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
		if MaxChi() - Chi() >= 1 and TimeToMaxEnergy() >= 0.5 Spell(arcane_torrent_chi)
		#call_action_list,name=cd
		WindwalkerCdCdActions()

		unless WindwalkerCdCdPostConditions()
		{
			#storm_earth_and_fire,if=!buff.storm_earth_and_fire.up
			if not BuffPresent(storm_earth_and_fire_buff) and CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff) Spell(storm_earth_and_fire)
			#call_action_list,name=st
			WindwalkerStCdActions()
		}
	}
}

AddFunction WindwalkerSefCdPostConditions
{
	not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and Spell(tiger_palm) or WindwalkerCdCdPostConditions() or WindwalkerStCdPostConditions()
}

### actions.serenity

AddFunction WindwalkerSerenityMainActions
{
	#tiger_palm,cycle_targets=1,if=!prev_gcd.1.tiger_palm&energy=energy.max&chi<1&!buff.serenity.up
	if not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) Spell(tiger_palm)
	#call_action_list,name=cd
	WindwalkerCdMainActions()

	unless WindwalkerCdMainPostConditions()
	{
		#rising_sun_kick,cycle_targets=1,if=active_enemies<3
		if Enemies() < 3 Spell(rising_sun_kick)
		#strike_of_the_windlord
		Spell(strike_of_the_windlord)
		#blackout_kick,cycle_targets=1,if=(!prev_gcd.1.blackout_kick)&(prev_gcd.1.strike_of_the_windlord|prev_gcd.1.fists_of_fury)&active_enemies<2
		if not PreviousGCDSpell(blackout_kick) and { PreviousGCDSpell(strike_of_the_windlord) or PreviousGCDSpell(fists_of_fury) } and Enemies() < 2 Spell(blackout_kick)
		#fists_of_fury,if=((equipped.drinking_horn_cover&buff.pressure_point.remains<=2&set_bonus.tier20_4pc)&(cooldown.rising_sun_kick.remains>1|active_enemies>1)),interrupt=1
		if HasEquippedItem(drinking_horn_cover) and BuffRemaining(pressure_point_buff) <= 2 and ArmorSetBonus(T20 4) and { SpellCooldown(rising_sun_kick) > 1 or Enemies() > 1 } Spell(fists_of_fury)
		#fists_of_fury,if=((!equipped.drinking_horn_cover|buff.bloodlust.up|buff.serenity.remains<1)&(cooldown.rising_sun_kick.remains>1|active_enemies>1)),interrupt=1
		if { not HasEquippedItem(drinking_horn_cover) or BuffPresent(burst_haste_buff any=1) or BuffRemaining(serenity_buff) < 1 } and { SpellCooldown(rising_sun_kick) > 1 or Enemies() > 1 } Spell(fists_of_fury)
		#spinning_crane_kick,if=active_enemies>=3&!prev_gcd.1.spinning_crane_kick
		if Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) Spell(spinning_crane_kick)
		#rushing_jade_wind,if=!prev_gcd.1.rushing_jade_wind&buff.rushing_jade_wind.down&buff.serenity.remains>=4
		if not PreviousGCDSpell(rushing_jade_wind) and BuffExpires(rushing_jade_wind_buff) and BuffRemaining(serenity_buff) >= 4 Spell(rushing_jade_wind)
		#rising_sun_kick,cycle_targets=1,if=active_enemies>=3
		if Enemies() >= 3 Spell(rising_sun_kick)
		#rushing_jade_wind,if=!prev_gcd.1.rushing_jade_wind&buff.rushing_jade_wind.down&active_enemies>1
		if not PreviousGCDSpell(rushing_jade_wind) and BuffExpires(rushing_jade_wind_buff) and Enemies() > 1 Spell(rushing_jade_wind)
		#spinning_crane_kick,if=!prev_gcd.1.spinning_crane_kick
		if not PreviousGCDSpell(spinning_crane_kick) Spell(spinning_crane_kick)
		#blackout_kick,cycle_targets=1,if=!prev_gcd.1.blackout_kick
		if not PreviousGCDSpell(blackout_kick) Spell(blackout_kick)
	}
}

AddFunction WindwalkerSerenityMainPostConditions
{
	WindwalkerCdMainPostConditions()
}

AddFunction WindwalkerSerenityShortCdActions
{
	unless not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) and Spell(tiger_palm)
	{
		#call_action_list,name=cd
		WindwalkerCdShortCdActions()

		unless WindwalkerCdShortCdPostConditions()
		{
			#serenity
			Spell(serenity)
		}
	}
}

AddFunction WindwalkerSerenityShortCdPostConditions
{
	not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) and Spell(tiger_palm) or WindwalkerCdShortCdPostConditions() or Enemies() < 3 and Spell(rising_sun_kick) or Spell(strike_of_the_windlord) or not PreviousGCDSpell(blackout_kick) and { PreviousGCDSpell(strike_of_the_windlord) or PreviousGCDSpell(fists_of_fury) } and Enemies() < 2 and Spell(blackout_kick) or HasEquippedItem(drinking_horn_cover) and BuffRemaining(pressure_point_buff) <= 2 and ArmorSetBonus(T20 4) and { SpellCooldown(rising_sun_kick) > 1 or Enemies() > 1 } and Spell(fists_of_fury) or { not HasEquippedItem(drinking_horn_cover) or BuffPresent(burst_haste_buff any=1) or BuffRemaining(serenity_buff) < 1 } and { SpellCooldown(rising_sun_kick) > 1 or Enemies() > 1 } and Spell(fists_of_fury) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(rushing_jade_wind) and BuffExpires(rushing_jade_wind_buff) and BuffRemaining(serenity_buff) >= 4 and Spell(rushing_jade_wind) or Enemies() >= 3 and Spell(rising_sun_kick) or not PreviousGCDSpell(rushing_jade_wind) and BuffExpires(rushing_jade_wind_buff) and Enemies() > 1 and Spell(rushing_jade_wind) or not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick)
}

AddFunction WindwalkerSerenityCdActions
{
	unless not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) and Spell(tiger_palm)
	{
		#call_action_list,name=cd
		WindwalkerCdCdActions()
	}
}

AddFunction WindwalkerSerenityCdPostConditions
{
	not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) and Spell(tiger_palm) or WindwalkerCdCdPostConditions() or Enemies() < 3 and Spell(rising_sun_kick) or Spell(strike_of_the_windlord) or not PreviousGCDSpell(blackout_kick) and { PreviousGCDSpell(strike_of_the_windlord) or PreviousGCDSpell(fists_of_fury) } and Enemies() < 2 and Spell(blackout_kick) or HasEquippedItem(drinking_horn_cover) and BuffRemaining(pressure_point_buff) <= 2 and ArmorSetBonus(T20 4) and { SpellCooldown(rising_sun_kick) > 1 or Enemies() > 1 } and Spell(fists_of_fury) or { not HasEquippedItem(drinking_horn_cover) or BuffPresent(burst_haste_buff any=1) or BuffRemaining(serenity_buff) < 1 } and { SpellCooldown(rising_sun_kick) > 1 or Enemies() > 1 } and Spell(fists_of_fury) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(rushing_jade_wind) and BuffExpires(rushing_jade_wind_buff) and BuffRemaining(serenity_buff) >= 4 and Spell(rushing_jade_wind) or Enemies() >= 3 and Spell(rising_sun_kick) or not PreviousGCDSpell(rushing_jade_wind) and BuffExpires(rushing_jade_wind_buff) and Enemies() > 1 and Spell(rushing_jade_wind) or not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick)
}

### actions.serenity_opener

AddFunction WindwalkerSerenityOpenerMainActions
{
	#tiger_palm,cycle_targets=1,if=!prev_gcd.1.tiger_palm&energy=energy.max&chi<1&!buff.serenity.up&cooldown.fists_of_fury.remains<=0
	if not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) and SpellCooldown(fists_of_fury) <= 0 Spell(tiger_palm)
	#call_action_list,name=cd,if=cooldown.fists_of_fury.remains>1
	if SpellCooldown(fists_of_fury) > 1 WindwalkerCdMainActions()

	unless SpellCooldown(fists_of_fury) > 1 and WindwalkerCdMainPostConditions()
	{
		#rising_sun_kick,cycle_targets=1,if=active_enemies<3&buff.serenity.up
		if Enemies() < 3 and BuffPresent(serenity_buff) Spell(rising_sun_kick)
		#strike_of_the_windlord,if=buff.serenity.up
		if BuffPresent(serenity_buff) Spell(strike_of_the_windlord)
		#blackout_kick,cycle_targets=1,if=(!prev_gcd.1.blackout_kick)&(prev_gcd.1.strike_of_the_windlord)
		if not PreviousGCDSpell(blackout_kick) and PreviousGCDSpell(strike_of_the_windlord) Spell(blackout_kick)
		#fists_of_fury,if=cooldown.rising_sun_kick.remains>1|buff.serenity.down,interrupt=1
		if SpellCooldown(rising_sun_kick) > 1 or BuffExpires(serenity_buff) Spell(fists_of_fury)
	}
}

AddFunction WindwalkerSerenityOpenerMainPostConditions
{
	SpellCooldown(fists_of_fury) > 1 and WindwalkerCdMainPostConditions()
}

AddFunction WindwalkerSerenityOpenerShortCdActions
{
	unless not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) and SpellCooldown(fists_of_fury) <= 0 and Spell(tiger_palm)
	{
		#call_action_list,name=cd,if=cooldown.fists_of_fury.remains>1
		if SpellCooldown(fists_of_fury) > 1 WindwalkerCdShortCdActions()

		unless SpellCooldown(fists_of_fury) > 1 and WindwalkerCdShortCdPostConditions()
		{
			#serenity,if=cooldown.fists_of_fury.remains>1
			if SpellCooldown(fists_of_fury) > 1 Spell(serenity)
		}
	}
}

AddFunction WindwalkerSerenityOpenerShortCdPostConditions
{
	not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) and SpellCooldown(fists_of_fury) <= 0 and Spell(tiger_palm) or SpellCooldown(fists_of_fury) > 1 and WindwalkerCdShortCdPostConditions() or Enemies() < 3 and BuffPresent(serenity_buff) and Spell(rising_sun_kick) or BuffPresent(serenity_buff) and Spell(strike_of_the_windlord) or not PreviousGCDSpell(blackout_kick) and PreviousGCDSpell(strike_of_the_windlord) and Spell(blackout_kick) or { SpellCooldown(rising_sun_kick) > 1 or BuffExpires(serenity_buff) } and Spell(fists_of_fury)
}

AddFunction WindwalkerSerenityOpenerCdActions
{
	unless not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) and SpellCooldown(fists_of_fury) <= 0 and Spell(tiger_palm)
	{
		#arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
		if MaxChi() - Chi() >= 1 and TimeToMaxEnergy() >= 0.5 Spell(arcane_torrent_chi)
		#call_action_list,name=cd,if=cooldown.fists_of_fury.remains>1
		if SpellCooldown(fists_of_fury) > 1 WindwalkerCdCdActions()
	}
}

AddFunction WindwalkerSerenityOpenerCdPostConditions
{
	not PreviousGCDSpell(tiger_palm) and Energy() == MaxEnergy() and Chi() < 1 and not BuffPresent(serenity_buff) and SpellCooldown(fists_of_fury) <= 0 and Spell(tiger_palm) or SpellCooldown(fists_of_fury) > 1 and WindwalkerCdCdPostConditions() or Enemies() < 3 and BuffPresent(serenity_buff) and Spell(rising_sun_kick) or BuffPresent(serenity_buff) and Spell(strike_of_the_windlord) or not PreviousGCDSpell(blackout_kick) and PreviousGCDSpell(strike_of_the_windlord) and Spell(blackout_kick) or { SpellCooldown(rising_sun_kick) > 1 or BuffExpires(serenity_buff) } and Spell(fists_of_fury)
}

### actions.st

AddFunction WindwalkerStMainActions
{
	#call_action_list,name=cd
	WindwalkerCdMainActions()

	unless WindwalkerCdMainPostConditions()
	{
		#tiger_palm,cycle_targets=1,if=!prev_gcd.1.tiger_palm&energy.time_to_max<=0.5&chi.max-chi>=2
		if not PreviousGCDSpell(tiger_palm) and TimeToMaxEnergy() <= 0.5 and MaxChi() - Chi() >= 2 Spell(tiger_palm)
		#strike_of_the_windlord,if=!talent.serenity.enabled|cooldown.serenity.remains>=10
		if not Talent(serenity_talent) or SpellCooldown(serenity) >= 10 Spell(strike_of_the_windlord)
		#rising_sun_kick,cycle_targets=1,if=((chi>=3&energy>=40)|chi>=5)&(!talent.serenity.enabled|cooldown.serenity.remains>=6)
		if { Chi() >= 3 and Energy() >= 40 or Chi() >= 5 } and { not Talent(serenity_talent) or SpellCooldown(serenity) >= 6 } Spell(rising_sun_kick)
		#fists_of_fury,if=talent.serenity.enabled&!equipped.drinking_horn_cover&cooldown.serenity.remains>=5&energy.time_to_max>2
		if Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover) and SpellCooldown(serenity) >= 5 and TimeToMaxEnergy() > 2 Spell(fists_of_fury)
		#fists_of_fury,if=talent.serenity.enabled&equipped.drinking_horn_cover&(cooldown.serenity.remains>=15|cooldown.serenity.remains<=4)&energy.time_to_max>2
		if Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover) and { SpellCooldown(serenity) >= 15 or SpellCooldown(serenity) <= 4 } and TimeToMaxEnergy() > 2 Spell(fists_of_fury)
		#fists_of_fury,if=!talent.serenity.enabled&energy.time_to_max>2
		if not Talent(serenity_talent) and TimeToMaxEnergy() > 2 Spell(fists_of_fury)
		#rising_sun_kick,cycle_targets=1,if=!talent.serenity.enabled|cooldown.serenity.remains>=5
		if not Talent(serenity_talent) or SpellCooldown(serenity) >= 5 Spell(rising_sun_kick)
		#whirling_dragon_punch
		if SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 Spell(whirling_dragon_punch)
		#blackout_kick,cycle_targets=1,if=!prev_gcd.1.blackout_kick&chi.max-chi>=1&set_bonus.tier21_4pc&(!set_bonus.tier19_2pc|talent.serenity.enabled|buff.bok_proc.up)
		if not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and { not ArmorSetBonus(T19 2) or Talent(serenity_talent) or BuffPresent(bok_proc_buff) } Spell(blackout_kick)
		#spinning_crane_kick,if=(active_enemies>=3|(buff.bok_proc.up&chi.max-chi>=0))&!prev_gcd.1.spinning_crane_kick&set_bonus.tier21_4pc
		if { Enemies() >= 3 or BuffPresent(bok_proc_buff) and MaxChi() - Chi() >= 0 } and not PreviousGCDSpell(spinning_crane_kick) and ArmorSetBonus(T21 4) Spell(spinning_crane_kick)
		#crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=19&energy.time_to_max>3
		if HasEquippedItem(the_emperors_capacitor) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 Spell(crackling_jade_lightning)
		#crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=14&cooldown.serenity.remains<13&talent.serenity.enabled&energy.time_to_max>3
		if HasEquippedItem(the_emperors_capacitor) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 Spell(crackling_jade_lightning)
		#spinning_crane_kick,if=active_enemies>=3&!prev_gcd.1.spinning_crane_kick
		if Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) Spell(spinning_crane_kick)
		#rushing_jade_wind,if=chi.max-chi>1&!prev_gcd.1.rushing_jade_wind
		if MaxChi() - Chi() > 1 and not PreviousGCDSpell(rushing_jade_wind) Spell(rushing_jade_wind)
		#blackout_kick,cycle_targets=1,if=(chi>1|buff.bok_proc.up|(talent.energizing_elixir.enabled&cooldown.energizing_elixir.remains<cooldown.fists_of_fury.remains))&((cooldown.rising_sun_kick.remains>1&(!artifact.strike_of_the_windlord.enabled|cooldown.strike_of_the_windlord.remains>1)|chi>2)&(cooldown.fists_of_fury.remains>1|chi>3)|prev_gcd.1.tiger_palm)&!prev_gcd.1.blackout_kick
		if { Chi() > 1 or BuffPresent(bok_proc_buff) or Talent(energizing_elixir_talent) and SpellCooldown(energizing_elixir) < SpellCooldown(fists_of_fury) } and { { SpellCooldown(rising_sun_kick) > 1 and { not HasArtifactTrait(strike_of_the_windlord) or SpellCooldown(strike_of_the_windlord) > 1 } or Chi() > 2 } and { SpellCooldown(fists_of_fury) > 1 or Chi() > 3 } or PreviousGCDSpell(tiger_palm) } and not PreviousGCDSpell(blackout_kick) Spell(blackout_kick)
		#chi_wave,if=energy.time_to_max>1
		if TimeToMaxEnergy() > 1 Spell(chi_wave)
		#chi_burst,if=energy.time_to_max>1
		if TimeToMaxEnergy() > 1 and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
		#tiger_palm,cycle_targets=1,if=!prev_gcd.1.tiger_palm&(chi.max-chi>=2|energy.time_to_max<1)
		if not PreviousGCDSpell(tiger_palm) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 1 } Spell(tiger_palm)
		#chi_wave
		Spell(chi_wave)
		#chi_burst
		if CheckBoxOn(opt_chi_burst) Spell(chi_burst)
	}
}

AddFunction WindwalkerStMainPostConditions
{
	WindwalkerCdMainPostConditions()
}

AddFunction WindwalkerStShortCdActions
{
	#call_action_list,name=cd
	WindwalkerCdShortCdActions()

	unless WindwalkerCdShortCdPostConditions()
	{
		#energizing_elixir,if=chi<=1&(cooldown.rising_sun_kick.remains=0|(artifact.strike_of_the_windlord.enabled&cooldown.strike_of_the_windlord.remains=0)|energy<50)
		if Chi() <= 1 and { not SpellCooldown(rising_sun_kick) > 0 or HasArtifactTrait(strike_of_the_windlord) and not SpellCooldown(strike_of_the_windlord) > 0 or Energy() < 50 } Spell(energizing_elixir)
	}
}

AddFunction WindwalkerStShortCdPostConditions
{
	WindwalkerCdShortCdPostConditions() or not PreviousGCDSpell(tiger_palm) and TimeToMaxEnergy() <= 0.5 and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or { not Talent(serenity_talent) or SpellCooldown(serenity) >= 10 } and Spell(strike_of_the_windlord) or { Chi() >= 3 and Energy() >= 40 or Chi() >= 5 } and { not Talent(serenity_talent) or SpellCooldown(serenity) >= 6 } and Spell(rising_sun_kick) or Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover) and SpellCooldown(serenity) >= 5 and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover) and { SpellCooldown(serenity) >= 15 or SpellCooldown(serenity) <= 4 } and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or not Talent(serenity_talent) and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or { not Talent(serenity_talent) or SpellCooldown(serenity) >= 5 } and Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and { not ArmorSetBonus(T19 2) or Talent(serenity_talent) or BuffPresent(bok_proc_buff) } and Spell(blackout_kick) or { Enemies() >= 3 or BuffPresent(bok_proc_buff) and MaxChi() - Chi() >= 0 } and not PreviousGCDSpell(spinning_crane_kick) and ArmorSetBonus(T21 4) and Spell(spinning_crane_kick) or HasEquippedItem(the_emperors_capacitor) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or HasEquippedItem(the_emperors_capacitor) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or MaxChi() - Chi() > 1 and not PreviousGCDSpell(rushing_jade_wind) and Spell(rushing_jade_wind) or { Chi() > 1 or BuffPresent(bok_proc_buff) or Talent(energizing_elixir_talent) and SpellCooldown(energizing_elixir) < SpellCooldown(fists_of_fury) } and { { SpellCooldown(rising_sun_kick) > 1 and { not HasArtifactTrait(strike_of_the_windlord) or SpellCooldown(strike_of_the_windlord) > 1 } or Chi() > 2 } and { SpellCooldown(fists_of_fury) > 1 or Chi() > 3 } or PreviousGCDSpell(tiger_palm) } and not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick) or TimeToMaxEnergy() > 1 and Spell(chi_wave) or TimeToMaxEnergy() > 1 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or not PreviousGCDSpell(tiger_palm) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 1 } and Spell(tiger_palm) or Spell(chi_wave) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst)
}

AddFunction WindwalkerStCdActions
{
	#call_action_list,name=cd
	WindwalkerCdCdActions()

	unless WindwalkerCdCdPostConditions()
	{
		#arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
		if MaxChi() - Chi() >= 1 and TimeToMaxEnergy() >= 0.5 Spell(arcane_torrent_chi)
	}
}

AddFunction WindwalkerStCdPostConditions
{
	WindwalkerCdCdPostConditions() or not PreviousGCDSpell(tiger_palm) and TimeToMaxEnergy() <= 0.5 and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or { not Talent(serenity_talent) or SpellCooldown(serenity) >= 10 } and Spell(strike_of_the_windlord) or { Chi() >= 3 and Energy() >= 40 or Chi() >= 5 } and { not Talent(serenity_talent) or SpellCooldown(serenity) >= 6 } and Spell(rising_sun_kick) or Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover) and SpellCooldown(serenity) >= 5 and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover) and { SpellCooldown(serenity) >= 15 or SpellCooldown(serenity) <= 4 } and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or not Talent(serenity_talent) and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or { not Talent(serenity_talent) or SpellCooldown(serenity) >= 5 } and Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or not PreviousGCDSpell(blackout_kick) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and { not ArmorSetBonus(T19 2) or Talent(serenity_talent) or BuffPresent(bok_proc_buff) } and Spell(blackout_kick) or { Enemies() >= 3 or BuffPresent(bok_proc_buff) and MaxChi() - Chi() >= 0 } and not PreviousGCDSpell(spinning_crane_kick) and ArmorSetBonus(T21 4) and Spell(spinning_crane_kick) or HasEquippedItem(the_emperors_capacitor) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or HasEquippedItem(the_emperors_capacitor) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or MaxChi() - Chi() > 1 and not PreviousGCDSpell(rushing_jade_wind) and Spell(rushing_jade_wind) or { Chi() > 1 or BuffPresent(bok_proc_buff) or Talent(energizing_elixir_talent) and SpellCooldown(energizing_elixir) < SpellCooldown(fists_of_fury) } and { { SpellCooldown(rising_sun_kick) > 1 and { not HasArtifactTrait(strike_of_the_windlord) or SpellCooldown(strike_of_the_windlord) > 1 } or Chi() > 2 } and { SpellCooldown(fists_of_fury) > 1 or Chi() > 3 } or PreviousGCDSpell(tiger_palm) } and not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick) or TimeToMaxEnergy() > 1 and Spell(chi_wave) or TimeToMaxEnergy() > 1 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or not PreviousGCDSpell(tiger_palm) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 1 } and Spell(tiger_palm) or Spell(chi_wave) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst)
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
# arcane_torrent_chi
# berserking
# blackout_kick
# blood_fury_apsp
# bok_proc_buff
# chi_burst
# chi_wave
# crackling_jade_lightning
# drinking_horn_cover
# energizing_elixir
# energizing_elixir_talent
# fists_of_fury
# gale_burst
# hidden_masters_forbidden_touch
# hidden_masters_forbidden_touch_buff
# invoke_xuen_the_white_tiger
# katsuos_eclipse
# leg_sweep
# paralysis
# power_strikes_talent
# pressure_point_buff
# prolonged_power_potion
# quaking_palm
# rising_sun_kick
# rushing_jade_wind
# rushing_jade_wind_buff
# serenity
# serenity_buff
# serenity_talent
# spear_hand_strike
# specter_of_betrayal
# spinning_crane_kick
# storm_earth_and_fire
# storm_earth_and_fire_buff
# strike_of_the_windlord
# the_emperors_capacitor
# the_emperors_capacitor_buff
# tiger_palm
# touch_of_death
# touch_of_death_debuff
# touch_of_karma
# war_stomp
# whirling_dragon_punch
]]
	OvaleScripts:RegisterScript("MONK", "windwalker", name, desc, code, "script")
end
