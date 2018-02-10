local __exports = LibStub:NewLibrary("ovale/scripts/ovale_common", 10000)
if not __exports then return end
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
__exports.register = function()
    local name = "ovale_common"
    local desc = "[7.3.2] Ovale: Common spell definitions"
    local code = [[
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
    ItemRequire(astral_healing_potion unusable 1=debuff,healing_immunity_debuff)
Define(ancient_healing_potion 127834)
    ItemRequire(ancient_healing_potion unusable 1=debuff,healing_immunity_debuff)
Define(aged_healing_potion 136569)
    ItemRequire(aged_healing_potion unusable 1=debuff,healing_immunity_debuff)
Define(healthstone 5512)
    ItemRequire(healthstone unusable 1=debuff,healing_immunity_debuff)


SpellList(trinket_proc_spell_power_buff)
SpellList(trinket_stacking_proc_spell_power_buff)

Define(astral_healing_potion 152615)
Define(ancient_healing_potion 127834)
Define(aged_healing_potion 136569)
Define(healthstone 5512)
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

Define(sephuzs_secret 132452)
Define(sephuzs_secret_buff 208051)
	SpellInfo(sephuzs_secret_buff buff_cd=30 duration=10)

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
	SpellInfo(berserking cd=180)
	SpellAddBuff(berserking berserking_buff=1)
Define(berserking_buff 26297)
	SpellInfo(berserking_buff duration=10)
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
		Item(astral_healing_potion usable=1)
		Item(ancient_healing_potion usable=1)
		Item(aged_healing_potion usable=1)
	}
}

# Movement allowing defines
Define(stellar_drift_buff 202461)
Define(norgannons_foresight_buff 236380)
Define(spiritwalkers_grace_buff 79206)

AddFunction CanMove
{
	if BuffPresent(norgannons_foresight_buff) 1
    if BuffPresent(stellar_drift_buff) 1
	if BuffPresent(ice_floes_buff) 1
	if BuffPresent(spiritwalkers_grace_buff) 1
    0
}

# Party checks
AddFunction PartyMemberCount
{
	player.Present() + party1.Present() + party2.Present() + party3.Present() + party4.Present()
}

AddFunction PartyHealth
{
	player.Health() + party1.Health() + party2.Health() + party3.Health() + party4.Health()
}

AddFunction PartyMaxHealth
{
	player.MaxHealth() + party1.MaxHealth() + party2.MaxHealth() + party3.MaxHealth() + party4.MaxHealth()
}

AddFunction PartyHealthPercent
{
	{ PartyHealth() / PartyMaxHealth() } * 100
}

# Raid checks
AddFunction RaidMemberCount
{
	player.Present() + raid1.Present() + raid2.Present() + raid3.Present() + raid4.Present() + raid5.Present() + raid6.Present() + raid7.Present() + raid8.Present() + raid9.Present() + raid10.Present() + raid11.Present() + raid12.Present() + raid13.Present() + raid14.Present() + raid15.Present() + raid16.Present() + raid17.Present() + raid18.Present() + raid19.Present() + raid20.Present() + raid21.Present() + raid22.Present() + raid23.Present() + raid24.Present() + raid25.Present()
}

AddFunction RaidHealth
{
	player.Health() + raid1.Health() + raid2.Health() + raid3.Health() + raid4.Health() + raid5.Health() + raid6.Health() + raid7.Health() + raid8.Health() + raid9.Health() + raid10.Health() + raid11.Health() + raid12.Health() + raid13.Health() + raid14.Health() + raid15.Health() + raid16.Health() + raid17.Health() + raid18.Health() + raid19.Health() + raid20.Health() + raid21.Health() + raid22.Health() + raid23.Health() + raid24.Health() + raid25.Health()
}

AddFunction RaidMaxHealth
{
	player.MaxHealth() + raid1.MaxHealth() + raid2.MaxHealth() + raid3.MaxHealth() + raid4.MaxHealth() + raid5.MaxHealth() + raid6.MaxHealth() + raid7.MaxHealth() + raid8.MaxHealth() + raid9.MaxHealth() + raid10.MaxHealth() + raid11.MaxHealth() + raid12.MaxHealth() + raid13.MaxHealth() + raid14.MaxHealth() + raid15.MaxHealth() + raid16.MaxHealth() + raid17.MaxHealth() + raid18.MaxHealth() + raid19.MaxHealth() + raid20.MaxHealth() + raid21.MaxHealth() + raid22.MaxHealth() + raid23.MaxHealth() + raid24.MaxHealth() + raid25.MaxHealth()
}

AddFunction RaidHealthPercent
{
	{ RaidHealth() / RaidMaxHealth() } * 100
}

AddFunction PartyMembersBelowEighty
{
	player.HealthPercent() < 80 + party1.HealthPercent() < 80 + party2.HealthPercent() < 80 + party3.HealthPercent() < 80 + party4.HealthPercent() < 80
}

AddFunction RaidMembersBelowEighty
{
	player.HealthPercent() < 80 + raid1.HealthPercent() < 80 + raid2.HealthPercent() < 80 + raid3.HealthPercent() < 80 + raid4.HealthPercent() < 80 + raid5.HealthPercent() < 80 + raid6.HealthPercent() < 80 + raid7.HealthPercent() < 80 + raid8.HealthPercent() < 80 + raid9.HealthPercent() < 80 + raid10.HealthPercent() < 80 + raid11.HealthPercent() < 80 + raid12.HealthPercent() < 80 + raid13.HealthPercent() < 80 + raid14.HealthPercent() < 80 + raid15.HealthPercent() < 80 + raid16.HealthPercent() < 80 + raid17.HealthPercent() < 80 + raid18.HealthPercent() < 80 + raid19.HealthPercent() < 80 + raid20.HealthPercent() < 80 + raid21.HealthPercent() < 80 + raid22.HealthPercent() < 80 + raid23.HealthPercent() < 80 + raid24.HealthPercent() < 80 + raid25.HealthPercent() < 80
}

AddFunction PartyMembersBelowSixty
{
	player.HealthPercent() < 60 + party1.HealthPercent() < 60 + party2.HealthPercent() < 60 + party3.HealthPercent() < 60 + party4.HealthPercent() < 60
}

AddFunction RaidMembersBelowSixty
{
	player.HealthPercent() < 60 + raid1.HealthPercent() < 60 + raid2.HealthPercent() < 60 + raid3.HealthPercent() < 60 + raid4.HealthPercent() < 60 + raid5.HealthPercent() < 60 + raid6.HealthPercent() < 60 + raid7.HealthPercent() < 60 + raid8.HealthPercent() < 60 + raid9.HealthPercent() < 60 + raid10.HealthPercent() < 60 + raid11.HealthPercent() < 60 + raid12.HealthPercent() < 60 + raid13.HealthPercent() < 60 + raid14.HealthPercent() < 60 + raid15.HealthPercent() < 60 + raid16.HealthPercent() < 60 + raid17.HealthPercent() < 60 + raid18.HealthPercent() < 60 + raid19.HealthPercent() < 60 + raid20.HealthPercent() < 60 + raid21.HealthPercent() < 60 + raid22.HealthPercent() < 60 + raid23.HealthPercent() < 60 + raid24.HealthPercent() < 60 + raid25.HealthPercent() < 60
}

AddFunction PartyMembersBelowFourty
{
	player.HealthPercent() < 40 + party1.HealthPercent() < 40 + party2.HealthPercent() < 40 + party3.HealthPercent() < 40 + party4.HealthPercent() < 40
}

AddFunction RaidMembersBelowFourty
{
	player.HealthPercent() < 40 + raid1.HealthPercent() < 40 + raid2.HealthPercent() < 40 + raid3.HealthPercent() < 40 + raid4.HealthPercent() < 40 + raid5.HealthPercent() < 40 + raid6.HealthPercent() < 40 + raid7.HealthPercent() < 40 + raid8.HealthPercent() < 40 + raid9.HealthPercent() < 40 + raid10.HealthPercent() < 40 + raid11.HealthPercent() < 40 + raid12.HealthPercent() < 40 + raid13.HealthPercent() < 40 + raid14.HealthPercent() < 40 + raid15.HealthPercent() < 40 + raid16.HealthPercent() < 40 + raid17.HealthPercent() < 40 + raid18.HealthPercent() < 40 + raid19.HealthPercent() < 40 + raid20.HealthPercent() < 40 + raid21.HealthPercent() < 40 + raid22.HealthPercent() < 40 + raid23.HealthPercent() < 40 + raid24.HealthPercent() < 40 + raid25.HealthPercent() < 40
}

AddFunction PartyMembersBelowTwentyFive
{
	player.HealthPercent() < 25 + party1.HealthPercent() < 25 + party2.HealthPercent() < 25 + party3.HealthPercent() < 25 + party4.HealthPercent() < 25
}

AddFunction RaidMembersBelowTwentyFive
{
	player.HealthPercent() < 25 + raid1.HealthPercent() < 25 + raid2.HealthPercent() < 25 + raid3.HealthPercent() < 25 + raid4.HealthPercent() < 25 + raid5.HealthPercent() < 25 + raid6.HealthPercent() < 25 + raid7.HealthPercent() < 25 + raid8.HealthPercent() < 25 + raid9.HealthPercent() < 25 + raid10.HealthPercent() < 25 + raid11.HealthPercent() < 25 + raid12.HealthPercent() < 25 + raid13.HealthPercent() < 25 + raid14.HealthPercent() < 25 + raid15.HealthPercent() < 25 + raid16.HealthPercent() < 25 + raid17.HealthPercent() < 25 + raid18.HealthPercent() < 25 + raid19.HealthPercent() < 25 + raid20.HealthPercent() < 25 + raid21.HealthPercent() < 25 + raid22.HealthPercent() < 25 + raid23.HealthPercent() < 25 + raid24.HealthPercent() < 25 + raid25.HealthPercent() < 25
}
]]
    OvaleScripts:RegisterScript(nil, nil, name, desc, code, "include")
end
