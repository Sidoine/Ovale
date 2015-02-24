local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_druid_balance_t17m"
	local desc = "[6.1] SimulationCraft: Druid_Balance_T17M"
	local code = [[
# Based on SimulationCraft profile "Druid_Balance_T17M".
#	class=druid
#	spec=balance
#	talents=0101001

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=balance)

AddFunction BalanceUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

### actions.default

AddFunction BalanceDefaultMainActions
{
	#call_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 BalanceSingleTargetMainActions()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 BalanceAoeMainActions()
}

AddFunction BalanceDefaultShortCdActions
{
	#force_of_nature,if=trinket.stat.intellect.up|charges=3|target.time_to_die<21
	if BuffPresent(trinket_stat_intellect_buff) or Charges(force_of_nature_caster) == 3 or target.TimeToDie() < 21 Spell(force_of_nature_caster)
}

AddFunction BalanceDefaultCdActions
{
	#potion,name=draenic_intellect,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) BalanceUsePotionIntellect()
	#blood_fury,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) Spell(blood_fury_apsp)
	#berserking,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) Spell(berserking)
	#arcane_torrent,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) Spell(arcane_torrent_energy)
	#call_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 BalanceSingleTargetCdActions()

	unless Enemies() == 1 and BalanceSingleTargetCdPostConditions()
	{
		#call_action_list,name=aoe,if=active_enemies>1
		if Enemies() > 1 BalanceAoeCdActions()
	}
}

### actions.aoe

AddFunction BalanceAoeMainActions
{
	#sunfire,cycle_targets=1,if=remains<8
	if target.DebuffRemaining(sunfire_debuff) < 8 Spell(sunfire)
	#starfall,if=!buff.starfall.up&active_enemies>2
	if not BuffPresent(starfall_buff) and Enemies() > 2 Spell(starfall)
	#starsurge,if=(charges=2&recharge_time<6)|charges=3
	if Charges(starsurge) == 2 and SpellChargeCooldown(starsurge) < 6 or Charges(starsurge) == 3 Spell(starsurge)
	#moonfire,cycle_targets=1,if=remains<12
	if target.DebuffRemaining(moonfire_debuff) < 12 Spell(moonfire)
	#stellar_flare,cycle_targets=1,if=remains<7
	if target.DebuffRemaining(stellar_flare_debuff) < 7 Spell(stellar_flare)
	#starsurge,if=buff.lunar_empowerment.down&eclipse_energy>20&active_enemies=2
	if BuffExpires(lunar_empowerment_buff) and EclipseEnergy() > 20 and Enemies() == 2 Spell(starsurge)
	#starsurge,if=buff.solar_empowerment.down&eclipse_energy<-40&active_enemies=2
	if BuffExpires(solar_empowerment_buff) and EclipseEnergy() < -40 and Enemies() == 2 Spell(starsurge)
	#wrath,if=(eclipse_energy<=0&eclipse_change>cast_time)|(eclipse_energy>0&cast_time>eclipse_change)
	if EclipseEnergy() <= 0 and TimeToEclipse() > CastTime(wrath) or EclipseEnergy() > 0 and CastTime(wrath) > TimeToEclipse() Spell(wrath)
	#starfire,if=(eclipse_energy>=0&eclipse_change>cast_time)|(eclipse_energy<0&cast_time>eclipse_change)
	if EclipseEnergy() >= 0 and TimeToEclipse() > CastTime(starfire) or EclipseEnergy() < 0 and CastTime(starfire) > TimeToEclipse() Spell(starfire)
	#wrath
	Spell(wrath)
}

AddFunction BalanceAoeCdActions
{
	#celestial_alignment,if=lunar_max<8|target.time_to_die<20
	if TimeToEclipse(lunar) < 8 or target.TimeToDie() < 20 Spell(celestial_alignment)
	#incarnation,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) Spell(incarnation_caster)
}

### actions.precombat

AddFunction BalancePrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=sleeper_sushi
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#moonkin_form
	Spell(moonkin_form)
	#starfire
	Spell(starfire)
}

AddFunction BalancePrecombatShortCdPostConditions
{
	not BuffPresent(str_agi_int_buff any=1) and Spell(mark_of_the_wild) or Spell(moonkin_form) or Spell(starfire)
}

AddFunction BalancePrecombatCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) and Spell(mark_of_the_wild) or Spell(moonkin_form)
	{
		#snapshot_stats
		#potion,name=draenic_intellect
		BalanceUsePotionIntellect()
		#incarnation
		Spell(incarnation_caster)
	}
}

AddFunction BalancePrecombatCdPostConditions
{
	not BuffPresent(str_agi_int_buff any=1) and Spell(mark_of_the_wild) or Spell(moonkin_form) or Spell(starfire)
}

### actions.single_target

AddFunction BalanceSingleTargetMainActions
{
	#starsurge,if=buff.lunar_empowerment.down&eclipse_energy>20
	if BuffExpires(lunar_empowerment_buff) and EclipseEnergy() > 20 Spell(starsurge)
	#starsurge,if=buff.solar_empowerment.down&eclipse_energy<-40
	if BuffExpires(solar_empowerment_buff) and EclipseEnergy() < -40 Spell(starsurge)
	#starsurge,if=(charges=2&recharge_time<6)|charges=3
	if Charges(starsurge) == 2 and SpellChargeCooldown(starsurge) < 6 or Charges(starsurge) == 3 Spell(starsurge)
	#sunfire,if=remains<7|(buff.solar_peak.up&!talent.balance_of_power.enabled)
	if target.DebuffRemaining(sunfire_debuff) < 7 or BuffPresent(solar_peak_buff) and not Talent(balance_of_power_talent) Spell(sunfire)
	#stellar_flare,if=remains<7
	if target.DebuffRemaining(stellar_flare_debuff) < 7 Spell(stellar_flare)
	#moonfire,if=!talent.balance_of_power.enabled&(buff.lunar_peak.up&remains<eclipse_change+20|remains<4|(buff.celestial_alignment.up&buff.celestial_alignment.remains<=2&remains<eclipse_change+20))
	if not Talent(balance_of_power_talent) and { BuffPresent(lunar_peak_buff) and target.DebuffRemaining(moonfire_debuff) < TimeToEclipse() + 20 or target.DebuffRemaining(moonfire_debuff) < 4 or BuffPresent(celestial_alignment_buff) and BuffRemaining(celestial_alignment_buff) <= 2 and target.DebuffRemaining(moonfire_debuff) < TimeToEclipse() + 20 } Spell(moonfire)
	#moonfire,if=talent.balance_of_power.enabled&(remains<4|(buff.celestial_alignment.up&buff.celestial_alignment.remains<=2&remains<eclipse_change+20))
	if Talent(balance_of_power_talent) and { target.DebuffRemaining(moonfire_debuff) < 4 or BuffPresent(celestial_alignment_buff) and BuffRemaining(celestial_alignment_buff) <= 2 and target.DebuffRemaining(moonfire_debuff) < TimeToEclipse() + 20 } Spell(moonfire)
	#wrath,if=(eclipse_energy<=0&eclipse_change>cast_time)|(eclipse_energy>0&cast_time>eclipse_change)
	if EclipseEnergy() <= 0 and TimeToEclipse() > CastTime(wrath) or EclipseEnergy() > 0 and CastTime(wrath) > TimeToEclipse() Spell(wrath)
	#starfire,if=(eclipse_energy>=0&eclipse_change>cast_time)|(eclipse_energy<0&cast_time>eclipse_change)
	if EclipseEnergy() >= 0 and TimeToEclipse() > CastTime(starfire) or EclipseEnergy() < 0 and CastTime(starfire) > TimeToEclipse() Spell(starfire)
	#wrath
	Spell(wrath)
}

AddFunction BalanceSingleTargetCdActions
{
	unless BuffExpires(lunar_empowerment_buff) and EclipseEnergy() > 20 and Spell(starsurge) or BuffExpires(solar_empowerment_buff) and EclipseEnergy() < -40 and Spell(starsurge) or { Charges(starsurge) == 2 and SpellChargeCooldown(starsurge) < 6 or Charges(starsurge) == 3 } and Spell(starsurge)
	{
		#celestial_alignment,if=eclipse_energy>40
		if EclipseEnergy() > 40 Spell(celestial_alignment)
		#incarnation,if=eclipse_energy>0
		if EclipseEnergy() > 0 Spell(incarnation_caster)
	}
}

AddFunction BalanceSingleTargetCdPostConditions
{
	BuffExpires(lunar_empowerment_buff) and EclipseEnergy() > 20 and Spell(starsurge) or BuffExpires(solar_empowerment_buff) and EclipseEnergy() < -40 and Spell(starsurge) or { Charges(starsurge) == 2 and SpellChargeCooldown(starsurge) < 6 or Charges(starsurge) == 3 } and Spell(starsurge) or { target.DebuffRemaining(sunfire_debuff) < 7 or BuffPresent(solar_peak_buff) and not Talent(balance_of_power_talent) } and Spell(sunfire) or target.DebuffRemaining(stellar_flare_debuff) < 7 and Spell(stellar_flare) or not Talent(balance_of_power_talent) and { BuffPresent(lunar_peak_buff) and target.DebuffRemaining(moonfire_debuff) < TimeToEclipse() + 20 or target.DebuffRemaining(moonfire_debuff) < 4 or BuffPresent(celestial_alignment_buff) and BuffRemaining(celestial_alignment_buff) <= 2 and target.DebuffRemaining(moonfire_debuff) < TimeToEclipse() + 20 } and Spell(moonfire) or Talent(balance_of_power_talent) and { target.DebuffRemaining(moonfire_debuff) < 4 or BuffPresent(celestial_alignment_buff) and BuffRemaining(celestial_alignment_buff) <= 2 and target.DebuffRemaining(moonfire_debuff) < TimeToEclipse() + 20 } and Spell(moonfire) or { EclipseEnergy() <= 0 and TimeToEclipse() > CastTime(wrath) or EclipseEnergy() > 0 and CastTime(wrath) > TimeToEclipse() } and Spell(wrath) or { EclipseEnergy() >= 0 and TimeToEclipse() > CastTime(starfire) or EclipseEnergy() < 0 and CastTime(starfire) > TimeToEclipse() } and Spell(starfire) or Spell(wrath)
}

### Balance icons.

AddCheckBox(opt_druid_balance_aoe L(AOE) default specialization=balance)

AddIcon checkbox=!opt_druid_balance_aoe enemies=1 help=shortcd specialization=balance
{
	unless not InCombat() and BalancePrecombatShortCdPostConditions()
	{
		BalanceDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_druid_balance_aoe help=shortcd specialization=balance
{
	unless not InCombat() and BalancePrecombatShortCdPostConditions()
	{
		BalanceDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=balance
{
	if not InCombat() BalancePrecombatMainActions()
	BalanceDefaultMainActions()
}

AddIcon checkbox=opt_druid_balance_aoe help=aoe specialization=balance
{
	if not InCombat() BalancePrecombatMainActions()
	BalanceDefaultMainActions()
}

AddIcon checkbox=!opt_druid_balance_aoe enemies=1 help=cd specialization=balance
{
	if not InCombat() BalancePrecombatCdActions()
	unless not InCombat() and BalancePrecombatCdPostConditions()
	{
		BalanceDefaultCdActions()
	}
}

AddIcon checkbox=opt_druid_balance_aoe help=cd specialization=balance
{
	if not InCombat() BalancePrecombatCdActions()
	unless not InCombat() and BalancePrecombatCdPostConditions()
	{
		BalanceDefaultCdActions()
	}
}

### Required symbols
# arcane_torrent_energy
# balance_of_power_talent
# berserking
# blood_fury_apsp
# celestial_alignment
# celestial_alignment_buff
# draenic_intellect_potion
# force_of_nature_caster
# incarnation_caster
# lunar_empowerment_buff
# lunar_peak_buff
# mark_of_the_wild
# moonfire
# moonfire_debuff
# moonkin_form
# solar_empowerment_buff
# solar_peak_buff
# starfall
# starfall_buff
# starfire
# starsurge
# stellar_flare
# stellar_flare_debuff
# sunfire
# sunfire_debuff
# wrath
]]
	OvaleScripts:RegisterScript("DRUID", "balance", name, desc, code, "script")
end
