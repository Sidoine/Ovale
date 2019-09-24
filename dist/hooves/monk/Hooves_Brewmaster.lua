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
	if not Mounted()
	{
		#if InCombat() InterruptActions()
		
		if target.InRange(tiger_palm) and HasFullControl()
		{
			if Boss() BrewmasterDefaultCdActions()
			BrewmasterDefaultShortCdActions()
			BrewmasterDefaultMainActions()
		}
	}
}

AddFunction BrewmasterHealMe
{
	if (HealthPercent() < 35) Spell(healing_elixir)
	if (HealthPercent() < 35) Spell(expel_harm)
	if (HealthPercent() <= 100 - (15 * 2.6)) Spell(healing_elixir)
} 
AddFunction BrewMasterIronskinMin
{
	if(DebuffRemaining(any_stagger_debuff) > BaseDuration(ironskin_brew_buff)) BaseDuration(ironskin_brew_buff)
	DebuffRemaining(any_stagger_debuff)
}


AddFunction StaggerPercentage
{
	StaggerRemaining() / MaxHealth() * 100
}

AddFunction BrewmasterUseHeartEssence
{
 Spell(concentrated_flame_essence)
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

AddFunction BrewmasterDefaultMainActions
{
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_superior_battle_potion_of_agility usable=1)
 #black_ox_brew,if=cooldown.brews.charges_fractional<0.5
 if SpellCharges(ironskin_brew count=0) < 0.5 Spell(black_ox_brew)
 #black_ox_brew,if=(energy+(energy.regen*cooldown.keg_smash.remains))<40&buff.blackout_combo.down&cooldown.keg_smash.up
 if Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) < 40 and BuffExpires(blackout_combo_buff) and not SpellCooldown(keg_smash) > 0 Spell(black_ox_brew)
 #keg_smash,if=spell_targets>=2
 if enemies(tagged=1) >= 2 Spell(keg_smash)
 #tiger_palm,if=talent.rushing_jade_wind.enabled&buff.blackout_combo.up&buff.rushing_jade_wind.up
 if Talent(rushing_jade_wind_talent) and BuffPresent(blackout_combo_buff) and BuffPresent(rushing_jade_wind_buff) Spell(tiger_palm)
 #tiger_palm,if=(talent.invoke_niuzao_the_black_ox.enabled|talent.special_delivery.enabled)&buff.blackout_combo.up
 if { Talent(invoke_niuzao_the_black_ox_talent) or Talent(special_delivery_talent) } and BuffPresent(blackout_combo_buff) Spell(tiger_palm)
 #expel_harm,if=buff.gift_of_the_ox.stack>4
 if BuffStacks(gift_of_the_ox) > 4 Spell(expel_harm)
 #blackout_strike
 Spell(blackout_strike)
 #keg_smash
 Spell(keg_smash)
 #concentrated_flame,if=dot.concentrated_flame.remains=0
 if not target.DebuffRemaining(concentrated_flame_essence) > 0 Spell(concentrated_flame_essence)
 #expel_harm,if=buff.gift_of_the_ox.stack>=3
 if BuffStacks(gift_of_the_ox) >= 3 Spell(expel_harm)
 #rushing_jade_wind,if=buff.rushing_jade_wind.down
 if BuffExpires(rushing_jade_wind_buff) Spell(rushing_jade_wind)
 #breath_of_fire,if=buff.blackout_combo.down&(buff.bloodlust.down|(buff.bloodlust.up&&dot.breath_of_fire_dot.refreshable))
 if BuffExpires(blackout_combo_buff) and { BuffExpires(bloodlust) or BuffPresent(bloodlust) and target.DebuffRefreshable(breath_of_fire_debuff) } Spell(breath_of_fire)
 #chi_burst
 if Speed() == 0 Spell(chi_burst)
 #chi_wave
 Spell(chi_wave)
 #expel_harm,if=buff.gift_of_the_ox.stack>=2
 if BuffStacks(gift_of_the_ox) >= 2 Spell(expel_harm)
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
 

# keep ISB up always when taking dmg
	if BuffRemaining(ironskin_brew_buff) < BrewMasterIronskinMin() Spell(ironskin_brew text=min)
	
	# keep stagger below 100% (or 30% when BOB is up)
	if (StaggerPercentage() >= 100 or (StaggerPercentage() >= 30 and Talent(black_ox_brew_talent) and SpellCooldown(black_ox_brew) <= 0)) Spell(purifying_brew)
	# use black_ox_brew when at 0 charges and low energy (or in an emergency)
	if ((SpellCharges(purifying_brew) == 0) and (Energy() < 40 or StaggerPercentage() >= 60 or BuffRemaining(ironskin_brew_buff) < BrewMasterIronskinMin())) Spell(black_ox_brew)
	# heal mean
	BrewmasterHealMe()
	# range check
	
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

AddFunction BrewmasterDefaultShortCdPostConditions
{
 CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(item_superior_battle_potion_of_agility usable=1) or SpellCharges(ironskin_brew count=0) < 0.5 and Spell(black_ox_brew) or Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) < 40 and BuffExpires(blackout_combo_buff) and not SpellCooldown(keg_smash) > 0 and Spell(black_ox_brew) or enemies(tagged=1) >= 2 and Spell(keg_smash) or Talent(rushing_jade_wind_talent) and BuffPresent(blackout_combo_buff) and BuffPresent(rushing_jade_wind_buff) and Spell(tiger_palm) or { Talent(invoke_niuzao_the_black_ox_talent) or Talent(special_delivery_talent) } and BuffPresent(blackout_combo_buff) and Spell(tiger_palm) or BuffStacks(gift_of_the_ox) > 4 and Spell(expel_harm) or Spell(blackout_strike) or Spell(keg_smash) or not target.DebuffRemaining(concentrated_flame_essence) > 0 and Spell(concentrated_flame_essence) or BuffStacks(gift_of_the_ox) >= 3 and Spell(expel_harm) or BuffExpires(rushing_jade_wind_buff) and Spell(rushing_jade_wind) or BuffExpires(blackout_combo_buff) and { BuffExpires(bloodlust) or BuffPresent(bloodlust) and target.DebuffRefreshable(breath_of_fire_debuff) } and Spell(breath_of_fire) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave) or BuffStacks(gift_of_the_ox) >= 2 and Spell(expel_harm) or not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 65 and Spell(tiger_palm) or Spell(rushing_jade_wind)
}

AddFunction BrewmasterDefaultCdActions
{
 #BrewmasterInterruptActions()
 #gift_of_the_ox,if=health<health.max*0.65
 #dampen_harm,if=incoming_damage_1500ms&buff.fortifying_brew.down
 if IncomingDamage(1.5) > 0 and BuffExpires(fortifying_brew_buff) Spell(dampen_harm)
 #fortifying_brew,if=incoming_damage_1500ms&(buff.dampen_harm.down|buff.diffuse_magic.down)
 if IncomingDamage(1.5) > 0 and { BuffExpires(dampen_harm) or BuffExpires(diffuse_magic) } Spell(fortifying_brew)
 #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.conductive_ink_debuff.up&target.health.pct<31|target.time_to_die<20
 #if target.DebuffExpires(razor_coral_debuff) or target.DebuffPresent(conductive_ink_debuff) and target.HealthPercent() < 31 or target.TimeToDie() < 20 BrewmasterUseItemActions()
 #use_items
 #BrewmasterUseItemActions()

 unless CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(item_superior_battle_potion_of_agility usable=1)
 {
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

  unless SpellCharges(ironskin_brew count=0) < 0.5 and Spell(black_ox_brew) or Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) < 40 and BuffExpires(blackout_combo_buff) and not SpellCooldown(keg_smash) > 0 and Spell(black_ox_brew) or enemies(tagged=1) >= 2 and Spell(keg_smash) or Talent(rushing_jade_wind_talent) and BuffPresent(blackout_combo_buff) and BuffPresent(rushing_jade_wind_buff) and Spell(tiger_palm) or { Talent(invoke_niuzao_the_black_ox_talent) or Talent(special_delivery_talent) } and BuffPresent(blackout_combo_buff) and Spell(tiger_palm) or BuffStacks(gift_of_the_ox) > 4 and Spell(expel_harm) or Spell(blackout_strike) or Spell(keg_smash) or not target.DebuffRemaining(concentrated_flame_essence) > 0 and Spell(concentrated_flame_essence)
  {
   #heart_essence,if=!essence.the_crucible_of_flame.major
   if not AzeriteEssenceIsMajor(the_crucible_of_flame_essence_id) BrewmasterUseHeartEssence()

   unless BuffStacks(gift_of_the_ox) >= 3 and Spell(expel_harm) or BuffExpires(rushing_jade_wind_buff) and Spell(rushing_jade_wind) or BuffExpires(blackout_combo_buff) and { BuffExpires(bloodlust) or BuffPresent(bloodlust) and target.DebuffRefreshable(breath_of_fire_debuff) } and Spell(breath_of_fire) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave) or BuffStacks(gift_of_the_ox) >= 2 and Spell(expel_harm) or not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 65 and Spell(tiger_palm)
   {
    #arcane_torrent,if=energy<31
    if Energy() < 31 Spell(arcane_torrent_chi)
   }
  }
 }
}

AddFunction BrewmasterDefaultCdPostConditions
{
 CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(item_superior_battle_potion_of_agility usable=1) or SpellCharges(ironskin_brew count=0) < 0.5 and Spell(black_ox_brew) or Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) < 40 and BuffExpires(blackout_combo_buff) and not SpellCooldown(keg_smash) > 0 and Spell(black_ox_brew) or enemies(tagged=1) >= 2 and Spell(keg_smash) or Talent(rushing_jade_wind_talent) and BuffPresent(blackout_combo_buff) and BuffPresent(rushing_jade_wind_buff) and Spell(tiger_palm) or { Talent(invoke_niuzao_the_black_ox_talent) or Talent(special_delivery_talent) } and BuffPresent(blackout_combo_buff) and Spell(tiger_palm) or BuffStacks(gift_of_the_ox) > 4 and Spell(expel_harm) or Spell(blackout_strike) or Spell(keg_smash) or not target.DebuffRemaining(concentrated_flame_essence) > 0 and Spell(concentrated_flame_essence) or BuffStacks(gift_of_the_ox) >= 3 and Spell(expel_harm) or BuffExpires(rushing_jade_wind_buff) and Spell(rushing_jade_wind) or BuffExpires(blackout_combo_buff) and { BuffExpires(bloodlust) or BuffPresent(bloodlust) and target.DebuffRefreshable(breath_of_fire_debuff) } and Spell(breath_of_fire) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave) or BuffStacks(gift_of_the_ox) >= 2 and Spell(expel_harm) or not Talent(blackout_combo_talent) and SpellCooldown(keg_smash) > GCD() and Energy() + EnergyRegenRate() * { SpellCooldown(keg_smash) + GCD() } >= 65 and Spell(tiger_palm) or Spell(rushing_jade_wind)
}

### actions.precombat

AddFunction BrewmasterPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 #if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_superior_battle_potion_of_agility usable=1)
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
 CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(item_superior_battle_potion_of_agility usable=1) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}

AddFunction BrewmasterPrecombatCdActions
{
}

AddFunction BrewmasterPrecombatCdPostConditions
{
 CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(item_superior_battle_potion_of_agility usable=1) or CheckBoxOn(opt_chi_burst) and Spell(chi_burst) or Spell(chi_wave)
}
]]

		OvaleScripts:RegisterScript("MONK", "brewmaster", name, desc, code, "script")
	end
end
