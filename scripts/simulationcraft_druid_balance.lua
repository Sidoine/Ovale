local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Druid_Balance_T16M"
	local desc = "[6.0] SimulationCraft: Druid_Balance_T16M"
	local code = [[
# Based on SimulationCraft profile "Druid_Balance_T16M".
#	class=druid
#	spec=balance
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Ua!.0.0.0.

Include(ovale_common)
Include(ovale_druid_spells)

AddCheckBox(opt_potion_intellect ItemName(jade_serpent_potion) default)

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(jade_serpent_potion usable=1)
}

AddFunction BalancePrecombatActions
{
	#flask,type=warm_sun
	#food,type=seafood_magnifique_feast
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#moonkin_form
	Spell(moonkin_form)
	#snapshot_stats
	#potion,name=jade_serpent
	UsePotionIntellect()
	#stellar_flare
	Spell(stellar_flare)
}

AddFunction BalanceDefaultActions
{
	#potion,name=jade_serpent,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) UsePotionIntellect()
	#blood_fury,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) Spell(blood_fury_apsp)
	#berserking,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) Spell(berserking)
	#arcane_torrent,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) Spell(arcane_torrent_energy)
	#force_of_nature,if=trinket.stat.intellect.up|charges=3|target.time_to_die<21
	if BuffPresent(trinket_stat_intellect_buff) or Charges(force_of_nature_caster) == 3 or target.TimeToDie() < 21 Spell(force_of_nature_caster)
	#call_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 BalanceSingleTargetActions()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 BalanceAoeActions()
}

AddFunction BalanceAoeActions
{
	#celestial_alignment,if=lunar_max<8|target.time_to_die<20
	if TimeToEclipse(lunar) < 8 or target.TimeToDie() < 20 Spell(celestial_alignment)
	#incarnation,if=buff.celestial_alignment.up
	if BuffPresent(celestial_alignment_buff) Spell(incarnation_caster)
	#sunfire,if=remains<8
	if target.DebuffRemaining(sunfire_debuff) < 8 Spell(sunfire)
	#starfall
	Spell(starfall)
	#moonfire,cycle_targets=1,if=remains<12
	if target.DebuffRemaining(moonfire_debuff) < 12 Spell(moonfire)
	#stellar_flare,cycle_targets=1,if=remains<7
	if target.DebuffRemaining(stellar_flare_debuff) < 7 Spell(stellar_flare)
	#wrath,if=(eclipse_energy<=0&eclipse_change>cast_time)|(eclipse_energy>0&cast_time>eclipse_change)
	if EclipseEnergy() <= 0 and TimeToEclipse() > CastTime(wrath) or EclipseEnergy() > 0 and CastTime(wrath) > TimeToEclipse() Spell(wrath)
	#starfire,if=(eclipse_energy>=0&eclipse_change>cast_time)|(eclipse_energy<0&cast_time>eclipse_change)
	if EclipseEnergy() >= 0 and TimeToEclipse() > CastTime(starfire) or EclipseEnergy() < 0 and CastTime(starfire) > TimeToEclipse() Spell(starfire)
}

AddFunction BalanceSingleTargetActions
{
	#starsurge,if=buff.lunar_empowerment.down&eclipse_energy>20
	if BuffExpires(lunar_empowerment_buff) and EclipseEnergy() > 20 Spell(starsurge)
	#starsurge,if=buff.solar_empowerment.down&eclipse_energy<-40
	if BuffExpires(solar_empowerment_buff) and EclipseEnergy() < -40 Spell(starsurge)
	#starsurge,if=(charges=2&recharge_time<6)|charges=3
	if Charges(starsurge) == 2 and SpellChargeCooldown(starsurge) < 6 or Charges(starsurge) == 3 Spell(starsurge)
	#celestial_alignment,if=eclipse_energy>40
	if EclipseEnergy() > 40 Spell(celestial_alignment)
	#incarnation,if=eclipse_energy>0
	if EclipseEnergy() > 0 Spell(incarnation_caster)
	#sunfire,if=remains<7|buff.solar_peak.up
	if target.DebuffRemaining(sunfire_debuff) < 7 or BuffPresent(solar_peak_buff) Spell(sunfire)
	#stellar_flare,if=remains<7
	if target.DebuffRemaining(stellar_flare_debuff) < 7 Spell(stellar_flare)
	#moonfire,if=buff.lunar_peak.up&remains<eclipse_change+20|remains<4|(buff.celestial_alignment.up&buff.celestial_alignment.remains<=2&remains<eclipse_change+20)
	if BuffPresent(lunar_peak_buff) and target.DebuffRemaining(moonfire_debuff) < TimeToEclipse() + 20 or target.DebuffRemaining(moonfire_debuff) < 4 or BuffPresent(celestial_alignment_buff) and BuffRemaining(celestial_alignment_buff) <= 2 and target.DebuffRemaining(moonfire_debuff) < TimeToEclipse() + 20 Spell(moonfire)
	#wrath,if=(eclipse_energy<=0&eclipse_change>cast_time)|(eclipse_energy>0&cast_time>eclipse_change)
	if EclipseEnergy() <= 0 and TimeToEclipse() > CastTime(wrath) or EclipseEnergy() > 0 and CastTime(wrath) > TimeToEclipse() Spell(wrath)
	#starfire,if=(eclipse_energy>=0&eclipse_change>cast_time)|(eclipse_energy<0&cast_time>eclipse_change)
	if EclipseEnergy() >= 0 and TimeToEclipse() > CastTime(starfire) or EclipseEnergy() < 0 and CastTime(starfire) > TimeToEclipse() Spell(starfire)
}

AddIcon specialization=balance help=main enemies=1
{
	if not InCombat() BalancePrecombatActions()
	BalanceDefaultActions()
}

AddIcon specialization=balance help=aoe
{
	if not InCombat() BalancePrecombatActions()
	BalanceDefaultActions()
}

### Required symbols
# arcane_torrent_energy
# berserking
# blood_fury_apsp
# celestial_alignment
# celestial_alignment_buff
# force_of_nature_caster
# incarnation_caster
# jade_serpent_potion
# lunar_empowerment_buff
# lunar_peak_buff
# mark_of_the_wild
# moonfire
# moonfire_debuff
# moonkin_form
# solar_empowerment_buff
# solar_peak_buff
# starfall
# starfire
# starsurge
# stellar_flare
# stellar_flare_debuff
# sunfire
# sunfire_debuff
# trinket_stat_intellect_buff
# wrath
]]
	OvaleScripts:RegisterScript("DRUID", name, desc, code, "reference")
end
