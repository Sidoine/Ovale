local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.2] Ovale: Frost, Unholy"
	local code = [[
# Ovale death knight script by Sidoine for WoW 5.2.

Include(ovale_items)
Include(ovale_racials)
Include(ovale_deathknight_spells)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

### Frost icons.

AddIcon mastery=frost size=small checkboxon=opt_icons_left {}
AddIcon mastery=frost size=small checkboxon=opt_icons_left {}

AddIcon mastery=frost help=offgcd
{
	if not InCombat()
	{
		Spell(pillar_of_frost)
	}
	Spell(pillar_of_frost)
	if TalentPoints(blood_tap_talent) and BuffStacks(blood_charge) >10 and {RunicPower() >76 or {RunicPower() >=20 and BuffStacks(killing_machine) } } Spell(blood_tap)
	if TalentPoints(blood_tap_talent) and {target.HealthPercent() -{3 *target.HealthPercent() /target.DeadIn() } <=35 and SpellCooldown(soul_reaper_frost) ==0 } Spell(blood_tap)
	if TalentPoints(blood_tap_talent) and {target.HealthPercent() -{3 *target.HealthPercent() /target.DeadIn() } >35 or BuffStacks(blood_charge) >=8 } Spell(blood_tap)
}

AddIcon mastery=frost help=main
{
	if not InCombat()
	{
		unless Stance(2) Spell(frost_presence)
		Spell(horn_of_winter)
	}
	if BuffStacks(killing_machine) or RunicPower() >88 Spell(frost_strike)
	if TalentPoints(plague_leech_talent) and {target.DebuffRemains(blood_plague) <3 or target.DebuffRemains(frost_fever) <3 or SpellCooldown(outbreak) <1 } Spell(plague_leech)
	if target.DebuffRemains(frost_fever) <3 or target.DebuffRemains(blood_plague) <3 Spell(outbreak)
	if target.HealthPercent() -{3 *target.HealthPercent() /target.DeadIn() } <=35 Spell(soul_reaper_frost)
	if not target.DebuffPresent(frost_fever) Spell(howling_blast)
	if not target.DebuffPresent(blood_plague) Spell(plague_strike)
	if BuffStacks(rime) Spell(howling_blast)
	if RunicPower() >76 Spell(frost_strike)
	if RuneCount(unholy) >1 Spell(obliterate)
	if RuneCount(death) >1 or RuneCount(frost) >1 Spell(howling_blast)
	Spell(horn_of_winter)
	if RuneCount(unholy) >0 Spell(obliterate)
	Spell(howling_blast)
	if TalentPoints(runic_empowerment_talent) and {RuneCount(frost) ==0 or RuneCount(blood) ==0 } Spell(frost_strike)
	if TalentPoints(runic_corruption_talent) and BuffExpires(runic_corruption) Spell(frost_strike)
	Spell(death_and_decay)
	if RunicPower() >=40 Spell(frost_strike)
}

AddIcon mastery=frost help=aoe checkboxon=opt_aoe {}

AddIcon mastery=frost help=cd
{
	if not InCombat()
	{
		Spell(army_of_the_dead)
		Spell(blood_fury)
		Spell(raise_dead)
	}
	if target.DeadIn() <=60 and {BuffPresent(mogu_power_potion_aura) or BuffPresent(golems_strength) } Spell(empower_rune_weapon)
	if BuffPresent(pillar_of_frost) UseItemActions()
	Spell(blood_fury)
	Spell(raise_dead)
	if TalentPoints(unholy_blight_talent) and {target.DebuffRemains(frost_fever) <3 or target.DebuffRemains(blood_plague) <3 } Spell(unholy_blight)
	Spell(empower_rune_weapon)
}

AddIcon mastery=frost size=small checkboxon=opt_icons_right {}

AddIcon mastery=frost size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

### Unholy icons.

AddIcon mastery=frost size=small checkboxon=opt_icons_left {}
AddIcon mastery=frost size=small checkboxon=opt_icons_left {}

AddIcon mastery=unholy help=offgcd
{
	if TalentPoints(blood_tap_talent) and BuffStacks(blood_charge) >10 and RunicPower() >=32 Spell(blood_tap)
	if TalentPoints(blood_tap_talent) and {target.HealthPercent() -{3 *target.HealthPercent() /target.DeadIn() } <=35 and SpellCooldown(soul_reaper_unholy) ==0 } Spell(blood_tap)
	if TalentPoints(blood_tap_talent) and BuffStacks(shadow_infusion) ==5 Spell(blood_tap)
	if TalentPoints(blood_tap_talent) and RuneCount(unholy) ==2 and SpellCooldown(death_and_decay) ==0 Spell(blood_tap)
	if TalentPoints(blood_tap_talent) and SpellCooldown(death_and_decay) ==0 Spell(blood_tap)
	if TalentPoints(blood_tap_talent) and BuffStacks(blood_charge) >=8 Spell(blood_tap)
}

AddIcon mastery=unholy help=main
{
	if not InCombat()
	{
		unless Stance(3) Spell(unholy_presence)
		Spell(horn_of_winter)
	}
	if AttackPower() >{LastSpellAttackPower(blood_plague) +5000 } and TimeInCombat() >15 and not {SpellCooldown(unholy_blight) >49 } Spell(outbreak)
	if AttackPower() >{LastSpellAttackPower(blood_plague) +5000 } and TimeInCombat() >15 and not {SpellCooldown(unholy_blight) >49 } Spell(plague_strike)
	if target.DebuffRemains(frost_fever) <3 or target.DebuffRemains(blood_plague) <3 Spell(outbreak)
	if target.HealthPercent() -{3 *target.HealthPercent() /target.DeadIn() } <=35 Spell(soul_reaper_unholy)
	if not target.DebuffPresent(blood_plague) or not target.DebuffPresent(frost_fever) Spell(plague_strike)
	if BuffStacks(shadow_infusion) ==5 Spell(dark_transformation)
	if RunicPower() >90 Spell(death_coil)
	if RuneCount(unholy) ==2 Spell(death_and_decay)
	if RuneCount(unholy) ==2 Spell(scourge_strike)
	if RuneCount(blood) ==2 and RuneCount(frost) ==2 Spell(festering_strike)
	Spell(death_and_decay)
	if BuffStacks(sudden_doom) or {BuffExpires(dark_transformation) and RuneCount(unholy) <=1 } Spell(death_coil)
	Spell(scourge_strike)
	if TalentPoints(plague_leech_talent) and SpellCooldown(outbreak) <1 Spell(plague_leech)
	Spell(festering_strike)
	Spell(horn_of_winter)
	if BuffExpires(dark_transformation) or {SpellCooldown(summon_gargoyle) >8 and BuffRemains(dark_transformation) >8 } Spell(death_coil)
}

AddIcon mastery=unholy help=aoe checkboxon=opt_aoe {}

AddIcon mastery=unholy help=cd
{
	if not InCombat()
	{
		Spell(army_of_the_dead)
		Spell(blood_fury)
		Spell(raise_dead)
	}
	if TimeInCombat() >=2 Spell(blood_fury)
	if TimeInCombat() >=4 Spell(unholy_frenzy)
	if TimeInCombat() >=4 UseItemActions()
	if TalentPoints(unholy_blight_talent) and {target.DebuffRemains(frost_fever) <3 or target.DebuffRemains(blood_plague) <3 } Spell(unholy_blight)
	Spell(summon_gargoyle)
	Spell(empower_rune_weapon)
}

AddIcon mastery=unholy size=small checkboxon=opt_icons_right {}

AddIcon mastery=unholy size=small checkboxon=opt_icons_right
{
	UseItemActions()
}
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code)
end
