local __exports = LibStub:GetLibrary("ovale/scripts/ovale_warrior")
if not __exports then return end
__exports.registerWarriorProtectionHooves = function(OvaleScripts)
do
	local name = "hooves_protection"
	local desc = "[Hooves][8.1.5] Warrior: Protection"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

AddIcon specialization=3 help=main
{
	if not Mounted()
	{
	if target.InRange(shield_slam) and HasFullControl()
	{
		ProtectionHealMe()
		if PreviousGCDSpell(intercept) Spell(thunder_clap)
		
		# Cooldowns
		ProtectionDefaultCdActions()
		
		# Short Cooldowns
		ProtectionDefaultShortCdActions()
		
		# Default rotation
		ProtectionDefaultMainActions()
	}

	# Move to the target!
	if target.InRange(heroic_throw) and InCombat() Spell(heroic_throw usable=1)
	}
}

AddFunction ProtectionHealMe
{
	if HealthPercent() < 70 Spell(victory_rush)
	if HealthPercent() < 85 Spell(impending_victory)
}

AddFunction ProtectionGetInMeleeRange
{
	if InFlightToTarget(intercept) and not InFlightToTarget(heroic_leap)
	{
		if target.InRange(intercept) Spell(intercept)
		# if SpellCharges(intercept) == 0 and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
		# if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}




### actions.default
AddCheckBox(UseRevenge L(REVENGE))
AddFunction ProtectionDefaultMainActions
{
 #potion,if=buff.avatar.up|target.time_to_die<25
 if { BuffPresent(avatar_buff) or target.TimeToDie() < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(superior_battle_potion_of_strength usable=1)
 #ignore_pain,if=rage.deficit<25+20*talent.booming_voice.enabled*cooldown.demoralizing_shout.ready
 if {CheckBoxOn(UseRevenge) and RageDeficit() < 25 + 20 * TalentPoints(booming_voice_talent) * { SpellCooldown(demoralizing_shout) == 0 }} Spell(revenge)
 if {not CheckBoxOn(UseRevenge)} and RageDeficit() < 25 + 20 * TalentPoints(booming_voice_talent) * { SpellCooldown(demoralizing_shout) == 0 } Spell(ignore_pain)
 #worldvein_resonance_essence,if=cooldown.avatar.remains<=2
 if SpellCooldown(avatar) <= 2 Spell(worldvein_resonance_essence)
 #ripple_in_space_essence
 Spell(ripple_in_space_essence)
 #memory_of_lucid_dreams_essence
 Spell(memory_of_lucid_dreams_essence)
 #concentrated_flame_essence,if=buff.avatar.down
 if BuffExpires(avatar_buff) Spell(concentrated_flame_essence)
 #run_action_list,name=aoe,if=spell_targets.thunder_clap>=3
 if Enemies(tagged=1) >= 3 ProtectionAoeMainActions()

 unless Enemies(tagged=1) >= 3 and ProtectionAoeMainPostConditions()
 {
  #call_action_list,name=st
  ProtectionStMainActions()
 }
}

AddFunction ProtectionDefaultMainPostConditions
{
 Enemies(tagged=1) >= 3 and ProtectionAoeMainPostConditions() or ProtectionStMainPostConditions()
}

AddFunction ProtectionDefaultShortCdActions
{
 #auto_attack
 ProtectionGetInMeleeRange()

 unless TimeInCombat() == 0 and Spell(intercept) or { BuffPresent(avatar_buff) or target.TimeToDie() < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(superior_battle_potion_of_strength usable=1) or RageDeficit() < 25 + 20 * TalentPoints(booming_voice_talent) * { SpellCooldown(demoralizing_shout) == 0 } and Spell(ignore_pain) or SpellCooldown(avatar) <= 2 and Spell(worldvein_resonance_essence) or Spell(ripple_in_space_essence) or Spell(memory_of_lucid_dreams_essence) or BuffExpires(avatar_buff) and Spell(concentrated_flame_essence)
 {
  #run_action_list,name=aoe,if=spell_targets.thunder_clap>=3
  if Enemies(tagged=1) >= 3 ProtectionAoeShortCdActions()

  unless Enemies(tagged=1) >= 3 and ProtectionAoeShortCdPostConditions()
  {
   #call_action_list,name=st
   ProtectionStShortCdActions()
  }
 }
}

AddFunction ProtectionDefaultShortCdPostConditions
{
 TimeInCombat() == 0 and Spell(intercept) or { BuffPresent(avatar_buff) or target.TimeToDie() < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(superior_battle_potion_of_strength usable=1) or RageDeficit() < 25 + 20 * TalentPoints(booming_voice_talent) * { SpellCooldown(demoralizing_shout) == 0 } and Spell(ignore_pain) or SpellCooldown(avatar) <= 2 and Spell(worldvein_resonance_essence) or Spell(ripple_in_space_essence) or Spell(memory_of_lucid_dreams_essence) or BuffExpires(avatar_buff) and Spell(concentrated_flame_essence) or Enemies(tagged=1) >= 3 and ProtectionAoeShortCdPostConditions() or ProtectionStShortCdPostConditions()
}

AddFunction ProtectionDefaultCdActions
{
 unless TimeInCombat() == 0 and Spell(intercept)
 {
  #use_items,if=cooldown.avatar.remains<=gcd|buff.avatar.up
  
  #blood_fury
  Spell(blood_fury_ap)
  #berserking
  Spell(berserking)
  #arcane_torrent
  Spell(arcane_torrent_rage)
  #lights_judgment
  Spell(lights_judgment)
  #fireblood
  Spell(fireblood)
  #ancestral_call
  Spell(ancestral_call)

  unless { BuffPresent(avatar_buff) or target.TimeToDie() < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(superior_battle_potion_of_strength usable=1) or RageDeficit() < 25 + 20 * TalentPoints(booming_voice_talent) * { SpellCooldown(demoralizing_shout) == 0 } and Spell(ignore_pain) or SpellCooldown(avatar) <= 2 and Spell(worldvein_resonance_essence) or Spell(ripple_in_space_essence) or Spell(memory_of_lucid_dreams_essence) or BuffExpires(avatar_buff) and Spell(concentrated_flame_essence)
  {
   #last_stand,if=cooldown.anima_of_death.remains<=2
   if BuffExpires(shield_block_buff) Spell(last_stand)
   #avatar
   Spell(avatar)
   #run_action_list,name=aoe,if=spell_targets.thunder_clap>=3
   if Enemies(tagged=1) >= 3 ProtectionAoeCdActions()

   unless Enemies(tagged=1) >= 3 and ProtectionAoeCdPostConditions()
   {
    #call_action_list,name=st
    ProtectionStCdActions()
   }
  }
 }
}

AddFunction ProtectionDefaultCdPostConditions
{
 TimeInCombat() == 0 and Spell(intercept) or { BuffPresent(avatar_buff) or target.TimeToDie() < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(superior_battle_potion_of_strength usable=1) or RageDeficit() < 25 + 20 * TalentPoints(booming_voice_talent) * { SpellCooldown(demoralizing_shout) == 0 } and Spell(ignore_pain) or SpellCooldown(avatar) <= 2 and Spell(worldvein_resonance_essence) or Spell(ripple_in_space_essence) or Spell(memory_of_lucid_dreams_essence) or BuffExpires(avatar_buff) and Spell(concentrated_flame_essence) or Enemies(tagged=1) >= 3 and ProtectionAoeCdPostConditions()
}

### actions.aoe

AddFunction ProtectionAoeMainActions
{
 #thunder_clap
 Spell(thunder_clap)
 #memory_of_lucid_dreams_essence,if=buff.avatar.down
 if BuffExpires(avatar_buff) Spell(memory_of_lucid_dreams_essence)
 #anima_of_death,if=buff.last_stand.up
 if BuffPresent(last_stand_buff) Spell(anima_of_death)
 #revenge
 if BuffPresent(revenge_buff) Spell(revenge)
 #shield_slam
 Spell(shield_slam)
}

AddFunction ProtectionAoeMainPostConditions
{
}

AddFunction ProtectionAoeShortCdActions
{
 unless Spell(thunder_clap) or BuffExpires(avatar_buff) and Spell(memory_of_lucid_dreams_essence)
 {
  #demoralizing_shout,if=talent.booming_voice.enabled
  if Talent(booming_voice_talent) Spell(demoralizing_shout)

  unless BuffPresent(last_stand_buff) and Spell(anima_of_death)
  {
   #dragon_roar
   Spell(dragon_roar)

   unless Spell(revenge)
   {
    #ravager
    Spell(ravager_prot)
    #shield_block,if=cooldown.shield_slam.ready&buff.shield_block.down
    if SpellCooldown(shield_slam) == 0 and BuffExpires(shield_block_buff) and BuffExpires(last_stand_buff) Spell(shield_block)
   }
  }
 }
}

AddFunction ProtectionAoeShortCdPostConditions
{
 Spell(thunder_clap) or BuffExpires(avatar_buff) and Spell(memory_of_lucid_dreams_essence) or BuffPresent(last_stand_buff) and Spell(anima_of_death) or Spell(revenge) or Spell(shield_slam)
}

AddFunction ProtectionAoeCdActions
{
 unless Spell(thunder_clap) or BuffExpires(avatar_buff) and Spell(memory_of_lucid_dreams_essence) or Talent(booming_voice_talent) and Spell(demoralizing_shout) or BuffPresent(last_stand_buff) and Spell(anima_of_death) or Spell(dragon_roar) or Spell(revenge)
 {
  #use_item,name=grongs_primal_rage,if=buff.avatar.down|cooldown.thunder_clap.remains>=4
  
 }
}

AddFunction ProtectionAoeCdPostConditions
{
 
}

### actions.precombat

AddFunction ProtectionPrecombatMainActions
{
 #memory_of_lucid_dreams_essence
 Spell(memory_of_lucid_dreams_essence)
 #guardian_of_azeroth
 Spell(guardian_of_azeroth)
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(superior_battle_potion_of_strength usable=1)
}

AddFunction ProtectionPrecombatMainPostConditions
{
}

AddFunction ProtectionPrecombatShortCdActions
{
}

AddFunction ProtectionPrecombatShortCdPostConditions
{
 Spell(memory_of_lucid_dreams_essence) or Spell(guardian_of_azeroth) or CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(superior_battle_potion_of_strength usable=1)
}

AddFunction ProtectionPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #use_item,name=azsharas_font_of_power
 
}

AddFunction ProtectionPrecombatCdPostConditions
{
 Spell(memory_of_lucid_dreams_essence) or Spell(guardian_of_azeroth) or CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(superior_battle_potion_of_strength usable=1)
}

### actions.st

AddFunction ProtectionStMainActions
{
 #thunder_clap,if=spell_targets.thunder_clap=2&talent.unstoppable_force.enabled&buff.avatar.up
 if Enemies(tagged=1) == 2 and Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) Spell(thunder_clap)
 #shield_slam,if=buff.shield_block.up
 if BuffPresent(shield_block_buff) Spell(shield_slam)
 #thunder_clap,if=(talent.unstoppable_force.enabled&buff.avatar.up)
 if Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) Spell(thunder_clap)
 #anima_of_death,if=buff.last_stand.up
 if BuffPresent(last_stand_buff) Spell(anima_of_death)
 #shield_slam
 Spell(shield_slam)
 #thunder_clap
 Spell(thunder_clap)
 #revenge
 if BuffPresent(revenge_buff) Spell(revenge)
 #devastate
 Spell(devastate)
}

AddFunction ProtectionStMainPostConditions
{
}

AddFunction ProtectionStShortCdActions
{
 unless Enemies(tagged=1) == 2 and Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap)
 {
  #shield_block,if=cooldown.shield_slam.ready&buff.shield_block.down
  if SpellCooldown(shield_slam) == 0 and BuffExpires(shield_block_buff) and BuffExpires(last_stand_buff) Spell(shield_block)

  unless BuffPresent(shield_block_buff) and Spell(shield_slam) or Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap)
  {
   #demoralizing_shout,if=talent.booming_voice.enabled
   if Talent(booming_voice_talent) Spell(demoralizing_shout)

   unless BuffPresent(last_stand_buff) and Spell(anima_of_death) or Spell(shield_slam)
   {
    #dragon_roar
    Spell(dragon_roar)

    unless Spell(thunder_clap) or Spell(revenge)
    {
     #ravager
     Spell(ravager_prot)
    }
   }
  }
 }
}

AddFunction ProtectionStShortCdPostConditions
{
 Enemies(tagged=1) == 2 and Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap) or BuffPresent(shield_block_buff) and Spell(shield_slam) or Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap) or BuffPresent(last_stand_buff) and Spell(anima_of_death) or Spell(shield_slam) or Spell(thunder_clap) or Spell(revenge) or Spell(devastate)
}

AddFunction ProtectionStCdActions
{
 unless Enemies(tagged=1) == 2 and Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap) or BuffPresent(shield_block_buff) and Spell(shield_slam) or Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap) or Talent(booming_voice_talent) and Spell(demoralizing_shout) or BuffPresent(last_stand_buff) and Spell(anima_of_death) or Spell(shield_slam)
 {
  #use_item,name=ashvanes_razor_coral,target_if=debuff.razor_coral_debuff.stack=0
  
  #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.stack>7&(cooldown.avatar.remains<5|buff.avatar.up)
  

  unless Spell(dragon_roar) or Spell(thunder_clap) or Spell(revenge)
  {
   #use_item,name=grongs_primal_rage,if=buff.avatar.down|cooldown.shield_slam.remains>=4
   
  }
 }
}
]]

		OvaleScripts:RegisterScript("WARRIOR", "protection", name, desc, code, "script")
	end
end
