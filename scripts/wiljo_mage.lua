local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Wiljo"
	local desc = "[5.4] Wiljo: Frost"
	local code = [[
##
##Please direct any questions, comments or suggestions to the Ovale mage forum:
##   http://wow.curseforge.com/addons/ovale/forum/mage/
##
##Last updated: 2013-12-18

Include(ovale_common)
Include(ovale_mage_spells)

AddFunction BrainFreeze
{
	if BuffPresent(brain_freeze_buff) and BuffStacks(fingers_of_frost_buff more 1) Spell(ice_lance)
	Spell(frostfire_bolt)
}

AddFunction BrainFreezeCD
{
	if BuffPresent(brain_freeze_buff) and BuffStacks(fingers_of_frost_buff more 1) Spell(ice_lance)
	Spell(frostfire_bolt)
}

AddFunction FfbBeforeMageBombRefresh
{
	if TalentPoints(nether_tempest_talent)
	{
		if BuffPresent(brain_freeze_buff) and target.TicksRemain(nether_tempest_debuff less 2) Spell(frostfire_bolt)
	}

	if TalentPoints(living_bomb_talent)
	{
		if BuffPresent(brain_freeze_buff) and target.TicksRemain(living_bomb_debuff less 2) Spell(frostfire_bolt)
	}

	if TalentPoints(frost_bomb_talent)
	{
		if BuffPresent(brain_freeze_buff) and {target.TimeToDie() > {CastTime(frost_bomb) + target.TickTime(frost_bomb_debuff)}}  Spell(frostfire_bolt)
	}
}

AddFunction MageBomb
{
	if TalentPoints(nether_tempest_talent)
	{
		#/nether_tempest,if=(!ticking|remains<tick_time)&target.time_to_die>6
		if {not target.DebuffPresent(nether_tempest_debuff) or target.TicksRemain(nether_tempest_debuff less 2)} and target.TimeToDie(more 6) Spell(nether_tempest)
	}

	if TalentPoints(living_bomb_talent)
	{
		#/living_bomb,if=(!ticking|remains<tick_time)&target.time_to_die>tick_time*3
		if not target.DebuffPresent(living_bomb_debuff) Spell(living_bomb)
		if {target.TicksRemain(living_bomb_debuff) < target.TickTime(living_bomb_debuff)} and {target.TimeToDie() > {target.TickTime(living_bomb_debuff) * 3}} Spell(living_bomb)
		#if not target.DebuffPresent(living_bomb_debuff) or target.TicksRemain(living_bomb_debuff less 2) Spell(living_bomb)
	}

	if TalentPoints(frost_bomb_talent)
	{
		#/frost_bomb,if=target.time_to_die>cast_time+tick_time
		if not target.DebuffPresent(frost_bomb_debuff) or {target.TimeToDie() > {CastTime(frost_bomb) + target.TickTime(frost_bomb_debuff)}}  Spell(frost_bomb)
	}
}

AddFunction TierTwoTalent
{
	if TalentPoints(temporal_shield_talent)
	{
		if SpellCooldown(temporal_shield more 0) SpellCooldown(temporal_shield)
		if SpellCooldown(temporal_shield equal 0) Spell(temporal_shield)
	}

	if TalentPoints(ice_barrier_talent)
	{
		if SpellCooldown(ice_barrier more 0) SpellCooldown(ice_barrier)
		if SpellCooldown(ice_barrier equal 0) Spell(ice_barrier)
	}
}

AddFunction TierSixTalent
{
	if TalentPoints(invocation_talent)
	{
		#/evocation,if=(buff.invokers_energy.down|mana.pct<20)&buff.alter_time.down
		unless BuffPresent(evocation_buff)
		{
			if BuffRemains(invokers_energy_buff atMost 4) and BuffExpires(alter_time_buff) Spell(evocation)
		}
	}

	if TalentPoints(rune_of_power_talent)
	{
		#/rune_of_power,if=buff.rune_of_power.remains<cast_time&buff.alter_time.down
		if RuneOfPowerRemains() < CastTime(rune_of_power) and BuffExpires(alter_time_buff) Spell(rune_of_power)
	}

	if TalentPoints(incanters_ward_talent)
	{
		#/incanters_ward,if=buff.incanters_ward.down&buff.alter_time.down
		if BuffExpires(incanters_ward_buff) and BuffExpires(alter_time_buff) Spell(incanters_ward)
	}
}

AddFunction UseItems
{
	Item(HandsSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction UseRacialInterrupt
{
	if not target.Classification(worldboss) Spell(quaking_palm)
	Spell(arcane_torrent_mana)
}

AddFunction Interrupt
{
	Spell(counterspell)
	if not target.Classification(worldboss) Spell(deep_freeze usable=1)
	UseRacialInterrupt()
}

AddIcon specialization=frost help=offgcd
{
	#/counterspell,if=target.debuff.casting.react
	if not target.IsFriend() and target.IsInterruptible() Interrupt()

	#/spellsteal
	if target.BuffStealable() Spell(spellsteal)

	#/water_elemental:freeze,if=buff.alter_time.down&buff.fingers_of_frost.stack<2
	unless target.Classification(worldboss)
	{
		if BuffExpires(alter_time_buff) and BuffStacks(fingers_of_frost_buff less 2) Spell(water_elemental_freeze)
	}

	#/time_warp,if=target.health.pct<25|time>5
	if InCombat() and {target.HealthPercent(less 25) or TimeInCombat(more 5)}
	{
		if BuffExpires(burst_haste any=1) and DebuffExpires(burst_haste_debuff) Spell(time_warp)
	}

	#/mana_gem,if=mana.pct<84&buff.alter_time.down
	if ManaPercent(less 84) and BuffExpires(alter_time_buff) UseManaGem()
}

AddIcon specialization=frost help=main
{
	if not InCombat()
	{
		#/arcane_brilliance
		unless BuffPresent(spell_power_multiplier any=1) or BuffPresent(critical_strike any=1) Spell(arcane_brilliance)

		#/armor
		unless BuffPresent(frost_armor) or BuffPresent(molten_armor) or BuffPresent(mage_armor) Spell(frost_armor)

		#/water_elemental
		if pet.Present(no) Spell(water_elemental)

		#/conjure_mana_gem,if=mana_gem_charges<3&target.debuff.invulnerable.react
		ConjureManaGem()
	}

	if TalentPoints(cold_snap_talent)
	{
		#cold_snap,if=health.pct<30
		if HealthPercent(less 30) Spell(cold_snap)
	}

	#/frostfire_bolt,if=buff.alter_time.up&buff.brain_freeze.up # Also cast if proc present and has <=5 remaining
	if BuffPresent(brain_freeze_buff)
	{
		if BuffPresent(alter_time_buff) or BuffRemains(brain_freeze_buff atMost 5) BrainFreezeCD()
	}

	#/ice_lance,if=buff.alter_time.up&buff.fingers_of_frost.up
	if BuffPresent(fingers_of_frost_buff)
	{
		if BuffPresent(alter_time_buff) or BuffRemains(fingers_of_frost_buff atMost 5) Spell(ice_lance)
	}

	#Cast Frostfire if Brainfreeze is present before new bomb cast
	FfbBeforeMageBombRefresh()

	#/mage_bomb
	MageBomb()

	#/frostfire_bolt,if=buff.brain_freeze.react&cooldown.icy_veins.remains>2
	if BuffPresent(brain_freeze_buff) BrainFreeze()

	#/ice_lance,if=buff.fingers_of_frost.react&cooldown.icy_veins.remains>2
	if BuffPresent(fingers_of_frost_buff) Spell(ice_lance)

	#/frostbolt
	Spell(frostbolt)
}

AddIcon specialization=frost help=cd
{
	#/evocation,if=mana.pct<20&buff.alter_time.down
	if ManaPercent(less 20) and BuffExpires(alter_time_buff) Spell(evocation)

	#/invocation
	TierSixTalent()

	#/frozen_orb,if=!buff.fingers_of_frost.react
	unless BuffPresent(fingers_of_frost_buff) Spell(frozen_orb)

	#/icy_veins,if=time_to_bloodlust>180&((buff.brain_freeze.react|buff.fingers_of_frost.react|target.time_to_die<22),moving=0
	#if BuffPresent(brain_freeze_buff) or BuffPresent(fingers_of_frost_buff) or target.TimeToDie(atMost 22) Spell(icy_veins)
	if BuffPresent(brain_freeze_buff) and BuffPresent(fingers_of_frost_buff) IcyVeins()
	if target.TimeToDie(less 22) IcyVeins()

	#/alter_time,if=buff.alter_time.down&buff.icy_veins.up
	if BuffExpires(alter_time_buff) and BuffPresent(icy_veins_buff) Spell(alter_time_activate)

	#/mirror_image
	Spell(mirror_image)

	#/use_item,name=gloves,sync=alter_time_activate,if=buff.alter_time.down
	UseItems()
}

AddIcon help=cd size=small
{
	TierTwoTalent()
}

AddIcon help=cd size=small
{
	Spell(deep_freeze usable=1)
}
]]

	OvaleScripts:RegisterScript("MAGE", name, desc, code, "script")
end
