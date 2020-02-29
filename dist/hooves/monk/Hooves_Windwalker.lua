local __exports = LibStub:GetLibrary("ovale/scripts/ovale_monk")
if not __exports then return end
__exports.registerMonkWindwalkerHooves = function(OvaleScripts)
do
	local name = "hooves_windwalker"
	local desc = "[Hooves][8.3] Monk: Windwalker"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

# Windwalker
AddIcon specialization=3 help=main
{
    # if not mounted() and not {BuffPresent(critical_strike_buff any=1) or BuffPresent(str_agi_int_buff any=1)} Spell(legacy_of_the_white_tiger)

	#spear_hand_strike
	#if InCombat() InterruptActions()

	if target.InRange(tiger_palm) and HasFullControl()
    {
		# Cooldowns
		if Boss() WindwalkerDefaultCdActions()

		WindwalkerDefaultShortCdActions()

		WindwalkerDefaultMainActions()
    }
}





AddFunction coral_double_tod_on_use
{
 hasequippeditem(ashvanes_razor_coral_item) and { hasequippeditem(cyclotronic_blast_item) or hasequippeditem(lustrous_golden_plumage_item) or hasequippeditem(gladiators_badge) or hasequippeditem(gladiators_medallion_item) or hasequippeditem(remote_guidance_device_item) }
}

AddFunction windwalkerinterruptactions
{
 #if target.hasmanagedinterrupts() and target.mustbeinterrupted() or not target.hasmanagedinterrupts() and target.isinterruptible()
 #{
#  if target.inrange(spear_hand_strike) and target.isinterruptible() and target.remainingcasttime() <= casttime(spear_hand_strike) + gcd() spell(spear_hand_strike)
#  if target.distance(less 5) and not target.classification(worldboss) and target.remainingcasttime() <= casttime(leg_sweep) + gcd() spell(leg_sweep)
#  if target.inrange(quaking_palm) and not target.classification(worldboss) and target.remainingcasttime() <= casttime(quaking_palm) + gcd() spell(quaking_palm)
#  if target.distance(less 5) and not target.classification(worldboss) and target.remainingcasttime() <= casttime(war_stomp) + gcd() spell(war_stomp)
#  if target.inrange(paralysis) and not target.classification(worldboss) and target.remainingcasttime() <= casttime(paralysis) + gcd() spell(paralysis)
 #}
}

AddFunction windwalkeruseitemactions
{
# if item(trinket0slot usable=1) texture(inv_jewelry_talisman_12)
 #if item(trinket1slot usable=1) texture(inv_jewelry_talisman_12)
}

AddFunction windwalkergetinmeleerange
{
 if checkboxon(opt_melee_range) and not target.inrange(tiger_palm) texture(misc_arrowlup help=l(not_in_melee_range))
}

### actions.default

AddFunction windwalkerdefaultmainactions
{
 #call_action_list,name=serenity,if=buff.serenity.up
 if buffpresent(serenity) windwalkerserenitymainactions()

 unless buffpresent(serenity) and windwalkerserenitymainpostconditions()
 {
  #fist_of_the_white_tiger,if=(energy.time_to_max<1|(talent.serenity.enabled&cooldown.serenity.remains<2)|(energy.time_to_max<4&cooldown.fists_of_fury.remains<1.5))&chi.max-chi>=3
  if { timetomaxenergy() < 1 or hastalent(serenity_talent) and spellcooldown(serenity) < 2 or timetomaxenergy() < 4 and spellcooldown(fists_of_fury) < 1.5 } and maxchi() - chi() >= 3 spell(fist_of_the_white_tiger)
  #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!combo_break&(energy.time_to_max<1|(talent.serenity.enabled&cooldown.serenity.remains<2)|(energy.time_to_max<4&cooldown.fists_of_fury.remains<1.5))&chi.max-chi>=2&!dot.touch_of_death.remains
  if not previousspell(tiger_palm) and { timetomaxenergy() < 1 or hastalent(serenity_talent) and spellcooldown(serenity) < 2 or timetomaxenergy() < 4 and spellcooldown(fists_of_fury) < 1.5 } and maxchi() - chi() >= 2 and not target.debuffremaining(touch_of_death) spell(tiger_palm)
  #chi_wave,if=!talent.fist_of_the_white_tiger.enabled&time<=3
  if not hastalent(fist_of_the_white_tiger_talent) and timeincombat() <= 3 spell(chi_wave)
  #call_action_list,name=cd
  windwalkercdmainactions()

  unless windwalkercdmainpostconditions()
  {
   #call_action_list,name=st,if=active_enemies<3
   if enemies(tagged=1) < 3 windwalkerstmainactions()

   unless enemies(tagged=1) < 3 and windwalkerstmainpostconditions()
   {
    #call_action_list,name=aoe,if=active_enemies>=3
    if enemies(tagged=1) >= 3 windwalkeraoemainactions()
   }
  }
 }
}

AddFunction windwalkerdefaultmainpostconditions
{
 buffpresent(serenity) and windwalkerserenitymainpostconditions() or windwalkercdmainpostconditions() or enemies(tagged=1) < 3 and windwalkerstmainpostconditions() or enemies(tagged=1) >= 3 and windwalkeraoemainpostconditions()
}

AddFunction windwalkerdefaultshortcdactions
{
 #auto_attack
 windwalkergetinmeleerange()
 #touch_of_karma,interval=90,pct_health=0.5
 if checkboxon(opt_touch_of_karma) spell(touch_of_karma)
 #call_action_list,name=serenity,if=buff.serenity.up
 if buffpresent(serenity) windwalkerserenityshortcdactions()

 unless buffpresent(serenity) and windwalkerserenityshortcdpostconditions()
 {
  #reverse_harm,if=(energy.time_to_max<1|(talent.serenity.enabled&cooldown.serenity.remains<2))&chi.max-chi>=2
  if { timetomaxenergy() < 1 or hastalent(serenity_talent) and spellcooldown(serenity) < 2 } and maxchi() - chi() >= 2 spell(reverse_harm)

  unless { timetomaxenergy() < 1 or hastalent(serenity_talent) and spellcooldown(serenity) < 2 or timetomaxenergy() < 4 and spellcooldown(fists_of_fury) < 1.5 } and maxchi() - chi() >= 3 and spell(fist_of_the_white_tiger) or not previousspell(tiger_palm) and { timetomaxenergy() < 1 or hastalent(serenity_talent) and spellcooldown(serenity) < 2 or timetomaxenergy() < 4 and spellcooldown(fists_of_fury) < 1.5 } and maxchi() - chi() >= 2 and not target.debuffremaining(touch_of_death) and spell(tiger_palm) or not hastalent(fist_of_the_white_tiger_talent) and timeincombat() <= 3 and spell(chi_wave)
  {
   #call_action_list,name=cd
   windwalkercdshortcdactions()

   unless windwalkercdshortcdpostconditions()
   {
    #call_action_list,name=st,if=active_enemies<3
    if enemies(tagged=1) < 3 windwalkerstshortcdactions()

    unless enemies(tagged=1) < 3 and windwalkerstshortcdpostconditions()
    {
     #call_action_list,name=aoe,if=active_enemies>=3
     if enemies(tagged=1) >= 3 windwalkeraoeshortcdactions()
    }
   }
  }
 }
}

AddFunction windwalkerdefaultshortcdpostconditions
{
 buffpresent(serenity) and windwalkerserenityshortcdpostconditions() or { timetomaxenergy() < 1 or hastalent(serenity_talent) and spellcooldown(serenity) < 2 or timetomaxenergy() < 4 and spellcooldown(fists_of_fury) < 1.5 } and maxchi() - chi() >= 3 and spell(fist_of_the_white_tiger) or not previousspell(tiger_palm) and { timetomaxenergy() < 1 or hastalent(serenity_talent) and spellcooldown(serenity) < 2 or timetomaxenergy() < 4 and spellcooldown(fists_of_fury) < 1.5 } and maxchi() - chi() >= 2 and not target.debuffremaining(touch_of_death) and spell(tiger_palm) or not hastalent(fist_of_the_white_tiger_talent) and timeincombat() <= 3 and spell(chi_wave) or windwalkercdshortcdpostconditions() or enemies(tagged=1) < 3 and windwalkerstshortcdpostconditions() or enemies(tagged=1) >= 3 and windwalkeraoeshortcdpostconditions()
}

AddFunction windwalkerdefaultcdactions
{
 #spear_hand_strike,if=target.debuff.casting.react
 if target.casting(harmful) windwalkerinterruptactions()
 #potion,if=buff.serenity.up|dot.touch_of_death.remains|!talent.serenity.enabled&trinket.proc.agility.react|buff.bloodlust.react|target.time_to_die<=60
 if { buffpresent(serenity) or target.debuffremaining(touch_of_death) or not hastalent(serenity_talent) and buffpresent(trinket_proc_agility_buff) or buffpresent(burst_haste_buff any=1) or target.timetodie() <= 60 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #call_action_list,name=serenity,if=buff.serenity.up
 if buffpresent(serenity) windwalkerserenitycdactions()

 unless buffpresent(serenity) and windwalkerserenitycdpostconditions() or { timetomaxenergy() < 1 or hastalent(serenity_talent) and spellcooldown(serenity) < 2 or timetomaxenergy() < 4 and spellcooldown(fists_of_fury) < 1.5 } and maxchi() - chi() >= 3 and spell(fist_of_the_white_tiger) or not previousspell(tiger_palm) and { timetomaxenergy() < 1 or hastalent(serenity_talent) and spellcooldown(serenity) < 2 or timetomaxenergy() < 4 and spellcooldown(fists_of_fury) < 1.5 } and maxchi() - chi() >= 2 and not target.debuffremaining(touch_of_death) and spell(tiger_palm) or not hastalent(fist_of_the_white_tiger_talent) and timeincombat() <= 3 and spell(chi_wave)
 {
  #call_action_list,name=cd
  windwalkercdcdactions()

  unless windwalkercdcdpostconditions()
  {
   #call_action_list,name=st,if=active_enemies<3
   if enemies(tagged=1) < 3 windwalkerstcdactions()

   unless enemies(tagged=1) < 3 and windwalkerstcdpostconditions()
   {
    #call_action_list,name=aoe,if=active_enemies>=3
    if enemies(tagged=1) >= 3 windwalkeraoecdactions()
   }
  }
 }
}

AddFunction windwalkerdefaultcdpostconditions
{
 buffpresent(serenity) and windwalkerserenitycdpostconditions() or { timetomaxenergy() < 1 or hastalent(serenity_talent) and spellcooldown(serenity) < 2 or timetomaxenergy() < 4 and spellcooldown(fists_of_fury) < 1.5 } and maxchi() - chi() >= 3 and spell(fist_of_the_white_tiger) or not previousspell(tiger_palm) and { timetomaxenergy() < 1 or hastalent(serenity_talent) and spellcooldown(serenity) < 2 or timetomaxenergy() < 4 and spellcooldown(fists_of_fury) < 1.5 } and maxchi() - chi() >= 2 and not target.debuffremaining(touch_of_death) and spell(tiger_palm) or not hastalent(fist_of_the_white_tiger_talent) and timeincombat() <= 3 and spell(chi_wave) or windwalkercdcdpostconditions() or enemies(tagged=1) < 3 and windwalkerstcdpostconditions() or enemies(tagged=1) >= 3 and windwalkeraoecdpostconditions()
}

### actions.aoe

AddFunction windwalkeraoemainactions
{
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(talent.whirling_dragon_punch.enabled&cooldown.whirling_dragon_punch.remains<5)&cooldown.fists_of_fury.remains>3
 if hastalent(whirling_dragon_punch_talent) and spellcooldown(whirling_dragon_punch) < 5 and spellcooldown(fists_of_fury) > 3 spell(rising_sun_kick)
 #whirling_dragon_punch
 if spellcooldown(fists_of_fury) > 0 and spellcooldown(rising_sun_kick) > 0 spell(whirling_dragon_punch)
 #energizing_elixir,if=!prev_gcd.1.tiger_palm&chi<=1&energy<50
 if not previousgcdspell(tiger_palm) and chi() <= 1 and energy() < 50 spell(energizing_elixir)
 #fists_of_fury,if=energy.time_to_max>3
 if timetomaxenergy() > 3 spell(fists_of_fury)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down
 if buffexpires(rushing_jade_wind_windwalker_buff) spell(rushing_jade_wind)
 #spinning_crane_kick,if=combo_strike&(((chi>3|cooldown.fists_of_fury.remains>6)&(chi>=5|cooldown.fists_of_fury.remains>2))|energy.time_to_max<=3)
 if not previousspell(spinning_crane_kick) and { { chi() > 3 or spellcooldown(fists_of_fury) > 6 } and { chi() >= 5 or spellcooldown(fists_of_fury) > 2 } or timetomaxenergy() <= 3 } spell(spinning_crane_kick)
 #chi_burst,if=chi<=3
 if chi() <= 3 spell(chi_burst)
 #fist_of_the_white_tiger,if=chi.max-chi>=3
 if maxchi() - chi() >= 3 spell(fist_of_the_white_tiger)
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=chi.max-chi>=2&(!talent.hit_combo.enabled|!combo_break)
 if maxchi() - chi() >= 2 and { not hastalent(hit_combo_talent) or not previousspell(tiger_palm) } spell(tiger_palm)
 #chi_wave,if=!combo_break
 if not previousspell(chi_wave) spell(chi_wave)
 #flying_serpent_kick,if=buff.bok_proc.down,interrupt=1
 if buffexpires(blackout_kick_buff) and checkboxon(opt_flying_serpent_kick) spell(flying_serpent_kick)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&(buff.bok_proc.up|(talent.hit_combo.enabled&prev_gcd.1.tiger_palm&chi<4))
 if not previousspell(blackout_kick_windwalker) and { buffpresent(blackout_kick_buff) or hastalent(hit_combo_talent) and previousgcdspell(tiger_palm) and chi() < 4 } spell(blackout_kick_windwalker)
}

AddFunction windwalkeraoemainpostconditions
{
}

AddFunction windwalkeraoeshortcdactions
{
 unless hastalent(whirling_dragon_punch_talent) and spellcooldown(whirling_dragon_punch) < 5 and spellcooldown(fists_of_fury) > 3 and spell(rising_sun_kick) or spellcooldown(fists_of_fury) > 0 and spellcooldown(rising_sun_kick) > 0 and spell(whirling_dragon_punch) or not previousgcdspell(tiger_palm) and chi() <= 1 and energy() < 50 and spell(energizing_elixir) or timetomaxenergy() > 3 and spell(fists_of_fury) or buffexpires(rushing_jade_wind_windwalker_buff) and spell(rushing_jade_wind) or not previousspell(spinning_crane_kick) and { { chi() > 3 or spellcooldown(fists_of_fury) > 6 } and { chi() >= 5 or spellcooldown(fists_of_fury) > 2 } or timetomaxenergy() <= 3 } and spell(spinning_crane_kick)
 {
  #reverse_harm,if=chi.max-chi>=2
  if maxchi() - chi() >= 2 spell(reverse_harm)
 }
}

AddFunction windwalkeraoeshortcdpostconditions
{
 hastalent(whirling_dragon_punch_talent) and spellcooldown(whirling_dragon_punch) < 5 and spellcooldown(fists_of_fury) > 3 and spell(rising_sun_kick) or spellcooldown(fists_of_fury) > 0 and spellcooldown(rising_sun_kick) > 0 and spell(whirling_dragon_punch) or not previousgcdspell(tiger_palm) and chi() <= 1 and energy() < 50 and spell(energizing_elixir) or timetomaxenergy() > 3 and spell(fists_of_fury) or buffexpires(rushing_jade_wind_windwalker_buff) and spell(rushing_jade_wind) or not previousspell(spinning_crane_kick) and { { chi() > 3 or spellcooldown(fists_of_fury) > 6 } and { chi() >= 5 or spellcooldown(fists_of_fury) > 2 } or timetomaxenergy() <= 3 } and spell(spinning_crane_kick) or chi() <= 3 and spell(chi_burst) or maxchi() - chi() >= 3 and spell(fist_of_the_white_tiger) or maxchi() - chi() >= 2 and { not hastalent(hit_combo_talent) or not previousspell(tiger_palm) } and spell(tiger_palm) or not previousspell(chi_wave) and spell(chi_wave) or buffexpires(blackout_kick_buff) and checkboxon(opt_flying_serpent_kick) and spell(flying_serpent_kick) or not previousspell(blackout_kick_windwalker) and { buffpresent(blackout_kick_buff) or hastalent(hit_combo_talent) and previousgcdspell(tiger_palm) and chi() < 4 } and spell(blackout_kick_windwalker)
}

AddFunction windwalkeraoecdactions
{
}

AddFunction windwalkeraoecdpostconditions
{
 hastalent(whirling_dragon_punch_talent) and spellcooldown(whirling_dragon_punch) < 5 and spellcooldown(fists_of_fury) > 3 and spell(rising_sun_kick) or spellcooldown(fists_of_fury) > 0 and spellcooldown(rising_sun_kick) > 0 and spell(whirling_dragon_punch) or not previousgcdspell(tiger_palm) and chi() <= 1 and energy() < 50 and spell(energizing_elixir) or timetomaxenergy() > 3 and spell(fists_of_fury) or buffexpires(rushing_jade_wind_windwalker_buff) and spell(rushing_jade_wind) or not previousspell(spinning_crane_kick) and { { chi() > 3 or spellcooldown(fists_of_fury) > 6 } and { chi() >= 5 or spellcooldown(fists_of_fury) > 2 } or timetomaxenergy() <= 3 } and spell(spinning_crane_kick) or chi() <= 3 and spell(chi_burst) or maxchi() - chi() >= 3 and spell(fist_of_the_white_tiger) or maxchi() - chi() >= 2 and { not hastalent(hit_combo_talent) or not previousspell(tiger_palm) } and spell(tiger_palm) or not previousspell(chi_wave) and spell(chi_wave) or buffexpires(blackout_kick_buff) and checkboxon(opt_flying_serpent_kick) and spell(flying_serpent_kick) or not previousspell(blackout_kick_windwalker) and { buffpresent(blackout_kick_buff) or hastalent(hit_combo_talent) and previousgcdspell(tiger_palm) and chi() < 4 } and spell(blackout_kick_windwalker)
}

### actions.cd

AddFunction windwalkercdmainactions
{
 #call_action_list,name=tod
 windwalkertodmainactions()

 unless windwalkertodmainpostconditions()
 {
  #concentrated_flame,if=!dot.concentrated_flame_burn.remains&(cooldown.concentrated_flame.remains<=cooldown.touch_of_death.remains&(talent.whirling_dragon_punch.enabled&cooldown.whirling_dragon_punch.remains)&cooldown.rising_sun_kick.remains&cooldown.fists_of_fury.remains&buff.storm_earth_and_fire.down|dot.touch_of_death.remains)|target.time_to_die<8
  if not target.debuffremaining(concentrated_flame_burn_debuff) and { spellcooldown(concentrated_flame_essence) <= spellcooldown(touch_of_death) and hastalent(whirling_dragon_punch_talent) and spellcooldown(whirling_dragon_punch) > 0 and spellcooldown(rising_sun_kick) > 0 and spellcooldown(fists_of_fury) > 0 and buffexpires(storm_earth_and_fire) or target.debuffremaining(touch_of_death) } or target.timetodie() < 8 spell(concentrated_flame_essence)
 }
}

AddFunction windwalkercdmainpostconditions
{
 windwalkertodmainpostconditions()
}

AddFunction windwalkercdshortcdactions
{
 #worldvein_resonance,if=cooldown.touch_of_death.remains>58|cooldown.touch_of_death.remains<2|target.time_to_die<20
 #if spellcooldown(touch_of_death) > 58 or spellcooldown(touch_of_death) < 2 or target.timetodie() < 20 spell(worldvein_resonance_essence)
 #bag_of_tricks
 spell(bag_of_tricks)
 #call_action_list,name=tod
 windwalkertodshortcdactions()

 unless windwalkertodshortcdpostconditions()
 {
  #blood_of_the_enemy,if=dot.touch_of_death.remains|target.time_to_die<12
  if target.debuffremaining(touch_of_death) or target.timetodie() < 12 spell(blood_of_the_enemy)

  unless { not target.debuffremaining(concentrated_flame_burn_debuff) and { spellcooldown(concentrated_flame_essence) <= spellcooldown(touch_of_death) and hastalent(whirling_dragon_punch_talent) and spellcooldown(whirling_dragon_punch) > 0 and spellcooldown(rising_sun_kick) > 0 and spellcooldown(fists_of_fury) > 0 and buffexpires(storm_earth_and_fire) or target.debuffremaining(touch_of_death) } or target.timetodie() < 8 } and spell(concentrated_flame_essence)
  {
   #the_unbound_force
   #spell(the_unbound_force)
   #purifying_blast
   #spell(purifying_blast)
   #reaping_flames
   #spell(reaping_flames_essence)
   #serenity,if=cooldown.rising_sun_kick.remains<=2|target.time_to_die<=12
   #if spellcooldown(rising_sun_kick) <= 2 or target.timetodie() <= 12 spell(serenity)
   #ripple_in_space
   #spell(ripple_in_space_essence)
  }
 }
}

AddFunction windwalkercdshortcdpostconditions
{
 windwalkertodshortcdpostconditions() or { not target.debuffremaining(concentrated_flame_burn_debuff) and { spellcooldown(concentrated_flame_essence) <= spellcooldown(touch_of_death) and hastalent(whirling_dragon_punch_talent) and spellcooldown(whirling_dragon_punch) > 0 and spellcooldown(rising_sun_kick) > 0 and spellcooldown(fists_of_fury) > 0 and buffexpires(storm_earth_and_fire) or target.debuffremaining(touch_of_death) } or target.timetodie() < 8 } and spell(concentrated_flame_essence)
}

AddFunction windwalkercdcdactions
{
 #invoke_xuen_the_white_tiger
 spell(invoke_xuen_the_white_tiger)
 #guardian_of_azeroth,if=target.time_to_die>185|(!equipped.dribbling_inkpod|equipped.cyclotronic_blast|target.health.pct<30)&cooldown.touch_of_death.remains<=14|equipped.dribbling_inkpod&target.time_to_pct_30.remains<20|target.time_to_die<35
 if target.timetodie() > 185 or { not hasequippeditem(dribbling_inkpod_item) or hasequippeditem(cyclotronic_blast_item) or target.healthpercent() < 30 } and spellcooldown(touch_of_death) <= 14 or hasequippeditem(dribbling_inkpod_item) and target.timetohealthpercent(30) < 20 or target.timetodie() < 35 spell(guardian_of_azeroth)

 unless { spellcooldown(touch_of_death) > 58 or spellcooldown(touch_of_death) < 2 or target.timetodie() < 20 } and spell(worldvein_resonance_essence)
 {
  #blood_fury
  spell(blood_fury_apsp)
  #arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
  if maxchi() - chi() >= 1 and timetomaxenergy() >= 0.5 spell(arcane_torrent_chi)
  #lights_judgment
  spell(lights_judgment)

  unless spell(bag_of_tricks)
  {
   #call_action_list,name=tod
   windwalkertodcdactions()

   unless windwalkertodcdpostconditions()
   {
    #storm_earth_and_fire,,if=cooldown.storm_earth_and_fire.charges=2|(!essence.worldvein_resonance.major|(buff.worldvein_resonance.up|cooldown.worldvein_resonance.remains>cooldown.storm_earth_and_fire.full_recharge_time))&(cooldown.touch_of_death.remains>cooldown.storm_earth_and_fire.full_recharge_time|cooldown.touch_of_death.remains>target.time_to_die)&cooldown.fists_of_fury.remains<=9&chi>=3&cooldown.whirling_dragon_punch.remains<=13|dot.touch_of_death.remains|target.time_to_die<20
    if { spellcharges(storm_earth_and_fire) == 2 or { not azeriteessenceismajor(worldvein_resonance_essence_id) or buffpresent(worldvein_resonance_essence) or spellcooldown(worldvein_resonance_essence) > spellcooldown(storm_earth_and_fire) } and { spellcooldown(touch_of_death) > spellcooldown(storm_earth_and_fire) or spellcooldown(touch_of_death) > target.timetodie() } and spellcooldown(fists_of_fury) <= 9 and chi() >= 3 and spellcooldown(whirling_dragon_punch) <= 13 or target.debuffremaining(touch_of_death) or target.timetodie() < 20 } and not buffpresent(storm_earth_and_fire_buff) spell(storm_earth_and_fire)
    #use_items,if=equipped.cyclotronic_blast&cooldown.cyclotronic_blast.remains>=20|!equipped.cyclotronic_blast
    if hasequippeditem(cyclotronic_blast_item) and spellcooldown(cyclotronic_blast) >= 20 or not hasequippeditem(cyclotronic_blast_item) windwalkeruseitemactions()
    #ancestral_call,if=dot.touch_of_death.remains|target.time_to_die<16
    if target.debuffremaining(touch_of_death) or target.timetodie() < 16 spell(ancestral_call)
    #fireblood,if=dot.touch_of_death.remains|target.time_to_die<9
    if target.debuffremaining(touch_of_death) or target.timetodie() < 9 spell(fireblood)

    unless { not target.debuffremaining(concentrated_flame_burn_debuff) and { spellcooldown(concentrated_flame_essence) <= spellcooldown(touch_of_death) and hastalent(whirling_dragon_punch_talent) and spellcooldown(whirling_dragon_punch) > 0 and spellcooldown(rising_sun_kick) > 0 and spellcooldown(fists_of_fury) > 0 and buffexpires(storm_earth_and_fire) or target.debuffremaining(touch_of_death) } or target.timetodie() < 8 } and spell(concentrated_flame_essence)
    {
     #berserking,if=target.time_to_die>183|dot.touch_of_death.remains|target.time_to_die<13
     if target.timetodie() > 183 or target.debuffremaining(touch_of_death) or target.timetodie() < 13 spell(berserking)
     #use_item,name=pocketsized_computation_device,if=dot.touch_of_death.remains
     if target.debuffremaining(touch_of_death) windwalkeruseitemactions()
     #use_item,name=ashvanes_razor_coral,if=variable.coral_double_tod_on_use&cooldown.touch_of_death.remains>=23&(debuff.razor_coral_debuff.down|buff.storm_earth_and_fire.remains>13|target.time_to_die-cooldown.touch_of_death.remains<40&cooldown.touch_of_death.remains<23|target.time_to_die<25)
     if coral_double_tod_on_use() and spellcooldown(touch_of_death) >= 23 and { target.debuffexpires(razor_coral_debuff) or buffremaining(storm_earth_and_fire) > 13 or target.timetodie() - spellcooldown(touch_of_death) < 40 and spellcooldown(touch_of_death) < 23 or target.timetodie() < 25 } windwalkeruseitemactions()
     #use_item,name=ashvanes_razor_coral,if=!variable.coral_double_tod_on_use&(debuff.razor_coral_debuff.down|(!equipped.dribbling_inkpod|target.time_to_pct_30.remains<8)&(dot.touch_of_death.remains|cooldown.touch_of_death.remains+9>target.time_to_die&buff.storm_earth_and_fire.up|target.time_to_die<25))
     if not coral_double_tod_on_use() and { target.debuffexpires(razor_coral_debuff) or { not hasequippeditem(dribbling_inkpod_item) or target.timetohealthpercent(30) < 8 } and { target.debuffremaining(touch_of_death) or spellcooldown(touch_of_death) + 9 > target.timetodie() and buffpresent(storm_earth_and_fire) or target.timetodie() < 25 } } windwalkeruseitemactions()

     unless spell(the_unbound_force) or spell(purifying_blast) or spell(reaping_flames_essence)
     {
      #focused_azerite_beam
      #spell(focused_azerite_beam)

      unless { spellcooldown(rising_sun_kick) <= 2 or target.timetodie() <= 12 } and spell(serenity)
      {
       #memory_of_lucid_dreams,if=energy<40&buff.storm_earth_and_fire.up
       #if energy() < 40 and buffpresent(storm_earth_and_fire) spell(memory_of_lucid_dreams_essence)
      }
     }
    }
   }
  }
 }
}

AddFunction windwalkercdcdpostconditions
{
 { spellcooldown(touch_of_death) > 58 or spellcooldown(touch_of_death) < 2 or target.timetodie() < 20 } and spell(worldvein_resonance_essence) or spell(bag_of_tricks) or windwalkertodcdpostconditions() or { not target.debuffremaining(concentrated_flame_burn_debuff) and { spellcooldown(concentrated_flame_essence) <= spellcooldown(touch_of_death) and hastalent(whirling_dragon_punch_talent) and spellcooldown(whirling_dragon_punch) > 0 and spellcooldown(rising_sun_kick) > 0 and spellcooldown(fists_of_fury) > 0 and buffexpires(storm_earth_and_fire) or target.debuffremaining(touch_of_death) } or target.timetodie() < 8 } and spell(concentrated_flame_essence) or spell(the_unbound_force) or spell(purifying_blast) or spell(reaping_flames_essence) or { spellcooldown(rising_sun_kick) <= 2 or target.timetodie() <= 12 } and spell(serenity) or spell(ripple_in_space_essence)
}

### actions.precombat

AddFunction windwalkerprecombatmainactions
{
 #variable,name=coral_double_tod_on_use,op=set,value=equipped.ashvanes_razor_coral&(equipped.cyclotronic_blast|equipped.lustrous_golden_plumage|equipped.gladiators_badge|equipped.gladiators_medallion|equipped.remote_guidance_device)
 #chi_burst,if=(!talent.serenity.enabled|!talent.fist_of_the_white_tiger.enabled)
 if not hastalent(serenity_talent) or not hastalent(fist_of_the_white_tiger_talent) spell(chi_burst)
 #chi_wave,if=talent.fist_of_the_white_tiger.enabled
 if hastalent(fist_of_the_white_tiger_talent) spell(chi_wave)
}

AddFunction windwalkerprecombatmainpostconditions
{
}

AddFunction windwalkerprecombatshortcdactions
{
}

AddFunction windwalkerprecombatshortcdpostconditions
{
 { not hastalent(serenity_talent) or not hastalent(fist_of_the_white_tiger_talent) } and spell(chi_burst) or hastalent(fist_of_the_white_tiger_talent) and spell(chi_wave)
}

AddFunction windwalkerprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

 unless { not hastalent(serenity_talent) or not hastalent(fist_of_the_white_tiger_talent) } and spell(chi_burst) or hastalent(fist_of_the_white_tiger_talent) and spell(chi_wave)
 {
  #invoke_xuen_the_white_tiger
  spell(invoke_xuen_the_white_tiger)
  #guardian_of_azeroth
  spell(guardian_of_azeroth)
 }
}

AddFunction windwalkerprecombatcdpostconditions
{
 { not hastalent(serenity_talent) or not hastalent(fist_of_the_white_tiger_talent) } and spell(chi_burst) or hastalent(fist_of_the_white_tiger_talent) and spell(chi_wave)
}

### actions.serenity

AddFunction windwalkerserenitymainactions
{
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies<3|prev_gcd.1.spinning_crane_kick
 if enemies(tagged=1) < 3 or previousgcdspell(spinning_crane_kick) spell(rising_sun_kick)
 #fists_of_fury,if=(buff.bloodlust.up&prev_gcd.1.rising_sun_kick)|buff.serenity.remains<1|(active_enemies>1&active_enemies<5)
 if buffpresent(burst_haste_buff any=1) and previousgcdspell(rising_sun_kick) or buffremaining(serenity) < 1 or enemies(tagged=1) > 1 and enemies(tagged=1) < 5 spell(fists_of_fury)
 #fist_of_the_white_tiger,if=talent.hit_combo.enabled&energy.time_to_max<2&prev_gcd.1.blackout_kick&chi<=2
 if hastalent(hit_combo_talent) and timetomaxenergy() < 2 and previousgcdspell(blackout_kick_windwalker) and chi() <= 2 spell(fist_of_the_white_tiger)
 #tiger_palm,if=talent.hit_combo.enabled&energy.time_to_max<1&prev_gcd.1.blackout_kick&chi.max-chi>=2
 if hastalent(hit_combo_talent) and timetomaxenergy() < 1 and previousgcdspell(blackout_kick_windwalker) and maxchi() - chi() >= 2 spell(tiger_palm)
 #spinning_crane_kick,if=combo_strike&(active_enemies>=3|(talent.hit_combo.enabled&prev_gcd.1.blackout_kick)|(active_enemies=2&prev_gcd.1.blackout_kick))
 if not previousspell(spinning_crane_kick) and { enemies(tagged=1) >= 3 or hastalent(hit_combo_talent) and previousgcdspell(blackout_kick_windwalker) or enemies(tagged=1) == 2 and previousgcdspell(blackout_kick_windwalker) } spell(spinning_crane_kick)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains
 spell(blackout_kick_windwalker)
}

AddFunction windwalkerserenitymainpostconditions
{
}

AddFunction windwalkerserenityshortcdactions
{
}

AddFunction windwalkerserenityshortcdpostconditions
{
 { enemies(tagged=1) < 3 or previousgcdspell(spinning_crane_kick) } and spell(rising_sun_kick) or { buffpresent(burst_haste_buff any=1) and previousgcdspell(rising_sun_kick) or buffremaining(serenity) < 1 or enemies(tagged=1) > 1 and enemies(tagged=1) < 5 } and spell(fists_of_fury) or hastalent(hit_combo_talent) and timetomaxenergy() < 2 and previousgcdspell(blackout_kick_windwalker) and chi() <= 2 and spell(fist_of_the_white_tiger) or hastalent(hit_combo_talent) and timetomaxenergy() < 1 and previousgcdspell(blackout_kick_windwalker) and maxchi() - chi() >= 2 and spell(tiger_palm) or not previousspell(spinning_crane_kick) and { enemies(tagged=1) >= 3 or hastalent(hit_combo_talent) and previousgcdspell(blackout_kick_windwalker) or enemies(tagged=1) == 2 and previousgcdspell(blackout_kick_windwalker) } and spell(spinning_crane_kick) or spell(blackout_kick_windwalker)
}

AddFunction windwalkerserenitycdactions
{
}

AddFunction windwalkerserenitycdpostconditions
{
 { enemies(tagged=1) < 3 or previousgcdspell(spinning_crane_kick) } and spell(rising_sun_kick) or { buffpresent(burst_haste_buff any=1) and previousgcdspell(rising_sun_kick) or buffremaining(serenity) < 1 or enemies(tagged=1) > 1 and enemies(tagged=1) < 5 } and spell(fists_of_fury) or hastalent(hit_combo_talent) and timetomaxenergy() < 2 and previousgcdspell(blackout_kick_windwalker) and chi() <= 2 and spell(fist_of_the_white_tiger) or hastalent(hit_combo_talent) and timetomaxenergy() < 1 and previousgcdspell(blackout_kick_windwalker) and maxchi() - chi() >= 2 and spell(tiger_palm) or not previousspell(spinning_crane_kick) and { enemies(tagged=1) >= 3 or hastalent(hit_combo_talent) and previousgcdspell(blackout_kick_windwalker) or enemies(tagged=1) == 2 and previousgcdspell(blackout_kick_windwalker) } and spell(spinning_crane_kick) or spell(blackout_kick_windwalker)
}

### actions.st

AddFunction windwalkerstmainactions
{
 #whirling_dragon_punch
 if spellcooldown(fists_of_fury) > 0 and spellcooldown(rising_sun_kick) > 0 spell(whirling_dragon_punch)
 #fists_of_fury,if=energy.time_to_max>3
 if timetomaxenergy() > 3 spell(fists_of_fury)
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=chi>=5
 if chi() >= 5 spell(rising_sun_kick)
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains
 spell(rising_sun_kick)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down&active_enemies>1
 if buffexpires(rushing_jade_wind_windwalker_buff) and enemies(tagged=1) > 1 spell(rushing_jade_wind)
 #fist_of_the_white_tiger,if=chi<=2
 if chi() <= 2 spell(fist_of_the_white_tiger)
 #energizing_elixir,if=chi<=3&energy<50
 if chi() <= 3 and energy() < 50 spell(energizing_elixir)
 #spinning_crane_kick,if=combo_strike&buff.dance_of_chiji.react
 if not previousspell(spinning_crane_kick) and buffpresent(dance_of_chiji_buff) spell(spinning_crane_kick)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&(cooldown.rising_sun_kick.remains>3|chi>=3)&(cooldown.fists_of_fury.remains>4|chi>=4|(chi=2&prev_gcd.1.tiger_palm))
 if not previousspell(blackout_kick_windwalker) and { spellcooldown(rising_sun_kick) > 3 or chi() >= 3 } and { spellcooldown(fists_of_fury) > 4 or chi() >= 4 or chi() == 2 and previousgcdspell(tiger_palm) } spell(blackout_kick_windwalker)
 #chi_wave
 spell(chi_wave)
 #chi_burst,if=chi.max-chi>=1&active_enemies=1|chi.max-chi>=2
 if maxchi() - chi() >= 1 and enemies(tagged=1) == 1 or maxchi() - chi() >= 2 spell(chi_burst)
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&chi.max-chi>=2
 if not previousspell(tiger_palm) and maxchi() - chi() >= 2 spell(tiger_palm)
 #flying_serpent_kick,if=prev_gcd.1.blackout_kick&chi>3,interrupt=1
 if previousgcdspell(blackout_kick_windwalker) and chi() > 3 and checkboxon(opt_flying_serpent_kick) spell(flying_serpent_kick)
}

AddFunction windwalkerstmainpostconditions
{
}

AddFunction windwalkerstshortcdactions
{
 unless spellcooldown(fists_of_fury) > 0 and spellcooldown(rising_sun_kick) > 0 and spell(whirling_dragon_punch) or timetomaxenergy() > 3 and spell(fists_of_fury) or chi() >= 5 and spell(rising_sun_kick) or spell(rising_sun_kick) or buffexpires(rushing_jade_wind_windwalker_buff) and enemies(tagged=1) > 1 and spell(rushing_jade_wind)
 {
  #reverse_harm,if=chi.max-chi>=2
  if maxchi() - chi() >= 2 spell(reverse_harm)
 }
}

AddFunction windwalkerstshortcdpostconditions
{
 spellcooldown(fists_of_fury) > 0 and spellcooldown(rising_sun_kick) > 0 and spell(whirling_dragon_punch) or timetomaxenergy() > 3 and spell(fists_of_fury) or chi() >= 5 and spell(rising_sun_kick) or spell(rising_sun_kick) or buffexpires(rushing_jade_wind_windwalker_buff) and enemies(tagged=1) > 1 and spell(rushing_jade_wind) or chi() <= 2 and spell(fist_of_the_white_tiger) or chi() <= 3 and energy() < 50 and spell(energizing_elixir) or not previousspell(spinning_crane_kick) and buffpresent(dance_of_chiji_buff) and spell(spinning_crane_kick) or not previousspell(blackout_kick_windwalker) and { spellcooldown(rising_sun_kick) > 3 or chi() >= 3 } and { spellcooldown(fists_of_fury) > 4 or chi() >= 4 or chi() == 2 and previousgcdspell(tiger_palm) } and spell(blackout_kick_windwalker) or spell(chi_wave) or { maxchi() - chi() >= 1 and enemies(tagged=1) == 1 or maxchi() - chi() >= 2 } and spell(chi_burst) or not previousspell(tiger_palm) and maxchi() - chi() >= 2 and spell(tiger_palm) or previousgcdspell(blackout_kick_windwalker) and chi() > 3 and checkboxon(opt_flying_serpent_kick) and spell(flying_serpent_kick)
}

AddFunction windwalkerstcdactions
{
}

AddFunction windwalkerstcdpostconditions
{
 spellcooldown(fists_of_fury) > 0 and spellcooldown(rising_sun_kick) > 0 and spell(whirling_dragon_punch) or timetomaxenergy() > 3 and spell(fists_of_fury) or chi() >= 5 and spell(rising_sun_kick) or spell(rising_sun_kick) or buffexpires(rushing_jade_wind_windwalker_buff) and enemies(tagged=1) > 1 and spell(rushing_jade_wind) or chi() <= 2 and spell(fist_of_the_white_tiger) or chi() <= 3 and energy() < 50 and spell(energizing_elixir) or not previousspell(spinning_crane_kick) and buffpresent(dance_of_chiji_buff) and spell(spinning_crane_kick) or not previousspell(blackout_kick_windwalker) and { spellcooldown(rising_sun_kick) > 3 or chi() >= 3 } and { spellcooldown(fists_of_fury) > 4 or chi() >= 4 or chi() == 2 and previousgcdspell(tiger_palm) } and spell(blackout_kick_windwalker) or spell(chi_wave) or { maxchi() - chi() >= 1 and enemies(tagged=1) == 1 or maxchi() - chi() >= 2 } and spell(chi_burst) or not previousspell(tiger_palm) and maxchi() - chi() >= 2 and spell(tiger_palm) or previousgcdspell(blackout_kick_windwalker) and chi() > 3 and checkboxon(opt_flying_serpent_kick) and spell(flying_serpent_kick)
}

### actions.tod

AddFunction windwalkertodmainactions
{
}

AddFunction windwalkertodmainpostconditions
{
}

AddFunction windwalkertodshortcdactions
{
}

AddFunction windwalkertodshortcdpostconditions
{
}

AddFunction windwalkertodcdactions
{
 #touch_of_death,if=equipped.cyclotronic_blast&target.time_to_die>9&cooldown.cyclotronic_blast.remains<=1
 if hasequippeditem(cyclotronic_blast_item) and target.timetodie() > 9 and spellcooldown(cyclotronic_blast) <= 1 and { not unitinraid() and target.classification(elite) or target.classification(worldboss) or not buffexpires(hidden_masters_forbidden_touch_buff) } spell(touch_of_death)
 #touch_of_death,if=!equipped.cyclotronic_blast&equipped.dribbling_inkpod&target.time_to_die>9&(target.time_to_pct_30.remains>=130|target.time_to_pct_30.remains<8)
 if not hasequippeditem(cyclotronic_blast_item) and hasequippeditem(dribbling_inkpod_item) and target.timetodie() > 9 and { target.timetohealthpercent(30) >= 130 or target.timetohealthpercent(30) < 8 } and { not unitinraid() and target.classification(elite) or target.classification(worldboss) or not buffexpires(hidden_masters_forbidden_touch_buff) } spell(touch_of_death)
 #touch_of_death,if=!equipped.cyclotronic_blast&!equipped.dribbling_inkpod&target.time_to_die>9
 if not hasequippeditem(cyclotronic_blast_item) and not hasequippeditem(dribbling_inkpod_item) and target.timetodie() > 9 and { not unitinraid() and target.classification(elite) or target.classification(worldboss) or not buffexpires(hidden_masters_forbidden_touch_buff) } spell(touch_of_death)
}

AddFunction windwalkertodcdpostconditions
{
}







]]

		OvaleScripts:RegisterScript("MONK", "windwalker", name, desc, code, "script")
	end
end
