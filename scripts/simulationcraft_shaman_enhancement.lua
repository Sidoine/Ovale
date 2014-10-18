local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Shaman_Enhancement_T16M"
	local desc = "[6.0.2] SimulationCraft: Shaman_Enhancement_T16M"
	local code = [[
# Based on SimulationCraft profile "Shaman_Enhancement_T16M".
#	class=shaman
#	spec=enhancement
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#WZ!...1.1.
#	glyphs=chain_lightning/frost_shock

Include(ovale_common)
Include(ovale_shaman_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)
AddCheckBox(opt_bloodlust SpellName(bloodlust) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction Bloodlust
{
	if CheckBoxOn(opt_bloodlust) and DebuffExpires(burst_haste_debuff any=1)
	{
		Spell(bloodlust)
		Spell(heroism)
	}
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
	{
		Spell(wind_shear)
		if not target.Classification(worldboss)
		{
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			Spell(war_stomp)
		}
	}
}

AddFunction EnhancementPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#lightning_shield,if=!buff.lightning_shield.up
	if not BuffPresent(lightning_shield_buff) Spell(lightning_shield)
	#snapshot_stats
	#potion,name=virmens_bite
	UsePotionAgility()
}

AddFunction EnhancementDefaultActions
{
	#wind_shear
	InterruptActions()
	#bloodlust,if=target.health.pct<25|time>0.500
	if target.HealthPercent() < 25 or TimeInCombat() > 0.5 Bloodlust()
	#auto_attack
	#potion,name=virmens_bite,if=(talent.storm_elemental_totem.enabled&pet.storm_elemental_totem.remains>=25)|(!talent.storm_elemental_totem.enabled&pet.fire_elemental_totem.remains>=25)|target.time_to_die<=30
	if Talent(storm_elemental_totem_talent) and TotemRemaining(air totem=storm_elemental_totem) >= 25 or not Talent(storm_elemental_totem_talent) and TotemRemaining(fire totem=fire_elemental_totem) >= 25 or target.TimeToDie() <= 30 UsePotionAgility()
	#blood_fury
	Spell(blood_fury_apsp)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#berserking
	Spell(berserking)
	#elemental_mastery
	Spell(elemental_mastery)
	#storm_elemental_totem
	Spell(storm_elemental_totem)
	#fire_elemental_totem
	Spell(fire_elemental_totem)
	#ascendance
	Spell(ascendance_melee)
	#feral_spirit
	Spell(feral_spirit)
	#liquid_magma,if=pet.searing_totem.remains>=15|pet.magma_totem.remains>=15|pet.fire_elemental_totem.remains>=15
	if TotemRemaining(fire totem=searing_totem) >= 15 or TotemRemaining(fire totem=magma_totem) >= 15 or TotemRemaining(fire totem=fire_elemental_totem) >= 15 Spell(liquid_magma)
	#ancestral_swiftness
	Spell(ancestral_swiftness)
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 EnhancementSingleActions()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 EnhancementAoeActions()
}

AddFunction EnhancementAoeActions
{
	#unleash_elements,if=active_enemies>=4&dot.flame_shock.ticking&(cooldown.shock.remains>cooldown.fire_nova.remains|cooldown.fire_nova.remains=0)
	if Enemies() >= 4 and target.DebuffPresent(flame_shock_debuff) and { SpellCooldown(shock) > SpellCooldown(fire_nova) or not SpellCooldown(fire_nova) > 0 } Spell(unleash_elements)
	#fire_nova,if=active_dot.flame_shock>=3
	if DebuffCountOnAny(flame_shock_debuff) >= 3 Spell(fire_nova)
	#wait,sec=cooldown.fire_nova.remains,if=active_dot.flame_shock>=4&cooldown.fire_nova.remains<=action.fire_nova.gcd
	unless DebuffCountOnAny(flame_shock_debuff) >= 4 and SpellCooldown(fire_nova) <= GCD() and SpellCooldown(fire_nova) > 0
	{
		#magma_totem,if=!totem.fire.active
		if not TotemPresent(fire) and target.InRange(primal_strike) Spell(magma_totem)
		#lava_lash,if=dot.flame_shock.ticking
		if target.DebuffPresent(flame_shock_debuff) Spell(lava_lash)
		#elemental_blast,if=buff.maelstrom_weapon.react>=1
		if BuffStacks(maelstrom_weapon_buff) >= 1 Spell(elemental_blast)
		#chain_lightning,if=glyph.chain_lightning.enabled&active_enemies>=4&(buff.maelstrom_weapon.react=5|(buff.ancestral_swiftness.up&buff.maelstrom_weapon.react>=3))
		if Glyph(glyph_of_chain_lightning) and Enemies() >= 4 and { BuffStacks(maelstrom_weapon_buff) == 5 or BuffPresent(ancestral_swiftness_buff) and BuffStacks(maelstrom_weapon_buff) >= 3 } Spell(chain_lightning)
		#unleash_elements,if=active_enemies<4
		if Enemies() < 4 Spell(unleash_elements)
		#flame_shock,cycle_targets=1,if=!ticking
		if not target.DebuffPresent(flame_shock_debuff) Spell(flame_shock)
		#lightning_bolt,if=(!glyph.chain_lightning.enabled|active_enemies<=3)&(buff.maelstrom_weapon.react=5|(buff.ancestral_swiftness.up&buff.maelstrom_weapon.react>=3))
		if { not Glyph(glyph_of_chain_lightning) or Enemies() <= 3 } and { BuffStacks(maelstrom_weapon_buff) == 5 or BuffPresent(ancestral_swiftness_buff) and BuffStacks(maelstrom_weapon_buff) >= 3 } Spell(lightning_bolt)
		#windstrike
		if BuffPresent(ascendance_melee_buff) Spell(windstrike)
		#fire_nova,if=active_dot.flame_shock>=2
		if DebuffCountOnAny(flame_shock_debuff) >= 2 Spell(fire_nova)
		#chain_lightning,if=active_enemies>=2&buff.maelstrom_weapon.react>=1
		if Enemies() >= 2 and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(chain_lightning)
		#stormstrike
		Spell(stormstrike)
		#frost_shock,if=active_enemies<4
		if Enemies() < 4 Spell(frost_shock)
		#chain_lightning,if=glyph.chain_lightning.enabled&active_enemies>=4&buff.maelstrom_weapon.react>=1
		if Glyph(glyph_of_chain_lightning) and Enemies() >= 4 and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(chain_lightning)
		#lightning_bolt,if=(!glyph.chain_lightning.enabled|active_enemies<=3)&buff.maelstrom_weapon.react>=1
		if { not Glyph(glyph_of_chain_lightning) or Enemies() <= 3 } and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(lightning_bolt)
		#fire_nova,if=active_dot.flame_shock>=1
		if DebuffCountOnAny(flame_shock_debuff) >= 1 Spell(fire_nova)
	}
}

AddFunction EnhancementSingleActions
{
	#searing_totem,if=!totem.fire.active
	if not TotemPresent(fire) Spell(searing_totem)
	#unleash_elements,if=(talent.unleashed_fury.enabled|set_bonus.tier16_2pc_melee=1)
	if Talent(unleashed_fury_talent) or ArmorSetBonus(T16_melee 2) == 1 Spell(unleash_elements)
	#elemental_blast,if=buff.maelstrom_weapon.react>=1
	if BuffStacks(maelstrom_weapon_buff) >= 1 Spell(elemental_blast)
	#lightning_bolt,if=buff.maelstrom_weapon.react=5|(buff.maelstrom_weapon.react>=4&!buff.ascendance.up)|(buff.ancestral_swiftness.up&buff.maelstrom_weapon.react>=3)
	if BuffStacks(maelstrom_weapon_buff) == 5 or BuffStacks(maelstrom_weapon_buff) >= 4 and not BuffPresent(ascendance_melee_buff) or BuffPresent(ancestral_swiftness_buff) and BuffStacks(maelstrom_weapon_buff) >= 3 Spell(lightning_bolt)
	#windstrike
	if BuffPresent(ascendance_melee_buff) Spell(windstrike)
	#stormstrike
	Spell(stormstrike)
	#lava_lash
	Spell(lava_lash)
	#flame_shock,if=(talent.elemental_fusion.enabled&buff.elemental_fusion.stack=2&buff.unleash_flame.up&dot.flame_shock.remains<16)|(!talent.elemental_fusion.enabled&buff.unleash_flame.up&dot.flame_shock.remains<=9)|!ticking
	if Talent(elemental_fusion_talent) and BuffStacks(elemental_fusion_buff) == 2 and BuffPresent(unleash_flame_buff) and target.DebuffRemaining(flame_shock_debuff) < 16 or not Talent(elemental_fusion_talent) and BuffPresent(unleash_flame_buff) and target.DebuffRemaining(flame_shock_debuff) <= 9 or not target.DebuffPresent(flame_shock_debuff) Spell(flame_shock)
	#unleash_elements
	Spell(unleash_elements)
	#frost_shock,if=(talent.elemental_fusion.enabled&dot.flame_shock.remains>=16)|!talent.elemental_fusion.enabled
	if Talent(elemental_fusion_talent) and target.DebuffRemaining(flame_shock_debuff) >= 16 or not Talent(elemental_fusion_talent) Spell(frost_shock)
	#lightning_bolt,if=buff.maelstrom_weapon.react>=1&!buff.ascendance.up
	if BuffStacks(maelstrom_weapon_buff) >= 1 and not BuffPresent(ascendance_melee_buff) Spell(lightning_bolt)
	#searing_totem,if=pet.searing_totem.remains<=20&!pet.fire_elemental_totem.active&!buff.liquid_magma.up
	if TotemRemaining(fire totem=searing_totem) <= 20 and not TotemPresent(fire totem=fire_elemental_totem) and not BuffPresent(liquid_magma_buff) Spell(searing_totem)
}

AddIcon specialization=enhancement help=main enemies=1
{
	if not InCombat() EnhancementPrecombatActions()
	EnhancementDefaultActions()
}

AddIcon specialization=enhancement help=aoe
{
	if not InCombat() EnhancementPrecombatActions()
	EnhancementDefaultActions()
}

### Required symbols
# ancestral_swiftness
# ancestral_swiftness_buff
# arcane_torrent_mana
# ascendance_melee
# ascendance_melee_buff
# berserking
# blood_fury_apsp
# chain_lightning
# elemental_blast
# elemental_fusion_buff
# elemental_fusion_talent
# elemental_mastery
# feral_spirit
# fire_elemental_totem
# fire_nova
# flame_shock
# flame_shock_debuff
# frost_shock
# glyph_of_chain_lightning
# lava_lash
# lightning_bolt
# lightning_shield
# lightning_shield_buff
# liquid_magma
# liquid_magma_buff
# maelstrom_weapon_buff
# magma_totem
# primal_strike
# quaking_palm
# searing_totem
# shock
# storm_elemental_totem
# storm_elemental_totem_talent
# stormstrike
# unleash_elements
# unleash_flame_buff
# unleashed_fury_talent
# virmens_bite_potion
# war_stomp
# wind_shear
# windstrike
]]
	OvaleScripts:RegisterScript("SHAMAN", name, desc, code, "reference")
end
