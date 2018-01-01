local __exports = LibStub:NewLibrary("ovale/scripts/ovale_warlock_spells", 10000)
if not __exports then return end
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
__exports.register = function()
    local name = "ovale_warlock_spells"
    local desc = "[7.0] Ovale: Warlock spells"
    local code = [[
# Warlock spells and functions.

Define(agony 980)
	SpellAddTargetDebuff(agony agony_debuff=1)
Define(agony_debuff 980)
	SpellInfo(agony_debuff duration=24 haste=spell max_stacks=10 tick=2)
Define(archimondes_darkness_talent 16)
Define(backdraft 117896)
Define(backdraft_buff 117828)
	SpellInfo(backdraft_buff duration=15 max_stacks=3)
# cancel_metamorphosis
Define(call_dreadstalkers 104316)
	SpellInfo(call_dreadstalkers soulshards=2 cd=15)
Define(cataclysm 152108)
	SpellInfo(cataclysm cd=60 gcd=0)
Define(cataclysm_talent 20)
Define(channel_demonfire 196447)
	SpellInfo(channel_demonfire cd=15 channel=3)
Define(chaos_bolt 116858)
	SpellInfo(chaos_bolt soulshards=2 travel_time=1)
	SpellRequire(chaos_bolt replace chaos_bolt_fire_and_brimstone=buff,fire_and_brimstone_buff if_spell=charred_remains if_spell=fire_and_brimstone)
	SpellAddBuff(chaos_bolt chaotic_infusion_buff=0 itemset=T17 itemcount=4 specialization=destruction)
	SpellAddBuff(chaos_bolt backdraft_buff=-3 if_spell=backdraft)
	SpellAddBuff(chaos_bolt fire_and_brimstone_buff=0 if_spell=charred_remains if_spell=fire_and_brimstone)
	SpellAddBuff(chaos_bolt havoc_buff=-3 if_spell=havoc)
Define(chaos_wave 124916)
	SpellInfo(chaos_wave demonicfury=80 travel_time=1)
	SpellAddBuff(chaos_wave fel_molten_core_aura=1 if_spell=the_codex_of_xerrath)
	SpellAddBuff(chaos_wave molten_core_aura=1 if_spell=!the_codex_of_xerrath)
Define(chaotic_infusion_buff 170000)
	SpellInfo(chaotic_infusion_buff duration=30)
Define(charred_remains 157696)
Define(charred_remains_talent 19)
Define(compounding_horror_buff 199281)
	SpellAddBuff(unstable_affliction compounding_horror_buff=0)
Define(conflagrate 17962)
	SpellInfo(conflagrate soulshards=-1 mana=600)
	SpellAddBuff(conflagrate havoc_buff=-1 if_spell=havoc)
Define(conflagration_of_chaos_buff 219195)
Define(corruption 172)
	SpellAddTargetDebuff(corruption corruption_debuff=1)
Define(corruption_debuff 146739)
	SpellInfo(corruption_debuff duration=18 haste=spell tick=2)
Define(dark_intent 109773)
	SpellAddBuff(dark_intent dark_intent_buff=1)
Define(dark_intent_buff 109773)
	SpellInfo(dark_intent_buff duration=3600)
Define(dark_soul_instability 113858)
	SpellInfo(dark_soul_instability gcd=0)
	SpellInfo(dark_soul_instability cd=120 talent=!archimondes_darkness_talent)
	SpellAddBuff(dark_soul_instability dark_soul_instability_buff=1)
Define(dark_soul_instability_buff 113858)
	SpellInfo(dark_soul_instability_buff duration=20)
Define(dark_soul_knowledge 113861)
	SpellInfo(dark_soul_knowledge gcd=0)
	SpellInfo(dark_soul_knowledge cd=120 talent=!archimondes_darkness_talent)
	SpellAddBuff(dark_soul_knowledge dark_soul_knowledge_buff=1)
Define(dark_soul_knowledge_buff 113861)
	SpellInfo(dark_soul_knowledge_buff duration=20)
Define(dark_soul_misery 113860)
	SpellInfo(dark_soul_misery gcd=0)
	SpellInfo(dark_soul_misery cd=120 talent=!archimondes_darkness_talent)
	SpellAddBuff(dark_soul_misery dark_soul_misery_buff=1)
Define(dark_soul_misery_buff 113860)
	SpellInfo(dark_soul_misery_buff duration=20)
Define(demon_rush_buff 188857)
	SpellInfo(demon_rush_buff duration=15 max_stacks=5)
Define(demonbolt 157695)
	SpellInfo(demonbolt soulshards=-1)
Define(demonbolt_buff 157695)
	SpellInfo(demonbolt_buff duration=40 max_stacks=10 stacking=1)
Define(demonbolt_talent 19)
Define(demonic_empowerment 193396)
	SpellRequire(demonic_empowerment unusable 1=pet_buff,demonic_empowerment)
	SpellAddPetBuff(demonic_empowerment demonic_empowerment=1)
Define(demonic_calling_buff 205146)
	SpellInfo(demonic_calling_buff duration=20)
	SpellRequire(call_dreadstalkers soulshards 0=buff,demonic_calling_buff)
Define(demonic_power_buff 196099)
	SpellInfo(demonic_power_buff duration=3600)
Define(demonic_servitude_talent 21)
Define(demonic_synergy_buff 171982)
	SpellInfo(demonic_synergy_buff duration=15)
Define(demonwrath 193440)
Define(dimensional_rift 196586)
	SpellInfo(dimensional_rift cd=45)
Define(doom 603)
	SpellInfo(doom soulshards=-1)
	SpellAddTargetDebuff(doom doom_debuff=1)
	SpellRequire(doom unusable 1=target_debuff,doom_debuff)
Define(doom_debuff 603)
	SpellInfo(doom_debuff duration=60 haste=spell tick=15)
Define(drain_soul 198590)
	SpellInfo(drain_soul channel=4 haste=spell)
Define(ember_master_buff 145164)	# tier16_4pc_caster
	SpellInfo(ember_master_buff duration=5)
Define(embrace_chaos_buff 212019)
	SpellInfo(embrace_chaos_buff duration=4)
Define(empowered_life_tap_buff 235156)
	SpellInfo(empowered_life_tap_buff duration=20)
Define(enhanced_haunt 157072)
Define(enhanced_havoc 157126)
Define(fel_molten_core_aura 140074)
	SpellInfo(fel_molten_core_aura duration=30 max_stacks=10)
Define(felguard_felstorm 89751)
	SpellInfo(felguard_felstorm cd=45 gcd=0)
Define(fire_and_brimstone 108683)
	SpellInfo(fire_and_brimstone cd=1 gcd=0)
	SpellAddBuff(fire_and_brimstone fire_and_brimstone_buff=1)
Define(fire_and_brimstone_buff 108683)
Define(flamelicked_debuff 185229)
	SpellInfo(flamelicked_debuff duration=10 max_stacks=5)
Define(grimoire_of_sacrifice 108503)
	SpellInfo(grimoire_of_sacrifice cd=30 gcd=0)
	SpellAddBuff(grimoire_of_sacrifice grimoire_of_sacrifice_buff=1)
Define(grimoire_of_sacrifice_buff 108503)
	SpellInfo(grimoire_of_sacrifice_buff duration=3600)
Define(grimoire_of_sacrifice_talent 15)
Define(grimoire_of_service_talent 14)
Define(grimoire_of_supremacy_talent 13)
Define(hand_of_guldan 105174)
	SpellInfo(hand_of_guldan max_travel_time=1.5 shards=finisher) # maximum observed travel time with a bit of padding
	SpellAddTargetDebuff(hand_of_guldan shadowflame_debuff=1)
Define(haunt 48181)
	SpellInfo(haunt mana=5)
	SpellInfo(haunt travel_time=2.3) # maximum observed travel time with a bit of padding
	SpellAddTargetDebuff(haunt haunt_debuff=1)
Define(haunt_debuff 48181)
	SpellInfo(haunt_debuff duration=8 haste=spell tick=2)
	SpellInfo(haunt_debuff addduration=2 if_spell=enhanced_haunt)
Define(haunting_spirits_buff 157698)
	SpellInfo(haunting_spirits_buff duration=30)
Define(havoc 80240)
	SpellInfo(havoc cd=20)
	SpellInfo(havoc addcd=-5 if_spell=enhanced_havoc)
	SpellAddBuff(havoc havoc_buff=3)
	SpellAddTargetDebuff(havoc havoc_debuff=1)
Define(havoc_buff 80240)
	SpellInfo(havoc_buff duration=15 max_stacks=3)
Define(havoc_debuff 80240)
	SpellInfo(havoc_debuff duration=15)
Define(hellfire 1949)
	SpellInfo(hellfire channel=14)
Define(immolate 348)
	SpellAddBuff(immolate havoc_buff=-1 if_spell=havoc)
	SpellAddTargetDebuff(immolate immolate_debuff=1)
Define(immolate_debuff 157736)
	SpellInfo(immolate_debuff duration=15 haste=spell tick=3)
Define(impending_doom_talent 4)
Define(implosion 196277)
Define(incinerate 29722)
	SpellInfo(incinerate travel_time=1)
	SpellAddBuff(incinerate backdraft_buff=-1 if_spell=backdraft)
	SpellAddBuff(incinerate havoc_buff=-1 if_spell=havoc)
	SpellAddTargetDebuff(incinerate flamelicked_debuff=1)
Define(kiljaedens_cunning 137587)
	SpellInfo(kiljaedens_cunning cd=35 gcd=0)
	SpellAddBuff(kiljaedens_cunning kiljaedens_cunning_buff=1)
Define(kiljaedens_cunning_buff 137587)
	SpellInfo(kiljaedens_cunning_buff duration=8)
Define(lessons_of_spacetime_buff 236176)
Define(life_tap 1454)
	SpellAddBuff(life_tap empowered_life_tap_buff=1 talent=empowered_life_tap_talent)
Define(lord_of_flames 224103)
Define(lord_of_flames_buff 224103) #TODO Not sure
Define(mannoroths_fury 108508)
	SpellInfo(mannoroths_fury cd=60 gcd=0)
	SpellAddBuff(mannoroths_fury mannoroths_fury_buff=1)
Define(mannoroths_fury_buff 108508)
	SpellInfo(mannoroths_fury_buff duration=10)
Define(mannoroths_fury_talent 18)
Define(mark_of_doom_debuff 184073)
	SpellInfo(mark_of_doom_debuff duration=10)
Define(molten_core_aura 122355)
	SpellInfo(molten_core_aura duration=30 max_stacks=10)
SpellList(molten_core_buff fel_molten_core_aura molten_core_aura)
Define(mortal_coil 6789)
Define(phantom_singularity 205179)
	SpellInfo(phantom_singularity cd=60)
Define(power_trip_talent 11)
Define(rain_of_fire 5740)
Define(rain_of_fire_debuff 5740)
	SpellInfo(rain_of_fire_debuff duration=8 haste=spell tick=1)
Define(roaring_blaze_debuff 205184) #TODO Check this
Define(roaring_blaze_talent 2)
Define(seed_of_corruption 27243)
	SpellInfo(seed_of_corruption soulshards=1)
	SpellRequire(seed_of_corruption replace seed_of_corruption_soulburn=buff,soulburn_buff if_spell=soulburn)
	SpellRequire(seed_of_corruption unusable 1=buff,soulburn_buff if_spell=soulburn)
	SpellAddTargetDebuff(seed_of_corruption seed_of_corruption_debuff=1)
Define(seed_of_corruption_aura 27243)
	SpellInfo(seed_of_corruption_aura duration=18 tick=3)
SpellList(seed_of_corruption_debuff seed_of_corruption_aura seed_of_corruption_soulburn_debuff)
Define(seed_of_corruption_soulburn 114790)
	SpellRequire(seed_of_corruption_soulburn unusable 1=buff,!soulburn_buff)
	SpellAddTargetDebuff(seed_of_corruption_soulburn seed_of_corruption_soulburn_debuff=1)
Define(seed_of_corruption_soulburn_debuff 114790)
	SpellInfo(seed_of_corruption_soulburn_debuff duration=18 tick=3)
Define(service_doomguard 157900)
	SpellInfo(service_doomguard cd=120 sharedcd=service_pet soulshards=1)
	SpellInfo(service_doomguard unusable=1 talent=!demonic_servitude_talent)
Define(service_felguard 111898)
	SpellInfo(service_felguard cd=120 sharedcd=service_pet soulshards=1)
Define(service_felhunter 111897)
	SpellInfo(service_felhunter cd=120 sharedcd=service_pet soulshards=1)
Define(service_imp 111859)
	SpellInfo(service_imp cd=120 sharedcd=service_pet soulshards=1)
Define(service_infernal 157901)
	SpellInfo(service_infernal cd=120 sharedcd=service_pet soulshards=1)
	SpellInfo(service_infernal unusable=1 talent=!demonic_servitude_talent)
Define(service_succubus 111896)
	SpellInfo(service_succubus cd=120 sharedcd=service_pet soulshards=1)
Define(service_pet 108501)
Define(service_voidwalker 111895)
	SpellInfo(service_voidwalker cd=120 sharedcd=service_pet soulshards=1)
Define(shadow_bolt 686)
	SpellInfo(shadow_bolt demonicfury=-25 specialization=demonology)
	SpellInfo(shadow_bolt travel_time=2.2) # maximum observed travel time with a bit of padding
	SpellAddBuff(shadow_bolt fel_molten_core_aura=1,target_health_pct,25 if_spell=the_codex_of_xerrath specialization=demonology)
	SpellAddBuff(shadow_bolt molten_core_aura=1,target_health_pct,25 if_spell=!the_codex_of_xerrath specialization=demonology)
Define(shadowburn 17877)
	SpellInfo(shadowburn soulshards=-0.5 target_health_pct=20)
	SpellAddBuff(shadowburn havoc_buff=-1 if_spell=havoc)
Define(shadowflame 205181)
	SpellInfo(shadowflame cd=14 soulshards=-1)
Define(shadowflame_debuff 205181)
	SpellInfo(shadowflame_debuff duration=8 haste=spell tick=2)
Define(shard_instability_buff 216457)
Define(siphon_life 63106)
	SpellAddTargetDebuff(siphon_life siphon_life_debuff=1)
Define(siphon_life_debuff 63106)
	SpellInfo(siphon_life_debuff duration=15 tick=3)
Define(soul_conduit_talent 21)
Define(soul_effigy 205178)
	SpellAddTargetDebuff(soul_effigy soul_effigy_debuff=1)
Define(soul_effigy_debuff 205178)
Define(soul_effigy_talent 19)
Define(soul_fire 6353)
	SpellInfo(soul_fire demonicfury=-30 travel_time=1)
	SpellAddBuff(soul_fire fel_molten_core_aura=-1,target_health_pct,!25 if_spell=the_codex_of_xerrath)
	SpellAddBuff(soul_fire molten_core_aura=-1,target_health_pct,!25 if_spell=!the_codex_of_xerrath)
	SpellAddBuff(soul_fire demon_rush_buff=1 itemset=T18 itemcount=2 specialization=demonology)
Define(soul_harvest 196098)
	SpellInfo(soul_harvest cd=120)
	SpellAddBuff(soul_harvest soul_harvest_buff=1)
Define(soul_harvest_buff 196098)
Define(soul_harvest_talent 16)
Define(soul_swap 86121)
	SpellInfo(soul_swap soulshards=1)
	SpellRequire(soul_swap replace soul_swap_soulburn=buff,soulburn_buff)
	SpellAddBuff(soul_swap soul_swap_buff=1)
Define(soul_swap_buff 86211)
	SpellInfo(soul_swap_buff duration=3)
Define(soul_swap_exhale 86213)
	SpellAddBuff(soul_swap_exhale soul_swap_buff=0)
Define(soul_swap_soulburn 119678)
	SpellInfo(soul_swap_soulburn soulshards=1)
	SpellAddTargetDebuff(soul_swap_soulburn agony_debuff=1 corruption_debuff=1 unstable_affliction_debuff=1)
Define(soulburn 74434)
	SpellInfo(soulburn cd=1 gcd=0 soulshards=1)
	SpellAddBuff(soulburn soulburn_buff=1)
Define(soulburn_buff 74434)
	SpellInfo(soulburn_buff duration=30)
Define(soulburn_haunt_talent 19)
Define(summon_darkglare 205180)
	SpellInfo(summon_darkglare soulshards=1 cd=24)
Define(summon_doomguard 18540)
	SpellInfo(summon_doomguard cd=180 soulshards=1)
	SpellInfo(summon_doomguard replace=summon_doomguard_demonic_servitude talent=demonic_servitude_talent)
Define(summon_doomguard_demonic_servitude 157757)
Define(summon_felguard 30146)
Define(summon_felhunter 691)
Define(summon_imp 688)
Define(summon_infernal 1122)
	SpellInfo(summon_infernal cd=180 soulshards=1)
	SpellInfo(summon_infernal replace=summon_infernal_demonic_servitude talent=demonic_servitude_talent)
Define(summon_infernal_demonic_servitude 157898)
Define(summon_succubus 712)
Define(summon_voidwalker 697)
Define(t18_class_trinket 124522)
Define(the_codex_of_xerrath 101508)
Define(unstable_affliction 30108)
    SpellInfo(unstable_affliction soulshards=1)
    SpellAddTargetDebuff(unstable_affliction unstable_affliction_debuff=1)
Define(unstable_affliction_debuff 30108)
    SpellInfo(unstable_affliction_debuff duration=8 haste=spell)
Define(wrathguard_mortal_cleave 115625)
	SpellInfo(wrathguard_mortal_cleave gcd=0)
	#SpellInfo(wrathguard_mortal_cleave energy=60)
	SpellAddTargetDebuff(wrathguard_mortal_cleave wrathguard_mortal_cleave_debuff=1)
Define(wrathguard_mortal_cleave_debuff 115625)
	SpellInfo(wrathguard_mortal_cleave_debuff duration=6)
Define(wrathguard_wrathstorm 115831)
	SpellInfo(wrathguard_wrathstorm cd=45 gcd=0)

# Talents
Define(absolute_corruption_talent 5)
Define(contagion_talent 4)
Define(deaths_embrace_talent 19)
Define(empowered_life_tap_talent 6)
Define(eradication_talent 5)
Define(fire_and_brimstone_talent 11)
Define(grimoire_of_synergy_talent 18)
Define(hand_of_doom_talent 10)
Define(haunt_talent 1)
Define(implosion_talent 6)
Define(malefic_grasp_talent 3)
Define(shadowy_inspiration_talent 1)
	Define(shadowy_inspiration_buff 196606)
Define(siphon_life_talent 10)
Define(sow_the_seeds_talent 11)
Define(summon_darkglare_talent 19)
Define(wreak_havoc_talent 19)
Define(writhe_in_agony_talent 2)

# Legendary items
Define(deadwind_harvester_buff 216708)
Define(sindorei_spite_icd 208871) # TODO should be the internal cooldown of the spell
Define(tormented_souls_buff 216695)
SpellList(concordance_of_the_legionfall_buff 243096 242583 242584 242586)

# Legion Artifact
Define(thalkiels_consumption 211714)
	SpellInfo(thalkiels_consumption cd=45)
Define(reap_souls 216698)
	SpellInfo(reap_souls unusable=1)
	SpellAddBuff(reap_souls deadwind_harvester=1)
	SpellAddBuff(reap_souls tormented_souls_buff=0)
	SpellRequire(reap_souls unusable 0=buff,tormented_souls_buff)
Define(tormented_agony_debuff 256807)
	SpellInfo(tormented_agony_debuff duration=8)

# Legion traits
Define(thalkiels_ascendance 238145)

# Pets
Define(doomguard 11859)
Define(wild_imp 55659)
Define(dreadstalker 98035)
Define(darkglare 103673)
Define(infernal 89)

# Non-default tags for OvaleSimulationCraft.
	SpellInfo(dark_soul_instability tag=cd)
	SpellInfo(dark_soul_knowledge tag=cd)
	SpellInfo(dark_soul_misery tag=cd)
	SpellInfo(grimoire_of_sacrifice tag=main)
	SpellInfo(havoc tag=shortcd)
	SpellInfo(metamorphosis tag=main)
	SpellInfo(service_doomguard tag=shortcd)
	SpellInfo(service_felguard tag=shortcd)
	SpellInfo(service_felhunter tag=shortcd)
	SpellInfo(service_imp tag=shortcd)
	SpellInfo(service_infernal tag=shortcd)
	SpellInfo(service_succubus tag=shortcd)
	SpellInfo(service_voidwalker tag=shortcd)
	SpellInfo(summon_felguard tag=shortcd)
	SpellInfo(summon_felhunter tag=shortcd)
	SpellInfo(summon_imp tag=shortcd)
	SpellInfo(summon_succubus tag=shortcd)
	SpellInfo(summon_voidwalker tag=shortcd)
]]
    OvaleScripts:RegisterScript("WARLOCK", nil, name, desc, code, "include")
end
