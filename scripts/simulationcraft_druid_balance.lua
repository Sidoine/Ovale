local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_druid_balance_t18m"
	local desc = "[6.2] SimulationCraft: Druid_Balance_T18M"
	local code = [[
# Based on SimulationCraft profile "Druid_Balance_T18M".
#	class=druid
#	spec=balance
#	talents=0001001

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=balance)

AddFunction BalanceUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction BalanceUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

### actions.default

AddFunction BalanceDefaultMainActions
{
	#call_action_list,name=aoe,if=spell_targets.starfall_pulse>1
	if Enemies() > 1 BalanceAoeMainActions()
	#call_action_list,name=single_target
	BalanceSingleTargetMainActions()
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
	#use_item,slot=finger1
	BalanceUseItemActions()
	#call_action_list,name=aoe,if=spell_targets.starfall_pulse>1
	if Enemies() > 1 BalanceAoeCdActions()

	unless Enemies() > 1 and BalanceAoeCdPostConditions()
	{
		#call_action_list,name=single_target
		BalanceSingleTargetCdActions()
	}
}

### actions.aoe

AddFunction BalanceAoeMainActions
{
	#sunfire,cycle_targets=1,if=remains<8
	if target.DebuffRemaining(sunfire_debuff) < 8 Spell(sunfire)
	#starsurge,if=t18_class_trinket&buff.starfall.remains<3&spell_targets.starfall_pulse>1
	if HasTrinket(t18_class_trinket) and BuffRemaining(starfall_buff) < 3 and Enemies() > 1 Spell(starsurge)
	#starfall,if=!t18_class_trinket&buff.starfall.remains<3&spell_targets.starfall_pulse>2
	if not HasTrinket(t18_class_trinket) and BuffRemaining(starfall_buff) < 3 and Enemies() > 2 Spell(starfall)
	#starsurge,if=(charges=2&recharge_time<6)|charges=3
	if Charges(starsurge) == 2 and SpellChargeCooldown(starsurge) < 6 or Charges(starsurge) == 3 Spell(starsurge)
	#moonfire,cycle_targets=1,if=remains<12
	if target.DebuffRemaining(moonfire_debuff) < 12 Spell(moonfire)
	#stellar_flare,cycle_targets=1,if=remains<7
	if target.DebuffRemaining(stellar_flare_debuff) < 7 Spell(stellar_flare)
	#starsurge,if=buff.lunar_empowerment.down&eclipse_energy>20&spell_targets.starfall_pulse=2
	if BuffExpires(lunar_empowerment_buff) and EclipseEnergy() > 20 and Enemies() == 2 Spell(starsurge)
	#starsurge,if=buff.solar_empowerment.down&eclipse_energy<-40&spell_targets.starfall_pulse=2
	if BuffExpires(solar_empowerment_buff) and EclipseEnergy() < -40 and Enemies() == 2 Spell(starsurge)
	#wrath,if=(eclipse_energy<=0&eclipse_change>cast_time)|(eclipse_energy>0&cast_time>eclipse_change)
	if EclipseEnergy() <= 0 and TimeToEclipse() > CastTime(wrath) or EclipseEnergy() > 0 and CastTime(wrath) > TimeToEclipse() Spell(wrath)
	#starfire
	Spell(starfire)
}

AddFunction BalanceAoeCdActions
{
	#celestial_alignment,if=lunar_max<8|target.time_to_die<20
	if TimeToEclipse(lunar) < 8 or target.TimeToDie() < 20 Spell(celestial_alignment)
	#incarnation,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) Spell(incarnation_chosen_of_elune)
}

AddFunction BalanceAoeCdPostConditions
{
	target.DebuffRemaining(sunfire_debuff) < 8 and Spell(sunfire) or HasTrinket(t18_class_trinket) and BuffRemaining(starfall_buff) < 3 and Enemies() > 1 and Spell(starsurge) or not HasTrinket(t18_class_trinket) and BuffRemaining(starfall_buff) < 3 and Enemies() > 2 and Spell(starfall) or { Charges(starsurge) == 2 and SpellChargeCooldown(starsurge) < 6 or Charges(starsurge) == 3 } and Spell(starsurge) or target.DebuffRemaining(moonfire_debuff) < 12 and Spell(moonfire) or target.DebuffRemaining(stellar_flare_debuff) < 7 and Spell(stellar_flare) or BuffExpires(lunar_empowerment_buff) and EclipseEnergy() > 20 and Enemies() == 2 and Spell(starsurge) or BuffExpires(solar_empowerment_buff) and EclipseEnergy() < -40 and Enemies() == 2 and Spell(starsurge) or { EclipseEnergy() <= 0 and TimeToEclipse() > CastTime(wrath) or EclipseEnergy() > 0 and CastTime(wrath) > TimeToEclipse() } and Spell(wrath) or Spell(starfire)
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
		Spell(incarnation_chosen_of_elune)
	}
}

AddFunction BalancePrecombatCdPostConditions
{
	not BuffPresent(str_agi_int_buff any=1) and Spell(mark_of_the_wild) or Spell(moonkin_form) or Spell(starfire)
}

### actions.single_target

AddFunction BalanceSingleTargetMainActions
{
	#starsurge,if=buff.lunar_empowerment.down&(eclipse_energy>20|buff.celestial_alignment.up)
	if BuffExpires(lunar_empowerment_buff) and { EclipseEnergy() > 20 or BuffPresent(celestial_alignment_buff) } Spell(starsurge)
	#starsurge,if=buff.solar_empowerment.down&eclipse_energy<-40
	if BuffExpires(solar_empowerment_buff) and EclipseEnergy() < -40 Spell(starsurge)
	#starsurge,if=(charges=2&recharge_time<6)|charges=3
	if Charges(starsurge) == 2 and SpellChargeCooldown(starsurge) < 6 or Charges(starsurge) == 3 Spell(starsurge)
	#sunfire,if=remains<7|(buff.solar_peak.up&buff.solar_peak.remains<action.wrath.cast_time&!talent.balance_of_power.enabled)
	if target.DebuffRemaining(sunfire_debuff) < 7 or BuffPresent(solar_peak_buff) and BuffRemaining(solar_peak_buff) < CastTime(wrath) and not Talent(balance_of_power_talent) Spell(sunfire)
	#stellar_flare,if=remains<7
	if target.DebuffRemaining(stellar_flare_debuff) < 7 Spell(stellar_flare)
	#moonfire,if=!talent.balance_of_power.enabled&(buff.lunar_peak.up&buff.lunar_peak.remains<action.starfire.cast_time&remains<eclipse_change+20|remains<4|(buff.celestial_alignment.up&buff.celestial_alignment.remains<=2&remains<eclipse_change+20))
	if not Talent(balance_of_power_talent) and { BuffPresent(lunar_peak_buff) and BuffRemaining(lunar_peak_buff) < CastTime(starfire) and target.DebuffRemaining(moonfire_debuff) < TimeToEclipse() + 20 or target.DebuffRemaining(moonfire_debuff) < 4 or BuffPresent(celestial_alignment_buff) and BuffRemaining(celestial_alignment_buff) <= 2 and target.DebuffRemaining(moonfire_debuff) < TimeToEclipse() + 20 } Spell(moonfire)
	#moonfire,if=talent.balance_of_power.enabled&(remains<4|(buff.celestial_alignment.up&buff.celestial_alignment.remains<=2&remains<eclipse_change+20))
	if Talent(balance_of_power_talent) and { target.DebuffRemaining(moonfire_debuff) < 4 or BuffPresent(celestial_alignment_buff) and BuffRemaining(celestial_alignment_buff) <= 2 and target.DebuffRemaining(moonfire_debuff) < TimeToEclipse() + 20 } Spell(moonfire)
	#wrath,if=(eclipse_energy<=0&eclipse_change>cast_time)|(eclipse_energy>0&cast_time>eclipse_change)
	if EclipseEnergy() <= 0 and TimeToEclipse() > CastTime(wrath) or EclipseEnergy() > 0 and CastTime(wrath) > TimeToEclipse() Spell(wrath)
	#starfire
	Spell(starfire)
}

AddFunction BalanceSingleTargetCdActions
{
	unless BuffExpires(lunar_empowerment_buff) and { EclipseEnergy() > 20 or BuffPresent(celestial_alignment_buff) } and Spell(starsurge) or BuffExpires(solar_empowerment_buff) and EclipseEnergy() < -40 and Spell(starsurge) or { Charges(starsurge) == 2 and SpellChargeCooldown(starsurge) < 6 or Charges(starsurge) == 3 } and Spell(starsurge)
	{
		#celestial_alignment,if=eclipse_energy>0
		if EclipseEnergy() > 0 Spell(celestial_alignment)
		#incarnation,if=eclipse_energy>0
		if EclipseEnergy() > 0 Spell(incarnation_chosen_of_elune)
	}
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
# incarnation_chosen_of_elune
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
# t18_class_trinket
# wrath
]]
	OvaleScripts:RegisterScript("DRUID", "balance", name, desc, code, "script")
end
