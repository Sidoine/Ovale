local L = LibStub("AceLocale-3.0"):GetLocale("Ovale")

Ovale = LibStub("AceAddon-3.0"):NewAddon("Ovale", "AceEvent-3.0", "AceConsole-3.0")
local Recount = Recount
local Skada = Skada

--Default scripts (see "defaut" directory)
Ovale.defaut = {}
--The table of check boxes definition
Ovale.casesACocher = {}
--key: spell name / value: action icon id
Ovale.actionSort = {}
--key: talentId / value: points in this talent
Ovale.pointsTalent = {}
--key: talentId / value: talent name (not used)
Ovale.talentIdToName = {}
Ovale.spellList = {}
--key: talent name / value: talent id
Ovale.talentNameToId = {}
--allows to do some initialization the first time the addon is enabled
Ovale.firstInit = false
--allows to fill the player talent tables on first use
Ovale.listeTalentsRemplie = false
--the frame with the icons
Ovale.frame = nil
--check boxes GUI items
Ovale.checkBoxes = {}
--drop down GUI items
Ovale.dropDowns = {}
--master nodes of the current script (one node for each icon)
Ovale.masterNodes = nil
--set it if there was a bug, traces will be enabled on next frame
Ovale.bug = false
--trace next script function calls
Ovale.trace=false
--in combat?
Ovale.enCombat = false
--current computed spell haste
Ovale.spellHaste = 0
--current computed melee haste TODO: why I don't use character sheet value anyway?
Ovale.meleeHaste = 0
--current auras
Ovale.aura = { player = {}, target = {}}
--allow to track the current target
Ovale.targetGUID = nil
--spell info from the current script (by spellId)
Ovale.spellInfo = {}
--track when a buff was applied (used for the old eclipse mechanism, maybe this could be removed?)
Ovale.buff = {}
--player class
Ovale.className = nil
--the state in the current frame
--TODO: really, the simulator should be in its own class
Ovale.state = {rune={}, cd = {}, counter={}}
--spells that count for scoring
Ovale.scoreSpell = {}
--tracks debuffs on the units that are not the current target
Ovale.otherDebuffs = {}
--score in current combat
Ovale.score = 0
--maximal theoric score in current combat
Ovale.maxScore = 0
--increased at each frame, allows to know if the aura was updated this frame
--TODO: aura should be tracked using combat log events or something like that
--and it should be in its own class
Ovale.serial = 0
--spell counter (see Counter function)
Ovale.counter = {}
--the spells that the player has casted but that did not reach their target
--the result is computed by the simulator, allowing to ignore lag or missile travel time
Ovale.lastSpell = {}
--the damage of the last spell or dot (by id)
Ovale.spellDamage = {}
Ovale.numberOfEnemies = nil
Ovale.enemies = {}
Ovale.refreshNeeded = false

Ovale.buffSpellList =
{
	fear =
	{
		5782, -- Fear
		5484, -- Howl of terror
		5246, -- Intimidating Shout 
		8122, -- Psychic scream
	},
	root =
	{
		23694, -- Improved Hamstring
		339, -- Entangling Roots
		122, -- Frost Nova
		47168, -- Improved Wing Clip
	},
	incapacitate = 
	{
		6770, -- Sap
		12540, -- Gouge
		20066, -- Repentance
	},
	stun = 
	{
		5211, -- Bash
		44415, -- Blackout
		6409, -- Cheap Shot
		22427, -- Concussion Blow
		853, -- Hammer of Justice
		408, -- Kidney Shot
		46968, -- Shockwave
	},
	strengthagility=
	{
		6673, -- Battle Shout
		8076, -- Strength of Earth
		57330, -- Horn of Winter
		93435 --Roar of Courage (Cat, Spirit Beast)
	},
	stamina =
	{
		21562, -- Fortitude TODO: vérifier
		469, -- Commanding Shout
		6307, -- Blood Pact
		90364 -- Qiraji Fortitude
	},
	lowerarmor=
	{
		58567, -- Sunder Armor (x3)
		8647, -- Expose Armor
		91565, -- Faerie Fire (x3)
		35387, --Corrosive Spit (x3 Serpent)
		50498 --Tear Armor (x3 Raptor)
	},
	magicaldamagetaken=
	{
		65142, -- Ebon Plague
		60433, -- Earth and Moon
		93068, -- Master Poisoner 
		1490, -- Curse of the Elements
		85547, -- Jinx 1
		86105, -- Jinx 2
		34889, --Fire Breath (Dragonhawk)
		24844 --Lightning Breath (Wind serpent)
	},
	magicalcrittaken=
    {
        17800, -- Shadow and Flame
        22959 -- Critical Mass
    },
	-- physicaldamagetaken
	lowerphysicaldamage=
	{
		99, -- Demoralizing Roar
		702, -- Curse of Weakness
		1160, -- Demoralizing Shout
		26017, -- Vindication
		81130, -- Scarlet Fever
		50256 --Demoralizing Roar (Bear)
	},
	meleeslow=
	{
		55095, --Icy Touch
		58179, --Infected Wounds rank 1
		58180, --Infected Wounds rank 2
		68055, --Judgments of the just
		6343, --Thunderclap
		8042, --Earth Shock
		50285 --Dust Cloud (Tallstrider)
	},
	castslow =
	{
		1714, --Curse of Tongues
        58604, --Lava Breath (Core Hound)
        50274, --Spore Cloud (Sporebat)
        5761, --Mind-numbing Poison
        73975, --Necrotic Strike
        31589 --Slow
	},
	bleed=
	{
		33876, --Mangle cat
		33878, --Mangle bear
		46856, -- Trauma rank 1
		46857, -- Trauma rank 2
		16511, --Hemorrhage
		50271, --Tendon Rip (Hyena)
		35290 --Gore (Boar)
	},
	heroism=
	{
		2825, --Bloodlust
		32182, --Heroism
		80353, --Time warp
		90355 -- Ancient Hysteria (Core Hound)
	},
	meleehaste =
	{
		8515, -- Windfury
		55610, -- Improved Icy Talons
		53290 -- Hunting Party
	},
	spellhaste = 
	{
		24907, -- Moonkin aura
		2895 -- Wrath of Air Totem
	}
}


--Key bindings
BINDING_HEADER_OVALE = "Ovale"
BINDING_NAME_OVALE_CHECKBOX0 = L["Inverser la boîte à cocher "].."(1)"
BINDING_NAME_OVALE_CHECKBOX1 = L["Inverser la boîte à cocher "].."(2)"
BINDING_NAME_OVALE_CHECKBOX2 = L["Inverser la boîte à cocher "].."(3)"
BINDING_NAME_OVALE_CHECKBOX3 = L["Inverser la boîte à cocher "].."(4)"
BINDING_NAME_OVALE_CHECKBOX4 = L["Inverser la boîte à cocher "].."(5)"

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
						return Ovale.db.profile.apparence.enCombat
					end,
					set = function(info, v)
						Ovale.db.profile.apparence.enCombat = v
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
						return Ovale.db.profile.apparence.avecCible
					end,
					set = function(info, v)
						Ovale.db.profile.apparence.avecCible = v
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
					get = function(info) return Ovale.db.profile.apparence.iconScale end,
					set = function(info,value) Ovale.db.profile.apparence.iconScale = value; Ovale:UpdateFrame() end
				},
				fontScale = 
				{
					order = 3,
					type = "range",
					name = L["Taille des polices"],
					desc = L["La taille des polices"],
					min = 0.1, max = 2, step = 0.1,
					get = function(info) return Ovale.db.profile.apparence.fontScale end,
					set = function(info,value) Ovale.db.profile.apparence.fontScale = value; Ovale:UpdateFrame() end
				},
				smallIconScale = 
				{
					order = 4,
					type = "range",
					name = L["Taille des petites icônes"],
					desc = L["La taille des petites icônes"],
					min = 0.1, max = 16, step = 0.1,
					get = function(info) return Ovale.db.profile.apparence.smallIconScale end,
					set = function(info,value) Ovale.db.profile.apparence.smallIconScale = value; Ovale:UpdateFrame() end
				},
				margin = 
				{
					order = 5.5,
					type = "range",
					name = L["Marge entre deux icônes"],
					min = -16, max = 64, step = 1,
					get = function(info) return Ovale.db.profile.apparence.margin end,
					set = function(info,value) Ovale.db.profile.apparence.margin = value; Ovale:UpdateFrame() end
				},
				iconShiftX =
				{
					order = 5.6,
					type = "range",
					name = L["Décalage horizontal des options"],
					min = -256, max = 256, step = 1,
					get = function(info) return Ovale.db.profile.apparence.iconShiftX end,
					set = function(info,value) Ovale.db.profile.apparence.iconShiftX = value; Ovale:UpdateFrame() end
				},
				iconShiftY =
				{
					order = 5.7,
					type = "range",
					name = L["Décalage vertical des options"],
					min = -256, max = 256, step = 1,
					get = function(info) return Ovale.db.profile.apparence.iconShiftY end,
					set = function(info,value) Ovale.db.profile.apparence.iconShiftY = value; Ovale:UpdateFrame() end
				},
				raccourcis =
				{
					order = 6,
					type = "toggle",
					name = L["Raccourcis clavier"],
					desc = L["Afficher les raccourcis clavier dans le coin inférieur gauche des icônes"],
					get = function(info) return Ovale.db.profile.apparence.raccourcis end,
					set = function(info, value) Ovale.db.profile.apparence.raccourcis = value end
				},
				numeric =
				{
					order = 7,
					type = "toggle",
					name = L["Affichage numérique"],
					desc = L["Affiche le temps de recharge sous forme numérique"],
					get = function(info) return Ovale.db.profile.apparence.numeric end,
					set = function(info, value) Ovale.db.profile.apparence.numeric = value end
				},
				verrouille =
				{
					order = 8,
					type = "toggle",
					name = L["Verrouiller position"],
					get = function(info) return Ovale.db.profile.apparence.verrouille end,
					set = function(info, value) Ovale.db.profile.apparence.verrouille = value end
				},
				vertical =
				{
					order = 9,
					type = "toggle",
					name = L["Vertical"],
					get = function(info) return Ovale.db.profile.apparence.vertical end,
					set = function(info, value) Ovale.db.profile.apparence.vertical = value; Ovale:UpdateFrame() end
				},
				alpha =
				{
					order = 9.5,
					type = "range",
					name = L["Opacité des icônes"],
					min = 0, max = 100, step = 5,
					get = function(info) return Ovale.db.profile.apparence.alpha * 100 end,
					set = function(info, value) Ovale.db.profile.apparence.alpha = value/100; Ovale.frame.frame:SetAlpha(value/100) end
				},
				optionsAlpha =
				{
					order = 9.5,
					type = "range",
					name = L["Opacité des options"],
					min = 0, max = 100, step = 5,
					get = function(info) return Ovale.db.profile.apparence.optionsAlpha * 100 end,
					set = function(info, value) Ovale.db.profile.apparence.optionsAlpha = value/100; Ovale.frame.content:SetAlpha(value/100) end
				},
				predictif =
				{
					order = 10,
					type = "toggle",
					name = L["Prédictif"],
					desc = L["Affiche les deux prochains sorts et pas uniquement le suivant"],
					get = function(info) return Ovale.db.profile.apparence.predictif end,
					set = function(info, value) Ovale.db.profile.apparence.predictif = value; Ovale:UpdateFrame() end
				},
				moving = 
				{
					order = 11,
					type = "toggle",
					name = L["Défilement"],
					desc = L["Les icônes se déplacent"],
					get = function(info) return Ovale.db.profile.apparence.moving end,
					set = function(info, value) Ovale.db.profile.apparence.moving = value; Ovale:UpdateFrame() end
				},
				hideEmpty =
				{
					order = 12,
					type = "toggle",
					name = L["Cacher bouton vide"],
					get = function(info) return Ovale.db.profile.apparence.hideEmpty end,
					set = function(info, value) Ovale.db.profile.apparence.hideEmpty = value; Ovale:UpdateFrame() end
				},
				targetHostileOnly = 
				{
					order = 13,
					type = "toggle",
					name = L["Cacher si cible amicale ou morte"],
					get = function(info) return Ovale.db.profile.apparence.targetHostileOnly end,
					set = function(info, value) Ovale.db.profile.apparence.targetHostileOnly = value; Ovale:UpdateFrame() end
				},
				highlightIcon =
				{
					order = 14,
					type = "toggle",
					name = L["Illuminer l'icône"],
					desc = L["Illuminer l'icône quand la technique doit être spammée"],
					get = function(info) return Ovale.db.profile.apparence.highlightIcon end,
					set = function(info, value) Ovale.db.profile.apparence.highlightIcon = value; Ovale:UpdateFrame() end
				},
				clickThru =
				{
					order = 15,
					type = "toggle",
					name = L["Ignorer les clics souris"],
					get = function(info) return Ovale.db.profile.apparence.clickThru end,
					set = function(info, value) Ovale.db.profile.apparence.clickThru = value; Ovale:UpdateFrame() end
				},
				latencyCorrection =
				{
					order = 16,
					type = "toggle",
					name = L["Correction de la latence"],
					get = function(info) return Ovale.db.profile.apparence.latencyCorrection end,
					set = function(info, value) Ovale.db.profile.apparence.latencyCorrection = value end
				},
				hideVehicule =
				{
					order = 17,
					type = "toggle",
					name = L["Cacher dans les véhicules"],
					get = function(info) return Ovale.db.profile.apparence.hideVehicule end,
					set = function(info, value) Ovale.db.profile.apparence.hideVehicule = value end
				},
				flashIcon =
				{
					order = 18,
					type = "toggle",
					name = L["Illuminer l'icône quand le temps de recharge est écoulé"],
					get = function(info) return Ovale.db.profile.apparence.flashIcon end,
					set = function(info, value) Ovale.db.profile.apparence.flashIcon = value; Ovale:UpdateFrame() end
				},
				targetText =
				{
					order = 19,
					type = "input",
					name = L["Caractère de portée"],
					desc = L["Ce caractère est affiché dans un coin de l'icône pour indiquer si la cible est à portée"],
					get = function(info) return Ovale.db.profile.apparence.targetText end,
					set = function(info, value) Ovale.db.profile.apparence.targetText = value; Ovale:UpdateFrame() end
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
						return string.gsub(Ovale.db.profile.code, "\t", "    ")
					end,
					set = function(info,v)
						Ovale.db.profile.code = v
						Ovale.needCompile = true
					end,
					width = "full"
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
						Ovale.db.profile.display = true
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
						Ovale.db.profile.display = false
						Ovale.frame:Hide()	
					end
				},
				config  =
				{
					name = "Configuration",
					type = "execute",
					func = function() Ovale:AfficherConfig() end
				},
				code  =
				{
					name = "Code",
					type = "execute",
					func = function() Ovale:AfficherCode() end
				},
				debug =
				{
					order = -3,
					name = "Debug",
					type = "execute",
					func = function() 
						for i=1,10 do Ovale:Print(i.."="..UnitPower("player", i)) end 
						Ovale:Print(Ovale.state.eclipse)
					end
				},
				talent =
				{
					order = -4,
					name = "List talent id",
					type = "execute",
					func = function() 
						for k,v in pairs(Ovale.talentNameToId) do
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

local function nilstring(text)
	if text == nil then
		return "nil"
	else
		return text
	end
end

function Ovale:Debug()
	self:Print(self:DebugNode(self.masterNodes[1]))
end

function Ovale:DebugListAura(target, filter)
	local i = 1
	while true do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId =  UnitAura(target, i, filter)
		if not name then
			break
		end
		Ovale:Print(name..": "..spellId)
		i = i + 1
	end
end

function Ovale:OnInitialize()
	self.AceConfig = LibStub("AceConfig-3.0");
	self.AceConfigDialog = LibStub("AceConfigDialog-3.0");
end

function Ovale:GetOtherDebuffs(spellId)
	if not self.otherDebuffs[spellId] then
		self.otherDebuffs[spellId] = {}
	end
	return self.otherDebuffs[spellId]
end

function Ovale:WithHaste(temps, hate)
	if not temps then
		temps = 0
	end
	if (not hate) then
		return temps
	elseif (hate == "spell") then
		return temps/(1+self.spellHaste/100)
	elseif (hate == "melee") then
		return temps/(1+self.meleeHaste/100)
	else
		return temps
	end
end

function Ovale:CompileAll()
	if self.db.profile.code then
		self.masterNodes = self:Compile(self.db.profile.code)
		self.refreshNeeded = true
		self:UpdateFrame()
		self.needCompile = false
	end
end

function Ovale:HandleProfileChanges()
	if (self.firstInit) then
		if (self.db.profile.code) then
			self.needCompile = true
		end
	end
end

function Ovale:FirstInit()
	self:RemplirActionIndexes()
	self:RemplirListeTalents()
	self:FillSpellList()
	
	local playerClass, englishClass = UnitClass("player")
	self.className = englishClass
	if self.className == "DEATHKNIGHT" then
		for i=1,6 do
			self.state.rune[i] = {}
		end
	end
	
	self:ChargerDefaut()
	
	self.frame = LibStub("AceGUI-3.0"):Create("OvaleFrame")

	self.frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",self.db.profile.left,self.db.profile.top)

	self.firstInit = true
	
	
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	self.AceConfig:RegisterOptionsTable("Ovale", options.args.code)
	self.AceConfig:RegisterOptionsTable("Ovale Actions", options.args.actions, "Ovale")
	self.AceConfig:RegisterOptionsTable("Ovale Profile", options.args.profile)
	self.AceConfig:RegisterOptionsTable("Ovale Apparence", options.args.apparence)

	self.AceConfigDialog:AddToBlizOptions("Ovale", "Ovale")
	self.AceConfigDialog:AddToBlizOptions("Ovale Profile", "Profile", "Ovale")
	self.AceConfigDialog:AddToBlizOptions("Ovale Apparence", "Apparence", "Ovale")
	
	self.db.RegisterCallback( self, "OnNewProfile", "HandleProfileChanges" )
	self.db.RegisterCallback( self, "OnProfileReset", "HandleProfileChanges" )
	self.db.RegisterCallback( self, "OnProfileChanged", "HandleProfileChanges" )
	self.db.RegisterCallback( self, "OnProfileCopied", "HandleProfileChanges" )

	
	if (self.db.profile.code) then
		self.needCompile = true
	end
	self:UpdateFrame()
	if (not Ovale.db.profile.display) then
		self.frame:Hide()
	end
end

function Ovale:OnEnable()
    -- Called when the addon is enabled
    self:RegisterEvent("PLAYER_REGEN_ENABLED");
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
    self:RegisterEvent("SPELLS_CHANGED")
    self:RegisterEvent("PLAYER_TALENT_UPDATE")
    self:RegisterEvent("CHARACTER_POINTS_CHANGED")
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
    self:RegisterEvent("UPDATE_BINDINGS");
    self:RegisterEvent("UNIT_AURA");
    self:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("GLYPH_UPDATED")
	self:RegisterEvent("GLYPH_ADDED")
	    
	if (not self.firstInit) then
		self:FirstInit()
	end
	self:UNIT_AURA("","player")
	
	self:UpdateVisibility()
end

function Ovale:OnDisable()
    -- Called when the addon is disabled
	self:UnregisterEvent("ACTIONBAR_PAGE_CHANGED")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:UnregisterEvent("PLAYER_REGEN_DISABLED")
    self:UnregisterEvent("PLAYER_TALENT_UPDATE")
    self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
    self:UnregisterEvent("SPELLS_CHANGED")
    self:UnregisterEvent("CHARACTER_POINTS_CHANGED")
    self:UnregisterEvent("UPDATE_BINDINGS")
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:UnregisterEvent("UNIT_SPELLCAST_START")
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:UnregisterEvent("CHAT_MSG_ADDON")
    self:UnregisterEvent("GLYPH_UPDATED")	
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self.frame:Hide()
end

function Ovale:ACTIONBAR_SLOT_CHANGED(event, slot, unknown)
	if (slot == 0) then
		self:RemplirActionIndexes()
	elseif (slot) then
	-- on reçoit aussi si c'est une macro avec mouseover à chaque fois que la souris passe sur une cible!
		self:RemplirActionIndex(tonumber(slot))
	end
end

function Ovale:ACTIONBAR_PAGE_CHANGED()
	-- self:RemplirActionIndexes()
end

function Ovale:CHARACTER_POINTS_CHANGED()
	self:RemplirListeTalents()
--	self:Print("CHARACTER_POINTS_CHANGED")
end

function Ovale:PLAYER_TALENT_UPDATE()
	self:RemplirListeTalents()
--	self:Print("PLAYER_TALENT_UPDATE")
end

--The user learnt a new spell
function Ovale:SPELLS_CHANGED()
	-- self:RemplirActionIndexes()
	-- self:RemplirListeTalents()
	self:FillSpellList()
	self.needCompile = true
end

--Called when the user changed his key bindings
function Ovale:UPDATE_BINDINGS()
	self:RemplirActionIndexes()
end

--Called for each combat log event
function Ovale:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local time, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = select(1, ...)
	if sourceName == UnitName("player") then
		--self:Print("event="..event.." source="..nilstring(sourceName).." destName="..nilstring(destName).." " ..GetTime())
		
		if string.find(event, "SPELL_PERIODIC_DAMAGE")==1 or string.find(event, "SPELL_DAMAGE")==1 then
			local spellId, spellName, spellSchool, amount = select(9, ...)
			self.spellDamage[spellId] = amount
		end
		
		--Called when a missile reached or missed its target
		--Update lastSpell accordingly
		--Do not use SPELL_CAST_SUCCESS because it is sent when the missile has not reached the target
		
		if 
				string.find(event, "SPELL_AURA_APPLIED")==1
				or string.find(event, "SPELL_DAMAGE")==1 
				or string.find(event, "SPELL_MISSED") == 1 
				or string.find(event, "SPELL_CAST_FAILED") == 1 then
			local spellId, spellName = select(9, ...)
			for i,v in ipairs(self.lastSpell) do
				if v.spellId == spellId then
					if not v.channeled then
						table.remove(self.lastSpell, i)
						self.refreshNeeded = true
						--self:Print("LOG_EVENT on supprime "..spellId.." a "..GetTime())
					end
					--self:Print(UnitDebuff("target", "Etreinte de l'ombre"))
					break
				end
			end
		end
		if self.otherDebuffsEnabled then
			--Track debuffs on units that are not the current target
			if string.find(event, "SPELL_AURA_") == 1 then
				local spellId, spellName, spellSchool, auraType = select(9, ...)
				if auraType == "DEBUFF" and self.spellInfo[spellId] and self.spellInfo[spellId].duration then
					local otherDebuff = self:GetOtherDebuffs(spellId)
					if event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" then
						otherDebuff[destGUID] = Ovale.maintenant + self:WithHaste(self.spellInfo[spellId].duration, self.spellInfo[spellId].durationhaste)
						self.refreshNeeded = true
					--	self:Print("ajout de "..spellName.." à "..destGUID)
					elseif event == "SPELL_AURA_REMOVED" then
						otherDebuff[destGUID] = nil
						self.refreshNeeded = true
					--	self:Print("suppression de "..spellName.." de "..destGUID)
					end	
				end
			end
		end
		--if string.find(event, "SWING")==1 then
		--	self:Print(select(1, ...))
		--end
	end
	
	if self.numberOfEnemies then
		if event == "UNIT_DIED" then
			for k,v in pairs(self.enemies) do
				if k==destGUID then
					self.enemies[v] = nil
					self.numberOfEnemies = self.numberOfEnemies - 1
					self.refreshNeeded = true
					--self:Print("enemy die")
				end
			end
		elseif sourceFlags and not self.enemies[sourceGUID] and bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE)>0 
					and bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0 and
				destFlags and bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
			self.enemies[sourceGUID] = true
			--self:Print("new ennemy source=".. sourceName)
			self.numberOfEnemies = self.numberOfEnemies + 1
			self.refreshNeeded = true
		elseif destGUID and not self.enemies[destGUID] and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE)>0 
					and bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0 and
				sourceFlags and bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
			self.enemies[destGUID] = true
			--self:Print("new ennemy dest=".. destName)
			self.numberOfEnemies = self.numberOfEnemies + 1
			self.refreshNeeded = true
		end
	end
	
	if self.otherDebuffsEnabled then
		if event == "UNIT_DIED" then
			--Remove any dead unit from otherDebuffs
			for k,v in pairs(self.otherDebuffs) do
				for j,w in pairs(v) do
					if j==destGUID then
						v[j] = nil
						self.refreshNeeded = true
					end
				end
			end
		end
	end
end

--Called when the player target change
--Used to update the visibility e.g. if the user chose
--to hide Ovale if a friendly unit is targeted
function Ovale:PLAYER_TARGET_CHANGED()
	self.refreshNeeded = true
	self:UpdateVisibility()
end

--Called when a new aura is added to an unit
--At this time it is not used to keep the aura list (may be used in the future for optimization)
--It is only used to update haste
function Ovale:UNIT_AURA(event, unit)
	if (unit == "player") then
		local hateBase = GetCombatRatingBonus(18)
		local hateCommune=0;
		local hateSorts = 0;
		local hateCaC = 0;
		local hateHero = 0
		local hateClasse = 0
		local i=1;
		
		while (true) do
			local name, rank, iconTexture, count, debuffType, duration, expirationTime, source, stealable, consolidate, spellId =  UnitBuff("player", i);
			if (not name) then
				break
			end
			if (not self.buff[spellId]) then
				self.buff[spellId] = {}
			end
			self.buff[spellId].icon = iconTexture
			self.buff[spellId].count = count
			self.buff[spellId].duration = duration
			self.buff[spellId].expirationTime = expirationTime
			self.buff[spellId].source = source
			if (not self.buff[spellId].present) then
				self.buff[spellId].gain = Ovale.maintenant
			end
			self.buff[spellId].lastSeen = Ovale.maintenant
			self.buff[spellId].present = true
			
			if self.buffSpellList.spellhaste[spellId] then --moonkin aura / wrath of air
				hateSorts = 5 --add shadow form?
			elseif self.buffSpellList.meleehaste[spellId] then 
				hateCaC = 10
			elseif self.buffSpellList.heroism[spellId] then
				hateHero = 30
			elseif spellId == 53657 then --judgements of the pure
				hateClasse = 9
			end
			i = i + 1;
		end
		
		for k,v in pairs(self.buff) do
			if (v.lastSeen ~= Ovale.maintenant) then
				v.present = false
			end
		end
		
		self.spellHaste = hateBase + hateCommune + hateSorts + hateHero + hateClasse
		self.meleeHaste = hateBase + hateCommune + hateCaC + hateHero + hateClasse
		
		self.refreshNeeded = true
--		self.rangedHaste = hateBase + hateCommune + hateHero + hateClasse -- TODO ajouter le bidule du chasseur en spé bête
--		print("spellHaste = "..self.spellHaste)
	end
end

--Called when a glyph has been added
--The script needs to be compiled
function Ovale:GLYPH_ADDED(event)
	self.needCompile = true
end

--Called when a glyph has been updated
--The script needs to be compiled
function Ovale:GLYPH_UPDATED(event)
	self.needCompile = true
end

function Ovale:GetNumberOfEnemies()
	if not self.numberOfEnemies then
		self.numberOfEnemies = 0
	end
	return self.numberOfEnemies
end

function Ovale:RemoveSpellFromList(spellId, lineId)
	for i,v in ipairs(self.lastSpell) do
		if v.lineId == lineId then
			table.remove(self.lastSpell, i)
			--self:Print("RemoveSpellFromList on supprime "..spellId)
			break
		end
	end
	self.refreshNeeded = true
end

--Called if the player interrupted early his cast
--The spell is removed from the lastSpell table
function Ovale:UNIT_SPELLCAST_INTERRUPTED(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		--self:Print("UNIT_SPELLCAST_INTERRUPTED "..event.." name="..name.." lineId="..lineId.." spellId="..spellId.. " time="..GetTime())
		self:RemoveSpellFromList(spellId, lineId)
	end
end

function Ovale:UNIT_SPELLCAST_SUCCEEDED(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		--self:Print("UNIT_SPELLCAST_SUCCEEDED "..event.." name="..name.." lineId="..lineId.." spellId="..spellId.. " time="..GetTime())
		for i,v in ipairs(self.lastSpell) do
			if v.lineId == lineId then
				--Already added in UNIT_SPELLCAST_START
				return
			end
		end
		if not UnitChannelInfo("player") then
			--A UNIT_SPELLCAST_SUCCEEDED is received when channeling a spell, with a different lineId!
			local now = GetTime()
			self:AddSpellToList(spellId, lineId, now, now, false)
		end
	end
end

function Ovale:SendScoreToDamageMeter(name, guid, scored, scoreMax)
	if Recount then
		local source = Recount.db2.combatants[name]
		if source then
			Recount:AddAmount(source,"Ovale",scored)
			Recount:AddAmount(source,"OvaleMax",scoreMax)
		end
	end
	if Skada then
		if not guid or not Skada.current or not Skada.total then return end
		local player = Skada:get_player(Skada.current, guid, nil)
		if not player then return end
		if not player.ovale then player.ovale = 0 end
		if not player.ovaleMax then player.ovaleMax = 0 end
		player.ovale = player.ovale + scored
		player.ovaleMax = player.ovaleMax + scoreMax
		player = Skada:get_player(Skada.total, guid, nil)
		player.ovale = player.ovale + scored
		player.ovaleMax = player.ovaleMax + scoreMax
	end
end

function Ovale:AddSpellToList(spellId, lineId, startTime, endTime, channeled)
	local newSpell = {}
	newSpell.spellId = spellId
	newSpell.lineId = lineId
	newSpell.start = startTime
	newSpell.stop = endTime
	newSpell.channeled = channeled
		
	self.lastSpell[#self.lastSpell+1] = newSpell
	--self:Print("on ajoute "..spellId..": ".. newSpell.start.." to "..newSpell.stop.." ("..self.maintenant..")" ..#self.lastSpell)
	
	if self.spellInfo[spellId] then
		local si = self.spellInfo[spellId]
		--self:Print("spellInfo found")
		if si and si.buffnocd and UnitBuff("player", GetSpellInfo(si.buffnocd)) then
			newSpell.nocd = true
		else
			newSpell.nocd = false
		end
		--Increase or reset the counter that is used by the Counter function
		if si.resetcounter then
			self.counter[si.resetcounter] = 0
			--self:Print("reset counter "..si.resetcounter)
		end
		if si.inccounter then
			local cname = si.inccounter
			if not self.counter[cname] then
				self.counter[cname] = 0
			end
			self.counter[cname] = self.counter[cname] + 1
			--self:Print("inc counter "..cname.." to "..self.counter[cname])
		end
	end
	
	if self.enCombat then
		--self:Print(tostring(self.scoreSpell[spellId]))
		if (not self.spellInfo[spellId] or not self.spellInfo[spellId].toggle) and self.scoreSpell[spellId] then
			--Compute the player score
			local scored = self.frame:GetScore(spellId)
			--self:Print("Scored "..scored)
			if scored~=nil then
				self.score = self.score + scored
				self.maxScore = self.maxScore + 1
				self:SendScoreToDamageMeter(UnitName("player"), UnitGUID("player"), scored, 1)
			end
		end
	end
	self.refreshNeeded = true
end

function Ovale:GetCounterValue(id)
	if self.state.counter[id] then
		return self.state.counter[id]
	elseif self.counter[id] then
		return self.counter[id]
	else
		return 0
	end
end

function Ovale:UNIT_SPELLCAST_CHANNEL_START(event, unit, name, rank, lineId, spellId)
	if unit=="player" then
		--self:Print("UNIT_SPELLCAST_CHANNEL_START "..event.." name="..name.." lineId="..lineId.." spellId="..spellId)
		local _,_,_,_,startTime, endTime = UnitChannelInfo("player")
		--self:Print("startTime = " ..startTime.." endTime = "..endTime)
		self:AddSpellToList(spellId, lineId, startTime/1000, endTime/1000, true)
	end
end

function Ovale:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		--self:Print("UNIT_SPELLCAST_CHANNEL_STOP "..event.." name="..name.." lineId="..lineId.." spellId="..spellId)
		self:RemoveSpellFromList(spellId, lineId)
	end
end

--Called when a spell started its cast
function Ovale:UNIT_SPELLCAST_START(event, unit, name, rank, lineId, spellId)
	--self:Print("UNIT_SPELLCAST_START "..event.." name="..name.." lineId="..lineId.." spellId="..spellId)
	if unit=="player" then
		local _,_,_,_,startTime,endTime = UnitCastingInfo("player")
		--local spell, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellId)
		--local startTime =  GetTime()
		--self:AddSpellToList(spellId, lineId, startTime, startTime + castTime/1000)
		self:AddSpellToList(spellId, lineId, startTime/1000, endTime/1000)
	end
end

function Ovale:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	if prefix ~= "Ovale" then return end
	if type ~= "RAID" and type~= "PARTY" then return end

	local value, maxValue, guid = strsplit(";", msg)
	self:SendScoreToDamageMeter(author, guid, value, maxValue)
end

function Ovale:PLAYER_REGEN_ENABLED()
	self.enCombat = false
	self:UpdateVisibility()
	-- if self.maxScore and self.maxScore > 0 then
	-- 	self:Print((self.score/self.maxScore*100).."%")
	-- end
end

function Ovale:PLAYER_REGEN_DISABLED()
	if self.maxScore>0 then
		SendAddonMessage("Ovale", self.score..";"..self.maxScore..";"..UnitGUID("player"), "RAID")
	end
	self.enCombat = true
	self.score = 0
	self.maxScore = 0
	self.combatStartTime = self.maintenant
	if self.numberOfEnemies then
		self.numberOfEnemies = 0
		self.enemies = {}
	end
	self:UpdateVisibility()
end

function Ovale:ChercherShortcut(id)
-- ACTIONBUTTON1..12 => principale (1..12, 13..24, 73..108)
-- MULTIACTIONBAR1BUTTON1..12 => bas gauche (61..72)
-- MULTIACTIONBAR2BUTTON1..12 => bas droite (49..60)
-- MULTIACTIONBAR3BUTTON1..12 => haut droit (25..36)
-- MULTIACTIONBAR4BUTTON1..12 => haut gauche (37..48)
	local name;
	if (id<=24 or id>72) then
		name = "ACTIONBUTTON"..(((id-1)%12)+1);
	elseif (id<=36) then
		name = "MULTIACTIONBAR3BUTTON"..(id-24);
	elseif (id<=48) then
		name = "MULTIACTIONBAR4BUTTON"..(id-36);
	elseif (id<=60) then
		name = "MULTIACTIONBAR2BUTTON"..(id-48);
	else
		name = "MULTIACTIONBAR1BUTTON"..(id-60);
	end
	local key = GetBindingKey(name);
--[[	if (not key) then
		DEFAULT_CHAT_FRAME:AddMessage(id.."=>"..name.." introuvable")
	else
		DEFAULT_CHAT_FRAME:AddMessage(id.."=>"..name.."="..key)
	end]]
	return key;
end

function Ovale:GetSpellInfoOrNil(spell)
	if (spell) then
		return GetSpellInfo(spell)
	else
		return nil
	end
end

function Ovale:RemplirActionIndex(i)
	self.shortCut[i] = self:ChercherShortcut(i)
	local actionText = GetActionText(i)
	if actionText then
		self.actionMacro[actionText] = i
	else
		local type, spellId = GetActionInfo(i);
		if (type=="spell") then
			self.actionSort[spellId] = i
		elseif (type =="item") then
			self.actionObjet[spellId] = i
		end
	end
end

function Ovale:RemplirActionIndexes()
	self.actionSort = {}
	self.actionMacro = {}
	self.actionObjet = {}
	self.shortCut = {}
	for i=1,120 do
		self:RemplirActionIndex(i)
	end
end

function Ovale:FillSpellList()
	self.spellList = {}
	local book=BOOKTYPE_SPELL
	while true do
		local i=1
		while true do
			local skillType, spellId = GetSpellBookItemInfo(i, book)
			if not spellId then
				break
			end
			if skillType~="FUTURESPELL" then
				local spellName = GetSpellBookItemName(i, book)
				self.spellList[spellId] = spellName
			end
			i = i + 1
		end
		if book==BOOKTYPE_SPELL then
			book = BOOKTYPE_PET
		else
			break
		end
	end
end

function Ovale:RemplirListeTalents()
	local numTabs = GetNumTalentTabs();
	for t=1, numTabs do
		local numTalents = GetNumTalents(t);
		for i=1, numTalents do
			local nameTalent, icon, tier, column, currRank, maxRank = GetTalentInfo(t,i);
			local link = GetTalentLink(t,i)
			if link then
				local a, b, talentId = string.find(link, "talent:(%d+)");
				talentId = tonumber(talentId)
				self.talentIdToName[talentId] = nameTalent
				self.talentNameToId[nameTalent] = talentId
				self.pointsTalent[talentId] = currRank
				self.listeTalentsRemplie = true
				self.needCompile = true
			end
		end
	end
end

function Ovale:AddRune(time, type, value)
	if value<0 then
		for i=1,6 do
			if (self.state.rune[i].type == type or self.state.rune[i].type==4)and self.state.rune[i].cd<=time then
				self.state.rune[i].cd = time + 10
			end
		end
	else
	
	end
end

function Ovale:Log(text)
	if self.trace then
		self:Print(text)
	end
end

function Ovale:GetAura(target, filter, spellId, forceduration)
	if not self.aura[target] then
		self.aura[target] = {}
	end
	if not self.aura[target][filter] then
		self.aura[target][filter] = {}
	end
	if not self.aura[target][filter][spellId] then
		self.aura[target][filter][spellId] = {}
	end
	local myAura = self.aura[target][filter][spellId]
	if myAura.serial == Ovale.serial then
		return myAura
	end
	
	myAura.mine = false
	myAura.start = nil
	myAura.ending = nil
	myAura.stacks = 0
	myAura.serial = Ovale.serial
	
	local i = 1
	
	while (true) do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, thisSpellId =  UnitAura(target, i, filter);
		if not name then
			break
		end
		if (unitCaster=="player" or not myAura.mine) and (spellId == thisSpellId or spellId == debuffType) then
			myAura.mine = (unitCaster == "player")
			myAura.start = expirationTime - duration
			
			if expirationTime>0 then
				myAura.ending = expirationTime
			else
				myAura.ending = nil
			end
			if count and count>0 then
				myAura.stacks = count
			else
				myAura.stacks = 1
			end
			if myAura.mine then
				break
			end
		end
		i = i + 1;
	end
	return myAura
end

function Ovale:GetCD(spellId)
	if not spellId then
		return nil
	end
	
	if self.spellInfo[spellId] and self.spellInfo[spellId].cd then
		local cdname
		if self.spellInfo[spellId].sharedcd then
			cdname = self.spellInfo[spellId].sharedcd
		else
			cdname = spellId
		end
		if not self.state.cd[cdname] then
			self.state.cd[cdname] = {}
		end
		return self.state.cd[cdname]
	else
		return nil
	end
end

function Ovale:AddEclipse(endCast, spellId)
	local newAura = self:GetAura("player", "HELPFUL", spellId)
	newAura.start = endCast + 0.5
	newAura.stacks = 1
	newAura.ending = nil
end

-- Cast a spell in the simulator
-- spellId : the spell id
-- startCast : temps du cast
-- endCast : fin du cast
-- nextCast : temps auquel le prochain sort peut être lancé (>=endCast, avec le GCD)
-- nocd : le sort ne déclenche pas son cooldown
function Ovale:AddSpellToStack(spellId, startCast, endCast, nextCast, nocd)
	if not spellId then
		return
	end
	
	local newSpellInfo = self.spellInfo[spellId]
	
	self.state.eclipse = self.state.nextEclipse
	
	--On enregistre les infos sur le sort en cours
	self.attenteFinCast = nextCast
	self.currentSpellId = spellId
	self.startCast = startCast
	self.endCast = endCast
	--Temps actuel de la simulation : un peu après le dernier cast (ou maintenant si dans le passé)
	if startCast>=self.maintenant then
		self.currentTime = startCast+0.1
	else
		self.currentTime = self.maintenant
	end
	
	if Ovale.trace then
		Ovale:Print("add spell "..spellId.." at "..startCast.." currentTime = "..self.currentTime.. " nextCast="..self.attenteFinCast .. " endCast="..endCast)
	end
	
	--Effet du sort au moment du début du cast
	--(donc si cast déjà commencé, on n'en tient pas compte)
	if startCast >= self.maintenant then
		if newSpellInfo then
			if newSpellInfo.inccounter then
				local id = newSpellInfo.inccounter
				self.state.counter[id] = self:GetCounterValue(id) + 1
			end
			
			if newSpellInfo.resetcounter then
				self.state.counter[newSpellInfo.resetcounter] = 0
			end
		end
	end
	
	--Effet du sort au moment où il est lancé
	--(donc si il est déjà lancé, on n'en tient pas compte)
	if endCast >= self.maintenant then
		--Mana
		local _, _, _, cost = GetSpellInfo(spellId)
		if cost then
			self.state.mana = self.state.mana - cost
		end

		if newSpellInfo then
		
			if newSpellInfo.mana then
				self.state.mana = self.state.mana - newSpellInfo.mana
			end
			
			--Points de combo
			if newSpellInfo.combo then
				self.state.combo = self.state.combo + newSpellInfo.combo
				if self.state.combo<0 then
					self.state.combo = 0
				end
			end
			--Runes
			if newSpellInfo.frost then
				self:AddRune(startCast, 3, newSpellInfo.frost)
			end
			if newSpellInfo.death then
				self:AddRune(startCast, 4, newSpellInfo.death)
			end
			if newSpellInfo.blood then
				self:AddRune(startCast, 1, newSpellInfo.blood)
			end
			if newSpellInfo.unholy then
				self:AddRune(startCast, 2, newSpellInfo.unholy)
			end
			if newSpellInfo.holy then
				self.state.holy = self.state.holy + newSpellInfo.holy
				if self.state.holy < 0 then
					self.state.holy = 0
				elseif self.state.holy > 3 then
					self.state.holy = 3
				end
			end
			if newSpellInfo.shard then
				self.state.shard = self.state.shard + newSpellInfo.shard
				if self.state.shard < 0 then
					self.state.shard = 0
				elseif self.state.shard > 3 then
					self.state.shard = 3
				end
			end
		end
	end
	
	-- Effets du sort au moment où il atteint sa cible
	if newSpellInfo then
		-- Cooldown du sort
		local cd = self:GetCD(spellId)
		if cd then
			cd.start = startCast
			cd.duration = newSpellInfo.cd
			--Pas de cooldown
			if nocd then
				cd.duration = 0
			end
			--On vérifie si le buff "buffnocd" est présent, auquel cas le CD du sort n'est pas déclenché
			if newSpellInfo.buffnocd and not nocd then
				local buffAura = self:GetAura("player", "HELPFUL", newSpellInfo.buffnocd)
				if self.traceAura then
					if buffAura then
						self:Print("buffAura stacks = "..buffAura.stacks.." start="..nilstring(buffAura.start).." ending = "..nilstring(buffAura.ending))
						self:Print("startCast = "..startCast)
					else
						self:Print("buffAura = nil")
					end
					self.traceAura = false
				end
				if buffAura and buffAura.stacks>0 and buffAura.start and buffAura.start<=startCast and (not buffAura.ending or buffAura.ending>startCast) then
					cd.duration = 0
				end
			end
			if newSpellInfo.targetlifenocd and not nocd then
				if UnitHealth("target")/UnitHealthMax("target")*100<newSpellInfo.targetlifenocd then
					cd.duration = 0
				end
			end
			cd.enable = 1
			if newSpellInfo.toggle then
				cd.toggled = 1
			end
		end

		if newSpellInfo.eclipse then
			self.state.eclipse = self.state.eclipse + newSpellInfo.eclipse
			if self.state.eclipse < -100 then
				self.state.eclipse = -100
				self:AddEclipse(endCast, 48518)
			elseif self.state.eclipse > 100 then
				self.state.eclipse = 100
				self:AddEclipse(endCast, 48517)
			end
		end
		if newSpellInfo.starsurge then
			local buffAura = self:GetAura("player", "HELPFUL", 48517) --Solar
			if buffAura.stacks>0 then
				self:Log("starsurge with solar buff = " .. (- newSpellInfo.starsurge))
				self.state.eclipse = self.state.eclipse - newSpellInfo.starsurge
			else
				buffAura = self:GetAura("player", "HELPFUL", 48518) --Lunar
				if buffAura.stacks>0 then
					self:Log("starsurge with lunar buff = " .. newSpellInfo.starsurge)
					self.state.eclipse = self.state.eclipse + newSpellInfo.starsurge
				elseif self.state.eclipse < 0 then
					self:Log("starsurge with eclipse < 0 = " .. (- newSpellInfo.starsurge))
					self.state.eclipse = self.state.eclipse - newSpellInfo.starsurge
				else
					self:Log("starsurge with eclipse > 0 = " .. newSpellInfo.starsurge)
					self.state.eclipse = self.state.eclipse + newSpellInfo.starsurge
				end
			end
			if self.state.eclipse < -100 then
				self.state.eclipse = -100
				self:AddEclipse(endCast, 48518)
			elseif self.state.eclipse > 100 then
				self.state.eclipse = 100
				self:AddEclipse(endCast, 48517)
			end
		end
			
		--Auras causés par le sort
		if newSpellInfo.aura then
			for target, targetInfo in pairs(newSpellInfo.aura) do
				for filter, filterInfo in pairs(targetInfo) do
					for auraSpellId, spellData in pairs(filterInfo) do
						local newAura = self:GetAura(target, filter, auraSpellId)
						newAura.mine = true
						local duration = spellData
						local stacks = duration
						--Optionnellement, on va regarder la durée du buff
						if auraSpellId and self.spellInfo[auraSpellId] and self.spellInfo[auraSpellId].duration then
							duration = self.spellInfo[auraSpellId].duration
						elseif stacks~="refresh" and stacks > 0 then
							stacks = 1
						end
						if stacks=="refresh" then
							if newAura.ending then
								newAura.ending = endCast + duration
							end
						elseif stacks<0 and newAura.ending then
							--Buff are immediatly removed when the cast ended, do not need to do it again
							if filter~="HELPFUL" or target~="player" or endCast>=Ovale.maintenant then
								newAura.stacks = newAura.stacks + stacks
								if Ovale.trace then
									self:Print("removing one stack of "..auraSpellId.." because of ".. spellId.." to ".. newAura.stacks)
								end
								--Plus de stacks, on supprime l'aura
								if newAura.stacks<=0 then
									self:Log("Aura is completly removed")
									newAura.stacks = 0
									newAura.ending = 0
								end
							end
						elseif newAura.ending and newAura.ending >= endCast then
							newAura.ending = endCast + duration
							newAura.stacks = newAura.stacks + stacks
						else
							newAura.start = endCast
							newAura.ending = endCast + duration
							newAura.stacks = stacks
						end
						if Ovale.trace then
							if auraSpellId then
								self:Print(spellId.." adding "..stacks.." aura "..auraSpellId.." to "..target.." "..filter.." "..newAura.start..","..newAura.ending)
							else
								self:Print("adding nil aura")
							end
						end
					end
				end
			end
		end
	end
end

function Ovale:InitAllActions()
	self.maintenant = GetTime();
	self.gcd = self:GetGCD()
end

function Ovale:InitCalculerMeilleureAction()
	self.serial = self.serial + 1
	self.currentTime = Ovale.maintenant
	self.currentSpellId = nil
	self.attenteFinCast = Ovale.maintenant
	self.state.combo = GetComboPoints("player")
	self.state.mana = UnitPower("player")
	self.state.shard = UnitPower("player", 7)
	self.state.eclipse = UnitPower("player", 8)
	self.state.nextEclipse = self.state.eclipse
	self.state.nextEclipseTime = self.currentTime
	self.state.holy = UnitPower("player", 9)
	if self.className == "DEATHKNIGHT" then
		for i=1,6 do
			self.state.rune[i].type = GetRuneType(i)
			local start, duration, runeReady = GetRuneCooldown(i)
			if runeReady then
				self.state.rune[i].cd = start
			else
				self.state.rune[i].cd = duration + start
				if self.state.rune[i].cd<0 then
					self.state.rune[i].cd = 0
				end
			end
		end
	end
	for k,v in pairs(self.state.cd) do
		v.start = nil
		v.duration = nil
		v.enable = 0
		v.toggled = nil
	end
	
	for k,v in pairs(self.state.counter) do
		self.state.counter[k] = self.counter[k]
	end
	
	for i,v in ipairs(self.lastSpell) do
		if not self.spellInfo[v.spellId] or not self.spellInfo[v.spellId].toggle then
			--[[local spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo("player")
			if spell and spell == v.name and startTime/1000 - v.start < 0.5 and v.stop~=endTime/1000 then
				print("ancien = "..v.stop)
				v.stop = endTime/1000
				print("changement de v.stop en "..v.stop.." "..v.start)
			end]]
			self:Log("self.maintenant = " ..self.maintenant.." spellId="..v.spellId.." v.stop="..v.stop)
			if self.maintenant - v.stop<5 then
				self:AddSpellToStack(v.spellId, v.start, v.stop, v.stop, v.nocd)
			else
				--self:Print("Removing obsolete "..v.spellId)
				table.remove(self.lastSpell, i)
			end
		end
	end
end

local function printTime(temps)
	if (temps == nil) then
		Ovale:Print("> nil")
	else
		Ovale:Print("> "..temps)
	end
end

function Ovale:GetGCD(spellId)
	if spellId and self.spellInfo[spellId] then
		if self.spellInfo[spellId].haste == "spell" then
			local cd = self.spellInfo[spellId].gcd
			if not cd then
				cd = 1.5
			end
			cd = cd /(1+self.spellHaste/100)
			if (cd<1) then
				cd = 1
			end
			return cd
		elseif self.spellInfo[spellId].gcd then
			return self.spellInfo[spellId].gcd
		end			
	end
	
	-- Default value
	if self.className == "ROGUE" or (self.className == "DRUID" and GetShapeshiftForm(true) == 3) then
		return 1.0
	elseif self.className == "MAGE" or self.className == "WARLOCK" or self.className == "PRIEST" or
			(self.className == "DRUID" and GetShapeshiftForm(true) ~= 1) then
		local cd = 1.5 /(1+self.spellHaste/100)
		if (cd<1) then
			cd = 1
		end
		return cd
	else
		return 1.5
	end
end

--Compute the spell Cooldown
function Ovale:GetComputedSpellCD(spellId)
	local actionCooldownStart, actionCooldownDuration, actionEnable
	local cd = self:GetCD(spellId)
	if cd and cd.start then
		actionCooldownStart = cd.start
		actionCooldownDuration = cd.duration
		actionEnable = cd.enable
	else
		actionCooldownStart, actionCooldownDuration, actionEnable = GetSpellCooldown(spellId)
		-- Les chevaliers de la mort ont des infos fausses sur le CD quand ils n'ont plus les runes
		-- On force à 1,5s ou 1s en présence impie
		if self.className=="DEATHKNIGHT" and actionCooldownDuration==10 and
				(not self.spellInfo[spellId] or self.spellInfo[spellId].cd~=10) then
			local impie = GetSpellInfo(48265)
			if impie and UnitBuff("player", impie) then
				actionCooldownDuration=1
			else
				actionCooldownDuration=1.5
			end
		end
		if self.spellInfo[spellId] and self.spellInfo[spellId].forcecd then
			actionCooldownStart, actionCooldownDuration = GetSpellCooldown(self.spellInfo[spellId].forcecd)
		end
	end
	return actionCooldownStart, actionCooldownDuration, actionEnable
end

function Ovale:GetActionInfo(element)
	if not element then
		return nil
	end
	
	local spellId = element.params[1]
	local action
	local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable
	
	local target = element.params.target
	if (not target) then
		target = "target"
	end

	if (element.func == "Spell" ) then
		if not self.spellList[spellId] and not self.actionSort[spellId] then 
			self:Log("Spell "..spellId.." not learnt")
			return nil
		end
		
		--Get spell info
		action = self.actionSort[spellId]
		actionCooldownStart, actionCooldownDuration, actionEnable = self:GetComputedSpellCD(spellId)
		
		--if (not action or not GetActionTexture(action)) then
			spellName = self.spellList[spellId]
			if not spellName then
				spellName = GetSpellInfo(spellId)
			end
			actionTexture = GetSpellTexture(spellId)
			actionInRange = IsSpellInRange(spellName, target)
			actionUsable = IsUsableSpell(spellId)
			actionShortcut = nil
		--end
	elseif (element.func=="Macro") then
		action = self.actionMacro[element.params[1]]
		if action then
			actionTexture = GetActionTexture(action)
			actionInRange = IsActionInRange(action, target)
			actionCooldownStart, actionCooldownDuration, actionEnable = GetActionCooldown(action)
			actionUsable = IsUsableAction(action)
			actionShortcut = self.shortCut[action]
			actionIsCurrent = IsCurrentAction(action)
		else
			Ovale:Log("Unknown macro "..element.params[1])
		end
	elseif (element.func=="Item") then
		local itemId
		if (type(element.params[1]) == "number") then
			itemId = element.params[1]
		else
			local _,_,id = string.find(GetInventoryItemLink("player",GetInventorySlotInfo(element.params[1])) or "","item:(%d+):%d+:%d+:%d+")
			if not id then
				return nil
			end
			itemId = tonumber(id)
		end
		
		if (Ovale.trace) then
			self:Print("Item "..nilstring(itemId))
		end

		local spellName = GetItemSpell(itemId)
		actionUsable = (spellName~=nil)
		
		action = self.actionObjet[itemId]
		--if (not action or not GetActionTexture(action)) then
			actionTexture = GetItemIcon(itemId)
			actionInRange = IsItemInRange(itemId, target)
			actionCooldownStart, actionCooldownDuration, actionEnable = GetItemCooldown(itemId)
			actionShortcut = nil
			actionIsCurrent = nil
		--end
	elseif element.func=="Texture" then
		actionTexture = "Interface\\Icons\\"..element.params[1]
		actionCooldownStart = Ovale.maintenant
		actionCooldownDuration = 0
		actionEnable = 1
		actionUsable = true
	end
	
	if action then 
		if actionUsable == nil then
			actionUsable = IsUsableAction(action)
		end
		actionShortcut = self.shortCut[action]
		actionIsCurrent = IsCurrentAction(action)
	end
	
	local cd = self:GetCD(spellId)
	if cd and cd.toggle then
		actionIsCurrent = 1
	end
	
	return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
					actionUsable, actionShortcut, actionIsCurrent, actionEnable, spellId, target, element.params.nored
end

local function subTime(time1, duration)
	if not time1 then
		return nil
	else
		return time1 - duration
	end
end

local function addTime(time1, duration)
	if not time1 then
		return nil
	else
		return time1 + duration
	end
end

local function isBeforeEqual(time1, time2)
	return time1 and (not time2 or time1<=time2)
end

local function isBefore(time1, time2)
	return time1 and (not time2 or time1<time2)
end

local function isAfterEqual(time1, time2)
	return not time1 or (time2 and time1>=time2)
end

local function isAfter(time1, time2)
	return not time1 or (time2 and time1>time2)
end

function Ovale:CalculerMeilleureAction(element)
	if (self.bug and not self.trace) then
		return nil
	end
	
	if (not element) then
		return nil
	end
	
	--TODO: créer un objet par type au lieu de ce if else if tout moche
	if (element.type=="function")then
		if (element.func == "Spell" or element.func=="Macro" or element.func=="Item" or element.func=="Texture") then
			local action
			local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
				actionUsable, actionShortcut, actionIsCurrent, actionEnable, spellId = self:GetActionInfo(element)
			
			if not actionTexture then
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." not found")
				end
				return nil
			end
			if element.params.usable==1 and not actionUsable then
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." not usable")
				end
				return nil
			end
			if spellId and self.spellInfo[spellId] and self.spellInfo[spellId].casttime then
				element.castTime = self.spellInfo[spellId].casttime
			elseif spellId then
				local spell, rank, icon, cost, isFunnel, powerType, castTime = GetSpellInfo(spellId)
				if castTime then
					element.castTime = castTime/1000
				else
					element.castTime = nil
				end
			else
				element.castTime = 0
			end
			--TODO: not useful anymore?
			if (spellId and self.spellInfo[spellId] and self.spellInfo[spellId].toggle and actionIsCurrent) then
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." is current action")
				end
				return nil
			end
			if actionEnable and actionEnable>0 then
				local restant
				if (not actionCooldownDuration or actionCooldownStart==0) then
					restant = self.currentTime
				else
					restant = actionCooldownDuration + actionCooldownStart
				end
				self:Log("restant = "..restant.." attenteFinCast="..nilstring(self.attenteFinCast))
				if restant<self.attenteFinCast then
					if -- spellName==self.currentSpellName or 
						not self.spellInfo[self.currentSpellId] or
							not self.spellInfo[self.currentSpellId].canStopChannelling then
						restant = self.attenteFinCast
					else
						--TODO: pas exact, parce que si ce sort est reporté de par exemple 0,5s par un debuff
						--ça tombera entre deux ticks
						local ticks = self.spellInfo[self.currentSpellId].canStopChannelling
						local tickLength = (self.attenteFinCast - self.startCast) / ticks
						local tickTime = self.startCast + tickLength
						if (Ovale.trace) then
							self:Print(spellName.." restant = " .. restant)
							self:Print("ticks = "..ticks.." tickLength="..tickLength.." tickTime="..tickTime)
						end	
						for i=1,ticks-1 do
							if restant<=tickTime then
								restant = tickTime
								break
							end
							tickTime = tickTime + tickLength
						end
						if (Ovale.trace) then
							self:Print(spellId.." restant = " .. restant)
						end	
					end
				end
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." remains "..restant)
				end
				local retourPriorite = element.params.priority
				if (not retourPriorite) then
					retourPriorite = 3
				end
				return restant, nil, retourPriorite, element
			else
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." not enabled")
				end
			end
		else
			local classe = Ovale.conditions[element.func]
			if (not classe) then
				self.bug = true
				self:Print("Function "..element.func.." not found")
				return nil
			end
			local start, ending, rate = classe(element.params)
			
			if (Ovale.trace) then
				local parameterList = element.func.."("
				for k,v in pairs(element.params) do
					parameterList = parameterList..k.."="..v..","
				end
				self:Print("Function "..parameterList..") returned "..nilstring(start)..","..nilstring(ending))
			end
			
			return start, ending, rate
		end
	elseif element.type == "time" then
		return element.value, 0, 0
	elseif element.type == "after" then
		local timeA = Ovale:CalculerMeilleureAction(element.time)
		local startA, endA = Ovale:CalculerMeilleureAction(element.a)
		return addTime(startA, timeA), addTime(endA, timeA)
	elseif (element.type == "before") then
		if (Ovale.trace) then
			--self:Print(nilstring(element.time).."s before ["..element.nodeId.."]")
		end
		local timeA = Ovale:CalculerMeilleureAction(element.time)
		local startA, endA = Ovale:CalculerMeilleureAction(element.a)
		return addTime(startA, -timeA), addTime(endA, -timeA)
	elseif (element.type == "between") then
		self:Log("between")
		local tempsA = Ovale:CalculerMeilleureAction(element.a)
		local tempsB = Ovale:CalculerMeilleureAction(element.b)
		if tempsB==nil and tempsA==nil then
			Ovale:Log("diff returns 0 because the two nodes are nil")
			return 0
		end
		
		if tempsA==nil or tempsB==nil then
			if Ovale.trace then Ovale:Print(element.type.." return nil") end
			return nil
		end
		local diff
		if tempsA>tempsB then
			diff = tempsA - tempsB
		else
			diff = tempsB - tempsA
		end
		Ovale:Log("diff returns "..diff)
		return diff
	elseif element.type == "fromuntil" then
		self:Log("fromuntil")
		local tempsA = Ovale:CalculerMeilleureAction(element.a)
		if (tempsA==nil) then
			if Ovale.trace then Ovale:Print(element.type.." return nil") end
			return nil
		end
		local tempsB = Ovale:CalculerMeilleureAction(element.b)
		if (tempsB==nil) then
			if Ovale.trace then Ovale:Print(element.type.." return nil") end
			return nil
		end
		Ovale:Log("fromuntil returns "..(tempsB - tempsA))
		return tempsB - tempsA
	elseif element.type == "compare" then
		self:Log("compare "..element.comparison)
		local tempsA = Ovale:CalculerMeilleureAction(element.a)
		local timeB = Ovale:CalculerMeilleureAction(element.time)
		self:Log(nilstring(tempsA).." "..element.comparison.." "..nilstring(timeB))
		if element.comparison == "more" and (not tempsA or tempsA>timeB) then
			if Ovale.trace then Ovale:Print(element.type.." return 0") end
			return 0
		elseif element.comparison == "less" and tempsA and tempsA<timeB then
			if Ovale.trace then Ovale:Print(element.type.." return 0") end
			return 0
		elseif element.comparison == "at most" and tempsA and tempsA<=timeB then
			if Ovale.trace then Ovale:Print(element.type.." return 0") end
			return 0
		elseif element.comparison == "at least" and (not tempsA or tempsA>=timeB) then
			if Ovale.trace then Ovale:Print(element.type.." return 0") end
			return 0
		end
		return nil
	elseif (element.type == "and" or element.type == "if") then
		if (Ovale.trace) then
			self:Print(element.type.." ["..element.nodeId.."]")
		end
		local startA, endA = Ovale:CalculerMeilleureAction(element.a)
		if (startA==nil) then
			if Ovale.trace then Ovale:Print(element.type.." return nil  ["..element.nodeId.."]") end
			return nil
		end
		if startA == endA then
			if Ovale.trace then Ovale:Print(element.type.." return startA=endA  ["..element.nodeId.."]") end
			return nil
		end
		local startB, endB, prioriteB, elementB = Ovale:CalculerMeilleureAction(element.b)
		if isAfter(startB, endA) or isAfter(startA, endB) then
			if Ovale.trace then Ovale:Print(element.type.." return nil ["..element.nodeId.."]") end
			return nil
		end
		if isBefore(startB, startA) then
			startB = startA
		end
		if isAfter(endB, endA) then
			endB = endA
		end
		if Ovale.trace then
			Ovale:Print(element.type.." return "..nilstring(startB)..","..nilstring(endB).." ["..element.nodeId.."]")
		end
		return startB, endB, prioriteB, elementB
	elseif (element.type == "unless") then
		if (Ovale.trace) then
			self:Print(element.type)
		end
		local startA, endA = Ovale:CalculerMeilleureAction(element.a)
		local startB, endB, prioriteB, elementB = Ovale:CalculerMeilleureAction(element.b)
		
		if isBeforeEqual(startA, startB) and isAfterEqual(endA, endB) then
			if Ovale.trace then Ovale:Print(element.type.." return nil") end
			return nil
		end
		
		if isAfterEqual(startA, startB) and isBefore(endA, endB) then
			if Ovale.trace then Ovale:Print(element.type.." return "..nilstring(endA)..","..nilstring(endB)) end
			return endA, endB, prioriteB, elementB
		end
		
		if isAfter(startA, startB) and isBefore(startA, endB) then
			endB = startA
		end
		
		if isAfter(endA, startB) and isBefore(endA, endB) then
			startB = endA
		end
					
		if Ovale.trace then Ovale:Print(element.type.." return "..nilstring(startB)..","..nilstring(endB)) end
		return startB, endB, prioriteB, elementB
	elseif (element.type == "or") then
		if (Ovale.trace) then
			self:Print(element.type)
		end
		
		local startA, endA = Ovale:CalculerMeilleureAction(element.a)
		local startB, endB = Ovale:CalculerMeilleureAction(element.b)
		if isBefore(endA,self.currentTime) then
			return startB,endB
		elseif isBefore(endB,self.currentTime) then
			return startA,endA
		end		
		
		if isBefore(endA,startB) then
			return startA,endA
		elseif isBefore(endB,startA) then
			return startB,endB
		end
				
		if isBefore(startA, startB) then
			startB = startA
		end
		if isAfter(endA, endB) then
			endB = endA
		end
		return startB, endB
	elseif element.type == "operator" then
		local a,b,c = self:CalculerMeilleureAction(element.a)
		local x,y,z = self:CalculerMeilleureAction(element.b)

		if not a or not x then
			self:Log("operator: a or x is nil")
			return nil
		end
		
		self:Log(a.."+(t-"..b..")*"..c.. element.operator..x.."+(t-"..y..")*"..z)
		
		if element.operator == "*" then
			if c == 0 then
				return a*x, y, a*z
			elseif z == 0 then
				return x*a, b, x*c
			else
				self:Print("ERROR: at least one value must be constant when multiplying")
				self.bug = true
			end
		elseif element.operator == "+" then
			if c+z == 0 then
				return a+x, 0, 0
			else
				return a+x, (b*c+y*z)/(c+z), c+z
			end
		elseif element.operator == '-' then
			if c-z == 0 then
				return a-x, 0, 0
			else
				return a-x, (b*c-y*z)/(c-z), c-z
			end
		elseif element.operator == '/' then
			if z == 0 then
				return a/x, b, c/x
			else
				self:Print("ERROR: second operator of / must be constant")
				self.bug = true
			end
		elseif element.operator == '<' then
			-- a + (t-b)*c = x + (t-y)*z
			-- (t-b)*c - (t-y)*z = x - a
			-- t*c - b*c - t*z + y*z = x - a
			-- t*(c-z) = x - a + b*c + y*z
			-- t = (x-a + b*c + y*z)/(c-z)
			if c == z then
				if a-b*c < x-y*z then
					return 0
				else
					return nil
				end
			else
				local t = (x-a + b*c + y*z)/(c-z)
				if c > z then
					return 0, t
				else
					return t, nil
				end
			end
		elseif element.operator == '>' then
			if c == z then
				self:Log("> with c==z")
				if a-b*c > x-y*z then
					self:Log("a>x")
					return 0
				else
					return nil
				end
			else
				local t = (x-a + b*c + y*z)/(c-z)
				if c < z then
					return 0, t
				else
					return t, nil
				end
			end
		end
	elseif element.type == "lua" then
		local ret = loadstring(element.lua)()
		self:Log("lua "..nilstring(ret))
		return ret, 0, 0
	elseif (element.type == "group") then
		local meilleurTempsFils
		local bestEnd
		local meilleurePrioriteFils
		local bestElement
		local bestCastTime
		 
		if (Ovale.trace) then
			self:Print(element.type.." ["..element.nodeId.."]")
		end
		
		if #element.nodes == 1 then
			return Ovale:CalculerMeilleureAction(element.nodes[1])
		end
		
		for k, v in ipairs(element.nodes) do
			local newStart, newEnd, priorite, nouveauElement = Ovale:CalculerMeilleureAction(v)
			if newStart~=nil and newStart<Ovale.currentTime then
				newStart = Ovale.currentTime
			end

			
			if newStart and (not newEnd or newStart<=newEnd) then
				local remplacer

				local newCastTime
				if nouveauElement then
					newCastTime = nouveauElement.castTime
				end
				if not newCastTime or newCastTime < self.gcd then
					newCastTime = self.gcd
				end
			
				if (not meilleurTempsFils) then
					remplacer = true
				else
					-- temps maximum entre le nouveau sort et le précédent
					local maxEcart
					if (priorite and not meilleurePrioriteFils) then
						self.bug = true
						self:Print("Internal error: meilleurePrioriteFils=nil and priorite="..priorite)
						return nil
					end
					if (priorite and priorite > meilleurePrioriteFils) then
						-- Si le nouveau sort est plus prioritaire que le précédent, on le lance
						-- si caster le sort actuel repousse le nouveau sort
						maxEcart = bestCastTime*0.75
					elseif (priorite and priorite < meilleurePrioriteFils) then
						-- A l'inverse, si il est moins prioritaire que le précédent, on ne le lance
						-- que si caster le nouveau sort ne repousse pas le meilleur
						maxEcart = -newCastTime*0.75
					else
						maxEcart = -0.01
					end
					if (newStart-meilleurTempsFils < maxEcart) then
						remplacer = true
					end
				end
				if (remplacer) then
					meilleurTempsFils = newStart
					meilleurePrioriteFils = priorite
					bestElement = nouveauElement
					bestEnd = newEnd
					bestCastTime = newCastTime
				end
			end
		end
		
		if (meilleurTempsFils) then
			if (Ovale.trace) then
				if bestElement then
					self:Print("group best action "..bestElement.params[1].." remains "..meilleurTempsFils..","..nilstring(bestEnd).." ["..element.nodeId.."]")
				else
					self:Print("group no best action returns "..meilleurTempsFils..","..nilstring(bestEnd).." ["..element.nodeId.."]")
				end
			end
			return meilleurTempsFils, bestEnd, meilleurePrioriteFils, bestElement
		else
			if (Ovale.trace) then self:Print("group return nil") end
			return nil
		end
	end
	if (Ovale.trace) then self:Print("unknown element "..element.type..", return nil") end
	return nil
end

function Ovale:ChargerDefaut()
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
			apparence = {enCombat=false, iconScale = 2, margin = 4, fontScale = 0.5, iconShiftX = 0, iconShiftY = 0,
				smallIconScale=1, raccourcis=true, numeric=false, avecCible = false,
				verrouille = false, vertical = false, predictif=false, highlightIcon = true, clickThru = false, 
				latencyCorrection=true, hideVehicule=true, flashIcon=true, targetText = "●", alpha = 1,
				optionsAlpha = 1, updateInterval=0.1},
			skin = {SkinID="Blizzard", Backdrop = true, Gloss = false, Colors = {}}
		}
	})
end

function Ovale:AfficherConfig()
	self.AceConfigDialog:SetDefaultSize("Ovale Apparence", 500, 550)
	self.AceConfigDialog:Open("Ovale Apparence", configFrame)
end

function Ovale:AfficherCode()
	self.AceConfigDialog:SetDefaultSize("Ovale", 500, 550)
	self.AceConfigDialog:Open("Ovale", configFrame)
end

local function OnCheckBoxValueChanged(widget)
	Ovale.db.profile.check[widget.userdata.k] = widget:GetValue()
end

local function OnDropDownValueChanged(widget)
	Ovale.db.profile.list[widget.userdata.k] = widget.value
end

function Ovale:ToggleOptions()
	self.frame:ToggleOptions()
end

function Ovale:UpdateVisibility()
	if not Ovale.db.profile.display then
		self.frame:Hide()
		return
	end

	self.frame:Show()

	if Ovale.db.profile.apparence.hideVehicule and UnitInVehicle("player") then
		self.frame:Hide()
	end
	
	if Ovale.db.profile.apparence.avecCible and not UnitExists("target") then
		self.frame:Hide()
	end
	
	if Ovale.db.profile.apparence.enCombat and not Ovale.enCombat then
		self.frame:Hide()
	end	
	
	if Ovale.db.profile.apparence.targetHostileOnly and (UnitIsDead("target") or not UnitCanAttack("player", "target")) then
		self.frame:Hide()
	end
end

function Ovale:UpdateFrame()
	self.frame:ReleaseChildren()

	self.frame:UpdateIcons()
	
	self:UpdateVisibility()
	
	self.checkBoxes = {}
	
	for k,checkBox in pairs(self.casesACocher) do
		self.checkBoxes[k] = LibStub("AceGUI-3.0"):Create("CheckBox");
		self.frame:AddChild(self.checkBoxes[k])
		self.checkBoxes[k]:SetLabel(checkBox.text)
		if self.db.profile.check[k]==nil then
			self.db.profile.check[k] = checkBox.checked
		end
		if (self.db.profile.check[k]) then
			self.checkBoxes[k]:SetValue(self.db.profile.check[k]);
		end
		self.checkBoxes[k].userdata.k = k
		self.checkBoxes[k]:SetCallback("OnValueChanged",OnCheckBoxValueChanged)
	end
	
	self.dropDowns = {}
	
	if (self.listes) then
		for k,list in pairs(self.listes) do
			self.dropDowns[k] = LibStub("AceGUI-3.0"):Create("Dropdown");
			self.dropDowns[k]:SetList(list.items)
			if not self.db.profile.list[k] then
				self.db.profile.list[k] = list.default
			end
			if (self.db.profile.list[k]) then
				self.dropDowns[k]:SetValue(self.db.profile.list[k]);
			end
			self.dropDowns[k].userdata.k = k
			self.dropDowns[k]:SetCallback("OnValueChanged",OnDropDownValueChanged)
			self.frame:AddChild(self.dropDowns[k])
		end
	end
end

function Ovale:IsChecked(v)
	return self.checkBoxes[v] and self.checkBoxes[v]:GetValue()
end

function Ovale:GetListValue(v)
	return self.dropDowns[v] and self.dropDowns[v].value
end

function Ovale:GetSpellInfo(spellId)
	if (not self.spellInfo[spellId]) then
		self.spellInfo[spellId] = { aura = {player = {}, target = {}} }
	end
	return self.spellInfo[spellId]
end

function Ovale:ResetSpellInfo()
	self.spellInfo = {}
end

function Ovale:EnableOtherDebuffs()
	if self.otherDebuffsEnabled then
		return
	end
	self.otherDebuffsEnabled = true
end

function Ovale:SetCheckBox(v,on)
	for k,checkBox in pairs(self.casesACocher) do
		if v==0 then
			self.checkBoxes[k]:SetValue(on)
			self.db.profile.check[k] = on
			break
		end
		v = v - 1
	end
end

function Ovale:ToggleCheckBox(v)
	for k,checkBox in pairs(self.casesACocher) do
		if v==0 then
			self.checkBoxes[k]:SetValue(not self.checkBoxes[k]:GetValue())
			self.db.profile.check[k] = self.checkBoxes[k]:GetValue()
			break
		end
		v = v - 1
	end
end