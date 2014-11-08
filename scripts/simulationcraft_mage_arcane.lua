local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Mage_Arcane_T16M"
	local desc = "[6.0] SimulationCraft: Mage_Arcane_T16M"
	local code = [[
# Based on SimulationCraft profile "Mage_Arcane_T16M".
#	class=mage
#	spec=arcane
#	talents=3003120
#	glyphs=arcane_power/cone_of_cold

Include(ovale_common)
Include(ovale_mage_spells)

AddCheckBox(opt_potion_intellect ItemName(jade_serpent_potion) default)
AddCheckBox(opt_time_warp SpellName(time_warp) default)

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(jade_serpent_potion usable=1)
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

AddFunction ArcaneCooldownsActions
{
	#arcane_power
	Spell(arcane_power)
	#blood_fury
	Spell(blood_fury_sp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#potion,name=jade_serpent,if=buff.arcane_power.up&(!talent.prismatic_crystal.enabled|pet.prismatic_crystal.active)
	if BuffPresent(arcane_power_buff) and { not Talent(prismatic_crystal_talent) or TotemPresent(crystal totem=prismatic_crystal) } UsePotionIntellect()
}

AddFunction ArcaneAoeActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsActions()
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

AddFunction ArcaneCrystalSequenceActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsActions()
	#nether_tempest,if=buff.arcane_charge.stack=4&!ticking&pet.prismatic_crystal.remains>8
	if DebuffStacks(arcane_charge_debuff) == 4 and not target.DebuffPresent(nether_tempest_debuff) and TotemRemaining(crystal totem=prismatic_crystal) > 8 Spell(nether_tempest)
	#call_action_list,name=burn
	ArcaneBurnActions()
}

AddFunction ArcaneConserveActions
{
	#call_action_list,name=cooldowns,if=time_to_die<30|(buff.arcane_charge.stack=4&(!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>15))
	if TimeToDie() < 30 or DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 15 } ArcaneCooldownsActions()
	#arcane_missiles,if=buff.arcane_missiles.react=3|(talent.overpowered.enabled&buff.arcane_power.up&buff.arcane_power.remains<action.arcane_blast.execute_time)
	if { BuffStacks(arcane_missiles_buff) == 3 or Talent(overpowered_talent) and BuffPresent(arcane_power_buff) and BuffRemaining(arcane_power_buff) < ExecuteTime(arcane_blast) } and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#arcane_missiles,if=set_bonus.tier17_4pc&buff.arcane_instability.react&buff.arcane_instability.remains<action.arcane_blast.execute_time
	if ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#nether_tempest,cycle_targets=1,if=target!=prismatic_crystal&buff.arcane_charge.stack=4&(active_dot.nether_tempest=0|(ticking&remains<3.6))
	if not target.Name("Prismatic Crystal") and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } Spell(nether_tempest)
	#supernova,if=time_to_die<8|(charges=2&(buff.arcane_power.up|!cooldown.arcane_power.up)&(!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>8))
	if TimeToDie() < 8 or Charges(supernova) == 2 and { BuffPresent(arcane_power_buff) or not { not SpellCooldown(arcane_power) > 0 } } and { not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 8 } Spell(supernova)
	#arcane_orb,if=buff.arcane_charge.stack<2
	if DebuffStacks(arcane_charge_debuff) < 2 Spell(arcane_orb)
	#presence_of_mind,if=mana.pct>96
	if ManaPercent() > 96 Spell(presence_of_mind)
	#arcane_blast,if=buff.arcane_charge.stack=4&mana.pct>93
	if DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 Spell(arcane_blast)
	#arcane_missiles,if=buff.arcane_charge.stack=4&(!talent.overpowered.enabled|cooldown.arcane_power.remains>10*spell_haste)
	if DebuffStacks(arcane_charge_debuff) == 4 and { not Talent(overpowered_talent) or SpellCooldown(arcane_power) > 10 * SpellHaste() / 100 } and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#supernova,if=mana.pct<96&(buff.arcane_missiles.stack<2|buff.arcane_charge.stack=4)&(buff.arcane_power.up|(charges=1&cooldown.arcane_power.remains>recharge_time))&(!talent.prismatic_crystal.enabled|current_target=prismatic_crystal|(charges=1&cooldown.prismatic_crystal.remains>recharge_time+8))
	if ManaPercent() < 96 and { BuffStacks(arcane_missiles_buff) < 2 or DebuffStacks(arcane_charge_debuff) == 4 } and { BuffPresent(arcane_power_buff) or Charges(supernova) == 1 and SpellCooldown(arcane_power) > SpellChargeCooldown(supernova) } and { not Talent(prismatic_crystal_talent) or target.Name("Prismatic Crystal") or Charges(supernova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(supernova) + 8 } Spell(supernova)
	#nether_tempest,cycle_targets=1,if=target!=prismatic_crystal&buff.arcane_charge.stack=4&(active_dot.nether_tempest=0|(ticking&remains<(10-3*talent.arcane_orb.enabled)*spell_haste))
	if not target.Name("Prismatic Crystal") and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < { 10 - 3 * Talent(arcane_orb_talent) } * SpellHaste() / 100 } Spell(nether_tempest)
	#arcane_barrage,if=buff.arcane_charge.stack=4
	if DebuffStacks(arcane_charge_debuff) == 4 Spell(arcane_barrage)
	#presence_of_mind,if=buff.arcane_charge.stack<2
	if DebuffStacks(arcane_charge_debuff) < 2 Spell(presence_of_mind)
	#arcane_blast
	Spell(arcane_blast)
	#arcane_barrage,moving=1
	if Speed() > 0 Spell(arcane_barrage)
}

AddFunction ArcanePrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#snapshot_stats
	#rune_of_power
	Spell(rune_of_power)
	#mirror_image
	Spell(mirror_image)
	#potion,name=jade_serpent
	UsePotionIntellect()
	#arcane_blast
	Spell(arcane_blast)
}

AddFunction ArcaneDefaultActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() InterruptActions()
	#blink,if=movement.distance>10
	if 0 > 10 Spell(blink)
	#blazing_speed,if=movement.remains>0
	if 0 > 0 Spell(blazing_speed)
	#cold_snap,if=health.pct<30
	if HealthPercent() < 30 Spell(cold_snap)
	#time_warp,if=target.health.pct<25|time>5
	if { target.HealthPercent() < 25 or TimeInCombat() > 5 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)
	#ice_floes,if=buff.ice_floes.down&(raid_event.movement.distance>0|raid_event.movement.in<action.arcane_missiles.cast_time)
	if BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < CastTime(arcane_missiles) } Spell(ice_floes)
	#rune_of_power,if=buff.rune_of_power.remains<cast_time
	if RuneOfPowerRemaining() < CastTime(rune_of_power) Spell(rune_of_power)
	#mirror_image
	Spell(mirror_image)
	#cold_snap,if=buff.presence_of_mind.down&cooldown.presence_of_mind.remains>75
	if BuffExpires(presence_of_mind_buff) and SpellCooldown(presence_of_mind) > 75 Spell(cold_snap)
	#call_action_list,name=init_crystal,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up
	if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 ArcaneInitCrystalActions()
	#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&pet.prismatic_crystal.active
	if Talent(prismatic_crystal_talent) and TotemPresent(crystal totem=prismatic_crystal) ArcaneCrystalSequenceActions()
	#call_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 ArcaneAoeActions()
	#call_action_list,name=burn,if=time_to_die<mana.pct*0.35*spell_haste|cooldown.evocation.remains<=(mana.pct-30)*0.3*spell_haste|(buff.arcane_power.up&cooldown.evocation.remains<=(mana.pct-30)*0.4*spell_haste)
	if TimeToDie() < ManaPercent() * 0.35 * SpellHaste() / 100 or SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.3 * SpellHaste() / 100 or BuffPresent(arcane_power_buff) and SpellCooldown(evocation) <= { ManaPercent() - 30 } * 0.4 * SpellHaste() / 100 ArcaneBurnActions()
	#call_action_list,name=conserve
	ArcaneConserveActions()
}

AddFunction ArcaneInitCrystalActions
{
	#call_action_list,name=conserve,if=buff.arcane_charge.stack<4
	if DebuffStacks(arcane_charge_debuff) < 4 ArcaneConserveActions()
	#prismatic_crystal,if=buff.arcane_charge.stack=4&cooldown.arcane_power.remains<0.5
	if DebuffStacks(arcane_charge_debuff) == 4 and SpellCooldown(arcane_power) < 0.5 Spell(prismatic_crystal)
	#prismatic_crystal,if=glyph.arcane_power.enabled&buff.arcane_charge.stack=4&cooldown.arcane_power.remains>45
	if Glyph(glyph_of_arcane_power) and DebuffStacks(arcane_charge_debuff) == 4 and SpellCooldown(arcane_power) > 45 Spell(prismatic_crystal)
}

AddFunction ArcaneBurnActions
{
	#call_action_list,name=cooldowns
	ArcaneCooldownsActions()
	#arcane_missiles,if=buff.arcane_missiles.react=3
	if BuffStacks(arcane_missiles_buff) == 3 and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#arcane_missiles,if=set_bonus.tier17_4pc&buff.arcane_instability.react&buff.arcane_instability.remains<action.arcane_blast.execute_time
	if ArmorSetBonus(T17 4) and BuffPresent(arcane_instability_buff) and BuffRemaining(arcane_instability_buff) < ExecuteTime(arcane_blast) and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#supernova,if=time_to_die<8|charges=2
	if TimeToDie() < 8 or Charges(supernova) == 2 Spell(supernova)
	#nether_tempest,cycle_targets=1,if=target!=prismatic_crystal&buff.arcane_charge.stack=4&(active_dot.nether_tempest=0|(ticking&remains<3.6))
	if not target.Name("Prismatic Crystal") and DebuffStacks(arcane_charge_debuff) == 4 and { not DebuffCountOnAny(nether_tempest_debuff) > 0 or target.DebuffPresent(nether_tempest_debuff) and target.DebuffRemaining(nether_tempest_debuff) < 3.6 } Spell(nether_tempest)
	#arcane_orb,if=buff.arcane_charge.stack<4
	if DebuffStacks(arcane_charge_debuff) < 4 Spell(arcane_orb)
	#supernova,if=current_target=prismatic_crystal
	if target.Name("Prismatic Crystal") Spell(supernova)
	#presence_of_mind,if=mana.pct>96
	if ManaPercent() > 96 Spell(presence_of_mind)
	#arcane_blast,if=buff.arcane_charge.stack=4&mana.pct>93
	if DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() > 93 Spell(arcane_blast)
	#arcane_missiles,if=buff.arcane_charge.stack=4
	if DebuffStacks(arcane_charge_debuff) == 4 and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#supernova,if=mana.pct<96
	if ManaPercent() < 96 Spell(supernova)
	#call_action_list,name=conserve,if=cooldown.evocation.duration-cooldown.evocation.remains<5
	if SpellCooldownDuration(evocation) - SpellCooldown(evocation) < 5 ArcaneConserveActions()
	#evocation,interrupt_if=mana.pct>92,if=time_to_die>10&mana.pct<50
	if TimeToDie() > 10 and ManaPercent() < 50 Spell(evocation)
	#presence_of_mind
	Spell(presence_of_mind)
	#arcane_blast
	Spell(arcane_blast)
}

AddIcon specialization=arcane help=main enemies=1
{
	if not InCombat() ArcanePrecombatActions()
	ArcaneDefaultActions()
}

AddIcon specialization=arcane help=aoe
{
	if not InCombat() ArcanePrecombatActions()
	ArcaneDefaultActions()
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
# evocation
# glyph_of_arcane_power
# glyph_of_cone_of_cold
# ice_floes
# ice_floes_buff
# jade_serpent_potion
# mirror_image
# nether_tempest
# nether_tempest_debuff
# overpowered_talent
# presence_of_mind
# presence_of_mind_buff
# prismatic_crystal
# prismatic_crystal_talent
# quaking_palm
# rune_of_power
# supernova
# time_warp
]]
	OvaleScripts:RegisterScript("MAGE", name, desc, code, "reference")
end
