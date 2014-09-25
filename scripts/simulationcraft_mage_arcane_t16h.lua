local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Mage_Arcane_T16H"
	local desc = "[5.4] SimulationCraft: Mage_Arcane_T16H"
	local code = [[
# Based on SimulationCraft profile "Mage_Arcane_T16H".
#	class=mage
#	spec=arcane
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#ea!0...11
#	glyphs=mana_gem/mirror_image/arcane_power/loose_mana

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

AddFunction ArcanePrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#frost_armor
	if BuffExpires(frost_armor_buff) Spell(frost_armor)
	#snapshot_stats
	#rune_of_power,if=talent.rune_of_power.enabled
	if Talent(rune_of_power_talent) Spell(rune_of_power)
	#jade_serpent_potion
	UsePotionIntellect()
	#mirror_image
	Spell(mirror_image)
	#arcane_blast
	Spell(arcane_blast)
}

AddFunction ArcaneDefaultActions
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
	#rune_of_power,if=talent.rune_of_power.enabled&buff.rune_of_power.remains<cast_time
	if Talent(rune_of_power_talent) and RuneOfPowerRemaining() < CastTime(rune_of_power) Spell(rune_of_power)
	#rune_of_power,if=talent.rune_of_power.enabled&(cooldown.arcane_power.remains<gcd&buff.rune_of_power.remains<buff.arcane_power.duration)
	if Talent(rune_of_power_talent) and SpellCooldown(arcane_power) < GCD() and RuneOfPowerRemaining() < SpellData(arcane_power_buff duration) Spell(rune_of_power)
	#mirror_image
	Spell(mirror_image)
	#arcane_power,if=time_to_bloodlust>cooldown.arcane_power.duration&((buff.arcane_charge.stack=4)|target.time_to_die<buff.arcane_power.duration+5),moving=0
	if TimeToBloodlust() > SpellCooldownDuration(arcane_power) and { DebuffStacks(arcane_charge_debuff) == 4 or target.TimeToDie() < SpellData(arcane_power_buff duration) + 5 } Spell(arcane_power)
	#mana_gem,if=glyph.loose_mana.enabled&mana.pct<90&buff.arcane_power.up&buff.arcane_charge.stack=4&buff.alter_time.down
	if Glyph(glyph_of_loose_mana) and ManaPercent() < 90 and BuffPresent(arcane_power_buff) and DebuffStacks(arcane_charge_debuff) == 4 and BuffExpires(alter_time_buff) UseManaGem()
	#mana_gem,if=!glyph.loose_mana.enabled&mana.pct<80&buff.alter_time.down
	if not Glyph(glyph_of_loose_mana) and ManaPercent() < 80 and BuffExpires(alter_time_buff) UseManaGem()
	#blood_fury,sync=alter_time_activate,if=buff.alter_time.down
	if not SpellCooldown(alter_time) > 0 and BuffExpires(alter_time_buff) Spell(blood_fury_sp)
	#berserking,sync=alter_time_activate,if=buff.alter_time.down
	if not SpellCooldown(alter_time) > 0 and BuffExpires(alter_time_buff) Spell(berserking)
	#arcane_torrent,sync=alter_time_activate,if=buff.alter_time.down
	if not SpellCooldown(alter_time) > 0 and BuffExpires(alter_time_buff) Spell(arcane_torrent_mana)
	#jade_serpent_potion,sync=alter_time_activate,if=buff.alter_time.down
	if not SpellCooldown(alter_time) > 0 and BuffExpires(alter_time_buff) UsePotionIntellect()
	#jade_serpent_potion,if=buff.alter_time.down&target.time_to_die<50
	if BuffExpires(alter_time_buff) and target.TimeToDie() < 50 UsePotionIntellect()
	#use_item,slot=hands,sync=alter_time_activate,if=buff.alter_time.down
	if BuffExpires(alter_time_buff) and not SpellCooldown(alter_time) > 0 UseItemActions()
	#use_item,slot=hands,if=(cooldown.alter_time_activate.remains>60|target.time_to_die<25)&(buff.rune_of_power.remains>20|buff.invokers_energy.remains>20|(!talent.rune_of_power.enabled&!talent.invocation.enabled))
	if { SpellCooldown(alter_time) > 60 or target.TimeToDie() < 25 } and { RuneOfPowerRemaining() > 20 or BuffRemaining(invokers_energy_buff) > 20 or not Talent(rune_of_power_talent) and not Talent(invocation_talent) } UseItemActions()
	#presence_of_mind,sync=alter_time_activate,if=talent.presence_of_mind.enabled&buff.alter_time.down
	if not SpellCooldown(alter_time) > 0 and Talent(presence_of_mind_talent) and BuffExpires(alter_time_buff) Spell(presence_of_mind)
	#alter_time,if=buff.alter_time.down&buff.arcane_power.up&trinket.stat.intellect.cooldown_remains>15
	if BuffExpires(alter_time_buff) and BuffPresent(arcane_power_buff) and BuffCooldown(trinket_stat_intellect_buff) > 15 Spell(alter_time)
	#alter_time,if=buff.alter_time.down&buff.arcane_power.up&buff.amplified.down
	if BuffExpires(alter_time_buff) and BuffPresent(arcane_power_buff) and BuffExpires(amplified_buff) Spell(alter_time)
	#run_action_list,name=aoe,if=active_enemies>=6
	if Enemies() >= 6 ArcaneAoeActions()
	#run_action_list,name=single_target,if=active_enemies<6
	if Enemies() < 6 ArcaneSingleTargetActions()
}

AddFunction ArcaneAoeActions
{
	#flamestrike
	Spell(flamestrike)
	#nether_tempest,cycle_targets=1,if=talent.nether_tempest.enabled&((!ticking|remains<tick_time)&target.time_to_die>6)
	if Talent(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemaining(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 Spell(nether_tempest)
	#living_bomb,cycle_targets=1,if=talent.living_bomb.enabled&((!ticking|remains<tick_time)&target.time_to_die>tick_time*3)
	if Talent(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemaining(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#frost_bomb,if=talent.frost_bomb.enabled&(!ticking&target.time_to_die>cast_time+tick_time)
	if Talent(frost_bomb_talent) and not target.DebuffPresent(frost_bomb_debuff) and target.TimeToDie() > CastTime(frost_bomb) + target.TickTime(frost_bomb_debuff) Spell(frost_bomb)
	#arcane_barrage,if=buff.arcane_charge.stack=4
	if DebuffStacks(arcane_charge_debuff) == 4 Spell(arcane_barrage)
	#arcane_explosion
	Spell(arcane_explosion)
}

AddFunction ArcaneSingleTargetActions
{
	#arcane_barrage,if=buff.alter_time.up&buff.alter_time.remains<action.arcane_blast.cast_time
	if BuffPresent(alter_time_buff) and BuffRemaining(alter_time_buff) < CastTime(arcane_blast) Spell(arcane_barrage)
	#nether_tempest,cycle_targets=1,if=talent.nether_tempest.enabled&((!ticking|remains<tick_time)&target.time_to_die>6)
	if Talent(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemaining(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 Spell(nether_tempest)
	#living_bomb,cycle_targets=1,if=talent.living_bomb.enabled&((!ticking|remains<tick_time)&target.time_to_die>tick_time*3)
	if Talent(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemaining(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#frost_bomb,if=talent.frost_bomb.enabled&(!ticking&target.time_to_die>cast_time+tick_time)
	if Talent(frost_bomb_talent) and not target.DebuffPresent(frost_bomb_debuff) and target.TimeToDie() > CastTime(frost_bomb) + target.TickTime(frost_bomb_debuff) Spell(frost_bomb)
	#arcane_missiles,if=buff.alter_time.up
	if BuffPresent(alter_time_buff) and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#arcane_blast,if=buff.alter_time.up
	if BuffPresent(alter_time_buff) Spell(arcane_blast)
	#arcane_blast,if=set_bonus.tier16_2pc_caster&buff.arcane_missiles.stack<2&buff.arcane_charge.stack=4&buff.profound_magic.stack>=2&mana.pct>90
	if ArmorSetBonus(T16_caster 2) and BuffStacks(arcane_missiles_buff) < 2 and DebuffStacks(arcane_charge_debuff) == 4 and BuffStacks(profound_magic_buff) >= 2 and ManaPercent() > 90 Spell(arcane_blast)
	#arcane_blast,if=set_bonus.tier16_2pc_caster&buff.arcane_missiles.stack<2&buff.arcane_charge.stack=4&buff.profound_magic.up&mana.pct>93
	if ArmorSetBonus(T16_caster 2) and BuffStacks(arcane_missiles_buff) < 2 and DebuffStacks(arcane_charge_debuff) == 4 and BuffPresent(profound_magic_buff) and ManaPercent() > 93 Spell(arcane_blast)
	#arcane_missiles,if=(buff.arcane_missiles.stack=2&cooldown.arcane_power.remains>0)|(buff.arcane_charge.stack=4&cooldown.arcane_power.remains>6*cast_time)
	if { BuffStacks(arcane_missiles_buff) == 2 and SpellCooldown(arcane_power) > 0 or DebuffStacks(arcane_charge_debuff) == 4 and SpellCooldown(arcane_power) > 6 * CastTime(arcane_missiles) } and BuffPresent(arcane_missiles_buff) Spell(arcane_missiles)
	#arcane_barrage,if=buff.arcane_charge.stack=4&mana.pct<95
	if DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() < 95 Spell(arcane_barrage)
	#presence_of_mind,if=talent.presence_of_mind.enabled&cooldown.arcane_power.remains>75
	if Talent(presence_of_mind_talent) and SpellCooldown(arcane_power) > 75 Spell(presence_of_mind)
	#arcane_blast
	Spell(arcane_blast)
	#ice_floes,if=talent.ice_floes.enabled
	#arcane_barrage,moving=1
	if Speed() > 0 Spell(arcane_barrage)
	#fire_blast,moving=1
	if Speed() > 0 Spell(fire_blast)
	#ice_lance,moving=1
	if Speed() > 0 Spell(ice_lance)
}

AddIcon specialization=arcane help=main enemies=1
{
	if InCombat(no) ArcanePrecombatActions()
	ArcaneDefaultActions()
}

AddIcon specialization=arcane help=aoe
{
	if InCombat(no) ArcanePrecombatActions()
	ArcaneDefaultActions()
}

### Required symbols
# alter_time
# alter_time_buff
# amplified_buff
# arcane_barrage
# arcane_blast
# arcane_brilliance
# arcane_charge_debuff
# arcane_explosion
# arcane_missiles
# arcane_missiles_buff
# arcane_power
# arcane_power_buff
# arcane_torrent_mana
# berserking
# blood_fury_sp
# brilliant_mana_gem
# cold_snap
# cold_snap_talent
# conjure_brilliant_mana_gem
# conjure_mana_gem
# counterspell
# fire_blast
# flamestrike
# frost_armor
# frost_armor_buff
# frost_bomb
# frost_bomb_debuff
# frost_bomb_talent
# glyph_of_loose_mana
# glyph_of_mana_gem
# ice_lance
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
# profound_magic_buff
# quaking_palm
# rune_of_power
# rune_of_power_talent
# time_warp
# trinket_stat_intellect_buff
]]
	OvaleScripts:RegisterScript("MAGE", name, desc, code, "reference")
end
