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
#	glyphs=mana_gem/mirror_image/arcane_power

Include(ovale_items)
Include(ovale_racials)
Include(ovale_mage_spells)

AddFunction ArcaneAoeActions
{
	#flamestrike
	Spell(flamestrike)
	#living_bomb,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>tick_time*3
	if { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemains(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
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
	if BuffPresent(alter_time_buff) Spell(arcane_missiles)
	#arcane_blast,if=buff.alter_time.up
	if BuffPresent(alter_time_buff) Spell(arcane_blast)
	#arcane_blast,if=buff.profound_magic.up&buff.arcane_charge.stack>3&mana.pct>93
	if BuffPresent(profound_magic_buff) and DebuffStacks(arcane_charge_debuff) > 3 and ManaPercent() > 93 Spell(arcane_blast)
	#arcane_missiles,if=(buff.arcane_missiles.stack=2&cooldown.arcane_power.remains>0)|(buff.arcane_charge.stack>=4&cooldown.arcane_power.remains>8)
	if { BuffStacks(arcane_missiles_buff) == 2 and SpellCooldown(arcane_power) > 0 } or { DebuffStacks(arcane_charge_debuff) >= 4 and SpellCooldown(arcane_power) > 8 } Spell(arcane_missiles)
	#living_bomb,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>tick_time*3
	if { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemains(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#arcane_barrage,if=buff.arcane_charge.stack>=4&mana.pct<95
	if DebuffStacks(arcane_charge_debuff) >= 4 and ManaPercent() < 95 Spell(arcane_barrage)
	#presence_of_mind
	Spell(presence_of_mind)
	#arcane_blast
	Spell(arcane_blast)
	#arcane_barrage,moving=1
	if Speed() > 0 Spell(arcane_barrage)
	#fire_blast,moving=1
	if Speed() > 0 Spell(fire_blast)
	#ice_lance,moving=1
	if Speed() > 0 Spell(ice_lance)
}

AddFunction ArcaneDefaultActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() Spell(counterspell)
	#cancel_buff,name=alter_time,moving=1
	#conjure_mana_gem,if=mana_gem_charges<3&target.debuff.invulnerable.react
	if ItemCharges(mana_gem) < 3 and target.InCombat(no) ConjureManaGem()
	#time_warp,if=target.health.pct<25|time>5
	if target.HealthPercent() < 25 or TimeInCombat() > 5 Spell(time_warp)
	#rune_of_power,if=buff.rune_of_power.remains<cast_time
	if RuneOfPowerRemains() < CastTime(rune_of_power) Spell(rune_of_power)
	#rune_of_power,if=cooldown.arcane_power.remains=0&buff.rune_of_power.remains<buff.arcane_power.duration
	if not SpellCooldown(arcane_power) > 0 and RuneOfPowerRemains() < SpellData(arcane_power_buff duration) Spell(rune_of_power)
	#mirror_image
	Spell(mirror_image)
	#mana_gem,if=mana.pct<80&buff.alter_time.down
	if ManaPercent() < 80 and BuffExpires(alter_time_buff) UseManaGem()
	#arcane_power,if=time_to_bloodlust>180&((buff.rune_of_power.remains>=buff.arcane_power.duration&buff.arcane_missiles.stack=2&buff.arcane_charge.stack>2)|target.time_to_die<buff.arcane_power.duration+5),moving=0
	if TimeToBloodlust() > 180 and { { RuneOfPowerRemains() >= SpellData(arcane_power_buff duration) and BuffStacks(arcane_missiles_buff) == 2 and DebuffStacks(arcane_charge_debuff) > 2 } or target.TimeToDie() < SpellData(arcane_power_buff duration) + 5 } Spell(arcane_power)
	#berserking,if=buff.alter_time.down&(buff.arcane_power.up|target.time_to_die<18)
	if BuffExpires(alter_time_buff) and { BuffPresent(arcane_power_buff) or target.TimeToDie() < 18 } Spell(berserking)
	#jade_serpent_potion,if=buff.alter_time.down&(buff.arcane_power.up|target.time_to_die<50)
	if BuffExpires(alter_time_buff) and { BuffPresent(arcane_power_buff) or target.TimeToDie() < 50 } UsePotionIntellect()
	#use_item,slot=hands,sync=alter_time_activate,if=buff.alter_time.down
	if not SpellCooldown(alter_time_activate) > 0 and BuffExpires(alter_time_buff) UseItemActions()
	#alter_time,if=buff.alter_time.down&buff.arcane_power.up
	if BuffExpires(alter_time_buff) and BuffPresent(arcane_power_buff) Spell(alter_time)
	#use_item,slot=hands,if=(cooldown.alter_time_activate.remains>45|target.time_to_die<25)&buff.rune_of_power.remains>20
	if { SpellCooldown(alter_time_activate) > 45 or target.TimeToDie() < 25 } and RuneOfPowerRemains() > 20 UseItemActions()
	#run_action_list,name=aoe,if=active_enemies>=6
	if Enemies() >= 6 ArcaneAoeActions()
	#run_action_list,name=single_target,if=active_enemies<6
	if Enemies() < 6 ArcaneSingleTargetActions()
}

AddFunction ArcanePrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#arcane_brilliance
	if BuffExpires(critical_strike any=1) or BuffExpires(spell_power_multiplier any=1) Spell(arcane_brilliance)
	#frost_armor
	if BuffExpires(frost_armor_buff) Spell(frost_armor)
	#snapshot_stats
	#rune_of_power
	Spell(rune_of_power)
	#jade_serpent_potion
	UsePotionIntellect()
	#mirror_image
	Spell(mirror_image)
}

AddIcon mastery=arcane help=main
{
	if InCombat(no) ArcanePrecombatActions()
	ArcaneDefaultActions()
}

### Required symbols
# alter_time
# alter_time_activate
# alter_time_buff
# arcane_barrage
# arcane_blast
# arcane_brilliance
# arcane_charge_debuff
# arcane_explosion
# arcane_missiles
# arcane_missiles_buff
# arcane_power
# arcane_power_buff
# berserking
# conjure_mana_gem
# counterspell
# fire_blast
# flamestrike
# frost_armor
# frost_armor_buff
# ice_lance
# jade_serpent_potion
# living_bomb
# living_bomb_debuff
# mana_gem
# mirror_image
# presence_of_mind
# profound_magic_buff
# rune_of_power
# time_warp
]]
	OvaleScripts:RegisterScript("MAGE", name, desc, code, "reference")
end