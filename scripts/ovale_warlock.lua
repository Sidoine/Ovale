local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.4] Ovale: Affliction, Demonology (5.2), Destruction"
	local code = [[
# Ovale warlock script based on SimulationCraft.

Include(ovale_common)
Include(ovale_warlock_common)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

###
### Affliction
###
# Based on SimulationCraft profile "Warlock_Affliction_T16H".
#	class=warlock
#	spec=affliction
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Va!....00
#	glyphs=siphon_life
#	pet=felhunter

AddFunction AfflictionAoeActions
{
	#soulburn,cycle_targets=1,if=buff.soulburn.down&!dot.soulburn_seed_of_corruption.ticking&!action.soulburn_seed_of_corruption.in_flight_to_target&shard_react
	if BuffExpires(soulburn_buff) and not target.DebuffPresent(soulburn_seed_of_corruption_debuff) and not InFlightToTarget(soulburn_seed_of_corruption) and SoulShards() >= 1 Spell(soulburn)
	#soul_swap,if=buff.soulburn.up&!dot.agony.ticking&!dot.corruption.ticking
	if BuffPresent(soulburn_buff) and not target.DebuffPresent(agony_debuff) and not target.DebuffPresent(corruption_debuff) Spell(soul_swap)
	#soul_swap,cycle_targets=1,if=buff.soulburn.up&dot.corruption.ticking&!dot.agony.ticking
	if BuffPresent(soulburn_buff) and target.DebuffPresent(corruption_debuff) and not target.DebuffPresent(agony_debuff) Spell(soul_swap_exhale)
	#seed_of_corruption,cycle_targets=1,if=(buff.soulburn.down&!in_flight_to_target&!ticking)|(buff.soulburn.up&!dot.soulburn_seed_of_corruption.ticking&!action.soulburn_seed_of_corruption.in_flight_to_target)
	if { BuffExpires(soulburn_buff) and not InFlightToTarget(seed_of_corruption) and not target.DebuffPresent(seed_of_corruption_debuff) } or { BuffPresent(soulburn_buff) and not target.DebuffPresent(soulburn_seed_of_corruption_debuff) and not InFlightToTarget(soulburn_seed_of_corruption) } Spell(seed_of_corruption)
	#haunt,cycle_targets=1,if=!in_flight_to_target&debuff.haunt.remains<cast_time+travel_time&shard_react
	if not InFlightToTarget(haunt) and target.DebuffRemains(haunt_debuff) < CastTime(haunt) + 0.5 and SoulShards() >= 1 Spell(haunt)
	#life_tap,if=mana.pct<70
	if ManaPercent() < 70 Spell(life_tap)
	#fel_flame,cycle_targets=1,if=!in_flight_to_target
	if not InFlightToTarget(fel_flame) Spell(fel_flame)
}

AddFunction AfflictionAoeCdActions
{
	#summon_infernal
	Spell(summon_infernal)
}

AddFunction AfflictionSingleTargetActions
{
	#soul_swap,if=buff.soulburn.up
	if BuffPresent(soulburn_buff) Spell(soul_swap)
	#soulburn,if=(buff.dark_soul.up|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react>6)&(dot.agony.ticks_remain<=action.agony.add_ticks%2|dot.corruption.ticks_remain<=action.corruption.add_ticks%2|dot.unstable_affliction.ticks_remain<=action.unstable_affliction.add_ticks%2)&shard_react
	if { BuffPresent(dark_soul_misery_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffStacks(trinket_stacking_proc_intellect_buff) > 6 } and { target.TicksRemain(agony_debuff) <= TicksAdded(agony_debuff) / 2 or target.TicksRemain(corruption_debuff) <= TicksAdded(corruption_debuff) / 2 or target.TicksRemain(unstable_affliction_debuff) <= TicksAdded(unstable_affliction_debuff) / 2 } and SoulShards() >= 1 Spell(soulburn)
	#soulburn,if=(dot.unstable_affliction.ticks_remain<=1|dot.corruption.ticks_remain<=1|dot.agony.ticks_remain<=1)&shard_react&target.health.pct<=20
	if { target.TicksRemain(unstable_affliction_debuff) <= 1 or target.TicksRemain(corruption_debuff) <= 1 or target.TicksRemain(agony_debuff) <= 1 } and SoulShards() >= 1 and target.HealthPercent() <= 20 Spell(soulburn)
	#haunt,if=!in_flight_to_target&remains<cast_time+travel_time+tick_time&shard_react&target.health.pct<=20
	if not InFlightToTarget(haunt) and target.DebuffRemains(haunt_debuff) < CastTime(haunt) + 0.5 + target.TickTime(haunt_debuff) and SoulShards() >= 1 and target.HealthPercent() <= 20 Spell(haunt)
	#drain_soul,interrupt=1,chain=1,if=target.health.pct<=20
	if target.HealthPercent() <= 20 Spell(drain_soul)
	#haunt,if=!in_flight_to_target&remains<cast_time+travel_time+tick_time&shard_react
	if not InFlightToTarget(haunt) and target.DebuffRemains(haunt_debuff) < CastTime(haunt) + 0.5 + target.TickTime(haunt_debuff) and SoulShards() >= 1 Spell(haunt)
	#agony,if=(tick_damage*n_ticks*(100+crit_pct_current)>4*dot.agony.tick_dmg*dot.agony.ticks_remain*(100+dot.agony.crit_pct))&miss_react
	if { target.Damage(agony_debuff) * target.Ticks(agony_debuff) * { 100 + SpellCritChance() } > 4 * target.LastEstimatedDamage(agony_debuff) * target.TicksRemain(agony_debuff) * { 100 + target.DebuffSpellCritChance(agony_debuff) } } and True(miss_react) Spell(agony)
	#corruption,if=((stat.spell_power>spell_power&ticks_remain<add_ticks%2)|(stat.spell_power>spell_power*1.5)|remains<gcd)&miss_react
	if { { Spellpower() > target.DebuffSpellpower(corruption_debuff) and target.TicksRemain(corruption_debuff) < TicksAdded(corruption_debuff) / 2 } or { Spellpower() > target.DebuffSpellpower(corruption_debuff) * 1.5 } or target.DebuffRemains(corruption_debuff) < GCD() } and True(miss_react) Spell(corruption)
	#unstable_affliction,if=((stat.spell_power>spell_power&ticks_remain<add_ticks%2)|(stat.spell_power>spell_power*1.5)|remains<cast_time+gcd)&miss_react
	if { { Spellpower() > target.DebuffSpellpower(unstable_affliction_debuff) and target.TicksRemain(unstable_affliction_debuff) < TicksAdded(unstable_affliction_debuff) / 2 } or { Spellpower() > target.DebuffSpellpower(unstable_affliction_debuff) * 1.5 } or target.DebuffRemains(unstable_affliction_debuff) < CastTime(unstable_affliction) + GCD() } and True(miss_react) Spell(unstable_affliction)
	#life_tap,if=buff.dark_soul.down&buff.bloodlust.down&mana.pct<50
	if BuffExpires(dark_soul_misery_buff) and BuffExpires(burst_haste any=1) and ManaPercent() < 50 Spell(life_tap)
	#malefic_grasp,chain=1,interrupt_if=target.health.pct<=20
	Spell(malefic_grasp)
	#life_tap,moving=1,if=mana.pct<80&mana.pct<target.health.pct
	if Speed() > 0 and ManaPercent() < 80 and ManaPercent() < target.HealthPercent() Spell(life_tap)
	#fel_flame,moving=1
	if Speed() > 0 Spell(fel_flame)
	#life_tap
	Spell(life_tap)
}

AddFunction AfflictionSingleTargetCdActions
{
	#summon_doomguard
	Spell(summon_doomguard)
}

AddFunction AfflictionDefaultActions
{
	#curse_of_the_elements,if=debuff.magic_vulnerability.down
	if target.DebuffExpires(magic_vulnerability any=1) Spell(curse_of_the_elements)
}

AddFunction AfflictionDefaultShortCdActions
{
	unless target.DebuffExpires(magic_vulnerability any=1)
	{
		#dark_soul,if=!talent.archimondes_darkness.enabled|(talent.archimondes_darkness.enabled&(charges=2|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react|target.health.pct<=10))
		if not TalentPoints(archimondes_darkness_talent) or { TalentPoints(archimondes_darkness_talent) and { Charges(dark_soul_misery) == 2 or BuffPresent(trinket_proc_intellect_buff) or BuffStacks(trinket_stacking_proc_intellect_buff) or target.HealthPercent() <= 10 } } Spell(dark_soul_misery)
		#service_pet,if=talent.grimoire_of_service.enabled
		if TalentPoints(grimoire_of_service_talent) ServicePet()
	}
}

AddFunction AfflictionDefaultCdActions
{
	unless target.DebuffExpires(magic_vulnerability any=1)
	{
		#use_item,name=gloves_of_the_horned_nightmare
		UseItemActions()
		#jade_serpent_potion,if=buff.bloodlust.react|target.health.pct<=20
		if BuffPresent(burst_haste any=1) or target.HealthPercent() <= 20 UsePotionIntellect()
		#berserking
		UseRacialActions()
	}
}

AddFunction AfflictionPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier any=1) Spell(dark_intent)
	#snapshot_stats
}

AddFunction AfflictionPrecombatShortCdActions
{
	#summon_pet,if=!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down
	if not TalentPoints(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) SummonPet()
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
	if pet.Present() and TalentPoints(grimoire_of_sacrifice_talent) Spell(grimoire_of_sacrifice)
	#service_pet,if=talent.grimoire_of_service.enabled
	if TalentPoints(grimoire_of_service_talent) ServicePet()
}

AddFunction AfflictionPrecombatCdActions
{
	#jade_serpent_potion
	UsePotionIntellect()
}

### Affliction icons.

AddIcon mastery=affliction size=small checkboxon=opt_icons_left
{
	if target.IsAggroed() Spell(soulshatter)
	if TalentPoints(dark_regeneration_talent) Spell(dark_regeneration)
}

AddIcon mastery=affliction size=small checkboxon=opt_icons_left
{
	if TalentPoints(sacrificial_pact_talent) Spell(sacrificial_pact)
	if TalentPoints(dark_bargain_talent) Spell(dark_bargain)
}

AddIcon mastery=affliction help=shortcd
{
	if InCombat(no) AfflictionPrecombatShortCdActions()
	AfflictionDefaultShortCdActions()
}

AddIcon mastery=affliction help=main
{
	if InCombat(no) AfflictionPrecombatActions()
	AfflictionDefaultActions()
	AfflictionSingleTargetActions()
}

AddIcon mastery=affliction help=aoe checkboxon=opt_aoe
{
	if InCombat(no) AfflictionPrecombatActions()
	AfflictionDefaultActions()
	AfflictionAoeActions()
}

AddIcon mastery=affliction help=cd
{
	if InCombat(no) AfflictionPrecombatCdActions()
	AfflictionDefaultCdActions()
	if Enemies() > 6 AfflictionAoeCdActions()
	if Enemies() <= 6 AfflictionSingleTargetCdActions()
}

AddIcon mastery=affliction size=small checkboxon=opt_icons_right
{
	Spell(demonic_circle_teleport)
}

AddIcon mastery=affliction size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

### Demonology icons.

AddIcon mastery=demonology size=small checkboxon=opt_icons_left
{
	if target.IsAggroed() Spell(soulshatter)
	if TalentPoints(dark_regeneration_talent) Spell(dark_regeneration)
}

AddIcon mastery=demonology size=small checkboxon=opt_icons_left
{
	if TalentPoints(sacrificial_pact_talent) Spell(sacrificial_pact)
	if TalentPoints(dark_bargain_talent) Spell(dark_bargain)
}

AddIcon mastery=demonology help=offgcd
{
	if not InCombat()
	{
		if pet.Present() and TalentPoints(grimoire_of_sacrifice_talent) Spell(grimoire_of_sacrifice)
	}
	Spell(melee)
	Spell(felguard_felstorm)
	Spell(wrathguard_wrathstorm)
	if {BuffPresent(dark_soul_knowledge) and DemonicFury() /32 >BuffRemains(dark_soul_knowledge) } or target.DebuffRemains(corruption_debuff) <5 or not target.DebuffPresent(doom) or DemonicFury() >=950 or DemonicFury() /32 >target.DeadIn() unless Stance(1) Spell(metamorphosis)
}

AddIcon mastery=demonology help=main
{
	if not InCombat()
	{
		if not BuffPresent(spell_power_multiplier any=1) Spell(dark_intent)
		if not TalentPoints(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice) unless pet.CreatureFamily(Felguard) Spell(summon_felguard)
		if TalentPoints(grimoire_of_service_talent) Spell(service_felguard)
	}
	if target.DebuffExpires(magic_vulnerability any=1) Spell(curse_of_the_elements)
	if TalentPoints(grimoire_of_service_talent) Spell(service_felguard)
	if BuffPresent(metamorphosis) and target.DebuffPresent(corruption_debuff) and target.DebuffRemains(corruption_debuff) <1.5 Spell(touch_of_chaos)
	if BuffPresent(metamorphosis) and {target.TicksRemain(doom) <=1 or {target.TicksRemain(doom) +1 <Ticks(doom) and BuffPresent(dark_soul_knowledge) } } and target.DeadIn() >=30 Spell(doom)
	if BuffPresent(metamorphosis) and target.DebuffPresent(corruption_debuff) and target.DebuffRemains(corruption_debuff) <20 Spell(touch_of_chaos)
	if BuffPresent(metamorphosis) and BuffExpires(dark_soul_knowledge) and DemonicFury() <=650 and target.DeadIn() >30 if Stance(1) cancel.Texture(Spell_shadow_demonform)
	if BuffPresent(metamorphosis) and BuffStacks(molten_core) and {BuffRemains(dark_soul_knowledge) <CastTime(shadow_bolt) or BuffRemains(dark_soul_knowledge) >CastTime(soul_fire) } Spell(soul_fire)
	if BuffPresent(metamorphosis) Spell(touch_of_chaos)
	if not target.DebuffPresent(corruption_debuff) and target.DeadIn() >=6 Spell(corruption)
	if not InFlightToTarget(hand_of_guldan) and target.DebuffRemains(shadowflame) <1 +CastTime(shadow_bolt) Spell(hand_of_guldan)
	if BuffStacks(molten_core) and {BuffRemains(dark_soul_knowledge) <CastTime(shadow_bolt) or BuffRemains(dark_soul_knowledge) >CastTime(soul_fire) } Spell(soul_fire)
	if ManaPercent() <60 Spell(life_tap)
	Spell(shadow_bolt)
	Spell(life_tap)
}

AddIcon mastery=demonology help=aoe checkboxon=opt_aoe
{
	if BuffPresent(metamorphosis) and target.DebuffRemains(corruption_debuff) >10 and DemonicFury() <=650 and BuffExpires(dark_soul_knowledge) and not target.DebuffPresent(immolation_aura) if Stance(1) cancel.Texture(Spell_shadow_demonform)
	if BuffPresent(metamorphosis) Spell(immolation_aura)
	if BuffPresent(metamorphosis) and target.DebuffRemains(corruption_debuff) <10 Spell(void_ray)
	if BuffPresent(metamorphosis) and {not target.DebuffPresent(doom) or target.DebuffRemains(doom) <TickTime(doom) or {target.TicksRemain(doom) +1 <Ticks(doom) and BuffPresent(dark_soul_knowledge) } } and target.DeadIn() >=30 Spell(doom)
	if BuffPresent(metamorphosis) Spell(void_ray)
	if not target.DebuffPresent(corruption_debuff) and target.DeadIn() >30 Spell(corruption)
	Spell(hand_of_guldan)
	if target.DebuffRemains(corruption_debuff) <10 or BuffPresent(dark_soul_knowledge) or DemonicFury() >=950 or DemonicFury() /32 >target.DeadIn() unless Stance(1) Spell(metamorphosis)
	Spell(hellfire)
	Spell(life_tap)
}

AddIcon mastery=demonology help=cd
{
	UseItemActions()
	Spell(blood_fury)
	Spell(dark_soul_knowledge)
	Spell(summon_doomguard)
}

AddIcon mastery=demonology size=small checkboxon=opt_icons_right
{
	Spell(demonic_circle_teleport)
}

AddIcon mastery=demonology size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

###
### Destruction
###
# Based on SimulationCraft profile "Warlock_Destruction_T16H".
#	class=warlock
#	spec=destruction
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Vb!....20
#	pet=felhunter

AddFunction DestructionAoeActions
{
	#rain_of_fire,if=!ticking&!in_flight
	if not target.DebuffPresent(rain_of_fire_aftermath_debuff) and not InFlightToTarget(rain_of_fire_aftermath) Spell(rain_of_fire_aftermath)
	#fire_and_brimstone,if=ember_react&buff.fire_and_brimstone.down
	if BurningEmbers() >= 10 and BuffExpires(fire_and_brimstone_buff) Spell(fire_and_brimstone)
	#immolate,if=buff.fire_and_brimstone.up&!ticking
	if BuffPresent(fire_and_brimstone_buff) and not target.DebuffPresent(immolate_debuff) Spell(immolate)
	#conflagrate,if=buff.fire_and_brimstone.up
	if BuffPresent(fire_and_brimstone_buff) Spell(conflagrate)
	#incinerate,if=buff.fire_and_brimstone.up
	if BuffPresent(fire_and_brimstone_buff) Spell(incinerate)
	#incinerate
	Spell(incinerate)
}

AddFunction DestructionAoeCdActions
{
	#summon_infernal
	Spell(summon_infernal)
}

AddFunction DestructionSingleTargetActions
{
	#immolate,cycle_targets=1,if=n_ticks*crit_pct_current>3*dot.immolate.ticks_remain*dot.immolate.crit_pct&miss_react
	if target.Ticks(immolate_debuff) * SpellCritChance() > 3 * target.TicksRemain(immolate_debuff) * target.DebuffSpellCritChance(immolate_debuff) and True(miss_react) Spell(immolate)
	#conflagrate,if=charges=2&buff.havoc.stack=0
	if Charges(conflagrate) == 2 and DebuffStacksOnAny(havoc_debuff) == 0 Spell(conflagrate)
	#chaos_bolt,if=ember_react&target.health.pct>20&(buff.backdraft.stack<3|level<86|(active_enemies>1&action.incinerate.cast_time<1))&(burning_ember>(4.5-active_enemies)|buff.skull_banner.remains>cast_time|(trinket.proc.intellect.react&trinket.proc.intellect.remains>cast_time)|(trinket.stacking_proc.intellect.remains<cast_time*2.5&trinket.stacking_proc.intellect.remains>cast_time))
	if BurningEmbers() >= 10 and target.HealthPercent() > 20 and { BuffStacks(backdraft_buff) < 3 or Level() < 86 } and { BurningEmbers() / 10 > 3.5 or BuffRemains(skull_banner_buff) > CastTime(chaos_bolt) or { BuffPresent(trinket_proc_intellect_buff) and BuffRemains(trinket_proc_intellect_buff) > CastTime(chaos_bolt) } or { BuffRemains(trinket_stacking_proc_intellect_buff) < CastTime(chaos_bolt) * 2.5 and BuffRemains(trinket_stacking_proc_intellect_buff) > CastTime(chaos_bolt) } } Spell(chaos_bolt)
	#chaos_bolt,if=ember_react&target.health.pct>20&(buff.havoc.stack=3&buff.havoc.remains>cast_time)
	if BurningEmbers() >= 10 and target.HealthPercent() > 20 and { DebuffStacksOnAny(havoc_debuff) == 3 and DebuffRemainsOnAny(havoc_debuff) > CastTime(chaos_bolt) } Spell(chaos_bolt)
	#conflagrate
	Spell(conflagrate)
	#incinerate
	Spell(incinerate)
}

AddFunction DestructionSingleTargetShortCdActions
{
	#shadowburn,if=ember_react&(burning_ember>3.5|mana.pct<=20|target.time_to_die<20|buff.havoc.stack>=1|trinket.proc.intellect.react|(trinket.stacking_proc.intellect.remains<cast_time*4&trinket.stacking_proc.intellect.remains>cast_time))
	if BurningEmbers() >= 10 and { BurningEmbers() / 10 > 3.5 or ManaPercent() <= 20 or target.TimeToDie() < 20 or DebuffStacksOnAny(havoc_debuff) >= 1 or BuffPresent(trinket_proc_intellect_buff) or { BuffRemains(trinket_stacking_proc_intellect_buff) < CastTime(shadowburn) * 4 and BuffRemains(trinket_stacking_proc_intellect_buff) > CastTime(shadowburn) } } Spell(shadowburn)
}

AddFunction DestructionSingleTargetCdActions
{
	#summon_doomguard
	Spell(summon_doomguard)
}

AddFunction DestructionDefaultActions
{
	#curse_of_the_elements,if=debuff.magic_vulnerability.down
	if target.DebuffExpires(magic_vulnerability any=1) Spell(curse_of_the_elements)
}

AddFunction DestructionDefaultShortCdActions
{
	unless target.DebuffExpires(magic_vulnerability any=1)
	{
		#dark_soul,if=!talent.archimondes_darkness.enabled|(talent.archimondes_darkness.enabled&(charges=2|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react|target.health.pct<=10))
		if not TalentPoints(archimondes_darkness_talent) or { TalentPoints(archimondes_darkness_talent) and { Charges(dark_soul_instability) == 2 or BuffPresent(trinket_proc_intellect_buff) or BuffStacks(trinket_stacking_proc_intellect_buff) or target.HealthPercent() <= 10 } } Spell(dark_soul_instability)
		#service_pet,if=talent.grimoire_of_service.enabled
		if TalentPoints(grimoire_of_service_talent) ServicePet()
	}
}

AddFunction DestructionDefaultCdActions
{
	unless target.DebuffExpires(magic_vulnerability any=1)
	{
		#use_item,name=gloves_of_the_horned_nightmare
		UseItemActions()
		#jade_serpent_potion,if=buff.bloodlust.react|target.health.pct<=20
		if BuffPresent(burst_haste any=1) or target.HealthPercent() <= 20 UsePotionIntellect()
		#berserking
		UseRacialActions()
	}
}

AddFunction DestructionPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier any=1) Spell(dark_intent)
	#snapshot_stats
}

AddFunction DestructionPrecombatShortCdActions
{
	#summon_pet,if=!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down
	if not TalentPoints(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) SummonPet()
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
	if pet.Present() and TalentPoints(grimoire_of_sacrifice_talent) Spell(grimoire_of_sacrifice)
	#service_pet,if=talent.grimoire_of_service.enabled
	if TalentPoints(grimoire_of_service_talent) ServicePet()
}

AddFunction DestructionPrecombatCdActions
{
	#jade_serpent_potion
	UsePotionIntellect()
}

### Destruction icons.

AddIcon mastery=destruction size=small checkboxon=opt_icons_left
{
	if target.IsAggroed() Spell(soulshatter)
	if TalentPoints(dark_regeneration_talent) Spell(dark_regeneration)
}

AddIcon mastery=destruction size=small checkboxon=opt_icons_left
{
	if TalentPoints(sacrificial_pact_talent) Spell(sacrificial_pact)
	if TalentPoints(dark_bargain_talent) Spell(dark_bargain)
}

AddIcon mastery=destruction help=shortcd
{
	if InCombat(no) DestructionPrecombatShortCdActions()
	DestructionDefaultShortCdActions()
	DestructionSingleTargetShortCdActions()
}

AddIcon mastery=destruction help=main
{
	if InCombat(no) DestructionPrecombatActions()
	DestructionDefaultActions()
	DestructionSingleTargetActions()
}

AddIcon mastery=destruction help=aoe checkboxon=opt_aoe
{
	if InCombat(no) DestructionPrecombatActions()
	DestructionDefaultActions()

	#havoc,target=2,if=active_enemies>1
	Spell(havoc)

	DestructionAoeActions()
}

AddIcon mastery=destruction help=cd
{
	if InCombat(no) DestructionPrecombatCdActions()
	DestructionDefaultCdActions()
	if Enemies() > 3 DestructionAoeCdActions()
	if Enemies() <= 3 DestructionSingleTargetCdActions()
}

AddIcon mastery=destruction size=small checkboxon=opt_icons_right
{
	Spell(demonic_circle_teleport)
}

AddIcon mastery=destruction size=small checkboxon=opt_icons_right
{
	UseItemActions()
}
]]

	OvaleScripts:RegisterScript("WARLOCK", name, desc, code, "script")
end
