local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_demonhunter_spells"
	local desc = "[7.0] Ovale: DemonHunter spells"
	local code = [[

Define(annihilation 201427)
	SpellInfo(annihilation fury=40)
Define(blade_dance 188499)
	SpellInfo(blade_dance replace death_sweep=buff,metamorphosis_havoc_buff)
	SpellInfo(blade_dance fury=35)
Define(bloodlet_talent 9)
Define(chaos_blades 211048)
	SpellInfo(chaos_blades cd=120)
Define(chaos_blades_buff 211048)
	SpellInfo(chaos_blades_buff duration=12)
Define(chaos_cleave_talent 2)
Define(chaos_strike 162794)
	SpellInfo(chaos_strike replace annihilation=buff,metamorphosis_havoc_buff)
	SpellInfo(chaos_strike fury=40)
Define(consume_magic 183752)
	SpellInfo(consume_magic cd=15 gcd=0 interrupt=1 offgcd=1)
Define(death_sweep 210152)
	SpellInfo(death_sweep fury=35)
Define(demonic_talent 21)
Define(demon_spikes 203720)
	SpellInfo(demon_spikes cd=1 gcd=0 offgcd=1)
	SpellInfo(demon_spikes cd_haste=melee haste=melee specialization=vengeance)
	SpellAddBuff(demon_spikes demon_spikes_buff=1)
Define(demon_spikes_buff 203819)
	SpellInfo(demon_spikes_buff duration=6)
Define(demons_bite 162243)
Define(empower_wards 218256)
	SpellInfo(empower_wards cd=20 gcd=0 offgcd=1)
	SpellAddBuff(empower_wards empower_wards_buff=1)
Define(empower_wards_buff 218256)
	SpellInfo(empower_wards_buff duration=6)
Define(eye_beam 198013)
	SpellInfo(eye_beam fury=50)
Define(felblade 213241)
	SpellInfo(felblade cd=15)
	SpellInfo(felblade cd_haste=melee haste=melee specialization=vengeance)
Define(fel_barrage 211053)
	SpellInfo(fel_barrage cd=30)
Define(fel_devastation 212084)
	SpellInfo(fel_devastation cd=60)
Define(fel_eruption 211881)
	SpellInfo(fel_eruption cd=35)
	SpellInfo(fel_eruption fury=20)
Define(fel_eruption_talent 14)
Define(fel_mastery_talent 1)
Define(fel_rush 195072)
Define(fiery_brand 204021)
	SpellInfo(fiery_brand cd=60 gcd=0 offgcd=1)
	SpellAddTargetDebuff(fiery_brand fiery_brand_debuff=1)
Define(fiery_brand_debuff 207744)
	SpellInfo(fiery_brand_debuff duration=8)
Define(first_blood_talent 8)
<<<<<<< HEAD
Define(flame_crash_talent 8)
=======
Define(fracture 209795)	
Define(frailty_debuff 224509)
	SpellInfo(frailty_debuff duration=15)
>>>>>>> 31f3a355ee8c745e967146a46fa098d49999846d
Define(fury_of_the_ilidari 201467)
	SpellInfo(fury_of_the_ilidari cd=60)
Define(immolation_aura 178740)
	SpellAddBuff(immolation_aura immolation_aura_buff=1)
Define(immolation_aura_buff 201122)
	SpellInfo(immolation_aura_buff duration=6)
Define(infernal_strike 189110)
	SpellInfo(infernal_strike cd=20)
Define(infernal_strike_debuff 189110)
Define(metamorphosis_havoc 191427)
	SpellInfo(metamorphosis_havoc cd=300)
	SpellAddBuff(metamorphosis_havoc metamorphosis_havoc_buff=1)
Define(metamorphosis_havoc_buff 162264)
	SpellInfo(metamorphosis_havoc_buff duration=30)
Define(metamorphosis_veng 187827)
	SpellInfo(metamorphosis_veng cd=180 gcd=0 offgcd=1)
	SpellAddBuff(metamorphosis_veng metamorphosis_veng_buff=1)
Define(metamorphosis_veng_buff 187827)
	SpellInfo(metamorphosis_veng_buff duration=15)
Define(momentum_buff 208628)
Define(nemesis 206491)
	SpellInfo(nemesis cd=120)
	SpellAddTargetDebuff(nemesis nemesis_debuff=1)
Define(nemesis_debuff 206491)
Define(pick_up_fragment 210788)
Define(prepared_talent 4)
Define(shear 203782)
Define(sigil_of_flame 204596)
	SpellInfo(sigil_of_flame cd=30)
Define(sigil_of_flame_debuff 204598)
Define(sigil_of_silence 202137)
Define(sigil_of_misery 207684)
Define(soul_cleave  228477)
	SpellInfo(soul_cleave pain=30 extra_pain=30)
	SpellAddBuff(soul_cleave soul_fragments=0)
Define(soul_carver 214743)
	SpellInfo(soul_carver cd=40)
<<<<<<< HEAD
Define(soul_fragments_buff 204256)
Define(felblade 213241)
	SpellInfo(felblade cd=15)
	SpellInfo(felblade cd_haste=melee haste=melee specialization=vengeance)
Define(fel_eruption 211881)
Define(empower_wards 218256)
	SpellInfo(empower_wards cd=20 gcd=0 offgcd=1)
	SpellAddBuff(empower_wards empower_wards_buff=1)
Define(empower_wards_buff 218256)
	SpellInfo(empower_wards_buff duration=6)
<<<<<<< HEAD
 
  

=======
=======
>>>>>>> 31f3a355ee8c745e967146a46fa098d49999846d
Define(soul_fragments 203981)
	SpellInfo(soul_fragments duration=20)		
Define(soul_barrier 227225)
	SpellInfo(soul_barrier cd=20)
Define(spirit_bomb 218679)	
<<<<<<< HEAD
Define(fel_devastation 212084)
	SpellInfo(fel_devastation cd=60)
Define(fracture 209795)	
>>>>>>> ce984cf99194413d14f5b0d618e2885bd969d654
=======
Define(throw_glaive 185123)
Define(vengeful_retreat 198793)
	SpellAddTargetDebuff(vengeful_retreat vengeful_retreat_debuff=1)
Define(vengeful_retreat_debuff 198813)
	SpellInfo(vengeful_retreat_debuff duration=3)

# Artifact traits
Define(anguish_of_the_deceiver 201473)
Define(fiery_demise 212817)
Define(fury_of_the_illidari 201467)
	SpellInfo(fury_of_the_ilidari cd=60)

# Talents
Define(chaos_blades_talent 19)
Define(demonic_appetite_talent 6)
Define(felblade_talent 4)
Define(master_of_the_glaive_talent 16)
Define(momentum_talent 13)
Define(nemesis_talent 15)

SpellInfo(fel_rush tag=shortcd)
>>>>>>> 31f3a355ee8c745e967146a46fa098d49999846d
]]

	OvaleScripts:RegisterScript("DEMONHUNTER", nil, name, desc, code, "include")
end
