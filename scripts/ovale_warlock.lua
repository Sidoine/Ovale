local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.2] Ovale: Affliction, Demonology, Destruction"
	local code = [[
# Ovale warlock script by Sidoine for WoW 5.2.

Include(ovale_items)
Include(ovale_racials)
Include(ovale_warlock_spells)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

### Affliction icons.

AddIcon mastery=affliction size=small checkboxon=opt_icons_left {}
AddIcon mastery=affliction size=small checkboxon=opt_icons_left {}

AddIcon mastery=affliction help=offgcd
{
	if not InCombat()
	{
		if TalentPoints(grimoire_of_sacrifice_talent) Spell(grimoire_of_sacrifice)
	}
	if BuffPresent(dark_soul_misery) and {target.TicksRemain(agony) <=Ticks(agony) /2 or target.TicksRemain(corruption_debuff) <=Ticks(corruption_debuff) /2 or target.TicksRemain(unstable_affliction) <=Ticks(unstable_affliction) /2 } and SoulShards() Spell(soulburn)
	if {target.TicksRemain(unstable_affliction) <=1 or target.TicksRemain(corruption_debuff) <=1 or target.TicksRemain(agony) <=1 } and SoulShards() and target.HealthPercent() <=20 Spell(soulburn)
	if SpellPower() >LastSpellSpellPower(unstable_affliction) and target.TicksRemain(unstable_affliction) <=Ticks(unstable_affliction) /2 and SoulShards() and target.HealthPercent() <=20 Spell(soulburn)
}

AddIcon mastery=affliction help=main
{
	if not InCombat()
	{
		if not BuffPresent(spell_power_multiplier any=1) Spell(dark_intent)
		if not TalentPoints(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice) unless pet.CreatureFamily(Felhunter) Spell(summon_felhunter)
		if TalentPoints(grimoire_of_service_talent) Spell(service_felhunter)
	}
	if target.DebuffExpires(magic_vulnerability any=1) Spell(curse_of_the_elements)
	if TalentPoints(grimoire_of_service_talent) Spell(service_felhunter)
	if BuffPresent(soulburn) Spell(soul_swap)
	if not InFlightToTarget(haunt) and target.DebuffRemains(haunt) <CastTime(haunt) +1 +TickTime(haunt) and SoulShards() and target.HealthPercent() <=20 Spell(haunt)
	if BuffExpires(dark_soul_misery) and BuffExpires(bloodlust any=1) and ManaPercent() <10 and target.HealthPercent() <=20 Spell(life_tap)
	if target.HealthPercent() <=20 Spell(drain_soul)
	if target.HealthPercent() <=20 Spell(life_tap)
	if target.DebuffRemains(agony) <GCD() and target.DebuffRemains(agony) +2 <SpellCooldown(dark_soul_misery) Spell(agony)
	if not InFlightToTarget(haunt) and target.DebuffRemains(haunt) <CastTime(haunt) +1 +TickTime(haunt) and {SoulShards() >2 or SpellCooldown(dark_soul_misery) >35 or {SoulShards() >1 and SpellCooldown(dark_soul_misery) <CastTime(haunt) } } and SoulShards() Spell(haunt)
	if target.DebuffRemains(corruption_debuff) <GCD() and target.DebuffRemains(corruption_debuff) <SpellCooldown(dark_soul_misery) Spell(corruption)
	if target.DebuffRemains(unstable_affliction) <GCD() +CastTime(unstable_affliction) and target.DebuffRemains(unstable_affliction) <SpellCooldown(dark_soul_misery) Spell(unstable_affliction)
	if target.TicksRemain(agony) <=2 and target.DebuffRemains(agony) +2 <SpellCooldown(dark_soul_misery) Spell(agony)
	if target.TicksRemain(corruption_debuff) <=2 and target.DebuffRemains(corruption_debuff) <SpellCooldown(dark_soul_misery) Spell(corruption)
	if {target.DebuffRemains(unstable_affliction) -CastTime(unstable_affliction) } /{BuffDuration(unstable_affliction) /Ticks(unstable_affliction) } <=2 and target.DebuffRemains(unstable_affliction) <SpellCooldown(dark_soul_misery) Spell(unstable_affliction)
	if SpellPower() >LastSpellSpellPower(agony) and target.TicksRemain(agony) <Ticks(agony) /2 and target.DebuffRemains(agony) +2 <SpellCooldown(dark_soul_misery) Spell(agony)
	if SpellPower() >LastSpellSpellPower(corruption_debuff) and target.TicksRemain(corruption_debuff) <Ticks(corruption_debuff) /2 and target.DebuffRemains(corruption_debuff) <SpellCooldown(dark_soul_misery) Spell(corruption)
	if SpellPower() >LastSpellSpellPower(unstable_affliction) and target.TicksRemain(unstable_affliction) <Ticks(unstable_affliction) /2 and target.DebuffRemains(unstable_affliction) <SpellCooldown(dark_soul_misery) Spell(unstable_affliction)
	if BuffExpires(dark_soul_misery) and BuffExpires(bloodlust any=1) and ManaPercent() <50 Spell(life_tap)
	Spell(malefic_grasp)
	Spell(life_tap)
}

AddIcon mastery=affliction help=aoe checkboxon=opt_aoe
{
	if BuffExpires(soulburn) and not target.DebuffPresent(soulburn_seed_of_corruption) and not InFlightToTarget(soulburn_seed_of_corruption) and SoulShards() Spell(soulburn)
	if BuffPresent(soulburn) and not target.DebuffPresent(agony) and not target.DebuffPresent(corruption_debuff) Spell(soul_swap)
	if BuffPresent(soulburn) and target.DebuffPresent(corruption_debuff) and not target.DebuffPresent(agony) Spell(soul_swap)
	if {BuffExpires(soulburn) and not InFlightToTarget(seed_of_corruption) and not target.DebuffPresent(seed_of_corruption) } or {BuffPresent(soulburn) and not target.DebuffPresent(soulburn_seed_of_corruption) and not InFlightToTarget(soulburn_seed_of_corruption) } Spell(seed_of_corruption)
	if not InFlightToTarget(haunt) and target.DebuffRemains(haunt) <CastTime(haunt) +1 and SoulShards() Spell(haunt)
	if ManaPercent() <70 Spell(life_tap)
	if not InFlightToTarget(fel_flame) Spell(fel_flame)
}

AddIcon mastery=affliction help=cd
{
	UseItemActions()
	Spell(blood_fury)
	Spell(dark_soul_misery)
	Spell(summon_doomguard)
}

AddIcon mastery=affliction size=small checkboxon=opt_icons_right {}

AddIcon mastery=affliction size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

### Demonology icons.

AddIcon mastery=demonology size=small checkboxon=opt_icons_left {}
AddIcon mastery=demonology size=small checkboxon=opt_icons_left {}

AddIcon mastery=demonology help=offgcd
{
	if not InCombat()
	{
		if TalentPoints(grimoire_of_sacrifice_talent) Spell(grimoire_of_sacrifice)
	}
	Spell(melee)
	Spell(felstorm)
	Spell(wrathstorm)
	if {BuffPresent(dark_soul_knowledge) and DemonicFury() /32 >BuffRemains(dark_soul_knowledge) } or target.DebuffRemains(corruption_debuff) <5 or not target.DebuffPresent(doom) or DemonicFury() >=950 or DemonicFury() /32 >target.DeadIn() unless Stance(1) Spell(metamorphosis)
}

AddIcon mastery=demonology help=main
{
	if not InCombat()
	{
		if not BuffPresent(spell_power_multiplier any=1) Spell(dark_intent)
		if not TalentPoints(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice) unless pet.CreatureFamily(Felguard) Spell(summon_felguard)
		if TalentPoints(grimoire_of_service_talent) Spell(service_felguard)
	}
	if target.DebuffExpires(magic_vulnerability any=1) Spell(curse_of_the_elements)
	if TalentPoints(grimoire_of_service_talent) Spell(service_felguard)
	if BuffPresent(metamorphosis) and target.DebuffPresent(corruption_debuff) and target.DebuffRemains(corruption_debuff) <1.5 Spell(touch_of_chaos)
	if BuffPresent(metamorphosis) and {target.TicksRemain(doom) <=1 or {target.TicksRemain(doom) +1 <Ticks(doom) and BuffPresent(dark_soul_knowledge) } } and target.DeadIn() >=30 Spell(doom)
	if BuffPresent(metamorphosis) and target.DebuffPresent(corruption_debuff) and target.DebuffRemains(corruption_debuff) <20 Spell(touch_of_chaos)
	if BuffPresent(metamorphosis) and BuffExpires(dark_soul_knowledge) and DemonicFury() <=650 and target.DeadIn() >30 if Stance(1) cancel.Texture(Spell_shadow_demonform)
	if BuffPresent(metamorphosis) and BuffStacks(molten_core) and {BuffRemains(dark_soul_knowledge) <CastTime(shadow_bolt) or BuffRemains(dark_soul_knowledge) >CastTime(soul_fire) } Spell(soul_fire)
	if BuffPresent(metamorphosis) Spell(touch_of_chaos)
	if not target.DebuffPresent(corruption_debuff) and target.DeadIn() >=6 Spell(corruption)
	if not InFlightToTarget(hand_of_guldan) and target.DebuffRemains(shadowflame) <1 +CastTime(shadow_bolt) Spell(hand_of_guldan)
	if BuffStacks(molten_core) and {BuffRemains(dark_soul_knowledge) <CastTime(shadow_bolt) or BuffRemains(dark_soul_knowledge) >CastTime(soul_fire) } Spell(soul_fire)
	if ManaPercent() <60 Spell(life_tap)
	Spell(shadow_bolt)
	Spell(life_tap)
}

AddIcon mastery=demonology help=aoe checkboxon=opt_aoe
{
	if BuffPresent(metamorphosis) and target.DebuffRemains(corruption_debuff) >10 and DemonicFury() <=650 and BuffExpires(dark_soul_knowledge) and not target.DebuffPresent(immolation_aura) if Stance(1) cancel.Texture(Spell_shadow_demonform)
	if BuffPresent(metamorphosis) Spell(immolation_aura)
	if BuffPresent(metamorphosis) and target.DebuffRemains(corruption_debuff) <10 Spell(void_ray)
	if BuffPresent(metamorphosis) and {not target.DebuffPresent(doom) or target.DebuffRemains(doom) <TickTime(doom) or {target.TicksRemain(doom) +1 <Ticks(doom) and BuffPresent(dark_soul_knowledge) } } and target.DeadIn() >=30 Spell(doom)
	if BuffPresent(metamorphosis) Spell(void_ray)
	if not target.DebuffPresent(corruption_debuff) and target.DeadIn() >30 Spell(corruption)
	Spell(hand_of_guldan)
	if target.DebuffRemains(corruption_debuff) <10 or BuffPresent(dark_soul_knowledge) or DemonicFury() >=950 or DemonicFury() /32 >target.DeadIn() unless Stance(1) Spell(metamorphosis)
	Spell(hellfire)
	Spell(life_tap)
}

AddIcon mastery=demonology help=cd
{
	UseItemActions()
	Spell(blood_fury)
	Spell(dark_soul_knowledge)
	Spell(summon_doomguard)
}

AddIcon mastery=demonology size=small checkboxon=opt_icons_right {}

AddIcon mastery=demonology size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

### Destruction icons.

AddIcon mastery=destruction size=small checkboxon=opt_icons_left {}
AddIcon mastery=destruction size=small checkboxon=opt_icons_left {}

AddIcon mastery=destruction help=offgcd
{
	if not InCombat()
	{
		if TalentPoints(grimoire_of_sacrifice_talent) Spell(grimoire_of_sacrifice)
	}
}

AddIcon mastery=destruction help=main
{
	if not InCombat()
	{
		if not BuffPresent(spell_power_multiplier any=1) Spell(dark_intent)
		if not TalentPoints(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice) unless pet.CreatureFamily(Felhunter) Spell(summon_felhunter)
		if TalentPoints(grimoire_of_service_talent) Spell(service_felhunter)
	}
	if target.DebuffExpires(magic_vulnerability any=1) Spell(curse_of_the_elements)
	if TalentPoints(grimoire_of_service_talent) Spell(service_felhunter)
	if BurningEmbers() if target.HealthPercent(less 20) Spell(shadowburn)
	if {target.TicksRemain(immolate_debuff) <Ticks(immolate_debuff) /2 or target.DebuffExpires(immolate_debuff) } and target.DeadIn() >=5 Spell(immolate)
	if Charges(conflagrate) ==2 Spell(conflagrate)
	if not target.DebuffPresent(rain_of_fire_aftermath) and not InFlightToTarget(rain_of_fire_aftermath) Spell(rain_of_fire_aftermath)
	if BurningEmbers() and {BuffStacks(backdraft) <3 or Level() <86 } and {{BurningEmbers() / 10} >3.5 or BuffRemains(dark_soul_instability) >CastTime(chaos_bolt) or BuffRemains(skull_banner) >CastTime(chaos_bolt) } Spell(chaos_bolt)
	Spell(conflagrate)
	Spell(incinerate)
}

AddIcon mastery=destruction help=aoe checkboxon=opt_aoe
{
	if not target.DebuffPresent(rain_of_fire_aftermath) and not InFlightToTarget(rain_of_fire_aftermath) Spell(rain_of_fire_aftermath)
	if {BurningEmbers() / 10} >=3.5 and BurningEmbers() and target.HealthPercent() <=20 focus.Spell(havoc)
	if {BurningEmbers() / 10} >=3.5 and BurningEmbers() and BuffStacks(havoc) >=1 if target.HealthPercent(less 20) Spell(shadowburn)
	if BurningEmbers() and BuffExpires(fire_and_brimstone) Spell(fire_and_brimstone)
	if BuffPresent(fire_and_brimstone) and not target.DebuffPresent(immolate_debuff) Spell(immolate)
	if BuffPresent(fire_and_brimstone) Spell(conflagrate)
	if BuffPresent(fire_and_brimstone) Spell(incinerate)
	if not target.DebuffPresent(immolate_debuff) Spell(immolate)

	if not target.DebuffPresent(rain_of_fire_aftermath) and not InFlightToTarget(rain_of_fire_aftermath) Spell(rain_of_fire_aftermath)
	focus.Spell(havoc)
}

AddIcon mastery=destruction help=cd
{
	UseItemActions()
	Spell(blood_fury)
	Spell(dark_soul_instability)
	Spell(summon_doomguard)
}

AddIcon mastery=destruction size=small checkboxon=opt_icons_right {}

AddIcon mastery=destruction size=small checkboxon=opt_icons_right
{
	UseItemActions()
}
]]

	OvaleScripts:RegisterScript("WARLOCK", name, desc, code)
end
