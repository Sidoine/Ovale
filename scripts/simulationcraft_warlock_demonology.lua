local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_warlock_demonology_t18m"
	local desc = "[6.2] SimulationCraft: Warlock_Demonology_T18M"
	local code = [[
# Based on SimulationCraft profile "Warlock_Demonology_T18M".
#	class=warlock
#	spec=demonology
#	talents=0000213
#	pet=felguard

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)

AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=demonology)

AddFunction DemonologyUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction DemonologyUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

### actions.default

AddFunction DemonologyDefaultMainActions
{
	#call_action_list,name=opener,if=time<7&talent.demonic_servitude.enabled
	if TimeInCombat() < 7 and Talent(demonic_servitude_talent) DemonologyOpenerMainActions()
	#life_tap,if=buff.metamorphosis.down&mana.pct<40&buff.dark_soul.down
	if BuffExpires(metamorphosis_buff) and ManaPercent() < 40 and BuffExpires(dark_soul_knowledge_buff) Spell(life_tap)
	#hand_of_guldan,if=!in_flight&dot.shadowflame.remains<travel_time+action.shadow_bolt.cast_time&(((set_bonus.tier17_4pc=0&((charges=1&recharge_time<4)|charges=2))|(charges=3|(charges=2&recharge_time<13.8-travel_time*2))&((cooldown.cataclysm.remains>dot.shadowflame.duration)|!talent.cataclysm.enabled))|dot.shadowflame.remains>travel_time)
	if not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and { ArmorSetBonus(T17 4) == 0 and { Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 or Charges(hand_of_guldan) == 2 } or { Charges(hand_of_guldan) == 3 or Charges(hand_of_guldan) == 2 and SpellChargeCooldown(hand_of_guldan) < 13.8 - TravelTime(hand_of_guldan) * 2 } and { SpellCooldown(cataclysm) > target.DebuffDuration(shadowflame_debuff) or not Talent(cataclysm_talent) } or target.DebuffRemaining(shadowflame_debuff) > TravelTime(hand_of_guldan) } Spell(hand_of_guldan)
	#hand_of_guldan,if=!in_flight&dot.shadowflame.remains<travel_time+action.shadow_bolt.cast_time&talent.demonbolt.enabled&((set_bonus.tier17_4pc=0&((charges=1&recharge_time<4)|charges=2))|(charges=3|(charges=2&recharge_time<13.8-travel_time*2))|dot.shadowflame.remains>travel_time)
	if not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and Talent(demonbolt_talent) and { ArmorSetBonus(T17 4) == 0 and { Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 or Charges(hand_of_guldan) == 2 } or Charges(hand_of_guldan) == 3 or Charges(hand_of_guldan) == 2 and SpellChargeCooldown(hand_of_guldan) < 13.8 - TravelTime(hand_of_guldan) * 2 or target.DebuffRemaining(shadowflame_debuff) > TravelTime(hand_of_guldan) } Spell(hand_of_guldan)
	#hand_of_guldan,if=!in_flight&dot.shadowflame.remains<3.7&time<5&buff.demonbolt.remains<gcd*2&(charges>=2|set_bonus.tier17_4pc=0)&action.dark_soul.charges>=1
	if not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < 3.7 and TimeInCombat() < 5 and BuffRemaining(demonbolt_buff) < GCD() * 2 and { Charges(hand_of_guldan) >= 2 or ArmorSetBonus(T17 4) == 0 } and Charges(dark_soul_knowledge) >= 1 Spell(hand_of_guldan)
	#call_action_list,name=db,if=talent.demonbolt.enabled
	if Talent(demonbolt_talent) DemonologyDbMainActions()
	#call_action_list,name=meta,if=buff.metamorphosis.up
	if BuffPresent(metamorphosis_buff) DemonologyMetaMainActions()
	#corruption,cycle_targets=1,if=target.time_to_die>=6&remains<=(0.3*duration)&buff.metamorphosis.down
	if target.TimeToDie() >= 6 and target.DebuffRemaining(corruption_debuff) <= 0.3 * BaseDuration(corruption_debuff) and BuffExpires(metamorphosis_buff) Spell(corruption)
	#metamorphosis,if=buff.nithramus.remains>4&demonic_fury>=80*action.soul_fire.gcd*buff.nithramus.remains
	if BuffRemaining(nithramus_buff) > 4 and DemonicFury() >= 80 * GCD() * BuffRemaining(nithramus_buff) Spell(metamorphosis)
	#metamorphosis,if=debuff.mark_of_doom.remains&demonic_fury>=40*action.touch_of_chaos.gcd*debuff.mark_of_doom.remains
	if target.DebuffPresent(mark_of_doom_debuff) and DemonicFury() >= 40 * GCD() * target.DebuffRemaining(mark_of_doom_debuff) Spell(metamorphosis)
	#metamorphosis,if=buff.dark_soul.remains>gcd&(time>6|debuff.shadowflame.stack=2)&(demonic_fury>300|!glyph.dark_soul.enabled)&(demonic_fury>=80&buff.molten_core.stack>=1|demonic_fury>=40)
	if BuffRemaining(dark_soul_knowledge_buff) > GCD() and { TimeInCombat() > 6 or target.DebuffStacks(shadowflame_debuff) == 2 } and { DemonicFury() > 300 or not Glyph(glyph_of_dark_soul) } and { DemonicFury() >= 80 and BuffStacks(molten_core_buff) >= 1 or DemonicFury() >= 40 } Spell(metamorphosis)
	#metamorphosis,if=(trinket.stacking_proc.any.react|trinket.proc.any.react)&((demonic_fury>450&action.dark_soul.recharge_time>=10&glyph.dark_soul.enabled)|(demonic_fury>650&cooldown.dark_soul.remains>=10))
	if { BuffPresent(trinket_stacking_proc_any_buff) or BuffPresent(trinket_proc_any_buff) } and { DemonicFury() > 450 and SpellChargeCooldown(dark_soul_knowledge) >= 10 and Glyph(glyph_of_dark_soul) or DemonicFury() > 650 and SpellCooldown(dark_soul_knowledge) >= 10 } Spell(metamorphosis)
	#metamorphosis,if=!cooldown.cataclysm.remains&talent.cataclysm.enabled
	if not SpellCooldown(cataclysm) > 0 and Talent(cataclysm_talent) Spell(metamorphosis)
	#metamorphosis,if=!dot.doom.ticking&target.time_to_die>=30%(1%spell_haste)&demonic_fury>300
	if not target.DebuffPresent(doom_debuff) and target.TimeToDie() >= 30 / { 1 / { 100 / { 100 + SpellHaste() } } } and DemonicFury() > 300 Spell(metamorphosis)
	#metamorphosis,if=(demonic_fury>750&(action.hand_of_guldan.charges=0|(!dot.shadowflame.ticking&!action.hand_of_guldan.in_flight_to_target)))|floor(demonic_fury%80)*action.soul_fire.execute_time>=target.time_to_die
	if DemonicFury() > 750 and { Charges(hand_of_guldan) == 0 or not target.DebuffPresent(shadowflame_debuff) and not InFlightToTarget(hand_of_guldan) } or DemonicFury() / 80 * ExecuteTime(soul_fire) >= target.TimeToDie() Spell(metamorphosis)
	#metamorphosis,if=demonic_fury>=950
	if DemonicFury() >= 950 Spell(metamorphosis)
	#hellfire,interrupt=1,if=spell_targets.hellfire_tick>=5
	if Enemies() >= 5 Spell(hellfire)
	#soul_fire,if=buff.molten_core.react&(buff.demon_rush.remains<=execute_time+travel_time+action.shadow_bolt.execute_time|buff.demon_rush.stack<5)&set_bonus.tier18_2pc=1
	if BuffPresent(molten_core_buff) and { BuffRemaining(demon_rush_buff) <= ExecuteTime(soul_fire) + TravelTime(soul_fire) + ExecuteTime(shadow_bolt) or BuffStacks(demon_rush_buff) < 5 } and ArmorSetBonus(T18 2) == 1 Spell(soul_fire)
	#soul_fire,if=buff.molten_core.react&(buff.molten_core.stack>=7|target.health.pct<=25|(buff.dark_soul.remains&cooldown.metamorphosis.remains>buff.dark_soul.remains)|trinket.proc.any.remains>execute_time|trinket.stacking_proc.any.remains>execute_time)&(buff.dark_soul.remains<action.shadow_bolt.cast_time|buff.dark_soul.remains>execute_time)
	if BuffPresent(molten_core_buff) and { BuffStacks(molten_core_buff) >= 7 or target.HealthPercent() <= 25 or BuffPresent(dark_soul_knowledge_buff) and SpellCooldown(metamorphosis) > BuffRemaining(dark_soul_knowledge_buff) or BuffRemaining(trinket_proc_any_buff) > ExecuteTime(soul_fire) or BuffRemaining(trinket_stacking_proc_any_buff) > ExecuteTime(soul_fire) } and { BuffRemaining(dark_soul_knowledge_buff) < CastTime(shadow_bolt) or BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(soul_fire) } Spell(soul_fire)
	#soul_fire,if=buff.molten_core.react&target.time_to_die<(time+target.time_to_die)*0.25+cooldown.dark_soul.remains
	if BuffPresent(molten_core_buff) and target.TimeToDie() < { TimeInCombat() + target.TimeToDie() } * 0.25 + SpellCooldown(dark_soul_knowledge) Spell(soul_fire)
	#life_tap,if=mana.pct<40&buff.dark_soul.down
	if ManaPercent() < 40 and BuffExpires(dark_soul_knowledge_buff) Spell(life_tap)
	#hellfire,interrupt=1,if=spell_targets.hellfire_tick>=4
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
	#call_action_list,name=opener,if=time<7&talent.demonic_servitude.enabled
	if TimeInCombat() < 7 and Talent(demonic_servitude_talent) DemonologyOpenerShortCdActions()

	unless TimeInCombat() < 7 and Talent(demonic_servitude_talent) and DemonologyOpenerShortCdPostConditions()
	{
		#service_pet,if=talent.grimoire_of_service.enabled&(target.time_to_die>120|target.time_to_die<=25|(buff.dark_soul.remains&target.health.pct<20))
		if Talent(grimoire_of_service_talent) and { target.TimeToDie() > 120 or target.TimeToDie() <= 25 or BuffPresent(dark_soul_knowledge_buff) and target.HealthPercent() < 20 } Spell(service_felguard)

		unless BuffExpires(metamorphosis_buff) and ManaPercent() < 40 and BuffExpires(dark_soul_knowledge_buff) and Spell(life_tap) or not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and { ArmorSetBonus(T17 4) == 0 and { Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 or Charges(hand_of_guldan) == 2 } or { Charges(hand_of_guldan) == 3 or Charges(hand_of_guldan) == 2 and SpellChargeCooldown(hand_of_guldan) < 13.8 - TravelTime(hand_of_guldan) * 2 } and { SpellCooldown(cataclysm) > target.DebuffDuration(shadowflame_debuff) or not Talent(cataclysm_talent) } or target.DebuffRemaining(shadowflame_debuff) > TravelTime(hand_of_guldan) } and Spell(hand_of_guldan) or not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and Talent(demonbolt_talent) and { ArmorSetBonus(T17 4) == 0 and { Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 or Charges(hand_of_guldan) == 2 } or Charges(hand_of_guldan) == 3 or Charges(hand_of_guldan) == 2 and SpellChargeCooldown(hand_of_guldan) < 13.8 - TravelTime(hand_of_guldan) * 2 or target.DebuffRemaining(shadowflame_debuff) > TravelTime(hand_of_guldan) } and Spell(hand_of_guldan) or not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < 3.7 and TimeInCombat() < 5 and BuffRemaining(demonbolt_buff) < GCD() * 2 and { Charges(hand_of_guldan) >= 2 or ArmorSetBonus(T17 4) == 0 } and Charges(dark_soul_knowledge) >= 1 and Spell(hand_of_guldan)
		{
			#call_action_list,name=db,if=talent.demonbolt.enabled
			if Talent(demonbolt_talent) DemonologyDbShortCdActions()

			unless Talent(demonbolt_talent) and DemonologyDbShortCdPostConditions()
			{
				#call_action_list,name=meta,if=buff.metamorphosis.up
				if BuffPresent(metamorphosis_buff) DemonologyMetaShortCdActions()
			}
		}
	}
}

AddFunction DemonologyDefaultCdActions
{
	#summon_doomguard,if=!talent.demonic_servitude.enabled&spell_targets.infernal_awakening<9
	if not Talent(demonic_servitude_talent) and Enemies() < 9 Spell(summon_doomguard)
	#summon_infernal,if=!talent.demonic_servitude.enabled&spell_targets.infernal_awakening>=9
	if not Talent(demonic_servitude_talent) and Enemies() >= 9 Spell(summon_infernal)
	#potion,name=draenic_intellect,if=buff.bloodlust.remains>30|buff.nithramus.remains>4|(((buff.dark_soul.up&(trinket.proc.any.react|trinket.stacking_proc.any.react>6)&!buff.demonbolt.remains)|target.health.pct<20)&(!talent.grimoire_of_service.enabled|!talent.demonic_servitude.enabled|pet.service_doomguard.active))
	if BuffRemaining(burst_haste_buff any=1) > 30 or BuffRemaining(nithramus_buff) > 4 or { BuffPresent(dark_soul_knowledge_buff) and { BuffPresent(trinket_proc_any_buff) or BuffStacks(trinket_stacking_proc_any_buff) > 6 } and not BuffPresent(demonbolt_buff) or target.HealthPercent() < 20 } and { not Talent(grimoire_of_service_talent) or not Talent(demonic_servitude_talent) or SpellCooldown(service_doomguard) > 100 } DemonologyUsePotionIntellect()
	#berserking
	Spell(berserking)
	#blood_fury
	Spell(blood_fury_sp)
	#arcane_torrent
	Spell(arcane_torrent_mana)

	unless TimeInCombat() < 7 and Talent(demonic_servitude_talent) and DemonologyOpenerCdPostConditions() or Talent(grimoire_of_service_talent) and { target.TimeToDie() > 120 or target.TimeToDie() <= 25 or BuffPresent(dark_soul_knowledge_buff) and target.HealthPercent() < 20 } and Spell(service_felguard)
	{
		#dark_soul,if=talent.demonbolt.enabled&((time<=20&!buff.demonbolt.remains&demonic_fury>=360)|target.time_to_die<buff.demonbolt.remains|(!buff.demonbolt.remains&demonic_fury>=790))
		if Talent(demonbolt_talent) and { TimeInCombat() <= 20 and not BuffPresent(demonbolt_buff) and DemonicFury() >= 360 or target.TimeToDie() < BuffRemaining(demonbolt_buff) or not BuffPresent(demonbolt_buff) and DemonicFury() >= 790 } Spell(dark_soul_knowledge)
		#dark_soul,if=!talent.demonbolt.enabled&((charges=2&(time>6|(debuff.shadowflame.stack=1&action.hand_of_guldan.in_flight)))|!talent.archimondes_darkness.enabled|(target.time_to_die<=20&!glyph.dark_soul.enabled)|target.time_to_die<=10|(target.time_to_die<=60&demonic_fury>400)|((trinket.proc.any.react|trinket.stacking_proc.any.react)&(demonic_fury>600|(glyph.dark_soul.enabled&demonic_fury>450))))|buff.nithramus.remains>4
		if not Talent(demonbolt_talent) and { Charges(dark_soul_knowledge) == 2 and { TimeInCombat() > 6 or target.DebuffStacks(shadowflame_debuff) == 1 and InFlightToTarget(hand_of_guldan) } or not Talent(archimondes_darkness_talent) or target.TimeToDie() <= 20 and not Glyph(glyph_of_dark_soul) or target.TimeToDie() <= 10 or target.TimeToDie() <= 60 and DemonicFury() > 400 or { BuffPresent(trinket_proc_any_buff) or BuffPresent(trinket_stacking_proc_any_buff) } and { DemonicFury() > 600 or Glyph(glyph_of_dark_soul) and DemonicFury() > 450 } } or BuffRemaining(nithramus_buff) > 4 Spell(dark_soul_knowledge)
		#imp_swarm,if=!talent.demonbolt.enabled&(buff.dark_soul.up|buff.nithramus.remains>4|(cooldown.dark_soul.remains>(120%(1%spell_haste)))|time_to_die<32)&time>3
		if not Talent(demonbolt_talent) and { BuffPresent(dark_soul_knowledge_buff) or BuffRemaining(nithramus_buff) > 4 or SpellCooldown(dark_soul_knowledge) > 120 / { 1 / { 100 / { 100 + SpellHaste() } } } or target.TimeToDie() < 32 } and TimeInCombat() > 3 Spell(imp_swarm)
		#use_item,name=nithramus_the_allseer,if=buff.dark_soul.remains
		if BuffPresent(dark_soul_knowledge_buff) DemonologyUseItemActions()

		unless BuffExpires(metamorphosis_buff) and ManaPercent() < 40 and BuffExpires(dark_soul_knowledge_buff) and Spell(life_tap) or not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and { ArmorSetBonus(T17 4) == 0 and { Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 or Charges(hand_of_guldan) == 2 } or { Charges(hand_of_guldan) == 3 or Charges(hand_of_guldan) == 2 and SpellChargeCooldown(hand_of_guldan) < 13.8 - TravelTime(hand_of_guldan) * 2 } and { SpellCooldown(cataclysm) > target.DebuffDuration(shadowflame_debuff) or not Talent(cataclysm_talent) } or target.DebuffRemaining(shadowflame_debuff) > TravelTime(hand_of_guldan) } and Spell(hand_of_guldan) or not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and Talent(demonbolt_talent) and { ArmorSetBonus(T17 4) == 0 and { Charges(hand_of_guldan) == 1 and SpellChargeCooldown(hand_of_guldan) < 4 or Charges(hand_of_guldan) == 2 } or Charges(hand_of_guldan) == 3 or Charges(hand_of_guldan) == 2 and SpellChargeCooldown(hand_of_guldan) < 13.8 - TravelTime(hand_of_guldan) * 2 or target.DebuffRemaining(shadowflame_debuff) > TravelTime(hand_of_guldan) } and Spell(hand_of_guldan) or not InFlightToTarget(hand_of_guldan) and target.DebuffRemaining(shadowflame_debuff) < 3.7 and TimeInCombat() < 5 and BuffRemaining(demonbolt_buff) < GCD() * 2 and { Charges(hand_of_guldan) >= 2 or ArmorSetBonus(T17 4) == 0 } and Charges(dark_soul_knowledge) >= 1 and Spell(hand_of_guldan)
		{
			#call_action_list,name=db,if=talent.demonbolt.enabled
			if Talent(demonbolt_talent) DemonologyDbCdActions()

			unless Talent(demonbolt_talent) and DemonologyDbCdPostConditions()
			{
				unless BuffPresent(metamorphosis_buff) and DemonologyMetaCdPostConditions() or target.TimeToDie() >= 6 and target.DebuffRemaining(corruption_debuff) <= 0.3 * BaseDuration(corruption_debuff) and BuffExpires(metamorphosis_buff) and Spell(corruption)
				{
					#imp_swarm
					Spell(imp_swarm)
				}
			}
		}
	}
}

### actions.db

AddFunction DemonologyDbMainActions
{
	#call_action_list,name=db_meta,if=buff.metamorphosis.up
	if BuffPresent(metamorphosis_buff) DemonologyDbMetaMainActions()
	#corruption,cycle_targets=1,if=target.time_to_die>=6&remains<=(0.3*duration)&buff.metamorphosis.down
	if target.TimeToDie() >= 6 and target.DebuffRemaining(corruption_debuff) <= 0.3 * BaseDuration(corruption_debuff) and BuffExpires(metamorphosis_buff) Spell(corruption)
	#metamorphosis,if=buff.dark_soul.remains>gcd&(demonic_fury>=470|buff.dark_soul.remains<=action.demonbolt.execute_time*3)&(buff.demonbolt.down|target.time_to_die<buff.demonbolt.remains|(buff.dark_soul.remains>execute_time&demonic_fury>=175))
	if BuffRemaining(dark_soul_knowledge_buff) > GCD() and { DemonicFury() >= 470 or BuffRemaining(dark_soul_knowledge_buff) <= ExecuteTime(demonbolt) * 3 } and { BuffExpires(demonbolt_buff) or target.TimeToDie() < BuffRemaining(demonbolt_buff) or BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(metamorphosis) and DemonicFury() >= 175 } Spell(metamorphosis)
	#metamorphosis,if=buff.demonbolt.down&demonic_fury>=480&(action.dark_soul.charges=0|!talent.archimondes_darkness.enabled&cooldown.dark_soul.remains)&(legendary_ring.cooldown.remains>=buff.demonbolt.duration|!legendary_ring.has_cooldown)
	if BuffExpires(demonbolt_buff) and DemonicFury() >= 480 and { Charges(dark_soul_knowledge) == 0 or not Talent(archimondes_darkness_talent) and SpellCooldown(dark_soul_knowledge) > 0 } and { ItemCooldown(legendary_ring_intellect) >= BaseDuration(demonbolt_buff) or not ItemCooldown(legendary_ring_intellect) > 0 } Spell(metamorphosis)
	#metamorphosis,if=(demonic_fury%80)*2*spell_haste>=target.time_to_die&target.time_to_die<buff.demonbolt.remains
	if DemonicFury() / 80 * 2 * { 100 / { 100 + SpellHaste() } } >= target.TimeToDie() and target.TimeToDie() < BuffRemaining(demonbolt_buff) Spell(metamorphosis)
	#metamorphosis,if=target.time_to_die>=30*spell_haste&!dot.doom.ticking&buff.dark_soul.down&time>10
	if target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and not target.DebuffPresent(doom_debuff) and BuffExpires(dark_soul_knowledge_buff) and TimeInCombat() > 10 Spell(metamorphosis)
	#metamorphosis,if=demonic_fury>750&buff.demonbolt.remains>=action.metamorphosis.cooldown
	if DemonicFury() > 750 and BuffRemaining(demonbolt_buff) >= SpellCooldown(metamorphosis) Spell(metamorphosis)
	#metamorphosis,if=(((demonic_fury-120)%800)>(buff.demonbolt.remains%40))&buff.demonbolt.remains>=10&dot.doom.remains-gcd<=dot.doom.duration*0.3
	if { DemonicFury() - 120 } / 800 > BuffRemaining(demonbolt_buff) / 40 and BuffRemaining(demonbolt_buff) >= 10 and target.DebuffRemaining(doom_debuff) - GCD() <= target.DebuffDuration(doom_debuff) * 0.3 Spell(metamorphosis)
	#metamorphosis,if=buff.demonbolt.remains&buff.demonbolt.remains<10&demonic_fury-((40*action.touch_of_chaos.gcd*buff.demonbolt.remains)+(6*buff.demonbolt.remains))>=800
	if BuffPresent(demonbolt_buff) and BuffRemaining(demonbolt_buff) < 10 and DemonicFury() - { 40 * GCD() * BuffRemaining(demonbolt_buff) + 6 * BuffRemaining(demonbolt_buff) } >= 800 Spell(metamorphosis)
	#metamorphosis,if=buff.demonbolt.remains>10&debuff.mark_of_doom.remains&demonic_fury>=40*action.touch_of_chaos.gcd*debuff.mark_of_doom.remains
	if BuffRemaining(demonbolt_buff) > 10 and target.DebuffPresent(mark_of_doom_debuff) and DemonicFury() >= 40 * GCD() * target.DebuffRemaining(mark_of_doom_debuff) Spell(metamorphosis)
	#hellfire,interrupt=1,if=spell_targets.hellfire_tick>=5
	if Enemies() >= 5 Spell(hellfire)
	#soul_fire,if=buff.molten_core.react&(buff.demon_rush.remains<=execute_time+travel_time+action.shadow_bolt.execute_time|buff.demon_rush.stack<5)&set_bonus.tier18_2pc=1
	if BuffPresent(molten_core_buff) and { BuffRemaining(demon_rush_buff) <= ExecuteTime(soul_fire) + TravelTime(soul_fire) + ExecuteTime(shadow_bolt) or BuffStacks(demon_rush_buff) < 5 } and ArmorSetBonus(T18 2) == 1 Spell(soul_fire)
	#soul_fire,if=((set_bonus.tier18_2pc=0&buff.molten_core.react)|buff.molten_core.react>1)&(buff.dark_soul.remains<action.shadow_bolt.cast_time|buff.dark_soul.remains>cast_time)
	if { ArmorSetBonus(T18 2) == 0 and BuffPresent(molten_core_buff) or BuffStacks(molten_core_buff) > 1 } and { BuffRemaining(dark_soul_knowledge_buff) < CastTime(shadow_bolt) or BuffRemaining(dark_soul_knowledge_buff) > CastTime(soul_fire) } Spell(soul_fire)
	#life_tap,if=mana.pct<40&buff.dark_soul.down
	if ManaPercent() < 40 and BuffExpires(dark_soul_knowledge_buff) Spell(life_tap)
	#hellfire,interrupt=1,if=spell_targets.hellfire_tick>=4
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
	#kiljaedens_cunning,moving=1,if=buff.demonbolt.stack=0|(buff.demonbolt.stack<4&buff.demonbolt.remains>=(40*spell_haste-execute_time))
	if Speed() > 0 and { BuffStacks(demonbolt_buff) == 0 or BuffStacks(demonbolt_buff) < 4 and BuffRemaining(demonbolt_buff) >= 40 * { 100 / { 100 + SpellHaste() } } - ExecuteTime(kiljaedens_cunning) } Spell(kiljaedens_cunning)
}

AddFunction DemonologyDbShortCdPostConditions
{
	BuffPresent(metamorphosis_buff) and DemonologyDbMetaShortCdPostConditions() or target.TimeToDie() >= 6 and target.DebuffRemaining(corruption_debuff) <= 0.3 * BaseDuration(corruption_debuff) and BuffExpires(metamorphosis_buff) and Spell(corruption) or Enemies() >= 5 and Spell(hellfire) or BuffPresent(molten_core_buff) and { BuffRemaining(demon_rush_buff) <= ExecuteTime(soul_fire) + TravelTime(soul_fire) + ExecuteTime(shadow_bolt) or BuffStacks(demon_rush_buff) < 5 } and ArmorSetBonus(T18 2) == 1 and Spell(soul_fire) or { ArmorSetBonus(T18 2) == 0 and BuffPresent(molten_core_buff) or BuffStacks(molten_core_buff) > 1 } and { BuffRemaining(dark_soul_knowledge_buff) < CastTime(shadow_bolt) or BuffRemaining(dark_soul_knowledge_buff) > CastTime(soul_fire) } and Spell(soul_fire) or ManaPercent() < 40 and BuffExpires(dark_soul_knowledge_buff) and Spell(life_tap) or Enemies() >= 4 and Spell(hellfire) or Spell(shadow_bolt) or Speed() > 0 and Spell(hellfire) or Spell(life_tap)
}

AddFunction DemonologyDbCdActions
{
	unless BuffPresent(metamorphosis_buff) and DemonologyDbMetaCdPostConditions() or target.TimeToDie() >= 6 and target.DebuffRemaining(corruption_debuff) <= 0.3 * BaseDuration(corruption_debuff) and BuffExpires(metamorphosis_buff) and Spell(corruption)
	{
		#imp_swarm
		Spell(imp_swarm)
	}
}

AddFunction DemonologyDbCdPostConditions
{
	BuffPresent(metamorphosis_buff) and DemonologyDbMetaCdPostConditions() or target.TimeToDie() >= 6 and target.DebuffRemaining(corruption_debuff) <= 0.3 * BaseDuration(corruption_debuff) and BuffExpires(metamorphosis_buff) and Spell(corruption) or Enemies() >= 5 and Spell(hellfire) or BuffPresent(molten_core_buff) and { BuffRemaining(demon_rush_buff) <= ExecuteTime(soul_fire) + TravelTime(soul_fire) + ExecuteTime(shadow_bolt) or BuffStacks(demon_rush_buff) < 5 } and ArmorSetBonus(T18 2) == 1 and Spell(soul_fire) or { ArmorSetBonus(T18 2) == 0 and BuffPresent(molten_core_buff) or BuffStacks(molten_core_buff) > 1 } and { BuffRemaining(dark_soul_knowledge_buff) < CastTime(shadow_bolt) or BuffRemaining(dark_soul_knowledge_buff) > CastTime(soul_fire) } and Spell(soul_fire) or ManaPercent() < 40 and BuffExpires(dark_soul_knowledge_buff) and Spell(life_tap) or Enemies() >= 4 and Spell(hellfire) or Spell(shadow_bolt) or Speed() > 0 and Spell(hellfire) or Spell(life_tap)
}

### actions.db_meta

AddFunction DemonologyDbMetaMainActions
{
	#immolation_aura,if=demonic_fury>450&spell_targets.immolation_aura_tick>=5&buff.immolation_aura.down
	if DemonicFury() > 450 and Enemies() >= 5 and BuffExpires(immolation_aura_buff) Spell(immolation_aura)
	#doom,cycle_targets=1,if=active_enemies_within.40>=6&target.time_to_die>=30*spell_haste&remains-gcd<=(duration*0.3)&(buff.dark_soul.down|!glyph.dark_soul.enabled)
	if Enemies() >= 6 and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) - GCD() <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } Spell(doom)
	#soul_fire,if=buff.molten_core.react&buff.demon_rush.remains<=4&set_bonus.tier18_2pc=1
	if BuffPresent(molten_core_buff) and BuffRemaining(demon_rush_buff) <= 4 and ArmorSetBonus(T18 2) == 1 Spell(soul_fire)
	#demonbolt,if=(buff.demonbolt.stack=0|(buff.demonbolt.stack<4&buff.demonbolt.remains>=(40*spell_haste-execute_time)))&(legendary_ring.cooldown.remains>=buff.demonbolt.duration|!legendary_ring.has_cooldown)
	if { BuffStacks(demonbolt_buff) == 0 or BuffStacks(demonbolt_buff) < 4 and BuffRemaining(demonbolt_buff) >= 40 * { 100 / { 100 + SpellHaste() } } - ExecuteTime(demonbolt) } and { ItemCooldown(legendary_ring_intellect) >= BaseDuration(demonbolt_buff) or not ItemCooldown(legendary_ring_intellect) > 0 } Spell(demonbolt)
	#doom,cycle_targets=1,if=target.time_to_die>=30*spell_haste&remains<=(duration*0.3)&(buff.dark_soul.down|!glyph.dark_soul.enabled)
	if target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } Spell(doom)
	#soul_fire,if=buff.molten_core.react&(buff.demon_rush.remains<=execute_time+travel_time+action.touch_of_chaos.execute_time)&set_bonus.tier18_2pc=1
	if BuffPresent(molten_core_buff) and BuffRemaining(demon_rush_buff) <= ExecuteTime(soul_fire) + TravelTime(soul_fire) + ExecuteTime(touch_of_chaos) and ArmorSetBonus(T18 2) == 1 Spell(soul_fire)
	#touch_of_chaos,if=debuff.mark_of_doom.remains
	if target.DebuffPresent(mark_of_doom_debuff) Spell(touch_of_chaos)
	#cancel_metamorphosis,if=buff.demonbolt.stack>3&demonic_fury<=600&target.time_to_die>buff.demonbolt.remains&buff.dark_soul.down
	if BuffStacks(demonbolt_buff) > 3 and DemonicFury() <= 600 and target.TimeToDie() > BuffRemaining(demonbolt_buff) and BuffExpires(dark_soul_knowledge_buff) and BuffPresent(metamorphosis_buff) Spell(metamorphosis text=cancel)
	#chaos_wave,if=buff.dark_soul.up&spell_targets.chaos_wave>=2&demonic_fury>450
	if BuffPresent(dark_soul_knowledge_buff) and Enemies() >= 2 and DemonicFury() > 450 Spell(chaos_wave)
	#soul_fire,if=buff.molten_core.react&(((buff.dark_soul.remains>execute_time)&demonic_fury>=175)|(target.time_to_die<buff.demonbolt.remains))
	if BuffPresent(molten_core_buff) and { BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(soul_fire) and DemonicFury() >= 175 or target.TimeToDie() < BuffRemaining(demonbolt_buff) } Spell(soul_fire)
	#soul_fire,if=buff.molten_core.react&target.health.pct<=25&(((demonic_fury-80)%800)>(buff.demonbolt.remains%40))&demonic_fury>=750
	if BuffPresent(molten_core_buff) and target.HealthPercent() <= 25 and { DemonicFury() - 80 } / 800 > BuffRemaining(demonbolt_buff) / 40 and DemonicFury() >= 750 Spell(soul_fire)
	#soul_fire,if=buff.molten_core.react&buff.demon_rush.stack<5&set_bonus.tier18_2pc=1
	if BuffPresent(molten_core_buff) and BuffStacks(demon_rush_buff) < 5 and ArmorSetBonus(T18 2) == 1 Spell(soul_fire)
	#touch_of_chaos,cycle_targets=1,if=dot.corruption.remains<17.4&demonic_fury>750
	if target.DebuffRemaining(corruption_debuff) < 17.4 and DemonicFury() > 750 Spell(touch_of_chaos)
	#touch_of_chaos,if=(target.time_to_die<buff.demonbolt.remains|(demonic_fury>=750&buff.demonbolt.remains)|buff.dark_soul.up)
	if target.TimeToDie() < BuffRemaining(demonbolt_buff) or DemonicFury() >= 750 and BuffPresent(demonbolt_buff) or BuffPresent(dark_soul_knowledge_buff) Spell(touch_of_chaos)
	#touch_of_chaos,if=(((demonic_fury-40)%800)>(buff.demonbolt.remains%40))&demonic_fury>=750
	if { DemonicFury() - 40 } / 800 > BuffRemaining(demonbolt_buff) / 40 and DemonicFury() >= 750 Spell(touch_of_chaos)
	#cancel_metamorphosis
	if BuffPresent(metamorphosis_buff) Spell(metamorphosis text=cancel)
}

AddFunction DemonologyDbMetaShortCdPostConditions
{
	DemonicFury() > 450 and Enemies() >= 5 and BuffExpires(immolation_aura_buff) and Spell(immolation_aura) or Enemies() >= 6 and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) - GCD() <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } and Spell(doom) or BuffPresent(molten_core_buff) and BuffRemaining(demon_rush_buff) <= 4 and ArmorSetBonus(T18 2) == 1 and Spell(soul_fire) or { BuffStacks(demonbolt_buff) == 0 or BuffStacks(demonbolt_buff) < 4 and BuffRemaining(demonbolt_buff) >= 40 * { 100 / { 100 + SpellHaste() } } - ExecuteTime(demonbolt) } and { ItemCooldown(legendary_ring_intellect) >= BaseDuration(demonbolt_buff) or not ItemCooldown(legendary_ring_intellect) > 0 } and Spell(demonbolt) or target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } and Spell(doom) or BuffPresent(molten_core_buff) and BuffRemaining(demon_rush_buff) <= ExecuteTime(soul_fire) + TravelTime(soul_fire) + ExecuteTime(touch_of_chaos) and ArmorSetBonus(T18 2) == 1 and Spell(soul_fire) or target.DebuffPresent(mark_of_doom_debuff) and Spell(touch_of_chaos) or BuffPresent(dark_soul_knowledge_buff) and Enemies() >= 2 and DemonicFury() > 450 and Spell(chaos_wave) or BuffPresent(molten_core_buff) and { BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(soul_fire) and DemonicFury() >= 175 or target.TimeToDie() < BuffRemaining(demonbolt_buff) } and Spell(soul_fire) or BuffPresent(molten_core_buff) and target.HealthPercent() <= 25 and { DemonicFury() - 80 } / 800 > BuffRemaining(demonbolt_buff) / 40 and DemonicFury() >= 750 and Spell(soul_fire) or BuffPresent(molten_core_buff) and BuffStacks(demon_rush_buff) < 5 and ArmorSetBonus(T18 2) == 1 and Spell(soul_fire) or target.DebuffRemaining(corruption_debuff) < 17.4 and DemonicFury() > 750 and Spell(touch_of_chaos) or { target.TimeToDie() < BuffRemaining(demonbolt_buff) or DemonicFury() >= 750 and BuffPresent(demonbolt_buff) or BuffPresent(dark_soul_knowledge_buff) } and Spell(touch_of_chaos) or { DemonicFury() - 40 } / 800 > BuffRemaining(demonbolt_buff) / 40 and DemonicFury() >= 750 and Spell(touch_of_chaos)
}

AddFunction DemonologyDbMetaCdPostConditions
{
	DemonicFury() > 450 and Enemies() >= 5 and BuffExpires(immolation_aura_buff) and Spell(immolation_aura) or Enemies() >= 6 and target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) - GCD() <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } and Spell(doom) or BuffPresent(molten_core_buff) and BuffRemaining(demon_rush_buff) <= 4 and ArmorSetBonus(T18 2) == 1 and Spell(soul_fire) or { BuffStacks(demonbolt_buff) == 0 or BuffStacks(demonbolt_buff) < 4 and BuffRemaining(demonbolt_buff) >= 40 * { 100 / { 100 + SpellHaste() } } - ExecuteTime(demonbolt) } and { ItemCooldown(legendary_ring_intellect) >= BaseDuration(demonbolt_buff) or not ItemCooldown(legendary_ring_intellect) > 0 } and Spell(demonbolt) or target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { BuffExpires(dark_soul_knowledge_buff) or not Glyph(glyph_of_dark_soul) } and Spell(doom) or BuffPresent(molten_core_buff) and BuffRemaining(demon_rush_buff) <= ExecuteTime(soul_fire) + TravelTime(soul_fire) + ExecuteTime(touch_of_chaos) and ArmorSetBonus(T18 2) == 1 and Spell(soul_fire) or target.DebuffPresent(mark_of_doom_debuff) and Spell(touch_of_chaos) or BuffPresent(dark_soul_knowledge_buff) and Enemies() >= 2 and DemonicFury() > 450 and Spell(chaos_wave) or BuffPresent(molten_core_buff) and { BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(soul_fire) and DemonicFury() >= 175 or target.TimeToDie() < BuffRemaining(demonbolt_buff) } and Spell(soul_fire) or BuffPresent(molten_core_buff) and target.HealthPercent() <= 25 and { DemonicFury() - 80 } / 800 > BuffRemaining(demonbolt_buff) / 40 and DemonicFury() >= 750 and Spell(soul_fire) or BuffPresent(molten_core_buff) and BuffStacks(demon_rush_buff) < 5 and ArmorSetBonus(T18 2) == 1 and Spell(soul_fire) or target.DebuffRemaining(corruption_debuff) < 17.4 and DemonicFury() > 750 and Spell(touch_of_chaos) or { target.TimeToDie() < BuffRemaining(demonbolt_buff) or DemonicFury() >= 750 and BuffPresent(demonbolt_buff) or BuffPresent(dark_soul_knowledge_buff) } and Spell(touch_of_chaos) or { DemonicFury() - 40 } / 800 > BuffRemaining(demonbolt_buff) / 40 and DemonicFury() >= 750 and Spell(touch_of_chaos)
}

### actions.meta

AddFunction DemonologyMetaMainActions
{
	#immolation_aura,if=demonic_fury>450&spell_targets.immolation_aura_tick>=3&buff.immolation_aura.down
	if DemonicFury() > 450 and Enemies() >= 3 and BuffExpires(immolation_aura_buff) Spell(immolation_aura)
	#doom,if=target.time_to_die>=30*spell_haste&remains<=(duration*0.3)&(remains<cooldown.cataclysm.remains|!talent.cataclysm.enabled)&trinket.stacking_proc.any.react<10
	if target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { target.DebuffRemaining(doom_debuff) < SpellCooldown(cataclysm) or not Talent(cataclysm_talent) } and BuffStacks(trinket_stacking_proc_any_buff) < 10 Spell(doom)
	#soul_fire,if=buff.molten_core.react&(buff.demon_rush.remains<=execute_time+travel_time+action.touch_of_chaos.execute_time)&set_bonus.tier18_2pc=1
	if BuffPresent(molten_core_buff) and BuffRemaining(demon_rush_buff) <= ExecuteTime(soul_fire) + TravelTime(soul_fire) + ExecuteTime(touch_of_chaos) and ArmorSetBonus(T18 2) == 1 Spell(soul_fire)
	#chaos_wave,if=buff.dark_soul.remains&(trinket.proc.crit.react|trinket.proc.mastery.react|trinket.proc.intellect.react|trinket.proc.multistrike.react|trinket.stacking_proc.multistrike.react>7)
	if BuffPresent(dark_soul_knowledge_buff) and { BuffPresent(trinket_proc_crit_buff) or BuffPresent(trinket_proc_mastery_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_proc_multistrike_buff) or BuffStacks(trinket_stacking_proc_multistrike_buff) > 7 } Spell(chaos_wave)
	#touch_of_chaos,if=debuff.mark_of_doom.remains
	if target.DebuffPresent(mark_of_doom_debuff) Spell(touch_of_chaos)
	#cancel_metamorphosis,if=((demonic_fury<650&!glyph.dark_soul.enabled)|demonic_fury<450)&buff.dark_soul.down&(trinket.stacking_proc.any.down&trinket.proc.any.down|demonic_fury<(800-cooldown.dark_soul.remains*(10%spell_haste)))&target.time_to_die>20
	if { DemonicFury() < 650 and not Glyph(glyph_of_dark_soul) or DemonicFury() < 450 } and BuffExpires(dark_soul_knowledge_buff) and { BuffExpires(trinket_stacking_proc_any_buff) and BuffExpires(trinket_proc_any_buff) or DemonicFury() < 800 - SpellCooldown(dark_soul_knowledge) * { 10 / { 100 / { 100 + SpellHaste() } } } } and target.TimeToDie() > 20 and BuffPresent(metamorphosis_buff) Spell(metamorphosis text=cancel)
	#cancel_metamorphosis,if=action.hand_of_guldan.charges>0&dot.shadowflame.remains<action.hand_of_guldan.travel_time+action.shadow_bolt.cast_time&((demonic_fury<100&buff.dark_soul.remains>10)|time<15)&!glyph.dark_soul.enabled
	if Charges(hand_of_guldan) > 0 and target.DebuffRemaining(shadowflame_debuff) < TravelTime(hand_of_guldan) + CastTime(shadow_bolt) and { DemonicFury() < 100 and BuffRemaining(dark_soul_knowledge_buff) > 10 or TimeInCombat() < 15 } and not Glyph(glyph_of_dark_soul) and BuffPresent(metamorphosis_buff) Spell(metamorphosis text=cancel)
	#cancel_metamorphosis,if=action.hand_of_guldan.charges=3&(!buff.dark_soul.remains>gcd|action.metamorphosis.cooldown<gcd)
	if Charges(hand_of_guldan) == 3 and { not BuffRemaining(dark_soul_knowledge_buff) > GCD() or SpellCooldown(metamorphosis) < GCD() } and BuffPresent(metamorphosis_buff) Spell(metamorphosis text=cancel)
	#chaos_wave,if=buff.dark_soul.up&spell_targets.chaos_wave>=2|(charges=3|set_bonus.tier17_4pc=0&charges=2)
	if BuffPresent(dark_soul_knowledge_buff) and Enemies() >= 2 or Charges(chaos_wave) == 3 or ArmorSetBonus(T17 4) == 0 and Charges(chaos_wave) == 2 Spell(chaos_wave)
	#soul_fire,if=buff.molten_core.react&(buff.dark_soul.remains>execute_time|target.health.pct<=25|trinket.proc.crit.react|trinket.proc.mastery.react|trinket.proc.intellect.react|trinket.proc.multistrike.react)
	if BuffPresent(molten_core_buff) and { BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(soul_fire) or target.HealthPercent() <= 25 or BuffPresent(trinket_proc_crit_buff) or BuffPresent(trinket_proc_mastery_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_proc_multistrike_buff) } Spell(soul_fire)
	#soul_fire,if=buff.molten_core.react&trinket.stacking_proc.multistrike.react&trinket.stacking_proc.multistrike.remains<=buff.molten_core.react*cast_time&trinket.stacking_proc.multistrike.remains<=demonic_fury%(80%cast_time)
	if BuffPresent(molten_core_buff) and BuffPresent(trinket_stacking_proc_multistrike_buff) and BuffRemaining(trinket_stacking_proc_multistrike_buff) <= BuffStacks(molten_core_buff) * CastTime(soul_fire) and BuffRemaining(trinket_stacking_proc_multistrike_buff) <= DemonicFury() / { 80 / CastTime(soul_fire) } Spell(soul_fire)
	#soul_fire,if=buff.molten_core.react&buff.demon_rush.stack<5&set_bonus.tier18_2pc=1
	if BuffPresent(molten_core_buff) and BuffStacks(demon_rush_buff) < 5 and ArmorSetBonus(T18 2) == 1 Spell(soul_fire)
	#touch_of_chaos,cycle_targets=1,if=dot.corruption.remains<17.4&demonic_fury>750
	if target.DebuffRemaining(corruption_debuff) < 17.4 and DemonicFury() > 750 Spell(touch_of_chaos)
	#touch_of_chaos
	Spell(touch_of_chaos)
	#cancel_metamorphosis
	if BuffPresent(metamorphosis_buff) Spell(metamorphosis text=cancel)
}

AddFunction DemonologyMetaShortCdActions
{
	#kiljaedens_cunning,if=!cooldown.cataclysm.remains
	if not SpellCooldown(cataclysm) > 0 Spell(kiljaedens_cunning)
	#cataclysm,if=(active_enemies=1|spell_targets.cataclysm>1)
	if Enemies() == 1 or Enemies() > 1 Spell(cataclysm)
}

AddFunction DemonologyMetaCdPostConditions
{
	DemonicFury() > 450 and Enemies() >= 3 and BuffExpires(immolation_aura_buff) and Spell(immolation_aura) or target.TimeToDie() >= 30 * { 100 / { 100 + SpellHaste() } } and target.DebuffRemaining(doom_debuff) <= BaseDuration(doom_debuff) * 0.3 and { target.DebuffRemaining(doom_debuff) < SpellCooldown(cataclysm) or not Talent(cataclysm_talent) } and BuffStacks(trinket_stacking_proc_any_buff) < 10 and Spell(doom) or BuffPresent(molten_core_buff) and BuffRemaining(demon_rush_buff) <= ExecuteTime(soul_fire) + TravelTime(soul_fire) + ExecuteTime(touch_of_chaos) and ArmorSetBonus(T18 2) == 1 and Spell(soul_fire) or BuffPresent(dark_soul_knowledge_buff) and { BuffPresent(trinket_proc_crit_buff) or BuffPresent(trinket_proc_mastery_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_proc_multistrike_buff) or BuffStacks(trinket_stacking_proc_multistrike_buff) > 7 } and Spell(chaos_wave) or target.DebuffPresent(mark_of_doom_debuff) and Spell(touch_of_chaos) or { BuffPresent(dark_soul_knowledge_buff) and Enemies() >= 2 or Charges(chaos_wave) == 3 or ArmorSetBonus(T17 4) == 0 and Charges(chaos_wave) == 2 } and Spell(chaos_wave) or BuffPresent(molten_core_buff) and { BuffRemaining(dark_soul_knowledge_buff) > ExecuteTime(soul_fire) or target.HealthPercent() <= 25 or BuffPresent(trinket_proc_crit_buff) or BuffPresent(trinket_proc_mastery_buff) or BuffPresent(trinket_proc_intellect_buff) or BuffPresent(trinket_proc_multistrike_buff) } and Spell(soul_fire) or BuffPresent(molten_core_buff) and BuffPresent(trinket_stacking_proc_multistrike_buff) and BuffRemaining(trinket_stacking_proc_multistrike_buff) <= BuffStacks(molten_core_buff) * CastTime(soul_fire) and BuffRemaining(trinket_stacking_proc_multistrike_buff) <= DemonicFury() / { 80 / CastTime(soul_fire) } and Spell(soul_fire) or BuffPresent(molten_core_buff) and BuffStacks(demon_rush_buff) < 5 and ArmorSetBonus(T18 2) == 1 and Spell(soul_fire) or target.DebuffRemaining(corruption_debuff) < 17.4 and DemonicFury() > 750 and Spell(touch_of_chaos) or Spell(touch_of_chaos)
}

### actions.opener

AddFunction DemonologyOpenerMainActions
{
	#hand_of_guldan,if=!in_flight&!dot.shadowflame.ticking
	if not InFlightToTarget(hand_of_guldan) and not target.DebuffPresent(shadowflame_debuff) Spell(hand_of_guldan)
	#corruption,if=!ticking
	if not target.DebuffPresent(corruption_debuff) Spell(corruption)
}

AddFunction DemonologyOpenerShortCdActions
{
	unless not InFlightToTarget(hand_of_guldan) and not target.DebuffPresent(shadowflame_debuff) and Spell(hand_of_guldan)
	{
		#service_pet,if=talent.grimoire_of_service.enabled
		if Talent(grimoire_of_service_talent) Spell(service_felguard)
	}
}

AddFunction DemonologyOpenerShortCdPostConditions
{
	not InFlightToTarget(hand_of_guldan) and not target.DebuffPresent(shadowflame_debuff) and Spell(hand_of_guldan) or not target.DebuffPresent(corruption_debuff) and Spell(corruption)
}

AddFunction DemonologyOpenerCdPostConditions
{
	not InFlightToTarget(hand_of_guldan) and not target.DebuffPresent(shadowflame_debuff) and Spell(hand_of_guldan) or Talent(grimoire_of_service_talent) and Spell(service_felguard) or not target.DebuffPresent(corruption_debuff) and Spell(corruption)
}

### actions.precombat

AddFunction DemonologyPrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=sleeper_sushi
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
		#summon_doomguard,if=talent.demonic_servitude.enabled&active_enemies<9
		if Talent(demonic_servitude_talent) and Enemies() < 9 Spell(summon_doomguard)
		#summon_infernal,if=talent.demonic_servitude.enabled&active_enemies>=9
		if Talent(demonic_servitude_talent) and Enemies() >= 9 Spell(summon_infernal)
		#snapshot_stats
		#potion,name=draenic_intellect
		DemonologyUsePotionIntellect()
	}
}

AddFunction DemonologyPrecombatCdPostConditions
{
	not BuffPresent(spell_power_multiplier_buff any=1) and Spell(dark_intent) or not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() and Spell(summon_felguard) or Spell(soul_fire)
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

### Required symbols
# arcane_torrent_mana
# archimondes_darkness_talent
# berserking
# blood_fury_sp
# cancel_metamorphosis
# cataclysm
# cataclysm_talent
# chaos_wave
# corruption
# corruption_debuff
# dark_intent
# dark_soul_knowledge
# dark_soul_knowledge_buff
# demon_rush_buff
# demonbolt
# demonbolt_buff
# demonbolt_talent
# demonic_servitude_talent
# doom
# doom_debuff
# draenic_intellect_potion
# felguard_felstorm
# glyph_of_dark_soul
# grimoire_of_sacrifice_buff
# grimoire_of_sacrifice_talent
# grimoire_of_service_talent
# hand_of_guldan
# hellfire
# immolation_aura
# immolation_aura_buff
# imp_swarm
# kiljaedens_cunning
# legendary_ring_intellect
# life_tap
# mannoroths_fury
# mark_of_doom_debuff
# metamorphosis
# metamorphosis_buff
# molten_core_buff
# nithramus_buff
# service_doomguard
# service_felguard
# shadow_bolt
# shadowflame_debuff
# soul_fire
# summon_doomguard
# summon_felguard
# summon_infernal
# touch_of_chaos
# wrathguard_mortal_cleave
# wrathguard_wrathstorm
]]
	OvaleScripts:RegisterScript("WARLOCK", "demonology", name, desc, code, "script")
end
