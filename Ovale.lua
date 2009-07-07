local L = LibStub("AceLocale-3.0"):GetLocale("Ovale")

Ovale = LibStub("AceAddon-3.0"):NewAddon("Ovale", "AceEvent-3.0", "AceConsole-3.0")

Ovale.defaut = {}
Ovale.action = {}
Ovale.casesACocher = {}
Ovale.actionSort = {}
Ovale.listeTalents = {}
Ovale.pointsTalent = {}
Ovale.talentIdToName = {}
Ovale.talentNameToId = {}
Ovale.firstInit = false
Ovale.Inferieur = 1
Ovale.Superieur = 2
Ovale.listeTalentsRemplie = false
Ovale.frame = nil
Ovale.checkBoxes = {}
Ovale.dropDowns = {}
Ovale.masterNodes = nil
Ovale.bug = false
Ovale.enCombat = false
Ovale.spellHaste = 0
Ovale.meleeHaste = 0
Ovale.aura = { player = {}, target = {}}
Ovale.possibleAura = { player = {}, target = {}}
Ovale.targetGUID = nil
Ovale.spellInfo = {}
Ovale.currentSpellInfo = nil
Ovale.buff = {}

Ovale.arbre = {}

-- Ovale.trace=true
local nouvelleCondition
local nouveauSort

local options = 
{ 
	type = "group",
	args = 
	{
		apparence =
		{
			name = "Apparence",
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
					width = full
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
					width = full
				},
				iconWidth = 
				{
					order = 2,
					type = "range",
					name = L["Largeur des icônes"],
					desc = L["La largeur des icônes"],
					min = 16, max = 256, step = 2,
					get = function(info) return Ovale.db.profile.apparence.iconWidth end,
					set = function(info,value) Ovale.db.profile.apparence.iconWidth = value; Ovale:UpdateFrame() end
				},
				iconHeight = 
				{
					order = 3,
					type = "range",
					name = L["Hauteur des icônes"],
					desc = L["La hauteur des icônes"],
					min = 16, max = 256, step = 2,
					get = function(info) return Ovale.db.profile.apparence.iconHeight end,
					set = function(info,value) Ovale.db.profile.apparence.iconHeight = value; Ovale:UpdateFrame() end
				},
				smallIconWidth = 
				{
					order = 4,
					type = "range",
					name = L["Largeur des petites icônes"],
					desc = L["La largeur des petites icônes"],
					min = 16, max = 256, step = 2,
					get = function(info) return Ovale.db.profile.apparence.smallIconWidth end,
					set = function(info,value) Ovale.db.profile.apparence.smallIconWidth = value; Ovale:UpdateFrame() end
				},
				smallIconHeight = 
				{
					order = 5,
					type = "range",
					name = L["Hauteur des petites icônes"],
					desc = L["La hauteur des petites icônes"],
					min = 16, max = 256, step = 2,
					get = function(info) return Ovale.db.profile.apparence.smallIconHeight end,
					set = function(info,value) Ovale.db.profile.apparence.smallIconHeight = value; Ovale:UpdateFrame() end
				},
				margin = 
				{
					order = 5.5,
					type = "range",
					name = L["Marge entre deux icônes"],
					min = 0, max = 64, step = 1,
					get = function(info) return Ovale.db.profile.apparence.margin end,
					set = function(info,value) Ovale.db.profile.apparence.margin = value; Ovale:UpdateFrame() end
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
						return Ovale.db.profile.code
					end,
					set = function(info,v)
						Ovale.db.profile.code = v
						Ovale.masterNodes = Ovale:Compile(Ovale.db.profile.code)
						Ovale:UpdateFrame()
						-- Ovale:Print("code change")
					end,
					width = "full"
				},
				show =
				{
					order = -1,
					type = "execute",
					name = L["Afficher la fenêtre"],
					guiHidden = true,
					func = function()
						Ovale.db.profile.display = true
						Ovale.frame:Show()	
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
			}
		}
	}
}

function Ovale:Debug()
	self:Print(self:DebugNode(self.masterNodes[1]))
end

function Ovale:OnInitialize()
	self.AceConfig = LibStub("AceConfig-3.0");
	self.AceConfigDialog = LibStub("AceConfigDialog-3.0");
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
end

function Ovale:PLAYER_TALENT_UPDATE()
	self:RemplirListeTalents()
end

function Ovale:SPELLS_CHANGED()
	-- self:RemplirActionIndexes()
	-- self:RemplirListeTalents()
end

function Ovale:UPDATE_BINDINGS()
	self:RemplirActionIndexes()
end

--[[
function Ovale:SaveAura(unit, filter)
	local i=1
	
	for k, v in pairs(Ovale.aura[unit]) do
		v.dispelled = true
		v.unitCaster = nil
	end
	
	while (true) do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster = UnitAura(unit, i, filter)
		
		if (not name) then
			break
		end
		
		if (not Ovale.aura[unit][filter][name].isMine or not isMine) then
			Ovale.aura[unit][filter][name].icon = icon
			Ovale.aura[unit][filter][name].count = count
			Ovale.aura[unit][filter][name].duration = duration
			Ovale.aura[unit][filter][name].expirationTime = expirationTime
			Ovale.aura[unit][filter][name].unitCaster  = unitCaster 
		end
	end
end

function Ovale:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local time, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = select(1, ...)
	if (
	if (event 
end

function Ovale:PLAYER_TARGET_CHANGED()
	Ovale.targetGUID = UnitGUID("target")
	Ovale.aura.target.HELPFUL = {}
	Ovale.aura.target.HARMFUL = {}
end
]]

function Ovale:PLAYER_TARGET_CHANGED()
	if (Ovale.db.profile.apparence.avecCible) then
		if not UnitExists("target") then
			self.frame:Hide()
		else
			self.frame:Show()
		end
	end
end


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
			local name, rank, iconTexture, count, debuffType, duration, expirationTime, source =  UnitBuff("player", i);
			if (not name) then
				break
			end
			if (not self.buff[name]) then
				self.buff[name] = {}
			end
			self.buff[name].icon = iconTexture
			self.buff[name].count = count
			self.buff[name].duration = duration
			self.buff[name].expirationTime = expirationTime
			self.buff[name].source = source
			if (not self.buff[name].present) then
				self.buff[name].gain = Ovale.maintenant
			end
			self.buff[name].lastSeen = Ovale.maintenant
			self.buff[name].present = true
			
			if (name == self.RETRIBUTION_AURA or name == self.MOONKIN_AURA) then
				hateCommune = 3
			elseif (name == self.WRATH_OF_AIR_TOTEM) then
				hateSorts = 5
			elseif (name == self.WINDFURY_TOTEM and hateCaC == 0) then
				hateCaC = 16
			elseif (name == self.ICY_TALONS) then
				hateCaC = 20
			elseif (name == self.BLOODLUST or name == self.HEROISM) then
				hateHero = 30
			elseif (name == self.JUDGMENT_OF_THE_PURE) then
				hateClasse = 15
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
--		print("spellHaste = "..self.spellHaste)
	end
end

function Ovale:HandleProfileChanges()
	if (self.firstInit) then
		if (self.db.profile.code) then
			self.masterNodes = self:Compile(self.db.profile.code)
			self:UpdateFrame()
		end
	end
end

function Ovale:ChercherNomsBuffs()
	self.MOONKIN_AURA = self:GetSpellInfoOrNil(24907)
	self.RETRIBUTION_AURA = self:GetSpellInfoOrNil(7294)
	self.WRATH_OF_AIR_TOTEM = self:GetSpellInfoOrNil(3738)
	self.WINDFURY_TOTEM = self:GetSpellInfoOrNil(8512)
	self.ICY_TALONS = self:GetSpellInfoOrNil(50880)
	self.BLOODLUST = self:GetSpellInfoOrNil(2825)
	self.HEROISM = self:GetSpellInfoOrNil(32182)
	self.JUDGMENT_OF_THE_PURE = self:GetSpellInfoOrNil(54153)
end

function Ovale:FirstInit()
	self:RemplirActionIndexes()
	self:RemplirListeTalents()
	self:ChercherNomsBuffs()
	-- self:InitEcranOption()
	
	local playerClass, englishClass = UnitClass("player")
	if (englishClass == "ROGUE") then
		self.gcd = 1
	else
		self.gcd = 1.5
	end
	-- OvaleFrame_Update(OvaleFrame)
	-- OvaleFrame:Show()
	
	self:ChargerDefaut()
	
	self.frame = LibStub("AceGUI-3.0"):Create("OvaleFrame")

	self.frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",self.db.profile.left,self.db.profile.top)

	self.firstInit = true
	
	
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	self.AceConfig:RegisterOptionsTable("Ovale", options.args.code, "Ovale")
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
		self.masterNodes = self:Compile(self.db.profile.code)
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
    	
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    -- self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	if (not self.firstInit) then
		self:FirstInit()
	end
	self:UNIT_AURA("","player")
	self:UpdateVisibility()
end

function Ovale:PLAYER_REGEN_ENABLED()
	self.enCombat = false
	if (Ovale.db.profile.apparence.enCombat and not Ovale.enCombat) then
		self.frame:Hide()
	end	
end

function Ovale:PLAYER_REGEN_DISABLED()
	self.enCombat = true
	
	if (Ovale.db.profile.apparence.enCombat and not Ovale.enCombat) then
		self.frame:Show()
	end	
	
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
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    -- self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self.frame:Hide()
end

function Ovale_GetNomAction(i)
	local actionText = GetActionText(i);
	local text;
	if (actionText) then
		text = "Macro "..actionText;
	else
		local type, id = GetActionInfo(i);
		if (type=="spell") then
			if (id~=0) then
				local spellName, spellRank = GetSpellName(id, BOOKTYPE_SPELL);
				text = "Sort ".. spellName;
				if (spellRank and spellRank~="") then
					text = text .. " ("..spellRank..")"
				end
			end
		elseif (type =="item") then
			local itemName = GetItemInfo(id)
			text = "Objet "..itemName
		else 
			if (type) then
				text = type;
				if (id) then
					text = text.." "..id;
				end
			end
		end
	end
	return text
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

function Ovale:GetSpellIdByName(name)
	if (not name) then
		return nil
	end
	local link = GetSpellLink(name);
	if (not link) then
		-- self:Print(name.." introuvable");
		return nil;
	end
	local a, b, spellId = string.find(link, "spell:(%d+)");
	return tonumber(spellId);
end

function Ovale:GetSpellIdRangMax(spellId)
	return self:GetSpellIdByName(GetSpellInfo(spellId))
end

function Ovale:GetSpellIdByNameAndRank(name,rank)
	if (not name or not rank) then
		return nil
	end
	local link = GetSpellLink(name.."("..rank..")");
	if (not link) then
		-- self:Print(name.."("..rank..")".." introuvable");
		return nil;
	end
	local a, b, spellId = string.find(link, "spell:(%d+)");
	return tonumber(spellId);
end

function Ovale:RemplirActionIndex(i)
	self.shortCut[i] = self:ChercherShortcut(i)
	local actionText = GetActionText(i);
	if (actionText) then
		self.actionMacro[actionText] = i
	else
		local type, id = GetActionInfo(i);
		if (type=="spell") then
			if (id~=0) then
				local spellName, spellRank = GetSpellName(id, BOOKTYPE_SPELL);
				self.actionSort[spellName] = i
			end
		elseif (type =="item") then
			self.actionObjet[id] = i
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

function Ovale:RemplirListeTalents()
	local numTabs = GetNumTalentTabs();
	self.listeTalents = {}
	for t=1, numTabs do
		local numTalents = GetNumTalents(t);
		for i=1, numTalents do
			local nameTalent, icon, tier, column, currRank, maxRank= GetTalentInfo(t,i);
			self.listeTalents[nameTalent] = nameTalent
			local link = GetTalentLink(t,i)
			local a, b, talentId = string.find(link, "talent:(%d+)");
			-- self:Print("talent = "..nameTalent.." id = ".. talentId)
			talentId = tonumber(talentId)
			self.talentIdToName[talentId] = nameTalent
			self.talentNameToId[nameTalent] = talentId
			self.pointsTalent[talentId] = currRank
			self.listeTalentsRemplie = true
		end
	end
end

function Ovale:ChercherBouton(sort)
	if (not sort) then
		return nil
	end
	local nom = GetSpellInfo(tonumber(sort))
	for i=1,120 do
		local type, id = GetActionInfo(i);
		if (type=="spell") then
			local spellName, spellRank = GetSpellName(id, BOOKTYPE_SPELL);
			if (spellName == nom) then
				return i
			end
		end
	end
end

function Ovale:InitCalculerMeilleureAction()
	self.attenteFinCast = 0
	self.currentSpellInfo = nil
	
	-- On attend que le sort courant soit fini
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo("player")
	if (spell) then
		self.attenteFinCast = endTime/1000 - Ovale.maintenant
		self.currentSpellInfo = self.spellInfo[spell]
	end
	
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitChannelInfo("player")
	if (spell and not Ovale.canStopChannelling[spell]) then
		self.attenteFinCast = endTime/1000 - Ovale.maintenant
		self.currentSpellInfo = self.spellInfo[spell]
	end
end

local function printTime(temps)
	if (temps == nil) then
		Ovale:Print("> nil")
	else
		Ovale:Print("> "..temps)
	end
end

function Ovale:CalculerMeilleureAction(element)
	if (self.bug and not self.trace) then
		return nil
	end
	
	if (not element) then
		return nil
	end
	
	if (element.type=="function")then
		if (element.func == "Spell" or element.func=="Macro" or element.func=="Item") then
			local action
			local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
				actionUsable, actionShortcut, actionIsCurrent, actionEnable
		
			if (element.func == "Spell" ) then
				local sort = self:GetSpellInfoOrNil(element.params[1])
				action = self.actionSort[sort]
				if (not action or not GetActionTexture(action)) then
					actionTexture = GetSpellTexture(sort)
					actionInRange = IsSpellInRange(sort, "target")
					actionCooldownStart, actionCooldownDuration, actionEnable = GetSpellCooldown(sort)
					actionUsable = IsUsableSpell(sort)
					actionShortcut = nil
					local casting = UnitCastingInfo("player")
					if (casting == sort) then
						actionIsCurrent = 1
					else
						actionIsCurrent = nil
					end
					-- not quite the same as IsCurrentAction. Why did they remove IsCurrentCast?
				end
			elseif (element.func=="Macro") then
				action = self.actionMacro[element.params[1]]
			elseif (element.func=="Item") then
				local itemId
				if (type(element.params[1]) == "number") then
					itemId = element.params[1]
				else
					local _,_,id = string.find(GetInventoryItemLink("player",GetInventorySlotInfo(element.params[1])) or "","item:(%d+):%d+:%d+:%d+")
					itemId = tonumber(id)
				end		
				if (Ovale.trace) then
					self:Print("Item "..itemId)
				end
				
				actionUsable = (GetItemSpell(itemId)~=nil)
				
				action = self.actionObjet[itemId]
				if (not action or not GetActionTexture(action)) then
					actionTexture = GetItemIcon(itemId)
					actionInRange = IsItemInRange(itemId, "target")
					actionCooldownStart, actionCooldownDuration, actionEnable = GetItemCooldown(itemId)
					actionShortcut = nil
					actionIsCurrent = nil
				end
			end
			
			if (action and not actionTexture) then
				actionTexture = GetActionTexture(action)
				actionInRange = IsActionInRange(action, "target")
				actionCooldownStart, actionCooldownDuration, actionEnable = GetActionCooldown(action)
				if (actionUsable == nil) then
					actionUsable = IsUsableAction(action)
				end
				actionShortcut = self.shortCut[action]
				actionIsCurrent = IsCurrentAction(action)				
			end
			
			if (not actionTexture) then
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." not found")
				end
				return nil
			end
			if (element.params.usable==1 and not actionUsable) then
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." not usable")
				end
				return nil
			end
			if (element.params.doNotRepeat==1 and actionIsCurrent) then
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." is current action")
				end
				return nil
			end
			if (actionEnable>0) then
				local restant
				if (not actionCooldownDuration or actionCooldownStart==0) then
					restant = 0
				else
					restant = actionCooldownDuration - (self.maintenant - actionCooldownStart);
				end
				if (restant<self.attenteFinCast) then
					restant = self.attenteFinCast
				end
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." remains "..restant)
				end
				local retourPriorite = element.params.priority
				if (not retourPriorite) then
					retourPriorite = 3
				end
				return restant, retourPriorite, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
					actionUsable, actionShortcut
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
			local temps = classe(element.params)
			
			if (Ovale.trace) then
				if (temps==nil) then
					self:Print("Function "..element.func.." returned nil")
				else
					self:Print("Function "..element.func.." returned "..temps)
				end
			end
			
			return temps
		end
	elseif (element.type == "before") then
		if (Ovale.trace) then
			self:Print(element.time.."s before")
		end
		local tempsA = Ovale:CalculerMeilleureAction(element.a)
		if (tempsA==nil) then
			return nil
		end
		if (tempsA<element.time) then
			return 0
		else
			return tempsA - element.time 
		end
	elseif (element.type == "and" or element.type == "if") then
		if (Ovale.trace) then
			self:Print(element.type)
		end
		local tempsA = Ovale:CalculerMeilleureAction(element.a)
		if (tempsA==nil) then
			return nil
		end
		local tempsB, priorite, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
			actionUsable, actionShortcut = Ovale:CalculerMeilleureAction(element.b)
		if (tempsB==nil) then
			return nil
		end
		if (tempsB>tempsA) then
			return  tempsB, priorite, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
				actionUsable, actionShortcut
		else
			return  tempsA, priorite, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
				actionUsable, actionShortcut
		end
	elseif (element.type == "unless") then
		if (Ovale.trace) then
			self:Print(element.type)
		end
		local tempsA = Ovale:CalculerMeilleureAction(element.a)
		if (tempsA==0) then
			return nil
		end
		local tempsB, priorite, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
			actionUsable, actionShortcut = Ovale:CalculerMeilleureAction(element.b)
		if (tempsA==nil or tempsA>tempsB) then
			return tempsB, priorite, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
				actionUsable, actionShortcut
		else
			return nil
		end
	elseif (element.type == "or") then
		if (Ovale.trace) then
			self:Print(element.type)
		end
		
		local tempsA = Ovale:CalculerMeilleureAction(element.a)
		local tempsB = Ovale:CalculerMeilleureAction(element.b)
		if (tempsB==nil or (tempsA~=nil and tempsB>tempsA)) then
			if (Ovale.trace) then printTime(tempsA) end
			return tempsA
		else
			if (Ovale.trace) then printTime(tempsB) end
			return tempsB
		end
	elseif (element.type == "group") then
		local meilleurFils
		local meilleurTempsFils
		local meilleurePrioriteFils
		local bestActionInRange
		local bestActionCooldownStart
		local bestActionCooldownDuration
		local bestActionUsable
		local bestActionShortCut
		 
		if (Ovale.trace) then
			self:Print(element.type)
		end
		
		for k, v in ipairs(element.nodes) do
			local nouveauTemps, priorite, action, actionInRange, actionCooldownStart, actionCooldownDuration,
				actionUsable, actionShortcut = Ovale:CalculerMeilleureAction(v)
			if (nouveauTemps) then
				local remplacer
			
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
						-- même si on doit attendre jusqu'à gcd secondes de plus
						maxEcart = self.gcd
					elseif (priorite and priorite < meilleurePrioriteFils) then
						-- A l'inverse, si il est moins prioritaire que le précédent, on ne le lance
						-- que si il se lance au moins 1,5s avant
						maxEcart = -self.gcd
					else
						maxEcart = -0.01
					end
					if (nouveauTemps-meilleurTempsFils < maxEcart) then
						remplacer = true
					end
				end
				if (remplacer) then
					meilleurTempsFils = nouveauTemps
					meilleurFils = action
					meilleurePrioriteFils = priorite
					bestActionInRange = actionInRange
					bestActionCooldownStart = actionCooldownStart
					bestActionCooldownDuration = actionCooldownDuration
					bestActionUsable = actionUsable
					bestActionShortCut = actionShortcut
				end
			end
		end
		
		if (meilleurTempsFils) then
			if (Ovale.trace) then
				self:Print("Best action "..meilleurFils.." remains "..meilleurTempsFils)
			end
			return meilleurTempsFils,meilleurePrioriteFils, meilleurFils, bestActionInRange, bestActionCooldownStart,
						bestActionCooldownDuration, bestActionUsable, bestActionShortCut
		else
			if (Ovale.trace) then printTime(nil) end
			return nil
		end
	end
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
			apparence = {enCombat=false, iconWidth = 64, iconHeight = 64, margin = 4,
				smallIconWidth=28, smallIconHeight=28, raccourcis=true, numeric=false, avecCible = false,
				verrouille = false, vertical = false},
			skin = {SkinID="Blizzard", Backdrop = true, Gloss = false, Colors = {}}
		}
	})
end

function Ovale:AfficherConfig()
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
	self.frame:Show()
	
	if (Ovale.db.profile.apparence.avecCible and not UnitExists("target")) then
		self.frame:Hide()
	end
	
	if (Ovale.db.profile.apparence.enCombat and not Ovale.enCombat) then
		self.frame:Hide()
	end	
end

function Ovale:UpdateFrame()
	self.frame:ReleaseChildren()

	self.frame:UpdateIcons()
	
	self:UpdateVisibility()
	
	self.checkBoxes = {}
	
	for k,v in pairs(self.casesACocher) do
		self.checkBoxes[k] = LibStub("AceGUI-3.0"):Create("CheckBox");
		self.frame:AddChild(self.checkBoxes[k])
		self.checkBoxes[k]:SetLabel(v)
		if (self.db.profile.check[k]) then
			self.checkBoxes[k]:SetValue(self.db.profile.check[k]);
		end
		self.checkBoxes[k].userdata.k = k
		self.checkBoxes[k]:SetCallback("OnValueChanged",OnCheckBoxValueChanged)
	end
	
	self.dropDowns = {}
	
	if (self.listes) then
		for k,v in pairs(self.listes) do
			self.dropDowns[k] = LibStub("AceGUI-3.0"):Create("Dropdown");
			self.dropDowns[k]:SetList(v)
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
