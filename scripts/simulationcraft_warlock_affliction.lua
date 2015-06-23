local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_warlock_affliction_t18m"
	local desc = "[6.2] SimulationCraft: Warlock_Affliction_T18M"
	local code = [[
# Based on SimulationCraft profile "Warlock_Affliction_T18M".
#	class=warlock
#	spec=affliction
#	talents=0000311
#	pet=felhunter

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)

AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=affliction)

AddFunction AfflictionUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction AfflictionUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

### actions.default

AddFunction AfflictionDefaultMainActions
{
	#soul_swap,if=buff.soulburn.remains&!dot.agony.ticking&!dot.corruption.ticking&!dot.unstable_affliction.ticking&time<10&!talent.cataclysm.enabled
	if BuffPresent(soulburn_buff) and not target.DebuffPresent(agony_debuff) and not target.DebuffPresent(corruption_debuff) and not target.DebuffPresent(unstable_affliction_debuff) and TimeInCombat() < 10 and not Talent(cataclysm_talent) Spell(soul_swap)
	#life_tap,if=mana.pct<30&buff.dark_soul.down
	if ManaPercent() < 30 and BuffExpires(dark_soul_misery_buff) Spell(life_tap)
	#agony,cycle_targets=1,if=remains<=gcd
	if target.DebuffRemaining(agony_debuff) <= GCD() Spell(agony)
	#corruption,cycle_targets=1,if=remains<=gcd
	if target.DebuffRemaining(corruption_debuff) <= GCD() Spell(corruption)
	#unstable_affliction,cycle_targets=1,if=remains<=cast_time
	if target.DebuffRemaining(unstable_affliction_debuff) <= CastTime(unstable_affliction) Spell(unstable_affliction)
	#seed_of_corruption,cycle_targets=1,if=!talent.soulburn_haunt.enabled&spell_targets.seed_of_corruption_aoe>2&!dot.seed_of_corruption.remains&buff.soulburn.remains
	if not Talent(soulburn_haunt_talent) and Enemies() > 2 and not target.DebuffRemaining(seed_of_corruption_debuff) and BuffPresent(soulburn_buff) Spell(seed_of_corruption)
	#haunt,if=shard_react&!talent.soulburn_haunt.enabled&!in_flight_to_target&(dot.haunt.remains<duration*0.3+cast_time+travel_time|soul_shard=4)&(buff.nithramus.remains>cast_time+travel_time|trinket.proc.any.react|trinket.stacking_proc.any.react>6|buff.dark_soul.up|soul_shard>2|soul_shard*14<=target.time_to_die)&(buff.dark_soul.down|set_bonus.tier18_4pc=0)
	if SoulShards() >= 1 and not Talent(soulburn_haunt_talent) and not InFlightToTarget(haunt) and { target.DebuffRemaining(haunt_debuff) < BaseDuration(haunt_debuff) * 0.3 + CastTime(haunt) + TravelTime(haunt) or SoulShards() == 4 } and { BuffRemaining(nithramus_buff) > CastTime(haunt) + TravelTime(haunt) or BuffPresent(trinket_proc_any_buff) or BuffStacks(trinket_stacking_proc_any_buff) > 6 or BuffPresent(dark_soul_misery_buff) or SoulShards() > 2 or SoulShards() * 14 <= target.TimeToDie() } and { BuffExpires(dark_soul_misery_buff) or ArmorSetBonus(T18 4) == 0 } Spell(haunt)
	#haunt,cycle_targets=1,if=shard_react&!in_flight_to_target&buff.dark_soul.remains>cast_time+travel_time&!dot.haunt.ticking&set_bonus.tier18_4pc=1
	if SoulShards() >= 1 and not InFlightToTarget(haunt) and BuffRemaining(dark_soul_misery_buff) > CastTime(haunt) + TravelTime(haunt) and not target.DebuffPresent(haunt_debuff) and ArmorSetBonus(T18 4) == 1 Spell(haunt)
	#haunt,if=shard_react&talent.soulburn_haunt.enabled&!in_flight_to_target&((buff.soulburn.up&((buff.haunting_spirits.remains-cast_time<=buff.haunting_spirits.duration*0.3&(dot.haunt.remains-cast_time<=dot.haunt.duration*0.3|set_bonus.tier18_4pc=1&buff.dark_soul.remains))|buff.haunting_spirits.down)))
	if SoulShards() >= 1 and Talent(soulburn_haunt_talent) and not InFlightToTarget(haunt) and BuffPresent(soulburn_buff) and { BuffRemaining(haunting_spirits_buff) - CastTime(haunt) <= BaseDuration(haunting_spirits_buff) * 0.3 and { target.DebuffRemaining(haunt_debuff) - CastTime(haunt) <= target.DebuffDuration(haunt_debuff) * 0.3 or ArmorSetBonus(T18 4) == 1 and BuffPresent(dark_soul_misery_buff) } or BuffExpires(haunting_spirits_buff) } Spell(haunt)
	#haunt,if=shard_react&talent.soulburn_haunt.enabled&!in_flight_to_target&soul_shard>2&(dot.haunt.remains<duration*0.3+cast_time+travel_time|soul_shard=4)&(buff.nithramus.remains>cast_time+travel_time|trinket.proc.any.react|trinket.stacking_proc.any.react>6|buff.dark_soul.up|soul_shard>2|soul_shard*14<=target.time_to_die)&(buff.dark_soul.down|set_bonus.tier18_4pc=0)
	if SoulShards() >= 1 and Talent(soulburn_haunt_talent) and not InFlightToTarget(haunt) and SoulShards() > 2 and { target.DebuffRemaining(haunt_debuff) < BaseDuration(haunt_debuff) * 0.3 + CastTime(haunt) + TravelTime(haunt) or SoulShards() == 4 } and { BuffRemaining(nithramus_buff) > CastTime(haunt) + TravelTime(haunt) or BuffPresent(trinket_proc_any_buff) or BuffStacks(trinket_stacking_proc_any_buff) > 6 or BuffPresent(dark_soul_misery_buff) or SoulShards() > 2 or SoulShards() * 14 <= target.TimeToDie() } and { BuffExpires(dark_soul_misery_buff) or ArmorSetBonus(T18 4) == 0 } Spell(haunt)
	#agony,cycle_targets=1,if=target.time_to_die>16&remains<=(duration*0.3)&(buff.nithramus.remains>8|buff.nithramus.down)&((talent.cataclysm.enabled&remains<=(cooldown.cataclysm.remains+action.cataclysm.cast_time))|!talent.cataclysm.enabled)
	if target.TimeToDie() > 16 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0.3 and { BuffRemaining(nithramus_buff) > 8 or BuffExpires(nithramus_buff) } and { Talent(cataclysm_talent) and target.DebuffRemaining(agony_debuff) <= SpellCooldown(cataclysm) + CastTime(cataclysm) or not Talent(cataclysm_talent) } Spell(agony)
	#unstable_affliction,cycle_targets=1,if=target.time_to_die>10&remains-cast_time<=(duration*0.3)&(buff.nithramus.remains>5|buff.nithramus.down)&((talent.cataclysm.enabled&remains<=(cooldown.cataclysm.remains+action.cataclysm.cast_time))|!talent.cataclysm.enabled)
	if target.TimeToDie() > 10 and target.DebuffRemaining(unstable_affliction_debuff) - CastTime(unstable_affliction) <= BaseDuration(unstable_affliction_debuff) * 0.3 and { BuffRemaining(nithramus_buff) > 5 or BuffExpires(nithramus_buff) } and { Talent(cataclysm_talent) and target.DebuffRemaining(unstable_affliction_debuff) <= SpellCooldown(cataclysm) + CastTime(cataclysm) or not Talent(cataclysm_talent) } Spell(unstable_affliction)
	#seed_of_corruption,cycle_targets=1,if=!talent.soulburn_haunt.enabled&spell_targets.seed_of_corruption_aoe>3&!dot.seed_of_corruption.ticking
	if not Talent(soulburn_haunt_talent) and Enemies() > 3 and not target.DebuffPresent(seed_of_corruption_debuff) Spell(seed_of_corruption)
	#corruption,cycle_targets=1,if=target.time_to_die>12&remains<=(duration*0.3)&(buff.nithramus.remains>5|buff.nithramus.down)
	if target.TimeToDie() > 12 and target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) * 0.3 and { BuffRemaining(nithramus_buff) > 5 or BuffExpires(nithramus_buff) } Spell(corruption)
	#drain_soul,cycle_targets=1,interrupt=1,if=buff.dark_soul.remains&dot.haunt.ticking&dot.haunt.remains<=dot.haunt.duration*0.3&set_bonus.tier18_4pc=1
	if BuffPresent(dark_soul_misery_buff) and target.DebuffPresent(haunt_debuff) and target.DebuffRemaining(haunt_debuff) <= target.DebuffDuration(haunt_debuff) * 0.3 and ArmorSetBonus(T18 4) == 1 Spell(drain_soul)
	#life_tap,if=mana.pct<30&buff.dark_soul.down
	if ManaPercent() < 30 and BuffExpires(dark_soul_misery_buff) Spell(life_tap)
	#seed_of_corruption,cycle_targets=1,if=spell_targets.seed_of_corruption_aoe>3&!dot.seed_of_corruption.ticking
	if Enemies() > 3 and not target.DebuffPresent(seed_of_corruption_debuff) Spell(seed_of_corruption)
	#drain_soul,interrupt=1,chain=1
	Spell(drain_soul)
	#agony,cycle_targets=1,moving=1,if=mana.pct>50
	if Speed() > 0 and ManaPercent() > 50 Spell(agony)
	#life_tap
	Spell(life_tap)
}

AddFunction AfflictionDefaultShortCdActions
{
	#soulburn,if=!dot.agony.ticking&!dot.corruption.ticking&!dot.unstable_affliction.ticking&buff.soulburn.down&time<10&!talent.cataclysm.enabled
	if not target.DebuffPresent(agony_debuff) and not target.DebuffPresent(corruption_debuff) and not target.DebuffPresent(unstable_affliction_debuff) and BuffExpires(soulburn_buff) and TimeInCombat() < 10 and not Talent(cataclysm_talent) Spell(soulburn)

	unless BuffPresent(soulburn_buff) and not target.DebuffPresent(agony_debuff) and not target.DebuffPresent(corruption_debuff) and not target.DebuffPresent(unstable_affliction_debuff) and TimeInCombat() < 10 and not Talent(cataclysm_talent) and Spell(soul_swap)
	{
		#mannoroths_fury
		Spell(mannoroths_fury)
		#service_pet,if=talent.grimoire_of_service.enabled&(target.time_to_die>120|target.time_to_die<=25|(buff.dark_soul.remains&target.health.pct<20))
		if Talent(grimoire_of_service_talent) and { target.TimeToDie() > 120 or target.TimeToDie() <= 25 or BuffPresent(dark_soul_misery_buff) and target.HealthPercent() < 20 } Spell(service_felhunter)
		#kiljaedens_cunning,if=(talent.cataclysm.enabled&!cooldown.cataclysm.remains)
		if Talent(cataclysm_talent) and not SpellCooldown(cataclysm) > 0 Spell(kiljaedens_cunning)
		#kiljaedens_cunning,moving=1,if=!talent.cataclysm.enabled
		if Speed() > 0 and not Talent(cataclysm_talent) Spell(kiljaedens_cunning)
		#cataclysm
		Spell(cataclysm)

		unless ManaPercent() < 30 and BuffExpires(dark_soul_misery_buff) and Spell(life_tap) or target.DebuffRemaining(agony_debuff) <= GCD() and Spell(agony) or target.DebuffRemaining(corruption_debuff) <= GCD() and Spell(corruption) or target.DebuffRemaining(unstable_affliction_debuff) <= CastTime(unstable_affliction) and Spell(unstable_affliction)
		{
			#soulburn,cycle_targets=1,if=!talent.soulburn_haunt.enabled&spell_targets.seed_of_corruption_aoe>2&dot.corruption.remains<=dot.corruption.duration*0.3
			if not Talent(soulburn_haunt_talent) and Enemies() > 2 and target.DebuffRemaining(corruption_debuff) <= target.DebuffDuration(corruption_debuff) * 0.3 Spell(soulburn)

			unless not Talent(soulburn_haunt_talent) and Enemies() > 2 and not target.DebuffRemaining(seed_of_corruption_debuff) and BuffPresent(soulburn_buff) and Spell(seed_of_corruption)
			{
				#soulburn,if=shard_react&soul_shard>=2&talent.soulburn_haunt.enabled&buff.soulburn.down&(buff.haunting_spirits.remains-action.haunt.cast_time<=buff.haunting_spirits.duration*0.3)
				if SoulShards() >= 1 and SoulShards() >= 2 and Talent(soulburn_haunt_talent) and BuffExpires(soulburn_buff) and BuffRemaining(haunting_spirits_buff) - CastTime(haunt) <= BaseDuration(haunting_spirits_buff) * 0.3 Spell(soulburn)
			}
		}
	}
}

AddFunction AfflictionDefaultCdActions
{
	#summon_doomguard,if=!talent.demonic_servitude.enabled&spell_targets.infernal_awakening<9
	if not Talent(demonic_servitude_talent) and Enemies() < 9 Spell(summon_doomguard)
	#summon_infernal,if=!talent.demonic_servitude.enabled&spell_targets.infernal_awakening>=9
	if not Talent(demonic_servitude_talent) and Enemies() >= 9 Spell(summon_infernal)

	unless BuffPresent(soulburn_buff) and not target.DebuffPresent(agony_debuff) and not target.DebuffPresent(corruption_debuff) and not target.DebuffPresent(unstable_affliction_debuff) and TimeInCombat() < 10 and not Talent(cataclysm_talent) and Spell(soul_swap)
	{
		#potion,name=draenic_intellect,if=(target.health.pct<20&buff.nithramus.up)|target.time_to_die<=25
		if target.HealthPercent() < 20 and BuffPresent(nithramus_buff) or target.TimeToDie() <= 25 AfflictionUsePotionIntellect()
		#berserking,if=(target.time_to_die<action.berserking.cooldown&target.health.pct<20&buff.nithramus.up)|target.time_to_die<=10|buff.dark_soul.up&target.health.pct>20
		if target.TimeToDie() < SpellCooldown(berserking) and target.HealthPercent() < 20 and BuffPresent(nithramus_buff) or target.TimeToDie() <= 10 or BuffPresent(dark_soul_misery_buff) and target.HealthPercent() > 20 Spell(berserking)
		#blood_fury
		Spell(blood_fury_sp)
		#arcane_torrent
		Spell(arcane_torrent_mana)
		#use_item,name=nithramus_the_allseer,if=buff.dark_soul.up&(target.time_to_die.remains>120|target.health.pct<20)
		if BuffPresent(dark_soul_misery_buff) and { target.TimeToDie() > 120 or target.HealthPercent() < 20 } AfflictionUseItemActions()

		unless Talent(grimoire_of_service_talent) and { target.TimeToDie() > 120 or target.TimeToDie() <= 25 or BuffPresent(dark_soul_misery_buff) and target.HealthPercent() < 20 } and Spell(service_felhunter)
		{
			#dark_soul,if=!talent.archimondes_darkness.enabled|(talent.archimondes_darkness.enabled&(charges=2|buff.nithramus.remains>4|target.time_to_die<40|((trinket.proc.any.react|trinket.stacking_proc.any.react)&(!talent.grimoire_of_service.enabled|!talent.demonic_servitude.enabled|pet.service_doomguard.active|recharge_time<=cooldown.service_pet.remains))))
			if not Talent(archimondes_darkness_talent) or Talent(archimondes_darkness_talent) and { Charges(dark_soul_misery) == 2 or BuffRemaining(nithramus_buff) > 4 or target.TimeToDie() < 40 or { BuffPresent(trinket_proc_any_buff) or BuffPresent(trinket_stacking_proc_any_buff) } and { not Talent(grimoire_of_service_talent) or not Talent(demonic_servitude_talent) or SpellCooldown(service_doomguard) > 100 or SpellChargeCooldown(dark_soul_misery) <= SpellCooldown(service_pet) } } Spell(dark_soul_misery)
		}
	}
}

### actions.precombat

AddFunction AfflictionPrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=sleeper_sushi
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier_buff any=1) Spell(dark_intent)
	#snapshot_stats
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled&!talent.demonic_servitude.enabled
	if Talent(grimoire_of_sacrifice_talent) and not Talent(demonic_servitude_talent) and pet.Present() Spell(grimoire_of_sacrifice)
	#haunt
	Spell(haunt)
}

AddFunction AfflictionPrecombatShortCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent)
	{
		#summon_pet,if=!talent.demonic_servitude.enabled&(!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down)
		if not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() Spell(summon_felhunter)
		#soulburn,if=talent.soulburn_haunt.enabled
		if Talent(soulburn_haunt_talent) Spell(soulburn)
	}
}

AddFunction AfflictionPrecombatShortCdPostConditions
{
	not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or Spell(haunt)
}

AddFunction AfflictionPrecombatCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() and Spell(summon_felhunter)
	{
		#summon_doomguard,if=talent.demonic_servitude.enabled&active_enemies<9
		if Talent(demonic_servitude_talent) and Enemies() < 9 Spell(summon_doomguard)
		#summon_infernal,if=talent.demonic_servitude.enabled&active_enemies>=9
		if Talent(demonic_servitude_talent) and Enemies() >= 9 Spell(summon_infernal)
		#potion,name=draenic_intellect
		AfflictionUsePotionIntellect()
	}
}

AddFunction AfflictionPrecombatCdPostConditions
{
	not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() and Spell(summon_felhunter) or Spell(haunt)
}

### Affliction icons.

AddCheckBox(opt_warlock_affliction_aoe L(AOE) default specialization=affliction)

AddIcon checkbox=!opt_warlock_affliction_aoe enemies=1 help=shortcd specialization=affliction
{
	if not InCombat() AfflictionPrecombatShortCdActions()
	unless not InCombat() and AfflictionPrecombatShortCdPostConditions()
	{
		AfflictionDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_warlock_affliction_aoe help=shortcd specialization=affliction
{
	if not InCombat() AfflictionPrecombatShortCdActions()
	unless not InCombat() and AfflictionPrecombatShortCdPostConditions()
	{
		AfflictionDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=affliction
{
	if not InCombat() AfflictionPrecombatMainActions()
	AfflictionDefaultMainActions()
}

AddIcon checkbox=opt_warlock_affliction_aoe help=aoe specialization=affliction
{
	if not InCombat() AfflictionPrecombatMainActions()
	AfflictionDefaultMainActions()
}

AddIcon checkbox=!opt_warlock_affliction_aoe enemies=1 help=cd specialization=affliction
{
	if not InCombat() AfflictionPrecombatCdActions()
	unless not InCombat() and AfflictionPrecombatCdPostConditions()
	{
		AfflictionDefaultCdActions()
	}
}

AddIcon checkbox=opt_warlock_affliction_aoe help=cd specialization=affliction
{
	if not InCombat() AfflictionPrecombatCdActions()
	unless not InCombat() and AfflictionPrecombatCdPostConditions()
	{
		AfflictionDefaultCdActions()
	}
}

### Required symbols
# agony
# agony_debuff
# arcane_torrent_mana
# archimondes_darkness_talent
# berserking
# blood_fury_sp
# cataclysm
# cataclysm_talent
# corruption
# corruption_debuff
# dark_intent
# dark_soul_misery
# dark_soul_misery_buff
# demonic_servitude_talent
# draenic_intellect_potion
# drain_soul
# grimoire_of_sacrifice
# grimoire_of_sacrifice_buff
# grimoire_of_sacrifice_talent
# grimoire_of_service_talent
# haunt
# haunt_debuff
# haunting_spirits_buff
# kiljaedens_cunning
# life_tap
# mannoroths_fury
# nithramus_buff
# seed_of_corruption
# seed_of_corruption_debuff
# service_doomguard
# service_felhunter
# service_pet
# soul_swap
# soulburn
# soulburn_buff
# soulburn_haunt_talent
# summon_doomguard
# summon_felhunter
# summon_infernal
# unstable_affliction
# unstable_affliction_debuff
]]
	OvaleScripts:RegisterScript("WARLOCK", "affliction", name, desc, code, "script")
end
