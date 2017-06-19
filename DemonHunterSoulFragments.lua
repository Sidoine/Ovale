local OVALE, Ovale = ...
local OvaleDemonHunterSoulFragments = Ovale:NewModule("OvaleDemonHunterSoulFragments", "AceEvent-3.0")
Ovale.OvaleDemonHunterSoulFragments = OvaleDemonHunterSoulFragments

local OvaleDebug = nil
local OvaleState = nil

local ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove
local API_GetTime = GetTime
local API_GetSpellCount = GetSpellCount

function OvaleDemonHunterSoulFragments:OnInitialize()
	OvaleDebug = Ovale.OvaleDebug
	OvaleState = Ovale.OvaleState
	
	OvaleDebug:RegisterDebugging(OvaleDemonHunterSoulFragments)
	
	self:SetCurrentSoulFragments(0)
end

function OvaleDemonHunterSoulFragments:OnEnable()
	if Ovale.playerClass == "DEMONHUNTER" then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		OvaleState:RegisterState(self, self.statePrototype)
	end
end

function OvaleDemonHunterSoulFragments:OnDisable()
	if Ovale.playerClass == "DEMONHUNTER" then
		OvaleState:UnregisterState(self)
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	end
end

local SOUL_FRAGMENTS_BUFF_ID = 228477
local SOUL_FRAGMENTS_SPELL_HEAL_ID = 203794
local SOUL_FRAGMENTS_SPELL_CAST_SUCCESS_ID = 204255

local SOUL_FRAGMENT_FINISHERS = {
	[228477] = true, -- Soul Cleave
	[247454] = true, -- Spirit Bomb
	[227225] = true, -- Soul Barrier
}

function OvaleDemonHunterSoulFragments:PLAYER_REGEN_ENABLED()
	self:SetCurrentSoulFragments()
end

function OvaleDemonHunterSoulFragments:PLAYER_REGEN_DISABLED()
	self.soul_fragments = {}
	self:SetCurrentSoulFragments()
end

function OvaleDemonHunterSoulFragments:COMBAT_LOG_EVENT_UNFILTERED( event, _, subtype, _, sourceGUID, _, _, _, _, _, _, _, spellID, spellName )
    local me = Ovale.playerGUID
    
    if sourceGUID == me then
		--print(subtype.." - "..spellName.." ("..spellID..")")
		local current_sould_fragment_count = self.last_soul_fragment_count
		if subtype == "SPELL_HEAL" and spellID == SOUL_FRAGMENTS_SPELL_HEAL_ID then
			self:SetCurrentSoulFragments(self.last_soul_fragment_count.fragments-1)
		end
		
		if subtype == "SPELL_CAST_SUCCESS" and spellID == SOUL_FRAGMENTS_SPELL_CAST_SUCCESS_ID then
			self:SetCurrentSoulFragments(self.last_soul_fragment_count.fragments+1)
		end
		
		if subtype == "SPELL_CAST_SUCCESS" and SOUL_FRAGMENT_FINISHERS[spellID] then
			self:SetCurrentSoulFragments(0)
		end
    end
	
	-- sync up the count if needed
	local now = API_GetTime()
	if now - self.last_soul_fragment_count.timestamp >= 1.5 then
		self:SetCurrentSoulFragments()
	end
end

function OvaleDemonHunterSoulFragments:SetCurrentSoulFragments(count)
	self.soul_fragments = self.soul_fragments or {}
	
	local now = API_GetTime()
	if type(count) ~= "number" then count = API_GetSpellCount(SOUL_FRAGMENTS_BUFF_ID) or 0 end
	if count < 0 then count = 0 end
	
	local entry = {["timestamp"] =  now, ["fragments"] = count}

	self:Debug("Setting current soul fragment count to '%d' (at: %s)", entry.fragments, entry.timestamp)
	self.last_soul_fragment_count = entry
	-- only insert in combat
	tinsert(self.soul_fragments, entry)
end

-- /run Ovale.OvaleDemonHunterSoulFragments:DebugSoulFragments()
-- /dump Ovale.OvaleDemonHunterSoulFragments.soul_fragments
function OvaleDemonHunterSoulFragments:DebugSoulFragments()
	print("Fragments:" .. self.last_soul_fragment_count["fragments"])
	print("Time:" .. self.last_soul_fragment_count["timestamp"])
end

OvaleDemonHunterSoulFragments.statePrototype = {}
local statePrototype = OvaleDemonHunterSoulFragments.statePrototype

statePrototype.SoulFragments = function(state, atTime) 
	for k,v in spairs(OvaleDemonHunterSoulFragments.soul_fragments, function(t,a,b) return t[a]["timestamp"] > t[b]["timestamp"] end) do
		if(atTime >= v["timestamp"]) then
			return v["fragments"]
		end
	end
	return self.last_soul_fragment_count.fragments or 0
end

-- https://stackoverflow.com/a/15706820/1134155
function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end