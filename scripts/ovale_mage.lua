local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_mage"
	local desc = "[5.4.8] Ovale: Arcane, Fire, Frost"
	local code = [[
# Ovale mage script based on SimulationCraft.

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

###
### Arcane
###
# Based on SimulationCraft profile "Mage_Arcane_T16H".
#	class=mage
#	spec=arcane
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#ea!0...11
#	glyphs=mana_gem/mirror_image/arcane_power/loose_mana

# ActionList: ArcanePrecombatActions --> main, predict, shortcd, cd

AddFunction ArcanePrecombatActions
{
	ArcanePrecombatPredictActions()
}

AddFunction ArcanePrecombatPredictActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#frost_armor
	if BuffExpires(frost_armor_buff) Spell(frost_armor)
	#snapshot_stats
	#arcane_blast
	Spell(arcane_blast)
}

AddFunction ArcanePrecombatShortCdActions
{
	unless BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) and Spell(arcane_brilliance)
		or BuffExpires(frost_armor_buff) and Spell(frost_armor)
	{
		#evocation,if=talent.invocation.enabled
		# CHANGE: Only suggest Evocation if the Invocation buff needs to be topped off prior to pull.
		#if Talent(invocation_talent) Spell(evocation)
		if Talent(invocation_talent) and BuffRemaining(invokers_energy_buff) < 45 Spell(evocation)
		#rune_of_power,if=talent.rune_of_power.enabled
		# CHANGE: Only suggest Rune of Power if the rune needs to be refreshed prior to pull.
		#if Talent(rune_of_power_talent) Spell(rune_of_power)
		if Talent(rune_of_power_talent) and RuneOfPowerRemaining() < 45 Spell(rune_of_power)
	}
}

AddFunction ArcanePrecombatCdActions
{
	unless BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) and Spell(arcane_brilliance)
		or BuffExpires(frost_armor_buff) and Spell(frost_armor)
		or Talent(invocation_talent) and BuffRemaining(invokers_energy_buff) < 45 and Spell(evocation)
		or Talent(rune_of_power_talent) and RuneOfPowerRemaining() < 45 and Spell(rune_of_power)
	{
		#jade_serpent_potion
		UsePotionIntellect()
		#mirror_image
		Spell(mirror_image)
	}
}

# ActionList: ArcaneDefaultActions --> main, predict, shortcd, cd

AddFunction ArcaneDefaultActions
{
	#conjure_mana_gem,if=mana_gem_charges<3&target.debuff.invulnerable.react
	if ItemCharges(mana_gem) < 3 and InCombat(no) ConjureManaGem()
	#run_action_list,name=aoe,if=active_enemies>=6
	if Enemies() >= 6 ArcaneAoeActions()
	#run_action_list,name=single_target,if=active_enemies<6
	if Enemies() < 6 ArcaneSingleTargetActions()
}

AddFunction ArcaneDefaultPredictActions
{
	#conjure_mana_gem,if=mana_gem_charges<3&target.debuff.invulnerable.react
	if ItemCharges(mana_gem) < 3 and InCombat(no) ConjureManaGem()
	#run_action_list,name=aoe,if=active_enemies>=6
	if Enemies() >= 6 ArcaneAoePredictActions()
	#run_action_list,name=single_target,if=active_enemies<6
	if Enemies() < 6 ArcaneSingleTargetPredictActions()
}

AddFunction ArcaneDefaultShortCdActions
{
	#cancel_buff,name=alter_time,moving=1
	unless ItemCharges(mana_gem) < 3 and InCombat(no)
	{
		#rune_of_power,if=talent.rune_of_power.enabled&buff.rune_of_power.remains<cast_time
		if Talent(rune_of_power_talent) and RuneOfPowerRemaining() < CastTime(rune_of_power) Spell(rune_of_power)
		#rune_of_power,if=talent.rune_of_power.enabled&(cooldown.arcane_power.remains<gcd&buff.rune_of_power.remains<buff.arcane_power.duration)
		if Talent(rune_of_power_talent) and SpellCooldown(arcane_power) < GCD() and RuneOfPowerRemaining() < SpellData(arcane_power_buff duration) Spell(rune_of_power)
		#evocation,if=talent.invocation.enabled&buff.invokers_energy.down
		if Talent(invocation_talent) and BuffExpires(invokers_energy_buff) Spell(evocation)
		#evocation,if=talent.invocation.enabled&cooldown.arcane_power.remains=0&buff.invokers_energy.remains<buff.arcane_power.duration
		if Talent(invocation_talent) and not SpellCooldown(arcane_power) > 0 and BuffRemaining(invokers_energy_buff) < SpellData(arcane_power_buff duration) Spell(evocation)
		#evocation,if=talent.invocation.enabled&mana.pct<50,interrupt_if=mana.pct>95&buff.invokers_energy.remains>10
		if Talent(invocation_talent) and ManaPercent() < 50 and BuffRemaining(invokers_energy_buff) > 10 Spell(evocation)
		#evocation,if=!talent.invocation.enabled&mana.pct<50,interrupt_if=mana.pct>95
		if Talent(invocation_talent no) and ManaPercent() < 50 Spell(evocation)
		#arcane_power,if=time_to_bloodlust>cooldown.arcane_power.duration&((buff.arcane_charge.stack=4)|target.time_to_die<buff.arcane_power.duration+5),moving=0
		if TimeToBloodlust() > SpellCooldownDuration(arcane_power) and { DebuffStacks(arcane_charge_debuff) == 4 or target.TimeToDie() < SpellData(arcane_power_buff duration) + 5 } Spell(arcane_power)
		#mana_gem,if=glyph.loose_mana.enabled&mana.pct<90&buff.arcane_power.up&buff.arcane_charge.stack=4&buff.alter_time.down
		if Glyph(glyph_of_loose_mana) and ManaPercent() < 90 and BuffPresent(arcane_power_buff) and DebuffStacks(arcane_charge_debuff) == 4 and BuffExpires(alter_time_buff) UseManaGem()
		#mana_gem,if=!glyph.loose_mana.enabled&mana.pct<80&buff.alter_time.down
		if not Glyph(glyph_of_loose_mana) and ManaPercent() < 80 and BuffExpires(alter_time_buff) UseManaGem()
		#presence_of_mind,sync=alter_time_activate,if=talent.presence_of_mind.enabled&buff.alter_time.down
		if not SpellCooldown(alter_time) > 0 and Talent(presence_of_mind_talent) and BuffExpires(alter_time_buff) Spell(presence_of_mind)
		#run_action_list,name=aoe,if=active_enemies>=6
		if Enemies() >= 6 ArcaneAoeShortCdActions()
		#run_action_list,name=single_target,if=active_enemies<6
		if Enemies() < 6 ArcaneSingleTargetShortCdActions()
	}
}

AddFunction ArcaneDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() InterruptActions()
	#cold_snap,if=talent.cold_snap.enabled&health.pct<30
	if Talent(cold_snap_talent) and HealthPercent() < 30 Spell(cold_snap)

	unless ItemCharges(mana_gem) < 3 and InCombat(no)
	{
		#time_warp,if=target.health.pct<25|time>5
		if { target.HealthPercent() < 25 or TimeInCombat() > 5 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)

		unless Talent(rune_of_power_talent) and RuneOfPowerRemaining() < CastTime(rune_of_power) and Spell(rune_of_power)
			or Talent(rune_of_power_talent) and SpellCooldown(arcane_power) < GCD() and RuneOfPowerRemaining() < SpellData(arcane_power_buff duration) and Spell(rune_of_power)
			or Talent(invocation_talent) and BuffExpires(invokers_energy_buff) and Spell(evocation)
			or Talent(invocation_talent) and not SpellCooldown(arcane_power) > 0 and BuffRemaining(invokers_energy_buff) < SpellData(arcane_power_buff duration) and Spell(evocation)
			or Talent(invocation_talent) and ManaPercent() < 50 and BuffRemaining(invokers_energy_buff) > 10 and Spell(evocation)
			or Talent(invocation_talent no) and ManaPercent() < 50 and Spell(evocation)
		{
			#mirror_image
			Spell(mirror_image)

			unless Glyph(glyph_of_loose_mana) and ManaPercent() < 90 and BuffPresent(arcane_power_buff) and DebuffStacks(arcane_charge_debuff) == 4 and BuffExpires(alter_time_buff) and UseManaGem()
				or not Glyph(glyph_of_loose_mana) and ManaPercent() < 80 and BuffExpires(alter_time_buff) and UseManaGem()
			{
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
				if { SpellCooldown(alter_time) > 60 or target.TimeToDie() < 25 } and { RuneOfPowerRemaining() > 20 or BuffRemaining(invokers_energy_buff) > 20 or Talent(rune_of_power_talent no) and Talent(invocation_talent no) } UseItemActions()
				#alter_time,if=buff.alter_time.down&buff.arcane_power.up&trinket.stat.intellect.cooldown_remains>15
				if BuffExpires(alter_time_buff) and BuffPresent(arcane_power_buff) and BuffCooldown(trinket_stat_intellect_buff) > 15 Spell(alter_time)
				#alter_time,if=buff.alter_time.down&buff.arcane_power.up&buff.amplified.down
				if BuffExpires(alter_time_buff) and BuffPresent(arcane_power_buff) and BuffExpires(amplified_buff) Spell(alter_time)
				#run_action_list,name=aoe,if=active_enemies>=6
				if Enemies() >= 6 ArcaneAoeCdActions()
				#run_action_list,name=single_target,if=active_enemies<6
				if Enemies() < 6 ArcaneSingleTargetCdActions()
			}
		}
	}
}

# ActionList: ArcaneAoeActions --> main, predict, shortcd, cd

AddFunction ArcaneAoeActions
{
	ArcaneAoePredictActions()

	#arcane_explosion
	Spell(arcane_explosion)
}

AddFunction ArcaneAoePredictActions
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
}

AddFunction ArcaneAoeShortCdActions {}

AddFunction ArcaneAoeCdActions {}

# ActionList: ArcaneSingleTargetActions --> main, predict, shortcd, cd

AddFunction ArcaneSingleTargetActions
{
	ArcaneSingleTargetPredictActions()

	#arcane_blast
	Spell(arcane_blast)
}

AddFunction ArcaneSingleTargetPredictActions
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
}

AddFunction ArcaneSingleTargetShortCdActions
{
	unless BuffPresent(alter_time_buff) and BuffRemaining(alter_time_buff) < CastTime(arcane_blast) and Spell(arcane_barrage)
		or Talent(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemaining(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 and Spell(nether_tempest)
		or Talent(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemaining(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 and Spell(living_bomb)
		or Talent(frost_bomb_talent) and not target.DebuffPresent(frost_bomb_debuff) and target.TimeToDie() > CastTime(frost_bomb) + target.TickTime(frost_bomb_debuff) and Spell(frost_bomb)
		or BuffPresent(alter_time_buff) and BuffPresent(arcane_missiles_buff) and Spell(arcane_missiles)
		or BuffPresent(alter_time_buff) and Spell(arcane_blast)
		or ArmorSetBonus(T16_caster 2) and BuffStacks(arcane_missiles_buff) < 2 and DebuffStacks(arcane_charge_debuff) == 4 and BuffStacks(profound_magic_buff) >= 2 and ManaPercent() > 90 and Spell(arcane_blast)
		or ArmorSetBonus(T16_caster 2) and BuffStacks(arcane_missiles_buff) < 2 and DebuffStacks(arcane_charge_debuff) == 4 and BuffPresent(profound_magic_buff) and ManaPercent() > 93 and Spell(arcane_blast)
		or { BuffStacks(arcane_missiles_buff) == 2 and SpellCooldown(arcane_power) > 0 or DebuffStacks(arcane_charge_debuff) == 4 and SpellCooldown(arcane_power) > 6 * CastTime(arcane_missiles) } and BuffPresent(arcane_missiles_buff) and Spell(arcane_missiles)
		or DebuffStacks(arcane_charge_debuff) == 4 and ManaPercent() < 95 and Spell(arcane_barrage)
	{
		#presence_of_mind,if=talent.presence_of_mind.enabled&cooldown.arcane_power.remains>75
		if Talent(presence_of_mind_talent) and SpellCooldown(arcane_power) > 75 Spell(presence_of_mind)
	}
}

AddFunction ArcaneSingleTargetCdActions {}

### Arcane icons.
AddCheckBox(opt_mage_arcane "Show Arcane icons" specialization=arcane default)
AddCheckBox(opt_mage_arcane_aoe L(AOE) specialization=arcane default)

AddIcon specialization=arcane help=shortcd enemies=1 checkbox=opt_mage_arcane checkbox=!opt_mage_arcane_aoe
{
	if InCombat(no) ArcanePrecombatShortCdActions()
	ArcaneDefaultShortCdActions()
}

AddIcon specialization=arcane help=shortcd checkbox=opt_mage_arcane checkbox=opt_mage_arcane_aoe
{
	if InCombat(no) ArcanePrecombatShortCdActions()
	ArcaneDefaultShortCdActions()
}

AddIcon specialization=arcane help=main enemies=1 checkbox=opt_mage_arcane
{
	if InCombat(no) ArcanePrecombatActions()
	ArcaneDefaultActions()
}

AddIcon specialization=arcane help=predict enemies=1 checkbox=opt_mage_arcane checkbox=!opt_mage_arcane_aoe
{
	if InCombat(no) ArcanePrecombatPredictActions()
	ArcaneDefaultPredictActions()
}

AddIcon specialization=arcane help=aoe checkbox=opt_mage_arcane checkbox=opt_mage_arcane_aoe
{
	if InCombat(no) ArcanePrecombatActions()
	ArcaneDefaultActions()
}

AddIcon specialization=arcane help=cd enemies=1 checkbox=opt_mage_arcane checkbox=!opt_mage_arcane_aoe
{
	if InCombat(no) ArcanePrecombatCdActions()
	ArcaneDefaultCdActions()
}

AddIcon specialization=arcane help=cd checkbox=opt_mage_arcane checkbox=opt_mage_arcane_aoe
{
	if InCombat(no) ArcanePrecombatCdActions()
	ArcaneDefaultCdActions()
}

###
### Fire
###
# Based on SimulationCraft profile "Mage_Fire_T16H".
#	class=mage
#	spec=fire
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#eZ!0...11
#	glyphs=combustion/counterspell

# ActionList: FireDefaultActions --> main, predict, shortcd, cd

AddFunction FireDefaultActions
{
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
	#run_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FireAoeActions()
	#run_action_list,name=proc_builder,if=buff.amplified.up&trinket.stat.intellect.cooldown_remains<action.fireball.execute_time
	if BuffPresent(amplified_buff) and BuffCooldown(trinket_stat_intellect_buff) < ExecuteTime(fireball) FireProcBuilderActions()
	#run_action_list,name=single_target
	FireSingleTargetActions()
}

AddFunction FireDefaultPredictActions
{
	#run_action_list,name=combust_sequence,if=buff.alter_time.up|pyro_chain
	if BuffPresent(alter_time_buff) or GetState(pyro_chain) > 0 FireCombustSequencePredictActions()
	#run_action_list,name=init_alter_combust,if=buff.amplified.up&cooldown.alter_time_activate.up&cooldown.combustion.up&(trinket.stat.intellect.cooldown_remains>95|trinket.stat.intellect.cooldown_remains+20>time_to_die)
	if BuffPresent(amplified_buff) and not SpellCooldown(alter_time) > 0 and not SpellCooldown(combustion) > 0 and { BuffCooldown(trinket_stat_intellect_buff) > 95 or BuffCooldown(trinket_stat_intellect_buff) + 20 > TimeToDie() } FireInitAlterCombustPredictActions()
	#run_action_list,name=init_alter_combust,if=buff.amplified.down&cooldown.alter_time_activate.up&cooldown.combustion.up
	if BuffExpires(amplified_buff) and not SpellCooldown(alter_time) > 0 and not SpellCooldown(combustion) > 0 FireInitAlterCombustPredictActions()
	#run_action_list,name=init_pom_combust,if=buff.amplified.up&cooldown.alter_time_activate.remains>45&cooldown.combustion.up&cooldown.presence_of_mind.up&(trinket.stat.intellect.cooldown_remains>95|trinket.stat.intellect.cooldown_remains+20>time_to_die)
	if BuffPresent(amplified_buff) and SpellCooldown(alter_time) > 45 and not SpellCooldown(combustion) > 0 and not SpellCooldown(presence_of_mind) > 0 and { BuffCooldown(trinket_stat_intellect_buff) > 95 or BuffCooldown(trinket_stat_intellect_buff) + 20 > TimeToDie() } FireInitPomCombustPredictActions()
	#run_action_list,name=init_pom_combust,if=buff.amplified.down&cooldown.alter_time_activate.remains>45&cooldown.combustion.up&cooldown.presence_of_mind.up
	if BuffExpires(amplified_buff) and SpellCooldown(alter_time) > 45 and not SpellCooldown(combustion) > 0 and not SpellCooldown(presence_of_mind) > 0 FireInitPomCombustPredictActions()
	#run_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FireAoePredictActions()
	#run_action_list,name=proc_builder,if=buff.amplified.up&trinket.stat.intellect.cooldown_remains<action.fireball.execute_time
	if BuffPresent(amplified_buff) and BuffCooldown(trinket_stat_intellect_buff) < ExecuteTime(fireball) FireProcBuilderPredictActions()
	#run_action_list,name=single_target
	FireSingleTargetPredictActions()
}

AddFunction FireDefaultShortCdActions
{
	#mana_gem,if=mana.pct<10
	if ManaPercent() < 10 UseManaGem()
	#rune_of_power,if=talent.rune_of_power.enabled&buff.rune_of_power.remains=0
	if Talent(rune_of_power_talent) and not RuneOfPowerRemaining() > 0 Spell(rune_of_power)
	#evocation,if=(talent.invocation.enabled&buff.invokers_energy.remains=0)|mana.pct<5
	if { Talent(invocation_talent) and not BuffRemaining(invokers_energy_buff) > 0 } or ManaPercent() < 5 Spell(evocation)
	#cancel_buff,name=alter_time,if=buff.amplified.up&buff.alter_time.up&(trinket.stat.intellect.cooldown_remains-buff.alter_time.remains>109)
	if BuffPresent(amplified_buff) and BuffPresent(alter_time_buff) and BuffCooldown(trinket_stat_intellect_buff) - BuffRemaining(alter_time_buff) > 109 Texture(spell_mage_altertime text=cancel)
	#run_action_list,name=combust_sequence,if=buff.alter_time.up|pyro_chain
	if BuffPresent(alter_time_buff) or GetState(pyro_chain) > 0 FireCombustSequenceShortCdActions()
	#run_action_list,name=init_alter_combust,if=buff.amplified.up&cooldown.alter_time_activate.up&cooldown.combustion.up&(trinket.stat.intellect.cooldown_remains>95|trinket.stat.intellect.cooldown_remains+20>time_to_die)
	if BuffPresent(amplified_buff) and not SpellCooldown(alter_time) > 0 and not SpellCooldown(combustion) > 0 and { BuffCooldown(trinket_stat_intellect_buff) > 95 or BuffCooldown(trinket_stat_intellect_buff) + 20 > TimeToDie() } FireInitAlterCombustShortCdActions()
	#run_action_list,name=init_alter_combust,if=buff.amplified.down&cooldown.alter_time_activate.up&cooldown.combustion.up
	if BuffExpires(amplified_buff) and not SpellCooldown(alter_time) > 0 and not SpellCooldown(combustion) > 0 FireInitAlterCombustShortCdActions()
	#run_action_list,name=init_pom_combust,if=buff.amplified.up&cooldown.alter_time_activate.remains>45&cooldown.combustion.up&cooldown.presence_of_mind.up&(trinket.stat.intellect.cooldown_remains>95|trinket.stat.intellect.cooldown_remains+20>time_to_die)
	if BuffPresent(amplified_buff) and SpellCooldown(alter_time) > 45 and not SpellCooldown(combustion) > 0 and not SpellCooldown(presence_of_mind) > 0 and { BuffCooldown(trinket_stat_intellect_buff) > 95 or BuffCooldown(trinket_stat_intellect_buff) + 20 > TimeToDie() } FireInitPomCombustShortCdActions()
	#run_action_list,name=init_pom_combust,if=buff.amplified.down&cooldown.alter_time_activate.remains>45&cooldown.combustion.up&cooldown.presence_of_mind.up
	if BuffExpires(amplified_buff) and SpellCooldown(alter_time) > 45 and not SpellCooldown(combustion) > 0 and not SpellCooldown(presence_of_mind) > 0 FireInitPomCombustShortCdActions()
	#rune_of_power,if=talent.rune_of_power.enabled&(buff.alter_time.down&buff.rune_of_power.remains<4*action.fireball.execute_time&(buff.heating_up.down|buff.pyroblast.down|!action.fireball.in_flight))
	if Talent(rune_of_power_talent) and BuffExpires(alter_time_buff) and RuneOfPowerRemaining() < 4 * ExecuteTime(fireball) and { BuffExpires(heating_up_buff) or BuffExpires(pyroblast_buff) or not InFlightToTarget(fireball) } Spell(rune_of_power)
	#evocation,if=talent.invocation.enabled&buff.alter_time.down&buff.amplified.up&(buff.invokers_energy.remains<4*action.fireball.execute_time|(buff.invokers_energy.remains<20&trinket.stat.intellect.cooldown_remains<action.fireball.execute_time))&(buff.heating_up.down|buff.pyroblast.down|!action.fireball.in_flight)
	if Talent(invocation_talent) and BuffExpires(alter_time_buff) and { BuffRemaining(invokers_energy_buff) < 4 * ExecuteTime(fireball) or BuffRemaining(invokers_energy_buff) < 20 and BuffCooldown(trinket_stat_intellect_buff) < ExecuteTime(fireball) } and { BuffExpires(heating_up_buff) or BuffExpires(pyroblast_buff) or not InFlightToTarget(fireball) } Spell(evocation)
	#evocation,if=talent.invocation.enabled&buff.alter_time.down&buff.amplified.down&buff.invokers_energy.remains<4*action.fireball.execute_time&(buff.heating_up.down|buff.pyroblast.down|!action.fireball.in_flight)
	if Talent(invocation_talent) and BuffExpires(alter_time_buff) and BuffRemaining(invokers_energy_buff) < 4 * ExecuteTime(fireball) and { BuffExpires(heating_up_buff) or BuffExpires(pyroblast_buff) or not InFlightToTarget(fireball) } Spell(evocation)
	#run_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FireAoeShortCdActions()
	#run_action_list,name=proc_builder,if=buff.amplified.up&trinket.stat.intellect.cooldown_remains<action.fireball.execute_time
	if BuffPresent(amplified_buff) and BuffCooldown(trinket_stat_intellect_buff) < ExecuteTime(fireball) FireProcBuilderShortCdActions()
	#run_action_list,name=single_target
	FireSingleTargetShortCdActions()
}

AddFunction FireDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() InterruptActions()
	#cold_snap,if=talent.cold_snap.enabled&health.pct<30
	if Talent(cold_snap_talent) and HealthPercent() < 30 Spell(cold_snap)
	#time_warp,if=buff.alter_time.down
	if BuffExpires(alter_time_buff) and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)

	unless ManaPercent() < 10 and UseManaGem()
		or Talent(rune_of_power_talent) and not RuneOfPowerRemaining() > 0 and Spell(rune_of_power)
		or { Talent(invocation_talent) and not BuffRemaining(invokers_energy_buff) > 0 } or ManaPercent() < 5 and Spell(evocation)
	{
		#run_action_list,name=combust_sequence,if=buff.alter_time.up|pyro_chain
		if BuffPresent(alter_time_buff) or GetState(pyro_chain) > 0 FireCombustSequenceCdActions()
		#run_action_list,name=init_alter_combust,if=buff.amplified.up&cooldown.alter_time_activate.up&cooldown.combustion.up&(trinket.stat.intellect.cooldown_remains>95|trinket.stat.intellect.cooldown_remains+20>time_to_die)
		if BuffPresent(amplified_buff) and not SpellCooldown(alter_time) > 0 and not SpellCooldown(combustion) > 0 and { BuffCooldown(trinket_stat_intellect_buff) > 95 or BuffCooldown(trinket_stat_intellect_buff) + 20 > TimeToDie() } FireInitAlterCombustCdActions()
		#run_action_list,name=init_alter_combust,if=buff.amplified.down&cooldown.alter_time_activate.up&cooldown.combustion.up
		if BuffExpires(amplified_buff) and not SpellCooldown(alter_time) > 0 and not SpellCooldown(combustion) > 0 FireInitAlterCombustCdActions()
		#run_action_list,name=init_pom_combust,if=buff.amplified.up&cooldown.alter_time_activate.remains>45&cooldown.combustion.up&cooldown.presence_of_mind.up&(trinket.stat.intellect.cooldown_remains>95|trinket.stat.intellect.cooldown_remains+20>time_to_die)
		if BuffPresent(amplified_buff) and SpellCooldown(alter_time) > 45 and not SpellCooldown(combustion) > 0 and not SpellCooldown(presence_of_mind) > 0 and { BuffCooldown(trinket_stat_intellect_buff) > 95 or BuffCooldown(trinket_stat_intellect_buff) + 20 > TimeToDie() } FireInitPomCombustCdActions()
		#run_action_list,name=init_pom_combust,if=buff.amplified.down&cooldown.alter_time_activate.remains>45&cooldown.combustion.up&cooldown.presence_of_mind.up
		if BuffExpires(amplified_buff) and SpellCooldown(alter_time) > 45 and not SpellCooldown(combustion) > 0 and not SpellCooldown(presence_of_mind) > 0 FireInitPomCombustCdActions()

		unless Talent(rune_of_power_talent) and BuffExpires(alter_time_buff) and RuneOfPowerRemaining() < 4 * ExecuteTime(fireball) and { BuffExpires(heating_up_buff) or BuffExpires(pyroblast_buff) or not InFlightToTarget(fireball) } and Spell(rune_of_power)
			or Talent(invocation_talent) and BuffExpires(alter_time_buff) and { BuffRemaining(invokers_energy_buff) < 4 * ExecuteTime(fireball) or BuffRemaining(invokers_energy_buff) < 20 and BuffCooldown(trinket_stat_intellect_buff) < ExecuteTime(fireball) } and { BuffExpires(heating_up_buff) or BuffExpires(pyroblast_buff) or not InFlightToTarget(fireball) } and Spell(evocation)
			or Talent(invocation_talent) and BuffExpires(alter_time_buff) and BuffRemaining(invokers_energy_buff) < 4 * ExecuteTime(fireball) and { BuffExpires(heating_up_buff) or BuffExpires(pyroblast_buff) or not InFlightToTarget(fireball) } and Spell(evocation)
		{
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
			if Enemies() >= 5 FireAoeCdActions()
			#run_action_list,name=proc_builder,if=buff.amplified.up&trinket.stat.intellect.cooldown_remains<action.fireball.execute_time
			if BuffPresent(amplified_buff) and BuffCooldown(trinket_stat_intellect_buff) < ExecuteTime(fireball) FireProcBuilderCdActions()
			#run_action_list,name=single_target
			FireSingleTargetCdActions()
		}
	}
}

# ActionList: FireProcBuilderActions --> main, predict, shortcd, cd

AddFunction FireProcBuilderActions
{
	FireProcBuilderPredictActions()

	#fireball
	Spell(fireball)
	#scorch,moving=1
	if Speed() > 0 Spell(scorch)
}

AddFunction FireProcBuilderPredictActions
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
}

AddFunction FireProcBuilderShortCdActions {}

AddFunction FireProcBuilderCdActions {}

# ActionList: FireAoeActions --> main, predict, shortcd, cd

AddFunction FireAoeActions
{
	FireAoePredictActions()

	#flamestrike
	Spell(flamestrike)
	#blizzard
	Spell(blizzard)
}

AddFunction FireAoePredictActions
{
	#inferno_blast,if=dot.combustion.ticking
	if target.DebuffPresent(combustion_debuff) Spell(inferno_blast)
}

AddFunction FireAoeShortCdActions {}

AddFunction FireAoeCdActions {}

# ActionList: FireSingleTargetActions --> main, predict, shortcd, cd

AddFunction FireSingleTargetActions
{
	FireSingleTargetPredictActions()

	#fireball
	Spell(fireball)
	#scorch,moving=1
	if Speed() > 0 Spell(scorch)
}

AddFunction FireSingleTargetPredictActions
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
}

AddFunction FireSingleTargetShortCdActions {}

AddFunction FireSingleTargetCdActions {}

# ActionList: FireInitPomCombustActions --> main, predict, shortcd, cd

AddFunction FireInitPomCombustActions
{
	#run_action_list,name=proc_builder,if=buff.pyroblast.down|buff.heating_up.down|!action.fireball.in_flight
	if BuffExpires(pyroblast_buff) or BuffExpires(heating_up_buff) or not InFlightToTarget(fireball) FireProcBuilderActions()
	#start_pyro_chain,if=!pyro_chain
	if not GetState(pyro_chain) > 0 SetState(pyro_chain 1)
}

AddFunction FireInitPomCombustPredictActions
{
	#run_action_list,name=proc_builder,if=buff.pyroblast.down|buff.heating_up.down|!action.fireball.in_flight
	if BuffExpires(pyroblast_buff) or BuffExpires(heating_up_buff) or not InFlightToTarget(fireball) FireProcBuilderPredictActions()
	#start_pyro_chain,if=!pyro_chain
	if not GetState(pyro_chain) > 0 SetState(pyro_chain 1)
}

AddFunction FireInitPomCombustShortCdActions
{
	#run_action_list,name=proc_builder,if=buff.pyroblast.down|buff.heating_up.down|!action.fireball.in_flight
	if BuffExpires(pyroblast_buff) or BuffExpires(heating_up_buff) or not InFlightToTarget(fireball) FireProcBuilderShortCdActions()
	#start_pyro_chain,if=!pyro_chain
	if not GetState(pyro_chain) > 0 SetState(pyro_chain 1)
}

AddFunction FireInitPomCombustCdActions
{
	#run_action_list,name=proc_builder,if=buff.pyroblast.down|buff.heating_up.down|!action.fireball.in_flight
	if BuffExpires(pyroblast_buff) or BuffExpires(heating_up_buff) or not InFlightToTarget(fireball) FireProcBuilderCdActions()
	#start_pyro_chain,if=!pyro_chain
	if not GetState(pyro_chain) > 0 SetState(pyro_chain 1)
}

# ActionList: FireCombustSequenceActions --> main, predict, shortcd, cd

AddFunction FireCombustSequenceActions
{
	FireCombustSequencePredictActions()
}

AddFunction FireCombustSequencePredictActions
{
	#start_pyro_chain,if=!pyro_chain
	if not GetState(pyro_chain) > 0 SetState(pyro_chain 1)
	#stop_pyro_chain,if=cooldown.combustion.remains>0&pyro_chain
	if SpellCooldown(combustion) > 0 and GetState(pyro_chain) > 0 SetState(pyro_chain 0)
	#pyroblast,if=execute_time=gcd&buff.alter_time.up
	if ExecuteTime(pyroblast) == GCD() and BuffPresent(alter_time_buff) Spell(pyroblast)
	#pyroblast,if=talent.presence_of_mind.enabled&buff.presence_of_mind.up&buff.pyroblast.up
	if Talent(presence_of_mind_talent) and BuffPresent(presence_of_mind_buff) and BuffPresent(pyroblast_buff) Spell(pyroblast)
	#pyroblast,if=!talent.presence_of_mind.enabled&buff.pyroblast.up
	if Talent(presence_of_mind_talent no) and BuffPresent(pyroblast_buff) Spell(pyroblast)
	#pyroblast,if=buff.presence_of_mind.up&(travel_time+0.15<dot.ignite.remains-4|(crit_damage*crit_pct_current+hit_damage*(100-crit_pct_current))*0.01*mastery_value>dot.ignite.tick_dmg)
	if BuffPresent(presence_of_mind_buff) and { 0.5 + 0.15 < target.DebuffRemaining(ignite_debuff) - 4 or { CritDamage(pyroblast) * SpellCritChance() + Damage(pyroblast) * { 100 - SpellCritChance() } } * 0.01 * { MasteryEffect() / 100 } > target.TickValue(ignite_debuff) } Spell(pyroblast)
	#pyroblast,if=buff.presence_of_mind.up&buff.heating_up.up&gcd+travel_time+0.15<dot.ignite.remains-2&(crit_damage*crit_pct_current+hit_damage*(100-crit_pct_current))*0.01*(0.0125*crit_pct_current+1)*mastery_value>dot.ignite.tick_dmg
	if BuffPresent(presence_of_mind_buff) and BuffPresent(heating_up_buff) and GCD() + 0.5 + 0.15 < target.DebuffRemaining(ignite_debuff) - 2 and { CritDamage(pyroblast) * SpellCritChance() + Damage(pyroblast) * { 100 - SpellCritChance() } } * 0.01 * { 0.0125 * SpellCritChance() + 1 } * { MasteryEffect() / 100 } > target.TickValue(ignite_debuff) Spell(pyroblast)
	#pyroblast,if=buff.presence_of_mind.down&buff.pyroblast.up&(travel_time+0.15<dot.ignite.remains-4|(crit_damage*crit_pct_current+hit_damage*(100-crit_pct_current))*0.01*mastery_value>dot.ignite.tick_dmg)
	if BuffExpires(presence_of_mind_buff) and BuffPresent(pyroblast_buff) and { 0.5 + 0.15 < target.DebuffRemaining(ignite_debuff) - 4 or { CritDamage(pyroblast) * SpellCritChance() + Damage(pyroblast) * { 100 - SpellCritChance() } } * 0.01 * { MasteryEffect() / 100 } > target.TickValue(ignite_debuff) } Spell(pyroblast)
}

AddFunction FireCombustSequenceShortCdActions
{
	#start_pyro_chain,if=!pyro_chain
	if not GetState(pyro_chain) > 0 SetState(pyro_chain 1)
	#stop_pyro_chain,if=cooldown.combustion.remains>0&pyro_chain
	if SpellCooldown(combustion) > 0 and GetState(pyro_chain) > 0 SetState(pyro_chain 0)
	#presence_of_mind,if=talent.presence_of_mind.enabled&buff.alter_time.down
	if Talent(presence_of_mind_talent) and BuffExpires(alter_time_buff) Spell(presence_of_mind)

	unless ExecuteTime(pyroblast) == GCD() and BuffPresent(alter_time_buff) and Spell(pyroblast)
		or Talent(presence_of_mind_talent) and BuffPresent(presence_of_mind_buff) and BuffPresent(pyroblast_buff) and Spell(pyroblast)
		or Talent(presence_of_mind_talent no) and BuffPresent(pyroblast_buff) and Spell(pyroblast)
	{
		#combustion,if=buff.alter_time.down&cooldown.alter_time_activate.remains>150&buff.tempus_repit.up&buff.tempus_repit.remains<gcd
		if BuffExpires(alter_time_buff) and SpellCooldown(alter_time) > 150 and BuffPresent(tempus_repit_buff) and BuffRemaining(tempus_repit_buff) < GCD() Spell(combustion)

		unless BuffPresent(presence_of_mind_buff) and { 0.5 + 0.15 < target.DebuffRemaining(ignite_debuff) - 4 or { CritDamage(pyroblast) * SpellCritChance() + Damage(pyroblast) * { 100 - SpellCritChance() } } * 0.01 * { MasteryEffect() / 100 } > target.TickValue(ignite_debuff) } and Spell(pyroblast)
			or BuffPresent(presence_of_mind_buff) and BuffPresent(heating_up_buff) and GCD() + 0.5 + 0.15 < target.DebuffRemaining(ignite_debuff) - 2 and { CritDamage(pyroblast) * SpellCritChance() + Damage(pyroblast) * { 100 - SpellCritChance() } } * 0.01 * { 0.0125 * SpellCritChance() + 1 } * { MasteryEffect() / 100 } > target.TickValue(ignite_debuff) and Spell(pyroblast)
			or BuffExpires(presence_of_mind_buff) and BuffPresent(pyroblast_buff) and { 0.5 + 0.15 < target.DebuffRemaining(ignite_debuff) - 4 or { CritDamage(pyroblast) * SpellCritChance() + Damage(pyroblast) * { 100 - SpellCritChance() } } * 0.01 * { MasteryEffect() / 100 } > target.TickValue(ignite_debuff) } and Spell(pyroblast)
		{
			#combustion
			Spell(combustion)
		}
	}
}

AddFunction FireCombustSequenceCdActions
{
	#start_pyro_chain,if=!pyro_chain
	if not GetState(pyro_chain) > 0 SetState(pyro_chain 1)
	#stop_pyro_chain,if=cooldown.combustion.remains>0&pyro_chain
	if SpellCooldown(combustion) > 0 and GetState(pyro_chain) > 0 SetState(pyro_chain 0)

	unless ExecuteTime(pyroblast) == GCD() and BuffPresent(alter_time_buff) and Spell(pyroblast)
	{
		#alter_time,if=buff.alter_time.up&action.pyroblast.execute_time>gcd
		# CHANGE: This is meant to trigger Alter Time while Alter Time is active.
		#if BuffPresent(alter_time_buff) and ExecuteTime(pyroblast) > GCD() Spell(alter_time)
		if BuffPresent(alter_time_buff) and ExecuteTime(pyroblast) > GCD() Spell(alter_time_trigger)
	}
}

# ActionList: FireInitAlterCombustActions --> main, predict, shortcd, cd

AddFunction FireInitAlterCombustActions
{
	#run_action_list,name=proc_builder,if=buff.pyroblast.down|buff.heating_up.down|!action.fireball.in_flight
	if BuffExpires(pyroblast_buff) or BuffExpires(heating_up_buff) or not InFlightToTarget(fireball) FireProcBuilderActions()
}

AddFunction FireInitAlterCombustPredictActions
{
	#run_action_list,name=proc_builder,if=buff.pyroblast.down|buff.heating_up.down|!action.fireball.in_flight
	if BuffExpires(pyroblast_buff) or BuffExpires(heating_up_buff) or not InFlightToTarget(fireball) FireProcBuilderPredictActions()
}

AddFunction FireInitAlterCombustShortCdActions
{
	#run_action_list,name=proc_builder,if=buff.pyroblast.down|buff.heating_up.down|!action.fireball.in_flight
	if BuffExpires(pyroblast_buff) or BuffExpires(heating_up_buff) or not InFlightToTarget(fireball) FireProcBuilderShortCdActions()
	#presence_of_mind,if=talent.presence_of_mind.enabled
	if Talent(presence_of_mind_talent) Spell(presence_of_mind)
}

AddFunction FireInitAlterCombustCdActions
{
	#run_action_list,name=proc_builder,if=buff.pyroblast.down|buff.heating_up.down|!action.fireball.in_flight
	if BuffExpires(pyroblast_buff) or BuffExpires(heating_up_buff) or not InFlightToTarget(fireball) FireProcBuilderCdActions()
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
	#alter_time
	Spell(alter_time)
}

# ActionList: FirePrecombatActions --> main, predict, shortcd, cd

AddFunction FirePrecombatActions
{
	FirePrecombatPredictActions()
}

AddFunction FirePrecombatPredictActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#molten_armor
	if BuffExpires(molten_armor_buff) Spell(molten_armor)
	#snapshot_stats
	#pyroblast
	Spell(pyroblast)
}

AddFunction FirePrecombatShortCdActions
{
	unless BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) and Spell(arcane_brilliance)
		or BuffExpires(molten_armor_buff) and Spell(molten_armor)
	{
		#evocation,if=talent.invocation.enabled
		# CHANGE: Only suggest Evocation if the Invocation buff needs to be topped off prior to pull.
		#if Talent(invocation_talent) Spell(evocation)
		if Talent(invocation_talent) and BuffRemaining(invokers_energy_buff) < 45 Spell(evocation)
		#rune_of_power,if=talent.rune_of_power.enabled
		# CHANGE: Only suggest Rune of Power if the rune needs to be refreshed prior to pull.
		#if Talent(rune_of_power_talent) Spell(rune_of_power)
		if Talent(rune_of_power_talent) and RuneOfPowerRemaining() < 45 Spell(rune_of_power)
	}
}

AddFunction FirePrecombatCdActions
{
	unless BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) and Spell(arcane_brilliance)
		or BuffExpires(molten_armor_buff) and Spell(molten_armor)
		or Talent(invocation_talent) and BuffRemaining(invokers_energy_buff) < 45 and Spell(evocation)
		or Talent(rune_of_power_talent) and RuneOfPowerRemaining() < 45 and Spell(rune_of_power)
	{
		#jade_serpent_potion
		UsePotionIntellect()
		#mirror_image
		Spell(mirror_image)
	}
}

### Fire icons.
AddCheckBox(opt_mage_fire "Show Fire icons" specialization=fire default)
AddCheckBox(opt_mage_fire_aoe L(AOE) specialization=fire default)

AddIcon specialization=fire help=shortcd enemies=1 checkbox=opt_mage_fire checkbox=!opt_mage_fire_aoe
{
	if InCombat(no) FirePrecombatShortCdActions()
	FireDefaultShortCdActions()
}

AddIcon specialization=fire help=shortcd checkbox=opt_mage_fire checkbox=opt_mage_fire_aoe
{
	if InCombat(no) FirePrecombatShortCdActions()
	FireDefaultShortCdActions()
}

AddIcon specialization=fire help=main enemies=1 checkbox=opt_mage_fire
{
	if InCombat(no) FirePrecombatActions()
	FireDefaultActions()
}

AddIcon specialization=fire help=predict enemies=1 checkbox=opt_mage_fire checkbox=!opt_mage_fire_aoe
{
	if InCombat(no) FirePrecombatPredictActions()
	FireDefaultPredictActions()
}

AddIcon specialization=fire help=aoe checkbox=opt_mage_fire checkbox=opt_mage_fire_aoe
{
	if InCombat(no) FirePrecombatActions()
	FireDefaultActions()
}

AddIcon specialization=fire help=cd enemies=1 checkbox=opt_mage_fire checkbox=!opt_mage_fire_aoe
{
	if InCombat(no) FirePrecombatCdActions()
	FireDefaultCdActions()
}

AddIcon specialization=fire help=cd checkbox=opt_mage_fire checkbox=opt_mage_fire_aoe
{
	if InCombat(no) FirePrecombatCdActions()
	FireDefaultCdActions()
}

###
### Frost
###
# Based on SimulationCraft profile "Mage_Frost_T16H".
#	class=mage
#	spec=frost
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#eb!0...11
#	glyphs=evocation/icy_veins/splitting_ice

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

# ActionList: FrostPrecombatActions --> main, predict, shortcd, cd

AddFunction FrostPrecombatActions
{
	FrostPrecombatPredictActions()
}

AddFunction FrostPrecombatPredictActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#arcane_brilliance
	if BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) Spell(arcane_brilliance)
	#frost_armor
	if BuffExpires(frost_armor_buff) Spell(frost_armor)
	#snapshot_stats
	#frostbolt
	Spell(frostbolt)
}

AddFunction FrostPrecombatShortCdActions
{
	unless BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) and Spell(arcane_brilliance)
		or BuffExpires(frost_armor_buff) and Spell(frost_armor)
	{
		#water_elemental
		if pet.Present(no) Spell(water_elemental)
		#evocation,if=talent.invocation.enabled
		# CHANGE: Only suggest Evocation if the Invocation buff needs to be topped off prior to pull.
		#if Talent(invocation_talent) Spell(evocation)
		if Talent(invocation_talent) and BuffRemaining(invokers_energy_buff) < 45 Spell(evocation)
		#rune_of_power,if=talent.rune_of_power.enabled
		# CHANGE: Only suggest Rune of Power if the rune needs to be refreshed prior to pull.
		#if Talent(rune_of_power_talent) Spell(rune_of_power)
		if Talent(rune_of_power_talent) and RuneOfPowerRemaining() < 45 Spell(rune_of_power)
	}
}

AddFunction FrostPrecombatCdActions
{
	unless BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1) and Spell(arcane_brilliance)
		or BuffExpires(frost_armor_buff) and Spell(frost_armor)
		or pet.Present(no) and Spell(water_elemental)
		or Talent(invocation_talent) and BuffRemaining(invokers_energy_buff) < 45 and Spell(evocation)
		or Talent(rune_of_power_talent) and Spell(rune_of_power)
	{
		#jade_serpent_potion
		UsePotionIntellect()
		#mirror_image
		Spell(mirror_image)
	}
}

# ActionList: FrostDefaultActions --> main, predict, shortcd, cd

AddFunction FrostDefaultActions
{
	FrostDefaultPredictActions()

	#frostbolt
	Spell(frostbolt)
	#ice_floes,if=talent.ice_floes.enabled
	#fire_blast,moving=1
	if Speed() > 0 Spell(fire_blast)
	#ice_lance,moving=1
	if Speed() > 0 Spell(ice_lance)
}

AddFunction FrostDefaultPredictActions
{
	#flamestrike,if=active_enemies>=5
	if Enemies() >= 5 Spell(flamestrike)
	#fire_blast,if=time_to_die<action.ice_lance.travel_time
	if TimeToDie() < 0.5 Spell(fire_blast)
	#frostfire_bolt,if=buff.alter_time.up&buff.brain_freeze.react
	if BuffPresent(alter_time_buff) and BuffPresent(brain_freeze_buff) Spell(frostfire_bolt)
	#frostfire_bolt,if=buff.brain_freeze.react&cooldown.icy_veins.remains>2*action.frostbolt.execute_time
	# CHANGE: Also consume Brain Freeze if Icy Veins isn't on cooldown in case Icy Veins was delayed by the player.
	#if BuffPresent(brain_freeze_buff) and IcyVeinsCooldownRemaining() > 2 * ExecuteTime(frostbolt) Spell(frostfire_bolt)
	if BuffPresent(brain_freeze_buff) and { not IcyVeinsCooldownRemaining() > 0 or IcyVeinsCooldownRemaining() > 2 * ExecuteTime(frostbolt) } Spell(frostfire_bolt)
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
	# CHANGE: Also consume Fingers of Frost if Icy Veins isn't on cooldown in case Icy Veins was delayed by the player.
	#if BuffPresent(fingers_of_frost_buff) and IcyVeinsCooldownRemaining() > 2 * ExecuteTime(frostbolt) Spell(ice_lance)
	if BuffPresent(fingers_of_frost_buff) and { not IcyVeinsCooldownRemaining() > 0 or IcyVeinsCooldownRemaining() > 2 * ExecuteTime(frostbolt) } Spell(ice_lance)
}

AddFunction FrostDefaultShortCdActions
{
	#cancel_buff,name=alter_time,moving=1
	#conjure_mana_gem,if=mana_gem_charges<3&target.debuff.invulnerable.react
	if ItemCharges(mana_gem) < 3 and InCombat(no) ConjureManaGem()
	#mana_gem,if=mana.pct<10
	if ManaPercent() < 10 UseManaGem()
	#rune_of_power,if=talent.rune_of_power.enabled&(buff.rune_of_power.remains<cast_time&buff.alter_time.down)
	if Talent(rune_of_power_talent) and RuneOfPowerRemaining() < CastTime(rune_of_power) and BuffExpires(alter_time_buff) Spell(rune_of_power)
	#rune_of_power,if=talent.rune_of_power.enabled&(cooldown.icy_veins.remains=0&buff.rune_of_power.remains<20)
	if Talent(rune_of_power_talent) and not IcyVeinsCooldownRemaining() > 0 and RuneOfPowerRemaining() < 20 Spell(rune_of_power)
	#evocation,if=talent.invocation.enabled&(buff.invokers_energy.down|mana.pct<10)&buff.alter_time.down
	if Talent(invocation_talent) and { BuffExpires(invokers_energy_buff) or ManaPercent() < 10 } and BuffExpires(alter_time_buff) Spell(evocation)
	#evocation,if=talent.invocation.enabled&cooldown.icy_veins.remains=0&buff.invokers_energy.remains<20
	if Talent(invocation_talent) and not IcyVeinsCooldownRemaining() > 0 and BuffRemaining(invokers_energy_buff) < 20 Spell(evocation)
	#evocation,if=!talent.invocation.enabled&mana.pct<50,interrupt_if=mana.pct>95
	if Talent(invocation_talent no) and ManaPercent() < 50 Spell(evocation)
	#frozen_orb,if=buff.fingers_of_frost.stack<2
	#presence_of_mind,sync=alter_time_activate,if=talent.presence_of_mind.enabled
	if not SpellCooldown(alter_time) > 0 and Talent(presence_of_mind_talent) Spell(presence_of_mind)

	unless Enemies() >= 5 and Spell(flamestrike)
		or TimeToDie() < 0.5 and Spell(fire_blast)
		or BuffPresent(alter_time_buff) and BuffPresent(brain_freeze_buff) and Spell(frostfire_bolt)
		or BuffPresent(brain_freeze_buff) and { not IcyVeinsCooldownRemaining() > 0 or IcyVeinsCooldownRemaining() > 2 * ExecuteTime(frostbolt) } and Spell(frostfire_bolt)
		or Talent(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemaining(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 and Spell(nether_tempest)
		or Talent(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemaining(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 and Spell(living_bomb)
		or Talent(frost_bomb_talent) and target.TimeToDie() > CastTime(frost_bomb) + target.TickTime(frost_bomb_debuff) and Spell(frost_bomb)
		or BuffPresent(alter_time_buff) and BuffPresent(fingers_of_frost_buff) and Spell(ice_lance)
		or BuffPresent(fingers_of_frost_buff) and BuffRemaining(fingers_of_frost_buff) < GCD() and Spell(ice_lance)
		or not SpellCooldown(frozen_orb) > SpellCooldownDuration(frozen_orb) - 10 and SpellHaste() / 100 < 0.55 and BuffRemaining(burst_haste_buff any=1) < { 2.5 - BuffStacks(fingers_of_frost_buff) } * 8 * ExecuteTime(frostbolt) and BuffRemaining(tempus_repit_buff) < { 2.5 - BuffStacks(fingers_of_frost_buff) } * 8 * ExecuteTime(frostbolt) and Spell(frostbolt)
		or BuffPresent(fingers_of_frost_buff) and { not IcyVeinsCooldownRemaining() > 0 or IcyVeinsCooldownRemaining() > 2 * ExecuteTime(frostbolt) } and Spell(ice_lance)
	{
		#rune_of_power,if=talent.rune_of_power.enabled&(buff.amplified.up&trinket.stat.intellect.cooldown_remains=0&buff.rune_of_power.remains<20)
		if Talent(rune_of_power_talent) and BuffPresent(amplified_buff) and not BuffCooldown(trinket_stat_intellect_buff) > 0 and RuneOfPowerRemaining() < 20 Spell(rune_of_power)
		#evocation,if=talent.invocation.enabled&buff.amplified.up&trinket.stat.intellect.cooldown_remains=0&buff.invokers_energy.remains<20
		if Talent(invocation_talent) and BuffPresent(amplified_buff) and not BuffCooldown(trinket_stat_intellect_buff) > 0 and BuffRemaining(invokers_energy_buff) < 20 Spell(evocation)
		#presence_of_mind,if=talent.presence_of_mind.enabled&cooldown.alter_time_activate.remains>0
		if Talent(presence_of_mind_talent) and SpellCooldown(alter_time) > 0 Spell(presence_of_mind)
	}
}

AddFunction FrostDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() InterruptActions()
	#cold_snap,if=talent.cold_snap.enabled&health.pct<30
	if Talent(cold_snap_talent) and HealthPercent() < 30 Spell(cold_snap)

	unless ItemCharges(mana_gem) < 3 and InCombat(no) and ConjureManaGem()
	{
		#time_warp,if=target.health.pct<25|time>5
		if { target.HealthPercent() < 25 or TimeInCombat() > 5 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)

		unless ManaPercent() < 10 and UseManaGem()
			or Talent(rune_of_power_talent) and RuneOfPowerRemaining() < CastTime(rune_of_power) and BuffExpires(alter_time_buff) and Spell(rune_of_power)
			or Talent(rune_of_power_talent) and not IcyVeinsCooldownRemaining() > 0 and RuneOfPowerRemaining() < 20 and Spell(rune_of_power)
			or Talent(invocation_talent) and { BuffExpires(invokers_energy_buff) or ManaPercent() < 10 } and BuffExpires(alter_time_buff) and Spell(evocation)
			or Talent(invocation_talent) and not IcyVeinsCooldownRemaining() > 0 and BuffRemaining(invokers_energy_buff) < 20 and Spell(evocation)
			or Talent(invocation_talent no) and ManaPercent() < 50 and Spell(evocation)
		{
			#mirror_image
			Spell(mirror_image)

			unless BuffStacks(fingers_of_frost_buff) < 2 and Spell(frozen_orb)
			{
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
				#use_item,slot=hands,sync=alter_time_activate,if=buff.alter_time.down
				if BuffExpires(alter_time_buff) and not SpellCooldown(alter_time) > 0 UseItemActions()
				#alter_time,if=buff.alter_time.down&buff.icy_veins.up&trinket.stat.intellect.cooldown_remains>25
				if BuffExpires(alter_time_buff) and BuffPresent(icy_veins_buff) and BuffCooldown(trinket_stat_intellect_buff) > 25 Spell(alter_time)
				#alter_time,if=buff.alter_time.down&buff.icy_veins.up&buff.amplified.down
				if BuffExpires(alter_time_buff) and BuffPresent(icy_veins_buff) and BuffExpires(amplified_buff) Spell(alter_time)
				#use_item,slot=hands,if=(cooldown.alter_time_activate.remains>45|target.time_to_die<25)&(buff.rune_of_power.remains>20|buff.invokers_energy.remains>20|(!talent.rune_of_power.enabled&!talent.invocation.enabled))
				if { SpellCooldown(alter_time) > 45 or target.TimeToDie() < 25 } and { RuneOfPowerRemaining() > 20 or BuffRemaining(invokers_energy_buff) > 20 or Talent(rune_of_power_talent no) and Talent(invocation_talent no) } UseItemActions()
			}
		}
	}
}

### Frost icons.
AddCheckBox(opt_mage_frost "Show Frost icons" specialization=frost default)
AddCheckBox(opt_mage_frost_aoe L(AOE) specialization=frost default)

AddIcon specialization=frost help=shortcd enemies=1 checkbox=opt_mage_frost checkbox=!opt_mage_frost_aoe
{
	if InCombat(no) FrostPrecombatShortCdActions()
	FrostDefaultShortCdActions()
}

AddIcon specialization=frost help=shortcd checkbox=opt_mage_frost checkbox=opt_mage_frost_aoe
{
	if InCombat(no) FrostPrecombatShortCdActions()
	FrostDefaultShortCdActions()
}

AddIcon specialization=frost help=main enemies=1 checkbox=opt_mage_frost
{
	if InCombat(no) FrostPrecombatActions()
	FrostDefaultActions()
}

AddIcon specialization=frost help=predict enemies=1 checkbox=opt_mage_frost checkbox=!opt_mage_frost_aoe
{
	if InCombat(no) FrostPrecombatPredictActions()
	FrostDefaultPredictActions()
}

AddIcon specialization=frost help=aoe checkbox=opt_mage_frost checkbox=opt_mage_frost_aoe
{
	if InCombat(no) FrostPrecombatActions()
	FrostDefaultActions()
}

AddIcon specialization=frost help=cd enemies=1 checkbox=opt_mage_frost checkbox=!opt_mage_frost_aoe
{
	if InCombat(no) FrostPrecombatCdActions()
	FrostDefaultCdActions()
}

AddIcon specialization=frost help=cd checkbox=opt_mage_frost checkbox=opt_mage_frost_aoe
{
	if InCombat(no) FrostPrecombatCdActions()
	FrostDefaultCdActions()
}
]]

	OvaleScripts:RegisterScript("MAGE", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("MAGE", "Ovale", desc, code, "script")
end
