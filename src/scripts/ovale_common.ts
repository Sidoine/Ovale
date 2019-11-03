import { OvaleScriptsClass } from "../Scripts";

export function registerCommon(OvaleScripts: OvaleScriptsClass) {
    let name = "ovale_common";
    let desc = "[8.2] Ovale: Common spell definitions";
    let code = `
# Common spell definitions shared by all classes and specializations.

###
### Potions
###

#  Mists of Pandaria
Define(golemblood_potion 58146)
Define(golemblood_potion_buff 79634)
	SpellInfo(golemblood_potion_buff duration=25)
Define(jade_serpent_potion 76093)
Define(jade_serpent_potion_buff 105702)
	SpellInfo(jade_serpent_potion_buff duration=25)
Define(master_mana_potion 76098)
Define(mogu_power_potion 76095)
Define(mogu_power_potion_buff 105706)
	SpellInfo(mogu_power_potion_buff duration=25)
Define(mountains_potion 76090)
Define(mountains_potion_buff 105698)
	SpellInfo(mountains_potion_buff duration=25)
Define(virmens_bite_potion 76089)
Define(virmens_bite_potion_buff 105697)
	SpellInfo(virmens_bite_potion_buff duration=25)

# Warlords of Draenor
Define(draenic_agility_potion 109217)
Define(draenic_agility_potion_buff 156423)
	SpellInfo(draenic_agility_potion_buff duration=25)
Define(draenic_armor_potion 109220)
Define(draenic_armor_potion_buff 156430)
	SpellInfo(draenic_armor_potion_buff duration=25)
Define(draenic_intellect_potion 109218)
Define(draenic_intellect_potion_buff 156426)
	SpellInfo(draenic_intellect_potion_buff duration=25)
Define(draenic_mana_potion 109222)
Define(draenic_strength_potion 109219)
Define(draenic_strength_potion_buff 156428)
	SpellInfo(draenic_strength_potion_buff duration=25)

SpellList(potion_agility_buff draenic_agility_potion_buff virmens_bite_potion_buff)
SpellList(potion_armor_buff draenic_armor_potion_buff mountains_potion_buff)
SpellList(potion_intellect_buff draenic_intellect_potion_buff jade_serpent_potion_buff)
SpellList(potion_strength_buff draenic_strength_potion_buff golemblood_potion_buff)

# Legion
Define(defiled_augmentation 140587)

Define(deadly_grace_potion 127843)
Define(old_war_potion 127844)
Define(prolonged_power_potion 142117)
Define(unbending_potion 127845)
Define(deadly_grace_potion_buff 188027)
Define(potion_of_prolonged_power_potion 142117)

Define(prolonged_power_buff 229206)
Define(unbending_potion_buff 188029)
SpellList(potion_buff unbending_potion_buff)

Define(astral_healing_potion 152615)
    ItemInfo(astral_healing_potion offgcd=1 gcd=0)
    ItemRequire(astral_healing_potion unusable 1=debuff,healing_immunity_debuff)
Define(ancient_healing_potion 127834)
    ItemInfo(ancient_healing_potion offgcd=1 gcd=0)
    ItemRequire(ancient_healing_potion unusable 1=debuff,healing_immunity_debuff)
Define(aged_healing_potion 136569)
    ItemInfo(aged_healing_potion offgcd=1 gcd=0)
    ItemRequire(aged_healing_potion unusable 1=debuff,healing_immunity_debuff)
Define(coastal_healing_potion 152494)
    ItemInfo(coastal_healing_potion offgcd=1 gcd=0)
    ItemRequire(coastal_healing_potion unusable 1=debuff,healing_immunity_debuff)
Define(healthstone 5512)
    ItemInfo(healthstone offgcd=1 gcd=0)
    ItemRequire(healthstone unusable 1=debuff,healing_immunity_debuff)


SpellList(trinket_proc_spell_power_buff)
SpellList(trinket_stacking_proc_spell_power_buff)

Define(umbral_glaive_storm 242553)

###
### Trinkets & OnUse Rings
###

# Amplification trinket passive buff.
Define(amplified_buff 146051)

# Cooldown reduction trinket passive buffs.
Define(cooldown_reduction_agility_buff 146019)
Define(cooldown_reduction_strength_buff 145955)
Define(cooldown_reduction_tank_buff 146025)

Define(coagulated_nightwell_residue 137400)
	ItemRequire(coagulated_nightwell_residue unusable 1=buff,!nightwell_energy_buff)
Define(cunning_of_the_deceiver 242629)
Define(convergence_of_fates 140806)
Define(draught_of_souls 140808)
Define(edits_of_the_faithless 169315)
    ItemInfo(edits_of_the_faithless unusable=1)
Define(gnawed_thumb_ring 134526)
	ItemInfo(gnawed_thumb_ring cd=180)
Define(nightwell_energy_buff 214572)
Define(shifting_cosmic_sliver 147026)
Define(specter_of_betrayal 151190)
Define(ring_of_collapsing_futures 142173)
	ItemInfo(ring_of_collapsing_futures cd=15)
	Define(temptation_buff 234143)

###
### Legendary Meta Gem
###

Define(lucidity_druid_buff 137247)
	SpellInfo(lucidity_druid_buff duration=4)
Define(lucidity_monk_buff 137331)
	SpellInfo(lucidity_monk_buff duration=4)
Define(lucidity_paladin_buff 137288)
	SpellInfo(lucidity_paladin_buff duration=4)
Define(lucidity_priest_buff 137323)
	SpellInfo(lucidity_priest_buff duration=4)
Define(lucidity_shaman_buff 137326)
	SpellInfo(lucidity_shaman_buff duration=4)
Define(tempus_repit_buff 137590)
	SpellInfo(tempus_repit_buff duration=10)

###
### Legendary ring
###

Define(archmages_greater_incandescence_agi_buff 177172)
	SpellInfo(archmages_greater_incandescence_agi_buff duration=10)
Define(archmages_incandescence_agi_buff 177161)
	SpellInfo(archmages_incandescence_agi_buff duration=10)
Define(archmages_greater_incandescence_int_buff 177176)
	SpellInfo(archmages_greater_incandescence_int_buff duration=10)
Define(archmages_incandescence_int_buff 177159)
	SpellInfo(archmages_incandescence_int_buff duration=10)
Define(archmages_greater_incandescence_str_buff 177175)
	SpellInfo(archmages_greater_incandescence_str_buff duration=10)
Define(archmages_incandescence_str_buff 177160)
	SpellInfo(archmages_incandescence_str_buff duration=10)
	
###
### Legendary Shared legiondaries
###

Define(sephuzs_secret_item 132452)
Define(sephuzs_secret_buff 208051)
	SpellInfo(sephuzs_secret_buff buff_cd=30 duration=10)
	
### Missing items (temporary)
Define(dread_combatants_insignia_item 161813)
Define(dread_combatants_medallion_item 161811)

### Missing spells 
Define(trinket_grongs_primal_rage_cooldown_buff 288267)
Define(trinket_ashvanes_razor_coral_cooldown_buff 303568)
Define(hyperthread_wristwraps_300142 300142)

###
### Essences
###

Define(anima_of_death_essence 294926)
    SpellInfo(anima_of_death_essence tag=cd)
Define(concentrated_flame_essence 295373)
    SpellInfo(concentrated_flame_essence cd=30 tag=main)
    Define(concentrated_flame_burn_debuff 295368)
    SpellInfo(concentrated_flame_burn_debuff duration=6)
    SpellAddTargetDebuff(concentrated_flame_essence concentrated_flame_burn_debuff=1)
Define(focused_azerite_beam_essence 295258)
    SpellInfo(focused_azerite_beam_essence cd=90 tag=cd)
Define(memory_of_lucid_dreams_essence 298357)
    SpellInfo(memory_of_lucid_dreams_essence cd=120 tag=cd)
    Define(memory_of_lucid_dreams_essence_buff 298357)
Define(ripple_in_space_essence 302731)
    SpellInfo(ripple_in_space_essence cd=60 tag=shortcd)
Define(the_unbound_force_essence 298452)
    SpellInfo(the_unbound_force_essence cd=60 tag=shortcd)
    Define(reckless_force_counter_buff 302917)
    SpellInfo(reckless_force_counter_buff max_stacks=20)
Define(worldvein_resonance_essence 295186)
    SpellInfo(worldvein_resonance_essence cd=60 tag=shortcd)
    Define(lifeblood_buff 295137)

###
### Racials
###

Define(arcane_torrent_chi 129597)
	SpellInfo(arcane_torrent_chi cd=120 chi=-1)
Define(arcane_torrent_energy 25046)
	SpellInfo(arcane_torrent_energy cd=120 energy=-15)
Define(arcane_torrent_focus 80483)
	SpellInfo(arcane_torrent_focus cd=120 focus=-15)
Define(arcane_torrent_holy 155145)
	SpellInfo(arcane_torrent_holy cd=120 holy=-1)
Define(arcane_torrent_mana 28730)
	SpellInfo(arcane_torrent_mana cd=120)
Define(arcane_torrent_rage 69179)
	SpellInfo(arcane_torrent_rage cd=120 rage=-15)
Define(arcane_torrent_runicpower 50613)
	SpellInfo(arcane_torrent_runicpower cd=120 runicpower=-20)
Define(arcane_torrent_dh 202719)
	SpellInfo(arcane_torrent_dh cd=120 pain=-15 specialization=vengeance)
	SpellInfo(arcane_torrent_dh cd=120 fury=-15 specialization=havoc)
Define(berserking 26297)
	SpellInfo(berserking cd=180 gcd=0 offgcd=1)
	SpellAddBuff(berserking berserking_buff=1)
Define(berserking_buff 26297)
	SpellInfo(berserking_buff duration=12)
Define(blood_fury_ap 20572)
	SpellInfo(blood_fury_ap cd=120)
	SpellAddBuff(blood_fury_ap blood_fury_ap_buff=1)
Define(blood_fury_ap_buff 20572)
	SpellInfo(blood_fury_ap_buff duration=15)
Define(blood_fury_apsp 33697)
	SpellInfo(blood_fury_apsp cd=120)
	SpellAddBuff(blood_fury_apsp blood_fury_apsp_buff=1)
Define(blood_fury_apsp_buff 33697)
	SpellInfo(blood_fury_apsp_buff duration=15)
Define(blood_fury_sp 33702)
	SpellInfo(blood_fury_sp cd=120)
	SpellAddBuff(blood_fury_sp blood_fury_sp_buff=1)
Define(blood_fury_sp_buff 33702)
	SpellInfo(blood_fury_sp_buff duration=15)
Define(fireblood 265221)
    SpellInfo(fireblood cd=120)
Define(darkflight 68992)
	SpellInfo(darkflight cd=120)
Define(quaking_palm 107079)
	SpellInfo(quaking_palm cd=120 interrupt=1)
Define(rocket_barrage 69041)
	SpellInfo(rocket_barrage cd=120)
Define(shadowmeld 58984)
	SpellInfo(shadowmeld cd=120)
	SpellAddBuff(shadowmeld shadowmeld_buff=1)
Define(shadowmeld_buff 58984)
Define(stoneform 20594)
	SpellInfo(stoneform cd=120)
	SpellAddBuff(stoneform stoneform_buff=1)
Define(stoneform_buff 20594)
	SpellInfo(stoneform_buff duration=8)
Define(war_stomp 20549)
	SpellInfo(war_stomp cd=120 interrupt=1)
Define(lights_judgment 255647)
	SpellInfo(lights_judgment cd=150)
Define(fireblood 265221)
	SpellInfo(fireblood cd=120)
Define(ancestral_call 274738)
	SpellInfo(ancestral_call cd=120)
Define(arcane_pulse 260364)  
	SpellInfo(arcane_pulse cd=180)
	
###
### Boss Spells
###
Define(misery_debuff 243961)
	SpellInfo(misery_debuff duration=7)
	
###
### Healing
###
SpellList(healing_immunity_debuff misery_debuff)

AddFunction UseRacialSurvivalActions
{
	Spell(stoneform)
}

AddFunction UseHealthPotions
{
	Item(healthstone usable=1)
	if CheckBoxOn(opt_use_consumables) 
	{
        Item(coastal_healing_potion usable=1)
        Item(astral_healing_potion usable=1)
		Item(ancient_healing_potion usable=1)
		Item(aged_healing_potion usable=1)
	}
}
`;
    OvaleScripts.RegisterScript(undefined, undefined, name, desc, code, "include");
}
