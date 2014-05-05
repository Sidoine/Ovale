local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.4] Ovale: Brewmaster, Mistweaver, Windwalker"
	local code = [[
# Ovale monk script based on SimulationCraft.

Include(ovale_items)
Include(ovale_racials)
Include(ovale_monk_spells)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

###
### Brewmaster
###
# Rotation from Elitist Jerks, "Like Water - The Brewmaster's Resource"
#	http://forums.elitistjerks.com/page/articles.html/_/world-of-warcraft/monk/like-water-the-brewmasters-resource-r83

AddFunction StaggerDamageRemaining
{
	if DebuffPresent(light_stagger_debuff)		{ TicksRemain(light_stagger_debuff)    * TickValue(light_stagger_debuff) }
	if DebuffPresent(moderate_stagger_debuff)	{ TicksRemain(moderate_stagger_debuff) * TickValue(moderate_stagger_debuff) }
	if DebuffPresent(heavy_stagger_debuff)		{ TicksRemain(heavy_stagger_debuff)    * TickValue(heavy_stagger_debuff) }
}

AddFunction StaggerTickDamage
{
	if DebuffPresent(light_stagger_debuff)		TickValue(light_stagger_debuff)
	if DebuffPresent(moderate_stagger_debuff)	TickValue(moderate_stagger_debuff)
	if DebuffPresent(heavy_stagger_debuff)		TickValue(heavy_stagger_debuff)
}

AddFunction BrewmasterFillerActions
{
	if TalentPoints(chi_wave_talent) Spell(chi_wave)
	if TalentPoints(zen_sphere_talent) and BuffExpires(zen_sphere_buff) Spell(zen_sphere)
	Spell(tiger_palm)
}

AddFunction BrewmasterDefaultActions
{
	if BuffRemains(shuffle_buff) <= 3 Spell(blackout_kick)
	if MaxChi() - Chi() >= 2 Spell(keg_smash)
	if MaxChi() - Chi() >= 1 and HealthPercent() < 35
	{
		if Glyph(glyph_of_targeted_expulsion) Spell(expel_harm_glyphed)
		if Glyph(glyph_of_targeted_expulsion no) Spell(expel_harm)
	}
	if BuffExpires(power_guard_buff)
	{
		if Glyph(glyph_of_guard) and BuffRemains(guard_glyphed_buff) <= 2 and SpellCooldown(guard_glyphed) < GCD() Spell(tiger_palm)
		if Glyph(glyph_of_guard no) and BuffRemains(guard_buff) <= 2 and SpellCooldown(guard) < GCD() Spell(tiger_palm)
	}
	if BuffExpires(tiger_power_buff) Spell(tiger_palm)
}

AddFunction BrewmasterSingleTargetActions
{
	if Chi() == MaxChi()
	{
		Spell(blackout_kick)
	}
	if TimeToMaxEnergy() < 2 and Energy() - 40 + SpellCooldown(keg_smash) * EnergyRegen() > 40
	{
		if SpellCooldown(keg_smash) > GCD()
		{
			# Only Jab or Expel Harm if we'll have enough energy to Keg Smash when it comes off cooldown.
			if HealthPercent() < 80
			{
				if Glyph(glyph_of_targeted_expulsion) Spell(expel_harm_glyphed)
				if Glyph(glyph_of_targeted_expulsion no) Spell(expel_harm)
			}
			Spell(jab)
		}
	}
	if MaxChi() - Chi() < 2
	{
		Spell(blackout_kick)
	}
}

AddFunction BrewmasterAoeActions
{
	if Chi() == MaxChi()
	{
		if BuffRemains(shuffle_buff) > 6 Spell(breath_of_fire)
		Spell(blackout_kick)
	}
	if TimeToMaxEnergy() < 2 and Energy() - 40 + SpellCooldown(keg_smash) * EnergyRegen() > 40
	{
		# Only SCK/RJW if we'll have enough energy to Keg Smash when it comes off cooldown.
		if TalentPoints(rushing_jade_wind_talent) and SpellCooldown(keg_smash) > GCD()
		{
			Spell(rushing_jade_wind)
		}
		if not TalentPoints(rushing_jade_wind_talent) and SpellCooldown(keg_smash) > 2
		{
			# The channel time of SCK is 2s, so only SCK if Keg Smash is on CD for at least 2s.
			Spell(spinning_crane_kick)
		}
	}
	if MaxChi() - Chi() < 2
	{
		if BuffRemains(shuffle_buff) > 6 Spell(breath_of_fire)
		Spell(blackout_kick)
	}
}

AddFunction BrewmasterShortCdActions
{
	# Cast Purifying Brew only if Heavy Stagger (urgent!) or if Shuffle uptime won't suffer.
	# Avoid Purifying while Elusive Brew is up unless under Heavy Stagger.
	if DebuffPresent(heavy_stagger_debuff) or { BuffExpires(elusive_brew_buff) and { BuffRemains(shuffle_buff) > 6 or Chi() > 2 } }
	{
		# Purify Stagger if it ticks for more than half of my remaining health (urgent!).
		if StaggerTickDamage() / Health() > 0.5 Spell(purifying_brew)
		# Purify Stagger > 40% of my health.
		if StaggerDamageRemaining() / MaxHealth() > 0.40 Spell(purifying_brew)
		# Purify Medium Stagger if below 70% health.
		if DebuffPresent(moderate_stagger_debuff) and HealthPercent() < 70 Spell(purifying_brew)
	}
	if BuffPresent(purifier_buff) and DebuffPresent(stagger_debuff) Spell(purifying_brew)
	if ArmorSetParts(T15_tank) < 2 and BuffStacks(elusive_brew_buff) > 10 Spell(elusive_brew_use)
	if ArmorSetParts(T15_tank) >= 2 and BuffStacks(elusive_brew_buff) > 5
	{
		if BuffRemains(staggering_buff) < BuffStacks(elusive_brew_buff) Spell(elusive_brew_use)
	}
	if BuffPresent(power_guard_buff)
	{
		if Glyph(glyph_of_guard) and BuffExpires(guard_glyphed_buff) Spell(guard_glyphed)
		if Glyph(glyph_of_guard no) and BuffExpires(guard_buff) Spell(guard)
	}
}

AddFunction BrewmasterCdActions
{
	if TalentPoints(chi_burst_talent) Spell(chi_burst)
	unless { target.Health() < Health() and BuffPresent(death_note_buff) Spell(touch_of_death) }
		or { TalentPoints(chi_burst_talent) and Spell(chi_burst) }
	{
		if TalentPoints(invoke_xuen_talent) Spell(invoke_xuen)
	}
}

AddFunction BrewmasterPrecombatActions
{
	if BuffExpires(str_agi_int any=1) Spell(legacy_of_the_emperor)
	if not Stance(monk_stance_of_the_sturdy_ox) Spell(stance_of_the_sturdy_ox)
	if DebuffPresent(light_stagger_debuff) or DebuffPresent(moderate_stagger_debuff) or DebuffPresent(heavy_stagger_debuff) Spell(purifying_brew)
}

### Brewmaster icons.

AddIcon mastery=brewmaster size=small checkboxon=opt_icons_left
{
	if TalentPoints(dampen_harm_talent) Spell(dampen_harm)
	if TalentPoints(diffuse_magic_talent) Spell(diffuse_magic)
}

AddIcon mastery=brewmaster size=small checkboxon=opt_icons_left
{
	Spell(fortifying_brew)
	Spell(symbiosis_survival_instincts)
	UseRacialSurvivalActions()
}

AddIcon mastery=brewmaster help=cd
{
	BrewmasterShortCdActions()
}

AddIcon mastery=brewmaster help=main
{
	if InCombat(no) BrewmasterPrecombatActions()
	BrewmasterDefaultActions()
	BrewmasterSingleTargetActions()
	BrewmasterFillerActions()
}

AddIcon mastery=brewmaster help=aoe checkboxon=opt_aoe
{
	if InCombat(no) BrewmasterPrecombatActions()
	BrewmasterDefaultActions()
	BrewmasterAoeActions()
	BrewmasterFillerActions()
}

AddIcon mastery=brewmaster help=cd
{
	if IsFeared() or IsRooted() or IsStunned() Spell(nimble_brew)
	if target.Health() < Health() and BuffPresent(death_note_buff) Spell(touch_of_death)
	Interrupt()

	BrewmasterCdActions()
}

AddIcon mastery=brewmaster size=small checkboxon=opt_icons_right
{
	if TotemExpires(statue) or BuffExpires(sanctuary_of_the_ox_buff) Spell(summon_black_ox_statue)
}

AddIcon mastery=brewmaster size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

###
### Mistweaver
###

AddCheckBox(opt_mistweaver_pool_chi "Pool Chi >= 2" mastery=mistweaver)
AddFunction MistweaverChiPool
{
	if CheckBoxOn(opt_mistweaver_pool_chi) 2
	0
}

AddFunction ManaTea
{
	if Glyph(glyph_of_mana_tea) Spell(mana_tea_glyphed)
	if not Glyph(glyph_of_mana_tea) Spell(mana_tea)
}

AddFunction MistweaverAoeActions
{
	#rushing_jade_wind,if=talent.rushing_jade_wind.enabled
	if TalentPoints(rushing_jade_wind_talent) Spell(rushing_jade_wind)
	#zen_sphere,cycle_targets=1,if=talent.zen_sphere.enabled&!dot.zen_sphere.ticking
	if TalentPoints(zen_sphere_talent) and BuffCountOnAny(zen_sphere_buff) < 1 Spell(zen_sphere)
	#chi_burst,if=talent.chi_burst.enabled
	if TalentPoints(chi_burst_talent) Spell(chi_burst)
	#tiger_palm,if=buff.muscle_memory.up&!buff.tiger_power.up
	if BuffPresent(muscle_memory_buff) and BuffExpires(tiger_power_buff) Spell(tiger_palm)
	#blackout_kick,if=buff.muscle_memory.up&buff.tiger_power.up&chi>1
	if BuffPresent(muscle_memory_buff) and BuffPresent(tiger_power_buff) and Chi() > MistweaverChiPool() + 1 Spell(blackout_kick)
	#spinning_crane_kick,if=!talent.rushing_jade_wind.enabled
	if not TalentPoints(rushing_jade_wind_talent) Spell(spinning_crane_kick)
	#jab,if=talent.rushing_jade_wind.enabled
	if Glyph(glyph_of_targeted_expulsion) Spell(expel_harm_glyphed)
	if Glyph(glyph_of_targeted_expulsion no) Spell(expel_harm)
	if TalentPoints(rushing_jade_wind_talent) Spell(jab)
}

AddFunction MistweaverSingleTargetActions
{
	#crackling_jade_lightning,if=buff.bloodlust.up&buff.lucidity.up
	if BuffPresent(burst_haste any=1) and BuffPresent(lucidity_monk_buff) Spell(crackling_jade_lightning)
	#tiger_palm,if=buff.muscle_memory.up&buff.lucidity.up
	if BuffPresent(lucidity_monk_buff) and BuffPresent(muscle_memory_buff) Spell(tiger_palm)
	#jab,if=buff.lucidity.up
	if BuffPresent(lucidity_monk_buff) Spell(jab)
	#tiger_palm,if=buff.muscle_memory.up&!buff.tiger_power.up
	if BuffPresent(muscle_memory_buff) and BuffExpires(tiger_power_buff) Spell(tiger_palm)
	#blackout_kick,if=buff.muscle_memory.up&buff.tiger_power.up&chi>1
	if BuffPresent(muscle_memory_buff) and BuffPresent(tiger_power_buff) and Chi() > MistweaverChiPool() + 1 Spell(blackout_kick)
	#tiger_palm,if=buff.muscle_memory.up&buff.tiger_power.up
	if BuffPresent(muscle_memory_buff) and BuffPresent(tiger_power_buff) and Chi() > MistweaverChiPool() Spell(tiger_palm)
	#chi_wave,if=talent.chi_wave.enabled
	if TalentPoints(chi_wave_talent) Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=talent.zen_sphere.enabled&!dot.zen_sphere.ticking
	if TalentPoints(zen_sphere_talent) and BuffCountOnAny(zen_sphere_buff) < 1 Spell(zen_sphere)
	#jab
	if Glyph(glyph_of_targeted_expulsion) Spell(expel_harm_glyphed)
	if Glyph(glyph_of_targeted_expulsion no) Spell(expel_harm)
	Spell(jab)
}

AddFunction MistweaverDefaultCdActions
{
	#chi_brew,if=talent.chi_brew.enabled&chi=0
	if TalentPoints(chi_brew_talent) and Chi() == 0 Spell(chi_brew)
	#mana_tea,if=buff.mana_tea.react>=2&mana.pct<=25
	if BuffStacks(mana_tea_buff) >= 2 and ManaPercent() <= 25 ManaTea()
	#jade_serpent_potion,if=buff.bloodlust.react|target.time_to_die<=60
	if BuffPresent(burst_haste any=1) and target.TimeToDie() <= 60 UsePotionIntellect()
	#use_item
	Item(HandsSlot usable=1)
	#invoke_xuen,if=talent.invoke_xuen.enabled
	if TalentPoints(invoke_xuen_talent) Spell(invoke_xuen)
}

AddFunction MistweaverPrecombatActions
{
	if BuffExpires(str_agi_int any=1) Spell(legacy_of_the_emperor)
}

### Mistweaver icons.

AddIcon mastery=mistweaver size=small checkboxon=opt_icons_right
{
	if TotemExpires(statue) Spell(summon_jade_serpent_statue)
}

AddIcon mastery=mistweaver size=small checkboxon=opt_icons_left
{
	if BuffCountOnAny(renewing_mist_buff) > 5 Spell(thunder_focus_tea)
	Spell(revival)
}

AddIcon mastery=mistweaver help=shortcd
{
	unless Stance(monk_stance_of_the_wise_serpent) Spell(stance_of_the_wise_serpent)

	if BuffStacks(vital_mists_buff) == 5
	{
		if Glyph(glyph_of_surging_mist) Spell(surging_mist_glyphed)
		if Glyph(glyph_of_surging_mist no) Spell(surging_mist)
	}
	Spell(renewing_mist)
	if TalentPoints(chi_burst_talent) Spell(chi_burst)
	if TalentPoints(zen_sphere_talent) and BuffCountOnAny(zen_sphere_buff) < 1 Spell(zen_sphere)
}

AddIcon mastery=mistweaver help=main
{
	if InCombat(no) MistweaverPrecombatActions()
	MistweaverSingleTargetActions()
}

AddIcon mastery=mistweaver help=aoe checkboxon=opt_aoe
{
	if InCombat(no) MistweaverPrecombatActions()
	MistweaverAoeActions()
}

AddIcon mastery=mistweaver help=cd
{
	if IsFeared() or IsRooted() or IsStunned() Spell(nimble_brew)
	if target.Health() < Health() and BuffPresent(death_note) Spell(touch_of_death)
	Interrupt()

	if Spell(thunder_focus_tea) and Chi() >=3 Spell(uplift)
	if not Spell(thunder_focus_tea) and Chi() >=2 Spell(uplift)

	MistweaverDefaultCdActions()
}

AddIcon mastery=mistweaver help=mana size=small checkboxon=opt_icons_left
{
	if ManaPercent() < 100
	{
		if BuffStacks(mana_tea_buff) == 20 or ManaPercent() < 75 or ManaPercent() < 100 - BuffStacks(mana_tea_buff) * 4 ManaTea()
	}
}

AddIcon mastery=mistweaver size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

###
### Windwalker
###
# Based on SimulationCraft profile "Monk_Windwalker_1h_T16H".
#	class=monk
#	spec=windwalker
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#fb!002221

AddFunction WindwalkerAoeActions
{
	#rushing_jade_wind,if=talent.rushing_jade_wind.enabled
	if TalentPoints(rushing_jade_wind_talent) Spell(rushing_jade_wind)
	#zen_sphere,cycle_targets=1,if=talent.zen_sphere.enabled&!dot.zen_sphere.ticking
	if TalentPoints(zen_sphere_talent) and not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#chi_wave,if=talent.chi_wave.enabled
	if TalentPoints(chi_wave_talent) Spell(chi_wave)
	#chi_burst,if=talent.chi_burst.enabled
	if TalentPoints(chi_burst_talent) Spell(chi_burst)
	#rising_sun_kick,if=chi=chi.max
	if Chi() == MaxChi() Spell(rising_sun_kick)
	#spinning_crane_kick,if=!talent.rushing_jade_wind.enabled
	if not TalentPoints(rushing_jade_wind_talent) Spell(spinning_crane_kick)
}

AddFunction WindwalkerSingleTargetActions
{
	#rising_sun_kick
	Spell(rising_sun_kick)
	#chi_wave,if=talent.chi_wave.enabled&energy.time_to_max>2
	if TalentPoints(chi_wave_talent) and TimeToMaxEnergy() > 2 Spell(chi_wave)
	#zen_sphere,cycle_targets=1,if=talent.zen_sphere.enabled&energy.time_to_max>2&!dot.zen_sphere.ticking
	if TalentPoints(zen_sphere_talent) and TimeToMaxEnergy() > 2 and not BuffPresent(zen_sphere_buff) Spell(zen_sphere)
	#blackout_kick,if=buff.combo_breaker_bok.react
	if BuffPresent(combo_breaker_bok_buff) Spell(blackout_kick)
	#tiger_palm,if=buff.combo_breaker_tp.react&(buff.combo_breaker_tp.remains<=2|energy.time_to_max>=2)
	if BuffPresent(combo_breaker_tp_buff) and { BuffRemains(combo_breaker_tp_buff) <= 2 or TimeToMaxEnergy() >= 2 } Spell(tiger_palm)
	#jab,if=chi.max-chi>=2
	if MaxChi() - Chi() >= 2 Spell(jab)
	#blackout_kick,if=energy+energy.regen*cooldown.rising_sun_kick.remains>=40
	if Energy() + EnergyRegen() * SpellCooldown(rising_sun_kick) >= 40 Spell(blackout_kick)
}

AddFunction WindwalkerSingleTargetShortCdActions
{
	unless Spell(rising_sun_kick)
	{
		#fists_of_fury,if=buff.energizing_brew.down&energy.time_to_max>4&buff.tiger_power.remains>4
		if BuffExpires(energizing_brew_buff) and TimeToMaxEnergy() > 4 and BuffRemains(tiger_power_buff) > 4 Spell(fists_of_fury)
		#chi_burst,if=talent.chi_burst.enabled&energy.time_to_max>2
		if TalentPoints(chi_burst_talent) and TimeToMaxEnergy() > 2 Spell(chi_burst)
	}
}

AddFunction WindwalkerDefaultActions
{
	#auto_attack
	#chi_sphere,if=talent.power_strikes.enabled&buff.chi_sphere.react&chi<4
	#chi_brew,if=talent.chi_brew.enabled&chi<=2&(trinket.proc.agility.react|(charges=1&recharge_time<=10)|charges=2|target.time_to_die<charges*10)
	if TalentPoints(chi_brew_talent) and Chi() <= 2 and { BuffPresent(trinket_proc_agility_buff) or { Charges(chi_brew) == 1 and SpellChargeCooldown(chi_brew) <= 10 } or Charges(chi_brew) == 2 or target.TimeToDie() < Charges(chi_brew) * 10 } Spell(chi_brew)
	#tiger_palm,if=buff.tiger_power.remains<=3
	if BuffRemains(tiger_power_buff) <= 3 Spell(tiger_palm)
	#energizing_brew,if=energy.time_to_max>5
	if TimeToMaxEnergy() > 5 Spell(energizing_brew)
	#rising_sun_kick,if=debuff.rising_sun_kick.down
	if target.DebuffExpires(rising_sun_kick_debuff) Spell(rising_sun_kick)
	#tiger_palm,if=buff.tiger_power.down&debuff.rising_sun_kick.remains>1&energy.time_to_max>1
	if BuffExpires(tiger_power_buff) and target.DebuffRemains(rising_sun_kick_debuff) > 1 and TimeToMaxEnergy() > 1 Spell(tiger_palm)
	#run_action_list,name=aoe,if=active_enemies>=3
	#if Enemies() >= 3 WindwalkerAoeActions()
	#run_action_list,name=single_target,if=active_enemies<3
	#if Enemies() < 3 WindwalkerSingleTargetActions()
}

AddFunction WindwalkerDefaultShortCdActions
{
	unless { BuffRemains(tiger_power_buff) <= 3 and Spell(tiger_palm) }
	{
		#tigereye_brew,if=buff.tigereye_brew_use.down&buff.tigereye_brew.stack=20
		if BuffExpires(tigereye_brew_use_buff) and BuffStacks(tigereye_brew_buff) == 20 Spell(tigereye_brew)
		#tigereye_brew,if=buff.tigereye_brew_use.down&trinket.proc.agility.react
		if BuffExpires(tigereye_brew_use_buff) and BuffPresent(trinket_proc_agility_buff) Spell(tigereye_brew)
		#tigereye_brew,if=buff.tigereye_brew_use.down&chi>=2&(trinket.proc.agility.react|trinket.proc.strength.react|buff.tigereye_brew.stack>=15|target.time_to_die<40)&debuff.rising_sun_kick.up&buff.tiger_power.up
		if BuffExpires(tigereye_brew_use_buff) and Chi() >= 2 and { BuffPresent(trinket_proc_agility_buff) or BuffPresent(trinket_proc_strength_buff) or BuffStacks(tigereye_brew_buff) >= 15 or target.TimeToDie() < 40 } and target.DebuffPresent(rising_sun_kick_debuff) and BuffPresent(tiger_power_buff) Spell(tigereye_brew)
	}
}

AddFunction WindwalkerDefaultCdActions
{
	#virmens_bite_potion,if=buff.bloodlust.react|target.time_to_die<=60
	if BuffPresent(burst_haste any=1) or target.TimeToDie() <= 60 UsePotionAgility()
	#use_item,name=gloves_of_the_golden_protector
	UseItemActions()
	#berserking
	UseRacialActions()
	unless { BuffRemains(tiger_power_buff) <= 3 and Spell(tiger_palm) }
		or { target.DebuffExpires(rising_sun_kick_debuff) and Spell(rising_sun_kick) }
		or { BuffExpires(tiger_power_buff) and target.DebuffRemains(rising_sun_kick_debuff) > 1 and TimeToMaxEnergy() > 1 and Spell(tiger_palm) }
	{
		#invoke_xuen,if=talent.invoke_xuen.enabled
		if TalentPoints(invoke_xuen_talent) Spell(invoke_xuen)
	}
}

AddFunction WindwalkerPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#stance,choose=fierce_tiger
	if not Stance(monk_stance_of_the_fierce_tiger) Spell(stance_of_the_fierce_tiger)
	#snapshot_stats
}

AddFunction WindwalkerPrecombatCdActions
{
	#virmens_bite_potion
	UsePotionAgility()
}

### Windwalker icons.

AddIcon mastery=windwalker size=small checkboxon=opt_icons_left
{
	if TalentPoints(dampen_harm_talent) Spell(dampen_harm)
	if TalentPoints(diffuse_magic_talent) Spell(diffuse_magic)
}

AddIcon mastery=windwalker size=small checkboxon=opt_icons_left
{
	if TalentPoints(chi_burst_talent) Spell(chi_burst)
	if TalentPoints(chi_wave_talent) Spell(chi_wave)
	if TalentPoints(zen_sphere_talent) and BuffExpires(zen_sphere_buff) Spell(zen_sphere)
}

AddIcon mastery=windwalker help=shortcd
{
	WindwalkerDefaultShortCdActions()
	WindwalkerSingleTargetShortCdActions()
}

AddIcon mastery=windwalker help=main
{
	if InCombat(no) WindwalkerPrecombatActions()
	WindwalkerDefaultActions()
	WindwalkerSingleTargetActions()
}

AddIcon mastery=windwalker help=aoe checkboxon=opt_aoe
{
	if InCombat(no) WindwalkerPrecombatActions()
	WindwalkerDefaultActions()
	WindwalkerAoeActions()
}

AddIcon mastery=windwalker help=cd
{
	if InCombat(no) WindwalkerPrecombatCdActions()

	if IsFeared() or IsRooted() or IsStunned() Spell(nimble_brew)
	if target.Health() < Health() and BuffPresent(death_note_buff) Spell(touch_of_death)
	Interrupt()
	UseRacialInterruptActions()

	WindwalkerDefaultCdActions()
}

AddIcon mastery=windwalker size=small checkboxon=opt_icons_right
{
	Spell(zen_meditation)
}

AddIcon mastery=windwalker size=small checkboxon=opt_icons_right
{
	UseItemActions()
}
]]

	OvaleScripts:RegisterScript("MONK", name, desc, code)
end
