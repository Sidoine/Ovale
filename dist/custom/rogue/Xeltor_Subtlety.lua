local __exports = LibStub:GetLibrary("ovale/scripts/ovale_rogue")
if not __exports then return end
__exports.registerRogueSubtletyXeltor = function(OvaleScripts)
do
	local name = "xeltor_shanky"
	local desc = "[Xel][8.1] Blush: Shanky"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)

# Subtlety (Shanky)
AddIcon specialization=3 help=main
{
	if not mounted() and not Stealthed() and not InCombat() and not Dead() and not PlayerIsResting()
	{
		unless target.Present() and target.Distance(less 5)
		{
			if Speed() > 0 Spell(stealth)
		}
	}
	if not InCombat() and target.Present() and target.Exists() and not target.IsFriend() and not mounted() and not Dead()
	{
		if target.InRange(marked_for_death) and Stealthed() Spell(cold_blood)
		#marked_for_death
		if target.InRange(marked_for_death) and ComboPoints() < 5 Spell(marked_for_death)
	}
	
	if InCombat() and { not target.IsFriend() or target.IsPvP() } InterruptActions()
	if { HealthPercent() <= 25 or HealthPercent() < 70 and not InCombat() and not mounted() } and not Dead() and Energy() > 24 Spell(crimson_vial)
	
	if target.InRange(backstab) and HasFullControl()
	{
		# Cooldowns
		SubtletyDefaultCdActions()
		
		# Short Cooldowns
		SubtletyDefaultShortCdActions()
		
		# Default Actions
		SubtletyDefaultMainActions()
	}
	
	if InCombat() and not target.IsDead() and not target.IsFriend() and target.Distance(more 5) and { not IsBossFight() or Falling() } and { target.Health() < target.MaxHealth() or target.istargetingplayer() } GetInMeleeRange()
}

AddFunction GetInMeleeRange
{
	if not target.InRange(kick)
	{
		if target.InRange(shadowstrike) and Stealthed() Spell(shadowstrike)
		if target.InRange(shadowstep) Spell(shadowstep)
		# Texture(misc_arrowlup help=L(not_in_melee_range))
		if target.InRange(shadowstrike) and not Stealthed() and SpellCooldown(shadowstep) > GCD() AcquireStealth()
		if not Stealthed() and target.InRange(shuriken_toss) Spell(shuriken_toss)
	}
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.InRange(kick) and target.IsInterruptible() Spell(kick)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		if target.InRange(kidney_shot) and not target.Classification(worldboss) and ComboPoints() >= 1 Spell(kidney_shot)
		if target.InRange(cheap_shot) and not target.Classification(worldboss) Spell(cheap_shot)
	}
}

AddFunction AcquireStealth
{
	if not InCombat() Spell(stealth)
	if VanishAllowed() and InCombat() Spell(vanish)
	if not BuffPresent(shadow_dance_buff) and InCombat() and not BuffPresent(shadow_dance_buff) Spell(shadow_dance)
}

AddFunction VanishAllowed
{
	{ not target.istargetingplayer() or target.IsPvP() or unitinparty() or unitinraid() }
}

AddFunction SubtletyUseItemActions
{
 if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
 if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

AddFunction shd_threshold
{
 SpellCharges(shadow_dance count=0) >= 1.75
}

AddFunction use_priority_rotation
{
 Enemies(tagged=1) >= 2
}

AddFunction stealth_threshold
{
 25 + TalentPoints(vigor_talent) * 35 + TalentPoints(master_of_shadows_talent) * 25 + TalentPoints(shadow_focus_talent) * 20 + TalentPoints(alacrity_talent) * 10 + 15 * { Enemies(tagged=1) >= 3 }
}

### actions.default

AddFunction SubtletyDefaultMainActions
{
 #call_action_list,name=cds
 SubtletyCdsMainActions()

 unless SubtletyCdsMainPostConditions()
 {
  #run_action_list,name=stealthed,if=stealthed.all
  if Stealthed() SubtletyStealthedMainActions()

  unless Stealthed() and SubtletyStealthedMainPostConditions()
  {
   #nightblade,if=target.time_to_die>6&remains<gcd.max&combo_points>=4-(time<10)*2
   if target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 Spell(nightblade)
   #variable,name=use_priority_rotation,value=priority_rotation&spell_targets.shuriken_storm>=2
   #call_action_list,name=stealth_cds,if=variable.use_priority_rotation
   if use_priority_rotation() SubtletyStealthCdsMainActions()

   unless use_priority_rotation() and SubtletyStealthCdsMainPostConditions()
   {
    #variable,name=stealth_threshold,value=25+talent.vigor.enabled*35+talent.master_of_shadows.enabled*25+talent.shadow_focus.enabled*20+talent.alacrity.enabled*10+15*(spell_targets.shuriken_storm>=3)
    #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&combo_points.deficit>=4
    if EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 SubtletyStealthCdsMainActions()

    unless EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthCdsMainPostConditions()
    {
     #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&talent.dark_shadow.enabled&talent.secret_technique.enabled&cooldown.secret_technique.up&spell_targets.shuriken_storm<=4
     if EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies(tagged=1) <= 4 SubtletyStealthCdsMainActions()

     unless EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies(tagged=1) <= 4 and SubtletyStealthCdsMainPostConditions()
     {
      #call_action_list,name=finish,if=combo_points.deficit<=1|target.time_to_die<=1&combo_points>=3
      if ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 SubtletyFinishMainActions()

      unless { ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishMainPostConditions()
      {
       #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
       if Enemies(tagged=1) == 4 and ComboPoints() >= 4 SubtletyFinishMainActions()

       unless Enemies(tagged=1) == 4 and ComboPoints() >= 4 and SubtletyFinishMainPostConditions()
       {
        #call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold
        if EnergyDeficit() <= stealth_threshold() SubtletyBuildMainActions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction SubtletyDefaultMainPostConditions
{
 SubtletyCdsMainPostConditions() or Stealthed() and SubtletyStealthedMainPostConditions() or use_priority_rotation() and SubtletyStealthCdsMainPostConditions() or EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthCdsMainPostConditions() or EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies(tagged=1) <= 4 and SubtletyStealthCdsMainPostConditions() or { ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishMainPostConditions() or Enemies(tagged=1) == 4 and ComboPoints() >= 4 and SubtletyFinishMainPostConditions() or EnergyDeficit() <= stealth_threshold() and SubtletyBuildMainPostConditions()
}

AddFunction SubtletyDefaultShortCdActions
{
 #stealth
 if not InCombat() Spell(stealth)
 #call_action_list,name=cds
 SubtletyCdsShortCdActions()

 unless SubtletyCdsShortCdPostConditions()
 {
  #run_action_list,name=stealthed,if=stealthed.all
  if Stealthed() SubtletyStealthedShortCdActions()

  unless Stealthed() and SubtletyStealthedShortCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade)
  {
   #variable,name=use_priority_rotation,value=priority_rotation&spell_targets.shuriken_storm>=2
   #call_action_list,name=stealth_cds,if=variable.use_priority_rotation
   if use_priority_rotation() SubtletyStealthCdsShortCdActions()

   unless use_priority_rotation() and SubtletyStealthCdsShortCdPostConditions()
   {
    #variable,name=stealth_threshold,value=25+talent.vigor.enabled*35+talent.master_of_shadows.enabled*25+talent.shadow_focus.enabled*20+talent.alacrity.enabled*10+15*(spell_targets.shuriken_storm>=3)
    #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&combo_points.deficit>=4
    if EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 SubtletyStealthCdsShortCdActions()

    unless EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthCdsShortCdPostConditions()
    {
     #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&talent.dark_shadow.enabled&talent.secret_technique.enabled&cooldown.secret_technique.up&spell_targets.shuriken_storm<=4
     if EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies(tagged=1) <= 4 SubtletyStealthCdsShortCdActions()

     unless EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies(tagged=1) <= 4 and SubtletyStealthCdsShortCdPostConditions()
     {
      #call_action_list,name=finish,if=combo_points.deficit<=1|target.time_to_die<=1&combo_points>=3
      if ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 SubtletyFinishShortCdActions()

      unless { ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishShortCdPostConditions()
      {
       #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
       if Enemies(tagged=1) == 4 and ComboPoints() >= 4 SubtletyFinishShortCdActions()

       unless Enemies(tagged=1) == 4 and ComboPoints() >= 4 and SubtletyFinishShortCdPostConditions()
       {
        #call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold
        if EnergyDeficit() <= stealth_threshold() SubtletyBuildShortCdActions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction SubtletyDefaultShortCdPostConditions
{
 SubtletyCdsShortCdPostConditions() or Stealthed() and SubtletyStealthedShortCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade) or use_priority_rotation() and SubtletyStealthCdsShortCdPostConditions() or EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthCdsShortCdPostConditions() or EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies(tagged=1) <= 4 and SubtletyStealthCdsShortCdPostConditions() or { ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishShortCdPostConditions() or Enemies(tagged=1) == 4 and ComboPoints() >= 4 and SubtletyFinishShortCdPostConditions() or EnergyDeficit() <= stealth_threshold() and SubtletyBuildShortCdPostConditions()
}

AddFunction SubtletyDefaultCdActions
{
 # SubtletyInterruptActions()
 #call_action_list,name=cds
 SubtletyCdsCdActions()

 unless SubtletyCdsCdPostConditions()
 {
  #run_action_list,name=stealthed,if=stealthed.all
  if Stealthed() SubtletyStealthedCdActions()

  unless Stealthed() and SubtletyStealthedCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade)
  {
   #variable,name=use_priority_rotation,value=priority_rotation&spell_targets.shuriken_storm>=2
   #call_action_list,name=stealth_cds,if=variable.use_priority_rotation
   if use_priority_rotation() SubtletyStealthCdsCdActions()

   unless use_priority_rotation() and SubtletyStealthCdsCdPostConditions()
   {
    #variable,name=stealth_threshold,value=25+talent.vigor.enabled*35+talent.master_of_shadows.enabled*25+talent.shadow_focus.enabled*20+talent.alacrity.enabled*10+15*(spell_targets.shuriken_storm>=3)
    #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&combo_points.deficit>=4
    if EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 SubtletyStealthCdsCdActions()

    unless EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthCdsCdPostConditions()
    {
     #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&talent.dark_shadow.enabled&talent.secret_technique.enabled&cooldown.secret_technique.up&spell_targets.shuriken_storm<=4
     if EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies(tagged=1) <= 4 SubtletyStealthCdsCdActions()

     unless EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies(tagged=1) <= 4 and SubtletyStealthCdsCdPostConditions()
     {
      #call_action_list,name=finish,if=combo_points.deficit<=1|target.time_to_die<=1&combo_points>=3
      if ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 SubtletyFinishCdActions()

      unless { ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishCdPostConditions()
      {
       #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
       if Enemies(tagged=1) == 4 and ComboPoints() >= 4 SubtletyFinishCdActions()

       unless Enemies(tagged=1) == 4 and ComboPoints() >= 4 and SubtletyFinishCdPostConditions()
       {
        #call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold
        if EnergyDeficit() <= stealth_threshold() SubtletyBuildCdActions()

        unless EnergyDeficit() <= stealth_threshold() and SubtletyBuildCdPostConditions()
        {
         #arcane_torrent,if=energy.deficit>=15+energy.regen
         if EnergyDeficit() >= 15 + EnergyRegenRate() Spell(arcane_torrent_energy)
         #arcane_pulse
         Spell(arcane_pulse)
         #lights_judgment
         Spell(lights_judgment)
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction SubtletyDefaultCdPostConditions
{
 SubtletyCdsCdPostConditions() or Stealthed() and SubtletyStealthedCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade) or use_priority_rotation() and SubtletyStealthCdsCdPostConditions() or EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthCdsCdPostConditions() or EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies(tagged=1) <= 4 and SubtletyStealthCdsCdPostConditions() or { ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishCdPostConditions() or Enemies(tagged=1) == 4 and ComboPoints() >= 4 and SubtletyFinishCdPostConditions() or EnergyDeficit() <= stealth_threshold() and SubtletyBuildCdPostConditions()
}

### actions.build

AddFunction SubtletyBuildMainActions
{
 #shuriken_storm,if=spell_targets>=2
 if Enemies(tagged=1) >= 2 Spell(shuriken_storm)
 #gloomblade
 Spell(gloomblade)
 #backstab
 Spell(backstab)
}

AddFunction SubtletyBuildMainPostConditions
{
}

AddFunction SubtletyBuildShortCdActions
{
}

AddFunction SubtletyBuildShortCdPostConditions
{
 Enemies(tagged=1) >= 2 and Spell(shuriken_storm) or Spell(gloomblade) or Spell(backstab)
}

AddFunction SubtletyBuildCdActions
{
}

AddFunction SubtletyBuildCdPostConditions
{
 Enemies(tagged=1) >= 2 and Spell(shuriken_storm) or Spell(gloomblade) or Spell(backstab)
}

### actions.cds

AddFunction SubtletyCdsMainActions
{
}

AddFunction SubtletyCdsMainPostConditions
{
}

AddFunction SubtletyCdsShortCdActions
{
 #shadow_dance,use_off_gcd=1,if=!buff.shadow_dance.up&buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5
 if not BuffPresent(shadow_dance_buff) and DebuffPresent(shuriken_tornado) and DebuffRemaining(shuriken_tornado) <= 3.5 Spell(shadow_dance)
 #symbols_of_death,use_off_gcd=1,if=buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5
 if DebuffPresent(shuriken_tornado) and DebuffRemaining(shuriken_tornado) <= 3.5 Spell(symbols_of_death)
 #symbols_of_death,if=dot.nightblade.ticking&(!talent.shuriken_tornado.enabled|talent.shadow_focus.enabled|spell_targets.shuriken_storm<3|!cooldown.shuriken_tornado.up)
 if target.DebuffPresent(nightblade_debuff) and { not Talent(shuriken_tornado_talent) or Talent(shadow_focus_talent) or Enemies(tagged=1) < 3 or not { not SpellCooldown(shuriken_tornado) > 0 } } Spell(symbols_of_death)
 #marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.all&combo_points.deficit>=cp_max_spend)
 if False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() or not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() } Spell(marked_for_death)
 #marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&!stealthed.all&combo_points.deficit>=cp_max_spend
 if 600 > 30 - 10 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() Spell(marked_for_death)
 #shuriken_tornado,if=spell_targets>=3&!talent.shadow_focus.enabled&dot.nightblade.ticking&!stealthed.all&cooldown.symbols_of_death.up&cooldown.shadow_dance.charges>=1
 if Enemies(tagged=1) >= 3 and not Talent(shadow_focus_talent) and target.DebuffPresent(nightblade_debuff) and not Stealthed() and not SpellCooldown(symbols_of_death) > 0 and SpellCharges(shadow_dance) >= 1 Spell(shuriken_tornado)
 #shuriken_tornado,if=spell_targets>=3&talent.shadow_focus.enabled&dot.nightblade.ticking&buff.symbols_of_death.up
 if Enemies(tagged=1) >= 3 and Talent(shadow_focus_talent) and target.DebuffPresent(nightblade_debuff) and BuffPresent(symbols_of_death_buff) Spell(shuriken_tornado)
 #shadow_dance,if=!buff.shadow_dance.up&target.time_to_die<=5+talent.subterfuge.enabled&!raid_event.adds.up
 if not BuffPresent(shadow_dance_buff) and target.TimeToDie() <= 5 + TalentPoints(subterfuge_talent) and not False(raid_event_adds_exists) Spell(shadow_dance)
 #cold_blood,if=stealthed.all
 if Stealthed() Spell(cold_blood)
}

AddFunction SubtletyCdsShortCdPostConditions
{
}

AddFunction SubtletyCdsCdActions
{
 #potion,if=buff.bloodlust.react|buff.symbols_of_death.up&(buff.shadow_blades.up|cooldown.shadow_blades.remains<=10)
 # if { BuffPresent(burst_haste_buff any=1) or BuffPresent(symbols_of_death_buff) and { BuffPresent(shadow_blades_buff) or SpellCooldown(shadow_blades) <= 10 } } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #use_item,name=galecallers_boon,if=buff.symbols_of_death.up|target.time_to_die<20
 if BuffPresent(symbols_of_death_buff) or target.TimeToDie() < 20 SubtletyUseItemActions()
 #blood_fury,if=buff.symbols_of_death.up
 if BuffPresent(symbols_of_death_buff) Spell(blood_fury_ap)
 #berserking,if=buff.symbols_of_death.up
 if BuffPresent(symbols_of_death_buff) Spell(berserking)
 #fireblood,if=buff.symbols_of_death.up
 if BuffPresent(symbols_of_death_buff) Spell(fireblood)
 #ancestral_call,if=buff.symbols_of_death.up
 if BuffPresent(symbols_of_death_buff) Spell(ancestral_call)
 #shadow_blades,if=combo_points.deficit>=2+stealthed.all
 if ComboPointsDeficit() >= 2 + Stealthed() and Boss() Spell(shadow_blades)
}

AddFunction SubtletyCdsCdPostConditions
{
 Enemies(tagged=1) >= 3 and not Talent(shadow_focus_talent) and target.DebuffPresent(nightblade_debuff) and not Stealthed() and not SpellCooldown(symbols_of_death) > 0 and SpellCharges(shadow_dance) >= 1 and Spell(shuriken_tornado) or Enemies(tagged=1) >= 3 and Talent(shadow_focus_talent) and target.DebuffPresent(nightblade_debuff) and BuffPresent(symbols_of_death_buff) and Spell(shuriken_tornado)
}

### actions.finish

AddFunction SubtletyFinishMainActions
{
 #eviscerate,if=talent.shadow_focus.enabled&buff.nights_vengeance.up&spell_targets.shuriken_storm>=2+3*talent.secret_technique.enabled
 if Talent(shadow_focus_talent) and BuffPresent(nights_vengeance_buff) and Enemies(tagged=1) >= 2 + 3 * TalentPoints(secret_technique_talent) Spell(eviscerate)
 #nightblade,if=(!talent.dark_shadow.enabled|!buff.shadow_dance.up)&target.time_to_die-remains>6&remains<tick_time*2
 if { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.CurrentTickTime(nightblade_debuff) * 2 Spell(nightblade)
 #nightblade,cycle_targets=1,if=!variable.use_priority_rotation&spell_targets.shuriken_storm>=2&(azerite.nights_vengeance.enabled|!azerite.replicating_shadows.enabled|spell_targets.shuriken_storm-active_dot.nightblade>=2)&!buff.shadow_dance.up&target.time_to_die>=(5+(2*combo_points))&refreshable
 if not use_priority_rotation() and Enemies(tagged=1) >= 2 and { HasAzeriteTrait(nights_vengeance_trait) or not HasAzeriteTrait(replicating_shadows_trait) or Enemies(tagged=1) - DebuffCountOnAny(nightblade_debuff) >= 2 } and not BuffPresent(shadow_dance_buff) and target.TimeToDie() >= 5 + 2 * ComboPoints() and target.Refreshable(nightblade_debuff) Spell(nightblade)
 #nightblade,if=remains<cooldown.symbols_of_death.remains+10&cooldown.symbols_of_death.remains<=5&target.time_to_die-remains>cooldown.symbols_of_death.remains+5
 if target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 Spell(nightblade)
 #eviscerate
 Spell(eviscerate)
}

AddFunction SubtletyFinishMainPostConditions
{
}

AddFunction SubtletyFinishShortCdActions
{
 unless Talent(shadow_focus_talent) and BuffPresent(nights_vengeance_buff) and Enemies(tagged=1) >= 2 + 3 * TalentPoints(secret_technique_talent) and Spell(eviscerate) or { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.CurrentTickTime(nightblade_debuff) * 2 and Spell(nightblade) or not use_priority_rotation() and Enemies(tagged=1) >= 2 and { HasAzeriteTrait(nights_vengeance_trait) or not HasAzeriteTrait(replicating_shadows_trait) or Enemies(tagged=1) - DebuffCountOnAny(nightblade_debuff) >= 2 } and not BuffPresent(shadow_dance_buff) and target.TimeToDie() >= 5 + 2 * ComboPoints() and target.Refreshable(nightblade_debuff) and Spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 and Spell(nightblade)
 {
  #secret_technique,if=buff.symbols_of_death.up&(!talent.dark_shadow.enabled|buff.shadow_dance.up)
  if BuffPresent(symbols_of_death_buff) and { not Talent(dark_shadow_talent) or BuffPresent(shadow_dance_buff) } Spell(secret_technique)
  #secret_technique,if=spell_targets.shuriken_storm>=2+talent.dark_shadow.enabled+talent.nightstalker.enabled
  if Enemies(tagged=1) >= 2 + TalentPoints(dark_shadow_talent) + TalentPoints(nightstalker_talent) Spell(secret_technique)
 }
}

AddFunction SubtletyFinishShortCdPostConditions
{
 Talent(shadow_focus_talent) and BuffPresent(nights_vengeance_buff) and Enemies(tagged=1) >= 2 + 3 * TalentPoints(secret_technique_talent) and Spell(eviscerate) or { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.CurrentTickTime(nightblade_debuff) * 2 and Spell(nightblade) or not use_priority_rotation() and Enemies(tagged=1) >= 2 and { HasAzeriteTrait(nights_vengeance_trait) or not HasAzeriteTrait(replicating_shadows_trait) or Enemies(tagged=1) - DebuffCountOnAny(nightblade_debuff) >= 2 } and not BuffPresent(shadow_dance_buff) and target.TimeToDie() >= 5 + 2 * ComboPoints() and target.Refreshable(nightblade_debuff) and Spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 and Spell(nightblade) or Spell(eviscerate)
}

AddFunction SubtletyFinishCdActions
{
}

AddFunction SubtletyFinishCdPostConditions
{
 Talent(shadow_focus_talent) and BuffPresent(nights_vengeance_buff) and Enemies(tagged=1) >= 2 + 3 * TalentPoints(secret_technique_talent) and Spell(eviscerate) or { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.CurrentTickTime(nightblade_debuff) * 2 and Spell(nightblade) or not use_priority_rotation() and Enemies(tagged=1) >= 2 and { HasAzeriteTrait(nights_vengeance_trait) or not HasAzeriteTrait(replicating_shadows_trait) or Enemies(tagged=1) - DebuffCountOnAny(nightblade_debuff) >= 2 } and not BuffPresent(shadow_dance_buff) and target.TimeToDie() >= 5 + 2 * ComboPoints() and target.Refreshable(nightblade_debuff) and Spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 and Spell(nightblade) or BuffPresent(symbols_of_death_buff) and { not Talent(dark_shadow_talent) or BuffPresent(shadow_dance_buff) } and Spell(secret_technique) or Enemies(tagged=1) >= 2 + TalentPoints(dark_shadow_talent) + TalentPoints(nightstalker_talent) and Spell(secret_technique) or Spell(eviscerate)
}

### actions.precombat

AddFunction SubtletyPrecombatMainActions
{
}

AddFunction SubtletyPrecombatMainPostConditions
{
}

AddFunction SubtletyPrecombatShortCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #stealth
 Spell(stealth)
 #marked_for_death,precombat_seconds=15
 Spell(marked_for_death)
}

AddFunction SubtletyPrecombatShortCdPostConditions
{
}

AddFunction SubtletyPrecombatCdActions
{
 #shadow_blades,precombat_seconds=1
 Spell(shadow_blades)
 #potion
 # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
}

AddFunction SubtletyPrecombatCdPostConditions
{
}

### actions.stealth_cds

AddFunction SubtletyStealthCdsMainActions
{
}

AddFunction SubtletyStealthCdsMainPostConditions
{
}

AddFunction SubtletyStealthCdsShortCdActions
{
 #variable,name=shd_threshold,value=cooldown.shadow_dance.charges_fractional>=1.75
 #vanish,if=!variable.shd_threshold&debuff.find_weakness.remains<1&combo_points.deficit>1
 if not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 and ComboPointsDeficit() > 1 and VanishAllowed() Spell(vanish)
 #pool_resource,for_next=1,extra_amount=40
 #shadowmeld,if=energy>=40&energy.deficit>=10&!variable.shd_threshold&debuff.find_weakness.remains<1&combo_points.deficit>1
 unless True(pool_energy 40) and EnergyDeficit() >= 10 and not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 and ComboPointsDeficit() > 1 and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(40)
 {
  #shadow_dance,if=(!talent.dark_shadow.enabled|dot.nightblade.remains>=5+talent.subterfuge.enabled)&(!talent.nightstalker.enabled&!talent.dark_shadow.enabled|!variable.use_priority_rotation|combo_points.deficit<=1+2*azerite.the_first_dance.enabled)&(variable.shd_threshold|buff.symbols_of_death.remains>=1.2|spell_targets.shuriken_storm>=4&cooldown.symbols_of_death.remains>10)
  if { not Talent(dark_shadow_talent) or target.DebuffRemaining(nightblade_debuff) >= 5 + TalentPoints(subterfuge_talent) } and { not Talent(nightstalker_talent) and not Talent(dark_shadow_talent) or not use_priority_rotation() or ComboPointsDeficit() <= 1 + 2 * HasAzeriteTrait(the_first_dance_trait) } and { shd_threshold() or BuffRemaining(symbols_of_death_buff) >= 1.2 or Enemies(tagged=1) >= 4 and SpellCooldown(symbols_of_death) > 10 } Spell(shadow_dance)
  #shadow_dance,if=target.time_to_die<cooldown.symbols_of_death.remains&!raid_event.adds.up
  if target.TimeToDie() < SpellCooldown(symbols_of_death) and not False(raid_event_adds_exists) Spell(shadow_dance)
 }
}

AddFunction SubtletyStealthCdsShortCdPostConditions
{
}

AddFunction SubtletyStealthCdsCdActions
{
 #pool_resource,for_next=1,extra_amount=40
 #shadowmeld,if=energy>=40&energy.deficit>=10&!variable.shd_threshold&debuff.find_weakness.remains<1&combo_points.deficit>1
 if Energy() >= 40 and EnergyDeficit() >= 10 and not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 and ComboPointsDeficit() > 1 Spell(shadowmeld)
}

AddFunction SubtletyStealthCdsCdPostConditions
{
}

### actions.stealthed

AddFunction SubtletyStealthedMainActions
{
 #shadowstrike,if=buff.stealth.up
 if BuffPresent(stealth_buff) Spell(shadowstrike)
 #call_action_list,name=finish,if=combo_points.deficit<=1-(talent.deeper_stratagem.enabled&buff.vanish.up)
 if ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } SubtletyFinishMainActions()

 unless ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and SubtletyFinishMainPostConditions()
 {
  #shadowstrike,cycle_targets=1,if=talent.secret_technique.enabled&talent.find_weakness.enabled&debuff.find_weakness.remains<1&spell_targets.shuriken_storm=2&target.time_to_die-remains>6
  if Talent(secret_technique_talent) and Talent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 and Enemies(tagged=1) == 2 and target.TimeToDie() - target.DebuffRemaining(shadowstrike) > 6 Spell(shadowstrike)
  #shadowstrike,if=!talent.deeper_stratagem.enabled&azerite.blade_in_the_shadows.rank=3&spell_targets.shuriken_storm=3
  if not Talent(deeper_stratagem_talent) and AzeriteTraitRank(blade_in_the_shadows_trait) == 3 and Enemies(tagged=1) == 3 Spell(shadowstrike)
  #shuriken_storm,if=spell_targets>=3
  if Enemies(tagged=1) >= 3 Spell(shuriken_storm)
  #shadowstrike
  Spell(shadowstrike)
 }
}

AddFunction SubtletyStealthedMainPostConditions
{
 ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and SubtletyFinishMainPostConditions()
}

AddFunction SubtletyStealthedShortCdActions
{
 unless BuffPresent(stealth_buff) and Spell(shadowstrike)
 {
  #call_action_list,name=finish,if=combo_points.deficit<=1-(talent.deeper_stratagem.enabled&buff.vanish.up)
  if ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } SubtletyFinishShortCdActions()
 }
}

AddFunction SubtletyStealthedShortCdPostConditions
{
 BuffPresent(stealth_buff) and Spell(shadowstrike) or ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and SubtletyFinishShortCdPostConditions() or Talent(secret_technique_talent) and Talent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 and Enemies(tagged=1) == 2 and target.TimeToDie() - target.DebuffRemaining(shadowstrike) > 6 and Spell(shadowstrike) or not Talent(deeper_stratagem_talent) and AzeriteTraitRank(blade_in_the_shadows_trait) == 3 and Enemies(tagged=1) == 3 and Spell(shadowstrike) or Enemies(tagged=1) >= 3 and Spell(shuriken_storm) or Spell(shadowstrike)
}

AddFunction SubtletyStealthedCdActions
{
 unless BuffPresent(stealth_buff) and Spell(shadowstrike)
 {
  #call_action_list,name=finish,if=combo_points.deficit<=1-(talent.deeper_stratagem.enabled&buff.vanish.up)
  if ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } SubtletyFinishCdActions()
 }
}

AddFunction SubtletyStealthedCdPostConditions
{
 BuffPresent(stealth_buff) and Spell(shadowstrike) or ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and SubtletyFinishCdPostConditions() or Talent(secret_technique_talent) and Talent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 and Enemies(tagged=1) == 2 and target.TimeToDie() - target.DebuffRemaining(shadowstrike) > 6 and Spell(shadowstrike) or not Talent(deeper_stratagem_talent) and AzeriteTraitRank(blade_in_the_shadows_trait) == 3 and Enemies(tagged=1) == 3 and Spell(shadowstrike) or Enemies(tagged=1) >= 3 and Spell(shuriken_storm) or Spell(shadowstrike)
}
]]

		OvaleScripts:RegisterScript("ROGUE", "subtlety", name, desc, code, "script")
	end
end
