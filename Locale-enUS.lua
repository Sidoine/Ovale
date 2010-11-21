local defaultLanguage = true
--@debug@
defaultLanguage = false
--@end-debug@

local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("Ovale", "enUS", defaultLanguage)
if not L then return end

--@localization(locale="enUS", format="lua_additive_table", same-key-is-true=true, handle-subnamespaces="concat")@