local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "icyveins_druid_guardian"
	local desc = "[7.3.2] Icy-Veins: Druid Guardian"
	local code = [[

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=guardian)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=guardian)
AddCheckBox(opt_druid_guardian_aoe L(AOE) default specialization=guardian)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=guardian)

AddFunction FrenziedRegenHealModifier
{
	(1+Versatility()/100) * 
	(1+0.20*BuffPresent(guardian_of_elune_buff)) * 
	(1+0.05*ArtifactTraitRank(wildflesh_trait)) *
	(1+0.12*HasEquippedItem(skysecs_hold)) * 
	# Guardian Spirit
	(1+0.40*BuffPresent(47788)) *
	# Divine Hymn
	(1+0.1*BuffPresent(64844)) *
	# Protection of Tyr
	(1+0.15*BuffPresent(211210)) *
	# Life Cocoon 
	(1+0.5*BuffPresent(116849)) *
	# T21
	(1+0.1*BuffPresent(253575)) *
	1
}

AddFunction FrenziedRegenHealTotal
{
	IncomingDamage(5) / 2
}

AddFunction GuardianHealMe
{
	unless(DebuffPresent(healing_immunity_debuff)) 
	{
		if BuffExpires(frenzied_regeneration_buff) and HealthPercent() <= 70 
		{
			if (FrenziedRegenHealTotal() >= MaxHealth() * 0.20) Spell(frenzied_regeneration)
		}
		
		if HealthPercent() <= 50 Spell(lunar_beam)
		if HealthPercent() <= 80 and not InCombat() Spell(regrowth)
		if HealthPercent() < 35 UseHealthPotions()
	}
}

AddFunction GuardianGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and (Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred))
	{
		if target.InRange(wild_charge) Spell(wild_charge)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction GuardianDefaultShortCDActions
{
	GuardianHealMe()
	if IncomingDamage(5 physical=1) Spell(ironfur)
	GuardianGetInMeleeRange()
}

#
# Single-Target
#

AddFunction GuardianDefaultMainActions
{
	if not Stance(druid_bear_form) Spell(bear_form)
	if not BuffExpires(incarnation_guardian_of_ursoc_buff) 
	{
		if (BuffRefreshable(pulverize_buff)) Spell(pulverize)
		if target.DebuffStacks(thrash_bear_debuff) < SpellData(thrash_bear_debuff max_stacks) Spell(thrash_bear)
		if Talent(soul_of_the_forest_talent) Spell(mangle)
		Spell(thrash_bear)
	}
	
	Spell(mangle)
	if not BuffExpires(galactic_guardian_buff) Spell(moonfire)
	Spell(thrash_bear)
	if (BuffRefreshable(pulverize_buff) or target.DebuffStacks(thrash_bear_debuff) >= 5) Spell(pulverize)
	if target.DebuffRefreshable(moonfire_debuff) Spell(moonfire)
	if RageDeficit() <= 20 Spell(maul)
	Spell(swipe_bear)
}

#
# AOE
#

AddFunction GuardianDefaultAoEActions
{
	if not Stance(druid_bear_form) Spell(bear_form)
	if Enemies() >= 4 and HealthPercent() <= 80 Spell(lunar_beam)
	
	if not BuffExpires(incarnation_guardian_of_ursoc_buff) 
	{
		if (BuffRefreshable(pulverize_buff)) Spell(pulverize)
		if target.DebuffStacks(thrash_bear_debuff) < SpellData(thrash_bear_debuff max_stacks) Spell(thrash_bear)
		if Talent(soul_of_the_forest_talent) and Enemies() <= 3 Spell(mangle)
		Spell(thrash_bear)
	}
	
	Spell(thrash_bear)
	Spell(mangle)
	if not BuffExpires(galactic_guardian_buff) Spell(moonfire)
	if (BuffRefreshable(pulverize_buff) or target.DebuffStacks(thrash_bear_debuff) >= 5) Spell(pulverize)
	if Enemies() <= 3 and target.DebuffRefreshable(moonfire_debuff) Spell(moonfire)
	if Enemies() <= 3 and RageDeficit() <= 20 Spell(maul)
	Spell(swipe_bear)
}

AddFunction GuardianDefaultCdActions 
{
	GuardianInterruptActions()
	Spell(incarnation_guardian_of_ursoc)
	if HasArtifactTrait(embrace_of_the_nightmare) Spell(rage_of_the_sleeper)
	if BuffExpires(bristling_fur_buff) and BuffExpires(survival_instincts_buff) and BuffExpires(rage_of_the_sleeper_buff) and BuffExpires(barkskin_buff) and BuffExpires(potion_buff)
	{
		Spell(bristling_fur)
		if (HasEquippedItem(shifting_cosmic_sliver)) Spell(survival_instincts)
		Item(Trinket0Slot usable=1 text=13)
		Item(Trinket1Slot usable=1 text=14)
		Spell(barkskin)
		Spell(rage_of_the_sleeper)
		Spell(survival_instincts)
		if CheckBoxOn(opt_use_consumables) Item(unbending_potion usable=1)
	}
}

AddFunction GuardianInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
	{
		if target.InRange(skull_bash) and target.IsInterruptible() Spell(skull_bash)
		if not target.Classification(worldboss)
		{
			Spell(mighty_bash)
			if target.Distance(less 10) Spell(incapacitating_roar)
			if target.Distance(less 8) Spell(war_stomp)
			if target.Distance(less 15) Spell(typhoon)
		}
	}
}

AddIcon help=shortcd specialization=guardian
{
	GuardianDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=guardian
{
	GuardianDefaultMainActions()
}

AddIcon checkbox=opt_druid_guardian_aoe help=aoe specialization=guardian
{
	GuardianDefaultAoEActions()
}

AddIcon help=cd specialization=guardian
{
	GuardianDefaultCdActions()
}
	
]]
	OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
end


-- THE REST OF THIS FILE IS AUTOMATICALLY GENERATED.
-- ANY CHANGES MADE BELOW THIS POINT WILL BE LOST.

do
	local name = "simulationcraft_druid_balance_t19p"
	local desc = "[7.0] SimulationCraft: Druid_Balance_T19P"
	local code = [[
# Based on SimulationCraft profile "Druid_Balance_T19P".
#	class=druid
#	spec=balance
#	talents=3200233

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=balance)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=balance)

AddFunction BalanceInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
	{
		if target.InRange(solar_beam) and target.IsInterruptible() Spell(solar_beam)
		if target.InRange(mighty_bash) and not target.Classification(worldboss) Spell(mighty_bash)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
		if target.Distance(less 15) and not target.Classification(worldboss) Spell(typhoon)
	}
}

### actions.default

AddFunction BalanceDefaultMainActions
{
	#blessing_of_elune,if=active_enemies<=2&talent.blessing_of_the_ancients.enabled&buff.blessing_of_elune.down
	if Enemies() <= 2 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_elune_buff) Spell(blessing_of_elune)
	#blessing_of_elune,if=active_enemies>=3&talent.blessing_of_the_ancients.enabled&buff.blessing_of_anshe.down
	if Enemies() >= 3 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_anshe_buff) Spell(blessing_of_elune)
	#call_action_list,name=fury_of_elune,if=talent.fury_of_elune.enabled&cooldown.fury_of_elue.remains<target.time_to_die
	if Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() BalanceFuryOfEluneMainActions()

	unless Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() and BalanceFuryOfEluneMainPostConditions()
	{
		#call_action_list,name=ed,if=equipped.the_emerald_dreamcatcher&active_enemies<=2
		if HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 2 BalanceEdMainActions()

		unless HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 2 and BalanceEdMainPostConditions()
		{
			#new_moon,if=(charges=2&recharge_time<5)|charges=3
			if { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
			#half_moon,if=(charges=2&recharge_time<5)|charges=3|(target.time_to_die<15&charges=2)
			if { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 or target.TimeToDie() < 15 and Charges(half_moon) == 2 } and SpellKnown(half_moon) Spell(half_moon)
			#full_moon,if=(charges=2&recharge_time<5)|charges=3|target.time_to_die<15
			if { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 or target.TimeToDie() < 15 } and SpellKnown(full_moon) Spell(full_moon)
			#stellar_flare,cycle_targets=1,max_cycle_targets=4,if=active_enemies<4&remains<7.2&astral_power>=15
			if DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7.2 and AstralPower() >= 15 Spell(stellar_flare)
			#moonfire,cycle_targets=1,if=(talent.natures_balance.enabled&remains<3)|(remains<6.6&!talent.natures_balance.enabled)
			if Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6.6 and not Talent(natures_balance_talent) Spell(moonfire)
			#sunfire,if=(talent.natures_balance.enabled&remains<3)|(remains<5.4&!talent.natures_balance.enabled)
			if Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5.4 and not Talent(natures_balance_talent) Spell(sunfire)
			#starfall,if=buff.oneths_overconfidence.up
			if BuffPresent(oneths_overconfidence_buff) Spell(starfall)
			#solar_wrath,if=buff.solar_empowerment.stack=3
			if BuffStacks(solar_empowerment_buff) == 3 Spell(solar_wrath)
			#lunar_strike,if=buff.lunar_empowerment.stack=3
			if BuffStacks(lunar_empowerment_buff) == 3 Spell(lunar_strike_balance)
			#call_action_list,name=celestial_alignment_phase,if=buff.celestial_alignment.up|buff.incarnation.up
			if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) BalanceCelestialAlignmentPhaseMainActions()

			unless { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and BalanceCelestialAlignmentPhaseMainPostConditions()
			{
				#call_action_list,name=single_target
				BalanceSingleTargetMainActions()
			}
		}
	}
}

AddFunction BalanceDefaultMainPostConditions
{
	Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() and BalanceFuryOfEluneMainPostConditions() or HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 2 and BalanceEdMainPostConditions() or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and BalanceCelestialAlignmentPhaseMainPostConditions() or BalanceSingleTargetMainPostConditions()
}

AddFunction BalanceDefaultShortCdActions
{
	unless Enemies() <= 2 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_elune_buff) and Spell(blessing_of_elune) or Enemies() >= 3 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_anshe_buff) and Spell(blessing_of_elune)
	{
		#call_action_list,name=fury_of_elune,if=talent.fury_of_elune.enabled&cooldown.fury_of_elue.remains<target.time_to_die
		if Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() BalanceFuryOfEluneShortCdActions()

		unless Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() and BalanceFuryOfEluneShortCdPostConditions()
		{
			#call_action_list,name=ed,if=equipped.the_emerald_dreamcatcher&active_enemies<=2
			if HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 2 BalanceEdShortCdActions()

			unless HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 2 and BalanceEdShortCdPostConditions() or { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 or target.TimeToDie() < 15 and Charges(half_moon) == 2 } and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 or target.TimeToDie() < 15 } and SpellKnown(full_moon) and Spell(full_moon) or DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7.2 and AstralPower() >= 15 and Spell(stellar_flare) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6.6 and not Talent(natures_balance_talent) } and Spell(moonfire) or { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5.4 and not Talent(natures_balance_talent) } and Spell(sunfire)
			{
				#astral_communion,if=astral_power.deficit>=75
				if AstralPowerDeficit() >= 75 Spell(astral_communion)

				unless BuffPresent(oneths_overconfidence_buff) and Spell(starfall) or BuffStacks(solar_empowerment_buff) == 3 and Spell(solar_wrath) or BuffStacks(lunar_empowerment_buff) == 3 and Spell(lunar_strike_balance)
				{
					#call_action_list,name=celestial_alignment_phase,if=buff.celestial_alignment.up|buff.incarnation.up
					if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) BalanceCelestialAlignmentPhaseShortCdActions()

					unless { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and BalanceCelestialAlignmentPhaseShortCdPostConditions()
					{
						#call_action_list,name=single_target
						BalanceSingleTargetShortCdActions()
					}
				}
			}
		}
	}
}

AddFunction BalanceDefaultShortCdPostConditions
{
	Enemies() <= 2 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_elune_buff) and Spell(blessing_of_elune) or Enemies() >= 3 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_anshe_buff) and Spell(blessing_of_elune) or Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() and BalanceFuryOfEluneShortCdPostConditions() or HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 2 and BalanceEdShortCdPostConditions() or { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 or target.TimeToDie() < 15 and Charges(half_moon) == 2 } and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 or target.TimeToDie() < 15 } and SpellKnown(full_moon) and Spell(full_moon) or DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7.2 and AstralPower() >= 15 and Spell(stellar_flare) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6.6 and not Talent(natures_balance_talent) } and Spell(moonfire) or { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5.4 and not Talent(natures_balance_talent) } and Spell(sunfire) or BuffPresent(oneths_overconfidence_buff) and Spell(starfall) or BuffStacks(solar_empowerment_buff) == 3 and Spell(solar_wrath) or BuffStacks(lunar_empowerment_buff) == 3 and Spell(lunar_strike_balance) or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and BalanceCelestialAlignmentPhaseShortCdPostConditions() or BalanceSingleTargetShortCdPostConditions()
}

AddFunction BalanceDefaultCdActions
{
	#potion,name=deadly_grace,if=buff.celestial_alignment.up|buff.incarnation.up
	if { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(deadly_grace_potion usable=1)
	#solar_beam
	BalanceInterruptActions()

	unless Enemies() <= 2 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_elune_buff) and Spell(blessing_of_elune) or Enemies() >= 3 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_anshe_buff) and Spell(blessing_of_elune)
	{
		#blood_fury,if=buff.celestial_alignment.up|buff.incarnation.up
		if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) Spell(blood_fury_apsp)
		#berserking,if=buff.celestial_alignment.up|buff.incarnation.up
		if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) Spell(berserking)
		#arcane_torrent,if=buff.celestial_alignment.up|buff.incarnation.up
		if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) Spell(arcane_torrent_energy)
		#call_action_list,name=fury_of_elune,if=talent.fury_of_elune.enabled&cooldown.fury_of_elue.remains<target.time_to_die
		if Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() BalanceFuryOfEluneCdActions()

		unless Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() and BalanceFuryOfEluneCdPostConditions()
		{
			#call_action_list,name=ed,if=equipped.the_emerald_dreamcatcher&active_enemies<=2
			if HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 2 BalanceEdCdActions()

			unless HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 2 and BalanceEdCdPostConditions() or { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 or target.TimeToDie() < 15 and Charges(half_moon) == 2 } and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 or target.TimeToDie() < 15 } and SpellKnown(full_moon) and Spell(full_moon) or DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7.2 and AstralPower() >= 15 and Spell(stellar_flare) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6.6 and not Talent(natures_balance_talent) } and Spell(moonfire) or { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5.4 and not Talent(natures_balance_talent) } and Spell(sunfire) or AstralPowerDeficit() >= 75 and Spell(astral_communion)
			{
				#incarnation,if=astral_power>=40
				if AstralPower() >= 40 Spell(incarnation_chosen_of_elune)
				#celestial_alignment,if=astral_power>=40
				if AstralPower() >= 40 Spell(celestial_alignment)

				unless BuffPresent(oneths_overconfidence_buff) and Spell(starfall) or BuffStacks(solar_empowerment_buff) == 3 and Spell(solar_wrath) or BuffStacks(lunar_empowerment_buff) == 3 and Spell(lunar_strike_balance)
				{
					#call_action_list,name=celestial_alignment_phase,if=buff.celestial_alignment.up|buff.incarnation.up
					if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) BalanceCelestialAlignmentPhaseCdActions()

					unless { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and BalanceCelestialAlignmentPhaseCdPostConditions()
					{
						#call_action_list,name=single_target
						BalanceSingleTargetCdActions()
					}
				}
			}
		}
	}
}

AddFunction BalanceDefaultCdPostConditions
{
	Enemies() <= 2 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_elune_buff) and Spell(blessing_of_elune) or Enemies() >= 3 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_anshe_buff) and Spell(blessing_of_elune) or Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() and BalanceFuryOfEluneCdPostConditions() or HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 2 and BalanceEdCdPostConditions() or { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 or target.TimeToDie() < 15 and Charges(half_moon) == 2 } and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 or target.TimeToDie() < 15 } and SpellKnown(full_moon) and Spell(full_moon) or DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7.2 and AstralPower() >= 15 and Spell(stellar_flare) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6.6 and not Talent(natures_balance_talent) } and Spell(moonfire) or { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5.4 and not Talent(natures_balance_talent) } and Spell(sunfire) or AstralPowerDeficit() >= 75 and Spell(astral_communion) or BuffPresent(oneths_overconfidence_buff) and Spell(starfall) or BuffStacks(solar_empowerment_buff) == 3 and Spell(solar_wrath) or BuffStacks(lunar_empowerment_buff) == 3 and Spell(lunar_strike_balance) or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and BalanceCelestialAlignmentPhaseCdPostConditions() or BalanceSingleTargetCdPostConditions()
}

### actions.celestial_alignment_phase

AddFunction BalanceCelestialAlignmentPhaseMainActions
{
	#starfall,if=((active_enemies>=2&talent.stellar_drift.enabled)|active_enemies>=3)
	if Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 Spell(starfall)
	#starsurge,if=active_enemies<=2
	if Enemies() <= 2 Spell(starsurge_moonkin)
	#lunar_strike,if=buff.warrior_of_elune.up
	if BuffPresent(warrior_of_elune_buff) Spell(lunar_strike_balance)
	#solar_wrath,if=buff.solar_empowerment.up
	if BuffPresent(solar_empowerment_buff) Spell(solar_wrath)
	#lunar_strike,if=buff.lunar_empowerment.up
	if BuffPresent(lunar_empowerment_buff) Spell(lunar_strike_balance)
	#solar_wrath,if=talent.natures_balance.enabled&dot.sunfire_dmg.remains<5&cast_time<dot.sunfire_dmg.remains
	if Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_dmg_debuff) < 5 and CastTime(solar_wrath) < target.DebuffRemaining(sunfire_dmg_debuff) Spell(solar_wrath)
	#lunar_strike,if=(talent.natures_balance.enabled&dot.moonfire_dmg.remains<5&cast_time<dot.moonfire_dmg.remains)|active_enemies>=2
	if Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_dmg_debuff) < 5 and CastTime(lunar_strike_balance) < target.DebuffRemaining(moonfire_dmg_debuff) or Enemies() >= 2 Spell(lunar_strike_balance)
	#solar_wrath
	Spell(solar_wrath)
}

AddFunction BalanceCelestialAlignmentPhaseMainPostConditions
{
}

AddFunction BalanceCelestialAlignmentPhaseShortCdActions
{
	unless { Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 } and Spell(starfall) or Enemies() <= 2 and Spell(starsurge_moonkin)
	{
		#warrior_of_elune
		Spell(warrior_of_elune)
	}
}

AddFunction BalanceCelestialAlignmentPhaseShortCdPostConditions
{
	{ Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 } and Spell(starfall) or Enemies() <= 2 and Spell(starsurge_moonkin) or BuffPresent(warrior_of_elune_buff) and Spell(lunar_strike_balance) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike_balance) or Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_dmg_debuff) < 5 and CastTime(solar_wrath) < target.DebuffRemaining(sunfire_dmg_debuff) and Spell(solar_wrath) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_dmg_debuff) < 5 and CastTime(lunar_strike_balance) < target.DebuffRemaining(moonfire_dmg_debuff) or Enemies() >= 2 } and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

AddFunction BalanceCelestialAlignmentPhaseCdActions
{
}

AddFunction BalanceCelestialAlignmentPhaseCdPostConditions
{
	{ Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 } and Spell(starfall) or Enemies() <= 2 and Spell(starsurge_moonkin) or BuffPresent(warrior_of_elune_buff) and Spell(lunar_strike_balance) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike_balance) or Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_dmg_debuff) < 5 and CastTime(solar_wrath) < target.DebuffRemaining(sunfire_dmg_debuff) and Spell(solar_wrath) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_dmg_debuff) < 5 and CastTime(lunar_strike_balance) < target.DebuffRemaining(moonfire_dmg_debuff) or Enemies() >= 2 } and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

### actions.ed

AddFunction BalanceEdMainActions
{
	#starsurge,if=(buff.celestial_alignment.up&buff.celestial_alignment.remains<(10))|(buff.incarnation.up&buff.incarnation.remains<(3*execute_time)&astral_power>78)|(buff.incarnation.up&buff.incarnation.remains<(2*execute_time)&astral_power>52)|(buff.incarnation.up&buff.incarnation.remains<execute_time&astral_power>26)
	if BuffPresent(celestial_alignment_buff) and BuffRemaining(celestial_alignment_buff) < 10 or BuffPresent(incarnation_chosen_of_elune_buff) and BuffRemaining(incarnation_chosen_of_elune_buff) < 3 * ExecuteTime(starsurge_moonkin) and AstralPower() > 78 or BuffPresent(incarnation_chosen_of_elune_buff) and BuffRemaining(incarnation_chosen_of_elune_buff) < 2 * ExecuteTime(starsurge_moonkin) and AstralPower() > 52 or BuffPresent(incarnation_chosen_of_elune_buff) and BuffRemaining(incarnation_chosen_of_elune_buff) < ExecuteTime(starsurge_moonkin) and AstralPower() > 26 Spell(starsurge_moonkin)
	#stellar_flare,cycle_targets=1,max_cycle_targets=4,if=active_enemies<4&remains<7.2&astral_power>=15
	if DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7.2 and AstralPower() >= 15 Spell(stellar_flare)
	#moonfire,if=((talent.natures_balance.enabled&remains<3)|(remains<6.6&!talent.natures_balance.enabled))&(buff.the_emerald_dreamcatcher.remains>gcd.max|!buff.the_emerald_dreamcatcher.up)
	if { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6.6 and not Talent(natures_balance_talent) } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } Spell(moonfire)
	#sunfire,if=((talent.natures_balance.enabled&remains<3)|(remains<5.4&!talent.natures_balance.enabled))&(buff.the_emerald_dreamcatcher.remains>gcd.max|!buff.the_emerald_dreamcatcher.up)
	if { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5.4 and not Talent(natures_balance_talent) } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } Spell(sunfire)
	#starfall,if=buff.oneths_overconfidence.up&buff.the_emerald_dreamcatcher.remains>execute_time&remains<2
	if BuffPresent(oneths_overconfidence_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(starfall) and BuffRemaining(starfall_buff) < 2 Spell(starfall)
	#half_moon,if=astral_power<=80&buff.the_emerald_dreamcatcher.remains>execute_time&astral_power>=6
	if AstralPower() <= 80 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(half_moon) and AstralPower() >= 6 and SpellKnown(half_moon) Spell(half_moon)
	#full_moon,if=astral_power<=60&buff.the_emerald_dreamcatcher.remains>execute_time
	if AstralPower() <= 60 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(full_moon) and SpellKnown(full_moon) Spell(full_moon)
	#solar_wrath,if=buff.solar_empowerment.stack>1&buff.the_emerald_dreamcatcher.remains>2*execute_time&astral_power>=6&(dot.moonfire.remains>5|(dot.sunfire.remains<5.4&dot.moonfire.remains>6.6))&(!(buff.celestial_alignment.up|buff.incarnation.up)&astral_power<=90|(buff.celestial_alignment.up|buff.incarnation.up)&astral_power<=85)
	if BuffStacks(solar_empowerment_buff) > 1 and BuffRemaining(the_emerald_dreamcatcher_buff) > 2 * ExecuteTime(solar_wrath) and AstralPower() >= 6 and { target.DebuffRemaining(moonfire_debuff) > 5 or target.DebuffRemaining(sunfire_debuff) < 5.4 and target.DebuffRemaining(moonfire_debuff) > 6.6 } and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 90 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 85 } Spell(solar_wrath)
	#lunar_strike,if=buff.lunar_empowerment.up&buff.the_emerald_dreamcatcher.remains>execute_time&astral_power>=11&(!(buff.celestial_alignment.up|buff.incarnation.up)&astral_power<=85|(buff.celestial_alignment.up|buff.incarnation.up)&astral_power<=77.5)
	if BuffPresent(lunar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(lunar_strike_balance) and AstralPower() >= 11 and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 85 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 77.5 } Spell(lunar_strike_balance)
	#solar_wrath,if=buff.solar_empowerment.up&buff.the_emerald_dreamcatcher.remains>execute_time&astral_power>=16&(!(buff.celestial_alignment.up|buff.incarnation.up)&astral_power<=90|(buff.celestial_alignment.up|buff.incarnation.up)&astral_power<=85)
	if BuffPresent(solar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(solar_wrath) and AstralPower() >= 16 and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 90 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 85 } Spell(solar_wrath)
	#starsurge,if=(buff.the_emerald_dreamcatcher.up&buff.the_emerald_dreamcatcher.remains<gcd.max)|astral_power>90|((buff.celestial_alignment.up|buff.incarnation.up)&astral_power>=85)|(buff.the_emerald_dreamcatcher.up&astral_power>=77.5&(buff.celestial_alignment.up|buff.incarnation.up))
	if BuffPresent(the_emerald_dreamcatcher_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) < GCD() or AstralPower() > 90 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() >= 85 or BuffPresent(the_emerald_dreamcatcher_buff) and AstralPower() >= 77.5 and { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } Spell(starsurge_moonkin)
	#starfall,if=buff.oneths_overconfidence.up&remains<2
	if BuffPresent(oneths_overconfidence_buff) and BuffRemaining(starfall_buff) < 2 Spell(starfall)
	#new_moon,if=astral_power<=90
	if AstralPower() <= 90 and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
	#half_moon,if=astral_power<=80
	if AstralPower() <= 80 and SpellKnown(half_moon) Spell(half_moon)
	#full_moon,if=astral_power<=60&((cooldown.incarnation.remains>65&cooldown.full_moon.charges>0)|(cooldown.incarnation.remains>50&cooldown.full_moon.charges>1)|(cooldown.incarnation.remains>25&cooldown.full_moon.charges>2))
	if AstralPower() <= 60 and { SpellCooldown(incarnation_chosen_of_elune) > 65 and SpellCharges(full_moon) > 0 or SpellCooldown(incarnation_chosen_of_elune) > 50 and SpellCharges(full_moon) > 1 or SpellCooldown(incarnation_chosen_of_elune) > 25 and SpellCharges(full_moon) > 2 } and SpellKnown(full_moon) Spell(full_moon)
	#solar_wrath,if=buff.solar_empowerment.up
	if BuffPresent(solar_empowerment_buff) Spell(solar_wrath)
	#lunar_strike,if=buff.lunar_empowerment.up
	if BuffPresent(lunar_empowerment_buff) Spell(lunar_strike_balance)
	#solar_wrath
	Spell(solar_wrath)
}

AddFunction BalanceEdMainPostConditions
{
}

AddFunction BalanceEdShortCdActions
{
	#astral_communion,if=astral_power.deficit>=75&buff.the_emerald_dreamcatcher.up
	if AstralPowerDeficit() >= 75 and BuffPresent(the_emerald_dreamcatcher_buff) Spell(astral_communion)
}

AddFunction BalanceEdShortCdPostConditions
{
	{ BuffPresent(celestial_alignment_buff) and BuffRemaining(celestial_alignment_buff) < 10 or BuffPresent(incarnation_chosen_of_elune_buff) and BuffRemaining(incarnation_chosen_of_elune_buff) < 3 * ExecuteTime(starsurge_moonkin) and AstralPower() > 78 or BuffPresent(incarnation_chosen_of_elune_buff) and BuffRemaining(incarnation_chosen_of_elune_buff) < 2 * ExecuteTime(starsurge_moonkin) and AstralPower() > 52 or BuffPresent(incarnation_chosen_of_elune_buff) and BuffRemaining(incarnation_chosen_of_elune_buff) < ExecuteTime(starsurge_moonkin) and AstralPower() > 26 } and Spell(starsurge_moonkin) or DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7.2 and AstralPower() >= 15 and Spell(stellar_flare) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6.6 and not Talent(natures_balance_talent) } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(moonfire) or { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5.4 and not Talent(natures_balance_talent) } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(sunfire) or BuffPresent(oneths_overconfidence_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(starfall) and BuffRemaining(starfall_buff) < 2 and Spell(starfall) or AstralPower() <= 80 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(half_moon) and AstralPower() >= 6 and SpellKnown(half_moon) and Spell(half_moon) or AstralPower() <= 60 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(full_moon) and SpellKnown(full_moon) and Spell(full_moon) or BuffStacks(solar_empowerment_buff) > 1 and BuffRemaining(the_emerald_dreamcatcher_buff) > 2 * ExecuteTime(solar_wrath) and AstralPower() >= 6 and { target.DebuffRemaining(moonfire_debuff) > 5 or target.DebuffRemaining(sunfire_debuff) < 5.4 and target.DebuffRemaining(moonfire_debuff) > 6.6 } and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 90 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 85 } and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(lunar_strike_balance) and AstralPower() >= 11 and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 85 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 77.5 } and Spell(lunar_strike_balance) or BuffPresent(solar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(solar_wrath) and AstralPower() >= 16 and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 90 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 85 } and Spell(solar_wrath) or { BuffPresent(the_emerald_dreamcatcher_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) < GCD() or AstralPower() > 90 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() >= 85 or BuffPresent(the_emerald_dreamcatcher_buff) and AstralPower() >= 77.5 and { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } } and Spell(starsurge_moonkin) or BuffPresent(oneths_overconfidence_buff) and BuffRemaining(starfall_buff) < 2 and Spell(starfall) or AstralPower() <= 90 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPower() <= 80 and SpellKnown(half_moon) and Spell(half_moon) or AstralPower() <= 60 and { SpellCooldown(incarnation_chosen_of_elune) > 65 and SpellCharges(full_moon) > 0 or SpellCooldown(incarnation_chosen_of_elune) > 50 and SpellCharges(full_moon) > 1 or SpellCooldown(incarnation_chosen_of_elune) > 25 and SpellCharges(full_moon) > 2 } and SpellKnown(full_moon) and Spell(full_moon) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

AddFunction BalanceEdCdActions
{
	unless AstralPowerDeficit() >= 75 and BuffPresent(the_emerald_dreamcatcher_buff) and Spell(astral_communion)
	{
		#incarnation,if=astral_power>=85&!buff.the_emerald_dreamcatcher.up|buff.bloodlust.up
		if AstralPower() >= 85 and not BuffPresent(the_emerald_dreamcatcher_buff) or BuffPresent(burst_haste_buff any=1) Spell(incarnation_chosen_of_elune)
		#celestial_alignment,if=astral_power>=85&!buff.the_emerald_dreamcatcher.up
		if AstralPower() >= 85 and not BuffPresent(the_emerald_dreamcatcher_buff) Spell(celestial_alignment)
	}
}

AddFunction BalanceEdCdPostConditions
{
	AstralPowerDeficit() >= 75 and BuffPresent(the_emerald_dreamcatcher_buff) and Spell(astral_communion) or { BuffPresent(celestial_alignment_buff) and BuffRemaining(celestial_alignment_buff) < 10 or BuffPresent(incarnation_chosen_of_elune_buff) and BuffRemaining(incarnation_chosen_of_elune_buff) < 3 * ExecuteTime(starsurge_moonkin) and AstralPower() > 78 or BuffPresent(incarnation_chosen_of_elune_buff) and BuffRemaining(incarnation_chosen_of_elune_buff) < 2 * ExecuteTime(starsurge_moonkin) and AstralPower() > 52 or BuffPresent(incarnation_chosen_of_elune_buff) and BuffRemaining(incarnation_chosen_of_elune_buff) < ExecuteTime(starsurge_moonkin) and AstralPower() > 26 } and Spell(starsurge_moonkin) or DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7.2 and AstralPower() >= 15 and Spell(stellar_flare) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6.6 and not Talent(natures_balance_talent) } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(moonfire) or { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5.4 and not Talent(natures_balance_talent) } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(sunfire) or BuffPresent(oneths_overconfidence_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(starfall) and BuffRemaining(starfall_buff) < 2 and Spell(starfall) or AstralPower() <= 80 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(half_moon) and AstralPower() >= 6 and SpellKnown(half_moon) and Spell(half_moon) or AstralPower() <= 60 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(full_moon) and SpellKnown(full_moon) and Spell(full_moon) or BuffStacks(solar_empowerment_buff) > 1 and BuffRemaining(the_emerald_dreamcatcher_buff) > 2 * ExecuteTime(solar_wrath) and AstralPower() >= 6 and { target.DebuffRemaining(moonfire_debuff) > 5 or target.DebuffRemaining(sunfire_debuff) < 5.4 and target.DebuffRemaining(moonfire_debuff) > 6.6 } and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 90 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 85 } and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(lunar_strike_balance) and AstralPower() >= 11 and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 85 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 77.5 } and Spell(lunar_strike_balance) or BuffPresent(solar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(solar_wrath) and AstralPower() >= 16 and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 90 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() <= 85 } and Spell(solar_wrath) or { BuffPresent(the_emerald_dreamcatcher_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) < GCD() or AstralPower() > 90 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() >= 85 or BuffPresent(the_emerald_dreamcatcher_buff) and AstralPower() >= 77.5 and { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } } and Spell(starsurge_moonkin) or BuffPresent(oneths_overconfidence_buff) and BuffRemaining(starfall_buff) < 2 and Spell(starfall) or AstralPower() <= 90 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPower() <= 80 and SpellKnown(half_moon) and Spell(half_moon) or AstralPower() <= 60 and { SpellCooldown(incarnation_chosen_of_elune) > 65 and SpellCharges(full_moon) > 0 or SpellCooldown(incarnation_chosen_of_elune) > 50 and SpellCharges(full_moon) > 1 or SpellCooldown(incarnation_chosen_of_elune) > 25 and SpellCharges(full_moon) > 2 } and SpellKnown(full_moon) and Spell(full_moon) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

### actions.fury_of_elune

AddFunction BalanceFuryOfEluneMainActions
{
	#new_moon,if=((charges=2&recharge_time<5)|charges=3)&&(buff.fury_of_elune_up.up|(cooldown.fury_of_elune.remains>gcd*3&astral_power<=90))
	if { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 90 } and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
	#half_moon,if=((charges=2&recharge_time<5)|charges=3)&&(buff.fury_of_elune_up.up|(cooldown.fury_of_elune.remains>gcd*3&astral_power<=80))
	if { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 80 } and SpellKnown(half_moon) Spell(half_moon)
	#full_moon,if=((charges=2&recharge_time<5)|charges=3)&&(buff.fury_of_elune_up.up|(cooldown.fury_of_elune.remains>gcd*3&astral_power<=60))
	if { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 60 } and SpellKnown(full_moon) Spell(full_moon)
	#lunar_strike,if=buff.warrior_of_elune.up&(astral_power<=90|(astral_power<=85&buff.incarnation.up))
	if BuffPresent(warrior_of_elune_buff) and { AstralPower() <= 90 or AstralPower() <= 85 and BuffPresent(incarnation_chosen_of_elune_buff) } Spell(lunar_strike_balance)
	#new_moon,if=astral_power<=90&buff.fury_of_elune_up.up
	if AstralPower() <= 90 and BuffPresent(fury_of_elune_up_buff) and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
	#half_moon,if=astral_power<=80&buff.fury_of_elune_up.up&astral_power>cast_time*12
	if AstralPower() <= 80 and BuffPresent(fury_of_elune_up_buff) and AstralPower() > CastTime(half_moon) * 12 and SpellKnown(half_moon) Spell(half_moon)
	#full_moon,if=astral_power<=60&buff.fury_of_elune_up.up&astral_power>cast_time*12
	if AstralPower() <= 60 and BuffPresent(fury_of_elune_up_buff) and AstralPower() > CastTime(full_moon) * 12 and SpellKnown(full_moon) Spell(full_moon)
	#moonfire,if=buff.fury_of_elune_up.down&remains<=6.6
	if BuffExpires(fury_of_elune_up_buff) and target.DebuffRemaining(moonfire_debuff) <= 6.6 Spell(moonfire)
	#sunfire,if=buff.fury_of_elune_up.down&remains<5.4
	if BuffExpires(fury_of_elune_up_buff) and target.DebuffRemaining(sunfire_debuff) < 5.4 Spell(sunfire)
	#stellar_flare,if=remains<7.2&active_enemies=1
	if target.DebuffRemaining(stellar_flare_debuff) < 7.2 and Enemies() == 1 Spell(stellar_flare)
	#starfall,if=(active_enemies>=2&talent.stellar_flare.enabled|active_enemies>=3)&buff.fury_of_elune_up.down&cooldown.fury_of_elune.remains>10
	if { Enemies() >= 2 and Talent(stellar_flare_talent) or Enemies() >= 3 } and BuffExpires(fury_of_elune_up_buff) and SpellCooldown(fury_of_elune) > 10 Spell(starfall)
	#starsurge,if=active_enemies<=2&buff.fury_of_elune_up.down&cooldown.fury_of_elune.remains>7
	if Enemies() <= 2 and BuffExpires(fury_of_elune_up_buff) and SpellCooldown(fury_of_elune) > 7 Spell(starsurge_moonkin)
	#starsurge,if=buff.fury_of_elune_up.down&((astral_power>=92&cooldown.fury_of_elune.remains>gcd*3)|(cooldown.warrior_of_elune.remains<=5&cooldown.fury_of_elune.remains>=35&buff.lunar_empowerment.stack<2))
	if BuffExpires(fury_of_elune_up_buff) and { AstralPower() >= 92 and SpellCooldown(fury_of_elune) > GCD() * 3 or SpellCooldown(warrior_of_elune) <= 5 and SpellCooldown(fury_of_elune) >= 35 and BuffStacks(lunar_empowerment_buff) < 2 } Spell(starsurge_moonkin)
	#solar_wrath,if=buff.solar_empowerment.up
	if BuffPresent(solar_empowerment_buff) Spell(solar_wrath)
	#lunar_strike,if=buff.lunar_empowerment.stack=3|(buff.lunar_empowerment.remains<5&buff.lunar_empowerment.up)|active_enemies>=2
	if BuffStacks(lunar_empowerment_buff) == 3 or BuffRemaining(lunar_empowerment_buff) < 5 and BuffPresent(lunar_empowerment_buff) or Enemies() >= 2 Spell(lunar_strike_balance)
	#solar_wrath
	Spell(solar_wrath)
}

AddFunction BalanceFuryOfEluneMainPostConditions
{
}

AddFunction BalanceFuryOfEluneShortCdActions
{
	#fury_of_elune,if=astral_power>=95
	if AstralPower() >= 95 Spell(fury_of_elune)

	unless { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 90 } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 80 } and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 60 } and SpellKnown(full_moon) and Spell(full_moon)
	{
		#astral_communion,if=buff.fury_of_elune_up.up&astral_power<=25
		if BuffPresent(fury_of_elune_up_buff) and AstralPower() <= 25 Spell(astral_communion)
		#warrior_of_elune,if=buff.fury_of_elune_up.up|(cooldown.fury_of_elune.remains>=35&buff.lunar_empowerment.up)
		if BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) >= 35 and BuffPresent(lunar_empowerment_buff) Spell(warrior_of_elune)
	}
}

AddFunction BalanceFuryOfEluneShortCdPostConditions
{
	{ Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 90 } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 80 } and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 60 } and SpellKnown(full_moon) and Spell(full_moon) or BuffPresent(warrior_of_elune_buff) and { AstralPower() <= 90 or AstralPower() <= 85 and BuffPresent(incarnation_chosen_of_elune_buff) } and Spell(lunar_strike_balance) or AstralPower() <= 90 and BuffPresent(fury_of_elune_up_buff) and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPower() <= 80 and BuffPresent(fury_of_elune_up_buff) and AstralPower() > CastTime(half_moon) * 12 and SpellKnown(half_moon) and Spell(half_moon) or AstralPower() <= 60 and BuffPresent(fury_of_elune_up_buff) and AstralPower() > CastTime(full_moon) * 12 and SpellKnown(full_moon) and Spell(full_moon) or BuffExpires(fury_of_elune_up_buff) and target.DebuffRemaining(moonfire_debuff) <= 6.6 and Spell(moonfire) or BuffExpires(fury_of_elune_up_buff) and target.DebuffRemaining(sunfire_debuff) < 5.4 and Spell(sunfire) or target.DebuffRemaining(stellar_flare_debuff) < 7.2 and Enemies() == 1 and Spell(stellar_flare) or { Enemies() >= 2 and Talent(stellar_flare_talent) or Enemies() >= 3 } and BuffExpires(fury_of_elune_up_buff) and SpellCooldown(fury_of_elune) > 10 and Spell(starfall) or Enemies() <= 2 and BuffExpires(fury_of_elune_up_buff) and SpellCooldown(fury_of_elune) > 7 and Spell(starsurge_moonkin) or BuffExpires(fury_of_elune_up_buff) and { AstralPower() >= 92 and SpellCooldown(fury_of_elune) > GCD() * 3 or SpellCooldown(warrior_of_elune) <= 5 and SpellCooldown(fury_of_elune) >= 35 and BuffStacks(lunar_empowerment_buff) < 2 } and Spell(starsurge_moonkin) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or { BuffStacks(lunar_empowerment_buff) == 3 or BuffRemaining(lunar_empowerment_buff) < 5 and BuffPresent(lunar_empowerment_buff) or Enemies() >= 2 } and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

AddFunction BalanceFuryOfEluneCdActions
{
	#incarnation,if=astral_power>=95&cooldown.fury_of_elune.remains<=gcd
	if AstralPower() >= 95 and SpellCooldown(fury_of_elune) <= GCD() Spell(incarnation_chosen_of_elune)
}

AddFunction BalanceFuryOfEluneCdPostConditions
{
	AstralPower() >= 95 and Spell(fury_of_elune) or { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 90 } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 80 } and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 60 } and SpellKnown(full_moon) and Spell(full_moon) or BuffPresent(fury_of_elune_up_buff) and AstralPower() <= 25 and Spell(astral_communion) or BuffPresent(warrior_of_elune_buff) and { AstralPower() <= 90 or AstralPower() <= 85 and BuffPresent(incarnation_chosen_of_elune_buff) } and Spell(lunar_strike_balance) or AstralPower() <= 90 and BuffPresent(fury_of_elune_up_buff) and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPower() <= 80 and BuffPresent(fury_of_elune_up_buff) and AstralPower() > CastTime(half_moon) * 12 and SpellKnown(half_moon) and Spell(half_moon) or AstralPower() <= 60 and BuffPresent(fury_of_elune_up_buff) and AstralPower() > CastTime(full_moon) * 12 and SpellKnown(full_moon) and Spell(full_moon) or BuffExpires(fury_of_elune_up_buff) and target.DebuffRemaining(moonfire_debuff) <= 6.6 and Spell(moonfire) or BuffExpires(fury_of_elune_up_buff) and target.DebuffRemaining(sunfire_debuff) < 5.4 and Spell(sunfire) or target.DebuffRemaining(stellar_flare_debuff) < 7.2 and Enemies() == 1 and Spell(stellar_flare) or { Enemies() >= 2 and Talent(stellar_flare_talent) or Enemies() >= 3 } and BuffExpires(fury_of_elune_up_buff) and SpellCooldown(fury_of_elune) > 10 and Spell(starfall) or Enemies() <= 2 and BuffExpires(fury_of_elune_up_buff) and SpellCooldown(fury_of_elune) > 7 and Spell(starsurge_moonkin) or BuffExpires(fury_of_elune_up_buff) and { AstralPower() >= 92 and SpellCooldown(fury_of_elune) > GCD() * 3 or SpellCooldown(warrior_of_elune) <= 5 and SpellCooldown(fury_of_elune) >= 35 and BuffStacks(lunar_empowerment_buff) < 2 } and Spell(starsurge_moonkin) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or { BuffStacks(lunar_empowerment_buff) == 3 or BuffRemaining(lunar_empowerment_buff) < 5 and BuffPresent(lunar_empowerment_buff) or Enemies() >= 2 } and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

### actions.precombat

AddFunction BalancePrecombatMainActions
{
	#flask,type=flask_of_the_whispered_pact
	#food,type=azshari_salad
	#augmentation,type=defiled
	#moonkin_form
	Spell(moonkin_form)
	#blessing_of_elune
	Spell(blessing_of_elune)
	#new_moon
	if not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
}

AddFunction BalancePrecombatMainPostConditions
{
}

AddFunction BalancePrecombatShortCdActions
{
}

AddFunction BalancePrecombatShortCdPostConditions
{
	Spell(moonkin_form) or Spell(blessing_of_elune) or not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon)
}

AddFunction BalancePrecombatCdActions
{
	unless Spell(moonkin_form) or Spell(blessing_of_elune)
	{
		#snapshot_stats
		#potion,name=deadly_grace
		if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(deadly_grace_potion usable=1)
	}
}

AddFunction BalancePrecombatCdPostConditions
{
	Spell(moonkin_form) or Spell(blessing_of_elune) or not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon)
}

### actions.single_target

AddFunction BalanceSingleTargetMainActions
{
	#new_moon,if=astral_power<=90
	if AstralPower() <= 90 and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
	#half_moon,if=astral_power<=80
	if AstralPower() <= 80 and SpellKnown(half_moon) Spell(half_moon)
	#full_moon,if=astral_power<=60
	if AstralPower() <= 60 and SpellKnown(full_moon) Spell(full_moon)
	#starfall,if=((active_enemies>=2&talent.stellar_drift.enabled)|active_enemies>=3)
	if Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 Spell(starfall)
	#starsurge,if=active_enemies<=2
	if Enemies() <= 2 Spell(starsurge_moonkin)
	#lunar_strike,if=buff.warrior_of_elune.up
	if BuffPresent(warrior_of_elune_buff) Spell(lunar_strike_balance)
	#solar_wrath,if=buff.solar_empowerment.up
	if BuffPresent(solar_empowerment_buff) Spell(solar_wrath)
	#lunar_strike,if=buff.lunar_empowerment.up
	if BuffPresent(lunar_empowerment_buff) Spell(lunar_strike_balance)
	#solar_wrath,if=talent.natures_balance.enabled&dot.sunfire_dmg.remains<5&cast_time<dot.sunfire_dmg.remains
	if Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_dmg_debuff) < 5 and CastTime(solar_wrath) < target.DebuffRemaining(sunfire_dmg_debuff) Spell(solar_wrath)
	#lunar_strike,if=(talent.natures_balance.enabled&dot.moonfire_dmg.remains<5&cast_time<dot.moonfire_dmg.remains)|active_enemies>=2
	if Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_dmg_debuff) < 5 and CastTime(lunar_strike_balance) < target.DebuffRemaining(moonfire_dmg_debuff) or Enemies() >= 2 Spell(lunar_strike_balance)
	#solar_wrath
	Spell(solar_wrath)
}

AddFunction BalanceSingleTargetMainPostConditions
{
}

AddFunction BalanceSingleTargetShortCdActions
{
	unless AstralPower() <= 90 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPower() <= 80 and SpellKnown(half_moon) and Spell(half_moon) or AstralPower() <= 60 and SpellKnown(full_moon) and Spell(full_moon) or { Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 } and Spell(starfall) or Enemies() <= 2 and Spell(starsurge_moonkin)
	{
		#warrior_of_elune
		Spell(warrior_of_elune)
	}
}

AddFunction BalanceSingleTargetShortCdPostConditions
{
	AstralPower() <= 90 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPower() <= 80 and SpellKnown(half_moon) and Spell(half_moon) or AstralPower() <= 60 and SpellKnown(full_moon) and Spell(full_moon) or { Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 } and Spell(starfall) or Enemies() <= 2 and Spell(starsurge_moonkin) or BuffPresent(warrior_of_elune_buff) and Spell(lunar_strike_balance) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike_balance) or Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_dmg_debuff) < 5 and CastTime(solar_wrath) < target.DebuffRemaining(sunfire_dmg_debuff) and Spell(solar_wrath) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_dmg_debuff) < 5 and CastTime(lunar_strike_balance) < target.DebuffRemaining(moonfire_dmg_debuff) or Enemies() >= 2 } and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

AddFunction BalanceSingleTargetCdActions
{
}

AddFunction BalanceSingleTargetCdPostConditions
{
	AstralPower() <= 90 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPower() <= 80 and SpellKnown(half_moon) and Spell(half_moon) or AstralPower() <= 60 and SpellKnown(full_moon) and Spell(full_moon) or { Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 } and Spell(starfall) or Enemies() <= 2 and Spell(starsurge_moonkin) or BuffPresent(warrior_of_elune_buff) and Spell(lunar_strike_balance) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike_balance) or Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_dmg_debuff) < 5 and CastTime(solar_wrath) < target.DebuffRemaining(sunfire_dmg_debuff) and Spell(solar_wrath) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_dmg_debuff) < 5 and CastTime(lunar_strike_balance) < target.DebuffRemaining(moonfire_dmg_debuff) or Enemies() >= 2 } and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

### Balance icons.

AddCheckBox(opt_druid_balance_aoe L(AOE) default specialization=balance)

AddIcon checkbox=!opt_druid_balance_aoe enemies=1 help=shortcd specialization=balance
{
	if not InCombat() BalancePrecombatShortCdActions()
	unless not InCombat() and BalancePrecombatShortCdPostConditions()
	{
		BalanceDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_druid_balance_aoe help=shortcd specialization=balance
{
	if not InCombat() BalancePrecombatShortCdActions()
	unless not InCombat() and BalancePrecombatShortCdPostConditions()
	{
		BalanceDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=balance
{
	if not InCombat() BalancePrecombatMainActions()
	unless not InCombat() and BalancePrecombatMainPostConditions()
	{
		BalanceDefaultMainActions()
	}
}

AddIcon checkbox=opt_druid_balance_aoe help=aoe specialization=balance
{
	if not InCombat() BalancePrecombatMainActions()
	unless not InCombat() and BalancePrecombatMainPostConditions()
	{
		BalanceDefaultMainActions()
	}
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
# astral_communion
# berserking
# blessing_of_anshe_buff
# blessing_of_elune
# blessing_of_elune_buff
# blessing_of_the_ancients_talent
# blood_fury_apsp
# celestial_alignment
# celestial_alignment_buff
# deadly_grace_potion
# full_moon
# fury_of_elune
# fury_of_elune_talent
# fury_of_elune_up_buff
# half_moon
# incarnation_chosen_of_elune
# incarnation_chosen_of_elune_buff
# lunar_empowerment_buff
# lunar_strike_balance
# mighty_bash
# moonfire
# moonfire_debuff
# moonfire_dmg_debuff
# moonkin_form
# natures_balance_talent
# new_moon
# oneths_overconfidence_buff
# solar_beam
# solar_empowerment_buff
# solar_wrath
# starfall
# starfall_buff
# starsurge_moonkin
# stellar_drift_talent
# stellar_flare
# stellar_flare_debuff
# stellar_flare_talent
# sunfire
# sunfire_debuff
# sunfire_dmg_debuff
# the_emerald_dreamcatcher
# the_emerald_dreamcatcher_buff
# typhoon
# war_stomp
# warrior_of_elune
# warrior_of_elune_buff
]]
	OvaleScripts:RegisterScript("DRUID", "balance", name, desc, code, "script")
end

do
	local name = "simulationcraft_druid_feral_t19p"
	local desc = "[7.0] SimulationCraft: Druid_Feral_T19P"
	local code = [[
# Based on SimulationCraft profile "Druid_Feral_T19P".
#	class=druid
#	spec=feral
#	talents=3323322

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=feral)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=feral)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=feral)

AddFunction FeralInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
	{
		if target.InRange(skull_bash) and target.IsInterruptible() Spell(skull_bash)
		if target.InRange(mighty_bash) and not target.Classification(worldboss) Spell(mighty_bash)
		if target.InRange(maim) and not target.Classification(worldboss) Spell(maim)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
		if target.Distance(less 15) and not target.Classification(worldboss) Spell(typhoon)
	}
}

AddFunction FeralUseItemActions
{
	Item(Trinket0Slot text=13 usable=1)
	Item(Trinket1Slot text=14 usable=1)
}

AddFunction FeralGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and { Stance(druid_bear_form) and not target.InRange(mangle) or Stance(druid_cat_form) and not target.InRange(shred) }
	{
		if target.InRange(wild_charge) Spell(wild_charge)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

### actions.default

AddFunction FeralDefaultMainActions
{
	#cat_form
	Spell(cat_form)
	#rake,if=buff.prowl.up|buff.shadowmeld.up
	if BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) Spell(rake)
	#ferocious_bite,cycle_targets=1,if=dot.rip.ticking&dot.rip.remains<3&target.time_to_die>3&(target.health.pct<25|talent.sabertooth.enabled)
	if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 3 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } Spell(ferocious_bite)
	#regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&(combo_points>=5|buff.predatory_swiftness.remains<1.5|(talent.bloodtalons.enabled&combo_points=2&cooldown.ashamanes_frenzy.remains<gcd)|(talent.elunes_guidance.enabled&((cooldown.elunes_guidance.remains<gcd&combo_points=0)|(buff.elunes_guidance.up&combo_points>=4))))
	if Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and { ComboPoints() >= 5 or BuffRemaining(predatory_swiftness_buff) < 1.5 or Talent(bloodtalons_talent) and ComboPoints() == 2 and SpellCooldown(ashamanes_frenzy) < GCD() or Talent(elunes_guidance_talent) and { SpellCooldown(elunes_guidance) < GCD() and ComboPoints() == 0 or BuffPresent(elunes_guidance_buff) and ComboPoints() >= 4 } } Spell(regrowth)
	#call_action_list,name=sbt_opener,if=talent.sabertooth.enabled&time<20
	if Talent(sabertooth_talent) and TimeInCombat() < 20 FeralSbtOpenerMainActions()

	unless Talent(sabertooth_talent) and TimeInCombat() < 20 and FeralSbtOpenerMainPostConditions()
	{
		#regrowth,if=equipped.ailuro_pouncers&talent.bloodtalons.enabled&buff.predatory_swiftness.stack>1&buff.bloodtalons.down
		if HasEquippedItem(ailuro_pouncers) and Talent(bloodtalons_talent) and BuffStacks(predatory_swiftness_buff) > 1 and BuffExpires(bloodtalons_buff) Spell(regrowth)
		#call_action_list,name=finisher
		FeralFinisherMainActions()

		unless FeralFinisherMainPostConditions()
		{
			#call_action_list,name=generator
			FeralGeneratorMainActions()
		}
	}
}

AddFunction FeralDefaultMainPostConditions
{
	Talent(sabertooth_talent) and TimeInCombat() < 20 and FeralSbtOpenerMainPostConditions() or FeralFinisherMainPostConditions() or FeralGeneratorMainPostConditions()
}

AddFunction FeralDefaultShortCdActions
{
	unless Spell(cat_form)
	{
		#wild_charge
		FeralGetInMeleeRange()
		#displacer_beast,if=movement.distance>10
		if target.Distance() > 10 Spell(displacer_beast)

		unless { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
		{
			#auto_attack
			FeralGetInMeleeRange()
			#tigers_fury,if=(!buff.clearcasting.react&energy.deficit>=60)|energy.deficit>=80|(t18_class_trinket&buff.berserk.up&buff.tigers_fury.down)
			if not BuffPresent(clearcasting_buff) and EnergyDeficit() >= 60 or EnergyDeficit() >= 80 or HasTrinket(t18_class_trinket) and BuffPresent(berserk_cat_buff) and BuffExpires(tigers_fury_buff) Spell(tigers_fury)

			unless target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 3 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } and Spell(ferocious_bite) or Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and { ComboPoints() >= 5 or BuffRemaining(predatory_swiftness_buff) < 1.5 or Talent(bloodtalons_talent) and ComboPoints() == 2 and SpellCooldown(ashamanes_frenzy) < GCD() or Talent(elunes_guidance_talent) and { SpellCooldown(elunes_guidance) < GCD() and ComboPoints() == 0 or BuffPresent(elunes_guidance_buff) and ComboPoints() >= 4 } } and Spell(regrowth)
			{
				#call_action_list,name=sbt_opener,if=talent.sabertooth.enabled&time<20
				if Talent(sabertooth_talent) and TimeInCombat() < 20 FeralSbtOpenerShortCdActions()

				unless Talent(sabertooth_talent) and TimeInCombat() < 20 and FeralSbtOpenerShortCdPostConditions() or HasEquippedItem(ailuro_pouncers) and Talent(bloodtalons_talent) and BuffStacks(predatory_swiftness_buff) > 1 and BuffExpires(bloodtalons_buff) and Spell(regrowth)
				{
					#call_action_list,name=finisher
					FeralFinisherShortCdActions()

					unless FeralFinisherShortCdPostConditions()
					{
						#call_action_list,name=generator
						FeralGeneratorShortCdActions()
					}
				}
			}
		}
	}
}

AddFunction FeralDefaultShortCdPostConditions
{
	Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake) or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 3 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } and Spell(ferocious_bite) or Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and { ComboPoints() >= 5 or BuffRemaining(predatory_swiftness_buff) < 1.5 or Talent(bloodtalons_talent) and ComboPoints() == 2 and SpellCooldown(ashamanes_frenzy) < GCD() or Talent(elunes_guidance_talent) and { SpellCooldown(elunes_guidance) < GCD() and ComboPoints() == 0 or BuffPresent(elunes_guidance_buff) and ComboPoints() >= 4 } } and Spell(regrowth) or Talent(sabertooth_talent) and TimeInCombat() < 20 and FeralSbtOpenerShortCdPostConditions() or HasEquippedItem(ailuro_pouncers) and Talent(bloodtalons_talent) and BuffStacks(predatory_swiftness_buff) > 1 and BuffExpires(bloodtalons_buff) and Spell(regrowth) or FeralFinisherShortCdPostConditions() or FeralGeneratorShortCdPostConditions()
}

AddFunction FeralDefaultCdActions
{
	#dash,if=!buff.cat_form.up
	if not BuffPresent(cat_form_buff) Spell(dash)

	unless Spell(cat_form) or target.Distance() > 10 and Spell(displacer_beast)
	{
		#dash,if=movement.distance&buff.displacer_beast.down&buff.wild_charge_movement.down
		if target.Distance() and BuffExpires(displacer_beast_buff) and True(wild_charge_movement_down) Spell(dash)

		unless { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
		{
			#skull_bash
			FeralInterruptActions()
			#berserk,if=buff.tigers_fury.up
			if BuffPresent(tigers_fury_buff) Spell(berserk_cat)
			#incarnation,if=cooldown.tigers_fury.remains<gcd
			if SpellCooldown(tigers_fury) < GCD() Spell(incarnation_king_of_the_jungle)
			#use_item,slot=trinket2,if=(buff.tigers_fury.up&(target.time_to_die>trinket.stat.any.cooldown|target.time_to_die<45))|buff.incarnation.remains>20
			if BuffPresent(tigers_fury_buff) and { target.TimeToDie() > BuffCooldownDuration(trinket_stat_any_buff) or target.TimeToDie() < 45 } or BuffRemaining(incarnation_king_of_the_jungle_buff) > 20 FeralUseItemActions()
			#potion,name=old_war,if=((buff.berserk.remains>10|buff.incarnation.remains>20)&(target.time_to_die<180|(trinket.proc.all.react&target.health.pct<25)))|target.time_to_die<=40
			if { { BuffRemaining(berserk_cat_buff) > 10 or BuffRemaining(incarnation_king_of_the_jungle_buff) > 20 } and { target.TimeToDie() < 180 or BuffPresent(trinket_proc_any_buff) and target.HealthPercent() < 25 } or target.TimeToDie() <= 40 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war_potion usable=1)
			#incarnation,if=energy.time_to_max>1&energy>=35
			if TimeToMaxEnergy() > 1 and Energy() >= 35 Spell(incarnation_king_of_the_jungle)

			unless target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 3 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } and Spell(ferocious_bite) or Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and { ComboPoints() >= 5 or BuffRemaining(predatory_swiftness_buff) < 1.5 or Talent(bloodtalons_talent) and ComboPoints() == 2 and SpellCooldown(ashamanes_frenzy) < GCD() or Talent(elunes_guidance_talent) and { SpellCooldown(elunes_guidance) < GCD() and ComboPoints() == 0 or BuffPresent(elunes_guidance_buff) and ComboPoints() >= 4 } } and Spell(regrowth)
			{
				#call_action_list,name=sbt_opener,if=talent.sabertooth.enabled&time<20
				if Talent(sabertooth_talent) and TimeInCombat() < 20 FeralSbtOpenerCdActions()

				unless Talent(sabertooth_talent) and TimeInCombat() < 20 and FeralSbtOpenerCdPostConditions() or HasEquippedItem(ailuro_pouncers) and Talent(bloodtalons_talent) and BuffStacks(predatory_swiftness_buff) > 1 and BuffExpires(bloodtalons_buff) and Spell(regrowth)
				{
					#call_action_list,name=finisher
					FeralFinisherCdActions()

					unless FeralFinisherCdPostConditions()
					{
						#call_action_list,name=generator
						FeralGeneratorCdActions()
					}
				}
			}
		}
	}
}

AddFunction FeralDefaultCdPostConditions
{
	Spell(cat_form) or target.Distance() > 10 and Spell(displacer_beast) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake) or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 3 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } and Spell(ferocious_bite) or Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and { ComboPoints() >= 5 or BuffRemaining(predatory_swiftness_buff) < 1.5 or Talent(bloodtalons_talent) and ComboPoints() == 2 and SpellCooldown(ashamanes_frenzy) < GCD() or Talent(elunes_guidance_talent) and { SpellCooldown(elunes_guidance) < GCD() and ComboPoints() == 0 or BuffPresent(elunes_guidance_buff) and ComboPoints() >= 4 } } and Spell(regrowth) or Talent(sabertooth_talent) and TimeInCombat() < 20 and FeralSbtOpenerCdPostConditions() or HasEquippedItem(ailuro_pouncers) and Talent(bloodtalons_talent) and BuffStacks(predatory_swiftness_buff) > 1 and BuffExpires(bloodtalons_buff) and Spell(regrowth) or FeralFinisherCdPostConditions() or FeralGeneratorCdPostConditions()
}

### actions.finisher

AddFunction FeralFinisherMainActions
{
	#pool_resource,for_next=1
	#savage_roar,if=!buff.savage_roar.up&(combo_points=5|(talent.brutal_slash.enabled&spell_targets.brutal_slash>desired_targets&action.brutal_slash.charges>0))
	if not BuffPresent(savage_roar_buff) and { ComboPoints() == 5 or Talent(brutal_slash_talent) and Enemies() > Enemies(tagged=1) and Charges(brutal_slash) > 0 } Spell(savage_roar)
	unless not BuffPresent(savage_roar_buff) and { ComboPoints() == 5 or Talent(brutal_slash_talent) and Enemies() > Enemies(tagged=1) and Charges(brutal_slash) > 0 } and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar)
	{
		#pool_resource,for_next=1
		#thrash_cat,cycle_targets=1,if=remains<=duration*0.3&spell_targets.thrash_cat>=5
		if target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() >= 5 Spell(thrash_cat)
		unless target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() >= 5 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
		{
			#pool_resource,for_next=1
			#swipe_cat,if=spell_targets.swipe_cat>=8
			if Enemies() >= 8 Spell(swipe_cat)
			unless Enemies() >= 8 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat)
			{
				#rip,cycle_targets=1,if=(!ticking|(remains<8&target.health.pct>25&!talent.sabertooth.enabled)|persistent_multiplier>dot.rip.pmultiplier)&target.time_to_die-remains>tick_time*4&combo_points=5&(energy.time_to_max<1|buff.berserk.up|buff.incarnation.up|buff.elunes_guidance.up|cooldown.tigers_fury.remains<3|set_bonus.tier18_4pc|(buff.clearcasting.react&energy>65)|talent.soul_of_the_forest.enabled|!dot.rip.ticking|(dot.rake.remains<1.5&spell_targets.swipe_cat<6))
				if { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) < 8 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) } and target.TimeToDie() - target.DebuffRemaining(rip_debuff) > target.TickTime(rip_debuff) * 4 and ComboPoints() == 5 and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 or ArmorSetBonus(T18 4) or BuffPresent(clearcasting_buff) and Energy() > 65 or Talent(soul_of_the_forest_talent) or not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rake_debuff) < 1.5 and Enemies() < 6 } Spell(rip)
				#savage_roar,if=((buff.savage_roar.remains<=10.5&talent.jagged_wounds.enabled)|(buff.savage_roar.remains<=7.2))&combo_points=5&(energy.time_to_max<1|buff.berserk.up|buff.incarnation.up|buff.elunes_guidance.up|cooldown.tigers_fury.remains<3|set_bonus.tier18_4pc|(buff.clearcasting.react&energy>65)|talent.soul_of_the_forest.enabled|!dot.rip.ticking|(dot.rake.remains<1.5&spell_targets.swipe_cat<6))
				if { BuffRemaining(savage_roar_buff) <= 10.5 and Talent(jagged_wounds_talent) or BuffRemaining(savage_roar_buff) <= 7.2 } and ComboPoints() == 5 and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 or ArmorSetBonus(T18 4) or BuffPresent(clearcasting_buff) and Energy() > 65 or Talent(soul_of_the_forest_talent) or not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rake_debuff) < 1.5 and Enemies() < 6 } Spell(savage_roar)
				#swipe_cat,if=combo_points=5&(spell_targets.swipe_cat>=6|(spell_targets.swipe_cat>=3&!talent.bloodtalons.enabled))&combo_points=5&(energy.time_to_max<1|buff.berserk.up|buff.incarnation.up|buff.elunes_guidance.up|cooldown.tigers_fury.remains<3|set_bonus.tier18_4pc|(talent.moment_of_clarity.enabled&buff.clearcasting.react))
				if ComboPoints() == 5 and { Enemies() >= 6 or Enemies() >= 3 and not Talent(bloodtalons_talent) } and ComboPoints() == 5 and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 or ArmorSetBonus(T18 4) or Talent(moment_of_clarity_talent) and BuffPresent(clearcasting_buff) } Spell(swipe_cat)
				#maim,,if=combo_points=5&buff.fiery_red_maimers.up&(energy.time_to_max<1|buff.berserk.up|buff.incarnation.up|buff.elunes_guidance.up|cooldown.tigers_fury.remains<3)
				if ComboPoints() == 5 and BuffPresent(fiery_red_maimers_buff) and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 } Spell(maim)
				#ferocious_bite,max_energy=1,cycle_targets=1,if=combo_points=5&(energy.time_to_max<1|buff.berserk.up|buff.incarnation.up|buff.elunes_guidance.up|cooldown.tigers_fury.remains<3)
				if Energy() >= EnergyCost(ferocious_bite max=1) and ComboPoints() == 5 and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 } Spell(ferocious_bite)
			}
		}
	}
}

AddFunction FeralFinisherMainPostConditions
{
}

AddFunction FeralFinisherShortCdActions
{
}

AddFunction FeralFinisherShortCdPostConditions
{
	not BuffPresent(savage_roar_buff) and { ComboPoints() == 5 or Talent(brutal_slash_talent) and Enemies() > Enemies(tagged=1) and Charges(brutal_slash) > 0 } and Spell(savage_roar) or not { not BuffPresent(savage_roar_buff) and { ComboPoints() == 5 or Talent(brutal_slash_talent) and Enemies() > Enemies(tagged=1) and Charges(brutal_slash) > 0 } and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() >= 5 and Spell(thrash_cat) or not { target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() >= 5 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { Enemies() >= 8 and Spell(swipe_cat) or not { Enemies() >= 8 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) < 8 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) } and target.TimeToDie() - target.DebuffRemaining(rip_debuff) > target.TickTime(rip_debuff) * 4 and ComboPoints() == 5 and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 or ArmorSetBonus(T18 4) or BuffPresent(clearcasting_buff) and Energy() > 65 or Talent(soul_of_the_forest_talent) or not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rake_debuff) < 1.5 and Enemies() < 6 } and Spell(rip) or { BuffRemaining(savage_roar_buff) <= 10.5 and Talent(jagged_wounds_talent) or BuffRemaining(savage_roar_buff) <= 7.2 } and ComboPoints() == 5 and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 or ArmorSetBonus(T18 4) or BuffPresent(clearcasting_buff) and Energy() > 65 or Talent(soul_of_the_forest_talent) or not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rake_debuff) < 1.5 and Enemies() < 6 } and Spell(savage_roar) or ComboPoints() == 5 and { Enemies() >= 6 or Enemies() >= 3 and not Talent(bloodtalons_talent) } and ComboPoints() == 5 and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 or ArmorSetBonus(T18 4) or Talent(moment_of_clarity_talent) and BuffPresent(clearcasting_buff) } and Spell(swipe_cat) or ComboPoints() == 5 and BuffPresent(fiery_red_maimers_buff) and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 } and Spell(maim) or Energy() >= EnergyCost(ferocious_bite max=1) and ComboPoints() == 5 and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 } and Spell(ferocious_bite) } } }
}

AddFunction FeralFinisherCdActions
{
}

AddFunction FeralFinisherCdPostConditions
{
	not BuffPresent(savage_roar_buff) and { ComboPoints() == 5 or Talent(brutal_slash_talent) and Enemies() > Enemies(tagged=1) and Charges(brutal_slash) > 0 } and Spell(savage_roar) or not { not BuffPresent(savage_roar_buff) and { ComboPoints() == 5 or Talent(brutal_slash_talent) and Enemies() > Enemies(tagged=1) and Charges(brutal_slash) > 0 } and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() >= 5 and Spell(thrash_cat) or not { target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() >= 5 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { Enemies() >= 8 and Spell(swipe_cat) or not { Enemies() >= 8 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) < 8 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) } and target.TimeToDie() - target.DebuffRemaining(rip_debuff) > target.TickTime(rip_debuff) * 4 and ComboPoints() == 5 and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 or ArmorSetBonus(T18 4) or BuffPresent(clearcasting_buff) and Energy() > 65 or Talent(soul_of_the_forest_talent) or not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rake_debuff) < 1.5 and Enemies() < 6 } and Spell(rip) or { BuffRemaining(savage_roar_buff) <= 10.5 and Talent(jagged_wounds_talent) or BuffRemaining(savage_roar_buff) <= 7.2 } and ComboPoints() == 5 and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 or ArmorSetBonus(T18 4) or BuffPresent(clearcasting_buff) and Energy() > 65 or Talent(soul_of_the_forest_talent) or not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rake_debuff) < 1.5 and Enemies() < 6 } and Spell(savage_roar) or ComboPoints() == 5 and { Enemies() >= 6 or Enemies() >= 3 and not Talent(bloodtalons_talent) } and ComboPoints() == 5 and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 or ArmorSetBonus(T18 4) or Talent(moment_of_clarity_talent) and BuffPresent(clearcasting_buff) } and Spell(swipe_cat) or ComboPoints() == 5 and BuffPresent(fiery_red_maimers_buff) and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 } and Spell(maim) or Energy() >= EnergyCost(ferocious_bite max=1) and ComboPoints() == 5 and { TimeToMaxEnergy() < 1 or BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) or BuffPresent(elunes_guidance_buff) or SpellCooldown(tigers_fury) < 3 } and Spell(ferocious_bite) } } }
}

### actions.generator

AddFunction FeralGeneratorMainActions
{
	#brutal_slash,if=spell_targets.brutal_slash>desired_targets&combo_points<5
	if Enemies() > Enemies(tagged=1) and ComboPoints() < 5 Spell(brutal_slash)
	#pool_resource,if=talent.elunes_guidance.enabled&combo_points=0&energy<action.ferocious_bite.cost+25-energy.regen*cooldown.elunes_guidance.remains
	unless Talent(elunes_guidance_talent) and ComboPoints() == 0 and Energy() < PowerCost(ferocious_bite) + 25 - EnergyRegenRate() * SpellCooldown(elunes_guidance)
	{
		#pool_resource,for_next=1
		#thrash_cat,if=talent.brutal_slash.enabled&spell_targets.thrash_cat>=9
		if Talent(brutal_slash_talent) and Enemies() >= 9 Spell(thrash_cat)
		unless Talent(brutal_slash_talent) and Enemies() >= 9 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
		{
			#pool_resource,for_next=1
			#swipe_cat,if=spell_targets.swipe_cat>=6
			if Enemies() >= 6 Spell(swipe_cat)
			unless Enemies() >= 6 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat)
			{
				#pool_resource,for_next=1
				#rake,cycle_targets=1,if=combo_points<5&(!ticking|(!talent.bloodtalons.enabled&remains<duration*0.3)|(talent.bloodtalons.enabled&buff.bloodtalons.up&(!talent.soul_of_the_forest.enabled&remains<=7|remains<=5)&persistent_multiplier>dot.rake.pmultiplier*0.80))&target.time_to_die-remains>tick_time
				if ComboPoints() < 5 and { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and { not Talent(soul_of_the_forest_talent) and target.DebuffRemaining(rake_debuff) <= 7 or target.DebuffRemaining(rake_debuff) <= 5 } and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.8 } and target.TimeToDie() - target.DebuffRemaining(rake_debuff) > target.TickTime(rake_debuff) Spell(rake)
				unless ComboPoints() < 5 and { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and { not Talent(soul_of_the_forest_talent) and target.DebuffRemaining(rake_debuff) <= 7 or target.DebuffRemaining(rake_debuff) <= 5 } and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.8 } and target.TimeToDie() - target.DebuffRemaining(rake_debuff) > target.TickTime(rake_debuff) and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake)
				{
					#moonfire_cat,cycle_targets=1,if=combo_points<5&remains<=4.2&target.time_to_die-remains>tick_time*2
					if ComboPoints() < 5 and target.DebuffRemaining(moonfire_cat_debuff) <= 4.2 and target.TimeToDie() - target.DebuffRemaining(moonfire_cat_debuff) > target.TickTime(moonfire_cat_debuff) * 2 Spell(moonfire_cat)
					#pool_resource,for_next=1
					#thrash_cat,cycle_targets=1,if=remains<=duration*0.3&spell_targets.swipe_cat>=2
					if target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() >= 2 Spell(thrash_cat)
					unless target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() >= 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
					{
						#brutal_slash,if=combo_points<5&((raid_event.adds.exists&raid_event.adds.in>(1+max_charges-charges_fractional)*15)|(!raid_event.adds.exists&(charges_fractional>2.66&time>10)))
						if ComboPoints() < 5 and { False(raid_event_adds_exists) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * 15 or not False(raid_event_adds_exists) and Charges(brutal_slash count=0) > 2.66 and TimeInCombat() > 10 } Spell(brutal_slash)
						#swipe_cat,if=combo_points<5&spell_targets.swipe_cat>=3
						if ComboPoints() < 5 and Enemies() >= 3 Spell(swipe_cat)
						#shred,if=combo_points<5&(spell_targets.swipe_cat<3|talent.brutal_slash.enabled)
						if ComboPoints() < 5 and { Enemies() < 3 or Talent(brutal_slash_talent) } Spell(shred)
					}
				}
			}
		}
	}
}

AddFunction FeralGeneratorMainPostConditions
{
}

AddFunction FeralGeneratorShortCdActions
{
	unless Enemies() > Enemies(tagged=1) and ComboPoints() < 5 and Spell(brutal_slash)
	{
		#ashamanes_frenzy,if=combo_points<=2&buff.elunes_guidance.down&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(buff.savage_roar.up|!talent.savage_roar.enabled)
		if ComboPoints() <= 2 and BuffExpires(elunes_guidance_buff) and { BuffPresent(bloodtalons_buff) or not Talent(bloodtalons_talent) } and { BuffPresent(savage_roar_buff) or not Talent(savage_roar_talent) } Spell(ashamanes_frenzy)
		#pool_resource,if=talent.elunes_guidance.enabled&combo_points=0&energy<action.ferocious_bite.cost+25-energy.regen*cooldown.elunes_guidance.remains
		unless Talent(elunes_guidance_talent) and ComboPoints() == 0 and Energy() < PowerCost(ferocious_bite) + 25 - EnergyRegenRate() * SpellCooldown(elunes_guidance)
		{
			#elunes_guidance,if=talent.elunes_guidance.enabled&combo_points=0&energy>=action.ferocious_bite.cost+25
			if Talent(elunes_guidance_talent) and ComboPoints() == 0 and Energy() >= PowerCost(ferocious_bite) + 25 Spell(elunes_guidance)
		}
	}
}

AddFunction FeralGeneratorShortCdPostConditions
{
	Enemies() > Enemies(tagged=1) and ComboPoints() < 5 and Spell(brutal_slash) or not { Talent(elunes_guidance_talent) and ComboPoints() == 0 and Energy() < PowerCost(ferocious_bite) + 25 - EnergyRegenRate() * SpellCooldown(elunes_guidance) } and { Talent(brutal_slash_talent) and Enemies() >= 9 and Spell(thrash_cat) or not { Talent(brutal_slash_talent) and Enemies() >= 9 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { Enemies() >= 6 and Spell(swipe_cat) or not { Enemies() >= 6 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and { ComboPoints() < 5 and { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and { not Talent(soul_of_the_forest_talent) and target.DebuffRemaining(rake_debuff) <= 7 or target.DebuffRemaining(rake_debuff) <= 5 } and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.8 } and target.TimeToDie() - target.DebuffRemaining(rake_debuff) > target.TickTime(rake_debuff) and Spell(rake) or not { ComboPoints() < 5 and { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and { not Talent(soul_of_the_forest_talent) and target.DebuffRemaining(rake_debuff) <= 7 or target.DebuffRemaining(rake_debuff) <= 5 } and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.8 } and target.TimeToDie() - target.DebuffRemaining(rake_debuff) > target.TickTime(rake_debuff) and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { ComboPoints() < 5 and target.DebuffRemaining(moonfire_cat_debuff) <= 4.2 and target.TimeToDie() - target.DebuffRemaining(moonfire_cat_debuff) > target.TickTime(moonfire_cat_debuff) * 2 and Spell(moonfire_cat) or target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() >= 2 and Spell(thrash_cat) or not { target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() >= 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { ComboPoints() < 5 and { False(raid_event_adds_exists) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * 15 or not False(raid_event_adds_exists) and Charges(brutal_slash count=0) > 2.66 and TimeInCombat() > 10 } and Spell(brutal_slash) or ComboPoints() < 5 and Enemies() >= 3 and Spell(swipe_cat) or ComboPoints() < 5 and { Enemies() < 3 or Talent(brutal_slash_talent) } and Spell(shred) } } } } }
}

AddFunction FeralGeneratorCdActions
{
	unless Enemies() > Enemies(tagged=1) and ComboPoints() < 5 and Spell(brutal_slash) or ComboPoints() <= 2 and BuffExpires(elunes_guidance_buff) and { BuffPresent(bloodtalons_buff) or not Talent(bloodtalons_talent) } and { BuffPresent(savage_roar_buff) or not Talent(savage_roar_talent) } and Spell(ashamanes_frenzy)
	{
		#pool_resource,if=talent.elunes_guidance.enabled&combo_points=0&energy<action.ferocious_bite.cost+25-energy.regen*cooldown.elunes_guidance.remains
		unless Talent(elunes_guidance_talent) and ComboPoints() == 0 and Energy() < PowerCost(ferocious_bite) + 25 - EnergyRegenRate() * SpellCooldown(elunes_guidance)
		{
			unless Talent(elunes_guidance_talent) and ComboPoints() == 0 and Energy() >= PowerCost(ferocious_bite) + 25 and Spell(elunes_guidance)
			{
				#pool_resource,for_next=1
				#thrash_cat,if=talent.brutal_slash.enabled&spell_targets.thrash_cat>=9
				unless Talent(brutal_slash_talent) and Enemies() >= 9 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
				{
					#pool_resource,for_next=1
					#swipe_cat,if=spell_targets.swipe_cat>=6
					unless Enemies() >= 6 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat)
					{
						#shadowmeld,if=combo_points<5&energy>=action.rake.cost&dot.rake.pmultiplier<2.1&buff.tigers_fury.up&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(!talent.incarnation.enabled|cooldown.incarnation.remains>18)&!buff.incarnation.up
						if ComboPoints() < 5 and Energy() >= PowerCost(rake) and target.DebuffPersistentMultiplier(rake_debuff) < 2.1 and BuffPresent(tigers_fury_buff) and { BuffPresent(bloodtalons_buff) or not Talent(bloodtalons_talent) } and { not Talent(incarnation_talent) or SpellCooldown(incarnation_king_of_the_jungle) > 18 } and not BuffPresent(incarnation_king_of_the_jungle_buff) Spell(shadowmeld)
					}
				}
			}
		}
	}
}

AddFunction FeralGeneratorCdPostConditions
{
	Enemies() > Enemies(tagged=1) and ComboPoints() < 5 and Spell(brutal_slash) or ComboPoints() <= 2 and BuffExpires(elunes_guidance_buff) and { BuffPresent(bloodtalons_buff) or not Talent(bloodtalons_talent) } and { BuffPresent(savage_roar_buff) or not Talent(savage_roar_talent) } and Spell(ashamanes_frenzy) or not { Talent(elunes_guidance_talent) and ComboPoints() == 0 and Energy() < PowerCost(ferocious_bite) + 25 - EnergyRegenRate() * SpellCooldown(elunes_guidance) } and { Talent(elunes_guidance_talent) and ComboPoints() == 0 and Energy() >= PowerCost(ferocious_bite) + 25 and Spell(elunes_guidance) or not { Talent(brutal_slash_talent) and Enemies() >= 9 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and not { Enemies() >= 6 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and { ComboPoints() < 5 and { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and { not Talent(soul_of_the_forest_talent) and target.DebuffRemaining(rake_debuff) <= 7 or target.DebuffRemaining(rake_debuff) <= 5 } and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.8 } and target.TimeToDie() - target.DebuffRemaining(rake_debuff) > target.TickTime(rake_debuff) and Spell(rake) or not { ComboPoints() < 5 and { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and { not Talent(soul_of_the_forest_talent) and target.DebuffRemaining(rake_debuff) <= 7 or target.DebuffRemaining(rake_debuff) <= 5 } and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.8 } and target.TimeToDie() - target.DebuffRemaining(rake_debuff) > target.TickTime(rake_debuff) and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { ComboPoints() < 5 and target.DebuffRemaining(moonfire_cat_debuff) <= 4.2 and target.TimeToDie() - target.DebuffRemaining(moonfire_cat_debuff) > target.TickTime(moonfire_cat_debuff) * 2 and Spell(moonfire_cat) or target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() >= 2 and Spell(thrash_cat) or not { target.DebuffRemaining(thrash_cat_debuff) <= BaseDuration(thrash_cat_debuff) * 0.3 and Enemies() >= 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { ComboPoints() < 5 and { False(raid_event_adds_exists) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * 15 or not False(raid_event_adds_exists) and Charges(brutal_slash count=0) > 2.66 and TimeInCombat() > 10 } and Spell(brutal_slash) or ComboPoints() < 5 and Enemies() >= 3 and Spell(swipe_cat) or ComboPoints() < 5 and { Enemies() < 3 or Talent(brutal_slash_talent) } and Spell(shred) } } } }
}

### actions.precombat

AddFunction FeralPrecombatMainActions
{
	#flask,type=flask_of_the_seventh_demon
	#food,type=nightborne_delicacy_platter
	#augmentation,type=defiled
	#regrowth,if=talent.bloodtalons.enabled
	if Talent(bloodtalons_talent) Spell(regrowth)
	#cat_form
	Spell(cat_form)
}

AddFunction FeralPrecombatMainPostConditions
{
}

AddFunction FeralPrecombatShortCdActions
{
	unless Talent(bloodtalons_talent) and Spell(regrowth) or Spell(cat_form)
	{
		#prowl
		Spell(prowl)
	}
}

AddFunction FeralPrecombatShortCdPostConditions
{
	Talent(bloodtalons_talent) and Spell(regrowth) or Spell(cat_form)
}

AddFunction FeralPrecombatCdActions
{
	unless Talent(bloodtalons_talent) and Spell(regrowth) or Spell(cat_form)
	{
		#snapshot_stats
		#potion,name=old_war
		if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war_potion usable=1)
	}
}

AddFunction FeralPrecombatCdPostConditions
{
	Talent(bloodtalons_talent) and Spell(regrowth) or Spell(cat_form)
}

### actions.sbt_opener

AddFunction FeralSbtOpenerMainActions
{
	#regrowth,if=talent.bloodtalons.enabled&combo_points=5&!buff.bloodtalons.up&!dot.rip.ticking
	if Talent(bloodtalons_talent) and ComboPoints() == 5 and not BuffPresent(bloodtalons_buff) and not target.DebuffPresent(rip_debuff) Spell(regrowth)
}

AddFunction FeralSbtOpenerMainPostConditions
{
}

AddFunction FeralSbtOpenerShortCdActions
{
	unless Talent(bloodtalons_talent) and ComboPoints() == 5 and not BuffPresent(bloodtalons_buff) and not target.DebuffPresent(rip_debuff) and Spell(regrowth)
	{
		#tigers_fury,if=!dot.rip.ticking&combo_points=5
		if not target.DebuffPresent(rip_debuff) and ComboPoints() == 5 Spell(tigers_fury)
	}
}

AddFunction FeralSbtOpenerShortCdPostConditions
{
	Talent(bloodtalons_talent) and ComboPoints() == 5 and not BuffPresent(bloodtalons_buff) and not target.DebuffPresent(rip_debuff) and Spell(regrowth)
}

AddFunction FeralSbtOpenerCdActions
{
}

AddFunction FeralSbtOpenerCdPostConditions
{
	Talent(bloodtalons_talent) and ComboPoints() == 5 and not BuffPresent(bloodtalons_buff) and not target.DebuffPresent(rip_debuff) and Spell(regrowth)
}

### Feral icons.

AddCheckBox(opt_druid_feral_aoe L(AOE) default specialization=feral)

AddIcon checkbox=!opt_druid_feral_aoe enemies=1 help=shortcd specialization=feral
{
	if not InCombat() FeralPrecombatShortCdActions()
	unless not InCombat() and FeralPrecombatShortCdPostConditions()
	{
		FeralDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_druid_feral_aoe help=shortcd specialization=feral
{
	if not InCombat() FeralPrecombatShortCdActions()
	unless not InCombat() and FeralPrecombatShortCdPostConditions()
	{
		FeralDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=feral
{
	if not InCombat() FeralPrecombatMainActions()
	unless not InCombat() and FeralPrecombatMainPostConditions()
	{
		FeralDefaultMainActions()
	}
}

AddIcon checkbox=opt_druid_feral_aoe help=aoe specialization=feral
{
	if not InCombat() FeralPrecombatMainActions()
	unless not InCombat() and FeralPrecombatMainPostConditions()
	{
		FeralDefaultMainActions()
	}
}

AddIcon checkbox=!opt_druid_feral_aoe enemies=1 help=cd specialization=feral
{
	if not InCombat() FeralPrecombatCdActions()
	unless not InCombat() and FeralPrecombatCdPostConditions()
	{
		FeralDefaultCdActions()
	}
}

AddIcon checkbox=opt_druid_feral_aoe help=cd specialization=feral
{
	if not InCombat() FeralPrecombatCdActions()
	unless not InCombat() and FeralPrecombatCdPostConditions()
	{
		FeralDefaultCdActions()
	}
}

### Required symbols
# ailuro_pouncers
# ashamanes_frenzy
# berserk_cat
# berserk_cat_buff
# bloodtalons_buff
# bloodtalons_talent
# brutal_slash
# brutal_slash_talent
# cat_form
# cat_form_buff
# clearcasting_buff
# dash
# displacer_beast
# displacer_beast_buff
# elunes_guidance
# elunes_guidance_buff
# elunes_guidance_talent
# ferocious_bite
# fiery_red_maimers_buff
# incarnation_king_of_the_jungle
# incarnation_king_of_the_jungle_buff
# incarnation_talent
# jagged_wounds_talent
# maim
# mangle
# mighty_bash
# moment_of_clarity_talent
# moonfire_cat
# moonfire_cat_debuff
# old_war_potion
# predatory_swiftness_buff
# prowl
# prowl_buff
# rake
# rake_debuff
# regrowth
# rip
# rip_debuff
# sabertooth_talent
# savage_roar
# savage_roar_buff
# savage_roar_talent
# shadowmeld
# shadowmeld_buff
# shred
# skull_bash
# soul_of_the_forest_talent
# swipe_cat
# t18_class_trinket
# thrash_cat
# thrash_cat_debuff
# tigers_fury
# tigers_fury_buff
# typhoon
# war_stomp
# wild_charge
# wild_charge_bear
# wild_charge_cat
]]
	OvaleScripts:RegisterScript("DRUID", "feral", name, desc, code, "script")
end

do
	local name = "simulationcraft_druid_guardian_t19p"
	local desc = "[7.0] SimulationCraft: Druid_Guardian_T19P"
	local code = [[
# Based on SimulationCraft profile "Druid_Guardian_T19P".
#	class=druid
#	spec=guardian
#	talents=3323323

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=guardian)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=guardian)

AddFunction GuardianInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
	{
		if target.InRange(skull_bash) and target.IsInterruptible() Spell(skull_bash)
		if target.InRange(mighty_bash) and not target.Classification(worldboss) Spell(mighty_bash)
		if target.Distance(less 10) and not target.Classification(worldboss) Spell(incapacitating_roar)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
		if target.Distance(less 15) and not target.Classification(worldboss) Spell(typhoon)
	}
}

AddFunction GuardianUseItemActions
{
	Item(Trinket0Slot text=13 usable=1)
	Item(Trinket1Slot text=14 usable=1)
}

AddFunction GuardianGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and { Stance(druid_bear_form) and not target.InRange(mangle) or Stance(druid_cat_form) and not target.InRange(shred) }
	{
		if target.InRange(wild_charge) Spell(wild_charge)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

### actions.default

AddFunction GuardianDefaultMainActions
{
	#frenzied_regeneration,if=incoming_damage_5s%health.max>=0.5|health<=health.max*0.4
	if IncomingDamage(5) / MaxHealth() >= 0.5 or Health() <= MaxHealth() * 0.4 Spell(frenzied_regeneration)
	#ironfur,if=(buff.ironfur.up=0)|(buff.gory_fur.up=1)|(rage>=80)
	if BuffPresent(ironfur_buff) == 0 or BuffPresent(gory_fur_buff) == 1 or Rage() >= 80 Spell(ironfur)
	#moonfire,if=buff.incarnation.up=1&dot.moonfire.remains<=4.8
	if BuffPresent(incarnation_guardian_of_ursoc_buff) == 1 and target.DebuffRemaining(moonfire_debuff) <= 4.8 Spell(moonfire)
	#thrash_bear,if=buff.incarnation.up=1&dot.thrash.remains<=4.5
	if BuffPresent(incarnation_guardian_of_ursoc_buff) == 1 and target.DebuffRemaining(thrash_bear_debuff) <= 4.5 Spell(thrash_bear)
	#mangle
	Spell(mangle)
	#thrash_bear
	Spell(thrash_bear)
	#pulverize,if=buff.pulverize.up=0|buff.pulverize.remains<=6
	if { BuffPresent(pulverize_buff) == 0 or BuffRemaining(pulverize_buff) <= 6 } and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) Spell(pulverize)
	#moonfire,if=buff.galactic_guardian.up=1&(!ticking|dot.moonfire.remains<=4.8)
	if BuffPresent(galactic_guardian_buff) == 1 and { not target.DebuffPresent(moonfire_debuff) or target.DebuffRemaining(moonfire_debuff) <= 4.8 } Spell(moonfire)
	#moonfire,if=buff.galactic_guardian.up=1
	if BuffPresent(galactic_guardian_buff) == 1 Spell(moonfire)
	#moonfire,if=dot.moonfire.remains<=4.8
	if target.DebuffRemaining(moonfire_debuff) <= 4.8 Spell(moonfire)
	#swipe_bear
	Spell(swipe_bear)
}

AddFunction GuardianDefaultMainPostConditions
{
}

AddFunction GuardianDefaultShortCdActions
{
	#auto_attack
	GuardianGetInMeleeRange()
	#rage_of_the_sleeper
	Spell(rage_of_the_sleeper)
	#lunar_beam
	Spell(lunar_beam)

	unless { IncomingDamage(5) / MaxHealth() >= 0.5 or Health() <= MaxHealth() * 0.4 } and Spell(frenzied_regeneration)
	{
		#bristling_fur,if=buff.ironfur.stack=1|buff.ironfur.down
		if BuffStacks(ironfur_buff) == 1 or BuffExpires(ironfur_buff) Spell(bristling_fur)
	}
}

AddFunction GuardianDefaultShortCdPostConditions
{
	{ IncomingDamage(5) / MaxHealth() >= 0.5 or Health() <= MaxHealth() * 0.4 } and Spell(frenzied_regeneration) or { BuffPresent(ironfur_buff) == 0 or BuffPresent(gory_fur_buff) == 1 or Rage() >= 80 } and Spell(ironfur) or BuffPresent(incarnation_guardian_of_ursoc_buff) == 1 and target.DebuffRemaining(moonfire_debuff) <= 4.8 and Spell(moonfire) or BuffPresent(incarnation_guardian_of_ursoc_buff) == 1 and target.DebuffRemaining(thrash_bear_debuff) <= 4.5 and Spell(thrash_bear) or Spell(mangle) or Spell(thrash_bear) or { BuffPresent(pulverize_buff) == 0 or BuffRemaining(pulverize_buff) <= 6 } and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or BuffPresent(galactic_guardian_buff) == 1 and { not target.DebuffPresent(moonfire_debuff) or target.DebuffRemaining(moonfire_debuff) <= 4.8 } and Spell(moonfire) or BuffPresent(galactic_guardian_buff) == 1 and Spell(moonfire) or target.DebuffRemaining(moonfire_debuff) <= 4.8 and Spell(moonfire) or Spell(swipe_bear)
}

AddFunction GuardianDefaultCdActions
{
	#skull_bash
	GuardianInterruptActions()
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_energy)
	#use_item,slot=trinket2
	GuardianUseItemActions()
	#incarnation
	Spell(incarnation_guardian_of_ursoc)
}

AddFunction GuardianDefaultCdPostConditions
{
	Spell(rage_of_the_sleeper) or Spell(lunar_beam) or { IncomingDamage(5) / MaxHealth() >= 0.5 or Health() <= MaxHealth() * 0.4 } and Spell(frenzied_regeneration) or { BuffPresent(ironfur_buff) == 0 or BuffPresent(gory_fur_buff) == 1 or Rage() >= 80 } and Spell(ironfur) or BuffPresent(incarnation_guardian_of_ursoc_buff) == 1 and target.DebuffRemaining(moonfire_debuff) <= 4.8 and Spell(moonfire) or BuffPresent(incarnation_guardian_of_ursoc_buff) == 1 and target.DebuffRemaining(thrash_bear_debuff) <= 4.5 and Spell(thrash_bear) or Spell(mangle) or Spell(thrash_bear) or { BuffPresent(pulverize_buff) == 0 or BuffRemaining(pulverize_buff) <= 6 } and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or BuffPresent(galactic_guardian_buff) == 1 and { not target.DebuffPresent(moonfire_debuff) or target.DebuffRemaining(moonfire_debuff) <= 4.8 } and Spell(moonfire) or BuffPresent(galactic_guardian_buff) == 1 and Spell(moonfire) or target.DebuffRemaining(moonfire_debuff) <= 4.8 and Spell(moonfire) or Spell(swipe_bear)
}

### actions.precombat

AddFunction GuardianPrecombatMainActions
{
	#flask,type=flask_of_the_seventh_demon
	#food,type=azshari_salad
	#augmentation,type=defiled
	#bear_form
	Spell(bear_form)
}

AddFunction GuardianPrecombatMainPostConditions
{
}

AddFunction GuardianPrecombatShortCdActions
{
}

AddFunction GuardianPrecombatShortCdPostConditions
{
	Spell(bear_form)
}

AddFunction GuardianPrecombatCdActions
{
}

AddFunction GuardianPrecombatCdPostConditions
{
	Spell(bear_form)
}

### Guardian icons.

AddCheckBox(opt_druid_guardian_aoe L(AOE) default specialization=guardian)

AddIcon checkbox=!opt_druid_guardian_aoe enemies=1 help=shortcd specialization=guardian
{
	if not InCombat() GuardianPrecombatShortCdActions()
	unless not InCombat() and GuardianPrecombatShortCdPostConditions()
	{
		GuardianDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_druid_guardian_aoe help=shortcd specialization=guardian
{
	if not InCombat() GuardianPrecombatShortCdActions()
	unless not InCombat() and GuardianPrecombatShortCdPostConditions()
	{
		GuardianDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=guardian
{
	if not InCombat() GuardianPrecombatMainActions()
	unless not InCombat() and GuardianPrecombatMainPostConditions()
	{
		GuardianDefaultMainActions()
	}
}

AddIcon checkbox=opt_druid_guardian_aoe help=aoe specialization=guardian
{
	if not InCombat() GuardianPrecombatMainActions()
	unless not InCombat() and GuardianPrecombatMainPostConditions()
	{
		GuardianDefaultMainActions()
	}
}

AddIcon checkbox=!opt_druid_guardian_aoe enemies=1 help=cd specialization=guardian
{
	if not InCombat() GuardianPrecombatCdActions()
	unless not InCombat() and GuardianPrecombatCdPostConditions()
	{
		GuardianDefaultCdActions()
	}
}

AddIcon checkbox=opt_druid_guardian_aoe help=cd specialization=guardian
{
	if not InCombat() GuardianPrecombatCdActions()
	unless not InCombat() and GuardianPrecombatCdPostConditions()
	{
		GuardianDefaultCdActions()
	}
}

### Required symbols
# arcane_torrent_energy
# bear_form
# berserking
# blood_fury_apsp
# bristling_fur
# frenzied_regeneration
# galactic_guardian_buff
# gory_fur_buff
# incapacitating_roar
# incarnation_guardian_of_ursoc
# incarnation_guardian_of_ursoc_buff
# ironfur
# ironfur_buff
# lunar_beam
# mangle
# mighty_bash
# moonfire
# moonfire_debuff
# pulverize
# pulverize_buff
# rage_of_the_sleeper
# shred
# skull_bash
# swipe_bear
# thrash_bear
# thrash_bear_debuff
# typhoon
# war_stomp
# wild_charge
# wild_charge_bear
# wild_charge_cat
]]
	OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
end
