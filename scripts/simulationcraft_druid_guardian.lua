local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Druid_Guardian_T16M"
	local desc = "[6.0.2] SimulationCraft: Druid_Guardian_T16M"
	local code = [[
# Based on SimulationCraft profile "Druid_Guardian_T16M".
#	class=druid
#	spec=guardian
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Ub!.0.0.1.

Include(ovale_common)
Include(ovale_druid_spells)

AddFunction InterruptActions
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.InRange(skull_bash) Spell(skull_bash)
		if target.Classification(worldboss no)
		{
			if Talent(mighty_bash_talent) and target.InRange(mighty_bash) Spell(mighty_bash)
			if Talent(typhoon_talent) and target.InRange(skull_bash) Spell(typhoon)
			if Stance(druid_cat_form) and target.InRange(maim) Spell(maim)
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
	#barkskin
	Spell(barkskin)
	#maul,if=buff.tooth_and_claw.react&incoming_damage_1s&rage>=80
	if BuffPresent(tooth_and_claw_buff) and IncomingDamage(1) and Rage() >= 80 Spell(maul)
	#cenarion_ward
	Spell(cenarion_ward)
	#renewal,if=health.pct<30
	if HealthPercent() < 30 Spell(renewal)
	#heart_of_the_wild
	Spell(heart_of_the_wild)
	#rejuvenation,if=!ticking&buff.heart_of_the_wild.up
	if not target.DebuffPresent(rejuvenation_debuff) and BuffPresent(heart_of_the_wild_buff) Spell(rejuvenation)
	#natures_vigil
	Spell(natures_vigil)
	#healing_touch,if=buff.dream_of_cenarius.react&health.pct<30
	if BuffPresent(dream_of_cenarius_buff) and HealthPercent() < 30 Spell(healing_touch)
	#pulverize,if=buff.pulverize.remains<0.5
	if BuffRemaining(pulverize_buff) < 0.5 Spell(pulverize)
	#lacerate,if=talent.pulverize.enabled&buff.pulverize.remains<=(3-dot.lacerate.stack)*gcd
	if Talent(pulverize_talent) and BuffRemaining(pulverize_buff) <= { 3 - FIXME_dot.lacerate.stack } * GCD() Spell(lacerate)
	#incarnation
	Spell(incarnation)
	#mangle,if=buff.son_of_ursoc.down
	if BuffExpires(son_of_ursoc_buff) Spell(mangle)
	#thrash_bear,if=!ticking
	if not target.DebuffPresent(thrash_bear_debuff) Spell(thrash_bear)
	#mangle
	Spell(mangle)
	#lacerate
	Spell(lacerate)
}

AddFunction GuardianPrecombatActions
{
	#elixir,type=mad_hozen
	#elixir,type=mantid
	#food,type=seafood_magnifique_feast
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#bear_form
	if not Stance(druid_bear_form) Spell(bear_form)
	#snapshot_stats
	#cenarion_ward
	Spell(cenarion_ward)
}

AddIcon specialization=guardian help=main enemies=1
{
	if InCombat(no) GuardianPrecombatActions()
	GuardianDefaultActions()
}

AddIcon specialization=guardian help=aoe
{
	if InCombat(no) GuardianPrecombatActions()
	GuardianDefaultActions()
}

### Required symbols
# arcane_torrent_energy
# barkskin
# bear_form
# berserking
# blood_fury_apsp
# cenarion_ward
# dream_of_cenarius_buff
# healing_touch
# heart_of_the_wild
# heart_of_the_wild_buff
# incarnation
# lacerate
# maim
# mangle
# mark_of_the_wild
# maul
# mighty_bash
# mighty_bash_talent
# natures_vigil
# pulverize
# pulverize_buff
# pulverize_talent
# rejuvenation
# rejuvenation_debuff
# renewal
# savage_defense
# skull_bash
# son_of_ursoc_buff
# thrash_bear
# thrash_bear_debuff
# tooth_and_claw_buff
# typhoon
# typhoon_talent
# war_stomp
]]
	OvaleScripts:RegisterScript("DRUID", name, desc, code, "reference")
end
