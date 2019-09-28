local __exports = LibStub:GetLibrary("ovale/scripts/ovale_druid")
if not __exports then return end
__exports.registerDruidRestorationXeltor = function(OvaleScripts)
do
	local name = "xeltor_restoration_a"
	local desc = "[Xel][8.2] Druid: Restoration"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)
Include(druid_common_functions)

AddIcon specialization=4 help=main
{
	# Don't fucking dismount me asshole script.
	if not Stance(2) and not Stance(3) and not mounted() and not Dead() and not IsDead()
	{
		if HealthPercent() > 0 and HealthPercent() < 70 Spell(renewal)
		
		# Ress dead ally
		if PartyMembersWithHealthPercent(equal 0) >= 1
		{
			if not InCombat() and Spell(revitalize usable=1) and not PreviousGCDSpell(revitalize) and { Speed() == 0 or CanMove() > 0 } Spell(revitalize)
		}
		
		if CheckBoxOn(auto) Party_Auto_Target()
		
		# Do main rotation.
		if target.Present() and target.IsFriend() and target.InRange(rejuvenation) and target.HealthPercent() < 100
		{
			Cooldowns()
			
			Rotation()
		}
		
		# Keep up focus stuff regardless of target.
		if HasFocus()
		{
			# Keep Lifebloom on an active tank. Refreshing it with less than 4.5 seconds left in order to proc the final Bloom and not lose any ticks is recommended.
			if focus.TicksRemaining(lifebloom_buff) <= 0 and focus.BuffRemains(lifebloom_buff) < 5 and focustarget.Present() and not focustarget.IsFriend() Spell(lifebloom)
		}
		
		# Bored do some dps.
		if target.IsFriend() and targettarget.Present() and not targettarget.IsFriend() and targettarget.HealthPercent() < 100 and InCombat() and targettarget.InRange(moonfire) and CheckBoxOn(dps) TTDPS()
		if not target.IsFriend() and target.Present() and target.InRange(moonfire) and InCombat() DPS()
	}
}
AddCheckBox(auto "Party auto target" default)
AddCheckBox(dps "Do Deeps")

AddFunction HasFocus
{
	focus.Present() and focus.InRange(lifebloom) and focus.HealthPercent() > 0
}

# Party auto target system
AddFunction Party_Auto_Target
{
	unless UnitInRaid()
	{
		# Self healing.
		if player.HealthPercent() < 50 ThePlayer()
		
		# Focus healing.
		unless player.HealthPercent() < 50
		{
			if HasFocus() and focus.HealthPercent() < 50
			{
				if player.IsFocus() ThePlayer()
				if player2.IsFocus() PartyMemberOne()
				if player3.IsFocus() PartyMemberTwo()
				if player4.IsFocus() PartyMemberThree()
				if player5.IsFocus() PartyMemberFour()
			}
		}
		
		# Normal healing.
		unless player.HealthPercent() < 50 or HasFocus() and focus.HealthPercent() < 50
		{
			if PartyMemberWithLowestHealth() == 1 ThePlayer()
			if PartyMemberWithLowestHealth() == 2 PartyMemberOne()
			if PartyMemberWithLowestHealth() == 3 PartyMemberTwo()
			if PartyMemberWithLowestHealth() == 4 PartyMemberThree()
			if PartyMemberWithLowestHealth() == 5 PartyMemberFour()
		}
	}
}

AddFunction HotCount
{
	BuffCountOnAny(rejuvenation_buff) + BuffCountOnAny(regrowth_buff) + BuffCountOnAny(wild_growth_buff) + BuffCountOnAny(lifebloom_buff) + BuffCountOnAny(tranquility_buff) + BuffCountOnAny(cenarion_ward_hot_buff)
}

AddFunction ThePlayer
{
	unless player.IsTarget() Texture(misc_arrowdown)
}

AddFunction PartyMemberOne
{
	unless party1.IsTarget() Texture(ships_ability_boardingparty)
}

AddFunction PartyMemberTwo
{
	unless party2.IsTarget() Texture(ships_ability_boardingpartyalliance)
}

AddFunction PartyMemberThree
{
	unless party3.IsTarget() Texture(ships_ability_boardingpartyhorde)
}

AddFunction PartyMemberFour
{
	unless party4.IsTarget() Texture(inv_helm_misc_starpartyhat)
}

# Rotation

AddFunction Cooldowns 
{
	if HotCount() >= 8 Spell(flourish)
	if UnitInRaid() and RaidMembersInRange(wild_growth) >= 6 and RaidMembersWithHealthPercent(less 80) >= 6 and { Speed() == 0 or CanMove() > 0 } or not UnitInRaid() and PartyMembersInRange(wild_growth) >= 3 and PartyMembersWithHealthPercent(less 85) >= 3 and { Speed() == 0 or CanMove() > 0 }
	{
		Spell(berserking)
		if ManaPercent() < 80 Spell(innervate)
		if BuffCountOnAny(wild_growth_buff) == 0 and SpellCooldown(wild_growth) > GCD() Spell(tranquility)
	}
}

AddFunction Rotation
{
	# Save dying players immediate.
	if target.HealthPercent() < 40 HotFix()
	# Keep Lifebloom on an active tank. Refreshing it with less than 4.5 seconds left in order to proc the final Bloom and not lose any ticks is recommended.
	if HasFocus() and focus.TicksRemaining(lifebloom_buff) <= 0 and focus.BuffRemains(lifebloom_buff) < 5 and focustarget.Present() and not focustarget.IsFriend() Spell(lifebloom)
	# Use Wild Growth when at least 6 members of the raid are damaged and you have some Rejuvenations up.
	if UnitInRaid() and RaidMembersInRange(wild_growth) >= 6 and RaidMembersWithHealthPercent(less 80) >= 6 and { Speed() == 0 or CanMove() > 0 } Spell(wild_growth)
	# Use Wild Growth when at least 4 members of the group are damaged.
	if not UnitInRaid() and PartyMembersInRange(wild_growth) >= 3 and PartyMembersWithHealthPercent(less 85) >= 3 and { Speed() == 0 or CanMove() > 0 } Spell(wild_growth)
	if InCombat() Spell(cenarion_ward)
	# Keep Rejuvenation on the tank and on members of the group that just took damage or are about to take damage.
	if not Talent(germination_talent) and target.BuffRemains(rejuvenation_buff) <= 3.5 Spell(rejuvenation)
	if Talent(germination_talent) and target.BuffRemains(rejuvenation_buff) <= 3.5 and { target.BuffRemains(germination_buff) > target.BuffRemains(rejuvenation_buff) or not target.BuffPresent(germination_buff) } Spell(rejuvenation)
	# Keep up both Rejuvenations on targets on which the damage is too high for a single one.
	if Talent(germination_talent) and { Talent(abundance_talent) or target.HealthPercent() < 89 } and target.BuffRemains(germination_buff) <= 3.5 and target.BuffPresent(rejuvenation_buff) and target.BuffRemains(germination_buff) < target.BuffRemains(rejuvenation_buff) Spell(rejuvenation)
	# Use Swiftmend on a player that just took heavy damage. If they are not in immediate danger, you should apply Rejuvenation to him first.
	if target.HealthPercent() <= 80 and { Speed() == 0 or CanMove() > 0 } Spell(regrowth)
}

AddFunction HotFix
{
	if SpellCooldown(swiftmend) > GCD() Spell(ironbark)
	if SpellCooldown(swiftmend) > GCD() Spell(berserking)
	Spell(swiftmend)
}

AddFunction TTDPS
{
	if not targettarget.DebuffPresent(sunfire_debuff) and ManaPercent() > 80 Spell(sunfire)
	if not targettarget.DebuffPresent(moonfire_debuff) and ManaPercent() > 80 Spell(moonfire)
}

AddFunction DPS
{
	if HealthPercent() < 100
	{
		Spell(cenarion_ward)
		if BuffRemains(rejuvenation_buff) <= 3.5 Spell(rejuvenation)
		if Speed() == 0 and HealthPercent() < 50 Spell(regrowth)
	}
	
	if Talent(balance_affinity_talent) and not Stance(4) Spell(moonkin_form)
	if target.DebuffRemains(sunfire_debuff) <= 3 Spell(sunfire)
	if target.DebuffRemains(moonfire_debuff) <= 3 Spell(moonfire)
	if Speed() == 0 or CanMove() > 0
	{
		if Talent(balance_affinity_talent) Spell(starsurge)
		if { BuffPresent(lunar_empowerment_buff) or Enemies(tagged=1) > 3 } and Talent(balance_affinity_talent) Spell(lunar_strike)
		Spell(solar_wrath)
	}
}
]]

		OvaleScripts:RegisterScript("DRUID", "restoration", name, desc, code, "script")
	end
end