local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Warrior_Protection_T16H"
	local desc = "[5.4] SimulationCraft: Warrior_Protection_T16H" 
	local code = [[
# Based on SimulationCraft profile "Warrior_Protection_T16H".
#	class=warrior
#	spec=protection
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Zb!.00110
#	glyphs=unending_rage/hold_the_line/heavy_repercussions

Include(ovale_common)
Include(ovale_warrior_common)

AddFunction ProtectionDpsCdsActions
{
	#avatar,if=enabled
	if TalentPoints(avatar_talent) Spell(avatar)
	#bloodbath,if=enabled
	if TalentPoints(bloodbath_talent) Spell(bloodbath)
	#blood_fury
	Spell(blood_fury)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent)
	#dragon_roar,if=enabled
	if TalentPoints(dragon_roar_talent) Spell(dragon_roar)
	#shattering_throw
	Spell(shattering_throw)
	#skull_banner
	Spell(skull_banner)
	#recklessness
	Spell(recklessness)
	#storm_bolt,if=enabled
	if TalentPoints(storm_bolt_talent) Spell(storm_bolt)
	#shockwave,if=enabled
	if TalentPoints(shockwave_talent) Spell(shockwave)
	#bladestorm,if=enabled
	if TalentPoints(bladestorm_talent) Spell(bladestorm)
	#run_action_list,name=normal_rotation
	ProtectionNormalRotationActions()
}

AddFunction ProtectionNormalRotationActions
{
	#shield_slam
	Spell(shield_slam)
	#revenge
	Spell(revenge)
	#battle_shout,if=rage<=rage.max-20
	if Rage() <= MaxRage() -20 Spell(battle_shout)
	#thunder_clap,if=glyph.resonating_power.enabled|target.debuff.weakened_blows.down
	if Glyph(glyph_of_resonating_power) or target.DebuffExpires(weakened_blows_debuff) Spell(thunder_clap)
	#demoralizing_shout
	Spell(demoralizing_shout)
	#impending_victory,if=enabled
	if TalentPoints(impending_victory_talent) Spell(impending_victory)
	#victory_rush,if=!talent.impending_victory.enabled
	if not TalentPoints(impending_victory_talent) Spell(victory_rush)
	#devastate
	Spell(devastate)
}

AddFunction ProtectionDefaultActions
{
	#auto_attack
	#mountains_potion,if=incoming_damage_2500ms>health.max*0.6&(buff.shield_wall.down&buff.last_stand.down)
	if IncomingDamage(2.500) > MaxHealth() * 0.6 and { BuffExpires(shield_wall_buff) and BuffExpires(last_stand_buff) } Spell(mountains_potion)
	#use_item,slot=trinket2
	UseItemActions()
	#heroic_strike,if=buff.ultimatum.up|buff.glyph_incite.up
	if BuffPresent(ultimatum_buff) or BuffPresent(glyph_incite_buff) Spell(heroic_strike)
	#berserker_rage,if=buff.enrage.down&rage<=rage.max-10
	if BuffExpires(enrage_buff) and Rage() <= MaxRage() -10 Spell(berserker_rage)
	#shield_block
	Spell(shield_block)
	#shield_barrier,if=incoming_damage_1500ms>health.max*0.3|rage>rage.max-20
	if IncomingDamage(1.500) > MaxHealth() * 0.3 or Rage() > MaxRage() -20 Spell(shield_barrier)
	#shield_wall,if=incoming_damage_2500ms>health.max*0.6
	if IncomingDamage(2.500) > MaxHealth() * 0.6 Spell(shield_wall)
	#run_action_list,name=dps_cds,if=buff.vengeance.value>health.max*0.20
	if BuffAmount(vengeance_buff) > MaxHealth() * 0.2 ProtectionDpsCdsActions()
	#run_action_list,name=normal_rotation
	ProtectionNormalRotationActions()
}

AddFunction ProtectionPrecombatActions
{
	#flask,type=earth
	#food,type=chun_tian_spring_rolls
	#snapshot_stats
	#stance,choose=defensive
	if not Stance(warrior_defensive_stance) Spell(defensive_stance)
	#battle_shout
	Spell(battle_shout)
	#mountains_potion
	Spell(mountains_potion)
}

AddIcon mastery=protection help=main
{
	if InCombat(no) ProtectionPrecombatActions()
	ProtectionDefaultActions()
}

### Required symbols
# arcane_torrent
# avatar
# avatar_talent
# battle_shout
# berserker_rage
# berserking
# bladestorm
# bladestorm_talent
# blood_fury
# bloodbath
# bloodbath_talent
# demoralizing_shout
# devastate
# dragon_roar
# dragon_roar_talent
# enrage_buff
# glyph_incite_buff
# glyph_of_resonating_power
# heroic_strike
# impending_victory
# impending_victory_talent
# last_stand_buff
# mountains_potion
# recklessness
# revenge
# shattering_throw
# shield_barrier
# shield_block
# shield_slam
# shield_wall
# shield_wall_buff
# shockwave
# shockwave_talent
# skull_banner
# storm_bolt
# storm_bolt_talent
# thunder_clap
# ultimatum_buff
# vengeance_buff
# victory_rush
# weakened_blows_debuff
]]
	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "reference")
end
