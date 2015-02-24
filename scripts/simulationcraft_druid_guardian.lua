local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_druid_guardian_t17m"
	local desc = "[6.1] SimulationCraft: Druid_Guardian_T17M"
	local code = [[
# Based on SimulationCraft profile "Druid_Guardian_T17M".
#	class=druid
#	spec=guardian
#	talents=0301022

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=guardian)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=guardian)

AddFunction GuardianUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction GuardianGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred)
	{
		if target.InRange(wild_charge) Spell(wild_charge)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction GuardianInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(skull_bash) Spell(skull_bash)
		if not target.Classification(worldboss)
		{
			if target.InRange(mighty_bash) Spell(mighty_bash)
			Spell(typhoon)
			if target.InRange(maim) Spell(maim)
			Spell(war_stomp)
		}
	}
}

### actions.default

AddFunction GuardianDefaultMainActions
{
	#cenarion_ward
	Spell(cenarion_ward)
	#rejuvenation,if=buff.heart_of_the_wild.up&remains<=3.6
	if BuffPresent(heart_of_the_wild_tank_buff) and BuffRemaining(rejuvenation_buff) <= 3.6 and SpellKnown(enhanced_rejuvenation) Spell(rejuvenation)
	#healing_touch,if=buff.dream_of_cenarius.react&health.pct<30
	if BuffPresent(dream_of_cenarius_tank_buff) and HealthPercent() < 30 Spell(healing_touch)
	#pulverize,if=buff.pulverize.remains<=3.6
	if BuffRemaining(pulverize_buff) <= 3.6 and target.DebuffGain(lacerate_debuff) <= BaseDuration(lacerate_debuff) Spell(pulverize)
	#lacerate,if=talent.pulverize.enabled&buff.pulverize.remains<=(3-dot.lacerate.stack)*gcd&buff.berserk.down
	if Talent(pulverize_talent) and BuffRemaining(pulverize_buff) <= { 3 - target.DebuffStacks(lacerate_debuff) } * GCD() and BuffExpires(berserk_bear_buff) Spell(lacerate)
	#lacerate,if=!ticking
	if not target.DebuffPresent(lacerate_debuff) Spell(lacerate)
	#thrash_bear,if=!ticking
	if not target.DebuffPresent(thrash_bear_debuff) Spell(thrash_bear)
	#mangle
	Spell(mangle)
	#thrash_bear,if=remains<=4.8
	if target.DebuffRemaining(thrash_bear_debuff) <= 4.8 Spell(thrash_bear)
	#lacerate
	Spell(lacerate)
}

AddFunction GuardianDefaultShortCdActions
{
	#auto_attack
	GuardianGetInMeleeRange()
	#savage_defense,if=buff.barkskin.down
	if BuffExpires(barkskin_buff) Spell(savage_defense)
	#maul,if=buff.tooth_and_claw.react&incoming_damage_1s
	if BuffPresent(tooth_and_claw_buff) and IncomingDamage(1) > 0 Spell(maul)
	#frenzied_regeneration,if=rage>=80
	if Rage() >= 80 Spell(frenzied_regeneration)
}

AddFunction GuardianDefaultCdActions
{
	#skull_bash
	GuardianInterruptActions()
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_energy)
	#use_item,slot=trinket2
	GuardianUseItemActions()
	#barkskin,if=buff.bristling_fur.down
	if BuffExpires(bristling_fur_buff) Spell(barkskin)
	#bristling_fur,if=buff.barkskin.down&buff.savage_defense.down
	if BuffExpires(barkskin_buff) and BuffExpires(savage_defense_buff) Spell(bristling_fur)
	#berserk,if=buff.pulverize.remains>10
	if BuffRemaining(pulverize_buff) > 10 Spell(berserk_bear)

	unless Spell(cenarion_ward)
	{
		#renewal,if=health.pct<30
		if HealthPercent() < 30 Spell(renewal)
		#heart_of_the_wild
		Spell(heart_of_the_wild_tank)

		unless BuffPresent(heart_of_the_wild_tank_buff) and BuffRemaining(rejuvenation_buff) <= 3.6 and SpellKnown(enhanced_rejuvenation) and Spell(rejuvenation)
		{
			#natures_vigil
			Spell(natures_vigil)

			unless BuffPresent(dream_of_cenarius_tank_buff) and HealthPercent() < 30 and Spell(healing_touch) or BuffRemaining(pulverize_buff) <= 3.6 and target.DebuffGain(lacerate_debuff) <= BaseDuration(lacerate_debuff) and Spell(pulverize) or Talent(pulverize_talent) and BuffRemaining(pulverize_buff) <= { 3 - target.DebuffStacks(lacerate_debuff) } * GCD() and BuffExpires(berserk_bear_buff) and Spell(lacerate)
			{
				#incarnation
				Spell(incarnation_tank)
			}
		}
	}
}

### actions.precombat

AddFunction GuardianPrecombatMainActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=sleeper_sushi
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#bear_form
	Spell(bear_form)
	#snapshot_stats
	#cenarion_ward
	Spell(cenarion_ward)
}

AddFunction GuardianPrecombatShortCdPostConditions
{
	not BuffPresent(str_agi_int_buff any=1) and Spell(mark_of_the_wild) or Spell(bear_form) or Spell(cenarion_ward)
}

AddFunction GuardianPrecombatCdPostConditions
{
	not BuffPresent(str_agi_int_buff any=1) and Spell(mark_of_the_wild) or Spell(bear_form) or Spell(cenarion_ward)
}

### Guardian icons.

AddCheckBox(opt_druid_guardian_aoe L(AOE) default specialization=guardian)

AddIcon checkbox=!opt_druid_guardian_aoe enemies=1 help=shortcd specialization=guardian
{
	unless not InCombat() and GuardianPrecombatShortCdPostConditions()
	{
		GuardianDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_druid_guardian_aoe help=shortcd specialization=guardian
{
	unless not InCombat() and GuardianPrecombatShortCdPostConditions()
	{
		GuardianDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=guardian
{
	if not InCombat() GuardianPrecombatMainActions()
	GuardianDefaultMainActions()
}

AddIcon checkbox=opt_druid_guardian_aoe help=aoe specialization=guardian
{
	if not InCombat() GuardianPrecombatMainActions()
	GuardianDefaultMainActions()
}

AddIcon checkbox=!opt_druid_guardian_aoe enemies=1 help=cd specialization=guardian
{
	unless not InCombat() and GuardianPrecombatCdPostConditions()
	{
		GuardianDefaultCdActions()
	}
}

AddIcon checkbox=opt_druid_guardian_aoe help=cd specialization=guardian
{
	unless not InCombat() and GuardianPrecombatCdPostConditions()
	{
		GuardianDefaultCdActions()
	}
}

### Required symbols
# arcane_torrent_energy
# barkskin
# barkskin_buff
# bear_form
# berserk_bear
# berserk_bear_buff
# berserking
# blood_fury_apsp
# bristling_fur
# bristling_fur_buff
# cenarion_ward
# dream_of_cenarius_tank_buff
# enhanced_rejuvenation
# frenzied_regeneration
# healing_touch
# heart_of_the_wild_tank
# heart_of_the_wild_tank_buff
# incarnation_tank
# lacerate
# lacerate_debuff
# maim
# mangle
# mark_of_the_wild
# maul
# mighty_bash
# natures_vigil
# pulverize
# pulverize_buff
# pulverize_talent
# rejuvenation
# rejuvenation_buff
# renewal
# savage_defense
# savage_defense_buff
# shred
# skull_bash
# thrash_bear
# thrash_bear_debuff
# tooth_and_claw_buff
# typhoon
# war_stomp
# wild_charge
# wild_charge_bear
# wild_charge_cat
]]
	OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
end
