local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_t23_priest_shadow"
    local desc = "[8.2] Simulationcraft: T23_Priest_Shadow"
    local code = [[
# Based on SimulationCraft profile "T23_Priest_Shadow".
#	class=priest
#	spec=shadow
#	talents=3111111

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_priest_spells)


AddFunction dots_up
{
 target.DebuffPresent(shadow_word_pain_debuff) and target.DebuffPresent(vampiric_touch_debuff)
}

AddFunction vt_mis_sd_check
{
 1 - 0.014 * AzeriteTraitRank(searing_dialogue_trait)
}

AddFunction vt_mis_trait_ranks_check
{
 { 1 - 0.07 * AzeriteTraitRank(death_throes_trait) - 0.03 * AzeriteTraitRank(thought_harvester_trait) - 0.055 * AzeriteTraitRank(spiteful_apparitions_trait) } * { 1 - 0.027 * AzeriteTraitRank(thought_harvester_trait) * AzeriteTraitRank(searing_dialogue_trait) }
}

AddFunction vt_trait_ranks_check
{
 1 - 0.04 * AzeriteTraitRank(thought_harvester_trait) - 0.05 * AzeriteTraitRank(spiteful_apparitions_trait)
}

AddFunction swp_trait_ranks_check
{
 { 1 - 0.07 * AzeriteTraitRank(death_throes_trait) + 0.2 * AzeriteTraitRank(thought_harvester_trait) } * { 1 - 0.09 * AzeriteTraitRank(thought_harvester_trait) * AzeriteTraitRank(searing_dialogue_trait) }
}

AddFunction mind_blast_targets
{
 { 4.5 + AzeriteTraitRank(whispers_of_the_damned_trait) } / { 1 + 0.27 * AzeriteTraitRank(searing_dialogue_trait) }
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=shadow)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=shadow)

AddFunction ShadowInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(silence) and target.IsInterruptible() Spell(silence)
  if target.InRange(mind_bomb) and not target.Classification(worldboss) and target.RemainingCastTime() > 2 Spell(mind_bomb)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
 }
}

AddFunction ShadowUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.single

AddFunction ShadowSingleMainActions
{
 #void_eruption
 Spell(void_eruption)
 #void_bolt
 Spell(void_bolt)
 #focused_azerite_beam
 Spell(focused_azerite_beam)
 #concentrated_flame
 Spell(concentrated_flame_essence)
 #mind_sear,if=buff.harvested_thoughts.up&cooldown.void_bolt.remains>=1.5&azerite.searing_dialogue.rank>=1
 if BuffPresent(harvested_thoughts_buff) and SpellCooldown(void_bolt) >= 1.5 and AzeriteTraitRank(searing_dialogue_trait) >= 1 Spell(mind_sear)
 #shadow_word_death,if=target.time_to_die<3|cooldown.shadow_word_death.charges=2|(cooldown.shadow_word_death.charges=1&cooldown.shadow_word_death.remains<gcd.max)
 if target.TimeToDie() < 3 or SpellCharges(shadow_word_death) == 2 or SpellCharges(shadow_word_death) == 1 and SpellCooldown(shadow_word_death) < GCD() Spell(shadow_word_death)
 #mindbender,if=talent.mindbender.enabled|(buff.voidform.stack>18|target.time_to_die<15)
 if Talent(mindbender_talent) or BuffStacks(voidform_shadow) > 18 or target.TimeToDie() < 15 Spell(mindbender_shadow)
 #shadow_word_death,if=!buff.voidform.up|(cooldown.shadow_word_death.charges=2&buff.voidform.stack<15)
 if not BuffPresent(voidform_shadow) or SpellCharges(shadow_word_death) == 2 and BuffStacks(voidform_shadow) < 15 Spell(shadow_word_death)
 #mind_blast,if=variable.dots_up&((raid_event.movement.in>cast_time+0.5&raid_event.movement.in<4)|!talent.shadow_word_void.enabled|buff.voidform.down|buff.voidform.stack>14&(insanity<70|charges_fractional>1.33)|buff.voidform.stack<=14&(insanity<60|charges_fractional>1.33))
 if dots_up() and { 600 > CastTime(mind_blast) + 0.5 and 600 < 4 or not Talent(shadow_word_void_talent) or BuffExpires(voidform_shadow) or BuffStacks(voidform_shadow) > 14 and { Insanity() < 70 or Charges(mind_blast count=0) > 1.33 } or BuffStacks(voidform_shadow) <= 14 and { Insanity() < 60 or Charges(mind_blast count=0) > 1.33 } } Spell(mind_blast)
 #void_torrent,if=dot.shadow_word_pain.remains>4&dot.vampiric_touch.remains>4&buff.voidform.up
 if target.DebuffRemaining(shadow_word_pain_debuff) > 4 and target.DebuffRemaining(vampiric_touch_debuff) > 4 and BuffPresent(voidform_shadow) Spell(void_torrent)
 #shadow_word_pain,if=refreshable&target.time_to_die>4&!talent.misery.enabled&!talent.dark_void.enabled
 if target.Refreshable(shadow_word_pain_debuff) and target.TimeToDie() > 4 and not Talent(misery_talent) and not Talent(dark_void_talent) Spell(shadow_word_pain)
 #vampiric_touch,if=refreshable&target.time_to_die>6|(talent.misery.enabled&dot.shadow_word_pain.refreshable)
 if target.Refreshable(vampiric_touch_debuff) and target.TimeToDie() > 6 or Talent(misery_talent) and target.DebuffRefreshable(shadow_word_pain_debuff) Spell(vampiric_touch)
 #mind_flay,chain=1,interrupt_immediate=1,interrupt_if=ticks>=2&(cooldown.void_bolt.up|cooldown.mind_blast.up)
 Spell(mind_flay)
 #shadow_word_pain
 Spell(shadow_word_pain)
}

AddFunction ShadowSingleMainPostConditions
{
}

AddFunction ShadowSingleShortCdActions
{
 unless Spell(void_eruption)
 {
  #dark_ascension,if=buff.voidform.down
  if BuffExpires(voidform_shadow) Spell(dark_ascension)

  unless Spell(void_bolt) or Spell(focused_azerite_beam)
  {
   #purifying_blast
   Spell(purifying_blast)
   #the_unbound_force
   Spell(the_unbound_force)

   unless Spell(concentrated_flame_essence)
   {
    #ripple_in_space
    Spell(ripple_in_space_essence)
    #worldvein_resonance
    Spell(worldvein_resonance_essence)

    unless BuffPresent(harvested_thoughts_buff) and SpellCooldown(void_bolt) >= 1.5 and AzeriteTraitRank(searing_dialogue_trait) >= 1 and Spell(mind_sear) or { target.TimeToDie() < 3 or SpellCharges(shadow_word_death) == 2 or SpellCharges(shadow_word_death) == 1 and SpellCooldown(shadow_word_death) < GCD() } and Spell(shadow_word_death)
    {
     #dark_void,if=raid_event.adds.in>10
     if 600 > 10 Spell(dark_void)

     unless { Talent(mindbender_talent) or BuffStacks(voidform_shadow) > 18 or target.TimeToDie() < 15 } and Spell(mindbender_shadow) or { not BuffPresent(voidform_shadow) or SpellCharges(shadow_word_death) == 2 and BuffStacks(voidform_shadow) < 15 } and Spell(shadow_word_death)
     {
      #shadow_crash,if=raid_event.adds.in>5&raid_event.adds.duration<20
      if 600 > 5 and 10 < 20 Spell(shadow_crash)
     }
    }
   }
  }
 }
}

AddFunction ShadowSingleShortCdPostConditions
{
 Spell(void_eruption) or Spell(void_bolt) or Spell(focused_azerite_beam) or Spell(concentrated_flame_essence) or BuffPresent(harvested_thoughts_buff) and SpellCooldown(void_bolt) >= 1.5 and AzeriteTraitRank(searing_dialogue_trait) >= 1 and Spell(mind_sear) or { target.TimeToDie() < 3 or SpellCharges(shadow_word_death) == 2 or SpellCharges(shadow_word_death) == 1 and SpellCooldown(shadow_word_death) < GCD() } and Spell(shadow_word_death) or { Talent(mindbender_talent) or BuffStacks(voidform_shadow) > 18 or target.TimeToDie() < 15 } and Spell(mindbender_shadow) or { not BuffPresent(voidform_shadow) or SpellCharges(shadow_word_death) == 2 and BuffStacks(voidform_shadow) < 15 } and Spell(shadow_word_death) or dots_up() and { 600 > CastTime(mind_blast) + 0.5 and 600 < 4 or not Talent(shadow_word_void_talent) or BuffExpires(voidform_shadow) or BuffStacks(voidform_shadow) > 14 and { Insanity() < 70 or Charges(mind_blast count=0) > 1.33 } or BuffStacks(voidform_shadow) <= 14 and { Insanity() < 60 or Charges(mind_blast count=0) > 1.33 } } and Spell(mind_blast) or target.DebuffRemaining(shadow_word_pain_debuff) > 4 and target.DebuffRemaining(vampiric_touch_debuff) > 4 and BuffPresent(voidform_shadow) and Spell(void_torrent) or target.Refreshable(shadow_word_pain_debuff) and target.TimeToDie() > 4 and not Talent(misery_talent) and not Talent(dark_void_talent) and Spell(shadow_word_pain) or { target.Refreshable(vampiric_touch_debuff) and target.TimeToDie() > 6 or Talent(misery_talent) and target.DebuffRefreshable(shadow_word_pain_debuff) } and Spell(vampiric_touch) or Spell(mind_flay) or Spell(shadow_word_pain)
}

AddFunction ShadowSingleCdActions
{
 unless Spell(void_eruption) or BuffExpires(voidform_shadow) and Spell(dark_ascension) or Spell(void_bolt)
 {
  #use_item,name=azsharas_font_of_power,if=(buff.voidform.up&buff.chorus_of_insanity.stack>20)|azerite.chorus_of_insanity.rank=0
  if BuffPresent(voidform_shadow) and BuffStacks(chorus_of_insanity) > 20 or AzeriteTraitRank(chorus_of_insanity_trait) == 0 ShadowUseItemActions()
  #memory_of_lucid_dreams,if=(buff.voidform.stack>20&insanity<=50)|buff.voidform.stack>(25+5*buff.bloodlust.up)|(current_insanity_drain*gcd.max*3)>insanity
  if BuffStacks(voidform_shadow) > 20 and Insanity() <= 50 or BuffStacks(voidform_shadow) > 25 + 5 * BuffPresent(bloodlust) or CurrentInsanityDrain() * GCD() * 3 > Insanity() Spell(memory_of_lucid_dreams_essence)
  #blood_of_the_enemy
  Spell(blood_of_the_enemy)
  #guardian_of_azeroth
  Spell(guardian_of_azeroth)

  unless Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(the_unbound_force) or Spell(concentrated_flame_essence) or Spell(ripple_in_space_essence) or Spell(worldvein_resonance_essence)
  {
   #use_item,name=pocketsized_computation_device,if=equipped.167555&(buff.voidform.up&buff.chorus_of_insanity.stack>20)|azerite.chorus_of_insanity.rank=0
   if HasEquippedItem(167555) and BuffPresent(voidform_shadow) and BuffStacks(chorus_of_insanity) > 20 or AzeriteTraitRank(chorus_of_insanity_trait) == 0 ShadowUseItemActions()

   unless BuffPresent(harvested_thoughts_buff) and SpellCooldown(void_bolt) >= 1.5 and AzeriteTraitRank(searing_dialogue_trait) >= 1 and Spell(mind_sear) or { target.TimeToDie() < 3 or SpellCharges(shadow_word_death) == 2 or SpellCharges(shadow_word_death) == 1 and SpellCooldown(shadow_word_death) < GCD() } and Spell(shadow_word_death)
   {
    #surrender_to_madness,if=buff.voidform.stack>10+(10*buff.bloodlust.up)
    if BuffStacks(voidform_shadow) > 10 + 10 * BuffPresent(bloodlust) Spell(surrender_to_madness)
   }
  }
 }
}

AddFunction ShadowSingleCdPostConditions
{
 Spell(void_eruption) or BuffExpires(voidform_shadow) and Spell(dark_ascension) or Spell(void_bolt) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(the_unbound_force) or Spell(concentrated_flame_essence) or Spell(ripple_in_space_essence) or Spell(worldvein_resonance_essence) or BuffPresent(harvested_thoughts_buff) and SpellCooldown(void_bolt) >= 1.5 and AzeriteTraitRank(searing_dialogue_trait) >= 1 and Spell(mind_sear) or { target.TimeToDie() < 3 or SpellCharges(shadow_word_death) == 2 or SpellCharges(shadow_word_death) == 1 and SpellCooldown(shadow_word_death) < GCD() } and Spell(shadow_word_death) or 600 > 10 and Spell(dark_void) or { Talent(mindbender_talent) or BuffStacks(voidform_shadow) > 18 or target.TimeToDie() < 15 } and Spell(mindbender_shadow) or { not BuffPresent(voidform_shadow) or SpellCharges(shadow_word_death) == 2 and BuffStacks(voidform_shadow) < 15 } and Spell(shadow_word_death) or 600 > 5 and 10 < 20 and Spell(shadow_crash) or dots_up() and { 600 > CastTime(mind_blast) + 0.5 and 600 < 4 or not Talent(shadow_word_void_talent) or BuffExpires(voidform_shadow) or BuffStacks(voidform_shadow) > 14 and { Insanity() < 70 or Charges(mind_blast count=0) > 1.33 } or BuffStacks(voidform_shadow) <= 14 and { Insanity() < 60 or Charges(mind_blast count=0) > 1.33 } } and Spell(mind_blast) or target.DebuffRemaining(shadow_word_pain_debuff) > 4 and target.DebuffRemaining(vampiric_touch_debuff) > 4 and BuffPresent(voidform_shadow) and Spell(void_torrent) or target.Refreshable(shadow_word_pain_debuff) and target.TimeToDie() > 4 and not Talent(misery_talent) and not Talent(dark_void_talent) and Spell(shadow_word_pain) or { target.Refreshable(vampiric_touch_debuff) and target.TimeToDie() > 6 or Talent(misery_talent) and target.DebuffRefreshable(shadow_word_pain_debuff) } and Spell(vampiric_touch) or Spell(mind_flay) or Spell(shadow_word_pain)
}

### actions.precombat

AddFunction ShadowPrecombatMainActions
{
 #variable,name=mind_blast_targets,op=set,value=floor((4.5+azerite.whispers_of_the_damned.rank)%(1+0.27*azerite.searing_dialogue.rank))
 #variable,name=swp_trait_ranks_check,op=set,value=(1-0.07*azerite.death_throes.rank+0.2*azerite.thought_harvester.rank)*(1-0.09*azerite.thought_harvester.rank*azerite.searing_dialogue.rank)
 #variable,name=vt_trait_ranks_check,op=set,value=(1-0.04*azerite.thought_harvester.rank-0.05*azerite.spiteful_apparitions.rank)
 #variable,name=vt_mis_trait_ranks_check,op=set,value=(1-0.07*azerite.death_throes.rank-0.03*azerite.thought_harvester.rank-0.055*azerite.spiteful_apparitions.rank)*(1-0.027*azerite.thought_harvester.rank*azerite.searing_dialogue.rank)
 #variable,name=vt_mis_sd_check,op=set,value=1-0.014*azerite.searing_dialogue.rank
 #shadowform,if=!buff.shadowform.up
 if not BuffPresent(shadowform_buff) Spell(shadowform)
 #mind_blast,if=spell_targets.mind_sear<2|azerite.thought_harvester.rank=0
 if Enemies() < 2 or AzeriteTraitRank(thought_harvester_trait) == 0 Spell(mind_blast)
 #vampiric_touch
 Spell(vampiric_touch)
}

AddFunction ShadowPrecombatMainPostConditions
{
}

AddFunction ShadowPrecombatShortCdActions
{
}

AddFunction ShadowPrecombatShortCdPostConditions
{
 not BuffPresent(shadowform_buff) and Spell(shadowform) or { Enemies() < 2 or AzeriteTraitRank(thought_harvester_trait) == 0 } and Spell(mind_blast) or Spell(vampiric_touch)
}

AddFunction ShadowPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
}

AddFunction ShadowPrecombatCdPostConditions
{
 not BuffPresent(shadowform_buff) and Spell(shadowform) or { Enemies() < 2 or AzeriteTraitRank(thought_harvester_trait) == 0 } and Spell(mind_blast) or Spell(vampiric_touch)
}

### actions.cleave

AddFunction ShadowCleaveMainActions
{
 #void_eruption
 Spell(void_eruption)
 #vampiric_touch,if=!ticking&azerite.thought_harvester.rank>=1
 if not target.DebuffPresent(vampiric_touch_debuff) and AzeriteTraitRank(thought_harvester_trait) >= 1 Spell(vampiric_touch)
 #mind_sear,if=buff.harvested_thoughts.up
 if BuffPresent(harvested_thoughts_buff) Spell(mind_sear)
 #void_bolt
 Spell(void_bolt)
 #focused_azerite_beam
 Spell(focused_azerite_beam)
 #concentrated_flame
 Spell(concentrated_flame_essence)
 #shadow_word_death,target_if=target.time_to_die<3|buff.voidform.down
 if target.TimeToDie() < 3 or BuffExpires(voidform_shadow) Spell(shadow_word_death)
 #mindbender
 Spell(mindbender_shadow)
 #mind_blast,target_if=spell_targets.mind_sear<variable.mind_blast_targets
 if Enemies() < mind_blast_targets() Spell(mind_blast)
 #shadow_word_pain,target_if=refreshable&target.time_to_die>((-1.2+3.3*spell_targets.mind_sear)*variable.swp_trait_ranks_check*(1-0.012*azerite.searing_dialogue.rank*spell_targets.mind_sear)),if=!talent.misery.enabled
 if target.Refreshable(shadow_word_pain_debuff) and target.TimeToDie() > { -1.2 + 3.3 * Enemies() } * swp_trait_ranks_check() * { 1 - 0.012 * AzeriteTraitRank(searing_dialogue_trait) * Enemies() } and not Talent(misery_talent) Spell(shadow_word_pain)
 #vampiric_touch,target_if=refreshable,if=target.time_to_die>((1+3.3*spell_targets.mind_sear)*variable.vt_trait_ranks_check*(1+0.10*azerite.searing_dialogue.rank*spell_targets.mind_sear))
 if target.Refreshable(vampiric_touch_debuff) and target.TimeToDie() > { 1 + 3.3 * Enemies() } * vt_trait_ranks_check() * { 1 + 0.1 * AzeriteTraitRank(searing_dialogue_trait) * Enemies() } Spell(vampiric_touch)
 #vampiric_touch,target_if=dot.shadow_word_pain.refreshable,if=(talent.misery.enabled&target.time_to_die>((1.0+2.0*spell_targets.mind_sear)*variable.vt_mis_trait_ranks_check*(variable.vt_mis_sd_check*spell_targets.mind_sear)))
 if target.DebuffRefreshable(shadow_word_pain_debuff) and Talent(misery_talent) and target.TimeToDie() > { 1 + 2 * Enemies() } * vt_mis_trait_ranks_check() * vt_mis_sd_check() * Enemies() Spell(vampiric_touch)
 #void_torrent,if=buff.voidform.up
 if BuffPresent(voidform_shadow) Spell(void_torrent)
 #mind_sear,target_if=spell_targets.mind_sear>1,chain=1,interrupt_immediate=1,interrupt_if=ticks>=2
 if Enemies() > 1 Spell(mind_sear)
 #mind_flay,chain=1,interrupt_immediate=1,interrupt_if=ticks>=2&(cooldown.void_bolt.up|cooldown.mind_blast.up)
 Spell(mind_flay)
 #shadow_word_pain
 Spell(shadow_word_pain)
}

AddFunction ShadowCleaveMainPostConditions
{
}

AddFunction ShadowCleaveShortCdActions
{
 unless Spell(void_eruption)
 {
  #dark_ascension,if=buff.voidform.down
  if BuffExpires(voidform_shadow) Spell(dark_ascension)

  unless not target.DebuffPresent(vampiric_touch_debuff) and AzeriteTraitRank(thought_harvester_trait) >= 1 and Spell(vampiric_touch) or BuffPresent(harvested_thoughts_buff) and Spell(mind_sear) or Spell(void_bolt) or Spell(focused_azerite_beam)
  {
   #purifying_blast
   Spell(purifying_blast)
   #the_unbound_force
   Spell(the_unbound_force)

   unless Spell(concentrated_flame_essence)
   {
    #ripple_in_space
    Spell(ripple_in_space_essence)
    #worldvein_resonance
    Spell(worldvein_resonance_essence)

    unless { target.TimeToDie() < 3 or BuffExpires(voidform_shadow) } and Spell(shadow_word_death)
    {
     #dark_void,if=raid_event.adds.in>10&(dot.shadow_word_pain.refreshable|target.time_to_die>30)
     if 600 > 10 and { target.DebuffRefreshable(shadow_word_pain_debuff) or target.TimeToDie() > 30 } Spell(dark_void)

     unless Spell(mindbender_shadow) or Enemies() < mind_blast_targets() and Spell(mind_blast)
     {
      #shadow_crash,if=(raid_event.adds.in>5&raid_event.adds.duration<2)|raid_event.adds.duration>2
      if 600 > 5 and 10 < 2 or 10 > 2 Spell(shadow_crash)
     }
    }
   }
  }
 }
}

AddFunction ShadowCleaveShortCdPostConditions
{
 Spell(void_eruption) or not target.DebuffPresent(vampiric_touch_debuff) and AzeriteTraitRank(thought_harvester_trait) >= 1 and Spell(vampiric_touch) or BuffPresent(harvested_thoughts_buff) and Spell(mind_sear) or Spell(void_bolt) or Spell(focused_azerite_beam) or Spell(concentrated_flame_essence) or { target.TimeToDie() < 3 or BuffExpires(voidform_shadow) } and Spell(shadow_word_death) or Spell(mindbender_shadow) or Enemies() < mind_blast_targets() and Spell(mind_blast) or target.Refreshable(shadow_word_pain_debuff) and target.TimeToDie() > { -1.2 + 3.3 * Enemies() } * swp_trait_ranks_check() * { 1 - 0.012 * AzeriteTraitRank(searing_dialogue_trait) * Enemies() } and not Talent(misery_talent) and Spell(shadow_word_pain) or target.Refreshable(vampiric_touch_debuff) and target.TimeToDie() > { 1 + 3.3 * Enemies() } * vt_trait_ranks_check() * { 1 + 0.1 * AzeriteTraitRank(searing_dialogue_trait) * Enemies() } and Spell(vampiric_touch) or target.DebuffRefreshable(shadow_word_pain_debuff) and Talent(misery_talent) and target.TimeToDie() > { 1 + 2 * Enemies() } * vt_mis_trait_ranks_check() * vt_mis_sd_check() * Enemies() and Spell(vampiric_touch) or BuffPresent(voidform_shadow) and Spell(void_torrent) or Enemies() > 1 and Spell(mind_sear) or Spell(mind_flay) or Spell(shadow_word_pain)
}

AddFunction ShadowCleaveCdActions
{
 unless Spell(void_eruption) or BuffExpires(voidform_shadow) and Spell(dark_ascension) or not target.DebuffPresent(vampiric_touch_debuff) and AzeriteTraitRank(thought_harvester_trait) >= 1 and Spell(vampiric_touch) or BuffPresent(harvested_thoughts_buff) and Spell(mind_sear) or Spell(void_bolt)
 {
  #use_item,name=azsharas_font_of_power,if=(buff.voidform.up&buff.chorus_of_insanity.stack>20)|azerite.chorus_of_insanity.rank=0
  if BuffPresent(voidform_shadow) and BuffStacks(chorus_of_insanity) > 20 or AzeriteTraitRank(chorus_of_insanity_trait) == 0 ShadowUseItemActions()
  #memory_of_lucid_dreams,if=(buff.voidform.stack>20&insanity<=50)|buff.voidform.stack>(25+5*buff.bloodlust.up)|(current_insanity_drain*gcd.max*3)>insanity
  if BuffStacks(voidform_shadow) > 20 and Insanity() <= 50 or BuffStacks(voidform_shadow) > 25 + 5 * BuffPresent(bloodlust) or CurrentInsanityDrain() * GCD() * 3 > Insanity() Spell(memory_of_lucid_dreams_essence)
  #blood_of_the_enemy
  Spell(blood_of_the_enemy)
  #guardian_of_azeroth
  Spell(guardian_of_azeroth)

  unless Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(the_unbound_force) or Spell(concentrated_flame_essence) or Spell(ripple_in_space_essence) or Spell(worldvein_resonance_essence)
  {
   #use_item,name=pocketsized_computation_device,if=equipped.167555&(buff.voidform.up&buff.chorus_of_insanity.stack>20)|azerite.chorus_of_insanity.rank=0
   if HasEquippedItem(167555) and BuffPresent(voidform_shadow) and BuffStacks(chorus_of_insanity) > 20 or AzeriteTraitRank(chorus_of_insanity_trait) == 0 ShadowUseItemActions()

   unless { target.TimeToDie() < 3 or BuffExpires(voidform_shadow) } and Spell(shadow_word_death)
   {
    #surrender_to_madness,if=buff.voidform.stack>10+(10*buff.bloodlust.up)
    if BuffStacks(voidform_shadow) > 10 + 10 * BuffPresent(bloodlust) Spell(surrender_to_madness)
   }
  }
 }
}

AddFunction ShadowCleaveCdPostConditions
{
 Spell(void_eruption) or BuffExpires(voidform_shadow) and Spell(dark_ascension) or not target.DebuffPresent(vampiric_touch_debuff) and AzeriteTraitRank(thought_harvester_trait) >= 1 and Spell(vampiric_touch) or BuffPresent(harvested_thoughts_buff) and Spell(mind_sear) or Spell(void_bolt) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(the_unbound_force) or Spell(concentrated_flame_essence) or Spell(ripple_in_space_essence) or Spell(worldvein_resonance_essence) or { target.TimeToDie() < 3 or BuffExpires(voidform_shadow) } and Spell(shadow_word_death) or 600 > 10 and { target.DebuffRefreshable(shadow_word_pain_debuff) or target.TimeToDie() > 30 } and Spell(dark_void) or Spell(mindbender_shadow) or Enemies() < mind_blast_targets() and Spell(mind_blast) or { 600 > 5 and 10 < 2 or 10 > 2 } and Spell(shadow_crash) or target.Refreshable(shadow_word_pain_debuff) and target.TimeToDie() > { -1.2 + 3.3 * Enemies() } * swp_trait_ranks_check() * { 1 - 0.012 * AzeriteTraitRank(searing_dialogue_trait) * Enemies() } and not Talent(misery_talent) and Spell(shadow_word_pain) or target.Refreshable(vampiric_touch_debuff) and target.TimeToDie() > { 1 + 3.3 * Enemies() } * vt_trait_ranks_check() * { 1 + 0.1 * AzeriteTraitRank(searing_dialogue_trait) * Enemies() } and Spell(vampiric_touch) or target.DebuffRefreshable(shadow_word_pain_debuff) and Talent(misery_talent) and target.TimeToDie() > { 1 + 2 * Enemies() } * vt_mis_trait_ranks_check() * vt_mis_sd_check() * Enemies() and Spell(vampiric_touch) or BuffPresent(voidform_shadow) and Spell(void_torrent) or Enemies() > 1 and Spell(mind_sear) or Spell(mind_flay) or Spell(shadow_word_pain)
}

### actions.default

AddFunction ShadowDefaultMainActions
{
 #variable,name=dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking
 #run_action_list,name=cleave,if=active_enemies>1
 if Enemies() > 1 ShadowCleaveMainActions()

 unless Enemies() > 1 and ShadowCleaveMainPostConditions()
 {
  #run_action_list,name=single,if=active_enemies=1
  if Enemies() == 1 ShadowSingleMainActions()
 }
}

AddFunction ShadowDefaultMainPostConditions
{
 Enemies() > 1 and ShadowCleaveMainPostConditions() or Enemies() == 1 and ShadowSingleMainPostConditions()
}

AddFunction ShadowDefaultShortCdActions
{
 #variable,name=dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking
 #run_action_list,name=cleave,if=active_enemies>1
 if Enemies() > 1 ShadowCleaveShortCdActions()

 unless Enemies() > 1 and ShadowCleaveShortCdPostConditions()
 {
  #run_action_list,name=single,if=active_enemies=1
  if Enemies() == 1 ShadowSingleShortCdActions()
 }
}

AddFunction ShadowDefaultShortCdPostConditions
{
 Enemies() > 1 and ShadowCleaveShortCdPostConditions() or Enemies() == 1 and ShadowSingleShortCdPostConditions()
}

AddFunction ShadowDefaultCdActions
{
 ShadowInterruptActions()
 #use_item,slot=trinket2
 ShadowUseItemActions()
 #potion,if=buff.bloodlust.react|target.time_to_die<=80|target.health.pct<35
 if { BuffPresent(bloodlust) or target.TimeToDie() <= 80 or target.HealthPercent() < 35 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 #variable,name=dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking
 #run_action_list,name=cleave,if=active_enemies>1
 if Enemies() > 1 ShadowCleaveCdActions()

 unless Enemies() > 1 and ShadowCleaveCdPostConditions()
 {
  #run_action_list,name=single,if=active_enemies=1
  if Enemies() == 1 ShadowSingleCdActions()
 }
}

AddFunction ShadowDefaultCdPostConditions
{
 Enemies() > 1 and ShadowCleaveCdPostConditions() or Enemies() == 1 and ShadowSingleCdPostConditions()
}

### Shadow icons.

AddCheckBox(opt_priest_shadow_aoe L(AOE) default specialization=shadow)

AddIcon checkbox=!opt_priest_shadow_aoe enemies=1 help=shortcd specialization=shadow
{
 if not InCombat() ShadowPrecombatShortCdActions()
 unless not InCombat() and ShadowPrecombatShortCdPostConditions()
 {
  ShadowDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_priest_shadow_aoe help=shortcd specialization=shadow
{
 if not InCombat() ShadowPrecombatShortCdActions()
 unless not InCombat() and ShadowPrecombatShortCdPostConditions()
 {
  ShadowDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=shadow
{
 if not InCombat() ShadowPrecombatMainActions()
 unless not InCombat() and ShadowPrecombatMainPostConditions()
 {
  ShadowDefaultMainActions()
 }
}

AddIcon checkbox=opt_priest_shadow_aoe help=aoe specialization=shadow
{
 if not InCombat() ShadowPrecombatMainActions()
 unless not InCombat() and ShadowPrecombatMainPostConditions()
 {
  ShadowDefaultMainActions()
 }
}

AddIcon checkbox=!opt_priest_shadow_aoe enemies=1 help=cd specialization=shadow
{
 if not InCombat() ShadowPrecombatCdActions()
 unless not InCombat() and ShadowPrecombatCdPostConditions()
 {
  ShadowDefaultCdActions()
 }
}

AddIcon checkbox=opt_priest_shadow_aoe help=cd specialization=shadow
{
 if not InCombat() ShadowPrecombatCdActions()
 unless not InCombat() and ShadowPrecombatCdPostConditions()
 {
  ShadowDefaultCdActions()
 }
}

### Required symbols
# 167555
# blood_of_the_enemy
# bloodlust
# chorus_of_insanity
# chorus_of_insanity_trait
# concentrated_flame_essence
# dark_ascension
# dark_void
# dark_void_talent
# death_throes_trait
# focused_azerite_beam
# guardian_of_azeroth
# harvested_thoughts_buff
# item_unbridled_fury
# memory_of_lucid_dreams_essence
# mind_blast
# mind_bomb
# mind_flay
# mind_sear
# mindbender_shadow
# mindbender_talent
# misery_talent
# purifying_blast
# quaking_palm
# ripple_in_space_essence
# searing_dialogue_trait
# shadow_crash
# shadow_word_death
# shadow_word_pain
# shadow_word_pain_debuff
# shadow_word_void_talent
# shadowform
# shadowform_buff
# silence
# spiteful_apparitions_trait
# surrender_to_madness
# the_unbound_force
# thought_harvester_trait
# vampiric_touch
# vampiric_touch_debuff
# void_bolt
# void_eruption
# void_torrent
# voidform_shadow
# war_stomp
# whispers_of_the_damned_trait
# worldvein_resonance_essence
]]
    OvaleScripts:RegisterScript("PRIEST", "shadow", name, desc, code, "script")
end
