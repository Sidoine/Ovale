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
Include(ovale_mage_common)

AddFunction FireDefaultActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() Spell(counterspell)
	#cancel_buff,name=alter_time,moving=1
	#conjure_mana_gem,if=mana_gem_charges<3&target.debuff.invulnerable.react
	if ItemCharges(mana_gem) < 3 and target.InCombat(no) ConjureManaGem()
	#time_warp,if=target.health.pct<25|time>5
	if target.HealthPercent() < 25 or TimeInCombat() > 5 Spell(time_warp)
	#rune_of_power,if=buff.rune_of_power.remains<cast_time&buff.alter_time.down
	if RuneOfPowerRemains() < CastTime(rune_of_power) and BuffExpires(alter_time_buff) Spell(rune_of_power)
	#rune_of_power,if=cooldown.alter_time_activate.remains=0&buff.rune_of_power.remains<6
	if not SpellCooldown(alter_time_activate) > 0 and RuneOfPowerRemains() < 6 Spell(rune_of_power)
	#berserking,if=buff.alter_time.down&target.time_to_die<18
	if BuffExpires(alter_time_buff) and target.TimeToDie() < 18 Spell(berserking)
	#jade_serpent_potion,if=buff.alter_time.down&target.time_to_die<45
	if BuffExpires(alter_time_buff) and target.TimeToDie() < 45 UsePotionIntellect()
	#mirror_image
	Spell(mirror_image)
	#combustion,if=target.time_to_die<22
	if target.TimeToDie() < 22 Spell(combustion)
	#combustion,if=dot.ignite.tick_dmg>=((3*action.pyroblast.crit_damage)*mastery_value*0.5)
	if target.LastEstimatedDamage(ignite_debuff) >= { { 3 * target.CritDamage(pyroblast) } * MasteryEffect() / 100 * 0.5 } Spell(combustion)
	#combustion,if=dot.ignite.tick_dmg>=((action.fireball.crit_damage+action.inferno_blast.crit_damage+action.pyroblast.hit_damage)*mastery_value*0.5)&dot.pyroblast.ticking&buff.alter_time.down&buff.pyroblast.down&buff.presence_of_mind.down
	if target.LastEstimatedDamage(ignite_debuff) >= { { target.CritDamage(fireball) + target.CritDamage(inferno_blast) + target.Damage(pyroblast) } * MasteryEffect() / 100 * 0.5 } and target.DebuffPresent(pyroblast_debuff) and BuffExpires(alter_time_buff) and BuffExpires(pyroblast_buff) and BuffExpires(presence_of_mind_buff) Spell(combustion)
	#berserking,sync=alter_time_activate,if=buff.alter_time.down
	if not SpellCooldown(alter_time_activate) > 0 and BuffExpires(alter_time_buff) Spell(berserking)
	#presence_of_mind,sync=alter_time_activate,if=buff.alter_time.down
	if not SpellCooldown(alter_time_activate) > 0 and BuffExpires(alter_time_buff) Spell(presence_of_mind)
	#jade_serpent_potion,sync=alter_time_activate,if=buff.alter_time.down
	if not SpellCooldown(alter_time_activate) > 0 and BuffExpires(alter_time_buff) UsePotionIntellect()
	#use_item,slot=hands,sync=alter_time_activate
	if not SpellCooldown(alter_time_activate) > 0 UseItemActions()
	#alter_time,if=time_to_bloodlust>180&buff.alter_time.down&buff.pyroblast.react
	if TimeToBloodlust() > 180 and BuffExpires(alter_time_buff) and BuffPresent(pyroblast_buff) Spell(alter_time)
	#use_item,slot=hands,if=cooldown.alter_time_activate.remains>40|target.time_to_die<12
	if SpellCooldown(alter_time_activate) > 40 or target.TimeToDie() < 12 UseItemActions()
	#presence_of_mind,if=cooldown.alter_time_activate.remains>60|target.time_to_die<5
	if SpellCooldown(alter_time_activate) > 60 or target.TimeToDie() < 5 Spell(presence_of_mind)
	#flamestrike,if=active_enemies>=5
	if Enemies() >= 5 Spell(flamestrike)
	#inferno_blast,if=dot.combustion.ticking&active_enemies>1
	if target.DebuffPresent(combustion_debuff) and Enemies() > 1 Spell(inferno_blast)
	#pyroblast,if=buff.pyroblast.react|buff.presence_of_mind.up
	if BuffPresent(pyroblast_buff) or BuffPresent(presence_of_mind_buff) Spell(pyroblast)
	#inferno_blast,if=buff.heating_up.react&buff.pyroblast.down
	if BuffPresent(heating_up_buff) and BuffExpires(pyroblast_buff) Spell(inferno_blast)
	#living_bomb,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>tick_time*3
	if { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemains(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#fireball
	Spell(fireball)
	#scorch,moving=1
	if Speed() > 0 Spell(scorch)
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
	#rune_of_power
	Spell(rune_of_power)
	#jade_serpent_potion
	UsePotionIntellect()
	#mirror_image
	Spell(mirror_image)
}

AddIcon mastery=fire help=main
{
	if InCombat(no) FirePrecombatActions()
	FireDefaultActions()
}

### Required symbols
# alter_time
# alter_time_activate
# alter_time_buff
# arcane_brilliance
# berserking
# combustion
# combustion_debuff
# conjure_mana_gem
# counterspell
# fireball
# flamestrike
# heating_up_buff
# ignite_debuff
# inferno_blast
# jade_serpent_potion
# living_bomb
# living_bomb_debuff
# mana_gem
# mirror_image
# molten_armor
# molten_armor_buff
# presence_of_mind
# presence_of_mind_buff
# pyroblast
# pyroblast_buff
# pyroblast_debuff
# rune_of_power
# scorch
# time_warp
]]
	OvaleScripts:RegisterScript("MAGE", name, desc, code, "reference")
end
