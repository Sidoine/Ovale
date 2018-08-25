local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_pr_priest_shadow"
    local desc = "[8.0] Simulationcraft: PR_Priest_Shadow"
    local code = [[
# Based on SimulationCraft profile "PR_Priest_Shadow".
#	class=priest
#	spec=shadow
#	talents=1111122

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_priest_spells)


AddFunction dots_up
{
 target.DebuffPresent(shadow_word_pain_debuff) and target.DebuffPresent(vampiric_touch_debuff)
}

AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=shadow)

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
 #shadow_word_death,if=target.time_to_die<3|cooldown.shadow_word_death.charges=2|(cooldown.shadow_word_death.charges=1&cooldown.shadow_word_death.remains<gcd.max)
 if target.TimeToDie() < 3 or SpellCharges(shadow_word_death) == 2 or SpellCharges(shadow_word_death) == 1 and SpellCooldown(shadow_word_death) < GCD() Spell(shadow_word_death)
 #mindbender
 Spell(mindbender)
 #shadow_word_death,if=!buff.voidform.up|(cooldown.shadow_word_death.charges=2&buff.voidform.stack<15)
 if not DebuffPresent(voidform_shadow) or SpellCharges(shadow_word_death) == 2 and DebuffStacks(voidform_shadow) < 15 Spell(shadow_word_death)
 #mind_blast,if=variable.dots_up
 if dots_up() Spell(mind_blast)
 #void_torrent,if=dot.shadow_word_pain.remains>4&dot.vampiric_touch.remains>4
 if target.DebuffRemaining(shadow_word_pain_debuff) > 4 and target.DebuffRemaining(vampiric_touch_debuff) > 4 Spell(void_torrent)
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
  if DebuffExpires(voidform_shadow) Spell(dark_ascension)

  unless Spell(void_bolt) or { target.TimeToDie() < 3 or SpellCharges(shadow_word_death) == 2 or SpellCharges(shadow_word_death) == 1 and SpellCooldown(shadow_word_death) < GCD() } and Spell(shadow_word_death)
  {
   #dark_void,if=raid_event.adds.in>10
   if 600 > 10 Spell(dark_void)

   unless Spell(mindbender) or { not DebuffPresent(voidform_shadow) or SpellCharges(shadow_word_death) == 2 and DebuffStacks(voidform_shadow) < 15 } and Spell(shadow_word_death)
   {
    #shadow_crash,if=raid_event.adds.in>5&raid_event.adds.duration<20
    if 600 > 5 and 10 < 20 Spell(shadow_crash)
   }
  }
 }
}

AddFunction ShadowSingleShortCdPostConditions
{
 Spell(void_eruption) or Spell(void_bolt) or { target.TimeToDie() < 3 or SpellCharges(shadow_word_death) == 2 or SpellCharges(shadow_word_death) == 1 and SpellCooldown(shadow_word_death) < GCD() } and Spell(shadow_word_death) or Spell(mindbender) or { not DebuffPresent(voidform_shadow) or SpellCharges(shadow_word_death) == 2 and DebuffStacks(voidform_shadow) < 15 } and Spell(shadow_word_death) or dots_up() and Spell(mind_blast) or target.DebuffRemaining(shadow_word_pain_debuff) > 4 and target.DebuffRemaining(vampiric_touch_debuff) > 4 and Spell(void_torrent) or target.Refreshable(shadow_word_pain_debuff) and target.TimeToDie() > 4 and not Talent(misery_talent) and not Talent(dark_void_talent) and Spell(shadow_word_pain) or { target.Refreshable(vampiric_touch_debuff) and target.TimeToDie() > 6 or Talent(misery_talent) and target.DebuffRefreshable(shadow_word_pain_debuff) } and Spell(vampiric_touch) or Spell(mind_flay) or Spell(shadow_word_pain)
}

AddFunction ShadowSingleCdActions
{
 unless Spell(void_eruption) or DebuffExpires(voidform_shadow) and Spell(dark_ascension) or Spell(void_bolt) or { target.TimeToDie() < 3 or SpellCharges(shadow_word_death) == 2 or SpellCharges(shadow_word_death) == 1 and SpellCooldown(shadow_word_death) < GCD() } and Spell(shadow_word_death)
 {
  #surrender_to_madness,if=buff.voidform.stack>=(15+buff.bloodlust.up)&target.time_to_die>200|target.time_to_die<75
  if DebuffStacks(voidform_shadow) >= 15 + BuffPresent(burst_haste_buff any=1) and target.TimeToDie() > 200 or target.TimeToDie() < 75 Spell(surrender_to_madness)
 }
}

AddFunction ShadowSingleCdPostConditions
{
 Spell(void_eruption) or DebuffExpires(voidform_shadow) and Spell(dark_ascension) or Spell(void_bolt) or { target.TimeToDie() < 3 or SpellCharges(shadow_word_death) == 2 or SpellCharges(shadow_word_death) == 1 and SpellCooldown(shadow_word_death) < GCD() } and Spell(shadow_word_death) or 600 > 10 and Spell(dark_void) or Spell(mindbender) or { not DebuffPresent(voidform_shadow) or SpellCharges(shadow_word_death) == 2 and DebuffStacks(voidform_shadow) < 15 } and Spell(shadow_word_death) or 600 > 5 and 10 < 20 and Spell(shadow_crash) or dots_up() and Spell(mind_blast) or target.DebuffRemaining(shadow_word_pain_debuff) > 4 and target.DebuffRemaining(vampiric_touch_debuff) > 4 and Spell(void_torrent) or target.Refreshable(shadow_word_pain_debuff) and target.TimeToDie() > 4 and not Talent(misery_talent) and not Talent(dark_void_talent) and Spell(shadow_word_pain) or { target.Refreshable(vampiric_touch_debuff) and target.TimeToDie() > 6 or Talent(misery_talent) and target.DebuffRefreshable(shadow_word_pain_debuff) } and Spell(vampiric_touch) or Spell(mind_flay) or Spell(shadow_word_pain)
}

### actions.precombat

AddFunction ShadowPrecombatMainActions
{
 #shadowform,if=!buff.shadowform.up
 if not BuffPresent(shadowform_buff) Spell(shadowform)
 #mind_blast
 Spell(mind_blast)
 #shadow_word_void
 Spell(shadow_word_void)
}

AddFunction ShadowPrecombatMainPostConditions
{
}

AddFunction ShadowPrecombatShortCdActions
{
}

AddFunction ShadowPrecombatShortCdPostConditions
{
 not BuffPresent(shadowform_buff) and Spell(shadowform) or Spell(mind_blast) or Spell(shadow_word_void)
}

AddFunction ShadowPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(rising_death usable=1)
}

AddFunction ShadowPrecombatCdPostConditions
{
 not BuffPresent(shadowform_buff) and Spell(shadowform) or Spell(mind_blast) or Spell(shadow_word_void)
}

### actions.cleave

AddFunction ShadowCleaveMainActions
{
 #void_eruption
 Spell(void_eruption)
 #void_bolt
 Spell(void_bolt)
 #shadow_word_death,target_if=target.time_to_die<3|buff.voidform.down
 if target.TimeToDie() < 3 or DebuffExpires(voidform_shadow) Spell(shadow_word_death)
 #mindbender
 Spell(mindbender)
 #mind_blast
 Spell(mind_blast)
 #shadow_word_pain,target_if=refreshable&target.time_to_die>4,if=!talent.misery.enabled&!talent.dark_void.enabled
 if target.Refreshable(shadow_word_pain_debuff) and target.TimeToDie() > 4 and not Talent(misery_talent) and not Talent(dark_void_talent) Spell(shadow_word_pain)
 #vampiric_touch,target_if=refreshable,if=(target.time_to_die>6)
 if target.Refreshable(vampiric_touch_debuff) and target.TimeToDie() > 6 Spell(vampiric_touch)
 #vampiric_touch,target_if=dot.shadow_word_pain.refreshable,if=(talent.misery.enabled&target.time_to_die>4)
 if target.DebuffRefreshable(shadow_word_pain_debuff) and Talent(misery_talent) and target.TimeToDie() > 4 Spell(vampiric_touch)
 #void_torrent
 Spell(void_torrent)
 #mind_sear,target_if=spell_targets.mind_sear>2,chain=1,interrupt=1
 if Enemies() > 2 Spell(mind_sear)
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
  if DebuffExpires(voidform_shadow) Spell(dark_ascension)

  unless Spell(void_bolt) or { target.TimeToDie() < 3 or DebuffExpires(voidform_shadow) } and Spell(shadow_word_death)
  {
   #dark_void,if=raid_event.adds.in>10
   if 600 > 10 Spell(dark_void)

   unless Spell(mindbender) or Spell(mind_blast)
   {
    #shadow_crash,if=(raid_event.adds.in>5&raid_event.adds.duration<2)|raid_event.adds.duration>2
    if 600 > 5 and 10 < 2 or 10 > 2 Spell(shadow_crash)
   }
  }
 }
}

AddFunction ShadowCleaveShortCdPostConditions
{
 Spell(void_eruption) or Spell(void_bolt) or { target.TimeToDie() < 3 or DebuffExpires(voidform_shadow) } and Spell(shadow_word_death) or Spell(mindbender) or Spell(mind_blast) or target.Refreshable(shadow_word_pain_debuff) and target.TimeToDie() > 4 and not Talent(misery_talent) and not Talent(dark_void_talent) and Spell(shadow_word_pain) or target.Refreshable(vampiric_touch_debuff) and target.TimeToDie() > 6 and Spell(vampiric_touch) or target.DebuffRefreshable(shadow_word_pain_debuff) and Talent(misery_talent) and target.TimeToDie() > 4 and Spell(vampiric_touch) or Spell(void_torrent) or Enemies() > 2 and Spell(mind_sear) or Spell(mind_flay) or Spell(shadow_word_pain)
}

AddFunction ShadowCleaveCdActions
{
 unless Spell(void_eruption) or DebuffExpires(voidform_shadow) and Spell(dark_ascension) or Spell(void_bolt) or { target.TimeToDie() < 3 or DebuffExpires(voidform_shadow) } and Spell(shadow_word_death)
 {
  #surrender_to_madness,if=buff.voidform.stack>=(15+buff.bloodlust.up)
  if DebuffStacks(voidform_shadow) >= 15 + BuffPresent(burst_haste_buff any=1) Spell(surrender_to_madness)
 }
}

AddFunction ShadowCleaveCdPostConditions
{
 Spell(void_eruption) or DebuffExpires(voidform_shadow) and Spell(dark_ascension) or Spell(void_bolt) or { target.TimeToDie() < 3 or DebuffExpires(voidform_shadow) } and Spell(shadow_word_death) or 600 > 10 and Spell(dark_void) or Spell(mindbender) or Spell(mind_blast) or { 600 > 5 and 10 < 2 or 10 > 2 } and Spell(shadow_crash) or target.Refreshable(shadow_word_pain_debuff) and target.TimeToDie() > 4 and not Talent(misery_talent) and not Talent(dark_void_talent) and Spell(shadow_word_pain) or target.Refreshable(vampiric_touch_debuff) and target.TimeToDie() > 6 and Spell(vampiric_touch) or target.DebuffRefreshable(shadow_word_pain_debuff) and Talent(misery_talent) and target.TimeToDie() > 4 and Spell(vampiric_touch) or Spell(void_torrent) or Enemies() > 2 and Spell(mind_sear) or Spell(mind_flay) or Spell(shadow_word_pain)
}

### actions.aoe

AddFunction ShadowAoeMainActions
{
 #void_eruption
 Spell(void_eruption)
 #void_bolt,if=talent.dark_void.enabled&dot.shadow_word_pain.remains>travel_time
 if Talent(dark_void_talent) and target.DebuffRemaining(shadow_word_pain_debuff) > TravelTime(void_bolt) Spell(void_bolt)
 #mindbender
 Spell(mindbender)
 #mind_sear,chain=1,interrupt_immediate=1,interrupt_if=ticks>=2&(cooldown.void_bolt.up|cooldown.mind_blast.up)
 Spell(mind_sear)
 #shadow_word_pain
 Spell(shadow_word_pain)
}

AddFunction ShadowAoeMainPostConditions
{
}

AddFunction ShadowAoeShortCdActions
{
 unless Spell(void_eruption)
 {
  #dark_ascension,if=buff.voidform.down
  if DebuffExpires(voidform_shadow) Spell(dark_ascension)

  unless Talent(dark_void_talent) and target.DebuffRemaining(shadow_word_pain_debuff) > TravelTime(void_bolt) and Spell(void_bolt)
  {
   #dark_void,if=raid_event.adds.in>10
   if 600 > 10 Spell(dark_void)

   unless Spell(mindbender)
   {
    #shadow_crash,if=raid_event.adds.in>5&raid_event.adds.duration<20
    if 600 > 5 and 10 < 20 Spell(shadow_crash)
   }
  }
 }
}

AddFunction ShadowAoeShortCdPostConditions
{
 Spell(void_eruption) or Talent(dark_void_talent) and target.DebuffRemaining(shadow_word_pain_debuff) > TravelTime(void_bolt) and Spell(void_bolt) or Spell(mindbender) or Spell(mind_sear) or Spell(shadow_word_pain)
}

AddFunction ShadowAoeCdActions
{
 unless Spell(void_eruption) or DebuffExpires(voidform_shadow) and Spell(dark_ascension) or Talent(dark_void_talent) and target.DebuffRemaining(shadow_word_pain_debuff) > TravelTime(void_bolt) and Spell(void_bolt)
 {
  #surrender_to_madness,if=buff.voidform.stack>=(15+buff.bloodlust.up)
  if DebuffStacks(voidform_shadow) >= 15 + BuffPresent(burst_haste_buff any=1) Spell(surrender_to_madness)
 }
}

AddFunction ShadowAoeCdPostConditions
{
 Spell(void_eruption) or DebuffExpires(voidform_shadow) and Spell(dark_ascension) or Talent(dark_void_talent) and target.DebuffRemaining(shadow_word_pain_debuff) > TravelTime(void_bolt) and Spell(void_bolt) or 600 > 10 and Spell(dark_void) or Spell(mindbender) or 600 > 5 and 10 < 20 and Spell(shadow_crash) or Spell(mind_sear) or Spell(shadow_word_pain)
}

### actions.default

AddFunction ShadowDefaultMainActions
{
 #run_action_list,name=aoe,if=spell_targets.mind_sear>(5+1*talent.misery.enabled)
 if Enemies() > 5 + 1 * TalentPoints(misery_talent) ShadowAoeMainActions()

 unless Enemies() > 5 + 1 * TalentPoints(misery_talent) and ShadowAoeMainPostConditions()
 {
  #run_action_list,name=cleave,if=active_enemies>1
  if Enemies() > 1 ShadowCleaveMainActions()

  unless Enemies() > 1 and ShadowCleaveMainPostConditions()
  {
   #run_action_list,name=single,if=active_enemies=1
   if Enemies() == 1 ShadowSingleMainActions()
  }
 }
}

AddFunction ShadowDefaultMainPostConditions
{
 Enemies() > 5 + 1 * TalentPoints(misery_talent) and ShadowAoeMainPostConditions() or Enemies() > 1 and ShadowCleaveMainPostConditions() or Enemies() == 1 and ShadowSingleMainPostConditions()
}

AddFunction ShadowDefaultShortCdActions
{
 #run_action_list,name=aoe,if=spell_targets.mind_sear>(5+1*talent.misery.enabled)
 if Enemies() > 5 + 1 * TalentPoints(misery_talent) ShadowAoeShortCdActions()

 unless Enemies() > 5 + 1 * TalentPoints(misery_talent) and ShadowAoeShortCdPostConditions()
 {
  #run_action_list,name=cleave,if=active_enemies>1
  if Enemies() > 1 ShadowCleaveShortCdActions()

  unless Enemies() > 1 and ShadowCleaveShortCdPostConditions()
  {
   #run_action_list,name=single,if=active_enemies=1
   if Enemies() == 1 ShadowSingleShortCdActions()
  }
 }
}

AddFunction ShadowDefaultShortCdPostConditions
{
 Enemies() > 5 + 1 * TalentPoints(misery_talent) and ShadowAoeShortCdPostConditions() or Enemies() > 1 and ShadowCleaveShortCdPostConditions() or Enemies() == 1 and ShadowSingleShortCdPostConditions()
}

AddFunction ShadowDefaultCdActions
{
 #use_item,slot=trinket2
 ShadowUseItemActions()
 #potion,if=buff.bloodlust.react|target.time_to_die<=80|target.health.pct<35
 if { BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 80 or target.HealthPercent() < 35 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(rising_death usable=1)
 #variable,name=dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking
 #berserking
 Spell(berserking)
 #run_action_list,name=aoe,if=spell_targets.mind_sear>(5+1*talent.misery.enabled)
 if Enemies() > 5 + 1 * TalentPoints(misery_talent) ShadowAoeCdActions()

 unless Enemies() > 5 + 1 * TalentPoints(misery_talent) and ShadowAoeCdPostConditions()
 {
  #run_action_list,name=cleave,if=active_enemies>1
  if Enemies() > 1 ShadowCleaveCdActions()

  unless Enemies() > 1 and ShadowCleaveCdPostConditions()
  {
   #run_action_list,name=single,if=active_enemies=1
   if Enemies() == 1 ShadowSingleCdActions()
  }
 }
}

AddFunction ShadowDefaultCdPostConditions
{
 Enemies() > 5 + 1 * TalentPoints(misery_talent) and ShadowAoeCdPostConditions() or Enemies() > 1 and ShadowCleaveCdPostConditions() or Enemies() == 1 and ShadowSingleCdPostConditions()
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
# berserking
# dark_ascension
# dark_void
# dark_void_talent
# mind_blast
# mind_flay
# mind_sear
# mindbender
# misery_talent
# rising_death
# shadow_crash
# shadow_word_death
# shadow_word_pain
# shadow_word_pain_debuff
# shadow_word_void
# shadowform
# shadowform_buff
# surrender_to_madness
# vampiric_touch
# vampiric_touch_debuff
# void_bolt
# void_eruption
# void_torrent
# voidform_shadow
]]
    OvaleScripts:RegisterScript("PRIEST", "shadow", name, desc, code, "script")
end
