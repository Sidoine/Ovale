local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Druid_Feral_T16M"
	local desc = "[6.0.2] SimulationCraft: Druid_Feral_T16M"
	local code = [[
# Based on SimulationCraft profile "Druid_Feral_T16M".
#	class=druid
#	spec=feral
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#UZ!...0...
#	glyphs=savage_roar

Include(ovale_common)
Include(ovale_druid_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
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

AddFunction FeralDefaultActions
{
	#rake,if=buff.prowl.up|buff.shadowmeld.up
	if BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) Spell(rake)
	#auto_attack
	#skull_bash
	InterruptActions()
	#force_of_nature,if=charges=3|trinket.proc.all.react|target.time_to_die<20
	if Charges(force_of_nature_melee) == 3 or BuffPresent(trinket_proc_agility_buff) or target.TimeToDie() < 20 Spell(force_of_nature_melee)
	#potion,name=tolvir,if=target.time_to_die<=40
	if target.TimeToDie() <= 40 UsePotionAgility()
	#blood_fury,sync=tigers_fury
	if not SpellCooldown(tigers_fury) > 0 Spell(blood_fury_apsp)
	#berserking,sync=tigers_fury
	if not SpellCooldown(tigers_fury) > 0 Spell(berserking)
	#arcane_torrent,sync=tigers_fury
	if not SpellCooldown(tigers_fury) > 0 Spell(arcane_torrent_energy)
	#incarnation,sync=tigers_fury
	if not SpellCooldown(tigers_fury) > 0 Spell(incarnation_melee)
	#tigers_fury,if=(!buff.omen_of_clarity.react&energy.max-energy>=60)|energy.max-energy>=80
	if not BuffPresent(omen_of_clarity_melee_buff) and MaxEnergy() - Energy() >= 60 or MaxEnergy() - Energy() >= 80 Spell(tigers_fury)
	#berserk,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) Spell(berserk_cat)
	#shadowmeld,if=(buff.bloodtalons.up|!talent.bloodtalons.enabled)&dot.rake.remains<0.3*dot.rake.duration
	if { BuffPresent(bloodtalons_buff) or not Talent(bloodtalons_talent) } and target.DebuffRemaining(rake_debuff) < 0.3 * target.DebuffDuration(rake_debuff) Spell(shadowmeld)
	#ferocious_bite,cycle_targets=1,if=dot.rip.ticking&dot.rip.remains<=3&target.health.pct<25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) <= 3 and target.HealthPercent() < 25 Spell(ferocious_bite)
	#healing_touch,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&(combo_points>=4|buff.predatory_swiftness.remains<1.5)
	if Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and { ComboPoints() >= 4 or BuffRemaining(predatory_swiftness_buff) < 1.5 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.remains<3
	if BuffRemaining(savage_roar_buff) < 3 Spell(savage_roar)
	#potion,name=tolvir,sync=berserk,if=target.health.pct<25
	if target.HealthPercent() < 25 and not SpellCooldown(berserk_cat) > 0 UsePotionAgility()
	#thrash_cat,if=buff.omen_of_clarity.react&remains<=duration*0.3&active_enemies>1
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemaining(thrash_cat_debuff) <= target.DebuffDurationIfApplied(thrash_cat_debuff) * 0.3 and Enemies() > 1 Spell(thrash_cat)
	#ferocious_bite,cycle_targets=1,if=combo_points=5&target.health.pct<25&dot.rip.ticking
	if ComboPoints() == 5 and target.HealthPercent() < 25 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
	#rip,cycle_targets=1,if=combo_points=5&remains<=3
	if ComboPoints() == 5 and target.DebuffRemaining(rip_debuff) <= 3 Spell(rip)
	#rip,cycle_targets=1,if=combo_points=5&remains<=duration*0.3&persistent_multiplier>dot.rip.pmultiplier
	if ComboPoints() == 5 and target.DebuffRemaining(rip_debuff) <= target.DebuffDurationIfApplied(rip_debuff) * 0.3 and DamageMultiplier(rip) > target.DebuffDamageMultiplier(rip_debuff) Spell(rip)
	#savage_roar,if=combo_points=5&(energy.time_to_max<=1|buff.berserk.up|cooldown.tigers_fury.remains<3)&buff.savage_roar.remains<42*0.3
	if ComboPoints() == 5 and { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) or SpellCooldown(tigers_fury) < 3 } and BuffRemaining(savage_roar_buff) < 42 * 0.3 Spell(savage_roar)
	#ferocious_bite,if=combo_points=5&(energy.time_to_max<=1|buff.berserk.up|cooldown.tigers_fury.remains<3)
	if ComboPoints() == 5 and { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) or SpellCooldown(tigers_fury) < 3 } Spell(ferocious_bite)
	#rake,cycle_targets=1,if=remains<=3&combo_points<5
	if target.DebuffRemaining(rake_debuff) <= 3 and ComboPoints() < 5 Spell(rake)
	#rake,cycle_targets=1,if=remains<=duration*0.3&combo_points<5&persistent_multiplier>dot.rake.pmultiplier
	if target.DebuffRemaining(rake_debuff) <= target.DebuffDurationIfApplied(rake_debuff) * 0.3 and ComboPoints() < 5 and DamageMultiplier(rake) > target.DebuffDamageMultiplier(rake_debuff) Spell(rake)
	#pool_resource,for_next=1
	#thrash_cat,if=remains<=duration*0.3&active_enemies>1
	if target.DebuffRemaining(thrash_cat_debuff) <= target.DebuffDurationIfApplied(thrash_cat_debuff) * 0.3 and Enemies() > 1 Spell(thrash_cat)
	unless target.DebuffRemaining(thrash_cat_debuff) <= target.DebuffDurationIfApplied(thrash_cat_debuff) * 0.3 and Enemies() > 1 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
	{
		#rake,cycle_targets=1,if=persistent_multiplier>dot.rake.pmultiplier&combo_points<5
		if DamageMultiplier(rake) > target.DebuffDamageMultiplier(rake_debuff) and ComboPoints() < 5 Spell(rake)
		#swipe,if=combo_points<5&active_enemies>=3
		if ComboPoints() < 5 and Enemies() >= 3 Spell(swipe)
		#shred,if=combo_points<5&active_enemies<3
		if ComboPoints() < 5 and Enemies() < 3 Spell(shred)
	}
}

AddFunction FeralPrecombatActions
{
	#flask,type=winds
	#food,type=seafood_magnifique_feast
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#cat_form
	Spell(cat_form)
	#prowl
	if BuffExpires(stealthed_buff any=1) Spell(prowl)
	#snapshot_stats
	#potion,name=tolvir
	UsePotionAgility()
}

AddIcon specialization=feral help=main enemies=1
{
	if not InCombat() FeralPrecombatActions()
	FeralDefaultActions()
}

AddIcon specialization=feral help=aoe
{
	if not InCombat() FeralPrecombatActions()
	FeralDefaultActions()
}

### Required symbols
# arcane_torrent_energy
# berserk_cat
# berserk_cat_buff
# berserking
# blood_fury_apsp
# bloodtalons_buff
# bloodtalons_talent
# cat_form
# ferocious_bite
# force_of_nature_melee
# healing_touch
# incarnation_melee
# maim
# mark_of_the_wild
# mighty_bash
# mighty_bash_talent
# omen_of_clarity_melee_buff
# predatory_swiftness_buff
# prowl
# prowl_buff
# rake
# rake_debuff
# rip
# rip_debuff
# savage_roar
# savage_roar_buff
# shadowmeld
# shadowmeld_buff
# shred
# skull_bash
# swipe
# thrash_cat
# thrash_cat_debuff
# tigers_fury
# tigers_fury_buff
# trinket_proc_agility_buff
# typhoon
# typhoon_talent
# virmens_bite_potion
# war_stomp
]]
	OvaleScripts:RegisterScript("DRUID", name, desc, code, "reference")
end
