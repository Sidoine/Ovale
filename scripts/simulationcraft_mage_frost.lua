local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Mage_Frost_T16M"
	local desc = "[6.0.2] SimulationCraft: Mage_Frost_T16M"
	local code = [[
# Based on SimulationCraft profile "Mage_Frost_T16M".
#	class=mage
#	spec=frost
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#eb!0..211.
#	glyphs=icy_veins/splitting_ice/cone_of_cold

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
	if target.IsFriend(no) and target.IsInterruptible()
	{
		Spell(counterspell)
		if target.Classification(worldboss no)
		{
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

AddFunction IcyVeins
{
	if Glyph(glyph_of_icy_veins) Spell(icy_veins_glyphed)
	if Glyph(glyph_of_icy_veins no) Spell(icy_veins)
}

AddFunction FrostPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#water_elemental
	if pet.Present(no) Spell(water_elemental)
	#snapshot_stats
	#rune_of_power
	Spell(rune_of_power)
	#mirror_image
	Spell(mirror_image)
	#potion,name=jade_serpent
	UsePotionIntellect()
	#frostbolt
	Spell(frostbolt)
}

AddFunction FrostDefaultActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() InterruptActions()
	#blink,if=movement.distance>10
	if 0 > 10 Spell(blink)
	#blazing_speed,if=movement.remains>0
	if 0 > 0 Spell(blazing_speed)
	#time_warp,if=target.health.pct<25|time>5
	if { target.HealthPercent() < 25 or TimeInCombat() > 5 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)
	#mirror_image
	Spell(mirror_image)
	#rune_of_power,if=buff.rune_of_power.remains<cast_time
	if RuneOfPowerRemaining() < CastTime(rune_of_power) Spell(rune_of_power)
	#rune_of_power,if=(cooldown.icy_veins.remains<gcd&buff.rune_of_power.remains<20)|(cooldown.prismatic_crystal.remains<gcd&buff.rune_of_power.remains<10)
	if SpellCooldown(icy_veins icy_veins_glyphed usable=1) < GCD() and RuneOfPowerRemaining() < 20 or SpellCooldown(prismatic_crystal) < GCD() and RuneOfPowerRemaining() < 10 Spell(rune_of_power)
	#call_action_list,name=cooldowns,if=time_to_die<24
	if TimeToDie() < 24 FrostCooldownsActions()
	#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&(cooldown.prismatic_crystal.remains<=action.frozen_orb.gcd|pet.prismatic_crystal.active)
	if Talent(prismatic_crystal_talent) and { SpellCooldown(prismatic_crystal) <= GCD() or TotemPresent(prismatic_crystal) } FrostCrystalSequenceActions()
	#call_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FrostAoeActions()
	#call_action_list,name=single_target
	FrostSingleTargetActions()
}

AddFunction FrostAoeActions
{
	#call_action_list,name=cooldowns
	FrostCooldownsActions()
	#frost_bomb,if=remains<action.ice_lance.travel_time&(cooldown.frozen_orb.remains<gcd|buff.fingers_of_frost.react=2)
	if target.DebuffRemaining(frost_bomb_debuff) < 0.5 and { SpellCooldown(frozen_orb) < GCD() or BuffStacks(fingers_of_frost_buff) == 2 } Spell(frost_bomb)
	#frozen_orb
	Spell(frozen_orb)
	#ice_lance,if=buff.fingers_of_frost.react&debuff.frost_bomb.up
	if BuffPresent(fingers_of_frost_buff) and target.DebuffPresent(frost_bomb_debuff) Spell(ice_lance)
	#comet_storm
	Spell(comet_storm)
	#ice_nova
	Spell(ice_nova)
	#cold_snap,if=glyph.cone_of_cold.enabled&!cooldown.cone_of_cold.up
	if Glyph(glyph_of_cone_of_cold) and not { not SpellCooldown(cone_of_cold) > 0 } Spell(cold_snap)
	#cone_of_cold,if=glyph.cone_of_cold.enabled
	if Glyph(glyph_of_cone_of_cold) Spell(cone_of_cold)
	#blizzard,interrupt_if=cooldown.frozen_orb.up|(talent.frost_bomb.enabled&buff.fingers_of_frost.react=2)
	Spell(blizzard)
	#ice_floes,moving=1
}

AddFunction FrostSingleTargetActions
{
	#call_action_list,name=cooldowns,if=!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>45
	if not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 45 FrostCooldownsActions()
	#ice_lance,if=buff.fingers_of_frost.react&buff.fingers_of_frost.remains<action.frostbolt.execute_time
	if BuffPresent(fingers_of_frost_buff) and BuffRemaining(fingers_of_frost_buff) < ExecuteTime(frostbolt) Spell(ice_lance)
	#frostfire_bolt,if=buff.brain_freeze.react&buff.brain_freeze.remains<action.frostbolt.execute_time
	if BuffPresent(brain_freeze_buff) and BuffRemaining(brain_freeze_buff) < ExecuteTime(frostbolt) Spell(frostfire_bolt)
	#frost_bomb,if=!talent.prismatic_crystal.enabled&cooldown.frozen_orb.remains<gcd&debuff.frost_bomb.remains<10
	if not Talent(prismatic_crystal_talent) and SpellCooldown(frozen_orb) < GCD() and target.DebuffRemaining(frost_bomb_debuff) < 10 Spell(frost_bomb)
	#frozen_orb,if=!talent.prismatic_crystal.enabled&buff.fingers_of_frost.stack<2&cooldown.icy_veins.remains>45
	if not Talent(prismatic_crystal_talent) and BuffStacks(fingers_of_frost_buff) < 2 and SpellCooldown(icy_veins icy_veins_glyphed usable=1) > 45 Spell(frozen_orb)
	#frost_bomb,if=remains<action.ice_lance.travel_time&(buff.fingers_of_frost.react=2|(buff.fingers_of_frost.react&(talent.thermal_void.enabled|buff.fingers_of_frost.remains<gcd*2)))
	if target.DebuffRemaining(frost_bomb_debuff) < 0.5 and { BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and { Talent(thermal_void_talent) or BuffRemaining(fingers_of_frost_buff) < GCD() * 2 } } Spell(frost_bomb)
	#ice_nova,if=time_to_die<10|(charges=2&(!talent.prismatic_crystal.enabled|!cooldown.prismatic_crystal.up))
	if TimeToDie() < 10 or Charges(ice_nova) == 2 and { not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } } Spell(ice_nova)
	#ice_lance,if=buff.fingers_of_frost.react=2|(buff.fingers_of_frost.react&dot.frozen_orb.ticking)
	if BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 Spell(ice_lance)
	#comet_storm
	Spell(comet_storm)
	#ice_lance,if=set_bonus.tier17_4pc&talent.thermal_void.enabled&dot.frozen_orb.ticking
	if ArmorSetBonus(T17 4) and Talent(thermal_void_talent) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 Spell(ice_lance)
	#ice_nova,if=(!talent.prismatic_crystal.enabled|(charges=1&cooldown.prismatic_crystal.remains>recharge_time))&(buff.icy_veins.up|(charges=1&cooldown.icy_veins.remains>recharge_time))
	if { not Talent(prismatic_crystal_talent) or Charges(ice_nova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(ice_nova) } and { BuffPresent(icy_veins_buff) or Charges(ice_nova) == 1 and SpellCooldown(icy_veins icy_veins_glyphed usable=1) > SpellChargeCooldown(ice_nova) } Spell(ice_nova)
	#frostfire_bolt,if=buff.brain_freeze.react
	if BuffPresent(brain_freeze_buff) Spell(frostfire_bolt)
	#ice_lance,if=buff.fingers_of_frost.react&debuff.frost_bomb.remains>travel_time&(!talent.thermal_void.enabled|cooldown.icy_veins.remains>8)
	if BuffPresent(fingers_of_frost_buff) and target.DebuffRemaining(frost_bomb_debuff) > 0.5 and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins icy_veins_glyphed usable=1) > 8 } Spell(ice_lance)
	#frostbolt,if=buff.ice_shard.up&!(talent.thermal_void.enabled&buff.icy_veins.up&buff.icy_veins.remains<10)
	if BuffPresent(ice_shard_buff) and not { Talent(thermal_void_talent) and BuffPresent(icy_veins_buff) and BuffRemaining(icy_veins_buff) < 10 } Spell(frostbolt)
	#ice_lance,if=buff.fingers_of_frost.react&!talent.frost_bomb.enabled&(!talent.thermal_void.enabled|cooldown.icy_veins.remains>8)
	if BuffPresent(fingers_of_frost_buff) and not Talent(frost_bomb_talent) and { not Talent(thermal_void_talent) or SpellCooldown(icy_veins icy_veins_glyphed usable=1) > 8 } Spell(ice_lance)
	#ice_lance,if=talent.thermal_void.enabled&buff.icy_veins.up&buff.icy_veins.remains<6&buff.icy_veins.remains<cooldown.icy_veins.remains
	if Talent(thermal_void_talent) and BuffPresent(icy_veins_buff) and BuffRemaining(icy_veins_buff) < 6 and BuffRemaining(icy_veins_buff) < SpellCooldown(icy_veins icy_veins_glyphed usable=1) Spell(ice_lance)
	#water_jet,if=buff.fingers_of_frost.react=0&!dot.frozen_orb.ticking
	if BuffStacks(fingers_of_frost_buff) == 0 and not SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 Spell(water_jet)
	#frostbolt
	Spell(frostbolt)
	#ice_floes,moving=1
	#ice_lance,moving=1
	if Speed() > 0 Spell(ice_lance)
}

AddFunction FrostCrystalSequenceActions
{
	#frost_bomb,if=active_enemies=1&current_target!=prismatic_crystal&remains<10
	if Enemies() == 1 and target.CreatureType(prismatic_crystal) and target.DebuffRemaining(frost_bomb_debuff) < 10 Spell(frost_bomb)
	#frozen_orb
	Spell(frozen_orb)
	#call_action_list,name=cooldowns
	FrostCooldownsActions()
	#prismatic_crystal
	Spell(prismatic_crystal)
	#frost_bomb,if=active_enemies>1&current_target=prismatic_crystal&!ticking
	if Enemies() > 1 and target.CreatureType(prismatic_crystal) and not target.DebuffPresent(frost_bomb_debuff) Spell(frost_bomb)
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

AddFunction FrostCooldownsActions
{
	#icy_veins
	IcyVeins()
	#blood_fury
	Spell(blood_fury_sp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#potion,name=jade_serpent,if=buff.bloodlust.up|buff.icy_veins.up
	if BuffPresent(burst_haste_buff any=1) or BuffPresent(icy_veins_buff) UsePotionIntellect()
}

AddIcon specialization=frost help=main enemies=1
{
	if InCombat(no) FrostPrecombatActions()
	FrostDefaultActions()
}

AddIcon specialization=frost help=aoe
{
	if InCombat(no) FrostPrecombatActions()
	FrostDefaultActions()
}

### Required symbols
# arcane_brilliance
# arcane_torrent_mana
# berserking
# blazing_speed
# blink
# blizzard
# blood_fury_sp
# brain_freeze_buff
# cold_snap
# comet_storm
# cone_of_cold
# counterspell
# fingers_of_frost_buff
# frost_bomb
# frost_bomb_debuff
# frost_bomb_talent
# frostbolt
# frostfire_bolt
# frozen_orb
# frozen_orb_debuff
# glyph_of_cone_of_cold
# glyph_of_icy_veins
# ice_lance
# ice_nova
# ice_shard_buff
# icy_veins
# icy_veins_buff
# icy_veins_glyphed
# jade_serpent_potion
# mirror_image
# prismatic_crystal
# prismatic_crystal_talent
# quaking_palm
# rune_of_power
# thermal_void_talent
# time_warp
# water_elemental
# water_jet
]]
	OvaleScripts:RegisterScript("MAGE", name, desc, code, "reference")
end
