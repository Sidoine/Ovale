local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_shaman"
	local desc = "[6.0] Ovale: Rotations (Elemental, Enhancement, Restoration)"
	local code = [[
# Shaman rotation functions based on SimulationCraft.

###
### Elemental
###
# Based on SimulationCraft profile "Shaman_Elemental_T17M".
#	class=shaman
#	spec=elemental
#	talents=0001011
#	glyphs=chain_lightning

AddCheckBox(opt_interrupt L(interrupt) default specialization=elemental)
AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=elemental)
AddCheckBox(opt_bloodlust SpellName(bloodlust) specialization=elemental)

AddFunction ElementalUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction ElementalBloodlust
{
	if CheckBoxOn(opt_bloodlust) and DebuffExpires(burst_haste_debuff any=1)
	{
		Spell(bloodlust)
		Spell(heroism)
	}
}

AddFunction ElementalInterruptActions
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

AddFunction ElementalDefaultMainActions
{
	#call_action_list,name=single,if=active_enemies<3
	if Enemies() < 3 ElementalSingleMainActions()
	#call_action_list,name=aoe,if=active_enemies>2
	if Enemies() > 2 ElementalAoeMainActions()
}

AddFunction ElementalDefaultShortCdActions
{
	#elemental_mastery,if=action.lava_burst.cast_time>=1.2
	if CastTime(lava_burst) >= 1.2 Spell(elemental_mastery)
	#ancestral_swiftness,if=!buff.ascendance.up
	if not BuffPresent(ascendance_caster_buff) Spell(ancestral_swiftness)
	#liquid_magma,if=pet.searing_totem.remains>=15|pet.fire_elemental_totem.remains>=15
	if TotemRemaining(searing_totem) >= 15 or TotemRemaining(fire_elemental_totem) >= 15 Spell(liquid_magma)
	#call_action_list,name=single,if=active_enemies<3
	if Enemies() < 3 ElementalSingleShortCdActions()

	unless Enemies() < 3 and ElementalSingleShortCdPostConditions()
	{
		#call_action_list,name=aoe,if=active_enemies>2
		if Enemies() > 2 ElementalAoeShortCdActions()
	}
}

AddFunction ElementalDefaultCdActions
{
	#wind_shear
	ElementalInterruptActions()
	#bloodlust,if=target.health.pct<25|time>0.500
	if target.HealthPercent() < 25 or TimeInCombat() > 0.5 ElementalBloodlust()
	#potion,name=draenic_intellect,if=buff.ascendance.up|target.time_to_die<=30
	if BuffPresent(ascendance_caster_buff) or target.TimeToDie() <= 30 ElementalUsePotionIntellect()
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

	unless { TotemRemaining(searing_totem) >= 15 or TotemRemaining(fire_elemental_totem) >= 15 } and Spell(liquid_magma)
	{
		#call_action_list,name=single,if=active_enemies<3
		if Enemies() < 3 ElementalSingleCdActions()
	}
}

### actions.aoe

AddFunction ElementalAoeMainActions
{
	#lava_beam
	Spell(lava_beam)
	#earth_shock,if=buff.lightning_shield.react=buff.lightning_shield.max_stack
	if BuffStacks(lightning_shield_buff) == SpellData(lightning_shield_buff max_stacks) Spell(earth_shock)
	#searing_totem,if=(!talent.liquid_magma.enabled&!totem.fire.active)|(talent.liquid_magma.enabled&pet.searing_totem.remains<=20&!pet.fire_elemental_totem.active&!buff.liquid_magma.up)
	if not Talent(liquid_magma_talent) and not TotemPresent(fire) or Talent(liquid_magma_talent) and TotemRemaining(searing_totem) <= 20 and not TotemPresent(fire_elemental_totem) and not BuffPresent(liquid_magma_buff) Spell(searing_totem)
	#chain_lightning,if=active_enemies>=2
	if Enemies() >= 2 Spell(chain_lightning)
	#lightning_bolt
	Spell(lightning_bolt)
}

AddFunction ElementalAoeShortCdActions
{
	#earthquake,cycle_targets=1,if=!ticking&(buff.enhanced_chain_lightning.up|level<=90)&active_enemies>=2
	if not target.DebuffPresent(earthquake_debuff) and { BuffPresent(enhanced_chain_lightning_buff) or Level() <= 90 } and Enemies() >= 2 Spell(earthquake)

	unless Spell(lava_beam) or BuffStacks(lightning_shield_buff) == SpellData(lightning_shield_buff max_stacks) and Spell(earth_shock)
	{
		#thunderstorm,if=active_enemies>=10
		if Enemies() >= 10 Spell(thunderstorm)
	}
}

### actions.precombat

AddFunction ElementalPrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=calamari_crepes
	#lightning_shield,if=!buff.lightning_shield.up
	if not BuffPresent(lightning_shield_buff) Spell(lightning_shield)
}

AddFunction ElementalPrecombatShortCdPostConditions
{
	not BuffPresent(lightning_shield_buff) and Spell(lightning_shield)
}

AddFunction ElementalPrecombatCdActions
{
	unless not BuffPresent(lightning_shield_buff) and Spell(lightning_shield)
	{
		#snapshot_stats
		#potion,name=draenic_intellect
		ElementalUsePotionIntellect()
	}
}

AddFunction ElementalPrecombatCdPostConditions
{
	not BuffPresent(lightning_shield_buff) and Spell(lightning_shield)
}

### actions.single

AddFunction ElementalSingleMainActions
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
	#earth_shock,if=(set_bonus.tier17_4pc&buff.lightning_shield.react>=15+ptr*3&!buff.lava_surge.up)|(!set_bonus.tier17_4pc&buff.lightning_shield.react>15)
	if ArmorSetBonus(T17 4) and BuffStacks(lightning_shield_buff) >= 15 + PTR() * 3 and not BuffPresent(lava_surge_buff) or not ArmorSetBonus(T17 4) and BuffStacks(lightning_shield_buff) > 15 Spell(earth_shock)
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
	unless Speed() > 0 and Spell(unleash_flame) or BuffStacks(lightning_shield_buff) == SpellData(lightning_shield_buff max_stacks) and Spell(earth_shock) or target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and { BuffPresent(ascendance_caster_buff) or not SpellCooldown(lava_burst) > 0 } and Spell(lava_burst) or Talent(unleashed_fury_talent) and not BuffPresent(ascendance_caster_buff) and Spell(unleash_flame) or target.DebuffRemaining(flame_shock_debuff) <= 9 and Spell(flame_shock) or { ArmorSetBonus(T17 4) and BuffStacks(lightning_shield_buff) >= 15 + PTR() * 3 and not BuffPresent(lava_surge_buff) or not ArmorSetBonus(T17 4) and BuffStacks(lightning_shield_buff) > 15 } and Spell(earth_shock)
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
	}
}

AddFunction ElementalSingleShortCdPostConditions
{
	Speed() > 0 and Spell(unleash_flame) or BuffStacks(lightning_shield_buff) == SpellData(lightning_shield_buff max_stacks) and Spell(earth_shock) or target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and { BuffPresent(ascendance_caster_buff) or not SpellCooldown(lava_burst) > 0 } and Spell(lava_burst) or Talent(unleashed_fury_talent) and not BuffPresent(ascendance_caster_buff) and Spell(unleash_flame) or target.DebuffRemaining(flame_shock_debuff) <= 9 and Spell(flame_shock) or { ArmorSetBonus(T17 4) and BuffStacks(lightning_shield_buff) >= 15 + PTR() * 3 and not BuffPresent(lava_surge_buff) or not ArmorSetBonus(T17 4) and BuffStacks(lightning_shield_buff) > 15 } and Spell(earth_shock) or Spell(elemental_blast) or TimeInCombat() > 60 and target.DebuffRemaining(flame_shock_debuff) <= BaseDuration(ascendance_caster_buff) and SpellCooldown(ascendance_caster) + BaseDuration(ascendance_caster_buff) < BaseDuration(flame_shock_debuff) and Spell(flame_shock) or { not Talent(liquid_magma_talent) and not TotemPresent(fire) or Talent(liquid_magma_talent) and TotemRemaining(searing_totem) <= 20 and not TotemPresent(fire_elemental_totem) and not BuffPresent(liquid_magma_buff) } and Spell(searing_totem) or Spell(lightning_bolt)
}

AddFunction ElementalSingleCdActions
{
	unless Speed() > 0 and Spell(unleash_flame)
	{
		#spiritwalkers_grace,moving=1,if=buff.ascendance.up
		if Speed() > 0 and BuffPresent(ascendance_caster_buff) Spell(spiritwalkers_grace)

		unless BuffStacks(lightning_shield_buff) == SpellData(lightning_shield_buff max_stacks) and Spell(earth_shock) or target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and { BuffPresent(ascendance_caster_buff) or not SpellCooldown(lava_burst) > 0 } and Spell(lava_burst) or Talent(unleashed_fury_talent) and not BuffPresent(ascendance_caster_buff) and Spell(unleash_flame) or target.DebuffRemaining(flame_shock_debuff) <= 9 and Spell(flame_shock) or { ArmorSetBonus(T17 4) and BuffStacks(lightning_shield_buff) >= 15 + PTR() * 3 and not BuffPresent(lava_surge_buff) or not ArmorSetBonus(T17 4) and BuffStacks(lightning_shield_buff) > 15 } and Spell(earth_shock) or not Talent(unleashed_fury_talent) and { 1 + 100 / { 100 + SpellHaste() } } * { 1 + MasteryEffect() / 100 * 2 / 4.5 } >= 1.875 + 1.25 * 0.226305 + 1.25 * 2 * 0.226305 * MultistrikeChance() / 100 and target.TimeToDie() > 10 and BuffExpires(elemental_mastery_buff) and BuffExpires(burst_haste_buff any=1) and Spell(earthquake) or not Talent(unleashed_fury_talent) and { 1 + 100 / { 100 + SpellHaste() } } * { 1 + MasteryEffect() / 100 * 2 / 4.5 } >= 1.3 * { 1.875 + 1.25 * 0.226305 + 1.25 * 2 * 0.226305 * MultistrikeChance() / 100 } and target.TimeToDie() > 10 and { BuffPresent(elemental_mastery_buff) or BuffPresent(burst_haste_buff any=1) } and Spell(earthquake) or not Talent(unleashed_fury_talent) and { 1 + 100 / { 100 + SpellHaste() } } * { 1 + MasteryEffect() / 100 * 2 / 4.5 } >= 1.875 + 1.25 * 0.226305 + 1.25 * 2 * 0.226305 * MultistrikeChance() / 100 and target.TimeToDie() > 10 and { BuffRemaining(elemental_mastery_buff) >= 10 or BuffRemaining(burst_haste_buff any=1) >= 10 } and Spell(earthquake) or Talent(unleashed_fury_talent) and { 1 + 100 / { 100 + SpellHaste() } } * { 1 + MasteryEffect() / 100 * 2 / 4.5 } >= 1.3 * 1.875 + 1.25 * 0.226305 + 1.25 * 2 * 0.226305 * MultistrikeChance() / 100 and target.TimeToDie() > 10 and BuffExpires(elemental_mastery_buff) and BuffExpires(burst_haste_buff any=1) and Spell(earthquake) or Talent(unleashed_fury_talent) and { 1 + 100 / { 100 + SpellHaste() } } * { 1 + MasteryEffect() / 100 * 2 / 4.5 } >= 1.3 * { 1.3 * 1.875 + 1.25 * 0.226305 + 1.25 * 2 * 0.226305 * MultistrikeChance() / 100 } and target.TimeToDie() > 10 and { BuffPresent(elemental_mastery_buff) or BuffPresent(burst_haste_buff any=1) } and Spell(earthquake) or Talent(unleashed_fury_talent) and { 1 + 100 / { 100 + SpellHaste() } } * { 1 + MasteryEffect() / 100 * 2 / 4.5 } >= 1.3 * 1.875 + 1.25 * 0.226305 + 1.25 * 2 * 0.226305 * MultistrikeChance() / 100 and target.TimeToDie() > 10 and { BuffRemaining(elemental_mastery_buff) >= 10 or BuffRemaining(burst_haste_buff any=1) >= 10 } and Spell(earthquake) or Spell(elemental_blast) or TimeInCombat() > 60 and target.DebuffRemaining(flame_shock_debuff) <= BaseDuration(ascendance_caster_buff) and SpellCooldown(ascendance_caster) + BaseDuration(ascendance_caster_buff) < BaseDuration(flame_shock_debuff) and Spell(flame_shock) or { not Talent(liquid_magma_talent) and not TotemPresent(fire) or Talent(liquid_magma_talent) and TotemRemaining(searing_totem) <= 20 and not TotemPresent(fire_elemental_totem) and not BuffPresent(liquid_magma_buff) } and Spell(searing_totem)
		{
			#spiritwalkers_grace,moving=1,if=((talent.elemental_blast.enabled&cooldown.elemental_blast.remains=0)|(cooldown.lava_burst.remains=0&!buff.lava_surge.react))
			if Speed() > 0 and { Talent(elemental_blast_talent) and not SpellCooldown(elemental_blast) > 0 or not SpellCooldown(lava_burst) > 0 and not BuffPresent(lava_surge_buff) } Spell(spiritwalkers_grace)
		}
	}
}

###
### Enhancement
###
# Based on SimulationCraft profile "Shaman_Enhancement_T17M".
#	class=shaman
#	spec=enhancement
#	talents=0001023
#	glyphs=chain_lightning/frost_shock

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
	#potion,name=draenic_agility,if=(talent.storm_elemental_totem.enabled&pet.storm_elemental_totem.remains>=25)|(!talent.storm_elemental_totem.enabled&pet.fire_elemental_totem.remains>=25)|target.time_to_die<=30
	if Talent(storm_elemental_totem_talent) and TotemRemaining(storm_elemental_totem) >= 25 or not Talent(storm_elemental_totem_talent) and TotemRemaining(fire_elemental_totem) >= 25 or target.TimeToDie() <= 30 EnhancementUsePotionAgility()
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
	#feral_spirit
	Spell(feral_spirit)
}

### actions.aoe

AddFunction EnhancementAoeMainActions
{
	#unleash_elements,if=active_enemies>=4&dot.flame_shock.ticking&(cooldown.shock.remains>cooldown.fire_nova.remains|cooldown.fire_nova.remains=0)
	if Enemies() >= 4 and target.DebuffPresent(flame_shock_debuff) and { SpellCooldown(shock) > SpellCooldown(fire_nova) or not SpellCooldown(fire_nova) > 0 } Spell(unleash_elements)
	#fire_nova,if=active_dot.flame_shock>=3
	if DebuffCountOnAny(flame_shock_debuff) >= 3 Spell(fire_nova)
	#wait,sec=cooldown.fire_nova.remains,if=active_dot.flame_shock>=4&cooldown.fire_nova.remains<=action.fire_nova.gcd%2
	unless DebuffCountOnAny(flame_shock_debuff) >= 4 and SpellCooldown(fire_nova) <= GCD() / 2 and SpellCooldown(fire_nova) > 0
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
		Spell(windstrike)
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

### actions.precombat

AddFunction EnhancementPrecombatMainActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=frosty_stew
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

###
### Restoration
###

AddFunction RestorationInterruptActions
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
	Spell(healing_rain)
	if Talent(totemic_persistence_talent) or TotemExpires(water) Spell(cloudburst_totem)
	Spell(chain_heal)
}

AddFunction RestorationShortCdActions
{
	if Talent(primal_elementalist_talent) and pet.Present()
	{
		if TotemPresent(fire_elemental_totem) and BuffExpires(fire_elemental_totem_empower_buff any=1) Spell(fire_elemental_totem_empower)
		if TotemPresent(earth totem=earth_elemental_totem) and BuffExpires(earth_elemental_totem_reinforce_buff any=1) Spell(earth_elemental_totem_reinforce)
	}
	Spell(unleash_life)
}

AddFunction RestorationCdActions
{
	if IsFeared() Spell(tremor_totem)
	RestorationInterruptActions()
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

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_shaman_spells)
Include(ovale_shaman)

### Elemental icons.

AddCheckBox(opt_shaman_elemental_aoe L(AOE) default specialization=elemental)

AddIcon checkbox=!opt_shaman_elemental_aoe enemies=1 help=shortcd specialization=elemental
{
	unless not InCombat() and ElementalPrecombatShortCdPostConditions()
	{
		ElementalDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_shaman_elemental_aoe help=shortcd specialization=elemental
{
	unless not InCombat() and ElementalPrecombatShortCdPostConditions()
	{
		ElementalDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=elemental
{
	if not InCombat() ElementalPrecombatMainActions()
	ElementalDefaultMainActions()
}

AddIcon checkbox=opt_shaman_elemental_aoe help=aoe specialization=elemental
{
	if not InCombat() ElementalPrecombatMainActions()
	ElementalDefaultMainActions()
}

AddIcon checkbox=!opt_shaman_elemental_aoe enemies=1 help=cd specialization=elemental
{
	if not InCombat() ElementalPrecombatCdActions()
	unless not InCombat() and ElementalPrecombatCdPostConditions()
	{
		ElementalDefaultCdActions()
	}
}

AddIcon checkbox=opt_shaman_elemental_aoe help=cd specialization=elemental
{
	if not InCombat() ElementalPrecombatCdActions()
	unless not InCombat() and ElementalPrecombatCdPostConditions()
	{
		ElementalDefaultCdActions()
	}
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

### Restoration icons.

AddCheckBox(opt_shaman_restoration_aoe L(AOE) default specialization=restoration)

AddIcon help=shortcd specialization=restoration
{
	RestorationShortCdActions()
}

AddIcon help=main specialization=restoration
{
	RestorationMainActions()
}

AddIcon checkbox=opt_shaman_restoration_aoe help=aoe specialization=restoration
{
	RestorationAoeActions()
}

AddIcon help=cd specialization=restoration
{
	RestorationCdActions()
}
]]
	OvaleScripts:RegisterScript("SHAMAN", name, desc, code, "script")
end
