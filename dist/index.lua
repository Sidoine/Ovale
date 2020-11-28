local __exports = LibStub:NewLibrary("ovale", 90000)
if not __exports then return end
local __scriptsindex = LibStub:GetLibrary("ovale/scripts/index")
local registerScripts = __scriptsindex.registerScripts
local __ioc = LibStub:GetLibrary("ovale/ioc")
local IoC = __ioc.IoC
__exports.ioc = IoC()
registerScripts(__exports.ioc.scripts)
