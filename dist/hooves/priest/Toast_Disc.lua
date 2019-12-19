local __exports = LibStub:GetLibrary("ovale/scripts/ovale_priest")
if not __exports then return end
__exports.registerPriestDisciplineToast = function(OvaleScripts)
do
	local name = "toast_disc"
	local desc = "[Toast][8.2] Priest: Discipline"
	local code = [[
	Include(ovale_common)
	Include(ovale_trinkets_mop)
	Include(ovale_trinkets_wod)
	Include(ovale_priest_spells)
	
	AddIcon specialization=1 help=main
	{
		#dmg rotation
		if (Talent(purge_the_wicked_talent) and not target.DebuffPresent(purge_the_wicked_debuff)) Spell(purge_the_wicked)
		if not Talent(purge_the_wicked_talent) and target.DebuffPresent(shadow_word_pain_debuff) Spell(shadow_word_pain)
		if (Speed() == 0) Spell(schism)
		Spell(penance)
		Spell(power_word_solace)
		if (Speed() == 0) Spell(smite)
		Spell(purge_the_wicked)
	
		#shield target
	
	}
	
	]]
	OvaleScripts:RegisterScript("PRIEST", "discipline", name, desc, code, "script")
	end
end