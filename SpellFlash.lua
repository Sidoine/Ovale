--[[--------------------------------------------------------------------
    Copyright (C) 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleSpellFlash = Ovale:NewModule("OvaleSpellFlash", "AceEvent-3.0")
Ovale.OvaleSpellFlash = OvaleSpellFlash

--<private-static-properties>
local L = Ovale.L
local OvaleOptions = Ovale.OvaleOptions

-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleFuture = nil
local OvaleSpellBook = nil
local OvaleStance = nil

local pairs = pairs
local type = type
local API_GetTime = GetTime
local API_UnitHasVehicleUI = UnitHasVehicleUI
local API_UnitExists = UnitExists
local API_UnitIsDead = UnitIsDead
local API_UnitCanAttack = UnitCanAttack
-- GLOBALS: _G

-- Local reference to SpellFlashCore addon.
local SpellFlashCore = nil

-- Flash colors.
local colorMain = {}
local colorShortCd = {}
local colorCd = {}
local colorInterrupt = {}
-- Map icon help text to a flash color.
local FLASH_COLOR = {
	main = colorMain,
	cd = colorCd,
	shortcd = colorCd,
}

-- Standard colors defined by SpellFlashCore.
local COLORTABLE = {
	aqua	= { r = 0, g = 1, b = 1 },
	blue	= { r = 0, g = 0, b = 1 },
	gray	= { r = 0.5, g = 0.5, b = 0.5 },
	green	= { r = 0.1, g = 1, b = 0.1 },
	orange	= { r = 1, g = 0.5, b = 0.25 },
	pink	= { r = 0.9, g = 0.4, b = 0.4 },
	purple	= { r = 1, g = 0, b = 1 },
	red		= { r = 1, g = 0.1, b = 0.1 },
	white	= { r = 1, g = 1, b = 1 },
	yellow	= { r = 1, g = 1, b = 0 },
}

do
	local defaultDB = {
		-- Store all SpellFlash settings into a separate table.
		spellFlash = {
			brightness = 1,
			enabled = true,
			hasHostileTarget = false,
			hasTarget = false,
			hideInVehicle = false,
			inCombat = false,
			size = 2.4,
			threshold = 500,
			colorMain = { r = 1, g = 1, b = 1 },		-- white
			colorShortCd = { r = 1, g = 1, b = 0 },		-- yellow
			colorCd = { r = 1, g = 1, b = 0 },			-- yellow
			colorInterrupt = { r = 0, g = 1, b = 1 }, 	-- aqua
		},
	}
	local options = {
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
					disabled = function()
						return not SpellFlashCore or not Ovale.db.profile.apparence.spellFlash.enabled
					end,
				},
				size = {
					order = 60,
					type = "range",
					name = L["Flash size"],
					min = 0, max = 3, bigStep = 0.01,
					isPercent = true,
					disabled = function()
						return not SpellFlashCore or not Ovale.db.profile.apparence.spellFlash.enabled
					end,
				},
				threshold = {
					order = 70,
					type = "range",
					name = L["Flash threshold"],
					desc = L["Time (in milliseconds) to begin flashing the spell to use before it is ready."],
					min = 0, max = 1000, step = 1, bigStep = 50,
					disabled = function()
						return not SpellFlashCore or not Ovale.db.profile.apparence.spellFlash.enabled
					end,
				},
				colors = {
					order = 80,
					type = "group",
					name = L["Colors"],
					inline = true,
					disabled = function()
						return not SpellFlashCore or not Ovale.db.profile.apparence.spellFlash.enabled
					end,
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
	}

	-- Insert defaults and options into OvaleOptions.
	for k, v in pairs(defaultDB) do
		OvaleOptions.defaultDB.profile.apparence[k] = v
	end
	for k, v in pairs(options) do
		OvaleOptions.options.args.apparence.args[k] = v
	end
	OvaleOptions:RegisterOptions(OvaleSpellFlash)
end
--</private-static-properties>

--<public-static-methods>
function OvaleSpellFlash:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvaleFuture = Ovale.OvaleFuture
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleStance = Ovale.OvaleStance
end

function OvaleSpellFlash:OnEnable()
	SpellFlashCore = _G["SpellFlashCore"]
	self:RegisterMessage("Ovale_OptionChanged")
	self:Ovale_OptionChanged()
end

function OvaleSpellFlash:OnDisable()
	SpellFlashCore = nil
	self:UnregisterMessage("Ovale_OptionChanged")
end

function OvaleSpellFlash:Ovale_OptionChanged()
	local db = Ovale.db.profile.apparence.spellFlash
	-- Main attack.
	colorMain.r = db.colorMain.r
	colorMain.g = db.colorMain.g
	colorMain.b = db.colorMain.b
	-- Long cooldown abilities.
	colorCd.r = db.colorCd.r
	colorCd.g = db.colorCd.g
	colorCd.b = db.colorCd.b
	-- Short cooldown abilities.
	colorShortCd.r = db.colorShortCd.r
	colorShortCd.g = db.colorShortCd.g
	colorShortCd.b = db.colorShortCd.b
	-- Interrupts.
	colorInterrupt.r = db.colorInterrupt.r
	colorInterrupt.g = db.colorInterrupt.g
	colorInterrupt.b = db.colorInterrupt.b
end

function OvaleSpellFlash:IsSpellFlashEnabled()
	local enabled = (SpellFlashCore ~= nil)
	local db = Ovale.db.profile.apparence.spellFlash
	if enabled and not db.enabled then
		enabled = false
	end
	if enabled and db.inCombat and not OvaleFuture.inCombat then
		enabled = false
	end
	if enabled and db.hideInVehicle and API_UnitHasVehicleUI("player") then
		enabled = false
	end
	if enabled and db.hasTarget and not API_UnitExists("target") then
		enabled = false
	end
	if enabled and db.hasHostileTarget and (API_UnitIsDead("target") or not API_UnitCanAttack("player", "target")) then
		enabled = false
	end
	return enabled
end

function OvaleSpellFlash:Flash(state, node, element, start, now)
	-- SpellFlash settings.
	local db = Ovale.db.profile.apparence.spellFlash
	now = now or API_GetTime()
	if self:IsSpellFlashEnabled() and start and start - now <= db.threshold / 1000 then
		-- Check that element is an action.
		if element and element.type == "action" then
			local spellId, spellInfo
			if element.lowername == "spell" then
				spellId = element.positionalParams[1]
				spellInfo = OvaleData.spellInfo[spellId]
			end
			local interrupt = spellInfo and spellInfo.interrupt

			-- Flash color.
			local color = COLORTABLE["white"]
			local flash = element.namedParams and element.namedParams.flash
			local iconFlash = node.namedParams.flash
			local iconHelp = node.namedParams.help
			if flash and COLORTABLE[flash] then
				-- Highest priority is known flash color set in the action parameters.
				color = COLORTABLE[flash]
			elseif iconFlash and COLORTABLE[iconFlash] then
				-- Next highest priority is known flash color set in the icon parameters.
				color = COLORTABLE[iconFlash]
			elseif iconHelp and FLASH_COLOR[iconHelp] then
				-- Fall back to color based on the help set in the icon parameters.
				color = FLASH_COLOR[iconHelp]
				-- Adjust color if it's a "cd" ability that is showing an interrupt.
				if interrupt == 1 and iconHelp == "cd" then
					color = colorInterrupt
				end
			end

			-- Flash size (percent).
			local size = db.size * 100
			if iconHelp == "cd" then
				-- Adjust to half size for "cd" abilities.
				if interrupt ~= 1 then
					size = size * 0.5
				end
			end

			-- Flash brightness (percent).
			local brightness = db.brightness * 100

			if element.lowername == "spell" then
				if OvaleStance:IsStanceSpell(spellId) then
					SpellFlashCore.FlashForm(spellId, color, size, brightness)
				end
				if OvaleSpellBook:IsPetSpell(spellId) then
					SpellFlashCore.FlashPet(spellId, color, size, brightness)
				end
				SpellFlashCore.FlashAction(spellId, color, size, brightness)
			elseif element.lowername == "item" then
				-- Item ID.
				local itemId = element.positionalParams[1]
				SpellFlashCore.FlashItem(itemId, color, size, brightness)
			end
		end
	end
end

function OvaleSpellFlash:UpgradeSavedVariables()
	local profile = Ovale.db.profile

	-- SpellFlash options have been moved and renamed.
	if profile.apparence.spellFlash and type(profile.apparence.spellFlash) ~= "table" then
		local enabled = profile.apparence.spellFlash
		profile.apparence.spellFlash = {}
		profile.apparence.spellFlash.enabled = enabled
	end
end
--</public-static-methods>
