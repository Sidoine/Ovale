local __exports = LibStub:NewLibrary("ovale/scripts/ovale_priest", 80300)
if not __exports then return end
__exports.registerPriest = function(OvaleScripts)
    do
        local name = "sc_t25_priest_discipline"
        local desc = "[9.0] Simulationcraft: T25_Priest_Discipline"
        local code = [[
# Based on SimulationCraft profile "T25_Priest_Discipline".
#	class=priest
#	spec=discipline
#	talents=3020110

Include(ovale_common)
Include(ovale_priest_spells)

AddFunction disciplineuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

### actions.precombat

AddFunction disciplineprecombatmainactions
{
}

AddFunction disciplineprecombatmainpostconditions
{
}

AddFunction disciplineprecombatshortcdactions
{
}

AddFunction disciplineprecombatshortcdpostconditions
{
}

AddFunction disciplineprecombatcdactions
{
}

AddFunction disciplineprecombatcdpostconditions
{
}

### actions.boon

AddFunction disciplineboonmainactions
{
 #ascended_blast
 spell(ascended_blast)
 #ascended_nova
 spell(ascended_nova)
}

AddFunction disciplineboonmainpostconditions
{
}

AddFunction disciplineboonshortcdactions
{
}

AddFunction disciplineboonshortcdpostconditions
{
 spell(ascended_blast) or spell(ascended_nova)
}

AddFunction disciplinebooncdactions
{
}

AddFunction disciplinebooncdpostconditions
{
 spell(ascended_blast) or spell(ascended_nova)
}

### actions.default

AddFunction discipline_defaultmainactions
{
 #berserking
 spell(berserking)
 #purge_the_wicked,if=!ticking
 if not target.debuffpresent(purge_the_wicked_debuff) spell(purge_the_wicked)
 #shadow_word_pain,if=!ticking&!talent.purge_the_wicked.enabled
 if not buffpresent(shadow_word_pain) and not hastalent(purge_the_wicked_talent) spell(shadow_word_pain)
 #schism
 spell(schism)
 #mind_blast
 spell(mind_blast)
 #penance
 spell(penance)
 #purge_the_wicked,if=remains<(duration*0.3)
 if target.debuffremaining(purge_the_wicked_debuff) < baseduration(purge_the_wicked_debuff) * 0.3 spell(purge_the_wicked)
 #shadow_word_pain,if=remains<(duration*0.3)&!talent.purge_the_wicked.enabled
 if buffremaining(shadow_word_pain) < baseduration(shadow_word_pain) * 0.3 and not hastalent(purge_the_wicked_talent) spell(shadow_word_pain)
 #power_word_solace
 spell(power_word_solace)
 #divine_star,if=mana.pct>80
 if manapercent() > 80 spell(divine_star)
 #smite
 spell(smite)
 #shadow_word_pain
 spell(shadow_word_pain)
}

AddFunction discipline_defaultmainpostconditions
{
}

AddFunction discipline_defaultshortcdactions
{
 #mindbender,if=talent.mindbender.enabled
 if hastalent(mindbender_talent) spell(mindbender)

 unless spell(berserking)
 {
  #bag_of_tricks
  spell(bag_of_tricks)
  #shadow_covenant
  spell(shadow_covenant)

  unless not target.debuffpresent(purge_the_wicked_debuff) and spell(purge_the_wicked) or not buffpresent(shadow_word_pain) and not hastalent(purge_the_wicked_talent) and spell(shadow_word_pain)
  {
   #shadow_word_death
   spell(shadow_word_death)
  }
 }
}

AddFunction discipline_defaultshortcdpostconditions
{
 spell(berserking) or not target.debuffpresent(purge_the_wicked_debuff) and spell(purge_the_wicked) or not buffpresent(shadow_word_pain) and not hastalent(purge_the_wicked_talent) and spell(shadow_word_pain) or spell(schism) or spell(mind_blast) or spell(penance) or target.debuffremaining(purge_the_wicked_debuff) < baseduration(purge_the_wicked_debuff) * 0.3 and spell(purge_the_wicked) or buffremaining(shadow_word_pain) < baseduration(shadow_word_pain) * 0.3 and not hastalent(purge_the_wicked_talent) and spell(shadow_word_pain) or spell(power_word_solace) or manapercent() > 80 and spell(divine_star) or spell(smite) or spell(shadow_word_pain)
}

AddFunction discipline_defaultcdactions
{
 #use_item,slot=trinket2
 disciplineuseitemactions()

 unless hastalent(mindbender_talent) and spell(mindbender)
 {
  #shadowfiend,if=!talent.mindbender.enabled
  if not hastalent(mindbender_talent) spell(shadowfiend)
  #blood_fury
  spell(blood_fury)

  unless spell(berserking)
  {
   #arcane_torrent
   spell(arcane_torrent)
   #lights_judgment
   spell(lights_judgment)
   #fireblood
   spell(fireblood)
   #ancestral_call
   spell(ancestral_call)
  }
 }
}

AddFunction discipline_defaultcdpostconditions
{
 hastalent(mindbender_talent) and spell(mindbender) or spell(berserking) or spell(bag_of_tricks) or spell(shadow_covenant) or not target.debuffpresent(purge_the_wicked_debuff) and spell(purge_the_wicked) or not buffpresent(shadow_word_pain) and not hastalent(purge_the_wicked_talent) and spell(shadow_word_pain) or spell(shadow_word_death) or spell(schism) or spell(mind_blast) or spell(penance) or target.debuffremaining(purge_the_wicked_debuff) < baseduration(purge_the_wicked_debuff) * 0.3 and spell(purge_the_wicked) or buffremaining(shadow_word_pain) < baseduration(shadow_word_pain) * 0.3 and not hastalent(purge_the_wicked_talent) and spell(shadow_word_pain) or spell(power_word_solace) or manapercent() > 80 and spell(divine_star) or spell(smite) or spell(shadow_word_pain)
}

### Discipline icons.

AddCheckBox(opt_priest_discipline_aoe l(aoe) default specialization=discipline)

AddIcon checkbox=!opt_priest_discipline_aoe enemies=1 help=shortcd specialization=discipline
{
 if not incombat() disciplineprecombatshortcdactions()
 discipline_defaultshortcdactions()
}

AddIcon checkbox=opt_priest_discipline_aoe help=shortcd specialization=discipline
{
 if not incombat() disciplineprecombatshortcdactions()
 discipline_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=discipline
{
 if not incombat() disciplineprecombatmainactions()
 discipline_defaultmainactions()
}

AddIcon checkbox=opt_priest_discipline_aoe help=aoe specialization=discipline
{
 if not incombat() disciplineprecombatmainactions()
 discipline_defaultmainactions()
}

AddIcon checkbox=!opt_priest_discipline_aoe enemies=1 help=cd specialization=discipline
{
 if not incombat() disciplineprecombatcdactions()
 discipline_defaultcdactions()
}

AddIcon checkbox=opt_priest_discipline_aoe help=cd specialization=discipline
{
 if not incombat() disciplineprecombatcdactions()
 discipline_defaultcdactions()
}

### Required symbols
# ancestral_call
# arcane_torrent
# ascended_blast
# ascended_nova
# bag_of_tricks
# berserking
# blood_fury
# divine_star
# fireblood
# lights_judgment
# mind_blast
# mindbender
# mindbender_talent
# penance
# power_word_solace
# purge_the_wicked
# purge_the_wicked_debuff
# purge_the_wicked_talent
# schism
# shadow_covenant
# shadow_word_death
# shadow_word_pain
# shadowfiend
# smite
]]
        OvaleScripts:RegisterScript("PRIEST", "discipline", name, desc, code, "script")
    end
    do
        local name = "sc_t25_priest_shadow"
        local desc = "[9.0] Simulationcraft: T25_Priest_Shadow"
        local code = [[
# Based on SimulationCraft profile "T25_Priest_Shadow".
#	class=priest
#	spec=shadow
#	talents=3111111

Include(ovale_common)
Include(ovale_priest_spells)


AddFunction pi_or_vf_sync_condition
{
 { message("priest.self_power_infusion is not implemented") or message("runeforge.twins_of_the_sun_priestess.equipped is not implemented") } and message("level is not implemented") >= 58 and not spellcooldown(power_infusion) > 0 or { message("level is not implemented") < 58 or not message("priest.self_power_infusion is not implemented") and not message("runeforge.twins_of_the_sun_priestess.equipped is not implemented") } and not spellcooldown(void_eruption) > 0
}

AddFunction searing_nightmare_cutoff
{
 enemies() > 3
}

AddFunction all_dots_up
{
 target.debuffpresent(shadow_word_pain) and target.debuffpresent(vampiric_touch) and target.debuffpresent(devouring_plague)
}

AddFunction dots_up
{
 target.debuffpresent(shadow_word_pain) and target.debuffpresent(vampiric_touch)
}

AddFunction mind_sear_cutoff
{
 1
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=shadow)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=shadow)

AddFunction shadowinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(silence) and target.isinterruptible() spell(silence)
  if target.inrange(mind_bomb) and not target.classification(worldboss) and target.remainingcasttime() > 2 spell(mind_bomb)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
 }
}

AddFunction shadowuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

### actions.precombat

AddFunction shadowprecombatmainactions
{
 #shadowform,if=!buff.shadowform.up
 if not buffpresent(shadowform) spell(shadowform)
 #variable,name=mind_sear_cutoff,op=set,value=1
 #vampiric_touch
 spell(vampiric_touch)
}

AddFunction shadowprecombatmainpostconditions
{
}

AddFunction shadowprecombatshortcdactions
{
}

AddFunction shadowprecombatshortcdpostconditions
{
 not buffpresent(shadowform) and spell(shadowform) or spell(vampiric_touch)
}

AddFunction shadowprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

 unless not buffpresent(shadowform) and spell(shadowform)
 {
  #use_item,name=azsharas_font_of_power
  shadowuseitemactions()
 }
}

AddFunction shadowprecombatcdpostconditions
{
 not buffpresent(shadowform) and spell(shadowform) or spell(vampiric_touch)
}

### actions.cds

AddFunction shadowcdsmainactions
{
 #call_action_list,name=essences
 shadowessencesactions()
}

AddFunction shadowcdsmainpostconditions
{
}

AddFunction shadowcdsshortcdactions
{
 #call_action_list,name=essences
 shadowessencesactions()
}

AddFunction shadowcdsshortcdpostconditions
{
}

AddFunction shadowcdscdactions
{
 #silence,target_if=runeforge.sephuzs_proclamation.equipped&(target.is_add|target.debuff.casting.react)
 if message("runeforge.sephuzs_proclamation.equipped is not implemented") and { not target.classification(worldboss) or target.isinterruptible() } shadowinterruptactions()
 #call_action_list,name=essences
 shadowessencesactions()
 #use_items
 shadowuseitemactions()
}

AddFunction shadowcdscdpostconditions
{
}

### actions.default

AddFunction shadow_defaultmainactions
{
 #variable,name=dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking
 #variable,name=all_dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking&dot.devouring_plague.ticking
 #variable,name=searing_nightmare_cutoff,op=set,value=spell_targets.mind_sear>3
 #variable,name=pi_or_vf_sync_condition,op=set,value=(priest.self_power_infusion|runeforge.twins_of_the_sun_priestess.equipped)&level>=58&cooldown.power_infusion.up|(level<58|!priest.self_power_infusion&!runeforge.twins_of_the_sun_priestess.equipped)&cooldown.void_eruption.up
 #call_action_list,name=cwc
 shadowcwcactions()
 #run_action_list,name=main
 shadowmainactions()
}

AddFunction shadow_defaultmainpostconditions
{
}

AddFunction shadow_defaultshortcdactions
{
 #variable,name=dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking
 #variable,name=all_dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking&dot.devouring_plague.ticking
 #variable,name=searing_nightmare_cutoff,op=set,value=spell_targets.mind_sear>3
 #variable,name=pi_or_vf_sync_condition,op=set,value=(priest.self_power_infusion|runeforge.twins_of_the_sun_priestess.equipped)&level>=58&cooldown.power_infusion.up|(level<58|!priest.self_power_infusion&!runeforge.twins_of_the_sun_priestess.equipped)&cooldown.void_eruption.up
 #call_action_list,name=cwc
 shadowcwcactions()
 #run_action_list,name=main
 shadowmainactions()
}

AddFunction shadow_defaultshortcdpostconditions
{
}

AddFunction shadow_defaultcdactions
{
 #potion,if=buff.bloodlust.react|target.time_to_die<=80|target.health.pct<35
 if { buffpresent(bloodlust) or target.timetodie() <= 80 or target.healthpercent() < 35 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #variable,name=dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking
 #variable,name=all_dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking&dot.devouring_plague.ticking
 #variable,name=searing_nightmare_cutoff,op=set,value=spell_targets.mind_sear>3
 #variable,name=pi_or_vf_sync_condition,op=set,value=(priest.self_power_infusion|runeforge.twins_of_the_sun_priestess.equipped)&level>=58&cooldown.power_infusion.up|(level<58|!priest.self_power_infusion&!runeforge.twins_of_the_sun_priestess.equipped)&cooldown.void_eruption.up
 #call_action_list,name=cwc
 shadowcwcactions()
 #run_action_list,name=main
 shadowmainactions()
}

AddFunction shadow_defaultcdpostconditions
{
}

### Shadow icons.

AddCheckBox(opt_priest_shadow_aoe l(aoe) default specialization=shadow)

AddIcon checkbox=!opt_priest_shadow_aoe enemies=1 help=shortcd specialization=shadow
{
 if not incombat() shadowprecombatshortcdactions()
 shadow_defaultshortcdactions()
}

AddIcon checkbox=opt_priest_shadow_aoe help=shortcd specialization=shadow
{
 if not incombat() shadowprecombatshortcdactions()
 shadow_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=shadow
{
 if not incombat() shadowprecombatmainactions()
 shadow_defaultmainactions()
}

AddIcon checkbox=opt_priest_shadow_aoe help=aoe specialization=shadow
{
 if not incombat() shadowprecombatmainactions()
 shadow_defaultmainactions()
}

AddIcon checkbox=!opt_priest_shadow_aoe enemies=1 help=cd specialization=shadow
{
 if not incombat() shadowprecombatcdactions()
 shadow_defaultcdactions()
}

AddIcon checkbox=opt_priest_shadow_aoe help=cd specialization=shadow
{
 if not incombat() shadowprecombatcdactions()
 shadow_defaultcdactions()
}

### Required symbols
# bloodlust
# devouring_plague
# mind_bomb
# power_infusion
# quaking_palm
# shadow_word_pain
# shadowform
# silence
# unbridled_fury_item
# vampiric_touch
# void_eruption
# war_stomp
]]
        OvaleScripts:RegisterScript("PRIEST", "shadow", name, desc, code, "script")
    end
end
