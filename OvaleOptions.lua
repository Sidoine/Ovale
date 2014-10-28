--[[--------------------------------------------------------------------
    Copyright (C) 2012, 2013 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- Ovale options and UI

local OVALE, Ovale = ...
local OvaleOptions = Ovale:NewModule("OvaleOptions", "AceConsole-3.0", "AceEvent-3.0")
Ovale.OvaleOptions = OvaleOptions

--<private-static-properties>
local L = Ovale.L

-- Forward declarations for module dependencies.
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local OvaleDataBroker = nil
local OvaleScripts = nil
local OvaleSpellBook = nil
local OvaleState = nil

local format = string.format
local strgmatch = string.gmatch
local strgsub = string.gsub
local tinsert = table.insert
local type = type
local API_GetTime = GetTime
local API_UnitClass = UnitClass

-- Player's class.
local _, self_class = API_UnitClass("player")

-- AceDB default database.
local self_defaultDB = {
	global = {
		debug = {},
	},
	profile = {
		display = true,
		showHiddenScripts = false,
		source = "Ovale",
		code = "",
		left = 500,
		top = 500,
		check = {},
		list = {},
		apparence = {
			minimap = {},
			enCombat = false,
			iconScale = 1,
			secondIconScale = 1,
			margin = 4,
			fontScale = 1,
			iconShiftX = 0,
			iconShiftY = 0,
			smallIconScale = 0.8,
			raccourcis = true,
			numeric = false,
			avecCible = false,
			verrouille = false,
			vertical = false,
			predictif = false,
			highlightIcon = true,
			clickThru = false,
			hideVehicule = false,
			flashIcon = true,
			targetText = "●",
			alpha = 1,
			optionsAlpha = 1,
			updateInterval = 0.1,
			auraLag = 400,
			enableIcons = true,
			spellFlash = {
				brightness = 1,
				enabled = true,
				hasHostileTarget = false,
				hasTarget = false,
				hideInVehicle = false,
				inCombat = false,
				size = 2.4,
				colorMain = { r = 1, g = 1, b = 1 },		-- white
				colorShortCd = { r = 1, g = 1, b = 0 },		-- yellow
				colorCd = { r = 1, g = 1, b = 0 },			-- yellow
				colorInterrupt = { r = 0, g = 1, b = 1 }, 	-- aqua
			},
		},
	},
}

-- AceDB options table.
local self_options = 
{ 
	type = "group",
	args = 
	{
		apparence =
		{
			name = L["Apparence"],
			type = "group",
			-- Generic getter/setter for options.
			get = function(info)
				return Ovale.db.profile.apparence[info[#info]]
			end,
			set = function(info, value)
				Ovale.db.profile.apparence[info[#info]] = value
				-- Pass the name of the parent group as the event parameter.
				OvaleOptions:SendMessage("Ovale_OptionChanged", info[#info - 1])
			end,
			args =
			{
				minimap =
				{
					order = 25,
					type = "toggle",
					name = L["Show minimap icon"],
					get = function(info)
						return not Ovale.db.profile.apparence.minimap.hide
					end,
					set = function(info, value)
						Ovale.db.profile.apparence.minimap.hide = not value
						if OvaleDataBroker then
							OvaleDataBroker:UpdateIcon()
						end
					end
				},
				iconGroupAppearance =
				{
					order = 40,
					type = "group",
					name = L["Groupe d'icônes"],
					args =
					{
						enableIcons = {
							order = 10,
							type = "toggle",
							name = L["Enabled"],
							width = "full",
							set = function(info, value)
								Ovale.db.profile.apparence.enableIcons = value
								OvaleOptions:SendMessage("Ovale_OptionChanged", "visibility")
							end,
						},
						verrouille =
						{
							order = 10,
							type = "toggle",
							name = L["Verrouiller position"],
							disabled = function()
								return not Ovale.db.profile.apparence.enableIcons
							end,
						},
						clickThru =
						{
							order = 20,
							type = "toggle",
							name = L["Ignorer les clics souris"],
							disabled = function()
								return not Ovale.db.profile.apparence.enableIcons
							end,
						},
						visibility = {
							order = 20,
							type = "group",
							name = L["Visibilité"],
							inline = true,
							disabled = function()
								return not Ovale.db.profile.apparence.enableIcons
							end,
							args = {
								enCombat = {
									order = 10,
									type = "toggle",
									name = L["En combat uniquement"],
								},
								avecCible = {
									order = 20,
									type = "toggle",
									name = L["Si cible uniquement"],
								},
								targetHostileOnly = {
									order = 30,
									type = "toggle",
									name = L["Cacher si cible amicale ou morte"],
								},
								hideVehicule = {
									order = 40,
									type = "toggle",
									name = L["Cacher dans les véhicules"],
								},
								hideEmpty = {
									order = 50,
									type = "toggle",
									name = L["Cacher bouton vide"],
								},
							},
						},
						layout = {
							order = 30,
							type = "group",
							name = L["Layout"],
							inline = true,
							disabled = function()
								return not Ovale.db.profile.apparence.enableIcons
							end,
							args = {
								moving = {
									order = 10,
									type = "toggle",
									name = L["Défilement"],
									desc = L["Les icônes se déplacent"],
								},
								vertical = {
									order = 20,
									type = "toggle",
									name = L["Vertical"],
								},
								margin = {
									order = 30,
									type = "range",
									name = L["Marge entre deux icônes"],
									min = -16, max = 64, step = 1,
								},
							}
						}
					},
				},
				iconAppearance =
				{
					order = 50,
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
							min = 0.5, max = 3, bigStep = 0.01,
							isPercent = true,
						},
						smallIconScale =
						{
							order = 20,
							type = "range",
							name = L["Taille des petites icônes"],
							desc = L["La taille des petites icônes"],
							min = 0.5, max = 3, bigStep = 0.01,
							isPercent = true,
						},
						fontScale =
						{
							order = 30,
							type = "range",
							name = L["Taille des polices"],
							desc = L["La taille des polices"],
							min = 0.2, max = 2, bigStep = 0.01,
							isPercent = true,
						},
						alpha =
						{
							order = 40,
							type = "range",
							name = L["Opacité des icônes"],
							min = 0, max = 1, bigStep = 0.01,
							isPercent = true,
						},
						raccourcis =
						{
							order = 50,
							type = "toggle",
							name = L["Raccourcis clavier"],
							desc = L["Afficher les raccourcis clavier dans le coin inférieur gauche des icônes"],
						},
						numeric =
						{
							order = 60,
							type = "toggle",
							name = L["Affichage numérique"],
							desc = L["Affiche le temps de recharge sous forme numérique"],
						},
						highlightIcon =
						{
							order = 70,
							type = "toggle",
							name = L["Illuminer l'icône"],
							desc = L["Illuminer l'icône quand la technique doit être spammée"],
						},
						flashIcon =
						{
							order = 80,
							type = "toggle",
							name = L["Illuminer l'icône quand le temps de recharge est écoulé"],
						},
						targetText =
						{
							order = 90,
							type = "input",
							name = L["Caractère de portée"],
							desc = L["Ce caractère est affiché dans un coin de l'icône pour indiquer si la cible est à portée"],
						},
						updateInterval =
						{
							order = 100,
							type = "range",
							name = "Update interval",
							desc = "Maximum time to wait (in milliseconds) before refreshing icons.",
							min = 0, max = 500, step = 10,
							get = function(info)
								return Ovale.db.profile.apparence.updateInterval * 1000
							end,
							set = function(info, value)
								Ovale.db.profile.apparence.updateInterval = value / 1000
								OvaleOptions:SendMessage("Ovale_OptionChanged")
							end
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
						},
						iconShiftY =
						{
							order = 20,
							type = "range",
							name = L["Décalage vertical des options"],
							min = -256, max = 256, step = 1,
						},
						optionsAlpha =
						{
							order = 30,
							type = "range",
							name = L["Opacité des options"],
							min = 0, max = 1, bigStep = 0.01,
							isPercent = true,
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
						},
						secondIconScale =
						{
							order = 20,
							type = "range",
							name = L["Taille du second icône"],
							min = 0.2, max = 1, bigStep = 0.01,
							isPercent = true,
						},
					},
				},
				spellFlash = {
					type = "group",
					name = "SpellFlash",
					disabled = function()
						return not SpellFlashCore
					end,
					get = function(info)
						return Ovale.db.profile.apparence.spellFlash[info[#info]]
					end,
					set = function(info, value)
						Ovale.db.profile.apparence.spellFlash[info[#info]] = value
						OvaleOptions:SendMessage("Ovale_OptionChanged")
					end,
					args = {
						enabled = {
							order = 10,
							type = "toggle",
							name = L["Enabled"],
							desc = L["Flash spells on action bars when they are ready to be cast. Requires SpellFlashCore."],
							width = "full",
						},
						inCombat = {
							order = 10,
							type = "toggle",
							name = L["En combat uniquement"],
							disabled = function()
								return not SpellFlashCore or not Ovale.db.profile.apparence.spellFlash.enabled
							end,
						},
						hasTarget = {
							order = 20,
							type = "toggle",
							name = L["Si cible uniquement"],
							disabled = function()
								return not SpellFlashCore or not Ovale.db.profile.apparence.spellFlash.enabled
							end,
						},
						hasHostileTarget = {
							order = 30,
							type = "toggle",
							name = L["Cacher si cible amicale ou morte"],
							disabled = function()
								return not SpellFlashCore or not Ovale.db.profile.apparence.spellFlash.enabled
							end,
						},
						hideInVehicle = {
							order = 40,
							type = "toggle",
							name = L["Cacher dans les véhicules"],
							disabled = function()
								return not SpellFlashCore or not Ovale.db.profile.apparence.spellFlash.enabled
							end,
						},
						brightness = {
							order = 50,
							type = "range",
							name = L["Flash brightness"],
							min = 0, max = 1, bigStep = 0.01,
							isPercent = true,
						},
						size = {
							order = 60,
							type = "range",
							name = L["Flash size"],
							min = 0, max = 3, bigStep = 0.01,
							isPercent = true,
						},
						colors = {
							order = 70,
							type = "group",
							name = L["Colors"],
							inline = true,
							get = function(info)
								local color = Ovale.db.profile.apparence.spellFlash[info[#info]]
								return color.r, color.g, color.b, 1.0
							end,
							set = function(info, r, g, b, a)
								local color = Ovale.db.profile.apparence.spellFlash[info[#info]]
								color.r = r
								color.g = g
								color.b = b
								OvaleOptions:SendMessage("Ovale_OptionChanged")
							end,
							args = {
								colorMain = {
									order = 10,
									type = "color",
									name = L["Main attack"],
									hasAlpha = false,
								},
								colorCd = {
									order = 20,
									type = "color",
									name = L["Long cooldown abilities"],
									hasAlpha = false,
								},
								colorShortCd = {
									order = 30,
									type = "color",
									name = L["Short cooldown abilities"],
									hasAlpha = false,
								},
								colorInterrupt = {
									order = 40,
									type = "color",
									name = L["Interrupts"],
									hasAlpha = false,
								},
							},
						},
					},
				},
				advanced = {
					order = 80,
					type = "group",
					name = "Advanced",
					args =
					{
						auraLag =
						{
							order = 10,
							type = "range",
							name = L["Aura lag"],
							desc = L["Lag (in milliseconds) between when an spell is cast and when the affected aura is applied or removed"],
							min = 100, max = 700, step = 10,
						},
					},
				},
			},
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
						local scriptType = not Ovale.db.profile.showHiddenScripts and "script"
						return OvaleScripts:GetDescriptions(scriptType)
					end,
					get = function(info)
						return Ovale.db.profile.source
					end,
					set = function(info, v)
						OvaleOptions:SetScript(v)
					end,
				},
				code = 
				{
					order = 20,
					type = "input",
					multiline = 25,
					name = L["Code"],
					width = "full",
					disabled = function()
						return Ovale.db.profile.source ~= "custom"
					end,
					get = function(info)
						local source = Ovale.db.profile.source
						local code
						if source and OvaleScripts.script[source] then
							code = OvaleScripts.script[source].code
						else
							code = ""
						end
						return strgsub(code, "\t", "    ")
					end,
					set = function(info, v)
						OvaleScripts:RegisterScript(self_class, "custom", L["Script personnalisé"], v, "script")
						Ovale.db.profile.code = v
						OvaleOptions:SendMessage("Ovale_ScriptChanged")
					end,
				},
				copy =
				{
					order = 30,
					type = "execute",
					name = L["Copier sur Script personnalisé"],
					disabled = function()
						return Ovale.db.profile.source == "custom"
					end,
					confirm = function()
						return L["Ecraser le Script personnalisé préexistant?"]
					end,
					func = function()
						local source = Ovale.db.profile.source
						local code
						if source and OvaleScripts.script[source] then
							code = OvaleScripts.script[source].code
						else
							code = ""
						end
						OvaleScripts.script["custom"].code = code
						Ovale.db.profile.source = "custom"
						Ovale.db.profile.code = code
						OvaleOptions:SendMessage("Ovale_ScriptChanged")
					end,
				},
				showHiddenScripts = {
					order = 40,
					type = "toggle",
					name = L["Show hidden"],
					get = function(info) return Ovale.db.profile.showHiddenScripts end,
					set = function(info, value) Ovale.db.profile.showHiddenScripts = value end
				},
			},
		},
		debug =
		{
			name = "Debug",
			type = "group",
			args =
			{
				toggles =
				{
					name = "Options",
					type = "group",
					order = 10,
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
						combo_points =
						{
							name = "Combo points",
							desc = L["Debug combo points"],
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
						power =
						{
							name = "Power",
							desc = L["Debug power"],
							type = "toggle",
						},
						snapshot =
						{
							name = "Snapshot updates",
							desc = L["Debug stat snapshots"],
							type = "toggle",
						},
						spellbook =
						{
							name = "Spellbook changes",
							desc = L["Debug spellbook changes"],
							type = "toggle",
						},
						steady_focus =
						{
							name = "Steady Focus",
							desc = L["Debug Steady Focus"],
							type = "toggle",
						},
						unknown_spells =
						{
							name = "Unknown spells",
							desc = L["Debug unknown spells"],
							type = "toggle",
						},
					},
					get = function(info)
						local value = Ovale.db.global.debug[info[#info]]
						return (value ~= nil)
					end,
					set = function(info, value)
						if value then
							Ovale.db.global.debug[info[#info]] = value
						else
							Ovale.db.global.debug[info[#info]] = nil
						end
					end,
				},
				trace =
				{
					name = "Trace",
					type = "group",
					order = 20,
					args =
					{
						trace =
						{
							order = 10,
							type = "execute",
							name = "Trace next frame",
							func = function()
								Ovale:ClearLog()
								Ovale.trace = true
								Ovale:Logf("=== Trace @%f", API_GetTime())
							end,
						},
						traceSpellId =
						{
							order = 20,
							type = "input",
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
												s = OvaleSpellBook:GetSpellName(v)
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
				traceLog = {
					name = L["Trace Log"],
					type = "group",
					order = 30,
					args = {
						traceLog = {
							name = L["Trace Log"],
							type = "input",
							multiline = 25,
							width = "full",
							get = function() return Ovale:TraceLog() end,
						},
					},
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
					type = "execute",
					name = L["Afficher la fenêtre"],
					guiHidden = true,
					func = function()
						Ovale.db.profile.display = true
						Ovale:UpdateVisibility()
					end
				},
				hide =
				{
					type = "execute",
					name = L["Cacher la fenêtre"],
					guiHidden = true,
					func = function()
						Ovale.db.profile.display = false
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
					func = function() AceConfigDialog:SetDefaultSize("Ovale", 700, 550); AceConfigDialog:Open("Ovale") end
				},
				debug =
				{
					name = "Debug",
					type = "execute",
					func = function() AceConfigDialog:SetDefaultSize("Ovale Debug", 800, 550); AceConfigDialog:Open("Ovale Debug") end
				},
				power =
				{
					name = "Power",
					type = "execute",
					func = function()
						OvaleState.state:DebugPower()
					end
				},
				talent =
				{
					name = "List talent id",
					type = "execute",
					func = function() OvaleSpellBook:DebugTalents() end
				},
				targetbuff =
				{
					name = "List target buffs and debuffs",
					type = "execute",
					func = function()
						OvaleState.state:PrintUnitAuras("target", "HELPFUL")
						OvaleState.state:PrintUnitAuras("target", "HARMFUL")
					end
				},
				buff =
				{
					name = "List player buffs and debuffs",
					type = "execute",
					func = function()
						OvaleState.state:PrintUnitAuras("player", "HELPFUL")
						OvaleState.state:PrintUnitAuras("player", "HARMFUL")
					end
				},
				glyph =
				{
					name = "List player glyphs",
					type = "execute",
					func = function() OvaleSpellBook:DebugGlyphs() end
				},
				spell =
				{
					name = "List player spells",
					type = "execute",
					func = function() OvaleSpellBook:DebugSpells() end
				},
				stance =
				{
					name = "List stances",
					type = "execute",
					func = function()
						if Ovale.OvaleStance then Ovale.OvaleStance:DebugStances() end
					end
				},
				profilestart = {
					name = "Start gathering profiling stats",
					type = "execute",
					func = function() Ovale.Profiler:Enable(nil, true) end,
				},
				profilestop = {
					name = "Stop gathering profiling stats",
					type = "execute",
					func = function() Ovale.Profiler:Disable(nil, true) end,
				},
				profilereset = {
					name = "Reset profiling stats",
					type = "execute",
					func = function() Ovale.Profiler:Reset() end,
				},
				profile = {
					name = "Print profiling stats",
					type = "execute",
					func = function() Ovale.Profiler:Info() end,
				},
				version = {
					name = "Show version number",
					type = "execute",
					func = function() Ovale:Print(Ovale.version) end,
				},
				ping = {
					name = "Ping for Ovale users in group",
					type = "execute",
					func = function() Ovale:VersionCheck() end,
				},
			},
		},
	},
}
--</private-static-properties>

--<public-static-methods>
function OvaleOptions:OnInitialize()
	-- Resolve module dependencies.
	OvaleDataBroker = Ovale.OvaleDataBroker
	OvaleScripts = Ovale.OvaleScripts
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleState = Ovale.OvaleState

	local db = LibStub("AceDB-3.0"):New("OvaleDB", self_defaultDB)
	self_options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)

	-- Add dual-spec support
	local LibDualSpec = LibStub("LibDualSpec-1.0",true)
	if LibDualSpec then
		LibDualSpec:EnhanceDatabase(db, "Ovale")
		LibDualSpec:EnhanceOptions(self_options.args.profile, db)
	end
	
	db.RegisterCallback( self, "OnNewProfile", "HandleProfileChanges" )
	db.RegisterCallback( self, "OnProfileReset", "HandleProfileChanges" )
	db.RegisterCallback( self, "OnProfileChanged", "HandleProfileChanges" )
	db.RegisterCallback( self, "OnProfileCopied", "HandleProfileChanges" )

	Ovale.db = db
	self:UpgradeSavedVariables()

	AceConfig:RegisterOptionsTable("Ovale", self_options.args.code)
	AceConfig:RegisterOptionsTable("Ovale Actions", self_options.args.actions, "Ovale")
	AceConfig:RegisterOptionsTable("Ovale Profile", self_options.args.profile)
	AceConfig:RegisterOptionsTable("Ovale Apparence", self_options.args.apparence)
	AceConfig:RegisterOptionsTable("Ovale Debug", self_options.args.debug)

	AceConfigDialog:AddToBlizOptions("Ovale", "Ovale")
	AceConfigDialog:AddToBlizOptions("Ovale Profile", "Profile", "Ovale")
	AceConfigDialog:AddToBlizOptions("Ovale Apparence", L["Apparence"], "Ovale")
	AceConfigDialog:AddToBlizOptions("Ovale Debug", "Debug", "Ovale")

	OvaleScripts:RegisterScript(self_class, "custom", L["Script personnalisé"], db.profile.code)
end

function OvaleOptions:OnEnable()
	self:HandleProfileChanges()
end

function OvaleOptions:UpgradeSavedVariables()
	local profile = Ovale.db.profile
	-- All profile-specific debug options are removed.  They are now in the global database.
	profile.debug = nil
	-- SpellFlash options have been moved and renamed.
	if profile.apparence.spellFlash and type(profile.apparence.spellFlash) ~= "table" then
		local enabled = profile.apparence.spellFlash
		profile.apparence.spellFlash = {}
		profile.apparence.spellFlash.enabled = enabled
	end
	-- Re-register defaults so that any tables created during the upgrade are "populated"
	-- by the default database automatically.
	Ovale.db:RegisterDefaults(self_defaultDB)
end

function OvaleOptions:HandleProfileChanges()
	self:SendMessage("Ovale_ProfileChanged")
	self:SendMessage("Ovale_ScriptChanged")
end

function OvaleOptions:SetScript(name)
	local oldSource = Ovale.db.profile.source
	if oldSource ~= name then
		Ovale.db.profile.source = name
		self:SendMessage("Ovale_ScriptChanged")
	end
end

function OvaleOptions:ToggleConfig()
	local frameName = "Ovale Apparence"
	if AceConfigDialog.OpenFrames[frameName] then
		AceConfigDialog:Close(frameName)
	else
		AceConfigDialog:Open(frameName)
	end
end
--</public-static-methods>
