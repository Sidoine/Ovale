local __exports = LibStub:GetLibrary("ovale/scripts/ovale_priest")
if not __exports then return end
__exports.registerPriestDisciplineToast = function(OvaleScripts)
do
	local name = "toast_disc"
	local desc = "[Toast][8.2] Priest: Discipline"
	local code = [[
	
	
	]]
	OvaleScripts:RegisterScript("PRIEST", "discipline", name, desc, code, "script")
	end
end