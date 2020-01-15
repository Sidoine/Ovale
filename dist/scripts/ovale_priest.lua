local __exports = LibStub:NewLibrary("ovale/scripts/ovale_priest", 80201)
if not __exports then return end
__exports.registerPriest = function(OvaleScripts)
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
 1 - 0.014 * azeritetraitrank(searing_dialogue_trait)
}

AddFunction vt_mis_trait_ranks_check
{
 { 1 - 0.07 * azeritetraitrank(death_throes_trait) - 0.03 * azeritetraitrank(thought_harvester_trait) - 0.055 * azeritetraitrank(spiteful_apparitions_trait) } * { 1 - 0.027 * azeritetraitrank(thought_harvester_trait) * azeritetraitrank(searing_dialogue_trait) }
}

AddFunction vt_trait_ranks_check
{
 1 - 0.04 * azeritetraitrank(thought_harvester_trait) - 0.05 * azeritetraitrank(spiteful_apparitions_trait)
}

AddFunction swp_trait_ranks_check
{
 { 1 - 0.07 * azeritetraitrank(death_throes_trait) + 0.2 * azeritetraitrank(thought_harvester_trait) } * { 1 - 0.09 * azeritetraitrank(thought_harvester_trait) * azeritetraitrank(searing_dialogue_trait) }
}

AddFunction mind_blast_targets
{
 { 4.5 + azeritetraitrank(whispers_of_the_damned_trait) } / { 1 + 0.27 * azeritetraitrank(searing_dialogue_trait) }
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=shadow)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=shadow)

AddFunction ShadowInterruptActions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(silence) and target.isinterruptible() spell(silence)
  if target.inrange(mind_bomb) and not target.classification(worldboss) and target.remainingcasttime() > 2 spell(mind_bomb)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
 }
}

AddFunction ShadowUseItemActions
{
 item(Trinket0Slot text=13 usable=1)
 item(Trinket1Slot text=14 usable=1)
}

### actions.single

AddFunction ShadowSingleMainActions
{
 #void_eruption
 spell(void_eruption)
 #void_bolt
 spell(void_bolt)
 #call_action_list,name=cds
 ShadowCdsMainActions()

 unless ShadowCdsMainPostConditions()
 {
  #mind_sear,if=buff.harvested_thoughts.up&cooldown.void_bolt.remains>=1.5&azerite.searing_dialogue.rank>=1
  if buffpresent(harvested_thoughts_buff) and spellcooldown(void_bolt) >= 1.5 and azeritetraitrank(searing_dialogue_trait) >= 1 spell(mind_sear)
  #shadow_word_death,if=target.time_to_die<3|cooldown.shadow_word_death.charges=2|(cooldown.shadow_word_death.charges=1&cooldown.shadow_word_death.remains<gcd.max)
  if target.timetodie() < 3 or spellcharges(shadow_word_death) == 2 or spellcharges(shadow_word_death) == 1 and spellcooldown(shadow_word_death) < gcd() spell(shadow_word_death)
  #mindbender,if=talent.mindbender.enabled|(buff.voidform.stack>18|target.time_to_die<15)
  if hastalent(mindbender_talent) or buffstacks(voidform_shadow) > 18 or target.timetodie() < 15 spell(mindbender_shadow)
  #shadow_word_death,if=!buff.voidform.up|(cooldown.shadow_word_death.charges=2&buff.voidform.stack<15)
  if not buffpresent(voidform_shadow) or spellcharges(shadow_word_death) == 2 and buffstacks(voidform_shadow) < 15 spell(shadow_word_death)
  #mind_blast,if=variable.dots_up&((raid_event.movement.in>cast_time+0.5&raid_event.movement.in<4)|!talent.shadow_word_void.enabled|buff.voidform.down|buff.voidform.stack>14&(insanity<70|charges_fractional>1.33)|buff.voidform.stack<=14&(insanity<60|charges_fractional>1.33))
  if undefined() and { 600 > casttime(mind_blast) + 0.5 and 600 < 4 or not hastalent(shadow_word_void_talent) or buffexpires(voidform_shadow) or buffstacks(voidform_shadow) > 14 and { insanity() < 70 or charges(mind_blast count=0) > 1.33 } or buffstacks(voidform_shadow) <= 14 and { insanity() < 60 or charges(mind_blast count=0) > 1.33 } } spell(mind_blast)
  #void_torrent,if=dot.shadow_word_pain.remains>4&dot.vampiric_touch.remains>4&buff.voidform.up
  if target.DebuffRemaining(shadow_word_pain_debuff) > 4 and target.DebuffRemaining(vampiric_touch_debuff) > 4 and buffpresent(voidform_shadow) spell(void_torrent)
  #shadow_word_pain,if=refreshable&target.time_to_die>4&!talent.misery.enabled&!talent.dark_void.enabled
  if target.refreshable(shadow_word_pain_debuff) and target.timetodie() > 4 and not hastalent(misery_talent) and not hastalent(dark_void_talent) spell(shadow_word_pain)
  #vampiric_touch,if=refreshable&target.time_to_die>6|(talent.misery.enabled&dot.shadow_word_pain.refreshable)
  if target.refreshable(vampiric_touch_debuff) and target.timetodie() > 6 or hastalent(misery_talent) and target.DebuffRefreshable(shadow_word_pain_debuff) spell(vampiric_touch)
  #mind_flay,chain=1,interrupt_immediate=1,interrupt_if=ticks>=2&(cooldown.void_bolt.up|cooldown.mind_blast.up)
  spell(mind_flay)
  #shadow_word_pain
  spell(shadow_word_pain)
 }
}

AddFunction ShadowSingleMainPostConditions
{
 ShadowCdsMainPostConditions()
}

AddFunction ShadowSingleShortCdActions
{
 unless spell(void_eruption)
 {
  #dark_ascension,if=buff.voidform.down
  if buffexpires(voidform_shadow) spell(dark_ascension)

  unless spell(void_bolt)
  {
   #call_action_list,name=cds
   ShadowCdsShortCdActions()

   unless ShadowCdsShortCdPostConditions() or buffpresent(harvested_thoughts_buff) and spellcooldown(void_bolt) >= 1.5 and azeritetraitrank(searing_dialogue_trait) >= 1 and spell(mind_sear) or { target.timetodie() < 3 or spellcharges(shadow_word_death) == 2 or spellcharges(shadow_word_death) == 1 and spellcooldown(shadow_word_death) < gcd() } and spell(shadow_word_death)
   {
    #dark_void,if=raid_event.adds.in>10
    if 600 > 10 spell(dark_void)

    unless { hastalent(mindbender_talent) or buffstacks(voidform_shadow) > 18 or target.timetodie() < 15 } and spell(mindbender_shadow) or { not buffpresent(voidform_shadow) or spellcharges(shadow_word_death) == 2 and buffstacks(voidform_shadow) < 15 } and spell(shadow_word_death)
    {
     #shadow_crash,if=raid_event.adds.in>5&raid_event.adds.duration<20
     if 600 > 5 and 10 < 20 spell(shadow_crash)
    }
   }
  }
 }
}

AddFunction ShadowSingleShortCdPostConditions
{
 spell(void_eruption) or spell(void_bolt) or ShadowCdsShortCdPostConditions() or buffpresent(harvested_thoughts_buff) and spellcooldown(void_bolt) >= 1.5 and azeritetraitrank(searing_dialogue_trait) >= 1 and spell(mind_sear) or { target.timetodie() < 3 or spellcharges(shadow_word_death) == 2 or spellcharges(shadow_word_death) == 1 and spellcooldown(shadow_word_death) < gcd() } and spell(shadow_word_death) or { hastalent(mindbender_talent) or buffstacks(voidform_shadow) > 18 or target.timetodie() < 15 } and spell(mindbender_shadow) or { not buffpresent(voidform_shadow) or spellcharges(shadow_word_death) == 2 and buffstacks(voidform_shadow) < 15 } and spell(shadow_word_death) or undefined() and { 600 > casttime(mind_blast) + 0.5 and 600 < 4 or not hastalent(shadow_word_void_talent) or buffexpires(voidform_shadow) or buffstacks(voidform_shadow) > 14 and { insanity() < 70 or charges(mind_blast count=0) > 1.33 } or buffstacks(voidform_shadow) <= 14 and { insanity() < 60 or charges(mind_blast count=0) > 1.33 } } and spell(mind_blast) or target.DebuffRemaining(shadow_word_pain_debuff) > 4 and target.DebuffRemaining(vampiric_touch_debuff) > 4 and buffpresent(voidform_shadow) and spell(void_torrent) or target.refreshable(shadow_word_pain_debuff) and target.timetodie() > 4 and not hastalent(misery_talent) and not hastalent(dark_void_talent) and spell(shadow_word_pain) or { target.refreshable(vampiric_touch_debuff) and target.timetodie() > 6 or hastalent(misery_talent) and target.DebuffRefreshable(shadow_word_pain_debuff) } and spell(vampiric_touch) or spell(mind_flay) or spell(shadow_word_pain)
}

AddFunction ShadowSingleCdActions
{
 unless spell(void_eruption) or buffexpires(voidform_shadow) and spell(dark_ascension) or spell(void_bolt)
 {
  #call_action_list,name=cds
  ShadowCdsCdActions()

  unless ShadowCdsCdPostConditions() or buffpresent(harvested_thoughts_buff) and spellcooldown(void_bolt) >= 1.5 and azeritetraitrank(searing_dialogue_trait) >= 1 and spell(mind_sear) or { target.timetodie() < 3 or spellcharges(shadow_word_death) == 2 or spellcharges(shadow_word_death) == 1 and spellcooldown(shadow_word_death) < gcd() } and spell(shadow_word_death)
  {
   #surrender_to_madness,if=buff.voidform.stack>10+(10*buff.bloodlust.up)
   if buffstacks(voidform_shadow) > 10 + 10 * buffpresent(bloodlust) spell(surrender_to_madness)
  }
 }
}

AddFunction ShadowSingleCdPostConditions
{
 spell(void_eruption) or buffexpires(voidform_shadow) and spell(dark_ascension) or spell(void_bolt) or ShadowCdsCdPostConditions() or buffpresent(harvested_thoughts_buff) and spellcooldown(void_bolt) >= 1.5 and azeritetraitrank(searing_dialogue_trait) >= 1 and spell(mind_sear) or { target.timetodie() < 3 or spellcharges(shadow_word_death) == 2 or spellcharges(shadow_word_death) == 1 and spellcooldown(shadow_word_death) < gcd() } and spell(shadow_word_death) or 600 > 10 and spell(dark_void) or { hastalent(mindbender_talent) or buffstacks(voidform_shadow) > 18 or target.timetodie() < 15 } and spell(mindbender_shadow) or { not buffpresent(voidform_shadow) or spellcharges(shadow_word_death) == 2 and buffstacks(voidform_shadow) < 15 } and spell(shadow_word_death) or 600 > 5 and 10 < 20 and spell(shadow_crash) or undefined() and { 600 > casttime(mind_blast) + 0.5 and 600 < 4 or not hastalent(shadow_word_void_talent) or buffexpires(voidform_shadow) or buffstacks(voidform_shadow) > 14 and { insanity() < 70 or charges(mind_blast count=0) > 1.33 } or buffstacks(voidform_shadow) <= 14 and { insanity() < 60 or charges(mind_blast count=0) > 1.33 } } and spell(mind_blast) or target.DebuffRemaining(shadow_word_pain_debuff) > 4 and target.DebuffRemaining(vampiric_touch_debuff) > 4 and buffpresent(voidform_shadow) and spell(void_torrent) or target.refreshable(shadow_word_pain_debuff) and target.timetodie() > 4 and not hastalent(misery_talent) and not hastalent(dark_void_talent) and spell(shadow_word_pain) or { target.refreshable(vampiric_touch_debuff) and target.timetodie() > 6 or hastalent(misery_talent) and target.DebuffRefreshable(shadow_word_pain_debuff) } and spell(vampiric_touch) or spell(mind_flay) or spell(shadow_word_pain)
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
 if not buffpresent(shadowform_buff) spell(shadowform)
 #mind_blast,if=spell_targets.mind_sear<2|azerite.thought_harvester.rank=0
 if enemies() < 2 or azeritetraitrank(thought_harvester_trait) == 0 spell(mind_blast)
 #vampiric_touch
 spell(vampiric_touch)
}

AddFunction ShadowPrecombatMainPostConditions
{
}

AddFunction ShadowPrecombatShortCdActions
{
}

AddFunction ShadowPrecombatShortCdPostConditions
{
 not buffpresent(shadowform_buff) and spell(shadowform) or { enemies() < 2 or azeritetraitrank(thought_harvester_trait) == 0 } and spell(mind_blast) or spell(vampiric_touch)
}

AddFunction ShadowPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

 unless not buffpresent(shadowform_buff) and spell(shadowform)
 {
  #use_item,name=azsharas_font_of_power
  shadowuseitemactions()
 }
}

AddFunction ShadowPrecombatCdPostConditions
{
 not buffpresent(shadowform_buff) and spell(shadowform) or { enemies() < 2 or azeritetraitrank(thought_harvester_trait) == 0 } and spell(mind_blast) or spell(vampiric_touch)
}

### actions.crit_cds

AddFunction ShadowCritcdsMainActions
{
}

AddFunction ShadowCritcdsMainPostConditions
{
}

AddFunction ShadowCritcdsShortCdActions
{
}

AddFunction ShadowCritcdsShortCdPostConditions
{
}

AddFunction ShadowCritcdsCdActions
{
 #use_item,name=azsharas_font_of_power
 shadowuseitemactions()
 #use_item,effect_name=cyclotronic_blast
 shadowuseitemactions()
}

AddFunction ShadowCritcdsCdPostConditions
{
}

### actions.cleave

AddFunction ShadowCleaveMainActions
{
 #void_eruption
 spell(void_eruption)
 #vampiric_touch,if=!ticking&azerite.thought_harvester.rank>=1
 if not target.DebuffPresent(vampiric_touch_debuff) and azeritetraitrank(thought_harvester_trait) >= 1 spell(vampiric_touch)
 #mind_sear,if=buff.harvested_thoughts.up
 if buffpresent(harvested_thoughts_buff) spell(mind_sear)
 #void_bolt
 spell(void_bolt)
 #call_action_list,name=cds
 ShadowCdsMainActions()

 unless ShadowCdsMainPostConditions()
 {
  #shadow_word_death,target_if=target.time_to_die<3|buff.voidform.down
  if target.timetodie() < 3 or buffexpires(voidform_shadow) spell(shadow_word_death)
  #mindbender
  spell(mindbender_shadow)
  #mind_blast,target_if=spell_targets.mind_sear<variable.mind_blast_targets
  if enemies() < undefined() spell(mind_blast)
  #shadow_word_pain,target_if=refreshable&target.time_to_die>((-1.2+3.3*spell_targets.mind_sear)*variable.swp_trait_ranks_check*(1-0.012*azerite.searing_dialogue.rank*spell_targets.mind_sear)),if=!talent.misery.enabled
  if target.refreshable(shadow_word_pain_debuff) and target.timetodie() > { -1.2 + 3.3 * enemies() } * undefined() * { 1 - 0.012 * azeritetraitrank(searing_dialogue_trait) * enemies() } and not hastalent(misery_talent) spell(shadow_word_pain)
  #vampiric_touch,target_if=refreshable,if=target.time_to_die>((1+3.3*spell_targets.mind_sear)*variable.vt_trait_ranks_check*(1+0.10*azerite.searing_dialogue.rank*spell_targets.mind_sear))
  if target.refreshable(vampiric_touch_debuff) and target.timetodie() > { 1 + 3.3 * enemies() } * undefined() * { 1 + 0.1 * azeritetraitrank(searing_dialogue_trait) * enemies() } spell(vampiric_touch)
  #vampiric_touch,target_if=dot.shadow_word_pain.refreshable,if=(talent.misery.enabled&target.time_to_die>((1.0+2.0*spell_targets.mind_sear)*variable.vt_mis_trait_ranks_check*(variable.vt_mis_sd_check*spell_targets.mind_sear)))
  if target.DebuffRefreshable(shadow_word_pain_debuff) and hastalent(misery_talent) and target.timetodie() > { 1 + 2 * enemies() } * undefined() * undefined() * enemies() spell(vampiric_touch)
  #void_torrent,if=buff.voidform.up
  if buffpresent(voidform_shadow) spell(void_torrent)
  #mind_sear,target_if=spell_targets.mind_sear>1,chain=1,interrupt_immediate=1,interrupt_if=ticks>=2
  if enemies() > 1 spell(mind_sear)
  #mind_flay,chain=1,interrupt_immediate=1,interrupt_if=ticks>=2&(cooldown.void_bolt.up|cooldown.mind_blast.up)
  spell(mind_flay)
  #shadow_word_pain
  spell(shadow_word_pain)
 }
}

AddFunction ShadowCleaveMainPostConditions
{
 ShadowCdsMainPostConditions()
}

AddFunction ShadowCleaveShortCdActions
{
 unless spell(void_eruption)
 {
  #dark_ascension,if=buff.voidform.down
  if buffexpires(voidform_shadow) spell(dark_ascension)

  unless not target.DebuffPresent(vampiric_touch_debuff) and azeritetraitrank(thought_harvester_trait) >= 1 and spell(vampiric_touch) or buffpresent(harvested_thoughts_buff) and spell(mind_sear) or spell(void_bolt)
  {
   #call_action_list,name=cds
   ShadowCdsShortCdActions()

   unless ShadowCdsShortCdPostConditions() or { target.timetodie() < 3 or buffexpires(voidform_shadow) } and spell(shadow_word_death)
   {
    #dark_void,if=raid_event.adds.in>10&(dot.shadow_word_pain.refreshable|target.time_to_die>30)
    if 600 > 10 and { target.DebuffRefreshable(shadow_word_pain_debuff) or target.timetodie() > 30 } spell(dark_void)

    unless spell(mindbender_shadow) or enemies() < undefined() and spell(mind_blast)
    {
     #shadow_crash,if=(raid_event.adds.in>5&raid_event.adds.duration<2)|raid_event.adds.duration>2
     if 600 > 5 and 10 < 2 or 10 > 2 spell(shadow_crash)
    }
   }
  }
 }
}

AddFunction ShadowCleaveShortCdPostConditions
{
 spell(void_eruption) or not target.DebuffPresent(vampiric_touch_debuff) and azeritetraitrank(thought_harvester_trait) >= 1 and spell(vampiric_touch) or buffpresent(harvested_thoughts_buff) and spell(mind_sear) or spell(void_bolt) or ShadowCdsShortCdPostConditions() or { target.timetodie() < 3 or buffexpires(voidform_shadow) } and spell(shadow_word_death) or spell(mindbender_shadow) or enemies() < undefined() and spell(mind_blast) or target.refreshable(shadow_word_pain_debuff) and target.timetodie() > { -1.2 + 3.3 * enemies() } * undefined() * { 1 - 0.012 * azeritetraitrank(searing_dialogue_trait) * enemies() } and not hastalent(misery_talent) and spell(shadow_word_pain) or target.refreshable(vampiric_touch_debuff) and target.timetodie() > { 1 + 3.3 * enemies() } * undefined() * { 1 + 0.1 * azeritetraitrank(searing_dialogue_trait) * enemies() } and spell(vampiric_touch) or target.DebuffRefreshable(shadow_word_pain_debuff) and hastalent(misery_talent) and target.timetodie() > { 1 + 2 * enemies() } * undefined() * undefined() * enemies() and spell(vampiric_touch) or buffpresent(voidform_shadow) and spell(void_torrent) or enemies() > 1 and spell(mind_sear) or spell(mind_flay) or spell(shadow_word_pain)
}

AddFunction ShadowCleaveCdActions
{
 unless spell(void_eruption) or buffexpires(voidform_shadow) and spell(dark_ascension) or not target.DebuffPresent(vampiric_touch_debuff) and azeritetraitrank(thought_harvester_trait) >= 1 and spell(vampiric_touch) or buffpresent(harvested_thoughts_buff) and spell(mind_sear) or spell(void_bolt)
 {
  #call_action_list,name=cds
  ShadowCdsCdActions()

  unless ShadowCdsCdPostConditions() or { target.timetodie() < 3 or buffexpires(voidform_shadow) } and spell(shadow_word_death)
  {
   #surrender_to_madness,if=buff.voidform.stack>10+(10*buff.bloodlust.up)
   if buffstacks(voidform_shadow) > 10 + 10 * buffpresent(bloodlust) spell(surrender_to_madness)
  }
 }
}

AddFunction ShadowCleaveCdPostConditions
{
 spell(void_eruption) or buffexpires(voidform_shadow) and spell(dark_ascension) or not target.DebuffPresent(vampiric_touch_debuff) and azeritetraitrank(thought_harvester_trait) >= 1 and spell(vampiric_touch) or buffpresent(harvested_thoughts_buff) and spell(mind_sear) or spell(void_bolt) or ShadowCdsCdPostConditions() or { target.timetodie() < 3 or buffexpires(voidform_shadow) } and spell(shadow_word_death) or 600 > 10 and { target.DebuffRefreshable(shadow_word_pain_debuff) or target.timetodie() > 30 } and spell(dark_void) or spell(mindbender_shadow) or enemies() < undefined() and spell(mind_blast) or { 600 > 5 and 10 < 2 or 10 > 2 } and spell(shadow_crash) or target.refreshable(shadow_word_pain_debuff) and target.timetodie() > { -1.2 + 3.3 * enemies() } * undefined() * { 1 - 0.012 * azeritetraitrank(searing_dialogue_trait) * enemies() } and not hastalent(misery_talent) and spell(shadow_word_pain) or target.refreshable(vampiric_touch_debuff) and target.timetodie() > { 1 + 3.3 * enemies() } * undefined() * { 1 + 0.1 * azeritetraitrank(searing_dialogue_trait) * enemies() } and spell(vampiric_touch) or target.DebuffRefreshable(shadow_word_pain_debuff) and hastalent(misery_talent) and target.timetodie() > { 1 + 2 * enemies() } * undefined() * undefined() * enemies() and spell(vampiric_touch) or buffpresent(voidform_shadow) and spell(void_torrent) or enemies() > 1 and spell(mind_sear) or spell(mind_flay) or spell(shadow_word_pain)
}

### actions.cds

AddFunction ShadowCdsMainActions
{
 #concentrated_flame,line_cd=6,if=time<=10|(buff.chorus_of_insanity.stack>=15&buff.voidform.up)|full_recharge_time<gcd|target.time_to_die<5
 if timesincepreviousspell(concentrated_flame_essence) > 6 and { timeincombat() <= 10 or buffstacks(chorus_of_insanity) >= 15 and buffpresent(voidform_shadow) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 } spell(concentrated_flame_essence)
 #call_action_list,name=crit_cds,if=(buff.voidform.up&buff.chorus_of_insanity.stack>20)|azerite.chorus_of_insanity.rank=0
 if buffpresent(voidform_shadow) and buffstacks(chorus_of_insanity) > 20 or azeritetraitrank(chorus_of_insanity_trait) == 0 ShadowCritcdsMainActions()
}

AddFunction ShadowCdsMainPostConditions
{
 { buffpresent(voidform_shadow) and buffstacks(chorus_of_insanity) > 20 or azeritetraitrank(chorus_of_insanity_trait) == 0 } and ShadowCritcdsMainPostConditions()
}

AddFunction ShadowCdsShortCdActions
{
 #purifying_blast,if=spell_targets.mind_sear>=2|raid_event.adds.in>60
 if enemies() >= 2 or 600 > 60 spell(purifying_blast)
 #the_unbound_force
 spell(the_unbound_force)

 unless timesincepreviousspell(concentrated_flame_essence) > 6 and { timeincombat() <= 10 or buffstacks(chorus_of_insanity) >= 15 and buffpresent(voidform_shadow) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame_essence)
 {
  #ripple_in_space
  spell(ripple_in_space_essence)
  #worldvein_resonance,if=buff.lifeblood.stack<3
  if buffstacks(lifeblood_buff) < 3 spell(worldvein_resonance_essence)
  #call_action_list,name=crit_cds,if=(buff.voidform.up&buff.chorus_of_insanity.stack>20)|azerite.chorus_of_insanity.rank=0
  if buffpresent(voidform_shadow) and buffstacks(chorus_of_insanity) > 20 or azeritetraitrank(chorus_of_insanity_trait) == 0 ShadowCritcdsShortCdActions()
 }
}

AddFunction ShadowCdsShortCdPostConditions
{
 timesincepreviousspell(concentrated_flame_essence) > 6 and { timeincombat() <= 10 or buffstacks(chorus_of_insanity) >= 15 and buffpresent(voidform_shadow) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame_essence) or { buffpresent(voidform_shadow) and buffstacks(chorus_of_insanity) > 20 or azeritetraitrank(chorus_of_insanity_trait) == 0 } and ShadowCritcdsShortCdPostConditions()
}

AddFunction ShadowCdsCdActions
{
 #memory_of_lucid_dreams,if=(buff.voidform.stack>20&insanity<=50)|buff.voidform.stack>(26+7*buff.bloodlust.up)|(current_insanity_drain*((gcd.max*2)+action.mind_blast.cast_time))>insanity
 if buffstacks(voidform_shadow) > 20 and insanity() <= 50 or buffstacks(voidform_shadow) > 26 + 7 * buffpresent(bloodlust) or currentinsanitydrain() * { gcd() * 2 + casttime(mind_blast) } > insanity() spell(memory_of_lucid_dreams_essence)
 #blood_of_the_enemy
 spell(blood_of_the_enemy)
 #guardian_of_azeroth,if=buff.voidform.stack>15
 if buffstacks(voidform_shadow) > 15 spell(guardian_of_azeroth)
 #focused_azerite_beam,if=spell_targets.mind_sear>=2|raid_event.adds.in>60
 if enemies() >= 2 or 600 > 60 spell(focused_azerite_beam)

 unless { enemies() >= 2 or 600 > 60 } and spell(purifying_blast) or spell(the_unbound_force) or timesincepreviousspell(concentrated_flame_essence) > 6 and { timeincombat() <= 10 or buffstacks(chorus_of_insanity) >= 15 and buffpresent(voidform_shadow) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame_essence) or spell(ripple_in_space_essence) or buffstacks(lifeblood_buff) < 3 and spell(worldvein_resonance_essence)
 {
  #call_action_list,name=crit_cds,if=(buff.voidform.up&buff.chorus_of_insanity.stack>20)|azerite.chorus_of_insanity.rank=0
  if buffpresent(voidform_shadow) and buffstacks(chorus_of_insanity) > 20 or azeritetraitrank(chorus_of_insanity_trait) == 0 ShadowCritcdsCdActions()

  unless { buffpresent(voidform_shadow) and buffstacks(chorus_of_insanity) > 20 or azeritetraitrank(chorus_of_insanity_trait) == 0 } and ShadowCritcdsCdPostConditions()
  {
   #use_items
   shadowuseitemactions()
  }
 }
}

AddFunction ShadowCdsCdPostConditions
{
 { enemies() >= 2 or 600 > 60 } and spell(purifying_blast) or spell(the_unbound_force) or timesincepreviousspell(concentrated_flame_essence) > 6 and { timeincombat() <= 10 or buffstacks(chorus_of_insanity) >= 15 and buffpresent(voidform_shadow) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame_essence) or spell(ripple_in_space_essence) or buffstacks(lifeblood_buff) < 3 and spell(worldvein_resonance_essence) or { buffpresent(voidform_shadow) and buffstacks(chorus_of_insanity) > 20 or azeritetraitrank(chorus_of_insanity_trait) == 0 } and ShadowCritcdsCdPostConditions()
}

### actions.default

AddFunction ShadowDefaultMainActions
{
 #variable,name=dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking
 #run_action_list,name=cleave,if=active_enemies>1
 if enemies() > 1 ShadowCleaveMainActions()

 unless enemies() > 1 and ShadowCleaveMainPostConditions()
 {
  #run_action_list,name=single,if=active_enemies=1
  if enemies() == 1 ShadowSingleMainActions()
 }
}

AddFunction ShadowDefaultMainPostConditions
{
 enemies() > 1 and ShadowCleaveMainPostConditions() or enemies() == 1 and ShadowSingleMainPostConditions()
}

AddFunction ShadowDefaultShortCdActions
{
 #variable,name=dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking
 #run_action_list,name=cleave,if=active_enemies>1
 if enemies() > 1 ShadowCleaveShortCdActions()

 unless enemies() > 1 and ShadowCleaveShortCdPostConditions()
 {
  #run_action_list,name=single,if=active_enemies=1
  if enemies() == 1 ShadowSingleShortCdActions()
 }
}

AddFunction ShadowDefaultShortCdPostConditions
{
 enemies() > 1 and ShadowCleaveShortCdPostConditions() or enemies() == 1 and ShadowSingleShortCdPostConditions()
}

AddFunction ShadowDefaultCdActions
{
 undefined()
 #potion,if=buff.bloodlust.react|target.time_to_die<=80|target.health.pct<35
 if { buffpresent(bloodlust) or target.timetodie() <= 80 or target.healthpercent() < 35 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #variable,name=dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking
 #run_action_list,name=cleave,if=active_enemies>1
 if enemies() > 1 ShadowCleaveCdActions()

 unless enemies() > 1 and ShadowCleaveCdPostConditions()
 {
  #run_action_list,name=single,if=active_enemies=1
  if enemies() == 1 ShadowSingleCdActions()
 }
}

AddFunction ShadowDefaultCdPostConditions
{
 enemies() > 1 and ShadowCleaveCdPostConditions() or enemies() == 1 and ShadowSingleCdPostConditions()
}

### Shadow icons.

AddCheckBox(opt_priest_shadow_aoe l(AOE) default specialization=shadow)

AddIcon checkbox=!opt_priest_shadow_aoe enemies=1 help=shortcd specialization=shadow
{
 if not incombat() shadowprecombatshortcdactions()
 unless not incombat() and shadowprecombatshortcdpostconditions()
 {
  shadowdefaultshortcdactions()
 }
}

AddIcon checkbox=opt_priest_shadow_aoe help=shortcd specialization=shadow
{
 if not incombat() shadowprecombatshortcdactions()
 unless not incombat() and shadowprecombatshortcdpostconditions()
 {
  shadowdefaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=shadow
{
 if not incombat() shadowprecombatmainactions()
 unless not incombat() and shadowprecombatmainpostconditions()
 {
  shadowdefaultmainactions()
 }
}

AddIcon checkbox=opt_priest_shadow_aoe help=aoe specialization=shadow
{
 if not incombat() shadowprecombatmainactions()
 unless not incombat() and shadowprecombatmainpostconditions()
 {
  shadowdefaultmainactions()
 }
}

AddIcon checkbox=!opt_priest_shadow_aoe enemies=1 help=cd specialization=shadow
{
 if not incombat() shadowprecombatcdactions()
 unless not incombat() and shadowprecombatcdpostconditions()
 {
  shadowdefaultcdactions()
 }
}

AddIcon checkbox=opt_priest_shadow_aoe help=cd specialization=shadow
{
 if not incombat() shadowprecombatcdactions()
 unless not incombat() and shadowprecombatcdpostconditions()
 {
  shadowdefaultcdactions()
 }
}

### Required symbols
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
# lifeblood_buff
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
# unbridled_fury_item
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
end
