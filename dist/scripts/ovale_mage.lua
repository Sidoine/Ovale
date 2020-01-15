local __exports = LibStub:NewLibrary("ovale/scripts/ovale_mage", 80201)
if not __exports then return end
__exports.registerMage = function(OvaleScripts)
    do
        local name = "sc_t23_mage_arcane"
        local desc = "[8.2] Simulationcraft: T23_Mage_Arcane"
        local code = [[
# Based on SimulationCraft profile "T23_Mage_Arcane".
#	class=mage
#	spec=arcane
#	talents=2032021

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)


AddFunction average_burn_length
{
 { 0 * undefined() - 0 + getstateduration() } / undefined()
}

AddFunction total_burns
{
 if not getstate(burn_phase) > 0 1
}

AddFunction font_double_on_use
{
 hasequippeditem(azsharas_font_of_power_item) and { hasequippeditem(gladiators_badge) or hasequippeditem(gladiators_medallion_item) or hasequippeditem(ignition_mages_fuse_item) or hasequippeditem(tzanes_barkspines_item) or hasequippeditem(azurethos_singed_plumage_item) or hasequippeditem(ancient_knot_of_wisdom_item) or hasequippeditem(shockbiters_fang_item) or hasequippeditem(neural_synapse_enhancer_item) or hasequippeditem(balefire_branch_item) }
}

AddFunction conserve_mana
{
 60 + 20 * hasazeritetrait(equipoise_trait)
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=arcane)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=arcane)
AddCheckBox(opt_arcane_mage_burn_phase l(arcane_mage_burn_phase) default specialization=arcane)
AddCheckBox(opt_blink spellname(blink) specialization=arcane)

AddFunction ArcaneInterruptActions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(counterspell) and target.isinterruptible() spell(counterspell)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
 }
}

AddFunction ArcaneUseItemActions
{
 item(Trinket0Slot text=13 usable=1)
 item(Trinket1Slot text=14 usable=1)
}

### actions.precombat

AddFunction ArcanePrecombatMainActions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 spell(arcane_intellect)
 #arcane_familiar
 spell(arcane_familiar)
 #arcane_blast
 if mana() > manacost(arcane_blast) spell(arcane_blast)
}

AddFunction ArcanePrecombatMainPostConditions
{
}

AddFunction ArcanePrecombatShortCdActions
{
}

AddFunction ArcanePrecombatShortCdPostConditions
{
 spell(arcane_intellect) or spell(arcane_familiar) or mana() > manacost(arcane_blast) and spell(arcane_blast)
}

AddFunction ArcanePrecombatCdActions
{
 unless spell(arcane_intellect) or spell(arcane_familiar)
 {
  #variable,name=conserve_mana,op=set,value=60+20*azerite.equipoise.enabled
  #variable,name=font_double_on_use,op=set,value=equipped.azsharas_font_of_power&(equipped.gladiators_badge|equipped.gladiators_medallion|equipped.ignition_mages_fuse|equipped.tzanes_barkspines|equipped.azurethos_singed_plumage|equipped.ancient_knot_of_wisdom|equipped.shockbiters_fang|equipped.neural_synapse_enhancer|equipped.balefire_branch)
  #snapshot_stats
  #use_item,name=azsharas_font_of_power
  arcaneuseitemactions()
  #mirror_image
  spell(mirror_image)
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)
 }
}

AddFunction ArcanePrecombatCdPostConditions
{
 spell(arcane_intellect) or spell(arcane_familiar) or mana() > manacost(arcane_blast) and spell(arcane_blast)
}

### actions.movement

AddFunction ArcaneMovementMainActions
{
 #arcane_missiles
 spell(arcane_missiles)
 #supernova
 spell(supernova)
}

AddFunction ArcaneMovementMainPostConditions
{
}

AddFunction ArcaneMovementShortCdActions
{
 #blink_any,if=movement.distance>=10
 if target.distance() >= 10 and checkboxon(opt_blink) spell(blink)
 #presence_of_mind
 spell(presence_of_mind)

 unless spell(arcane_missiles)
 {
  #arcane_orb
  spell(arcane_orb)
 }
}

AddFunction ArcaneMovementShortCdPostConditions
{
 spell(arcane_missiles) or spell(supernova)
}

AddFunction ArcaneMovementCdActions
{
}

AddFunction ArcaneMovementCdPostConditions
{
 target.distance() >= 10 and checkboxon(opt_blink) and spell(blink) or spell(presence_of_mind) or spell(arcane_missiles) or spell(arcane_orb) or spell(supernova)
}

### actions.essences

AddFunction ArcaneEssencesMainActions
{
 #concentrated_flame,line_cd=6,if=buff.rune_of_power.down&buff.arcane_power.down&(!burn_phase|time_to_die<cooldown.arcane_power.remains)&mana.time_to_max>=execute_time
 if timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and { not getstate(burn_phase) > 0 or target.timetodie() < spellcooldown(arcane_power) } and timetomaxmana() >= executetime(concentrated_flame_essence) spell(concentrated_flame_essence)
}

AddFunction ArcaneEssencesMainPostConditions
{
}

AddFunction ArcaneEssencesShortCdActions
{
 unless timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and { not getstate(burn_phase) > 0 or target.timetodie() < spellcooldown(arcane_power) } and timetomaxmana() >= executetime(concentrated_flame_essence) and spell(concentrated_flame_essence)
 {
  #purifying_blast,if=buff.rune_of_power.down&buff.arcane_power.down
  if buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) spell(purifying_blast)
  #ripple_in_space,if=buff.rune_of_power.down&buff.arcane_power.down
  if buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) spell(ripple_in_space_essence)
  #the_unbound_force,if=buff.rune_of_power.down&buff.arcane_power.down
  if buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) spell(the_unbound_force)
  #worldvein_resonance,if=burn_phase&buff.arcane_power.down&buff.rune_of_power.down&buff.arcane_charge.stack=buff.arcane_charge.max_stack|time_to_die<cooldown.arcane_power.remains
  if getstate(burn_phase) > 0 and buffexpires(arcane_power_buff) and buffexpires(rune_of_power_buff) and arcanecharges() == maxarcanecharges() or target.timetodie() < spellcooldown(arcane_power) spell(worldvein_resonance_essence)
 }
}

AddFunction ArcaneEssencesShortCdPostConditions
{
 timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and { not getstate(burn_phase) > 0 or target.timetodie() < spellcooldown(arcane_power) } and timetomaxmana() >= executetime(concentrated_flame_essence) and spell(concentrated_flame_essence)
}

AddFunction ArcaneEssencesCdActions
{
 #blood_of_the_enemy,if=burn_phase&buff.arcane_power.down&buff.rune_of_power.down&buff.arcane_charge.stack=buff.arcane_charge.max_stack|time_to_die<cooldown.arcane_power.remains
 if getstate(burn_phase) > 0 and buffexpires(arcane_power_buff) and buffexpires(rune_of_power_buff) and arcanecharges() == maxarcanecharges() or target.timetodie() < spellcooldown(arcane_power) spell(blood_of_the_enemy)

 unless timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and { not getstate(burn_phase) > 0 or target.timetodie() < spellcooldown(arcane_power) } and timetomaxmana() >= executetime(concentrated_flame_essence) and spell(concentrated_flame_essence)
 {
  #focused_azerite_beam,if=buff.rune_of_power.down&buff.arcane_power.down
  if buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) spell(focused_azerite_beam)
  #guardian_of_azeroth,if=buff.rune_of_power.down&buff.arcane_power.down
  if buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) spell(guardian_of_azeroth)

  unless buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(purifying_blast) or buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(ripple_in_space_essence) or buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(the_unbound_force)
  {
   #memory_of_lucid_dreams,if=!burn_phase&buff.arcane_power.down&cooldown.arcane_power.remains&buff.arcane_charge.stack=buff.arcane_charge.max_stack&(!talent.rune_of_power.enabled|action.rune_of_power.charges)|time_to_die<cooldown.arcane_power.remains
   if not getstate(burn_phase) > 0 and buffexpires(arcane_power_buff) and spellcooldown(arcane_power) > 0 and arcanecharges() == maxarcanecharges() and { not hastalent(rune_of_power_talent) or charges(rune_of_power) } or target.timetodie() < spellcooldown(arcane_power) spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction ArcaneEssencesCdPostConditions
{
 timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and { not getstate(burn_phase) > 0 or target.timetodie() < spellcooldown(arcane_power) } and timetomaxmana() >= executetime(concentrated_flame_essence) and spell(concentrated_flame_essence) or buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(purifying_blast) or buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(ripple_in_space_essence) or buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(the_unbound_force) or { getstate(burn_phase) > 0 and buffexpires(arcane_power_buff) and buffexpires(rune_of_power_buff) and arcanecharges() == maxarcanecharges() or target.timetodie() < spellcooldown(arcane_power) } and spell(worldvein_resonance_essence)
}

### actions.conserve

AddFunction ArcaneConserveMainActions
{
 #charged_up,if=buff.arcane_charge.stack=0
 if arcanecharges() == 0 spell(charged_up)
 #nether_tempest,if=(refreshable|!ticking)&buff.arcane_charge.stack=buff.arcane_charge.max_stack&buff.rune_of_power.down&buff.arcane_power.down
 if { target.refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and arcanecharges() == maxarcanecharges() and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) spell(nether_tempest)
 #arcane_blast,if=buff.rule_of_threes.up&buff.arcane_charge.stack>3
 if buffpresent(rule_of_threes) and arcanecharges() > 3 and mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_missiles,if=mana.pct<=95&buff.clearcasting.react&active_enemies<3,chain=1
 if manapercent() <= 95 and buffpresent(clearcasting_buff) and enemies() < 3 spell(arcane_missiles)
 #arcane_barrage,if=((buff.arcane_charge.stack=buff.arcane_charge.max_stack)&((mana.pct<=variable.conserve_mana)|(talent.rune_of_power.enabled&cooldown.arcane_power.remains>cooldown.rune_of_power.full_recharge_time&mana.pct<=variable.conserve_mana+25))|(talent.arcane_orb.enabled&cooldown.arcane_orb.remains<=gcd&cooldown.arcane_power.remains>10))|mana.pct<=(variable.conserve_mana-10)
 if arcanecharges() == maxarcanecharges() and { manapercent() <= undefined() or hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > spellcooldown(rune_of_power) and manapercent() <= undefined() + 25 } or hastalent(arcane_orb_talent) and spellcooldown(arcane_orb) <= gcd() and spellcooldown(arcane_power) > 10 or manapercent() <= undefined() - 10 spell(arcane_barrage)
 #supernova,if=mana.pct<=95
 if manapercent() <= 95 spell(supernova)
 #arcane_explosion,if=active_enemies>=3&(mana.pct>=variable.conserve_mana|buff.arcane_charge.stack=3)
 if enemies() >= 3 and { manapercent() >= undefined() or arcanecharges() == 3 } spell(arcane_explosion)
 #arcane_blast
 if mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_barrage
 spell(arcane_barrage)
}

AddFunction ArcaneConserveMainPostConditions
{
}

AddFunction ArcaneConserveShortCdActions
{
 unless arcanecharges() == 0 and spell(charged_up) or { target.refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and arcanecharges() == maxarcanecharges() and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(nether_tempest)
 {
  #arcane_orb,if=buff.arcane_charge.stack<=2&(cooldown.arcane_power.remains>10|active_enemies<=2)
  if arcanecharges() <= 2 and { spellcooldown(arcane_power) > 10 or enemies() <= 2 } spell(arcane_orb)

  unless buffpresent(rule_of_threes) and arcanecharges() > 3 and mana() > manacost(arcane_blast) and spell(arcane_blast)
  {
   #rune_of_power,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack&(full_recharge_time<=execute_time|full_recharge_time<=cooldown.arcane_power.remains|target.time_to_die<=cooldown.arcane_power.remains)
   if arcanecharges() == maxarcanecharges() and { spellfullrecharge(rune_of_power) <= executetime(rune_of_power) or spellfullrecharge(rune_of_power) <= spellcooldown(arcane_power) or target.timetodie() <= spellcooldown(arcane_power) } spell(rune_of_power)
  }
 }
}

AddFunction ArcaneConserveShortCdPostConditions
{
 arcanecharges() == 0 and spell(charged_up) or { target.refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and arcanecharges() == maxarcanecharges() and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(nether_tempest) or buffpresent(rule_of_threes) and arcanecharges() > 3 and mana() > manacost(arcane_blast) and spell(arcane_blast) or manapercent() <= 95 and buffpresent(clearcasting_buff) and enemies() < 3 and spell(arcane_missiles) or { arcanecharges() == maxarcanecharges() and { manapercent() <= undefined() or hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > spellcooldown(rune_of_power) and manapercent() <= undefined() + 25 } or hastalent(arcane_orb_talent) and spellcooldown(arcane_orb) <= gcd() and spellcooldown(arcane_power) > 10 or manapercent() <= undefined() - 10 } and spell(arcane_barrage) or manapercent() <= 95 and spell(supernova) or enemies() >= 3 and { manapercent() >= undefined() or arcanecharges() == 3 } and spell(arcane_explosion) or mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
}

AddFunction ArcaneConserveCdActions
{
 #mirror_image
 spell(mirror_image)

 unless arcanecharges() == 0 and spell(charged_up) or { target.refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and arcanecharges() == maxarcanecharges() and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(nether_tempest) or arcanecharges() <= 2 and { spellcooldown(arcane_power) > 10 or enemies() <= 2 } and spell(arcane_orb) or buffpresent(rule_of_threes) and arcanecharges() > 3 and mana() > manacost(arcane_blast) and spell(arcane_blast)
 {
  #use_item,name=tidestorm_codex,if=buff.rune_of_power.down&!buff.arcane_power.react&cooldown.arcane_power.remains>20
  if buffexpires(rune_of_power_buff) and not buffpresent(arcane_power_buff) and spellcooldown(arcane_power) > 20 arcaneuseitemactions()
  #use_item,effect_name=cyclotronic_blast,if=buff.rune_of_power.down&!buff.arcane_power.react&cooldown.arcane_power.remains>20
  if buffexpires(rune_of_power_buff) and not buffpresent(arcane_power_buff) and spellcooldown(arcane_power) > 20 arcaneuseitemactions()
 }
}

AddFunction ArcaneConserveCdPostConditions
{
 arcanecharges() == 0 and spell(charged_up) or { target.refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and arcanecharges() == maxarcanecharges() and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(nether_tempest) or arcanecharges() <= 2 and { spellcooldown(arcane_power) > 10 or enemies() <= 2 } and spell(arcane_orb) or buffpresent(rule_of_threes) and arcanecharges() > 3 and mana() > manacost(arcane_blast) and spell(arcane_blast) or arcanecharges() == maxarcanecharges() and { spellfullrecharge(rune_of_power) <= executetime(rune_of_power) or spellfullrecharge(rune_of_power) <= spellcooldown(arcane_power) or target.timetodie() <= spellcooldown(arcane_power) } and spell(rune_of_power) or manapercent() <= 95 and buffpresent(clearcasting_buff) and enemies() < 3 and spell(arcane_missiles) or { arcanecharges() == maxarcanecharges() and { manapercent() <= undefined() or hastalent(rune_of_power_talent) and spellcooldown(arcane_power) > spellcooldown(rune_of_power) and manapercent() <= undefined() + 25 } or hastalent(arcane_orb_talent) and spellcooldown(arcane_orb) <= gcd() and spellcooldown(arcane_power) > 10 or manapercent() <= undefined() - 10 } and spell(arcane_barrage) or manapercent() <= 95 and spell(supernova) or enemies() >= 3 and { manapercent() >= undefined() or arcanecharges() == 3 } and spell(arcane_explosion) or mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
}

### actions.burn

AddFunction ArcaneBurnMainActions
{
 #variable,name=total_burns,op=add,value=1,if=!burn_phase
 #start_burn_phase,if=!burn_phase
 if not getstate(burn_phase) > 0 and not getstate(burn_phase) > 0 setstate(burn_phase 1)
 #stop_burn_phase,if=burn_phase&prev_gcd.1.evocation&target.time_to_die>variable.average_burn_length&burn_phase_duration>0
 if getstate(burn_phase) > 0 and previousgcdspell(evocation) and target.timetodie() > undefined() and getstateduration() > 0 and getstate(burn_phase) > 0 setstate(burn_phase 0)
 #charged_up,if=buff.arcane_charge.stack<=1
 if arcanecharges() <= 1 spell(charged_up)
 #nether_tempest,if=(refreshable|!ticking)&buff.arcane_charge.stack=buff.arcane_charge.max_stack&buff.rune_of_power.down&buff.arcane_power.down
 if { target.refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and arcanecharges() == maxarcanecharges() and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) spell(nether_tempest)
 #arcane_blast,if=buff.rule_of_threes.up&talent.overpowered.enabled&active_enemies<3
 if buffpresent(rule_of_threes) and hastalent(overpowered_talent) and enemies() < 3 and mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_barrage,if=active_enemies>=3&(buff.arcane_charge.stack=buff.arcane_charge.max_stack)
 if enemies() >= 3 and arcanecharges() == maxarcanecharges() spell(arcane_barrage)
 #arcane_explosion,if=active_enemies>=3
 if enemies() >= 3 spell(arcane_explosion)
 #arcane_missiles,if=buff.clearcasting.react&active_enemies<3&(talent.amplification.enabled|(!talent.overpowered.enabled&azerite.arcane_pummeling.rank>=2)|buff.arcane_power.down),chain=1
 if buffpresent(clearcasting_buff) and enemies() < 3 and { hastalent(amplification_talent) or not hastalent(overpowered_talent) and azeritetraitrank(arcane_pummeling_trait) >= 2 or buffexpires(arcane_power_buff) } spell(arcane_missiles)
 #arcane_blast,if=active_enemies<3
 if enemies() < 3 and mana() > manacost(arcane_blast) spell(arcane_blast)
 #arcane_barrage
 spell(arcane_barrage)
}

AddFunction ArcaneBurnMainPostConditions
{
}

AddFunction ArcaneBurnShortCdActions
{
 #variable,name=total_burns,op=add,value=1,if=!burn_phase
 #start_burn_phase,if=!burn_phase
 if not getstate(burn_phase) > 0 and not getstate(burn_phase) > 0 setstate(burn_phase 1)
 #stop_burn_phase,if=burn_phase&prev_gcd.1.evocation&target.time_to_die>variable.average_burn_length&burn_phase_duration>0
 if getstate(burn_phase) > 0 and previousgcdspell(evocation) and target.timetodie() > undefined() and getstateduration() > 0 and getstate(burn_phase) > 0 setstate(burn_phase 0)

 unless arcanecharges() <= 1 and spell(charged_up) or { target.refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and arcanecharges() == maxarcanecharges() and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(nether_tempest) or buffpresent(rule_of_threes) and hastalent(overpowered_talent) and enemies() < 3 and mana() > manacost(arcane_blast) and spell(arcane_blast)
 {
  #rune_of_power,if=!buff.arcane_power.up&(mana.pct>=50|cooldown.arcane_power.remains=0)&(buff.arcane_charge.stack=buff.arcane_charge.max_stack)
  if not buffpresent(arcane_power_buff) and { manapercent() >= 50 or not spellcooldown(arcane_power) > 0 } and arcanecharges() == maxarcanecharges() spell(rune_of_power)
  #presence_of_mind,if=(talent.rune_of_power.enabled&buff.rune_of_power.remains<=buff.presence_of_mind.max_stack*action.arcane_blast.execute_time)|buff.arcane_power.remains<=buff.presence_of_mind.max_stack*action.arcane_blast.execute_time
  if hastalent(rune_of_power_talent) and totemremaining(rune_of_power) <= spelldata(presence_of_mind_buff max_stacks) * executetime(arcane_blast) or buffremaining(arcane_power_buff) <= spelldata(presence_of_mind_buff max_stacks) * executetime(arcane_blast) spell(presence_of_mind)
  #arcane_orb,if=buff.arcane_charge.stack=0|(active_enemies<3|(active_enemies<2&talent.resonance.enabled))
  if arcanecharges() == 0 or enemies() < 3 or enemies() < 2 and hastalent(resonance_talent) spell(arcane_orb)
 }
}

AddFunction ArcaneBurnShortCdPostConditions
{
 arcanecharges() <= 1 and spell(charged_up) or { target.refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and arcanecharges() == maxarcanecharges() and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(nether_tempest) or buffpresent(rule_of_threes) and hastalent(overpowered_talent) and enemies() < 3 and mana() > manacost(arcane_blast) and spell(arcane_blast) or enemies() >= 3 and arcanecharges() == maxarcanecharges() and spell(arcane_barrage) or enemies() >= 3 and spell(arcane_explosion) or buffpresent(clearcasting_buff) and enemies() < 3 and { hastalent(amplification_talent) or not hastalent(overpowered_talent) and azeritetraitrank(arcane_pummeling_trait) >= 2 or buffexpires(arcane_power_buff) } and spell(arcane_missiles) or enemies() < 3 and mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
}

AddFunction ArcaneBurnCdActions
{
 #variable,name=total_burns,op=add,value=1,if=!burn_phase
 #start_burn_phase,if=!burn_phase
 if not getstate(burn_phase) > 0 and not getstate(burn_phase) > 0 setstate(burn_phase 1)
 #stop_burn_phase,if=burn_phase&prev_gcd.1.evocation&target.time_to_die>variable.average_burn_length&burn_phase_duration>0
 if getstate(burn_phase) > 0 and previousgcdspell(evocation) and target.timetodie() > undefined() and getstateduration() > 0 and getstate(burn_phase) > 0 setstate(burn_phase 0)

 unless arcanecharges() <= 1 and spell(charged_up)
 {
  #mirror_image
  spell(mirror_image)

  unless { target.refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and arcanecharges() == maxarcanecharges() and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(nether_tempest) or buffpresent(rule_of_threes) and hastalent(overpowered_talent) and enemies() < 3 and mana() > manacost(arcane_blast) and spell(arcane_blast)
  {
   #lights_judgment,if=buff.arcane_power.down
   if buffexpires(arcane_power_buff) spell(lights_judgment)

   unless not buffpresent(arcane_power_buff) and { manapercent() >= 50 or not spellcooldown(arcane_power) > 0 } and arcanecharges() == maxarcanecharges() and spell(rune_of_power)
   {
    #berserking
    spell(berserking)
    #arcane_power
    spell(arcane_power)
    #use_items,if=buff.arcane_power.up|target.time_to_die<cooldown.arcane_power.remains
    if buffpresent(arcane_power_buff) or target.timetodie() < spellcooldown(arcane_power) arcaneuseitemactions()
    #blood_fury
    spell(blood_fury_sp)
    #fireblood
    spell(fireblood)
    #ancestral_call
    spell(ancestral_call)

    unless { hastalent(rune_of_power_talent) and totemremaining(rune_of_power) <= spelldata(presence_of_mind_buff max_stacks) * executetime(arcane_blast) or buffremaining(arcane_power_buff) <= spelldata(presence_of_mind_buff max_stacks) * executetime(arcane_blast) } and spell(presence_of_mind)
    {
     #potion,if=buff.arcane_power.up&(buff.berserking.up|buff.blood_fury.up|!(race.troll|race.orc))
     if buffpresent(arcane_power_buff) and { buffpresent(berserking_buff) or buffpresent(blood_fury_sp_buff) or not { race(Troll) or race(Orc) } } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)

     unless { arcanecharges() == 0 or enemies() < 3 or enemies() < 2 and hastalent(resonance_talent) } and spell(arcane_orb) or enemies() >= 3 and arcanecharges() == maxarcanecharges() and spell(arcane_barrage) or enemies() >= 3 and spell(arcane_explosion) or buffpresent(clearcasting_buff) and enemies() < 3 and { hastalent(amplification_talent) or not hastalent(overpowered_talent) and azeritetraitrank(arcane_pummeling_trait) >= 2 or buffexpires(arcane_power_buff) } and spell(arcane_missiles) or enemies() < 3 and mana() > manacost(arcane_blast) and spell(arcane_blast)
     {
      #variable,name=average_burn_length,op=set,value=(variable.average_burn_length*variable.total_burns-variable.average_burn_length+(burn_phase_duration))%variable.total_burns
      #evocation,interrupt_if=mana.pct>=85,interrupt_immediate=1
      spell(evocation)
     }
    }
   }
  }
 }
}

AddFunction ArcaneBurnCdPostConditions
{
 arcanecharges() <= 1 and spell(charged_up) or { target.refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and arcanecharges() == maxarcanecharges() and buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and spell(nether_tempest) or buffpresent(rule_of_threes) and hastalent(overpowered_talent) and enemies() < 3 and mana() > manacost(arcane_blast) and spell(arcane_blast) or not buffpresent(arcane_power_buff) and { manapercent() >= 50 or not spellcooldown(arcane_power) > 0 } and arcanecharges() == maxarcanecharges() and spell(rune_of_power) or { hastalent(rune_of_power_talent) and totemremaining(rune_of_power) <= spelldata(presence_of_mind_buff max_stacks) * executetime(arcane_blast) or buffremaining(arcane_power_buff) <= spelldata(presence_of_mind_buff max_stacks) * executetime(arcane_blast) } and spell(presence_of_mind) or { arcanecharges() == 0 or enemies() < 3 or enemies() < 2 and hastalent(resonance_talent) } and spell(arcane_orb) or enemies() >= 3 and arcanecharges() == maxarcanecharges() and spell(arcane_barrage) or enemies() >= 3 and spell(arcane_explosion) or buffpresent(clearcasting_buff) and enemies() < 3 and { hastalent(amplification_talent) or not hastalent(overpowered_talent) and azeritetraitrank(arcane_pummeling_trait) >= 2 or buffexpires(arcane_power_buff) } and spell(arcane_missiles) or enemies() < 3 and mana() > manacost(arcane_blast) and spell(arcane_blast) or spell(arcane_barrage)
}

### actions.default

AddFunction ArcaneDefaultMainActions
{
 #call_action_list,name=essences
 ArcaneEssencesMainActions()

 unless ArcaneEssencesMainPostConditions()
 {
  #call_action_list,name=burn,if=burn_phase|target.time_to_die<variable.average_burn_length
  if { getstate(burn_phase) > 0 or target.timetodie() < undefined() } and checkboxon(opt_arcane_mage_burn_phase) ArcaneBurnMainActions()

  unless { getstate(burn_phase) > 0 or target.timetodie() < undefined() } and checkboxon(opt_arcane_mage_burn_phase) and ArcaneBurnMainPostConditions()
  {
   #call_action_list,name=burn,if=(cooldown.arcane_power.remains=0&cooldown.evocation.remains<=variable.average_burn_length&(buff.arcane_charge.stack=buff.arcane_charge.max_stack|(talent.charged_up.enabled&cooldown.charged_up.remains=0&buff.arcane_charge.stack<=1)))
   if not spellcooldown(arcane_power) > 0 and spellcooldown(evocation) <= undefined() and { arcanecharges() == maxarcanecharges() or hastalent(charged_up_talent) and not spellcooldown(charged_up) > 0 and arcanecharges() <= 1 } and checkboxon(opt_arcane_mage_burn_phase) ArcaneBurnMainActions()

   unless not spellcooldown(arcane_power) > 0 and spellcooldown(evocation) <= undefined() and { arcanecharges() == maxarcanecharges() or hastalent(charged_up_talent) and not spellcooldown(charged_up) > 0 and arcanecharges() <= 1 } and checkboxon(opt_arcane_mage_burn_phase) and ArcaneBurnMainPostConditions()
   {
    #call_action_list,name=conserve,if=!burn_phase
    if not getstate(burn_phase) > 0 ArcaneConserveMainActions()

    unless not getstate(burn_phase) > 0 and ArcaneConserveMainPostConditions()
    {
     #call_action_list,name=movement
     ArcaneMovementMainActions()
    }
   }
  }
 }
}

AddFunction ArcaneDefaultMainPostConditions
{
 ArcaneEssencesMainPostConditions() or { getstate(burn_phase) > 0 or target.timetodie() < undefined() } and checkboxon(opt_arcane_mage_burn_phase) and ArcaneBurnMainPostConditions() or not spellcooldown(arcane_power) > 0 and spellcooldown(evocation) <= undefined() and { arcanecharges() == maxarcanecharges() or hastalent(charged_up_talent) and not spellcooldown(charged_up) > 0 and arcanecharges() <= 1 } and checkboxon(opt_arcane_mage_burn_phase) and ArcaneBurnMainPostConditions() or not getstate(burn_phase) > 0 and ArcaneConserveMainPostConditions() or ArcaneMovementMainPostConditions()
}

AddFunction ArcaneDefaultShortCdActions
{
 #call_action_list,name=essences
 ArcaneEssencesShortCdActions()

 unless ArcaneEssencesShortCdPostConditions()
 {
  #call_action_list,name=burn,if=burn_phase|target.time_to_die<variable.average_burn_length
  if { getstate(burn_phase) > 0 or target.timetodie() < undefined() } and checkboxon(opt_arcane_mage_burn_phase) ArcaneBurnShortCdActions()

  unless { getstate(burn_phase) > 0 or target.timetodie() < undefined() } and checkboxon(opt_arcane_mage_burn_phase) and ArcaneBurnShortCdPostConditions()
  {
   #call_action_list,name=burn,if=(cooldown.arcane_power.remains=0&cooldown.evocation.remains<=variable.average_burn_length&(buff.arcane_charge.stack=buff.arcane_charge.max_stack|(talent.charged_up.enabled&cooldown.charged_up.remains=0&buff.arcane_charge.stack<=1)))
   if not spellcooldown(arcane_power) > 0 and spellcooldown(evocation) <= undefined() and { arcanecharges() == maxarcanecharges() or hastalent(charged_up_talent) and not spellcooldown(charged_up) > 0 and arcanecharges() <= 1 } and checkboxon(opt_arcane_mage_burn_phase) ArcaneBurnShortCdActions()

   unless not spellcooldown(arcane_power) > 0 and spellcooldown(evocation) <= undefined() and { arcanecharges() == maxarcanecharges() or hastalent(charged_up_talent) and not spellcooldown(charged_up) > 0 and arcanecharges() <= 1 } and checkboxon(opt_arcane_mage_burn_phase) and ArcaneBurnShortCdPostConditions()
   {
    #call_action_list,name=conserve,if=!burn_phase
    if not getstate(burn_phase) > 0 ArcaneConserveShortCdActions()

    unless not getstate(burn_phase) > 0 and ArcaneConserveShortCdPostConditions()
    {
     #call_action_list,name=movement
     ArcaneMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction ArcaneDefaultShortCdPostConditions
{
 ArcaneEssencesShortCdPostConditions() or { getstate(burn_phase) > 0 or target.timetodie() < undefined() } and checkboxon(opt_arcane_mage_burn_phase) and ArcaneBurnShortCdPostConditions() or not spellcooldown(arcane_power) > 0 and spellcooldown(evocation) <= undefined() and { arcanecharges() == maxarcanecharges() or hastalent(charged_up_talent) and not spellcooldown(charged_up) > 0 and arcanecharges() <= 1 } and checkboxon(opt_arcane_mage_burn_phase) and ArcaneBurnShortCdPostConditions() or not getstate(burn_phase) > 0 and ArcaneConserveShortCdPostConditions() or ArcaneMovementShortCdPostConditions()
}

AddFunction ArcaneDefaultCdActions
{
 #counterspell
 arcaneinterruptactions()
 #call_action_list,name=essences
 ArcaneEssencesCdActions()

 unless ArcaneEssencesCdPostConditions()
 {
  #use_item,name=azsharas_font_of_power,if=buff.rune_of_power.down&buff.arcane_power.down&(cooldown.arcane_power.remains<=4+10*variable.font_double_on_use&cooldown.evocation.remains<=variable.average_burn_length+4+10*variable.font_double_on_use|time_to_die<cooldown.arcane_power.remains)
  if buffexpires(rune_of_power_buff) and buffexpires(arcane_power_buff) and { spellcooldown(arcane_power) <= 4 + 10 * undefined() and spellcooldown(evocation) <= undefined() + 4 + 10 * undefined() or target.timetodie() < spellcooldown(arcane_power) } arcaneuseitemactions()
  #call_action_list,name=burn,if=burn_phase|target.time_to_die<variable.average_burn_length
  if { getstate(burn_phase) > 0 or target.timetodie() < undefined() } and checkboxon(opt_arcane_mage_burn_phase) ArcaneBurnCdActions()

  unless { getstate(burn_phase) > 0 or target.timetodie() < undefined() } and checkboxon(opt_arcane_mage_burn_phase) and ArcaneBurnCdPostConditions()
  {
   #call_action_list,name=burn,if=(cooldown.arcane_power.remains=0&cooldown.evocation.remains<=variable.average_burn_length&(buff.arcane_charge.stack=buff.arcane_charge.max_stack|(talent.charged_up.enabled&cooldown.charged_up.remains=0&buff.arcane_charge.stack<=1)))
   if not spellcooldown(arcane_power) > 0 and spellcooldown(evocation) <= undefined() and { arcanecharges() == maxarcanecharges() or hastalent(charged_up_talent) and not spellcooldown(charged_up) > 0 and arcanecharges() <= 1 } and checkboxon(opt_arcane_mage_burn_phase) ArcaneBurnCdActions()

   unless not spellcooldown(arcane_power) > 0 and spellcooldown(evocation) <= undefined() and { arcanecharges() == maxarcanecharges() or hastalent(charged_up_talent) and not spellcooldown(charged_up) > 0 and arcanecharges() <= 1 } and checkboxon(opt_arcane_mage_burn_phase) and ArcaneBurnCdPostConditions()
   {
    #call_action_list,name=conserve,if=!burn_phase
    if not getstate(burn_phase) > 0 ArcaneConserveCdActions()

    unless not getstate(burn_phase) > 0 and ArcaneConserveCdPostConditions()
    {
     #call_action_list,name=movement
     ArcaneMovementCdActions()
    }
   }
  }
 }
}

AddFunction ArcaneDefaultCdPostConditions
{
 ArcaneEssencesCdPostConditions() or { getstate(burn_phase) > 0 or target.timetodie() < undefined() } and checkboxon(opt_arcane_mage_burn_phase) and ArcaneBurnCdPostConditions() or not spellcooldown(arcane_power) > 0 and spellcooldown(evocation) <= undefined() and { arcanecharges() == maxarcanecharges() or hastalent(charged_up_talent) and not spellcooldown(charged_up) > 0 and arcanecharges() <= 1 } and checkboxon(opt_arcane_mage_burn_phase) and ArcaneBurnCdPostConditions() or not getstate(burn_phase) > 0 and ArcaneConserveCdPostConditions() or ArcaneMovementCdPostConditions()
}

### Arcane icons.

AddCheckBox(opt_mage_arcane_aoe l(AOE) default specialization=arcane)

AddIcon checkbox=!opt_mage_arcane_aoe enemies=1 help=shortcd specialization=arcane
{
 if not incombat() arcaneprecombatshortcdactions()
 unless not incombat() and arcaneprecombatshortcdpostconditions()
 {
  arcanedefaultshortcdactions()
 }
}

AddIcon checkbox=opt_mage_arcane_aoe help=shortcd specialization=arcane
{
 if not incombat() arcaneprecombatshortcdactions()
 unless not incombat() and arcaneprecombatshortcdpostconditions()
 {
  arcanedefaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=arcane
{
 if not incombat() arcaneprecombatmainactions()
 unless not incombat() and arcaneprecombatmainpostconditions()
 {
  arcanedefaultmainactions()
 }
}

AddIcon checkbox=opt_mage_arcane_aoe help=aoe specialization=arcane
{
 if not incombat() arcaneprecombatmainactions()
 unless not incombat() and arcaneprecombatmainpostconditions()
 {
  arcanedefaultmainactions()
 }
}

AddIcon checkbox=!opt_mage_arcane_aoe enemies=1 help=cd specialization=arcane
{
 if not incombat() arcaneprecombatcdactions()
 unless not incombat() and arcaneprecombatcdpostconditions()
 {
  arcanedefaultcdactions()
 }
}

AddIcon checkbox=opt_mage_arcane_aoe help=cd specialization=arcane
{
 if not incombat() arcaneprecombatcdactions()
 unless not incombat() and arcaneprecombatcdpostconditions()
 {
  arcanedefaultcdactions()
 }
}

### Required symbols
# amplification_talent
# ancestral_call
# ancient_knot_of_wisdom_item
# arcane_barrage
# arcane_blast
# arcane_explosion
# arcane_familiar
# arcane_intellect
# arcane_missiles
# arcane_orb
# arcane_orb_talent
# arcane_power
# arcane_power_buff
# arcane_pummeling_trait
# azsharas_font_of_power_item
# azurethos_singed_plumage_item
# balefire_branch_item
# berserking
# berserking_buff
# blink
# blood_fury_sp
# blood_fury_sp_buff
# blood_of_the_enemy
# charged_up
# charged_up_talent
# clearcasting_buff
# concentrated_flame_essence
# counterspell
# equipoise_trait
# evocation
# fireblood
# focused_azerite_beam
# focused_resolve_item
# gladiators_badge
# gladiators_medallion_item
# guardian_of_azeroth
# ignition_mages_fuse_item
# lights_judgment
# memory_of_lucid_dreams_essence
# mirror_image
# nether_tempest
# nether_tempest_debuff
# neural_synapse_enhancer_item
# overpowered_talent
# presence_of_mind
# presence_of_mind_buff
# purifying_blast
# quaking_palm
# resonance_talent
# ripple_in_space_essence
# rule_of_threes
# rune_of_power
# rune_of_power_buff
# rune_of_power_talent
# shockbiters_fang_item
# supernova
# the_unbound_force
# tzanes_barkspines_item
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("MAGE", "arcane", name, desc, code, "script")
    end
    do
        local name = "sc_t23_mage_fire"
        local desc = "[8.2] Simulationcraft: T23_Mage_Fire"
        local code = [[
# Based on SimulationCraft profile "T23_Mage_Fire".
#	class=mage
#	spec=fire
#	talents=3031022

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)


AddFunction phoenix_pooling
{
 hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) < spellcooldown(phoenix_flames) and { spellcooldown(combustion) > undefined() or undefined() } and { spellcooldown(rune_of_power) < target.timetodie() or charges(rune_of_power) > 0 } or not undefined() and spellcooldown(combustion) < spellfullrecharge(phoenix_flames) and spellcooldown(combustion) < target.timetodie()
}

AddFunction fire_blast_pooling
{
 hastalent(rune_of_power_talent) and spellcooldown(rune_of_power) < spellcooldown(fire_blast) and { spellcooldown(combustion) > undefined() or undefined() or talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(rune_of_power) < target.timetodie() or charges(rune_of_power) > 0 } or not undefined() and spellcooldown(combustion) < spellfullrecharge(fire_blast) + spellcooldownduration(fire_blast) * hasazeritetrait(blaster_master_trait) and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and spellcooldown(combustion) < target.timetodie() or hastalent(firestarter_talent) and talent(firestarter_talent) and target.healthpercent() >= 90 and target.timetohealthpercent(90) < spellcooldown(fire_blast) + spellcooldownduration(fire_blast) * hasazeritetrait(blaster_master_trait)
}

AddFunction on_use_cutoff
{
 20 * undefined() and not undefined() + 40 * undefined() + 25 * hasequippeditem(azsharas_font_of_power_item) and not undefined()
}

AddFunction font_double_on_use
{
 hasequippeditem(azsharas_font_of_power_item) and undefined()
}

AddFunction combustion_on_use
{
 hasequippeditem(gladiators_badge) or hasequippeditem(gladiators_medallion_item) or hasequippeditem(ignition_mages_fuse_item) or hasequippeditem(tzanes_barkspines_item) or hasequippeditem(azurethos_singed_plumage_item) or hasequippeditem(ancient_knot_of_wisdom_item) or hasequippeditem(shockbiters_fang_item) or hasequippeditem(neural_synapse_enhancer_item) or hasequippeditem(balefire_branch_item)
}

AddFunction combustion_rop_cutoff
{
 60
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=fire)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=fire)

AddFunction FireInterruptActions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(counterspell) and target.isinterruptible() spell(counterspell)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
 }
}

AddFunction FireUseItemActions
{
 item(Trinket0Slot text=13 usable=1)
 item(Trinket1Slot text=14 usable=1)
}

### actions.standard_rotation

AddFunction FireStandardrotationMainActions
{
 #flamestrike,if=((talent.flame_patch.enabled&active_enemies>1&!firestarter.active)|active_enemies>4)&buff.hot_streak.react
 if { hastalent(flame_patch_talent) and enemies() > 1 and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or enemies() > 4 } and buffpresent(hot_streak_buff) spell(flamestrike)
 #pyroblast,if=buff.hot_streak.react&buff.hot_streak.remains<action.fireball.execute_time
 if buffpresent(hot_streak_buff) and buffremaining(hot_streak_buff) < executetime(fireball) spell(pyroblast)
 #pyroblast,if=buff.hot_streak.react&(prev_gcd.1.fireball|firestarter.active|action.pyroblast.in_flight)
 if buffpresent(hot_streak_buff) and { previousgcdspell(fireball) or talent(firestarter_talent) and target.healthpercent() >= 90 or inflighttotarget(pyroblast) } spell(pyroblast)
 #phoenix_flames,if=charges>=3&active_enemies>2&!variable.phoenix_pooling
 if charges(phoenix_flames) >= 3 and enemies() > 2 and not undefined() spell(phoenix_flames)
 #pyroblast,if=buff.hot_streak.react&target.health.pct<=30&talent.searing_touch.enabled
 if buffpresent(hot_streak_buff) and target.healthpercent() <= 30 and hastalent(searing_touch_talent) spell(pyroblast)
 #pyroblast,if=buff.pyroclasm.react&cast_time<buff.pyroclasm.remains
 if buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) spell(pyroblast)
 #fire_blast,use_off_gcd=1,use_while_casting=1,if=((cooldown.combustion.remains>0|variable.disable_combustion)&buff.rune_of_power.down&!firestarter.active)&!talent.kindling.enabled&!variable.fire_blast_pooling&(((action.fireball.executing|action.pyroblast.executing)&(buff.heating_up.react))|(talent.searing_touch.enabled&target.health.pct<=30&(buff.heating_up.react&!action.scorch.executing|!buff.hot_streak.react&!buff.heating_up.react&action.scorch.executing&!action.pyroblast.in_flight&!action.fireball.in_flight)))
 if { spellcooldown(combustion) > 0 or undefined() } and buffexpires(rune_of_power_buff) and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not hastalent(kindling_talent) and not undefined() and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up_buff) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up_buff) and not executetime(scorch) > 0 or not buffpresent(hot_streak_buff) and not buffpresent(heating_up_buff) and executetime(scorch) > 0 and not inflighttotarget(pyroblast) and not inflighttotarget(fireball) } } spell(fire_blast)
 #fire_blast,if=talent.kindling.enabled&buff.heating_up.react&!firestarter.active&(cooldown.combustion.remains>full_recharge_time+2+talent.kindling.enabled|variable.disable_combustion|(!talent.rune_of_power.enabled|cooldown.rune_of_power.remains>target.time_to_die&action.rune_of_power.charges<1)&cooldown.combustion.remains>target.time_to_die)
 if hastalent(kindling_talent) and buffpresent(heating_up_buff) and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > spellfullrecharge(fire_blast) + 2 + talentpoints(kindling_talent) or undefined() or { not hastalent(rune_of_power_talent) or spellcooldown(rune_of_power) > target.timetodie() and charges(rune_of_power) < 1 } and spellcooldown(combustion) > target.timetodie() } spell(fire_blast)
 #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.up&talent.searing_touch.enabled&target.health.pct<=30&((talent.flame_patch.enabled&active_enemies=1&!firestarter.active)|(active_enemies<4&!talent.flame_patch.enabled))
 if previousgcdspell(scorch) and buffpresent(heating_up_buff) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { hastalent(flame_patch_talent) and enemies() == 1 and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or enemies() < 4 and not hastalent(flame_patch_talent) } spell(pyroblast)
 #phoenix_flames,if=(buff.heating_up.react|(!buff.hot_streak.react&(action.fire_blast.charges>0|talent.searing_touch.enabled&target.health.pct<=30)))&!variable.phoenix_pooling
 if { buffpresent(heating_up_buff) or not buffpresent(hot_streak_buff) and { charges(fire_blast) > 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } } and not undefined() spell(phoenix_flames)
 #call_action_list,name=active_talents
 FireActivetalentsMainActions()

 unless FireActivetalentsMainPostConditions()
 {
  #call_action_list,name=items_low_priority
  FireItemslowpriorityMainActions()

  unless FireItemslowpriorityMainPostConditions()
  {
   #scorch,if=target.health.pct<=30&talent.searing_touch.enabled
   if target.healthpercent() <= 30 and hastalent(searing_touch_talent) spell(scorch)
   #fire_blast,use_off_gcd=1,use_while_casting=1,if=(talent.flame_patch.enabled&active_enemies>2|active_enemies>9)&((cooldown.combustion.remains>0|variable.disable_combustion)&!firestarter.active)&buff.hot_streak.down&(!azerite.blaster_master.enabled|buff.blaster_master.remains<0.5)
   if { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 9 } and { spellcooldown(combustion) > 0 or undefined() } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and buffexpires(hot_streak_buff) and { not hasazeritetrait(blaster_master_trait) or buffremaining(blaster_master_buff) < 0.5 } spell(fire_blast)
   #flamestrike,if=talent.flame_patch.enabled&active_enemies>2|active_enemies>9
   if hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 9 spell(flamestrike)
   #fireball
   spell(fireball)
   #scorch
   spell(scorch)
  }
 }
}

AddFunction FireStandardrotationMainPostConditions
{
 FireActivetalentsMainPostConditions() or FireItemslowpriorityMainPostConditions()
}

AddFunction FireStandardrotationShortCdActions
{
 unless { hastalent(flame_patch_talent) and enemies() > 1 and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or enemies() > 4 } and buffpresent(hot_streak_buff) and spell(flamestrike) or buffpresent(hot_streak_buff) and buffremaining(hot_streak_buff) < executetime(fireball) and spell(pyroblast) or buffpresent(hot_streak_buff) and { previousgcdspell(fireball) or talent(firestarter_talent) and target.healthpercent() >= 90 or inflighttotarget(pyroblast) } and spell(pyroblast) or charges(phoenix_flames) >= 3 and enemies() > 2 and not undefined() and spell(phoenix_flames) or buffpresent(hot_streak_buff) and target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(pyroblast) or buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and spell(pyroblast) or { spellcooldown(combustion) > 0 or undefined() } and buffexpires(rune_of_power_buff) and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not hastalent(kindling_talent) and not undefined() and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up_buff) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up_buff) and not executetime(scorch) > 0 or not buffpresent(hot_streak_buff) and not buffpresent(heating_up_buff) and executetime(scorch) > 0 and not inflighttotarget(pyroblast) and not inflighttotarget(fireball) } } and spell(fire_blast) or hastalent(kindling_talent) and buffpresent(heating_up_buff) and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > spellfullrecharge(fire_blast) + 2 + talentpoints(kindling_talent) or undefined() or { not hastalent(rune_of_power_talent) or spellcooldown(rune_of_power) > target.timetodie() and charges(rune_of_power) < 1 } and spellcooldown(combustion) > target.timetodie() } and spell(fire_blast) or previousgcdspell(scorch) and buffpresent(heating_up_buff) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { hastalent(flame_patch_talent) and enemies() == 1 and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or enemies() < 4 and not hastalent(flame_patch_talent) } and spell(pyroblast) or { buffpresent(heating_up_buff) or not buffpresent(hot_streak_buff) and { charges(fire_blast) > 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } } and not undefined() and spell(phoenix_flames)
 {
  #call_action_list,name=active_talents
  FireActivetalentsShortCdActions()

  unless FireActivetalentsShortCdPostConditions()
  {
   #dragons_breath,if=active_enemies>1
   if enemies() > 1 and target.distance(less 12) spell(dragons_breath)
   #call_action_list,name=items_low_priority
   FireItemslowpriorityShortCdActions()
  }
 }
}

AddFunction FireStandardrotationShortCdPostConditions
{
 { hastalent(flame_patch_talent) and enemies() > 1 and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or enemies() > 4 } and buffpresent(hot_streak_buff) and spell(flamestrike) or buffpresent(hot_streak_buff) and buffremaining(hot_streak_buff) < executetime(fireball) and spell(pyroblast) or buffpresent(hot_streak_buff) and { previousgcdspell(fireball) or talent(firestarter_talent) and target.healthpercent() >= 90 or inflighttotarget(pyroblast) } and spell(pyroblast) or charges(phoenix_flames) >= 3 and enemies() > 2 and not undefined() and spell(phoenix_flames) or buffpresent(hot_streak_buff) and target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(pyroblast) or buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and spell(pyroblast) or { spellcooldown(combustion) > 0 or undefined() } and buffexpires(rune_of_power_buff) and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not hastalent(kindling_talent) and not undefined() and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up_buff) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up_buff) and not executetime(scorch) > 0 or not buffpresent(hot_streak_buff) and not buffpresent(heating_up_buff) and executetime(scorch) > 0 and not inflighttotarget(pyroblast) and not inflighttotarget(fireball) } } and spell(fire_blast) or hastalent(kindling_talent) and buffpresent(heating_up_buff) and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > spellfullrecharge(fire_blast) + 2 + talentpoints(kindling_talent) or undefined() or { not hastalent(rune_of_power_talent) or spellcooldown(rune_of_power) > target.timetodie() and charges(rune_of_power) < 1 } and spellcooldown(combustion) > target.timetodie() } and spell(fire_blast) or previousgcdspell(scorch) and buffpresent(heating_up_buff) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { hastalent(flame_patch_talent) and enemies() == 1 and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or enemies() < 4 and not hastalent(flame_patch_talent) } and spell(pyroblast) or { buffpresent(heating_up_buff) or not buffpresent(hot_streak_buff) and { charges(fire_blast) > 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } } and not undefined() and spell(phoenix_flames) or FireActivetalentsShortCdPostConditions() or FireItemslowpriorityShortCdPostConditions() or target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(scorch) or { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 9 } and { spellcooldown(combustion) > 0 or undefined() } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and buffexpires(hot_streak_buff) and { not hasazeritetrait(blaster_master_trait) or buffremaining(blaster_master_buff) < 0.5 } and spell(fire_blast) or { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 9 } and spell(flamestrike) or spell(fireball) or spell(scorch)
}

AddFunction FireStandardrotationCdActions
{
 unless { hastalent(flame_patch_talent) and enemies() > 1 and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or enemies() > 4 } and buffpresent(hot_streak_buff) and spell(flamestrike) or buffpresent(hot_streak_buff) and buffremaining(hot_streak_buff) < executetime(fireball) and spell(pyroblast) or buffpresent(hot_streak_buff) and { previousgcdspell(fireball) or talent(firestarter_talent) and target.healthpercent() >= 90 or inflighttotarget(pyroblast) } and spell(pyroblast) or charges(phoenix_flames) >= 3 and enemies() > 2 and not undefined() and spell(phoenix_flames) or buffpresent(hot_streak_buff) and target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(pyroblast) or buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and spell(pyroblast) or { spellcooldown(combustion) > 0 or undefined() } and buffexpires(rune_of_power_buff) and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not hastalent(kindling_talent) and not undefined() and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up_buff) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up_buff) and not executetime(scorch) > 0 or not buffpresent(hot_streak_buff) and not buffpresent(heating_up_buff) and executetime(scorch) > 0 and not inflighttotarget(pyroblast) and not inflighttotarget(fireball) } } and spell(fire_blast) or hastalent(kindling_talent) and buffpresent(heating_up_buff) and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > spellfullrecharge(fire_blast) + 2 + talentpoints(kindling_talent) or undefined() or { not hastalent(rune_of_power_talent) or spellcooldown(rune_of_power) > target.timetodie() and charges(rune_of_power) < 1 } and spellcooldown(combustion) > target.timetodie() } and spell(fire_blast) or previousgcdspell(scorch) and buffpresent(heating_up_buff) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { hastalent(flame_patch_talent) and enemies() == 1 and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or enemies() < 4 and not hastalent(flame_patch_talent) } and spell(pyroblast) or { buffpresent(heating_up_buff) or not buffpresent(hot_streak_buff) and { charges(fire_blast) > 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } } and not undefined() and spell(phoenix_flames)
 {
  #call_action_list,name=active_talents
  FireActivetalentsCdActions()

  unless FireActivetalentsCdPostConditions() or enemies() > 1 and target.distance(less 12) and spell(dragons_breath)
  {
   #call_action_list,name=items_low_priority
   FireItemslowpriorityCdActions()
  }
 }
}

AddFunction FireStandardrotationCdPostConditions
{
 { hastalent(flame_patch_talent) and enemies() > 1 and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or enemies() > 4 } and buffpresent(hot_streak_buff) and spell(flamestrike) or buffpresent(hot_streak_buff) and buffremaining(hot_streak_buff) < executetime(fireball) and spell(pyroblast) or buffpresent(hot_streak_buff) and { previousgcdspell(fireball) or talent(firestarter_talent) and target.healthpercent() >= 90 or inflighttotarget(pyroblast) } and spell(pyroblast) or charges(phoenix_flames) >= 3 and enemies() > 2 and not undefined() and spell(phoenix_flames) or buffpresent(hot_streak_buff) and target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(pyroblast) or buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and spell(pyroblast) or { spellcooldown(combustion) > 0 or undefined() } and buffexpires(rune_of_power_buff) and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and not hastalent(kindling_talent) and not undefined() and { { executetime(fireball) > 0 or executetime(pyroblast) > 0 } and buffpresent(heating_up_buff) or hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up_buff) and not executetime(scorch) > 0 or not buffpresent(hot_streak_buff) and not buffpresent(heating_up_buff) and executetime(scorch) > 0 and not inflighttotarget(pyroblast) and not inflighttotarget(fireball) } } and spell(fire_blast) or hastalent(kindling_talent) and buffpresent(heating_up_buff) and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > spellfullrecharge(fire_blast) + 2 + talentpoints(kindling_talent) or undefined() or { not hastalent(rune_of_power_talent) or spellcooldown(rune_of_power) > target.timetodie() and charges(rune_of_power) < 1 } and spellcooldown(combustion) > target.timetodie() } and spell(fire_blast) or previousgcdspell(scorch) and buffpresent(heating_up_buff) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { hastalent(flame_patch_talent) and enemies() == 1 and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or enemies() < 4 and not hastalent(flame_patch_talent) } and spell(pyroblast) or { buffpresent(heating_up_buff) or not buffpresent(hot_streak_buff) and { charges(fire_blast) > 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } } and not undefined() and spell(phoenix_flames) or FireActivetalentsCdPostConditions() or enemies() > 1 and target.distance(less 12) and spell(dragons_breath) or FireItemslowpriorityCdPostConditions() or target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(scorch) or { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 9 } and { spellcooldown(combustion) > 0 or undefined() } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and buffexpires(hot_streak_buff) and { not hasazeritetrait(blaster_master_trait) or buffremaining(blaster_master_buff) < 0.5 } and spell(fire_blast) or { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 9 } and spell(flamestrike) or spell(fireball) or spell(scorch)
}

### actions.rop_phase

AddFunction FireRopphaseMainActions
{
 #flamestrike,if=(talent.flame_patch.enabled&active_enemies>1|active_enemies>4)&buff.hot_streak.react
 if { hastalent(flame_patch_talent) and enemies() > 1 or enemies() > 4 } and buffpresent(hot_streak_buff) spell(flamestrike)
 #pyroblast,if=buff.hot_streak.react
 if buffpresent(hot_streak_buff) spell(pyroblast)
 #fire_blast,use_off_gcd=1,use_while_casting=1,if=!(talent.flame_patch.enabled&active_enemies>2|active_enemies>5)&(!firestarter.active&(cooldown.combustion.remains>0|variable.disable_combustion))&(!buff.heating_up.react&!buff.hot_streak.react&!prev_off_gcd.fire_blast&(action.fire_blast.charges>=2|(action.phoenix_flames.charges>=1&talent.phoenix_flames.enabled)|(talent.alexstraszas_fury.enabled&cooldown.dragons_breath.ready)|(talent.searing_touch.enabled&target.health.pct<=30)))
 if not { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > 0 or undefined() } and not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) and not previousoffgcdspell(fire_blast) and { charges(fire_blast) >= 2 or charges(phoenix_flames) >= 1 and hastalent(phoenix_flames_talent) or hastalent(alexstraszas_fury_talent) and spellcooldown(dragons_breath) == 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } spell(fire_blast)
 #call_action_list,name=active_talents
 FireActivetalentsMainActions()

 unless FireActivetalentsMainPostConditions()
 {
  #pyroblast,if=buff.pyroclasm.react&cast_time<buff.pyroclasm.remains&buff.rune_of_power.remains>cast_time
  if buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and totemremaining(rune_of_power) > casttime(pyroblast) spell(pyroblast)
  #fire_blast,use_off_gcd=1,use_while_casting=1,if=!(talent.flame_patch.enabled&active_enemies>2|active_enemies>5)&(!firestarter.active&(cooldown.combustion.remains>0|variable.disable_combustion))&(buff.heating_up.react&(target.health.pct>=30|!talent.searing_touch.enabled))
  if not { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > 0 or undefined() } and buffpresent(heating_up_buff) and { target.healthpercent() >= 30 or not hastalent(searing_touch_talent) } spell(fire_blast)
  #fire_blast,use_off_gcd=1,use_while_casting=1,if=!(talent.flame_patch.enabled&active_enemies>2|active_enemies>5)&(!firestarter.active&(cooldown.combustion.remains>0|variable.disable_combustion))&talent.searing_touch.enabled&target.health.pct<=30&(buff.heating_up.react&!action.scorch.executing|!buff.heating_up.react&!buff.hot_streak.react)
  if not { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > 0 or undefined() } and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up_buff) and not executetime(scorch) > 0 or not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) } spell(fire_blast)
  #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.up&talent.searing_touch.enabled&target.health.pct<=30&(!talent.flame_patch.enabled|active_enemies=1)
  if previousgcdspell(scorch) and buffpresent(heating_up_buff) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { not hastalent(flame_patch_talent) or enemies() == 1 } spell(pyroblast)
  #phoenix_flames,if=!prev_gcd.1.phoenix_flames&buff.heating_up.react
  if not previousgcdspell(phoenix_flames) and buffpresent(heating_up_buff) spell(phoenix_flames)
  #scorch,if=target.health.pct<=30&talent.searing_touch.enabled
  if target.healthpercent() <= 30 and hastalent(searing_touch_talent) spell(scorch)
  #fire_blast,use_off_gcd=1,use_while_casting=1,if=(talent.flame_patch.enabled&active_enemies>2|active_enemies>5)&((cooldown.combustion.remains>0|variable.disable_combustion)&!firestarter.active)&buff.hot_streak.down&(!azerite.blaster_master.enabled|buff.blaster_master.remains<0.5)
  if { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and { spellcooldown(combustion) > 0 or undefined() } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and buffexpires(hot_streak_buff) and { not hasazeritetrait(blaster_master_trait) or buffremaining(blaster_master_buff) < 0.5 } spell(fire_blast)
  #flamestrike,if=talent.flame_patch.enabled&active_enemies>2|active_enemies>5
  if hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 spell(flamestrike)
  #fireball
  spell(fireball)
 }
}

AddFunction FireRopphaseMainPostConditions
{
 FireActivetalentsMainPostConditions()
}

AddFunction FireRopphaseShortCdActions
{
 #rune_of_power
 spell(rune_of_power)

 unless { hastalent(flame_patch_talent) and enemies() > 1 or enemies() > 4 } and buffpresent(hot_streak_buff) and spell(flamestrike) or buffpresent(hot_streak_buff) and spell(pyroblast) or not { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > 0 or undefined() } and not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) and not previousoffgcdspell(fire_blast) and { charges(fire_blast) >= 2 or charges(phoenix_flames) >= 1 and hastalent(phoenix_flames_talent) or hastalent(alexstraszas_fury_talent) and spellcooldown(dragons_breath) == 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } and spell(fire_blast)
 {
  #call_action_list,name=active_talents
  FireActivetalentsShortCdActions()

  unless FireActivetalentsShortCdPostConditions() or buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and totemremaining(rune_of_power) > casttime(pyroblast) and spell(pyroblast) or not { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > 0 or undefined() } and buffpresent(heating_up_buff) and { target.healthpercent() >= 30 or not hastalent(searing_touch_talent) } and spell(fire_blast) or not { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > 0 or undefined() } and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up_buff) and not executetime(scorch) > 0 or not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) } and spell(fire_blast) or previousgcdspell(scorch) and buffpresent(heating_up_buff) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { not hastalent(flame_patch_talent) or enemies() == 1 } and spell(pyroblast) or not previousgcdspell(phoenix_flames) and buffpresent(heating_up_buff) and spell(phoenix_flames) or target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(scorch)
  {
   #dragons_breath,if=active_enemies>2
   if enemies() > 2 and target.distance(less 12) spell(dragons_breath)
  }
 }
}

AddFunction FireRopphaseShortCdPostConditions
{
 { hastalent(flame_patch_talent) and enemies() > 1 or enemies() > 4 } and buffpresent(hot_streak_buff) and spell(flamestrike) or buffpresent(hot_streak_buff) and spell(pyroblast) or not { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > 0 or undefined() } and not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) and not previousoffgcdspell(fire_blast) and { charges(fire_blast) >= 2 or charges(phoenix_flames) >= 1 and hastalent(phoenix_flames_talent) or hastalent(alexstraszas_fury_talent) and spellcooldown(dragons_breath) == 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } and spell(fire_blast) or FireActivetalentsShortCdPostConditions() or buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and totemremaining(rune_of_power) > casttime(pyroblast) and spell(pyroblast) or not { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > 0 or undefined() } and buffpresent(heating_up_buff) and { target.healthpercent() >= 30 or not hastalent(searing_touch_talent) } and spell(fire_blast) or not { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > 0 or undefined() } and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up_buff) and not executetime(scorch) > 0 or not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) } and spell(fire_blast) or previousgcdspell(scorch) and buffpresent(heating_up_buff) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { not hastalent(flame_patch_talent) or enemies() == 1 } and spell(pyroblast) or not previousgcdspell(phoenix_flames) and buffpresent(heating_up_buff) and spell(phoenix_flames) or target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(scorch) or { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and { spellcooldown(combustion) > 0 or undefined() } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and buffexpires(hot_streak_buff) and { not hasazeritetrait(blaster_master_trait) or buffremaining(blaster_master_buff) < 0.5 } and spell(fire_blast) or { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and spell(flamestrike) or spell(fireball)
}

AddFunction FireRopphaseCdActions
{
 unless spell(rune_of_power) or { hastalent(flame_patch_talent) and enemies() > 1 or enemies() > 4 } and buffpresent(hot_streak_buff) and spell(flamestrike) or buffpresent(hot_streak_buff) and spell(pyroblast) or not { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > 0 or undefined() } and not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) and not previousoffgcdspell(fire_blast) and { charges(fire_blast) >= 2 or charges(phoenix_flames) >= 1 and hastalent(phoenix_flames_talent) or hastalent(alexstraszas_fury_talent) and spellcooldown(dragons_breath) == 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } and spell(fire_blast)
 {
  #call_action_list,name=active_talents
  FireActivetalentsCdActions()
 }
}

AddFunction FireRopphaseCdPostConditions
{
 spell(rune_of_power) or { hastalent(flame_patch_talent) and enemies() > 1 or enemies() > 4 } and buffpresent(hot_streak_buff) and spell(flamestrike) or buffpresent(hot_streak_buff) and spell(pyroblast) or not { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > 0 or undefined() } and not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) and not previousoffgcdspell(fire_blast) and { charges(fire_blast) >= 2 or charges(phoenix_flames) >= 1 and hastalent(phoenix_flames_talent) or hastalent(alexstraszas_fury_talent) and spellcooldown(dragons_breath) == 0 or hastalent(searing_touch_talent) and target.healthpercent() <= 30 } and spell(fire_blast) or FireActivetalentsCdPostConditions() or buffpresent(pyroclasm) and casttime(pyroblast) < buffremaining(pyroclasm) and totemremaining(rune_of_power) > casttime(pyroblast) and spell(pyroblast) or not { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > 0 or undefined() } and buffpresent(heating_up_buff) and { target.healthpercent() >= 30 or not hastalent(searing_touch_talent) } and spell(fire_blast) or not { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and { spellcooldown(combustion) > 0 or undefined() } and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { buffpresent(heating_up_buff) and not executetime(scorch) > 0 or not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) } and spell(fire_blast) or previousgcdspell(scorch) and buffpresent(heating_up_buff) and hastalent(searing_touch_talent) and target.healthpercent() <= 30 and { not hastalent(flame_patch_talent) or enemies() == 1 } and spell(pyroblast) or not previousgcdspell(phoenix_flames) and buffpresent(heating_up_buff) and spell(phoenix_flames) or target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(scorch) or enemies() > 2 and target.distance(less 12) and spell(dragons_breath) or { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and { spellcooldown(combustion) > 0 or undefined() } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } and buffexpires(hot_streak_buff) and { not hasazeritetrait(blaster_master_trait) or buffremaining(blaster_master_buff) < 0.5 } and spell(fire_blast) or { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 5 } and spell(flamestrike) or spell(fireball)
}

### actions.precombat

AddFunction FirePrecombatMainActions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 spell(arcane_intellect)
 #pyroblast
 spell(pyroblast)
}

AddFunction FirePrecombatMainPostConditions
{
}

AddFunction FirePrecombatShortCdActions
{
}

AddFunction FirePrecombatShortCdPostConditions
{
 spell(arcane_intellect) or spell(pyroblast)
}

AddFunction FirePrecombatCdActions
{
 unless spell(arcane_intellect)
 {
  #variable,name=disable_combustion,op=reset
  #variable,name=combustion_rop_cutoff,op=set,value=60
  #variable,name=combustion_on_use,op=set,value=equipped.gladiators_badge|equipped.gladiators_medallion|equipped.ignition_mages_fuse|equipped.tzanes_barkspines|equipped.azurethos_singed_plumage|equipped.ancient_knot_of_wisdom|equipped.shockbiters_fang|equipped.neural_synapse_enhancer|equipped.balefire_branch
  #variable,name=font_double_on_use,op=set,value=equipped.azsharas_font_of_power&variable.combustion_on_use
  #variable,name=on_use_cutoff,op=set,value=20*variable.combustion_on_use&!variable.font_double_on_use+40*variable.font_double_on_use+25*equipped.azsharas_font_of_power&!variable.font_double_on_use
  #snapshot_stats
  #use_item,name=azsharas_font_of_power
  fireuseitemactions()
  #mirror_image
  spell(mirror_image)
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 }
}

AddFunction FirePrecombatCdPostConditions
{
 spell(arcane_intellect) or spell(pyroblast)
}

### actions.items_low_priority

AddFunction FireItemslowpriorityMainActions
{
}

AddFunction FireItemslowpriorityMainPostConditions
{
}

AddFunction FireItemslowpriorityShortCdActions
{
}

AddFunction FireItemslowpriorityShortCdPostConditions
{
}

AddFunction FireItemslowpriorityCdActions
{
 #use_item,name=tidestorm_codex,if=cooldown.combustion.remains>variable.on_use_cutoff|variable.disable_combustion|talent.firestarter.enabled&firestarter.remains>variable.on_use_cutoff
 if spellcooldown(combustion) > undefined() or undefined() or hastalent(firestarter_talent) and target.timetohealthpercent(90) > undefined() fireuseitemactions()
 #use_item,effect_name=cyclotronic_blast,if=cooldown.combustion.remains>variable.on_use_cutoff|variable.disable_combustion|talent.firestarter.enabled&firestarter.remains>variable.on_use_cutoff
 if spellcooldown(combustion) > undefined() or undefined() or hastalent(firestarter_talent) and target.timetohealthpercent(90) > undefined() fireuseitemactions()
}

AddFunction FireItemslowpriorityCdPostConditions
{
}

### actions.items_high_priority

AddFunction FireItemshighpriorityMainActions
{
 #call_action_list,name=items_combustion,if=!variable.disable_combustion&(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
 if not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) FireItemscombustionMainActions()
}

AddFunction FireItemshighpriorityMainPostConditions
{
 { not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) } and FireItemscombustionMainPostConditions()
}

AddFunction FireItemshighpriorityShortCdActions
{
 #call_action_list,name=items_combustion,if=!variable.disable_combustion&(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
 if not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) FireItemscombustionShortCdActions()
}

AddFunction FireItemshighpriorityShortCdPostConditions
{
 { not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) } and FireItemscombustionShortCdPostConditions()
}

AddFunction FireItemshighpriorityCdActions
{
 #call_action_list,name=items_combustion,if=!variable.disable_combustion&(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
 if not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) FireItemscombustionCdActions()

 unless { not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) } and FireItemscombustionCdPostConditions()
 {
  #use_items
  fireuseitemactions()
  #use_item,name=azsharas_font_of_power,if=cooldown.combustion.remains<=5+15*variable.font_double_on_use&!variable.disable_combustion
  if spellcooldown(combustion) <= 5 + 15 * undefined() and not undefined() fireuseitemactions()
  #use_item,name=rotcrusted_voodoo_doll,if=cooldown.combustion.remains>variable.on_use_cutoff|variable.disable_combustion
  if spellcooldown(combustion) > undefined() or undefined() fireuseitemactions()
  #use_item,name=aquipotent_nautilus,if=cooldown.combustion.remains>variable.on_use_cutoff|variable.disable_combustion
  if spellcooldown(combustion) > undefined() or undefined() fireuseitemactions()
  #use_item,name=shiver_venom_relic,if=cooldown.combustion.remains>variable.on_use_cutoff|variable.disable_combustion
  if spellcooldown(combustion) > undefined() or undefined() fireuseitemactions()
  #use_item,effect_name=harmonic_dematerializer
  fireuseitemactions()
  #use_item,name=malformed_heralds_legwraps,if=cooldown.combustion.remains>=55&buff.combustion.down&cooldown.combustion.remains>variable.on_use_cutoff|variable.disable_combustion
  if spellcooldown(combustion) >= 55 and buffexpires(combustion_buff) and spellcooldown(combustion) > undefined() or undefined() fireuseitemactions()
  #use_item,name=ancient_knot_of_wisdom,if=cooldown.combustion.remains>=55&buff.combustion.down&cooldown.combustion.remains>variable.on_use_cutoff|variable.disable_combustion
  if spellcooldown(combustion) >= 55 and buffexpires(combustion_buff) and spellcooldown(combustion) > undefined() or undefined() fireuseitemactions()
  #use_item,name=neural_synapse_enhancer,if=cooldown.combustion.remains>=45&buff.combustion.down&cooldown.combustion.remains>variable.on_use_cutoff|variable.disable_combustion
  if spellcooldown(combustion) >= 45 and buffexpires(combustion_buff) and spellcooldown(combustion) > undefined() or undefined() fireuseitemactions()
 }
}

AddFunction FireItemshighpriorityCdPostConditions
{
 { not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) } and FireItemscombustionCdPostConditions()
}

### actions.items_combustion

AddFunction FireItemscombustionMainActions
{
}

AddFunction FireItemscombustionMainPostConditions
{
}

AddFunction FireItemscombustionShortCdActions
{
}

AddFunction FireItemscombustionShortCdPostConditions
{
}

AddFunction FireItemscombustionCdActions
{
 #use_item,name=ignition_mages_fuse
 fireuseitemactions()
 #use_item,name=hyperthread_wristwraps,if=buff.combustion.up&action.fire_blast.charges=0&action.fire_blast.recharge_time>gcd.max
 if buffpresent(combustion_buff) and charges(fire_blast) == 0 and spellchargecooldown(fire_blast) > gcd() fireuseitemactions()
 #use_item,use_off_gcd=1,name=azurethos_singed_plumage,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if buffpresent(combustion_buff) or inflighttotarget(meteor) and 0 <= 0.5 fireuseitemactions()
 #use_item,use_off_gcd=1,effect_name=gladiators_badge,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if buffpresent(combustion_buff) or inflighttotarget(meteor) and 0 <= 0.5 fireuseitemactions()
 #use_item,use_off_gcd=1,effect_name=gladiators_medallion,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if buffpresent(combustion_buff) or inflighttotarget(meteor) and 0 <= 0.5 fireuseitemactions()
 #use_item,use_off_gcd=1,name=balefire_branch,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if buffpresent(combustion_buff) or inflighttotarget(meteor) and 0 <= 0.5 fireuseitemactions()
 #use_item,use_off_gcd=1,name=shockbiters_fang,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if buffpresent(combustion_buff) or inflighttotarget(meteor) and 0 <= 0.5 fireuseitemactions()
 #use_item,use_off_gcd=1,name=tzanes_barkspines,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if buffpresent(combustion_buff) or inflighttotarget(meteor) and 0 <= 0.5 fireuseitemactions()
 #use_item,use_off_gcd=1,name=ancient_knot_of_wisdom,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if buffpresent(combustion_buff) or inflighttotarget(meteor) and 0 <= 0.5 fireuseitemactions()
 #use_item,use_off_gcd=1,name=neural_synapse_enhancer,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if buffpresent(combustion_buff) or inflighttotarget(meteor) and 0 <= 0.5 fireuseitemactions()
 #use_item,use_off_gcd=1,name=malformed_heralds_legwraps,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if buffpresent(combustion_buff) or inflighttotarget(meteor) and 0 <= 0.5 fireuseitemactions()
}

AddFunction FireItemscombustionCdPostConditions
{
}

### actions.combustion_phase

AddFunction FireCombustionphaseMainActions
{
 #fire_blast,use_while_casting=1,use_off_gcd=1,if=charges>=1&((action.fire_blast.charges_fractional+(buff.combustion.remains-buff.blaster_master.duration)%cooldown.fire_blast.duration-(buff.combustion.remains)%(buff.blaster_master.duration-0.5))>=0|!azerite.blaster_master.enabled|!talent.flame_on.enabled|buff.combustion.remains<=buff.blaster_master.duration|buff.blaster_master.remains<0.5|equipped.hyperthread_wristwraps&cooldown.hyperthread_wristwraps_300142.remains<5)&buff.combustion.up&(!action.scorch.executing&!action.pyroblast.in_flight&buff.heating_up.up|action.scorch.executing&buff.hot_streak.down&(buff.heating_up.down|azerite.blaster_master.enabled)|azerite.blaster_master.enabled&talent.flame_on.enabled&action.pyroblast.in_flight&buff.heating_up.down&buff.hot_streak.down)
 if charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { buffremaining(combustion_buff) - baseduration(blaster_master_buff) } / spellcooldownduration(fire_blast) - buffremaining(combustion_buff) / { baseduration(blaster_master_buff) - 0.5 } >= 0 or not hasazeritetrait(blaster_master_trait) or not hastalent(flame_on_talent) or buffremaining(combustion_buff) <= baseduration(blaster_master_buff) or buffremaining(blaster_master_buff) < 0.5 or hasequippeditem(hyperthread_wristwraps_item) and spellcooldown(hyperthread_wristwraps_300142) < 5 } and buffpresent(combustion_buff) and { not executetime(scorch) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up_buff) or executetime(scorch) > 0 and buffexpires(hot_streak_buff) and { buffexpires(heating_up_buff) or hasazeritetrait(blaster_master_trait) } or hasazeritetrait(blaster_master_trait) and hastalent(flame_on_talent) and inflighttotarget(pyroblast) and buffexpires(heating_up_buff) and buffexpires(hot_streak_buff) } spell(fire_blast)
 #fire_blast,use_while_casting=1,if=azerite.blaster_master.enabled&essence.memory_of_lucid_dreams.major&talent.meteor.enabled&talent.flame_on.enabled&buff.blaster_master.down&(talent.rune_of_power.enabled&action.rune_of_power.executing&action.rune_of_power.execute_remains<0.6|(cooldown.combustion.ready|buff.combustion.up)&!talent.rune_of_power.enabled&!action.pyroblast.in_flight&!action.fireball.in_flight)
 if hasazeritetrait(blaster_master_trait) and azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and hastalent(meteor_talent) and hastalent(flame_on_talent) and buffexpires(blaster_master_buff) and { hastalent(rune_of_power_talent) and executetime(rune_of_power) > 0 and executetime(rune_of_power) < 0.6 or { spellcooldown(combustion) == 0 or buffpresent(combustion_buff) } and not hastalent(rune_of_power_talent) and not inflighttotarget(pyroblast) and not inflighttotarget(fireball) } spell(fire_blast)
 #call_action_list,name=active_talents
 FireActivetalentsMainActions()

 unless FireActivetalentsMainPostConditions()
 {
  #flamestrike,if=((talent.flame_patch.enabled&active_enemies>2)|active_enemies>6)&buff.hot_streak.react&!azerite.blaster_master.enabled
  if { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 6 } and buffpresent(hot_streak_buff) and not hasazeritetrait(blaster_master_trait) spell(flamestrike)
  #pyroblast,if=buff.pyroclasm.react&buff.combustion.remains>cast_time
  if buffpresent(pyroclasm) and buffremaining(combustion_buff) > casttime(pyroblast) spell(pyroblast)
  #pyroblast,if=buff.hot_streak.react
  if buffpresent(hot_streak_buff) spell(pyroblast)
  #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.up
  if previousgcdspell(scorch) and buffpresent(heating_up_buff) spell(pyroblast)
  #phoenix_flames
  spell(phoenix_flames)
  #scorch,if=buff.combustion.remains>cast_time&buff.combustion.up|buff.combustion.down
  if buffremaining(combustion_buff) > casttime(scorch) and buffpresent(combustion_buff) or buffexpires(combustion_buff) spell(scorch)
  #living_bomb,if=buff.combustion.remains<gcd.max&active_enemies>1
  if buffremaining(combustion_buff) < gcd() and enemies() > 1 spell(living_bomb)
  #scorch,if=target.health.pct<=30&talent.searing_touch.enabled
  if target.healthpercent() <= 30 and hastalent(searing_touch_talent) spell(scorch)
 }
}

AddFunction FireCombustionphaseMainPostConditions
{
 FireActivetalentsMainPostConditions()
}

AddFunction FireCombustionphaseShortCdActions
{
 unless charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { buffremaining(combustion_buff) - baseduration(blaster_master_buff) } / spellcooldownduration(fire_blast) - buffremaining(combustion_buff) / { baseduration(blaster_master_buff) - 0.5 } >= 0 or not hasazeritetrait(blaster_master_trait) or not hastalent(flame_on_talent) or buffremaining(combustion_buff) <= baseduration(blaster_master_buff) or buffremaining(blaster_master_buff) < 0.5 or hasequippeditem(hyperthread_wristwraps_item) and spellcooldown(hyperthread_wristwraps_300142) < 5 } and buffpresent(combustion_buff) and { not executetime(scorch) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up_buff) or executetime(scorch) > 0 and buffexpires(hot_streak_buff) and { buffexpires(heating_up_buff) or hasazeritetrait(blaster_master_trait) } or hasazeritetrait(blaster_master_trait) and hastalent(flame_on_talent) and inflighttotarget(pyroblast) and buffexpires(heating_up_buff) and buffexpires(hot_streak_buff) } and spell(fire_blast)
 {
  #rune_of_power,if=buff.combustion.down
  if buffexpires(combustion_buff) spell(rune_of_power)

  unless hasazeritetrait(blaster_master_trait) and azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and hastalent(meteor_talent) and hastalent(flame_on_talent) and buffexpires(blaster_master_buff) and { hastalent(rune_of_power_talent) and executetime(rune_of_power) > 0 and executetime(rune_of_power) < 0.6 or { spellcooldown(combustion) == 0 or buffpresent(combustion_buff) } and not hastalent(rune_of_power_talent) and not inflighttotarget(pyroblast) and not inflighttotarget(fireball) } and spell(fire_blast)
  {
   #call_action_list,name=active_talents
   FireActivetalentsShortCdActions()

   unless FireActivetalentsShortCdPostConditions() or { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 6 } and buffpresent(hot_streak_buff) and not hasazeritetrait(blaster_master_trait) and spell(flamestrike) or buffpresent(pyroclasm) and buffremaining(combustion_buff) > casttime(pyroblast) and spell(pyroblast) or buffpresent(hot_streak_buff) and spell(pyroblast) or previousgcdspell(scorch) and buffpresent(heating_up_buff) and spell(pyroblast) or spell(phoenix_flames) or { buffremaining(combustion_buff) > casttime(scorch) and buffpresent(combustion_buff) or buffexpires(combustion_buff) } and spell(scorch) or buffremaining(combustion_buff) < gcd() and enemies() > 1 and spell(living_bomb)
   {
    #dragons_breath,if=buff.combustion.remains<gcd.max&buff.combustion.up
    if buffremaining(combustion_buff) < gcd() and buffpresent(combustion_buff) and target.distance(less 12) spell(dragons_breath)
   }
  }
 }
}

AddFunction FireCombustionphaseShortCdPostConditions
{
 charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { buffremaining(combustion_buff) - baseduration(blaster_master_buff) } / spellcooldownduration(fire_blast) - buffremaining(combustion_buff) / { baseduration(blaster_master_buff) - 0.5 } >= 0 or not hasazeritetrait(blaster_master_trait) or not hastalent(flame_on_talent) or buffremaining(combustion_buff) <= baseduration(blaster_master_buff) or buffremaining(blaster_master_buff) < 0.5 or hasequippeditem(hyperthread_wristwraps_item) and spellcooldown(hyperthread_wristwraps_300142) < 5 } and buffpresent(combustion_buff) and { not executetime(scorch) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up_buff) or executetime(scorch) > 0 and buffexpires(hot_streak_buff) and { buffexpires(heating_up_buff) or hasazeritetrait(blaster_master_trait) } or hasazeritetrait(blaster_master_trait) and hastalent(flame_on_talent) and inflighttotarget(pyroblast) and buffexpires(heating_up_buff) and buffexpires(hot_streak_buff) } and spell(fire_blast) or hasazeritetrait(blaster_master_trait) and azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and hastalent(meteor_talent) and hastalent(flame_on_talent) and buffexpires(blaster_master_buff) and { hastalent(rune_of_power_talent) and executetime(rune_of_power) > 0 and executetime(rune_of_power) < 0.6 or { spellcooldown(combustion) == 0 or buffpresent(combustion_buff) } and not hastalent(rune_of_power_talent) and not inflighttotarget(pyroblast) and not inflighttotarget(fireball) } and spell(fire_blast) or FireActivetalentsShortCdPostConditions() or { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 6 } and buffpresent(hot_streak_buff) and not hasazeritetrait(blaster_master_trait) and spell(flamestrike) or buffpresent(pyroclasm) and buffremaining(combustion_buff) > casttime(pyroblast) and spell(pyroblast) or buffpresent(hot_streak_buff) and spell(pyroblast) or previousgcdspell(scorch) and buffpresent(heating_up_buff) and spell(pyroblast) or spell(phoenix_flames) or { buffremaining(combustion_buff) > casttime(scorch) and buffpresent(combustion_buff) or buffexpires(combustion_buff) } and spell(scorch) or buffremaining(combustion_buff) < gcd() and enemies() > 1 and spell(living_bomb) or target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(scorch)
}

AddFunction FireCombustionphaseCdActions
{
 #lights_judgment,if=buff.combustion.down
 if buffexpires(combustion_buff) spell(lights_judgment)
 #blood_of_the_enemy
 spell(blood_of_the_enemy)
 #memory_of_lucid_dreams
 spell(memory_of_lucid_dreams_essence)

 unless charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { buffremaining(combustion_buff) - baseduration(blaster_master_buff) } / spellcooldownduration(fire_blast) - buffremaining(combustion_buff) / { baseduration(blaster_master_buff) - 0.5 } >= 0 or not hasazeritetrait(blaster_master_trait) or not hastalent(flame_on_talent) or buffremaining(combustion_buff) <= baseduration(blaster_master_buff) or buffremaining(blaster_master_buff) < 0.5 or hasequippeditem(hyperthread_wristwraps_item) and spellcooldown(hyperthread_wristwraps_300142) < 5 } and buffpresent(combustion_buff) and { not executetime(scorch) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up_buff) or executetime(scorch) > 0 and buffexpires(hot_streak_buff) and { buffexpires(heating_up_buff) or hasazeritetrait(blaster_master_trait) } or hasazeritetrait(blaster_master_trait) and hastalent(flame_on_talent) and inflighttotarget(pyroblast) and buffexpires(heating_up_buff) and buffexpires(hot_streak_buff) } and spell(fire_blast) or buffexpires(combustion_buff) and spell(rune_of_power) or hasazeritetrait(blaster_master_trait) and azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and hastalent(meteor_talent) and hastalent(flame_on_talent) and buffexpires(blaster_master_buff) and { hastalent(rune_of_power_talent) and executetime(rune_of_power) > 0 and executetime(rune_of_power) < 0.6 or { spellcooldown(combustion) == 0 or buffpresent(combustion_buff) } and not hastalent(rune_of_power_talent) and not inflighttotarget(pyroblast) and not inflighttotarget(fireball) } and spell(fire_blast)
 {
  #call_action_list,name=active_talents
  FireActivetalentsCdActions()

  unless FireActivetalentsCdPostConditions()
  {
   #combustion,use_off_gcd=1,use_while_casting=1,if=((action.meteor.in_flight&action.meteor.in_flight_remains<=0.5)|!talent.meteor.enabled)&(buff.rune_of_power.up|!talent.rune_of_power.enabled)
   if { inflighttotarget(meteor) and 0 <= 0.5 or not hastalent(meteor_talent) } and { buffpresent(rune_of_power_buff) or not hastalent(rune_of_power_talent) } spell(combustion)
   #potion
   if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
   #blood_fury
   spell(blood_fury_sp)
   #berserking
   spell(berserking)
   #fireblood
   spell(fireblood)
   #ancestral_call
   spell(ancestral_call)
  }
 }
}

AddFunction FireCombustionphaseCdPostConditions
{
 charges(fire_blast) >= 1 and { charges(fire_blast count=0) + { buffremaining(combustion_buff) - baseduration(blaster_master_buff) } / spellcooldownduration(fire_blast) - buffremaining(combustion_buff) / { baseduration(blaster_master_buff) - 0.5 } >= 0 or not hasazeritetrait(blaster_master_trait) or not hastalent(flame_on_talent) or buffremaining(combustion_buff) <= baseduration(blaster_master_buff) or buffremaining(blaster_master_buff) < 0.5 or hasequippeditem(hyperthread_wristwraps_item) and spellcooldown(hyperthread_wristwraps_300142) < 5 } and buffpresent(combustion_buff) and { not executetime(scorch) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up_buff) or executetime(scorch) > 0 and buffexpires(hot_streak_buff) and { buffexpires(heating_up_buff) or hasazeritetrait(blaster_master_trait) } or hasazeritetrait(blaster_master_trait) and hastalent(flame_on_talent) and inflighttotarget(pyroblast) and buffexpires(heating_up_buff) and buffexpires(hot_streak_buff) } and spell(fire_blast) or buffexpires(combustion_buff) and spell(rune_of_power) or hasazeritetrait(blaster_master_trait) and azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and hastalent(meteor_talent) and hastalent(flame_on_talent) and buffexpires(blaster_master_buff) and { hastalent(rune_of_power_talent) and executetime(rune_of_power) > 0 and executetime(rune_of_power) < 0.6 or { spellcooldown(combustion) == 0 or buffpresent(combustion_buff) } and not hastalent(rune_of_power_talent) and not inflighttotarget(pyroblast) and not inflighttotarget(fireball) } and spell(fire_blast) or FireActivetalentsCdPostConditions() or { hastalent(flame_patch_talent) and enemies() > 2 or enemies() > 6 } and buffpresent(hot_streak_buff) and not hasazeritetrait(blaster_master_trait) and spell(flamestrike) or buffpresent(pyroclasm) and buffremaining(combustion_buff) > casttime(pyroblast) and spell(pyroblast) or buffpresent(hot_streak_buff) and spell(pyroblast) or previousgcdspell(scorch) and buffpresent(heating_up_buff) and spell(pyroblast) or spell(phoenix_flames) or { buffremaining(combustion_buff) > casttime(scorch) and buffpresent(combustion_buff) or buffexpires(combustion_buff) } and spell(scorch) or buffremaining(combustion_buff) < gcd() and enemies() > 1 and spell(living_bomb) or buffremaining(combustion_buff) < gcd() and buffpresent(combustion_buff) and target.distance(less 12) and spell(dragons_breath) or target.healthpercent() <= 30 and hastalent(searing_touch_talent) and spell(scorch)
}

### actions.active_talents

AddFunction FireActivetalentsMainActions
{
 #living_bomb,if=active_enemies>1&buff.combustion.down&(cooldown.combustion.remains>cooldown.living_bomb.duration|cooldown.combustion.ready|variable.disable_combustion)
 if enemies() > 1 and buffexpires(combustion_buff) and { spellcooldown(combustion) > spellcooldownduration(living_bomb) or spellcooldown(combustion) == 0 or undefined() } spell(living_bomb)
}

AddFunction FireActivetalentsMainPostConditions
{
}

AddFunction FireActivetalentsShortCdActions
{
 unless enemies() > 1 and buffexpires(combustion_buff) and { spellcooldown(combustion) > spellcooldownduration(living_bomb) or spellcooldown(combustion) == 0 or undefined() } and spell(living_bomb)
 {
  #meteor,if=buff.rune_of_power.up&(firestarter.remains>cooldown.meteor.duration|!firestarter.active)|cooldown.rune_of_power.remains>target.time_to_die&action.rune_of_power.charges<1|(cooldown.meteor.duration<cooldown.combustion.remains|cooldown.combustion.ready|variable.disable_combustion)&!talent.rune_of_power.enabled&(cooldown.meteor.duration<firestarter.remains|!talent.firestarter.enabled|!firestarter.active)
  if buffpresent(rune_of_power_buff) and { target.timetohealthpercent(90) > spellcooldownduration(meteor) or not { talent(firestarter_talent) and target.healthpercent() >= 90 } } or spellcooldown(rune_of_power) > target.timetodie() and charges(rune_of_power) < 1 or { spellcooldownduration(meteor) < spellcooldown(combustion) or spellcooldown(combustion) == 0 or undefined() } and not hastalent(rune_of_power_talent) and { spellcooldownduration(meteor) < target.timetohealthpercent(90) or not hastalent(firestarter_talent) or not { talent(firestarter_talent) and target.healthpercent() >= 90 } } spell(meteor)
 }
}

AddFunction FireActivetalentsShortCdPostConditions
{
 enemies() > 1 and buffexpires(combustion_buff) and { spellcooldown(combustion) > spellcooldownduration(living_bomb) or spellcooldown(combustion) == 0 or undefined() } and spell(living_bomb)
}

AddFunction FireActivetalentsCdActions
{
}

AddFunction FireActivetalentsCdPostConditions
{
 enemies() > 1 and buffexpires(combustion_buff) and { spellcooldown(combustion) > spellcooldownduration(living_bomb) or spellcooldown(combustion) == 0 or undefined() } and spell(living_bomb) or { buffpresent(rune_of_power_buff) and { target.timetohealthpercent(90) > spellcooldownduration(meteor) or not { talent(firestarter_talent) and target.healthpercent() >= 90 } } or spellcooldown(rune_of_power) > target.timetodie() and charges(rune_of_power) < 1 or { spellcooldownduration(meteor) < spellcooldown(combustion) or spellcooldown(combustion) == 0 or undefined() } and not hastalent(rune_of_power_talent) and { spellcooldownduration(meteor) < target.timetohealthpercent(90) or not hastalent(firestarter_talent) or not { talent(firestarter_talent) and target.healthpercent() >= 90 } } } and spell(meteor)
}

### actions.default

AddFunction FireDefaultMainActions
{
 #call_action_list,name=items_high_priority
 FireItemshighpriorityMainActions()

 unless FireItemshighpriorityMainPostConditions()
 {
  #concentrated_flame
  spell(concentrated_flame_essence)
  #call_action_list,name=combustion_phase,if=!variable.disable_combustion&(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
  if not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) FireCombustionphaseMainActions()

  unless { not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) } and FireCombustionphaseMainPostConditions()
  {
   #fire_blast,use_while_casting=1,use_off_gcd=1,if=(essence.memory_of_lucid_dreams.major|essence.memory_of_lucid_dreams.minor&azerite.blaster_master.enabled)&charges=max_charges&!buff.hot_streak.react&!(buff.heating_up.react&(buff.combustion.up&(action.fireball.in_flight|action.pyroblast.in_flight|action.scorch.executing)|target.health.pct<=30&action.scorch.executing))&!(!buff.heating_up.react&!buff.hot_streak.react&buff.combustion.down&(action.fireball.in_flight|action.pyroblast.in_flight))
   if { azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or azeriteessenceisminor(memory_of_lucid_dreams_essence_id) and hasazeritetrait(blaster_master_trait) } and charges(fire_blast) == spellmaxcharges(fire_blast) and not buffpresent(hot_streak_buff) and not { buffpresent(heating_up_buff) and { buffpresent(combustion_buff) and { inflighttotarget(fireball) or inflighttotarget(pyroblast) or executetime(scorch) > 0 } or target.healthpercent() <= 30 and executetime(scorch) > 0 } } and not { not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) and buffexpires(combustion_buff) and { inflighttotarget(fireball) or inflighttotarget(pyroblast) } } spell(fire_blast)
   #fire_blast,use_while_casting=1,use_off_gcd=1,if=firestarter.active&charges>=1&(!variable.fire_blast_pooling|buff.rune_of_power.up)&(!azerite.blaster_master.enabled|buff.blaster_master.remains<0.5)&(!action.fireball.executing&!action.pyroblast.in_flight&buff.heating_up.up|action.fireball.executing&buff.hot_streak.down|action.pyroblast.in_flight&buff.heating_up.down&buff.hot_streak.down)
   if talent(firestarter_talent) and target.healthpercent() >= 90 and charges(fire_blast) >= 1 and { not undefined() or buffpresent(rune_of_power_buff) } and { not hasazeritetrait(blaster_master_trait) or buffremaining(blaster_master_buff) < 0.5 } and { not executetime(fireball) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up_buff) or executetime(fireball) > 0 and buffexpires(hot_streak_buff) or inflighttotarget(pyroblast) and buffexpires(heating_up_buff) and buffexpires(hot_streak_buff) } spell(fire_blast)
   #call_action_list,name=rop_phase,if=buff.rune_of_power.up&buff.combustion.down
   if buffpresent(rune_of_power_buff) and buffexpires(combustion_buff) FireRopphaseMainActions()

   unless buffpresent(rune_of_power_buff) and buffexpires(combustion_buff) and FireRopphaseMainPostConditions()
   {
    #variable,name=fire_blast_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.fire_blast.full_recharge_time&(cooldown.combustion.remains>variable.combustion_rop_cutoff|variable.disable_combustion|firestarter.active)&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|!variable.disable_combustion&cooldown.combustion.remains<action.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled&!firestarter.active&cooldown.combustion.remains<target.time_to_die|talent.firestarter.enabled&firestarter.active&firestarter.remains<cooldown.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled
    #variable,name=phoenix_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.phoenix_flames.full_recharge_time&(cooldown.combustion.remains>variable.combustion_rop_cutoff|variable.disable_combustion)&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|!variable.disable_combustion&cooldown.combustion.remains<action.phoenix_flames.full_recharge_time&cooldown.combustion.remains<target.time_to_die
    #call_action_list,name=standard_rotation
    FireStandardrotationMainActions()
   }
  }
 }
}

AddFunction FireDefaultMainPostConditions
{
 FireItemshighpriorityMainPostConditions() or { not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) } and FireCombustionphaseMainPostConditions() or buffpresent(rune_of_power_buff) and buffexpires(combustion_buff) and FireRopphaseMainPostConditions() or FireStandardrotationMainPostConditions()
}

AddFunction FireDefaultShortCdActions
{
 #call_action_list,name=items_high_priority
 FireItemshighpriorityShortCdActions()

 unless FireItemshighpriorityShortCdPostConditions() or spell(concentrated_flame_essence)
 {
  #purifying_blast
  spell(purifying_blast)
  #ripple_in_space
  spell(ripple_in_space_essence)
  #the_unbound_force
  spell(the_unbound_force)
  #worldvein_resonance
  spell(worldvein_resonance_essence)
  #rune_of_power,if=talent.firestarter.enabled&firestarter.remains>full_recharge_time|cooldown.combustion.remains>variable.combustion_rop_cutoff&buff.combustion.down|target.time_to_die<cooldown.combustion.remains&buff.combustion.down|variable.disable_combustion
  if hastalent(firestarter_talent) and target.timetohealthpercent(90) > spellfullrecharge(rune_of_power) or spellcooldown(combustion) > undefined() and buffexpires(combustion_buff) or target.timetodie() < spellcooldown(combustion) and buffexpires(combustion_buff) or undefined() spell(rune_of_power)
  #call_action_list,name=combustion_phase,if=!variable.disable_combustion&(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
  if not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) FireCombustionphaseShortCdActions()

  unless { not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) } and FireCombustionphaseShortCdPostConditions() or { azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or azeriteessenceisminor(memory_of_lucid_dreams_essence_id) and hasazeritetrait(blaster_master_trait) } and charges(fire_blast) == spellmaxcharges(fire_blast) and not buffpresent(hot_streak_buff) and not { buffpresent(heating_up_buff) and { buffpresent(combustion_buff) and { inflighttotarget(fireball) or inflighttotarget(pyroblast) or executetime(scorch) > 0 } or target.healthpercent() <= 30 and executetime(scorch) > 0 } } and not { not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) and buffexpires(combustion_buff) and { inflighttotarget(fireball) or inflighttotarget(pyroblast) } } and spell(fire_blast) or talent(firestarter_talent) and target.healthpercent() >= 90 and charges(fire_blast) >= 1 and { not undefined() or buffpresent(rune_of_power_buff) } and { not hasazeritetrait(blaster_master_trait) or buffremaining(blaster_master_buff) < 0.5 } and { not executetime(fireball) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up_buff) or executetime(fireball) > 0 and buffexpires(hot_streak_buff) or inflighttotarget(pyroblast) and buffexpires(heating_up_buff) and buffexpires(hot_streak_buff) } and spell(fire_blast)
  {
   #call_action_list,name=rop_phase,if=buff.rune_of_power.up&buff.combustion.down
   if buffpresent(rune_of_power_buff) and buffexpires(combustion_buff) FireRopphaseShortCdActions()

   unless buffpresent(rune_of_power_buff) and buffexpires(combustion_buff) and FireRopphaseShortCdPostConditions()
   {
    #variable,name=fire_blast_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.fire_blast.full_recharge_time&(cooldown.combustion.remains>variable.combustion_rop_cutoff|variable.disable_combustion|firestarter.active)&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|!variable.disable_combustion&cooldown.combustion.remains<action.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled&!firestarter.active&cooldown.combustion.remains<target.time_to_die|talent.firestarter.enabled&firestarter.active&firestarter.remains<cooldown.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled
    #variable,name=phoenix_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.phoenix_flames.full_recharge_time&(cooldown.combustion.remains>variable.combustion_rop_cutoff|variable.disable_combustion)&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|!variable.disable_combustion&cooldown.combustion.remains<action.phoenix_flames.full_recharge_time&cooldown.combustion.remains<target.time_to_die
    #call_action_list,name=standard_rotation
    FireStandardrotationShortCdActions()
   }
  }
 }
}

AddFunction FireDefaultShortCdPostConditions
{
 FireItemshighpriorityShortCdPostConditions() or spell(concentrated_flame_essence) or { not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) } and FireCombustionphaseShortCdPostConditions() or { azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or azeriteessenceisminor(memory_of_lucid_dreams_essence_id) and hasazeritetrait(blaster_master_trait) } and charges(fire_blast) == spellmaxcharges(fire_blast) and not buffpresent(hot_streak_buff) and not { buffpresent(heating_up_buff) and { buffpresent(combustion_buff) and { inflighttotarget(fireball) or inflighttotarget(pyroblast) or executetime(scorch) > 0 } or target.healthpercent() <= 30 and executetime(scorch) > 0 } } and not { not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) and buffexpires(combustion_buff) and { inflighttotarget(fireball) or inflighttotarget(pyroblast) } } and spell(fire_blast) or talent(firestarter_talent) and target.healthpercent() >= 90 and charges(fire_blast) >= 1 and { not undefined() or buffpresent(rune_of_power_buff) } and { not hasazeritetrait(blaster_master_trait) or buffremaining(blaster_master_buff) < 0.5 } and { not executetime(fireball) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up_buff) or executetime(fireball) > 0 and buffexpires(hot_streak_buff) or inflighttotarget(pyroblast) and buffexpires(heating_up_buff) and buffexpires(hot_streak_buff) } and spell(fire_blast) or buffpresent(rune_of_power_buff) and buffexpires(combustion_buff) and FireRopphaseShortCdPostConditions() or FireStandardrotationShortCdPostConditions()
}

AddFunction FireDefaultCdActions
{
 #counterspell
 fireinterruptactions()
 #call_action_list,name=items_high_priority
 FireItemshighpriorityCdActions()

 unless FireItemshighpriorityCdPostConditions()
 {
  #mirror_image,if=buff.combustion.down
  if buffexpires(combustion_buff) spell(mirror_image)
  #guardian_of_azeroth,if=cooldown.combustion.remains<10|target.time_to_die<cooldown.combustion.remains
  if spellcooldown(combustion) < 10 or target.timetodie() < spellcooldown(combustion) spell(guardian_of_azeroth)

  unless spell(concentrated_flame_essence)
  {
   #focused_azerite_beam
   spell(focused_azerite_beam)

   unless spell(purifying_blast) or spell(ripple_in_space_essence) or spell(the_unbound_force) or spell(worldvein_resonance_essence) or { hastalent(firestarter_talent) and target.timetohealthpercent(90) > spellfullrecharge(rune_of_power) or spellcooldown(combustion) > undefined() and buffexpires(combustion_buff) or target.timetodie() < spellcooldown(combustion) and buffexpires(combustion_buff) or undefined() } and spell(rune_of_power)
   {
    #call_action_list,name=combustion_phase,if=!variable.disable_combustion&(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
    if not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) FireCombustionphaseCdActions()

    unless { not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) } and FireCombustionphaseCdPostConditions() or { azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or azeriteessenceisminor(memory_of_lucid_dreams_essence_id) and hasazeritetrait(blaster_master_trait) } and charges(fire_blast) == spellmaxcharges(fire_blast) and not buffpresent(hot_streak_buff) and not { buffpresent(heating_up_buff) and { buffpresent(combustion_buff) and { inflighttotarget(fireball) or inflighttotarget(pyroblast) or executetime(scorch) > 0 } or target.healthpercent() <= 30 and executetime(scorch) > 0 } } and not { not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) and buffexpires(combustion_buff) and { inflighttotarget(fireball) or inflighttotarget(pyroblast) } } and spell(fire_blast) or talent(firestarter_talent) and target.healthpercent() >= 90 and charges(fire_blast) >= 1 and { not undefined() or buffpresent(rune_of_power_buff) } and { not hasazeritetrait(blaster_master_trait) or buffremaining(blaster_master_buff) < 0.5 } and { not executetime(fireball) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up_buff) or executetime(fireball) > 0 and buffexpires(hot_streak_buff) or inflighttotarget(pyroblast) and buffexpires(heating_up_buff) and buffexpires(hot_streak_buff) } and spell(fire_blast)
    {
     #call_action_list,name=rop_phase,if=buff.rune_of_power.up&buff.combustion.down
     if buffpresent(rune_of_power_buff) and buffexpires(combustion_buff) FireRopphaseCdActions()

     unless buffpresent(rune_of_power_buff) and buffexpires(combustion_buff) and FireRopphaseCdPostConditions()
     {
      #variable,name=fire_blast_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.fire_blast.full_recharge_time&(cooldown.combustion.remains>variable.combustion_rop_cutoff|variable.disable_combustion|firestarter.active)&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|!variable.disable_combustion&cooldown.combustion.remains<action.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled&!firestarter.active&cooldown.combustion.remains<target.time_to_die|talent.firestarter.enabled&firestarter.active&firestarter.remains<cooldown.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled
      #variable,name=phoenix_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.phoenix_flames.full_recharge_time&(cooldown.combustion.remains>variable.combustion_rop_cutoff|variable.disable_combustion)&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|!variable.disable_combustion&cooldown.combustion.remains<action.phoenix_flames.full_recharge_time&cooldown.combustion.remains<target.time_to_die
      #call_action_list,name=standard_rotation
      FireStandardrotationCdActions()
     }
    }
   }
  }
 }
}

AddFunction FireDefaultCdPostConditions
{
 FireItemshighpriorityCdPostConditions() or spell(concentrated_flame_essence) or spell(purifying_blast) or spell(ripple_in_space_essence) or spell(the_unbound_force) or spell(worldvein_resonance_essence) or { hastalent(firestarter_talent) and target.timetohealthpercent(90) > spellfullrecharge(rune_of_power) or spellcooldown(combustion) > undefined() and buffexpires(combustion_buff) or target.timetodie() < spellcooldown(combustion) and buffexpires(combustion_buff) or undefined() } and spell(rune_of_power) or { not undefined() and { hastalent(rune_of_power_talent) and spellcooldown(combustion) <= casttime(rune_of_power) or spellcooldown(combustion) == 0 } and not { talent(firestarter_talent) and target.healthpercent() >= 90 } or buffpresent(combustion_buff) } and FireCombustionphaseCdPostConditions() or { azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or azeriteessenceisminor(memory_of_lucid_dreams_essence_id) and hasazeritetrait(blaster_master_trait) } and charges(fire_blast) == spellmaxcharges(fire_blast) and not buffpresent(hot_streak_buff) and not { buffpresent(heating_up_buff) and { buffpresent(combustion_buff) and { inflighttotarget(fireball) or inflighttotarget(pyroblast) or executetime(scorch) > 0 } or target.healthpercent() <= 30 and executetime(scorch) > 0 } } and not { not buffpresent(heating_up_buff) and not buffpresent(hot_streak_buff) and buffexpires(combustion_buff) and { inflighttotarget(fireball) or inflighttotarget(pyroblast) } } and spell(fire_blast) or talent(firestarter_talent) and target.healthpercent() >= 90 and charges(fire_blast) >= 1 and { not undefined() or buffpresent(rune_of_power_buff) } and { not hasazeritetrait(blaster_master_trait) or buffremaining(blaster_master_buff) < 0.5 } and { not executetime(fireball) > 0 and not inflighttotarget(pyroblast) and buffpresent(heating_up_buff) or executetime(fireball) > 0 and buffexpires(hot_streak_buff) or inflighttotarget(pyroblast) and buffexpires(heating_up_buff) and buffexpires(hot_streak_buff) } and spell(fire_blast) or buffpresent(rune_of_power_buff) and buffexpires(combustion_buff) and FireRopphaseCdPostConditions() or FireStandardrotationCdPostConditions()
}

### Fire icons.

AddCheckBox(opt_mage_fire_aoe l(AOE) default specialization=fire)

AddIcon checkbox=!opt_mage_fire_aoe enemies=1 help=shortcd specialization=fire
{
 if not incombat() fireprecombatshortcdactions()
 unless not incombat() and fireprecombatshortcdpostconditions()
 {
  firedefaultshortcdactions()
 }
}

AddIcon checkbox=opt_mage_fire_aoe help=shortcd specialization=fire
{
 if not incombat() fireprecombatshortcdactions()
 unless not incombat() and fireprecombatshortcdpostconditions()
 {
  firedefaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=fire
{
 if not incombat() fireprecombatmainactions()
 unless not incombat() and fireprecombatmainpostconditions()
 {
  firedefaultmainactions()
 }
}

AddIcon checkbox=opt_mage_fire_aoe help=aoe specialization=fire
{
 if not incombat() fireprecombatmainactions()
 unless not incombat() and fireprecombatmainpostconditions()
 {
  firedefaultmainactions()
 }
}

AddIcon checkbox=!opt_mage_fire_aoe enemies=1 help=cd specialization=fire
{
 if not incombat() fireprecombatcdactions()
 unless not incombat() and fireprecombatcdpostconditions()
 {
  firedefaultcdactions()
 }
}

AddIcon checkbox=opt_mage_fire_aoe help=cd specialization=fire
{
 if not incombat() fireprecombatcdactions()
 unless not incombat() and fireprecombatcdpostconditions()
 {
  firedefaultcdactions()
 }
}

### Required symbols
# alexstraszas_fury_talent
# ancestral_call
# ancient_knot_of_wisdom_item
# arcane_intellect
# azsharas_font_of_power_item
# azurethos_singed_plumage_item
# balefire_branch_item
# berserking
# blaster_master_buff
# blaster_master_trait
# blood_fury_sp
# blood_of_the_enemy
# combustion
# combustion_buff
# concentrated_flame_essence
# counterspell
# dragons_breath
# fire_blast
# fireball
# fireblood
# firestarter_talent
# flame_on_talent
# flame_patch_talent
# flamestrike
# focused_azerite_beam
# gladiators_badge
# gladiators_medallion_item
# guardian_of_azeroth
# heating_up_buff
# hot_streak_buff
# hyperthread_wristwraps_300142
# hyperthread_wristwraps_item
# ignition_mages_fuse_item
# kindling_talent
# lights_judgment
# living_bomb
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_id
# meteor
# meteor_talent
# mirror_image
# neural_synapse_enhancer_item
# phoenix_flames
# phoenix_flames_talent
# purifying_blast
# pyroblast
# pyroclasm
# quaking_palm
# ripple_in_space_essence
# rune_of_power
# rune_of_power_buff
# rune_of_power_talent
# scorch
# searing_touch_talent
# shockbiters_fang_item
# the_unbound_force
# tzanes_barkspines_item
# unbridled_fury_item
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("MAGE", "fire", name, desc, code, "script")
    end
    do
        local name = "sc_t23_mage_frost"
        local desc = "[8.2] Simulationcraft: T23_Mage_Frost"
        local code = [[
# Based on SimulationCraft profile "T23_Mage_Frost".
#	class=mage
#	spec=frost
#	talents=1013033

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=frost)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=frost)
AddCheckBox(opt_blink spellname(blink) specialization=frost)

AddFunction FrostInterruptActions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(counterspell) and target.isinterruptible() spell(counterspell)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
 }
}

AddFunction FrostUseItemActions
{
 item(Trinket0Slot text=13 usable=1)
 item(Trinket1Slot text=14 usable=1)
}

### actions.talent_rop

AddFunction FrostTalentropMainActions
{
}

AddFunction FrostTalentropMainPostConditions
{
}

AddFunction FrostTalentropShortCdActions
{
 #rune_of_power,if=talent.glacial_spike.enabled&buff.icicles.stack=5&(buff.brain_freeze.react|talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time)
 if hastalent(glacial_spike_talent) and buffstacks(icicles_buff) == 5 and { buffpresent(brain_freeze_buff) or hastalent(ebonbolt_talent) and spellcooldown(ebonbolt) < casttime(rune_of_power) } spell(rune_of_power)
 #rune_of_power,if=!talent.glacial_spike.enabled&(talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time|talent.comet_storm.enabled&cooldown.comet_storm.remains<cast_time|talent.ray_of_frost.enabled&cooldown.ray_of_frost.remains<cast_time|charges_fractional>1.9)
 if not hastalent(glacial_spike_talent) and { hastalent(ebonbolt_talent) and spellcooldown(ebonbolt) < casttime(rune_of_power) or hastalent(comet_storm_talent) and spellcooldown(comet_storm) < casttime(rune_of_power) or hastalent(ray_of_frost_talent) and spellcooldown(ray_of_frost) < casttime(rune_of_power) or charges(rune_of_power count=0) > 1.9 } spell(rune_of_power)
}

AddFunction FrostTalentropShortCdPostConditions
{
}

AddFunction FrostTalentropCdActions
{
}

AddFunction FrostTalentropCdPostConditions
{
 hastalent(glacial_spike_talent) and buffstacks(icicles_buff) == 5 and { buffpresent(brain_freeze_buff) or hastalent(ebonbolt_talent) and spellcooldown(ebonbolt) < casttime(rune_of_power) } and spell(rune_of_power) or not hastalent(glacial_spike_talent) and { hastalent(ebonbolt_talent) and spellcooldown(ebonbolt) < casttime(rune_of_power) or hastalent(comet_storm_talent) and spellcooldown(comet_storm) < casttime(rune_of_power) or hastalent(ray_of_frost_talent) and spellcooldown(ray_of_frost) < casttime(rune_of_power) or charges(rune_of_power count=0) > 1.9 } and spell(rune_of_power)
}

### actions.single

AddFunction FrostSingleMainActions
{
 #ice_nova,if=cooldown.ice_nova.ready&debuff.winters_chill.up
 if spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) spell(ice_nova)
 #flurry,if=talent.ebonbolt.enabled&prev_gcd.1.ebonbolt&(!talent.glacial_spike.enabled|buff.icicles.stack<4|buff.brain_freeze.react)
 if hastalent(ebonbolt_talent) and previousgcdspell(ebonbolt) and { not hastalent(glacial_spike_talent) or buffstacks(icicles_buff) < 4 or buffpresent(brain_freeze_buff) } spell(flurry)
 #flurry,if=talent.glacial_spike.enabled&prev_gcd.1.glacial_spike&buff.brain_freeze.react
 if hastalent(glacial_spike_talent) and previousgcdspell(glacial_spike) and buffpresent(brain_freeze_buff) spell(flurry)
 #flurry,if=prev_gcd.1.frostbolt&buff.brain_freeze.react&(!talent.glacial_spike.enabled|buff.icicles.stack<4)
 if previousgcdspell(frostbolt) and buffpresent(brain_freeze_buff) and { not hastalent(glacial_spike_talent) or buffstacks(icicles_buff) < 4 } spell(flurry)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #blizzard,if=active_enemies>2|active_enemies>1&cast_time=0&buff.fingers_of_frost.react<2
  if enemies() > 2 or enemies() > 1 and casttime(blizzard) == 0 and buffstacks(fingers_of_frost_buff) < 2 spell(blizzard)
  #ice_lance,if=buff.fingers_of_frost.react
  if buffpresent(fingers_of_frost_buff) spell(ice_lance)
  #ebonbolt
  spell(ebonbolt)
  #ray_of_frost,if=!action.frozen_orb.in_flight&ground_aoe.frozen_orb.remains=0
  if not timesincepreviousspell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 spell(ray_of_frost)
  #blizzard,if=cast_time=0|active_enemies>1
  if casttime(blizzard) == 0 or enemies() > 1 spell(blizzard)
  #glacial_spike,if=buff.brain_freeze.react|prev_gcd.1.ebonbolt|active_enemies>1&talent.splitting_ice.enabled
  if buffpresent(brain_freeze_buff) or previousgcdspell(ebonbolt) or enemies() > 1 and hastalent(splitting_ice_talent) spell(glacial_spike)
  #ice_nova
  spell(ice_nova)
  #frostbolt
  spell(frostbolt)
  #call_action_list,name=movement
  FrostMovementMainActions()

  unless FrostMovementMainPostConditions()
  {
   #ice_lance
   spell(ice_lance)
  }
 }
}

AddFunction FrostSingleMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostSingleShortCdActions
{
 unless spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and spell(ice_nova) or hastalent(ebonbolt_talent) and previousgcdspell(ebonbolt) and { not hastalent(glacial_spike_talent) or buffstacks(icicles_buff) < 4 or buffpresent(brain_freeze_buff) } and spell(flurry) or hastalent(glacial_spike_talent) and previousgcdspell(glacial_spike) and buffpresent(brain_freeze_buff) and spell(flurry) or previousgcdspell(frostbolt) and buffpresent(brain_freeze_buff) and { not hastalent(glacial_spike_talent) or buffstacks(icicles_buff) < 4 } and spell(flurry)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #frozen_orb
   spell(frozen_orb)

   unless { enemies() > 2 or enemies() > 1 and casttime(blizzard) == 0 and buffstacks(fingers_of_frost_buff) < 2 } and spell(blizzard) or buffpresent(fingers_of_frost_buff) and spell(ice_lance)
   {
    #comet_storm
    spell(comet_storm)

    unless spell(ebonbolt) or not timesincepreviousspell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 and spell(ray_of_frost) or { casttime(blizzard) == 0 or enemies() > 1 } and spell(blizzard) or { buffpresent(brain_freeze_buff) or previousgcdspell(ebonbolt) or enemies() > 1 and hastalent(splitting_ice_talent) } and spell(glacial_spike) or spell(ice_nova) or spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostSingleShortCdPostConditions
{
 spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and spell(ice_nova) or hastalent(ebonbolt_talent) and previousgcdspell(ebonbolt) and { not hastalent(glacial_spike_talent) or buffstacks(icicles_buff) < 4 or buffpresent(brain_freeze_buff) } and spell(flurry) or hastalent(glacial_spike_talent) and previousgcdspell(glacial_spike) and buffpresent(brain_freeze_buff) and spell(flurry) or previousgcdspell(frostbolt) and buffpresent(brain_freeze_buff) and { not hastalent(glacial_spike_talent) or buffstacks(icicles_buff) < 4 } and spell(flurry) or FrostEssencesShortCdPostConditions() or { enemies() > 2 or enemies() > 1 and casttime(blizzard) == 0 and buffstacks(fingers_of_frost_buff) < 2 } and spell(blizzard) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(ebonbolt) or not timesincepreviousspell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 and spell(ray_of_frost) or { casttime(blizzard) == 0 or enemies() > 1 } and spell(blizzard) or { buffpresent(brain_freeze_buff) or previousgcdspell(ebonbolt) or enemies() > 1 and hastalent(splitting_ice_talent) } and spell(glacial_spike) or spell(ice_nova) or spell(frostbolt) or FrostMovementShortCdPostConditions() or spell(ice_lance)
}

AddFunction FrostSingleCdActions
{
 unless spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and spell(ice_nova) or hastalent(ebonbolt_talent) and previousgcdspell(ebonbolt) and { not hastalent(glacial_spike_talent) or buffstacks(icicles_buff) < 4 or buffpresent(brain_freeze_buff) } and spell(flurry) or hastalent(glacial_spike_talent) and previousgcdspell(glacial_spike) and buffpresent(brain_freeze_buff) and spell(flurry) or previousgcdspell(frostbolt) and buffpresent(brain_freeze_buff) and { not hastalent(glacial_spike_talent) or buffstacks(icicles_buff) < 4 } and spell(flurry)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or spell(frozen_orb) or { enemies() > 2 or enemies() > 1 and casttime(blizzard) == 0 and buffstacks(fingers_of_frost_buff) < 2 } and spell(blizzard) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(comet_storm) or spell(ebonbolt) or not timesincepreviousspell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 and spell(ray_of_frost) or { casttime(blizzard) == 0 or enemies() > 1 } and spell(blizzard) or { buffpresent(brain_freeze_buff) or previousgcdspell(ebonbolt) or enemies() > 1 and hastalent(splitting_ice_talent) } and spell(glacial_spike) or spell(ice_nova)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if buffexpires(icy_veins_buff) and buffexpires(rune_of_power_buff) frostuseitemactions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if buffexpires(icy_veins_buff) and buffexpires(rune_of_power_buff) frostuseitemactions()

   unless spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostSingleCdPostConditions
{
 spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and spell(ice_nova) or hastalent(ebonbolt_talent) and previousgcdspell(ebonbolt) and { not hastalent(glacial_spike_talent) or buffstacks(icicles_buff) < 4 or buffpresent(brain_freeze_buff) } and spell(flurry) or hastalent(glacial_spike_talent) and previousgcdspell(glacial_spike) and buffpresent(brain_freeze_buff) and spell(flurry) or previousgcdspell(frostbolt) and buffpresent(brain_freeze_buff) and { not hastalent(glacial_spike_talent) or buffstacks(icicles_buff) < 4 } and spell(flurry) or FrostEssencesCdPostConditions() or spell(frozen_orb) or { enemies() > 2 or enemies() > 1 and casttime(blizzard) == 0 and buffstacks(fingers_of_frost_buff) < 2 } and spell(blizzard) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(comet_storm) or spell(ebonbolt) or not timesincepreviousspell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 and spell(ray_of_frost) or { casttime(blizzard) == 0 or enemies() > 1 } and spell(blizzard) or { buffpresent(brain_freeze_buff) or previousgcdspell(ebonbolt) or enemies() > 1 and hastalent(splitting_ice_talent) } and spell(glacial_spike) or spell(ice_nova) or spell(frostbolt) or FrostMovementCdPostConditions() or spell(ice_lance)
}

### actions.precombat

AddFunction FrostPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 spell(arcane_intellect)
 #frostbolt
 spell(frostbolt)
}

AddFunction FrostPrecombatMainPostConditions
{
}

AddFunction FrostPrecombatShortCdActions
{
 unless spell(arcane_intellect)
 {
  #summon_water_elemental
  if not pet.present() spell(summon_water_elemental)
 }
}

AddFunction FrostPrecombatShortCdPostConditions
{
 spell(arcane_intellect) or spell(frostbolt)
}

AddFunction FrostPrecombatCdActions
{
 unless spell(arcane_intellect) or not pet.present() and spell(summon_water_elemental)
 {
  #snapshot_stats
  #use_item,name=azsharas_font_of_power
  frostuseitemactions()
  #mirror_image
  spell(mirror_image)
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 }
}

AddFunction FrostPrecombatCdPostConditions
{
 spell(arcane_intellect) or not pet.present() and spell(summon_water_elemental) or spell(frostbolt)
}

### actions.movement

AddFunction FrostMovementMainActions
{
}

AddFunction FrostMovementMainPostConditions
{
}

AddFunction FrostMovementShortCdActions
{
 #blink_any,if=movement.distance>10
 if target.distance() > 10 and checkboxon(opt_blink) spell(blink)
 #ice_floes,if=buff.ice_floes.down
 if buffexpires(ice_floes_buff) and speed() > 0 spell(ice_floes)
}

AddFunction FrostMovementShortCdPostConditions
{
}

AddFunction FrostMovementCdActions
{
}

AddFunction FrostMovementCdPostConditions
{
 target.distance() > 10 and checkboxon(opt_blink) and spell(blink) or buffexpires(ice_floes_buff) and speed() > 0 and spell(ice_floes)
}

### actions.essences

AddFunction FrostEssencesMainActions
{
 #concentrated_flame,line_cd=6,if=buff.rune_of_power.down
 if timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) spell(concentrated_flame_essence)
}

AddFunction FrostEssencesMainPostConditions
{
}

AddFunction FrostEssencesShortCdActions
{
 #purifying_blast,if=buff.rune_of_power.down|active_enemies>3
 if buffexpires(rune_of_power_buff) or enemies() > 3 spell(purifying_blast)
 #ripple_in_space,if=buff.rune_of_power.down|active_enemies>3
 if buffexpires(rune_of_power_buff) or enemies() > 3 spell(ripple_in_space_essence)

 unless timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and spell(concentrated_flame_essence)
 {
  #the_unbound_force,if=buff.reckless_force.up
  if buffpresent(reckless_force_buff) spell(the_unbound_force)
  #worldvein_resonance,if=buff.rune_of_power.down|active_enemies>3
  if buffexpires(rune_of_power_buff) or enemies() > 3 spell(worldvein_resonance_essence)
 }
}

AddFunction FrostEssencesShortCdPostConditions
{
 timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and spell(concentrated_flame_essence)
}

AddFunction FrostEssencesCdActions
{
 #focused_azerite_beam,if=buff.rune_of_power.down|active_enemies>3
 if buffexpires(rune_of_power_buff) or enemies() > 3 spell(focused_azerite_beam)
 #memory_of_lucid_dreams,if=active_enemies<5&(buff.icicles.stack<=1|!talent.glacial_spike.enabled)&cooldown.frozen_orb.remains>10&!action.frozen_orb.in_flight&ground_aoe.frozen_orb.remains=0
 if enemies() < 5 and { buffstacks(icicles_buff) <= 1 or not hastalent(glacial_spike_talent) } and spellcooldown(frozen_orb) > 10 and not timesincepreviousspell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 spell(memory_of_lucid_dreams_essence)
 #blood_of_the_enemy,if=(talent.glacial_spike.enabled&buff.icicles.stack=5&(buff.brain_freeze.react|prev_gcd.1.ebonbolt))|((active_enemies>3|!talent.glacial_spike.enabled)&(prev_gcd.1.frozen_orb|ground_aoe.frozen_orb.remains>5))
 if hastalent(glacial_spike_talent) and buffstacks(icicles_buff) == 5 and { buffpresent(brain_freeze_buff) or previousgcdspell(ebonbolt) } or { enemies() > 3 or not hastalent(glacial_spike_talent) } and { previousgcdspell(frozen_orb) or target.DebuffRemaining(frozen_orb_debuff) > 5 } spell(blood_of_the_enemy)
}

AddFunction FrostEssencesCdPostConditions
{
 { buffexpires(rune_of_power_buff) or enemies() > 3 } and spell(purifying_blast) or { buffexpires(rune_of_power_buff) or enemies() > 3 } and spell(ripple_in_space_essence) or timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and spell(concentrated_flame_essence) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or { buffexpires(rune_of_power_buff) or enemies() > 3 } and spell(worldvein_resonance_essence)
}

### actions.cooldowns

AddFunction FrostCooldownsMainActions
{
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) FrostTalentropMainActions()
}

AddFunction FrostCooldownsMainPostConditions
{
 hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) and FrostTalentropMainPostConditions()
}

AddFunction FrostCooldownsShortCdActions
{
 #rune_of_power,if=prev_gcd.1.frozen_orb|target.time_to_die>10+cast_time&target.time_to_die<20
 if previousgcdspell(frozen_orb) or target.timetodie() > 10 + casttime(rune_of_power) and target.timetodie() < 20 spell(rune_of_power)
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) FrostTalentropShortCdActions()
}

AddFunction FrostCooldownsShortCdPostConditions
{
 hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) and FrostTalentropShortCdPostConditions()
}

AddFunction FrostCooldownsCdActions
{
 #guardian_of_azeroth
 spell(guardian_of_azeroth)
 #icy_veins
 spell(icy_veins)
 #mirror_image
 spell(mirror_image)

 unless { previousgcdspell(frozen_orb) or target.timetodie() > 10 + casttime(rune_of_power) and target.timetodie() < 20 } and spell(rune_of_power)
 {
  #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
  if hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) FrostTalentropCdActions()

  unless hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) and FrostTalentropCdPostConditions()
  {
   #potion,if=prev_gcd.1.icy_veins|target.time_to_die<30
   if { previousgcdspell(icy_veins) or target.timetodie() < 30 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
   #use_item,name=balefire_branch,if=!talent.glacial_spike.enabled|buff.brain_freeze.react&prev_gcd.1.glacial_spike
   if not hastalent(glacial_spike_talent) or buffpresent(brain_freeze_buff) and previousgcdspell(glacial_spike) frostuseitemactions()
   #use_items
   frostuseitemactions()
   #blood_fury
   spell(blood_fury_sp)
   #berserking
   spell(berserking)
   #lights_judgment
   spell(lights_judgment)
   #fireblood
   spell(fireblood)
   #ancestral_call
   spell(ancestral_call)
  }
 }
}

AddFunction FrostCooldownsCdPostConditions
{
 { previousgcdspell(frozen_orb) or target.timetodie() > 10 + casttime(rune_of_power) and target.timetodie() < 20 } and spell(rune_of_power) or hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) and FrostTalentropCdPostConditions()
}

### actions.aoe

AddFunction FrostAoeMainActions
{
 #blizzard
 spell(blizzard)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #ice_nova
  spell(ice_nova)
  #flurry,if=prev_gcd.1.ebonbolt|buff.brain_freeze.react&(prev_gcd.1.frostbolt&(buff.icicles.stack<4|!talent.glacial_spike.enabled)|prev_gcd.1.glacial_spike)
  if previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } spell(flurry)
  #ice_lance,if=buff.fingers_of_frost.react
  if buffpresent(fingers_of_frost_buff) spell(ice_lance)
  #ray_of_frost
  spell(ray_of_frost)
  #ebonbolt
  spell(ebonbolt)
  #glacial_spike
  spell(glacial_spike)
  #frostbolt
  spell(frostbolt)
  #call_action_list,name=movement
  FrostMovementMainActions()

  unless FrostMovementMainPostConditions()
  {
   #ice_lance
   spell(ice_lance)
  }
 }
}

AddFunction FrostAoeMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostAoeShortCdActions
{
 #frozen_orb
 spell(frozen_orb)

 unless spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #comet_storm
   spell(comet_storm)

   unless spell(ice_nova) or { previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } } and spell(flurry) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(ray_of_frost) or spell(ebonbolt) or spell(glacial_spike)
   {
    #cone_of_cold
    if target.distance() < 12 spell(cone_of_cold)

    unless spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostAoeShortCdPostConditions
{
 spell(blizzard) or FrostEssencesShortCdPostConditions() or spell(ice_nova) or { previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } } and spell(flurry) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(ray_of_frost) or spell(ebonbolt) or spell(glacial_spike) or spell(frostbolt) or FrostMovementShortCdPostConditions() or spell(ice_lance)
}

AddFunction FrostAoeCdActions
{
 unless spell(frozen_orb) or spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or spell(comet_storm) or spell(ice_nova) or { previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } } and spell(flurry) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(ray_of_frost) or spell(ebonbolt) or spell(glacial_spike) or target.distance() < 12 and spell(cone_of_cold)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if buffexpires(icy_veins_buff) and buffexpires(rune_of_power_buff) frostuseitemactions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if buffexpires(icy_veins_buff) and buffexpires(rune_of_power_buff) frostuseitemactions()

   unless spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostAoeCdPostConditions
{
 spell(frozen_orb) or spell(blizzard) or FrostEssencesCdPostConditions() or spell(comet_storm) or spell(ice_nova) or { previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } } and spell(flurry) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(ray_of_frost) or spell(ebonbolt) or spell(glacial_spike) or target.distance() < 12 and spell(cone_of_cold) or spell(frostbolt) or FrostMovementCdPostConditions() or spell(ice_lance)
}

### actions.default

AddFunction FrostDefaultMainActions
{
 #ice_lance,if=prev_gcd.1.flurry&!buff.fingers_of_frost.react
 if previousgcdspell(flurry) and not buffpresent(fingers_of_frost_buff) spell(ice_lance)
 #call_action_list,name=cooldowns
 FrostCooldownsMainActions()

 unless FrostCooldownsMainPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
  if enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 FrostAoeMainActions()

  unless { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeMainPostConditions()
  {
   #call_action_list,name=single
   FrostSingleMainActions()
  }
 }
}

AddFunction FrostDefaultMainPostConditions
{
 FrostCooldownsMainPostConditions() or { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeMainPostConditions() or FrostSingleMainPostConditions()
}

AddFunction FrostDefaultShortCdActions
{
 unless previousgcdspell(flurry) and not buffpresent(fingers_of_frost_buff) and spell(ice_lance)
 {
  #call_action_list,name=cooldowns
  FrostCooldownsShortCdActions()

  unless FrostCooldownsShortCdPostConditions()
  {
   #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
   if enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 FrostAoeShortCdActions()

   unless { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeShortCdPostConditions()
   {
    #call_action_list,name=single
    FrostSingleShortCdActions()
   }
  }
 }
}

AddFunction FrostDefaultShortCdPostConditions
{
 previousgcdspell(flurry) and not buffpresent(fingers_of_frost_buff) and spell(ice_lance) or FrostCooldownsShortCdPostConditions() or { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeShortCdPostConditions() or FrostSingleShortCdPostConditions()
}

AddFunction FrostDefaultCdActions
{
 #counterspell
 frostinterruptactions()

 unless previousgcdspell(flurry) and not buffpresent(fingers_of_frost_buff) and spell(ice_lance)
 {
  #call_action_list,name=cooldowns
  FrostCooldownsCdActions()

  unless FrostCooldownsCdPostConditions()
  {
   #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
   if enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 FrostAoeCdActions()

   unless { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeCdPostConditions()
   {
    #call_action_list,name=single
    FrostSingleCdActions()
   }
  }
 }
}

AddFunction FrostDefaultCdPostConditions
{
 previousgcdspell(flurry) and not buffpresent(fingers_of_frost_buff) and spell(ice_lance) or FrostCooldownsCdPostConditions() or { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeCdPostConditions() or FrostSingleCdPostConditions()
}

### Frost icons.

AddCheckBox(opt_mage_frost_aoe l(AOE) default specialization=frost)

AddIcon checkbox=!opt_mage_frost_aoe enemies=1 help=shortcd specialization=frost
{
 if not incombat() frostprecombatshortcdactions()
 unless not incombat() and frostprecombatshortcdpostconditions()
 {
  frostdefaultshortcdactions()
 }
}

AddIcon checkbox=opt_mage_frost_aoe help=shortcd specialization=frost
{
 if not incombat() frostprecombatshortcdactions()
 unless not incombat() and frostprecombatshortcdpostconditions()
 {
  frostdefaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=frost
{
 if not incombat() frostprecombatmainactions()
 unless not incombat() and frostprecombatmainpostconditions()
 {
  frostdefaultmainactions()
 }
}

AddIcon checkbox=opt_mage_frost_aoe help=aoe specialization=frost
{
 if not incombat() frostprecombatmainactions()
 unless not incombat() and frostprecombatmainpostconditions()
 {
  frostdefaultmainactions()
 }
}

AddIcon checkbox=!opt_mage_frost_aoe enemies=1 help=cd specialization=frost
{
 if not incombat() frostprecombatcdactions()
 unless not incombat() and frostprecombatcdpostconditions()
 {
  frostdefaultcdactions()
 }
}

AddIcon checkbox=opt_mage_frost_aoe help=cd specialization=frost
{
 if not incombat() frostprecombatcdactions()
 unless not incombat() and frostprecombatcdpostconditions()
 {
  frostdefaultcdactions()
 }
}

### Required symbols
# ancestral_call
# arcane_intellect
# berserking
# blink
# blizzard
# blood_fury_sp
# blood_of_the_enemy
# brain_freeze_buff
# comet_storm
# comet_storm_talent
# concentrated_flame_essence
# cone_of_cold
# counterspell
# ebonbolt
# ebonbolt_talent
# fingers_of_frost_buff
# fireblood
# flurry
# focused_azerite_beam
# freezing_rain_talent
# frostbolt
# frozen_orb
# frozen_orb_debuff
# glacial_spike
# glacial_spike_talent
# guardian_of_azeroth
# ice_floes
# ice_floes_buff
# ice_lance
# ice_nova
# icicles_buff
# icy_veins
# icy_veins_buff
# lights_judgment
# memory_of_lucid_dreams_essence
# mirror_image
# purifying_blast
# quaking_palm
# ray_of_frost
# ray_of_frost_talent
# reckless_force_buff
# ripple_in_space_essence
# rune_of_power
# rune_of_power_buff
# rune_of_power_talent
# splitting_ice_talent
# summon_water_elemental
# the_unbound_force
# unbridled_fury_item
# winters_chill_debuff
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("MAGE", "frost", name, desc, code, "script")
    end
    do
        local name = "sc_t23_mage_frost_frozenorb"
        local desc = "[8.2] Simulationcraft: T23_Mage_Frost_FrozenOrb"
        local code = [[
# Based on SimulationCraft profile "T23_Mage_Frost_FrozenOrb".
#	class=mage
#	spec=frost
#	talents=2032011

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=frost)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=frost)
AddCheckBox(opt_blink spellname(blink) specialization=frost)

AddFunction FrostInterruptActions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(counterspell) and target.isinterruptible() spell(counterspell)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
 }
}

AddFunction FrostUseItemActions
{
 item(Trinket0Slot text=13 usable=1)
 item(Trinket1Slot text=14 usable=1)
}

### actions.talent_rop

AddFunction FrostTalentropMainActions
{
}

AddFunction FrostTalentropMainPostConditions
{
}

AddFunction FrostTalentropShortCdActions
{
 #rune_of_power,if=talent.glacial_spike.enabled&buff.icicles.stack=5&(buff.brain_freeze.react|talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time)
 if hastalent(glacial_spike_talent) and buffstacks(icicles_buff) == 5 and { buffpresent(brain_freeze_buff) or hastalent(ebonbolt_talent) and spellcooldown(ebonbolt) < casttime(rune_of_power) } spell(rune_of_power)
 #rune_of_power,if=!talent.glacial_spike.enabled&(talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time|talent.comet_storm.enabled&cooldown.comet_storm.remains<cast_time|talent.ray_of_frost.enabled&cooldown.ray_of_frost.remains<cast_time|charges_fractional>1.9)
 if not hastalent(glacial_spike_talent) and { hastalent(ebonbolt_talent) and spellcooldown(ebonbolt) < casttime(rune_of_power) or hastalent(comet_storm_talent) and spellcooldown(comet_storm) < casttime(rune_of_power) or hastalent(ray_of_frost_talent) and spellcooldown(ray_of_frost) < casttime(rune_of_power) or charges(rune_of_power count=0) > 1.9 } spell(rune_of_power)
}

AddFunction FrostTalentropShortCdPostConditions
{
}

AddFunction FrostTalentropCdActions
{
}

AddFunction FrostTalentropCdPostConditions
{
 hastalent(glacial_spike_talent) and buffstacks(icicles_buff) == 5 and { buffpresent(brain_freeze_buff) or hastalent(ebonbolt_talent) and spellcooldown(ebonbolt) < casttime(rune_of_power) } and spell(rune_of_power) or not hastalent(glacial_spike_talent) and { hastalent(ebonbolt_talent) and spellcooldown(ebonbolt) < casttime(rune_of_power) or hastalent(comet_storm_talent) and spellcooldown(comet_storm) < casttime(rune_of_power) or hastalent(ray_of_frost_talent) and spellcooldown(ray_of_frost) < casttime(rune_of_power) or charges(rune_of_power count=0) > 1.9 } and spell(rune_of_power)
}

### actions.single

AddFunction FrostSingleMainActions
{
 #ice_nova,if=cooldown.ice_nova.ready&debuff.winters_chill.up
 if spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) spell(ice_nova)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #flurry,if=prev_gcd.1.ebonbolt&buff.brain_freeze.react
  if previousgcdspell(ebonbolt) and buffpresent(brain_freeze_buff) spell(flurry)
  #blizzard,if=active_enemies>2|active_enemies>1&cast_time=0
  if enemies() > 2 or enemies() > 1 and casttime(blizzard) == 0 spell(blizzard)
  #ice_lance,if=buff.fingers_of_frost.react&cooldown.frozen_orb.remains>5|buff.fingers_of_frost.react=2
  if buffpresent(fingers_of_frost_buff) and spellcooldown(frozen_orb) > 5 or buffstacks(fingers_of_frost_buff) == 2 spell(ice_lance)
  #blizzard,if=cast_time=0
  if casttime(blizzard) == 0 spell(blizzard)
  #flurry,if=prev_gcd.1.ebonbolt
  if previousgcdspell(ebonbolt) spell(flurry)
  #flurry,if=buff.brain_freeze.react&(prev_gcd.1.frostbolt|debuff.packed_ice.remains>execute_time+action.ice_lance.travel_time)
  if buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) or target.DebuffRemaining(packed_ice) > executetime(flurry) + traveltime(ice_lance) } spell(flurry)
  #ebonbolt
  spell(ebonbolt)
  #ray_of_frost,if=debuff.packed_ice.up,interrupt_if=buff.fingers_of_frost.react=2,interrupt_immediate=1
  if target.DebuffPresent(packed_ice) spell(ray_of_frost)
  #blizzard
  spell(blizzard)
  #ice_nova
  spell(ice_nova)
  #frostbolt
  spell(frostbolt)
  #call_action_list,name=movement
  FrostMovementMainActions()

  unless FrostMovementMainPostConditions()
  {
   #ice_lance
   spell(ice_lance)
  }
 }
}

AddFunction FrostSingleMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostSingleShortCdActions
{
 unless spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and spell(ice_nova)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #frozen_orb
   spell(frozen_orb)

   unless previousgcdspell(ebonbolt) and buffpresent(brain_freeze_buff) and spell(flurry) or { enemies() > 2 or enemies() > 1 and casttime(blizzard) == 0 } and spell(blizzard) or { buffpresent(fingers_of_frost_buff) and spellcooldown(frozen_orb) > 5 or buffstacks(fingers_of_frost_buff) == 2 } and spell(ice_lance) or casttime(blizzard) == 0 and spell(blizzard) or previousgcdspell(ebonbolt) and spell(flurry) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) or target.DebuffRemaining(packed_ice) > executetime(flurry) + traveltime(ice_lance) } and spell(flurry)
   {
    #comet_storm
    spell(comet_storm)

    unless spell(ebonbolt) or target.DebuffPresent(packed_ice) and spell(ray_of_frost) or spell(blizzard) or spell(ice_nova) or spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostSingleShortCdPostConditions
{
 spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and spell(ice_nova) or FrostEssencesShortCdPostConditions() or previousgcdspell(ebonbolt) and buffpresent(brain_freeze_buff) and spell(flurry) or { enemies() > 2 or enemies() > 1 and casttime(blizzard) == 0 } and spell(blizzard) or { buffpresent(fingers_of_frost_buff) and spellcooldown(frozen_orb) > 5 or buffstacks(fingers_of_frost_buff) == 2 } and spell(ice_lance) or casttime(blizzard) == 0 and spell(blizzard) or previousgcdspell(ebonbolt) and spell(flurry) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) or target.DebuffRemaining(packed_ice) > executetime(flurry) + traveltime(ice_lance) } and spell(flurry) or spell(ebonbolt) or target.DebuffPresent(packed_ice) and spell(ray_of_frost) or spell(blizzard) or spell(ice_nova) or spell(frostbolt) or FrostMovementShortCdPostConditions() or spell(ice_lance)
}

AddFunction FrostSingleCdActions
{
 unless spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and spell(ice_nova)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or spell(frozen_orb) or previousgcdspell(ebonbolt) and buffpresent(brain_freeze_buff) and spell(flurry) or { enemies() > 2 or enemies() > 1 and casttime(blizzard) == 0 } and spell(blizzard) or { buffpresent(fingers_of_frost_buff) and spellcooldown(frozen_orb) > 5 or buffstacks(fingers_of_frost_buff) == 2 } and spell(ice_lance) or casttime(blizzard) == 0 and spell(blizzard) or previousgcdspell(ebonbolt) and spell(flurry) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) or target.DebuffRemaining(packed_ice) > executetime(flurry) + traveltime(ice_lance) } and spell(flurry) or spell(comet_storm) or spell(ebonbolt) or target.DebuffPresent(packed_ice) and spell(ray_of_frost) or spell(blizzard) or spell(ice_nova)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if buffexpires(icy_veins_buff) and buffexpires(rune_of_power_buff) frostuseitemactions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if buffexpires(icy_veins_buff) and buffexpires(rune_of_power_buff) frostuseitemactions()

   unless spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostSingleCdPostConditions
{
 spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and spell(ice_nova) or FrostEssencesCdPostConditions() or spell(frozen_orb) or previousgcdspell(ebonbolt) and buffpresent(brain_freeze_buff) and spell(flurry) or { enemies() > 2 or enemies() > 1 and casttime(blizzard) == 0 } and spell(blizzard) or { buffpresent(fingers_of_frost_buff) and spellcooldown(frozen_orb) > 5 or buffstacks(fingers_of_frost_buff) == 2 } and spell(ice_lance) or casttime(blizzard) == 0 and spell(blizzard) or previousgcdspell(ebonbolt) and spell(flurry) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) or target.DebuffRemaining(packed_ice) > executetime(flurry) + traveltime(ice_lance) } and spell(flurry) or spell(comet_storm) or spell(ebonbolt) or target.DebuffPresent(packed_ice) and spell(ray_of_frost) or spell(blizzard) or spell(ice_nova) or spell(frostbolt) or FrostMovementCdPostConditions() or spell(ice_lance)
}

### actions.precombat

AddFunction FrostPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 spell(arcane_intellect)
 #frostbolt
 spell(frostbolt)
}

AddFunction FrostPrecombatMainPostConditions
{
}

AddFunction FrostPrecombatShortCdActions
{
 unless spell(arcane_intellect)
 {
  #summon_water_elemental
  if not pet.present() spell(summon_water_elemental)
 }
}

AddFunction FrostPrecombatShortCdPostConditions
{
 spell(arcane_intellect) or spell(frostbolt)
}

AddFunction FrostPrecombatCdActions
{
 unless spell(arcane_intellect) or not pet.present() and spell(summon_water_elemental)
 {
  #snapshot_stats
  #use_item,name=azsharas_font_of_power
  frostuseitemactions()
  #mirror_image
  spell(mirror_image)
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 }
}

AddFunction FrostPrecombatCdPostConditions
{
 spell(arcane_intellect) or not pet.present() and spell(summon_water_elemental) or spell(frostbolt)
}

### actions.movement

AddFunction FrostMovementMainActions
{
}

AddFunction FrostMovementMainPostConditions
{
}

AddFunction FrostMovementShortCdActions
{
 #blink_any,if=movement.distance>10
 if target.distance() > 10 and checkboxon(opt_blink) spell(blink)
 #ice_floes,if=buff.ice_floes.down
 if buffexpires(ice_floes_buff) and speed() > 0 spell(ice_floes)
}

AddFunction FrostMovementShortCdPostConditions
{
}

AddFunction FrostMovementCdActions
{
}

AddFunction FrostMovementCdPostConditions
{
 target.distance() > 10 and checkboxon(opt_blink) and spell(blink) or buffexpires(ice_floes_buff) and speed() > 0 and spell(ice_floes)
}

### actions.essences

AddFunction FrostEssencesMainActions
{
 #concentrated_flame,line_cd=6,if=buff.rune_of_power.down&debuff.packed_ice.down
 if timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) spell(concentrated_flame_essence)
}

AddFunction FrostEssencesMainPostConditions
{
}

AddFunction FrostEssencesShortCdActions
{
 #purifying_blast,if=buff.rune_of_power.down&debuff.packed_ice.down|active_enemies>3
 if buffexpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or enemies() > 3 spell(purifying_blast)
 #ripple_in_space,if=buff.rune_of_power.down&debuff.packed_ice.down|active_enemies>3
 if buffexpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or enemies() > 3 spell(ripple_in_space_essence)

 unless timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) and spell(concentrated_flame_essence)
 {
  #the_unbound_force,if=buff.reckless_force.up
  if buffpresent(reckless_force_buff) spell(the_unbound_force)
  #worldvein_resonance,if=buff.rune_of_power.down&debuff.packed_ice.down|active_enemies>3
  if buffexpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or enemies() > 3 spell(worldvein_resonance_essence)
 }
}

AddFunction FrostEssencesShortCdPostConditions
{
 timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) and spell(concentrated_flame_essence)
}

AddFunction FrostEssencesCdActions
{
 #focused_azerite_beam,if=buff.rune_of_power.down&debuff.packed_ice.down|active_enemies>3
 if buffexpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or enemies() > 3 spell(focused_azerite_beam)
 #memory_of_lucid_dreams,if=active_enemies<5&debuff.packed_ice.down&cooldown.frozen_orb.remains>5&!action.frozen_orb.in_flight&ground_aoe.frozen_orb.remains=0
 if enemies() < 5 and target.DebuffExpires(packed_ice) and spellcooldown(frozen_orb) > 5 and not timesincepreviousspell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 spell(memory_of_lucid_dreams_essence)
 #blood_of_the_enemy,if=prev_gcd.1.frozen_orb|ground_aoe.frozen_orb.remains>5
 if previousgcdspell(frozen_orb) or target.DebuffRemaining(frozen_orb_debuff) > 5 spell(blood_of_the_enemy)
}

AddFunction FrostEssencesCdPostConditions
{
 { buffexpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or enemies() > 3 } and spell(purifying_blast) or { buffexpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or enemies() > 3 } and spell(ripple_in_space_essence) or timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) and spell(concentrated_flame_essence) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or { buffexpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or enemies() > 3 } and spell(worldvein_resonance_essence)
}

### actions.cooldowns

AddFunction FrostCooldownsMainActions
{
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) FrostTalentropMainActions()
}

AddFunction FrostCooldownsMainPostConditions
{
 hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) and FrostTalentropMainPostConditions()
}

AddFunction FrostCooldownsShortCdActions
{
 #rune_of_power,if=prev_gcd.1.frozen_orb|target.time_to_die>10+cast_time&target.time_to_die<20
 if previousgcdspell(frozen_orb) or target.timetodie() > 10 + casttime(rune_of_power) and target.timetodie() < 20 spell(rune_of_power)
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) FrostTalentropShortCdActions()
}

AddFunction FrostCooldownsShortCdPostConditions
{
 hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) and FrostTalentropShortCdPostConditions()
}

AddFunction FrostCooldownsCdActions
{
 #guardian_of_azeroth,if=cooldown.frozen_orb.remains<5
 if spellcooldown(frozen_orb) < 5 spell(guardian_of_azeroth)
 #icy_veins,if=cooldown.frozen_orb.remains<5
 if spellcooldown(frozen_orb) < 5 spell(icy_veins)
 #mirror_image
 spell(mirror_image)

 unless { previousgcdspell(frozen_orb) or target.timetodie() > 10 + casttime(rune_of_power) and target.timetodie() < 20 } and spell(rune_of_power)
 {
  #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
  if hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) FrostTalentropCdActions()

  unless hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) and FrostTalentropCdPostConditions()
  {
   #potion,if=prev_gcd.1.icy_veins|target.time_to_die<30
   if { previousgcdspell(icy_veins) or target.timetodie() < 30 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
   #use_item,name=balefire_branch,if=!talent.glacial_spike.enabled|buff.brain_freeze.react&prev_gcd.1.glacial_spike
   if not hastalent(glacial_spike_talent) or buffpresent(brain_freeze_buff) and previousgcdspell(glacial_spike) frostuseitemactions()
   #use_items
   frostuseitemactions()
   #blood_fury
   spell(blood_fury_sp)
   #berserking
   spell(berserking)
   #lights_judgment
   spell(lights_judgment)
   #fireblood
   spell(fireblood)
   #ancestral_call
   spell(ancestral_call)
  }
 }
}

AddFunction FrostCooldownsCdPostConditions
{
 { previousgcdspell(frozen_orb) or target.timetodie() > 10 + casttime(rune_of_power) and target.timetodie() < 20 } and spell(rune_of_power) or hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) and FrostTalentropCdPostConditions()
}

### actions.aoe

AddFunction FrostAoeMainActions
{
 #blizzard
 spell(blizzard)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #ice_nova
  spell(ice_nova)
  #flurry,if=prev_gcd.1.ebonbolt|buff.brain_freeze.react&(prev_gcd.1.frostbolt&(buff.icicles.stack<4|!talent.glacial_spike.enabled)|prev_gcd.1.glacial_spike)
  if previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } spell(flurry)
  #ice_lance,if=buff.fingers_of_frost.react
  if buffpresent(fingers_of_frost_buff) spell(ice_lance)
  #ray_of_frost
  spell(ray_of_frost)
  #ebonbolt
  spell(ebonbolt)
  #glacial_spike
  spell(glacial_spike)
  #frostbolt
  spell(frostbolt)
  #call_action_list,name=movement
  FrostMovementMainActions()

  unless FrostMovementMainPostConditions()
  {
   #ice_lance
   spell(ice_lance)
  }
 }
}

AddFunction FrostAoeMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostAoeShortCdActions
{
 #frozen_orb
 spell(frozen_orb)

 unless spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #comet_storm
   spell(comet_storm)

   unless spell(ice_nova) or { previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } } and spell(flurry) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(ray_of_frost) or spell(ebonbolt) or spell(glacial_spike)
   {
    #cone_of_cold
    if target.distance() < 12 spell(cone_of_cold)

    unless spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostAoeShortCdPostConditions
{
 spell(blizzard) or FrostEssencesShortCdPostConditions() or spell(ice_nova) or { previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } } and spell(flurry) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(ray_of_frost) or spell(ebonbolt) or spell(glacial_spike) or spell(frostbolt) or FrostMovementShortCdPostConditions() or spell(ice_lance)
}

AddFunction FrostAoeCdActions
{
 unless spell(frozen_orb) or spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or spell(comet_storm) or spell(ice_nova) or { previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } } and spell(flurry) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(ray_of_frost) or spell(ebonbolt) or spell(glacial_spike) or target.distance() < 12 and spell(cone_of_cold)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if buffexpires(icy_veins_buff) and buffexpires(rune_of_power_buff) frostuseitemactions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if buffexpires(icy_veins_buff) and buffexpires(rune_of_power_buff) frostuseitemactions()

   unless spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostAoeCdPostConditions
{
 spell(frozen_orb) or spell(blizzard) or FrostEssencesCdPostConditions() or spell(comet_storm) or spell(ice_nova) or { previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } } and spell(flurry) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(ray_of_frost) or spell(ebonbolt) or spell(glacial_spike) or target.distance() < 12 and spell(cone_of_cold) or spell(frostbolt) or FrostMovementCdPostConditions() or spell(ice_lance)
}

### actions.default

AddFunction FrostDefaultMainActions
{
 #ice_lance,if=prev_gcd.1.flurry&!buff.fingers_of_frost.react
 if previousgcdspell(flurry) and not buffpresent(fingers_of_frost_buff) spell(ice_lance)
 #call_action_list,name=cooldowns
 FrostCooldownsMainActions()

 unless FrostCooldownsMainPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
  if enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 FrostAoeMainActions()

  unless { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeMainPostConditions()
  {
   #call_action_list,name=single
   FrostSingleMainActions()
  }
 }
}

AddFunction FrostDefaultMainPostConditions
{
 FrostCooldownsMainPostConditions() or { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeMainPostConditions() or FrostSingleMainPostConditions()
}

AddFunction FrostDefaultShortCdActions
{
 unless previousgcdspell(flurry) and not buffpresent(fingers_of_frost_buff) and spell(ice_lance)
 {
  #call_action_list,name=cooldowns
  FrostCooldownsShortCdActions()

  unless FrostCooldownsShortCdPostConditions()
  {
   #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
   if enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 FrostAoeShortCdActions()

   unless { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeShortCdPostConditions()
   {
    #call_action_list,name=single
    FrostSingleShortCdActions()
   }
  }
 }
}

AddFunction FrostDefaultShortCdPostConditions
{
 previousgcdspell(flurry) and not buffpresent(fingers_of_frost_buff) and spell(ice_lance) or FrostCooldownsShortCdPostConditions() or { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeShortCdPostConditions() or FrostSingleShortCdPostConditions()
}

AddFunction FrostDefaultCdActions
{
 #counterspell
 frostinterruptactions()

 unless previousgcdspell(flurry) and not buffpresent(fingers_of_frost_buff) and spell(ice_lance)
 {
  #call_action_list,name=cooldowns
  FrostCooldownsCdActions()

  unless FrostCooldownsCdPostConditions()
  {
   #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
   if enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 FrostAoeCdActions()

   unless { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeCdPostConditions()
   {
    #call_action_list,name=single
    FrostSingleCdActions()
   }
  }
 }
}

AddFunction FrostDefaultCdPostConditions
{
 previousgcdspell(flurry) and not buffpresent(fingers_of_frost_buff) and spell(ice_lance) or FrostCooldownsCdPostConditions() or { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeCdPostConditions() or FrostSingleCdPostConditions()
}

### Frost icons.

AddCheckBox(opt_mage_frost_aoe l(AOE) default specialization=frost)

AddIcon checkbox=!opt_mage_frost_aoe enemies=1 help=shortcd specialization=frost
{
 if not incombat() frostprecombatshortcdactions()
 unless not incombat() and frostprecombatshortcdpostconditions()
 {
  frostdefaultshortcdactions()
 }
}

AddIcon checkbox=opt_mage_frost_aoe help=shortcd specialization=frost
{
 if not incombat() frostprecombatshortcdactions()
 unless not incombat() and frostprecombatshortcdpostconditions()
 {
  frostdefaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=frost
{
 if not incombat() frostprecombatmainactions()
 unless not incombat() and frostprecombatmainpostconditions()
 {
  frostdefaultmainactions()
 }
}

AddIcon checkbox=opt_mage_frost_aoe help=aoe specialization=frost
{
 if not incombat() frostprecombatmainactions()
 unless not incombat() and frostprecombatmainpostconditions()
 {
  frostdefaultmainactions()
 }
}

AddIcon checkbox=!opt_mage_frost_aoe enemies=1 help=cd specialization=frost
{
 if not incombat() frostprecombatcdactions()
 unless not incombat() and frostprecombatcdpostconditions()
 {
  frostdefaultcdactions()
 }
}

AddIcon checkbox=opt_mage_frost_aoe help=cd specialization=frost
{
 if not incombat() frostprecombatcdactions()
 unless not incombat() and frostprecombatcdpostconditions()
 {
  frostdefaultcdactions()
 }
}

### Required symbols
# ancestral_call
# arcane_intellect
# berserking
# blink
# blizzard
# blood_fury_sp
# blood_of_the_enemy
# brain_freeze_buff
# comet_storm
# comet_storm_talent
# concentrated_flame_essence
# cone_of_cold
# counterspell
# ebonbolt
# ebonbolt_talent
# fingers_of_frost_buff
# fireblood
# flurry
# focused_azerite_beam
# freezing_rain_talent
# frostbolt
# frozen_orb
# frozen_orb_debuff
# glacial_spike
# glacial_spike_talent
# guardian_of_azeroth
# ice_floes
# ice_floes_buff
# ice_lance
# ice_nova
# icicles_buff
# icy_veins
# icy_veins_buff
# lights_judgment
# memory_of_lucid_dreams_essence
# mirror_image
# packed_ice
# purifying_blast
# quaking_palm
# ray_of_frost
# ray_of_frost_talent
# reckless_force_buff
# ripple_in_space_essence
# rune_of_power
# rune_of_power_buff
# rune_of_power_talent
# summon_water_elemental
# the_unbound_force
# unbridled_fury_item
# winters_chill_debuff
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("MAGE", "frost", name, desc, code, "script")
    end
    do
        local name = "sc_t23_mage_frost_noicelance"
        local desc = "[8.2] Simulationcraft: T23_Mage_Frost_NoIceLance"
        local code = [[
# Based on SimulationCraft profile "T23_Mage_Frost_NoIceLance".
#	class=mage
#	spec=frost
#	talents=1013023

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=frost)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=frost)
AddCheckBox(opt_blink spellname(blink) specialization=frost)

AddFunction FrostInterruptActions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(counterspell) and target.isinterruptible() spell(counterspell)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
 }
}

AddFunction FrostUseItemActions
{
 item(Trinket0Slot text=13 usable=1)
 item(Trinket1Slot text=14 usable=1)
}

### actions.talent_rop

AddFunction FrostTalentropMainActions
{
}

AddFunction FrostTalentropMainPostConditions
{
}

AddFunction FrostTalentropShortCdActions
{
 #rune_of_power,if=talent.glacial_spike.enabled&buff.icicles.stack=5&(buff.brain_freeze.react|talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time)
 if hastalent(glacial_spike_talent) and buffstacks(icicles_buff) == 5 and { buffpresent(brain_freeze_buff) or hastalent(ebonbolt_talent) and spellcooldown(ebonbolt) < casttime(rune_of_power) } spell(rune_of_power)
 #rune_of_power,if=!talent.glacial_spike.enabled&(talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time|talent.comet_storm.enabled&cooldown.comet_storm.remains<cast_time|talent.ray_of_frost.enabled&cooldown.ray_of_frost.remains<cast_time|charges_fractional>1.9)
 if not hastalent(glacial_spike_talent) and { hastalent(ebonbolt_talent) and spellcooldown(ebonbolt) < casttime(rune_of_power) or hastalent(comet_storm_talent) and spellcooldown(comet_storm) < casttime(rune_of_power) or hastalent(ray_of_frost_talent) and spellcooldown(ray_of_frost) < casttime(rune_of_power) or charges(rune_of_power count=0) > 1.9 } spell(rune_of_power)
}

AddFunction FrostTalentropShortCdPostConditions
{
}

AddFunction FrostTalentropCdActions
{
}

AddFunction FrostTalentropCdPostConditions
{
 hastalent(glacial_spike_talent) and buffstacks(icicles_buff) == 5 and { buffpresent(brain_freeze_buff) or hastalent(ebonbolt_talent) and spellcooldown(ebonbolt) < casttime(rune_of_power) } and spell(rune_of_power) or not hastalent(glacial_spike_talent) and { hastalent(ebonbolt_talent) and spellcooldown(ebonbolt) < casttime(rune_of_power) or hastalent(comet_storm_talent) and spellcooldown(comet_storm) < casttime(rune_of_power) or hastalent(ray_of_frost_talent) and spellcooldown(ray_of_frost) < casttime(rune_of_power) or charges(rune_of_power count=0) > 1.9 } and spell(rune_of_power)
}

### actions.single

AddFunction FrostSingleMainActions
{
 #ice_nova,if=cooldown.ice_nova.ready&debuff.winters_chill.up
 if spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) spell(ice_nova)
 #flurry,if=talent.ebonbolt.enabled&prev_gcd.1.ebonbolt&buff.brain_freeze.react
 if hastalent(ebonbolt_talent) and previousgcdspell(ebonbolt) and buffpresent(brain_freeze_buff) spell(flurry)
 #flurry,if=prev_gcd.1.glacial_spike&buff.brain_freeze.react
 if previousgcdspell(glacial_spike) and buffpresent(brain_freeze_buff) spell(flurry)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #blizzard,if=active_enemies>2|active_enemies>1&!talent.splitting_ice.enabled
  if enemies() > 2 or enemies() > 1 and not hastalent(splitting_ice_talent) spell(blizzard)
  #ebonbolt,if=buff.icicles.stack=5&!buff.brain_freeze.react
  if buffstacks(icicles_buff) == 5 and not buffpresent(brain_freeze_buff) spell(ebonbolt)
  #glacial_spike,if=buff.brain_freeze.react|prev_gcd.1.ebonbolt|talent.incanters_flow.enabled&cast_time+travel_time>incanters_flow_time_to.5.up&cast_time+travel_time<incanters_flow_time_to.4.down
  if buffpresent(brain_freeze_buff) or previousgcdspell(ebonbolt) or hastalent(incanters_flow_talent) and casttime(glacial_spike) + traveltime(glacial_spike) > stacktimeto(incanters_flow_buff 5 up) and casttime(glacial_spike) + traveltime(glacial_spike) < stacktimeto(incanters_flow_buff 4 down) spell(glacial_spike)
  #ice_nova
  spell(ice_nova)
  #frostbolt
  spell(frostbolt)
  #call_action_list,name=movement
  FrostMovementMainActions()

  unless FrostMovementMainPostConditions()
  {
   #ice_lance
   spell(ice_lance)
  }
 }
}

AddFunction FrostSingleMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostSingleShortCdActions
{
 unless spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and spell(ice_nova) or hastalent(ebonbolt_talent) and previousgcdspell(ebonbolt) and buffpresent(brain_freeze_buff) and spell(flurry) or previousgcdspell(glacial_spike) and buffpresent(brain_freeze_buff) and spell(flurry)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #frozen_orb
   spell(frozen_orb)

   unless { enemies() > 2 or enemies() > 1 and not hastalent(splitting_ice_talent) } and spell(blizzard)
   {
    #comet_storm
    spell(comet_storm)

    unless buffstacks(icicles_buff) == 5 and not buffpresent(brain_freeze_buff) and spell(ebonbolt) or { buffpresent(brain_freeze_buff) or previousgcdspell(ebonbolt) or hastalent(incanters_flow_talent) and casttime(glacial_spike) + traveltime(glacial_spike) > stacktimeto(incanters_flow_buff 5 up) and casttime(glacial_spike) + traveltime(glacial_spike) < stacktimeto(incanters_flow_buff 4 down) } and spell(glacial_spike) or spell(ice_nova) or spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostSingleShortCdPostConditions
{
 spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and spell(ice_nova) or hastalent(ebonbolt_talent) and previousgcdspell(ebonbolt) and buffpresent(brain_freeze_buff) and spell(flurry) or previousgcdspell(glacial_spike) and buffpresent(brain_freeze_buff) and spell(flurry) or FrostEssencesShortCdPostConditions() or { enemies() > 2 or enemies() > 1 and not hastalent(splitting_ice_talent) } and spell(blizzard) or buffstacks(icicles_buff) == 5 and not buffpresent(brain_freeze_buff) and spell(ebonbolt) or { buffpresent(brain_freeze_buff) or previousgcdspell(ebonbolt) or hastalent(incanters_flow_talent) and casttime(glacial_spike) + traveltime(glacial_spike) > stacktimeto(incanters_flow_buff 5 up) and casttime(glacial_spike) + traveltime(glacial_spike) < stacktimeto(incanters_flow_buff 4 down) } and spell(glacial_spike) or spell(ice_nova) or spell(frostbolt) or FrostMovementShortCdPostConditions() or spell(ice_lance)
}

AddFunction FrostSingleCdActions
{
 unless spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and spell(ice_nova) or hastalent(ebonbolt_talent) and previousgcdspell(ebonbolt) and buffpresent(brain_freeze_buff) and spell(flurry) or previousgcdspell(glacial_spike) and buffpresent(brain_freeze_buff) and spell(flurry)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or spell(frozen_orb) or { enemies() > 2 or enemies() > 1 and not hastalent(splitting_ice_talent) } and spell(blizzard) or spell(comet_storm) or buffstacks(icicles_buff) == 5 and not buffpresent(brain_freeze_buff) and spell(ebonbolt) or { buffpresent(brain_freeze_buff) or previousgcdspell(ebonbolt) or hastalent(incanters_flow_talent) and casttime(glacial_spike) + traveltime(glacial_spike) > stacktimeto(incanters_flow_buff 5 up) and casttime(glacial_spike) + traveltime(glacial_spike) < stacktimeto(incanters_flow_buff 4 down) } and spell(glacial_spike) or spell(ice_nova)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if buffexpires(icy_veins_buff) and buffexpires(rune_of_power_buff) frostuseitemactions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if buffexpires(icy_veins_buff) and buffexpires(rune_of_power_buff) frostuseitemactions()

   unless spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostSingleCdPostConditions
{
 spellcooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and spell(ice_nova) or hastalent(ebonbolt_talent) and previousgcdspell(ebonbolt) and buffpresent(brain_freeze_buff) and spell(flurry) or previousgcdspell(glacial_spike) and buffpresent(brain_freeze_buff) and spell(flurry) or FrostEssencesCdPostConditions() or spell(frozen_orb) or { enemies() > 2 or enemies() > 1 and not hastalent(splitting_ice_talent) } and spell(blizzard) or spell(comet_storm) or buffstacks(icicles_buff) == 5 and not buffpresent(brain_freeze_buff) and spell(ebonbolt) or { buffpresent(brain_freeze_buff) or previousgcdspell(ebonbolt) or hastalent(incanters_flow_talent) and casttime(glacial_spike) + traveltime(glacial_spike) > stacktimeto(incanters_flow_buff 5 up) and casttime(glacial_spike) + traveltime(glacial_spike) < stacktimeto(incanters_flow_buff 4 down) } and spell(glacial_spike) or spell(ice_nova) or spell(frostbolt) or FrostMovementCdPostConditions() or spell(ice_lance)
}

### actions.precombat

AddFunction FrostPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 spell(arcane_intellect)
 #frostbolt
 spell(frostbolt)
}

AddFunction FrostPrecombatMainPostConditions
{
}

AddFunction FrostPrecombatShortCdActions
{
 unless spell(arcane_intellect)
 {
  #summon_water_elemental
  if not pet.present() spell(summon_water_elemental)
 }
}

AddFunction FrostPrecombatShortCdPostConditions
{
 spell(arcane_intellect) or spell(frostbolt)
}

AddFunction FrostPrecombatCdActions
{
 unless spell(arcane_intellect) or not pet.present() and spell(summon_water_elemental)
 {
  #snapshot_stats
  #use_item,name=azsharas_font_of_power
  frostuseitemactions()
  #mirror_image
  spell(mirror_image)
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 }
}

AddFunction FrostPrecombatCdPostConditions
{
 spell(arcane_intellect) or not pet.present() and spell(summon_water_elemental) or spell(frostbolt)
}

### actions.movement

AddFunction FrostMovementMainActions
{
}

AddFunction FrostMovementMainPostConditions
{
}

AddFunction FrostMovementShortCdActions
{
 #blink_any,if=movement.distance>10
 if target.distance() > 10 and checkboxon(opt_blink) spell(blink)
 #ice_floes,if=buff.ice_floes.down
 if buffexpires(ice_floes_buff) and speed() > 0 spell(ice_floes)
}

AddFunction FrostMovementShortCdPostConditions
{
}

AddFunction FrostMovementCdActions
{
}

AddFunction FrostMovementCdPostConditions
{
 target.distance() > 10 and checkboxon(opt_blink) and spell(blink) or buffexpires(ice_floes_buff) and speed() > 0 and spell(ice_floes)
}

### actions.essences

AddFunction FrostEssencesMainActions
{
 #concentrated_flame,line_cd=6,if=buff.rune_of_power.down
 if timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) spell(concentrated_flame_essence)
}

AddFunction FrostEssencesMainPostConditions
{
}

AddFunction FrostEssencesShortCdActions
{
 #purifying_blast,if=buff.rune_of_power.down|active_enemies>3
 if buffexpires(rune_of_power_buff) or enemies() > 3 spell(purifying_blast)
 #ripple_in_space,if=buff.rune_of_power.down|active_enemies>3
 if buffexpires(rune_of_power_buff) or enemies() > 3 spell(ripple_in_space_essence)

 unless timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and spell(concentrated_flame_essence)
 {
  #the_unbound_force,if=buff.reckless_force.up
  if buffpresent(reckless_force_buff) spell(the_unbound_force)
  #worldvein_resonance,if=buff.rune_of_power.down|active_enemies>3
  if buffexpires(rune_of_power_buff) or enemies() > 3 spell(worldvein_resonance_essence)
 }
}

AddFunction FrostEssencesShortCdPostConditions
{
 timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and spell(concentrated_flame_essence)
}

AddFunction FrostEssencesCdActions
{
 #focused_azerite_beam,if=buff.rune_of_power.down|active_enemies>3
 if buffexpires(rune_of_power_buff) or enemies() > 3 spell(focused_azerite_beam)
 #memory_of_lucid_dreams,if=active_enemies<5&(buff.icicles.stack<=1|!talent.glacial_spike.enabled)&cooldown.frozen_orb.remains>10
 if enemies() < 5 and { buffstacks(icicles_buff) <= 1 or not hastalent(glacial_spike_talent) } and spellcooldown(frozen_orb) > 10 spell(memory_of_lucid_dreams_essence)
 #blood_of_the_enemy,if=(talent.glacial_spike.enabled&buff.icicles.stack=5&(buff.brain_freeze.react|prev_gcd.1.ebonbolt))|((active_enemies>3|!talent.glacial_spike.enabled)&(prev_gcd.1.frozen_orb|ground_aoe.frozen_orb.remains>5))
 if hastalent(glacial_spike_talent) and buffstacks(icicles_buff) == 5 and { buffpresent(brain_freeze_buff) or previousgcdspell(ebonbolt) } or { enemies() > 3 or not hastalent(glacial_spike_talent) } and { previousgcdspell(frozen_orb) or target.DebuffRemaining(frozen_orb_debuff) > 5 } spell(blood_of_the_enemy)
}

AddFunction FrostEssencesCdPostConditions
{
 { buffexpires(rune_of_power_buff) or enemies() > 3 } and spell(purifying_blast) or { buffexpires(rune_of_power_buff) or enemies() > 3 } and spell(ripple_in_space_essence) or timesincepreviousspell(concentrated_flame_essence) > 6 and buffexpires(rune_of_power_buff) and spell(concentrated_flame_essence) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or { buffexpires(rune_of_power_buff) or enemies() > 3 } and spell(worldvein_resonance_essence)
}

### actions.cooldowns

AddFunction FrostCooldownsMainActions
{
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) FrostTalentropMainActions()
}

AddFunction FrostCooldownsMainPostConditions
{
 hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) and FrostTalentropMainPostConditions()
}

AddFunction FrostCooldownsShortCdActions
{
 #rune_of_power,if=prev_gcd.1.frozen_orb|target.time_to_die>10+cast_time&target.time_to_die<20
 if previousgcdspell(frozen_orb) or target.timetodie() > 10 + casttime(rune_of_power) and target.timetodie() < 20 spell(rune_of_power)
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) FrostTalentropShortCdActions()
}

AddFunction FrostCooldownsShortCdPostConditions
{
 hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) and FrostTalentropShortCdPostConditions()
}

AddFunction FrostCooldownsCdActions
{
 #guardian_of_azeroth
 spell(guardian_of_azeroth)
 #icy_veins
 spell(icy_veins)
 #mirror_image
 spell(mirror_image)

 unless { previousgcdspell(frozen_orb) or target.timetodie() > 10 + casttime(rune_of_power) and target.timetodie() < 20 } and spell(rune_of_power)
 {
  #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
  if hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) FrostTalentropCdActions()

  unless hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) and FrostTalentropCdPostConditions()
  {
   #potion,if=prev_gcd.1.icy_veins|target.time_to_die<30
   if { previousgcdspell(icy_veins) or target.timetodie() < 30 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
   #use_item,name=balefire_branch,if=!talent.glacial_spike.enabled|buff.brain_freeze.react&prev_gcd.1.glacial_spike
   if not hastalent(glacial_spike_talent) or buffpresent(brain_freeze_buff) and previousgcdspell(glacial_spike) frostuseitemactions()
   #use_items
   frostuseitemactions()
   #blood_fury
   spell(blood_fury_sp)
   #berserking
   spell(berserking)
   #lights_judgment
   spell(lights_judgment)
   #fireblood
   spell(fireblood)
   #ancestral_call
   spell(ancestral_call)
  }
 }
}

AddFunction FrostCooldownsCdPostConditions
{
 { previousgcdspell(frozen_orb) or target.timetodie() > 10 + casttime(rune_of_power) and target.timetodie() < 20 } and spell(rune_of_power) or hastalent(rune_of_power_talent) and enemies() == 1 and spellcooldown(rune_of_power) < spellcooldown(frozen_orb) and FrostTalentropCdPostConditions()
}

### actions.aoe

AddFunction FrostAoeMainActions
{
 #blizzard
 spell(blizzard)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #ice_nova
  spell(ice_nova)
  #flurry,if=prev_gcd.1.ebonbolt|buff.brain_freeze.react&(prev_gcd.1.frostbolt&(buff.icicles.stack<4|!talent.glacial_spike.enabled)|prev_gcd.1.glacial_spike)
  if previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } spell(flurry)
  #ice_lance,if=buff.fingers_of_frost.react
  if buffpresent(fingers_of_frost_buff) spell(ice_lance)
  #ray_of_frost
  spell(ray_of_frost)
  #ebonbolt
  spell(ebonbolt)
  #glacial_spike
  spell(glacial_spike)
  #frostbolt
  spell(frostbolt)
  #call_action_list,name=movement
  FrostMovementMainActions()

  unless FrostMovementMainPostConditions()
  {
   #ice_lance
   spell(ice_lance)
  }
 }
}

AddFunction FrostAoeMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostAoeShortCdActions
{
 #frozen_orb
 spell(frozen_orb)

 unless spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #comet_storm
   spell(comet_storm)

   unless spell(ice_nova) or { previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } } and spell(flurry) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(ray_of_frost) or spell(ebonbolt) or spell(glacial_spike)
   {
    #cone_of_cold
    if target.distance() < 12 spell(cone_of_cold)

    unless spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostAoeShortCdPostConditions
{
 spell(blizzard) or FrostEssencesShortCdPostConditions() or spell(ice_nova) or { previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } } and spell(flurry) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(ray_of_frost) or spell(ebonbolt) or spell(glacial_spike) or spell(frostbolt) or FrostMovementShortCdPostConditions() or spell(ice_lance)
}

AddFunction FrostAoeCdActions
{
 unless spell(frozen_orb) or spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or spell(comet_storm) or spell(ice_nova) or { previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } } and spell(flurry) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(ray_of_frost) or spell(ebonbolt) or spell(glacial_spike) or target.distance() < 12 and spell(cone_of_cold)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if buffexpires(icy_veins_buff) and buffexpires(rune_of_power_buff) frostuseitemactions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if buffexpires(icy_veins_buff) and buffexpires(rune_of_power_buff) frostuseitemactions()

   unless spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostAoeCdPostConditions
{
 spell(frozen_orb) or spell(blizzard) or FrostEssencesCdPostConditions() or spell(comet_storm) or spell(ice_nova) or { previousgcdspell(ebonbolt) or buffpresent(brain_freeze_buff) and { previousgcdspell(frostbolt) and { buffstacks(icicles_buff) < 4 or not hastalent(glacial_spike_talent) } or previousgcdspell(glacial_spike) } } and spell(flurry) or buffpresent(fingers_of_frost_buff) and spell(ice_lance) or spell(ray_of_frost) or spell(ebonbolt) or spell(glacial_spike) or target.distance() < 12 and spell(cone_of_cold) or spell(frostbolt) or FrostMovementCdPostConditions() or spell(ice_lance)
}

### actions.default

AddFunction FrostDefaultMainActions
{
 #call_action_list,name=cooldowns
 FrostCooldownsMainActions()

 unless FrostCooldownsMainPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
  if enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 FrostAoeMainActions()

  unless { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeMainPostConditions()
  {
   #call_action_list,name=single
   FrostSingleMainActions()
  }
 }
}

AddFunction FrostDefaultMainPostConditions
{
 FrostCooldownsMainPostConditions() or { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeMainPostConditions() or FrostSingleMainPostConditions()
}

AddFunction FrostDefaultShortCdActions
{
 #call_action_list,name=cooldowns
 FrostCooldownsShortCdActions()

 unless FrostCooldownsShortCdPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
  if enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 FrostAoeShortCdActions()

  unless { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeShortCdPostConditions()
  {
   #call_action_list,name=single
   FrostSingleShortCdActions()
  }
 }
}

AddFunction FrostDefaultShortCdPostConditions
{
 FrostCooldownsShortCdPostConditions() or { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeShortCdPostConditions() or FrostSingleShortCdPostConditions()
}

AddFunction FrostDefaultCdActions
{
 #counterspell
 frostinterruptactions()
 #call_action_list,name=cooldowns
 FrostCooldownsCdActions()

 unless FrostCooldownsCdPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
  if enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 FrostAoeCdActions()

  unless { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeCdPostConditions()
  {
   #call_action_list,name=single
   FrostSingleCdActions()
  }
 }
}

AddFunction FrostDefaultCdPostConditions
{
 FrostCooldownsCdPostConditions() or { enemies() > 3 and hastalent(freezing_rain_talent) or enemies() > 4 } and FrostAoeCdPostConditions() or FrostSingleCdPostConditions()
}

### Frost icons.

AddCheckBox(opt_mage_frost_aoe l(AOE) default specialization=frost)

AddIcon checkbox=!opt_mage_frost_aoe enemies=1 help=shortcd specialization=frost
{
 if not incombat() frostprecombatshortcdactions()
 unless not incombat() and frostprecombatshortcdpostconditions()
 {
  frostdefaultshortcdactions()
 }
}

AddIcon checkbox=opt_mage_frost_aoe help=shortcd specialization=frost
{
 if not incombat() frostprecombatshortcdactions()
 unless not incombat() and frostprecombatshortcdpostconditions()
 {
  frostdefaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=frost
{
 if not incombat() frostprecombatmainactions()
 unless not incombat() and frostprecombatmainpostconditions()
 {
  frostdefaultmainactions()
 }
}

AddIcon checkbox=opt_mage_frost_aoe help=aoe specialization=frost
{
 if not incombat() frostprecombatmainactions()
 unless not incombat() and frostprecombatmainpostconditions()
 {
  frostdefaultmainactions()
 }
}

AddIcon checkbox=!opt_mage_frost_aoe enemies=1 help=cd specialization=frost
{
 if not incombat() frostprecombatcdactions()
 unless not incombat() and frostprecombatcdpostconditions()
 {
  frostdefaultcdactions()
 }
}

AddIcon checkbox=opt_mage_frost_aoe help=cd specialization=frost
{
 if not incombat() frostprecombatcdactions()
 unless not incombat() and frostprecombatcdpostconditions()
 {
  frostdefaultcdactions()
 }
}

### Required symbols
# ancestral_call
# arcane_intellect
# berserking
# blink
# blizzard
# blood_fury_sp
# blood_of_the_enemy
# brain_freeze_buff
# comet_storm
# comet_storm_talent
# concentrated_flame_essence
# cone_of_cold
# counterspell
# ebonbolt
# ebonbolt_talent
# fingers_of_frost_buff
# fireblood
# flurry
# focused_azerite_beam
# freezing_rain_talent
# frostbolt
# frozen_orb
# frozen_orb_debuff
# glacial_spike
# glacial_spike_talent
# guardian_of_azeroth
# ice_floes
# ice_floes_buff
# ice_lance
# ice_nova
# icicles_buff
# icy_veins
# icy_veins_buff
# incanters_flow_talent
# lights_judgment
# memory_of_lucid_dreams_essence
# mirror_image
# purifying_blast
# quaking_palm
# ray_of_frost
# ray_of_frost_talent
# reckless_force_buff
# ripple_in_space_essence
# rune_of_power
# rune_of_power_buff
# rune_of_power_talent
# splitting_ice_talent
# summon_water_elemental
# the_unbound_force
# unbridled_fury_item
# winters_chill_debuff
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("MAGE", "frost", name, desc, code, "script")
    end
end
