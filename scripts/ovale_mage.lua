local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_mage"
	local desc = "[6.0] Ovale: Rotations (Arcane, Fire, Frost)"
	local code = [[
# Mage rotation functions based on SimulationCraft.

###
### Arcane
###
# Based on SimulationCraft profile "Mage_Arcane_T17M".
#	class=mage
#	spec=arcane
#	talents=3003322
#	glyphs=arcane_power/cone_of_cold

AddCheckBox(opt_interrupt L(interrupt) default specialization=arcane)
AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=arcane)
AddCheckBox(opt_arcane_mage_burn_phase L(arcane_mage_burn_phase) default specialization=arcane)
AddCheckBox(opt_time_warp SpellName(time_warp) specialization=arcane)

AddFunction ArcaneUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction ArcaneInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		Spell(counterspell)
		if not target.Classification(worldboss)
		{
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

### actions.default

AddFunction ArcaneDefaultMainActions
{
	#call_action_list,name=init_crystal,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up
	if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 ArcaneInitCrystalMainActions()
	#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
	if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) ArcaneCrystalSequenceMainActions()
	#call_action_list,name=aoe,if=active_enemies>=4
	if Enemies() >= 4 ArcaneAoeMainActions()
	#call_action_list,name=burn,if=time_to_die<mana.pct*0.35*spell_haste|cooldown.evocation.remains<=(mana.pct-30)*0.3*spell_haste|(buff.arcane_power.up&cooldown.evocation.remains<=(mana.pct-30)*0.4*spell_haste)
	if { target.TimeToDie() < ManaPercent() * 0.35 * { 100 / { 100 + SpellHaste() } } or SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.3 * { 100 / { 100 + SpellHaste() } } or BuffPresent(arcane_power_buff) and SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.4 * { 100 / { 100 + SpellHaste() } } } and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnMainActions()
	#call_action_list,name=conserve
	ArcaneConserveMainActions()
}

AddFunction ArcaneDefaultShortCdActions
{
	#blink,if=movement.distance>10
	if 0 > 10 Spell(blink)
	#blazing_speed,if=movement.remains>0
	if 0 > 0 Spell(blazing_speed)
	#ice_floes,if=buff.ice_floes.down&(raid_event.movement.distance>0|raid_event.movement.in<action.arcane_missiles.cast_time)
	if BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < CastTime(arcane_missiles) } Spell(ice_floes)
	#rune_of_power,if=buff.rune_of_power.remains<cast_time
	if TotemRemaining(rune_of_power) < CastTime(rune_of_power) Spell(rune_of_power)
	#call_action_list,name=init_crystal,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up
	if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 ArcaneInitCrystalShortCdActions()

	unless Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 and ArcaneInitCrystalShortCdPostConditions()
	{
		#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
		if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) ArcaneCrystalSequenceShortCdActions()

		unless Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) and ArcaneCrystalSequenceShortCdPostConditions()
		{
			#call_action_list,name=aoe,if=active_enemies>=4
			if Enemies() >= 4 ArcaneAoeShortCdActions()

			unless Enemies() >= 4 and ArcaneAoeShortCdPostConditions()
			{
				#call_action_list,name=burn,if=time_to_die<mana.pct*0.35*spell_haste|cooldown.evocation.remains<=(mana.pct-30)*0.3*spell_haste|(buff.arcane_power.up&cooldown.evocation.remains<=(mana.pct-30)*0.4*spell_haste)
				if { target.TimeToDie() < ManaPercent() * 0.35 * { 100 / { 100 + SpellHaste() } } or SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.3 * { 100 / { 100 + SpellHaste() } } or BuffPresent(arcane_power_buff) and SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.4 * { 100 / { 100 + SpellHaste() } } } and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnShortCdActions()

				unless { target.TimeToDie() < ManaPercent() * 0.35 * { 100 / { 100 + SpellHaste() } } or SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.3 * { 100 / { 100 + SpellHaste() } } or BuffPresent(arcane_power_buff) and SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.4 * { 100 / { 100 + SpellHaste() } } } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnShortCdPostConditions()
				{
					#call_action_list,name=conserve
					ArcaneConserveShortCdActions()
				}
			}
		}
	}
}

AddFunction ArcaneDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() ArcaneInterruptActions()

	unless 0 > 10 and Spell(blink)
	{
		#cold_snap,if=health.pct<30
		if HealthPercent() < 30 Spell(cold_snap)
		#time_warp,if=target.health.pct<25|time>5
		if { target.HealthPercent() < 25 or TimeInCombat() > 5 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)

		unless BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < CastTime(arcane_missiles) } and Spell(ice_floes) or TotemRemaining(rune_of_power) < CastTime(rune_of_power) and Spell(rune_of_power)
		{
			#mirror_image
			Spell(mirror_image)
			#cold_snap,if=buff.presence_of_mind.down&cooldown.presence_of_mind.remains>75
			if BuffExpires(presence_of_mind_buff) and SpellCooldown(presence_of_mind) > 75 Spell(cold_snap)
			#call_action_list,name=init_crystal,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up
			if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 ArcaneInitCrystalCdActions()

			unless Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 and ArcaneInitCrystalCdPostConditions()
			{
				#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
				if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) ArcaneCrystalSequenceCdActions()

				unless Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) and ArcaneCrystalSequenceCdPostConditions()
				{
					#call_action_list,name=aoe,if=active_enemies>=4
					if Enemies() >= 4 ArcaneAoeCdActions()

					unless Enemies() >= 4 and ArcaneAoeCdPostConditions()
					{
						#call_action_list,name=burn,if=time_to_die<mana.pct*0.35*spell_haste|cooldown.evocation.remains<=(mana.pct-30)*0.3*spell_haste|(buff.arcane_power.up&cooldown.evocation.remains<=(mana.pct-30)*0.4*spell_haste)
						if { target.TimeToDie() < ManaPercent() * 0.35 * { 100 / { 100 + SpellHaste() } } or SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.3 * { 100 / { 100 + SpellHaste() } } or BuffPresent(arcane_power_buff) and SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.4 * { 100 / { 100 + SpellHaste() } } } and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnCdActions()

						unless { target.TimeToDie() < ManaPercent() * 0.35 * { 100 / { 100 + SpellHaste() } } or SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.3 * { 100 / { 100 + SpellHaste() } } or BuffPresent(arcane_power_buff) and SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.4 * { 100 / { 100 + SpellHaste() } } } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnCdPostConditions()
						{
							#call_action_list,name=conserve
							ArcaneConserveCdActions()
						}
					}
				}
			}
		}
	}
}

### actions.aoe

AddFunction ArcaneAoeMainActions
{
	#nether_tempest,cycle_targets=1,if=buff.arcane_charge.stack=4&(active_dot.nether_tempest=0|(ticking&remains<3.6))
	if DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } Spell(nether_tempest)
	#supernova
	Spell(supernova)
	#arcane_barrage,if=buff.arcane_charge.stack=4
	if DebuffStacks(arcane_charge_debuff) == 4 Spell(arcane_barrage)
	#arcane_explosion
	Spell(arcane_explosion)
}

AddFunction ArcaneAoeShortCdActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsShortCdActions()

	unless DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or Spell(supernova) or DebuffStacks(arcane_charge_debuff) == 4 and Spell(arcane_barrage)
	{
		#arcane_orb,if=buff.arcane_charge.stack<4
		if DebuffStacks(arcane_charge_debuff) < 4 Spell(arcane_orb)
		#cone_of_cold,if=glyph.cone_of_cold.enabled
		if Glyph(glyph_of_cone_of_cold) Spell(cone_of_cold)
	}
}

AddFunction ArcaneAoeShortCdPostConditions
{
	DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or Spell(supernova) or DebuffStacks(arcane_charge_debuff) == 4 and Spell(arcane_barrage) or Spell(arcane_explosion)
}

AddFunction ArcaneAoeCdActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsCdActions()
}

AddFunction ArcaneAoeCdPostConditions
{
	DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or Spell(supernova) or DebuffStacks(arcane_charge_debuff) == 4 and Spell(arcane_barrage) or DebuffStacks(arcane_charge_debuff) < 4 and Spell(arcane_orb) or Glyph(glyph_of_cone_of_cold) and Spell(cone_of_cold) or Spell(arcane_explosion)
}

### actions.burn

AddFunction ArcaneBurnMainActions
{
	#arcane_missiles,if=buff.arcane_missiles.react=3
	if BuffStacks(arcane_missiles_buff) == 3 Spell(arcane_missiles)
	#arcane_missiles,if=set_bonus.tier17_4pc&buff.arcane_instability.react&buff.arcane_instability.remains<action.arcane_blast.execute_time
	if ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) Spell(arcane_missiles)
	#supernova,if=time_to_die<8|charges=2
	if target.TimeToDie() < 8 or Charges(supernova) == 2 Spell(supernova)
	#nether_tempest,cycle_targets=1,if=target!=prismatic_crystal&buff.arcane_charge.stack=4&(active_dot.nether_tempest=0|(ticking&remains<3.6))
	if not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } Spell(nether_tempest)
	#arcane_blast,if=buff.arcane_charge.stack=4&mana.pct>93
	if DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 Spell(arcane_blast)
	#arcane_missiles,if=buff.arcane_charge.stack=4&(mana.pct>70|!cooldown.evocation.up)
	if DebuffStacks(arcane_charge_debuff) == 4 and { ManaPercent() > 70 or not { not SpellCooldown(evocation) > 0 } } Spell(arcane_missiles)
	#supernova,if=mana.pct>70&mana.pct<96
	if ManaPercent() > 70 and ManaPercent() < 96 Spell(supernova)
	#call_action_list,name=conserve,if=cooldown.evocation.duration-cooldown.evocation.remains<5
	if SpellCooldownDuration(evocation) - SpellCooldown(evocation) < 5 ArcaneConserveMainActions()
	#arcane_blast
	Spell(arcane_blast)
}

AddFunction ArcaneBurnShortCdActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsShortCdActions()

	unless BuffStacks(arcane_missiles_buff) == 3 and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or { target.TimeToDie() < 8 or Charges(supernova) == 2 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest)
	{
		#arcane_orb,if=buff.arcane_charge.stack<4
		if DebuffStacks(arcane_charge_debuff) < 4 Spell(arcane_orb)
		#presence_of_mind,if=mana.pct>96&(!talent.prismatic_crystal.enabled|!cooldown.prismatic_crystal.up)
		if ManaPercent() > 96 and { not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } } Spell(presence_of_mind)

		unless DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or DebuffStacks(arcane_charge_debuff) == 4 and { ManaPercent() > 70 or not { not SpellCooldown(evocation) > 0 } } and Spell(arcane_missiles) or ManaPercent() > 70 and ManaPercent() < 96 and Spell(supernova)
		{
			#call_action_list,name=conserve,if=cooldown.evocation.duration-cooldown.evocation.remains<5
			if SpellCooldownDuration(evocation) - SpellCooldown(evocation) < 5 ArcaneConserveShortCdActions()

			unless SpellCooldownDuration(evocation) - SpellCooldown(evocation) < 5 and ArcaneConserveShortCdPostConditions()
			{
				#presence_of_mind,if=!talent.prismatic_crystal.enabled|!cooldown.prismatic_crystal.up
				if not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } Spell(presence_of_mind)
			}
		}
	}
}

AddFunction ArcaneBurnShortCdPostConditions
{
	BuffStacks(arcane_missiles_buff) == 3 and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or { target.TimeToDie() < 8 or Charges(supernova) == 2 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or DebuffStacks(arcane_charge_debuff) == 4 and { ManaPercent() > 70 or not { not SpellCooldown(evocation) > 0 } } and Spell(arcane_missiles) or ManaPercent() > 70 and ManaPercent() < 96 and Spell(supernova) or SpellCooldownDuration(evocation) - SpellCooldown(evocation) < 5 and ArcaneConserveShortCdPostConditions() or Spell(arcane_blast)
}

AddFunction ArcaneBurnCdActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsCdActions()

	unless BuffStacks(arcane_missiles_buff) == 3 and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or { target.TimeToDie() < 8 or Charges(supernova) == 2 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) < 4 and Spell(arcane_orb) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or DebuffStacks(arcane_charge_debuff) == 4 and { ManaPercent() > 70 or not { not SpellCooldown(evocation) > 0 } } and Spell(arcane_missiles) or ManaPercent() > 70 and ManaPercent() < 96 and Spell(supernova)
	{
		#call_action_list,name=conserve,if=cooldown.evocation.duration-cooldown.evocation.remains<5
		if SpellCooldownDuration(evocation) - SpellCooldown(evocation) < 5 ArcaneConserveCdActions()

		unless SpellCooldownDuration(evocation) - SpellCooldown(evocation) < 5 and ArcaneConserveCdPostConditions()
		{
			#evocation,interrupt_if=mana.pct>92,if=time_to_die>10&mana.pct<50
			if target.TimeToDie() > 10 and ManaPercent() < 50 Spell(evocation)
		}
	}
}

AddFunction ArcaneBurnCdPostConditions
{
	BuffStacks(arcane_missiles_buff) == 3 and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or { target.TimeToDie() < 8 or Charges(supernova) == 2 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) < 4 and Spell(arcane_orb) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or DebuffStacks(arcane_charge_debuff) == 4 and { ManaPercent() > 70 or not { not SpellCooldown(evocation) > 0 } } and Spell(arcane_missiles) or ManaPercent() > 70 and ManaPercent() < 96 and Spell(supernova) or SpellCooldownDuration(evocation) - SpellCooldown(evocation) < 5 and ArcaneConserveCdPostConditions() or Spell(arcane_blast)
}

### actions.conserve

AddFunction ArcaneConserveMainActions
{
	#arcane_missiles,if=buff.arcane_missiles.react=3|(talent.overpowered.enabled&buff.arcane_power.up&buff.arcane_power.remains<action.arcane_blast.execute_time)
	if BuffStacks(arcane_missiles_buff) == 3 or Talent(overpowered_talent) and BuffPresent(arcane_power_buff) and BuffRemaining(arcane_power_buff) < ExecuteTime(arcane_blast) Spell(arcane_missiles)
	#arcane_missiles,if=set_bonus.tier17_4pc&buff.arcane_instability.react&buff.arcane_instability.remains<action.arcane_blast.execute_time
	if ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) Spell(arcane_missiles)
	#nether_tempest,cycle_targets=1,if=target!=prismatic_crystal&buff.arcane_charge.stack=4&(active_dot.nether_tempest=0|(ticking&remains<3.6))
	if not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } Spell(nether_tempest)
	#supernova,if=time_to_die<8|(charges=2&(buff.arcane_power.up|!cooldown.arcane_power.up)&(!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>8))
	if target.TimeToDie() < 8 or Charges(supernova) == 2 and { BuffPresent(arcane_power_buff) or not { not SpellCooldown(arcane_power) > 0 } } and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 8 } Spell(supernova)
	#arcane_blast,if=buff.arcane_charge.stack=4&mana.pct>93
	if DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 Spell(arcane_blast)
	#arcane_missiles,if=buff.arcane_charge.stack=4&(!talent.overpowered.enabled|cooldown.arcane_power.remains>10*spell_haste)
	if DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(overpowered_talent) or SpellCooldown(arcane_power) > 10 * { 100 / { 100 + SpellHaste() } } } Spell(arcane_missiles)
	#supernova,if=mana.pct<96&(buff.arcane_missiles.stack<2|buff.arcane_charge.stack=4)&(buff.arcane_power.up|(charges=1&cooldown.arcane_power.remains>recharge_time))&(!talent.prismatic_crystal.enabled|current_target=prismatic_crystal|(charges=1&cooldown.prismatic_crystal.remains>recharge_time+8))
	if ManaPercent() < 96 and { BuffStacks(arcane_missiles_buff) < 2 or DebuffStacks(arcane_charge_debuff) == 4 } and { BuffPresent(arcane_power_buff) or Charges(supernova) == 1 and SpellCooldown(arcane_power) > SpellChargeCooldown(supernova) } and { not Talent(prismatic_crystal_talent) or target.Name(prismatic_crystal) or Charges(supernova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(supernova) + 8 } Spell(supernova)
	#nether_tempest,cycle_targets=1,if=target!=prismatic_crystal&buff.arcane_charge.stack=4&(active_dot.nether_tempest=0|(ticking&remains<(10-3*talent.arcane_orb.enabled)*spell_haste))
	if not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < { 10 - 3 * TalentPoints(arcane_orb_talent) } * { 100 / { 100 + SpellHaste() } } } Spell(nether_tempest)
	#arcane_barrage,if=buff.arcane_charge.stack=4
	if DebuffStacks(arcane_charge_debuff) == 4 Spell(arcane_barrage)
	#arcane_blast
	Spell(arcane_blast)
	#arcane_barrage,moving=1
	if Speed() > 0 Spell(arcane_barrage)
}

AddFunction ArcaneConserveShortCdActions
{
	#call_action_list,name=cooldowns,if=time_to_die<30|(buff.arcane_charge.stack=4&(!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>15))
	if target.TimeToDie() < 30 or DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 15 } ArcaneCooldownsShortCdActions()

	unless { BuffStacks(arcane_missiles_buff) == 3 or Talent(overpowered_talent) and BuffPresent(arcane_power_buff) and BuffRemaining(arcane_power_buff) < ExecuteTime(arcane_blast) } and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or { target.TimeToDie() < 8 or Charges(supernova) == 2 and { BuffPresent(arcane_power_buff) or not { not SpellCooldown(arcane_power) > 0 } } and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 8 } } and Spell(supernova)
	{
		#arcane_orb,if=buff.arcane_charge.stack<2
		if DebuffStacks(arcane_charge_debuff) < 2 Spell(arcane_orb)
		#presence_of_mind,if=mana.pct>96&(!talent.prismatic_crystal.enabled|!cooldown.prismatic_crystal.up)
		if ManaPercent() > 96 and { not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } } Spell(presence_of_mind)

		unless DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(overpowered_talent) or SpellCooldown(arcane_power) > 10 * { 100 / { 100 + SpellHaste() } } } and Spell(arcane_missiles) or ManaPercent() < 96 and { BuffStacks(arcane_missiles_buff) < 2 or DebuffStacks(arcane_charge_debuff) == 4 } and { BuffPresent(arcane_power_buff) or Charges(supernova) == 1 and SpellCooldown(arcane_power) > SpellChargeCooldown(supernova) } and { not Talent(prismatic_crystal_talent) or target.Name(prismatic_crystal) or Charges(supernova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(supernova) + 8 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < { 10 - 3 * TalentPoints(arcane_orb_talent) } * { 100 / { 100 + SpellHaste() } } } and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) == 4 and Spell(arcane_barrage)
		{
			#presence_of_mind,if=buff.arcane_charge.stack<2&(!talent.prismatic_crystal.enabled|!cooldown.prismatic_crystal.up)
			if DebuffStacks(arcane_charge_debuff) < 2 and { not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } } Spell(presence_of_mind)
		}
	}
}

AddFunction ArcaneConserveShortCdPostConditions
{
	{ BuffStacks(arcane_missiles_buff) == 3 or Talent(overpowered_talent) and BuffPresent(arcane_power_buff) and BuffRemaining(arcane_power_buff) < ExecuteTime(arcane_blast) } and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or { target.TimeToDie() < 8 or Charges(supernova) == 2 and { BuffPresent(arcane_power_buff) or not { not SpellCooldown(arcane_power) > 0 } } and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 8 } } and Spell(supernova) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(overpowered_talent) or SpellCooldown(arcane_power) > 10 * { 100 / { 100 + SpellHaste() } } } and Spell(arcane_missiles) or ManaPercent() < 96 and { BuffStacks(arcane_missiles_buff) < 2 or DebuffStacks(arcane_charge_debuff) == 4 } and { BuffPresent(arcane_power_buff) or Charges(supernova) == 1 and SpellCooldown(arcane_power) > SpellChargeCooldown(supernova) } and { not Talent(prismatic_crystal_talent) or target.Name(prismatic_crystal) or Charges(supernova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(supernova) + 8 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < { 10 - 3 * TalentPoints(arcane_orb_talent) } * { 100 / { 100 + SpellHaste() } } } and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) == 4 and Spell(arcane_barrage) or Spell(arcane_blast) or Speed() > 0 and Spell(arcane_barrage)
}

AddFunction ArcaneConserveCdActions
{
	#call_action_list,name=cooldowns,if=time_to_die<30|(buff.arcane_charge.stack=4&(!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>15))
	if target.TimeToDie() < 30 or DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 15 } ArcaneCooldownsCdActions()
}

AddFunction ArcaneConserveCdPostConditions
{
	{ BuffStacks(arcane_missiles_buff) == 3 or Talent(overpowered_talent) and BuffPresent(arcane_power_buff) and BuffRemaining(arcane_power_buff) < ExecuteTime(arcane_blast) } and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or { target.TimeToDie() < 8 or Charges(supernova) == 2 and { BuffPresent(arcane_power_buff) or not { not SpellCooldown(arcane_power) > 0 } } and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 8 } } and Spell(supernova) or DebuffStacks(arcane_charge_debuff) < 2 and Spell(arcane_orb) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(overpowered_talent) or SpellCooldown(arcane_power) > 10 * { 100 / { 100 + SpellHaste() } } } and Spell(arcane_missiles) or ManaPercent() < 96 and { BuffStacks(arcane_missiles_buff) < 2 or DebuffStacks(arcane_charge_debuff) == 4 } and { BuffPresent(arcane_power_buff) or Charges(supernova) == 1 and SpellCooldown(arcane_power) > SpellChargeCooldown(supernova) } and { not Talent(prismatic_crystal_talent) or target.Name(prismatic_crystal) or Charges(supernova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(supernova) + 8 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < { 10 - 3 * TalentPoints(arcane_orb_talent) } * { 100 / { 100 + SpellHaste() } } } and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) == 4 and Spell(arcane_barrage) or Spell(arcane_blast) or Speed() > 0 and Spell(arcane_barrage)
}

### actions.cooldowns

AddFunction ArcaneCooldownsShortCdActions
{
	#arcane_power
	Spell(arcane_power)
}

AddFunction ArcaneCooldownsCdActions
{
	#blood_fury
	Spell(blood_fury_sp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#potion,name=draenic_intellect,if=buff.arcane_power.up&(!talent.prismatic_crystal.enabled|pet.prismatic_crystal.active)
	if BuffPresent(arcane_power_buff) and { not Talent(prismatic_crystal_talent) or TotemPresent(prismatic_crystal) } ArcaneUsePotionIntellect()
}

### actions.crystal_sequence

AddFunction ArcaneCrystalSequenceMainActions
{
	#nether_tempest,if=buff.arcane_charge.stack=4&!ticking&pet.prismatic_crystal.remains>8
	if DebuffStacks(arcane_charge_debuff) == 4 and not target.DebuffPresent(nether_tempest_debuff) and TotemRemaining(prismatic_crystal) > 8 Spell(nether_tempest)
	#supernova,if=mana.pct<96
	if ManaPercent() < 96 Spell(supernova)
	#arcane_blast,if=buff.arcane_charge.stack=4&mana.pct>93&pet.prismatic_crystal.remains>cast_time+buff.arcane_missiles.stack*2*spell_haste+action.arcane_missiles.travel_time
	if DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and TotemRemaining(prismatic_crystal) > CastTime(arcane_blast) + BuffStacks(arcane_missiles_buff) * 2 * { 100 / { 100 + SpellHaste() } } + TravelTime(arcane_missiles) Spell(arcane_blast)
	#arcane_missiles,if=pet.prismatic_crystal.remains>2*spell_haste+travel_time
	if TotemRemaining(prismatic_crystal) > 2 * { 100 / { 100 + SpellHaste() } } + TravelTime(arcane_missiles) Spell(arcane_missiles)
	#supernova,if=pet.prismatic_crystal.remains<action.arcane_blast.cast_time
	if TotemRemaining(prismatic_crystal) < CastTime(arcane_blast) Spell(supernova)
	#choose_target,if=pet.prismatic_crystal.remains<action.arcane_blast.cast_time&buff.presence_of_mind.down
	#arcane_blast
	Spell(arcane_blast)
}

AddFunction ArcaneCrystalSequenceShortCdActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsShortCdActions()

	unless DebuffStacks(arcane_charge_debuff) == 4 and not target.DebuffPresent(nether_tempest_debuff) and TotemRemaining(prismatic_crystal) > 8 and Spell(nether_tempest) or ManaPercent() < 96 and Spell(supernova)
	{
		#presence_of_mind,if=cooldown.cold_snap.up|pet.prismatic_crystal.remains<action.arcane_blast.cast_time
		if not SpellCooldown(cold_snap) > 0 or TotemRemaining(prismatic_crystal) < CastTime(arcane_blast) Spell(presence_of_mind)
	}
}

AddFunction ArcaneCrystalSequenceShortCdPostConditions
{
	DebuffStacks(arcane_charge_debuff) == 4 and not target.DebuffPresent(nether_tempest_debuff) and TotemRemaining(prismatic_crystal) > 8 and Spell(nether_tempest) or ManaPercent() < 96 and Spell(supernova) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and TotemRemaining(prismatic_crystal) > CastTime(arcane_blast) + BuffStacks(arcane_missiles_buff) * 2 * { 100 / { 100 + SpellHaste() } } + TravelTime(arcane_missiles) and Spell(arcane_blast) or TotemRemaining(prismatic_crystal) > 2 * { 100 / { 100 + SpellHaste() } } + TravelTime(arcane_missiles) and Spell(arcane_missiles) or TotemRemaining(prismatic_crystal) < CastTime(arcane_blast) and Spell(supernova) or Spell(arcane_blast)
}

AddFunction ArcaneCrystalSequenceCdActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsCdActions()
}

AddFunction ArcaneCrystalSequenceCdPostConditions
{
	DebuffStacks(arcane_charge_debuff) == 4 and not target.DebuffPresent(nether_tempest_debuff) and TotemRemaining(prismatic_crystal) > 8 and Spell(nether_tempest) or ManaPercent() < 96 and Spell(supernova) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and TotemRemaining(prismatic_crystal) > CastTime(arcane_blast) + BuffStacks(arcane_missiles_buff) * 2 * { 100 / { 100 + SpellHaste() } } + TravelTime(arcane_missiles) and Spell(arcane_blast) or TotemRemaining(prismatic_crystal) > 2 * { 100 / { 100 + SpellHaste() } } + TravelTime(arcane_missiles) and Spell(arcane_missiles) or TotemRemaining(prismatic_crystal) < CastTime(arcane_blast) and Spell(supernova) or Spell(arcane_blast)
}

### actions.init_crystal

AddFunction ArcaneInitCrystalMainActions
{
	#call_action_list,name=conserve,if=buff.arcane_charge.stack<4
	if DebuffStacks(arcane_charge_debuff) < 4 ArcaneConserveMainActions()
}

AddFunction ArcaneInitCrystalShortCdActions
{
	#call_action_list,name=conserve,if=buff.arcane_charge.stack<4
	if DebuffStacks(arcane_charge_debuff) < 4 ArcaneConserveShortCdActions()

	unless DebuffStacks(arcane_charge_debuff) < 4 and ArcaneConserveShortCdPostConditions()
	{
		#prismatic_crystal,if=buff.arcane_charge.stack=4&cooldown.arcane_power.remains<0.5
		if DebuffStacks(arcane_charge_debuff) == 4 and SpellCooldown(arcane_power) < 0.5 Spell(prismatic_crystal)
		#prismatic_crystal,if=glyph.arcane_power.enabled&buff.arcane_charge.stack=4&cooldown.arcane_power.remains>75
		if Glyph(glyph_of_arcane_power) and DebuffStacks(arcane_charge_debuff) == 4 and SpellCooldown(arcane_power) > 75 Spell(prismatic_crystal)
	}
}

AddFunction ArcaneInitCrystalShortCdPostConditions
{
	DebuffStacks(arcane_charge_debuff) < 4 and ArcaneConserveShortCdPostConditions()
}

AddFunction ArcaneInitCrystalCdActions
{
	#call_action_list,name=conserve,if=buff.arcane_charge.stack<4
	if DebuffStacks(arcane_charge_debuff) < 4 ArcaneConserveCdActions()
}

AddFunction ArcaneInitCrystalCdPostConditions
{
	DebuffStacks(arcane_charge_debuff) < 4 and ArcaneConserveCdPostConditions() or DebuffStacks(arcane_charge_debuff) == 4 and SpellCooldown(arcane_power) < 0.5 and Spell(prismatic_crystal) or Glyph(glyph_of_arcane_power) and DebuffStacks(arcane_charge_debuff) == 4 and SpellCooldown(arcane_power) > 75 and Spell(prismatic_crystal)
}

### actions.precombat

AddFunction ArcanePrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=sleeper_surprise
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#arcane_blast
	Spell(arcane_blast)
}

AddFunction ArcanePrecombatShortCdActions
{
	unless { BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance)
	{
		#snapshot_stats
		#rune_of_power,if=buff.rune_of_power.remains<150
		if TotemRemaining(rune_of_power) < 150 Spell(rune_of_power)
	}
}

AddFunction ArcanePrecombatShortCdPostConditions
{
	{ BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance) or Spell(arcane_blast)
}

AddFunction ArcanePrecombatCdActions
{
	unless { BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance) or TotemRemaining(rune_of_power) < 150 and Spell(rune_of_power)
	{
		#mirror_image
		Spell(mirror_image)
		#potion,name=draenic_intellect
		ArcaneUsePotionIntellect()
	}
}

AddFunction ArcanePrecombatCdPostConditions
{
	{ BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance) or TotemRemaining(rune_of_power) < 150 and Spell(rune_of_power) or Spell(arcane_blast)
}

###
### Fire
###
# Based on SimulationCraft profile "Mage_Fire_T17M".
#	class=mage
#	spec=fire
#	talents=3003322
#	glyphs=inferno_blast/combustion/dragons_breath

AddCheckBox(opt_interrupt L(interrupt) default specialization=fire)
AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=fire)
AddCheckBox(opt_time_warp SpellName(time_warp) specialization=fire)

AddFunction FireUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction FireInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		Spell(counterspell)
		if not target.Classification(worldboss)
		{
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

### actions.default

AddFunction FireDefaultMainActions
{
	#call_action_list,name=combust_sequence,if=pyro_chain
	if GetState(pyro_chain) > 0 FireCombustSequenceMainActions()
	#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
	if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) FireCrystalSequenceMainActions()
	#call_action_list,name=init_combust,if=!pyro_chain
	if not GetState(pyro_chain) > 0 FireInitCombustMainActions()
	#call_action_list,name=aoe,if=active_enemies>=4
	if Enemies() >= 4 FireAoeMainActions()
	#call_action_list,name=single_target
	FireSingleTargetMainActions()
}

AddFunction FireDefaultShortCdActions
{
	#blink,if=movement.distance>10
	if 0 > 10 Spell(blink)
	#blazing_speed,if=movement.remains>0
	if 0 > 0 Spell(blazing_speed)
	#ice_floes,if=buff.ice_floes.down&(raid_event.movement.distance>0|raid_event.movement.in<action.fireball.cast_time)
	if BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < CastTime(fireball) } Spell(ice_floes)
	#rune_of_power,if=buff.rune_of_power.remains<cast_time
	if TotemRemaining(rune_of_power) < CastTime(rune_of_power) Spell(rune_of_power)
	#call_action_list,name=combust_sequence,if=pyro_chain
	if GetState(pyro_chain) > 0 FireCombustSequenceShortCdActions()

	unless GetState(pyro_chain) > 0 and FireCombustSequenceShortCdPostConditions()
	{
		#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
		if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) FireCrystalSequenceShortCdActions()

		unless Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) and FireCrystalSequenceShortCdPostConditions()
		{
			#call_action_list,name=init_combust,if=!pyro_chain
			if not GetState(pyro_chain) > 0 FireInitCombustShortCdActions()
			#rune_of_power,if=buff.rune_of_power.remains<action.fireball.execute_time+gcd.max&!(buff.heating_up.up&action.fireball.in_flight)
			if TotemRemaining(rune_of_power) < ExecuteTime(fireball) + GCD() and not { BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } Spell(rune_of_power)
			#call_action_list,name=aoe,if=active_enemies>=4
			if Enemies() >= 4 FireAoeShortCdActions()

			unless Enemies() >= 4 and FireAoeShortCdPostConditions()
			{
				#call_action_list,name=single_target
				FireSingleTargetShortCdActions()
			}
		}
	}
}

AddFunction FireDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() FireInterruptActions()

	unless 0 > 10 and Spell(blink)
	{
		#time_warp,if=target.health.pct<25|time>5
		if { target.HealthPercent() < 25 or TimeInCombat() > 5 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)

		unless BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < CastTime(fireball) } and Spell(ice_floes) or TotemRemaining(rune_of_power) < CastTime(rune_of_power) and Spell(rune_of_power)
		{
			#call_action_list,name=combust_sequence,if=pyro_chain
			if GetState(pyro_chain) > 0 FireCombustSequenceCdActions()

			unless GetState(pyro_chain) > 0 and FireCombustSequenceCdPostConditions()
			{
				unless Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) and FireCrystalSequenceCdPostConditions()
				{
					#call_action_list,name=init_combust,if=!pyro_chain
					if not GetState(pyro_chain) > 0 FireInitCombustCdActions()

					unless TotemRemaining(rune_of_power) < ExecuteTime(fireball) + GCD() and not { BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } and Spell(rune_of_power)
					{
						#mirror_image,if=!(buff.heating_up.up&action.fireball.in_flight)
						if not { BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } Spell(mirror_image)
						#call_action_list,name=aoe,if=active_enemies>=4
						if Enemies() >= 4 FireAoeCdActions()
					}
				}
			}
		}
	}
}

### actions.active_talents

AddFunction FireActiveTalentsMainActions
{
	#call_action_list,name=living_bomb,if=talent.living_bomb.enabled
	if Talent(living_bomb_talent) FireLivingBombMainActions()
	#blast_wave,if=(!talent.incanters_flow.enabled|buff.incanters_flow.stack>=4)&(time_to_die<10|!talent.prismatic_crystal.enabled|(charges=1&cooldown.prismatic_crystal.remains>recharge_time)|charges=2|current_target=prismatic_crystal)
	if { not Talent(incanters_flow_talent) or BuffStacks(incanters_flow_buff) >= 4 } and { target.TimeToDie() < 10 or not Talent(prismatic_crystal_talent) or Charges(blast_wave) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(blast_wave) or Charges(blast_wave) == 2 or target.Name(prismatic_crystal) } Spell(blast_wave)
}

AddFunction FireActiveTalentsShortCdActions
{
	#meteor,if=active_enemies>=5|(glyph.combustion.enabled&(!talent.incanters_flow.enabled|buff.incanters_flow.stack+incanters_flow_dir>=4)&cooldown.meteor.duration-cooldown.combustion.remains<10)
	if Enemies() >= 5 or Glyph(glyph_of_combustion) and { not Talent(incanters_flow_talent) or BuffStacks(incanters_flow_buff) + BuffDirection(incanters_flow_buff) >= 4 } and SpellCooldownDuration(meteor) - SpellCooldown(combustion) < 10 Spell(meteor)
}

AddFunction FireActiveTalentsShortCdPostConditions
{
	Talent(living_bomb_talent) and FireLivingBombShortCdPostConditions() or { not Talent(incanters_flow_talent) or BuffStacks(incanters_flow_buff) >= 4 } and { target.TimeToDie() < 10 or not Talent(prismatic_crystal_talent) or Charges(blast_wave) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(blast_wave) or Charges(blast_wave) == 2 or target.Name(prismatic_crystal) } and Spell(blast_wave)
}

AddFunction FireActiveTalentsCdPostConditions
{
	{ Enemies() >= 5 or Glyph(glyph_of_combustion) and { not Talent(incanters_flow_talent) or BuffStacks(incanters_flow_buff) + BuffDirection(incanters_flow_buff) >= 4 } and SpellCooldownDuration(meteor) - SpellCooldown(combustion) < 10 } and Spell(meteor) or Talent(living_bomb_talent) and FireLivingBombCdPostConditions() or { not Talent(incanters_flow_talent) or BuffStacks(incanters_flow_buff) >= 4 } and { target.TimeToDie() < 10 or not Talent(prismatic_crystal_talent) or Charges(blast_wave) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(blast_wave) or Charges(blast_wave) == 2 or target.Name(prismatic_crystal) } and Spell(blast_wave)
}

### actions.aoe

AddFunction FireAoeMainActions
{
	#inferno_blast,cycle_targets=1,if=(dot.combustion.ticking&active_dot.combustion<active_enemies)|(dot.pyroblast.ticking&active_dot.pyroblast<active_enemies)
	if target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(pyroblast_debuff) and DebuffCountOnAny(pyroblast_debuff) < Enemies() Spell(inferno_blast)
	#call_action_list,name=active_talents
	FireActiveTalentsMainActions()
	#pyroblast,if=buff.pyroblast.react|buff.pyromaniac.react
	if BuffPresent(pyroblast_buff) or BuffPresent(pyromaniac_buff) Spell(pyroblast)
	#pyroblast,if=active_dot.pyroblast=0&!in_flight
	if not DebuffCountOnAny(pyroblast_debuff) > 0 and not InFlightToTarget(pyroblast) Spell(pyroblast)
	#flamestrike,if=mana.pct>10&remains<2.4
	if ManaPercent() > 10 and target.DebuffRemaining(flamestrike_debuff) < 2.4 Spell(flamestrike)
}

AddFunction FireAoeShortCdActions
{
	unless { target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(pyroblast_debuff) and DebuffCountOnAny(pyroblast_debuff) < Enemies() } and Spell(inferno_blast)
	{
		#call_action_list,name=active_talents
		FireActiveTalentsShortCdActions()

		unless FireActiveTalentsShortCdPostConditions() or { BuffPresent(pyroblast_buff) or BuffPresent(pyromaniac_buff) } and Spell(pyroblast) or not DebuffCountOnAny(pyroblast_debuff) > 0 and not InFlightToTarget(pyroblast) and Spell(pyroblast)
		{
			#dragons_breath,if=glyph.dragons_breath.enabled
			if Glyph(glyph_of_dragons_breath) Spell(dragons_breath)
		}
	}
}

AddFunction FireAoeShortCdPostConditions
{
	{ target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(pyroblast_debuff) and DebuffCountOnAny(pyroblast_debuff) < Enemies() } and Spell(inferno_blast) or FireActiveTalentsShortCdPostConditions() or { BuffPresent(pyroblast_buff) or BuffPresent(pyromaniac_buff) } and Spell(pyroblast) or not DebuffCountOnAny(pyroblast_debuff) > 0 and not InFlightToTarget(pyroblast) and Spell(pyroblast) or ManaPercent() > 10 and target.DebuffRemaining(flamestrike_debuff) < 2.4 and Spell(flamestrike)
}

AddFunction FireAoeCdActions
{
	unless { target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(pyroblast_debuff) and DebuffCountOnAny(pyroblast_debuff) < Enemies() } and Spell(inferno_blast)
	{
		unless FireActiveTalentsCdPostConditions() or { BuffPresent(pyroblast_buff) or BuffPresent(pyromaniac_buff) } and Spell(pyroblast) or not DebuffCountOnAny(pyroblast_debuff) > 0 and not InFlightToTarget(pyroblast) and Spell(pyroblast)
		{
			#cold_snap,if=glyph.dragons_breath.enabled&!cooldown.dragons_breath.up
			if Glyph(glyph_of_dragons_breath) and not { not SpellCooldown(dragons_breath) > 0 } Spell(cold_snap)
		}
	}
}

### actions.combust_sequence

AddFunction FireCombustSequenceMainActions
{
	#stop_pyro_chain,if=cooldown.combustion.duration-cooldown.combustion.remains<15
	if SpellCooldownDuration(combustion) - SpellCooldown(combustion) < 15 SetState(pyro_chain 0)
	#pyroblast,if=set_bonus.tier17_4pc&buff.pyromaniac.up
	if ArmorSetBonus(T17 4) and BuffPresent(pyromaniac_buff) Spell(pyroblast)
	#inferno_blast,if=set_bonus.tier16_4pc_caster&(buff.pyroblast.up^buff.heating_up.up)
	if ArmorSetBonus(T16_caster 4) and { BuffPresent(pyroblast_buff) xor BuffPresent(heating_up_buff) } Spell(inferno_blast)
	#fireball,if=!dot.ignite.ticking&!in_flight
	if not target.DebuffPresent(ignite_debuff) and not { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } Spell(fireball)
	#pyroblast,if=buff.pyroblast.up
	if BuffPresent(pyroblast_buff) Spell(pyroblast)
	#inferno_blast,if=talent.meteor.enabled&cooldown.meteor.duration-cooldown.meteor.remains<gcd.max*3
	if Talent(meteor_talent) and SpellCooldownDuration(meteor) - SpellCooldown(meteor) < GCD() * 3 Spell(inferno_blast)
}

AddFunction FireCombustSequenceShortCdActions
{
	#stop_pyro_chain,if=cooldown.combustion.duration-cooldown.combustion.remains<15
	if SpellCooldownDuration(combustion) - SpellCooldown(combustion) < 15 SetState(pyro_chain 0)
	#prismatic_crystal
	Spell(prismatic_crystal)
	#meteor
	Spell(meteor)

	unless ArmorSetBonus(T17 4) and BuffPresent(pyromaniac_buff) and Spell(pyroblast) or ArmorSetBonus(T16_caster 4) and { BuffPresent(pyroblast_buff) xor BuffPresent(heating_up_buff) } and Spell(inferno_blast) or not target.DebuffPresent(ignite_debuff) and not { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } and Spell(fireball) or BuffPresent(pyroblast_buff) and Spell(pyroblast) or Talent(meteor_talent) and SpellCooldownDuration(meteor) - SpellCooldown(meteor) < GCD() * 3 and Spell(inferno_blast)
	{
		#combustion
		Spell(combustion)
	}
}

AddFunction FireCombustSequenceShortCdPostConditions
{
	ArmorSetBonus(T17 4) and BuffPresent(pyromaniac_buff) and Spell(pyroblast) or ArmorSetBonus(T16_caster 4) and { BuffPresent(pyroblast_buff) xor BuffPresent(heating_up_buff) } and Spell(inferno_blast) or not target.DebuffPresent(ignite_debuff) and not { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } and Spell(fireball) or BuffPresent(pyroblast_buff) and Spell(pyroblast) or Talent(meteor_talent) and SpellCooldownDuration(meteor) - SpellCooldown(meteor) < GCD() * 3 and Spell(inferno_blast)
}

AddFunction FireCombustSequenceCdActions
{
	#stop_pyro_chain,if=cooldown.combustion.duration-cooldown.combustion.remains<15
	if SpellCooldownDuration(combustion) - SpellCooldown(combustion) < 15 SetState(pyro_chain 0)

	unless Spell(prismatic_crystal)
	{
		#blood_fury
		Spell(blood_fury_sp)
		#berserking
		Spell(berserking)
		#arcane_torrent
		Spell(arcane_torrent_mana)
		#potion,name=draenic_intellect
		FireUsePotionIntellect()
	}
}

AddFunction FireCombustSequenceCdPostConditions
{
	Spell(prismatic_crystal) or Spell(meteor) or ArmorSetBonus(T17 4) and BuffPresent(pyromaniac_buff) and Spell(pyroblast) or ArmorSetBonus(T16_caster 4) and { BuffPresent(pyroblast_buff) xor BuffPresent(heating_up_buff) } and Spell(inferno_blast) or not target.DebuffPresent(ignite_debuff) and not { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } and Spell(fireball) or BuffPresent(pyroblast_buff) and Spell(pyroblast) or Talent(meteor_talent) and SpellCooldownDuration(meteor) - SpellCooldown(meteor) < GCD() * 3 and Spell(inferno_blast)
}

### actions.crystal_sequence

AddFunction FireCrystalSequenceMainActions
{
	#inferno_blast,cycle_targets=1,if=dot.combustion.ticking&active_dot.combustion<active_enemies+1
	if target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() + 1 Spell(inferno_blast)
	#pyroblast,if=execute_time=gcd.max&pet.prismatic_crystal.remains<gcd.max+travel_time&pet.prismatic_crystal.remains>travel_time
	if ExecuteTime(pyroblast) == GCD() and TotemRemaining(prismatic_crystal) < GCD() + TravelTime(pyroblast) and TotemRemaining(prismatic_crystal) > TravelTime(pyroblast) Spell(pyroblast)
	#call_action_list,name=single_target
	FireSingleTargetMainActions()
}

AddFunction FireCrystalSequenceShortCdActions
{
	unless target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() + 1 and Spell(inferno_blast) or ExecuteTime(pyroblast) == GCD() and TotemRemaining(prismatic_crystal) < GCD() + TravelTime(pyroblast) and TotemRemaining(prismatic_crystal) > TravelTime(pyroblast) and Spell(pyroblast)
	{
		#call_action_list,name=single_target
		FireSingleTargetShortCdActions()
	}
}

AddFunction FireCrystalSequenceShortCdPostConditions
{
	target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() + 1 and Spell(inferno_blast) or ExecuteTime(pyroblast) == GCD() and TotemRemaining(prismatic_crystal) < GCD() + TravelTime(pyroblast) and TotemRemaining(prismatic_crystal) > TravelTime(pyroblast) and Spell(pyroblast) or FireSingleTargetShortCdPostConditions()
}

AddFunction FireCrystalSequenceCdPostConditions
{
	target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() + 1 and Spell(inferno_blast) or ExecuteTime(pyroblast) == GCD() and TotemRemaining(prismatic_crystal) < GCD() + TravelTime(pyroblast) and TotemRemaining(prismatic_crystal) > TravelTime(pyroblast) and Spell(pyroblast) or FireSingleTargetCdPostConditions()
}

### actions.init_combust

AddFunction FireInitCombustMainActions
{
	#start_pyro_chain,if=talent.meteor.enabled&cooldown.meteor.up&((cooldown.combustion.remains<gcd.max*3&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(meteor_talent) and not SpellCooldown(meteor) > 0 and { SpellCooldown(combustion) < GCD() * 3 and BuffPresent(pyroblast_buff) and { BuffPresent(heating_up_buff) xor { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up&((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 and { SpellCooldown(combustion) < GCD() * 2 and BuffPresent(pyroblast_buff) and { BuffPresent(heating_up_buff) xor { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=talent.prismatic_crystal.enabled&!glyph.combustion.enabled&cooldown.prismatic_crystal.remains>20&((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(prismatic_crystal_talent) and not Glyph(glyph_of_combustion) and SpellCooldown(prismatic_crystal) > 20 and { SpellCooldown(combustion) < GCD() * 2 and BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=!talent.prismatic_crystal.enabled&!talent.meteor.enabled&((cooldown.combustion.remains<gcd.max*4&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)|(buff.pyromaniac.up&cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*(gcd.max+talent.kindling.enabled)))
	if not Talent(prismatic_crystal_talent) and not Talent(meteor_talent) and { SpellCooldown(combustion) < GCD() * 4 and BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * { GCD() + TalentPoints(kindling_talent) } } SetState(pyro_chain 1)
}

AddFunction FireInitCombustShortCdActions
{
	#start_pyro_chain,if=talent.meteor.enabled&cooldown.meteor.up&((cooldown.combustion.remains<gcd.max*3&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(meteor_talent) and not SpellCooldown(meteor) > 0 and { SpellCooldown(combustion) < GCD() * 3 and BuffPresent(pyroblast_buff) and { BuffPresent(heating_up_buff) xor { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up&((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 and { SpellCooldown(combustion) < GCD() * 2 and BuffPresent(pyroblast_buff) and { BuffPresent(heating_up_buff) xor { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=talent.prismatic_crystal.enabled&!glyph.combustion.enabled&cooldown.prismatic_crystal.remains>20&((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(prismatic_crystal_talent) and not Glyph(glyph_of_combustion) and SpellCooldown(prismatic_crystal) > 20 and { SpellCooldown(combustion) < GCD() * 2 and BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=!talent.prismatic_crystal.enabled&!talent.meteor.enabled&((cooldown.combustion.remains<gcd.max*4&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)|(buff.pyromaniac.up&cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*(gcd.max+talent.kindling.enabled)))
	if not Talent(prismatic_crystal_talent) and not Talent(meteor_talent) and { SpellCooldown(combustion) < GCD() * 4 and BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * { GCD() + TalentPoints(kindling_talent) } } SetState(pyro_chain 1)
}

AddFunction FireInitCombustCdActions
{
	#start_pyro_chain,if=talent.meteor.enabled&cooldown.meteor.up&((cooldown.combustion.remains<gcd.max*3&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(meteor_talent) and not SpellCooldown(meteor) > 0 and { SpellCooldown(combustion) < GCD() * 3 and BuffPresent(pyroblast_buff) and { BuffPresent(heating_up_buff) xor { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up&((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 and { SpellCooldown(combustion) < GCD() * 2 and BuffPresent(pyroblast_buff) and { BuffPresent(heating_up_buff) xor { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=talent.prismatic_crystal.enabled&!glyph.combustion.enabled&cooldown.prismatic_crystal.remains>20&((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(prismatic_crystal_talent) and not Glyph(glyph_of_combustion) and SpellCooldown(prismatic_crystal) > 20 and { SpellCooldown(combustion) < GCD() * 2 and BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=!talent.prismatic_crystal.enabled&!talent.meteor.enabled&((cooldown.combustion.remains<gcd.max*4&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)|(buff.pyromaniac.up&cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*(gcd.max+talent.kindling.enabled)))
	if not Talent(prismatic_crystal_talent) and not Talent(meteor_talent) and { SpellCooldown(combustion) < GCD() * 4 and BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * { GCD() + TalentPoints(kindling_talent) } } SetState(pyro_chain 1)
}

### actions.living_bomb

AddFunction FireLivingBombMainActions
{
	#inferno_blast,cycle_targets=1,if=dot.living_bomb.ticking&active_dot.living_bomb<active_enemies
	if target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) < Enemies() Spell(inferno_blast)
	#living_bomb,cycle_targets=1,if=target!=prismatic_crystal&(active_dot.living_bomb=0|(ticking&active_dot.living_bomb=1))&(((!talent.incanters_flow.enabled|incanters_flow_dir<0|buff.incanters_flow.stack=5)&remains<3.6)|((incanters_flow_dir>0|buff.incanters_flow.stack=1)&remains<gcd.max))&target.time_to_die>remains+12
	if not target.Name(prismatic_crystal) and { not DebuffCountOnAny(living_bomb_debuff) > 0 or target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) == 1 } and { { not Talent(incanters_flow_talent) or BuffDirection(incanters_flow_buff) < 0 or BuffStacks(incanters_flow_buff) == 5 } and target.DebuffRemaining(living_bomb_debuff) < 3.6 or { BuffDirection(incanters_flow_buff) > 0 or BuffStacks(incanters_flow_buff) == 1 } and target.DebuffRemaining(living_bomb_debuff) < GCD() } and target.TimeToDie() > target.DebuffRemaining(living_bomb_debuff) + 12 Spell(living_bomb)
}

AddFunction FireLivingBombShortCdPostConditions
{
	target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) < Enemies() and Spell(inferno_blast) or not target.Name(prismatic_crystal) and { not DebuffCountOnAny(living_bomb_debuff) > 0 or target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) == 1 } and { { not Talent(incanters_flow_talent) or BuffDirection(incanters_flow_buff) < 0 or BuffStacks(incanters_flow_buff) == 5 } and target.DebuffRemaining(living_bomb_debuff) < 3.6 or { BuffDirection(incanters_flow_buff) > 0 or BuffStacks(incanters_flow_buff) == 1 } and target.DebuffRemaining(living_bomb_debuff) < GCD() } and target.TimeToDie() > target.DebuffRemaining(living_bomb_debuff) + 12 and Spell(living_bomb)
}

AddFunction FireLivingBombCdPostConditions
{
	target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) < Enemies() and Spell(inferno_blast) or not target.Name(prismatic_crystal) and { not DebuffCountOnAny(living_bomb_debuff) > 0 or target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) == 1 } and { { not Talent(incanters_flow_talent) or BuffDirection(incanters_flow_buff) < 0 or BuffStacks(incanters_flow_buff) == 5 } and target.DebuffRemaining(living_bomb_debuff) < 3.6 or { BuffDirection(incanters_flow_buff) > 0 or BuffStacks(incanters_flow_buff) == 1 } and target.DebuffRemaining(living_bomb_debuff) < GCD() } and target.TimeToDie() > target.DebuffRemaining(living_bomb_debuff) + 12 and Spell(living_bomb)
}

### actions.precombat

AddFunction FirePrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=blackrock_barbecue
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#pyroblast
	Spell(pyroblast)
}

AddFunction FirePrecombatShortCdActions
{
	unless { BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance)
	{
		#snapshot_stats
		#rune_of_power,if=buff.rune_of_power.remains<150
		if TotemRemaining(rune_of_power) < 150 Spell(rune_of_power)
	}
}

AddFunction FirePrecombatShortCdPostConditions
{
	{ BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance) or Spell(pyroblast)
}

AddFunction FirePrecombatCdActions
{
	unless { BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance) or TotemRemaining(rune_of_power) < 150 and Spell(rune_of_power)
	{
		#mirror_image
		Spell(mirror_image)
		#potion,name=draenic_intellect
		FireUsePotionIntellect()
	}
}

AddFunction FirePrecombatCdPostConditions
{
	{ BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance) or TotemRemaining(rune_of_power) < 150 and Spell(rune_of_power) or Spell(pyroblast)
}

### actions.single_target

AddFunction FireSingleTargetMainActions
{
	#inferno_blast,if=(dot.combustion.ticking&active_dot.combustion<active_enemies)|(dot.living_bomb.ticking&active_dot.living_bomb<active_enemies)
	if target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) < Enemies() Spell(inferno_blast)
	#pyroblast,if=buff.pyroblast.up&buff.pyroblast.remains<action.fireball.execute_time
	if BuffPresent(pyroblast_buff) and BuffRemaining(pyroblast_buff) < ExecuteTime(fireball) Spell(pyroblast)
	#pyroblast,if=set_bonus.tier16_2pc_caster&buff.pyroblast.up&buff.potent_flames.up&buff.potent_flames.remains<gcd.max
	if ArmorSetBonus(T16_caster 2) and BuffPresent(pyroblast_buff) and BuffPresent(potent_flames_buff) and BuffRemaining(potent_flames_buff) < GCD() Spell(pyroblast)
	#pyroblast,if=set_bonus.tier17_4pc&buff.pyromaniac.react
	if ArmorSetBonus(T17 4) and BuffPresent(pyromaniac_buff) Spell(pyroblast)
	#pyroblast,if=buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight
	if BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } Spell(pyroblast)
	#pyroblast,if=set_bonus.tier17_2pc&buff.pyroblast.up&cooldown.combustion.remains>8&action.inferno_blast.charges_fractional>0.85
	if ArmorSetBonus(T17 2) and BuffPresent(pyroblast_buff) and SpellCooldown(combustion) > 8 and Charges(inferno_blast count=0) > 0.85 Spell(pyroblast)
	#inferno_blast,if=buff.pyroblast.down&buff.heating_up.up
	if BuffExpires(pyroblast_buff) and BuffPresent(heating_up_buff) Spell(inferno_blast)
	#call_action_list,name=active_talents
	FireActiveTalentsMainActions()
	#inferno_blast,if=buff.pyroblast.up&buff.heating_up.down&!action.fireball.in_flight
	if BuffPresent(pyroblast_buff) and BuffExpires(heating_up_buff) and not { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } Spell(inferno_blast)
	#inferno_blast,if=set_bonus.tier17_2pc&charges_fractional>1.85
	if ArmorSetBonus(T17 2) and Charges(inferno_blast count=0) > 1.85 Spell(inferno_blast)
	#fireball
	Spell(fireball)
	#scorch,moving=1
	if Speed() > 0 Spell(scorch)
}

AddFunction FireSingleTargetShortCdActions
{
	unless { target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) < Enemies() } and Spell(inferno_blast) or BuffPresent(pyroblast_buff) and BuffRemaining(pyroblast_buff) < ExecuteTime(fireball) and Spell(pyroblast) or ArmorSetBonus(T16_caster 2) and BuffPresent(pyroblast_buff) and BuffPresent(potent_flames_buff) and BuffRemaining(potent_flames_buff) < GCD() and Spell(pyroblast) or ArmorSetBonus(T17 4) and BuffPresent(pyromaniac_buff) and Spell(pyroblast) or BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } and Spell(pyroblast) or ArmorSetBonus(T17 2) and BuffPresent(pyroblast_buff) and SpellCooldown(combustion) > 8 and Charges(inferno_blast count=0) > 0.85 and Spell(pyroblast) or BuffExpires(pyroblast_buff) and BuffPresent(heating_up_buff) and Spell(inferno_blast)
	{
		#call_action_list,name=active_talents
		FireActiveTalentsShortCdActions()
	}
}

AddFunction FireSingleTargetShortCdPostConditions
{
	{ target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) < Enemies() } and Spell(inferno_blast) or BuffPresent(pyroblast_buff) and BuffRemaining(pyroblast_buff) < ExecuteTime(fireball) and Spell(pyroblast) or ArmorSetBonus(T16_caster 2) and BuffPresent(pyroblast_buff) and BuffPresent(potent_flames_buff) and BuffRemaining(potent_flames_buff) < GCD() and Spell(pyroblast) or ArmorSetBonus(T17 4) and BuffPresent(pyromaniac_buff) and Spell(pyroblast) or BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } and Spell(pyroblast) or ArmorSetBonus(T17 2) and BuffPresent(pyroblast_buff) and SpellCooldown(combustion) > 8 and Charges(inferno_blast count=0) > 0.85 and Spell(pyroblast) or BuffExpires(pyroblast_buff) and BuffPresent(heating_up_buff) and Spell(inferno_blast) or FireActiveTalentsShortCdPostConditions() or BuffPresent(pyroblast_buff) and BuffExpires(heating_up_buff) and not { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } and Spell(inferno_blast) or ArmorSetBonus(T17 2) and Charges(inferno_blast count=0) > 1.85 and Spell(inferno_blast) or Spell(fireball) or Speed() > 0 and Spell(scorch)
}

AddFunction FireSingleTargetCdPostConditions
{
	{ target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) < Enemies() } and Spell(inferno_blast) or BuffPresent(pyroblast_buff) and BuffRemaining(pyroblast_buff) < ExecuteTime(fireball) and Spell(pyroblast) or ArmorSetBonus(T16_caster 2) and BuffPresent(pyroblast_buff) and BuffPresent(potent_flames_buff) and BuffRemaining(potent_flames_buff) < GCD() and Spell(pyroblast) or ArmorSetBonus(T17 4) and BuffPresent(pyromaniac_buff) and Spell(pyroblast) or BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } and Spell(pyroblast) or ArmorSetBonus(T17 2) and BuffPresent(pyroblast_buff) and SpellCooldown(combustion) > 8 and Charges(inferno_blast count=0) > 0.85 and Spell(pyroblast) or BuffExpires(pyroblast_buff) and BuffPresent(heating_up_buff) and Spell(inferno_blast) or FireActiveTalentsCdPostConditions() or BuffPresent(pyroblast_buff) and BuffExpires(heating_up_buff) and not { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } and Spell(inferno_blast) or ArmorSetBonus(T17 2) and Charges(inferno_blast count=0) > 1.85 and Spell(inferno_blast) or Spell(fireball) or Speed() > 0 and Spell(scorch)
}

###
### Frost
###
# Based on SimulationCraft profile "Mage_Frost_T17M".
#	class=mage
#	spec=frost
#	talents=3003122
#	glyphs=icy_veins/splitting_ice/cone_of_cold

AddCheckBox(opt_interrupt L(interrupt) default specialization=frost)
AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=frost)
AddCheckBox(opt_time_warp SpellName(time_warp) specialization=frost)

AddFunction FrostUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction FrostInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		Spell(counterspell)
		if not target.Classification(worldboss)
		{
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

### actions.default

AddFunction FrostDefaultMainActions
{
	#call_action_list,name=water_jet,if=prev.water_jet|debuff.water_jet.remains>0
	if PreviousSpell(water_elemental_water_jet) or target.DebuffRemaining(water_elemental_water_jet_debuff) > 0 FrostWaterJetMainActions()
	#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&(cooldown.prismatic_crystal.remains<=gcd.max|pet.prismatic_crystal.active)
	if Talent(prismatic_crystal_talent) and { SpellCooldown(prismatic_crystal) <= GCD() or TotemPresent(prismatic_crystal) } FrostCrystalSequenceMainActions()
	#call_action_list,name=aoe,if=active_enemies>=4
	if Enemies() >= 4 FrostAoeMainActions()
	#call_action_list,name=single_target
	FrostSingleTargetMainActions()
}

AddFunction FrostDefaultShortCdActions
{
	#blink,if=movement.distance>10
	if 0 > 10 Spell(blink)
	#blazing_speed,if=movement.remains>0
	if 0 > 0 Spell(blazing_speed)
	#water_elemental
	if not pet.Present() Spell(water_elemental)
	#call_action_list,name=water_jet,if=prev.water_jet|debuff.water_jet.remains>0
	if PreviousSpell(water_elemental_water_jet) or target.DebuffRemaining(water_elemental_water_jet_debuff) > 0 FrostWaterJetShortCdActions()

	unless { PreviousSpell(water_elemental_water_jet) or target.DebuffRemaining(water_elemental_water_jet_debuff) > 0 } and FrostWaterJetShortCdPostConditions()
	{
		#ice_floes,if=buff.ice_floes.down&(raid_event.movement.distance>0|raid_event.movement.in<action.frostbolt.cast_time)
		if BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < CastTime(frostbolt) } Spell(ice_floes)
		#rune_of_power,if=buff.rune_of_power.remains<cast_time
		if TotemRemaining(rune_of_power) < CastTime(rune_of_power) Spell(rune_of_power)
		#rune_of_power,if=(cooldown.icy_veins.remains<gcd.max&buff.rune_of_power.remains<20)|(cooldown.prismatic_crystal.remains<gcd.max&buff.rune_of_power.remains<10)
		if SpellCooldown(icy_veins) < GCD() and TotemRemaining(rune_of_power) < 20 or SpellCooldown(prismatic_crystal) < GCD() and TotemRemaining(rune_of_power) < 10 Spell(rune_of_power)
		#water_jet,if=time<1&active_enemies<4&!(talent.ice_nova.enabled&talent.prismatic_crystal.enabled)
		if TimeInCombat() < 1 and Enemies() < 4 and not { Talent(ice_nova_talent) and Talent(prismatic_crystal_talent) } Spell(water_elemental_water_jet)
		#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&(cooldown.prismatic_crystal.remains<=gcd.max|pet.prismatic_crystal.active)
		if Talent(prismatic_crystal_talent) and { SpellCooldown(prismatic_crystal) <= GCD() or TotemPresent(prismatic_crystal) } FrostCrystalSequenceShortCdActions()

		unless Talent(prismatic_crystal_talent) and { SpellCooldown(prismatic_crystal) <= GCD() or TotemPresent(prismatic_crystal) } and FrostCrystalSequenceShortCdPostConditions()
		{
			#call_action_list,name=aoe,if=active_enemies>=4
			if Enemies() >= 4 FrostAoeShortCdActions()

			unless Enemies() >= 4 and FrostAoeShortCdPostConditions()
			{
				#call_action_list,name=single_target
				FrostSingleTargetShortCdActions()
			}
		}
	}
}

AddFunction FrostDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() FrostInterruptActions()

	unless 0 > 10 and Spell(blink) or not pet.Present() and Spell(water_elemental)
	{
		#time_warp,if=target.health.pct<25|time>5
		if { target.HealthPercent() < 25 or TimeInCombat() > 5 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)
		#call_action_list,name=water_jet,if=prev.water_jet|debuff.water_jet.remains>0
		if PreviousSpell(water_elemental_water_jet) or target.DebuffRemaining(water_elemental_water_jet_debuff) > 0 FrostWaterJetCdActions()

		unless { PreviousSpell(water_elemental_water_jet) or target.DebuffRemaining(water_elemental_water_jet_debuff) > 0 } and FrostWaterJetCdPostConditions()
		{
			#mirror_image
			Spell(mirror_image)

			unless BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < CastTime(frostbolt) } and Spell(ice_floes) or TotemRemaining(rune_of_power) < CastTime(rune_of_power) and Spell(rune_of_power) or { SpellCooldown(icy_veins) < GCD() and TotemRemaining(rune_of_power) < 20 or SpellCooldown(prismatic_crystal) < GCD() and TotemRemaining(rune_of_power) < 10 } and Spell(rune_of_power)
			{
				#call_action_list,name=cooldowns,if=time_to_die<24
				if target.TimeToDie() < 24 FrostCooldownsCdActions()
				#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&(cooldown.prismatic_crystal.remains<=gcd.max|pet.prismatic_crystal.active)
				if Talent(prismatic_crystal_talent) and { SpellCooldown(prismatic_crystal) <= GCD() or TotemPresent(prismatic_crystal) } FrostCrystalSequenceCdActions()

				unless Talent(prismatic_crystal_talent) and { SpellCooldown(prismatic_crystal) <= GCD() or TotemPresent(prismatic_crystal) } and FrostCrystalSequenceCdPostConditions()
				{
					#call_action_list,name=aoe,if=active_enemies>=4
					if Enemies() >= 4 FrostAoeCdActions()

					unless Enemies() >= 4 and FrostAoeCdPostConditions()
					{
						#call_action_list,name=single_target
						FrostSingleTargetCdActions()
					}
				}
			}
		}
	}
}

### actions.aoe

AddFunction FrostAoeMainActions
{
	#ice_lance,if=talent.frost_bomb.enabled&buff.fingers_of_frost.react&debuff.frost_bomb.up
	if Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and target.DebuffPresent(frost_bomb_debuff) Spell(ice_lance)
	#ice_nova
	Spell(ice_nova)
	#blizzard,interrupt_if=cooldown.frozen_orb.up|(talent.frost_bomb.enabled&buff.fingers_of_frost.react=2)
	Spell(blizzard)
}

AddFunction FrostAoeShortCdActions
{
	#frost_bomb,if=remains<action.ice_lance.travel_time&(cooldown.frozen_orb.remains<gcd.max|buff.fingers_of_frost.react=2)
	if target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and { SpellCooldown(frozen_orb) < GCD() or BuffStacks(fingers_of_frost_buff) == 2 } Spell(frost_bomb)
	#frozen_orb
	Spell(frozen_orb)

	unless Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and target.DebuffPresent(frost_bomb_debuff) and Spell(ice_lance)
	{
		#comet_storm
		Spell(comet_storm)
	}
}

AddFunction FrostAoeShortCdPostConditions
{
	Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and target.DebuffPresent(frost_bomb_debuff) and Spell(ice_lance) or Spell(ice_nova) or Spell(blizzard)
}

AddFunction FrostAoeCdActions
{
	#call_action_list,name=cooldowns
	FrostCooldownsCdActions()
}

AddFunction FrostAoeCdPostConditions
{
	target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and { SpellCooldown(frozen_orb) < GCD() or BuffStacks(fingers_of_frost_buff) == 2 } and Spell(frost_bomb) or Spell(frozen_orb) or Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and target.DebuffPresent(frost_bomb_debuff) and Spell(ice_lance) or Spell(comet_storm) or Spell(ice_nova) or Spell(blizzard)
}

### actions.cooldowns

AddFunction FrostCooldownsCdActions
{
	#icy_veins
	Spell(icy_veins)
	#blood_fury
	Spell(blood_fury_sp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#potion,name=draenic_intellect,if=buff.bloodlust.up|buff.icy_veins.up
	if BuffPresent(burst_haste_buff any=1) or BuffPresent(icy_veins_buff) FrostUsePotionIntellect()
}

### actions.crystal_sequence

AddFunction FrostCrystalSequenceMainActions
{
	#ice_lance,if=buff.fingers_of_frost.react=2|(buff.fingers_of_frost.react&active_dot.frozen_orb>=1)
	if BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and DebuffCountOnAny(frozen_orb_debuff) >= 1 Spell(ice_lance)
	#ice_nova,if=charges=2
	if Charges(ice_nova) == 2 Spell(ice_nova)
	#frostfire_bolt,if=buff.brain_freeze.react
	if BuffPresent(brain_freeze_buff) Spell(frostfire_bolt)
	#ice_lance,if=buff.fingers_of_frost.react
	if BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
	#ice_nova
	Spell(ice_nova)
	#blizzard,interrupt_if=cooldown.frozen_orb.up|(talent.frost_bomb.enabled&buff.fingers_of_frost.react=2),if=active_enemies>=5
	if Enemies() >= 5 Spell(blizzard)
	#frostbolt
	Spell(frostbolt)
}

AddFunction FrostCrystalSequenceShortCdActions
{
	#frost_bomb,if=active_enemies=1&current_target!=prismatic_crystal&remains<10
	if Enemies() == 1 and not target.Name(prismatic_crystal) and target.DebuffRemaining(frost_bomb_debuff) < 10 Spell(frost_bomb)
	#frozen_orb
	Spell(frozen_orb)
	#prismatic_crystal
	Spell(prismatic_crystal)
	#frost_bomb,if=talent.prismatic_crystal.enabled&current_target=prismatic_crystal&active_enemies>1&!ticking
	if Talent(prismatic_crystal_talent) and target.Name(prismatic_crystal) and Enemies() > 1 and not target.DebuffPresent(frost_bomb_debuff) Spell(frost_bomb)
}

AddFunction FrostCrystalSequenceShortCdPostConditions
{
	{ BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and DebuffCountOnAny(frozen_orb_debuff) >= 1 } and Spell(ice_lance) or Charges(ice_nova) == 2 and Spell(ice_nova) or BuffPresent(brain_freeze_buff) and Spell(frostfire_bolt) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ice_nova) or Enemies() >= 5 and Spell(blizzard) or Spell(frostbolt)
}

AddFunction FrostCrystalSequenceCdActions
{
	unless Enemies() == 1 and not target.Name(prismatic_crystal) and target.DebuffRemaining(frost_bomb_debuff) < 10 and Spell(frost_bomb) or Spell(frozen_orb)
	{
		#call_action_list,name=cooldowns
		FrostCooldownsCdActions()
	}
}

AddFunction FrostCrystalSequenceCdPostConditions
{
	Enemies() == 1 and not target.Name(prismatic_crystal) and target.DebuffRemaining(frost_bomb_debuff) < 10 and Spell(frost_bomb) or Spell(frozen_orb) or Spell(prismatic_crystal) or Talent(prismatic_crystal_talent) and target.Name(prismatic_crystal) and Enemies() > 1 and not target.DebuffPresent(frost_bomb_debuff) and Spell(frost_bomb) or { BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and DebuffCountOnAny(frozen_orb_debuff) >= 1 } and Spell(ice_lance) or Charges(ice_nova) == 2 and Spell(ice_nova) or BuffPresent(brain_freeze_buff) and Spell(frostfire_bolt) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ice_nova) or Enemies() >= 5 and Spell(blizzard) or Spell(frostbolt)
}

### actions.init_water_jet

AddFunction FrostInitWaterJetMainActions
{
	#ice_lance,if=buff.fingers_of_frost.react&pet.water_elemental.cooldown.water_jet.up
	if BuffPresent(fingers_of_frost_buff) and not SpellCooldown(water_elemental_water_jet) > 0 Spell(ice_lance)
	#frostbolt
	Spell(frostbolt)
}

AddFunction FrostInitWaterJetShortCdActions
{
	#frost_bomb,if=remains<3.6
	if target.DebuffRemaining(frost_bomb_debuff) < 3.6 Spell(frost_bomb)

	unless BuffPresent(fingers_of_frost_buff) and not SpellCooldown(water_elemental_water_jet) > 0 and Spell(ice_lance)
	{
		#water_jet,if=prev_gcd.frostbolt
		if PreviousGCDSpell(frostbolt) Spell(water_elemental_water_jet)
	}
}

AddFunction FrostInitWaterJetShortCdPostConditions
{
	BuffPresent(fingers_of_frost_buff) and not SpellCooldown(water_elemental_water_jet) > 0 and Spell(ice_lance) or Spell(frostbolt)
}

AddFunction FrostInitWaterJetCdPostConditions
{
	target.DebuffRemaining(frost_bomb_debuff) < 3.6 and Spell(frost_bomb) or BuffPresent(fingers_of_frost_buff) and not SpellCooldown(water_elemental_water_jet) > 0 and Spell(ice_lance) or Spell(frostbolt)
}

### actions.precombat

AddFunction FrostPrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=calamari_crepes
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#frostbolt
	Spell(frostbolt)
}

AddFunction FrostPrecombatShortCdActions
{
	unless { BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance)
	{
		#water_elemental
		if not pet.Present() Spell(water_elemental)
		#snapshot_stats
		#rune_of_power,if=buff.rune_of_power.remains<150
		if TotemRemaining(rune_of_power) < 150 Spell(rune_of_power)
	}
}

AddFunction FrostPrecombatShortCdPostConditions
{
	{ BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance) or Spell(frostbolt)
}

AddFunction FrostPrecombatCdActions
{
	unless { BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance) or not pet.Present() and Spell(water_elemental) or TotemRemaining(rune_of_power) < 150 and Spell(rune_of_power)
	{
		#mirror_image
		Spell(mirror_image)
		#potion,name=draenic_intellect
		FrostUsePotionIntellect()
	}
}

AddFunction FrostPrecombatCdPostConditions
{
	{ BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance) or not pet.Present() and Spell(water_elemental) or TotemRemaining(rune_of_power) < 150 and Spell(rune_of_power) or Spell(frostbolt)
}

### actions.single_target

AddFunction FrostSingleTargetMainActions
{
	#ice_lance,if=buff.fingers_of_frost.react&buff.fingers_of_frost.remains<action.frostbolt.execute_time
	if BuffPresent(fingers_of_frost_buff) and BuffRemaining(fingers_of_frost_buff) < ExecuteTime(frostbolt) Spell(ice_lance)
	#frostfire_bolt,if=buff.brain_freeze.react&buff.brain_freeze.remains<action.frostbolt.execute_time
	if BuffPresent(brain_freeze_buff) and BuffRemaining(brain_freeze_buff) < ExecuteTime(frostbolt) Spell(frostfire_bolt)
	#ice_nova,if=time_to_die<10|(charges=2&(!talent.prismatic_crystal.enabled|!cooldown.prismatic_crystal.up))
	if target.TimeToDie() < 10 or Charges(ice_nova) == 2 and { not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } } Spell(ice_nova)
	#ice_lance,if=buff.fingers_of_frost.react=2|(buff.fingers_of_frost.react&dot.frozen_orb.ticking)
	if BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 Spell(ice_lance)
	#ice_nova,if=(!talent.prismatic_crystal.enabled|(charges=1&cooldown.prismatic_crystal.remains>recharge_time&(buff.incanters_flow.stack>3|!talent.ice_nova.enabled)))&(buff.icy_veins.up|(charges=1&cooldown.icy_veins.remains>recharge_time))
	if { not Talent(prismatic_crystal_talent) or Charges(ice_nova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(ice_nova) and { BuffStacks(incanters_flow_buff) > 3 or not Talent(ice_nova_talent) } } and { BuffPresent(icy_veins_buff) or Charges(ice_nova) == 1 and SpellCooldown(icy_veins) > SpellChargeCooldown(ice_nova) } Spell(ice_nova)
	#frostfire_bolt,if=buff.brain_freeze.react
	if BuffPresent(brain_freeze_buff) Spell(frostfire_bolt)
	#ice_lance,if=set_bonus.tier17_4pc&talent.thermal_void.enabled&talent.mirror_image.enabled&dot.frozen_orb.ticking
	if ArmorSetBonus(T17 4) and Talent(thermal_void_talent) and Talent(mirror_image_talent) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 Spell(ice_lance)
	#ice_lance,if=talent.frost_bomb.enabled&buff.fingers_of_frost.react&debuff.frost_bomb.remains>travel_time&(!talent.thermal_void.enabled|cooldown.icy_veins.remains>8)
	if Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and target.DebuffRemaining(frost_bomb_debuff) > TravelTime(ice_lance) and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins) > 8 } Spell(ice_lance)
	#frostbolt,if=set_bonus.tier17_2pc&buff.ice_shard.up&!(talent.thermal_void.enabled&buff.icy_veins.up&buff.icy_veins.remains<10)
	if ArmorSetBonus(T17 2) and BuffPresent(ice_shard_buff) and not { Talent(thermal_void_talent) and BuffPresent(icy_veins_buff) and BuffRemaining(icy_veins_buff) < 10 } Spell(frostbolt)
	#ice_lance,if=!talent.frost_bomb.enabled&buff.fingers_of_frost.react&(!talent.thermal_void.enabled|cooldown.icy_veins.remains>8)
	if not Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins) > 8 } Spell(ice_lance)
	#call_action_list,name=init_water_jet,if=pet.water_elemental.cooldown.water_jet.remains<=gcd.max*(buff.fingers_of_frost.react+talent.frost_bomb.enabled)&!dot.frozen_orb.ticking
	if SpellCooldown(water_elemental_water_jet) <= GCD() * { BuffStacks(fingers_of_frost_buff) + TalentPoints(frost_bomb_talent) } and not SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 FrostInitWaterJetMainActions()
	#frostbolt
	Spell(frostbolt)
	#ice_lance,moving=1
	if Speed() > 0 Spell(ice_lance)
}

AddFunction FrostSingleTargetShortCdActions
{
	unless BuffPresent(fingers_of_frost_buff) and BuffRemaining(fingers_of_frost_buff) < ExecuteTime(frostbolt) and Spell(ice_lance) or BuffPresent(brain_freeze_buff) and BuffRemaining(brain_freeze_buff) < ExecuteTime(frostbolt) and Spell(frostfire_bolt)
	{
		#frost_bomb,if=!talent.prismatic_crystal.enabled&cooldown.frozen_orb.remains<gcd.max&debuff.frost_bomb.remains<10
		if not Talent(prismatic_crystal_talent) and SpellCooldown(frozen_orb) < GCD() and target.DebuffRemaining(frost_bomb_debuff) < 10 Spell(frost_bomb)
		#frozen_orb,if=!talent.prismatic_crystal.enabled&buff.fingers_of_frost.stack<2&cooldown.icy_veins.remains>45
		if not Talent(prismatic_crystal_talent) and BuffStacks(fingers_of_frost_buff) < 2 and SpellCooldown(icy_veins) > 45 Spell(frozen_orb)
		#frost_bomb,if=remains<action.ice_lance.travel_time&(buff.fingers_of_frost.react=2|(buff.fingers_of_frost.react&(talent.thermal_void.enabled|buff.fingers_of_frost.remains<gcd.max*2)))
		if target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and { BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and { Talent(thermal_void_talent) or BuffRemaining(fingers_of_frost_buff) < GCD() * 2 } } Spell(frost_bomb)

		unless { target.TimeToDie() < 10 or Charges(ice_nova) == 2 and { not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } } } and Spell(ice_nova) or { BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 } and Spell(ice_lance)
		{
			#comet_storm
			Spell(comet_storm)

			unless { not Talent(prismatic_crystal_talent) or Charges(ice_nova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(ice_nova) and { BuffStacks(incanters_flow_buff) > 3 or not Talent(ice_nova_talent) } } and { BuffPresent(icy_veins_buff) or Charges(ice_nova) == 1 and SpellCooldown(icy_veins) > SpellChargeCooldown(ice_nova) } and Spell(ice_nova) or BuffPresent(brain_freeze_buff) and Spell(frostfire_bolt) or ArmorSetBonus(T17 4) and Talent(thermal_void_talent) and Talent(mirror_image_talent) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 and Spell(ice_lance) or Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and target.DebuffRemaining(frost_bomb_debuff) > TravelTime(ice_lance) and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins) > 8 } and Spell(ice_lance) or ArmorSetBonus(T17 2) and BuffPresent(ice_shard_buff) and not { Talent(thermal_void_talent) and BuffPresent(icy_veins_buff) and BuffRemaining(icy_veins_buff) < 10 } and Spell(frostbolt) or not Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins) > 8 } and Spell(ice_lance)
			{
				#call_action_list,name=init_water_jet,if=pet.water_elemental.cooldown.water_jet.remains<=gcd.max*(buff.fingers_of_frost.react+talent.frost_bomb.enabled)&!dot.frozen_orb.ticking
				if SpellCooldown(water_elemental_water_jet) <= GCD() * { BuffStacks(fingers_of_frost_buff) + TalentPoints(frost_bomb_talent) } and not SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 FrostInitWaterJetShortCdActions()
			}
		}
	}
}

AddFunction FrostSingleTargetShortCdPostConditions
{
	BuffPresent(fingers_of_frost_buff) and BuffRemaining(fingers_of_frost_buff) < ExecuteTime(frostbolt) and Spell(ice_lance) or BuffPresent(brain_freeze_buff) and BuffRemaining(brain_freeze_buff) < ExecuteTime(frostbolt) and Spell(frostfire_bolt) or { target.TimeToDie() < 10 or Charges(ice_nova) == 2 and { not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } } } and Spell(ice_nova) or { BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 } and Spell(ice_lance) or { not Talent(prismatic_crystal_talent) or Charges(ice_nova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(ice_nova) and { BuffStacks(incanters_flow_buff) > 3 or not Talent(ice_nova_talent) } } and { BuffPresent(icy_veins_buff) or Charges(ice_nova) == 1 and SpellCooldown(icy_veins) > SpellChargeCooldown(ice_nova) } and Spell(ice_nova) or BuffPresent(brain_freeze_buff) and Spell(frostfire_bolt) or ArmorSetBonus(T17 4) and Talent(thermal_void_talent) and Talent(mirror_image_talent) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 and Spell(ice_lance) or Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and target.DebuffRemaining(frost_bomb_debuff) > TravelTime(ice_lance) and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins) > 8 } and Spell(ice_lance) or ArmorSetBonus(T17 2) and BuffPresent(ice_shard_buff) and not { Talent(thermal_void_talent) and BuffPresent(icy_veins_buff) and BuffRemaining(icy_veins_buff) < 10 } and Spell(frostbolt) or not Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins) > 8 } and Spell(ice_lance) or SpellCooldown(water_elemental_water_jet) <= GCD() * { BuffStacks(fingers_of_frost_buff) + TalentPoints(frost_bomb_talent) } and not SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 and FrostInitWaterJetShortCdPostConditions() or Spell(frostbolt) or Speed() > 0 and Spell(ice_lance)
}

AddFunction FrostSingleTargetCdActions
{
	#call_action_list,name=cooldowns,if=!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>15
	if not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 15 FrostCooldownsCdActions()
}

AddFunction FrostSingleTargetCdPostConditions
{
	BuffPresent(fingers_of_frost_buff) and BuffRemaining(fingers_of_frost_buff) < ExecuteTime(frostbolt) and Spell(ice_lance) or BuffPresent(brain_freeze_buff) and BuffRemaining(brain_freeze_buff) < ExecuteTime(frostbolt) and Spell(frostfire_bolt) or not Talent(prismatic_crystal_talent) and SpellCooldown(frozen_orb) < GCD() and target.DebuffRemaining(frost_bomb_debuff) < 10 and Spell(frost_bomb) or not Talent(prismatic_crystal_talent) and BuffStacks(fingers_of_frost_buff) < 2 and SpellCooldown(icy_veins) > 45 and Spell(frozen_orb) or target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and { BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and { Talent(thermal_void_talent) or BuffRemaining(fingers_of_frost_buff) < GCD() * 2 } } and Spell(frost_bomb) or { target.TimeToDie() < 10 or Charges(ice_nova) == 2 and { not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } } } and Spell(ice_nova) or { BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 } and Spell(ice_lance) or Spell(comet_storm) or { not Talent(prismatic_crystal_talent) or Charges(ice_nova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(ice_nova) and { BuffStacks(incanters_flow_buff) > 3 or not Talent(ice_nova_talent) } } and { BuffPresent(icy_veins_buff) or Charges(ice_nova) == 1 and SpellCooldown(icy_veins) > SpellChargeCooldown(ice_nova) } and Spell(ice_nova) or BuffPresent(brain_freeze_buff) and Spell(frostfire_bolt) or ArmorSetBonus(T17 4) and Talent(thermal_void_talent) and Talent(mirror_image_talent) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 and Spell(ice_lance) or Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and target.DebuffRemaining(frost_bomb_debuff) > TravelTime(ice_lance) and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins) > 8 } and Spell(ice_lance) or ArmorSetBonus(T17 2) and BuffPresent(ice_shard_buff) and not { Talent(thermal_void_talent) and BuffPresent(icy_veins_buff) and BuffRemaining(icy_veins_buff) < 10 } and Spell(frostbolt) or not Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins) > 8 } and Spell(ice_lance) or SpellCooldown(water_elemental_water_jet) <= GCD() * { BuffStacks(fingers_of_frost_buff) + TalentPoints(frost_bomb_talent) } and not SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 and FrostInitWaterJetCdPostConditions() or Spell(frostbolt) or Speed() > 0 and Spell(ice_lance)
}

### actions.water_jet

AddFunction FrostWaterJetMainActions
{
	#frostbolt,if=prev.water_jet
	if PreviousSpell(water_elemental_water_jet) Spell(frostbolt)
	#ice_lance,if=buff.fingers_of_frost.react=2&action.frostbolt.in_flight
	if BuffStacks(fingers_of_frost_buff) == 2 and InFlightToTarget(frostbolt) Spell(ice_lance)
	#frostbolt,if=debuff.water_jet.remains>cast_time+travel_time
	if target.DebuffRemaining(water_elemental_water_jet_debuff) > CastTime(frostbolt) + TravelTime(frostbolt) Spell(frostbolt)
	#ice_lance,if=prev_gcd.frostbolt
	if PreviousGCDSpell(frostbolt) Spell(ice_lance)
	#call_action_list,name=single_target
	FrostSingleTargetMainActions()
}

AddFunction FrostWaterJetShortCdActions
{
	unless PreviousSpell(water_elemental_water_jet) and Spell(frostbolt) or BuffStacks(fingers_of_frost_buff) == 2 and InFlightToTarget(frostbolt) and Spell(ice_lance) or target.DebuffRemaining(water_elemental_water_jet_debuff) > CastTime(frostbolt) + TravelTime(frostbolt) and Spell(frostbolt) or PreviousGCDSpell(frostbolt) and Spell(ice_lance)
	{
		#call_action_list,name=single_target
		FrostSingleTargetShortCdActions()
	}
}

AddFunction FrostWaterJetShortCdPostConditions
{
	PreviousSpell(water_elemental_water_jet) and Spell(frostbolt) or BuffStacks(fingers_of_frost_buff) == 2 and InFlightToTarget(frostbolt) and Spell(ice_lance) or target.DebuffRemaining(water_elemental_water_jet_debuff) > CastTime(frostbolt) + TravelTime(frostbolt) and Spell(frostbolt) or PreviousGCDSpell(frostbolt) and Spell(ice_lance) or FrostSingleTargetShortCdPostConditions()
}

AddFunction FrostWaterJetCdActions
{
	unless PreviousSpell(water_elemental_water_jet) and Spell(frostbolt) or BuffStacks(fingers_of_frost_buff) == 2 and InFlightToTarget(frostbolt) and Spell(ice_lance) or target.DebuffRemaining(water_elemental_water_jet_debuff) > CastTime(frostbolt) + TravelTime(frostbolt) and Spell(frostbolt) or PreviousGCDSpell(frostbolt) and Spell(ice_lance)
	{
		#call_action_list,name=single_target
		FrostSingleTargetCdActions()
	}
}

AddFunction FrostWaterJetCdPostConditions
{
	PreviousSpell(water_elemental_water_jet) and Spell(frostbolt) or BuffStacks(fingers_of_frost_buff) == 2 and InFlightToTarget(frostbolt) and Spell(ice_lance) or target.DebuffRemaining(water_elemental_water_jet_debuff) > CastTime(frostbolt) + TravelTime(frostbolt) and Spell(frostbolt) or PreviousGCDSpell(frostbolt) and Spell(ice_lance) or FrostSingleTargetCdPostConditions()
}
]]
	OvaleScripts:RegisterScript("MAGE", name, desc, code, "include")
end

do
	local name = "Ovale"	-- The default script.
	local desc = "[6.0] Ovale: Arcane, Fire, Frost"
	local code = [[
# Ovale mage script based on SimulationCraft.

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)
Include(ovale_mage)

### Arcane icons.

AddCheckBox(opt_mage_arcane_aoe L(AOE) default specialization=arcane)

AddIcon checkbox=!opt_mage_arcane_aoe enemies=1 help=shortcd specialization=arcane
{
	if not InCombat() ArcanePrecombatShortCdActions()
	unless not InCombat() and ArcanePrecombatShortCdPostConditions()
	{
		ArcaneDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_mage_arcane_aoe help=shortcd specialization=arcane
{
	if not InCombat() ArcanePrecombatShortCdActions()
	unless not InCombat() and ArcanePrecombatShortCdPostConditions()
	{
		ArcaneDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=arcane
{
	if not InCombat() ArcanePrecombatMainActions()
	ArcaneDefaultMainActions()
}

AddIcon checkbox=opt_mage_arcane_aoe help=aoe specialization=arcane
{
	if not InCombat() ArcanePrecombatMainActions()
	ArcaneDefaultMainActions()
}

AddIcon checkbox=!opt_mage_arcane_aoe enemies=1 help=cd specialization=arcane
{
	if not InCombat() ArcanePrecombatCdActions()
	unless not InCombat() and ArcanePrecombatCdPostConditions()
	{
		ArcaneDefaultCdActions()
	}
}

AddIcon checkbox=opt_mage_arcane_aoe help=cd specialization=arcane
{
	if not InCombat() ArcanePrecombatCdActions()
	unless not InCombat() and ArcanePrecombatCdPostConditions()
	{
		ArcaneDefaultCdActions()
	}
}

### Fire icons.

AddCheckBox(opt_mage_fire_aoe L(AOE) default specialization=fire)

AddIcon checkbox=!opt_mage_fire_aoe enemies=1 help=shortcd specialization=fire
{
	if not InCombat() FirePrecombatShortCdActions()
	unless not InCombat() and FirePrecombatShortCdPostConditions()
	{
		FireDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_mage_fire_aoe help=shortcd specialization=fire
{
	if not InCombat() FirePrecombatShortCdActions()
	unless not InCombat() and FirePrecombatShortCdPostConditions()
	{
		FireDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=fire
{
	if not InCombat() FirePrecombatMainActions()
	FireDefaultMainActions()
}

AddIcon checkbox=opt_mage_fire_aoe help=aoe specialization=fire
{
	if not InCombat() FirePrecombatMainActions()
	FireDefaultMainActions()
}

AddIcon checkbox=!opt_mage_fire_aoe enemies=1 help=cd specialization=fire
{
	if not InCombat() FirePrecombatCdActions()
	unless not InCombat() and FirePrecombatCdPostConditions()
	{
		FireDefaultCdActions()
	}
}

AddIcon checkbox=opt_mage_fire_aoe help=cd specialization=fire
{
	if not InCombat() FirePrecombatCdActions()
	unless not InCombat() and FirePrecombatCdPostConditions()
	{
		FireDefaultCdActions()
	}
}

### Frost icons.

AddCheckBox(opt_mage_frost_aoe L(AOE) default specialization=frost)

AddIcon checkbox=!opt_mage_frost_aoe enemies=1 help=shortcd specialization=frost
{
	if not InCombat() FrostPrecombatShortCdActions()
	unless not InCombat() and FrostPrecombatShortCdPostConditions()
	{
		FrostDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_mage_frost_aoe help=shortcd specialization=frost
{
	if not InCombat() FrostPrecombatShortCdActions()
	unless not InCombat() and FrostPrecombatShortCdPostConditions()
	{
		FrostDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=frost
{
	if not InCombat() FrostPrecombatMainActions()
	FrostDefaultMainActions()
}

AddIcon checkbox=opt_mage_frost_aoe help=aoe specialization=frost
{
	if not InCombat() FrostPrecombatMainActions()
	FrostDefaultMainActions()
}

AddIcon checkbox=!opt_mage_frost_aoe enemies=1 help=cd specialization=frost
{
	if not InCombat() FrostPrecombatCdActions()
	unless not InCombat() and FrostPrecombatCdPostConditions()
	{
		FrostDefaultCdActions()
	}
}

AddIcon checkbox=opt_mage_frost_aoe help=cd specialization=frost
{
	if not InCombat() FrostPrecombatCdActions()
	unless not InCombat() and FrostPrecombatCdPostConditions()
	{
		FrostDefaultCdActions()
	}
}
]]
	OvaleScripts:RegisterScript("MAGE", name, desc, code, "script")
end
