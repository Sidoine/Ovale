local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "nerien_druid_restoration"
	local desc = "[6.0] Nerien: Restoration"
	local code = [[
###
### Nerien's restoration druid script.
###

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=restoration)

AddFunction RestorationInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(skull_bash) Spell(skull_bash)
		if not target.Classification(worldboss)
		{
			if target.InRange(mighty_bash) Spell(mighty_bash)
			Spell(typhoon)
			if target.InRange(maim) Spell(maim)
			Spell(war_stomp)
		}
	}
}

AddFunction RestorationPrecombatActions
{
	# Raid buffs.
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	# Healing Touch to refresh Harmony buff.
	if BuffRemaining(harmony_buff) < 6 Spell(healing_touch)
}

AddFunction RestorationMainActions
{
	# Cast instant/mana-free Healing Touch or Regrowth.
	if BuffStacks(sage_mender_buff) == 5 Spell(healing_touch)
	if BuffPresent(omen_of_clarity_heal_buff) or BuffPresent(omen_of_clarity_moment_of_clarity_buff) Spell(regrowth)
	if BuffPresent(natures_swiftness_buff) Spell(healing_touch)

	# Maintain 100% uptime on Harmony mastery buff using Swiftmend.
	# Swiftmend requires either a Rejuvenation or Regrowth HoT to be on the target before
	# it is usable, but we want to show Swiftmend as usable as long as the cooldown is up.
	if BuffRemaining(harmony_buff) < 6 and { BuffCountOnAny(regrowth_buff) > 0 or BuffCountOnAny(rejuvenation_buff) > 0 or BuffCountOnAny(rejuvenation_germination_buff) > 0 } and not SpellCooldown(swiftmend) > 0 Texture(inv_relics_idolofrejuvenation help=Swiftmend)

	# Keep one Lifebloom up on the raid.
	if BuffRemainingOnAny(lifebloom_buff) < 4 Spell(lifebloom)

	# Cast Cenarion Ward on cooldown, usually on the tank.
	if Talent(cenarion_ward_talent) Spell(cenarion_ward)
}

AddFunction RestorationAoeActions
{
	if BuffPresent(tree_of_life_buff)
	{
		Spell(wild_growth)
		if BuffPresent(omen_of_clarity_heal_buff) or BuffPresent(omen_of_clarity_moment_of_clarity_buff) Spell(regrowth)
	}
	unless BuffPresent(tree_of_life_buff)
	{
		Spell(wild_growth)
		if BuffCountOnAny(rejuvenation_buff) > 4 or BuffCountOnAny(rejuvenation_germination_buff) > 4 Spell(genesis)
	}
}

AddFunction RestorationShortCdActions
{
	# Don't cap out on Force of Nature charges.
	if Talent(force_of_nature_talent) and Charges(force_of_nature_heal count=0) >= 3 Spell(force_of_nature_heal)
	# Maintain Efflorescence.
	if TotemExpires(wild_mushroom_heal) Spell(wild_mushroom_heal)
}

AddFunction RestorationCdActions
{
	RestorationInterruptActions()
	Spell(blood_fury_apsp)
	Spell(berserking)
	if ManaPercent() < 97 Spell(arcane_torrent_mana)
	Spell(incarnation_heal)
	Spell(heart_of_the_wild_heal)
	Spell(natures_vigil)
}

### Restoration icons.

AddCheckBox(opt_druid_restoration_aoe L(AOE) default specialization=restoration)

AddIcon help=shortcd specialization=restoration
{
	RestorationShortCdActions()
}

AddIcon help=main specialization=restoration
{
	if not InCombat() RestorationPrecombatActions()
	RestorationMainActions()
}

AddIcon checkbox=opt_druid_restoration_aoe help=aoe specialization=restoration
{
	RestorationAoeActions()
}

AddIcon help=cd specialization=restoration
{
	RestorationCdActions()
}
]]
	OvaleScripts:RegisterScript("DRUID", "restoration", name, desc, code, "script")
end
