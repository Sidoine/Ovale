local __exports = LibStub:NewLibrary("ovale/scripts/ovale_deathknight", 80300)
if not __exports then return end
__exports.registerDeathKnight = function(OvaleScripts)
    do
        local name = "sc_t24_death_knight_blood"
        local desc = "[8.3] Simulationcraft: T24_Death_Knight_Blood"
        local code = [[
# Based on SimulationCraft profile "T24_Death_Knight_Blood".
#	class=deathknight
#	spec=blood
#	talents=2220022

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=blood)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=blood)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=blood)

AddFunction bloodinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(mind_freeze) and target.isinterruptible() spell(mind_freeze)
  if target.inrange(asphyxiate) and not target.classification(worldboss) spell(asphyxiate)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
 }
}

AddFunction blooduseheartessence
{
 spell(concentrated_flame_essence)
}

AddFunction blooduseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction bloodgetinmeleerange
{
 if checkboxon(opt_melee_range) and not target.inrange(death_strike) texture(misc_arrowlup help=l(not_in_melee_range))
}

### actions.standard

AddFunction bloodstandardmainactions
{
 #death_strike,if=runic_power.deficit<=10
 if runicpowerdeficit() <= 10 spell(death_strike)
 #blooddrinker,if=!buff.dancing_rune_weapon.up
 if not buffpresent(dancing_rune_weapon_buff) spell(blooddrinker)
 #marrowrend,if=(buff.bone_shield.remains<=rune.time_to_3|buff.bone_shield.remains<=(gcd+cooldown.blooddrinker.ready*talent.blooddrinker.enabled*2)|buff.bone_shield.stack<3)&runic_power.deficit>=20
 if { buffremaining(bone_shield_buff) <= timetorunes(3) or buffremaining(bone_shield_buff) <= gcd() + { spellcooldown(blooddrinker) == 0 } * talentpoints(blooddrinker_talent) * 2 or buffstacks(bone_shield_buff) < 3 } and runicpowerdeficit() >= 20 spell(marrowrend)
 #blood_boil,if=charges_fractional>=1.8&(buff.hemostasis.stack<=(5-spell_targets.blood_boil)|spell_targets.blood_boil>2)
 if charges(blood_boil count=0) >= 1.8 and { buffstacks(hemostasis_buff) <= 5 - enemies() or enemies() > 2 } spell(blood_boil)
 #marrowrend,if=buff.bone_shield.stack<5&talent.ossuary.enabled&runic_power.deficit>=15
 if buffstacks(bone_shield_buff) < 5 and hastalent(ossuary_talent) and runicpowerdeficit() >= 15 spell(marrowrend)
 #death_strike,if=runic_power.deficit<=(15+buff.dancing_rune_weapon.up*5+spell_targets.heart_strike*talent.heartbreaker.enabled*2)|target.1.time_to_die<10
 if runicpowerdeficit() <= 15 + buffpresent(dancing_rune_weapon_buff) * 5 + enemies() * talentpoints(heartbreaker_talent) * 2 or target.timetodie() < 10 spell(death_strike)
 #heart_strike,if=buff.dancing_rune_weapon.up|rune.time_to_4<gcd
 if buffpresent(dancing_rune_weapon_buff) or timetorunes(4) < gcd() spell(heart_strike)
 #blood_boil,if=buff.dancing_rune_weapon.up
 if buffpresent(dancing_rune_weapon_buff) spell(blood_boil)
 #consumption
 spell(consumption)
 #blood_boil
 spell(blood_boil)
 #heart_strike,if=rune.time_to_3<gcd|buff.bone_shield.stack>6
 if timetorunes(3) < gcd() or buffstacks(bone_shield_buff) > 6 spell(heart_strike)
}

AddFunction bloodstandardmainpostconditions
{
}

AddFunction bloodstandardshortcdactions
{
 unless runicpowerdeficit() <= 10 and spell(death_strike) or not buffpresent(dancing_rune_weapon_buff) and spell(blooddrinker) or { buffremaining(bone_shield_buff) <= timetorunes(3) or buffremaining(bone_shield_buff) <= gcd() + { spellcooldown(blooddrinker) == 0 } * talentpoints(blooddrinker_talent) * 2 or buffstacks(bone_shield_buff) < 3 } and runicpowerdeficit() >= 20 and spell(marrowrend) or charges(blood_boil count=0) >= 1.8 and { buffstacks(hemostasis_buff) <= 5 - enemies() or enemies() > 2 } and spell(blood_boil) or buffstacks(bone_shield_buff) < 5 and hastalent(ossuary_talent) and runicpowerdeficit() >= 15 and spell(marrowrend)
 {
  #bonestorm,if=runic_power>=100&!buff.dancing_rune_weapon.up
  if runicpower() >= 100 and not buffpresent(dancing_rune_weapon_buff) spell(bonestorm)

  unless { runicpowerdeficit() <= 15 + buffpresent(dancing_rune_weapon_buff) * 5 + enemies() * talentpoints(heartbreaker_talent) * 2 or target.timetodie() < 10 } and spell(death_strike)
  {
   #death_and_decay,if=spell_targets.death_and_decay>=3
   if enemies() >= 3 spell(death_and_decay)
   #rune_strike,if=(charges_fractional>=1.8|buff.dancing_rune_weapon.up)&rune.time_to_3>=gcd
   if { charges(rune_strike count=0) >= 1.8 or buffpresent(dancing_rune_weapon_buff) } and timetorunes(3) >= gcd() spell(rune_strike)

   unless { buffpresent(dancing_rune_weapon_buff) or timetorunes(4) < gcd() } and spell(heart_strike) or buffpresent(dancing_rune_weapon_buff) and spell(blood_boil)
   {
    #death_and_decay,if=buff.crimson_scourge.up|talent.rapid_decomposition.enabled|spell_targets.death_and_decay>=2
    if buffpresent(crimson_scourge_buff) or hastalent(rapid_decomposition_talent) or enemies() >= 2 spell(death_and_decay)

    unless spell(consumption) or spell(blood_boil) or { timetorunes(3) < gcd() or buffstacks(bone_shield_buff) > 6 } and spell(heart_strike)
    {
     #rune_strike
     spell(rune_strike)
    }
   }
  }
 }
}

AddFunction bloodstandardshortcdpostconditions
{
 runicpowerdeficit() <= 10 and spell(death_strike) or not buffpresent(dancing_rune_weapon_buff) and spell(blooddrinker) or { buffremaining(bone_shield_buff) <= timetorunes(3) or buffremaining(bone_shield_buff) <= gcd() + { spellcooldown(blooddrinker) == 0 } * talentpoints(blooddrinker_talent) * 2 or buffstacks(bone_shield_buff) < 3 } and runicpowerdeficit() >= 20 and spell(marrowrend) or charges(blood_boil count=0) >= 1.8 and { buffstacks(hemostasis_buff) <= 5 - enemies() or enemies() > 2 } and spell(blood_boil) or buffstacks(bone_shield_buff) < 5 and hastalent(ossuary_talent) and runicpowerdeficit() >= 15 and spell(marrowrend) or { runicpowerdeficit() <= 15 + buffpresent(dancing_rune_weapon_buff) * 5 + enemies() * talentpoints(heartbreaker_talent) * 2 or target.timetodie() < 10 } and spell(death_strike) or { buffpresent(dancing_rune_weapon_buff) or timetorunes(4) < gcd() } and spell(heart_strike) or buffpresent(dancing_rune_weapon_buff) and spell(blood_boil) or spell(consumption) or spell(blood_boil) or { timetorunes(3) < gcd() or buffstacks(bone_shield_buff) > 6 } and spell(heart_strike)
}

AddFunction bloodstandardcdactions
{
 unless runicpowerdeficit() <= 10 and spell(death_strike) or not buffpresent(dancing_rune_weapon_buff) and spell(blooddrinker) or { buffremaining(bone_shield_buff) <= timetorunes(3) or buffremaining(bone_shield_buff) <= gcd() + { spellcooldown(blooddrinker) == 0 } * talentpoints(blooddrinker_talent) * 2 or buffstacks(bone_shield_buff) < 3 } and runicpowerdeficit() >= 20 and spell(marrowrend)
 {
  #heart_essence,if=!buff.dancing_rune_weapon.up
  if not buffpresent(dancing_rune_weapon_buff) blooduseheartessence()

  unless charges(blood_boil count=0) >= 1.8 and { buffstacks(hemostasis_buff) <= 5 - enemies() or enemies() > 2 } and spell(blood_boil) or buffstacks(bone_shield_buff) < 5 and hastalent(ossuary_talent) and runicpowerdeficit() >= 15 and spell(marrowrend) or runicpower() >= 100 and not buffpresent(dancing_rune_weapon_buff) and spell(bonestorm) or { runicpowerdeficit() <= 15 + buffpresent(dancing_rune_weapon_buff) * 5 + enemies() * talentpoints(heartbreaker_talent) * 2 or target.timetodie() < 10 } and spell(death_strike) or enemies() >= 3 and spell(death_and_decay) or { charges(rune_strike count=0) >= 1.8 or buffpresent(dancing_rune_weapon_buff) } and timetorunes(3) >= gcd() and spell(rune_strike) or { buffpresent(dancing_rune_weapon_buff) or timetorunes(4) < gcd() } and spell(heart_strike) or buffpresent(dancing_rune_weapon_buff) and spell(blood_boil) or { buffpresent(crimson_scourge_buff) or hastalent(rapid_decomposition_talent) or enemies() >= 2 } and spell(death_and_decay) or spell(consumption) or spell(blood_boil) or { timetorunes(3) < gcd() or buffstacks(bone_shield_buff) > 6 } and spell(heart_strike)
  {
   #use_item,name=grongs_primal_rage
   blooduseitemactions()

   unless spell(rune_strike)
   {
    #arcane_torrent,if=runic_power.deficit>20
    if runicpowerdeficit() > 20 spell(arcane_torrent_runicpower)
   }
  }
 }
}

AddFunction bloodstandardcdpostconditions
{
 runicpowerdeficit() <= 10 and spell(death_strike) or not buffpresent(dancing_rune_weapon_buff) and spell(blooddrinker) or { buffremaining(bone_shield_buff) <= timetorunes(3) or buffremaining(bone_shield_buff) <= gcd() + { spellcooldown(blooddrinker) == 0 } * talentpoints(blooddrinker_talent) * 2 or buffstacks(bone_shield_buff) < 3 } and runicpowerdeficit() >= 20 and spell(marrowrend) or charges(blood_boil count=0) >= 1.8 and { buffstacks(hemostasis_buff) <= 5 - enemies() or enemies() > 2 } and spell(blood_boil) or buffstacks(bone_shield_buff) < 5 and hastalent(ossuary_talent) and runicpowerdeficit() >= 15 and spell(marrowrend) or runicpower() >= 100 and not buffpresent(dancing_rune_weapon_buff) and spell(bonestorm) or { runicpowerdeficit() <= 15 + buffpresent(dancing_rune_weapon_buff) * 5 + enemies() * talentpoints(heartbreaker_talent) * 2 or target.timetodie() < 10 } and spell(death_strike) or enemies() >= 3 and spell(death_and_decay) or { charges(rune_strike count=0) >= 1.8 or buffpresent(dancing_rune_weapon_buff) } and timetorunes(3) >= gcd() and spell(rune_strike) or { buffpresent(dancing_rune_weapon_buff) or timetorunes(4) < gcd() } and spell(heart_strike) or buffpresent(dancing_rune_weapon_buff) and spell(blood_boil) or { buffpresent(crimson_scourge_buff) or hastalent(rapid_decomposition_talent) or enemies() >= 2 } and spell(death_and_decay) or spell(consumption) or spell(blood_boil) or { timetorunes(3) < gcd() or buffstacks(bone_shield_buff) > 6 } and spell(heart_strike) or spell(rune_strike)
}

### actions.precombat

AddFunction bloodprecombatmainactions
{
}

AddFunction bloodprecombatmainpostconditions
{
}

AddFunction bloodprecombatshortcdactions
{
}

AddFunction bloodprecombatshortcdpostconditions
{
}

AddFunction bloodprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
}

AddFunction bloodprecombatcdpostconditions
{
}

### actions.default

AddFunction blood_defaultmainactions
{
 #call_action_list,name=standard
 bloodstandardmainactions()
}

AddFunction blood_defaultmainpostconditions
{
 bloodstandardmainpostconditions()
}

AddFunction blood_defaultshortcdactions
{
 #auto_attack
 bloodgetinmeleerange()
 #bag_of_tricks
 spell(bag_of_tricks)
 #tombstone,if=buff.bone_shield.stack>=7
 if buffstacks(bone_shield_buff) >= 7 spell(tombstone)
 #call_action_list,name=standard
 bloodstandardshortcdactions()
}

AddFunction blood_defaultshortcdpostconditions
{
 bloodstandardshortcdpostconditions()
}

AddFunction blood_defaultcdactions
{
 bloodinterruptactions()
 #blood_fury,if=cooldown.dancing_rune_weapon.ready&(!cooldown.blooddrinker.ready|!talent.blooddrinker.enabled)
 if spellcooldown(dancing_rune_weapon) == 0 and { not spellcooldown(blooddrinker) == 0 or not hastalent(blooddrinker_talent) } spell(blood_fury_ap)
 #berserking
 spell(berserking)
 #arcane_pulse,if=active_enemies>=2|rune<1&runic_power.deficit>60
 if enemies() >= 2 or runecount() < 1 and runicpowerdeficit() > 60 spell(arcane_pulse)
 #lights_judgment,if=buff.unholy_strength.up
 if buffpresent(unholy_strength_buff) spell(lights_judgment)
 #ancestral_call
 spell(ancestral_call)
 #fireblood
 spell(fireblood)

 unless spell(bag_of_tricks)
 {
  #use_items,if=cooldown.dancing_rune_weapon.remains>90
  if spellcooldown(dancing_rune_weapon) > 90 blooduseitemactions()
  #use_item,name=razdunks_big_red_button
  blooduseitemactions()
  #use_item,name=merekthas_fang
  blooduseitemactions()
  #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down
  if target.debuffexpires(razor_coral) blooduseitemactions()
  #use_item,name=ashvanes_razor_coral,if=target.health.pct<31&equipped.dribbling_inkpod
  if target.healthpercent() < 31 and hasequippeditem(dribbling_inkpod_item) blooduseitemactions()
  #use_item,name=ashvanes_razor_coral,if=buff.dancing_rune_weapon.up&debuff.razor_coral_debuff.up&!equipped.dribbling_inkpod
  if buffpresent(dancing_rune_weapon_buff) and target.debuffpresent(razor_coral) and not hasequippeditem(dribbling_inkpod_item) blooduseitemactions()
  #potion,if=buff.dancing_rune_weapon.up
  if buffpresent(dancing_rune_weapon_buff) and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
  #dancing_rune_weapon,if=!talent.blooddrinker.enabled|!cooldown.blooddrinker.ready
  if not hastalent(blooddrinker_talent) or not spellcooldown(blooddrinker) == 0 spell(dancing_rune_weapon)

  unless buffstacks(bone_shield_buff) >= 7 and spell(tombstone)
  {
   #call_action_list,name=standard
   bloodstandardcdactions()
  }
 }
}

AddFunction blood_defaultcdpostconditions
{
 spell(bag_of_tricks) or buffstacks(bone_shield_buff) >= 7 and spell(tombstone) or bloodstandardcdpostconditions()
}

### Blood icons.

AddCheckBox(opt_deathknight_blood_aoe l(aoe) default specialization=blood)

AddIcon checkbox=!opt_deathknight_blood_aoe enemies=1 help=shortcd specialization=blood
{
 if not incombat() bloodprecombatshortcdactions()
 blood_defaultshortcdactions()
}

AddIcon checkbox=opt_deathknight_blood_aoe help=shortcd specialization=blood
{
 if not incombat() bloodprecombatshortcdactions()
 blood_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=blood
{
 if not incombat() bloodprecombatmainactions()
 blood_defaultmainactions()
}

AddIcon checkbox=opt_deathknight_blood_aoe help=aoe specialization=blood
{
 if not incombat() bloodprecombatmainactions()
 blood_defaultmainactions()
}

AddIcon checkbox=!opt_deathknight_blood_aoe enemies=1 help=cd specialization=blood
{
 if not incombat() bloodprecombatcdactions()
 blood_defaultcdactions()
}

AddIcon checkbox=opt_deathknight_blood_aoe help=cd specialization=blood
{
 if not incombat() bloodprecombatcdactions()
 blood_defaultcdactions()
}

### Required symbols
# ancestral_call
# arcane_pulse
# arcane_torrent_runicpower
# asphyxiate
# bag_of_tricks
# berserking
# blood_boil
# blood_fury_ap
# blooddrinker
# blooddrinker_talent
# bone_shield_buff
# bonestorm
# concentrated_flame_essence
# consumption
# crimson_scourge_buff
# dancing_rune_weapon
# dancing_rune_weapon_buff
# death_and_decay
# death_strike
# dribbling_inkpod_item
# fireblood
# heart_strike
# heartbreaker_talent
# hemostasis_buff
# lights_judgment
# marrowrend
# mind_freeze
# ossuary_talent
# rapid_decomposition_talent
# razor_coral
# rune_strike
# tombstone
# unbridled_fury_item
# unholy_strength_buff
# war_stomp
]]
        OvaleScripts:RegisterScript("DEATHKNIGHT", "blood", name, desc, code, "script")
    end
    do
        local name = "sc_t24_death_knight_frost"
        local desc = "[8.3] Simulationcraft: T24_Death_Knight_Frost"
        local code = [[
# Based on SimulationCraft profile "T24_Death_Knight_Frost".
#	class=deathknight
#	spec=frost
#	talents=3102013

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)


AddFunction other_on_use_equipped
{
 hasequippeditem(notorious_gladiators_badge_item) or hasequippeditem(sinister_gladiators_badge_item) or hasequippeditem(sinister_gladiators_medallion_item) or hasequippeditem(vial_of_animated_blood_item) or hasequippeditem(first_mates_spyglass_item) or hasequippeditem(jes_howler_item) or hasequippeditem(notorious_gladiators_medallion_item) or hasequippeditem(ashvanes_razor_coral_item)
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=frost)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=frost)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=frost)

AddFunction frostinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(mind_freeze) and target.isinterruptible() spell(mind_freeze)
  if target.distance(less 12) and not target.classification(worldboss) spell(blinding_sleet)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
 }
}

AddFunction frostuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction frostgetinmeleerange
{
 if checkboxon(opt_melee_range) and not target.inrange(death_strike) texture(misc_arrowlup help=l(not_in_melee_range))
}

### actions.standard

AddFunction froststandardmainactions
{
 #remorseless_winter
 spell(remorseless_winter)
 #frost_strike,if=cooldown.remorseless_winter.remains<=2*gcd&talent.gathering_storm.enabled
 if spellcooldown(remorseless_winter) <= 2 * gcd() and hastalent(gathering_storm_talent) spell(frost_strike)
 #howling_blast,if=buff.rime.up
 if buffpresent(rime_buff) spell(howling_blast)
 #obliterate,if=talent.icecap.enabled&buff.pillar_of_frost.up&azerite.icy_citadel.rank>=2
 if hastalent(icecap_talent) and buffpresent(pillar_of_frost_buff) and azeritetraitrank(icy_citadel_trait) >= 2 spell(obliterate)
 #obliterate,if=!buff.frozen_pulse.up&talent.frozen_pulse.enabled
 if not buffpresent(frozen_pulse_buff) and hastalent(frozen_pulse_talent) spell(obliterate)
 #frost_strike,if=runic_power.deficit<(15+talent.runic_attenuation.enabled*3)
 if runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 spell(frost_strike)
 #frostscythe,if=buff.killing_machine.up&rune.time_to_4>=gcd
 if buffpresent(killing_machine_buff) and timetorunes(4) >= gcd() spell(frostscythe)
 #obliterate,if=runic_power.deficit>(25+talent.runic_attenuation.enabled*3)
 if runicpowerdeficit() > 25 + talentpoints(runic_attenuation_talent) * 3 spell(obliterate)
 #frost_strike
 spell(frost_strike)
 #horn_of_winter
 spell(horn_of_winter)
}

AddFunction froststandardmainpostconditions
{
}

AddFunction froststandardshortcdactions
{
}

AddFunction froststandardshortcdpostconditions
{
 spell(remorseless_winter) or spellcooldown(remorseless_winter) <= 2 * gcd() and hastalent(gathering_storm_talent) and spell(frost_strike) or buffpresent(rime_buff) and spell(howling_blast) or hastalent(icecap_talent) and buffpresent(pillar_of_frost_buff) and azeritetraitrank(icy_citadel_trait) >= 2 and spell(obliterate) or not buffpresent(frozen_pulse_buff) and hastalent(frozen_pulse_talent) and spell(obliterate) or runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and spell(frost_strike) or buffpresent(killing_machine_buff) and timetorunes(4) >= gcd() and spell(frostscythe) or runicpowerdeficit() > 25 + talentpoints(runic_attenuation_talent) * 3 and spell(obliterate) or spell(frost_strike) or spell(horn_of_winter)
}

AddFunction froststandardcdactions
{
 unless spell(remorseless_winter) or spellcooldown(remorseless_winter) <= 2 * gcd() and hastalent(gathering_storm_talent) and spell(frost_strike) or buffpresent(rime_buff) and spell(howling_blast) or hastalent(icecap_talent) and buffpresent(pillar_of_frost_buff) and azeritetraitrank(icy_citadel_trait) >= 2 and spell(obliterate) or not buffpresent(frozen_pulse_buff) and hastalent(frozen_pulse_talent) and spell(obliterate) or runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and spell(frost_strike) or buffpresent(killing_machine_buff) and timetorunes(4) >= gcd() and spell(frostscythe) or runicpowerdeficit() > 25 + talentpoints(runic_attenuation_talent) * 3 and spell(obliterate) or spell(frost_strike) or spell(horn_of_winter)
 {
  #arcane_torrent
  spell(arcane_torrent_runicpower)
 }
}

AddFunction froststandardcdpostconditions
{
 spell(remorseless_winter) or spellcooldown(remorseless_winter) <= 2 * gcd() and hastalent(gathering_storm_talent) and spell(frost_strike) or buffpresent(rime_buff) and spell(howling_blast) or hastalent(icecap_talent) and buffpresent(pillar_of_frost_buff) and azeritetraitrank(icy_citadel_trait) >= 2 and spell(obliterate) or not buffpresent(frozen_pulse_buff) and hastalent(frozen_pulse_talent) and spell(obliterate) or runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and spell(frost_strike) or buffpresent(killing_machine_buff) and timetorunes(4) >= gcd() and spell(frostscythe) or runicpowerdeficit() > 25 + talentpoints(runic_attenuation_talent) * 3 and spell(obliterate) or spell(frost_strike) or spell(horn_of_winter)
}

### actions.precombat

AddFunction frostprecombatmainactions
{
}

AddFunction frostprecombatmainpostconditions
{
}

AddFunction frostprecombatshortcdactions
{
}

AddFunction frostprecombatshortcdpostconditions
{
}

AddFunction frostprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #use_item,name=azsharas_font_of_power
 frostuseitemactions()
}

AddFunction frostprecombatcdpostconditions
{
}

### actions.obliteration

AddFunction frostobliterationmainactions
{
 #remorseless_winter,if=talent.gathering_storm.enabled
 if hastalent(gathering_storm_talent) spell(remorseless_winter)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&!talent.frostscythe.enabled&!buff.rime.up&spell_targets.howling_blast>=3
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and not hastalent(frostscythe_talent) and not buffpresent(rime_buff) and enemies() >= 3 spell(obliterate)
 #obliterate,if=!talent.frostscythe.enabled&!buff.rime.up&spell_targets.howling_blast>=3
 if not hastalent(frostscythe_talent) and not buffpresent(rime_buff) and enemies() >= 3 spell(obliterate)
 #frostscythe,if=(buff.killing_machine.react|(buff.killing_machine.up&(prev_gcd.1.frost_strike|prev_gcd.1.howling_blast|prev_gcd.1.glacial_advance)))&spell_targets.frostscythe>=2
 if { buffpresent(killing_machine_buff) or buffpresent(killing_machine_buff) and { previousgcdspell(frost_strike) or previousgcdspell(howling_blast) or previousgcdspell(glacial_advance) } } and enemies() >= 2 spell(frostscythe)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&buff.killing_machine.react|(buff.killing_machine.up&(prev_gcd.1.frost_strike|prev_gcd.1.howling_blast|prev_gcd.1.glacial_advance))
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and buffpresent(killing_machine_buff) or buffpresent(killing_machine_buff) and { previousgcdspell(frost_strike) or previousgcdspell(howling_blast) or previousgcdspell(glacial_advance) } spell(obliterate)
 #obliterate,if=buff.killing_machine.react|(buff.killing_machine.up&(prev_gcd.1.frost_strike|prev_gcd.1.howling_blast|prev_gcd.1.glacial_advance))
 if buffpresent(killing_machine_buff) or buffpresent(killing_machine_buff) and { previousgcdspell(frost_strike) or previousgcdspell(howling_blast) or previousgcdspell(glacial_advance) } spell(obliterate)
 #glacial_advance,if=(!buff.rime.up|runic_power.deficit<10|rune.time_to_2>gcd)&spell_targets.glacial_advance>=2
 if { not buffpresent(rime_buff) or runicpowerdeficit() < 10 or timetorunes(2) > gcd() } and enemies() >= 2 spell(glacial_advance)
 #howling_blast,if=buff.rime.up&spell_targets.howling_blast>=2
 if buffpresent(rime_buff) and enemies() >= 2 spell(howling_blast)
 #frost_strike,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&!buff.rime.up|runic_power.deficit<10|rune.time_to_2>gcd&!talent.frostscythe.enabled
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and not buffpresent(rime_buff) or runicpowerdeficit() < 10 or timetorunes(2) > gcd() and not hastalent(frostscythe_talent) spell(frost_strike)
 #frost_strike,if=!buff.rime.up|runic_power.deficit<10|rune.time_to_2>gcd
 if not buffpresent(rime_buff) or runicpowerdeficit() < 10 or timetorunes(2) > gcd() spell(frost_strike)
 #howling_blast,if=buff.rime.up
 if buffpresent(rime_buff) spell(howling_blast)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&!talent.frostscythe.enabled
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and not hastalent(frostscythe_talent) spell(obliterate)
 #obliterate
 spell(obliterate)
}

AddFunction frostobliterationmainpostconditions
{
}

AddFunction frostobliterationshortcdactions
{
}

AddFunction frostobliterationshortcdpostconditions
{
 hastalent(gathering_storm_talent) and spell(remorseless_winter) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and not hastalent(frostscythe_talent) and not buffpresent(rime_buff) and enemies() >= 3 and spell(obliterate) or not hastalent(frostscythe_talent) and not buffpresent(rime_buff) and enemies() >= 3 and spell(obliterate) or { buffpresent(killing_machine_buff) or buffpresent(killing_machine_buff) and { previousgcdspell(frost_strike) or previousgcdspell(howling_blast) or previousgcdspell(glacial_advance) } } and enemies() >= 2 and spell(frostscythe) or { { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and buffpresent(killing_machine_buff) or buffpresent(killing_machine_buff) and { previousgcdspell(frost_strike) or previousgcdspell(howling_blast) or previousgcdspell(glacial_advance) } } and spell(obliterate) or { buffpresent(killing_machine_buff) or buffpresent(killing_machine_buff) and { previousgcdspell(frost_strike) or previousgcdspell(howling_blast) or previousgcdspell(glacial_advance) } } and spell(obliterate) or { not buffpresent(rime_buff) or runicpowerdeficit() < 10 or timetorunes(2) > gcd() } and enemies() >= 2 and spell(glacial_advance) or buffpresent(rime_buff) and enemies() >= 2 and spell(howling_blast) or { { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and not buffpresent(rime_buff) or runicpowerdeficit() < 10 or timetorunes(2) > gcd() and not hastalent(frostscythe_talent) } and spell(frost_strike) or { not buffpresent(rime_buff) or runicpowerdeficit() < 10 or timetorunes(2) > gcd() } and spell(frost_strike) or buffpresent(rime_buff) and spell(howling_blast) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and not hastalent(frostscythe_talent) and spell(obliterate) or spell(obliterate)
}

AddFunction frostobliterationcdactions
{
}

AddFunction frostobliterationcdpostconditions
{
 hastalent(gathering_storm_talent) and spell(remorseless_winter) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and not hastalent(frostscythe_talent) and not buffpresent(rime_buff) and enemies() >= 3 and spell(obliterate) or not hastalent(frostscythe_talent) and not buffpresent(rime_buff) and enemies() >= 3 and spell(obliterate) or { buffpresent(killing_machine_buff) or buffpresent(killing_machine_buff) and { previousgcdspell(frost_strike) or previousgcdspell(howling_blast) or previousgcdspell(glacial_advance) } } and enemies() >= 2 and spell(frostscythe) or { { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and buffpresent(killing_machine_buff) or buffpresent(killing_machine_buff) and { previousgcdspell(frost_strike) or previousgcdspell(howling_blast) or previousgcdspell(glacial_advance) } } and spell(obliterate) or { buffpresent(killing_machine_buff) or buffpresent(killing_machine_buff) and { previousgcdspell(frost_strike) or previousgcdspell(howling_blast) or previousgcdspell(glacial_advance) } } and spell(obliterate) or { not buffpresent(rime_buff) or runicpowerdeficit() < 10 or timetorunes(2) > gcd() } and enemies() >= 2 and spell(glacial_advance) or buffpresent(rime_buff) and enemies() >= 2 and spell(howling_blast) or { { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and not buffpresent(rime_buff) or runicpowerdeficit() < 10 or timetorunes(2) > gcd() and not hastalent(frostscythe_talent) } and spell(frost_strike) or { not buffpresent(rime_buff) or runicpowerdeficit() < 10 or timetorunes(2) > gcd() } and spell(frost_strike) or buffpresent(rime_buff) and spell(howling_blast) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and not hastalent(frostscythe_talent) and spell(obliterate) or spell(obliterate)
}

### actions.essences

AddFunction frostessencesmainactions
{
 #concentrated_flame,if=!buff.pillar_of_frost.up&!buff.breath_of_sindragosa.up&dot.concentrated_flame_burn.remains=0
 if not buffpresent(pillar_of_frost_buff) and not buffpresent(breath_of_sindragosa_buff) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 spell(concentrated_flame_essence)
}

AddFunction frostessencesmainpostconditions
{
}

AddFunction frostessencesshortcdactions
{
 #chill_streak,if=buff.pillar_of_frost.remains<5&buff.pillar_of_frost.up|target.1.time_to_die<5
 if buffremaining(pillar_of_frost_buff) < 5 and buffpresent(pillar_of_frost_buff) or target.timetodie() < 5 spell(chill_streak)
 #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<11
 if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 11 spell(the_unbound_force)

 unless not buffpresent(pillar_of_frost_buff) and not buffpresent(breath_of_sindragosa_buff) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence)
 {
  #purifying_blast,if=!buff.pillar_of_frost.up&!buff.breath_of_sindragosa.up
  if not buffpresent(pillar_of_frost_buff) and not buffpresent(breath_of_sindragosa_buff) spell(purifying_blast)
  #worldvein_resonance,if=buff.pillar_of_frost.up|buff.empower_rune_weapon.up|cooldown.breath_of_sindragosa.remains>60+15
  if buffpresent(pillar_of_frost_buff) or buffpresent(empower_rune_weapon_buff) or spellcooldown(breath_of_sindragosa) > 60 + 15 spell(worldvein_resonance_essence)
  #ripple_in_space,if=!buff.pillar_of_frost.up&!buff.breath_of_sindragosa.up
  if not buffpresent(pillar_of_frost_buff) and not buffpresent(breath_of_sindragosa_buff) spell(ripple_in_space_essence)
  #reaping_flames
  spell(reaping_flames)
 }
}

AddFunction frostessencesshortcdpostconditions
{
 not buffpresent(pillar_of_frost_buff) and not buffpresent(breath_of_sindragosa_buff) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence)
}

AddFunction frostessencescdactions
{
 #blood_of_the_enemy,if=buff.pillar_of_frost.up&(buff.pillar_of_frost.remains<10&(buff.breath_of_sindragosa.up|talent.obliteration.enabled|talent.icecap.enabled&!azerite.icy_citadel.enabled)|buff.icy_citadel.up&talent.icecap.enabled)
 if buffpresent(pillar_of_frost_buff) and { buffremaining(pillar_of_frost_buff) < 10 and { buffpresent(breath_of_sindragosa_buff) or hastalent(obliteration_talent) or hastalent(icecap_talent) and not hasazeritetrait(icy_citadel_trait) } or buffpresent(icy_citadel_expires_buff) and hastalent(icecap_talent) } spell(blood_of_the_enemy)
 #guardian_of_azeroth,if=!talent.icecap.enabled|talent.icecap.enabled&azerite.icy_citadel.enabled&buff.pillar_of_frost.remains<6&buff.pillar_of_frost.up|talent.icecap.enabled&!azerite.icy_citadel.enabled
 if not hastalent(icecap_talent) or hastalent(icecap_talent) and hasazeritetrait(icy_citadel_trait) and buffremaining(pillar_of_frost_buff) < 6 and buffpresent(pillar_of_frost_buff) or hastalent(icecap_talent) and not hasazeritetrait(icy_citadel_trait) spell(guardian_of_azeroth)

 unless { buffremaining(pillar_of_frost_buff) < 5 and buffpresent(pillar_of_frost_buff) or target.timetodie() < 5 } and spell(chill_streak) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 11 } and spell(the_unbound_force)
 {
  #focused_azerite_beam,if=!buff.pillar_of_frost.up&!buff.breath_of_sindragosa.up
  if not buffpresent(pillar_of_frost_buff) and not buffpresent(breath_of_sindragosa_buff) spell(focused_azerite_beam)

  unless not buffpresent(pillar_of_frost_buff) and not buffpresent(breath_of_sindragosa_buff) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence) or not buffpresent(pillar_of_frost_buff) and not buffpresent(breath_of_sindragosa_buff) and spell(purifying_blast) or { buffpresent(pillar_of_frost_buff) or buffpresent(empower_rune_weapon_buff) or spellcooldown(breath_of_sindragosa) > 60 + 15 } and spell(worldvein_resonance_essence) or not buffpresent(pillar_of_frost_buff) and not buffpresent(breath_of_sindragosa_buff) and spell(ripple_in_space_essence)
  {
   #memory_of_lucid_dreams,if=buff.empower_rune_weapon.remains<5&buff.breath_of_sindragosa.up|(rune.time_to_2>gcd&runic_power<50)
   if buffremaining(empower_rune_weapon_buff) < 5 and buffpresent(breath_of_sindragosa_buff) or timetorunes(2) > gcd() and runicpower() < 50 spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction frostessencescdpostconditions
{
 { buffremaining(pillar_of_frost_buff) < 5 and buffpresent(pillar_of_frost_buff) or target.timetodie() < 5 } and spell(chill_streak) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 11 } and spell(the_unbound_force) or not buffpresent(pillar_of_frost_buff) and not buffpresent(breath_of_sindragosa_buff) and not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence) or not buffpresent(pillar_of_frost_buff) and not buffpresent(breath_of_sindragosa_buff) and spell(purifying_blast) or { buffpresent(pillar_of_frost_buff) or buffpresent(empower_rune_weapon_buff) or spellcooldown(breath_of_sindragosa) > 60 + 15 } and spell(worldvein_resonance_essence) or not buffpresent(pillar_of_frost_buff) and not buffpresent(breath_of_sindragosa_buff) and spell(ripple_in_space_essence) or spell(reaping_flames)
}

### actions.cooldowns

AddFunction frostcooldownsmainactions
{
 #call_action_list,name=cold_heart,if=talent.cold_heart.enabled&((buff.cold_heart.stack>=10&debuff.razorice.stack=5)|target.1.time_to_die<=gcd)
 if hastalent(cold_heart_talent) and { buffstacks(cold_heart_buff) >= 10 and target.debuffstacks(razorice_debuff) == 5 or target.timetodie() <= gcd() } frostcold_heartmainactions()
}

AddFunction frostcooldownsmainpostconditions
{
 hastalent(cold_heart_talent) and { buffstacks(cold_heart_buff) >= 10 and target.debuffstacks(razorice_debuff) == 5 or target.timetodie() <= gcd() } and frostcold_heartmainpostconditions()
}

AddFunction frostcooldownsshortcdactions
{
 #bag_of_tricks,if=buff.pillar_of_frost.up&(buff.pillar_of_frost.remains<5&talent.cold_heart.enabled|!talent.cold_heart.enabled&buff.pillar_of_frost.remains<3)|buff.seething_rage.up
 if buffpresent(pillar_of_frost_buff) and { buffremaining(pillar_of_frost_buff) < 5 and hastalent(cold_heart_talent) or not hastalent(cold_heart_talent) and buffremaining(pillar_of_frost_buff) < 3 } or buffpresent(seething_rage) spell(bag_of_tricks)
 #pillar_of_frost,if=cooldown.empower_rune_weapon.remains|talent.icecap.enabled
 if spellcooldown(empower_rune_weapon) > 0 or hastalent(icecap_talent) spell(pillar_of_frost)
 #call_action_list,name=cold_heart,if=talent.cold_heart.enabled&((buff.cold_heart.stack>=10&debuff.razorice.stack=5)|target.1.time_to_die<=gcd)
 if hastalent(cold_heart_talent) and { buffstacks(cold_heart_buff) >= 10 and target.debuffstacks(razorice_debuff) == 5 or target.timetodie() <= gcd() } frostcold_heartshortcdactions()
}

AddFunction frostcooldownsshortcdpostconditions
{
 hastalent(cold_heart_talent) and { buffstacks(cold_heart_buff) >= 10 and target.debuffstacks(razorice_debuff) == 5 or target.timetodie() <= gcd() } and frostcold_heartshortcdpostconditions()
}

AddFunction frostcooldownscdactions
{
 #use_item,name=azsharas_font_of_power,if=(cooldown.empowered_rune_weapon.ready&!variable.other_on_use_equipped)|(cooldown.pillar_of_frost.remains<=10&variable.other_on_use_equipped)
 if spellcooldown(empower_rune_weapon) == 0 and not other_on_use_equipped() or spellcooldown(pillar_of_frost) <= 10 and other_on_use_equipped() frostuseitemactions()
 #use_item,name=lurkers_insidious_gift,if=talent.breath_of_sindragosa.enabled&((cooldown.pillar_of_frost.remains<=10&variable.other_on_use_equipped)|(buff.pillar_of_frost.up&!variable.other_on_use_equipped))|(buff.pillar_of_frost.up&!talent.breath_of_sindragosa.enabled)
 if hastalent(breath_of_sindragosa_talent) and { spellcooldown(pillar_of_frost) <= 10 and other_on_use_equipped() or buffpresent(pillar_of_frost_buff) and not other_on_use_equipped() } or buffpresent(pillar_of_frost_buff) and not hastalent(breath_of_sindragosa_talent) frostuseitemactions()
 #use_item,name=cyclotronic_blast,if=!buff.pillar_of_frost.up
 if not buffpresent(pillar_of_frost_buff) frostuseitemactions()
 #use_items,if=(cooldown.pillar_of_frost.ready|cooldown.pillar_of_frost.remains>20)&(!talent.breath_of_sindragosa.enabled|cooldown.empower_rune_weapon.remains>95)
 if { spellcooldown(pillar_of_frost) == 0 or spellcooldown(pillar_of_frost) > 20 } and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(empower_rune_weapon) > 95 } frostuseitemactions()
 #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down
 if target.debuffexpires(razor_coral) frostuseitemactions()
 #use_item,name=ashvanes_razor_coral,if=cooldown.empower_rune_weapon.remains>90&debuff.razor_coral_debuff.up&variable.other_on_use_equipped|buff.breath_of_sindragosa.up&debuff.razor_coral_debuff.up&!variable.other_on_use_equipped|buff.empower_rune_weapon.up&debuff.razor_coral_debuff.up&!talent.breath_of_sindragosa.enabled|target.1.time_to_die<21
 if spellcooldown(empower_rune_weapon) > 90 and target.debuffpresent(razor_coral) and other_on_use_equipped() or buffpresent(breath_of_sindragosa_buff) and target.debuffpresent(razor_coral) and not other_on_use_equipped() or buffpresent(empower_rune_weapon_buff) and target.debuffpresent(razor_coral) and not hastalent(breath_of_sindragosa_talent) or target.timetodie() < 21 frostuseitemactions()
 #use_item,name=jes_howler,if=(equipped.lurkers_insidious_gift&buff.pillar_of_frost.remains)|(!equipped.lurkers_insidious_gift&buff.pillar_of_frost.remains<12&buff.pillar_of_frost.up)
 if hasequippeditem(lurkers_insidious_gift_item) and buffpresent(pillar_of_frost_buff) or not hasequippeditem(lurkers_insidious_gift_item) and buffremaining(pillar_of_frost_buff) < 12 and buffpresent(pillar_of_frost_buff) frostuseitemactions()
 #use_item,name=knot_of_ancient_fury,if=cooldown.empower_rune_weapon.remains>40
 if spellcooldown(empower_rune_weapon) > 40 frostuseitemactions()
 #use_item,name=grongs_primal_rage,if=rune<=3&!buff.pillar_of_frost.up&(!buff.breath_of_sindragosa.up|!talent.breath_of_sindragosa.enabled)
 if runecount() <= 3 and not buffpresent(pillar_of_frost_buff) and { not buffpresent(breath_of_sindragosa_buff) or not hastalent(breath_of_sindragosa_talent) } frostuseitemactions()
 #use_item,name=razdunks_big_red_button
 frostuseitemactions()
 #use_item,name=merekthas_fang,if=!buff.breath_of_sindragosa.up&!buff.pillar_of_frost.up
 if not buffpresent(breath_of_sindragosa_buff) and not buffpresent(pillar_of_frost_buff) frostuseitemactions()
 #potion,if=buff.pillar_of_frost.up&buff.empower_rune_weapon.up
 if buffpresent(pillar_of_frost_buff) and buffpresent(empower_rune_weapon_buff) and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #blood_fury,if=buff.pillar_of_frost.up&buff.empower_rune_weapon.up
 if buffpresent(pillar_of_frost_buff) and buffpresent(empower_rune_weapon_buff) spell(blood_fury_ap)
 #berserking,if=buff.pillar_of_frost.up
 if buffpresent(pillar_of_frost_buff) spell(berserking)
 #arcane_pulse,if=(!buff.pillar_of_frost.up&active_enemies>=2)|!buff.pillar_of_frost.up&(rune.deficit>=5&runic_power.deficit>=60)
 if not buffpresent(pillar_of_frost_buff) and enemies() >= 2 or not buffpresent(pillar_of_frost_buff) and runedeficit() >= 5 and runicpowerdeficit() >= 60 spell(arcane_pulse)
 #lights_judgment,if=buff.pillar_of_frost.up
 if buffpresent(pillar_of_frost_buff) spell(lights_judgment)
 #ancestral_call,if=buff.pillar_of_frost.up&buff.empower_rune_weapon.up
 if buffpresent(pillar_of_frost_buff) and buffpresent(empower_rune_weapon_buff) spell(ancestral_call)
 #fireblood,if=buff.pillar_of_frost.remains<=8&buff.empower_rune_weapon.up
 if buffremaining(pillar_of_frost_buff) <= 8 and buffpresent(empower_rune_weapon_buff) spell(fireblood)

 unless { buffpresent(pillar_of_frost_buff) and { buffremaining(pillar_of_frost_buff) < 5 and hastalent(cold_heart_talent) or not hastalent(cold_heart_talent) and buffremaining(pillar_of_frost_buff) < 3 } or buffpresent(seething_rage) } and spell(bag_of_tricks) or { spellcooldown(empower_rune_weapon) > 0 or hastalent(icecap_talent) } and spell(pillar_of_frost)
 {
  #breath_of_sindragosa,use_off_gcd=1,if=cooldown.empower_rune_weapon.remains&cooldown.pillar_of_frost.remains
  if spellcooldown(empower_rune_weapon) > 0 and spellcooldown(pillar_of_frost) > 0 spell(breath_of_sindragosa)
  #empower_rune_weapon,if=cooldown.pillar_of_frost.ready&talent.obliteration.enabled&rune.time_to_5>gcd&runic_power.deficit>=10|target.1.time_to_die<20
  if spellcooldown(pillar_of_frost) == 0 and hastalent(obliteration_talent) and timetorunes(5) > gcd() and runicpowerdeficit() >= 10 or target.timetodie() < 20 spell(empower_rune_weapon)
  #empower_rune_weapon,if=(cooldown.pillar_of_frost.ready|target.1.time_to_die<20)&talent.breath_of_sindragosa.enabled&runic_power>60
  if { spellcooldown(pillar_of_frost) == 0 or target.timetodie() < 20 } and hastalent(breath_of_sindragosa_talent) and runicpower() > 60 spell(empower_rune_weapon)
  #empower_rune_weapon,if=talent.icecap.enabled&rune<3
  if hastalent(icecap_talent) and runecount() < 3 spell(empower_rune_weapon)
  #call_action_list,name=cold_heart,if=talent.cold_heart.enabled&((buff.cold_heart.stack>=10&debuff.razorice.stack=5)|target.1.time_to_die<=gcd)
  if hastalent(cold_heart_talent) and { buffstacks(cold_heart_buff) >= 10 and target.debuffstacks(razorice_debuff) == 5 or target.timetodie() <= gcd() } frostcold_heartcdactions()

  unless hastalent(cold_heart_talent) and { buffstacks(cold_heart_buff) >= 10 and target.debuffstacks(razorice_debuff) == 5 or target.timetodie() <= gcd() } and frostcold_heartcdpostconditions()
  {
   #frostwyrms_fury,if=(buff.pillar_of_frost.up&azerite.icy_citadel.rank<=1&(buff.pillar_of_frost.remains<=gcd|buff.unholy_strength.remains<=gcd&buff.unholy_strength.up))
   if buffpresent(pillar_of_frost_buff) and azeritetraitrank(icy_citadel_trait) <= 1 and { buffremaining(pillar_of_frost_buff) <= gcd() or buffremaining(unholy_strength_buff) <= gcd() and buffpresent(unholy_strength_buff) } spell(frostwyrms_fury)
   #frostwyrms_fury,if=(buff.icy_citadel.up&!talent.icecap.enabled&(buff.unholy_strength.up|buff.icy_citadel.remains<=gcd))|buff.icy_citadel.up&buff.icy_citadel.remains<=gcd&talent.icecap.enabled&buff.pillar_of_frost.up
   if buffpresent(icy_citadel_expires_buff) and not hastalent(icecap_talent) and { buffpresent(unholy_strength_buff) or buffremaining(icy_citadel_expires_buff) <= gcd() } or buffpresent(icy_citadel_expires_buff) and buffremaining(icy_citadel_expires_buff) <= gcd() and hastalent(icecap_talent) and buffpresent(pillar_of_frost_buff) spell(frostwyrms_fury)
   #frostwyrms_fury,if=target.1.time_to_die<gcd|(target.1.time_to_die<cooldown.pillar_of_frost.remains&buff.unholy_strength.up)
   if target.timetodie() < gcd() or target.timetodie() < spellcooldown(pillar_of_frost) and buffpresent(unholy_strength_buff) spell(frostwyrms_fury)
  }
 }
}

AddFunction frostcooldownscdpostconditions
{
 { buffpresent(pillar_of_frost_buff) and { buffremaining(pillar_of_frost_buff) < 5 and hastalent(cold_heart_talent) or not hastalent(cold_heart_talent) and buffremaining(pillar_of_frost_buff) < 3 } or buffpresent(seething_rage) } and spell(bag_of_tricks) or { spellcooldown(empower_rune_weapon) > 0 or hastalent(icecap_talent) } and spell(pillar_of_frost) or hastalent(cold_heart_talent) and { buffstacks(cold_heart_buff) >= 10 and target.debuffstacks(razorice_debuff) == 5 or target.timetodie() <= gcd() } and frostcold_heartcdpostconditions()
}

### actions.cold_heart

AddFunction frostcold_heartmainactions
{
 #chains_of_ice,if=buff.cold_heart.stack>5&target.1.time_to_die<gcd
 if buffstacks(cold_heart_buff) > 5 and target.timetodie() < gcd() spell(chains_of_ice)
 #chains_of_ice,if=(buff.seething_rage.remains<gcd)&buff.seething_rage.up
 if buffremaining(seething_rage) < gcd() and buffpresent(seething_rage) spell(chains_of_ice)
 #chains_of_ice,if=(buff.pillar_of_frost.remains<=gcd*(1+cooldown.frostwyrms_fury.ready)|buff.pillar_of_frost.remains<rune.time_to_3)&buff.pillar_of_frost.up&(azerite.icy_citadel.rank<=1|buff.breath_of_sindragosa.up)&!talent.icecap.enabled
 if { buffremaining(pillar_of_frost_buff) <= gcd() * { 1 + { spellcooldown(frostwyrms_fury) == 0 } } or buffremaining(pillar_of_frost_buff) < timetorunes(3) } and buffpresent(pillar_of_frost_buff) and { azeritetraitrank(icy_citadel_trait) <= 1 or buffpresent(breath_of_sindragosa_buff) } and not hastalent(icecap_talent) spell(chains_of_ice)
 #chains_of_ice,if=buff.pillar_of_frost.remains<8&buff.unholy_strength.remains<gcd*(1+cooldown.frostwyrms_fury.ready)&buff.unholy_strength.remains&buff.pillar_of_frost.up&(azerite.icy_citadel.rank<=1|buff.breath_of_sindragosa.up)&!talent.icecap.enabled
 if buffremaining(pillar_of_frost_buff) < 8 and buffremaining(unholy_strength_buff) < gcd() * { 1 + { spellcooldown(frostwyrms_fury) == 0 } } and buffpresent(unholy_strength_buff) and buffpresent(pillar_of_frost_buff) and { azeritetraitrank(icy_citadel_trait) <= 1 or buffpresent(breath_of_sindragosa_buff) } and not hastalent(icecap_talent) spell(chains_of_ice)
 #chains_of_ice,if=(buff.icy_citadel.remains<4|buff.icy_citadel.remains<rune.time_to_3)&buff.icy_citadel.up&azerite.icy_citadel.rank>=2&!buff.breath_of_sindragosa.up&!talent.icecap.enabled
 if { buffremaining(icy_citadel_expires_buff) < 4 or buffremaining(icy_citadel_expires_buff) < timetorunes(3) } and buffpresent(icy_citadel_expires_buff) and azeritetraitrank(icy_citadel_trait) >= 2 and not buffpresent(breath_of_sindragosa_buff) and not hastalent(icecap_talent) spell(chains_of_ice)
 #chains_of_ice,if=buff.icy_citadel.up&buff.unholy_strength.up&azerite.icy_citadel.rank>=2&!buff.breath_of_sindragosa.up&!talent.icecap.enabled
 if buffpresent(icy_citadel_expires_buff) and buffpresent(unholy_strength_buff) and azeritetraitrank(icy_citadel_trait) >= 2 and not buffpresent(breath_of_sindragosa_buff) and not hastalent(icecap_talent) spell(chains_of_ice)
 #chains_of_ice,if=buff.pillar_of_frost.remains<4&buff.pillar_of_frost.up&talent.icecap.enabled&buff.cold_heart.stack>=18&azerite.icy_citadel.rank<=1
 if buffremaining(pillar_of_frost_buff) < 4 and buffpresent(pillar_of_frost_buff) and hastalent(icecap_talent) and buffstacks(cold_heart_buff) >= 18 and azeritetraitrank(icy_citadel_trait) <= 1 spell(chains_of_ice)
 #chains_of_ice,if=buff.pillar_of_frost.up&talent.icecap.enabled&azerite.icy_citadel.rank>=2&(buff.cold_heart.stack>=19&buff.icy_citadel.remains<gcd&buff.icy_citadel.up|buff.unholy_strength.up&buff.cold_heart.stack>=18)
 if buffpresent(pillar_of_frost_buff) and hastalent(icecap_talent) and azeritetraitrank(icy_citadel_trait) >= 2 and { buffstacks(cold_heart_buff) >= 19 and buffremaining(icy_citadel_expires_buff) < gcd() and buffpresent(icy_citadel_expires_buff) or buffpresent(unholy_strength_buff) and buffstacks(cold_heart_buff) >= 18 } spell(chains_of_ice)
}

AddFunction frostcold_heartmainpostconditions
{
}

AddFunction frostcold_heartshortcdactions
{
}

AddFunction frostcold_heartshortcdpostconditions
{
 buffstacks(cold_heart_buff) > 5 and target.timetodie() < gcd() and spell(chains_of_ice) or buffremaining(seething_rage) < gcd() and buffpresent(seething_rage) and spell(chains_of_ice) or { buffremaining(pillar_of_frost_buff) <= gcd() * { 1 + { spellcooldown(frostwyrms_fury) == 0 } } or buffremaining(pillar_of_frost_buff) < timetorunes(3) } and buffpresent(pillar_of_frost_buff) and { azeritetraitrank(icy_citadel_trait) <= 1 or buffpresent(breath_of_sindragosa_buff) } and not hastalent(icecap_talent) and spell(chains_of_ice) or buffremaining(pillar_of_frost_buff) < 8 and buffremaining(unholy_strength_buff) < gcd() * { 1 + { spellcooldown(frostwyrms_fury) == 0 } } and buffpresent(unholy_strength_buff) and buffpresent(pillar_of_frost_buff) and { azeritetraitrank(icy_citadel_trait) <= 1 or buffpresent(breath_of_sindragosa_buff) } and not hastalent(icecap_talent) and spell(chains_of_ice) or { buffremaining(icy_citadel_expires_buff) < 4 or buffremaining(icy_citadel_expires_buff) < timetorunes(3) } and buffpresent(icy_citadel_expires_buff) and azeritetraitrank(icy_citadel_trait) >= 2 and not buffpresent(breath_of_sindragosa_buff) and not hastalent(icecap_talent) and spell(chains_of_ice) or buffpresent(icy_citadel_expires_buff) and buffpresent(unholy_strength_buff) and azeritetraitrank(icy_citadel_trait) >= 2 and not buffpresent(breath_of_sindragosa_buff) and not hastalent(icecap_talent) and spell(chains_of_ice) or buffremaining(pillar_of_frost_buff) < 4 and buffpresent(pillar_of_frost_buff) and hastalent(icecap_talent) and buffstacks(cold_heart_buff) >= 18 and azeritetraitrank(icy_citadel_trait) <= 1 and spell(chains_of_ice) or buffpresent(pillar_of_frost_buff) and hastalent(icecap_talent) and azeritetraitrank(icy_citadel_trait) >= 2 and { buffstacks(cold_heart_buff) >= 19 and buffremaining(icy_citadel_expires_buff) < gcd() and buffpresent(icy_citadel_expires_buff) or buffpresent(unholy_strength_buff) and buffstacks(cold_heart_buff) >= 18 } and spell(chains_of_ice)
}

AddFunction frostcold_heartcdactions
{
}

AddFunction frostcold_heartcdpostconditions
{
 buffstacks(cold_heart_buff) > 5 and target.timetodie() < gcd() and spell(chains_of_ice) or buffremaining(seething_rage) < gcd() and buffpresent(seething_rage) and spell(chains_of_ice) or { buffremaining(pillar_of_frost_buff) <= gcd() * { 1 + { spellcooldown(frostwyrms_fury) == 0 } } or buffremaining(pillar_of_frost_buff) < timetorunes(3) } and buffpresent(pillar_of_frost_buff) and { azeritetraitrank(icy_citadel_trait) <= 1 or buffpresent(breath_of_sindragosa_buff) } and not hastalent(icecap_talent) and spell(chains_of_ice) or buffremaining(pillar_of_frost_buff) < 8 and buffremaining(unholy_strength_buff) < gcd() * { 1 + { spellcooldown(frostwyrms_fury) == 0 } } and buffpresent(unholy_strength_buff) and buffpresent(pillar_of_frost_buff) and { azeritetraitrank(icy_citadel_trait) <= 1 or buffpresent(breath_of_sindragosa_buff) } and not hastalent(icecap_talent) and spell(chains_of_ice) or { buffremaining(icy_citadel_expires_buff) < 4 or buffremaining(icy_citadel_expires_buff) < timetorunes(3) } and buffpresent(icy_citadel_expires_buff) and azeritetraitrank(icy_citadel_trait) >= 2 and not buffpresent(breath_of_sindragosa_buff) and not hastalent(icecap_talent) and spell(chains_of_ice) or buffpresent(icy_citadel_expires_buff) and buffpresent(unholy_strength_buff) and azeritetraitrank(icy_citadel_trait) >= 2 and not buffpresent(breath_of_sindragosa_buff) and not hastalent(icecap_talent) and spell(chains_of_ice) or buffremaining(pillar_of_frost_buff) < 4 and buffpresent(pillar_of_frost_buff) and hastalent(icecap_talent) and buffstacks(cold_heart_buff) >= 18 and azeritetraitrank(icy_citadel_trait) <= 1 and spell(chains_of_ice) or buffpresent(pillar_of_frost_buff) and hastalent(icecap_talent) and azeritetraitrank(icy_citadel_trait) >= 2 and { buffstacks(cold_heart_buff) >= 19 and buffremaining(icy_citadel_expires_buff) < gcd() and buffpresent(icy_citadel_expires_buff) or buffpresent(unholy_strength_buff) and buffstacks(cold_heart_buff) >= 18 } and spell(chains_of_ice)
}

### actions.bos_ticking

AddFunction frostbos_tickingmainactions
{
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&runic_power<=32&!talent.frostscythe.enabled
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpower() <= 32 and not hastalent(frostscythe_talent) spell(obliterate)
 #obliterate,if=runic_power<=32
 if runicpower() <= 32 spell(obliterate)
 #remorseless_winter,if=talent.gathering_storm.enabled
 if hastalent(gathering_storm_talent) spell(remorseless_winter)
 #howling_blast,if=buff.rime.up
 if buffpresent(rime_buff) spell(howling_blast)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&rune.time_to_5<gcd|runic_power<=45&!talent.frostscythe.enabled
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and timetorunes(5) < gcd() or runicpower() <= 45 and not hastalent(frostscythe_talent) spell(obliterate)
 #obliterate,if=rune.time_to_5<gcd|runic_power<=45
 if timetorunes(5) < gcd() or runicpower() <= 45 spell(obliterate)
 #frostscythe,if=buff.killing_machine.up&spell_targets.frostscythe>=2
 if buffpresent(killing_machine_buff) and enemies() >= 2 spell(frostscythe)
 #horn_of_winter,if=runic_power.deficit>=32&rune.time_to_3>gcd
 if runicpowerdeficit() >= 32 and timetorunes(3) > gcd() spell(horn_of_winter)
 #remorseless_winter
 spell(remorseless_winter)
 #frostscythe,if=spell_targets.frostscythe>=2
 if enemies() >= 2 spell(frostscythe)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&runic_power.deficit>25|rune>3&!talent.frostscythe.enabled
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() > 25 or runecount() > 3 and not hastalent(frostscythe_talent) spell(obliterate)
 #obliterate,if=runic_power.deficit>25|rune>3
 if runicpowerdeficit() > 25 or runecount() > 3 spell(obliterate)
}

AddFunction frostbos_tickingmainpostconditions
{
}

AddFunction frostbos_tickingshortcdactions
{
}

AddFunction frostbos_tickingshortcdpostconditions
{
 { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpower() <= 32 and not hastalent(frostscythe_talent) and spell(obliterate) or runicpower() <= 32 and spell(obliterate) or hastalent(gathering_storm_talent) and spell(remorseless_winter) or buffpresent(rime_buff) and spell(howling_blast) or { { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and timetorunes(5) < gcd() or runicpower() <= 45 and not hastalent(frostscythe_talent) } and spell(obliterate) or { timetorunes(5) < gcd() or runicpower() <= 45 } and spell(obliterate) or buffpresent(killing_machine_buff) and enemies() >= 2 and spell(frostscythe) or runicpowerdeficit() >= 32 and timetorunes(3) > gcd() and spell(horn_of_winter) or spell(remorseless_winter) or enemies() >= 2 and spell(frostscythe) or { { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() > 25 or runecount() > 3 and not hastalent(frostscythe_talent) } and spell(obliterate) or { runicpowerdeficit() > 25 or runecount() > 3 } and spell(obliterate)
}

AddFunction frostbos_tickingcdactions
{
 unless { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpower() <= 32 and not hastalent(frostscythe_talent) and spell(obliterate) or runicpower() <= 32 and spell(obliterate) or hastalent(gathering_storm_talent) and spell(remorseless_winter) or buffpresent(rime_buff) and spell(howling_blast) or { { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and timetorunes(5) < gcd() or runicpower() <= 45 and not hastalent(frostscythe_talent) } and spell(obliterate) or { timetorunes(5) < gcd() or runicpower() <= 45 } and spell(obliterate) or buffpresent(killing_machine_buff) and enemies() >= 2 and spell(frostscythe) or runicpowerdeficit() >= 32 and timetorunes(3) > gcd() and spell(horn_of_winter) or spell(remorseless_winter) or enemies() >= 2 and spell(frostscythe) or { { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() > 25 or runecount() > 3 and not hastalent(frostscythe_talent) } and spell(obliterate) or { runicpowerdeficit() > 25 or runecount() > 3 } and spell(obliterate)
 {
  #arcane_torrent,if=runic_power.deficit>50
  if runicpowerdeficit() > 50 spell(arcane_torrent_runicpower)
 }
}

AddFunction frostbos_tickingcdpostconditions
{
 { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpower() <= 32 and not hastalent(frostscythe_talent) and spell(obliterate) or runicpower() <= 32 and spell(obliterate) or hastalent(gathering_storm_talent) and spell(remorseless_winter) or buffpresent(rime_buff) and spell(howling_blast) or { { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and timetorunes(5) < gcd() or runicpower() <= 45 and not hastalent(frostscythe_talent) } and spell(obliterate) or { timetorunes(5) < gcd() or runicpower() <= 45 } and spell(obliterate) or buffpresent(killing_machine_buff) and enemies() >= 2 and spell(frostscythe) or runicpowerdeficit() >= 32 and timetorunes(3) > gcd() and spell(horn_of_winter) or spell(remorseless_winter) or enemies() >= 2 and spell(frostscythe) or { { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() > 25 or runecount() > 3 and not hastalent(frostscythe_talent) } and spell(obliterate) or { runicpowerdeficit() > 25 or runecount() > 3 } and spell(obliterate)
}

### actions.bos_pooling

AddFunction frostbos_poolingmainactions
{
 #howling_blast,if=buff.rime.up
 if buffpresent(rime_buff) spell(howling_blast)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&&runic_power.deficit>=25&!talent.frostscythe.enabled
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() >= 25 and not hastalent(frostscythe_talent) spell(obliterate)
 #obliterate,if=runic_power.deficit>=25
 if runicpowerdeficit() >= 25 spell(obliterate)
 #glacial_advance,if=runic_power.deficit<20&spell_targets.glacial_advance>=2&cooldown.pillar_of_frost.remains>5
 if runicpowerdeficit() < 20 and enemies() >= 2 and spellcooldown(pillar_of_frost) > 5 spell(glacial_advance)
 #frost_strike,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&runic_power.deficit<20&!talent.frostscythe.enabled&cooldown.pillar_of_frost.remains>5
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() < 20 and not hastalent(frostscythe_talent) and spellcooldown(pillar_of_frost) > 5 spell(frost_strike)
 #frost_strike,if=runic_power.deficit<20&cooldown.pillar_of_frost.remains>5
 if runicpowerdeficit() < 20 and spellcooldown(pillar_of_frost) > 5 spell(frost_strike)
 #frostscythe,if=buff.killing_machine.up&runic_power.deficit>(15+talent.runic_attenuation.enabled*3)&spell_targets.frostscythe>=2
 if buffpresent(killing_machine_buff) and runicpowerdeficit() > 15 + talentpoints(runic_attenuation_talent) * 3 and enemies() >= 2 spell(frostscythe)
 #frostscythe,if=runic_power.deficit>=(35+talent.runic_attenuation.enabled*3)&spell_targets.frostscythe>=2
 if runicpowerdeficit() >= 35 + talentpoints(runic_attenuation_talent) * 3 and enemies() >= 2 spell(frostscythe)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&runic_power.deficit>=(35+talent.runic_attenuation.enabled*3)&!talent.frostscythe.enabled
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() >= 35 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) spell(obliterate)
 #obliterate,if=runic_power.deficit>=(35+talent.runic_attenuation.enabled*3)
 if runicpowerdeficit() >= 35 + talentpoints(runic_attenuation_talent) * 3 spell(obliterate)
 #glacial_advance,if=cooldown.pillar_of_frost.remains>rune.time_to_4&runic_power.deficit<40&spell_targets.glacial_advance>=2
 if spellcooldown(pillar_of_frost) > timetorunes(4) and runicpowerdeficit() < 40 and enemies() >= 2 spell(glacial_advance)
 #frost_strike,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&cooldown.pillar_of_frost.remains>rune.time_to_4&runic_power.deficit<40&!talent.frostscythe.enabled
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and spellcooldown(pillar_of_frost) > timetorunes(4) and runicpowerdeficit() < 40 and not hastalent(frostscythe_talent) spell(frost_strike)
 #frost_strike,if=cooldown.pillar_of_frost.remains>rune.time_to_4&runic_power.deficit<40
 if spellcooldown(pillar_of_frost) > timetorunes(4) and runicpowerdeficit() < 40 spell(frost_strike)
}

AddFunction frostbos_poolingmainpostconditions
{
}

AddFunction frostbos_poolingshortcdactions
{
}

AddFunction frostbos_poolingshortcdpostconditions
{
 buffpresent(rime_buff) and spell(howling_blast) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() >= 25 and not hastalent(frostscythe_talent) and spell(obliterate) or runicpowerdeficit() >= 25 and spell(obliterate) or runicpowerdeficit() < 20 and enemies() >= 2 and spellcooldown(pillar_of_frost) > 5 and spell(glacial_advance) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() < 20 and not hastalent(frostscythe_talent) and spellcooldown(pillar_of_frost) > 5 and spell(frost_strike) or runicpowerdeficit() < 20 and spellcooldown(pillar_of_frost) > 5 and spell(frost_strike) or buffpresent(killing_machine_buff) and runicpowerdeficit() > 15 + talentpoints(runic_attenuation_talent) * 3 and enemies() >= 2 and spell(frostscythe) or runicpowerdeficit() >= 35 + talentpoints(runic_attenuation_talent) * 3 and enemies() >= 2 and spell(frostscythe) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() >= 35 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) and spell(obliterate) or runicpowerdeficit() >= 35 + talentpoints(runic_attenuation_talent) * 3 and spell(obliterate) or spellcooldown(pillar_of_frost) > timetorunes(4) and runicpowerdeficit() < 40 and enemies() >= 2 and spell(glacial_advance) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and spellcooldown(pillar_of_frost) > timetorunes(4) and runicpowerdeficit() < 40 and not hastalent(frostscythe_talent) and spell(frost_strike) or spellcooldown(pillar_of_frost) > timetorunes(4) and runicpowerdeficit() < 40 and spell(frost_strike)
}

AddFunction frostbos_poolingcdactions
{
}

AddFunction frostbos_poolingcdpostconditions
{
 buffpresent(rime_buff) and spell(howling_blast) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() >= 25 and not hastalent(frostscythe_talent) and spell(obliterate) or runicpowerdeficit() >= 25 and spell(obliterate) or runicpowerdeficit() < 20 and enemies() >= 2 and spellcooldown(pillar_of_frost) > 5 and spell(glacial_advance) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() < 20 and not hastalent(frostscythe_talent) and spellcooldown(pillar_of_frost) > 5 and spell(frost_strike) or runicpowerdeficit() < 20 and spellcooldown(pillar_of_frost) > 5 and spell(frost_strike) or buffpresent(killing_machine_buff) and runicpowerdeficit() > 15 + talentpoints(runic_attenuation_talent) * 3 and enemies() >= 2 and spell(frostscythe) or runicpowerdeficit() >= 35 + talentpoints(runic_attenuation_talent) * 3 and enemies() >= 2 and spell(frostscythe) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() >= 35 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) and spell(obliterate) or runicpowerdeficit() >= 35 + talentpoints(runic_attenuation_talent) * 3 and spell(obliterate) or spellcooldown(pillar_of_frost) > timetorunes(4) and runicpowerdeficit() < 40 and enemies() >= 2 and spell(glacial_advance) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and spellcooldown(pillar_of_frost) > timetorunes(4) and runicpowerdeficit() < 40 and not hastalent(frostscythe_talent) and spell(frost_strike) or spellcooldown(pillar_of_frost) > timetorunes(4) and runicpowerdeficit() < 40 and spell(frost_strike)
}

### actions.aoe

AddFunction frostaoemainactions
{
 #remorseless_winter,if=talent.gathering_storm.enabled|(azerite.frozen_tempest.rank&spell_targets.remorseless_winter>=3&!buff.rime.up)
 if hastalent(gathering_storm_talent) or azeritetraitrank(frozen_tempest_trait) and enemies() >= 3 and not buffpresent(rime_buff) spell(remorseless_winter)
 #glacial_advance,if=talent.frostscythe.enabled
 if hastalent(frostscythe_talent) spell(glacial_advance)
 #frost_strike,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&cooldown.remorseless_winter.remains<=2*gcd&talent.gathering_storm.enabled&!talent.frostscythe.enabled
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and spellcooldown(remorseless_winter) <= 2 * gcd() and hastalent(gathering_storm_talent) and not hastalent(frostscythe_talent) spell(frost_strike)
 #frost_strike,if=cooldown.remorseless_winter.remains<=2*gcd&talent.gathering_storm.enabled
 if spellcooldown(remorseless_winter) <= 2 * gcd() and hastalent(gathering_storm_talent) spell(frost_strike)
 #howling_blast,if=buff.rime.up
 if buffpresent(rime_buff) spell(howling_blast)
 #frostscythe,if=buff.killing_machine.up
 if buffpresent(killing_machine_buff) spell(frostscythe)
 #glacial_advance,if=runic_power.deficit<(15+talent.runic_attenuation.enabled*3)
 if runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 spell(glacial_advance)
 #frost_strike,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&runic_power.deficit<(15+talent.runic_attenuation.enabled*3)&!talent.frostscythe.enabled
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) spell(frost_strike)
 #frost_strike,if=runic_power.deficit<(15+talent.runic_attenuation.enabled*3)&!talent.frostscythe.enabled
 if runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) spell(frost_strike)
 #remorseless_winter
 spell(remorseless_winter)
 #frostscythe
 spell(frostscythe)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&runic_power.deficit>(25+talent.runic_attenuation.enabled*3)&!talent.frostscythe.enabled
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() > 25 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) spell(obliterate)
 #obliterate,if=runic_power.deficit>(25+talent.runic_attenuation.enabled*3)
 if runicpowerdeficit() > 25 + talentpoints(runic_attenuation_talent) * 3 spell(obliterate)
 #glacial_advance
 spell(glacial_advance)
 #frost_strike,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&!talent.frostscythe.enabled
 if { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and not hastalent(frostscythe_talent) spell(frost_strike)
 #frost_strike
 spell(frost_strike)
 #horn_of_winter
 spell(horn_of_winter)
}

AddFunction frostaoemainpostconditions
{
}

AddFunction frostaoeshortcdactions
{
}

AddFunction frostaoeshortcdpostconditions
{
 { hastalent(gathering_storm_talent) or azeritetraitrank(frozen_tempest_trait) and enemies() >= 3 and not buffpresent(rime_buff) } and spell(remorseless_winter) or hastalent(frostscythe_talent) and spell(glacial_advance) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and spellcooldown(remorseless_winter) <= 2 * gcd() and hastalent(gathering_storm_talent) and not hastalent(frostscythe_talent) and spell(frost_strike) or spellcooldown(remorseless_winter) <= 2 * gcd() and hastalent(gathering_storm_talent) and spell(frost_strike) or buffpresent(rime_buff) and spell(howling_blast) or buffpresent(killing_machine_buff) and spell(frostscythe) or runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and spell(glacial_advance) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) and spell(frost_strike) or runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) and spell(frost_strike) or spell(remorseless_winter) or spell(frostscythe) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() > 25 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) and spell(obliterate) or runicpowerdeficit() > 25 + talentpoints(runic_attenuation_talent) * 3 and spell(obliterate) or spell(glacial_advance) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and not hastalent(frostscythe_talent) and spell(frost_strike) or spell(frost_strike) or spell(horn_of_winter)
}

AddFunction frostaoecdactions
{
 unless { hastalent(gathering_storm_talent) or azeritetraitrank(frozen_tempest_trait) and enemies() >= 3 and not buffpresent(rime_buff) } and spell(remorseless_winter) or hastalent(frostscythe_talent) and spell(glacial_advance) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and spellcooldown(remorseless_winter) <= 2 * gcd() and hastalent(gathering_storm_talent) and not hastalent(frostscythe_talent) and spell(frost_strike) or spellcooldown(remorseless_winter) <= 2 * gcd() and hastalent(gathering_storm_talent) and spell(frost_strike) or buffpresent(rime_buff) and spell(howling_blast) or buffpresent(killing_machine_buff) and spell(frostscythe) or runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and spell(glacial_advance) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) and spell(frost_strike) or runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) and spell(frost_strike) or spell(remorseless_winter) or spell(frostscythe) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() > 25 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) and spell(obliterate) or runicpowerdeficit() > 25 + talentpoints(runic_attenuation_talent) * 3 and spell(obliterate) or spell(glacial_advance) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and not hastalent(frostscythe_talent) and spell(frost_strike) or spell(frost_strike) or spell(horn_of_winter)
 {
  #arcane_torrent
  spell(arcane_torrent_runicpower)
 }
}

AddFunction frostaoecdpostconditions
{
 { hastalent(gathering_storm_talent) or azeritetraitrank(frozen_tempest_trait) and enemies() >= 3 and not buffpresent(rime_buff) } and spell(remorseless_winter) or hastalent(frostscythe_talent) and spell(glacial_advance) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and spellcooldown(remorseless_winter) <= 2 * gcd() and hastalent(gathering_storm_talent) and not hastalent(frostscythe_talent) and spell(frost_strike) or spellcooldown(remorseless_winter) <= 2 * gcd() and hastalent(gathering_storm_talent) and spell(frost_strike) or buffpresent(rime_buff) and spell(howling_blast) or buffpresent(killing_machine_buff) and spell(frostscythe) or runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and spell(glacial_advance) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) and spell(frost_strike) or runicpowerdeficit() < 15 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) and spell(frost_strike) or spell(remorseless_winter) or spell(frostscythe) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and runicpowerdeficit() > 25 + talentpoints(runic_attenuation_talent) * 3 and not hastalent(frostscythe_talent) and spell(obliterate) or runicpowerdeficit() > 25 + talentpoints(runic_attenuation_talent) * 3 and spell(obliterate) or spell(glacial_advance) or { target.debuffstacks(razorice_debuff) < 5 or target.debuffremaining(razorice_debuff) < 10 } and not hastalent(frostscythe_talent) and spell(frost_strike) or spell(frost_strike) or spell(horn_of_winter)
}

### actions.default

AddFunction frost_defaultmainactions
{
 #howling_blast,if=!dot.frost_fever.ticking&(!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>15)
 if not target.debuffpresent(frost_fever_debuff) and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } spell(howling_blast)
 #glacial_advance,if=buff.icy_talons.remains<=gcd&buff.icy_talons.up&spell_targets.glacial_advance>=2&(!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>15)
 if buffremaining(icy_talons_buff) <= gcd() and buffpresent(icy_talons_buff) and enemies() >= 2 and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } spell(glacial_advance)
 #frost_strike,if=buff.icy_talons.remains<=gcd&buff.icy_talons.up&(!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>15)
 if buffremaining(icy_talons_buff) <= gcd() and buffpresent(icy_talons_buff) and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } spell(frost_strike)
 #call_action_list,name=essences
 frostessencesmainactions()

 unless frostessencesmainpostconditions()
 {
  #call_action_list,name=cooldowns
  frostcooldownsmainactions()

  unless frostcooldownsmainpostconditions()
  {
   #run_action_list,name=bos_pooling,if=talent.breath_of_sindragosa.enabled&((cooldown.breath_of_sindragosa.remains=0&cooldown.pillar_of_frost.remains<10)|(cooldown.breath_of_sindragosa.remains<20&target.1.time_to_die<35))
   if hastalent(breath_of_sindragosa_talent) and { not spellcooldown(breath_of_sindragosa) > 0 and spellcooldown(pillar_of_frost) < 10 or spellcooldown(breath_of_sindragosa) < 20 and target.timetodie() < 35 } frostbos_poolingmainactions()

   unless hastalent(breath_of_sindragosa_talent) and { not spellcooldown(breath_of_sindragosa) > 0 and spellcooldown(pillar_of_frost) < 10 or spellcooldown(breath_of_sindragosa) < 20 and target.timetodie() < 35 } and frostbos_poolingmainpostconditions()
   {
    #run_action_list,name=bos_ticking,if=buff.breath_of_sindragosa.up
    if buffpresent(breath_of_sindragosa_buff) frostbos_tickingmainactions()

    unless buffpresent(breath_of_sindragosa_buff) and frostbos_tickingmainpostconditions()
    {
     #run_action_list,name=obliteration,if=buff.pillar_of_frost.up&talent.obliteration.enabled
     if buffpresent(pillar_of_frost_buff) and hastalent(obliteration_talent) frostobliterationmainactions()

     unless buffpresent(pillar_of_frost_buff) and hastalent(obliteration_talent) and frostobliterationmainpostconditions()
     {
      #run_action_list,name=aoe,if=active_enemies>=2
      if enemies() >= 2 frostaoemainactions()

      unless enemies() >= 2 and frostaoemainpostconditions()
      {
       #call_action_list,name=standard
       froststandardmainactions()
      }
     }
    }
   }
  }
 }
}

AddFunction frost_defaultmainpostconditions
{
 frostessencesmainpostconditions() or frostcooldownsmainpostconditions() or hastalent(breath_of_sindragosa_talent) and { not spellcooldown(breath_of_sindragosa) > 0 and spellcooldown(pillar_of_frost) < 10 or spellcooldown(breath_of_sindragosa) < 20 and target.timetodie() < 35 } and frostbos_poolingmainpostconditions() or buffpresent(breath_of_sindragosa_buff) and frostbos_tickingmainpostconditions() or buffpresent(pillar_of_frost_buff) and hastalent(obliteration_talent) and frostobliterationmainpostconditions() or enemies() >= 2 and frostaoemainpostconditions() or froststandardmainpostconditions()
}

AddFunction frost_defaultshortcdactions
{
 #auto_attack
 frostgetinmeleerange()

 unless not target.debuffpresent(frost_fever_debuff) and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } and spell(howling_blast) or buffremaining(icy_talons_buff) <= gcd() and buffpresent(icy_talons_buff) and enemies() >= 2 and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } and spell(glacial_advance) or buffremaining(icy_talons_buff) <= gcd() and buffpresent(icy_talons_buff) and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } and spell(frost_strike)
 {
  #call_action_list,name=essences
  frostessencesshortcdactions()

  unless frostessencesshortcdpostconditions()
  {
   #call_action_list,name=cooldowns
   frostcooldownsshortcdactions()

   unless frostcooldownsshortcdpostconditions()
   {
    #run_action_list,name=bos_pooling,if=talent.breath_of_sindragosa.enabled&((cooldown.breath_of_sindragosa.remains=0&cooldown.pillar_of_frost.remains<10)|(cooldown.breath_of_sindragosa.remains<20&target.1.time_to_die<35))
    if hastalent(breath_of_sindragosa_talent) and { not spellcooldown(breath_of_sindragosa) > 0 and spellcooldown(pillar_of_frost) < 10 or spellcooldown(breath_of_sindragosa) < 20 and target.timetodie() < 35 } frostbos_poolingshortcdactions()

    unless hastalent(breath_of_sindragosa_talent) and { not spellcooldown(breath_of_sindragosa) > 0 and spellcooldown(pillar_of_frost) < 10 or spellcooldown(breath_of_sindragosa) < 20 and target.timetodie() < 35 } and frostbos_poolingshortcdpostconditions()
    {
     #run_action_list,name=bos_ticking,if=buff.breath_of_sindragosa.up
     if buffpresent(breath_of_sindragosa_buff) frostbos_tickingshortcdactions()

     unless buffpresent(breath_of_sindragosa_buff) and frostbos_tickingshortcdpostconditions()
     {
      #run_action_list,name=obliteration,if=buff.pillar_of_frost.up&talent.obliteration.enabled
      if buffpresent(pillar_of_frost_buff) and hastalent(obliteration_talent) frostobliterationshortcdactions()

      unless buffpresent(pillar_of_frost_buff) and hastalent(obliteration_talent) and frostobliterationshortcdpostconditions()
      {
       #run_action_list,name=aoe,if=active_enemies>=2
       if enemies() >= 2 frostaoeshortcdactions()

       unless enemies() >= 2 and frostaoeshortcdpostconditions()
       {
        #call_action_list,name=standard
        froststandardshortcdactions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction frost_defaultshortcdpostconditions
{
 not target.debuffpresent(frost_fever_debuff) and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } and spell(howling_blast) or buffremaining(icy_talons_buff) <= gcd() and buffpresent(icy_talons_buff) and enemies() >= 2 and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } and spell(glacial_advance) or buffremaining(icy_talons_buff) <= gcd() and buffpresent(icy_talons_buff) and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } and spell(frost_strike) or frostessencesshortcdpostconditions() or frostcooldownsshortcdpostconditions() or hastalent(breath_of_sindragosa_talent) and { not spellcooldown(breath_of_sindragosa) > 0 and spellcooldown(pillar_of_frost) < 10 or spellcooldown(breath_of_sindragosa) < 20 and target.timetodie() < 35 } and frostbos_poolingshortcdpostconditions() or buffpresent(breath_of_sindragosa_buff) and frostbos_tickingshortcdpostconditions() or buffpresent(pillar_of_frost_buff) and hastalent(obliteration_talent) and frostobliterationshortcdpostconditions() or enemies() >= 2 and frostaoeshortcdpostconditions() or froststandardshortcdpostconditions()
}

AddFunction frost_defaultcdactions
{
 frostinterruptactions()

 unless not target.debuffpresent(frost_fever_debuff) and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } and spell(howling_blast) or buffremaining(icy_talons_buff) <= gcd() and buffpresent(icy_talons_buff) and enemies() >= 2 and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } and spell(glacial_advance) or buffremaining(icy_talons_buff) <= gcd() and buffpresent(icy_talons_buff) and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } and spell(frost_strike)
 {
  #call_action_list,name=essences
  frostessencescdactions()

  unless frostessencescdpostconditions()
  {
   #call_action_list,name=cooldowns
   frostcooldownscdactions()

   unless frostcooldownscdpostconditions()
   {
    #run_action_list,name=bos_pooling,if=talent.breath_of_sindragosa.enabled&((cooldown.breath_of_sindragosa.remains=0&cooldown.pillar_of_frost.remains<10)|(cooldown.breath_of_sindragosa.remains<20&target.1.time_to_die<35))
    if hastalent(breath_of_sindragosa_talent) and { not spellcooldown(breath_of_sindragosa) > 0 and spellcooldown(pillar_of_frost) < 10 or spellcooldown(breath_of_sindragosa) < 20 and target.timetodie() < 35 } frostbos_poolingcdactions()

    unless hastalent(breath_of_sindragosa_talent) and { not spellcooldown(breath_of_sindragosa) > 0 and spellcooldown(pillar_of_frost) < 10 or spellcooldown(breath_of_sindragosa) < 20 and target.timetodie() < 35 } and frostbos_poolingcdpostconditions()
    {
     #run_action_list,name=bos_ticking,if=buff.breath_of_sindragosa.up
     if buffpresent(breath_of_sindragosa_buff) frostbos_tickingcdactions()

     unless buffpresent(breath_of_sindragosa_buff) and frostbos_tickingcdpostconditions()
     {
      #run_action_list,name=obliteration,if=buff.pillar_of_frost.up&talent.obliteration.enabled
      if buffpresent(pillar_of_frost_buff) and hastalent(obliteration_talent) frostobliterationcdactions()

      unless buffpresent(pillar_of_frost_buff) and hastalent(obliteration_talent) and frostobliterationcdpostconditions()
      {
       #run_action_list,name=aoe,if=active_enemies>=2
       if enemies() >= 2 frostaoecdactions()

       unless enemies() >= 2 and frostaoecdpostconditions()
       {
        #call_action_list,name=standard
        froststandardcdactions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction frost_defaultcdpostconditions
{
 not target.debuffpresent(frost_fever_debuff) and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } and spell(howling_blast) or buffremaining(icy_talons_buff) <= gcd() and buffpresent(icy_talons_buff) and enemies() >= 2 and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } and spell(glacial_advance) or buffremaining(icy_talons_buff) <= gcd() and buffpresent(icy_talons_buff) and { not hastalent(breath_of_sindragosa_talent) or spellcooldown(breath_of_sindragosa) > 15 } and spell(frost_strike) or frostessencescdpostconditions() or frostcooldownscdpostconditions() or hastalent(breath_of_sindragosa_talent) and { not spellcooldown(breath_of_sindragosa) > 0 and spellcooldown(pillar_of_frost) < 10 or spellcooldown(breath_of_sindragosa) < 20 and target.timetodie() < 35 } and frostbos_poolingcdpostconditions() or buffpresent(breath_of_sindragosa_buff) and frostbos_tickingcdpostconditions() or buffpresent(pillar_of_frost_buff) and hastalent(obliteration_talent) and frostobliterationcdpostconditions() or enemies() >= 2 and frostaoecdpostconditions() or froststandardcdpostconditions()
}

### Frost icons.

AddCheckBox(opt_deathknight_frost_aoe l(aoe) default specialization=frost)

AddIcon checkbox=!opt_deathknight_frost_aoe enemies=1 help=shortcd specialization=frost
{
 if not incombat() frostprecombatshortcdactions()
 frost_defaultshortcdactions()
}

AddIcon checkbox=opt_deathknight_frost_aoe help=shortcd specialization=frost
{
 if not incombat() frostprecombatshortcdactions()
 frost_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=frost
{
 if not incombat() frostprecombatmainactions()
 frost_defaultmainactions()
}

AddIcon checkbox=opt_deathknight_frost_aoe help=aoe specialization=frost
{
 if not incombat() frostprecombatmainactions()
 frost_defaultmainactions()
}

AddIcon checkbox=!opt_deathknight_frost_aoe enemies=1 help=cd specialization=frost
{
 if not incombat() frostprecombatcdactions()
 frost_defaultcdactions()
}

AddIcon checkbox=opt_deathknight_frost_aoe help=cd specialization=frost
{
 if not incombat() frostprecombatcdactions()
 frost_defaultcdactions()
}

### Required symbols
# ancestral_call
# arcane_pulse
# arcane_torrent_runicpower
# ashvanes_razor_coral_item
# bag_of_tricks
# berserking
# blinding_sleet
# blood_fury_ap
# blood_of_the_enemy
# breath_of_sindragosa
# breath_of_sindragosa_buff
# breath_of_sindragosa_talent
# chains_of_ice
# chill_streak
# cold_heart_buff
# cold_heart_talent
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# death_strike
# empower_rune_weapon
# empower_rune_weapon_buff
# fireblood
# first_mates_spyglass_item
# focused_azerite_beam
# frost_fever_debuff
# frost_strike
# frostscythe
# frostscythe_talent
# frostwyrms_fury
# frozen_pulse_buff
# frozen_pulse_talent
# frozen_tempest_trait
# gathering_storm_talent
# glacial_advance
# guardian_of_azeroth
# horn_of_winter
# howling_blast
# icecap_talent
# icy_citadel_expires_buff
# icy_citadel_trait
# icy_talons_buff
# jes_howler_item
# killing_machine_buff
# lights_judgment
# lurkers_insidious_gift_item
# memory_of_lucid_dreams_essence
# mind_freeze
# notorious_gladiators_badge_item
# notorious_gladiators_medallion_item
# obliterate
# obliteration_talent
# pillar_of_frost
# pillar_of_frost_buff
# purifying_blast
# razor_coral
# razorice_debuff
# reaping_flames
# reckless_force_buff
# reckless_force_counter_buff
# remorseless_winter
# rime_buff
# ripple_in_space_essence
# runic_attenuation_talent
# seething_rage
# sinister_gladiators_badge_item
# sinister_gladiators_medallion_item
# the_unbound_force
# unbridled_fury_item
# unholy_strength_buff
# vial_of_animated_blood_item
# war_stomp
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("DEATHKNIGHT", "frost", name, desc, code, "script")
    end
    do
        local name = "sc_t24_death_knight_unholy"
        local desc = "[8.3] Simulationcraft: T24_Death_Knight_Unholy"
        local code = [[
# Based on SimulationCraft profile "T24_Death_Knight_Unholy".
#	class=deathknight
#	spec=unholy
#	talents=2203032

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)


AddFunction pooling_for_gargoyle
{
 spellcooldown(summon_gargoyle) < 5 and hastalent(summon_gargoyle_talent)
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=unholy)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=unholy)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=unholy)

AddFunction unholyinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(mind_freeze) and target.isinterruptible() spell(mind_freeze)
  if target.inrange(asphyxiate) and not target.classification(worldboss) spell(asphyxiate)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
 }
}

AddFunction unholyuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction unholygetinmeleerange
{
 if checkboxon(opt_melee_range) and not target.inrange(death_strike) texture(misc_arrowlup help=l(not_in_melee_range))
}

### actions.precombat

AddFunction unholyprecombatmainactions
{
}

AddFunction unholyprecombatmainpostconditions
{
}

AddFunction unholyprecombatshortcdactions
{
 #raise_dead
 spell(raise_dead)
}

AddFunction unholyprecombatshortcdpostconditions
{
}

AddFunction unholyprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

 unless spell(raise_dead)
 {
  #use_item,name=azsharas_font_of_power
  unholyuseitemactions()
  #army_of_the_dead,delay=2
  spell(army_of_the_dead)
 }
}

AddFunction unholyprecombatcdpostconditions
{
 spell(raise_dead)
}

### actions.generic

AddFunction unholygenericmainactions
{
 #death_coil,if=buff.sudden_doom.react&!variable.pooling_for_gargoyle|pet.gargoyle.active
 if buffpresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.present() spell(death_coil)
 #death_coil,if=runic_power.deficit<14&(cooldown.apocalypse.remains>5|debuff.festering_wound.stack>4)&!variable.pooling_for_gargoyle
 if runicpowerdeficit() < 14 and { spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() spell(death_coil)
 #defile,if=cooldown.apocalypse.remains
 if spellcooldown(apocalypse) > 0 spell(defile)
 #scourge_strike,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&(cooldown.army_of_the_dead.remains>5|death_knight.disable_aotd)
 if { target.debuffpresent(festering_wound_debuff) and spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and { 480 > 5 or 0 } spell(scourge_strike)
 #clawing_shadows,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&(cooldown.army_of_the_dead.remains>5|death_knight.disable_aotd)
 if { target.debuffpresent(festering_wound_debuff) and spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and { 480 > 5 or 0 } spell(clawing_shadows)
 #death_coil,if=runic_power.deficit<20&!variable.pooling_for_gargoyle
 if runicpowerdeficit() < 20 and not pooling_for_gargoyle() spell(death_coil)
 #festering_strike,if=((((debuff.festering_wound.stack<4&!buff.unholy_frenzy.up)|debuff.festering_wound.stack<3)&cooldown.apocalypse.remains<3)|debuff.festering_wound.stack<1)&(cooldown.army_of_the_dead.remains>5|death_knight.disable_aotd)
 if { { target.debuffstacks(festering_wound_debuff) < 4 and not buffpresent(unholy_frenzy_buff) or target.debuffstacks(festering_wound_debuff) < 3 } and spellcooldown(apocalypse) < 3 or target.debuffstacks(festering_wound_debuff) < 1 } and { 480 > 5 or 0 } spell(festering_strike)
 #death_coil,if=!variable.pooling_for_gargoyle
 if not pooling_for_gargoyle() spell(death_coil)
}

AddFunction unholygenericmainpostconditions
{
}

AddFunction unholygenericshortcdactions
{
 unless { buffpresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.present() } and spell(death_coil) or runicpowerdeficit() < 14 and { spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and spell(death_coil)
 {
  #death_and_decay,if=talent.pestilence.enabled&cooldown.apocalypse.remains
  if hastalent(pestilence_talent) and spellcooldown(apocalypse) > 0 spell(death_and_decay)
 }
}

AddFunction unholygenericshortcdpostconditions
{
 { buffpresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.present() } and spell(death_coil) or runicpowerdeficit() < 14 and { spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and spell(death_coil) or spellcooldown(apocalypse) > 0 and spell(defile) or { target.debuffpresent(festering_wound_debuff) and spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and { 480 > 5 or 0 } and spell(scourge_strike) or { target.debuffpresent(festering_wound_debuff) and spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and { 480 > 5 or 0 } and spell(clawing_shadows) or runicpowerdeficit() < 20 and not pooling_for_gargoyle() and spell(death_coil) or { { target.debuffstacks(festering_wound_debuff) < 4 and not buffpresent(unholy_frenzy_buff) or target.debuffstacks(festering_wound_debuff) < 3 } and spellcooldown(apocalypse) < 3 or target.debuffstacks(festering_wound_debuff) < 1 } and { 480 > 5 or 0 } and spell(festering_strike) or not pooling_for_gargoyle() and spell(death_coil)
}

AddFunction unholygenericcdactions
{
}

AddFunction unholygenericcdpostconditions
{
 { buffpresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.present() } and spell(death_coil) or runicpowerdeficit() < 14 and { spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and spell(death_coil) or hastalent(pestilence_talent) and spellcooldown(apocalypse) > 0 and spell(death_and_decay) or spellcooldown(apocalypse) > 0 and spell(defile) or { target.debuffpresent(festering_wound_debuff) and spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and { 480 > 5 or 0 } and spell(scourge_strike) or { target.debuffpresent(festering_wound_debuff) and spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and { 480 > 5 or 0 } and spell(clawing_shadows) or runicpowerdeficit() < 20 and not pooling_for_gargoyle() and spell(death_coil) or { { target.debuffstacks(festering_wound_debuff) < 4 and not buffpresent(unholy_frenzy_buff) or target.debuffstacks(festering_wound_debuff) < 3 } and spellcooldown(apocalypse) < 3 or target.debuffstacks(festering_wound_debuff) < 1 } and { 480 > 5 or 0 } and spell(festering_strike) or not pooling_for_gargoyle() and spell(death_coil)
}

### actions.essences

AddFunction unholyessencesmainactions
{
 #concentrated_flame,if=dot.concentrated_flame_burn.remains=0
 if not target.debuffremaining(concentrated_flame_burn_debuff) > 0 spell(concentrated_flame_essence)
}

AddFunction unholyessencesmainpostconditions
{
}

AddFunction unholyessencesshortcdactions
{
 #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<11
 if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 11 spell(the_unbound_force)

 unless not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence)
 {
  #purifying_blast,if=!death_and_decay.ticking
  if not buffpresent(death_and_decay) spell(purifying_blast)
  #worldvein_resonance,if=talent.army_of_the_damned.enabled&essence.vision_of_perfection.minor&buff.unholy_strength.up|essence.vision_of_perfection.minor&pet.apoc_ghoul.active|talent.army_of_the_damned.enabled&pet.apoc_ghoul.active&cooldown.army_of_the_dead.remains>60|talent.army_of_the_damned.enabled&pet.army_ghoul.active
  if hastalent(army_of_the_damned_talent) and azeriteessenceisminor(vision_of_perfection_essence_id) and buffpresent(unholy_strength_buff) or azeriteessenceisminor(vision_of_perfection_essence_id) and 0 or hastalent(army_of_the_damned_talent) and 0 and 480 > 60 or hastalent(army_of_the_damned_talent) and pet.present() spell(worldvein_resonance_essence)
  #worldvein_resonance,if=!death_and_decay.ticking&buff.unholy_strength.up&!essence.vision_of_perfection.minor&!talent.army_of_the_damned.enabled|target.time_to_die<cooldown.apocalypse.remains
  if not buffpresent(death_and_decay) and buffpresent(unholy_strength_buff) and not azeriteessenceisminor(vision_of_perfection_essence_id) and not hastalent(army_of_the_damned_talent) or target.timetodie() < spellcooldown(apocalypse) spell(worldvein_resonance_essence)
  #ripple_in_space,if=!death_and_decay.ticking
  if not buffpresent(death_and_decay) spell(ripple_in_space_essence)
  #reaping_flames
  spell(reaping_flames)
 }
}

AddFunction unholyessencesshortcdpostconditions
{
 not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence)
}

AddFunction unholyessencescdactions
{
 #memory_of_lucid_dreams,if=rune.time_to_1>gcd&runic_power<40
 if timetorunes(1) > gcd() and runicpower() < 40 spell(memory_of_lucid_dreams_essence)
 #blood_of_the_enemy,if=(cooldown.death_and_decay.remains&spell_targets.death_and_decay>1)|(cooldown.defile.remains&spell_targets.defile>1)|(cooldown.apocalypse.remains&cooldown.death_and_decay.ready)
 if spellcooldown(death_and_decay) > 0 and enemies() > 1 or spellcooldown(defile) > 0 and enemies() > 1 or spellcooldown(apocalypse) > 0 and spellcooldown(death_and_decay) == 0 spell(blood_of_the_enemy)
 #guardian_of_azeroth,if=(cooldown.apocalypse.remains<6&cooldown.army_of_the_dead.remains>cooldown.condensed_lifeforce.remains)|cooldown.army_of_the_dead.remains<2
 if spellcooldown(apocalypse) < 6 and 480 > spellcooldown(condensed_life_force) or 480 < 2 spell(guardian_of_azeroth)

 unless { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 11 } and spell(the_unbound_force)
 {
  #focused_azerite_beam,if=!death_and_decay.ticking
  if not buffpresent(death_and_decay) spell(focused_azerite_beam)
 }
}

AddFunction unholyessencescdpostconditions
{
 { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 11 } and spell(the_unbound_force) or not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame_essence) or not buffpresent(death_and_decay) and spell(purifying_blast) or { hastalent(army_of_the_damned_talent) and azeriteessenceisminor(vision_of_perfection_essence_id) and buffpresent(unholy_strength_buff) or azeriteessenceisminor(vision_of_perfection_essence_id) and 0 or hastalent(army_of_the_damned_talent) and 0 and 480 > 60 or hastalent(army_of_the_damned_talent) and pet.present() } and spell(worldvein_resonance_essence) or { not buffpresent(death_and_decay) and buffpresent(unholy_strength_buff) and not azeriteessenceisminor(vision_of_perfection_essence_id) and not hastalent(army_of_the_damned_talent) or target.timetodie() < spellcooldown(apocalypse) } and spell(worldvein_resonance_essence) or not buffpresent(death_and_decay) and spell(ripple_in_space_essence) or spell(reaping_flames)
}

### actions.cooldowns

AddFunction unholycooldownsmainactions
{
}

AddFunction unholycooldownsmainpostconditions
{
}

AddFunction unholycooldownsshortcdactions
{
 #apocalypse,if=debuff.festering_wound.stack>=4
 if target.debuffstacks(festering_wound_debuff) >= 4 spell(apocalypse)
 #dark_transformation,if=!raid_event.adds.exists|raid_event.adds.in>15
 if not false(raid_event_adds_exists) or 600 > 15 spell(dark_transformation)
 #unholy_frenzy,if=essence.vision_of_perfection.enabled|(essence.condensed_lifeforce.enabled&pet.apoc_ghoul.active)|debuff.festering_wound.stack<4&!(equipped.ramping_amplitude_gigavolt_engine|azerite.magus_of_the_dead.enabled)|cooldown.apocalypse.remains<2&(equipped.ramping_amplitude_gigavolt_engine|azerite.magus_of_the_dead.enabled)
 if azeriteessenceisenabled(vision_of_perfection_essence_id) or azeriteessenceisenabled(condensed_life_force_essence_id) and 0 or target.debuffstacks(festering_wound_debuff) < 4 and not { hasequippeditem(ramping_amplitude_gigavolt_engine_item) or hasazeritetrait(magus_of_the_dead_trait) } or spellcooldown(apocalypse) < 2 and { hasequippeditem(ramping_amplitude_gigavolt_engine_item) or hasazeritetrait(magus_of_the_dead_trait) } spell(unholy_frenzy)
 #unholy_frenzy,if=active_enemies>=2&((cooldown.death_and_decay.remains<=gcd&!talent.defile.enabled)|(cooldown.defile.remains<=gcd&talent.defile.enabled))
 if enemies() >= 2 and { spellcooldown(death_and_decay) <= gcd() and not hastalent(defile_talent) or spellcooldown(defile) <= gcd() and hastalent(defile_talent) } spell(unholy_frenzy)
 #soul_reaper,target_if=target.time_to_die<8&target.time_to_die>4
 if target.timetodie() < 8 and target.timetodie() > 4 spell(soul_reaper)
 #soul_reaper,if=(!raid_event.adds.exists|raid_event.adds.in>20)&rune<=(1-buff.unholy_frenzy.up)
 if { not false(raid_event_adds_exists) or 600 > 20 } and runecount() <= 1 - buffpresent(unholy_frenzy_buff) spell(soul_reaper)
 #unholy_blight
 spell(unholy_blight)
}

AddFunction unholycooldownsshortcdpostconditions
{
}

AddFunction unholycooldownscdactions
{
 #army_of_the_dead
 spell(army_of_the_dead)

 unless target.debuffstacks(festering_wound_debuff) >= 4 and spell(apocalypse) or { not false(raid_event_adds_exists) or 600 > 15 } and spell(dark_transformation)
 {
  #summon_gargoyle,if=runic_power.deficit<14
  if runicpowerdeficit() < 14 spell(summon_gargoyle)
 }
}

AddFunction unholycooldownscdpostconditions
{
 target.debuffstacks(festering_wound_debuff) >= 4 and spell(apocalypse) or { not false(raid_event_adds_exists) or 600 > 15 } and spell(dark_transformation) or { azeriteessenceisenabled(vision_of_perfection_essence_id) or azeriteessenceisenabled(condensed_life_force_essence_id) and 0 or target.debuffstacks(festering_wound_debuff) < 4 and not { hasequippeditem(ramping_amplitude_gigavolt_engine_item) or hasazeritetrait(magus_of_the_dead_trait) } or spellcooldown(apocalypse) < 2 and { hasequippeditem(ramping_amplitude_gigavolt_engine_item) or hasazeritetrait(magus_of_the_dead_trait) } } and spell(unholy_frenzy) or enemies() >= 2 and { spellcooldown(death_and_decay) <= gcd() and not hastalent(defile_talent) or spellcooldown(defile) <= gcd() and hastalent(defile_talent) } and spell(unholy_frenzy) or target.timetodie() < 8 and target.timetodie() > 4 and spell(soul_reaper) or { not false(raid_event_adds_exists) or 600 > 20 } and runecount() <= 1 - buffpresent(unholy_frenzy_buff) and spell(soul_reaper) or spell(unholy_blight)
}

### actions.aoe

AddFunction unholyaoemainactions
{
 #defile
 spell(defile)
 #epidemic,if=death_and_decay.ticking&rune<2&!variable.pooling_for_gargoyle
 if buffpresent(death_and_decay) and runecount() < 2 and not pooling_for_gargoyle() spell(epidemic)
 #death_coil,if=death_and_decay.ticking&rune<2&!variable.pooling_for_gargoyle
 if buffpresent(death_and_decay) and runecount() < 2 and not pooling_for_gargoyle() spell(death_coil)
 #scourge_strike,if=death_and_decay.ticking&cooldown.apocalypse.remains
 if buffpresent(death_and_decay) and spellcooldown(apocalypse) > 0 spell(scourge_strike)
 #clawing_shadows,if=death_and_decay.ticking&cooldown.apocalypse.remains
 if buffpresent(death_and_decay) and spellcooldown(apocalypse) > 0 spell(clawing_shadows)
 #epidemic,if=!variable.pooling_for_gargoyle
 if not pooling_for_gargoyle() spell(epidemic)
 #festering_strike,target_if=debuff.festering_wound.stack<=1&cooldown.death_and_decay.remains
 if target.debuffstacks(festering_wound_debuff) <= 1 and spellcooldown(death_and_decay) > 0 spell(festering_strike)
 #festering_strike,if=talent.bursting_sores.enabled&spell_targets.bursting_sores>=2&debuff.festering_wound.stack<=1
 if hastalent(bursting_sores_talent) and enemies() >= 2 and target.debuffstacks(festering_wound_debuff) <= 1 spell(festering_strike)
 #death_coil,if=buff.sudden_doom.react&rune.deficit>=4
 if buffpresent(sudden_doom_buff) and runedeficit() >= 4 spell(death_coil)
 #death_coil,if=buff.sudden_doom.react&!variable.pooling_for_gargoyle|pet.gargoyle.active
 if buffpresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.present() spell(death_coil)
 #death_coil,if=runic_power.deficit<14&(cooldown.apocalypse.remains>5|debuff.festering_wound.stack>4)&!variable.pooling_for_gargoyle
 if runicpowerdeficit() < 14 and { spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() spell(death_coil)
 #scourge_strike,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&(cooldown.army_of_the_dead.remains>5|death_knight.disable_aotd)
 if { target.debuffpresent(festering_wound_debuff) and spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and { 480 > 5 or 0 } spell(scourge_strike)
 #clawing_shadows,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&(cooldown.army_of_the_dead.remains>5|death_knight.disable_aotd)
 if { target.debuffpresent(festering_wound_debuff) and spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and { 480 > 5 or 0 } spell(clawing_shadows)
 #death_coil,if=runic_power.deficit<20&!variable.pooling_for_gargoyle
 if runicpowerdeficit() < 20 and not pooling_for_gargoyle() spell(death_coil)
 #festering_strike,if=((((debuff.festering_wound.stack<4&!buff.unholy_frenzy.up)|debuff.festering_wound.stack<3)&cooldown.apocalypse.remains<3)|debuff.festering_wound.stack<1)&(cooldown.army_of_the_dead.remains>5|death_knight.disable_aotd)
 if { { target.debuffstacks(festering_wound_debuff) < 4 and not buffpresent(unholy_frenzy_buff) or target.debuffstacks(festering_wound_debuff) < 3 } and spellcooldown(apocalypse) < 3 or target.debuffstacks(festering_wound_debuff) < 1 } and { 480 > 5 or 0 } spell(festering_strike)
 #death_coil,if=!variable.pooling_for_gargoyle
 if not pooling_for_gargoyle() spell(death_coil)
}

AddFunction unholyaoemainpostconditions
{
}

AddFunction unholyaoeshortcdactions
{
 #death_and_decay,if=cooldown.apocalypse.remains
 if spellcooldown(apocalypse) > 0 spell(death_and_decay)
}

AddFunction unholyaoeshortcdpostconditions
{
 spell(defile) or buffpresent(death_and_decay) and runecount() < 2 and not pooling_for_gargoyle() and spell(epidemic) or buffpresent(death_and_decay) and runecount() < 2 and not pooling_for_gargoyle() and spell(death_coil) or buffpresent(death_and_decay) and spellcooldown(apocalypse) > 0 and spell(scourge_strike) or buffpresent(death_and_decay) and spellcooldown(apocalypse) > 0 and spell(clawing_shadows) or not pooling_for_gargoyle() and spell(epidemic) or target.debuffstacks(festering_wound_debuff) <= 1 and spellcooldown(death_and_decay) > 0 and spell(festering_strike) or hastalent(bursting_sores_talent) and enemies() >= 2 and target.debuffstacks(festering_wound_debuff) <= 1 and spell(festering_strike) or buffpresent(sudden_doom_buff) and runedeficit() >= 4 and spell(death_coil) or { buffpresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.present() } and spell(death_coil) or runicpowerdeficit() < 14 and { spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and spell(death_coil) or { target.debuffpresent(festering_wound_debuff) and spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and { 480 > 5 or 0 } and spell(scourge_strike) or { target.debuffpresent(festering_wound_debuff) and spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and { 480 > 5 or 0 } and spell(clawing_shadows) or runicpowerdeficit() < 20 and not pooling_for_gargoyle() and spell(death_coil) or { { target.debuffstacks(festering_wound_debuff) < 4 and not buffpresent(unholy_frenzy_buff) or target.debuffstacks(festering_wound_debuff) < 3 } and spellcooldown(apocalypse) < 3 or target.debuffstacks(festering_wound_debuff) < 1 } and { 480 > 5 or 0 } and spell(festering_strike) or not pooling_for_gargoyle() and spell(death_coil)
}

AddFunction unholyaoecdactions
{
}

AddFunction unholyaoecdpostconditions
{
 spellcooldown(apocalypse) > 0 and spell(death_and_decay) or spell(defile) or buffpresent(death_and_decay) and runecount() < 2 and not pooling_for_gargoyle() and spell(epidemic) or buffpresent(death_and_decay) and runecount() < 2 and not pooling_for_gargoyle() and spell(death_coil) or buffpresent(death_and_decay) and spellcooldown(apocalypse) > 0 and spell(scourge_strike) or buffpresent(death_and_decay) and spellcooldown(apocalypse) > 0 and spell(clawing_shadows) or not pooling_for_gargoyle() and spell(epidemic) or target.debuffstacks(festering_wound_debuff) <= 1 and spellcooldown(death_and_decay) > 0 and spell(festering_strike) or hastalent(bursting_sores_talent) and enemies() >= 2 and target.debuffstacks(festering_wound_debuff) <= 1 and spell(festering_strike) or buffpresent(sudden_doom_buff) and runedeficit() >= 4 and spell(death_coil) or { buffpresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.present() } and spell(death_coil) or runicpowerdeficit() < 14 and { spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and spell(death_coil) or { target.debuffpresent(festering_wound_debuff) and spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and { 480 > 5 or 0 } and spell(scourge_strike) or { target.debuffpresent(festering_wound_debuff) and spellcooldown(apocalypse) > 5 or target.debuffstacks(festering_wound_debuff) > 4 } and { 480 > 5 or 0 } and spell(clawing_shadows) or runicpowerdeficit() < 20 and not pooling_for_gargoyle() and spell(death_coil) or { { target.debuffstacks(festering_wound_debuff) < 4 and not buffpresent(unholy_frenzy_buff) or target.debuffstacks(festering_wound_debuff) < 3 } and spellcooldown(apocalypse) < 3 or target.debuffstacks(festering_wound_debuff) < 1 } and { 480 > 5 or 0 } and spell(festering_strike) or not pooling_for_gargoyle() and spell(death_coil)
}

### actions.default

AddFunction unholy_defaultmainactions
{
 #outbreak,target_if=dot.virulent_plague.remains<=gcd
 if target.debuffremaining(virulent_plague_debuff) <= gcd() spell(outbreak)
 #call_action_list,name=essences
 unholyessencesmainactions()

 unless unholyessencesmainpostconditions()
 {
  #call_action_list,name=cooldowns
  unholycooldownsmainactions()

  unless unholycooldownsmainpostconditions()
  {
   #run_action_list,name=aoe,if=active_enemies>=2
   if enemies() >= 2 unholyaoemainactions()

   unless enemies() >= 2 and unholyaoemainpostconditions()
   {
    #call_action_list,name=generic
    unholygenericmainactions()
   }
  }
 }
}

AddFunction unholy_defaultmainpostconditions
{
 unholyessencesmainpostconditions() or unholycooldownsmainpostconditions() or enemies() >= 2 and unholyaoemainpostconditions() or unholygenericmainpostconditions()
}

AddFunction unholy_defaultshortcdactions
{
 #auto_attack
 unholygetinmeleerange()
 #bag_of_tricks,if=buff.unholy_strength.up|buff.festermight.remains<gcd
 if buffpresent(unholy_strength_buff) or buffremaining(festermight) < gcd() spell(bag_of_tricks)

 unless target.debuffremaining(virulent_plague_debuff) <= gcd() and spell(outbreak)
 {
  #call_action_list,name=essences
  unholyessencesshortcdactions()

  unless unholyessencesshortcdpostconditions()
  {
   #call_action_list,name=cooldowns
   unholycooldownsshortcdactions()

   unless unholycooldownsshortcdpostconditions()
   {
    #run_action_list,name=aoe,if=active_enemies>=2
    if enemies() >= 2 unholyaoeshortcdactions()

    unless enemies() >= 2 and unholyaoeshortcdpostconditions()
    {
     #call_action_list,name=generic
     unholygenericshortcdactions()
    }
   }
  }
 }
}

AddFunction unholy_defaultshortcdpostconditions
{
 target.debuffremaining(virulent_plague_debuff) <= gcd() and spell(outbreak) or unholyessencesshortcdpostconditions() or unholycooldownsshortcdpostconditions() or enemies() >= 2 and unholyaoeshortcdpostconditions() or unholygenericshortcdpostconditions()
}

AddFunction unholy_defaultcdactions
{
 unholyinterruptactions()
 #variable,name=pooling_for_gargoyle,value=cooldown.summon_gargoyle.remains<5&talent.summon_gargoyle.enabled
 #arcane_torrent,if=runic_power.deficit>65&(pet.gargoyle.active|!talent.summon_gargoyle.enabled)&rune.deficit>=5
 if runicpowerdeficit() > 65 and { pet.present() or not hastalent(summon_gargoyle_talent) } and runedeficit() >= 5 spell(arcane_torrent_runicpower)
 #blood_fury,if=pet.gargoyle.active|!talent.summon_gargoyle.enabled
 if pet.present() or not hastalent(summon_gargoyle_talent) spell(blood_fury_ap)
 #berserking,if=buff.unholy_frenzy.up|pet.gargoyle.active|(talent.army_of_the_damned.enabled&pet.apoc_ghoul.active)
 if buffpresent(unholy_frenzy_buff) or pet.present() or hastalent(army_of_the_damned_talent) and 0 spell(berserking)
 #lights_judgment,if=(buff.unholy_strength.up&buff.festermight.remains<=5)|active_enemies>=2&(buff.unholy_strength.up|buff.festermight.remains<=5)
 if buffpresent(unholy_strength_buff) and buffremaining(festermight) <= 5 or enemies() >= 2 and { buffpresent(unholy_strength_buff) or buffremaining(festermight) <= 5 } spell(lights_judgment)
 #ancestral_call,if=(pet.gargoyle.active&talent.summon_gargoyle.enabled)|pet.apoc_ghoul.active
 if pet.present() and hastalent(summon_gargoyle_talent) or 0 spell(ancestral_call)
 #arcane_pulse,if=active_enemies>=2|(rune.deficit>=5&runic_power.deficit>=60)
 if enemies() >= 2 or runedeficit() >= 5 and runicpowerdeficit() >= 60 spell(arcane_pulse)
 #fireblood,if=(pet.gargoyle.active&talent.summon_gargoyle.enabled)|pet.apoc_ghoul.active
 if pet.present() and hastalent(summon_gargoyle_talent) or 0 spell(fireblood)

 unless { buffpresent(unholy_strength_buff) or buffremaining(festermight) < gcd() } and spell(bag_of_tricks)
 {
  #use_items,if=time>20|!equipped.ramping_amplitude_gigavolt_engine|!equipped.vision_of_demise
  if timeincombat() > 20 or not hasequippeditem(ramping_amplitude_gigavolt_engine_item) or not hasequippeditem(vision_of_demise_item) unholyuseitemactions()
  #use_item,name=azsharas_font_of_power,if=(essence.vision_of_perfection.enabled&!talent.unholy_frenzy.enabled)|(!essence.condensed_lifeforce.major&!essence.vision_of_perfection.enabled)
  if azeriteessenceisenabled(vision_of_perfection_essence_id) and not hastalent(unholy_frenzy_talent) or not azeriteessenceismajor(condensed_life_force_essence_id) and not azeriteessenceisenabled(vision_of_perfection_essence_id) unholyuseitemactions()
  #use_item,name=azsharas_font_of_power,if=cooldown.apocalypse.remains<14&(essence.condensed_lifeforce.major|essence.vision_of_perfection.enabled&talent.unholy_frenzy.enabled)
  if spellcooldown(apocalypse) < 14 and { azeriteessenceismajor(condensed_life_force_essence_id) or azeriteessenceisenabled(vision_of_perfection_essence_id) and hastalent(unholy_frenzy_talent) } unholyuseitemactions()
  #use_item,name=azsharas_font_of_power,if=target.1.time_to_die<cooldown.apocalypse.remains+34
  if target.timetodie() < spellcooldown(apocalypse) + 34 unholyuseitemactions()
  #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.stack<1
  if target.debuffstacks(razor_coral) < 1 unholyuseitemactions()
  #use_item,name=ashvanes_razor_coral,if=pet.guardian_of_azeroth.active&pet.apoc_ghoul.active
  if pet.present() and 0 unholyuseitemactions()
  #use_item,name=ashvanes_razor_coral,if=cooldown.apocalypse.ready&(essence.condensed_lifeforce.major&target.1.time_to_die<cooldown.condensed_lifeforce.remains+20|!essence.condensed_lifeforce.major)
  if spellcooldown(apocalypse) == 0 and { azeriteessenceismajor(condensed_life_force_essence_id) and target.timetodie() < spellcooldown(condensed_life_force) + 20 or not azeriteessenceismajor(condensed_life_force_essence_id) } unholyuseitemactions()
  #use_item,name=ashvanes_razor_coral,if=target.1.time_to_die<cooldown.apocalypse.remains+20
  if target.timetodie() < spellcooldown(apocalypse) + 20 unholyuseitemactions()
  #use_item,name=vision_of_demise,if=(cooldown.apocalypse.ready&debuff.festering_wound.stack>=4&essence.vision_of_perfection.enabled)|buff.unholy_frenzy.up|pet.gargoyle.active
  if spellcooldown(apocalypse) == 0 and target.debuffstacks(festering_wound_debuff) >= 4 and azeriteessenceisenabled(vision_of_perfection_essence_id) or buffpresent(unholy_frenzy_buff) or pet.present() unholyuseitemactions()
  #use_item,name=ramping_amplitude_gigavolt_engine,if=cooldown.apocalypse.remains<2|talent.army_of_the_damned.enabled|raid_event.adds.in<5
  if spellcooldown(apocalypse) < 2 or hastalent(army_of_the_damned_talent) or 600 < 5 unholyuseitemactions()
  #use_item,name=bygone_bee_almanac,if=cooldown.summon_gargoyle.remains>60|!talent.summon_gargoyle.enabled&time>20|!equipped.ramping_amplitude_gigavolt_engine
  if spellcooldown(summon_gargoyle) > 60 or not hastalent(summon_gargoyle_talent) and timeincombat() > 20 or not hasequippeditem(ramping_amplitude_gigavolt_engine_item) unholyuseitemactions()
  #use_item,name=jes_howler,if=pet.gargoyle.active|!talent.summon_gargoyle.enabled&time>20|!equipped.ramping_amplitude_gigavolt_engine
  if pet.present() or not hastalent(summon_gargoyle_talent) and timeincombat() > 20 or not hasequippeditem(ramping_amplitude_gigavolt_engine_item) unholyuseitemactions()
  #use_item,name=galecallers_beak,if=pet.gargoyle.active|!talent.summon_gargoyle.enabled&time>20|!equipped.ramping_amplitude_gigavolt_engine
  if pet.present() or not hastalent(summon_gargoyle_talent) and timeincombat() > 20 or not hasequippeditem(ramping_amplitude_gigavolt_engine_item) unholyuseitemactions()
  #use_item,name=grongs_primal_rage,if=rune<=3&(time>20|!equipped.ramping_amplitude_gigavolt_engine)
  if runecount() <= 3 and { timeincombat() > 20 or not hasequippeditem(ramping_amplitude_gigavolt_engine_item) } unholyuseitemactions()
  #potion,if=cooldown.army_of_the_dead.ready|pet.gargoyle.active|buff.unholy_frenzy.up
  if { spellcooldown(army_of_the_dead) == 0 or pet.present() or buffpresent(unholy_frenzy_buff) } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

  unless target.debuffremaining(virulent_plague_debuff) <= gcd() and spell(outbreak)
  {
   #call_action_list,name=essences
   unholyessencescdactions()

   unless unholyessencescdpostconditions()
   {
    #call_action_list,name=cooldowns
    unholycooldownscdactions()

    unless unholycooldownscdpostconditions()
    {
     #run_action_list,name=aoe,if=active_enemies>=2
     if enemies() >= 2 unholyaoecdactions()

     unless enemies() >= 2 and unholyaoecdpostconditions()
     {
      #call_action_list,name=generic
      unholygenericcdactions()
     }
    }
   }
  }
 }
}

AddFunction unholy_defaultcdpostconditions
{
 { buffpresent(unholy_strength_buff) or buffremaining(festermight) < gcd() } and spell(bag_of_tricks) or target.debuffremaining(virulent_plague_debuff) <= gcd() and spell(outbreak) or unholyessencescdpostconditions() or unholycooldownscdpostconditions() or enemies() >= 2 and unholyaoecdpostconditions() or unholygenericcdpostconditions()
}

### Unholy icons.

AddCheckBox(opt_deathknight_unholy_aoe l(aoe) default specialization=unholy)

AddIcon checkbox=!opt_deathknight_unholy_aoe enemies=1 help=shortcd specialization=unholy
{
 if not incombat() unholyprecombatshortcdactions()
 unholy_defaultshortcdactions()
}

AddIcon checkbox=opt_deathknight_unholy_aoe help=shortcd specialization=unholy
{
 if not incombat() unholyprecombatshortcdactions()
 unholy_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=unholy
{
 if not incombat() unholyprecombatmainactions()
 unholy_defaultmainactions()
}

AddIcon checkbox=opt_deathknight_unholy_aoe help=aoe specialization=unholy
{
 if not incombat() unholyprecombatmainactions()
 unholy_defaultmainactions()
}

AddIcon checkbox=!opt_deathknight_unholy_aoe enemies=1 help=cd specialization=unholy
{
 if not incombat() unholyprecombatcdactions()
 unholy_defaultcdactions()
}

AddIcon checkbox=opt_deathknight_unholy_aoe help=cd specialization=unholy
{
 if not incombat() unholyprecombatcdactions()
 unholy_defaultcdactions()
}

### Required symbols
# ancestral_call
# apocalypse
# arcane_pulse
# arcane_torrent_runicpower
# army_of_the_damned_talent
# army_of_the_dead
# asphyxiate
# bag_of_tricks
# berserking
# blood_fury_ap
# blood_of_the_enemy
# bursting_sores_talent
# clawing_shadows
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# condensed_life_force
# condensed_life_force_essence_id
# dark_transformation
# death_and_decay
# death_coil
# death_strike
# defile
# defile_talent
# epidemic
# festering_strike
# festering_wound_debuff
# festermight
# fireblood
# focused_azerite_beam
# guardian_of_azeroth
# lights_judgment
# magus_of_the_dead_trait
# memory_of_lucid_dreams_essence
# mind_freeze
# outbreak
# pestilence_talent
# purifying_blast
# raise_dead
# ramping_amplitude_gigavolt_engine_item
# razor_coral
# reaping_flames
# reckless_force_buff
# reckless_force_counter_buff
# ripple_in_space_essence
# scourge_strike
# soul_reaper
# sudden_doom_buff
# summon_gargoyle
# summon_gargoyle_talent
# the_unbound_force
# unbridled_fury_item
# unholy_blight
# unholy_frenzy
# unholy_frenzy_buff
# unholy_frenzy_talent
# unholy_strength_buff
# virulent_plague_debuff
# vision_of_demise_item
# vision_of_perfection_essence_id
# war_stomp
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("DEATHKNIGHT", "unholy", name, desc, code, "script")
    end
end
