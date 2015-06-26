local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "mmo_champion_rogue_assassination_20"
	local desc = "[6.2] MMO-Champion: Rogue_Assassination_2.0"
	local code = [[
# Based on SimulationCraft profile "Rogue_Assassination_2.0".
#	class=rogue
#	spec=assassination
#	talents=3000032
#	glyphs=vendetta/energy/disappearance

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=assassination)
AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default specialization=assassination)
AddCheckBox(opt_vanish SpellName(vanish) default specialization=assassination)

AddFunction AssassinationUsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction AssassinationUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

### actions.default

AddFunction AssassinationDefaultMainActions
{
	#run_action_list,name=opener_ant,if=(time<5.5&combo_points<5)&talent.anticipation.enabled
	if TimeInCombat() < 5.5 and ComboPoints() < 5 and Talent(anticipation_talent) AssassinationOpenerAntMainActions()
	#run_action_list,name=reflection_rotation_ant_ref,if=buff.shadow_reflection.up&talent.anticipation.enabled&talent.shadow_reflection.enabled
	if BuffPresent(shadow_reflection_buff) and Talent(anticipation_talent) and Talent(shadow_reflection_talent) AssassinationReflectionRotationAntRefMainActions()
	#run_action_list,name=vanish_rotation_ant_ref,if=buff.vanish.up&talent.anticipation.enabled&talent.shadow_reflection.enabled
	if BuffPresent(vanish_buff) and Talent(anticipation_talent) and Talent(shadow_reflection_talent) AssassinationVanishRotationAntRefMainActions()
	#call_action_list,name=cd_controller_ant,if=talent.anticipation.enabled
	if Talent(anticipation_talent) AssassinationCdControllerAntMainActions()
	#run_action_list,name=generators_ant_env,if=talent.anticipation.enabled&buff.envenom.up
	if Talent(anticipation_talent) and BuffPresent(envenom_buff) AssassinationGeneratorsAntEnvMainActions()
	#run_action_list,name=generators_ant,if=talent.anticipation.enabled
	if Talent(anticipation_talent) AssassinationGeneratorsAntMainActions()
}

AddFunction AssassinationDefaultShortCdActions
{
	unless TimeInCombat() < 5.5 and ComboPoints() < 5 and Talent(anticipation_talent) and AssassinationOpenerAntShortCdPostConditions()
	{
		unless BuffPresent(shadow_reflection_buff) and Talent(anticipation_talent) and Talent(shadow_reflection_talent) and AssassinationReflectionRotationAntRefShortCdPostConditions()
		{
			unless BuffPresent(vanish_buff) and Talent(anticipation_talent) and Talent(shadow_reflection_talent) and AssassinationVanishRotationAntRefShortCdPostConditions()
			{
				#call_action_list,name=cd_controller_ant,if=talent.anticipation.enabled
				if Talent(anticipation_talent) AssassinationCdControllerAntShortCdActions()
			}
		}
	}
}

AddFunction AssassinationDefaultCdActions
{
	unless TimeInCombat() < 5.5 and ComboPoints() < 5 and Talent(anticipation_talent) and AssassinationOpenerAntCdPostConditions()
	{
		#run_action_list,name=reflection_rotation_ant_ref,if=buff.shadow_reflection.up&talent.anticipation.enabled&talent.shadow_reflection.enabled
		if BuffPresent(shadow_reflection_buff) and Talent(anticipation_talent) and Talent(shadow_reflection_talent) AssassinationReflectionRotationAntRefCdActions()

		unless BuffPresent(shadow_reflection_buff) and Talent(anticipation_talent) and Talent(shadow_reflection_talent) and AssassinationReflectionRotationAntRefCdPostConditions()
		{
			unless BuffPresent(vanish_buff) and Talent(anticipation_talent) and Talent(shadow_reflection_talent) and AssassinationVanishRotationAntRefCdPostConditions()
			{
				#call_action_list,name=cd_controller_ant,if=talent.anticipation.enabled
				if Talent(anticipation_talent) AssassinationCdControllerAntCdActions()

				unless Talent(anticipation_talent) and AssassinationCdControllerAntCdPostConditions()
				{
					#run_action_list,name=generators_ant_env,if=talent.anticipation.enabled&buff.envenom.up
					if Talent(anticipation_talent) and BuffPresent(envenom_buff) AssassinationGeneratorsAntEnvCdActions()

					unless Talent(anticipation_talent) and BuffPresent(envenom_buff) and AssassinationGeneratorsAntEnvCdPostConditions()
					{
						#run_action_list,name=generators_ant,if=talent.anticipation.enabled
						if Talent(anticipation_talent) AssassinationGeneratorsAntCdActions()
					}
				}
			}
		}
	}
}

### actions.cd_controller_ant

AddFunction AssassinationCdControllerAntMainActions
{
	#call_action_list,name=pool_ant,if=energy+energy.regen*cooldown.vendetta.remains<=105
	if Energy() + EnergyRegenRate() * SpellCooldown(vendetta) <= 105 AssassinationPoolAntMainActions()
}

AddFunction AssassinationCdControllerAntShortCdActions
{
	#vanish,if=energy>13&!buff.stealth.up&combo_points+anticipation_charges<8&buff.blindside.down
	if Energy() > 13 and not BuffPresent(stealthed_buff any=1) and ComboPoints() + BuffStacks(anticipation_buff) < 8 and BuffExpires(blindside_buff) and { CheckBoxOn(opt_vanish) or not SpellCooldown(preparation) > 0 } Spell(vanish)
}

AddFunction AssassinationCdControllerAntCdActions
{
	#shadow_reflection,if=energy>35
	if Energy() > 35 Spell(shadow_reflection)
	#preparation,if=cooldown.vanish.remains>25
	if SpellCooldown(vanish) > 25 Spell(preparation)
	#call_action_list,name=pool_ant,if=energy+energy.regen*cooldown.vendetta.remains<=105
	if Energy() + EnergyRegenRate() * SpellCooldown(vendetta) <= 105 AssassinationPoolAntCdActions()
}

AddFunction AssassinationCdControllerAntCdPostConditions
{
	Energy() + EnergyRegenRate() * SpellCooldown(vendetta) <= 105 and AssassinationPoolAntCdPostConditions()
}

### actions.energy_neutral_finishers

AddFunction AssassinationEnergyNeutralFinishersMainActions
{
	#rupture,cycle_targets=1,if=ticks_remain<3
	if target.TicksRemaining(rupture_debuff) < 3 Spell(rupture)
}

AddFunction AssassinationEnergyNeutralFinishersShortCdPostConditions
{
	target.TicksRemaining(rupture_debuff) < 3 and Spell(rupture)
}

AddFunction AssassinationEnergyNeutralFinishersCdPostConditions
{
	target.TicksRemaining(rupture_debuff) < 3 and Spell(rupture)
}

### actions.finishers

AddFunction AssassinationFinishersMainActions
{
	#rupture,cycle_targets=1,if=ticks_remain<3
	if target.TicksRemaining(rupture_debuff) < 3 Spell(rupture)
	#pool_resource,for_next=1,extra_amount=50
	#death_from_above
	Spell(death_from_above)
	unless SpellUsable(death_from_above) and SpellCooldown(death_from_above) < TimeToEnergy(50)
	{
		#envenom,cycle_targets=1,if=target.health.pct<=35&(energy+energy.regen*cooldown.vendetta.remains>=105&(buff.envenom.remains<=1.8|energy>45))|buff.bloodlust.up|debuff.vendetta.up
		if target.HealthPercent() <= 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 45 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) Spell(envenom)
		#envenom,cycle_targets=1,if=target.health.pct>35&(energy+energy.regen*cooldown.vendetta.remains>=105&(buff.envenom.remains<=1.8|energy>55))|buff.bloodlust.up|debuff.vendetta.up
		if target.HealthPercent() > 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 55 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) Spell(envenom)
	}
}

AddFunction AssassinationFinishersShortCdPostConditions
{
	target.TicksRemaining(rupture_debuff) < 3 and Spell(rupture) or not { SpellUsable(death_from_above) and SpellCooldown(death_from_above) < TimeToEnergy(50) } and { { target.HealthPercent() <= 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 45 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) } and Spell(envenom) or { target.HealthPercent() > 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 55 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) } and Spell(envenom) }
}

AddFunction AssassinationFinishersCdActions
{
	unless target.TicksRemaining(rupture_debuff) < 3 and Spell(rupture)
	{
		#pool_resource,for_next=1,extra_amount=50
		#death_from_above
		unless SpellUsable(death_from_above) and SpellCooldown(death_from_above) < TimeToEnergy(50)
		{
			unless { target.HealthPercent() <= 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 45 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) } and Spell(envenom) or { target.HealthPercent() > 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 55 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) } and Spell(envenom)
			{
				#call_action_list,name=pool_ant_env
				AssassinationPoolAntEnvCdActions()
			}
		}
	}
}

AddFunction AssassinationFinishersCdPostConditions
{
	target.TicksRemaining(rupture_debuff) < 3 and Spell(rupture) or not { SpellUsable(death_from_above) and SpellCooldown(death_from_above) < TimeToEnergy(50) } and { { target.HealthPercent() <= 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 45 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) } and Spell(envenom) or { target.HealthPercent() > 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 55 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) } and Spell(envenom) }
}

### actions.generators_ant

AddFunction AssassinationGeneratorsAntMainActions
{
	#call_action_list,name=finishers,if=combo_points=5
	if ComboPoints() == 5 AssassinationFinishersMainActions()
	#call_action_list,name=energy_neutral_finishers,if=combo_points=5
	if ComboPoints() == 5 AssassinationEnergyNeutralFinishersMainActions()
	#dispatch
	Spell(dispatch)
	#mutilate
	Spell(mutilate)
}

AddFunction AssassinationGeneratorsAntShortCdPostConditions
{
	ComboPoints() == 5 and AssassinationFinishersShortCdPostConditions() or ComboPoints() == 5 and AssassinationEnergyNeutralFinishersShortCdPostConditions() or Spell(dispatch) or Spell(mutilate)
}

AddFunction AssassinationGeneratorsAntCdActions
{
	#call_action_list,name=finishers,if=combo_points=5
	if ComboPoints() == 5 AssassinationFinishersCdActions()
}

AddFunction AssassinationGeneratorsAntCdPostConditions
{
	ComboPoints() == 5 and AssassinationFinishersCdPostConditions() or ComboPoints() == 5 and AssassinationEnergyNeutralFinishersCdPostConditions() or Spell(dispatch) or Spell(mutilate)
}

### actions.generators_ant_env

AddFunction AssassinationGeneratorsAntEnvMainActions
{
	#call_action_list,name=finishers,if=combo_points=5&combo_points+anticipation_charges>=7
	if ComboPoints() == 5 and ComboPoints() + BuffStacks(anticipation_buff) >= 7 AssassinationFinishersMainActions()
	#call_action_list,name=energy_neutral_finishers,if=combo_points=5
	if ComboPoints() == 5 AssassinationEnergyNeutralFinishersMainActions()
	#dispatch
	Spell(dispatch)
	#mutilate
	Spell(mutilate)
}

AddFunction AssassinationGeneratorsAntEnvShortCdPostConditions
{
	ComboPoints() == 5 and ComboPoints() + BuffStacks(anticipation_buff) >= 7 and AssassinationFinishersShortCdPostConditions() or ComboPoints() == 5 and AssassinationEnergyNeutralFinishersShortCdPostConditions() or Spell(dispatch) or Spell(mutilate)
}

AddFunction AssassinationGeneratorsAntEnvCdActions
{
	#call_action_list,name=finishers,if=combo_points=5&combo_points+anticipation_charges>=7
	if ComboPoints() == 5 and ComboPoints() + BuffStacks(anticipation_buff) >= 7 AssassinationFinishersCdActions()
}

AddFunction AssassinationGeneratorsAntEnvCdPostConditions
{
	ComboPoints() == 5 and ComboPoints() + BuffStacks(anticipation_buff) >= 7 and AssassinationFinishersCdPostConditions() or ComboPoints() == 5 and AssassinationEnergyNeutralFinishersCdPostConditions() or Spell(dispatch) or Spell(mutilate)
}

### actions.opener_ant

AddFunction AssassinationOpenerAntMainActions
{
	#mutilate,if=time<1
	if TimeInCombat() < 1 Spell(mutilate)
	#rupture,if=time<2
	if TimeInCombat() < 2 Spell(rupture)
	#dispatch
	Spell(dispatch)
	#mutilate
	Spell(mutilate)
}

AddFunction AssassinationOpenerAntShortCdPostConditions
{
	TimeInCombat() < 1 and Spell(mutilate) or TimeInCombat() < 2 and Spell(rupture) or Spell(dispatch) or Spell(mutilate)
}

AddFunction AssassinationOpenerAntCdPostConditions
{
	TimeInCombat() < 1 and Spell(mutilate) or TimeInCombat() < 2 and Spell(rupture) or Spell(dispatch) or Spell(mutilate)
}

### actions.pool_ant

AddFunction AssassinationPoolAntMainActions
{
	#call_action_list,name=finishers,if=combo_points+anticipation_charges>=8&combo_points=5
	if ComboPoints() + BuffStacks(anticipation_buff) >= 8 and ComboPoints() == 5 AssassinationFinishersMainActions()
}

AddFunction AssassinationPoolAntCdActions
{
	#call_action_list,name=finishers,if=combo_points+anticipation_charges>=8&combo_points=5
	if ComboPoints() + BuffStacks(anticipation_buff) >= 8 and ComboPoints() == 5 AssassinationFinishersCdActions()

	unless ComboPoints() + BuffStacks(anticipation_buff) >= 8 and ComboPoints() == 5 and AssassinationFinishersCdPostConditions()
	{
		#preparation,if=cooldown.vanish.remains>25|target.time_to_die<17&cooldown.vendetta.remains>1
		if SpellCooldown(vanish) > 25 or target.TimeToDie() < 17 and SpellCooldown(vendetta) > 1 Spell(preparation)
	}
}

AddFunction AssassinationPoolAntCdPostConditions
{
	ComboPoints() + BuffStacks(anticipation_buff) >= 8 and ComboPoints() == 5 and AssassinationFinishersCdPostConditions()
}

### actions.pool_ant_env

AddFunction AssassinationPoolAntEnvCdActions
{
	#preparation,if=cooldown.vanish.remains>25|target.time_to_die<17&cooldown.vendetta.remains>1
	if SpellCooldown(vanish) > 25 or target.TimeToDie() < 17 and SpellCooldown(vendetta) > 1 Spell(preparation)
}

### actions.precombat

AddFunction AssassinationPrecombatMainActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=sleeper_sushi
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#stealth
	Spell(stealth)
}

AddFunction AssassinationPrecombatShortCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth)
	{
		#marked_for_death
		Spell(marked_for_death)
	}
}

AddFunction AssassinationPrecombatShortCdPostConditions
{
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth)
}

AddFunction AssassinationPrecombatCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison)
	{
		#snapshot_stats
		#potion,name=draenic_agility
		AssassinationUsePotionAgility()
	}
}

AddFunction AssassinationPrecombatCdPostConditions
{
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth)
}

### actions.reflection_rotation_ant_ref

AddFunction AssassinationReflectionRotationAntRefMainActions
{
	#run_action_list,name=generators_ant_env,if=talent.anticipation.enabled&buff.envenom.up
	if Talent(anticipation_talent) and BuffPresent(envenom_buff) AssassinationGeneratorsAntEnvMainActions()
	#run_action_list,name=generators_ant,if=talent.anticipation.enabled
	if Talent(anticipation_talent) AssassinationGeneratorsAntMainActions()
}

AddFunction AssassinationReflectionRotationAntRefShortCdPostConditions
{
	Talent(anticipation_talent) and BuffPresent(envenom_buff) and AssassinationGeneratorsAntEnvShortCdPostConditions() or Talent(anticipation_talent) and AssassinationGeneratorsAntShortCdPostConditions()
}

AddFunction AssassinationReflectionRotationAntRefCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40|(buff.shadow_reflection.up|(!talent.shadow_reflection.enabled&buff.vendetta.up))&(trinket.stat.agi.up|trinket.stat.multistrike.up|trinket.stat.crit.up|buff.archmages_greater_incandescence_agi.up)|((buff.shadow_reflection.up|(!talent.shadow_reflection.enabled&buff.vendetta.up))&target.time_to_die<136)
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 or { BuffPresent(shadow_reflection_buff) or not Talent(shadow_reflection_talent) and BuffPresent(vendetta_buff) } and { BuffPresent(trinket_stat_agi_buff) or BuffPresent(trinket_stat_multistrike_buff) or BuffPresent(trinket_stat_crit_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } or { BuffPresent(shadow_reflection_buff) or not Talent(shadow_reflection_talent) and BuffPresent(vendetta_buff) } and target.TimeToDie() < 136 AssassinationUsePotionAgility()
	#vendetta
	Spell(vendetta)
	#use_item,slot=trinket2
	AssassinationUseItemActions()
	#use_item,slot=finger1
	AssassinationUseItemActions()
	#Arcane_Torrent,if=energy<90
	if Energy() < 90 Spell(arcane_torrent_energy)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#run_action_list,name=generators_ant_env,if=talent.anticipation.enabled&buff.envenom.up
	if Talent(anticipation_talent) and BuffPresent(envenom_buff) AssassinationGeneratorsAntEnvCdActions()

	unless Talent(anticipation_talent) and BuffPresent(envenom_buff) and AssassinationGeneratorsAntEnvCdPostConditions()
	{
		#run_action_list,name=generators_ant,if=talent.anticipation.enabled
		if Talent(anticipation_talent) AssassinationGeneratorsAntCdActions()
	}
}

AddFunction AssassinationReflectionRotationAntRefCdPostConditions
{
	Talent(anticipation_talent) and BuffPresent(envenom_buff) and AssassinationGeneratorsAntEnvCdPostConditions() or Talent(anticipation_talent) and AssassinationGeneratorsAntCdPostConditions()
}

### actions.vanish_rotation_ant_ref

AddFunction AssassinationVanishRotationAntRefMainActions
{
	#mutilate
	Spell(mutilate)
}

AddFunction AssassinationVanishRotationAntRefShortCdPostConditions
{
	Spell(mutilate)
}

AddFunction AssassinationVanishRotationAntRefCdPostConditions
{
	Spell(mutilate)
}

### Assassination icons.

AddCheckBox(opt_rogue_assassination_aoe L(AOE) default specialization=assassination)

AddIcon checkbox=!opt_rogue_assassination_aoe enemies=1 help=shortcd specialization=assassination
{
	if not InCombat() AssassinationPrecombatShortCdActions()
	unless not InCombat() and AssassinationPrecombatShortCdPostConditions()
	{
		AssassinationDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_rogue_assassination_aoe help=shortcd specialization=assassination
{
	if not InCombat() AssassinationPrecombatShortCdActions()
	unless not InCombat() and AssassinationPrecombatShortCdPostConditions()
	{
		AssassinationDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=assassination
{
	if not InCombat() AssassinationPrecombatMainActions()
	AssassinationDefaultMainActions()
}

AddIcon checkbox=opt_rogue_assassination_aoe help=aoe specialization=assassination
{
	if not InCombat() AssassinationPrecombatMainActions()
	AssassinationDefaultMainActions()
}

AddIcon checkbox=!opt_rogue_assassination_aoe enemies=1 help=cd specialization=assassination
{
	if not InCombat() AssassinationPrecombatCdActions()
	unless not InCombat() and AssassinationPrecombatCdPostConditions()
	{
		AssassinationDefaultCdActions()
	}
}

AddIcon checkbox=opt_rogue_assassination_aoe help=cd specialization=assassination
{
	if not InCombat() AssassinationPrecombatCdActions()
	unless not InCombat() and AssassinationPrecombatCdPostConditions()
	{
		AssassinationDefaultCdActions()
	}
}

### Required symbols
# anticipation_buff
# anticipation_talent
# arcane_torrent_energy
# archmages_greater_incandescence_agi_buff
# berserking
# blindside_buff
# blood_fury_ap
# deadly_poison
# death_from_above
# dispatch
# draenic_agility_potion
# envenom
# envenom_buff
# kick
# lethal_poison_buff
# marked_for_death
# mutilate
# preparation
# rupture
# rupture_debuff
# shadow_reflection
# shadow_reflection_buff
# shadow_reflection_talent
# shadowstep
# stealth
# vanish
# vanish_buff
# vendetta
# vendetta_buff
# vendetta_debuff
]]
	OvaleScripts:RegisterScript("ROGUE", "assassination", name, desc, code, "script")
end
