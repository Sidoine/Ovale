local __exports = LibStub:GetLibrary("ovale/scripts/ovale_shaman")
if not __exports then return end
__exports.registerShamanRestorationXeltor = function(OvaleScripts)
do
	local name = "xeltor_restoration"
	local desc = "[Xel][7.3] Shaman: Restoration"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)

Define(riptide 61295)
	SpellInfo(riptide cd=6)
	SpellInfo(riptide max_stacks=2 talent=echo_of_the_elements_talent)
	SpellAddTargetBuff(riptide riptide_buff=1)
	SpellAddBuff(riptide tidal_wave_buff=1)
Define(riptide_buff 61295)
	SpellInfo(riptide_buff duration=18)
Define(tidal_wave_buff 53390)
	SpellInfo(tidal_wave_buff duration=15)
Define(chain_heal 1064)
	SpellAddBuff(chain_heal tidal_wave_buff=1)
Define(healing_surge 8004)
	SpellAddBuff(healing_surge tidal_wave_buff=-1)
Define(healing_wave 77472)
	SpellAddBuff(healing_wave tidal_wave_buff=-1)
Define(healing_stream_totem 5394)
	SpellInfo(healing_stream_totem totem=water cd=30)
	SpellInfo(healing_stream_totem max_stacks=2 talent=echo_of_the_elements_talent)
Define(healing_tide_totem 108280)
	SpellInfo(healing_tide_totem cd=180)
Define(ancestral_guidance 108281)
	SpellInfo(ancestral_guidance cd=120)
Define(cloudburst_totem 157153)
	SpellInfo(cloudburst_totem cd=30)
Define(ascendance 114052)
	SpellInfo(ascendance cd=180)
	SpellAddBuff(ascendance ascendance_buff=1)
Define(ascendance_buff 114052)
	SpellInfo(ascendance_buff duration=15)
Define(gift_of_the_queen 207778)
	SpellInfo(gift_of_the_queen cd=45)
Define(wind_shear 57994)
	SpellInfo(wind_shear cd=12 gcd=0 offgcd=1 interrupt=1)
	
# Talents
Define(cloudburst_totem_talent 17)
Define(echo_of_the_elements_talent 18)
Define(high_tide_talent 21)

# Restoration
AddIcon specialization=3 help=main
{
	# Interrupt
	if InCombat() InterruptActions()
	
	if CheckBoxOn(auto) Party_Auto_Target()
	
	if target.Present() and target.IsFriend() and target.InRange(riptide) and target.HealthPercent() < 100
    {
		Cooldowns()
		
		Rotation()
	}
}
AddCheckBox(hard "Heal harder")
AddCheckBox(auto "Party auto target")

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible() and { target.MustBeInterrupted() or Level() < 100 or target.IsPVP() }
	{
		if target.InRange(wind_shear) and target.IsInterruptible() Spell(wind_shear)
        if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
        if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
	}
}

# Party auto target system
AddFunction Party_Auto_Target
{
	unless UnitInRaid()
	{
		# Anti non friend selection bit.
		if not target.IsFriend() and target.Exists() and InCombat() ThePlayer()

		# Prioritize low health
		if HealthPercent() < 60 and { target.HealthPercent() >= 60 or HealthPercent() < target.HealthPercent() or not target.Present() } ThePlayer()
		if party1.HealthPercent() < 60 and { target.HealthPercent() >= 60 or party1.HealthPercent() < target.HealthPercent() or not target.Present() } and party1.Present() and party1.InRange(riptide) PartyMemberOne()
		if party2.HealthPercent() < 60 and { target.HealthPercent() >= 60 or party2.HealthPercent() < target.HealthPercent() or not target.Present() } and party2.Present() and party2.InRange(riptide) PartyMemberTwo()
		if party3.HealthPercent() < 60 and { target.HealthPercent() >= 60 or party3.HealthPercent() < target.HealthPercent() or not target.Present() } and party3.Present() and party3.InRange(riptide) PartyMemberThree()
		if party4.HealthPercent() < 60 and { target.HealthPercent() >= 60 or party4.HealthPercent() < target.HealthPercent() or not target.Present() } and party4.Present() and party4.InRange(riptide) PartyMemberFour()
		
		# Normal healing.
		unless HealthPercent() < 60 and { target.HealthPercent() >= 60 or HealthPercent() < target.HealthPercent() or not target.Present() } or party1.HealthPercent() < 60 and { target.HealthPercent() >= 60 or party1.HealthPercent() < target.HealthPercent() or not target.Present() } and party1.Present() and party1.InRange(riptide) or party2.HealthPercent() < 60 and { target.HealthPercent() >= 60 or party2.HealthPercent() < target.HealthPercent() or not target.Present() } and party2.Present() and party2.InRange(riptide) or party3.HealthPercent() < 60 and { target.HealthPercent() >= 60 or party3.HealthPercent() < target.HealthPercent() or not target.Present() } and party3.Present() and party3.InRange(riptide) or party4.HealthPercent() < 60 and { target.HealthPercent() >= 60 or party4.HealthPercent() < target.HealthPercent() or not target.Present() } and party4.Present() and party4.InRange(riptide)
		{
			if HealthPercent() < 85 and { target.HealthPercent() >= 85 or HealthPercent() < target.HealthPercent() or not target.Present() } ThePlayer()
			if party1.HealthPercent() < 85 and { target.HealthPercent() >= 85 or party1.HealthPercent() < target.HealthPercent() or not target.Present() } and party1.Present() and party1.InRange(riptide) PartyMemberOne()
			if party2.HealthPercent() < 85 and { target.HealthPercent() >= 85 or party2.HealthPercent() < target.HealthPercent() or not target.Present() } and party2.Present() and party2.InRange(riptide) PartyMemberTwo()
			if party3.HealthPercent() < 85 and { target.HealthPercent() >= 85 or party3.HealthPercent() < target.HealthPercent() or not target.Present() } and party3.Present() and party3.InRange(riptide) PartyMemberThree()
			if party4.HealthPercent() < 85 and { target.HealthPercent() >= 85 or party4.HealthPercent() < target.HealthPercent() or not target.Present() } and party4.Present() and party4.InRange(riptide) PartyMemberFour()
		}
	}
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

############
# Rotation #
############

AddFunction Cooldowns
{
	# Ascendance + racials
	if CheckBoxOn(hard)
	{
		if not BuffPresent(ascendance_buff) Spell(ascendance)
		Spell(berserking)
		Spell(blood_fury_apsp)
	}
	# Cloudburst Totem
	if not TotemPresent(cloudburst_totem) and { CheckBoxOn(hard) or not UnitInRaid() and PartyMembersInRange(riptide) >= 3 and PartyMembersWithHealthPercent(less 60) >= 3 or UnitInRaid() and RaidMembersInRange(riptide) >= 6 and RaidMembersWithHealthPercent(less 60) >= 6 } Spell(cloudburst_totem)
	# Ancestral Guidance
	if CheckBoxOn(hard) or Talent(cloudburst_totem_talent) and TotemPresent(cloudburst_totem) or not Talent(cloudburst_totem_talent) and { not UnitInRaid() and PartyMembersInRange(riptide) >= 3 and PartyMembersWithHealthPercent(less 60) >= 3 or UnitInRaid() and RaidMembersInRange(riptide) >= 6 and RaidMembersWithHealthPercent(less 60) >= 6 } Spell(ancestral_guidance)
	# Gift of the Queen
	if { Speed() == 0 or CanMove() } and { CheckBoxOn(hard) or Talent(cloudburst_totem_talent) and TotemPresent(cloudburst_totem) or not Talent(cloudburst_totem_talent) and { not UnitInRaid() and PartyMembersInRange(riptide) >= 3 and PartyMembersWithHealthPercent(less 60) >= 3 or UnitInRaid() and RaidMembersInRange(riptide) >= 6 and RaidMembersWithHealthPercent(less 60) >= 6 } } Spell(gift_of_the_queen)
	# Healing Tide Totem
	if not UnitInRaid() and PartyMembersWithHealthPercent(less 60) >= 3 and PartyMembersInRange(riptide) >= 3 Spell(healing_tide_totem)
	# Healing Stream Totem
	if InCombat() and not TotemPresent(healing_stream_totem) Spell(healing_stream_totem)
}

AddFunction Rotation
{
	# Keep up tidal wave, always.
	if not target.BuffPresent(riptide_buff) and BuffStacks(tidal_wave_buff) < 2 and target.HealthPercent() < 100 or target.HealthPercent() <= 25 Spell(riptide)
	if BuffStacks(tidal_wave_buff) == 0 and SpellCooldown(riptide) > CastTime(chain_heal) + GCD() and target.HealthPercent() < 100 and { Speed() == 0 or CanMove() } Spell(chain_heal)
	
	# Routine
	if Talent(high_tide_talent) and target.HealthPercent() < 80 and { PartyMembersWithHealthPercent(less 80) >= 3 or RaidMembersWithHealthPercent(less 80) >= 5 } and { Speed() == 0 or CanMove() } Spell(chain_heal)
	if not Talent(high_tide_talent) and target.HealthPercent() < 60 and { PartyMembersWithHealthPercent(less 80) >= 3 or RaidMembersWithHealthPercent(less 80) >= 5 } and { Speed() == 0 or CanMove() } Spell(chain_heal)
	if target.HealthPercent() < 60 and BuffStacks(tidal_wave_buff) >= 1 and { Speed() == 0 or CanMove() } Spell(healing_surge)
	if target.HealthPercent() < 100 and { Speed() == 0 or CanMove() } Spell(healing_wave)
}
]]

		OvaleScripts:RegisterScript("SHAMAN", "restoration", name, desc, code, "script")
	end
end
