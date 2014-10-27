local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Mage_Fire_T16M"
	local desc = "[6.0.2] SimulationCraft: Mage_Fire_T16M"
	local code = [[
# Based on SimulationCraft profile "Mage_Fire_T16M".
#	class=mage
#	spec=fire
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#eZ!0..211.
#	glyphs=inferno_blast/combustion/dragons_breath

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

AddFunction FireInitCombustActions
{
	#start_pyro_chain,if=talent.meteor.enabled&cooldown.meteor.up&((cooldown.combustion.remains<gcd.max*3&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(meteor_talent) and not SpellCooldown(meteor) > 0 and { SpellCooldown(combustion) < GCD() * 3 and BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) ^ InFlightToTarget(fireball) or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up&((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(prismatic_crystal_talent) and not SpellCooldown(prismatic_crystal) > 0 and { SpellCooldown(combustion) < GCD() * 2 and BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) ^ InFlightToTarget(fireball) or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=talent.prismatic_crystal.enabled&!glyph.combustion.enabled&cooldown.prismatic_crystal.remains>20&((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	if Talent(prismatic_crystal_talent) and not Glyph(glyph_of_combustion) and SpellCooldown(prismatic_crystal) > 20 and { SpellCooldown(combustion) < GCD() * 2 and BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and InFlightToTarget(fireball) or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * GCD() } SetState(pyro_chain 1)
	#start_pyro_chain,if=!talent.prismatic_crystal.enabled&!talent.meteor.enabled&((cooldown.combustion.remains<gcd.max*4&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)|(buff.pyromaniac.up&cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*(gcd.max+talent.kindling.enabled)))
	if not Talent(prismatic_crystal_talent) and not Talent(meteor_talent) and { SpellCooldown(combustion) < GCD() * 4 and BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and InFlightToTarget(fireball) or BuffPresent(pyromaniac_buff) and SpellCooldown(combustion) < BuffRemaining(pyromaniac_buff) / GCD() * { GCD() + Talent(kindling_talent) } } SetState(pyro_chain 1)
}

AddFunction FireDefaultActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() InterruptActions()
	#blink,if=movement.distance>10
	if 0 > 10 Spell(blink)
	#blazing_speed,if=movement.remains>0
	if 0 > 0 Spell(blazing_speed)
	#time_warp,if=target.health.pct<25|time>5
	if { target.HealthPercent() < 25 or TimeInCombat() > 5 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)
	#rune_of_power,if=buff.rune_of_power.remains<cast_time
	if RuneOfPowerRemaining() < CastTime(rune_of_power) Spell(rune_of_power)
	#call_action_list,name=combust_sequence,if=pyro_chain
	if GetState(pyro_chain) > 0 FireCombustSequenceActions()
	#call_action_list,name=crystal_sequence,if=pet.prismatic_crystal.active
	if TotemPresent(prismatic_crystal) FireCrystalSequenceActions()
	#call_action_list,name=init_combust,if=!pyro_chain
	if not GetState(pyro_chain) > 0 FireInitCombustActions()
	#rune_of_power,if=buff.rune_of_power.remains<action.fireball.execute_time+gcd.max&!(buff.heating_up.up&action.fireball.in_flight)
	if RuneOfPowerRemaining() < ExecuteTime(fireball) + GCD() and not { BuffPresent(heating_up_buff) and InFlightToTarget(fireball) } Spell(rune_of_power)
	#mirror_image,if=!(buff.heating_up.up&action.fireball.in_flight)
	if not { BuffPresent(heating_up_buff) and InFlightToTarget(fireball) } Spell(mirror_image)
	#call_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FireAoeActions()
	#call_action_list,name=single_target
	FireSingleTargetActions()
}

AddFunction FireLivingBombActions
{
	#inferno_blast,cycle_targets=1,if=dot.living_bomb.ticking&active_dot.living_bomb<active_enemies
	if target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) < Enemies() Spell(inferno_blast)
	#living_bomb,cycle_targets=1,if=target!=prismatic_crystal&(active_dot.living_bomb=0|(ticking&active_dot.living_bomb=1))&(((!talent.incanters_flow.enabled|incanters_flow_dir<0|buff.incanters_flow.stack=5)&remains<3.6)|((incanters_flow_dir>0|buff.incanters_flow.stack=1)&remains<gcd.max))&target.time_to_die>remains+12
	if target.CreatureType(prismatic_crystal) and { not DebuffCountOnAny(living_bomb_debuff) > 0 or target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) == 1 } and { { not Talent(incanters_flow_talent) or 0 < 0 or BuffStacks(incanters_flow_buff) == 5 } and target.DebuffRemaining(living_bomb_debuff) < 3.6 or { 0 > 0 or BuffStacks(incanters_flow_buff) == 1 } and target.DebuffRemaining(living_bomb_debuff) < GCD() } and target.TimeToDie() > target.DebuffRemaining(living_bomb_debuff) + 12 Spell(living_bomb)
}

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
	#cold_snap,if=glyph.dragons_breath.enabled&!cooldown.dragons_breath.up
	if Glyph(glyph_of_dragons_breath) and not { not SpellCooldown(dragons_breath) > 0 } Spell(cold_snap)
	#dragons_breath,if=glyph.dragons_breath.enabled
	if Glyph(glyph_of_dragons_breath) Spell(dragons_breath)
	#flamestrike,if=mana.pct>10&remains<2.4
	if ManaPercent() > 10 and target.DebuffRemaining(flamestrike_debuff) < 2.4 Spell(flamestrike)
}

AddFunction FireSingleTargetActions
{
	#inferno_blast,if=(dot.combustion.ticking&active_dot.combustion<active_enemies)|(dot.living_bomb.ticking&active_dot.living_bomb<active_enemies)
	if target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() or target.DebuffPresent(living_bomb_debuff) and DebuffCountOnAny(living_bomb_debuff) < Enemies() Spell(inferno_blast)
	#pyroblast,if=buff.pyroblast.up&buff.pyroblast.remains<action.fireball.execute_time
	if BuffPresent(pyroblast_buff) and BuffRemaining(pyroblast_buff) < ExecuteTime(fireball) Spell(pyroblast)
	#pyroblast,if=buff.pyroblast.up&buff.potent_flames.up&buff.potent_flames.remains<gcd.max
	if BuffPresent(pyroblast_buff) and BuffPresent(potent_flames_buff) and BuffRemaining(potent_flames_buff) < GCD() Spell(pyroblast)
	#pyroblast,if=buff.pyromaniac.react
	if BuffPresent(pyromaniac_buff) Spell(pyroblast)
	#pyroblast,if=buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight
	if BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and InFlightToTarget(fireball) Spell(pyroblast)
	#inferno_blast,if=buff.pyroblast.down&buff.heating_up.up
	if BuffExpires(pyroblast_buff) and BuffPresent(heating_up_buff) Spell(inferno_blast)
	#call_action_list,name=active_talents
	FireActiveTalentsActions()
	#inferno_blast,if=buff.pyroblast.up&buff.heating_up.down&!action.fireball.in_flight
	if BuffPresent(pyroblast_buff) and BuffExpires(heating_up_buff) and not InFlightToTarget(fireball) Spell(inferno_blast)
	#fireball
	Spell(fireball)
	#scorch,moving=1
	if Speed() > 0 Spell(scorch)
}

AddFunction FireActiveTalentsActions
{
	#meteor,if=active_enemies>=5|(glyph.combustion.enabled&(!talent.incanters_flow.enabled|buff.incanters_flow.stack+incanters_flow_dir>=4)&cooldown.meteor.duration-cooldown.combustion.remains<10)
	if Enemies() >= 5 or Glyph(glyph_of_combustion) and { not Talent(incanters_flow_talent) or BuffStacks(incanters_flow_buff) + 0 >= 4 } and SpellCooldownDuration(meteor) - SpellCooldown(combustion) < 10 Spell(meteor)
	#call_action_list,name=living_bomb,if=talent.living_bomb.enabled
	if Talent(living_bomb_talent) FireLivingBombActions()
	#blast_wave,if=(!talent.incanters_flow.enabled|buff.incanters_flow.stack>=4)&(time_to_die<10|!talent.prismatic_crystal.enabled|(charges=1&cooldown.prismatic_crystal.remains>recharge_time)|charges=2|current_target=prismatic_crystal)
	if { not Talent(incanters_flow_talent) or BuffStacks(incanters_flow_buff) >= 4 } and { TimeToDie() < 10 or not Talent(prismatic_crystal_talent) or Charges(blast_wave) == 1 and SpellCooldown(prismatic_crystal) > SpellChargeCooldown(blast_wave) or Charges(blast_wave) == 2 or target.CreatureType(prismatic_crystal) } Spell(blast_wave)
}

AddFunction FireCombustSequenceActions
{
	#stop_pyro_chain,if=cooldown.combustion.duration-cooldown.combustion.remains<15
	if SpellCooldownDuration(combustion) - SpellCooldown(combustion) < 15 SetState(pyro_chain 0)
	#prismatic_crystal
	Spell(prismatic_crystal)
	#blood_fury
	Spell(blood_fury_sp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#potion,name=jade_serpent
	UsePotionIntellect()
	#meteor
	Spell(meteor)
	#pyroblast,if=buff.pyromaniac.up
	if BuffPresent(pyromaniac_buff) Spell(pyroblast)
	#inferno_blast,if=set_bonus.tier16_4pc_caster&(buff.pyroblast.up^buff.heating_up.up)
	if ArmorSetBonus(T16_caster 4) and BuffPresent(pyroblast_buff) ^ BuffPresent(heating_up_buff) Spell(inferno_blast)
	#fireball,if=!dot.ignite.ticking&!in_flight
	if not target.DebuffPresent(ignite_debuff) and not InFlightToTarget(fireball) Spell(fireball)
	#pyroblast,if=buff.pyroblast.up
	if BuffPresent(pyroblast_buff) Spell(pyroblast)
	#inferno_blast,if=talent.meteor.enabled&cooldown.meteor.duration-cooldown.meteor.remains<gcd.max*3
	if Talent(meteor_talent) and SpellCooldownDuration(meteor) - SpellCooldown(meteor) < GCD() * 3 Spell(inferno_blast)
	#combustion
	Spell(combustion)
}

AddFunction FirePrecombatActions
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
	#pyroblast
	Spell(pyroblast)
}

AddFunction FireCrystalSequenceActions
{
	#inferno_blast,cycle_targets=1,if=dot.combustion.ticking&active_dot.combustion<active_enemies+1
	if target.DebuffPresent(combustion_debuff) and DebuffCountOnAny(combustion_debuff) < Enemies() + 1 Spell(inferno_blast)
	#pyroblast,if=execute_time=gcd.max&pet.prismatic_crystal.remains<gcd.max+travel_time&pet.prismatic_crystal.remains>travel_time
	if ExecuteTime(pyroblast) == GCD() and TotemRemaining(prismatic_crystal) < GCD() + 0.5 and TotemRemaining(prismatic_crystal) > 0.5 Spell(pyroblast)
	#call_action_list,name=single_target
	FireSingleTargetActions()
}

AddIcon specialization=fire help=main enemies=1
{
	if not InCombat() FirePrecombatActions()
	FireDefaultActions()
}

AddIcon specialization=fire help=aoe
{
	if not InCombat() FirePrecombatActions()
	FireDefaultActions()
}

### Required symbols
# arcane_brilliance
# arcane_torrent_mana
# berserking
# blast_wave
# blazing_speed
# blink
# blood_fury_sp
# cold_snap
# combustion
# combustion_debuff
# counterspell
# dragons_breath
# fireball
# flamestrike
# flamestrike_debuff
# glyph_of_combustion
# glyph_of_dragons_breath
# heating_up_buff
# ignite_debuff
# incanters_flow_buff
# incanters_flow_talent
# inferno_blast
# jade_serpent_potion
# kindling_talent
# living_bomb
# living_bomb_debuff
# living_bomb_talent
# meteor
# meteor_talent
# mirror_image
# potent_flames_buff
# prismatic_crystal
# prismatic_crystal_talent
# pyroblast
# pyroblast_buff
# pyroblast_debuff
# pyromaniac_buff
# quaking_palm
# rune_of_power
# scorch
# time_warp
]]
	OvaleScripts:RegisterScript("MAGE", name, desc, code, "reference")
end
