local __exports = LibStub:GetLibrary("ovale/scripts/ovale_rogue")
if not __exports then return end
__exports.registerRogueAssassinationXeltor = function(OvaleScripts)
do
	local name = "xeltor_stabby"
	local desc = "[Xel][8.2] Blush: Stabby"
	local code = [[

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)

# Assassination (Stabby)
AddIcon specialization=1 help=main
{
	if not mounted() and not Stealthed() and not InCombat() and not Dead() and not PlayerIsResting()
	{
		unless target.Present() and target.Distance(less 5)
		{
			if Speed() > 0 Spell(stealth)
		}
	}
	if not InCombat() and not mounted() and not Dead()
	{
		# Poisons!
		if BuffRemaining(lethal_poison_buff) < 600 and Speed() == 0 and SpellUsable(deadly_poison) Texture(spell_nature_corrosivebreath)
		if BuffRemaining(crippling_poison_buff) < 600 and Speed() == 0 Spell(crippling_poison)
		# if target.InRange(marked_for_death) and Stealthed() and not BuffPresent(cold_blood) Spell(cold_blood)
		#marked_for_death
		if target.InRange(marked_for_death) and ComboPoints() < 5 and target.Present() and target.Exists() and not target.IsFriend() Spell(marked_for_death)
	}
	
	if InCombat() InterruptActions()
	if HealthPercent() < 50 and not Dead() and Energy() > 24 Spell(crimson_vial)
	
	if target.InRange(mutilate) and HasFullControl()
	{
		# Cooldowns
		# AssassinationDefaultCdActions()
		
		# Short Cooldowns
		# AssassinationDefaultShortCdActions()
		
		# Default Actions
		# AssassinationDefaultMainActions()
	}
	
	if InCombat() and target.Present() and not target.IsDead() and not target.IsFriend() and Falling() and { target.HealthPercent() < 100 or target.istargetingplayer() } AssassinationGetInMeleeRange()
	if InCombat() and target.Present() and not target.IsFriend() and not target.InRange(kick) and not target.DebuffPresent(deadly_poison_debuff) and target.InRange(poisoned_knife) Spell(poisoned_knife)
}

AddFunction VanishAllowed
{
	{ not target.istargetingplayer() or { unitinparty() and PartyMemberCount() >= 5 } or unitinraid() }
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		if target.InRange(kidney_shot) and not target.Classification(worldboss) and ComboPoints() >= 1 Spell(kidney_shot)
		if target.InRange(cheap_shot) and not target.Classification(worldboss) Spell(cheap_shot)
		if target.InRange(kick) and target.IsInterruptible() Spell(kick)
	}
}

AddFunction AssassinationUseItemActions
{
 if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
 if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

AddFunction AssassinationGetInMeleeRange
{
	if not target.InRange(kick)
	{
		if target.InRange(shadowstep) Spell(shadowstep)
		# Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction skip_rupture
{
 target.DebuffPresent(vendetta_debuff) and { target.DebuffPresent(toxic_blade_debuff) or BuffRemaining(master_assassin_buff) > 0 } and target.DebuffRemaining(rupture_debuff) > 2
}

AddFunction use_filler
{
 ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target()
}

AddFunction ss_vanish_condition
{
 HasAzeriteTrait(shrouded_suffocation_trait) and { Enemies(tagged=1) - DebuffCountOnAny(garrote_debuff) >= 1 or Enemies(tagged=1) == 3 } and { 0 == 0 or Enemies(tagged=1) >= 6 }
}

AddFunction energy_regen_combined
{
 EnergyRegenRate() + { DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) } * 7 / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } }
}

AddFunction skip_cycle_rupture
{
 Enemies(tagged=1) > 3 and { target.DebuffPresent(toxic_blade_debuff) or DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) > 5 and not HasAzeriteTrait(scent_of_blood_trait) }
}

AddFunction skip_cycle_garrote
{
 Enemies(tagged=1) > 3 and { target.DebuffRemaining(garrote_debuff) < SpellCooldownDuration(garrote) or DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) > 5 }
}

AddFunction single_target
{
 Enemies(tagged=1) < 2
}


]]

		OvaleScripts:RegisterScript("ROGUE", "assassination", name, desc, code, "script")
	end
end
