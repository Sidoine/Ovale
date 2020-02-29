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
 HasEquippedItem(ashvanes_razor_coral_item) and { HasEquippedItem(cyclotronic_blast_item) or HasEquippedItem(lustrous_golden_plumage_item) or HasEquippedItem(gladiators_badge_item) or HasEquippedItem(gladiators_medallion_item) or HasEquippedItem(remote_guidance_device_item) }
}

AddFunction WindwalkerInterruptActions
{
# if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 #{
  #if target.InRange(paralysis) and not target.Classification(worldboss) Spell(paralysis)
  #if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  #if target.InRange(spear_hand_strike) and target.IsInterruptible() Spell(spear_hand_strike)
  #if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  #if target.Distance(less 5) and not target.Classification(worldboss) Spell(leg_sweep)
 #}
}

AddFunction WindwalkerUseItemActions
{
 #Item(Trinket0Slot text=13 usable=1)
 #Item(Trinket1Slot text=14 usable=1)
}

AddFunction WindwalkerGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.default

AddFunction WindwalkerDefaultMainActions
{
 #call_action_list,name=serenity,if=buff.serenity.up
 if BuffPresent(serenity) WindwalkerSerenityMainActions()

 unless BuffPresent(serenity) and WindwalkerSerenityMainPostConditions()
 {
  #fist_of_the_white_tiger,if=(energy.time_to_max<1|(talent.serenity.enabled&cooldown.serenity.remains<2)|(energy.time_to_max<4&cooldown.fists_of_fury.remains<1.5))&chi.max-chi>=3
  if { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 or TimeToMaxEnergy() < 4 and SpellCooldown(fists_of_fury) < 1.5 } and MaxChi() - Chi() >= 3 Spell(fist_of_the_white_tiger)
  #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!combo_break&(energy.time_to_max<1|(talent.serenity.enabled&cooldown.serenity.remains<2)|(energy.time_to_max<4&cooldown.fists_of_fury.remains<1.5))&chi.max-chi>=2&!dot.touch_of_death.remains
  if not FIXME_combo_break and { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 or TimeToMaxEnergy() < 4 and SpellCooldown(fists_of_fury) < 1.5 } and MaxChi() - Chi() >= 2 and not target.DebuffRemaining(touch_of_death) Spell(tiger_palm)
  #chi_wave,if=!talent.fist_of_the_white_tiger.enabled&time<=3
  if not Talent(fist_of_the_white_tiger_talent) and TimeInCombat() <= 3 Spell(chi_wave)
  #call_action_list,name=cd
  WindwalkerCdMainActions()

  unless WindwalkerCdMainPostConditions()
  {
   #call_action_list,name=st,if=active_enemies<3
   if Enemies(tagged=1) < 3 WindwalkerStMainActions()

   unless Enemies(tagged=1) < 3 and WindwalkerStMainPostConditions()
   {
    #call_action_list,name=aoe,if=active_enemies>=3
    if Enemies(tagged=1) >= 3 WindwalkerAoeMainActions()
   }
  }
 }
}

AddFunction WindwalkerDefaultMainPostConditions
{
 BuffPresent(serenity) and WindwalkerSerenityMainPostConditions() or WindwalkerCdMainPostConditions() or Enemies(tagged=1) < 3 and WindwalkerStMainPostConditions() or Enemies(tagged=1) >= 3 and WindwalkerAoeMainPostConditions()
}

AddFunction WindwalkerDefaultShortCdActions
{
 #auto_attack
 WindwalkerGetInMeleeRange()
 #touch_of_karma,interval=90,pct_health=0.5
 if CheckBoxOn(opt_touch_of_karma) Spell(touch_of_karma)
 #call_action_list,name=serenity,if=buff.serenity.up
 if BuffPresent(serenity) WindwalkerSerenityShortCdActions()

 unless BuffPresent(serenity) and WindwalkerSerenityShortCdPostConditions()
 {
  #reverse_harm,if=(energy.time_to_max<1|(talent.serenity.enabled&cooldown.serenity.remains<2))&chi.max-chi>=2
  if { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 2 Spell(reverse_harm)

  unless { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 or TimeToMaxEnergy() < 4 and SpellCooldown(fists_of_fury) < 1.5 } and MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or not FIXME_combo_break and { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 or TimeToMaxEnergy() < 4 and SpellCooldown(fists_of_fury) < 1.5 } and MaxChi() - Chi() >= 2 and not target.DebuffRemaining(touch_of_death) and Spell(tiger_palm) or not Talent(fist_of_the_white_tiger_talent) and TimeInCombat() <= 3 and Spell(chi_wave)
  {
   #call_action_list,name=cd
   WindwalkerCdShortCdActions()

   unless WindwalkerCdShortCdPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<3
    if Enemies(tagged=1) < 3 WindwalkerStShortCdActions()

    unless Enemies(tagged=1) < 3 and WindwalkerStShortCdPostConditions()
    {
     #call_action_list,name=aoe,if=active_enemies>=3
     if Enemies(tagged=1) >= 3 WindwalkerAoeShortCdActions()
    }
   }
  }
 }
}

AddFunction WindwalkerDefaultShortCdPostConditions
{
 BuffPresent(serenity) and WindwalkerSerenityShortCdPostConditions() or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 or TimeToMaxEnergy() < 4 and SpellCooldown(fists_of_fury) < 1.5 } and MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or not FIXME_combo_break and { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 or TimeToMaxEnergy() < 4 and SpellCooldown(fists_of_fury) < 1.5 } and MaxChi() - Chi() >= 2 and not target.DebuffRemaining(touch_of_death) and Spell(tiger_palm) or not Talent(fist_of_the_white_tiger_talent) and TimeInCombat() <= 3 and Spell(chi_wave) or WindwalkerCdShortCdPostConditions() or Enemies(tagged=1) < 3 and WindwalkerStShortCdPostConditions() or Enemies(tagged=1) >= 3 and WindwalkerAoeShortCdPostConditions()
}

AddFunction WindwalkerDefaultCdActions
{
 #spear_hand_strike,if=target.debuff.casting.react
 if target.IsInterruptible() WindwalkerInterruptActions()
 #potion,if=buff.serenity.up|dot.touch_of_death.remains|!talent.serenity.enabled&trinket.proc.agility.react|buff.bloodlust.react|target.time_to_die<=60
 if { BuffPresent(serenity) or target.DebuffRemaining(touch_of_death) or not Talent(serenity_talent) and BuffPresent(trinket_proc_agility_buff) or BuffPresent(bloodlust) or target.TimeToDie() <= 60 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 #call_action_list,name=serenity,if=buff.serenity.up
 if BuffPresent(serenity) WindwalkerSerenityCdActions()

 unless BuffPresent(serenity) and WindwalkerSerenityCdPostConditions() or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 or TimeToMaxEnergy() < 4 and SpellCooldown(fists_of_fury) < 1.5 } and MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or not FIXME_combo_break and { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 or TimeToMaxEnergy() < 4 and SpellCooldown(fists_of_fury) < 1.5 } and MaxChi() - Chi() >= 2 and not target.DebuffRemaining(touch_of_death) and Spell(tiger_palm) or not Talent(fist_of_the_white_tiger_talent) and TimeInCombat() <= 3 and Spell(chi_wave)
 {
  #call_action_list,name=cd
  WindwalkerCdCdActions()

  unless WindwalkerCdCdPostConditions()
  {
   #call_action_list,name=st,if=active_enemies<3
   if Enemies(tagged=1) < 3 WindwalkerStCdActions()

   unless Enemies(tagged=1) < 3 and WindwalkerStCdPostConditions()
   {
    #call_action_list,name=aoe,if=active_enemies>=3
    if Enemies(tagged=1) >= 3 WindwalkerAoeCdActions()
   }
  }
 }
}

AddFunction WindwalkerDefaultCdPostConditions
{
 BuffPresent(serenity) and WindwalkerSerenityCdPostConditions() or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 or TimeToMaxEnergy() < 4 and SpellCooldown(fists_of_fury) < 1.5 } and MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or not FIXME_combo_break and { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 or TimeToMaxEnergy() < 4 and SpellCooldown(fists_of_fury) < 1.5 } and MaxChi() - Chi() >= 2 and not target.DebuffRemaining(touch_of_death) and Spell(tiger_palm) or not Talent(fist_of_the_white_tiger_talent) and TimeInCombat() <= 3 and Spell(chi_wave) or WindwalkerCdCdPostConditions() or Enemies(tagged=1) < 3 and WindwalkerStCdPostConditions() or Enemies(tagged=1) >= 3 and WindwalkerAoeCdPostConditions()
}

### actions.aoe

AddFunction WindwalkerAoeMainActions
{
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(talent.whirling_dragon_punch.enabled&cooldown.whirling_dragon_punch.remains<5)&cooldown.fists_of_fury.remains>3
 if Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) < 5 and SpellCooldown(fists_of_fury) > 3 Spell(rising_sun_kick)
 #whirling_dragon_punch
 if SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 Spell(whirling_dragon_punch)
 #energizing_elixir,if=!prev_gcd.1.tiger_palm&chi<=1&energy<50
 if not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and Energy() < 50 Spell(energizing_elixir)
 #fists_of_fury,if=energy.time_to_max>3
 if TimeToMaxEnergy() > 3 Spell(fists_of_fury)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down
 if BuffExpires(rushing_jade_wind_windwalker_buff) Spell(rushing_jade_wind)
 #spinning_crane_kick,if=combo_strike&(((chi>3|cooldown.fists_of_fury.remains>6)&(chi>=5|cooldown.fists_of_fury.remains>2))|energy.time_to_max<=3)
 if FIXME_combo_strike and { { Chi() > 3 or SpellCooldown(fists_of_fury) > 6 } and { Chi() >= 5 or SpellCooldown(fists_of_fury) > 2 } or TimeToMaxEnergy() <= 3 } Spell(spinning_crane_kick)
 #chi_burst,if=chi<=3
 if Chi() <= 3 and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #fist_of_the_white_tiger,if=chi.max-chi>=3
 if MaxChi() - Chi() >= 3 Spell(fist_of_the_white_tiger)
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=chi.max-chi>=2&(!talent.hit_combo.enabled|!combo_break)
 if MaxChi() - Chi() >= 2 and { not Talent(hit_combo_talent) or not FIXME_combo_break } Spell(tiger_palm)
 #chi_wave,if=!combo_break
 if not FIXME_combo_break Spell(chi_wave)
 #flying_serpent_kick,if=buff.bok_proc.down,interrupt=1
 if BuffExpires(blackout_kick_buff) and CheckBoxOn(opt_flying_serpent_kick) Spell(flying_serpent_kick)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&(buff.bok_proc.up|(talent.hit_combo.enabled&prev_gcd.1.tiger_palm&chi<4))
 if FIXME_combo_strike and { BuffPresent(blackout_kick_buff) or Talent(hit_combo_talent) and PreviousGCDSpell(tiger_palm) and Chi() < 4 } Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerAoeMainPostConditions
{
}

AddFunction WindwalkerAoeShortCdActions
{
 unless Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) < 5 and SpellCooldown(fists_of_fury) > 3 and Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and Energy() < 50 and Spell(energizing_elixir) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or BuffExpires(rushing_jade_wind_windwalker_buff) and Spell(rushing_jade_wind) or FIXME_combo_strike and { { Chi() > 3 or SpellCooldown(fists_of_fury) > 6 } and { Chi() >= 5 or SpellCooldown(fists_of_fury) > 2 } or TimeToMaxEnergy() <= 3 } and Spell(spinning_crane_kick)
 {
  #reverse_harm,if=chi.max-chi>=2
  if MaxChi() - Chi() >= 2 Spell(reverse_harm)
 }
}

AddFunction WindwalkerAoeShortCdPostConditions
{
 Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) < 5 and SpellCooldown(fists_of_fury) > 3 and Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and Energy() < 50 and Spell(energizing_elixir) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or BuffExpires(rushing_jade_wind_windwalker_buff) and Spell(rushing_jade_wind) or FIXME_combo_strike and { { Chi() > 3 or SpellCooldown(fists_of_fury) > 6 } and { Chi() >= 5 or SpellCooldown(fists_of_fury) > 2 } or TimeToMaxEnergy() <= 3 } and Spell(spinning_crane_kick) or Chi() <= 3 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or MaxChi() - Chi() >= 2 and { not Talent(hit_combo_talent) or not FIXME_combo_break } and Spell(tiger_palm) or not FIXME_combo_break and Spell(chi_wave) or BuffExpires(blackout_kick_buff) and CheckBoxOn(opt_flying_serpent_kick) and Spell(flying_serpent_kick) or FIXME_combo_strike and { BuffPresent(blackout_kick_buff) or Talent(hit_combo_talent) and PreviousGCDSpell(tiger_palm) and Chi() < 4 } and Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerAoeCdActions
{
}

AddFunction WindwalkerAoeCdPostConditions
{
 Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) < 5 and SpellCooldown(fists_of_fury) > 3 and Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and Energy() < 50 and Spell(energizing_elixir) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or BuffExpires(rushing_jade_wind_windwalker_buff) and Spell(rushing_jade_wind) or FIXME_combo_strike and { { Chi() > 3 or SpellCooldown(fists_of_fury) > 6 } and { Chi() >= 5 or SpellCooldown(fists_of_fury) > 2 } or TimeToMaxEnergy() <= 3 } and Spell(spinning_crane_kick) or Chi() <= 3 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or MaxChi() - Chi() >= 2 and { not Talent(hit_combo_talent) or not FIXME_combo_break } and Spell(tiger_palm) or not FIXME_combo_break and Spell(chi_wave) or BuffExpires(blackout_kick_buff) and CheckBoxOn(opt_flying_serpent_kick) and Spell(flying_serpent_kick) or FIXME_combo_strike and { BuffPresent(blackout_kick_buff) or Talent(hit_combo_talent) and PreviousGCDSpell(tiger_palm) and Chi() < 4 } and Spell(blackout_kick_windwalker)
}

### actions.cd

AddFunction WindwalkerCdMainActions
{
 #bag_of_tricks
 Spell(bag_of_tricks)
 #call_action_list,name=tod
 WindwalkerTodMainActions()

 unless WindwalkerTodMainPostConditions()
 {
  #concentrated_flame,if=!dot.concentrated_flame_burn.remains&(cooldown.concentrated_flame.remains<=cooldown.touch_of_death.remains&(talent.whirling_dragon_punch.enabled&cooldown.whirling_dragon_punch.remains)&cooldown.rising_sun_kick.remains&cooldown.fists_of_fury.remains&buff.storm_earth_and_fire.down|dot.touch_of_death.remains)|target.time_to_die<8
  if not target.DebuffRemaining(concentrated_flame_burn_debuff) and { SpellCooldown(concentrated_flame_essence) <= SpellCooldown(touch_of_death) and Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) > 0 and SpellCooldown(rising_sun_kick) > 0 and SpellCooldown(fists_of_fury) > 0 and BuffExpires(storm_earth_and_fire) or target.DebuffRemaining(touch_of_death) } or target.TimeToDie() < 8 Spell(concentrated_flame_essence)
  #reaping_flames
  Spell(reaping_flames)
 }
}

AddFunction WindwalkerCdMainPostConditions
{
 WindwalkerTodMainPostConditions()
}

AddFunction WindwalkerCdShortCdActions
{
 #worldvein_resonance,if=cooldown.touch_of_death.remains>58|cooldown.touch_of_death.remains<2|target.time_to_die<20
 #if SpellCooldown(touch_of_death) > 58 or SpellCooldown(touch_of_death) < 2 or target.TimeToDie() < 20 Spell(worldvein_resonance_essence)

 unless Spell(bag_of_tricks)
 {
  #call_action_list,name=tod
  WindwalkerTodShortCdActions()

  unless WindwalkerTodShortCdPostConditions()
  {
   #blood_of_the_enemy,if=dot.touch_of_death.remains|target.time_to_die<12
   if target.DebuffRemaining(touch_of_death) or target.TimeToDie() < 12 Spell(blood_of_the_enemy)

   unless { not target.DebuffRemaining(concentrated_flame_burn_debuff) and { SpellCooldown(concentrated_flame_essence) <= SpellCooldown(touch_of_death) and Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) > 0 and SpellCooldown(rising_sun_kick) > 0 and SpellCooldown(fists_of_fury) > 0 and BuffExpires(storm_earth_and_fire) or target.DebuffRemaining(touch_of_death) } or target.TimeToDie() < 8 } and Spell(concentrated_flame_essence)
   {
    #the_unbound_force
    #Spell(the_unbound_force)
    #purifying_blast
    #Spell(purifying_blast)

    unless Spell(reaping_flames)
    {
     #focused_azerite_beam
     #Spell(focused_azerite_beam)
     #serenity,if=cooldown.rising_sun_kick.remains<=2|target.time_to_die<=12
     #if SpellCooldown(rising_sun_kick) <= 2 or target.TimeToDie() <= 12 Spell(serenity)
     #ripple_in_space
     #Spell(ripple_in_space_essence)
    }
   }
  }
 }
}

AddFunction WindwalkerCdShortCdPostConditions
{
 Spell(bag_of_tricks) or WindwalkerTodShortCdPostConditions() or { not target.DebuffRemaining(concentrated_flame_burn_debuff) and { SpellCooldown(concentrated_flame_essence) <= SpellCooldown(touch_of_death) and Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) > 0 and SpellCooldown(rising_sun_kick) > 0 and SpellCooldown(fists_of_fury) > 0 and BuffExpires(storm_earth_and_fire) or target.DebuffRemaining(touch_of_death) } or target.TimeToDie() < 8 } and Spell(concentrated_flame_essence) or Spell(reaping_flames)
}

AddFunction WindwalkerCdCdActions
{
 #invoke_xuen_the_white_tiger
 Spell(invoke_xuen_the_white_tiger)
 #guardian_of_azeroth,if=target.time_to_die>185|(!equipped.dribbling_inkpod|equipped.cyclotronic_blast|target.health.pct<30)&cooldown.touch_of_death.remains<=14|equipped.dribbling_inkpod&target.time_to_pct_30.remains<20|target.time_to_die<35
 if target.TimeToDie() > 185 or { not HasEquippedItem(dribbling_inkpod_item) or HasEquippedItem(cyclotronic_blast_item) or target.HealthPercent() < 30 } and SpellCooldown(touch_of_death) <= 14 or HasEquippedItem(dribbling_inkpod_item) and target.TimeToHealthPercent(30) < 20 or target.TimeToDie() < 35 Spell(guardian_of_azeroth)

 unless { SpellCooldown(touch_of_death) > 58 or SpellCooldown(touch_of_death) < 2 or target.TimeToDie() < 20 } and Spell(worldvein_resonance_essence)
 {
  #blood_fury
  Spell(blood_fury_apsp)
  #arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
  if MaxChi() - Chi() >= 1 and TimeToMaxEnergy() >= 0.5 Spell(arcane_torrent_chi)
  #lights_judgment
  Spell(lights_judgment)

  unless Spell(bag_of_tricks)
  {
   #call_action_list,name=tod
   WindwalkerTodCdActions()

   unless WindwalkerTodCdPostConditions()
   {
    #storm_earth_and_fire,,if=cooldown.storm_earth_and_fire.charges=2|(!essence.worldvein_resonance.major|(buff.worldvein_resonance.up|cooldown.worldvein_resonance.remains>cooldown.storm_earth_and_fire.full_recharge_time))&(cooldown.touch_of_death.remains>cooldown.storm_earth_and_fire.full_recharge_time|cooldown.touch_of_death.remains>target.time_to_die)&cooldown.fists_of_fury.remains<=9&chi>=3&cooldown.whirling_dragon_punch.remains<=13|dot.touch_of_death.remains|target.time_to_die<20
    if { SpellCharges(storm_earth_and_fire) == 2 or { not AzeriteEssenceIsMajor(worldvein_resonance_essence_id) or BuffPresent(worldvein_resonance_essence) or SpellCooldown(worldvein_resonance_essence) > SpellCooldown(storm_earth_and_fire) } and { SpellCooldown(touch_of_death) > SpellCooldown(storm_earth_and_fire) or SpellCooldown(touch_of_death) > target.TimeToDie() } and SpellCooldown(fists_of_fury) <= 9 and Chi() >= 3 and SpellCooldown(whirling_dragon_punch) <= 13 or target.DebuffRemaining(touch_of_death) or target.TimeToDie() < 20 } and CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff) Spell(storm_earth_and_fire)
    #use_items,if=equipped.cyclotronic_blast&cooldown.cyclotronic_blast.remains>=20|!equipped.cyclotronic_blast
    if HasEquippedItem(cyclotronic_blast_item) and SpellCooldown(cyclotronic_blast) >= 20 or not HasEquippedItem(cyclotronic_blast_item) WindwalkerUseItemActions()
    #ancestral_call,if=dot.touch_of_death.remains|target.time_to_die<16
    if target.DebuffRemaining(touch_of_death) or target.TimeToDie() < 16 Spell(ancestral_call)
    #fireblood,if=dot.touch_of_death.remains|target.time_to_die<9
    if target.DebuffRemaining(touch_of_death) or target.TimeToDie() < 9 Spell(fireblood)

    unless { not target.DebuffRemaining(concentrated_flame_burn_debuff) and { SpellCooldown(concentrated_flame_essence) <= SpellCooldown(touch_of_death) and Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) > 0 and SpellCooldown(rising_sun_kick) > 0 and SpellCooldown(fists_of_fury) > 0 and BuffExpires(storm_earth_and_fire) or target.DebuffRemaining(touch_of_death) } or target.TimeToDie() < 8 } and Spell(concentrated_flame_essence)
    {
     #berserking,if=target.time_to_die>183|dot.touch_of_death.remains|target.time_to_die<13
     if target.TimeToDie() > 183 or target.DebuffRemaining(touch_of_death) or target.TimeToDie() < 13 Spell(berserking)
     #use_item,name=pocketsized_computation_device,if=dot.touch_of_death.remains
     if target.DebuffRemaining(touch_of_death) WindwalkerUseItemActions()
     #use_item,name=ashvanes_razor_coral,if=variable.coral_double_tod_on_use&cooldown.touch_of_death.remains>=23&(debuff.razor_coral_debuff.down|buff.storm_earth_and_fire.remains>13|target.time_to_die-cooldown.touch_of_death.remains<40&cooldown.touch_of_death.remains<23|target.time_to_die<25)
     if coral_double_tod_on_use() and SpellCooldown(touch_of_death) >= 23 and { target.DebuffExpires(razor_coral_debuff) or BuffRemaining(storm_earth_and_fire) > 13 or target.TimeToDie() - SpellCooldown(touch_of_death) < 40 and SpellCooldown(touch_of_death) < 23 or target.TimeToDie() < 25 } WindwalkerUseItemActions()
     #use_item,name=ashvanes_razor_coral,if=!variable.coral_double_tod_on_use&(debuff.razor_coral_debuff.down|(!equipped.dribbling_inkpod|target.time_to_pct_30.remains<8)&(dot.touch_of_death.remains|cooldown.touch_of_death.remains+9>target.time_to_die&buff.storm_earth_and_fire.up|target.time_to_die<25))
     if not coral_double_tod_on_use() and { target.DebuffExpires(razor_coral_debuff) or { not HasEquippedItem(dribbling_inkpod_item) or target.TimeToHealthPercent(30) < 8 } and { target.DebuffRemaining(touch_of_death) or SpellCooldown(touch_of_death) + 9 > target.TimeToDie() and BuffPresent(storm_earth_and_fire) or target.TimeToDie() < 25 } } WindwalkerUseItemActions()

     unless Spell(the_unbound_force) or Spell(purifying_blast) or Spell(reaping_flames) or Spell(focused_azerite_beam) or { SpellCooldown(rising_sun_kick) <= 2 or target.TimeToDie() <= 12 } and Spell(serenity)
     {
      #memory_of_lucid_dreams,if=energy<40&buff.storm_earth_and_fire.up
      if Energy() < 40 and BuffPresent(storm_earth_and_fire) Spell(memory_of_lucid_dreams_essence)
     }
    }
   }
  }
 }
}

AddFunction WindwalkerCdCdPostConditions
{
 { SpellCooldown(touch_of_death) > 58 or SpellCooldown(touch_of_death) < 2 or target.TimeToDie() < 20 } and Spell(worldvein_resonance_essence) or Spell(bag_of_tricks) or WindwalkerTodCdPostConditions() or { not target.DebuffRemaining(concentrated_flame_burn_debuff) and { SpellCooldown(concentrated_flame_essence) <= SpellCooldown(touch_of_death) and Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) > 0 and SpellCooldown(rising_sun_kick) > 0 and SpellCooldown(fists_of_fury) > 0 and BuffExpires(storm_earth_and_fire) or target.DebuffRemaining(touch_of_death) } or target.TimeToDie() < 8 } and Spell(concentrated_flame_essence) or Spell(the_unbound_force) or Spell(purifying_blast) or Spell(reaping_flames) or Spell(focused_azerite_beam) or { SpellCooldown(rising_sun_kick) <= 2 or target.TimeToDie() <= 12 } and Spell(serenity) or Spell(ripple_in_space_essence)
}

### actions.precombat

AddFunction WindwalkerPrecombatMainActions
{
 #variable,name=coral_double_tod_on_use,op=set,value=equipped.ashvanes_razor_coral&(equipped.cyclotronic_blast|equipped.lustrous_golden_plumage|equipped.gladiators_badge|equipped.gladiators_medallion|equipped.remote_guidance_device)
 #chi_burst,if=(!talent.serenity.enabled|!talent.fist_of_the_white_tiger.enabled)
 if { not Talent(serenity_talent) or not Talent(fist_of_the_white_tiger_talent) } and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #chi_wave,if=talent.fist_of_the_white_tiger.enabled
 if Talent(fist_of_the_white_tiger_talent) Spell(chi_wave)
}

AddFunction WindwalkerPrecombatMainPostConditions
{
}

AddFunction WindwalkerPrecombatShortCdActions
{
}

AddFunction WindwalkerPrecombatShortCdPostConditions
{
 { not Talent(serenity_talent) or not Talent(fist_of_the_white_tiger_talent) } and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Talent(fist_of_the_white_tiger_talent) and Spell(chi_wave)
}

AddFunction WindwalkerPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)

 unless { not Talent(serenity_talent) or not Talent(fist_of_the_white_tiger_talent) } and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Talent(fist_of_the_white_tiger_talent) and Spell(chi_wave)
 {
  #invoke_xuen_the_white_tiger
  Spell(invoke_xuen_the_white_tiger)
  #guardian_of_azeroth
  Spell(guardian_of_azeroth)
 }
}

AddFunction WindwalkerPrecombatCdPostConditions
{
 { not Talent(serenity_talent) or not Talent(fist_of_the_white_tiger_talent) } and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Talent(fist_of_the_white_tiger_talent) and Spell(chi_wave)
}

### actions.serenity

AddFunction WindwalkerSerenityMainActions
{
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies<3|prev_gcd.1.spinning_crane_kick
 if Enemies(tagged=1) < 3 or PreviousGCDSpell(spinning_crane_kick) Spell(rising_sun_kick)
 #fists_of_fury,if=(buff.bloodlust.up&prev_gcd.1.rising_sun_kick)|buff.serenity.remains<1|(active_enemies>1&active_enemies<5)
 if BuffPresent(bloodlust) and PreviousGCDSpell(rising_sun_kick) or BuffRemaining(serenity) < 1 or Enemies(tagged=1) > 1 and Enemies(tagged=1) < 5 Spell(fists_of_fury)
 #fist_of_the_white_tiger,if=talent.hit_combo.enabled&energy.time_to_max<2&prev_gcd.1.blackout_kick&chi<=2
 if Talent(hit_combo_talent) and TimeToMaxEnergy() < 2 and PreviousGCDSpell(blackout_kick_windwalker) and Chi() <= 2 Spell(fist_of_the_white_tiger)
 #tiger_palm,if=talent.hit_combo.enabled&energy.time_to_max<1&prev_gcd.1.blackout_kick&chi.max-chi>=2
 if Talent(hit_combo_talent) and TimeToMaxEnergy() < 1 and PreviousGCDSpell(blackout_kick_windwalker) and MaxChi() - Chi() >= 2 Spell(tiger_palm)
 #spinning_crane_kick,if=combo_strike&(active_enemies>=3|(talent.hit_combo.enabled&prev_gcd.1.blackout_kick)|(active_enemies=2&prev_gcd.1.blackout_kick))
 if FIXME_combo_strike and { Enemies(tagged=1) >= 3 or Talent(hit_combo_talent) and PreviousGCDSpell(blackout_kick_windwalker) or Enemies(tagged=1) == 2 and PreviousGCDSpell(blackout_kick_windwalker) } Spell(spinning_crane_kick)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains
 Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerSerenityMainPostConditions
{
}

AddFunction WindwalkerSerenityShortCdActions
{
}

AddFunction WindwalkerSerenityShortCdPostConditions
{
 { Enemies(tagged=1) < 3 or PreviousGCDSpell(spinning_crane_kick) } and Spell(rising_sun_kick) or { BuffPresent(bloodlust) and PreviousGCDSpell(rising_sun_kick) or BuffRemaining(serenity) < 1 or Enemies(tagged=1) > 1 and Enemies(tagged=1) < 5 } and Spell(fists_of_fury) or Talent(hit_combo_talent) and TimeToMaxEnergy() < 2 and PreviousGCDSpell(blackout_kick_windwalker) and Chi() <= 2 and Spell(fist_of_the_white_tiger) or Talent(hit_combo_talent) and TimeToMaxEnergy() < 1 and PreviousGCDSpell(blackout_kick_windwalker) and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or FIXME_combo_strike and { Enemies(tagged=1) >= 3 or Talent(hit_combo_talent) and PreviousGCDSpell(blackout_kick_windwalker) or Enemies(tagged=1) == 2 and PreviousGCDSpell(blackout_kick_windwalker) } and Spell(spinning_crane_kick) or Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerSerenityCdActions
{
}

AddFunction WindwalkerSerenityCdPostConditions
{
 { Enemies(tagged=1) < 3 or PreviousGCDSpell(spinning_crane_kick) } and Spell(rising_sun_kick) or { BuffPresent(bloodlust) and PreviousGCDSpell(rising_sun_kick) or BuffRemaining(serenity) < 1 or Enemies(tagged=1) > 1 and Enemies(tagged=1) < 5 } and Spell(fists_of_fury) or Talent(hit_combo_talent) and TimeToMaxEnergy() < 2 and PreviousGCDSpell(blackout_kick_windwalker) and Chi() <= 2 and Spell(fist_of_the_white_tiger) or Talent(hit_combo_talent) and TimeToMaxEnergy() < 1 and PreviousGCDSpell(blackout_kick_windwalker) and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or FIXME_combo_strike and { Enemies(tagged=1) >= 3 or Talent(hit_combo_talent) and PreviousGCDSpell(blackout_kick_windwalker) or Enemies(tagged=1) == 2 and PreviousGCDSpell(blackout_kick_windwalker) } and Spell(spinning_crane_kick) or Spell(blackout_kick_windwalker)
}

### actions.st

AddFunction WindwalkerStMainActions
{
 #whirling_dragon_punch
 if SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 Spell(whirling_dragon_punch)
 #fists_of_fury,if=energy.time_to_max>3
 if TimeToMaxEnergy() > 3 Spell(fists_of_fury)
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=chi>=5
 if Chi() >= 5 Spell(rising_sun_kick)
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains
 Spell(rising_sun_kick)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down&active_enemies>1
 if BuffExpires(rushing_jade_wind_windwalker_buff) and Enemies(tagged=1) > 1 Spell(rushing_jade_wind)
 #fist_of_the_white_tiger,if=chi<=2
 if Chi() <= 2 Spell(fist_of_the_white_tiger)
 #energizing_elixir,if=chi<=3&energy<50
 if Chi() <= 3 and Energy() < 50 Spell(energizing_elixir)
 #spinning_crane_kick,if=combo_strike&buff.dance_of_chiji.react
 if FIXME_combo_strike and BuffPresent(dance_of_chiji_buff) Spell(spinning_crane_kick)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&(cooldown.rising_sun_kick.remains>3|chi>=3)&(cooldown.fists_of_fury.remains>4|chi>=4|(chi=2&prev_gcd.1.tiger_palm))
 if FIXME_combo_strike and { SpellCooldown(rising_sun_kick) > 3 or Chi() >= 3 } and { SpellCooldown(fists_of_fury) > 4 or Chi() >= 4 or Chi() == 2 and PreviousGCDSpell(tiger_palm) } Spell(blackout_kick_windwalker)
 #chi_wave
 Spell(chi_wave)
 #chi_burst,if=chi.max-chi>=1&active_enemies=1|chi.max-chi>=2
 if { MaxChi() - Chi() >= 1 and Enemies(tagged=1) == 1 or MaxChi() - Chi() >= 2 } and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&chi.max-chi>=2
 if FIXME_combo_strike and MaxChi() - Chi() >= 2 Spell(tiger_palm)
 #flying_serpent_kick,if=prev_gcd.1.blackout_kick&chi>3,interrupt=1
 if PreviousGCDSpell(blackout_kick_windwalker) and Chi() > 3 and CheckBoxOn(opt_flying_serpent_kick) Spell(flying_serpent_kick)
}

AddFunction WindwalkerStMainPostConditions
{
}

AddFunction WindwalkerStShortCdActions
{
 unless SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or Chi() >= 5 and Spell(rising_sun_kick) or Spell(rising_sun_kick) or BuffExpires(rushing_jade_wind_windwalker_buff) and Enemies(tagged=1) > 1 and Spell(rushing_jade_wind)
 {
  #reverse_harm,if=chi.max-chi>=2
  if MaxChi() - Chi() >= 2 Spell(reverse_harm)
 }
}

AddFunction WindwalkerStShortCdPostConditions
{
 SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or Chi() >= 5 and Spell(rising_sun_kick) or Spell(rising_sun_kick) or BuffExpires(rushing_jade_wind_windwalker_buff) and Enemies(tagged=1) > 1 and Spell(rushing_jade_wind) or Chi() <= 2 and Spell(fist_of_the_white_tiger) or Chi() <= 3 and Energy() < 50 and Spell(energizing_elixir) or FIXME_combo_strike and BuffPresent(dance_of_chiji_buff) and Spell(spinning_crane_kick) or FIXME_combo_strike and { SpellCooldown(rising_sun_kick) > 3 or Chi() >= 3 } and { SpellCooldown(fists_of_fury) > 4 or Chi() >= 4 or Chi() == 2 and PreviousGCDSpell(tiger_palm) } and Spell(blackout_kick_windwalker) or Spell(chi_wave) or { MaxChi() - Chi() >= 1 and Enemies(tagged=1) == 1 or MaxChi() - Chi() >= 2 } and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or FIXME_combo_strike and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or PreviousGCDSpell(blackout_kick_windwalker) and Chi() > 3 and CheckBoxOn(opt_flying_serpent_kick) and Spell(flying_serpent_kick)
}

AddFunction WindwalkerStCdActions
{
}

AddFunction WindwalkerStCdPostConditions
{
 SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or Chi() >= 5 and Spell(rising_sun_kick) or Spell(rising_sun_kick) or BuffExpires(rushing_jade_wind_windwalker_buff) and Enemies(tagged=1) > 1 and Spell(rushing_jade_wind) or Chi() <= 2 and Spell(fist_of_the_white_tiger) or Chi() <= 3 and Energy() < 50 and Spell(energizing_elixir) or FIXME_combo_strike and BuffPresent(dance_of_chiji_buff) and Spell(spinning_crane_kick) or FIXME_combo_strike and { SpellCooldown(rising_sun_kick) > 3 or Chi() >= 3 } and { SpellCooldown(fists_of_fury) > 4 or Chi() >= 4 or Chi() == 2 and PreviousGCDSpell(tiger_palm) } and Spell(blackout_kick_windwalker) or Spell(chi_wave) or { MaxChi() - Chi() >= 1 and Enemies(tagged=1) == 1 or MaxChi() - Chi() >= 2 } and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or FIXME_combo_strike and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or PreviousGCDSpell(blackout_kick_windwalker) and Chi() > 3 and CheckBoxOn(opt_flying_serpent_kick) and Spell(flying_serpent_kick)
}

### actions.tod

AddFunction WindwalkerTodMainActions
{
}

AddFunction WindwalkerTodMainPostConditions
{
}

AddFunction WindwalkerTodShortCdActions
{
}

AddFunction WindwalkerTodShortCdPostConditions
{
}

AddFunction WindwalkerTodCdActions
{
 #touch_of_death,if=equipped.cyclotronic_blast&target.time_to_die>9&cooldown.cyclotronic_blast.remains<=1
 if HasEquippedItem(cyclotronic_blast_item) and target.TimeToDie() > 9 and SpellCooldown(cyclotronic_blast) <= 1 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } Spell(touch_of_death)
 #touch_of_death,if=!equipped.cyclotronic_blast&equipped.dribbling_inkpod&target.time_to_die>9&(target.time_to_pct_30.remains>=130|target.time_to_pct_30.remains<8)
 if not HasEquippedItem(cyclotronic_blast_item) and HasEquippedItem(dribbling_inkpod_item) and target.TimeToDie() > 9 and { target.TimeToHealthPercent(30) >= 130 or target.TimeToHealthPercent(30) < 8 } and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } Spell(touch_of_death)
 #touch_of_death,if=!equipped.cyclotronic_blast&!equipped.dribbling_inkpod&target.time_to_die>9
 if not HasEquippedItem(cyclotronic_blast_item) and not HasEquippedItem(dribbling_inkpod_item) and target.TimeToDie() > 9 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } Spell(touch_of_death)
}

AddFunction WindwalkerTodCdPostConditions
{
}







]]

		OvaleScripts:RegisterScript("MONK", "windwalker", name, desc, code, "script")
	end
end
