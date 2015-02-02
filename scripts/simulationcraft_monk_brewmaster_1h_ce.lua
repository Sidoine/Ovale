local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_monk_brewmaster_1h_ce_t17m"
	local desc = "[6.0] SimulationCraft: Monk_Brewmaster_1h_CE_T17M"
	local code = [[
# Based on SimulationCraft profile "Monk_Brewmaster_1h_CE_T17M".
#	class=monk
#	spec=brewmaster
#	talents=2133112
#	glyphs=fortifying_brew,expel_harm,fortuitous_spheres

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=brewmaster)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=brewmaster)
AddCheckBox(opt_potion_armor ItemName(draenic_armor_potion) default specialization=brewmaster)
AddCheckBox(opt_chi_burst SpellName(chi_burst) default specialization=brewmaster)

AddFunction BrewmasterUsePotionArmor
{
	if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(draenic_armor_potion usable=1)
}

AddFunction BrewmasterGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction BrewmasterInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(spear_hand_strike) Spell(spear_hand_strike)
		if not target.Classification(worldboss)
		{
			if target.InRange(paralysis) Spell(paralysis)
			Spell(arcane_torrent_chi)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			Spell(war_stomp)
		}
	}
}

### actions.default

AddFunction BrewmasterDefaultMainActions
{
	#chi_sphere,if=talent.power_strikes.enabled&buff.chi_sphere.react&chi<4
	#chi_brew,if=talent.chi_brew.enabled&chi.max-chi>=2&buff.elusive_brew_stacks.stack<=10&((charges=1&recharge_time<5)|charges=2|(target.time_to_die<15&(cooldown.touch_of_death.remains>target.time_to_die|glyph.touch_of_death.enabled)))
	if Talent(chi_brew_talent) and MaxChi() - Chi() >= 2 and BuffStacks(elusive_brew_stacks_buff) <= 10 and { Charges(chi_brew) == 1 and SpellChargeCooldown(chi_brew) < 5 or Charges(chi_brew) == 2 or target.TimeToDie() < 15 and { SpellCooldown(touch_of_death) > target.TimeToDie() or Glyph(glyph_of_touch_of_death) } } Spell(chi_brew)
	#chi_brew,if=(chi<1&stagger.heavy)|(chi<2&buff.shuffle.down)
	if Chi() < 1 and DebuffPresent(heavy_stagger_debuff) or Chi() < 2 and BuffExpires(shuffle_buff) Spell(chi_brew)
	#call_action_list,name=tod,if=target.health.percent<10&target.time_to_die<8&cooldown.touch_of_death.remains=0&!glyph.touch_of_death.enabled
	if target.HealthPercent() < 10 and target.TimeToDie() < 8 and not SpellCooldown(touch_of_death) > 0 and not Glyph(glyph_of_touch_of_death) BrewmasterTodMainActions()
	#call_action_list,name=st,if=active_enemies<3
	if Enemies() < 3 BrewmasterStMainActions()
	#call_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 BrewmasterAoeMainActions()
}

AddFunction BrewmasterDefaultShortCdActions
{
	#auto_attack
	BrewmasterGetInMeleeRange()
	#touch_of_death,if=target.health<health
	if target.Health() < Health() Spell(touch_of_death)
	#elusive_brew,if=buff.elusive_brew_stacks.react>=9&(buff.dampen_harm.down|buff.diffuse_magic.down)&buff.elusive_brew_activated.down
	if BuffStacks(elusive_brew_stacks_buff) >= 9 and { BuffExpires(dampen_harm_buff) or BuffExpires(diffuse_magic_buff) } and BuffExpires(elusive_brew_activated_buff) Spell(elusive_brew)
	#serenity,if=talent.serenity.enabled&cooldown.keg_smash.remains>6
	if Talent(serenity_talent) and SpellCooldown(keg_smash) > 6 Spell(serenity)
	#call_action_list,name=tod,if=target.health.percent<10&target.time_to_die<8&cooldown.touch_of_death.remains=0&!glyph.touch_of_death.enabled
	if target.HealthPercent() < 10 and target.TimeToDie() < 8 and not SpellCooldown(touch_of_death) > 0 and not Glyph(glyph_of_touch_of_death) BrewmasterTodShortCdActions()

	unless target.HealthPercent() < 10 and target.TimeToDie() < 8 and not SpellCooldown(touch_of_death) > 0 and not Glyph(glyph_of_touch_of_death) and BrewmasterTodShortCdPostConditions()
	{
		#call_action_list,name=st,if=active_enemies<3
		if Enemies() < 3 BrewmasterStShortCdActions()

		unless Enemies() < 3 and BrewmasterStShortCdPostConditions()
		{
			#call_action_list,name=aoe,if=active_enemies>=3
			if Enemies() >= 3 BrewmasterAoeShortCdActions()
		}
	}
}

AddFunction BrewmasterDefaultCdActions
{
	unless target.Health() < Health() and Spell(touch_of_death)
	{
		#spear_hand_strike
		BrewmasterInterruptActions()
		#nimble_brew
		if IsFeared() or IsRooted() or IsStunned() Spell(nimble_brew)
		#blood_fury,if=energy<=40
		if Energy() <= 40 Spell(blood_fury_apsp)
		#berserking,if=energy<=40
		if Energy() <= 40 Spell(berserking)
		#arcane_torrent,if=energy<=40
		if Energy() <= 40 Spell(arcane_torrent_chi)
		#gift_of_the_ox,if=buff.gift_of_the_ox.react&incoming_damage_1500ms
		#diffuse_magic,if=incoming_damage_1500ms&buff.fortifying_brew.down
		if IncomingDamage(1.5) > 0 and BuffExpires(fortifying_brew_buff) Spell(diffuse_magic)
		#dampen_harm,if=incoming_damage_1500ms&buff.fortifying_brew.down&buff.elusive_brew_activated.down
		if IncomingDamage(1.5) > 0 and BuffExpires(fortifying_brew_buff) and BuffExpires(elusive_brew_activated_buff) Spell(dampen_harm)
		#fortifying_brew,if=incoming_damage_1500ms&(buff.dampen_harm.down|buff.diffuse_magic.down)&buff.elusive_brew_activated.down
		if IncomingDamage(1.5) > 0 and { BuffExpires(dampen_harm_buff) or BuffExpires(diffuse_magic_buff) } and BuffExpires(elusive_brew_activated_buff) Spell(fortifying_brew)
		#invoke_xuen,if=talent.invoke_xuen.enabled&target.time_to_die>15&buff.shuffle.remains>=3&buff.serenity.down
		if Talent(invoke_xuen_talent) and target.TimeToDie() > 15 and BuffRemaining(shuffle_buff) >= 3 and BuffExpires(serenity_buff) Spell(invoke_xuen)
		#potion,name=draenic_armor,if=(buff.fortifying_brew.down&(buff.dampen_harm.down|buff.diffuse_magic.down)&buff.elusive_brew_activated.down)
		if BuffExpires(fortifying_brew_buff) and { BuffExpires(dampen_harm_buff) or BuffExpires(diffuse_magic_buff) } and BuffExpires(elusive_brew_activated_buff) BrewmasterUsePotionArmor()
	}
}

### actions.aoe

AddFunction BrewmasterAoeMainActions
{
	#blackout_kick,if=buff.shuffle.down
	if BuffExpires(shuffle_buff) Spell(blackout_kick)
	#chi_brew,if=target.health.percent<10&cooldown.touch_of_death.remains=0&chi<=3&chi>=1&(buff.shuffle.remains>=6|target.time_to_die<buff.shuffle.remains)&!glyph.touch_of_death.enabled
	if target.HealthPercent() < 10 and not SpellCooldown(touch_of_death) > 0 and Chi() <= 3 and Chi() >= 1 and { BuffRemaining(shuffle_buff) >= 6 or target.TimeToDie() < BuffRemaining(shuffle_buff) } and not Glyph(glyph_of_touch_of_death) Spell(chi_brew)
	#breath_of_fire,if=(chi>=3|buff.serenity.up)&buff.shuffle.remains>=6&dot.breath_of_fire.remains<=2.4&!talent.chi_explosion.enabled
	if { Chi() >= 3 or BuffPresent(serenity_buff) } and BuffRemaining(shuffle_buff) >= 6 and target.DebuffRemaining(breath_of_fire_debuff) <= 2.4 and not Talent(chi_explosion_talent) Spell(breath_of_fire)
	#keg_smash,if=chi.max-chi>=1&!buff.serenity.remains
	if MaxChi() - Chi() >= 1 and not BuffPresent(serenity_buff) Spell(keg_smash)
	#rushing_jade_wind,if=chi.max-chi>=1&!buff.serenity.remains&talent.rushing_jade_wind.enabled
	if MaxChi() - Chi() >= 1 and not BuffPresent(serenity_buff) and Talent(rushing_jade_wind_talent) Spell(rushing_jade_wind)
	#chi_wave,if=(energy+(energy.regen*gcd))<100
	if Energy() + EnergyRegenRate() * GCD() < 100 Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=talent.zen_sphere.enabled&!dot.zen_sphere.ticking&(energy+(energy.regen*gcd))<100
	if Talent(zen_sphere_talent) and not BuffPresent(zen_sphere_buff) and Energy() + EnergyRegenRate() * GCD() < 100 Spell(zen_sphere)
	#chi_explosion,if=chi>=4
	if Chi() >= 4 Spell(chi_explosion_tank)
	#blackout_kick,if=chi>=4
	if Chi() >= 4 Spell(blackout_kick)
	#blackout_kick,if=buff.shuffle.remains<=3&cooldown.keg_smash.remains>=gcd
	if BuffRemaining(shuffle_buff) <= 3 and SpellCooldown(keg_smash) >= GCD() Spell(blackout_kick)
	#blackout_kick,if=buff.serenity.up
	if BuffPresent(serenity_buff) Spell(blackout_kick)
	#expel_harm,if=chi.max-chi>=1&cooldown.keg_smash.remains>=gcd&(energy+(energy.regen*(cooldown.keg_smash.remains)))>=80
	if MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 80 Spell(expel_harm)
	#jab,if=chi.max-chi>=1&cooldown.keg_smash.remains>=gcd&cooldown.expel_harm.remains>=gcd&(energy+(energy.regen*(cooldown.keg_smash.remains)))>=80
	if MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and SpellCooldown(expel_harm) >= GCD() and Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 80 Spell(jab)
	#tiger_palm
	Spell(tiger_palm)
}

AddFunction BrewmasterAoeShortCdActions
{
	#purifying_brew,if=stagger.heavy
	if DebuffPresent(heavy_stagger_debuff) Spell(purifying_brew)

	unless BuffExpires(shuffle_buff) and Spell(blackout_kick)
	{
		#purifying_brew,if=buff.serenity.up
		if BuffPresent(serenity_buff) Spell(purifying_brew)
		#purifying_brew,if=!talent.chi_explosion.enabled&stagger.moderate&buff.shuffle.remains>=6
		if not Talent(chi_explosion_talent) and DebuffPresent(moderate_stagger_debuff) and BuffRemaining(shuffle_buff) >= 6 Spell(purifying_brew)
		#guard,if=(charges=1&recharge_time<5)|charges=2|target.time_to_die<15
		if Charges(guard) == 1 and SpellChargeCooldown(guard) < 5 or Charges(guard) == 2 or target.TimeToDie() < 15 Spell(guard)
		#guard,if=incoming_damage_10s>=health.max*0.5
		if IncomingDamage(10) >= MaxHealth() * 0.5 Spell(guard)
		#touch_of_death,if=target.health.percent<10&(buff.shuffle.remains>=6|target.time_to_die<=buff.shuffle.remains)&!glyph.touch_of_death.enabled
		if target.HealthPercent() < 10 and { BuffRemaining(shuffle_buff) >= 6 or target.TimeToDie() <= BuffRemaining(shuffle_buff) } and not Glyph(glyph_of_touch_of_death) Spell(touch_of_death)

		unless { Chi() >= 3 or BuffPresent(serenity_buff) } and BuffRemaining(shuffle_buff) >= 6 and target.DebuffRemaining(breath_of_fire_debuff) <= 2.4 and not Talent(chi_explosion_talent) and Spell(breath_of_fire) or MaxChi() - Chi() >= 1 and not BuffPresent(serenity_buff) and Spell(keg_smash)
		{
			#touch_of_death,if=target.health.percent<10&glyph.touch_of_death.enabled
			if target.HealthPercent() < 10 and Glyph(glyph_of_touch_of_death) Spell(touch_of_death)

			unless MaxChi() - Chi() >= 1 and not BuffPresent(serenity_buff) and Talent(rushing_jade_wind_talent) and Spell(rushing_jade_wind)
			{
				#chi_burst,if=(energy+(energy.regen*gcd))<100
				if Energy() + EnergyRegenRate() * GCD() < 100 and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
			}
		}
	}
}

### actions.precombat

AddFunction BrewmasterPrecombatMainActions
{
	#flask,type=greater_draenic_stamina_flask
	#food,type=talador_surf_and_turf
	#legacy_of_the_white_tiger,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(legacy_of_the_white_tiger)
	#stance,choose=sturdy_ox
	Spell(stance_of_the_sturdy_ox)
}

AddFunction BrewmasterPrecombatShortCdPostConditions
{
	not BuffPresent(str_agi_int_buff any=1) and Spell(legacy_of_the_white_tiger) or Spell(stance_of_the_sturdy_ox)
}

AddFunction BrewmasterPrecombatCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) and Spell(legacy_of_the_white_tiger) or Spell(stance_of_the_sturdy_ox)
	{
		#snapshot_stats
		#potion,name=draenic_armor
		BrewmasterUsePotionArmor()
		#dampen_harm
		Spell(dampen_harm)
	}
}

AddFunction BrewmasterPrecombatCdPostConditions
{
	not BuffPresent(str_agi_int_buff any=1) and Spell(legacy_of_the_white_tiger) or Spell(stance_of_the_sturdy_ox)
}

### actions.st

AddFunction BrewmasterStMainActions
{
	#blackout_kick,if=buff.shuffle.down
	if BuffExpires(shuffle_buff) Spell(blackout_kick)
	#chi_brew,if=target.health.percent<10&cooldown.touch_of_death.remains=0&chi<=3&chi>=1&(buff.shuffle.remains>=6|target.time_to_die<buff.shuffle.remains)&!glyph.touch_of_death.enabled
	if target.HealthPercent() < 10 and not SpellCooldown(touch_of_death) > 0 and Chi() <= 3 and Chi() >= 1 and { BuffRemaining(shuffle_buff) >= 6 or target.TimeToDie() < BuffRemaining(shuffle_buff) } and not Glyph(glyph_of_touch_of_death) Spell(chi_brew)
	#keg_smash,if=chi.max-chi>=1&!buff.serenity.remains
	if MaxChi() - Chi() >= 1 and not BuffPresent(serenity_buff) Spell(keg_smash)
	#chi_wave,if=(energy+(energy.regen*gcd))<100
	if Energy() + EnergyRegenRate() * GCD() < 100 Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=talent.zen_sphere.enabled&!dot.zen_sphere.ticking&(energy+(energy.regen*gcd))<100
	if Talent(zen_sphere_talent) and not BuffPresent(zen_sphere_buff) and Energy() + EnergyRegenRate() * GCD() < 100 Spell(zen_sphere)
	#chi_explosion,if=chi>=3
	if Chi() >= 3 Spell(chi_explosion_tank)
	#blackout_kick,if=chi>=4
	if Chi() >= 4 Spell(blackout_kick)
	#blackout_kick,if=buff.shuffle.remains<=3&cooldown.keg_smash.remains>=gcd
	if BuffRemaining(shuffle_buff) <= 3 and SpellCooldown(keg_smash) >= GCD() Spell(blackout_kick)
	#blackout_kick,if=buff.serenity.up
	if BuffPresent(serenity_buff) Spell(blackout_kick)
	#expel_harm,if=chi.max-chi>=1&cooldown.keg_smash.remains>=gcd&(energy+(energy.regen*(cooldown.keg_smash.remains)))>=80
	if MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 80 Spell(expel_harm)
	#jab,if=chi.max-chi>=1&cooldown.keg_smash.remains>=gcd&cooldown.expel_harm.remains>=gcd&(energy+(energy.regen*(cooldown.keg_smash.remains)))>=80
	if MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and SpellCooldown(expel_harm) >= GCD() and Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 80 Spell(jab)
	#tiger_palm
	Spell(tiger_palm)
}

AddFunction BrewmasterStShortCdActions
{
	#purifying_brew,if=!talent.chi_explosion.enabled&stagger.heavy
	if not Talent(chi_explosion_talent) and DebuffPresent(heavy_stagger_debuff) Spell(purifying_brew)

	unless BuffExpires(shuffle_buff) and Spell(blackout_kick)
	{
		#purifying_brew,if=buff.serenity.up
		if BuffPresent(serenity_buff) Spell(purifying_brew)
		#purifying_brew,if=!talent.chi_explosion.enabled&stagger.moderate&buff.shuffle.remains>=6
		if not Talent(chi_explosion_talent) and DebuffPresent(moderate_stagger_debuff) and BuffRemaining(shuffle_buff) >= 6 Spell(purifying_brew)
		#guard,if=(charges=1&recharge_time<5)|charges=2|target.time_to_die<15
		if Charges(guard) == 1 and SpellChargeCooldown(guard) < 5 or Charges(guard) == 2 or target.TimeToDie() < 15 Spell(guard)
		#guard,if=incoming_damage_10s>=health.max*0.5
		if IncomingDamage(10) >= MaxHealth() * 0.5 Spell(guard)
		#touch_of_death,if=target.health.percent<10&(buff.shuffle.remains>=6|target.time_to_die<=buff.shuffle.remains)&!glyph.touch_of_death.enabled
		if target.HealthPercent() < 10 and { BuffRemaining(shuffle_buff) >= 6 or target.TimeToDie() <= BuffRemaining(shuffle_buff) } and not Glyph(glyph_of_touch_of_death) Spell(touch_of_death)

		unless MaxChi() - Chi() >= 1 and not BuffPresent(serenity_buff) and Spell(keg_smash)
		{
			#touch_of_death,if=target.health.percent<10&glyph.touch_of_death.enabled
			if target.HealthPercent() < 10 and Glyph(glyph_of_touch_of_death) Spell(touch_of_death)
			#chi_burst,if=(energy+(energy.regen*gcd))<100
			if Energy() + EnergyRegenRate() * GCD() < 100 and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
		}
	}
}

AddFunction BrewmasterStShortCdPostConditions
{
	BuffExpires(shuffle_buff) and Spell(blackout_kick) or MaxChi() - Chi() >= 1 and not BuffPresent(serenity_buff) and Spell(keg_smash) or Energy() + EnergyRegenRate() * GCD() < 100 and Spell(chi_wave) or Talent(zen_sphere_talent) and not BuffPresent(zen_sphere_buff) and Energy() + EnergyRegenRate() * GCD() < 100 and Spell(zen_sphere) or Chi() >= 3 and Spell(chi_explosion_tank) or Chi() >= 4 and Spell(blackout_kick) or BuffRemaining(shuffle_buff) <= 3 and SpellCooldown(keg_smash) >= GCD() and Spell(blackout_kick) or BuffPresent(serenity_buff) and Spell(blackout_kick) or MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 80 and Spell(expel_harm) or MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and SpellCooldown(expel_harm) >= GCD() and Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 80 and Spell(jab) or Spell(tiger_palm)
}

### actions.tod

AddFunction BrewmasterTodMainActions
{
	#chi_brew,if=chi<3&talent.chi_brew.enabled
	if Chi() < 3 and Talent(chi_brew_talent) Spell(chi_brew)
	#keg_smash,if=talent.chi_brew.enabled&chi<3
	if Talent(chi_brew_talent) and Chi() < 3 Spell(keg_smash)
	#expel_harm,if=chi<3&(cooldown.keg_smash.remains>target.time_to_die|((energy+(energy.regen*(cooldown.keg_smash.remains)))>=80)&cooldown.keg_smash.remains>=gcd)
	if Chi() < 3 and { SpellCooldown(keg_smash) > target.TimeToDie() or Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 80 and SpellCooldown(keg_smash) >= GCD() } Spell(expel_harm)
	#jab,if=chi<3&(cooldown.keg_smash.remains>target.time_to_die|((energy+(energy.regen*(cooldown.keg_smash.remains)))>=80)&cooldown.keg_smash.remains>=gcd&cooldown.expel_harm.remains>=gcd)
	if Chi() < 3 and { SpellCooldown(keg_smash) > target.TimeToDie() or Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 80 and SpellCooldown(keg_smash) >= GCD() and SpellCooldown(expel_harm) >= GCD() } Spell(jab)
	#tiger_palm,if=talent.chi_brew.enabled&chi<3
	if Talent(chi_brew_talent) and Chi() < 3 Spell(tiger_palm)
}

AddFunction BrewmasterTodShortCdActions
{
	#touch_of_death
	Spell(touch_of_death)
}

AddFunction BrewmasterTodShortCdPostConditions
{
	Talent(chi_brew_talent) and Chi() < 3 and Spell(keg_smash) or Chi() < 3 and { SpellCooldown(keg_smash) > target.TimeToDie() or Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 80 and SpellCooldown(keg_smash) >= GCD() } and Spell(expel_harm) or Chi() < 3 and { SpellCooldown(keg_smash) > target.TimeToDie() or Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 80 and SpellCooldown(keg_smash) >= GCD() and SpellCooldown(expel_harm) >= GCD() } and Spell(jab) or Talent(chi_brew_talent) and Chi() < 3 and Spell(tiger_palm)
}

### Brewmaster icons.

AddCheckBox(opt_monk_brewmaster_aoe L(AOE) default specialization=brewmaster)

AddIcon checkbox=!opt_monk_brewmaster_aoe enemies=1 help=shortcd specialization=brewmaster
{
	unless not InCombat() and BrewmasterPrecombatShortCdPostConditions()
	{
		BrewmasterDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_monk_brewmaster_aoe help=shortcd specialization=brewmaster
{
	unless not InCombat() and BrewmasterPrecombatShortCdPostConditions()
	{
		BrewmasterDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=brewmaster
{
	if not InCombat() BrewmasterPrecombatMainActions()
	BrewmasterDefaultMainActions()
}

AddIcon checkbox=opt_monk_brewmaster_aoe help=aoe specialization=brewmaster
{
	if not InCombat() BrewmasterPrecombatMainActions()
	BrewmasterDefaultMainActions()
}

AddIcon checkbox=!opt_monk_brewmaster_aoe enemies=1 help=cd specialization=brewmaster
{
	if not InCombat() BrewmasterPrecombatCdActions()
	unless not InCombat() and BrewmasterPrecombatCdPostConditions()
	{
		BrewmasterDefaultCdActions()
	}
}

AddIcon checkbox=opt_monk_brewmaster_aoe help=cd specialization=brewmaster
{
	if not InCombat() BrewmasterPrecombatCdActions()
	unless not InCombat() and BrewmasterPrecombatCdPostConditions()
	{
		BrewmasterDefaultCdActions()
	}
}

### Required symbols
# arcane_torrent_chi
# berserking
# blackout_kick
# blood_fury_apsp
# breath_of_fire
# breath_of_fire_debuff
# chi_brew
# chi_brew_talent
# chi_burst
# chi_explosion_talent
# chi_explosion_tank
# chi_wave
# dampen_harm
# dampen_harm_buff
# diffuse_magic
# diffuse_magic_buff
# draenic_armor_potion
# elusive_brew
# elusive_brew_activated_buff
# elusive_brew_stacks_buff
# expel_harm
# fortifying_brew
# fortifying_brew_buff
# glyph_of_touch_of_death
# guard
# heavy_stagger_debuff
# invoke_xuen
# invoke_xuen_talent
# jab
# keg_smash
# legacy_of_the_white_tiger
# moderate_stagger_debuff
# nimble_brew
# paralysis
# purifying_brew
# quaking_palm
# rushing_jade_wind
# rushing_jade_wind_talent
# serenity
# serenity_buff
# serenity_talent
# shuffle_buff
# spear_hand_strike
# stance_of_the_sturdy_ox
# tiger_palm
# touch_of_death
# war_stomp
# zen_sphere
# zen_sphere_buff
# zen_sphere_talent
]]
	OvaleScripts:RegisterScript("MONK", name, desc, code, "reference")
end
