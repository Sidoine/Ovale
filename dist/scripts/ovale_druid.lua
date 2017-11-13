local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "icyveins_druid_guardian"
    local desc = "[7.1.5] Icy-Veins: Druid Guardian"
    local code = [[

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=guardian)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=guardian)
AddCheckBox(opt_druid_guardian_aoe L(AOE) default specialization=guardian)

AddFunction GuardianHealMe
{
	if IncomingDamage(5) >= MaxHealth() * 0.5 Spell(frenzied_regeneration)
	if ((IncomingDamage(5) / 2 <= HealthMissing()) and (IncomingDamage(5) / 2 > MaxHealth() * 0.1) and SpellCharges(frenzied_regeneration) >= 2) Spell(frenzied_regeneration)
	if HealthPercent() <= 50 Spell(lunar_beam)
	if HealthPercent() <= 50 and IncomingDamage(5 physical=1) == 0 Spell(regrowth)
	if HealthPercent() <= 80 and not InCombat() Spell(regrowth)
}

AddFunction GuardianGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred)
	{
		if target.InRange(wild_charge) Spell(wild_charge)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction GuardianDefaultShortCDActions
{
	GuardianHealMe()
	if InCombat() and BuffExpires(bristling_fur_buff)
	{
		if IncomingDamage(5 physical=1) Spell(ironfur)
	}
	if BuffExpires(survival_instincts_buff) and BuffExpires(rage_of_the_sleeper_buff) and BuffExpires(barkskin_buff) Spell(bristling_fur)
	# range check
	GuardianGetInMeleeRange()
}

#
# Single-Target
#

AddFunction GuardianDefaultMainActions
{
	if not Stance(druid_bear_form) Spell(bear_form)
	if not BuffExpires(galactic_guardian_buff) Spell(moonfire)
	Spell(mangle)
	Spell(thrash_bear)
	if target.DebuffStacks(thrash_bear_debuff) >= 2 Spell(pulverize)
	if target.DebuffRefreshable(moonfire_debuff) Spell(moonfire)
	if RageDeficit() <= 20 Spell(maul)
	Spell(swipe_bear)
}

#
# AOE
#

AddFunction GuardianDefaultAoEActions
{
	if not Stance(druid_bear_form) Spell(bear_form)
	if Enemies() >= 4 and HealthPercent() <= 80 Spell(lunar_beam)
	if not BuffExpires(galactic_guardian_buff) Spell(moonfire)
	Spell(thrash_bear)
	Spell(mangle)
	if target.DebuffStacks(thrash_bear_debuff) >= 2 Spell(pulverize)
	if Enemies() <= 3 and target.DebuffRefreshable(moonfire_debuff) Spell(moonfire)
	if RageDeficit() <= 20 Spell(maul)
	Spell(swipe_bear)
}

AddFunction GuardianDefaultCdActions 
{
	GuardianInterruptActions()
	Spell(incarnation_guardian_of_ursoc)
	if HasArtifactTrait(embrace_of_the_nightmare) Spell(rage_of_the_sleeper)
	if BuffExpires(bristling_fur_buff) and BuffExpires(survival_instincts_buff) and BuffExpires(rage_of_the_sleeper_buff) and BuffExpires(barkskin_buff) and BuffExpires(potion_buff)
	{
		if (HasEquippedItem(shifting_cosmic_sliver)) Spell(survival_instincts)
		Item(Trinket0Slot usable=1 text=13)
		Item(Trinket1Slot usable=1 text=14)
		Spell(barkskin)
		Spell(rage_of_the_sleeper)
		Spell(survival_instincts)
		Item(unbending_potion usable=1)
	}
}

AddFunction GuardianInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
	{
		if target.InRange(skull_bash) and target.IsInterruptible() Spell(skull_bash)
		if not target.Classification(worldboss)
		{
			Spell(mighty_bash)
			if target.Distance(less 10) Spell(incapacitating_roar)
			if target.Distance(less 8) Spell(war_stomp)
			if target.Distance(less 15) Spell(typhoon)
		}
	}
}

AddIcon help=shortcd specialization=guardian
{
	GuardianDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=guardian
{
	GuardianDefaultMainActions()
}

AddIcon checkbox=opt_druid_guardian_aoe help=aoe specialization=guardian
{
	GuardianDefaultAoEActions()
}

AddIcon help=cd specialization=guardian
{
	GuardianDefaultCdActions()
}
	
]]
    OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
end
do
    local name = "shmoodude_druid_feral"
    local desc = "[7.3.5] ShmooDude: Druid Feral"
    local code = [[# ShmooDude Feral and Guardian script
    ###
    ### Options:
    # Interrupt - Suggests use of interuptting abilities, including stuns/knockbacks on non-boss targets.
    #
    #
    # Not in Melee Range - Suggests movement abilities if available or a forward arrow if you're out of range.
    #
    #
    # Multiple-targets rotation - If this is disabled, the AoE icon is removed
    #
    #
    # Ashamane's Frenzy as main action - Puts the Ashamane's Frenzy suggestion in the main action box.
    #       Requires TimeToDie of 20 seconds or more
    #       If this is off, Ovale will suggest 2 CP Regrowths in the Short CD box.
    # Shadowmeld as main action - Puts the Shadowmeld suggestion in the main action box.
    #       Requires TimeToDie of 20 seconds or more
    #       Suggested off except on (raid) bosses.
    # Tiger's Fury multiplier prediction - Applies the Tiger's Fury multiplier if Tiger's Fury is ready.
    #       e.g. If TF is being suggested, any Rip suggestions will assume you use TF first.
    #
    # Prevent capping BrS charges - Will suggest Brutal Slash if you are about to reach max charges.
    #       Advantage: Helps not waste charges.  
    #       Disadvantage: Will probably not have 3 charges when AoE for the encounter shows up.
    # BrS at X targets - Minimum number of targets to suggest using Brutal Slash.
    #       This will use all available Brutal Slash charges.
    #       
    # Only suggest BrS when TF is up
    #       Good for Mythic+ to get the most out of your Brutal Slash charges
    #       Too much haste makes this sub-optimal
    # Rip - At how many seconds to overwrite a Rip
    #       Default Pandemic
    #
    # Rake - At how many seconds to overwrite a Rake
    #       Default 7 or
    #               Pandemic with Ailuro Pouncers Legendary or you are not speced into Bloodtalons
    # Savage Roar - At how many seconds to overwrite Savage Roar
    #       Default Pandemic
    #
    
    Include(ovale_common)
    Include(ovale_trinkets_mop)
    Include(ovale_trinkets_wod)
    Include(ovale_druid_spells)
    
    AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=feral)
    AddCheckBox(opt_use_consumables "Suggest Prolonged Power Potion" default specialization=feral)
    AddCheckBox(opt_interrupt L(interrupt) default specialization=feral)
    
    AddCheckBox(opt_ashamanes_frenzy_main_action "Ashamane's Frenzy as a main action" default specialization=feral)
    AddCheckBox(opt_shadowmeld_main_action "Shadowmeld as a main action" specialization=feral)
    
    AddCheckBox(opt_tigers_fury_multiplier_predict "Tiger's Fury multiplier prediction" default specialization=feral)
    AddCheckBox(opt_brutal_slash_use_at_three_always "Prevent capping BrS charges" specialization=feral)
    AddCheckBox(opt_brutal_slash_use_with_tigers_fury "Only suggest BrS when TF is up" specialization=feral)
    # AddCheckBox(opt_sync_af_tf "Try to sync Ashamane's with TF" specialization=feral)
    
    AddListItem(opt_10_rake_refresh rake_00_default "Rake: Default (7 w/ BT)" specialization=feral default)
    AddListItem(opt_10_rake_refresh rake_01_pandemic "Rake at Pandemic (duration*0.3)" specialization=feral)
    AddListItem(opt_10_rake_refresh rake_05 "Rake at 5 seconds" specialization=feral)
    AddListItem(opt_10_rake_refresh rake_06 "Rake at 6 seconds" specialization=feral)
    AddListItem(opt_10_rake_refresh rake_07 "Rake at 7 seconds" specialization=feral)
    AddListItem(opt_10_rake_refresh rake_08 "Rake at 8 seconds" specialization=feral)
    AddListItem(opt_10_rake_refresh rake_09 "Rake at 9 seconds" specialization=feral)
    
    AddListItem(opt_11_rip_refresh rip_00_default "Rip: Default (Pandemic)" specialization=feral default)
    AddListItem(opt_11_rip_refresh rip_01_pandemic "Rip at Pandemic (duration*0.3)" specialization=feral)
    AddListItem(opt_11_rip_refresh rip_07 "Rip at 7 seconds" specialization=feral)
    AddListItem(opt_11_rip_refresh rip_08 "Rip at 8 seconds" specialization=feral)
    AddListItem(opt_11_rip_refresh rip_09 "Rip at 9 seconds" specialization=feral)
    AddListItem(opt_11_rip_refresh rip_10 "Rip at 10 seconds" specialization=feral)
    AddListItem(opt_11_rip_refresh rip_11 "Rip at 11 seconds" specialization=feral)
    
    AddListItem(opt_12_savage_roar_refresh savage_roar_00_default "Savage Roar: Default (Pandemic)" specialization=feral default)
    AddListItem(opt_12_savage_roar_refresh savage_roar_01_pandemic "Savage Roar Pandemic (duration*0.3)" specialization=feral)
    AddListItem(opt_12_savage_roar_refresh savage_roar_12 "Savage Roar at 12 seconds" specialization=feral)
    AddListItem(opt_12_savage_roar_refresh savage_roar_13 "Savage Roar at 13 seconds" specialization=feral)
    AddListItem(opt_12_savage_roar_refresh savage_roar_14 "Savage Roar at 14 seconds" specialization=feral)
    AddListItem(opt_12_savage_roar_refresh savage_roar_15 "Savage Roar at 15 seconds" specialization=feral)
    AddListItem(opt_12_savage_roar_refresh savage_roar_16 "Savage Roar at 16 seconds" specialization=feral)
    
    AddListItem(opt_09_desired_targets desired_targets_01 "BrS at 1 target" specialization=feral)
    AddListItem(opt_09_desired_targets desired_targets_02 "BrS at 2 targets" specialization=feral)
    AddListItem(opt_09_desired_targets desired_targets_03 "BrS at 3 targets" specialization=feral default)
    AddListItem(opt_09_desired_targets desired_targets_04 "BrS at 4 targets" specialization=feral)
    AddListItem(opt_09_desired_targets desired_targets_05 "BrS at 5 targets" specialization=feral)
    AddListItem(opt_09_desired_targets desired_targets_06 "BrS at 6 targets" specialization=feral)
    AddListItem(opt_09_desired_targets desired_targets_07 "BrS at 7 targets" specialization=feral)
    AddListItem(opt_09_desired_targets desired_targets_08 "BrS at 8 targets" specialization=feral)
    AddListItem(opt_09_desired_targets desired_targets_09 "BrS at 9 targets" specialization=feral)
    
    
    
    ########################################
    ### Helper Variables (Functions)     ###
    ########################################
    
    #variable,name=rake_refresh,value=4.5
    #variable,name=rake_refresh,op=mul,value=0.8,if=talent.jagged_wounds.enabled
    #variable,name=rake_refresh,value=7,if=talent.bloodtalons.enabled&!equipped.ailuro_pouncers
    AddFunction rake_refresh
    {
        unless List(opt_10_rake_refresh rake_00_default)
        {
            if List(opt_10_rake_refresh rake_01_pandemic) target.DebuffDuration(rake_debuff) * 0.3
            if List(opt_10_rake_refresh rake_05) 5
            if List(opt_10_rake_refresh rake_06) 6
            if List(opt_10_rake_refresh rake_07) 7
            if List(opt_10_rake_refresh rake_08) 8
            if List(opt_10_rake_refresh rake_09) 9
        }
        if HasEquippedItem(ailuro_pouncers) or not Talent(bloodtalons_talent) target.DebuffDuration(rake_debuff) * 0.3
        7
    }
    
    #variable,name=savage_roar_refresh,value=10.8
    AddFunction savage_roar_refresh
    {
        unless List(opt_12_savage_roar_refresh savage_roar_00_default)
        {
            if List(opt_12_savage_roar_refresh savage_roar_01_pandemic) BaseDuration(savage_roar_buff) * 0.3
            if List(opt_12_savage_roar_refresh savage_roar_12) 12
            if List(opt_12_savage_roar_refresh savage_roar_13) 13
            if List(opt_12_savage_roar_refresh savage_roar_14) 14
            if List(opt_12_savage_roar_refresh savage_roar_15) 15
            if List(opt_12_savage_roar_refresh savage_roar_16) 16
        }
        BaseDuration(savage_roar_buff) * 0.3
    }
    
    #variable,name=rip_refresh,value=7.2
    #variable,name=rip_refresh,op=add,value=1.2,if=set_bonus.tier20_4pc
    #variable,name=rip_refresh,op=mul,value=0.8,if=talent.jagged_wounds.enabled
    AddFunction rip_refresh
    {
        unless List(opt_11_rip_refresh rip_00_default)
        {
            if List(opt_11_rip_refresh rip_01_pandemic) target.DebuffDuration(rip_debuff) * 0.3
            if List(opt_11_rip_refresh rip_07) 7
            if List(opt_11_rip_refresh rip_08) 8
            if List(opt_11_rip_refresh rip_09) 9
            if List(opt_11_rip_refresh rip_10) 10
            if List(opt_11_rip_refresh rip_11) 11
        }
        target.DebuffDuration(rip_debuff) * 0.3
    }
    
    #variable,name=execute_range,value=25
    #variable,name=execute_range,value=100,if=talent.sabertooth.enabled
    AddFunction execute_range
    {
        if Talent(sabertooth_talent) 100
        25
    }
    
    #variable,name=use_thrash,value=0
    #variable,name=use_thrash,value=1,if=equipped.luffa_wrappings
    AddFunction use_thrash
    {
        if HasEquippedItem(luffa_wrappings) 1
        0
    }
    
    #variable,name=bt_stack,value=2
    #variable,name=bt_stack,value=1,if=equipped.ailuro_pouncers
    AddFunction bt_stack
    {
        if HasEquippedItem(ailuro_pouncers) 1
        2
    }
    
    #desired_targets
    AddFunction BrutalSlashDesiredTargets asvalue=1
    {
        if List(opt_09_desired_targets desired_targets_02) 2
        if List(opt_09_desired_targets desired_targets_03) 3
        if List(opt_09_desired_targets desired_targets_04) 4
        if List(opt_09_desired_targets desired_targets_05) 5
        if List(opt_09_desired_targets desired_targets_06) 6
        if List(opt_09_desired_targets desired_targets_07) 7
        if List(opt_09_desired_targets desired_targets_08) 8
        if List(opt_09_desired_targets desired_targets_09) 9
    }
    
    #trinket
    AddFunction FeralUseItemActions
    {
        Item(Trinket0Slot text=13 usable=1)
        Item(Trinket1Slot text=14 usable=1)
    }
    
    #melee_range
    AddFunction FeralGetInMeleeRange
    {
        if CheckBoxOn(opt_melee_range) and target.InRange(shred no)
        {
            #wild_charge
            if target.InRange(wild_charge) Spell(wild_charge)
            #displacer_beast,if=movement.distance>25
            if target.distance() > 25 Spell(displacer_beast)
            #dash,if=movement.distance>25&buff.displacer_beast.down&buff.wild_charge_movement.down
            if target.distance() > 25 and BuffExpires(displacer_beast_buff) Spell(dash)
            Texture(misc_arrowlup help=L(not_in_melee_range))
        }
    }
    
    #interrupt
    AddFunction FeralInterruptActions
    {
        if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
        {
            if target.InRange(skull_bash) Spell(skull_bash)
            if not target.Classification(worldboss)
            {
                if target.InRange(mighty_bash) Spell(mighty_bash)
                if target.distance() < 20 Spell(typhoon)
                if target.InRange(maim) Spell(maim)
                if target.distance() < 8 Spell(war_stomp)
            }
        }
    }
    
    #Tiger's Fury multiplier prediction 
    AddFunction TFMultPred asvalue=1
    {
        if CheckBoxOn(opt_tigers_fury_multiplier_predict) 
            and BuffExpires(tigers_fury_buff)
            and SpellCooldown(tigers_fury) <= 0
            and ShortCd_TigersFury() 1.15
        1
    }
    
    
    
    ########################################
    ### Main Action List                 ###
    ########################################
    
    #rake,if=buff.prowl.up|buff.shadowmeld.up
    AddFunction Main_Rake_Prowl
    {
        BuffPresent(prowl_buff) 
            or BuffPresent(shadowmeld_buff)
    }
    
    #dash,if=buff.cat_form.down
    #AddFunction Main_Dash_CatForm #### Unused
    #{
    #   BuffExpires(cat_form_buff)
    #}
    
    #cat_form,if=buff.cat_form.down
    #AddFunction Main_CatForm #### Unused
    #{
    #   BuffExpires(cat_form_buff)
    #}
    
    
    #######call_action_list,name=opener,if=!dot.rip.ticking&time<8
    # MODIFICATION: Add target.Classification(worldboss)
    # REASON: Only use opener on bosses.
    AddFunction Main_Opener_Conditions
    {
        target.DebuffExpires(rip_debuff) 
            and TimeInCombat() < 8
            and target.Classification(worldboss)
    }
    
    
    #######call_action_list,name=cooldowns
    #AddFunction Main_Cooldowns_Conditions #### Unused
    #{
    #
    #}
    
    #tigers_fury,if=energy.deficit>=60
    AddFunction ShortCd_TigersFury
    {
        EnergyDeficit() >= 60
    }
    
    # MODIFICATION: Predator TF
    # REASON: Suggest TF anytime its ready if TF is already up to maximize buff uptime.
    AddFunction ShortCd_TigersFury_Predator
    {
        UnitInRaid() 
            and Talent(predator_talent) 
            and BuffPresent(tigers_fury_buff)
    }
    
    #berserk,if=energy>=30&(cooldown.tigers_fury.remains>5|buff.tigers_fury.up)
    # MODIFICATION: SpellCooldown(tigers_fury) <= 0 and ShortCd_TigersFury()
    # REASON: Make Berserk show up if Tiger's Fury conditions are met
    AddFunction Cd_Berserk
    {
        Energy() >= 30 
            and { SpellCooldown(tigers_fury) > 5 
                or BuffPresent(tigers_fury_buff) or TFMultPred() > 1 }
    }
    
    #incarnation,if=energy>=30&(cooldown.tigers_fury.remains>15|buff.tigers_fury.up)
    # MODIFICATION: SpellCooldown(tigers_fury) <= 0 and ShortCd_TigersFury()
    # REASON: Make Incarnation show up if Tiger's Fury conditions are met
    AddFunction Cd_Incarnation
    {
        Energy() >= 30 
            and { SpellCooldown(tigers_fury) > 15 
                or BuffPresent(tigers_fury_buff) or TFMultPred() > 1 }
    }
    
    #elunes_guidance,if=combo_points=0&energy>=50
    AddFunction ShortCd_ElunesGuidance
    {
        ComboPoints() == 0 
            and Energy() >= 50
    }
    
    #potion,name=prolonged_power,if=target.time_to_die<65|(time_to_die<180&(buff.berserk.up|buff.incarnation.up))
    AddFunction Cd_Potion
    {
        { target.TimeToDie() < 65 
                or target.TimeToDie() < 180 
                    and { BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) } } 
            and CheckBoxOn(opt_use_consumables) 
            and target.Classification(worldboss)
    }
    
    #ashamanes_frenzy,if=combo_points<=2&(!talent.bloodtalons.enabled|buff.bloodtalons.up)
    # MODIFICATION: AshamanesFrenzy_Main for CheckBoxOn(opt_ashamanes_frenzy_main_action)
    # REASON: Allows player to choose via checkbox whether to add Azshamane's Frenzy to the Main Icon
    # MODIFICATION: target.TimeToDie() > 20
    # REASON: Does not use Regrowth for Ashamane's Frenzy on targets with less than 20 seconds to live
    AddFunction Cooldowns_AshamanesFrenzy
    {
        CheckBoxOn(opt_ashamanes_frenzy_main_action)
            and ComboPoints() <= 2 
            and { not Talent(bloodtalons_talent) or BuffPresent(bloodtalons_buff) }
            and target.TimeToDie() > 20
    }
    
    # MODIFICATION: ShortCd_AshamanesFrenzy for CheckBoxOff(opt_ashamanes_frenzy_main_action)
    # REASON: Allows player to choose via checkbox whether to add Azshamane's Frenzy to the Main Icon
    AddFunction ShortCd_AshamanesFrenzy
    {
        CheckBoxOff(opt_ashamanes_frenzy_main_action)
            and ComboPoints() <= 2 
            and { not Talent(bloodtalons_talent) or BuffPresent(bloodtalons_buff) }
    }
    
    #shadowmeld,if=combo_points<5&energy>=action.rake.cost&dot.rake.pmultiplier<2.1&buff.tigers_fury.up&(!talent.bloodtalons.enabled|buff.bloodtalons.up)&(!talent.incarnation.enabled|cooldown.incarnation.remains>18)&!buff.incarnation.up
    # MODIFICATION: Cooldowns_Shadowmeld for CheckBoxOn(opt_shadowmeld_main_action)
    # REASON: Allows player to choose via checkbox whether to add Shadowmeld to the Main Icon
    # MODIFICATION: target.TimeToDie() > BaseDuration(rake_debuff) + 5
    # REASON: Does not use Shadowmeld on targets with less than BaseDuration(rake_debuff) + 5 seconds to live
    # MODIFICATION: target.InRange(rake)
    # REASON: Cannot move after Shadowmeld so add range check before suggesting
    AddFunction Cooldowns_Shadowmeld
    {
        CheckBoxOn(opt_shadowmeld_main_action)
            and ComboPoints() < 5 
            and Energy() >= PowerCost(rake) 
            and target.DebuffPersistentMultiplier(rake_debuff) < 2.1 
            and { BuffPresent(tigers_fury_buff) or TFMultPred() > 1 }
            and { not Talent(bloodtalons_talent) or BuffPresent(bloodtalons_buff) } 
            and { not Talent(incarnation_talent) or SpellCooldown(incarnation_king_of_the_jungle) > 18 } 
            and BuffExpires(incarnation_king_of_the_jungle_buff)
            and target.TimeToDie() > BaseDuration(rake_debuff) + 5
            and target.InRange(rake)
    }
    
    # MODIFICATION: Cd_Shadowmeld for CheckBoxOff(opt_shadowmeld_main_action)
    # REASON: Allows player to choose via checkbox whether to add Shadowmeld to the Main Icon
    AddFunction Cd_Shadowmeld
    {
        CheckBoxOff(opt_shadowmeld_main_action) 
            and ComboPoints() < 5 
            and Energy() >= PowerCost(rake) 
            and target.DebuffPersistentMultiplier(rake_debuff) < 2.1 
            and { BuffPresent(tigers_fury_buff) or TFMultPred() > 1 }
            and { not Talent(bloodtalons_talent) or BuffPresent(bloodtalons_buff) } 
            and { not Talent(incarnation_talent) or SpellCooldown(incarnation_king_of_the_jungle) > 18 } 
            and BuffExpires(incarnation_king_of_the_jungle_buff)
            and target.TimeToDie() > BaseDuration(rake_debuff) + 5
            and target.InRange(rake)
    }
    
    #use_items
    #AddFunction Cooldowns_Trinket #### Unused
    #{
    #
    #}
    
    
    #regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.stack<variable.bt_stack&(buff.predatory_swiftness.remains<1.5|(combo_points=5&(!buff.incarnation.up|dot.rip.remains<8|dot.rake.remains<5)))
    AddFunction Main_Regrowth_Expires_or_5CP
    {
        Talent(bloodtalons_talent) 
            and BuffPresent(predatory_swiftness_buff) 
            and BuffStacks(bloodtalons_buff) < bt_stack() 
            and { BuffRemaining(predatory_swiftness_buff) < 1.5 
                or ComboPoints() == 5 
                    and { BuffExpires(incarnation_king_of_the_jungle_buff) 
                        or target.DebuffRemaining(rip_debuff) < 8 
                        or target.DebuffRemaining(rake_debuff) < 5 } }
    }
    
    #ferocious_bite,cycle_targets=1,if=dot.rip.ticking&dot.rip.remains<3&target.time_to_die>10&target.health.pct<variable.execute_range
    AddFunction Main_FerociousBite_3SecondRefresh
    {
        target.DebuffPresent(rip_debuff) 
            and target.DebuffRemaining(rip_debuff) < 3 
            and target.TimeToDie() > 10 
            and target.HealthPercent() < execute_range()
    }
    
    
    #######run_action_list,name=finishers,if=combo_points>4
    AddFunction Main_Finishers_Conditions
    {
        ComboPoints() > 4
    }
    
    #savage_roar,if=buff.savage_roar.down
    AddFunction Finishers_SavageRoarExpires
    {
        BuffExpires(savage_roar_buff)
    }
    
    #rip,target_if=(!ticking|remains<=variable.rip_refresh&target.health.pct>variable.execute_range|(remains<=duration*0.8&persistent_multiplier>dot.rip.pmultiplier))&target.time_to_die>6+2*active_enemies+remains
    # MODIFICATION: TFMultPred when CheckBoxOn(opt_tigers_fury_multiplier_predict)
    # REASON: When Tiger's Fury is suggested, treat Rip as if it is already up even if it hasn't been cast yet.
    AddFunction Finishers_Rip
    {
        { target.DebuffExpires(rip_debuff) 
                or target.DebuffRemaining(rip_debuff) <= rip_refresh() 
                    and target.HealthPercent() > execute_range() 
                or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 
                    and TFMultPred() * PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) } 
            and target.TimeToDie() > 6 + 2 * Enemies() + target.DebuffRemaining(rip_debuff)
    }
    
    #savage_roar,if=buff.savage_roar.remains<variable.savage_roar_refresh
    AddFunction Finishers_SavageRoarRefresh
    {
        BuffRemaining(savage_roar_buff) < savage_roar_refresh()
    }
    
    #maim,if=buff.fiery_red_maimers.up
    AddFunction Finishers_Maimers
    {
        BuffPresent(fiery_red_maimers_buff)
    }
    
    #regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&((combo_points=2&&cooldown.ashamanes_frenzy.remains<gcd)|(combo_points=4&dot.rake.remains<4))
    # MODIFICATION: CheckBoxOn(opt_ashamanes_frenzy_main_action) in Main_Regrowth_AshamanesFrenzy
    # REASON: Allows player to choose via checkbox whether to add Ashamane's Frenzy to the Main Icon
    # MODIFICATION: target.TimeToDie() > 21
    # REASON: Does not use Regrowth for Ashamane's Frenzy on targets with less than 21 seconds to live
    AddFunction Main_Regrowth_AshamanesFrenzy
    {
        CheckBoxOn(opt_ashamanes_frenzy_main_action) 
            and Talent(bloodtalons_talent) 
            and BuffPresent(predatory_swiftness_buff) 
            and BuffExpires(bloodtalons_buff) 
            and ComboPoints() == 2 
            and SpellCooldown(ashamanes_frenzy) < 0.75 
            and target.TimeToDie() > 21
    }
    
    # MODIFICATION: ShortCd_Regrowth_AshamanesFrenzy for CheckBoxOff(opt_ashamanes_frenzy_main_action)
    # REASON: Allows player to choose via checkbox whether to add Ashamane's Frenzy to the Main Icon
    AddFunction ShortCd_Regrowth_AshamanesFrenzy
    {
        CheckBoxOff(opt_ashamanes_frenzy_main_action) 
            and Talent(bloodtalons_talent) 
            and BuffPresent(predatory_swiftness_buff) 
            and BuffExpires(bloodtalons_buff) 
            and ComboPoints() == 2 
            and SpellCooldown(ashamanes_frenzy) < 0.75 
    }
    
    #regrowth,if=equipped.ailuro_pouncers&talent.bloodtalons.enabled&buff.bloodtalons.down&(buff.predatory_swiftness.stack>2|(buff.predatory_swiftness.stack>1&dot.rake.remains<3))
    AddFunction Main_Regrowth_Pouncers
    {
        HasEquippedItem(ailuro_pouncers) 
            and Talent(bloodtalons_talent) 
            and BuffExpires(bloodtalons_buff) 
            and { BuffStacks(predatory_swiftness_buff) > 2 
                or BuffStacks(predatory_swiftness_buff) > 1 and target.DebuffRemaining(rake_debuff) < 3 }
    }
    
    
    #######run_action_list,name=generators
    #AddFunction Main_Generators_Conditions
    #{
    #
    #}
    
    #brutal_slash,if=spell_targets.brutal_slash>desired_targets
    AddFunction Generators_BrutalSlash_DesiredTargets
    {
        Enemies() >= BrutalSlashDesiredTargets()
            and { BuffPresent(tigers_fury_buff) or TFMultPred() > 1 or CheckBoxOff(opt_brutal_slash_use_with_tigers_fury) }
    }
    
    #pool_resource,for_next=1
    #thrash_cat,if=refreshable&spell_targets.thrash_cat>2
    AddFunction Generators_ThrashCat_3Targets
    {
        target.Refreshable(thrash_cat_debuff) 
            and Enemies() > 2
    }
    
    #rake,target_if=(!ticking|(!talent.bloodtalons.enabled|buff.bloodtalons.up)&remains<=variable.rake_refresh&persistent_multiplier>dot.rake.pmultiplier*0.85)&target.time_to_die>6+remains
    AddFunction Generators_Rake
    {
        { not target.DebuffPresent(rake_debuff) 
                or { not Talent(bloodtalons_talent) or BuffPresent(bloodtalons_buff) } 
                    and target.DebuffRemaining(rake_debuff) <= rake_refresh() 
                    and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.85 } 
            and target.TimeToDie() > 6 + target.DebuffRemaining(rake_debuff)
    }
    
    #brutal_slash,if=(buff.tigers_fury.up&(raid_event.adds.in>(1+max_charges-charges_fractional)*recharge_time))
    AddFunction Generators_BrutalSlash_3Charges
    {
        CheckBoxOn(opt_brutal_slash_use_at_three_always)
            and Charges(brutal_slash count=0) > 2.66 
    }
    
    #moonfire_cat,target_if=refreshable&target.time_to_die>4+remains
    AddFunction Generators_MoonfireCat
    {
        target.Refreshable(moonfire_cat_debuff) 
            and target.TimeToDie() > 4 + target.DebuffRemaining(moonfire_cat_debuff)
    }
    
    #pool_resource,for_next=1
    #thrash_cat,if=refreshable&(variable.use_thrash=1|spell_targets.thrash_cat>1)
    AddFunction Generators_ThrashCat_Luffa_or_2Targets
    {
        target.Refreshable(thrash_cat_debuff) 
            and { use_thrash() == 1 or Enemies() > 1 }
    }
    
    #pool_resource,for_next=1
    #swipe_cat,if=spell_targets.swipe_cat>1
    AddFunction Generators_SwipeCat
    {
        Enemies() > 1
    }
    
    #shred,if=dot.rake.remains>(action.shred.cost+action.rake.cost-energy)%energy.regen|buff.clearcasting.react
    # MODIFICATION: or target.TimeToDie() <= 6 + target.DebuffRemaining(rake_debuff)
    # REASON: To make shred show up if Rake is not on a target about to die.
    AddFunction Generators_Shred
    {
        target.DebuffRemaining(rake_debuff) > { PowerCost(shred) + PowerCost(rake) - Energy() } / EnergyRegenRate() 
            or BuffPresent(clearcasting_buff)
            or target.TimeToDie() <= 6 + target.DebuffRemaining(rake_debuff)
    }
    
    
    ### actions.default
    
    AddFunction FeralDefaultMainActions
    {
        #rake,if=buff.prowl.up|buff.shadowmeld.up
        if Main_Rake_Prowl() Spell(rake)
        
        #dash,if=buff.cat_form.down
        if BuffExpires(cat_form_buff) Spell(dash)
        
        #cat_form,if=buff.cat_form.down
        if BuffExpires(cat_form_buff) Spell(cat_form)
        
        #call_action_list,name=opener,if=!dot.rip.ticking&time<8
        if Main_Opener_Conditions() FeralOpenerMainActions()
        
        #call_action_list,name=cooldowns
        FeralCooldownsMainActions()
        
        #regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.stack<variable.bt_stack&(buff.predatory_swiftness.remains<1.5|(combo_points=5&(!buff.incarnation.up|dot.rip.remains<8|dot.rake.remains<5)))
        if Main_Regrowth_Expires_or_5CP() Spell(regrowth)
        
        #ferocious_bite,cycle_targets=1,if=dot.rip.ticking&dot.rip.remains<3&target.time_to_die>10&target.health.pct<variable.execute_range
        if Main_FerociousBite_3SecondRefresh() Spell(ferocious_bite text=Refresh)
        
        #run_action_list,name=finishers,if=combo_points>4
        if Main_Finishers_Conditions() FeralFinishersMainActions()
        unless Main_Finishers_Conditions()
        {
            #regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&((combo_points=2&&cooldown.ashamanes_frenzy.remains<gcd)|(combo_points=4&dot.rake.remains<4&buff.bloodtalons.down))
            # MODIFICATION: CheckBoxOn(opt_ashamanes_frenzy_main_action) in Main_Regrowth_AshamanesFrenzy
            # REASON: Allows player to choose via checkbox whether to add Ashamane's Frenzy to the Main Icon
            if Main_Regrowth_AshamanesFrenzy() Spell(regrowth text=AF)
    
            #regrowth,if=equipped.ailuro_pouncers&talent.bloodtalons.enabled&buff.bloodtalons.down&(buff.predatory_swiftness.stack>2|(buff.predatory_swiftness.stack>1&dot.rake.remains<3))
            if Main_Regrowth_Pouncers() Spell(regrowth text=Pouncers)
            
            #run_action_list,name=generators
            FeralGeneratorsMainActions()
        }
    }
    
    AddFunction FeralDefaultShortCdActions
    {
        unless Main_Rake_Prowl() and Spell(rake) or BuffExpires(cat_form_buff) and Spell(cat_form)
        {
            #auto_attack
            FeralGetInMeleeRange()
            
            #call_action_list,name=opener,if=!dot.rip.ticking&time<8
            #if Main_Opener_Conditions() FeralOpenerShortCdActions()
            unless Main_Opener_Conditions() and FeralOpenerShortCdPostConditions()
            {
                #call_action_list,name=cooldowns
                FeralCooldownsShortCdActions()
                
                unless Main_Finishers_Conditions()
                {
                    # MODIFICATION: ShortCd_Regrowth_AshamanesFrenzy for CheckBoxOff(opt_ashamanes_frenzy_main_action)
                    # REASON: Allows player to choose via checkbox whether to add Ashamane's Frenzy to the Main Icon
                    #regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&((combo_points=2&&cooldown.ashamanes_frenzy.remains<gcd)|(combo_points=4&dot.rake.remains<4&buff.bloodtalons.down))
                    if ShortCd_Regrowth_AshamanesFrenzy() Spell(regrowth text=AF)
                }
            }
        }
    }
    
    AddFunction FeralDefaultCdActions
    {
        unless Main_Rake_Prowl() and Spell(rake) or BuffExpires(cat_form_buff) and Spell(cat_form)
        {
            #skull_bash
            FeralInterruptActions()
            
            #call_action_list,name=opener,if=!dot.rip.ticking&time<8
            if Main_Opener_Conditions() FeralOpenerCdActions()
            unless Main_Opener_Conditions() and FeralOpenerCdPostConditions()
            {
                #call_action_list,name=cooldowns
                FeralCooldownsCdActions()
            }
        }
    }
    
    ### actions.cooldowns
    
    AddFunction FeralCooldownsMainActions
    {
        #ashamanes_frenzy,if=combo_points<=2&(!talent.bloodtalons.enabled|buff.bloodtalons.up)
        # MODIFICATION: Cooldowns_AshamanesFrenzy for CheckBoxOn(opt_ashamanes_frenzy_main_action)
        # REASON: Allows player to choose via checkbox whether to add Azshamane's Frenzy to the Main Icon
        if Cooldowns_AshamanesFrenzy() Spell(ashamanes_frenzy)
        
        #shadowmeld,if=combo_points<5&energy>=action.rake.cost&dot.rake.pmultiplier<2.1&buff.tigers_fury.up&(!talent.bloodtalons.enabled|buff.bloodtalons.up)&(!talent.incarnation.enabled|cooldown.incarnation.remains>18)&!buff.incarnation.up
        # MODIFICATION: Cooldowns_Shadowmeld for CheckBoxOn(opt_shadowmeld_main_action)
        # REASON: Allows player to choose via checkbox whether to add Shadowmeld to the Main Icon
        if Cooldowns_Shadowmeld() Spell(shadowmeld)
    }
    
    AddFunction FeralCooldownsShortCdActions
    {
        #elunes_guidance,if=combo_points=0&energy>=50
        if ShortCd_ElunesGuidance() Spell(elunes_guidance)
        
        # MODIFICATION: Show "+TF" text on AF if you should also cast TF
        # REASON: Instead of TF blocking AF suggestion.
        #ashamanes_frenzy,if=combo_points<=2&(!talent.bloodtalons.enabled|buff.bloodtalons.up)
        if ShortCd_AshamanesFrenzy() 
        {
            if SpellCooldown(tigers_fury) <= 0 and ShortCd_TigersFury() Spell(ashamanes_frenzy text="+TF")
            Spell(ashamanes_frenzy)
        }
        
        # MODIFICATION: Moved both tigers_fury to below ashamanes_frenzy
        # REASON: Instead show AF with "+TF" text.
        #tigers_fury,if=energy.deficit>=60
        if ShortCd_TigersFury() Spell(tigers_fury)
        
        # MODIFICATION: ShortCd_TigersFury_Predator
        # REASON: Spam Tiger's Fury with predator in raid to maximize raid uptime of versatility buff
        if ShortCd_TigersFury_Predator() Spell(tigers_fury text=Pred)
    }
    
    AddFunction FeralCooldownsCdActions
    {
        #berserk,if=energy>=30&(cooldown.tigers_fury.remains>5|buff.tigers_fury.up)
        # MODIFICATION: Display potion if it is time to use your DPS potion with your cooldowns
        # REASON: Potion won't show up till after Berserk is cast normally
        if Cd_Berserk() 
        {
            if Cd_Potion() and Item(prolonged_power_potion usable=1) Spell(berserk_cat text=potion)
            Spell(berserk_cat)
        }
        
        #incarnation,if=energy>=30&(cooldown.tigers_fury.remains>15|buff.tigers_fury.up)
        # MODIFICATION: Display potion if it is time to use your DPS potion with your cooldowns
        # REASON: Potion won't show up till after Incarnation is cast normally
        if Cd_Incarnation() 
        {
            if Cd_Potion() and Item(prolonged_power_potion usable=1) Spell(incarnation_king_of_the_jungle text=potion)
            Spell(incarnation_king_of_the_jungle)
        }
    
        unless ShortCd_ElunesGuidance() and Spell(elunes_guidance)
        {
            #potion,name=prolonged_power,if=target.time_to_die<65|(time_to_die<180&(buff.berserk.up|buff.incarnation.up))
            if Cd_Potion() Item(prolonged_power_potion usable=1)
    
            unless Cooldowns_AshamanesFrenzy() and Spell(ashamanes_frenzy)
            {
                #shadowmeld,if=combo_points<5&energy>=action.rake.cost&dot.rake.pmultiplier<2.1&buff.tigers_fury.up&(!talent.bloodtalons.enabled|buff.bloodtalons.up)&(!talent.incarnation.enabled|cooldown.incarnation.remains>18)&!buff.incarnation.up
                # MODIFICATION: Cd_Shadowmeld for CheckBoxOff(opt_shadowmeld_main_action)
                # REASON: Allows player to choose via checkbox whether to add Shadowmeld to the Main Icon
                if Cd_Shadowmeld() Spell(shadowmeld)
                
                #use_items
                FeralUseItemActions()
            }
        }
    }
    
    ### actions.finishers
    
    AddFunction FeralFinishersMainActions
    {
        #pool_resource,for_next=1
        #savage_roar,if=buff.savage_roar.down
        if Finishers_SavageRoarExpires() Spell(savage_roar)
        unless Finishers_SavageRoarExpires() and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar)
        {
            #pool_resource,for_next=1
            #rip,target_if=(!ticking|remains<=variable.rip_refresh&target.health.pct>variable.execute_range|(remains<=duration*0.8&persistent_multiplier>dot.rip.pmultiplier))&target.time_to_die>6+2*active_enemies+remains
            if Finishers_Rip() Spell(rip)
            unless Finishers_Rip() and SpellUsable(rip) and SpellCooldown(rip) < TimeToEnergyFor(rip)
            {
                #pool_resource,for_next=1
                #savage_roar,if=buff.savage_roar.remains<variable.savage_roar_refresh
                if Finishers_SavageRoarRefresh() Spell(savage_roar)
                unless Finishers_SavageRoarRefresh() and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar)
                {
                    #maim,if=buff.fiery_red_maimers.up
                    if Finishers_Maimers() Spell(maim)
                    
                    #ferocious_bite,max_energy=1
                    if Energy() >= EnergyCost(ferocious_bite max=1) Spell(ferocious_bite)
                }
            }
        }
    }
    
    ### actions.generators
    
    AddFunction FeralGeneratorsMainActions
    {
        #brutal_slash,if=spell_targets.brutal_slash>desired_targets
        if Generators_BrutalSlash_DesiredTargets() Spell(brutal_slash)
        
        #pool_resource,for_next=1
        #thrash_cat,if=refreshable&spell_targets.thrash_cat>2
        if Generators_ThrashCat_3Targets() Spell(thrash_cat)
        unless Generators_ThrashCat_3Targets() and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
        {
            #pool_resource,for_next=1
            #rake,target_if=(!ticking|(!talent.bloodtalons.enabled|buff.bloodtalons.up)&remains<=variable.rake_refresh&persistent_multiplier>dot.rake.pmultiplier*0.85)&target.time_to_die>6+remains
            if Generators_Rake() Spell(rake)
            unless Generators_Rake() and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake)
            {
                #brutal_slash,if=(buff.tigers_fury.up&(raid_event.adds.in>(1+max_charges-charges_fractional)*recharge_time))
                if Generators_BrutalSlash_3Charges() Spell(brutal_slash)
                
                #moonfire_cat,target_if=refreshable&target.time_to_die>4+remains
                if Generators_MoonfireCat() Spell(moonfire_cat)
                
                #pool_resource,for_next=1
                #thrash_cat,if=refreshable&(variable.use_thrash=1|spell_targets.thrash_cat>1)
                if Generators_ThrashCat_Luffa_or_2Targets() Spell(thrash_cat)
                unless Generators_ThrashCat_Luffa_or_2Targets() and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
                {
                    #pool_resource,for_next=1
                    #swipe_cat,if=spell_targets.swipe_cat>1
                    if Generators_SwipeCat() Spell(swipe_cat)
                    unless Generators_SwipeCat() and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat)
                    {
                        #shred,if=dot.rake.remains>(action.shred.cost+action.rake.cost-energy)%energy.regen|buff.clearcasting.react
                        if Generators_Shred() Spell(shred)
                    }
                }
            }
        }
    }
    
    ### actions.opener
    
    AddFunction FeralOpenerMainActions
    {
        #moonfire_cat,if=talent.lunar_inspiration.enabled&!ticking
        if Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) Spell(moonfire_cat)
        
        #savage_roar,if=buff.savage_roar.down
        if BuffExpires(savage_roar_buff) Spell(savage_roar)
        
        #regrowth,if=talent.sabertooth.enabled&talent.bloodtalons.enabled&buff.bloodtalons.down&combo_points=5
        if Talent(sabertooth_talent) and Talent(bloodtalons_talent) and BuffExpires(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() == 5 Spell(regrowth text=hardcast)
    }
    
    AddFunction FeralOpenerShortCdActions
    {
        unless Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) 
            or Finishers_SavageRoarExpires() and Spell(savage_roar)
        {
            # MODIFICATION: Remove TF display from the opener
            # REASON: Shows AF instead.
            #tigers_fury,if=buff.savage_roar.up
            #if BuffPresent(savage_roar_buff) Spell(tigers_fury)
        }
    }
    
    AddFunction FeralOpenerShortCdPostConditions
    {
        Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) 
            or Finishers_SavageRoarExpires() and Spell(savage_roar) 
            or Talent(sabertooth_talent) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and ComboPoints() == 5 and Spell(regrowth)
    }
    
    AddFunction FeralOpenerCdActions
    {
        unless Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) 
            or Finishers_SavageRoarExpires() and Spell(savage_roar)
        {
            # MODIFICATION: if BuffPresent(savage_roar_buff)
            # REASON: Make Berserk/Incarnation show up for the opener
            #berserk,if=buff.savage_roar.up
            if BuffPresent(savage_roar_buff) Spell(berserk_cat text="+TF")
            
            #incarnation,if=buff.savage_roar.up
            if BuffPresent(savage_roar_buff) Spell(incarnation_king_of_the_jungle text="+TF")
        }
    }
    
    AddFunction FeralOpenerCdPostConditions
    {
        Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) 
            or Finishers_SavageRoarExpires() and Spell(savage_roar) 
            or Talent(sabertooth_talent) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and ComboPoints() == 5 and Spell(regrowth)
    }
    
    ### actions.precombat
    
    AddFunction FeralPrecombatMainActions
    {
        #flask
        #food
        #augmentation
    
        #regrowth,if=talent.bloodtalons.enabled
        # MODIFICATION: Talent(bloodtalons_talent) to Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 15 and BuffExpires(prowl_buff)
        # REASON: Only suggest Regrowth out of stealth and if there's <15 seconds remaining
        if Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 15 and BuffExpires(prowl_buff) Spell(regrowth)
        
        #cat_form
        Spell(cat_form)
        
        #savage_roar
        if BuffRefreshable(savage_roar_buff) Spell(savage_roar)
    }
    
    AddFunction FeralPrecombatMainPostConditions
    {
    }
    
    AddFunction FeralPrecombatShortCdActions
    {
        # MODIFICATION: Talent(bloodtalons_talent) to Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 15 and BuffExpires(prowl_buff)
        # REASON: Only suggest Regrowth out of stealth and if there's <15 seconds remaining
        # MODIFICATION: Remove "or Spell(cat_form)"
        # REASON: Blocks Prowl from showing up
        unless Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 15 and BuffExpires(prowl_buff) and Spell(regrowth)
        {
            #prowl
            Spell(prowl)
        }
    }
    
    AddFunction FeralPrecombatShortCdPostConditions
    {
        # MODIFICATION: Talent(bloodtalons_talent) to Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 15 and BuffExpires(prowl_buff)
        # REASON: Only suggest Regrowth out of stealth and if there's <15 seconds remaining
        # MODIFICATION: Remove "or Spell(cat_form)"
        # REASON: Blocks Prowl from showing up
        Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 15 and BuffExpires(prowl_buff) and Spell(regrowth)
    }
    
    AddFunction FeralPrecombatCdActions
    {
        unless Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 15 and BuffExpires(prowl_buff) and Spell(regrowth)
        {
            #snapshot_stats
            #potion
            if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
        }
    }
    
    AddFunction FeralPrecombatCdPostConditions
    {
        # MODIFICATION: Talent(bloodtalons_talent) to Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 15 and BuffExpires(prowl_buff)
        # REASON: Only suggest Regrowth out of stealth and if there's <15 seconds remaining
        # MODIFICATION: Remove "or Spell(cat_form)"
        # REASON: Blocks Prowl from showing up
        Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 15 and BuffExpires(prowl_buff) and Spell(regrowth)
    }
    
    ### Feral icons.
    
    AddCheckBox(opt_druid_feral_aoe L(AOE) default specialization=feral)
    
    AddIcon checkbox=!opt_druid_feral_aoe enemies=1 help=shortcd specialization=feral
    {
        if not InCombat() FeralPrecombatShortCdActions()
        unless not InCombat() and FeralPrecombatShortCdPostConditions()
        {
            FeralDefaultShortCdActions()
        }
    }
    
    AddIcon checkbox=opt_druid_feral_aoe help=shortcd specialization=feral
    {
        if not InCombat() FeralPrecombatShortCdActions()
        unless not InCombat() and FeralPrecombatShortCdPostConditions()
        {
            FeralDefaultShortCdActions()
        }
    }
    
    AddIcon enemies=1 help=main specialization=feral
    {
        if not InCombat() FeralPrecombatMainActions()
        unless not InCombat() and FeralPrecombatMainPostConditions()
        {
            FeralDefaultMainActions()
        }
    }
    
    AddIcon checkbox=opt_druid_feral_aoe help=aoe specialization=feral
    {
        if not InCombat() FeralPrecombatMainActions()
        unless not InCombat() and FeralPrecombatMainPostConditions()
        {
            FeralDefaultMainActions()
        }
    }
    
    AddIcon checkbox=!opt_druid_feral_aoe enemies=1 help=cd specialization=feral
    {
        if not InCombat() FeralPrecombatCdActions()
        unless not InCombat() and FeralPrecombatCdPostConditions()
        {
            FeralDefaultCdActions()
        }
    }
    
    AddIcon checkbox=opt_druid_feral_aoe help=cd specialization=feral
    {
        if not InCombat() FeralPrecombatCdActions()
        unless not InCombat() and FeralPrecombatCdPostConditions()
        {
            FeralDefaultCdActions()
        }
    }
    
    ### Required symbols
    # ailuro_pouncers
    # ashamanes_frenzy
    # berserk_cat
    # berserk_cat_buff
    # bloodtalons_buff
    # bloodtalons_talent
    # brutal_slash
    # cat_form
    # cat_form_buff
    # clearcasting_buff
    # dash
    # elunes_guidance
    # ferocious_bite
    # fiery_red_maimers_buff
    # incarnation_king_of_the_jungle
    # incarnation_king_of_the_jungle_buff
    # incarnation_talent
    # luffa_wrappings
    # lunar_inspiration_talent
    # maim
    # mangle
    # moonfire_cat
    # moonfire_cat_debuff
    # predatory_swiftness_buff
    # prolonged_power_potion
    # prowl
    # prowl_buff
    # rake
    # rake_debuff
    # regrowth
    # rip
    # rip_debuff
    # sabertooth_talent
    # savage_roar
    # savage_roar_buff
    # shadowmeld
    # shadowmeld_buff
    # shred
    # swipe_cat
    # thrash_cat
    # thrash_cat_debuff
    # tigers_fury
    # tigers_fury_buff
    # wild_charge
    # wild_charge_bear
    # wild_charge_cat
]]
    OvaleScripts:RegisterScript("DRUID", "feral", name, desc, code, "script")
end
do
    local name = "sc_druid_balance_t19"
    local desc = "[7.0] Simulationcraft: Druid_Balance_T19"
    local code = [[
# Based on SimulationCraft profile "Druid_Balance_T19P".
#	class=druid
#	spec=balance
#	talents=3200233

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=balance)

AddFunction BalanceUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.single_target

AddFunction BalanceSingletargetMainActions
{
 #starsurge,if=astral_power.deficit<44|(buff.celestial_alignment.up|buff.incarnation.up|buff.astral_acceleration.remains>5|(set_bonus.tier21_4pc&!buff.solar_solstice.up))|(gcd.max*(astral_power%40))>target.time_to_die
 if AstralPowerDeficit() < 44 or BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) or BuffRemaining(astral_acceleration_buff) > 5 or ArmorSetBonus(T21 4) and not BuffPresent(solar_solstice_buff) or GCD() * { AstralPower() / 40 } > target.TimeToDie() Spell(starsurge_moonkin)
 #new_moon,if=astral_power.deficit>14&!(buff.celestial_alignment.up|buff.incarnation.up)
 if AstralPowerDeficit() > 14 and not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
 #half_moon,if=astral_power.deficit>24&!(buff.celestial_alignment.up|buff.incarnation.up)
 if AstralPowerDeficit() > 24 and not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and SpellKnown(half_moon) Spell(half_moon)
 #full_moon,if=astral_power.deficit>44
 if AstralPowerDeficit() > 44 and SpellKnown(full_moon) Spell(full_moon)
 #warrior_of_elune
 Spell(warrior_of_elune)
 #lunar_strike,if=buff.warrior_of_elune.up
 if BuffPresent(warrior_of_elune_buff) Spell(lunar_strike_balance)
 #solar_wrath,if=buff.solar_empowerment.up
 if BuffPresent(solar_empowerment_buff) Spell(solar_wrath)
 #lunar_strike,if=buff.lunar_empowerment.up
 if BuffPresent(lunar_empowerment_buff) Spell(lunar_strike_balance)
 #solar_wrath
 Spell(solar_wrath)
}

AddFunction BalanceSingletargetMainPostConditions
{
}

AddFunction BalanceSingletargetShortCdActions
{
}

AddFunction BalanceSingletargetShortCdPostConditions
{
 { AstralPowerDeficit() < 44 or BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) or BuffRemaining(astral_acceleration_buff) > 5 or ArmorSetBonus(T21 4) and not BuffPresent(solar_solstice_buff) or GCD() * { AstralPower() / 40 } > target.TimeToDie() } and Spell(starsurge_moonkin) or AstralPowerDeficit() > 14 and not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() > 24 and not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() > 44 and SpellKnown(full_moon) and Spell(full_moon) or Spell(warrior_of_elune) or BuffPresent(warrior_of_elune_buff) and Spell(lunar_strike_balance) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

AddFunction BalanceSingletargetCdActions
{
}

AddFunction BalanceSingletargetCdPostConditions
{
 { AstralPowerDeficit() < 44 or BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) or BuffRemaining(astral_acceleration_buff) > 5 or ArmorSetBonus(T21 4) and not BuffPresent(solar_solstice_buff) or GCD() * { AstralPower() / 40 } > target.TimeToDie() } and Spell(starsurge_moonkin) or AstralPowerDeficit() > 14 and not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() > 24 and not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() > 44 and SpellKnown(full_moon) and Spell(full_moon) or Spell(warrior_of_elune) or BuffPresent(warrior_of_elune_buff) and Spell(lunar_strike_balance) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

### actions.precombat

AddFunction BalancePrecombatMainActions
{
 #flask
 #food
 #augmentation
 #moonkin_form
 Spell(moonkin_form)
 #blessing_of_elune
 Spell(blessing_of_elune)
 #new_moon
 if not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
}

AddFunction BalancePrecombatMainPostConditions
{
}

AddFunction BalancePrecombatShortCdActions
{
}

AddFunction BalancePrecombatShortCdPostConditions
{
 Spell(moonkin_form) or Spell(blessing_of_elune) or not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon)
}

AddFunction BalancePrecombatCdActions
{
 unless Spell(moonkin_form) or Spell(blessing_of_elune)
 {
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(potion_of_prolonged_power_potion usable=1)
 }
}

AddFunction BalancePrecombatCdPostConditions
{
 Spell(moonkin_form) or Spell(blessing_of_elune) or not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon)
}

### actions.fury_of_elune

AddFunction BalanceFuryofeluneMainActions
{
 #new_moon,if=((charges=2&recharge_time<5)|charges=3)&&(buff.fury_of_elune_up.up|(cooldown.fury_of_elune.remains>gcd*3&astral_power<=90))
 if { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 90 } and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
 #half_moon,if=((charges=2&recharge_time<5)|charges=3)&&(buff.fury_of_elune_up.up|(cooldown.fury_of_elune.remains>gcd*3&astral_power<=80))
 if { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 80 } and SpellKnown(half_moon) Spell(half_moon)
 #full_moon,if=((charges=2&recharge_time<5)|charges=3)&&(buff.fury_of_elune_up.up|(cooldown.fury_of_elune.remains>gcd*3&astral_power<=60))
 if { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 60 } and SpellKnown(full_moon) Spell(full_moon)
 #warrior_of_elune,if=buff.fury_of_elune_up.up|(cooldown.fury_of_elune.remains>=35&buff.lunar_empowerment.up)
 if BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) >= 35 and BuffPresent(lunar_empowerment_buff) Spell(warrior_of_elune)
 #lunar_strike,if=buff.warrior_of_elune.up&(astral_power<=90|(astral_power<=85&buff.incarnation.up))
 if BuffPresent(warrior_of_elune_buff) and { AstralPower() <= 90 or AstralPower() <= 85 and BuffPresent(incarnation_chosen_of_elune_buff) } Spell(lunar_strike_balance)
 #new_moon,if=astral_power<=90&buff.fury_of_elune_up.up
 if AstralPower() <= 90 and BuffPresent(fury_of_elune_up_buff) and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
 #half_moon,if=astral_power<=80&buff.fury_of_elune_up.up&astral_power>cast_time*12
 if AstralPower() <= 80 and BuffPresent(fury_of_elune_up_buff) and AstralPower() > CastTime(half_moon) * 12 and SpellKnown(half_moon) Spell(half_moon)
 #full_moon,if=astral_power<=60&buff.fury_of_elune_up.up&astral_power>cast_time*12
 if AstralPower() <= 60 and BuffPresent(fury_of_elune_up_buff) and AstralPower() > CastTime(full_moon) * 12 and SpellKnown(full_moon) Spell(full_moon)
 #moonfire,if=buff.fury_of_elune_up.down&remains<=6.6
 if BuffExpires(fury_of_elune_up_buff) and target.DebuffRemaining(moonfire_debuff) <= 6 Spell(moonfire)
 #sunfire,if=buff.fury_of_elune_up.down&remains<5.4
 if BuffExpires(fury_of_elune_up_buff) and target.DebuffRemaining(sunfire_debuff) < 5 Spell(sunfire)
 #stellar_flare,if=remains<7.2&active_enemies=1
 if target.DebuffRemaining(stellar_flare_debuff) < 7 and Enemies() == 1 Spell(stellar_flare)
 #starfall,if=(active_enemies>=2&talent.stellar_flare.enabled|active_enemies>=3)&buff.fury_of_elune_up.down&cooldown.fury_of_elune.remains>10
 if { Enemies() >= 2 and Talent(stellar_flare_talent) or Enemies() >= 3 } and BuffExpires(fury_of_elune_up_buff) and SpellCooldown(fury_of_elune) > 10 Spell(starfall)
 #starsurge,if=active_enemies<=2&buff.fury_of_elune_up.down&cooldown.fury_of_elune.remains>7
 if Enemies() <= 2 and BuffExpires(fury_of_elune_up_buff) and SpellCooldown(fury_of_elune) > 7 Spell(starsurge_moonkin)
 #starsurge,if=buff.fury_of_elune_up.down&((astral_power>=92&cooldown.fury_of_elune.remains>gcd*3)|(cooldown.warrior_of_elune.remains<=5&cooldown.fury_of_elune.remains>=35&buff.lunar_empowerment.stack<2))
 if BuffExpires(fury_of_elune_up_buff) and { AstralPower() >= 92 and SpellCooldown(fury_of_elune) > GCD() * 3 or SpellCooldown(warrior_of_elune) <= 5 and SpellCooldown(fury_of_elune) >= 35 and BuffStacks(lunar_empowerment_buff) < 2 } Spell(starsurge_moonkin)
 #solar_wrath,if=buff.solar_empowerment.up
 if BuffPresent(solar_empowerment_buff) Spell(solar_wrath)
 #lunar_strike,if=buff.lunar_empowerment.stack=3|(buff.lunar_empowerment.remains<5&buff.lunar_empowerment.up)|active_enemies>=2
 if BuffStacks(lunar_empowerment_buff) == 3 or BuffRemaining(lunar_empowerment_buff) < 5 and BuffPresent(lunar_empowerment_buff) or Enemies() >= 2 Spell(lunar_strike_balance)
 #solar_wrath
 Spell(solar_wrath)
}

AddFunction BalanceFuryofeluneMainPostConditions
{
}

AddFunction BalanceFuryofeluneShortCdActions
{
 #fury_of_elune,if=astral_power>=95
 if AstralPower() >= 95 Spell(fury_of_elune)

 unless { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 90 } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 80 } and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 60 } and SpellKnown(full_moon) and Spell(full_moon)
 {
  #astral_communion,if=buff.fury_of_elune_up.up&astral_power<=25
  if BuffPresent(fury_of_elune_up_buff) and AstralPower() <= 25 Spell(astral_communion)
 }
}

AddFunction BalanceFuryofeluneShortCdPostConditions
{
 { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 90 } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 80 } and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 60 } and SpellKnown(full_moon) and Spell(full_moon) or { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) >= 35 and BuffPresent(lunar_empowerment_buff) } and Spell(warrior_of_elune) or BuffPresent(warrior_of_elune_buff) and { AstralPower() <= 90 or AstralPower() <= 85 and BuffPresent(incarnation_chosen_of_elune_buff) } and Spell(lunar_strike_balance) or AstralPower() <= 90 and BuffPresent(fury_of_elune_up_buff) and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPower() <= 80 and BuffPresent(fury_of_elune_up_buff) and AstralPower() > CastTime(half_moon) * 12 and SpellKnown(half_moon) and Spell(half_moon) or AstralPower() <= 60 and BuffPresent(fury_of_elune_up_buff) and AstralPower() > CastTime(full_moon) * 12 and SpellKnown(full_moon) and Spell(full_moon) or BuffExpires(fury_of_elune_up_buff) and target.DebuffRemaining(moonfire_debuff) <= 6 and Spell(moonfire) or BuffExpires(fury_of_elune_up_buff) and target.DebuffRemaining(sunfire_debuff) < 5 and Spell(sunfire) or target.DebuffRemaining(stellar_flare_debuff) < 7 and Enemies() == 1 and Spell(stellar_flare) or { Enemies() >= 2 and Talent(stellar_flare_talent) or Enemies() >= 3 } and BuffExpires(fury_of_elune_up_buff) and SpellCooldown(fury_of_elune) > 10 and Spell(starfall) or Enemies() <= 2 and BuffExpires(fury_of_elune_up_buff) and SpellCooldown(fury_of_elune) > 7 and Spell(starsurge_moonkin) or BuffExpires(fury_of_elune_up_buff) and { AstralPower() >= 92 and SpellCooldown(fury_of_elune) > GCD() * 3 or SpellCooldown(warrior_of_elune) <= 5 and SpellCooldown(fury_of_elune) >= 35 and BuffStacks(lunar_empowerment_buff) < 2 } and Spell(starsurge_moonkin) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or { BuffStacks(lunar_empowerment_buff) == 3 or BuffRemaining(lunar_empowerment_buff) < 5 and BuffPresent(lunar_empowerment_buff) or Enemies() >= 2 } and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

AddFunction BalanceFuryofeluneCdActions
{
 #incarnation,if=astral_power>=95&cooldown.fury_of_elune.remains<=gcd
 if AstralPower() >= 95 and SpellCooldown(fury_of_elune) <= GCD() Spell(incarnation_chosen_of_elune)
}

AddFunction BalanceFuryofeluneCdPostConditions
{
 AstralPower() >= 95 and Spell(fury_of_elune) or { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 90 } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 80 } and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 } and { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) > GCD() * 3 and AstralPower() <= 60 } and SpellKnown(full_moon) and Spell(full_moon) or BuffPresent(fury_of_elune_up_buff) and AstralPower() <= 25 and Spell(astral_communion) or { BuffPresent(fury_of_elune_up_buff) or SpellCooldown(fury_of_elune) >= 35 and BuffPresent(lunar_empowerment_buff) } and Spell(warrior_of_elune) or BuffPresent(warrior_of_elune_buff) and { AstralPower() <= 90 or AstralPower() <= 85 and BuffPresent(incarnation_chosen_of_elune_buff) } and Spell(lunar_strike_balance) or AstralPower() <= 90 and BuffPresent(fury_of_elune_up_buff) and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPower() <= 80 and BuffPresent(fury_of_elune_up_buff) and AstralPower() > CastTime(half_moon) * 12 and SpellKnown(half_moon) and Spell(half_moon) or AstralPower() <= 60 and BuffPresent(fury_of_elune_up_buff) and AstralPower() > CastTime(full_moon) * 12 and SpellKnown(full_moon) and Spell(full_moon) or BuffExpires(fury_of_elune_up_buff) and target.DebuffRemaining(moonfire_debuff) <= 6 and Spell(moonfire) or BuffExpires(fury_of_elune_up_buff) and target.DebuffRemaining(sunfire_debuff) < 5 and Spell(sunfire) or target.DebuffRemaining(stellar_flare_debuff) < 7 and Enemies() == 1 and Spell(stellar_flare) or { Enemies() >= 2 and Talent(stellar_flare_talent) or Enemies() >= 3 } and BuffExpires(fury_of_elune_up_buff) and SpellCooldown(fury_of_elune) > 10 and Spell(starfall) or Enemies() <= 2 and BuffExpires(fury_of_elune_up_buff) and SpellCooldown(fury_of_elune) > 7 and Spell(starsurge_moonkin) or BuffExpires(fury_of_elune_up_buff) and { AstralPower() >= 92 and SpellCooldown(fury_of_elune) > GCD() * 3 or SpellCooldown(warrior_of_elune) <= 5 and SpellCooldown(fury_of_elune) >= 35 and BuffStacks(lunar_empowerment_buff) < 2 } and Spell(starsurge_moonkin) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or { BuffStacks(lunar_empowerment_buff) == 3 or BuffRemaining(lunar_empowerment_buff) < 5 and BuffPresent(lunar_empowerment_buff) or Enemies() >= 2 } and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

### actions.ed

AddFunction BalanceEdMainActions
{
 #starsurge,if=(gcd.max*astral_power%26)>target.time_to_die
 if GCD() * AstralPower() / 26 > target.TimeToDie() Spell(starsurge_moonkin)
 #stellar_flare,cycle_targets=1,max_cycle_targets=4,if=active_enemies<4&remains<7.2
 if DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7 Spell(stellar_flare)
 #moonfire,if=((talent.natures_balance.enabled&remains<3)|(remains<6.6&!talent.natures_balance.enabled))&(buff.the_emerald_dreamcatcher.remains>gcd.max|!buff.the_emerald_dreamcatcher.up)
 if { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6 and not Talent(natures_balance_talent) } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } Spell(moonfire)
 #sunfire,if=((talent.natures_balance.enabled&remains<3)|(remains<5.4&!talent.natures_balance.enabled))&(buff.the_emerald_dreamcatcher.remains>gcd.max|!buff.the_emerald_dreamcatcher.up)
 if { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5 and not Talent(natures_balance_talent) } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } Spell(sunfire)
 #starfall,if=buff.oneths_overconfidence.up&buff.the_emerald_dreamcatcher.remains>execute_time
 if BuffPresent(oneths_overconfidence_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(starfall) Spell(starfall)
 #new_moon,if=astral_power.deficit>=10&buff.the_emerald_dreamcatcher.remains>execute_time&astral_power>=16
 if AstralPowerDeficit() >= 10 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(new_moon) and AstralPower() >= 16 and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
 #half_moon,if=astral_power.deficit>=20&buff.the_emerald_dreamcatcher.remains>execute_time&astral_power>=6
 if AstralPowerDeficit() >= 20 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(half_moon) and AstralPower() >= 6 and SpellKnown(half_moon) Spell(half_moon)
 #full_moon,if=astral_power.deficit>=40&buff.the_emerald_dreamcatcher.remains>execute_time
 if AstralPowerDeficit() >= 40 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(full_moon) and SpellKnown(full_moon) Spell(full_moon)
 #lunar_strike,if=(buff.lunar_empowerment.up&buff.the_emerald_dreamcatcher.remains>execute_time&(!(buff.celestial_alignment.up|buff.incarnation.up)&astral_power.deficit>=15|(buff.celestial_alignment.up|buff.incarnation.up)&astral_power.deficit>=22.5))&spell_haste<0.4
 if BuffPresent(lunar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(lunar_strike_balance) and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 15 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 22 } and 100 / { 100 + SpellHaste() } < 0 Spell(lunar_strike_balance)
 #solar_wrath,if=buff.solar_empowerment.stack>1&buff.the_emerald_dreamcatcher.remains>2*execute_time&astral_power>=6&(dot.moonfire.remains>5|(dot.sunfire.remains<5.4&dot.moonfire.remains>6.6))&(!(buff.celestial_alignment.up|buff.incarnation.up)&astral_power.deficit>=10|(buff.celestial_alignment.up|buff.incarnation.up)&astral_power.deficit>=15)
 if BuffStacks(solar_empowerment_buff) > 1 and BuffRemaining(the_emerald_dreamcatcher_buff) > 2 * ExecuteTime(solar_wrath) and AstralPower() >= 6 and { target.DebuffRemaining(moonfire_debuff) > 5 or target.DebuffRemaining(sunfire_debuff) < 5 and target.DebuffRemaining(moonfire_debuff) > 6 } and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 10 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 15 } Spell(solar_wrath)
 #lunar_strike,if=buff.lunar_empowerment.up&buff.the_emerald_dreamcatcher.remains>execute_time&astral_power>=11&(!(buff.celestial_alignment.up|buff.incarnation.up)&astral_power.deficit>=15|(buff.celestial_alignment.up|buff.incarnation.up)&astral_power.deficit>=22.5)
 if BuffPresent(lunar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(lunar_strike_balance) and AstralPower() >= 11 and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 15 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 22 } Spell(lunar_strike_balance)
 #solar_wrath,if=buff.solar_empowerment.up&buff.the_emerald_dreamcatcher.remains>execute_time&astral_power>=16&(!(buff.celestial_alignment.up|buff.incarnation.up)&astral_power.deficit>=10|(buff.celestial_alignment.up|buff.incarnation.up)&astral_power.deficit>=15)
 if BuffPresent(solar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(solar_wrath) and AstralPower() >= 16 and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 10 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 15 } Spell(solar_wrath)
 #starsurge,if=(buff.the_emerald_dreamcatcher.up&buff.the_emerald_dreamcatcher.remains<gcd.max)|astral_power>85|((buff.celestial_alignment.up|buff.incarnation.up)&astral_power>30)
 if BuffPresent(the_emerald_dreamcatcher_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) < GCD() or AstralPower() > 85 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() > 30 Spell(starsurge_moonkin)
 #starfall,if=buff.oneths_overconfidence.up
 if BuffPresent(oneths_overconfidence_buff) Spell(starfall)
 #new_moon,if=astral_power.deficit>=10
 if AstralPowerDeficit() >= 10 and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
 #half_moon,if=astral_power.deficit>=20
 if AstralPowerDeficit() >= 20 and SpellKnown(half_moon) Spell(half_moon)
 #full_moon,if=astral_power.deficit>=40
 if AstralPowerDeficit() >= 40 and SpellKnown(full_moon) Spell(full_moon)
 #solar_wrath,if=buff.solar_empowerment.up
 if BuffPresent(solar_empowerment_buff) Spell(solar_wrath)
 #lunar_strike,if=buff.lunar_empowerment.up
 if BuffPresent(lunar_empowerment_buff) Spell(lunar_strike_balance)
 #solar_wrath
 Spell(solar_wrath)
}

AddFunction BalanceEdMainPostConditions
{
}

AddFunction BalanceEdShortCdActions
{
 #astral_communion,if=astral_power.deficit>=75&buff.the_emerald_dreamcatcher.up
 if AstralPowerDeficit() >= 75 and BuffPresent(the_emerald_dreamcatcher_buff) Spell(astral_communion)
}

AddFunction BalanceEdShortCdPostConditions
{
 GCD() * AstralPower() / 26 > target.TimeToDie() and Spell(starsurge_moonkin) or DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7 and Spell(stellar_flare) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6 and not Talent(natures_balance_talent) } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(moonfire) or { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5 and not Talent(natures_balance_talent) } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(sunfire) or BuffPresent(oneths_overconfidence_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(starfall) and Spell(starfall) or AstralPowerDeficit() >= 10 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(new_moon) and AstralPower() >= 16 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() >= 20 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(half_moon) and AstralPower() >= 6 and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() >= 40 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(full_moon) and SpellKnown(full_moon) and Spell(full_moon) or BuffPresent(lunar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(lunar_strike_balance) and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 15 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 22 } and 100 / { 100 + SpellHaste() } < 0 and Spell(lunar_strike_balance) or BuffStacks(solar_empowerment_buff) > 1 and BuffRemaining(the_emerald_dreamcatcher_buff) > 2 * ExecuteTime(solar_wrath) and AstralPower() >= 6 and { target.DebuffRemaining(moonfire_debuff) > 5 or target.DebuffRemaining(sunfire_debuff) < 5 and target.DebuffRemaining(moonfire_debuff) > 6 } and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 10 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 15 } and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(lunar_strike_balance) and AstralPower() >= 11 and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 15 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 22 } and Spell(lunar_strike_balance) or BuffPresent(solar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(solar_wrath) and AstralPower() >= 16 and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 10 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 15 } and Spell(solar_wrath) or { BuffPresent(the_emerald_dreamcatcher_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) < GCD() or AstralPower() > 85 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() > 30 } and Spell(starsurge_moonkin) or BuffPresent(oneths_overconfidence_buff) and Spell(starfall) or AstralPowerDeficit() >= 10 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() >= 20 and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() >= 40 and SpellKnown(full_moon) and Spell(full_moon) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

AddFunction BalanceEdCdActions
{
 unless AstralPowerDeficit() >= 75 and BuffPresent(the_emerald_dreamcatcher_buff) and Spell(astral_communion)
 {
  #incarnation,if=astral_power>=60|buff.bloodlust.up
  if AstralPower() >= 60 or BuffPresent(burst_haste_buff any=1) Spell(incarnation_chosen_of_elune)
  #celestial_alignment,if=astral_power>=60&!buff.the_emerald_dreamcatcher.up
  if AstralPower() >= 60 and not BuffPresent(the_emerald_dreamcatcher_buff) Spell(celestial_alignment)
 }
}

AddFunction BalanceEdCdPostConditions
{
 AstralPowerDeficit() >= 75 and BuffPresent(the_emerald_dreamcatcher_buff) and Spell(astral_communion) or GCD() * AstralPower() / 26 > target.TimeToDie() and Spell(starsurge_moonkin) or DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7 and Spell(stellar_flare) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6 and not Talent(natures_balance_talent) } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(moonfire) or { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5 and not Talent(natures_balance_talent) } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(sunfire) or BuffPresent(oneths_overconfidence_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(starfall) and Spell(starfall) or AstralPowerDeficit() >= 10 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(new_moon) and AstralPower() >= 16 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() >= 20 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(half_moon) and AstralPower() >= 6 and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() >= 40 and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(full_moon) and SpellKnown(full_moon) and Spell(full_moon) or BuffPresent(lunar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(lunar_strike_balance) and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 15 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 22 } and 100 / { 100 + SpellHaste() } < 0 and Spell(lunar_strike_balance) or BuffStacks(solar_empowerment_buff) > 1 and BuffRemaining(the_emerald_dreamcatcher_buff) > 2 * ExecuteTime(solar_wrath) and AstralPower() >= 6 and { target.DebuffRemaining(moonfire_debuff) > 5 or target.DebuffRemaining(sunfire_debuff) < 5 and target.DebuffRemaining(moonfire_debuff) > 6 } and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 10 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 15 } and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(lunar_strike_balance) and AstralPower() >= 11 and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 15 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 22 } and Spell(lunar_strike_balance) or BuffPresent(solar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(solar_wrath) and AstralPower() >= 16 and { not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 10 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPowerDeficit() >= 15 } and Spell(solar_wrath) or { BuffPresent(the_emerald_dreamcatcher_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) < GCD() or AstralPower() > 85 or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and AstralPower() > 30 } and Spell(starsurge_moonkin) or BuffPresent(oneths_overconfidence_buff) and Spell(starfall) or AstralPowerDeficit() >= 10 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() >= 20 and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() >= 40 and SpellKnown(full_moon) and Spell(full_moon) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

### actions.default

AddFunction BalanceDefaultMainActions
{
 #blessing_of_elune,if=active_enemies<=2&talent.blessing_of_the_ancients.enabled&buff.blessing_of_elune.down
 if Enemies() <= 2 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_elune_buff) Spell(blessing_of_elune)
 #blessing_of_elune,if=active_enemies>=3&talent.blessing_of_the_ancients.enabled&buff.blessing_of_anshe.down
 if Enemies() >= 3 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_anshe_buff) Spell(blessing_of_elune)
 #call_action_list,name=fury_of_elune,if=talent.fury_of_elune.enabled&cooldown.fury_of_elune.remains<target.time_to_die
 if Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() BalanceFuryofeluneMainActions()

 unless Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() and BalanceFuryofeluneMainPostConditions()
 {
  #call_action_list,name=ed,if=equipped.the_emerald_dreamcatcher&active_enemies<=1
  if HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 1 BalanceEdMainActions()

  unless HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 1 and BalanceEdMainPostConditions()
  {
   #new_moon,if=((charges=2&recharge_time<5)|charges=3)&astral_power.deficit>14
   if { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and AstralPowerDeficit() > 14 and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
   #half_moon,if=((charges=2&recharge_time<5)|charges=3|(target.time_to_die<15&charges=2))&astral_power.deficit>24
   if { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 or target.TimeToDie() < 15 and Charges(half_moon) == 2 } and AstralPowerDeficit() > 24 and SpellKnown(half_moon) Spell(half_moon)
   #full_moon,if=((charges=2&recharge_time<5)|charges=3|target.time_to_die<15)&astral_power.deficit>44
   if { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 or target.TimeToDie() < 15 } and AstralPowerDeficit() > 44 and SpellKnown(full_moon) Spell(full_moon)
   #stellar_flare,cycle_targets=1,max_cycle_targets=4,if=active_enemies<4&remains<7.2
   if DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7 Spell(stellar_flare)
   #moonfire,cycle_targets=1,if=((talent.natures_balance.enabled&remains<3)|(remains<6.6&!talent.natures_balance.enabled))&astral_power.deficit>7
   if { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6 and not Talent(natures_balance_talent) } and AstralPowerDeficit() > 7 Spell(moonfire)
   #sunfire,if=((talent.natures_balance.enabled&remains<3)|(remains<5.4&!talent.natures_balance.enabled))&astral_power.deficit>7
   if { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5 and not Talent(natures_balance_talent) } and AstralPowerDeficit() > 7 Spell(sunfire)
   #starfall,if=buff.oneths_overconfidence.up&(!buff.solar_solstice.up|astral_power.deficit>44|buff.celestial_alignment.up|buff.incarnation.up)
   if BuffPresent(oneths_overconfidence_buff) and { not BuffPresent(solar_solstice_buff) or AstralPowerDeficit() > 44 or BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } Spell(starfall)
   #solar_wrath,if=buff.solar_empowerment.stack=3
   if BuffStacks(solar_empowerment_buff) == 3 Spell(solar_wrath)
   #lunar_strike,if=buff.lunar_empowerment.stack=3
   if BuffStacks(lunar_empowerment_buff) == 3 Spell(lunar_strike_balance)
   #starsurge,if=buff.oneths_intuition.up
   if BuffPresent(oneths_intuition_buff) Spell(starsurge_moonkin)
   #call_action_list,name=AoE,if=(active_enemies>=2&talent.stellar_drift.enabled)|active_enemies>=3
   if Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 BalanceAoeMainActions()

   unless { Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 } and BalanceAoeMainPostConditions()
   {
    #call_action_list,name=single_target
    BalanceSingletargetMainActions()
   }
  }
 }
}

AddFunction BalanceDefaultMainPostConditions
{
 Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() and BalanceFuryofeluneMainPostConditions() or HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 1 and BalanceEdMainPostConditions() or { Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 } and BalanceAoeMainPostConditions() or BalanceSingletargetMainPostConditions()
}

AddFunction BalanceDefaultShortCdActions
{
 unless Enemies() <= 2 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_elune_buff) and Spell(blessing_of_elune) or Enemies() >= 3 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_anshe_buff) and Spell(blessing_of_elune)
 {
  #call_action_list,name=fury_of_elune,if=talent.fury_of_elune.enabled&cooldown.fury_of_elune.remains<target.time_to_die
  if Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() BalanceFuryofeluneShortCdActions()

  unless Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() and BalanceFuryofeluneShortCdPostConditions()
  {
   #call_action_list,name=ed,if=equipped.the_emerald_dreamcatcher&active_enemies<=1
   if HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 1 BalanceEdShortCdActions()

   unless HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 1 and BalanceEdShortCdPostConditions() or { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and AstralPowerDeficit() > 14 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 or target.TimeToDie() < 15 and Charges(half_moon) == 2 } and AstralPowerDeficit() > 24 and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 or target.TimeToDie() < 15 } and AstralPowerDeficit() > 44 and SpellKnown(full_moon) and Spell(full_moon) or DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7 and Spell(stellar_flare) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6 and not Talent(natures_balance_talent) } and AstralPowerDeficit() > 7 and Spell(moonfire) or { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5 and not Talent(natures_balance_talent) } and AstralPowerDeficit() > 7 and Spell(sunfire)
   {
    #astral_communion,if=astral_power.deficit>=71
    if AstralPowerDeficit() >= 71 Spell(astral_communion)

    unless BuffPresent(oneths_overconfidence_buff) and { not BuffPresent(solar_solstice_buff) or AstralPowerDeficit() > 44 or BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and Spell(starfall) or BuffStacks(solar_empowerment_buff) == 3 and Spell(solar_wrath) or BuffStacks(lunar_empowerment_buff) == 3 and Spell(lunar_strike_balance) or BuffPresent(oneths_intuition_buff) and Spell(starsurge_moonkin)
    {
     #call_action_list,name=AoE,if=(active_enemies>=2&talent.stellar_drift.enabled)|active_enemies>=3
     if Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 BalanceAoeShortCdActions()

     unless { Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 } and BalanceAoeShortCdPostConditions()
     {
      #call_action_list,name=single_target
      BalanceSingletargetShortCdActions()
     }
    }
   }
  }
 }
}

AddFunction BalanceDefaultShortCdPostConditions
{
 Enemies() <= 2 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_elune_buff) and Spell(blessing_of_elune) or Enemies() >= 3 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_anshe_buff) and Spell(blessing_of_elune) or Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() and BalanceFuryofeluneShortCdPostConditions() or HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 1 and BalanceEdShortCdPostConditions() or { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and AstralPowerDeficit() > 14 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 or target.TimeToDie() < 15 and Charges(half_moon) == 2 } and AstralPowerDeficit() > 24 and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 or target.TimeToDie() < 15 } and AstralPowerDeficit() > 44 and SpellKnown(full_moon) and Spell(full_moon) or DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7 and Spell(stellar_flare) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6 and not Talent(natures_balance_talent) } and AstralPowerDeficit() > 7 and Spell(moonfire) or { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5 and not Talent(natures_balance_talent) } and AstralPowerDeficit() > 7 and Spell(sunfire) or BuffPresent(oneths_overconfidence_buff) and { not BuffPresent(solar_solstice_buff) or AstralPowerDeficit() > 44 or BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and Spell(starfall) or BuffStacks(solar_empowerment_buff) == 3 and Spell(solar_wrath) or BuffStacks(lunar_empowerment_buff) == 3 and Spell(lunar_strike_balance) or BuffPresent(oneths_intuition_buff) and Spell(starsurge_moonkin) or { Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 } and BalanceAoeShortCdPostConditions() or BalanceSingletargetShortCdPostConditions()
}

AddFunction BalanceDefaultCdActions
{
 #potion,name=potion_of_prolonged_power,if=buff.celestial_alignment.up|buff.incarnation.up
 if { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(potion_of_prolonged_power_potion usable=1)

 unless Enemies() <= 2 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_elune_buff) and Spell(blessing_of_elune) or Enemies() >= 3 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_anshe_buff) and Spell(blessing_of_elune)
 {
  #blood_fury,if=buff.celestial_alignment.up|buff.incarnation.up
  if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) Spell(blood_fury_apsp)
  #berserking,if=buff.celestial_alignment.up|buff.incarnation.up
  if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) Spell(berserking)
  #arcane_torrent,if=buff.celestial_alignment.up|buff.incarnation.up
  if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) Spell(arcane_torrent_energy)
  #use_items
  BalanceUseItemActions()
  #call_action_list,name=fury_of_elune,if=talent.fury_of_elune.enabled&cooldown.fury_of_elune.remains<target.time_to_die
  if Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() BalanceFuryofeluneCdActions()

  unless Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() and BalanceFuryofeluneCdPostConditions()
  {
   #call_action_list,name=ed,if=equipped.the_emerald_dreamcatcher&active_enemies<=1
   if HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 1 BalanceEdCdActions()

   unless HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 1 and BalanceEdCdPostConditions() or { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and AstralPowerDeficit() > 14 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 or target.TimeToDie() < 15 and Charges(half_moon) == 2 } and AstralPowerDeficit() > 24 and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 or target.TimeToDie() < 15 } and AstralPowerDeficit() > 44 and SpellKnown(full_moon) and Spell(full_moon) or DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7 and Spell(stellar_flare) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6 and not Talent(natures_balance_talent) } and AstralPowerDeficit() > 7 and Spell(moonfire) or { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5 and not Talent(natures_balance_talent) } and AstralPowerDeficit() > 7 and Spell(sunfire) or AstralPowerDeficit() >= 71 and Spell(astral_communion)
   {
    #incarnation,if=astral_power>=40
    if AstralPower() >= 40 Spell(incarnation_chosen_of_elune)
    #celestial_alignment,if=astral_power>=40
    if AstralPower() >= 40 Spell(celestial_alignment)

    unless BuffPresent(oneths_overconfidence_buff) and { not BuffPresent(solar_solstice_buff) or AstralPowerDeficit() > 44 or BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and Spell(starfall) or BuffStacks(solar_empowerment_buff) == 3 and Spell(solar_wrath) or BuffStacks(lunar_empowerment_buff) == 3 and Spell(lunar_strike_balance) or BuffPresent(oneths_intuition_buff) and Spell(starsurge_moonkin)
    {
     #call_action_list,name=AoE,if=(active_enemies>=2&talent.stellar_drift.enabled)|active_enemies>=3
     if Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 BalanceAoeCdActions()

     unless { Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 } and BalanceAoeCdPostConditions()
     {
      #call_action_list,name=single_target
      BalanceSingletargetCdActions()
     }
    }
   }
  }
 }
}

AddFunction BalanceDefaultCdPostConditions
{
 Enemies() <= 2 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_elune_buff) and Spell(blessing_of_elune) or Enemies() >= 3 and Talent(blessing_of_the_ancients_talent) and BuffExpires(blessing_of_anshe_buff) and Spell(blessing_of_elune) or Talent(fury_of_elune_talent) and SpellCooldown(fury_of_elune) < target.TimeToDie() and BalanceFuryofeluneCdPostConditions() or HasEquippedItem(the_emerald_dreamcatcher) and Enemies() <= 1 and BalanceEdCdPostConditions() or { Charges(new_moon) == 2 and SpellChargeCooldown(new_moon) < 5 or Charges(new_moon) == 3 } and AstralPowerDeficit() > 14 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or { Charges(half_moon) == 2 and SpellChargeCooldown(half_moon) < 5 or Charges(half_moon) == 3 or target.TimeToDie() < 15 and Charges(half_moon) == 2 } and AstralPowerDeficit() > 24 and SpellKnown(half_moon) and Spell(half_moon) or { Charges(full_moon) == 2 and SpellChargeCooldown(full_moon) < 5 or Charges(full_moon) == 3 or target.TimeToDie() < 15 } and AstralPowerDeficit() > 44 and SpellKnown(full_moon) and Spell(full_moon) or DebuffCountOnAny(stellar_flare_debuff) < Enemies() and DebuffCountOnAny(stellar_flare_debuff) <= 4 and Enemies() < 4 and target.DebuffRemaining(stellar_flare_debuff) < 7 and Spell(stellar_flare) or { Talent(natures_balance_talent) and target.DebuffRemaining(moonfire_debuff) < 3 or target.DebuffRemaining(moonfire_debuff) < 6 and not Talent(natures_balance_talent) } and AstralPowerDeficit() > 7 and Spell(moonfire) or { Talent(natures_balance_talent) and target.DebuffRemaining(sunfire_debuff) < 3 or target.DebuffRemaining(sunfire_debuff) < 5 and not Talent(natures_balance_talent) } and AstralPowerDeficit() > 7 and Spell(sunfire) or AstralPowerDeficit() >= 71 and Spell(astral_communion) or BuffPresent(oneths_overconfidence_buff) and { not BuffPresent(solar_solstice_buff) or AstralPowerDeficit() > 44 or BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and Spell(starfall) or BuffStacks(solar_empowerment_buff) == 3 and Spell(solar_wrath) or BuffStacks(lunar_empowerment_buff) == 3 and Spell(lunar_strike_balance) or BuffPresent(oneths_intuition_buff) and Spell(starsurge_moonkin) or { Enemies() >= 2 and Talent(stellar_drift_talent) or Enemies() >= 3 } and BalanceAoeCdPostConditions() or BalanceSingletargetCdPostConditions()
}

### actions.AoE

AddFunction BalanceAoeMainActions
{
 #starfall,if=debuff.stellar_empowerment.remains<gcd.max*2|astral_power.deficit<22.5|(buff.celestial_alignment.remains>8|buff.incarnation.remains>8)|target.time_to_die<8
 if target.DebuffRemaining(stellar_empowerment_debuff) < GCD() * 2 or AstralPowerDeficit() < 22 or BuffRemaining(celestial_alignment_buff) > 8 or BuffRemaining(incarnation_chosen_of_elune_buff) > 8 or target.TimeToDie() < 8 Spell(starfall)
 #new_moon,if=astral_power.deficit>14
 if AstralPowerDeficit() > 14 and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
 #half_moon,if=astral_power.deficit>24
 if AstralPowerDeficit() > 24 and SpellKnown(half_moon) Spell(half_moon)
 #full_moon,if=astral_power.deficit>44
 if AstralPowerDeficit() > 44 and SpellKnown(full_moon) Spell(full_moon)
 #warrior_of_elune
 Spell(warrior_of_elune)
 #lunar_strike,if=buff.warrior_of_elune.up
 if BuffPresent(warrior_of_elune_buff) Spell(lunar_strike_balance)
 #solar_wrath,if=buff.solar_empowerment.up
 if BuffPresent(solar_empowerment_buff) Spell(solar_wrath)
 #lunar_strike,if=buff.lunar_empowerment.up
 if BuffPresent(lunar_empowerment_buff) Spell(lunar_strike_balance)
 #moonfire,if=equipped.lady_and_the_child&active_enemies=2&spell_haste>0.4&!(buff.celestial_alignment.up|buff.incarnation.up)
 if HasEquippedItem(lady_and_the_child) and Enemies() == 2 and 100 / { 100 + SpellHaste() } > 0 and not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } Spell(moonfire)
 #lunar_strike,if=active_enemies>=4|spell_haste<0.45
 if Enemies() >= 4 or 100 / { 100 + SpellHaste() } < 0 Spell(lunar_strike_balance)
 #solar_wrath
 Spell(solar_wrath)
}

AddFunction BalanceAoeMainPostConditions
{
}

AddFunction BalanceAoeShortCdActions
{
}

AddFunction BalanceAoeShortCdPostConditions
{
 { target.DebuffRemaining(stellar_empowerment_debuff) < GCD() * 2 or AstralPowerDeficit() < 22 or BuffRemaining(celestial_alignment_buff) > 8 or BuffRemaining(incarnation_chosen_of_elune_buff) > 8 or target.TimeToDie() < 8 } and Spell(starfall) or AstralPowerDeficit() > 14 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() > 24 and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() > 44 and SpellKnown(full_moon) and Spell(full_moon) or Spell(warrior_of_elune) or BuffPresent(warrior_of_elune_buff) and Spell(lunar_strike_balance) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike_balance) or HasEquippedItem(lady_and_the_child) and Enemies() == 2 and 100 / { 100 + SpellHaste() } > 0 and not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and Spell(moonfire) or { Enemies() >= 4 or 100 / { 100 + SpellHaste() } < 0 } and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

AddFunction BalanceAoeCdActions
{
}

AddFunction BalanceAoeCdPostConditions
{
 { target.DebuffRemaining(stellar_empowerment_debuff) < GCD() * 2 or AstralPowerDeficit() < 22 or BuffRemaining(celestial_alignment_buff) > 8 or BuffRemaining(incarnation_chosen_of_elune_buff) > 8 or target.TimeToDie() < 8 } and Spell(starfall) or AstralPowerDeficit() > 14 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() > 24 and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() > 44 and SpellKnown(full_moon) and Spell(full_moon) or Spell(warrior_of_elune) or BuffPresent(warrior_of_elune_buff) and Spell(lunar_strike_balance) or BuffPresent(solar_empowerment_buff) and Spell(solar_wrath) or BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike_balance) or HasEquippedItem(lady_and_the_child) and Enemies() == 2 and 100 / { 100 + SpellHaste() } > 0 and not { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and Spell(moonfire) or { Enemies() >= 4 or 100 / { 100 + SpellHaste() } < 0 } and Spell(lunar_strike_balance) or Spell(solar_wrath)
}

### Balance icons.

AddCheckBox(opt_druid_balance_aoe L(AOE) default specialization=balance)

AddIcon checkbox=!opt_druid_balance_aoe enemies=1 help=shortcd specialization=balance
{
 if not InCombat() BalancePrecombatShortCdActions()
 unless not InCombat() and BalancePrecombatShortCdPostConditions()
 {
  BalanceDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_druid_balance_aoe help=shortcd specialization=balance
{
 if not InCombat() BalancePrecombatShortCdActions()
 unless not InCombat() and BalancePrecombatShortCdPostConditions()
 {
  BalanceDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=balance
{
 if not InCombat() BalancePrecombatMainActions()
 unless not InCombat() and BalancePrecombatMainPostConditions()
 {
  BalanceDefaultMainActions()
 }
}

AddIcon checkbox=opt_druid_balance_aoe help=aoe specialization=balance
{
 if not InCombat() BalancePrecombatMainActions()
 unless not InCombat() and BalancePrecombatMainPostConditions()
 {
  BalanceDefaultMainActions()
 }
}

AddIcon checkbox=!opt_druid_balance_aoe enemies=1 help=cd specialization=balance
{
 if not InCombat() BalancePrecombatCdActions()
 unless not InCombat() and BalancePrecombatCdPostConditions()
 {
  BalanceDefaultCdActions()
 }
}

AddIcon checkbox=opt_druid_balance_aoe help=cd specialization=balance
{
 if not InCombat() BalancePrecombatCdActions()
 unless not InCombat() and BalancePrecombatCdPostConditions()
 {
  BalanceDefaultCdActions()
 }
}

### Required symbols
# starsurge_moonkin
# celestial_alignment_buff
# incarnation_chosen_of_elune_buff
# astral_acceleration_buff
# solar_solstice_buff
# half_moon
# full_moon
# new_moon
# warrior_of_elune
# lunar_strike_balance
# warrior_of_elune_buff
# solar_wrath
# solar_empowerment_buff
# lunar_empowerment_buff
# moonkin_form
# blessing_of_elune
# potion_of_prolonged_power_potion
# incarnation_chosen_of_elune
# fury_of_elune
# fury_of_elune_up_buff
# astral_communion
# moonfire
# moonfire_debuff
# sunfire
# sunfire_debuff
# stellar_flare
# stellar_flare_debuff
# starfall
# stellar_flare_talent
# the_emerald_dreamcatcher_buff
# celestial_alignment
# natures_balance_talent
# oneths_overconfidence_buff
# blessing_of_the_ancients_talent
# blessing_of_elune_buff
# blessing_of_anshe_buff
# blood_fury_apsp
# berserking
# arcane_torrent_energy
# fury_of_elune_talent
# the_emerald_dreamcatcher
# oneths_intuition_buff
# stellar_drift_talent
# stellar_empowerment_debuff
# lady_and_the_child
]]
    OvaleScripts:RegisterScript("DRUID", "balance", name, desc, code, "script")
end
do
    local name = "sc_druid_feral_t19"
    local desc = "[7.0] Simulationcraft: Druid_Feral_T19"
    local code = [[
# Based on SimulationCraft profile "Druid_Feral_T19P".
#	class=druid
#	spec=feral
#	talents=3323322

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)


AddFunction use_thrash
{
 if HasEquippedItem(luffa_wrappings) 1
 0
}

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=feral)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=feral)

AddFunction FeralUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction FeralGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred)
 {
  if target.InRange(wild_charge) Spell(wild_charge)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.st_generators

AddFunction FeralStgeneratorsMainActions
{
 #regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&combo_points>=2&cooldown.ashamanes_frenzy.remains<gcd
 if Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() >= 2 and SpellCooldown(ashamanes_frenzy) < GCD() Spell(regrowth)
 #regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&combo_points=4&dot.rake.remains<4
 if Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() == 4 and target.DebuffRemaining(rake_debuff) < 4 Spell(regrowth)
 #regrowth,if=equipped.ailuro_pouncers&talent.bloodtalons.enabled&(buff.predatory_swiftness.stack>2|(buff.predatory_swiftness.stack>1&dot.rake.remains<3))&buff.bloodtalons.down
 if HasEquippedItem(ailuro_pouncers) and Talent(bloodtalons_talent) and { BuffStacks(predatory_swiftness_buff) > 2 or BuffStacks(predatory_swiftness_buff) > 1 and target.DebuffRemaining(rake_debuff) < 3 } and BuffExpires(bloodtalons_buff) Spell(regrowth)
 #brutal_slash,if=spell_targets.brutal_slash>desired_targets
 if Enemies() > Enemies(tagged=1) Spell(brutal_slash)
 #pool_resource,for_next=1
 #thrash_cat,if=(!ticking|remains<duration*0.3)&(spell_targets.thrash_cat>2)
 if { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and Enemies() > 2 Spell(thrash_cat)
 unless { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and Enemies() > 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
 {
  #pool_resource,for_next=1
  #rake,target_if=!ticking|(!talent.bloodtalons.enabled&remains<duration*0.3)&target.time_to_die>4
  if not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0 and target.TimeToDie() > 4 Spell(rake)
  unless { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0 and target.TimeToDie() > 4 } and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake)
  {
   #pool_resource,for_next=1
   #rake,target_if=talent.bloodtalons.enabled&buff.bloodtalons.up&((remains<=7)&persistent_multiplier>dot.rake.pmultiplier*0.85)&target.time_to_die>4
   if Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0 and target.TimeToDie() > 4 Spell(rake)
   unless Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0 and target.TimeToDie() > 4 and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake)
   {
    #brutal_slash,if=(buff.tigers_fury.up&(raid_event.adds.in>(1+max_charges-charges_fractional)*recharge_time))
    if BuffPresent(tigers_fury_buff) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * SpellChargeCooldown(brutal_slash) Spell(brutal_slash)
    #moonfire_cat,target_if=remains<=duration*0.3
    if target.DebuffRemaining(moonfire_cat_debuff) <= BaseDuration(moonfire_cat_debuff) * 0 Spell(moonfire_cat)
    #pool_resource,for_next=1
    #thrash_cat,if=(!ticking|remains<duration*0.3)&(variable.use_thrash=2|spell_targets.thrash_cat>1)
    if { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and { use_thrash() == 2 or Enemies() > 1 } Spell(thrash_cat)
    unless { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and { use_thrash() == 2 or Enemies() > 1 } and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
    {
     #thrash_cat,if=(!ticking|remains<duration*0.3)&variable.use_thrash=1&buff.clearcasting.react
     if { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and use_thrash() == 1 and BuffPresent(clearcasting_buff) Spell(thrash_cat)
     #pool_resource,for_next=1
     #swipe_cat,if=spell_targets.swipe_cat>1
     if Enemies() > 1 Spell(swipe_cat)
     unless Enemies() > 1 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat)
     {
      #shred
      Spell(shred)
     }
    }
   }
  }
 }
}

AddFunction FeralStgeneratorsMainPostConditions
{
}

AddFunction FeralStgeneratorsShortCdActions
{
}

AddFunction FeralStgeneratorsShortCdPostConditions
{
 Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() >= 2 and SpellCooldown(ashamanes_frenzy) < GCD() and Spell(regrowth) or Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() == 4 and target.DebuffRemaining(rake_debuff) < 4 and Spell(regrowth) or HasEquippedItem(ailuro_pouncers) and Talent(bloodtalons_talent) and { BuffStacks(predatory_swiftness_buff) > 2 or BuffStacks(predatory_swiftness_buff) > 1 and target.DebuffRemaining(rake_debuff) < 3 } and BuffExpires(bloodtalons_buff) and Spell(regrowth) or Enemies() > Enemies(tagged=1) and Spell(brutal_slash) or { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and Enemies() > 2 and Spell(thrash_cat) or not { { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and Enemies() > 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0 and target.TimeToDie() > 4 } and Spell(rake) or not { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0 and target.TimeToDie() > 4 } and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0 and target.TimeToDie() > 4 and Spell(rake) or not { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0 and target.TimeToDie() > 4 and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { BuffPresent(tigers_fury_buff) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * SpellChargeCooldown(brutal_slash) and Spell(brutal_slash) or target.DebuffRemaining(moonfire_cat_debuff) <= BaseDuration(moonfire_cat_debuff) * 0 and Spell(moonfire_cat) or { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and { use_thrash() == 2 or Enemies() > 1 } and Spell(thrash_cat) or not { { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and { use_thrash() == 2 or Enemies() > 1 } and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and use_thrash() == 1 and BuffPresent(clearcasting_buff) and Spell(thrash_cat) or Enemies() > 1 and Spell(swipe_cat) or not { Enemies() > 1 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and Spell(shred) } } } }
}

AddFunction FeralStgeneratorsCdActions
{
}

AddFunction FeralStgeneratorsCdPostConditions
{
 Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() >= 2 and SpellCooldown(ashamanes_frenzy) < GCD() and Spell(regrowth) or Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() == 4 and target.DebuffRemaining(rake_debuff) < 4 and Spell(regrowth) or HasEquippedItem(ailuro_pouncers) and Talent(bloodtalons_talent) and { BuffStacks(predatory_swiftness_buff) > 2 or BuffStacks(predatory_swiftness_buff) > 1 and target.DebuffRemaining(rake_debuff) < 3 } and BuffExpires(bloodtalons_buff) and Spell(regrowth) or Enemies() > Enemies(tagged=1) and Spell(brutal_slash) or { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and Enemies() > 2 and Spell(thrash_cat) or not { { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and Enemies() > 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0 and target.TimeToDie() > 4 } and Spell(rake) or not { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0 and target.TimeToDie() > 4 } and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0 and target.TimeToDie() > 4 and Spell(rake) or not { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0 and target.TimeToDie() > 4 and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { BuffPresent(tigers_fury_buff) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * SpellChargeCooldown(brutal_slash) and Spell(brutal_slash) or target.DebuffRemaining(moonfire_cat_debuff) <= BaseDuration(moonfire_cat_debuff) * 0 and Spell(moonfire_cat) or { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and { use_thrash() == 2 or Enemies() > 1 } and Spell(thrash_cat) or not { { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and { use_thrash() == 2 or Enemies() > 1 } and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { { not target.DebuffPresent(thrash_cat_debuff) or target.DebuffRemaining(thrash_cat_debuff) < BaseDuration(thrash_cat_debuff) * 0 } and use_thrash() == 1 and BuffPresent(clearcasting_buff) and Spell(thrash_cat) or Enemies() > 1 and Spell(swipe_cat) or not { Enemies() > 1 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and Spell(shred) } } } }
}

### actions.st_finishers

AddFunction FeralStfinishersMainActions
{
 #pool_resource,for_next=1
 #savage_roar,if=buff.savage_roar.down
 if BuffExpires(savage_roar_buff) Spell(savage_roar)
 unless BuffExpires(savage_roar_buff) and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar)
 {
  #pool_resource,for_next=1
  #rip,target_if=!ticking|(remains<=duration*0.3)&(target.health.pct>25&!talent.sabertooth.enabled)|(remains<=duration*0.8&persistent_multiplier>dot.rip.pmultiplier)&target.time_to_die>8
  if not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 Spell(rip)
  unless { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and SpellUsable(rip) and SpellCooldown(rip) < TimeToEnergyFor(rip)
  {
   #pool_resource,for_next=1
   #savage_roar,if=buff.savage_roar.remains<12
   if BuffRemaining(savage_roar_buff) < 12 Spell(savage_roar)
   unless BuffRemaining(savage_roar_buff) < 12 and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar)
   {
    #maim,if=buff.fiery_red_maimers.up
    if BuffPresent(fiery_red_maimers_buff) Spell(maim)
    #ferocious_bite,max_energy=1
    if Energy() >= EnergyCost(ferocious_bite max=1) Spell(ferocious_bite)
   }
  }
 }
}

AddFunction FeralStfinishersMainPostConditions
{
}

AddFunction FeralStfinishersShortCdActions
{
}

AddFunction FeralStfinishersShortCdPostConditions
{
 BuffExpires(savage_roar_buff) and Spell(savage_roar) or not { BuffExpires(savage_roar_buff) and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and Spell(rip) or not { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and SpellUsable(rip) and SpellCooldown(rip) < TimeToEnergyFor(rip) } and { BuffRemaining(savage_roar_buff) < 12 and Spell(savage_roar) or not { BuffRemaining(savage_roar_buff) < 12 and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { BuffPresent(fiery_red_maimers_buff) and Spell(maim) or Energy() >= EnergyCost(ferocious_bite max=1) and Spell(ferocious_bite) } } }
}

AddFunction FeralStfinishersCdActions
{
}

AddFunction FeralStfinishersCdPostConditions
{
 BuffExpires(savage_roar_buff) and Spell(savage_roar) or not { BuffExpires(savage_roar_buff) and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and Spell(rip) or not { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and SpellUsable(rip) and SpellCooldown(rip) < TimeToEnergyFor(rip) } and { BuffRemaining(savage_roar_buff) < 12 and Spell(savage_roar) or not { BuffRemaining(savage_roar_buff) < 12 and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { BuffPresent(fiery_red_maimers_buff) and Spell(maim) or Energy() >= EnergyCost(ferocious_bite max=1) and Spell(ferocious_bite) } } }
}

### actions.single_target

AddFunction FeralSingletargetMainActions
{
 #cat_form,if=!buff.cat_form.up
 if not BuffPresent(cat_form_buff) Spell(cat_form)
 #rake,if=buff.prowl.up|buff.shadowmeld.up
 if BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) Spell(rake)
 #call_action_list,name=cooldowns
 FeralCooldownsMainActions()

 unless FeralCooldownsMainPostConditions()
 {
  #regrowth,if=combo_points=5&talent.bloodtalons.enabled&buff.bloodtalons.down&(!buff.incarnation.up|dot.rip.remains<8|dot.rake.remains<5)
  if ComboPoints() == 5 and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not BuffPresent(incarnation_king_of_the_jungle_buff) or target.DebuffRemaining(rip_debuff) < 8 or target.DebuffRemaining(rake_debuff) < 5 } Spell(regrowth)
  #run_action_list,name=st_finishers,if=combo_points>4
  if ComboPoints() > 4 FeralStfinishersMainActions()

  unless ComboPoints() > 4 and FeralStfinishersMainPostConditions()
  {
   #run_action_list,name=st_generators
   FeralStgeneratorsMainActions()
  }
 }
}

AddFunction FeralSingletargetMainPostConditions
{
 FeralCooldownsMainPostConditions() or ComboPoints() > 4 and FeralStfinishersMainPostConditions() or FeralStgeneratorsMainPostConditions()
}

AddFunction FeralSingletargetShortCdActions
{
 unless not BuffPresent(cat_form_buff) and Spell(cat_form)
 {
  #auto_attack
  FeralGetInMeleeRange()

  unless { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
  {
   #call_action_list,name=cooldowns
   FeralCooldownsShortCdActions()

   unless FeralCooldownsShortCdPostConditions() or ComboPoints() == 5 and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not BuffPresent(incarnation_king_of_the_jungle_buff) or target.DebuffRemaining(rip_debuff) < 8 or target.DebuffRemaining(rake_debuff) < 5 } and Spell(regrowth)
   {
    #run_action_list,name=st_finishers,if=combo_points>4
    if ComboPoints() > 4 FeralStfinishersShortCdActions()

    unless ComboPoints() > 4 and FeralStfinishersShortCdPostConditions()
    {
     #run_action_list,name=st_generators
     FeralStgeneratorsShortCdActions()
    }
   }
  }
 }
}

AddFunction FeralSingletargetShortCdPostConditions
{
 not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake) or FeralCooldownsShortCdPostConditions() or ComboPoints() == 5 and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not BuffPresent(incarnation_king_of_the_jungle_buff) or target.DebuffRemaining(rip_debuff) < 8 or target.DebuffRemaining(rake_debuff) < 5 } and Spell(regrowth) or ComboPoints() > 4 and FeralStfinishersShortCdPostConditions() or FeralStgeneratorsShortCdPostConditions()
}

AddFunction FeralSingletargetCdActions
{
 unless not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
 {
  #call_action_list,name=cooldowns
  FeralCooldownsCdActions()

  unless FeralCooldownsCdPostConditions() or ComboPoints() == 5 and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not BuffPresent(incarnation_king_of_the_jungle_buff) or target.DebuffRemaining(rip_debuff) < 8 or target.DebuffRemaining(rake_debuff) < 5 } and Spell(regrowth)
  {
   #run_action_list,name=st_finishers,if=combo_points>4
   if ComboPoints() > 4 FeralStfinishersCdActions()

   unless ComboPoints() > 4 and FeralStfinishersCdPostConditions()
   {
    #run_action_list,name=st_generators
    FeralStgeneratorsCdActions()
   }
  }
 }
}

AddFunction FeralSingletargetCdPostConditions
{
 not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake) or FeralCooldownsCdPostConditions() or ComboPoints() == 5 and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not BuffPresent(incarnation_king_of_the_jungle_buff) or target.DebuffRemaining(rip_debuff) < 8 or target.DebuffRemaining(rake_debuff) < 5 } and Spell(regrowth) or ComboPoints() > 4 and FeralStfinishersCdPostConditions() or FeralStgeneratorsCdPostConditions()
}

### actions.precombat

AddFunction FeralPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #regrowth,if=talent.bloodtalons.enabled
 if Talent(bloodtalons_talent) Spell(regrowth)
 #variable,name=use_thrash,value=0
 #variable,name=use_thrash,value=1,if=equipped.luffa_wrappings
 #cat_form
 Spell(cat_form)
 #prowl
 Spell(prowl)
}

AddFunction FeralPrecombatMainPostConditions
{
}

AddFunction FeralPrecombatShortCdActions
{
}

AddFunction FeralPrecombatShortCdPostConditions
{
 Talent(bloodtalons_talent) and Spell(regrowth) or Spell(cat_form) or Spell(prowl)
}

AddFunction FeralPrecombatCdActions
{
 unless Talent(bloodtalons_talent) and Spell(regrowth) or Spell(cat_form) or Spell(prowl)
 {
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war_potion usable=1)
 }
}

AddFunction FeralPrecombatCdPostConditions
{
 Talent(bloodtalons_talent) and Spell(regrowth) or Spell(cat_form) or Spell(prowl)
}

### actions.cooldowns

AddFunction FeralCooldownsMainActions
{
}

AddFunction FeralCooldownsMainPostConditions
{
}

AddFunction FeralCooldownsShortCdActions
{
 #tigers_fury,if=energy.deficit>=60
 if EnergyDeficit() >= 60 Spell(tigers_fury)
 #elunes_guidance,if=combo_points=0&energy>=50
 if ComboPoints() == 0 and Energy() >= 50 Spell(elunes_guidance)
 #ashamanes_frenzy,if=combo_points>=2&(!talent.bloodtalons.enabled|buff.bloodtalons.up)
 if ComboPoints() >= 2 and { not Talent(bloodtalons_talent) or BuffPresent(bloodtalons_buff) } Spell(ashamanes_frenzy)
}

AddFunction FeralCooldownsShortCdPostConditions
{
}

AddFunction FeralCooldownsCdActions
{
 #dash,if=!buff.cat_form.up
 if not BuffPresent(cat_form_buff) Spell(dash)
 #berserk,if=energy>=30&(cooldown.tigers_fury.remains>5|buff.tigers_fury.up)
 if Energy() >= 30 and { SpellCooldown(tigers_fury) > 5 or BuffPresent(tigers_fury_buff) } Spell(berserk_cat)

 unless EnergyDeficit() >= 60 and Spell(tigers_fury) or ComboPoints() == 0 and Energy() >= 50 and Spell(elunes_guidance)
 {
  #incarnation,if=energy>=30&(cooldown.tigers_fury.remains>15|buff.tigers_fury.up)
  if Energy() >= 30 and { SpellCooldown(tigers_fury) > 15 or BuffPresent(tigers_fury_buff) } Spell(incarnation_king_of_the_jungle)
  #potion,name=prolonged_power,if=target.time_to_die<65|(time_to_die<180&(buff.berserk.up|buff.incarnation.up))
  if { target.TimeToDie() < 65 or target.TimeToDie() < 180 and { BuffPresent(berserk_cat_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) } } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)

  unless ComboPoints() >= 2 and { not Talent(bloodtalons_talent) or BuffPresent(bloodtalons_buff) } and Spell(ashamanes_frenzy)
  {
   #shadowmeld,if=combo_points<5&energy>=action.rake.cost&dot.rake.pmultiplier<2.1&buff.tigers_fury.up&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(!talent.incarnation.enabled|cooldown.incarnation.remains>18)&!buff.incarnation.up
   if ComboPoints() < 5 and Energy() >= PowerCost(rake) and target.DebuffPersistentMultiplier(rake_debuff) < 2 and BuffPresent(tigers_fury_buff) and { BuffPresent(bloodtalons_buff) or not Talent(bloodtalons_talent) } and { not Talent(incarnation_talent) or SpellCooldown(incarnation_king_of_the_jungle) > 18 } and not BuffPresent(incarnation_king_of_the_jungle_buff) Spell(shadowmeld)
   #use_items
   FeralUseItemActions()
  }
 }
}

AddFunction FeralCooldownsCdPostConditions
{
 EnergyDeficit() >= 60 and Spell(tigers_fury) or ComboPoints() == 0 and Energy() >= 50 and Spell(elunes_guidance) or ComboPoints() >= 2 and { not Talent(bloodtalons_talent) or BuffPresent(bloodtalons_buff) } and Spell(ashamanes_frenzy)
}

### actions.default

AddFunction FeralDefaultMainActions
{
 #run_action_list,name=single_target,if=dot.rip.ticking|time>15
 if target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 FeralSingletargetMainActions()

 unless { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetMainPostConditions()
 {
  #rake,if=!ticking|buff.prowl.up
  if not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) Spell(rake)
  #moonfire_cat,if=talent.lunar_inspiration.enabled&!ticking
  if Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) Spell(moonfire_cat)
  #savage_roar,if=!buff.savage_roar.up
  if not BuffPresent(savage_roar_buff) Spell(savage_roar)
  #regrowth,if=(talent.sabertooth.enabled|buff.predatory_swiftness.up)&talent.bloodtalons.enabled&buff.bloodtalons.down&combo_points=5
  if { Talent(sabertooth_talent) or BuffPresent(predatory_swiftness_buff) } and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and ComboPoints() == 5 Spell(regrowth)
  #rip,if=combo_points=5
  if ComboPoints() == 5 Spell(rip)
  #thrash_cat,if=!ticking&variable.use_thrash>0
  if not target.DebuffPresent(thrash_cat_debuff) and use_thrash() > 0 Spell(thrash_cat)
  #shred
  Spell(shred)
 }
}

AddFunction FeralDefaultMainPostConditions
{
 { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetMainPostConditions()
}

AddFunction FeralDefaultShortCdActions
{
 #run_action_list,name=single_target,if=dot.rip.ticking|time>15
 if target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 FeralSingletargetShortCdActions()

 unless { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetShortCdPostConditions() or { not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) } and Spell(rake)
 {
  #auto_attack
  FeralGetInMeleeRange()

  unless Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) or not BuffPresent(savage_roar_buff) and Spell(savage_roar)
  {
   #tigers_fury
   Spell(tigers_fury)
   #ashamanes_frenzy
   Spell(ashamanes_frenzy)
  }
 }
}

AddFunction FeralDefaultShortCdPostConditions
{
 { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetShortCdPostConditions() or { not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) } and Spell(rake) or Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) or not BuffPresent(savage_roar_buff) and Spell(savage_roar) or { Talent(sabertooth_talent) or BuffPresent(predatory_swiftness_buff) } and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and ComboPoints() == 5 and Spell(regrowth) or ComboPoints() == 5 and Spell(rip) or not target.DebuffPresent(thrash_cat_debuff) and use_thrash() > 0 and Spell(thrash_cat) or Spell(shred)
}

AddFunction FeralDefaultCdActions
{
 #run_action_list,name=single_target,if=dot.rip.ticking|time>15
 if target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 FeralSingletargetCdActions()

 unless { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetCdPostConditions() or { not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) } and Spell(rake)
 {
  #dash,if=!buff.cat_form.up
  if not BuffPresent(cat_form_buff) Spell(dash)

  unless Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) or not BuffPresent(savage_roar_buff) and Spell(savage_roar)
  {
   #berserk
   Spell(berserk_cat)
   #incarnation
   Spell(incarnation_king_of_the_jungle)
  }
 }
}

AddFunction FeralDefaultCdPostConditions
{
 { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetCdPostConditions() or { not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) } and Spell(rake) or Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) or not BuffPresent(savage_roar_buff) and Spell(savage_roar) or Spell(tigers_fury) or Spell(ashamanes_frenzy) or { Talent(sabertooth_talent) or BuffPresent(predatory_swiftness_buff) } and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and ComboPoints() == 5 and Spell(regrowth) or ComboPoints() == 5 and Spell(rip) or not target.DebuffPresent(thrash_cat_debuff) and use_thrash() > 0 and Spell(thrash_cat) or Spell(shred)
}

### Feral icons.

AddCheckBox(opt_druid_feral_aoe L(AOE) default specialization=feral)

AddIcon checkbox=!opt_druid_feral_aoe enemies=1 help=shortcd specialization=feral
{
 if not InCombat() FeralPrecombatShortCdActions()
 unless not InCombat() and FeralPrecombatShortCdPostConditions()
 {
  FeralDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_druid_feral_aoe help=shortcd specialization=feral
{
 if not InCombat() FeralPrecombatShortCdActions()
 unless not InCombat() and FeralPrecombatShortCdPostConditions()
 {
  FeralDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=feral
{
 if not InCombat() FeralPrecombatMainActions()
 unless not InCombat() and FeralPrecombatMainPostConditions()
 {
  FeralDefaultMainActions()
 }
}

AddIcon checkbox=opt_druid_feral_aoe help=aoe specialization=feral
{
 if not InCombat() FeralPrecombatMainActions()
 unless not InCombat() and FeralPrecombatMainPostConditions()
 {
  FeralDefaultMainActions()
 }
}

AddIcon checkbox=!opt_druid_feral_aoe enemies=1 help=cd specialization=feral
{
 if not InCombat() FeralPrecombatCdActions()
 unless not InCombat() and FeralPrecombatCdPostConditions()
 {
  FeralDefaultCdActions()
 }
}

AddIcon checkbox=opt_druid_feral_aoe help=cd specialization=feral
{
 if not InCombat() FeralPrecombatCdActions()
 unless not InCombat() and FeralPrecombatCdPostConditions()
 {
  FeralDefaultCdActions()
 }
}

### Required symbols
# regrowth
# bloodtalons_talent
# predatory_swiftness_buff
# bloodtalons_buff
# ashamanes_frenzy
# rake_debuff
# ailuro_pouncers
# brutal_slash
# thrash_cat
# thrash_cat_debuff
# rake
# tigers_fury_buff
# moonfire_cat
# moonfire_cat_debuff
# clearcasting_buff
# swipe_cat
# shred
# savage_roar
# savage_roar_buff
# rip
# rip_debuff
# sabertooth_talent
# maim
# fiery_red_maimers_buff
# ferocious_bite
# cat_form
# cat_form_buff
# prowl_buff
# shadowmeld_buff
# incarnation_king_of_the_jungle_buff
# luffa_wrappings
# prowl
# old_war_potion
# dash
# berserk_cat
# tigers_fury
# elunes_guidance
# incarnation_king_of_the_jungle
# prolonged_power_potion
# berserk_cat_buff
# shadowmeld
# incarnation_talent
# lunar_inspiration_talent
# mangle
# wild_charge
# wild_charge_bear
# wild_charge_cat
]]
    OvaleScripts:RegisterScript("DRUID", "feral", name, desc, code, "script")
end
do
    local name = "sc_druid_guardian_t19"
    local desc = "[7.0] Simulationcraft: Druid_Guardian_T19"
    local code = [[
# Based on SimulationCraft profile "Druid_Guardian_T19P".
#	class=druid
#	spec=guardian
#	talents=3323323

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=guardian)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=guardian)

AddFunction GuardianUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction GuardianGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred)
 {
  if target.InRange(wild_charge) Spell(wild_charge)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.precombat

AddFunction GuardianPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #bear_form
 Spell(bear_form)
}

AddFunction GuardianPrecombatMainPostConditions
{
}

AddFunction GuardianPrecombatShortCdActions
{
}

AddFunction GuardianPrecombatShortCdPostConditions
{
 Spell(bear_form)
}

AddFunction GuardianPrecombatCdActions
{
 unless Spell(bear_form)
 {
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war_potion usable=1)
 }
}

AddFunction GuardianPrecombatCdPostConditions
{
 Spell(bear_form)
}

### actions.default

AddFunction GuardianDefaultMainActions
{
 #frenzied_regeneration,if=incoming_damage_5s%health.max>=0.5|health<=health.max*0.4
 if IncomingDamage(5) / MaxHealth() >= 0 or Health() <= MaxHealth() * 0 Spell(frenzied_regeneration)
 #ironfur,if=(buff.ironfur.up=0)|(buff.gory_fur.up=1)|(rage>=80)
 if BuffPresent(ironfur_buff) == 0 or BuffPresent(gory_fur_buff) == 1 or Rage() >= 80 Spell(ironfur)
 #moonfire,if=buff.incarnation.up=1&dot.moonfire.remains<=4.8
 if BuffPresent(incarnation_guardian_of_ursoc_buff) == 1 and target.DebuffRemaining(moonfire_debuff) <= 4 Spell(moonfire)
 #thrash_bear,if=buff.incarnation.up=1&dot.thrash.remains<=4.5
 if BuffPresent(incarnation_guardian_of_ursoc_buff) == 1 and target.DebuffRemaining(thrash_bear_debuff) <= 4 Spell(thrash_bear)
 #mangle
 Spell(mangle)
 #thrash_bear
 Spell(thrash_bear)
 #pulverize,if=buff.pulverize.up=0|buff.pulverize.remains<=6
 if { BuffPresent(pulverize_buff) == 0 or BuffRemaining(pulverize_buff) <= 6 } and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) Spell(pulverize)
 #moonfire,if=buff.galactic_guardian.up=1&(!ticking|dot.moonfire.remains<=4.8)
 if BuffPresent(galactic_guardian_buff) == 1 and { not target.DebuffPresent(moonfire_debuff) or target.DebuffRemaining(moonfire_debuff) <= 4 } Spell(moonfire)
 #moonfire,if=buff.galactic_guardian.up=1
 if BuffPresent(galactic_guardian_buff) == 1 Spell(moonfire)
 #moonfire,if=dot.moonfire.remains<=4.8
 if target.DebuffRemaining(moonfire_debuff) <= 4 Spell(moonfire)
 #swipe_bear
 Spell(swipe_bear)
}

AddFunction GuardianDefaultMainPostConditions
{
}

AddFunction GuardianDefaultShortCdActions
{
 #auto_attack
 GuardianGetInMeleeRange()
 #rage_of_the_sleeper
 Spell(rage_of_the_sleeper)
 #lunar_beam
 Spell(lunar_beam)

 unless { IncomingDamage(5) / MaxHealth() >= 0 or Health() <= MaxHealth() * 0 } and Spell(frenzied_regeneration)
 {
  #bristling_fur,if=buff.ironfur.stack=1|buff.ironfur.down
  if BuffStacks(ironfur_buff) == 1 or BuffExpires(ironfur_buff) Spell(bristling_fur)
 }
}

AddFunction GuardianDefaultShortCdPostConditions
{
 { IncomingDamage(5) / MaxHealth() >= 0 or Health() <= MaxHealth() * 0 } and Spell(frenzied_regeneration) or { BuffPresent(ironfur_buff) == 0 or BuffPresent(gory_fur_buff) == 1 or Rage() >= 80 } and Spell(ironfur) or BuffPresent(incarnation_guardian_of_ursoc_buff) == 1 and target.DebuffRemaining(moonfire_debuff) <= 4 and Spell(moonfire) or BuffPresent(incarnation_guardian_of_ursoc_buff) == 1 and target.DebuffRemaining(thrash_bear_debuff) <= 4 and Spell(thrash_bear) or Spell(mangle) or Spell(thrash_bear) or { BuffPresent(pulverize_buff) == 0 or BuffRemaining(pulverize_buff) <= 6 } and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or BuffPresent(galactic_guardian_buff) == 1 and { not target.DebuffPresent(moonfire_debuff) or target.DebuffRemaining(moonfire_debuff) <= 4 } and Spell(moonfire) or BuffPresent(galactic_guardian_buff) == 1 and Spell(moonfire) or target.DebuffRemaining(moonfire_debuff) <= 4 and Spell(moonfire) or Spell(swipe_bear)
}

AddFunction GuardianDefaultCdActions
{
 #blood_fury
 Spell(blood_fury_apsp)
 #berserking
 Spell(berserking)
 #arcane_torrent
 Spell(arcane_torrent_energy)
 #use_item,slot=trinket2
 GuardianUseItemActions()
 #incarnation
 Spell(incarnation_guardian_of_ursoc)
}

AddFunction GuardianDefaultCdPostConditions
{
 Spell(rage_of_the_sleeper) or Spell(lunar_beam) or { IncomingDamage(5) / MaxHealth() >= 0 or Health() <= MaxHealth() * 0 } and Spell(frenzied_regeneration) or { BuffStacks(ironfur_buff) == 1 or BuffExpires(ironfur_buff) } and Spell(bristling_fur) or { BuffPresent(ironfur_buff) == 0 or BuffPresent(gory_fur_buff) == 1 or Rage() >= 80 } and Spell(ironfur) or BuffPresent(incarnation_guardian_of_ursoc_buff) == 1 and target.DebuffRemaining(moonfire_debuff) <= 4 and Spell(moonfire) or BuffPresent(incarnation_guardian_of_ursoc_buff) == 1 and target.DebuffRemaining(thrash_bear_debuff) <= 4 and Spell(thrash_bear) or Spell(mangle) or Spell(thrash_bear) or { BuffPresent(pulverize_buff) == 0 or BuffRemaining(pulverize_buff) <= 6 } and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or BuffPresent(galactic_guardian_buff) == 1 and { not target.DebuffPresent(moonfire_debuff) or target.DebuffRemaining(moonfire_debuff) <= 4 } and Spell(moonfire) or BuffPresent(galactic_guardian_buff) == 1 and Spell(moonfire) or target.DebuffRemaining(moonfire_debuff) <= 4 and Spell(moonfire) or Spell(swipe_bear)
}

### Guardian icons.

AddCheckBox(opt_druid_guardian_aoe L(AOE) default specialization=guardian)

AddIcon checkbox=!opt_druid_guardian_aoe enemies=1 help=shortcd specialization=guardian
{
 if not InCombat() GuardianPrecombatShortCdActions()
 unless not InCombat() and GuardianPrecombatShortCdPostConditions()
 {
  GuardianDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_druid_guardian_aoe help=shortcd specialization=guardian
{
 if not InCombat() GuardianPrecombatShortCdActions()
 unless not InCombat() and GuardianPrecombatShortCdPostConditions()
 {
  GuardianDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=guardian
{
 if not InCombat() GuardianPrecombatMainActions()
 unless not InCombat() and GuardianPrecombatMainPostConditions()
 {
  GuardianDefaultMainActions()
 }
}

AddIcon checkbox=opt_druid_guardian_aoe help=aoe specialization=guardian
{
 if not InCombat() GuardianPrecombatMainActions()
 unless not InCombat() and GuardianPrecombatMainPostConditions()
 {
  GuardianDefaultMainActions()
 }
}

AddIcon checkbox=!opt_druid_guardian_aoe enemies=1 help=cd specialization=guardian
{
 if not InCombat() GuardianPrecombatCdActions()
 unless not InCombat() and GuardianPrecombatCdPostConditions()
 {
  GuardianDefaultCdActions()
 }
}

AddIcon checkbox=opt_druid_guardian_aoe help=cd specialization=guardian
{
 if not InCombat() GuardianPrecombatCdActions()
 unless not InCombat() and GuardianPrecombatCdPostConditions()
 {
  GuardianDefaultCdActions()
 }
}

### Required symbols
# bear_form
# old_war_potion
# blood_fury_apsp
# berserking
# arcane_torrent_energy
# incarnation_guardian_of_ursoc
# rage_of_the_sleeper
# lunar_beam
# frenzied_regeneration
# bristling_fur
# ironfur_buff
# ironfur
# gory_fur_buff
# moonfire
# incarnation_guardian_of_ursoc_buff
# moonfire_debuff
# thrash_bear
# thrash_bear_debuff
# mangle
# pulverize
# pulverize_buff
# galactic_guardian_buff
# swipe_bear
# shred
# wild_charge
# wild_charge_bear
# wild_charge_cat
]]
    OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
end
