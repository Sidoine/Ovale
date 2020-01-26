local __exports = LibStub:NewLibrary("ovale", 80300)
if not __exports then return end
local __scriptsindex = LibStub:GetLibrary("ovale/scripts/index")
local registerScripts = __scriptsindex.registerScripts
local __customindex = LibStub:GetLibrary("ovale/custom/index")
local customScripts = __customindex.registerScripts
local __hoovesindex = LibStub:GetLibrary("ovale/hooves/index")
local hoovesScripts = __hoovesindex.registerScripts
local __spellhelpersindex = LibStub:GetLibrary("ovale/spellhelpers/index")
local spellhelperScripts = __spellhelpersindex.registerScripts
local __ioc = LibStub:GetLibrary("ovale/ioc")
local IoC = __ioc.IoC
__exports.ioc = IoC()
registerScripts(__exports.ioc.scripts)
customScripts(__exports.ioc.scripts)
hoovesScripts(__exports.ioc.scripts)
spellhelperScripts(__exports.ioc.scripts)
