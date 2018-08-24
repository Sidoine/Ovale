local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "icyveins_monk_brewmaster"
    local desc = "[8.0.1] Icy-Veins: Monk Brewmaster"
    local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=brewmaster)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=brewmaster)
AddCheckBox(opt_monk_bm_aoe L(AOE) default specialization=brewmaster)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=brewmaster)

AddFunction BrewmasterHealMeShortCd
{
	unless(DebuffPresent(healing_immunity_debuff)) 
	{
		if (HealthPercent() < 35) 
		{
			Spell(healing_elixir)
			Spell(expel_harm)
		}
		if (HealthPercent() <= 100 - (15 * 2.6)) Spell(healing_elixir)
		if (HealthPercent() < 35) UseHealthPotions()
	}
}

AddFunction BrewmasterHealMeMain
{
	unless(DebuffPresent(healing_immunity_debuff)) 
	{
	}
}

AddFunction StaggerPercentage
{
	StaggerRemaining() / MaxHealth() * 100
}

AddFunction BrewmasterRangeCheck
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction BrewmasterDefaultShortCDActions
{
	# keep ISB up always when taking dmg
    if ((BaseDuration(light_stagger_debuff)-DebuffRemaining(any_stagger_debuff)<5 or target.IsTargetingPlayer()) and BuffExpires(ironskin_brew_buff 3) and BuffExpires(blackout_combo_buff)) Spell(ironskin_brew text=min)
	
	# keep stagger below 100% (or 30% when BOB is up)
	if (StaggerPercentage() >= 100 or (StaggerPercentage() >= 30 and Talent(black_ox_brew_talent) and SpellCooldown(black_ox_brew) <= 0)) Spell(purifying_brew)
	# use black_ox_brew when at 0 charges and low energy (or in an emergency)
    if (SpellCharges(ironskin_brew count=0) <= 0.75)
    {
        #black_ox_brew,if=incoming_damage_1500ms&stagger.heavy&cooldown.brews.charges_fractional<=0.75
        if IncomingDamage(1.5) > 0 and DebuffPresent(heavy_stagger_debuff) Spell(black_ox_brew)
        #black_ox_brew,if=(energy+(energy.regen*cooldown.keg_smash.remains))<40&buff.blackout_combo.down&cooldown.keg_smash.up
        if Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) < 40 and BuffExpires(blackout_combo_buff) and not SpellCooldown(keg_smash) > 0 Spell(black_ox_brew)
    }
	
	# heal me
	BrewmasterHealMeShortCd()
	# range check
	BrewmasterRangeCheck()

	unless StaggerPercentage() > 100
	{
		# purify heavy stagger when we have enough ISB
		if (StaggerPercentage() >= 60 and (BuffRemaining(ironskin_brew_buff) >= 2*BaseDuration(ironskin_brew_buff))) Spell(purifying_brew)

		# always bank 1 charge
		unless (SpellCharges(ironskin_brew) <= 1)
		{
            # keep ISB rolling
            if BuffRemaining(ironskin_brew_buff) < DebuffRemaining(any_stagger_debuff) and BuffExpires(blackout_combo_buff) Spell(ironskin_brew)
			
            # never be at (almost) max charges 
			unless (SpellFullRecharge(ironskin_brew) > 3)
			{
				if (BuffRemaining(ironskin_brew_buff) < 2*BaseDuration(ironskin_brew_buff) and BuffExpires(blackout_combo_buff)) Spell(ironskin_brew text=max)
				if (StaggerPercentage() > 30 or Talent(special_delivery_talent)) Spell(purifying_brew text=max)
			}
		}
	}
}

#
# Single-Target
#

AddFunction BrewmasterDefaultMainActions
{
    BrewmasterHealMeMain()
    if (not InCombat()) Spell(keg_smash)
        
	if Talent(blackout_combo_talent) BrewmasterBlackoutComboMainActions()
	unless Talent(blackout_combo_talent) 
	{
		Spell(keg_smash)
		Spell(blackout_strike)
		if (target.DebuffPresent(keg_smash_debuff)) Spell(breath_of_fire)
		if (BuffRefreshable(rushing_jade_wind_buff)) Spell(rushing_jade_wind)
		if (Energy() >= 65 or (Talent(black_ox_brew_talent) and SpellCooldown(black_ox_brew) <= 0)) Spell(tiger_palm)
		Spell(chi_burst)
		Spell(chi_wave)
		Spell(arcane_pulse)
	}
}

AddFunction BrewmasterBlackoutComboMainActions
{
	if(not BuffPresent(blackout_combo_buff) or (SpellCharges(ironskin_brew) <= 1) and BuffRemaining(ironskin_brew_buff) < BaseDuration(ironskin_brew)) Spell(keg_smash)
	if(not BuffPresent(blackout_combo_buff)) Spell(blackout_strike)
	if(BuffPresent(blackout_combo_buff)) Spell(tiger_palm)
	
	unless BuffPresent(blackout_combo_buff)
	{
		if target.DebuffPresent(keg_smash_debuff) Spell(breath_of_fire)
		if BuffRefreshable(rushing_jade_wind_buff) Spell(rushing_jade_wind)
		Spell(chi_burst)
		Spell(chi_wave)
		Spell(arcane_pulse)
	}
}

#
# AOE
#

AddFunction BrewmasterDefaultAoEActions
{
    BrewmasterHealMeMain()
    if (not InCombat()) Spell(keg_smash)
 
    if (Talent(blackout_combo_talent) and not BuffPresent(blackout_combo_buff)) Spell(blackout_strike)
	if (not Talent(blackout_combo_talent) or (BuffPresent(blackout_combo_buff) and SpellCharges(ironskin_brew) <= SpellData(ironskin_brew charges)-2) or SpellFullRecharge(keg_smash) == 0) Spell(keg_smash)
	Spell(chi_burst)
	Spell(chi_wave)
	if (target.DebuffPresent(keg_smash_debuff) and not BuffPresent(blackout_combo_buff)) Spell(breath_of_fire)
	if (BuffRefreshable(rushing_jade_wind_buff)) Spell(rushing_jade_wind)
    Spell(arcane_pulse)
	if (Energy() >= 65 or (Talent(black_ox_brew_talent) and SpellCooldown(black_ox_brew) <= 0)) Spell(tiger_palm)
	if (not BuffPresent(blackout_combo_buff)) Spell(blackout_strike)	
}

AddFunction BrewmasterDefaultCdActions 
{
	BrewmasterInterruptActions()
	Spell(guard)
	if not PetPresent(name=Niuzao) Spell(invoke_niuzao_the_black_ox)
	if (HasEquippedItem(firestone_walkers)) Spell(fortifying_brew)
	if (HasEquippedItem(shifting_cosmic_sliver)) Spell(fortifying_brew)
	if (HasEquippedItem(fundamental_observation)) Spell(zen_meditation text=FO)
	Item(Trinket0Slot usable=1 text=13)
	Item(Trinket1Slot usable=1 text=14)
	Spell(fortifying_brew)
	Spell(dampen_harm)
	if CheckBoxOn(opt_use_consumables) Item(unbending_potion usable=1)
	Spell(zen_meditation)
	UseRacialSurvivalActions()
}

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

AddIcon help=shortcd specialization=brewmaster
{
	BrewmasterDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=brewmaster
{
	BrewmasterDefaultMainActions()
}

AddIcon checkbox=opt_monk_bm_aoe help=aoe specialization=brewmaster
{
	BrewmasterDefaultAoEActions()
}

AddIcon help=cd specialization=brewmaster
{
	BrewmasterDefaultCdActions()
}
]]
    OvaleScripts:RegisterScript("MONK", "brewmaster", name, desc, code, "script")
end
do
    local name = "sc_pr_monk_brewmaster"
    local desc = "[8.0] Simulationcraft: PR_Monk_Brewmaster"
    local code = [[
# Based on SimulationCraft profile "PR_Monk_Brewmaster".
#	class=monk
#	spec=brewmaster
#	talents=2020033

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=brewmaster)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=brewmaster)
AddCheckBox(opt_chi_burst SpellName(chi_burst) default specialization=brewmaster)

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
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
}

AddFunction BrewmasterPrecombatCdPostConditions
{
 CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

### actions.default

AddFunction BrewmasterDefaultMainActions
{
 #ironskin_brew,if=buff.blackout_combo.down&incoming_damage_1999ms>(health.max*0.1+stagger.last_tick_damage_4)&buff.elusive_brawler.stack<2&!buff.ironskin_brew.up
 if BuffExpires(blackout_combo_buff) and IncomingDamage(1) > MaxHealth() * 0.1 + StaggerTick(4) and DebuffStacks(elusive_brawler) < 2 and not BuffPresent(ironskin_brew_buff) Spell(ironskin_brew)
 #ironskin_brew,if=cooldown.brews.charges_fractional>1&cooldown.black_ox_brew.remains<3
 if SpellCharges(ironskin_brew count=0) > 1 and SpellCooldown(black_ox_brew) < 3 Spell(ironskin_brew)
 #purifying_brew,if=stagger.pct>(6*(3-(cooldown.brews.charges_fractional)))&(stagger.last_tick_damage_1>((0.02+0.001*(3-cooldown.brews.charges_fractional))*stagger.last_tick_damage_30))
 if StaggerRemaining() / MaxHealth() * 100 > 6 * { 3 - SpellCharges(ironskin_brew count=0) } and StaggerTick(1) > { 0.2 + 0.001 * { 3 - SpellCharges(ironskin_brew count=0) } } * StaggerTick(30) Spell(purifying_brew)
 #keg_smash,if=spell_targets>=2
 if Enemies() >= 2 Spell(keg_smash)
 #tiger_palm,if=talent.rushing_jade_wind.enabled&buff.blackout_combo.up&buff.rushing_jade_wind.up
 if Talent(rushing_jade_wind_talent) and BuffPresent(blackout_combo_buff) and DebuffPresent(rushing_jade_wind) Spell(tiger_palm)
 #tiger_palm,if=(talent.invoke_niuzao_the_black_ox.enabled|talent.special_delivery.enabled)&buff.blackout_combo.up
 if { Talent(invoke_niuzao_the_black_ox_talent) or Talent(special_delivery_talent) } and BuffPresent(blackout_combo_buff) Spell(tiger_palm)
 #blackout_strike
 Spell(blackout_strike)
 #keg_smash
 Spell(keg_smash)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down
 if DebuffExpires(rushing_jade_wind) Spell(rushing_jade_wind)
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
}

AddFunction BrewmasterDefaultShortCdPostConditions
{
 BuffExpires(blackout_combo_buff) and IncomingDamage(1) > MaxHealth() * 0 + StaggerTick(4) and DebuffStacks(elusive_brawler) < 2 and not BuffPresent(ironskin_brew_buff) and Spell(ironskin_brew) or SpellCharges(ironskin_brew count=0) > 1 and SpellCooldown(black_ox_brew) < 3 and Spell(ironskin_brew) or StaggerRemaining() / MaxHealth() * 100 > 6 * { 3 - SpellCharges(ironskin_brew count=0) } and StaggerTick(1) > { 0 + 0 * { 3 - SpellCharges(ironskin_brew count=0) } } * StaggerTick(30) and Spell(purifying_brew) or Enemies() >= 2 and Spell(keg_smash) or Talent(rushing_jade_wind_talent) and BuffPresent(blackout_combo_buff) and DebuffPresent(rushing_jade_wind) and Spell(tiger_palm) or { Talent(invoke_niuzao_the_black_ox_talent) or Talent(special_delivery_talent) } and BuffPresent(blackout_combo_buff) and Spell(tiger_palm) or Spell(blackout_strike) or Spell(keg_smash) or DebuffExpires(rushing_jade_wind) and Spell(rushing_jade_wind) or BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_debuff) } and Spell(breath_of_fire) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave) or not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 65 and Spell(tiger_palm) or Spell(rushing_jade_wind)
}

AddFunction BrewmasterDefaultCdActions
{
 #gift_of_the_ox,if=health<health.max*0.65
 #dampen_harm,if=incoming_damage_1500ms&buff.fortifying_brew.down
 if IncomingDamage(1) > 0 and BuffExpires(fortifying_brew_buff) Spell(dampen_harm)
 #fortifying_brew,if=incoming_damage_1500ms&(buff.dampen_harm.down|buff.diffuse_magic.down)
 if IncomingDamage(1) > 0 and { DebuffExpires(dampen_harm) or DebuffExpires(diffuse_magic) } Spell(fortifying_brew)
 #use_item,name=lustrous_golden_plumage
 BrewmasterUseItemActions()
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
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

 unless BuffExpires(blackout_combo_buff) and IncomingDamage(1) > MaxHealth() * 0 + StaggerTick(4) and DebuffStacks(elusive_brawler) < 2 and not BuffPresent(ironskin_brew_buff) and Spell(ironskin_brew) or SpellCharges(ironskin_brew count=0) > 1 and SpellCooldown(black_ox_brew) < 3 and Spell(ironskin_brew) or StaggerRemaining() / MaxHealth() * 100 > 6 * { 3 - SpellCharges(ironskin_brew count=0) } and StaggerTick(1) > { 0 + 0 * { 3 - SpellCharges(ironskin_brew count=0) } } * StaggerTick(30) and Spell(purifying_brew)
 {
  #black_ox_brew,if=cooldown.brews.charges_fractional<0.5
  if SpellCharges(ironskin_brew count=0) < 0.5 Spell(black_ox_brew)
  #black_ox_brew,if=(energy+(energy.regen*cooldown.keg_smash.remains))<40&buff.blackout_combo.down&cooldown.keg_smash.up
  if Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) < 40 and BuffExpires(blackout_combo_buff) and not SpellCooldown(keg_smash) > 0 Spell(black_ox_brew)

  unless Enemies() >= 2 and Spell(keg_smash) or Talent(rushing_jade_wind_talent) and BuffPresent(blackout_combo_buff) and DebuffPresent(rushing_jade_wind) and Spell(tiger_palm) or { Talent(invoke_niuzao_the_black_ox_talent) or Talent(special_delivery_talent) } and BuffPresent(blackout_combo_buff) and Spell(tiger_palm) or Spell(blackout_strike) or Spell(keg_smash) or DebuffExpires(rushing_jade_wind) and Spell(rushing_jade_wind) or BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_debuff) } and Spell(breath_of_fire) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave) or not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 65 and Spell(tiger_palm)
  {
   #arcane_torrent,if=energy<31
   if Energy() < 31 Spell(arcane_torrent_chi)
  }
 }
}

AddFunction BrewmasterDefaultCdPostConditions
{
 BuffExpires(blackout_combo_buff) and IncomingDamage(1) > MaxHealth() * 0 + StaggerTick(4) and DebuffStacks(elusive_brawler) < 2 and not BuffPresent(ironskin_brew_buff) and Spell(ironskin_brew) or SpellCharges(ironskin_brew count=0) > 1 and SpellCooldown(black_ox_brew) < 3 and Spell(ironskin_brew) or StaggerRemaining() / MaxHealth() * 100 > 6 * { 3 - SpellCharges(ironskin_brew count=0) } and StaggerTick(1) > { 0 + 0 * { 3 - SpellCharges(ironskin_brew count=0) } } * StaggerTick(30) and Spell(purifying_brew) or Enemies() >= 2 and Spell(keg_smash) or Talent(rushing_jade_wind_talent) and BuffPresent(blackout_combo_buff) and DebuffPresent(rushing_jade_wind) and Spell(tiger_palm) or { Talent(invoke_niuzao_the_black_ox_talent) or Talent(special_delivery_talent) } and BuffPresent(blackout_combo_buff) and Spell(tiger_palm) or Spell(blackout_strike) or Spell(keg_smash) or DebuffExpires(rushing_jade_wind) and Spell(rushing_jade_wind) or BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_debuff) } and Spell(breath_of_fire) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave) or not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 65 and Spell(tiger_palm) or Spell(rushing_jade_wind)
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
# battle_potion_of_agility
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
# keg_smash
# lights_judgment
# purifying_brew
# rushing_jade_wind
# rushing_jade_wind_talent
# special_delivery_talent
# tiger_palm
]]
    OvaleScripts:RegisterScript("MONK", "brewmaster", name, desc, code, "script")
end
do
    local name = "sc_pr_monk_windwalker"
    local desc = "[8.0] Simulationcraft: PR_Monk_Windwalker"
    local code = [[
# Based on SimulationCraft profile "PR_Monk_Windwalker".
#	class=monk
#	spec=windwalker
#	talents=3022033

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=windwalker)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=windwalker)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=windwalker)
AddCheckBox(opt_touch_of_death_on_elite_only L(touch_of_death_on_elite_only) default specialization=windwalker)
AddCheckBox(opt_touch_of_karma SpellName(touch_of_karma) specialization=windwalker)
AddCheckBox(opt_chi_burst SpellName(chi_burst) default specialization=windwalker)
AddCheckBox(opt_storm_earth_and_fire SpellName(storm_earth_and_fire) specialization=windwalker)

AddFunction WindwalkerInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(paralysis) and not target.Classification(worldboss) Spell(paralysis)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(leg_sweep)
  if target.InRange(spear_hand_strike) and target.IsInterruptible() Spell(spear_hand_strike)
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
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=azerite.swift_roundhouse.enabled&buff.swift_roundhouse.stack=2
 if HasAzeriteTrait(swift_roundhouse_trait) and BuffStacks(swift_roundhouse_buff) == 2 Spell(rising_sun_kick)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down&!prev_gcd.1.rushing_jade_wind
 if DebuffExpires(rushing_jade_wind_windwalker) and not PreviousGCDSpell(rushing_jade_wind_windwalker) Spell(rushing_jade_wind_windwalker)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&chi.max-chi>=1&set_bonus.tier21_4pc&buff.bok_proc.up
 if not PreviousGCDSpell(blackout_kick_windwalker) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) Spell(blackout_kick_windwalker)
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=chi<=3&energy.time_to_max<2
 if Chi() <= 3 and TimeToMaxEnergy() < 2 Spell(tiger_palm)
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=chi.max-chi>=2&buff.serenity.down&cooldown.fist_of_the_white_tiger.remains>energy.time_to_max
 if MaxChi() - Chi() >= 2 and DebuffExpires(serenity) and SpellCooldown(fist_of_the_white_tiger) > TimeToMaxEnergy() Spell(tiger_palm)
 #whirling_dragon_punch
 if SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 Spell(whirling_dragon_punch)
 #fists_of_fury,if=chi>=3&energy.time_to_max>2.5&azerite.swift_roundhouse.rank<2
 if Chi() >= 3 and TimeToMaxEnergy() > 2 and AzeriteTraitRank(swift_roundhouse_trait) < 2 Spell(fists_of_fury)
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=((chi>=3&energy>=40)|chi>=5)&(talent.serenity.enabled|cooldown.serenity.remains>=6)&!azerite.swift_roundhouse.enabled
 if { Chi() >= 3 and Energy() >= 40 or Chi() >= 5 } and { Talent(serenity_talent) or SpellCooldown(serenity) >= 6 } and not HasAzeriteTrait(swift_roundhouse_trait) Spell(rising_sun_kick)
 #fists_of_fury,if=!talent.serenity.enabled&(azerite.swift_roundhouse.rank<2|cooldown.whirling_dragon_punch.remains<13)
 if not Talent(serenity_talent) and { AzeriteTraitRank(swift_roundhouse_trait) < 2 or SpellCooldown(whirling_dragon_punch) < 13 } Spell(fists_of_fury)
 #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=cooldown.serenity.remains>=5|(!talent.serenity.enabled)&!azerite.swift_roundhouse.enabled
 if SpellCooldown(serenity) >= 5 or not Talent(serenity_talent) and not HasAzeriteTrait(swift_roundhouse_trait) Spell(rising_sun_kick)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=cooldown.fists_of_fury.remains>2&!prev_gcd.1.blackout_kick&energy.time_to_max>1&azerite.swift_roundhouse.rank>1
 if SpellCooldown(fists_of_fury) > 2 and not PreviousGCDSpell(blackout_kick_windwalker) and TimeToMaxEnergy() > 1 and AzeriteTraitRank(swift_roundhouse_trait) > 1 Spell(blackout_kick_windwalker)
 #flying_serpent_kick,if=prev_gcd.1.blackout_kick&energy.time_to_max>2&chi>1,interrupt=1
 if PreviousGCDSpell(blackout_kick_windwalker) and TimeToMaxEnergy() > 2 and Chi() > 1 Spell(flying_serpent_kick)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.swift_roundhouse.stack<2&!prev_gcd.1.blackout_kick
 if BuffStacks(swift_roundhouse_buff) < 2 and not PreviousGCDSpell(blackout_kick_windwalker) Spell(blackout_kick_windwalker)
 #crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=19&energy.time_to_max>3
 if HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 Spell(crackling_jade_lightning)
 #crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=14&cooldown.serenity.remains<13&talent.serenity.enabled&energy.time_to_max>3
 if HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 Spell(crackling_jade_lightning)
 #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick
 if not PreviousGCDSpell(blackout_kick_windwalker) Spell(blackout_kick_windwalker)
 #chi_wave
 Spell(chi_wave)
 #chi_burst,if=energy.time_to_max>1&talent.serenity.enabled
 if TimeToMaxEnergy() > 1 and Talent(serenity_talent) and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&(chi.max-chi>=2|energy.time_to_max<3)&!buff.serenity.up
 if not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 3 } and not DebuffPresent(serenity) Spell(tiger_palm)
 #chi_burst,if=chi.max-chi>=3&energy.time_to_max>1&!talent.serenity.enabled
 if MaxChi() - Chi() >= 3 and TimeToMaxEnergy() > 1 and not Talent(serenity_talent) and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
}

AddFunction WindwalkerStMainPostConditions
{
}

AddFunction WindwalkerStShortCdActions
{
 unless HasAzeriteTrait(swift_roundhouse_trait) and BuffStacks(swift_roundhouse_buff) == 2 and Spell(rising_sun_kick) or DebuffExpires(rushing_jade_wind_windwalker) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and Spell(rushing_jade_wind_windwalker)
 {
  #energizing_elixir,if=!prev_gcd.1.tiger_palm
  if not PreviousGCDSpell(tiger_palm) Spell(energizing_elixir)

  unless not PreviousGCDSpell(blackout_kick_windwalker) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) and Spell(blackout_kick_windwalker)
  {
   #fist_of_the_white_tiger,if=(chi<=2)
   if Chi() <= 2 Spell(fist_of_the_white_tiger)
  }
 }
}

AddFunction WindwalkerStShortCdPostConditions
{
 HasAzeriteTrait(swift_roundhouse_trait) and BuffStacks(swift_roundhouse_buff) == 2 and Spell(rising_sun_kick) or DebuffExpires(rushing_jade_wind_windwalker) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and Spell(rushing_jade_wind_windwalker) or not PreviousGCDSpell(blackout_kick_windwalker) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) and Spell(blackout_kick_windwalker) or Chi() <= 3 and TimeToMaxEnergy() < 2 and Spell(tiger_palm) or MaxChi() - Chi() >= 2 and DebuffExpires(serenity) and SpellCooldown(fist_of_the_white_tiger) > TimeToMaxEnergy() and Spell(tiger_palm) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or Chi() >= 3 and TimeToMaxEnergy() > 2 and AzeriteTraitRank(swift_roundhouse_trait) < 2 and Spell(fists_of_fury) or { Chi() >= 3 and Energy() >= 40 or Chi() >= 5 } and { Talent(serenity_talent) or SpellCooldown(serenity) >= 6 } and not HasAzeriteTrait(swift_roundhouse_trait) and Spell(rising_sun_kick) or not Talent(serenity_talent) and { AzeriteTraitRank(swift_roundhouse_trait) < 2 or SpellCooldown(whirling_dragon_punch) < 13 } and Spell(fists_of_fury) or { SpellCooldown(serenity) >= 5 or not Talent(serenity_talent) and not HasAzeriteTrait(swift_roundhouse_trait) } and Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 2 and not PreviousGCDSpell(blackout_kick_windwalker) and TimeToMaxEnergy() > 1 and AzeriteTraitRank(swift_roundhouse_trait) > 1 and Spell(blackout_kick_windwalker) or PreviousGCDSpell(blackout_kick_windwalker) and TimeToMaxEnergy() > 2 and Chi() > 1 and Spell(flying_serpent_kick) or BuffStacks(swift_roundhouse_buff) < 2 and not PreviousGCDSpell(blackout_kick_windwalker) and Spell(blackout_kick_windwalker) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or not PreviousGCDSpell(blackout_kick_windwalker) and Spell(blackout_kick_windwalker) or Spell(chi_wave) or TimeToMaxEnergy() > 1 and Talent(serenity_talent) and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 3 } and not DebuffPresent(serenity) and Spell(tiger_palm) or MaxChi() - Chi() >= 3 and TimeToMaxEnergy() > 1 and not Talent(serenity_talent) and CheckBoxOn(opt_chi_burst) and Spell(chi_burst)
}

AddFunction WindwalkerStCdActions
{
 #invoke_xuen_the_white_tiger
 Spell(invoke_xuen_the_white_tiger)
 #touch_of_death
 if not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) Spell(touch_of_death)
 #storm_earth_and_fire,if=!buff.storm_earth_and_fire.up
 if not DebuffPresent(storm_earth_and_fire) and CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff) Spell(storm_earth_and_fire)
}

AddFunction WindwalkerStCdPostConditions
{
 HasAzeriteTrait(swift_roundhouse_trait) and BuffStacks(swift_roundhouse_buff) == 2 and Spell(rising_sun_kick) or DebuffExpires(rushing_jade_wind_windwalker) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and Spell(rushing_jade_wind_windwalker) or not PreviousGCDSpell(tiger_palm) and Spell(energizing_elixir) or not PreviousGCDSpell(blackout_kick_windwalker) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) and Spell(blackout_kick_windwalker) or Chi() <= 2 and Spell(fist_of_the_white_tiger) or Chi() <= 3 and TimeToMaxEnergy() < 2 and Spell(tiger_palm) or MaxChi() - Chi() >= 2 and DebuffExpires(serenity) and SpellCooldown(fist_of_the_white_tiger) > TimeToMaxEnergy() and Spell(tiger_palm) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or Chi() >= 3 and TimeToMaxEnergy() > 2 and AzeriteTraitRank(swift_roundhouse_trait) < 2 and Spell(fists_of_fury) or { Chi() >= 3 and Energy() >= 40 or Chi() >= 5 } and { Talent(serenity_talent) or SpellCooldown(serenity) >= 6 } and not HasAzeriteTrait(swift_roundhouse_trait) and Spell(rising_sun_kick) or not Talent(serenity_talent) and { AzeriteTraitRank(swift_roundhouse_trait) < 2 or SpellCooldown(whirling_dragon_punch) < 13 } and Spell(fists_of_fury) or { SpellCooldown(serenity) >= 5 or not Talent(serenity_talent) and not HasAzeriteTrait(swift_roundhouse_trait) } and Spell(rising_sun_kick) or SpellCooldown(fists_of_fury) > 2 and not PreviousGCDSpell(blackout_kick_windwalker) and TimeToMaxEnergy() > 1 and AzeriteTraitRank(swift_roundhouse_trait) > 1 and Spell(blackout_kick_windwalker) or PreviousGCDSpell(blackout_kick_windwalker) and TimeToMaxEnergy() > 2 and Chi() > 1 and Spell(flying_serpent_kick) or BuffStacks(swift_roundhouse_buff) < 2 and not PreviousGCDSpell(blackout_kick_windwalker) and Spell(blackout_kick_windwalker) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or not PreviousGCDSpell(blackout_kick_windwalker) and Spell(blackout_kick_windwalker) or Spell(chi_wave) or TimeToMaxEnergy() > 1 and Talent(serenity_talent) and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 3 } and not DebuffPresent(serenity) and Spell(tiger_palm) or MaxChi() - Chi() >= 3 and TimeToMaxEnergy() > 1 and not Talent(serenity_talent) and CheckBoxOn(opt_chi_burst) and Spell(chi_burst)
}

### actions.serenity_openerSR

AddFunction WindwalkerSerenityopenersrMainActions
{
 #tiger_palm,target_if=debuff.mark_of_the_crane.down,if=buff.serenity.down&chi<4
 if target.DebuffExpires(mark_of_the_crane_debuff) and DebuffExpires(serenity) and Chi() < 4 Spell(tiger_palm)
 #call_action_list,name=cd,if=buff.serenity.down
 if DebuffExpires(serenity) WindwalkerCdMainActions()

 unless DebuffExpires(serenity) and WindwalkerCdMainPostConditions()
 {
  #call_action_list,name=serenity,if=buff.bloodlust.down
  if BuffExpires(burst_haste_buff any=1) WindwalkerSerenityMainActions()

  unless BuffExpires(burst_haste_buff any=1) and WindwalkerSerenityMainPostConditions()
  {
   #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains
   Spell(rising_sun_kick)
   #fists_of_fury,if=buff.serenity.remains<1
   if DebuffRemaining(serenity) < 1 Spell(fists_of_fury)
   #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&cooldown.rising_sun_kick.remains>=2&cooldown.fists_of_fury.remains>=2
   if not PreviousGCDSpell(blackout_kick_windwalker) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 Spell(blackout_kick_windwalker)
   #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains
   Spell(blackout_kick_windwalker)
  }
 }
}

AddFunction WindwalkerSerenityopenersrMainPostConditions
{
 DebuffExpires(serenity) and WindwalkerCdMainPostConditions() or BuffExpires(burst_haste_buff any=1) and WindwalkerSerenityMainPostConditions()
}

AddFunction WindwalkerSerenityopenersrShortCdActions
{
 #fist_of_the_white_tiger,if=buff.serenity.down
 if DebuffExpires(serenity) Spell(fist_of_the_white_tiger)

 unless target.DebuffExpires(mark_of_the_crane_debuff) and DebuffExpires(serenity) and Chi() < 4 and Spell(tiger_palm)
 {
  #call_action_list,name=cd,if=buff.serenity.down
  if DebuffExpires(serenity) WindwalkerCdShortCdActions()

  unless DebuffExpires(serenity) and WindwalkerCdShortCdPostConditions()
  {
   #call_action_list,name=serenity,if=buff.bloodlust.down
   if BuffExpires(burst_haste_buff any=1) WindwalkerSerenityShortCdActions()

   unless BuffExpires(burst_haste_buff any=1) and WindwalkerSerenityShortCdPostConditions()
   {
    #serenity
    Spell(serenity)
   }
  }
 }
}

AddFunction WindwalkerSerenityopenersrShortCdPostConditions
{
 target.DebuffExpires(mark_of_the_crane_debuff) and DebuffExpires(serenity) and Chi() < 4 and Spell(tiger_palm) or DebuffExpires(serenity) and WindwalkerCdShortCdPostConditions() or BuffExpires(burst_haste_buff any=1) and WindwalkerSerenityShortCdPostConditions() or Spell(rising_sun_kick) or DebuffRemaining(serenity) < 1 and Spell(fists_of_fury) or not PreviousGCDSpell(blackout_kick_windwalker) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 and Spell(blackout_kick_windwalker) or Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerSerenityopenersrCdActions
{
 unless DebuffExpires(serenity) and Spell(fist_of_the_white_tiger) or target.DebuffExpires(mark_of_the_crane_debuff) and DebuffExpires(serenity) and Chi() < 4 and Spell(tiger_palm)
 {
  #call_action_list,name=cd,if=buff.serenity.down
  if DebuffExpires(serenity) WindwalkerCdCdActions()

  unless DebuffExpires(serenity) and WindwalkerCdCdPostConditions()
  {
   #call_action_list,name=serenity,if=buff.bloodlust.down
   if BuffExpires(burst_haste_buff any=1) WindwalkerSerenityCdActions()
  }
 }
}

AddFunction WindwalkerSerenityopenersrCdPostConditions
{
 DebuffExpires(serenity) and Spell(fist_of_the_white_tiger) or target.DebuffExpires(mark_of_the_crane_debuff) and DebuffExpires(serenity) and Chi() < 4 and Spell(tiger_palm) or DebuffExpires(serenity) and WindwalkerCdCdPostConditions() or BuffExpires(burst_haste_buff any=1) and WindwalkerSerenityCdPostConditions() or Spell(serenity) or Spell(rising_sun_kick) or DebuffRemaining(serenity) < 1 and Spell(fists_of_fury) or not PreviousGCDSpell(blackout_kick_windwalker) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 and Spell(blackout_kick_windwalker) or Spell(blackout_kick_windwalker)
}

### actions.serenity_opener

AddFunction WindwalkerSerenityopenerMainActions
{
 #tiger_palm,target_if=debuff.mark_of_the_crane.down,if=!prev_gcd.1.tiger_palm&buff.serenity.down&chi<4
 if target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and DebuffExpires(serenity) and Chi() < 4 Spell(tiger_palm)
 #call_action_list,name=cd,if=buff.serenity.down
 if DebuffExpires(serenity) WindwalkerCdMainActions()

 unless DebuffExpires(serenity) and WindwalkerCdMainPostConditions()
 {
  #call_action_list,name=serenity,if=buff.bloodlust.down
  if BuffExpires(burst_haste_buff any=1) WindwalkerSerenityMainActions()

  unless BuffExpires(burst_haste_buff any=1) and WindwalkerSerenityMainPostConditions()
  {
   #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains
   Spell(rising_sun_kick)
   #fists_of_fury,if=prev_gcd.1.rising_sun_kick&prev_gcd.2.serenity
   if PreviousGCDSpell(rising_sun_kick) and PreviousGCDSpell(serenity count=2) Spell(fists_of_fury)
   #fists_of_fury,if=prev_gcd.1.rising_sun_kick&prev_gcd.2.blackout_kick
   if PreviousGCDSpell(rising_sun_kick) and PreviousGCDSpell(blackout_kick_windwalker count=2) Spell(fists_of_fury)
   #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&cooldown.rising_sun_kick.remains>=2&cooldown.fists_of_fury.remains>=2
   if not PreviousGCDSpell(blackout_kick_windwalker) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 Spell(blackout_kick_windwalker)
   #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick
   if not PreviousGCDSpell(blackout_kick_windwalker) Spell(blackout_kick_windwalker)
  }
 }
}

AddFunction WindwalkerSerenityopenerMainPostConditions
{
 DebuffExpires(serenity) and WindwalkerCdMainPostConditions() or BuffExpires(burst_haste_buff any=1) and WindwalkerSerenityMainPostConditions()
}

AddFunction WindwalkerSerenityopenerShortCdActions
{
 #fist_of_the_white_tiger,if=buff.serenity.down
 if DebuffExpires(serenity) Spell(fist_of_the_white_tiger)

 unless target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and DebuffExpires(serenity) and Chi() < 4 and Spell(tiger_palm)
 {
  #call_action_list,name=cd,if=buff.serenity.down
  if DebuffExpires(serenity) WindwalkerCdShortCdActions()

  unless DebuffExpires(serenity) and WindwalkerCdShortCdPostConditions()
  {
   #call_action_list,name=serenity,if=buff.bloodlust.down
   if BuffExpires(burst_haste_buff any=1) WindwalkerSerenityShortCdActions()

   unless BuffExpires(burst_haste_buff any=1) and WindwalkerSerenityShortCdPostConditions()
   {
    #serenity
    Spell(serenity)
   }
  }
 }
}

AddFunction WindwalkerSerenityopenerShortCdPostConditions
{
 target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and DebuffExpires(serenity) and Chi() < 4 and Spell(tiger_palm) or DebuffExpires(serenity) and WindwalkerCdShortCdPostConditions() or BuffExpires(burst_haste_buff any=1) and WindwalkerSerenityShortCdPostConditions() or Spell(rising_sun_kick) or PreviousGCDSpell(rising_sun_kick) and PreviousGCDSpell(serenity count=2) and Spell(fists_of_fury) or PreviousGCDSpell(rising_sun_kick) and PreviousGCDSpell(blackout_kick_windwalker count=2) and Spell(fists_of_fury) or not PreviousGCDSpell(blackout_kick_windwalker) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 and Spell(blackout_kick_windwalker) or not PreviousGCDSpell(blackout_kick_windwalker) and Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerSerenityopenerCdActions
{
 unless DebuffExpires(serenity) and Spell(fist_of_the_white_tiger) or target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and DebuffExpires(serenity) and Chi() < 4 and Spell(tiger_palm)
 {
  #call_action_list,name=cd,if=buff.serenity.down
  if DebuffExpires(serenity) WindwalkerCdCdActions()

  unless DebuffExpires(serenity) and WindwalkerCdCdPostConditions()
  {
   #call_action_list,name=serenity,if=buff.bloodlust.down
   if BuffExpires(burst_haste_buff any=1) WindwalkerSerenityCdActions()
  }
 }
}

AddFunction WindwalkerSerenityopenerCdPostConditions
{
 DebuffExpires(serenity) and Spell(fist_of_the_white_tiger) or target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and DebuffExpires(serenity) and Chi() < 4 and Spell(tiger_palm) or DebuffExpires(serenity) and WindwalkerCdCdPostConditions() or BuffExpires(burst_haste_buff any=1) and WindwalkerSerenityCdPostConditions() or Spell(serenity) or Spell(rising_sun_kick) or PreviousGCDSpell(rising_sun_kick) and PreviousGCDSpell(serenity count=2) and Spell(fists_of_fury) or PreviousGCDSpell(rising_sun_kick) and PreviousGCDSpell(blackout_kick_windwalker count=2) and Spell(fists_of_fury) or not PreviousGCDSpell(blackout_kick_windwalker) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 and Spell(blackout_kick_windwalker) or not PreviousGCDSpell(blackout_kick_windwalker) and Spell(blackout_kick_windwalker)
}

### actions.serenitySR

AddFunction WindwalkerSerenitysrMainActions
{
 #tiger_palm,target_if=debuff.mark_of_the_crane.down,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&energy=energy.max&chi<1&!buff.serenity.up
 if target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not DebuffPresent(serenity) Spell(tiger_palm)
 #call_action_list,name=cd
 WindwalkerCdMainActions()

 unless WindwalkerCdMainPostConditions()
 {
  #fists_of_fury,if=buff.serenity.remains<=1.05
  if DebuffRemaining(serenity) <= 1 Spell(fists_of_fury)
  #rising_sun_kick,target_if=debuff.mark_of_the_crane.down
  if target.DebuffExpires(mark_of_the_crane_debuff) Spell(rising_sun_kick)
  #blackout_kick,target_if=debuff.mark_of_the_crane.down,if=!prev_gcd.1.blackout_kick&cooldown.rising_sun_kick.remains>=2&cooldown.fists_of_fury.remains>=2
  if target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(blackout_kick_windwalker) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 Spell(blackout_kick_windwalker)
  #blackout_kick,target_if=debuff.mark_of_the_crane.down
  if target.DebuffExpires(mark_of_the_crane_debuff) Spell(blackout_kick_windwalker)
 }
}

AddFunction WindwalkerSerenitysrMainPostConditions
{
 WindwalkerCdMainPostConditions()
}

AddFunction WindwalkerSerenitysrShortCdActions
{
 unless target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not DebuffPresent(serenity) and Spell(tiger_palm)
 {
  #call_action_list,name=cd
  WindwalkerCdShortCdActions()

  unless WindwalkerCdShortCdPostConditions()
  {
   #serenity,if=cooldown.rising_sun_kick.remains<=2
   if SpellCooldown(rising_sun_kick) <= 2 Spell(serenity)
  }
 }
}

AddFunction WindwalkerSerenitysrShortCdPostConditions
{
 target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not DebuffPresent(serenity) and Spell(tiger_palm) or WindwalkerCdShortCdPostConditions() or DebuffRemaining(serenity) <= 1 and Spell(fists_of_fury) or target.DebuffExpires(mark_of_the_crane_debuff) and Spell(rising_sun_kick) or target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(blackout_kick_windwalker) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 and Spell(blackout_kick_windwalker) or target.DebuffExpires(mark_of_the_crane_debuff) and Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerSerenitysrCdActions
{
 unless target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not DebuffPresent(serenity) and Spell(tiger_palm)
 {
  #call_action_list,name=cd
  WindwalkerCdCdActions()
 }
}

AddFunction WindwalkerSerenitysrCdPostConditions
{
 target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not DebuffPresent(serenity) and Spell(tiger_palm) or WindwalkerCdCdPostConditions() or SpellCooldown(rising_sun_kick) <= 2 and Spell(serenity) or DebuffRemaining(serenity) <= 1 and Spell(fists_of_fury) or target.DebuffExpires(mark_of_the_crane_debuff) and Spell(rising_sun_kick) or target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(blackout_kick_windwalker) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 and Spell(blackout_kick_windwalker) or target.DebuffExpires(mark_of_the_crane_debuff) and Spell(blackout_kick_windwalker)
}

### actions.serenity

AddFunction WindwalkerSerenityMainActions
{
 #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&energy=energy.max&chi<1&!buff.serenity.up
 if not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not DebuffPresent(serenity) Spell(tiger_palm)
 #call_action_list,name=cd
 WindwalkerCdMainActions()

 unless WindwalkerCdMainPostConditions()
 {
  #rushing_jade_wind,if=talent.rushing_jade_wind.enabled&!prev_gcd.1.rushing_jade_wind&buff.rushing_jade_wind.down
  if Talent(rushing_jade_wind_talent_windwalker) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and DebuffExpires(rushing_jade_wind_windwalker) Spell(rushing_jade_wind_windwalker)
  #fists_of_fury,if=prev_gcd.1.rising_sun_kick&prev_gcd.2.serenity
  if PreviousGCDSpell(rising_sun_kick) and PreviousGCDSpell(serenity count=2) Spell(fists_of_fury)
  #fists_of_fury,if=buff.serenity.remains<=1.05
  if DebuffRemaining(serenity) <= 1 Spell(fists_of_fury)
  #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains
  Spell(rising_sun_kick)
  #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=prev_gcd.1.blackout_kick&prev_gcd.2.rising_sun_kick&chi.max-chi>1
  if PreviousGCDSpell(blackout_kick_windwalker) and PreviousGCDSpell(rising_sun_kick count=2) and MaxChi() - Chi() > 1 Spell(tiger_palm)
  #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&cooldown.rising_sun_kick.remains>=2&cooldown.fists_of_fury.remains>=2
  if not PreviousGCDSpell(blackout_kick_windwalker) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 Spell(blackout_kick_windwalker)
  #spinning_crane_kick,if=active_enemies>=3&!prev_gcd.1.spinning_crane_kick
  if Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) Spell(spinning_crane_kick)
  #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains
  Spell(rising_sun_kick)
  #spinning_crane_kick,if=!prev_gcd.1.spinning_crane_kick
  if not PreviousGCDSpell(spinning_crane_kick) Spell(spinning_crane_kick)
  #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick
  if not PreviousGCDSpell(blackout_kick_windwalker) Spell(blackout_kick_windwalker)
 }
}

AddFunction WindwalkerSerenityMainPostConditions
{
 WindwalkerCdMainPostConditions()
}

AddFunction WindwalkerSerenityShortCdActions
{
 unless not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not DebuffPresent(serenity) and Spell(tiger_palm)
 {
  #call_action_list,name=cd
  WindwalkerCdShortCdActions()

  unless WindwalkerCdShortCdPostConditions() or Talent(rushing_jade_wind_talent_windwalker) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and DebuffExpires(rushing_jade_wind_windwalker) and Spell(rushing_jade_wind_windwalker)
  {
   #serenity,if=cooldown.rising_sun_kick.remains<=2&cooldown.fists_of_fury.remains<=4
   if SpellCooldown(rising_sun_kick) <= 2 and SpellCooldown(fists_of_fury) <= 4 Spell(serenity)

   unless PreviousGCDSpell(rising_sun_kick) and PreviousGCDSpell(serenity count=2) and Spell(fists_of_fury) or DebuffRemaining(serenity) <= 1 and Spell(fists_of_fury) or Spell(rising_sun_kick)
   {
    #fist_of_the_white_tiger,if=prev_gcd.1.blackout_kick&prev_gcd.2.rising_sun_kick&chi.max-chi>2
    if PreviousGCDSpell(blackout_kick_windwalker) and PreviousGCDSpell(rising_sun_kick count=2) and MaxChi() - Chi() > 2 Spell(fist_of_the_white_tiger)
   }
  }
 }
}

AddFunction WindwalkerSerenityShortCdPostConditions
{
 not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not DebuffPresent(serenity) and Spell(tiger_palm) or WindwalkerCdShortCdPostConditions() or Talent(rushing_jade_wind_talent_windwalker) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and DebuffExpires(rushing_jade_wind_windwalker) and Spell(rushing_jade_wind_windwalker) or PreviousGCDSpell(rising_sun_kick) and PreviousGCDSpell(serenity count=2) and Spell(fists_of_fury) or DebuffRemaining(serenity) <= 1 and Spell(fists_of_fury) or Spell(rising_sun_kick) or PreviousGCDSpell(blackout_kick_windwalker) and PreviousGCDSpell(rising_sun_kick count=2) and MaxChi() - Chi() > 1 and Spell(tiger_palm) or not PreviousGCDSpell(blackout_kick_windwalker) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 and Spell(blackout_kick_windwalker) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or Spell(rising_sun_kick) or not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(blackout_kick_windwalker) and Spell(blackout_kick_windwalker)
}

AddFunction WindwalkerSerenityCdActions
{
 unless not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not DebuffPresent(serenity) and Spell(tiger_palm)
 {
  #call_action_list,name=cd
  WindwalkerCdCdActions()
 }
}

AddFunction WindwalkerSerenityCdPostConditions
{
 not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and not DebuffPresent(serenity) and Spell(tiger_palm) or WindwalkerCdCdPostConditions() or Talent(rushing_jade_wind_talent_windwalker) and not PreviousGCDSpell(rushing_jade_wind_windwalker) and DebuffExpires(rushing_jade_wind_windwalker) and Spell(rushing_jade_wind_windwalker) or SpellCooldown(rising_sun_kick) <= 2 and SpellCooldown(fists_of_fury) <= 4 and Spell(serenity) or PreviousGCDSpell(rising_sun_kick) and PreviousGCDSpell(serenity count=2) and Spell(fists_of_fury) or DebuffRemaining(serenity) <= 1 and Spell(fists_of_fury) or Spell(rising_sun_kick) or PreviousGCDSpell(blackout_kick_windwalker) and PreviousGCDSpell(rising_sun_kick count=2) and MaxChi() - Chi() > 2 and Spell(fist_of_the_white_tiger) or PreviousGCDSpell(blackout_kick_windwalker) and PreviousGCDSpell(rising_sun_kick count=2) and MaxChi() - Chi() > 1 and Spell(tiger_palm) or not PreviousGCDSpell(blackout_kick_windwalker) and SpellCooldown(rising_sun_kick) >= 2 and SpellCooldown(fists_of_fury) >= 2 and Spell(blackout_kick_windwalker) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or Spell(rising_sun_kick) or not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(blackout_kick_windwalker) and Spell(blackout_kick_windwalker)
}

### actions.sef

AddFunction WindwalkerSefMainActions
{
 #tiger_palm,target_if=debuff.mark_of_the_crane.down,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&energy=energy.max&chi<1
 if target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 Spell(tiger_palm)
 #call_action_list,name=cd
 WindwalkerCdMainActions()

 unless WindwalkerCdMainPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3
  if Enemies() > 3 WindwalkerAoeMainActions()

  unless Enemies() > 3 and WindwalkerAoeMainPostConditions()
  {
   #call_action_list,name=st,if=active_enemies<=3
   if Enemies() <= 3 WindwalkerStMainActions()
  }
 }
}

AddFunction WindwalkerSefMainPostConditions
{
 WindwalkerCdMainPostConditions() or Enemies() > 3 and WindwalkerAoeMainPostConditions() or Enemies() <= 3 and WindwalkerStMainPostConditions()
}

AddFunction WindwalkerSefShortCdActions
{
 unless target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and Spell(tiger_palm)
 {
  #call_action_list,name=cd
  WindwalkerCdShortCdActions()

  unless WindwalkerCdShortCdPostConditions()
  {
   #call_action_list,name=aoe,if=active_enemies>3
   if Enemies() > 3 WindwalkerAoeShortCdActions()

   unless Enemies() > 3 and WindwalkerAoeShortCdPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<=3
    if Enemies() <= 3 WindwalkerStShortCdActions()
   }
  }
 }
}

AddFunction WindwalkerSefShortCdPostConditions
{
 target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and Spell(tiger_palm) or WindwalkerCdShortCdPostConditions() or Enemies() > 3 and WindwalkerAoeShortCdPostConditions() or Enemies() <= 3 and WindwalkerStShortCdPostConditions()
}

AddFunction WindwalkerSefCdActions
{
 unless target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and Spell(tiger_palm)
 {
  #call_action_list,name=cd
  WindwalkerCdCdActions()

  unless WindwalkerCdCdPostConditions()
  {
   #storm_earth_and_fire,if=!buff.storm_earth_and_fire.up
   if not DebuffPresent(storm_earth_and_fire) and CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff) Spell(storm_earth_and_fire)
   #call_action_list,name=aoe,if=active_enemies>3
   if Enemies() > 3 WindwalkerAoeCdActions()

   unless Enemies() > 3 and WindwalkerAoeCdPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<=3
    if Enemies() <= 3 WindwalkerStCdActions()
   }
  }
 }
}

AddFunction WindwalkerSefCdPostConditions
{
 target.DebuffExpires(mark_of_the_crane_debuff) and not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and Energy() == MaxEnergy() and Chi() < 1 and Spell(tiger_palm) or WindwalkerCdCdPostConditions() or Enemies() > 3 and WindwalkerAoeCdPostConditions() or Enemies() <= 3 and WindwalkerStCdPostConditions()
}

### actions.precombat

AddFunction WindwalkerPrecombatMainActions
{
 #chi_burst
 if CheckBoxOn(opt_chi_burst) Spell(chi_burst)
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
 CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

AddFunction WindwalkerPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
}

AddFunction WindwalkerPrecombatCdPostConditions
{
 CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
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
 #touch_of_death
 if not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) Spell(touch_of_death)
}

AddFunction WindwalkerCdCdPostConditions
{
}

### actions.aoe

AddFunction WindwalkerAoeMainActions
{
 #call_action_list,name=cd
 WindwalkerCdMainActions()

 unless WindwalkerCdMainPostConditions()
 {
  #fists_of_fury,if=talent.serenity.enabled&!equipped.drinking_horn_cover&cooldown.serenity.remains>=5&energy.time_to_max>2
  if Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(serenity) >= 5 and TimeToMaxEnergy() > 2 Spell(fists_of_fury)
  #fists_of_fury,if=talent.serenity.enabled&equipped.drinking_horn_cover&(cooldown.serenity.remains>=15|cooldown.serenity.remains<=4)&energy.time_to_max>2
  if Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover_item) and { SpellCooldown(serenity) >= 15 or SpellCooldown(serenity) <= 4 } and TimeToMaxEnergy() > 2 Spell(fists_of_fury)
  #fists_of_fury,if=!talent.serenity.enabled&energy.time_to_max>2
  if not Talent(serenity_talent) and TimeToMaxEnergy() > 2 Spell(fists_of_fury)
  #fists_of_fury,if=cooldown.rising_sun_kick.remains>=3.5&chi<=5
  if SpellCooldown(rising_sun_kick) >= 3 and Chi() <= 5 Spell(fists_of_fury)
  #whirling_dragon_punch
  if SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 Spell(whirling_dragon_punch)
  #rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=cooldown.whirling_dragon_punch.remains>=gcd&!prev_gcd.1.rising_sun_kick&cooldown.fists_of_fury.remains>gcd
  if SpellCooldown(whirling_dragon_punch) >= GCD() and not PreviousGCDSpell(rising_sun_kick) and SpellCooldown(fists_of_fury) > GCD() Spell(rising_sun_kick)
  #chi_burst,if=chi<=3&(cooldown.rising_sun_kick.remains>=5|cooldown.whirling_dragon_punch.remains>=5)&energy.time_to_max>1
  if Chi() <= 3 and { SpellCooldown(rising_sun_kick) >= 5 or SpellCooldown(whirling_dragon_punch) >= 5 } and TimeToMaxEnergy() > 1 and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
  #chi_burst
  if CheckBoxOn(opt_chi_burst) Spell(chi_burst)
  #spinning_crane_kick,if=(active_enemies>=3|(buff.bok_proc.up&chi.max-chi>=0))&!prev_gcd.1.spinning_crane_kick&set_bonus.tier21_4pc
  if { Enemies() >= 3 or BuffPresent(blackout_kick_buff) and MaxChi() - Chi() >= 0 } and not PreviousGCDSpell(spinning_crane_kick) and ArmorSetBonus(T21 4) Spell(spinning_crane_kick)
  #spinning_crane_kick,if=active_enemies>=3&!prev_gcd.1.spinning_crane_kick
  if Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) Spell(spinning_crane_kick)
  #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&chi.max-chi>=1&set_bonus.tier21_4pc&(!set_bonus.tier19_2pc|talent.serenity.enabled)
  if not PreviousGCDSpell(blackout_kick_windwalker) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and { not ArmorSetBonus(T19 2) or Talent(serenity_talent) } Spell(blackout_kick_windwalker)
  #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(chi>1|buff.bok_proc.up|(talent.energizing_elixir.enabled&cooldown.energizing_elixir.remains<cooldown.fists_of_fury.remains))&((cooldown.rising_sun_kick.remains>1&(!talent.fist_of_the_white_tiger.enabled|cooldown.fist_of_the_white_tiger.remains>1)|chi>4)&(cooldown.fists_of_fury.remains>1|chi>2)|prev_gcd.1.tiger_palm)&!prev_gcd.1.blackout_kick
  if { Chi() > 1 or BuffPresent(blackout_kick_buff) or Talent(energizing_elixir_talent) and SpellCooldown(energizing_elixir) < SpellCooldown(fists_of_fury) } and { { SpellCooldown(rising_sun_kick) > 1 and { not Talent(fist_of_the_white_tiger_talent) or SpellCooldown(fist_of_the_white_tiger) > 1 } or Chi() > 4 } and { SpellCooldown(fists_of_fury) > 1 or Chi() > 2 } or PreviousGCDSpell(tiger_palm) } and not PreviousGCDSpell(blackout_kick_windwalker) Spell(blackout_kick_windwalker)
  #crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=19&energy.time_to_max>3
  if HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 Spell(crackling_jade_lightning)
  #crackling_jade_lightning,if=equipped.the_emperors_capacitor&buff.the_emperors_capacitor.stack>=14&cooldown.serenity.remains<13&talent.serenity.enabled&energy.time_to_max>3
  if HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 Spell(crackling_jade_lightning)
  #blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&chi.max-chi>=1&set_bonus.tier21_4pc&buff.bok_proc.up
  if not PreviousGCDSpell(blackout_kick_windwalker) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) Spell(blackout_kick_windwalker)
  #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&(chi.max-chi>=2|energy.time_to_max<3)
  if not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 3 } Spell(tiger_palm)
  #tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&!prev_gcd.1.energizing_elixir&energy.time_to_max<=1&chi.max-chi>=2
  if not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and TimeToMaxEnergy() <= 1 and MaxChi() - Chi() >= 2 Spell(tiger_palm)
  #chi_wave,if=chi<=3&(cooldown.rising_sun_kick.remains>=5|cooldown.whirling_dragon_punch.remains>=5)&energy.time_to_max>1
  if Chi() <= 3 and { SpellCooldown(rising_sun_kick) >= 5 or SpellCooldown(whirling_dragon_punch) >= 5 } and TimeToMaxEnergy() > 1 Spell(chi_wave)
  #chi_wave
  Spell(chi_wave)
 }
}

AddFunction WindwalkerAoeMainPostConditions
{
 WindwalkerCdMainPostConditions()
}

AddFunction WindwalkerAoeShortCdActions
{
 #call_action_list,name=cd
 WindwalkerCdShortCdActions()

 unless WindwalkerCdShortCdPostConditions()
 {
  #energizing_elixir,if=!prev_gcd.1.tiger_palm&chi<=1&(cooldown.rising_sun_kick.remains=0|(talent.fist_of_the_white_tiger.enabled&cooldown.fist_of_the_white_tiger.remains=0)|energy<50)
  if not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and { not SpellCooldown(rising_sun_kick) > 0 or Talent(fist_of_the_white_tiger_talent) and not SpellCooldown(fist_of_the_white_tiger) > 0 or Energy() < 50 } Spell(energizing_elixir)
 }
}

AddFunction WindwalkerAoeShortCdPostConditions
{
 WindwalkerCdShortCdPostConditions() or Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(serenity) >= 5 and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover_item) and { SpellCooldown(serenity) >= 15 or SpellCooldown(serenity) <= 4 } and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or not Talent(serenity_talent) and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or SpellCooldown(rising_sun_kick) >= 3 and Chi() <= 5 and Spell(fists_of_fury) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or SpellCooldown(whirling_dragon_punch) >= GCD() and not PreviousGCDSpell(rising_sun_kick) and SpellCooldown(fists_of_fury) > GCD() and Spell(rising_sun_kick) or Chi() <= 3 and { SpellCooldown(rising_sun_kick) >= 5 or SpellCooldown(whirling_dragon_punch) >= 5 } and TimeToMaxEnergy() > 1 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or { Enemies() >= 3 or BuffPresent(blackout_kick_buff) and MaxChi() - Chi() >= 0 } and not PreviousGCDSpell(spinning_crane_kick) and ArmorSetBonus(T21 4) and Spell(spinning_crane_kick) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(blackout_kick_windwalker) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and { not ArmorSetBonus(T19 2) or Talent(serenity_talent) } and Spell(blackout_kick_windwalker) or { Chi() > 1 or BuffPresent(blackout_kick_buff) or Talent(energizing_elixir_talent) and SpellCooldown(energizing_elixir) < SpellCooldown(fists_of_fury) } and { { SpellCooldown(rising_sun_kick) > 1 and { not Talent(fist_of_the_white_tiger_talent) or SpellCooldown(fist_of_the_white_tiger) > 1 } or Chi() > 4 } and { SpellCooldown(fists_of_fury) > 1 or Chi() > 2 } or PreviousGCDSpell(tiger_palm) } and not PreviousGCDSpell(blackout_kick_windwalker) and Spell(blackout_kick_windwalker) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or not PreviousGCDSpell(blackout_kick_windwalker) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) and Spell(blackout_kick_windwalker) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 3 } and Spell(tiger_palm) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and TimeToMaxEnergy() <= 1 and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or Chi() <= 3 and { SpellCooldown(rising_sun_kick) >= 5 or SpellCooldown(whirling_dragon_punch) >= 5 } and TimeToMaxEnergy() > 1 and Spell(chi_wave) or Spell(chi_wave)
}

AddFunction WindwalkerAoeCdActions
{
 #call_action_list,name=cd
 WindwalkerCdCdActions()

 unless WindwalkerCdCdPostConditions() or not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and { not SpellCooldown(rising_sun_kick) > 0 or Talent(fist_of_the_white_tiger_talent) and not SpellCooldown(fist_of_the_white_tiger) > 0 or Energy() < 50 } and Spell(energizing_elixir)
 {
  #arcane_torrent,if=chi.max-chi>=1&energy.time_to_max>=0.5
  if MaxChi() - Chi() >= 1 and TimeToMaxEnergy() >= 0.5 Spell(arcane_torrent_chi)
 }
}

AddFunction WindwalkerAoeCdPostConditions
{
 WindwalkerCdCdPostConditions() or not PreviousGCDSpell(tiger_palm) and Chi() <= 1 and { not SpellCooldown(rising_sun_kick) > 0 or Talent(fist_of_the_white_tiger_talent) and not SpellCooldown(fist_of_the_white_tiger) > 0 or Energy() < 50 } and Spell(energizing_elixir) or Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(serenity) >= 5 and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or Talent(serenity_talent) and HasEquippedItem(drinking_horn_cover_item) and { SpellCooldown(serenity) >= 15 or SpellCooldown(serenity) <= 4 } and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or not Talent(serenity_talent) and TimeToMaxEnergy() > 2 and Spell(fists_of_fury) or SpellCooldown(rising_sun_kick) >= 3 and Chi() <= 5 and Spell(fists_of_fury) or SpellCooldown(fists_of_fury) > 0 and SpellCooldown(rising_sun_kick) > 0 and Spell(whirling_dragon_punch) or SpellCooldown(whirling_dragon_punch) >= GCD() and not PreviousGCDSpell(rising_sun_kick) and SpellCooldown(fists_of_fury) > GCD() and Spell(rising_sun_kick) or Chi() <= 3 and { SpellCooldown(rising_sun_kick) >= 5 or SpellCooldown(whirling_dragon_punch) >= 5 } and TimeToMaxEnergy() > 1 and CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or { Enemies() >= 3 or BuffPresent(blackout_kick_buff) and MaxChi() - Chi() >= 0 } and not PreviousGCDSpell(spinning_crane_kick) and ArmorSetBonus(T21 4) and Spell(spinning_crane_kick) or Enemies() >= 3 and not PreviousGCDSpell(spinning_crane_kick) and Spell(spinning_crane_kick) or not PreviousGCDSpell(blackout_kick_windwalker) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and { not ArmorSetBonus(T19 2) or Talent(serenity_talent) } and Spell(blackout_kick_windwalker) or { Chi() > 1 or BuffPresent(blackout_kick_buff) or Talent(energizing_elixir_talent) and SpellCooldown(energizing_elixir) < SpellCooldown(fists_of_fury) } and { { SpellCooldown(rising_sun_kick) > 1 and { not Talent(fist_of_the_white_tiger_talent) or SpellCooldown(fist_of_the_white_tiger) > 1 } or Chi() > 4 } and { SpellCooldown(fists_of_fury) > 1 or Chi() > 2 } or PreviousGCDSpell(tiger_palm) } and not PreviousGCDSpell(blackout_kick_windwalker) and Spell(blackout_kick_windwalker) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 19 and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or HasEquippedItem(the_emperors_capacitor_item) and BuffStacks(the_emperors_capacitor_buff) >= 14 and SpellCooldown(serenity) < 13 and Talent(serenity_talent) and TimeToMaxEnergy() > 3 and Spell(crackling_jade_lightning) or not PreviousGCDSpell(blackout_kick_windwalker) and MaxChi() - Chi() >= 1 and ArmorSetBonus(T21 4) and BuffPresent(blackout_kick_buff) and Spell(blackout_kick_windwalker) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and { MaxChi() - Chi() >= 2 or TimeToMaxEnergy() < 3 } and Spell(tiger_palm) or not PreviousGCDSpell(tiger_palm) and not PreviousGCDSpell(energizing_elixir) and TimeToMaxEnergy() <= 1 and MaxChi() - Chi() >= 2 and Spell(tiger_palm) or Chi() <= 3 and { SpellCooldown(rising_sun_kick) >= 5 or SpellCooldown(whirling_dragon_punch) >= 5 } and TimeToMaxEnergy() > 1 and Spell(chi_wave) or Spell(chi_wave)
}

### actions.default

AddFunction WindwalkerDefaultMainActions
{
 #call_action_list,name=serenitySR,if=((talent.serenity.enabled&cooldown.serenity.remains<=0)|buff.serenity.up)&azerite.swift_roundhouse.rank>1&time>30
 if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and AzeriteTraitRank(swift_roundhouse_trait) > 1 and TimeInCombat() > 30 WindwalkerSerenitysrMainActions()

 unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and AzeriteTraitRank(swift_roundhouse_trait) > 1 and TimeInCombat() > 30 and WindwalkerSerenitysrMainPostConditions()
 {
  #call_action_list,name=serenity,if=((talent.serenity.enabled&cooldown.serenity.remains<=0)|buff.serenity.up)&time>30
  if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() > 30 WindwalkerSerenityMainActions()

  unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() > 30 and WindwalkerSerenityMainPostConditions()
  {
   #call_action_list,name=serenity_openerSR,if=(talent.serenity.enabled&cooldown.serenity.remains<=0|buff.serenity.up)&time<30&azerite.swift_roundhouse.enabled
   if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and HasAzeriteTrait(swift_roundhouse_trait) WindwalkerSerenityopenersrMainActions()

   unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and HasAzeriteTrait(swift_roundhouse_trait) and WindwalkerSerenityopenersrMainPostConditions()
   {
    #call_action_list,name=serenity_opener,if=(talent.serenity.enabled&cooldown.serenity.remains<=0|buff.serenity.up)&time<30
    if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 WindwalkerSerenityopenerMainActions()

    unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and WindwalkerSerenityopenerMainPostConditions()
    {
     #call_action_list,name=sef,if=!talent.serenity.enabled&(buff.storm_earth_and_fire.up|cooldown.storm_earth_and_fire.charges=2)
     if not Talent(serenity_talent) and { DebuffPresent(storm_earth_and_fire) or SpellCharges(storm_earth_and_fire) == 2 } WindwalkerSefMainActions()

     unless not Talent(serenity_talent) and { DebuffPresent(storm_earth_and_fire) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefMainPostConditions()
     {
      #call_action_list,name=sef,if=(!talent.serenity.enabled&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=25|cooldown.touch_of_death.remains>112
      if not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 WindwalkerSefMainActions()

      unless { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and WindwalkerSefMainPostConditions()
      {
       #call_action_list,name=sef,if=(!talent.serenity.enabled&!equipped.drinking_horn_cover&cooldown.fists_of_fury.remains<=6&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=15|cooldown.touch_of_death.remains>112&cooldown.storm_earth_and_fire.charges=1
       if not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefMainActions()

       unless { not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefMainPostConditions()
       {
        #call_action_list,name=sef,if=(!talent.serenity.enabled&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=25|cooldown.touch_of_death.remains>112&cooldown.storm_earth_and_fire.charges=1
        if not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefMainActions()

        unless { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefMainPostConditions()
        {
         #call_action_list,name=aoe,if=active_enemies>3
         if Enemies() > 3 WindwalkerAoeMainActions()

         unless Enemies() > 3 and WindwalkerAoeMainPostConditions()
         {
          #call_action_list,name=st,if=active_enemies<=3
          if Enemies() <= 3 WindwalkerStMainActions()
         }
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction WindwalkerDefaultMainPostConditions
{
 { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and AzeriteTraitRank(swift_roundhouse_trait) > 1 and TimeInCombat() > 30 and WindwalkerSerenitysrMainPostConditions() or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() > 30 and WindwalkerSerenityMainPostConditions() or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and HasAzeriteTrait(swift_roundhouse_trait) and WindwalkerSerenityopenersrMainPostConditions() or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and WindwalkerSerenityopenerMainPostConditions() or not Talent(serenity_talent) and { DebuffPresent(storm_earth_and_fire) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefMainPostConditions() or { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and WindwalkerSefMainPostConditions() or { not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefMainPostConditions() or { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefMainPostConditions() or Enemies() > 3 and WindwalkerAoeMainPostConditions() or Enemies() <= 3 and WindwalkerStMainPostConditions()
}

AddFunction WindwalkerDefaultShortCdActions
{
 #auto_attack
 WindwalkerGetInMeleeRange()
 #touch_of_karma,interval=90,pct_health=0.5,if=!talent.Good_Karma.enabled,interval=90,pct_health=0.5
 if not Talent(good_karma_talent) and CheckBoxOn(opt_touch_of_karma) Spell(touch_of_karma)
 #touch_of_karma,interval=90,pct_health=1.0,if=talent.good_karma.enabled&buff.bloodlust.down&time>1
 if Talent(good_karma_talent) and BuffExpires(burst_haste_buff any=1) and TimeInCombat() > 1 and CheckBoxOn(opt_touch_of_karma) Spell(touch_of_karma)
 #touch_of_karma,interval=90,pct_health=1.0,if=talent.good_karma.enabled&prev_gcd.1.touch_of_death&buff.bloodlust.up
 if Talent(good_karma_talent) and PreviousGCDSpell(touch_of_death) and BuffPresent(burst_haste_buff any=1) and CheckBoxOn(opt_touch_of_karma) Spell(touch_of_karma)
 #call_action_list,name=serenitySR,if=((talent.serenity.enabled&cooldown.serenity.remains<=0)|buff.serenity.up)&azerite.swift_roundhouse.rank>1&time>30
 if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and AzeriteTraitRank(swift_roundhouse_trait) > 1 and TimeInCombat() > 30 WindwalkerSerenitysrShortCdActions()

 unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and AzeriteTraitRank(swift_roundhouse_trait) > 1 and TimeInCombat() > 30 and WindwalkerSerenitysrShortCdPostConditions()
 {
  #call_action_list,name=serenity,if=((talent.serenity.enabled&cooldown.serenity.remains<=0)|buff.serenity.up)&time>30
  if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() > 30 WindwalkerSerenityShortCdActions()

  unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() > 30 and WindwalkerSerenityShortCdPostConditions()
  {
   #call_action_list,name=serenity_openerSR,if=(talent.serenity.enabled&cooldown.serenity.remains<=0|buff.serenity.up)&time<30&azerite.swift_roundhouse.enabled
   if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and HasAzeriteTrait(swift_roundhouse_trait) WindwalkerSerenityopenersrShortCdActions()

   unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and HasAzeriteTrait(swift_roundhouse_trait) and WindwalkerSerenityopenersrShortCdPostConditions()
   {
    #call_action_list,name=serenity_opener,if=(talent.serenity.enabled&cooldown.serenity.remains<=0|buff.serenity.up)&time<30
    if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 WindwalkerSerenityopenerShortCdActions()

    unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and WindwalkerSerenityopenerShortCdPostConditions()
    {
     #call_action_list,name=sef,if=!talent.serenity.enabled&(buff.storm_earth_and_fire.up|cooldown.storm_earth_and_fire.charges=2)
     if not Talent(serenity_talent) and { DebuffPresent(storm_earth_and_fire) or SpellCharges(storm_earth_and_fire) == 2 } WindwalkerSefShortCdActions()

     unless not Talent(serenity_talent) and { DebuffPresent(storm_earth_and_fire) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefShortCdPostConditions()
     {
      #call_action_list,name=sef,if=(!talent.serenity.enabled&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=25|cooldown.touch_of_death.remains>112
      if not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 WindwalkerSefShortCdActions()

      unless { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and WindwalkerSefShortCdPostConditions()
      {
       #call_action_list,name=sef,if=(!talent.serenity.enabled&!equipped.drinking_horn_cover&cooldown.fists_of_fury.remains<=6&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=15|cooldown.touch_of_death.remains>112&cooldown.storm_earth_and_fire.charges=1
       if not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefShortCdActions()

       unless { not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefShortCdPostConditions()
       {
        #call_action_list,name=sef,if=(!talent.serenity.enabled&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=25|cooldown.touch_of_death.remains>112&cooldown.storm_earth_and_fire.charges=1
        if not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefShortCdActions()

        unless { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefShortCdPostConditions()
        {
         #call_action_list,name=aoe,if=active_enemies>3
         if Enemies() > 3 WindwalkerAoeShortCdActions()

         unless Enemies() > 3 and WindwalkerAoeShortCdPostConditions()
         {
          #call_action_list,name=st,if=active_enemies<=3
          if Enemies() <= 3 WindwalkerStShortCdActions()
         }
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction WindwalkerDefaultShortCdPostConditions
{
 { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and AzeriteTraitRank(swift_roundhouse_trait) > 1 and TimeInCombat() > 30 and WindwalkerSerenitysrShortCdPostConditions() or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() > 30 and WindwalkerSerenityShortCdPostConditions() or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and HasAzeriteTrait(swift_roundhouse_trait) and WindwalkerSerenityopenersrShortCdPostConditions() or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and WindwalkerSerenityopenerShortCdPostConditions() or not Talent(serenity_talent) and { DebuffPresent(storm_earth_and_fire) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefShortCdPostConditions() or { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and WindwalkerSefShortCdPostConditions() or { not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefShortCdPostConditions() or { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefShortCdPostConditions() or Enemies() > 3 and WindwalkerAoeShortCdPostConditions() or Enemies() <= 3 and WindwalkerStShortCdPostConditions()
}

AddFunction WindwalkerDefaultCdActions
{
 #spear_hand_strike,if=target.debuff.casting.react
 if target.IsInterruptible() WindwalkerInterruptActions()

 unless not Talent(good_karma_talent) and CheckBoxOn(opt_touch_of_karma) and Spell(touch_of_karma) or Talent(good_karma_talent) and BuffExpires(burst_haste_buff any=1) and TimeInCombat() > 1 and CheckBoxOn(opt_touch_of_karma) and Spell(touch_of_karma) or Talent(good_karma_talent) and PreviousGCDSpell(touch_of_death) and BuffPresent(burst_haste_buff any=1) and CheckBoxOn(opt_touch_of_karma) and Spell(touch_of_karma)
 {
  #potion,if=buff.serenity.up|buff.storm_earth_and_fire.up|(!talent.serenity.enabled&trinket.proc.agility.react)|buff.bloodlust.react|target.time_to_die<=60
  if { DebuffPresent(serenity) or DebuffPresent(storm_earth_and_fire) or not Talent(serenity_talent) and BuffPresent(trinket_proc_agility_buff) or BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
  #touch_of_death,if=target.time_to_die<=9
  if target.TimeToDie() <= 9 and { not CheckBoxOn(opt_touch_of_death_on_elite_only) or not UnitInRaid() and target.Classification(elite) or target.Classification(worldboss) or not BuffExpires(hidden_masters_forbidden_touch_buff) } Spell(touch_of_death)
  #call_action_list,name=serenitySR,if=((talent.serenity.enabled&cooldown.serenity.remains<=0)|buff.serenity.up)&azerite.swift_roundhouse.rank>1&time>30
  if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and AzeriteTraitRank(swift_roundhouse_trait) > 1 and TimeInCombat() > 30 WindwalkerSerenitysrCdActions()

  unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and AzeriteTraitRank(swift_roundhouse_trait) > 1 and TimeInCombat() > 30 and WindwalkerSerenitysrCdPostConditions()
  {
   #call_action_list,name=serenity,if=((talent.serenity.enabled&cooldown.serenity.remains<=0)|buff.serenity.up)&time>30
   if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() > 30 WindwalkerSerenityCdActions()

   unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() > 30 and WindwalkerSerenityCdPostConditions()
   {
    #call_action_list,name=serenity_openerSR,if=(talent.serenity.enabled&cooldown.serenity.remains<=0|buff.serenity.up)&time<30&azerite.swift_roundhouse.enabled
    if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and HasAzeriteTrait(swift_roundhouse_trait) WindwalkerSerenityopenersrCdActions()

    unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and HasAzeriteTrait(swift_roundhouse_trait) and WindwalkerSerenityopenersrCdPostConditions()
    {
     #call_action_list,name=serenity_opener,if=(talent.serenity.enabled&cooldown.serenity.remains<=0|buff.serenity.up)&time<30
     if { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 WindwalkerSerenityopenerCdActions()

     unless { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and WindwalkerSerenityopenerCdPostConditions()
     {
      #call_action_list,name=sef,if=!talent.serenity.enabled&(buff.storm_earth_and_fire.up|cooldown.storm_earth_and_fire.charges=2)
      if not Talent(serenity_talent) and { DebuffPresent(storm_earth_and_fire) or SpellCharges(storm_earth_and_fire) == 2 } WindwalkerSefCdActions()

      unless not Talent(serenity_talent) and { DebuffPresent(storm_earth_and_fire) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefCdPostConditions()
      {
       #call_action_list,name=sef,if=(!talent.serenity.enabled&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=25|cooldown.touch_of_death.remains>112
       if not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 WindwalkerSefCdActions()

       unless { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and WindwalkerSefCdPostConditions()
       {
        #call_action_list,name=sef,if=(!talent.serenity.enabled&!equipped.drinking_horn_cover&cooldown.fists_of_fury.remains<=6&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=15|cooldown.touch_of_death.remains>112&cooldown.storm_earth_and_fire.charges=1
        if not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefCdActions()

        unless { not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefCdPostConditions()
        {
         #call_action_list,name=sef,if=(!talent.serenity.enabled&cooldown.fists_of_fury.remains<=12&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=25|cooldown.touch_of_death.remains>112&cooldown.storm_earth_and_fire.charges=1
         if not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 WindwalkerSefCdActions()

         unless { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefCdPostConditions()
         {
          #call_action_list,name=aoe,if=active_enemies>3
          if Enemies() > 3 WindwalkerAoeCdActions()

          unless Enemies() > 3 and WindwalkerAoeCdPostConditions()
          {
           #call_action_list,name=st,if=active_enemies<=3
           if Enemies() <= 3 WindwalkerStCdActions()
          }
         }
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction WindwalkerDefaultCdPostConditions
{
 not Talent(good_karma_talent) and CheckBoxOn(opt_touch_of_karma) and Spell(touch_of_karma) or Talent(good_karma_talent) and BuffExpires(burst_haste_buff any=1) and TimeInCombat() > 1 and CheckBoxOn(opt_touch_of_karma) and Spell(touch_of_karma) or Talent(good_karma_talent) and PreviousGCDSpell(touch_of_death) and BuffPresent(burst_haste_buff any=1) and CheckBoxOn(opt_touch_of_karma) and Spell(touch_of_karma) or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and AzeriteTraitRank(swift_roundhouse_trait) > 1 and TimeInCombat() > 30 and WindwalkerSerenitysrCdPostConditions() or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() > 30 and WindwalkerSerenityCdPostConditions() or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and HasAzeriteTrait(swift_roundhouse_trait) and WindwalkerSerenityopenersrCdPostConditions() or { Talent(serenity_talent) and SpellCooldown(serenity) <= 0 or DebuffPresent(serenity) } and TimeInCombat() < 30 and WindwalkerSerenityopenerCdPostConditions() or not Talent(serenity_talent) and { DebuffPresent(storm_earth_and_fire) or SpellCharges(storm_earth_and_fire) == 2 } and WindwalkerSefCdPostConditions() or { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 } and WindwalkerSefCdPostConditions() or { not Talent(serenity_talent) and not HasEquippedItem(drinking_horn_cover_item) and SpellCooldown(fists_of_fury) <= 6 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 15 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefCdPostConditions() or { not Talent(serenity_talent) and SpellCooldown(fists_of_fury) <= 12 and Chi() >= 3 and SpellCooldown(rising_sun_kick) <= 1 or target.TimeToDie() <= 25 or SpellCooldown(touch_of_death) > 112 and SpellCharges(storm_earth_and_fire) == 1 } and WindwalkerSefCdPostConditions() or Enemies() > 3 and WindwalkerAoeCdPostConditions() or Enemies() <= 3 and WindwalkerStCdPostConditions()
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
# battle_potion_of_agility
# berserking
# blackout_kick_buff
# blackout_kick_windwalker
# blood_fury_apsp
# chi_burst
# chi_wave
# crackling_jade_lightning
# drinking_horn_cover_item
# energizing_elixir
# energizing_elixir_talent
# fireblood
# fist_of_the_white_tiger
# fist_of_the_white_tiger_talent
# fists_of_fury
# flying_serpent_kick
# good_karma_talent
# hidden_masters_forbidden_touch_buff
# invoke_xuen_the_white_tiger
# leg_sweep
# lights_judgment
# mark_of_the_crane_debuff
# paralysis
# quaking_palm
# rising_sun_kick
# rushing_jade_wind_talent_windwalker
# rushing_jade_wind_windwalker
# serenity
# serenity_talent
# spear_hand_strike
# spinning_crane_kick
# storm_earth_and_fire
# swift_roundhouse_buff
# swift_roundhouse_trait
# the_emperors_capacitor_buff
# the_emperors_capacitor_item
# tiger_palm
# touch_of_death
# touch_of_karma
# war_stomp
# whirling_dragon_punch
]]
    OvaleScripts:RegisterScript("MONK", "windwalker", name, desc, code, "script")
end
