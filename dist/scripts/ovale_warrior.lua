local __exports = LibStub:NewLibrary("ovale/scripts/ovale_warrior", 80300)
if not __exports then return end
__exports.registerWarrior = function(OvaleScripts)
    do
        local name = "sc_t24_warrior_arms"
        local desc = "[8.3] Simulationcraft: T24_Warrior_Arms"
        local code = [[
# Based on SimulationCraft profile "T24_Warrior_Arms".
#	class=warrior
#	spec=arms
#	talents=3322211

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=arms)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=arms)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=arms)

AddFunction armsinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(pummel) and target.isinterruptible() spell(pummel)
  if target.inrange(storm_bolt) and not target.classification(worldboss) spell(storm_bolt)
  if target.distance(less 10) and not target.classification(worldboss) spell(shockwave)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
  if target.inrange(intimidating_shout) and not target.classification(worldboss) spell(intimidating_shout)
 }
}

AddFunction armsuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction armsgetinmeleerange
{
 if checkboxon(opt_melee_range) and not inflighttotarget(charge) and not inflighttotarget(heroic_leap) and not target.inrange(pummel)
 {
  if target.inrange(charge) spell(charge)
  if spellcharges(charge) == 0 and target.distance(atleast 8) and target.distance(atmost 40) spell(heroic_leap)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.single_target

AddFunction armssingle_targetmainactions
{
 #rend,if=remains<=duration*0.3&debuff.colossus_smash.down
 if target.debuffremaining(rend_debuff) <= baseduration(rend_debuff) * 0.3 and target.debuffexpires(colossus_smash) spell(rend)
 #skullsplitter,if=rage<60&buff.deadly_calm.down&buff.memory_of_lucid_dreams.down
 if rage() < 60 and buffexpires(deadly_calm_buff) and buffexpires(memory_of_lucid_dreams_essence_buff) spell(skullsplitter)
 #warbreaker
 spell(warbreaker)
 #execute,if=buff.sudden_death.react
 if buffpresent(sudden_death_buff_arms) spell(execute_arms)
 #cleave,if=spell_targets.whirlwind>2
 if enemies() > 2 spell(cleave)
 #overpower,if=(rage<30&buff.memory_of_lucid_dreams.up&debuff.colossus_smash.up)|(rage<70&buff.memory_of_lucid_dreams.down)
 if rage() < 30 and buffpresent(memory_of_lucid_dreams_essence_buff) and target.debuffpresent(colossus_smash) or rage() < 70 and buffexpires(memory_of_lucid_dreams_essence_buff) spell(overpower)
 #mortal_strike
 spell(mortal_strike)
 #whirlwind,if=talent.fervor_of_battle.enabled&(buff.memory_of_lucid_dreams.up|debuff.colossus_smash.up|buff.deadly_calm.up)
 if hastalent(fervor_of_battle_talent) and { buffpresent(memory_of_lucid_dreams_essence_buff) or target.debuffpresent(colossus_smash) or buffpresent(deadly_calm_buff) } spell(whirlwind_arms)
 #overpower
 spell(overpower)
 #whirlwind,if=talent.fervor_of_battle.enabled&(buff.test_of_might.up|debuff.colossus_smash.down&buff.test_of_might.down&rage>60)
 if hastalent(fervor_of_battle_talent) and { buffpresent(test_of_might_buff) or target.debuffexpires(colossus_smash) and buffexpires(test_of_might_buff) and rage() > 60 } spell(whirlwind_arms)
 #slam,if=!talent.fervor_of_battle.enabled
 if not hastalent(fervor_of_battle_talent) spell(slam)
}

AddFunction armssingle_targetmainpostconditions
{
}

AddFunction armssingle_targetshortcdactions
{
 unless target.debuffremaining(rend_debuff) <= baseduration(rend_debuff) * 0.3 and target.debuffexpires(colossus_smash) and spell(rend) or rage() < 60 and buffexpires(deadly_calm_buff) and buffexpires(memory_of_lucid_dreams_essence_buff) and spell(skullsplitter)
 {
  #ravager,if=!buff.deadly_calm.up&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if not buffpresent(deadly_calm_buff) and { spellcooldown(colossus_smash) < 2 or hastalent(warbreaker_talent) and spellcooldown(warbreaker) < 2 } spell(ravager)
  #colossus_smash
  spell(colossus_smash)

  unless spell(warbreaker)
  {
   #deadly_calm
   spell(deadly_calm)

   unless buffpresent(sudden_death_buff_arms) and spell(execute_arms)
   {
    #bladestorm,if=cooldown.mortal_strike.remains&(!talent.deadly_calm.enabled|buff.deadly_calm.down)&((debuff.colossus_smash.up&!azerite.test_of_might.enabled)|buff.test_of_might.up)&buff.memory_of_lucid_dreams.down&rage<40
    if spellcooldown(mortal_strike) > 0 and { not hastalent(deadly_calm_talent) or buffexpires(deadly_calm_buff) } and { target.debuffpresent(colossus_smash) and not hasazeritetrait(test_of_might_trait) or buffpresent(test_of_might_buff) } and buffexpires(memory_of_lucid_dreams_essence_buff) and rage() < 40 spell(bladestorm_arms)
   }
  }
 }
}

AddFunction armssingle_targetshortcdpostconditions
{
 target.debuffremaining(rend_debuff) <= baseduration(rend_debuff) * 0.3 and target.debuffexpires(colossus_smash) and spell(rend) or rage() < 60 and buffexpires(deadly_calm_buff) and buffexpires(memory_of_lucid_dreams_essence_buff) and spell(skullsplitter) or spell(warbreaker) or buffpresent(sudden_death_buff_arms) and spell(execute_arms) or enemies() > 2 and spell(cleave) or { rage() < 30 and buffpresent(memory_of_lucid_dreams_essence_buff) and target.debuffpresent(colossus_smash) or rage() < 70 and buffexpires(memory_of_lucid_dreams_essence_buff) } and spell(overpower) or spell(mortal_strike) or hastalent(fervor_of_battle_talent) and { buffpresent(memory_of_lucid_dreams_essence_buff) or target.debuffpresent(colossus_smash) or buffpresent(deadly_calm_buff) } and spell(whirlwind_arms) or spell(overpower) or hastalent(fervor_of_battle_talent) and { buffpresent(test_of_might_buff) or target.debuffexpires(colossus_smash) and buffexpires(test_of_might_buff) and rage() > 60 } and spell(whirlwind_arms) or not hastalent(fervor_of_battle_talent) and spell(slam)
}

AddFunction armssingle_targetcdactions
{
}

AddFunction armssingle_targetcdpostconditions
{
 target.debuffremaining(rend_debuff) <= baseduration(rend_debuff) * 0.3 and target.debuffexpires(colossus_smash) and spell(rend) or rage() < 60 and buffexpires(deadly_calm_buff) and buffexpires(memory_of_lucid_dreams_essence_buff) and spell(skullsplitter) or not buffpresent(deadly_calm_buff) and { spellcooldown(colossus_smash) < 2 or hastalent(warbreaker_talent) and spellcooldown(warbreaker) < 2 } and spell(ravager) or spell(colossus_smash) or spell(warbreaker) or spell(deadly_calm) or buffpresent(sudden_death_buff_arms) and spell(execute_arms) or spellcooldown(mortal_strike) > 0 and { not hastalent(deadly_calm_talent) or buffexpires(deadly_calm_buff) } and { target.debuffpresent(colossus_smash) and not hasazeritetrait(test_of_might_trait) or buffpresent(test_of_might_buff) } and buffexpires(memory_of_lucid_dreams_essence_buff) and rage() < 40 and spell(bladestorm_arms) or enemies() > 2 and spell(cleave) or { rage() < 30 and buffpresent(memory_of_lucid_dreams_essence_buff) and target.debuffpresent(colossus_smash) or rage() < 70 and buffexpires(memory_of_lucid_dreams_essence_buff) } and spell(overpower) or spell(mortal_strike) or hastalent(fervor_of_battle_talent) and { buffpresent(memory_of_lucid_dreams_essence_buff) or target.debuffpresent(colossus_smash) or buffpresent(deadly_calm_buff) } and spell(whirlwind_arms) or spell(overpower) or hastalent(fervor_of_battle_talent) and { buffpresent(test_of_might_buff) or target.debuffexpires(colossus_smash) and buffexpires(test_of_might_buff) and rage() > 60 } and spell(whirlwind_arms) or not hastalent(fervor_of_battle_talent) and spell(slam)
}

### actions.precombat

AddFunction armsprecombatmainactions
{
}

AddFunction armsprecombatmainpostconditions
{
}

AddFunction armsprecombatshortcdactions
{
 #worldvein_resonance
 spell(worldvein_resonance_essence)
}

AddFunction armsprecombatshortcdpostconditions
{
}

AddFunction armsprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #use_item,name=azsharas_font_of_power
 armsuseitemactions()

 unless spell(worldvein_resonance_essence)
 {
  #memory_of_lucid_dreams
  spell(memory_of_lucid_dreams_essence)
  #guardian_of_azeroth
  spell(guardian_of_azeroth)
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)
 }
}

AddFunction armsprecombatcdpostconditions
{
 spell(worldvein_resonance_essence)
}

### actions.hac

AddFunction armshacmainactions
{
 #rend,if=remains<=duration*0.3&(!raid_event.adds.up|buff.sweeping_strikes.up)
 if target.debuffremaining(rend_debuff) <= baseduration(rend_debuff) * 0.3 and { not false(raid_event_adds_exists) or buffpresent(sweeping_strikes_buff) } spell(rend)
 #skullsplitter,if=rage<60&(cooldown.deadly_calm.remains>3|!talent.deadly_calm.enabled)
 if rage() < 60 and { spellcooldown(deadly_calm) > 3 or not hastalent(deadly_calm_talent) } spell(skullsplitter)
 #warbreaker,if=raid_event.adds.up|raid_event.adds.in>40|(raid_event.adds.in>20&talent.anger_management.enabled)
 if false(raid_event_adds_exists) or 600 > 40 or 600 > 20 and hastalent(anger_management_talent) spell(warbreaker)
 #overpower,if=!raid_event.adds.up|(raid_event.adds.up&azerite.seismic_wave.enabled)
 if not false(raid_event_adds_exists) or false(raid_event_adds_exists) and hasazeritetrait(seismic_wave_trait) spell(overpower)
 #cleave,if=spell_targets.whirlwind>2
 if enemies() > 2 spell(cleave)
 #execute,if=!raid_event.adds.up|(!talent.cleave.enabled&dot.deep_wounds.remains<2)|buff.sudden_death.react
 if not false(raid_event_adds_exists) or not hastalent(cleave_talent) and target.debuffremaining(deep_wounds_arms_debuff) < 2 or buffpresent(sudden_death_buff_arms) spell(execute_arms)
 #mortal_strike,if=!raid_event.adds.up|(!talent.cleave.enabled&dot.deep_wounds.remains<2)
 if not false(raid_event_adds_exists) or not hastalent(cleave_talent) and target.debuffremaining(deep_wounds_arms_debuff) < 2 spell(mortal_strike)
 #whirlwind,if=raid_event.adds.up
 if false(raid_event_adds_exists) spell(whirlwind_arms)
 #overpower
 spell(overpower)
 #whirlwind,if=talent.fervor_of_battle.enabled
 if hastalent(fervor_of_battle_talent) spell(whirlwind_arms)
 #slam,if=!talent.fervor_of_battle.enabled&!raid_event.adds.up
 if not hastalent(fervor_of_battle_talent) and not false(raid_event_adds_exists) spell(slam)
}

AddFunction armshacmainpostconditions
{
}

AddFunction armshacshortcdactions
{
 unless target.debuffremaining(rend_debuff) <= baseduration(rend_debuff) * 0.3 and { not false(raid_event_adds_exists) or buffpresent(sweeping_strikes_buff) } and spell(rend) or rage() < 60 and { spellcooldown(deadly_calm) > 3 or not hastalent(deadly_calm_talent) } and spell(skullsplitter)
 {
  #deadly_calm,if=(cooldown.bladestorm.remains>6|talent.ravager.enabled&cooldown.ravager.remains>6)&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if { spellcooldown(bladestorm_arms) > 6 or hastalent(ravager_talent) and spellcooldown(ravager) > 6 } and { spellcooldown(colossus_smash) < 2 or hastalent(warbreaker_talent) and spellcooldown(warbreaker) < 2 } spell(deadly_calm)
  #ravager,if=(raid_event.adds.up|raid_event.adds.in>target.time_to_die)&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if { false(raid_event_adds_exists) or 600 > target.timetodie() } and { spellcooldown(colossus_smash) < 2 or hastalent(warbreaker_talent) and spellcooldown(warbreaker) < 2 } spell(ravager)
  #colossus_smash,if=raid_event.adds.up|raid_event.adds.in>40|(raid_event.adds.in>20&talent.anger_management.enabled)
  if false(raid_event_adds_exists) or 600 > 40 or 600 > 20 and hastalent(anger_management_talent) spell(colossus_smash)

  unless { false(raid_event_adds_exists) or 600 > 40 or 600 > 20 and hastalent(anger_management_talent) } and spell(warbreaker)
  {
   #bladestorm,if=(debuff.colossus_smash.up&raid_event.adds.in>target.time_to_die)|raid_event.adds.up&((debuff.colossus_smash.remains>4.5&!azerite.test_of_might.enabled)|buff.test_of_might.up)
   if target.debuffpresent(colossus_smash) and 600 > target.timetodie() or false(raid_event_adds_exists) and { target.debuffremaining(colossus_smash) > 4.5 and not hasazeritetrait(test_of_might_trait) or buffpresent(test_of_might_buff) } spell(bladestorm_arms)
  }
 }
}

AddFunction armshacshortcdpostconditions
{
 target.debuffremaining(rend_debuff) <= baseduration(rend_debuff) * 0.3 and { not false(raid_event_adds_exists) or buffpresent(sweeping_strikes_buff) } and spell(rend) or rage() < 60 and { spellcooldown(deadly_calm) > 3 or not hastalent(deadly_calm_talent) } and spell(skullsplitter) or { false(raid_event_adds_exists) or 600 > 40 or 600 > 20 and hastalent(anger_management_talent) } and spell(warbreaker) or { not false(raid_event_adds_exists) or false(raid_event_adds_exists) and hasazeritetrait(seismic_wave_trait) } and spell(overpower) or enemies() > 2 and spell(cleave) or { not false(raid_event_adds_exists) or not hastalent(cleave_talent) and target.debuffremaining(deep_wounds_arms_debuff) < 2 or buffpresent(sudden_death_buff_arms) } and spell(execute_arms) or { not false(raid_event_adds_exists) or not hastalent(cleave_talent) and target.debuffremaining(deep_wounds_arms_debuff) < 2 } and spell(mortal_strike) or false(raid_event_adds_exists) and spell(whirlwind_arms) or spell(overpower) or hastalent(fervor_of_battle_talent) and spell(whirlwind_arms) or not hastalent(fervor_of_battle_talent) and not false(raid_event_adds_exists) and spell(slam)
}

AddFunction armshaccdactions
{
}

AddFunction armshaccdpostconditions
{
 target.debuffremaining(rend_debuff) <= baseduration(rend_debuff) * 0.3 and { not false(raid_event_adds_exists) or buffpresent(sweeping_strikes_buff) } and spell(rend) or rage() < 60 and { spellcooldown(deadly_calm) > 3 or not hastalent(deadly_calm_talent) } and spell(skullsplitter) or { spellcooldown(bladestorm_arms) > 6 or hastalent(ravager_talent) and spellcooldown(ravager) > 6 } and { spellcooldown(colossus_smash) < 2 or hastalent(warbreaker_talent) and spellcooldown(warbreaker) < 2 } and spell(deadly_calm) or { false(raid_event_adds_exists) or 600 > target.timetodie() } and { spellcooldown(colossus_smash) < 2 or hastalent(warbreaker_talent) and spellcooldown(warbreaker) < 2 } and spell(ravager) or { false(raid_event_adds_exists) or 600 > 40 or 600 > 20 and hastalent(anger_management_talent) } and spell(colossus_smash) or { false(raid_event_adds_exists) or 600 > 40 or 600 > 20 and hastalent(anger_management_talent) } and spell(warbreaker) or { target.debuffpresent(colossus_smash) and 600 > target.timetodie() or false(raid_event_adds_exists) and { target.debuffremaining(colossus_smash) > 4.5 and not hasazeritetrait(test_of_might_trait) or buffpresent(test_of_might_buff) } } and spell(bladestorm_arms) or { not false(raid_event_adds_exists) or false(raid_event_adds_exists) and hasazeritetrait(seismic_wave_trait) } and spell(overpower) or enemies() > 2 and spell(cleave) or { not false(raid_event_adds_exists) or not hastalent(cleave_talent) and target.debuffremaining(deep_wounds_arms_debuff) < 2 or buffpresent(sudden_death_buff_arms) } and spell(execute_arms) or { not false(raid_event_adds_exists) or not hastalent(cleave_talent) and target.debuffremaining(deep_wounds_arms_debuff) < 2 } and spell(mortal_strike) or false(raid_event_adds_exists) and spell(whirlwind_arms) or spell(overpower) or hastalent(fervor_of_battle_talent) and spell(whirlwind_arms) or not hastalent(fervor_of_battle_talent) and not false(raid_event_adds_exists) and spell(slam)
}

### actions.five_target

AddFunction armsfive_targetmainactions
{
 #skullsplitter,if=rage<60&(!talent.deadly_calm.enabled|buff.deadly_calm.down)
 if rage() < 60 and { not hastalent(deadly_calm_talent) or buffexpires(deadly_calm_buff) } spell(skullsplitter)
 #warbreaker,if=debuff.colossus_smash.down
 if target.debuffexpires(colossus_smash) spell(warbreaker)
 #cleave
 spell(cleave)
 #execute,if=(!talent.cleave.enabled&dot.deep_wounds.remains<2)|(buff.sudden_death.react|buff.stone_heart.react)&(buff.sweeping_strikes.up|cooldown.sweeping_strikes.remains>8)
 if not hastalent(cleave_talent) and target.debuffremaining(deep_wounds_arms_debuff) < 2 or { buffpresent(sudden_death_buff_arms) or buffpresent(stone_heart) } and { buffpresent(sweeping_strikes_buff) or spellcooldown(sweeping_strikes) > 8 } spell(execute_arms)
 #mortal_strike,if=(!talent.cleave.enabled&dot.deep_wounds.remains<2)|buff.sweeping_strikes.up&buff.overpower.stack=2&(talent.dreadnaught.enabled|buff.executioners_precision.stack=2)
 if not hastalent(cleave_talent) and target.debuffremaining(deep_wounds_arms_debuff) < 2 or buffpresent(sweeping_strikes_buff) and buffstacks(overpower_buff) == 2 and { hastalent(dreadnaught_talent) or 0 == 2 } spell(mortal_strike)
 #whirlwind,if=debuff.colossus_smash.up|(buff.crushing_assault.up&talent.fervor_of_battle.enabled)
 if target.debuffpresent(colossus_smash) or buffpresent(crushing_assault_buff) and hastalent(fervor_of_battle_talent) spell(whirlwind_arms)
 #whirlwind,if=buff.deadly_calm.up|rage>60
 if buffpresent(deadly_calm_buff) or rage() > 60 spell(whirlwind_arms)
 #overpower
 spell(overpower)
 #whirlwind
 spell(whirlwind_arms)
}

AddFunction armsfive_targetmainpostconditions
{
}

AddFunction armsfive_targetshortcdactions
{
 unless rage() < 60 and { not hastalent(deadly_calm_talent) or buffexpires(deadly_calm_buff) } and spell(skullsplitter)
 {
  #ravager,if=(!talent.warbreaker.enabled|cooldown.warbreaker.remains<2)
  if not hastalent(warbreaker_talent) or spellcooldown(warbreaker) < 2 spell(ravager)
  #colossus_smash,if=debuff.colossus_smash.down
  if target.debuffexpires(colossus_smash) spell(colossus_smash)

  unless target.debuffexpires(colossus_smash) and spell(warbreaker)
  {
   #bladestorm,if=buff.sweeping_strikes.down&(!talent.deadly_calm.enabled|buff.deadly_calm.down)&((debuff.colossus_smash.remains>4.5&!azerite.test_of_might.enabled)|buff.test_of_might.up)
   if buffexpires(sweeping_strikes_buff) and { not hastalent(deadly_calm_talent) or buffexpires(deadly_calm_buff) } and { target.debuffremaining(colossus_smash) > 4.5 and not hasazeritetrait(test_of_might_trait) or buffpresent(test_of_might_buff) } spell(bladestorm_arms)
   #deadly_calm
   spell(deadly_calm)
  }
 }
}

AddFunction armsfive_targetshortcdpostconditions
{
 rage() < 60 and { not hastalent(deadly_calm_talent) or buffexpires(deadly_calm_buff) } and spell(skullsplitter) or target.debuffexpires(colossus_smash) and spell(warbreaker) or spell(cleave) or { not hastalent(cleave_talent) and target.debuffremaining(deep_wounds_arms_debuff) < 2 or { buffpresent(sudden_death_buff_arms) or buffpresent(stone_heart) } and { buffpresent(sweeping_strikes_buff) or spellcooldown(sweeping_strikes) > 8 } } and spell(execute_arms) or { not hastalent(cleave_talent) and target.debuffremaining(deep_wounds_arms_debuff) < 2 or buffpresent(sweeping_strikes_buff) and buffstacks(overpower_buff) == 2 and { hastalent(dreadnaught_talent) or 0 == 2 } } and spell(mortal_strike) or { target.debuffpresent(colossus_smash) or buffpresent(crushing_assault_buff) and hastalent(fervor_of_battle_talent) } and spell(whirlwind_arms) or { buffpresent(deadly_calm_buff) or rage() > 60 } and spell(whirlwind_arms) or spell(overpower) or spell(whirlwind_arms)
}

AddFunction armsfive_targetcdactions
{
}

AddFunction armsfive_targetcdpostconditions
{
 rage() < 60 and { not hastalent(deadly_calm_talent) or buffexpires(deadly_calm_buff) } and spell(skullsplitter) or { not hastalent(warbreaker_talent) or spellcooldown(warbreaker) < 2 } and spell(ravager) or target.debuffexpires(colossus_smash) and spell(colossus_smash) or target.debuffexpires(colossus_smash) and spell(warbreaker) or buffexpires(sweeping_strikes_buff) and { not hastalent(deadly_calm_talent) or buffexpires(deadly_calm_buff) } and { target.debuffremaining(colossus_smash) > 4.5 and not hasazeritetrait(test_of_might_trait) or buffpresent(test_of_might_buff) } and spell(bladestorm_arms) or spell(deadly_calm) or spell(cleave) or { not hastalent(cleave_talent) and target.debuffremaining(deep_wounds_arms_debuff) < 2 or { buffpresent(sudden_death_buff_arms) or buffpresent(stone_heart) } and { buffpresent(sweeping_strikes_buff) or spellcooldown(sweeping_strikes) > 8 } } and spell(execute_arms) or { not hastalent(cleave_talent) and target.debuffremaining(deep_wounds_arms_debuff) < 2 or buffpresent(sweeping_strikes_buff) and buffstacks(overpower_buff) == 2 and { hastalent(dreadnaught_talent) or 0 == 2 } } and spell(mortal_strike) or { target.debuffpresent(colossus_smash) or buffpresent(crushing_assault_buff) and hastalent(fervor_of_battle_talent) } and spell(whirlwind_arms) or { buffpresent(deadly_calm_buff) or rage() > 60 } and spell(whirlwind_arms) or spell(overpower) or spell(whirlwind_arms)
}

### actions.execute

AddFunction armsexecutemainactions
{
 #skullsplitter,if=rage<60&buff.deadly_calm.down&buff.memory_of_lucid_dreams.down
 if rage() < 60 and buffexpires(deadly_calm_buff) and buffexpires(memory_of_lucid_dreams_essence_buff) spell(skullsplitter)
 #warbreaker,if=!essence.memory_of_lucid_dreams.major|(buff.memory_of_lucid_dreams.up|cooldown.memory_of_lucid_dreams.remains>10)
 if not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or buffpresent(memory_of_lucid_dreams_essence_buff) or spellcooldown(memory_of_lucid_dreams_essence) > 10 spell(warbreaker)
 #cleave,if=spell_targets.whirlwind>2
 if enemies() > 2 spell(cleave)
 #slam,if=buff.crushing_assault.up&buff.memory_of_lucid_dreams.down
 if buffpresent(crushing_assault_buff) and buffexpires(memory_of_lucid_dreams_essence_buff) spell(slam)
 #mortal_strike,if=buff.overpower.stack=2&talent.dreadnaught.enabled|buff.executioners_precision.stack=2
 if buffstacks(overpower_buff) == 2 and hastalent(dreadnaught_talent) or 0 == 2 spell(mortal_strike)
 #execute,if=buff.memory_of_lucid_dreams.up|buff.deadly_calm.up|(buff.test_of_might.up&cooldown.memory_of_lucid_dreams.remains>94)
 if buffpresent(memory_of_lucid_dreams_essence_buff) or buffpresent(deadly_calm_buff) or buffpresent(test_of_might_buff) and spellcooldown(memory_of_lucid_dreams_essence) > 94 spell(execute_arms)
 #overpower
 spell(overpower)
 #execute
 spell(execute_arms)
}

AddFunction armsexecutemainpostconditions
{
}

AddFunction armsexecuteshortcdactions
{
 unless rage() < 60 and buffexpires(deadly_calm_buff) and buffexpires(memory_of_lucid_dreams_essence_buff) and spell(skullsplitter)
 {
  #ravager,if=!buff.deadly_calm.up&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if not buffpresent(deadly_calm_buff) and { spellcooldown(colossus_smash) < 2 or hastalent(warbreaker_talent) and spellcooldown(warbreaker) < 2 } spell(ravager)
  #colossus_smash,if=!essence.memory_of_lucid_dreams.major|(buff.memory_of_lucid_dreams.up|cooldown.memory_of_lucid_dreams.remains>10)
  if not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or buffpresent(memory_of_lucid_dreams_essence_buff) or spellcooldown(memory_of_lucid_dreams_essence) > 10 spell(colossus_smash)

  unless { not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or buffpresent(memory_of_lucid_dreams_essence_buff) or spellcooldown(memory_of_lucid_dreams_essence) > 10 } and spell(warbreaker)
  {
   #deadly_calm
   spell(deadly_calm)
   #bladestorm,if=!buff.memory_of_lucid_dreams.up&buff.test_of_might.up&rage<30&!buff.deadly_calm.up
   if not buffpresent(memory_of_lucid_dreams_essence_buff) and buffpresent(test_of_might_buff) and rage() < 30 and not buffpresent(deadly_calm_buff) spell(bladestorm_arms)
  }
 }
}

AddFunction armsexecuteshortcdpostconditions
{
 rage() < 60 and buffexpires(deadly_calm_buff) and buffexpires(memory_of_lucid_dreams_essence_buff) and spell(skullsplitter) or { not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or buffpresent(memory_of_lucid_dreams_essence_buff) or spellcooldown(memory_of_lucid_dreams_essence) > 10 } and spell(warbreaker) or enemies() > 2 and spell(cleave) or buffpresent(crushing_assault_buff) and buffexpires(memory_of_lucid_dreams_essence_buff) and spell(slam) or { buffstacks(overpower_buff) == 2 and hastalent(dreadnaught_talent) or 0 == 2 } and spell(mortal_strike) or { buffpresent(memory_of_lucid_dreams_essence_buff) or buffpresent(deadly_calm_buff) or buffpresent(test_of_might_buff) and spellcooldown(memory_of_lucid_dreams_essence) > 94 } and spell(execute_arms) or spell(overpower) or spell(execute_arms)
}

AddFunction armsexecutecdactions
{
}

AddFunction armsexecutecdpostconditions
{
 rage() < 60 and buffexpires(deadly_calm_buff) and buffexpires(memory_of_lucid_dreams_essence_buff) and spell(skullsplitter) or not buffpresent(deadly_calm_buff) and { spellcooldown(colossus_smash) < 2 or hastalent(warbreaker_talent) and spellcooldown(warbreaker) < 2 } and spell(ravager) or { not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or buffpresent(memory_of_lucid_dreams_essence_buff) or spellcooldown(memory_of_lucid_dreams_essence) > 10 } and spell(colossus_smash) or { not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or buffpresent(memory_of_lucid_dreams_essence_buff) or spellcooldown(memory_of_lucid_dreams_essence) > 10 } and spell(warbreaker) or spell(deadly_calm) or not buffpresent(memory_of_lucid_dreams_essence_buff) and buffpresent(test_of_might_buff) and rage() < 30 and not buffpresent(deadly_calm_buff) and spell(bladestorm_arms) or enemies() > 2 and spell(cleave) or buffpresent(crushing_assault_buff) and buffexpires(memory_of_lucid_dreams_essence_buff) and spell(slam) or { buffstacks(overpower_buff) == 2 and hastalent(dreadnaught_talent) or 0 == 2 } and spell(mortal_strike) or { buffpresent(memory_of_lucid_dreams_essence_buff) or buffpresent(deadly_calm_buff) or buffpresent(test_of_might_buff) and spellcooldown(memory_of_lucid_dreams_essence) > 94 } and spell(execute_arms) or spell(overpower) or spell(execute_arms)
}

### actions.default

AddFunction arms_defaultmainactions
{
 #charge
 if checkboxon(opt_melee_range) and target.inrange(charge) and not target.inrange(pummel) spell(charge)
 #avatar,if=cooldown.colossus_smash.remains<8|(talent.warbreaker.enabled&cooldown.warbreaker.remains<8)
 if spellcooldown(colossus_smash) < 8 or hastalent(warbreaker_talent) and spellcooldown(warbreaker) < 8 spell(avatar)
 #sweeping_strikes,if=spell_targets.whirlwind>1&(cooldown.bladestorm.remains>10|cooldown.colossus_smash.remains>8|azerite.test_of_might.enabled)
 if enemies() > 1 and { spellcooldown(bladestorm_arms) > 10 or spellcooldown(colossus_smash) > 8 or hasazeritetrait(test_of_might_trait) } spell(sweeping_strikes)
 #concentrated_flame,if=!debuff.colossus_smash.up&!buff.test_of_might.up&dot.concentrated_flame_burn.remains=0
 if not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 spell(concentrated_flame_essence)
 #run_action_list,name=hac,if=raid_event.adds.exists
 if false(raid_event_adds_exists) armshacmainactions()

 unless false(raid_event_adds_exists) and armshacmainpostconditions()
 {
  #run_action_list,name=five_target,if=spell_targets.whirlwind>4
  if enemies() > 4 armsfive_targetmainactions()

  unless enemies() > 4 and armsfive_targetmainpostconditions()
  {
   #run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
   if hastalent(massacre_talent) and target.healthpercent() < 35 or target.healthpercent() < 20 armsexecutemainactions()

   unless { hastalent(massacre_talent) and target.healthpercent() < 35 or target.healthpercent() < 20 } and armsexecutemainpostconditions()
   {
    #run_action_list,name=single_target
    armssingle_targetmainactions()
   }
  }
 }
}

AddFunction arms_defaultmainpostconditions
{
 false(raid_event_adds_exists) and armshacmainpostconditions() or enemies() > 4 and armsfive_targetmainpostconditions() or { hastalent(massacre_talent) and target.healthpercent() < 35 or target.healthpercent() < 20 } and armsexecutemainpostconditions() or armssingle_targetmainpostconditions()
}

AddFunction arms_defaultshortcdactions
{
 unless checkboxon(opt_melee_range) and target.inrange(charge) and not target.inrange(pummel) and spell(charge)
 {
  #auto_attack
  armsgetinmeleerange()
  #bag_of_tricks,if=buff.memory_of_lucid_dreams.remains<5|(!essence.memory_of_lucid_dreams.major&debuff.colossus_smash.up)
  if buffremaining(memory_of_lucid_dreams_essence_buff) < 5 or not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and target.debuffpresent(colossus_smash) spell(bag_of_tricks)

  unless { spellcooldown(colossus_smash) < 8 or hastalent(warbreaker_talent) and spellcooldown(warbreaker) < 8 } and spell(avatar) or enemies() > 1 and { spellcooldown(bladestorm_arms) > 10 or spellcooldown(colossus_smash) > 8 or hasazeritetrait(test_of_might_trait) } and spell(sweeping_strikes)
  {
   #purifying_blast,if=!debuff.colossus_smash.up&!buff.test_of_might.up
   if not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) spell(purifying_blast)
   #ripple_in_space,if=!debuff.colossus_smash.up&!buff.test_of_might.up
   if not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) spell(ripple_in_space_essence)
   #worldvein_resonance,if=!debuff.colossus_smash.up&!buff.test_of_might.up
   if not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) spell(worldvein_resonance_essence)
   #reaping_flames,if=!debuff.colossus_smash.up&!buff.test_of_might.up
   if not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) spell(reaping_flames)

   unless not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence)
   {
    #the_unbound_force,if=buff.reckless_force.up
    if buffpresent(reckless_force_buff) spell(the_unbound_force)
    #run_action_list,name=hac,if=raid_event.adds.exists
    if false(raid_event_adds_exists) armshacshortcdactions()

    unless false(raid_event_adds_exists) and armshacshortcdpostconditions()
    {
     #run_action_list,name=five_target,if=spell_targets.whirlwind>4
     if enemies() > 4 armsfive_targetshortcdactions()

     unless enemies() > 4 and armsfive_targetshortcdpostconditions()
     {
      #run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
      if hastalent(massacre_talent) and target.healthpercent() < 35 or target.healthpercent() < 20 armsexecuteshortcdactions()

      unless { hastalent(massacre_talent) and target.healthpercent() < 35 or target.healthpercent() < 20 } and armsexecuteshortcdpostconditions()
      {
       #run_action_list,name=single_target
       armssingle_targetshortcdactions()
      }
     }
    }
   }
  }
 }
}

AddFunction arms_defaultshortcdpostconditions
{
 checkboxon(opt_melee_range) and target.inrange(charge) and not target.inrange(pummel) and spell(charge) or { spellcooldown(colossus_smash) < 8 or hastalent(warbreaker_talent) and spellcooldown(warbreaker) < 8 } and spell(avatar) or enemies() > 1 and { spellcooldown(bladestorm_arms) > 10 or spellcooldown(colossus_smash) > 8 or hasazeritetrait(test_of_might_trait) } and spell(sweeping_strikes) or not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence) or false(raid_event_adds_exists) and armshacshortcdpostconditions() or enemies() > 4 and armsfive_targetshortcdpostconditions() or { hastalent(massacre_talent) and target.healthpercent() < 35 or target.healthpercent() < 20 } and armsexecuteshortcdpostconditions() or armssingle_targetshortcdpostconditions()
}

AddFunction arms_defaultcdactions
{
 armsinterruptactions()

 unless checkboxon(opt_melee_range) and target.inrange(charge) and not target.inrange(pummel) and spell(charge)
 {
  #potion,if=target.health.pct<21&buff.memory_of_lucid_dreams.up|!essence.memory_of_lucid_dreams.major
  if { target.healthpercent() < 21 and buffpresent(memory_of_lucid_dreams_essence_buff) or not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)
  #blood_fury,if=buff.memory_of_lucid_dreams.remains<5|(!essence.memory_of_lucid_dreams.major&debuff.colossus_smash.up)
  if buffremaining(memory_of_lucid_dreams_essence_buff) < 5 or not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and target.debuffpresent(colossus_smash) spell(blood_fury_ap)
  #berserking,if=buff.memory_of_lucid_dreams.up|(!essence.memory_of_lucid_dreams.major&debuff.colossus_smash.up)
  if buffpresent(memory_of_lucid_dreams_essence_buff) or not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and target.debuffpresent(colossus_smash) spell(berserking)
  #arcane_torrent,if=cooldown.mortal_strike.remains>1.5&buff.memory_of_lucid_dreams.down&rage<50
  if spellcooldown(mortal_strike) > 1.5 and buffexpires(memory_of_lucid_dreams_essence_buff) and rage() < 50 spell(arcane_torrent_rage)
  #lights_judgment,if=debuff.colossus_smash.down
  if target.debuffexpires(colossus_smash) spell(lights_judgment)
  #fireblood,if=buff.memory_of_lucid_dreams.remains<5|(!essence.memory_of_lucid_dreams.major&debuff.colossus_smash.up)
  if buffremaining(memory_of_lucid_dreams_essence_buff) < 5 or not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and target.debuffpresent(colossus_smash) spell(fireblood)
  #ancestral_call,if=buff.memory_of_lucid_dreams.remains<5|(!essence.memory_of_lucid_dreams.major&debuff.colossus_smash.up)
  if buffremaining(memory_of_lucid_dreams_essence_buff) < 5 or not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and target.debuffpresent(colossus_smash) spell(ancestral_call)

  unless { buffremaining(memory_of_lucid_dreams_essence_buff) < 5 or not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and target.debuffpresent(colossus_smash) } and spell(bag_of_tricks)
  {
   #use_item,name=ashvanes_razor_coral,if=!debuff.razor_coral_debuff.up|(target.health.pct<20.1&buff.memory_of_lucid_dreams.up&cooldown.memory_of_lucid_dreams.remains<117)|(target.health.pct<30.1&debuff.conductive_ink_debuff.up&!essence.memory_of_lucid_dreams.major)|(!debuff.conductive_ink_debuff.up&!essence.memory_of_lucid_dreams.major&debuff.colossus_smash.up)|target.time_to_die<30
   if not target.debuffpresent(razor_coral) or target.healthpercent() < 20.1 and buffpresent(memory_of_lucid_dreams_essence_buff) and spellcooldown(memory_of_lucid_dreams_essence) < 117 or target.healthpercent() < 30.1 and target.debuffpresent(conductive_ink) and not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or not target.debuffpresent(conductive_ink) and not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and target.debuffpresent(colossus_smash) or target.timetodie() < 30 armsuseitemactions()

   unless { spellcooldown(colossus_smash) < 8 or hastalent(warbreaker_talent) and spellcooldown(warbreaker) < 8 } and spell(avatar) or enemies() > 1 and { spellcooldown(bladestorm_arms) > 10 or spellcooldown(colossus_smash) > 8 or hasazeritetrait(test_of_might_trait) } and spell(sweeping_strikes)
   {
    #blood_of_the_enemy,if=buff.test_of_might.up|(debuff.colossus_smash.up&!azerite.test_of_might.enabled)
    if buffpresent(test_of_might_buff) or target.debuffpresent(colossus_smash) and not hasazeritetrait(test_of_might_trait) spell(blood_of_the_enemy)

    unless not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) and spell(purifying_blast) or not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) and spell(ripple_in_space_essence) or not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) and spell(worldvein_resonance_essence)
    {
     #focused_azerite_beam,if=!debuff.colossus_smash.up&!buff.test_of_might.up
     if not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) spell(focused_azerite_beam)

     unless not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) and spell(reaping_flames) or not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence) or buffpresent(reckless_force_buff) and spell(the_unbound_force)
     {
      #guardian_of_azeroth,if=cooldown.colossus_smash.remains<10
      if spellcooldown(colossus_smash) < 10 spell(guardian_of_azeroth)
      #memory_of_lucid_dreams,if=!talent.warbreaker.enabled&cooldown.colossus_smash.remains<gcd&(target.time_to_die>150|target.health.pct<20)
      if not hastalent(warbreaker_talent) and spellcooldown(colossus_smash) < gcd() and { target.timetodie() > 150 or target.healthpercent() < 20 } spell(memory_of_lucid_dreams_essence)
      #memory_of_lucid_dreams,if=talent.warbreaker.enabled&cooldown.warbreaker.remains<gcd&(target.time_to_die>150|target.health.pct<20)
      if hastalent(warbreaker_talent) and spellcooldown(warbreaker) < gcd() and { target.timetodie() > 150 or target.healthpercent() < 20 } spell(memory_of_lucid_dreams_essence)
      #run_action_list,name=hac,if=raid_event.adds.exists
      if false(raid_event_adds_exists) armshaccdactions()

      unless false(raid_event_adds_exists) and armshaccdpostconditions()
      {
       #run_action_list,name=five_target,if=spell_targets.whirlwind>4
       if enemies() > 4 armsfive_targetcdactions()

       unless enemies() > 4 and armsfive_targetcdpostconditions()
       {
        #run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
        if hastalent(massacre_talent) and target.healthpercent() < 35 or target.healthpercent() < 20 armsexecutecdactions()

        unless { hastalent(massacre_talent) and target.healthpercent() < 35 or target.healthpercent() < 20 } and armsexecutecdpostconditions()
        {
         #run_action_list,name=single_target
         armssingle_targetcdactions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction arms_defaultcdpostconditions
{
 checkboxon(opt_melee_range) and target.inrange(charge) and not target.inrange(pummel) and spell(charge) or { buffremaining(memory_of_lucid_dreams_essence_buff) < 5 or not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and target.debuffpresent(colossus_smash) } and spell(bag_of_tricks) or { spellcooldown(colossus_smash) < 8 or hastalent(warbreaker_talent) and spellcooldown(warbreaker) < 8 } and spell(avatar) or enemies() > 1 and { spellcooldown(bladestorm_arms) > 10 or spellcooldown(colossus_smash) > 8 or hasazeritetrait(test_of_might_trait) } and spell(sweeping_strikes) or not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) and spell(purifying_blast) or not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) and spell(ripple_in_space_essence) or not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) and spell(worldvein_resonance_essence) or not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) and spell(reaping_flames) or not target.debuffpresent(colossus_smash) and not buffpresent(test_of_might_buff) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or false(raid_event_adds_exists) and armshaccdpostconditions() or enemies() > 4 and armsfive_targetcdpostconditions() or { hastalent(massacre_talent) and target.healthpercent() < 35 or target.healthpercent() < 20 } and armsexecutecdpostconditions() or armssingle_targetcdpostconditions()
}

### Arms icons.

AddCheckBox(opt_warrior_arms_aoe l(aoe) default specialization=arms)

AddIcon checkbox=!opt_warrior_arms_aoe enemies=1 help=shortcd specialization=arms
{
 if not incombat() armsprecombatshortcdactions()
 arms_defaultshortcdactions()
}

AddIcon checkbox=opt_warrior_arms_aoe help=shortcd specialization=arms
{
 if not incombat() armsprecombatshortcdactions()
 arms_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=arms
{
 if not incombat() armsprecombatmainactions()
 arms_defaultmainactions()
}

AddIcon checkbox=opt_warrior_arms_aoe help=aoe specialization=arms
{
 if not incombat() armsprecombatmainactions()
 arms_defaultmainactions()
}

AddIcon checkbox=!opt_warrior_arms_aoe enemies=1 help=cd specialization=arms
{
 if not incombat() armsprecombatcdactions()
 arms_defaultcdactions()
}

AddIcon checkbox=opt_warrior_arms_aoe help=cd specialization=arms
{
 if not incombat() armsprecombatcdactions()
 arms_defaultcdactions()
}

### Required symbols
# ancestral_call
# anger_management_talent
# arcane_torrent_rage
# avatar
# bag_of_tricks
# berserking
# bladestorm_arms
# blood_fury_ap
# blood_of_the_enemy
# charge
# cleave
# cleave_talent
# colossus_smash
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# conductive_ink
# crushing_assault_buff
# deadly_calm
# deadly_calm_buff
# deadly_calm_talent
# deep_wounds_arms_debuff
# dreadnaught_talent
# execute_arms
# fervor_of_battle_talent
# fireblood
# focused_azerite_beam
# focused_resolve_item
# guardian_of_azeroth
# heroic_leap
# intimidating_shout
# lights_judgment
# massacre_talent
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# memory_of_lucid_dreams_essence_id
# mortal_strike
# overpower
# overpower_buff
# pummel
# purifying_blast
# quaking_palm
# ravager
# ravager_talent
# razor_coral
# reaping_flames
# reckless_force_buff
# rend
# rend_debuff
# ripple_in_space_essence
# seismic_wave_trait
# shockwave
# skullsplitter
# slam
# stone_heart
# storm_bolt
# sudden_death_buff_arms
# sweeping_strikes
# sweeping_strikes_buff
# test_of_might_buff
# test_of_might_trait
# the_unbound_force
# war_stomp
# warbreaker
# warbreaker_talent
# whirlwind_arms
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("WARRIOR", "arms", name, desc, code, "script")
    end
    do
        local name = "sc_t24_warrior_fury"
        local desc = "[8.3] Simulationcraft: T24_Warrior_Fury"
        local code = [[
# Based on SimulationCraft profile "T24_Warrior_Fury".
#	class=warrior
#	spec=fury
#	talents=2133123

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=fury)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=fury)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=fury)

AddFunction furyinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(pummel) and target.isinterruptible() spell(pummel)
  if target.inrange(storm_bolt) and not target.classification(worldboss) spell(storm_bolt)
  if target.distance(less 10) and not target.classification(worldboss) spell(shockwave)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
  if target.inrange(intimidating_shout) and not target.classification(worldboss) spell(intimidating_shout)
 }
}

AddFunction furyuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction furygetinmeleerange
{
 if checkboxon(opt_melee_range) and not inflighttotarget(charge) and not inflighttotarget(heroic_leap) and not target.inrange(pummel)
 {
  if target.inrange(charge) spell(charge)
  if spellcharges(charge) == 0 and target.distance(atleast 8) and target.distance(atmost 40) spell(heroic_leap)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.single_target

AddFunction furysingle_targetmainactions
{
 #rampage,if=(buff.recklessness.up|buff.memory_of_lucid_dreams.up)|(talent.frothing_berserker.enabled|talent.carnage.enabled&(buff.enrage.remains<gcd|rage>90)|talent.massacre.enabled&(buff.enrage.remains<gcd|rage>90))
 if buffpresent(recklessness_buff) or buffpresent(memory_of_lucid_dreams_essence_buff) or hastalent(frothing_berserker_talent) or hastalent(carnage_talent) and { enrageremaining() < gcd() or rage() > 90 } or hastalent(massacre_talent_fury) and { enrageremaining() < gcd() or rage() > 90 } spell(rampage)
 #execute
 spell(execute)
 #furious_slash,if=!buff.bloodlust.up&buff.furious_slash.remains<3
 if not buffpresent(bloodlust) and buffremaining(furious_slash_buff) < 3 spell(furious_slash)
 #bloodthirst,if=buff.enrage.down|azerite.cold_steel_hot_blood.rank>1
 if not isenraged() or azeritetraitrank(cold_steel_hot_blood_trait) > 1 spell(bloodthirst)
 #dragon_roar,if=buff.enrage.up
 if isenraged() spell(dragon_roar)
 #raging_blow,if=charges=2
 if charges(raging_blow) == 2 spell(raging_blow)
 #bloodthirst
 spell(bloodthirst)
 #raging_blow,if=talent.carnage.enabled|(talent.massacre.enabled&rage<80)|(talent.frothing_berserker.enabled&rage<90)
 if hastalent(carnage_talent) or hastalent(massacre_talent_fury) and rage() < 80 or hastalent(frothing_berserker_talent) and rage() < 90 spell(raging_blow)
 #furious_slash,if=talent.furious_slash.enabled
 if hastalent(furious_slash_talent) spell(furious_slash)
 #whirlwind
 spell(whirlwind_fury)
}

AddFunction furysingle_targetmainpostconditions
{
}

AddFunction furysingle_targetshortcdactions
{
 #siegebreaker
 spell(siegebreaker)

 unless { buffpresent(recklessness_buff) or buffpresent(memory_of_lucid_dreams_essence_buff) or hastalent(frothing_berserker_talent) or hastalent(carnage_talent) and { enrageremaining() < gcd() or rage() > 90 } or hastalent(massacre_talent_fury) and { enrageremaining() < gcd() or rage() > 90 } } and spell(rampage) or spell(execute) or not buffpresent(bloodlust) and buffremaining(furious_slash_buff) < 3 and spell(furious_slash)
 {
  #bladestorm,if=prev_gcd.1.rampage
  if previousgcdspell(rampage) spell(bladestorm_fury)
 }
}

AddFunction furysingle_targetshortcdpostconditions
{
 { buffpresent(recklessness_buff) or buffpresent(memory_of_lucid_dreams_essence_buff) or hastalent(frothing_berserker_talent) or hastalent(carnage_talent) and { enrageremaining() < gcd() or rage() > 90 } or hastalent(massacre_talent_fury) and { enrageremaining() < gcd() or rage() > 90 } } and spell(rampage) or spell(execute) or not buffpresent(bloodlust) and buffremaining(furious_slash_buff) < 3 and spell(furious_slash) or { not isenraged() or azeritetraitrank(cold_steel_hot_blood_trait) > 1 } and spell(bloodthirst) or isenraged() and spell(dragon_roar) or charges(raging_blow) == 2 and spell(raging_blow) or spell(bloodthirst) or { hastalent(carnage_talent) or hastalent(massacre_talent_fury) and rage() < 80 or hastalent(frothing_berserker_talent) and rage() < 90 } and spell(raging_blow) or hastalent(furious_slash_talent) and spell(furious_slash) or spell(whirlwind_fury)
}

AddFunction furysingle_targetcdactions
{
}

AddFunction furysingle_targetcdpostconditions
{
 spell(siegebreaker) or { buffpresent(recklessness_buff) or buffpresent(memory_of_lucid_dreams_essence_buff) or hastalent(frothing_berserker_talent) or hastalent(carnage_talent) and { enrageremaining() < gcd() or rage() > 90 } or hastalent(massacre_talent_fury) and { enrageremaining() < gcd() or rage() > 90 } } and spell(rampage) or spell(execute) or not buffpresent(bloodlust) and buffremaining(furious_slash_buff) < 3 and spell(furious_slash) or previousgcdspell(rampage) and spell(bladestorm_fury) or { not isenraged() or azeritetraitrank(cold_steel_hot_blood_trait) > 1 } and spell(bloodthirst) or isenraged() and spell(dragon_roar) or charges(raging_blow) == 2 and spell(raging_blow) or spell(bloodthirst) or { hastalent(carnage_talent) or hastalent(massacre_talent_fury) and rage() < 80 or hastalent(frothing_berserker_talent) and rage() < 90 } and spell(raging_blow) or hastalent(furious_slash_talent) and spell(furious_slash) or spell(whirlwind_fury)
}

### actions.precombat

AddFunction furyprecombatmainactions
{
}

AddFunction furyprecombatmainpostconditions
{
}

AddFunction furyprecombatshortcdactions
{
 #worldvein_resonance
 spell(worldvein_resonance_essence)
}

AddFunction furyprecombatshortcdpostconditions
{
}

AddFunction furyprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #use_item,name=azsharas_font_of_power
 furyuseitemactions()

 unless spell(worldvein_resonance_essence)
 {
  #memory_of_lucid_dreams
  spell(memory_of_lucid_dreams_essence)
  #guardian_of_azeroth
  spell(guardian_of_azeroth)
  #recklessness
  spell(recklessness)
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 }
}

AddFunction furyprecombatcdpostconditions
{
 spell(worldvein_resonance_essence)
}

### actions.movement

AddFunction furymovementmainactions
{
}

AddFunction furymovementmainpostconditions
{
}

AddFunction furymovementshortcdactions
{
 #heroic_leap
 if checkboxon(opt_melee_range) and target.distance(atleast 8) and target.distance(atmost 40) spell(heroic_leap)
}

AddFunction furymovementshortcdpostconditions
{
}

AddFunction furymovementcdactions
{
}

AddFunction furymovementcdpostconditions
{
 checkboxon(opt_melee_range) and target.distance(atleast 8) and target.distance(atmost 40) and spell(heroic_leap)
}

### actions.default

AddFunction fury_defaultmainactions
{
 #charge
 if checkboxon(opt_melee_range) and target.inrange(charge) and not target.inrange(pummel) spell(charge)
 #run_action_list,name=movement,if=movement.distance>5
 if target.distance() > 5 furymovementmainactions()

 unless target.distance() > 5 and furymovementmainpostconditions()
 {
  #rampage,if=cooldown.recklessness.remains<3
  if spellcooldown(recklessness) < 3 spell(rampage)
  #concentrated_flame,if=!buff.recklessness.up&!buff.siegebreaker.up&dot.concentrated_flame_burn.remains=0
  if not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 spell(concentrated_flame_essence)
  #whirlwind,if=spell_targets.whirlwind>1&!buff.meat_cleaver.up
  if enemies() > 1 and not buffpresent(whirlwind_buff) spell(whirlwind_fury)
  #run_action_list,name=single_target
  furysingle_targetmainactions()
 }
}

AddFunction fury_defaultmainpostconditions
{
 target.distance() > 5 and furymovementmainpostconditions() or furysingle_targetmainpostconditions()
}

AddFunction fury_defaultshortcdactions
{
 #auto_attack
 furygetinmeleerange()

 unless checkboxon(opt_melee_range) and target.inrange(charge) and not target.inrange(pummel) and spell(charge)
 {
  #run_action_list,name=movement,if=movement.distance>5
  if target.distance() > 5 furymovementshortcdactions()

  unless target.distance() > 5 and furymovementshortcdpostconditions()
  {
   #heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)
   if target.distance() > 25 and 600 > 45 and checkboxon(opt_melee_range) and target.distance(atleast 8) and target.distance(atmost 40) spell(heroic_leap)

   unless spellcooldown(recklessness) < 3 and spell(rampage)
   {
    #purifying_blast,if=!buff.recklessness.up&!buff.siegebreaker.up
    if not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) spell(purifying_blast)
    #ripple_in_space,if=!buff.recklessness.up&!buff.siegebreaker.up
    if not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) spell(ripple_in_space_essence)
    #worldvein_resonance,if=!buff.recklessness.up&!buff.siegebreaker.up
    if not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) spell(worldvein_resonance_essence)
    #reaping_flames,if=!buff.recklessness.up&!buff.siegebreaker.up
    if not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) spell(reaping_flames)

    unless not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence)
    {
     #the_unbound_force,if=buff.reckless_force.up
     if buffpresent(reckless_force_buff) spell(the_unbound_force)

     unless enemies() > 1 and not buffpresent(whirlwind_buff) and spell(whirlwind_fury)
     {
      #bag_of_tricks,if=buff.recklessness.up
      if buffpresent(recklessness_buff) spell(bag_of_tricks)
      #run_action_list,name=single_target
      furysingle_targetshortcdactions()
     }
    }
   }
  }
 }
}

AddFunction fury_defaultshortcdpostconditions
{
 checkboxon(opt_melee_range) and target.inrange(charge) and not target.inrange(pummel) and spell(charge) or target.distance() > 5 and furymovementshortcdpostconditions() or spellcooldown(recklessness) < 3 and spell(rampage) or not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence) or enemies() > 1 and not buffpresent(whirlwind_buff) and spell(whirlwind_fury) or furysingle_targetshortcdpostconditions()
}

AddFunction fury_defaultcdactions
{
 furyinterruptactions()

 unless checkboxon(opt_melee_range) and target.inrange(charge) and not target.inrange(pummel) and spell(charge)
 {
  #run_action_list,name=movement,if=movement.distance>5
  if target.distance() > 5 furymovementcdactions()

  unless target.distance() > 5 and furymovementcdpostconditions() or target.distance() > 25 and 600 > 45 and checkboxon(opt_melee_range) and target.distance(atleast 8) and target.distance(atmost 40) and spell(heroic_leap)
  {
   #potion,if=buff.guardian_of_azeroth.up|(!essence.condensed_lifeforce.major&target.time_to_die=60)
   if { buffpresent(guardian_of_azeroth_buff) or not azeriteessenceismajor(condensed_life_force_essence_id) and target.timetodie() == 60 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

   unless spellcooldown(recklessness) < 3 and spell(rampage)
   {
    #blood_of_the_enemy,if=buff.recklessness.up
    if buffpresent(recklessness_buff) spell(blood_of_the_enemy)

    unless not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) and spell(purifying_blast) or not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) and spell(ripple_in_space_essence) or not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) and spell(worldvein_resonance_essence)
    {
     #focused_azerite_beam,if=!buff.recklessness.up&!buff.siegebreaker.up
     if not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) spell(focused_azerite_beam)

     unless not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) and spell(reaping_flames) or not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence) or buffpresent(reckless_force_buff) and spell(the_unbound_force)
     {
      #guardian_of_azeroth,if=!buff.recklessness.up&(target.time_to_die>195|target.health.pct<20)
      if not buffpresent(recklessness_buff) and { target.timetodie() > 195 or target.healthpercent() < 20 } spell(guardian_of_azeroth)
      #memory_of_lucid_dreams,if=!buff.recklessness.up
      if not buffpresent(recklessness_buff) spell(memory_of_lucid_dreams_essence)
      #recklessness,if=!essence.condensed_lifeforce.major&!essence.blood_of_the_enemy.major|cooldown.guardian_of_azeroth.remains>1|buff.guardian_of_azeroth.up|cooldown.blood_of_the_enemy.remains<gcd
      if not azeriteessenceismajor(condensed_life_force_essence_id) and not azeriteessenceismajor(blood_of_the_enemy_essence_id) or spellcooldown(guardian_of_azeroth) > 1 or buffpresent(guardian_of_azeroth_buff) or spellcooldown(blood_of_the_enemy) < gcd() spell(recklessness)

      unless enemies() > 1 and not buffpresent(whirlwind_buff) and spell(whirlwind_fury)
      {
       #use_item,name=ashvanes_razor_coral,if=target.time_to_die<20|!debuff.razor_coral_debuff.up|(target.health.pct<30.1&debuff.conductive_ink_debuff.up)|(!debuff.conductive_ink_debuff.up&buff.memory_of_lucid_dreams.up|prev_gcd.2.guardian_of_azeroth|prev_gcd.2.recklessness&(!essence.memory_of_lucid_dreams.major&!essence.condensed_lifeforce.major))
       if target.timetodie() < 20 or not target.debuffpresent(razor_coral) or target.healthpercent() < 30.1 and target.debuffpresent(conductive_ink) or not target.debuffpresent(conductive_ink) and buffpresent(memory_of_lucid_dreams_essence_buff) or previousgcdspell(guardian_of_azeroth count=2) or previousgcdspell(recklessness count=2) and not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and not azeriteessenceismajor(condensed_life_force_essence_id) furyuseitemactions()
       #blood_fury,if=buff.recklessness.up
       if buffpresent(recklessness_buff) spell(blood_fury_ap)
       #berserking,if=buff.recklessness.up
       if buffpresent(recklessness_buff) spell(berserking)
       #lights_judgment,if=buff.recklessness.down
       if buffexpires(recklessness_buff) spell(lights_judgment)
       #fireblood,if=buff.recklessness.up
       if buffpresent(recklessness_buff) spell(fireblood)
       #ancestral_call,if=buff.recklessness.up
       if buffpresent(recklessness_buff) spell(ancestral_call)

       unless buffpresent(recklessness_buff) and spell(bag_of_tricks)
       {
        #run_action_list,name=single_target
        furysingle_targetcdactions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction fury_defaultcdpostconditions
{
 checkboxon(opt_melee_range) and target.inrange(charge) and not target.inrange(pummel) and spell(charge) or target.distance() > 5 and furymovementcdpostconditions() or target.distance() > 25 and 600 > 45 and checkboxon(opt_melee_range) and target.distance(atleast 8) and target.distance(atmost 40) and spell(heroic_leap) or spellcooldown(recklessness) < 3 and spell(rampage) or not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) and spell(purifying_blast) or not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) and spell(ripple_in_space_essence) or not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) and spell(worldvein_resonance_essence) or not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) and spell(reaping_flames) or not buffpresent(recklessness_buff) and not buffpresent(siegebreaker) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or enemies() > 1 and not buffpresent(whirlwind_buff) and spell(whirlwind_fury) or buffpresent(recklessness_buff) and spell(bag_of_tricks) or furysingle_targetcdpostconditions()
}

### Fury icons.

AddCheckBox(opt_warrior_fury_aoe l(aoe) default specialization=fury)

AddIcon checkbox=!opt_warrior_fury_aoe enemies=1 help=shortcd specialization=fury
{
 if not incombat() furyprecombatshortcdactions()
 fury_defaultshortcdactions()
}

AddIcon checkbox=opt_warrior_fury_aoe help=shortcd specialization=fury
{
 if not incombat() furyprecombatshortcdactions()
 fury_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=fury
{
 if not incombat() furyprecombatmainactions()
 fury_defaultmainactions()
}

AddIcon checkbox=opt_warrior_fury_aoe help=aoe specialization=fury
{
 if not incombat() furyprecombatmainactions()
 fury_defaultmainactions()
}

AddIcon checkbox=!opt_warrior_fury_aoe enemies=1 help=cd specialization=fury
{
 if not incombat() furyprecombatcdactions()
 fury_defaultcdactions()
}

AddIcon checkbox=opt_warrior_fury_aoe help=cd specialization=fury
{
 if not incombat() furyprecombatcdactions()
 fury_defaultcdactions()
}

### Required symbols
# ancestral_call
# bag_of_tricks
# berserking
# bladestorm_fury
# blood_fury_ap
# blood_of_the_enemy
# blood_of_the_enemy_essence_id
# bloodlust
# bloodthirst
# carnage_talent
# charge
# cold_steel_hot_blood_trait
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# condensed_life_force_essence_id
# conductive_ink
# dragon_roar
# execute
# fireblood
# focused_azerite_beam
# frothing_berserker_talent
# furious_slash
# furious_slash_buff
# furious_slash_talent
# guardian_of_azeroth
# guardian_of_azeroth_buff
# heroic_leap
# intimidating_shout
# lights_judgment
# massacre_talent_fury
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# memory_of_lucid_dreams_essence_id
# pummel
# purifying_blast
# quaking_palm
# raging_blow
# rampage
# razor_coral
# reaping_flames
# reckless_force_buff
# recklessness
# recklessness_buff
# ripple_in_space_essence
# shockwave
# siegebreaker
# storm_bolt
# the_unbound_force
# unbridled_fury_item
# war_stomp
# whirlwind_buff
# whirlwind_fury
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("WARRIOR", "fury", name, desc, code, "script")
    end
    do
        local name = "sc_t24_warrior_protection"
        local desc = "[8.3] Simulationcraft: T24_Warrior_Protection"
        local code = [[
# Based on SimulationCraft profile "T24_Warrior_Protection".
#	class=warrior
#	spec=protection
#	talents=1223231

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=protection)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=protection)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=protection)

AddFunction protectioninterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(pummel) and target.isinterruptible() spell(pummel)
  if target.inrange(storm_bolt) and not target.classification(worldboss) spell(storm_bolt)
  if target.distance(less 10) and not target.classification(worldboss) spell(shockwave)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
  if target.inrange(intimidating_shout) and not target.classification(worldboss) spell(intimidating_shout)
 }
}

AddFunction protectionuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction protectiongetinmeleerange
{
 if checkboxon(opt_melee_range) and not inflighttotarget(intercept) and not inflighttotarget(heroic_leap) and not target.inrange(pummel)
 {
  if target.inrange(intercept) spell(intercept)
  if spellcharges(intercept) == 0 and target.distance(atleast 8) and target.distance(atmost 40) spell(heroic_leap)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.st

AddFunction protectionstmainactions
{
 #thunder_clap,if=spell_targets.thunder_clap=2&talent.unstoppable_force.enabled&buff.avatar.up
 if enemies() == 2 and hastalent(unstoppable_force_talent) and buffpresent(avatar) spell(thunder_clap)
 #shield_block,if=cooldown.shield_slam.ready&buff.shield_block.down
 if spellcooldown(shield_slam) == 0 and buffexpires(shield_block_buff) spell(shield_block)
 #shield_slam,if=buff.shield_block.up
 if buffpresent(shield_block_buff) spell(shield_slam)
 #thunder_clap,if=(talent.unstoppable_force.enabled&buff.avatar.up)
 if hastalent(unstoppable_force_talent) and buffpresent(avatar) spell(thunder_clap)
 #shield_slam
 spell(shield_slam)
 #dragon_roar
 spell(dragon_roar)
 #thunder_clap
 spell(thunder_clap)
 #revenge
 spell(revenge)
 #devastate
 spell(devastate)
}

AddFunction protectionstmainpostconditions
{
}

AddFunction protectionstshortcdactions
{
 unless enemies() == 2 and hastalent(unstoppable_force_talent) and buffpresent(avatar) and spell(thunder_clap) or spellcooldown(shield_slam) == 0 and buffexpires(shield_block_buff) and spell(shield_block) or buffpresent(shield_block_buff) and spell(shield_slam) or hastalent(unstoppable_force_talent) and buffpresent(avatar) and spell(thunder_clap)
 {
  #demoralizing_shout,if=talent.booming_voice.enabled
  if hastalent(booming_voice_talent) spell(demoralizing_shout)

  unless spell(shield_slam) or spell(dragon_roar) or spell(thunder_clap) or spell(revenge)
  {
   #ravager
   spell(ravager_protection)
  }
 }
}

AddFunction protectionstshortcdpostconditions
{
 enemies() == 2 and hastalent(unstoppable_force_talent) and buffpresent(avatar) and spell(thunder_clap) or spellcooldown(shield_slam) == 0 and buffexpires(shield_block_buff) and spell(shield_block) or buffpresent(shield_block_buff) and spell(shield_slam) or hastalent(unstoppable_force_talent) and buffpresent(avatar) and spell(thunder_clap) or spell(shield_slam) or spell(dragon_roar) or spell(thunder_clap) or spell(revenge) or spell(devastate)
}

AddFunction protectionstcdactions
{
 unless enemies() == 2 and hastalent(unstoppable_force_talent) and buffpresent(avatar) and spell(thunder_clap) or spellcooldown(shield_slam) == 0 and buffexpires(shield_block_buff) and spell(shield_block) or buffpresent(shield_block_buff) and spell(shield_slam) or hastalent(unstoppable_force_talent) and buffpresent(avatar) and spell(thunder_clap) or hastalent(booming_voice_talent) and spell(demoralizing_shout)
 {
  #anima_of_death,if=buff.last_stand.up
  if buffpresent(last_stand_buff) spell(anima_of_death)

  unless spell(shield_slam)
  {
   #use_item,name=ashvanes_razor_coral,target_if=debuff.razor_coral_debuff.stack=0
   if target.debuffstacks(razor_coral) == 0 protectionuseitemactions()
   #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.stack>7&(cooldown.avatar.remains<5|buff.avatar.up)
   if target.debuffstacks(razor_coral) > 7 and { spellcooldown(avatar) < 5 or buffpresent(avatar) } protectionuseitemactions()

   unless spell(dragon_roar) or spell(thunder_clap) or spell(revenge)
   {
    #use_item,name=grongs_primal_rage,if=buff.avatar.down|cooldown.shield_slam.remains>=4
    if buffexpires(avatar) or spellcooldown(shield_slam) >= 4 protectionuseitemactions()
   }
  }
 }
}

AddFunction protectionstcdpostconditions
{
 enemies() == 2 and hastalent(unstoppable_force_talent) and buffpresent(avatar) and spell(thunder_clap) or spellcooldown(shield_slam) == 0 and buffexpires(shield_block_buff) and spell(shield_block) or buffpresent(shield_block_buff) and spell(shield_slam) or hastalent(unstoppable_force_talent) and buffpresent(avatar) and spell(thunder_clap) or hastalent(booming_voice_talent) and spell(demoralizing_shout) or spell(shield_slam) or spell(dragon_roar) or spell(thunder_clap) or spell(revenge) or spell(ravager_protection) or spell(devastate)
}

### actions.precombat

AddFunction protectionprecombatmainactions
{
}

AddFunction protectionprecombatmainpostconditions
{
}

AddFunction protectionprecombatshortcdactions
{
 #worldvein_resonance
 spell(worldvein_resonance_essence)
}

AddFunction protectionprecombatshortcdpostconditions
{
}

AddFunction protectionprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #use_item,name=azsharas_font_of_power
 protectionuseitemactions()

 unless spell(worldvein_resonance_essence)
 {
  #memory_of_lucid_dreams
  spell(memory_of_lucid_dreams_essence)
  #guardian_of_azeroth
  spell(guardian_of_azeroth)
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(superior_battle_potion_of_strength_item usable=1)
 }
}

AddFunction protectionprecombatcdpostconditions
{
 spell(worldvein_resonance_essence)
}

### actions.aoe

AddFunction protectionaoemainactions
{
 #thunder_clap
 spell(thunder_clap)
 #dragon_roar
 spell(dragon_roar)
 #revenge
 spell(revenge)
 #shield_block,if=cooldown.shield_slam.ready&buff.shield_block.down
 if spellcooldown(shield_slam) == 0 and buffexpires(shield_block_buff) spell(shield_block)
 #shield_slam
 spell(shield_slam)
}

AddFunction protectionaoemainpostconditions
{
}

AddFunction protectionaoeshortcdactions
{
 unless spell(thunder_clap)
 {
  #demoralizing_shout,if=talent.booming_voice.enabled
  if hastalent(booming_voice_talent) spell(demoralizing_shout)

  unless spell(dragon_roar) or spell(revenge)
  {
   #ravager
   spell(ravager_protection)
  }
 }
}

AddFunction protectionaoeshortcdpostconditions
{
 spell(thunder_clap) or spell(dragon_roar) or spell(revenge) or spellcooldown(shield_slam) == 0 and buffexpires(shield_block_buff) and spell(shield_block) or spell(shield_slam)
}

AddFunction protectionaoecdactions
{
 unless spell(thunder_clap)
 {
  #memory_of_lucid_dreams,if=buff.avatar.down
  if buffexpires(avatar) spell(memory_of_lucid_dreams_essence)

  unless hastalent(booming_voice_talent) and spell(demoralizing_shout)
  {
   #anima_of_death,if=buff.last_stand.up
   if buffpresent(last_stand_buff) spell(anima_of_death)

   unless spell(dragon_roar) or spell(revenge)
   {
    #use_item,name=grongs_primal_rage,if=buff.avatar.down|cooldown.thunder_clap.remains>=4
    if buffexpires(avatar) or spellcooldown(thunder_clap) >= 4 protectionuseitemactions()
   }
  }
 }
}

AddFunction protectionaoecdpostconditions
{
 spell(thunder_clap) or hastalent(booming_voice_talent) and spell(demoralizing_shout) or spell(dragon_roar) or spell(revenge) or spell(ravager_protection) or spellcooldown(shield_slam) == 0 and buffexpires(shield_block_buff) and spell(shield_block) or spell(shield_slam)
}

### actions.default

AddFunction protection_defaultmainactions
{
 #ignore_pain,if=rage.deficit<25+20*talent.booming_voice.enabled*cooldown.demoralizing_shout.ready
 if ragedeficit() < 25 + 20 * talentpoints(booming_voice_talent) * { spellcooldown(demoralizing_shout) == 0 } spell(ignore_pain)
 #concentrated_flame,if=buff.avatar.down&!dot.concentrated_flame_burn.remains>0|essence.the_crucible_of_flame.rank<3
 if buffexpires(avatar) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 or azeriteessencerank(the_crucible_of_flame_essence_id) < 3 spell(concentrated_flame_essence)
 #avatar
 spell(avatar)
 #run_action_list,name=aoe,if=spell_targets.thunder_clap>=3
 if enemies() >= 3 protectionaoemainactions()

 unless enemies() >= 3 and protectionaoemainpostconditions()
 {
  #call_action_list,name=st
  protectionstmainactions()
 }
}

AddFunction protection_defaultmainpostconditions
{
 enemies() >= 3 and protectionaoemainpostconditions() or protectionstmainpostconditions()
}

AddFunction protection_defaultshortcdactions
{
 #auto_attack
 protectiongetinmeleerange()

 unless timeincombat() == 0 and spell(intercept)
 {
  #bag_of_tricks
  spell(bag_of_tricks)

  unless ragedeficit() < 25 + 20 * talentpoints(booming_voice_talent) * { spellcooldown(demoralizing_shout) == 0 } and spell(ignore_pain)
  {
   #worldvein_resonance,if=cooldown.avatar.remains<=2
   if spellcooldown(avatar) <= 2 spell(worldvein_resonance_essence)
   #ripple_in_space
   spell(ripple_in_space_essence)

   unless { buffexpires(avatar) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 or azeriteessencerank(the_crucible_of_flame_essence_id) < 3 } and spell(concentrated_flame_essence) or spell(avatar)
   {
    #run_action_list,name=aoe,if=spell_targets.thunder_clap>=3
    if enemies() >= 3 protectionaoeshortcdactions()

    unless enemies() >= 3 and protectionaoeshortcdpostconditions()
    {
     #call_action_list,name=st
     protectionstshortcdactions()
    }
   }
  }
 }
}

AddFunction protection_defaultshortcdpostconditions
{
 timeincombat() == 0 and spell(intercept) or ragedeficit() < 25 + 20 * talentpoints(booming_voice_talent) * { spellcooldown(demoralizing_shout) == 0 } and spell(ignore_pain) or { buffexpires(avatar) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 or azeriteessencerank(the_crucible_of_flame_essence_id) < 3 } and spell(concentrated_flame_essence) or spell(avatar) or enemies() >= 3 and protectionaoeshortcdpostconditions() or protectionstshortcdpostconditions()
}

AddFunction protection_defaultcdactions
{
 protectioninterruptactions()

 unless timeincombat() == 0 and spell(intercept)
 {
  #use_items,if=cooldown.avatar.remains<=gcd|buff.avatar.up
  if spellcooldown(avatar) <= gcd() or buffpresent(avatar) protectionuseitemactions()
  #blood_fury
  spell(blood_fury_ap)
  #berserking
  spell(berserking)
  #arcane_torrent
  spell(arcane_torrent_rage)
  #lights_judgment
  spell(lights_judgment)
  #fireblood
  spell(fireblood)
  #ancestral_call
  spell(ancestral_call)

  unless spell(bag_of_tricks)
  {
   #potion,if=buff.avatar.up|target.time_to_die<25
   if { buffpresent(avatar) or target.timetodie() < 25 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(superior_battle_potion_of_strength_item usable=1)

   unless ragedeficit() < 25 + 20 * talentpoints(booming_voice_talent) * { spellcooldown(demoralizing_shout) == 0 } and spell(ignore_pain) or spellcooldown(avatar) <= 2 and spell(worldvein_resonance_essence) or spell(ripple_in_space_essence)
   {
    #memory_of_lucid_dreams
    spell(memory_of_lucid_dreams_essence)

    unless { buffexpires(avatar) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 or azeriteessencerank(the_crucible_of_flame_essence_id) < 3 } and spell(concentrated_flame_essence)
    {
     #last_stand,if=cooldown.anima_of_death.remains<=2
     if spellcooldown(anima_of_death) <= 2 spell(last_stand)

     unless spell(avatar)
     {
      #run_action_list,name=aoe,if=spell_targets.thunder_clap>=3
      if enemies() >= 3 protectionaoecdactions()

      unless enemies() >= 3 and protectionaoecdpostconditions()
      {
       #call_action_list,name=st
       protectionstcdactions()
      }
     }
    }
   }
  }
 }
}

AddFunction protection_defaultcdpostconditions
{
 timeincombat() == 0 and spell(intercept) or spell(bag_of_tricks) or ragedeficit() < 25 + 20 * talentpoints(booming_voice_talent) * { spellcooldown(demoralizing_shout) == 0 } and spell(ignore_pain) or spellcooldown(avatar) <= 2 and spell(worldvein_resonance_essence) or spell(ripple_in_space_essence) or { buffexpires(avatar) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 or azeriteessencerank(the_crucible_of_flame_essence_id) < 3 } and spell(concentrated_flame_essence) or spell(avatar) or enemies() >= 3 and protectionaoecdpostconditions() or protectionstcdpostconditions()
}

### Protection icons.

AddCheckBox(opt_warrior_protection_aoe l(aoe) default specialization=protection)

AddIcon checkbox=!opt_warrior_protection_aoe enemies=1 help=shortcd specialization=protection
{
 if not incombat() protectionprecombatshortcdactions()
 protection_defaultshortcdactions()
}

AddIcon checkbox=opt_warrior_protection_aoe help=shortcd specialization=protection
{
 if not incombat() protectionprecombatshortcdactions()
 protection_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=protection
{
 if not incombat() protectionprecombatmainactions()
 protection_defaultmainactions()
}

AddIcon checkbox=opt_warrior_protection_aoe help=aoe specialization=protection
{
 if not incombat() protectionprecombatmainactions()
 protection_defaultmainactions()
}

AddIcon checkbox=!opt_warrior_protection_aoe enemies=1 help=cd specialization=protection
{
 if not incombat() protectionprecombatcdactions()
 protection_defaultcdactions()
}

AddIcon checkbox=opt_warrior_protection_aoe help=cd specialization=protection
{
 if not incombat() protectionprecombatcdactions()
 protection_defaultcdactions()
}

### Required symbols
# ancestral_call
# anima_of_death
# arcane_torrent_rage
# avatar
# bag_of_tricks
# berserking
# blood_fury_ap
# booming_voice_talent
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# demoralizing_shout
# devastate
# dragon_roar
# fireblood
# guardian_of_azeroth
# heroic_leap
# ignore_pain
# intercept
# intimidating_shout
# last_stand
# last_stand_buff
# lights_judgment
# memory_of_lucid_dreams_essence
# pummel
# quaking_palm
# ravager_protection
# razor_coral
# revenge
# ripple_in_space_essence
# shield_block
# shield_block_buff
# shield_slam
# shockwave
# storm_bolt
# superior_battle_potion_of_strength_item
# the_crucible_of_flame_essence_id
# thunder_clap
# unstoppable_force_talent
# war_stomp
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("WARRIOR", "protection", name, desc, code, "script")
    end
end
