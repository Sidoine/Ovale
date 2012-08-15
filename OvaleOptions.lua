-- Ovale options and UI

OvaleOptions = LibStub("AceAddon-3.0"):NewAddon("OvaleOptions", "AceEvent-3.0", "AceConsole-3.0")

--<public-static-properties>
OvaleOptions.firstInit = false
OvaleOptions.db = nil
--</public-static-properties>

--<private-static-properties>
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("Ovale")
	
--GUI option
local options = 
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
				combatUniquement =
				{
					order = 1,
					type = "toggle",
					name = L["En combat uniquement"],
					get = function(info)
						return OvaleOptions.db.profile.apparence.enCombat
					end,
					set = function(info, v)
						OvaleOptions.db.profile.apparence.enCombat = v
						Ovale:UpdateVisibility()
					end,
					width = "full"
				},
				targetOnly =
				{
					order = 1.5,
					type = "toggle",
					name = L["Si cible uniquement"],
					get = function(info)
						return OvaleOptions.db.profile.apparence.avecCible
					end,
					set = function(info, v)
						OvaleOptions.db.profile.apparence.avecCible = v
						Ovale:UpdateVisibility()
					end,
					width = "full"
				},
				iconScale = 
				{
					order = 2,
					type = "range",
					name = L["Taille des icônes"],
					desc = L["La taille des icônes"],
					min = 0.1, max = 16, step = 0.1,
					get = function(info) return OvaleOptions.db.profile.apparence.iconScale end,
					set = function(info,value) OvaleOptions.db.profile.apparence.iconScale = value; Ovale:UpdateFrame() end
				},
				secondIconScale =
				{
					order = 2.5,
					type = "range",
					name = L["Taille du second icône"],
					min = 0.2, max = 1, step = 0.1,
					get = function(info) return OvaleOptions.db.profile.apparence.secondIconScale end,
					set = function(info,value) OvaleOptions.db.profile.apparence.secondIconScale = value; Ovale:UpdateFrame() end
				},
				fontScale = 
				{
					order = 3,
					type = "range",
					name = L["Taille des polices"],
					desc = L["La taille des polices"],
					min = 0.1, max = 2, step = 0.1,
					get = function(info) return OvaleOptions.db.profile.apparence.fontScale end,
					set = function(info,value) OvaleOptions.db.profile.apparence.fontScale = value; Ovale:UpdateFrame() end
				},
				smallIconScale = 
				{
					order = 4,
					type = "range",
					name = L["Taille des petites icônes"],
					desc = L["La taille des petites icônes"],
					min = 0.1, max = 16, step = 0.1,
					get = function(info) return OvaleOptions.db.profile.apparence.smallIconScale end,
					set = function(info,value) OvaleOptions.db.profile.apparence.smallIconScale = value; Ovale:UpdateFrame() end
				},
				margin = 
				{
					order = 5.5,
					type = "range",
					name = L["Marge entre deux icônes"],
					min = -16, max = 64, step = 1,
					get = function(info) return OvaleOptions.db.profile.apparence.margin end,
					set = function(info,value) OvaleOptions.db.profile.apparence.margin = value; Ovale:UpdateFrame() end
				},
				iconShiftX =
				{
					order = 5.6,
					type = "range",
					name = L["Décalage horizontal des options"],
					min = -256, max = 256, step = 1,
					get = function(info) return OvaleOptions.db.profile.apparence.iconShiftX end,
					set = function(info,value) OvaleOptions.db.profile.apparence.iconShiftX = value; Ovale:UpdateFrame() end
				},
				iconShiftY =
				{
					order = 5.7,
					type = "range",
					name = L["Décalage vertical des options"],
					min = -256, max = 256, step = 1,
					get = function(info) return OvaleOptions.db.profile.apparence.iconShiftY end,
					set = function(info,value) OvaleOptions.db.profile.apparence.iconShiftY = value; Ovale:UpdateFrame() end
				},
				raccourcis =
				{
					order = 6,
					type = "toggle",
					name = L["Raccourcis clavier"],
					desc = L["Afficher les raccourcis clavier dans le coin inférieur gauche des icônes"],
					get = function(info) return OvaleOptions.db.profile.apparence.raccourcis end,
					set = function(info, value) OvaleOptions.db.profile.apparence.raccourcis = value end
				},
				numeric =
				{
					order = 7,
					type = "toggle",
					name = L["Affichage numérique"],
					desc = L["Affiche le temps de recharge sous forme numérique"],
					get = function(info) return OvaleOptions.db.profile.apparence.numeric end,
					set = function(info, value) OvaleOptions.db.profile.apparence.numeric = value end
				},
				verrouille =
				{
					order = 8,
					type = "toggle",
					name = L["Verrouiller position"],
					get = function(info) return OvaleOptions.db.profile.apparence.verrouille end,
					set = function(info, value) OvaleOptions.db.profile.apparence.verrouille = value end
				},
				vertical =
				{
					order = 9,
					type = "toggle",
					name = L["Vertical"],
					get = function(info) return OvaleOptions.db.profile.apparence.vertical end,
					set = function(info, value) OvaleOptions.db.profile.apparence.vertical = value; Ovale:UpdateFrame() end
				},
				alpha =
				{
					order = 9.5,
					type = "range",
					name = L["Opacité des icônes"],
					min = 0, max = 100, step = 5,
					get = function(info) return OvaleOptions.db.profile.apparence.alpha * 100 end,
					set = function(info, value) OvaleOptions.db.profile.apparence.alpha = value/100; Ovale.frame.frame:SetAlpha(value/100) end
				},
				optionsAlpha =
				{
					order = 9.5,
					type = "range",
					name = L["Opacité des options"],
					min = 0, max = 100, step = 5,
					get = function(info) return OvaleOptions.db.profile.apparence.optionsAlpha * 100 end,
					set = function(info, value) OvaleOptions.db.profile.apparence.optionsAlpha = value/100; Ovale.frame.content:SetAlpha(value/100) end
				},
				predictif =
				{
					order = 10,
					type = "toggle",
					name = L["Prédictif"],
					desc = L["Affiche les deux prochains sorts et pas uniquement le suivant"],
					get = function(info) return OvaleOptions.db.profile.apparence.predictif end,
					set = function(info, value) OvaleOptions.db.profile.apparence.predictif = value; Ovale:UpdateFrame() end
				},
				moving = 
				{
					order = 11,
					type = "toggle",
					name = L["Défilement"],
					desc = L["Les icônes se déplacent"],
					get = function(info) return OvaleOptions.db.profile.apparence.moving end,
					set = function(info, value) OvaleOptions.db.profile.apparence.moving = value; Ovale:UpdateFrame() end
				},
				hideEmpty =
				{
					order = 12,
					type = "toggle",
					name = L["Cacher bouton vide"],
					get = function(info) return OvaleOptions.db.profile.apparence.hideEmpty end,
					set = function(info, value) OvaleOptions.db.profile.apparence.hideEmpty = value; Ovale:UpdateFrame() end
				},
				targetHostileOnly = 
				{
					order = 13,
					type = "toggle",
					name = L["Cacher si cible amicale ou morte"],
					get = function(info) return OvaleOptions.db.profile.apparence.targetHostileOnly end,
					set = function(info, value) OvaleOptions.db.profile.apparence.targetHostileOnly = value; Ovale:UpdateFrame() end
				},
				highlightIcon =
				{
					order = 14,
					type = "toggle",
					name = L["Illuminer l'icône"],
					desc = L["Illuminer l'icône quand la technique doit être spammée"],
					get = function(info) return OvaleOptions.db.profile.apparence.highlightIcon end,
					set = function(info, value) OvaleOptions.db.profile.apparence.highlightIcon = value; Ovale:UpdateFrame() end
				},
				clickThru =
				{
					order = 15,
					type = "toggle",
					name = L["Ignorer les clics souris"],
					get = function(info) return OvaleOptions.db.profile.apparence.clickThru end,
					set = function(info, value) OvaleOptions.db.profile.apparence.clickThru = value; Ovale:UpdateFrame() end
				},
				latencyCorrection =
				{
					order = 16,
					type = "toggle",
					name = L["Correction de la latence"],
					get = function(info) return OvaleOptions.db.profile.apparence.latencyCorrection end,
					set = function(info, value) OvaleOptions.db.profile.apparence.latencyCorrection = value end
				},
				hideVehicule =
				{
					order = 17,
					type = "toggle",
					name = L["Cacher dans les véhicules"],
					get = function(info) return OvaleOptions.db.profile.apparence.hideVehicule end,
					set = function(info, value) OvaleOptions.db.profile.apparence.hideVehicule = value end
				},
				flashIcon =
				{
					order = 18,
					type = "toggle",
					name = L["Illuminer l'icône quand le temps de recharge est écoulé"],
					get = function(info) return OvaleOptions.db.profile.apparence.flashIcon end,
					set = function(info, value) OvaleOptions.db.profile.apparence.flashIcon = value; Ovale:UpdateFrame() end
				},
				targetText =
				{
					order = 19,
					type = "input",
					name = L["Caractère de portée"],
					desc = L["Ce caractère est affiché dans un coin de l'icône pour indiquer si la cible est à portée"],
					get = function(info) return OvaleOptions.db.profile.apparence.targetText end,
					set = function(info, value) OvaleOptions.db.profile.apparence.targetText = value; Ovale:UpdateFrame() end
				}
			}
		},
		code =
		{
			name = L["Code"],
			type = "group",
			args = 
			{
				code = 
				{
					order = 1,
					type = "input",
					multiline = 15,
					name = L["Code"],
					get = function(info)
						return string.gsub(OvaleOptions.db.profile.code, "\t", "    ")
					end,
					set = function(info,v)
						OvaleOptions.db.profile.code = v
						Ovale.needCompile = true
					end,
					width = "full"
				},
				restore =
				{
					order = 2,
					type = "execute",
					name = L["Restaurer le défaut"],
					func = function()
						OvaleOptions.db.profile.code = OvaleOptions.db.defaults.profile.code
						Ovale.needCompile = true
					end,
				}
			}
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
					order = -3,
					name = "Debug",
					type = "execute",
					func = function() 
						for i=1,10 do Ovale:Print(i.."="..UnitPower("player", i)) end 
						Ovale:Print(OvaleState.state.eclipse)
					end
				},
				talent =
				{
					order = -4,
					name = "List talent id",
					type = "execute",
					func = function() 
						for k,v in pairs(OvaleData.talentNameToId) do
							Ovale:Print(k.."="..v)
						end
					end
				},
				targetbuff =
				{
					order = -5,
					name = "List target buff and debuff spell id",
					type = "execute",
					func = function()
						Ovale:DebugListAura("target", "HELPFUL")
						Ovale:DebugListAura("target", "HARMFUL")
					end
				},
				buff =
				{
					order = -6,
					name = "List player buff and debuff spell id",
					type = "execute",
					func = function()
						Ovale:DebugListAura("player", "HELPFUL")
						Ovale:DebugListAura("player", "HARMFUL")
					end
				},
				glyph =
				{
					order = -7,
					name = "List player glyphs",
					type = "execute",
					func = function()
						for i=1,GetNumGlyphs() do
							local name, level, enabled, texture, spellId = GetGlyphInfo(i)
							if spellId then	Ovale:Print(name..": "..spellId.." ("..tostring(enabled)..")") end
						end
					end
				},
				spell =
				{
					order = -8,
					name = "List player spells",
					type = "execute",
					func = function()
						local book=BOOKTYPE_SPELL
						while true do
							local i=1
							while true do
								local skillType, spellId = GetSpellBookItemInfo(i, book)
								if not spellId then
									break
								end
								local spellName = GetSpellBookItemName(i, book)
								Ovale:Print(spellName..": "..spellId)
								i = i + 1
							end
							if book == BOOKTYPE_SPELL then
								book = BOOKTYPE_PET
							else
								break
							end
						end
					end					
				}
			}
		}
	}
}
--</private-static-properties>

--<public-static-methods>
function OvaleOptions:OnInitialize()
	
end

function OvaleOptions:FirstInit()
	if self.firstInit then
		return
	end
	
	self.firstInit = true

	local localizedClass, englishClass = UnitClass("player")
	self.db = LibStub("AceDB-3.0"):New("OvaleDB",
	{
		profile = 
		{
			display = true,
			code = Ovale.defaut[englishClass],
			left = 500,
			top = 500,
			check = {},
			list = {},
			apparence = {enCombat=false, iconScale = 2, secondIconScale = 1, margin = 4, fontScale = 0.5, iconShiftX = 0, iconShiftY = 0,
				smallIconScale=1, raccourcis=true, numeric=false, avecCible = false,
				verrouille = false, vertical = false, predictif=false, highlightIcon = true, clickThru = false, 
				latencyCorrection=true, hideVehicule=false, flashIcon=true, targetText = "●", alpha = 1,
				optionsAlpha = 1, updateInterval=0.1}
		}
	})
	
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	AceConfig:RegisterOptionsTable("Ovale", options.args.code)
	AceConfig:RegisterOptionsTable("Ovale Actions", options.args.actions, "Ovale")
	AceConfig:RegisterOptionsTable("Ovale Profile", options.args.profile)
	AceConfig:RegisterOptionsTable("Ovale Apparence", options.args.apparence)

	AceConfigDialog:AddToBlizOptions("Ovale", "Ovale")
	AceConfigDialog:AddToBlizOptions("Ovale Profile", "Profile", "Ovale")
	AceConfigDialog:AddToBlizOptions("Ovale Apparence", "Apparence", "Ovale")
	
	self.db.RegisterCallback( self, "OnNewProfile", "HandleProfileChanges" )
	self.db.RegisterCallback( self, "OnProfileReset", "HandleProfileChanges" )
	self.db.RegisterCallback( self, "OnProfileChanged", "HandleProfileChanges" )
	self.db.RegisterCallback( self, "OnProfileCopied", "HandleProfileChanges" )
	
	if self.db.profile.code then
		Ovale.needCompile = true
	end
end

function OvaleOptions:HandleProfileChanges()
	if self.firstInit then
		if (self.db.profile.code) then
			Ovale.needCompile = true
		end
	end
end

function OvaleOptions:OnEnable()
	self:FirstInit()
	
end

function OvaleOptions:GetApparence()
	self:FirstInit()
	return self.db.profile.apparence
end

function OvaleOptions:GetProfile()
	self:FirstInit()
	return self.db.profile
end

--</public-static-methods>
