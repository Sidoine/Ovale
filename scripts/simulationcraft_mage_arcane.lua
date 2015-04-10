local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_mage_arcane_t17m"
	local desc = "[6.1] SimulationCraft: Mage_Arcane_T17M"
	local code = [[
# Based on SimulationCraft profile "Mage_Arcane_T17M".
#	class=mage
#	spec=arcane
#	talents=3003322
#	glyphs=cone_of_cold

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)

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
	#stop_burn_phase,if=prev_gcd.evocation&burn_phase_duration>gcd.max
	if PreviousGCDSpell(evocation) and GetStateDuration(burn_phase) > GCD() and GetState(burn_phase) > 0 SetState(burn_phase 0)
	#call_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 ArcaneAoeMainActions()
	#call_action_list,name=init_burn,if=!burn_phase
	if not GetState(burn_phase) > 0 and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneInitBurnMainActions()
	#call_action_list,name=burn,if=burn_phase
	if GetState(burn_phase) > 0 and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnMainActions()
	#call_action_list,name=conserve
	ArcaneConserveMainActions()
}

AddFunction ArcaneDefaultShortCdActions
{
	#stop_burn_phase,if=prev_gcd.evocation&burn_phase_duration>gcd.max
	if PreviousGCDSpell(evocation) and GetStateDuration(burn_phase) > GCD() and GetState(burn_phase) > 0 SetState(burn_phase 0)
	#blink,if=movement.distance>10
	if 0 > 10 Spell(blink)
	#blazing_speed,if=movement.remains>0
	if 0 > 0 Spell(blazing_speed)
	#ice_floes,if=buff.ice_floes.down&(raid_event.movement.distance>0|raid_event.movement.in<2*spell_haste)
	if BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < 2 * { 100 / { 100 + SpellHaste() } } } Spell(ice_floes)
	#rune_of_power,if=buff.rune_of_power.remains<2*spell_haste
	if TotemRemaining(rune_of_power) < 2 * { 100 / { 100 + SpellHaste() } } Spell(rune_of_power)
	#call_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 ArcaneAoeShortCdActions()

	unless Enemies() >= 5 and ArcaneAoeShortCdPostConditions()
	{
		#call_action_list,name=init_burn,if=!burn_phase
		if not GetState(burn_phase) > 0 and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneInitBurnShortCdActions()
		#call_action_list,name=burn,if=burn_phase
		if GetState(burn_phase) > 0 and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnShortCdActions()

		unless GetState(burn_phase) > 0 and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnShortCdPostConditions()
		{
			#call_action_list,name=conserve
			ArcaneConserveShortCdActions()
		}
	}
}

AddFunction ArcaneDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() ArcaneInterruptActions()
	#stop_burn_phase,if=prev_gcd.evocation&burn_phase_duration>gcd.max
	if PreviousGCDSpell(evocation) and GetStateDuration(burn_phase) > GCD() and GetState(burn_phase) > 0 SetState(burn_phase 0)

	unless 0 > 10 and Spell(blink)
	{
		#cold_snap,if=health.pct<30
		if HealthPercent() < 30 Spell(cold_snap)
		#time_warp,if=target.health.pct<25|time>5
		if { target.HealthPercent() < 25 or TimeInCombat() > 5 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)

		unless BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < 2 * { 100 / { 100 + SpellHaste() } } } and Spell(ice_floes) or TotemRemaining(rune_of_power) < 2 * { 100 / { 100 + SpellHaste() } } and Spell(rune_of_power)
		{
			#mirror_image
			Spell(mirror_image)
			#cold_snap,if=buff.presence_of_mind.down&cooldown.presence_of_mind.remains>75
			if BuffExpires(presence_of_mind_buff) and SpellCooldown(presence_of_mind) > 75 Spell(cold_snap)
			#call_action_list,name=aoe,if=active_enemies>=5
			if Enemies() >= 5 ArcaneAoeCdActions()

			unless Enemies() >= 5 and ArcaneAoeCdPostConditions()
			{
				#call_action_list,name=init_burn,if=!burn_phase
				if not GetState(burn_phase) > 0 and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneInitBurnCdActions()
				#call_action_list,name=burn,if=burn_phase
				if GetState(burn_phase) > 0 and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnCdActions()

				unless GetState(burn_phase) > 0 and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnCdPostConditions()
				{
					#call_action_list,name=conserve
					ArcaneConserveCdActions()
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
	#arcane_explosion,if=prev_gcd.evocation
	if PreviousGCDSpell(evocation) Spell(arcane_explosion)
	#arcane_missiles,if=set_bonus.tier17_4pc&active_enemies<10&buff.arcane_charge.stack=4&buff.arcane_instability.react
	if ArmorSetBonus(T17 4) and Enemies() < 10 and DebuffStacks(arcane_charge_debuff) == 4 and BuffPresent(arcane_instability_buff) Spell(arcane_missiles)
	#nether_tempest,cycle_targets=1,if=talent.arcane_orb.enabled&buff.arcane_charge.stack=4&ticking&remains<cooldown.arcane_orb.remains
	if Talent(arcane_orb_talent) and DebuffStacks(arcane_charge_debuff) == 4 and target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < SpellCooldown(arcane_orb) Spell(nether_tempest)
	#arcane_barrage,if=buff.arcane_charge.stack=4
	if DebuffStacks(arcane_charge_debuff) == 4 Spell(arcane_barrage)
	#arcane_explosion
	Spell(arcane_explosion)
}

AddFunction ArcaneAoeShortCdActions
{
	unless DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or Spell(supernova)
	{
		#arcane_orb,if=buff.arcane_charge.stack<4
		if DebuffStacks(arcane_charge_debuff) < 4 Spell(arcane_orb)

		unless PreviousGCDSpell(evocation) and Spell(arcane_explosion) or ArmorSetBonus(T17 4) and Enemies() < 10 and DebuffStacks(arcane_charge_debuff) == 4 and BuffPresent(arcane_instability_buff) and Spell(arcane_missiles) or Talent(arcane_orb_talent) and DebuffStacks(arcane_charge_debuff) == 4 and target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < SpellCooldown(arcane_orb) and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) == 4 and Spell(arcane_barrage)
		{
			#cone_of_cold,if=glyph.cone_of_cold.enabled
			if Glyph(glyph_of_cone_of_cold) Spell(cone_of_cold)
		}
	}
}

AddFunction ArcaneAoeShortCdPostConditions
{
	DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or Spell(supernova) or PreviousGCDSpell(evocation) and Spell(arcane_explosion) or ArmorSetBonus(T17 4) and Enemies() < 10 and DebuffStacks(arcane_charge_debuff) == 4 and BuffPresent(arcane_instability_buff) and Spell(arcane_missiles) or Talent(arcane_orb_talent) and DebuffStacks(arcane_charge_debuff) == 4 and target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < SpellCooldown(arcane_orb) and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) == 4 and Spell(arcane_barrage) or Spell(arcane_explosion)
}

AddFunction ArcaneAoeCdActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsCdActions()

	unless DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or Spell(supernova) or DebuffStacks(arcane_charge_debuff) < 4 and Spell(arcane_orb) or PreviousGCDSpell(evocation) and Spell(arcane_explosion)
	{
		#evocation,interrupt_if=mana.pct>96,if=mana.pct<85-2.5*buff.arcane_charge.stack
		if ManaPercent() < 85 - 2.5 * DebuffStacks(arcane_charge_debuff) Spell(evocation)
	}
}

AddFunction ArcaneAoeCdPostConditions
{
	DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or Spell(supernova) or DebuffStacks(arcane_charge_debuff) < 4 and Spell(arcane_orb) or PreviousGCDSpell(evocation) and Spell(arcane_explosion) or ArmorSetBonus(T17 4) and Enemies() < 10 and DebuffStacks(arcane_charge_debuff) == 4 and BuffPresent(arcane_instability_buff) and Spell(arcane_missiles) or Talent(arcane_orb_talent) and DebuffStacks(arcane_charge_debuff) == 4 and target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < SpellCooldown(arcane_orb) and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) == 4 and Spell(arcane_barrage) or Glyph(glyph_of_cone_of_cold) and Spell(cone_of_cold) or Spell(arcane_explosion)
}

### actions.burn

AddFunction ArcaneBurnMainActions
{
	#call_action_list,name=init_crystal,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up
	if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 ArcaneInitCrystalMainActions()
	#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
	if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) ArcaneCrystalSequenceMainActions()
	#arcane_missiles,if=buff.arcane_missiles.react=3
	if BuffStacks(arcane_missiles_buff) == 3 Spell(arcane_missiles)
	#arcane_missiles,if=set_bonus.tier17_4pc&buff.arcane_instability.react&buff.arcane_instability.remains<action.arcane_blast.execute_time
	if ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) Spell(arcane_missiles)
	#supernova,if=target.time_to_die<8|charges=2
	if target.TimeToDie() < 8 or Charges(supernova) == 2 Spell(supernova)
	#nether_tempest,cycle_targets=1,if=target!=prismatic_crystal&buff.arcane_charge.stack=4&(active_dot.nether_tempest=0|(ticking&remains<3.6))
	if not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } Spell(nether_tempest)
	#arcane_barrage,if=talent.arcane_orb.enabled&active_enemies>=3&buff.arcane_charge.stack=4&(cooldown.arcane_orb.remains<gcd.max|prev_gcd.arcane_orb)
	if Talent(arcane_orb_talent) and Enemies() >= 3 and DebuffStacks(arcane_charge_debuff) == 4 and { SpellCooldown(arcane_orb) < GCD() or PreviousGCDSpell(arcane_orb) } Spell(arcane_barrage)
	#arcane_blast,if=buff.arcane_charge.stack=4&mana.pct>93
	if DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 Spell(arcane_blast)
	#arcane_missiles,if=buff.arcane_charge.stack=4&(mana.pct>70|!cooldown.evocation.up|target.time_to_die<15)
	if DebuffStacks(arcane_charge_debuff) == 4 and { ManaPercent() > 70 or not { not SpellCooldown(evocation) > 0 } or target.TimeToDie() < 15 } Spell(arcane_missiles)
	#supernova,if=mana.pct>70&mana.pct<96
	if ManaPercent() > 70 and ManaPercent() < 96 Spell(supernova)
	#arcane_blast
	Spell(arcane_blast)
}

AddFunction ArcaneBurnShortCdActions
{
	#call_action_list,name=init_crystal,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up
	if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 ArcaneInitCrystalShortCdActions()

	unless Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 and ArcaneInitCrystalShortCdPostConditions()
	{
		#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
		if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) ArcaneCrystalSequenceShortCdActions()

		unless Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) and ArcaneCrystalSequenceShortCdPostConditions()
		{
			unless BuffStacks(arcane_missiles_buff) == 3 and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or { target.TimeToDie() < 8 or Charges(supernova) == 2 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest)
			{
				#arcane_orb,if=buff.arcane_charge.stack<4
				if DebuffStacks(arcane_charge_debuff) < 4 Spell(arcane_orb)

				unless Talent(arcane_orb_talent) and Enemies() >= 3 and DebuffStacks(arcane_charge_debuff) == 4 and { SpellCooldown(arcane_orb) < GCD() or PreviousGCDSpell(arcane_orb) } and Spell(arcane_barrage)
				{
					#presence_of_mind,if=mana.pct>96&(!talent.prismatic_crystal.enabled|!cooldown.prismatic_crystal.up)
					if ManaPercent() > 96 and { not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } } Spell(presence_of_mind)

					unless DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or DebuffStacks(arcane_charge_debuff) == 4 and { ManaPercent() > 70 or not { not SpellCooldown(evocation) > 0 } or target.TimeToDie() < 15 } and Spell(arcane_missiles) or ManaPercent() > 70 and ManaPercent() < 96 and Spell(supernova)
					{
						#presence_of_mind,if=!talent.prismatic_crystal.enabled|!cooldown.prismatic_crystal.up
						if not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } Spell(presence_of_mind)
					}
				}
			}
		}
	}
}

AddFunction ArcaneBurnShortCdPostConditions
{
	Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 and ArcaneInitCrystalShortCdPostConditions() or Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) and ArcaneCrystalSequenceShortCdPostConditions() or BuffStacks(arcane_missiles_buff) == 3 and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or { target.TimeToDie() < 8 or Charges(supernova) == 2 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or Talent(arcane_orb_talent) and Enemies() >= 3 and DebuffStacks(arcane_charge_debuff) == 4 and { SpellCooldown(arcane_orb) < GCD() or PreviousGCDSpell(arcane_orb) } and Spell(arcane_barrage) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or DebuffStacks(arcane_charge_debuff) == 4 and { ManaPercent() > 70 or not { not SpellCooldown(evocation) > 0 } or target.TimeToDie() < 15 } and Spell(arcane_missiles) or ManaPercent() > 70 and ManaPercent() < 96 and Spell(supernova) or Spell(arcane_blast)
}

AddFunction ArcaneBurnCdActions
{
	#call_action_list,name=init_crystal,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up
	if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 ArcaneInitCrystalCdActions()

	unless Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 and ArcaneInitCrystalCdPostConditions()
	{
		#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
		if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) ArcaneCrystalSequenceCdActions()

		unless Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) and ArcaneCrystalSequenceCdPostConditions()
		{
			#call_action_list,name=cooldowns
			ArcaneCooldownsCdActions()

			unless BuffStacks(arcane_missiles_buff) == 3 and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or { target.TimeToDie() < 8 or Charges(supernova) == 2 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) < 4 and Spell(arcane_orb) or Talent(arcane_orb_talent) and Enemies() >= 3 and DebuffStacks(arcane_charge_debuff) == 4 and { SpellCooldown(arcane_orb) < GCD() or PreviousGCDSpell(arcane_orb) } and Spell(arcane_barrage) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or DebuffStacks(arcane_charge_debuff) == 4 and { ManaPercent() > 70 or not { not SpellCooldown(evocation) > 0 } or target.TimeToDie() < 15 } and Spell(arcane_missiles) or ManaPercent() > 70 and ManaPercent() < 96 and Spell(supernova)
			{
				#evocation,interrupt_if=mana.pct>92,if=target.time_to_die>10&mana.pct<30+2.5*active_enemies*(9-active_enemies)
				if target.TimeToDie() > 10 and ManaPercent() < 30 + 2.5 * Enemies() * { 9 - Enemies() } Spell(evocation)
			}
		}
	}
}

AddFunction ArcaneBurnCdPostConditions
{
	Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 and ArcaneInitCrystalCdPostConditions() or Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) and ArcaneCrystalSequenceCdPostConditions() or BuffStacks(arcane_missiles_buff) == 3 and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or { target.TimeToDie() < 8 or Charges(supernova) == 2 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) < 4 and Spell(arcane_orb) or Talent(arcane_orb_talent) and Enemies() >= 3 and DebuffStacks(arcane_charge_debuff) == 4 and { SpellCooldown(arcane_orb) < GCD() or PreviousGCDSpell(arcane_orb) } and Spell(arcane_barrage) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or DebuffStacks(arcane_charge_debuff) == 4 and { ManaPercent() > 70 or not { not SpellCooldown(evocation) > 0 } or target.TimeToDie() < 15 } and Spell(arcane_missiles) or ManaPercent() > 70 and ManaPercent() < 96 and Spell(supernova) or Spell(arcane_blast)
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
	#supernova,if=target.time_to_die<8|(charges=2&(buff.arcane_power.up|!cooldown.arcane_power.up)&(!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>8))
	if target.TimeToDie() < 8 or Charges(supernova) == 2 and { BuffPresent(arcane_power_buff) or not { not SpellCooldown(arcane_power) > 0 } } and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 8 } Spell(supernova)
	#arcane_blast,if=buff.arcane_charge.stack=4&mana.pct>93
	if DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 Spell(arcane_blast)
	#arcane_barrage,if=talent.arcane_orb.enabled&active_enemies>=3&buff.arcane_charge.stack=4&(cooldown.arcane_orb.remains<gcd.max|prev_gcd.arcane_orb)
	if Talent(arcane_orb_talent) and Enemies() >= 3 and DebuffStacks(arcane_charge_debuff) == 4 and { SpellCooldown(arcane_orb) < GCD() or PreviousGCDSpell(arcane_orb) } Spell(arcane_barrage)
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
	#arcane_barrage
	Spell(arcane_barrage)
}

AddFunction ArcaneConserveShortCdActions
{
	unless { BuffStacks(arcane_missiles_buff) == 3 or Talent(overpowered_talent) and BuffPresent(arcane_power_buff) and BuffRemaining(arcane_power_buff) < ExecuteTime(arcane_blast) } and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or { target.TimeToDie() < 8 or Charges(supernova) == 2 and { BuffPresent(arcane_power_buff) or not { not SpellCooldown(arcane_power) > 0 } } and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 8 } } and Spell(supernova)
	{
		#arcane_orb,if=buff.arcane_charge.stack<2
		if DebuffStacks(arcane_charge_debuff) < 2 Spell(arcane_orb)
		#presence_of_mind,if=mana.pct>96&(!talent.prismatic_crystal.enabled|!cooldown.prismatic_crystal.up)
		if ManaPercent() > 96 and { not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } } Spell(presence_of_mind)

		unless DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or Talent(arcane_orb_talent) and Enemies() >= 3 and DebuffStacks(arcane_charge_debuff) == 4 and { SpellCooldown(arcane_orb) < GCD() or PreviousGCDSpell(arcane_orb) } and Spell(arcane_barrage) or DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(overpowered_talent) or SpellCooldown(arcane_power) > 10 * { 100 / { 100 + SpellHaste() } } } and Spell(arcane_missiles) or ManaPercent() < 96 and { BuffStacks(arcane_missiles_buff) < 2 or DebuffStacks(arcane_charge_debuff) == 4 } and { BuffPresent(arcane_power_buff) or Charges(supernova) == 1 and SpellCooldown(arcane_power) > SpellChargeCooldown(supernova) } and { not Talent(prismatic_crystal_talent) or target.Name(prismatic_crystal) or Charges(supernova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(supernova) + 8 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < { 10 - 3 * TalentPoints(arcane_orb_talent) } * { 100 / { 100 + SpellHaste() } } } and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) == 4 and Spell(arcane_barrage)
		{
			#presence_of_mind,if=buff.arcane_charge.stack<2&mana.pct>93
			if DebuffStacks(arcane_charge_debuff) < 2 and ManaPercent() > 93 Spell(presence_of_mind)
		}
	}
}

AddFunction ArcaneConserveShortCdPostConditions
{
	{ BuffStacks(arcane_missiles_buff) == 3 or Talent(overpowered_talent) and BuffPresent(arcane_power_buff) and BuffRemaining(arcane_power_buff) < ExecuteTime(arcane_blast) } and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or { target.TimeToDie() < 8 or Charges(supernova) == 2 and { BuffPresent(arcane_power_buff) or not { not SpellCooldown(arcane_power) > 0 } } and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 8 } } and Spell(supernova) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or Talent(arcane_orb_talent) and Enemies() >= 3 and DebuffStacks(arcane_charge_debuff) == 4 and { SpellCooldown(arcane_orb) < GCD() or PreviousGCDSpell(arcane_orb) } and Spell(arcane_barrage) or DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(overpowered_talent) or SpellCooldown(arcane_power) > 10 * { 100 / { 100 + SpellHaste() } } } and Spell(arcane_missiles) or ManaPercent() < 96 and { BuffStacks(arcane_missiles_buff) < 2 or DebuffStacks(arcane_charge_debuff) == 4 } and { BuffPresent(arcane_power_buff) or Charges(supernova) == 1 and SpellCooldown(arcane_power) > SpellChargeCooldown(supernova) } and { not Talent(prismatic_crystal_talent) or target.Name(prismatic_crystal) or Charges(supernova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(supernova) + 8 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < { 10 - 3 * TalentPoints(arcane_orb_talent) } * { 100 / { 100 + SpellHaste() } } } and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) == 4 and Spell(arcane_barrage) or Spell(arcane_blast) or Spell(arcane_barrage)
}

AddFunction ArcaneConserveCdActions
{
	#call_action_list,name=cooldowns,if=target.time_to_die<15
	if target.TimeToDie() < 15 ArcaneCooldownsCdActions()
}

AddFunction ArcaneConserveCdPostConditions
{
	{ BuffStacks(arcane_missiles_buff) == 3 or Talent(overpowered_talent) and BuffPresent(arcane_power_buff) and BuffRemaining(arcane_power_buff) < ExecuteTime(arcane_blast) } and Spell(arcane_missiles) or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and Spell(arcane_missiles) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest) or { target.TimeToDie() < 8 or Charges(supernova) == 2 and { BuffPresent(arcane_power_buff) or not { not SpellCooldown(arcane_power) > 0 } } and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 8 } } and Spell(supernova) or DebuffStacks(arcane_charge_debuff) < 2 and Spell(arcane_orb) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast) or Talent(arcane_orb_talent) and Enemies() >= 3 and DebuffStacks(arcane_charge_debuff) == 4 and { SpellCooldown(arcane_orb) < GCD() or PreviousGCDSpell(arcane_orb) } and Spell(arcane_barrage) or DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(overpowered_talent) or SpellCooldown(arcane_power) > 10 * { 100 / { 100 + SpellHaste() } } } and Spell(arcane_missiles) or ManaPercent() < 96 and { BuffStacks(arcane_missiles_buff) < 2 or DebuffStacks(arcane_charge_debuff) == 4 } and { BuffPresent(arcane_power_buff) or Charges(supernova) == 1 and SpellCooldown(arcane_power) > SpellChargeCooldown(supernova) } and { not Talent(prismatic_crystal_talent) or target.Name(prismatic_crystal) or Charges(supernova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(supernova) + 8 } and Spell(supernova) or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < { 10 - 3 * TalentPoints(arcane_orb_talent) } * { 100 / { 100 + SpellHaste() } } } and Spell(nether_tempest) or DebuffStacks(arcane_charge_debuff) == 4 and Spell(arcane_barrage) or Spell(arcane_blast) or Spell(arcane_barrage)
}

### actions.cooldowns

AddFunction ArcaneCooldownsCdActions
{
	#arcane_power
	Spell(arcane_power)
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
	#arcane_blast,if=buff.arcane_charge.stack=4&mana.pct>93&pet.prismatic_crystal.remains>cast_time
	if DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and TotemRemaining(prismatic_crystal) > CastTime(arcane_blast) Spell(arcane_blast)
	#arcane_missiles,if=pet.prismatic_crystal.remains>2*spell_haste+travel_time
	if TotemRemaining(prismatic_crystal) > 2 * { 100 / { 100 + SpellHaste() } } + TravelTime(arcane_missiles) Spell(arcane_missiles)
	#supernova,if=pet.prismatic_crystal.remains<2*spell_haste
	if TotemRemaining(prismatic_crystal) < 2 * { 100 / { 100 + SpellHaste() } } Spell(supernova)
	#choose_target,if=pet.prismatic_crystal.remains<action.arcane_blast.cast_time&buff.presence_of_mind.down
	#arcane_blast
	Spell(arcane_blast)
}

AddFunction ArcaneCrystalSequenceShortCdActions
{
	unless DebuffStacks(arcane_charge_debuff) == 4 and not target.DebuffPresent(nether_tempest_debuff) and TotemRemaining(prismatic_crystal) > 8 and Spell(nether_tempest) or ManaPercent() < 96 and Spell(supernova)
	{
		#presence_of_mind,if=cooldown.cold_snap.up|pet.prismatic_crystal.remains<2*spell_haste
		if not SpellCooldown(cold_snap) > 0 or TotemRemaining(prismatic_crystal) < 2 * { 100 / { 100 + SpellHaste() } } Spell(presence_of_mind)
	}
}

AddFunction ArcaneCrystalSequenceShortCdPostConditions
{
	DebuffStacks(arcane_charge_debuff) == 4 and not target.DebuffPresent(nether_tempest_debuff) and TotemRemaining(prismatic_crystal) > 8 and Spell(nether_tempest) or ManaPercent() < 96 and Spell(supernova) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and TotemRemaining(prismatic_crystal) > CastTime(arcane_blast) and Spell(arcane_blast) or TotemRemaining(prismatic_crystal) > 2 * { 100 / { 100 + SpellHaste() } } + TravelTime(arcane_missiles) and Spell(arcane_missiles) or TotemRemaining(prismatic_crystal) < 2 * { 100 / { 100 + SpellHaste() } } and Spell(supernova) or Spell(arcane_blast)
}

AddFunction ArcaneCrystalSequenceCdActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsCdActions()
}

AddFunction ArcaneCrystalSequenceCdPostConditions
{
	DebuffStacks(arcane_charge_debuff) == 4 and not target.DebuffPresent(nether_tempest_debuff) and TotemRemaining(prismatic_crystal) > 8 and Spell(nether_tempest) or ManaPercent() < 96 and Spell(supernova) or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and TotemRemaining(prismatic_crystal) > CastTime(arcane_blast) and Spell(arcane_blast) or TotemRemaining(prismatic_crystal) > 2 * { 100 / { 100 + SpellHaste() } } + TravelTime(arcane_missiles) and Spell(arcane_missiles) or TotemRemaining(prismatic_crystal) < 2 * { 100 / { 100 + SpellHaste() } } and Spell(supernova) or Spell(arcane_blast)
}

### actions.init_burn

AddFunction ArcaneInitBurnMainActions
{
	#start_burn_phase,if=buff.arcane_charge.stack>=4&(cooldown.prismatic_crystal.up|!talent.prismatic_crystal.enabled)&(cooldown.arcane_power.up|(glyph.arcane_power.enabled&cooldown.arcane_power.remains>60))&(cooldown.evocation.remains-2*buff.arcane_missiles.stack*spell_haste-gcd.max*talent.prismatic_crystal.enabled)*0.75*(1-0.1*(cooldown.arcane_power.remains<5))*(1-0.1*(talent.nether_tempest.enabled|talent.supernova.enabled))*(10%action.arcane_blast.execute_time)<mana.pct-20-2.5*active_enemies*(9-active_enemies)+(cooldown.evocation.remains*1.8%spell_haste)
	if DebuffStacks(arcane_charge_debuff) >= 4 and { not SpellCooldown(prismatic_crystal) > 0 or not Talent(prismatic_crystal_talent) } and { not SpellCooldown(arcane_power) > 0 or Glyph(glyph_of_arcane_power) and SpellCooldown(arcane_power) > 60 } and { SpellCooldown(evocation) - 2 * BuffStacks(arcane_missiles_buff) * { 100 / { 100 + SpellHaste() } } - GCD() * TalentPoints(prismatic_crystal_talent) } * 0.75 * { 1 - 0.1 * { SpellCooldown(arcane_power) < 5 } } * { 1 - 0.1 * { Talent(nether_tempest_talent) or Talent(supernova_talent) } } * { 10 / ExecuteTime(arcane_blast) } < ManaPercent() - 20 - 2.5 * Enemies() * { 9 - Enemies() } + SpellCooldown(evocation) * 1.8 / { 100 / { 100 + SpellHaste() } } and not GetState(burn_phase) > 0 SetState(burn_phase 1)
	#start_burn_phase,if=target.time_to_die*0.75*(1-0.1*(talent.nether_tempest.enabled|talent.supernova.enabled))*(10%action.arcane_blast.execute_time)*1.1<mana.pct-10+(target.time_to_die*1.8%spell_haste)
	if target.TimeToDie() * 0.75 * { 1 - 0.1 * { Talent(nether_tempest_talent) or Talent(supernova_talent) } } * { 10 / ExecuteTime(arcane_blast) } * 1.1 < ManaPercent() - 10 + target.TimeToDie() * 1.8 / { 100 / { 100 + SpellHaste() } } and not GetState(burn_phase) > 0 SetState(burn_phase 1)
}

AddFunction ArcaneInitBurnShortCdActions
{
	#start_burn_phase,if=buff.arcane_charge.stack>=4&(cooldown.prismatic_crystal.up|!talent.prismatic_crystal.enabled)&(cooldown.arcane_power.up|(glyph.arcane_power.enabled&cooldown.arcane_power.remains>60))&(cooldown.evocation.remains-2*buff.arcane_missiles.stack*spell_haste-gcd.max*talent.prismatic_crystal.enabled)*0.75*(1-0.1*(cooldown.arcane_power.remains<5))*(1-0.1*(talent.nether_tempest.enabled|talent.supernova.enabled))*(10%action.arcane_blast.execute_time)<mana.pct-20-2.5*active_enemies*(9-active_enemies)+(cooldown.evocation.remains*1.8%spell_haste)
	if DebuffStacks(arcane_charge_debuff) >= 4 and { not SpellCooldown(prismatic_crystal) > 0 or not Talent(prismatic_crystal_talent) } and { not SpellCooldown(arcane_power) > 0 or Glyph(glyph_of_arcane_power) and SpellCooldown(arcane_power) > 60 } and { SpellCooldown(evocation) - 2 * BuffStacks(arcane_missiles_buff) * { 100 / { 100 + SpellHaste() } } - GCD() * TalentPoints(prismatic_crystal_talent) } * 0.75 * { 1 - 0.1 * { SpellCooldown(arcane_power) < 5 } } * { 1 - 0.1 * { Talent(nether_tempest_talent) or Talent(supernova_talent) } } * { 10 / ExecuteTime(arcane_blast) } < ManaPercent() - 20 - 2.5 * Enemies() * { 9 - Enemies() } + SpellCooldown(evocation) * 1.8 / { 100 / { 100 + SpellHaste() } } and not GetState(burn_phase) > 0 SetState(burn_phase 1)
	#start_burn_phase,if=target.time_to_die*0.75*(1-0.1*(talent.nether_tempest.enabled|talent.supernova.enabled))*(10%action.arcane_blast.execute_time)*1.1<mana.pct-10+(target.time_to_die*1.8%spell_haste)
	if target.TimeToDie() * 0.75 * { 1 - 0.1 * { Talent(nether_tempest_talent) or Talent(supernova_talent) } } * { 10 / ExecuteTime(arcane_blast) } * 1.1 < ManaPercent() - 10 + target.TimeToDie() * 1.8 / { 100 / { 100 + SpellHaste() } } and not GetState(burn_phase) > 0 SetState(burn_phase 1)
}

AddFunction ArcaneInitBurnCdActions
{
	#start_burn_phase,if=buff.arcane_charge.stack>=4&(cooldown.prismatic_crystal.up|!talent.prismatic_crystal.enabled)&(cooldown.arcane_power.up|(glyph.arcane_power.enabled&cooldown.arcane_power.remains>60))&(cooldown.evocation.remains-2*buff.arcane_missiles.stack*spell_haste-gcd.max*talent.prismatic_crystal.enabled)*0.75*(1-0.1*(cooldown.arcane_power.remains<5))*(1-0.1*(talent.nether_tempest.enabled|talent.supernova.enabled))*(10%action.arcane_blast.execute_time)<mana.pct-20-2.5*active_enemies*(9-active_enemies)+(cooldown.evocation.remains*1.8%spell_haste)
	if DebuffStacks(arcane_charge_debuff) >= 4 and { not SpellCooldown(prismatic_crystal) > 0 or not Talent(prismatic_crystal_talent) } and { not SpellCooldown(arcane_power) > 0 or Glyph(glyph_of_arcane_power) and SpellCooldown(arcane_power) > 60 } and { SpellCooldown(evocation) - 2 * BuffStacks(arcane_missiles_buff) * { 100 / { 100 + SpellHaste() } } - GCD() * TalentPoints(prismatic_crystal_talent) } * 0.75 * { 1 - 0.1 * { SpellCooldown(arcane_power) < 5 } } * { 1 - 0.1 * { Talent(nether_tempest_talent) or Talent(supernova_talent) } } * { 10 / ExecuteTime(arcane_blast) } < ManaPercent() - 20 - 2.5 * Enemies() * { 9 - Enemies() } + SpellCooldown(evocation) * 1.8 / { 100 / { 100 + SpellHaste() } } and not GetState(burn_phase) > 0 SetState(burn_phase 1)
	#start_burn_phase,if=target.time_to_die*0.75*(1-0.1*(talent.nether_tempest.enabled|talent.supernova.enabled))*(10%action.arcane_blast.execute_time)*1.1<mana.pct-10+(target.time_to_die*1.8%spell_haste)
	if target.TimeToDie() * 0.75 * { 1 - 0.1 * { Talent(nether_tempest_talent) or Talent(supernova_talent) } } * { 10 / ExecuteTime(arcane_blast) } * 1.1 < ManaPercent() - 10 + target.TimeToDie() * 1.8 / { 100 / { 100 + SpellHaste() } } and not GetState(burn_phase) > 0 SetState(burn_phase 1)
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
		#prismatic_crystal
		Spell(prismatic_crystal)
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
	DebuffStacks(arcane_charge_debuff) < 4 and ArcaneConserveCdPostConditions() or Spell(prismatic_crystal)
}

### actions.precombat

AddFunction ArcanePrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=sleeper_sushi
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

### Required symbols
# arcane_barrage
# arcane_blast
# arcane_brilliance
# arcane_charge_debuff
# arcane_explosion
# arcane_instability_buff
# arcane_missiles
# arcane_missiles_buff
# arcane_orb
# arcane_orb_talent
# arcane_power
# arcane_power_buff
# arcane_torrent_mana
# berserking
# blazing_speed
# blink
# blood_fury_sp
# cold_snap
# cone_of_cold
# counterspell
# draenic_intellect_potion
# evocation
# glyph_of_arcane_power
# glyph_of_cone_of_cold
# ice_floes
# ice_floes_buff
# mirror_image
# nether_tempest
# nether_tempest_debuff
# nether_tempest_talent
# overpowered_talent
# presence_of_mind
# presence_of_mind_buff
# prismatic_crystal
# prismatic_crystal_talent
# quaking_palm
# rune_of_power
# supernova
# supernova_talent
# time_warp
]]
	OvaleScripts:RegisterScript("MAGE", "arcane", name, desc, code, "script")
end
