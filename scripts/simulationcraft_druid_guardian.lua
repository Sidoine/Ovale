local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Druid_Guardian_T16M"
	local desc = "[6.0.2] SimulationCraft: Druid_Guardian_T16M"
	local code = [[
# Based on SimulationCraft profile "Druid_Guardian_T16M".
#	class=druid
#	spec=guardian
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Ub!.1.0.1.
#	glyphs=maul

Include(ovale_common)
Include(ovale_druid_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction GetInMeleeRange
{
	if Stance(druid_bear_form) and not target.InRange(mangle)
	{
		if target.InRange(wild_charge_bear) Spell(wild_charge_bear)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
	if Stance(druid_cat_form) and not target.InRange(shred)
	{
		if target.InRange(wild_charge_cat) Spell(wild_charge_cat)
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
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_energy)
	#potion,name=tolvir,if=buff.berserking.up|buff.berserk.up
	if BuffPresent(berserking_buff) or BuffPresent(berserk_bear_buff) UsePotionAgility()
	#skull_bash
	InterruptActions()
	#barkskin
	Spell(barkskin)
	#survival_instincts,if=health.pct<50
	if HealthPercent() < 50 Spell(survival_instincts)
	#savage_defense,if=buff.savage_defense.down
	if BuffExpires(savage_defense_buff) Spell(savage_defense)
	#frenzied_regeneration,if=health.pct<40
	if HealthPercent() < 40 Spell(frenzied_regeneration)
	#maul
	Spell(maul)
	#force_of_nature,if=charges=3|trinket.proc.all.react|target.time_to_die<20
	if Charges(force_of_nature_tank) == 3 or BuffPresent(trinket_proc_agility_buff) or target.TimeToDie() < 20 Spell(force_of_nature_tank)
	#berserk,if=dot.thrash_bear.remains>10&dot.lacerate.stack=3&dot.lacerate.remains>10&buff.son_of_ursoc.down
	if target.DebuffRemaining(thrash_bear_debuff) > 10 and target.DebuffStacks(lacerate_debuff) == 3 and target.DebuffRemaining(lacerate_debuff) > 10 and BuffExpires(son_of_ursoc_buff) Spell(berserk_bear)
	#renewal,if=health.pct<30
	if HealthPercent() < 30 Spell(renewal)
	#natures_vigil
	Spell(natures_vigil)
	#heart_of_the_wild
	Spell(heart_of_the_wild_tank)
	#cenarion_ward
	Spell(cenarion_ward)
	#lacerate,cycle_targets=1,if=dot.lacerate.ticking&dot.lacerate.remains<2
	if target.DebuffPresent(lacerate_debuff) and target.DebuffRemaining(lacerate_debuff) < 2 Spell(lacerate)
	#mangle,if=active_enemies<4
	if Enemies() < 4 Spell(mangle)
	#thrash_bear,if=dot.thrash_bear.remains<1
	if target.DebuffRemaining(thrash_bear_debuff) < 1 Spell(thrash_bear)
	#healing_touch,if=buff.dream_of_cenarius.react&health.pct<10
	if BuffPresent(dream_of_cenarius_tank_buff) and HealthPercent() < 10 Spell(healing_touch)
	#thrash_bear,if=active_enemies>4
	if Enemies() > 4 Spell(thrash_bear)
	#lacerate,cycle_targets=1,if=!dot.lacerate.ticking
	if not target.DebuffPresent(lacerate_debuff) Spell(lacerate)
	#lacerate,cycle_targets=1,if=dot.lacerate.stack<3
	if target.DebuffStacks(lacerate_debuff) < 3 Spell(lacerate)
	#thrash_bear,if=active_enemies>1
	if Enemies() > 1 Spell(thrash_bear)
	#lacerate
	Spell(lacerate)
}

AddFunction GuardianPrecombatActions
{
	#flask,type=winds
	#food,type=seafood_magnifique_feast
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#bear_form
	Spell(bear_form)
	#snapshot_stats
	#rejuvenation
	if SpellKnown(enhanced_rejuvenation) Spell(rejuvenation)
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
# berserking_buff
# blood_fury_apsp
# cenarion_ward
# dream_of_cenarius_tank_buff
# enhanced_rejuvenation
# force_of_nature_tank
# frenzied_regeneration
# healing_touch
# heart_of_the_wild_tank
# lacerate
# lacerate_debuff
# maim
# mangle
# mark_of_the_wild
# maul
# mighty_bash
# natures_vigil
# rejuvenation
# renewal
# savage_defense
# savage_defense_buff
# shred
# skull_bash
# son_of_ursoc_buff
# survival_instincts
# thrash_bear
# thrash_bear_debuff
# trinket_proc_agility_buff
# typhoon
# virmens_bite_potion
# war_stomp
# wild_charge_bear
# wild_charge_cat
]]
	OvaleScripts:RegisterScript("DRUID", name, desc, code, "reference")
end
