local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_trinkets_wod"
	local desc = "[6.2] Ovale: Trinkets (Warlords of Draenor)"
	local code = [[
# Trinkets from Warlords of Draenor.

###
### Legendary ring
###

Define(legendary_ring_agility 124636)
Define(legendary_ring_bonus_armor 124637)
Define(legendary_ring_intellect 124635)
Define(legendary_ring_spirit 124638)
Define(legendary_ring_strength 124634)

Define(etheralus_buff 187618)
	SpellInfo(etheralus_buff duration=15)
Define(maalus_buff 187620)
	SpellInfo(maalus_buff duration=15)
Define(nithramus_buff 187616)
	SpellInfo(nithramus_buff duration=15)
Define(sanctus_buff 187617)
	SpellInfo(sanctus_buff duration=15)
Define(thorasus_buff 187619)
	SpellInfo(thorasus_buff duration=15)

###
### Agility
###

Define(call_of_conquest_buff 126690)
	SpellInfo(call_of_conquest_buff buff_cd=60 duration=20 stat=agility)
Define(lucky_flip_buff 177597)
	SpellInfo(lucky_flip_buff buff_cd=120 duration=20 stat=agility)
Define(surge_of_conquest_buff 126707)
	SpellInfo(surge_of_conquest_buff buff_cd=55 duration=20 stat=agility)

Define(lucky_double_sided_coin 118876)
	ItemInfo(lucky_double_sided_coin buff=lucky_flip_buff)
ItemList(primal_combatants_badge_of_conquest primal_combatants_badge_of_conquest_alliance primal_combatants_badge_of_conquest_horde)
Define(primal_combatants_badge_of_conquest_alliance 115149)
	ItemInfo(primal_combatants_badge_of_conquest_alliance buff=call_of_conquest_buff)
Define(primal_combatants_badge_of_conquest_horde 119926)
	ItemInfo(primal_combatants_badge_of_conquest_horde buff=call_of_conquest_buff)
ItemList(primal_combatants_insignia_of_conquest primal_combatants_insignia_of_conquest_alliance primal_combatants_insignia_of_conquest_horde)
Define(primal_combatants_insignia_of_conquest_alliance 115150)
	ItemInfo(primal_combatants_insignia_of_conquest_alliance buff=surge_of_conquest_buff)
Define(primal_combatants_insignia_of_conquest_horde 119927)
	ItemInfo(primal_combatants_insignia_of_conquest_horde buff=surge_of_conquest_buff)
ItemList(primal_gladiators_badge_of_conquest primal_gladiators_badge_of_conquest_alliance primal_gladiators_badge_of_conquest_horde)
Define(primal_gladiators_badge_of_conquest_alliance 115749)
	ItemInfo(primal_gladiators_badge_of_conquest_alliance buff=call_of_conquest_buff)
Define(primal_gladiators_badge_of_conquest_horde 111222)
	ItemInfo(primal_gladiators_badge_of_conquest_horde buff=call_of_conquest_buff)
ItemList(primal_gladiators_insignia_of_conquest primal_gladiators_insignia_of_conquest_alliance primal_gladiators_insignia_of_conquest_horde)
Define(primal_gladiators_insignia_of_conquest_alliance 115750)
	ItemInfo(primal_gladiators_insignia_of_conquest_alliance buff=surge_of_conquest_buff)
Define(primal_gladiators_insignia_of_conquest_horde 111223)
	ItemInfo(primal_gladiators_insignia_of_conquest_horde buff=surge_of_conquest_buff)

###
### Bonus armor
###

Define(gazing_eye_buff 177053)
	SpellInfo(gazing_eye_buff buff_cd=65 duration=10 stat=bonus_armor)
Define(turnbuckle_terror_buff 176873)
	SpellInfo(turnbuckle_terror_buff buff_cd=120 duration=20 stat=bonus_armor)

Define(evergaze_arcane_eidolon 113861)
	ItemInfo(evergaze_arcane_eidolon buff=gazing_eye_buff)
Define(tablet_of_turnbuckle_teamwork 113905)
	ItemInfo(tablet_of_turnbuckle_teamwork buff=turnbuckle_terror_buff)

###
### Critical Strike
###

Define(critical_strike_proc_buff 165830)
	SpellInfo(critical_strike_proc_buff buff_cd=65 duration=10 stat=critical_strike)
Define(critical_strike_use_buff 165532)
	SpellInfo(critical_strike_use_buff buff_cd=120 duration=20 stat=critical_strike)
Define(detonation_buff 177067)
	SpellInfo(177067 buff_cd=65 max_stacks=20 duration=10 stat=critical_strike)
Define(howling_soul_buff 177046)
	SpellInfo(howling_soul_buff buff_cd=65 duration=10 stat=critical_strike)
Define(immaculate_living_mushroom_buff 176978)
	SpellInfo(immaculate_living_mushroom_buff buff_cd=65 duration=10 stat=critical_strike)
Define(nightmare_fire_buff 162919)
	SpellInfo(nightmare_fire_buff buff_cd=115 duration=20 stat=critical_strike)
Define(spirit_of_the_warlords_buff 162915)
	SpellInfo(spirit_of_the_warlords_buff buff_cd=115 duration=20 stat=critical_strike)
Define(stoneheart_idol_buff 176982)
	SpellInfo(stoneheart_idol_buff buff_cd=65 duration=10 stat=critical_strike)
Define(strength_of_steel_buff 162917)
	SpellInfo(strength_of_steel_buff buff_cd=115 duration=20 stat=critical_strike)
Define(tectus_heartbeat_buff 177040)
	SpellInfo(tectus_heartbeat_buff buff_cd=65 duration=10 stat=critical_strike)

Define(bloodcasters_charm 118777)
	ItemInfo(bloodcasters_charm buff=critical_strike_proc_buff)
Define(bonemaws_big_toe 110012)
	ItemInfo(bonemaws_big_toe buff=critical_strike_use_buff)
Define(goren_soul_repository 119194)
	ItemInfo(goren_soul_repository buff=howling_soul_buff)
Define(humming_blackiron_trigger 113985)
	ItemInfo(humming_blackiron_trigger buff=detonation_buff)
Define(immaculate_living_mushroom 116291)
	ItemInfo(immaculate_living_mushroom buff=immaculate_living_mushroom_buff)
Define(knights_badge 112319)
	ItemInfo(knights_badge buff=strength_of_steel_buff)
Define(munificent_emblem_of_terror 114427)
	ItemInfo(munificent_emblem_of_terror buff=critical_strike_proc_buff)
Define(sandmans_pouch 112320)
	ItemInfo(sandmans_pouch buff=nightmare_fire_buff)
Define(skull_of_war 112318)
	ItemInfo(skull_of_war buff=spirit_of_the_warlords_buff)
Define(stoneheart_idol 116318)
	ItemInfo(stoneheart_idol buff=stoneheart_idol_buff)
Define(tectus_beating_heart 113645)
	ItemInfo(tectus_beating_heart buff=tectus_heartbeat_buff)
Define(voidmenders_shadowgem 110007)
	ItemInfo(voidmenders_shadowgem buff=critical_strike_use_buff)

###
### Haste
###

Define(battering_buff 177102)
	SpellInfo(battering_buff buff_cd=65 duration=10 max_stacks=20 stat=haste)
Define(caustic_healing_buff 176879)
	SpellInfo(caustic_healing_buff buff_cd=120 duration=20 stat=haste)
Define(haste_proc_buff 165822)
	SpellInfo(haste_proc_buff buff_cd=65 duration=10 stat=haste)
Define(haste_use_buff 165531)
	SpellInfo(haste_use_buff buff_cd=120 duration=20 stat=haste)
Define(heart_of_the_fury_buff 176980)
	SpellInfo(heart_of_the_fury_buff buff_cd=65 duration=10 stat=haste)
Define(instability_buff 177051)
	SpellInfo(instability_buff buff_cd=65 duration=10 stat=haste)
Define(meaty_dragonspine_trophy_buff 177035)
	SpellInfo(meaty_dragonspine_trophy_buff buff_cd=65 duration=10 stat=haste)
Define(sanitizing_buff 177086)
	SpellInfo(sanitizing_buff buff_cd=65 duration=10 max_stacks=20 stat=haste)
Define(turbulent_focusing_crystal_buff 176882)
	SpellInfo(turbulent_focusing_crystal_buff buff_cd=120 duration=20 stat=haste)
Define(turbulent_seal_of_defiance_buff 176885)
	SpellInfo(turbulent_seal_of_defiance_buff buff_cd=90 duration=15 stat=haste)
Define(void_shards_buff 176875)
	SpellInfo(void_shards_buff buff_cd=120 duration=20 stat=haste)

Define(auto_repairing_autoclave 113986)
	ItemInfo(auto_repairing_autoclave buff=sanitizing_buff)
Define(battering_talisman 113987)
	ItemInfo(battering_talisman buff=battering_buff)
Define(darmacs_unstable_talisman 113948)
	ItemInfo(darmacs_unstable_talisman buff=instability_buff)
Define(emblem_of_caustic_healing 113842)
	ItemInfo(emblem_of_caustic_healing buff=caustic_healing_buff)
Define(fleshrenders_meathook 110002)
	ItemInfo(fleshrenders_meathook buff=haste_use_buff)
Define(furyheart_talisman 116315)
	ItemInfo(furyheart_talisman buff=heart_of_the_fury_buff)
Define(meaty_dragonspine_trophy 118114)
	ItemInfo(meaty_dragonspine_trophy buff=meaty_dragonspine_trophy_buff)
Define(munificent_bonds_of_fury 114430)
	ItemInfo(munificent_bonds_of_fury buff=haste_proc_buff)
Define(shards_of_nothing 113835)
	ItemInfo(shards_of_nothing buff=void_shards_buff)
Define(spores_of_alacrity 110014)
	ItemInfo(spores_of_alacrity buff=haste_proc_buff)
Define(turbulent_focusing_crystal 114489)
	ItemInfo(turbulent_focusing_crystal buff=turbulent_focusing_crystal_buff)
Define(turbulent_seal_of_defiance 114492)
	ItemInfo(turbulent_seal_of_defiance buff=turbulent_seal_of_defiance_buff)
Define(witherbarks_branch 109999)
	ItemInfo(witherbarks_branch buff=haste_proc_buff)


###
### Intellect
###

Define(call_of_dominance_buff 126683)
	SpellInfo(call_of_dominance_buff buff_cd=60 duration=20 stat=intellect)
Define(surge_of_dominance_buff 126705)
	SpellInfo(surge_of_dominance_buff buff_cd=55 duration=20 stat=intellect)

ItemList(primal_combatants_badge_of_dominance primal_combatants_badge_of_dominance_alliance primal_combatants_badge_of_dominance_horde)
Define(primal_combatants_badge_of_dominance_alliance 115154)
	ItemInfo(primal_combatants_badge_of_dominance_alliance buff=call_of_dominance_buff)
Define(primal_combatants_badge_of_dominance_horde 119931)
	ItemInfo(primal_combatants_badge_of_dominance_horde buff=call_of_dominance_buff)
ItemList(primal_combatants_insignia_of_dominance primal_combatants_insignia_of_dominance_alliance primal_combatants_insignia_of_dominance_horde)
Define(primal_combatants_insignia_of_dominance_alliance 115155)
	ItemInfo(primal_combatants_insignia_of_dominance_alliance buff=surge_of_dominance_buff)
Define(primal_combatants_insignia_of_dominance_horde 119932)
	ItemInfo(primal_combatants_insignia_of_dominance_horde buff=surge_of_dominance_buff)
ItemList(primal_gladiators_badge_of_dominance primal_gladiators_badge_of_dominance_alliance primal_gladiators_badge_of_dominance_horde)
Define(primal_gladiators_badge_of_dominance_alliance 115754)
	ItemInfo(primal_gladiators_badge_of_dominance_alliance buff=call_of_dominance_buff)
Define(primal_gladiators_badge_of_dominance_horde 111227)
	ItemInfo(primal_gladiators_badge_of_dominance_horde buff=call_of_dominance_buff)
ItemList(primal_gladiators_insignia_of_dominance primal_gladiators_insignia_of_dominance_alliance primal_gladiators_insignia_of_dominance_horde)
Define(primal_gladiators_insignia_of_dominance_alliance 115755)
	ItemInfo(primal_gladiators_insignia_of_dominance_alliance buff=surge_of_dominance_buff)
Define(primal_gladiators_insignia_of_dominance_horde 111228)
	ItemInfo(primal_gladiators_insignia_of_dominance_horde buff=surge_of_dominance_buff)

###
### Mastery
###

Define(blast_furnace_buff 177056)
	SpellInfo(blast_furnace_buff buff_cd=65 duration=10 stat=mastery)
Define(mastery_proc_buff 165824)
	SpellInfo(mastery_proc_buff buff_cd=65 duration=10 stat=mastery)
Define(mastery_short_use_buff 165535)
	SpellInfo(mastery_short_use_buff buff_cd=90 duration=15 stat=mastery)
Define(mastery_use_buff 165485)
	SpellInfo(mastery_use_buff buff_cd=120 duration=20 stat=mastery)
Define(screaming_spirits_buff 177042)
	SpellInfo(screaming_spirits_buff buff_cd=65 duration=10 stat=mastery)
Define(turbulent_vial_of_toxin_buff 176883)
	SpellInfo(turbulent_vial_of_toxin_buff buff_cd=90 duration=15 stat=mastery)
Define(turbulent_relic_of_mendacity_buff 176884)
	SpellInfo(turbulent_relic_of_mendacity_buff buff_cd=90 duration=15 stat=mastery)
Define(vision_of_the_cyclops_buff 176876)
	SpellInfo(vision_of_the_cyclops_buff buff_cd=120 duration=20 stat=mastery)

Define(blast_furnace_door 113893)
	ItemInfo(blast_furnace_door buff=blast_furnace_buff)
Define(horn_of_screaming_spirits 119193)
	ItemInfo(horn_of_screaming_spirits buff=screaming_spirits_buff)
Define(kihras_adrenaline_injector 109997)
	ItemInfo(kihras_adrenaline_injector buff=mastery_use_buff)
Define(kyraks_vileblood_serum 110018)
	ItemInfo(kyraks_vileblood_serum buff=mastery_short_use_buff)
Define(munificent_censer_of_tranquility 114429)
	ItemInfo(munificent_censer_of_tranquility buff=mastery_proc_buff)
Define(petrified_flesh_eating_spore 113663)
	ItemInfo(petrified_flesh_eating_spore buff=mastery_proc_buff)
Define(pols_blinded_eye 113834)
	ItemInfo(pols_blinded_eye buff=vision_of_the_cyclops_buff)
Define(tharbeks_lucky_pebble 110008)
	ItemInfo(tharbeks_lucky_pebble buff=mastery_short_use_buff)
Define(turbulent_vial_of_toxin 114488)
	ItemInfo(turbulent_vial_of_toxin buff=turbulent_vial_of_toxin_buff)
Define(turbulent_relic_of_mendacity 114490)
	ItemInfo(turbulent_relic_of_mendacity buff=turbulent_relic_of_mendacity_buff)
Define(xeritacs_unhatched_egg_sac 110019)
	ItemInfo(xeritacs_unhatched_egg_sac buff=mastery_proc_buff)

###
### Multistrike
###

Define(blackheart_enforcers_medallion_buff 176984)
	SpellInfo(blackheart_enforcers_medallion_buff buff_cd=65 duration=10 stat=multistrike)
Define(balanced_fate_buff 177038)
	SpellInfo(balanced_fate_buff buff_cd=65 duration=10 stat=multistrike)
Define(convulsive_shadows_buff 176874)
	SpellInfo(convulsive_shadows_buff buff_cd=120 duration=15 stat=multistrike)
Define(elemental_shield_buff 177063)
	SpellInfo(elemental_shield_buff buff_cd=65 duration=10 stat=multistrike)
Define(forgemasters_vigor_buff 177096)
	SpellInfo(forgemasters_vigor_buff buff_cd=65 duration=10 max_stacks=20 stat=multistrike)
Define(lub_dub_buff 176878)
	SpellInfo(lub_dub_buff buff_cd=120 duration=20 stat=multistrike)
Define(molten_metal_buff 177081)
	SpellInfo(molten_metal_buff buff_cd=65 duration=10 max_stacks=20 stat=multistrike)
Define(multi_strike_buff 165542)
	SpellInfo(multi_strike_use_buff buff_cd=90 duration=15 stat=multistrike)
Define(multistrike_proc_buff 165832)
	SpellInfo(multistrike_proc_buff buff_cd=65 duration=10 stat=multistrike)
Define(turbulent_emblem_buff 176881)
	SpellInfo(turbulent_emblem_buff buff_cd=120 duration=20 stat=multistrike)

Define(beating_heart_of_the_mountain 113931)
	ItemInfo(beating_heart_of_the_mountain buff=lub_dub_buff)
Define(blackheart_enforcers_medallion 116314)
	ItemInfo(blackheart_enforcers_medallion buff=blackheart_enforcers_medallion_buff)
Define(blackiron_micro_crucible 113984)
	ItemInfo(blackiron_micro_crucible buff=molten_metal_buff)
Define(coagulated_genesaur_blood 110004)
	ItemInfo(coagulated_genesaur_blood buff=multistrike_proc_buff)
Define(elementalists_shielding_talisman 113889)
	ItemInfo(elementalists_shielding_talisman buff=elemental_shield_buff)
Define(forgemasters_insignia 113983)
	ItemInfo(forgemasters_insignia buff=forgemasters_vigor_buff)
Define(gorashans_lodestone_spike 109998)
	ItemInfo(gorashans_lodestone_spike buff=multi_strike_buff)
Define(scales_of_doom 113612)
	ItemInfo(scales_of_doom buff=balanced_fate_buff)
Define(turbulent_emblem 114491)
	ItemInfo(turbulent_emblem buff=turbulent_emblem_buff)
Define(vial_of_convulsive_shadows 113969)
	ItemInfo(vial_of_convulsive_shadows buff=convulsive_shadows_buff)

###
### Spellpower
###

Define(sudden_clarity_buff 177594)
	SpellInfo(sudden_clarity_buff buff_cd=120 duration=20 stat=spellpower)

Define(copelands_clarity 118878)
	ItemInfo(copelands_clarity buff=sudden_clarity_buff)

###
### Spirit
###

Define(squeak_squeak_buff 177060)
	SpellInfo(squeak_squeak_buff buff_cd=65 duration=10 stat=spirit)
Define(visions_of_the_future_buff 162913)
	SpellInfo(visions_of_the_future_buff buff_cd=115 duration=20 stat=spirit)

Define(ironspike_chew_toy 119192)
	ItemInfo(ironspike_chew_toy buff=squeak_squeak_buff)
Define(winged_hourglass 112317)
	ItemInfo(winged_hourglass buff=visions_of_the_future_buff)

###
### Strength
###

Define(call_of_victory_buff 126679)
	SpellInfo(call_of_victory_buff buff_cd=60 duration=20 stat=strength)
Define(surge_of_victory_buff 126700)
	SpellInfo(surge_of_victory_buff buff_cd=55 duration=20 stat=strength)
Define(sword_technique_buff 177189)
	SpellInfo(sword_technique_buff buff_cd=90 duration=10 stat=strength)

ItemList(primal_combatants_badge_of_victory primal_combatants_badge_of_victory_alliance primal_combatants_badge_of_victory_horde)
Define(primal_combatants_badge_of_victory_alliance 115159)
	ItemInfo(primal_combatants_badge_of_victory_alliance buff=call_of_victory_buff)
Define(primal_combatants_badge_of_victory_horde 119936)
	ItemInfo(primal_combatants_badge_of_victory_horde buff=call_of_victory_buff)
ItemList(primal_combatants_insignia_of_victory primal_combatants_insignia_of_victory_alliance primal_combatants_insignia_of_victory_horde)
Define(primal_combatants_insignia_of_victory_alliance 115160)
	ItemInfo(primal_combatants_insignia_of_victory_alliance buff=surge_of_victory_buff)
Define(primal_combatants_insignia_of_victory_horde 119937)
	ItemInfo(primal_combatants_insignia_of_victory_horde buff=surge_of_victory_buff)
ItemList(primal_gladiators_badge_of_victory primal_gladiators_badge_of_victory_alliance primal_gladiators_badge_of_victory_horde)
Define(primal_gladiators_badge_of_victory_alliance 115759)
	ItemInfo(primal_gladiators_badge_of_victory_alliance buff=call_of_victory_buff)
Define(primal_gladiators_badge_of_victory_horde 111232)
	ItemInfo(primal_gladiators_badge_of_victory_horde buff=call_of_victory_buff)
ItemList(primal_gladiators_insignia_of_victory primal_gladiators_insignia_of_victory_alliance primal_gladiators_insignia_of_victory_horde)
Define(primal_gladiators_insignia_of_victory_alliance 115760)
	ItemInfo(primal_gladiators_insignia_of_victory_alliance buff=surge_of_victory_buff)
Define(primal_gladiators_insignia_of_victory_horde 111233)
	ItemInfo(primal_gladiators_insignia_of_victory_horde buff=surge_of_victory_buff)
Define(scabbard_of_kyanos 118882)
	ItemInfo(scabbard_of_kyanos buff=sword_technique_buff)

###
### Versatility
###

Define(mote_of_the_mountain_buff 176974)
	SpellInfo(mote_of_the_mountain_buff buff_cd=65 duration=10 stat=versatility)
Define(versatility_proc_buff 165833)
	SpellInfo(versatility_proc_buff buff_cd=65 duration=10 stat=versatility)
Define(versatility_short_use_buff 165543)
	SpellInfo(versatility_short_use_buff buff_cd=90 duration=15 stat=versatility)
Define(versatility_use_buff 165534)
	SpellInfo(versatility_use_buff buff_cd=120 duration=20 stat=versatility)

Define(emberscale_talisman 110013)
	ItemInfo(emberscale_talisman buff=versatility_short_use_buff)
Define(enforcers_stun_grenade 110017)
	ItemInfo(enforcers_stun_grenade buff=versatility_use_buff)
Define(leaf_of_the_ancient_protectors 110009)
	ItemInfo(leaf_of_the_ancient_protectors buff=versatility_proc_buff)
Define(mote_of_the_mountain 116292)
	ItemInfo(mote_of_the_mountain buff=mote_of_the_mountain_buff)
Define(munificent_orb_of_ice 114428)
	ItemInfo(munificent_orb_of_ice buff=versatility_proc_buff)
Define(munificent_soul_of_compassion 114431)
	ItemInfo(munificent_soul_of_compassion buff=versatility_proc_buff)
Define(ragewings_firefang 110003)
	ItemInfo(ragewings_firefang buff=versatility_short_use_buff)

###
### Miscellaneous
###

Define(empty_drinking_horn 124238)

Define(soul_capacitor 124225)
	ItemInfo(soul_capacitor buff=spirit_shift_buff)
Define(spirit_shift_buff 184293)
	SpellInfo(spirit_shift_buff buff_cd=60 duration=10)
]]

	OvaleScripts:RegisterScript(nil, nil, name, desc, code, "include")
end
