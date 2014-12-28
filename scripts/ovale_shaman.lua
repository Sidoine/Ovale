local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_shaman"
	local desc = "[6.0] Ovale: Rotations (Elemental, Enhancement, Restoration)"
	local code = [[
# Shaman rotation functions based on SimulationCraft.

Include(ovale_common)
Include(ovale_shaman_spells)

AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default specialization=enhancement)
AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=elemental)
AddCheckBox(opt_bloodlust SpellName(bloodlust) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
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

###
### Elemental
###
# Based on SimulationCraft profile "Shaman_Elemental_T17M".
#	class=shaman
#	spec=elemental
#	talents=0001011
#	glyphs=chain_lightning

# ActionList: ElementalDefaultActions --> main, shortcd, cd

AddFunction ElementalDefaultActions
{
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ElementalSingleActions()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 ElementalAoeActions()
}

AddFunction ElementalDefaultShortCdActions
{
	#elemental_mastery,if=action.lava_burst.cast_time>=1.2
	if CastTime(lava_burst) >= 1.2 Spell(elemental_mastery)
	#ancestral_swiftness,if=!buff.ascendance.up
	if not BuffPresent(ascendance_caster_buff) Spell(ancestral_swiftness)
	#liquid_magma,if=pet.searing_totem.remains>=15|pet.fire_elemental_totem.remains>=15
	if TotemRemaining(searing_totem) >= 15 or TotemRemaining(fire_elemental_totem) >= 15 Spell(liquid_magma)
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ElementalSingleShortCdActions()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 ElementalAoeShortCdActions()
}

AddFunction ElementalDefaultCdActions
{
	#wind_shear
	InterruptActions()
	#bloodlust,if=target.health.pct<25|time>0.500
	if target.HealthPercent() < 25 or TimeInCombat() > 0.5 Bloodlust()
	#potion,name=draenic_intellect,if=buff.ascendance.up|target.time_to_die<=30
	if BuffPresent(ascendance_caster_buff) or target.TimeToDie() <= 30 UsePotionIntellect()
	#berserking,if=!buff.bloodlust.up&!buff.elemental_mastery.up&(set_bonus.tier15_4pc_caster=1|(buff.ascendance.cooldown_remains=0&(dot.flame_shock.remains>buff.ascendance.duration|level<87)))
	if not BuffPresent(burst_haste_buff any=1) and not BuffPresent(elemental_mastery_buff) and { ArmorSetBonus(T15_caster 4) == 1 or not SpellCooldown(ascendance_caster) > 0 and { target.DebuffRemaining(flame_shock_debuff) > BaseDuration(ascendance_caster_buff) or Level() < 87 } } Spell(berserking)
	#blood_fury,if=buff.bloodlust.up|buff.ascendance.up|((cooldown.ascendance.remains>10|level<87)&cooldown.fire_elemental_totem.remains>10)
	if BuffPresent(burst_haste_buff any=1) or BuffPresent(ascendance_caster_buff) or { SpellCooldown(ascendance_caster) > 10 or Level() < 87 } and SpellCooldown(fire_elemental_totem) > 10 Spell(blood_fury_apsp)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#storm_elemental_totem
	Spell(storm_elemental_totem)
	#fire_elemental_totem,if=!active
	if not TotemPresent(fire_elemental_totem) Spell(fire_elemental_totem)
	#ascendance,if=active_enemies>1|(dot.flame_shock.remains>buff.ascendance.duration&(target.time_to_die<20|buff.bloodlust.up|time>=60)&cooldown.lava_burst.remains>0)
	if { Enemies() > 1 or target.DebuffRemaining(flame_shock_debuff) > BaseDuration(ascendance_caster_buff) and { target.TimeToDie() < 20 or BuffPresent(burst_haste_buff any=1) or TimeInCombat() >= 60 } and SpellCooldown(lava_burst) > 0 } and BuffExpires(ascendance_caster_buff) Spell(ascendance_caster)
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ElementalSingleCdActions()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 ElementalAoeCdActions()
}

# ActionList: ElementalAoeActions --> main, shortcd, cd

AddFunction ElementalAoeActions
{
	#earthquake,cycle_targets=1,if=!ticking&(buff.enhanced_chain_lightning.up|level<=90)&active_enemies>=2
	if not target.DebuffPresent(earthquake_debuff) and { BuffPresent(enhanced_chain_lightning_buff) or Level() <= 90 } and Enemies() >= 2 Spell(earthquake)
	#lava_beam
	if BuffPresent(ascendance_caster_buff) Spell(lava_beam)
	#earth_shock,if=buff.lightning_shield.react=buff.lightning_shield.max_stack
	if BuffStacks(lightning_shield_buff) == SpellData(lightning_shield_buff max_stacks) Spell(earth_shock)
	#thunderstorm,if=active_enemies>=10
	if Enemies() >= 10 Spell(thunderstorm)
	#searing_totem,if=(!talent.liquid_magma.enabled&!totem.fire.active)|(talent.liquid_magma.enabled&pet.searing_totem.remains<=20&!pet.fire_elemental_totem.active&!buff.liquid_magma.up)
	if not Talent(liquid_magma_talent) and not TotemPresent(fire) or Talent(liquid_magma_talent) and TotemRemaining(searing_totem) <= 20 and not TotemPresent(fire_elemental_totem) and not BuffPresent(liquid_magma_buff) Spell(searing_totem)
	#chain_lightning,if=active_enemies>=2
	if Enemies() >= 2 Spell(chain_lightning)
	#lightning_bolt
	Spell(lightning_bolt)
}

AddFunction ElementalAoeShortCdActions {}

AddFunction ElementalAoeCdActions {}

# ActionList: ElementalPrecombatActions --> main, shortcd, cd

AddFunction ElementalPrecombatActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=calamari_crepes
	#lightning_shield,if=!buff.lightning_shield.up
	if not BuffPresent(lightning_shield_buff) Spell(lightning_shield)
	#snapshot_stats
}

AddFunction ElementalPrecombatShortCdActions {}

AddFunction ElementalPrecombatCdActions
{
	unless not BuffPresent(lightning_shield_buff) and Spell(lightning_shield)
	{
		#potion,name=draenic_intellect
		UsePotionIntellect()
	}
}

# ActionList: ElementalSingleActions --> main, shortcd, cd

AddFunction ElementalSingleActions
{
	#unleash_flame,moving=1
	if Speed() > 0 Spell(unleash_flame)
	#earth_shock,if=buff.lightning_shield.react=buff.lightning_shield.max_stack
	if BuffStacks(lightning_shield_buff) == SpellData(lightning_shield_buff max_stacks) Spell(earth_shock)
	#lava_burst,if=dot.flame_shock.remains>cast_time&(buff.ascendance.up|cooldown_react)
	if target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and { BuffPresent(ascendance_caster_buff) or not SpellCooldown(lava_burst) > 0 } Spell(lava_burst)
	#unleash_flame,if=talent.unleashed_fury.enabled&!buff.ascendance.up
	if Talent(unleashed_fury_talent) and not BuffPresent(ascendance_caster_buff) Spell(unleash_flame)
	#flame_shock,if=dot.flame_shock.remains<=9
	if target.DebuffRemaining(flame_shock_debuff) <= 9 Spell(flame_shock)
	#earth_shock,if=(set_bonus.tier17_4pc&buff.lightning_shield.react>=15&!buff.lava_surge.up)|(!set_bonus.tier17_4pc&buff.lightning_shield.react>15)
	if ArmorSetBonus(T17 4) and BuffStacks(lightning_shield_buff) >= 15 and not BuffPresent(lava_surge_buff) or not ArmorSetBonus(T17 4) and BuffStacks(lightning_shield_buff) > 15 Spell(earth_shock)
	#elemental_blast
	Spell(elemental_blast)
	#flame_shock,if=time>60&remains<=buff.ascendance.duration&cooldown.ascendance.remains+buff.ascendance.duration<duration
	if TimeInCombat() > 60 and target.DebuffRemaining(flame_shock_debuff) <= BaseDuration(ascendance_caster_buff) and SpellCooldown(ascendance_caster) + BaseDuration(ascendance_caster_buff) < BaseDuration(flame_shock_debuff) Spell(flame_shock)
	#searing_totem,if=(!talent.liquid_magma.enabled&!totem.fire.active)|(talent.liquid_magma.enabled&pet.searing_totem.remains<=20&!pet.fire_elemental_totem.active&!buff.liquid_magma.up)
	if not Talent(liquid_magma_talent) and not TotemPresent(fire) or Talent(liquid_magma_talent) and TotemRemaining(searing_totem) <= 20 and not TotemPresent(fire_elemental_totem) and not BuffPresent(liquid_magma_buff) Spell(searing_totem)
	#lightning_bolt
	Spell(lightning_bolt)
}

AddFunction ElementalSingleShortCdActions
{
	unless Speed() > 0 and Spell(unleash_flame)
	{
		#spiritwalkers_grace,moving=1,if=buff.ascendance.up
		if Speed() > 0 and BuffPresent(ascendance_caster_buff) Spell(spiritwalkers_grace)

		unless BuffStacks(lightning_shield_buff) == SpellData(lightning_shield_buff max_stacks) and Spell(earth_shock)
			or target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and { BuffPresent(ascendance_caster_buff) or not SpellCooldown(lava_burst) > 0 } and Spell(lava_burst)
			or Talent(unleashed_fury_talent) and not BuffPresent(ascendance_caster_buff) and Spell(unleash_flame)
			or target.DebuffRemaining(flame_shock_debuff) <= 9 and Spell(flame_shock)
			or ArmorSetBonus(T17 4) and BuffStacks(lightning_shield_buff) >= 15 and not BuffPresent(lava_surge_buff) or not ArmorSetBonus(T17 4) and BuffStacks(lightning_shield_buff) > 15 and Spell(earth_shock)
		{
			#earthquake,if=!talent.unleashed_fury.enabled&((1+stat.spell_haste)*(1+(mastery_value*2%4.5))>=(1.875+(1.25*0.226305)+1.25*(2*0.226305*stat.multistrike_pct%100)))&target.time_to_die>10&buff.elemental_mastery.down&buff.bloodlust.down
			if not Talent(unleashed_fury_talent) and { 1 + 100 / { 100 + SpellHaste() } } * { 1 + MasteryEffect() / 100 * 2 / 4.5 } >= 1.875 + 1.25 * 0.226305 + 1.25 * 2 * 0.226305 * MultistrikeChance() / 100 and target.TimeToDie() > 10 and BuffExpires(elemental_mastery_buff) and BuffExpires(burst_haste_buff any=1) Spell(earthquake)
			#earthquake,if=!talent.unleashed_fury.enabled&((1+stat.spell_haste)*(1+(mastery_value*2%4.5))>=1.3*(1.875+(1.25*0.226305)+1.25*(2*0.226305*stat.multistrike_pct%100)))&target.time_to_die>10&(buff.elemental_mastery.up|buff.bloodlust.up)
			if not Talent(unleashed_fury_talent) and { 1 + 100 / { 100 + SpellHaste() } } * { 1 + MasteryEffect() / 100 * 2 / 4.5 } >= 1.3 * { 1.875 + 1.25 * 0.226305 + 1.25 * 2 * 0.226305 * MultistrikeChance() / 100 } and target.TimeToDie() > 10 and { BuffPresent(elemental_mastery_buff) or BuffPresent(burst_haste_buff any=1) } Spell(earthquake)
			#earthquake,if=!talent.unleashed_fury.enabled&((1+stat.spell_haste)*(1+(mastery_value*2%4.5))>=(1.875+(1.25*0.226305)+1.25*(2*0.226305*stat.multistrike_pct%100)))&target.time_to_die>10&(buff.elemental_mastery.remains>=10|buff.bloodlust.remains>=10)
			if not Talent(unleashed_fury_talent) and { 1 + 100 / { 100 + SpellHaste() } } * { 1 + MasteryEffect() / 100 * 2 / 4.5 } >= 1.875 + 1.25 * 0.226305 + 1.25 * 2 * 0.226305 * MultistrikeChance() / 100 and target.TimeToDie() > 10 and { BuffRemaining(elemental_mastery_buff) >= 10 or BuffRemaining(burst_haste_buff any=1) >= 10 } Spell(earthquake)
			#earthquake,if=talent.unleashed_fury.enabled&((1+stat.spell_haste)*(1+(mastery_value*2%4.5))>=((1.3*1.875)+(1.25*0.226305)+1.25*(2*0.226305*stat.multistrike_pct%100)))&target.time_to_die>10&buff.elemental_mastery.down&buff.bloodlust.down
			if Talent(unleashed_fury_talent) and { 1 + 100 / { 100 + SpellHaste() } } * { 1 + MasteryEffect() / 100 * 2 / 4.5 } >= 1.3 * 1.875 + 1.25 * 0.226305 + 1.25 * 2 * 0.226305 * MultistrikeChance() / 100 and target.TimeToDie() > 10 and BuffExpires(elemental_mastery_buff) and BuffExpires(burst_haste_buff any=1) Spell(earthquake)
			#earthquake,if=talent.unleashed_fury.enabled&((1+stat.spell_haste)*(1+(mastery_value*2%4.5))>=1.3*((1.3*1.875)+(1.25*0.226305)+1.25*(2*0.226305*stat.multistrike_pct%100)))&target.time_to_die>10&(buff.elemental_mastery.up|buff.bloodlust.up)
			if Talent(unleashed_fury_talent) and { 1 + 100 / { 100 + SpellHaste() } } * { 1 + MasteryEffect() / 100 * 2 / 4.5 } >= 1.3 * { 1.3 * 1.875 + 1.25 * 0.226305 + 1.25 * 2 * 0.226305 * MultistrikeChance() / 100 } and target.TimeToDie() > 10 and { BuffPresent(elemental_mastery_buff) or BuffPresent(burst_haste_buff any=1) } Spell(earthquake)
			#earthquake,if=talent.unleashed_fury.enabled&((1+stat.spell_haste)*(1+(mastery_value*2%4.5))>=((1.3*1.875)+(1.25*0.226305)+1.25*(2*0.226305*stat.multistrike_pct%100)))&target.time_to_die>10&(buff.elemental_mastery.remains>=10|buff.bloodlust.remains>=10)
			if Talent(unleashed_fury_talent) and { 1 + 100 / { 100 + SpellHaste() } } * { 1 + MasteryEffect() / 100 * 2 / 4.5 } >= 1.3 * 1.875 + 1.25 * 0.226305 + 1.25 * 2 * 0.226305 * MultistrikeChance() / 100 and target.TimeToDie() > 10 and { BuffRemaining(elemental_mastery_buff) >= 10 or BuffRemaining(burst_haste_buff any=1) >= 10 } Spell(earthquake)

			unless Spell(elemental_blast)
				or TimeInCombat() > 60 and target.DebuffRemaining(flame_shock_debuff) <= BaseDuration(ascendance_caster_buff) and SpellCooldown(ascendance_caster) + BaseDuration(ascendance_caster_buff) < BaseDuration(flame_shock_debuff) and Spell(flame_shock)
				or not Talent(liquid_magma_talent) and not TotemPresent(fire) or Talent(liquid_magma_talent) and TotemRemaining(searing_totem) <= 20 and not TotemPresent(fire_elemental_totem) and not BuffPresent(liquid_magma_buff) and Spell(searing_totem)
			{
				#spiritwalkers_grace,moving=1,if=((talent.elemental_blast.enabled&cooldown.elemental_blast.remains=0)|(cooldown.lava_burst.remains=0&!buff.lava_surge.react))
				if Speed() > 0 and { Talent(elemental_blast_talent) and not SpellCooldown(elemental_blast) > 0 or not SpellCooldown(lava_burst) > 0 and not BuffPresent(lava_surge_buff) } Spell(spiritwalkers_grace)
			}
		}
	}
}

AddFunction ElementalSingleCdActions {}

###
### Enhancement
###
# Based on SimulationCraft profile "Shaman_Enhancement_T17M".
#	class=shaman
#	spec=enhancement
#	talents=0001023
#	glyphs=chain_lightning/frost_shock

# ActionList: EnhancementDefaultActions --> main, shortcd, cd

AddFunction EnhancementDefaultActions
{
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 EnhancementSingleActions()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 EnhancementAoeActions()
}

AddFunction EnhancementDefaultShortCdActions
{
	#elemental_mastery
	Spell(elemental_mastery)
	#feral_spirit
	Spell(feral_spirit)
	#liquid_magma,if=pet.searing_totem.remains>=15|pet.magma_totem.remains>=15|pet.fire_elemental_totem.remains>=15
	if TotemRemaining(searing_totem) >= 15 or TotemRemaining(magma_totem) >= 15 or TotemRemaining(fire_elemental_totem) >= 15 Spell(liquid_magma)
}

AddFunction EnhancementDefaultCdActions
{
	#wind_shear
	InterruptActions()
	#bloodlust,if=target.health.pct<25|time>0.500
	if target.HealthPercent() < 25 or TimeInCombat() > 0.5 Bloodlust()
	#use_item,name=beating_heart_of_the_mountain
	UseItemActions()
	#potion,name=draenic_agility,if=(talent.storm_elemental_totem.enabled&pet.storm_elemental_totem.remains>=25)|(!talent.storm_elemental_totem.enabled&pet.fire_elemental_totem.remains>=25)|target.time_to_die<=30
	if Talent(storm_elemental_totem_talent) and TotemRemaining(storm_elemental_totem) >= 25 or not Talent(storm_elemental_totem_talent) and TotemRemaining(fire_elemental_totem) >= 25 or target.TimeToDie() <= 30 UsePotionAgility()
	#blood_fury
	Spell(blood_fury_apsp)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#berserking
	Spell(berserking)
	#storm_elemental_totem
	Spell(storm_elemental_totem)
	#fire_elemental_totem,if=(talent.primal_elementalist.enabled&active_enemies<=10)|active_enemies<=6
	if Talent(primal_elementalist_talent) and Enemies() <= 10 or Enemies() <= 6 Spell(fire_elemental_totem)
	#ascendance
	if BuffExpires(ascendance_melee_buff) Spell(ascendance_melee)

	unless Spell(feral_spirit)
		or { TotemRemaining(searing_totem) >= 15 or TotemRemaining(magma_totem) >= 15 or TotemRemaining(fire_elemental_totem) >= 15 } and Spell(liquid_magma)
	{
		#ancestral_swiftness
		Spell(ancestral_swiftness)
	}
}

# ActionList: EnhancementAoeActions --> main

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
		#lava_lash,if=dot.flame_shock.ticking&(active_dot.flame_shock<active_enemies|!talent.echo_of_the_elements.enabled|!buff.echo_of_the_elements.up)
		if target.DebuffPresent(flame_shock_debuff) and { DebuffCountOnAny(flame_shock_debuff) < Enemies() or not Talent(echo_of_the_elements_talent) or not BuffPresent(echo_of_the_elements_buff) } Spell(lava_lash)
		#elemental_blast,if=!buff.unleash_flame.up&(buff.maelstrom_weapon.react>=4|buff.ancestral_swiftness.up)
		if not BuffPresent(unleash_flame_buff) and { BuffStacks(maelstrom_weapon_buff) >= 4 or BuffPresent(ancestral_swiftness_buff) } Spell(elemental_blast)
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
		#elemental_blast,if=!buff.unleash_flame.up&buff.maelstrom_weapon.react>=1
		if not BuffPresent(unleash_flame_buff) and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(elemental_blast)
		#chain_lightning,if=glyph.chain_lightning.enabled&active_enemies>=4&buff.maelstrom_weapon.react>=1
		if Glyph(glyph_of_chain_lightning) and Enemies() >= 4 and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(chain_lightning)
		#fire_nova,if=active_dot.flame_shock>=2
		if DebuffCountOnAny(flame_shock_debuff) >= 2 Spell(fire_nova)
		#magma_totem,if=pet.magma_totem.remains<=20&!pet.fire_elemental_totem.active&!buff.liquid_magma.up
		if TotemRemaining(magma_totem) <= 20 and not TotemPresent(fire_elemental_totem) and not BuffPresent(liquid_magma_buff) and target.InRange(primal_strike) Spell(magma_totem)
		#stormstrike
		Spell(stormstrike)
		#frost_shock,if=active_enemies<4
		if Enemies() < 4 Spell(frost_shock)
		#elemental_blast,if=buff.maelstrom_weapon.react>=1
		if BuffStacks(maelstrom_weapon_buff) >= 1 Spell(elemental_blast)
		#chain_lightning,if=active_enemies>=3&buff.maelstrom_weapon.react>=1
		if Enemies() >= 3 and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(chain_lightning)
		#lightning_bolt,if=active_enemies<3&buff.maelstrom_weapon.react>=1
		if Enemies() < 3 and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(lightning_bolt)
		#fire_nova,if=active_dot.flame_shock>=1
		if DebuffCountOnAny(flame_shock_debuff) >= 1 Spell(fire_nova)
	}
}

# ActionList: EnhancementPrecombatActions --> main, shortcd, cd

AddFunction EnhancementPrecombatActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=frosty_stew
	#lightning_shield,if=!buff.lightning_shield.up
	if not BuffPresent(lightning_shield_buff) Spell(lightning_shield)
	#snapshot_stats
}

AddFunction EnhancementPrecombatShortCdActions {}

AddFunction EnhancementPrecombatCdActions
{
	unless not BuffPresent(lightning_shield_buff) and Spell(lightning_shield)
	{
		#potion,name=draenic_agility
		UsePotionAgility()
	}
}

# ActionList: EnhancementSingleActions --> main

AddFunction EnhancementSingleActions
{
	#searing_totem,if=!totem.fire.active
	if not TotemPresent(fire) Spell(searing_totem)
	#unleash_elements,if=(talent.unleashed_fury.enabled|set_bonus.tier16_2pc_melee=1)
	if Talent(unleashed_fury_talent) or ArmorSetBonus(T16_melee 2) == 1 Spell(unleash_elements)
	#elemental_blast,if=buff.maelstrom_weapon.react>=4|buff.ancestral_swiftness.up
	if BuffStacks(maelstrom_weapon_buff) >= 4 or BuffPresent(ancestral_swiftness_buff) Spell(elemental_blast)
	#windstrike
	if BuffPresent(ascendance_melee_buff) Spell(windstrike)
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

###
### Restoration
###

AddFunction RestorationMainActions
{
	if BuffExpires(water_shield_buff) Spell(water_shield)
	if BuffCountOnAny(earth_shield_buff) == 0 Spell(earth_shield)

	# If using Glyph of Totemic Recall, assume that the player wants to use Totemic Recall
	# to regain mana by recalling Healing Stream Totem.
	#
	# Totemic Recall is suggested at 3s remaining on HST so that there is still time to cast
	# it after the current spellcast and GCD.  Take care not to recall other totems that have
	# long cooldowns.
	#
	if Glyph(glyph_of_totemic_recall) and TotemPresent(water totem=healing_stream_totem) and TotemExpires(water 3) and TotemExpires(fire) and TotemExpires(earth) and TotemExpires(air) Spell(totemic_recall)

	if Talent(elemental_blast_talent) and BuffRemaining(elemental_blast_spirit_buff) < CastTime(elemental_blast) Spell(elemental_blast)
	if BuffPresent(unleash_life_buff) Spell(healing_wave)
	if Talent(totemic_persistence_talent) or TotemExpires(water) Spell(healing_stream_totem)
	if Glyph(glyph_of_riptide no) Spell(riptide)
}

AddFunction RestorationAoeActions
{
	if BuffExpires(water_shield_buff) Spell(water_shield)
	if BuffCountOnAny(earth_shield_buff) == 0 Spell(earth_shield)

	if Talent(elemental_blast_talent) and BuffRemaining(elemental_blast_spirit_buff) < CastTime(elemental_blast) Spell(elemental_blast)
	if BuffPresent(unleash_life_buff) Spell(chain_heal)
	if Talent(totemic_persistence_talent) or TotemExpires(water) Spell(healing_stream_totem)
	if Talent(totemic_persistence_talent) or TotemExpires(water) Spell(cloudburst_totem)
	Spell(healing_rain)
	Spell(chain_heal)
}

AddFunction RestorationShortCdActions
{
	if Talent(primal_elementalist_talent) and pet.Present()
	{
		if TotemPresent(fire_elemental_totem) and BuffExpires(pet_empower any=1) Spell(pet_empower)
		if TotemPresent(earth totem=earth_elemental_totem) and BuffExpires(pet_reinforce any=1) Spell(pet_reinforce)
	}
	Spell(unleash_life)
}

AddFunction RestorationCdActions
{
	if IsFeared() Spell(tremor_totem)
	InterruptActions()
	if Speed(more 0) Spell(spiritwalkers_grace)
	Spell(blood_fury_apsp)
	Spell(berserking)
	if ManaPercent() < 90 Spell(arcane_torrent_mana)
	if Talent(totemic_persistence_talent) or TotemExpires(water) Spell(healing_tide_totem)
	Spell(ancestral_guidance)
	Spell(ascendance_heal)
	Spell(fire_elemental_totem)
	Spell(earth_elemental_totem)
}
]]
	OvaleScripts:RegisterScript("SHAMAN", name, desc, code, "include")
end

do
	local name = "Ovale"	-- The default script.
	local desc = "[6.0] Ovale: Elemental, Enhancement, Restoration"
	local code = [[
# Ovale shaman script based on SimulationCraft.

# Shaman rotation functions.
Include(ovale_shaman)

### Elemental icons.
AddCheckBox(opt_shaman_elemental_aoe L(AOE) specialization=elemental default)

AddIcon specialization=elemental help=shortcd enemies=1 checkbox=!opt_shaman_elemental_aoe
{
	if InCombat(no) ElementalPrecombatShortCdActions()
	ElementalDefaultShortCdActions()
}

AddIcon specialization=elemental help=shortcd checkbox=opt_shaman_elemental_aoe
{
	if InCombat(no) ElementalPrecombatShortCdActions()
	ElementalDefaultShortCdActions()
}

AddIcon specialization=elemental help=main enemies=1
{
	if InCombat(no) ElementalPrecombatActions()
	ElementalDefaultActions()
}

AddIcon specialization=elemental help=aoe checkbox=opt_shaman_elemental_aoe
{
	if InCombat(no) ElementalPrecombatActions()
	ElementalDefaultActions()
}

AddIcon specialization=elemental help=cd enemies=1 checkbox=!opt_shaman_elemental_aoe
{
	if InCombat(no) ElementalPrecombatCdActions()
	ElementalDefaultCdActions()
}

AddIcon specialization=elemental help=cd checkbox=opt_shaman_elemental_aoe
{
	if InCombat(no) ElementalPrecombatCdActions()
	ElementalDefaultCdActions()
}

### Enhancement icons.
AddCheckBox(opt_shaman_enhancement_aoe L(AOE) specialization=enhancement default)

AddIcon specialization=enhancement help=shortcd enemies=1 checkbox=!opt_shaman_enhancement_aoe
{
	if InCombat(no) EnhancementPrecombatShortCdActions()
	EnhancementDefaultShortCdActions()
}

AddIcon specialization=enhancement help=shortcd checkbox=opt_shaman_enhancement_aoe
{
	if InCombat(no) EnhancementPrecombatShortCdActions()
	EnhancementDefaultShortCdActions()
}

AddIcon specialization=enhancement help=main enemies=1
{
	if InCombat(no) EnhancementPrecombatActions()
	EnhancementDefaultActions()
}

AddIcon specialization=enhancement help=aoe checkbox=opt_shaman_enhancement_aoe
{
	if InCombat(no) EnhancementPrecombatActions()
	EnhancementDefaultActions()
}

AddIcon specialization=enhancement help=cd enemies=1 checkbox=!opt_shaman_enhancement_aoe
{
	if InCombat(no) EnhancementPrecombatCdActions()
	EnhancementDefaultCdActions()
}

AddIcon specialization=enhancement help=cd checkbox=opt_shaman_enhancement_aoe
{
	if InCombat(no) EnhancementPrecombatCdActions()
	EnhancementDefaultCdActions()
}

### Restoration icons.
AddCheckBox(opt_shaman_restoration_aoe L(AOE) specialization=restoration default)

AddIcon specialization=restoration help=shortcd
{
	RestorationShortCdActions()
}

AddIcon specialization=restoration help=main
{
	RestorationMainActions()
}

AddIcon specialization=restoration help=aoe checkbox=opt_shaman_restoration_aoe
{
	RestorationAoeActions()
}

AddIcon specialization=restoration help=cd
{
	RestorationCdActions()
}
]]
	OvaleScripts:RegisterScript("SHAMAN", name, desc, code, "script")
end
