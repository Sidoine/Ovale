local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_rogue_assassination_t18m"
	local desc = "[6.2] SimulationCraft: Rogue_Assassination_T18M"
	local code = [[
# Based on SimulationCraft profile "Rogue_Assassination_T18M".
#	class=rogue
#	spec=assassination
#	talents=3000032
#	glyphs=vendetta/energy/disappearance

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=assassination)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=assassination)
AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default specialization=assassination)
AddCheckBox(opt_vanish SpellName(vanish) default specialization=assassination)

AddFunction AssassinationUsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction AssassinationUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction AssassinationGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(kick)
	{
		Spell(shadowstep)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction AssassinationInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(kick) Spell(kick)
		if not target.Classification(worldboss)
		{
			if target.InRange(cheap_shot) Spell(cheap_shot)
			if target.InRange(deadly_throw) and ComboPoints() == 5 Spell(deadly_throw)
			if target.InRange(kidney_shot) Spell(kidney_shot)
			Spell(arcane_torrent_energy)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

### actions.default

AddFunction AssassinationDefaultMainActions
{
	#mutilate,if=buff.stealth.up|buff.vanish.up
	if BuffPresent(stealthed_buff any=1) or BuffPresent(vanish_buff) Spell(mutilate)
	#rupture,if=((combo_points>=4&!talent.anticipation.enabled)|combo_points=5)&ticks_remain<3
	if { ComboPoints() >= 4 and not Talent(anticipation_talent) or ComboPoints() == 5 } and target.TicksRemaining(rupture_debuff) < 3 Spell(rupture)
	#rupture,cycle_targets=1,if=spell_targets.fan_of_knives>1&!ticking&combo_points=5
	if Enemies() > 1 and not target.DebuffPresent(rupture_debuff) and ComboPoints() == 5 Spell(rupture)
	#rupture,cycle_targets=1,if=combo_points=5&remains<=duration*0.3&spell_targets.fan_of_knives>1
	if ComboPoints() == 5 and target.DebuffRemaining(rupture_debuff) <= BaseDuration(rupture_debuff) * 0.3 and Enemies() > 1 Spell(rupture)
	#call_action_list,name=finishers,if=combo_points=5&((!cooldown.death_from_above.remains&talent.death_from_above.enabled)|buff.envenom.down|!talent.anticipation.enabled|anticipation_charges+combo_points>=6)
	if ComboPoints() == 5 and { not SpellCooldown(death_from_above) > 0 and Talent(death_from_above_talent) or BuffExpires(envenom_buff) or not Talent(anticipation_talent) or BuffStacks(anticipation_buff) + ComboPoints() >= 6 } AssassinationFinishersMainActions()
	#call_action_list,name=finishers,if=dot.rupture.remains<2
	if target.DebuffRemaining(rupture_debuff) < 2 AssassinationFinishersMainActions()
	#call_action_list,name=generators
	AssassinationGeneratorsMainActions()
}

AddFunction AssassinationDefaultShortCdActions
{
	#vanish,if=time>10&energy>13&!buff.stealth.up&buff.blindside.down&energy.time_to_max>gcd*2&((combo_points+anticipation_charges<8)|(!talent.anticipation.enabled&combo_points<=1))
	if TimeInCombat() > 10 and Energy() > 13 and not BuffPresent(stealthed_buff any=1) and BuffExpires(blindside_buff) and TimeToMaxEnergy() > GCD() * 2 and { ComboPoints() + BuffStacks(anticipation_buff) < 8 or not Talent(anticipation_talent) and ComboPoints() <= 1 } and { CheckBoxOn(opt_vanish) or not SpellCooldown(preparation) > 0 } Spell(vanish)

	unless { BuffPresent(stealthed_buff any=1) or BuffPresent(vanish_buff) } and Spell(mutilate)
	{
		#auto_attack
		AssassinationGetInMeleeRange()

		unless { ComboPoints() >= 4 and not Talent(anticipation_talent) or ComboPoints() == 5 } and target.TicksRemaining(rupture_debuff) < 3 and Spell(rupture) or Enemies() > 1 and not target.DebuffPresent(rupture_debuff) and ComboPoints() == 5 and Spell(rupture)
		{
			#marked_for_death,if=combo_points=0
			if ComboPoints() == 0 Spell(marked_for_death)
		}
	}
}

AddFunction AssassinationDefaultCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40|debuff.vendetta.up
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 or target.DebuffPresent(vendetta_debuff) AssassinationUsePotionAgility()
	#kick
	AssassinationInterruptActions()
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60&time>10
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 and TimeInCombat() > 10 Spell(preparation)
	#use_item,slot=finger1,if=spell_targets.fan_of_knives>1|(debuff.vendetta.up&spell_targets.fan_of_knives=1)
	if Enemies() > 1 or target.DebuffPresent(vendetta_debuff) and Enemies() == 1 AssassinationUseItemActions()
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)

	unless { BuffPresent(stealthed_buff any=1) or BuffPresent(vanish_buff) } and Spell(mutilate) or { ComboPoints() >= 4 and not Talent(anticipation_talent) or ComboPoints() == 5 } and target.TicksRemaining(rupture_debuff) < 3 and Spell(rupture) or Enemies() > 1 and not target.DebuffPresent(rupture_debuff) and ComboPoints() == 5 and Spell(rupture)
	{
		#shadow_reflection,if=combo_points>4|target.time_to_die<=20
		if ComboPoints() > 4 or target.TimeToDie() <= 20 Spell(shadow_reflection)
		#vendetta,if=buff.shadow_reflection.up|!talent.shadow_reflection.enabled|target.time_to_die<=20|(target.time_to_die<=30&glyph.vendetta.enabled)
		if BuffPresent(shadow_reflection_buff) or not Talent(shadow_reflection_talent) or target.TimeToDie() <= 20 or target.TimeToDie() <= 30 and Glyph(glyph_of_vendetta) Spell(vendetta)

		unless ComboPoints() == 5 and target.DebuffRemaining(rupture_debuff) <= BaseDuration(rupture_debuff) * 0.3 and Enemies() > 1 and Spell(rupture)
		{
			unless ComboPoints() == 5 and { not SpellCooldown(death_from_above) > 0 and Talent(death_from_above_talent) or BuffExpires(envenom_buff) or not Talent(anticipation_talent) or BuffStacks(anticipation_buff) + ComboPoints() >= 6 } and AssassinationFinishersCdPostConditions()
			{
				unless target.DebuffRemaining(rupture_debuff) < 2 and AssassinationFinishersCdPostConditions()
				{
					#call_action_list,name=generators
					AssassinationGeneratorsCdActions()
				}
			}
		}
	}
}

### actions.finishers

AddFunction AssassinationFinishersMainActions
{
	#rupture,cycle_targets=1,if=(remains<2|(combo_points=5&remains<=(duration*0.3)))
	if target.DebuffRemaining(rupture_debuff) < 2 or ComboPoints() == 5 and target.DebuffRemaining(rupture_debuff) <= BaseDuration(rupture_debuff) * 0.3 Spell(rupture)
	#pool_resource,for_next=1
	#death_from_above,if=(cooldown.vendetta.remains>10|debuff.vendetta.up|target.time_to_die<=25)
	if SpellCooldown(vendetta) > 10 or target.DebuffPresent(vendetta_debuff) or target.TimeToDie() <= 25 Spell(death_from_above)
	unless { SpellCooldown(vendetta) > 10 or target.DebuffPresent(vendetta_debuff) or target.TimeToDie() <= 25 } and SpellUsable(death_from_above) and SpellCooldown(death_from_above) < TimeToEnergyFor(death_from_above)
	{
		#envenom,cycle_targets=1,if=dot.deadly_poison_dot.remains<4&target.health.pct<=35&(energy+energy.regen*cooldown.vendetta.remains>=105&(buff.envenom.remains<=1.8|energy>45))|buff.bloodlust.up|debuff.vendetta.up
		if target.DebuffRemaining(deadly_poison_dot_debuff) < 4 and target.HealthPercent() <= 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 45 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) Spell(envenom)
		#envenom,cycle_targets=1,if=dot.deadly_poison_dot.remains<4&target.health.pct>35&(energy+energy.regen*cooldown.vendetta.remains>=105&(buff.envenom.remains<=1.8|energy>55))|buff.bloodlust.up|debuff.vendetta.up
		if target.DebuffRemaining(deadly_poison_dot_debuff) < 4 and target.HealthPercent() > 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 55 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) Spell(envenom)
		#envenom,if=target.health.pct<=35&(energy+energy.regen*cooldown.vendetta.remains>=105&(buff.envenom.remains<=1.8|energy>45))|buff.bloodlust.up|debuff.vendetta.up
		if target.HealthPercent() <= 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 45 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) Spell(envenom)
		#envenom,if=target.health.pct>35&(energy+energy.regen*cooldown.vendetta.remains>=105&(buff.envenom.remains<=1.8|energy>55))|buff.bloodlust.up|debuff.vendetta.up
		if target.HealthPercent() > 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 55 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) Spell(envenom)
	}
}

AddFunction AssassinationFinishersCdPostConditions
{
	{ target.DebuffRemaining(rupture_debuff) < 2 or ComboPoints() == 5 and target.DebuffRemaining(rupture_debuff) <= BaseDuration(rupture_debuff) * 0.3 } and Spell(rupture) or { SpellCooldown(vendetta) > 10 or target.DebuffPresent(vendetta_debuff) or target.TimeToDie() <= 25 } and Spell(death_from_above) or not { { SpellCooldown(vendetta) > 10 or target.DebuffPresent(vendetta_debuff) or target.TimeToDie() <= 25 } and SpellUsable(death_from_above) and SpellCooldown(death_from_above) < TimeToEnergyFor(death_from_above) } and { { target.DebuffRemaining(deadly_poison_dot_debuff) < 4 and target.HealthPercent() <= 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 45 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) } and Spell(envenom) or { target.DebuffRemaining(deadly_poison_dot_debuff) < 4 and target.HealthPercent() > 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 55 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) } and Spell(envenom) or { target.HealthPercent() <= 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 45 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) } and Spell(envenom) or { target.HealthPercent() > 35 and Energy() + EnergyRegenRate() * SpellCooldown(vendetta) >= 105 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 55 } or BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) } and Spell(envenom) }
}

### actions.generators

AddFunction AssassinationGeneratorsMainActions
{
	#dispatch,cycle_targets=1,if=dot.deadly_poison_dot.remains<4&talent.anticipation.enabled&((anticipation_charges<4&set_bonus.tier18_4pc=0)|(anticipation_charges<2&set_bonus.tier18_4pc=1))
	if target.DebuffRemaining(deadly_poison_dot_debuff) < 4 and Talent(anticipation_talent) and { BuffStacks(anticipation_buff) < 4 and ArmorSetBonus(T18 4) == 0 or BuffStacks(anticipation_buff) < 2 and ArmorSetBonus(T18 4) == 1 } Spell(dispatch)
	#dispatch,cycle_targets=1,if=dot.deadly_poison_dot.remains<4&!talent.anticipation.enabled&combo_points<5&set_bonus.tier18_4pc=0
	if target.DebuffRemaining(deadly_poison_dot_debuff) < 4 and not Talent(anticipation_talent) and ComboPoints() < 5 and ArmorSetBonus(T18 4) == 0 Spell(dispatch)
	#dispatch,cycle_targets=1,if=dot.deadly_poison_dot.remains<4&!talent.anticipation.enabled&set_bonus.tier18_4pc=1&(combo_points<2|target.health.pct<35)
	if target.DebuffRemaining(deadly_poison_dot_debuff) < 4 and not Talent(anticipation_talent) and ArmorSetBonus(T18 4) == 1 and { ComboPoints() < 2 or target.HealthPercent() < 35 } Spell(dispatch)
	#dispatch,if=talent.anticipation.enabled&((anticipation_charges<4&set_bonus.tier18_4pc=0)|(anticipation_charges<2&set_bonus.tier18_4pc=1))
	if Talent(anticipation_talent) and { BuffStacks(anticipation_buff) < 4 and ArmorSetBonus(T18 4) == 0 or BuffStacks(anticipation_buff) < 2 and ArmorSetBonus(T18 4) == 1 } Spell(dispatch)
	#dispatch,if=!talent.anticipation.enabled&combo_points<5&set_bonus.tier18_4pc=0
	if not Talent(anticipation_talent) and ComboPoints() < 5 and ArmorSetBonus(T18 4) == 0 Spell(dispatch)
	#dispatch,if=!talent.anticipation.enabled&set_bonus.tier18_4pc=1&(combo_points<2|target.health.pct<35)
	if not Talent(anticipation_talent) and ArmorSetBonus(T18 4) == 1 and { ComboPoints() < 2 or target.HealthPercent() < 35 } Spell(dispatch)
	#mutilate,cycle_targets=1,if=dot.deadly_poison_dot.remains<4&target.health.pct>35&(combo_points<5|(talent.anticipation.enabled&anticipation_charges<3))
	if target.DebuffRemaining(deadly_poison_dot_debuff) < 4 and target.HealthPercent() > 35 and { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } Spell(mutilate)
	#mutilate,if=target.health.pct>35&(combo_points<5|(talent.anticipation.enabled&anticipation_charges<3))
	if target.HealthPercent() > 35 and { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } Spell(mutilate)
}

AddFunction AssassinationGeneratorsCdActions
{
	unless target.DebuffRemaining(deadly_poison_dot_debuff) < 4 and Talent(anticipation_talent) and { BuffStacks(anticipation_buff) < 4 and ArmorSetBonus(T18 4) == 0 or BuffStacks(anticipation_buff) < 2 and ArmorSetBonus(T18 4) == 1 } and Spell(dispatch) or target.DebuffRemaining(deadly_poison_dot_debuff) < 4 and not Talent(anticipation_talent) and ComboPoints() < 5 and ArmorSetBonus(T18 4) == 0 and Spell(dispatch) or target.DebuffRemaining(deadly_poison_dot_debuff) < 4 and not Talent(anticipation_talent) and ArmorSetBonus(T18 4) == 1 and { ComboPoints() < 2 or target.HealthPercent() < 35 } and Spell(dispatch) or Talent(anticipation_talent) and { BuffStacks(anticipation_buff) < 4 and ArmorSetBonus(T18 4) == 0 or BuffStacks(anticipation_buff) < 2 and ArmorSetBonus(T18 4) == 1 } and Spell(dispatch) or not Talent(anticipation_talent) and ComboPoints() < 5 and ArmorSetBonus(T18 4) == 0 and Spell(dispatch) or not Talent(anticipation_talent) and ArmorSetBonus(T18 4) == 1 and { ComboPoints() < 2 or target.HealthPercent() < 35 } and Spell(dispatch) or target.DebuffRemaining(deadly_poison_dot_debuff) < 4 and target.HealthPercent() > 35 and { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } and Spell(mutilate) or target.HealthPercent() > 35 and { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } and Spell(mutilate)
	{
		#preparation,if=(cooldown.vanish.remains>50|!glyph.disappearance.enabled&cooldown.vanish.remains>110)&buff.vanish.down&buff.stealth.down
		if { SpellCooldown(vanish) > 50 or not Glyph(glyph_of_disappearance) and SpellCooldown(vanish) > 110 } and BuffExpires(vanish_buff) and BuffExpires(stealthed_buff any=1) Spell(preparation)
	}
}

### actions.precombat

AddFunction AssassinationPrecombatMainActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=sleeper_sushi
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#stealth
	Spell(stealth)
	#slice_and_dice,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) Spell(slice_and_dice)
}

AddFunction AssassinationPrecombatShortCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth)
	{
		#marked_for_death
		Spell(marked_for_death)
	}
}

AddFunction AssassinationPrecombatShortCdPostConditions
{
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth) or Talent(marked_for_death_talent) and Spell(slice_and_dice)
}

AddFunction AssassinationPrecombatCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison)
	{
		#snapshot_stats
		#potion,name=draenic_agility
		AssassinationUsePotionAgility()
	}
}

AddFunction AssassinationPrecombatCdPostConditions
{
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth) or Talent(marked_for_death_talent) and Spell(slice_and_dice)
}

### Assassination icons.

AddCheckBox(opt_rogue_assassination_aoe L(AOE) default specialization=assassination)

AddIcon checkbox=!opt_rogue_assassination_aoe enemies=1 help=shortcd specialization=assassination
{
	if not InCombat() AssassinationPrecombatShortCdActions()
	unless not InCombat() and AssassinationPrecombatShortCdPostConditions()
	{
		AssassinationDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_rogue_assassination_aoe help=shortcd specialization=assassination
{
	if not InCombat() AssassinationPrecombatShortCdActions()
	unless not InCombat() and AssassinationPrecombatShortCdPostConditions()
	{
		AssassinationDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=assassination
{
	if not InCombat() AssassinationPrecombatMainActions()
	AssassinationDefaultMainActions()
}

AddIcon checkbox=opt_rogue_assassination_aoe help=aoe specialization=assassination
{
	if not InCombat() AssassinationPrecombatMainActions()
	AssassinationDefaultMainActions()
}

AddIcon checkbox=!opt_rogue_assassination_aoe enemies=1 help=cd specialization=assassination
{
	if not InCombat() AssassinationPrecombatCdActions()
	unless not InCombat() and AssassinationPrecombatCdPostConditions()
	{
		AssassinationDefaultCdActions()
	}
}

AddIcon checkbox=opt_rogue_assassination_aoe help=cd specialization=assassination
{
	if not InCombat() AssassinationPrecombatCdActions()
	unless not InCombat() and AssassinationPrecombatCdPostConditions()
	{
		AssassinationDefaultCdActions()
	}
}

### Required symbols
# anticipation_buff
# anticipation_talent
# arcane_torrent_energy
# berserking
# blindside_buff
# blood_fury_ap
# cheap_shot
# deadly_poison
# deadly_poison_dot_debuff
# deadly_throw
# death_from_above
# death_from_above_talent
# dispatch
# draenic_agility_potion
# envenom
# envenom_buff
# glyph_of_disappearance
# glyph_of_vendetta
# kick
# kidney_shot
# lethal_poison_buff
# marked_for_death
# marked_for_death_talent
# mutilate
# preparation
# quaking_palm
# rupture
# rupture_debuff
# shadow_reflection
# shadow_reflection_buff
# shadow_reflection_talent
# shadowstep
# slice_and_dice
# stealth
# vanish
# vanish_buff
# vendetta
# vendetta_debuff
]]
	OvaleScripts:RegisterScript("ROGUE", "assassination", name, desc, code, "script")
end
