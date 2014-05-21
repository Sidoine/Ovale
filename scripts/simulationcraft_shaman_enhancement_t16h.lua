local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Shaman_Enhancement_T16H"
	local desc = "[5.4] SimulationCraft: Shaman_Enhancement_T16H" 
	local code = [[
# Based on SimulationCraft profile "Shaman_Enhancement_T16H".
#	class=shaman
#	spec=enhancement
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#WZ!...0.1
#	glyphs=chain_lightning

Include(ovale_items)
Include(ovale_racials)
Include(ovale_shaman_spells)

AddFunction EnhancementAoeActions
{
	#fire_nova,if=active_flame_shock>=4
	if DebuffCountOnAny(flame_shock_debuff) >= 4 Spell(fire_nova)
	#wait,sec=cooldown.fire_nova.remains,if=active_flame_shock>=4&cooldown.fire_nova.remains<0.67
	if DebuffCountOnAny(flame_shock_debuff) >= 4 and SpellCooldown(fire_nova) < 0.67 wait Spell(fire_nova)
	#magma_totem,if=active_enemies>5&!totem.fire.active
	if Enemies() > 5 and not TotemPresent(fire) Spell(magma_totem)
	#searing_totem,if=active_enemies<=5&!totem.fire.active
	if Enemies() <= 5 and not TotemPresent(fire) Spell(searing_totem)
	#lava_lash,if=dot.flame_shock.ticking
	if target.DebuffPresent(flame_shock_debuff) Spell(lava_lash)
	#elemental_blast,if=talent.elemental_blast.enabled&buff.maelstrom_weapon.react>=1
	if TalentPoints(elemental_blast_talent) and BuffPresent(maelstrom_weapon_buff) >= 1 Spell(elemental_blast)
	#chain_lightning,if=active_enemies>=2&buff.maelstrom_weapon.react>=3
	if Enemies() >= 2 and BuffPresent(maelstrom_weapon_buff) >= 3 Spell(chain_lightning)
	#unleash_elements
	Spell(unleash_elements)
	#flame_shock,cycle_targets=1,if=!ticking
	if not target.DebuffPresent(flame_shock_debuff) Spell(flame_shock)
	#stormblast
	Spell(stormblast)
	#fire_nova,if=active_flame_shock>=3
	if DebuffCountOnAny(flame_shock_debuff) >= 3 Spell(fire_nova)
	#chain_lightning,if=active_enemies>=2&buff.maelstrom_weapon.react>=1
	if Enemies() >= 2 and BuffPresent(maelstrom_weapon_buff) >= 1 Spell(chain_lightning)
	#stormstrike
	Spell(stormstrike)
	#earth_shock,if=active_enemies<4
	if Enemies() < 4 Spell(earth_shock)
	#feral_spirit
	Spell(feral_spirit)
	#earth_elemental_totem,if=!active&cooldown.fire_elemental_totem.remains>=50
	if not TotemPresent(earth totem=earth_elemental_totem) and SpellCooldown(fire_elemental_totem) >= 50 Spell(earth_elemental_totem)
	#spiritwalkers_grace,moving=1
	if Speed() > 0 Spell(spiritwalkers_grace)
	#fire_nova,if=active_flame_shock>=1
	if DebuffCountOnAny(flame_shock_debuff) >= 1 Spell(fire_nova)
}

AddFunction EnhancementSingleActions
{
	#searing_totem,if=!totem.fire.active
	if not TotemPresent(fire) Spell(searing_totem)
	#unleash_elements,if=(talent.unleashed_fury.enabled|set_bonus.tier16_2pc_melee=1)
	if { TalentPoints(unleashed_fury_talent) or ArmorSetBonus(T16_melee 2) == 1 } Spell(unleash_elements)
	#elemental_blast,if=talent.elemental_blast.enabled&buff.maelstrom_weapon.react>=1
	if TalentPoints(elemental_blast_talent) and BuffPresent(maelstrom_weapon_buff) >= 1 Spell(elemental_blast)
	#lightning_bolt,if=buff.maelstrom_weapon.react=5
	if BuffPresent(maelstrom_weapon_buff) == 5 Spell(lightning_bolt)
	#feral_spirit,if=set_bonus.tier15_4pc_melee=1
	if ArmorSetBonus(T15_melee 4) == 1 Spell(feral_spirit)
	#stormblast
	Spell(stormblast)
	#stormstrike
	Spell(stormstrike)
	#flame_shock,if=buff.unleash_flame.up&!ticking
	if BuffPresent(unleash_flame_buff) and not target.DebuffPresent(flame_shock_debuff) Spell(flame_shock)
	#lava_lash
	Spell(lava_lash)
	#lightning_bolt,if=set_bonus.tier15_2pc_melee=1&buff.maelstrom_weapon.react>=4&!buff.ascendance.up
	if ArmorSetBonus(T15_melee 2) == 1 and BuffPresent(maelstrom_weapon_buff) >= 4 and not BuffPresent(ascendance_melee_buff) Spell(lightning_bolt)
	#flame_shock,if=(buff.unleash_flame.up&(dot.flame_shock.remains<10|action.flame_shock.tick_damage>dot.flame_shock.tick_dmg))|!ticking
	if { BuffPresent(unleash_flame_buff) and { target.DebuffRemains(flame_shock_debuff) < 10 or target.Damage(flame_shock_debuff) > target.LastEstimatedDamage(flame_shock_debuff) } } or not target.DebuffPresent(flame_shock_debuff) Spell(flame_shock)
	#unleash_elements
	Spell(unleash_elements)
	#frost_shock,if=glyph.frost_shock.enabled&set_bonus.tier14_4pc_melee=0
	if Glyph(glyph_of_frost_shock) and ArmorSetBonus(T14_melee 4) == 0 Spell(frost_shock)
	#lightning_bolt,if=buff.maelstrom_weapon.react>=3&!buff.ascendance.up
	if BuffPresent(maelstrom_weapon_buff) >= 3 and not BuffPresent(ascendance_melee_buff) Spell(lightning_bolt)
	#ancestral_swiftness,if=talent.ancestral_swiftness.enabled&buff.maelstrom_weapon.react<2
	if TalentPoints(ancestral_swiftness_talent) and BuffPresent(maelstrom_weapon_buff) < 2 Spell(ancestral_swiftness)
	#lightning_bolt,if=buff.ancestral_swiftness.up
	if BuffPresent(ancestral_swiftness_buff) Spell(lightning_bolt)
	#earth_shock,if=(!glyph.frost_shock.enabled|set_bonus.tier14_4pc_melee=1)
	if { not Glyph(glyph_of_frost_shock) or ArmorSetBonus(T14_melee 4) == 1 } Spell(earth_shock)
	#feral_spirit
	Spell(feral_spirit)
	#earth_elemental_totem,if=!active
	if not TotemPresent(earth totem=earth_elemental_totem) Spell(earth_elemental_totem)
	#spiritwalkers_grace,moving=1
	if Speed() > 0 Spell(spiritwalkers_grace)
	#lightning_bolt,if=buff.maelstrom_weapon.react>1&!buff.ascendance.up
	if BuffPresent(maelstrom_weapon_buff) > 1 and not BuffPresent(ascendance_melee_buff) Spell(lightning_bolt)
}

AddFunction EnhancementDefaultActions
{
	#wind_shear
	Interrupt()
	#bloodlust,if=target.health.pct<25|time>5
	if target.HealthPercent() < 25 or TimeInCombat() > 5 Bloodlust()
	#auto_attack
	#use_item,name=grips_of_celestial_harmony
	UseItemActions()
	#stormlash_totem,if=!active&!buff.stormlash.up&(buff.bloodlust.up|time>=60)
	if not TotemPresent(air totem=stormlash_totem) and not BuffPresent(stormlash_buff) and { BuffPresent(burst_haste any=1) or TimeInCombat() >= 60 } Spell(stormlash_totem)
	#virmens_bite_potion,if=time>60&(pet.primal_fire_elemental.active|pet.greater_fire_elemental.active|target.time_to_die<=60)
	if TimeInCombat() > 60 and { TotemPresent(fire totem=fire_elemental_totem) or TotemPresent(fire totem=fire_elemental_totem) or target.TimeToDie() <= 60 } UsePotionAgility()
	#blood_fury
	Spell(blood_fury)
	#arcane_torrent
	Spell(arcane_torrent)
	#berserking
	Spell(berserking)
	#elemental_mastery,if=talent.elemental_mastery.enabled&(talent.primal_elementalist.enabled&glyph.fire_elemental_totem.enabled&(cooldown.fire_elemental_totem.remains=0|cooldown.fire_elemental_totem.remains>=80))
	if TalentPoints(elemental_mastery_talent) and { TalentPoints(primal_elementalist_talent) and Glyph(glyph_of_fire_elemental_totem) and { not SpellCooldown(fire_elemental_totem) > 0 or SpellCooldown(fire_elemental_totem) >= 80 } } Spell(elemental_mastery)
	#elemental_mastery,if=talent.elemental_mastery.enabled&(talent.primal_elementalist.enabled&!glyph.fire_elemental_totem.enabled&(cooldown.fire_elemental_totem.remains=0|cooldown.fire_elemental_totem.remains>=50))
	if TalentPoints(elemental_mastery_talent) and { TalentPoints(primal_elementalist_talent) and not Glyph(glyph_of_fire_elemental_totem) and { not SpellCooldown(fire_elemental_totem) > 0 or SpellCooldown(fire_elemental_totem) >= 50 } } Spell(elemental_mastery)
	#elemental_mastery,if=talent.elemental_mastery.enabled&!talent.primal_elementalist.enabled
	if TalentPoints(elemental_mastery_talent) and not TalentPoints(primal_elementalist_talent) Spell(elemental_mastery)
	#fire_elemental_totem,if=!active
	if not TotemPresent(fire totem=fire_elemental_totem) Spell(fire_elemental_totem)
	#ascendance,if=cooldown.strike.remains>=3
	if SpellCooldown(strike) >= 3 Spell(ascendance_melee)
	#lifeblood,if=(glyph.fire_elemental_totem.enabled&(pet.primal_fire_elemental.active|pet.greater_fire_elemental.active))|!glyph.fire_elemental_totem.enabled
	if { Glyph(glyph_of_fire_elemental_totem) and { TotemPresent(fire totem=fire_elemental_totem) or TotemPresent(fire totem=fire_elemental_totem) } } or not Glyph(glyph_of_fire_elemental_totem) Spell(lifeblood)
	#run_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 EnhancementSingleActions()
	#run_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 EnhancementAoeActions()
}

AddFunction EnhancementPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#windfury_weapon,weapon=main
	if WeaponEnchantExpires(main) Spell(windfury_weapon)
	#flametongue_weapon,weapon=off
	if WeaponEnchantExpires(off) Spell(flametongue_weapon)
	#lightning_shield,if=!buff.lightning_shield.up
	if not BuffPresent(lightning_shield_buff) Spell(lightning_shield)
	#snapshot_stats
	#virmens_bite_potion
	UsePotionAgility()
}

AddIcon mastery=enhancement help=main
{
	if InCombat(no) EnhancementPrecombatActions()
	EnhancementDefaultActions()
}

### Required symbols
# ancestral_swiftness
# ancestral_swiftness_buff
# ancestral_swiftness_talent
# arcane_torrent
# ascendance_melee
# ascendance_melee_buff
# berserking
# blood_fury
# bloodlust
# chain_lightning
# earth_elemental_totem
# earth_shock
# elemental_blast
# elemental_blast_talent
# elemental_mastery
# elemental_mastery_talent
# feral_spirit
# fire_elemental_totem
# fire_nova
# flame_shock
# flame_shock_debuff
# flametongue_weapon
# frost_shock
# glyph_of_fire_elemental_totem
# glyph_of_frost_shock
# lava_lash
# lifeblood
# lightning_bolt
# lightning_shield
# lightning_shield_buff
# maelstrom_weapon_buff
# magma_totem
# primal_elementalist_talent
# searing_totem
# spiritwalkers_grace
# stormblast
# stormlash_buff
# stormlash_totem
# stormstrike
# strike
# unleash_elements
# unleash_flame_buff
# unleashed_fury_talent
# virmens_bite_potion
# wind_shear
# windfury_weapon
]]
	OvaleScripts:RegisterScript("SHAMAN", name, desc, code, "reference")
end