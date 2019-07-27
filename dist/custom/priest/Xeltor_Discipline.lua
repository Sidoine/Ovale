local __exports = LibStub:GetLibrary("ovale/scripts/ovale_priest")
if not __exports then return end
__exports.registerPriestDisciplineXeltor = function(OvaleScripts)
do
	local name = "xeltor_discipline"
	local desc = "[Xel][7.1.5] Priest: Discipline"
	local code = [[
# Based on XeltorCraft profile "Priest_Discipline".
#	class=priest
#	spec=discipline
#	talents=3103121

Include(ovale_common)

Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_priest_spells)

Define(atonement 81749)
Define(atonement_buff 194384)
	SpellInfo(atonement_buff duration=19)
#Mindbender: 999123040
Define(shadowfiend 34433)
	SpellInfo(shadowfiend cd=180)
Define(mindbender_talent 12)
Define(mindbender 123040)
	SpellInfo(mindbender cd=60)
Define(penance 47540)
	SpellInfo(penance cd=9)
Define(plea 200829)
	SpellAddBuff(plea atonement_buff)
Define(power_word_solace 129250)
	SpellInfo(power_word_solace haste=spell cd=12)
Define(power_word_radiance 194509)
	SpellAddBuff(power_word_radiance atonement_buff)
Define(power_word_shield 17)
	SpellInfo(power_word_shield haste=spell cd=7.5)
	SpellAddBuff(power_word_shield power_word_shield_buff)
	SpellAddBuff(power_word_shield atonement_buff)
Define(power_word_shield_buff 17)
	SpellInfo(power_word_shield_buff duration=15)
Define(purge_the_wicked 204197)
	SpellAddTargetDebuff(purge_the_wicked purge_the_wicked_debuff=1)
Define(purge_the_wicked_debuff 204213)
	SpellInfo(purge_the_wicked_debuff duration=19)
Define(purge_the_wicked_talent 16)
Define(schism 214621)
	SpellInfo(schism cd=6)
	SpellAddTargetDebuff(schism schism_debuff=1)
Define(schism_debuff 214621)
	SpellInfo(schism_debuff duration=6)
Define(shadow_mend 186263)
	SpellAddBuff(shadow_mend atonement_buff)
Define(shadow_word_pain 589)
	SpellAddTargetDebuff(shadow_word_pain shadow_word_pain_debuff=1)
Define(shadow_word_pain_debuff 589)
	SpellInfo(shadow_word_pain_debuff duration=18 haste=spell tick=6)
Define(smite 585)
Define(pain_suppression 33206)
	SpellInfo(pain_suppression cd=240)
Define(power_infusion 10060)
	SpellInfo(power_infusion cd=120)
Define(lights_wrath 207946)
	SpellInfo(lights_wrath cd=90)

AddIcon specialization=1 help=main
{
	if InCombat() InterruptActions()
	
	if HasFullControl()
	{
		DisciplineDefaultMainActions()
	}
}
AddCheckBox(grouped "Group")

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible() and { target.MustBeInterrupted() or Level() < 100 or target.IsPVP() }
	{
		if not target.Classification(worldboss)
		{
			if target.Distance(less 8) Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			if target.Distance(less 8) Spell(war_stomp)
		}
	}
}

### actions.default

AddFunction DisciplineDefaultMainActions
{
	# Healing rotation.
	if mouseover.Present() and mouseover.IsFriend()
	{
		DisciplineHealing()
	}
	
	# DPS rotation.
	if { not target.IsFriend() and target.Present() and target.Exists() and target.InRange(penance) } or { not focus.IsFriend() and focus.Present() and focus.Exists() and focus.InRange(penance) }
	{
		if InCombat() DisciplineDPS()
	}
}

AddFunction DisciplineHealing
{
	# Pain suppression.
	if mouseover.HealthPercent() <= 25 Spell(pain_suppression)

	# Atonement.
	if mouseover.BuffDuration(atonement_buff) <= CastTime(power_word_radiance) and CheckBoxOn(grouped) and Speed() == 0 Spell(power_word_radiance)
	if mouseover.BuffDuration(atonement_buff) <= GCD() + 1 or mouseover.BuffExpires(power_word_shield_buff) Spell(power_word_shield)
	
	# Healing.
	if mouseover.HealthPercent() < 60
	{
		if Speed() == 0 Spell(power_infusion)
		if BuffCountOnAny(atonement_buff) >= 6 and Speed() == 0 Spell(lights_wrath)
		if BuffCountOnAny(atonement_buff) >= 6 and Speed() == 0 Spell(shadow_mend)
		Spell(plea)
	}
}

AddFunction DisciplineDPS
{
	Spell(shadowfiend)
	
	if not focus.Present() and not focus.Present()
	{
		# Keep atonement up on self
		if BuffDuration(atonement_buff) <= GCD() + 1 or BuffExpires(power_word_shield_buff) Spell(power_word_shield)
		# Purge the Wicked
		if Talent(purge_the_wicked_talent) and { target.DebuffExpires(purge_the_wicked_debuff) or not target.DebuffPresent(purge_the_wicked_debuff) } Spell(purge_the_wicked)
		# Shadow Word: Pain
		if not Talent(purge_the_wicked_talent) and { target.DebuffExpires(shadow_word_pain_debuff) or not target.DebuffPresent(shadow_word_pain_debuff) } Spell(shadow_word_pain)
		# Schism
		if { target.DebuffExpires(schism_debuff) or not target.DebuffPresent(schism_debuff) } and Speed() == 0 Spell(schism)
	}
	if focus.Exists() and focus.Present()
	{
		# Purge the Wicked
		if Talent(purge_the_wicked_talent) and { focus.DebuffExpires(purge_the_wicked_debuff) or not focus.DebuffPresent(purge_the_wicked_debuff) } Spell(purge_the_wicked)
		# Shadow Word: Pain
		if not Talent(purge_the_wicked_talent) and { focus.DebuffExpires(shadow_word_pain_debuff) or not focus.DebuffPresent(shadow_word_pain_debuff) } Spell(shadow_word_pain)
		# Schism
		if { focus.DebuffExpires(schism_debuff) or not focus.DebuffPresent(schism_debuff) } and Speed() == 0 Spell(schism)
	}
	# Penance
	Spell(penance)
	# Power Word: Solace
	Spell(power_word_solace)
	# Artifact
	if BuffCountOnAny(atonement_buff) >= 6 and Speed() == 0 and target.HealthPercent() < 60 Spell(lights_wrath)
	# Smite filler.
	if Speed() == 0 Spell(smite)
}
]]

		OvaleScripts:RegisterScript("PRIEST", "discipline", name, desc, code, "script")
	end
end