local MAJOR_VERSION = "LibInterrupt-1.0"
local MINOR_VERSION = 2

local lib, oldminor = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then
    return
end

-- Open global interrupt table.
local InterruptTable = {}
_G["InterruptTable"] = InterruptTable

function lib:HasManagedInterrupts(target)
	-- Get target name.
	local targetName = UnitName(target)
	
	-- Is the target on the interrupt table?
	local boolean = InterruptTable[targetName] ~= nil and InterruptTable[targetName]
	
	if boolean then
		-- Yes.
		return true
	else
		-- No.
		return false
	end
end

function lib:MustInterrupt(target)
	-- Get target name.
	local targetName = UnitName(target)
	
	-- Get cast / channel info.
	local spellName, _, _, _, _, _, _, notInterruptible, _ = UnitCastingInfo(target)
	if not spellName then
		spellName, _, _, _, _, _, notInterruptible = UnitChannelInfo(target)
	end
	
	-- Do we stop it?
	local interruptable = notInterruptible ~= nil and not notInterruptible
	local boolean = InterruptTable[targetName] ~= nil and InterruptTable[targetName][spellName] ~= nil and InterruptTable[targetName][spellName]
	
	if boolean and interruptable then
		-- Yes
		return true
	else
		-- No
		return false
	end
end
