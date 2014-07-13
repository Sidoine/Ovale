local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_shaman"
	local desc = "[5.4] Ovale: Elemental, Enhancement, Restoration"
	local code = [[
# Ovale shaman script based on SimulationCraft.

Include(ovale_common)
Include(ovale_shaman_common)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

###
### Elemental
###
# Based on SimulationCraft profile "Shaman_Elemental_T16H".
#	class=shaman
#	spec=elemental
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Wa!...2.0
#	glyphs=chain_lightning

AddFunction ElementalAoeActions
{
	#lava_beam
	Spell(lava_beam)
	#magma_totem,if=active_enemies>2&!totem.fire.active
	if Enemies() > 2 and not TotemPresent(fire) Spell(magma_totem)
	#searing_totem,if=active_enemies<=2&!totem.fire.active
	if Enemies() <= 2 and not TotemPresent(fire) Spell(searing_totem)
	#lava_burst,if=active_enemies<3&dot.flame_shock.remains>cast_time&cooldown_react
	if Enemies() < 3 and target.DebuffRemains(flame_shock_debuff) > CastTime(lava_burst) and True(lava_burst cooldown_react) Spell(lava_burst)
	#flame_shock,cycle_targets=1,if=!ticking&active_enemies<3
	if not target.DebuffPresent(flame_shock_debuff) and Enemies() < 3 Spell(flame_shock)
	#earthquake,if=active_enemies>4
	if Enemies() > 4 Spell(earthquake)
	#thunderstorm,if=mana.pct_nonproc<80
	if ManaPercent() < 80 Spell(thunderstorm)
	#chain_lightning,if=mana.pct_nonproc>10
	if ManaPercent() > 10 Spell(chain_lightning)
	#lightning_bolt
	Spell(lightning_bolt)
}

AddFunction ElementalSingleActions
{
	#unleash_elements,if=talent.unleashed_fury.enabled&!buff.ascendance.up
	if TalentPoints(unleashed_fury_talent) and not BuffPresent(ascendance_caster_buff) Spell(unleash_elements)
	#lava_burst,if=dot.flame_shock.remains>cast_time&(buff.ascendance.up|cooldown_react)
	if target.DebuffRemains(flame_shock_debuff) > CastTime(lava_burst) and { BuffPresent(ascendance_caster_buff) or True(lava_burst cooldown_react) } Spell(lava_burst)
	#flame_shock,if=ticks_remain<2
	if target.TicksRemain(flame_shock_debuff) < 2 Spell(flame_shock)
	#elemental_blast,if=talent.elemental_blast.enabled
	if TalentPoints(elemental_blast_talent) Spell(elemental_blast)
	#earth_shock,if=buff.lightning_shield.react=buff.lightning_shield.max_stack
	if BuffStacks(lightning_shield_buff) == 7 Spell(earth_shock)
	#earth_shock,if=buff.lightning_shield.react>3&dot.flame_shock.remains>cooldown&dot.flame_shock.remains<cooldown+action.flame_shock.tick_time
	if BuffStacks(lightning_shield_buff) > 3 and target.DebuffRemains(flame_shock_debuff) > SpellCooldown(earth_shock) and target.DebuffRemains(flame_shock_debuff) < SpellCooldown(earth_shock) + target.TickTime(flame_shock_debuff) Spell(earth_shock)
	#flame_shock,if=time>60&remains<=buff.ascendance.duration&cooldown.ascendance.remains+buff.ascendance.duration<duration
	if TimeInCombat() > 60 and target.DebuffRemains(flame_shock_debuff) <= SpellData(ascendance_caster_buff duration) and SpellCooldown(ascendance_caster) + SpellData(ascendance_caster_buff duration) < SpellData(flame_shock_debuff duration) Spell(flame_shock)
	#searing_totem,if=cooldown.fire_elemental_totem.remains>20&!totem.fire.active
	#if SpellCooldown(fire_elemental_totem) > 20 and not TotemPresent(fire) Spell(searing_totem)
	if not TotemPresent(fire) Spell(searing_totem)
	#lightning_bolt
	#Spell(lightning_bolt)
}

AddFunction ElementalSingleCdActions
{
	unless { TalentPoints(unleashed_fury_talent) and not BuffPresent(ascendance_caster_buff) and Spell(unleash_elements) }
		or { target.DebuffRemains(flame_shock_debuff) > CastTime(lava_burst) and { BuffPresent(ascendance_caster_buff) or True(lava_burst cooldown_react) } and Spell(lava_burst) }
		or { target.TicksRemain(flame_shock_debuff) < 2 and Spell(flame_shock) }
		or { TalentPoints(elemental_blast_talent) and Spell(elemental_blast) }
		or { BuffStacks(lightning_shield_buff) == 7 and Spell(earth_shock) }
		or { BuffStacks(lightning_shield_buff) > 3 and target.DebuffRemains(flame_shock_debuff) > SpellCooldown(earth_shock) and target.DebuffRemains(flame_shock_debuff) < SpellCooldown(earth_shock) + target.TickTime(flame_shock_debuff) and Spell(earth_shock) }
		or { TimeInCombat() > 60 and target.DebuffRemains(flame_shock_debuff) <= SpellData(ascendance_caster_buff duration) and SpellCooldown(ascendance_caster) + SpellData(ascendance_caster_buff duration) < SpellData(flame_shock_debuff duration) and Spell(flame_shock) }
	{
		#earth_elemental_totem,if=!active&cooldown.fire_elemental_totem.remains>=60
		if not TotemPresent(earth totem=earth_elemental_totem) and SpellCooldown(fire_elemental_totem) >= 60 Spell(earth_elemental_totem)
	}
}

AddFunction ElementalDefaultActions
{
	if not BuffPresent(lightning_shield_buff) Spell(lightning_shield)

	#run_action_list,name=single,if=active_enemies=1
	#if Enemies() == 1 ElementalSingleActions()
	#run_action_list,name=aoe,if=active_enemies>1
	#if Enemies() > 1 ElementalAoeActions()
}

AddFunction ElementalDefaultCdActions
{
	#wind_shear
	Interrupt()
	UseRacialInterruptActions()

	unless not BuffPresent(lightning_shield_buff)
	{
		#jade_serpent_potion,if=time>60&(pet.primal_fire_elemental.active|pet.greater_fire_elemental.active|target.time_to_die<=60)
		if TimeInCombat() > 60 and { TotemPresent(fire totem=fire_elemental_totem) or TotemPresent(fire totem=fire_elemental_totem) or target.TimeToDie() <= 60 } UsePotionIntellect()
		#berserking,if=!buff.bloodlust.up&!buff.elemental_mastery.up&(set_bonus.tier15_4pc_caster=1|(buff.ascendance.cooldown_remains=0&(dot.flame_shock.remains>buff.ascendance.duration|level<87)))
		if not BuffPresent(burst_haste any=1) and not BuffPresent(elemental_mastery_buff) and { ArmorSetBonus(T15_caster 4) == 1 or { not SpellCooldown(ascendance_caster) > 0 and { target.DebuffRemains(flame_shock_debuff) > SpellData(ascendance_caster_buff duration) or Level() < 87 } } } Spell(berserking)
		#blood_fury,if=buff.bloodlust.up|buff.ascendance.up|((cooldown.ascendance.remains>10|level<87)&cooldown.fire_elemental_totem.remains>10)
		if BuffPresent(burst_haste any=1) or BuffPresent(ascendance_caster_buff) or { { SpellCooldown(ascendance_caster) > 10 or Level() < 87 } and SpellCooldown(fire_elemental_totem) > 10 } Spell(blood_fury)
		#elemental_mastery,if=talent.elemental_mastery.enabled&(time>15&((!buff.bloodlust.up&time<120)|(!buff.berserking.up&!buff.bloodlust.up&buff.ascendance.up)|(time>=200&(cooldown.ascendance.remains>30|level<87))))
		if TalentPoints(elemental_mastery_talent) and { TimeInCombat() > 15 and { { not BuffPresent(burst_haste any=1) and TimeInCombat() < 120 } or { not BuffPresent(berserking_buff) and not BuffPresent(burst_haste any=1) and BuffPresent(ascendance_caster_buff) } or { TimeInCombat() >= 200 and { SpellCooldown(ascendance_caster) > 30 or Level() < 87 } } } } Spell(elemental_mastery)
		#ancestral_swiftness,if=talent.ancestral_swiftness.enabled&!buff.ascendance.up
		if TalentPoints(ancestral_swiftness_talent) and not BuffPresent(ascendance_caster_buff) Spell(ancestral_swiftness)
		#fire_elemental_totem,if=!active
		if not TotemPresent(fire totem=fire_elemental_totem) Spell(fire_elemental_totem)
		#ascendance,if=active_enemies>1|(dot.flame_shock.remains>buff.ascendance.duration&(target.time_to_die<20|buff.bloodlust.up|time>=60)&cooldown.lava_burst.remains>0)
		if Enemies() > 1 or { target.DebuffRemains(flame_shock_debuff) > SpellData(ascendance_caster_buff duration) and { target.TimeToDie() < 20 or BuffPresent(burst_haste any=1) or TimeInCombat() >= 60 } and SpellCooldown(lava_burst) > 0 } Spell(ascendance_caster)
		#use_item,name=grips_of_tidal_force,if=((cooldown.ascendance.remains>10|level<87)&cooldown.fire_elemental_totem.remains>10)|buff.ascendance.up|buff.bloodlust.up|totem.fire_elemental_totem.active
		if { { SpellCooldown(ascendance_caster) > 10 or Level() < 87 } and SpellCooldown(fire_elemental_totem) > 10 } or BuffPresent(ascendance_caster_buff) or BuffPresent(burst_haste any=1) or TotemPresent(fire totem=fire_elemental_totem) UseItemActions()
	}
}

AddFunction ElementalPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#flametongue_weapon,weapon=main
	if WeaponEnchantExpires(main) Spell(flametongue_weapon)
	#lightning_shield,if=!buff.lightning_shield.up
	if not BuffPresent(lightning_shield_buff) Spell(lightning_shield)
	#snapshot_stats
}

AddFunction ElementalPrecombatCdActions
{
	#jade_serpent_potion
	UsePotionIntellect()
}

### Elemental icons.

AddIcon specialization=elemental size=small checkbox=opt_icons_left
{
	if TalentPoints(stone_bulwark_totem_talent) Spell(stone_bulwark_totem)
	if TalentPoints(astral_shift_talent) Spell(astral_shift)
	if TalentPoints(earthgrab_totem_talent) Spell(earthgrab_totem)
	Spell(earthbind_totem)
}

AddIcon specialization=elemental size=small checkbox=opt_icons_left
{
	if IsFeared() Spell(tremor_totem)
	#if IsStunned() Spell(windwalk_totem)
	if TalentPoints(conductivity_talent) Spell(healing_rain)
	if TotemExpires(water)
	{
		if TalentPoints(healing_tide_totem) Spell(healing_tide_totem)
		Spell(healing_stream_totem)
	}
	if TalentPoints(ancestral_guidance_talent) Spell(ancestral_guidance)
}

AddIcon specialization=elemental help=main
{
	ElementalPrecombatActions()
	ElementalDefaultActions()
	ElementalSingleActions()
	#lightning_bolt
	Spell(lightning_bolt)
}

AddIcon specialization=elemental help=main
{
	ElementalPrecombatActions()
	ElementalDefaultActions()
	ElementalSingleActions()
}

AddIcon specialization=elemental help=aoe checkbox=aoe
{
	ElementalPrecombatActions()
	ElementalDefaultActions()
	ElementalAoeActions()
}

AddIcon specialization=elemental help=cd
{
	ElementalDefaultCdActions()
	ElementalSingleCdActions()
}

AddIcon specialization=elemental size=small checkbox=opt_icons_right
{
	#bloodlust,if=target.health.pct<25|time>5
	if target.HealthPercent() < 25 or TimeInCombat() > 5 Bloodlust()
	#stormlash_totem,if=!active&!buff.stormlash.up&(buff.bloodlust.up|time>=60)
	if not TotemPresent(air totem=stormlash_totem) and not BuffPresent(stormlash_buff) and { BuffPresent(burst_haste any=1) or TimeInCombat() >= 60 } Spell(stormlash_totem)
}

AddIcon specialization=elemental size=small checkbox=opt_icons_right
{
	UseItemActions()
}

###
### Enhancement
###
# Based on SimulationCraft profile "Shaman_Enhancement_T16H".
#	class=shaman
#	spec=enhancement
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#WZ!...0.1
#	glyphs=chain_lightning

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
	if TalentPoints(elemental_blast_talent) and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(elemental_blast)
	#chain_lightning,if=active_enemies>=2&buff.maelstrom_weapon.react>=3
	if Enemies() >= 2 and BuffStacks(maelstrom_weapon_buff) >= 3 Spell(chain_lightning)
	#unleash_elements
	Spell(unleash_elements)
	#flame_shock,cycle_targets=1,if=!ticking
	if not target.DebuffPresent(flame_shock_debuff) Spell(flame_shock)
	#stormblast
	Spell(stormblast)
	#fire_nova,if=active_flame_shock>=3
	if DebuffCountOnAny(flame_shock_debuff) >= 3 Spell(fire_nova)
	#chain_lightning,if=active_enemies>=2&buff.maelstrom_weapon.react>=1
	if Enemies() >= 2 and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(chain_lightning)
	#stormstrike
	Spell(stormstrike)
	#earth_shock,if=active_enemies<4
	if Enemies() < 4 Spell(earth_shock)
	#feral_spirit
	Spell(feral_spirit)
	#earth_elemental_totem,if=!active&cooldown.fire_elemental_totem.remains>=50
	if not TotemPresent(earth totem=earth_elemental_totem) and SpellCooldown(fire_elemental_totem) >= 50 Spell(earth_elemental_totem)
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
	if TalentPoints(elemental_blast_talent) and BuffStacks(maelstrom_weapon_buff) >= 1 Spell(elemental_blast)
	#lightning_bolt,if=buff.maelstrom_weapon.react=5
	if BuffStacks(maelstrom_weapon_buff) == 5 Spell(lightning_bolt)
	#stormblast
	Spell(stormblast)
	#stormstrike
	Spell(stormstrike)
	#flame_shock,if=buff.unleash_flame.up&!ticking
	if BuffPresent(unleash_flame_buff) and not target.DebuffPresent(flame_shock_debuff) Spell(flame_shock)
	#lava_lash
	Spell(lava_lash)
	#lightning_bolt,if=set_bonus.tier15_2pc_melee=1&buff.maelstrom_weapon.react>=4&!buff.ascendance.up
	if ArmorSetBonus(T15_melee 2) == 1 and BuffStacks(maelstrom_weapon_buff) >= 4 and not BuffPresent(ascendance_melee_buff) Spell(lightning_bolt)
	#flame_shock,if=(buff.unleash_flame.up&(dot.flame_shock.remains<10|action.flame_shock.tick_damage>dot.flame_shock.tick_dmg))|!ticking
	if { BuffPresent(unleash_flame_buff) and { target.DebuffRemains(flame_shock_debuff) < 10 or Damage(flame_shock) > target.LastEstimatedDamage(flame_shock_debuff) } } or not target.DebuffPresent(flame_shock_debuff) Spell(flame_shock)
	#unleash_elements
	Spell(unleash_elements)
	#frost_shock,if=glyph.frost_shock.enabled&set_bonus.tier14_4pc_melee=0
	if Glyph(glyph_of_frost_shock) and ArmorSetBonus(T14_melee 4) == 0 Spell(frost_shock)
	#lightning_bolt,if=buff.maelstrom_weapon.react>=3&!buff.ascendance.up
	if BuffStacks(maelstrom_weapon_buff) >= 3 and not BuffPresent(ascendance_melee_buff) Spell(lightning_bolt)
	#lightning_bolt,if=buff.ancestral_swiftness.up
	if BuffPresent(ancestral_swiftness_buff) or Spell(ancestral_swiftness) Spell(lightning_bolt)
	#earth_shock,if=(!glyph.frost_shock.enabled|set_bonus.tier14_4pc_melee=1)
	if { not Glyph(glyph_of_frost_shock) or ArmorSetBonus(T14_melee 4) == 1 } Spell(earth_shock)
	#lightning_bolt,if=buff.maelstrom_weapon.react>1&!buff.ascendance.up
	if BuffStacks(maelstrom_weapon_buff) > 1 and not BuffPresent(ascendance_melee_buff) Spell(lightning_bolt)
}

AddFunction EnhancementSingleCdActions
{
	unless not TotemPresent(fire)
		or { { TalentPoints(unleashed_fury_talent) or ArmorSetBonus(T16_melee 2) == 1 } and Spell(unleash_elements) }
		or { TalentPoints(elemental_blast_talent) and BuffStacks(maelstrom_weapon_buff) >= 1 and Spell(elemental_blast) }
		or BuffStacks(maelstrom_weapon_buff) == 5
	{
		#feral_spirit,if=set_bonus.tier15_4pc_melee=1
		if ArmorSetBonus(T15_melee 4) == 1 Spell(feral_spirit)

		unless Spell(stormblast)
			or Spell(stormstrike)
			or { BuffPresent(unleash_flame_buff) and not target.DebuffPresent(flame_shock_debuff) and Spell(flame_shock) }
			or Spell(lava_lash)
			or { ArmorSetBonus(T15_melee 2) == 1 and BuffStacks(maelstrom_weapon_buff) >= 4 and not BuffPresent(ascendance_melee_buff) }
			or { { BuffPresent(unleash_flame_buff) and { target.DebuffRemains(flame_shock_debuff) < 10 or Damage(flame_shock) > target.LastEstimatedDamage(flame_shock_debuff) } } or not target.DebuffPresent(flame_shock_debuff) or Spell(flame_shock) }
			or Spell(unleash_elements)
			or { Glyph(glyph_of_frost_shock) and ArmorSetBonus(T14_melee 4) == 0 and Spell(frost_shock) }
			or { BuffStacks(maelstrom_weapon_buff) >= 3 and not BuffPresent(ascendance_melee_buff) }
		{
			#ancestral_swiftness,if=talent.ancestral_swiftness.enabled&buff.maelstrom_weapon.react<2
			if TalentPoints(ancestral_swiftness_talent) and BuffStacks(maelstrom_weapon_buff) < 2 Spell(ancestral_swiftness)

			unless BuffPresent(ancestral_swiftness_buff)
				or { { not Glyph(glyph_of_frost_shock) or ArmorSetBonus(T14_melee 4) == 1 } and Spell(earth_shock) }
			{
				#feral_spirit
				Spell(feral_spirit)
				#earth_elemental_totem,if=!active
				if not TotemPresent(earth totem=earth_elemental_totem) Spell(earth_elemental_totem)
			}
		}
	}
}

AddFunction EnhancementDefaultActions
{
	if not BuffPresent(lightning_shield_buff) Spell(lightning_shield)

	#run_action_list,name=single,if=active_enemies=1
	#if Enemies() == 1 EnhancementSingleActions()
	#run_action_list,name=aoe,if=active_enemies>1
	#if Enemies() > 1 EnhancementAoeActions()
}

AddFunction EnhancementDefaultCdActions
{
	#wind_shear
	Interrupt()
	UseRacialInterruptActions()

	unless not BuffPresent(lightning_shield_buff)
	{
		#use_item,name=grips_of_celestial_harmony
		UseItemActions()
		#virmens_bite_potion,if=time>60&(pet.primal_fire_elemental.active|pet.greater_fire_elemental.active|target.time_to_die<=60)
		if TimeInCombat() > 60 and { TotemPresent(fire totem=fire_elemental_totem) or TotemPresent(fire totem=fire_elemental_totem) or target.TimeToDie() <= 60 } UsePotionAgility()
		#blood_fury
		UseRacialActions()
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
		#if { Glyph(glyph_of_fire_elemental_totem) and { TotemPresent(fire totem=fire_elemental_totem) or TotemPresent(fire totem=fire_elemental_totem) } } or not Glyph(glyph_of_fire_elemental_totem) Spell(lifeblood)
	}
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
}

AddFunction EnhancementPrecombatCdActions
{
	#virmens_bite_potion
	UsePotionAgility()
}

### Enhancement icons.

AddIcon specialization=enhancement size=small checkbox=opt_icons_left
{
	if TalentPoints(stone_bulwark_totem_talent) Spell(stone_bulwark_totem)
	if TalentPoints(astral_shift_talent) Spell(astral_shift)
	if TalentPoints(earthgrab_totem_talent) Spell(earthgrab_totem)
	Spell(earthbind_totem)
}

AddIcon specialization=enhancement size=small checkbox=opt_icons_left
{
	if IsFeared() Spell(tremor_totem)
	#if IsStunned() Spell(windwalk_totem)
	if TalentPoints(conductivity_talent) Spell(healing_rain)
	if TotemExpires(water)
	{
		if TalentPoints(healing_tide_totem) Spell(healing_tide_totem)
		Spell(healing_stream_totem)
	}
	if TalentPoints(ancestral_guidance_talent) Spell(ancestral_guidance)
}

AddIcon specialization=enhancement help=main
{
	EnhancementPrecombatActions()
	EnhancementDefaultActions()
	EnhancementSingleActions()
}

AddIcon specialization=enhancement help=main
{
	EnhancementPrecombatActions()
	EnhancementDefaultActions()
	EnhancementSingleActions()
}

AddIcon specialization=enhancement help=aoe checkbox=aoe
{
	EnhancementPrecombatActions()
	EnhancementDefaultActions()
	EnhancementAoeActions()
}

AddIcon specialization=enhancement help=cd
{
	EnhancementDefaultCdActions()
	EnhancementSingleCdActions()
}

AddIcon specialization=enhancement size=small checkbox=opt_icons_right
{
	#bloodlust,if=target.health.pct<25|time>5
	if target.HealthPercent() < 25 or TimeInCombat() > 5 Spell(bloodlust)
	#stormlash_totem,if=!active&!buff.stormlash.up&(buff.bloodlust.up|time>=60)
	if not TotemPresent(air totem=stormlash_totem) and not BuffPresent(stormlash_buff) and { BuffPresent(burst_haste any=1) or TimeInCombat() >= 60 } Spell(stormlash_totem)
}

AddIcon specialization=enhancement size=small checkbox=opt_icons_right
{
	UseItemActions()
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
	if TalentPoints(primal_elementalist_talent) and pet.Present()
	{
		if TotemPresent(fire totem=fire_elemental_totem) and BuffExpires(pet_empower any=1) Spell(pet_empower)
		if TotemPresent(earth totem=earth_elemental_totem) and BuffExpires(pet_reinforce any=1) Spell(pet_reinforce)
	}
	Spell(unleash_elements)
}

### Restoration icons.

AddIcon specialization=restoration size=small checkbox=opt_icons_left
{
	if TalentPoints(stone_bulwark_totem_talent) Spell(stone_bulwark_totem)
	if TalentPoints(astral_shift_talent) Spell(astral_shift)
	if TalentPoints(earthgrab_totem_talent) Spell(earthgrab_totem)
	Spell(earthbind_totem)
}

AddIcon specialization=restoration size=small checkbox=opt_icons_left
{
	if IsFeared() Spell(tremor_totem)
	#if IsStunned() Spell(windwalk_totem)
	if TotemExpires(water)
	{
		if ManaPercent(less 80) Spell(mana_tide_totem)
		Spell(healing_stream_totem)
		if TalentPoints(healing_tide_totem) Spell(healing_tide_totem)
	}
	if TalentPoints(ancestral_guidance_talent) Spell(ancestral_guidance)
	Spell(spirit_link_totem)
}

AddIcon specialization=restoration help=shortcd
{
	RestorationShortCdActions()
}

AddIcon specialization=restoration help=main
{
	RestorationMainActions()
}

AddIcon specialization=restoration help=aoe checkbox=aoe
{
	RestorationAoeActions()
}

AddIcon specialization=restoration help=cd
{
	Interrupt()
	if Speed(more 0) Spell(spiritwalkers_grace)
	Spell(ascendance_heal)
	Spell(fire_elemental_totem)
	Spell(earth_elemental_totem)
}

AddIcon specialization=restoration size=small checkbox=opt_icons_right
{
	if BuffExpires(stormlash_totem_buff any=1) and {BuffPresent(burst_haste any=1) or TimeInCombat() >60} Spell(stormlash_totem)
	if BuffExpires(burst_haste any=1) Bloodlust()
}

AddIcon specialization=restoration size=small checkbox=opt_icons_right
{
	UseItemActions()
}
]]

	OvaleScripts:RegisterScript("SHAMAN", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("SHAMAN", "Ovale", desc, code, "script")
end
