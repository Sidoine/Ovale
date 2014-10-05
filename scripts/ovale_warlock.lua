local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_warlock"
	local desc = "[5.4.8] Ovale: Affliction, Demonology, Destruction"
	local code = [[
# Ovale warlock script based on SimulationCraft.

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

###
### Affliction
###
# Based on SimulationCraft profile "Warlock_Affliction_T16H".
#	class=warlock
#	spec=affliction
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Va!....00
#	glyphs=siphon_life
#	pet=felhunter

# ActionList: AfflictionPrecombatActions --> main, predict, shortcd, cd

AddFunction AfflictionPrecombatActions
{
	AfflictionPrecombatPredictActions()
}

AddFunction AfflictionPrecombatPredictActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier_buff any=1) Spell(dark_intent)
	#snapshot_stats
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
	if Talent(grimoire_of_sacrifice_talent) and pet.Present() Spell(grimoire_of_sacrifice)
}

AddFunction AfflictionPrecombatShortCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent)
	{
		#summon_pet,if=!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down
		if { Talent(grimoire_of_sacrifice_talent no) or BuffExpires(grimoire_of_sacrifice_buff) } and pet.Present(no) Spell(summon_felhunter)
		#service_pet,if=talent.grimoire_of_service.enabled
		if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)
	}
}

AddFunction AfflictionPrecombatCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent)
		or { Talent(grimoire_of_sacrifice_talent no) or BuffExpires(grimoire_of_sacrifice_buff) } and pet.Present(no) and Spell(summon_felhunter)
		or Talent(grimoire_of_service_talent) and Spell(grimoire_felhunter)
	{
		#jade_serpent_potion
		UsePotionIntellect()
	}
}

# ActionList: AfflictionDefaultActions --> main, predict, shortcd, cd

AddFunction AfflictionDefaultActions
{
	AfflictionDefaultPredictActions()

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

AddFunction AfflictionDefaultPredictActions
{
	#curse_of_the_elements,if=debuff.magic_vulnerability.down
	if target.DebuffExpires(magic_vulnerability_debuff any=1) Spell(curse_of_the_elements)
	#run_action_list,name=aoe,if=active_enemies>6
	if Enemies() > 6 AfflictionAoePredictActions()
	#soul_swap,if=buff.soulburn.up
	if BuffPresent(soulburn_buff) Spell(soul_swap)
	# CHANGE: Synchronize abilities that use Soulburn with Soulburn's conditions so that they are shown concurrently with Soulburn.
	unless Talent(grimoire_of_service_talent) and Spell(grimoire_felhunter)
	{
		#soulburn,if=(buff.dark_soul.up|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react>6)&(dot.agony.ticks_remain<=action.agony.add_ticks%2|dot.corruption.ticks_remain<=action.corruption.add_ticks%2|dot.unstable_affliction.ticks_remain<=action.unstable_affliction.add_ticks%2)&shard_react
		#soulburn,if=(dot.unstable_affliction.ticks_remain<=1|dot.corruption.ticks_remain<=1|dot.agony.ticks_remain<=1)&shard_react&target.health.pct<=20
		if { BuffPresent(dark_soul_misery_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffStacks(trinket_stacking_proc_intellect_buff) > 6 } and { target.TicksRemaining(agony_debuff) <= TicksAdded(agony_debuff) / 2 or target.TicksRemaining(corruption_debuff) <= TicksAdded(corruption_debuff) / 2 or target.TicksRemaining(unstable_affliction_debuff) <= TicksAdded(unstable_affliction_debuff) / 2 } and SoulShards() >= 1 Spell(soul_swap)
		if { target.TicksRemaining(unstable_affliction_debuff) < 2 or target.TicksRemaining(corruption_debuff) < 2 or target.TicksRemaining(agony_debuff) < 2 } and SoulShards() >= 1 and target.HealthPercent() <= 20 Spell(soul_swap)
	}
	#soul_swap,if=active_enemies>1&buff.soul_swap.down&(buff.dark_soul.up|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react>6)
	if Enemies() > 1 and BuffExpires(soul_swap_buff) and { BuffPresent(dark_soul_misery_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffStacks(trinket_stacking_proc_intellect_buff) > 6 } Spell(soul_swap)
	#soul_swap,cycle_targets=1,if=active_enemies>1&buff.soul_swap.up&(dot.agony.ticks_remain<=action.agony.add_ticks%2|dot.corruption.ticks_remain<=action.corruption.add_ticks%2|dot.unstable_affliction.ticks_remain<=action.unstable_affliction.add_ticks%2)&shard_react
	# CHANGE: Soul Swap: Exhale replaces Soul Swap if the Soul Swap buff is present.
	#if Enemies() > 1 and BuffPresent(soul_swap_buff) and { target.TicksRemaining(agony_debuff) <= TicksAdded(agony_debuff) / 2 or target.TicksRemaining(corruption_debuff) <= TicksAdded(corruption_debuff) / 2 or target.TicksRemaining(unstable_affliction_debuff) <= TicksAdded(unstable_affliction_debuff) / 2 } and SoulShards() >= 1 Spell(soul_swap)
	if Enemies() > 1 and BuffPresent(soul_swap_buff) and { target.TicksRemaining(agony_debuff) <= TicksAdded(agony_debuff) / 2 or target.TicksRemaining(corruption_debuff) <= TicksAdded(corruption_debuff) / 2 or target.TicksRemaining(unstable_affliction_debuff) <= TicksAdded(unstable_affliction_debuff) / 2 } and SoulShards() >= 1 Spell(soul_swap_exhale)
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
}

AddFunction AfflictionDefaultShortCdActions
{
	unless target.DebuffExpires(magic_vulnerability_debuff any=1) and Spell(curse_of_the_elements)
	{
		#service_pet,if=talent.grimoire_of_service.enabled
		if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)

		unless BuffPresent(soulburn_buff) and Spell(soul_swap)
		{
			#soulburn,if=(buff.dark_soul.up|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react>6)&(dot.agony.ticks_remain<=action.agony.add_ticks%2|dot.corruption.ticks_remain<=action.corruption.add_ticks%2|dot.unstable_affliction.ticks_remain<=action.unstable_affliction.add_ticks%2)&shard_react
			if { BuffPresent(dark_soul_misery_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffStacks(trinket_stacking_proc_intellect_buff) > 6 } and { target.TicksRemaining(agony_debuff) <= TicksAdded(agony_debuff) / 2 or target.TicksRemaining(corruption_debuff) <= TicksAdded(corruption_debuff) / 2 or target.TicksRemaining(unstable_affliction_debuff) <= TicksAdded(unstable_affliction_debuff) / 2 } and SoulShards() >= 1 Spell(soulburn)
			#soulburn,if=(dot.unstable_affliction.ticks_remain<=1|dot.corruption.ticks_remain<=1|dot.agony.ticks_remain<=1)&shard_react&target.health.pct<=20
			if { target.TicksRemaining(unstable_affliction_debuff) < 2 or target.TicksRemaining(corruption_debuff) < 2 or target.TicksRemaining(agony_debuff) < 2 } and SoulShards() >= 1 and target.HealthPercent() <= 20 Spell(soulburn)
		}
	}
}

AddFunction AfflictionDefaultCdActions
{
	unless target.DebuffExpires(magic_vulnerability_debuff any=1) and Spell(curse_of_the_elements)
	{
		#use_item,name=gloves_of_the_horned_nightmare
		UseItemActions()
		#jade_serpent_potion,if=buff.bloodlust.react|target.health.pct<=20
		if BuffPresent(burst_haste_buff any=1) or target.HealthPercent() <= 20 UsePotionIntellect()
		#berserking
		Spell(berserking)
		#dark_soul,if=!talent.archimondes_darkness.enabled|(talent.archimondes_darkness.enabled&(charges=2|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react|target.health.pct<=10))
		if Talent(archimondes_darkness_talent no) or Talent(archimondes_darkness_talent) and { Charges(dark_soul_misery) == 2 or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_stacking_proc_intellect_buff) or target.HealthPercent() <= 10 } Spell(dark_soul_misery)

		unless Talent(grimoire_of_service_talent) and Spell(grimoire_felhunter)
		{
			#run_action_list,name=aoe,if=active_enemies>6
			if Enemies() > 6 AfflictionAoeCdActions()
			#summon_doomguard
			Spell(summon_doomguard)
		}
	}
}

# ActionList: AfflictionAoeActions --> main, predict, shortcd, cd

AddFunction AfflictionAoeActions
{
	AfflictionAoePredictActions()
}

AddFunction AfflictionAoePredictActions
{
	# CHANGE: Synchronize abilities that use Soulburn with Soulburn's conditions so that they are shown concurrently with Soulburn.
	#soulburn,cycle_targets=1,if=buff.soulburn.down&!dot.soulburn_seed_of_corruption.ticking&!action.soulburn_seed_of_corruption.in_flight_to_target&shard_react
	#if BuffExpires(soulburn_buff) and not target.DebuffPresent(soulburn_seed_of_corruption_debuff) and not InFlightToTarget(soulburn_seed_of_corruption) and SoulShards() >= 1 Spell(soul_swap)
	#soul_swap,if=buff.soulburn.up&!dot.agony.ticking&!dot.corruption.ticking
	if { BuffPresent(soulburn_buff) or BuffExpires(soulburn_buff) and not target.DebuffPresent(soulburn_seed_of_corruption_debuff) and not InFlightToTarget(soulburn_seed_of_corruption) and SoulShards() >= 1 } and not target.DebuffPresent(agony_debuff) and not target.DebuffPresent(corruption_debuff) Spell(soul_swap)
	#soul_swap,cycle_targets=1,if=buff.soulburn.up&dot.corruption.ticking&!dot.agony.ticking
	if { BuffPresent(soulburn_buff) or BuffExpires(soulburn_buff) and not target.DebuffPresent(soulburn_seed_of_corruption_debuff) and not InFlightToTarget(soulburn_seed_of_corruption) and SoulShards() >= 1 } and target.DebuffPresent(corruption_debuff) and not target.DebuffPresent(agony_debuff) Spell(soul_swap)
	#seed_of_corruption,cycle_targets=1,if=(buff.soulburn.down&!in_flight_to_target&!ticking)|(buff.soulburn.up&!dot.soulburn_seed_of_corruption.ticking&!action.soulburn_seed_of_corruption.in_flight_to_target)
	if BuffExpires(soulburn_buff) and not InFlightToTarget(seed_of_corruption) and not target.DebuffPresent(seed_of_corruption_debuff) or { BuffPresent(soulburn_buff) or BuffExpires(soulburn_buff) and not target.DebuffPresent(soulburn_seed_of_corruption_debuff) and not InFlightToTarget(soulburn_seed_of_corruption) and SoulShards() >= 1 } and not target.DebuffPresent(soulburn_seed_of_corruption_debuff) and not InFlightToTarget(soulburn_seed_of_corruption) Spell(seed_of_corruption)
	#haunt,cycle_targets=1,if=!in_flight_to_target&debuff.haunt.remains<cast_time+travel_time&shard_react
	if not InFlightToTarget(haunt) and target.DebuffRemaining(haunt_debuff) < CastTime(haunt) + 0.5 and SoulShards() >= 1 Spell(haunt)
	#life_tap,if=mana.pct<70
	if ManaPercent() < 70 Spell(life_tap)
	#fel_flame,cycle_targets=1,if=!in_flight_to_target
	if not InFlightToTarget(fel_flame) Spell(fel_flame)
}

AddFunction AfflictionAoeShortCdActions
{
	#soulburn,cycle_targets=1,if=buff.soulburn.down&!dot.soulburn_seed_of_corruption.ticking&!action.soulburn_seed_of_corruption.in_flight_to_target&shard_react
	if BuffExpires(soulburn_buff) and not target.DebuffPresent(soulburn_seed_of_corruption_debuff) and not InFlightToTarget(soulburn_seed_of_corruption) and SoulShards() >= 1 Spell(soulburn)
}

AddFunction AfflictionAoeCdActions
{
	#summon_infernal
	Spell(summon_infernal)
}

### Affliction icons.
AddCheckBox(opt_warlock_affliction "Show Affliction icons" specialization=affliction default)
AddCheckBox(opt_warlock_affliction_aoe L(AOE) specialization=affliction default)

AddIcon specialization=affliction help=shortcd enemies=1 checkbox=opt_warlock_affliction checkbox=!opt_warlock_affliction_aoe
{
	if InCombat(no) AfflictionPrecombatShortCdActions()
	AfflictionDefaultShortCdActions()
}

AddIcon specialization=affliction help=shortcd checkbox=opt_warlock_affliction checkbox=opt_warlock_affliction_aoe
{
	if InCombat(no) AfflictionPrecombatShortCdActions()
	AfflictionDefaultShortCdActions()
}

AddIcon specialization=affliction help=main enemies=1 checkbox=opt_warlock_affliction
{
	if InCombat(no) AfflictionPrecombatActions()
	AfflictionDefaultActions()
}

AddIcon specialization=affliction help=predict enemies=1 checkbox=opt_warlock_affliction checkbox=!opt_warlock_affliction_aoe
{
	if InCombat(no) AfflictionPrecombatPredictActions()
	AfflictionDefaultPredictActions()
}

AddIcon specialization=affliction help=aoe checkbox=opt_warlock_affliction checkbox=opt_warlock_affliction_aoe
{
	if InCombat(no) AfflictionPrecombatActions()
	AfflictionDefaultActions()
}

AddIcon specialization=affliction help=cd enemies=1 checkbox=opt_warlock_affliction checkbox=!opt_warlock_affliction_aoe
{
	if InCombat(no) AfflictionPrecombatCdActions()
	AfflictionDefaultCdActions()
}

AddIcon specialization=affliction help=cd checkbox=opt_warlock_affliction checkbox=opt_warlock_affliction_aoe
{
	if InCombat(no) AfflictionPrecombatCdActions()
	AfflictionDefaultCdActions()
}

# Based on SimulationCraft profile "Warlock_Demonology_T16H".
#	class=warlock
#	spec=demonology
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#VZ!....10
#	pet=felguard

# ActionList: DemonologyPrecombatActions --> main, predict, shortcd, cd

AddFunction DemonologyPrecombatActions
{
	DemonologyPrecombatPredictActions()
}

AddFunction DemonologyPrecombatPredictActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier_buff any=1) Spell(dark_intent)
	#snapshot_stats
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
	if Talent(grimoire_of_sacrifice_talent) and pet.Present() Spell(grimoire_of_sacrifice)
}

AddFunction DemonologyPrecombatShortCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent)
	{
		#summon_pet,if=!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down
		if { Talent(grimoire_of_sacrifice_talent no) or BuffExpires(grimoire_of_sacrifice_buff) } and pet.Present(no) Spell(summon_felhunter)
		#service_pet,if=talent.grimoire_of_service.enabled
		if Talent(grimoire_of_service_talent) Spell(grimoire_felguard)
	}
}

AddFunction DemonologyPrecombatCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent)
		or { Talent(grimoire_of_sacrifice_talent no) or BuffExpires(grimoire_of_sacrifice_buff) } and pet.Present(no) and Spell(summon_felguard)
		or Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice)
		or Talent(grimoire_of_service_talent) and Spell(grimoire_felguard)
	{
		#jade_serpent_potion
		UsePotionIntellect()
	}
}

# ActionList: DemonologyDefaultActions --> main, predict, shortcd, cd

AddFunction DemonologyDefaultActions
{
	DemonologyDefaultPredictActions()

	#life_tap,if=mana.pct<60
	if ManaPercent() < 60 Spell(life_tap)
	#shadow_bolt
	Spell(shadow_bolt)
	#fel_flame,moving=1
	if Speed() > 0 Spell(fel_flame)
	#life_tap
	Spell(life_tap)
}

AddFunction DemonologyDefaultPredictActions
{
	#curse_of_the_elements,if=debuff.magic_vulnerability.down
	if target.DebuffExpires(magic_vulnerability_debuff any=1) Spell(curse_of_the_elements)
	#run_action_list,name=aoe,if=active_enemies>4
	if Enemies() > 4 DemonologyAoePredictActions()
	#doom,cycle_targets=1,if=buff.metamorphosis.up&(ticks_remain<=1|(ticks_remain+1<n_ticks&buff.dark_soul.up)|(ticks_remain<=add_ticks%2&stat.spell_power>spell_power))&target.time_to_die>=30&miss_react
	if BuffPresent(metamorphosis_buff) and { target.TicksRemaining(doom_debuff) < 2 or target.TicksRemaining(doom_debuff) + 1 < target.Ticks(doom_debuff) and BuffPresent(dark_soul_knowledge_buff) or target.TicksRemaining(doom_debuff) <= TicksAdded(doom_debuff) / 2 and Spellpower() > target.DebuffSpellpower(doom_debuff) } and target.TimeToDie() >= 30 and True(miss_react) Spell(doom)
	#soul_fire,if=buff.metamorphosis.up&buff.molten_core.react&(buff.dark_soul.remains<action.shadow_bolt.cast_time|buff.dark_soul.remains>cast_time)
	if BuffPresent(metamorphosis_buff) and BuffPresent(molten_core_buff) and { BuffRemaining(dark_soul_knowledge_buff) < CastTime(shadow_bolt) or BuffRemaining(dark_soul_knowledge_buff) > CastTime(soul_fire) } Spell(soul_fire)
	#touch_of_chaos,if=buff.metamorphosis.up
	if BuffPresent(metamorphosis_buff) Spell(touch_of_chaos)
	#corruption,cycle_targets=1,if=!ticking&target.time_to_die>=6&miss_react
	if not target.DebuffPresent(corruption_debuff) and target.TimeToDie() >= 6 and True(miss_react) Spell(corruption)
	#corruption,cycle_targets=1,if=spell_power<stat.spell_power&ticks_remain<=add_ticks%2&target.time_to_die>=6&miss_react
	if target.DebuffSpellpower(corruption_debuff) < Spellpower() and target.TicksRemaining(corruption_debuff) <= TicksAdded(corruption_debuff) / 2 and target.TimeToDie() >= 6 and True(miss_react) Spell(corruption)
	#hand_of_guldan,if=!in_flight&dot.shadowflame.remains<travel_time+action.shadow_bolt.cast_time&(charges=2|dot.shadowflame.remains>travel_time|(charges=1&recharge_time<4))
	if not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < 0.5 + CastTime(shadow_bolt) and { Charges(hand_of_guldan) == 2 or target.DebuffRemaining(shadowflame_debuff) > 0.5 or Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 } Spell(hand_of_guldan)
	#soul_fire,if=buff.molten_core.react&(buff.dark_soul.remains<action.shadow_bolt.cast_time|buff.dark_soul.remains>cast_time)&(buff.molten_core.react>9|target.health.pct<=28)
	if BuffPresent(molten_core_buff) and { BuffRemaining(dark_soul_knowledge_buff) < CastTime(shadow_bolt) or BuffRemaining(dark_soul_knowledge_buff) > CastTime(soul_fire) } and { BuffStacks(molten_core_buff) > 9 or target.HealthPercent() <= 28 } Spell(soul_fire)
}

AddFunction DemonologyDefaultShortCdActions
{
	unless target.DebuffExpires(magic_vulnerability_debuff any=1) and Spell(curse_of_the_elements)
	{
		#service_pet,if=talent.grimoire_of_service.enabled
		if Talent(grimoire_of_service_talent) Spell(grimoire_felguard)
		#felguard:felstorm
		if pet.Present() and pet.CreatureFamily(Felguard) Spell(felguard_felstorm)
		#wrathguard:wrathstorm
		if pet.Present() and pet.CreatureFamily(Wrathguard) Spell(wrathguard_wrathstorm)
		#run_action_list,name=aoe,if=active_enemies>4
		if Enemies() > 4 DemonologyAoeShortCdActions()

		unless BuffPresent(metamorphosis_buff) and { target.TicksRemaining(doom_debuff) < 2 or target.TicksRemaining(doom_debuff) + 1 < target.Ticks(doom_debuff) and BuffPresent(dark_soul_knowledge_buff) or target.TicksRemaining(doom_debuff) <= TicksAdded(doom_debuff) / 2 and Spellpower() > target.DebuffSpellpower(doom_debuff) } and target.TimeToDie() >= 30 and True(miss_react) and Spell(doom)
		{
			#cancel_metamorphosis,if=buff.metamorphosis.up&buff.dark_soul.down&demonic_fury<=650&target.time_to_die>30&(cooldown.metamorphosis.remains<4|demonic_fury<=300)&!(action.hand_of_guldan.in_flight&dot.shadowflame.remains)
			if BuffPresent(metamorphosis_buff) and BuffExpires(dark_soul_knowledge_buff) and DemonicFury() <= 650 and target.TimeToDie() > 30 and { SpellCooldown(metamorphosis) < 4 or DemonicFury() <= 300 } and not { InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) } Texture(spell_shadow_demonform text=cancel)

			unless BuffPresent(metamorphosis_buff) and BuffPresent(molten_core_buff) and { BuffRemaining(dark_soul_knowledge_buff) < CastTime(shadow_bolt) or BuffRemaining(dark_soul_knowledge_buff) > CastTime(soul_fire) } and Spell(soul_fire)
				or BuffPresent(metamorphosis_buff) and Spell(touch_of_chaos)
			{
				#metamorphosis,if=(buff.dark_soul.up&buff.dark_soul.remains<demonic_fury%32)|demonic_fury>=950|demonic_fury%32>target.time_to_die|(action.hand_of_guldan.in_flight&dot.shadowflame.remains)
				if { BuffPresent(dark_soul_knowledge_buff) and BuffRemaining(dark_soul_knowledge_buff) < DemonicFury() / 32 or DemonicFury() >= 950 or DemonicFury() / 32 > target.TimeToDie() or InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) } and not Stance(warlock_metamorphosis) Spell(metamorphosis)
			}
		}
	}
}

AddFunction DemonologyDefaultCdActions
{
	unless target.DebuffExpires(magic_vulnerability_debuff any=1) and Spell(curse_of_the_elements)
	{
		#use_item,name=gloves_of_the_horned_nightmare
		UseItemActions()
		#jade_serpent_potion,if=buff.bloodlust.react|target.health.pct<=20
		if BuffPresent(burst_haste_buff any=1) or target.HealthPercent() <= 20 UsePotionIntellect()
		#berserking
		Spell(berserking)
		#dark_soul,if=!talent.archimondes_darkness.enabled|(talent.archimondes_darkness.enabled&(charges=2|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react|target.health.pct<=10))
		if Talent(archimondes_darkness_talent no) or Talent(archimondes_darkness_talent) and { Charges(dark_soul_knowledge) == 2 or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_stacking_proc_intellect_buff) or target.HealthPercent() <= 10 } Spell(dark_soul_knowledge)

		unless Talent(grimoire_of_service_talent) and Spell(grimoire_felguard)
		{
			#run_action_list,name=aoe,if=active_enemies>4
			if Enemies() > 4 DemonologyAoeCdActions()
			#summon_doomguard
			Spell(summon_doomguard)
		}
	}
}

# ActionList: DemonologyAoeActions --> main, predict, shortcd, cd

AddFunction DemonologyAoeActions
{
	DemonologyAoePredictActions()

	#hellfire,chain=1,interrupt=1
	Spell(hellfire)
	#life_tap
	Spell(life_tap)
}

AddFunction DemonologyAoePredictActions
{
	#immolation_aura,if=buff.metamorphosis.up
	if BuffPresent(metamorphosis_buff) Spell(immolation_aura)
	#void_ray,if=buff.metamorphosis.up&dot.corruption.remains<10
	if BuffPresent(metamorphosis_buff) and target.DebuffRemaining(corruption_debuff) < 10 Spell(void_ray)
	#doom,cycle_targets=1,if=buff.metamorphosis.up&(!ticking|remains<tick_time|(ticks_remain+1<n_ticks&buff.dark_soul.up))&target.time_to_die>=30&miss_react
	if BuffPresent(metamorphosis_buff) and { not target.DebuffPresent(doom_debuff) or target.DebuffRemaining(doom_debuff) < target.TickTime(doom_debuff) or target.TicksRemaining(doom_debuff) + 1 < target.Ticks(doom_debuff) and BuffPresent(dark_soul_knowledge_buff) } and target.TimeToDie() >= 30 and True(miss_react) Spell(doom)
	#void_ray,if=buff.metamorphosis.up
	if BuffPresent(metamorphosis_buff) Spell(void_ray)
	#corruption,cycle_targets=1,if=!ticking&target.time_to_die>30&miss_react
	if not target.DebuffPresent(corruption_debuff) and target.TimeToDie() > 30 and True(miss_react) Spell(corruption)
	#hand_of_guldan
	Spell(hand_of_guldan)
}

AddFunction DemonologyAoeShortCdActions
{
	#cancel_metamorphosis,if=buff.metamorphosis.up&dot.corruption.remains>10&demonic_fury<=650&buff.dark_soul.down&!dot.immolation_aura.ticking
	if BuffPresent(metamorphosis_buff) and target.DebuffRemaining(corruption_debuff) > 10 and DemonicFury() <= 650 and BuffExpires(dark_soul_knowledge_buff) and not target.DebuffPresent(immolation_aura_debuff) Texture(spell_shadow_demonform text=cancel)

	unless BuffPresent(metamorphosis_buff) and Spell(immolation_aura)
		or BuffPresent(metamorphosis_buff) and target.DebuffRemaining(corruption_debuff) < 10 and Spell(void_ray)
		or BuffPresent(metamorphosis_buff) and { not target.DebuffPresent(doom_debuff) or target.DebuffRemaining(doom_debuff) < target.TickTime(doom_debuff) or target.TicksRemaining(doom_debuff) + 1 < target.Ticks(doom_debuff) and BuffPresent(dark_soul_knowledge_buff) } and target.TimeToDie() >= 30 and True(miss_react) and Spell(doom)
		or BuffPresent(metamorphosis_buff) and Spell(void_ray)
		or not target.DebuffPresent(corruption_debuff) and target.TimeToDie() > 30 and True(miss_react) and Spell(corruption)
		or Spell(hand_of_guldan)
	{
		#metamorphosis,if=dot.corruption.remains<10|buff.dark_soul.up|demonic_fury>=950|demonic_fury%32>target.time_to_die
		if { target.DebuffRemaining(corruption_debuff) < 10 or BuffPresent(dark_soul_knowledge_buff) or DemonicFury() >= 950 or DemonicFury() / 32 > target.TimeToDie() } and not Stance(warlock_metamorphosis) Spell(metamorphosis)
	}
}

AddFunction DemonologyAoeCdActions
{
	#summon_infernal
	Spell(summon_infernal)
}

### Demonology icons.
AddCheckBox(opt_warlock_demonology "Show Demonology icons" specialization=demonology default)
AddCheckBox(opt_warlock_demonology_aoe L(AOE) specialization=demonology default)

AddIcon specialization=demonology help=shortcd enemies=1 checkbox=opt_warlock_demonology checkbox=!opt_warlock_demonology_aoe
{
	if InCombat(no) DemonologyPrecombatShortCdActions()
	DemonologyDefaultShortCdActions()
}

AddIcon specialization=demonology help=shortcd checkbox=opt_warlock_demonology checkbox=opt_warlock_demonology_aoe
{
	if InCombat(no) DemonologyPrecombatShortCdActions()
	DemonologyDefaultShortCdActions()
}

AddIcon specialization=demonology help=main enemies=1 checkbox=opt_warlock_demonology
{
	if InCombat(no) DemonologyPrecombatActions()
	DemonologyDefaultActions()
}

AddIcon specialization=demonology help=predict enemies=1 checkbox=opt_warlock_demonology checkbox=!opt_warlock_demonology_aoe
{
	if InCombat(no) DemonologyPrecombatPredictActions()
	DemonologyDefaultPredictActions()
}

AddIcon specialization=demonology help=aoe checkbox=opt_warlock_demonology checkbox=opt_warlock_demonology_aoe
{
	if InCombat(no) DemonologyPrecombatActions()
	DemonologyDefaultActions()
}

AddIcon specialization=demonology help=cd enemies=1 checkbox=opt_warlock_demonology checkbox=!opt_warlock_demonology_aoe
{
	if InCombat(no) DemonologyPrecombatCdActions()
	DemonologyDefaultCdActions()
}

AddIcon specialization=demonology help=cd checkbox=opt_warlock_demonology checkbox=opt_warlock_demonology_aoe
{
	if InCombat(no) DemonologyPrecombatCdActions()
	DemonologyDefaultCdActions()
}

###
### Destruction
###
# Based on SimulationCraft profile "Warlock_Destruction_T16H".
#	class=warlock
#	spec=destruction
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Vb!....20
#	pet=felhunter

# ActionList: DestructionPrecombatActions --> main, predict, shortcd, cd

AddFunction DestructionPrecombatActions
{
	DestructionPrecombatPredictActions()
}

AddFunction DestructionPrecombatPredictActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier_buff any=1) Spell(dark_intent)
	#snapshot_stats
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
	if Talent(grimoire_of_sacrifice_talent) and pet.Present() Spell(grimoire_of_sacrifice)
}

AddFunction DestructionPrecombatShortCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent)
	{
		#summon_pet,if=!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down
		if { Talent(grimoire_of_sacrifice_talent no) or BuffExpires(grimoire_of_sacrifice_buff) } and pet.Present(no) Spell(summon_felhunter)
		#service_pet,if=talent.grimoire_of_service.enabled
		if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)
	}
}

AddFunction DestructionPrecombatCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent)
		or { Talent(grimoire_of_sacrifice_talent no) or BuffExpires(grimoire_of_sacrifice_buff) } and pet.Present(no) and Spell(summon_felhunter)
		or Talent(grimoire_of_service_talent) and Spell(grimoire_felhunter)
	{
		#jade_serpent_potion
		UsePotionIntellect()
	}
}

# ActionList: DestructionDefaultActions --> main, predict, shortcd, cd

AddFunction DestructionDefaultActions
{
	DestructionDefaultPredictActions()

	#incinerate
	Spell(incinerate)
	#fel_flame,moving=1
	if Speed() > 0 Spell(fel_flame)
}

AddFunction DestructionDefaultPredictActions
{
	#curse_of_the_elements,if=debuff.magic_vulnerability.down
	if target.DebuffExpires(magic_vulnerability_debuff any=1) Spell(curse_of_the_elements)
	#run_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 DestructionAoePredictActions()
	#shadowburn,if=ember_react&(burning_ember>3.5|mana.pct<=20|target.time_to_die<20|buff.havoc.stack>=1|trinket.proc.intellect.react|(trinket.stacking_proc.intellect.remains<cast_time*4&trinket.stacking_proc.intellect.remains>cast_time))
	if BurningEmbers() >= 10 and { BurningEmbers() / 10 > 3.5 or ManaPercent() <= 20 or target.TimeToDie() < 20 or DebuffStacksOnAny(havoc_debuff) >= 1 or BuffPresent(trinket_proc_intellect_buff) or BuffRemaining(trinket_stacking_proc_intellect_buff) < CastTime(shadowburn) * 4 and BuffRemaining(trinket_stacking_proc_intellect_buff) > CastTime(shadowburn) } and target.HealthPercent() < 20 Spell(shadowburn)
	#immolate,cycle_targets=1,if=n_ticks*crit_pct_current>3*dot.immolate.ticks_remain*dot.immolate.crit_pct&miss_react
	if target.Ticks(immolate_debuff) * SpellCritChance() > 3 * target.TicksRemaining(immolate_debuff) * target.DebuffSpellCritChance(immolate_debuff) and True(miss_react) Spell(immolate)
	#conflagrate,if=charges=2&buff.havoc.stack=0
	if Charges(conflagrate) == 2 and DebuffStacksOnAny(havoc_debuff) == 0 Spell(conflagrate)
	#chaos_bolt,if=ember_react&target.health.pct>20&(buff.backdraft.stack<3|level<86|(active_enemies>1&action.incinerate.cast_time<1))&(burning_ember>(4.5-active_enemies)|buff.skull_banner.remains>cast_time|(trinket.proc.intellect.react&trinket.proc.intellect.remains>cast_time)|(trinket.stacking_proc.intellect.remains<cast_time*2.5&trinket.stacking_proc.intellect.remains>cast_time))
	if BurningEmbers() >= 10 and target.HealthPercent() > 20 and { BuffStacks(backdraft_buff) < 3 or Level() < 86 or Enemies() > 1 and CastTime(incinerate) < 1 } and { BurningEmbers() / 10 > 4.5 - Enemies() or BuffRemaining(skull_banner_buff any=1) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) or BuffRemaining(trinket_stacking_proc_intellect_buff) < CastTime(chaos_bolt) * 2.5 and BuffRemaining(trinket_stacking_proc_intellect_buff) > CastTime(chaos_bolt) } Spell(chaos_bolt)
	#chaos_bolt,if=ember_react&target.health.pct>20&(buff.havoc.stack=3&buff.havoc.remains>cast_time)
	if BurningEmbers() >= 10 and target.HealthPercent() > 20 and DebuffStacksOnAny(havoc_debuff) == 3 and DebuffRemainingOnAny(havoc_debuff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#conflagrate
	Spell(conflagrate)
}

AddFunction DestructionDefaultShortCdActions
{
	unless target.DebuffExpires(magic_vulnerability_debuff any=1) and Spell(curse_of_the_elements)
	{
		#service_pet,if=talent.grimoire_of_service.enabled
		if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)
		#run_action_list,name=aoe,if=active_enemies>3
		if Enemies() > 3 DestructionAoeShortCdActions()
		#rain_of_fire,if=!ticking&!in_flight&active_enemies>1
		if not target.DebuffPresent(rain_of_fire_aftermath_debuff) and not InFlightToTarget(rain_of_fire_aftermath) and Enemies() > 1 Spell(rain_of_fire_aftermath)
		#havoc,target=2,if=active_enemies>1
		if Enemies() > 1 Spell(havoc)

		unless BurningEmbers() >= 10 and { BurningEmbers() / 10 > 3.5 or ManaPercent() <= 20 or target.TimeToDie() < 20 or DebuffStacksOnAny(havoc_debuff) >= 1 or BuffPresent(trinket_proc_intellect_buff) or BuffRemaining(trinket_stacking_proc_intellect_buff) < CastTime(shadowburn) * 4 and BuffRemaining(trinket_stacking_proc_intellect_buff) > CastTime(shadowburn) } and target.HealthPercent() < 20 and Spell(shadowburn)
			or target.Ticks(immolate_debuff) * SpellCritChance() > 3 * target.TicksRemaining(immolate_debuff) * target.DebuffSpellCritChance(immolate_debuff) and True(miss_react) and Spell(immolate)
			or Charges(conflagrate) == 2 and DebuffStacksOnAny(havoc_debuff) == 0 and Spell(conflagrate)
		{
			#rain_of_fire,if=!ticking&!in_flight,moving=1
			if not target.DebuffPresent(rain_of_fire_aftermath_debuff) and not InFlightToTarget(rain_of_fire_aftermath) and Speed() > 0 Spell(rain_of_fire_aftermath)
		}
	}
}

AddFunction DestructionDefaultCdActions
{
	unless target.DebuffExpires(magic_vulnerability_debuff any=1) and Spell(curse_of_the_elements)
	{
		#use_item,name=gloves_of_the_horned_nightmare
		UseItemActions()
		#jade_serpent_potion,if=buff.bloodlust.react|target.health.pct<=20
		if BuffPresent(burst_haste_buff any=1) or target.HealthPercent() <= 20 UsePotionIntellect()
		#berserking
		Spell(berserking)
		#dark_soul,if=!talent.archimondes_darkness.enabled|(talent.archimondes_darkness.enabled&(charges=2|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react|target.health.pct<=10))
		if Talent(archimondes_darkness_talent no) or Talent(archimondes_darkness_talent) and { Charges(dark_soul_instability) == 2 or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_stacking_proc_intellect_buff) or target.HealthPercent() <= 10 } Spell(dark_soul_instability)

		unless Talent(grimoire_of_service_talent) and Spell(grimoire_felhunter)
		{
			#run_action_list,name=aoe,if=active_enemies>3
			if Enemies() > 3 DestructionAoeCdActions()
			#summon_doomguard
			Spell(summon_doomguard)
		}
	}
}

# ActionList: DestructionAoeActions --> main, predict, shortcd, cd

AddFunction DestructionAoeActions
{
	DestructionAoePredictActions()

	#incinerate
	Spell(incinerate)
}

AddFunction DestructionAoePredictActions
{
	#rain_of_fire,if=!ticking&!in_flight
	if not target.DebuffPresent(rain_of_fire_aftermath_debuff) and not InFlightToTarget(rain_of_fire_aftermath) Spell(rain_of_fire_aftermath)
	#immolate,if=buff.fire_and_brimstone.up&!ticking
	if BuffPresent(fire_and_brimstone_buff) and not target.DebuffPresent(immolate_debuff) Spell(immolate)
	#conflagrate,if=buff.fire_and_brimstone.up
	if BuffPresent(fire_and_brimstone_buff) Spell(conflagrate)
	#incinerate,if=buff.fire_and_brimstone.up
	if BuffPresent(fire_and_brimstone_buff) Spell(incinerate)
}

AddFunction DestructionAoeShortCdActions
{
	unless not target.DebuffPresent(rain_of_fire_aftermath_debuff) and not InFlightToTarget(rain_of_fire_aftermath) and Spell(rain_of_fire_aftermath)
	{
		#fire_and_brimstone,if=ember_react&buff.fire_and_brimstone.down
		if BurningEmbers() >= 10 and BuffExpires(fire_and_brimstone_buff) Spell(fire_and_brimstone)
	}
}

AddFunction DestructionAoeCdActions
{
	#summon_infernal
	Spell(summon_infernal)
}

### Destruction icons.
AddCheckBox(opt_warlock_destruction "Show Destruction icons" specialization=destruction default)
AddCheckBox(opt_warlock_destruction_aoe L(AOE) specialization=destruction default)

AddIcon specialization=destruction help=shortcd enemies=1 checkbox=opt_warlock_destruction checkbox=!opt_warlock_destruction_aoe
{
	if InCombat(no) DestructionPrecombatShortCdActions()
	DestructionDefaultShortCdActions()
}

AddIcon specialization=destruction help=shortcd checkbox=opt_warlock_destruction checkbox=opt_warlock_destruction_aoe
{
	if InCombat(no) DestructionPrecombatShortCdActions()
	DestructionDefaultShortCdActions()
}

AddIcon specialization=destruction help=main enemies=1 checkbox=opt_warlock_destruction
{
	if InCombat(no) DestructionPrecombatActions()
	DestructionDefaultActions()
}

AddIcon specialization=destruction help=predict enemies=1 checkbox=opt_warlock_destruction checkbox=!opt_warlock_destruction_aoe
{
	if InCombat(no) DestructionPrecombatPredictActions()
	DestructionDefaultPredictActions()
}

AddIcon specialization=destruction help=aoe checkbox=opt_warlock_destruction checkbox=opt_warlock_destruction_aoe
{
	if InCombat(no) DestructionPrecombatActions()
	DestructionDefaultActions()
}

AddIcon specialization=destruction help=cd enemies=1 checkbox=opt_warlock_destruction checkbox=!opt_warlock_destruction_aoe
{
	if InCombat(no) DestructionPrecombatCdActions()
	DestructionDefaultCdActions()
}

AddIcon specialization=destruction help=cd checkbox=opt_warlock_destruction checkbox=opt_warlock_destruction_aoe
{
	if InCombat(no) DestructionPrecombatCdActions()
	DestructionDefaultCdActions()
}
]]

	OvaleScripts:RegisterScript("WARLOCK", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("WARLOCK", "Ovale", desc, code, "script")
end
