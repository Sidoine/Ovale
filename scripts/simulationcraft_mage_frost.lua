local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Mage_Frost_T16M"
	local desc = "[6.0] SimulationCraft: Mage_Frost_T16M"
	local code = [[
# Based on SimulationCraft profile "Mage_Frost_T16M".
#	class=mage
#	spec=frost
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#eb!2..211.
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

AddFunction FrostPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#water_elemental
	if not pet.Present() Spell(water_elemental)
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
	#ice_floes,if=buff.ice_floes.down&(raid_event.movement.distance>0|raid_event.movement.in<action.frostbolt.cast_time)
	if BuffExpires(ice_floes_buff) and { 0 > 0 or 600 < CastTime(frostbolt) } Spell(ice_floes)
	#rune_of_power,if=buff.rune_of_power.remains<cast_time
	if RuneOfPowerRemaining() < CastTime(rune_of_power) Spell(rune_of_power)
	#rune_of_power,if=(cooldown.icy_veins.remains<gcd.max&buff.rune_of_power.remains<20)|(cooldown.prismatic_crystal.remains<gcd.max&buff.rune_of_power.remains<10)
	if SpellCooldown(icy_veins) < GCD() and RuneOfPowerRemaining() < 20 or SpellCooldown(prismatic_crystal) < GCD() and RuneOfPowerRemaining() < 10 Spell(rune_of_power)
	#call_action_list,name=cooldowns,if=time_to_die<24
	if TimeToDie() < 24 FrostCooldownsActions()
	#call_action_list,name=crystal_sequence,if=talent.prismatic_crystal.enabled&(cooldown.prismatic_crystal.remains<=gcd.max|pet.prismatic_crystal.active)
	if Talent(prismatic_crystal_talent) and { SpellCooldown(prismatic_crystal) <= GCD() or TotemPresent(crystal totem=prismatic_crystal) } FrostCrystalSequenceActions()
	#call_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FrostAoeActions()
	#call_action_list,name=single_target
	FrostSingleTargetActions()
}

AddFunction FrostAoeActions
{
	#call_action_list,name=cooldowns
	FrostCooldownsActions()
	#frost_bomb,if=remains<action.ice_lance.travel_time&(cooldown.frozen_orb.remains<gcd.max|buff.fingers_of_frost.react=2)
	if target.DebuffRemaining(frost_bomb_debuff) < MaxTravelTime(ice_lance) and { SpellCooldown(frozen_orb) < GCD() or BuffStacks(fingers_of_frost_buff) == 2 } Spell(frost_bomb)
	#frozen_orb
	Spell(frozen_orb)
	#ice_lance,if=talent.frost_bomb.enabled&buff.fingers_of_frost.react&debuff.frost_bomb.up
	if Talent(frost_bomb_talent) and BuffPresent(fingers_of_frost_buff) and target.DebuffPresent(frost_bomb_debuff) Spell(ice_lance)
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
}

AddFunction FrostSingleTargetActions
{
	#call_action_list,name=cooldowns,if=!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>45
	if not Talent(prismatic_crystal_talent) or SpellCooldown(prismatic_crystal) > 45 FrostCooldownsActions()
	#ice_lance,if=buff.fingers_of_frost.react&buff.fingers_of_frost.remains<action.frostbolt.execute_time
	if BuffPresent(fingers_of_frost_buff) and BuffRemaining(fingers_of_frost_buff) < ExecuteTime(frostbolt) Spell(ice_lance)
	#frostfire_bolt,if=buff.brain_freeze.react&buff.brain_freeze.remains<action.frostbolt.execute_time
	if BuffPresent(brain_freeze_buff) and BuffRemaining(brain_freeze_buff) < ExecuteTime(frostbolt) Spell(frostfire_bolt)
	#frost_bomb,if=!talent.prismatic_crystal.enabled&cooldown.frozen_orb.remains<gcd.max&debuff.frost_bomb.remains<10
	if not Talent(prismatic_crystal_talent) and SpellCooldown(frozen_orb) < GCD() and target.DebuffRemaining(frost_bomb_debuff) < 10 Spell(frost_bomb)
	#frozen_orb,if=!talent.prismatic_crystal.enabled&buff.fingers_of_frost.stack<2&cooldown.icy_veins.remains>45
	if not Talent(prismatic_crystal_talent) and BuffStacks(fingers_of_frost_buff) < 2 and SpellCooldown(icy_veins) > 45 Spell(frozen_orb)
	#frost_bomb,if=remains<action.ice_lance.travel_time&(buff.fingers_of_frost.react=2|(buff.fingers_of_frost.react&(talent.thermal_void.enabled|buff.fingers_of_frost.remains<gcd.max*2)))
	if target.DebuffRemaining(frost_bomb_debuff) < MaxTravelTime(ice_lance) and { BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and { Talent(thermal_void_talent) or BuffRemaining(fingers_of_frost_buff) < GCD() * 2 } } Spell(frost_bomb)
	#ice_nova,if=time_to_die<10|(charges=2&(!talent.prismatic_crystal.enabled|!cooldown.prismatic_crystal.up))
	if TimeToDie() < 10 or Charges(ice_nova) == 2 and { not Talent(prismatic_crystal_talent) or not { not SpellCooldown(prismatic_crystal) > 0 } } Spell(ice_nova)
	#ice_lance,if=buff.fingers_of_frost.react=2|(buff.fingers_of_frost.react&dot.frozen_orb.ticking)
	if BuffStacks(fingers_of_frost_buff) == 2 or BuffPresent(fingers_of_frost_buff) and SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 Spell(ice_lance)
	#comet_storm
	Spell(comet_storm)
	#ice_nova,if=(!talent.prismatic_crystal.enabled|(charges=1&cooldown.prismatic_crystal.remains>recharge_time))&(buff.icy_veins.up|(charges=1&cooldown.icy_veins.remains>recharge_time))
	if { not Talent(prismatic_crystal_talent) or Charges(ice_nova) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(ice_nova) } and { BuffPresent(icy_veins_buff) or Charges(ice_nova) == 1 and SpellCooldown(icy_veins) > SpellChargeCooldown(ice_nova) } Spell(ice_nova)
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
	#ice_lance,if=talent.thermal_void.enabled&talent.mirror_image.enabled&buff.icy_veins.up&buff.icy_veins.remains<6&buff.icy_veins.remains<cooldown.icy_veins.remains
	if Talent(thermal_void_talent) and Talent(mirror_image_talent) and BuffPresent(icy_veins_buff) and BuffRemaining(icy_veins_buff) < 6 and BuffRemaining(icy_veins_buff) < SpellCooldown(icy_veins) Spell(ice_lance)
	#water_jet,if=buff.fingers_of_frost.react=0&!dot.frozen_orb.ticking
	if BuffStacks(fingers_of_frost_buff) == 0 and not SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 Spell(water_jet)
	#frostbolt
	Spell(frostbolt)
	#ice_lance,moving=1
	if Speed() > 0 Spell(ice_lance)
}

AddFunction FrostCrystalSequenceActions
{
	#frost_bomb,if=active_enemies=1&current_target!=prismatic_crystal&remains<10
	if Enemies() == 1 and not target.Name("Prismatic Crystal") and target.DebuffRemaining(frost_bomb_debuff) < 10 Spell(frost_bomb)
	#frozen_orb
	Spell(frozen_orb)
	#call_action_list,name=cooldowns
	FrostCooldownsActions()
	#prismatic_crystal
	Spell(prismatic_crystal)
	#frost_bomb,if=talent.prismatic_crystal.enabled&current_target=prismatic_crystal&active_enemies>1&!ticking
	if Talent(prismatic_crystal_talent) and target.Name("Prismatic Crystal") and Enemies() > 1 and not target.DebuffPresent(frost_bomb_debuff) Spell(frost_bomb)
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
	Spell(icy_veins)
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
	if not InCombat() FrostPrecombatActions()
	FrostDefaultActions()
}

AddIcon specialization=frost help=aoe
{
	if not InCombat() FrostPrecombatActions()
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
# ice_floes
# ice_floes_buff
# ice_lance
# ice_nova
# ice_shard_buff
# icy_veins
# icy_veins_buff
# jade_serpent_potion
# mirror_image
# mirror_image_talent
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
