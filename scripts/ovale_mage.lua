local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.4] Ovale: Arcane, Fire, Frost"
	local code = [[
# Ovale mage script based on SimulationCraft.

Include(ovale_items)
Include(ovale_racials)
Include(ovale_mage_spells)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

###
### Arcane
###
# Based on SimulationCraft profile "Mage_Arcane_T16H".
#	class=mage
#	spec=arcane
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#ea!0...11
#	glyphs=mana_gem/mirror_image/arcane_power

AddFunction ArcaneAoeActions
{
	#flamestrike
	Spell(flamestrike)
	#nether_tempest,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>6
	if TalentPoints(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemains(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 Spell(nether_tempest)
	#living_bomb,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>tick_time*3
	if TalentPoints(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemains(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#frost_bomb,if=!ticking&target.time_to_die>tick_time*3
	if TalentPoints(frost_bomb_talent) and not target.DebuffPresent(frost_bomb_debuff) and target.TimeToDie() > target.TickTime(frost_bomb_debuff) * 3 Spell(frost_bomb)
	#arcane_barrage,if=buff.arcane_charge.stack>=4
	if DebuffStacks(arcane_charge_debuff) >= 4 Spell(arcane_barrage)
	#arcane_explosion
	Spell(arcane_explosion)
}

AddFunction ArcaneSingleTargetActions
{
	#arcane_barrage,if=buff.alter_time.up&buff.alter_time.remains<2
	if BuffPresent(alter_time_buff) and BuffRemains(alter_time_buff) < 2 Spell(arcane_barrage)
	#arcane_missiles,if=buff.alter_time.up
	if BuffPresent(arcane_missiles_buff) and BuffPresent(alter_time_buff) Spell(arcane_missiles)
	#arcane_blast,if=buff.alter_time.up
	if BuffPresent(alter_time_buff) Spell(arcane_blast)
	#arcane_blast,if=buff.profound_magic.up&buff.arcane_charge.stack>3&mana.pct>93
	if BuffPresent(profound_magic_buff) and DebuffStacks(arcane_charge_debuff) > 3 and ManaPercent() > 93 Spell(arcane_blast)
	#arcane_missiles,if=(buff.arcane_missiles.stack=2&cooldown.arcane_power.remains>0)|(buff.arcane_charge.stack>=4&cooldown.arcane_power.remains>8)
	if BuffPresent(arcane_missiles_buff) and { { BuffStacks(arcane_missiles_buff) == 2 and SpellCooldown(arcane_power) > 0 } or { DebuffStacks(arcane_charge_debuff) >= 4 and SpellCooldown(arcane_power) > 8 } } Spell(arcane_missiles)
	#nether_tempest,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>6
	if TalentPoints(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemains(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 Spell(nether_tempest)
	#living_bomb,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>tick_time*3
	if TalentPoints(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemains(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#frost_bomb,if=!ticking&target.time_to_die>tick_time*3
	if TalentPoints(frost_bomb_talent) and not target.DebuffPresent(frost_bomb_debuff) and target.TimeToDie() > target.TickTime(frost_bomb_debuff) * 3 Spell(frost_bomb)
	#arcane_barrage,if=buff.arcane_charge.stack>=4&mana.pct<95
	if DebuffStacks(arcane_charge_debuff) >= 4 and ManaPercent() < 95 Spell(arcane_barrage)
	#presence_of_mind
	if TalentPoints(presence_of_mind_talent) Spell(presence_of_mind)
	#arcane_blast
	Spell(arcane_blast)
}

AddFunction ArcaneSingleTargetMovingActions
{
	#arcane_barrage,if=buff.alter_time.up&buff.alter_time.remains<2
	if BuffPresent(alter_time_buff) and BuffRemains(alter_time_buff) < 2 Spell(arcane_barrage)
	#nether_tempest,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>6
	if TalentPoints(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemains(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 Spell(nether_tempest)
	#living_bomb,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>tick_time*3
	if TalentPoints(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemains(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#frost_bomb,if=!ticking&target.time_to_die>tick_time*3
	if TalentPoints(frost_bomb_talent) and not target.DebuffPresent(frost_bomb_debuff) and target.TimeToDie() > target.TickTime(frost_bomb_debuff) * 3 Spell(frost_bomb)
	#arcane_barrage,if=buff.arcane_charge.stack>=4&mana.pct<95
	if DebuffStacks(arcane_charge_debuff) >= 4 and ManaPercent() < 95 Spell(arcane_barrage)
	#presence_of_mind
	if TalentPoints(presence_of_mind_talent) Spell(presence_of_mind)
	#arcane_blast
	if BuffPresent(presence_of_mind_buff) Spell(arcane_blast)
	#arcane_barrage,moving=1
	Spell(arcane_barrage)
	#fire_blast,moving=1
	Spell(fire_blast)
	#ice_lance,moving=1
	Spell(ice_lance)
}

AddFunction ArcaneDefaultActions
{
	#cancel_buff,name=alter_time,moving=1
	#conjure_mana_gem,if=mana_gem_charges<3&target.debuff.invulnerable.react
	if ItemCharges(mana_gem) < 3 and target.InCombat(no) ConjureManaGem()
	#run_action_list,name=aoe,if=active_enemies>=6
	#run_action_list,name=single_target,if=active_enemies<6
}

AddFunction ArcaneDefaultManaActions
{
	#rune_of_power,if=buff.rune_of_power.remains<cast_time
	if TalentPoints(rune_of_power_talent) and RuneOfPowerRemains() < CastTime(rune_of_power) Spell(rune_of_power)
	#rune_of_power,if=cooldown.arcane_power.remains=0&buff.rune_of_power.remains<buff.arcane_power.duration
	if TalentPoints(rune_of_power_talent) and Spell(arcane_power) and RuneOfPowerRemains() < SpellData(arcane_power_buff duration) Spell(rune_of_power)
	#evocation,if=buff.invokers_energy.down
	if TalentPoints(invocation_talent) and BuffExpires(invokers_energy_buff) Spell(evocation)
	#evocation,if=cooldown.arcane_power.remains=0&buff.invokers_energy.remains<buff.arcane_power.duration
	if TalentPoints(invocation_talent) and Spell(arcane_power) and BuffRemains(invokers_energy_buff) < SpellData(arcane_power_buff duration) Spell(evocation)
	#evocation,if=mana.pct<50,interrupt_if=mana.pct>95&buff.invokers_energy.remains>10
	if not TalentPoints(rune_of_power_talent) and ManaPercent() < 50 Spell(evocation)
}

AddFunction ArcaneDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() Spell(counterspell)
	UseRacialInterruptActions()

	unless { TalentPoints(rune_of_power_talent) and RuneOfPowerRemains() < CastTime(rune_of_power) }
		or { TalentPoints(rune_of_power_talent) and Spell(arcane_power) and RuneOfPowerRemains() < SpellData(arcane_power_buff duration) }
		or { TalentPoints(invocation_talent) and BuffExpires(invokers_energy_buff) }
		or { TalentPoints(invocation_talent) and Spell(arcane_power) and BuffRemains(invokers_energy_buff) < SpellData(arcane_power_buff duration) }
		or { not TalentPoints(rune_of_power_talent) and ManaPercent() < 50 and Spell(evocation) }
	{
		#mirror_image
		Spell(mirror_image)
		#mana_gem,if=mana.pct<80&buff.alter_time.down
		if ManaPercent() < 80 and BuffExpires(alter_time_buff) UseManaGem()
		#arcane_power,if=time_to_bloodlust>180&((buff.rune_of_power.remains>=buff.arcane_power.duration&buff.arcane_missiles.stack=2&buff.arcane_charge.stack>2)|target.time_to_die<buff.arcane_power.duration+5),moving=0
		if TalentPoints(rune_of_power_talent) and TimeToBloodlust() > SpellData(arcane_power cd) and { { RuneOfPowerRemains() >= SpellData(arcane_power_buff duration) and BuffStacks(arcane_missiles_buff) == 2 and DebuffStacks(arcane_charge_debuff) > 2 } or target.TimeToDie() < SpellData(arcane_power_buff duration) + 5 } Spell(arcane_power)
		#arcane_power,if=time_to_bloodlust>180&((buff.invokers_energy.remains>=buff.arcane_power.duration&buff.arcane_missiles.stack=2&buff.arcane_charge.stack>2)|target.time_to_die<buff.arcane_power.duration+5),moving=0
		if TalentPoints(invocation_talent) and TimeToBloodlust() > SpellData(arcane_power cd) and { { BuffRemains(invokers_energy_buff) >= SpellData(arcane_power_buff duration) and BuffStacks(arcane_missiles_buff) == 2 and DebuffStacks(arcane_charge_debuff) > 2 } or target.TimeToDie() < SpellData(arcane_power_buff duration) + 5 } Spell(arcane_power)
		#arcane_power,if=time_to_bloodlust>180&((buff.arcane_missiles.stack=2&buff.arcane_charge.stack>2)|target.time_to_die<buff.arcane_power.duration+5),moving=0
		if not TalentPoints(rune_of_power_talent) and not TalentPoints(invocation_talent) and TimeToBloodlust() > SpellData(arcane_power cd) and { { BuffStacks(arcane_missiles_buff) == 2 and DebuffStacks(arcane_charge_debuff) > 2 } or target.TimeToDie() < SpellData(arcane_power_buff duration) + 5 } Spell(arcane_power)
		#blood_fury,if=buff.alter_time.down&(buff.arcane_power.up|cooldown.arcane_power.remains>15|target.time_to_die<18)
		if BuffExpires(alter_time_buff) and { BuffPresent(arcane_power_buff) or SpellCooldown(arcane_power) > 15 or target.TimeToDie() < 18 } Spell(blood_fury)
		#berserking,if=buff.alter_time.down&(buff.arcane_power.up|target.time_to_die<18)
		if BuffExpires(alter_time_buff) and { BuffPresent(arcane_power_buff) or target.TimeToDie() < 18 } Spell(berserking)
		#jade_serpent_potion,if=buff.alter_time.down&(buff.arcane_power.up|target.time_to_die<50)
		if BuffExpires(alter_time_buff) and { BuffPresent(arcane_power_buff) or target.TimeToDie() < 50 } UsePotionIntellect()
		#use_item,slot=hands,sync=alter_time_activate,if=buff.alter_time.down
		if Spell(alter_time_activate) and BuffExpires(alter_time_buff) UseItemActions()
		#alter_time,if=buff.alter_time.down&buff.arcane_power.up
		if BuffExpires(alter_time_buff) and BuffPresent(arcane_power_buff) Spell(alter_time)
		#use_item,slot=hands,if=(cooldown.alter_time_activate.remains>45|target.time_to_die<25)&buff.rune_of_power.remains>20
		if TalentPoints(rune_of_power_talent) and { SpellCooldown(alter_time_activate) > 45 or target.TimeToDie() < 25 } and RuneOfPowerRemains() > 20 UseItemActions()
		#use_item,slot=hands,if=(cooldown.alter_time_activate.remains>45|target.time_to_die<25)&buff.invokers_energy.remains>20
		if TalentPoints(invocation_talent) and { SpellCooldown(alter_time_activate) > 45 or target.TimeToDie() < 25 } and BuffRemains(invokers_energy_buff) > 20 UseItemActions()
		#use_item,slot=hands,if=cooldown.alter_time_activate.remains>45|target.time_to_die<25
		if not TalentPoints(rune_of_power_talent) and not TalentPoints(invocation_talent) and { SpellCooldown(alter_time_activate) > 45 or target.TimeToDie() < 25 } UseItemActions()
	}
}

AddFunction ArcanePrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#arcane_brilliance
	if BuffExpires(critical_strike any=1) or BuffExpires(spell_power_multiplier any=1) Spell(arcane_brilliance)
	#frost_armor,if=set_bonus.tier16_2pc=1
	if ArmorSetBonus(T16_caster 2) == 1 and BuffExpires(frost_armor_buff) Spell(frost_armor)
	#mage_armor,if=set_bonus.tier16_2pc=0
	if ArmorSetBonus(T16_caster 2) == 0 and BuffExpires(mage_armor_buff) Spell(mage_armor)
	#snapshot_stats
}

AddFunction ArcanePrecombatManaActions
{
	#evocation
	if TalentPoints(invocation_talent) Spell(evocation)
	#rune_of_power
	if TalentPoints(rune_of_power_talent) Spell(rune_of_power)
}

AddFunction ArcanePrecombatCdActions
{
	#jade_serpent_potion
	UsePotionIntellect()
	#mirror_image
	Spell(mirror_image)
}

### Arcane icons.

AddIcon mastery=arcane size=small checkboxon=opt_icons_left
{
	if TalentPoints(cold_snap_talent) and HealthPercent() < 30 Spell(cold_snap)
	Spell(blink)
}

AddIcon mastery=arcane help=moving size=small checkboxon=opt_icons_left
{
	ArcaneSingleTargetMovingActions()
}

AddIcon mastery=arcane help=mana
{
	if InCombat(no) ArcanePrecombatManaActions()
	ArcaneDefaultManaActions()
}

AddIcon mastery=arcane help=main
{
	if InCombat(no) ArcanePrecombatActions()
	ArcaneDefaultActions()
	ArcaneSingleTargetActions()
}

AddIcon mastery=arcane help=aoe checkboxon=opt_aoe
{
	if InCombat(no) ArcanePrecombatActions()
	ArcaneDefaultActions()
	ArcaneAoeActions()
}

AddIcon mastery=arcane help=cd
{
	ArcaneDefaultCdActions()
}

AddIcon mastery=arcane size=small checkboxon=opt_icons_right
{
	if BuffExpires(burst_haste any=1) and DebuffExpires(burst_haste_debuff) Spell(time_warp)
}

AddIcon mastery=arcane size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

###
### Fire
###
# Based on SimulationCraft profile "Mage_Fire_T16H".
#	class=mage
#	spec=fire
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#eZ!0...11
#	glyphs=combustion/counterspell

AddFunction FireDefaultActions
{
	#cancel_buff,name=alter_time,moving=1
	#conjure_mana_gem,if=mana_gem_charges<3&target.debuff.invulnerable.react
	if ItemCharges(mana_gem) < 3 and target.InCombat(no) ConjureManaGem()
	#presence_of_mind,sync=alter_time_activate,if=buff.alter_time.down
	if TalentPoints(presence_of_mind_talent) and Spell(alter_time_activate) and BuffExpires(alter_time_buff) Spell(presence_of_mind)
	#presence_of_mind,if=cooldown.alter_time_activate.remains>60|target.time_to_die<5
	if TalentPoints(presence_of_mind_talent) and { SpellCooldown(alter_time_activate) > 60 or target.TimeToDie() < 5 } Spell(presence_of_mind)
	#pyroblast,if=buff.pyroblast.react|buff.presence_of_mind.up
	if BuffPresent(pyroblast_buff) or BuffPresent(presence_of_mind_buff) Spell(pyroblast)
	#inferno_blast,if=buff.heating_up.react&buff.pyroblast.down
	if BuffPresent(heating_up_buff) and BuffExpires(pyroblast_buff) Spell(inferno_blast)
	#nether_tempest,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>6
	if TalentPoints(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemains(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 Spell(nether_tempest)
	#living_bomb,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>tick_time*3
	if TalentPoints(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemains(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#frost_bomb,if=!ticking&target.time_to_die>tick_time*3
	if TalentPoints(frost_bomb_talent) and not target.DebuffPresent(frost_bomb_debuff) and target.TimeToDie() > target.TickTime(frost_bomb_debuff) * 3 Spell(frost_bomb)
	#scorch,moving=1
	if Speed() > 0 Spell(scorch)
	#fireball
	Spell(fireball)
}

AddFunction FireDefaultAoeActions
{
	#cancel_buff,name=alter_time,moving=1
	#conjure_mana_gem,if=mana_gem_charges<3&target.debuff.invulnerable.react
	if ItemCharges(mana_gem) < 3 and target.InCombat(no) ConjureManaGem()
	#presence_of_mind,sync=alter_time_activate,if=buff.alter_time.down
	if TalentPoints(presence_of_mind_talent) and Spell(alter_time_activate) and BuffExpires(alter_time_buff) Spell(presence_of_mind)
	#presence_of_mind,if=cooldown.alter_time_activate.remains>60|target.time_to_die<5
	if TalentPoints(presence_of_mind_talent) and { SpellCooldown(alter_time_activate) > 60 or target.TimeToDie() < 5 } Spell(presence_of_mind)
	#flamestrike,if=active_enemies>=5
	if Enemies() >= 5 Spell(flamestrike)
	#inferno_blast,if=dot.combustion.ticking&active_enemies>1
	if target.DebuffPresent(combustion_debuff) Spell(inferno_blast)
	#pyroblast,if=buff.pyroblast.react|buff.presence_of_mind.up
	if BuffPresent(pyroblast_buff) or BuffPresent(presence_of_mind_buff) Spell(pyroblast)
	#inferno_blast,if=buff.heating_up.react&buff.pyroblast.down
	if BuffPresent(heating_up_buff) and BuffExpires(pyroblast_buff) Spell(inferno_blast)
	#nether_tempest,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>6
	if TalentPoints(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemains(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 Spell(nether_tempest)
	#living_bomb,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>tick_time*3
	if TalentPoints(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemains(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#frost_bomb,if=!ticking&target.time_to_die>tick_time*3
	if TalentPoints(frost_bomb_talent) and not target.DebuffPresent(frost_bomb_debuff) and target.TimeToDie() > target.TickTime(frost_bomb_debuff) * 3 Spell(frost_bomb)
}

AddFunction FireDefaultShortCdActions
{
	#rune_of_power,if=buff.rune_of_power.remains<cast_time&buff.alter_time.down
	if TalentPoints(rune_of_power_talent) and RuneOfPowerRemains() < CastTime(rune_of_power) and BuffExpires(alter_time_buff) Spell(rune_of_power)
	#rune_of_power,if=cooldown.alter_time_activate.remains=0&buff.rune_of_power.remains<6
	if TalentPoints(rune_of_power_talent) and Spell(alter_time_activate) and RuneOfPowerRemains() < 6 Spell(rune_of_power)
	#evocation,if=buff.rune_of_power.remains<cast_time&buff.alter_time.down
	if TalentPoints(invocation_talent) and BuffRemains(invokers_energy_buff) < CastTime(rune_of_power) and BuffExpires(alter_time_buff) Spell(evocation)
	#evocation,if=cooldown.alter_time_activate.remains=0&buff.rune_of_power.remains<6
	if TalentPoints(invocation_talent) and Spell(alter_time_activate) and BuffRemains(invokers_energy_buff) < 6 Spell(evocation)
	#evocation,if=buff.alter_time.down&mana.pct<20,interrupt_if=mana.pct>95
	if not TalentPoints(rune_of_power_talent) and not TalentPoints(invocation_talent) and BuffExpires(alter_time_buff) and ManaPercent() < 20 Spell(evocation)
	#combustion,if=target.time_to_die<22
	if target.TimeToDie() < 22 Spell(combustion)
	#combustion,if=dot.ignite.tick_dmg>=((3*action.pyroblast.crit_damage)*mastery_value*0.5)
	if target.DebuffPresent(ignite_debuff) and target.TickValue(ignite_debuff) >= { { 3 * target.CritDamage(pyroblast) } * MasteryEffect() / 100 * 0.5 } Spell(combustion)
	#combustion,if=dot.ignite.tick_dmg>=((action.fireball.crit_damage+action.inferno_blast.crit_damage+action.pyroblast.hit_damage)*mastery_value*0.5)&dot.pyroblast.ticking&buff.alter_time.down&buff.pyroblast.down&buff.presence_of_mind.down
	if target.DebuffPresent(ignite_debuff) and target.TickValue(ignite_debuff) >= { { target.CritDamage(fireball) + target.CritDamage(inferno_blast) + target.Damage(pyroblast) } * MasteryEffect() / 100 * 0.5 } and target.DebuffPresent(pyroblast_debuff) and BuffExpires(alter_time_buff) and BuffExpires(pyroblast_buff) and BuffExpires(presence_of_mind_buff) Spell(combustion)
}

AddFunction FireDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() Spell(counterspell)
	UseRacialInterruptActions()

	unless { TalentPoints(rune_of_power_talent) and RuneOfPowerRemains() < CastTime(rune_of_power) and BuffExpires(alter_time_buff) }
		or { TalentPoints(rune_of_power_talent) and Spell(alter_time_activate) and RuneOfPowerRemains() < 6 }
		or { TalentPoints(invocation_talent) and BuffRemains(invokers_energy_buff) < CastTime(rune_of_power) and BuffExpires(alter_time_buff) }
		or { TalentPoints(invocation_talent) and Spell(alter_time_activate) and BuffRemains(invokers_energy_buff) < 6 }
		or { not TalentPoints(rune_of_power_talent) and not TalentPoints(invocation_talent) and BuffExpires(alter_time_buff) and ManaPercent() < 20 and Spell(evocation) }
	{
		#berserking,if=buff.alter_time.down&target.time_to_die<18
		if BuffExpires(alter_time_buff) and target.TimeToDie() < 18 Spell(berserking)
		#jade_serpent_potion,if=buff.alter_time.down&target.time_to_die<45
		if BuffExpires(alter_time_buff) and target.TimeToDie() < 45 UsePotionIntellect()
		#mirror_image
		Spell(mirror_image)

		unless { target.TimeToDie() < 22 and Spell(combustion) }
			or { target.LastEstimatedDamage(ignite_debuff) >= { { 3 * target.CritDamage(pyroblast) } * MasteryEffect() * 0.5 } and Spell(combustion) }
			or { target.LastEstimatedDamage(ignite_debuff) >= { { target.CritDamage(fireball) + target.CritDamage(inferno_blast) + target.Damage(pyroblast) } * MasteryEffect() * 0.5 } and target.DebuffPresent(pyroblast_debuff) and BuffExpires(alter_time_buff) and BuffExpires(pyroblast_buff) and BuffExpires(presence_of_mind_buff) and Spell(combustion) }
		{
			#blood_fury,if=buff.alter_time.down&(cooldown.alter_time_activate.remains>30|target.time_to_die<18)
			if BuffExpires(alter_time_buff) and { SpellCooldown(alter_time_activate) > 30 or target.TimeToDie() < 18 } Spell(blood_fury)
			#berserking,sync=alter_time_activate,if=buff.alter_time.down
			if Spell(alter_time_activate) and BuffExpires(alter_time_buff) Spell(berserking)
			#jade_serpent_potion,sync=alter_time_activate,if=buff.alter_time.down
			if Spell(alter_time_activate) and BuffExpires(alter_time_buff) UsePotionIntellect()
			#use_item,slot=hands,sync=alter_time_activate
			if Spell(alter_time_activate) UseItemActions()
			#alter_time,if=time_to_bloodlust>180&buff.alter_time.down&buff.pyroblast.react
			if TimeToBloodlust() > 180 and BuffExpires(alter_time_buff) and BuffPresent(pyroblast_buff) Spell(alter_time)
			#use_item,slot=hands,if=cooldown.alter_time_activate.remains>40|target.time_to_die<12
			if SpellCooldown(alter_time_activate) > 40 or target.TimeToDie() < 12 UseItemActions()
		}
	}
}

AddFunction FirePrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#arcane_brilliance
	if BuffExpires(critical_strike any=1) or BuffExpires(spell_power_multiplier any=1) Spell(arcane_brilliance)
	#molten_armor
	if BuffExpires(molten_armor_buff) Spell(molten_armor)
	#snapshot_stats
}

AddFunction FirePrecombatShortCdActions
{
	#evocation
	if TalentPoints(invocation_talent) Spell(evocation)
	#rune_of_power
	if TalentPoints(rune_of_power_talent) Spell(rune_of_power)
}

AddFunction FirePrecombatCdActions
{
	#jade_serpent_potion
	UsePotionIntellect()
	#mirror_image
	Spell(mirror_image)
}

### Fire icons.

AddIcon mastery=fire size=small checkboxon=opt_icons_left
{
	if TalentPoints(cold_snap_talent) and HealthPercent() < 30 Spell(cold_snap)
	Spell(blink)
}

AddIcon mastery=fire size=small checkboxon=opt_icons_left
{
	Spell(combustion)
}

AddIcon mastery=fire help=shortcd
{
	if InCombat(no) FirePrecombatShortCdActions()
	FireDefaultShortCdActions()
}

AddIcon mastery=fire help=main
{
	if InCombat(no) FirePrecombatActions()
	FireDefaultActions()
}

AddIcon mastery=fire help=aoe checkboxon=opt_aoe
{
	if InCombat(no) FirePrecombatActions()
	FireDefaultAoeActions()
}

AddIcon mastery=fire help=cd
{
	FireDefaultCdActions()
}

AddIcon mastery=fire size=small checkboxon=opt_icons_right
{
	if BuffExpires(burst_haste any=1) and DebuffExpires(burst_haste_debuff) Spell(time_warp)
}

AddIcon mastery=fire size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

###
### Frost
###
# Based on SimulationCraft profile "Mage_Frost_T16H".
#	class=mage
#	spec=frost
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#eb!0...11
#	glyphs=evocation/icy_veins/splitting_ice

AddFunction FrostDefaultActions
{
	#cancel_buff,name=alter_time,moving=1
	#conjure_mana_gem,if=mana_gem_charges<3&target.debuff.invulnerable.react
	if ItemCharges(mana_gem) < 3 and target.InCombat(no) ConjureManaGem()
	#frostfire_bolt,if=buff.alter_time.up&buff.brain_freeze.up
	if BuffPresent(alter_time_buff) and BuffPresent(brain_freeze_buff) Spell(frostfire_bolt)
	#ice_lance,if=buff.alter_time.up&buff.fingers_of_frost.up
	if BuffPresent(alter_time_buff) and BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
	#nether_tempest,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>6
	if TalentPoints(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemains(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 Spell(nether_tempest)
	#living_bomb,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>tick_time*3
	if TalentPoints(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemains(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#frost_bomb,if=!ticking&target.time_to_die>tick_time*3
	if TalentPoints(frost_bomb_talent) and not target.DebuffPresent(frost_bomb_debuff) and target.TimeToDie() > target.TickTime(frost_bomb_debuff) * 3 Spell(frost_bomb)
	#frostfire_bolt,if=buff.brain_freeze.react&cooldown.icy_veins.remains>2
	if BuffPresent(brain_freeze_buff) and { IcyVeins() or IcyVeinsCooldownRemains() > 2 } Spell(frostfire_bolt)
	#ice_lance,if=buff.frozen_thoughts.react&buff.fingers_of_frost.up
	if ArmorSetBonus(T16_caster 2) == 1 and BuffPresent(frozen_thoughts_buff) and BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
	#ice_lance,if=buff.fingers_of_frost.up&(buff.fingers_of_frost.remains<2|(buff.fingers_of_frost.stack>1&cooldown.icy_veins.remains>2))
	if ArmorSetBonus(T16_caster 2) == 1 and BuffPresent(fingers_of_frost_buff) and { BuffRemains(fingers_of_frost_buff) < 2 or { BuffStacks(fingers_of_frost_buff) > 1 and { IcyVeins() or IcyVeinsCooldownRemains() > 2 } } } Spell(ice_lance)
	#ice_lance,if=buff.fingers_of_frost.react&cooldown.icy_veins.remains>2
	if ArmorSetBonus(T16_caster 2) == 0 and BuffPresent(fingers_of_frost_buff) and { IcyVeins() or IcyVeinsCooldownRemains() > 2 } Spell(ice_lance)
	#frostbolt
	Spell(frostbolt)
}

AddFunction FrostDefaultShortCdActions
{
	#rune_of_power,if=buff.rune_of_power.remains<cast_time&buff.alter_time.down
	if TalentPoints(rune_of_power_talent) and RuneOfPowerRemains() < CastTime(rune_of_power) and BuffExpires(alter_time_buff) Spell(rune_of_power)
	#rune_of_power,if=cooldown.icy_veins.remains=0&buff.rune_of_power.remains<20
	if TalentPoints(rune_of_power_talent) and IcyVeins() and RuneOfPowerRemains() < 20 Spell(rune_of_power)
	#evocation,if=buff.invokers_energy.remains<cast_time&buff.alter_time.down
	if TalentPoints(invocation_talent) and BuffRemains(invokers_energy_buff) < CastTime(rune_of_power) and BuffExpires(alter_time_buff) Spell(evocation)
	#evocation,if=cooldown.icy_veins.remains=0&buff.rune_of_power.remains<20
	if TalentPoints(invocation_talent) and IcyVeins() and BuffRemains(invokers_energy_buff) < 20 Spell(evocation)
	#evocation,if=mana.pct<50,interrupt_if=mana.pct>95
	if not TalentPoints(rune_of_power_talent) and not TalentPoints(invocation_talent) and ManaPercent() < 50 Spell(evocation)
	#frozen_orb
	Spell(frozen_orb)
}

AddFunction FrostDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() Spell(counterspell)
	UseRacialInterruptActions()

	unless { TalentPoints(rune_of_power_talent) and RuneOfPowerRemains() < CastTime(rune_of_power) and BuffExpires(alter_time_buff) }
		or { TalentPoints(rune_of_power_talent) and IcyVeins() and RuneOfPowerRemains() < 20 }
		or { TalentPoints(invocation_talent) and BuffRemains(invokers_energy_buff) < CastTime(rune_of_power) and BuffExpires(alter_time_buff) }
		or { TalentPoints(invocation_talent) and IcyVeins() and BuffRemains(invokers_energy_buff) < 20 }
		or { not TalentPoints(rune_of_power_talent) and not TalentPoints(invocation_talent) and ManaPercent() < 50 and Spell(evocation) }
	{
		#mirror_image
		Spell(mirror_image)
		#icy_veins,if=time_to_bloodlust>180&((buff.brain_freeze.react|buff.fingers_of_frost.react)|target.time_to_die<22),moving=0
		if TimeToBloodlust() > 180 and { { BuffPresent(brain_freeze_buff) or BuffPresent(fingers_of_frost_buff) } or target.TimeToDie() < 22 } IcyVeins()
		#blood_fury,if=buff.icy_veins.up|cooldown.icy_veins.remains>30|target.time_to_die<18
		if BuffPresent(icy_veins_buff) or IcyVeinsCooldownRemains() > 30 or target.TimeToDie() < 18 Spell(blood_fury)
		#berserking,if=buff.icy_veins.up|target.time_to_die<18
		if BuffPresent(icy_veins_buff) or target.TimeToDie() < 18 Spell(berserking)
		#jade_serpent_potion,if=buff.icy_veins.up|target.time_to_die<45
		if BuffPresent(icy_veins_buff) or target.TimeToDie() < 45 UsePotionIntellect()
		#presence_of_mind,if=buff.icy_veins.up|cooldown.icy_veins.remains>15|target.time_to_die<15
		if BuffPresent(icy_veins_buff) or IcyVeinsCooldownRemains() > 15 or target.TimeToDie() < 15 Spell(presence_of_mind)
		#use_item,slot=hands,sync=alter_time_activate,if=buff.alter_time.down
		if Spell(alter_time_activate) and BuffExpires(alter_time_buff) UseItemActions()
		#alter_time,if=buff.alter_time.down&buff.icy_veins.up
		if BuffExpires(alter_time_buff) and BuffPresent(icy_veins_buff) Spell(alter_time)
		#use_item,slot=hands,if=(cooldown.alter_time_activate.remains>45&buff.rune_of_power.remains>20)|target.time_to_die<25" )
		if TalentPoints(rune_of_power_talent) and { { SpellCooldown(alter_time_activate) > 45 and RuneOfPowerRemains() > 20 } or target.TimeToDie() < 25 } UseItemActions()
		#use_item,slot=hands,if=(cooldown.alter_time_activate.remains>45&buff.invokers_energy.remains>20)|target.time_to_die<25
		if TalentPoints(invocation_talent) and { { SpellCooldown(alter_time_activate) > 45 and BuffRemains(invokers_energy_buff) > 20 } or target.TimeToDie() < 25 } UseItemActions()
		#use_item,slot=hands,if=cooldown.alter_time_activate.remains>45|target.time_to_die<25
		if not TalentPoints(rune_of_power_talent) and not TalentPoints(invocation_talent) and { SpellCooldown(alter_time_activate) > 45 or target.TimeToDie() < 25 } UseItemActions()
	}
}

AddFunction FrostPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#arcane_brilliance
	if BuffExpires(critical_strike any=1) or BuffExpires(spell_power_multiplier any=1) Spell(arcane_brilliance)
	#frost_armor
	if BuffExpires(frost_armor_buff) Spell(frost_armor)
	#water_elemental
	if pet.Present(no) Spell(water_elemental)
	#snapshot_stats
}

AddFunction FrostPrecombatShortCdActions
{
	#evocation
	if TalentPoints(invocation_talent) Spell(evocation)
	#rune_of_power
	if TalentPoints(rune_of_power_talent) Spell(rune_of_power)
}

AddFunction FrostPrecombatCdActions
{
	#jade_serpent_potion
	UsePotionIntellect()
	#mirror_image
	Spell(mirror_image)
}

# Frost AoE rotation from Icy Veins Frost Mage Class Guide:
#	http://icy-veins.com/frost-mage-wow-pve-dps-rotation-cooldowns-abilities#sec-2
#
AddFunction FrostAoeActions
{
	# Cast Flamestrike on cooldown.
	#flamestrike,if=active_enemies>=5
	if Enemies() >= 5 Spell(flamestrike)

	# Cast glyphed Cone of Cold on cooldown.
	if Glyph(glyph_of_cone_of_cold) Spell(cone_of_cold)

	# Cast mage bomb on at least one target.
	#nether_tempest,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>6
	if TalentPoints(nether_tempest_talent) and { not target.DebuffPresent(nether_tempest_debuff) or target.DebuffRemains(nether_tempest_debuff) < target.TickTime(nether_tempest_debuff) } and target.TimeToDie() > 6 Spell(nether_tempest)
	#living_bomb,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>tick_time*3
	if TalentPoints(living_bomb_talent) and { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemains(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#frost_bomb,if=!ticking&target.time_to_die>tick_time*3
	if TalentPoints(frost_bomb_talent) and not target.DebuffPresent(frost_bomb_debuff) and target.TimeToDie() > target.TickTime(frost_bomb_debuff) * 3 Spell(frost_bomb)

	# Toss out Frozen Orb to generate Fingers of Frost to use with Ice Lance.
	# Ice Lance should be glyphed for maximum cleave damage.
	if BuffExpires(fingers_of_frost_buff) Spell(frozen_orb)
	if BuffPresent(fingers_of_frost_buff) Spell(ice_lance)

	# Blizzard as filler.
	Spell(blizzard)
}

### Frost icons.

AddIcon mastery=frost size=small checkboxon=opt_icons_left
{
	if TalentPoints(cold_snap_talent) and HealthPercent() < 30 Spell(cold_snap)
	Spell(blink)
}

AddIcon mastery=frost size=small checkboxon=opt_icons_left
{
	if pet.Present() Spell(water_elemental_freeze)
}

AddIcon mastery=frost help=shortcd
{
	if InCombat(no) FrostPrecombatShortCdActions()
	FrostDefaultShortCdActions()
}

AddIcon mastery=frost help=main
{
	if InCombat(no) FrostPrecombatActions()
	FrostDefaultActions()
}

AddIcon mastery=frost help=aoe checkboxon=opt_aoe
{
	if InCombat(no) FrostPrecombatActions()
	FrostAoeActions()
}

AddIcon mastery=frost help=cd
{
	FrostDefaultCdActions()
}

AddIcon mastery=frost size=small checkboxon=opt_icons_right
{
	if BuffExpires(burst_haste any=1) and DebuffExpires(burst_haste_debuff) Spell(time_warp)
}

AddIcon mastery=frost size=small checkboxon=opt_icons_right
{
	UseItemActions()
}
]]

	OvaleScripts:RegisterScript("MAGE", name, desc, code)
end
