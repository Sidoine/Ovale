local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_demonhunter_spells"
	local desc = "[7.0] Ovale: DemonHunter spells"
	local code = [[

Define(annihilation 201427)
Define(blade_dance 188499)
	SpellInfo(blade_dance replace death_sweep=buff,metamorphosis_havoc_buff)
Define(chaos_cleave_talent 2)
Define(chaos_strike 162794)
	SpellInfo(chaos_strike replace annihilation=buff,metamorphosis_havoc_buff)
Define(consume_magic 183752)
	SpellInfo(consume_magic cd=15 gcd=0 interrupt=1 offgcd=1)
Define(death_sweep 210152)
Define(demon_spikes 203720)
	SpellInfo(demon_spikes cd=1 gcd=0 offgcd=1)
	SpellInfo(demon_spikes cd_haste=melee haste=melee specialization=vengeance)
	SpellAddBuff(demon_spikes demon_spikes_buff=1)
Define(demon_spikes_buff 203819)
	SpellInfo(demon_spikes_buff duration=6)
Define(demons_bite 162243)
Define(eye_beam 198013)
Define(fel_mastery_talent 1)
Define(fel_rush 195072)
Define(fiery_brand 204021)
	SpellInfo(fiery_brand cd=60 gcd=0 offgcd=1)
	SpellAddTargetDebuff(fiery_brand fiery_brand_debuff=1)
Define(fiery_brand_debuff 207744)
	SpellInfo(fiery_brand_debuff duration=8)
Define(immolation_aura 178740)
	SpellAddBuff(immolation_aura immolation_aura_buff=1)
Define(immolation_aura_buff 201122)
	SpellInfo(immolation_aura_buff duration=6)
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
Define(prepared_talent 4)
Define(shear 203782)
Define(sigil_of_flame 204596)
Define(soul_cleave 203798)
Define(throw_glaive 185123)
Define(vengeful_retreat 198793)
	SpellAddTargetDebuff(vengeful_retreat vengeful_retreat_debuff=1)
Define(vengeful_retreat_debuff 198813)
	SpellInfo(vengeful_retreat_debuff duration=3)


]]

	OvaleScripts:RegisterScript("DEMONHUNTER", nil, name, desc, code, "include")
end