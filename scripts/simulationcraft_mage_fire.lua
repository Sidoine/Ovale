local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_mage_fire_t17m"
	local desc = "[6.1] SimulationCraft: Mage_Fire_T17M"
	local code = [[
# Based on SimulationCraft profile "Mage_Fire_T17M".
#	class=mage
#	spec=fire
#	talents=3003322
#	glyphs=inferno_blast/combustion/dragons_breath

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)

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
	#food,type=pickled_eel
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
# draenic_intellect_potion
# dragons_breath
# fireball
# flamestrike
# flamestrike_debuff
# frostfire_bolt
# glyph_of_combustion
# glyph_of_dragons_breath
# heating_up_buff
# ice_floes
# ice_floes_buff
# ignite_debuff
# incanters_flow_buff
# incanters_flow_talent
# inferno_blast
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
	OvaleScripts:RegisterScript("MAGE", "fire", name, desc, code, "script")
end
