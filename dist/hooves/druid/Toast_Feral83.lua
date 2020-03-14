local __exports = LibStub:GetLibrary("ovale/scripts/ovale_druid")
if not __exports then return end
__exports.registerDruidFeralToast83 = function(OvaleScripts)
do
	local name = "toast_feral83"
	local desc = "[Toast][8.3] Druid: Feral"
	local code = [[
# Based on SimulationCraft profile "T24_Druid_Feral".
#    class=druid
#    spec=feral
#    talents=2000122

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

Define(travel_form 783)
Define(travel_form_buff 783)

# Feral
AddIcon specialization=2 help=main
{
# Pre-combat stuff
if not BuffPresent(travel_form)
{
#mark_of_the_wild,if=!aura.str_agi_int.up
# if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
# CHANGE: Cast Healing Touch to gain Bloodtalons buff if less than 20s remaining on the buff.
#healing_touch,if=talent.bloodtalons.enabled
#if Talent(bloodtalons_talent) Spell(healing_touch)
# if Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 20 and not InCombat() and Speed() == 0 Spell(healing_touch)
if target.Present() and not target.IsDead() and not target.IsFriend()
{
#bloodtalons_talent
#if Talent(bloodtalons_talent) and BuffRemains(bloodtalons_buff) <= CastTime(regrowth) and not InCombat() and { Speed() == 0 or BuffPresent(movement_allowed_buff) } Spell(regrowth)
#cat_form
#if not BuffPresent(cat_form) Spell(cat_form)
#prowl
if not { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and not InCombat() Spell(prowl)
}
#not bloodtalons_talent
if not { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and not Talent(bloodtalons_talent) and { HealthPercent() < 100 and { not BuffPresent(regrowth_buff) or not InCombat() } or HealthPercent() < 80 } and CastTime(regrowth) <= 0 Spell(regrowth)
}

# Interrupt
#if InCombat() and not mounted() and not BuffPresent(travel_form) InterruptActions()

# Rotation
if target.InRange(rake) and HasFullControl() and target.Present()
{
#cat_form
#if not BuffPresent(cat_form) Spell(cat_form)

# Cooldowns
if BuffPresent(cat_form)
{
if Boss()
{
FeralDefaultCdActions()
}

# Short Cooldowns
FeralDefaultShortCdActions()

# Default Actions
FeralDefaultMainActions()
}
}
#if InCombat() and target.Present() and not target.IsFriend() and not target.InRange(rake) and target.InRange(wild_charge) and { TimeInCombat() < 6 or Falling() } Spell(wild_charge)
#if CheckBoxOn(travers) Travel()
}
AddFunction Boss
{
IsBossFight() or target.Classification(worldboss) or target.Classification(rareelite) or BuffPresent(burst_haste_buff any=1) or { target.IsPvP() and not target.IsFriend() }
}

AddFunction opener_done
{
 target.debuffpresent(rip_debuff)
}

AddFunction use_thrash
{
 if hasazeritetrait(wild_fleshrending_trait) 2
 0
}

AddFunction feralinterruptactions
{
# if target.hasmanagedinterrupts() and target.mustbeinterrupted() or not target.hasmanagedinterrupts() and target.isinterruptible()
 #{
  #if target.inrange(skull_bash) and target.isinterruptible() and target.remainingcasttime() <= casttime(skull_bash) + gcd() spell(skull_bash)
  #if target.inrange(mighty_bash) and not target.classification(worldboss) and target.remainingcasttime() <= casttime(mighty_bash) + gcd() spell(mighty_bash)
  #if target.inrange(maim) and not target.classification(worldboss) and target.remainingcasttime() <= casttime(maim) + gcd() spell(maim)
  #if target.distance(less 5) and not target.classification(worldboss) and target.remainingcasttime() <= casttime(war_stomp) + gcd() spell(war_stomp)
  #if target.distance(less 15) and not target.classification(worldboss) and target.remainingcasttime() <= casttime(typhoon) + gcd() spell(typhoon)
 #}
}

AddFunction feraluseheartessence
{
 #spell(concentrated_flame_essence)
}

AddFunction feraluseitemactions
{
 #if item(trinket0slot usable=1) texture(inv_jewelry_talisman_12)
 #if item(trinket1slot usable=1) texture(inv_jewelry_talisman_12)
}

AddFunction feralgetinmeleerange
{
 if checkboxon(opt_melee_range) and stance(druid_bear_form) and not target.inrange(mangle) or { stance(druid_cat_form) or stance(druid_claws_of_shirvallah) } and not target.inrange(shred)
 {
  if target.inrange(wild_charge) spell(wild_charge)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.default

AddFunction feraldefaultmainactions
{
 #run_action_list,name=opener,if=variable.opener_done=0
 if opener_done() == 0 feralopenermainactions()

 unless opener_done() == 0 and feralopenermainpostconditions()
 {
  #cat_form,if=!buff.cat_form.up
  if not buffpresent(cat_form_buff) spell(cat_form)
  #rake,if=buff.prowl.up|buff.shadowmeld.up
  if buffpresent(prowl_buff) or buffpresent(shadowmeld_buff) spell(rake)
  #call_action_list,name=cooldowns
  feralcooldownsmainactions()

  unless feralcooldownsmainpostconditions()
  {
   #ferocious_bite,target_if=dot.rip.ticking&dot.rip.remains<3&target.time_to_die>10&(talent.sabertooth.enabled)
   if target.debuffpresent(rip_debuff) and target.debuffremaining(rip_debuff) < 3 and target.timetodie() > 10 and hastalent(sabertooth_talent) spell(ferocious_bite)
   #regrowth,if=combo_points=5&buff.predatory_swiftness.up&talent.bloodtalons.enabled&buff.bloodtalons.down
   if combopoints() == 5 and buffpresent(predatory_swiftness_buff) and hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } spell(regrowth)
   #run_action_list,name=finishers,if=combo_points>4
   if combopoints() > 4 feralfinishersmainactions()

   unless combopoints() > 4 and feralfinishersmainpostconditions()
   {
    #run_action_list,name=generators
    feralgeneratorsmainactions()
   }
  }
 }
}

AddFunction feraldefaultmainpostconditions
{
 opener_done() == 0 and feralopenermainpostconditions() or feralcooldownsmainpostconditions() or combopoints() > 4 and feralfinishersmainpostconditions() or feralgeneratorsmainpostconditions()
}

AddFunction feraldefaultshortcdactions
{
 #auto_attack,if=!buff.prowl.up&!buff.shadowmeld.up
 if not buffpresent(prowl_buff) and not buffpresent(shadowmeld_buff) feralgetinmeleerange()
 #run_action_list,name=opener,if=variable.opener_done=0
 if opener_done() == 0 feralopenershortcdactions()

 unless opener_done() == 0 and feralopenershortcdpostconditions() or not buffpresent(cat_form_buff) and spell(cat_form) or { buffpresent(prowl_buff) or buffpresent(shadowmeld_buff) } and spell(rake)
 {
  #call_action_list,name=cooldowns
  feralcooldownsshortcdactions()

  unless feralcooldownsshortcdpostconditions() or target.debuffpresent(rip_debuff) and target.debuffremaining(rip_debuff) < 3 and target.timetodie() > 10 and hastalent(sabertooth_talent) and spell(ferocious_bite) or combopoints() == 5 and buffpresent(predatory_swiftness_buff) and hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth)
  {
   #run_action_list,name=finishers,if=combo_points>4
   if combopoints() > 4 feralfinishersshortcdactions()

   unless combopoints() > 4 and feralfinishersshortcdpostconditions()
   {
    #run_action_list,name=generators
    feralgeneratorsshortcdactions()
   }
  }
 }
}

AddFunction feraldefaultshortcdpostconditions
{
 opener_done() == 0 and feralopenershortcdpostconditions() or not buffpresent(cat_form_buff) and spell(cat_form) or { buffpresent(prowl_buff) or buffpresent(shadowmeld_buff) } and spell(rake) or feralcooldownsshortcdpostconditions() or target.debuffpresent(rip_debuff) and target.debuffremaining(rip_debuff) < 3 and target.timetodie() > 10 and hastalent(sabertooth_talent) and spell(ferocious_bite) or combopoints() == 5 and buffpresent(predatory_swiftness_buff) and hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or combopoints() > 4 and feralfinishersshortcdpostconditions() or feralgeneratorsshortcdpostconditions()
}

AddFunction feraldefaultcdactions
{
 feralinterruptactions()
 #run_action_list,name=opener,if=variable.opener_done=0
 if opener_done() == 0 feralopenercdactions()

 unless opener_done() == 0 and feralopenercdpostconditions() or not buffpresent(cat_form_buff) and spell(cat_form) or { buffpresent(prowl_buff) or buffpresent(shadowmeld_buff) } and spell(rake)
 {
  #call_action_list,name=cooldowns
  feralcooldownscdactions()

  unless feralcooldownscdpostconditions() or target.debuffpresent(rip_debuff) and target.debuffremaining(rip_debuff) < 3 and target.timetodie() > 10 and hastalent(sabertooth_talent) and spell(ferocious_bite) or combopoints() == 5 and buffpresent(predatory_swiftness_buff) and hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth)
  {
   #run_action_list,name=finishers,if=combo_points>4
   if combopoints() > 4 feralfinisherscdactions()

   unless combopoints() > 4 and feralfinisherscdpostconditions()
   {
    #run_action_list,name=generators
    feralgeneratorscdactions()
   }
  }
 }
}

AddFunction feraldefaultcdpostconditions
{
 opener_done() == 0 and feralopenercdpostconditions() or not buffpresent(cat_form_buff) and spell(cat_form) or { buffpresent(prowl_buff) or buffpresent(shadowmeld_buff) } and spell(rake) or feralcooldownscdpostconditions() or target.debuffpresent(rip_debuff) and target.debuffremaining(rip_debuff) < 3 and target.timetodie() > 10 and hastalent(sabertooth_talent) and spell(ferocious_bite) or combopoints() == 5 and buffpresent(predatory_swiftness_buff) and hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or combopoints() > 4 and feralfinisherscdpostconditions() or feralgeneratorscdpostconditions()
}

### actions.cooldowns

AddFunction feralcooldownsmainactions
{
 #thorns,if=active_enemies>desired_targets|raid_event.adds.in>45
 if enemies(tagged=1) > 5 or 600 > 45 spell(thorns)
}

AddFunction feralcooldownsmainpostconditions
{
}

AddFunction feralcooldownsshortcdactions
{
 #tigers_fury,if=energy.deficit>=60
 if energydeficit() >= 60 spell(tigers_fury)

 unless { enemies(tagged=1) > 5 or 600 > 45 } and spell(thorns)
 {
  #the_unbound_force,if=buff.reckless_force.up|buff.tigers_fury.up
  if buffpresent(reckless_force_buff) or buffpresent(tigers_fury_buff) spell(the_unbound_force)
  #blood_of_the_enemy,if=buff.tigers_fury.up
  #if buffpresent(tigers_fury_buff) spell(blood_of_the_enemy)
  #feral_frenzy,if=combo_points=0
  if combopoints() == 0 spell(feral_frenzy)
  #purifying_blast,if=active_enemies>desired_targets|raid_event.adds.in>60
  if enemies(tagged=1) > 5 or 600 > 60 spell(purifying_blast)
 }
}

AddFunction feralcooldownsshortcdpostconditions
{
 { enemies(tagged=1) > 5 or 600 > 45 } and spell(thorns)
}

AddFunction feralcooldownscdactions
{
 #berserk,if=energy>=30&(cooldown.tigers_fury.remains>5|buff.tigers_fury.up)
 if energy() >= 30 and { spellcooldown(tigers_fury) > 5 or buffpresent(tigers_fury_buff) } and checkboxon(UseCooldowns) spell(berserk)
 #berserking
 if checkboxon(UseCooldowns) Spell(berserking)

 unless { enemies(tagged=1) > 5 or 600 > 45 } and spell(thorns) or { buffpresent(reckless_force_buff) or buffpresent(tigers_fury_buff) } and spell(the_unbound_force)
 {
  #memory_of_lucid_dreams,if=buff.tigers_fury.up&buff.berserk.down
  if buffpresent(tigers_fury_buff) and buffexpires(berserk_buff) spell(memory_of_lucid_dreams_essence)

  unless combopoints() == 0 and spell(feral_frenzy)
  {
   #focused_azerite_beam,if=active_enemies>desired_targets|(raid_event.adds.in>90&energy.deficit>=50)
   if enemies(tagged=1) > 5 or 600 > 90 and energydeficit() >= 50 spell(focused_azerite_beam)

   unless { enemies(tagged=1) > 5 or 600 > 60 } and spell(purifying_blast)
   {
    #heart_essence,if=buff.tigers_fury.up
    if buffpresent(tigers_fury_buff) feraluseheartessence()
    #incarnation,if=energy>=30&(cooldown.tigers_fury.remains>15|buff.tigers_fury.up)
    if energy() >= 30 and { spellcooldown(tigers_fury) > 15 or buffpresent(tigers_fury_buff) } spell(incarnation_king_of_the_jungle)
    #potion,if=target.time_to_die<65|(time_to_die<180&(buff.berserk.up|buff.incarnation.up))
    if { target.timetodie() < 65 or target.timetodie() < 180 and { buffpresent(berserk_buff) or buffpresent(incarnation_king_of_the_jungle_buff) } } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)
    #shadowmeld,if=combo_points<5&energy>=action.rake.cost&dot.rake.pmultiplier<2.1&buff.tigers_fury.up&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(!talent.incarnation.enabled|cooldown.incarnation.remains>18)&!buff.incarnation.up
    if combopoints() < 5 and energy() >= powercost(rake) and target.debuffpersistentmultiplier(rake_debuff) < 2.1 and buffpresent(tigers_fury_buff) and { buffpresent(bloodtalons_buff) or not hastalent(bloodtalons_talent) } and { not hastalent(incarnation_talent) or spellcooldown(incarnation_king_of_the_jungle) > 18 } and not buffpresent(incarnation_king_of_the_jungle_buff) spell(shadowmeld)
    #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.conductive_ink_debuff.up&target.time_to_pct_30<1.5|!debuff.conductive_ink_debuff.up&(debuff.razor_coral_debuff.stack>=25-10*debuff.blood_of_the_enemy.up|target.time_to_die<40)&buff.tigers_fury.remains>10
    if target.debuffexpires(razor_coral_debuff) or target.debuffpresent(conductive_ink_debuff) and target.timetohealthpercent(30) < 1.5 or not target.debuffpresent(conductive_ink_debuff) and { target.debuffstacks(razor_coral_debuff) >= 25 - 10 * target.debuffpresent(blood_of_the_enemy) or target.timetodie() < 40 } and buffremaining(tigers_fury_buff) > 10 feraluseitemactions()
    #use_item,effect_name=cyclotronic_blast,if=(energy.deficit>=energy.regen*3)&buff.tigers_fury.down&!azerite.jungle_fury.enabled
    if energydeficit() >= energyregenrate() * 3 and buffexpires(tigers_fury_buff) and not hasazeritetrait(jungle_fury_trait) feraluseitemactions()
    #use_item,effect_name=cyclotronic_blast,if=buff.tigers_fury.up&azerite.jungle_fury.enabled
    if buffpresent(tigers_fury_buff) and hasazeritetrait(jungle_fury_trait) feraluseitemactions()
    #use_item,effect_name=azsharas_font_of_power,if=energy.deficit>=50
    if energydeficit() >= 50 feraluseitemactions()
    #use_items,if=buff.tigers_fury.up|target.time_to_die<20
    if buffpresent(tigers_fury_buff) or target.timetodie() < 20 feraluseitemactions()
   }
  }
 }
}

AddFunction feralcooldownscdpostconditions
{
 { enemies(tagged=1) > 5 or 600 > 45 } and spell(thorns) or { buffpresent(reckless_force_buff) or buffpresent(tigers_fury_buff) } and spell(the_unbound_force) or combopoints() == 0 and spell(feral_frenzy) or { enemies(tagged=1) > 5 or 600 > 60 } and spell(purifying_blast)
}

### actions.finishers

AddFunction feralfinishersmainactions
{
 #pool_resource,for_next=1
 #savage_roar,if=buff.savage_roar.down
 if buffexpires(savage_roar_buff) spell(savage_roar)
 unless buffexpires(savage_roar_buff) and spellusable(savage_roar) and spellcooldown(savage_roar) < timetoenergyfor(savage_roar)
 {
  #pool_resource,for_next=1
  #primal_wrath,target_if=spell_targets.primal_wrath>1&dot.rip.remains<4
  if enemies(tagged=1) > 1 and target.debuffremaining(rip_debuff) < 4 spell(primal_wrath)
  unless enemies(tagged=1) > 1 and target.debuffremaining(rip_debuff) < 4 and spellusable(primal_wrath) and spellcooldown(primal_wrath) < timetoenergyfor(primal_wrath)
  {
   #pool_resource,for_next=1
   #primal_wrath,target_if=spell_targets.primal_wrath>=2
   if enemies(tagged=1) >= 2 spell(primal_wrath)
   unless enemies(tagged=1) >= 2 and spellusable(primal_wrath) and spellcooldown(primal_wrath) < timetoenergyfor(primal_wrath)
   {
    #pool_resource,for_next=1
    #rip,target_if=!ticking|(remains<=duration*0.3)&(!talent.sabertooth.enabled)|(remains<=duration*0.8&persistent_multiplier>dot.rip.pmultiplier)&target.time_to_die>8
    if not target.debuffpresent(rip_debuff) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.3 and not hastalent(sabertooth_talent) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.8 and persistentmultiplier(rip_debuff) > target.debuffpersistentmultiplier(rip_debuff) and target.timetodie() > 8 spell(rip)
    unless { not target.debuffpresent(rip_debuff) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.3 and not hastalent(sabertooth_talent) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.8 and persistentmultiplier(rip_debuff) > target.debuffpersistentmultiplier(rip_debuff) and target.timetodie() > 8 } and spellusable(rip) and spellcooldown(rip) < timetoenergyfor(rip)
    {
     #pool_resource,for_next=1
     #savage_roar,if=buff.savage_roar.remains<12
     if buffremaining(savage_roar_buff) < 12 spell(savage_roar)
     unless buffremaining(savage_roar_buff) < 12 and spellusable(savage_roar) and spellcooldown(savage_roar) < timetoenergyfor(savage_roar)
     {
      #pool_resource,for_next=1
      #maim,if=buff.iron_jaws.up
      if buffpresent(iron_jaws) spell(maim)
      unless buffpresent(iron_jaws) and spellusable(maim) and spellcooldown(maim) < timetoenergyfor(maim)
      {
       #ferocious_bite,max_energy=1,target_if=max:druid.rip.ticks_gained_on_refresh
       if energy() >= energycost(ferocious_bite max=1) spell(ferocious_bite)
      }
     }
    }
   }
  }
 }
}

AddFunction feralfinishersmainpostconditions
{
}

AddFunction feralfinishersshortcdactions
{
}

AddFunction feralfinishersshortcdpostconditions
{
 buffexpires(savage_roar_buff) and spell(savage_roar) or not { buffexpires(savage_roar_buff) and spellusable(savage_roar) and spellcooldown(savage_roar) < timetoenergyfor(savage_roar) } and { enemies(tagged=1) > 1 and target.debuffremaining(rip_debuff) < 4 and spell(primal_wrath) or not { enemies(tagged=1) > 1 and target.debuffremaining(rip_debuff) < 4 and spellusable(primal_wrath) and spellcooldown(primal_wrath) < timetoenergyfor(primal_wrath) } and { enemies(tagged=1) >= 2 and spell(primal_wrath) or not { enemies(tagged=1) >= 2 and spellusable(primal_wrath) and spellcooldown(primal_wrath) < timetoenergyfor(primal_wrath) } and { { not target.debuffpresent(rip_debuff) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.3 and not hastalent(sabertooth_talent) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.8 and persistentmultiplier(rip_debuff) > target.debuffpersistentmultiplier(rip_debuff) and target.timetodie() > 8 } and spell(rip) or not { { not target.debuffpresent(rip_debuff) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.3 and not hastalent(sabertooth_talent) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.8 and persistentmultiplier(rip_debuff) > target.debuffpersistentmultiplier(rip_debuff) and target.timetodie() > 8 } and spellusable(rip) and spellcooldown(rip) < timetoenergyfor(rip) } and { buffremaining(savage_roar_buff) < 12 and spell(savage_roar) or not { buffremaining(savage_roar_buff) < 12 and spellusable(savage_roar) and spellcooldown(savage_roar) < timetoenergyfor(savage_roar) } and { buffpresent(iron_jaws) and spell(maim) or not { buffpresent(iron_jaws) and spellusable(maim) and spellcooldown(maim) < timetoenergyfor(maim) } and energy() >= energycost(ferocious_bite max=1) and spell(ferocious_bite) } } } } }
}

AddFunction feralfinisherscdactions
{
}

AddFunction feralfinisherscdpostconditions
{
 buffexpires(savage_roar_buff) and spell(savage_roar) or not { buffexpires(savage_roar_buff) and spellusable(savage_roar) and spellcooldown(savage_roar) < timetoenergyfor(savage_roar) } and { enemies(tagged=1) > 1 and target.debuffremaining(rip_debuff) < 4 and spell(primal_wrath) or not { enemies(tagged=1) > 1 and target.debuffremaining(rip_debuff) < 4 and spellusable(primal_wrath) and spellcooldown(primal_wrath) < timetoenergyfor(primal_wrath) } and { enemies(tagged=1) >= 2 and spell(primal_wrath) or not { enemies(tagged=1) >= 2 and spellusable(primal_wrath) and spellcooldown(primal_wrath) < timetoenergyfor(primal_wrath) } and { { not target.debuffpresent(rip_debuff) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.3 and not hastalent(sabertooth_talent) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.8 and persistentmultiplier(rip_debuff) > target.debuffpersistentmultiplier(rip_debuff) and target.timetodie() > 8 } and spell(rip) or not { { not target.debuffpresent(rip_debuff) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.3 and not hastalent(sabertooth_talent) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.8 and persistentmultiplier(rip_debuff) > target.debuffpersistentmultiplier(rip_debuff) and target.timetodie() > 8 } and spellusable(rip) and spellcooldown(rip) < timetoenergyfor(rip) } and { buffremaining(savage_roar_buff) < 12 and spell(savage_roar) or not { buffremaining(savage_roar_buff) < 12 and spellusable(savage_roar) and spellcooldown(savage_roar) < timetoenergyfor(savage_roar) } and { buffpresent(iron_jaws) and spell(maim) or not { buffpresent(iron_jaws) and spellusable(maim) and spellcooldown(maim) < timetoenergyfor(maim) } and energy() >= energycost(ferocious_bite max=1) and spell(ferocious_bite) } } } } }
}

### actions.generators

AddFunction feralgeneratorsmainactions
{
 #regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&combo_points=4&dot.rake.remains<4
 if hastalent(bloodtalons_talent) and buffpresent(predatory_swiftness_buff) and buffexpires(bloodtalons_buff) and combopoints() == 4 and target.debuffremaining(rake_debuff) < 4 and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } spell(regrowth)
 #regrowth,if=talent.bloodtalons.enabled&buff.bloodtalons.down&buff.predatory_swiftness.up&talent.lunar_inspiration.enabled&dot.rake.remains<1
 if hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and buffpresent(predatory_swiftness_buff) and hastalent(lunar_inspiration_talent) and target.debuffremaining(rake_debuff) < 1 and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } spell(regrowth)
 #brutal_slash,if=spell_targets.brutal_slash>desired_targets
 if enemies(tagged=1) > 5 spell(brutal_slash)
 #pool_resource,for_next=1
 #thrash_cat,if=(refreshable)&(spell_targets.thrash_cat>2)
 if target.refreshable(thrash_cat_debuff) and enemies(tagged=1) > 2 spell(thrash_cat)
 unless target.refreshable(thrash_cat_debuff) and enemies(tagged=1) > 2 and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat)
 {
  #pool_resource,for_next=1
  #thrash_cat,if=(talent.scent_of_blood.enabled&buff.scent_of_blood.down)&spell_targets.thrash_cat>3
  if hastalent(scent_of_blood_talent) and buffexpires(scent_of_blood_feral) and enemies(tagged=1) > 3 spell(thrash_cat)
  unless hastalent(scent_of_blood_talent) and buffexpires(scent_of_blood_feral) and enemies(tagged=1) > 3 and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat)
  {
   #pool_resource,for_next=1
   #swipe_cat,if=buff.scent_of_blood.up|(action.swipe_cat.damage*spell_targets.swipe_cat>(action.rake.damage+(action.rake_bleed.tick_damage*5)))
   if buffpresent(scent_of_blood_feral) or damage(swipe_cat) * enemies(tagged=1) > damage(rake) + target.lastdamage(rake_debuff) * 5 spell(swipe_cat)
   unless { buffpresent(scent_of_blood_feral) or damage(swipe_cat) * enemies(tagged=1) > damage(rake) + target.lastdamage(rake_debuff) * 5 } and spellusable(swipe_cat) and spellcooldown(swipe_cat) < timetoenergyfor(swipe_cat)
   {
    #pool_resource,for_next=1
    #rake,target_if=!ticking|(!talent.bloodtalons.enabled&remains<duration*0.3)&target.time_to_die>4
    if not target.debuffpresent(rake_debuff) or not hastalent(bloodtalons_talent) and target.debuffremaining(rake_debuff) < baseduration(rake_debuff) * 0.3 and target.timetodie() > 4 spell(rake)
    unless { not target.debuffpresent(rake_debuff) or not hastalent(bloodtalons_talent) and target.debuffremaining(rake_debuff) < baseduration(rake_debuff) * 0.3 and target.timetodie() > 4 } and spellusable(rake) and spellcooldown(rake) < timetoenergyfor(rake)
    {
     #pool_resource,for_next=1
     #rake,target_if=talent.bloodtalons.enabled&buff.bloodtalons.up&((remains<=7)&persistent_multiplier>dot.rake.pmultiplier*0.85)&target.time_to_die>4
     if hastalent(bloodtalons_talent) and buffpresent(bloodtalons_buff) and target.debuffremaining(rake_debuff) <= 7 and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) * 0.85 and target.timetodie() > 4 spell(rake)
     unless hastalent(bloodtalons_talent) and buffpresent(bloodtalons_buff) and target.debuffremaining(rake_debuff) <= 7 and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) * 0.85 and target.timetodie() > 4 and spellusable(rake) and spellcooldown(rake) < timetoenergyfor(rake)
     {
      #moonfire_cat,if=buff.bloodtalons.up&buff.predatory_swiftness.down&combo_points<5
      if buffpresent(bloodtalons_buff) and buffexpires(predatory_swiftness_buff) and combopoints() < 5 spell(moonfire_cat)
      #brutal_slash,if=(buff.tigers_fury.up&(raid_event.adds.in>(1+max_charges-charges_fractional)*recharge_time))
      if buffpresent(tigers_fury_buff) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) spell(brutal_slash)
      #moonfire_cat,target_if=refreshable
      if target.refreshable(moonfire_cat_debuff) spell(moonfire_cat)
      #pool_resource,for_next=1
      #thrash_cat,if=refreshable&((variable.use_thrash=2&(!buff.incarnation.up|azerite.wild_fleshrending.enabled))|spell_targets.thrash_cat>1)
      if target.refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } or enemies(tagged=1) > 1 } spell(thrash_cat)
      unless target.refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } or enemies(tagged=1) > 1 } and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat)
      {
       #thrash_cat,if=refreshable&variable.use_thrash=1&buff.clearcasting.react&(!buff.incarnation.up|azerite.wild_fleshrending.enabled)
       if target.refreshable(thrash_cat_debuff) and use_thrash() == 1 and buffpresent(clearcasting_buff) and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } spell(thrash_cat)
       #pool_resource,for_next=1
       #swipe_cat,if=spell_targets.swipe_cat>1
       if enemies(tagged=1) > 1 spell(swipe_cat)
       unless enemies(tagged=1) > 1 and spellusable(swipe_cat) and spellcooldown(swipe_cat) < timetoenergyfor(swipe_cat)
       {
        #shred,if=dot.rake.remains>(action.shred.cost+action.rake.cost-energy)%energy.regen|buff.clearcasting.react
        if target.debuffremaining(rake_debuff) > { powercost(shred) + powercost(rake) - energy() } / energyregenrate() or buffpresent(clearcasting_buff) spell(shred)
       }
      }
     }
    }
   }
  }
 }
}

AddFunction feralgeneratorsmainpostconditions
{
}

AddFunction feralgeneratorsshortcdactions
{
}

AddFunction feralgeneratorsshortcdpostconditions
{
 hastalent(bloodtalons_talent) and buffpresent(predatory_swiftness_buff) and buffexpires(bloodtalons_buff) and combopoints() == 4 and target.debuffremaining(rake_debuff) < 4 and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and buffpresent(predatory_swiftness_buff) and hastalent(lunar_inspiration_talent) and target.debuffremaining(rake_debuff) < 1 and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or enemies(tagged=1) > 5 and spell(brutal_slash) or target.refreshable(thrash_cat_debuff) and enemies(tagged=1) > 2 and spell(thrash_cat) or not { target.refreshable(thrash_cat_debuff) and enemies(tagged=1) > 2 and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat) } and { hastalent(scent_of_blood_talent) and buffexpires(scent_of_blood_feral) and enemies(tagged=1) > 3 and spell(thrash_cat) or not { hastalent(scent_of_blood_talent) and buffexpires(scent_of_blood_feral) and enemies(tagged=1) > 3 and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat) } and { { buffpresent(scent_of_blood_feral) or damage(swipe_cat) * enemies(tagged=1) > damage(rake) + target.lastdamage(rake_debuff) * 5 } and spell(swipe_cat) or not { { buffpresent(scent_of_blood_feral) or damage(swipe_cat) * enemies(tagged=1) > damage(rake) + target.lastdamage(rake_debuff) * 5 } and spellusable(swipe_cat) and spellcooldown(swipe_cat) < timetoenergyfor(swipe_cat) } and { { not target.debuffpresent(rake_debuff) or not hastalent(bloodtalons_talent) and target.debuffremaining(rake_debuff) < baseduration(rake_debuff) * 0.3 and target.timetodie() > 4 } and spell(rake) or not { { not target.debuffpresent(rake_debuff) or not hastalent(bloodtalons_talent) and target.debuffremaining(rake_debuff) < baseduration(rake_debuff) * 0.3 and target.timetodie() > 4 } and spellusable(rake) and spellcooldown(rake) < timetoenergyfor(rake) } and { hastalent(bloodtalons_talent) and buffpresent(bloodtalons_buff) and target.debuffremaining(rake_debuff) <= 7 and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) * 0.85 and target.timetodie() > 4 and spell(rake) or not { hastalent(bloodtalons_talent) and buffpresent(bloodtalons_buff) and target.debuffremaining(rake_debuff) <= 7 and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) * 0.85 and target.timetodie() > 4 and spellusable(rake) and spellcooldown(rake) < timetoenergyfor(rake) } and { buffpresent(bloodtalons_buff) and buffexpires(predatory_swiftness_buff) and combopoints() < 5 and spell(moonfire_cat) or buffpresent(tigers_fury_buff) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and spell(brutal_slash) or target.refreshable(moonfire_cat_debuff) and spell(moonfire_cat) or target.refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } or enemies(tagged=1) > 1 } and spell(thrash_cat) or not { target.refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } or enemies(tagged=1) > 1 } and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat) } and { target.refreshable(thrash_cat_debuff) and use_thrash() == 1 and buffpresent(clearcasting_buff) and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } and spell(thrash_cat) or enemies(tagged=1) > 1 and spell(swipe_cat) or not { enemies(tagged=1) > 1 and spellusable(swipe_cat) and spellcooldown(swipe_cat) < timetoenergyfor(swipe_cat) } and { target.debuffremaining(rake_debuff) > { powercost(shred) + powercost(rake) - energy() } / energyregenrate() or buffpresent(clearcasting_buff) } and spell(shred) } } } } } }
}

AddFunction feralgeneratorscdactions
{
}

AddFunction feralgeneratorscdpostconditions
{
 hastalent(bloodtalons_talent) and buffpresent(predatory_swiftness_buff) and buffexpires(bloodtalons_buff) and combopoints() == 4 and target.debuffremaining(rake_debuff) < 4 and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and buffpresent(predatory_swiftness_buff) and hastalent(lunar_inspiration_talent) and target.debuffremaining(rake_debuff) < 1 and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or enemies(tagged=1) > 5 and spell(brutal_slash) or target.refreshable(thrash_cat_debuff) and enemies(tagged=1) > 2 and spell(thrash_cat) or not { target.refreshable(thrash_cat_debuff) and enemies(tagged=1) > 2 and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat) } and { hastalent(scent_of_blood_talent) and buffexpires(scent_of_blood_feral) and enemies(tagged=1) > 3 and spell(thrash_cat) or not { hastalent(scent_of_blood_talent) and buffexpires(scent_of_blood_feral) and enemies(tagged=1) > 3 and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat) } and { { buffpresent(scent_of_blood_feral) or damage(swipe_cat) * enemies(tagged=1) > damage(rake) + target.lastdamage(rake_debuff) * 5 } and spell(swipe_cat) or not { { buffpresent(scent_of_blood_feral) or damage(swipe_cat) * enemies(tagged=1) > damage(rake) + target.lastdamage(rake_debuff) * 5 } and spellusable(swipe_cat) and spellcooldown(swipe_cat) < timetoenergyfor(swipe_cat) } and { { not target.debuffpresent(rake_debuff) or not hastalent(bloodtalons_talent) and target.debuffremaining(rake_debuff) < baseduration(rake_debuff) * 0.3 and target.timetodie() > 4 } and spell(rake) or not { { not target.debuffpresent(rake_debuff) or not hastalent(bloodtalons_talent) and target.debuffremaining(rake_debuff) < baseduration(rake_debuff) * 0.3 and target.timetodie() > 4 } and spellusable(rake) and spellcooldown(rake) < timetoenergyfor(rake) } and { hastalent(bloodtalons_talent) and buffpresent(bloodtalons_buff) and target.debuffremaining(rake_debuff) <= 7 and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) * 0.85 and target.timetodie() > 4 and spell(rake) or not { hastalent(bloodtalons_talent) and buffpresent(bloodtalons_buff) and target.debuffremaining(rake_debuff) <= 7 and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) * 0.85 and target.timetodie() > 4 and spellusable(rake) and spellcooldown(rake) < timetoenergyfor(rake) } and { buffpresent(bloodtalons_buff) and buffexpires(predatory_swiftness_buff) and combopoints() < 5 and spell(moonfire_cat) or buffpresent(tigers_fury_buff) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and spell(brutal_slash) or target.refreshable(moonfire_cat_debuff) and spell(moonfire_cat) or target.refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } or enemies(tagged=1) > 1 } and spell(thrash_cat) or not { target.refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } or enemies(tagged=1) > 1 } and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat) } and { target.refreshable(thrash_cat_debuff) and use_thrash() == 1 and buffpresent(clearcasting_buff) and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } and spell(thrash_cat) or enemies(tagged=1) > 1 and spell(swipe_cat) or not { enemies(tagged=1) > 1 and spellusable(swipe_cat) and spellcooldown(swipe_cat) < timetoenergyfor(swipe_cat) } and { target.debuffremaining(rake_debuff) > { powercost(shred) + powercost(rake) - energy() } / energyregenrate() or buffpresent(clearcasting_buff) } and spell(shred) } } } } } }
}

### actions.opener

AddFunction feralopenermainactions
{
 #rake,if=!ticking|buff.prowl.up
 if not target.debuffpresent(rake_debuff) or buffpresent(prowl_buff) spell(rake)
 #variable,name=opener_done,value=dot.rip.ticking
 #wait,sec=0.001,if=dot.rip.ticking
 #moonfire_cat,if=!ticking
 if not target.debuffpresent(moonfire_cat_debuff) spell(moonfire_cat)
 #rip,if=!ticking
 if not target.debuffpresent(rip_debuff) spell(rip)
}

AddFunction feralopenermainpostconditions
{
}

AddFunction feralopenershortcdactions
{
 #tigers_fury
 spell(tigers_fury)
}

AddFunction feralopenershortcdpostconditions
{
 { not target.debuffpresent(rake_debuff) or buffpresent(prowl_buff) } and spell(rake) or not target.debuffpresent(moonfire_cat_debuff) and spell(moonfire_cat) or not target.debuffpresent(rip_debuff) and spell(rip)
}

AddFunction feralopenercdactions
{
}

AddFunction feralopenercdpostconditions
{
 { not target.debuffpresent(rake_debuff) or buffpresent(prowl_buff) } and spell(rake) or not target.debuffpresent(moonfire_cat_debuff) and spell(moonfire_cat) or not target.debuffpresent(rip_debuff) and spell(rip)
}

### actions.precombat

AddFunction feralprecombatmainactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #variable,name=use_thrash,value=0
 #variable,name=use_thrash,value=2,if=azerite.wild_fleshrending.enabled
 #regrowth,if=talent.bloodtalons.enabled
 if hastalent(bloodtalons_talent) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } spell(regrowth)
 #cat_form
 spell(cat_form)
}

AddFunction feralprecombatmainpostconditions
{
}

AddFunction feralprecombatshortcdactions
{
 unless hastalent(bloodtalons_talent) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or spell(cat_form)
 {
  #prowl
  spell(prowl)
 }
}

AddFunction feralprecombatshortcdpostconditions
{
 hastalent(bloodtalons_talent) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or spell(cat_form)
}

AddFunction feralprecombatcdactions
{
 unless hastalent(bloodtalons_talent) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth)
 {
  #use_item,name=azsharas_font_of_power
  #feraluseitemactions()

  unless spell(cat_form)
  {
   #potion,dynamic_prepot=1
   #if checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)
   #berserk
   if checkboxon(UseCooldowns) spell(berserk)
  }
 }
}

AddFunction feralprecombatcdpostconditions
{
 hastalent(bloodtalons_talent) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or spell(cat_form)
}
AddCheckBox(UseCooldowns L(Cooldowns))

]]
		OvaleScripts:RegisterScript("DRUID", "feral", name, desc, code, "script")
	end
end
