local __scriptsindex = LibStub:GetLibrary("ovale/scripts/index")
local registerScripts = __scriptsindex.registerScripts
local __ioc = LibStub:GetLibrary("ovale/ioc")
local IoC = __ioc.IoC
local ioc = IoC()
registerScripts(ioc.scripts)
