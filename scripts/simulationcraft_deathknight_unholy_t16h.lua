local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Death_Knight_Unholy_T16H"
	local desc = "[5.4] SimulationCraft: Death_Knight_Unholy_T16H"
	local code = [[
# Based on SimulationCraft profile "Death_Knight_Unholy_T16H".
#	class=deathknight
#	spec=unholy
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#db!2...0.

Include(ovale_common)
Include(ovale_deathknight_spells)

AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default)

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

AddFunction UnholyPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#horn_of_winter
	Spell(horn_of_winter)
	#unholy_presence
	if not Stance(deathknight_unholy_presence) Spell(unholy_presence)
	#snapshot_stats
	#army_of_the_dead
	Spell(army_of_the_dead)
	#mogu_power_potion
	UsePotionStrength()
	#raise_dead
	Spell(raise_dead)
}

AddFunction UnholyDefaultActions
{
	#auto_attack
	#antimagic_shell,damage=100000
	Spell(antimagic_shell)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#use_item,slot=hands
	UseItemActions()
	#mogu_power_potion,if=buff.dark_transformation.up&target.time_to_die<=60
	if pet.BuffPresent(dark_transformation_buff any=1) and target.TimeToDie() <= 60 UsePotionStrength()
	#unholy_frenzy,if=time>=4
	if TimeInCombat() >= 4 Spell(unholy_frenzy)
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 UnholyAoeActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 UnholySingleTargetActions()
}

AddFunction UnholyAoeActions
{
	#unholy_blight,if=talent.unholy_blight.enabled
	if Talent(unholy_blight_talent) Spell(unholy_blight)
	#plague_strike,if=!dot.blood_plague.ticking|!dot.frost_fever.ticking
	if not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) Spell(plague_strike)
	#pestilence,if=dot.blood_plague.ticking&talent.plague_leech.enabled,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and Talent(plague_leech_talent) and TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)
	#pestilence,if=dot.blood_plague.ticking&talent.unholy_blight.enabled&cooldown.unholy_blight.remains<49,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and Talent(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 and TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)
	#summon_gargoyle
	Spell(summon_gargoyle)
	#dark_transformation
	if BuffStacks(shadow_infusion_buff) >= 5 Spell(dark_transformation)
	#blood_tap,if=talent.blood_tap.enabled&buff.shadow_infusion.stack=5
	if Talent(blood_tap_talent) and BuffStacks(shadow_infusion_buff) == 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#blood_boil,if=blood=2|death=2
	if Runes(blood 2) or Runes(death 2) and not Runes(death 3) Spell(blood_boil)
	#death_and_decay,if=unholy=1
	if Runes(unholy 1) and not Runes(unholy 2) Spell(death_and_decay)
	#soul_reaper,if=unholy=2&target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if Runes(unholy 2) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_unholy)
	#scourge_strike,if=unholy=2
	if Runes(unholy 2) Spell(scourge_strike)
	#blood_tap,if=talent.blood_tap.enabled&buff.blood_charge.stack>10
	if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#death_coil,if=runic_power>90|buff.sudden_doom.react|(buff.dark_transformation.down&rune.unholy<=1)
	if RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Runes(unholy 2) Spell(death_coil)
	#blood_boil
	Spell(blood_boil)
	#icy_touch
	Spell(icy_touch)
	#soul_reaper,if=unholy=1&target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if Runes(unholy 1) and not Runes(unholy 2) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_unholy)
	#scourge_strike,if=unholy=1
	if Runes(unholy 1) and not Runes(unholy 2) Spell(scourge_strike)
	#death_coil
	Spell(death_coil)
	#blood_tap,if=talent.blood_tap.enabled
	if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#plague_leech,if=talent.plague_leech.enabled&unholy=1
	if Talent(plague_leech_talent) and Runes(unholy 1) and not Runes(unholy 2) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
	#horn_of_winter
	Spell(horn_of_winter)
	#empower_rune_weapon
	Spell(empower_rune_weapon)
}

AddFunction UnholySingleTargetActions
{
	#outbreak,if=stat.attack_power>(dot.blood_plague.attack_power*1.1)&time>15&!(cooldown.unholy_blight.remains>79)
	if AttackPower() > target.DebuffAttackPower(blood_plague_debuff) * 1.1 and TimeInCombat() > 15 and not SpellCooldown(unholy_blight) > 79 Spell(outbreak)
	#plague_strike,if=stat.attack_power>(dot.blood_plague.attack_power*1.1)&time>15&!(cooldown.unholy_blight.remains>79)
	if AttackPower() > target.DebuffAttackPower(blood_plague_debuff) * 1.1 and TimeInCombat() > 15 and not SpellCooldown(unholy_blight) > 79 Spell(plague_strike)
	#blood_tap,if=talent.blood_tap.enabled&(buff.blood_charge.stack>10&runic_power>=32)
	if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 32 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#unholy_blight,if=talent.unholy_blight.enabled&((dot.frost_fever.remains<3|dot.blood_plague.remains<3))
	if Talent(unholy_blight_talent) and { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } Spell(unholy_blight)
	#outbreak,if=dot.frost_fever.remains<3|dot.blood_plague.remains<3
	if target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 Spell(outbreak)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_unholy)
	#blood_tap,if=talent.blood_tap.enabled&((target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0))
	if Talent(blood_tap_talent) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_unholy) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#plague_strike,if=!dot.blood_plague.ticking|!dot.frost_fever.ticking
	if not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) Spell(plague_strike)
	#summon_gargoyle
	Spell(summon_gargoyle)
	#dark_transformation
	if BuffStacks(shadow_infusion_buff) >= 5 Spell(dark_transformation)
	#death_coil,if=runic_power>90
	if RunicPower() > 90 Spell(death_coil)
	#death_and_decay,if=unholy=2
	if Runes(unholy 2) Spell(death_and_decay)
	#blood_tap,if=talent.blood_tap.enabled&(unholy=2&cooldown.death_and_decay.remains=0)
	if Talent(blood_tap_talent) and Runes(unholy 2) and not SpellCooldown(death_and_decay) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#scourge_strike,if=unholy=2
	if Runes(unholy 2) Spell(scourge_strike)
	#festering_strike,if=blood=2&frost=2
	if Runes(blood 2) and Runes(frost 2) Spell(festering_strike)
	#death_and_decay
	Spell(death_and_decay)
	#blood_tap,if=talent.blood_tap.enabled&cooldown.death_and_decay.remains=0
	if Talent(blood_tap_talent) and not SpellCooldown(death_and_decay) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#death_coil,if=buff.sudden_doom.react|(buff.dark_transformation.down&rune.unholy<=1)
	if BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Runes(unholy 2) Spell(death_coil)
	#scourge_strike
	Spell(scourge_strike)
	#plague_leech,if=talent.plague_leech.enabled&cooldown.outbreak.remains<1
	if Talent(plague_leech_talent) and SpellCooldown(outbreak) < 1 and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
	#festering_strike
	Spell(festering_strike)
	#horn_of_winter
	Spell(horn_of_winter)
	#death_coil
	Spell(death_coil)
	#blood_tap,if=talent.blood_tap.enabled&buff.blood_charge.stack>=8
	if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 8 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#empower_rune_weapon
	Spell(empower_rune_weapon)
}

AddIcon specialization=unholy help=main enemies=1
{
	if InCombat(no) UnholyPrecombatActions()
	UnholyDefaultActions()
}

AddIcon specialization=unholy help=aoe
{
	if InCombat(no) UnholyPrecombatActions()
	UnholyDefaultActions()
}

### Required symbols
# antimagic_shell
# arcane_torrent_runicpower
# army_of_the_dead
# berserking
# blood_boil
# blood_charge_buff
# blood_fury_ap
# blood_plague_debuff
# blood_tap
# blood_tap_talent
# dark_transformation
# dark_transformation_buff
# death_and_decay
# death_coil
# empower_rune_weapon
# festering_strike
# frost_fever_debuff
# horn_of_winter
# icy_touch
# mogu_power_potion
# outbreak
# pestilence
# plague_leech
# plague_leech_talent
# plague_strike
# raise_dead
# scourge_strike
# shadow_infusion_buff
# soul_reaper_unholy
# sudden_doom_buff
# summon_gargoyle
# unholy_blight
# unholy_blight_talent
# unholy_frenzy
# unholy_presence
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code, "reference")
end
