local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Warlock_Affliction_T16H"
	local desc = "[5.4] SimulationCraft: Warlock_Affliction_T16H"
	local code = [[
# Based on SimulationCraft profile "Warlock_Affliction_T16H".
#	class=warlock
#	spec=affliction
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Va!....00
#	glyphs=siphon_life
#	pet=felhunter

Include(ovale_common)
Include(ovale_warlock_spells)

AddCheckBox(opt_potion_intellect ItemName(jade_serpent_potion) default)

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

AddFunction AfflictionPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier_buff any=1) Spell(dark_intent)
	#summon_pet,if=!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down
	if { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and pet.Present(no) Spell(summon_felhunter)
	#snapshot_stats
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
	if Talent(grimoire_of_sacrifice_talent) and pet.Present() Spell(grimoire_of_sacrifice)
	#service_pet,if=talent.grimoire_of_service.enabled
	if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)
	#jade_serpent_potion
	UsePotionIntellect()
}

AddFunction AfflictionDefaultActions
{
	#curse_of_the_elements,if=debuff.magic_vulnerability.down
	if target.DebuffExpires(magic_vulnerability_debuff any=1) Spell(curse_of_the_elements)
	#use_item,name=gloves_of_the_horned_nightmare
	UseItemActions()
	#jade_serpent_potion,if=buff.bloodlust.react|target.health.pct<=20
	if BuffPresent(burst_haste_buff any=1) or target.HealthPercent() <= 20 UsePotionIntellect()
	#berserking
	Spell(berserking)
	#dark_soul,if=!talent.archimondes_darkness.enabled|(talent.archimondes_darkness.enabled&(charges=2|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react|target.health.pct<=10))
	if not Talent(archimondes_darkness_talent) or Talent(archimondes_darkness_talent) and { Charges(dark_soul_misery) == 2 or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_stacking_proc_intellect_buff) or target.HealthPercent() <= 10 } Spell(dark_soul_misery)
	#service_pet,if=talent.grimoire_of_service.enabled
	if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)
	#run_action_list,name=aoe,if=active_enemies>6
	if Enemies() > 6 AfflictionAoeActions()
	#summon_doomguard
	Spell(summon_doomguard)
	#soul_swap,if=buff.soulburn.up
	if BuffPresent(soulburn_buff) Spell(soul_swap)
	#soulburn,if=(buff.dark_soul.up|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react>6)&(dot.agony.ticks_remain<=action.agony.add_ticks%2|dot.corruption.ticks_remain<=action.corruption.add_ticks%2|dot.unstable_affliction.ticks_remain<=action.unstable_affliction.add_ticks%2)&shard_react
	if { BuffPresent(dark_soul_misery_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffStacks(trinket_stacking_proc_intellect_buff) > 6 } and { target.TicksRemaining(agony_debuff) <= TicksAdded(agony_debuff) / 2 or target.TicksRemaining(corruption_debuff) <= TicksAdded(corruption_debuff) / 2 or target.TicksRemaining(unstable_affliction_debuff) <= TicksAdded(unstable_affliction_debuff) / 2 } and SoulShards() >= 1 Spell(soulburn)
	#soulburn,if=(dot.unstable_affliction.ticks_remain<=1|dot.corruption.ticks_remain<=1|dot.agony.ticks_remain<=1)&shard_react&target.health.pct<=20
	if { target.TicksRemaining(unstable_affliction_debuff) < 2 or target.TicksRemaining(corruption_debuff) < 2 or target.TicksRemaining(agony_debuff) < 2 } and SoulShards() >= 1 and target.HealthPercent() <= 20 Spell(soulburn)
	#soul_swap,if=active_enemies>1&buff.soul_swap.down&(buff.dark_soul.up|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react>6)
	if Enemies() > 1 and BuffExpires(soul_swap_buff) and { BuffPresent(dark_soul_misery_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffStacks(trinket_stacking_proc_intellect_buff) > 6 } Spell(soul_swap)
	#soul_swap,cycle_targets=1,if=active_enemies>1&buff.soul_swap.up&(dot.agony.ticks_remain<=action.agony.add_ticks%2|dot.corruption.ticks_remain<=action.corruption.add_ticks%2|dot.unstable_affliction.ticks_remain<=action.unstable_affliction.add_ticks%2)&shard_react
	if Enemies() > 1 and BuffPresent(soul_swap_buff) and { target.TicksRemaining(agony_debuff) <= TicksAdded(agony_debuff) / 2 or target.TicksRemaining(corruption_debuff) <= TicksAdded(corruption_debuff) / 2 or target.TicksRemaining(unstable_affliction_debuff) <= TicksAdded(unstable_affliction_debuff) / 2 } and SoulShards() >= 1 Spell(soul_swap)
	#haunt,if=!in_flight_to_target&remains<cast_time+travel_time+tick_time&shard_react&target.health.pct<=20
	if not InFlightToTarget(haunt) and target.DebuffRemaining(haunt_debuff) < CastTime(haunt) + 0.5 + target.TickTime(haunt_debuff) and SoulShards() >= 1 and target.HealthPercent() <= 20 Spell(haunt)
	#drain_soul,interrupt=1,chain=1,if=target.health.pct<=20
	if target.HealthPercent() <= 20 Spell(drain_soul)
	#haunt,if=!in_flight_to_target&remains<cast_time+travel_time+tick_time&shard_react
	if not InFlightToTarget(haunt) and target.DebuffRemaining(haunt_debuff) < CastTime(haunt) + 0.5 + target.TickTime(haunt_debuff) and SoulShards() >= 1 Spell(haunt)
	#agony,if=(tick_damage*n_ticks*(100+crit_pct_current)>4*dot.agony.tick_dmg*dot.agony.ticks_remain*(100+dot.agony.crit_pct))&miss_react
	if target.Damage(agony_debuff) * target.Ticks(agony_debuff) * { 100 + SpellCritChance() } > 4 * target.LastEstimatedDamage(agony_debuff) * target.TicksRemaining(agony_debuff) * { 100 + target.DebuffSpellCritChance(agony_debuff) } and True(miss_react) Spell(agony)
	#corruption,if=((stat.spell_power>spell_power&ticks_remain<add_ticks%2)|(stat.spell_power>spell_power*1.5)|remains<gcd)&miss_react
	if { Spellpower() > target.DebuffSpellpower(corruption_debuff) and target.TicksRemaining(corruption_debuff) < TicksAdded(corruption_debuff) / 2 or Spellpower() > target.DebuffSpellpower(corruption_debuff) * 1.5 or target.DebuffRemaining(corruption_debuff) < GCD() } and True(miss_react) Spell(corruption)
	#unstable_affliction,if=((stat.spell_power>spell_power&ticks_remain<add_ticks%2)|(stat.spell_power>spell_power*1.5)|remains<cast_time+gcd)&miss_react
	if { Spellpower() > target.DebuffSpellpower(unstable_affliction_debuff) and target.TicksRemaining(unstable_affliction_debuff) < TicksAdded(unstable_affliction_debuff) / 2 or Spellpower() > target.DebuffSpellpower(unstable_affliction_debuff) * 1.5 or target.DebuffRemaining(unstable_affliction_debuff) < CastTime(unstable_affliction) + GCD() } and True(miss_react) Spell(unstable_affliction)
	#life_tap,if=buff.dark_soul.down&buff.bloodlust.down&mana.pct<50
	if BuffExpires(dark_soul_misery_buff) and BuffExpires(burst_haste_buff any=1) and ManaPercent() < 50 Spell(life_tap)
	#malefic_grasp,chain=1,interrupt_if=target.health.pct<=20
	Spell(malefic_grasp)
	#life_tap,moving=1,if=mana.pct<80&mana.pct<target.health.pct
	if Speed() > 0 and ManaPercent() < 80 and ManaPercent() < target.HealthPercent() Spell(life_tap)
	#fel_flame,moving=1
	if Speed() > 0 Spell(fel_flame)
	#life_tap
	Spell(life_tap)
}

AddFunction AfflictionAoeActions
{
	#summon_infernal
	Spell(summon_infernal)
	#soulburn,cycle_targets=1,if=buff.soulburn.down&!dot.soulburn_seed_of_corruption.ticking&!action.soulburn_seed_of_corruption.in_flight_to_target&shard_react
	if BuffExpires(soulburn_buff) and not target.DebuffPresent(soulburn_seed_of_corruption_debuff) and not InFlightToTarget(soulburn_seed_of_corruption) and SoulShards() >= 1 Spell(soulburn)
	#soul_swap,if=buff.soulburn.up&!dot.agony.ticking&!dot.corruption.ticking
	if BuffPresent(soulburn_buff) and not target.DebuffPresent(agony_debuff) and not target.DebuffPresent(corruption_debuff) Spell(soul_swap)
	#soul_swap,cycle_targets=1,if=buff.soulburn.up&dot.corruption.ticking&!dot.agony.ticking
	if BuffPresent(soulburn_buff) and target.DebuffPresent(corruption_debuff) and not target.DebuffPresent(agony_debuff) Spell(soul_swap)
	#seed_of_corruption,cycle_targets=1,if=(buff.soulburn.down&!in_flight_to_target&!ticking)|(buff.soulburn.up&!dot.soulburn_seed_of_corruption.ticking&!action.soulburn_seed_of_corruption.in_flight_to_target)
	if BuffExpires(soulburn_buff) and not InFlightToTarget(seed_of_corruption) and not target.DebuffPresent(seed_of_corruption_debuff) or BuffPresent(soulburn_buff) and not target.DebuffPresent(soulburn_seed_of_corruption_debuff) and not InFlightToTarget(soulburn_seed_of_corruption) Spell(seed_of_corruption)
	#haunt,cycle_targets=1,if=!in_flight_to_target&debuff.haunt.remains<cast_time+travel_time&shard_react
	if not InFlightToTarget(haunt) and target.DebuffRemaining(haunt_debuff) < CastTime(haunt) + 0.5 and SoulShards() >= 1 Spell(haunt)
	#life_tap,if=mana.pct<70
	if ManaPercent() < 70 Spell(life_tap)
	#fel_flame,cycle_targets=1,if=!in_flight_to_target
	if not InFlightToTarget(fel_flame) Spell(fel_flame)
}

AddIcon specialization=affliction help=main enemies=1
{
	if InCombat(no) AfflictionPrecombatActions()
	AfflictionDefaultActions()
}

AddIcon specialization=affliction help=aoe
{
	if InCombat(no) AfflictionPrecombatActions()
	AfflictionDefaultActions()
}

### Required symbols
# agony
# agony_debuff
# archimondes_darkness_talent
# berserking
# corruption
# corruption_debuff
# curse_of_the_elements
# dark_intent
# dark_soul_misery
# dark_soul_misery_buff
# drain_soul
# fel_flame
# grimoire_felhunter
# grimoire_of_sacrifice
# grimoire_of_sacrifice_buff
# grimoire_of_sacrifice_talent
# grimoire_of_service_talent
# haunt
# haunt_debuff
# jade_serpent_potion
# life_tap
# malefic_grasp
# seed_of_corruption
# seed_of_corruption_debuff
# soul_swap
# soul_swap_buff
# soulburn
# soulburn_buff
# soulburn_seed_of_corruption
# soulburn_seed_of_corruption_debuff
# summon_doomguard
# summon_felhunter
# summon_infernal
# trinket_proc_intellect_buff
# trinket_stacking_proc_intellect_buff
# unstable_affliction
# unstable_affliction_debuff
]]
	OvaleScripts:RegisterScript("WARLOCK", name, desc, code, "reference")
end
