local __exports = LibStub:GetLibrary("ovale/scripts/ovale_monk")
if not __exports then return end
__exports.registerMonkBrewmasterHooves = function(OvaleScripts)
do
	local name = "hooves_brewmaster"
	local desc = "[Hooves][8.2] Monk: Brewmaster"
	local code = [[
Include(ovale_common)

Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

Define(ring_of_peace 116844)
Define(leg_sweep 119381)

# Brewmaster
AddIcon specialization=1 help=main
{
	if InCombat() InterruptActions()
	
	if target.InRange(tiger_palm) and HasFullControl()
	{
		if Boss() BrewmasterDefaultCdActions()
		BrewmasterDefaultShortCdActions()
		if Talent(blackout_combo_talent) BrewmasterBlackoutComboMainActions()
		unless Talent(blackout_combo_talent) 
		{
			BrewmasterDefaultMainActions()
		}
	}
}

AddFunction Boss
{
	IsBossFight() or BuffPresent(burst_haste_buff any=1) or { target.IsPvP() and not target.IsFriend() } 
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(spear_hand_strike) Spell(spear_hand_strike)
		if not target.Classification(worldboss)
		{
			if target.InRange(paralysis) Spell(paralysis)
			if target.InRange(spear_hand_strike) Spell(arcane_torrent_chi)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			if target.InRange(spear_hand_strike) Spell(leg_sweep)
			if target.InRange(spear_hand_strike) Spell(ring_of_peace)
			if target.InRange(spear_hand_strike) Spell(war_stomp)
		}
	}
}

### actions.default

AddFunction BrewmasterExpelHarmOffensivelyPreConditions
{
	(SpellCount(expel_harm) >= 3 and (SpellCount(expel_harm) * 7.5 * AttackPower() * 2.65) <= HealthMissing()) and Spell(expel_harm)
}
AddFunction BrewmasterHealMe
{
	if (HealthPercent() < 35) Spell(healing_elixir)
	if (HealthPercent() < 35) Spell(expel_harm)
	if (HealthPercent() <= 100 - (15 * 2.6)) Spell(healing_elixir)
}

AddFunction StaggerPercentage
{
	StaggerRemaining() / MaxHealth() * 100
}

AddFunction BrewmasterRangeCheck
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction BrewMasterIronskinMin
{
	if(DebuffRemaining(any_stagger_debuff) > BaseDuration(ironskin_brew_buff)) BaseDuration(ironskin_brew_buff)
	DebuffRemaining(any_stagger_debuff)
}
AddFunction BrewmasterDefaultShortCdActions
{
	# keep ISB up always when taking dmg
	if BuffRemaining(ironskin_brew_buff) < BrewMasterIronskinMin() Spell(ironskin_brew text=min)
	
	# keep stagger below 100% (or 30% when BOB is up)
	if (StaggerPercentage() >= 100 or (StaggerPercentage() >= 30 and Talent(black_ox_brew_talent) and SpellCooldown(black_ox_brew) <= 0)) Spell(purifying_brew)
	# use black_ox_brew when at 0 charges and low energy (or in an emergency)
	if ((SpellCharges(purifying_brew) == 0) and (Energy() < 40 or StaggerPercentage() >= 60 or BuffRemaining(ironskin_brew_buff) < BrewMasterIronskinMin())) Spell(black_ox_brew)
	# heal mean
	BrewmasterHealMe()
	# range check
	BrewmasterRangeCheck()
	unless StaggerPercentage() > 100 or BrewmasterHealMe()
	{
		# purify heavy stagger when we have enough ISB
		if (StaggerPercentage() >= 60 and (BuffRemaining(ironskin_brew_buff) >= 2*BaseDuration(ironskin_brew_buff))) Spell(purifying_brew)
		# always bank 1 charge (or bank 2 with light_brewing)
		unless (SpellCharges(ironskin_brew count=0) <= SpellData(ironskin_brew charges)-2)
		{
			# never be at (almost) max charges 
			unless (SpellFullRecharge(ironskin_brew) > 3)
			{
				if (BuffRemaining(ironskin_brew_buff) < 2*BaseDuration(ironskin_brew_buff)) Spell(ironskin_brew text=max)
				if (StaggerPercentage() > 30 or Talent(special_delivery_talent)) Spell(purifying_brew text=max)
			}
			
			# keep brew-stache rolling
			if (IncomingDamage(4 physical=1)>0 and HasArtifactTrait(brew_stache_trait) and BuffExpires(brew_stache_buff)) 
			{
				if (BuffRemaining(ironskin_brew_buff) < 2*BaseDuration(ironskin_brew_buff)) Spell(ironskin_brew text=stache)
				if (StaggerPercentage() > 30) Spell(purifying_brew text=stache)
			}
			# purify stagger when talent elusive dance 
			if (Talent(elusive_dance_talent) and BuffExpires(elusive_dance_buff)) Spell(purifying_brew)
		}
	}
}

#
# Single-Target
#

AddFunction BrewmasterDefaultMainActions
{
	 #invoke_niuzao,if=target.time_to_die>45
 if target.TimeToDie() > 45 Spell(invoke_niuzao_the_black_ox)
 #keg_smash,if=spell_targets>=3
 if Enemies(tagged=1) >= 3 Spell(keg_smash)
 #tiger_palm,if=buff.blackout_combo.up
 if BuffPresent(blackout_combo_buff) Spell(tiger_palm)
 #keg_smash
 Spell(keg_smash)
 #blackout_strike
 Spell(blackout_strike)
 #breath_of_fire,if=buff.blackout_combo.down&(buff.bloodlust.down|(buff.bloodlust.up&&dot.breath_of_fire_dot.refreshable))
 if BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_dot_debuff) } Spell(breath_of_fire)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down
 if BuffExpires(rushing_jade_wind_buff) Spell(rushing_jade_wind)
 #chi_burst
 if CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #chi_wave
 Spell(chi_wave)
 #tiger_palm,if=!talent.blackout_combo.enabled&cooldown.keg_smash.remains>gcd&(energy+(energy.regen*(cooldown.keg_smash.remains+gcd)))>=55
 if not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 55 Spell(tiger_palm)
}

AddFunction BrewmasterBlackoutComboMainActions
{
	 #invoke_niuzao,if=target.time_to_die>45
 if target.TimeToDie() > 45 Spell(invoke_niuzao_the_black_ox)
 #keg_smash,if=spell_targets>=3
 if Enemies(tagged=1) >= 3 Spell(keg_smash)
 #tiger_palm,if=buff.blackout_combo.up
 if BuffPresent(blackout_combo_buff) Spell(tiger_palm)
 #keg_smash
 Spell(keg_smash)
 #blackout_strike
 Spell(blackout_strike)
 #breath_of_fire,if=buff.blackout_combo.down&(buff.bloodlust.down|(buff.bloodlust.up&&dot.breath_of_fire_dot.refreshable))
 if BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_dot_debuff) } Spell(breath_of_fire)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down
 if BuffExpires(rushing_jade_wind_buff) Spell(rushing_jade_wind)
 #chi_burst
 if CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #chi_wave
 Spell(chi_wave)
 #tiger_palm,if=!talent.blackout_combo.enabled&cooldown.keg_smash.remains>gcd&(energy+(energy.regen*(cooldown.keg_smash.remains+gcd)))>=55
 if not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 55 Spell(tiger_palm)
}

#
# AOE
#

AddFunction BrewmasterDefaultAoEActions
{
	 #invoke_niuzao,if=target.time_to_die>45
 if target.TimeToDie() > 45 Spell(invoke_niuzao_the_black_ox)
 #keg_smash,if=spell_targets>=3
 if Enemies(tagged=1) >= 3 Spell(keg_smash)
 #tiger_palm,if=buff.blackout_combo.up
 if BuffPresent(blackout_combo_buff) Spell(tiger_palm)
 #keg_smash
 Spell(keg_smash)
 #blackout_strike
 Spell(blackout_strike)
 #breath_of_fire,if=buff.blackout_combo.down&(buff.bloodlust.down|(buff.bloodlust.up&&dot.breath_of_fire_dot.refreshable))
 if BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_dot_debuff) } Spell(breath_of_fire)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down
 if BuffExpires(rushing_jade_wind_buff) Spell(rushing_jade_wind)
 #chi_burst
 if CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #chi_wave
 Spell(chi_wave)
 #tiger_palm,if=!talent.blackout_combo.enabled&cooldown.keg_smash.remains>gcd&(energy+(energy.regen*(cooldown.keg_smash.remains+gcd)))>=55
 if not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 55 Spell(tiger_palm)
}

AddFunction BrewmasterBlackoutComboAoEActions
{
 #invoke_niuzao,if=target.time_to_die>45
 if target.TimeToDie() > 45 Spell(invoke_niuzao_the_black_ox)
 #keg_smash,if=spell_targets>=3
 if Enemies(tagged=1) >= 3 Spell(keg_smash)
 #tiger_palm,if=buff.blackout_combo.up
 if BuffPresent(blackout_combo_buff) Spell(tiger_palm)
 #keg_smash
 Spell(keg_smash)
 #blackout_strike
 Spell(blackout_strike)
 #breath_of_fire,if=buff.blackout_combo.down&(buff.bloodlust.down|(buff.bloodlust.up&&dot.breath_of_fire_dot.refreshable))
 if BuffExpires(blackout_combo_buff) and { BuffExpires(burst_haste_buff any=1) or BuffPresent(burst_haste_buff any=1) and target.DebuffRefreshable(breath_of_fire_dot_debuff) } Spell(breath_of_fire)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down
 if BuffExpires(rushing_jade_wind_buff) Spell(rushing_jade_wind)
 #chi_burst
 if CheckBoxOn(opt_chi_burst) Spell(chi_burst)
 #chi_wave
 Spell(chi_wave)
 #tiger_palm,if=!talent.blackout_combo.enabled&cooldown.keg_smash.remains>gcd&(energy+(energy.regen*(cooldown.keg_smash.remains+gcd)))>=55
 if not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 55 Spell(tiger_palm)
}

AddFunction BrewmasterDefaultCdActions 
{
	# BrewmasterInterruptActions()
	# if CheckBoxOn(opt_legendary_ring_tank) Item(legendary_ring_bonus_armor usable=1)
	#if not PetPresent(name=Niuzao) Spell(invoke_niuzao_the_black_ox)
	# Item(Trinket0Slot usable=1 text=13)
	# Item(Trinket1Slot usable=1 text=14)
	#if (HasEquippedItem(fundamental_observation)) Spell(zen_meditation)
	#Spell(fortifying_brew)
	#Spell(zen_meditation)
	#Spell(dampen_harm)
	# Item(unbending_potion usable=1)
}
]]

		OvaleScripts:RegisterScript("MONK", "brewmaster", name, desc, code, "script")
	end
end
