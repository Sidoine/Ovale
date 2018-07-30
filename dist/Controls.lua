local __exports = LibStub:NewLibrary("ovale/Controls", 80000)
if not __exports then return end
local wipe = wipe
__exports.checkBoxes = {}
__exports.lists = {}
__exports.ResetControls = function()
    wipe(__exports.checkBoxes)
    wipe(__exports.lists)
end
