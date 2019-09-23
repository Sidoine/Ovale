local __exports = LibStub:GetLibrary("ovale/scripts/ovale_paladin")
if not __exports then return end
__exports.registerPaladinProtectionHooves = function(OvaleScripts)
do
	local name = "hooves_prot"
	local desc = "[Hooves][8.2] Paladin: Protection"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)

# Protection
AddIcon specialization=2 help=main
{
    # Interrupt
       
   # if { target.InRange(shield_of_the_righteous) or target.InRange(hammer_of_the_righteous) } #and HasFullControl()
   if not Mounted()
   {
    if { target.InRange(rebuke) } and HasFullControl()
    {
		PaladinHealMe()
        if not BuffPresent(consecration_buff) Spell(consecration)
        ProtectionDefaultShortCdActions()
        ProtectionDefaultCdActions()
        ProtectionDefaultMainActions()
		}
	}
}
AddFunction ProtectionSelfHealCondition
{
    (HealthPercent() < 40)
        or (IncomingDamage(10) < MaxHealth() * 1.25 and HealthPercent() < 55 and Talent(righteous_protector_talent))
        or (IncomingDamage(13) < MaxHealth() * 1.6 and HealthPercent() < 55)
        or (IncomingDamage(6) < MaxHealth() * 0.7 and HealthPercent() < 65 and Talent(righteous_protector_talent))
        or (IncomingDamage(9) < MaxHealth() * 1.2 and HealthPercent() < 55)
        or (HealthPercent() < 60 and HasEquippedItem(saruans_resolve) and (SpellCharges(light_of_the_protector) >= 2 or SpellCharges(hand_of_the_protector) >= 2))
}

AddFunction PaladinHealMe
{
    unless(DebuffPresent(healing_immunity_debuff)) 
    {
        if ProtectionSelfHealCondition() Spell(light_of_the_protector)
        if (HealthPercent() < 35) UseHealthPotions()
    }
}

AddFunction ProtectionGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.precombat
AddFunction ProtectionPrecombatMainActions
{
 #consecration
 Spell(consecration)
}
AddFunction ProtectionPrecombatMainPostConditions
{
}
AddFunction ProtectionPrecombatShortCdActions
{
}
AddFunction ProtectionPrecombatShortCdPostConditions
{
 Spell(consecration)
}
AddFunction ProtectionPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 unless Spell(consecration)
 {
  #lights_judgment
  Spell(lights_judgment)
 }
}
AddFunction ProtectionPrecombatCdPostConditions
{
 Spell(consecration)
}
### actions.cooldowns
AddFunction ProtectionCooldownsMainActions
{
}
AddFunction ProtectionCooldownsMainPostConditions
{
}
AddFunction ProtectionCooldownsShortCdActions
{
 #seraphim,if=cooldown.shield_of_the_righteous.charges_fractional>=2
 if SpellCharges(shield_of_the_righteous count=0) >= 2 Spell(seraphim)
}
AddFunction ProtectionCooldownsShortCdPostConditions
{
}
AddFunction ProtectionCooldownsCdActions
{
 #fireblood,if=buff.avenging_wrath.up
 if BuffPresent(avenging_wrath_buff) Spell(fireblood)
 #use_item,name=azsharas_font_of_power,if=cooldown.seraphim.remains<=10|!talent.seraphim.enabled

 unless SpellCharges(shield_of_the_righteous count=0) >= 2 and Spell(seraphim)
 {
  #avenging_wrath,if=buff.seraphim.up|cooldown.seraphim.remains<2|!talent.seraphim.enabled
  if BuffPresent(seraphim_buff) or SpellCooldown(seraphim) < 2 or not Talent(seraphim_talent) Spell(avenging_wrath)
  #bastion_of_light,if=cooldown.shield_of_the_righteous.charges_fractional<=0.5
  if SpellCharges(shield_of_the_righteous count=0) <= 0.5 Spell(bastion_of_light)
  #potion,if=buff.avenging_wrath.up
  if BuffPresent(avenging_wrath_buff) and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
  #use_items,if=buff.seraphim.up|!talent.seraphim.enabled

  #use_item,name=grongs_primal_rage,if=((cooldown.judgment.full_recharge_time>4|(!talent.crusaders_judgment.enabled&prev_gcd.1.judgment))&cooldown.avengers_shield.remains>4&buff.seraphim.remains>4)|(buff.seraphim.remains<4)
  
  #use_item,name=merekthas_fang,if=!buff.avenging_wrath.up&(buff.seraphim.up|!talent.seraphim.enabled)
  
  #use_item,name=razdunks_big_red_button
  
 }
}
AddFunction ProtectionCooldownsCdPostConditions
{
 SpellCharges(shield_of_the_righteous count=0) >= 2 and Spell(seraphim)
}
### actions.default
AddFunction ProtectionDefaultMainActions
{
 #call_action_list,name=cooldowns
 ProtectionCooldownsMainActions()
 unless ProtectionCooldownsMainPostConditions()
 {
  #shield_of_the_righteous,if=(buff.avengers_valor.up&cooldown.shield_of_the_righteous.charges_fractional>=2.5)&(cooldown.seraphim.remains>gcd|!talent.seraphim.enabled)
  if BuffPresent(avengers_valor_buff) and SpellCharges(shield_of_the_righteous count=0) >= 2.5 and { SpellCooldown(seraphim) > GCD() or not Talent(seraphim_talent) } Spell(shield_of_the_righteous)
  #shield_of_the_righteous,if=(buff.avenging_wrath.up&!talent.seraphim.enabled)|buff.seraphim.up&buff.avengers_valor.up
  if BuffPresent(avenging_wrath_buff) and not Talent(seraphim_talent) or BuffPresent(seraphim_buff) and BuffPresent(avengers_valor_buff) Spell(shield_of_the_righteous)
  #shield_of_the_righteous,if=(buff.avenging_wrath.up&buff.avenging_wrath.remains<4&!talent.seraphim.enabled)|(buff.seraphim.remains<4&buff.seraphim.up)
  if BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) < 4 and not Talent(seraphim_talent) or BuffRemaining(seraphim_buff) < 4 and BuffPresent(seraphim_buff) Spell(shield_of_the_righteous)
  #consecration,if=!consecration.up
  if not BuffPresent(consecration) Spell(consecration)
  #judgment,if=(cooldown.judgment.remains<gcd&cooldown.judgment.charges_fractional>1&cooldown_react)|!talent.crusaders_judgment.enabled
  if SpellCooldown(judgment_protection) < GCD() and SpellCharges(judgment_protection count=0) > 1 and not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) Spell(judgment_protection)
  #avengers_shield,if=cooldown_react
  if not SpellCooldown(avengers_shield) > 0 Spell(avengers_shield)
  #judgment,if=cooldown_react|!talent.crusaders_judgment.enabled
  if not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) Spell(judgment_protection)
  #blessed_hammer,strikes=3
  Spell(blessed_hammer)
  #hammer_of_the_righteous
  Spell(hammer_of_the_righteous)
  #consecration
  Spell(consecration)
 }
}
AddFunction ProtectionDefaultMainPostConditions
{
 ProtectionCooldownsMainPostConditions()
}
AddFunction ProtectionDefaultShortCdActions
{
 #auto_attack
 ProtectionGetInMeleeRange()
 #call_action_list,name=cooldowns
 ProtectionCooldownsShortCdActions()
}
AddFunction ProtectionDefaultShortCdPostConditions
{
 ProtectionCooldownsShortCdPostConditions() or BuffPresent(avengers_valor_buff) and SpellCharges(shield_of_the_righteous count=0) >= 2.5 and { SpellCooldown(seraphim) > GCD() or not Talent(seraphim_talent) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and not Talent(seraphim_talent) or BuffPresent(seraphim_buff) and BuffPresent(avengers_valor_buff) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) < 4 and not Talent(seraphim_talent) or BuffRemaining(seraphim_buff) < 4 and BuffPresent(seraphim_buff) } and Spell(shield_of_the_righteous) or not BuffPresent(consecration) and Spell(consecration) or { SpellCooldown(judgment_protection) < GCD() and SpellCharges(judgment_protection count=0) > 1 and not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or not SpellCooldown(avengers_shield) > 0 and Spell(avengers_shield) or { not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or Spell(blessed_hammer) or Spell(hammer_of_the_righteous) or Spell(consecration)
}
AddFunction ProtectionDefaultCdActions
{
 
 #call_action_list,name=cooldowns
 ProtectionCooldownsCdActions()
 unless ProtectionCooldownsCdPostConditions() or BuffPresent(avengers_valor_buff) and SpellCharges(shield_of_the_righteous count=0) >= 2.5 and { SpellCooldown(seraphim) > GCD() or not Talent(seraphim_talent) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and not Talent(seraphim_talent) or BuffPresent(seraphim_buff) and BuffPresent(avengers_valor_buff) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) < 4 and not Talent(seraphim_talent) or BuffRemaining(seraphim_buff) < 4 and BuffPresent(seraphim_buff) } and Spell(shield_of_the_righteous)
 {
  #lights_judgment,if=buff.seraphim.up&buff.seraphim.remains<3
  if BuffPresent(seraphim_buff) and BuffRemaining(seraphim_buff) < 3 Spell(lights_judgment)
  unless not BuffPresent(consecration) and Spell(consecration) or { SpellCooldown(judgment_protection) < GCD() and SpellCharges(judgment_protection count=0) > 1 and not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or not SpellCooldown(avengers_shield) > 0 and Spell(avengers_shield) or { not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection)
  {
   #lights_judgment,if=!talent.seraphim.enabled|buff.seraphim.up
   if not Talent(seraphim_talent) or BuffPresent(seraphim_buff) Spell(lights_judgment)
  }
 }
}
AddFunction ProtectionDefaultCdPostConditions
{
 ProtectionCooldownsCdPostConditions() or BuffPresent(avengers_valor_buff) and SpellCharges(shield_of_the_righteous count=0) >= 2.5 and { SpellCooldown(seraphim) > GCD() or not Talent(seraphim_talent) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and not Talent(seraphim_talent) or BuffPresent(seraphim_buff) and BuffPresent(avengers_valor_buff) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) < 4 and not Talent(seraphim_talent) or BuffRemaining(seraphim_buff) < 4 and BuffPresent(seraphim_buff) } and Spell(shield_of_the_righteous) or not BuffPresent(consecration) and Spell(consecration) or { SpellCooldown(judgment_protection) < GCD() and SpellCharges(judgment_protection count=0) > 1 and not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or not SpellCooldown(avengers_shield) > 0 and Spell(avengers_shield) or { not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or Spell(blessed_hammer) or Spell(hammer_of_the_righteous) or Spell(consecration)
}
]]

		OvaleScripts:RegisterScript("PALADIN", "protection", name, desc, code, "script")
	end
end
