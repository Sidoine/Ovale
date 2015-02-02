local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_monk_windwalker_2h_t17m"
	local desc = "[6.0] SimulationCraft: Monk_Windwalker_2h_T17M"
	local code = [[
# Based on SimulationCraft profile "Monk_Windwalker_2h_T17M".
#	class=monk
#	spec=windwalker
#	talents=0130023
#	glyphs=touch_of_death

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=windwalker)
AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default specialization=windwalker)
AddCheckBox(opt_chi_burst SpellName(chi_burst) default specialization=windwalker)
AddCheckBox(opt_storm_earth_and_fire SpellName(storm_earth_and_fire) specialization=windwalker)

AddFunction WindwalkerUsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction WindwalkerUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
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
	#storm_earth_and_fire,target=2,if=debuff.storm_earth_and_fire_target.down
	if target.DebuffExpires(storm_earth_and_fire_target_debuff) and CheckBoxOn(opt_storm_earth_and_fire) and Enemies() > 1 and { Enemies() < 3 and BuffStacks(storm_earth_and_fire_buff) < 1 or Enemies() >= 3 and BuffStacks(storm_earth_and_fire_buff) < 2 } Spell(storm_earth_and_fire text=other)
	#storm_earth_and_fire,target=3,if=debuff.storm_earth_and_fire_target.down
	if target.DebuffExpires(storm_earth_and_fire_target_debuff) and CheckBoxOn(opt_storm_earth_and_fire) and Enemies() > 1 and { Enemies() < 3 and BuffStacks(storm_earth_and_fire_buff) < 1 or Enemies() >= 3 and BuffStacks(storm_earth_and_fire_buff) < 2 } Spell(storm_earth_and_fire text=3)
	#call_action_list,name=opener,if=talent.serenity.enabled&talent.chi_brew.enabled&cooldown.fists_of_fury.up&time<20
	if Talent(serenity_talent) and Talent(chi_brew_talent) and not SpellCooldown(fists_of_fury) > 0 and TimeInCombat() < 20 WindwalkerOpenerMainActions()
	#chi_brew,if=chi.max-chi>=2&((charges=1&recharge_time<=10)|charges=2|target.time_to_die<charges*10)&buff.tigereye_brew.stack<=16
	if MaxChi() - Chi() >= 2 and { Charges(chi_brew) == 1 and SpellChargeCooldown(chi_brew) <= 10 or Charges(chi_brew) == 2 or target.TimeToDie() < Charges(chi_brew) * 10 } and BuffStacks(tigereye_brew_buff) <= 16 Spell(chi_brew)
	#tiger_palm,if=buff.tiger_power.remains<6.6
	if BuffRemaining(tiger_power_buff) < 6.6 Spell(tiger_palm)
	#rising_sun_kick,if=(debuff.rising_sun_kick.down|debuff.rising_sun_kick.remains<3)
	if target.DebuffExpires(rising_sun_kick_debuff) or target.DebuffRemaining(rising_sun_kick_debuff) < 3 Spell(rising_sun_kick)
	#call_action_list,name=st,if=active_enemies<3&(level<100|!talent.chi_explosion.enabled)
	if Enemies() < 3 and { Level() < 100 or not Talent(chi_explosion_talent) } WindwalkerStMainActions()
	#call_action_list,name=st_chix,if=active_enemies=1&talent.chi_explosion.enabled
	if Enemies() == 1 and Talent(chi_explosion_talent) WindwalkerStChixMainActions()
	#call_action_list,name=cleave_chix,if=active_enemies=2&talent.chi_explosion.enabled
	if Enemies() == 2 and Talent(chi_explosion_talent) WindwalkerCleaveChixMainActions()
	#call_action_list,name=aoe,if=active_enemies>=3&!talent.rushing_jade_wind.enabled
	if Enemies() >= 3 and not Talent(rushing_jade_wind_talent) WindwalkerAoeMainActions()
	#call_action_list,name=aoe_rjw,if=active_enemies>=3&talent.rushing_jade_wind.enabled
	if Enemies() >= 3 and Talent(rushing_jade_wind_talent) WindwalkerAoeRjwMainActions()
}

AddFunction WindwalkerDefaultShortCdActions
{
	unless target.DebuffExpires(storm_earth_and_fire_target_debuff) and CheckBoxOn(opt_storm_earth_and_fire) and Enemies() > 1 and { Enemies() < 3 and BuffStacks(storm_earth_and_fire_buff) < 1 or Enemies() >= 3 and BuffStacks(storm_earth_and_fire_buff) < 2 } and Spell(storm_earth_and_fire text=other) or target.DebuffExpires(storm_earth_and_fire_target_debuff) and CheckBoxOn(opt_storm_earth_and_fire) and Enemies() > 1 and { Enemies() < 3 and BuffStacks(storm_earth_and_fire_buff) < 1 or Enemies() >= 3 and BuffStacks(storm_earth_and_fire_buff) < 2 } and Spell(storm_earth_and_fire text=3)
	{
		#call_action_list,name=opener,if=talent.serenity.enabled&talent.chi_brew.enabled&cooldown.fists_of_fury.up&time<20
		if Talent(serenity_talent) and Talent(chi_brew_talent) and not SpellCooldown(fists_of_fury) > 0 and TimeInCombat() < 20 WindwalkerOpenerShortCdActions()

		unless Talent(serenity_talent) and Talent(chi_brew_talent) and not SpellCooldown(fists_of_fury) > 0 and TimeInCombat() < 20 and WindwalkerOpenerShortCdPostConditions() or BuffRemaining(tiger_power_buff) < 6.6 and Spell(tiger_palm)
		{
			#tigereye_brew,if=buff.tigereye_brew_use.down&buff.tigereye_brew.stack=20
			if BuffExpires(tigereye_brew_use_buff) and BuffStacks(tigereye_brew_buff) == 20 Spell(tigereye_brew)
			#tigereye_brew,if=buff.tigereye_brew_use.down&buff.tigereye_brew.stack>=9&buff.serenity.up
			if BuffExpires(tigereye_brew_use_buff) and BuffStacks(tigereye_brew_buff) >= 9 and BuffPresent(serenity_buff) Spell(tigereye_brew)
			#tigereye_brew,if=buff.tigereye_brew_use.down&buff.tigereye_brew.stack>=9&cooldown.fists_of_fury.up&chi>=3&debuff.rising_sun_kick.up&buff.tiger_power.up
			if BuffExpires(tigereye_brew_use_buff) and BuffStacks(tigereye_brew_buff) >= 9 and not SpellCooldown(fists_of_fury) > 0 and Chi() >= 3 and target.DebuffPresent(rising_sun_kick_debuff) and BuffPresent(tiger_power_buff) Spell(tigereye_brew)
			#tigereye_brew,if=talent.hurricane_strike.enabled&buff.tigereye_brew_use.down&buff.tigereye_brew.stack>=9&cooldown.hurricane_strike.up&chi>=3&debuff.rising_sun_kick.up&buff.tiger_power.up
			if Talent(hurricane_strike_talent) and BuffExpires(tigereye_brew_use_buff) and BuffStacks(tigereye_brew_buff) >= 9 and not SpellCooldown(hurricane_strike) > 0 and Chi() >= 3 and target.DebuffPresent(rising_sun_kick_debuff) and BuffPresent(tiger_power_buff) Spell(tigereye_brew)
			#tigereye_brew,if=buff.tigereye_brew_use.down&chi>=2&(buff.tigereye_brew.stack>=16|target.time_to_die<40)&debuff.rising_sun_kick.up&buff.tiger_power.up
			if BuffExpires(tigereye_brew_use_buff) and Chi() >= 2 and { BuffStacks(tigereye_brew_buff) >= 16 or target.TimeToDie() < 40 } and target.DebuffPresent(rising_sun_kick_debuff) and BuffPresent(tiger_power_buff) Spell(tigereye_brew)

			unless { target.DebuffExpires(rising_sun_kick_debuff) or target.DebuffRemaining(rising_sun_kick_debuff) < 3 } and Spell(rising_sun_kick)
			{
				#serenity,if=chi>=2&buff.tiger_power.up&debuff.rising_sun_kick.up
				if Chi() >= 2 and BuffPresent(tiger_power_buff) and target.DebuffPresent(rising_sun_kick_debuff) Spell(serenity)
				#fists_of_fury,if=buff.tiger_power.remains>cast_time&debuff.rising_sun_kick.remains>cast_time&energy.time_to_max>cast_time&!buff.serenity.up
				if BuffRemaining(tiger_power_buff) > CastTime(fists_of_fury) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(fists_of_fury) and TimeToMaxEnergy() > CastTime(fists_of_fury) and not BuffPresent(serenity_buff) Spell(fists_of_fury)
				#touch_of_death,if=target.health.percent<10&(glyph.touch_of_death.enabled|chi>=3)
				if target.HealthPercent() < 10 and { Glyph(glyph_of_touch_of_death) or Chi() >= 3 } Spell(touch_of_death)
				#hurricane_strike,if=energy.time_to_max>cast_time&buff.tiger_power.remains>cast_time&debuff.rising_sun_kick.remains>cast_time&buff.energizing_brew.down
				if TimeToMaxEnergy() > CastTime(hurricane_strike) and BuffRemaining(tiger_power_buff) > CastTime(hurricane_strike) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(hurricane_strike) and BuffExpires(energizing_brew_buff) Spell(hurricane_strike)
				#energizing_brew,if=cooldown.fists_of_fury.remains>6&(!talent.serenity.enabled|(!buff.serenity.remains&cooldown.serenity.remains>4))&energy+energy.regen*gcd<50
				if SpellCooldown(fists_of_fury) > 6 and { not Talent(serenity_talent) or not BuffPresent(serenity_buff) and SpellCooldown(serenity) > 4 } and Energy() + EnergyRegenRate() * GCD() < 50 Spell(energizing_brew)
				#call_action_list,name=st,if=active_enemies<3&(level<100|!talent.chi_explosion.enabled)
				if Enemies() < 3 and { Level() < 100 or not Talent(chi_explosion_talent) } WindwalkerStShortCdActions()

				unless Enemies() < 3 and { Level() < 100 or not Talent(chi_explosion_talent) } and WindwalkerStShortCdPostConditions()
				{
					#call_action_list,name=st_chix,if=active_enemies=1&talent.chi_explosion.enabled
					if Enemies() == 1 and Talent(chi_explosion_talent) WindwalkerStChixShortCdActions()

					unless Enemies() == 1 and Talent(chi_explosion_talent) and WindwalkerStChixShortCdPostConditions()
					{
						#call_action_list,name=cleave_chix,if=active_enemies=2&talent.chi_explosion.enabled
						if Enemies() == 2 and Talent(chi_explosion_talent) WindwalkerCleaveChixShortCdActions()

						unless Enemies() == 2 and Talent(chi_explosion_talent) and WindwalkerCleaveChixShortCdPostConditions()
						{
							#call_action_list,name=aoe,if=active_enemies>=3&!talent.rushing_jade_wind.enabled
							if Enemies() >= 3 and not Talent(rushing_jade_wind_talent) WindwalkerAoeShortCdActions()

							unless Enemies() >= 3 and not Talent(rushing_jade_wind_talent) and WindwalkerAoeShortCdPostConditions()
							{
								#call_action_list,name=aoe_rjw,if=active_enemies>=3&talent.rushing_jade_wind.enabled
								if Enemies() >= 3 and Talent(rushing_jade_wind_talent) WindwalkerAoeRjwShortCdActions()
							}
						}
					}
				}
			}
		}
	}
}

AddFunction WindwalkerDefaultCdActions
{
	#auto_attack
	#spear_hand_strike
	WindwalkerInterruptActions()
	#nimble_brew
	if IsFeared() or IsRooted() or IsStunned() Spell(nimble_brew)
	#invoke_xuen
	Spell(invoke_xuen)

	unless target.DebuffExpires(storm_earth_and_fire_target_debuff) and CheckBoxOn(opt_storm_earth_and_fire) and Enemies() > 1 and { Enemies() < 3 and BuffStacks(storm_earth_and_fire_buff) < 1 or Enemies() >= 3 and BuffStacks(storm_earth_and_fire_buff) < 2 } and Spell(storm_earth_and_fire text=other) or target.DebuffExpires(storm_earth_and_fire_target_debuff) and CheckBoxOn(opt_storm_earth_and_fire) and Enemies() > 1 and { Enemies() < 3 and BuffStacks(storm_earth_and_fire_buff) < 1 or Enemies() >= 3 and BuffStacks(storm_earth_and_fire_buff) < 2 } and Spell(storm_earth_and_fire text=3)
	{
		#call_action_list,name=opener,if=talent.serenity.enabled&talent.chi_brew.enabled&cooldown.fists_of_fury.up&time<20
		if Talent(serenity_talent) and Talent(chi_brew_talent) and not SpellCooldown(fists_of_fury) > 0 and TimeInCombat() < 20 WindwalkerOpenerCdActions()

		unless Talent(serenity_talent) and Talent(chi_brew_talent) and not SpellCooldown(fists_of_fury) > 0 and TimeInCombat() < 20 and WindwalkerOpenerCdPostConditions()
		{
			#chi_sphere,if=talent.power_strikes.enabled&buff.chi_sphere.react&chi<4
			#potion,name=draenic_agility,if=buff.serenity.up|(!talent.serenity.enabled&trinket.proc.agility.react)
			if BuffPresent(serenity_buff) or not Talent(serenity_talent) and BuffPresent(trinket_proc_agility_buff) WindwalkerUsePotionAgility()
			#use_item,name=beating_heart_of_the_mountain,if=buff.tigereye_brew_use.up|target.time_to_die<18
			if BuffPresent(tigereye_brew_use_buff) or target.TimeToDie() < 18 WindwalkerUseItemActions()
			#blood_fury,if=buff.tigereye_brew_use.up|target.time_to_die<18
			if BuffPresent(tigereye_brew_use_buff) or target.TimeToDie() < 18 Spell(blood_fury_apsp)
			#berserking,if=buff.tigereye_brew_use.up|target.time_to_die<18
			if BuffPresent(tigereye_brew_use_buff) or target.TimeToDie() < 18 Spell(berserking)
			#arcane_torrent,if=chi.max-chi>=1&(buff.tigereye_brew_use.up|target.time_to_die<18)
			if MaxChi() - Chi() >= 1 and { BuffPresent(tigereye_brew_use_buff) or target.TimeToDie() < 18 } Spell(arcane_torrent_chi)

			unless BuffRemaining(tiger_power_buff) < 6.6 and Spell(tiger_palm) or { target.DebuffExpires(rising_sun_kick_debuff) or target.DebuffRemaining(rising_sun_kick_debuff) < 3 } and Spell(rising_sun_kick) or BuffRemaining(tiger_power_buff) > CastTime(fists_of_fury) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(fists_of_fury) and TimeToMaxEnergy() > CastTime(fists_of_fury) and not BuffPresent(serenity_buff) and Spell(fists_of_fury)
			{
				#fortifying_brew,if=target.health.percent<10&cooldown.touch_of_death.remains=0&(glyph.touch_of_death.enabled|chi>=3)
				if target.HealthPercent() < 10 and not SpellCooldown(touch_of_death) > 0 and { Glyph(glyph_of_touch_of_death) or Chi() >= 3 } Spell(fortifying_brew)
			}
		}
	}
}

### actions.aoe

AddFunction WindwalkerAoeMainActions
{
	#chi_explosion,if=chi>=4&cooldown.fists_of_fury.remains>4
	if Chi() >= 4 and SpellCooldown(fists_of_fury) > 4 Spell(chi_explosion_melee)
	#rising_sun_kick,if=chi=chi.max
	if Chi() == MaxChi() Spell(rising_sun_kick)
	#chi_wave,if=energy.time_to_max>2&buff.serenity.down
	if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=energy.time_to_max>2&!dot.zen_sphere.ticking
	if TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#spinning_crane_kick
	Spell(spinning_crane_kick)
}

AddFunction WindwalkerAoeShortCdActions
{
	unless Chi() >= 4 and SpellCooldown(fists_of_fury) > 4 and Spell(chi_explosion_melee) or Chi() == MaxChi() and Spell(rising_sun_kick) or TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and Spell(chi_wave)
	{
		#chi_burst,if=energy.time_to_max>2&buff.serenity.down
		if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and CheckBoxOn(opt_chi_burst) Spell(chi_burst)

		unless TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) and Spell(zen_sphere)
		{
			#chi_torpedo,if=energy.time_to_max>2
			if TimeToMaxEnergy() > 2 Spell(chi_torpedo)
		}
	}
}

AddFunction WindwalkerAoeShortCdPostConditions
{
	Chi() >= 4 and SpellCooldown(fists_of_fury) > 4 and Spell(chi_explosion_melee) or Chi() == MaxChi() and Spell(rising_sun_kick) or TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and Spell(chi_wave) or TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) and Spell(zen_sphere) or Spell(spinning_crane_kick)
}

### actions.aoe_rjw

AddFunction WindwalkerAoeRjwMainActions
{
	#chi_explosion,if=chi>=4&cooldown.fists_of_fury.remains>4
	if Chi() >= 4 and SpellCooldown(fists_of_fury) > 4 Spell(chi_explosion_melee)
	#rushing_jade_wind
	Spell(rushing_jade_wind)
	#chi_wave,if=energy.time_to_max>2&buff.serenity.down
	if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=energy.time_to_max>2&!dot.zen_sphere.ticking
	if TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#blackout_kick,if=buff.combo_breaker_bok.react|buff.serenity.up
	if BuffPresent(combo_breaker_bok_buff) or BuffPresent(serenity_buff) Spell(blackout_kick)
	#tiger_palm,if=buff.combo_breaker_tp.react&buff.combo_breaker_tp.remains<=2
	if BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 Spell(tiger_palm)
	#blackout_kick,if=chi.max-chi<2&(cooldown.fists_of_fury.remains>3|!talent.rushing_jade_wind.enabled)
	if MaxChi() - Chi() < 2 and { SpellCooldown(fists_of_fury) > 3 or not Talent(rushing_jade_wind_talent) } Spell(blackout_kick)
	#expel_harm,if=chi.max-chi>=2&health.percent<95
	if MaxChi() - Chi() >= 2 and HealthPercent() < 95 Spell(expel_harm)
	#jab,if=chi.max-chi>=2
	if MaxChi() - Chi() >= 2 Spell(jab)
}

AddFunction WindwalkerAoeRjwShortCdActions
{
	unless Chi() >= 4 and SpellCooldown(fists_of_fury) > 4 and Spell(chi_explosion_melee) or Spell(rushing_jade_wind) or TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and Spell(chi_wave)
	{
		#chi_burst,if=energy.time_to_max>2&buff.serenity.down
		if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and CheckBoxOn(opt_chi_burst) Spell(chi_burst)

		unless TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) and Spell(zen_sphere) or { BuffPresent(combo_breaker_bok_buff) or BuffPresent(serenity_buff) } and Spell(blackout_kick) or BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 and Spell(tiger_palm) or MaxChi() - Chi() < 2 and { SpellCooldown(fists_of_fury) > 3 or not Talent(rushing_jade_wind_talent) } and Spell(blackout_kick)
		{
			#chi_torpedo,if=energy.time_to_max>2
			if TimeToMaxEnergy() > 2 Spell(chi_torpedo)
		}
	}
}

### actions.cleave_chix

AddFunction WindwalkerCleaveChixMainActions
{
	#chi_explosion,if=chi>=4&cooldown.fists_of_fury.remains>4
	if Chi() >= 4 and SpellCooldown(fists_of_fury) > 4 Spell(chi_explosion_melee)
	#tiger_palm,if=buff.combo_breaker_tp.react&buff.combo_breaker_tp.remains<=2
	if BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 Spell(tiger_palm)
	#chi_wave,if=energy.time_to_max>2&buff.serenity.down
	if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=energy.time_to_max>2&!dot.zen_sphere.ticking
	if TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#expel_harm,if=chi.max-chi>=2&health.percent<95
	if MaxChi() - Chi() >= 2 and HealthPercent() < 95 Spell(expel_harm)
	#jab,if=chi.max-chi>=2
	if MaxChi() - Chi() >= 2 Spell(jab)
}

AddFunction WindwalkerCleaveChixShortCdActions
{
	unless Chi() >= 4 and SpellCooldown(fists_of_fury) > 4 and Spell(chi_explosion_melee) or BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 and Spell(tiger_palm) or TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and Spell(chi_wave)
	{
		#chi_burst,if=energy.time_to_max>2&buff.serenity.down
		if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and CheckBoxOn(opt_chi_burst) Spell(chi_burst)

		unless TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) and Spell(zen_sphere)
		{
			#chi_torpedo,if=energy.time_to_max>2
			if TimeToMaxEnergy() > 2 Spell(chi_torpedo)
		}
	}
}

AddFunction WindwalkerCleaveChixShortCdPostConditions
{
	Chi() >= 4 and SpellCooldown(fists_of_fury) > 4 and Spell(chi_explosion_melee) or BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 and Spell(tiger_palm) or TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and Spell(chi_wave) or TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) and Spell(zen_sphere) or MaxChi() - Chi() >= 2 and HealthPercent() < 95 and Spell(expel_harm) or MaxChi() - Chi() >= 2 and Spell(jab)
}

### actions.opener

AddFunction WindwalkerOpenerMainActions
{
	#tiger_palm,if=buff.tiger_power.remains<2
	if BuffRemaining(tiger_power_buff) < 2 Spell(tiger_palm)
	#rising_sun_kick
	Spell(rising_sun_kick)
	#blackout_kick,if=chi.max-chi<=1&cooldown.chi_brew.up|buff.serenity.up
	if MaxChi() - Chi() <= 1 and not SpellCooldown(chi_brew) > 0 or BuffPresent(serenity_buff) Spell(blackout_kick)
	#chi_brew,if=chi.max-chi>=2
	if MaxChi() - Chi() >= 2 Spell(chi_brew)
	#jab,if=chi.max-chi>=2&!buff.serenity.up
	if MaxChi() - Chi() >= 2 and not BuffPresent(serenity_buff) Spell(jab)
}

AddFunction WindwalkerOpenerShortCdActions
{
	#tigereye_brew,if=buff.tigereye_brew_use.down&buff.tigereye_brew.stack>=9
	if BuffExpires(tigereye_brew_use_buff) and BuffStacks(tigereye_brew_buff) >= 9 Spell(tigereye_brew)
	#fists_of_fury,if=buff.tiger_power.remains>cast_time&debuff.rising_sun_kick.remains>cast_time&buff.serenity.up&buff.serenity.remains<1.5
	if BuffRemaining(tiger_power_buff) > CastTime(fists_of_fury) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(fists_of_fury) and BuffPresent(serenity_buff) and BuffRemaining(serenity_buff) < 1.5 Spell(fists_of_fury)

	unless BuffRemaining(tiger_power_buff) < 2 and Spell(tiger_palm) or Spell(rising_sun_kick) or { MaxChi() - Chi() <= 1 and not SpellCooldown(chi_brew) > 0 or BuffPresent(serenity_buff) } and Spell(blackout_kick)
	{
		#serenity,if=chi.max-chi<=2
		if MaxChi() - Chi() <= 2 Spell(serenity)
	}
}

AddFunction WindwalkerOpenerShortCdPostConditions
{
	BuffRemaining(tiger_power_buff) < 2 and Spell(tiger_palm) or Spell(rising_sun_kick) or { MaxChi() - Chi() <= 1 and not SpellCooldown(chi_brew) > 0 or BuffPresent(serenity_buff) } and Spell(blackout_kick) or MaxChi() - Chi() >= 2 and not BuffPresent(serenity_buff) and Spell(jab)
}

AddFunction WindwalkerOpenerCdActions
{
	#use_item,name=beating_heart_of_the_mountain,if=buff.tigereye_brew_use.up
	if BuffPresent(tigereye_brew_use_buff) WindwalkerUseItemActions()
	#blood_fury,if=buff.tigereye_brew_use.up
	if BuffPresent(tigereye_brew_use_buff) Spell(blood_fury_apsp)
	#berserking,if=buff.tigereye_brew_use.up
	if BuffPresent(tigereye_brew_use_buff) Spell(berserking)
	#arcane_torrent,if=buff.tigereye_brew_use.up&chi.max-chi>=1
	if BuffPresent(tigereye_brew_use_buff) and MaxChi() - Chi() >= 1 Spell(arcane_torrent_chi)
}

AddFunction WindwalkerOpenerCdPostConditions
{
	BuffRemaining(tiger_power_buff) > CastTime(fists_of_fury) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(fists_of_fury) and BuffPresent(serenity_buff) and BuffRemaining(serenity_buff) < 1.5 and Spell(fists_of_fury) or BuffRemaining(tiger_power_buff) < 2 and Spell(tiger_palm) or Spell(rising_sun_kick) or { MaxChi() - Chi() <= 1 and not SpellCooldown(chi_brew) > 0 or BuffPresent(serenity_buff) } and Spell(blackout_kick) or MaxChi() - Chi() >= 2 and not BuffPresent(serenity_buff) and Spell(jab)
}

### actions.precombat

AddFunction WindwalkerPrecombatMainActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=rylak_crepes
	#legacy_of_the_white_tiger,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(legacy_of_the_white_tiger)
	#stance,choose=fierce_tiger
	Spell(stance_of_the_fierce_tiger)
}

AddFunction WindwalkerPrecombatShortCdPostConditions
{
	not BuffPresent(str_agi_int_buff any=1) and Spell(legacy_of_the_white_tiger) or Spell(stance_of_the_fierce_tiger)
}

AddFunction WindwalkerPrecombatCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) and Spell(legacy_of_the_white_tiger) or Spell(stance_of_the_fierce_tiger)
	{
		#snapshot_stats
		#potion,name=draenic_agility
		WindwalkerUsePotionAgility()
	}
}

AddFunction WindwalkerPrecombatCdPostConditions
{
	not BuffPresent(str_agi_int_buff any=1) and Spell(legacy_of_the_white_tiger) or Spell(stance_of_the_fierce_tiger)
}

### actions.st

AddFunction WindwalkerStMainActions
{
	#rising_sun_kick
	Spell(rising_sun_kick)
	#blackout_kick,if=buff.combo_breaker_bok.react|buff.serenity.up
	if BuffPresent(combo_breaker_bok_buff) or BuffPresent(serenity_buff) Spell(blackout_kick)
	#tiger_palm,if=buff.combo_breaker_tp.react&buff.combo_breaker_tp.remains<=2
	if BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 Spell(tiger_palm)
	#chi_wave,if=energy.time_to_max>2&buff.serenity.down
	if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=energy.time_to_max>2&!dot.zen_sphere.ticking&buff.serenity.down
	if TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) and BuffExpires(serenity_buff) Spell(zen_sphere)
	#blackout_kick,if=chi.max-chi<2
	if MaxChi() - Chi() < 2 Spell(blackout_kick)
	#expel_harm,if=chi.max-chi>=2&health.percent<95
	if MaxChi() - Chi() >= 2 and HealthPercent() < 95 Spell(expel_harm)
	#jab,if=chi.max-chi>=2
	if MaxChi() - Chi() >= 2 Spell(jab)
}

AddFunction WindwalkerStShortCdActions
{
	unless Spell(rising_sun_kick) or { BuffPresent(combo_breaker_bok_buff) or BuffPresent(serenity_buff) } and Spell(blackout_kick) or BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 and Spell(tiger_palm) or TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and Spell(chi_wave)
	{
		#chi_burst,if=energy.time_to_max>2&buff.serenity.down
		if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and CheckBoxOn(opt_chi_burst) Spell(chi_burst)

		unless TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) and BuffExpires(serenity_buff) and Spell(zen_sphere)
		{
			#chi_torpedo,if=energy.time_to_max>2&buff.serenity.down
			if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) Spell(chi_torpedo)
		}
	}
}

AddFunction WindwalkerStShortCdPostConditions
{
	Spell(rising_sun_kick) or { BuffPresent(combo_breaker_bok_buff) or BuffPresent(serenity_buff) } and Spell(blackout_kick) or BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 and Spell(tiger_palm) or TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and Spell(chi_wave) or TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) and BuffExpires(serenity_buff) and Spell(zen_sphere) or MaxChi() - Chi() < 2 and Spell(blackout_kick) or MaxChi() - Chi() >= 2 and HealthPercent() < 95 and Spell(expel_harm) or MaxChi() - Chi() >= 2 and Spell(jab)
}

### actions.st_chix

AddFunction WindwalkerStChixMainActions
{
	#chi_explosion,if=chi>=2&buff.combo_breaker_ce.react&cooldown.fists_of_fury.remains>2
	if Chi() >= 2 and BuffPresent(combo_breaker_ce_buff) and SpellCooldown(fists_of_fury) > 2 Spell(chi_explosion_melee)
	#tiger_palm,if=buff.combo_breaker_tp.react&buff.combo_breaker_tp.remains<=2
	if BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 Spell(tiger_palm)
	#chi_wave,if=energy.time_to_max>2&buff.serenity.down
	if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=energy.time_to_max>2&!dot.zen_sphere.ticking
	if TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#rising_sun_kick
	Spell(rising_sun_kick)
	#tiger_palm,if=chi=4&!buff.combo_breaker_tp.react
	if Chi() == 4 and not BuffPresent(combo_breaker_tp_buff) Spell(tiger_palm)
	#chi_explosion,if=chi>=3&cooldown.fists_of_fury.remains>4
	if Chi() >= 3 and SpellCooldown(fists_of_fury) > 4 Spell(chi_explosion_melee)
	#expel_harm,if=chi.max-chi>=2&health.percent<95
	if MaxChi() - Chi() >= 2 and HealthPercent() < 95 Spell(expel_harm)
	#jab,if=chi.max-chi>=2
	if MaxChi() - Chi() >= 2 Spell(jab)
}

AddFunction WindwalkerStChixShortCdActions
{
	unless Chi() >= 2 and BuffPresent(combo_breaker_ce_buff) and SpellCooldown(fists_of_fury) > 2 and Spell(chi_explosion_melee) or BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 and Spell(tiger_palm) or TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and Spell(chi_wave)
	{
		#chi_burst,if=energy.time_to_max>2&buff.serenity.down
		if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and CheckBoxOn(opt_chi_burst) Spell(chi_burst)

		unless TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) and Spell(zen_sphere) or Spell(rising_sun_kick) or Chi() == 4 and not BuffPresent(combo_breaker_tp_buff) and Spell(tiger_palm) or Chi() >= 3 and SpellCooldown(fists_of_fury) > 4 and Spell(chi_explosion_melee)
		{
			#chi_torpedo,if=energy.time_to_max>2
			if TimeToMaxEnergy() > 2 Spell(chi_torpedo)
		}
	}
}

AddFunction WindwalkerStChixShortCdPostConditions
{
	Chi() >= 2 and BuffPresent(combo_breaker_ce_buff) and SpellCooldown(fists_of_fury) > 2 and Spell(chi_explosion_melee) or BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 and Spell(tiger_palm) or TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and Spell(chi_wave) or TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) and Spell(zen_sphere) or Spell(rising_sun_kick) or Chi() == 4 and not BuffPresent(combo_breaker_tp_buff) and Spell(tiger_palm) or Chi() >= 3 and SpellCooldown(fists_of_fury) > 4 and Spell(chi_explosion_melee) or MaxChi() - Chi() >= 2 and HealthPercent() < 95 and Spell(expel_harm) or MaxChi() - Chi() >= 2 and Spell(jab)
}

### Windwalker icons.

AddCheckBox(opt_monk_windwalker_aoe L(AOE) default specialization=windwalker)

AddIcon checkbox=!opt_monk_windwalker_aoe enemies=1 help=shortcd specialization=windwalker
{
	unless not InCombat() and WindwalkerPrecombatShortCdPostConditions()
	{
		WindwalkerDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_monk_windwalker_aoe help=shortcd specialization=windwalker
{
	unless not InCombat() and WindwalkerPrecombatShortCdPostConditions()
	{
		WindwalkerDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=windwalker
{
	if not InCombat() WindwalkerPrecombatMainActions()
	WindwalkerDefaultMainActions()
}

AddIcon checkbox=opt_monk_windwalker_aoe help=aoe specialization=windwalker
{
	if not InCombat() WindwalkerPrecombatMainActions()
	WindwalkerDefaultMainActions()
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
# chi_brew
# chi_brew_talent
# chi_burst
# chi_explosion_melee
# chi_explosion_talent
# chi_torpedo
# chi_wave
# combo_breaker_bok_buff
# combo_breaker_ce_buff
# combo_breaker_tp_buff
# draenic_agility_potion
# energizing_brew
# energizing_brew_buff
# expel_harm
# fists_of_fury
# fortifying_brew
# glyph_of_touch_of_death
# hurricane_strike
# hurricane_strike_talent
# invoke_xuen
# jab
# legacy_of_the_white_tiger
# nimble_brew
# paralysis
# quaking_palm
# rising_sun_kick
# rising_sun_kick_debuff
# rushing_jade_wind
# rushing_jade_wind_talent
# serenity
# serenity_buff
# serenity_talent
# spear_hand_strike
# spinning_crane_kick
# stance_of_the_fierce_tiger
# storm_earth_and_fire
# storm_earth_and_fire_target_debuff
# tiger_palm
# tiger_power_buff
# tigereye_brew
# tigereye_brew_buff
# tigereye_brew_use_buff
# touch_of_death
# war_stomp
# zen_sphere
# zen_sphere_buff
]]
	OvaleScripts:RegisterScript("MONK", name, desc, code, "reference")
end
