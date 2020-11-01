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


AddFunction ap_minimum_mana_pct
{
 if message("variable.ap_minimum_mana_pct is not implemented") == 30 and equippedruneforge(grisly_icicle_runeforge) 50
 if 0 == 30 and equippedruneforge(disciplinary_command_runeforge) 50
}

AddFunction barrage_mana_pct
{
 if 0 == 70 and covenant(night_fae) 40
}

AddFunction totm_max_delay
{
 if message("variable.totm_max_delay is not implemented") == 5 and azeriteessenceisminor(vision_of_perfection_essence_id) 30
 if message("variable.totm_max_delay is not implemented") == 5 and message("conduit.arcane_prodigy.enabled is not implemented") and enemies() < 3 15
 if message("variable.totm_max_delay is not implemented") == 5 and covenant(night_fae) 15
 if 0 == 5 and equippedruneforge(disciplinary_command_runeforge) 3
}

AddFunction have_opened
{
 if previousgcdspell(evocation) 1
 if message("variable.have_opened is not implemented") == 0 and am_spam() == 1 1
 if message("variable.have_opened is not implemented") == 0 and prepull_evo() == 1 1
 if 0 == 0 and enemies() > 2 1
}

AddFunction prepull_evo
{
 if message("variable.prepull_evo is not implemented") == 0 and equippedruneforge(siphon_storm_runeforge) and covenant(night_fae) 1
 if message("variable.prepull_evo is not implemented") == 0 and equippedruneforge(siphon_storm_runeforge) and covenant(necrolord) and enemies() > 1 1
 if 0 == 0 and equippedruneforge(siphon_storm_runeforge) and enemies() > 2 1
}

AddFunction final_burn
{
 if buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and not buffpresent(rule_of_threes) and fightremains() <= mana() / powercost(arcane_blast) * executetime(arcane_blast) 1
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

### actions.shared_cds

AddFunction arcaneshared_cdsmainactions
{
 #use_mana_gem,if=(talent.enlightened.enabled&mana.pct<=80&mana.pct>=65)|(!talent.enlightened.enabled&mana.pct<=85)
 if hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 spell(use_mana_gem)
 #berserking,if=buff.arcane_power.up
 if buffpresent(arcane_power) spell(berserking)
}

AddFunction arcaneshared_cdsmainpostconditions
{
}

AddFunction arcaneshared_cdsshortcdactions
{
 unless { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem)
 {
  #bag_of_tricks,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
  if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(bag_of_tricks)
 }
}

AddFunction arcaneshared_cdsshortcdpostconditions
{
 { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem) or buffpresent(arcane_power) and spell(berserking)
}

AddFunction arcaneshared_cdscdactions
{
 unless { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem)
 {
  #use_items,if=buff.arcane_power.up
  if buffpresent(arcane_power) arcaneuseitemactions()
  #potion,if=buff.arcane_power.up
  if buffpresent(arcane_power) and checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)
  #time_warp,if=runeforge.temporal_warp.equipped&buff.exhaustion.up
  if equippedruneforge(temporal_warp_runeforge) and buffpresent(exhaustion) and checkboxon(opt_time_warp) and debuffexpires(burst_haste_debuff any=1) spell(time_warp)
  #lights_judgment,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
  if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(lights_judgment)

  unless buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(bag_of_tricks) or buffpresent(arcane_power) and spell(berserking)
  {
   #blood_fury,if=buff.arcane_power.up
   if buffpresent(arcane_power) spell(blood_fury)
   #fireblood,if=buff.arcane_power.up
   if buffpresent(arcane_power) spell(fireblood)
   #ancestral_call,if=buff.arcane_power.up
   if buffpresent(arcane_power) spell(ancestral_call)
  }
 }
}

AddFunction arcaneshared_cdscdpostconditions
{
 { hastalent(enlightened_talent) and manapercent() <= 80 and manapercent() >= 65 or not hastalent(enlightened_talent) and manapercent() <= 85 } and spell(use_mana_gem) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(bag_of_tricks) or buffpresent(arcane_power) and spell(berserking)
}

### actions.rotation

AddFunction arcanerotationmainactions
{
 #variable,name=final_burn,op=set,value=1,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack&!buff.rule_of_threes.up&fight_remains<=((mana%action.arcane_blast.cost)*action.arcane_blast.execute_time)
 #arcane_barrage,if=cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack>variable.totm_max_charges&talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay&covenant.kyrian.enabled&cooldown.radiant_spark.remains<=8)
 if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and covenant(kyrian) and spellcooldown(radiant_spark) <= 8 spell(arcane_barrage)
 #arcane_barrage,if=cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack>variable.totm_max_charges&talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay&!covenant.kyrian.enabled)
 if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and not covenant(kyrian) spell(arcane_barrage)
 #arcane_barrage,if=cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack>variable.totm_max_charges&!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay)
 if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() spell(arcane_barrage)
 #arcane_barrage,if=cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack>variable.totm_max_charges&cooldown.arcane_power.remains<=gcd)
 if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and spellcooldown(arcane_power) <= gcd() spell(arcane_barrage)
 #strict_sequence,if=debuff.radiant_spark_vulnerability.stack=debuff.radiant_spark_vulnerability.max_stack&buff.arcane_power.down&buff.rune_of_power.down,name=last_spark_stack:arcane_blast:arcane_barrage
 if target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and buffexpires(arcane_power) and buffexpires(rune_of_power) spell(strict_sequence)
 #arcane_barrage,if=debuff.radiant_spark_vulnerability.stack=debuff.radiant_spark_vulnerability.max_stack&(buff.arcane_power.down|buff.arcane_power.remains<=gcd)&(buff.rune_of_power.down|buff.rune_of_power.remains<=gcd)
 if target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and { buffexpires(arcane_power) or buffremaining(arcane_power) <= gcd() } and { buffexpires(rune_of_power) or totemremaining(rune_of_power) <= gcd() } spell(arcane_barrage)
 #arcane_blast,if=dot.radiant_spark.remains>5|debuff.radiant_spark_vulnerability.stack>0
 if { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_blast,if=buff.presence_of_mind.up&debuff.touch_of_the_magi.up&debuff.touch_of_the_magi.remains<=action.arcane_blast.execute_time
 if buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_missiles,if=debuff.touch_of_the_magi.up&talent.arcane_echo.enabled&buff.deathborne.down&(debuff.touch_of_the_magi.remains>action.arcane_missiles.execute_time|cooldown.presence_of_mind.remains>0|covenant.kyrian.enabled)&(!azerite.arcane_pummeling.enabled|buff.clearcasting_channel.down),chain=1
 if target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and { target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) or spellcooldown(presence_of_mind) > 0 or covenant(kyrian) } and { not hasazeritetrait(arcane_pummeling_trait) or buffexpires(clearcasting_channel_buff) } spell(arcane_missiles)
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
 #arcane_orb,if=buff.arcane_charge.stack<=variable.totm_max_charges
 if buffstacks(arcane_charge_buff) <= totm_max_charges() spell(arcane_orb)
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
 #arcane_barrage,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.up&debuff.touch_of_the_magi.remains<=gcd&buff.arcane_charge.stack=buff.arcane_charge.max_stack
 if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) spell(arcane_barrage)
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
 unless not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and covenant(kyrian) and spellcooldown(radiant_spark) <= 8 and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and not covenant(kyrian) and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and spellcooldown(arcane_power) <= gcd() and spell(arcane_barrage) or target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and buffexpires(arcane_power) and buffexpires(rune_of_power) and spell(strict_sequence) or target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and { buffexpires(arcane_power) or buffremaining(arcane_power) <= gcd() } and { buffexpires(rune_of_power) or totemremaining(rune_of_power) <= gcd() } and spell(arcane_barrage) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and { target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) or spellcooldown(presence_of_mind) > 0 or covenant(kyrian) } and { not hasazeritetrait(arcane_pummeling_trait) or buffexpires(clearcasting_channel_buff) } and spell(arcane_missiles) or buffpresent(clearcasting) and buffpresent(expanded_potential_buff) and spell(arcane_missiles) or buffpresent(clearcasting) and { buffpresent(arcane_power) or buffpresent(rune_of_power) or target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) } and spell(arcane_missiles) or buffpresent(clearcasting) and buffstacks(clearcasting) == spelldata(clearcasting max_stacks) and spell(arcane_missiles) or buffpresent(clearcasting) and buffremaining(clearcasting) <= buffstacks(clearcasting) * executetime(arcane_missiles) + gcd() and spell(arcane_missiles) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and spell(nether_tempest) or buffstacks(arcane_charge_buff) <= totm_max_charges() and spell(arcane_orb) or manapercent() <= 95 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(supernova)
 {
  #shifting_power,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down&cooldown.evocation.remains>0&cooldown.arcane_power.remains>0&cooldown.touch_of_the_magi.remains>0&(!talent.rune_of_power.enabled|(talent.rune_of_power.enabled&cooldown.rune_of_power.remains>0))
  if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spellcooldown(evocation) > 0 and spellcooldown(arcane_power) > 0 and spellcooldown(touch_of_the_magi) > 0 and { not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > 0 } spell(shifting_power)
 }
}

AddFunction arcanerotationshortcdpostconditions
{
 not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and covenant(kyrian) and spellcooldown(radiant_spark) <= 8 and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and not covenant(kyrian) and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and spellcooldown(arcane_power) <= gcd() and spell(arcane_barrage) or target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and buffexpires(arcane_power) and buffexpires(rune_of_power) and spell(strict_sequence) or target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and { buffexpires(arcane_power) or buffremaining(arcane_power) <= gcd() } and { buffexpires(rune_of_power) or totemremaining(rune_of_power) <= gcd() } and spell(arcane_barrage) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and { target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) or spellcooldown(presence_of_mind) > 0 or covenant(kyrian) } and { not hasazeritetrait(arcane_pummeling_trait) or buffexpires(clearcasting_channel_buff) } and spell(arcane_missiles) or buffpresent(clearcasting) and buffpresent(expanded_potential_buff) and spell(arcane_missiles) or buffpresent(clearcasting) and { buffpresent(arcane_power) or buffpresent(rune_of_power) or target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) } and spell(arcane_missiles) or buffpresent(clearcasting) and buffstacks(clearcasting) == spelldata(clearcasting max_stacks) and spell(arcane_missiles) or buffpresent(clearcasting) and buffremaining(clearcasting) <= buffstacks(clearcasting) * executetime(arcane_missiles) + gcd() and spell(arcane_missiles) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and spell(nether_tempest) or buffstacks(arcane_charge_buff) <= totm_max_charges() and spell(arcane_orb) or manapercent() <= 95 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(supernova) or buffpresent(rule_of_threes) and buffstacks(arcane_charge_buff) > 3 and mana() > manacost(arcane_blast) and spell(arcane_blast) or manapercent() < barrage_mana_pct() and spellcooldown(evocation) > 0 and buffexpires(arcane_power) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and azeriteessenceisminor(vision_of_perfection_essence_id) and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and { not spellcooldown(rune_of_power) > 0 or not spellcooldown(arcane_power) > 0 } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or manapercent() <= barrage_mana_pct() and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spellcooldown(evocation) > 0 and spell(arcane_barrage) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and hastalent(arcane_orb_talent) and spellcooldown(arcane_orb) <= gcd() and manapercent() <= 90 and spellcooldown(evocation) > 0 and spell(arcane_barrage) or buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffpresent(rune_of_power) and totemremaining(rune_of_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
}

AddFunction arcanerotationcdactions
{
 unless not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and covenant(kyrian) and spellcooldown(radiant_spark) <= 8 and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and not covenant(kyrian) and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and spellcooldown(arcane_power) <= gcd() and spell(arcane_barrage) or target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and buffexpires(arcane_power) and buffexpires(rune_of_power) and spell(strict_sequence) or target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and { buffexpires(arcane_power) or buffremaining(arcane_power) <= gcd() } and { buffexpires(rune_of_power) or totemremaining(rune_of_power) <= gcd() } and spell(arcane_barrage) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and { target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) or spellcooldown(presence_of_mind) > 0 or covenant(kyrian) } and { not hasazeritetrait(arcane_pummeling_trait) or buffexpires(clearcasting_channel_buff) } and spell(arcane_missiles) or buffpresent(clearcasting) and buffpresent(expanded_potential_buff) and spell(arcane_missiles) or buffpresent(clearcasting) and { buffpresent(arcane_power) or buffpresent(rune_of_power) or target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) } and spell(arcane_missiles) or buffpresent(clearcasting) and buffstacks(clearcasting) == spelldata(clearcasting max_stacks) and spell(arcane_missiles) or buffpresent(clearcasting) and buffremaining(clearcasting) <= buffstacks(clearcasting) * executetime(arcane_missiles) + gcd() and spell(arcane_missiles) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and spell(nether_tempest) or buffstacks(arcane_charge_buff) <= totm_max_charges() and spell(arcane_orb) or manapercent() <= 95 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(supernova) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spellcooldown(evocation) > 0 and spellcooldown(arcane_power) > 0 and spellcooldown(touch_of_the_magi) > 0 and { not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > 0 } and spell(shifting_power) or buffpresent(rule_of_threes) and buffstacks(arcane_charge_buff) > 3 and mana() > manacost(arcane_blast) and spell(arcane_blast) or manapercent() < barrage_mana_pct() and spellcooldown(evocation) > 0 and buffexpires(arcane_power) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and azeriteessenceisminor(vision_of_perfection_essence_id) and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and { not spellcooldown(rune_of_power) > 0 or not spellcooldown(arcane_power) > 0 } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or manapercent() <= barrage_mana_pct() and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spellcooldown(evocation) > 0 and spell(arcane_barrage) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and hastalent(arcane_orb_talent) and spellcooldown(arcane_orb) <= gcd() and manapercent() <= 90 and spellcooldown(evocation) > 0 and spell(arcane_barrage) or buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffpresent(rune_of_power) and totemremaining(rune_of_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or mana() > manacost(arcane_blast) and spell(arcane_blast)
 {
  #evocation,interrupt_if=mana.pct>=85,interrupt_immediate=1
  spell(evocation)
 }
}

AddFunction arcanerotationcdpostconditions
{
 not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and covenant(kyrian) and spellcooldown(radiant_spark) <= 8 and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and not covenant(kyrian) and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) > totm_max_charges() and spellcooldown(arcane_power) <= gcd() and spell(arcane_barrage) or target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and buffexpires(arcane_power) and buffexpires(rune_of_power) and spell(strict_sequence) or target.debuffstacks(radiant_spark_vulnerability) == spelldata(radiant_spark_vulnerability max_stacks) and { buffexpires(arcane_power) or buffremaining(arcane_power) <= gcd() } and { buffexpires(rune_of_power) or totemremaining(rune_of_power) <= gcd() } and spell(arcane_barrage) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and { target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) or spellcooldown(presence_of_mind) > 0 or covenant(kyrian) } and { not hasazeritetrait(arcane_pummeling_trait) or buffexpires(clearcasting_channel_buff) } and spell(arcane_missiles) or buffpresent(clearcasting) and buffpresent(expanded_potential_buff) and spell(arcane_missiles) or buffpresent(clearcasting) and { buffpresent(arcane_power) or buffpresent(rune_of_power) or target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) } and spell(arcane_missiles) or buffpresent(clearcasting) and buffstacks(clearcasting) == spelldata(clearcasting max_stacks) and spell(arcane_missiles) or buffpresent(clearcasting) and buffremaining(clearcasting) <= buffstacks(clearcasting) * executetime(arcane_missiles) + gcd() and spell(arcane_missiles) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and spell(nether_tempest) or buffstacks(arcane_charge_buff) <= totm_max_charges() and spell(arcane_orb) or manapercent() <= 95 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(supernova) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spellcooldown(evocation) > 0 and spellcooldown(arcane_power) > 0 and spellcooldown(touch_of_the_magi) > 0 and { not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > 0 } and spell(shifting_power) or buffpresent(rule_of_threes) and buffstacks(arcane_charge_buff) > 3 and mana() > manacost(arcane_blast) and spell(arcane_blast) or manapercent() < barrage_mana_pct() and spellcooldown(evocation) > 0 and buffexpires(arcane_power) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and azeriteessenceisminor(vision_of_perfection_essence_id) and spell(arcane_barrage) or not spellcooldown(touch_of_the_magi) > 0 and { not spellcooldown(rune_of_power) > 0 or not spellcooldown(arcane_power) > 0 } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or manapercent() <= barrage_mana_pct() and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spellcooldown(evocation) > 0 and spell(arcane_barrage) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and hastalent(arcane_orb_talent) and spellcooldown(arcane_orb) <= gcd() and manapercent() <= 90 and spellcooldown(evocation) > 0 and spell(arcane_barrage) or buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffpresent(rune_of_power) and totemremaining(rune_of_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
}

### actions.precombat

AddFunction arcaneprecombatmainactions
{
 #variable,name=prepull_evo,op=reset,default=0
 #variable,name=prepull_evo,op=set,value=1,if=variable.prepull_evo=0&runeforge.siphon_storm.equipped&active_enemies>2
 #variable,name=prepull_evo,op=set,value=1,if=variable.prepull_evo=0&runeforge.siphon_storm.equipped&covenant.necrolord.enabled&active_enemies>1
 #variable,name=prepull_evo,op=set,value=1,if=variable.prepull_evo=0&runeforge.siphon_storm.equipped&covenant.night_fae.enabled
 #variable,name=have_opened,op=reset,default=0
 #variable,name=have_opened,op=set,value=1,if=variable.have_opened=0&active_enemies>2
 #variable,name=have_opened,op=set,value=1,if=variable.have_opened=0&variable.prepull_evo=1
 #variable,name=final_burn,op=set,value=0
 #variable,name=rs_max_delay,op=reset,default=5
 #variable,name=ap_max_delay,op=reset,default=10
 #variable,name=rop_max_delay,op=reset,default=20
 #variable,name=totm_max_delay,op=reset,default=5
 #variable,name=totm_max_delay,op=set,value=3,if=variable.totm_max_delay=5&runeforge.disciplinary_command.equipped
 #variable,name=totm_max_delay,op=set,value=15,if=variable.totm_max_delay=5&covenant.night_fae.enabled
 #variable,name=totm_max_delay,op=set,value=15,if=variable.totm_max_delay=5&conduit.arcane_prodigy.enabled&active_enemies<3
 #variable,name=totm_max_delay,op=set,value=30,if=variable.totm_max_delay=5&essence.vision_of_perfection.minor
 #variable,name=barrage_mana_pct,op=reset,default=70
 #variable,name=barrage_mana_pct,op=set,value=40,if=variable.barrage_mana_pct=70&covenant.night_fae.enabled
 #variable,name=ap_minimum_mana_pct,op=reset,default=30
 #variable,name=ap_minimum_mana_pct,op=set,value=50,if=variable.ap_minimum_mana_pct=30&runeforge.disciplinary_command.equipped
 #variable,name=ap_minimum_mana_pct,op=set,value=50,if=variable.ap_minimum_mana_pct=30&runeforge.grisly_icicle.equipped
 #variable,name=totm_max_charges,op=reset,default=2
 #variable,name=aoe_totm_max_charges,op=reset,default=2
 #variable,name=am_spam,op=reset,default=0
 #variable,name=have_opened,op=set,value=1,if=variable.have_opened=0&variable.am_spam=1
 #flask
 #food
 #augmentation
 #arcane_familiar
 spell(arcane_familiar)
 #arcane_intellect
 spell(arcane_intellect)
 #conjure_mana_gem
 spell(conjure_mana_gem)
 #frostbolt,if=variable.prepull_evo<=0
 if prepull_evo() <= 0 spell(frostbolt)
}

AddFunction arcaneprecombatmainpostconditions
{
}

AddFunction arcaneprecombatshortcdactions
{
}

AddFunction arcaneprecombatshortcdpostconditions
{
 spell(arcane_familiar) or spell(arcane_intellect) or spell(conjure_mana_gem) or prepull_evo() <= 0 and spell(frostbolt)
}

AddFunction arcaneprecombatcdactions
{
 unless spell(arcane_familiar) or spell(arcane_intellect) or spell(conjure_mana_gem)
 {
  #snapshot_stats
  #mirror_image
  spell(mirror_image)

  unless prepull_evo() <= 0 and spell(frostbolt)
  {
   #evocation,if=variable.prepull_evo>0
   if prepull_evo() > 0 spell(evocation)
  }
 }
}

AddFunction arcaneprecombatcdpostconditions
{
 spell(arcane_familiar) or spell(arcane_intellect) or spell(conjure_mana_gem) or prepull_evo() <= 0 and spell(frostbolt)
}

### actions.opener

AddFunction arcaneopenermainactions
{
 #variable,name=have_opened,op=set,value=1,if=prev_gcd.1.evocation
 #fire_blast,if=runeforge.disciplinary_command.equipped&buff.disciplinary_command_frost.up
 if equippedruneforge(disciplinary_command_runeforge) and buffpresent(disciplinary_command_frost_buff) spell(fire_blast)
 #cancel_action,if=action.shifting_power.channeling&gcd.remains=0
 if message("action.shifting_power.channeling is not implemented") and not gcdremaining() > 0 spell(cancel_action)
 #rune_of_power,if=buff.rune_of_power.down
 if buffexpires(rune_of_power) spell(rune_of_power)
 #arcane_blast,if=dot.radiant_spark.remains>5|debuff.radiant_spark_vulnerability.stack>0
 if { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_blast,if=buff.presence_of_mind.up&debuff.touch_of_the_magi.up&debuff.touch_of_the_magi.remains<=action.arcane_blast.execute_time
 if buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_barrage,if=buff.arcane_power.up&buff.arcane_power.remains<=gcd&buff.arcane_charge.stack=buff.arcane_charge.max_stack
 if buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) spell(arcane_barrage)
 #arcane_missiles,if=debuff.touch_of_the_magi.up&talent.arcane_echo.enabled&buff.deathborne.down&debuff.touch_of_the_magi.remains>action.arcane_missiles.execute_time&(!azerite.arcane_pummeling.enabled|buff.clearcasting_channel.down),chain=1
 if target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) and { not hasazeritetrait(arcane_pummeling_trait) or buffexpires(clearcasting_channel_buff) } spell(arcane_missiles)
 #arcane_missiles,if=buff.clearcasting.react,chain=1
 if buffpresent(clearcasting) spell(arcane_missiles)
 #arcane_orb,if=buff.arcane_charge.stack<=variable.totm_max_charges&(cooldown.arcane_power.remains>10|active_enemies<=2)
 if buffstacks(arcane_charge_buff) <= totm_max_charges() and { spellcooldown(arcane_power) > 10 or enemies() <= 2 } spell(arcane_orb)
 #arcane_blast,if=buff.rune_of_power.up|mana.pct>15
 if { buffpresent(rune_of_power) or manapercent() > 15 } and mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_barrage
 spell(arcane_barrage)
}

AddFunction arcaneopenermainpostconditions
{
}

AddFunction arcaneopenershortcdactions
{
 unless equippedruneforge(disciplinary_command_runeforge) and buffpresent(disciplinary_command_frost_buff) and spell(fire_blast)
 {
  #frost_nova,if=runeforge.grisly_icicle.equipped&mana.pct>95
  if equippedruneforge(grisly_icicle_runeforge) and manapercent() > 95 spell(frost_nova)
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

   unless buffexpires(rune_of_power) and spell(rune_of_power)
   {
    #presence_of_mind
    spell(presence_of_mind)
   }
  }
 }
}

AddFunction arcaneopenershortcdpostconditions
{
 equippedruneforge(disciplinary_command_runeforge) and buffpresent(disciplinary_command_frost_buff) and spell(fire_blast) or message("action.shifting_power.channeling is not implemented") and not gcdremaining() > 0 and spell(cancel_action) or buffexpires(rune_of_power) and spell(rune_of_power) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) and { not hasazeritetrait(arcane_pummeling_trait) or buffexpires(clearcasting_channel_buff) } and spell(arcane_missiles) or buffpresent(clearcasting) and spell(arcane_missiles) or buffstacks(arcane_charge_buff) <= totm_max_charges() and { spellcooldown(arcane_power) > 10 or enemies() <= 2 } and spell(arcane_orb) or { buffpresent(rune_of_power) or manapercent() > 15 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
}

AddFunction arcaneopenercdactions
{
 unless equippedruneforge(disciplinary_command_runeforge) and buffpresent(disciplinary_command_frost_buff) and spell(fire_blast) or equippedruneforge(grisly_icicle_runeforge) and manapercent() > 95 and spell(frost_nova) or spell(mirrors_of_torment)
 {
  #deathborne
  spell(deathborne)

  unless manapercent() > 40 and spell(radiant_spark) or message("action.shifting_power.channeling is not implemented") and not gcdremaining() > 0 and spell(cancel_action) or message("soulbind.field_of_blossoms.enabled is not implemented") and spell(shifting_power) or spell(touch_of_the_magi)
  {
   #arcane_power
   spell(arcane_power)

   unless buffexpires(rune_of_power) and spell(rune_of_power) or spell(presence_of_mind) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) and { not hasazeritetrait(arcane_pummeling_trait) or buffexpires(clearcasting_channel_buff) } and spell(arcane_missiles) or buffpresent(clearcasting) and spell(arcane_missiles) or buffstacks(arcane_charge_buff) <= totm_max_charges() and { spellcooldown(arcane_power) > 10 or enemies() <= 2 } and spell(arcane_orb) or { buffpresent(rune_of_power) or manapercent() > 15 } and mana() > manacost(arcane_blast) and spell(arcane_blast)
   {
    #evocation,if=buff.rune_of_power.down,interrupt_if=mana.pct>=85,interrupt_immediate=1
    if buffexpires(rune_of_power) spell(evocation)
   }
  }
 }
}

AddFunction arcaneopenercdpostconditions
{
 equippedruneforge(disciplinary_command_runeforge) and buffpresent(disciplinary_command_frost_buff) and spell(fire_blast) or equippedruneforge(grisly_icicle_runeforge) and manapercent() > 95 and spell(frost_nova) or spell(mirrors_of_torment) or manapercent() > 40 and spell(radiant_spark) or message("action.shifting_power.channeling is not implemented") and not gcdremaining() > 0 and spell(cancel_action) or message("soulbind.field_of_blossoms.enabled is not implemented") and spell(shifting_power) or spell(touch_of_the_magi) or buffexpires(rune_of_power) and spell(rune_of_power) or spell(presence_of_mind) or { target.debuffremaining(radiant_spark) > 5 or target.debuffstacks(radiant_spark_vulnerability) > 0 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(presence_of_mind) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= executetime(arcane_blast) and mana() > manacost(arcane_blast) and spell(arcane_blast) or buffpresent(arcane_power) and buffremaining(arcane_power) <= gcd() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or target.debuffpresent(touch_of_the_magi) and hastalent(arcane_echo_talent) and buffexpires(deathborne) and target.debuffremaining(touch_of_the_magi) > executetime(arcane_missiles) and { not hasazeritetrait(arcane_pummeling_trait) or buffexpires(clearcasting_channel_buff) } and spell(arcane_missiles) or buffpresent(clearcasting) and spell(arcane_missiles) or buffstacks(arcane_charge_buff) <= totm_max_charges() and { spellcooldown(arcane_power) > 10 or enemies() <= 2 } and spell(arcane_orb) or { buffpresent(rune_of_power) or manapercent() > 15 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
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
 #blood_of_the_enemy,if=cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.totm_max_charges&cooldown.arcane_power.remains<=gcd|fight_remains<cooldown.arcane_power.remains
 if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() or fightremains() < spellcooldown(arcane_power) spell(blood_of_the_enemy)
 #blood_of_the_enemy,if=cooldown.arcane_power.remains=0&(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70|variable.am_spam=1))&((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&(buff.arcane_charge.stack=buff.arcane_charge.max_stack|variable.am_spam=1))|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
 if not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 or am_spam() == 1 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and { buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or am_spam() == 1 } or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(blood_of_the_enemy)
 #worldvein_resonance,if=cooldown.arcane_power.remains>=50&cooldown.touch_of_the_magi.remains<=gcd&buff.arcane_charge.stack<=variable.totm_max_charges&talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay
 if spellcooldown(arcane_power) >= 50 and spellcooldown(touch_of_the_magi) <= gcd() and buffstacks(arcane_charge_buff) <= totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() spell(worldvein_resonance)
 #worldvein_resonance,if=cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.totm_max_charges&cooldown.arcane_power.remains<=gcd|fight_remains<cooldown.arcane_power.remains
 if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() or fightremains() < spellcooldown(arcane_power) spell(worldvein_resonance)
 #worldvein_resonance,if=cooldown.arcane_power.remains=0&(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70|variable.am_spam=1))&((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&(buff.arcane_charge.stack=buff.arcane_charge.max_stack|variable.am_spam=1))|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
 if not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 or am_spam() == 1 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and { buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or am_spam() == 1 } or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(worldvein_resonance)
 #concentrated_flame,line_cd=6,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down&mana.time_to_max>=execute_time
 if timesincepreviousspell(concentrated_flame) > 6 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and timetomaxmana() >= executetime(concentrated_flame) spell(concentrated_flame)
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
 unless { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() or fightremains() < spellcooldown(arcane_power) } and spell(blood_of_the_enemy) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 or am_spam() == 1 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and { buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or am_spam() == 1 } or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(blood_of_the_enemy) or spellcooldown(arcane_power) >= 50 and spellcooldown(touch_of_the_magi) <= gcd() and buffstacks(arcane_charge_buff) <= totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and spell(worldvein_resonance) or { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() or fightremains() < spellcooldown(arcane_power) } and spell(worldvein_resonance) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 or am_spam() == 1 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and { buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or am_spam() == 1 } or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(worldvein_resonance) or timesincepreviousspell(concentrated_flame) > 6 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and timetomaxmana() >= executetime(concentrated_flame) and spell(concentrated_flame)
 {
  #reaping_flames,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down&mana.time_to_max>=execute_time
  if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and timetomaxmana() >= executetime(reaping_flames) spell(reaping_flames)
  #focused_azerite_beam,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
  if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(focused_azerite_beam)
  #purifying_blast,if=buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down
  if buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) spell(purifying_blast)
 }
}

AddFunction arcaneessencesshortcdpostconditions
{
 { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() or fightremains() < spellcooldown(arcane_power) } and spell(blood_of_the_enemy) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 or am_spam() == 1 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and { buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or am_spam() == 1 } or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(blood_of_the_enemy) or spellcooldown(arcane_power) >= 50 and spellcooldown(touch_of_the_magi) <= gcd() and buffstacks(arcane_charge_buff) <= totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and spell(worldvein_resonance) or { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() or fightremains() < spellcooldown(arcane_power) } and spell(worldvein_resonance) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 or am_spam() == 1 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and { buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or am_spam() == 1 } or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(worldvein_resonance) or timesincepreviousspell(concentrated_flame) > 6 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and timetomaxmana() >= executetime(concentrated_flame) and spell(concentrated_flame) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(ripple_in_space) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(the_unbound_force) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(memory_of_lucid_dreams)
}

AddFunction arcaneessencescdactions
{
 unless { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() or fightremains() < spellcooldown(arcane_power) } and spell(blood_of_the_enemy) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 or am_spam() == 1 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and { buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or am_spam() == 1 } or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(blood_of_the_enemy) or spellcooldown(arcane_power) >= 50 and spellcooldown(touch_of_the_magi) <= gcd() and buffstacks(arcane_charge_buff) <= totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and spell(worldvein_resonance) or { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() or fightremains() < spellcooldown(arcane_power) } and spell(worldvein_resonance) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 or am_spam() == 1 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and { buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or am_spam() == 1 } or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(worldvein_resonance)
 {
  #guardian_of_azeroth,if=cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.totm_max_charges&cooldown.arcane_power.remains<=gcd|fight_remains<cooldown.arcane_power.remains
  if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() or fightremains() < spellcooldown(arcane_power) spell(guardian_of_azeroth)
  #guardian_of_azeroth,if=cooldown.arcane_power.remains=0&(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70|variable.am_spam=1))&((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&(buff.arcane_charge.stack=buff.arcane_charge.max_stack|variable.am_spam=1))|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
  if not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 or am_spam() == 1 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and { buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or am_spam() == 1 } or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(guardian_of_azeroth)
 }
}

AddFunction arcaneessencescdpostconditions
{
 { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() or fightremains() < spellcooldown(arcane_power) } and spell(blood_of_the_enemy) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 or am_spam() == 1 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and { buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or am_spam() == 1 } or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(blood_of_the_enemy) or spellcooldown(arcane_power) >= 50 and spellcooldown(touch_of_the_magi) <= gcd() and buffstacks(arcane_charge_buff) <= totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and spell(worldvein_resonance) or { not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() or fightremains() < spellcooldown(arcane_power) } and spell(worldvein_resonance) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 or am_spam() == 1 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and { buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or am_spam() == 1 } or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(worldvein_resonance) or timesincepreviousspell(concentrated_flame) > 6 and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and timetomaxmana() >= executetime(concentrated_flame) and spell(concentrated_flame) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and timetomaxmana() >= executetime(reaping_flames) and spell(reaping_flames) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(focused_azerite_beam) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(purifying_blast) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(ripple_in_space) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(the_unbound_force) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spell(memory_of_lucid_dreams)
}

### actions.cooldowns

AddFunction arcanecooldownsmainactions
{
 #frostbolt,if=runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_frost.down&(buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down)&cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack<=variable.totm_max_charges&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay)|cooldown.arcane_power.remains<=gcd))
 if equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } spell(frostbolt)
 #fire_blast,if=runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_fire.down&prev_gcd.1.frostbolt
 if equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) spell(fire_blast)
 #rune_of_power,if=buff.rune_of_power.down&cooldown.touch_of_the_magi.remains>variable.rop_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack&(cooldown.arcane_power.remains>15|debuff.touch_of_the_magi.up)
 if buffexpires(rune_of_power) and spellcooldown(touch_of_the_magi) > rop_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } spell(rune_of_power)
}

AddFunction arcanecooldownsmainpostconditions
{
}

AddFunction arcanecooldownsshortcdactions
{
 #frost_nova,if=runeforge.grisly_icicle.equipped&cooldown.arcane_power.remains>30&cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack<=variable.totm_max_charges&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay)|cooldown.arcane_power.remains<=gcd))
 if equippedruneforge(grisly_icicle_runeforge) and spellcooldown(arcane_power) > 30 and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } spell(frost_nova)
 #frost_nova,if=runeforge.grisly_icicle.equipped&cooldown.arcane_power.remains=0&(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70))&((cooldown.touch_of_the_magi.remains>10&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
 if equippedruneforge(grisly_icicle_runeforge) and not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(frost_nova)

 unless equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) and spell(fire_blast)
 {
  #mirrors_of_torment,if=cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.totm_max_charges&cooldown.arcane_power.remains<=gcd
  if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() spell(mirrors_of_torment)
  #mirrors_of_torment,if=cooldown.arcane_power.remains=0&(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70))&((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
  if not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(mirrors_of_torment)
  #radiant_spark,if=cooldown.touch_of_the_magi.remains>variable.rs_max_delay&cooldown.arcane_power.remains>variable.rs_max_delay&(talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd|talent.rune_of_power.enabled&cooldown.rune_of_power.remains>variable.rs_max_delay|!talent.rune_of_power.enabled)&buff.arcane_charge.stack>2&debuff.touch_of_the_magi.down
  if spellcooldown(touch_of_the_magi) > rs_max_delay() and spellcooldown(arcane_power) > rs_max_delay() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > rs_max_delay() or not hastalent(rune_of_power_talent) } and buffstacks(arcane_charge_buff) > 2 and target.debuffexpires(touch_of_the_magi) spell(radiant_spark)
  #radiant_spark,if=cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.totm_max_charges&cooldown.arcane_power.remains<=gcd
  if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() spell(radiant_spark)
  #radiant_spark,if=cooldown.arcane_power.remains=0&((!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70))&((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct)
  if not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(radiant_spark)
  #touch_of_the_magi,if=cooldown.arcane_power.remains<50&essence.vision_of_perfection.minor
  if spellcooldown(arcane_power) < 50 and azeriteessenceisminor(vision_of_perfection_essence_id) spell(touch_of_the_magi)
  #touch_of_the_magi,if=buff.arcane_charge.stack<=variable.totm_max_charges&talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay&covenant.kyrian.enabled&cooldown.radiant_spark.remains<=8
  if buffstacks(arcane_charge_buff) <= totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and covenant(kyrian) and spellcooldown(radiant_spark) <= 8 spell(touch_of_the_magi)
  #touch_of_the_magi,if=buff.arcane_charge.stack<=variable.totm_max_charges&talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay&!covenant.kyrian.enabled
  if buffstacks(arcane_charge_buff) <= totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and not covenant(kyrian) spell(touch_of_the_magi)
  #touch_of_the_magi,if=buff.arcane_charge.stack<=variable.totm_max_charges&!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay
  if buffstacks(arcane_charge_buff) <= totm_max_charges() and not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() spell(touch_of_the_magi)
  #touch_of_the_magi,if=buff.arcane_charge.stack<=variable.totm_max_charges&cooldown.arcane_power.remains<=gcd
  if buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() spell(touch_of_the_magi)

  unless buffexpires(rune_of_power) and spellcooldown(touch_of_the_magi) > rop_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power)
  {
   #presence_of_mind,if=buff.arcane_charge.stack=0&covenant.kyrian.enabled
   if buffstacks(arcane_charge_buff) == 0 and covenant(kyrian) spell(presence_of_mind)
   #presence_of_mind,if=debuff.touch_of_the_magi.up&!covenant.kyrian.enabled
   if target.debuffpresent(touch_of_the_magi) and not covenant(kyrian) spell(presence_of_mind)
  }
 }
}

AddFunction arcanecooldownsshortcdpostconditions
{
 equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) and spell(fire_blast) or buffexpires(rune_of_power) and spellcooldown(touch_of_the_magi) > rop_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power)
}

AddFunction arcanecooldownscdactions
{
 unless equippedruneforge(grisly_icicle_runeforge) and spellcooldown(arcane_power) > 30 and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frost_nova) or equippedruneforge(grisly_icicle_runeforge) and not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(frost_nova) or equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) and spell(fire_blast) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() and spell(mirrors_of_torment) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(mirrors_of_torment)
 {
  #deathborne,if=cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.totm_max_charges&cooldown.arcane_power.remains<=gcd
  if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() spell(deathborne)
  #deathborne,if=cooldown.arcane_power.remains=0&(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70))&((cooldown.touch_of_the_magi.remains>10&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack=0))&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
  if not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(deathborne)

  unless spellcooldown(touch_of_the_magi) > rs_max_delay() and spellcooldown(arcane_power) > rs_max_delay() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > rs_max_delay() or not hastalent(rune_of_power_talent) } and buffstacks(arcane_charge_buff) > 2 and target.debuffexpires(touch_of_the_magi) and spell(radiant_spark) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() and spell(radiant_spark) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(radiant_spark) or spellcooldown(arcane_power) < 50 and azeriteessenceisminor(vision_of_perfection_essence_id) and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and covenant(kyrian) and spellcooldown(radiant_spark) <= 8 and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and not covenant(kyrian) and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= totm_max_charges() and not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() and spell(touch_of_the_magi)
  {
   #arcane_power,if=(!talent.enlightened.enabled|(talent.enlightened.enabled&mana.pct>=70))&cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack&buff.rune_of_power.down&mana.pct>=variable.ap_minimum_mana_pct
   if { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() spell(arcane_power)
  }
 }
}

AddFunction arcanecooldownscdpostconditions
{
 equippedruneforge(grisly_icicle_runeforge) and spellcooldown(arcane_power) > 30 and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frost_nova) or equippedruneforge(grisly_icicle_runeforge) and not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > 10 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(frost_nova) or equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) and spell(fire_blast) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() and spell(mirrors_of_torment) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(mirrors_of_torment) or spellcooldown(touch_of_the_magi) > rs_max_delay() and spellcooldown(arcane_power) > rs_max_delay() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > rs_max_delay() or not hastalent(rune_of_power_talent) } and buffstacks(arcane_charge_buff) > 2 and target.debuffexpires(touch_of_the_magi) and spell(radiant_spark) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() and spell(radiant_spark) or not spellcooldown(arcane_power) > 0 and { not hastalent(enlightened_talent) or hastalent(enlightened_talent) and manapercent() >= 70 } and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) == 0 } and buffexpires(rune_of_power) and manapercent() >= ap_minimum_mana_pct() and spell(radiant_spark) or spellcooldown(arcane_power) < 50 and azeriteessenceisminor(vision_of_perfection_essence_id) and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and covenant(kyrian) and spellcooldown(radiant_spark) <= 8 and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= totm_max_charges() and hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() and not covenant(kyrian) and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= totm_max_charges() and not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() and spell(touch_of_the_magi) or buffstacks(arcane_charge_buff) <= totm_max_charges() and spellcooldown(arcane_power) <= gcd() and spell(touch_of_the_magi) or buffexpires(rune_of_power) and spellcooldown(touch_of_the_magi) > rop_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power) or buffstacks(arcane_charge_buff) == 0 and covenant(kyrian) and spell(presence_of_mind) or target.debuffpresent(touch_of_the_magi) and not covenant(kyrian) and spell(presence_of_mind)
}

### actions.aoe

AddFunction arcaneaoemainactions
{
 #frostbolt,if=runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_frost.down&(buff.arcane_power.down&buff.rune_of_power.down&debuff.touch_of_the_magi.down)&cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack<=variable.aoe_totm_max_charges&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay)|cooldown.arcane_power.remains<=gcd))
 if equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } spell(frostbolt)
 #fire_blast,if=(runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_fire.down&prev_gcd.1.frostbolt)|(runeforge.disciplinary_command.equipped&time=0)
 if equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) or equippedruneforge(disciplinary_command_runeforge) and timeincombat() == 0 spell(fire_blast)
 #rune_of_power,if=buff.rune_of_power.down&((cooldown.touch_of_the_magi.remains>20&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.aoe_totm_max_charges))&(cooldown.arcane_power.remains>15|debuff.touch_of_the_magi.up)
 if buffexpires(rune_of_power) and { spellcooldown(touch_of_the_magi) > 20 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } spell(rune_of_power)
 #arcane_blast,if=buff.deathborne.up&((talent.resonance.enabled&active_enemies<4)|active_enemies<5)
 if buffpresent(deathborne) and { hastalent(resonance_talent) and enemies() < 4 or enemies() < 5 } and mana() > manacost(arcane_blast) spell(arcane_blast)
 #supernova
 spell(supernova)
 #arcane_orb,if=buff.arcane_charge.stack=0
 if buffstacks(arcane_charge_buff) == 0 spell(arcane_orb)
 #nether_tempest,if=(refreshable|!ticking)&buff.arcane_charge.stack=buff.arcane_charge.max_stack
 if { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) spell(nether_tempest)
 #arcane_missiles,if=buff.clearcasting.react&runeforge.arcane_infinity.equipped&talent.amplification.enabled&active_enemies<9
 if buffpresent(clearcasting) and equippedruneforge(arcane_infinity_runeforge) and hastalent(amplification_talent) and enemies() < 9 spell(arcane_missiles)
 #arcane_missiles,if=buff.clearcasting.react&runeforge.arcane_infinity.equipped&active_enemies<6
 if buffpresent(clearcasting) and equippedruneforge(arcane_infinity_runeforge) and enemies() < 6 spell(arcane_missiles)
 #arcane_explosion,if=buff.arcane_charge.stack<buff.arcane_charge.max_stack
 if buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) spell(arcane_explosion)
 #arcane_explosion,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack&prev_gcd.1.arcane_barrage
 if buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and previousgcdspell(arcane_barrage) spell(arcane_explosion)
 #arcane_barrage,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack
 if buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) spell(arcane_barrage)
}

AddFunction arcaneaoemainpostconditions
{
}

AddFunction arcaneaoeshortcdactions
{
 unless equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or { equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) or equippedruneforge(disciplinary_command_runeforge) and timeincombat() == 0 } and spell(fire_blast)
 {
  #frost_nova,if=runeforge.grisly_icicle.equipped&cooldown.arcane_power.remains>30&cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack<=variable.aoe_totm_max_charges&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay)|cooldown.arcane_power.remains<=gcd))
  if equippedruneforge(grisly_icicle_runeforge) and spellcooldown(arcane_power) > 30 and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } spell(frost_nova)
  #frost_nova,if=runeforge.grisly_icicle.equipped&cooldown.arcane_power.remains=0&(((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.aoe_totm_max_charges))&buff.rune_of_power.down)
  if equippedruneforge(grisly_icicle_runeforge) and not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and buffexpires(rune_of_power) spell(frost_nova)
  #touch_of_the_magi,if=runeforge.siphon_storm.equipped&prev_gcd.1.evocation
  if equippedruneforge(siphon_storm_runeforge) and previousgcdspell(evocation) spell(touch_of_the_magi)
  #mirrors_of_torment,if=(cooldown.arcane_power.remains>45|cooldown.arcane_power.remains<=3)&cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack<=variable.aoe_totm_max_charges&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>5)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>5)|cooldown.arcane_power.remains<=gcd))
  if { spellcooldown(arcane_power) > 45 or spellcooldown(arcane_power) <= 3 } and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > 5 or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > 5 or spellcooldown(arcane_power) <= gcd() } spell(mirrors_of_torment)
  #radiant_spark,if=cooldown.touch_of_the_magi.remains>variable.rs_max_delay&cooldown.arcane_power.remains>variable.rs_max_delay&(talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd|talent.rune_of_power.enabled&cooldown.rune_of_power.remains>variable.rs_max_delay|!talent.rune_of_power.enabled)&buff.arcane_charge.stack<=variable.aoe_totm_max_charges&debuff.touch_of_the_magi.down
  if spellcooldown(touch_of_the_magi) > rs_max_delay() and spellcooldown(arcane_power) > rs_max_delay() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > rs_max_delay() or not hastalent(rune_of_power_talent) } and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and target.debuffexpires(touch_of_the_magi) spell(radiant_spark)
  #radiant_spark,if=cooldown.touch_of_the_magi.remains=0&(buff.arcane_charge.stack<=variable.aoe_totm_max_charges&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay)|cooldown.arcane_power.remains<=gcd))
  if not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } spell(radiant_spark)
  #radiant_spark,if=cooldown.arcane_power.remains=0&(((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.aoe_totm_max_charges))&buff.rune_of_power.down)
  if not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and buffexpires(rune_of_power) spell(radiant_spark)
  #touch_of_the_magi,if=buff.arcane_charge.stack<=variable.aoe_totm_max_charges&((talent.rune_of_power.enabled&cooldown.rune_of_power.remains<=gcd&cooldown.arcane_power.remains>variable.totm_max_delay)|(!talent.rune_of_power.enabled&cooldown.arcane_power.remains>variable.totm_max_delay)|cooldown.arcane_power.remains<=gcd)
  if buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } spell(touch_of_the_magi)

  unless buffexpires(rune_of_power) and { spellcooldown(touch_of_the_magi) > 20 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power)
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

AddFunction arcaneaoeshortcdpostconditions
{
 equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or { equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) or equippedruneforge(disciplinary_command_runeforge) and timeincombat() == 0 } and spell(fire_blast) or buffexpires(rune_of_power) and { spellcooldown(touch_of_the_magi) > 20 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power) or buffpresent(deathborne) and { hastalent(resonance_talent) and enemies() < 4 or enemies() < 5 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(supernova) or buffstacks(arcane_charge_buff) == 0 and spell(arcane_orb) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(nether_tempest) or buffpresent(clearcasting) and equippedruneforge(arcane_infinity_runeforge) and hastalent(amplification_talent) and enemies() < 9 and spell(arcane_missiles) or buffpresent(clearcasting) and equippedruneforge(arcane_infinity_runeforge) and enemies() < 6 and spell(arcane_missiles) or buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) and spell(arcane_explosion) or buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and previousgcdspell(arcane_barrage) and spell(arcane_explosion) or buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage)
}

AddFunction arcaneaoecdactions
{
 unless equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or { equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) or equippedruneforge(disciplinary_command_runeforge) and timeincombat() == 0 } and spell(fire_blast) or equippedruneforge(grisly_icicle_runeforge) and spellcooldown(arcane_power) > 30 and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frost_nova) or equippedruneforge(grisly_icicle_runeforge) and not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and buffexpires(rune_of_power) and spell(frost_nova) or equippedruneforge(siphon_storm_runeforge) and previousgcdspell(evocation) and spell(touch_of_the_magi)
 {
  #arcane_power,if=runeforge.siphon_storm.equipped&(prev_gcd.1.evocation|prev_gcd.1.touch_of_the_magi)
  if equippedruneforge(siphon_storm_runeforge) and { previousgcdspell(evocation) or previousgcdspell(touch_of_the_magi) } spell(arcane_power)
  #evocation,if=time>30&runeforge.siphon_storm.equipped&buff.arcane_charge.stack<=variable.aoe_totm_max_charges&cooldown.touch_of_the_magi.remains=0&cooldown.arcane_power.remains<=gcd
  if timeincombat() > 30 and equippedruneforge(siphon_storm_runeforge) and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and not spellcooldown(touch_of_the_magi) > 0 and spellcooldown(arcane_power) <= gcd() spell(evocation)
  #evocation,if=time>30&runeforge.siphon_storm.equipped&cooldown.arcane_power.remains=0&(((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.aoe_totm_max_charges))&buff.rune_of_power.down),interrupt_if=buff.siphon_storm.stack=buff.siphon_storm.max_stack,interrupt_immediate=1
  if timeincombat() > 30 and equippedruneforge(siphon_storm_runeforge) and not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and buffexpires(rune_of_power) spell(evocation)

  unless { spellcooldown(arcane_power) > 45 or spellcooldown(arcane_power) <= 3 } and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > 5 or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > 5 or spellcooldown(arcane_power) <= gcd() } and spell(mirrors_of_torment) or spellcooldown(touch_of_the_magi) > rs_max_delay() and spellcooldown(arcane_power) > rs_max_delay() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > rs_max_delay() or not hastalent(rune_of_power_talent) } and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and target.debuffexpires(touch_of_the_magi) and spell(radiant_spark) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(radiant_spark) or not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and buffexpires(rune_of_power) and spell(radiant_spark)
  {
   #deathborne,if=cooldown.arcane_power.remains=0&(((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.aoe_totm_max_charges))&buff.rune_of_power.down)
   if not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and buffexpires(rune_of_power) spell(deathborne)

   unless buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(touch_of_the_magi)
   {
    #arcane_power,if=((cooldown.touch_of_the_magi.remains>variable.ap_max_delay&buff.arcane_charge.stack=buff.arcane_charge.max_stack)|(cooldown.touch_of_the_magi.remains=0&buff.arcane_charge.stack<=variable.aoe_totm_max_charges))&buff.rune_of_power.down
    if { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and buffexpires(rune_of_power) spell(arcane_power)

    unless buffexpires(rune_of_power) and { spellcooldown(touch_of_the_magi) > 20 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power) or buffpresent(deathborne) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= spelldata(presence_of_mind max_stacks) * executetime(arcane_blast) and spell(presence_of_mind) or buffpresent(deathborne) and { hastalent(resonance_talent) and enemies() < 4 or enemies() < 5 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(supernova) or buffstacks(arcane_charge_buff) == 0 and spell(arcane_orb) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(nether_tempest) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spellcooldown(arcane_power) > 0 and spellcooldown(touch_of_the_magi) > 0 and { not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > 0 } and spell(shifting_power) or buffpresent(clearcasting) and equippedruneforge(arcane_infinity_runeforge) and hastalent(amplification_talent) and enemies() < 9 and spell(arcane_missiles) or buffpresent(clearcasting) and equippedruneforge(arcane_infinity_runeforge) and enemies() < 6 and spell(arcane_missiles) or buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) and spell(arcane_explosion) or buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and previousgcdspell(arcane_barrage) and spell(arcane_explosion) or buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage)
    {
     #evocation,interrupt_if=mana.pct>=85,interrupt_immediate=1
     spell(evocation)
    }
   }
  }
 }
}

AddFunction arcaneaoecdpostconditions
{
 equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frostbolt) or { equippedruneforge(disciplinary_command_runeforge) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and previousgcdspell(frostbolt) or equippedruneforge(disciplinary_command_runeforge) and timeincombat() == 0 } and spell(fire_blast) or equippedruneforge(grisly_icicle_runeforge) and spellcooldown(arcane_power) > 30 and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(frost_nova) or equippedruneforge(grisly_icicle_runeforge) and not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and buffexpires(rune_of_power) and spell(frost_nova) or equippedruneforge(siphon_storm_runeforge) and previousgcdspell(evocation) and spell(touch_of_the_magi) or { spellcooldown(arcane_power) > 45 or spellcooldown(arcane_power) <= 3 } and not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > 5 or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > 5 or spellcooldown(arcane_power) <= gcd() } and spell(mirrors_of_torment) or spellcooldown(touch_of_the_magi) > rs_max_delay() and spellcooldown(arcane_power) > rs_max_delay() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > rs_max_delay() or not hastalent(rune_of_power_talent) } and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and target.debuffexpires(touch_of_the_magi) and spell(radiant_spark) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(radiant_spark) or not spellcooldown(arcane_power) > 0 and { spellcooldown(touch_of_the_magi) > ap_max_delay() and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and buffexpires(rune_of_power) and spell(radiant_spark) or buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() and { hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) <= gcd() and spellcooldown(arcane_power) > totm_max_delay() or not hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > totm_max_delay() or spellcooldown(arcane_power) <= gcd() } and spell(touch_of_the_magi) or buffexpires(rune_of_power) and { spellcooldown(touch_of_the_magi) > 20 and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) or not spellcooldown(touch_of_the_magi) > 0 and buffstacks(arcane_charge_buff) <= aoe_totm_max_charges() } and { spellcooldown(arcane_power) > 15 or target.debuffpresent(touch_of_the_magi) } and spell(rune_of_power) or buffpresent(deathborne) and target.debuffpresent(touch_of_the_magi) and target.debuffremaining(touch_of_the_magi) <= spelldata(presence_of_mind max_stacks) * executetime(arcane_blast) and spell(presence_of_mind) or buffpresent(deathborne) and { hastalent(resonance_talent) and enemies() < 4 or enemies() < 5 } and mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(supernova) or buffstacks(arcane_charge_buff) == 0 and spell(arcane_orb) or { target.refreshable(nether_tempest) or not buffpresent(nether_tempest) } and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(nether_tempest) or buffexpires(arcane_power) and buffexpires(rune_of_power) and target.debuffexpires(touch_of_the_magi) and spellcooldown(arcane_power) > 0 and spellcooldown(touch_of_the_magi) > 0 and { not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) > 0 } and spell(shifting_power) or buffpresent(clearcasting) and equippedruneforge(arcane_infinity_runeforge) and hastalent(amplification_talent) and enemies() < 9 and spell(arcane_missiles) or buffpresent(clearcasting) and equippedruneforge(arcane_infinity_runeforge) and enemies() < 6 and spell(arcane_missiles) or buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) and spell(arcane_explosion) or buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and previousgcdspell(arcane_barrage) and spell(arcane_explosion) or buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage)
}

### actions.am_spam

AddFunction arcaneam_spammainactions
{
 #rune_of_power,if=buff.rune_of_power.down&cooldown.arcane_power.remains>0
 if buffexpires(rune_of_power) and spellcooldown(arcane_power) > 0 spell(rune_of_power)
 #arcane_barrage,if=buff.arcane_power.up&buff.arcane_power.remains<=action.arcane_missiles.execute_time&buff.arcane_charge.stack=buff.arcane_charge.max_stack
 if buffpresent(arcane_power) and buffremaining(arcane_power) <= executetime(arcane_missiles) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) spell(arcane_barrage)
 #arcane_orb,if=buff.arcane_charge.stack<buff.arcane_charge.max_stack&buff.rune_of_power.down&buff.arcane_power.down&debuff.touch_of_the_magi.down
 if buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) and buffexpires(rune_of_power) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) spell(arcane_orb)
 #arcane_barrage,if=buff.rune_of_power.down&buff.arcane_power.down&debuff.touch_of_the_magi.down&buff.arcane_charge.stack=buff.arcane_charge.max_stack
 if buffexpires(rune_of_power) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) spell(arcane_barrage)
 #arcane_missiles,if=buff.clearcasting.react,chain=1,early_chain_if=buff.clearcasting_channel.down&(buff.arcane_power.up|buff.rune_of_power.up|cooldown.evocation.ready)
 if buffpresent(clearcasting) spell(arcane_missiles)
 #arcane_missiles,if=!azerite.arcane_pummeling.enabled|buff.clearcasting_channel.down,chain=1,early_chain_if=buff.clearcasting_channel.down&(buff.arcane_power.up|buff.rune_of_power.up|cooldown.evocation.ready)
 if not hasazeritetrait(arcane_pummeling_trait) or buffexpires(clearcasting_channel_buff) spell(arcane_missiles)
 #cancel_action,if=action.evocation.channeling&mana.pct>=95
 if message("action.evocation.channeling is not implemented") and manapercent() >= 95 spell(cancel_action)
 #arcane_orb,if=buff.arcane_charge.stack<buff.arcane_charge.max_stack
 if buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) spell(arcane_orb)
 #arcane_barrage
 spell(arcane_barrage)
 #arcane_blast
 if mana() > manacost(arcane_blast) spell(arcane_blast)
}

AddFunction arcaneam_spammainpostconditions
{
}

AddFunction arcaneam_spamshortcdactions
{
 unless buffexpires(rune_of_power) and spellcooldown(arcane_power) > 0 and spell(rune_of_power)
 {
  #touch_of_the_magi,if=(cooldown.arcane_power.remains=0&buff.rune_of_power.down)|prev_gcd.1.rune_of_power
  if not spellcooldown(arcane_power) > 0 and buffexpires(rune_of_power) or previousgcdspell(rune_of_power) spell(touch_of_the_magi)
  #touch_of_the_magi,if=cooldown.arcane_power.remains<50&buff.rune_of_power.down&essence.vision_of_perfection.enabled
  if spellcooldown(arcane_power) < 50 and buffexpires(rune_of_power) and azeriteessenceisenabled(vision_of_perfection_essence_id) spell(touch_of_the_magi)
 }
}

AddFunction arcaneam_spamshortcdpostconditions
{
 buffexpires(rune_of_power) and spellcooldown(arcane_power) > 0 and spell(rune_of_power) or buffpresent(arcane_power) and buffremaining(arcane_power) <= executetime(arcane_missiles) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) and buffexpires(rune_of_power) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and spell(arcane_orb) or buffexpires(rune_of_power) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffpresent(clearcasting) and spell(arcane_missiles) or { not hasazeritetrait(arcane_pummeling_trait) or buffexpires(clearcasting_channel_buff) } and spell(arcane_missiles) or message("action.evocation.channeling is not implemented") and manapercent() >= 95 and spell(cancel_action) or buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) and spell(arcane_orb) or spell(arcane_barrage) or mana() > manacost(arcane_blast) and spell(arcane_blast)
}

AddFunction arcaneam_spamcdactions
{
 unless buffexpires(rune_of_power) and spellcooldown(arcane_power) > 0 and spell(rune_of_power) or { not spellcooldown(arcane_power) > 0 and buffexpires(rune_of_power) or previousgcdspell(rune_of_power) } and spell(touch_of_the_magi) or spellcooldown(arcane_power) < 50 and buffexpires(rune_of_power) and azeriteessenceisenabled(vision_of_perfection_essence_id) and spell(touch_of_the_magi)
 {
  #arcane_power,if=buff.rune_of_power.down&cooldown.touch_of_the_magi.remains>variable.ap_max_delay
  if buffexpires(rune_of_power) and spellcooldown(touch_of_the_magi) > ap_max_delay() spell(arcane_power)

  unless buffpresent(arcane_power) and buffremaining(arcane_power) <= executetime(arcane_missiles) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) and buffexpires(rune_of_power) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and spell(arcane_orb) or buffexpires(rune_of_power) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffpresent(clearcasting) and spell(arcane_missiles) or { not hasazeritetrait(arcane_pummeling_trait) or buffexpires(clearcasting_channel_buff) } and spell(arcane_missiles) or message("action.evocation.channeling is not implemented") and manapercent() >= 95 and spell(cancel_action)
  {
   #evocation
   spell(evocation)
  }
 }
}

AddFunction arcaneam_spamcdpostconditions
{
 buffexpires(rune_of_power) and spellcooldown(arcane_power) > 0 and spell(rune_of_power) or { not spellcooldown(arcane_power) > 0 and buffexpires(rune_of_power) or previousgcdspell(rune_of_power) } and spell(touch_of_the_magi) or spellcooldown(arcane_power) < 50 and buffexpires(rune_of_power) and azeriteessenceisenabled(vision_of_perfection_essence_id) and spell(touch_of_the_magi) or buffpresent(arcane_power) and buffremaining(arcane_power) <= executetime(arcane_missiles) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) and buffexpires(rune_of_power) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and spell(arcane_orb) or buffexpires(rune_of_power) and buffexpires(arcane_power) and target.debuffexpires(touch_of_the_magi) and buffstacks(arcane_charge_buff) == spelldata(arcane_charge_buff max_stacks) and spell(arcane_barrage) or buffpresent(clearcasting) and spell(arcane_missiles) or { not hasazeritetrait(arcane_pummeling_trait) or buffexpires(clearcasting_channel_buff) } and spell(arcane_missiles) or message("action.evocation.channeling is not implemented") and manapercent() >= 95 and spell(cancel_action) or buffstacks(arcane_charge_buff) < spelldata(arcane_charge_buff max_stacks) and spell(arcane_orb) or spell(arcane_barrage) or mana() > manacost(arcane_blast) and spell(arcane_blast)
}

### actions.default

AddFunction arcane_defaultmainactions
{
 #call_action_list,name=shared_cds
 arcaneshared_cdsmainactions()

 unless arcaneshared_cdsmainpostconditions()
 {
  #call_action_list,name=essences
  arcaneessencesmainactions()

  unless arcaneessencesmainpostconditions()
  {
   #call_action_list,name=aoe,if=active_enemies>2
   if enemies() > 2 arcaneaoemainactions()

   unless enemies() > 2 and arcaneaoemainpostconditions()
   {
    #call_action_list,name=opener,if=variable.have_opened<=0
    if have_opened() <= 0 arcaneopenermainactions()

    unless have_opened() <= 0 and arcaneopenermainpostconditions()
    {
     #call_action_list,name=am_spam,if=variable.am_spam=1
     if am_spam() == 1 arcaneam_spammainactions()

     unless am_spam() == 1 and arcaneam_spammainpostconditions()
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
 }
}

AddFunction arcane_defaultmainpostconditions
{
 arcaneshared_cdsmainpostconditions() or arcaneessencesmainpostconditions() or enemies() > 2 and arcaneaoemainpostconditions() or have_opened() <= 0 and arcaneopenermainpostconditions() or am_spam() == 1 and arcaneam_spammainpostconditions() or arcanecooldownsmainpostconditions() or final_burn() == 0 and arcanerotationmainpostconditions() or final_burn() == 1 and arcanefinal_burnmainpostconditions() or arcanemovementmainpostconditions()
}

AddFunction arcane_defaultshortcdactions
{
 #call_action_list,name=shared_cds
 arcaneshared_cdsshortcdactions()

 unless arcaneshared_cdsshortcdpostconditions()
 {
  #call_action_list,name=essences
  arcaneessencesshortcdactions()

  unless arcaneessencesshortcdpostconditions()
  {
   #call_action_list,name=aoe,if=active_enemies>2
   if enemies() > 2 arcaneaoeshortcdactions()

   unless enemies() > 2 and arcaneaoeshortcdpostconditions()
   {
    #call_action_list,name=opener,if=variable.have_opened<=0
    if have_opened() <= 0 arcaneopenershortcdactions()

    unless have_opened() <= 0 and arcaneopenershortcdpostconditions()
    {
     #call_action_list,name=am_spam,if=variable.am_spam=1
     if am_spam() == 1 arcaneam_spamshortcdactions()

     unless am_spam() == 1 and arcaneam_spamshortcdpostconditions()
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
 }
}

AddFunction arcane_defaultshortcdpostconditions
{
 arcaneshared_cdsshortcdpostconditions() or arcaneessencesshortcdpostconditions() or enemies() > 2 and arcaneaoeshortcdpostconditions() or have_opened() <= 0 and arcaneopenershortcdpostconditions() or am_spam() == 1 and arcaneam_spamshortcdpostconditions() or arcanecooldownsshortcdpostconditions() or final_burn() == 0 and arcanerotationshortcdpostconditions() or final_burn() == 1 and arcanefinal_burnshortcdpostconditions() or arcanemovementshortcdpostconditions()
}

AddFunction arcane_defaultcdactions
{
 #counterspell,if=target.debuff.casting.react
 if target.isinterruptible() arcaneinterruptactions()
 #call_action_list,name=shared_cds
 arcaneshared_cdscdactions()

 unless arcaneshared_cdscdpostconditions()
 {
  #call_action_list,name=essences
  arcaneessencescdactions()

  unless arcaneessencescdpostconditions()
  {
   #call_action_list,name=aoe,if=active_enemies>2
   if enemies() > 2 arcaneaoecdactions()

   unless enemies() > 2 and arcaneaoecdpostconditions()
   {
    #call_action_list,name=opener,if=variable.have_opened<=0
    if have_opened() <= 0 arcaneopenercdactions()

    unless have_opened() <= 0 and arcaneopenercdpostconditions()
    {
     #call_action_list,name=am_spam,if=variable.am_spam=1
     if am_spam() == 1 arcaneam_spamcdactions()

     unless am_spam() == 1 and arcaneam_spamcdpostconditions()
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
 }
}

AddFunction arcane_defaultcdpostconditions
{
 arcaneshared_cdscdpostconditions() or arcaneessencescdpostconditions() or enemies() > 2 and arcaneaoecdpostconditions() or have_opened() <= 0 and arcaneopenercdpostconditions() or am_spam() == 1 and arcaneam_spamcdpostconditions() or arcanecooldownscdpostconditions() or final_burn() == 0 and arcanerotationcdpostconditions() or final_burn() == 1 and arcanefinal_burncdpostconditions() or arcanemovementcdpostconditions()
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
# arcane_infinity_runeforge
# arcane_intellect
# arcane_missiles
# arcane_orb
# arcane_orb_talent
# arcane_power
# arcane_pummeling_trait
# bag_of_tricks
# berserking
# blink_any
# blood_fury
# blood_of_the_enemy
# buff_disciplinary_command
# cancel_action
# clearcasting
# clearcasting_channel_buff
# concentrated_flame
# conjure_mana_gem
# counterspell
# deathborne
# disciplinary_command_fire_buff
# disciplinary_command_frost_buff
# disciplinary_command_runeforge
# enlightened_talent
# evocation
# exhaustion
# expanded_potential_buff
# fire_blast
# fireblood
# focused_azerite_beam
# focused_resolve_item
# frost_nova
# frostbolt
# grisly_icicle_runeforge
# guardian_of_azeroth
# kyrian
# lights_judgment
# memory_of_lucid_dreams
# mirror_image
# mirrors_of_torment
# necrolord
# nether_tempest
# night_fae
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
# siphon_storm_runeforge
# strict_sequence
# supernova
# temporal_warp_runeforge
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


AddFunction phoenix_pooling
{
 not disable_combustion() and time_to_combustion() < spellfullrecharge(phoenix_flames) and time_to_combustion() < fightremains() or equippedruneforge(sun_kings_blessing_runeforge)
}

AddFunction fire_blast_pooling
{
 not disable_combustion() and time_to_combustion() < spellfullrecharge(fire_blast) - shifting_power_reduction() * { spellcooldown(shifting_power) < time_to_combustion() } and time_to_combustion() < fightremains() or equippedruneforge(sun_kings_blessing_runeforge) and charges(fire_blast count=0) < spellmaxcharges(fire_blast) - 0.5 and { spellcooldown(shifting_power) > 15 or not covenant(night_fae) }
}

AddFunction ignite_min
{
 target.tickvalue(debuff)
}

AddFunction time_to_combustion
{
 talentpoints(firestarter_talent) * message("firestarter.remains is not implemented") + spellcooldown(combustion) * { 1 - kindling_reduction() * talentpoints(kindling_talent) } * { not { spellcooldown(combustion) == 0 } * buffexpires(combustion) }
}

AddFunction extended_combustion_remains
{
 buffremaining(combustion) + baseduration(combustion) * { spellcooldown(combustion) < buffremaining(combustion) }
}

AddFunction font_of_power_precombat_channel
{
 if font_double_on_use() and not hastalent(firestarter_talent) and 0 == 0 18
}

AddFunction font_double_on_use
{
 hasequippeditem(azsharas_font_of_power_item) and combustion_on_use()
}

AddFunction combustion_on_use
{
 hasequippeditem(manifesto_of_madness_item) or hasequippeditem(gladiators_badge) or hasequippeditem(gladiators_medallion_item) or hasequippeditem(ignition_mages_fuse_item) or hasequippeditem(tzanes_barkspines_item) or hasequippeditem(azurethos_singed_plumage_item) or hasequippeditem(ancient_knot_of_wisdom_item) or hasequippeditem(shockbiters_fang_item) or hasequippeditem(neural_synapse_enhancer_item) or hasequippeditem(balefire_branch_item)
}

AddFunction shifting_power_reduction
{
 if covenant(night_fae) casttime(shifting_power) / currentticktime(shifting_power) * 3
}

AddFunction arcane_explosion
{
 if 0 == 0 99 * talentpoints(flame_patch_talent) + 2 * hastalent(flame_patch_talent no)
}

AddFunction combustion_flamestrike
{
 if 0 == 0 3 * talentpoints(flame_patch_talent) + 6 * hastalent(flame_patch_talent no)
}

AddFunction hard_cast_flamestrike
{
 if 0 == 0 2 * talentpoints(flame_patch_talent) + 3 * hastalent(flame_patch_talent no)
}

AddFunction hot_streak_flamestrike
{
 if 0 == 0 2 * talentpoints(flame_patch_talent) + 3 * hastalent(flame_patch_talent no)
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=fire)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=fire)
AddCheckBox(opt_time_warp spellname(time_warp) specialization=fire)

AddFunction fireinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(counterspell) and target.isinterruptible() spell(counterspell)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
 }
}

AddFunction fireuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

### actions.standard_rotation

AddFunction firestandard_rotationmainactions
{
 #flamestrike,if=(active_enemies>=variable.hot_streak_flamestrike&(time-buff.combustion.last_expire>variable.delay_flamestrike|variable.disable_combustion))&(buff.hot_streak.react|buff.firestorm.react)
 if enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and { buffpresent(hot_streak) or buffpresent(firestorm_buff) } spell(flamestrike)
 #pyroblast,if=buff.firestorm.react
 if buffpresent(firestorm_buff) spell(pyroblast)
 #pyroblast,if=buff.hot_streak.react&buff.hot_streak.remains<action.fireball.execute_time
 if buffpresent(hot_streak) and buffremaining(hot_streak) < executetime(fireball) spell(pyroblast)
 #pyroblast,if=buff.hot_streak.react&(prev_gcd.1.fireball|firestarter.active|action.pyroblast.in_flight)
 if buffpresent(hot_streak) and { previousgcdspell(fireball) or talent(firestarter_talent) and target.healthpercent() >= 90 or inflighttotarget(pyroblast) } spell(pyroblast)
 #pyroblast,if=buff.sun_kings_blessing_ready.up&(cooldown.rune_of_power.remains+action.rune_of_power.execute_time+cast_time>buff.sun_kings_blessing_ready.remains|!talent.rune_of_power.enabled)&variable.time_to_combustion+cast_time>buff.sun_kings_blessing_ready.remains
 if buffpresent(sun_kings_blessing_ready_buff) and { spellcooldown(rune_of_power) + executetime(rune_of_power) + casttime(pyroblast) > buffremaining(sun_kings_blessing_ready_buff) or not hastalent(rune_of_power_talent) } and time_to_combustion() + casttime(pyroblast) > buffremaining(sun_kings_blessing_ready_buff) spell(pyroblast)
 #pyroblast,if=buff.hot_streak.react&target.health.pct<=30&talent.searing_touch.enabled
 if buffpresent(hot_streak) and target.healthpercent() <= 30 and hastalent(searing_touch_talent) spell(pyroblast)
 #pyroblast,if=buff.pyroclasm.react&cast_time<buff.pyroclasm.remains&(buff.pyroclasm.react=buff.pyroclasm.max_stack|buff.pyroclasm.remains<cast_time+action.fireball.execute_time|buff.alexstraszas_fury.up|!runeforge.sun_kings_blessing.equipped)
 if buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and { buffstacks(pyroclasm) == spelldata(pyroclasm max_stacks) or buffremaining(pyroclasm) < casttime(pyroblast) + executetime(fireball) or buffpresent(alexstraszas_fury) or not equippedruneforge(sun_kings_blessing_runeforge) } spell(pyroblast)
 #fire_blast,use_off_gcd=1,use_while_casting=1,if=!firestarter.active&!variable.fire_blast_pooling&(((action.fireball.executing|action.pyroblast.executing)&buff.heating_up.react)|(talent.searing_touch.enabled&target.health.pct<=30&(buff.heating_up.react&!action.scorch.executing|!buff.hot_streak.react&!buff.heating_up.react&action.scorch.executing&!hot_streak_spells_in_flight)))
 if not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not fire_blast_pooling() and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up) and not executetime(scorch) > 0 or not buffpresent(hot_streak) and not buffpresent(heating_up) and executetime(scorch) > 0 and not message("hot_streak_spells_in_flight is not implemented") } } spell(fire_blast)
 #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.react&talent.searing_touch.enabled&target.health.pct<=30&!(active_enemies>=variable.hot_streak_flamestrike&(time-buff.combustion.last_expire>variable.delay_flamestrike|variable.disable_combustion))
 if previousgcdspell(scorch) and buffpresent(heating_up) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and not { enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } } spell(pyroblast)
 #phoenix_flames,if=!variable.phoenix_pooling&(!talent.from_the_ashes.enabled|active_enemies>1)&(active_dot.ignite<2|active_enemies>=variable.hard_cast_flamestrike|active_enemies>=variable.hot_streak_flamestrike)
 if not phoenix_pooling() and { not hastalent(from_the_ashes_talent) or enemies() > 1 } and { debuffcountonany(ignite) < 2 or enemies() >= hard_cast_flamestrike() or enemies() >= hot_streak_flamestrike() } spell(phoenix_flames)
 #call_action_list,name=active_talents
 fireactive_talentsmainactions()

 unless fireactive_talentsmainpostconditions()
 {
  #dragons_breath,if=active_enemies>1
  if enemies() > 1 and target.distance(less 12) spell(dragons_breath)
  #scorch,if=target.health.pct<=30&talent.searing_touch.enabled
  if target.healthpercent() <= 30 and hastalent(searing_touch_talent) spell(scorch)
  #arcane_explosion,if=active_enemies>=variable.arcane_explosion&mana.pct>=variable.arcane_explosion_mana
  if enemies() >= arcane_explosion() and manapercent() >= arcane_explosion_mana() spell(arcane_explosion)
  #flamestrike,if=active_enemies>=variable.hard_cast_flamestrike&(time-buff.combustion.last_expire>variable.delay_flamestrike|variable.disable_combustion)
  if enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } spell(flamestrike)
  #fireball
  spell(fireball)
  #scorch
  spell(scorch)
 }
}

AddFunction firestandard_rotationmainpostconditions
{
 fireactive_talentsmainpostconditions()
}

AddFunction firestandard_rotationshortcdactions
{
 unless enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and { buffpresent(hot_streak) or buffpresent(firestorm_buff) } and spell(flamestrike) or buffpresent(firestorm_buff) and spell(pyroblast) or buffpresent(hot_streak) and buffremaining(hot_streak) < executetime(fireball) and spell(pyroblast) or buffpresent(hot_streak) and { previousgcdspell(fireball) or talent(firestarter_talent) and target.healthpercent() >= 90 or inflighttotarget(pyroblast) } and spell(pyroblast) or buffpresent(sun_kings_blessing_ready_buff) and { spellcooldown(rune_of_power) + executetime(rune_of_power) + casttime(pyroblast) > buffremaining(sun_kings_blessing_ready_buff) or not hastalent(rune_of_power_talent) } and time_to_combustion() + casttime(pyroblast) > buffremaining(sun_kings_blessing_ready_buff) and spell(pyroblast) or buffpresent(hot_streak) and target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(pyroblast) or buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and { buffstacks(pyroclasm) == spelldata(pyroclasm max_stacks) or buffremaining(pyroclasm) < casttime(pyroblast) + executetime(fireball) or buffpresent(alexstraszas_fury) or not equippedruneforge(sun_kings_blessing_runeforge) } and spell(pyroblast) or not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not fire_blast_pooling() and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up) and not executetime(scorch) > 0 or not buffpresent(hot_streak) and not buffpresent(heating_up) and executetime(scorch) > 0 and not message("hot_streak_spells_in_flight is not implemented") } } and spell(fire_blast) or previousgcdspell(scorch) and buffpresent(heating_up) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and not { enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } } and spell(pyroblast) or not phoenix_pooling() and { not hastalent(from_the_ashes_talent) or enemies() > 1 } and { debuffcountonany(ignite) < 2 or enemies() >= hard_cast_flamestrike() or enemies() >= hot_streak_flamestrike() } and spell(phoenix_flames)
 {
  #call_action_list,name=active_talents
  fireactive_talentsshortcdactions()
 }
}

AddFunction firestandard_rotationshortcdpostconditions
{
 enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and { buffpresent(hot_streak) or buffpresent(firestorm_buff) } and spell(flamestrike) or buffpresent(firestorm_buff) and spell(pyroblast) or buffpresent(hot_streak) and buffremaining(hot_streak) < executetime(fireball) and spell(pyroblast) or buffpresent(hot_streak) and { previousgcdspell(fireball) or talent(firestarter_talent) and target.healthpercent() >= 90 or inflighttotarget(pyroblast) } and spell(pyroblast) or buffpresent(sun_kings_blessing_ready_buff) and { spellcooldown(rune_of_power) + executetime(rune_of_power) + casttime(pyroblast) > buffremaining(sun_kings_blessing_ready_buff) or not hastalent(rune_of_power_talent) } and time_to_combustion() + casttime(pyroblast) > buffremaining(sun_kings_blessing_ready_buff) and spell(pyroblast) or buffpresent(hot_streak) and target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(pyroblast) or buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and { buffstacks(pyroclasm) == spelldata(pyroclasm max_stacks) or buffremaining(pyroclasm) < casttime(pyroblast) + executetime(fireball) or buffpresent(alexstraszas_fury) or not equippedruneforge(sun_kings_blessing_runeforge) } and spell(pyroblast) or not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not fire_blast_pooling() and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up) and not executetime(scorch) > 0 or not buffpresent(hot_streak) and not buffpresent(heating_up) and executetime(scorch) > 0 and not message("hot_streak_spells_in_flight is not implemented") } } and spell(fire_blast) or previousgcdspell(scorch) and buffpresent(heating_up) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and not { enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } } and spell(pyroblast) or not phoenix_pooling() and { not hastalent(from_the_ashes_talent) or enemies() > 1 } and { debuffcountonany(ignite) < 2 or enemies() >= hard_cast_flamestrike() or enemies() >= hot_streak_flamestrike() } and spell(phoenix_flames) or fireactive_talentsshortcdpostconditions() or enemies() > 1 and target.distance(less 12) and spell(dragons_breath) or target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(scorch) or enemies() >= arcane_explosion() and manapercent() >= arcane_explosion_mana() and spell(arcane_explosion) or enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and spell(flamestrike) or spell(fireball) or spell(scorch)
}

AddFunction firestandard_rotationcdactions
{
 unless enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and { buffpresent(hot_streak) or buffpresent(firestorm_buff) } and spell(flamestrike) or buffpresent(firestorm_buff) and spell(pyroblast) or buffpresent(hot_streak) and buffremaining(hot_streak) < executetime(fireball) and spell(pyroblast) or buffpresent(hot_streak) and { previousgcdspell(fireball) or talent(firestarter_talent) and target.healthpercent() >= 90 or inflighttotarget(pyroblast) } and spell(pyroblast) or buffpresent(sun_kings_blessing_ready_buff) and { spellcooldown(rune_of_power) + executetime(rune_of_power) + casttime(pyroblast) > buffremaining(sun_kings_blessing_ready_buff) or not hastalent(rune_of_power_talent) } and time_to_combustion() + casttime(pyroblast) > buffremaining(sun_kings_blessing_ready_buff) and spell(pyroblast) or buffpresent(hot_streak) and target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(pyroblast) or buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and { buffstacks(pyroclasm) == spelldata(pyroclasm max_stacks) or buffremaining(pyroclasm) < casttime(pyroblast) + executetime(fireball) or buffpresent(alexstraszas_fury) or not equippedruneforge(sun_kings_blessing_runeforge) } and spell(pyroblast) or not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not fire_blast_pooling() and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up) and not executetime(scorch) > 0 or not buffpresent(hot_streak) and not buffpresent(heating_up) and executetime(scorch) > 0 and not message("hot_streak_spells_in_flight is not implemented") } } and spell(fire_blast) or previousgcdspell(scorch) and buffpresent(heating_up) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and not { enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } } and spell(pyroblast) or not phoenix_pooling() and { not hastalent(from_the_ashes_talent) or enemies() > 1 } and { debuffcountonany(ignite) < 2 or enemies() >= hard_cast_flamestrike() or enemies() >= hot_streak_flamestrike() } and spell(phoenix_flames)
 {
  #call_action_list,name=active_talents
  fireactive_talentscdactions()
 }
}

AddFunction firestandard_rotationcdpostconditions
{
 enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and { buffpresent(hot_streak) or buffpresent(firestorm_buff) } and spell(flamestrike) or buffpresent(firestorm_buff) and spell(pyroblast) or buffpresent(hot_streak) and buffremaining(hot_streak) < executetime(fireball) and spell(pyroblast) or buffpresent(hot_streak) and { previousgcdspell(fireball) or talent(firestarter_talent) and target.healthpercent() >= 90 or inflighttotarget(pyroblast) } and spell(pyroblast) or buffpresent(sun_kings_blessing_ready_buff) and { spellcooldown(rune_of_power) + executetime(rune_of_power) + casttime(pyroblast) > buffremaining(sun_kings_blessing_ready_buff) or not hastalent(rune_of_power_talent) } and time_to_combustion() + casttime(pyroblast) > buffremaining(sun_kings_blessing_ready_buff) and spell(pyroblast) or buffpresent(hot_streak) and target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(pyroblast) or buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and { buffstacks(pyroclasm) == spelldata(pyroclasm max_stacks) or buffremaining(pyroclasm) < casttime(pyroblast) + executetime(fireball) or buffpresent(alexstraszas_fury) or not equippedruneforge(sun_kings_blessing_runeforge) } and spell(pyroblast) or not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not fire_blast_pooling() and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up) and not executetime(scorch) > 0 or not buffpresent(hot_streak) and not buffpresent(heating_up) and executetime(scorch) > 0 and not message("hot_streak_spells_in_flight is not implemented") } } and spell(fire_blast) or previousgcdspell(scorch) and buffpresent(heating_up) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and not { enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } } and spell(pyroblast) or not phoenix_pooling() and { not hastalent(from_the_ashes_talent) or enemies() > 1 } and { debuffcountonany(ignite) < 2 or enemies() >= hard_cast_flamestrike() or enemies() >= hot_streak_flamestrike() } and spell(phoenix_flames) or fireactive_talentscdpostconditions() or enemies() > 1 and target.distance(less 12) and spell(dragons_breath) or target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(scorch) or enemies() >= arcane_explosion() and manapercent() >= arcane_explosion_mana() and spell(arcane_explosion) or enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and spell(flamestrike) or spell(fireball) or spell(scorch)
}

### actions.rop_phase

AddFunction firerop_phasemainactions
{
 #flamestrike,if=(active_enemies>=variable.hot_streak_flamestrike&(time-buff.combustion.last_expire>variable.delay_flamestrike|variable.disable_combustion))&(buff.hot_streak.react|buff.firestorm.react)
 if enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and { buffpresent(hot_streak) or buffpresent(firestorm_buff) } spell(flamestrike)
 #pyroblast,if=buff.sun_kings_blessing_ready.up&buff.sun_kings_blessing_ready.remains>cast_time
 if buffpresent(sun_kings_blessing_ready_buff) and buffremaining(sun_kings_blessing_ready_buff) > casttime(pyroblast) spell(pyroblast)
 #pyroblast,if=buff.firestorm.react
 if buffpresent(firestorm_buff) spell(pyroblast)
 #pyroblast,if=buff.hot_streak.react
 if buffpresent(hot_streak) spell(pyroblast)
 #fire_blast,use_off_gcd=1,use_while_casting=1,if=buff.sun_kings_blessing_ready.down&!(active_enemies>=variable.hard_cast_flamestrike&(time-buff.combustion.last_expire>variable.delay_flamestrike|variable.disable_combustion))&!firestarter.active&(!buff.heating_up.react&!buff.hot_streak.react&!prev_off_gcd.fire_blast&(action.fire_blast.charges>=2|(talent.alexstraszas_fury.enabled&cooldown.dragons_breath.ready)|(talent.searing_touch.enabled&target.health.pct<=30)))
 if buffexpires(sun_kings_blessing_ready_buff) and not { enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not buffpresent(heating_up) and not buffpresent(hot_streak) and not previousoffgcdspell(fire_blast) and { charges(fire_blast) >= 2 or hastalent(alexstraszas_fury_talent) and spellcooldown(dragons_breath) == 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } spell(fire_blast)
 #fire_blast,use_off_gcd=1,use_while_casting=1,if=!firestarter.active&(((action.fireball.executing|action.pyroblast.executing)&buff.heating_up.react)|(talent.searing_touch.enabled&target.health.pct<=30&(buff.heating_up.react&!action.scorch.executing|!buff.hot_streak.react&!buff.heating_up.react&action.scorch.executing&!hot_streak_spells_in_flight)))
 if not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up) and not executetime(scorch) > 0 or not buffpresent(hot_streak) and not buffpresent(heating_up) and executetime(scorch) > 0 and not message("hot_streak_spells_in_flight is not implemented") } } spell(fire_blast)
 #call_action_list,name=active_talents
 fireactive_talentsmainactions()

 unless fireactive_talentsmainpostconditions()
 {
  #pyroblast,if=buff.pyroclasm.react&cast_time<buff.pyroclasm.remains&cast_time<buff.rune_of_power.remains&(buff.pyroclasm.react=buff.pyroclasm.max_stack|buff.pyroclasm.remains<cast_time+action.fireball.execute_time|buff.alexstraszas_fury.up|!runeforge.sun_kings_blessing.equipped)
  if buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and casttime(pyroblast) < totemremaining(rune_of_power) and { buffstacks(pyroclasm) == spelldata(pyroclasm max_stacks) or buffremaining(pyroclasm) < casttime(pyroblast) + executetime(fireball) or buffpresent(alexstraszas_fury) or not equippedruneforge(sun_kings_blessing_runeforge) } spell(pyroblast)
  #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.react&talent.searing_touch.enabled&target.health.pct<=30&!(active_enemies>=variable.hot_streak_flamestrike&(time-buff.combustion.last_expire>variable.delay_flamestrike|variable.disable_combustion))
  if previousgcdspell(scorch) and buffpresent(heating_up) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and not { enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } } spell(pyroblast)
  #phoenix_flames,if=!variable.phoenix_pooling&buff.heating_up.react&!buff.hot_streak.react&(active_dot.ignite<2|active_enemies>=variable.hard_cast_flamestrike|active_enemies>=variable.hot_streak_flamestrike)
  if not phoenix_pooling() and buffpresent(heating_up) and not buffpresent(hot_streak) and { debuffcountonany(ignite) < 2 or enemies() >= hard_cast_flamestrike() or enemies() >= hot_streak_flamestrike() } spell(phoenix_flames)
  #scorch,if=target.health.pct<=30&talent.searing_touch.enabled
  if target.healthpercent() <= 30 and hastalent(searing_touch_talent) spell(scorch)
  #dragons_breath,if=active_enemies>2
  if enemies() > 2 and target.distance(less 12) spell(dragons_breath)
  #arcane_explosion,if=active_enemies>=variable.arcane_explosion&mana.pct>=variable.arcane_explosion_mana
  if enemies() >= arcane_explosion() and manapercent() >= arcane_explosion_mana() spell(arcane_explosion)
  #flamestrike,if=(active_enemies>=variable.hard_cast_flamestrike&(time-buff.combustion.last_expire>variable.delay_flamestrike|variable.disable_combustion))
  if enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } spell(flamestrike)
  #fireball
  spell(fireball)
 }
}

AddFunction firerop_phasemainpostconditions
{
 fireactive_talentsmainpostconditions()
}

AddFunction firerop_phaseshortcdactions
{
 unless enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and { buffpresent(hot_streak) or buffpresent(firestorm_buff) } and spell(flamestrike) or buffpresent(sun_kings_blessing_ready_buff) and buffremaining(sun_kings_blessing_ready_buff) > casttime(pyroblast) and spell(pyroblast) or buffpresent(firestorm_buff) and spell(pyroblast) or buffpresent(hot_streak) and spell(pyroblast) or buffexpires(sun_kings_blessing_ready_buff) and not { enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not buffpresent(heating_up) and not buffpresent(hot_streak) and not previousoffgcdspell(fire_blast) and { charges(fire_blast) >= 2 or hastalent(alexstraszas_fury_talent) and spellcooldown(dragons_breath) == 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } and spell(fire_blast) or not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up) and not executetime(scorch) > 0 or not buffpresent(hot_streak) and not buffpresent(heating_up) and executetime(scorch) > 0 and not message("hot_streak_spells_in_flight is not implemented") } } and spell(fire_blast)
 {
  #call_action_list,name=active_talents
  fireactive_talentsshortcdactions()
 }
}

AddFunction firerop_phaseshortcdpostconditions
{
 enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and { buffpresent(hot_streak) or buffpresent(firestorm_buff) } and spell(flamestrike) or buffpresent(sun_kings_blessing_ready_buff) and buffremaining(sun_kings_blessing_ready_buff) > casttime(pyroblast) and spell(pyroblast) or buffpresent(firestorm_buff) and spell(pyroblast) or buffpresent(hot_streak) and spell(pyroblast) or buffexpires(sun_kings_blessing_ready_buff) and not { enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not buffpresent(heating_up) and not buffpresent(hot_streak) and not previousoffgcdspell(fire_blast) and { charges(fire_blast) >= 2 or hastalent(alexstraszas_fury_talent) and spellcooldown(dragons_breath) == 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } and spell(fire_blast) or not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up) and not executetime(scorch) > 0 or not buffpresent(hot_streak) and not buffpresent(heating_up) and executetime(scorch) > 0 and not message("hot_streak_spells_in_flight is not implemented") } } and spell(fire_blast) or fireactive_talentsshortcdpostconditions() or buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and casttime(pyroblast) < totemremaining(rune_of_power) and { buffstacks(pyroclasm) == spelldata(pyroclasm max_stacks) or buffremaining(pyroclasm) < casttime(pyroblast) + executetime(fireball) or buffpresent(alexstraszas_fury) or not equippedruneforge(sun_kings_blessing_runeforge) } and spell(pyroblast) or previousgcdspell(scorch) and buffpresent(heating_up) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and not { enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } } and spell(pyroblast) or not phoenix_pooling() and buffpresent(heating_up) and not buffpresent(hot_streak) and { debuffcountonany(ignite) < 2 or enemies() >= hard_cast_flamestrike() or enemies() >= hot_streak_flamestrike() } and spell(phoenix_flames) or target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(scorch) or enemies() > 2 and target.distance(less 12) and spell(dragons_breath) or enemies() >= arcane_explosion() and manapercent() >= arcane_explosion_mana() and spell(arcane_explosion) or enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and spell(flamestrike) or spell(fireball)
}

AddFunction firerop_phasecdactions
{
 unless enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and { buffpresent(hot_streak) or buffpresent(firestorm_buff) } and spell(flamestrike) or buffpresent(sun_kings_blessing_ready_buff) and buffremaining(sun_kings_blessing_ready_buff) > casttime(pyroblast) and spell(pyroblast) or buffpresent(firestorm_buff) and spell(pyroblast) or buffpresent(hot_streak) and spell(pyroblast) or buffexpires(sun_kings_blessing_ready_buff) and not { enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not buffpresent(heating_up) and not buffpresent(hot_streak) and not previousoffgcdspell(fire_blast) and { charges(fire_blast) >= 2 or hastalent(alexstraszas_fury_talent) and spellcooldown(dragons_breath) == 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } and spell(fire_blast) or not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up) and not executetime(scorch) > 0 or not buffpresent(hot_streak) and not buffpresent(heating_up) and executetime(scorch) > 0 and not message("hot_streak_spells_in_flight is not implemented") } } and spell(fire_blast)
 {
  #call_action_list,name=active_talents
  fireactive_talentscdactions()
 }
}

AddFunction firerop_phasecdpostconditions
{
 enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and { buffpresent(hot_streak) or buffpresent(firestorm_buff) } and spell(flamestrike) or buffpresent(sun_kings_blessing_ready_buff) and buffremaining(sun_kings_blessing_ready_buff) > casttime(pyroblast) and spell(pyroblast) or buffpresent(firestorm_buff) and spell(pyroblast) or buffpresent(hot_streak) and spell(pyroblast) or buffexpires(sun_kings_blessing_ready_buff) and not { enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not buffpresent(heating_up) and not buffpresent(hot_streak) and not previousoffgcdspell(fire_blast) and { charges(fire_blast) >= 2 or hastalent(alexstraszas_fury_talent) and spellcooldown(dragons_breath) == 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } and spell(fire_blast) or not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up) and not executetime(scorch) > 0 or not buffpresent(hot_streak) and not buffpresent(heating_up) and executetime(scorch) > 0 and not message("hot_streak_spells_in_flight is not implemented") } } and spell(fire_blast) or fireactive_talentscdpostconditions() or buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and casttime(pyroblast) < totemremaining(rune_of_power) and { buffstacks(pyroclasm) == spelldata(pyroclasm max_stacks) or buffremaining(pyroclasm) < casttime(pyroblast) + executetime(fireball) or buffpresent(alexstraszas_fury) or not equippedruneforge(sun_kings_blessing_runeforge) } and spell(pyroblast) or previousgcdspell(scorch) and buffpresent(heating_up) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and not { enemies() >= hot_streak_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } } and spell(pyroblast) or not phoenix_pooling() and buffpresent(heating_up) and not buffpresent(hot_streak) and { debuffcountonany(ignite) < 2 or enemies() >= hard_cast_flamestrike() or enemies() >= hot_streak_flamestrike() } and spell(phoenix_flames) or target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(scorch) or enemies() > 2 and target.distance(less 12) and spell(dragons_breath) or enemies() >= arcane_explosion() and manapercent() >= arcane_explosion_mana() and spell(arcane_explosion) or enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and spell(flamestrike) or spell(fireball)
}

### actions.precombat

AddFunction fireprecombatmainactions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 spell(arcane_intellect)
 #pyroblast
 spell(pyroblast)
}

AddFunction fireprecombatmainpostconditions
{
}

AddFunction fireprecombatshortcdactions
{
}

AddFunction fireprecombatshortcdpostconditions
{
 spell(arcane_intellect) or spell(pyroblast)
}

AddFunction fireprecombatcdactions
{
 unless spell(arcane_intellect)
 {
  #variable,name=disable_combustion,op=reset
  #variable,name=hot_streak_flamestrike,op=set,if=variable.hot_streak_flamestrike=0,value=2*talent.flame_patch.enabled+3*!talent.flame_patch.enabled
  #variable,name=hard_cast_flamestrike,op=set,if=variable.hard_cast_flamestrike=0,value=2*talent.flame_patch.enabled+3*!talent.flame_patch.enabled
  #variable,name=combustion_flamestrike,op=set,if=variable.combustion_flamestrike=0,value=3*talent.flame_patch.enabled+6*!talent.flame_patch.enabled
  #variable,name=arcane_explosion,op=set,if=variable.arcane_explosion=0,value=99*talent.flame_patch.enabled+2*!talent.flame_patch.enabled
  #variable,name=arcane_explosion_mana,default=40,op=reset
  #variable,name=delay_flamestrike,default=0,op=reset
  #variable,name=kindling_reduction,default=0.2,op=reset
  #variable,name=shifting_power_reduction,op=set,value=action.shifting_power.cast_time%action.shifting_power.tick_time*3,if=covenant.night_fae.enabled
  #variable,name=combustion_on_use,op=set,value=equipped.manifesto_of_madness|equipped.gladiators_badge|equipped.gladiators_medallion|equipped.ignition_mages_fuse|equipped.tzanes_barkspines|equipped.azurethos_singed_plumage|equipped.ancient_knot_of_wisdom|equipped.shockbiters_fang|equipped.neural_synapse_enhancer|equipped.balefire_branch
  #variable,name=font_double_on_use,op=set,value=equipped.azsharas_font_of_power&variable.combustion_on_use
  #variable,name=font_of_power_precombat_channel,op=set,value=18,if=variable.font_double_on_use&!talent.firestarter.enabled&variable.font_of_power_precombat_channel=0
  #snapshot_stats
  #use_item,name=azsharas_font_of_power,if=!variable.disable_combustion
  if not disable_combustion() fireuseitemactions()
  #mirror_image
  spell(mirror_image)
 }
}

AddFunction fireprecombatcdpostconditions
{
 spell(arcane_intellect) or spell(pyroblast)
}

### actions.combustion_phase

AddFunction firecombustion_phasemainactions
{
 #living_bomb,if=active_enemies>1&buff.combustion.down
 if enemies() > 1 and buffexpires(combustion) spell(living_bomb)
 #blood_of_the_enemy
 spell(blood_of_the_enemy)
 #memory_of_lucid_dreams
 spell(memory_of_lucid_dreams)
 #worldvein_resonance
 spell(worldvein_resonance)
 #fire_blast,use_off_gcd=1,use_while_casting=1,if=azerite.blaster_master.enabled&charges>=1&((action.fire_blast.charges_fractional+(buff.combustion.remains-buff.blaster_master.duration)%cooldown.fire_blast.duration-(buff.combustion.remains)%(buff.blaster_master.duration-0.5))>=0|!azerite.blaster_master.enabled|!talent.flame_on.enabled|buff.combustion.remains<=buff.blaster_master.duration|buff.blaster_master.remains<0.5|equipped.hyperthread_wristwraps&cooldown.hyperthread_wristwraps_300142.remains<5)&buff.combustion.up&(!action.scorch.executing&!action.pyroblast.in_flight&buff.heating_up.up|action.scorch.executing&buff.hot_streak.down&(buff.heating_up.down|azerite.blaster_master.enabled)|azerite.blaster_master.enabled&talent.flame_on.enabled&action.pyroblast.in_flight&buff.heating_up.down&buff.hot_streak.down)
 if hasazeritetrait(blaster_master_trait) and charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { buffremaining(combustion) - baseduration(blaster_master_buff) } / spellcooldownduration(fire_blast) - buffremaining(combustion) / { baseduration(blaster_master_buff) - 0.5 } >= 0 or not hasazeritetrait(blaster_master_trait) or not hastalent(flame_on_talent) or buffremaining(combustion) <= baseduration(blaster_master_buff) or buffremaining(blaster_master_buff) < 0.5 or hasequippeditem(hyperthread_wristwraps_item) and spellcooldown(hyperthread_wristwraps_300142) < 5 } and buffpresent(combustion) and { not executetime(scorch) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up) or executetime(scorch) > 0 and buffexpires(hot_streak) and { buffexpires(heating_up) or hasazeritetrait(blaster_master_trait) } or hasazeritetrait(blaster_master_trait) and hastalent(flame_on_talent) and inflighttotarget(pyroblast) and buffexpires(heating_up) and buffexpires(hot_streak) } spell(fire_blast)
 #fire_blast,use_off_gcd=1,use_while_casting=1,if=!azerite.blaster_master.enabled&(active_enemies<=active_dot.ignite|!cooldown.phoenix_flames.ready)&conduit.infernal_cascade.enabled&charges>=1&((action.fire_blast.charges_fractional+(variable.extended_combustion_remains-buff.infernal_cascade.duration)%cooldown.fire_blast.duration-variable.extended_combustion_remains%(buff.infernal_cascade.duration-0.5))>=0|variable.extended_combustion_remains<=buff.infernal_cascade.duration|buff.infernal_cascade.remains<0.5)&buff.combustion.up&!buff.firestorm.react&!buff.hot_streak.react&hot_streak_spells_in_flight+buff.heating_up.react<2
 if not hasazeritetrait(blaster_master_trait) and { enemies() <= debuffcountonany(ignite) or not spellcooldown(phoenix_flames) == 0 } and message("conduit.infernal_cascade.enabled is not implemented") and charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { extended_combustion_remains() - baseduration(infernal_cascade) } / spellcooldownduration(fire_blast) - extended_combustion_remains() / { baseduration(infernal_cascade) - 0.5 } >= 0 or extended_combustion_remains() <= baseduration(infernal_cascade) or buffremaining(infernal_cascade) < 0.5 } and buffpresent(combustion) and not buffpresent(firestorm_buff) and not buffpresent(hot_streak) and message("hot_streak_spells_in_flight is not implemented") + buffstacks(heating_up) < 2 spell(fire_blast)
 #fire_blast,use_off_gcd=1,use_while_casting=1,if=!azerite.blaster_master.enabled&(active_enemies<=active_dot.ignite|!cooldown.phoenix_flames.ready)&!conduit.infernal_cascade.enabled&charges>=1&buff.combustion.up&!buff.firestorm.react&!buff.hot_streak.react&hot_streak_spells_in_flight+buff.heating_up.react<2
 if not hasazeritetrait(blaster_master_trait) and { enemies() <= debuffcountonany(ignite) or not spellcooldown(phoenix_flames) == 0 } and not message("conduit.infernal_cascade.enabled is not implemented") and charges(fire_blast) >= 1 and buffpresent(combustion) and not buffpresent(firestorm_buff) and not buffpresent(hot_streak) and message("hot_streak_spells_in_flight is not implemented") + buffstacks(heating_up) < 2 spell(fire_blast)
 #arcane_explosion,if=runeforge.disciplinary_command.equipped&buff.disciplinary_command.down&buff.disciplinary_command_arcane.down&cooldown.buff_disciplinary_command.ready
 if equippedruneforge(disciplinary_command_runeforge_fire) and buffexpires(disciplinary_command) and buffexpires(disciplinary_command_arcane_buff) and spellcooldown(buff_disciplinary_command) == 0 spell(arcane_explosion)
 #frostbolt,if=runeforge.disciplinary_command.equipped&buff.disciplinary_command.down&buff.disciplinary_command_frost.down
 if equippedruneforge(disciplinary_command_runeforge_fire) and buffexpires(disciplinary_command) and buffexpires(disciplinary_command_frost_buff) spell(frostbolt)
 #call_action_list,name=active_talents
 fireactive_talentsmainactions()

 unless fireactive_talentsmainpostconditions()
 {
  #berserking,if=buff.combustion.last_expire<=action.combustion.last_used
  if message("buff.combustion.last_expire is not implemented") <= message("action.combustion.last_used is not implemented") spell(berserking)
  #flamestrike,if=(buff.hot_streak.react|buff.firestorm.react)&active_enemies>=variable.combustion_flamestrike
  if { buffpresent(hot_streak) or buffpresent(firestorm_buff) } and enemies() >= combustion_flamestrike() spell(flamestrike)
  #pyroblast,if=buff.sun_kings_blessing_ready.up&buff.sun_kings_blessing_ready.remains>cast_time
  if buffpresent(sun_kings_blessing_ready_buff) and buffremaining(sun_kings_blessing_ready_buff) > casttime(pyroblast) spell(pyroblast)
  #pyroblast,if=buff.firestorm.react
  if buffpresent(firestorm_buff) spell(pyroblast)
  #pyroblast,if=buff.pyroclasm.react&buff.pyroclasm.remains>cast_time&(buff.combustion.remains>cast_time|buff.combustion.down)&active_enemies<variable.combustion_flamestrike
  if buffpresent(pyroclasm) and buffremaining(pyroclasm) > casttime(pyroblast) and { buffremaining(combustion) > casttime(pyroblast) or buffexpires(combustion) } and enemies() < combustion_flamestrike() spell(pyroblast)
  #pyroblast,if=buff.hot_streak.react&buff.combustion.up
  if buffpresent(hot_streak) and buffpresent(combustion) spell(pyroblast)
  #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.react&active_enemies<variable.combustion_flamestrike
  if previousgcdspell(scorch) and buffpresent(heating_up) and enemies() < combustion_flamestrike() spell(pyroblast)
  #phoenix_flames,if=buff.combustion.up&((action.fire_blast.charges<1&talent.pyroclasm.enabled&active_enemies=1)|!talent.pyroclasm.enabled|active_enemies>1)
  if buffpresent(combustion) and { charges(fire_blast) < 1 and hastalent(pyroclasm_talent) and enemies() == 1 or not hastalent(pyroclasm_talent) or enemies() > 1 } spell(phoenix_flames)
  #fireball,if=buff.combustion.down&cooldown.combustion.remains<cast_time&!conduit.flame_accretion.enabled
  if buffexpires(combustion) and spellcooldown(combustion) < casttime(fireball) and not message("conduit.flame_accretion.enabled is not implemented") spell(fireball)
  #scorch,if=buff.combustion.remains>cast_time&buff.combustion.up|buff.combustion.down&cooldown.combustion.remains<cast_time
  if buffremaining(combustion) > casttime(scorch) and buffpresent(combustion) or buffexpires(combustion) and spellcooldown(combustion) < casttime(scorch) spell(scorch)
  #living_bomb,if=buff.combustion.remains<gcd.max&active_enemies>1
  if buffremaining(combustion) < gcd() and enemies() > 1 spell(living_bomb)
  #dragons_breath,if=buff.combustion.remains<gcd.max&buff.combustion.up
  if buffremaining(combustion) < gcd() and buffpresent(combustion) and target.distance(less 12) spell(dragons_breath)
  #scorch,if=target.health.pct<=30&talent.searing_touch.enabled
  if target.healthpercent() <= 30 and hastalent(searing_touch_talent) spell(scorch)
 }
}

AddFunction firecombustion_phasemainpostconditions
{
 fireactive_talentsmainpostconditions()
}

AddFunction firecombustion_phaseshortcdactions
{
 #variable,name=extended_combustion_remains,op=set,value=buff.combustion.remains+buff.combustion.duration*(cooldown.combustion.remains<buff.combustion.remains)
 #variable,name=extended_combustion_remains,op=add,value=dbc.effect.828420.base_value,if=buff.sun_kings_blessing_ready.up|variable.extended_combustion_remains>1.5*gcd.max*(buff.sun_kings_blessing.max_stack-buff.sun_kings_blessing.stack)
 #bag_of_tricks,if=buff.combustion.down
 if buffexpires(combustion) spell(bag_of_tricks)

 unless enemies() > 1 and buffexpires(combustion) and spell(living_bomb)
 {
  #mirrors_of_torment,if=buff.combustion.down&buff.rune_of_power.down
  if buffexpires(combustion) and buffexpires(rune_of_power) spell(mirrors_of_torment)

  unless spell(blood_of_the_enemy) or spell(memory_of_lucid_dreams) or spell(worldvein_resonance) or hasazeritetrait(blaster_master_trait) and charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { buffremaining(combustion) - baseduration(blaster_master_buff) } / spellcooldownduration(fire_blast) - buffremaining(combustion) / { baseduration(blaster_master_buff) - 0.5 } >= 0 or not hasazeritetrait(blaster_master_trait) or not hastalent(flame_on_talent) or buffremaining(combustion) <= baseduration(blaster_master_buff) or buffremaining(blaster_master_buff) < 0.5 or hasequippeditem(hyperthread_wristwraps_item) and spellcooldown(hyperthread_wristwraps_300142) < 5 } and buffpresent(combustion) and { not executetime(scorch) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up) or executetime(scorch) > 0 and buffexpires(hot_streak) and { buffexpires(heating_up) or hasazeritetrait(blaster_master_trait) } or hasazeritetrait(blaster_master_trait) and hastalent(flame_on_talent) and inflighttotarget(pyroblast) and buffexpires(heating_up) and buffexpires(hot_streak) } and spell(fire_blast) or not hasazeritetrait(blaster_master_trait) and { enemies() <= debuffcountonany(ignite) or not spellcooldown(phoenix_flames) == 0 } and message("conduit.infernal_cascade.enabled is not implemented") and charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { extended_combustion_remains() - baseduration(infernal_cascade) } / spellcooldownduration(fire_blast) - extended_combustion_remains() / { baseduration(infernal_cascade) - 0.5 } >= 0 or extended_combustion_remains() <= baseduration(infernal_cascade) or buffremaining(infernal_cascade) < 0.5 } and buffpresent(combustion) and not buffpresent(firestorm_buff) and not buffpresent(hot_streak) and message("hot_streak_spells_in_flight is not implemented") + buffstacks(heating_up) < 2 and spell(fire_blast) or not hasazeritetrait(blaster_master_trait) and { enemies() <= debuffcountonany(ignite) or not spellcooldown(phoenix_flames) == 0 } and not message("conduit.infernal_cascade.enabled is not implemented") and charges(fire_blast) >= 1 and buffpresent(combustion) and not buffpresent(firestorm_buff) and not buffpresent(hot_streak) and message("hot_streak_spells_in_flight is not implemented") + buffstacks(heating_up) < 2 and spell(fire_blast) or equippedruneforge(disciplinary_command_runeforge_fire) and buffexpires(disciplinary_command) and buffexpires(disciplinary_command_arcane_buff) and spellcooldown(buff_disciplinary_command) == 0 and spell(arcane_explosion) or equippedruneforge(disciplinary_command_runeforge_fire) and buffexpires(disciplinary_command) and buffexpires(disciplinary_command_frost_buff) and spell(frostbolt)
  {
   #call_action_list,name=active_talents
   fireactive_talentsshortcdactions()
  }
 }
}

AddFunction firecombustion_phaseshortcdpostconditions
{
 enemies() > 1 and buffexpires(combustion) and spell(living_bomb) or spell(blood_of_the_enemy) or spell(memory_of_lucid_dreams) or spell(worldvein_resonance) or hasazeritetrait(blaster_master_trait) and charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { buffremaining(combustion) - baseduration(blaster_master_buff) } / spellcooldownduration(fire_blast) - buffremaining(combustion) / { baseduration(blaster_master_buff) - 0.5 } >= 0 or not hasazeritetrait(blaster_master_trait) or not hastalent(flame_on_talent) or buffremaining(combustion) <= baseduration(blaster_master_buff) or buffremaining(blaster_master_buff) < 0.5 or hasequippeditem(hyperthread_wristwraps_item) and spellcooldown(hyperthread_wristwraps_300142) < 5 } and buffpresent(combustion) and { not executetime(scorch) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up) or executetime(scorch) > 0 and buffexpires(hot_streak) and { buffexpires(heating_up) or hasazeritetrait(blaster_master_trait) } or hasazeritetrait(blaster_master_trait) and hastalent(flame_on_talent) and inflighttotarget(pyroblast) and buffexpires(heating_up) and buffexpires(hot_streak) } and spell(fire_blast) or not hasazeritetrait(blaster_master_trait) and { enemies() <= debuffcountonany(ignite) or not spellcooldown(phoenix_flames) == 0 } and message("conduit.infernal_cascade.enabled is not implemented") and charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { extended_combustion_remains() - baseduration(infernal_cascade) } / spellcooldownduration(fire_blast) - extended_combustion_remains() / { baseduration(infernal_cascade) - 0.5 } >= 0 or extended_combustion_remains() <= baseduration(infernal_cascade) or buffremaining(infernal_cascade) < 0.5 } and buffpresent(combustion) and not buffpresent(firestorm_buff) and not buffpresent(hot_streak) and message("hot_streak_spells_in_flight is not implemented") + buffstacks(heating_up) < 2 and spell(fire_blast) or not hasazeritetrait(blaster_master_trait) and { enemies() <= debuffcountonany(ignite) or not spellcooldown(phoenix_flames) == 0 } and not message("conduit.infernal_cascade.enabled is not implemented") and charges(fire_blast) >= 1 and buffpresent(combustion) and not buffpresent(firestorm_buff) and not buffpresent(hot_streak) and message("hot_streak_spells_in_flight is not implemented") + buffstacks(heating_up) < 2 and spell(fire_blast) or equippedruneforge(disciplinary_command_runeforge_fire) and buffexpires(disciplinary_command) and buffexpires(disciplinary_command_arcane_buff) and spellcooldown(buff_disciplinary_command) == 0 and spell(arcane_explosion) or equippedruneforge(disciplinary_command_runeforge_fire) and buffexpires(disciplinary_command) and buffexpires(disciplinary_command_frost_buff) and spell(frostbolt) or fireactive_talentsshortcdpostconditions() or message("buff.combustion.last_expire is not implemented") <= message("action.combustion.last_used is not implemented") and spell(berserking) or { buffpresent(hot_streak) or buffpresent(firestorm_buff) } and enemies() >= combustion_flamestrike() and spell(flamestrike) or buffpresent(sun_kings_blessing_ready_buff) and buffremaining(sun_kings_blessing_ready_buff) > casttime(pyroblast) and spell(pyroblast) or buffpresent(firestorm_buff) and spell(pyroblast) or buffpresent(pyroclasm) and buffremaining(pyroclasm) > casttime(pyroblast) and { buffremaining(combustion) > casttime(pyroblast) or buffexpires(combustion) } and enemies() < combustion_flamestrike() and spell(pyroblast) or buffpresent(hot_streak) and buffpresent(combustion) and spell(pyroblast) or previousgcdspell(scorch) and buffpresent(heating_up) and enemies() < combustion_flamestrike() and spell(pyroblast) or buffpresent(combustion) and { charges(fire_blast) < 1 and hastalent(pyroclasm_talent) and enemies() == 1 or not hastalent(pyroclasm_talent) or enemies() > 1 } and spell(phoenix_flames) or buffexpires(combustion) and spellcooldown(combustion) < casttime(fireball) and not message("conduit.flame_accretion.enabled is not implemented") and spell(fireball) or { buffremaining(combustion) > casttime(scorch) and buffpresent(combustion) or buffexpires(combustion) and spellcooldown(combustion) < casttime(scorch) } and spell(scorch) or buffremaining(combustion) < gcd() and enemies() > 1 and spell(living_bomb) or buffremaining(combustion) < gcd() and buffpresent(combustion) and target.distance(less 12) and spell(dragons_breath) or target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(scorch)
}

AddFunction firecombustion_phasecdactions
{
 #lights_judgment,if=buff.combustion.down
 if buffexpires(combustion) spell(lights_judgment)

 unless buffexpires(combustion) and spell(bag_of_tricks) or enemies() > 1 and buffexpires(combustion) and spell(living_bomb) or buffexpires(combustion) and buffexpires(rune_of_power) and spell(mirrors_of_torment)
 {
  #use_item,name=hyperthread_wristwraps,if=buff.combustion.up&action.fire_blast.charges=0&action.fire_blast.recharge_time>gcd.max
  if buffpresent(combustion) and charges(fire_blast) == 0 and spellchargecooldown(fire_blast) > gcd() fireuseitemactions()

  unless spell(blood_of_the_enemy) or spell(memory_of_lucid_dreams) or spell(worldvein_resonance) or hasazeritetrait(blaster_master_trait) and charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { buffremaining(combustion) - baseduration(blaster_master_buff) } / spellcooldownduration(fire_blast) - buffremaining(combustion) / { baseduration(blaster_master_buff) - 0.5 } >= 0 or not hasazeritetrait(blaster_master_trait) or not hastalent(flame_on_talent) or buffremaining(combustion) <= baseduration(blaster_master_buff) or buffremaining(blaster_master_buff) < 0.5 or hasequippeditem(hyperthread_wristwraps_item) and spellcooldown(hyperthread_wristwraps_300142) < 5 } and buffpresent(combustion) and { not executetime(scorch) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up) or executetime(scorch) > 0 and buffexpires(hot_streak) and { buffexpires(heating_up) or hasazeritetrait(blaster_master_trait) } or hasazeritetrait(blaster_master_trait) and hastalent(flame_on_talent) and inflighttotarget(pyroblast) and buffexpires(heating_up) and buffexpires(hot_streak) } and spell(fire_blast) or not hasazeritetrait(blaster_master_trait) and { enemies() <= debuffcountonany(ignite) or not spellcooldown(phoenix_flames) == 0 } and message("conduit.infernal_cascade.enabled is not implemented") and charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { extended_combustion_remains() - baseduration(infernal_cascade) } / spellcooldownduration(fire_blast) - extended_combustion_remains() / { baseduration(infernal_cascade) - 0.5 } >= 0 or extended_combustion_remains() <= baseduration(infernal_cascade) or buffremaining(infernal_cascade) < 0.5 } and buffpresent(combustion) and not buffpresent(firestorm_buff) and not buffpresent(hot_streak) and message("hot_streak_spells_in_flight is not implemented") + buffstacks(heating_up) < 2 and spell(fire_blast) or not hasazeritetrait(blaster_master_trait) and { enemies() <= debuffcountonany(ignite) or not spellcooldown(phoenix_flames) == 0 } and not message("conduit.infernal_cascade.enabled is not implemented") and charges(fire_blast) >= 1 and buffpresent(combustion) and not buffpresent(firestorm_buff) and not buffpresent(hot_streak) and message("hot_streak_spells_in_flight is not implemented") + buffstacks(heating_up) < 2 and spell(fire_blast)
  {
   #counterspell,if=runeforge.disciplinary_command.equipped&buff.disciplinary_command.down&buff.disciplinary_command_arcane.down&cooldown.buff_disciplinary_command.ready
   if equippedruneforge(disciplinary_command_runeforge_fire) and buffexpires(disciplinary_command) and buffexpires(disciplinary_command_arcane_buff) and spellcooldown(buff_disciplinary_command) == 0 fireinterruptactions()

   unless equippedruneforge(disciplinary_command_runeforge_fire) and buffexpires(disciplinary_command) and buffexpires(disciplinary_command_arcane_buff) and spellcooldown(buff_disciplinary_command) == 0 and spell(arcane_explosion) or equippedruneforge(disciplinary_command_runeforge_fire) and buffexpires(disciplinary_command) and buffexpires(disciplinary_command_frost_buff) and spell(frostbolt)
   {
    #call_action_list,name=active_talents
    fireactive_talentscdactions()

    unless fireactive_talentscdpostconditions()
    {
     #combustion,use_off_gcd=1,use_while_casting=1,if=buff.combustion.down&(runeforge.disciplinary_command.equipped=buff.disciplinary_command.up)&(action.meteor.in_flight&action.meteor.in_flight_remains<=0.5|action.scorch.executing&action.scorch.execute_remains<0.5|action.fireball.executing&action.fireball.execute_remains<0.5|action.pyroblast.executing&action.pyroblast.execute_remains<0.5)
     if buffexpires(combustion) and equippedruneforge(disciplinary_command_runeforge_fire) == buffpresent(disciplinary_command) and { inflighttotarget(meteor) and 0 <= 0.5 or executetime(scorch) > 0 and executetime(scorch) < 0.5 or executetime(fireball) > 0 and executetime(fireball) < 0.5 or executetime(pyroblast) > 0 and executetime(pyroblast) < 0.5 } spell(combustion)
     #potion,if=buff.combustion.last_expire<=action.combustion.last_used
     if message("buff.combustion.last_expire is not implemented") <= message("action.combustion.last_used is not implemented") and checkboxon(opt_use_consumables) and target.classification(worldboss) item(superior_battle_potion_of_intellect_item usable=1)
     #blood_fury,if=buff.combustion.last_expire<=action.combustion.last_used
     if message("buff.combustion.last_expire is not implemented") <= message("action.combustion.last_used is not implemented") spell(blood_fury)

     unless message("buff.combustion.last_expire is not implemented") <= message("action.combustion.last_used is not implemented") and spell(berserking)
     {
      #fireblood,if=buff.combustion.last_expire<=action.combustion.last_used
      if message("buff.combustion.last_expire is not implemented") <= message("action.combustion.last_used is not implemented") spell(fireblood)
      #ancestral_call,if=buff.combustion.last_expire<=action.combustion.last_used
      if message("buff.combustion.last_expire is not implemented") <= message("action.combustion.last_used is not implemented") spell(ancestral_call)
      #use_items,if=buff.combustion.last_expire<=action.combustion.last_used
      if message("buff.combustion.last_expire is not implemented") <= message("action.combustion.last_used is not implemented") fireuseitemactions()
      #time_warp,if=runeforge.temporal_warp.equipped&buff.combustion.last_expire<=action.combustion.last_used&buff.exhaustion.up
      if equippedruneforge(temporal_warp_runeforge) and message("buff.combustion.last_expire is not implemented") <= message("action.combustion.last_used is not implemented") and buffpresent(exhaustion) and checkboxon(opt_time_warp) and debuffexpires(burst_haste_debuff any=1) spell(time_warp)
     }
    }
   }
  }
 }
}

AddFunction firecombustion_phasecdpostconditions
{
 buffexpires(combustion) and spell(bag_of_tricks) or enemies() > 1 and buffexpires(combustion) and spell(living_bomb) or buffexpires(combustion) and buffexpires(rune_of_power) and spell(mirrors_of_torment) or spell(blood_of_the_enemy) or spell(memory_of_lucid_dreams) or spell(worldvein_resonance) or hasazeritetrait(blaster_master_trait) and charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { buffremaining(combustion) - baseduration(blaster_master_buff) } / spellcooldownduration(fire_blast) - buffremaining(combustion) / { baseduration(blaster_master_buff) - 0.5 } >= 0 or not hasazeritetrait(blaster_master_trait) or not hastalent(flame_on_talent) or buffremaining(combustion) <= baseduration(blaster_master_buff) or buffremaining(blaster_master_buff) < 0.5 or hasequippeditem(hyperthread_wristwraps_item) and spellcooldown(hyperthread_wristwraps_300142) < 5 } and buffpresent(combustion) and { not executetime(scorch) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up) or executetime(scorch) > 0 and buffexpires(hot_streak) and { buffexpires(heating_up) or hasazeritetrait(blaster_master_trait) } or hasazeritetrait(blaster_master_trait) and hastalent(flame_on_talent) and inflighttotarget(pyroblast) and buffexpires(heating_up) and buffexpires(hot_streak) } and spell(fire_blast) or not hasazeritetrait(blaster_master_trait) and { enemies() <= debuffcountonany(ignite) or not spellcooldown(phoenix_flames) == 0 } and message("conduit.infernal_cascade.enabled is not implemented") and charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { extended_combustion_remains() - baseduration(infernal_cascade) } / spellcooldownduration(fire_blast) - extended_combustion_remains() / { baseduration(infernal_cascade) - 0.5 } >= 0 or extended_combustion_remains() <= baseduration(infernal_cascade) or buffremaining(infernal_cascade) < 0.5 } and buffpresent(combustion) and not buffpresent(firestorm_buff) and not buffpresent(hot_streak) and message("hot_streak_spells_in_flight is not implemented") + buffstacks(heating_up) < 2 and spell(fire_blast) or not hasazeritetrait(blaster_master_trait) and { enemies() <= debuffcountonany(ignite) or not spellcooldown(phoenix_flames) == 0 } and not message("conduit.infernal_cascade.enabled is not implemented") and charges(fire_blast) >= 1 and buffpresent(combustion) and not buffpresent(firestorm_buff) and not buffpresent(hot_streak) and message("hot_streak_spells_in_flight is not implemented") + buffstacks(heating_up) < 2 and spell(fire_blast) or equippedruneforge(disciplinary_command_runeforge_fire) and buffexpires(disciplinary_command) and buffexpires(disciplinary_command_arcane_buff) and spellcooldown(buff_disciplinary_command) == 0 and spell(arcane_explosion) or equippedruneforge(disciplinary_command_runeforge_fire) and buffexpires(disciplinary_command) and buffexpires(disciplinary_command_frost_buff) and spell(frostbolt) or fireactive_talentscdpostconditions() or message("buff.combustion.last_expire is not implemented") <= message("action.combustion.last_used is not implemented") and spell(berserking) or { buffpresent(hot_streak) or buffpresent(firestorm_buff) } and enemies() >= combustion_flamestrike() and spell(flamestrike) or buffpresent(sun_kings_blessing_ready_buff) and buffremaining(sun_kings_blessing_ready_buff) > casttime(pyroblast) and spell(pyroblast) or buffpresent(firestorm_buff) and spell(pyroblast) or buffpresent(pyroclasm) and buffremaining(pyroclasm) > casttime(pyroblast) and { buffremaining(combustion) > casttime(pyroblast) or buffexpires(combustion) } and enemies() < combustion_flamestrike() and spell(pyroblast) or buffpresent(hot_streak) and buffpresent(combustion) and spell(pyroblast) or previousgcdspell(scorch) and buffpresent(heating_up) and enemies() < combustion_flamestrike() and spell(pyroblast) or buffpresent(combustion) and { charges(fire_blast) < 1 and hastalent(pyroclasm_talent) and enemies() == 1 or not hastalent(pyroclasm_talent) or enemies() > 1 } and spell(phoenix_flames) or buffexpires(combustion) and spellcooldown(combustion) < casttime(fireball) and not message("conduit.flame_accretion.enabled is not implemented") and spell(fireball) or { buffremaining(combustion) > casttime(scorch) and buffpresent(combustion) or buffexpires(combustion) and spellcooldown(combustion) < casttime(scorch) } and spell(scorch) or buffremaining(combustion) < gcd() and enemies() > 1 and spell(living_bomb) or buffremaining(combustion) < gcd() and buffpresent(combustion) and target.distance(less 12) and spell(dragons_breath) or target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(scorch)
}

### actions.active_talents

AddFunction fireactive_talentsmainactions
{
 #living_bomb,if=active_enemies>1&buff.combustion.down&(variable.time_to_combustion>cooldown.living_bomb.duration|variable.time_to_combustion<=0|variable.disable_combustion)
 if enemies() > 1 and buffexpires(combustion) and { time_to_combustion() > spellcooldownduration(living_bomb) or time_to_combustion() <= 0 or disable_combustion() } spell(living_bomb)
 #meteor,if=!variable.disable_combustion&variable.time_to_combustion<=0|(cooldown.meteor.duration<variable.time_to_combustion&!talent.rune_of_power.enabled)|talent.rune_of_power.enabled&buff.rune_of_power.up&variable.time_to_combustion>action.meteor.cooldown|fight_remains<variable.time_to_combustion|variable.disable_combustion
 if not disable_combustion() and time_to_combustion() <= 0 or spellcooldownduration(meteor) < time_to_combustion() and not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and buffpresent(rune_of_power) and time_to_combustion() > spellcooldown(meteor) or fightremains() < time_to_combustion() or disable_combustion() spell(meteor)
 #dragons_breath,if=talent.alexstraszas_fury.enabled&(buff.combustion.down&!buff.hot_streak.react)
 if hastalent(alexstraszas_fury_talent) and buffexpires(combustion) and not buffpresent(hot_streak) and target.distance(less 12) spell(dragons_breath)
}

AddFunction fireactive_talentsmainpostconditions
{
}

AddFunction fireactive_talentsshortcdactions
{
}

AddFunction fireactive_talentsshortcdpostconditions
{
 enemies() > 1 and buffexpires(combustion) and { time_to_combustion() > spellcooldownduration(living_bomb) or time_to_combustion() <= 0 or disable_combustion() } and spell(living_bomb) or { not disable_combustion() and time_to_combustion() <= 0 or spellcooldownduration(meteor) < time_to_combustion() and not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and buffpresent(rune_of_power) and time_to_combustion() > spellcooldown(meteor) or fightremains() < time_to_combustion() or disable_combustion() } and spell(meteor) or hastalent(alexstraszas_fury_talent) and buffexpires(combustion) and not buffpresent(hot_streak) and target.distance(less 12) and spell(dragons_breath)
}

AddFunction fireactive_talentscdactions
{
}

AddFunction fireactive_talentscdpostconditions
{
 enemies() > 1 and buffexpires(combustion) and { time_to_combustion() > spellcooldownduration(living_bomb) or time_to_combustion() <= 0 or disable_combustion() } and spell(living_bomb) or { not disable_combustion() and time_to_combustion() <= 0 or spellcooldownduration(meteor) < time_to_combustion() and not hastalent(rune_of_power_talent) or hastalent(rune_of_power_talent) and buffpresent(rune_of_power) and time_to_combustion() > spellcooldown(meteor) or fightremains() < time_to_combustion() or disable_combustion() } and spell(meteor) or hastalent(alexstraszas_fury_talent) and buffexpires(combustion) and not buffpresent(hot_streak) and target.distance(less 12) and spell(dragons_breath)
}

### actions.default

AddFunction fire_defaultmainactions
{
 #concentrated_flame
 spell(concentrated_flame)
 #ripple_in_space
 spell(ripple_in_space)
 #the_unbound_force
 spell(the_unbound_force)
 #arcane_explosion,if=runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_arcane.down&cooldown.combustion.remains>30&!buff.disciplinary_command.up
 if equippedruneforge(disciplinary_command_runeforge_fire) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_arcane_buff) and spellcooldown(combustion) > 30 and not buffpresent(disciplinary_command) spell(arcane_explosion)
 #frostbolt,if=runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_frost.down&cooldown.combustion.remains>30&!buff.disciplinary_command.up
 if equippedruneforge(disciplinary_command_runeforge_fire) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and spellcooldown(combustion) > 30 and not buffpresent(disciplinary_command) spell(frostbolt)
 #rune_of_power,if=buff.rune_of_power.down&(variable.time_to_combustion>buff.rune_of_power.duration&variable.time_to_combustion>action.fire_blast.full_recharge_time|variable.time_to_combustion>fight_remains|variable.disable_combustion)
 if buffexpires(rune_of_power) and { time_to_combustion() > baseduration(rune_of_power) and time_to_combustion() > spellfullrecharge(fire_blast) or time_to_combustion() > fightremains() or disable_combustion() } spell(rune_of_power)
 #call_action_list,name=combustion_phase,if=!variable.disable_combustion&variable.time_to_combustion<=0
 if not disable_combustion() and time_to_combustion() <= 0 firecombustion_phasemainactions()

 unless not disable_combustion() and time_to_combustion() <= 0 and firecombustion_phasemainpostconditions()
 {
  #variable,name=fire_blast_pooling,value=!variable.disable_combustion&variable.time_to_combustion<action.fire_blast.full_recharge_time-variable.shifting_power_reduction*(cooldown.shifting_power.remains<variable.time_to_combustion)&variable.time_to_combustion<fight_remains|runeforge.sun_kings_blessing.equipped&action.fire_blast.charges_fractional<action.fire_blast.max_charges-0.5&(cooldown.shifting_power.remains>15|!covenant.night_fae.enabled)
  #call_action_list,name=rop_phase,if=buff.rune_of_power.up&(variable.time_to_combustion>0|variable.disable_combustion)
  if buffpresent(rune_of_power) and { time_to_combustion() > 0 or disable_combustion() } firerop_phasemainactions()

  unless buffpresent(rune_of_power) and { time_to_combustion() > 0 or disable_combustion() } and firerop_phasemainpostconditions()
  {
   #variable,name=phoenix_pooling,value=!variable.disable_combustion&variable.time_to_combustion<action.phoenix_flames.full_recharge_time&variable.time_to_combustion<fight_remains|runeforge.sun_kings_blessing.equipped
   #fire_blast,use_off_gcd=1,use_while_casting=1,if=!variable.fire_blast_pooling&(variable.time_to_combustion>0|variable.disable_combustion)&(active_enemies>=variable.hard_cast_flamestrike&(time-buff.combustion.last_expire>variable.delay_flamestrike|variable.disable_combustion))&!firestarter.active&!buff.hot_streak.react
   if not fire_blast_pooling() and { time_to_combustion() > 0 or disable_combustion() } and enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not buffpresent(hot_streak) spell(fire_blast)
   #fire_blast,use_off_gcd=1,use_while_casting=1,if=firestarter.active&charges>=1&!variable.fire_blast_pooling&(!action.fireball.executing&!action.pyroblast.in_flight&buff.heating_up.react|action.fireball.executing&!buff.hot_streak.react|action.pyroblast.in_flight&buff.heating_up.react&!buff.hot_streak.react)
   if talent(firestarter_talent) and target.healthpercent() >= 90 and charges(fire_blast) >= 1 and not fire_blast_pooling() and { not executetime(fireball) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up) or executetime(fireball) > 0 and not buffpresent(hot_streak) or inflighttotarget(pyroblast) and buffpresent(heating_up) and not buffpresent(hot_streak) } spell(fire_blast)
   #call_action_list,name=standard_rotation,if=(variable.time_to_combustion>0|variable.disable_combustion)&buff.rune_of_power.down
   if { time_to_combustion() > 0 or disable_combustion() } and buffexpires(rune_of_power) firestandard_rotationmainactions()
  }
 }
}

AddFunction fire_defaultmainpostconditions
{
 not disable_combustion() and time_to_combustion() <= 0 and firecombustion_phasemainpostconditions() or buffpresent(rune_of_power) and { time_to_combustion() > 0 or disable_combustion() } and firerop_phasemainpostconditions() or { time_to_combustion() > 0 or disable_combustion() } and buffexpires(rune_of_power) and firestandard_rotationmainpostconditions()
}

AddFunction fire_defaultshortcdactions
{
 #variable,name=time_to_combustion,op=set,value=talent.firestarter.enabled*firestarter.remains+(cooldown.combustion.remains*(1-variable.kindling_reduction*talent.kindling.enabled))*!cooldown.combustion.ready*buff.combustion.down
 #cycling_variable,name=ignite_min,op=min,value=dot.ignite.tick_dmg
 #shifting_power,if=buff.combustion.down&buff.rune_of_power.down&cooldown.combustion.remains>0&(cooldown.rune_of_power.remains>0|!talent.rune_of_power.enabled)
 if buffexpires(combustion) and buffexpires(rune_of_power) and spellcooldown(combustion) > 0 and { spellcooldown(rune_of_power) > 0 or not hastalent(rune_of_power_talent) } spell(shifting_power)
 #radiant_spark,if=(buff.combustion.down&buff.rune_of_power.down&(cooldown.combustion.remains<execute_time|cooldown.combustion.remains>cooldown.radiant_spark.duration))|(buff.rune_of_power.up&cooldown.combustion.remains>30)
 if buffexpires(combustion) and buffexpires(rune_of_power) and { spellcooldown(combustion) < executetime(radiant_spark) or spellcooldown(combustion) > spellcooldownduration(radiant_spark) } or buffpresent(rune_of_power) and spellcooldown(combustion) > 30 spell(radiant_spark)

 unless spell(concentrated_flame)
 {
  #reaping_flames
  spell(reaping_flames)
  #focused_azerite_beam
  spell(focused_azerite_beam)
  #purifying_blast
  spell(purifying_blast)

  unless spell(ripple_in_space) or spell(the_unbound_force) or equippedruneforge(disciplinary_command_runeforge_fire) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_arcane_buff) and spellcooldown(combustion) > 30 and not buffpresent(disciplinary_command) and spell(arcane_explosion) or equippedruneforge(disciplinary_command_runeforge_fire) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and spellcooldown(combustion) > 30 and not buffpresent(disciplinary_command) and spell(frostbolt) or buffexpires(rune_of_power) and { time_to_combustion() > baseduration(rune_of_power) and time_to_combustion() > spellfullrecharge(fire_blast) or time_to_combustion() > fightremains() or disable_combustion() } and spell(rune_of_power)
  {
   #call_action_list,name=combustion_phase,if=!variable.disable_combustion&variable.time_to_combustion<=0
   if not disable_combustion() and time_to_combustion() <= 0 firecombustion_phaseshortcdactions()

   unless not disable_combustion() and time_to_combustion() <= 0 and firecombustion_phaseshortcdpostconditions()
   {
    #variable,name=fire_blast_pooling,value=!variable.disable_combustion&variable.time_to_combustion<action.fire_blast.full_recharge_time-variable.shifting_power_reduction*(cooldown.shifting_power.remains<variable.time_to_combustion)&variable.time_to_combustion<fight_remains|runeforge.sun_kings_blessing.equipped&action.fire_blast.charges_fractional<action.fire_blast.max_charges-0.5&(cooldown.shifting_power.remains>15|!covenant.night_fae.enabled)
    #call_action_list,name=rop_phase,if=buff.rune_of_power.up&(variable.time_to_combustion>0|variable.disable_combustion)
    if buffpresent(rune_of_power) and { time_to_combustion() > 0 or disable_combustion() } firerop_phaseshortcdactions()

    unless buffpresent(rune_of_power) and { time_to_combustion() > 0 or disable_combustion() } and firerop_phaseshortcdpostconditions() or not fire_blast_pooling() and { time_to_combustion() > 0 or disable_combustion() } and enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not buffpresent(hot_streak) and spell(fire_blast) or talent(firestarter_talent) and target.healthpercent() >= 90 and charges(fire_blast) >= 1 and not fire_blast_pooling() and { not executetime(fireball) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up) or executetime(fireball) > 0 and not buffpresent(hot_streak) or inflighttotarget(pyroblast) and buffpresent(heating_up) and not buffpresent(hot_streak) } and spell(fire_blast)
    {
     #call_action_list,name=standard_rotation,if=(variable.time_to_combustion>0|variable.disable_combustion)&buff.rune_of_power.down
     if { time_to_combustion() > 0 or disable_combustion() } and buffexpires(rune_of_power) firestandard_rotationshortcdactions()
    }
   }
  }
 }
}

AddFunction fire_defaultshortcdpostconditions
{
 spell(concentrated_flame) or spell(ripple_in_space) or spell(the_unbound_force) or equippedruneforge(disciplinary_command_runeforge_fire) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_arcane_buff) and spellcooldown(combustion) > 30 and not buffpresent(disciplinary_command) and spell(arcane_explosion) or equippedruneforge(disciplinary_command_runeforge_fire) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and spellcooldown(combustion) > 30 and not buffpresent(disciplinary_command) and spell(frostbolt) or buffexpires(rune_of_power) and { time_to_combustion() > baseduration(rune_of_power) and time_to_combustion() > spellfullrecharge(fire_blast) or time_to_combustion() > fightremains() or disable_combustion() } and spell(rune_of_power) or not disable_combustion() and time_to_combustion() <= 0 and firecombustion_phaseshortcdpostconditions() or buffpresent(rune_of_power) and { time_to_combustion() > 0 or disable_combustion() } and firerop_phaseshortcdpostconditions() or not fire_blast_pooling() and { time_to_combustion() > 0 or disable_combustion() } and enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not buffpresent(hot_streak) and spell(fire_blast) or talent(firestarter_talent) and target.healthpercent() >= 90 and charges(fire_blast) >= 1 and not fire_blast_pooling() and { not executetime(fireball) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up) or executetime(fireball) > 0 and not buffpresent(hot_streak) or inflighttotarget(pyroblast) and buffpresent(heating_up) and not buffpresent(hot_streak) } and spell(fire_blast) or { time_to_combustion() > 0 or disable_combustion() } and buffexpires(rune_of_power) and firestandard_rotationshortcdpostconditions()
}

AddFunction fire_defaultcdactions
{
 #counterspell,if=!runeforge.disciplinary_command.equipped
 if not equippedruneforge(disciplinary_command_runeforge_fire) fireinterruptactions()

 unless buffexpires(combustion) and buffexpires(rune_of_power) and spellcooldown(combustion) > 0 and { spellcooldown(rune_of_power) > 0 or not hastalent(rune_of_power_talent) } and spell(shifting_power) or { buffexpires(combustion) and buffexpires(rune_of_power) and { spellcooldown(combustion) < executetime(radiant_spark) or spellcooldown(combustion) > spellcooldownduration(radiant_spark) } or buffpresent(rune_of_power) and spellcooldown(combustion) > 30 } and spell(radiant_spark)
 {
  #deathborne,if=buff.combustion.down&buff.rune_of_power.down&cooldown.combustion.remains<execute_time
  if buffexpires(combustion) and buffexpires(rune_of_power) and spellcooldown(combustion) < executetime(deathborne) spell(deathborne)
  #mirror_image,if=buff.combustion.down&debuff.radiant_spark_vulnerability.down
  if buffexpires(combustion) and target.debuffexpires(radiant_spark_vulnerability) spell(mirror_image)
  #use_item,name=azsharas_font_of_power,if=variable.time_to_combustion<=5+15*variable.font_double_on_use&variable.time_to_combustion>0&!variable.disable_combustion
  if time_to_combustion() <= 5 + 15 * font_double_on_use() and time_to_combustion() > 0 and not disable_combustion() fireuseitemactions()
  #guardian_of_azeroth,if=(variable.time_to_combustion<10|fight_remains<variable.time_to_combustion)&!variable.disable_combustion
  if { time_to_combustion() < 10 or fightremains() < time_to_combustion() } and not disable_combustion() spell(guardian_of_azeroth)

  unless spell(concentrated_flame) or spell(reaping_flames) or spell(focused_azerite_beam) or spell(purifying_blast) or spell(ripple_in_space) or spell(the_unbound_force)
  {
   #counterspell,if=runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_arcane.down&cooldown.combustion.remains>30&!buff.disciplinary_command.up
   if equippedruneforge(disciplinary_command_runeforge_fire) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_arcane_buff) and spellcooldown(combustion) > 30 and not buffpresent(disciplinary_command) fireinterruptactions()

   unless equippedruneforge(disciplinary_command_runeforge_fire) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_arcane_buff) and spellcooldown(combustion) > 30 and not buffpresent(disciplinary_command) and spell(arcane_explosion) or equippedruneforge(disciplinary_command_runeforge_fire) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and spellcooldown(combustion) > 30 and not buffpresent(disciplinary_command) and spell(frostbolt) or buffexpires(rune_of_power) and { time_to_combustion() > baseduration(rune_of_power) and time_to_combustion() > spellfullrecharge(fire_blast) or time_to_combustion() > fightremains() or disable_combustion() } and spell(rune_of_power)
   {
    #call_action_list,name=combustion_phase,if=!variable.disable_combustion&variable.time_to_combustion<=0
    if not disable_combustion() and time_to_combustion() <= 0 firecombustion_phasecdactions()

    unless not disable_combustion() and time_to_combustion() <= 0 and firecombustion_phasecdpostconditions()
    {
     #variable,name=fire_blast_pooling,value=!variable.disable_combustion&variable.time_to_combustion<action.fire_blast.full_recharge_time-variable.shifting_power_reduction*(cooldown.shifting_power.remains<variable.time_to_combustion)&variable.time_to_combustion<fight_remains|runeforge.sun_kings_blessing.equipped&action.fire_blast.charges_fractional<action.fire_blast.max_charges-0.5&(cooldown.shifting_power.remains>15|!covenant.night_fae.enabled)
     #call_action_list,name=rop_phase,if=buff.rune_of_power.up&(variable.time_to_combustion>0|variable.disable_combustion)
     if buffpresent(rune_of_power) and { time_to_combustion() > 0 or disable_combustion() } firerop_phasecdactions()

     unless buffpresent(rune_of_power) and { time_to_combustion() > 0 or disable_combustion() } and firerop_phasecdpostconditions() or not fire_blast_pooling() and { time_to_combustion() > 0 or disable_combustion() } and enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not buffpresent(hot_streak) and spell(fire_blast) or talent(firestarter_talent) and target.healthpercent() >= 90 and charges(fire_blast) >= 1 and not fire_blast_pooling() and { not executetime(fireball) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up) or executetime(fireball) > 0 and not buffpresent(hot_streak) or inflighttotarget(pyroblast) and buffpresent(heating_up) and not buffpresent(hot_streak) } and spell(fire_blast)
     {
      #call_action_list,name=standard_rotation,if=(variable.time_to_combustion>0|variable.disable_combustion)&buff.rune_of_power.down
      if { time_to_combustion() > 0 or disable_combustion() } and buffexpires(rune_of_power) firestandard_rotationcdactions()
     }
    }
   }
  }
 }
}

AddFunction fire_defaultcdpostconditions
{
 buffexpires(combustion) and buffexpires(rune_of_power) and spellcooldown(combustion) > 0 and { spellcooldown(rune_of_power) > 0 or not hastalent(rune_of_power_talent) } and spell(shifting_power) or { buffexpires(combustion) and buffexpires(rune_of_power) and { spellcooldown(combustion) < executetime(radiant_spark) or spellcooldown(combustion) > spellcooldownduration(radiant_spark) } or buffpresent(rune_of_power) and spellcooldown(combustion) > 30 } and spell(radiant_spark) or spell(concentrated_flame) or spell(reaping_flames) or spell(focused_azerite_beam) or spell(purifying_blast) or spell(ripple_in_space) or spell(the_unbound_force) or equippedruneforge(disciplinary_command_runeforge_fire) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_arcane_buff) and spellcooldown(combustion) > 30 and not buffpresent(disciplinary_command) and spell(arcane_explosion) or equippedruneforge(disciplinary_command_runeforge_fire) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_frost_buff) and spellcooldown(combustion) > 30 and not buffpresent(disciplinary_command) and spell(frostbolt) or buffexpires(rune_of_power) and { time_to_combustion() > baseduration(rune_of_power) and time_to_combustion() > spellfullrecharge(fire_blast) or time_to_combustion() > fightremains() or disable_combustion() } and spell(rune_of_power) or not disable_combustion() and time_to_combustion() <= 0 and firecombustion_phasecdpostconditions() or buffpresent(rune_of_power) and { time_to_combustion() > 0 or disable_combustion() } and firerop_phasecdpostconditions() or not fire_blast_pooling() and { time_to_combustion() > 0 or disable_combustion() } and enemies() >= hard_cast_flamestrike() and { timeincombat() - message("buff.combustion.last_expire is not implemented") > delay_flamestrike() or disable_combustion() } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not buffpresent(hot_streak) and spell(fire_blast) or talent(firestarter_talent) and target.healthpercent() >= 90 and charges(fire_blast) >= 1 and not fire_blast_pooling() and { not executetime(fireball) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up) or executetime(fireball) > 0 and not buffpresent(hot_streak) or inflighttotarget(pyroblast) and buffpresent(heating_up) and not buffpresent(hot_streak) } and spell(fire_blast) or { time_to_combustion() > 0 or disable_combustion() } and buffexpires(rune_of_power) and firestandard_rotationcdpostconditions()
}

### Fire icons.

AddCheckBox(opt_mage_fire_aoe l(aoe) default specialization=fire)

AddIcon checkbox=!opt_mage_fire_aoe enemies=1 help=shortcd specialization=fire
{
 if not incombat() fireprecombatshortcdactions()
 fire_defaultshortcdactions()
}

AddIcon checkbox=opt_mage_fire_aoe help=shortcd specialization=fire
{
 if not incombat() fireprecombatshortcdactions()
 fire_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=fire
{
 if not incombat() fireprecombatmainactions()
 fire_defaultmainactions()
}

AddIcon checkbox=opt_mage_fire_aoe help=aoe specialization=fire
{
 if not incombat() fireprecombatmainactions()
 fire_defaultmainactions()
}

AddIcon checkbox=!opt_mage_fire_aoe enemies=1 help=cd specialization=fire
{
 if not incombat() fireprecombatcdactions()
 fire_defaultcdactions()
}

AddIcon checkbox=opt_mage_fire_aoe help=cd specialization=fire
{
 if not incombat() fireprecombatcdactions()
 fire_defaultcdactions()
}

### Required symbols
# alexstraszas_fury
# alexstraszas_fury_talent
# ancestral_call
# ancient_knot_of_wisdom_item
# arcane_explosion
# arcane_intellect
# azsharas_font_of_power_item
# azurethos_singed_plumage_item
# bag_of_tricks
# balefire_branch_item
# berserking
# blaster_master_buff
# blaster_master_trait
# blood_fury
# blood_of_the_enemy
# buff_disciplinary_command
# combustion
# concentrated_flame
# counterspell
# deathborne
# disciplinary_command
# disciplinary_command_arcane_buff
# disciplinary_command_frost_buff
# disciplinary_command_runeforge_fire
# dragons_breath
# exhaustion
# fire_blast
# fireball
# fireblood
# firestarter_talent
# firestorm_buff
# flame_on_talent
# flame_patch_talent
# flamestrike
# focused_azerite_beam
# from_the_ashes_talent
# frostbolt
# gladiators_badge
# gladiators_medallion_item
# guardian_of_azeroth
# heating_up
# hot_streak
# hyperthread_wristwraps_300142
# hyperthread_wristwraps_item
# ignite
# ignition_mages_fuse_item
# infernal_cascade
# kindling_talent
# lights_judgment
# living_bomb
# manifesto_of_madness_item
# memory_of_lucid_dreams
# meteor
# mirror_image
# mirrors_of_torment
# neural_synapse_enhancer_item
# night_fae
# phoenix_flames
# purifying_blast
# pyroblast
# pyroclasm
# pyroclasm_talent
# quaking_palm
# radiant_spark
# radiant_spark_vulnerability
# reaping_flames
# ripple_in_space
# rune_of_power
# rune_of_power_talent
# scorch
# searing_touch_talent
# shifting_power
# shockbiters_fang_item
# sun_kings_blessing_ready_buff
# sun_kings_blessing_runeforge
# superior_battle_potion_of_intellect_item
# temporal_warp_runeforge
# the_unbound_force
# time_warp
# tzanes_barkspines_item
# worldvein_resonance
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
 if buffpresent(freezing_rain_buff) or enemies() >= 3 or enemies() >= 2 and not equippedruneforge(cold_front_runeforge) spell(blizzard)
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
 if equippedruneforge(disciplinary_command_runeforge_frost) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_arcane_buff) spell(arcane_explosion)
 #fire_blast,if=runeforge.disciplinary_command.equipped&cooldown.buff_disciplinary_command.ready&buff.disciplinary_command_fire.down
 if equippedruneforge(disciplinary_command_runeforge_frost) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) spell(fire_blast)
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

  unless { buffpresent(freezing_rain_buff) or enemies() >= 3 or enemies() >= 2 and not equippedruneforge(cold_front_runeforge) } and spell(blizzard) or message("remaining_winters_chill is not implemented") == 1 and target.debuffpresent(winters_chill) and spell(ray_of_frost) or message("remaining_winters_chill is not implemented") and target.debuffremaining(winters_chill) > casttime(glacial_spike) + traveltime(glacial_spike) and spell(glacial_spike) or message("remaining_winters_chill is not implemented") and message("remaining_winters_chill is not implemented") > buffstacks(fingers_of_frost) and target.debuffremaining(winters_chill) > traveltime(ice_lance) and spell(ice_lance) or spell(comet_storm) or spell(ice_nova)
  {
   #radiant_spark,if=buff.freezing_winds.up&active_enemies=1
   if buffpresent(freezing_winds) and enemies() == 1 spell(radiant_spark)

   unless { buffpresent(fingers_of_frost) or target.debuffremaining(frozen) > traveltime(ice_lance) } and spell(ice_lance) or spell(ebonbolt)
   {
    #radiant_spark,if=(!runeforge.freezing_winds.equipped|active_enemies>=2)&(buff.brain_freeze.react|soulbind.combat_meditation.enabled)
    if { not equippedruneforge(freezing_winds_runeforge) or enemies() >= 2 } and { buffpresent(brain_freeze) or message("soulbind.combat_meditation.enabled is not implemented") } spell(radiant_spark)
    #shifting_power,if=active_enemies>=3
    if enemies() >= 3 spell(shifting_power)
    #shifting_power,line_cd=60,if=(soulbind.field_of_blossoms.enabled|soulbind.grove_invigoration.enabled)&(!talent.rune_of_power.enabled|buff.rune_of_power.down&cooldown.rune_of_power.remains>16)
    if timesincepreviousspell(shifting_power) > 60 and { message("soulbind.field_of_blossoms.enabled is not implemented") or message("soulbind.grove_invigoration.enabled is not implemented") } and { not hastalent(rune_of_power_talent) or buffexpires(rune_of_power) and spellcooldown(rune_of_power) > 16 } spell(shifting_power)
    #mirrors_of_torment
    spell(mirrors_of_torment)
    #frost_nova,if=runeforge.grisly_icicle.equipped&target.level<=level&debuff.frozen.down
    if equippedruneforge(grisly_icicle_runeforge_frost) and level() <= level() and target.debuffexpires(frozen) spell(frost_nova)
   }
  }
 }
}

AddFunction froststshortcdpostconditions
{
 { message("remaining_winters_chill is not implemented") == 0 or target.debuffexpires(winters_chill) } and { previousgcdspell(ebonbolt) or buffpresent(brain_freeze) and { previousgcdspell(radiant_spark) or previousgcdspell(glacial_spike) or previousgcdspell(frostbolt) or { target.debuffpresent(mirrors_of_torment) or buffpresent(expanded_potential_buff) or buffpresent(freezing_winds) } and buffstacks(fingers_of_frost) == 0 } } and spell(flurry) or { buffpresent(freezing_rain_buff) or enemies() >= 3 or enemies() >= 2 and not equippedruneforge(cold_front_runeforge) } and spell(blizzard) or message("remaining_winters_chill is not implemented") == 1 and target.debuffpresent(winters_chill) and spell(ray_of_frost) or message("remaining_winters_chill is not implemented") and target.debuffremaining(winters_chill) > casttime(glacial_spike) + traveltime(glacial_spike) and spell(glacial_spike) or message("remaining_winters_chill is not implemented") and message("remaining_winters_chill is not implemented") > buffstacks(fingers_of_frost) and target.debuffremaining(winters_chill) > traveltime(ice_lance) and spell(ice_lance) or spell(comet_storm) or spell(ice_nova) or { buffpresent(fingers_of_frost) or target.debuffremaining(frozen) > traveltime(ice_lance) } and spell(ice_lance) or spell(ebonbolt) or equippedruneforge(disciplinary_command_runeforge_frost) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_arcane_buff) and spell(arcane_explosion) or equippedruneforge(disciplinary_command_runeforge_frost) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and spell(fire_blast) or buffpresent(brain_freeze) and spell(glacial_spike) or spell(frostbolt)
}

AddFunction froststcdactions
{
}

AddFunction froststcdpostconditions
{
 { message("remaining_winters_chill is not implemented") == 0 or target.debuffexpires(winters_chill) } and { previousgcdspell(ebonbolt) or buffpresent(brain_freeze) and { previousgcdspell(radiant_spark) or previousgcdspell(glacial_spike) or previousgcdspell(frostbolt) or { target.debuffpresent(mirrors_of_torment) or buffpresent(expanded_potential_buff) or buffpresent(freezing_winds) } and buffstacks(fingers_of_frost) == 0 } } and spell(flurry) or spell(frozen_orb) or { buffpresent(freezing_rain_buff) or enemies() >= 3 or enemies() >= 2 and not equippedruneforge(cold_front_runeforge) } and spell(blizzard) or message("remaining_winters_chill is not implemented") == 1 and target.debuffpresent(winters_chill) and spell(ray_of_frost) or message("remaining_winters_chill is not implemented") and target.debuffremaining(winters_chill) > casttime(glacial_spike) + traveltime(glacial_spike) and spell(glacial_spike) or message("remaining_winters_chill is not implemented") and message("remaining_winters_chill is not implemented") > buffstacks(fingers_of_frost) and target.debuffremaining(winters_chill) > traveltime(ice_lance) and spell(ice_lance) or spell(comet_storm) or spell(ice_nova) or buffpresent(freezing_winds) and enemies() == 1 and spell(radiant_spark) or { buffpresent(fingers_of_frost) or target.debuffremaining(frozen) > traveltime(ice_lance) } and spell(ice_lance) or spell(ebonbolt) or { not equippedruneforge(freezing_winds_runeforge) or enemies() >= 2 } and { buffpresent(brain_freeze) or message("soulbind.combat_meditation.enabled is not implemented") } and spell(radiant_spark) or enemies() >= 3 and spell(shifting_power) or timesincepreviousspell(shifting_power) > 60 and { message("soulbind.field_of_blossoms.enabled is not implemented") or message("soulbind.grove_invigoration.enabled is not implemented") } and { not hastalent(rune_of_power_talent) or buffexpires(rune_of_power) and spellcooldown(rune_of_power) > 16 } and spell(shifting_power) or spell(mirrors_of_torment) or equippedruneforge(grisly_icicle_runeforge_frost) and level() <= level() and target.debuffexpires(frozen) and spell(frost_nova) or equippedruneforge(disciplinary_command_runeforge_frost) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_arcane_buff) and spell(arcane_explosion) or equippedruneforge(disciplinary_command_runeforge_frost) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and spell(fire_blast) or buffpresent(brain_freeze) and spell(glacial_spike) or spell(frostbolt)
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
 #potion,if=prev_off_gcd.icy_veins|fight_remains<30
 if { previousoffgcdspell(icy_veins) or fightremains() < 30 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(superior_battle_potion_of_intellect_item usable=1)

 unless message("soulbind.wasteland_propriety.enabled is not implemented") and spell(mirrors_of_torment)
 {
  #deathborne
  spell(deathborne)

  unless spellcooldown(icy_veins) > 15 and buffexpires(rune_of_power) and spell(rune_of_power)
  {
   #icy_veins,if=buff.rune_of_power.down
   if buffexpires(rune_of_power) spell(icy_veins)
   #time_warp,if=runeforge.temporal_warp.equipped&buff.exhaustion.up&(prev_off_gcd.icy_veins|fight_remains<30)
   if equippedruneforge(temporal_warp_runeforge) and buffpresent(exhaustion) and { previousoffgcdspell(icy_veins) or fightremains() < 30 } and checkboxon(opt_time_warp) and debuffexpires(burst_haste_debuff any=1) spell(time_warp)
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
 if equippedruneforge(disciplinary_command_runeforge_frost) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) spell(fire_blast)
 #arcane_explosion,if=mana.pct>30&!runeforge.cold_front.equipped&(!runeforge.freezing_winds.equipped|buff.freezing_winds.up)
 if manapercent() > 30 and not equippedruneforge(cold_front_runeforge) and { not equippedruneforge(freezing_winds_runeforge) or buffpresent(freezing_winds) } spell(arcane_explosion)
 #ebonbolt
 spell(ebonbolt)
 #ice_lance,if=runeforge.glacial_fragments.equipped&talent.splitting_ice.enabled
 if equippedruneforge(glacial_fragments_runeforge) and hastalent(splitting_ice_talent) spell(ice_lance)
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
  if equippedruneforge(grisly_icicle_runeforge_frost) and level() <= level() and target.debuffexpires(frozen) spell(frost_nova)
 }
}

AddFunction frostaoeshortcdpostconditions
{
 spell(blizzard) or { message("remaining_winters_chill is not implemented") == 0 or target.debuffexpires(winters_chill) } and { previousgcdspell(ebonbolt) or buffpresent(brain_freeze) and buffstacks(fingers_of_frost) == 0 } and spell(flurry) or spell(ice_nova) or spell(comet_storm) or { buffpresent(fingers_of_frost) or target.debuffremaining(frozen) > traveltime(ice_lance) or message("remaining_winters_chill is not implemented") and target.debuffremaining(winters_chill) > traveltime(ice_lance) } and spell(ice_lance) or equippedruneforge(disciplinary_command_runeforge_frost) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and spell(fire_blast) or manapercent() > 30 and not equippedruneforge(cold_front_runeforge) and { not equippedruneforge(freezing_winds_runeforge) or buffpresent(freezing_winds) } and spell(arcane_explosion) or spell(ebonbolt) or equippedruneforge(glacial_fragments_runeforge) and hastalent(splitting_ice_talent) and spell(ice_lance) or spell(frostbolt)
}

AddFunction frostaoecdactions
{
}

AddFunction frostaoecdpostconditions
{
 spell(frozen_orb) or spell(blizzard) or { message("remaining_winters_chill is not implemented") == 0 or target.debuffexpires(winters_chill) } and { previousgcdspell(ebonbolt) or buffpresent(brain_freeze) and buffstacks(fingers_of_frost) == 0 } and spell(flurry) or spell(ice_nova) or spell(comet_storm) or { buffpresent(fingers_of_frost) or target.debuffremaining(frozen) > traveltime(ice_lance) or message("remaining_winters_chill is not implemented") and target.debuffremaining(winters_chill) > traveltime(ice_lance) } and spell(ice_lance) or spell(radiant_spark) or spell(shifting_power) or spell(mirrors_of_torment) or equippedruneforge(grisly_icicle_runeforge_frost) and level() <= level() and target.debuffexpires(frozen) and spell(frost_nova) or equippedruneforge(disciplinary_command_runeforge_frost) and spellcooldown(buff_disciplinary_command) == 0 and buffexpires(disciplinary_command_fire_buff) and spell(fire_blast) or manapercent() > 30 and not equippedruneforge(cold_front_runeforge) and { not equippedruneforge(freezing_winds_runeforge) or buffpresent(freezing_winds) } and spell(arcane_explosion) or spell(ebonbolt) or equippedruneforge(glacial_fragments_runeforge) and hastalent(splitting_ice_talent) and spell(ice_lance) or spell(frostbolt)
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
# cold_front_runeforge
# comet_storm
# concentrated_flame
# counterspell
# deathborne
# disciplinary_command_arcane_buff
# disciplinary_command_fire_buff
# disciplinary_command_runeforge_frost
# ebonbolt
# exhaustion
# expanded_potential_buff
# fingers_of_frost
# fire_blast
# fireblood
# flurry
# focused_azerite_beam
# freezing_rain_buff
# freezing_winds
# freezing_winds_runeforge
# frost_nova
# frostbolt
# frozen
# frozen_orb
# glacial_fragments_runeforge
# glacial_spike
# grisly_icicle_runeforge_frost
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
# splitting_ice_talent
# summon_water_elemental
# superior_battle_potion_of_intellect_item
# temporal_warp_runeforge
# the_unbound_force
# time_warp
# winters_chill
# worldvein_resonance
]]
        OvaleScripts:RegisterScript("MAGE", "frost", name, desc, code, "script")
    end
end
