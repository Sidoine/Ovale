local L = LibStub("AceLocale-3.0"):GetLocale("Ovale")

Ovale = LibStub("AceAddon-3.0"):NewAddon("Ovale", "AceEvent-3.0", "AceConsole-3.0")

Ovale.defaut = {}
Ovale.action = {}
Ovale.listeSorts = {}
Ovale.casesACocher = {}
Ovale.actionSort = {}
Ovale.listeFormes = {}
Ovale.listeTalents = {}
Ovale.pointsTalent = {}
Ovale.talentIdToName = {}
Ovale.talentNameToId = {}
Ovale.firstInit = false
Ovale.Inferieur = 1
Ovale.Superieur = 2
Ovale.retourPriorite = 0
Ovale.retourAction = nil
Ovale.listeTalentsRemplie = false
Ovale.frame = nil
Ovale.checkBoxes = {}
Ovale.dropDowns = {}
Ovale.masterNode = nil
Ovale.bug = false

Ovale.arbre = {}

-- Ovale.trace=true
local nouvelleCondition
local nouveauSort

local options = 
{ 
	type = "group",
	args = 
	{
		code =
		{
			name = "Code",
			type = "group",
			args = 
			{
				code = 
				{
					order = 2,
					type = "input",
					multiline = 20,
					name = "Code",
					get = function(info)
						return Ovale.db.profile.code
					end,
					set = function(info,v)
						Ovale.db.profile.code = v
						-- Ovale:Print("code change")
					end,
					width = "full"
				},
				compiler = 
				{
					order = 1,
					type = "execute",
					name = "Compiler",
					func = function()
						Ovale.masterNode = Ovale:Compile(Ovale.db.profile.code)
						-- Ovale:Print(Ovale:DebugNode(Ovale.masterNode))
					end
				}
			}
		}
	}
}

function Ovale:OnInitialize()
	self.AceConfig = LibStub("AceConfig-3.0");
	self.AceConfigDialog = LibStub("AceConfigDialog-3.0");
end

function Ovale:ACTIONBAR_SLOT_CHANGED(event, slot, unknown)
	if (slot) then
	-- on reçoit aussi si c'est une macro avec mouseover à chaque fois que la souris passe sur une cible!
		self:RemplirActionIndex(tonumber(slot))
	end
end

function Ovale:CHARACTER_POINTS_CHANGED()
	self:RemplirListeTalents()
end

function Ovale:SPELLS_CHANGED()
	self:RemplirListeSorts();
	self:RemplirListeFormes()
	self:RemplirActionIndexes()
	self:RemplirListeTalents()
end

function Ovale:UPDATE_BINDINGS()
	self:RemplirActionIndexes()
end

function Ovale:HandleProfileChanges()
	if (self.firstInit) then
		if (self.db.profile.code) then
			self.masterNode = self:Compile(self.db.profile.code)
		end
	end
end

function Ovale:FirstInit()
	self:RemplirListeSorts()
	self:RemplirListeFormes()
	self:RemplirActionIndexes()
	self:RemplirListeTalents()
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

	self.frame:SetWidth(64)
	self.frame:SetHeight(64)
	self.frame:SetPoint("TOPLEFT",self.db.profile.left,-self.db.profile.top)

	self.firstInit = true
	
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	self.AceConfig:RegisterOptionsTable("Ovale", options.args.code, "Ovale")
	self.AceConfig:RegisterOptionsTable("Ovale Profile", options.args.profile)

	self.AceConfigDialog:AddToBlizOptions("Ovale", "Ovale")
	self.AceConfigDialog:AddToBlizOptions("Ovale Profile", "Profile", "Ovale")
	
	self.db.RegisterCallback( self, "OnNewProfile", "HandleProfileChanges" )
	self.db.RegisterCallback( self, "OnProfileReset", "HandleProfileChanges" )
	self.db.RegisterCallback( self, "OnProfileChanged", "HandleProfileChanges" )
	self.db.RegisterCallback( self, "OnProfileCopied", "HandleProfileChanges" )

	
	if (self.db.profile.code) then
		self.masterNode = self:Compile(self.db.profile.code)
	end
	
	--self:UpdateFrame()
	
	self:Test()
end

function Ovale:OnEnable()
    -- Called when the addon is enabled
    self:RegisterEvent("PLAYER_REGEN_ENABLED");
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
    self:RegisterEvent("SPELLS_CHANGED")
    self:RegisterEvent("CHARACTER_POINTS_CHANGED")
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
    self:RegisterEvent("UPDATE_BINDINGS");
	
	if (not self.firstInit) then
		self:FirstInit()
	end
	
end

function Ovale:PLAYER_REGEN_ENABLED()
end

function Ovale:PLAYER_REGEN_DISABLED()
end

function Ovale:OnDisable()
    -- Called when the addon is disabled
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:UnregisterEvent("PLAYER_REGEN_DISABLED")
    self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
    self:UnregisterEvent("SPELLS_CHANGED")
    self:UnregisterEvent("CHARACTER_POINTS_CHANGED")
    self:UnregisterEvent("UPDATE_BINDINGS")
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

function Ovale:RemplirListeFormes()
	self.listeFormes[0] = "Humanoïde";
	local index=1;
	while true do
		local icon, name, active, castable = GetShapeshiftFormInfo(index);
		if not icon then
			break;
		end
		Ovale.listeFormes[index] = name;
		index = index + 1
	end
end

function Ovale:RemplirListeSorts()
	local sorts = {};
	local name, texture, offset, numSpells = GetSpellTabInfo(1);
	local i=numSpells+1;
	while true do
		local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
		if not spellName then
			break
		end
		-- DEFAULT_CHAT_FRAME:AddMessage(spellName);
		local nom = spellName;
		local a, b, numeroRang = string.find(spellRank, "(%d+)");
		--if (not numeroRang or tonumber(numeroRang)==1) then
			Ovale.listeSorts[nom] = nom;
		--else
		--end
		i = i+1;
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

function Ovale:CalculerMeilleureAction(element)
	if (self.bug and not self.trace) then
		return nil
	end
	
	if (not element) then
		return nil
	end

	self.retourAction = nil
	self.retourPriorite = nil
				
	if (element.type=="function")then
		if (element.func == "Spell" or element.func=="Macro" or element.func=="Item") then
			local action
			if (element.func == "Spell" ) then
				local sort = self:GetSpellInfoOrNil(element.params[1])
				action = self.actionSort[sort]
			elseif (element.func=="Macro") then
				action = self.actionMacro[element.params[1]]
			elseif (element.func=="Item") then
				action = self.actionObjet[element.params[1]]
			end
			if (not action) then
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." not found")
				end
				return nil
			end
			if (element.params.usable==1 and not IsUsableAction(action)) then
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." not usable")
				end
				return nil
			end
			if (element.params.doNotRepeat==1 and IsCurrentAction(action)) then
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." is current action")
				end
				return nil
			end
			local start, duration, enable = GetActionCooldown(action)
			local restant
			if (enable>0) then
				if (not duration or start==0) then
					restant = 0
				else
					restant = duration - (self.maintenant - start);
				end
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." remains "..restant)
				end
				self.retourAction = action
				self.retourPriorite = element.params.priority
				if (not self.retourPriorite) then
					self.retourPriorite = 3
				end
				return restant
			else
				if (Ovale.trace) then
					self:Print("Action "..element.params[1].." not enabled")
				end
				return nil
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
			
			if (temps == nil) then
				return nil
			end
	 		return temps
		end
	elseif (element.type == "and" or element.type == "if") then
		if (Ovale.trace) then
			self:Print(element.type)
		end
		local tempsA = Ovale:CalculerMeilleureAction(element.a)
		if (tempsA==nil) then
			return nil
		end
		local tempsB = Ovale:CalculerMeilleureAction(element.b)
		if (tempsB==nil) then
			return nil
		end
		if (tempsB>tempsA) then
			return tempsB
		else
			return tempsA
		end
	elseif (element.type == "unless") then
		if (Ovale.trace) then
			self:Print(element.type)
		end
		local tempsA = Ovale:CalculerMeilleureAction(element.a)
		if (tempsA~=nil) then
			return nil
		end
		local tempsB = Ovale:CalculerMeilleureAction(element.b)
		return tempsB
	elseif (element.type == "or") then
		if (Ovale.trace) then
			self:Print(element.type)
		end
		
		local tempsA = Ovale:CalculerMeilleureAction(element.a)
		local tempsB = Ovale:CalculerMeilleureAction(element.b)
		if (tempsB==nil or tempsB>tempsA) then
			return tempsA
		else
			return tempsB
		end
	elseif (element.type == "group") then
		local meilleurFils
		local meilleurTempsFils
		local meilleurePrioriteFils
		 
		if (Ovale.trace) then
			self:Print(element.type)
		end
		
		for k, v in ipairs(element.nodes) do
			local nouveauTemps = Ovale:CalculerMeilleureAction(v)
			local action = self.retourAction
			local priorite = self.retourPriorite
			if (nouveauTemps) then
				local remplacer
				if (not meilleurTempsFils) then
					remplacer = true
				else
					-- temps maximum entre le nouveau sort et le précédent
					local maxEcart
					if (priorite and not meilleurePrioriteFils) then
						self.bug = true
						self:Print("meilleurePrioriteFils nil and priorite not nil")
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
						maxEcart = 0
					end
					if (nouveauTemps-meilleurTempsFils < maxEcart) then
						remplacer = true
					end
				end
				if (remplacer) then
					meilleurTempsFils = nouveauTemps
					meilleurFils = action
					meilleurePrioriteFils = priorite
				end
			end
		end
		
		if (meilleurFils) then
			if (Ovale.trace) then
				self:Print("Best action "..meilleurFils.." remains "..meilleurTempsFils)
			end
			self.retourPriorite = meilleurePrioriteFils
			self.retourAction = meilleurFils
			return meilleurTempsFils
		else
			return nil
		end
	end
end

function Ovale:ChargerDefaut()
	local localizedClass, englishClass = UnitClass("player")
	
	self.db = LibStub("AceDB-3.0"):New("OvaleDB",
	{
		profile = 
		{
			code = Ovale.defaut[englishClass],
			left = 0,
			top = 0,
			check = {},
			list = {}
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

function Ovale:UpdateFrame()
	self.frame:ReleaseChildren()

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

function Ovale:Test()
	this.node = {}
	
end