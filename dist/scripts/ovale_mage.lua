local __exports = LibStub:NewLibrary("ovale/scripts/ovale_mage", 80300)
if not __exports then return end
__exports.registerMage = function(OvaleScripts)
    do
        local name = "sc_t25_mage_arcane"
        local desc = "[9.0] Simulationcraft: T25_Mage_Arcane"
        local code = [[
# Based on SimulationCraft profile "T25_Mage_Arcane".
#	class=mage
#	spec=arcane
#	talents=2032021

Include(ovale_common)
Include(ovale_mage_spells)


AddFunction aoe_totm_charges
{
 2
}

AddFunction ap_minimum_mana_pct
{
 if message("runeforge.grisly_icicle.equipped is not implemented") 50
 if message("runeforge.disciplinary_command.equipped is not implemented") 50
 30
}

AddFunction barrage_mana_pct
{
 if message("covenant.night_fae.enabled is not implemented") 80
 90
}

AddFunction totm_max_delay
{
 if azeriteessenceisminor(vision_of_perfection_essence_id) 30
 if message("conduit.arcane_prodigy.enabled is not implemented") and enemies() < 3 15
 if message("covenant.night_fae.enabled is not implemented") 15
 if message("runeforge.disciplinary_command.equipped is not implemented") 3
 5
}

AddFunction rop_max_delay
{
 20
}

AddFunction ap_max_delay
{
 10
}

AddFunction rs_max_delay
{
 5
}

AddFunction have_opened
{
 if previousgcdspell(evocation) 1
 if prepull_evo() == 1 1
 if enemies() > 2 1
 0
}

AddFunction prepull_evo
{
 if message("runeforge.siphon_storm.equipped is not implemented") and message("covenant.night_fae.enabled is not implemented") 1
 if message("runeforge.siphon_storm.equipped is not implemented") and message("covenant.necrolord.enabled is not implemented") and enemies() > 1 1
 if message("runeforge.siphon_storm.equipped is not implemented") and enemies() > 2 1
 0
}

AddFunction final_burn
{
 if buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and not buffpresent(rule_of_threes) and target.timetodie() <= mana() / powercost(arcane_blast) * executetime(arcane_blast) 1
 0
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=arcane)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=arcane)
AddCheckBox(opt_time_warp spellname(time_warp) specialization=arcane)

AddFunction arcaneinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(counterspell) and target.isinterruptible() spell(counterspell)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
 }
}

AddFunction arcaneuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

### actions.rotation

AddFunction arcanerotationmainactions
{
 #variable,name=final_burn,op=set,value=1,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack&!buff.rule_of_threes.up&target.time_to_die<=((mana%action.arcane_blast.cost)*action.arcane_blast.execute_time)
 #strict_sequence,if=debuff.radiant_spark_vulnerability.stack=debuff.radiant_spark_vulnerability.max_stack&buff.arcane_power.down&buff.rune_of_power.down,name=last_spark_stack:arcane_blast:arcane_barrage
 if target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and buffexpires(arcane_power) and buffexpires(rune_of_power) spell(strict_sequence)
 #arcane_barrage,if=debuff.radiant_spark_vulnerability.stack=debuff.radiant_spark_vulnerability.max_stack&(buff.arcane_power.down|buff.arcane_power.remains<=gcd)&(buff.rune_of_power.down|buff.rune_of_power.remains<=gcd)
 if target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and { buffexpires(arcane_power) or buffremaining(arcane_power) <= gcd() } and { buffexpires(rune_of_power) or totemremaining(rune_of_power) <= gcd() } spell(arcane_barrage)
 #arcane_blast,if=dot.radiant_spark.remains>5|debuff.radiant_spark_vulnerability.stack>0
 if { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_blast,if=buff.presence_of_mind.up&debuff.touch_of_the_magi.up&debuff.touch_of_the_magi.remains<=action.arcane_blast.execute_time
 if buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_missiles,if=debuff.touch_of_the_magi.up&talent.arcane_echo.enabled&buff.deathborne.down&(debuff.touch_of_the_magi.remains>action.arcane_missiles.execute_time|cooldown.presence_of_mind.remains>0|covenant.kyrian.enabled),chain=1
 if target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and { target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) or spellcooldown(presence_of_mind) > 0 or message("covenant.kyrian.enabled is not implemented") } spell(arcane_missiles)
 #arcane_missiles,if=buff.clearcasting.react&buff.expanded_potential.up
 if buffpresent(clearcasting) and buffpresent(expanded_potential_buff) spell(arcane_missiles)
 #arcane_missiles,if=buff.clearcasting.react&(buff.arcane_power.up|buff.rune_of_power.up|debuff.touch_of_the_magi.remains>action.arcane_missiles.execute_time),chain=1
 if buffpresent(clearcasting) and { buffpresent(arcane_power) or buffpresent(rune_of_power) or target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) } spell(arcane_missiles)
 #arcane_missiles,if=buff.clearcasting.react&buff.clearcasting.stack=buff.clearcasting.max_stack,chain=1
 if buffpresent(clearcasting) and buffstacks(clearcasting) == spelldata(clearcasting max_stacks) spell(arcane_missiles)
 #arcane_missiles,if=buff.clearcasting.react&buff.clearcasting.remains<=((buff.clearcasting.stack*action.arcane_missiles.execute_time)+gcd),chain=1
 if buffpresent(clearcasting) and buffremaining(clearcasting) <= buffstacks(clearcasting) * executetime(arcane_missiles) + gcd() spell(arcane_missiles)
 #nether_tempest,if=(refreshable|!ticking)&buff.arcane_charge.stack=buff.arcane_charge.max_stack&buff.arcane_power.down&debuff.touch_of_the_magi.down
 if { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) spell(nether_tempest)
 #arcane_orb,if=buff.arcane_charge.stack<=2
 if buffstacks(arcane_charge_buff) <= 2 spell(arcane_orb)
 #supernova,if=mana.pct<=95&buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
 if manapercent() <= 95 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(supernova)
 #arcane_blast,if=buff.rule_of_threes.up&buff.arcane_charge.stack>3
 if buffpresent(rule_of_threes) and buffstacks(arcane_charge_buff) > 3 and mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_barrage,if=mana.pct<variable.barrage_mana_pct&cooldown.evocation.remains>0&buff.arcane_power.down&buff.arcane_charge.stack=buff.arcane_charge.max_stack&essence.vision_of_perfection.minor
 if manapercent() < barrage_mana_pct() and spellcooldown(evocation) > 0 and buffexpires(arcane_power) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and azeriteessenceisminor(vision_of_perfection_essence_id) spell(arcane_barrage)
 #arcane_barrage,if=cooldown.touch_of_the_magi.remains=0&(cooldown.rune_of_power.remains=0|cooldown.arcane_power.remains=0)&buff.arcane_charge.stack=buff.arcane_charge.max_stack
 if not spellcooldown(touch_of_the_magi) > 0 and { not spellcooldown(rune_of_power) > 0 or not spellcooldown(arcane_power) > 0 } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) spell(arcane_barrage)
 #arcane_barrage,if=mana.pct<=variable.barrage_mana_pct&buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down&buff.arcane_charge.stack=buff.arcane_charge.max_stack&cooldown.evocation.remains>0
 if manapercent() <= barrage_mana_pct() and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spellcooldown(evocation) > 0 spell(arcane_barrage)
 #arcane_barrage,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down&buff.arcane_charge.stack=buff.arcane_charge.max_stack&talent.arcane_orb.enabled&cooldown.arcane_orb.remains<=gcd&mana.pct<=90&cooldown.evocation.remains>0
 if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and hastalent(arcane_orb_talent) and spellcooldown(arcane_orb) <= gcd() and manapercent() <= 90 and spellcooldown(evocation) > 0 spell(arcane_barrage)
 #arcane_barrage,if=buff.arcane_power.up&buff.arcane_power.remains<=gcd&buff.arcane_charge.stack=buff.arcane_charge.max_stack
 if buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) spell(arcane_barrage)
 #arcane_barrage,if=buff.rune_of_power.up&buff.rune_of_power.remains<=gcd&buff.arcane_charge.stack=buff.arcane_charge.max_stack
 if buffpresent(rune_of_power) and totemremaining(rune_of_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) spell(arcane_barrage)
 #arcane_blast
 if mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_barrage
 spell(arcane_barrage)
}

AddFunction arcanerotationmainpostconditions
{
}

AddFunction arcanerotationshortcdactions
{
 unless target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and buffexpires(arcane_power) and buffexpires(rune_of_power) and spell(strict_sequence) or target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and { buffexpires(arcane_power) or buffremaining(arcane_power) <= gcd() } and { buffexpires(rune_of_power) or totemremaining(rune_of_power) <= gcd() } and spell(arcane_barrage) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and { target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) or spellcooldown(presence_of_mind) > 0 or message("covenant.kyrian.enabled is not implemented") } and spell(arcane_missiles) or buffpresent(clearcasting) and buffpresent(expanded_potential_buff) and spell(arcane_missiles) or buffpresent(clearcasting) and { buffpresent(arcane_power) or buffpresent(rune_of_power) or target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) } and spell(arcane_missiles) or buffpresent(clearcasting) and buffstacks(clearcasting) == spelldata(clearcasting max_stacks) and spell(arcane_missiles) or buffpresent(clearcasting) and buffremaining(clearcasting) <= buffstacks(clearcasting) * executetime(arcane_missiles) + gcd() and spell(arcane_missiles) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and spell(nether_tempest) or buffstacks(arcane_charge_buff) <= 2 and spell(arcane_orb) or manapercent() <= 95 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(supernova)
 {
  #shifting_power,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down&cooldown.evocation.remains>0&cooldown.arcane_power.remains>0&cooldown.touch_of_the_magi.remains>0&(!talent.rune_of_power.enabled|(talent.rune_of_power.enabled&cooldown.rune_of_power.remains>0))
  if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spellcooldown(evocation) > 0 and spellcooldown(arcane_power) > 0 and spellcooldown(touch_of_the_magi) > 0 and { not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > 0 } spell(shifting_power)
 }
}

AddFunction arcanerotationshortcdpostconditions
{
 target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and buffexpires(arcane_power) and buffexpires(rune_of_power) and spell(strict_sequence) or target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and { buffexpires(arcane_power) or buffremaining(arcane_power) <= gcd() } and { buffexpires(rune_of_power) or totemremaining(rune_of_power) <= gcd() } and spell(arcane_barrage) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and { target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) or spellcooldown(presence_of_mind) > 0 or message("covenant.kyrian.enabled is not implemented") } and spell(arcane_missiles) or buffpresent(clearcasting) and buffpresent(expanded_potential_buff) and spell(arcane_missiles) or buffpresent(clearcasting) and { buffpresent(arcane_power) or buffpresent(rune_of_power) or target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) } and spell(arcane_missiles) or buffpresent(clearcasting) and buffstacks(clearcasting) == spelldata(clearcasting max_stacks) and spell(arcane_missiles) or buffpresent(clearcasting) and buffremaining(clearcasting) <= buffstacks(clearcasting) * executetime(arcane_missiles) + gcd() and spell(arcane_missiles) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and spell(nether_tempest) or buffstacks(arcane_charge_buff) <= 2 and spell(arcane_orb) or manapercent() <= 95 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(supernova) or buffpresent(rule_of_threes) and buffstacks(arcane_charge_buff) > 3 and mana() > manacost(arcane_blast) and spell(arcane_blast) or manapercent() < barrage_mana_pct() and spellcooldown(evocation) > 0 and buffexpires(arcane_power) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and azeriteessenceisminor(vision_of_perfection_essence_id) and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and { not spellcooldown(rune_of_power) > 0 or not spellcooldown(arcane_power) > 0 } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or manapercent() <= barrage_mana_pct() and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spellcooldown(evocation) > 0 and spell(arcane_barrage) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and hastalent(arcane_orb_talent) and spellcooldown(arcane_orb) <= gcd() and manapercent() <= 90 and spellcooldown(evocation) > 0 and spell(arcane_barrage) or buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffpresent(rune_of_power) and totemremaining(rune_of_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
}

AddFunction arcanerotationcdactions
{
 unless target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and buffexpires(arcane_power) and buffexpires(rune_of_power) and spell(strict_sequence) or target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and { buffexpires(arcane_power) or buffremaining(arcane_power) <= gcd() } and { buffexpires(rune_of_power) or totemremaining(rune_of_power) <= gcd() } and spell(arcane_barrage) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and { target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) or spellcooldown(presence_of_mind) > 0 or message("covenant.kyrian.enabled is not implemented") } and spell(arcane_missiles) or buffpresent(clearcasting) and buffpresent(expanded_potential_buff) and spell(arcane_missiles) or buffpresent(clearcasting) and { buffpresent(arcane_power) or buffpresent(rune_of_power) or target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) } and spell(arcane_missiles) or buffpresent(clearcasting) and buffstacks(clearcasting) == spelldata(clearcasting max_stacks) and spell(arcane_missiles) or buffpresent(clearcasting) and buffremaining(clearcasting) <= buffstacks(clearcasting) * executetime(arcane_missiles) + gcd() and spell(arcane_missiles) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and spell(nether_tempest) or buffstacks(arcane_charge_buff) <= 2 and spell(arcane_orb) or manapercent() <= 95 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(supernova) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spellcooldown(evocation) > 0 and spellcooldown(arcane_power) > 0 and spellcooldown(touch_of_the_magi) > 0 and { not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > 0 } and spell(shifting_power) or buffpresent(rule_of_threes) and buffstacks(arcane_charge_buff) > 3 and mana() > manacost(arcane_blast) and spell(arcane_blast) or manapercent() < barrage_mana_pct() and spellcooldown(evocation) > 0 and buffexpires(arcane_power) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and azeriteessenceisminor(vision_of_perfection_essence_id) and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and { not spellcooldown(rune_of_power) > 0 or not spellcooldown(arcane_power) > 0 } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or manapercent() <= barrage_mana_pct() and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spellcooldown(evocation) > 0 and spell(arcane_barrage) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and hastalent(arcane_orb_talent) and spellcooldown(arcane_orb) <= gcd() and manapercent() <= 90 and spellcooldown(evocation) > 0 and spell(arcane_barrage) or buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffpresent(rune_of_power) and totemremaining(rune_of_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or mana() > manacost(arcane_blast) and spell(arcane_blast)
 {
  #evocation,interrupt_if=mana.pct>=85,interrupt_immediate=1
  spell(evocation)
 }
}

AddFunction arcanerotationcdpostconditions
{
 target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and buffexpires(arcane_power) and buffexpires(rune_of_power) and spell(strict_sequence) or target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and { buffexpires(arcane_power) or buffremaining(arcane_power) <= gcd() } and { buffexpires(rune_of_power) or totemremaining(rune_of_power) <= gcd() } and spell(arcane_barrage) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and { target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) or spellcooldown(presence_of_mind) > 0 or message("covenant.kyrian.enabled is not implemented") } and spell(arcane_missiles) or buffpresent(clearcasting) and buffpresent(expanded_potential_buff) and spell(arcane_missiles) or buffpresent(clearcasting) and { buffpresent(arcane_power) or buffpresent(rune_of_power) or target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) } and spell(arcane_missiles) or buffpresent(clearcasting) and buffstacks(clearcasting) == spelldata(clearcasting max_stacks) and spell(arcane_missiles) or buffpresent(clearcasting) and buffremaining(clearcasting) <= buffstacks(clearcasting) * executetime(arcane_missiles) + gcd() and spell(arcane_missiles) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and spell(nether_tempest) or buffstacks(arcane_charge_buff) <= 2 and spell(arcane_orb) or manapercent() <= 95 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(supernova) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spellcooldown(evocation) > 0 and spellcooldown(arcane_power) > 0 and spellcooldown(touch_of_the_magi) > 0 and { not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > 0 } and spell(shifting_power) or buffpresent(rule_of_threes) and buffstacks(arcane_charge_buff) > 3 and mana() > manacost(arcane_blast) and spell(arcane_blast) or manapercent() < barrage_mana_pct() and spellcooldown(evocation) > 0 and buffexpires(arcane_power) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and azeriteessenceisminor(vision_of_perfection_essence_id) and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and { not spellcooldown(rune_of_power) > 0 or not spellcooldown(arcane_power) > 0 } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or manapercent() <= barrage_mana_pct() and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spellcooldown(evocation) > 0 and spell(arcane_barrage) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and hastalent(arcane_orb_talent) and spellcooldown(arcane_orb) <= gcd() and manapercent() <= 90 and spellcooldown(evocation) > 0 and spell(arcane_barrage) or buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffpresent(rune_of_power) and totemremaining(rune_of_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
}

### actions.precombat

AddFunction arcaneprecombatmainactions
{
 #variable,name=prepull_evo,op=set,value=0
 #variable,name=prepull_evo,op=set,value=1,if=runeforge.siphon_storm.equipped&active_enemies>2
 #variable,name=prepull_evo,op=set,value=1,if=runeforge.siphon_storm.equipped&covenant.necrolord.enabled&active_enemies>1
 #variable,name=prepull_evo,op=set,value=1,if=runeforge.siphon_storm.equipped&covenant.night_fae.enabled
 #variable,name=have_opened,op=set,value=0
 #variable,name=have_opened,op=set,value=1,if=active_enemies>2
 #variable,name=have_opened,op=set,value=1,if=variable.prepull_evo=1
 #variable,name=final_burn,op=set,value=0
 #variable,name=rs_max_delay,op=set,value=5
 #variable,name=ap_max_delay,op=set,value=10
 #variable,name=rop_max_delay,op=set,value=20
 #variable,name=totm_max_delay,op=set,value=5
 #variable,name=totm_max_delay,op=set,value=3,if=runeforge.disciplinary_command.equipped
 #variable,name=totm_max_delay,op=set,value=15,if=covenant.night_fae.enabled
 #variable,name=totm_max_delay,op=set,value=15,if=conduit.arcane_prodigy.enabled&active_enemies<3
 #variable,name=totm_max_delay,op=set,value=30,if=essence.vision_of_perfection.minor
 #variable,name=barrage_mana_pct,op=set,value=90
 #variable,name=barrage_mana_pct,op=set,value=80,if=covenant.night_fae.enabled
 #variable,name=ap_minimum_mana_pct,op=set,value=30
 #variable,name=ap_minimum_mana_pct,op=set,value=50,if=runeforge.disciplinary_command.equipped
 #variable,name=ap_minimum_mana_pct,op=set,value=50,if=runeforge.grisly_icicle.equipped
 #variable,name=aoe_totm_charges,op=set,value=2
 #flask
 #food
 #augmentation
 #arcane_familiar
 spell(arcane_familiar)
 #arcane_intellect
 spell(arcane_intellect)
 #conjure_mana_gem
 spell(conjure_mana_gem)
 #frostbolt,if=variable.prepull_evo=0
 if prepull_evo() == 0 spell(frostbolt)
}

AddFunction arcaneprecombatmainpostconditions
{
}

AddFunction arcaneprecombatshortcdactions
{
}

AddFunction arcaneprecombatshortcdpostconditions
{
 spell(arcane_familiar) or spell(arcane_intellect) or spell(conjure_mana_gem) or prepull_evo() == 0 and spell(frostbolt)
}

AddFunction arcaneprecombatcdactions
{
 unless spell(arcane_familiar) or spell(arcane_intellect) or spell(conjure_mana_gem)
 {
  #snapshot_stats
  #mirror_image
  spell(mirror_image)

  unless prepull_evo() == 0 and spell(frostbolt)
  {
   #evocation,if=variable.prepull_evo=1
   if prepull_evo() == 1 spell(evocation)
  }
 }
}

AddFunction arcaneprecombatcdpostconditions
{
 spell(arcane_familiar) or spell(arcane_intellect) or spell(conjure_mana_gem) or prepull_evo() == 0 and spell(frostbolt)
}

### actions.opener

AddFunction arcaneopenermainactions
{
 #call_action_list,name=items,if=buff.arcane_power.up
 if buffpresent(arcane_power) arcaneitemsmainactions()

 unless buffpresent(arcane_power) and arcaneitemsmainpostconditions()
 {
  #berserking,if=buff.arcane_power.up
  if buffpresent(arcane_power) spell(berserking)
  #fire_blast,if=runeforge.disciplinary_command.equipped&buff.disciplinary_command_frost.up
  if message("runeforge.disciplinary_command.equipped is not implemented") and buffpresent(disciplinary_command_frost_buff) spell(fire_blast)
  #cancel_action,if=action.shifting_power.channeling&gcd.remains=0
  if message("action.shifting_power.channeling is not implemented") and not gcdremaining() > 0 spell(cancel_action)
  #rune_of_power,if=buff.rune_of_power.down
  if buffexpires(rune_of_power) spell(rune_of_power)
  #use_mana_gem,if=(talent.enlightened.enabled&mana.pct<=80&mana.pct>=65)|(!talent.enlightened.enabled&mana.pct<=85)
  if hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 spell(use_mana_gem)
  #berserking,if=buff.arcane_power.up
  if buffpresent(arcane_power) spell(berserking)
  #arcane_blast,if=dot.radiant_spark.remains>5|debuff.radiant_spark_vulnerability.stack>0
  if { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) spell(arcane_blast)
  #arcane_blast,if=buff.presence_of_mind.up&debuff.touch_of_the_magi.up&debuff.touch_of_the_magi.remains<=action.arcane_blast.execute_time
  if buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) spell(arcane_blast)
  #arcane_barrage,if=buff.arcane_power.up&buff.arcane_power.remains<=gcd&buff.arcane_charge.stack=buff.arcane_charge.max_stack
  if buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) spell(arcane_barrage)
  #arcane_missiles,if=debuff.touch_of_the_magi.up&talent.arcane_echo.enabled&buff.deathborne.down&debuff.touch_of_the_magi.remains>action.arcane_missiles.execute_time,chain=1
  if target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) spell(arcane_missiles)
  #arcane_missiles,if=buff.clearcasting.react,chain=1
  if buffpresent(clearcasting) spell(arcane_missiles)
  #arcane_orb,if=buff.arcane_charge.stack<=2&(cooldown.arcane_power.remains>10|active_enemies<=2)
  if buffstacks(arcane_charge_buff) <= 2 and { spellcooldown(arcane_power) > 10 or enemies() <= 2 } spell(arcane_orb)
  #arcane_blast,if=buff.rune_of_power.up|mana.pct>15
  if { buffpresent(rune_of_power) or manapercent() > 15 } and mana() > manacost(arcane_blast) spell(arcane_blast)
  #arcane_barrage
  spell(arcane_barrage)
 }
}

AddFunction arcaneopenermainpostconditions
{
 buffpresent(arcane_power) and arcaneitemsmainpostconditions()
}

AddFunction arcaneopenershortcdactions
{
 #bag_of_tricks,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
 if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(bag_of_tricks)
 #call_action_list,name=items,if=buff.arcane_power.up
 if buffpresent(arcane_power) arcaneitemsshortcdactions()

 unless buffpresent(arcane_power) and arcaneitemsshortcdpostconditions() or buffpresent(arcane_power) and spell(berserking) or message("runeforge.disciplinary_command.equipped is not implemented") and buffpresent(disciplinary_command_frost_buff) and spell(fire_blast)
 {
  #frost_nova,if=runeforge.grisly_icicle.equipped&mana.pct>95
  if message("runeforge.grisly_icicle.equipped is not implemented") and manapercent() > 95 spell(frost_nova)
  #mirrors_of_torment
  spell(mirrors_of_torment)
  #radiant_spark,if=mana.pct>40
  if manapercent() > 40 spell(radiant_spark)

  unless message("action.shifting_power.channeling is not implemented") and not gcdremaining() > 0 and spell(cancel_action)
  {
   #shifting_power,if=soulbind.field_of_blossoms.enabled
   if message("soulbind.field_of_blossoms.enabled is not implemented") spell(shifting_power)
   #touch_of_the_magi
   spell(touch_of_the_magi)

   unless buffexpires(rune_of_power) and spell(rune_of_power) or { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem) or buffpresent(arcane_power) and spell(berserking)
   {
    #presence_of_mind,if=debuff.touch_of_the_magi.up&debuff.touch_of_the_magi.remains<=buff.presence_of_mind.max_stack*action.arcane_blast.execute_time
    if target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= spelldata(presence_of_mind max_stacks) * executetime(arcane_blast) spell(presence_of_mind)
   }
  }
 }
}

AddFunction arcaneopenershortcdpostconditions
{
 buffpresent(arcane_power) and arcaneitemsshortcdpostconditions() or buffpresent(arcane_power) and spell(berserking) or message("runeforge.disciplinary_command.equipped is not implemented") and buffpresent(disciplinary_command_frost_buff) and spell(fire_blast) or message("action.shifting_power.channeling is not implemented") and not gcdremaining() > 0 and spell(cancel_action) or buffexpires(rune_of_power) and spell(rune_of_power) or { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem) or buffpresent(arcane_power) and spell(berserking) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) and spell(arcane_missiles) or buffpresent(clearcasting) and spell(arcane_missiles) or buffstacks(arcane_charge_buff) <= 2 and { spellcooldown(arcane_power) > 10 or enemies() <= 2 } and spell(arcane_orb) or { buffpresent(rune_of_power) or manapercent() > 15 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
}

AddFunction arcaneopenercdactions
{
 #variable,name=have_opened,op=set,value=1,if=prev_gcd.1.evocation
 #lights_judgment,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
 if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(lights_judgment)

 unless buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(bag_of_tricks)
 {
  #call_action_list,name=items,if=buff.arcane_power.up
  if buffpresent(arcane_power) arcaneitemscdactions()

  unless buffpresent(arcane_power) and arcaneitemscdpostconditions()
  {
   #potion,if=buff.arcane_power.up
   if buffpresent(arcane_power) and checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)

   unless buffpresent(arcane_power) and spell(berserking)
   {
    #blood_fury,if=buff.arcane_power.up
    if buffpresent(arcane_power) spell(blood_fury)
    #fireblood,if=buff.arcane_power.up
    if buffpresent(arcane_power) spell(fireblood)
    #ancestral_call,if=buff.arcane_power.up
    if buffpresent(arcane_power) spell(ancestral_call)

    unless message("runeforge.disciplinary_command.equipped is not implemented") and buffpresent(disciplinary_command_frost_buff) and spell(fire_blast) or message("runeforge.grisly_icicle.equipped is not implemented") and manapercent() > 95 and spell(frost_nova) or spell(mirrors_of_torment)
    {
     #deathborne
     spell(deathborne)

     unless manapercent() > 40 and spell(radiant_spark) or message("action.shifting_power.channeling is not implemented") and not gcdremaining() > 0 and spell(cancel_action) or message("soulbind.field_of_blossoms.enabled is not implemented") and spell(shifting_power) or spell(touch_of_the_magi)
     {
      #arcane_power
      spell(arcane_power)

      unless buffexpires(rune_of_power) and spell(rune_of_power) or { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem) or buffpresent(arcane_power) and spell(berserking)
      {
       #time_warp,if=runeforge.temporal_warp.equipped
       if message("runeforge.temporal_warp.equipped is not implemented") and checkboxon(opt_time_warp) and debuffexpires(burst_haste_debuff any=1) spell(time_warp)

       unless target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= spelldata(presence_of_mind max_stacks) * executetime(arcane_blast) and spell(presence_of_mind) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) and spell(arcane_missiles) or buffpresent(clearcasting) and spell(arcane_missiles) or buffstacks(arcane_charge_buff) <= 2 and { spellcooldown(arcane_power) > 10 or enemies() <= 2 } and spell(arcane_orb) or { buffpresent(rune_of_power) or manapercent() > 15 } and mana() > manacost(arcane_blast) and spell(arcane_blast)
       {
        #evocation,if=buff.rune_of_power.down,interrupt_if=mana.pct>=85,interrupt_immediate=1
        if buffexpires(rune_of_power) spell(evocation)
       }
      }
     }
    }
   }
  }
 }
}

AddFunction arcaneopenercdpostconditions
{
 buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(bag_of_tricks) or buffpresent(arcane_power) and arcaneitemscdpostconditions() or buffpresent(arcane_power) and spell(berserking) or message("runeforge.disciplinary_command.equipped is not implemented") and buffpresent(disciplinary_command_frost_buff) and spell(fire_blast) or message("runeforge.grisly_icicle.equipped is not implemented") and manapercent() > 95 and spell(frost_nova) or spell(mirrors_of_torment) or manapercent() > 40 and spell(radiant_spark) or message("action.shifting_power.channeling is not implemented") and not gcdremaining() > 0 and spell(cancel_action) or message("soulbind.field_of_blossoms.enabled is not implemented") and spell(shifting_power) or spell(touch_of_the_magi) or buffexpires(rune_of_power) and spell(rune_of_power) or { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem) or buffpresent(arcane_power) and spell(berserking) or target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= spelldata(presence_of_mind max_stacks) * executetime(arcane_blast) and spell(presence_of_mind) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) and spell(arcane_missiles) or buffpresent(clearcasting) and spell(arcane_missiles) or buffstacks(arcane_charge_buff) <= 2 and { spellcooldown(arcane_power) > 10 or enemies() <= 2 } and spell(arcane_orb) or { buffpresent(rune_of_power) or manapercent() > 15 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
}

### actions.movement

AddFunction arcanemovementmainactions
{
 #blink_any,if=movement.distance>=10
 if target.distance() >= 10 spell(blink_any)
 #arcane_missiles,if=movement.distance<10
 if target.distance() < 10 spell(arcane_missiles)
 #arcane_orb
 spell(arcane_orb)
 #fire_blast
 spell(fire_blast)
}

AddFunction arcanemovementmainpostconditions
{
}

AddFunction arcanemovementshortcdactions
{
 unless target.distance() >= 10 and spell(blink_any)
 {
  #presence_of_mind
  spell(presence_of_mind)
 }
}

AddFunction arcanemovementshortcdpostconditions
{
 target.distance() >= 10 and spell(blink_any) or target.distance() < 10 and spell(arcane_missiles) or spell(arcane_orb) or spell(fire_blast)
}

AddFunction arcanemovementcdactions
{
}

AddFunction arcanemovementcdpostconditions
{
 target.distance() >= 10 and spell(blink_any) or spell(presence_of_mind) or target.distance() < 10 and spell(arcane_missiles) or spell(arcane_orb) or spell(fire_blast)
}

### actions.items

AddFunction arcaneitemsmainactions
{
}

AddFunction arcaneitemsmainpostconditions
{
}

AddFunction arcaneitemsshortcdactions
{
}

AddFunction arcaneitemsshortcdpostconditions
{
}

AddFunction arcaneitemscdactions
{
 #use_items
 arcaneuseitemactions()
}

AddFunction arcaneitemscdpostconditions
{
}

### actions.final_burn

AddFunction arcanefinal_burnmainactions
{
 #arcane_missiles,if=buff.clearcasting.react,chain=1
 if buffpresent(clearcasting) spell(arcane_missiles)
 #arcane_blast
 if mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_barrage
 spell(arcane_barrage)
}

AddFunction arcanefinal_burnmainpostconditions
{
}

AddFunction arcanefinal_burnshortcdactions
{
}

AddFunction arcanefinal_burnshortcdpostconditions
{
 buffpresent(clearcasting) and spell(arcane_missiles) or mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
}

AddFunction arcanefinal_burncdactions
{
}

AddFunction arcanefinal_burncdpostconditions
{
 buffpresent(clearcasting) and spell(arcane_missiles) or mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
}

### actions.essences

AddFunction arcaneessencesmainactions
{
 #blood_of_the_enemy,if=cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=2&cooldown.arcane_power.remains<=gcd|target.time_to_die<cooldown.arcane_power.remains
 if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() or target.timetodie() < spellcooldown(arcane_power) spell(blood_of_the_enemy)
 #blood_of_the_enemy,if=cooldown.arcane_power.remains=0&(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70))&((cooldown.touch_of_the_magi.remains>10&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
 if not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(blood_of_the_enemy)
 #worldvein_resonance,if=cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=2&cooldown.arcane_power.remains<=gcd|target.time_to_die<cooldown.arcane_power.remains
 if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() or target.timetodie() < spellcooldown(arcane_power) spell(worldvein_resonance)
 #worldvein_resonance,if=cooldown.arcane_power.remains=0&(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70))&((cooldown.touch_of_the_magi.remains>10&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
 if not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(worldvein_resonance)
 #concentrated_flame,line_cd=6,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down&mana.time_to_max>=execute_time
 if timesincepreviousspell(concentrated_flame) > 6 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and mana() >= executetime(concentrated_flame) spell(concentrated_flame)
 #ripple_in_space,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
 if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(ripple_in_space)
 #the_unbound_force,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
 if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(the_unbound_force)
 #memory_of_lucid_dreams,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
 if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(memory_of_lucid_dreams)
}

AddFunction arcaneessencesmainpostconditions
{
}

AddFunction arcaneessencesshortcdactions
{
 unless { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() or target.timetodie() < spellcooldown(arcane_power) } and spell(blood_of_the_enemy) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(blood_of_the_enemy) or { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() or target.timetodie() < spellcooldown(arcane_power) } and spell(worldvein_resonance) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(worldvein_resonance) or timesincepreviousspell(concentrated_flame) > 6 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and mana() >= executetime(concentrated_flame) and spell(concentrated_flame)
 {
  #reaping_flames,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down&mana.time_to_max>=execute_time
  if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and mana() >= executetime(reaping_flames) spell(reaping_flames)
  #focused_azerite_beam,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
  if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(focused_azerite_beam)
  #purifying_blast,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
  if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(purifying_blast)
 }
}

AddFunction arcaneessencesshortcdpostconditions
{
 { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() or target.timetodie() < spellcooldown(arcane_power) } and spell(blood_of_the_enemy) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(blood_of_the_enemy) or { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() or target.timetodie() < spellcooldown(arcane_power) } and spell(worldvein_resonance) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(worldvein_resonance) or timesincepreviousspell(concentrated_flame) > 6 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and mana() >= executetime(concentrated_flame) and spell(concentrated_flame) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(ripple_in_space) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(the_unbound_force) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(memory_of_lucid_dreams)
}

AddFunction arcaneessencescdactions
{
 unless { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() or target.timetodie() < spellcooldown(arcane_power) } and spell(blood_of_the_enemy) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(blood_of_the_enemy) or { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() or target.timetodie() < spellcooldown(arcane_power) } and spell(worldvein_resonance) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(worldvein_resonance)
 {
  #guardian_of_azeroth,if=cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=2&cooldown.arcane_power.remains<=gcd|target.time_to_die<cooldown.arcane_power.remains
  if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() or target.timetodie() < spellcooldown(arcane_power) spell(guardian_of_azeroth)
  #guardian_of_azeroth,if=cooldown.arcane_power.remains=0&(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70))&((cooldown.touch_of_the_magi.remains>10&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
  if not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(guardian_of_azeroth)
 }
}

AddFunction arcaneessencescdpostconditions
{
 { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() or target.timetodie() < spellcooldown(arcane_power) } and spell(blood_of_the_enemy) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(blood_of_the_enemy) or { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() or target.timetodie() < spellcooldown(arcane_power) } and spell(worldvein_resonance) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(worldvein_resonance) or timesincepreviousspell(concentrated_flame) > 6 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and mana() >= executetime(concentrated_flame) and spell(concentrated_flame) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and mana() >= executetime(reaping_flames) and spell(reaping_flames) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(focused_azerite_beam) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(purifying_blast) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(ripple_in_space) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(the_unbound_force) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(memory_of_lucid_dreams)
}

### actions.cooldowns

AddFunction arcanecooldownsmainactions
{
 #call_action_list,name=items,if=buff.arcane_power.up
 if buffpresent(arcane_power) arcaneitemsmainactions()

 unless buffpresent(arcane_power) and arcaneitemsmainpostconditions()
 {
  #berserking,if=buff.arcane_power.up
  if buffpresent(arcane_power) spell(berserking)
  #frostbolt,if=runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_frost.down&(buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down)&cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack<=2&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay)|cooldown.arcane_power.remains<=gcd))
  if message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } spell(frostbolt)
  #fire_blast,if=runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_fire.down&prev_gcd.1.frostbolt
  if message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) spell(fire_blast)
  #rune_of_power,if=buff.rune_of_power.down&cooldown.touch_of_the_magi.remains>variable.rop_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack&(cooldown.arcane_power.remains>15|debuff.touch_of_the_magi.up)
  if buffexpires(rune_of_power) and spellcooldown(touch_of_the_magi) > rop_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } spell(rune_of_power)
  #use_mana_gem,if=cooldown.evocation.remains>0&((talent.enlightened.enabled&mana.pct<=80&mana.pct>=65)|(!talent.enlightened.enabled&mana.pct<=85))
  if spellcooldown(evocation) > 0 and { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } spell(use_mana_gem)
 }
}

AddFunction arcanecooldownsmainpostconditions
{
 buffpresent(arcane_power) and arcaneitemsmainpostconditions()
}

AddFunction arcanecooldownsshortcdactions
{
 #bag_of_tricks,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
 if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(bag_of_tricks)
 #call_action_list,name=items,if=buff.arcane_power.up
 if buffpresent(arcane_power) arcaneitemsshortcdactions()

 unless buffpresent(arcane_power) and arcaneitemsshortcdpostconditions() or buffpresent(arcane_power) and spell(berserking)
 {
  #frost_nova,if=runeforge.grisly_icicle.equipped&cooldown.arcane_power.remains>30&cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack<=2&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay)|cooldown.arcane_power.remains<=gcd))
  if message("runeforge.grisly_icicle.equipped is not implemented") and spellcooldown(arcane_power) > 30 and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } spell(frost_nova)
  #frost_nova,if=runeforge.grisly_icicle.equipped&cooldown.arcane_power.remains=0&(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70))&((cooldown.touch_of_the_magi.remains>10&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
  if message("runeforge.grisly_icicle.equipped is not implemented") and not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(frost_nova)

  unless message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) and spell(fire_blast)
  {
   #mirrors_of_torment,if=cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=2&cooldown.arcane_power.remains<=gcd
   if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() spell(mirrors_of_torment)
   #mirrors_of_torment,if=cooldown.arcane_power.remains=0&(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70))&((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
   if not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(mirrors_of_torment)
   #radiant_spark,if=cooldown.touch_of_the_magi.remains>variable.rs_max_delay&cooldown.arcane_power.remains>variable.rs_max_delay&(talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd|talent.rune_of_power.enabled&cooldown.rune_of_power.remains>variable.rs_max_delay|!talent.rune_of_power.enabled)&buff.arcane_charge.stack>2&debuff.touch_of_the_magi.down
   if spellcooldown(touch_of_the_magi) > rs_max_delay() and spellcooldown(arcane_power) > rs_max_delay() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > rs_max_delay() or not hastalent(rune_of_power_talent) } and buffstacks(arcane_charge_buff) > 2 and target.debuffexpires(touch_of_the_magi) spell(radiant_spark)
   #radiant_spark,if=cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=2&cooldown.arcane_power.remains<=gcd
   if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() spell(radiant_spark)
   #radiant_spark,if=cooldown.arcane_power.remains=0&((!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70))&((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct)
   if not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(radiant_spark)
   #touch_of_the_magi,if=buff.arcane_charge.stack<=2&talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay&covenant.kyrian.enabled&cooldown.radiant_spark.remains<=8
   if buffstacks(arcane_charge_buff) <= 2 and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and message("covenant.kyrian.enabled is not implemented") and spellcooldown(radiant_spark) <= 8 spell(touch_of_the_magi)
   #touch_of_the_magi,if=buff.arcane_charge.stack<=2&talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay&!covenant.kyrian.enabled
   if buffstacks(arcane_charge_buff) <= 2 and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and not message("covenant.kyrian.enabled is not implemented") spell(touch_of_the_magi)
   #touch_of_the_magi,if=buff.arcane_charge.stack<=2&!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay
   if buffstacks(arcane_charge_buff) <= 2 and not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() spell(touch_of_the_magi)
   #touch_of_the_magi,if=buff.arcane_charge.stack<=2&cooldown.arcane_power.remains<=gcd
   if buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() spell(touch_of_the_magi)

   unless buffexpires(rune_of_power) and spellcooldown(touch_of_the_magi) > rop_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power)
   {
    #presence_of_mind,if=buff.arcane_charge.stack=0&covenant.kyrian.enabled
    if buffstacks(arcane_charge_buff) == 0 and message("covenant.kyrian.enabled is not implemented") spell(presence_of_mind)
    #presence_of_mind,if=debuff.touch_of_the_magi.up&!covenant.kyrian.enabled
    if target.debuffpresent(touch_of_the_magi) and not message("covenant.kyrian.enabled is not implemented") spell(presence_of_mind)
   }
  }
 }
}

AddFunction arcanecooldownsshortcdpostconditions
{
 buffpresent(arcane_power) and arcaneitemsshortcdpostconditions() or buffpresent(arcane_power) and spell(berserking) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) and spell(fire_blast) or buffexpires(rune_of_power) and spellcooldown(touch_of_the_magi) > rop_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power) or spellcooldown(evocation) > 0 and { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem)
}

AddFunction arcanecooldownscdactions
{
 #lights_judgment,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
 if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(lights_judgment)

 unless buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(bag_of_tricks)
 {
  #call_action_list,name=items,if=buff.arcane_power.up
  if buffpresent(arcane_power) arcaneitemscdactions()

  unless buffpresent(arcane_power) and arcaneitemscdpostconditions()
  {
   #potion,if=buff.arcane_power.up
   if buffpresent(arcane_power) and checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)

   unless buffpresent(arcane_power) and spell(berserking)
   {
    #blood_fury,if=buff.arcane_power.up
    if buffpresent(arcane_power) spell(blood_fury)
    #fireblood,if=buff.arcane_power.up
    if buffpresent(arcane_power) spell(fireblood)
    #ancestral_call,if=buff.arcane_power.up
    if buffpresent(arcane_power) spell(ancestral_call)

    unless message("runeforge.grisly_icicle.equipped is not implemented") and spellcooldown(arcane_power) > 30 and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frost_nova) or message("runeforge.grisly_icicle.equipped is not implemented") and not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(frost_nova) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) and spell(fire_blast) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() and spell(mirrors_of_torment) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(mirrors_of_torment)
    {
     #deathborne,if=cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=2&cooldown.arcane_power.remains<=gcd
     if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() spell(deathborne)
     #deathborne,if=cooldown.arcane_power.remains=0&(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70))&((cooldown.touch_of_the_magi.remains>10&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
     if not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(deathborne)

     unless spellcooldown(touch_of_the_magi) > rs_max_delay() and spellcooldown(arcane_power) > rs_max_delay() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > rs_max_delay() or not hastalent(rune_of_power_talent) } and buffstacks(arcane_charge_buff) > 2 and target.debuffexpires(touch_of_the_magi) and spell(radiant_spark) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() and spell(radiant_spark) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(radiant_spark) or buffstacks(arcane_charge_buff) <= 2 and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and message("covenant.kyrian.enabled is not implemented") and spellcooldown(radiant_spark) <= 8 and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= 2 and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and not message("covenant.kyrian.enabled is not implemented") and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= 2 and not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() and spell(touch_of_the_magi)
     {
      #arcane_power,if=(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70))&cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
      if { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(arcane_power)
     }
    }
   }
  }
 }
}

AddFunction arcanecooldownscdpostconditions
{
 buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(bag_of_tricks) or buffpresent(arcane_power) and arcaneitemscdpostconditions() or buffpresent(arcane_power) and spell(berserking) or message("runeforge.grisly_icicle.equipped is not implemented") and spellcooldown(arcane_power) > 30 and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frost_nova) or message("runeforge.grisly_icicle.equipped is not implemented") and not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(frost_nova) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) and spell(fire_blast) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() and spell(mirrors_of_torment) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(mirrors_of_torment) or spellcooldown(touch_of_the_magi) > rs_max_delay() and spellcooldown(arcane_power) > rs_max_delay() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > rs_max_delay() or not hastalent(rune_of_power_talent) } and buffstacks(arcane_charge_buff) > 2 and target.debuffexpires(touch_of_the_magi) and spell(radiant_spark) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() and spell(radiant_spark) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(radiant_spark) or buffstacks(arcane_charge_buff) <= 2 and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and message("covenant.kyrian.enabled is not implemented") and spellcooldown(radiant_spark) <= 8 and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= 2 and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and not message("covenant.kyrian.enabled is not implemented") and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= 2 and not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= 2 and spellcooldown(arcane_power) <= gcd() and spell(touch_of_the_magi) or buffexpires(rune_of_power) and spellcooldown(touch_of_the_magi) > rop_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power) or buffstacks(arcane_charge_buff) == 0 and message("covenant.kyrian.enabled is not implemented") and spell(presence_of_mind) or target.debuffpresent(touch_of_the_magi) and not message("covenant.kyrian.enabled is not implemented") and spell(presence_of_mind) or spellcooldown(evocation) > 0 and { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem)
}

### actions.aoe

AddFunction arcaneaoemainactions
{
 #use_mana_gem,if=(talent.enlightened.enabled&mana.pct<=80&mana.pct>=65)|(!talent.enlightened.enabled&mana.pct<=85)
 if hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 spell(use_mana_gem)
 #call_action_list,name=items,if=buff.arcane_power.up
 if buffpresent(arcane_power) arcaneitemsmainactions()

 unless buffpresent(arcane_power) and arcaneitemsmainpostconditions()
 {
  #berserking,if=buff.arcane_power.up
  if buffpresent(arcane_power) spell(berserking)
  #frostbolt,if=runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_frost.down&(buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down)&cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack<=variable.aoe_totm_charges&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay)|cooldown.arcane_power.remains<=gcd))
  if message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } spell(frostbolt)
  #fire_blast,if=(runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_fire.down&prev_gcd.1.frostbolt)|(runeforge.disciplinary_command.equipped&time=0)
  if message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) or message("runeforge.disciplinary_command.equipped is not implemented") and timeincombat() == 0 spell(fire_blast)
  #rune_of_power,if=buff.rune_of_power.down&((cooldown.touch_of_the_magi.remains>20&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.aoe_totm_charges))&(cooldown.arcane_power.remains>15|debuff.touch_of_the_magi.up)
  if buffexpires(rune_of_power) and { spellcooldown(touch_of_the_magi) > 20 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } spell(rune_of_power)
  #arcane_blast,if=buff.deathborne.up&((talent.resonance.enabled&active_enemies<4)|active_enemies<5)
  if buffpresent(deathborne) and { hastalent(resonance_talent) and enemies() < 4 or enemies() < 5 } and mana() > manacost(arcane_blast) spell(arcane_blast)
  #supernova
  spell(supernova)
  #arcane_orb,if=buff.arcane_charge.stack=0
  if buffstacks(arcane_charge_buff) == 0 spell(arcane_orb)
  #nether_tempest,if=(refreshable|!ticking)&buff.arcane_charge.stack=buff.arcane_charge.max_stack
  if { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) spell(nether_tempest)
  #arcane_missiles,if=buff.clearcasting.react&runeforge.arcane_infinity.equipped&talent.amplification.enabled&active_enemies<6
  if buffpresent(clearcasting) and message("runeforge.arcane_infinity.equipped is not implemented") and hastalent(amplification_talent) and enemies() < 6 spell(arcane_missiles)
  #arcane_missiles,if=buff.clearcasting.react&runeforge.arcane_infinity.equipped&active_enemies<4
  if buffpresent(clearcasting) and message("runeforge.arcane_infinity.equipped is not implemented") and enemies() < 4 spell(arcane_missiles)
  #arcane_explosion,if=buff.arcane_charge.stack<buff.arcane_charge.max_stack
  if buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) spell(arcane_explosion)
  #arcane_explosion,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack&prev_gcd.1.arcane_barrage
  if buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and previousgcdspell(arcane_barrage) spell(arcane_explosion)
  #arcane_barrage,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack
  if buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) spell(arcane_barrage)
 }
}

AddFunction arcaneaoemainpostconditions
{
 buffpresent(arcane_power) and arcaneitemsmainpostconditions()
}

AddFunction arcaneaoeshortcdactions
{
 unless { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem)
 {
  #bag_of_tricks,if=buff.arcane_power.down
  if buffexpires(arcane_power) spell(bag_of_tricks)
  #call_action_list,name=items,if=buff.arcane_power.up
  if buffpresent(arcane_power) arcaneitemsshortcdactions()

  unless buffpresent(arcane_power) and arcaneitemsshortcdpostconditions() or buffpresent(arcane_power) and spell(berserking) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or { message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) or message("runeforge.disciplinary_command.equipped is not implemented") and timeincombat() == 0 } and spell(fire_blast)
  {
   #frost_nova,if=runeforge.grisly_icicle.equipped&cooldown.arcane_power.remains>30&cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack<=variable.aoe_totm_charges&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay)|cooldown.arcane_power.remains<=gcd))
   if message("runeforge.grisly_icicle.equipped is not implemented") and spellcooldown(arcane_power) > 30 and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } spell(frost_nova)
   #frost_nova,if=runeforge.grisly_icicle.equipped&cooldown.arcane_power.remains=0&(((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.aoe_totm_charges))&buff.rune_of_power.down)
   if message("runeforge.grisly_icicle.equipped is not implemented") and not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and buffexpires(rune_of_power) spell(frost_nova)
   #touch_of_the_magi,if=runeforge.siphon_storm.equipped&prev_gcd.1.evocation
   if message("runeforge.siphon_storm.equipped is not implemented") and previousgcdspell(evocation) spell(touch_of_the_magi)
   #mirrors_of_torment,if=(cooldown.arcane_power.remains>45|cooldown.arcane_power.remains<=3)&cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack<=variable.aoe_totm_charges&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>5)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>5)|cooldown.arcane_power.remains<=gcd))
   if { spellcooldown(arcane_power) > 45 or spellcooldown(arcane_power) <= 3 } and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > 5 or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > 5 or spellcooldown(arcane_power) <= gcd() } spell(mirrors_of_torment)
   #radiant_spark,if=cooldown.touch_of_the_magi.remains>variable.rs_max_delay&cooldown.arcane_power.remains>variable.rs_max_delay&(talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd|talent.rune_of_power.enabled&cooldown.rune_of_power.remains>variable.rs_max_delay|!talent.rune_of_power.enabled)&buff.arcane_charge.stack<=variable.aoe_totm_charges&debuff.touch_of_the_magi.down
   if spellcooldown(touch_of_the_magi) > rs_max_delay() and spellcooldown(arcane_power) > rs_max_delay() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > rs_max_delay() or not hastalent(rune_of_power_talent) } and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and target.debuffexpires(touch_of_the_magi) spell(radiant_spark)
   #radiant_spark,if=cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack<=variable.aoe_totm_charges&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay)|cooldown.arcane_power.remains<=gcd))
   if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } spell(radiant_spark)
   #radiant_spark,if=cooldown.arcane_power.remains=0&(((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.aoe_totm_charges))&buff.rune_of_power.down)
   if not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and buffexpires(rune_of_power) spell(radiant_spark)
   #touch_of_the_magi,if=buff.arcane_charge.stack<=variable.aoe_totm_charges&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay)|cooldown.arcane_power.remains<=gcd)
   if buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } spell(touch_of_the_magi)

   unless buffexpires(rune_of_power) and { spellcooldown(touch_of_the_magi) > 20 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power)
   {
    #presence_of_mind,if=buff.deathborne.up&debuff.touch_of_the_magi.up&debuff.touch_of_the_magi.remains<=buff.presence_of_mind.max_stack*action.arcane_blast.execute_time
    if buffpresent(deathborne) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= spelldata(presence_of_mind max_stacks) * executetime(arcane_blast) spell(presence_of_mind)

    unless buffpresent(deathborne) and { hastalent(resonance_talent) and enemies() < 4 or enemies() < 5 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(supernova) or buffstacks(arcane_charge_buff) == 0 and spell(arcane_orb) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(nether_tempest)
    {
     #shifting_power,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down&cooldown.arcane_power.remains>0&cooldown.touch_of_the_magi.remains>0&(!talent.rune_of_power.enabled|(talent.rune_of_power.enabled&cooldown.rune_of_power.remains>0))
     if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spellcooldown(arcane_power) > 0 and spellcooldown(touch_of_the_magi) > 0 and { not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > 0 } spell(shifting_power)
    }
   }
  }
 }
}

AddFunction arcaneaoeshortcdpostconditions
{
 { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem) or buffpresent(arcane_power) and arcaneitemsshortcdpostconditions() or buffpresent(arcane_power) and spell(berserking) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or { message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) or message("runeforge.disciplinary_command.equipped is not implemented") and timeincombat() == 0 } and spell(fire_blast) or buffexpires(rune_of_power) and { spellcooldown(touch_of_the_magi) > 20 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power) or buffpresent(deathborne) and { hastalent(resonance_talent) and enemies() < 4 or enemies() < 5 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(supernova) or buffstacks(arcane_charge_buff) == 0 and spell(arcane_orb) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(nether_tempest) or buffpresent(clearcasting) and message("runeforge.arcane_infinity.equipped is not implemented") and hastalent(amplification_talent) and enemies() < 6 and spell(arcane_missiles) or buffpresent(clearcasting) and message("runeforge.arcane_infinity.equipped is not implemented") and enemies() < 4 and spell(arcane_missiles) or buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) and spell(arcane_explosion) or buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and previousgcdspell(arcane_barrage) and spell(arcane_explosion) or buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage)
}

AddFunction arcaneaoecdactions
{
 unless { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem)
 {
  #lights_judgment,if=buff.arcane_power.down
  if buffexpires(arcane_power) spell(lights_judgment)

  unless buffexpires(arcane_power) and spell(bag_of_tricks)
  {
   #call_action_list,name=items,if=buff.arcane_power.up
   if buffpresent(arcane_power) arcaneitemscdactions()

   unless buffpresent(arcane_power) and arcaneitemscdpostconditions()
   {
    #potion,if=buff.arcane_power.up
    if buffpresent(arcane_power) and checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)

    unless buffpresent(arcane_power) and spell(berserking)
    {
     #blood_fury,if=buff.arcane_power.up
     if buffpresent(arcane_power) spell(blood_fury)
     #fireblood,if=buff.arcane_power.up
     if buffpresent(arcane_power) spell(fireblood)
     #ancestral_call,if=buff.arcane_power.up
     if buffpresent(arcane_power) spell(ancestral_call)
     #time_warp,if=runeforge.temporal_warp.equipped
     if message("runeforge.temporal_warp.equipped is not implemented") and checkboxon(opt_time_warp) and debuffexpires(burst_haste_debuff any=1) spell(time_warp)

     unless message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or { message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) or message("runeforge.disciplinary_command.equipped is not implemented") and timeincombat() == 0 } and spell(fire_blast) or message("runeforge.grisly_icicle.equipped is not implemented") and spellcooldown(arcane_power) > 30 and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frost_nova) or message("runeforge.grisly_icicle.equipped is not implemented") and not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and buffexpires(rune_of_power) and spell(frost_nova) or message("runeforge.siphon_storm.equipped is not implemented") and previousgcdspell(evocation) and spell(touch_of_the_magi)
     {
      #arcane_power,if=runeforge.siphon_storm.equipped&(prev_gcd.1.evocation|prev_gcd.1.touch_of_the_magi)
      if message("runeforge.siphon_storm.equipped is not implemented") and { previousgcdspell(evocation) or previousgcdspell(touch_of_the_magi) } spell(arcane_power)
      #evocation,if=time>30&runeforge.siphon_storm.equipped&buff.arcane_charge.stack<=variable.aoe_totm_charges&cooldown.touch_of_the_magi.remains=0&cooldown.arcane_power.remains<=gcd
      if timeincombat() > 30 and message("runeforge.siphon_storm.equipped is not implemented") and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and not spellcooldown(touch_of_the_magi) > 0 and spellcooldown(arcane_power) <= gcd() spell(evocation)
      #evocation,if=time>30&runeforge.siphon_storm.equipped&cooldown.arcane_power.remains=0&(((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.aoe_totm_charges))&buff.rune_of_power.down),interrupt_if=buff.siphon_storm.stack=buff.siphon_storm.max_stack,interrupt_immediate=1
      if timeincombat() > 30 and message("runeforge.siphon_storm.equipped is not implemented") and not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and buffexpires(rune_of_power) spell(evocation)

      unless { spellcooldown(arcane_power) > 45 or spellcooldown(arcane_power) <= 3 } and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > 5 or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > 5 or spellcooldown(arcane_power) <= gcd() } and spell(mirrors_of_torment) or spellcooldown(touch_of_the_magi) > rs_max_delay() and spellcooldown(arcane_power) > rs_max_delay() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > rs_max_delay() or not hastalent(rune_of_power_talent) } and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and target.debuffexpires(touch_of_the_magi) and spell(radiant_spark) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(radiant_spark) or not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and buffexpires(rune_of_power) and spell(radiant_spark)
      {
       #deathborne,if=cooldown.arcane_power.remains=0&(((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.aoe_totm_charges))&buff.rune_of_power.down)
       if not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and buffexpires(rune_of_power) spell(deathborne)

       unless buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(touch_of_the_magi)
       {
        #arcane_power,if=((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.aoe_totm_charges))&buff.rune_of_power.down
        if { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and buffexpires(rune_of_power) spell(arcane_power)

        unless buffexpires(rune_of_power) and { spellcooldown(touch_of_the_magi) > 20 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power) or buffpresent(deathborne) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= spelldata(presence_of_mind max_stacks) * executetime(arcane_blast) and spell(presence_of_mind) or buffpresent(deathborne) and { hastalent(resonance_talent) and enemies() < 4 or enemies() < 5 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(supernova) or buffstacks(arcane_charge_buff) == 0 and spell(arcane_orb) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(nether_tempest) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spellcooldown(arcane_power) > 0 and spellcooldown(touch_of_the_magi) > 0 and { not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > 0 } and spell(shifting_power) or buffpresent(clearcasting) and message("runeforge.arcane_infinity.equipped is not implemented") and hastalent(amplification_talent) and enemies() < 6 and spell(arcane_missiles) or buffpresent(clearcasting) and message("runeforge.arcane_infinity.equipped is not implemented") and enemies() < 4 and spell(arcane_missiles) or buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) and spell(arcane_explosion) or buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and previousgcdspell(arcane_barrage) and spell(arcane_explosion) or buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage)
        {
         #evocation,interrupt_if=mana.pct>=85,interrupt_immediate=1
         spell(evocation)
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction arcaneaoecdpostconditions
{
 { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem) or buffexpires(arcane_power) and spell(bag_of_tricks) or buffpresent(arcane_power) and arcaneitemscdpostconditions() or buffpresent(arcane_power) and spell(berserking) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or { message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) or message("runeforge.disciplinary_command.equipped is not implemented") and timeincombat() == 0 } and spell(fire_blast) or message("runeforge.grisly_icicle.equipped is not implemented") and spellcooldown(arcane_power) > 30 and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frost_nova) or message("runeforge.grisly_icicle.equipped is not implemented") and not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and buffexpires(rune_of_power) and spell(frost_nova) or message("runeforge.siphon_storm.equipped is not implemented") and previousgcdspell(evocation) and spell(touch_of_the_magi) or { spellcooldown(arcane_power) > 45 or spellcooldown(arcane_power) <= 3 } and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > 5 or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > 5 or spellcooldown(arcane_power) <= gcd() } and spell(mirrors_of_torment) or spellcooldown(touch_of_the_magi) > rs_max_delay() and spellcooldown(arcane_power) > rs_max_delay() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > rs_max_delay() or not hastalent(rune_of_power_talent) } and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and target.debuffexpires(touch_of_the_magi) and spell(radiant_spark) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(radiant_spark) or not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and buffexpires(rune_of_power) and spell(radiant_spark) or buffstacks(arcane_charge_buff) <= aoe_totm_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(touch_of_the_magi) or buffexpires(rune_of_power) and { spellcooldown(touch_of_the_magi) > 20 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_charges() } and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power) or buffpresent(deathborne) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= spelldata(presence_of_mind max_stacks) * executetime(arcane_blast) and spell(presence_of_mind) or buffpresent(deathborne) and { hastalent(resonance_talent) and enemies() < 4 or enemies() < 5 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(supernova) or buffstacks(arcane_charge_buff) == 0 and spell(arcane_orb) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(nether_tempest) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spellcooldown(arcane_power) > 0 and spellcooldown(touch_of_the_magi) > 0 and { not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > 0 } and spell(shifting_power) or buffpresent(clearcasting) and message("runeforge.arcane_infinity.equipped is not implemented") and hastalent(amplification_talent) and enemies() < 6 and spell(arcane_missiles) or buffpresent(clearcasting) and message("runeforge.arcane_infinity.equipped is not implemented") and enemies() < 4 and spell(arcane_missiles) or buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) and spell(arcane_explosion) or buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and previousgcdspell(arcane_barrage) and spell(arcane_explosion) or buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage)
}

### actions.default

AddFunction arcane_defaultmainactions
{
 #call_action_list,name=essences
 arcaneessencesmainactions()

 unless arcaneessencesmainpostconditions()
 {
  #call_action_list,name=aoe,if=active_enemies>2
  if enemies() > 2 arcaneaoemainactions()

  unless enemies() > 2 and arcaneaoemainpostconditions()
  {
   #call_action_list,name=opener,if=variable.have_opened=0
   if have_opened() == 0 arcaneopenermainactions()

   unless have_opened() == 0 and arcaneopenermainpostconditions()
   {
    #call_action_list,name=cooldowns
    arcanecooldownsmainactions()

    unless arcanecooldownsmainpostconditions()
    {
     #call_action_list,name=rotation,if=variable.final_burn=0
     if final_burn() == 0 arcanerotationmainactions()

     unless final_burn() == 0 and arcanerotationmainpostconditions()
     {
      #call_action_list,name=final_burn,if=variable.final_burn=1
      if final_burn() == 1 arcanefinal_burnmainactions()

      unless final_burn() == 1 and arcanefinal_burnmainpostconditions()
      {
       #call_action_list,name=movement
       arcanemovementmainactions()
      }
     }
    }
   }
  }
 }
}

AddFunction arcane_defaultmainpostconditions
{
 arcaneessencesmainpostconditions() or enemies() > 2 and arcaneaoemainpostconditions() or have_opened() == 0 and arcaneopenermainpostconditions() or arcanecooldownsmainpostconditions() or final_burn() == 0 and arcanerotationmainpostconditions() or final_burn() == 1 and arcanefinal_burnmainpostconditions() or arcanemovementmainpostconditions()
}

AddFunction arcane_defaultshortcdactions
{
 #call_action_list,name=essences
 arcaneessencesshortcdactions()

 unless arcaneessencesshortcdpostconditions()
 {
  #call_action_list,name=aoe,if=active_enemies>2
  if enemies() > 2 arcaneaoeshortcdactions()

  unless enemies() > 2 and arcaneaoeshortcdpostconditions()
  {
   #call_action_list,name=opener,if=variable.have_opened=0
   if have_opened() == 0 arcaneopenershortcdactions()

   unless have_opened() == 0 and arcaneopenershortcdpostconditions()
   {
    #call_action_list,name=cooldowns
    arcanecooldownsshortcdactions()

    unless arcanecooldownsshortcdpostconditions()
    {
     #call_action_list,name=rotation,if=variable.final_burn=0
     if final_burn() == 0 arcanerotationshortcdactions()

     unless final_burn() == 0 and arcanerotationshortcdpostconditions()
     {
      #call_action_list,name=final_burn,if=variable.final_burn=1
      if final_burn() == 1 arcanefinal_burnshortcdactions()

      unless final_burn() == 1 and arcanefinal_burnshortcdpostconditions()
      {
       #call_action_list,name=movement
       arcanemovementshortcdactions()
      }
     }
    }
   }
  }
 }
}

AddFunction arcane_defaultshortcdpostconditions
{
 arcaneessencesshortcdpostconditions() or enemies() > 2 and arcaneaoeshortcdpostconditions() or have_opened() == 0 and arcaneopenershortcdpostconditions() or arcanecooldownsshortcdpostconditions() or final_burn() == 0 and arcanerotationshortcdpostconditions() or final_burn() == 1 and arcanefinal_burnshortcdpostconditions() or arcanemovementshortcdpostconditions()
}

AddFunction arcane_defaultcdactions
{
 #counterspell,if=target.debuff.casting.react
 if target.isinterruptible() arcaneinterruptactions()
 #call_action_list,name=essences
 arcaneessencescdactions()

 unless arcaneessencescdpostconditions()
 {
  #call_action_list,name=aoe,if=active_enemies>2
  if enemies() > 2 arcaneaoecdactions()

  unless enemies() > 2 and arcaneaoecdpostconditions()
  {
   #call_action_list,name=opener,if=variable.have_opened=0
   if have_opened() == 0 arcaneopenercdactions()

   unless have_opened() == 0 and arcaneopenercdpostconditions()
   {
    #call_action_list,name=cooldowns
    arcanecooldownscdactions()

    unless arcanecooldownscdpostconditions()
    {
     #call_action_list,name=rotation,if=variable.final_burn=0
     if final_burn() == 0 arcanerotationcdactions()

     unless final_burn() == 0 and arcanerotationcdpostconditions()
     {
      #call_action_list,name=final_burn,if=variable.final_burn=1
      if final_burn() == 1 arcanefinal_burncdactions()

      unless final_burn() == 1 and arcanefinal_burncdpostconditions()
      {
       #call_action_list,name=movement
       arcanemovementcdactions()
      }
     }
    }
   }
  }
 }
}

AddFunction arcane_defaultcdpostconditions
{
 arcaneessencescdpostconditions() or enemies() > 2 and arcaneaoecdpostconditions() or have_opened() == 0 and arcaneopenercdpostconditions() or arcanecooldownscdpostconditions() or final_burn() == 0 and arcanerotationcdpostconditions() or final_burn() == 1 and arcanefinal_burncdpostconditions() or arcanemovementcdpostconditions()
}

### Arcane icons.

AddCheckBox(opt_mage_arcane_aoe l(aoe) default specialization=arcane)

AddIcon checkbox=!opt_mage_arcane_aoe enemies=1 help=shortcd specialization=arcane
{
 if not incombat() arcaneprecombatshortcdactions()
 arcane_defaultshortcdactions()
}

AddIcon checkbox=opt_mage_arcane_aoe help=shortcd specialization=arcane
{
 if not incombat() arcaneprecombatshortcdactions()
 arcane_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=arcane
{
 if not incombat() arcaneprecombatmainactions()
 arcane_defaultmainactions()
}

AddIcon checkbox=opt_mage_arcane_aoe help=aoe specialization=arcane
{
 if not incombat() arcaneprecombatmainactions()
 arcane_defaultmainactions()
}

AddIcon checkbox=!opt_mage_arcane_aoe enemies=1 help=cd specialization=arcane
{
 if not incombat() arcaneprecombatcdactions()
 arcane_defaultcdactions()
}

AddIcon checkbox=opt_mage_arcane_aoe help=cd specialization=arcane
{
 if not incombat() arcaneprecombatcdactions()
 arcane_defaultcdactions()
}

### Required symbols
# amplification_talent
# ancestral_call
# arcane_barrage
# arcane_blast
# arcane_charge_buff
# arcane_echo_talent
# arcane_explosion
# arcane_familiar
# arcane_intellect
# arcane_missiles
# arcane_orb
# arcane_orb_talent
# arcane_power
# bag_of_tricks
# berserking
# blink_any
# blood_fury
# blood_of_the_enemy
# buff_disciplinary_command
# cancel_action
# clearcasting
# concentrated_flame
# conjure_mana_gem
# counterspell
# deathborne
# disciplinary_command_fire_buff
# disciplinary_command_frost_buff
# enlightened_talent
# evocation
# expanded_potential_buff
# fire_blast
# fireblood
# focused_azerite_beam
# focused_resolve_item
# frost_nova
# frostbolt
# guardian_of_azeroth
# lights_judgment
# memory_of_lucid_dreams
# mirror_image
# mirrors_of_torment
# nether_tempest
# presence_of_mind
# purifying_blast
# quaking_palm
# radiant_spark
# radiant_spark_vulnerability
# reaping_flames
# resonance_talent
# ripple_in_space
# rule_of_threes
# rune_of_power
# rune_of_power_talent
# shifting_power
# strict_sequence
# supernova
# the_unbound_force
# time_warp
# touch_of_the_magi
# use_mana_gem
# vision_of_perfection_essence_id
# worldvein_resonance
]]
        OvaleScripts:RegisterScript("MAGE", "arcane", name, desc, code, "script")
    end
    do
        local name = "sc_t25_mage_fire"
        local desc = "[9.0] Simulationcraft: T25_Mage_Fire"
        local code = [[
# Based on SimulationCraft profile "T25_Mage_Fire".
#	class=mage
#	spec=fire
#	talents=3031022

Include(ovale_common)
Include(ovale_mage_spells)
### Fire icons.

AddCheckBox(opt_mage_fire_aoe l(aoe) default specialization=fire)
]]
        OvaleScripts:RegisterScript("MAGE", "fire", name, desc, code, "script")
    end
    do
        local name = "sc_t25_mage_frost"
        local desc = "[9.0] Simulationcraft: T25_Mage_Frost"
        local code = [[
# Based on SimulationCraft profile "T25_Mage_Frost".
#	class=mage
#	spec=frost
#	talents=2332021

Include(ovale_common)
Include(ovale_mage_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=frost)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=frost)
AddCheckBox(opt_time_warp spellname(time_warp) specialization=frost)

AddFunction frostinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(counterspell) and target.isinterruptible() spell(counterspell)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
 }
}

AddFunction frostuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

### actions.st

AddFunction froststmainactions
{
 #flurry,if=(remaining_winters_chill=0|debuff.winters_chill.down)&(prev_gcd.1.ebonbolt|buff.brain_freeze.react&(prev_gcd.1.radiant_spark|prev_gcd.1.glacial_spike|prev_gcd.1.frostbolt|(debuff.mirrors_of_torment.up|buff.expanded_potential.react|buff.freezing_winds.up)&buff.fingers_of_frost.react=0))
 if { message("remaining_winters_chill is not implemented") == 0 or target.debuffexpires(winters_chill) } and { previousgcdspell(ebonbolt) or buffpresent(brain_freeze) and { previousgcdspell(radiant_spark) or previousgcdspell(glacial_spike) or previousgcdspell(frostbolt) or { target.debuffpresent(mirrors_of_torment) or buffpresent(expanded_potential_buff) or buffpresent(freezing_winds) } and buffstacks(fingers_of_frost) == 0 } } spell(flurry)
 #blizzard,if=buff.freezing_rain.up|active_enemies>=3|active_enemies>=2&!runeforge.cold_front.equipped
 if buffpresent(freezing_rain_buff) or enemies() >= 3 or enemies() >= 2 and not message("runeforge.cold_front.equipped is not implemented") spell(blizzard)
 #ray_of_frost,if=remaining_winters_chill=1&debuff.winters_chill.remains
 if message("remaining_winters_chill is not implemented") == 1 and target.debuffpresent(winters_chill) spell(ray_of_frost)
 #glacial_spike,if=remaining_winters_chill&debuff.winters_chill.remains>cast_time+travel_time
 if message("remaining_winters_chill is not implemented") and target.debuffremaining(winters_chill) > casttime(glacial_spike) + traveltime(glacial_spike) spell(glacial_spike)
 #ice_lance,if=remaining_winters_chill&remaining_winters_chill>buff.fingers_of_frost.react&debuff.winters_chill.remains>travel_time
 if message("remaining_winters_chill is not implemented") and message("remaining_winters_chill is not implemented") > buffstacks(fingers_of_frost) and target.debuffremaining(winters_chill) > traveltime(ice_lance) spell(ice_lance)
 #comet_storm
 spell(comet_storm)
 #ice_nova
 spell(ice_nova)
 #ice_lance,if=buff.fingers_of_frost.react|debuff.frozen.remains>travel_time
 if buffpresent(fingers_of_frost) or target.debuffremaining(frozen) > traveltime(ice_lance) spell(ice_lance)
 #ebonbolt
 spell(ebonbolt)
 #arcane_explosion,if=runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_arcane.down
 if message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_arcane_buff) spell(arcane_explosion)
 #fire_blast,if=runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_fire.down
 if message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) spell(fire_blast)
 #glacial_spike,if=buff.brain_freeze.react
 if buffpresent(brain_freeze) spell(glacial_spike)
 #frostbolt
 spell(frostbolt)
}

AddFunction froststmainpostconditions
{
}

AddFunction froststshortcdactions
{
 unless { message("remaining_winters_chill is not implemented") == 0 or target.debuffexpires(winters_chill) } and { previousgcdspell(ebonbolt) or buffpresent(brain_freeze) and { previousgcdspell(radiant_spark) or previousgcdspell(glacial_spike) or previousgcdspell(frostbolt) or { target.debuffpresent(mirrors_of_torment) or buffpresent(expanded_potential_buff) or buffpresent(freezing_winds) } and buffstacks(fingers_of_frost) == 0 } } and spell(flurry)
 {
  #frozen_orb
  spell(frozen_orb)

  unless { buffpresent(freezing_rain_buff) or enemies() >= 3 or enemies() >= 2 and not message("runeforge.cold_front.equipped is not implemented") } and spell(blizzard) or message("remaining_winters_chill is not implemented") == 1 and target.debuffpresent(winters_chill) and spell(ray_of_frost) or message("remaining_winters_chill is not implemented") and target.debuffremaining(winters_chill) > casttime(glacial_spike) + traveltime(glacial_spike) and spell(glacial_spike) or message("remaining_winters_chill is not implemented") and message("remaining_winters_chill is not implemented") > buffstacks(fingers_of_frost) and target.debuffremaining(winters_chill) > traveltime(ice_lance) and spell(ice_lance) or spell(comet_storm) or spell(ice_nova)
  {
   #radiant_spark,if=buff.freezing_winds.up&active_enemies=1
   if buffpresent(freezing_winds) and enemies() == 1 spell(radiant_spark)

   unless { buffpresent(fingers_of_frost) or target.debuffremaining(frozen) > traveltime(ice_lance) } and spell(ice_lance) or spell(ebonbolt)
   {
    #radiant_spark,if=(!runeforge.freezing_winds.equipped|active_enemies>=2)&(buff.brain_freeze.react|soulbind.combat_meditation.enabled)
    if { not message("runeforge.freezing_winds.equipped is not implemented") or enemies() >= 2 } and { buffpresent(brain_freeze) or message("soulbind.combat_meditation.enabled is not implemented") } spell(radiant_spark)
    #shifting_power,if=active_enemies>=3
    if enemies() >= 3 spell(shifting_power)
    #shifting_power,line_cd=60,if=(soulbind.field_of_blossoms.enabled|soulbind.grove_invigoration.enabled)&(!talent.rune_of_power.enabled|buff.rune_of_power.down&cooldown.rune_of_power.remains>16)
    if timesincepreviousspell(shifting_power) > 60 and { message("soulbind.field_of_blossoms.enabled is not implemented") or message("soulbind.grove_invigoration.enabled is not implemented") } and { not hastalent(rune_of_power_talent) or buffexpires(rune_of_power) and spellcooldown(rune_of_power) > 16 } spell(shifting_power)
    #mirrors_of_torment
    spell(mirrors_of_torment)
    #frost_nova,if=runeforge.grisly_icicle.equipped&target.level<=level&debuff.frozen.down
    if message("runeforge.grisly_icicle.equipped is not implemented") and message("target.level is not implemented") <= message("level is not implemented") and target.debuffexpires(frozen) spell(frost_nova)
   }
  }
 }
}

AddFunction froststshortcdpostconditions
{
 { message("remaining_winters_chill is not implemented") == 0 or target.debuffexpires(winters_chill) } and { previousgcdspell(ebonbolt) or buffpresent(brain_freeze) and { previousgcdspell(radiant_spark) or previousgcdspell(glacial_spike) or previousgcdspell(frostbolt) or { target.debuffpresent(mirrors_of_torment) or buffpresent(expanded_potential_buff) or buffpresent(freezing_winds) } and buffstacks(fingers_of_frost) == 0 } } and spell(flurry) or { buffpresent(freezing_rain_buff) or enemies() >= 3 or enemies() >= 2 and not message("runeforge.cold_front.equipped is not implemented") } and spell(blizzard) or message("remaining_winters_chill is not implemented") == 1 and target.debuffpresent(winters_chill) and spell(ray_of_frost) or message("remaining_winters_chill is not implemented") and target.debuffremaining(winters_chill) > casttime(glacial_spike) + traveltime(glacial_spike) and spell(glacial_spike) or message("remaining_winters_chill is not implemented") and message("remaining_winters_chill is not implemented") > buffstacks(fingers_of_frost) and target.debuffremaining(winters_chill) > traveltime(ice_lance) and spell(ice_lance) or spell(comet_storm) or spell(ice_nova) or { buffpresent(fingers_of_frost) or target.debuffremaining(frozen) > traveltime(ice_lance) } and spell(ice_lance) or spell(ebonbolt) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_arcane_buff) and spell(arcane_explosion) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and spell(fire_blast) or buffpresent(brain_freeze) and spell(glacial_spike) or spell(frostbolt)
}

AddFunction froststcdactions
{
}

AddFunction froststcdpostconditions
{
 { message("remaining_winters_chill is not implemented") == 0 or target.debuffexpires(winters_chill) } and { previousgcdspell(ebonbolt) or buffpresent(brain_freeze) and { previousgcdspell(radiant_spark) or previousgcdspell(glacial_spike) or previousgcdspell(frostbolt) or { target.debuffpresent(mirrors_of_torment) or buffpresent(expanded_potential_buff) or buffpresent(freezing_winds) } and buffstacks(fingers_of_frost) == 0 } } and spell(flurry) or spell(frozen_orb) or { buffpresent(freezing_rain_buff) or enemies() >= 3 or enemies() >= 2 and not message("runeforge.cold_front.equipped is not implemented") } and spell(blizzard) or message("remaining_winters_chill is not implemented") == 1 and target.debuffpresent(winters_chill) and spell(ray_of_frost) or message("remaining_winters_chill is not implemented") and target.debuffremaining(winters_chill) > casttime(glacial_spike) + traveltime(glacial_spike) and spell(glacial_spike) or message("remaining_winters_chill is not implemented") and message("remaining_winters_chill is not implemented") > buffstacks(fingers_of_frost) and target.debuffremaining(winters_chill) > traveltime(ice_lance) and spell(ice_lance) or spell(comet_storm) or spell(ice_nova) or buffpresent(freezing_winds) and enemies() == 1 and spell(radiant_spark) or { buffpresent(fingers_of_frost) or target.debuffremaining(frozen) > traveltime(ice_lance) } and spell(ice_lance) or spell(ebonbolt) or { not message("runeforge.freezing_winds.equipped is not implemented") or enemies() >= 2 } and { buffpresent(brain_freeze) or message("soulbind.combat_meditation.enabled is not implemented") } and spell(radiant_spark) or enemies() >= 3 and spell(shifting_power) or timesincepreviousspell(shifting_power) > 60 and { message("soulbind.field_of_blossoms.enabled is not implemented") or message("soulbind.grove_invigoration.enabled is not implemented") } and { not hastalent(rune_of_power_talent) or buffexpires(rune_of_power) and spellcooldown(rune_of_power) > 16 } and spell(shifting_power) or spell(mirrors_of_torment) or message("runeforge.grisly_icicle.equipped is not implemented") and message("target.level is not implemented") <= message("level is not implemented") and target.debuffexpires(frozen) and spell(frost_nova) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_arcane_buff) and spell(arcane_explosion) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and spell(fire_blast) or buffpresent(brain_freeze) and spell(glacial_spike) or spell(frostbolt)
}

### actions.precombat

AddFunction frostprecombatmainactions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 spell(arcane_intellect)
 #snapshot_stats
 #frostbolt
 spell(frostbolt)
}

AddFunction frostprecombatmainpostconditions
{
}

AddFunction frostprecombatshortcdactions
{
 unless spell(arcane_intellect)
 {
  #summon_water_elemental
  if not pet.present() spell(summon_water_elemental)
 }
}

AddFunction frostprecombatshortcdpostconditions
{
 spell(arcane_intellect) or spell(frostbolt)
}

AddFunction frostprecombatcdactions
{
}

AddFunction frostprecombatcdpostconditions
{
 spell(arcane_intellect) or not pet.present() and spell(summon_water_elemental) or spell(frostbolt)
}

### actions.movement

AddFunction frostmovementmainactions
{
 #blink_any,if=movement.distance>10
 if target.distance() > 10 spell(blink_any)
 #ice_floes,if=buff.ice_floes.down
 if buffexpires(ice_floes) and speed() > 0 spell(ice_floes)
 #arcane_explosion,if=mana.pct>30&active_enemies>=2
 if manapercent() > 30 and enemies() >= 2 spell(arcane_explosion)
 #fire_blast
 spell(fire_blast)
 #ice_lance
 spell(ice_lance)
}

AddFunction frostmovementmainpostconditions
{
}

AddFunction frostmovementshortcdactions
{
}

AddFunction frostmovementshortcdpostconditions
{
 target.distance() > 10 and spell(blink_any) or buffexpires(ice_floes) and speed() > 0 and spell(ice_floes) or manapercent() > 30 and enemies() >= 2 and spell(arcane_explosion) or spell(fire_blast) or spell(ice_lance)
}

AddFunction frostmovementcdactions
{
}

AddFunction frostmovementcdpostconditions
{
 target.distance() > 10 and spell(blink_any) or buffexpires(ice_floes) and speed() > 0 and spell(ice_floes) or manapercent() > 30 and enemies() >= 2 and spell(arcane_explosion) or spell(fire_blast) or spell(ice_lance)
}

### actions.essences

AddFunction frostessencesmainactions
{
 #memory_of_lucid_dreams
 spell(memory_of_lucid_dreams)
 #blood_of_the_enemy
 spell(blood_of_the_enemy)
 #ripple_in_space
 spell(ripple_in_space)
 #concentrated_flame,line_cd=6
 if timesincepreviousspell(concentrated_flame) > 6 spell(concentrated_flame)
 #the_unbound_force,if=buff.reckless_force.up
 if buffpresent(reckless_force_buff) spell(the_unbound_force)
 #worldvein_resonance
 spell(worldvein_resonance)
}

AddFunction frostessencesmainpostconditions
{
}

AddFunction frostessencesshortcdactions
{
 #focused_azerite_beam
 spell(focused_azerite_beam)

 unless spell(memory_of_lucid_dreams) or spell(blood_of_the_enemy)
 {
  #purifying_blast
  spell(purifying_blast)

  unless spell(ripple_in_space) or timesincepreviousspell(concentrated_flame) > 6 and spell(concentrated_flame)
  {
   #reaping_flames
   spell(reaping_flames)
  }
 }
}

AddFunction frostessencesshortcdpostconditions
{
 spell(memory_of_lucid_dreams) or spell(blood_of_the_enemy) or spell(ripple_in_space) or timesincepreviousspell(concentrated_flame) > 6 and spell(concentrated_flame) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or spell(worldvein_resonance)
}

AddFunction frostessencescdactions
{
 #guardian_of_azeroth
 spell(guardian_of_azeroth)
}

AddFunction frostessencescdpostconditions
{
 spell(focused_azerite_beam) or spell(memory_of_lucid_dreams) or spell(blood_of_the_enemy) or spell(purifying_blast) or spell(ripple_in_space) or timesincepreviousspell(concentrated_flame) > 6 and spell(concentrated_flame) or spell(reaping_flames) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or spell(worldvein_resonance)
}

### actions.cds

AddFunction frostcdsmainactions
{
 #rune_of_power,if=cooldown.icy_veins.remains>15&buff.rune_of_power.down
 if spellcooldown(icy_veins) > 15 and buffexpires(rune_of_power) spell(rune_of_power)
 #berserking
 spell(berserking)
}

AddFunction frostcdsmainpostconditions
{
}

AddFunction frostcdsshortcdactions
{
 #mirrors_of_torment,if=soulbind.wasteland_propriety.enabled
 if message("soulbind.wasteland_propriety.enabled is not implemented") spell(mirrors_of_torment)

 unless spellcooldown(icy_veins) > 15 and buffexpires(rune_of_power) and spell(rune_of_power) or spell(berserking)
 {
  #bag_of_tricks
  spell(bag_of_tricks)
 }
}

AddFunction frostcdsshortcdpostconditions
{
 spellcooldown(icy_veins) > 15 and buffexpires(rune_of_power) and spell(rune_of_power) or spell(berserking)
}

AddFunction frostcdscdactions
{
 #potion,if=prev_off_gcd.icy_veins|target.time_to_die<30
 if { previousoffgcdspell(icy_veins) or target.timetodie() < 30 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(superior_battle_potion_of_intellect_item usable=1)

 unless message("soulbind.wasteland_propriety.enabled is not implemented") and spell(mirrors_of_torment)
 {
  #deathborne
  spell(deathborne)

  unless spellcooldown(icy_veins) > 15 and buffexpires(rune_of_power) and spell(rune_of_power)
  {
   #icy_veins,if=buff.rune_of_power.down
   if buffexpires(rune_of_power) spell(icy_veins)
   #time_warp,if=runeforge.temporal_warp.equipped&time>10&(prev_off_gcd.icy_veins|target.time_to_die<30)
   if message("runeforge.temporal_warp.equipped is not implemented") and timeincombat() > 10 and { previousoffgcdspell(icy_veins) or target.timetodie() < 30 } and checkboxon(opt_time_warp) and debuffexpires(burst_haste_debuff any=1) spell(time_warp)
   #use_items
   frostuseitemactions()
   #blood_fury
   spell(blood_fury)

   unless spell(berserking)
   {
    #lights_judgment
    spell(lights_judgment)
    #fireblood
    spell(fireblood)
    #ancestral_call
    spell(ancestral_call)
   }
  }
 }
}

AddFunction frostcdscdpostconditions
{
 message("soulbind.wasteland_propriety.enabled is not implemented") and spell(mirrors_of_torment) or spellcooldown(icy_veins) > 15 and buffexpires(rune_of_power) and spell(rune_of_power) or spell(berserking) or spell(bag_of_tricks)
}

### actions.aoe

AddFunction frostaoemainactions
{
 #blizzard
 spell(blizzard)
 #flurry,if=(remaining_winters_chill=0|debuff.winters_chill.down)&(prev_gcd.1.ebonbolt|buff.brain_freeze.react&buff.fingers_of_frost.react=0)
 if { message("remaining_winters_chill is not implemented") == 0 or target.debuffexpires(winters_chill) } and { previousgcdspell(ebonbolt) or buffpresent(brain_freeze) and buffstacks(fingers_of_frost) == 0 } spell(flurry)
 #ice_nova
 spell(ice_nova)
 #comet_storm
 spell(comet_storm)
 #ice_lance,if=buff.fingers_of_frost.react|debuff.frozen.remains>travel_time|remaining_winters_chill&debuff.winters_chill.remains>travel_time
 if buffpresent(fingers_of_frost) or target.debuffremaining(frozen) > traveltime(ice_lance) or message("remaining_winters_chill is not implemented") and target.debuffremaining(winters_chill) > traveltime(ice_lance) spell(ice_lance)
 #fire_blast,if=runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_fire.down
 if message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) spell(fire_blast)
 #arcane_explosion,if=mana.pct>30&!runeforge.cold_front.equipped&(!runeforge.freezing_winds.equipped|buff.freezing_winds.up)
 if manapercent() > 30 and not message("runeforge.cold_front.equipped is not implemented") and { not message("runeforge.freezing_winds.equipped is not implemented") or buffpresent(freezing_winds) } spell(arcane_explosion)
 #ebonbolt
 spell(ebonbolt)
 #frostbolt
 spell(frostbolt)
}

AddFunction frostaoemainpostconditions
{
}

AddFunction frostaoeshortcdactions
{
 #frozen_orb
 spell(frozen_orb)

 unless spell(blizzard) or { message("remaining_winters_chill is not implemented") == 0 or target.debuffexpires(winters_chill) } and { previousgcdspell(ebonbolt) or buffpresent(brain_freeze) and buffstacks(fingers_of_frost) == 0 } and spell(flurry) or spell(ice_nova) or spell(comet_storm) or { buffpresent(fingers_of_frost) or target.debuffremaining(frozen) > traveltime(ice_lance) or message("remaining_winters_chill is not implemented") and target.debuffremaining(winters_chill) > traveltime(ice_lance) } and spell(ice_lance)
 {
  #radiant_spark
  spell(radiant_spark)
  #shifting_power
  spell(shifting_power)
  #mirrors_of_torment
  spell(mirrors_of_torment)
  #frost_nova,if=runeforge.grisly_icicle.equipped&target.level<=level&debuff.frozen.down
  if message("runeforge.grisly_icicle.equipped is not implemented") and message("target.level is not implemented") <= message("level is not implemented") and target.debuffexpires(frozen) spell(frost_nova)
 }
}

AddFunction frostaoeshortcdpostconditions
{
 spell(blizzard) or { message("remaining_winters_chill is not implemented") == 0 or target.debuffexpires(winters_chill) } and { previousgcdspell(ebonbolt) or buffpresent(brain_freeze) and buffstacks(fingers_of_frost) == 0 } and spell(flurry) or spell(ice_nova) or spell(comet_storm) or { buffpresent(fingers_of_frost) or target.debuffremaining(frozen) > traveltime(ice_lance) or message("remaining_winters_chill is not implemented") and target.debuffremaining(winters_chill) > traveltime(ice_lance) } and spell(ice_lance) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and spell(fire_blast) or manapercent() > 30 and not message("runeforge.cold_front.equipped is not implemented") and { not message("runeforge.freezing_winds.equipped is not implemented") or buffpresent(freezing_winds) } and spell(arcane_explosion) or spell(ebonbolt) or spell(frostbolt)
}

AddFunction frostaoecdactions
{
}

AddFunction frostaoecdpostconditions
{
 spell(frozen_orb) or spell(blizzard) or { message("remaining_winters_chill is not implemented") == 0 or target.debuffexpires(winters_chill) } and { previousgcdspell(ebonbolt) or buffpresent(brain_freeze) and buffstacks(fingers_of_frost) == 0 } and spell(flurry) or spell(ice_nova) or spell(comet_storm) or { buffpresent(fingers_of_frost) or target.debuffremaining(frozen) > traveltime(ice_lance) or message("remaining_winters_chill is not implemented") and target.debuffremaining(winters_chill) > traveltime(ice_lance) } and spell(ice_lance) or spell(radiant_spark) or spell(shifting_power) or spell(mirrors_of_torment) or message("runeforge.grisly_icicle.equipped is not implemented") and message("target.level is not implemented") <= message("level is not implemented") and target.debuffexpires(frozen) and spell(frost_nova) or message("runeforge.disciplinary_command.equipped is not implemented") and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and spell(fire_blast) or manapercent() > 30 and not message("runeforge.cold_front.equipped is not implemented") and { not message("runeforge.freezing_winds.equipped is not implemented") or buffpresent(freezing_winds) } and spell(arcane_explosion) or spell(ebonbolt) or spell(frostbolt)
}

### actions.default

AddFunction frost_defaultmainactions
{
 #call_action_list,name=cds
 frostcdsmainactions()

 unless frostcdsmainpostconditions()
 {
  #call_action_list,name=essences
  frostessencesmainactions()

  unless frostessencesmainpostconditions()
  {
   #call_action_list,name=aoe,if=active_enemies>=5
   if enemies() >= 5 frostaoemainactions()

   unless enemies() >= 5 and frostaoemainpostconditions()
   {
    #call_action_list,name=st,if=active_enemies<5
    if enemies() < 5 froststmainactions()

    unless enemies() < 5 and froststmainpostconditions()
    {
     #call_action_list,name=movement
     frostmovementmainactions()
    }
   }
  }
 }
}

AddFunction frost_defaultmainpostconditions
{
 frostcdsmainpostconditions() or frostessencesmainpostconditions() or enemies() >= 5 and frostaoemainpostconditions() or enemies() < 5 and froststmainpostconditions() or frostmovementmainpostconditions()
}

AddFunction frost_defaultshortcdactions
{
 #call_action_list,name=cds
 frostcdsshortcdactions()

 unless frostcdsshortcdpostconditions()
 {
  #call_action_list,name=essences
  frostessencesshortcdactions()

  unless frostessencesshortcdpostconditions()
  {
   #call_action_list,name=aoe,if=active_enemies>=5
   if enemies() >= 5 frostaoeshortcdactions()

   unless enemies() >= 5 and frostaoeshortcdpostconditions()
   {
    #call_action_list,name=st,if=active_enemies<5
    if enemies() < 5 froststshortcdactions()

    unless enemies() < 5 and froststshortcdpostconditions()
    {
     #call_action_list,name=movement
     frostmovementshortcdactions()
    }
   }
  }
 }
}

AddFunction frost_defaultshortcdpostconditions
{
 frostcdsshortcdpostconditions() or frostessencesshortcdpostconditions() or enemies() >= 5 and frostaoeshortcdpostconditions() or enemies() < 5 and froststshortcdpostconditions() or frostmovementshortcdpostconditions()
}

AddFunction frost_defaultcdactions
{
 #counterspell
 frostinterruptactions()
 #call_action_list,name=cds
 frostcdscdactions()

 unless frostcdscdpostconditions()
 {
  #call_action_list,name=essences
  frostessencescdactions()

  unless frostessencescdpostconditions()
  {
   #call_action_list,name=aoe,if=active_enemies>=5
   if enemies() >= 5 frostaoecdactions()

   unless enemies() >= 5 and frostaoecdpostconditions()
   {
    #call_action_list,name=st,if=active_enemies<5
    if enemies() < 5 froststcdactions()

    unless enemies() < 5 and froststcdpostconditions()
    {
     #call_action_list,name=movement
     frostmovementcdactions()
    }
   }
  }
 }
}

AddFunction frost_defaultcdpostconditions
{
 frostcdscdpostconditions() or frostessencescdpostconditions() or enemies() >= 5 and frostaoecdpostconditions() or enemies() < 5 and froststcdpostconditions() or frostmovementcdpostconditions()
}

### Frost icons.

AddCheckBox(opt_mage_frost_aoe l(aoe) default specialization=frost)

AddIcon checkbox=!opt_mage_frost_aoe enemies=1 help=shortcd specialization=frost
{
 if not incombat() frostprecombatshortcdactions()
 frost_defaultshortcdactions()
}

AddIcon checkbox=opt_mage_frost_aoe help=shortcd specialization=frost
{
 if not incombat() frostprecombatshortcdactions()
 frost_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=frost
{
 if not incombat() frostprecombatmainactions()
 frost_defaultmainactions()
}

AddIcon checkbox=opt_mage_frost_aoe help=aoe specialization=frost
{
 if not incombat() frostprecombatmainactions()
 frost_defaultmainactions()
}

AddIcon checkbox=!opt_mage_frost_aoe enemies=1 help=cd specialization=frost
{
 if not incombat() frostprecombatcdactions()
 frost_defaultcdactions()
}

AddIcon checkbox=opt_mage_frost_aoe help=cd specialization=frost
{
 if not incombat() frostprecombatcdactions()
 frost_defaultcdactions()
}

### Required symbols
# ancestral_call
# arcane_explosion
# arcane_intellect
# bag_of_tricks
# berserking
# blink_any
# blizzard
# blood_fury
# blood_of_the_enemy
# brain_freeze
# buff_disciplinary_command
# comet_storm
# concentrated_flame
# counterspell
# deathborne
# disciplinary_command_arcane_buff
# disciplinary_command_fire_buff
# ebonbolt
# expanded_potential_buff
# fingers_of_frost
# fire_blast
# fireblood
# flurry
# focused_azerite_beam
# freezing_rain_buff
# freezing_winds
# frost_nova
# frostbolt
# frozen
# frozen_orb
# glacial_spike
# guardian_of_azeroth
# ice_floes
# ice_lance
# ice_nova
# icy_veins
# lights_judgment
# memory_of_lucid_dreams
# mirrors_of_torment
# purifying_blast
# quaking_palm
# radiant_spark
# ray_of_frost
# reaping_flames
# reckless_force_buff
# ripple_in_space
# rune_of_power
# rune_of_power_talent
# shifting_power
# summon_water_elemental
# superior_battle_potion_of_intellect_item
# the_unbound_force
# time_warp
# winters_chill
# worldvein_resonance
]]
        OvaleScripts:RegisterScript("MAGE", "frost", name, desc, code, "script")
    end
end
