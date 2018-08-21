local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "icyveins_druid_guardian"
    local desc = "[7.3.2] Icy-Veins: Druid Guardian"
    local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=guardian)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=guardian)
AddCheckBox(opt_druid_guardian_aoe L(AOE) default specialization=guardian)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=guardian)

AddFunction FrenziedRegenHealModifier
{
	(1+Versatility()/100) * 
	(1+0.20*BuffPresent(guardian_of_elune_buff)) * 
	(1+0.05*ArtifactTraitRank(wildflesh_trait)) *
	(1+0.12*HasEquippedItem(skysecs_hold)) * 
	# Guardian Spirit
	(1+0.40*BuffPresent(47788)) *
	# Divine Hymn
	(1+0.1*BuffPresent(64844)) *
	# Protection of Tyr
	(1+0.15*BuffPresent(211210)) *
	# Life Cocoon 
	(1+0.5*BuffPresent(116849)) *
	# T21
	(1+0.1*BuffPresent(253575)) *
	1
}

AddFunction FrenziedRegenHealTotal
{
	IncomingDamage(5) / 2
}

AddFunction GuardianHealMe
{
	unless(DebuffPresent(healing_immunity_debuff)) 
	{
		if BuffExpires(frenzied_regeneration_buff) and HealthPercent() <= 70 
		{
			if (FrenziedRegenHealTotal() >= MaxHealth() * 0.20) Spell(frenzied_regeneration)
		}
		
		if HealthPercent() <= 50 Spell(lunar_beam)
		if HealthPercent() <= 80 and not InCombat() Spell(regrowth)
		if HealthPercent() < 35 UseHealthPotions()
	}
}

AddFunction GuardianGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and (Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred))
	{
		if target.InRange(wild_charge) Spell(wild_charge)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction GuardianDefaultShortCDActions
{
	GuardianHealMe()
	if IncomingDamage(5 physical=1) Spell(ironfur)
	GuardianGetInMeleeRange()
}

#
# Single-Target
#

AddFunction GuardianDefaultMainActions
{
	if not Stance(druid_bear_form) Spell(bear_form)
	if not BuffExpires(incarnation_guardian_of_ursoc_buff) 
	{
		if (BuffRefreshable(pulverize_buff)) Spell(pulverize)
		if target.DebuffStacks(thrash_bear_debuff) < SpellData(thrash_bear_debuff max_stacks) Spell(thrash_bear)
		if Talent(soul_of_the_forest_talent) Spell(mangle)
		Spell(thrash_bear)
	}
	
	Spell(mangle)
	if not BuffExpires(galactic_guardian_buff) Spell(moonfire)
	Spell(thrash_bear)
	if (BuffRefreshable(pulverize_buff) or target.DebuffStacks(thrash_bear_debuff) >= 5) Spell(pulverize)
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
	
	if not BuffExpires(incarnation_guardian_of_ursoc_buff) 
	{
		if (BuffRefreshable(pulverize_buff)) Spell(pulverize)
		if target.DebuffStacks(thrash_bear_debuff) < SpellData(thrash_bear_debuff max_stacks) Spell(thrash_bear)
		if Talent(soul_of_the_forest_talent) and Enemies() <= 3 Spell(mangle)
		Spell(thrash_bear)
	}
	
	Spell(thrash_bear)
	Spell(mangle)
	if not BuffExpires(galactic_guardian_buff) Spell(moonfire)
	if (BuffRefreshable(pulverize_buff) or target.DebuffStacks(thrash_bear_debuff) >= 5) Spell(pulverize)
	if Enemies() <= 3 and target.DebuffRefreshable(moonfire_debuff) Spell(moonfire)
	if Enemies() <= 3 and RageDeficit() <= 20 Spell(maul)
	Spell(swipe_bear)
}

AddFunction GuardianDefaultCdActions 
{
	GuardianInterruptActions()
	Spell(incarnation_guardian_of_ursoc)
	if HasArtifactTrait(embrace_of_the_nightmare) Spell(rage_of_the_sleeper)
	if BuffExpires(bristling_fur_buff) and BuffExpires(survival_instincts_buff) and BuffExpires(rage_of_the_sleeper_buff) and BuffExpires(barkskin_buff) and BuffExpires(potion_buff)
	{
		Spell(bristling_fur)
		if (HasEquippedItem(shifting_cosmic_sliver)) Spell(survival_instincts)
		Item(Trinket0Slot usable=1 text=13)
		Item(Trinket1Slot usable=1 text=14)
		Spell(survival_instincts)
		Spell(rage_of_the_sleeper)
		Spell(barkskin)
		if CheckBoxOn(opt_use_consumables) Item(unbending_potion usable=1)
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
        EnergyRegenRate() > 0 and target.DebuffRemaining(rake_debuff) > { PowerCost(shred) + PowerCost(rake) - Energy() } / EnergyRegenRate()
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
    local name = "sc_pr_druid_balance"
    local desc = "[8.0] Simulationcraft: PR_Druid_Balance"
    local code = [[
# Based on SimulationCraft profile "PR_Druid_Balance".
#	class=druid
#	spec=balance
#	talents=2000231

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

### actions.st

AddFunction BalanceStMainActions
{
 #fury_of_elune,if=(((raid_event.adds.duration%8)*(4)<(raid_event.adds.in%60))|(raid_event.adds.up))&((buff.celestial_alignment.up|buff.incarnation.up)|(cooldown.celestial_alignment.remains>30|cooldown.incarnation.remains>30))
 if { 10 / 8 * 4 < 600 / 60 or False(raid_event_adds_exists) } and { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } Spell(fury_of_elune)
 #moonfire,target_if=refreshable,if=target.time_to_die>8
 if target.Refreshable(moonfire_debuff) and target.TimeToDie() > 8 Spell(moonfire)
 #sunfire,target_if=refreshable,if=target.time_to_die>8
 if target.Refreshable(sunfire_debuff) and target.TimeToDie() > 8 Spell(sunfire)
 #stellar_flare,target_if=refreshable,if=target.time_to_die>10
 if target.Refreshable(stellar_flare_debuff) and target.TimeToDie() > 10 Spell(stellar_flare)
 #solar_wrath,if=(buff.solar_empowerment.stack=3|buff.solar_empowerment.stack=2&buff.lunar_empowerment.stack=2&astral_power>=40)&astral_power.deficit>10
 if { BuffStacks(solar_empowerment_buff) == 3 or BuffStacks(solar_empowerment_buff) == 2 and BuffStacks(lunar_empowerment_buff) == 2 and AstralPower() >= 40 } and AstralPowerDeficit() > 10 Spell(solar_wrath)
 #lunar_strike,if=buff.lunar_empowerment.stack=3&astral_power.deficit>14
 if BuffStacks(lunar_empowerment_buff) == 3 and AstralPowerDeficit() > 14 Spell(lunar_strike)
 #starfall,if=buff.oneths_overconfidence.react
 if BuffPresent(oneths_overconfidence_buff) Spell(starfall)
 #starsurge,if=!buff.starlord.up|buff.starlord.remains>=4|(gcd.max*(astral_power%40))>target.time_to_die
 if not BuffPresent(starlord_buff) or BuffRemaining(starlord_buff) >= 4 or GCD() * { AstralPower() / 40 } > target.TimeToDie() Spell(starsurge)
 #lunar_strike,if=(buff.warrior_of_elune.up|!buff.solar_empowerment.up)&buff.lunar_empowerment.up
 if { BuffPresent(warrior_of_elune_buff) or not BuffPresent(solar_empowerment_buff) } and BuffPresent(lunar_empowerment_buff) Spell(lunar_strike)
 #new_moon,if=astral_power.deficit>10
 if AstralPowerDeficit() > 10 and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
 #half_moon,if=astral_power.deficit>20
 if AstralPowerDeficit() > 20 and SpellKnown(half_moon) Spell(half_moon)
 #full_moon,if=astral_power.deficit>40
 if AstralPowerDeficit() > 40 and SpellKnown(full_moon) Spell(full_moon)
 #solar_wrath
 Spell(solar_wrath)
 #moonfire
 Spell(moonfire)
}

AddFunction BalanceStMainPostConditions
{
}

AddFunction BalanceStShortCdActions
{
 unless { 10 / 8 * 4 < 600 / 60 or False(raid_event_adds_exists) } and { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and Spell(fury_of_elune)
 {
  #force_of_nature,if=(buff.celestial_alignment.up|buff.incarnation.up)|(cooldown.celestial_alignment.remains>30|cooldown.incarnation.remains>30)
  if BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 Spell(force_of_nature)
 }
}

AddFunction BalanceStShortCdPostConditions
{
 { 10 / 8 * 4 < 600 / 60 or False(raid_event_adds_exists) } and { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and Spell(fury_of_elune) or target.Refreshable(moonfire_debuff) and target.TimeToDie() > 8 and Spell(moonfire) or target.Refreshable(sunfire_debuff) and target.TimeToDie() > 8 and Spell(sunfire) or target.Refreshable(stellar_flare_debuff) and target.TimeToDie() > 10 and Spell(stellar_flare) or { BuffStacks(solar_empowerment_buff) == 3 or BuffStacks(solar_empowerment_buff) == 2 and BuffStacks(lunar_empowerment_buff) == 2 and AstralPower() >= 40 } and AstralPowerDeficit() > 10 and Spell(solar_wrath) or BuffStacks(lunar_empowerment_buff) == 3 and AstralPowerDeficit() > 14 and Spell(lunar_strike) or BuffPresent(oneths_overconfidence_buff) and Spell(starfall) or { not BuffPresent(starlord_buff) or BuffRemaining(starlord_buff) >= 4 or GCD() * { AstralPower() / 40 } > target.TimeToDie() } and Spell(starsurge) or { BuffPresent(warrior_of_elune_buff) or not BuffPresent(solar_empowerment_buff) } and BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike) or AstralPowerDeficit() > 10 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() > 20 and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() > 40 and SpellKnown(full_moon) and Spell(full_moon) or Spell(solar_wrath) or Spell(moonfire)
}

AddFunction BalanceStCdActions
{
}

AddFunction BalanceStCdPostConditions
{
 { 10 / 8 * 4 < 600 / 60 or False(raid_event_adds_exists) } and { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and Spell(fury_of_elune) or { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and Spell(force_of_nature) or target.Refreshable(moonfire_debuff) and target.TimeToDie() > 8 and Spell(moonfire) or target.Refreshable(sunfire_debuff) and target.TimeToDie() > 8 and Spell(sunfire) or target.Refreshable(stellar_flare_debuff) and target.TimeToDie() > 10 and Spell(stellar_flare) or { BuffStacks(solar_empowerment_buff) == 3 or BuffStacks(solar_empowerment_buff) == 2 and BuffStacks(lunar_empowerment_buff) == 2 and AstralPower() >= 40 } and AstralPowerDeficit() > 10 and Spell(solar_wrath) or BuffStacks(lunar_empowerment_buff) == 3 and AstralPowerDeficit() > 14 and Spell(lunar_strike) or BuffPresent(oneths_overconfidence_buff) and Spell(starfall) or { not BuffPresent(starlord_buff) or BuffRemaining(starlord_buff) >= 4 or GCD() * { AstralPower() / 40 } > target.TimeToDie() } and Spell(starsurge) or { BuffPresent(warrior_of_elune_buff) or not BuffPresent(solar_empowerment_buff) } and BuffPresent(lunar_empowerment_buff) and Spell(lunar_strike) or AstralPowerDeficit() > 10 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() > 20 and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() > 40 and SpellKnown(full_moon) and Spell(full_moon) or Spell(solar_wrath) or Spell(moonfire)
}

### actions.precombat

AddFunction BalancePrecombatMainActions
{
 #flask
 #food
 #augmentation
 #moonkin_form
 Spell(moonkin_form)
 #solar_wrath
 Spell(solar_wrath)
}

AddFunction BalancePrecombatMainPostConditions
{
}

AddFunction BalancePrecombatShortCdActions
{
}

AddFunction BalancePrecombatShortCdPostConditions
{
 Spell(moonkin_form) or Spell(solar_wrath)
}

AddFunction BalancePrecombatCdActions
{
 unless Spell(moonkin_form)
 {
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(rising_death usable=1)
 }
}

AddFunction BalancePrecombatCdPostConditions
{
 Spell(moonkin_form) or Spell(solar_wrath)
}

### actions.ed

AddFunction BalanceEdMainActions
{
 #incarnation,if=astral_power>=30
 if AstralPower() >= 30 Spell(incarnation)
 #fury_of_elune,if=(buff.celestial_alignment.up|buff.incarnation.up)|(cooldown.celestial_alignment.remains>30|cooldown.incarnation.remains>30)&(buff.the_emerald_dreamcatcher.remains>gcd.max|!buff.the_emerald_dreamcatcher.up)
 if BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or { SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } Spell(fury_of_elune)
 #starsurge,if=(gcd.max*astral_power%30)>target.time_to_die
 if GCD() * AstralPower() / 30 > target.TimeToDie() Spell(starsurge)
 #moonfire,target_if=refreshable,if=buff.the_emerald_dreamcatcher.remains>gcd.max|!buff.the_emerald_dreamcatcher.up
 if target.Refreshable(moonfire_debuff) and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } Spell(moonfire)
 #sunfire,target_if=refreshable,if=buff.the_emerald_dreamcatcher.remains>gcd.max|!buff.the_emerald_dreamcatcher.up
 if target.Refreshable(sunfire_debuff) and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } Spell(sunfire)
 #stellar_flare,target_if=refreshable,if=buff.the_emerald_dreamcatcher.remains>gcd.max|!buff.the_emerald_dreamcatcher.up
 if target.Refreshable(stellar_flare_debuff) and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } Spell(stellar_flare)
 #starfall,if=buff.oneths_overconfidence.up&(buff.the_emerald_dreamcatcher.remains>gcd.max|!buff.the_emerald_dreamcatcher.up)
 if BuffPresent(oneths_overconfidence_buff) and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } Spell(starfall)
 #new_moon,if=buff.the_emerald_dreamcatcher.remains>execute_time|!buff.the_emerald_dreamcatcher.up
 if { BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(new_moon) or not BuffPresent(the_emerald_dreamcatcher_buff) } and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
 #half_moon,if=astral_power.deficit>=20&(buff.the_emerald_dreamcatcher.remains>execute_time|!buff.the_emerald_dreamcatcher.up)
 if AstralPowerDeficit() >= 20 and { BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(half_moon) or not BuffPresent(the_emerald_dreamcatcher_buff) } and SpellKnown(half_moon) Spell(half_moon)
 #full_moon,if=astral_power.deficit>=40&(buff.the_emerald_dreamcatcher.remains>execute_time|!buff.the_emerald_dreamcatcher.up)
 if AstralPowerDeficit() >= 40 and { BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(full_moon) or not BuffPresent(the_emerald_dreamcatcher_buff) } and SpellKnown(full_moon) Spell(full_moon)
 #lunar_strike,,if=buff.lunar_empowerment.up&buff.the_emerald_dreamcatcher.remains>execute_time
 if BuffPresent(lunar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(lunar_strike) Spell(lunar_strike)
 #solar_wrath,if=buff.solar_empowerment.up&buff.the_emerald_dreamcatcher.remains>execute_time
 if BuffPresent(solar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(solar_wrath) Spell(solar_wrath)
 #starsurge,if=(buff.the_emerald_dreamcatcher.up&buff.the_emerald_dreamcatcher.remains<gcd.max)|astral_power>=50
 if BuffPresent(the_emerald_dreamcatcher_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) < GCD() or AstralPower() >= 50 Spell(starsurge)
 #solar_wrath
 Spell(solar_wrath)
}

AddFunction BalanceEdMainPostConditions
{
}

AddFunction BalanceEdShortCdActions
{
 unless AstralPower() >= 30 and Spell(incarnation) or { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or { SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } } and Spell(fury_of_elune)
 {
  #force_of_nature,if=(buff.celestial_alignment.up|buff.incarnation.up)|(cooldown.celestial_alignment.remains>30|cooldown.incarnation.remains>30)&(buff.the_emerald_dreamcatcher.remains>gcd.max|!buff.the_emerald_dreamcatcher.up)
  if BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or { SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } Spell(force_of_nature)
 }
}

AddFunction BalanceEdShortCdPostConditions
{
 AstralPower() >= 30 and Spell(incarnation) or { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or { SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } } and Spell(fury_of_elune) or GCD() * AstralPower() / 30 > target.TimeToDie() and Spell(starsurge) or target.Refreshable(moonfire_debuff) and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(moonfire) or target.Refreshable(sunfire_debuff) and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(sunfire) or target.Refreshable(stellar_flare_debuff) and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(stellar_flare) or BuffPresent(oneths_overconfidence_buff) and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(starfall) or { BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(new_moon) or not BuffPresent(the_emerald_dreamcatcher_buff) } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() >= 20 and { BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(half_moon) or not BuffPresent(the_emerald_dreamcatcher_buff) } and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() >= 40 and { BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(full_moon) or not BuffPresent(the_emerald_dreamcatcher_buff) } and SpellKnown(full_moon) and Spell(full_moon) or BuffPresent(lunar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(lunar_strike) and Spell(lunar_strike) or BuffPresent(solar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(solar_wrath) and Spell(solar_wrath) or { BuffPresent(the_emerald_dreamcatcher_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) < GCD() or AstralPower() >= 50 } and Spell(starsurge) or Spell(solar_wrath)
}

AddFunction BalanceEdCdActions
{
 unless AstralPower() >= 30 and Spell(incarnation)
 {
  #celestial_alignment,if=astral_power>=30
  if AstralPower() >= 30 Spell(celestial_alignment)
 }
}

AddFunction BalanceEdCdPostConditions
{
 AstralPower() >= 30 and Spell(incarnation) or { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or { SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } } and Spell(fury_of_elune) or { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or { SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } } and Spell(force_of_nature) or GCD() * AstralPower() / 30 > target.TimeToDie() and Spell(starsurge) or target.Refreshable(moonfire_debuff) and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(moonfire) or target.Refreshable(sunfire_debuff) and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(sunfire) or target.Refreshable(stellar_flare_debuff) and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(stellar_flare) or BuffPresent(oneths_overconfidence_buff) and { BuffRemaining(the_emerald_dreamcatcher_buff) > GCD() or not BuffPresent(the_emerald_dreamcatcher_buff) } and Spell(starfall) or { BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(new_moon) or not BuffPresent(the_emerald_dreamcatcher_buff) } and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() >= 20 and { BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(half_moon) or not BuffPresent(the_emerald_dreamcatcher_buff) } and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() >= 40 and { BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(full_moon) or not BuffPresent(the_emerald_dreamcatcher_buff) } and SpellKnown(full_moon) and Spell(full_moon) or BuffPresent(lunar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(lunar_strike) and Spell(lunar_strike) or BuffPresent(solar_empowerment_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) > ExecuteTime(solar_wrath) and Spell(solar_wrath) or { BuffPresent(the_emerald_dreamcatcher_buff) and BuffRemaining(the_emerald_dreamcatcher_buff) < GCD() or AstralPower() >= 50 } and Spell(starsurge) or Spell(solar_wrath)
}

### actions.aoe

AddFunction BalanceAoeMainActions
{
 #fury_of_elune,if=(((raid_event.adds.duration%8)*(4)<(raid_event.adds.in%60))|(raid_event.adds.up))&((buff.celestial_alignment.up|buff.incarnation.up)|(cooldown.celestial_alignment.remains>30|cooldown.incarnation.remains>30))
 if { 10 / 8 * 4 < 600 / 60 or False(raid_event_adds_exists) } and { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } Spell(fury_of_elune)
 #sunfire,target_if=refreshable,if=astral_power.deficit>7&target.time_to_die>4
 if target.Refreshable(sunfire_debuff) and AstralPowerDeficit() > 7 and target.TimeToDie() > 4 Spell(sunfire)
 #moonfire,target_if=refreshable,if=astral_power.deficit>7&target.time_to_die>4
 if target.Refreshable(moonfire_debuff) and AstralPowerDeficit() > 7 and target.TimeToDie() > 4 Spell(moonfire)
 #stellar_flare,target_if=refreshable,if=target.time_to_die>10
 if target.Refreshable(stellar_flare_debuff) and target.TimeToDie() > 10 Spell(stellar_flare)
 #lunar_strike,if=(buff.lunar_empowerment.stack=3|buff.solar_empowerment.stack=2&buff.lunar_empowerment.stack=2&astral_power>=40)&astral_power.deficit>14
 if { BuffStacks(lunar_empowerment_buff) == 3 or BuffStacks(solar_empowerment_buff) == 2 and BuffStacks(lunar_empowerment_buff) == 2 and AstralPower() >= 40 } and AstralPowerDeficit() > 14 Spell(lunar_strike)
 #solar_wrath,if=buff.solar_empowerment.stack=3&astral_power.deficit>10
 if BuffStacks(solar_empowerment_buff) == 3 and AstralPowerDeficit() > 10 Spell(solar_wrath)
 #starsurge,if=buff.oneths_intuition.react|target.time_to_die<=4
 if BuffPresent(oneths_intuition_buff) or target.TimeToDie() <= 4 Spell(starsurge)
 #starfall,if=!buff.starlord.up|buff.starlord.remains>=4
 if not BuffPresent(starlord_buff) or BuffRemaining(starlord_buff) >= 4 Spell(starfall)
 #new_moon,if=astral_power.deficit>12
 if AstralPowerDeficit() > 12 and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
 #half_moon,if=astral_power.deficit>22
 if AstralPowerDeficit() > 22 and SpellKnown(half_moon) Spell(half_moon)
 #full_moon,if=astral_power.deficit>42
 if AstralPowerDeficit() > 42 and SpellKnown(full_moon) Spell(full_moon)
 #solar_wrath,if=(buff.solar_empowerment.up&!buff.warrior_of_elune.up|buff.solar_empowerment.stack>=3)&buff.lunar_empowerment.stack<3
 if { BuffPresent(solar_empowerment_buff) and not BuffPresent(warrior_of_elune_buff) or BuffStacks(solar_empowerment_buff) >= 3 } and BuffStacks(lunar_empowerment_buff) < 3 Spell(solar_wrath)
 #lunar_strike
 Spell(lunar_strike)
 #moonfire
 Spell(moonfire)
}

AddFunction BalanceAoeMainPostConditions
{
}

AddFunction BalanceAoeShortCdActions
{
 unless { 10 / 8 * 4 < 600 / 60 or False(raid_event_adds_exists) } and { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and Spell(fury_of_elune)
 {
  #force_of_nature,if=(buff.celestial_alignment.up|buff.incarnation.up)|(cooldown.celestial_alignment.remains>30|cooldown.incarnation.remains>30)
  if BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 Spell(force_of_nature)
 }
}

AddFunction BalanceAoeShortCdPostConditions
{
 { 10 / 8 * 4 < 600 / 60 or False(raid_event_adds_exists) } and { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and Spell(fury_of_elune) or target.Refreshable(sunfire_debuff) and AstralPowerDeficit() > 7 and target.TimeToDie() > 4 and Spell(sunfire) or target.Refreshable(moonfire_debuff) and AstralPowerDeficit() > 7 and target.TimeToDie() > 4 and Spell(moonfire) or target.Refreshable(stellar_flare_debuff) and target.TimeToDie() > 10 and Spell(stellar_flare) or { BuffStacks(lunar_empowerment_buff) == 3 or BuffStacks(solar_empowerment_buff) == 2 and BuffStacks(lunar_empowerment_buff) == 2 and AstralPower() >= 40 } and AstralPowerDeficit() > 14 and Spell(lunar_strike) or BuffStacks(solar_empowerment_buff) == 3 and AstralPowerDeficit() > 10 and Spell(solar_wrath) or { BuffPresent(oneths_intuition_buff) or target.TimeToDie() <= 4 } and Spell(starsurge) or { not BuffPresent(starlord_buff) or BuffRemaining(starlord_buff) >= 4 } and Spell(starfall) or AstralPowerDeficit() > 12 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() > 22 and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() > 42 and SpellKnown(full_moon) and Spell(full_moon) or { BuffPresent(solar_empowerment_buff) and not BuffPresent(warrior_of_elune_buff) or BuffStacks(solar_empowerment_buff) >= 3 } and BuffStacks(lunar_empowerment_buff) < 3 and Spell(solar_wrath) or Spell(lunar_strike) or Spell(moonfire)
}

AddFunction BalanceAoeCdActions
{
}

AddFunction BalanceAoeCdPostConditions
{
 { 10 / 8 * 4 < 600 / 60 or False(raid_event_adds_exists) } and { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and Spell(fury_of_elune) or { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation) > 30 } and Spell(force_of_nature) or target.Refreshable(sunfire_debuff) and AstralPowerDeficit() > 7 and target.TimeToDie() > 4 and Spell(sunfire) or target.Refreshable(moonfire_debuff) and AstralPowerDeficit() > 7 and target.TimeToDie() > 4 and Spell(moonfire) or target.Refreshable(stellar_flare_debuff) and target.TimeToDie() > 10 and Spell(stellar_flare) or { BuffStacks(lunar_empowerment_buff) == 3 or BuffStacks(solar_empowerment_buff) == 2 and BuffStacks(lunar_empowerment_buff) == 2 and AstralPower() >= 40 } and AstralPowerDeficit() > 14 and Spell(lunar_strike) or BuffStacks(solar_empowerment_buff) == 3 and AstralPowerDeficit() > 10 and Spell(solar_wrath) or { BuffPresent(oneths_intuition_buff) or target.TimeToDie() <= 4 } and Spell(starsurge) or { not BuffPresent(starlord_buff) or BuffRemaining(starlord_buff) >= 4 } and Spell(starfall) or AstralPowerDeficit() > 12 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() > 22 and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() > 42 and SpellKnown(full_moon) and Spell(full_moon) or { BuffPresent(solar_empowerment_buff) and not BuffPresent(warrior_of_elune_buff) or BuffStacks(solar_empowerment_buff) >= 3 } and BuffStacks(lunar_empowerment_buff) < 3 and Spell(solar_wrath) or Spell(lunar_strike) or Spell(moonfire)
}

### actions.default

AddFunction BalanceDefaultMainActions
{
 #run_action_list,name=ed,if=equipped.the_emerald_dreamcatcher&active_enemies<=1
 if HasEquippedItem(the_emerald_dreamcatcher_item) and Enemies() <= 1 BalanceEdMainActions()

 unless HasEquippedItem(the_emerald_dreamcatcher_item) and Enemies() <= 1 and BalanceEdMainPostConditions()
 {
  #incarnation,if=astral_power>=40&(((raid_event.adds.duration%30)*(4)<(raid_event.adds.in%180))|(raid_event.adds.up))
  if AstralPower() >= 40 and { 10 / 30 * 4 < 600 / 180 or False(raid_event_adds_exists) } Spell(incarnation)
  #run_action_list,name=aoe,if=spell_targets.starfall>=3
  if Enemies() >= 3 BalanceAoeMainActions()

  unless Enemies() >= 3 and BalanceAoeMainPostConditions()
  {
   #run_action_list,name=st
   BalanceStMainActions()
  }
 }
}

AddFunction BalanceDefaultMainPostConditions
{
 HasEquippedItem(the_emerald_dreamcatcher_item) and Enemies() <= 1 and BalanceEdMainPostConditions() or Enemies() >= 3 and BalanceAoeMainPostConditions() or BalanceStMainPostConditions()
}

AddFunction BalanceDefaultShortCdActions
{
 #warrior_of_elune
 Spell(warrior_of_elune)
 #run_action_list,name=ed,if=equipped.the_emerald_dreamcatcher&active_enemies<=1
 if HasEquippedItem(the_emerald_dreamcatcher_item) and Enemies() <= 1 BalanceEdShortCdActions()

 unless HasEquippedItem(the_emerald_dreamcatcher_item) and Enemies() <= 1 and BalanceEdShortCdPostConditions() or AstralPower() >= 40 and { 10 / 30 * 4 < 600 / 180 or False(raid_event_adds_exists) } and Spell(incarnation)
 {
  #run_action_list,name=aoe,if=spell_targets.starfall>=3
  if Enemies() >= 3 BalanceAoeShortCdActions()

  unless Enemies() >= 3 and BalanceAoeShortCdPostConditions()
  {
   #run_action_list,name=st
   BalanceStShortCdActions()
  }
 }
}

AddFunction BalanceDefaultShortCdPostConditions
{
 HasEquippedItem(the_emerald_dreamcatcher_item) and Enemies() <= 1 and BalanceEdShortCdPostConditions() or AstralPower() >= 40 and { 10 / 30 * 4 < 600 / 180 or False(raid_event_adds_exists) } and Spell(incarnation) or Enemies() >= 3 and BalanceAoeShortCdPostConditions() or BalanceStShortCdPostConditions()
}

AddFunction BalanceDefaultCdActions
{
 #potion,if=buff.celestial_alignment.up|buff.incarnation.up
 if { BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(rising_death usable=1)
 #blood_fury,if=buff.celestial_alignment.up|buff.incarnation.up
 if BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) Spell(blood_fury)
 #berserking,if=buff.celestial_alignment.up|buff.incarnation.up
 if BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) Spell(berserking)
 #arcane_torrent,if=buff.celestial_alignment.up|buff.incarnation.up
 if BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) Spell(arcane_torrent_energy)
 #lights_judgment,if=buff.celestial_alignment.up|buff.incarnation.up
 if BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) Spell(lights_judgment)
 #fireblood,if=buff.celestial_alignment.up|buff.incarnation.up
 if BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) Spell(fireblood)
 #ancestral_call,if=buff.celestial_alignment.up|buff.incarnation.up
 if BuffPresent(celestial_alignment_buff) or DebuffPresent(incarnation) Spell(ancestral_call)
 #use_items
 BalanceUseItemActions()

 unless Spell(warrior_of_elune)
 {
  #run_action_list,name=ed,if=equipped.the_emerald_dreamcatcher&active_enemies<=1
  if HasEquippedItem(the_emerald_dreamcatcher_item) and Enemies() <= 1 BalanceEdCdActions()

  unless HasEquippedItem(the_emerald_dreamcatcher_item) and Enemies() <= 1 and BalanceEdCdPostConditions()
  {
   #innervate,if=azerite.lively_spirit.enabled&(cooldown.incarnation.up|cooldown.celestial_alignment.remains<12)&(((raid_event.adds.duration%15)*(4)<(raid_event.adds.in%180))|(raid_event.adds.up))
   if HasAzeriteTrait(lively_spirit_trait) and { not SpellCooldown(incarnation) > 0 or SpellCooldown(celestial_alignment) < 12 } and { 10 / 15 * 4 < 600 / 180 or False(raid_event_adds_exists) } Spell(innervate)

   unless AstralPower() >= 40 and { 10 / 30 * 4 < 600 / 180 or False(raid_event_adds_exists) } and Spell(incarnation)
   {
    #celestial_alignment,if=astral_power>=40&(!azerite.lively_spirit.enabled|buff.lively_spirit.up)&(((raid_event.adds.duration%15)*(4)<(raid_event.adds.in%180))|(raid_event.adds.up))
    if AstralPower() >= 40 and { not HasAzeriteTrait(lively_spirit_trait) or BuffPresent(lively_spirit_buff) } and { 10 / 15 * 4 < 600 / 180 or False(raid_event_adds_exists) } Spell(celestial_alignment)
    #run_action_list,name=aoe,if=spell_targets.starfall>=3
    if Enemies() >= 3 BalanceAoeCdActions()

    unless Enemies() >= 3 and BalanceAoeCdPostConditions()
    {
     #run_action_list,name=st
     BalanceStCdActions()
    }
   }
  }
 }
}

AddFunction BalanceDefaultCdPostConditions
{
 Spell(warrior_of_elune) or HasEquippedItem(the_emerald_dreamcatcher_item) and Enemies() <= 1 and BalanceEdCdPostConditions() or AstralPower() >= 40 and { 10 / 30 * 4 < 600 / 180 or False(raid_event_adds_exists) } and Spell(incarnation) or Enemies() >= 3 and BalanceAoeCdPostConditions() or BalanceStCdPostConditions()
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
# ancestral_call
# arcane_torrent_energy
# berserking
# blood_fury
# celestial_alignment
# celestial_alignment_buff
# fireblood
# force_of_nature
# full_moon
# fury_of_elune
# half_moon
# incarnation
# innervate
# lights_judgment
# lively_spirit_buff
# lively_spirit_trait
# lunar_empowerment_buff
# lunar_strike
# moonfire
# moonfire_debuff
# moonkin_form
# new_moon
# oneths_intuition_buff
# oneths_overconfidence_buff
# rising_death
# solar_empowerment_buff
# solar_wrath
# starfall
# starlord_buff
# starsurge
# stellar_flare
# stellar_flare_debuff
# sunfire
# sunfire_debuff
# the_emerald_dreamcatcher_buff
# the_emerald_dreamcatcher_item
# warrior_of_elune
# warrior_of_elune_buff
]]
    OvaleScripts:RegisterScript("DRUID", "balance", name, desc, code, "script")
end
do
    local name = "sc_pr_druid_feral"
    local desc = "[8.0] Simulationcraft: PR_Druid_Feral"
    local code = [[
# Based on SimulationCraft profile "PR_Druid_Feral".
#	class=druid
#	spec=feral
#	talents=3000212

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)


AddFunction use_thrash
{
 if HasEquippedItem(luffa_wrappings_item) 1
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
 #regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&combo_points=4&dot.rake.remains<4
 if Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() == 4 and target.DebuffRemaining(rake_debuff) < 4 Spell(regrowth)
 #regrowth,if=equipped.ailuro_pouncers&talent.bloodtalons.enabled&(buff.predatory_swiftness.stack>2|(buff.predatory_swiftness.stack>1&dot.rake.remains<3))&buff.bloodtalons.down
 if HasEquippedItem(ailuro_pouncers_item) and Talent(bloodtalons_talent) and { BuffStacks(predatory_swiftness_buff) > 2 or BuffStacks(predatory_swiftness_buff) > 1 and target.DebuffRemaining(rake_debuff) < 3 } and BuffExpires(bloodtalons_buff) Spell(regrowth)
 #brutal_slash,if=spell_targets.brutal_slash>desired_targets
 if Enemies() > Enemies(tagged=1) Spell(brutal_slash)
 #pool_resource,for_next=1
 #thrash_cat,if=refreshable&(spell_targets.thrash_cat>2)
 if target.Refreshable(thrash_cat_debuff) and Enemies() > 2 Spell(thrash_cat)
 unless target.Refreshable(thrash_cat_debuff) and Enemies() > 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
 {
  #pool_resource,for_next=1
  #thrash_cat,if=spell_targets.thrash_cat>3&equipped.luffa_wrappings&talent.brutal_slash.enabled
  if Enemies() > 3 and HasEquippedItem(luffa_wrappings_item) and Talent(brutal_slash_talent) Spell(thrash_cat)
  unless Enemies() > 3 and HasEquippedItem(luffa_wrappings_item) and Talent(brutal_slash_talent) and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
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
     #moonfire_cat,target_if=refreshable
     if target.Refreshable(moonfire_cat_debuff) Spell(moonfire_cat)
     #pool_resource,for_next=1
     #thrash_cat,if=refreshable&(variable.use_thrash=2|spell_targets.thrash_cat>1)
     if target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 or Enemies() > 1 } Spell(thrash_cat)
     unless target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 or Enemies() > 1 } and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
     {
      #thrash_cat,if=refreshable&variable.use_thrash=1&buff.clearcasting.react
      if target.Refreshable(thrash_cat_debuff) and use_thrash() == 1 and BuffPresent(clearcasting_buff) Spell(thrash_cat)
      #pool_resource,for_next=1
      #swipe_cat,if=spell_targets.swipe_cat>1
      if Enemies() > 1 Spell(swipe_cat)
      unless Enemies() > 1 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat)
      {
       #shred,if=dot.rake.remains>(action.shred.cost+action.rake.cost-energy)%energy.regen|buff.clearcasting.react
       if target.DebuffRemaining(rake_debuff) > { PowerCost(shred) + PowerCost(rake) - Energy() } / EnergyRegenRate() or BuffPresent(clearcasting_buff) Spell(shred)
      }
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
 Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() == 4 and target.DebuffRemaining(rake_debuff) < 4 and Spell(regrowth) or HasEquippedItem(ailuro_pouncers_item) and Talent(bloodtalons_talent) and { BuffStacks(predatory_swiftness_buff) > 2 or BuffStacks(predatory_swiftness_buff) > 1 and target.DebuffRemaining(rake_debuff) < 3 } and BuffExpires(bloodtalons_buff) and Spell(regrowth) or Enemies() > Enemies(tagged=1) and Spell(brutal_slash) or target.Refreshable(thrash_cat_debuff) and Enemies() > 2 and Spell(thrash_cat) or not { target.Refreshable(thrash_cat_debuff) and Enemies() > 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { Enemies() > 3 and HasEquippedItem(luffa_wrappings_item) and Talent(brutal_slash_talent) and Spell(thrash_cat) or not { Enemies() > 3 and HasEquippedItem(luffa_wrappings_item) and Talent(brutal_slash_talent) and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0 and target.TimeToDie() > 4 } and Spell(rake) or not { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0 and target.TimeToDie() > 4 } and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0 and target.TimeToDie() > 4 and Spell(rake) or not { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0 and target.TimeToDie() > 4 and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { BuffPresent(tigers_fury_buff) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * SpellChargeCooldown(brutal_slash) and Spell(brutal_slash) or target.Refreshable(moonfire_cat_debuff) and Spell(moonfire_cat) or target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 or Enemies() > 1 } and Spell(thrash_cat) or not { target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 or Enemies() > 1 } and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { target.Refreshable(thrash_cat_debuff) and use_thrash() == 1 and BuffPresent(clearcasting_buff) and Spell(thrash_cat) or Enemies() > 1 and Spell(swipe_cat) or not { Enemies() > 1 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and { target.DebuffRemaining(rake_debuff) > { PowerCost(shred) + PowerCost(rake) - Energy() } / EnergyRegenRate() or BuffPresent(clearcasting_buff) } and Spell(shred) } } } } }
}

AddFunction FeralStgeneratorsCdActions
{
}

AddFunction FeralStgeneratorsCdPostConditions
{
 Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() == 4 and target.DebuffRemaining(rake_debuff) < 4 and Spell(regrowth) or HasEquippedItem(ailuro_pouncers_item) and Talent(bloodtalons_talent) and { BuffStacks(predatory_swiftness_buff) > 2 or BuffStacks(predatory_swiftness_buff) > 1 and target.DebuffRemaining(rake_debuff) < 3 } and BuffExpires(bloodtalons_buff) and Spell(regrowth) or Enemies() > Enemies(tagged=1) and Spell(brutal_slash) or target.Refreshable(thrash_cat_debuff) and Enemies() > 2 and Spell(thrash_cat) or not { target.Refreshable(thrash_cat_debuff) and Enemies() > 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { Enemies() > 3 and HasEquippedItem(luffa_wrappings_item) and Talent(brutal_slash_talent) and Spell(thrash_cat) or not { Enemies() > 3 and HasEquippedItem(luffa_wrappings_item) and Talent(brutal_slash_talent) and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0 and target.TimeToDie() > 4 } and Spell(rake) or not { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0 and target.TimeToDie() > 4 } and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0 and target.TimeToDie() > 4 and Spell(rake) or not { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0 and target.TimeToDie() > 4 and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { BuffPresent(tigers_fury_buff) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * SpellChargeCooldown(brutal_slash) and Spell(brutal_slash) or target.Refreshable(moonfire_cat_debuff) and Spell(moonfire_cat) or target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 or Enemies() > 1 } and Spell(thrash_cat) or not { target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 or Enemies() > 1 } and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { target.Refreshable(thrash_cat_debuff) and use_thrash() == 1 and BuffPresent(clearcasting_buff) and Spell(thrash_cat) or Enemies() > 1 and Spell(swipe_cat) or not { Enemies() > 1 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and { target.DebuffRemaining(rake_debuff) > { PowerCost(shred) + PowerCost(rake) - Energy() } / EnergyRegenRate() or BuffPresent(clearcasting_buff) } and Spell(shred) } } } } }
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
 BuffExpires(savage_roar_buff) and Spell(savage_roar) or not { BuffExpires(savage_roar_buff) and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and Spell(rip) or not { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and SpellUsable(rip) and SpellCooldown(rip) < TimeToEnergyFor(rip) } and { BuffRemaining(savage_roar_buff) < 12 and Spell(savage_roar) or not { BuffRemaining(savage_roar_buff) < 12 and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and Energy() >= EnergyCost(ferocious_bite max=1) and Spell(ferocious_bite) } }
}

AddFunction FeralStfinishersCdActions
{
}

AddFunction FeralStfinishersCdPostConditions
{
 BuffExpires(savage_roar_buff) and Spell(savage_roar) or not { BuffExpires(savage_roar_buff) and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and Spell(rip) or not { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and SpellUsable(rip) and SpellCooldown(rip) < TimeToEnergyFor(rip) } and { BuffRemaining(savage_roar_buff) < 12 and Spell(savage_roar) or not { BuffRemaining(savage_roar_buff) < 12 and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and Energy() >= EnergyCost(ferocious_bite max=1) and Spell(ferocious_bite) } }
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
  #ferocious_bite,target_if=dot.rip.ticking&dot.rip.remains<3&target.time_to_die>10&(target.health.pct<25|talent.sabertooth.enabled)
  if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } Spell(ferocious_bite)
  #regrowth,if=combo_points=5&buff.predatory_swiftness.up&talent.bloodtalons.enabled&buff.bloodtalons.down&(!buff.incarnation.up|dot.rip.remains<8)
  if ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not DebuffPresent(incarnation) or target.DebuffRemaining(rip_debuff) < 8 } Spell(regrowth)
  #regrowth,if=combo_points>3&talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.apex_predator.up&buff.incarnation.down
  if ComboPoints() > 3 and Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffPresent(apex_predator_buff) and DebuffExpires(incarnation) Spell(regrowth)
  #ferocious_bite,if=buff.apex_predator.up&((combo_points>4&(buff.incarnation.up|talent.moment_of_clarity.enabled))|(talent.bloodtalons.enabled&buff.bloodtalons.up&combo_points>3))
  if BuffPresent(apex_predator_buff) and { ComboPoints() > 4 and { DebuffPresent(incarnation) or Talent(moment_of_clarity_talent) } or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and ComboPoints() > 3 } Spell(ferocious_bite)
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
 unless not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
 {
  #auto_attack
  FeralGetInMeleeRange()
  #call_action_list,name=cooldowns
  FeralCooldownsShortCdActions()

  unless FeralCooldownsShortCdPostConditions() or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } and Spell(ferocious_bite) or ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not DebuffPresent(incarnation) or target.DebuffRemaining(rip_debuff) < 8 } and Spell(regrowth) or ComboPoints() > 3 and Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffPresent(apex_predator_buff) and DebuffExpires(incarnation) and Spell(regrowth) or BuffPresent(apex_predator_buff) and { ComboPoints() > 4 and { DebuffPresent(incarnation) or Talent(moment_of_clarity_talent) } or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and ComboPoints() > 3 } and Spell(ferocious_bite)
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

AddFunction FeralSingletargetShortCdPostConditions
{
 not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake) or FeralCooldownsShortCdPostConditions() or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } and Spell(ferocious_bite) or ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not DebuffPresent(incarnation) or target.DebuffRemaining(rip_debuff) < 8 } and Spell(regrowth) or ComboPoints() > 3 and Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffPresent(apex_predator_buff) and DebuffExpires(incarnation) and Spell(regrowth) or BuffPresent(apex_predator_buff) and { ComboPoints() > 4 and { DebuffPresent(incarnation) or Talent(moment_of_clarity_talent) } or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and ComboPoints() > 3 } and Spell(ferocious_bite) or ComboPoints() > 4 and FeralStfinishersShortCdPostConditions() or FeralStgeneratorsShortCdPostConditions()
}

AddFunction FeralSingletargetCdActions
{
 unless not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
 {
  #call_action_list,name=cooldowns
  FeralCooldownsCdActions()

  unless FeralCooldownsCdPostConditions() or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } and Spell(ferocious_bite) or ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not DebuffPresent(incarnation) or target.DebuffRemaining(rip_debuff) < 8 } and Spell(regrowth) or ComboPoints() > 3 and Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffPresent(apex_predator_buff) and DebuffExpires(incarnation) and Spell(regrowth) or BuffPresent(apex_predator_buff) and { ComboPoints() > 4 and { DebuffPresent(incarnation) or Talent(moment_of_clarity_talent) } or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and ComboPoints() > 3 } and Spell(ferocious_bite)
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
 not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake) or FeralCooldownsCdPostConditions() or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } and Spell(ferocious_bite) or ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not DebuffPresent(incarnation) or target.DebuffRemaining(rip_debuff) < 8 } and Spell(regrowth) or ComboPoints() > 3 and Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffPresent(apex_predator_buff) and DebuffExpires(incarnation) and Spell(regrowth) or BuffPresent(apex_predator_buff) and { ComboPoints() > 4 and { DebuffPresent(incarnation) or Talent(moment_of_clarity_talent) } or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and ComboPoints() > 3 } and Spell(ferocious_bite) or ComboPoints() > 4 and FeralStfinishersCdPostConditions() or FeralStgeneratorsCdPostConditions()
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
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 }
}

AddFunction FeralPrecombatCdPostConditions
{
 Talent(bloodtalons_talent) and Spell(regrowth) or Spell(cat_form) or Spell(prowl)
}

### actions.cooldowns

AddFunction FeralCooldownsMainActions
{
 #prowl,if=buff.incarnation.remains<0.5&buff.jungle_stalker.up
 if DebuffRemaining(incarnation) < 0 and BuffPresent(jungle_stalker_buff) Spell(prowl)
 #incarnation,if=energy>=30&(cooldown.tigers_fury.remains>15|buff.tigers_fury.up)
 if Energy() >= 30 and { SpellCooldown(tigers_fury) > 15 or BuffPresent(tigers_fury_buff) } Spell(incarnation)
}

AddFunction FeralCooldownsMainPostConditions
{
}

AddFunction FeralCooldownsShortCdActions
{
 unless DebuffRemaining(incarnation) < 0 and BuffPresent(jungle_stalker_buff) and Spell(prowl)
 {
  #tigers_fury,if=energy.deficit>=60
  if EnergyDeficit() >= 60 Spell(tigers_fury)
  #feral_frenzy,if=combo_points=0
  if ComboPoints() == 0 Spell(feral_frenzy)
 }
}

AddFunction FeralCooldownsShortCdPostConditions
{
 DebuffRemaining(incarnation) < 0 and BuffPresent(jungle_stalker_buff) and Spell(prowl) or Energy() >= 30 and { SpellCooldown(tigers_fury) > 15 or BuffPresent(tigers_fury_buff) } and Spell(incarnation)
}

AddFunction FeralCooldownsCdActions
{
 #dash,if=!buff.cat_form.up
 if not BuffPresent(cat_form_buff) Spell(dash)

 unless DebuffRemaining(incarnation) < 0 and BuffPresent(jungle_stalker_buff) and Spell(prowl)
 {
  #berserk,if=energy>=30&(cooldown.tigers_fury.remains>5|buff.tigers_fury.up)
  if Energy() >= 30 and { SpellCooldown(tigers_fury) > 5 or BuffPresent(tigers_fury_buff) } Spell(berserk)

  unless EnergyDeficit() >= 60 and Spell(tigers_fury)
  {
   #berserking
   Spell(berserking)

   unless ComboPoints() == 0 and Spell(feral_frenzy) or Energy() >= 30 and { SpellCooldown(tigers_fury) > 15 or BuffPresent(tigers_fury_buff) } and Spell(incarnation)
   {
    #potion,name=prolonged_power,if=target.time_to_die<65|(time_to_die<180&(buff.berserk.up|buff.incarnation.up))
    if { target.TimeToDie() < 65 or target.TimeToDie() < 180 and { BuffPresent(berserk_buff) or DebuffPresent(incarnation) } } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power usable=1)
    #shadowmeld,if=combo_points<5&energy>=action.rake.cost&dot.rake.pmultiplier<2.1&buff.tigers_fury.up&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(!talent.incarnation.enabled|cooldown.incarnation.remains>18)&!buff.incarnation.up
    if ComboPoints() < 5 and Energy() >= PowerCost(rake) and target.DebuffPersistentMultiplier(rake_debuff) < 2 and BuffPresent(tigers_fury_buff) and { BuffPresent(bloodtalons_buff) or not Talent(bloodtalons_talent) } and { not Talent(incarnation_talent) or SpellCooldown(incarnation) > 18 } and not DebuffPresent(incarnation) Spell(shadowmeld)
    #use_items
    FeralUseItemActions()
   }
  }
 }
}

AddFunction FeralCooldownsCdPostConditions
{
 DebuffRemaining(incarnation) < 0 and BuffPresent(jungle_stalker_buff) and Spell(prowl) or EnergyDeficit() >= 60 and Spell(tigers_fury) or ComboPoints() == 0 and Spell(feral_frenzy) or Energy() >= 30 and { SpellCooldown(tigers_fury) > 15 or BuffPresent(tigers_fury_buff) } and Spell(incarnation)
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
  #incarnation
  Spell(incarnation)
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

  unless Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) or not BuffPresent(savage_roar_buff) and Spell(savage_roar) or Spell(incarnation)
  {
   #tigers_fury
   Spell(tigers_fury)
  }
 }
}

AddFunction FeralDefaultShortCdPostConditions
{
 { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetShortCdPostConditions() or { not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) } and Spell(rake) or Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) or not BuffPresent(savage_roar_buff) and Spell(savage_roar) or Spell(incarnation) or { Talent(sabertooth_talent) or BuffPresent(predatory_swiftness_buff) } and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and ComboPoints() == 5 and Spell(regrowth) or ComboPoints() == 5 and Spell(rip) or not target.DebuffPresent(thrash_cat_debuff) and use_thrash() > 0 and Spell(thrash_cat) or Spell(shred)
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
   Spell(berserk)
  }
 }
}

AddFunction FeralDefaultCdPostConditions
{
 { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetCdPostConditions() or { not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) } and Spell(rake) or Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) or not BuffPresent(savage_roar_buff) and Spell(savage_roar) or Spell(incarnation) or Spell(tigers_fury) or { Talent(sabertooth_talent) or BuffPresent(predatory_swiftness_buff) } and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and ComboPoints() == 5 and Spell(regrowth) or ComboPoints() == 5 and Spell(rip) or not target.DebuffPresent(thrash_cat_debuff) and use_thrash() > 0 and Spell(thrash_cat) or Spell(shred)
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
# ailuro_pouncers_item
# apex_predator_buff
# battle_potion_of_agility
# berserk
# berserk_buff
# berserking
# bloodtalons_buff
# bloodtalons_talent
# brutal_slash
# brutal_slash_talent
# cat_form
# cat_form_buff
# clearcasting_buff
# dash
# feral_frenzy
# ferocious_bite
# incarnation
# incarnation_talent
# jungle_stalker_buff
# luffa_wrappings_item
# lunar_inspiration_talent
# mangle
# moment_of_clarity_talent
# moonfire_cat
# moonfire_cat_debuff
# predatory_swiftness_buff
# prolonged_power
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
    local name = "sc_pr_druid_guardian"
    local desc = "[8.0] Simulationcraft: PR_Druid_Guardian"
    local code = [[
# Based on SimulationCraft profile "PR_Druid_Guardian".
#	class=druid
#	spec=guardian
#	talents=1111123

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
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war usable=1)
 }
}

AddFunction GuardianPrecombatCdPostConditions
{
 Spell(bear_form)
}

### actions.cooldowns

AddFunction GuardianCooldownsMainActions
{
}

AddFunction GuardianCooldownsMainPostConditions
{
}

AddFunction GuardianCooldownsShortCdActions
{
 #barkskin,if=buff.bear_form.up
 if DebuffPresent(bear_form) Spell(barkskin)
 #lunar_beam,if=buff.bear_form.up
 if DebuffPresent(bear_form) Spell(lunar_beam)
 #bristling_fur,if=buff.bear_form.up
 if DebuffPresent(bear_form) Spell(bristling_fur)
}

AddFunction GuardianCooldownsShortCdPostConditions
{
}

AddFunction GuardianCooldownsCdActions
{
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war usable=1)
 #blood_fury
 Spell(blood_fury)
 #berserking
 Spell(berserking)
 #arcane_torrent
 Spell(arcane_torrent_energy)
 #lights_judgment
 Spell(lights_judgment)
 #fireblood
 Spell(fireblood)
 #ancestral_call
 Spell(ancestral_call)

 unless DebuffPresent(bear_form) and Spell(barkskin) or DebuffPresent(bear_form) and Spell(lunar_beam) or DebuffPresent(bear_form) and Spell(bristling_fur)
 {
  #use_items
  GuardianUseItemActions()
 }
}

AddFunction GuardianCooldownsCdPostConditions
{
 DebuffPresent(bear_form) and Spell(barkskin) or DebuffPresent(bear_form) and Spell(lunar_beam) or DebuffPresent(bear_form) and Spell(bristling_fur)
}

### actions.default

AddFunction GuardianDefaultMainActions
{
 #call_action_list,name=cooldowns
 GuardianCooldownsMainActions()

 unless GuardianCooldownsMainPostConditions()
 {
  #maul,if=rage.deficit<10&active_enemies<4
  if RageDeficit() < 10 and Enemies() < 4 Spell(maul)
  #pulverize,target_if=dot.thrash_bear.stack=dot.thrash_bear.max_stacks
  if target.DebuffStacks(thrash_bear_debuff) == FIXME_dot.thrash_bear.max_stacks and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) Spell(pulverize)
  #moonfire,target_if=dot.moonfire.refreshable&active_enemies<2
  if target.DebuffRefreshable(moonfire_debuff) and Enemies() < 2 Spell(moonfire)
  #incarnation
  Spell(incarnation)
  #thrash,if=(buff.incarnation.down&active_enemies>1)|(buff.incarnation.up&active_enemies>4)
  if DebuffExpires(incarnation) and Enemies() > 1 or DebuffPresent(incarnation) and Enemies() > 4 Spell(thrash)
  #swipe,if=buff.incarnation.down&active_enemies>4
  if DebuffExpires(incarnation) and Enemies() > 4 Spell(swipe)
  #mangle,if=dot.thrash_bear.ticking
  if target.DebuffPresent(thrash_bear_debuff) Spell(mangle)
  #moonfire,target_if=buff.galactic_guardian.up&active_enemies<2
  if BuffPresent(galactic_guardian_buff) and Enemies() < 2 Spell(moonfire)
  #thrash
  Spell(thrash)
  #maul
  Spell(maul)
  #swipe
  Spell(swipe)
 }
}

AddFunction GuardianDefaultMainPostConditions
{
 GuardianCooldownsMainPostConditions()
}

AddFunction GuardianDefaultShortCdActions
{
 #auto_attack
 GuardianGetInMeleeRange()
 #call_action_list,name=cooldowns
 GuardianCooldownsShortCdActions()
}

AddFunction GuardianDefaultShortCdPostConditions
{
 GuardianCooldownsShortCdPostConditions() or RageDeficit() < 10 and Enemies() < 4 and Spell(maul) or target.DebuffStacks(thrash_bear_debuff) == FIXME_dot.thrash_bear.max_stacks and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or target.DebuffRefreshable(moonfire_debuff) and Enemies() < 2 and Spell(moonfire) or Spell(incarnation) or { DebuffExpires(incarnation) and Enemies() > 1 or DebuffPresent(incarnation) and Enemies() > 4 } and Spell(thrash) or DebuffExpires(incarnation) and Enemies() > 4 and Spell(swipe) or target.DebuffPresent(thrash_bear_debuff) and Spell(mangle) or BuffPresent(galactic_guardian_buff) and Enemies() < 2 and Spell(moonfire) or Spell(thrash) or Spell(maul) or Spell(swipe)
}

AddFunction GuardianDefaultCdActions
{
 #call_action_list,name=cooldowns
 GuardianCooldownsCdActions()
}

AddFunction GuardianDefaultCdPostConditions
{
 GuardianCooldownsCdPostConditions() or RageDeficit() < 10 and Enemies() < 4 and Spell(maul) or target.DebuffStacks(thrash_bear_debuff) == FIXME_dot.thrash_bear.max_stacks and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or target.DebuffRefreshable(moonfire_debuff) and Enemies() < 2 and Spell(moonfire) or Spell(incarnation) or { DebuffExpires(incarnation) and Enemies() > 1 or DebuffPresent(incarnation) and Enemies() > 4 } and Spell(thrash) or DebuffExpires(incarnation) and Enemies() > 4 and Spell(swipe) or target.DebuffPresent(thrash_bear_debuff) and Spell(mangle) or BuffPresent(galactic_guardian_buff) and Enemies() < 2 and Spell(moonfire) or Spell(thrash) or Spell(maul) or Spell(swipe)
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
# ancestral_call
# arcane_torrent_energy
# barkskin
# bear_form
# berserking
# blood_fury
# bristling_fur
# fireblood
# galactic_guardian_buff
# incarnation
# lights_judgment
# lunar_beam
# mangle
# maul
# moonfire
# moonfire_debuff
# old_war
# pulverize
# shred
# swipe
# thrash
# thrash_bear_debuff
# wild_charge
# wild_charge_bear
# wild_charge_cat
]]
    OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
end
