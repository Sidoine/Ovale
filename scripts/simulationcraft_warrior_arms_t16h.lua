local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Warrior_Arms_T16H"
	local desc = "[5.4] SimulationCraft: Warrior_Arms_T16H"
	local code = [[
# Based on SimulationCraft profile "Warrior_Arms_T16H".
#	class=warrior
#	spec=arms
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Za!122011
#	glyphs=unending_rage/death_from_above/sweeping_strikes/resonating_power

Include(ovale_common)
Include(ovale_warrior_spells)

AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default)
AddCheckBox(opt_heroic_leap_dps SpellName(heroic_leap) specialization=!protection)
AddCheckBox(opt_skull_banner SpellName(skull_banner) default)

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction ArmsPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#snapshot_stats
	#stance,choose=battle
	if not Stance(warrior_battle_stance) Spell(battle_stance)
	#battle_shout
	Spell(battle_shout)
	#mogu_power_potion
	UsePotionStrength()
}

AddFunction ArmsDefaultActions
{
	#auto_attack
	#mogu_power_potion,if=(target.health.pct<20&buff.recklessness.up)|buff.bloodlust.react|target.time_to_die<=25
	if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 25 UsePotionStrength()
	#recklessness,if=!talent.bloodbath.enabled&((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20))|buff.bloodbath.up&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20)|target.time_to_die<=12
	if not Talent(bloodbath_talent) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 } and { target.TimeToDie() > 192 * BuffAmount(cooldown_reduction_strength_buff) or target.HealthPercent() < 20 } or BuffPresent(bloodbath_buff) and { target.TimeToDie() > 192 * BuffAmount(cooldown_reduction_strength_buff) or target.HealthPercent() < 20 } or target.TimeToDie() <= 12 Spell(recklessness)
	#avatar,if=enabled&(buff.recklessness.up|target.time_to_die<=25)
	if Talent(avatar_talent) and { BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 } Spell(avatar)
	#skull_banner,if=buff.skull_banner.down&(((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&target.time_to_die>192&buff.cooldown_reduction.up)|buff.recklessness.up)
	if BuffExpires(skull_banner_buff any=1) and { { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 } and target.TimeToDie() > 192 and BuffPresent(cooldown_reduction_strength_buff) or BuffPresent(recklessness_buff) } and CheckBoxOn(opt_skull_banner) Spell(skull_banner)
	#use_item,slot=hands,if=!talent.bloodbath.enabled&debuff.colossus_smash.up|buff.bloodbath.up
	if not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(bloodbath_buff) UseItemActions()
	#blood_fury,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(blood_fury_ap)
	#berserking,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(berserking)
	#arcane_torrent,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(arcane_torrent_rage)
	#bloodbath,if=enabled&(debuff.colossus_smash.remains>0.1|cooldown.colossus_smash.remains<5|target.time_to_die<=20)
	if Talent(bloodbath_talent) and { target.DebuffRemaining(colossus_smash_debuff) > 0.1 or SpellCooldown(colossus_smash) < 5 or target.TimeToDie() <= 20 } Spell(bloodbath)
	#berserker_rage,if=buff.enrage.remains<0.5
	if BuffRemaining(enrage_buff any=1) < 0.5 Spell(berserker_rage)
	#heroic_leap,if=debuff.colossus_smash.up
	if target.DebuffPresent(colossus_smash_debuff) and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
	#run_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 ArmsAoeActions()
	#run_action_list,name=single_target,if=active_enemies<2
	if Enemies() < 2 ArmsSingleTargetActions()
}

AddFunction ArmsAoeActions
{
	#sweeping_strikes
	Spell(sweeping_strikes)
	#cleave,if=rage>110&active_enemies<=4
	if Rage() > 110 and Enemies() <= 4 Spell(cleave)
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } Spell(bladestorm)
	#dragon_roar,if=enabled&debuff.colossus_smash.down
	if Talent(dragon_roar_talent) and target.DebuffExpires(colossus_smash_debuff) Spell(dragon_roar)
	#colossus_smash,if=debuff.colossus_smash.remains<1
	if target.DebuffRemaining(colossus_smash_debuff) < 1 Spell(colossus_smash)
	#thunder_clap,target=2,if=dot.deep_wounds.attack_power*1.1<stat.attack_power
	if target.DebuffAttackPower(deep_wounds_debuff) * 1.1 < AttackPower() Spell(thunder_clap)
	#mortal_strike,if=active_enemies=2|rage<50
	if Enemies() == 2 or Rage() < 50 Spell(mortal_strike)
	#execute,if=buff.sudden_execute.down&active_enemies=2
	if BuffExpires(sudden_execute_buff) and Enemies() == 2 and { BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 } Spell(execute)
	#slam,if=buff.sweeping_strikes.up&debuff.colossus_smash.up
	if BuffPresent(sweeping_strikes_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(slam)
	#overpower,if=active_enemies=2
	if Enemies() == 2 Spell(overpower)
	#slam,if=buff.sweeping_strikes.up
	if BuffPresent(sweeping_strikes_buff) Spell(slam)
	#battle_shout
	Spell(battle_shout)
}

AddFunction ArmsSingleTargetActions
{
	#heroic_strike,if=rage>115|(debuff.colossus_smash.up&rage>60&set_bonus.tier16_2pc_melee)
	if Rage() > 115 or target.DebuffPresent(colossus_smash_debuff) and Rage() > 60 and ArmorSetBonus(T16_melee 2) Spell(heroic_strike)
	#mortal_strike,if=dot.deep_wounds.remains<1.0|buff.enrage.down|rage<10
	if target.DebuffRemaining(deep_wounds_debuff) < 1 or BuffExpires(enrage_buff any=1) or Rage() < 10 Spell(mortal_strike)
	#colossus_smash,if=debuff.colossus_smash.remains<1.0
	if target.DebuffRemaining(colossus_smash_debuff) < 1 Spell(colossus_smash)
	#bladestorm,if=enabled,interrupt_if=!cooldown.colossus_smash.remains
	if Talent(bladestorm_talent) Spell(bladestorm)
	#mortal_strike
	Spell(mortal_strike)
	#storm_bolt,if=enabled&debuff.colossus_smash.up
	if Talent(storm_bolt_talent) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#dragon_roar,if=enabled&debuff.colossus_smash.down
	if Talent(dragon_roar_talent) and target.DebuffExpires(colossus_smash_debuff) Spell(dragon_roar)
	#execute,if=buff.sudden_execute.down|buff.taste_for_blood.down|rage>90|target.time_to_die<12
	if { BuffExpires(sudden_execute_buff) or BuffExpires(taste_for_blood_buff) or Rage() > 90 or target.TimeToDie() < 12 } and { BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 } Spell(execute)
	#slam,if=target.health.pct>=20&(trinket.stacking_stat.crit.stack>=10|buff.recklessness.up)
	if target.HealthPercent() >= 20 and { BuffStacks(trinket_stacking_stat_crit_buff) >= 10 or BuffPresent(recklessness_buff) } Spell(slam)
	#overpower,if=target.health.pct>=20&rage<100|buff.sudden_execute.up
	if target.HealthPercent() >= 20 and Rage() < 100 or BuffPresent(sudden_execute_buff) Spell(overpower)
	#execute
	if BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 Spell(execute)
	#slam,if=target.health.pct>=20
	if target.HealthPercent() >= 20 Spell(slam)
	#heroic_throw
	Spell(heroic_throw)
	#battle_shout
	Spell(battle_shout)
}

AddIcon specialization=arms help=main enemies=1
{
	if InCombat(no) ArmsPrecombatActions()
	ArmsDefaultActions()
}

AddIcon specialization=arms help=aoe
{
	if InCombat(no) ArmsPrecombatActions()
	ArmsDefaultActions()
}

### Required symbols
# arcane_torrent_rage
# avatar
# avatar_talent
# battle_shout
# battle_stance
# berserker_rage
# berserking
# bladestorm
# bladestorm_talent
# blood_fury_ap
# bloodbath
# bloodbath_buff
# bloodbath_talent
# cleave
# colossus_smash
# colossus_smash_debuff
# cooldown_reduction_strength_buff
# death_sentence_buff
# deep_wounds_debuff
# dragon_roar
# dragon_roar_talent
# execute
# heroic_leap
# heroic_strike
# heroic_throw
# mogu_power_potion
# mortal_strike
# overpower
# recklessness
# recklessness_buff
# skull_banner
# slam
# storm_bolt
# storm_bolt_talent
# sudden_execute_buff
# sweeping_strikes
# sweeping_strikes_buff
# taste_for_blood_buff
# thunder_clap
# trinket_stacking_stat_crit_buff
]]
	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "reference")
end
