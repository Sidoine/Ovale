local __scriptsindex = LibStub:GetLibrary("ovale/scripts/index")
local registerScripts = __scriptsindex.registerScripts
local __customindex = LibStub:GetLibrary("ovale/custom/index")
local customScripts = __customindex.registerScripts
local __spellhelpersindex = LibStub:GetLibrary("ovale/spellhelpers/index")
local spellhelperScripts = __spellhelpersindex.registerScripts
local __ioc = LibStub:GetLibrary("ovale/ioc")
local IoC = __ioc.IoC
local ioc = IoC()
registerScripts(ioc.scripts)
customScripts(ioc.scripts)
spellhelperScripts(ioc.scripts)