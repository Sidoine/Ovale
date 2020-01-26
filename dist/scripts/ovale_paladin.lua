local __exports = LibStub:NewLibrary("ovale/scripts/ovale_paladin", 80300)
if not __exports then return end
__exports.registerPaladin = function(OvaleScripts)
    do
        local name = "sc_t24_paladin_protection"
        local desc = "[8.3] Simulationcraft: T24_Paladin_Protection"
        local code = [[
# Based on SimulationCraft profile "T24_Paladin_Protection".
#	class=paladin
#	spec=protection
#	talents=3200003

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=protection)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=protection)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=protection)

AddFunction protectioninterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(rebuke) and target.isinterruptible() spell(rebuke)
  if target.inrange(avengers_shield) and target.isinterruptible() spell(avengers_shield)
  if target.inrange(hammer_of_justice) and not target.classification(worldboss) spell(hammer_of_justice)
  if target.distance(less 10) and not target.classification(worldboss) spell(blinding_light)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
 }
}

AddFunction protectionuseheartessence
{
 spell(concentrated_flame_essence)
}

AddFunction protectionuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction protectiongetinmeleerange
{
 if checkboxon(opt_melee_range) and not target.inrange(rebuke) texture(misc_arrowlup help=l(not_in_melee_range))
}

### actions.precombat

AddFunction protectionprecombatmainactions
{
 #consecration
 spell(consecration)
}

AddFunction protectionprecombatmainpostconditions
{
}

AddFunction protectionprecombatshortcdactions
{
}

AddFunction protectionprecombatshortcdpostconditions
{
 spell(consecration)
}

AddFunction protectionprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

 unless spell(consecration)
 {
  #lights_judgment
  spell(lights_judgment)
 }
}

AddFunction protectionprecombatcdpostconditions
{
 spell(consecration)
}

### actions.cooldowns

AddFunction protectioncooldownsmainactions
{
}

AddFunction protectioncooldownsmainpostconditions
{
}

AddFunction protectioncooldownsshortcdactions
{
 #seraphim,if=cooldown.shield_of_the_righteous.charges_fractional>=2
 if spellcharges(shield_of_the_righteous count=0) >= 2 spell(seraphim)
}

AddFunction protectioncooldownsshortcdpostconditions
{
}

AddFunction protectioncooldownscdactions
{
 #fireblood,if=buff.avenging_wrath.up
 if buffpresent(avenging_wrath_buff) spell(fireblood)
 #use_item,name=azsharas_font_of_power,if=cooldown.seraphim.remains<=10|!talent.seraphim.enabled
 if spellcooldown(seraphim) <= 10 or not hastalent(seraphim_talent) protectionuseitemactions()
 #use_item,name=ashvanes_razor_coral,if=(debuff.razor_coral_debuff.stack>7&buff.avenging_wrath.up)|debuff.razor_coral_debuff.stack=0
 if target.debuffstacks(razor_coral) > 7 and buffpresent(avenging_wrath_buff) or target.debuffstacks(razor_coral) == 0 protectionuseitemactions()

 unless spellcharges(shield_of_the_righteous count=0) >= 2 and spell(seraphim)
 {
  #avenging_wrath,if=buff.seraphim.up|cooldown.seraphim.remains<2|!talent.seraphim.enabled
  if buffpresent(seraphim_buff) or spellcooldown(seraphim) < 2 or not hastalent(seraphim_talent) spell(avenging_wrath)
  #memory_of_lucid_dreams,if=!talent.seraphim.enabled|cooldown.seraphim.remains<=gcd|buff.seraphim.up
  if not hastalent(seraphim_talent) or spellcooldown(seraphim) <= gcd() or buffpresent(seraphim_buff) spell(memory_of_lucid_dreams_essence)
  #bastion_of_light,if=cooldown.shield_of_the_righteous.charges_fractional<=0.5
  if spellcharges(shield_of_the_righteous count=0) <= 0.5 spell(bastion_of_light)
  #potion,if=buff.avenging_wrath.up
  if buffpresent(avenging_wrath_buff) and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
  #use_items,if=buff.seraphim.up|!talent.seraphim.enabled
  if buffpresent(seraphim_buff) or not hastalent(seraphim_talent) protectionuseitemactions()
  #use_item,name=grongs_primal_rage,if=cooldown.judgment.full_recharge_time>4&cooldown.avengers_shield.remains>4&(buff.seraphim.up|cooldown.seraphim.remains+4+gcd>expected_combat_length-time)&consecration.up
  if spellcooldown(judgment_protection) > 4 and spellcooldown(avengers_shield) > 4 and { buffpresent(seraphim_buff) or spellcooldown(seraphim) + 4 + gcd() > 600 - timeincombat() } and buffpresent(consecration) protectionuseitemactions()
  #use_item,name=pocketsized_computation_device,if=cooldown.judgment.full_recharge_time>4*spell_haste&cooldown.avengers_shield.remains>4*spell_haste&(!equipped.grongs_primal_rage|!trinket.grongs_primal_rage.cooldown.up)&consecration.up
  if spellcooldown(judgment_protection) > 4 * { 100 / { 100 + spellcastspeedpercent() } } and spellcooldown(avengers_shield) > 4 * { 100 / { 100 + spellcastspeedpercent() } } and { not hasequippeditem(grongs_primal_rage_item) or buffexpires(trinket_grongs_primal_rage_cooldown_buff) } and buffpresent(consecration) protectionuseitemactions()
  #use_item,name=merekthas_fang,if=!buff.avenging_wrath.up&(buff.seraphim.up|!talent.seraphim.enabled)
  if not buffpresent(avenging_wrath_buff) and { buffpresent(seraphim_buff) or not hastalent(seraphim_talent) } protectionuseitemactions()
  #use_item,name=razdunks_big_red_button
  protectionuseitemactions()
 }
}

AddFunction protectioncooldownscdpostconditions
{
 spellcharges(shield_of_the_righteous count=0) >= 2 and spell(seraphim)
}

### actions.default

AddFunction protection_defaultmainactions
{
 #call_action_list,name=cooldowns
 protectioncooldownsmainactions()

 unless protectioncooldownsmainpostconditions()
 {
  #consecration,if=!consecration.up
  if not buffpresent(consecration) spell(consecration)
  #judgment,if=(cooldown.judgment.remains<gcd&cooldown.judgment.charges_fractional>1&cooldown_react)|!talent.crusaders_judgment.enabled
  if spellcooldown(judgment_protection) < gcd() and spellcharges(judgment_protection count=0) > 1 and not spellcooldown(judgment_protection) > 0 or not hastalent(crusaders_judgment_talent) spell(judgment_protection)
  #avengers_shield,if=cooldown_react
  if not spellcooldown(avengers_shield) > 0 spell(avengers_shield)
  #judgment,if=cooldown_react|!talent.crusaders_judgment.enabled
  if not spellcooldown(judgment_protection) > 0 or not hastalent(crusaders_judgment_talent) spell(judgment_protection)
  #concentrated_flame,if=(!talent.seraphim.enabled|buff.seraphim.up)&!dot.concentrated_flame_burn.remains>0|essence.the_crucible_of_flame.rank<3
  if { not hastalent(seraphim_talent) or buffpresent(seraphim_buff) } and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 or azeriteessencerank(the_crucible_of_flame_essence_id) < 3 spell(concentrated_flame_essence)
  #blessed_hammer,strikes=3
  spell(blessed_hammer)
  #hammer_of_the_righteous
  spell(hammer_of_the_righteous)
  #consecration
  spell(consecration)
 }
}

AddFunction protection_defaultmainpostconditions
{
 protectioncooldownsmainpostconditions()
}

AddFunction protection_defaultshortcdactions
{
 #auto_attack
 protectiongetinmeleerange()
 #call_action_list,name=cooldowns
 protectioncooldownsshortcdactions()

 unless protectioncooldownsshortcdpostconditions()
 {
  #worldvein_resonance,if=buff.lifeblood.stack<3
  if buffstacks(lifeblood_buff) < 3 spell(worldvein_resonance_essence)
  #shield_of_the_righteous,if=(buff.avengers_valor.up&cooldown.shield_of_the_righteous.charges_fractional>=2.5)&(cooldown.seraphim.remains>gcd|!talent.seraphim.enabled)
  if buffpresent(avengers_valor_buff) and spellcharges(shield_of_the_righteous count=0) >= 2.5 and { spellcooldown(seraphim) > gcd() or not hastalent(seraphim_talent) } spell(shield_of_the_righteous)
  #shield_of_the_righteous,if=(buff.avenging_wrath.up&!talent.seraphim.enabled)|buff.seraphim.up&buff.avengers_valor.up
  if buffpresent(avenging_wrath_buff) and not hastalent(seraphim_talent) or buffpresent(seraphim_buff) and buffpresent(avengers_valor_buff) spell(shield_of_the_righteous)
  #shield_of_the_righteous,if=(buff.avenging_wrath.up&buff.avenging_wrath.remains<4&!talent.seraphim.enabled)|(buff.seraphim.remains<4&buff.seraphim.up)
  if buffpresent(avenging_wrath_buff) and buffremaining(avenging_wrath_buff) < 4 and not hastalent(seraphim_talent) or buffremaining(seraphim_buff) < 4 and buffpresent(seraphim_buff) spell(shield_of_the_righteous)
 }
}

AddFunction protection_defaultshortcdpostconditions
{
 protectioncooldownsshortcdpostconditions() or not buffpresent(consecration) and spell(consecration) or { spellcooldown(judgment_protection) < gcd() and spellcharges(judgment_protection count=0) > 1 and not spellcooldown(judgment_protection) > 0 or not hastalent(crusaders_judgment_talent) } and spell(judgment_protection) or not spellcooldown(avengers_shield) > 0 and spell(avengers_shield) or { not spellcooldown(judgment_protection) > 0 or not hastalent(crusaders_judgment_talent) } and spell(judgment_protection) or { { not hastalent(seraphim_talent) or buffpresent(seraphim_buff) } and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 or azeriteessencerank(the_crucible_of_flame_essence_id) < 3 } and spell(concentrated_flame_essence) or spell(blessed_hammer) or spell(hammer_of_the_righteous) or spell(consecration)
}

AddFunction protection_defaultcdactions
{
 protectioninterruptactions()
 #call_action_list,name=cooldowns
 protectioncooldownscdactions()

 unless protectioncooldownscdpostconditions() or buffstacks(lifeblood_buff) < 3 and spell(worldvein_resonance_essence) or buffpresent(avengers_valor_buff) and spellcharges(shield_of_the_righteous count=0) >= 2.5 and { spellcooldown(seraphim) > gcd() or not hastalent(seraphim_talent) } and spell(shield_of_the_righteous) or { buffpresent(avenging_wrath_buff) and not hastalent(seraphim_talent) or buffpresent(seraphim_buff) and buffpresent(avengers_valor_buff) } and spell(shield_of_the_righteous) or { buffpresent(avenging_wrath_buff) and buffremaining(avenging_wrath_buff) < 4 and not hastalent(seraphim_talent) or buffremaining(seraphim_buff) < 4 and buffpresent(seraphim_buff) } and spell(shield_of_the_righteous)
 {
  #lights_judgment,if=buff.seraphim.up&buff.seraphim.remains<3
  if buffpresent(seraphim_buff) and buffremaining(seraphim_buff) < 3 spell(lights_judgment)

  unless not buffpresent(consecration) and spell(consecration) or { spellcooldown(judgment_protection) < gcd() and spellcharges(judgment_protection count=0) > 1 and not spellcooldown(judgment_protection) > 0 or not hastalent(crusaders_judgment_talent) } and spell(judgment_protection) or not spellcooldown(avengers_shield) > 0 and spell(avengers_shield) or { not spellcooldown(judgment_protection) > 0 or not hastalent(crusaders_judgment_talent) } and spell(judgment_protection) or { { not hastalent(seraphim_talent) or buffpresent(seraphim_buff) } and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 or azeriteessencerank(the_crucible_of_flame_essence_id) < 3 } and spell(concentrated_flame_essence)
  {
   #lights_judgment,if=!talent.seraphim.enabled|buff.seraphim.up
   if not hastalent(seraphim_talent) or buffpresent(seraphim_buff) spell(lights_judgment)
   #anima_of_death
   spell(anima_of_death)

   unless spell(blessed_hammer) or spell(hammer_of_the_righteous) or spell(consecration)
   {
    #heart_essence,if=!(essence.the_crucible_of_flame.major|essence.worldvein_resonance.major|essence.anima_of_life_and_death.major|essence.memory_of_lucid_dreams.major)
    if not { azeriteessenceismajor(the_crucible_of_flame_essence_id) or azeriteessenceismajor(worldvein_resonance_essence_id) or azeriteessenceismajor(anima_of_life_and_death_essence_id) or azeriteessenceismajor(memory_of_lucid_dreams_essence_id) } protectionuseheartessence()
   }
  }
 }
}

AddFunction protection_defaultcdpostconditions
{
 protectioncooldownscdpostconditions() or buffstacks(lifeblood_buff) < 3 and spell(worldvein_resonance_essence) or buffpresent(avengers_valor_buff) and spellcharges(shield_of_the_righteous count=0) >= 2.5 and { spellcooldown(seraphim) > gcd() or not hastalent(seraphim_talent) } and spell(shield_of_the_righteous) or { buffpresent(avenging_wrath_buff) and not hastalent(seraphim_talent) or buffpresent(seraphim_buff) and buffpresent(avengers_valor_buff) } and spell(shield_of_the_righteous) or { buffpresent(avenging_wrath_buff) and buffremaining(avenging_wrath_buff) < 4 and not hastalent(seraphim_talent) or buffremaining(seraphim_buff) < 4 and buffpresent(seraphim_buff) } and spell(shield_of_the_righteous) or not buffpresent(consecration) and spell(consecration) or { spellcooldown(judgment_protection) < gcd() and spellcharges(judgment_protection count=0) > 1 and not spellcooldown(judgment_protection) > 0 or not hastalent(crusaders_judgment_talent) } and spell(judgment_protection) or not spellcooldown(avengers_shield) > 0 and spell(avengers_shield) or { not spellcooldown(judgment_protection) > 0 or not hastalent(crusaders_judgment_talent) } and spell(judgment_protection) or { { not hastalent(seraphim_talent) or buffpresent(seraphim_buff) } and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 or azeriteessencerank(the_crucible_of_flame_essence_id) < 3 } and spell(concentrated_flame_essence) or spell(blessed_hammer) or spell(hammer_of_the_righteous) or spell(consecration)
}

### Protection icons.

AddCheckBox(opt_paladin_protection_aoe l(aoe) default specialization=protection)

AddIcon checkbox=!opt_paladin_protection_aoe enemies=1 help=shortcd specialization=protection
{
 if not incombat() protectionprecombatshortcdactions()
 protection_defaultshortcdactions()
}

AddIcon checkbox=opt_paladin_protection_aoe help=shortcd specialization=protection
{
 if not incombat() protectionprecombatshortcdactions()
 protection_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=protection
{
 if not incombat() protectionprecombatmainactions()
 protection_defaultmainactions()
}

AddIcon checkbox=opt_paladin_protection_aoe help=aoe specialization=protection
{
 if not incombat() protectionprecombatmainactions()
 protection_defaultmainactions()
}

AddIcon checkbox=!opt_paladin_protection_aoe enemies=1 help=cd specialization=protection
{
 if not incombat() protectionprecombatcdactions()
 protection_defaultcdactions()
}

AddIcon checkbox=opt_paladin_protection_aoe help=cd specialization=protection
{
 if not incombat() protectionprecombatcdactions()
 protection_defaultcdactions()
}

### Required symbols
# anima_of_death
# anima_of_life_and_death_essence_id
# avengers_shield
# avengers_valor_buff
# avenging_wrath
# avenging_wrath_buff
# bastion_of_light
# blessed_hammer
# blinding_light
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# consecration
# crusaders_judgment_talent
# fireblood
# grongs_primal_rage_item
# hammer_of_justice
# hammer_of_the_righteous
# judgment_protection
# lifeblood_buff
# lights_judgment
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_id
# razor_coral
# rebuke
# seraphim
# seraphim_buff
# seraphim_talent
# shield_of_the_righteous
# the_crucible_of_flame_essence_id
# trinket_grongs_primal_rage_cooldown_buff
# unbridled_fury_item
# war_stomp
# worldvein_resonance_essence
# worldvein_resonance_essence_id
]]
        OvaleScripts:RegisterScript("PALADIN", "protection", name, desc, code, "script")
    end
    do
        local name = "sc_t24_paladin_retribution"
        local desc = "[8.3] Simulationcraft: T24_Paladin_Retribution"
        local code = [[
# Based on SimulationCraft profile "T24_Paladin_Retribution".
#	class=paladin
#	spec=retribution
#	talents=3303103

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)


AddFunction ds_castable
{
 enemies() >= 2 and not hastalent(righteous_verdict_talent) or enemies() >= 3 and hastalent(righteous_verdict_talent) or buffpresent(empyrean_power_buff) and target.debuffexpires(judgment) and buffexpires(divine_purpose_retribution) and buffexpires(avenging_wrath_autocrit_buff)
}

AddFunction wings_pool
{
 not hasequippeditem(169314) and { not hastalent(crusade_talent) and spellcooldown(avenging_wrath) > gcd() * 3 or spellcooldown(crusade) > gcd() * 3 } or hasequippeditem(169314) and { not hastalent(crusade_talent) and spellcooldown(avenging_wrath) > gcd() * 6 or spellcooldown(crusade) > gcd() * 6 }
}

AddFunction HoW
{
 not hastalent(hammer_of_wrath_talent) or target.healthpercent() >= 20 and not { buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) }
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=retribution)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=retribution)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=retribution)
AddCheckBox(opt_shield_of_vengeance spellname(shield_of_vengeance) specialization=retribution)

AddFunction retributioninterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(rebuke) and target.isinterruptible() spell(rebuke)
  if target.inrange(hammer_of_justice) and not target.classification(worldboss) spell(hammer_of_justice)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
 }
}

AddFunction retributionuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction retributiongetinmeleerange
{
 if checkboxon(opt_melee_range) and not target.inrange(rebuke) texture(misc_arrowlup help=l(not_in_melee_range))
}

### actions.precombat

AddFunction retributionprecombatmainactions
{
}

AddFunction retributionprecombatmainpostconditions
{
}

AddFunction retributionprecombatshortcdactions
{
}

AddFunction retributionprecombatshortcdpostconditions
{
}

AddFunction retributionprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)
 #use_item,name=azsharas_font_of_power
 retributionuseitemactions()
 #arcane_torrent,if=!talent.wake_of_ashes.enabled
 if not hastalent(wake_of_ashes_talent) spell(arcane_torrent_holy)
}

AddFunction retributionprecombatcdpostconditions
{
}

### actions.generators

AddFunction retributiongeneratorsmainactions
{
 #variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&!(buff.avenging_wrath.up|buff.crusade.up))
 #call_action_list,name=finishers,if=holy_power>=5|buff.memory_of_lucid_dreams.up|buff.seething_rage.up|talent.inquisition.enabled&buff.inquisition.down&holy_power>=3
 if holypower() >= 5 or buffpresent(memory_of_lucid_dreams_essence_buff) or buffpresent(seething_rage) or hastalent(inquisition_talent) and buffexpires(inquisition_buff) and holypower() >= 3 retributionfinishersmainactions()

 unless { holypower() >= 5 or buffpresent(memory_of_lucid_dreams_essence_buff) or buffpresent(seething_rage) or hastalent(inquisition_talent) and buffexpires(inquisition_buff) and holypower() >= 3 } and retributionfinishersmainpostconditions()
 {
  #wake_of_ashes,if=(!raid_event.adds.exists|raid_event.adds.in>15|spell_targets.wake_of_ashes>=2)&(holy_power<=0|holy_power=1&cooldown.blade_of_justice.remains>gcd)&(cooldown.avenging_wrath.remains>10|talent.crusade.enabled&cooldown.crusade.remains>10)
  if { not false(raid_event_adds_exists) or 600 > 15 or enemies() >= 2 } and { holypower() <= 0 or holypower() == 1 and spellcooldown(blade_of_justice) > gcd() } and { spellcooldown(avenging_wrath) > 10 or hastalent(crusade_talent) and spellcooldown(crusade) > 10 } spell(wake_of_ashes)
  #blade_of_justice,if=holy_power<=2|(holy_power=3&(cooldown.hammer_of_wrath.remains>gcd*2|variable.HoW))
  if holypower() <= 2 or holypower() == 3 and { spellcooldown(hammer_of_wrath) > gcd() * 2 or HoW() } spell(blade_of_justice)
  #judgment,if=holy_power<=2|(holy_power<=4&(cooldown.blade_of_justice.remains>gcd*2|variable.HoW))
  if holypower() <= 2 or holypower() <= 4 and { spellcooldown(blade_of_justice) > gcd() * 2 or HoW() } spell(judgment)
  #hammer_of_wrath,if=holy_power<=4
  if holypower() <= 4 spell(hammer_of_wrath)
  #consecration,if=holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power=4&cooldown.blade_of_justice.remains>gcd*2&cooldown.judgment.remains>gcd*2
  if holypower() <= 2 or holypower() <= 3 and spellcooldown(blade_of_justice) > gcd() * 2 or holypower() == 4 and spellcooldown(blade_of_justice) > gcd() * 2 and spellcooldown(judgment) > gcd() * 2 spell(consecration_retribution)
  #call_action_list,name=finishers,if=talent.hammer_of_wrath.enabled&target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up
  if hastalent(hammer_of_wrath_talent) and target.healthpercent() <= 20 or buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) retributionfinishersmainactions()

  unless { hastalent(hammer_of_wrath_talent) and target.healthpercent() <= 20 or buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) } and retributionfinishersmainpostconditions()
  {
   #crusader_strike,if=cooldown.crusader_strike.charges_fractional>=1.75&(holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power=4&cooldown.blade_of_justice.remains>gcd*2&cooldown.judgment.remains>gcd*2&cooldown.consecration.remains>gcd*2)
   if spellcharges(crusader_strike count=0) >= 1.75 and { holypower() <= 2 or holypower() <= 3 and spellcooldown(blade_of_justice) > gcd() * 2 or holypower() == 4 and spellcooldown(blade_of_justice) > gcd() * 2 and spellcooldown(judgment) > gcd() * 2 and spellcooldown(consecration_retribution) > gcd() * 2 } spell(crusader_strike)
   #call_action_list,name=finishers
   retributionfinishersmainactions()

   unless retributionfinishersmainpostconditions()
   {
    #concentrated_flame
    spell(concentrated_flame_essence)
    #crusader_strike,if=holy_power<=4
    if holypower() <= 4 spell(crusader_strike)
   }
  }
 }
}

AddFunction retributiongeneratorsmainpostconditions
{
 { holypower() >= 5 or buffpresent(memory_of_lucid_dreams_essence_buff) or buffpresent(seething_rage) or hastalent(inquisition_talent) and buffexpires(inquisition_buff) and holypower() >= 3 } and retributionfinishersmainpostconditions() or { hastalent(hammer_of_wrath_talent) and target.healthpercent() <= 20 or buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) } and retributionfinishersmainpostconditions() or retributionfinishersmainpostconditions()
}

AddFunction retributiongeneratorsshortcdactions
{
 #variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&!(buff.avenging_wrath.up|buff.crusade.up))
 #call_action_list,name=finishers,if=holy_power>=5|buff.memory_of_lucid_dreams.up|buff.seething_rage.up|talent.inquisition.enabled&buff.inquisition.down&holy_power>=3
 if holypower() >= 5 or buffpresent(memory_of_lucid_dreams_essence_buff) or buffpresent(seething_rage) or hastalent(inquisition_talent) and buffexpires(inquisition_buff) and holypower() >= 3 retributionfinishersshortcdactions()

 unless { holypower() >= 5 or buffpresent(memory_of_lucid_dreams_essence_buff) or buffpresent(seething_rage) or hastalent(inquisition_talent) and buffexpires(inquisition_buff) and holypower() >= 3 } and retributionfinishersshortcdpostconditions() or { not false(raid_event_adds_exists) or 600 > 15 or enemies() >= 2 } and { holypower() <= 0 or holypower() == 1 and spellcooldown(blade_of_justice) > gcd() } and { spellcooldown(avenging_wrath) > 10 or hastalent(crusade_talent) and spellcooldown(crusade) > 10 } and spell(wake_of_ashes) or { holypower() <= 2 or holypower() == 3 and { spellcooldown(hammer_of_wrath) > gcd() * 2 or HoW() } } and spell(blade_of_justice) or { holypower() <= 2 or holypower() <= 4 and { spellcooldown(blade_of_justice) > gcd() * 2 or HoW() } } and spell(judgment) or holypower() <= 4 and spell(hammer_of_wrath) or { holypower() <= 2 or holypower() <= 3 and spellcooldown(blade_of_justice) > gcd() * 2 or holypower() == 4 and spellcooldown(blade_of_justice) > gcd() * 2 and spellcooldown(judgment) > gcd() * 2 } and spell(consecration_retribution)
 {
  #call_action_list,name=finishers,if=talent.hammer_of_wrath.enabled&target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up
  if hastalent(hammer_of_wrath_talent) and target.healthpercent() <= 20 or buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) retributionfinishersshortcdactions()

  unless { hastalent(hammer_of_wrath_talent) and target.healthpercent() <= 20 or buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) } and retributionfinishersshortcdpostconditions() or spellcharges(crusader_strike count=0) >= 1.75 and { holypower() <= 2 or holypower() <= 3 and spellcooldown(blade_of_justice) > gcd() * 2 or holypower() == 4 and spellcooldown(blade_of_justice) > gcd() * 2 and spellcooldown(judgment) > gcd() * 2 and spellcooldown(consecration_retribution) > gcd() * 2 } and spell(crusader_strike)
  {
   #call_action_list,name=finishers
   retributionfinishersshortcdactions()

   unless retributionfinishersshortcdpostconditions() or spell(concentrated_flame_essence)
   {
    #reaping_flames
    spell(reaping_flames)
   }
  }
 }
}

AddFunction retributiongeneratorsshortcdpostconditions
{
 { holypower() >= 5 or buffpresent(memory_of_lucid_dreams_essence_buff) or buffpresent(seething_rage) or hastalent(inquisition_talent) and buffexpires(inquisition_buff) and holypower() >= 3 } and retributionfinishersshortcdpostconditions() or { not false(raid_event_adds_exists) or 600 > 15 or enemies() >= 2 } and { holypower() <= 0 or holypower() == 1 and spellcooldown(blade_of_justice) > gcd() } and { spellcooldown(avenging_wrath) > 10 or hastalent(crusade_talent) and spellcooldown(crusade) > 10 } and spell(wake_of_ashes) or { holypower() <= 2 or holypower() == 3 and { spellcooldown(hammer_of_wrath) > gcd() * 2 or HoW() } } and spell(blade_of_justice) or { holypower() <= 2 or holypower() <= 4 and { spellcooldown(blade_of_justice) > gcd() * 2 or HoW() } } and spell(judgment) or holypower() <= 4 and spell(hammer_of_wrath) or { holypower() <= 2 or holypower() <= 3 and spellcooldown(blade_of_justice) > gcd() * 2 or holypower() == 4 and spellcooldown(blade_of_justice) > gcd() * 2 and spellcooldown(judgment) > gcd() * 2 } and spell(consecration_retribution) or { hastalent(hammer_of_wrath_talent) and target.healthpercent() <= 20 or buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) } and retributionfinishersshortcdpostconditions() or spellcharges(crusader_strike count=0) >= 1.75 and { holypower() <= 2 or holypower() <= 3 and spellcooldown(blade_of_justice) > gcd() * 2 or holypower() == 4 and spellcooldown(blade_of_justice) > gcd() * 2 and spellcooldown(judgment) > gcd() * 2 and spellcooldown(consecration_retribution) > gcd() * 2 } and spell(crusader_strike) or retributionfinishersshortcdpostconditions() or spell(concentrated_flame_essence) or holypower() <= 4 and spell(crusader_strike)
}

AddFunction retributiongeneratorscdactions
{
 #variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&!(buff.avenging_wrath.up|buff.crusade.up))
 #call_action_list,name=finishers,if=holy_power>=5|buff.memory_of_lucid_dreams.up|buff.seething_rage.up|talent.inquisition.enabled&buff.inquisition.down&holy_power>=3
 if holypower() >= 5 or buffpresent(memory_of_lucid_dreams_essence_buff) or buffpresent(seething_rage) or hastalent(inquisition_talent) and buffexpires(inquisition_buff) and holypower() >= 3 retributionfinisherscdactions()

 unless { holypower() >= 5 or buffpresent(memory_of_lucid_dreams_essence_buff) or buffpresent(seething_rage) or hastalent(inquisition_talent) and buffexpires(inquisition_buff) and holypower() >= 3 } and retributionfinisherscdpostconditions() or { not false(raid_event_adds_exists) or 600 > 15 or enemies() >= 2 } and { holypower() <= 0 or holypower() == 1 and spellcooldown(blade_of_justice) > gcd() } and { spellcooldown(avenging_wrath) > 10 or hastalent(crusade_talent) and spellcooldown(crusade) > 10 } and spell(wake_of_ashes) or { holypower() <= 2 or holypower() == 3 and { spellcooldown(hammer_of_wrath) > gcd() * 2 or HoW() } } and spell(blade_of_justice) or { holypower() <= 2 or holypower() <= 4 and { spellcooldown(blade_of_justice) > gcd() * 2 or HoW() } } and spell(judgment) or holypower() <= 4 and spell(hammer_of_wrath) or { holypower() <= 2 or holypower() <= 3 and spellcooldown(blade_of_justice) > gcd() * 2 or holypower() == 4 and spellcooldown(blade_of_justice) > gcd() * 2 and spellcooldown(judgment) > gcd() * 2 } and spell(consecration_retribution)
 {
  #call_action_list,name=finishers,if=talent.hammer_of_wrath.enabled&target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up
  if hastalent(hammer_of_wrath_talent) and target.healthpercent() <= 20 or buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) retributionfinisherscdactions()

  unless { hastalent(hammer_of_wrath_talent) and target.healthpercent() <= 20 or buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) } and retributionfinisherscdpostconditions() or spellcharges(crusader_strike count=0) >= 1.75 and { holypower() <= 2 or holypower() <= 3 and spellcooldown(blade_of_justice) > gcd() * 2 or holypower() == 4 and spellcooldown(blade_of_justice) > gcd() * 2 and spellcooldown(judgment) > gcd() * 2 and spellcooldown(consecration_retribution) > gcd() * 2 } and spell(crusader_strike)
  {
   #call_action_list,name=finishers
   retributionfinisherscdactions()

   unless retributionfinisherscdpostconditions() or spell(concentrated_flame_essence) or spell(reaping_flames) or holypower() <= 4 and spell(crusader_strike)
   {
    #arcane_torrent,if=holy_power<=4
    if holypower() <= 4 spell(arcane_torrent_holy)
   }
  }
 }
}

AddFunction retributiongeneratorscdpostconditions
{
 { holypower() >= 5 or buffpresent(memory_of_lucid_dreams_essence_buff) or buffpresent(seething_rage) or hastalent(inquisition_talent) and buffexpires(inquisition_buff) and holypower() >= 3 } and retributionfinisherscdpostconditions() or { not false(raid_event_adds_exists) or 600 > 15 or enemies() >= 2 } and { holypower() <= 0 or holypower() == 1 and spellcooldown(blade_of_justice) > gcd() } and { spellcooldown(avenging_wrath) > 10 or hastalent(crusade_talent) and spellcooldown(crusade) > 10 } and spell(wake_of_ashes) or { holypower() <= 2 or holypower() == 3 and { spellcooldown(hammer_of_wrath) > gcd() * 2 or HoW() } } and spell(blade_of_justice) or { holypower() <= 2 or holypower() <= 4 and { spellcooldown(blade_of_justice) > gcd() * 2 or HoW() } } and spell(judgment) or holypower() <= 4 and spell(hammer_of_wrath) or { holypower() <= 2 or holypower() <= 3 and spellcooldown(blade_of_justice) > gcd() * 2 or holypower() == 4 and spellcooldown(blade_of_justice) > gcd() * 2 and spellcooldown(judgment) > gcd() * 2 } and spell(consecration_retribution) or { hastalent(hammer_of_wrath_talent) and target.healthpercent() <= 20 or buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) } and retributionfinisherscdpostconditions() or spellcharges(crusader_strike count=0) >= 1.75 and { holypower() <= 2 or holypower() <= 3 and spellcooldown(blade_of_justice) > gcd() * 2 or holypower() == 4 and spellcooldown(blade_of_justice) > gcd() * 2 and spellcooldown(judgment) > gcd() * 2 and spellcooldown(consecration_retribution) > gcd() * 2 } and spell(crusader_strike) or retributionfinisherscdpostconditions() or spell(concentrated_flame_essence) or spell(reaping_flames) or holypower() <= 4 and spell(crusader_strike)
}

### actions.finishers

AddFunction retributionfinishersmainactions
{
 #variable,name=wings_pool,value=!equipped.169314&(!talent.crusade.enabled&cooldown.avenging_wrath.remains>gcd*3|cooldown.crusade.remains>gcd*3)|equipped.169314&(!talent.crusade.enabled&cooldown.avenging_wrath.remains>gcd*6|cooldown.crusade.remains>gcd*6)
 #variable,name=ds_castable,value=spell_targets.divine_storm>=2&!talent.righteous_verdict.enabled|spell_targets.divine_storm>=3&talent.righteous_verdict.enabled|buff.empyrean_power.up&debuff.judgment.down&buff.divine_purpose.down&buff.avenging_wrath_autocrit.down
 #inquisition,if=buff.avenging_wrath.down&(buff.inquisition.down|buff.inquisition.remains<8&holy_power>=3|talent.execution_sentence.enabled&cooldown.execution_sentence.remains<10&buff.inquisition.remains<15|cooldown.avenging_wrath.remains<15&buff.inquisition.remains<20&holy_power>=3)
 if buffexpires(avenging_wrath_buff) and { buffexpires(inquisition_buff) or buffremaining(inquisition_buff) < 8 and holypower() >= 3 or hastalent(execution_sentence_talent) and spellcooldown(execution_sentence) < 10 and buffremaining(inquisition_buff) < 15 or spellcooldown(avenging_wrath) < 15 and buffremaining(inquisition_buff) < 20 and holypower() >= 3 } spell(inquisition)
 #execution_sentence,if=spell_targets.divine_storm<=2&(!talent.crusade.enabled&cooldown.avenging_wrath.remains>10|talent.crusade.enabled&buff.crusade.down&cooldown.crusade.remains>10|buff.crusade.stack>=7)
 if enemies() <= 2 and { not hastalent(crusade_talent) and spellcooldown(avenging_wrath) > 10 or hastalent(crusade_talent) and buffexpires(crusade_buff) and spellcooldown(crusade) > 10 or buffstacks(crusade_buff) >= 7 } spell(execution_sentence)
 #divine_storm,if=variable.ds_castable&variable.wings_pool&((!talent.execution_sentence.enabled|(spell_targets.divine_storm>=2|cooldown.execution_sentence.remains>gcd*2))|(cooldown.avenging_wrath.remains>gcd*3&cooldown.avenging_wrath.remains<10|cooldown.crusade.remains>gcd*3&cooldown.crusade.remains<10|buff.crusade.up&buff.crusade.stack<10))
 if ds_castable() and wings_pool() and { not hastalent(execution_sentence_talent) or enemies() >= 2 or spellcooldown(execution_sentence) > gcd() * 2 or spellcooldown(avenging_wrath) > gcd() * 3 and spellcooldown(avenging_wrath) < 10 or spellcooldown(crusade) > gcd() * 3 and spellcooldown(crusade) < 10 or buffpresent(crusade_buff) and buffstacks(crusade_buff) < 10 } spell(divine_storm)
 #templars_verdict,if=variable.wings_pool&(!talent.execution_sentence.enabled|cooldown.execution_sentence.remains>gcd*2|cooldown.avenging_wrath.remains>gcd*3&cooldown.avenging_wrath.remains<10|cooldown.crusade.remains>gcd*3&cooldown.crusade.remains<10|buff.crusade.up&buff.crusade.stack<10)
 if wings_pool() and { not hastalent(execution_sentence_talent) or spellcooldown(execution_sentence) > gcd() * 2 or spellcooldown(avenging_wrath) > gcd() * 3 and spellcooldown(avenging_wrath) < 10 or spellcooldown(crusade) > gcd() * 3 and spellcooldown(crusade) < 10 or buffpresent(crusade_buff) and buffstacks(crusade_buff) < 10 } spell(templars_verdict)
}

AddFunction retributionfinishersmainpostconditions
{
}

AddFunction retributionfinishersshortcdactions
{
}

AddFunction retributionfinishersshortcdpostconditions
{
 buffexpires(avenging_wrath_buff) and { buffexpires(inquisition_buff) or buffremaining(inquisition_buff) < 8 and holypower() >= 3 or hastalent(execution_sentence_talent) and spellcooldown(execution_sentence) < 10 and buffremaining(inquisition_buff) < 15 or spellcooldown(avenging_wrath) < 15 and buffremaining(inquisition_buff) < 20 and holypower() >= 3 } and spell(inquisition) or enemies() <= 2 and { not hastalent(crusade_talent) and spellcooldown(avenging_wrath) > 10 or hastalent(crusade_talent) and buffexpires(crusade_buff) and spellcooldown(crusade) > 10 or buffstacks(crusade_buff) >= 7 } and spell(execution_sentence) or ds_castable() and wings_pool() and { not hastalent(execution_sentence_talent) or enemies() >= 2 or spellcooldown(execution_sentence) > gcd() * 2 or spellcooldown(avenging_wrath) > gcd() * 3 and spellcooldown(avenging_wrath) < 10 or spellcooldown(crusade) > gcd() * 3 and spellcooldown(crusade) < 10 or buffpresent(crusade_buff) and buffstacks(crusade_buff) < 10 } and spell(divine_storm) or wings_pool() and { not hastalent(execution_sentence_talent) or spellcooldown(execution_sentence) > gcd() * 2 or spellcooldown(avenging_wrath) > gcd() * 3 and spellcooldown(avenging_wrath) < 10 or spellcooldown(crusade) > gcd() * 3 and spellcooldown(crusade) < 10 or buffpresent(crusade_buff) and buffstacks(crusade_buff) < 10 } and spell(templars_verdict)
}

AddFunction retributionfinisherscdactions
{
}

AddFunction retributionfinisherscdpostconditions
{
 buffexpires(avenging_wrath_buff) and { buffexpires(inquisition_buff) or buffremaining(inquisition_buff) < 8 and holypower() >= 3 or hastalent(execution_sentence_talent) and spellcooldown(execution_sentence) < 10 and buffremaining(inquisition_buff) < 15 or spellcooldown(avenging_wrath) < 15 and buffremaining(inquisition_buff) < 20 and holypower() >= 3 } and spell(inquisition) or enemies() <= 2 and { not hastalent(crusade_talent) and spellcooldown(avenging_wrath) > 10 or hastalent(crusade_talent) and buffexpires(crusade_buff) and spellcooldown(crusade) > 10 or buffstacks(crusade_buff) >= 7 } and spell(execution_sentence) or ds_castable() and wings_pool() and { not hastalent(execution_sentence_talent) or enemies() >= 2 or spellcooldown(execution_sentence) > gcd() * 2 or spellcooldown(avenging_wrath) > gcd() * 3 and spellcooldown(avenging_wrath) < 10 or spellcooldown(crusade) > gcd() * 3 and spellcooldown(crusade) < 10 or buffpresent(crusade_buff) and buffstacks(crusade_buff) < 10 } and spell(divine_storm) or wings_pool() and { not hastalent(execution_sentence_talent) or spellcooldown(execution_sentence) > gcd() * 2 or spellcooldown(avenging_wrath) > gcd() * 3 and spellcooldown(avenging_wrath) < 10 or spellcooldown(crusade) > gcd() * 3 and spellcooldown(crusade) < 10 or buffpresent(crusade_buff) and buffstacks(crusade_buff) < 10 } and spell(templars_verdict)
}

### actions.cooldowns

AddFunction retributioncooldownsmainactions
{
}

AddFunction retributioncooldownsmainpostconditions
{
}

AddFunction retributioncooldownsshortcdactions
{
 #shield_of_vengeance,if=buff.seething_rage.down&buff.memory_of_lucid_dreams.down
 if buffexpires(seething_rage) and buffexpires(memory_of_lucid_dreams_essence_buff) and checkboxon(opt_shield_of_vengeance) spell(shield_of_vengeance)
 #the_unbound_force,if=time<=2|buff.reckless_force.up
 if timeincombat() <= 2 or buffpresent(reckless_force_buff) spell(the_unbound_force)
 #worldvein_resonance,if=cooldown.avenging_wrath.remains<gcd&holy_power>=3|talent.crusade.enabled&cooldown.crusade.remains<gcd&holy_power>=4|cooldown.avenging_wrath.remains>=45|cooldown.crusade.remains>=45
 if spellcooldown(avenging_wrath) < gcd() and holypower() >= 3 or hastalent(crusade_talent) and spellcooldown(crusade) < gcd() and holypower() >= 4 or spellcooldown(avenging_wrath) >= 45 or spellcooldown(crusade) >= 45 spell(worldvein_resonance_essence)
 #purifying_blast,if=(!raid_event.adds.exists|raid_event.adds.in>30|spell_targets.divine_storm>=2)
 if not false(raid_event_adds_exists) or 600 > 30 or enemies() >= 2 spell(purifying_blast)
}

AddFunction retributioncooldownsshortcdpostconditions
{
}

AddFunction retributioncooldownscdactions
{
 #potion,if=(cooldown.guardian_of_azeroth.remains>90|!essence.condensed_lifeforce.major)&(buff.bloodlust.react|buff.avenging_wrath.up&buff.avenging_wrath.remains>18|buff.crusade.up&buff.crusade.remains<25)
 if { spellcooldown(guardian_of_azeroth) > 90 or not azeriteessenceismajor(condensed_life_force_essence_id) } and { buffpresent(bloodlust) or buffpresent(avenging_wrath_buff) and buffremaining(avenging_wrath_buff) > 18 or buffpresent(crusade_buff) and buffremaining(crusade_buff) < 25 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)
 #lights_judgment,if=spell_targets.lights_judgment>=2|(!raid_event.adds.exists|raid_event.adds.in>75)
 if enemies() >= 2 or not false(raid_event_adds_exists) or 600 > 75 spell(lights_judgment)
 #fireblood,if=buff.avenging_wrath.up|buff.crusade.up&buff.crusade.stack=10
 if buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) and buffstacks(crusade_buff) == 10 spell(fireblood)

 unless buffexpires(seething_rage) and buffexpires(memory_of_lucid_dreams_essence_buff) and checkboxon(opt_shield_of_vengeance) and spell(shield_of_vengeance)
 {
  #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|(buff.avenging_wrath.remains>=20|buff.crusade.stack=10&buff.crusade.remains>15)&(cooldown.guardian_of_azeroth.remains>90|target.time_to_die<30|!essence.condensed_lifeforce.major)
  if target.debuffexpires(razor_coral) or { buffremaining(avenging_wrath_buff) >= 20 or buffstacks(crusade_buff) == 10 and buffremaining(crusade_buff) > 15 } and { spellcooldown(guardian_of_azeroth) > 90 or target.timetodie() < 30 or not azeriteessenceismajor(condensed_life_force_essence_id) } retributionuseitemactions()

  unless { timeincombat() <= 2 or buffpresent(reckless_force_buff) } and spell(the_unbound_force)
  {
   #blood_of_the_enemy,if=buff.avenging_wrath.up|buff.crusade.up&buff.crusade.stack=10
   if buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) and buffstacks(crusade_buff) == 10 spell(blood_of_the_enemy)
   #guardian_of_azeroth,if=!talent.crusade.enabled&(cooldown.avenging_wrath.remains<5&holy_power>=3&(buff.inquisition.up|!talent.inquisition.enabled)|cooldown.avenging_wrath.remains>=45)|(talent.crusade.enabled&cooldown.crusade.remains<gcd&holy_power>=4|holy_power>=3&time<10&talent.wake_of_ashes.enabled|cooldown.crusade.remains>=45)
   if not hastalent(crusade_talent) and { spellcooldown(avenging_wrath) < 5 and holypower() >= 3 and { buffpresent(inquisition_buff) or not hastalent(inquisition_talent) } or spellcooldown(avenging_wrath) >= 45 } or hastalent(crusade_talent) and spellcooldown(crusade) < gcd() and holypower() >= 4 or holypower() >= 3 and timeincombat() < 10 and hastalent(wake_of_ashes_talent) or spellcooldown(crusade) >= 45 spell(guardian_of_azeroth)

   unless { spellcooldown(avenging_wrath) < gcd() and holypower() >= 3 or hastalent(crusade_talent) and spellcooldown(crusade) < gcd() and holypower() >= 4 or spellcooldown(avenging_wrath) >= 45 or spellcooldown(crusade) >= 45 } and spell(worldvein_resonance_essence)
   {
    #focused_azerite_beam,if=(!raid_event.adds.exists|raid_event.adds.in>30|spell_targets.divine_storm>=2)&!(buff.avenging_wrath.up|buff.crusade.up)&(cooldown.blade_of_justice.remains>gcd*3&cooldown.judgment.remains>gcd*3)
    if { not false(raid_event_adds_exists) or 600 > 30 or enemies() >= 2 } and not { buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) } and spellcooldown(blade_of_justice) > gcd() * 3 and spellcooldown(judgment) > gcd() * 3 spell(focused_azerite_beam)
    #memory_of_lucid_dreams,if=(buff.avenging_wrath.up|buff.crusade.up&buff.crusade.stack=10)&holy_power<=3
    if { buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) and buffstacks(crusade_buff) == 10 } and holypower() <= 3 spell(memory_of_lucid_dreams_essence)

    unless { not false(raid_event_adds_exists) or 600 > 30 or enemies() >= 2 } and spell(purifying_blast)
    {
     #use_item,effect_name=cyclotronic_blast,if=!(buff.avenging_wrath.up|buff.crusade.up)&(cooldown.blade_of_justice.remains>gcd*3&cooldown.judgment.remains>gcd*3)
     if not { buffpresent(avenging_wrath_buff) or buffpresent(crusade_buff) } and spellcooldown(blade_of_justice) > gcd() * 3 and spellcooldown(judgment) > gcd() * 3 retributionuseitemactions()
     #avenging_wrath,if=(!talent.inquisition.enabled|buff.inquisition.up)&holy_power>=3
     if { not hastalent(inquisition_talent) or buffpresent(inquisition_buff) } and holypower() >= 3 spell(avenging_wrath)
     #crusade,if=holy_power>=4|holy_power>=3&time<10&talent.wake_of_ashes.enabled
     if holypower() >= 4 or holypower() >= 3 and timeincombat() < 10 and hastalent(wake_of_ashes_talent) spell(crusade)
    }
   }
  }
 }
}

AddFunction retributioncooldownscdpostconditions
{
 buffexpires(seething_rage) and buffexpires(memory_of_lucid_dreams_essence_buff) and checkboxon(opt_shield_of_vengeance) and spell(shield_of_vengeance) or { timeincombat() <= 2 or buffpresent(reckless_force_buff) } and spell(the_unbound_force) or { spellcooldown(avenging_wrath) < gcd() and holypower() >= 3 or hastalent(crusade_talent) and spellcooldown(crusade) < gcd() and holypower() >= 4 or spellcooldown(avenging_wrath) >= 45 or spellcooldown(crusade) >= 45 } and spell(worldvein_resonance_essence) or { not false(raid_event_adds_exists) or 600 > 30 or enemies() >= 2 } and spell(purifying_blast)
}

### actions.default

AddFunction retribution_defaultmainactions
{
 #call_action_list,name=cooldowns
 retributioncooldownsmainactions()

 unless retributioncooldownsmainpostconditions()
 {
  #call_action_list,name=generators
  retributiongeneratorsmainactions()
 }
}

AddFunction retribution_defaultmainpostconditions
{
 retributioncooldownsmainpostconditions() or retributiongeneratorsmainpostconditions()
}

AddFunction retribution_defaultshortcdactions
{
 #auto_attack
 retributiongetinmeleerange()
 #call_action_list,name=cooldowns
 retributioncooldownsshortcdactions()

 unless retributioncooldownsshortcdpostconditions()
 {
  #call_action_list,name=generators
  retributiongeneratorsshortcdactions()
 }
}

AddFunction retribution_defaultshortcdpostconditions
{
 retributioncooldownsshortcdpostconditions() or retributiongeneratorsshortcdpostconditions()
}

AddFunction retribution_defaultcdactions
{
 #rebuke
 retributioninterruptactions()
 #call_action_list,name=cooldowns
 retributioncooldownscdactions()

 unless retributioncooldownscdpostconditions()
 {
  #call_action_list,name=generators
  retributiongeneratorscdactions()
 }
}

AddFunction retribution_defaultcdpostconditions
{
 retributioncooldownscdpostconditions() or retributiongeneratorscdpostconditions()
}

### Retribution icons.

AddCheckBox(opt_paladin_retribution_aoe l(aoe) default specialization=retribution)

AddIcon checkbox=!opt_paladin_retribution_aoe enemies=1 help=shortcd specialization=retribution
{
 if not incombat() retributionprecombatshortcdactions()
 retribution_defaultshortcdactions()
}

AddIcon checkbox=opt_paladin_retribution_aoe help=shortcd specialization=retribution
{
 if not incombat() retributionprecombatshortcdactions()
 retribution_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=retribution
{
 if not incombat() retributionprecombatmainactions()
 retribution_defaultmainactions()
}

AddIcon checkbox=opt_paladin_retribution_aoe help=aoe specialization=retribution
{
 if not incombat() retributionprecombatmainactions()
 retribution_defaultmainactions()
}

AddIcon checkbox=!opt_paladin_retribution_aoe enemies=1 help=cd specialization=retribution
{
 if not incombat() retributionprecombatcdactions()
 retribution_defaultcdactions()
}

AddIcon checkbox=opt_paladin_retribution_aoe help=cd specialization=retribution
{
 if not incombat() retributionprecombatcdactions()
 retribution_defaultcdactions()
}

### Required symbols
# 169314
# arcane_torrent_holy
# avenging_wrath
# avenging_wrath_autocrit_buff
# avenging_wrath_buff
# blade_of_justice
# blood_of_the_enemy
# bloodlust
# concentrated_flame_essence
# condensed_life_force_essence_id
# consecration_retribution
# crusade
# crusade_buff
# crusade_talent
# crusader_strike
# divine_purpose_retribution
# divine_storm
# empyrean_power_buff
# execution_sentence
# execution_sentence_talent
# fireblood
# focused_azerite_beam
# focused_resolve_item
# guardian_of_azeroth
# hammer_of_justice
# hammer_of_wrath
# hammer_of_wrath_talent
# inquisition
# inquisition_buff
# inquisition_talent
# judgment
# lights_judgment
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# purifying_blast
# razor_coral
# reaping_flames
# rebuke
# reckless_force_buff
# righteous_verdict_talent
# seething_rage
# shield_of_vengeance
# templars_verdict
# the_unbound_force
# wake_of_ashes
# wake_of_ashes_talent
# war_stomp
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("PALADIN", "retribution", name, desc, code, "script")
    end
end
