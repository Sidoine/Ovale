local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Druid_Guardian_T17M"
	local desc = "[6.0] SimulationCraft: Druid_Guardian_T17M"
	local code = [[
# Based on SimulationCraft profile "Druid_Guardian_T17M".
#	class=druid
#	spec=guardian
#	talents=0301022

Include(ovale_common)
Include(ovale_druid_spells)

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction GetInMeleeRange
{
	if Stance(druid_bear_form) and not target.InRange(mangle) or Stance(druid_cat_form) and not target.InRange(shred)
	{
		if target.InRange(wild_charge) Spell(wild_charge)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
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

AddFunction GuardianDefaultActions
{
	#auto_attack
	#skull_bash
	InterruptActions()
	#savage_defense
	Spell(savage_defense)
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_energy)
	#use_item,slot=trinket2
	UseItemActions()
	#barkskin
	Spell(barkskin)
	#maul,if=buff.tooth_and_claw.react&incoming_damage_1s
	if BuffPresent(tooth_and_claw_buff) and IncomingDamage(1) > 0 Spell(maul)
	#berserk,if=buff.pulverize.remains>10
	if BuffRemaining(pulverize_buff) > 10 Spell(berserk_bear)
	#frenzied_regeneration,if=rage>=80
	if Rage() >= 80 Spell(frenzied_regeneration)
	#cenarion_ward
	Spell(cenarion_ward)
	#renewal,if=health.pct<30
	if HealthPercent() < 30 Spell(renewal)
	#heart_of_the_wild
	Spell(heart_of_the_wild_tank)
	#rejuvenation,if=buff.heart_of_the_wild.up&remains<=0.3*duration
	if BuffPresent(heart_of_the_wild_tank_buff) and BuffRemaining(rejuvenation_buff) <= 0.3 * BaseDuration(rejuvenation_buff) and SpellKnown(enhanced_rejuvenation) Spell(rejuvenation)
	#natures_vigil
	Spell(natures_vigil)
	#healing_touch,if=buff.dream_of_cenarius.react&health.pct<30
	if BuffPresent(dream_of_cenarius_tank_buff) and HealthPercent() < 30 Spell(healing_touch)
	#pulverize,if=buff.pulverize.remains<0.5
	if BuffRemaining(pulverize_buff) < 0.5 and target.DebuffStacks(lacerate_debuff) >= 3 Spell(pulverize)
	#lacerate,if=talent.pulverize.enabled&buff.pulverize.remains<=(3-dot.lacerate.stack)*gcd&buff.berserk.down
	if Talent(pulverize_talent) and BuffRemaining(pulverize_buff) <= { 3 - target.DebuffStacks(lacerate_debuff) } * GCD() and BuffExpires(berserk_bear_buff) Spell(lacerate)
	#incarnation
	Spell(incarnation_tank)
	#lacerate,if=!ticking
	if not target.DebuffPresent(lacerate_debuff) Spell(lacerate)
	#thrash_bear,if=!ticking
	if not target.DebuffPresent(thrash_bear_debuff) Spell(thrash_bear)
	#mangle
	Spell(mangle)
	#thrash_bear,if=remains<=0.3*duration
	if target.DebuffRemaining(thrash_bear_debuff) <= 0.3 * BaseDuration(thrash_bear_debuff) Spell(thrash_bear)
	#lacerate
	Spell(lacerate)
}

AddFunction GuardianPrecombatActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=sleeper_surprise
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#bear_form
	Spell(bear_form)
	#snapshot_stats
	#cenarion_ward
	Spell(cenarion_ward)
}

AddIcon specialization=guardian help=main enemies=1
{
	if not InCombat() GuardianPrecombatActions()
	GuardianDefaultActions()
}

AddIcon specialization=guardian help=aoe
{
	if not InCombat() GuardianPrecombatActions()
	GuardianDefaultActions()
}

### Required symbols
# arcane_torrent_energy
# barkskin
# bear_form
# berserk_bear
# berserk_bear_buff
# berserking
# blood_fury_apsp
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
# shred
# skull_bash
# thrash_bear
# thrash_bear_debuff
# tooth_and_claw_buff
# typhoon
# war_stomp
# wild_charge_bear
# wild_charge_cat
]]
	OvaleScripts:RegisterScript("DRUID", name, desc, code, "reference")
end
