local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_pr_monk_brewmaster"
    local desc = "[8.1] Simulationcraft: PR_Monk_Brewmaster"
    local code = [[
# Based on SimulationCraft profile "PR_Monk_Brewmaster".
#	class=monk
#	spec=brewmaster
#	talents=1030021

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=brewmaster)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=brewmaster)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=brewmaster)
AddCheckBox(opt_chi_burst SpellName(chi_burst) default specialization=brewmaster)

AddFunction BrewmasterInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(spear_hand_strike) and target.IsInterruptible() Spell(spear_hand_strike)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(leg_sweep)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(paralysis) and not target.Classification(worldboss) Spell(paralysis)
 }
}

AddFunction BrewmasterUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction BrewmasterGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.precombat

AddFunction BrewmasterPrecombatMainActions
{
 #chi_burst
 if CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #chi_wave
 Spell(chi_wave)
}

AddFunction BrewmasterPrecombatMainPostConditions
{
}

AddFunction BrewmasterPrecombatShortCdActions
{
}

AddFunction BrewmasterPrecombatShortCdPostConditions
{
 CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

AddFunction BrewmasterPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_agility usable=1)
}

AddFunction BrewmasterPrecombatCdPostConditions
{
 CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

### actions.default

AddFunction BrewmasterDefaultMainActions
{
 #keg_smash,if=spell_targets>=2
 if Enemies() >= 2 Spell(keg_smash)
 #tiger_palm,if=talent.rushing_jade_wind.enabled&buff.blackout_combo.up&buff.rushing_jade_wind.up
 if Talent(rushing_jade_wind_talent) and BuffPresent(blackout_combo_buff) and BuffPresent(rushing_jade_wind_buff) Spell(tiger_palm)
 #tiger_palm,if=(talent.invoke_niuzao_the_black_ox.enabled|talent.special_delivery.enabled)&buff.blackout_combo.up
 if { Talent(invoke_niuzao_the_black_ox_talent) or Talent(special_delivery_talent) } and BuffPresent(blackout_combo_buff) Spell(tiger_palm)
 #blackout_strike
 Spell(blackout_strike)
 #keg_smash
 Spell(keg_smash)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down
 if BuffExpires(rushing_jade_wind_buff) Spell(rushing_jade_wind)
 #breath_of_fire,if=buff.blackout_combo.down&(buff.bloodlust.down|(buff.bloodlust.up&&dot.breath_of_fire_dot.refreshable))
 if BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_debuff) } Spell(breath_of_fire)
 #chi_burst
 if CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #chi_wave
 Spell(chi_wave)
 #tiger_palm,if=!talent.blackout_combo.enabled&cooldown.keg_smash.remains>gcd&(energy+(energy.regen*(cooldown.keg_smash.remains+gcd)))>=65
 if not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 65 Spell(tiger_palm)
 #rushing_jade_wind
 Spell(rushing_jade_wind)
}

AddFunction BrewmasterDefaultMainPostConditions
{
}

AddFunction BrewmasterDefaultShortCdActions
{
 #auto_attack
 BrewmasterGetInMeleeRange()
 #ironskin_brew,if=buff.blackout_combo.down&incoming_damage_1999ms>(health.max*0.1+stagger.last_tick_damage_4)&buff.elusive_brawler.stack<2&!buff.ironskin_brew.up
 if BuffExpires(blackout_combo_buff) and IncomingDamage(1.999) > MaxHealth() * 0.1 + StaggerTick(4) and BuffStacks(elusive_brawler) < 2 and not BuffPresent(ironskin_brew_buff) Spell(ironskin_brew)
 #ironskin_brew,if=cooldown.brews.charges_fractional>1&cooldown.black_ox_brew.remains<3
 if SpellCharges(ironskin_brew count=0) > 1 and SpellCooldown(black_ox_brew) < 3 Spell(ironskin_brew)
 #purifying_brew,if=stagger.pct>(6*(3-(cooldown.brews.charges_fractional)))&(stagger.last_tick_damage_1>((0.02+0.001*(3-cooldown.brews.charges_fractional))*stagger.last_tick_damage_30))
 if StaggerRemaining() / MaxHealth() * 100 > 6 * { 3 - SpellCharges(ironskin_brew count=0) } and StaggerTick(1) > { 0.02 + 0.001 * { 3 - SpellCharges(ironskin_brew count=0) } } * StaggerTick(30) Spell(purifying_brew)
}

AddFunction BrewmasterDefaultShortCdPostConditions
{
 Enemies() >= 2 and Spell(keg_smash) or Talent(rushing_jade_wind_talent) and BuffPresent(blackout_combo_buff) and BuffPresent(rushing_jade_wind_buff) and Spell(tiger_palm) or { Talent(invoke_niuzao_the_black_ox_talent) or Talent(special_delivery_talent) } and BuffPresent(blackout_combo_buff) and Spell(tiger_palm) or Spell(blackout_strike) or Spell(keg_smash) or BuffExpires(rushing_jade_wind_buff) and Spell(rushing_jade_wind) or BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_debuff) } and Spell(breath_of_fire) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave) or not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 65 and Spell(tiger_palm) or Spell(rushing_jade_wind)
}

AddFunction BrewmasterDefaultCdActions
{
 BrewmasterInterruptActions()
 #gift_of_the_ox,if=health<health.max*0.65
 #dampen_harm,if=incoming_damage_1500ms&buff.fortifying_brew.down
 if IncomingDamage(1.5) > 0 and BuffExpires(fortifying_brew_buff) Spell(dampen_harm)
 #fortifying_brew,if=incoming_damage_1500ms&(buff.dampen_harm.down|buff.diffuse_magic.down)
 if IncomingDamage(1.5) > 0 and { BuffExpires(dampen_harm) or BuffExpires(diffuse_magic) } Spell(fortifying_brew)
 #use_item,name=lustrous_golden_plumage
 BrewmasterUseItemActions()
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_agility usable=1)
 #blood_fury
 Spell(blood_fury_apsp)
 #berserking
 Spell(berserking)
 #lights_judgment
 Spell(lights_judgment)
 #fireblood
 Spell(fireblood)
 #ancestral_call
 Spell(ancestral_call)
 #invoke_niuzao_the_black_ox,if=target.time_to_die>25
 if target.TimeToDie() > 25 Spell(invoke_niuzao_the_black_ox)

 unless BuffExpires(blackout_combo_buff) and IncomingDamage(1.999) > MaxHealth() * 0.1 + StaggerTick(4) and BuffStacks(elusive_brawler) < 2 and not BuffPresent(ironskin_brew_buff) and Spell(ironskin_brew) or SpellCharges(ironskin_brew count=0) > 1 and SpellCooldown(black_ox_brew) < 3 and Spell(ironskin_brew) or StaggerRemaining() / MaxHealth() * 100 > 6 * { 3 - SpellCharges(ironskin_brew count=0) } and StaggerTick(1) > { 0.02 + 0.001 * { 3 - SpellCharges(ironskin_brew count=0) } } * StaggerTick(30) and Spell(purifying_brew)
 {
  #black_ox_brew,if=cooldown.brews.charges_fractional<0.5
  if SpellCharges(ironskin_brew count=0) < 0.5 Spell(black_ox_brew)
  #black_ox_brew,if=(energy+(energy.regen*cooldown.keg_smash.remains))<40&buff.blackout_combo.down&cooldown.keg_smash.up
  if Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) < 40 and BuffExpires(blackout_combo_buff) and not SpellCooldown(keg_smash) > 0 Spell(black_ox_brew)

  unless Enemies() >= 2 and Spell(keg_smash) or Talent(rushing_jade_wind_talent) and BuffPresent(blackout_combo_buff) and BuffPresent(rushing_jade_wind_buff) and Spell(tiger_palm) or { Talent(invoke_niuzao_the_black_ox_talent) or Talent(special_delivery_talent) } and BuffPresent(blackout_combo_buff) and Spell(tiger_palm) or Spell(blackout_strike) or Spell(keg_smash) or BuffExpires(rushing_jade_wind_buff) and Spell(rushing_jade_wind) or BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_debuff) } and Spell(breath_of_fire) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave) or not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 65 and Spell(tiger_palm)
  {
   #arcane_torrent,if=energy<31
   if Energy() < 31 Spell(arcane_torrent_chi)
  }
 }
}

AddFunction BrewmasterDefaultCdPostConditions
{
 BuffExpires(blackout_combo_buff) and IncomingDamage(1.999) > MaxHealth() * 0.1 + StaggerTick(4) and BuffStacks(elusive_brawler) < 2 and not BuffPresent(ironskin_brew_buff) and Spell(ironskin_brew) or SpellCharges(ironskin_brew count=0) > 1 and SpellCooldown(black_ox_brew) < 3 and Spell(ironskin_brew) or StaggerRemaining() / MaxHealth() * 100 > 6 * { 3 - SpellCharges(ironskin_brew count=0) } and StaggerTick(1) > { 0.02 + 0.001 * { 3 - SpellCharges(ironskin_brew count=0) } } * StaggerTick(30) and Spell(purifying_brew) or Enemies() >= 2 and Spell(keg_smash) or Talent(rushing_jade_wind_talent) and BuffPresent(blackout_combo_buff) and BuffPresent(rushing_jade_wind_buff) and Spell(tiger_palm) or { Talent(invoke_niuzao_the_black_ox_talent) or Talent(special_delivery_talent) } and BuffPresent(blackout_combo_buff) and Spell(tiger_palm) or Spell(blackout_strike) or Spell(keg_smash) or BuffExpires(rushing_jade_wind_buff) and Spell(rushing_jade_wind) or BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_debuff) } and Spell(breath_of_fire) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave) or not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 65 and Spell(tiger_palm) or Spell(rushing_jade_wind)
}

### Brewmaster icons.

AddCheckBox(opt_monk_brewmaster_aoe L(AOE) default specialization=brewmaster)

AddIcon checkbox=!opt_monk_brewmaster_aoe enemies=1 help=shortcd specialization=brewmaster
{
 if not InCombat() BrewmasterPrecombatShortCdActions()
 unless not InCombat() and BrewmasterPrecombatShortCdPostConditions()
 {
  BrewmasterDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_monk_brewmaster_aoe help=shortcd specialization=brewmaster
{
 if not InCombat() BrewmasterPrecombatShortCdActions()
 unless not InCombat() and BrewmasterPrecombatShortCdPostConditions()
 {
  BrewmasterDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=brewmaster
{
 if not InCombat() BrewmasterPrecombatMainActions()
 unless not InCombat() and BrewmasterPrecombatMainPostConditions()
 {
  BrewmasterDefaultMainActions()
 }
}

AddIcon checkbox=opt_monk_brewmaster_aoe help=aoe specialization=brewmaster
{
 if not InCombat() BrewmasterPrecombatMainActions()
 unless not InCombat() and BrewmasterPrecombatMainPostConditions()
 {
  BrewmasterDefaultMainActions()
 }
}

AddIcon checkbox=!opt_monk_brewmaster_aoe enemies=1 help=cd specialization=brewmaster
{
 if not InCombat() BrewmasterPrecombatCdActions()
 unless not InCombat() and BrewmasterPrecombatCdPostConditions()
 {
  BrewmasterDefaultCdActions()
 }
}

AddIcon checkbox=opt_monk_brewmaster_aoe help=cd specialization=brewmaster
{
 if not InCombat() BrewmasterPrecombatCdActions()
 unless not InCombat() and BrewmasterPrecombatCdPostConditions()
 {
  BrewmasterDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# arcane_torrent_chi
# berserking
# black_ox_brew
# blackout_combo_buff
# blackout_combo_talent
# blackout_strike
# blood_fury_apsp
# breath_of_fire
# breath_of_fire_debuff
# chi_burst
# chi_wave
# dampen_harm
# diffuse_magic
# elusive_brawler
# fireblood
# fortifying_brew
# fortifying_brew_buff
# invoke_niuzao_the_black_ox
# invoke_niuzao_the_black_ox_talent
# ironskin_brew
# ironskin_brew_buff
# item_battle_potion_of_agility
# keg_smash
# leg_sweep
# lights_judgment
# paralysis
# purifying_brew
# quaking_palm
# rushing_jade_wind
# rushing_jade_wind_buff
# rushing_jade_wind_talent
# spear_hand_strike
# special_delivery_talent
# tiger_palm
# war_stomp
]]
    OvaleScripts:RegisterScript("MONK", "brewmaster", name, desc, code, "script")
end
do
    local name = "sc_pr_monk_windwalker"
    local desc = "[8.1] Simulationcraft: PR_Monk_Windwalker"
    local code = [[
# Based on SimulationCraft profile "PR_Monk_Windwalker".
#	class=monk
#	spec=windwalker
#	talents=2022032

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=windwalker)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=windwalker)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=windwalker)
AddCheckBox(opt_touch_of_death_on_elite_only L(touch_of_death_on_elite_only) default specialization=windwalker)
AddCheckBox(opt_flying_serpent_kick SpellName(flying_serpent_kick) default specialization=windwalker)
AddCheckBox(opt_touch_of_karma SpellName(touch_of_karma) specialization=windwalker)
AddCheckBox(opt_chi_burst SpellName(chi_burst) default specialization=windwalker)
AddCheckBox(opt_storm_earth_and_fire SpellName(storm_earth_and_fire) default specialization=windwalker)

AddFunction WindwalkerInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(spear_hand_strike) and target.IsInterruptible() Spell(spear_hand_strike)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(leg_sweep)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(paralysis) and not target.Classification(worldboss) Spell(paralysis)
 }
}

AddFunction WindwalkerUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction WindwalkerGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.st

AddFunction WindwalkerStMainActions
{
 #whirling_dragon_punch
 if SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 Spell(whirling_dragon_punch)
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=chi>=5
 if Chi() >= 5 Spell(rising_sun_kick)
 #fists_of_fury,if=energy.time_to_max>3
 if TimeToMaxEnergy() > 3 Spell(fists_of_fury)
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains
 Spell(rising_sun_kick)
 #spinning_crane_kick,if=!prev_gcd.1.spinning_crane_kick&buff.dance_of_chiji.up
 if not PreviousGCDSpell(spinning_crane_kick) and BuffPresent(dance_of_chiji_buff) Spell(spinning_crane_kick)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down&active_enemies>1
 if BuffExpires(rushing_jade_wind_windwalker_buff) and Enemies() > 1 Spell(rushing_jade_wind)
 #fist_of_the_white_tiger,if=chi<=2
 if Chi() <= 2 Spell(fist_of_the_white_tiger)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&(cooldown.rising_sun_kick.remains>3|chi>=3)&(cooldown.fists_of_fury.remains>4|chi>=4|(chi=2&prev_gcd.1.tiger_palm))&buff.swift_roundhouse.stack<2
 if not PreviousGCDSpell(blackout_kick_windwalker) and { SpellCooldown(rising_sun_kick) > 3 or Chi() >= 3 } and { SpellCooldown(fists_of_fury) > 4 or Chi() >= 4 or Chi() == 2 and PreviousGCDSpell(tiger_palm) } and BuffStacks(swift_roundhouse_buff) < 2 Spell(blackout_kick_windwalker)
 #chi_wave
 Spell(chi_wave)
 #chi_burst,if=chi.max-chi>=1&active_enemies=1|chi.max-chi>=2
 if { MaxChi() - Chi() >= 1 and Enemies() == 1 or MaxChi() - Chi() >= 2 } and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&chi.max-chi>=2
 if not PreviousGCDSpell(tiger_palm) and MaxChi() - Chi() >= 2 Spell(tiger_palm)
 #flying_serpent_kick,if=prev_gcd.1.blackout_kick&chi>3&buff.swift_roundhouse.stack<2,interrupt=1
 if PreviousGCDSpell(blackout_kick_windwalker) and Chi() > 3 and BuffStacks(swift_roundhouse_buff) < 2 and CheckBoxOn(opt_flying_serpent_kick) Spell(flying_serpent_kick)
}

AddFunction WindwalkerStMainPostConditions
{
}

AddFunction WindwalkerStShortCdActions
{
 unless SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or Chi() >= 5 and Spell(rising_sun_kick) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or Spell(rising_sun_kick) or not PreviousGCDSpell(spinning_crane_kick) and BuffPresent(dance_of_chiji_buff) and Spell(spinning_crane_kick) or BuffExpires(rushing_jade_wind_windwalker_buff) and Enemies() > 1 and Spell(rushing_jade_wind) or Chi() <= 2 and Spell(fist_of_the_white_tiger)
 {
  #energizing_elixir,if=chi<=3&energy<50
  if Chi() <= 3 and Energy() < 50 Spell(energizing_elixir)
 }
}

AddFunction WindwalkerStShortCdPostConditions
{
 SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or Chi() >= 5 and Spell(rising_sun_kick) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or Spell(rising_sun_kick) or not PreviousGCDSpell(spinning_crane_kick) and BuffPresent(dance_of_chiji_buff) and Spell(spinning_crane_kick) or BuffExpires(rushing_jade_wind_windwalker_buff) and Enemies() > 1 and Spell(rushing_jade_wind) or Chi() <= 2 and Spell(fist_of_the_white_tiger) or not PreviousGCDSpell(blackout_kick_windwalker) and { SpellCooldown(rising_sun_kick) > 3 or Chi() >= 3 } and { SpellCooldown(fists_of_fury) > 4 or Chi() >= 4 or Chi() == 2 and PreviousGCDSpell(tiger_palm) } and BuffStacks(swift_roundhouse_buff) < 2 and Spell(blackout_kick_windwalker) or Spell(chi_wave) or { MaxChi() - Chi() >= 1 and Enemies() == 1 or MaxChi() - Chi() >= 2 } and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or not PreviousGCDSpell(tiger_palm) and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or PreviousGCDSpell(blackout_kick_windwalker) and Chi() > 3 and BuffStacks(swift_roundhouse_buff) < 2 and CheckBoxOn(opt_flying_serpent_kick) and Spell(flying_serpent_kick)
}

AddFunction WindwalkerStCdActions
{
}

AddFunction WindwalkerStCdPostConditions
{
 SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or Chi() >= 5 and Spell(rising_sun_kick) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or Spell(rising_sun_kick) or not PreviousGCDSpell(spinning_crane_kick) and BuffPresent(dance_of_chiji_buff) and Spell(spinning_crane_kick) or BuffExpires(rushing_jade_wind_windwalker_buff) and Enemies() > 1 and Spell(rushing_jade_wind) or Chi() <= 2 and Spell(fist_of_the_white_tiger) or Chi() <= 3 and Energy() < 50 and Spell(energizing_elixir) or not PreviousGCDSpell(blackout_kick_windwalker) and { SpellCooldown(rising_sun_kick) > 3 or Chi() >= 3 } and { SpellCooldown(fists_of_fury) > 4 or Chi() >= 4 or Chi() == 2 and PreviousGCDSpell(tiger_palm) } and BuffStacks(swift_roundhouse_buff) < 2 and Spell(blackout_kick_windwalker) or Spell(chi_wave) or { MaxChi() - Chi() >= 1 and Enemies() == 1 or MaxChi() - Chi() >= 2 } and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or not PreviousGCDSpell(tiger_palm) and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or PreviousGCDSpell(blackout_kick_windwalker) and Chi() > 3 and BuffStacks(swift_roundhouse_buff) < 2 and CheckBoxOn(opt_flying_serpent_kick) and Spell(flying_serpent_kick)
}

### actions.serenity

AddFunction WindwalkerSerenityMainActions
{
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies<3|prev_gcd.1.spinning_crane_kick
 if Enemies() < 3 or PreviousGCDSpell(spinning_crane_kick) Spell(rising_sun_kick)
 #fists_of_fury,if=(buff.bloodlust.up&prev_gcd.1.rising_sun_kick)|buff.serenity.remains<1|(active_enemies>1&active_enemies<5)
 if BuffPresent(burst_haste_buff any=1) and PreviousGCDSpell(rising_sun_kick) or BuffRemaining(serenity) < 1 or Enemies() > 1 and Enemies() < 5 Spell(fists_of_fury)
 #spinning_crane_kick,if=!prev_gcd.1.spinning_crane_kick&(active_enemies>=3|(active_enemies=2&prev_gcd.1.blackout_kick))
 if not PreviousGCDSpell(spinning_crane_kick) and { Enemies() >= 3 or Enemies() == 2 and PreviousGCDSpell(blackout_kick_windwalker) } Spell(spinning_crane_kick)
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
 { Enemies() < 3 or PreviousGCDSpell(spinning_crane_kick) } and Spell(rising_sun_kick) or { BuffPresent(burst_haste_buff any=1) and PreviousGCDSpell(rising_sun_kick) or BuffRemaining(serenity) < 1 or Enemies() > 1 and Enemies() < 5 } and Spell(fists_of_fury) or not PreviousGCDSpell(spinning_crane_kick) and { Enemies() >= 3 or Enemies() == 2 and PreviousGCDSpell(blackout_kick_windwalker) } and Spell(spinning_crane_kick) or Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerSerenityCdActions
{
}

AddFunction WindwalkerSerenityCdPostConditions
{
 { Enemies() < 3 or PreviousGCDSpell(spinning_crane_kick) } and Spell(rising_sun_kick) or { BuffPresent(burst_haste_buff any=1) and PreviousGCDSpell(rising_sun_kick) or BuffRemaining(serenity) < 1 or Enemies() > 1 and Enemies() < 5 } and Spell(fists_of_fury) or not PreviousGCDSpell(spinning_crane_kick) and { Enemies() >= 3 or Enemies() == 2 and PreviousGCDSpell(blackout_kick_windwalker) } and Spell(spinning_crane_kick) or Spell(blackout_kick_windwalker)
}

### actions.precombat

AddFunction WindwalkerPrecombatMainActions
{
 #chi_burst,if=(!talent.serenity.enabled|!talent.fist_of_the_white_tiger.enabled)
 if { not Talent(serenity_talent) or not Talent(fist_of_the_white_tiger_talent) } and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #chi_wave
 Spell(chi_wave)
}

AddFunction WindwalkerPrecombatMainPostConditions
{
}

AddFunction WindwalkerPrecombatShortCdActions
{
}

AddFunction WindwalkerPrecombatShortCdPostConditions
{
 { not Talent(serenity_talent) or not Talent(fist_of_the_white_tiger_talent) } and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

AddFunction WindwalkerPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_bursting_blood usable=1)
}

AddFunction WindwalkerPrecombatCdPostConditions
{
 { not Talent(serenity_talent) or not Talent(fist_of_the_white_tiger_talent) } and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

### actions.cd

AddFunction WindwalkerCdMainActions
{
}

AddFunction WindwalkerCdMainPostConditions
{
}

AddFunction WindwalkerCdShortCdActions
{
 #serenity,if=cooldown.rising_sun_kick.remains<=2|target.time_to_die<=12
 if SpellCooldown(rising_sun_kick) <= 2 or target.TimeToDie() <= 12 Spell(serenity)
}

AddFunction WindwalkerCdShortCdPostConditions
{
}

AddFunction WindwalkerCdCdActions
{
 #invoke_xuen_the_white_tiger
 Spell(invoke_xuen_the_white_tiger)
 #use_item,name=lustrous_golden_plumage
 WindwalkerUseItemActions()
 #blood_fury
 Spell(blood_fury_apsp)
 #berserking
 Spell(berserking)
 #arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
 if MaxChi() - Chi() >= 1 and TimeToMaxEnergy() >= 0.5 Spell(arcane_torrent_chi)
 #lights_judgment
 Spell(lights_judgment)
 #fireblood
 Spell(fireblood)
 #ancestral_call
 Spell(ancestral_call)
 #touch_of_death,if=target.time_to_die>9
 if target.TimeToDie() > 9 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } Spell(touch_of_death)
 #storm_earth_and_fire,if=cooldown.storm_earth_and_fire.charges=2|(cooldown.fists_of_fury.remains<=6&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=15
 if { SpellCharges(storm_earth_and_fire) == 2 or SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 } and CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff) Spell(storm_earth_and_fire)
}

AddFunction WindwalkerCdCdPostConditions
{
 { SpellCooldown(rising_sun_kick) <= 2 or target.TimeToDie() <= 12 } and Spell(serenity)
}

### actions.aoe

AddFunction WindwalkerAoeMainActions
{
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(talent.whirling_dragon_punch.enabled&cooldown.whirling_dragon_punch.remains<5)&cooldown.fists_of_fury.remains>3
 if Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) < 5 and SpellCooldown(fists_of_fury) > 3 Spell(rising_sun_kick)
 #whirling_dragon_punch
 if SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 Spell(whirling_dragon_punch)
 #fists_of_fury,if=energy.time_to_max>3
 if TimeToMaxEnergy() > 3 Spell(fists_of_fury)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down
 if BuffExpires(rushing_jade_wind_windwalker_buff) Spell(rushing_jade_wind)
 #spinning_crane_kick,if=!prev_gcd.1.spinning_crane_kick&(((chi>3|cooldown.fists_of_fury.remains>6)&(chi>=5|cooldown.fists_of_fury.remains>2))|energy.time_to_max<=3)
 if not PreviousGCDSpell(spinning_crane_kick) and { { Chi() > 3 or SpellCooldown(fists_of_fury) > 6 } and { Chi() >= 5 or SpellCooldown(fists_of_fury) > 2 } or TimeToMaxEnergy() <= 3 } Spell(spinning_crane_kick)
 #chi_burst,if=chi<=3
 if Chi() <= 3 and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #fist_of_the_white_tiger,if=chi.max-chi>=3
 if MaxChi() - Chi() >= 3 Spell(fist_of_the_white_tiger)
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=chi.max-chi>=2&(!talent.hit_combo.enabled|!prev_gcd.1.tiger_palm)
 if MaxChi() - Chi() >= 2 and { not Talent(hit_combo_talent) or not PreviousGCDSpell(tiger_palm) } Spell(tiger_palm)
 #chi_wave
 Spell(chi_wave)
 #flying_serpent_kick,if=buff.bok_proc.down,interrupt=1
 if BuffExpires(blackout_kick_buff) and CheckBoxOn(opt_flying_serpent_kick) Spell(flying_serpent_kick)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&(buff.bok_proc.up|(talent.hit_combo.enabled&prev_gcd.1.tiger_palm&chi<4))
 if not PreviousGCDSpell(blackout_kick_windwalker) and { BuffPresent(blackout_kick_buff) or Talent(hit_combo_talent) and PreviousGCDSpell(tiger_palm) and Chi() < 4 } Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerAoeMainPostConditions
{
}

AddFunction WindwalkerAoeShortCdActions
{
 unless Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) < 5 and SpellCooldown(fists_of_fury) > 3 and Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch)
 {
  #energizing_elixir,if=!prev_gcd.1.tiger_palm&chi<=1&energy<50
  if not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and Energy() < 50 Spell(energizing_elixir)
 }
}

AddFunction WindwalkerAoeShortCdPostConditions
{
 Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) < 5 and SpellCooldown(fists_of_fury) > 3 and Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or BuffExpires(rushing_jade_wind_windwalker_buff) and Spell(rushing_jade_wind) or not PreviousGCDSpell(spinning_crane_kick) and { { Chi() > 3 or SpellCooldown(fists_of_fury) > 6 } and { Chi() >= 5 or SpellCooldown(fists_of_fury) > 2 } or TimeToMaxEnergy() <= 3 } and Spell(spinning_crane_kick) or Chi() <= 3 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or MaxChi() - Chi() >= 2 and { not Talent(hit_combo_talent) or not PreviousGCDSpell(tiger_palm) } and Spell(tiger_palm) or Spell(chi_wave) or BuffExpires(blackout_kick_buff) and CheckBoxOn(opt_flying_serpent_kick) and Spell(flying_serpent_kick) or not PreviousGCDSpell(blackout_kick_windwalker) and { BuffPresent(blackout_kick_buff) or Talent(hit_combo_talent) and PreviousGCDSpell(tiger_palm) and Chi() < 4 } and Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerAoeCdActions
{
}

AddFunction WindwalkerAoeCdPostConditions
{
 Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) < 5 and SpellCooldown(fists_of_fury) > 3 and Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and Energy() < 50 and Spell(energizing_elixir) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or BuffExpires(rushing_jade_wind_windwalker_buff) and Spell(rushing_jade_wind) or not PreviousGCDSpell(spinning_crane_kick) and { { Chi() > 3 or SpellCooldown(fists_of_fury) > 6 } and { Chi() >= 5 or SpellCooldown(fists_of_fury) > 2 } or TimeToMaxEnergy() <= 3 } and Spell(spinning_crane_kick) or Chi() <= 3 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or MaxChi() - Chi() >= 2 and { not Talent(hit_combo_talent) or not PreviousGCDSpell(tiger_palm) } and Spell(tiger_palm) or Spell(chi_wave) or BuffExpires(blackout_kick_buff) and CheckBoxOn(opt_flying_serpent_kick) and Spell(flying_serpent_kick) or not PreviousGCDSpell(blackout_kick_windwalker) and { BuffPresent(blackout_kick_buff) or Talent(hit_combo_talent) and PreviousGCDSpell(tiger_palm) and Chi() < 4 } and Spell(blackout_kick_windwalker)
}

### actions.default

AddFunction WindwalkerDefaultMainActions
{
 #call_action_list,name=serenity,if=buff.serenity.up
 if BuffPresent(serenity) WindwalkerSerenityMainActions()

 unless BuffPresent(serenity) and WindwalkerSerenityMainPostConditions()
 {
  #fist_of_the_white_tiger,if=(energy.time_to_max<1|(talent.serenity.enabled&cooldown.serenity.remains<2))&chi.max-chi>=3
  if { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 3 Spell(fist_of_the_white_tiger)
  #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=(energy.time_to_max<1|(talent.serenity.enabled&cooldown.serenity.remains<2))&chi.max-chi>=2&!prev_gcd.1.tiger_palm
  if { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 2 and not PreviousGCDSpell(tiger_palm) Spell(tiger_palm)
  #call_action_list,name=cd
  WindwalkerCdMainActions()

  unless WindwalkerCdMainPostConditions()
  {
   #call_action_list,name=st,if=active_enemies<3
   if Enemies() < 3 WindwalkerStMainActions()

   unless Enemies() < 3 and WindwalkerStMainPostConditions()
   {
    #call_action_list,name=aoe,if=active_enemies>=3
    if Enemies() >= 3 WindwalkerAoeMainActions()
   }
  }
 }
}

AddFunction WindwalkerDefaultMainPostConditions
{
 BuffPresent(serenity) and WindwalkerSerenityMainPostConditions() or WindwalkerCdMainPostConditions() or Enemies() < 3 and WindwalkerStMainPostConditions() or Enemies() >= 3 and WindwalkerAoeMainPostConditions()
}

AddFunction WindwalkerDefaultShortCdActions
{
 #auto_attack
 WindwalkerGetInMeleeRange()
 #touch_of_karma,interval=90,pct_health=0.5
 if CheckBoxOn(opt_touch_of_karma) Spell(touch_of_karma)
 #call_action_list,name=serenity,if=buff.serenity.up
 if BuffPresent(serenity) WindwalkerSerenityShortCdActions()

 unless BuffPresent(serenity) and WindwalkerSerenityShortCdPostConditions() or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 2 and not PreviousGCDSpell(tiger_palm) and Spell(tiger_palm)
 {
  #call_action_list,name=cd
  WindwalkerCdShortCdActions()

  unless WindwalkerCdShortCdPostConditions()
  {
   #call_action_list,name=st,if=active_enemies<3
   if Enemies() < 3 WindwalkerStShortCdActions()

   unless Enemies() < 3 and WindwalkerStShortCdPostConditions()
   {
    #call_action_list,name=aoe,if=active_enemies>=3
    if Enemies() >= 3 WindwalkerAoeShortCdActions()
   }
  }
 }
}

AddFunction WindwalkerDefaultShortCdPostConditions
{
 BuffPresent(serenity) and WindwalkerSerenityShortCdPostConditions() or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 2 and not PreviousGCDSpell(tiger_palm) and Spell(tiger_palm) or WindwalkerCdShortCdPostConditions() or Enemies() < 3 and WindwalkerStShortCdPostConditions() or Enemies() >= 3 and WindwalkerAoeShortCdPostConditions()
}

AddFunction WindwalkerDefaultCdActions
{
 #spear_hand_strike,if=target.debuff.casting.react
 if target.IsInterruptible() WindwalkerInterruptActions()

 unless CheckBoxOn(opt_touch_of_karma) and Spell(touch_of_karma)
 {
  #potion,if=buff.serenity.up|buff.storm_earth_and_fire.up|(!talent.serenity.enabled&trinket.proc.agility.react)|buff.bloodlust.react|target.time_to_die<=60
  if { BuffPresent(serenity) or BuffPresent(storm_earth_and_fire) or not Talent(serenity_talent) and BuffPresent(trinket_proc_agility_buff) or BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_bursting_blood usable=1)
  #call_action_list,name=serenity,if=buff.serenity.up
  if BuffPresent(serenity) WindwalkerSerenityCdActions()

  unless BuffPresent(serenity) and WindwalkerSerenityCdPostConditions() or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 2 and not PreviousGCDSpell(tiger_palm) and Spell(tiger_palm)
  {
   #call_action_list,name=cd
   WindwalkerCdCdActions()

   unless WindwalkerCdCdPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<3
    if Enemies() < 3 WindwalkerStCdActions()

    unless Enemies() < 3 and WindwalkerStCdPostConditions()
    {
     #call_action_list,name=aoe,if=active_enemies>=3
     if Enemies() >= 3 WindwalkerAoeCdActions()
    }
   }
  }
 }
}

AddFunction WindwalkerDefaultCdPostConditions
{
 CheckBoxOn(opt_touch_of_karma) and Spell(touch_of_karma) or BuffPresent(serenity) and WindwalkerSerenityCdPostConditions() or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 2 and not PreviousGCDSpell(tiger_palm) and Spell(tiger_palm) or WindwalkerCdCdPostConditions() or Enemies() < 3 and WindwalkerStCdPostConditions() or Enemies() >= 3 and WindwalkerAoeCdPostConditions()
}

### Windwalker icons.

AddCheckBox(opt_monk_windwalker_aoe L(AOE) default specialization=windwalker)

AddIcon checkbox=!opt_monk_windwalker_aoe enemies=1 help=shortcd specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatShortCdActions()
 unless not InCombat() and WindwalkerPrecombatShortCdPostConditions()
 {
  WindwalkerDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_monk_windwalker_aoe help=shortcd specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatShortCdActions()
 unless not InCombat() and WindwalkerPrecombatShortCdPostConditions()
 {
  WindwalkerDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatMainActions()
 unless not InCombat() and WindwalkerPrecombatMainPostConditions()
 {
  WindwalkerDefaultMainActions()
 }
}

AddIcon checkbox=opt_monk_windwalker_aoe help=aoe specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatMainActions()
 unless not InCombat() and WindwalkerPrecombatMainPostConditions()
 {
  WindwalkerDefaultMainActions()
 }
}

AddIcon checkbox=!opt_monk_windwalker_aoe enemies=1 help=cd specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatCdActions()
 unless not InCombat() and WindwalkerPrecombatCdPostConditions()
 {
  WindwalkerDefaultCdActions()
 }
}

AddIcon checkbox=opt_monk_windwalker_aoe help=cd specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatCdActions()
 unless not InCombat() and WindwalkerPrecombatCdPostConditions()
 {
  WindwalkerDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# arcane_torrent_chi
# berserking
# blackout_kick_buff
# blackout_kick_windwalker
# blood_fury_apsp
# chi_burst
# chi_wave
# dance_of_chiji_buff
# energizing_elixir
# fireblood
# fist_of_the_white_tiger
# fist_of_the_white_tiger_talent
# fists_of_fury
# flying_serpent_kick
# hidden_masters_forbidden_touch_buff
# hit_combo_talent
# invoke_xuen_the_white_tiger
# item_bursting_blood
# leg_sweep
# lights_judgment
# paralysis
# quaking_palm
# rising_sun_kick
# rushing_jade_wind
# rushing_jade_wind_windwalker_buff
# serenity
# serenity_talent
# spear_hand_strike
# spinning_crane_kick
# storm_earth_and_fire
# swift_roundhouse_buff
# tiger_palm
# touch_of_death
# touch_of_karma
# war_stomp
# whirling_dragon_punch
# whirling_dragon_punch_talent
]]
    OvaleScripts:RegisterScript("MONK", "windwalker", name, desc, code, "script")
end
do
    local name = "sc_pr_monk_windwalker_serenity"
    local desc = "[8.1] Simulationcraft: PR_Monk_Windwalker_Serenity"
    local code = [[
# Based on SimulationCraft profile "PR_Monk_Windwalker_Serenity".
#	class=monk
#	spec=windwalker
#	talents=2022033

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=windwalker)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=windwalker)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=windwalker)
AddCheckBox(opt_touch_of_death_on_elite_only L(touch_of_death_on_elite_only) default specialization=windwalker)
AddCheckBox(opt_flying_serpent_kick SpellName(flying_serpent_kick) default specialization=windwalker)
AddCheckBox(opt_touch_of_karma SpellName(touch_of_karma) specialization=windwalker)
AddCheckBox(opt_chi_burst SpellName(chi_burst) default specialization=windwalker)
AddCheckBox(opt_storm_earth_and_fire SpellName(storm_earth_and_fire) default specialization=windwalker)

AddFunction WindwalkerInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(spear_hand_strike) and target.IsInterruptible() Spell(spear_hand_strike)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(leg_sweep)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(paralysis) and not target.Classification(worldboss) Spell(paralysis)
 }
}

AddFunction WindwalkerUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction WindwalkerGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.st

AddFunction WindwalkerStMainActions
{
 #whirling_dragon_punch
 if SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 Spell(whirling_dragon_punch)
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=chi>=5
 if Chi() >= 5 Spell(rising_sun_kick)
 #fists_of_fury,if=energy.time_to_max>3
 if TimeToMaxEnergy() > 3 Spell(fists_of_fury)
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains
 Spell(rising_sun_kick)
 #spinning_crane_kick,if=!prev_gcd.1.spinning_crane_kick&buff.dance_of_chiji.up
 if not PreviousGCDSpell(spinning_crane_kick) and BuffPresent(dance_of_chiji_buff) Spell(spinning_crane_kick)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down&active_enemies>1
 if BuffExpires(rushing_jade_wind_windwalker_buff) and Enemies() > 1 Spell(rushing_jade_wind)
 #fist_of_the_white_tiger,if=chi<=2
 if Chi() <= 2 Spell(fist_of_the_white_tiger)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&(cooldown.rising_sun_kick.remains>3|chi>=3)&(cooldown.fists_of_fury.remains>4|chi>=4|(chi=2&prev_gcd.1.tiger_palm))&buff.swift_roundhouse.stack<2
 if not PreviousGCDSpell(blackout_kick_windwalker) and { SpellCooldown(rising_sun_kick) > 3 or Chi() >= 3 } and { SpellCooldown(fists_of_fury) > 4 or Chi() >= 4 or Chi() == 2 and PreviousGCDSpell(tiger_palm) } and BuffStacks(swift_roundhouse_buff) < 2 Spell(blackout_kick_windwalker)
 #chi_wave
 Spell(chi_wave)
 #chi_burst,if=chi.max-chi>=1&active_enemies=1|chi.max-chi>=2
 if { MaxChi() - Chi() >= 1 and Enemies() == 1 or MaxChi() - Chi() >= 2 } and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&chi.max-chi>=2
 if not PreviousGCDSpell(tiger_palm) and MaxChi() - Chi() >= 2 Spell(tiger_palm)
 #flying_serpent_kick,if=prev_gcd.1.blackout_kick&chi>3&buff.swift_roundhouse.stack<2,interrupt=1
 if PreviousGCDSpell(blackout_kick_windwalker) and Chi() > 3 and BuffStacks(swift_roundhouse_buff) < 2 and CheckBoxOn(opt_flying_serpent_kick) Spell(flying_serpent_kick)
}

AddFunction WindwalkerStMainPostConditions
{
}

AddFunction WindwalkerStShortCdActions
{
 unless SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or Chi() >= 5 and Spell(rising_sun_kick) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or Spell(rising_sun_kick) or not PreviousGCDSpell(spinning_crane_kick) and BuffPresent(dance_of_chiji_buff) and Spell(spinning_crane_kick) or BuffExpires(rushing_jade_wind_windwalker_buff) and Enemies() > 1 and Spell(rushing_jade_wind) or Chi() <= 2 and Spell(fist_of_the_white_tiger)
 {
  #energizing_elixir,if=chi<=3&energy<50
  if Chi() <= 3 and Energy() < 50 Spell(energizing_elixir)
 }
}

AddFunction WindwalkerStShortCdPostConditions
{
 SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or Chi() >= 5 and Spell(rising_sun_kick) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or Spell(rising_sun_kick) or not PreviousGCDSpell(spinning_crane_kick) and BuffPresent(dance_of_chiji_buff) and Spell(spinning_crane_kick) or BuffExpires(rushing_jade_wind_windwalker_buff) and Enemies() > 1 and Spell(rushing_jade_wind) or Chi() <= 2 and Spell(fist_of_the_white_tiger) or not PreviousGCDSpell(blackout_kick_windwalker) and { SpellCooldown(rising_sun_kick) > 3 or Chi() >= 3 } and { SpellCooldown(fists_of_fury) > 4 or Chi() >= 4 or Chi() == 2 and PreviousGCDSpell(tiger_palm) } and BuffStacks(swift_roundhouse_buff) < 2 and Spell(blackout_kick_windwalker) or Spell(chi_wave) or { MaxChi() - Chi() >= 1 and Enemies() == 1 or MaxChi() - Chi() >= 2 } and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or not PreviousGCDSpell(tiger_palm) and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or PreviousGCDSpell(blackout_kick_windwalker) and Chi() > 3 and BuffStacks(swift_roundhouse_buff) < 2 and CheckBoxOn(opt_flying_serpent_kick) and Spell(flying_serpent_kick)
}

AddFunction WindwalkerStCdActions
{
}

AddFunction WindwalkerStCdPostConditions
{
 SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or Chi() >= 5 and Spell(rising_sun_kick) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or Spell(rising_sun_kick) or not PreviousGCDSpell(spinning_crane_kick) and BuffPresent(dance_of_chiji_buff) and Spell(spinning_crane_kick) or BuffExpires(rushing_jade_wind_windwalker_buff) and Enemies() > 1 and Spell(rushing_jade_wind) or Chi() <= 2 and Spell(fist_of_the_white_tiger) or Chi() <= 3 and Energy() < 50 and Spell(energizing_elixir) or not PreviousGCDSpell(blackout_kick_windwalker) and { SpellCooldown(rising_sun_kick) > 3 or Chi() >= 3 } and { SpellCooldown(fists_of_fury) > 4 or Chi() >= 4 or Chi() == 2 and PreviousGCDSpell(tiger_palm) } and BuffStacks(swift_roundhouse_buff) < 2 and Spell(blackout_kick_windwalker) or Spell(chi_wave) or { MaxChi() - Chi() >= 1 and Enemies() == 1 or MaxChi() - Chi() >= 2 } and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or not PreviousGCDSpell(tiger_palm) and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or PreviousGCDSpell(blackout_kick_windwalker) and Chi() > 3 and BuffStacks(swift_roundhouse_buff) < 2 and CheckBoxOn(opt_flying_serpent_kick) and Spell(flying_serpent_kick)
}

### actions.serenity

AddFunction WindwalkerSerenityMainActions
{
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies<3|prev_gcd.1.spinning_crane_kick
 if Enemies() < 3 or PreviousGCDSpell(spinning_crane_kick) Spell(rising_sun_kick)
 #fists_of_fury,if=(buff.bloodlust.up&prev_gcd.1.rising_sun_kick)|buff.serenity.remains<1|(active_enemies>1&active_enemies<5)
 if BuffPresent(burst_haste_buff any=1) and PreviousGCDSpell(rising_sun_kick) or BuffRemaining(serenity) < 1 or Enemies() > 1 and Enemies() < 5 Spell(fists_of_fury)
 #spinning_crane_kick,if=!prev_gcd.1.spinning_crane_kick&(active_enemies>=3|(active_enemies=2&prev_gcd.1.blackout_kick))
 if not PreviousGCDSpell(spinning_crane_kick) and { Enemies() >= 3 or Enemies() == 2 and PreviousGCDSpell(blackout_kick_windwalker) } Spell(spinning_crane_kick)
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
 { Enemies() < 3 or PreviousGCDSpell(spinning_crane_kick) } and Spell(rising_sun_kick) or { BuffPresent(burst_haste_buff any=1) and PreviousGCDSpell(rising_sun_kick) or BuffRemaining(serenity) < 1 or Enemies() > 1 and Enemies() < 5 } and Spell(fists_of_fury) or not PreviousGCDSpell(spinning_crane_kick) and { Enemies() >= 3 or Enemies() == 2 and PreviousGCDSpell(blackout_kick_windwalker) } and Spell(spinning_crane_kick) or Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerSerenityCdActions
{
}

AddFunction WindwalkerSerenityCdPostConditions
{
 { Enemies() < 3 or PreviousGCDSpell(spinning_crane_kick) } and Spell(rising_sun_kick) or { BuffPresent(burst_haste_buff any=1) and PreviousGCDSpell(rising_sun_kick) or BuffRemaining(serenity) < 1 or Enemies() > 1 and Enemies() < 5 } and Spell(fists_of_fury) or not PreviousGCDSpell(spinning_crane_kick) and { Enemies() >= 3 or Enemies() == 2 and PreviousGCDSpell(blackout_kick_windwalker) } and Spell(spinning_crane_kick) or Spell(blackout_kick_windwalker)
}

### actions.precombat

AddFunction WindwalkerPrecombatMainActions
{
 #chi_burst,if=(!talent.serenity.enabled|!talent.fist_of_the_white_tiger.enabled)
 if { not Talent(serenity_talent) or not Talent(fist_of_the_white_tiger_talent) } and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #chi_wave
 Spell(chi_wave)
}

AddFunction WindwalkerPrecombatMainPostConditions
{
}

AddFunction WindwalkerPrecombatShortCdActions
{
}

AddFunction WindwalkerPrecombatShortCdPostConditions
{
 { not Talent(serenity_talent) or not Talent(fist_of_the_white_tiger_talent) } and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

AddFunction WindwalkerPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_bursting_blood usable=1)
}

AddFunction WindwalkerPrecombatCdPostConditions
{
 { not Talent(serenity_talent) or not Talent(fist_of_the_white_tiger_talent) } and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

### actions.cd

AddFunction WindwalkerCdMainActions
{
}

AddFunction WindwalkerCdMainPostConditions
{
}

AddFunction WindwalkerCdShortCdActions
{
 #serenity,if=cooldown.rising_sun_kick.remains<=2|target.time_to_die<=12
 if SpellCooldown(rising_sun_kick) <= 2 or target.TimeToDie() <= 12 Spell(serenity)
}

AddFunction WindwalkerCdShortCdPostConditions
{
}

AddFunction WindwalkerCdCdActions
{
 #invoke_xuen_the_white_tiger
 Spell(invoke_xuen_the_white_tiger)
 #use_item,name=lustrous_golden_plumage
 WindwalkerUseItemActions()
 #blood_fury
 Spell(blood_fury_apsp)
 #berserking
 Spell(berserking)
 #arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
 if MaxChi() - Chi() >= 1 and TimeToMaxEnergy() >= 0.5 Spell(arcane_torrent_chi)
 #lights_judgment
 Spell(lights_judgment)
 #fireblood
 Spell(fireblood)
 #ancestral_call
 Spell(ancestral_call)
 #touch_of_death,if=target.time_to_die>9
 if target.TimeToDie() > 9 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } Spell(touch_of_death)
 #storm_earth_and_fire,if=cooldown.storm_earth_and_fire.charges=2|(cooldown.fists_of_fury.remains<=6&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=15
 if { SpellCharges(storm_earth_and_fire) == 2 or SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 } and CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff) Spell(storm_earth_and_fire)
}

AddFunction WindwalkerCdCdPostConditions
{
 { SpellCooldown(rising_sun_kick) <= 2 or target.TimeToDie() <= 12 } and Spell(serenity)
}

### actions.aoe

AddFunction WindwalkerAoeMainActions
{
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(talent.whirling_dragon_punch.enabled&cooldown.whirling_dragon_punch.remains<5)&cooldown.fists_of_fury.remains>3
 if Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) < 5 and SpellCooldown(fists_of_fury) > 3 Spell(rising_sun_kick)
 #whirling_dragon_punch
 if SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 Spell(whirling_dragon_punch)
 #fists_of_fury,if=energy.time_to_max>3
 if TimeToMaxEnergy() > 3 Spell(fists_of_fury)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down
 if BuffExpires(rushing_jade_wind_windwalker_buff) Spell(rushing_jade_wind)
 #spinning_crane_kick,if=!prev_gcd.1.spinning_crane_kick&(((chi>3|cooldown.fists_of_fury.remains>6)&(chi>=5|cooldown.fists_of_fury.remains>2))|energy.time_to_max<=3)
 if not PreviousGCDSpell(spinning_crane_kick) and { { Chi() > 3 or SpellCooldown(fists_of_fury) > 6 } and { Chi() >= 5 or SpellCooldown(fists_of_fury) > 2 } or TimeToMaxEnergy() <= 3 } Spell(spinning_crane_kick)
 #chi_burst,if=chi<=3
 if Chi() <= 3 and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #fist_of_the_white_tiger,if=chi.max-chi>=3
 if MaxChi() - Chi() >= 3 Spell(fist_of_the_white_tiger)
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=chi.max-chi>=2&(!talent.hit_combo.enabled|!prev_gcd.1.tiger_palm)
 if MaxChi() - Chi() >= 2 and { not Talent(hit_combo_talent) or not PreviousGCDSpell(tiger_palm) } Spell(tiger_palm)
 #chi_wave
 Spell(chi_wave)
 #flying_serpent_kick,if=buff.bok_proc.down,interrupt=1
 if BuffExpires(blackout_kick_buff) and CheckBoxOn(opt_flying_serpent_kick) Spell(flying_serpent_kick)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&(buff.bok_proc.up|(talent.hit_combo.enabled&prev_gcd.1.tiger_palm&chi<4))
 if not PreviousGCDSpell(blackout_kick_windwalker) and { BuffPresent(blackout_kick_buff) or Talent(hit_combo_talent) and PreviousGCDSpell(tiger_palm) and Chi() < 4 } Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerAoeMainPostConditions
{
}

AddFunction WindwalkerAoeShortCdActions
{
 unless Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) < 5 and SpellCooldown(fists_of_fury) > 3 and Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch)
 {
  #energizing_elixir,if=!prev_gcd.1.tiger_palm&chi<=1&energy<50
  if not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and Energy() < 50 Spell(energizing_elixir)
 }
}

AddFunction WindwalkerAoeShortCdPostConditions
{
 Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) < 5 and SpellCooldown(fists_of_fury) > 3 and Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or BuffExpires(rushing_jade_wind_windwalker_buff) and Spell(rushing_jade_wind) or not PreviousGCDSpell(spinning_crane_kick) and { { Chi() > 3 or SpellCooldown(fists_of_fury) > 6 } and { Chi() >= 5 or SpellCooldown(fists_of_fury) > 2 } or TimeToMaxEnergy() <= 3 } and Spell(spinning_crane_kick) or Chi() <= 3 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or MaxChi() - Chi() >= 2 and { not Talent(hit_combo_talent) or not PreviousGCDSpell(tiger_palm) } and Spell(tiger_palm) or Spell(chi_wave) or BuffExpires(blackout_kick_buff) and CheckBoxOn(opt_flying_serpent_kick) and Spell(flying_serpent_kick) or not PreviousGCDSpell(blackout_kick_windwalker) and { BuffPresent(blackout_kick_buff) or Talent(hit_combo_talent) and PreviousGCDSpell(tiger_palm) and Chi() < 4 } and Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerAoeCdActions
{
}

AddFunction WindwalkerAoeCdPostConditions
{
 Talent(whirling_dragon_punch_talent) and SpellCooldown(whirling_dragon_punch) < 5 and SpellCooldown(fists_of_fury) > 3 and Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and Energy() < 50 and Spell(energizing_elixir) or TimeToMaxEnergy() > 3 and Spell(fists_of_fury) or BuffExpires(rushing_jade_wind_windwalker_buff) and Spell(rushing_jade_wind) or not PreviousGCDSpell(spinning_crane_kick) and { { Chi() > 3 or SpellCooldown(fists_of_fury) > 6 } and { Chi() >= 5 or SpellCooldown(fists_of_fury) > 2 } or TimeToMaxEnergy() <= 3 } and Spell(spinning_crane_kick) or Chi() <= 3 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or MaxChi() - Chi() >= 2 and { not Talent(hit_combo_talent) or not PreviousGCDSpell(tiger_palm) } and Spell(tiger_palm) or Spell(chi_wave) or BuffExpires(blackout_kick_buff) and CheckBoxOn(opt_flying_serpent_kick) and Spell(flying_serpent_kick) or not PreviousGCDSpell(blackout_kick_windwalker) and { BuffPresent(blackout_kick_buff) or Talent(hit_combo_talent) and PreviousGCDSpell(tiger_palm) and Chi() < 4 } and Spell(blackout_kick_windwalker)
}

### actions.default

AddFunction WindwalkerDefaultMainActions
{
 #call_action_list,name=serenity,if=buff.serenity.up
 if BuffPresent(serenity) WindwalkerSerenityMainActions()

 unless BuffPresent(serenity) and WindwalkerSerenityMainPostConditions()
 {
  #fist_of_the_white_tiger,if=(energy.time_to_max<1|(talent.serenity.enabled&cooldown.serenity.remains<2))&chi.max-chi>=3
  if { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 3 Spell(fist_of_the_white_tiger)
  #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=(energy.time_to_max<1|(talent.serenity.enabled&cooldown.serenity.remains<2))&chi.max-chi>=2&!prev_gcd.1.tiger_palm
  if { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 2 and not PreviousGCDSpell(tiger_palm) Spell(tiger_palm)
  #call_action_list,name=cd
  WindwalkerCdMainActions()

  unless WindwalkerCdMainPostConditions()
  {
   #call_action_list,name=st,if=active_enemies<3
   if Enemies() < 3 WindwalkerStMainActions()

   unless Enemies() < 3 and WindwalkerStMainPostConditions()
   {
    #call_action_list,name=aoe,if=active_enemies>=3
    if Enemies() >= 3 WindwalkerAoeMainActions()
   }
  }
 }
}

AddFunction WindwalkerDefaultMainPostConditions
{
 BuffPresent(serenity) and WindwalkerSerenityMainPostConditions() or WindwalkerCdMainPostConditions() or Enemies() < 3 and WindwalkerStMainPostConditions() or Enemies() >= 3 and WindwalkerAoeMainPostConditions()
}

AddFunction WindwalkerDefaultShortCdActions
{
 #auto_attack
 WindwalkerGetInMeleeRange()
 #touch_of_karma,interval=90,pct_health=0.5
 if CheckBoxOn(opt_touch_of_karma) Spell(touch_of_karma)
 #call_action_list,name=serenity,if=buff.serenity.up
 if BuffPresent(serenity) WindwalkerSerenityShortCdActions()

 unless BuffPresent(serenity) and WindwalkerSerenityShortCdPostConditions() or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 2 and not PreviousGCDSpell(tiger_palm) and Spell(tiger_palm)
 {
  #call_action_list,name=cd
  WindwalkerCdShortCdActions()

  unless WindwalkerCdShortCdPostConditions()
  {
   #call_action_list,name=st,if=active_enemies<3
   if Enemies() < 3 WindwalkerStShortCdActions()

   unless Enemies() < 3 and WindwalkerStShortCdPostConditions()
   {
    #call_action_list,name=aoe,if=active_enemies>=3
    if Enemies() >= 3 WindwalkerAoeShortCdActions()
   }
  }
 }
}

AddFunction WindwalkerDefaultShortCdPostConditions
{
 BuffPresent(serenity) and WindwalkerSerenityShortCdPostConditions() or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 2 and not PreviousGCDSpell(tiger_palm) and Spell(tiger_palm) or WindwalkerCdShortCdPostConditions() or Enemies() < 3 and WindwalkerStShortCdPostConditions() or Enemies() >= 3 and WindwalkerAoeShortCdPostConditions()
}

AddFunction WindwalkerDefaultCdActions
{
 #spear_hand_strike,if=target.debuff.casting.react
 if target.IsInterruptible() WindwalkerInterruptActions()

 unless CheckBoxOn(opt_touch_of_karma) and Spell(touch_of_karma)
 {
  #potion,if=buff.serenity.up|buff.storm_earth_and_fire.up|(!talent.serenity.enabled&trinket.proc.agility.react)|buff.bloodlust.react|target.time_to_die<=60
  if { BuffPresent(serenity) or BuffPresent(storm_earth_and_fire) or not Talent(serenity_talent) and BuffPresent(trinket_proc_agility_buff) or BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_bursting_blood usable=1)
  #call_action_list,name=serenity,if=buff.serenity.up
  if BuffPresent(serenity) WindwalkerSerenityCdActions()

  unless BuffPresent(serenity) and WindwalkerSerenityCdPostConditions() or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 2 and not PreviousGCDSpell(tiger_palm) and Spell(tiger_palm)
  {
   #call_action_list,name=cd
   WindwalkerCdCdActions()

   unless WindwalkerCdCdPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<3
    if Enemies() < 3 WindwalkerStCdActions()

    unless Enemies() < 3 and WindwalkerStCdPostConditions()
    {
     #call_action_list,name=aoe,if=active_enemies>=3
     if Enemies() >= 3 WindwalkerAoeCdActions()
    }
   }
  }
 }
}

AddFunction WindwalkerDefaultCdPostConditions
{
 CheckBoxOn(opt_touch_of_karma) and Spell(touch_of_karma) or BuffPresent(serenity) and WindwalkerSerenityCdPostConditions() or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 3 and Spell(fist_of_the_white_tiger) or { TimeToMaxEnergy() < 1 or Talent(serenity_talent) and SpellCooldown(serenity) < 2 } and MaxChi() - Chi() >= 2 and not PreviousGCDSpell(tiger_palm) and Spell(tiger_palm) or WindwalkerCdCdPostConditions() or Enemies() < 3 and WindwalkerStCdPostConditions() or Enemies() >= 3 and WindwalkerAoeCdPostConditions()
}

### Windwalker icons.

AddCheckBox(opt_monk_windwalker_aoe L(AOE) default specialization=windwalker)

AddIcon checkbox=!opt_monk_windwalker_aoe enemies=1 help=shortcd specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatShortCdActions()
 unless not InCombat() and WindwalkerPrecombatShortCdPostConditions()
 {
  WindwalkerDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_monk_windwalker_aoe help=shortcd specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatShortCdActions()
 unless not InCombat() and WindwalkerPrecombatShortCdPostConditions()
 {
  WindwalkerDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatMainActions()
 unless not InCombat() and WindwalkerPrecombatMainPostConditions()
 {
  WindwalkerDefaultMainActions()
 }
}

AddIcon checkbox=opt_monk_windwalker_aoe help=aoe specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatMainActions()
 unless not InCombat() and WindwalkerPrecombatMainPostConditions()
 {
  WindwalkerDefaultMainActions()
 }
}

AddIcon checkbox=!opt_monk_windwalker_aoe enemies=1 help=cd specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatCdActions()
 unless not InCombat() and WindwalkerPrecombatCdPostConditions()
 {
  WindwalkerDefaultCdActions()
 }
}

AddIcon checkbox=opt_monk_windwalker_aoe help=cd specialization=windwalker
{
 if not InCombat() WindwalkerPrecombatCdActions()
 unless not InCombat() and WindwalkerPrecombatCdPostConditions()
 {
  WindwalkerDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# arcane_torrent_chi
# berserking
# blackout_kick_buff
# blackout_kick_windwalker
# blood_fury_apsp
# chi_burst
# chi_wave
# dance_of_chiji_buff
# energizing_elixir
# fireblood
# fist_of_the_white_tiger
# fist_of_the_white_tiger_talent
# fists_of_fury
# flying_serpent_kick
# hidden_masters_forbidden_touch_buff
# hit_combo_talent
# invoke_xuen_the_white_tiger
# item_bursting_blood
# leg_sweep
# lights_judgment
# paralysis
# quaking_palm
# rising_sun_kick
# rushing_jade_wind
# rushing_jade_wind_windwalker_buff
# serenity
# serenity_talent
# spear_hand_strike
# spinning_crane_kick
# storm_earth_and_fire
# swift_roundhouse_buff
# tiger_palm
# touch_of_death
# touch_of_karma
# war_stomp
# whirling_dragon_punch
# whirling_dragon_punch_talent
]]
    OvaleScripts:RegisterScript("MONK", "windwalker", name, desc, code, "script")
end
