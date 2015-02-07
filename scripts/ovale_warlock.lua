local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_warlock"
	local desc = "[6.0] Ovale: Rotations (Affliction, Demonology, Destruction)"
	local code = [[
# Warlock rotation functions based on SimulationCraft.

###
### Affliction
###
# Based on SimulationCraft profile "Warlock_Affliction_T17M".
#	class=warlock
#	spec=affliction
#	talents=0000111
#	pet=felhunter

AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=affliction)

AddFunction AfflictionUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

### actions.default

AddFunction AfflictionDefaultMainActions
{
	#life_tap,if=mana.pct<40
	if ManaPercent() < 40 Spell(life_tap)
	#haunt,if=shard_react&!talent.soulburn_haunt.enabled&!in_flight_to_target&(dot.haunt.remains<duration*0.3+cast_time+travel_time|soul_shard=4)&(trinket.proc.any.react|trinket.stacking_proc.any.react>6|buff.dark_soul.up|soul_shard>2|soul_shard*14<=target.time_to_die)
	if SoulShards() >= 1 and not Talent(soulburn_haunt_talent) and not InFlightToTarget(haunt) and { target.DebuffRemaining(haunt_debuff) < BaseDuration(haunt_debuff) * 0.3 + CastTime(haunt) + TravelTime(haunt) or SoulShards() == 4 } and { BuffPresent(trinket_proc_any_buff) or BuffStacks(trinket_stacking_proc_any_buff) > 6 or BuffPresent(dark_soul_misery_buff) or SoulShards() > 2 or SoulShards() * 14 <= target.TimeToDie() } Spell(haunt)
	#haunt,if=shard_react&talent.soulburn_haunt.enabled&!in_flight_to_target&((buff.soulburn.up&((buff.haunting_spirits.remains<=buff.haunting_spirits.duration*0.3&dot.haunt.remains<=dot.haunt.duration*0.3)|buff.haunting_spirits.down)))
	if SoulShards() >= 1 and Talent(soulburn_haunt_talent) and not InFlightToTarget(haunt) and BuffPresent(soulburn_buff) and { BuffRemaining(haunting_spirits_buff) <= BaseDuration(haunting_spirits_buff) * 0.3 and target.DebuffRemaining(haunt_debuff) <= target.DebuffDuration(haunt_debuff) * 0.3 or BuffExpires(haunting_spirits_buff) } Spell(haunt)
	#haunt,if=shard_react&talent.soulburn_haunt.enabled&!in_flight_to_target&buff.haunting_spirits.remains>=buff.haunting_spirits.duration*0.5&(dot.haunt.remains<duration*0.3+cast_time+travel_time|soul_shard=4)&(trinket.proc.any.react|trinket.stacking_proc.any.react>6|buff.dark_soul.up|soul_shard>2|soul_shard*14<=target.time_to_die)
	if SoulShards() >= 1 and Talent(soulburn_haunt_talent) and not InFlightToTarget(haunt) and BuffRemaining(haunting_spirits_buff) >= BaseDuration(haunting_spirits_buff) * 0.5 and { target.DebuffRemaining(haunt_debuff) < BaseDuration(haunt_debuff) * 0.3 + CastTime(haunt) + TravelTime(haunt) or SoulShards() == 4 } and { BuffPresent(trinket_proc_any_buff) or BuffStacks(trinket_stacking_proc_any_buff) > 6 or BuffPresent(dark_soul_misery_buff) or SoulShards() > 2 or SoulShards() * 14 <= target.TimeToDie() } Spell(haunt)
	#agony,cycle_targets=1,if=target.time_to_die>16&remains<=(duration*0.3)&((talent.cataclysm.enabled&remains<=(cooldown.cataclysm.remains+action.cataclysm.cast_time))|!talent.cataclysm.enabled)
	if target.TimeToDie() > 16 and target.DebuffRemaining(agony_debuff) <= BaseDuration(agony_debuff) * 0.3 and { Talent(cataclysm_talent) and target.DebuffRemaining(agony_debuff) <= SpellCooldown(cataclysm) + CastTime(cataclysm) or not Talent(cataclysm_talent) } Spell(agony)
	#unstable_affliction,cycle_targets=1,if=target.time_to_die>10&remains<=(duration*0.3)
	if target.TimeToDie() > 10 and target.DebuffRemaining(unstable_affliction_debuff) <= BaseDuration(unstable_affliction_debuff) * 0.3 Spell(unstable_affliction)
	#corruption,cycle_targets=1,if=target.time_to_die>12&remains<=(duration*0.3)
	if target.TimeToDie() > 12 and target.DebuffRemaining(corruption_debuff) <= BaseDuration(corruption_debuff) * 0.3 Spell(corruption)
	#life_tap,if=mana.pct<40&buff.dark_soul.down
	if ManaPercent() < 40 and BuffExpires(dark_soul_misery_buff) Spell(life_tap)
	#drain_soul,interrupt=1,chain=1
	Spell(drain_soul)
	#agony,cycle_targets=1,moving=1,if=mana.pct>50
	if Speed() > 0 and ManaPercent() > 50 Spell(agony)
	#life_tap
	Spell(life_tap)
}

AddFunction AfflictionDefaultShortCdActions
{
	#mannoroths_fury
	Spell(mannoroths_fury)
	#service_pet,if=talent.grimoire_of_service.enabled&(target.time_to_die>120|target.time_to_die<20|(buff.dark_soul.remains&target.health.pct<20))
	if Talent(grimoire_of_service_talent) and { target.TimeToDie() > 120 or target.TimeToDie() < 20 or BuffPresent(dark_soul_misery_buff) and target.HealthPercent() < 20 } Spell(grimoire_felhunter)
	#kiljaedens_cunning,if=(talent.cataclysm.enabled&!cooldown.cataclysm.remains)
	if Talent(cataclysm_talent) and not SpellCooldown(cataclysm) > 0 Spell(kiljaedens_cunning)
	#kiljaedens_cunning,moving=1,if=!talent.cataclysm.enabled
	if Speed() > 0 and not Talent(cataclysm_talent) Spell(kiljaedens_cunning)
	#cataclysm
	Spell(cataclysm)

	unless ManaPercent() < 40 and Spell(life_tap) or SoulShards() >= 1 and not Talent(soulburn_haunt_talent) and not InFlightToTarget(haunt) and { target.DebuffRemaining(haunt_debuff) < BaseDuration(haunt_debuff) * 0.3 + CastTime(haunt) + TravelTime(haunt) or SoulShards() == 4 } and { BuffPresent(trinket_proc_any_buff) or BuffStacks(trinket_stacking_proc_any_buff) > 6 or BuffPresent(dark_soul_misery_buff) or SoulShards() > 2 or SoulShards() * 14 <= target.TimeToDie() } and Spell(haunt)
	{
		#soulburn,if=shard_react&talent.soulburn_haunt.enabled&buff.soulburn.down&(buff.haunting_spirits.remains<=buff.haunting_spirits.duration*0.3)
		if SoulShards() >= 1 and Talent(soulburn_haunt_talent) and BuffExpires(soulburn_buff) and BuffRemaining(haunting_spirits_buff) <= BaseDuration(haunting_spirits_buff) * 0.3 Spell(soulburn)
	}
}

AddFunction AfflictionDefaultCdActions
{
	#potion,name=draenic_intellect,if=buff.bloodlust.react&buff.dark_soul.remains>10|target.time_to_die<=25|buff.dark_soul.remains>10
	if BuffPresent(burst_haste_buff any=1) and BuffRemaining(dark_soul_misery_buff) > 10 or target.TimeToDie() <= 25 or BuffRemaining(dark_soul_misery_buff) > 10 AfflictionUsePotionIntellect()
	#berserking
	Spell(berserking)
	#blood_fury
	Spell(blood_fury_sp)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#dark_soul,if=!talent.archimondes_darkness.enabled|(talent.archimondes_darkness.enabled&(charges=2|trinket.proc.any.react|trinket.stacking_any.intellect.react>6|target.time_to_die<40))
	if not Talent(archimondes_darkness_talent) or Talent(archimondes_darkness_talent) and { Charges(dark_soul_misery) == 2 or BuffPresent(trinket_proc_any_buff) or BuffStacks(trinket_stacking_any_intellect_buff) > 6 or target.TimeToDie() < 40 } Spell(dark_soul_misery)

	unless Talent(grimoire_of_service_talent) and { target.TimeToDie() > 120 or target.TimeToDie() < 20 or BuffPresent(dark_soul_misery_buff) and target.HealthPercent() < 20 } and Spell(grimoire_felhunter)
	{
		#summon_doomguard,if=!talent.demonic_servitude.enabled&active_enemies<5
		if not Talent(demonic_servitude_talent) and Enemies() < 5 Spell(summon_doomguard)
		#summon_infernal,if=!talent.demonic_servitude.enabled&active_enemies>=5
		if not Talent(demonic_servitude_talent) and Enemies() >= 5 Spell(summon_infernal)
	}
}

### actions.precombat

AddFunction AfflictionPrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=sleeper_surprise
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier_buff any=1) Spell(dark_intent)
	#snapshot_stats
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled&!talent.demonic_servitude.enabled
	if Talent(grimoire_of_sacrifice_talent) and not Talent(demonic_servitude_talent) and pet.Present() Spell(grimoire_of_sacrifice)
}

AddFunction AfflictionPrecombatShortCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent)
	{
		#summon_pet,if=!talent.demonic_servitude.enabled&(!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down)
		if not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() Spell(summon_felhunter)
		#service_pet,if=talent.grimoire_of_service.enabled
		if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)
	}
}

AddFunction AfflictionPrecombatShortCdPostConditions
{
	not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent)
}

AddFunction AfflictionPrecombatCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() and Spell(summon_felhunter)
	{
		#summon_doomguard,if=talent.demonic_servitude.enabled&active_enemies<5
		if Talent(demonic_servitude_talent) and Enemies() < 5 Spell(summon_doomguard)
		#summon_infernal,if=talent.demonic_servitude.enabled&active_enemies>=5
		if Talent(demonic_servitude_talent) and Enemies() >= 5 Spell(summon_infernal)

		unless Talent(grimoire_of_service_talent) and Spell(grimoire_felhunter)
		{
			#potion,name=draenic_intellect
			AfflictionUsePotionIntellect()
		}
	}
}

AddFunction AfflictionPrecombatCdPostConditions
{
	not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() and Spell(summon_felhunter) or Talent(grimoire_of_service_talent) and Spell(grimoire_felhunter)
}

###
### Demonology
###
# Based on SimulationCraft profile "Warlock_Demonology_T17M".
#	class=warlock
#	spec=demonology
#	talents=0000311
#	glyphs=dark_soul
#	pet=felguard

AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=demonology)

AddFunction DemonologyUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

### actions.default

AddFunction DemonologyDefaultMainActions
{
	#life_tap,if=buff.metamorphosis.down&mana.pct<40
	if BuffExpires(metamorphosis_buff) and ManaPercent() < 40 Spell(life_tap)
	#hand_of_guldan,if=!in_flight&dot.shadowflame.remains<travel_time+action.shadow_bolt.cast_time&(((set_bonus.tier17_4pc=0&((charges=1&recharge_time<4)|charges=2))|(charges=3|(charges=2&recharge_time<13.8-travel_time*2))&((cooldown.cataclysm.remains>dot.shadowflame.duration)|!talent.cataclysm.enabled))|dot.shadowflame.remains>travel_time)
	if not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and { ArmorSetBonus(T17 4) == 0 and { Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 or Charges(hand_of_guldan) == 2 } or { Charges(hand_of_guldan) == 3 or Charges(hand_of_guldan) == 2 and SpellChargeCooldown(hand_of_guldan) < 13.8 - TravelTime(hand_of_guldan) * 2 } and { SpellCooldown(cataclysm) > target.DebuffDuration(shadowflame_debuff) or not Talent(cataclysm_talent) } or target.DebuffRemaining(shadowflame_debuff) > TravelTime(hand_of_guldan) } Spell(hand_of_guldan)
	#hand_of_guldan,if=!in_flight&dot.shadowflame.remains<travel_time+action.shadow_bolt.cast_time&talent.demonbolt.enabled&((set_bonus.tier17_4pc=0&((charges=1&recharge_time<4)|charges=2))|(charges=3|(charges=2&recharge_time<13.8-travel_time*2))|dot.shadowflame.remains>travel_time)
	if not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and Talent(demonbolt_talent) and { ArmorSetBonus(T17 4) == 0 and { Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 or Charges(hand_of_guldan) == 2 } or Charges(hand_of_guldan) == 3 or Charges(hand_of_guldan) == 2 and SpellChargeCooldown(hand_of_guldan) < 13.8 - TravelTime(hand_of_guldan) * 2 or target.DebuffRemaining(shadowflame_debuff) > TravelTime(hand_of_guldan) } Spell(hand_of_guldan)
	#hand_of_guldan,if=!in_flight&dot.shadowflame.remains<3.7&time<5&buff.demonbolt.remains<gcd*2&(charges>=2|set_bonus.tier17_4pc=0)&action.dark_soul.charges>=1
	if not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < 3.7 and TimeInCombat() < 5 and BuffRemaining(demonbolt_buff) < GCD() * 2 and { Charges(hand_of_guldan) >= 2 or ArmorSetBonus(T17 4) == 0 } and Charges(dark_soul_knowledge) >= 1 Spell(hand_of_guldan)
	#call_action_list,name=db,if=talent.demonbolt.enabled
	if Talent(demonbolt_talent) DemonologyDbMainActions()
	#immolation_aura,if=demonic_fury>450&active_enemies>=3&buff.immolation_aura.down
	if DemonicFury() > 450 and Enemies() >= 3 and BuffExpires(immolation_aura_buff) Spell(immolation_aura)
	#doom,if=buff.metamorphosis.up&target.time_to_die>=30*spell_haste&remains<=(duration*0.3)&(remains<cooldown.cataclysm.remains|!talent.cataclysm.enabled)&(buff.dark_soul.down|!glyph.dark_soul.enabled)&trinket.stacking_proc.multistrike.react<10
	if BuffPresent(metamorphosis_buff) and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { target.DebuffRemaining(doom_debuff) < SpellCooldown(cataclysm) or not Talent(cataclysm_talent) } and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } and BuffStacks(trinket_stacking_proc_multistrike_buff) < 10 Spell(doom)
	#corruption,cycle_targets=1,if=target.time_to_die>=6&remains<=(0.3*duration)&buff.metamorphosis.down
	if target.TimeToDie() >= 6 and target.DebuffRemaining(corruption_debuff) <= 0.3 * BaseDuration(corruption_debuff) and BuffExpires(metamorphosis_buff) Spell(corruption)
	#cancel_metamorphosis,if=buff.metamorphosis.up&((demonic_fury<650&!glyph.dark_soul.enabled)|demonic_fury<450)&buff.dark_soul.down&(trinket.stacking_proc.multistrike.down&trinket.proc.any.down|demonic_fury<(800-cooldown.dark_soul.remains*(10%spell_haste)))&target.time_to_die>20
	if BuffPresent(metamorphosis_buff) and { DemonicFury() < 650 and not Glyph(glyph_of_dark_soul) or DemonicFury() < 450 } and BuffExpires(dark_soul_knowledge_buff) and { BuffExpires(trinket_stacking_proc_multistrike_buff) and BuffExpires(trinket_proc_any_buff) or DemonicFury() < 800 - SpellCooldown(dark_soul_knowledge) * { 10 / { 100 / { 100 + SpellHaste() } } } } and target.TimeToDie() > 20 and BuffPresent(metamorphosis_buff) Spell(metamorphosis text=cancel)
	#cancel_metamorphosis,if=buff.metamorphosis.up&action.hand_of_guldan.charges>0&dot.shadowflame.remains<action.hand_of_guldan.travel_time+action.shadow_bolt.cast_time&demonic_fury<100&buff.dark_soul.remains>10
	if BuffPresent(metamorphosis_buff) and Charges(hand_of_guldan) > 0 and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and DemonicFury() < 100 and BuffRemaining(dark_soul_knowledge_buff) > 10 and BuffPresent(metamorphosis_buff) Spell(metamorphosis text=cancel)
	#cancel_metamorphosis,if=buff.metamorphosis.up&action.hand_of_guldan.charges=3&(!buff.dark_soul.remains>gcd|action.metamorphosis.cooldown<gcd)
	if BuffPresent(metamorphosis_buff) and Charges(hand_of_guldan) == 3 and { not BuffRemaining(dark_soul_knowledge_buff) > GCD() or SpellCooldown(metamorphosis) < GCD() } and BuffPresent(metamorphosis_buff) Spell(metamorphosis text=cancel)
	#chaos_wave,if=buff.metamorphosis.up&(buff.dark_soul.up&active_enemies>=2|(charges=3|set_bonus.tier17_4pc=0&charges=2))
	if BuffPresent(metamorphosis_buff) and { BuffPresent(dark_soul_knowledge_buff) and Enemies() >= 2 or Charges(chaos_wave) == 3 or ArmorSetBonus(T17 4) == 0 and Charges(chaos_wave) == 2 } Spell(chaos_wave)
	#soul_fire,if=buff.metamorphosis.up&buff.molten_core.react&(buff.dark_soul.remains>execute_time|target.health.pct<=25)&(((buff.molten_core.stack*execute_time>=trinket.stacking_proc.multistrike.remains-1|demonic_fury<=ceil((trinket.stacking_proc.multistrike.remains-buff.molten_core.stack*execute_time)*40)+80*buff.molten_core.stack)|target.health.pct<=25)&trinket.stacking_proc.multistrike.remains>=execute_time|trinket.stacking_proc.multistrike.down|!trinket.has_stacking_proc.multistrike)
	if BuffPresent(metamorphosis_buff) and BuffPresent(molten_core_buff any=1) and { BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(soul_fire) or target.HealthPercent() <= 25 } and { { BuffStacks(molten_core_buff any=1) * ExecuteTime(soul_fire) >= BuffRemaining(trinket_stacking_proc_multistrike_buff) - 1 or DemonicFury() <= { BuffRemaining(trinket_stacking_proc_multistrike_buff) - BuffStacks(molten_core_buff any=1) * ExecuteTime(soul_fire) } * 40 + 80 * BuffStacks(molten_core_buff any=1) or target.HealthPercent() <= 25 } and BuffRemaining(trinket_stacking_proc_multistrike_buff) >= ExecuteTime(soul_fire) or BuffExpires(trinket_stacking_proc_multistrike_buff) or not True(trinket_has_stacking_proc_multistrike) } Spell(soul_fire)
	#touch_of_chaos,cycle_targets=1,if=buff.metamorphosis.up&dot.corruption.remains<17.4&demonic_fury>750
	if BuffPresent(metamorphosis_buff) and target.DebuffRemaining(corruption_debuff) < 17.4 and DemonicFury() > 750 Spell(touch_of_chaos)
	#touch_of_chaos,if=buff.metamorphosis.up
	if BuffPresent(metamorphosis_buff) Spell(touch_of_chaos)
	#metamorphosis,if=buff.dark_soul.remains>gcd&(demonic_fury>300|!glyph.dark_soul.enabled)&(demonic_fury>=80&buff.molten_core.stack>=1|demonic_fury>=40)
	if BuffRemaining(dark_soul_knowledge_buff) > GCD() and { DemonicFury() > 300 or not Glyph(glyph_of_dark_soul) } and { DemonicFury() >= 80 and BuffStacks(molten_core_buff any=1) >= 1 or DemonicFury() >= 40 } Spell(metamorphosis)
	#metamorphosis,if=(trinket.stacking_proc.multistrike.react|trinket.proc.any.react)&((demonic_fury>450&action.dark_soul.recharge_time>=10&glyph.dark_soul.enabled)|(demonic_fury>650&cooldown.dark_soul.remains>=10))
	if { BuffPresent(trinket_stacking_proc_multistrike_buff) or BuffPresent(trinket_proc_any_buff) } and { DemonicFury() > 450 and SpellChargeCooldown(dark_soul_knowledge) >= 10 and Glyph(glyph_of_dark_soul) or DemonicFury() > 650 and SpellCooldown(dark_soul_knowledge) >= 10 } Spell(metamorphosis)
	#metamorphosis,if=!cooldown.cataclysm.remains&talent.cataclysm.enabled
	if not SpellCooldown(cataclysm) > 0 and Talent(cataclysm_talent) Spell(metamorphosis)
	#metamorphosis,if=!dot.doom.ticking&target.time_to_die>=30%(1%spell_haste)&demonic_fury>300
	if not target.DebuffPresent(doom_debuff) and target.TimeToDie() >= 30 / { 1 / { 100 / { 100 + SpellHaste() } } } and DemonicFury() > 300 Spell(metamorphosis)
	#metamorphosis,if=(demonic_fury>750&(action.hand_of_guldan.charges=0|(!dot.shadowflame.ticking&!action.hand_of_guldan.in_flight_to_target)))|floor(demonic_fury%80)*action.soul_fire.execute_time>=target.time_to_die
	if DemonicFury() > 750 and { Charges(hand_of_guldan) == 0 or not target.DebuffPresent(shadowflame_debuff) and not InFlightToTarget(hand_of_guldan) } or DemonicFury() / 80 * ExecuteTime(soul_fire) >= target.TimeToDie() Spell(metamorphosis)
	#metamorphosis,if=demonic_fury>=950
	if DemonicFury() >= 950 Spell(metamorphosis)
	#cancel_metamorphosis
	if BuffPresent(metamorphosis_buff) Spell(metamorphosis text=cancel)
	#hellfire,interrupt=1,if=active_enemies>=5
	if Enemies() >= 5 Spell(hellfire)
	#soul_fire,if=buff.molten_core.react&(buff.molten_core.stack>=7|target.health.pct<=25|(buff.dark_soul.remains&cooldown.metamorphosis.remains>buff.dark_soul.remains)|trinket.proc.any.remains>execute_time|trinket.stacking_proc.multistrike.remains>execute_time)&(buff.dark_soul.remains<action.shadow_bolt.cast_time|buff.dark_soul.remains>execute_time)
	if BuffPresent(molten_core_buff any=1) and { BuffStacks(molten_core_buff any=1) >= 7 or target.HealthPercent() <= 25 or BuffPresent(dark_soul_knowledge_buff) and SpellCooldown(metamorphosis) > BuffRemaining(dark_soul_knowledge_buff) or BuffRemaining(trinket_proc_any_buff) > ExecuteTime(soul_fire) or BuffRemaining(trinket_stacking_proc_multistrike_buff) > ExecuteTime(soul_fire) } and { BuffRemaining(dark_soul_knowledge_buff) < CastTime(shadow_bolt) or BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(soul_fire) } Spell(soul_fire)
	#soul_fire,if=buff.molten_core.react&target.time_to_die<(time+target.time_to_die)*0.25+cooldown.dark_soul.remains
	if BuffPresent(molten_core_buff any=1) and target.TimeToDie() < { TimeInCombat() + target.TimeToDie() } * 0.25 + SpellCooldown(dark_soul_knowledge) Spell(soul_fire)
	#life_tap,if=mana.pct<40&buff.dark_soul.down
	if ManaPercent() < 40 and BuffExpires(dark_soul_knowledge_buff) Spell(life_tap)
	#hellfire,interrupt=1,if=active_enemies>=4
	if Enemies() >= 4 Spell(hellfire)
	#shadow_bolt
	Spell(shadow_bolt)
	#hellfire,moving=1,interrupt=1
	if Speed() > 0 Spell(hellfire)
	#life_tap
	Spell(life_tap)
}

AddFunction DemonologyDefaultShortCdActions
{
	#mannoroths_fury
	Spell(mannoroths_fury)
	#felguard:felstorm
	if pet.Present() and pet.CreatureFamily(Felguard) Spell(felguard_felstorm)
	#wrathguard:wrathstorm
	if pet.Present() and pet.CreatureFamily(Wrathguard) Spell(wrathguard_wrathstorm)
	#wrathguard:mortal_cleave,if=pet.wrathguard.cooldown.wrathstorm.remains>5
	if SpellCooldown(wrathguard_wrathstorm) > 5 Spell(wrathguard_mortal_cleave)

	unless BuffExpires(metamorphosis_buff) and ManaPercent() < 40 and Spell(life_tap) or not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and { ArmorSetBonus(T17 4) == 0 and { Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 or Charges(hand_of_guldan) == 2 } or { Charges(hand_of_guldan) == 3 or Charges(hand_of_guldan) == 2 and SpellChargeCooldown(hand_of_guldan) < 13.8 - TravelTime(hand_of_guldan) * 2 } and { SpellCooldown(cataclysm) > target.DebuffDuration(shadowflame_debuff) or not Talent(cataclysm_talent) } or target.DebuffRemaining(shadowflame_debuff) > TravelTime(hand_of_guldan) } and Spell(hand_of_guldan) or not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and Talent(demonbolt_talent) and { ArmorSetBonus(T17 4) == 0 and { Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 or Charges(hand_of_guldan) == 2 } or Charges(hand_of_guldan) == 3 or Charges(hand_of_guldan) == 2 and SpellChargeCooldown(hand_of_guldan) < 13.8 - TravelTime(hand_of_guldan) * 2 or target.DebuffRemaining(shadowflame_debuff) > TravelTime(hand_of_guldan) } and Spell(hand_of_guldan) or not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < 3.7 and TimeInCombat() < 5 and BuffRemaining(demonbolt_buff) < GCD() * 2 and { Charges(hand_of_guldan) >= 2 or ArmorSetBonus(T17 4) == 0 } and Charges(dark_soul_knowledge) >= 1 and Spell(hand_of_guldan)
	{
		#service_pet,if=talent.grimoire_of_service.enabled&(target.time_to_die>120|target.time_to_die<20|(buff.dark_soul.remains&target.health.pct<20))
		if Talent(grimoire_of_service_talent) and { target.TimeToDie() > 120 or target.TimeToDie() < 20 or BuffPresent(dark_soul_knowledge_buff) and target.HealthPercent() < 20 } Spell(grimoire_felguard)
		#call_action_list,name=db,if=talent.demonbolt.enabled
		if Talent(demonbolt_talent) DemonologyDbShortCdActions()

		unless Talent(demonbolt_talent) and DemonologyDbShortCdPostConditions()
		{
			#kiljaedens_cunning,if=!cooldown.cataclysm.remains&buff.metamorphosis.up
			if not SpellCooldown(cataclysm) > 0 and BuffPresent(metamorphosis_buff) Spell(kiljaedens_cunning)
			#cataclysm,if=buff.metamorphosis.up
			if BuffPresent(metamorphosis_buff) Spell(cataclysm)
		}
	}
}

AddFunction DemonologyDefaultCdActions
{
	#potion,name=draenic_intellect,if=buff.bloodlust.react|(buff.dark_soul.up&(trinket.proc.any.react|trinket.stacking_proc.any.react>6)&!buff.demonbolt.remains)|target.health.pct<20
	if BuffPresent(burst_haste_buff any=1) or BuffPresent(dark_soul_knowledge_buff) and { BuffPresent(trinket_proc_any_buff) or BuffStacks(trinket_stacking_proc_any_buff) > 6 } and not BuffPresent(demonbolt_buff) or target.HealthPercent() < 20 DemonologyUsePotionIntellect()
	#berserking
	Spell(berserking)
	#blood_fury
	Spell(blood_fury_sp)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#dark_soul,if=talent.demonbolt.enabled&((charges=2&((!glyph.imp_swarm.enabled&(dot.corruption.ticking|trinket.proc.haste.remains<=10))|cooldown.imp_swarm.remains))|target.time_to_die<buff.demonbolt.remains|(!buff.demonbolt.remains&demonic_fury>=790))
	if Talent(demonbolt_talent) and { Charges(dark_soul_knowledge) == 2 and { not Glyph(glyph_of_imp_swarm) and { target.DebuffPresent(corruption_debuff) or BuffRemaining(trinket_proc_haste_buff) <= 10 } or SpellCooldown(imp_swarm) > 0 } or target.TimeToDie() < BuffRemaining(demonbolt_buff) or not BuffPresent(demonbolt_buff) and DemonicFury() >= 790 } Spell(dark_soul_knowledge)
	#dark_soul,if=!talent.demonbolt.enabled&(charges=2|!talent.archimondes_darkness.enabled|(target.time_to_die<=20&!glyph.dark_soul.enabled|target.time_to_die<=10)|(target.time_to_die<=60&demonic_fury>400)|((trinket.stacking_proc.multistrike.remains>7.5|trinket.proc.any.remains>7.5)&demonic_fury>=400))
	if not Talent(demonbolt_talent) and { Charges(dark_soul_knowledge) == 2 or not Talent(archimondes_darkness_talent) or target.TimeToDie() <= 20 and not Glyph(glyph_of_dark_soul) or target.TimeToDie() <= 10 or target.TimeToDie() <= 60 and DemonicFury() > 400 or { BuffRemaining(trinket_stacking_proc_multistrike_buff) > 7.5 or BuffRemaining(trinket_proc_any_buff) > 7.5 } and DemonicFury() >= 400 } Spell(dark_soul_knowledge)
	#imp_swarm,if=!talent.demonbolt.enabled&(buff.dark_soul.up|(cooldown.dark_soul.remains>(120%(1%spell_haste)))|time_to_die<32)&time>3
	if not Talent(demonbolt_talent) and { BuffPresent(dark_soul_knowledge_buff) or SpellCooldown(dark_soul_knowledge) > 120 / { 1 / { 100 / { 100 + SpellHaste() } } } or target.TimeToDie() < 32 } and TimeInCombat() > 3 Spell(imp_swarm)

	unless BuffExpires(metamorphosis_buff) and ManaPercent() < 40 and Spell(life_tap) or not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and { ArmorSetBonus(T17 4) == 0 and { Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 or Charges(hand_of_guldan) == 2 } or { Charges(hand_of_guldan) == 3 or Charges(hand_of_guldan) == 2 and SpellChargeCooldown(hand_of_guldan) < 13.8 - TravelTime(hand_of_guldan) * 2 } and { SpellCooldown(cataclysm) > target.DebuffDuration(shadowflame_debuff) or not Talent(cataclysm_talent) } or target.DebuffRemaining(shadowflame_debuff) > TravelTime(hand_of_guldan) } and Spell(hand_of_guldan) or not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and Talent(demonbolt_talent) and { ArmorSetBonus(T17 4) == 0 and { Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 or Charges(hand_of_guldan) == 2 } or Charges(hand_of_guldan) == 3 or Charges(hand_of_guldan) == 2 and SpellChargeCooldown(hand_of_guldan) < 13.8 - TravelTime(hand_of_guldan) * 2 or target.DebuffRemaining(shadowflame_debuff) > TravelTime(hand_of_guldan) } and Spell(hand_of_guldan) or not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < 3.7 and TimeInCombat() < 5 and BuffRemaining(demonbolt_buff) < GCD() * 2 and { Charges(hand_of_guldan) >= 2 or ArmorSetBonus(T17 4) == 0 } and Charges(dark_soul_knowledge) >= 1 and Spell(hand_of_guldan) or Talent(grimoire_of_service_talent) and { target.TimeToDie() > 120 or target.TimeToDie() < 20 or BuffPresent(dark_soul_knowledge_buff) and target.HealthPercent() < 20 } and Spell(grimoire_felguard)
	{
		#summon_doomguard,if=!talent.demonic_servitude.enabled&active_enemies<5
		if not Talent(demonic_servitude_talent) and Enemies() < 5 Spell(summon_doomguard)
		#summon_infernal,if=!talent.demonic_servitude.enabled&active_enemies>=5
		if not Talent(demonic_servitude_talent) and Enemies() >= 5 Spell(summon_infernal)
		#call_action_list,name=db,if=talent.demonbolt.enabled
		if Talent(demonbolt_talent) DemonologyDbCdActions()

		unless Talent(demonbolt_talent) and DemonologyDbCdPostConditions() or DemonicFury() > 450 and Enemies() >= 3 and BuffExpires(immolation_aura_buff) and Spell(immolation_aura) or BuffPresent(metamorphosis_buff) and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { target.DebuffRemaining(doom_debuff) < SpellCooldown(cataclysm) or not Talent(cataclysm_talent) } and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } and BuffStacks(trinket_stacking_proc_multistrike_buff) < 10 and Spell(doom) or target.TimeToDie() >= 6 and target.DebuffRemaining(corruption_debuff) <= 0.3 * BaseDuration(corruption_debuff) and BuffExpires(metamorphosis_buff) and Spell(corruption) or BuffPresent(metamorphosis_buff) and { BuffPresent(dark_soul_knowledge_buff) and Enemies() >= 2 or Charges(chaos_wave) == 3 or ArmorSetBonus(T17 4) == 0 and Charges(chaos_wave) == 2 } and Spell(chaos_wave) or BuffPresent(metamorphosis_buff) and BuffPresent(molten_core_buff any=1) and { BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(soul_fire) or target.HealthPercent() <= 25 } and { { BuffStacks(molten_core_buff any=1) * ExecuteTime(soul_fire) >= BuffRemaining(trinket_stacking_proc_multistrike_buff) - 1 or DemonicFury() <= { BuffRemaining(trinket_stacking_proc_multistrike_buff) - BuffStacks(molten_core_buff any=1) * ExecuteTime(soul_fire) } * 40 + 80 * BuffStacks(molten_core_buff any=1) or target.HealthPercent() <= 25 } and BuffRemaining(trinket_stacking_proc_multistrike_buff) >= ExecuteTime(soul_fire) or BuffExpires(trinket_stacking_proc_multistrike_buff) or not True(trinket_has_stacking_proc_multistrike) } and Spell(soul_fire) or BuffPresent(metamorphosis_buff) and target.DebuffRemaining(corruption_debuff) < 17.4 and DemonicFury() > 750 and Spell(touch_of_chaos) or BuffPresent(metamorphosis_buff) and Spell(touch_of_chaos)
		{
			#imp_swarm
			Spell(imp_swarm)
		}
	}
}

### actions.db

AddFunction DemonologyDbMainActions
{
	#immolation_aura,if=demonic_fury>450&active_enemies>=5&buff.immolation_aura.down
	if DemonicFury() > 450 and Enemies() >= 5 and BuffExpires(immolation_aura_buff) Spell(immolation_aura)
	#doom,cycle_targets=1,if=buff.metamorphosis.up&active_enemies>=6&target.time_to_die>=30*spell_haste&remains<=(duration*0.3)&(buff.dark_soul.down|!glyph.dark_soul.enabled)
	if BuffPresent(metamorphosis_buff) and Enemies() >= 6 and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } Spell(doom)
	#demonbolt,if=buff.demonbolt.stack=0|(buff.demonbolt.stack<4&buff.demonbolt.remains>=(40*spell_haste-execute_time))
	if BuffStacks(demonbolt_buff) == 0 or BuffStacks(demonbolt_buff) < 4 and BuffRemaining(demonbolt_buff) >= 40 * { 100 / { 100 + SpellHaste() } } - ExecuteTime(demonbolt) Spell(demonbolt)
	#doom,cycle_targets=1,if=buff.metamorphosis.up&target.time_to_die>=30*spell_haste&remains<=(duration*0.3)&(buff.dark_soul.down|!glyph.dark_soul.enabled)
	if BuffPresent(metamorphosis_buff) and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } Spell(doom)
	#corruption,cycle_targets=1,if=target.time_to_die>=6&remains<=(0.3*duration)&buff.metamorphosis.down
	if target.TimeToDie() >= 6 and target.DebuffRemaining(corruption_debuff) <= 0.3 * BaseDuration(corruption_debuff) and BuffExpires(metamorphosis_buff) Spell(corruption)
	#cancel_metamorphosis,if=buff.metamorphosis.up&buff.demonbolt.stack>3&demonic_fury<=600&target.time_to_die>buff.demonbolt.remains&buff.dark_soul.down
	if BuffPresent(metamorphosis_buff) and BuffStacks(demonbolt_buff) > 3 and DemonicFury() <= 600 and target.TimeToDie() > BuffRemaining(demonbolt_buff) and BuffExpires(dark_soul_knowledge_buff) and BuffPresent(metamorphosis_buff) Spell(metamorphosis text=cancel)
	#chaos_wave,if=buff.metamorphosis.up&buff.dark_soul.up&active_enemies>=2&demonic_fury>450
	if BuffPresent(metamorphosis_buff) and BuffPresent(dark_soul_knowledge_buff) and Enemies() >= 2 and DemonicFury() > 450 Spell(chaos_wave)
	#soul_fire,if=buff.metamorphosis.up&buff.molten_core.react&(((buff.dark_soul.remains>execute_time)&demonic_fury>=175)|(target.time_to_die<buff.demonbolt.remains))
	if BuffPresent(metamorphosis_buff) and BuffPresent(molten_core_buff any=1) and { BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(soul_fire) and DemonicFury() >= 175 or target.TimeToDie() < BuffRemaining(demonbolt_buff) } Spell(soul_fire)
	#soul_fire,if=buff.metamorphosis.up&buff.molten_core.react&target.health.pct<=25&(((demonic_fury-80)%800)>(buff.demonbolt.remains%(40*spell_haste)))&demonic_fury>=750
	if BuffPresent(metamorphosis_buff) and BuffPresent(molten_core_buff any=1) and target.HealthPercent() <= 25 and { DemonicFury() - 80 } / 800 > BuffRemaining(demonbolt_buff) / { 40 * { 100 / { 100 + SpellHaste() } } } and DemonicFury() >= 750 Spell(soul_fire)
	#touch_of_chaos,cycle_targets=1,if=buff.metamorphosis.up&dot.corruption.remains<17.4&demonic_fury>750
	if BuffPresent(metamorphosis_buff) and target.DebuffRemaining(corruption_debuff) < 17.4 and DemonicFury() > 750 Spell(touch_of_chaos)
	#touch_of_chaos,if=buff.metamorphosis.up&(target.time_to_die<buff.demonbolt.remains|(demonic_fury>=750&buff.demonbolt.remains)|buff.dark_soul.up)
	if BuffPresent(metamorphosis_buff) and { target.TimeToDie() < BuffRemaining(demonbolt_buff) or DemonicFury() >= 750 and BuffPresent(demonbolt_buff) or BuffPresent(dark_soul_knowledge_buff) } Spell(touch_of_chaos)
	#touch_of_chaos,if=buff.metamorphosis.up&(((demonic_fury-40)%800)>(buff.demonbolt.remains%(40*spell_haste)))&demonic_fury>=750
	if BuffPresent(metamorphosis_buff) and { DemonicFury() - 40 } / 800 > BuffRemaining(demonbolt_buff) / { 40 * { 100 / { 100 + SpellHaste() } } } and DemonicFury() >= 750 Spell(touch_of_chaos)
	#metamorphosis,if=buff.dark_soul.remains>gcd&(demonic_fury>=470|buff.dark_soul.remains<=action.demonbolt.execute_time*3)&(buff.demonbolt.down|target.time_to_die<buff.demonbolt.remains|(buff.dark_soul.remains>execute_time&demonic_fury>=175))
	if BuffRemaining(dark_soul_knowledge_buff) > GCD() and { DemonicFury() >= 470 or BuffRemaining(dark_soul_knowledge_buff) <= ExecuteTime(demonbolt) * 3 } and { BuffExpires(demonbolt_buff) or target.TimeToDie() < BuffRemaining(demonbolt_buff) or BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(metamorphosis) and DemonicFury() >= 175 } Spell(metamorphosis)
	#metamorphosis,if=buff.demonbolt.down&demonic_fury>=480&(action.dark_soul.charges=0|!talent.archimondes_darkness.enabled&cooldown.dark_soul.remains)
	if BuffExpires(demonbolt_buff) and DemonicFury() >= 480 and { Charges(dark_soul_knowledge) == 0 or not Talent(archimondes_darkness_talent) and SpellCooldown(dark_soul_knowledge) > 0 } Spell(metamorphosis)
	#metamorphosis,if=(demonic_fury%80)*2*spell_haste>=target.time_to_die&target.time_to_die<buff.demonbolt.remains
	if DemonicFury() / 80 * 2 * { 100 / { 100 + SpellHaste() } } >= target.TimeToDie() and target.TimeToDie() < BuffRemaining(demonbolt_buff) Spell(metamorphosis)
	#metamorphosis,if=target.time_to_die>=30*spell_haste&!dot.doom.ticking&buff.dark_soul.down&time>10
	if target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and not target.DebuffPresent(doom_debuff) and BuffExpires(dark_soul_knowledge_buff) and TimeInCombat() > 10 Spell(metamorphosis)
	#metamorphosis,if=demonic_fury>750&buff.demonbolt.remains>=action.metamorphosis.cooldown
	if DemonicFury() > 750 and BuffRemaining(demonbolt_buff) >= SpellCooldown(metamorphosis) Spell(metamorphosis)
	#metamorphosis,if=(((demonic_fury-120)%800)>(buff.demonbolt.remains%(40*spell_haste)))&buff.demonbolt.remains>=10&dot.doom.remains<=dot.doom.duration*0.3
	if { DemonicFury() - 120 } / 800 > BuffRemaining(demonbolt_buff) / { 40 * { 100 / { 100 + SpellHaste() } } } and BuffRemaining(demonbolt_buff) >= 10 and target.DebuffRemaining(doom_debuff) <= target.DebuffDuration(doom_debuff) * 0.3 Spell(metamorphosis)
	#cancel_metamorphosis
	if BuffPresent(metamorphosis_buff) Spell(metamorphosis text=cancel)
	#hellfire,interrupt=1,if=active_enemies>=5
	if Enemies() >= 5 Spell(hellfire)
	#soul_fire,if=buff.molten_core.react&(buff.dark_soul.remains<action.shadow_bolt.cast_time|buff.dark_soul.remains>cast_time)
	if BuffPresent(molten_core_buff any=1) and { BuffRemaining(dark_soul_knowledge_buff) < CastTime(shadow_bolt) or BuffRemaining(dark_soul_knowledge_buff) > CastTime(soul_fire) } Spell(soul_fire)
	#life_tap,if=mana.pct<40&buff.dark_soul.down
	if ManaPercent() < 40 and BuffExpires(dark_soul_knowledge_buff) Spell(life_tap)
	#hellfire,interrupt=1,if=active_enemies>=4
	if Enemies() >= 4 Spell(hellfire)
	#shadow_bolt
	Spell(shadow_bolt)
	#hellfire,moving=1,interrupt=1
	if Speed() > 0 Spell(hellfire)
	#life_tap
	Spell(life_tap)
}

AddFunction DemonologyDbShortCdActions
{
	unless DemonicFury() > 450 and Enemies() >= 5 and BuffExpires(immolation_aura_buff) and Spell(immolation_aura) or BuffPresent(metamorphosis_buff) and Enemies() >= 6 and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } and Spell(doom)
	{
		#kiljaedens_cunning,moving=1,if=buff.demonbolt.stack=0|(buff.demonbolt.stack<4&buff.demonbolt.remains>=(40*spell_haste-execute_time))
		if Speed() > 0 and { BuffStacks(demonbolt_buff) == 0 or BuffStacks(demonbolt_buff) < 4 and BuffRemaining(demonbolt_buff) >= 40 * { 100 / { 100 + SpellHaste() } } - ExecuteTime(kiljaedens_cunning) } Spell(kiljaedens_cunning)
	}
}

AddFunction DemonologyDbShortCdPostConditions
{
	DemonicFury() > 450 and Enemies() >= 5 and BuffExpires(immolation_aura_buff) and Spell(immolation_aura) or BuffPresent(metamorphosis_buff) and Enemies() >= 6 and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } and Spell(doom) or { BuffStacks(demonbolt_buff) == 0 or BuffStacks(demonbolt_buff) < 4 and BuffRemaining(demonbolt_buff) >= 40 * { 100 / { 100 + SpellHaste() } } - ExecuteTime(demonbolt) } and Spell(demonbolt) or BuffPresent(metamorphosis_buff) and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } and Spell(doom) or target.TimeToDie() >= 6 and target.DebuffRemaining(corruption_debuff) <= 0.3 * BaseDuration(corruption_debuff) and BuffExpires(metamorphosis_buff) and Spell(corruption) or BuffPresent(metamorphosis_buff) and BuffPresent(dark_soul_knowledge_buff) and Enemies() >= 2 and DemonicFury() > 450 and Spell(chaos_wave) or BuffPresent(metamorphosis_buff) and BuffPresent(molten_core_buff any=1) and { BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(soul_fire) and DemonicFury() >= 175 or target.TimeToDie() < BuffRemaining(demonbolt_buff) } and Spell(soul_fire) or BuffPresent(metamorphosis_buff) and BuffPresent(molten_core_buff any=1) and target.HealthPercent() <= 25 and { DemonicFury() - 80 } / 800 > BuffRemaining(demonbolt_buff) / { 40 * { 100 / { 100 + SpellHaste() } } } and DemonicFury() >= 750 and Spell(soul_fire) or BuffPresent(metamorphosis_buff) and target.DebuffRemaining(corruption_debuff) < 17.4 and DemonicFury() > 750 and Spell(touch_of_chaos) or BuffPresent(metamorphosis_buff) and { target.TimeToDie() < BuffRemaining(demonbolt_buff) or DemonicFury() >= 750 and BuffPresent(demonbolt_buff) or BuffPresent(dark_soul_knowledge_buff) } and Spell(touch_of_chaos) or BuffPresent(metamorphosis_buff) and { DemonicFury() - 40 } / 800 > BuffRemaining(demonbolt_buff) / { 40 * { 100 / { 100 + SpellHaste() } } } and DemonicFury() >= 750 and Spell(touch_of_chaos) or Enemies() >= 5 and Spell(hellfire) or BuffPresent(molten_core_buff any=1) and { BuffRemaining(dark_soul_knowledge_buff) < CastTime(shadow_bolt) or BuffRemaining(dark_soul_knowledge_buff) > CastTime(soul_fire) } and Spell(soul_fire) or ManaPercent() < 40 and BuffExpires(dark_soul_knowledge_buff) and Spell(life_tap) or Enemies() >= 4 and Spell(hellfire) or Spell(shadow_bolt) or Speed() > 0 and Spell(hellfire) or Spell(life_tap)
}

AddFunction DemonologyDbCdActions
{
	unless DemonicFury() > 450 and Enemies() >= 5 and BuffExpires(immolation_aura_buff) and Spell(immolation_aura) or BuffPresent(metamorphosis_buff) and Enemies() >= 6 and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } and Spell(doom) or { BuffStacks(demonbolt_buff) == 0 or BuffStacks(demonbolt_buff) < 4 and BuffRemaining(demonbolt_buff) >= 40 * { 100 / { 100 + SpellHaste() } } - ExecuteTime(demonbolt) } and Spell(demonbolt) or BuffPresent(metamorphosis_buff) and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } and Spell(doom) or target.TimeToDie() >= 6 and target.DebuffRemaining(corruption_debuff) <= 0.3 * BaseDuration(corruption_debuff) and BuffExpires(metamorphosis_buff) and Spell(corruption) or BuffPresent(metamorphosis_buff) and BuffPresent(dark_soul_knowledge_buff) and Enemies() >= 2 and DemonicFury() > 450 and Spell(chaos_wave) or BuffPresent(metamorphosis_buff) and BuffPresent(molten_core_buff any=1) and { BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(soul_fire) and DemonicFury() >= 175 or target.TimeToDie() < BuffRemaining(demonbolt_buff) } and Spell(soul_fire) or BuffPresent(metamorphosis_buff) and BuffPresent(molten_core_buff any=1) and target.HealthPercent() <= 25 and { DemonicFury() - 80 } / 800 > BuffRemaining(demonbolt_buff) / { 40 * { 100 / { 100 + SpellHaste() } } } and DemonicFury() >= 750 and Spell(soul_fire) or BuffPresent(metamorphosis_buff) and target.DebuffRemaining(corruption_debuff) < 17.4 and DemonicFury() > 750 and Spell(touch_of_chaos) or BuffPresent(metamorphosis_buff) and { target.TimeToDie() < BuffRemaining(demonbolt_buff) or DemonicFury() >= 750 and BuffPresent(demonbolt_buff) or BuffPresent(dark_soul_knowledge_buff) } and Spell(touch_of_chaos) or BuffPresent(metamorphosis_buff) and { DemonicFury() - 40 } / 800 > BuffRemaining(demonbolt_buff) / { 40 * { 100 / { 100 + SpellHaste() } } } and DemonicFury() >= 750 and Spell(touch_of_chaos)
	{
		#imp_swarm
		Spell(imp_swarm)
	}
}

AddFunction DemonologyDbCdPostConditions
{
	DemonicFury() > 450 and Enemies() >= 5 and BuffExpires(immolation_aura_buff) and Spell(immolation_aura) or BuffPresent(metamorphosis_buff) and Enemies() >= 6 and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } and Spell(doom) or { BuffStacks(demonbolt_buff) == 0 or BuffStacks(demonbolt_buff) < 4 and BuffRemaining(demonbolt_buff) >= 40 * { 100 / { 100 + SpellHaste() } } - ExecuteTime(demonbolt) } and Spell(demonbolt) or BuffPresent(metamorphosis_buff) and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } and Spell(doom) or target.TimeToDie() >= 6 and target.DebuffRemaining(corruption_debuff) <= 0.3 * BaseDuration(corruption_debuff) and BuffExpires(metamorphosis_buff) and Spell(corruption) or BuffPresent(metamorphosis_buff) and BuffPresent(dark_soul_knowledge_buff) and Enemies() >= 2 and DemonicFury() > 450 and Spell(chaos_wave) or BuffPresent(metamorphosis_buff) and BuffPresent(molten_core_buff any=1) and { BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(soul_fire) and DemonicFury() >= 175 or target.TimeToDie() < BuffRemaining(demonbolt_buff) } and Spell(soul_fire) or BuffPresent(metamorphosis_buff) and BuffPresent(molten_core_buff any=1) and target.HealthPercent() <= 25 and { DemonicFury() - 80 } / 800 > BuffRemaining(demonbolt_buff) / { 40 * { 100 / { 100 + SpellHaste() } } } and DemonicFury() >= 750 and Spell(soul_fire) or BuffPresent(metamorphosis_buff) and target.DebuffRemaining(corruption_debuff) < 17.4 and DemonicFury() > 750 and Spell(touch_of_chaos) or BuffPresent(metamorphosis_buff) and { target.TimeToDie() < BuffRemaining(demonbolt_buff) or DemonicFury() >= 750 and BuffPresent(demonbolt_buff) or BuffPresent(dark_soul_knowledge_buff) } and Spell(touch_of_chaos) or BuffPresent(metamorphosis_buff) and { DemonicFury() - 40 } / 800 > BuffRemaining(demonbolt_buff) / { 40 * { 100 / { 100 + SpellHaste() } } } and DemonicFury() >= 750 and Spell(touch_of_chaos) or Enemies() >= 5 and Spell(hellfire) or BuffPresent(molten_core_buff any=1) and { BuffRemaining(dark_soul_knowledge_buff) < CastTime(shadow_bolt) or BuffRemaining(dark_soul_knowledge_buff) > CastTime(soul_fire) } and Spell(soul_fire) or ManaPercent() < 40 and BuffExpires(dark_soul_knowledge_buff) and Spell(life_tap) or Enemies() >= 4 and Spell(hellfire) or Spell(shadow_bolt) or Speed() > 0 and Spell(hellfire) or Spell(life_tap)
}

### actions.precombat

AddFunction DemonologyPrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=sleeper_surprise
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier_buff any=1) Spell(dark_intent)
	#soul_fire
	Spell(soul_fire)
}

AddFunction DemonologyPrecombatShortCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent)
	{
		#summon_pet,if=!talent.demonic_servitude.enabled&(!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down)
		if not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() Spell(summon_felguard)
		#snapshot_stats
		#service_pet,if=talent.grimoire_of_service.enabled
		if Talent(grimoire_of_service_talent) Spell(grimoire_felguard)
	}
}

AddFunction DemonologyPrecombatShortCdPostConditions
{
	not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or Spell(soul_fire)
}

AddFunction DemonologyPrecombatCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() and Spell(summon_felguard)
	{
		#summon_doomguard,if=talent.demonic_servitude.enabled&active_enemies<5
		if Talent(demonic_servitude_talent) and Enemies() < 5 Spell(summon_doomguard)
		#summon_infernal,if=talent.demonic_servitude.enabled&active_enemies>=5
		if Talent(demonic_servitude_talent) and Enemies() >= 5 Spell(summon_infernal)

		unless Talent(grimoire_of_service_talent) and Spell(grimoire_felguard)
		{
			#potion,name=draenic_intellect
			DemonologyUsePotionIntellect()
		}
	}
}

AddFunction DemonologyPrecombatCdPostConditions
{
	not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() and Spell(summon_felguard) or Talent(grimoire_of_service_talent) and Spell(grimoire_felguard) or Spell(soul_fire)
}

###
### Destruction
###
# Based on SimulationCraft profile "Warlock_Destruction_T17M".
#	class=warlock
#	spec=destruction
#	talents=0000213
#	pet=felhunter

AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=destruction)

AddFunction DestructionUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

### actions.default

AddFunction DestructionDefaultMainActions
{
	#run_action_list,name=single_target,if=active_enemies<6
	if Enemies() < 6 DestructionSingleTargetMainActions()
	#run_action_list,name=aoe,if=active_enemies>=6
	if Enemies() >= 6 DestructionAoeMainActions()
}

AddFunction DestructionDefaultShortCdActions
{
	#mannoroths_fury
	Spell(mannoroths_fury)
	#service_pet,if=talent.grimoire_of_service.enabled&(target.time_to_die>120|target.time_to_die<20|(buff.dark_soul.remains&target.health.pct<20))
	if Talent(grimoire_of_service_talent) and { target.TimeToDie() > 120 or target.TimeToDie() < 20 or BuffPresent(dark_soul_instability_buff) and target.HealthPercent() < 20 } Spell(grimoire_felhunter)
	#run_action_list,name=single_target,if=active_enemies<6
	if Enemies() < 6 DestructionSingleTargetShortCdActions()

	unless Enemies() < 6 and DestructionSingleTargetShortCdPostConditions()
	{
		#run_action_list,name=aoe,if=active_enemies>=6
		if Enemies() >= 6 DestructionAoeShortCdActions()
	}
}

AddFunction DestructionDefaultCdActions
{
	#potion,name=draenic_intellect,if=buff.bloodlust.react&buff.dark_soul.remains>10|target.time_to_die<=25|buff.dark_soul.remains>10
	if BuffPresent(burst_haste_buff any=1) and BuffRemaining(dark_soul_instability_buff) > 10 or target.TimeToDie() <= 25 or BuffRemaining(dark_soul_instability_buff) > 10 DestructionUsePotionIntellect()
	#berserking
	Spell(berserking)
	#blood_fury
	Spell(blood_fury_sp)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#dark_soul,if=!talent.archimondes_darkness.enabled|(talent.archimondes_darkness.enabled&(charges=2|trinket.proc.any.react|trinket.stacking_any.intellect.react>6|target.time_to_die<40))
	if not Talent(archimondes_darkness_talent) or Talent(archimondes_darkness_talent) and { Charges(dark_soul_instability) == 2 or BuffPresent(trinket_proc_any_buff) or BuffStacks(trinket_stacking_any_intellect_buff) > 6 or target.TimeToDie() < 40 } Spell(dark_soul_instability)

	unless Talent(grimoire_of_service_talent) and { target.TimeToDie() > 120 or target.TimeToDie() < 20 or BuffPresent(dark_soul_instability_buff) and target.HealthPercent() < 20 } and Spell(grimoire_felhunter)
	{
		#summon_doomguard,if=!talent.demonic_servitude.enabled&active_enemies<5
		if not Talent(demonic_servitude_talent) and Enemies() < 5 Spell(summon_doomguard)
		#summon_infernal,if=!talent.demonic_servitude.enabled&active_enemies>=5
		if not Talent(demonic_servitude_talent) and Enemies() >= 5 Spell(summon_infernal)
	}
}

### actions.aoe

AddFunction DestructionAoeMainActions
{
	#rain_of_fire,if=remains<=tick_time
	if target.DebuffRemaining(rain_of_fire_debuff) <= target.TickTime(rain_of_fire_debuff) Spell(rain_of_fire)
	#shadowburn,if=buff.havoc.remains
	if BuffPresent(havoc_buff) Spell(shadowburn)
	#chaos_bolt,if=buff.havoc.remains>cast_time&buff.havoc.stack>=3
	if BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and BuffStacks(havoc_buff) >= 3 Spell(chaos_bolt)
	#immolate,if=buff.fire_and_brimstone.up&!dot.immolate.ticking
	if BuffPresent(fire_and_brimstone_buff) and not target.DebuffPresent(immolate_debuff) Spell(immolate)
	#conflagrate,if=buff.fire_and_brimstone.up&charges=2
	if BuffPresent(fire_and_brimstone_buff) and Charges(conflagrate) == 2 Spell(conflagrate)
	#immolate,if=buff.fire_and_brimstone.up&dot.immolate.remains<=(dot.immolate.duration*0.3)
	if BuffPresent(fire_and_brimstone_buff) and target.DebuffRemaining(immolate_debuff) <= target.DebuffDuration(immolate_debuff) * 0.3 Spell(immolate)
	#chaos_bolt,if=talent.charred_remains.enabled&buff.fire_and_brimstone.up&burning_ember>=2.5
	if Talent(charred_remains_talent) and BuffPresent(fire_and_brimstone_buff) and BurningEmbers() / 10 >= 2.5 Spell(chaos_bolt)
	#incinerate
	Spell(incinerate)
}

AddFunction DestructionAoeShortCdActions
{
	unless target.DebuffRemaining(rain_of_fire_debuff) <= target.TickTime(rain_of_fire_debuff) and Spell(rain_of_fire)
	{
		#havoc,target=2
		if Enemies() > 1 Spell(havoc text=other)

		unless BuffPresent(havoc_buff) and Spell(shadowburn) or BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and BuffStacks(havoc_buff) >= 3 and Spell(chaos_bolt)
		{
			#kiljaedens_cunning,if=(talent.cataclysm.enabled&!cooldown.cataclysm.remains)
			if Talent(cataclysm_talent) and not SpellCooldown(cataclysm) > 0 Spell(kiljaedens_cunning)
			#kiljaedens_cunning,moving=1,if=!talent.cataclysm.enabled
			if Speed() > 0 and not Talent(cataclysm_talent) Spell(kiljaedens_cunning)
			#cataclysm
			Spell(cataclysm)
			#fire_and_brimstone,if=buff.fire_and_brimstone.down
			if BuffExpires(fire_and_brimstone_buff) Spell(fire_and_brimstone)
		}
	}
}

### actions.precombat

AddFunction DestructionPrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=blackrock_barbecue
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier_buff any=1) Spell(dark_intent)
	#snapshot_stats
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled&!talent.demonic_servitude.enabled
	if Talent(grimoire_of_sacrifice_talent) and not Talent(demonic_servitude_talent) and pet.Present() Spell(grimoire_of_sacrifice)
	#incinerate
	Spell(incinerate)
}

AddFunction DestructionPrecombatShortCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent)
	{
		#summon_pet,if=!talent.demonic_servitude.enabled&(!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down)
		if not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() Spell(summon_felhunter)
		#service_pet,if=talent.grimoire_of_service.enabled
		if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)
	}
}

AddFunction DestructionPrecombatShortCdPostConditions
{
	not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or Spell(incinerate)
}

AddFunction DestructionPrecombatCdActions
{
	unless not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() and Spell(summon_felhunter)
	{
		#summon_doomguard,if=talent.demonic_servitude.enabled&active_enemies<5
		if Talent(demonic_servitude_talent) and Enemies() < 5 Spell(summon_doomguard)
		#summon_infernal,if=talent.demonic_servitude.enabled&active_enemies>=5
		if Talent(demonic_servitude_talent) and Enemies() >= 5 Spell(summon_infernal)

		unless Talent(grimoire_of_service_talent) and Spell(grimoire_felhunter)
		{
			#potion,name=draenic_intellect
			DestructionUsePotionIntellect()
		}
	}
}

AddFunction DestructionPrecombatCdPostConditions
{
	not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() and Spell(summon_felhunter) or Talent(grimoire_of_service_talent) and Spell(grimoire_felhunter) or Spell(incinerate)
}

### actions.single_target

AddFunction DestructionSingleTargetMainActions
{
	#shadowburn,if=talent.charred_remains.enabled&(burning_ember>=2.5|buff.dark_soul.up|target.time_to_die<10)
	if Talent(charred_remains_talent) and { BurningEmbers() / 10 >= 2.5 or BuffPresent(dark_soul_instability_buff) or target.TimeToDie() < 10 } Spell(shadowburn)
	#immolate,cycle_targets=1,if=remains<=cast_time&(cooldown.cataclysm.remains>cast_time|!talent.cataclysm.enabled)
	if target.DebuffRemaining(immolate_debuff) <= CastTime(immolate) and { SpellCooldown(cataclysm) > CastTime(immolate) or not Talent(cataclysm_talent) } Spell(immolate)
	#shadowburn,if=buff.havoc.remains
	if BuffPresent(havoc_buff) Spell(shadowburn)
	#chaos_bolt,if=buff.havoc.remains>cast_time&buff.havoc.stack>=3
	if BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and BuffStacks(havoc_buff) >= 3 Spell(chaos_bolt)
	#conflagrate,if=charges=2
	if Charges(conflagrate) == 2 Spell(conflagrate)
	#rain_of_fire,if=remains<=tick_time&(active_enemies>4|(buff.mannoroths_fury.up&active_enemies>2))
	if target.DebuffRemaining(rain_of_fire_debuff) <= target.TickTime(rain_of_fire_debuff) and { Enemies() > 4 or BuffPresent(mannoroths_fury_buff) and Enemies() > 2 } Spell(rain_of_fire)
	#chaos_bolt,if=talent.charred_remains.enabled&active_enemies>1&target.health.pct>20
	if Talent(charred_remains_talent) and Enemies() > 1 and target.HealthPercent() > 20 Spell(chaos_bolt)
	#chaos_bolt,if=talent.charred_remains.enabled&buff.backdraft.stack<3&burning_ember>=2.5
	if Talent(charred_remains_talent) and BuffStacks(backdraft_buff) < 3 and BurningEmbers() / 10 >= 2.5 Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&(burning_ember>=3.5|buff.dark_soul.up|(burning_ember>=3&buff.ember_master.react)|target.time_to_die<20)
	if BuffStacks(backdraft_buff) < 3 and { BurningEmbers() / 10 >= 3.5 or BuffPresent(dark_soul_instability_buff) or BurningEmbers() / 10 >= 3 and BuffPresent(ember_master_buff) or target.TimeToDie() < 20 } Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&set_bonus.tier17_2pc=1&burning_ember>=2.5
	if BuffStacks(backdraft_buff) < 3 and ArmorSetBonus(T17 2) == 1 and BurningEmbers() / 10 >= 2.5 Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&buff.archmages_greater_incandescence_int.react&buff.archmages_greater_incandescence_int.remains>cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffPresent(archmages_greater_incandescence_int_buff) and BuffRemaining(archmages_greater_incandescence_int_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.proc.intellect.react&trinket.proc.intellect.remains>cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.stacking_proc.intellect.react>7&trinket.stacking_proc.intellect.remains>=cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffStacks(trinket_stacking_proc_intellect_buff) > 7 and BuffRemaining(trinket_stacking_proc_intellect_buff) >= CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.proc.crit.react&trinket.proc.crit.remains>cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_crit_buff) and BuffRemaining(trinket_proc_crit_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.stacking_proc.multistrike.react>=8&trinket.stacking_proc.multistrike.remains>=cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffStacks(trinket_stacking_proc_multistrike_buff) >= 8 and BuffRemaining(trinket_stacking_proc_multistrike_buff) >= CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.proc.multistrike.react&trinket.proc.multistrike.remains>cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_multistrike_buff) and BuffRemaining(trinket_proc_multistrike_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.proc.versatility.react&trinket.proc.versatility.remains>cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_versatility_buff) and BuffRemaining(trinket_proc_versatility_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&trinket.proc.mastery.react&trinket.proc.mastery.remains>cast_time
	if BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_mastery_buff) and BuffRemaining(trinket_proc_mastery_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
	#immolate,cycle_targets=1,if=remains<=(duration*0.3)
	if target.DebuffRemaining(immolate_debuff) <= BaseDuration(immolate_debuff) * 0.3 Spell(immolate)
	#conflagrate
	Spell(conflagrate)
	#incinerate
	Spell(incinerate)
}

AddFunction DestructionSingleTargetShortCdActions
{
	#havoc,target=2
	if Enemies() > 1 Spell(havoc text=other)

	unless Talent(charred_remains_talent) and { BurningEmbers() / 10 >= 2.5 or BuffPresent(dark_soul_instability_buff) or target.TimeToDie() < 10 } and Spell(shadowburn)
	{
		#kiljaedens_cunning,if=(talent.cataclysm.enabled&!cooldown.cataclysm.remains)
		if Talent(cataclysm_talent) and not SpellCooldown(cataclysm) > 0 Spell(kiljaedens_cunning)
		#kiljaedens_cunning,moving=1,if=!talent.cataclysm.enabled
		if Speed() > 0 and not Talent(cataclysm_talent) Spell(kiljaedens_cunning)
		#cataclysm,if=active_enemies>1
		if Enemies() > 1 Spell(cataclysm)
		#fire_and_brimstone,if=buff.fire_and_brimstone.down&dot.immolate.remains<=action.immolate.cast_time&(cooldown.cataclysm.remains>action.immolate.cast_time|!talent.cataclysm.enabled)&active_enemies>4
		if BuffExpires(fire_and_brimstone_buff) and target.DebuffRemaining(immolate_debuff) <= CastTime(immolate) and { SpellCooldown(cataclysm) > CastTime(immolate) or not Talent(cataclysm_talent) } and Enemies() > 4 Spell(fire_and_brimstone)

		unless target.DebuffRemaining(immolate_debuff) <= CastTime(immolate) and { SpellCooldown(cataclysm) > CastTime(immolate) or not Talent(cataclysm_talent) } and Spell(immolate) or BuffPresent(havoc_buff) and Spell(shadowburn) or BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and BuffStacks(havoc_buff) >= 3 and Spell(chaos_bolt) or Charges(conflagrate) == 2 and Spell(conflagrate)
		{
			#cataclysm
			Spell(cataclysm)

			unless target.DebuffRemaining(rain_of_fire_debuff) <= target.TickTime(rain_of_fire_debuff) and { Enemies() > 4 or BuffPresent(mannoroths_fury_buff) and Enemies() > 2 } and Spell(rain_of_fire) or Talent(charred_remains_talent) and Enemies() > 1 and target.HealthPercent() > 20 and Spell(chaos_bolt) or Talent(charred_remains_talent) and BuffStacks(backdraft_buff) < 3 and BurningEmbers() / 10 >= 2.5 and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and { BurningEmbers() / 10 >= 3.5 or BuffPresent(dark_soul_instability_buff) or BurningEmbers() / 10 >= 3 and BuffPresent(ember_master_buff) or target.TimeToDie() < 20 } and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and ArmorSetBonus(T17 2) == 1 and BurningEmbers() / 10 >= 2.5 and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(archmages_greater_incandescence_int_buff) and BuffRemaining(archmages_greater_incandescence_int_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffStacks(trinket_stacking_proc_intellect_buff) > 7 and BuffRemaining(trinket_stacking_proc_intellect_buff) >= CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_crit_buff) and BuffRemaining(trinket_proc_crit_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffStacks(trinket_stacking_proc_multistrike_buff) >= 8 and BuffRemaining(trinket_stacking_proc_multistrike_buff) >= CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_multistrike_buff) and BuffRemaining(trinket_proc_multistrike_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_versatility_buff) and BuffRemaining(trinket_proc_versatility_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_mastery_buff) and BuffRemaining(trinket_proc_mastery_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt)
			{
				#fire_and_brimstone,if=buff.fire_and_brimstone.down&dot.immolate.remains<=(dot.immolate.duration*0.3)&active_enemies>4
				if BuffExpires(fire_and_brimstone_buff) and target.DebuffRemaining(immolate_debuff) <= target.DebuffDuration(immolate_debuff) * 0.3 and Enemies() > 4 Spell(fire_and_brimstone)
			}
		}
	}
}

AddFunction DestructionSingleTargetShortCdPostConditions
{
	Talent(charred_remains_talent) and { BurningEmbers() / 10 >= 2.5 or BuffPresent(dark_soul_instability_buff) or target.TimeToDie() < 10 } and Spell(shadowburn) or target.DebuffRemaining(immolate_debuff) <= CastTime(immolate) and { SpellCooldown(cataclysm) > CastTime(immolate) or not Talent(cataclysm_talent) } and Spell(immolate) or BuffPresent(havoc_buff) and Spell(shadowburn) or BuffRemaining(havoc_buff) > CastTime(chaos_bolt) and BuffStacks(havoc_buff) >= 3 and Spell(chaos_bolt) or Charges(conflagrate) == 2 and Spell(conflagrate) or target.DebuffRemaining(rain_of_fire_debuff) <= target.TickTime(rain_of_fire_debuff) and { Enemies() > 4 or BuffPresent(mannoroths_fury_buff) and Enemies() > 2 } and Spell(rain_of_fire) or Talent(charred_remains_talent) and Enemies() > 1 and target.HealthPercent() > 20 and Spell(chaos_bolt) or Talent(charred_remains_talent) and BuffStacks(backdraft_buff) < 3 and BurningEmbers() / 10 >= 2.5 and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and { BurningEmbers() / 10 >= 3.5 or BuffPresent(dark_soul_instability_buff) or BurningEmbers() / 10 >= 3 and BuffPresent(ember_master_buff) or target.TimeToDie() < 20 } and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and ArmorSetBonus(T17 2) == 1 and BurningEmbers() / 10 >= 2.5 and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(archmages_greater_incandescence_int_buff) and BuffRemaining(archmages_greater_incandescence_int_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffStacks(trinket_stacking_proc_intellect_buff) > 7 and BuffRemaining(trinket_stacking_proc_intellect_buff) >= CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_crit_buff) and BuffRemaining(trinket_proc_crit_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffStacks(trinket_stacking_proc_multistrike_buff) >= 8 and BuffRemaining(trinket_stacking_proc_multistrike_buff) >= CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_multistrike_buff) and BuffRemaining(trinket_proc_multistrike_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_versatility_buff) and BuffRemaining(trinket_proc_versatility_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or BuffStacks(backdraft_buff) < 3 and BuffPresent(trinket_proc_mastery_buff) and BuffRemaining(trinket_proc_mastery_buff) > CastTime(chaos_bolt) and Spell(chaos_bolt) or target.DebuffRemaining(immolate_debuff) <= BaseDuration(immolate_debuff) * 0.3 and Spell(immolate) or Spell(conflagrate) or Spell(incinerate)
}
]]
	OvaleScripts:RegisterScript("WARLOCK", name, desc, code, "include")
end

do
	local name = "Ovale"	-- The default script.
	local desc = "[6.0] Ovale: Affliction, Demonology, Destruction"
	local code = [[
# Ovale warlock script based on SimulationCraft.

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)
Include(ovale_warlock)

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

### Demonology icons.

AddCheckBox(opt_warlock_demonology_aoe L(AOE) default specialization=demonology)

AddIcon checkbox=!opt_warlock_demonology_aoe enemies=1 help=shortcd specialization=demonology
{
	if not InCombat() DemonologyPrecombatShortCdActions()
	unless not InCombat() and DemonologyPrecombatShortCdPostConditions()
	{
		DemonologyDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_warlock_demonology_aoe help=shortcd specialization=demonology
{
	if not InCombat() DemonologyPrecombatShortCdActions()
	unless not InCombat() and DemonologyPrecombatShortCdPostConditions()
	{
		DemonologyDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=demonology
{
	if not InCombat() DemonologyPrecombatMainActions()
	DemonologyDefaultMainActions()
}

AddIcon checkbox=opt_warlock_demonology_aoe help=aoe specialization=demonology
{
	if not InCombat() DemonologyPrecombatMainActions()
	DemonologyDefaultMainActions()
}

AddIcon checkbox=!opt_warlock_demonology_aoe enemies=1 help=cd specialization=demonology
{
	if not InCombat() DemonologyPrecombatCdActions()
	unless not InCombat() and DemonologyPrecombatCdPostConditions()
	{
		DemonologyDefaultCdActions()
	}
}

AddIcon checkbox=opt_warlock_demonology_aoe help=cd specialization=demonology
{
	if not InCombat() DemonologyPrecombatCdActions()
	unless not InCombat() and DemonologyPrecombatCdPostConditions()
	{
		DemonologyDefaultCdActions()
	}
}

### Destruction icons.

AddCheckBox(opt_warlock_destruction_aoe L(AOE) default specialization=destruction)

AddIcon checkbox=!opt_warlock_destruction_aoe enemies=1 help=shortcd specialization=destruction
{
	if not InCombat() DestructionPrecombatShortCdActions()
	unless not InCombat() and DestructionPrecombatShortCdPostConditions()
	{
		DestructionDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_warlock_destruction_aoe help=shortcd specialization=destruction
{
	if not InCombat() DestructionPrecombatShortCdActions()
	unless not InCombat() and DestructionPrecombatShortCdPostConditions()
	{
		DestructionDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=destruction
{
	if not InCombat() DestructionPrecombatMainActions()
	DestructionDefaultMainActions()
}

AddIcon checkbox=opt_warlock_destruction_aoe help=aoe specialization=destruction
{
	if not InCombat() DestructionPrecombatMainActions()
	DestructionDefaultMainActions()
}

AddIcon checkbox=!opt_warlock_destruction_aoe enemies=1 help=cd specialization=destruction
{
	if not InCombat() DestructionPrecombatCdActions()
	unless not InCombat() and DestructionPrecombatCdPostConditions()
	{
		DestructionDefaultCdActions()
	}
}

AddIcon checkbox=opt_warlock_destruction_aoe help=cd specialization=destruction
{
	if not InCombat() DestructionPrecombatCdActions()
	unless not InCombat() and DestructionPrecombatCdPostConditions()
	{
		DestructionDefaultCdActions()
	}
}
]]
	OvaleScripts:RegisterScript("WARLOCK", name, desc, code, "script")
end
