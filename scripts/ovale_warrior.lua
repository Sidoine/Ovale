local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.2] Ovale: Arms, Fury, Protection"
	local code = [[
# Ovale warrior script by Sidoine for WoW 5.2.

Include(ovale_items)
Include(ovale_racials)
Include(ovale_warrior_spells)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

AddCheckBox(heroic_leap_check SpellName(heroic_leap))
AddCheckBox(sunder_armor_check SpellName(sunder_armor))
AddCheckBox(showwait L(showwait) mastery=fury default)

### Arms icons.

AddIcon mastery=arms size=small checkboxon=opt_icons_left {}
AddIcon mastery=arms size=small checkboxon=opt_icons_left {}

AddIcon mastery=arms help=offgcd
{
	if target.IsInterruptible() Spell(pummel)
	if TalentPoints(bloodbath_talent) and {target.DeadIn() <=18 or BuffPresent(recklessness) or target.DeadIn() >=75 } Spell(bloodbath)
	if BuffExpires(enrage) and Rage() <=Rage() -10 Spell(berserker_rage)
	if target.DebuffPresent(colossus_smash) if CheckBoxOn(heroic_leap_check) Spell(heroic_leap)
	if {target.DebuffPresent(colossus_smash) and Rage() >=Rage() -40 and target.HealthPercent() >=20 } or Rage() >=Rage() -15 Spell(heroic_strike)
}

AddIcon mastery=arms help=main
{
	if not InCombat()
	{
		unless Stance(1) Spell(battle_stance)
	}
	if target.DebuffStacks(weakened_armor any=1) <3 or target.DebuffRemains(weakened_armor any=1) <3 if CheckBoxOn(sunder_armor_check) Spell(sunder_armor)
	Spell(mortal_strike)
	if TalentPoints(dragon_roar_talent) and TalentPoints(bloodbath_talent) and BuffPresent(bloodbath) and target.DebuffExpires(colossus_smash) and target.HealthPercent() >=20 Spell(dragon_roar)
	if TalentPoints(storm_bolt_talent) and target.DebuffPresent(colossus_smash) Spell(storm_bolt)
	if target.DebuffRemains(colossus_smash) <1 Spell(colossus_smash)
	if target.DebuffPresent(colossus_smash) or BuffPresent(recklessness) or Rage() >=Rage() -25 if target.HealthPercent(less 20) Spell(execute)
	if TalentPoints(dragon_roar_talent) and {TalentPoints(bloodbath_talent) and BuffPresent(bloodbath) and target.HealthPercent() >=20 } or {target.DebuffExpires(colossus_smash) and target.HealthPercent() <20 } Spell(dragon_roar)
	if target.DebuffPresent(colossus_smash) and {target.DebuffRemains(colossus_smash) <1 or BuffPresent(recklessness) } and target.HealthPercent() >=20 Spell(slam)
	if BuffStacks(taste_for_blood) >=3 and target.HealthPercent() >=20 Spell(overpower usable=1)
	if target.DebuffPresent(colossus_smash) and target.DebuffRemains(colossus_smash) <2.5 and target.HealthPercent() >=20 Spell(slam)
	if BuffExpires(sudden_execute) if target.HealthPercent(less 20) Spell(execute)
	if target.HealthPercent() >=20 or BuffPresent(sudden_execute) Spell(overpower usable=1)
	if Rage() >=40 and target.HealthPercent() >=20 Spell(slam)
	Spell(battle_shout)
	Spell(heroic_throw)
}

AddIcon mastery=arms help=aoe checkboxon=opt_aoe
{
	Spell(dragon_roar)
	Spell(shockwave)
	Spell(whirlwind)
	Spell(sweeping_strikes)
	if Rage() >=90 Spell(cleave)
	Spell(bloodthirst)
}

AddIcon mastery=arms help=cd
{
	if target.DeadIn() <=18 or {{target.DeadIn() >=186 or {target.HealthPercent() <20 and {target.DebuffRemains(colossus_smash) >=5 or SpellCooldown(colossus_smash) <=1.5 } } } and {not TalentPoints(bloodbath_talent) or not SpellCooldown(bloodbath) } } Spell(recklessness)
	if TalentPoints(avatar_talent) and {BuffPresent(recklessness) or target.DeadIn() <=25 } Spell(avatar)
	if BuffPresent(recklessness) Spell(skull_banner)
	if TalentPoints(bloodbath_talent) and BuffPresent(bloodbath) UseItemActions()
}

AddIcon mastery=arms size=small checkboxon=opt_icons_right {}

AddIcon mastery=arms size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

### Fury icons.

AddIcon mastery=fury size=small checkboxon=opt_icons_left {}
AddIcon mastery=fury size=small checkboxon=opt_icons_left {}

AddIcon mastery=fury help=offgcd
{
	if target.IsInterruptible() Spell(pummel)
	if TalentPoints(bloodbath_talent) and {SpellCooldown(colossus_smash) <2 or target.DebuffRemains(colossus_smash) >=5 or target.DeadIn() <=20 } Spell(bloodbath)
	if not {BuffStacks(enrage) or {BuffStacks(raging_blow_aura) ==2 and target.HealthPercent() >=20 } } or {BuffRemains(recklessness) >=10 and not BuffStacks(raging_blow_aura) } Spell(berserker_rage)
	if target.DebuffPresent(colossus_smash) if CheckBoxOn(heroic_leap_check) Spell(heroic_leap)
	if {{target.DebuffPresent(colossus_smash) and Rage() >=40 } and target.HealthPercent() >=20 } or Rage() >=110 Spell(heroic_strike)
}

AddIcon mastery=fury help=main
{
	if not InCombat()
	{
		unless Stance(1) Spell(battle_stance)
	}
	if target.DebuffStacks(weakened_armor any=1) <3 or target.DebuffRemains(weakened_armor any=1) <3 if CheckBoxOn(sunder_armor_check) Spell(sunder_armor)
	if BuffStacks(raging_blow_aura) ==2 and target.DebuffPresent(colossus_smash) and target.HealthPercent() >=20 Spell(raging_blow)
	if not {target.HealthPercent() <20 and target.DebuffPresent(colossus_smash) and Rage() >=30 } Spell(bloodthirst)
	if BuffStacks(bloodsurge) and target.HealthPercent() >=20 and SpellCooldown(bloodthirst) <=1 Spell(wild_strike)
	if not {target.HealthPercent() <20 and target.DebuffPresent(colossus_smash) and Rage() >=30 } and SpellCooldown(bloodthirst) <=1 and SpellCooldown(bloodthirst) if CheckBoxOn(showwait) Texture(Spell_nature_timestop)
	if TalentPoints(dragon_roar_talent) and {not target.DebuffPresent(colossus_smash) and {BuffPresent(bloodbath) or not TalentPoints(bloodbath_talent) } } Spell(dragon_roar)
	Spell(colossus_smash)
	if BuffPresent(enrage) or target.DebuffPresent(colossus_smash) or Rage() >90 or target.DeadIn() <12 or BuffPresent(recklessness) if target.HealthPercent(less 20) Spell(execute)
	if TalentPoints(storm_bolt_talent) Spell(storm_bolt)
	if BuffStacks(raging_blow_aura) ==2 or {BuffPresent(raging_blow_aura) and {target.DebuffPresent(colossus_smash) or SpellCooldown(colossus_smash) >=3 or {SpellCooldown(bloodthirst) >=1 and BuffRemains(raging_blow_aura) <=3 } } } Spell(raging_blow)
	if BuffStacks(bloodsurge) Spell(wild_strike)
	if TalentPoints(shockwave_talent) Spell(shockwave)
	if target.DebuffExpires(colossus_smash) Spell(heroic_throw)
	if Rage() <70 and not target.DebuffPresent(colossus_smash) Spell(battle_shout)
	if target.DebuffPresent(colossus_smash) and target.HealthPercent() >=20 Spell(wild_strike)
	if TalentPoints(impending_victory_talent) and target.HealthPercent() >=20 Spell(impending_victory)
	if SpellCooldown(colossus_smash) >=2 and Rage() >=80 and target.HealthPercent() >=20 Spell(wild_strike)
	if Rage() <70 Spell(battle_shout)
}

AddIcon mastery=fury help=aoe checkboxon=opt_aoe
{

	Spell(dragon_roar)
	Spell(shockwave)
	if BuffStacks(meat_cleaver) and BuffStacks(raging_blow_aura) Spell(raging_blow)
	Spell(whirlwind)
	if Rage() >=90 Spell(cleave)
	Spell(bloodthirst)

}

AddIcon mastery=fury help=cd
{
	if {TalentPoints(avatar_talent) and {SpellCooldown(colossus_smash) <2 or target.DebuffRemains(colossus_smash) >=5 } } or {TalentPoints(bloodbath_talent) and {BuffPresent(bloodbath) and {target.DeadIn() >192 or target.HealthPercent() <20 } } } or target.DeadIn() <=12 Spell(recklessness)
	if BuffPresent(recklessness) and TalentPoints(avatar_talent) Spell(avatar)
	if BuffPresent(recklessness) Spell(skull_banner)
	if {not TalentPoints(bloodbath_talent) and target.DebuffPresent(colossus_smash) } or {TalentPoints(bloodbath_talent) and BuffPresent(bloodbath) } UseItemActions()
}

AddIcon mastery=fury size=small checkboxon=opt_icons_right {}

AddIcon mastery=fury size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

### Protection icons.

AddIcon mastery=protection size=small checkboxon=opt_icons_left {}
AddIcon mastery=protection size=small checkboxon=opt_icons_left {}

AddIcon mastery=protection help=offgcd
{
	if target.IsInterruptible() Spell(pummel)
	if {BuffPresent(ultimatum) and target.HealthPercent() >=20 } Spell(heroic_strike)
	if Rage() <90 Spell(berserker_rage)
	if BuffExpires(shield_block_aura) Spell(shield_block)
	if BuffExpires(shield_barrier) and Rage() >80 Spell(shield_barrier)
	Spell(demoralizing_shout)
}

AddIcon mastery=protection help=main
{
	if not InCombat()
	{
		unless Stance(2) Spell(defensive_stance)
	}
	if Rage() <80 Spell(shield_slam)
	if Rage() <85 Spell(revenge)
	if Rage() <90 Spell(battle_shout)
	if target.DebuffExpires(weakened_blows) Spell(thunder_clap)
	if target.HealthPercent(less 20) Spell(execute)
	Spell(devastate)
}

AddIcon mastery=protection help=aoe checkboxon=opt_aoe
{
	Spell(dragon_roar)
	Spell(shockwave)
	Spell(thunder_clap)
	if BuffPresent(ultimatum) Spell(cleave)
	if Rage() >=90 Spell(cleave)
	Spell(shield_slam)
}

AddIcon mastery=protection help=cd
{
	if Health() <130000 Spell(last_stand)
	if TalentPoints(avatar_talent) Spell(avatar)
	Spell(recklessness)
	if BuffExpires(shield_block_aura) Spell(shield_wall)
	UseItemActions()
}

AddIcon mastery=protection size=small checkboxon=opt_icons_right {}

AddIcon mastery=protection size=small checkboxon=opt_icons_right
{
	UseItemActions()
}
]]

	OvaleScripts:RegisterScript("WARRIOR", name, desc, code)
end
