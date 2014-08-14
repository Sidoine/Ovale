local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Mage_Fire_T16H"
	local desc = "[5.4] SimulationCraft: Mage_Fire_T16H"
	local code = [[
# Based on SimulationCraft profile "Mage_Fire_T16H".
#	class=mage
#	spec=fire
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#eZ!0...11
#	glyphs=combustion/counterspell

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

AddFunction UseManaGem
{
	if Glyph(glyph_of_mana_gem) Item(brilliant_mana_gem)
	if Glyph(glyph_of_mana_gem no) Item(mana_gem)
}

AddFunction FireDefaultActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() InterruptActions()
	#cancel_buff,name=alter_time,moving=1
	#cold_snap,if=talent.cold_snap.enabled&health.pct<30
	if Talent(cold_snap_talent) and HealthPercent() < 30 Spell(cold_snap)
	#time_warp,if=buff.alter_time.down
	if BuffExpires(alter_time_buff) and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)
	#mana_gem,if=mana.pct<10
	if ManaPercent() < 10 UseManaGem()
	#rune_of_power,if=talent.rune_of_power.enabled&buff.rune_of_power.remains=0
	if Talent(rune_of_power_talent) and not RuneOfPowerRemaining() > 0 Spell(rune_of_power)
	#cancel_buff,name=alter_time,if=buff.amplified.up&buff.alter_time.up&(trinket.stat.intellect.cooldown_remains-buff.alter_time.remains>109)
	if BuffPresent(amplified_buff) and BuffPresent(alter_time_buff) and BuffCooldown(trinket_stat_intellect_buff) - BuffRemaining(alter_time_buff) > 109 Texture(spell_mage_altertime text=cancel)
	#run_action_list,name=combust_sequence,if=buff.alter_time.up|pyro_chain
	if BuffPresent(alter_time_buff) or GetState(pyro_chain) > 0 FireCombustSequenceActions()
	#run_action_list,name=init_alter_combust,if=buff.amplified.up&cooldown.alter_time_activate.up&cooldown.combustion.up&(trinket.stat.intellect.cooldown_remains>95|trinket.stat.intellect.cooldown_remains+20>time_to_die)
	if BuffPresent(amplified_buff) and not SpellCooldown(alter_time) > 0 and not SpellCooldown(combustion) > 0 and { BuffCooldown(trinket_stat_intellect_buff) > 95 or BuffCooldown(trinket_stat_intellect_buff) + 20 > TimeToDie() } FireInitAlterCombustActions()
	#run_action_list,name=init_alter_combust,if=buff.amplified.down&cooldown.alter_time_activate.up&cooldown.combustion.up
	if BuffExpires(amplified_buff) and not SpellCooldown(alter_time) > 0 and not SpellCooldown(combustion) > 0 FireInitAlterCombustActions()
	#run_action_list,name=init_pom_combust,if=buff.amplified.up&cooldown.alter_time_activate.remains>45&cooldown.combustion.up&cooldown.presence_of_mind.up&(trinket.stat.intellect.cooldown_remains>95|trinket.stat.intellect.cooldown_remains+20>time_to_die)
	if BuffPresent(amplified_buff) and SpellCooldown(alter_time) > 45 and not SpellCooldown(combustion) > 0 and not SpellCooldown(presence_of_mind) > 0 and { BuffCooldown(trinket_stat_intellect_buff) > 95 or BuffCooldown(trinket_stat_intellect_buff) + 20 > TimeToDie() } FireInitPomCombustActions()
	#run_action_list,name=init_pom_combust,if=buff.amplified.down&cooldown.alter_time_activate.remains>45&cooldown.combustion.up&cooldown.presence_of_mind.up
	if BuffExpires(amplified_buff) and SpellCooldown(alter_time) > 45 and not SpellCooldown(combustion) > 0 and not SpellCooldown(presence_of_mind) > 0 FireInitPomCombustActions()
	#rune_of_power,if=talent.rune_of_power.enabled&(buff.alter_time.down&buff.rune_of_power.remains<4*action.fireball.execute_time&(buff.heating_up.down|buff.pyroblast.down|!action.fireball.in_flight))
	if Talent(rune_of_power_talent) and BuffExpires(alter_time_buff) and RuneOfPowerRemaining() < 4 * ExecuteTime(fireball) and { BuffExpires(heating_up_buff) or BuffExpires(pyroblast_buff) or not InFlightToTarget(fireball) } Spell(rune_of_power)
	#mirror_image,if=buff.alter_time.down&(buff.heating_up.down|buff.pyroblast.down|!action.fireball.in_flight)
	if BuffExpires(alter_time_buff) and { BuffExpires(heating_up_buff) or BuffExpires(pyroblast_buff) or not InFlightToTarget(fireball) } Spell(mirror_image)
	#blood_fury,if=buff.alter_time.down&target.time_to_die<18
	if BuffExpires(alter_time_buff) and target.TimeToDie() < 18 Spell(blood_fury_sp)
	#berserking,if=buff.alter_time.down&target.time_to_die<18
	if BuffExpires(alter_time_buff) and target.TimeToDie() < 18 Spell(berserking)
	#arcane_torrent,if=buff.alter_time.down&target.time_to_die<18
	if BuffExpires(alter_time_buff) and target.TimeToDie() < 18 Spell(arcane_torrent_mana)
	#jade_serpent_potion,if=buff.alter_time.down&target.time_to_die<45
	if BuffExpires(alter_time_buff) and target.TimeToDie() < 45 UsePotionIntellect()
	#use_item,slot=hands,if=buff.alter_time.down&(trinket.stat.intellect.cooldown_remains>50|target.time_to_die<12)
	if BuffExpires(alter_time_buff) and { BuffCooldown(trinket_stat_intellect_buff) > 50 or target.TimeToDie() < 12 } UseItemActions()
	#run_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FireAoeActions()
	#run_action_list,name=proc_builder,if=buff.amplified.up&trinket.stat.intellect.cooldown_remains<action.fireball.execute_time
	if BuffPresent(amplified_buff) and BuffCooldown(trinket_stat_intellect_buff) < ExecuteTime(fireball) FireProcBuilderActions()
	#run_action_list,name=single_target
	FireSingleTargetActions()
}

AddFunction FireProcBuilderActions
{
	#pyroblast,if=buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight
	if BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and InFlightToTarget(fireball) Spell(pyroblast)
	#nether_tempest,cycle_targets=1,if=talent.nether_tempest.enabled&((!ticking|remains<tick_time)&target.time_to_die>6)
	if Talent(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemaining(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 Spell(nether_tempest)
	#living_bomb,cycle_targets=1,if=talent.living_bomb.enabled&((!ticking|remains<tick_time)&target.time_to_die>tick_time*3)
	if Talent(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemaining(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#frost_bomb,if=talent.frost_bomb.enabled&(!ticking&target.time_to_die>cast_time+tick_time)
	if Talent(frost_bomb_talent) and not target.DebuffPresent(frost_bomb_debuff) and target.TimeToDie() > CastTime(frost_bomb) + target.TickTime(frost_bomb_debuff) Spell(frost_bomb)
	#inferno_blast,if=(buff.pyroblast.down&buff.heating_up.up)|(buff.pyroblast.up&buff.heating_up.down&!action.fireball.in_flight&!action.pyroblast.in_flight)
	if BuffExpires(pyroblast_buff) and BuffPresent(heating_up_buff) or BuffPresent(pyroblast_buff) and BuffExpires(heating_up_buff) and not InFlightToTarget(fireball) and not InFlightToTarget(pyroblast) Spell(inferno_blast)
	#fireball
	Spell(fireball)
	#scorch,moving=1
	if Speed() > 0 Spell(scorch)
}

AddFunction FireAoeActions
{
	#inferno_blast,if=dot.combustion.ticking
	if target.DebuffPresent(combustion_debuff) Spell(inferno_blast)
	#flamestrike
	Spell(flamestrike)
	#blizzard
	Spell(blizzard)
}

AddFunction FireSingleTargetActions
{
	#inferno_blast,if=dot.combustion.ticking&active_enemies>1
	if target.DebuffPresent(combustion_debuff) and Enemies() > 1 Spell(inferno_blast)
	#pyroblast,if=buff.pyroblast.up&buff.pyroblast.remains<action.fireball.execute_time
	if BuffPresent(pyroblast_buff) and BuffRemaining(pyroblast_buff) < ExecuteTime(fireball) Spell(pyroblast)
	#pyroblast,if=set_bonus.tier16_2pc_caster&buff.pyroblast.up&buff.potent_flames.up&buff.potent_flames.remains<action.fireball.execute_time
	if ArmorSetBonus(T16_caster 2) and BuffPresent(pyroblast_buff) and BuffPresent(potent_flames_buff) and BuffRemaining(potent_flames_buff) < ExecuteTime(fireball) Spell(pyroblast)
	#scorch,if=set_bonus.tier16_2pc_caster&buff.potent_flames.up&buff.pyroblast.down&buff.heating_up.down&buff.potent_flames.remains<action.fireball.execute_time+gcd&buff.potent_flames.remains>2*gcd
	if ArmorSetBonus(T16_caster 2) and BuffPresent(potent_flames_buff) and BuffExpires(pyroblast_buff) and BuffExpires(heating_up_buff) and BuffRemaining(potent_flames_buff) < ExecuteTime(fireball) + GCD() and BuffRemaining(potent_flames_buff) > 2 * GCD() Spell(scorch)
	#inferno_blast,if=set_bonus.tier16_2pc_caster&buff.pyroblast.down&buff.potent_flames.up&buff.potent_flames.remains<action.fireball.execute_time&buff.potent_flames.remains>gcd&(buff.heating_up.up|action.fireball.in_flight|action.pyroblast.in_flight)
	if ArmorSetBonus(T16_caster 2) and BuffExpires(pyroblast_buff) and BuffPresent(potent_flames_buff) and BuffRemaining(potent_flames_buff) < ExecuteTime(fireball) and BuffRemaining(potent_flames_buff) > GCD() and { BuffPresent(heating_up_buff) or InFlightToTarget(fireball) or InFlightToTarget(pyroblast) } Spell(inferno_blast)
	#pyroblast,if=buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight
	if BuffPresent(pyroblast_buff) and BuffPresent(heating_up_buff) and InFlightToTarget(fireball) Spell(pyroblast)
	#nether_tempest,cycle_targets=1,if=talent.nether_tempest.enabled&((!ticking|remains<tick_time)&target.time_to_die>6)
	if Talent(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemaining(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 Spell(nether_tempest)
	#living_bomb,cycle_targets=1,if=talent.living_bomb.enabled&((!ticking|remains<tick_time)&target.time_to_die>tick_time*3)
	if Talent(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemaining(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#frost_bomb,if=talent.frost_bomb.enabled&(!ticking&target.time_to_die>cast_time+tick_time)
	if Talent(frost_bomb_talent) and not target.DebuffPresent(frost_bomb_debuff) and target.TimeToDie() > CastTime(frost_bomb) + target.TickTime(frost_bomb_debuff) Spell(frost_bomb)
	#inferno_blast,if=buff.pyroblast.down&buff.heating_up.up
	if BuffExpires(pyroblast_buff) and BuffPresent(heating_up_buff) Spell(inferno_blast)
	#pyroblast,if=buff.amplified.up&(cooldown.alter_time_activate.remains>0|(buff.amplified.up&trinket.stat.intellect.cooldown_remains>0))&trinket.stacking_proc.intellect.up&trinket.stacking_proc.intellect.remains<3*gcd&execute_time=gcd
	if BuffPresent(amplified_buff) and { SpellCooldown(alter_time) > 0 or BuffPresent(amplified_buff) and BuffCooldown(trinket_stat_intellect_buff) > 0 } and BuffPresent(trinket_stacking_proc_intellect_buff) and BuffRemaining(trinket_stacking_proc_intellect_buff) < 3 * GCD() and ExecuteTime(pyroblast) == GCD() Spell(pyroblast)
	#pyroblast,if=(cooldown.alter_time_activate.remains>0|cooldown.combustion.remains>0)&trinket.stacking_proc.intellect.up&trinket.stacking_proc.intellect.remains<3*gcd&execute_time=gcd
	if { SpellCooldown(alter_time) > 0 or SpellCooldown(combustion) > 0 } and BuffPresent(trinket_stacking_proc_intellect_buff) and BuffRemaining(trinket_stacking_proc_intellect_buff) < 3 * GCD() and ExecuteTime(pyroblast) == GCD() Spell(pyroblast)
	#inferno_blast,if=buff.pyroblast.up&buff.heating_up.down&!action.fireball.in_flight
	if BuffPresent(pyroblast_buff) and BuffExpires(heating_up_buff) and not InFlightToTarget(fireball) Spell(inferno_blast)
	#pyroblast,if=buff.presence_of_mind.up
	if BuffPresent(presence_of_mind_buff) Spell(pyroblast)
	#fireball
	Spell(fireball)
	#scorch,moving=1
	if Speed() > 0 Spell(scorch)
}

AddFunction FireInitPomCombustActions
{
	#run_action_list,name=proc_builder,if=buff.pyroblast.down|buff.heating_up.down|!action.fireball.in_flight
	if BuffExpires(pyroblast_buff) or BuffExpires(heating_up_buff) or not InFlightToTarget(fireball) FireProcBuilderActions()
	#start_pyro_chain,if=!pyro_chain
	if not GetState(pyro_chain) > 0 SetState(pyro_chain 1)
}

AddFunction FireCombustSequenceActions
{
	#start_pyro_chain,if=!pyro_chain
	if not GetState(pyro_chain) > 0 SetState(pyro_chain 1)
	#stop_pyro_chain,if=cooldown.combustion.remains>0&pyro_chain
	if SpellCooldown(combustion) > 0 and GetState(pyro_chain) > 0 SetState(pyro_chain 0)
	#presence_of_mind,if=talent.presence_of_mind.enabled&buff.alter_time.down
	if Talent(presence_of_mind_talent) and BuffExpires(alter_time_buff) Spell(presence_of_mind)
	#pyroblast,if=execute_time=gcd&buff.alter_time.up
	if ExecuteTime(pyroblast) == GCD() and BuffPresent(alter_time_buff) Spell(pyroblast)
	#alter_time,if=buff.alter_time.up&action.pyroblast.execute_time>gcd
	if BuffPresent(alter_time_buff) and ExecuteTime(pyroblast) > GCD() Spell(alter_time)
	#pyroblast,if=talent.presence_of_mind.enabled&buff.presence_of_mind.up&buff.pyroblast.up
	if Talent(presence_of_mind_talent) and BuffPresent(presence_of_mind_buff) and BuffPresent(pyroblast_buff) Spell(pyroblast)
	#pyroblast,if=!talent.presence_of_mind.enabled&buff.pyroblast.up
	if not Talent(presence_of_mind_talent) and BuffPresent(pyroblast_buff) Spell(pyroblast)
	#combustion,if=buff.alter_time.down&cooldown.alter_time_activate.remains>150&buff.tempus_repit.up&buff.tempus_repit.remains<gcd
	if BuffExpires(alter_time_buff) and SpellCooldown(alter_time) > 150 and BuffPresent(tempus_repit_buff) and BuffRemaining(tempus_repit_buff) < GCD() Spell(combustion)
	#pyroblast,if=buff.presence_of_mind.up&(travel_time+0.15<dot.ignite.remains-4|(crit_damage*crit_pct_current+hit_damage*(100-crit_pct_current))*0.01*mastery_value>dot.ignite.tick_dmg)
	if BuffPresent(presence_of_mind_buff) and { 0.5 + 0.15 < target.DebuffRemaining(ignite_debuff) - 4 or { CritDamage(pyroblast) * SpellCritChance() + Damage(pyroblast) * { 100 - SpellCritChance() } } * 0.01 * { MasteryEffect() / 100 } > target.TickValue(ignite_debuff) } Spell(pyroblast)
	#pyroblast,if=buff.presence_of_mind.up&buff.heating_up.up&gcd+travel_time+0.15<dot.ignite.remains-2&(crit_damage*crit_pct_current+hit_damage*(100-crit_pct_current))*0.01*(0.0125*crit_pct_current+1)*mastery_value>dot.ignite.tick_dmg
	if BuffPresent(presence_of_mind_buff) and BuffPresent(heating_up_buff) and GCD() + 0.5 + 0.15 < target.DebuffRemaining(ignite_debuff) - 2 and { CritDamage(pyroblast) * SpellCritChance() + Damage(pyroblast) * { 100 - SpellCritChance() } } * 0.01 * { 0.0125 * SpellCritChance() + 1 } * { MasteryEffect() / 100 } > target.TickValue(ignite_debuff) Spell(pyroblast)
	#pyroblast,if=buff.presence_of_mind.down&buff.pyroblast.up&(travel_time+0.15<dot.ignite.remains-4|(crit_damage*crit_pct_current+hit_damage*(100-crit_pct_current))*0.01*mastery_value>dot.ignite.tick_dmg)
	if BuffExpires(presence_of_mind_buff) and BuffPresent(pyroblast_buff) and { 0.5 + 0.15 < target.DebuffRemaining(ignite_debuff) - 4 or { CritDamage(pyroblast) * SpellCritChance() + Damage(pyroblast) * { 100 - SpellCritChance() } } * 0.01 * { MasteryEffect() / 100 } > target.TickValue(ignite_debuff) } Spell(pyroblast)
	#combustion
	Spell(combustion)
}

AddFunction FireInitAlterCombustActions
{
	#run_action_list,name=proc_builder,if=buff.pyroblast.down|buff.heating_up.down|!action.fireball.in_flight
	if BuffExpires(pyroblast_buff) or BuffExpires(heating_up_buff) or not InFlightToTarget(fireball) FireProcBuilderActions()
	#blood_fury
	Spell(blood_fury_sp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#jade_serpent_potion
	UsePotionIntellect()
	#use_item,slot=hands
	UseItemActions()
	#presence_of_mind,if=talent.presence_of_mind.enabled
	if Talent(presence_of_mind_talent) Spell(presence_of_mind)
	#alter_time
	Spell(alter_time)
}

AddFunction FirePrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#molten_armor
	if BuffExpires(molten_armor_buff) Spell(molten_armor)
	#snapshot_stats
	#rune_of_power,if=talent.rune_of_power.enabled
	if Talent(rune_of_power_talent) Spell(rune_of_power)
	#jade_serpent_potion
	UsePotionIntellect()
	#mirror_image
	Spell(mirror_image)
	#pyroblast
	Spell(pyroblast)
}

AddIcon specialization=fire help=main enemies=1
{
	if InCombat(no) FirePrecombatActions()
	FireDefaultActions()
}

AddIcon specialization=fire help=aoe
{
	if InCombat(no) FirePrecombatActions()
	FireDefaultActions()
}

### Required symbols
# alter_time
# alter_time_buff
# amplified_buff
# arcane_brilliance
# arcane_torrent_mana
# berserking
# blizzard
# blood_fury_sp
# brilliant_mana_gem
# cold_snap
# cold_snap_talent
# combustion
# combustion_debuff
# counterspell
# fireball
# flamestrike
# frost_bomb
# frost_bomb_debuff
# frost_bomb_talent
# glyph_of_mana_gem
# heating_up_buff
# ignite_debuff
# inferno_blast
# jade_serpent_potion
# living_bomb
# living_bomb_debuff
# living_bomb_talent
# mana_gem
# mirror_image
# molten_armor
# molten_armor_buff
# nether_tempest
# nether_tempest_debuff
# nether_tempest_talent
# potent_flames_buff
# presence_of_mind
# presence_of_mind_buff
# presence_of_mind_talent
# pyroblast
# pyroblast_buff
# quaking_palm
# rune_of_power
# rune_of_power_talent
# scorch
# tempus_repit_buff
# time_warp
# trinket_stacking_proc_intellect_buff
# trinket_stat_intellect_buff
]]
	OvaleScripts:RegisterScript("MAGE", name, desc, code, "reference")
end
