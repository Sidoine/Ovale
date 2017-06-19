local OVALE, Ovale = ...
local OvaleSigil = Ovale:NewModule("OvaleSigil", "AceEvent-3.0")
Ovale.OvaleSigil = OvaleSigil

local OvaleProfiler = Ovale.OvaleProfiler

local OvalePaperDoll = nil
local OvaleSpellBook = nil
local OvaleState = nil

local ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove
local API_GetTime = GetTime

local activated_sigils = {}

OvaleProfiler:RegisterProfiling(OvaleSigil)

function OvaleSigil:OnInitialize()
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleState = Ovale.OvaleState
	
	activated_sigils["flame"] = {}
	activated_sigils["silence"] = {}
	activated_sigils["misery"] = {}
	activated_sigils["chains"] = {}
end

function OvaleSigil:OnEnable()
	if Ovale.playerClass == "DEMONHUNTER" then
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		OvaleState:RegisterState(self, self.statePrototype)
	end
end

function OvaleSigil:OnDisable()
	if Ovale.playerClass == "DEMONHUNTER" then
		OvaleState:UnregisterState(self)
		self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	end
end

local sigil_start = {
	[204596] = { type="flame"}, -- Sigil of flame
	[189111] = { type="flame", talent=8}, -- Infernal strike
	[202137] = { type="silence"}, -- Sigil of Silence
	[207684] = { type="misery"}, -- Sigil of Misery
	[202138] = { type="chains"}, -- Sigil of Chains
}

local sigil_end = {
	[204598] = { type="flame"},
	[204490] = { type="silence"},
	[207685] = { type="misery"},
	[204834] = { type="chains"},
}

local QUICKENED_SIGILS_TALENT = 15

function OvaleSigil:UNIT_SPELLCAST_SUCCEEDED(event, unitId, spellName, spellRank, guid, spellId, ...)
	if (not OvalePaperDoll:IsSpecialization("vengeance")) then return end
	if (unitId == nil or unitId ~= "player") then return end

	local id = tonumber(spellId)
	--print(event .. " " .. spellName .. " " .. id)
	-- queue all the sigils when they are cast
	if (sigil_start[id] ~= nil) then
		local s = sigil_start[id];
		local t = s.type
		local tal = s.talent or nil;
		if (tal == nil or OvaleSpellBook:GetTalentPoints(tal) > 0) then
			if(OvaleSpellBook:GetTalentPoints(QUICKENED_SIGILS_TALENT) > 0) then
				tinsert(activated_sigils[t], API_GetTime()+2.5)
			else
				tinsert(activated_sigils[t], API_GetTime()+3.5)
			end
		end
	end
	
	-- unqueue all the sigils when they finished charging
	if(sigil_end[id] ~= nil) then
		local s = sigil_end[id];
		local t = s.type
		tremove(activated_sigils[t], 1)
	end
end

OvaleSigil.statePrototype = {}
local statePrototype = OvaleSigil.statePrototype

statePrototype.IsSigilCharging = function(state, type, atTime) 
	atTime = atTime or state.currentTime
	
	if(#activated_sigils[type] == 0) then return false end
	
	local charging = false
	for _,v in ipairs(activated_sigils[type]) do
		charging = charging or atTime < v
	end
	return charging
end