local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_mage"
	local desc = "[6.0] Ovale: Rotations (Arcane, Fire, Frost)"
	local code = [[
# Mage rotation functions based on SimulationCraft.

Include(ovale_common)
Include(ovale_mage_spells)

AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default)
AddCheckBox(opt_time_warp SpellName(time_warp) default)

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
	{
		Spell(counterspell)
		if not target.Classification(worldboss)
		{
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

###
### Arcane
###
# Based on SimulationCraft profile "Mage_Arcane_T17M".
#	class=mage
#	spec=arcane
#	talents=3003121
#	glyphs=arcane_power/cone_of_cold

# ActionList: ArcaneDefaultActions --> main, shortcd, cd

AddFunction ArcaneDefaultActions
{
	#call_action_list,name=init_crystal,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up
	if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 ArcaneInitCrystalActions()
	#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
	if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) ArcaneCrystalSequenceActions()
	#call_action_list,name=aoe,if=active_enemies>=4
	if Enemies() >= 4 ArcaneAoeActions()
	#call_action_list,name=burn,if=time_to_die<mana.pct*0.35*spell_haste|cooldown.evocation.remains<=(mana.pct-30)*0.3*spell_haste|(buff.arcane_power.up&cooldown.evocation.remains<=(mana.pct-30)*0.4*spell_haste)
	if TimeToDie() < ManaPercent() * 0.35 * 100 / { 100 + SpellHaste() } or SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.3 * 100 / { 100 + SpellHaste() } or BuffPresent(arcane_power_buff) and SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.4 * 100 / { 100 + SpellHaste() } ArcaneBurnActions()
	#call_action_list,name=conserve
	ArcaneConserveActions()
}

AddFunction ArcaneDefaultShortCdActions
{
	#ice_floes,if=buff.ice_floes.down&(raid_event.movement.distance>0|raid_event.movement.in<action.arcane_missiles.cast_time)
	if BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < CastTime(arcane_missiles) } Spell(ice_floes)
	#rune_of_power,if=buff.rune_of_power.remains<cast_time
	if TotemRemaining(rune_of_power) < CastTime(rune_of_power) Spell(rune_of_power)
	#call_action_list,name=init_crystal,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up
	if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 ArcaneInitCrystalShortCdActions()
	#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
	if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) ArcaneCrystalSequenceShortCdActions()
	#call_action_list,name=aoe,if=active_enemies>=4
	if Enemies() >= 4 ArcaneAoeShortCdActions()
	#call_action_list,name=burn,if=time_to_die<mana.pct*0.35*spell_haste|cooldown.evocation.remains<=(mana.pct-30)*0.3*spell_haste|(buff.arcane_power.up&cooldown.evocation.remains<=(mana.pct-30)*0.4*spell_haste)
	if TimeToDie() < ManaPercent() * 0.35 * 100 / { 100 + SpellHaste() } or SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.3 * 100 / { 100 + SpellHaste() } or BuffPresent(arcane_power_buff) and SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.4 * 100 / { 100 + SpellHaste() } ArcaneBurnShortCdActions()
	#call_action_list,name=conserve
	ArcaneConserveShortCdActions()
}

AddFunction ArcaneDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() InterruptActions()
	#cold_snap,if=health.pct<30
	if HealthPercent() < 30 Spell(cold_snap)
	#time_warp,if=target.health.pct<25|time>5
	if { target.HealthPercent() < 25 or TimeInCombat() > 5 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)

	unless BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < CastTime(arcane_missiles) } and Spell(ice_floes)
		or TotemRemaining(rune_of_power) < CastTime(rune_of_power) and Spell(rune_of_power)
	{
		#mirror_image
		Spell(mirror_image)
		#cold_snap,if=buff.presence_of_mind.down&cooldown.presence_of_mind.remains>75
		if BuffExpires(presence_of_mind_buff) and SpellCooldown(presence_of_mind) > 75 Spell(cold_snap)
		#call_action_list,name=init_crystal,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up
		if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 ArcaneInitCrystalCdActions()
		#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
		if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) ArcaneCrystalSequenceCdActions()
		#call_action_list,name=aoe,if=active_enemies>=4
		if Enemies() >= 4 ArcaneAoeCdActions()
		#call_action_list,name=burn,if=time_to_die<mana.pct*0.35*spell_haste|cooldown.evocation.remains<=(mana.pct-30)*0.3*spell_haste|(buff.arcane_power.up&cooldown.evocation.remains<=(mana.pct-30)*0.4*spell_haste)
		if TimeToDie() < ManaPercent() * 0.35 * 100 / { 100 + SpellHaste() } or SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.3 * 100 / { 100 + SpellHaste() } or BuffPresent(arcane_power_buff) and SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.4 * 100 / { 100 + SpellHaste() } ArcaneBurnCdActions()
		#call_action_list,name=conserve
		ArcaneConserveCdActions()
	}
}

# ActionList: ArcaneAoeActions --> main, shortcd, cd

AddFunction ArcaneAoeActions
{
	#nether_tempest,cycle_targets=1,if=buff.arcane_charge.stack=4&(active_dot.nether_tempest=0|(ticking&remains<3.6))
	if DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } Spell(nether_tempest)
	#supernova
	Spell(supernova)
	#arcane_barrage,if=buff.arcane_charge.stack=4
	if DebuffStacks(arcane_charge_debuff) == 4 Spell(arcane_barrage)
	#arcane_orb,if=buff.arcane_charge.stack<4
	if DebuffStacks(arcane_charge_debuff) < 4 Spell(arcane_orb)
	#cone_of_cold,if=glyph.cone_of_cold.enabled
	if Glyph(glyph_of_cone_of_cold) Spell(cone_of_cold)
	#arcane_explosion
	Spell(arcane_explosion)
}

AddFunction ArcaneAoeShortCdActions {}

AddFunction ArcaneAoeCdActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsCdActions()
}

# ActionList: ArcaneBurnActions --> main, shortcd, cd

AddFunction ArcaneBurnActions
{
	#arcane_missiles,if=buff.arcane_missiles.react=3
	if BuffStacks(arcane_missiles_buff) == 3 and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#arcane_missiles,if=set_bonus.tier17_4pc&buff.arcane_instability.react&buff.arcane_instability.remains<action.arcane_blast.execute_time
	if ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#supernova,if=time_to_die<8|charges=2
	if TimeToDie() < 8 or Charges(supernova) == 2 Spell(supernova)
	#nether_tempest,cycle_targets=1,if=target!=prismatic_crystal&buff.arcane_charge.stack=4&(active_dot.nether_tempest=0|(ticking&remains<3.6))
	if not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } Spell(nether_tempest)
	#arcane_orb,if=buff.arcane_charge.stack<4
	if DebuffStacks(arcane_charge_debuff) < 4 Spell(arcane_orb)
	#supernova,if=current_target=prismatic_crystal
	if target.Name(prismatic_crystal) Spell(supernova)
	#arcane_blast,if=buff.arcane_charge.stack=4&mana.pct>93
	if DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 Spell(arcane_blast)
	#arcane_missiles,if=buff.arcane_charge.stack=4
	if DebuffStacks(arcane_charge_debuff) == 4 and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#supernova,if=mana.pct<96
	if ManaPercent() < 96 Spell(supernova)
	#call_action_list,name=conserve,if=cooldown.evocation.duration-cooldown.evocation.remains<5
	if SpellCooldownDuration(evocation) - SpellCooldown(evocation) < 5 ArcaneConserveActions()
	#arcane_blast
	Spell(arcane_blast)
}

AddFunction ArcaneBurnShortCdActions
{
	unless BuffStacks(arcane_missiles_buff) == 3 and BuffPresent(arcane_missiles_buff) and Spell(arcane_missiles)
		or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and BuffPresent(arcane_missiles_buff) and Spell(arcane_missiles)
		or { TimeToDie() < 8 or Charges(supernova) == 2 } and Spell(supernova)
		or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest)
	{
		#arcane_orb,if=buff.arcane_charge.stack<4
		if DebuffStacks(arcane_charge_debuff) < 4 Spell(arcane_orb)

		unless target.Name(prismatic_crystal) and Spell(supernova)
		{
			#presence_of_mind,if=mana.pct>96
			if ManaPercent() > 96 Spell(presence_of_mind)

			unless DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast)
				or DebuffStacks(arcane_charge_debuff) == 4 and BuffPresent(arcane_missiles_buff) and Spell(arcane_missiles)
				or ManaPercent() < 96 and Spell(supernova)
			{
				#call_action_list,name=conserve,if=cooldown.evocation.duration-cooldown.evocation.remains<5
				if SpellCooldownDuration(evocation) - SpellCooldown(evocation) < 5 ArcaneConserveShortCdActions()
				#evocation,interrupt_if=mana.pct>92,if=time_to_die>10&mana.pct<50
				if TimeToDie() > 10 and ManaPercent() < 50 Spell(evocation)
				#presence_of_mind
				Spell(presence_of_mind)
			}
		}
	}
}

AddFunction ArcaneBurnCdActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsCdActions()

	unless BuffStacks(arcane_missiles_buff) == 3 and BuffPresent(arcane_missiles_buff) and Spell(arcane_missiles)
		or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and BuffPresent(arcane_missiles_buff) and Spell(arcane_missiles)
		or { TimeToDie() < 8 or Charges(supernova) == 2 } and Spell(supernova)
		or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest)
		or DebuffStacks(arcane_charge_debuff) < 4 and Spell(arcane_orb)
		or target.Name(prismatic_crystal) and Spell(supernova)
		or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast)
		or DebuffStacks(arcane_charge_debuff) == 4 and BuffPresent(arcane_missiles_buff) and Spell(arcane_missiles)
		or ManaPercent() < 96 and Spell(supernova)
	{
		#call_action_list,name=conserve,if=cooldown.evocation.duration-cooldown.evocation.remains<5
		if SpellCooldownDuration(evocation) - SpellCooldown(evocation) < 5 ArcaneConserveCdActions()
	}
}

# ActionList: ArcaneConserveActions --> main, shortcd, cd

AddFunction ArcaneConserveActions
{
	#arcane_missiles,if=buff.arcane_missiles.react=3|(talent.overpowered.enabled&buff.arcane_power.up&buff.arcane_power.remains<action.arcane_blast.execute_time)
	if { BuffStacks(arcane_missiles_buff) == 3 or Talent(overpowered_talent) and BuffPresent(arcane_power_buff) and BuffRemaining(arcane_power_buff) < ExecuteTime(arcane_blast) } and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#arcane_missiles,if=set_bonus.tier17_4pc&buff.arcane_instability.react&buff.arcane_instability.remains<action.arcane_blast.execute_time
	if ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#nether_tempest,cycle_targets=1,if=target!=prismatic_crystal&buff.arcane_charge.stack=4&(active_dot.nether_tempest=0|(ticking&remains<3.6))
	if not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } Spell(nether_tempest)
	#supernova,if=time_to_die<8|(charges=2&(buff.arcane_power.up|!cooldown.arcane_power.up)&(!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>8))
	if TimeToDie() < 8 or Charges(supernova) == 2 and { BuffPresent(arcane_power_buff) or not { not SpellCooldown(arcane_power) > 0 } } and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 8 } Spell(supernova)
	#arcane_blast,if=buff.arcane_charge.stack=4&mana.pct>93
	if DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 Spell(arcane_blast)
	#arcane_missiles,if=buff.arcane_charge.stack=4&(!talent.overpowered.enabled|cooldown.arcane_power.remains>10*spell_haste)
	if DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(overpowered_talent) or SpellCooldown(arcane_power) > 10 * 100 / { 100 + SpellHaste() } } and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#supernova,if=mana.pct<96&(buff.arcane_missiles.stack<2|buff.arcane_charge.stack=4)&(buff.arcane_power.up|(charges=1&cooldown.arcane_power.remains>recharge_time))&(!talent.prismatic_crystal.enabled|current_target=prismatic_crystal|(charges=1&cooldown.prismatic_crystal.remains>recharge_time+8))
	if ManaPercent() < 96 and { BuffStacks(arcane_missiles_buff) < 2 or DebuffStacks(arcane_charge_debuff) == 4 } and { BuffPresent(arcane_power_buff) or Charges(supernova) == 1 and SpellCooldown(arcane_power) > SpellChargeCooldown(supernova) } and { not Talent(prismatic_crystal_talent) or target.Name(prismatic_crystal) or Charges(supernova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(supernova) + 8 } Spell(supernova)
	#nether_tempest,cycle_targets=1,if=target!=prismatic_crystal&buff.arcane_charge.stack=4&(active_dot.nether_tempest=0|(ticking&remains<(10-3*talent.arcane_orb.enabled)*spell_haste))
	if not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < { 10 - 3 * Talent(arcane_orb_talent) } * 100 / { 100 + SpellHaste() } } Spell(nether_tempest)
	#arcane_barrage,if=buff.arcane_charge.stack=4
	if DebuffStacks(arcane_charge_debuff) == 4 Spell(arcane_barrage)
	#arcane_blast
	Spell(arcane_blast)
	#arcane_barrage,moving=1
	if Speed() > 0 Spell(arcane_barrage)
}

AddFunction ArcaneConserveShortCdActions
{
	unless { BuffStacks(arcane_missiles_buff) == 3 or Talent(overpowered_talent) and BuffPresent(arcane_power_buff) and BuffRemaining(arcane_power_buff) < ExecuteTime(arcane_blast) } and BuffPresent(arcane_missiles_buff) and Spell(arcane_missiles)
		or ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and BuffPresent(arcane_missiles_buff) and Spell(arcane_missiles)
		or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } and Spell(nether_tempest)
		or { TimeToDie() < 8 or Charges(supernova) == 2 and { BuffPresent(arcane_power_buff) or not { not SpellCooldown(arcane_power) > 0 } } and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 8 } } and Spell(supernova)
	{
		#arcane_orb,if=buff.arcane_charge.stack<2
		if DebuffStacks(arcane_charge_debuff) < 2 Spell(arcane_orb)
		#presence_of_mind,if=mana.pct>96
		if ManaPercent() > 96 Spell(presence_of_mind)

		unless DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 and Spell(arcane_blast)
			or DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(overpowered_talent) or SpellCooldown(arcane_power) > 10 * 100 / { 100 + SpellHaste() } } and BuffPresent(arcane_missiles_buff) and Spell(arcane_missiles)
			or ManaPercent() < 96 and { BuffStacks(arcane_missiles_buff) < 2 or DebuffStacks(arcane_charge_debuff) == 4 } and { BuffPresent(arcane_power_buff) or Charges(supernova) == 1 and SpellCooldown(arcane_power) > SpellChargeCooldown(supernova) } and { not Talent(prismatic_crystal_talent) or target.Name(prismatic_crystal) or Charges(supernova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(supernova) + 8 } and Spell(supernova)
			or not target.Name(prismatic_crystal) and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < { 10 - 3 * Talent(arcane_orb_talent) } * 100 / { 100 + SpellHaste() } } and Spell(nether_tempest)
			or DebuffStacks(arcane_charge_debuff) == 4 and Spell(arcane_barrage)
		{
			#presence_of_mind,if=buff.arcane_charge.stack<2
			if DebuffStacks(arcane_charge_debuff) < 2 Spell(presence_of_mind)
		}
	}
}

AddFunction ArcaneConserveCdActions
{
	#call_action_list,name=cooldowns,if=time_to_die<30|(buff.arcane_charge.stack=4&(!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>15))
	if TimeToDie() < 30 or DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 15 } ArcaneCooldownsCdActions()
}

# ActionList: ArcaneCooldownsActions --> cd

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
	if BuffPresent(arcane_power_buff) and { not Talent(prismatic_crystal_talent) or TotemPresent(prismatic_crystal) } UsePotionIntellect()
}

# ActionList: ArcaneCrystalSequenceActions --> main, shortcd, cd

AddFunction ArcaneCrystalSequenceActions
{
	#nether_tempest,if=buff.arcane_charge.stack=4&!ticking&pet.prismatic_crystal.remains>8
	if DebuffStacks(arcane_charge_debuff) == 4 and not target.DebuffPresent(nether_tempest_debuff) and TotemRemaining(crystal totem=prismatic_crystal) > 8 Spell(nether_tempest)
	#call_action_list,name=burn
	ArcaneBurnActions()
}

AddFunction ArcaneCrystalSequenceShortCdActions
{
	unless DebuffStacks(arcane_charge_debuff) == 4 and not target.DebuffPresent(nether_tempest_debuff) and TotemRemaining(crystal totem=prismatic_crystal) > 8 and Spell(nether_tempest)
	{
		#call_action_list,name=burn
		ArcaneBurnShortCdActions()
	}
}

AddFunction ArcaneCrystalSequenceCdActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsCdActions()

	unless DebuffStacks(arcane_charge_debuff) == 4 and not target.DebuffPresent(nether_tempest_debuff) and TotemRemaining(crystal totem=prismatic_crystal) > 8 and Spell(nether_tempest)
	{
		#call_action_list,name=burn
		ArcaneBurnCdActions()
	}
}

# ActionList: ArcaneInitCrystalActions --> main, shortcd, cd

AddFunction ArcaneInitCrystalActions
{
	#call_action_list,name=conserve,if=buff.arcane_charge.stack<4
	if DebuffStacks(arcane_charge_debuff) < 4 ArcaneConserveActions()
}

AddFunction ArcaneInitCrystalShortCdActions
{
	#call_action_list,name=conserve,if=buff.arcane_charge.stack<4
	if DebuffStacks(arcane_charge_debuff) < 4 ArcaneConserveShortCdActions()
	#prismatic_crystal,if=buff.arcane_charge.stack=4&cooldown.arcane_power.remains<0.5
	if DebuffStacks(arcane_charge_debuff) == 4 and SpellCooldown(arcane_power) < 0.5 Spell(prismatic_crystal)
	#prismatic_crystal,if=glyph.arcane_power.enabled&buff.arcane_charge.stack=4&cooldown.arcane_power.remains>45
	if Glyph(glyph_of_arcane_power) and DebuffStacks(arcane_charge_debuff) == 4 and SpellCooldown(arcane_power) > 45 Spell(prismatic_crystal)
}

AddFunction ArcaneInitCrystalCdActions
{
	#call_action_list,name=conserve,if=buff.arcane_charge.stack<4
	if DebuffStacks(arcane_charge_debuff) < 4 ArcaneConserveCdActions()
}

# ActionList: ArcanePrecombatActions --> main, shortcd, cd

AddFunction ArcanePrecombatActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=sleeper_surprise
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#snapshot_stats
	#arcane_blast
	Spell(arcane_blast)
}

AddFunction ArcanePrecombatShortCdActions
{
	unless { BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance)
	{
		# CHANGE: Only suggest Rune of Power if the rune needs to be refreshed prior to pull.
		#rune_of_power
		#Spell(rune_of_power)
		if TotemRemaining(rune_of_power) < 150 Spell(rune_of_power)
	}
}

AddFunction ArcanePrecombatCdActions
{
	unless { BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance)
		or TotemRemaining(rune_of_power) < 150 and Spell(rune_of_power)
	{
		#mirror_image
		Spell(mirror_image)
		#potion,name=draenic_intellect
		UsePotionIntellect()
	}
}

###
### Fire
###
# Based on SimulationCraft profile "Mage_Fire_T17M".
#	class=mage
#	spec=fire
#	talents=3003322
#	glyphs=inferno_blast/combustion/dragons_breath

# ActionList: FireDefaultActions --> main, shortcd, cd

AddFunction FireDefaultActions
{
	#call_action_list,name=combust_sequence,if=pyro_chain
	if GetState(pyro_chain) > 0 FireCombustSequenceActions()
	#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
	if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) FireCrystalSequenceActions()
	#call_action_list,name=init_combust,if=!pyro_chain
	if not GetState(pyro_chain) > 0 FireInitCombustActions()
	#call_action_list,name=aoe,if=active_enemies>=4
	if Enemies() >= 4 FireAoeActions()
	#call_action_list,name=single_target
	FireSingleTargetActions()
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
	#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
	if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) FireCrystalSequenceShortCdActions()
	#call_action_list,name=init_combust,if=!pyro_chain
	if not GetState(pyro_chain) > 0 FireInitCombustShortCdActions()
	#rune_of_power,if=buff.rune_of_power.remains<action.fireball.execute_time+gcd.max&!(buff.heating_up.up&action.fireball.in_flight)
	if TotemRemaining(rune_of_power) < ExecuteTime(fireball) + GCD() and not { BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } Spell(rune_of_power)
	#call_action_list,name=aoe,if=active_enemies>=4
	if Enemies() >= 4 FireAoeShortCdActions()
	#call_action_list,name=single_target
	FireSingleTargetShortCdActions()
}

AddFunction FireDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() InterruptActions()
	#time_warp,if=target.health.pct<25|time>5
	if { target.HealthPercent() < 25 or TimeInCombat() > 5 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)

	unless BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < CastTime(fireball) } and Spell(ice_floes)
		or TotemRemaining(rune_of_power) < CastTime(rune_of_power) and Spell(rune_of_power)
	{
		#call_action_list,name=combust_sequence,if=pyro_chain
		if GetState(pyro_chain) > 0 FireCombustSequenceCdActions()
		#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
		if Talent(prismatic_crystal_talent) and TotemPresent(prismatic_crystal) FireCrystalSequenceCdActions()
		#call_action_list,name=init_combust,if=!pyro_chain
		if not GetState(pyro_chain) > 0 FireInitCombustCdActions()

		unless TotemRemaining(rune_of_power) < ExecuteTime(fireball) + GCD() and not { BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } and Spell(rune_of_power)
		{
			#mirror_image,if=!(buff.heating_up.up&action.fireball.in_flight)
			if not { BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } Spell(mirror_image)
			#call_action_list,name=aoe,if=active_enemies>=4
			if Enemies() >= 4 FireAoeCdActions()
			#call_action_list,name=single_target
			FireSingleTargetCdActions()
		}
	}
}

# ActionList: FireActiveTalentsActions --> main, shortcd, cd

AddFunction FireActiveTalentsActions
{
	#call_action_list,name=living_bomb,if=talent.living_bomb.enabled
	if Talent(living_bomb_talent) FireLivingBombActions()
	#blast_wave,if=(!talent.incanters_flow.enabled|buff.incanters_flow.stack>=4)&(time_to_die<10|!talent.prismatic_crystal.enabled|(charges=1&cooldown.prismatic_crystal.remains>recharge_time)|charges=2|current_target=prismatic_crystal)
	if { not Talent(incanters_flow_talent) or BuffStacks(incanters_flow_buff) >= 4 } and { TimeToDie() < 10 or not Talent(prismatic_crystal_talent) or Charges(blast_wave) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(blast_wave) or Charges(blast_wave) == 2 or target.Name(prismatic_crystal) } Spell(blast_wave)
}

AddFunction FireActiveTalentsShortCdActions
{
	#meteor,if=active_enemies>=5|(glyph.combustion.enabled&(!talent.incanters_flow.enabled|buff.incanters_flow.stack+incanters_flow_dir>=4)&cooldown.meteor.duration-cooldown.combustion.remains<10)
	if Enemies() >= 5 or Glyph(glyph_of_combustion) and { not Talent(incanters_flow_talent) or BuffStacks(incanters_flow_buff) + BuffDirection(incanters_flow_buff) >= 4 } and SpellCooldownDuration(meteor) - SpellCooldown(combustion) < 10 Spell(meteor)
}

AddFunction FireActiveTalentsCdActions {}

# ActionList: FireAoeActions --> main, shortcd, cd

AddFunction FireAoeActions
{
	#inferno_blast,cycle_targets=1,if=(dot.combustion.ticking&active_dot.combustion<active_enemies)|(dot.pyroblast.ticking&active_dot.pyroblast<active_enemies)
	if target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(pyroblast_debuff) and DebuffCountOnAny(pyroblast_debuff) < Enemies() Spell(inferno_blast)
	#call_action_list,name=active_talents
	FireActiveTalentsActions()
	#pyroblast,if=buff.pyroblast.react|buff.pyromaniac.react
	if BuffPresent(pyroblast_buff) or BuffPresent(pyromaniac_buff) Spell(pyroblast)
	#pyroblast,if=active_dot.pyroblast=0&!in_flight
	if not DebuffCountOnAny(pyroblast_debuff) > 0 and not InFlightToTarget(pyroblast) Spell(pyroblast)
	#dragons_breath,if=glyph.dragons_breath.enabled
	if Glyph(glyph_of_dragons_breath) Spell(dragons_breath)
	#flamestrike,if=mana.pct>10&remains<2.4
	if ManaPercent() > 10 and target.DebuffRemaining(flamestrike_debuff) < 2.4 Spell(flamestrike)
}

AddFunction FireAoeShortCdActions
{
	unless { target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(pyroblast_debuff) and DebuffCountOnAny(pyroblast_debuff) < Enemies() } and Spell(inferno_blast)
	{
		#call_action_list,name=active_talents
		FireActiveTalentsShortCdActions()
	}
}

AddFunction FireAoeCdActions
{
	unless { target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(pyroblast_debuff) and DebuffCountOnAny(pyroblast_debuff) < Enemies() } and Spell(inferno_blast)
	{
		#call_action_list,name=active_talents
		FireActiveTalentsCdActions()

		unless { BuffPresent(pyroblast_buff) or BuffPresent(pyromaniac_buff) } and Spell(pyroblast)
			or not DebuffCountOnAny(pyroblast_debuff) > 0 and not InFlightToTarget(pyroblast) and Spell(pyroblast)
		{
			#cold_snap,if=glyph.dragons_breath.enabled&!cooldown.dragons_breath.up
			if Glyph(glyph_of_dragons_breath) and not { not SpellCooldown(dragons_breath) > 0 } Spell(cold_snap)
		}
	}
}

# ActionList: FireCombustSequenceActions --> main, shortcd, cd

AddFunction FireCombustSequenceActions
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

	unless ArmorSetBonus(T17 4) and BuffPresent(pyromaniac_buff) and Spell(pyroblast)
		or ArmorSetBonus(T16_caster 4) and BuffPresent(pyroblast_buff) xor BuffPresent(heating_up_buff) and Spell(inferno_blast)
		or not target.DebuffPresent(ignite_debuff) and not { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } and Spell(fireball)
		or BuffPresent(pyroblast_buff) and Spell(pyroblast)
		or Talent(meteor_talent) and SpellCooldownDuration(meteor) - SpellCooldown(meteor) < GCD() * 3 and Spell(inferno_blast)
	{
		#combustion
		Spell(combustion)
	}
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
		UsePotionIntellect()
	}
}

# ActionList: FireCrystalSequenceActions --> main, shortcd, cd

AddFunction FireCrystalSequenceActions
{
	#inferno_blast,cycle_targets=1,if=dot.combustion.ticking&active_dot.combustion<active_enemies+1
	if target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() + 1 Spell(inferno_blast)
	#pyroblast,if=execute_time=gcd.max&pet.prismatic_crystal.remains<gcd.max+travel_time&pet.prismatic_crystal.remains>travel_time
	if ExecuteTime(pyroblast) == GCD() and TotemRemaining(crystal totem=prismatic_crystal) < GCD() + MaxTravelTime(pyroblast) and TotemRemaining(crystal totem=prismatic_crystal) > MaxTravelTime(pyroblast) Spell(pyroblast)
	#call_action_list,name=single_target
	FireSingleTargetActions()
}

AddFunction FireCrystalSequenceShortCdActions
{
	unless target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() + 1 and Spell(inferno_blast)
		or ExecuteTime(pyroblast) == GCD() and TotemRemaining(crystal totem=prismatic_crystal) < GCD() + MaxTravelTime(pyroblast) and TotemRemaining(crystal totem=prismatic_crystal) > MaxTravelTime(pyroblast) and Spell(pyroblast)
	{
		#call_action_list,name=single_target
		FireSingleTargetCdActions()
	}
}

AddFunction FireCrystalSequenceCdActions
{
	unless target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() + 1 and Spell(inferno_blast)
		or ExecuteTime(pyroblast) == GCD() and TotemRemaining(crystal totem=prismatic_crystal) < GCD() + MaxTravelTime(pyroblast) and TotemRemaining(crystal totem=prismatic_crystal) > MaxTravelTime(pyroblast) and Spell(pyroblast)
	{
		#call_action_list,name=single_target
		FireSingleTargetCdActions()
	}
}

# ActionList: FireInitCombustActions --> main, shortcd, cd

AddFunction FireInitCombustActions
{
	#start_pyro_chain,if=talent.meteor.enabled&cooldown.meteor.up&((cooldown.combustion.remains<gcd.max*3&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(meteor_talent) and not SpellCooldown(meteor) > 0 and { SpellCooldown(combustion) < GCD() * 3 and BuffPresent(pyroblast_buff) and { BuffPresent(heating_up_buff) xor { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up&((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 and { SpellCooldown(combustion) < GCD() * 2 and BuffPresent(pyroblast_buff) and { BuffPresent(heating_up_buff) xor { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=talent.prismatic_crystal.enabled&!glyph.combustion.enabled&cooldown.prismatic_crystal.remains>20&((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(prismatic_crystal_talent) and not Glyph(glyph_of_combustion) and SpellCooldown(prismatic_crystal) > 20 and { SpellCooldown(combustion) < GCD() * 2 and BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=!talent.prismatic_crystal.enabled&!talent.meteor.enabled&((cooldown.combustion.remains<gcd.max*4&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)|(buff.pyromaniac.up&cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*(gcd.max+talent.kindling.enabled)))
	if not Talent(prismatic_crystal_talent) and not Talent(meteor_talent) and { SpellCooldown(combustion) < GCD() * 4 and BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * { GCD() + Talent(kindling_talent) } } SetState(pyro_chain 1)
}

AddFunction FireInitCombustShortCdActions
{
	FireInitCombustActions()
}

AddFunction FireInitCombustCdActions
{
	FireInitCombustActions()
}

# ActionList: FireLivingBombActions --> main

AddFunction FireLivingBombActions
{
	#inferno_blast,cycle_targets=1,if=dot.living_bomb.ticking&active_dot.living_bomb<active_enemies
	if target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) < Enemies() Spell(inferno_blast)
	#living_bomb,cycle_targets=1,if=target!=prismatic_crystal&(active_dot.living_bomb=0|(ticking&active_dot.living_bomb=1))&(((!talent.incanters_flow.enabled|incanters_flow_dir<0|buff.incanters_flow.stack=5)&remains<3.6)|((incanters_flow_dir>0|buff.incanters_flow.stack=1)&remains<gcd.max))&target.time_to_die>remains+12
	if not target.Name(prismatic_crystal) and { not DebuffCountOnAny(living_bomb_debuff) > 0 or target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) == 1 } and { { not Talent(incanters_flow_talent) or BuffDirection(incanters_flow_buff) < 0 or BuffStacks(incanters_flow_buff) == 5 } and target.DebuffRemaining(living_bomb_debuff) < 3.6 or { BuffDirection(incanters_flow_buff) > 0 or BuffStacks(incanters_flow_buff) == 1 } and target.DebuffRemaining(living_bomb_debuff) < GCD() } and target.TimeToDie() > target.DebuffRemaining(living_bomb_debuff) + 12 Spell(living_bomb)
}

# ActionList: FirePrecombatActions --> main, shortcd, cd

AddFunction FirePrecombatActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=blackrock_barbecue
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#snapshot_stats
	#pyroblast
	Spell(pyroblast)
}

AddFunction FirePrecombatShortCdActions
{
	unless { BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance)
	{
		# CHANGE: Only suggest Rune of Power if the rune needs to be refreshed prior to pull.
		#rune_of_power
		#Spell(rune_of_power)
		if TotemRemaining(rune_of_power) < 150 Spell(rune_of_power)
	}
}

AddFunction FirePrecombatCdActions
{
	unless { BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance)
		or TotemRemaining(rune_of_power) < 150 and Spell(rune_of_power)
	{
		#mirror_image
		Spell(mirror_image)
		#potion,name=draenic_intellect
		UsePotionIntellect()
	}
}

# ActionList: FireSingleTargetActions --> main, shortcd, cd

AddFunction FireSingleTargetActions
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
	#inferno_blast,if=buff.pyroblast.down&buff.heating_up.up
	if BuffExpires(pyroblast_buff) and BuffPresent(heating_up_buff) Spell(inferno_blast)
	#call_action_list,name=active_talents
	FireActiveTalentsActions()
	#inferno_blast,if=buff.pyroblast.up&buff.heating_up.down&!action.fireball.in_flight
	if BuffPresent(pyroblast_buff) and BuffExpires(heating_up_buff) and not { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } Spell(inferno_blast)
	#fireball
	Spell(fireball)
	#scorch,moving=1
	if Speed() > 0 Spell(scorch)
}

AddFunction FireSingleTargetShortCdActions
{
	unless { target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) < Enemies() } and Spell(inferno_blast)
		or BuffPresent(pyroblast_buff) and BuffRemaining(pyroblast_buff) < ExecuteTime(fireball) and Spell(pyroblast)
		or ArmorSetBonus(T16_caster 2) and BuffPresent(pyroblast_buff) and BuffPresent(potent_flames_buff) and BuffRemaining(potent_flames_buff) < GCD() and Spell(pyroblast)
		or ArmorSetBonus(T17 4) and BuffPresent(pyromaniac_buff) and Spell(pyroblast)
		or BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } and Spell(pyroblast)
		or BuffExpires(pyroblast_buff) and BuffPresent(heating_up_buff) and Spell(inferno_blast)
	{
		#call_action_list,name=active_talents
		FireActiveTalentsShortCdActions()
	}
}

AddFunction FireSingleTargetCdActions
{
	unless { target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) < Enemies() } and Spell(inferno_blast)
		or BuffPresent(pyroblast_buff) and BuffRemaining(pyroblast_buff) < ExecuteTime(fireball) and Spell(pyroblast)
		or ArmorSetBonus(T16_caster 2) and BuffPresent(pyroblast_buff) and BuffPresent(potent_flames_buff) and BuffRemaining(potent_flames_buff) < GCD() and Spell(pyroblast)
		or ArmorSetBonus(T17 4) and BuffPresent(pyromaniac_buff) and Spell(pyroblast)
		or BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and { InFlightToTarget(fireball) or InFlightToTarget(frostfire_bolt) } and Spell(pyroblast)
		or BuffExpires(pyroblast_buff) and BuffPresent(heating_up_buff) and Spell(inferno_blast)
	{
		#call_action_list,name=active_talents
		FireActiveTalentsCdActions()
	}
}

###
### Frost
###
# Based on SimulationCraft profile "Mage_Frost_T17M".
#	class=mage
#	spec=frost
#	talents=3003122
#	glyphs=icy_veins/splitting_ice/cone_of_cold

# ActionList: FrostDefaultActions --> main, shortcd, cd

AddFunction FrostDefaultActions
{
	#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&(cooldown.prismatic_crystal.remains<=gcd.max|pet.prismatic_crystal.active)
	if Talent(prismatic_crystal_talent) and { SpellCooldown(prismatic_crystal) <= GCD() or TotemPresent(prismatic_crystal) } FrostCrystalSequenceActions()
	#call_action_list,name=aoe,if=active_enemies>=4
	if Enemies() >= 4 FrostAoeActions()
	#call_action_list,name=single_target
	FrostSingleTargetActions()
}

AddFunction FrostDefaultShortCdActions
{
	#ice_floes,if=buff.ice_floes.down&(raid_event.movement.distance>0|raid_event.movement.in<action.frostbolt.cast_time)
	if BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < CastTime(frostbolt) } Spell(ice_floes)
	#rune_of_power,if=buff.rune_of_power.remains<cast_time
	if TotemRemaining(rune_of_power) < CastTime(rune_of_power) Spell(rune_of_power)
	# CHANGE: Check for the talent before any of the spell properties for Prismatic Crystal.
	#rune_of_power,if=(cooldown.icy_veins.remains<gcd.max&buff.rune_of_power.remains<20)|(cooldown.prismatic_crystal.remains<gcd.max&buff.rune_of_power.remains<10)
	#if SpellCooldown(icy_veins) < GCD() and TotemRemaining(rune_of_power) < 20 or SpellCooldown(prismatic_crystal) < GCD() and TotemRemaining(rune_of_power) < 10 Spell(rune_of_power)
	if SpellCooldown(icy_veins) < GCD() and TotemRemaining(rune_of_power) < 20 or { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) < GCD() } and TotemRemaining(rune_of_power) < 10 Spell(rune_of_power)
	#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&(cooldown.prismatic_crystal.remains<=gcd.max|pet.prismatic_crystal.active)
	if Talent(prismatic_crystal_talent) and { SpellCooldown(prismatic_crystal) <= GCD() or TotemPresent(prismatic_crystal) } FrostCrystalSequenceShortCdActions()
	#call_action_list,name=aoe,if=active_enemies>=4
	if Enemies() >= 4 FrostAoeShortCdActions()
	#call_action_list,name=single_target
	FrostSingleTargetShortCdActions()
}

AddFunction FrostDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() InterruptActions()
	#time_warp,if=target.health.pct<25|time>5
	if { target.HealthPercent() < 25 or TimeInCombat() > 5 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)
	#mirror_image
	Spell(mirror_image)

	unless BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < CastTime(frostbolt) } and Spell(ice_floes)
		or TotemRemaining(rune_of_power) < CastTime(rune_of_power) and Spell(rune_of_power)
		or { SpellCooldown(icy_veins) < GCD() and TotemRemaining(rune_of_power) < 20 or { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) < GCD() } and TotemRemaining(rune_of_power) < 10 } and Spell(rune_of_power)
	{
		#call_action_list,name=cooldowns,if=time_to_die<24
		if TimeToDie() < 24 FrostCooldownsCdActions()
		#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&(cooldown.prismatic_crystal.remains<=gcd.max|pet.prismatic_crystal.active)
		if Talent(prismatic_crystal_talent) and { SpellCooldown(prismatic_crystal) <= GCD() or TotemPresent(prismatic_crystal) } FrostCrystalSequenceCdActions()
		#call_action_list,name=aoe,if=active_enemies>=4
		if Enemies() >= 4 FrostAoeCdActions()
		#call_action_list,name=single_target
		FrostSingleTargetCdActions()
	}
}

# ActionList: FrostAoeActions --> main, shortcd, cd

AddFunction FrostAoeActions
{
	#frost_bomb,if=remains<action.ice_lance.travel_time&(cooldown.frozen_orb.remains<gcd.max|buff.fingers_of_frost.react=2)
	if target.DebuffRemaining(frost_bomb_debuff) < MaxTravelTime(ice_lance) and { SpellCooldown(frozen_orb) < GCD() or BuffStacks(fingers_of_frost_buff) == 2 } Spell(frost_bomb)
	#ice_lance,if=talent.frost_bomb.enabled&buff.fingers_of_frost.react&debuff.frost_bomb.up
	if Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and target.DebuffPresent(frost_bomb_debuff) Spell(ice_lance)
	#ice_nova
	Spell(ice_nova)
	#blizzard,interrupt_if=cooldown.frozen_orb.up|(talent.frost_bomb.enabled&buff.fingers_of_frost.react=2)
	Spell(blizzard)
}

AddFunction FrostAoeShortCdActions
{
	unless target.DebuffRemaining(frost_bomb_debuff) < MaxTravelTime(ice_lance) and { SpellCooldown(frozen_orb) < GCD() or BuffStacks(fingers_of_frost_buff) == 2 } and Spell(frost_bomb)
	{
		#frozen_orb
		Spell(frozen_orb)

		unless Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and target.DebuffPresent(frost_bomb_debuff) and Spell(ice_lance)
		{
			#comet_storm
			Spell(comet_storm)
		}
	}
}

AddFunction FrostAoeCdActions
{
	#call_action_list,name=cooldowns
	FrostCooldownsCdActions()
}

# ActionList: FrostCooldownsActions --> cd

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
	if BuffPresent(burst_haste_buff any=1) or BuffPresent(icy_veins_buff) UsePotionIntellect()
}

# ActionList: FrostCrystalSequenceActions --> main, shortcd, cd

AddFunction FrostCrystalSequenceActions
{
	# CHANGE: Workaround possible bug in SimulationCraft APL.
	#frost_bomb,if=active_enemies=1&current_target!=prismatic_crystal&remains<10
	#if Enemies() == 1 and not target.Name(prismatic_crystal) and target.DebuffRemaining(frost_bomb_debuff) < 10 Spell(frost_bomb)
	if Enemies() == 1 and not target.Name(prismatic_crystal) and target.DebuffRemaining(frost_bomb_debuff) < MaxTravelTime(ice_lance) Spell(frost_bomb)
	#frost_bomb,if=talent.prismatic_crystal.enabled&current_target=prismatic_crystal&active_enemies>1&!ticking
	if Talent(prismatic_crystal_talent) and target.Name(prismatic_crystal) and Enemies() > 1 and not target.DebuffPresent(frost_bomb_debuff) Spell(frost_bomb)
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
	unless Enemies() == 1 and not target.Name(prismatic_crystal) and target.DebuffRemaining(frost_bomb_debuff) < MaxTravelTime(ice_lance) and Spell(frost_bomb)
	{
		#frozen_orb
		Spell(frozen_orb)
		#prismatic_crystal
		Spell(prismatic_crystal)
	}
}

AddFunction FrostCrystalSequenceCdActions
{
	unless Enemies() == 1 and not target.Name(prismatic_crystal) and target.DebuffRemaining(frost_bomb_debuff) < MaxTravelTime(ice_lance) and Spell(frost_bomb)
		or Spell(frozen_orb)
	{
		#call_action_list,name=cooldowns
		FrostCooldownsCdActions()
	}
}

# ActionList: FrostPrecombatActions --> main, shortcd, cd

AddFunction FrostPrecombatActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=calamari_crepes
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#snapshot_stats
	#frostbolt
	Spell(frostbolt)
}

AddFunction FrostPrecombatShortCdActions
{
	unless { BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance)
	{
		#water_elemental
		if not pet.Present() Spell(water_elemental)
		# CHANGE: Only suggest Rune of Power if the rune needs to be refreshed prior to pull.
		#rune_of_power
		#Spell(rune_of_power)
		if TotemRemaining(rune_of_power) < 150 Spell(rune_of_power)
	}
}

AddFunction FrostPrecombatCdActions
{
	unless { BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) } and Spell(arcane_brilliance)
		or not pet.Present() and Spell(water_elemental)
		or TotemRemaining(rune_of_power) < 150 and Spell(rune_of_power)
	{
		#mirror_image
		Spell(mirror_image)
		#potion,name=draenic_intellect
		UsePotionIntellect()
	}
}

# ActionList: FrostSingleTargetActions --> main, shortcd, cd

AddFunction FrostSingleTargetActions
{
	#ice_lance,if=buff.fingers_of_frost.react&buff.fingers_of_frost.remains<action.frostbolt.execute_time
	if BuffPresent(fingers_of_frost_buff) and BuffRemaining(fingers_of_frost_buff) < ExecuteTime(frostbolt) Spell(ice_lance)
	#frostfire_bolt,if=buff.brain_freeze.react&buff.brain_freeze.remains<action.frostbolt.execute_time
	if BuffPresent(brain_freeze_buff) and BuffRemaining(brain_freeze_buff) < ExecuteTime(frostbolt) Spell(frostfire_bolt)
	# CHANGE: Workaround possible bug in SimulationCraft APL.
	#frost_bomb,if=!talent.prismatic_crystal.enabled&cooldown.frozen_orb.remains<gcd.max&debuff.frost_bomb.remains<10
	#if not Talent(prismatic_crystal_talent) and SpellCooldown(frozen_orb) < GCD() and target.DebuffRemaining(frost_bomb_debuff) < 10 Spell(frost_bomb)
	if not Talent(prismatic_crystal_talent) and SpellCooldown(frozen_orb) < GCD() and target.DebuffRemaining(frost_bomb_debuff) < MaxTravelTime(ice_lance) Spell(frost_bomb)
	#frost_bomb,if=remains<action.ice_lance.travel_time&(buff.fingers_of_frost.react=2|(buff.fingers_of_frost.react&(talent.thermal_void.enabled|buff.fingers_of_frost.remains<gcd.max*2)))
	if target.DebuffRemaining(frost_bomb_debuff) < MaxTravelTime(ice_lance) and { BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and { Talent(thermal_void_talent) or BuffRemaining(fingers_of_frost_buff) < GCD() * 2 } } Spell(frost_bomb)
	#ice_nova,if=time_to_die<10|(charges=2&(!talent.prismatic_crystal.enabled|!cooldown.prismatic_crystal.up))
	if TimeToDie() < 10 or Charges(ice_nova) == 2 and { not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } } Spell(ice_nova)
	#ice_lance,if=buff.fingers_of_frost.react=2|(buff.fingers_of_frost.react&dot.frozen_orb.ticking)
	if BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 Spell(ice_lance)
	#ice_nova,if=(!talent.prismatic_crystal.enabled|(charges=1&cooldown.prismatic_crystal.remains>recharge_time&buff.incanters_flow.stack>3))&(buff.icy_veins.up|(charges=1&cooldown.icy_veins.remains>recharge_time))
	if { not Talent(prismatic_crystal_talent) or Charges(ice_nova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(ice_nova) and BuffStacks(incanters_flow_buff) > 3 } and { BuffPresent(icy_veins_buff) or Charges(ice_nova) == 1 and SpellCooldown(icy_veins) > SpellChargeCooldown(ice_nova) } Spell(ice_nova)
	#frostfire_bolt,if=buff.brain_freeze.react
	if BuffPresent(brain_freeze_buff) Spell(frostfire_bolt)
	#ice_lance,if=set_bonus.tier17_4pc&talent.thermal_void.enabled&talent.mirror_image.enabled&dot.frozen_orb.ticking
	if ArmorSetBonus(T17 4) and Talent(thermal_void_talent) and Talent(mirror_image_talent) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 Spell(ice_lance)
	#ice_lance,if=talent.frost_bomb.enabled&buff.fingers_of_frost.react&debuff.frost_bomb.remains>travel_time&(!talent.thermal_void.enabled|cooldown.icy_veins.remains>8)
	if Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and target.DebuffRemaining(frost_bomb_debuff) > MaxTravelTime(ice_lance) and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins) > 8 } Spell(ice_lance)
	#frostbolt,if=set_bonus.tier17_2pc&buff.ice_shard.up&!(talent.thermal_void.enabled&buff.icy_veins.up&buff.icy_veins.remains<10)
	if ArmorSetBonus(T17 2) and BuffPresent(ice_shard_buff) and not { Talent(thermal_void_talent) and BuffPresent(icy_veins_buff) and BuffRemaining(icy_veins_buff) < 10 } Spell(frostbolt)
	#ice_lance,if=!talent.frost_bomb.enabled&buff.fingers_of_frost.react&(!talent.thermal_void.enabled|cooldown.icy_veins.remains>8)
	if not Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins) > 8 } Spell(ice_lance)
	#frostbolt
	Spell(frostbolt)
	#ice_lance,moving=1
	if Speed() > 0 Spell(ice_lance)
}

AddFunction FrostSingleTargetShortCdActions
{
	# CHANGE: Always suggest summoning the Water Elemental if it's gone, even during combat.
	if not pet.Present() Spell(water_elemental)
	# CHANGE: Suggest pet's Freeze on non-worldboss targets to generate Fingers of Frost.
	if not target.Classification(worldboss) and not BuffPresent(fingers_of_frost_buff) and pet.Present() Spell(pet_freeze)
	unless BuffPresent(fingers_of_frost_buff) and BuffRemaining(fingers_of_frost_buff) < ExecuteTime(frostbolt) and Spell(ice_lance)
		or BuffPresent(brain_freeze_buff) and BuffRemaining(brain_freeze_buff) < ExecuteTime(frostbolt) and Spell(frostfire_bolt)
		or not Talent(prismatic_crystal_talent) and SpellCooldown(frozen_orb) < GCD() and target.DebuffRemaining(frost_bomb_debuff) < MaxTravelTime(ice_lance) and Spell(frost_bomb)
	{
		#frozen_orb,if=!talent.prismatic_crystal.enabled&buff.fingers_of_frost.stack<2&cooldown.icy_veins.remains>45
		if not Talent(prismatic_crystal_talent) and BuffStacks(fingers_of_frost_buff) < 2 and SpellCooldown(icy_veins) > 45 Spell(frozen_orb)

		unless target.DebuffRemaining(frost_bomb_debuff) < MaxTravelTime(ice_lance) and { BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and { Talent(thermal_void_talent) or BuffRemaining(fingers_of_frost_buff) < GCD() * 2 } } and Spell(frost_bomb)
			or { TimeToDie() < 10 or Charges(ice_nova) == 2 and { not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } } } and Spell(ice_nova)
			or { BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 } and Spell(ice_lance)
		{
			#comet_storm
			Spell(comet_storm)

			unless { not Talent(prismatic_crystal_talent) or Charges(ice_nova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(ice_nova) and BuffStacks(incanters_flow_buff) > 3 } and { BuffPresent(icy_veins_buff) or Charges(ice_nova) == 1 and SpellCooldown(icy_veins) > SpellChargeCooldown(ice_nova) } and Spell(ice_nova)
				or BuffPresent(brain_freeze_buff) and Spell(frostfire_bolt)
				or ArmorSetBonus(T17 4) and Talent(thermal_void_talent) and Talent(mirror_image_talent) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 and Spell(ice_lance)
				or Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and target.DebuffRemaining(frost_bomb_debuff) > MaxTravelTime(ice_lance) and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins) > 8 } and Spell(ice_lance)
				or ArmorSetBonus(T17 2) and BuffPresent(ice_shard_buff) and not { Talent(thermal_void_talent) and BuffPresent(icy_veins_buff) and BuffRemaining(icy_veins_buff) < 10 } and Spell(frostbolt)
				or not Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins) > 8 } and Spell(ice_lance)
			{
				#water_jet,if=buff.fingers_of_frost.react=0&!dot.frozen_orb.ticking
				if BuffStacks(fingers_of_frost_buff) == 0 and not SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 and pet.Present() Spell(pet_water_jet)
			}
		}
	}
}

AddFunction FrostSingleTargetCdActions
{
	#call_action_list,name=cooldowns,if=!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>15
	if not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 15 FrostCooldownsCdActions()
}
]]
	OvaleScripts:RegisterScript("MAGE", name, desc, code, "include")
end

do
	local name = "Ovale"	-- The default script.
	local desc = "[6.0] Ovale: Arcane, Fire, Frost"
	local code = [[
# Ovale mage script based on SimulationCraft.

# Mage rotation functions.
Include(ovale_mage)

### Arcane icons.
AddCheckBox(opt_mage_arcane_aoe L(AOE) specialization=arcane default)

AddIcon specialization=arcane help=shortcd enemies=1 checkbox=!opt_mage_arcane_aoe
{
	if InCombat(no) ArcanePrecombatShortCdActions()
	ArcaneDefaultShortCdActions()
}

AddIcon specialization=arcane help=shortcd checkbox=opt_mage_arcane_aoe
{
	if InCombat(no) ArcanePrecombatShortCdActions()
	ArcaneDefaultShortCdActions()
}

AddIcon specialization=arcane help=main enemies=1
{
	if InCombat(no) ArcanePrecombatActions()
	ArcaneDefaultActions()
}

AddIcon specialization=arcane help=aoe checkbox=opt_mage_arcane_aoe
{
	if InCombat(no) ArcanePrecombatActions()
	ArcaneDefaultActions()
}

AddIcon specialization=arcane help=cd enemies=1 checkbox=!opt_mage_arcane_aoe
{
	if InCombat(no) ArcanePrecombatCdActions()
	ArcaneDefaultCdActions()
}

AddIcon specialization=arcane help=cd checkbox=opt_mage_arcane_aoe
{
	if InCombat(no) ArcanePrecombatCdActions()
	ArcaneDefaultCdActions()
}

### Fire icons.
AddCheckBox(opt_mage_fire_aoe L(AOE) specialization=fire default)

AddIcon specialization=fire help=shortcd enemies=1 checkbox=!opt_mage_fire_aoe
{
	if InCombat(no) FirePrecombatShortCdActions()
	FireDefaultShortCdActions()
}

AddIcon specialization=fire help=shortcd checkbox=opt_mage_fire_aoe
{
	if InCombat(no) FirePrecombatShortCdActions()
	FireDefaultShortCdActions()
}

AddIcon specialization=fire help=main enemies=1
{
	if InCombat(no) FirePrecombatActions()
	FireDefaultActions()
}

AddIcon specialization=fire help=aoe checkbox=opt_mage_fire_aoe
{
	if InCombat(no) FirePrecombatActions()
	FireDefaultActions()
}

AddIcon specialization=fire help=cd enemies=1 checkbox=!opt_mage_fire_aoe
{
	if InCombat(no) FirePrecombatCdActions()
	FireDefaultCdActions()
}

AddIcon specialization=fire help=cd checkbox=opt_mage_fire_aoe
{
	if InCombat(no) FirePrecombatCdActions()
	FireDefaultCdActions()
}

### Frost icons.
AddCheckBox(opt_mage_frost_aoe L(AOE) specialization=frost default)

AddIcon specialization=frost help=shortcd enemies=1 checkbox=!opt_mage_frost_aoe
{
	if InCombat(no) FrostPrecombatShortCdActions()
	FrostDefaultShortCdActions()
}

AddIcon specialization=frost help=shortcd checkbox=opt_mage_frost_aoe
{
	if InCombat(no) FrostPrecombatShortCdActions()
	FrostDefaultShortCdActions()
}

AddIcon specialization=frost help=main enemies=1
{
	if InCombat(no) FrostPrecombatActions()
	FrostDefaultActions()
}

AddIcon specialization=frost help=aoe checkbox=opt_mage_frost_aoe
{
	if InCombat(no) FrostPrecombatActions()
	FrostDefaultActions()
}

AddIcon specialization=frost help=cd enemies=1 checkbox=!opt_mage_frost_aoe
{
	if InCombat(no) FrostPrecombatCdActions()
	FrostDefaultCdActions()
}

AddIcon specialization=frost help=cd checkbox=opt_mage_frost_aoe
{
	if InCombat(no) FrostPrecombatCdActions()
	FrostDefaultCdActions()
}
]]
	OvaleScripts:RegisterScript("MAGE", name, desc, code, "script")
end
