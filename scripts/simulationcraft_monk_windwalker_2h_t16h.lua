local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Monk_Windwalker_2h_T16H"
	local desc = "[5.4] SimulationCraft: Monk_Windwalker_2h_T16H"
	local code = [[
# Based on SimulationCraft profile "Monk_Windwalker_2h_T16H".
#	class=monk
#	spec=windwalker
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#fb!002221

Include(ovale_common)
Include(ovale_monk_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction WindwalkerPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#stance,choose=fierce_tiger
	if not Stance(monk_stance_of_the_fierce_tiger) Spell(stance_of_the_fierce_tiger)
	#snapshot_stats
	#virmens_bite_potion
	UsePotionAgility()
}

AddFunction WindwalkerDefaultActions
{
	#auto_attack
	#chi_sphere,if=talent.power_strikes.enabled&buff.chi_sphere.react&chi<4
	#virmens_bite_potion,if=buff.bloodlust.react|target.time_to_die<=60
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 UsePotionAgility()
	#use_item,name=gloves_of_the_golden_protector
	UseItemActions()
	#berserking
	Spell(berserking)
	#chi_brew,if=talent.chi_brew.enabled&chi<=2&(trinket.proc.agility.react|(charges=1&recharge_time<=10)|charges=2|target.time_to_die<charges*10)
	if Talent(chi_brew_talent) and Chi() <= 2 and { BuffPresent(trinket_proc_agility_buff) or Charges(chi_brew) == 1 and SpellChargeCooldown(chi_brew) <= 10 or Charges(chi_brew) == 2 or target.TimeToDie() < Charges(chi_brew) * 10 } Spell(chi_brew)
	#tiger_palm,if=buff.tiger_power.remains<=3
	if BuffRemaining(tiger_power_buff) <= 3 Spell(tiger_palm)
	#tigereye_brew,if=buff.tigereye_brew_use.down&buff.tigereye_brew.stack=20
	if BuffExpires(tigereye_brew_use_buff) and BuffStacks(tigereye_brew_buff) == 20 Spell(tigereye_brew)
	#tigereye_brew,if=buff.tigereye_brew_use.down&trinket.proc.agility.react
	if BuffExpires(tigereye_brew_use_buff) and BuffPresent(trinket_proc_agility_buff) Spell(tigereye_brew)
	#tigereye_brew,if=buff.tigereye_brew_use.down&chi>=2&(trinket.proc.agility.react|trinket.proc.strength.react|buff.tigereye_brew.stack>=15|target.time_to_die<40)&debuff.rising_sun_kick.up&buff.tiger_power.up
	if BuffExpires(tigereye_brew_use_buff) and Chi() >= 2 and { BuffPresent(trinket_proc_agility_buff) or BuffPresent(trinket_proc_strength_buff) or BuffStacks(tigereye_brew_buff) >= 15 or target.TimeToDie() < 40 } and target.DebuffPresent(rising_sun_kick_debuff) and BuffPresent(tiger_power_buff) Spell(tigereye_brew)
	#energizing_brew,if=energy.time_to_max>5
	if TimeToMaxEnergy() > 5 Spell(energizing_brew)
	#rising_sun_kick,if=debuff.rising_sun_kick.down
	if target.DebuffExpires(rising_sun_kick_debuff) Spell(rising_sun_kick)
	#tiger_palm,if=buff.tiger_power.down&debuff.rising_sun_kick.remains>1&energy.time_to_max>1
	if BuffExpires(tiger_power_buff) and target.DebuffRemaining(rising_sun_kick_debuff) > 1 and TimeToMaxEnergy() > 1 Spell(tiger_palm)
	#invoke_xuen,if=talent.invoke_xuen.enabled
	if Talent(invoke_xuen_talent) Spell(invoke_xuen)
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 WindwalkerAoeActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 WindwalkerSingleTargetActions()
}

AddFunction WindwalkerAoeActions
{
	#rushing_jade_wind,if=talent.rushing_jade_wind.enabled
	if Talent(rushing_jade_wind_talent) Spell(rushing_jade_wind)
	#zen_sphere,cycle_targets=1,if=talent.zen_sphere.enabled&!dot.zen_sphere.ticking
	if Talent(zen_sphere_talent) and not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#chi_wave,if=talent.chi_wave.enabled
	if Talent(chi_wave_talent) Spell(chi_wave)
	#chi_burst,if=talent.chi_burst.enabled
	if Talent(chi_burst_talent) Spell(chi_burst)
	#rising_sun_kick,if=chi=chi.max
	if Chi() == MaxChi() Spell(rising_sun_kick)
	#spinning_crane_kick,if=!talent.rushing_jade_wind.enabled
	if not Talent(rushing_jade_wind_talent) Spell(spinning_crane_kick)
}

AddFunction WindwalkerSingleTargetActions
{
	#rising_sun_kick
	Spell(rising_sun_kick)
	#fists_of_fury,if=buff.energizing_brew.down&energy.time_to_max>4&buff.tiger_power.remains>4
	if BuffExpires(energizing_brew_buff) and TimeToMaxEnergy() > 4 and BuffRemaining(tiger_power_buff) > 4 Spell(fists_of_fury)
	#chi_wave,if=talent.chi_wave.enabled&energy.time_to_max>2
	if Talent(chi_wave_talent) and TimeToMaxEnergy() > 2 Spell(chi_wave)
	#chi_burst,if=talent.chi_burst.enabled&energy.time_to_max>2
	if Talent(chi_burst_talent) and TimeToMaxEnergy() > 2 Spell(chi_burst)
	#zen_sphere,cycle_targets=1,if=talent.zen_sphere.enabled&energy.time_to_max>2&!dot.zen_sphere.ticking
	if Talent(zen_sphere_talent) and TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#blackout_kick,if=buff.combo_breaker_bok.react
	if BuffPresent(combo_breaker_bok_buff) Spell(blackout_kick)
	#tiger_palm,if=buff.combo_breaker_tp.react&(buff.combo_breaker_tp.remains<=2|energy.time_to_max>=2)
	if BuffPresent(combo_breaker_tp_buff) and { BuffRemaining(combo_breaker_tp_buff) <= 2 or TimeToMaxEnergy() >= 2 } Spell(tiger_palm)
	#jab,if=chi.max-chi>=2
	if MaxChi() - Chi() >= 2 Spell(jab)
	#blackout_kick,if=energy+energy.regen*cooldown.rising_sun_kick.remains>=40
	if Energy() + EnergyRegen() * SpellCooldown(rising_sun_kick) >= 40 Spell(blackout_kick)
}

AddIcon specialization=windwalker help=main enemies=1
{
	if InCombat(no) WindwalkerPrecombatActions()
	WindwalkerDefaultActions()
}

AddIcon specialization=windwalker help=aoe
{
	if InCombat(no) WindwalkerPrecombatActions()
	WindwalkerDefaultActions()
}

### Required symbols
# berserking
# blackout_kick
# chi_brew
# chi_brew_talent
# chi_burst
# chi_burst_talent
# chi_wave
# chi_wave_talent
# combo_breaker_bok_buff
# combo_breaker_tp_buff
# energizing_brew
# energizing_brew_buff
# fists_of_fury
# invoke_xuen
# invoke_xuen_talent
# jab
# rising_sun_kick
# rising_sun_kick_debuff
# rushing_jade_wind
# rushing_jade_wind_talent
# spinning_crane_kick
# stance_of_the_fierce_tiger
# tiger_palm
# tiger_power_buff
# tigereye_brew
# tigereye_brew_buff
# tigereye_brew_use_buff
# trinket_proc_agility_buff
# trinket_proc_strength_buff
# virmens_bite_potion
# zen_sphere
# zen_sphere_buff
# zen_sphere_talent
]]
	OvaleScripts:RegisterScript("MONK", name, desc, code, "reference")
end
