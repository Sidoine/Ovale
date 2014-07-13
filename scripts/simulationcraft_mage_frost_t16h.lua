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
Include(ovale_mage_common)

AddFunction FrostDefaultActions
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
	#rune_of_power,if=cooldown.icy_veins.remains=0&buff.rune_of_power.remains<20
	if not IcyVeinsCooldownRemains() > 0 and RuneOfPowerRemains() < 20 Spell(rune_of_power)
	#mirror_image
	Spell(mirror_image)
	#frozen_orb
	Spell(frozen_orb)
	#icy_veins,if=time_to_bloodlust>180&((buff.brain_freeze.react|buff.fingers_of_frost.react)|target.time_to_die<22),moving=0
	if TimeToBloodlust() > 180 and { { BuffPresent(brain_freeze_buff) or BuffPresent(fingers_of_frost_buff) } or target.TimeToDie() < 22 } IcyVeins()
	#berserking,if=buff.icy_veins.up|target.time_to_die<18
	if BuffPresent(icy_veins_buff) or target.TimeToDie() < 18 Spell(berserking)
	#jade_serpent_potion,if=buff.icy_veins.up|target.time_to_die<45
	if BuffPresent(icy_veins_buff) or target.TimeToDie() < 45 UsePotionIntellect()
	#presence_of_mind,if=buff.icy_veins.up|cooldown.icy_veins.remains>15|target.time_to_die<15
	if BuffPresent(icy_veins_buff) or IcyVeinsCooldownRemains() > 15 or target.TimeToDie() < 15 Spell(presence_of_mind)
	#use_item,slot=hands,sync=alter_time_activate,if=buff.alter_time.down
	if not SpellCooldown(alter_time_activate) > 0 and BuffExpires(alter_time_buff) UseItemActions()
	#alter_time,if=buff.alter_time.down&buff.icy_veins.up
	if BuffExpires(alter_time_buff) and BuffPresent(icy_veins_buff) Spell(alter_time)
	#use_item,slot=hands,if=(cooldown.alter_time_activate.remains>45&buff.rune_of_power.remains>20)|target.time_to_die<25
	if { SpellCooldown(alter_time_activate) > 45 and RuneOfPowerRemains() > 20 } or target.TimeToDie() < 25 UseItemActions()
	#flamestrike,if=active_enemies>=5
	if Enemies() >= 5 Spell(flamestrike)
	#frostfire_bolt,if=buff.alter_time.up&buff.brain_freeze.up
	if BuffPresent(alter_time_buff) and BuffPresent(brain_freeze_buff) Spell(frostfire_bolt)
	#ice_lance,if=buff.alter_time.up&buff.fingers_of_frost.up
	if BuffPresent(alter_time_buff) and BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
	#living_bomb,cycle_targets=1,if=(!ticking|remains<tick_time)&target.time_to_die>tick_time*3
	if { not target.DebuffPresent(living_bomb_debuff) or target.DebuffRemains(living_bomb_debuff) < target.TickTime(living_bomb_debuff) } and target.TimeToDie() > target.TickTime(living_bomb_debuff) * 3 Spell(living_bomb)
	#frostfire_bolt,if=buff.brain_freeze.react&cooldown.icy_veins.remains>2
	if BuffPresent(brain_freeze_buff) and IcyVeinsCooldownRemains() > 2 Spell(frostfire_bolt)
	#ice_lance,if=buff.frozen_thoughts.react&buff.fingers_of_frost.up
	if BuffPresent(frozen_thoughts_buff) and BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
	#ice_lance,if=buff.fingers_of_frost.up&(buff.fingers_of_frost.remains<2|(buff.fingers_of_frost.stack>1&cooldown.icy_veins.remains>2))
	if BuffPresent(fingers_of_frost_buff) and { BuffRemains(fingers_of_frost_buff) < 2 or { BuffStacks(fingers_of_frost_buff) > 1 and IcyVeinsCooldownRemains() > 2 } } Spell(ice_lance)
	#frostbolt
	Spell(frostbolt)
	#fire_blast,moving=1
	if Speed() > 0 Spell(fire_blast)
	#ice_lance,moving=1
	if Speed() > 0 Spell(ice_lance)
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
	#rune_of_power
	Spell(rune_of_power)
	#jade_serpent_potion
	UsePotionIntellect()
	#mirror_image
	Spell(mirror_image)
}

AddIcon mastery=frost help=main
{
	if InCombat(no) FrostPrecombatActions()
	FrostDefaultActions()
}

### Required symbols
# alter_time
# alter_time_activate
# alter_time_buff
# arcane_brilliance
# berserking
# brain_freeze_buff
# conjure_mana_gem
# counterspell
# fingers_of_frost_buff
# fire_blast
# flamestrike
# frost_armor
# frost_armor_buff
# frostbolt
# frostfire_bolt
# frozen_orb
# frozen_thoughts_buff
# ice_lance
# icy_veins
# icy_veins_buff
# jade_serpent_potion
# living_bomb
# living_bomb_debuff
# mana_gem
# mirror_image
# presence_of_mind
# rune_of_power
# time_warp
# water_elemental
]]
	OvaleScripts:RegisterScript("MAGE", name, desc, code, "reference")
end
