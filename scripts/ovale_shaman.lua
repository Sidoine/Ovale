local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_shaman"
	local desc = "[5.4.8] Ovale: Elemental, Enhancement, Restoration"
	local code = [[
# Ovale shaman script based on SimulationCraft.

Include(ovale_common)
Include(ovale_shaman_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default specialization=enhancement)
AddCheckBox(opt_potion_intellect ItemName(jade_serpent_potion) default specialization=elemental)
AddCheckBox(opt_bloodlust SpellName(bloodlust) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(jade_serpent_potion usable=1)
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
	if target.IsFriend(no) and target.IsInterruptible()
	{
		Spell(wind_shear)
		if target.Classification(worldboss no)
		{
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

###
### Elemental
###
# Based on SimulationCraft profile "Shaman_Elemental_T16H".
#	class=shaman
#	spec=elemental
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Wa!...2.0
#	glyphs=chain_lightning

# ActionList: ElementalPrecombatActions --> main, predict, shortcd, cd

AddFunction ElementalPrecombatActions
{
	ElementalPrecombatPredictActions()
}

AddFunction ElementalPrecombatPredictActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#flametongue_weapon,weapon=main
	if WeaponEnchantExpires(main) Spell(flametongue_weapon)
	#lightning_shield,if=!buff.lightning_shield.up
	if not BuffPresent(lightning_shield_buff) Spell(lightning_shield)
	#snapshot_stats
}

AddFunction ElementalPrecombatShortCdActions {}

AddFunction ElementalPrecombatCdActions
{
	unless WeaponEnchantExpires(main) and Spell(flametongue_weapon)
		or not BuffPresent(lightning_shield_buff) and Spell(lightning_shield)
	{
		#jade_serpent_potion
		UsePotionIntellect()
	}
}

# ActionList: ElementalDefaultActions --> main, predict, shortcd, cd

AddFunction ElementalDefaultActions
{
	#run_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ElementalSingleActions()
	#run_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 ElementalAoeActions()
}

AddFunction ElementalDefaultPredictActions
{
	#run_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ElementalSinglePredictActions()
	#run_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 ElementalAoePredictActions()
}

AddFunction ElementalDefaultShortCdActions
{
	#elemental_mastery,if=talent.elemental_mastery.enabled&(time>15&((!buff.bloodlust.up&time<120)|(!buff.berserking.up&!buff.bloodlust.up&buff.ascendance.up)|(time>=200&(cooldown.ascendance.remains>30|level<87))))
	if Talent(elemental_mastery_talent) and TimeInCombat() > 15 and { not BuffPresent(burst_haste_buff any=1) and TimeInCombat() < 120 or not BuffPresent(berserking_buff) and not BuffPresent(burst_haste_buff any=1) and BuffPresent(ascendance_caster_buff) or TimeInCombat() >= 200 and { SpellCooldown(ascendance_caster) > 30 or Level() < 87 } } Spell(elemental_mastery)
	#ancestral_swiftness,if=talent.ancestral_swiftness.enabled&!buff.ascendance.up
	if Talent(ancestral_swiftness_talent) and not BuffPresent(ascendance_caster_buff) Spell(ancestral_swiftness)
	#run_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ElementalSingleShortCdActions()
	#run_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 ElementalAoeShortCdActions()
}

AddFunction ElementalDefaultCdActions
{
	# CHANGE: Suggest breaking fear effects with Tremor Totem.
	if IsFeared() Spell(tremor_totem)

	#wind_shear
	InterruptActions()
	#bloodlust,if=target.health.pct<25|time>0.500
	if target.HealthPercent() < 25 or TimeInCombat() > 0.5 Bloodlust()
	#stormlash_totem,if=!active&!buff.stormlash.up&(buff.bloodlust.up|time>=60)
	if not TotemPresent(air totem=stormlash_totem) and not BuffPresent(stormlash_buff any=1) and { BuffPresent(burst_haste_buff any=1) or TimeInCombat() >= 60 } Spell(stormlash_totem)
	#jade_serpent_potion,if=time>60&(pet.primal_fire_elemental.active|pet.greater_fire_elemental.active|target.time_to_die<=60)
	if TimeInCombat() > 60 and { TotemPresent(fire totem=fire_elemental_totem) or TotemPresent(fire totem=fire_elemental_totem) or target.TimeToDie() <= 60 } UsePotionIntellect()
	#berserking,if=!buff.bloodlust.up&!buff.elemental_mastery.up&(set_bonus.tier15_4pc_caster=1|(buff.ascendance.cooldown_remains=0&(dot.flame_shock.remains>buff.ascendance.duration|level<87)))
	if not BuffPresent(burst_haste_buff any=1) and not BuffPresent(elemental_mastery_buff) and { ArmorSetBonus(T15_caster 4) == 1 or not SpellCooldown(ascendance_caster) > 0 and { target.DebuffRemaining(flame_shock_debuff) > SpellData(ascendance_caster_buff duration) or Level() < 87 } } Spell(berserking)
	#blood_fury,if=buff.bloodlust.up|buff.ascendance.up|((cooldown.ascendance.remains>10|level<87)&cooldown.fire_elemental_totem.remains>10)
	if BuffPresent(burst_haste_buff any=1) or BuffPresent(ascendance_caster_buff) or { SpellCooldown(ascendance_caster) > 10 or Level() < 87 } and SpellCooldown(fire_elemental_totem) > 10 Spell(blood_fury_apsp)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#fire_elemental_totem,if=!active
	if not TotemPresent(fire totem=fire_elemental_totem) Spell(fire_elemental_totem)
	#ascendance,if=active_enemies>1|(dot.flame_shock.remains>buff.ascendance.duration&(target.time_to_die<20|buff.bloodlust.up|time>=60)&cooldown.lava_burst.remains>0)
	# CHANGE: Don't delay casting Ascendance for one minute.
	#if Enemies() > 1 or target.DebuffRemaining(flame_shock_debuff) > SpellData(ascendance_caster_buff duration) and { target.TimeToDie() < 20 or BuffPresent(burst_haste_buff any=1) or TimeInCombat() >= 60 } and SpellCooldown(lava_burst) > 0 Spell(ascendance_caster)
	if Enemies() > 1 or target.DebuffRemaining(flame_shock_debuff) > SpellData(ascendance_caster_buff duration) and SpellCooldown(lava_burst) > 0 Spell(ascendance_caster)
	#run_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ElementalSingleCdActions()
	#run_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 ElementalAoeCdActions()
}

# ActionList: ElementalAoeActions --> main, predict, shortcd, cd

AddFunction ElementalAoeActions
{
	#lava_beam
	if BuffPresent(ascendance_caster_buff) Spell(lava_beam)
	#searing_totem,if=active_enemies<=2&!totem.fire.active
	if Enemies() <= 2 and not TotemPresent(fire) Spell(searing_totem)
	#lava_burst,if=active_enemies<3&dot.flame_shock.remains>cast_time&cooldown_react
	if Enemies() < 3 and target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and not SpellCooldown(lava_burst) > 0 Spell(lava_burst)
	#flame_shock,cycle_targets=1,if=!ticking&active_enemies<3
	if not target.DebuffPresent(flame_shock_debuff) and Enemies() < 3 Spell(flame_shock)
	#chain_lightning,if=mana.pct_nonproc>10
	if ManaPercent() > 10 Spell(chain_lightning)
	#lightning_bolt
	Spell(lightning_bolt)
}

AddFunction ElementalAoePredictActions
{
	unless BuffPresent(ascendance_caster_buff) and Spell(lava_beam)
	{
		#searing_totem,if=active_enemies<=2&!totem.fire.active
		if Enemies() <= 2 and not TotemPresent(fire) Spell(searing_totem)
		#lava_burst,if=active_enemies<3&dot.flame_shock.remains>cast_time&cooldown_react
		if Enemies() < 3 and target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and not SpellCooldown(lava_burst) > 0 Spell(lava_burst)
		#flame_shock,cycle_targets=1,if=!ticking&active_enemies<3
		if not target.DebuffPresent(flame_shock_debuff) and Enemies() < 3 Spell(flame_shock)
	}
}

AddFunction ElementalAoeShortCdActions
{
	unless BuffPresent(ascendance_caster_buff) and Spell(lava_beam)
	{
		#magma_totem,if=active_enemies>2&!totem.fire.active
		if Enemies() > 2 and not TotemPresent(fire) and target.InRange(primal_strike) Spell(magma_totem)

		unless Enemies() <= 2 and not TotemPresent(fire) and Spell(searing_totem)
			or Enemies() < 3 and target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and not SpellCooldown(lava_burst) > 0 and Spell(lava_burst)
			or not target.DebuffPresent(flame_shock_debuff) and Enemies() < 3 and Spell(flame_shock)
		{
			#earthquake,if=active_enemies>4
			if Enemies() > 4 Spell(earthquake)
			#thunderstorm,if=mana.pct_nonproc<80
			if ManaPercent() < 80 Spell(thunderstorm)
		}
	}
}

AddFunction ElementalAoeCdActions {}

# ActionList: ElementalSingleActions --> main, predict, shortcd, cd

AddFunction ElementalSingleActions
{
	ElementalSinglePredictActions()

	#lightning_bolt
	Spell(lightning_bolt)
}

AddFunction ElementalSinglePredictActions
{
	#unleash_elements,if=talent.unleashed_fury.enabled&!buff.ascendance.up
	if Talent(unleashed_fury_talent) and not BuffPresent(ascendance_caster_buff) Spell(unleash_elements)
	#lava_burst,if=dot.flame_shock.remains>cast_time&(buff.ascendance.up|cooldown_react)
	if target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and { BuffPresent(ascendance_caster_buff) or not SpellCooldown(lava_burst) > 0 } Spell(lava_burst)
	#flame_shock,if=ticks_remain<2
	if target.TicksRemaining(flame_shock_debuff) < 2 Spell(flame_shock)
	#elemental_blast,if=talent.elemental_blast.enabled
	if Talent(elemental_blast_talent) Spell(elemental_blast)
	#earth_shock,if=buff.lightning_shield.react=buff.lightning_shield.max_stack
	if BuffStacks(lightning_shield_buff) == 7 Spell(earth_shock)
	#earth_shock,if=buff.lightning_shield.react>3&dot.flame_shock.remains>cooldown&dot.flame_shock.remains<cooldown+action.flame_shock.tick_time
	if BuffStacks(lightning_shield_buff) > 3 and target.DebuffRemaining(flame_shock_debuff) > SpellCooldown(earth_shock) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(earth_shock) + target.TickTime(flame_shock_debuff) Spell(earth_shock)
	#flame_shock,if=time>60&remains<=buff.ascendance.duration&cooldown.ascendance.remains+buff.ascendance.duration<duration
	if TimeInCombat() > 60 and target.DebuffRemaining(flame_shock_debuff) <= SpellData(ascendance_caster_buff duration) and SpellCooldown(ascendance_caster) + SpellData(ascendance_caster_buff duration) < SpellData(flame_shock_debuff duration) Spell(flame_shock)
	#searing_totem,if=cooldown.fire_elemental_totem.remains>20&!totem.fire.active
	# CHANGE: Ignore the cooldown of Fire Elemental Totem so the player can avoid dropping FE
	#         totem in order to line up with a burn phase.
	#if SpellCooldown(fire_elemental_totem) > 20 and not TotemPresent(fire) Spell(searing_totem)
	if not TotemPresent(fire) Spell(searing_totem)
}

AddFunction ElementalSingleShortCdActions {}

AddFunction ElementalSingleCdActions
{
	#use_item,name=grips_of_tidal_force,if=((cooldown.ascendance.remains>10|level<87)&cooldown.fire_elemental_totem.remains>10)|buff.ascendance.up|buff.bloodlust.up|totem.fire_elemental_totem.active
	if { SpellCooldown(ascendance_caster) > 10 or Level() < 87 } and SpellCooldown(fire_elemental_totem) > 10 or BuffPresent(ascendance_caster_buff) or BuffPresent(burst_haste_buff any=1) or TotemPresent(fire totem=fire_elemental_totem) UseItemActions()

	unless Talent(unleashed_fury_talent) and not BuffPresent(ascendance_caster_buff) and Spell(unleash_elements)
	{
		#spiritwalkers_grace,moving=1,if=buff.ascendance.up
		if Speed() > 0 and BuffPresent(ascendance_caster_buff) Spell(spiritwalkers_grace)

		unless target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and { BuffPresent(ascendance_caster_buff) or not SpellCooldown(lava_burst) > 0 } and Spell(lava_burst)
			or target.TicksRemaining(flame_shock_debuff) < 2 and Spell(flame_shock)
			or Talent(elemental_blast_talent) and Spell(elemental_blast)
			or BuffStacks(lightning_shield_buff) == 7 and Spell(earth_shock)
			or BuffStacks(lightning_shield_buff) > 3 and target.DebuffRemaining(flame_shock_debuff) > SpellCooldown(earth_shock) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(earth_shock) + target.TickTime(flame_shock_debuff) and Spell(earth_shock)
			or TimeInCombat() > 60 and target.DebuffRemaining(flame_shock_debuff) <= SpellData(ascendance_caster_buff duration) and SpellCooldown(ascendance_caster) + SpellData(ascendance_caster_buff duration) < SpellData(flame_shock_debuff duration) and Spell(flame_shock)
		{
			#earth_elemental_totem,if=!active&cooldown.fire_elemental_totem.remains>=60
			if not TotemPresent(earth totem=earth_elemental_totem) and SpellCooldown(fire_elemental_totem) >= 60 Spell(earth_elemental_totem)

			unless not TotemPresent(fire) and Spell(searing_totem)
			{
				#spiritwalkers_grace,moving=1,if=((talent.elemental_blast.enabled&cooldown.elemental_blast.remains=0)|(cooldown.lava_burst.remains=0&!buff.lava_surge.react))|(buff.raid_movement.duration>=action.unleash_elements.gcd+action.earth_shock.gcd)
				if Speed() > 0 and { Talent(elemental_blast_talent) and not SpellCooldown(elemental_blast) > 0 or not SpellCooldown(lava_burst) > 0 and not BuffPresent(lava_surge_buff) or 0 >= GCD() + GCD() } Spell(spiritwalkers_grace)
			}
		}
	}
}

### Elemental icons.
AddCheckBox(opt_shaman_elemental "Show Elemental icons" specialization=elemental default)
AddCheckBox(opt_shaman_elemental_aoe L(AOE) specialization=elemental default)

AddIcon specialization=elemental help=shortcd enemies=1 checkbox=opt_shaman_elemental checkbox=!opt_shaman_elemental_aoe
{
	if InCombat(no) ElementalPrecombatShortCdActions()
	ElementalDefaultShortCdActions()
}

AddIcon specialization=elemental help=shortcd checkbox=opt_shaman_elemental checkbox=opt_shaman_elemental_aoe
{
	if InCombat(no) ElementalPrecombatShortCdActions()
	ElementalDefaultShortCdActions()
}

AddIcon specialization=elemental help=main enemies=1 checkbox=opt_shaman_elemental
{
	if InCombat(no) ElementalPrecombatActions()
	ElementalDefaultActions()
}

AddIcon specialization=elemental help=predict enemies=1 checkbox=opt_shaman_elemental checkbox=!opt_shaman_elemental_aoe
{
	if InCombat(no) ElementalPrecombatPredictActions()
	ElementalDefaultPredictActions()
}

AddIcon specialization=elemental help=aoe checkbox=opt_shaman_elemental checkbox=opt_shaman_elemental_aoe
{
	if InCombat(no) ElementalPrecombatActions()
	ElementalDefaultActions()
}

AddIcon specialization=elemental help=cd enemies=1 checkbox=opt_shaman_elemental checkbox=!opt_shaman_elemental_aoe
{
	if InCombat(no) ElementalPrecombatCdActions()
	ElementalDefaultCdActions()
}

AddIcon specialization=elemental help=cd checkbox=opt_shaman_elemental checkbox=opt_shaman_elemental_aoe
{
	if InCombat(no) ElementalPrecombatCdActions()
	ElementalDefaultCdActions()
}

###
### Enhancement
###
# Based on SimulationCraft profile "Shaman_Enhancement_T16H".
#	class=shaman
#	spec=enhancement
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#WZ!...0.1
#	glyphs=chain_lightning

# ActionList: EnhancementPrecombatActions --> main, shortcd, cd

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
}

AddFunction EnhancementPrecombatShortCdActions {}

AddFunction EnhancementPrecombatCdActions
{
	unless WeaponEnchantExpires(main) and Spell(windfury_weapon)
		or WeaponEnchantExpires(off) and Spell(flametongue_weapon)
		or not BuffPresent(lightning_shield_buff) and Spell(lightning_shield)
	{
		#virmens_bite_potion
		UsePotionAgility()
	}
}

# ActionList: EnhancementDefaultActions --> main, shortcd, cd

AddFunction EnhancementDefaultActions
{
	#auto_attack
	#run_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 EnhancementSingleActions()
	#run_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 EnhancementAoeActions()
}

AddFunction EnhancementDefaultShortCdActions
{
	#elemental_mastery,if=talent.elemental_mastery.enabled&(talent.primal_elementalist.enabled&glyph.fire_elemental_totem.enabled&(cooldown.fire_elemental_totem.remains=0|cooldown.fire_elemental_totem.remains>=80))
	if Talent(elemental_mastery_talent) and Talent(primal_elementalist_talent) and Glyph(glyph_of_fire_elemental_totem) and { not SpellCooldown(fire_elemental_totem) > 0 or SpellCooldown(fire_elemental_totem) >= 80 } Spell(elemental_mastery)
	#elemental_mastery,if=talent.elemental_mastery.enabled&(talent.primal_elementalist.enabled&!glyph.fire_elemental_totem.enabled&(cooldown.fire_elemental_totem.remains=0|cooldown.fire_elemental_totem.remains>=50))
	if Talent(elemental_mastery_talent) and Talent(primal_elementalist_talent) and not Glyph(glyph_of_fire_elemental_totem) and { not SpellCooldown(fire_elemental_totem) > 0 or SpellCooldown(fire_elemental_totem) >= 50 } Spell(elemental_mastery)
	#elemental_mastery,if=talent.elemental_mastery.enabled&!talent.primal_elementalist.enabled
	if Talent(elemental_mastery_talent) and Talent(primal_elementalist_talent no) Spell(elemental_mastery)
	#run_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 EnhancementSingleShortCdActions()
	#run_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 EnhancementAoeShortCdActions()
}

AddFunction EnhancementDefaultCdActions
{
	# CHANGE: Suggest breaking fear effects with Tremor Totem.
	if IsFeared() Spell(tremor_totem)

	#wind_shear
	InterruptActions()
	#bloodlust,if=target.health.pct<25|time>0.500
	if target.HealthPercent() < 25 or TimeInCombat() > 0.5 Bloodlust()
	#use_item,name=grips_of_celestial_harmony
	UseItemActions()
	#stormlash_totem,if=!active&!buff.stormlash.up&(buff.bloodlust.up|time>=60)
	if not TotemPresent(air totem=stormlash_totem) and not BuffPresent(stormlash_buff any=1) and { BuffPresent(burst_haste_buff any=1) or TimeInCombat() >= 60 } Spell(stormlash_totem)
	#virmens_bite_potion,if=time>60&(pet.primal_fire_elemental.active|pet.greater_fire_elemental.active|target.time_to_die<=60)
	if TimeInCombat() > 60 and { TotemPresent(fire totem=fire_elemental_totem) or TotemPresent(fire totem=fire_elemental_totem) or target.TimeToDie() <= 60 } UsePotionAgility()
	#blood_fury
	Spell(blood_fury_apsp)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#berserking
	Spell(berserking)
	#fire_elemental_totem,if=!active
	if not TotemPresent(fire totem=fire_elemental_totem) Spell(fire_elemental_totem)
	#ascendance,if=cooldown.strike.remains>=3
	if SpellCooldown(strike) >= 3 Spell(ascendance_melee)
	#lifeblood,if=(glyph.fire_elemental_totem.enabled&(pet.primal_fire_elemental.active|pet.greater_fire_elemental.active))|!glyph.fire_elemental_totem.enabled
	if Glyph(glyph_of_fire_elemental_totem) and { TotemPresent(fire totem=fire_elemental_totem) or TotemPresent(fire totem=fire_elemental_totem) } or not Glyph(glyph_of_fire_elemental_totem) Spell(lifeblood)
	#run_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 EnhancementSingleCdActions()
	#run_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 EnhancementAoeCdActions()
}

# ActionList: EnhancementAoeActions --> main, shortcd, cd

AddFunction EnhancementAoeActions
{
	#fire_nova,if=active_flame_shock>=4
	if DebuffCountOnAny(flame_shock_debuff) >= 4 Spell(fire_nova)
	#wait,sec=cooldown.fire_nova.remains,if=active_flame_shock>=4&cooldown.fire_nova.remains<0.67
	unless DebuffCountOnAny(flame_shock_debuff) >= 4 and SpellCooldown(fire_nova) < 0.67 and SpellCooldown(fire_nova) > 0
	{
		#magma_totem,if=active_enemies>5&!totem.fire.active
		if Enemies() > 5 and not TotemPresent(fire) and target.InRange(primal_strike) Spell(magma_totem)
		#searing_totem,if=active_enemies<=5&!totem.fire.active
		if Enemies() <= 5 and not TotemPresent(fire) Spell(searing_totem)
		#lava_lash,if=dot.flame_shock.ticking
		if target.DebuffPresent(flame_shock_debuff) Spell(lava_lash)
		#elemental_blast,if=talent.elemental_blast.enabled&buff.maelstrom_weapon.react>=1
		if Talent(elemental_blast_talent) and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(elemental_blast)
		#chain_lightning,if=active_enemies>=2&buff.maelstrom_weapon.react>=3
		if Enemies() >= 2 and BuffStacks(maelstrom_weapon_buff) >= 3 Spell(chain_lightning)
		#unleash_elements
		Spell(unleash_elements)
		#flame_shock,cycle_targets=1,if=!ticking
		if not target.DebuffPresent(flame_shock_debuff) Spell(flame_shock)
		#stormblast
		if BuffPresent(ascendance_melee_buff) Spell(stormblast)
		#fire_nova,if=active_flame_shock>=3
		if DebuffCountOnAny(flame_shock_debuff) >= 3 Spell(fire_nova)
		#chain_lightning,if=active_enemies>=2&buff.maelstrom_weapon.react>=1
		if Enemies() >= 2 and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(chain_lightning)
		#stormstrike
		if BuffExpires(ascendance_melee_buff) Spell(stormstrike)
		#earth_shock,if=active_enemies<4
		if Enemies() < 4 Spell(earth_shock)
		#fire_nova,if=active_flame_shock>=1
		if DebuffCountOnAny(flame_shock_debuff) >= 1 Spell(fire_nova)
	}
}

AddFunction EnhancementAoeShortCdActions {}

AddFunction EnhancementAoeCdActions
{
	unless DebuffCountOnAny(flame_shock_debuff) >= 4 and Spell(fire_nova)
	{
		#wait,sec=cooldown.fire_nova.remains,if=active_flame_shock>=4&cooldown.fire_nova.remains<0.67
		unless DebuffCountOnAny(flame_shock_debuff) >= 4 and SpellCooldown(fire_nova) < 0.67 and SpellCooldown(fire_nova) > 0
		{
			unless Enemies() > 5 and not TotemPresent(fire) and target.InRange(primal_strike) and Spell(magma_totem)
				or Enemies() <= 5 and not TotemPresent(fire) and Spell(searing_totem)
				or target.DebuffPresent(flame_shock_debuff) and Spell(lava_lash)
				or Talent(elemental_blast_talent) and BuffStacks(maelstrom_weapon_buff) >= 1 and Spell(elemental_blast)
				or Enemies() >= 2 and BuffStacks(maelstrom_weapon_buff) >= 3 and Spell(chain_lightning)
				or Spell(unleash_elements)
				or not target.DebuffPresent(flame_shock_debuff) and Spell(flame_shock)
				or BuffPresent(ascendance_melee_buff) and Spell(stormblast)
				or DebuffCountOnAny(flame_shock_debuff) >= 3 and Spell(fire_nova)
				or Enemies() >= 2 and BuffStacks(maelstrom_weapon_buff) >= 1 and Spell(chain_lightning)
				or BuffExpires(ascendance_melee_buff) and Spell(stormstrike)
				or Enemies() < 4 Spell(earth_shock)
			{
				#feral_spirit
				Spell(feral_spirit)
				#earth_elemental_totem,if=!active&cooldown.fire_elemental_totem.remains>=50
				if not TotemPresent(earth totem=earth_elemental_totem) and SpellCooldown(fire_elemental_totem) >= 50 Spell(earth_elemental_totem)
				#spiritwalkers_grace,moving=1
				if Speed() > 0 Spell(spiritwalkers_grace)
			}
		}
	}
}

# ActionList: EnhancementSingleActions --> main, shortcd, cd

AddFunction EnhancementSingleActions
{
	#searing_totem,if=!totem.fire.active
	if not TotemPresent(fire) Spell(searing_totem)
	#unleash_elements,if=(talent.unleashed_fury.enabled|set_bonus.tier16_2pc_melee=1)
	if Talent(unleashed_fury_talent) or ArmorSetBonus(T16_melee 2) == 1 Spell(unleash_elements)
	#elemental_blast,if=talent.elemental_blast.enabled&buff.maelstrom_weapon.react>=1
	if Talent(elemental_blast_talent) and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(elemental_blast)
	#lightning_bolt,if=buff.maelstrom_weapon.react=5
	if BuffStacks(maelstrom_weapon_buff) == 5 Spell(lightning_bolt)
	#stormblast
	if BuffPresent(ascendance_melee_buff) Spell(stormblast)
	#stormstrike
	if BuffExpires(ascendance_melee_buff) Spell(stormstrike)
	#flame_shock,if=buff.unleash_flame.up&!ticking
	if BuffPresent(unleash_flame_buff) and not target.DebuffPresent(flame_shock_debuff) Spell(flame_shock)
	#lava_lash
	Spell(lava_lash)
	#lightning_bolt,if=set_bonus.tier15_2pc_melee=1&buff.maelstrom_weapon.react>=4&!buff.ascendance.up
	if ArmorSetBonus(T15_melee 2) == 1 and BuffStacks(maelstrom_weapon_buff) >= 4 and not BuffPresent(ascendance_melee_buff) Spell(lightning_bolt)
	#flame_shock,if=(buff.unleash_flame.up&(dot.flame_shock.remains<10|action.flame_shock.tick_damage>dot.flame_shock.tick_dmg))|!ticking
	if BuffPresent(unleash_flame_buff) and { target.DebuffRemaining(flame_shock_debuff) < 10 or target.Damage(flame_shock_debuff) > target.LastEstimatedDamage(flame_shock_debuff) } or not target.DebuffPresent(flame_shock_debuff) Spell(flame_shock)
	#unleash_elements
	Spell(unleash_elements)
	#frost_shock,if=glyph.frost_shock.enabled&set_bonus.tier14_4pc_melee=0
	if Glyph(glyph_of_frost_shock) and ArmorSetBonus(T14_melee 4) == 0 Spell(frost_shock)
	#lightning_bolt,if=buff.maelstrom_weapon.react>=3&!buff.ascendance.up
	if BuffStacks(maelstrom_weapon_buff) >= 3 and not BuffPresent(ascendance_melee_buff) Spell(lightning_bolt)
	#ancestral_swiftness,if=talent.ancestral_swiftness.enabled&buff.maelstrom_weapon.react<2
	if Talent(ancestral_swiftness_talent) and BuffStacks(maelstrom_weapon_buff) < 2 Spell(ancestral_swiftness)
	#lightning_bolt,if=buff.ancestral_swiftness.up
	if BuffPresent(ancestral_swiftness_buff) Spell(lightning_bolt)
	#earth_shock,if=(!glyph.frost_shock.enabled|set_bonus.tier14_4pc_melee=1)
	if not Glyph(glyph_of_frost_shock) or ArmorSetBonus(T14_melee 4) == 1 Spell(earth_shock)
	#lightning_bolt,if=buff.maelstrom_weapon.react>1&!buff.ascendance.up
	if BuffStacks(maelstrom_weapon_buff) > 1 and not BuffPresent(ascendance_melee_buff) Spell(lightning_bolt)
}

AddFunction EnhancementSingleShortCdActions {}

AddFunction EnhancementSingleCdActions
{
	unless not TotemPresent(fire) and Spell(searing_totem)
		or { Talent(unleashed_fury_talent) or ArmorSetBonus(T16_melee 2) == 1 } and Spell(unleash_elements)
		or Talent(elemental_blast_talent) and BuffStacks(maelstrom_weapon_buff) >= 1 and Spell(elemental_blast)
		or BuffStacks(maelstrom_weapon_buff) == 5 and Spell(lightning_bolt)
	{
		#feral_spirit,if=set_bonus.tier15_4pc_melee=1
		if ArmorSetBonus(T15_melee 4) == 1 Spell(feral_spirit)

		unless BuffPresent(ascendance_melee_buff) and Spell(stormblast)
			or BuffExpires(ascendance_melee_buff) and Spell(stormstrike)
			or BuffPresent(unleash_flame_buff) and not target.DebuffPresent(flame_shock_debuff) and Spell(flame_shock)
			or Spell(lava_lash)
			or ArmorSetBonus(T15_melee 2) == 1 and BuffStacks(maelstrom_weapon_buff) >= 4 and not BuffPresent(ascendance_melee_buff) and Spell(lightning_bolt)
			or { BuffPresent(unleash_flame_buff) and { target.DebuffRemaining(flame_shock_debuff) < 10 or target.Damage(flame_shock_debuff) > target.LastEstimatedDamage(flame_shock_debuff) } or not target.DebuffPresent(flame_shock_debuff) } and Spell(flame_shock)
			or Spell(unleash_elements)
			or Glyph(glyph_of_frost_shock) and ArmorSetBonus(T14_melee 4) == 0 and Spell(frost_shock)
			or BuffStacks(maelstrom_weapon_buff) >= 3 and not BuffPresent(ascendance_melee_buff) and Spell(lightning_bolt)
			or Talent(ancestral_swiftness_talent) and BuffStacks(maelstrom_weapon_buff) < 2 Spell(ancestral_swiftness)
			or BuffPresent(ancestral_swiftness_buff) and Spell(lightning_bolt)
			or { not Glyph(glyph_of_frost_shock) or ArmorSetBonus(T14_melee 4) == 1 } and Spell(earth_shock)
		{
			#feral_spirit
			Spell(feral_spirit)
			#earth_elemental_totem,if=!active
			if not TotemPresent(earth totem=earth_elemental_totem) Spell(earth_elemental_totem)
			#spiritwalkers_grace,moving=1
			if Speed() > 0 Spell(spiritwalkers_grace)
		}
	}
}

### Enhancement icons.
AddCheckBox(opt_shaman_enhancement "Show Enhancement icons" specialization=enhancement default)
AddCheckBox(opt_shaman_enhancement_aoe L(AOE) specialization=enhancement default)

AddIcon specialization=enhancement help=shortcd enemies=1 checkbox=opt_shaman_enhancement checkbox=!opt_shaman_enhancement_aoe
{
	if InCombat(no) EnhancementPrecombatShortCdActions()
	EnhancementDefaultShortCdActions()
}

AddIcon specialization=enhancement help=shortcd checkbox=opt_shaman_enhancement checkbox=opt_shaman_enhancement_aoe
{
	if InCombat(no) EnhancementPrecombatShortCdActions()
	EnhancementDefaultShortCdActions()
}

AddIcon specialization=enhancement help=main enemies=1 checkbox=opt_shaman_enhancement
{
	if InCombat(no) EnhancementPrecombatActions()
	EnhancementDefaultActions()
}

AddIcon specialization=enhancement help=aoe checkbox=opt_shaman_enhancement checkbox=opt_shaman_enhancement_aoe
{
	if InCombat(no) EnhancementPrecombatActions()
	EnhancementDefaultActions()
}

AddIcon specialization=enhancement help=cd enemies=1 checkbox=opt_shaman_enhancement checkbox=!opt_shaman_enhancement_aoe
{
	if InCombat(no) EnhancementPrecombatCdActions()
	EnhancementDefaultCdActions()
}

AddIcon specialization=enhancement help=cd checkbox=opt_shaman_enhancement checkbox=opt_shaman_enhancement_aoe
{
	if InCombat(no) EnhancementPrecombatCdActions()
	EnhancementDefaultCdActions()
}

###
### Restoration
###
# Information from Elitist Jerks, "[Resto] It's Raining Heals 5.4"
#	http://forums.elitistjerks.com/page/articles.html/_/world-of-warcraft/shaman/resto-its-raining-heals-54-r89

AddFunction RestorationMainActions
{
	if WeaponEnchantExpires(mainhand) Spell(earthliving_weapon)
	if BuffExpires(water_shield_buff) Spell(water_shield)
	if BuffCountOnAny(earth_shield_buff) == 0 Spell(earth_shield)
	if Glyph(glyph_of_totemic_recall)
	{
		# Suggest Totemic Recall to regain mana from Healing Stream Totem, but only if it won't
		# recall other totems with very long CDs.
		#
		# Totemic Recall is suggested at 3s remaining on HST so that there is still time to cast
		# it after the current spellcast and GCD.
		#
		if TotemPresent(water totem=healing_stream_totem) and TotemExpires(water 3)
			and TotemExpires(fire) and TotemExpires(earth) and TotemExpires(air)
		{
			Spell(totemic_recall)
		}
	}
	if TotemExpires(water) Spell(healing_stream_totem)
	if Glyph(glyph_of_riptide no) Spell(riptide)
}

AddFunction RestorationAoeActions
{
	if WeaponEnchantExpires(mainhand) Spell(earthliving_weapon)
	if TotemExpires(water) Spell(healing_stream_totem)
	Spell(healing_rain)
	Spell(chain_heal)
}

AddFunction RestorationShortCdActions
{
	if Talent(primal_elementalist_talent) and pet.Present()
	{
		if TotemPresent(fire totem=fire_elemental_totem) and BuffExpires(pet_empower any=1) Spell(pet_empower)
		if TotemPresent(earth totem=earth_elemental_totem) and BuffExpires(pet_reinforce any=1) Spell(pet_reinforce)
	}
	Spell(unleash_elements)
}

### Restoration icons.
AddCheckBox(opt_shaman_restoration "Show Restoration icons" specialization=restoration default)
AddCheckBox(opt_shaman_restoration_aoe L(AOE) specialization=restoration default)

AddIcon specialization=restoration help=shortcd checkbox=opt_shaman_restoration
{
	RestorationShortCdActions()
}

AddIcon specialization=restoration help=main checkbox=opt_shaman_restoration
{
	RestorationMainActions()
}

AddIcon specialization=restoration help=aoe checkbox=opt_shaman_restoration checkbox=opt_shaman_restoration_aoe
{
	RestorationAoeActions()
}

AddIcon specialization=restoration help=cd checkbox=opt_shaman_restoration
{
	if IsFeared() Spell(tremor_totem)
	InterruptActions()
	if BuffExpires(stormlash_totem_buff any=1) and {BuffPresent(burst_haste any=1) or TimeInCombat() >60} Spell(stormlash_totem)
	if Speed(more 0) Spell(spiritwalkers_grace)
	if TotemExpires(water)
	{
		if ManaPercent(less 80) Spell(mana_tide_totem)
		if Talent(healing_tide_totem) Spell(healing_tide_totem)
	}
	if Talent(ancestral_guidance_talent) Spell(ancestral_guidance)
	Spell(ascendance_heal)
	Spell(fire_elemental_totem)
	Spell(earth_elemental_totem)
}
]]

	OvaleScripts:RegisterScript("SHAMAN", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("SHAMAN", "Ovale", desc, code, "script")
end
