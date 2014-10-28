local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Monk_Brewmaster_2h_T16M"
	local desc = "[6.0] SimulationCraft: Monk_Brewmaster_2h_T16M"
	local code = [[
# Based on SimulationCraft profile "Monk_Brewmaster_2h_T16M".
#	class=monk
#	spec=brewmaster
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#fa!.00.11.
#	glyphs=fortifying_brew,fortuitous_spheres

Include(ovale_common)
Include(ovale_monk_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)
AddCheckBox(opt_chi_burst SpellName(chi_burst) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction ExpelHarm
{
	Spell(expel_harm)
	Spell(expel_harm_glyphed)
}

AddFunction Guard
{
	Spell(guard)
	Spell(guard_glyphed)
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
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

AddFunction BrewmasterPrecombatActions
{
	#flask,type=earth
	#food,type=mogu_fish_stew
	#stance,choose=sturdy_ox
	Spell(stance_of_the_sturdy_ox)
	#snapshot_stats
	#potion,name=virmens_bite
	UsePotionAgility()
	#dampen_harm
	Spell(dampen_harm)
}

AddFunction BrewmasterDefaultActions
{
	#auto_attack
	#blood_fury,if=energy<=40
	if Energy() <= 40 Spell(blood_fury_apsp)
	#berserking,if=energy<=40
	if Energy() <= 40 Spell(berserking)
	#arcane_torrent,if=energy<=40
	if Energy() <= 40 Spell(arcane_torrent_chi)
	#chi_brew,if=talent.chi_brew.enabled&chi.max-chi>=2&buff.elusive_brew_stacks.stack<=10
	if Talent(chi_brew_talent) and MaxChi() - Chi() >= 2 and BuffStacks(elusive_brew_stacks_buff) <= 10 Spell(chi_brew)
	#gift_of_the_ox,if=buff.gift_of_the_ox.react&incoming_damage_1500ms
	#dampen_harm,if=incoming_damage_1500ms&buff.fortifying_brew.down&buff.elusive_brew_activated.down
	if IncomingDamage(1.5) > 0 and BuffExpires(fortifying_brew_buff) and BuffExpires(elusive_brew_activated_buff) Spell(dampen_harm)
	#fortifying_brew,if=incoming_damage_1500ms&buff.dampen_harm.down&buff.elusive_brew_activated.down
	if IncomingDamage(1.5) > 0 and BuffExpires(dampen_harm_buff) and BuffExpires(elusive_brew_activated_buff) Spell(fortifying_brew)
	#elusive_brew,if=buff.elusive_brew_stacks.react>=9&buff.dampen_harm.down&buff.elusive_brew_activated.down
	if BuffStacks(elusive_brew_stacks_buff) >= 9 and BuffExpires(dampen_harm_buff) and BuffExpires(elusive_brew_activated_buff) Spell(elusive_brew)
	#invoke_xuen,if=talent.invoke_xuen.enabled&time>5
	if Talent(invoke_xuen_talent) and TimeInCombat() > 5 Spell(invoke_xuen)
	#serenity,if=talent.serenity.enabled&energy<=40
	if Talent(serenity_talent) and Energy() <= 40 Spell(serenity)
	#call_action_list,name=st,if=active_enemies<3
	if Enemies() < 3 BrewmasterStActions()
	#call_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 BrewmasterAoeActions()
}

AddFunction BrewmasterAoeActions
{
	#guard
	Guard()
	#breath_of_fire,if=chi>=3&buff.shuffle.remains>=6&dot.breath_of_fire.remains<=1&target.debuff.dizzying_haze.up
	if Chi() >= 3 and BuffRemaining(shuffle_buff) >= 6 and target.DebuffRemaining(breath_of_fire_debuff) <= 1 and target.DebuffPresent(dizzying_haze_debuff) Spell(breath_of_fire)
	#chi_explosion,if=chi>=4
	if Chi() >= 4 Spell(chi_explosion_tank)
	#rushing_jade_wind,if=chi.max-chi>=1&talent.rushing_jade_wind.enabled
	if MaxChi() - Chi() >= 1 and Talent(rushing_jade_wind_talent) Spell(rushing_jade_wind)
	#purifying_brew,if=!talent.chi_explosion.enabled&stagger.heavy
	if not Talent(chi_explosion_talent) and DebuffPresent(heavy_stagger_debuff) Spell(purifying_brew)
	#guard
	Guard()
	#keg_smash,if=chi.max-chi>=2&!buff.serenity.remains
	if MaxChi() - Chi() >= 2 and not BuffRemaining(serenity_buff) Spell(keg_smash)
	#chi_burst,if=talent.chi_burst.enabled&energy.time_to_max>3
	if Talent(chi_burst_talent) and TimeToMaxEnergy() > 3 and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
	#chi_wave,if=talent.chi_wave.enabled&energy.time_to_max>3
	if Talent(chi_wave_talent) and TimeToMaxEnergy() > 3 Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=talent.zen_sphere.enabled&!dot.zen_sphere.ticking
	if Talent(zen_sphere_talent) and not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#blackout_kick,if=talent.rushing_jade_wind.enabled&buff.shuffle.remains<=3&cooldown.keg_smash.remains>=gcd
	if Talent(rushing_jade_wind_talent) and BuffRemaining(shuffle_buff) <= 3 and SpellCooldown(keg_smash) >= GCD() Spell(blackout_kick)
	#blackout_kick,if=talent.rushing_jade_wind.enabled&buff.serenity.up
	if Talent(rushing_jade_wind_talent) and BuffPresent(serenity_buff) Spell(blackout_kick)
	#blackout_kick,if=talent.rushing_jade_wind.enabled&chi>=4
	if Talent(rushing_jade_wind_talent) and Chi() >= 4 Spell(blackout_kick)
	#expel_harm,if=chi.max-chi>=1&cooldown.keg_smash.remains>=gcd&(energy+(energy.regen*(cooldown.keg_smash.remains)))>=40
	if MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 40 ExpelHarm()
	#spinning_crane_kick,if=chi.max-chi>=1&!talent.rushing_jade_wind.enabled
	if MaxChi() - Chi() >= 1 and not Talent(rushing_jade_wind_talent) Spell(spinning_crane_kick)
	#jab,if=talent.rushing_jade_wind.enabled&chi.max-chi>=1&cooldown.keg_smash.remains>=gcd&cooldown.expel_harm.remains>=gcd
	if Talent(rushing_jade_wind_talent) and MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and SpellCooldown(expel_harm) >= GCD() Spell(jab)
	#purifying_brew,if=!talent.chi_explosion.enabled&talent.rushing_jade_wind.enabled&stagger.moderate&buff.shuffle.remains>=6
	if not Talent(chi_explosion_talent) and Talent(rushing_jade_wind_talent) and DebuffPresent(moderate_stagger_debuff) and BuffRemaining(shuffle_buff) >= 6 Spell(purifying_brew)
	#tiger_palm,if=talent.rushing_jade_wind.enabled&(energy+(energy.regen*(cooldown.keg_smash.remains)))>=40
	if Talent(rushing_jade_wind_talent) and Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 40 Spell(tiger_palm)
	#tiger_palm,if=talent.rushing_jade_wind.enabled&cooldown.keg_smash.remains>=gcd
	if Talent(rushing_jade_wind_talent) and SpellCooldown(keg_smash) >= GCD() Spell(tiger_palm)
}

AddFunction BrewmasterStActions
{
	#blackout_kick,if=buff.shuffle.down
	if BuffExpires(shuffle_buff) Spell(blackout_kick)
	#purifying_brew,if=!talent.chi_explosion.enabled&stagger.heavy
	if not Talent(chi_explosion_talent) and DebuffPresent(heavy_stagger_debuff) Spell(purifying_brew)
	#purifying_brew,if=!buff.serenity.up
	if not BuffPresent(serenity_buff) Spell(purifying_brew)
	#guard
	Guard()
	#keg_smash,if=chi.max-chi>=2&!buff.serenity.remains
	if MaxChi() - Chi() >= 2 and not BuffRemaining(serenity_buff) Spell(keg_smash)
	#chi_burst,if=talent.chi_burst.enabled&energy.time_to_max>3
	if Talent(chi_burst_talent) and TimeToMaxEnergy() > 3 and CheckBoxOn(opt_chi_burst) Spell(chi_burst)
	#chi_wave,if=talent.chi_wave.enabled&energy.time_to_max>3
	if Talent(chi_wave_talent) and TimeToMaxEnergy() > 3 Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=talent.zen_sphere.enabled&!dot.zen_sphere.ticking
	if Talent(zen_sphere_talent) and not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#chi_explosion,if=chi>=3
	if Chi() >= 3 Spell(chi_explosion_tank)
	#blackout_kick,if=buff.shuffle.remains<=3&cooldown.keg_smash.remains>=gcd
	if BuffRemaining(shuffle_buff) <= 3 and SpellCooldown(keg_smash) >= GCD() Spell(blackout_kick)
	#blackout_kick,if=buff.serenity.up
	if BuffPresent(serenity_buff) Spell(blackout_kick)
	#blackout_kick,if=chi>=4
	if Chi() >= 4 Spell(blackout_kick)
	#expel_harm,if=chi.max-chi>=1&cooldown.keg_smash.remains>=gcd
	if MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() ExpelHarm()
	#jab,if=chi.max-chi>=1&cooldown.keg_smash.remains>=gcd&cooldown.expel_harm.remains>=gcd
	if MaxChi() - Chi() >= 1 and SpellCooldown(keg_smash) >= GCD() and SpellCooldown(expel_harm) >= GCD() Spell(jab)
	#purifying_brew,if=!talent.chi_explosion.enabled&stagger.moderate&buff.shuffle.remains>=6
	if not Talent(chi_explosion_talent) and DebuffPresent(moderate_stagger_debuff) and BuffRemaining(shuffle_buff) >= 6 Spell(purifying_brew)
	#tiger_palm,if=(energy+(energy.regen*(cooldown.keg_smash.remains)))>=40
	if Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) >= 40 Spell(tiger_palm)
	#tiger_palm,if=cooldown.keg_smash.remains>=gcd
	if SpellCooldown(keg_smash) >= GCD() Spell(tiger_palm)
}

AddIcon specialization=brewmaster help=main enemies=1
{
	if not InCombat() BrewmasterPrecombatActions()
	BrewmasterDefaultActions()
}

AddIcon specialization=brewmaster help=aoe
{
	if not InCombat() BrewmasterPrecombatActions()
	BrewmasterDefaultActions()
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
# chi_burst_talent
# chi_explosion_talent
# chi_explosion_tank
# chi_wave
# chi_wave_talent
# dampen_harm
# dampen_harm_buff
# dizzying_haze_debuff
# elusive_brew
# elusive_brew_activated_buff
# elusive_brew_stacks_buff
# expel_harm
# expel_harm_glyphed
# fortifying_brew
# fortifying_brew_buff
# glyph_of_guard
# glyph_of_targeted_expulsion
# guard
# guard_glyphed
# heavy_stagger_debuff
# invoke_xuen
# invoke_xuen_talent
# jab
# keg_smash
# moderate_stagger_debuff
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
# spinning_crane_kick
# stance_of_the_sturdy_ox
# tiger_palm
# virmens_bite_potion
# war_stomp
# zen_sphere
# zen_sphere_buff
# zen_sphere_talent
]]
	OvaleScripts:RegisterScript("MONK", name, desc, code, "reference")
end
