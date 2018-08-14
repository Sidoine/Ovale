local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "icyveins_warrior_protection"
    local desc = "[7.3.2] Icy-Veins: Warrior Protection"
    local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=protection)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=protection)
AddCheckBox(opt_warrior_protection_aoe L(AOE) default specialization=protection)

AddFunction ProtectionHealMe
{
	unless(DebuffPresent(healing_immunity_debuff)) 
	{
		if HealthPercent() < 70 Spell(victory_rush)
		if HealthPercent() < 85 Spell(impending_victory)
		if (HealthPercent() < 35) UseHealthPotions()
	}
}

AddFunction ProtectionGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not InFlightToTarget(intercept) and not InFlightToTarget(heroic_leap)
	{
		if target.InRange(intercept) Spell(intercept)
		if SpellCharges(intercept) == 0 and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
		if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction ProtectionInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
	{
		if target.InRange(pummel) and target.IsInterruptible() Spell(pummel)
		if target.InRange(storm_bolt) and not target.Classification(worldboss) Spell(storm_bolt)
		if target.InRange(intercept) and not target.Classification(worldboss) and Talent(warbringer_talent) Spell(intercept)
		if target.Distance(less 10) and not target.Classification(worldboss) Spell(shockwave)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
		if target.InRange(intimidating_shout) and not target.Classification(worldboss) Spell(intimidating_shout)
	}
}

AddFunction ProtectionOffensiveCooldowns
{
	Spell(avatar)
	Spell(battle_cry)
	if (Talent(booming_voice_talent) and RageDeficit() >= Talent(booming_voice_talent)*60) Spell(demoralizing_shout)
}

#
# Short
#

AddFunction ProtectionDefaultShortCDActions
{
	ProtectionHealMe()
	if ArmorSetBonus(T20 2) and RageDeficit() >= 26 Spell(berserker_rage)
	if IncomingDamage(5 physical=1) 
	{
		if not BuffPresent(shield_block_buff) and SpellFullRecharge(shield_block) > 3 Spell(neltharions_fury)
		if not BuffPresent(neltharions_fury_buff) and (SpellCooldown(neltharions_fury)>0 or SpellCharges(shield_block) == SpellMaxCharges(shield_block)) Spell(shield_block)
	}
	if ((not BuffPresent(renewed_fury_buff) and Talent(renewed_fury_talent)) or Rage() >= 60) Spell(ignore_pain)
	# range check
	ProtectionGetInMeleeRange()
}

#
# Single-Target
#

AddFunction ProtectionDefaultMainActions
{
	Spell(shield_slam)
	if Talent(devastatator_talent) and BuffPresent(revenge_buff) Spell(revenge)
	if BuffPresent(vengeance_revenge_buff) Spell(revenge)
	Spell(thunder_clap)
	if BuffPresent(revenge_buff) Spell(revenge)
	Spell(storm_bolt)
	Spell(devastate)
}

#
# AOE
#

AddFunction ProtectionDefaultAoEActions
{
	Spell(ravager)
	Spell(revenge)
	Spell(thunder_clap)
	Spell(shield_slam)
	if Enemies() >= 3 Spell(shockwave)
	Spell(devastate)
}

#
# Cooldowns
#

AddFunction ProtectionDefaultCdActions 
{
	ProtectionInterruptActions()
	ProtectionOffensiveCooldowns()
	if IncomingDamage(1.5 magic=1) > 0 Spell(spell_reflection)
	if (HasEquippedItem(shifting_cosmic_sliver)) Spell(shield_wall)
	Item(Trinket0Slot usable=1 text=13)
	Item(Trinket1Slot usable=1 text=14)
	Spell(demoralizing_shout)
	Spell(shield_wall)
	Spell(last_stand)
	
}

#
# Icons
#

AddIcon help=shortcd specialization=protection
{
	ProtectionDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=protection
{
	ProtectionDefaultMainActions()
}

AddIcon checkbox=opt_warrior_protection_aoe help=aoe specialization=protection
{
	ProtectionDefaultAoEActions()
}

AddIcon help=cd specialization=protection
{
	ProtectionDefaultCdActions()
}
]]
    OvaleScripts:RegisterScript("WARRIOR", "protection", name, desc, code, "script")
end
do
    local name = "sc_pr_warrior_arms"
    local desc = "[8.0] Simulationcraft: PR_Warrior_Arms"
    local code = [[
# Based on SimulationCraft profile "PR_Warrior_Arms".
#	class=warrior
#	spec=arms
#	talents=3312211

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=arms)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=arms)

AddFunction ArmsGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not InFlightToTarget(charge) and not InFlightToTarget(heroic_leap)
 {
  if target.InRange(charge) Spell(charge)
  if SpellCharges(charge) == 0 and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
  if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.single_target

AddFunction ArmsSingletargetMainActions
{
 #rend,if=remains<=duration*0.3&debuff.colossus_smash.down
 if target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0 and target.DebuffExpires(colossus_smash_debuff) Spell(rend)
 #skullsplitter,if=rage<70&(cooldown.deadly_calm.remains>3|!talent.deadly_calm.enabled)
 if Rage() < 70 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } Spell(skullsplitter)
 #colossus_smash,if=debuff.colossus_smash.down
 if target.DebuffExpires(colossus_smash_debuff) Spell(colossus_smash)
 #warbreaker,if=debuff.colossus_smash.down
 if target.DebuffExpires(colossus_smash_debuff) Spell(warbreaker)
 #execute,if=buff.sudden_death.react|buff.stone_heart.react
 if BuffPresent(sudden_death_arms_buff) or BuffPresent(stone_heart_buff) Spell(execute_arms)
 #cleave,if=spell_targets.whirlwind>2
 if Enemies() > 2 Spell(cleave)
 #mortal_strike
 Spell(mortal_strike)
 #overpower
 Spell(overpower)
 #whirlwind,if=talent.fervor_of_battle.enabled&(rage>=50|debuff.colossus_smash.up)
 if Talent(fervor_of_battle_talent) and { Rage() >= 50 or target.DebuffPresent(colossus_smash_debuff) } Spell(whirlwind_arms)
 #slam,if=!talent.fervor_of_battle.enabled&(rage>=40|debuff.colossus_smash.up)
 if not Talent(fervor_of_battle_talent) and { Rage() >= 40 or target.DebuffPresent(colossus_smash_debuff) } Spell(slam)
}

AddFunction ArmsSingletargetMainPostConditions
{
}

AddFunction ArmsSingletargetShortCdActions
{
 unless target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0 and target.DebuffExpires(colossus_smash_debuff) and Spell(rend) or Rage() < 70 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } and Spell(skullsplitter)
 {
  #deadly_calm,if=cooldown.bladestorm.remains>6&((cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))|(equipped.weight_of_the_earth&cooldown.heroic_leap.remains<2))
  if SpellCooldown(bladestorm_arms) > 6 and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 or HasEquippedItem(weight_of_the_earth_item) and SpellCooldown(heroic_leap) < 2 } Spell(deadly_calm)

  unless target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker)
  {
   #heroic_leap,if=equipped.weight_of_the_earth&debuff.colossus_smash.down&((cooldown.colossus_smash.remains>8&!prev_gcd.1.colossus_smash)|(talent.warbreaker.enabled&cooldown.warbreaker.remains>8&!prev_gcd.1.warbreaker))
   if HasEquippedItem(weight_of_the_earth_item) and target.DebuffExpires(colossus_smash_debuff) and { SpellCooldown(colossus_smash) > 8 and not PreviousGCDSpell(colossus_smash) or Talent(warbreaker_talent) and SpellCooldown(warbreaker) > 8 and not PreviousGCDSpell(warbreaker) } and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)

   unless { BuffPresent(sudden_death_arms_buff) or BuffPresent(stone_heart_buff) } and Spell(execute_arms)
   {
    #bladestorm,if=buff.sweeping_strikes.down&debuff.colossus_smash.remains>4.5&(prev_gcd.1.mortal_strike|spell_targets.whirlwind>1)&(!buff.deadly_calm.up|!talent.deadly_calm.enabled)
    if BuffExpires(sweeping_strikes_buff) and target.DebuffRemaining(colossus_smash_debuff) > 4 and { PreviousGCDSpell(mortal_strike) or Enemies() > 1 } and { not BuffPresent(deadly_calm_buff) or not Talent(deadly_calm_talent) } Spell(bladestorm_arms)
    #ravager,if=debuff.colossus_smash.up&(cooldown.deadly_calm.remains>6|!talent.deadly_calm.enabled)
    if target.DebuffPresent(colossus_smash_debuff) and { SpellCooldown(deadly_calm) > 6 or not Talent(deadly_calm_talent) } Spell(ravager)
   }
  }
 }
}

AddFunction ArmsSingletargetShortCdPostConditions
{
 target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0 and target.DebuffExpires(colossus_smash_debuff) and Spell(rend) or Rage() < 70 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } and Spell(skullsplitter) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or { BuffPresent(sudden_death_arms_buff) or BuffPresent(stone_heart_buff) } and Spell(execute_arms) or Enemies() > 2 and Spell(cleave) or Spell(mortal_strike) or Spell(overpower) or Talent(fervor_of_battle_talent) and { Rage() >= 50 or target.DebuffPresent(colossus_smash_debuff) } and Spell(whirlwind_arms) or not Talent(fervor_of_battle_talent) and { Rage() >= 40 or target.DebuffPresent(colossus_smash_debuff) } and Spell(slam)
}

AddFunction ArmsSingletargetCdActions
{
}

AddFunction ArmsSingletargetCdPostConditions
{
 target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0 and target.DebuffExpires(colossus_smash_debuff) and Spell(rend) or Rage() < 70 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } and Spell(skullsplitter) or SpellCooldown(bladestorm_arms) > 6 and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 or HasEquippedItem(weight_of_the_earth_item) and SpellCooldown(heroic_leap) < 2 } and Spell(deadly_calm) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or HasEquippedItem(weight_of_the_earth_item) and target.DebuffExpires(colossus_smash_debuff) and { SpellCooldown(colossus_smash) > 8 and not PreviousGCDSpell(colossus_smash) or Talent(warbreaker_talent) and SpellCooldown(warbreaker) > 8 and not PreviousGCDSpell(warbreaker) } and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) and Spell(heroic_leap) or { BuffPresent(sudden_death_arms_buff) or BuffPresent(stone_heart_buff) } and Spell(execute_arms) or BuffExpires(sweeping_strikes_buff) and target.DebuffRemaining(colossus_smash_debuff) > 4 and { PreviousGCDSpell(mortal_strike) or Enemies() > 1 } and { not BuffPresent(deadly_calm_buff) or not Talent(deadly_calm_talent) } and Spell(bladestorm_arms) or target.DebuffPresent(colossus_smash_debuff) and { SpellCooldown(deadly_calm) > 6 or not Talent(deadly_calm_talent) } and Spell(ravager) or Enemies() > 2 and Spell(cleave) or Spell(mortal_strike) or Spell(overpower) or Talent(fervor_of_battle_talent) and { Rage() >= 50 or target.DebuffPresent(colossus_smash_debuff) } and Spell(whirlwind_arms) or not Talent(fervor_of_battle_talent) and { Rage() >= 40 or target.DebuffPresent(colossus_smash_debuff) } and Spell(slam)
}

### actions.precombat

AddFunction ArmsPrecombatMainActions
{
}

AddFunction ArmsPrecombatMainPostConditions
{
}

AddFunction ArmsPrecombatShortCdActions
{
}

AddFunction ArmsPrecombatShortCdPostConditions
{
}

AddFunction ArmsPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_strength usable=1)
}

AddFunction ArmsPrecombatCdPostConditions
{
}

### actions.five_target

AddFunction ArmsFivetargetMainActions
{
 #skullsplitter,if=rage<70&(cooldown.deadly_calm.remains>3|!talent.deadly_calm.enabled)
 if Rage() < 70 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } Spell(skullsplitter)
 #colossus_smash,if=debuff.colossus_smash.down
 if target.DebuffExpires(colossus_smash_debuff) Spell(colossus_smash)
 #warbreaker,if=debuff.colossus_smash.down
 if target.DebuffExpires(colossus_smash_debuff) Spell(warbreaker)
 #cleave
 Spell(cleave)
 #execute,if=(!talent.cleave.enabled&dot.deep_wounds.remains<2)|(buff.sudden_death.react|buff.stone_heart.react)&(buff.sweeping_strikes.up|cooldown.sweeping_strikes.remains>8)
 if not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or { BuffPresent(sudden_death_arms_buff) or BuffPresent(stone_heart_buff) } and { BuffPresent(sweeping_strikes_buff) or SpellCooldown(sweeping_strikes) > 8 } Spell(execute_arms)
 #mortal_strike,if=(!talent.cleave.enabled&dot.deep_wounds.remains<2)|buff.sweeping_strikes.up&buff.overpower.stack=2&(talent.dreadnaught.enabled|equipped.archavons_heavy_hand)
 if not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sweeping_strikes_buff) and BuffStacks(overpower_buff) == 2 and { Talent(dreadnaught_talent) or HasEquippedItem(archavons_heavy_hand_item) } Spell(mortal_strike)
 #whirlwind,if=debuff.colossus_smash.up
 if target.DebuffPresent(colossus_smash_debuff) Spell(whirlwind_arms)
 #overpower
 Spell(overpower)
 #whirlwind
 Spell(whirlwind_arms)
}

AddFunction ArmsFivetargetMainPostConditions
{
}

AddFunction ArmsFivetargetShortCdActions
{
 unless Rage() < 70 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } and Spell(skullsplitter)
 {
  #deadly_calm,if=cooldown.bladestorm.remains>6&((cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))|(equipped.weight_of_the_earth&cooldown.heroic_leap.remains<2))
  if SpellCooldown(bladestorm_arms) > 6 and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 or HasEquippedItem(weight_of_the_earth_item) and SpellCooldown(heroic_leap) < 2 } Spell(deadly_calm)

  unless target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker)
  {
   #heroic_leap,if=equipped.weight_of_the_earth&debuff.colossus_smash.down&((cooldown.colossus_smash.remains>8&!prev_gcd.1.colossus_smash)|(talent.warbreaker.enabled&cooldown.warbreaker.remains>8&!prev_gcd.1.warbreaker))
   if HasEquippedItem(weight_of_the_earth_item) and target.DebuffExpires(colossus_smash_debuff) and { SpellCooldown(colossus_smash) > 8 and not PreviousGCDSpell(colossus_smash) or Talent(warbreaker_talent) and SpellCooldown(warbreaker) > 8 and not PreviousGCDSpell(warbreaker) } and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
   #bladestorm,if=buff.sweeping_strikes.down&debuff.colossus_smash.remains>4.5&(prev_gcd.1.mortal_strike|spell_targets.whirlwind>1)&(!buff.deadly_calm.up|!talent.deadly_calm.enabled)
   if BuffExpires(sweeping_strikes_buff) and target.DebuffRemaining(colossus_smash_debuff) > 4 and { PreviousGCDSpell(mortal_strike) or Enemies() > 1 } and { not BuffPresent(deadly_calm_buff) or not Talent(deadly_calm_talent) } Spell(bladestorm_arms)
   #ravager,if=debuff.colossus_smash.up&(cooldown.deadly_calm.remains>6|!talent.deadly_calm.enabled)
   if target.DebuffPresent(colossus_smash_debuff) and { SpellCooldown(deadly_calm) > 6 or not Talent(deadly_calm_talent) } Spell(ravager)
  }
 }
}

AddFunction ArmsFivetargetShortCdPostConditions
{
 Rage() < 70 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } and Spell(skullsplitter) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or Spell(cleave) or { not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or { BuffPresent(sudden_death_arms_buff) or BuffPresent(stone_heart_buff) } and { BuffPresent(sweeping_strikes_buff) or SpellCooldown(sweeping_strikes) > 8 } } and Spell(execute_arms) or { not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sweeping_strikes_buff) and BuffStacks(overpower_buff) == 2 and { Talent(dreadnaught_talent) or HasEquippedItem(archavons_heavy_hand_item) } } and Spell(mortal_strike) or target.DebuffPresent(colossus_smash_debuff) and Spell(whirlwind_arms) or Spell(overpower) or Spell(whirlwind_arms)
}

AddFunction ArmsFivetargetCdActions
{
}

AddFunction ArmsFivetargetCdPostConditions
{
 Rage() < 70 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } and Spell(skullsplitter) or SpellCooldown(bladestorm_arms) > 6 and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 or HasEquippedItem(weight_of_the_earth_item) and SpellCooldown(heroic_leap) < 2 } and Spell(deadly_calm) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or HasEquippedItem(weight_of_the_earth_item) and target.DebuffExpires(colossus_smash_debuff) and { SpellCooldown(colossus_smash) > 8 and not PreviousGCDSpell(colossus_smash) or Talent(warbreaker_talent) and SpellCooldown(warbreaker) > 8 and not PreviousGCDSpell(warbreaker) } and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) and Spell(heroic_leap) or BuffExpires(sweeping_strikes_buff) and target.DebuffRemaining(colossus_smash_debuff) > 4 and { PreviousGCDSpell(mortal_strike) or Enemies() > 1 } and { not BuffPresent(deadly_calm_buff) or not Talent(deadly_calm_talent) } and Spell(bladestorm_arms) or target.DebuffPresent(colossus_smash_debuff) and { SpellCooldown(deadly_calm) > 6 or not Talent(deadly_calm_talent) } and Spell(ravager) or Spell(cleave) or { not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or { BuffPresent(sudden_death_arms_buff) or BuffPresent(stone_heart_buff) } and { BuffPresent(sweeping_strikes_buff) or SpellCooldown(sweeping_strikes) > 8 } } and Spell(execute_arms) or { not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sweeping_strikes_buff) and BuffStacks(overpower_buff) == 2 and { Talent(dreadnaught_talent) or HasEquippedItem(archavons_heavy_hand_item) } } and Spell(mortal_strike) or target.DebuffPresent(colossus_smash_debuff) and Spell(whirlwind_arms) or Spell(overpower) or Spell(whirlwind_arms)
}

### actions.execute

AddFunction ArmsExecuteMainActions
{
 #rend,if=remains<=duration*0.3&debuff.colossus_smash.down
 if target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0 and target.DebuffExpires(colossus_smash_debuff) Spell(rend)
 #skullsplitter,if=rage<70&((cooldown.deadly_calm.remains>3&!buff.deadly_calm.up)|!talent.deadly_calm.enabled)
 if Rage() < 70 and { SpellCooldown(deadly_calm) > 3 and not BuffPresent(deadly_calm_buff) or not Talent(deadly_calm_talent) } Spell(skullsplitter)
 #colossus_smash,if=debuff.colossus_smash.down
 if target.DebuffExpires(colossus_smash_debuff) Spell(colossus_smash)
 #warbreaker,if=debuff.colossus_smash.down
 if target.DebuffExpires(colossus_smash_debuff) Spell(warbreaker)
 #cleave,if=spell_targets.whirlwind>2
 if Enemies() > 2 Spell(cleave)
 #mortal_strike,if=buff.overpower.stack=2&(talent.dreadnaught.enabled|equipped.archavons_heavy_hand)
 if BuffStacks(overpower_buff) == 2 and { Talent(dreadnaught_talent) or HasEquippedItem(archavons_heavy_hand_item) } Spell(mortal_strike)
 #overpower
 Spell(overpower)
 #execute,if=rage>=40|debuff.colossus_smash.up|buff.sudden_death.react|buff.stone_heart.react
 if Rage() >= 40 or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(sudden_death_arms_buff) or BuffPresent(stone_heart_buff) Spell(execute_arms)
}

AddFunction ArmsExecuteMainPostConditions
{
}

AddFunction ArmsExecuteShortCdActions
{
 unless target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0 and target.DebuffExpires(colossus_smash_debuff) and Spell(rend) or Rage() < 70 and { SpellCooldown(deadly_calm) > 3 and not BuffPresent(deadly_calm_buff) or not Talent(deadly_calm_talent) } and Spell(skullsplitter)
 {
  #deadly_calm,if=cooldown.bladestorm.remains>6&((cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))|(equipped.weight_of_the_earth&cooldown.heroic_leap.remains<2))
  if SpellCooldown(bladestorm_arms) > 6 and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 or HasEquippedItem(weight_of_the_earth_item) and SpellCooldown(heroic_leap) < 2 } Spell(deadly_calm)

  unless target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker)
  {
   #heroic_leap,if=equipped.weight_of_the_earth&debuff.colossus_smash.down&((cooldown.colossus_smash.remains>8&!prev_gcd.1.colossus_smash)|(talent.warbreaker.enabled&cooldown.warbreaker.remains>8&!prev_gcd.1.warbreaker))
   if HasEquippedItem(weight_of_the_earth_item) and target.DebuffExpires(colossus_smash_debuff) and { SpellCooldown(colossus_smash) > 8 and not PreviousGCDSpell(colossus_smash) or Talent(warbreaker_talent) and SpellCooldown(warbreaker) > 8 and not PreviousGCDSpell(warbreaker) } and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
   #bladestorm,if=debuff.colossus_smash.remains>4.5&rage<70&(!buff.deadly_calm.up|!talent.deadly_calm.enabled)
   if target.DebuffRemaining(colossus_smash_debuff) > 4 and Rage() < 70 and { not BuffPresent(deadly_calm_buff) or not Talent(deadly_calm_talent) } Spell(bladestorm_arms)
   #ravager,if=debuff.colossus_smash.up&(cooldown.deadly_calm.remains>6|!talent.deadly_calm.enabled)
   if target.DebuffPresent(colossus_smash_debuff) and { SpellCooldown(deadly_calm) > 6 or not Talent(deadly_calm_talent) } Spell(ravager)
  }
 }
}

AddFunction ArmsExecuteShortCdPostConditions
{
 target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0 and target.DebuffExpires(colossus_smash_debuff) and Spell(rend) or Rage() < 70 and { SpellCooldown(deadly_calm) > 3 and not BuffPresent(deadly_calm_buff) or not Talent(deadly_calm_talent) } and Spell(skullsplitter) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or Enemies() > 2 and Spell(cleave) or BuffStacks(overpower_buff) == 2 and { Talent(dreadnaught_talent) or HasEquippedItem(archavons_heavy_hand_item) } and Spell(mortal_strike) or Spell(overpower) or { Rage() >= 40 or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(sudden_death_arms_buff) or BuffPresent(stone_heart_buff) } and Spell(execute_arms)
}

AddFunction ArmsExecuteCdActions
{
}

AddFunction ArmsExecuteCdPostConditions
{
 target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0 and target.DebuffExpires(colossus_smash_debuff) and Spell(rend) or Rage() < 70 and { SpellCooldown(deadly_calm) > 3 and not BuffPresent(deadly_calm_buff) or not Talent(deadly_calm_talent) } and Spell(skullsplitter) or SpellCooldown(bladestorm_arms) > 6 and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 or HasEquippedItem(weight_of_the_earth_item) and SpellCooldown(heroic_leap) < 2 } and Spell(deadly_calm) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or HasEquippedItem(weight_of_the_earth_item) and target.DebuffExpires(colossus_smash_debuff) and { SpellCooldown(colossus_smash) > 8 and not PreviousGCDSpell(colossus_smash) or Talent(warbreaker_talent) and SpellCooldown(warbreaker) > 8 and not PreviousGCDSpell(warbreaker) } and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) and Spell(heroic_leap) or target.DebuffRemaining(colossus_smash_debuff) > 4 and Rage() < 70 and { not BuffPresent(deadly_calm_buff) or not Talent(deadly_calm_talent) } and Spell(bladestorm_arms) or target.DebuffPresent(colossus_smash_debuff) and { SpellCooldown(deadly_calm) > 6 or not Talent(deadly_calm_talent) } and Spell(ravager) or Enemies() > 2 and Spell(cleave) or BuffStacks(overpower_buff) == 2 and { Talent(dreadnaught_talent) or HasEquippedItem(archavons_heavy_hand_item) } and Spell(mortal_strike) or Spell(overpower) or { Rage() >= 40 or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(sudden_death_arms_buff) or BuffPresent(stone_heart_buff) } and Spell(execute_arms)
}

### actions.default

AddFunction ArmsDefaultMainActions
{
 #charge
 if CheckBoxOn(opt_melee_range) and target.InRange(charge) Spell(charge)
 #sweeping_strikes,if=spell_targets.whirlwind>1
 if Enemies() > 1 Spell(sweeping_strikes)
 #run_action_list,name=five_target,if=spell_targets.whirlwind>4
 if Enemies() > 4 ArmsFivetargetMainActions()

 unless Enemies() > 4 and ArmsFivetargetMainPostConditions()
 {
  #run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
  if Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 ArmsExecuteMainActions()

  unless { Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteMainPostConditions()
  {
   #run_action_list,name=single_target
   ArmsSingletargetMainActions()
  }
 }
}

AddFunction ArmsDefaultMainPostConditions
{
 Enemies() > 4 and ArmsFivetargetMainPostConditions() or { Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteMainPostConditions() or ArmsSingletargetMainPostConditions()
}

AddFunction ArmsDefaultShortCdActions
{
 unless CheckBoxOn(opt_melee_range) and target.InRange(charge) and Spell(charge)
 {
  #auto_attack
  ArmsGetInMeleeRange()

  unless Enemies() > 1 and Spell(sweeping_strikes)
  {
   #run_action_list,name=five_target,if=spell_targets.whirlwind>4
   if Enemies() > 4 ArmsFivetargetShortCdActions()

   unless Enemies() > 4 and ArmsFivetargetShortCdPostConditions()
   {
    #run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
    if Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 ArmsExecuteShortCdActions()

    unless { Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteShortCdPostConditions()
    {
     #run_action_list,name=single_target
     ArmsSingletargetShortCdActions()
    }
   }
  }
 }
}

AddFunction ArmsDefaultShortCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.InRange(charge) and Spell(charge) or Enemies() > 1 and Spell(sweeping_strikes) or Enemies() > 4 and ArmsFivetargetShortCdPostConditions() or { Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteShortCdPostConditions() or ArmsSingletargetShortCdPostConditions()
}

AddFunction ArmsDefaultCdActions
{
 unless CheckBoxOn(opt_melee_range) and target.InRange(charge) and Spell(charge)
 {
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_strength usable=1)
  #blood_fury,if=debuff.colossus_smash.up
  if target.DebuffPresent(colossus_smash_debuff) Spell(blood_fury_ap)
  #berserking,if=debuff.colossus_smash.up
  if target.DebuffPresent(colossus_smash_debuff) Spell(berserking)
  #arcane_torrent,if=debuff.colossus_smash.down&cooldown.mortal_strike.remains>1.5&rage<50
  if target.DebuffExpires(colossus_smash_debuff) and SpellCooldown(mortal_strike) > 1 and Rage() < 50 Spell(arcane_torrent_rage)
  #lights_judgment,if=debuff.colossus_smash.down
  if target.DebuffExpires(colossus_smash_debuff) Spell(lights_judgment)
  #fireblood,if=debuff.colossus_smash.up
  if target.DebuffPresent(colossus_smash_debuff) Spell(fireblood)
  #ancestral_call,if=debuff.colossus_smash.up
  if target.DebuffPresent(colossus_smash_debuff) Spell(ancestral_call)
  #avatar,if=cooldown.colossus_smash.remains<8|(talent.warbreaker.enabled&cooldown.warbreaker.remains<8)
  if SpellCooldown(colossus_smash) < 8 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 8 Spell(avatar)

  unless Enemies() > 1 and Spell(sweeping_strikes)
  {
   #run_action_list,name=five_target,if=spell_targets.whirlwind>4
   if Enemies() > 4 ArmsFivetargetCdActions()

   unless Enemies() > 4 and ArmsFivetargetCdPostConditions()
   {
    #run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
    if Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 ArmsExecuteCdActions()

    unless { Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteCdPostConditions()
    {
     #run_action_list,name=single_target
     ArmsSingletargetCdActions()
    }
   }
  }
 }
}

AddFunction ArmsDefaultCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.InRange(charge) and Spell(charge) or Enemies() > 1 and Spell(sweeping_strikes) or Enemies() > 4 and ArmsFivetargetCdPostConditions() or { Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteCdPostConditions() or ArmsSingletargetCdPostConditions()
}

### Arms icons.

AddCheckBox(opt_warrior_arms_aoe L(AOE) default specialization=arms)

AddIcon checkbox=!opt_warrior_arms_aoe enemies=1 help=shortcd specialization=arms
{
 if not InCombat() ArmsPrecombatShortCdActions()
 unless not InCombat() and ArmsPrecombatShortCdPostConditions()
 {
  ArmsDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_warrior_arms_aoe help=shortcd specialization=arms
{
 if not InCombat() ArmsPrecombatShortCdActions()
 unless not InCombat() and ArmsPrecombatShortCdPostConditions()
 {
  ArmsDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=arms
{
 if not InCombat() ArmsPrecombatMainActions()
 unless not InCombat() and ArmsPrecombatMainPostConditions()
 {
  ArmsDefaultMainActions()
 }
}

AddIcon checkbox=opt_warrior_arms_aoe help=aoe specialization=arms
{
 if not InCombat() ArmsPrecombatMainActions()
 unless not InCombat() and ArmsPrecombatMainPostConditions()
 {
  ArmsDefaultMainActions()
 }
}

AddIcon checkbox=!opt_warrior_arms_aoe enemies=1 help=cd specialization=arms
{
 if not InCombat() ArmsPrecombatCdActions()
 unless not InCombat() and ArmsPrecombatCdPostConditions()
 {
  ArmsDefaultCdActions()
 }
}

AddIcon checkbox=opt_warrior_arms_aoe help=cd specialization=arms
{
 if not InCombat() ArmsPrecombatCdActions()
 unless not InCombat() and ArmsPrecombatCdPostConditions()
 {
  ArmsDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# arcane_torrent_rage
# archavons_heavy_hand_item
# arms_massacre_talent
# avatar
# battle_potion_of_strength
# berserking
# bladestorm_arms
# blood_fury_ap
# charge
# cleave
# cleave_talent
# colossus_smash
# colossus_smash_debuff
# deadly_calm
# deadly_calm_buff
# deadly_calm_talent
# deep_wounds_arms_debuff
# dreadnaught_talent
# execute_arms
# fervor_of_battle_talent
# fireblood
# heroic_leap
# lights_judgment
# mortal_strike
# overpower
# overpower_buff
# pummel
# ravager
# rend
# rend_debuff
# skullsplitter
# slam
# stone_heart_buff
# sudden_death_arms_buff
# sweeping_strikes
# sweeping_strikes_buff
# warbreaker
# warbreaker_talent
# weight_of_the_earth_item
# whirlwind_arms
]]
    OvaleScripts:RegisterScript("WARRIOR", "arms", name, desc, code, "script")
end
do
    local name = "sc_pr_warrior_fury"
    local desc = "[8.0] Simulationcraft: PR_Warrior_Fury"
    local code = [[
# Based on SimulationCraft profile "PR_Warrior_Fury".
#	class=warrior
#	spec=fury
#	talents=2122122

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=fury)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=fury)

AddFunction FuryGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not InFlightToTarget(charge) and not InFlightToTarget(heroic_leap)
 {
  if target.InRange(charge) Spell(charge)
  if SpellCharges(charge) == 0 and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
  if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.single_target

AddFunction FurySingletargetMainActions
{
 #rampage,if=buff.recklessness.up|(talent.frothing_berserker.enabled|talent.carnage.enabled&(buff.enrage.remains<gcd|rage>90)|talent.massacre.enabled&(buff.enrage.remains<gcd|rage>90))
 if BuffPresent(recklessness_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } Spell(rampage)
 #execute,if=buff.enrage.up
 if IsEnraged() Spell(execute)
 #bloodthirst,if=buff.enrage.down
 if not IsEnraged() Spell(bloodthirst)
 #raging_blow,if=charges=2
 if Charges(raging_blow) == 2 Spell(raging_blow)
 #bloodthirst
 Spell(bloodthirst)
 #raging_blow,if=talent.carnage.enabled|(talent.massacre.enabled&rage<80)|(talent.frothing_berserker.enabled&rage<90)
 if Talent(carnage_talent) or Talent(massacre_talent) and Rage() < 80 or Talent(frothing_berserker_talent) and Rage() < 90 Spell(raging_blow)
 #furious_slash,if=talent.furious_slash.enabled
 if Talent(furious_slash_talent) Spell(furious_slash)
 #whirlwind
 Spell(whirlwind)
}

AddFunction FurySingletargetMainPostConditions
{
}

AddFunction FurySingletargetShortCdActions
{
 #siegebreaker,if=buff.recklessness.up|cooldown.recklessness.remains>28
 if BuffPresent(recklessness_buff) or SpellCooldown(recklessness) > 28 Spell(siegebreaker)

 unless { BuffPresent(recklessness_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } } and Spell(rampage) or IsEnraged() and Spell(execute) or not IsEnraged() and Spell(bloodthirst) or Charges(raging_blow) == 2 and Spell(raging_blow) or Spell(bloodthirst)
 {
  #bladestorm,if=prev_gcd.1.rampage&(debuff.siegebreaker.up|!talent.siegebreaker.enabled)
  if PreviousGCDSpell(rampage) and { target.DebuffPresent(siegebreaker_debuff) or not Talent(siegebreaker_talent) } Spell(bladestorm_fury)
  #dragon_roar,if=buff.enrage.up&(debuff.siegebreaker.up|!talent.siegebreaker.enabled)
  if IsEnraged() and { target.DebuffPresent(siegebreaker_debuff) or not Talent(siegebreaker_talent) } Spell(dragon_roar)
 }
}

AddFunction FurySingletargetShortCdPostConditions
{
 { BuffPresent(recklessness_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } } and Spell(rampage) or IsEnraged() and Spell(execute) or not IsEnraged() and Spell(bloodthirst) or Charges(raging_blow) == 2 and Spell(raging_blow) or Spell(bloodthirst) or { Talent(carnage_talent) or Talent(massacre_talent) and Rage() < 80 or Talent(frothing_berserker_talent) and Rage() < 90 } and Spell(raging_blow) or Talent(furious_slash_talent) and Spell(furious_slash) or Spell(whirlwind)
}

AddFunction FurySingletargetCdActions
{
}

AddFunction FurySingletargetCdPostConditions
{
 { BuffPresent(recklessness_buff) or SpellCooldown(recklessness) > 28 } and Spell(siegebreaker) or { BuffPresent(recklessness_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } } and Spell(rampage) or IsEnraged() and Spell(execute) or not IsEnraged() and Spell(bloodthirst) or Charges(raging_blow) == 2 and Spell(raging_blow) or Spell(bloodthirst) or PreviousGCDSpell(rampage) and { target.DebuffPresent(siegebreaker_debuff) or not Talent(siegebreaker_talent) } and Spell(bladestorm_fury) or IsEnraged() and { target.DebuffPresent(siegebreaker_debuff) or not Talent(siegebreaker_talent) } and Spell(dragon_roar) or { Talent(carnage_talent) or Talent(massacre_talent) and Rage() < 80 or Talent(frothing_berserker_talent) and Rage() < 90 } and Spell(raging_blow) or Talent(furious_slash_talent) and Spell(furious_slash) or Spell(whirlwind)
}

### actions.precombat

AddFunction FuryPrecombatMainActions
{
}

AddFunction FuryPrecombatMainPostConditions
{
}

AddFunction FuryPrecombatShortCdActions
{
}

AddFunction FuryPrecombatShortCdPostConditions
{
}

AddFunction FuryPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_strength usable=1)
}

AddFunction FuryPrecombatCdPostConditions
{
}

### actions.movement

AddFunction FuryMovementMainActions
{
}

AddFunction FuryMovementMainPostConditions
{
}

AddFunction FuryMovementShortCdActions
{
 #heroic_leap
 if CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
}

AddFunction FuryMovementShortCdPostConditions
{
}

AddFunction FuryMovementCdActions
{
}

AddFunction FuryMovementCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) and Spell(heroic_leap)
}

### actions.default

AddFunction FuryDefaultMainActions
{
 #charge
 if CheckBoxOn(opt_melee_range) and target.InRange(charge) Spell(charge)
 #run_action_list,name=movement,if=movement.distance>5
 if target.Distance() > 5 FuryMovementMainActions()

 unless target.Distance() > 5 and FuryMovementMainPostConditions()
 {
  #furious_slash,if=talent.furious_slash.enabled&(buff.furious_slash.stack<3|buff.furious_slash.remains<3|(cooldown.recklessness.remains<3&buff.furious_slash.remains<9))
  if Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } Spell(furious_slash)
  #bloodthirst,if=equipped.kazzalax_fujiedas_fury&(buff.fujiedas_fury.down|remains<2)
  if HasEquippedItem(kazzalax_fujiedas_fury_item) and { BuffExpires(fujiedas_fury_buff) or target.DebuffRemaining(bloodthirst) < 2 } Spell(bloodthirst)
  #rampage,if=cooldown.recklessness.remains<3
  if SpellCooldown(recklessness) < 3 Spell(rampage)
  #whirlwind,if=spell_targets.whirlwind>1&!buff.meat_cleaver.up
  if Enemies() > 1 and not BuffPresent(whirlwind_buff) Spell(whirlwind)
  #run_action_list,name=single_target
  FurySingletargetMainActions()
 }
}

AddFunction FuryDefaultMainPostConditions
{
 target.Distance() > 5 and FuryMovementMainPostConditions() or FurySingletargetMainPostConditions()
}

AddFunction FuryDefaultShortCdActions
{
 #auto_attack
 FuryGetInMeleeRange()

 unless CheckBoxOn(opt_melee_range) and target.InRange(charge) and Spell(charge)
 {
  #run_action_list,name=movement,if=movement.distance>5
  if target.Distance() > 5 FuryMovementShortCdActions()

  unless target.Distance() > 5 and FuryMovementShortCdPostConditions()
  {
   #heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
   if { target.Distance() > 25 and 600 > 45 or not False(raid_event_movement_exists) } and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)

   unless Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or HasEquippedItem(kazzalax_fujiedas_fury_item) and { BuffExpires(fujiedas_fury_buff) or target.DebuffRemaining(bloodthirst) < 2 } and Spell(bloodthirst) or SpellCooldown(recklessness) < 3 and Spell(rampage) or Enemies() > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind)
   {
    #run_action_list,name=single_target
    FurySingletargetShortCdActions()
   }
  }
 }
}

AddFunction FuryDefaultShortCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.InRange(charge) and Spell(charge) or target.Distance() > 5 and FuryMovementShortCdPostConditions() or Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or HasEquippedItem(kazzalax_fujiedas_fury_item) and { BuffExpires(fujiedas_fury_buff) or target.DebuffRemaining(bloodthirst) < 2 } and Spell(bloodthirst) or SpellCooldown(recklessness) < 3 and Spell(rampage) or Enemies() > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind) or FurySingletargetShortCdPostConditions()
}

AddFunction FuryDefaultCdActions
{
 unless CheckBoxOn(opt_melee_range) and target.InRange(charge) and Spell(charge)
 {
  #run_action_list,name=movement,if=movement.distance>5
  if target.Distance() > 5 FuryMovementCdActions()

  unless target.Distance() > 5 and FuryMovementCdPostConditions() or { target.Distance() > 25 and 600 > 45 or not False(raid_event_movement_exists) } and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) and Spell(heroic_leap)
  {
   #potion
   if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_strength usable=1)

   unless Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or HasEquippedItem(kazzalax_fujiedas_fury_item) and { BuffExpires(fujiedas_fury_buff) or target.DebuffRemaining(bloodthirst) < 2 } and Spell(bloodthirst) or SpellCooldown(recklessness) < 3 and Spell(rampage)
   {
    #recklessness
    Spell(recklessness)

    unless Enemies() > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind)
    {
     #blood_fury,if=buff.recklessness.up
     if BuffPresent(recklessness_buff) Spell(blood_fury_ap)
     #berserking,if=buff.recklessness.up
     if BuffPresent(recklessness_buff) Spell(berserking)
     #arcane_torrent,if=rage<40&!buff.recklessness.up
     if Rage() < 40 and not BuffPresent(recklessness_buff) Spell(arcane_torrent_rage)
     #lights_judgment,if=cooldown.recklessness.remains<3
     if SpellCooldown(recklessness) < 3 Spell(lights_judgment)
     #fireblood,if=buff.recklessness.up
     if BuffPresent(recklessness_buff) Spell(fireblood)
     #ancestral_call,if=buff.recklessness.up
     if BuffPresent(recklessness_buff) Spell(ancestral_call)
     #run_action_list,name=single_target
     FurySingletargetCdActions()
    }
   }
  }
 }
}

AddFunction FuryDefaultCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.InRange(charge) and Spell(charge) or target.Distance() > 5 and FuryMovementCdPostConditions() or { target.Distance() > 25 and 600 > 45 or not False(raid_event_movement_exists) } and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) and Spell(heroic_leap) or Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or HasEquippedItem(kazzalax_fujiedas_fury_item) and { BuffExpires(fujiedas_fury_buff) or target.DebuffRemaining(bloodthirst) < 2 } and Spell(bloodthirst) or SpellCooldown(recklessness) < 3 and Spell(rampage) or Enemies() > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind) or FurySingletargetCdPostConditions()
}

### Fury icons.

AddCheckBox(opt_warrior_fury_aoe L(AOE) default specialization=fury)

AddIcon checkbox=!opt_warrior_fury_aoe enemies=1 help=shortcd specialization=fury
{
 if not InCombat() FuryPrecombatShortCdActions()
 unless not InCombat() and FuryPrecombatShortCdPostConditions()
 {
  FuryDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_warrior_fury_aoe help=shortcd specialization=fury
{
 if not InCombat() FuryPrecombatShortCdActions()
 unless not InCombat() and FuryPrecombatShortCdPostConditions()
 {
  FuryDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=fury
{
 if not InCombat() FuryPrecombatMainActions()
 unless not InCombat() and FuryPrecombatMainPostConditions()
 {
  FuryDefaultMainActions()
 }
}

AddIcon checkbox=opt_warrior_fury_aoe help=aoe specialization=fury
{
 if not InCombat() FuryPrecombatMainActions()
 unless not InCombat() and FuryPrecombatMainPostConditions()
 {
  FuryDefaultMainActions()
 }
}

AddIcon checkbox=!opt_warrior_fury_aoe enemies=1 help=cd specialization=fury
{
 if not InCombat() FuryPrecombatCdActions()
 unless not InCombat() and FuryPrecombatCdPostConditions()
 {
  FuryDefaultCdActions()
 }
}

AddIcon checkbox=opt_warrior_fury_aoe help=cd specialization=fury
{
 if not InCombat() FuryPrecombatCdActions()
 unless not InCombat() and FuryPrecombatCdPostConditions()
 {
  FuryDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# arcane_torrent_rage
# battle_potion_of_strength
# berserking
# bladestorm_fury
# blood_fury_ap
# bloodthirst
# carnage_talent
# charge
# dragon_roar
# execute
# fireblood
# frothing_berserker_talent
# fujiedas_fury_buff
# furious_slash
# furious_slash_buff
# furious_slash_talent
# heroic_leap
# kazzalax_fujiedas_fury_item
# lights_judgment
# massacre_talent
# pummel
# raging_blow
# rampage
# recklessness
# recklessness_buff
# siegebreaker
# siegebreaker_debuff
# siegebreaker_talent
# whirlwind
# whirlwind_buff
]]
    OvaleScripts:RegisterScript("WARRIOR", "fury", name, desc, code, "script")
end
