local __exports = LibStub:NewLibrary("ovale/engine/controls", 90000)
if not __exports then return end
local wipe = wipe
__exports.checkBoxes = {}
__exports.lists = {}
__exports.ResetControls = function()
    wipe(__exports.checkBoxes)
    wipe(__exports.lists)
end
