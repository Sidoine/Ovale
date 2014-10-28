local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Warlock_Destruction_T16M"
	local desc = "[6.0] SimulationCraft: Warlock_Destruction_T16M"
	local code = [[
# Based on SimulationCraft profile "Warlock_Destruction_T16M".
#	class=warlock
#	spec=destruction
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Vb!....20.
#	pet=felhunter

Include(ovale_common)
Include(ovale_warlock_spells)

AddCheckBox(opt_potion_intellect ItemName(jade_serpent_potion) default)

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(jade_serpent_potion usable=1)
}

AddFunction DestructionDefaultActions
{
	#potion,name=jade_serpent,if=buff.bloodlust.react|target.health.pct<=20
	if BuffPresent(burst_haste_buff any=1) or target.HealthPercent() <= 20 UsePotionIntellect()
	#berserking
	Spell(berserking)
	#blood_fury
	Spell(blood_fury_sp)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#mannoroths_fury
	Spell(mannoroths_fury)
	#dark_soul,if=!talent.archimondes_darkness.enabled|(talent.archimondes_darkness.enabled&(charges=2|trinket.proc.intellect.react|trinket.stacking_proc.intellect.react>6|target.health.pct<=10))
	if not Talent(archimondes_darkness_talent) or Talent(archimondes_darkness_talent) and { Charges(dark_soul_instability) == 2 or BuffPresent(trinket_proc_intellect_buff) or BuffStacks(trinket_stacking_proc_intellect_buff) > 6 or target.HealthPercent() <= 10 } Spell(dark_soul_instability)
	#service_pet,if=talent.grimoire_of_service.enabled&!talent.demonbolt.enabled
	if Talent(grimoire_of_service_talent) and not Talent(demonbolt_talent) Spell(grimoire_felhunter)
	#summon_doomguard,if=!talent.demonic_servitude.enabled&active_enemies<5
	if not Talent(demonic_servitude_talent) and Enemies() < 5 Spell(summon_doomguard)
	#summon_infernal,,if=!talent.demonic_servitude.enabled&active_enemies>=5
	if not Talent(demonic_servitude_talent) and Enemies() >= 5 Spell(summon_infernal)
	#shadowburn,if=talent.charred_remains.enabled&(burning_ember>=2.5|target.time_to_die<20|trinket.proc.intellect.react|(trinket.stacking_proc.intellect.remains<cast_time*4&trinket.stacking_proc.intellect.remains>cast_time))
	if Talent(charred_remains_talent) and { BurningEmbers() / 10 >= 2.5 or target.TimeToDie() < 20 or BuffPresent(trinket_proc_intellect_buff) or BuffRemaining(trinket_stacking_proc_intellect_buff) < CastTime(shadowburn) * 4 and BuffRemaining(trinket_stacking_proc_intellect_buff) > CastTime(shadowburn) } Spell(shadowburn)
	#immolate,if=remains<=cast_time
	if target.DebuffRemaining(immolate_debuff) <= CastTime(immolate) Spell(immolate)
	#conflagrate,if=charges=2
	if Charges(conflagrate) == 2 Spell(conflagrate)
	#cataclysm
	Spell(cataclysm)
	#chaos_bolt,if=set_bonus.tier17_4pc=1&buff.chaotic_infusion.react
	if ArmorSetBonus(T17 4) == 1 and BuffPresent(chaotic_infusion_buff) Spell(chaos_bolt)
	#chaos_bolt,if=set_bonus.tier17_2pc=1&buff.backdraft.stack<3&(burning_ember>=2.5|(trinket.proc.intellect.react&trinket.proc.intellect.remains>cast_time)|buff.dark_soul.up)
	if ArmorSetBonus(T17 2) == 1 and BuffStacks(backdraft_buff) < 3 and { BurningEmbers() / 10 >= 2.5 or BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(dark_soul_instability_buff) } Spell(chaos_bolt)
	#chaos_bolt,if=talent.charred_remains.enabled&buff.backdraft.stack<3&(burning_ember>=2.5|(trinket.proc.intellect.react&trinket.proc.intellect.remains>cast_time)|buff.dark_soul.up)
	if Talent(charred_remains_talent) and BuffStacks(backdraft_buff) < 3 and { BurningEmbers() / 10 >= 2.5 or BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(dark_soul_instability_buff) } Spell(chaos_bolt)
	#chaos_bolt,if=buff.backdraft.stack<3&(burning_ember>=3.5|(trinket.proc.intellect.react&trinket.proc.intellect.remains>cast_time)|buff.dark_soul.up|(burning_ember>=3&buff.ember_master.react))
	if BuffStacks(backdraft_buff) < 3 and { BurningEmbers() / 10 >= 3.5 or BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(dark_soul_instability_buff) or BurningEmbers() / 10 >= 3 and BuffPresent(ember_master_buff) } Spell(chaos_bolt)
	#immolate,if=remains<=(duration*0.3)
	if target.DebuffRemaining(immolate_debuff) <= BaseDuration(immolate_debuff) * 0.3 Spell(immolate)
	#rain_of_fire,if=(!ticking|(talent.mannoroths_fury.enabled&buff.mannoroths_fury.up&buff.mannoroths_fury.remains<1))
	if not target.DebuffPresent(rain_of_fire_debuff) or Talent(mannoroths_fury_talent) and BuffPresent(mannoroths_fury_buff) and BuffRemaining(mannoroths_fury_buff) < 1 Spell(rain_of_fire)
	#conflagrate
	Spell(conflagrate)
	#incinerate
	Spell(incinerate)
}

AddFunction DestructionPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#dark_intent,if=!aura.spell_power_multiplier.up
	if not BuffPresent(spell_power_multiplier_buff any=1) Spell(dark_intent)
	#summon_pet,if=!talent.demonic_servitude.enabled&(!talent.grimoire_of_sacrifice.enabled|buff.grimoire_of_sacrifice.down)
	if not Talent(demonic_servitude_talent) and { not Talent(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice_buff) } and not pet.Present() Spell(summon_felhunter)
	#summon_doomguard,if=talent.demonic_servitude.enabled&active_enemies<5
	if Talent(demonic_servitude_talent) and Enemies() < 5 Spell(summon_doomguard)
	#summon_infernal,if=talent.demonic_servitude.enabled&active_enemies>=5
	if Talent(demonic_servitude_talent) and Enemies() >= 5 Spell(summon_infernal)
	#snapshot_stats
	#grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled&!talent.demonic_servitude.enabled
	if Talent(grimoire_of_sacrifice_talent) and not Talent(demonic_servitude_talent) and pet.Present() Spell(grimoire_of_sacrifice)
	#service_pet,if=talent.grimoire_of_service.enabled
	if Talent(grimoire_of_service_talent) Spell(grimoire_felhunter)
	#potion,name=jade_serpent
	UsePotionIntellect()
	#incinerate
	Spell(incinerate)
}

AddIcon specialization=destruction help=main enemies=1
{
	if not InCombat() DestructionPrecombatActions()
	DestructionDefaultActions()
}

AddIcon specialization=destruction help=aoe
{
	if not InCombat() DestructionPrecombatActions()
	DestructionDefaultActions()
}

### Required symbols
# arcane_torrent_mana
# archimondes_darkness_talent
# backdraft_buff
# berserking
# blood_fury_sp
# cataclysm
# chaos_bolt
# chaotic_infusion_buff
# charred_remains_talent
# conflagrate
# dark_intent
# dark_soul_instability
# dark_soul_instability_buff
# demonbolt_talent
# demonic_servitude_talent
# ember_master_buff
# grimoire_felhunter
# grimoire_of_sacrifice
# grimoire_of_sacrifice_buff
# grimoire_of_sacrifice_talent
# grimoire_of_service_talent
# immolate
# immolate_debuff
# incinerate
# jade_serpent_potion
# mannoroths_fury
# mannoroths_fury_buff
# mannoroths_fury_talent
# rain_of_fire
# rain_of_fire_debuff
# shadowburn
# summon_doomguard
# summon_felhunter
# summon_infernal
# trinket_proc_intellect_buff
# trinket_stacking_proc_intellect_buff
]]
	OvaleScripts:RegisterScript("WARLOCK", name, desc, code, "reference")
end
