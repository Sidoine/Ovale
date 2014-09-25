local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Mage_Frost_T16H"
	local desc = "[5.4] SimulationCraft: Mage_Frost_T16H"
	local code = [[
# Based on SimulationCraft profile "Mage_Frost_T16H".
#	class=mage
#	spec=frost
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#eb!0...11
#	glyphs=evocation/icy_veins/splitting_ice

Include(ovale_common)
Include(ovale_mage_spells)

AddCheckBox(opt_potion_intellect ItemName(jade_serpent_potion) default)
AddCheckBox(opt_time_warp SpellName(time_warp) default)

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(jade_serpent_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
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

AddFunction ConjureManaGem
{
	if Glyph(glyph_of_mana_gem) and ItemCharges(brilliant_mana_gem) < 10 Spell(conjure_brilliant_mana_gem)
	if Glyph(glyph_of_mana_gem no) and ItemCharges(mana_gem) < 10 Spell(conjure_mana_gem)
}

AddFunction UseManaGem
{
	if Glyph(glyph_of_mana_gem) Item(brilliant_mana_gem)
	if Glyph(glyph_of_mana_gem no) Item(mana_gem)
}

AddFunction IcyVeins
{
	if Glyph(glyph_of_icy_veins) Spell(icy_veins_glyphed)
	if Glyph(glyph_of_icy_veins no) Spell(icy_veins)
}

AddFunction IcyVeinsCooldownRemaining
{
	if Glyph(glyph_of_icy_veins) SpellCooldown(icy_veins_glyphed)
	if Glyph(glyph_of_icy_veins no) SpellCooldown(icy_veins)
}

AddFunction FrostPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#frost_armor
	if BuffExpires(frost_armor_buff) Spell(frost_armor)
	#water_elemental
	if pet.Present(no) Spell(water_elemental)
	#snapshot_stats
	#rune_of_power,if=talent.rune_of_power.enabled
	if Talent(rune_of_power_talent) Spell(rune_of_power)
	#jade_serpent_potion
	UsePotionIntellect()
	#mirror_image
	Spell(mirror_image)
	#frostbolt
	Spell(frostbolt)
}

AddFunction FrostDefaultActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() InterruptActions()
	#cancel_buff,name=alter_time,moving=1
	#cold_snap,if=talent.cold_snap.enabled&health.pct<30
	if Talent(cold_snap_talent) and HealthPercent() < 30 Spell(cold_snap)
	#conjure_mana_gem,if=mana_gem_charges<3&target.debuff.invulnerable.react
	if ItemCharges(mana_gem) < 3 and InCombat(no) ConjureManaGem()
	#time_warp,if=target.health.pct<25|time>5
	if { target.HealthPercent() < 25 or TimeInCombat() > 5 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)
	#mana_gem,if=mana.pct<10
	if ManaPercent() < 10 UseManaGem()
	#rune_of_power,if=talent.rune_of_power.enabled&(buff.rune_of_power.remains<cast_time&buff.alter_time.down)
	if Talent(rune_of_power_talent) and RuneOfPowerRemaining() < CastTime(rune_of_power) and BuffExpires(alter_time_buff) Spell(rune_of_power)
	#rune_of_power,if=talent.rune_of_power.enabled&(cooldown.icy_veins.remains=0&buff.rune_of_power.remains<20)
	if Talent(rune_of_power_talent) and not IcyVeinsCooldownRemaining() > 0 and RuneOfPowerRemaining() < 20 Spell(rune_of_power)
	#mirror_image
	Spell(mirror_image)
	#frozen_orb,if=buff.fingers_of_frost.stack<2
	if BuffStacks(fingers_of_frost_buff) < 2 Spell(frozen_orb)
	#icy_veins,if=(time_to_bloodlust>160&(buff.brain_freeze.react|buff.fingers_of_frost.react))|target.time_to_die<22,moving=0
	if TimeToBloodlust() > 160 and { BuffPresent(brain_freeze_buff) or BuffPresent(fingers_of_frost_buff) } or target.TimeToDie() < 22 IcyVeins()
	#blood_fury,sync=alter_time_activate,if=buff.icy_veins.up|target.time_to_die<18
	if not SpellCooldown(alter_time) > 0 and { BuffPresent(icy_veins_buff) or target.TimeToDie() < 18 } Spell(blood_fury_sp)
	#berserking,sync=alter_time_activate,if=buff.icy_veins.up|target.time_to_die<18
	if not SpellCooldown(alter_time) > 0 and { BuffPresent(icy_veins_buff) or target.TimeToDie() < 18 } Spell(berserking)
	#arcane_torrent,sync=alter_time_activate,if=buff.icy_veins.up|target.time_to_die<18
	if not SpellCooldown(alter_time) > 0 and { BuffPresent(icy_veins_buff) or target.TimeToDie() < 18 } Spell(arcane_torrent_mana)
	#jade_serpent_potion,sync=alter_time_activate,if=buff.icy_veins.up|target.time_to_die<45
	if not SpellCooldown(alter_time) > 0 and { BuffPresent(icy_veins_buff) or target.TimeToDie() < 45 } UsePotionIntellect()
	#presence_of_mind,sync=alter_time_activate,if=talent.presence_of_mind.enabled
	if not SpellCooldown(alter_time) > 0 and Talent(presence_of_mind_talent) Spell(presence_of_mind)
	#use_item,slot=hands,sync=alter_time_activate,if=buff.alter_time.down
	if BuffExpires(alter_time_buff) and not SpellCooldown(alter_time) > 0 UseItemActions()
	#alter_time,if=buff.alter_time.down&buff.icy_veins.up&trinket.stat.intellect.cooldown_remains>25
	if BuffExpires(alter_time_buff) and BuffPresent(icy_veins_buff) and BuffCooldown(trinket_stat_intellect_buff) > 25 Spell(alter_time)
	#alter_time,if=buff.alter_time.down&buff.icy_veins.up&buff.amplified.down
	if BuffExpires(alter_time_buff) and BuffPresent(icy_veins_buff) and BuffExpires(amplified_buff) Spell(alter_time)
	#use_item,slot=hands,if=(cooldown.alter_time_activate.remains>45|target.time_to_die<25)&(buff.rune_of_power.remains>20|buff.invokers_energy.remains>20|(!talent.rune_of_power.enabled&!talent.invocation.enabled))
	if { SpellCooldown(alter_time) > 45 or target.TimeToDie() < 25 } and { RuneOfPowerRemaining() > 20 or BuffRemaining(invokers_energy_buff) > 20 or not Talent(rune_of_power_talent) and not Talent(invocation_talent) } UseItemActions()
	#flamestrike,if=active_enemies>=5
	if Enemies() >= 5 Spell(flamestrike)
	#fire_blast,if=time_to_die<action.ice_lance.travel_time
	if TimeToDie() < 0.5 Spell(fire_blast)
	#frostfire_bolt,if=buff.alter_time.up&buff.brain_freeze.react
	if BuffPresent(alter_time_buff) and BuffPresent(brain_freeze_buff) Spell(frostfire_bolt)
	#frostfire_bolt,if=buff.brain_freeze.react&cooldown.icy_veins.remains>2*action.frostbolt.execute_time
	if BuffPresent(brain_freeze_buff) and IcyVeinsCooldownRemaining() > 2 * ExecuteTime(frostbolt) Spell(frostfire_bolt)
	#nether_tempest,cycle_targets=1,if=talent.nether_tempest.enabled&((!ticking|remains<tick_time)&target.time_to_die>6)
	if Talent(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemaining(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 Spell(nether_tempest)
	#living_bomb,cycle_targets=1,if=talent.living_bomb.enabled&((!ticking|remains<tick_time)&target.time_to_die>tick_time*3)
	if Talent(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemaining(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#frost_bomb,if=talent.frost_bomb.enabled&target.time_to_die>cast_time+tick_time
	if Talent(frost_bomb_talent) and target.TimeToDie() > CastTime(frost_bomb) + target.TickTime(frost_bomb_debuff) Spell(frost_bomb)
	#ice_lance,if=buff.alter_time.up&buff.fingers_of_frost.react
	if BuffPresent(alter_time_buff) and BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
	#ice_lance,if=buff.fingers_of_frost.react&buff.fingers_of_frost.remains<gcd
	if BuffPresent(fingers_of_frost_buff) and BuffRemaining(fingers_of_frost_buff) < GCD() Spell(ice_lance)
	#frostbolt,if=!action.frozen_orb.in_flight&spell_haste<0.55&buff.bloodlust.remains<(2.5-buff.fingers_of_frost.stack)*8*execute_time&buff.tempus_repit.remains<(2.5-buff.fingers_of_frost.stack)*8*execute_time
	if not SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 and SpellHaste() / 100 < 0.55 and BuffRemaining(burst_haste_buff any=1) < { 2.5 - BuffStacks(fingers_of_frost_buff) } * 8 * ExecuteTime(frostbolt) and BuffRemaining(tempus_repit_buff) < { 2.5 - BuffStacks(fingers_of_frost_buff) } * 8 * ExecuteTime(frostbolt) Spell(frostbolt)
	#ice_lance,if=buff.fingers_of_frost.react&cooldown.icy_veins.remains>2*action.frostbolt.execute_time
	if BuffPresent(fingers_of_frost_buff) and IcyVeinsCooldownRemaining() > 2 * ExecuteTime(frostbolt) Spell(ice_lance)
	#rune_of_power,if=talent.rune_of_power.enabled&(buff.amplified.up&trinket.stat.intellect.cooldown_remains=0&buff.rune_of_power.remains<20)
	if Talent(rune_of_power_talent) and BuffPresent(amplified_buff) and not BuffCooldown(trinket_stat_intellect_buff) > 0 and RuneOfPowerRemaining() < 20 Spell(rune_of_power)
	#presence_of_mind,if=talent.presence_of_mind.enabled&cooldown.alter_time_activate.remains>0
	if Talent(presence_of_mind_talent) and SpellCooldown(alter_time) > 0 Spell(presence_of_mind)
	#frostbolt
	Spell(frostbolt)
	#ice_floes,if=talent.ice_floes.enabled
	#fire_blast,moving=1
	if Speed() > 0 Spell(fire_blast)
	#ice_lance,moving=1
	if Speed() > 0 Spell(ice_lance)
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
# alter_time
# alter_time_buff
# amplified_buff
# arcane_brilliance
# arcane_torrent_mana
# berserking
# blood_fury_sp
# brain_freeze_buff
# brilliant_mana_gem
# cold_snap
# cold_snap_talent
# conjure_brilliant_mana_gem
# conjure_mana_gem
# counterspell
# fingers_of_frost_buff
# fire_blast
# flamestrike
# frost_armor
# frost_armor_buff
# frost_bomb
# frost_bomb_debuff
# frost_bomb_talent
# frostbolt
# frostfire_bolt
# frozen_orb
# glyph_of_icy_veins
# glyph_of_mana_gem
# ice_lance
# icy_veins
# icy_veins_buff
# icy_veins_glyphed
# invocation_talent
# invokers_energy_buff
# jade_serpent_potion
# living_bomb
# living_bomb_debuff
# living_bomb_talent
# mana_gem
# mirror_image
# nether_tempest
# nether_tempest_debuff
# nether_tempest_talent
# presence_of_mind
# presence_of_mind_talent
# quaking_palm
# rune_of_power
# rune_of_power_talent
# tempus_repit_buff
# time_warp
# trinket_stat_intellect_buff
# water_elemental
]]
	OvaleScripts:RegisterScript("MAGE", name, desc, code, "reference")
end
