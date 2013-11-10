local defaultLanguage = false
--@debug@
defaultLanguage = true
--@end-debug@

local L = LibStub:GetLibrary("AceLocale-3.0"):NewLocale("Ovale", "frFR", defaultLanguage, true)
if not L then return end

--@localization(locale="frFR", format="lua_additive_table", same-key-is-true=true, handle-subnamespaces="concat")@
