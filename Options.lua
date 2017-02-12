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
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = Ovale.L

local ipairs = ipairs
local pairs = pairs
local tinsert = table.insert
local type = type
local API_InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
-- GLOBALS: LibStub

-- List of registered modules providing options.
local self_register = {}
--</private-static-properties>

--<public-static-properties>
-- AceDB default database.
OvaleOptions.defaultDB = {
	profile = {
		check = {},
		list = {},
		standaloneOptions = false,
		apparence = {
			-- Icon group
			avecCible = false,
			clickThru = false,
			enCombat = false,
			enableIcons = true,
			hideEmpty = false,
			hideVehicule = false,
			margin = 4,
			offsetX = 0,
			offsetY = 0,
			targetHostileOnly = false,
			verrouille = false,
			vertical = false,
			-- Icon
			alpha = 1,
			flashIcon = true,
			remainsFontColor = {r=1,g=1,b=1},
			fontScale = 1,
			highlightIcon = true,
			iconScale = 1,
			numeric = false,
			raccourcis = true,
			smallIconScale = 0.8,
			targetText = "●",
			-- Options
			iconShiftX = 0,
			iconShiftY = 0,
			optionsAlpha = 1,
			-- Two abilities
			predictif = false,
			secondIconScale = 1,
			-- Advanced
			taggedEnemies = false,
			auraLag = 400,
		},
	},
}

-- AceDB options table.
OvaleOptions.options = {
	type = "group",
	args = 
	{
		apparence =
		{
			name = OVALE,
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
				standaloneOptions = {
					order = 30,
					name = L["Standalone options"],
					desc = L["Open configuration panel in a separate, movable window."],
					type = "toggle",
					get = function(info)
						return Ovale.db.profile.standaloneOptions
					end,
					set = function(info, value)
						Ovale.db.profile.standaloneOptions = value
					end,
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
								offsetX = {
									order = 30,
									type = "range",
									name = L["Horizontal offset"],
									desc = L["Horizontal offset from the center of the screen."],
									min = -1000, max = 1000,
									softMin = -500, softMax = 500, bigStep = 1,
								},
								offsetY = {
									order = 40,
									type = "range",
									name = L["Vertical offset"],
									desc = L["Vertical offset from the center of the screen."],
									min = -1000, max = 1000,
									softMin = -500, softMax = 500, bigStep = 1,
								},
								margin = {
									order = 50,
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
						remainsFontColor =
						{
							type = "color",
							order = 25,
							name = L["Remaining time font color"],
							get = function(info)
								local t = Ovale.db.profile.apparence.remainsFontColor
								return t.r, t.g, t.b
							end,
							set = function(info, r, g, b)
								local t = Ovale.db.profile.apparence.remainsFontColor
								t.r, t.g, t.b = r, g, b
								Ovale.db.profile.apparence.remainsFontColor = t
							end,
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
				advanced = {
					order = 80,
					type = "group",
					name = "Advanced",
					args =
					{
						taggedEnemies = {
							order = 10,
							type = "toggle",
							name = L["Only count tagged enemies"],
							desc = L["Only count a mob as an enemy if it is directly affected by a player's spells."],
						},
						auraLag =
						{
							order = 20,
							type = "range",
							name = L["Aura lag"],
							desc = L["Lag (in milliseconds) between when an spell is cast and when the affected aura is applied or removed"],
							min = 100, max = 700, step = 10,
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
						Ovale.db.profile.apparence.enableIcons = true
						OvaleOptions:SendMessage("Ovale_OptionChanged", "visibility")
					end
				},
				hide =
				{
					type = "execute",
					name = L["Cacher la fenêtre"],
					guiHidden = true,
					func = function()
						Ovale.db.profile.apparence.enableIcons = false
						OvaleOptions:SendMessage("Ovale_OptionChanged", "visibility")
					end
				},
				config  =
				{
					name = "Configuration",
					type = "execute",
					func = function() OvaleOptions:ToggleConfig() end,
				},
				refresh = {
					name = L["Display refresh statistics"],
					type = "execute",
					func = function()
						local avgRefresh, minRefresh, maxRefresh, count = Ovale:GetRefreshIntervalStatistics()
						Ovale:Print("Refresh intervals: count = %d, avg = %d, min = %d, max = %d (ms)", count, avgRefresh, minRefresh, maxRefresh)
					end,
				},
			},
		},
	},
}
--</public-static-properties>

--<public-static-methods>
function OvaleOptions:OnInitialize()
	local db = LibStub("AceDB-3.0"):New("OvaleDB", self.defaultDB)
	self.options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)

	-- Add dual-spec support
	local LibDualSpec = LibStub("LibDualSpec-1.0",true)
	if LibDualSpec then
		LibDualSpec:EnhanceDatabase(db, "Ovale")
		LibDualSpec:EnhanceOptions(self.options.args.profile, db)
	end
	
	db.RegisterCallback( self, "OnNewProfile", "HandleProfileChanges" )
	db.RegisterCallback( self, "OnProfileReset", "HandleProfileChanges" )
	db.RegisterCallback( self, "OnProfileChanged", "HandleProfileChanges" )
	db.RegisterCallback( self, "OnProfileCopied", "HandleProfileChanges" )

	Ovale.db = db

	-- Upgrade saved variables to current format.
	self:UpgradeSavedVariables()

	AceConfig:RegisterOptionsTable(OVALE, self.options.args.apparence)
	AceConfig:RegisterOptionsTable(OVALE .. " Profiles", self.options.args.profile)
	-- Slash commands.
	AceConfig:RegisterOptionsTable(OVALE .. " Actions", self.options.args.actions, "Ovale")

	AceConfigDialog:AddToBlizOptions(OVALE)
	AceConfigDialog:AddToBlizOptions(OVALE .. " Profiles", "Profiles", OVALE)
end

function OvaleOptions:OnEnable()
	self:HandleProfileChanges()
end

function OvaleOptions:RegisterOptions(addon)
	tinsert(self_register, addon)
end

function OvaleOptions:UpgradeSavedVariables()
	local profile = Ovale.db.profile

	-- Merge two options that had the same meaning.
	if profile.display ~= nil and type(profile.display) == "boolean" then
		profile.apparence.enableIcons = profile.display
		profile.display = nil
	end

	-- The frame position settings changed from left/top to offsetX/offsetY.
	if profile.left or profile.top then
		profile.left = nil
		profile.top = nil
		Ovale:OneTimeMessage("The Ovale icon frames position has been reset.")
	end

	-- Invoke module-specific upgrade for Saved Variables.
	for _, addon in ipairs(self_register) do
		if addon.UpgradeSavedVariables then
			addon:UpgradeSavedVariables()
		end
	end

	-- Re-register defaults so that any tables created during the upgrade are "populated"
	-- by the default database automatically.
	Ovale.db:RegisterDefaults(self.defaultDB)
end

function OvaleOptions:HandleProfileChanges()
	self:SendMessage("Ovale_ProfileChanged")
	self:SendMessage("Ovale_ScriptChanged")
	self:SendMessage("Ovale_OptionChanged", "layout")
	self:SendMessage("Ovale_OptionChanged", "visibility")
end

function OvaleOptions:ToggleConfig()
	if Ovale.db.profile.standaloneOptions then
		local appName = OVALE
		if AceConfigDialog.OpenFrames[appName] then
			AceConfigDialog:Close(appName)
		else
			AceConfigDialog:Open(appName)
		end
	else
		API_InterfaceOptionsFrame_OpenToCategory(OVALE)
		-- Invoke the same call twice in a row to workaround a bug with Interface panel
		-- opening without selecting the right category.
		API_InterfaceOptionsFrame_OpenToCategory(OVALE)
	end
end
--</public-static-methods>
