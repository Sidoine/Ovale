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
AddCheckBox(opt_legendary_ring_tank ItemName(legendary_ring_bonus_armor) default specialization=brewmaster)
AddCheckBox(opt_monk_bm_aoe L(AOE) default specialization=brewmaster)

AddFunction BrewmasterExpelHarmOffensivelyPreConditions
{
	(SpellCount(expel_harm) >= 3 and (SpellCount(expel_harm) * 7.5 * AttackPower() * 2.65) <= HealthMissing()) and Spell(expel_harm)
}

AddFunction BrewmasterHealMe
{
	if (HealthPercent() < 35) Spell(healing_elixir)
	if (SpellCount(expel_harm) >= 1 and HealthPercent() < 35) Spell(expel_harm)
	if (HealthPercent() <= 100 - (15 * 2.6)) Spell(healing_elixir)
}

AddFunction BrewmasterDefaultShortCDActions
{
	# always purify red stagger
	if (DebuffPresent(heavy_stagger_debuff) and SpellCharges(purifying_brew) > 0) Spell(purifying_brew)
	# use black_ox_brew when at 0 charges but delay it when a charge is about to come off cd
	if ((SpellCharges(purifying_brew) == 0) and (SpellChargeCooldown(purifying_brew) > 2 or DebuffPresent(heavy_stagger_debuff))) Spell(black_ox_brew)
	# heal me
	BrewmasterHealMe()
	# range check
	if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
	
	unless DebuffPresent(heavy_stagger_debuff) or BrewmasterHealMe() or StaggerRemaining() == 0
	{
		# purify moderate stagger
		if (DebuffPresent(moderate_stagger_debuff) and (not Talent(elusive_dance_talent) or not BuffPresent(elusive_dance_buff))) Spell(purifying_brew)
		# always keep 1 charge unless black_ox_brew is coming off cd
		unless not (SpellCharges(ironskin_brew) > 1 or SpellCooldown(black_ox_brew) <= 3)
		{
			# keep elusive dance up
			if (Talent(elusive_dance_talent) and (BuffAmount(elusive_dance_buff value=3) < 10 and DebuffPresent(moderate_stagger_debuff))) Spell(purifying_brew)
			if (Talent(elusive_dance_talent) and (BuffAmount(elusive_dance_buff value=3) <  5 and StaggerRemaining() > 0)) Spell(purifying_brew)
			# never be at max charges 
			if (SpellCharges(ironskin_brew) >= SpellMaxCharges(ironskin_brew)) Spell(ironskin_brew)
			if (SpellCharges(ironskin_brew) >= SpellMaxCharges(ironskin_brew)-1 and (SpellChargeCooldown(ironskin_brew) <= 2 or SpellChargeCooldown(ironskin_brew) <= SpellCooldown(keg_smash))) Spell(ironskin_brew)
			# use up those charges when black_ox_brew_talent comes off cd
			if (Talent(black_ox_brew_talent) and SpellCooldown(black_ox_brew) <= 3) Spell(ironskin_brew)
			# keep brew-stache rolling
			if (HasArtifactTrait(brew_stache_trait) and not BuffPresent(brew_stache_buff)) Spell(ironskin_brew text=stache)
			# keep up ironskin_brew_buff but keep 2 charges ready for purifying when elusive_dance_talent
			if (BuffExpires(ironskin_brew_buff 2) and (not Talent(elusive_dance_talent) or SpellCharges(purifying_brew) >= 2)) Spell(ironskin_brew)
		}
	}
}

#
# Single-Target
#

AddFunction BrewmasterDefaultMainActions
{
	Spell(keg_smash)
	if EnergyDeficit() <= 35 Spell(tiger_palm)
	unless EnergyDeficit() <= 35
	{
		Spell(blackout_strike)
		Spell(rushing_jade_wind)
		if target.DebuffPresent(keg_smash_debuff) Spell(breath_of_fire)
		Spell(exploding_keg)
		Spell(chi_burst)
		Spell(chi_wave)
		if BrewmasterExpelHarmOffensivelyPreConditions() Spell(expel_harm)
	}
}

AddFunction BrewmasterBlackoutComboMainActions
{
	if(not BuffPresent(blackout_combo_buff)) Spell(blackout_strike)
	if(BuffPresent(blackout_combo_buff)) 
	{
		Spell(keg_smash)
		unless (SpellCooldown(keg_smash) < GCD())
		{
			Spell(breath_of_fire)
			Spell(tiger_palm)
		}
	}
	
	unless (BuffPresent(blackout_combo_buff)) 
	{
		Spell(rushing_jade_wind)
		Spell(chi_burst)
		Spell(chi_wave)
		if EnergyDeficit() <= 35 Spell(tiger_palm)
		unless EnergyDeficit() <= 35
		{
			if BrewmasterExpelHarmOffensivelyPreConditions() Spell(expel_harm)
			Spell(exploding_keg)
		}
	}
}

#
# AOE
#

AddFunction BrewmasterDefaultAoEActions
{
	Spell(exploding_keg)
	Spell(keg_smash)
	Spell(chi_burst)
	Spell(chi_wave)
	if target.DebuffPresent(keg_smash_debuff) Spell(breath_of_fire)
	Spell(rushing_jade_wind)
	if EnergyDeficit() <= 35 Spell(tiger_palm)
	unless EnergyDeficit() <= 35
	{
		Spell(blackout_strike)
		if BrewmasterExpelHarmOffensivelyPreConditions() Spell(expel_harm)
	}
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
		unless EnergyDeficit() <= 35
		{
			if BrewmasterExpelHarmOffensivelyPreConditions() Spell(expel_harm)
		}
	}
}

AddFunction BrewmasterDefaultCdActions 
{
	BrewmasterInterruptActions()
	if CheckBoxOn(opt_legendary_ring_tank) Item(legendary_ring_bonus_armor usable=1)
	Spell(fortifying_brew)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
	Spell(zen_meditation)
	Spell(dampen_harm)
	Spell(diffuse_magic)
}

AddFunction BrewmasterInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(spear_hand_strike) Spell(spear_hand_strike)
		if not target.Classification(worldboss)
		{
			if target.Distance(less 8) Spell(arcane_torrent_chi)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			if target.Distance(less 8) Spell(war_stomp)
			if target.Distance(less 5) Spell(leg_sweep)
		}
		if target.IsTargetingPlayer() 
		{
			Spell(diffuse_magic)
			Spell(zen_meditation)
			Spell(dampen_harm)
		}
	}
}

AddIcon help=shortcd specialization=brewmaster
{
	BrewmasterDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=brewmaster
{
	if Talent(blackout_combo_talent) BrewmasterBlackoutComboMainActions()
	unless Talent(blackout_combo_talent) 
	{
		BrewmasterDefaultMainActions()
	}
}

AddIcon checkbox=opt_monk_bm_aoe help=aoe specialization=brewmaster
{
	if Talent(blackout_combo_talent) BrewmasterBlackoutComboAoEActions()
	unless Talent(blackout_combo_talent) 
	{
		BrewmasterDefaultAoEActions()
	}
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
AddCheckBox(opt_chi_burst SpellName(chi_burst) default specialization=windwalker)
AddCheckBox(opt_storm_earth_and_fire SpellName(storm_earth_and_fire) specialization=windwalker)

AddFunction WindwalkerGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction WindwalkerInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(spear_hand_strike) Spell(spear_hand_strike)
		if not target.Classification(worldboss)
		{
			if target.InRange(paralysis) Spell(paralysis)
			Spell(arcane_torrent_chi)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			Spell(war_stomp)
		}
	}
}

### actions.default

AddFunction WindwalkerDefaultMainActions
{
	#potion,name=old_war,if=buff.serenity.up|buff.storm_earth_and_fire.up|(!talent.serenity.enabled&trinket.proc.agility.react)|buff.bloodlust.react|target.time_to_die<=60
	#call_action_list,name=serenity,if=talent.serenity.enabled&((artifact.strike_of_the_windlord.enabled&cooldown.strike_of_the_windlord.remains<=14&cooldown.rising_sun_kick.remains<=4)|buff.serenity.up)
	if Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(rising_sun_kick) <= 4 or BuffPresent(serenity_buff) } WindwalkerSerenityMainActions()

	unless Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(rising_sun_kick) <= 4 or BuffPresent(serenity_buff) } and WindwalkerSerenityMainPostConditions()
	{
		#call_action_list,name=sef,if=!talent.serenity.enabled&((artifact.strike_of_the_windlord.enabled&cooldown.strike_of_the_windlord.remains<=14&cooldown.fists_of_fury.remains<=6&cooldown.rising_sun_kick.remains<=6)|buff.storm_earth_and_fire.up)
		if not Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and SpellCooldown(rising_sun_kick) <= 6 or BuffPresent(storm_earth_and_fire_buff) } WindwalkerSefMainActions()

		unless not Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and SpellCooldown(rising_sun_kick) <= 6 or BuffPresent(storm_earth_and_fire_buff) } and WindwalkerSefMainPostConditions()
		{
			#call_action_list,name=serenity,if=(!artifact.strike_of_the_windlord.enabled&cooldown.strike_of_the_windlord.remains<14&cooldown.fists_of_fury.remains<=15&cooldown.rising_sun_kick.remains<7)|buff.serenity.up
			if not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) < 14 and SpellCooldown(fists_of_fury) <= 15 and SpellCooldown(rising_sun_kick) < 7 or BuffPresent(serenity_buff) WindwalkerSerenityMainActions()

			unless { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) < 14 and SpellCooldown(fists_of_fury) <= 15 and SpellCooldown(rising_sun_kick) < 7 or BuffPresent(serenity_buff) } and WindwalkerSerenityMainPostConditions()
			{
				#call_action_list,name=sef,if=!talent.serenity.enabled&((!artifact.strike_of_the_windlord.enabled&cooldown.fists_of_fury.remains<=9&cooldown.rising_sun_kick.remains<=5)|buff.storm_earth_and_fire.up)
				if not Talent(serenity_talent) and { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(fists_of_fury) <= 9 and SpellCooldown(rising_sun_kick) <= 5 or BuffPresent(storm_earth_and_fire_buff) } WindwalkerSefMainActions()

				unless not Talent(serenity_talent) and { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(fists_of_fury) <= 9 and SpellCooldown(rising_sun_kick) <= 5 or BuffPresent(storm_earth_and_fire_buff) } and WindwalkerSefMainPostConditions()
				{
					#call_action_list,name=st
					WindwalkerStMainActions()
				}
			}
		}
	}
}

AddFunction WindwalkerDefaultMainPostConditions
{
	Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(rising_sun_kick) <= 4 or BuffPresent(serenity_buff) } and WindwalkerSerenityMainPostConditions() or not Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and SpellCooldown(rising_sun_kick) <= 6 or BuffPresent(storm_earth_and_fire_buff) } and WindwalkerSefMainPostConditions() or { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) < 14 and SpellCooldown(fists_of_fury) <= 15 and SpellCooldown(rising_sun_kick) < 7 or BuffPresent(serenity_buff) } and WindwalkerSerenityMainPostConditions() or not Talent(serenity_talent) and { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(fists_of_fury) <= 9 and SpellCooldown(rising_sun_kick) <= 5 or BuffPresent(storm_earth_and_fire_buff) } and WindwalkerSefMainPostConditions() or WindwalkerStMainPostConditions()
}

AddFunction WindwalkerDefaultShortCdActions
{
	#auto_attack
	WindwalkerGetInMeleeRange()
	#potion,name=old_war,if=buff.serenity.up|buff.storm_earth_and_fire.up|(!talent.serenity.enabled&trinket.proc.agility.react)|buff.bloodlust.react|target.time_to_die<=60
	#call_action_list,name=serenity,if=talent.serenity.enabled&((artifact.strike_of_the_windlord.enabled&cooldown.strike_of_the_windlord.remains<=14&cooldown.rising_sun_kick.remains<=4)|buff.serenity.up)
	if Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(rising_sun_kick) <= 4 or BuffPresent(serenity_buff) } WindwalkerSerenityShortCdActions()

	unless Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(rising_sun_kick) <= 4 or BuffPresent(serenity_buff) } and WindwalkerSerenityShortCdPostConditions()
	{
		#call_action_list,name=sef,if=!talent.serenity.enabled&((artifact.strike_of_the_windlord.enabled&cooldown.strike_of_the_windlord.remains<=14&cooldown.fists_of_fury.remains<=6&cooldown.rising_sun_kick.remains<=6)|buff.storm_earth_and_fire.up)
		if not Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and SpellCooldown(rising_sun_kick) <= 6 or BuffPresent(storm_earth_and_fire_buff) } WindwalkerSefShortCdActions()

		unless not Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and SpellCooldown(rising_sun_kick) <= 6 or BuffPresent(storm_earth_and_fire_buff) } and WindwalkerSefShortCdPostConditions()
		{
			#call_action_list,name=serenity,if=(!artifact.strike_of_the_windlord.enabled&cooldown.strike_of_the_windlord.remains<14&cooldown.fists_of_fury.remains<=15&cooldown.rising_sun_kick.remains<7)|buff.serenity.up
			if not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) < 14 and SpellCooldown(fists_of_fury) <= 15 and SpellCooldown(rising_sun_kick) < 7 or BuffPresent(serenity_buff) WindwalkerSerenityShortCdActions()

			unless { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) < 14 and SpellCooldown(fists_of_fury) <= 15 and SpellCooldown(rising_sun_kick) < 7 or BuffPresent(serenity_buff) } and WindwalkerSerenityShortCdPostConditions()
			{
				#call_action_list,name=sef,if=!talent.serenity.enabled&((!artifact.strike_of_the_windlord.enabled&cooldown.fists_of_fury.remains<=9&cooldown.rising_sun_kick.remains<=5)|buff.storm_earth_and_fire.up)
				if not Talent(serenity_talent) and { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(fists_of_fury) <= 9 and SpellCooldown(rising_sun_kick) <= 5 or BuffPresent(storm_earth_and_fire_buff) } WindwalkerSefShortCdActions()

				unless not Talent(serenity_talent) and { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(fists_of_fury) <= 9 and SpellCooldown(rising_sun_kick) <= 5 or BuffPresent(storm_earth_and_fire_buff) } and WindwalkerSefShortCdPostConditions()
				{
					#call_action_list,name=st
					WindwalkerStShortCdActions()
				}
			}
		}
	}
}

AddFunction WindwalkerDefaultShortCdPostConditions
{
	Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(rising_sun_kick) <= 4 or BuffPresent(serenity_buff) } and WindwalkerSerenityShortCdPostConditions() or not Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and SpellCooldown(rising_sun_kick) <= 6 or BuffPresent(storm_earth_and_fire_buff) } and WindwalkerSefShortCdPostConditions() or { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) < 14 and SpellCooldown(fists_of_fury) <= 15 and SpellCooldown(rising_sun_kick) < 7 or BuffPresent(serenity_buff) } and WindwalkerSerenityShortCdPostConditions() or not Talent(serenity_talent) and { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(fists_of_fury) <= 9 and SpellCooldown(rising_sun_kick) <= 5 or BuffPresent(storm_earth_and_fire_buff) } and WindwalkerSefShortCdPostConditions() or WindwalkerStShortCdPostConditions()
}

AddFunction WindwalkerDefaultCdActions
{
	#spear_hand_strike,if=target.debuff.casting.react
	if target.IsInterruptible() WindwalkerInterruptActions()
	#potion,name=old_war,if=buff.serenity.up|buff.storm_earth_and_fire.up|(!talent.serenity.enabled&trinket.proc.agility.react)|buff.bloodlust.react|target.time_to_die<=60
	#call_action_list,name=serenity,if=talent.serenity.enabled&((artifact.strike_of_the_windlord.enabled&cooldown.strike_of_the_windlord.remains<=14&cooldown.rising_sun_kick.remains<=4)|buff.serenity.up)
	if Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(rising_sun_kick) <= 4 or BuffPresent(serenity_buff) } WindwalkerSerenityCdActions()

	unless Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(rising_sun_kick) <= 4 or BuffPresent(serenity_buff) } and WindwalkerSerenityCdPostConditions()
	{
		#call_action_list,name=sef,if=!talent.serenity.enabled&((artifact.strike_of_the_windlord.enabled&cooldown.strike_of_the_windlord.remains<=14&cooldown.fists_of_fury.remains<=6&cooldown.rising_sun_kick.remains<=6)|buff.storm_earth_and_fire.up)
		if not Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and SpellCooldown(rising_sun_kick) <= 6 or BuffPresent(storm_earth_and_fire_buff) } WindwalkerSefCdActions()

		unless not Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and SpellCooldown(rising_sun_kick) <= 6 or BuffPresent(storm_earth_and_fire_buff) } and WindwalkerSefCdPostConditions()
		{
			#call_action_list,name=serenity,if=(!artifact.strike_of_the_windlord.enabled&cooldown.strike_of_the_windlord.remains<14&cooldown.fists_of_fury.remains<=15&cooldown.rising_sun_kick.remains<7)|buff.serenity.up
			if not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) < 14 and SpellCooldown(fists_of_fury) <= 15 and SpellCooldown(rising_sun_kick) < 7 or BuffPresent(serenity_buff) WindwalkerSerenityCdActions()

			unless { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) < 14 and SpellCooldown(fists_of_fury) <= 15 and SpellCooldown(rising_sun_kick) < 7 or BuffPresent(serenity_buff) } and WindwalkerSerenityCdPostConditions()
			{
				#call_action_list,name=sef,if=!talent.serenity.enabled&((!artifact.strike_of_the_windlord.enabled&cooldown.fists_of_fury.remains<=9&cooldown.rising_sun_kick.remains<=5)|buff.storm_earth_and_fire.up)
				if not Talent(serenity_talent) and { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(fists_of_fury) <= 9 and SpellCooldown(rising_sun_kick) <= 5 or BuffPresent(storm_earth_and_fire_buff) } WindwalkerSefCdActions()

				unless not Talent(serenity_talent) and { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(fists_of_fury) <= 9 and SpellCooldown(rising_sun_kick) <= 5 or BuffPresent(storm_earth_and_fire_buff) } and WindwalkerSefCdPostConditions()
				{
					#call_action_list,name=st
					WindwalkerStCdActions()
				}
			}
		}
	}
}

AddFunction WindwalkerDefaultCdPostConditions
{
	Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(rising_sun_kick) <= 4 or BuffPresent(serenity_buff) } and WindwalkerSerenityCdPostConditions() or not Talent(serenity_talent) and { HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) <= 14 and SpellCooldown(fists_of_fury) <= 6 and SpellCooldown(rising_sun_kick) <= 6 or BuffPresent(storm_earth_and_fire_buff) } and WindwalkerSefCdPostConditions() or { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(strike_of_the_windlord) < 14 and SpellCooldown(fists_of_fury) <= 15 and SpellCooldown(rising_sun_kick) < 7 or BuffPresent(serenity_buff) } and WindwalkerSerenityCdPostConditions() or not Talent(serenity_talent) and { not HasArtifactTrait(strike_of_the_windlord) and SpellCooldown(fists_of_fury) <= 9 and SpellCooldown(rising_sun_kick) <= 5 or BuffPresent(storm_earth_and_fire_buff) } and WindwalkerSefCdPostConditions() or WindwalkerStCdPostConditions()
}

### actions.cd

AddFunction WindwalkerCdMainActions
{
}

AddFunction WindwalkerCdMainPostConditions
{
}

AddFunction WindwalkerCdShortCdActions
{
}

AddFunction WindwalkerCdShortCdPostConditions
{
}

AddFunction WindwalkerCdCdActions
{
	#invoke_xuen
	Spell(invoke_xuen)
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#touch_of_death,cycle_targets=1,max_cycle_targets=2,if=!artifact.gale_burst.enabled&equipped.137057&!prev_gcd.touch_of_death
	if DebuffCountOnAny(touch_of_death_debuff) < Enemies() and DebuffCountOnAny(touch_of_death_debuff) <= 2 and not HasArtifactTrait(gale_burst) and HasEquippedItem(137057) and not PreviousGCDSpell(touch_of_death) Spell(touch_of_death)
	#touch_of_death,if=!artifact.gale_burst.enabled&!equipped.137057
	if not HasArtifactTrait(gale_burst) and not HasEquippedItem(137057) Spell(touch_of_death)
	#touch_of_death,cycle_targets=1,max_cycle_targets=2,if=artifact.gale_burst.enabled&equipped.137057&cooldown.strike_of_the_windlord.remains<8&cooldown.fists_of_fury.remains<=4&cooldown.rising_sun_kick.remains<7&!prev_gcd.touch_of_death
	if DebuffCountOnAny(touch_of_death_debuff) < Enemies() and DebuffCountOnAny(touch_of_death_debuff) <= 2 and HasArtifactTrait(gale_burst) and HasEquippedItem(137057) and SpellCooldown(strike_of_the_windlord) < 8 and SpellCooldown(fists_of_fury) <= 4 and SpellCooldown(rising_sun_kick) < 7 and not PreviousGCDSpell(touch_of_death) Spell(touch_of_death)
	#touch_of_death,if=artifact.gale_burst.enabled&!equipped.137057&cooldown.strike_of_the_windlord.remains<8&cooldown.fists_of_fury.remains<=4&cooldown.rising_sun_kick.remains<7
	if HasArtifactTrait(gale_burst) and not HasEquippedItem(137057) and SpellCooldown(strike_of_the_windlord) < 8 and SpellCooldown(fists_of_fury) <= 4 and SpellCooldown(rising_sun_kick) < 7 Spell(touch_of_death)
}

AddFunction WindwalkerCdCdPostConditions
{
}

### actions.precombat

AddFunction WindwalkerPrecombatMainActions
{
	#flask,type=flask_of_the_seventh_demon
	#food,type=fishbrul_special
	#augmentation,type=defiled
	Spell(augmentation)
}

AddFunction WindwalkerPrecombatMainPostConditions
{
}

AddFunction WindwalkerPrecombatShortCdActions
{
}

AddFunction WindwalkerPrecombatShortCdPostConditions
{
	Spell(augmentation)
}

AddFunction WindwalkerPrecombatCdActions
{
}

AddFunction WindwalkerPrecombatCdPostConditions
{
	Spell(augmentation)
}

### actions.sef

AddFunction WindwalkerSefMainActions
{
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
	#energizing_elixir
	Spell(energizing_elixir)
	#call_action_list,name=cd
	WindwalkerCdShortCdActions()

	unless WindwalkerCdShortCdPostConditions()
	{
		#storm_earth_and_fire
		if CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff) Spell(storm_earth_and_fire)
		#call_action_list,name=st
		WindwalkerStShortCdActions()
	}
}

AddFunction WindwalkerSefShortCdPostConditions
{
	WindwalkerCdShortCdPostConditions() or WindwalkerStShortCdPostConditions()
}

AddFunction WindwalkerSefCdActions
{
	#arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
	if MaxChi() - Chi() >= 1 and TimeToMaxEnergy() >= 0.5 Spell(arcane_torrent_chi)
	#call_action_list,name=cd
	WindwalkerCdCdActions()

	unless WindwalkerCdCdPostConditions() or CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff) and Spell(storm_earth_and_fire)
	{
		#call_action_list,name=st
		WindwalkerStCdActions()
	}
}

AddFunction WindwalkerSefCdPostConditions
{
	WindwalkerCdCdPostConditions() or CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff) and Spell(storm_earth_and_fire) or WindwalkerStCdPostConditions()
}

### actions.serenity

AddFunction WindwalkerSerenityMainActions
{
	#call_action_list,name=cd
	WindwalkerCdMainActions()

	unless WindwalkerCdMainPostConditions()
	{
		#strike_of_the_windlord
		Spell(strike_of_the_windlord)
		#rising_sun_kick,cycle_targets=1,if=active_enemies<3
		if Enemies() < 3 Spell(rising_sun_kick)
		#fists_of_fury
		Spell(fists_of_fury)
		#spinning_crane_kick,if=active_enemies>=3&!prev_gcd.spinning_crane_kick
		if Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) Spell(spinning_crane_kick)
		#rising_sun_kick,cycle_targets=1,if=active_enemies>=3
		if Enemies() >= 3 Spell(rising_sun_kick)
		#blackout_kick,cycle_targets=1,if=!prev_gcd.blackout_kick
		if not PreviousGCDSpell(blackout_kick) Spell(blackout_kick)
		#spinning_crane_kick,if=!prev_gcd.spinning_crane_kick
		if not PreviousGCDSpell(spinning_crane_kick) Spell(spinning_crane_kick)
		#rushing_jade_wind,if=!prev_gcd.rushing_jade_wind
		if not PreviousGCDSpell(rushing_jade_wind) Spell(rushing_jade_wind)
	}
}

AddFunction WindwalkerSerenityMainPostConditions
{
	WindwalkerCdMainPostConditions()
}

AddFunction WindwalkerSerenityShortCdActions
{
	#energizing_elixir
	Spell(energizing_elixir)
	#call_action_list,name=cd
	WindwalkerCdShortCdActions()

	unless WindwalkerCdShortCdPostConditions()
	{
		#serenity
		Spell(serenity)
	}
}

AddFunction WindwalkerSerenityShortCdPostConditions
{
	WindwalkerCdShortCdPostConditions() or Spell(strike_of_the_windlord) or Enemies() < 3 and Spell(rising_sun_kick) or Spell(fists_of_fury) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or Enemies() >= 3 and Spell(rising_sun_kick) or not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick) or not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(rushing_jade_wind) and Spell(rushing_jade_wind)
}

AddFunction WindwalkerSerenityCdActions
{
	#call_action_list,name=cd
	WindwalkerCdCdActions()
}

AddFunction WindwalkerSerenityCdPostConditions
{
	WindwalkerCdCdPostConditions() or Spell(strike_of_the_windlord) or Enemies() < 3 and Spell(rising_sun_kick) or Spell(fists_of_fury) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or Enemies() >= 3 and Spell(rising_sun_kick) or not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick) or not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(rushing_jade_wind) and Spell(rushing_jade_wind)
}

### actions.st

AddFunction WindwalkerStMainActions
{
	#call_action_list,name=cd
	WindwalkerCdMainActions()

	unless WindwalkerCdMainPostConditions()
	{
		#strike_of_the_windlord,if=talent.serenity.enabled|active_enemies<6
		if Talent(serenity_talent) or Enemies() < 6 Spell(strike_of_the_windlord)
		#fists_of_fury
		Spell(fists_of_fury)
		#rising_sun_kick,cycle_targets=1
		Spell(rising_sun_kick)
		#whirling_dragon_punch
		if SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 Spell(whirling_dragon_punch)
		#spinning_crane_kick,if=active_enemies>=3&!prev_gcd.spinning_crane_kick
		if Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) Spell(spinning_crane_kick)
		#rushing_jade_wind,if=chi.max-chi>1&!prev_gcd.rushing_jade_wind
		if MaxChi() - Chi() > 1 and not PreviousGCDSpell(rushing_jade_wind) Spell(rushing_jade_wind)
		#blackout_kick,cycle_targets=1,if=(chi>1|buff.bok_proc.up)&!prev_gcd.blackout_kick
		if { Chi() > 1 or BuffPresent(bok_proc_buff) } and not PreviousGCDSpell(blackout_kick) Spell(blackout_kick)
		#chi_wave,if=energy.time_to_max>=2.25
		if TimeToMaxEnergy() >= 2.25 Spell(chi_wave)
		#tiger_palm,cycle_targets=1,if=!prev_gcd.tiger_palm
		if not PreviousGCDSpell(tiger_palm) Spell(tiger_palm)
		#crackling_jade_lightning,interrupt=1,if=talent.rushing_jade_wind.enabled&chi.max-chi=1&prev_gcd.blackout_kick&cooldown.rising_sun_kick.remains>1&cooldown.fists_of_fury.remains>1&cooldown.strike_of_the_windlord.remains>1&cooldown.rushing_jade_wind.remains>1
		if Talent(rushing_jade_wind_talent) and MaxChi() - Chi() == 1 and PreviousGCDSpell(blackout_kick) and SpellCooldown(rising_sun_kick) > 1 and SpellCooldown(fists_of_fury) > 1 and SpellCooldown(strike_of_the_windlord) > 1 and SpellCooldown(rushing_jade_wind) > 1 Spell(crackling_jade_lightning)
		#crackling_jade_lightning,interrupt=1,if=!talent.rushing_jade_wind.enabled&chi.max-chi=1&prev_gcd.blackout_kick&cooldown.rising_sun_kick.remains>1&cooldown.fists_of_fury.remains>1&cooldown.strike_of_the_windlord.remains>1
		if not Talent(rushing_jade_wind_talent) and MaxChi() - Chi() == 1 and PreviousGCDSpell(blackout_kick) and SpellCooldown(rising_sun_kick) > 1 and SpellCooldown(fists_of_fury) > 1 and SpellCooldown(strike_of_the_windlord) > 1 Spell(crackling_jade_lightning)
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
		#energizing_elixir,if=energy<energy.max&chi<=1
		if Energy() < MaxEnergy() and Chi() <= 1 Spell(energizing_elixir)

		unless { Talent(serenity_talent) or Enemies() < 6 } and Spell(strike_of_the_windlord) or Spell(fists_of_fury) or Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or MaxChi() - Chi() > 1 and not PreviousGCDSpell(rushing_jade_wind) and Spell(rushing_jade_wind) or { Chi() > 1 or BuffPresent(bok_proc_buff) } and not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick) or TimeToMaxEnergy() >= 2.25 and Spell(chi_wave)
		{
			#chi_burst,if=energy.time_to_max>=2.25
			if TimeToMaxEnergy() >= 2.25 and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
		}
	}
}

AddFunction WindwalkerStShortCdPostConditions
{
	WindwalkerCdShortCdPostConditions() or { Talent(serenity_talent) or Enemies() < 6 } and Spell(strike_of_the_windlord) or Spell(fists_of_fury) or Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or MaxChi() - Chi() > 1 and not PreviousGCDSpell(rushing_jade_wind) and Spell(rushing_jade_wind) or { Chi() > 1 or BuffPresent(bok_proc_buff) } and not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick) or TimeToMaxEnergy() >= 2.25 and Spell(chi_wave) or not PreviousGCDSpell(tiger_palm) and Spell(tiger_palm) or Talent(rushing_jade_wind_talent) and MaxChi() - Chi() == 1 and PreviousGCDSpell(blackout_kick) and SpellCooldown(rising_sun_kick) > 1 and SpellCooldown(fists_of_fury) > 1 and SpellCooldown(strike_of_the_windlord) > 1 and SpellCooldown(rushing_jade_wind) > 1 and Spell(crackling_jade_lightning) or not Talent(rushing_jade_wind_talent) and MaxChi() - Chi() == 1 and PreviousGCDSpell(blackout_kick) and SpellCooldown(rising_sun_kick) > 1 and SpellCooldown(fists_of_fury) > 1 and SpellCooldown(strike_of_the_windlord) > 1 and Spell(crackling_jade_lightning)
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
	WindwalkerCdCdPostConditions() or { Talent(serenity_talent) or Enemies() < 6 } and Spell(strike_of_the_windlord) or Spell(fists_of_fury) or Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or MaxChi() - Chi() > 1 and not PreviousGCDSpell(rushing_jade_wind) and Spell(rushing_jade_wind) or { Chi() > 1 or BuffPresent(bok_proc_buff) } and not PreviousGCDSpell(blackout_kick) and Spell(blackout_kick) or TimeToMaxEnergy() >= 2.25 and Spell(chi_wave) or TimeToMaxEnergy() >= 2.25 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or not PreviousGCDSpell(tiger_palm) and Spell(tiger_palm) or Talent(rushing_jade_wind_talent) and MaxChi() - Chi() == 1 and PreviousGCDSpell(blackout_kick) and SpellCooldown(rising_sun_kick) > 1 and SpellCooldown(fists_of_fury) > 1 and SpellCooldown(strike_of_the_windlord) > 1 and SpellCooldown(rushing_jade_wind) > 1 and Spell(crackling_jade_lightning) or not Talent(rushing_jade_wind_talent) and MaxChi() - Chi() == 1 and PreviousGCDSpell(blackout_kick) and SpellCooldown(rising_sun_kick) > 1 and SpellCooldown(fists_of_fury) > 1 and SpellCooldown(strike_of_the_windlord) > 1 and Spell(crackling_jade_lightning)
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
# 137057
# arcane_torrent_chi
# augmentation
# berserking
# blackout_kick
# blood_fury_apsp
# bok_proc_buff
# chi_burst
# chi_wave
# crackling_jade_lightning
# energizing_elixir
# fists_of_fury
# gale_burst
# invoke_xuen
# paralysis
# quaking_palm
# rising_sun_kick
# rushing_jade_wind
# rushing_jade_wind_talent
# serenity
# serenity_buff
# serenity_talent
# spear_hand_strike
# spinning_crane_kick
# storm_earth_and_fire
# storm_earth_and_fire_buff
# strike_of_the_windlord
# tiger_palm
# touch_of_death
# touch_of_death_debuff
# war_stomp
# whirling_dragon_punch
]]
	OvaleScripts:RegisterScript("MONK", "windwalker", name, desc, code, "script")
end
