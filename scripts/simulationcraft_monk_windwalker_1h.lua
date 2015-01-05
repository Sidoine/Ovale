local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Monk_Windwalker_1h_T17M"
	local desc = "[6.0] SimulationCraft: Monk_Windwalker_1h_T17M"
	local code = [[
# Based on SimulationCraft profile "Monk_Windwalker_1h_T17M".
#	class=monk
#	spec=windwalker
#	talents=0130023

Include(ovale_common)
Include(ovale_monk_spells)

AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default)
AddCheckBox(opt_chi_burst SpellName(chi_burst) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
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

### actions.default

AddFunction WindwalkerDefaultMainActions
{
	#chi_brew,if=chi.max-chi>=2&((charges=1&recharge_time<=10)|charges=2|target.time_to_die<charges*10)&buff.tigereye_brew.stack<=16
	if MaxChi() - Chi() >= 2 and { Charges(chi_brew) == 1 and SpellChargeCooldown(chi_brew) <= 10 or Charges(chi_brew) == 2 or target.TimeToDie() < Charges(chi_brew) * 10 } and BuffStacks(tigereye_brew_buff) <= 16 Spell(chi_brew)
	#tiger_palm,if=buff.tiger_power.remains<6
	if BuffRemaining(tiger_power_buff) < 6 Spell(tiger_palm)
	#rising_sun_kick,if=(debuff.rising_sun_kick.down|debuff.rising_sun_kick.remains<3)
	if target.DebuffExpires(rising_sun_kick_debuff) or target.DebuffRemaining(rising_sun_kick_debuff) < 3 Spell(rising_sun_kick)
	#tiger_palm,if=buff.tiger_power.down&debuff.rising_sun_kick.remains>1&energy.time_to_max>1
	if BuffExpires(tiger_power_buff) and target.DebuffRemaining(rising_sun_kick_debuff) > 1 and TimeToMaxEnergy() > 1 Spell(tiger_palm)
	#call_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 WindwalkerAoeMainActions()
	#call_action_list,name=st,if=active_enemies<3
	if Enemies() < 3 WindwalkerStMainActions()
}

AddFunction WindwalkerDefaultShortCdActions
{
	unless BuffRemaining(tiger_power_buff) < 6 and Spell(tiger_palm)
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

		unless { target.DebuffExpires(rising_sun_kick_debuff) or target.DebuffRemaining(rising_sun_kick_debuff) < 3 } and Spell(rising_sun_kick) or BuffExpires(tiger_power_buff) and target.DebuffRemaining(rising_sun_kick_debuff) > 1 and TimeToMaxEnergy() > 1 and Spell(tiger_palm)
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
	#auto_attack
	#invoke_xuen,if=talent.invoke_xuen.enabled&time>5
	if Talent(invoke_xuen_talent) and TimeInCombat() > 5 Spell(invoke_xuen)
	#chi_sphere,if=talent.power_strikes.enabled&buff.chi_sphere.react&chi<4
	#potion,name=draenic_agility,if=buff.serenity.up|(!talent.serenity.enabled&trinket.proc.agility.react)
	if BuffPresent(serenity_buff) or not Talent(serenity_talent) and BuffPresent(trinket_proc_agility_buff) UsePotionAgility()
	#blood_fury,if=buff.tigereye_brew_use.up|target.time_to_die<18
	if BuffPresent(tigereye_brew_use_buff) or target.TimeToDie() < 18 Spell(blood_fury_apsp)
	#berserking,if=buff.tigereye_brew_use.up|target.time_to_die<18
	if BuffPresent(tigereye_brew_use_buff) or target.TimeToDie() < 18 Spell(berserking)
	#arcane_torrent,if=chi.max-chi>=1&(buff.tigereye_brew_use.up|target.time_to_die<18)
	if MaxChi() - Chi() >= 1 and { BuffPresent(tigereye_brew_use_buff) or target.TimeToDie() < 18 } Spell(arcane_torrent_chi)

	unless BuffRemaining(tiger_power_buff) < 6 and Spell(tiger_palm) or { target.DebuffExpires(rising_sun_kick_debuff) or target.DebuffRemaining(rising_sun_kick_debuff) < 3 } and Spell(rising_sun_kick) or BuffExpires(tiger_power_buff) and target.DebuffRemaining(rising_sun_kick_debuff) > 1 and TimeToMaxEnergy() > 1 and Spell(tiger_palm)
	{
		#call_action_list,name=aoe,if=active_enemies>=3
		if Enemies() >= 3 WindwalkerAoeCdActions()
		#call_action_list,name=st,if=active_enemies<3
		if Enemies() < 3 WindwalkerStCdActions()
	}
}

### actions.aoe

AddFunction WindwalkerAoeMainActions
{
	#chi_explosion,if=chi>=4&(cooldown.fists_of_fury.remains>3|!talent.rushing_jade_wind.enabled)
	if Chi() >= 4 and { SpellCooldown(fists_of_fury) > 3 or not Talent(rushing_jade_wind_talent) } Spell(chi_explosion_melee)
	#rushing_jade_wind
	Spell(rushing_jade_wind)
	#rising_sun_kick,if=!talent.rushing_jade_wind.enabled&chi=chi.max
	if not Talent(rushing_jade_wind_talent) and Chi() == MaxChi() Spell(rising_sun_kick)
	#zen_sphere,cycle_targets=1,if=!dot.zen_sphere.ticking
	if not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#chi_wave,if=energy.time_to_max>2&buff.serenity.down
	if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) Spell(chi_wave)
	#blackout_kick,if=talent.rushing_jade_wind.enabled&!talent.chi_explosion.enabled&(buff.combo_breaker_bok.react|buff.serenity.up)
	if Talent(rushing_jade_wind_talent) and not Talent(chi_explosion_talent) and { BuffPresent(combo_breaker_bok_buff) or BuffPresent(serenity_buff) } Spell(blackout_kick)
	#tiger_palm,if=talent.rushing_jade_wind.enabled&buff.combo_breaker_tp.react&buff.combo_breaker_tp.remains<=2
	if Talent(rushing_jade_wind_talent) and BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) <= 2 Spell(tiger_palm)
	#blackout_kick,if=talent.rushing_jade_wind.enabled&!talent.chi_explosion.enabled&chi.max-chi<2&(cooldown.fists_of_fury.remains>3|!talent.rushing_jade_wind.enabled)
	if Talent(rushing_jade_wind_talent) and not Talent(chi_explosion_talent) and MaxChi() - Chi() < 2 and { SpellCooldown(fists_of_fury) > 3 or not Talent(rushing_jade_wind_talent) } Spell(blackout_kick)
	#spinning_crane_kick
	Spell(spinning_crane_kick)
	#jab,if=talent.rushing_jade_wind.enabled&chi.max-chi>=2
	if Talent(rushing_jade_wind_talent) and MaxChi() - Chi() >= 2 Spell(jab)
	#jab,if=talent.rushing_jade_wind.enabled&chi.max-chi>=1&talent.chi_explosion.enabled&cooldown.fists_of_fury.remains<=3
	if Talent(rushing_jade_wind_talent) and MaxChi() - Chi() >= 1 and Talent(chi_explosion_talent) and SpellCooldown(fists_of_fury) <= 3 Spell(jab)
}

AddFunction WindwalkerAoeShortCdActions
{
	unless Chi() >= 4 and { SpellCooldown(fists_of_fury) > 3 or not Talent(rushing_jade_wind_talent) } and Spell(chi_explosion_melee) or Spell(rushing_jade_wind)
	{
		#energizing_brew,if=cooldown.fists_of_fury.remains>6&(!talent.serenity.enabled|(!buff.serenity.remains&cooldown.serenity.remains>4))&energy+energy.regen*gcd<50
		if SpellCooldown(fists_of_fury) > 6 and { not Talent(serenity_talent) or not BuffPresent(serenity_buff) and SpellCooldown(serenity) > 4 } and Energy() + EnergyRegenRate() * GCD() < 50 Spell(energizing_brew)

		unless not Talent(rushing_jade_wind_talent) and Chi() == MaxChi() and Spell(rising_sun_kick)
		{
			#fists_of_fury,if=talent.rushing_jade_wind.enabled&buff.tiger_power.remains>cast_time&debuff.rising_sun_kick.remains>cast_time&!buff.serenity.remains
			if Talent(rushing_jade_wind_talent) and BuffRemaining(tiger_power_buff) > CastTime(fists_of_fury) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(fists_of_fury) and not BuffPresent(serenity_buff) Spell(fists_of_fury)
			#touch_of_death,if=target.health.percent<10
			if target.HealthPercent() < 10 and BuffPresent(death_note_buff) Spell(touch_of_death)
			#hurricane_strike,if=talent.rushing_jade_wind.enabled&talent.hurricane_strike.enabled&energy.time_to_max>cast_time&buff.tiger_power.remains>cast_time&debuff.rising_sun_kick.remains>cast_time&buff.energizing_brew.down
			if Talent(rushing_jade_wind_talent) and Talent(hurricane_strike_talent) and TimeToMaxEnergy() > CastTime(hurricane_strike) and BuffRemaining(tiger_power_buff) > CastTime(hurricane_strike) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(hurricane_strike) and BuffExpires(energizing_brew_buff) Spell(hurricane_strike)

			unless not BuffPresent(zen_sphere_buff) and Spell(zen_sphere) or TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and Spell(chi_wave)
			{
				#chi_burst,if=talent.chi_burst.enabled&energy.time_to_max>2&buff.serenity.down
				if Talent(chi_burst_talent) and TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
			}
		}
	}
}

AddFunction WindwalkerAoeCdActions
{
	unless Chi() >= 4 and { SpellCooldown(fists_of_fury) > 3 or not Talent(rushing_jade_wind_talent) } and Spell(chi_explosion_melee) or Spell(rushing_jade_wind) or not Talent(rushing_jade_wind_talent) and Chi() == MaxChi() and Spell(rising_sun_kick) or Talent(rushing_jade_wind_talent) and BuffRemaining(tiger_power_buff) > CastTime(fists_of_fury) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(fists_of_fury) and not BuffPresent(serenity_buff) and Spell(fists_of_fury)
	{
		#fortifying_brew,if=target.health.percent<10&cooldown.touch_of_death.remains=0
		if target.HealthPercent() < 10 and not SpellCooldown(touch_of_death) > 0 Spell(fortifying_brew)
	}
}

### actions.precombat

AddFunction WindwalkerPrecombatMainActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=rylak_crepes
	#stance,choose=fierce_tiger
	Spell(stance_of_the_fierce_tiger)
}

AddFunction WindwalkerPrecombatCdActions
{
	unless Spell(stance_of_the_fierce_tiger)
	{
		#snapshot_stats
		#potion,name=draenic_agility
		UsePotionAgility()
	}
}

### actions.st

AddFunction WindwalkerStMainActions
{
	#rising_sun_kick,if=!talent.chi_explosion.enabled
	if not Talent(chi_explosion_talent) Spell(rising_sun_kick)
	#chi_wave,if=energy.time_to_max>2&buff.serenity.down
	if TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=energy.time_to_max>2&!dot.zen_sphere.ticking&buff.serenity.down
	if TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) and BuffExpires(serenity_buff) Spell(zen_sphere)
	#blackout_kick,if=!talent.chi_explosion.enabled&(buff.combo_breaker_bok.react|buff.serenity.up)
	if not Talent(chi_explosion_talent) and { BuffPresent(combo_breaker_bok_buff) or BuffPresent(serenity_buff) } Spell(blackout_kick)
	#chi_explosion,if=talent.chi_explosion.enabled&chi>=3&buff.combo_breaker_ce.react&cooldown.fists_of_fury.remains>3
	if Talent(chi_explosion_talent) and Chi() >= 3 and BuffPresent(combo_breaker_ce_buff) and SpellCooldown(fists_of_fury) > 3 Spell(chi_explosion_melee)
	#tiger_palm,if=buff.combo_breaker_tp.react&buff.combo_breaker_tp.remains<6
	if BuffPresent(combo_breaker_tp_buff) and BuffRemaining(combo_breaker_tp_buff) < 6 Spell(tiger_palm)
	#blackout_kick,if=!talent.chi_explosion.enabled&chi.max-chi<2
	if not Talent(chi_explosion_talent) and MaxChi() - Chi() < 2 Spell(blackout_kick)
	#chi_explosion,if=talent.chi_explosion.enabled&chi>=3&cooldown.fists_of_fury.remains>3
	if Talent(chi_explosion_talent) and Chi() >= 3 and SpellCooldown(fists_of_fury) > 3 Spell(chi_explosion_melee)
	#jab,if=chi.max-chi>=2
	if MaxChi() - Chi() >= 2 Spell(jab)
	#jab,if=chi.max-chi>=1&talent.chi_explosion.enabled&cooldown.fists_of_fury.remains<=3
	if MaxChi() - Chi() >= 1 and Talent(chi_explosion_talent) and SpellCooldown(fists_of_fury) <= 3 Spell(jab)
}

AddFunction WindwalkerStShortCdActions
{
	#fists_of_fury,if=buff.tiger_power.remains>cast_time&debuff.rising_sun_kick.remains>cast_time&!buff.serenity.remains
	if BuffRemaining(tiger_power_buff) > CastTime(fists_of_fury) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(fists_of_fury) and not BuffPresent(serenity_buff) Spell(fists_of_fury)
	#touch_of_death,if=target.health.percent<10
	if target.HealthPercent() < 10 and BuffPresent(death_note_buff) Spell(touch_of_death)
	#hurricane_strike,if=talent.hurricane_strike.enabled&energy.time_to_max>cast_time&buff.tiger_power.remains>cast_time&debuff.rising_sun_kick.remains>cast_time&buff.energizing_brew.down
	if Talent(hurricane_strike_talent) and TimeToMaxEnergy() > CastTime(hurricane_strike) and BuffRemaining(tiger_power_buff) > CastTime(hurricane_strike) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(hurricane_strike) and BuffExpires(energizing_brew_buff) Spell(hurricane_strike)
	#energizing_brew,if=cooldown.fists_of_fury.remains>6&(!talent.serenity.enabled|(!buff.serenity.remains&cooldown.serenity.remains>4))&energy+energy.regen*gcd<50
	if SpellCooldown(fists_of_fury) > 6 and { not Talent(serenity_talent) or not BuffPresent(serenity_buff) and SpellCooldown(serenity) > 4 } and Energy() + EnergyRegenRate() * GCD() < 50 Spell(energizing_brew)

	unless not Talent(chi_explosion_talent) and Spell(rising_sun_kick) or TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and Spell(chi_wave)
	{
		#chi_burst,if=talent.chi_burst.enabled&energy.time_to_max>2&buff.serenity.down
		if Talent(chi_burst_talent) and TimeToMaxEnergy() > 2 and BuffExpires(serenity_buff) and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
	}
}

AddFunction WindwalkerStCdActions
{
	unless BuffRemaining(tiger_power_buff) > CastTime(fists_of_fury) and target.DebuffRemaining(rising_sun_kick_debuff) > CastTime(fists_of_fury) and not BuffPresent(serenity_buff) and Spell(fists_of_fury)
	{
		#fortifying_brew,if=target.health.percent<10&cooldown.touch_of_death.remains=0&chi>=3
		if target.HealthPercent() < 10 and not SpellCooldown(touch_of_death) > 0 and Chi() >= 3 Spell(fortifying_brew)
	}
}

### Windwalker icons.
AddCheckBox(opt_monk_windwalker_aoe L(AOE) specialization=windwalker default)

AddIcon specialization=windwalker help=shortcd enemies=1 checkbox=!opt_monk_windwalker_aoe
{
	WindwalkerDefaultShortCdActions()
}

AddIcon specialization=windwalker help=shortcd checkbox=opt_monk_windwalker_aoe
{
	WindwalkerDefaultShortCdActions()
}

AddIcon specialization=windwalker help=main enemies=1
{
	if not InCombat() WindwalkerPrecombatMainActions()
	WindwalkerDefaultMainActions()
}

AddIcon specialization=windwalker help=aoe checkbox=opt_monk_windwalker_aoe
{
	if not InCombat() WindwalkerPrecombatMainActions()
	WindwalkerDefaultMainActions()
}

AddIcon specialization=windwalker help=cd enemies=1 checkbox=!opt_monk_windwalker_aoe
{
	if not InCombat() WindwalkerPrecombatCdActions()
	WindwalkerDefaultCdActions()
}

AddIcon specialization=windwalker help=cd checkbox=opt_monk_windwalker_aoe
{
	if not InCombat() WindwalkerPrecombatCdActions()
	WindwalkerDefaultCdActions()
}

### Required symbols
# arcane_torrent_chi
# berserking
# blackout_kick
# blood_fury_apsp
# chi_brew
# chi_burst
# chi_burst_talent
# chi_explosion_melee
# chi_explosion_talent
# chi_wave
# combo_breaker_bok_buff
# combo_breaker_ce_buff
# combo_breaker_tp_buff
# death_note_buff
# draenic_agility_potion
# energizing_brew
# energizing_brew_buff
# fists_of_fury
# fortifying_brew
# hurricane_strike
# hurricane_strike_talent
# invoke_xuen
# invoke_xuen_talent
# jab
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
