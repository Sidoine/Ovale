local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_shaman_enhancement_t17m"
	local desc = "[6.1] SimulationCraft: Shaman_Enhancement_T17M"
	local code = [[
# Based on SimulationCraft profile "Shaman_Enhancement_T17M".
#	class=shaman
#	spec=enhancement
#	talents=0002012
#	glyphs=chain_lightning/frost_shock

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_shaman_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=enhancement)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=enhancement)
AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default specialization=enhancement)
AddCheckBox(opt_bloodlust SpellName(bloodlust) specialization=enhancement)

AddFunction EnhancementUsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction EnhancementUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction EnhancementBloodlust
{
	if CheckBoxOn(opt_bloodlust) and DebuffExpires(burst_haste_debuff any=1)
	{
		Spell(bloodlust)
		Spell(heroism)
	}
}

AddFunction EnhancementGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(primal_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction EnhancementInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
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

### actions.default

AddFunction EnhancementDefaultMainActions
{
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 EnhancementSingleMainActions()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 EnhancementAoeMainActions()
}

AddFunction EnhancementDefaultShortCdActions
{
	#auto_attack
	EnhancementGetInMeleeRange()
	#elemental_mastery
	Spell(elemental_mastery)
	#liquid_magma,if=pet.searing_totem.remains>10|pet.magma_totem.remains>10|pet.fire_elemental_totem.remains>10
	if TotemRemaining(searing_totem) > 10 or TotemRemaining(magma_totem) > 10 or TotemRemaining(fire_elemental_totem) > 10 Spell(liquid_magma)
	#ancestral_swiftness
	Spell(ancestral_swiftness)
}

AddFunction EnhancementDefaultCdActions
{
	#wind_shear
	EnhancementInterruptActions()
	#bloodlust,if=target.health.pct<25|time>0.500
	if target.HealthPercent() < 25 or TimeInCombat() > 0.5 EnhancementBloodlust()
	#use_item,name=beating_heart_of_the_mountain
	EnhancementUseItemActions()
	#potion,name=draenic_agility,if=(talent.storm_elemental_totem.enabled&(pet.storm_elemental_totem.remains>=25|(cooldown.storm_elemental_totem.remains>target.time_to_die&pet.fire_elemental_totem.remains>=25)))|(!talent.storm_elemental_totem.enabled&pet.fire_elemental_totem.remains>=25)|target.time_to_die<=30
	if Talent(storm_elemental_totem_talent) and { TotemRemaining(storm_elemental_totem) >= 25 or SpellCooldown(storm_elemental_totem) > target.TimeToDie() and TotemRemaining(fire_elemental_totem) >= 25 } or not Talent(storm_elemental_totem_talent) and TotemRemaining(fire_elemental_totem) >= 25 or target.TimeToDie() <= 30 EnhancementUsePotionAgility()
	#blood_fury
	Spell(blood_fury_apsp)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#berserking
	Spell(berserking)
	#storm_elemental_totem
	Spell(storm_elemental_totem)
	#fire_elemental_totem
	Spell(fire_elemental_totem)
	#feral_spirit
	Spell(feral_spirit)

	unless { TotemRemaining(searing_totem) > 10 or TotemRemaining(magma_totem) > 10 or TotemRemaining(fire_elemental_totem) > 10 } and Spell(liquid_magma)
	{
		#ascendance
		if BuffExpires(ascendance_melee_buff) Spell(ascendance_melee)
	}
}

### actions.aoe

AddFunction EnhancementAoeMainActions
{
	#unleash_elements,if=active_enemies>=4&dot.flame_shock.ticking&(cooldown.shock.remains>cooldown.fire_nova.remains|cooldown.fire_nova.remains=0)
	if Enemies() >= 4 and target.DebuffPresent(flame_shock_debuff) and { SpellCooldown(shock) > SpellCooldown(fire_nova) or not SpellCooldown(fire_nova) > 0 } Spell(unleash_elements)
	#fire_nova,if=active_dot.flame_shock>=3
	if DebuffCountOnAny(flame_shock_debuff) >= 3 Spell(fire_nova)
	#wait,sec=cooldown.fire_nova.remains,if=!talent.echo_of_the_elements.enabled&active_dot.flame_shock>=4&cooldown.fire_nova.remains<=action.fire_nova.gcd%2
	unless not Talent(echo_of_the_elements_talent) and DebuffCountOnAny(flame_shock_debuff) >= 4 and SpellCooldown(fire_nova) <= GCD() / 2 and SpellCooldown(fire_nova) > 0
	{
		#magma_totem,if=!totem.fire.active
		if not TotemPresent(fire) and target.InRange(primal_strike) Spell(magma_totem)
		#lava_lash,if=dot.flame_shock.ticking&active_dot.flame_shock<active_enemies
		if target.DebuffPresent(flame_shock_debuff) and DebuffCountOnAny(flame_shock_debuff) < Enemies() Spell(lava_lash)
		#elemental_blast,if=!buff.unleash_flame.up&(buff.maelstrom_weapon.react>=4|buff.ancestral_swiftness.up)
		if not BuffPresent(unleash_flame_buff) and { BuffStacks(maelstrom_weapon_buff) >= 4 or BuffPresent(ancestral_swiftness_buff) } Spell(elemental_blast)
		#chain_lightning,if=buff.maelstrom_weapon.react=5&((glyph.chain_lightning.enabled&active_enemies>=3)|(!glyph.chain_lightning.enabled&active_enemies>=2))
		if BuffStacks(maelstrom_weapon_buff) == 5 and { Glyph(glyph_of_chain_lightning) and Enemies() >= 3 or not Glyph(glyph_of_chain_lightning) and Enemies() >= 2 } Spell(chain_lightning)
		#unleash_elements,if=active_enemies<4
		if Enemies() < 4 Spell(unleash_elements)
		#flame_shock,if=dot.flame_shock.remains<=9|!ticking
		if target.DebuffRemaining(flame_shock_debuff) <= 9 or not target.DebuffPresent(flame_shock_debuff) Spell(flame_shock)
		#windstrike,target=1,if=!debuff.stormstrike.up
		if not target.DebuffPresent(stormstrike_debuff) Spell(windstrike)
		#windstrike,target=2,if=!debuff.stormstrike.up
		if not target.DebuffPresent(stormstrike_debuff) Spell(windstrike text=other)
		#windstrike,target=3,if=!debuff.stormstrike.up
		if not target.DebuffPresent(stormstrike_debuff) Spell(windstrike text=3)
		#windstrike
		Spell(windstrike)
		#elemental_blast,if=!buff.unleash_flame.up&buff.maelstrom_weapon.react>=3
		if not BuffPresent(unleash_flame_buff) and BuffStacks(maelstrom_weapon_buff) >= 3 Spell(elemental_blast)
		#chain_lightning,if=(buff.maelstrom_weapon.react>=3|buff.ancestral_swiftness.up)&((glyph.chain_lightning.enabled&active_enemies>=4)|(!glyph.chain_lightning.enabled&active_enemies>=3))
		if { BuffStacks(maelstrom_weapon_buff) >= 3 or BuffPresent(ancestral_swiftness_buff) } and { Glyph(glyph_of_chain_lightning) and Enemies() >= 4 or not Glyph(glyph_of_chain_lightning) and Enemies() >= 3 } Spell(chain_lightning)
		#magma_totem,if=pet.magma_totem.remains<=20&!pet.fire_elemental_totem.active&!buff.liquid_magma.up
		if TotemRemaining(magma_totem) <= 20 and not TotemPresent(fire_elemental_totem) and not BuffPresent(liquid_magma_buff) and target.InRange(primal_strike) Spell(magma_totem)
		#lightning_bolt,if=buff.maelstrom_weapon.react=5&glyph.chain_lightning.enabled&active_enemies<3
		if BuffStacks(maelstrom_weapon_buff) == 5 and Glyph(glyph_of_chain_lightning) and Enemies() < 3 Spell(lightning_bolt)
		#stormstrike,target=1,if=!debuff.stormstrike.up
		if not target.DebuffPresent(stormstrike_debuff) Spell(stormstrike)
		#stormstrike,target=2,if=!debuff.stormstrike.up
		if not target.DebuffPresent(stormstrike_debuff) Spell(stormstrike text=other)
		#stormstrike,target=3,if=!debuff.stormstrike.up
		if not target.DebuffPresent(stormstrike_debuff) Spell(stormstrike text=3)
		#stormstrike
		Spell(stormstrike)
		#lava_lash
		Spell(lava_lash)
		#fire_nova,if=active_dot.flame_shock>=2
		if DebuffCountOnAny(flame_shock_debuff) >= 2 Spell(fire_nova)
		#elemental_blast,if=!buff.unleash_flame.up&buff.maelstrom_weapon.react>=1
		if not BuffPresent(unleash_flame_buff) and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(elemental_blast)
		#chain_lightning,if=(buff.maelstrom_weapon.react>=1|buff.ancestral_swiftness.up)&((glyph.chain_lightning.enabled&active_enemies>=3)|(!glyph.chain_lightning.enabled&active_enemies>=2))
		if { BuffStacks(maelstrom_weapon_buff) >= 1 or BuffPresent(ancestral_swiftness_buff) } and { Glyph(glyph_of_chain_lightning) and Enemies() >= 3 or not Glyph(glyph_of_chain_lightning) and Enemies() >= 2 } Spell(chain_lightning)
		#lightning_bolt,if=(buff.maelstrom_weapon.react>=1|buff.ancestral_swiftness.up)&glyph.chain_lightning.enabled&active_enemies<3
		if { BuffStacks(maelstrom_weapon_buff) >= 1 or BuffPresent(ancestral_swiftness_buff) } and Glyph(glyph_of_chain_lightning) and Enemies() < 3 Spell(lightning_bolt)
		#fire_nova,if=active_dot.flame_shock>=1
		if DebuffCountOnAny(flame_shock_debuff) >= 1 Spell(fire_nova)
	}
}

### actions.precombat

AddFunction EnhancementPrecombatMainActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=buttered_sturgeon
	#lightning_shield,if=!buff.lightning_shield.up
	if not BuffPresent(lightning_shield_buff) Spell(lightning_shield)
}

AddFunction EnhancementPrecombatShortCdPostConditions
{
	not BuffPresent(lightning_shield_buff) and Spell(lightning_shield)
}

AddFunction EnhancementPrecombatCdActions
{
	unless not BuffPresent(lightning_shield_buff) and Spell(lightning_shield)
	{
		#snapshot_stats
		#potion,name=draenic_agility
		EnhancementUsePotionAgility()
	}
}

AddFunction EnhancementPrecombatCdPostConditions
{
	not BuffPresent(lightning_shield_buff) and Spell(lightning_shield)
}

### actions.single

AddFunction EnhancementSingleMainActions
{
	#searing_totem,if=!totem.fire.active
	if not TotemPresent(fire) Spell(searing_totem)
	#unleash_elements,if=(talent.unleashed_fury.enabled|set_bonus.tier16_2pc_melee=1)
	if Talent(unleashed_fury_talent) or ArmorSetBonus(T16_melee 2) == 1 Spell(unleash_elements)
	#elemental_blast,if=buff.maelstrom_weapon.react>=4|buff.ancestral_swiftness.up
	if BuffStacks(maelstrom_weapon_buff) >= 4 or BuffPresent(ancestral_swiftness_buff) Spell(elemental_blast)
	#windstrike
	Spell(windstrike)
	#lightning_bolt,if=buff.maelstrom_weapon.react=5
	if BuffStacks(maelstrom_weapon_buff) == 5 Spell(lightning_bolt)
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
	#elemental_blast,if=buff.maelstrom_weapon.react>=1
	if BuffStacks(maelstrom_weapon_buff) >= 1 Spell(elemental_blast)
	#lightning_bolt,if=(buff.maelstrom_weapon.react>=1&!buff.ascendance.up)|buff.ancestral_swiftness.up
	if BuffStacks(maelstrom_weapon_buff) >= 1 and not BuffPresent(ascendance_melee_buff) or BuffPresent(ancestral_swiftness_buff) Spell(lightning_bolt)
	#searing_totem,if=pet.searing_totem.remains<=20&!pet.fire_elemental_totem.active&!buff.liquid_magma.up
	if TotemRemaining(searing_totem) <= 20 and not TotemPresent(fire_elemental_totem) and not BuffPresent(liquid_magma_buff) Spell(searing_totem)
}

### Enhancement icons.

AddCheckBox(opt_shaman_enhancement_aoe L(AOE) default specialization=enhancement)

AddIcon checkbox=!opt_shaman_enhancement_aoe enemies=1 help=shortcd specialization=enhancement
{
	unless not InCombat() and EnhancementPrecombatShortCdPostConditions()
	{
		EnhancementDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=shortcd specialization=enhancement
{
	unless not InCombat() and EnhancementPrecombatShortCdPostConditions()
	{
		EnhancementDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=enhancement
{
	if not InCombat() EnhancementPrecombatMainActions()
	EnhancementDefaultMainActions()
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=aoe specialization=enhancement
{
	if not InCombat() EnhancementPrecombatMainActions()
	EnhancementDefaultMainActions()
}

AddIcon checkbox=!opt_shaman_enhancement_aoe enemies=1 help=cd specialization=enhancement
{
	if not InCombat() EnhancementPrecombatCdActions()
	unless not InCombat() and EnhancementPrecombatCdPostConditions()
	{
		EnhancementDefaultCdActions()
	}
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=cd specialization=enhancement
{
	if not InCombat() EnhancementPrecombatCdActions()
	unless not InCombat() and EnhancementPrecombatCdPostConditions()
	{
		EnhancementDefaultCdActions()
	}
}

### Required symbols
# ancestral_swiftness
# ancestral_swiftness_buff
# arcane_torrent_mana
# ascendance_melee
# ascendance_melee_buff
# berserking
# blood_fury_apsp
# bloodlust
# chain_lightning
# draenic_agility_potion
# echo_of_the_elements_talent
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
# heroism
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
# stormstrike_debuff
# unleash_elements
# unleash_flame_buff
# unleashed_fury_talent
# war_stomp
# wind_shear
# windstrike
]]
	OvaleScripts:RegisterScript("SHAMAN", "enhancement", name, desc, code, "script")
end
