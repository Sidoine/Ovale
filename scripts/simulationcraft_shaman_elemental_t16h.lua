local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Shaman_Elemental_T16H"
	local desc = "[5.4] SimulationCraft: Shaman_Elemental_T16H"
	local code = [[
# Based on SimulationCraft profile "Shaman_Elemental_T16H".
#	class=shaman
#	spec=elemental
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Wa!...2.0
#	glyphs=chain_lightning

Include(ovale_common)
Include(ovale_shaman_spells)

AddCheckBox(opt_potion_intellect ItemName(jade_serpent_potion) default)
AddCheckBox(opt_bloodlust SpellName(bloodlust) default)

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

AddFunction ElementalPrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#flametongue_weapon,weapon=main
	if WeaponEnchantExpires(main) Spell(flametongue_weapon)
	#lightning_shield,if=!buff.lightning_shield.up
	if not BuffPresent(lightning_shield_buff) Spell(lightning_shield)
	#snapshot_stats
	#jade_serpent_potion
	UsePotionIntellect()
}

AddFunction ElementalDefaultActions
{
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
	#elemental_mastery,if=talent.elemental_mastery.enabled&(time>15&((!buff.bloodlust.up&time<120)|(!buff.berserking.up&!buff.bloodlust.up&buff.ascendance.up)|(time>=200&(cooldown.ascendance.remains>30|level<87))))
	if Talent(elemental_mastery_talent) and TimeInCombat() > 15 and { not BuffPresent(burst_haste_buff any=1) and TimeInCombat() < 120 or not BuffPresent(berserking_buff) and not BuffPresent(burst_haste_buff any=1) and BuffPresent(ascendance_caster_buff) or TimeInCombat() >= 200 and { SpellCooldown(ascendance_caster) > 30 or Level() < 87 } } Spell(elemental_mastery)
	#ancestral_swiftness,if=talent.ancestral_swiftness.enabled&!buff.ascendance.up
	if Talent(ancestral_swiftness_talent) and not BuffPresent(ascendance_caster_buff) Spell(ancestral_swiftness)
	#fire_elemental_totem,if=!active
	if not TotemPresent(fire totem=fire_elemental_totem) Spell(fire_elemental_totem)
	#ascendance,if=active_enemies>1|(dot.flame_shock.remains>buff.ascendance.duration&(target.time_to_die<20|buff.bloodlust.up|time>=60)&cooldown.lava_burst.remains>0)
	if Enemies() > 1 or target.DebuffRemaining(flame_shock_debuff) > SpellData(ascendance_caster_buff duration) and { target.TimeToDie() < 20 or BuffPresent(burst_haste_buff any=1) or TimeInCombat() >= 60 } and SpellCooldown(lava_burst) > 0 Spell(ascendance_caster)
	#run_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ElementalSingleActions()
	#run_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 ElementalAoeActions()
}

AddFunction ElementalAoeActions
{
	#lava_beam
	if BuffPresent(ascendance_caster_buff) Spell(lava_beam)
	#magma_totem,if=active_enemies>2&!totem.fire.active
	if Enemies() > 2 and not TotemPresent(fire) and target.InRange(primal_strike) Spell(magma_totem)
	#searing_totem,if=active_enemies<=2&!totem.fire.active
	if Enemies() <= 2 and not TotemPresent(fire) Spell(searing_totem)
	#lava_burst,if=active_enemies<3&dot.flame_shock.remains>cast_time&cooldown_react
	if Enemies() < 3 and target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and not SpellCooldown(lava_burst) > 0 Spell(lava_burst)
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
	#use_item,name=grips_of_tidal_force,if=((cooldown.ascendance.remains>10|level<87)&cooldown.fire_elemental_totem.remains>10)|buff.ascendance.up|buff.bloodlust.up|totem.fire_elemental_totem.active
	if { SpellCooldown(ascendance_caster) > 10 or Level() < 87 } and SpellCooldown(fire_elemental_totem) > 10 or BuffPresent(ascendance_caster_buff) or BuffPresent(burst_haste_buff any=1) or TotemPresent(fire totem=fire_elemental_totem) UseItemActions()
	#unleash_elements,if=talent.unleashed_fury.enabled&!buff.ascendance.up
	if Talent(unleashed_fury_talent) and not BuffPresent(ascendance_caster_buff) Spell(unleash_elements)
	#spiritwalkers_grace,moving=1,if=buff.ascendance.up
	if Speed() > 0 and BuffPresent(ascendance_caster_buff) Spell(spiritwalkers_grace)
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
	#earth_elemental_totem,if=!active&cooldown.fire_elemental_totem.remains>=60
	if not TotemPresent(earth totem=earth_elemental_totem) and SpellCooldown(fire_elemental_totem) >= 60 Spell(earth_elemental_totem)
	#searing_totem,if=cooldown.fire_elemental_totem.remains>20&!totem.fire.active
	if SpellCooldown(fire_elemental_totem) > 20 and not TotemPresent(fire) Spell(searing_totem)
	#spiritwalkers_grace,moving=1,if=((talent.elemental_blast.enabled&cooldown.elemental_blast.remains=0)|(cooldown.lava_burst.remains=0&!buff.lava_surge.react))|(buff.raid_movement.duration>=action.unleash_elements.gcd+action.earth_shock.gcd)
	if Speed() > 0 and { Talent(elemental_blast_talent) and not SpellCooldown(elemental_blast) > 0 or not SpellCooldown(lava_burst) > 0 and not BuffPresent(lava_surge_buff) or 0 >= GCD() + GCD() } Spell(spiritwalkers_grace)
	#lightning_bolt
	Spell(lightning_bolt)
}

AddIcon specialization=elemental help=main enemies=1
{
	if InCombat(no) ElementalPrecombatActions()
	ElementalDefaultActions()
}

AddIcon specialization=elemental help=aoe
{
	if InCombat(no) ElementalPrecombatActions()
	ElementalDefaultActions()
}

### Required symbols
# ancestral_swiftness
# ancestral_swiftness_talent
# arcane_torrent_mana
# ascendance_caster
# ascendance_caster_buff
# berserking
# berserking_buff
# blood_fury_apsp
# chain_lightning
# earth_elemental_totem
# earth_shock
# earthquake
# elemental_blast
# elemental_blast_talent
# elemental_mastery
# elemental_mastery_buff
# elemental_mastery_talent
# fire_elemental_totem
# flame_shock
# flame_shock_debuff
# flametongue_weapon
# jade_serpent_potion
# lava_beam
# lava_burst
# lava_surge_buff
# lightning_bolt
# lightning_shield
# lightning_shield_buff
# magma_totem
# primal_strike
# quaking_palm
# searing_totem
# spiritwalkers_grace
# stormlash_totem
# thunderstorm
# unleash_elements
# unleashed_fury_talent
# wind_shear
]]
	OvaleScripts:RegisterScript("SHAMAN", name, desc, code, "reference")
end
