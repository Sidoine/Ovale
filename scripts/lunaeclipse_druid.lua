local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "LunaEclipse"
	local desc = "[5.4.8] LunaEclipse: Balance"
	local code = [[
# LunaEclipse's druid script.
# Based on Icy Veins forum post "Moonkin Info and Fixing Your DPS":
# http://www.icy-veins.com/forums/topic/5528-balance-moonkin-info-and-fixing-your-dps/

Include(ovale_common)
Include(ovale_druid_spells)

AddCheckBox(opt_potion_intellect ItemName(jade_serpent_potion) default specialization=balance)

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

AddFunction InterruptActions
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if Stance(druid_bear_form) and target.InRange(skull_bash_bear) Spell(skull_bash_bear)
		if Stance(druid_cat_form) and target.InRange(skull_bash_cat) Spell(skull_bash_cat)
		if target.Classification(worldboss no)
		{
			if Talent(mighty_bash_talent) and target.InRange(mighty_bash) Spell(mighty_bash)
			if Talent(typhoon_talent) and target.InRange(skull_bash_cat) Spell(typhoon)
			if Stance(druid_cat_form) and ComboPoints() > 0 and target.InRange(maim) Spell(maim)
			Spell(solar_beam)
		}
	}
}

AddFunction BalanceIsNearEclipseState
{
	# True if we're one cast away from reaching the next Eclipse.
	   EclipseDir() < 0 and BuffExpires(shooting_stars_buff) and Eclipse() + 100 <= 30
	or EclipseDir() < 0 and BuffPresent(shooting_stars_buff) and Eclipse() + 100 <= 40
	or EclipseDir() > 0 and 100 - Eclipse() <= 40
}

AddFunction BalanceDotActions
{
	# If either DoT need to be applied or refreshed during celestial alignment only suggest Moonfire.
	if { target.TicksRemain(moonfire_debuff) < 2 or target.TicksRemain(sunfire_debuff) < 2 } and BuffPresent(celestial_alignment_buff) Spell(moonfire)

	# If both DoTs need to be applied or refreshed, apply the non-Eclipsed DoT first to gain Lunar Shower for the application of the Eclipsed DoT.
	if target.TicksRemain(moonfire_debuff) < 2 and target.TicksRemain(sunfire_debuff) < 2
	{
		if BuffPresent(lunar_eclipse_buff) Spell(sunfire)
		if BuffPresent(solar_eclipse_buff) Spell(moonfire)
	}

	# Apply the Eclipsed DoT when entering the corresponding Eclipse state.
	if BuffPresent(lunar_eclipse_buff) and target.DebuffRemaining(moonfire_debuff) < BuffRemaining(natures_grace_buff) - 2 Spell(moonfire)
	if BuffPresent(solar_eclipse_buff) and target.DebuffRemaining(sunfire_debuff) < BuffRemaining(natures_grace_buff) - 2 Spell(sunfire)

	# Apply the Eclipsed DoT if it fell off during the Eclipse state.
	if BuffPresent(lunar_eclipse_buff) and target.TicksRemain(moonfire_debuff) < 2 Spell(moonfire)
	if BuffPresent(solar_eclipse_buff) and target.TicksRemain(sunfire_debuff) < 2 Spell(sunfire)

	# Apply the non-Eclipsed DoT only when it is about to expire (on the last tick) and we are not about to enter a new Eclipse state.
	unless BalanceIsNearEclipseState()
	{
		if BuffExpires(lunar_eclipse_buff) and target.TicksRemain(moonfire_debuff) < 2 Spell(moonfire)
		if BuffExpires(solar_eclipse_buff) and target.TicksRemain(sunfire_debuff) < 2 Spell(sunfire)
	}

	# Simplistic logic for refreshing DoTs early to snapshot powerful buff effects.
	if Level() >= 90 and target.DebuffPresent(moonfire_debuff) and Damage(moonfire_debuff) / LastEstimatedDamage(moonfire_debuff) > 1.5 Spell(moonfire)
	if Level() >= 90 and target.DebuffPresent(sunfire_debuff) and Damage(sunfire_debuff) / LastEstimatedDamage(sunfire_debuff) > 1.5 Spell(sunfire)
}

# Minimize the time spent outside of Eclipse by only casting Starsurge at the appropriate times:
#    * The Shooting Stars buff is about to expire.
#    * During Celestial Alignment.
#    * During Lunar Eclipse unless it pushes you out of Eclipse during Starfall.
#    * When outside Lunar Eclipse and moving toward Solar Eclipse.
#    * The first time Starsurge is available during Solar Eclipse.
#    * The second time Starsurge is available during Solar Eclipse only at 5 Eclipse energy.
#    * When outside Solar Eclipse and moving toward Lunar Eclipse.
#
AddFunction BalanceStarsurgeCondition
{
	   BuffPresent(shooting_stars_buff) and BuffRemaining(shooting_stars_buff) < 2
	or BuffPresent(celestial_alignment_buff)
	or BuffPresent(lunar_eclipse_buff) and 0 - Eclipse() > 20
	or BuffPresent(lunar_eclipse_buff) and 0 - Eclipse() <= 20 and BuffPresent(shooting_stars_buff) and BuffExpires(starfall_buff)
	or BuffPresent(lunar_eclipse_buff) and 0 - Eclipse() <= 20 and BuffExpires(shooting_stars_buff) and BuffRemaining(starfall_buff) < CastTime(starsurge)
	or BuffExpires(lunar_eclipse_buff) and EclipseDir() >= 0
	or BuffPresent(solar_eclipse_buff) and { Eclipse(asValue=1) - 10 } % 15 == 0
	or BuffPresent(solar_eclipse_buff) and Eclipse() == 5
	or BuffExpires(solar_eclipse_buff) and EclipseDir() <= 0
}

# Only suggest Starfire at the appropriate times:
#    * During Lunar Eclipse unless it pushes you out of Eclipse during Starfall.
#    * When outside Lunar Eclipse and moving toward Solar Eclipse.
#
AddFunction BalanceStarfireCondition
{
	   BuffPresent(lunar_eclipse_buff) and 0 - Eclipse() > 20
	or BuffPresent(lunar_eclipse_buff) and 0 - Eclipse() <= 20 and BuffRemaining(starfall_buff) < CastTime(starfire)
	or BuffExpires(lunar_eclipse_buff) and EclipseDir() >= 0
}

# Only suggest Incarnation at the appropriate times:
#    * During an Eclipse state with Nature's Grace active or Eclipse energy at either -100 or 100.
#
AddFunction BalanceIncarnationCondition
{
	   BuffPresent(lunar_eclipse_buff) and { BuffPresent(natures_grace_buff) or Eclipse() == -100 }
	or BuffPresent(solar_eclipse_buff) and { BuffPresent(natures_grace_buff) or Eclipse() == 100 }
}

AddFunction BalanceMainActions
{
	# Always be in Moonkin form.
	if not Stance(druid_moonkin_form) Spell(moonkin_form)
	# Proc Dream of Cenarius with Healing Touch if one cast away from reaching Eclipse.
	if TalentPoints(dream_of_cenarius_talent) and BuffExpires(dream_of_cenarius_caster_buff) and BalanceIsNearEclipseState() Spell(healing_touch)
	# Cast Incarnation.
	if TalentPoints(incarnation_talent) and BalanceIncarnationCondition() Spell(incarnation_caster)
	# Cast Celestial Alignment if currently out of an Eclipse state and Incarnation is active.
	if BuffExpires(lunar_eclipse_buff) and BuffExpires(solar_eclipse_buff) and { BuffPresent(chosen_of_elune_buff) or not TalentPoints(incarnation_talent) or SpellCooldown(incarnation_caster) > 10 } Spell(celestial_alignment)
	# Cast Starfall if it won't clip a previous Starfall.
	if BuffExpires(starfall_buff) and { BuffPresent(lunar_eclipse_buff) or BuffPresent(celestial_alignment_buff) } Spell(starfall)
	# Cast instant-cast Starsurge.
	if BuffPresent(shooting_stars_buff) and BalanceStarsurgeCondition() Spell(starsurge)
	# Apply and maintain Moonfire and Sunfire on the target.
	BalanceDotActions()
	# Proc Dream of Cenarius with Healing Touch after refreshing DoTs if outside of major CD buffs.
	if TalentPoints(dream_of_cenarius_talent) and BuffExpires(dream_of_cenarius_caster_buff) and BuffExpires(celestial_alignment) and BuffExpires(chosen_of_elune_buff) Spell(healing_touch)
	# Cast Starsurge on cooldown.
	if BalanceStarsurgeCondition() Spell(starsurge)
	# Spam Starfire during Celestial Alignment.
	if BuffPresent(celestial_alignment_buff) and CastTime(starfire) < BuffRemaining(celestial_alignment_buff) Spell(starfire)
	# Cast Wrath as Celestial Alignment is expiring if the cast will finish before the buff expires.
	if BuffPresent(celestial_alignment_buff) and CastTime(wrath) < BuffRemaining(celestial_alignment_buff) Spell(wrath)
	# Cast Starfire if moving toward Solar Eclipse (only if it won't affect Eclipsed Starfall).
	if EclipseDir() > 0 and BalanceStarfireCondition() Spell(starfire)
	# Filler
	Spell(wrath)
}

AddFunction BalanceMovingActions
{
	# Always be in Moonkin form.
	if not Stance(druid_moonkin_form) Spell(moonkin_form)
	# Cast Starfall if it won't clip a previous Starfall.
	if BuffExpires(starfall_buff) and { BuffPresent(lunar_eclipse_buff) or BuffPresent(celestial_alignment_buff) } Spell(starfall)
	# Cast instant-cast Starsurge.
	if BuffPresent(shooting_stars_buff) and BalanceStarsurgeCondition() Spell(starsurge)
	# Apply and maintain Moonfire and Sunfire on the target.
	BalanceDotActions()
	# Plant mushrooms.
	if WildMushroomCount() < 3 Spell(wild_mushroom_caster)
	# Spam Sunfire or Moonfire as filler, depending on the Eclipse state.
	if BuffPresent(solar_eclipse_buff) Spell(sunfire)
	Spell(moonfire)
}

AddFunction BalanceCdActions
{
	InterruptActions()
	if BuffPresent(burst_haste any=1) or target.TimeToDie() <= 40 or BuffPresent(celestial_alignment_buff) UsePotionIntellect()
	if BuffPresent(celestial_alignment_buff) Spell(berserking)
	if BuffPresent(celestial_alignment_buff) or SpellCooldown(celestial_alignment) > 30 UseItemActions()
	if TalentPoints(natures_vigil_talent) and BuffPresent(celestial_alignment_buff) or BuffPresent(chosen_of_elune_buff) Spell(natures_vigil)
}

AddFunction BalanceAoeActions
{
	#wild_mushroom_detonate,moving=0,if=buff.wild_mushroom.stack>0&buff.solar_eclipse.up
	if WildMushroomCount() > 0 and BuffPresent(solar_eclipse_buff) Spell(wild_mushroom_detonate)
	#hurricane,if=active_enemies>4&buff.solar_eclipse.up&buff.natures_grace.up
	if BuffPresent(solar_eclipse_buff) and BuffPresent(natures_grace_buff) Spell(hurricane)
	#hurricane,if=active_enemies>5&buff.solar_eclipse.up&mana.pct>25
	if BuffPresent(solar_eclipse_buff) and ManaPercent() > 25 Spell(hurricane)
}

AddFunction BalanceDefaultShortCdActions
{
	if TalentPoints(force_of_nature_talent) Spell(force_of_nature_caster)
}

AddFunction BalancePrecombatActions
{
	#flask,type=warm_sun
	#food,type=mogu_fish_stew
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int any=1) Spell(mark_of_the_wild)
	#healing_touch,if=!buff.dream_of_cenarius.up&talent.dream_of_cenarius.enabled
	if not BuffPresent(dream_of_cenarius_caster_buff) and TalentPoints(dream_of_cenarius_talent) Spell(healing_touch)
	#moonkin_form
	if not Stance(druid_moonkin_form) Spell(moonkin_form)
	if not { BuffPresent(solar_eclipse_buff) and Eclipse() == 100 } Spell(astral_communion)
	# Snapshot raid buffed stats before combat begins and pre-potting is done.
	#snapshot_stats
}

AddFunction BalancePrecombatMovingActions
{
	unless not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	{
		#wild_mushroom,if=buff.wild_mushroom.stack<buff.wild_mushroom.max_stack
		if WildMushroomCount() < 3 Spell(wild_mushroom_caster)
	}
}

AddFunction BalancePrecombatCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
		or WildMushroomCount() < 3 and Spell(wild_mushroom_caster)
		or not BuffPresent(dream_of_cenarius_caster_buff) and Talent(dream_of_cenarius_talent) and Spell(healing_touch)
		or not Stance(druid_moonkin_form) and Spell(moonkin_form)
	{
		#jade_serpent_potion
		UsePotionIntellect()
	}
}

### Balance Icons
AddIcon specialization=balance help=shortcd
{
	BalanceDefaultShortCdActions()
	BalanceAoeActions()
}

AddIcon specialization=balance help=main
{
	if InCombat(no) BalancePrecombatActions()
	BalanceMainActions()
}

AddIcon specialization=balance help=moving
{
	if InCombat(no) BalancePrecombatMovingActions()
	BalanceMovingActions()
}

AddIcon specialization=balance help=cd
{
	if InCombat(no) BalancePrecombatCdActions()
	BalanceCdActions()
}
]]

	OvaleScripts:RegisterScript("DRUID", name, desc, code, "script")
end
