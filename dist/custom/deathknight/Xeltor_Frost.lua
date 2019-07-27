local __exports = LibStub:GetLibrary("ovale/scripts/ovale_deathknight")
if not __exports then return end
__exports.registerDeathKnightFrostXeltor = function(OvaleScripts)
do
	local name = "xeltor_frost"
	local desc = "[Xel][8.0] Death Knight: Frost"
	local code = [[
# Common functions.
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)

# Frost
AddIcon specialization=2 help=main
{
	# Interrupt
	if InCombat() and { not target.IsFriend() or target.IsPvP() } InterruptActions()
	
    if target.InRange(obliterate) and HasFullControl()
    {
		if BuffStacks(dark_succor_buff) Spell(death_strike)
		
		# Cooldown
		if Boss() FrostDefaultCdActions()
		
		# Short Cooldown
		FrostDefaultShortCdActions()
		
		# Main rotation
		FrostDefaultMainActions()
    }
}

# Custom functions.
AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.InRange(mind_freeze) Spell(mind_freeze)
		if not target.Classification(worldboss)
		{
			if target.InRange(asphyxiate) Spell(asphyxiate)
			# if target.InRange(strangulate) Spell(strangulate)
			if target.Distance(less 12) Spell(blinding_sleet)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			if target.Distance(less 8) Spell(war_stomp)
		}
	}
}

### actions.default

AddFunction FrostDefaultMainActions
{
 #howling_blast,if=!dot.frost_fever.ticking&(!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>15)
 if not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } Spell(howling_blast)
 #glacial_advance,if=buff.icy_talons.remains<=gcd&buff.icy_talons.up&spell_targets.glacial_advance>=2&(!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>15)
 if BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies(tagged=1) >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } Spell(glacial_advance)
 #frost_strike,if=buff.icy_talons.remains<=gcd&buff.icy_talons.up&(!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>15)
 if BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } Spell(frost_strike)
 #call_action_list,name=cooldowns
 FrostCooldownsMainActions()

 unless FrostCooldownsMainPostConditions()
 {
  #run_action_list,name=bos_pooling,if=talent.breath_of_sindragosa.enabled&cooldown.breath_of_sindragosa.remains<5
  if Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 FrostBosPoolingMainActions()

  unless Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 and FrostBosPoolingMainPostConditions()
  {
   #run_action_list,name=bos_ticking,if=dot.breath_of_sindragosa.ticking
   if BuffPresent(breath_of_sindragosa_buff) FrostBosTickingMainActions()

   unless BuffPresent(breath_of_sindragosa_buff) and FrostBosTickingMainPostConditions()
   {
    #run_action_list,name=obliteration,if=buff.pillar_of_frost.up&talent.obliteration.enabled
    if BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) FrostObliterationMainActions()

    unless BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationMainPostConditions()
    {
     #run_action_list,name=aoe,if=active_enemies>=2
     if Enemies(tagged=1) >= 2 FrostAoeMainActions()

     unless Enemies(tagged=1) >= 2 and FrostAoeMainPostConditions()
     {
      #call_action_list,name=standard
      FrostStandardMainActions()
     }
    }
   }
  }
 }
}

AddFunction FrostDefaultMainPostConditions
{
 FrostCooldownsMainPostConditions() or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 and FrostBosPoolingMainPostConditions() or BuffPresent(breath_of_sindragosa_buff) and FrostBosTickingMainPostConditions() or BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationMainPostConditions() or Enemies(tagged=1) >= 2 and FrostAoeMainPostConditions() or FrostStandardMainPostConditions()
}

AddFunction FrostDefaultShortCdActions
{
 #auto_attack
 # FrostGetInMeleeRange()

 unless not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(howling_blast) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies(tagged=1) >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(glacial_advance) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(frost_strike)
 {
  #call_action_list,name=cooldowns
  FrostCooldownsShortCdActions()

  unless FrostCooldownsShortCdPostConditions()
  {
   #run_action_list,name=bos_pooling,if=talent.breath_of_sindragosa.enabled&cooldown.breath_of_sindragosa.remains<5
   if Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 FrostBosPoolingShortCdActions()

   unless Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 and FrostBosPoolingShortCdPostConditions()
   {
    #run_action_list,name=bos_ticking,if=dot.breath_of_sindragosa.ticking
    if BuffPresent(breath_of_sindragosa_buff) FrostBosTickingShortCdActions()

    unless BuffPresent(breath_of_sindragosa_buff) and FrostBosTickingShortCdPostConditions()
    {
     #run_action_list,name=obliteration,if=buff.pillar_of_frost.up&talent.obliteration.enabled
     if BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) FrostObliterationShortCdActions()

     unless BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationShortCdPostConditions()
     {
      #run_action_list,name=aoe,if=active_enemies>=2
      if Enemies(tagged=1) >= 2 FrostAoeShortCdActions()

      unless Enemies(tagged=1) >= 2 and FrostAoeShortCdPostConditions()
      {
       #call_action_list,name=standard
       FrostStandardShortCdActions()
      }
     }
    }
   }
  }
 }
}

AddFunction FrostDefaultShortCdPostConditions
{
 not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(howling_blast) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies(tagged=1) >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(glacial_advance) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(frost_strike) or FrostCooldownsShortCdPostConditions() or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 and FrostBosPoolingShortCdPostConditions() or BuffPresent(breath_of_sindragosa_buff) and FrostBosTickingShortCdPostConditions() or BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationShortCdPostConditions() or Enemies(tagged=1) >= 2 and FrostAoeShortCdPostConditions() or FrostStandardShortCdPostConditions()
}

AddFunction FrostDefaultCdActions
{
 #mind_freeze
 # FrostInterruptActions()

 unless not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(howling_blast) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies(tagged=1) >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(glacial_advance) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(frost_strike)
 {
  #breath_of_sindragosa,if=cooldown.empower_rune_weapon.remains&cooldown.pillar_of_frost.remains
  if SpellCooldown(empower_rune_weapon) > 0 and SpellCooldown(pillar_of_frost) > 0 Spell(breath_of_sindragosa)
  #call_action_list,name=cooldowns
  FrostCooldownsCdActions()

  unless FrostCooldownsCdPostConditions()
  {
   #run_action_list,name=bos_pooling,if=talent.breath_of_sindragosa.enabled&cooldown.breath_of_sindragosa.remains<5
   if Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 FrostBosPoolingCdActions()

   unless Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 and FrostBosPoolingCdPostConditions()
   {
    #run_action_list,name=bos_ticking,if=dot.breath_of_sindragosa.ticking
    if BuffPresent(breath_of_sindragosa_buff) FrostBosTickingCdActions()

    unless BuffPresent(breath_of_sindragosa_buff) and FrostBosTickingCdPostConditions()
    {
     #run_action_list,name=obliteration,if=buff.pillar_of_frost.up&talent.obliteration.enabled
     if BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) FrostObliterationCdActions()

     unless BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationCdPostConditions()
     {
      #run_action_list,name=aoe,if=active_enemies>=2
      if Enemies(tagged=1) >= 2 FrostAoeCdActions()

      unless Enemies(tagged=1) >= 2 and FrostAoeCdPostConditions()
      {
       #call_action_list,name=standard
       FrostStandardCdActions()
      }
     }
    }
   }
  }
 }
}

AddFunction FrostDefaultCdPostConditions
{
 not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(howling_blast) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies(tagged=1) >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(glacial_advance) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(frost_strike) or FrostCooldownsCdPostConditions() or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 and FrostBosPoolingCdPostConditions() or BuffPresent(breath_of_sindragosa_buff) and FrostBosTickingCdPostConditions() or BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationCdPostConditions() or Enemies(tagged=1) >= 2 and FrostAoeCdPostConditions() or FrostStandardCdPostConditions()
}

### actions.aoe

AddFunction FrostAoeMainActions
{
 #remorseless_winter,if=talent.gathering_storm.enabled
 if Talent(gathering_storm_talent) Spell(remorseless_winter)
 #glacial_advance,if=talent.frostscythe.enabled
 if Talent(frostscythe_talent) Spell(glacial_advance)
 #frost_strike,if=cooldown.remorseless_winter.remains<=2*gcd&talent.gathering_storm.enabled
 if SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) Spell(frost_strike)
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
 #frostscythe,if=buff.killing_machine.up
 if BuffPresent(killing_machine_buff) Spell(frostscythe)
 #glacial_advance,if=runic_power.deficit<(15+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 Spell(glacial_advance)
 #frost_strike,if=runic_power.deficit<(15+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 Spell(frost_strike)
 #remorseless_winter
 Spell(remorseless_winter)
 #frostscythe
 Spell(frostscythe)
 #obliterate,if=runic_power.deficit>(25+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 Spell(obliterate)
 #glacial_advance
 Spell(glacial_advance)
 #frost_strike
 Spell(frost_strike)
 #horn_of_winter
 Spell(horn_of_winter)
}

AddFunction FrostAoeMainPostConditions
{
}

AddFunction FrostAoeShortCdActions
{
}

AddFunction FrostAoeShortCdPostConditions
{
 Talent(gathering_storm_talent) and Spell(remorseless_winter) or Talent(frostscythe_talent) and Spell(glacial_advance) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(glacial_advance) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frost_strike) or Spell(remorseless_winter) or Spell(frostscythe) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(glacial_advance) or Spell(frost_strike) or Spell(horn_of_winter)
}

AddFunction FrostAoeCdActions
{
 unless Talent(gathering_storm_talent) and Spell(remorseless_winter) or Talent(frostscythe_talent) and Spell(glacial_advance) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(glacial_advance) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frost_strike) or Spell(remorseless_winter) or Spell(frostscythe) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(glacial_advance) or Spell(frost_strike) or Spell(horn_of_winter)
 {
  #arcane_torrent
  Spell(arcane_torrent_runicpower)
 }
}

AddFunction FrostAoeCdPostConditions
{
 Talent(gathering_storm_talent) and Spell(remorseless_winter) or Talent(frostscythe_talent) and Spell(glacial_advance) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(glacial_advance) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frost_strike) or Spell(remorseless_winter) or Spell(frostscythe) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(glacial_advance) or Spell(frost_strike) or Spell(horn_of_winter)
}

### actions.bos_pooling

AddFunction FrostBosPoolingMainActions
{
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
 #obliterate,if=rune.time_to_4<gcd&runic_power.deficit>=25
 if TimeToRunes(4) < GCD() and RunicPowerDeficit() >= 25 Spell(obliterate)
 #glacial_advance,if=runic_power.deficit<20&cooldown.pillar_of_frost.remains>rune.time_to_4
 if RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > TimeToRunes(4) Spell(glacial_advance)
 #frost_strike,if=runic_power.deficit<20&cooldown.pillar_of_frost.remains>rune.time_to_4
 if RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > TimeToRunes(4) Spell(frost_strike)
 #frostscythe,if=buff.killing_machine.up&runic_power.deficit>(15+talent.runic_attenuation.enabled*3)
 if BuffPresent(killing_machine_buff) and RunicPowerDeficit() > 15 + TalentPoints(runic_attenuation_talent) * 3 Spell(frostscythe)
 #obliterate,if=runic_power.deficit>=(25+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() >= 25 + TalentPoints(runic_attenuation_talent) * 3 Spell(obliterate)
 #glacial_advance,if=cooldown.pillar_of_frost.remains>rune.time_to_4&runic_power.deficit<40&spell_targets.glacial_advance>=2
 if SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Enemies(tagged=1) >= 2 Spell(glacial_advance)
 #frost_strike,if=cooldown.pillar_of_frost.remains>rune.time_to_4&runic_power.deficit<40
 if SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 Spell(frost_strike)
}

AddFunction FrostBosPoolingMainPostConditions
{
}

AddFunction FrostBosPoolingShortCdActions
{
}

AddFunction FrostBosPoolingShortCdPostConditions
{
 BuffPresent(rime_buff) and Spell(howling_blast) or TimeToRunes(4) < GCD() and RunicPowerDeficit() >= 25 and Spell(obliterate) or RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > TimeToRunes(4) and Spell(glacial_advance) or RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > TimeToRunes(4) and Spell(frost_strike) or BuffPresent(killing_machine_buff) and RunicPowerDeficit() > 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frostscythe) or RunicPowerDeficit() >= 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Enemies(tagged=1) >= 2 and Spell(glacial_advance) or SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Spell(frost_strike)
}

AddFunction FrostBosPoolingCdActions
{
}

AddFunction FrostBosPoolingCdPostConditions
{
 BuffPresent(rime_buff) and Spell(howling_blast) or TimeToRunes(4) < GCD() and RunicPowerDeficit() >= 25 and Spell(obliterate) or RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > TimeToRunes(4) and Spell(glacial_advance) or RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > TimeToRunes(4) and Spell(frost_strike) or BuffPresent(killing_machine_buff) and RunicPowerDeficit() > 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frostscythe) or RunicPowerDeficit() >= 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Enemies(tagged=1) >= 2 and Spell(glacial_advance) or SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Spell(frost_strike)
}

### actions.bos_ticking

AddFunction FrostBosTickingMainActions
{
 #obliterate,if=runic_power<=30
 if RunicPower() <= 30 Spell(obliterate)
 #remorseless_winter,if=talent.gathering_storm.enabled
 if Talent(gathering_storm_talent) Spell(remorseless_winter)
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
 #obliterate,if=rune.time_to_5<gcd|runic_power<=45
 if TimeToRunes(5) < GCD() or RunicPower() <= 45 Spell(obliterate)
 #frostscythe,if=buff.killing_machine.up
 if BuffPresent(killing_machine_buff) Spell(frostscythe)
 #horn_of_winter,if=runic_power.deficit>=30&rune.time_to_3>gcd
 if RunicPowerDeficit() >= 30 and TimeToRunes(3) > GCD() Spell(horn_of_winter)
 #remorseless_winter
 Spell(remorseless_winter)
 #frostscythe,if=spell_targets.frostscythe>=2
 if Enemies(tagged=1) >= 2 Spell(frostscythe)
 #obliterate,if=runic_power.deficit>25|rune>3
 if RunicPowerDeficit() > 25 or Rune() >= 4 Spell(obliterate)
}

AddFunction FrostBosTickingMainPostConditions
{
}

AddFunction FrostBosTickingShortCdActions
{
}

AddFunction FrostBosTickingShortCdPostConditions
{
 RunicPower() <= 30 and Spell(obliterate) or Talent(gathering_storm_talent) and Spell(remorseless_winter) or BuffPresent(rime_buff) and Spell(howling_blast) or { TimeToRunes(5) < GCD() or RunicPower() <= 45 } and Spell(obliterate) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() >= 30 and TimeToRunes(3) > GCD() and Spell(horn_of_winter) or Spell(remorseless_winter) or Enemies(tagged=1) >= 2 and Spell(frostscythe) or { RunicPowerDeficit() > 25 or Rune() >= 4 } and Spell(obliterate)
}

AddFunction FrostBosTickingCdActions
{
 unless RunicPower() <= 30 and Spell(obliterate) or Talent(gathering_storm_talent) and Spell(remorseless_winter) or BuffPresent(rime_buff) and Spell(howling_blast) or { TimeToRunes(5) < GCD() or RunicPower() <= 45 } and Spell(obliterate) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() >= 30 and TimeToRunes(3) > GCD() and Spell(horn_of_winter) or Spell(remorseless_winter) or Enemies(tagged=1) >= 2 and Spell(frostscythe) or { RunicPowerDeficit() > 25 or Rune() >= 4 } and Spell(obliterate)
 {
  #arcane_torrent,if=runic_power.deficit>20
  if RunicPowerDeficit() > 20 Spell(arcane_torrent_runicpower)
 }
}

AddFunction FrostBosTickingCdPostConditions
{
 RunicPower() <= 30 and Spell(obliterate) or Talent(gathering_storm_talent) and Spell(remorseless_winter) or BuffPresent(rime_buff) and Spell(howling_blast) or { TimeToRunes(5) < GCD() or RunicPower() <= 45 } and Spell(obliterate) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() >= 30 and TimeToRunes(3) > GCD() and Spell(horn_of_winter) or Spell(remorseless_winter) or Enemies(tagged=1) >= 2 and Spell(frostscythe) or { RunicPowerDeficit() > 25 or Rune() >= 4 } and Spell(obliterate)
}

### actions.cold_heart

AddFunction FrostColdHeartMainActions
{
 #chains_of_ice,if=(buff.cold_heart_item.stack>5|buff.cold_heart_talent.stack>5)&target.time_to_die<gcd
 if { BuffStacks(cold_heart_item_buff) > 5 or BuffStacks(cold_heart_talent_buff) > 5 } and target.TimeToDie() < GCD() Spell(chains_of_ice)
 #chains_of_ice,if=(buff.pillar_of_frost.remains<=gcd*(1+cooldown.frostwyrms_fury.ready)|buff.pillar_of_frost.remains<rune.time_to_3)&buff.pillar_of_frost.up
 if { BuffRemaining(pillar_of_frost_buff) <= GCD() * { 1 + { SpellCooldown(frostwyrms_fury) == 0 } } or BuffRemaining(pillar_of_frost_buff) < TimeToRunes(3) } and BuffPresent(pillar_of_frost_buff) Spell(chains_of_ice)
}

AddFunction FrostColdHeartMainPostConditions
{
}

AddFunction FrostColdHeartShortCdActions
{
}

AddFunction FrostColdHeartShortCdPostConditions
{
 { BuffStacks(cold_heart_item_buff) > 5 or BuffStacks(cold_heart_talent_buff) > 5 } and target.TimeToDie() < GCD() and Spell(chains_of_ice) or { BuffRemaining(pillar_of_frost_buff) <= GCD() * { 1 + { SpellCooldown(frostwyrms_fury) == 0 } } or BuffRemaining(pillar_of_frost_buff) < TimeToRunes(3) } and BuffPresent(pillar_of_frost_buff) and Spell(chains_of_ice)
}

AddFunction FrostColdHeartCdActions
{
}

AddFunction FrostColdHeartCdPostConditions
{
 { BuffStacks(cold_heart_item_buff) > 5 or BuffStacks(cold_heart_talent_buff) > 5 } and target.TimeToDie() < GCD() and Spell(chains_of_ice) or { BuffRemaining(pillar_of_frost_buff) <= GCD() * { 1 + { SpellCooldown(frostwyrms_fury) == 0 } } or BuffRemaining(pillar_of_frost_buff) < TimeToRunes(3) } and BuffPresent(pillar_of_frost_buff) and Spell(chains_of_ice)
}

### actions.cooldowns

AddFunction FrostCooldownsMainActions
{
 #call_action_list,name=cold_heart,if=(equipped.cold_heart|talent.cold_heart.enabled)&(((buff.cold_heart_item.stack>=10|buff.cold_heart_talent.stack>=10)&debuff.razorice.stack=5)|target.time_to_die<=gcd)
 if { HasEquippedItem(cold_heart) or Talent(cold_heart_talent) } and { { BuffStacks(cold_heart_item_buff) >= 10 or BuffStacks(cold_heart_talent_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } FrostColdHeartMainActions()
}

AddFunction FrostCooldownsMainPostConditions
{
 { HasEquippedItem(cold_heart) or Talent(cold_heart_talent) } and { { BuffStacks(cold_heart_item_buff) >= 10 or BuffStacks(cold_heart_talent_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } and FrostColdHeartMainPostConditions()
}

AddFunction FrostCooldownsShortCdActions
{
 #pillar_of_frost,if=cooldown.empower_rune_weapon.remains
 if SpellCooldown(empower_rune_weapon) > 0 Spell(pillar_of_frost)
 #call_action_list,name=cold_heart,if=(equipped.cold_heart|talent.cold_heart.enabled)&(((buff.cold_heart_item.stack>=10|buff.cold_heart_talent.stack>=10)&debuff.razorice.stack=5)|target.time_to_die<=gcd)
 if { HasEquippedItem(cold_heart) or Talent(cold_heart_talent) } and { { BuffStacks(cold_heart_item_buff) >= 10 or BuffStacks(cold_heart_talent_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } FrostColdHeartShortCdActions()
}

AddFunction FrostCooldownsShortCdPostConditions
{
 { HasEquippedItem(cold_heart) or Talent(cold_heart_talent) } and { { BuffStacks(cold_heart_item_buff) >= 10 or BuffStacks(cold_heart_talent_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } and FrostColdHeartShortCdPostConditions()
}

AddFunction FrostCooldownsCdActions
{
 #use_items
 # FrostUseItemActions()
 #use_item,name=horn_of_valor,if=buff.pillar_of_frost.up&(!talent.breath_of_sindragosa.enabled|!cooldown.breath_of_sindragosa.remains)
 # if BuffPresent(pillar_of_frost_buff) and { not Talent(breath_of_sindragosa_talent) or not SpellCooldown(breath_of_sindragosa) > 0 } FrostUseItemActions()
 #potion,if=buff.pillar_of_frost.up&buff.empower_rune_weapon.up
 # if BuffPresent(pillar_of_frost_buff) and BuffPresent(empower_rune_weapon_buff) and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 #blood_fury,if=buff.pillar_of_frost.up&buff.empower_rune_weapon.up
 if BuffPresent(pillar_of_frost_buff) and BuffPresent(empower_rune_weapon_buff) Spell(blood_fury_ap)
 #berserking,if=buff.pillar_of_frost.up
 if BuffPresent(pillar_of_frost_buff) Spell(berserking)

 unless SpellCooldown(empower_rune_weapon) > 0 and Spell(pillar_of_frost)
 {
  #empower_rune_weapon,if=cooldown.pillar_of_frost.ready&!talent.breath_of_sindragosa.enabled&rune.time_to_5>gcd&runic_power.deficit>=10
  if SpellCooldown(pillar_of_frost) == 0 and not Talent(breath_of_sindragosa_talent) and TimeToRunes(5) > GCD() and RunicPowerDeficit() >= 10 Spell(empower_rune_weapon)
  #empower_rune_weapon,if=cooldown.pillar_of_frost.ready&talent.breath_of_sindragosa.enabled&rune>=3&runic_power>60
  if SpellCooldown(pillar_of_frost) == 0 and Talent(breath_of_sindragosa_talent) and Rune() >= 3 and RunicPower() > 60 Spell(empower_rune_weapon)
  #call_action_list,name=cold_heart,if=(equipped.cold_heart|talent.cold_heart.enabled)&(((buff.cold_heart_item.stack>=10|buff.cold_heart_talent.stack>=10)&debuff.razorice.stack=5)|target.time_to_die<=gcd)
  if { HasEquippedItem(cold_heart) or Talent(cold_heart_talent) } and { { BuffStacks(cold_heart_item_buff) >= 10 or BuffStacks(cold_heart_talent_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } FrostColdHeartCdActions()

  unless { HasEquippedItem(cold_heart) or Talent(cold_heart_talent) } and { { BuffStacks(cold_heart_item_buff) >= 10 or BuffStacks(cold_heart_talent_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } and FrostColdHeartCdPostConditions()
  {
   #frostwyrms_fury,if=(buff.pillar_of_frost.remains<=gcd&buff.pillar_of_frost.up)
   if BuffRemaining(pillar_of_frost_buff) <= GCD() and BuffPresent(pillar_of_frost_buff) Spell(frostwyrms_fury)
  }
 }
}

AddFunction FrostCooldownsCdPostConditions
{
 SpellCooldown(empower_rune_weapon) > 0 and Spell(pillar_of_frost) or { HasEquippedItem(cold_heart) or Talent(cold_heart_talent) } and { { BuffStacks(cold_heart_item_buff) >= 10 or BuffStacks(cold_heart_talent_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } and FrostColdHeartCdPostConditions()
}

### actions.obliteration

AddFunction FrostObliterationMainActions
{
 #remorseless_winter,if=talent.gathering_storm.enabled
 if Talent(gathering_storm_talent) Spell(remorseless_winter)
 #obliterate,if=!talent.frostscythe.enabled&!buff.rime.up&spell_targets.howling_blast>=3
 if not Talent(frostscythe_talent) and not BuffPresent(rime_buff) and Enemies(tagged=1) >= 3 Spell(obliterate)
 #frostscythe,if=(buff.killing_machine.react|(buff.killing_machine.up&(prev_gcd.1.frost_strike|prev_gcd.1.howling_blast|prev_gcd.1.glacial_advance)))&(rune.time_to_4>gcd|spell_targets.frostscythe>=2)
 if { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and { TimeToRunes(4) > GCD() or Enemies(tagged=1) >= 2 } Spell(frostscythe)
 #obliterate,if=buff.killing_machine.react|(buff.killing_machine.up&(prev_gcd.1.frost_strike|prev_gcd.1.howling_blast|prev_gcd.1.glacial_advance))
 if BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } Spell(obliterate)
 #glacial_advance,if=(!buff.rime.up|runic_power.deficit<10|rune.time_to_2>gcd)&spell_targets.glacial_advance>=2
 if { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Enemies(tagged=1) >= 2 Spell(glacial_advance)
 #howling_blast,if=buff.rime.up&spell_targets.howling_blast>=2
 if BuffPresent(rime_buff) and Enemies(tagged=1) >= 2 Spell(howling_blast)
 #frost_strike,if=!buff.rime.up|runic_power.deficit<10|rune.time_to_2>gcd
 if not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() Spell(frost_strike)
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
 #obliterate
 Spell(obliterate)
}

AddFunction FrostObliterationMainPostConditions
{
}

AddFunction FrostObliterationShortCdActions
{
}

AddFunction FrostObliterationShortCdPostConditions
{
 Talent(gathering_storm_talent) and Spell(remorseless_winter) or not Talent(frostscythe_talent) and not BuffPresent(rime_buff) and Enemies(tagged=1) >= 3 and Spell(obliterate) or { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and { TimeToRunes(4) > GCD() or Enemies(tagged=1) >= 2 } and Spell(frostscythe) or { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and Spell(obliterate) or { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Enemies(tagged=1) >= 2 and Spell(glacial_advance) or BuffPresent(rime_buff) and Enemies(tagged=1) >= 2 and Spell(howling_blast) or { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or Spell(obliterate)
}

AddFunction FrostObliterationCdActions
{
}

AddFunction FrostObliterationCdPostConditions
{
 Talent(gathering_storm_talent) and Spell(remorseless_winter) or not Talent(frostscythe_talent) and not BuffPresent(rime_buff) and Enemies(tagged=1) >= 3 and Spell(obliterate) or { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and { TimeToRunes(4) > GCD() or Enemies(tagged=1) >= 2 } and Spell(frostscythe) or { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and Spell(obliterate) or { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Enemies(tagged=1) >= 2 and Spell(glacial_advance) or BuffPresent(rime_buff) and Enemies(tagged=1) >= 2 and Spell(howling_blast) or { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or Spell(obliterate)
}

### actions.precombat

AddFunction FrostPrecombatMainActions
{
}

AddFunction FrostPrecombatMainPostConditions
{
}

AddFunction FrostPrecombatShortCdActions
{
}

AddFunction FrostPrecombatShortCdPostConditions
{
}

AddFunction FrostPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
}

AddFunction FrostPrecombatCdPostConditions
{
}

### actions.standard

AddFunction FrostStandardMainActions
{
 #remorseless_winter
 Spell(remorseless_winter)
 #frost_strike,if=cooldown.remorseless_winter.remains<=2*gcd&talent.gathering_storm.enabled
 if SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) Spell(frost_strike)
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
 #obliterate,if=!buff.frozen_pulse.up&talent.frozen_pulse.enabled
 if Rune() > 3 and Talent(frozen_pulse_talent) Spell(obliterate)
 #frost_strike,if=runic_power.deficit<(15+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 Spell(frost_strike)
 #frostscythe,if=buff.killing_machine.up&rune.time_to_4>=gcd
 if BuffPresent(killing_machine_buff) and TimeToRunes(4) >= GCD() Spell(frostscythe)
 #obliterate,if=runic_power.deficit>(25+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 Spell(obliterate)
 #frost_strike
 Spell(frost_strike)
 #horn_of_winter
 Spell(horn_of_winter)
}

AddFunction FrostStandardMainPostConditions
{
}

AddFunction FrostStandardShortCdActions
{
}

AddFunction FrostStandardShortCdPostConditions
{
 Spell(remorseless_winter) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or Rune() > 3 and Talent(frozen_pulse_talent) and Spell(obliterate) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frost_strike) or BuffPresent(killing_machine_buff) and TimeToRunes(4) >= GCD() and Spell(frostscythe) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(frost_strike) or Spell(horn_of_winter)
}

AddFunction FrostStandardCdActions
{
 unless Spell(remorseless_winter) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or Rune() > 3 and Talent(frozen_pulse_talent) and Spell(obliterate) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frost_strike) or BuffPresent(killing_machine_buff) and TimeToRunes(4) >= GCD() and Spell(frostscythe) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(frost_strike) or Spell(horn_of_winter)
 {
  #arcane_torrent
  Spell(arcane_torrent_runicpower)
 }
}

AddFunction FrostStandardCdPostConditions
{
 Spell(remorseless_winter) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or Rune() > 3 and Talent(frozen_pulse_talent) and Spell(obliterate) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frost_strike) or BuffPresent(killing_machine_buff) and TimeToRunes(4) >= GCD() and Spell(frostscythe) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(frost_strike) or Spell(horn_of_winter)
}
]]

	OvaleScripts:RegisterScript("DEATHKNIGHT", "frost", name, desc, code, "script")
end
end