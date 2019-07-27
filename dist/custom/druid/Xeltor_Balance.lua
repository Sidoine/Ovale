local __exports = LibStub:GetLibrary("ovale/scripts/ovale_druid")
if not __exports then return end
__exports.registerDruidBalanceXeltor = function(OvaleScripts)
do
	local name = "xeltor_balance"
	local desc = "[Xel][8.1.5] Druid: Balance"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)
Include(druid_common_functions)

AddIcon specialization=1 help=main
{
	if not mounted() and target.Present() and target.Exists() and not BuffPresent(travel_form)
	{
		if InCombat() or not target.IsFriend() and target.Distance(more 8) Spell(moonkin_form)
	}
	
	if not mounted() and not BuffPresent(travel_form) and not Dead() SaveActions()
	if CheckBoxOn(ap) and not target.Exists() MoveActions()
	
	# Interrupt
	if InCombat() InterruptActions()
	
	if target.InRange(solar_wrath) and HasFullControl() and target.Present() and InCombat()
	{
		# Cooldowns
		if Boss() and { CanMove() > 0 or Speed() == 0 } BalanceDefaultCdActions()
		
		# Short Cooldowns
		if CanMove() > 0 or Speed() == 0 BalanceDefaultShortCdActions()
		
		# Default Actions
		if CanMove() > 0 or Speed() == 0 BalanceDefaultMainActions()
		
		if Speed() > 0
		{
			if not target.DebuffPresent(moonfire_debuff) Spell(moonfire)
			Spell(sunfire)
		}
	}
}
AddCheckBox(ap "Auto-Pilot")

AddFunction InterruptActions
{
 if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
 {
  if target.Distance(less 15) and not target.Classification(worldboss) Spell(typhoon)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(mighty_bash) and not target.Classification(worldboss) Spell(mighty_bash)
  if target.InRange(solar_beam) and target.IsInterruptible() Spell(solar_beam)
 }
}

AddFunction sf_targets
{
 4
}

AddFunction az_ap
{
 AzeriteTraitRank(arcanic_pulsar_trait)
}

AddFunction az_ss
{
 AzeriteTraitRank(streaking_stars_trait)
}

AddFunction BalanceUseItemActions
{
	if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
	if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

### actions.default

AddFunction BalanceDefaultMainActions
{
 #warrior_of_elune
 Spell(warrior_of_elune)
 #force_of_nature,if=(buff.ca_inc.up|cooldown.ca_inc.remains>30)&ap_check
 if { DebuffPresent(ca_inc) or SpellCooldown(ca_inc) > 30 } and AstralPower() >= AstralPowerCost(force_of_nature) Spell(force_of_nature)
 #cancel_buff,name=starlord,if=buff.starlord.remains<3&!solar_wrath.ap_check
 # if BuffRemaining(starlord_buff) < 3 and not AstralPower() >= AstralPowerCost(solar_wrath) and BuffPresent(starlord_buff) Texture(starlord text=cancel)
 #starfall,if=(buff.starlord.stack<3|buff.starlord.remains>=8)&spell_targets>=variable.sf_targets&(target.time_to_die+1)*spell_targets>cost%2.5
 if { BuffStacks(starlord_buff) < 3 or BuffRemaining(starlord_buff) >= 8 } and Enemies() >= sf_targets() and { target.TimeToDie() + 1 } * Enemies() > PowerCost(starfall) / 2.5 Spell(starfall)
 #starsurge,if=(talent.starlord.enabled&(buff.starlord.stack<3|buff.starlord.remains>=5&buff.arcanic_pulsar.stack<8)|!talent.starlord.enabled&(buff.arcanic_pulsar.stack<8|buff.ca_inc.up))&spell_targets.starfall<variable.sf_targets&buff.lunar_empowerment.stack+buff.solar_empowerment.stack<4&buff.solar_empowerment.stack<3&buff.lunar_empowerment.stack<3&(!variable.az_ss|!buff.ca_inc.up|!prev.starsurge)|target.time_to_die<=execute_time*astral_power%40|!solar_wrath.ap_check
 if { Talent(starlord_talent) and { BuffStacks(starlord_buff) < 3 or BuffRemaining(starlord_buff) >= 5 and BuffStacks(arcanic_pulsar_buff) < 8 } or not Talent(starlord_talent) and { BuffStacks(arcanic_pulsar_buff) < 8 or DebuffPresent(ca_inc) } } and Enemies() < sf_targets() and BuffStacks(lunar_empowerment_buff) + BuffStacks(solar_empowerment_buff) < 4 and BuffStacks(solar_empowerment_buff) < 3 and BuffStacks(lunar_empowerment_buff) < 3 and { not az_ss() or not DebuffPresent(ca_inc) or not PreviousSpell(starsurge_balance) } or target.TimeToDie() <= ExecuteTime(starsurge_balance) * AstralPower() / 40 or not AstralPower() >= AstralPowerCost(solar_wrath) Spell(starsurge_balance)
 #sunfire,if=buff.ca_inc.up&buff.ca_inc.remains<gcd.max&variable.az_ss&dot.moonfire.remains>remains
 if DebuffPresent(ca_inc) and DebuffRemaining(ca_inc) < GCD() and az_ss() and target.DebuffRemaining(moonfire_debuff) > target.DebuffRemaining(sunfire_debuff) Spell(sunfire)
 #moonfire,if=buff.ca_inc.up&buff.ca_inc.remains<gcd.max&variable.az_ss
 if DebuffPresent(ca_inc) and DebuffRemaining(ca_inc) < GCD() and az_ss() Spell(moonfire)
 #sunfire,target_if=refreshable,if=ap_check&floor(target.time_to_die%(2*spell_haste))*spell_targets>=ceil(floor(2%spell_targets)*1.5)+2*spell_targets&(spell_targets>1+talent.twin_moons.enabled|dot.moonfire.ticking)&(!variable.az_ss|!buff.ca_inc.up|!prev.sunfire)&(buff.ca_inc.remains>remains|!buff.ca_inc.up)
 if AstralPower() >= AstralPowerCost(sunfire) and target.TimeToDie() / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } } * Enemies() >= 2 / Enemies() * 1.5 + 2 * Enemies() and { Enemies() > 1 + TalentPoints(twin_moons_talent) or target.DebuffPresent(moonfire_debuff) } and { not az_ss() or not DebuffPresent(ca_inc) or not PreviousSpell(sunfire) } and { DebuffRemaining(ca_inc) > target.DebuffRemaining(sunfire_debuff) or not DebuffPresent(ca_inc) } and target.Refreshable(sunfire_debuff) Spell(sunfire)
 #moonfire,target_if=refreshable,if=ap_check&floor(target.time_to_die%(2*spell_haste))*spell_targets>=6&(!variable.az_ss|!buff.ca_inc.up|!prev.moonfire)&(buff.ca_inc.remains>remains|!buff.ca_inc.up)
 if AstralPower() >= AstralPowerCost(moonfire) and target.TimeToDie() / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } } * Enemies() >= 6 and { not az_ss() or not DebuffPresent(ca_inc) or not PreviousSpell(moonfire) } and { DebuffRemaining(ca_inc) > target.DebuffRemaining(moonfire_debuff) or not DebuffPresent(ca_inc) } and target.Refreshable(moonfire_debuff) Spell(moonfire)
 #stellar_flare,target_if=refreshable,if=ap_check&floor(target.time_to_die%(2*spell_haste))>=5&(!variable.az_ss|!buff.ca_inc.up|!prev.stellar_flare)
 if AstralPower() >= AstralPowerCost(stellar_flare) and target.TimeToDie() / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } } >= 5 and { not az_ss() or not DebuffPresent(ca_inc) or not PreviousSpell(stellar_flare) } and target.Refreshable(stellar_flare_debuff) Spell(stellar_flare)
 #new_moon,if=ap_check
 if AstralPower() >= AstralPowerCost(new_moon) and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
 #half_moon,if=ap_check
 if AstralPower() >= AstralPowerCost(half_moon) and SpellKnown(half_moon) Spell(half_moon)
 #full_moon,if=ap_check
 if AstralPower() >= AstralPowerCost(full_moon) and SpellKnown(full_moon) Spell(full_moon)
 #lunar_strike,if=buff.solar_empowerment.stack<3&(ap_check|buff.lunar_empowerment.stack=3)&((buff.warrior_of_elune.up|buff.lunar_empowerment.up|spell_targets>=2&!buff.solar_empowerment.up)&(!variable.az_ss|!buff.ca_inc.up)|variable.az_ss&buff.ca_inc.up&prev.solar_wrath)
 if BuffStacks(solar_empowerment_buff) < 3 and { AstralPower() >= AstralPowerCost(lunar_strike) or BuffStacks(lunar_empowerment_buff) == 3 } and { { BuffPresent(warrior_of_elune_buff) or BuffPresent(lunar_empowerment_buff) or Enemies() >= 2 and not BuffPresent(solar_empowerment_buff) } and { not az_ss() or not DebuffPresent(ca_inc) } or az_ss() and DebuffPresent(ca_inc) and PreviousSpell(solar_wrath_balance) } Spell(lunar_strike)
 #solar_wrath,if=variable.az_ss<3|!buff.ca_inc.up|!prev.solar_wrath
 if az_ss() < 3 or not DebuffPresent(ca_inc) or not PreviousSpell(solar_wrath_balance) Spell(solar_wrath_balance)
 #sunfire
 Spell(sunfire)
}

AddFunction BalanceDefaultMainPostConditions
{
}

AddFunction BalanceDefaultShortCdActions
{
 unless Spell(warrior_of_elune)
 {
  #fury_of_elune,if=(buff.ca_inc.up|cooldown.ca_inc.remains>30)&solar_wrath.ap_check
  if { DebuffPresent(ca_inc) or SpellCooldown(ca_inc) > 30 } and AstralPower() >= AstralPowerCost(solar_wrath) Spell(fury_of_elune)
 }
}

AddFunction BalanceDefaultShortCdPostConditions
{
 Spell(warrior_of_elune) or { DebuffPresent(ca_inc) or SpellCooldown(ca_inc) > 30 } and AstralPower() >= AstralPowerCost(force_of_nature) and Spell(force_of_nature) or { BuffStacks(starlord_buff) < 3 or BuffRemaining(starlord_buff) >= 8 } and Enemies() >= sf_targets() and { target.TimeToDie() + 1 } * Enemies() > PowerCost(starfall) / 2.5 and Spell(starfall) or { { Talent(starlord_talent) and { BuffStacks(starlord_buff) < 3 or BuffRemaining(starlord_buff) >= 5 and BuffStacks(arcanic_pulsar_buff) < 8 } or not Talent(starlord_talent) and { BuffStacks(arcanic_pulsar_buff) < 8 or DebuffPresent(ca_inc) } } and Enemies() < sf_targets() and BuffStacks(lunar_empowerment_buff) + BuffStacks(solar_empowerment_buff) < 4 and BuffStacks(solar_empowerment_buff) < 3 and BuffStacks(lunar_empowerment_buff) < 3 and { not az_ss() or not DebuffPresent(ca_inc) or not PreviousSpell(starsurge_balance) } or target.TimeToDie() <= ExecuteTime(starsurge_balance) * AstralPower() / 40 or not AstralPower() >= AstralPowerCost(solar_wrath) } and Spell(starsurge_balance) or DebuffPresent(ca_inc) and DebuffRemaining(ca_inc) < GCD() and az_ss() and target.DebuffRemaining(moonfire_debuff) > target.DebuffRemaining(sunfire_debuff) and Spell(sunfire) or DebuffPresent(ca_inc) and DebuffRemaining(ca_inc) < GCD() and az_ss() and Spell(moonfire) or AstralPower() >= AstralPowerCost(sunfire) and target.TimeToDie() / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } } * Enemies() >= 2 / Enemies() * 1.5 + 2 * Enemies() and { Enemies() > 1 + TalentPoints(twin_moons_talent) or target.DebuffPresent(moonfire_debuff) } and { not az_ss() or not DebuffPresent(ca_inc) or not PreviousSpell(sunfire) } and { DebuffRemaining(ca_inc) > target.DebuffRemaining(sunfire_debuff) or not DebuffPresent(ca_inc) } and target.Refreshable(sunfire_debuff) and Spell(sunfire) or AstralPower() >= AstralPowerCost(moonfire) and target.TimeToDie() / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } } * Enemies() >= 6 and { not az_ss() or not DebuffPresent(ca_inc) or not PreviousSpell(moonfire) } and { DebuffRemaining(ca_inc) > target.DebuffRemaining(moonfire_debuff) or not DebuffPresent(ca_inc) } and target.Refreshable(moonfire_debuff) and Spell(moonfire) or AstralPower() >= AstralPowerCost(stellar_flare) and target.TimeToDie() / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } } >= 5 and { not az_ss() or not DebuffPresent(ca_inc) or not PreviousSpell(stellar_flare) } and target.Refreshable(stellar_flare_debuff) and Spell(stellar_flare) or AstralPower() >= AstralPowerCost(new_moon) and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPower() >= AstralPowerCost(half_moon) and SpellKnown(half_moon) and Spell(half_moon) or AstralPower() >= AstralPowerCost(full_moon) and SpellKnown(full_moon) and Spell(full_moon) or BuffStacks(solar_empowerment_buff) < 3 and { AstralPower() >= AstralPowerCost(lunar_strike) or BuffStacks(lunar_empowerment_buff) == 3 } and { { BuffPresent(warrior_of_elune_buff) or BuffPresent(lunar_empowerment_buff) or Enemies() >= 2 and not BuffPresent(solar_empowerment_buff) } and { not az_ss() or not DebuffPresent(ca_inc) } or az_ss() and DebuffPresent(ca_inc) and PreviousSpell(solar_wrath_balance) } and Spell(lunar_strike) or { az_ss() < 3 or not DebuffPresent(ca_inc) or not PreviousSpell(solar_wrath_balance) } and Spell(solar_wrath_balance) or Spell(sunfire)
}

AddFunction BalanceDefaultCdActions
{
 # BalanceInterruptActions()
 #potion,if=buff.ca_inc.remains>6&active_enemies=1
 # if DebuffRemaining(ca_inc) > 6 and Enemies() == 1 and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
 #potion,name=battle_potion_of_intellect,if=buff.ca_inc.remains>6
 # if DebuffRemaining(ca_inc) > 6 and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
 #blood_fury,if=buff.ca_inc.up
 if DebuffPresent(ca_inc) Spell(blood_fury)
 #berserking,if=buff.ca_inc.up
 if DebuffPresent(ca_inc) Spell(berserking)
 #arcane_torrent,if=buff.ca_inc.up
 if DebuffPresent(ca_inc) Spell(arcane_torrent_energy)
 #lights_judgment,if=buff.ca_inc.up
 if DebuffPresent(ca_inc) Spell(lights_judgment)
 #fireblood,if=buff.ca_inc.up
 if DebuffPresent(ca_inc) Spell(fireblood)
 #ancestral_call,if=buff.ca_inc.up
 if DebuffPresent(ca_inc) Spell(ancestral_call)
 #use_item,name=balefire_branch,if=equipped.159630&cooldown.ca_inc.remains>30
 if HasEquippedItem(159630) and SpellCooldown(ca_inc) > 30 BalanceUseItemActions()
 #use_item,name=dread_gladiators_badge,if=equipped.161902&cooldown.ca_inc.remains>30
 if HasEquippedItem(161902) and SpellCooldown(ca_inc) > 30 BalanceUseItemActions()
 #use_item,name=azurethos_singed_plumage,if=equipped.161377&cooldown.ca_inc.remains>30
 if HasEquippedItem(161377) and SpellCooldown(ca_inc) > 30 BalanceUseItemActions()
 #use_item,name=tidestorm_codex,if=equipped.165576
 if HasEquippedItem(165576) BalanceUseItemActions()
 #use_items,if=cooldown.ca_inc.remains>30
 if SpellCooldown(ca_inc) > 30 BalanceUseItemActions()

 unless Spell(warrior_of_elune)
 {
  #innervate,if=azerite.lively_spirit.enabled&(cooldown.incarnation.remains<2|cooldown.celestial_alignment.remains<12)
  if HasAzeriteTrait(lively_spirit_trait) and { SpellCooldown(incarnation_chosen_of_elune) < 2 or SpellCooldown(celestial_alignment) < 12 } Spell(innervate)
  #incarnation,if=dot.sunfire.remains>8&dot.moonfire.remains>12&(dot.stellar_flare.remains>6|!talent.stellar_flare.enabled)&ap_check&!buff.ca_inc.up
  if target.DebuffRemaining(sunfire_debuff) > 8 and target.DebuffRemaining(moonfire_debuff) > 12 and { target.DebuffRemaining(stellar_flare_debuff) > 6 or not Talent(stellar_flare_talent) } and AstralPower() >= AstralPowerCost(incarnation_chosen_of_elune) and not DebuffPresent(ca_inc) Spell(incarnation_chosen_of_elune)
  #celestial_alignment,if=astral_power>=40&!buff.ca_inc.up&ap_check&(!azerite.lively_spirit.enabled|buff.lively_spirit.up)&(dot.sunfire.remains>2&dot.moonfire.ticking&(dot.stellar_flare.ticking|!talent.stellar_flare.enabled))
  if AstralPower() >= 40 and not DebuffPresent(ca_inc) and AstralPower() >= AstralPowerCost(celestial_alignment) and { not HasAzeriteTrait(lively_spirit_trait) or BuffPresent(lively_spirit_buff) } and target.DebuffRemaining(sunfire_debuff) > 2 and target.DebuffPresent(moonfire_debuff) and { target.DebuffPresent(stellar_flare_debuff) or not Talent(stellar_flare_talent) } Spell(celestial_alignment)
 }
}

AddFunction BalanceDefaultCdPostConditions
{
 Spell(warrior_of_elune) or { DebuffPresent(ca_inc) or SpellCooldown(ca_inc) > 30 } and AstralPower() >= AstralPowerCost(solar_wrath) and Spell(fury_of_elune) or { DebuffPresent(ca_inc) or SpellCooldown(ca_inc) > 30 } and AstralPower() >= AstralPowerCost(force_of_nature) and Spell(force_of_nature) or { BuffStacks(starlord_buff) < 3 or BuffRemaining(starlord_buff) >= 8 } and Enemies() >= sf_targets() and { target.TimeToDie() + 1 } * Enemies() > PowerCost(starfall) / 2.5 and Spell(starfall) or { { Talent(starlord_talent) and { BuffStacks(starlord_buff) < 3 or BuffRemaining(starlord_buff) >= 5 and BuffStacks(arcanic_pulsar_buff) < 8 } or not Talent(starlord_talent) and { BuffStacks(arcanic_pulsar_buff) < 8 or DebuffPresent(ca_inc) } } and Enemies() < sf_targets() and BuffStacks(lunar_empowerment_buff) + BuffStacks(solar_empowerment_buff) < 4 and BuffStacks(solar_empowerment_buff) < 3 and BuffStacks(lunar_empowerment_buff) < 3 and { not az_ss() or not DebuffPresent(ca_inc) or not PreviousSpell(starsurge_balance) } or target.TimeToDie() <= ExecuteTime(starsurge_balance) * AstralPower() / 40 or not AstralPower() >= AstralPowerCost(solar_wrath) } and Spell(starsurge_balance) or DebuffPresent(ca_inc) and DebuffRemaining(ca_inc) < GCD() and az_ss() and target.DebuffRemaining(moonfire_debuff) > target.DebuffRemaining(sunfire_debuff) and Spell(sunfire) or DebuffPresent(ca_inc) and DebuffRemaining(ca_inc) < GCD() and az_ss() and Spell(moonfire) or AstralPower() >= AstralPowerCost(sunfire) and target.TimeToDie() / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } } * Enemies() >= 2 / Enemies() * 1.5 + 2 * Enemies() and { Enemies() > 1 + TalentPoints(twin_moons_talent) or target.DebuffPresent(moonfire_debuff) } and { not az_ss() or not DebuffPresent(ca_inc) or not PreviousSpell(sunfire) } and { DebuffRemaining(ca_inc) > target.DebuffRemaining(sunfire_debuff) or not DebuffPresent(ca_inc) } and target.Refreshable(sunfire_debuff) and Spell(sunfire) or AstralPower() >= AstralPowerCost(moonfire) and target.TimeToDie() / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } } * Enemies() >= 6 and { not az_ss() or not DebuffPresent(ca_inc) or not PreviousSpell(moonfire) } and { DebuffRemaining(ca_inc) > target.DebuffRemaining(moonfire_debuff) or not DebuffPresent(ca_inc) } and target.Refreshable(moonfire_debuff) and Spell(moonfire) or AstralPower() >= AstralPowerCost(stellar_flare) and target.TimeToDie() / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } } >= 5 and { not az_ss() or not DebuffPresent(ca_inc) or not PreviousSpell(stellar_flare) } and target.Refreshable(stellar_flare_debuff) and Spell(stellar_flare) or AstralPower() >= AstralPowerCost(new_moon) and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPower() >= AstralPowerCost(half_moon) and SpellKnown(half_moon) and Spell(half_moon) or AstralPower() >= AstralPowerCost(full_moon) and SpellKnown(full_moon) and Spell(full_moon) or BuffStacks(solar_empowerment_buff) < 3 and { AstralPower() >= AstralPowerCost(lunar_strike) or BuffStacks(lunar_empowerment_buff) == 3 } and { { BuffPresent(warrior_of_elune_buff) or BuffPresent(lunar_empowerment_buff) or Enemies() >= 2 and not BuffPresent(solar_empowerment_buff) } and { not az_ss() or not DebuffPresent(ca_inc) } or az_ss() and DebuffPresent(ca_inc) and PreviousSpell(solar_wrath_balance) } and Spell(lunar_strike) or { az_ss() < 3 or not DebuffPresent(ca_inc) or not PreviousSpell(solar_wrath_balance) } and Spell(solar_wrath_balance) or Spell(sunfire)
}

### actions.precombat

AddFunction BalancePrecombatMainActions
{
 #flask
 #food
 #augmentation
 #variable,name=az_ss,value=azerite.streaking_stars.rank
 #variable,name=az_ap,value=azerite.arcanic_pulsar.rank
 #variable,name=sf_targets,value=4
 #variable,name=sf_targets,op=add,value=1,if=azerite.arcanic_pulsar.enabled
 #variable,name=sf_targets,op=add,value=1,if=talent.starlord.enabled
 #variable,name=sf_targets,op=add,value=1,if=azerite.streaking_stars.rank>2&azerite.arcanic_pulsar.enabled
 #variable,name=sf_targets,op=sub,value=1,if=!talent.twin_moons.enabled
 #moonkin_form
 Spell(moonkin_form_balance)
 #solar_wrath
 Spell(solar_wrath_balance)
}

AddFunction BalancePrecombatMainPostConditions
{
}

AddFunction BalancePrecombatShortCdActions
{
}

AddFunction BalancePrecombatShortCdPostConditions
{
 Spell(moonkin_form_balance) or Spell(solar_wrath_balance)
}

AddFunction BalancePrecombatCdActions
{
 unless Spell(moonkin_form_balance)
 {
  #snapshot_stats
  #potion
  # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
 }
}

AddFunction BalancePrecombatCdPostConditions
{
 Spell(moonkin_form_balance) or Spell(solar_wrath_balance)
}
]]
		OvaleScripts:RegisterScript("DRUID", "balance", name, desc, code, "script")
	end
end