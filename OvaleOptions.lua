--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- Ovale options and UI

local _, Ovale = ...
local OvaleOptions = Ovale:NewModule("OvaleOptions", "AceConsole-3.0", "AceEvent-3.0")
Ovale.OvaleOptions = OvaleOptions

--<private-static-properties>
local L = Ovale.L

-- Forward declarations for module dependencies.
local OvaleScripts = nil
local OvaleSpellBook = nil
local OvaleState = nil

local strgmatch = string.gmatch
local strgsub = string.gsub
local tostring = tostring
local API_GetSpellInfo = GetSpellInfo
local API_UnitClass = UnitClass

-- Player's class.
local self_class = select(2, API_UnitClass("player"))
--</private-static-properties>

--<public-static-properties>
OvaleOptions.db = nil
--</public-static-properties>

--<private-static-properties>
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LibDualSpec = LibStub("LibDualSpec-1.0",true)
	
--GUI option
local self_options = 
{ 
	type = "group",
	args = 
	{
		apparence =
		{
			name = L["Apparence"],
			type = "group",
			args =
			{
				verrouille =
				{
					order = 10,
					type = "toggle",
					name = L["Verrouiller position"],
					get = function(info) return OvaleOptions.db.profile.apparence.verrouille end,
					set = function(info, value) OvaleOptions.db.profile.apparence.verrouille = value end
				},
				clickThru =
				{
					order = 20,
					type = "toggle",
					name = L["Ignorer les clics souris"],
					get = function(info) return OvaleOptions.db.profile.apparence.clickThru end,
					set = function(info, value) OvaleOptions.db.profile.apparence.clickThru = value; Ovale:UpdateFrame() end
				},
				visibility =
				{
					order = 30,
					type = "group",
					name = L["Visibilité"],
					args =
					{
						combatUniquement =
						{
							order = 10,
							type = "toggle",
							name = L["En combat uniquement"],
							get = function(info) return OvaleOptions.db.profile.apparence.enCombat end,
							set = function(info, v) OvaleOptions.db.profile.apparence.enCombat = v; Ovale:UpdateVisibility() end,
						},
						targetOnly =
						{
							order = 20,
							type = "toggle",
							name = L["Si cible uniquement"],
							get = function(info) return OvaleOptions.db.profile.apparence.avecCible end,
							set = function(info, v) OvaleOptions.db.profile.apparence.avecCible = v; Ovale:UpdateVisibility() end,
						},
						targetHostileOnly =
						{
							order = 30,
							type = "toggle",
							name = L["Cacher si cible amicale ou morte"],
							get = function(info) return OvaleOptions.db.profile.apparence.targetHostileOnly end,
							set = function(info, value) OvaleOptions.db.profile.apparence.targetHostileOnly = value; Ovale:UpdateFrame() end
						},
						hideVehicule =
						{
							order = 40,
							type = "toggle",
							name = L["Cacher dans les véhicules"],
							get = function(info) return OvaleOptions.db.profile.apparence.hideVehicule end,
							set = function(info, value) OvaleOptions.db.profile.apparence.hideVehicule = value end
						},
						hideEmpty =
						{
							order = 50,
							type = "toggle",
							name = L["Cacher bouton vide"],
							get = function(info) return OvaleOptions.db.profile.apparence.hideEmpty end,
							set = function(info, value) OvaleOptions.db.profile.apparence.hideEmpty = value; Ovale:UpdateFrame() end
						},
					},
				},
				iconAppearance =
				{
					order = 40,
					type = "group",
					name = L["Icône"],
					args =
					{
						iconScale =
						{
							order = 10,
							type = "range",
							name = L["Taille des icônes"],
							desc = L["La taille des icônes"],
							min = 0.1, max = 16, step = 0.1,
							get = function(info) return OvaleOptions.db.profile.apparence.iconScale end,
							set = function(info,value) OvaleOptions.db.profile.apparence.iconScale = value; Ovale:UpdateFrame() end
						},
						smallIconScale =
						{
							order = 20,
							type = "range",
							name = L["Taille des petites icônes"],
							desc = L["La taille des petites icônes"],
							min = 0.1, max = 16, step = 0.1,
							get = function(info) return OvaleOptions.db.profile.apparence.smallIconScale end,
							set = function(info,value) OvaleOptions.db.profile.apparence.smallIconScale = value; Ovale:UpdateFrame() end
						},
						fontScale =
						{
							order = 30,
							type = "range",
							name = L["Taille des polices"],
							desc = L["La taille des polices"],
							min = 0.1, max = 2, step = 0.1,
							get = function(info) return OvaleOptions.db.profile.apparence.fontScale end,
							set = function(info,value) OvaleOptions.db.profile.apparence.fontScale = value; Ovale:UpdateFrame() end
						},
						alpha =
						{
							order = 40,
							type = "range",
							name = L["Opacité des icônes"],
							min = 0, max = 100, step = 5,
							get = function(info) return OvaleOptions.db.profile.apparence.alpha * 100 end,
							set = function(info, value) OvaleOptions.db.profile.apparence.alpha = value/100; Ovale.frame.frame:SetAlpha(value/100) end
						},
						raccourcis =
						{
							order = 50,
							type = "toggle",
							name = L["Raccourcis clavier"],
							desc = L["Afficher les raccourcis clavier dans le coin inférieur gauche des icônes"],
							get = function(info) return OvaleOptions.db.profile.apparence.raccourcis end,
							set = function(info, value) OvaleOptions.db.profile.apparence.raccourcis = value end
						},
						numeric =
						{
							order = 60,
							type = "toggle",
							name = L["Affichage numérique"],
							desc = L["Affiche le temps de recharge sous forme numérique"],
							get = function(info) return OvaleOptions.db.profile.apparence.numeric end,
							set = function(info, value) OvaleOptions.db.profile.apparence.numeric = value end
						},
						highlightIcon =
						{
							order = 70,
							type = "toggle",
							name = L["Illuminer l'icône"],
							desc = L["Illuminer l'icône quand la technique doit être spammée"],
							get = function(info) return OvaleOptions.db.profile.apparence.highlightIcon end,
							set = function(info, value) OvaleOptions.db.profile.apparence.highlightIcon = value; Ovale:UpdateFrame() end
						},
						flashIcon =
						{
							order = 80,
							type = "toggle",
							name = L["Illuminer l'icône quand le temps de recharge est écoulé"],
							get = function(info) return OvaleOptions.db.profile.apparence.flashIcon end,
							set = function(info, value) OvaleOptions.db.profile.apparence.flashIcon = value; Ovale:UpdateFrame() end
						},
						targetText =
						{
							order = 90,
							type = "input",
							name = L["Caractère de portée"],
							desc = L["Ce caractère est affiché dans un coin de l'icône pour indiquer si la cible est à portée"],
							get = function(info) return OvaleOptions.db.profile.apparence.targetText end,
							set = function(info, value) OvaleOptions.db.profile.apparence.targetText = value; Ovale:UpdateFrame() end
						},
						updateInterval =
						{
							order = 100,
							type = "range",
							name = "Update interval",
							desc = "Maximum time to wait (in milliseconds) before refreshing icons.",
							min = 0, max = 500, step = 10,
							get = function(info) return OvaleOptions.db.profile.apparence.updateInterval * 1000 end,
							set = function(info, value) OvaleOptions.db.profile.apparence.updateInterval = value / 1000; Ovale:UpdateFrame() end
						},
					},
				},
				iconGroupAppearance =
				{
					order = 50,
					type = "group",
					name = L["Groupe d'icônes"],
					args =
					{
						moving =
						{
							order = 10,
							type = "toggle",
							name = L["Défilement"],
							desc = L["Les icônes se déplacent"],
							get = function(info) return OvaleOptions.db.profile.apparence.moving end,
							set = function(info, value) OvaleOptions.db.profile.apparence.moving = value; Ovale:UpdateFrame() end
						},
						vertical =
						{
							order = 20,
							type = "toggle",
							name = L["Vertical"],
							get = function(info) return OvaleOptions.db.profile.apparence.vertical end,
							set = function(info, value) OvaleOptions.db.profile.apparence.vertical = value; Ovale:UpdateFrame() end
						},
						margin =
						{
							order = 30,
							type = "range",
							name = L["Marge entre deux icônes"],
							min = -16, max = 64, step = 1,
							get = function(info) return OvaleOptions.db.profile.apparence.margin end,
							set = function(info,value) OvaleOptions.db.profile.apparence.margin = value; Ovale:UpdateFrame() end
						},
					},
				},
				optionsAppearance =
				{
					order = 60,
					type = "group",
					name = L["Options"],
					args =
					{
						iconShiftX =
						{
							order = 10,
							type = "range",
							name = L["Décalage horizontal des options"],
							min = -256, max = 256, step = 1,
							get = function(info) return OvaleOptions.db.profile.apparence.iconShiftX end,
							set = function(info,value) OvaleOptions.db.profile.apparence.iconShiftX = value; Ovale:UpdateFrame() end
						},
						iconShiftY =
						{
							order = 20,
							type = "range",
							name = L["Décalage vertical des options"],
							min = -256, max = 256, step = 1,
							get = function(info) return OvaleOptions.db.profile.apparence.iconShiftY end,
							set = function(info,value) OvaleOptions.db.profile.apparence.iconShiftY = value; Ovale:UpdateFrame() end
						},
						optionsAlpha =
						{
							order = 30,
							type = "range",
							name = L["Opacité des options"],
							min = 0, max = 100, step = 5,
							get = function(info) return OvaleOptions.db.profile.apparence.optionsAlpha * 100 end,
							set = function(info, value) OvaleOptions.db.profile.apparence.optionsAlpha = value/100; Ovale.frame.content:SetAlpha(value/100) end
						},
					},
				},
				predictiveIcon =
				{
					order = 70,
					type = "group",
					name = L["Prédictif"],
					args =
					{
						predictif =
						{
							order = 10,
							type = "toggle",
							name = L["Prédictif"],
							desc = L["Affiche les deux prochains sorts et pas uniquement le suivant"],
							get = function(info) return OvaleOptions.db.profile.apparence.predictif end,
							set = function(info, value) OvaleOptions.db.profile.apparence.predictif = value; Ovale:UpdateFrame() end
						},
						secondIconScale =
						{
							order = 20,
							type = "range",
							name = L["Taille du second icône"],
							min = 0.2, max = 1, step = 0.1,
							get = function(info) return OvaleOptions.db.profile.apparence.secondIconScale end,
							set = function(info,value) OvaleOptions.db.profile.apparence.secondIconScale = value; Ovale:UpdateFrame() end
						},
					},
				},
			}
		},
		code =
		{
			name = L["Code"],
			type = "group",
			args = 
			{
				source = {
					order = 10,
					type = "select",
					name = L["Script"],
					width = "double",
					values = function(info)
						return OvaleScripts:GetDescriptions()
					end,
					get = function(info)
						return OvaleOptions.db.profile.source
					end,
					set = function(info, v)
						local oldSource = OvaleOptions.db.profile.source
						if oldSource ~= v then
							OvaleOptions.db.profile.source = v
							OvaleOptions:SendMessage("Ovale_ScriptChanged")
						end
					end,
				},
				code = 
				{
					order = 20,
					type = "input",
					multiline = 15,
					name = L["Code"],
					width = "full",
					disabled = function()
						return OvaleOptions.db.profile.source ~= "custom"
					end,
					get = function(info)
						local source = OvaleOptions.db.profile.source
						local code
						if source and OvaleScripts.script[source] then
							code = OvaleScripts.script[source].code
						else
							code = ""
						end
						return strgsub(code, "\t", "    ")
					end,
					set = function(info, v)
						OvaleScripts:RegisterScript(self_class, "custom", L["Script personnalisé"], v)
						OvaleOptions.db.profile.code = v
						OvaleOptions:SendMessage("Ovale_ScriptChanged")
					end,
				},
				copy =
				{
					order = 30,
					type = "execute",
					name = L["Copier sur Script personnalisé"],
					disabled = function()
						return OvaleOptions.db.profile.source == "custom"
					end,
					confirm = function()
						return L["Ecraser le Script personnalisé préexistant?"]
					end,
					func = function()
						local source = OvaleOptions.db.profile.source
						local code
						if source and OvaleScripts.script[source] then
							code = OvaleScripts.script[source].code
						else
							code = ""
						end
						OvaleScripts.script["custom"].code = code
						OvaleOptions.db.profile.source = "custom"
						OvaleOptions.db.profile.code = code
						OvaleOptions:SendMessage("Ovale_ScriptChanged")
					end,
				}
			}
		},
		debug =
		{
			name = "Debug",
			type = "group",
			args =
			{
				trace =
				{
					name = "Trace",
					type = "group",
					args =
					{
						trace =
						{
							order = 10,
							type = "execute",
							name = "Trace next frame",
							func = function() Ovale.trace = true end,
						},
						traceSpellId =
						{
							order = 20,
							type = "input",
							dialogControl = "Aura_EditBox",
							name = "Trace spellcast",
							desc = "Names or spell IDs of spellcasts to watch, separated by semicolons.",
							get = function(info)
								local OvaleFuture = Ovale.OvaleFuture
								if OvaleFuture then
									local t = OvaleFuture.traceSpellList or {}
									local s = ""
									for k, v in pairs(t) do
										if type(v) == "boolean" then
											if string.len(s) == 0 then
												s = k
											else
												s = s .. "; " .. k
											end
										end
									end
									return s
								else
									return ""
								end
							end,
							set = function(info, value)
								local OvaleFuture = Ovale.OvaleFuture
								if OvaleFuture then
									local t = {}
									for s in strgmatch(value, "[^;]+") do
										-- strip leading and trailing whitespace
										s = strgsub(s, "^%s*", "")
										s = strgsub(s, "%s*$", "")
										if string.len(s) > 0 then
											local v = tonumber(s)
											if v then
												s = API_GetSpellInfo(v)
												if s then
													t[v] = true
													t[s] = v
												end
											else
												t[s] = true
											end
										end
									end
									if next(t) then
										OvaleFuture.traceSpellList = t
									else
										OvaleFuture.traceSpellList = nil
									end
								end
							end,
						},
					},
				},
				toggles =
				{
					name = "Options",
					type = "group",
					args =
					{
						-- Node names must match the names of the debug flags.
						action_bar =
						{
							name = "Action bars",
							desc = L["Debug action bars"],
							type = "toggle",
						},
						aura =
						{
							name = "Auras",
							desc = L["Debug aura"],
							type = "toggle",
						},
						compile =
						{
							name = "Compile",
							desc = L["Debug compile"],
							type = "toggle",
						},
						damage_taken =
						{
							name = "Damage taken",
							desc = L["Debug damage taken"],
							type = "toggle",
						},
						enemy =
						{
							name = "Enemies",
							desc = L["Debug enemies"],
							type = "toggle",
						},
						guid =
						{
							name = "GUIDs",
							desc = L["Debug GUID"],
							type = "toggle",
						},
						missing_spells =
						{
							name = "Missing spells",
							desc = L["Debug missing spells"],
							type = "toggle",
						},
						paper_doll =
						{
							name = "Paper doll updates",
							desc = L["Debug paper doll"],
							type = "toggle",
						},
						snapshot =
						{
							name = "Snapshot updates",
							desc = L["Debug stat snapshots"],
							type = "toggle",
						},
						unknown_spells =
						{
							name = "Unknown spells",
							desc = L["Debug unknown spells"],
							type = "toggle",
						},
					},
					get = function(info) return OvaleOptions.db.profile.debug[info[#info]] end,
					set = function(info, value) OvaleOptions.db.profile.debug[info[#info]] = value end,
				},
			},
		},
		actions =
		{
			name = "Actions",
			type = "group",
			args = 
			{
				show =
				{
					order = -1,
					type = "execute",
					name = L["Afficher la fenêtre"],
					guiHidden = true,
					func = function()
						OvaleOptions.db.profile.display = true
						Ovale:UpdateVisibility()
					end
				},
				hide =
				{
					order = -2,
					type = "execute",
					name = L["Cacher la fenêtre"],
					guiHidden = true,
					func = function()
						OvaleOptions.db.profile.display = false
						Ovale.frame:Hide()	
					end
				},
				config  =
				{
					name = "Configuration",
					type = "execute",
					func = function() AceConfigDialog:SetDefaultSize("Ovale Apparence", 500, 550); AceConfigDialog:Open("Ovale Apparence") end
				},
				code  =
				{
					name = "Code",
					type = "execute",
					func = function() AceConfigDialog:SetDefaultSize("Ovale", 500, 550); AceConfigDialog:Open("Ovale") end
				},
				debug =
				{
					name = "Debug",
					type = "execute",
					func = function() AceConfigDialog:SetDefaultSize("Ovale", 500, 550); AceConfigDialog:Open("Ovale Debug") end
				},
				power =
				{
					order = -3,
					name = "Power",
					type = "execute",
					func = function()
						OvaleState.state:DebugPower()
					end
				},
				talent =
				{
					order = -4,
					name = "List talent id",
					type = "execute",
					func = function() OvaleSpellBook:DebugTalents() end
				},
				targetbuff =
				{
					order = -5,
					name = "List target buffs and debuffs",
					type = "execute",
					func = function()
						local OvaleAura = Ovale.OvaleAura
						if OvaleAura then
							OvaleAura:DebugListAura("target", "HELPFUL")
							OvaleAura:DebugListAura("target", "HARMFUL")
						end
					end
				},
				buff =
				{
					order = -6,
					name = "List player buffs and debuffs",
					type = "execute",
					func = function()
						local OvaleAura = Ovale.OvaleAura
						if OvaleAura then
							OvaleAura:DebugListAura("player", "HELPFUL")
							OvaleAura:DebugListAura("player", "HARMFUL")
						end
					end
				},
				glyph =
				{
					order = -7,
					name = "List player glyphs",
					type = "execute",
					func = function() OvaleSpellBook:DebugGlyphs() end
				},
				spell =
				{
					order = -8,
					name = "List player spells",
					type = "execute",
					func = function() OvaleSpellBook:DebugSpells() end
				},
				stance =
				{
					order = -9,
					name = "List stances",
					type = "execute",
					func = function()
						if Ovale.OvaleStance then Ovale.OvaleStance:DebugStances() end
					end
				},
			}
		}
	}
}
--</private-static-properties>

--<public-static-methods>
function OvaleOptions:OnInitialize()
	-- Resolve module dependencies.
	OvaleScripts = Ovale.OvaleScripts
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleState = Ovale.OvaleState

	self.db = LibStub("AceDB-3.0"):New("OvaleDB",
	{
		profile = 
		{
			display = true,
			source = "Ovale",
			code = "",
			left = 500,
			top = 500,
			check = {},
			list = {},
			debug = {},
			apparence = {enCombat=false, iconScale = 2, secondIconScale = 1, margin = 4, fontScale = 0.5, iconShiftX = 0, iconShiftY = 0,
				smallIconScale=1, raccourcis=true, numeric=false, avecCible = false,
				verrouille = false, vertical = false, predictif=false, highlightIcon = true, clickThru = false, 
				hideVehicule=false, flashIcon=true, targetText = "●", alpha = 1,
				optionsAlpha = 1, updateInterval=0.1}
		}
	})

	self_options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

	-- Add dual-spec support
	if LibDualSpec then
		LibDualSpec:EnhanceDatabase(self.db, "Ovale")
		LibDualSpec:EnhanceOptions(self_options.args.profile, self.db)
	end
	
	AceConfig:RegisterOptionsTable("Ovale", self_options.args.code)
	AceConfig:RegisterOptionsTable("Ovale Actions", self_options.args.actions, "Ovale")
	AceConfig:RegisterOptionsTable("Ovale Profile", self_options.args.profile)
	AceConfig:RegisterOptionsTable("Ovale Apparence", self_options.args.apparence)
	AceConfig:RegisterOptionsTable("Ovale Debug", self_options.args.debug)

	AceConfigDialog:AddToBlizOptions("Ovale", "Ovale")
	AceConfigDialog:AddToBlizOptions("Ovale Profile", "Profile", "Ovale")
	AceConfigDialog:AddToBlizOptions("Ovale Apparence", "Apparence", "Ovale")
	AceConfigDialog:AddToBlizOptions("Ovale Debug", "Debug", "Ovale")

	self.db.RegisterCallback( self, "OnNewProfile", "HandleProfileChanges" )
	self.db.RegisterCallback( self, "OnProfileReset", "HandleProfileChanges" )
	self.db.RegisterCallback( self, "OnProfileChanged", "HandleProfileChanges" )
	self.db.RegisterCallback( self, "OnProfileCopied", "HandleProfileChanges" )

	OvaleScripts:RegisterScript(self_class, "custom", L["Script personnalisé"], self.db.profile.code)
	self:HandleProfileChanges()
end

function OvaleOptions:HandleProfileChanges()
	self:SendMessage("Ovale_ScriptChanged")
end

function OvaleOptions:GetProfile()
	return self.db.profile
end

--</public-static-methods>
