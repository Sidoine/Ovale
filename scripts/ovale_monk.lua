local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_monk"
	local desc = "[6.0] Ovale: Brewmaster, Windwalker"
	local code = [[
# Ovale monk script based on SimulationCraft.

Include(ovale_common)
Include(ovale_monk_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)
AddCheckBox(opt_chi_burst SpellName(chi_burst) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
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

###
### Brewmaster
###
# Based on SimulationCraft profile "Monk_Brewmaster_1h_T16M".
#	class=monk
#	spec=brewmaster
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#fa!.00.11.
#	glyphs=fortifying_brew,fortuitous_spheres

# ActionList: BrewmasterPrecombatActions --> main, shortcd, cd

AddFunction BrewmasterPrecombatActions
{
	#flask,type=earth
	#food,type=mogu_fish_stew
	# CHANGE: Buff with Legacy of the White Tiger
	if BuffExpires(str_agi_int_buff any=1) Spell(legacy_of_the_white_tiger)
	#stance,choose=sturdy_ox
	Spell(stance_of_the_sturdy_ox)
	#snapshot_stats
}

AddFunction BrewmasterPrecombatShortCdActions
{
	unless BuffExpires(str_agi_int_buff any=1) and Spell(legacy_of_the_white_tiger)
		or Spell(stance_of_the_sturdy_ox)
	{
		#dampen_harm
		Spell(dampen_harm)
	}
}

AddFunction BrewmasterPrecombatCdActions
{
	unless BuffExpires(str_agi_int_buff any=1) and Spell(legacy_of_the_white_tiger)
		or Spell(stance_of_the_sturdy_ox)
	{
		#potion,name=virmens_bite
		UsePotionAgility()
	}
}

# ActionList: BrewmasterDefaultActions --> main, shortcd, cd

AddFunction BrewmasterDefaultActions
{
	#auto_attack
	#chi_brew,if=talent.chi_brew.enabled&chi.max-chi>=2&buff.elusive_brew_stacks.stack<=10
	if Talent(chi_brew_talent) and MaxChi() - Chi() >= 2 and BuffStacks(elusive_brew_stacks_buff) <= 10 Spell(chi_brew)
	#gift_of_the_ox,if=buff.gift_of_the_ox.react&incoming_damage_1500ms
	#call_action_list,name=st,if=active_enemies<3
	if Enemies() < 3 BrewmasterStActions()
	#call_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 BrewmasterAoeActions()
}

AddFunction BrewmasterDefaultShortCdActions
{
	#chi_brew,if=talent.chi_brew.enabled&chi.max-chi>=2&buff.elusive_brew_stacks.stack<=10
	if Talent(chi_brew_talent) and MaxChi() - Chi() >= 2 and BuffStacks(elusive_brew_stacks_buff) <= 10 Spell(chi_brew)
	#dampen_harm,if=incoming_damage_1500ms&buff.fortifying_brew.down&buff.elusive_brew_activated.down
	if IncomingDamage(1.5) and BuffExpires(fortifying_brew_buff) and BuffExpires(elusive_brew_activated_buff) Spell(dampen_harm)
	#elusive_brew,if=buff.elusive_brew_stacks.react>=9&(buff.dampen_harm.down|buff.diffuse_magic.down)&buff.elusive_brew_activated.down
	if BuffStacks(elusive_brew_stacks_buff) >= 9 and { BuffExpires(dampen_harm_buff) or BuffExpires(diffuse_magic_buff) } and BuffExpires(elusive_brew_activated_buff) Spell(elusive_brew)
	#serenity,if=talent.serenity.enabled&energy<=40
	if Talent(serenity_talent) and Energy() <= 40 Spell(serenity)
	#call_action_list,name=st,if=active_enemies<3
	if Enemies() < 3 BrewmasterStShortCdActions()
	#call_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 BrewmasterAoeShortCdActions()
}

AddFunction BrewmasterDefaultCdActions
{
	# CHANGE: Touch of Death if it will kill the mob.
	if target.Health() < Health() and BuffPresent(death_note_buff) Spell(touch_of_death)
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()
	# CHANGE: Break snares with Nimble Brew.
	if IsFeared() or IsRooted() or IsStunned() Spell(nimble_brew)
	#blood_fury,if=energy<=40
	if Energy() <= 40 Spell(blood_fury_apsp)
	#berserking,if=energy<=40
	if Energy() <= 40 Spell(berserking)
	#arcane_torrent,if=energy<=40
	if Energy() <= 40 Spell(arcane_torrent_chi)
	#diffuse_magic,if=incoming_damage_1500ms&buff.fortifying_brew.down
	if IncomingDamage(1.5) > 0 and BuffExpires(fortifying_brew_buff) Spell(diffuse_magic)
	#dampen_harm,if=incoming_damage_1500ms&buff.fortifying_brew.down&buff.elusive_brew_activated.down
	if IncomingDamage(1.5) and BuffExpires(fortifying_brew_buff) and BuffExpires(elusive_brew_activated_buff) Spell(dampen_harm)
	#fortifying_brew,if=incoming_damage_1500ms&(buff.dampen_harm.down|buff.diffuse_magic.down)&buff.elusive_brew_activated.down
	if IncomingDamage(1.5) > 0 and { BuffExpires(dampen_harm_buff) or BuffExpires(diffuse_magic_buff) } and BuffExpires(elusive_brew_activated_buff) Spell(fortifying_brew)
	#invoke_xuen,if=talent.invoke_xuen.enabled&time>5
	if Talent(invoke_xuen_talent) and TimeInCombat() > 5 Spell(invoke_xuen)
	#call_action_list,name=st,if=active_enemies<3
	if Enemies() < 3 BrewmasterStCdActions()
	#call_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 BrewmasterAoeCdActions()
}

# ActionList: BrewmasterAoeActions --> main, shortcd, cd

AddFunction BrewmasterAoeActions
{
	# CHANGE: Ensure that Shuffle is never down.
	if BuffExpires(shuffle_buff) Spell(blackout_kick)
	#breath_of_fire,if=chi>=3&buff.shuffle.remains>=6&dot.breath_of_fire.remains<=1&target.debuff.dizzying_haze.up
	if Chi() >= 3 and BuffRemaining(shuffle_buff) >= 6 and target.DebuffRemaining(breath_of_fire_debuff) <= 1 and target.DebuffPresent(dizzying_haze_debuff) Spell(breath_of_fire)
	#chi_explosion,if=chi>=4
	if Chi() >= 4 Spell(chi_explosion_tank)
	#rushing_jade_wind,if=chi.max-chi>=1&talent.rushing_jade_wind.enabled
	if MaxChi() - Chi() >= 1 and Talent(rushing_jade_wind_talent) Spell(rushing_jade_wind)
	#keg_smash,if=chi.max-chi>=2&!buff.serenity.remains
	if MaxChi() - Chi() >= 2 and not BuffPresent(serenity_buff) Spell(keg_smash)
	#chi_burst,if=talent.chi_burst.enabled&energy.time_to_max>3
	if Talent(chi_burst_talent) and TimeToMaxEnergy() > 3 and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
	#chi_wave,if=talent.chi_wave.enabled&energy.time_to_max>3
	if Talent(chi_wave_talent) and TimeToMaxEnergy() > 3 Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=talent.zen_sphere.enabled&!dot.zen_sphere.ticking
	if Talent(zen_sphere_talent) and not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#blackout_kick,if=talent.rushing_jade_wind.enabled&buff.shuffle.remains<=3&cooldown.keg_smash.remains>=gcd
	if Talent(rushing_jade_wind_talent) and BuffRemaining(shuffle_buff) <= 3 and SpellCooldown(keg_smash) >= GCD() Spell(blackout_kick)
	#blackout_kick,if=talent.rushing_jade_wind.enabled&buff.serenity.up
	if Talent(rushing_jade_wind_talent) and BuffPresent(serenity_buff) Spell(blackout_kick)
	#blackout_kick,if=talent.rushing_jade_wind.enabled&chi>=4
	if Talent(rushing_jade_wind_talent) and Chi() >= 4 Spell(blackout_kick)
	#expel_harm,if=chi.max-chi>=1&cooldown.keg_smash.remains>=gcd&(energy+(energy.regen*(cooldown.keg_smash.remains)))>=40
	if MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 40 Spell(expel_harm)
	#spinning_crane_kick,if=chi.max-chi>=1&!talent.rushing_jade_wind.enabled
	if MaxChi() - Chi() >= 1 and not Talent(rushing_jade_wind_talent) Spell(spinning_crane_kick)
	#jab,if=talent.rushing_jade_wind.enabled&chi.max-chi>=1&cooldown.keg_smash.remains>=gcd&cooldown.expel_harm.remains>=gcd
	if Talent(rushing_jade_wind_talent) and MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and SpellCooldown(expel_harm) >= GCD() Spell(jab)
	#tiger_palm,if=talent.rushing_jade_wind.enabled&(energy+(energy.regen*(cooldown.keg_smash.remains)))>=40
	if Talent(rushing_jade_wind_talent) and Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 40 Spell(tiger_palm)
	#tiger_palm,if=talent.rushing_jade_wind.enabled&cooldown.keg_smash.remains>=gcd
	if Talent(rushing_jade_wind_talent) and SpellCooldown(keg_smash) >= GCD() Spell(tiger_palm)
}

AddFunction BrewmasterAoeShortCdActions
{
	#guard
	Spell(guard)

	unless Chi() >= 3 and BuffRemaining(shuffle_buff) >= 6 and target.DebuffRemaining(breath_of_fire_debuff) <= 1 and target.DebuffPresent(dizzying_haze_debuff) and Spell(breath_of_fire)
		or Chi() >= 4 and Spell(chi_explosion_tank)
		or MaxChi() - Chi() >= 1 and Talent(rushing_jade_wind_talent) and Spell(rushing_jade_wind)
	{
		#purifying_brew,if=!talent.chi_explosion.enabled&stagger.heavy
		if not Talent(chi_explosion_talent) and DebuffPresent(heavy_stagger_debuff) Spell(purifying_brew)
		#guard
		Spell(guard)

		unless MaxChi() - Chi() >= 2 and not BuffPresent(serenity_buff) and Spell(keg_smash)
			or Talent(chi_burst_talent) and TimeToMaxEnergy() > 3 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst)
			or Talent(chi_wave_talent) and TimeToMaxEnergy() > 3 and Spell(chi_wave)
			or Talent(zen_sphere_talent) and not BuffPresent(zen_sphere_buff) and Spell(zen_sphere)
			or Talent(rushing_jade_wind_talent) and BuffRemaining(shuffle_buff) <= 3 and SpellCooldown(keg_smash) >= GCD() and Spell(blackout_kick)
			or Talent(rushing_jade_wind_talent) and BuffPresent(serenity_buff) and Spell(blackout_kick)
			or Talent(rushing_jade_wind_talent) and Chi() >= 4 and Spell(blackout_kick)
			or MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 40 and Spell(expel_harm)
			or MaxChi() - Chi() >= 1 and not Talent(rushing_jade_wind_talent) and Spell(spinning_crane_kick)
			or Talent(rushing_jade_wind_talent) and MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and SpellCooldown(expel_harm) >= GCD() and Spell(jab)
		{
			#purifying_brew,if=!talent.chi_explosion.enabled&talent.rushing_jade_wind.enabled&stagger.moderate&buff.shuffle.remains>=6
			if not Talent(chi_explosion_talent) and Talent(rushing_jade_wind_talent) and DebuffPresent(moderate_stagger_debuff) and BuffRemaining(shuffle_buff) >= 6 Spell(purifying_brew)
		}
	}
}

AddFunction BrewmasterAoeCdActions {}

# ActionList: BrewmasterStActions --> main, shortcd, cd

AddFunction BrewmasterStActions
{
	#blackout_kick,if=buff.shuffle.down
	if BuffExpires(shuffle_buff) Spell(blackout_kick)
	#keg_smash,if=chi.max-chi>=2&!buff.serenity.remains
	if MaxChi() - Chi() >= 2 and not BuffPresent(serenity_buff) Spell(keg_smash)
	#chi_burst,if=talent.chi_burst.enabled&energy.time_to_max>3
	if Talent(chi_burst_talent) and TimeToMaxEnergy() > 3 and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
	#chi_wave,if=talent.chi_wave.enabled&energy.time_to_max>3
	if Talent(chi_wave_talent) and TimeToMaxEnergy() > 3 Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=talent.zen_sphere.enabled&!dot.zen_sphere.ticking
	if Talent(zen_sphere_talent) and not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#chi_explosion,if=chi>=3
	if Chi() >= 3 Spell(chi_explosion_tank)
	#blackout_kick,if=buff.shuffle.remains<=3&cooldown.keg_smash.remains>=gcd
	if BuffRemaining(shuffle_buff) <= 3 and SpellCooldown(keg_smash) >= GCD() Spell(blackout_kick)
	#blackout_kick,if=buff.serenity.up
	if BuffPresent(serenity_buff) Spell(blackout_kick)
	#blackout_kick,if=chi>=4
	if Chi() >= 4 Spell(blackout_kick)
	#expel_harm,if=chi.max-chi>=1&cooldown.keg_smash.remains>=gcd
	if MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() Spell(expel_harm)
	#jab,if=chi.max-chi>=1&cooldown.keg_smash.remains>=gcd&cooldown.expel_harm.remains>=gcd
	if MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and SpellCooldown(expel_harm) >= GCD() Spell(jab)
	#tiger_palm,if=(energy+(energy.regen*(cooldown.keg_smash.remains)))>=40
	if Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 40 Spell(tiger_palm)
	#tiger_palm,if=cooldown.keg_smash.remains>=gcd
	if SpellCooldown(keg_smash) >= GCD() Spell(tiger_palm)
}

AddFunction BrewmasterStShortCdActions
{
	unless BuffExpires(shuffle_buff) and Spell(blackout_kick)
	{
		#purifying_brew,if=!talent.chi_explosion.enabled&stagger.heavy
		if not Talent(chi_explosion_talent) and DebuffPresent(heavy_stagger_debuff) Spell(purifying_brew)
		# CHANGE: Ignore this next Purifying Brew suggestion since it blocks casting Guard later on.
		#purifying_brew,if=!buff.serenity.up
		#if not BuffPresent(serenity_buff) Spell(purifying_brew)
		#guard
		Spell(guard)

		unless MaxChi() - Chi() >= 2 and not BuffPresent(serenity_buff) and Spell(keg_smash)
			or Talent(chi_burst_talent) and TimeToMaxEnergy() > 3 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst)
			or Talent(chi_wave_talent) and TimeToMaxEnergy() > 3 and Spell(chi_wave)
			or Talent(zen_sphere_talent) and not BuffPresent(zen_sphere_buff) and Spell(zen_sphere)
			or Chi() >= 3 and Spell(chi_explosion_tank)
			or BuffRemaining(shuffle_buff) <= 3 and SpellCooldown(keg_smash) >= GCD() and Spell(blackout_kick)
			or BuffPresent(serenity_buff) and Spell(blackout_kick)
			or Chi() >= 4 and Spell(blackout_kick)
			or MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and Spell(expel_harm)
			or MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and SpellCooldown(expel_harm) >= GCD() and Spell(jab)
		{
			#purifying_brew,if=!talent.chi_explosion.enabled&stagger.moderate&buff.shuffle.remains>=6
			if not Talent(chi_explosion_talent) and DebuffPresent(moderate_stagger_debuff) and BuffRemaining(shuffle_buff) >= 6 Spell(purifying_brew)
		}
	}
}

AddFunction BrewmasterStCdActions {}

### Brewmaster icons.
AddCheckBox(opt_monk_brewmaster_aoe L(AOE) specialization=brewmaster default)

AddIcon specialization=brewmaster help=shortcd enemies=1 checkbox=!opt_monk_brewmaster_aoe
{
	if InCombat(no) BrewmasterPrecombatShortCdActions()
	BrewmasterDefaultShortCdActions()
}

AddIcon specialization=brewmaster help=shortcd checkbox=opt_monk_brewmaster_aoe
{
	if InCombat(no) BrewmasterPrecombatShortCdActions()
	BrewmasterDefaultShortCdActions()
}

AddIcon specialization=brewmaster help=main enemies=1
{
	if InCombat(no) BrewmasterPrecombatActions()
	BrewmasterDefaultActions()
}

AddIcon specialization=brewmaster help=aoe checkbox=opt_monk_brewmaster_aoe
{
	if InCombat(no) BrewmasterPrecombatActions()
	BrewmasterDefaultActions()
}

AddIcon specialization=brewmaster help=cd enemies=1 checkbox=!opt_monk_brewmaster_aoe
{
	if InCombat(no) BrewmasterPrecombatCdActions()
	BrewmasterDefaultCdActions()
}

AddIcon specialization=brewmaster help=cd checkbox=opt_monk_brewmaster_aoe
{
	if InCombat(no) BrewmasterPrecombatCdActions()
	BrewmasterDefaultCdActions()
}

# Based on SimulationCraft profile "Monk_Windwalker_1h_T16M".
#	class=monk
#	spec=windwalker
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#fb!002221.

# ActionList: WindwalkerPrecombatActions --> main, shortcd, cd

AddFunction WindwalkerPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	# CHANGE: Buff with Legacy of the White Tiger
	if BuffExpires(str_agi_int_buff any=1) Spell(legacy_of_the_white_tiger)
	#stance,choose=fierce_tiger
	Spell(stance_of_the_fierce_tiger)
	#snapshot_stats
}

AddFunction WindwalkerPrecombatShortCdActions {}

AddFunction WindwalkerPrecombatCdActions
{
	unless BuffExpires(str_agi_int_buff any=1) and Spell(legacy_of_the_white_tiger)
		or Spell(stance_of_the_fierce_tiger)
	{
		#potion,name=virmens_bite
		UsePotionAgility()
	}
}

# ActionList: WindwalkerDefaultActions --> main, shortcd, cd

AddFunction WindwalkerDefaultActions
{
	#auto_attack
	#chi_brew,if=chi.max-chi>=2&((charges=1&recharge_time<=10)|charges=2|target.time_to_die<charges*10)&buff.tigereye_brew.stack<=16
	if MaxChi() - Chi() >= 2 and { Charges(chi_brew) == 1 and SpellChargeCooldown(chi_brew) <= 10 or Charges(chi_brew) == 2 or target.TimeToDie() < Charges(chi_brew) * 10 } and BuffStacks(tigereye_brew_buff) <= 16 Spell(chi_brew)
	#tiger_palm,if=buff.tiger_power.remains<=3
	if BuffRemaining(tiger_power_buff) <= 3 Spell(tiger_palm)
	#rising_sun_kick,if=(debuff.rising_sun_kick.down|debuff.rising_sun_kick.remains<3)
	if target.DebuffExpires(rising_sun_kick_debuff) or target.DebuffRemaining(rising_sun_kick_debuff) < 3 Spell(rising_sun_kick)
	#tiger_palm,if=buff.tiger_power.down&debuff.rising_sun_kick.remains>1&energy.time_to_max>1
	if BuffExpires(tiger_power_buff) and target.DebuffRemaining(rising_sun_kick_debuff) > 1 and TimeToMaxEnergy() > 1 Spell(tiger_palm)
	#call_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 WindwalkerAoeActions()
	#call_action_list,name=st,if=active_enemies<3
	if Enemies() < 3 WindwalkerStActions()
}

AddFunction WindwalkerDefaultShortCdActions
{
	unless BuffRemaining(tiger_power_buff) <= 3 and Spell(tiger_palm)
	{
		#tigereye_brew,if=buff.tigereye_brew_use.down&buff.tigereye_brew.stack=20
		if BuffExpires(tigereye_brew_use_buff) and BuffStacks(tigereye_brew_buff) == 20 Spell(tigereye_brew)
		#tigereye_brew,if=buff.tigereye_brew_use.down&buff.tigereye_brew.stack>=10&buff.serenity.up
		if BuffExpires(tigereye_brew_use_buff) and BuffStacks(tigereye_brew_buff) >= 10 and BuffPresent(serenity_buff) Spell(tigereye_brew)
		#tigereye_brew,if=buff.tigereye_brew_use.down&buff.tigereye_brew.stack>=10&cooldown.fists_of_fury.up&chi>=3&debuff.rising_sun_kick.up&buff.tiger_power.up
		if BuffExpires(tigereye_brew_use_buff) and BuffStacks(tigereye_brew_buff) >= 10 and not SpellCooldown(fists_of_fury) > 0 and Chi() >= 3 and target.DebuffPresent(rising_sun_kick_debuff) and BuffPresent(tiger_power_buff) Spell(tigereye_brew)
		#tigereye_brew,if=talent.hurricane_strike.enabled&buff.tigereye_brew_use.down&buff.tigereye_brew.stack>=10&cooldown.hurricane_strike.up&chi>=3&debuff.rising_sun_kick.up&buff.tiger_power.up
		if Talent(hurricane_strike_talent) and BuffExpires(tigereye_brew_use_buff) and BuffStacks(tigereye_brew_buff) >= 10 and not SpellCooldown(hurricane_strike) > 0 and Chi() >= 3 and target.DebuffPresent(rising_sun_kick_debuff) and BuffPresent(tiger_power_buff) Spell(tigereye_brew)
		#tigereye_brew,if=buff.tigereye_brew_use.down&chi>=2&(buff.tigereye_brew.stack>=16|target.time_to_die<40)&debuff.rising_sun_kick.up&buff.tiger_power.up
		if BuffExpires(tigereye_brew_use_buff) and Chi() >= 2 and { BuffStacks(tigereye_brew_buff) >= 16 or target.TimeToDie() < 40 } and target.DebuffPresent(rising_sun_kick_debuff) and BuffPresent(tiger_power_buff) Spell(tigereye_brew)

		unless { target.DebuffExpires(rising_sun_kick_debuff) or target.DebuffRemaining(rising_sun_kick_debuff) < 3 } and Spell(rising_sun_kick)
			or BuffExpires(tiger_power_buff) and target.DebuffRemaining(rising_sun_kick_debuff) > 1 and TimeToMaxEnergy() > 1 and Spell(tiger_palm)
		{
			#serenity,if=talent.serenity.enabled&chi>=2&buff.tiger_power.up&debuff.rising_sun_kick.up
			if Talent(serenity_talent) and Chi() >= 2 and BuffPresent(tiger_power_buff) and target.DebuffPresent(rising_sun_kick_debuff) Spell(serenity)
			#call_action_list,name=aoe,if=active_enemies>=3
			if Enemies() >= 3 WindwalkerAoeShortCdActions()
			#call_action_list,name=st,if=active_enemies<3
			if Enemies() < 3 WindwalkerStShortCdActions()
		}
	}
}

AddFunction WindwalkerDefaultCdActions
{
	# CHANGE: Touch of Death if it will kill the mob.
	if target.Health() < Health() and BuffPresent(death_note_buff) Spell(touch_of_death)
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()
	# CHANGE: Break snares with Nimble Brew.
	#invoke_xuen,if=talent.invoke_xuen.enabled&time>5
	if Talent(invoke_xuen_talent) and TimeInCombat() > 5 Spell(invoke_xuen)
	#potion,name=virmens_bite,if=buff.bloodlust.react|target.time_to_die<=60
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 UsePotionAgility()
	#blood_fury,if=buff.tigereye_brew_use.up|target.time_to_die<18
	if BuffPresent(tigereye_brew_use_buff) or target.TimeToDie() < 18 Spell(blood_fury_apsp)
	#berserking,if=buff.tigereye_brew_use.up|target.time_to_die<18
	if BuffPresent(tigereye_brew_use_buff) or target.TimeToDie() < 18 Spell(berserking)
	#arcane_torrent,if=buff.tigereye_brew_use.up|target.time_to_die<18
	if BuffPresent(tigereye_brew_use_buff) or target.TimeToDie() < 18 Spell(arcane_torrent_chi)

	unless BuffRemaining(tiger_power_buff) <= 3 and Spell(tiger_palm)
		or { target.DebuffExpires(rising_sun_kick_debuff) or target.DebuffRemaining(rising_sun_kick_debuff) < 3 } and Spell(rising_sun_kick)
		or BuffExpires(tiger_power_buff) and target.DebuffRemaining(rising_sun_kick_debuff) > 1 and TimeToMaxEnergy() > 1 and Spell(tiger_palm)
	{
		#call_action_list,name=aoe,if=active_enemies>=3
		if Enemies() >= 3 WindwalkerAoeCdActions()
		#call_action_list,name=st,if=active_enemies<3
		if Enemies() < 3 WindwalkerStCdActions()
	}
}

# ActionList: WindwalkerAoeActions --> main, shortcd, cd

AddFunction WindwalkerAoeActions
{
	#chi_explosion,if=chi>=4
	if Chi() >= 4 Spell(chi_explosion_melee)
	#rushing_jade_wind
	Spell(rushing_jade_wind)
	#rising_sun_kick,if=!talent.rushing_jade_wind.enabled&chi=chi.max
	if not Talent(rushing_jade_wind_talent) and Chi() == MaxChi() Spell(rising_sun_kick)
	#zen_sphere,cycle_targets=1,if=!dot.zen_sphere.ticking
	if not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#chi_wave,if=energy.time_to_max>2&buff.serenity.down
	if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) Spell(chi_wave)
	#chi_burst,if=talent.chi_burst.enabled&energy.time_to_max>2&buff.serenity.down
	if Talent(chi_burst_talent) and TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
	#blackout_kick,if=talent.rushing_jade_wind.enabled&!talent.chi_explosion.enabled&(buff.combo_breaker_bok.react|buff.serenity.up)
	if Talent(rushing_jade_wind_talent) and not Talent(chi_explosion_talent) and { BuffPresent(combo_breaker_bok_buff) or BuffPresent(serenity_buff) } Spell(blackout_kick)
	#tiger_palm,if=talent.rushing_jade_wind.enabled&buff.combo_breaker_tp.react&buff.combo_breaker_tp.remains<=2
	if Talent(rushing_jade_wind_talent) and BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 Spell(tiger_palm)
	#blackout_kick,if=talent.rushing_jade_wind.enabled&!talent.chi_explosion.enabled&chi.max-chi<2
	if Talent(rushing_jade_wind_talent) and not Talent(chi_explosion_talent) and MaxChi() - Chi() < 2 Spell(blackout_kick)
	#spinning_crane_kick,if=!talent.rushing_jade_wind.enabled
	if not Talent(rushing_jade_wind_talent) Spell(spinning_crane_kick)
	#jab,if=talent.rushing_jade_wind.enabled&chi.max-chi>=2
	if Talent(rushing_jade_wind_talent) and MaxChi() - Chi() >= 2 Spell(jab)
}

AddFunction WindwalkerAoeShortCdActions
{
	unless Chi() >= 4 and Spell(chi_explosion_melee)
		or Spell(rushing_jade_wind)
		or not Talent(rushing_jade_wind_talent) and Chi() == MaxChi() and Spell(rising_sun_kick)
	{
		#fists_of_fury,if=talent.rushing_jade_wind.enabled&energy.time_to_max>cast_time&buff.tiger_power.remains>cast_time&debuff.rising_sun_kick.remains>cast_time&!buff.serenity.remains
		if Talent(rushing_jade_wind_talent) and TimeToMaxEnergy() > CastTime(fists_of_fury) and BuffRemaining(tiger_power_buff) > CastTime(fists_of_fury) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(fists_of_fury) and not BuffPresent(serenity_buff) Spell(fists_of_fury)
		#touch_of_death,if=target.health.percent<10
		if target.HealthPercent() < 10 and BuffPresent(death_note_buff) Spell(touch_of_death)
		#hurricane_strike,if=talent.rushing_jade_wind.enabled&talent.hurricane_strike.enabled&energy.time_to_max>cast_time&buff.tiger_power.remains>cast_time&debuff.rising_sun_kick.remains>cast_time&buff.energizing_brew.down
		if Talent(rushing_jade_wind_talent) and Talent(hurricane_strike_talent) and TimeToMaxEnergy() > CastTime(hurricane_strike) and BuffRemaining(tiger_power_buff) > CastTime(hurricane_strike) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(hurricane_strike) and BuffExpires(energizing_brew_buff) Spell(hurricane_strike)
	}
}

AddFunction WindwalkerAoeCdActions {}

# ActionList: WindwalkerStActions --> main, shortcd, cd

AddFunction WindwalkerStActions
{
	#energizing_brew,if=cooldown.fists_of_fury.remains>6&(!talent.serenity.enabled|(!buff.serenity.remains&cooldown.serenity.remains>4))&energy+energy.regen*gcd<50
	if SpellCooldown(fists_of_fury) > 6 and { not Talent(serenity_talent) or not BuffPresent(serenity_buff) and SpellCooldown(serenity) > 4 } and Energy() + EnergyRegenRate() * GCD() < 50 Spell(energizing_brew)
	#rising_sun_kick,if=!talent.chi_explosion.enabled
	if not Talent(chi_explosion_talent) Spell(rising_sun_kick)
	#chi_wave,if=energy.time_to_max>2&buff.serenity.down
	if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) Spell(chi_wave)
	#chi_burst,if=talent.chi_burst.enabled&energy.time_to_max>2&buff.serenity.down
	if Talent(chi_burst_talent) and TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
	#zen_sphere,cycle_targets=1,if=energy.time_to_max>2&!dot.zen_sphere.ticking&buff.serenity.down
	if TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) and BuffExpires(serenity_buff) Spell(zen_sphere)
	#blackout_kick,if=!talent.chi_explosion.enabled&(buff.combo_breaker_bok.react|buff.serenity.up)
	if not Talent(chi_explosion_talent) and { BuffPresent(combo_breaker_bok_buff) or BuffPresent(serenity_buff) } Spell(blackout_kick)
	#chi_explosion,if=talent.chi_explosion.enabled&chi>=3&buff.combo_breaker_ce.react
	if Talent(chi_explosion_talent) and Chi() >= 3 and BuffPresent(combo_breaker_ce_buff) Spell(chi_explosion_melee)
	#tiger_palm,if=buff.combo_breaker_tp.react&buff.combo_breaker_tp.remains<=2
	if BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 Spell(tiger_palm)
	#blackout_kick,if=!talent.chi_explosion.enabled&chi.max-chi<2
	if not Talent(chi_explosion_talent) and MaxChi() - Chi() < 2 Spell(blackout_kick)
	#chi_explosion,if=talent.chi_explosion.enabled&chi>=3
	if Talent(chi_explosion_talent) and Chi() >= 3 Spell(chi_explosion_melee)
	#jab,if=chi.max-chi>=2
	if MaxChi() - Chi() >= 2 Spell(jab)
}

AddFunction WindwalkerStShortCdActions
{
	#fists_of_fury,if=energy.time_to_max>cast_time&buff.tiger_power.remains>cast_time&debuff.rising_sun_kick.remains>cast_time&!buff.serenity.remains
	if TimeToMaxEnergy() > CastTime(fists_of_fury) and BuffRemaining(tiger_power_buff) > CastTime(fists_of_fury) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(fists_of_fury) and not BuffPresent(serenity_buff) Spell(fists_of_fury)
	#touch_of_death,if=target.health.percent<10
	if target.HealthPercent() < 10 and BuffPresent(death_note_buff) Spell(touch_of_death)
	#hurricane_strike,if=talent.hurricane_strike.enabled&energy.time_to_max>cast_time&buff.tiger_power.remains>cast_time&debuff.rising_sun_kick.remains>cast_time&buff.energizing_brew.down
	if Talent(hurricane_strike_talent) and TimeToMaxEnergy() > CastTime(hurricane_strike) and BuffRemaining(tiger_power_buff) > CastTime(hurricane_strike) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(hurricane_strike) and BuffExpires(energizing_brew_buff) Spell(hurricane_strike)
}

AddFunction WindwalkerStCdActions {}

### Windwalker icons.
AddCheckBox(opt_monk_windwalker_aoe L(AOE) specialization=windwalker default)

AddIcon specialization=windwalker help=shortcd enemies=1 checkbox=!opt_monk_windwalker_aoe
{
	if InCombat(no) WindwalkerPrecombatShortCdActions()
	WindwalkerDefaultShortCdActions()
}

AddIcon specialization=windwalker help=shortcd checkbox=opt_monk_windwalker_aoe
{
	if InCombat(no) WindwalkerPrecombatShortCdActions()
	WindwalkerDefaultShortCdActions()
}

AddIcon specialization=windwalker help=main enemies=1
{
	if InCombat(no) WindwalkerPrecombatActions()
	WindwalkerDefaultActions()
}

AddIcon specialization=windwalker help=aoe checkbox=opt_monk_windwalker_aoe
{
	if InCombat(no) WindwalkerPrecombatActions()
	WindwalkerDefaultActions()
}

AddIcon specialization=windwalker help=cd enemies=1 checkbox=!opt_monk_windwalker_aoe
{
	if InCombat(no) WindwalkerPrecombatCdActions()
	WindwalkerDefaultCdActions()
}

AddIcon specialization=windwalker help=cd checkbox=opt_monk_windwalker_aoe
{
	if InCombat(no) WindwalkerPrecombatCdActions()
	WindwalkerDefaultCdActions()
}
]]

	OvaleScripts:RegisterScript("MONK", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("MONK", "Ovale", desc, code, "script")
end
