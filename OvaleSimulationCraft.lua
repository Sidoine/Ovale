--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleSimulationCraft = {}
Ovale.OvaleSimulationCraft = OvaleSimulationCraft

--<private-static-properties>
local OvaleLexer = Ovale.OvaleLexer

local format = string.format
local gmatch = string.gmatch
local gsub = string.gsub
local setmetatable = setmetatable
local strfind = string.find
local strlower = string.lower
local strmatch = string.match
local strsplit = strsplit
local strupper = string.upper
local tconcat = table.concat
local tinsert = table.insert
local tonumber = tonumber
local tremove = table.remove
local tsort = table.sort
local type = type
local wipe = table.wipe
local yield = coroutine.yield
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local INDENTATION = {}
do
	INDENTATION[0] = ""
	local metatable = {
		__index = function(tbl, key)
				key = tonumber(key)
				if key > 0 then
					local s = tbl[key - 1] .. "	"
					rawset(tbl, key, s)
					return s
				end
				return INDENTATION[0]
			end,
	}
	setmetatable(INDENTATION, metatable)
end

local SIMC_CLASS = {}
do
	for class in pairs(RAID_CLASS_COLORS) do
		SIMC_CLASS[strlower(class)] = true
	end
end
--<private-static-properties>

--<public-static-properties>
OvaleSimulationCraft.simcString = nil
OvaleSimulationCraft.simcComments = nil
OvaleSimulationCraft.indent = 0
OvaleSimulationCraft.profile = {}
OvaleSimulationCraft.symbols = {}
OvaleSimulationCraft.script = {}
OvaleSimulationCraft.__index = OvaleSimulationCraft
do
	-- Class constructor
	setmetatable(OvaleSimulationCraft, { __call = function(self, ...) return self:New(...) end })
end
--</public-static-properties>

--<private-static-methods>
local function NameValuePair(expr)
	local name, value = strmatch(expr, "^([^=]*)=(.*)")
	if strmatch(value, "^[%-]?%d+%.?%d*$") then
		value = tonumber(value)
	end
	return name, value
end
--</private-static-methods>

--<public-static-methods>
function OvaleSimulationCraft:New(simcString)
	local obj = {
		simcString = nil,
		simcComments = nil,
		indent = 0,
		profile = {},
		symbols = {},
		script = {},
	}
	setmetatable(obj, self)
	if simcString then
		obj:ParseProfile(simcString)
	end
	return obj
end

function OvaleSimulationCraft:Indent()
	self.indent = self.indent + 1
end

function OvaleSimulationCraft:UnIndent()
	self.indent = (self.indent > 0) and (self.indent - 1) or 0
end

function OvaleSimulationCraft:Append(script, ...)
	local s = format("%s%s", INDENTATION[self.indent], format(...))
	tinsert(script, s)
end

function OvaleSimulationCraft:ParseProfile(simcString)
	self.simcString = simcString
	local profile = self.profile
	for line in gmatch(simcString, "[^\r\n]+") do
		line = strmatch(line, "^%s*(.-)%s*$")
		if not (strmatch(line, "^#.*") or strmatch(line, "^$")) then
			local key, value = strmatch(line, "([^%+=]+)%+?=(.*)")
			if not profile[key] then
				profile[key] = value
			elseif type(profile[key]) == "table" then
				tinsert(profile[key], value)
			else
				local oldValue = profile[key]
				profile[key] = {}
				tinsert(profile[key], oldValue)
				tinsert(profile[key], value)
			end
		end
	end
	-- Concatenate variables defined over multiple lines using +=
	for k, v in pairs(profile) do
		if type(v) == "table" then
			local value = tconcat(v)
			profile[k] = value
		end
	end
	for k, v in pairs(profile) do
		if strmatch(k, "^actions") then
			local listName = strmatch(k, "^actions[.]([%w_]+)") or "default"
			profile[k] = nil
			profile.actionList = profile.actionList or {}
			local tbl = { strsplit("/", v) }
			for i, action in ipairs(tbl) do
				local line = tbl[i]
				tbl[i] = { strsplit(",", action) }
				tbl[i].action = tremove(tbl[i], 1)
				tbl[i].line = line
			end
			profile.actionList[listName] = tbl
		elseif k == "glyphs" then
			profile[k] = { strsplit("/", v) }
		elseif k == "professions" then
			local tbl = { strsplit("/", v) }
			for i, profession in ipairs(tbl) do
				local prof, level = NameValuePair(profession)
				tbl[i] = nil
				tbl[prof] = level
			end
			profile[k] = tbl
		end
	end
end

do
	local symbols = {}

	function OvaleSimulationCraft:GenerateScript(script)
		script = script or {}
		local profile = self.profile
		for class in pairs(SIMC_CLASS) do
			local simcName = profile[class]
			if simcName then
				profile.class = class
				self:Append(script, "# Based on SimulationCraft profile %s.", simcName)
				self:Append(script, "#	class=%s", class)
			end
		end
		if profile.spec then
			self:Append(script, "#	spec=%s", profile.spec)
		end
		if profile.talents then
			self:Append(script, "#	talents=%s", profile.talents)
		end
		if profile.glyphs then
			self:Append(script, "#	glyphs=%s", tconcat(profile.glyphs, "/"))
		end
		if profile.default_pet then
			self:Append(script, "#	pet=%s", profile.default_pet)
		end
		if profile.actionList then
			for listName, actionList in pairs(profile.actionList) do
				self:ParseActionList(script, listName, actionList)
			end
		end
		self:Append(script, "")

		tsort(self.symbols)
		wipe(symbols)
		for _, v in ipairs(self.symbols) do
			if not symbols[v] then
				symbols[v] = true
				tinsert(symbols, v)
			end
		end
		self:Append(script, "### Pre-defined symbols")
		for _, v in ipairs(symbols) do
			self:Append(script, format("# %s", v))
		end
		return script
	end
end

do
	local function TitleCase(first, rest)
		return strupper(first) .. strlower(rest)
	end

	function OvaleSimulationCraft:FunctionName(listName)
		if self.profile.spec then
			listName = format("%s_%s_actions", self.profile.spec, listName)
		else
			listName = format("%s_actions", listName)
		end
		listName = gsub(listName, "_", " ")
		listName = gsub(listName, "(%a)(%w*)", TitleCase)
		listName = gsub(listName, "%s", "")
		return listName
	end
end

function OvaleSimulationCraft:ParseActionList(script, listName, actionList)
	self:Append(script, "")
	self:Append(script, "AddFunction %s", self:FunctionName(listName))
	self:Append(script, "{")
	self:Indent()
	local indent = self.indent
	for i, actionLine in ipairs(actionList) do
		self:ParseActionLine(script, actionLine)
	end
	while self.indent > indent do
		self:UnIndent()
		self:Append(script, "}")
	end
	self:UnIndent()
	self:Append(script, "}")
end

do
	local TO_NAME = {
		druid = {
			balance = {
				["dream_of_cenarius"] = "dream_of_cenarius_caster",
				["force_of_nature"] = "force_of_nature_caster",
				["heart_of_the_wild"] = "heart_of_the_wild_caster",
				["wild_mushroom"] = "wild_mushroom_caster",
			},
			feral = {
				["berserk"] = "berserk_cat",
				["dream_of_cenarius"] = "dream_of_cenarius_melee",
				["force_of_nature"] = "force_of_nature_melee",
				["heart_of_the_wild"] = "heart_of_the_wild_melee",
				["omen_of_clarity"] = "omen_of_clarity_melee",
				["stealth"] = "prowl",
			},
			restoration = {
				["force_of_nature"] = "force_of_nature_heal",
				["heart_of_the_wild"] = "heart_of_the_wild_heal",
				["omen_of_clarity"] = "omen_of_clarity_heal",
			},
		},
		paladin = {
			protection = {
				["arcane_torrent"] = "arcane_torrent_mana",
				["guardian_of_ancient_kings"] = "guardian_of_ancient_kings_tank",
			},
			retribution = {
				["arcane_torrent"] = "arcane_torrent_mana",
				["guardian_of_ancient_kings"] = "guardian_of_ancient_kings_melee",
			},
		},
		priest = {
			shadow = {
				["arcane_torrent"] = "arcane_torrent_mana",
			},
		},
		rogue = {
			assassination = {
				["arcane_torrent"] = "arcane_torrent_energy",
			},
			combat = {
				["arcane_torrent"] = "arcane_torrent_energy",
			},
			subtlety = {
				["arcane_torrent"] = "arcane_torrent_energy",
			},
		},
		shaman = {
			elemental = {
				["ascendance"] = "ascendance_caster",
			},
			enhancement = {
				["ascendance"] = "ascendance_melee",
			},
			restoration = {
				["ascendance"] = "ascendance_heal",
			},
		},
		warlock = {
			affliction = {
				["dark_soul"] = "dark_soul_misery",
			},
			demonology = {
				["dark_soul"] = "dark_soul_knowledge",
			},
			destruction = {
				["dark_soul"] = "dark_soul_instability",
				["rain_of_fire"] = "rain_of_fire_aftermath",
			},
		},
	}

	function OvaleSimulationCraft:Name(name)
		local class, spec = self.profile.class, self.profile.spec
		if TO_NAME[class] and TO_NAME[class][spec] and TO_NAME[class][spec][name] then
			return TO_NAME[class][spec][name]
		end
		return name
	end
end

do
	local SIMC_ACTION = {
		["^jade_serpent_potion$"] = "UsePotionIntellect()",
		["^mogu_power_potion$"] = "UsePotionStrength()",
		["^virmens_bite_potion$"] = "UsePotionAgility()",
		["^$"] = false,
		["^auto_attack$"] = false,
		["^auto_shot$"] = false,
		["^flask$"] = false,
		["^food$"] = false,
		["^snapshot_stats$"] = false,
		-- Death Knight
		["^blood_presence$"] = "if not Stance(deathknight_blood_presence) Spell(blood_presence)",
		["^frost_presence$"] = "if not Stance(deathknight_frost_presence) Spell(frost_presence)",
		["^unholy_presence$"] = "if not Stance(deathknight_unholy_presence) Spell(unholy_presence)",
		-- Druid
		["^cat_form$"] = "if not Stance(druid_cat_form) Spell(cat_form)",
		["^moonkin_form$"] = "if not Stance(druid_moonkin_form) Spell(moonkin_form)",
		["^prowl$"] = "if Stealthed(no) Spell(prowl)",
		["^ravage$"] = "Spell(ravage usable=1)",
		["^savage_roar$"] = "SavageRoar()",
		["^skull_bash_cat$"] = "FeralInterrupt()",
		-- Hunter
		["^aspect_of_the_"] = function(simc, action) return format("if not Stance(hunter_%s) Spell(%s)", action, action) end,
		["^kill_command$"] = "KillCommand()",
		["^kill_shot$"] = "Spell(kill_shot usable=1)",
		["^summon_pet$"] = "SummonPet()",
		-- Mage
		["^arcane_brilliance$"] = "if BuffExpires(critical_strike any=1) or BuffExpires(spell_power_multiplier any=1) Spell(arcane_brilliance)",
		["^cancel_buff$"] = false,
		["^conjure_mana_gem$"] = "ConjureManaGem()",
		["^mana_gem$"] = "UseManaGem()",
		["^frost_armor$"] = function(simc, action)
				tinsert(simc.symbols, "frost_armor_buff")
				return "if BuffExpires(frost_armor_buff) Spell(frost_armor)"
			end,
		["^icy_veins$"] = "IcyVeins()",
		["^molten_armor$"] = function(simc, action)
				tinsert(simc.symbols, "molten_armor_buff")
				return "if BuffExpires(molten_armor_buff) Spell(molten_armor)"
			end,
		["^water_elemental$"] = "if pet.Present(no) Spell(water_elemental)",
		-- Monk
		["^chi_sphere$"] = false,
		-- Paladin
		["^hammer_of_wrath$"] = "Spell(hammer_of_wrath usable=1)",
		["^rebuke$"] = "Interrupt()",
		["^seal_of_"] = function(simc, action) return format("if not Stance(paladin_%s) Spell(%s)", action, action) end,
		-- Priest
		["^inner_fire$"] = function(simc, action)
				tinsert(simc.symbols, "inner_fire_buff")
				return "if BuffExpires(inner_fire_buff) Spell(inner_fire)"
			end,
		["^mind_flay_insanity$"] = function(simc, action)
				tinsert(simc.symbols, "mind_flay")
				return "Spell(mind_flay)"
			end,
		["^shadowform$"] = "if not Stance(priest_shadowform) Spell(shadowform)",
		["^shadow_word_death$"] = "Spell(shadow_word_death usable=1)",
		-- Rogue
		["^ambush$"] = "Spell(ambush usable=1)",
		["^apply_poison$"] = "ApplyPoisons()",
		["^backstab$"] = "Spell(backstab usable=1)",
		["^dispatch$"] = "Spell(dispatch usable=1)",
		["^kick$"] = "if target.IsInterruptible() Spell(kick)",
		["^premeditation$"] = "Spell(premeditation usable=1)",
		["^stealth$"] = "if not IsStealthed() Spell(stealth)",
		["^tricks_of_the_trade$"] = "TricksOfTheTrade()",
		-- Shaman
		["^bloodlust$"] = "Bloodlust()",
		["^wind_shear$"] = "Interrupt()",
		-- Warlock
		["^service_pet$"] = "ServicePet()",
	}

	local scriptLine = {}

	function OvaleSimulationCraft:ParseActionLine(script, actionLine)
		wipe(scriptLine)
		if self.simcComments then
			self:Append(script, "#%s", actionLine.line)
		end

		local action = self:Name(gsub(actionLine.action, ":", "_"))
		local matchedAction = false
		for pattern, result in pairs(SIMC_ACTION) do
			if strmatch(action, pattern) then
				matchedAction = true
				scriptLine.action = (type(result) == "function") and result(self, action) or result
				break
			end
		end
		if not matchedAction then
			scriptLine.action = format("Spell(%s)", action)
		end

		if scriptLine.action then
			local addActionSymbol = false
			if #actionLine == 0 then
				addActionSymbol = true
			else
				for i, expr in ipairs(actionLine) do
					local name, value = NameValuePair(expr)
					if action == "use_item" then
						scriptLine.action = "UseItemActions()"
						--[[
						if name == "slot" then
							if value == "hands" then
								scriptLine.action = "Item(HandsSlot usable=1)"
							elseif value == "trinket" then
								scriptLine.action = "{ Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) }"
							end
						elseif name == "name" then
							if strmatch(value, "gauntlets") or strmatch(value, "gloves") or strmatch(value, "grips") or strmatch(value, "handguards") then
								scriptLine.action = "Item(HandsSlot usable=1)"
							end
						end
						]]--
					elseif action == "wait" then
						if name == "sec" then
							if type(value) == "number" then
								scriptLine.action = nil
							else
								local spellName = strmatch(value, "^cooldown%.([%w_]+)%.remains$")
								if spellName then
									scriptLine.action = format("wait Spell(%s)", spellName)
								end
							end
						end
					elseif action == "swap_action_list" then
						if name == "name" then
							scriptLine.action = format("%s()", self:FunctionName(value))
						end
					elseif action == "run_action_list" then
						if name == "name" then
							scriptLine.action = format("%s()", self:FunctionName(value))
						end
					elseif action == "pool_resource" then
						scriptLine.action = nil
						if name == "for_next" and value == 1 then
							script.for_next = true
						end
					elseif action == "stance" then
						-- Don't add symbol for "stance".
					else
						addActionSymbol = true
					end
					if name == "if" then
						scriptLine.if_expr = self:ParseExpression(action, value, addActionSymbol)
					else
						scriptLine[name] = value
					end
				end
			end
			if addActionSymbol then
				tinsert(self.symbols, action)
			end

			if scriptLine.if_expr
				or scriptLine.moving == 1
				or scriptLine.sync
				or action == "focus_fire" and scriptLine.five_stacks == 1
				or action == "grimoire_of_sacrifice"
				or action == "kill_command"
				or action == "mind_flay_insanity"
				or action == "stance" and scriptLine.choose
				or scriptLine.weapon
				or scriptLine.max_cycle_targets
			then
				local needAnd = false
				if action == "pool_resource" and not script.for_next then
					tinsert(scriptLine, "unless")
				else
					tinsert(scriptLine, "if")
				end
				if scriptLine.moving == 1 then
					tinsert(scriptLine, "Speed() > 0")
					needAnd = true
				end
				if scriptLine.sync then
					if needAnd then
						tinsert(scriptLine, "and")
					end
					tinsert(scriptLine, format("Spell(%s)", scriptLine.sync))
					needAnd = true
				end
				if scriptLine.weapon then
					if needAnd then
						tinsert(scriptLine, "and")
					end
					tinsert(scriptLine, format("WeaponEnchantExpires(%s)", scriptLine.weapon))
					needAnd = true
				end
				if action == "focus_fire" and scriptLine.five_stacks == 1 then
					if needAnd then
						tinsert(scriptLine, "and")
					end
					tinsert(scriptLine, "BuffStacks(frenzy_buff any=1) == 5")
					needAnd = true
				elseif action == "grimoire_of_sacrifice" then
					if needAnd then
						tinsert(scriptLine, "and")
					end
					tinsert(scriptLine, "pet.Present()")
					needAnd = true
				elseif action == "kill_command" then
					if needAnd then
						tinsert(scriptLine, "and")
					end
					tinsert(scriptLine, "pet.Present()")
					needAnd = true
				elseif action == "mind_flay_insanity" then
					if needAnd then
						tinsert(scriptLine, "and")
					end
					tinsert(scriptLine, "TalentPoints(solace_and_insanity_talent) and target.DebuffPresent(devouring_plague_debuff)")
					tinsert(self.symbols, "solace_and_insanity_talent")
					tinsert(self.symbols, "devouring_plague_debuff")
					needAnd = true
				elseif action == "stance" and scriptLine.choose then
					if needAnd then
						tinsert(scriptLine, "and")
					end
					local class = self.profile.class
					if class == "deathknight" then
						local spellName = format("%s_presence", scriptLine.choose)
						scriptLine.action = format("Spell(%s)", spellName)
						tinsert(scriptLine, format("not Stance(%s_%s)", class, spellName))
					elseif class == "monk" then
						local spellName = format("stance_of_the_%s", scriptLine.choose)
						scriptLine.action = format("Spell(%s)", spellName)
						tinsert(scriptLine, format("not Stance(%s_%s)", class, spellName))
					elseif class == "warrior" then
						local spellName = format("%s_stance", scriptLine.choose)
						scriptLine.action = format("Spell(%s)", spellName)
						tinsert(scriptLine, format("not Stance(%s_%s)", class, spellName))
					else
						tinsert(scriptLine, format("not Stance(%s_%s)", class, scriptLine.choose))
					end
					needAnd = true
				end
				if scriptLine.if_expr then
					if needAnd then
						tinsert(scriptLine, "and")
					end
					if needAnd and strmatch(scriptLine.if_expr, " or ") then
						tinsert(scriptLine, format("{ %s }", scriptLine.if_expr))
					else
						tinsert(scriptLine, scriptLine.if_expr)
					end
					needAnd = true
				end
				if scriptLine.max_cycle_targets then
					if needAnd then
						tinsert(scriptLine, "and")
					end
					tinsert(scriptLine, format("DebuffCountOnAny(%s_debuff) <= %d", action, scriptLine.max_cycle_targets))
					needAnd = true
				end
			end

			if action ~= "pool_resource" then
				if script.for_next then
					tinsert(scriptLine, "wait")
					script.for_next = nil
				end
				tinsert(scriptLine, scriptLine.action)
			end

			if scriptLine[1] then
				self:Append(script, tconcat(scriptLine, " "))
			end
			if action == "pool_resource" and not script.for_next then
				self:Append(script, "{")
				self:Indent()
			end
		end
	end
end

do
	-- Table of matching tokens for SimC conditional expressions for OvaleLexer.scan().
	local MATCHES = {}
	local function chdump(tok, options)
		if options and options.string then
			tok = strsub(tok, 2, -2)
		end
		return yield("char", tok)
	end

	local function ndump(tok, options)
		if options and options.number then
			tok = tonumber(tok)
		end
		return yield("number", tok)
	end

	local function tdump(tok)
		return yield(tok, tok)
	end

	local function vdump(tok)
		return yield("iden", tok)
	end

	local function wsdump(tok)
		return yield("space", tok)
	end

	-- whitespace
	tinsert(MATCHES, { '^%s+', wsdump })
	-- numbers
	tinsert(MATCHES, { '^[%-]?%d+%.?%d*', ndump })
	-- floor/ceil
	tinsert(MATCHES, { '^floor', tdump })
	tinsert(MATCHES, { '^ceil', tdump })
	-- identifiers (foo.bar.baz.etc)
	tinsert(MATCHES, { '^[%a_][%w_%.]*[%w_]', vdump })
	-- not-equal
	tinsert(MATCHES, { '^!=', tdump })
	-- less-than-equal
	tinsert(MATCHES, { '^<=', tdump })
	-- greater-than-equal
	tinsert(MATCHES, { '^>=', tdump })
	-- exclusion
	tinsert(MATCHES, { '^!~', tdump })
	-- catch-all
	tinsert(MATCHES, { '^.', tdump })

	--[[
		The "buff" list also contains special buffs such as:
			"bleeding" (target is bleeding),
			"casting" (character is casting),
			"raid_movement" (character is moving because of a "movement" raid event),
			"poisoned" (target is poisoned),
			"self_movement" (character is moving because of a start_move action),
			"stunned" (character is stunned),
			"vulnerable" (target is vulnerable),
			"stealthed" (character is stealthed).
	--]]
	local SPECIAL_PROPERTY = {
		["^debuff%.casting%.react$"] = "IsInterruptible()",
		["^debuff%.flying%.down$"] = "True(not flying_debuff)",
		["^buff%.raid_movement%.duration$"] = "0",
		-- Pretend the target can never be invulnerable.
		["^debuff%.invulnerable%.react$"] = "InCombat(no)",
		["^buff%.bloodlust%.react$"] = "BuffPresent(burst_haste any=1)",
		["^buff%.bloodlust%.up$"] = "BuffPresent(burst_haste any=1)",
		["^buff%.bloodlust%.down$"] = "BuffExpires(burst_haste any=1)",
		["^buff%.stealthed%.down$"] = "Stealthed(no)",
		["^buff%.stealthed%.up$"] = "Stealthed()",
		["^debuff%.weakened_armor%.stack$"] = function(simc, action)
				tinsert(simc.symbols, "weakened_armor_debuff")
				return "target.DebuffStacks(weakened_armor_debuff any=1)"
			end,
		["^buff%.vicious%.react$"] = function(simc, action)
				tinsert(simc.symbols, "trinket_proc_agility_buff")
				return "BuffPresent(trinket_proc_agility_buff)"
			end,
		["^buff%.vicious%.remains$"] = function(simc, action)
				tinsert(simc.symbols, "trinket_proc_agility_buff")
				return "BuffRemains(trinket_proc_agility_buff)"
			end,
		-- Druid
		["^buff%.wild_mushroom%.max_stack$"] = function(simc, action)
				local class, spec = simc.profile.class, simc.profile.spec
				if class == "druid" and spec == "restoration" then
					return "1"
				end
				return "3"
			end,
		["^buff%.wild_mushroom%.stack$"] = "WildMushroomCount()",
		-- Hunter
		["^debuff%.ranged_vulnerability%.up$"] = "target.DebuffPresent(ranged_vulnerability any=1)",
		["^buff%.beast_cleave$.down$"] = function(simc, action)
				tinsert(simc.symbols, "pet_beast_cleave_buff")
				return "pet.BuffExpires(pet_beast_cleave_buff any=1)"
			end,
		-- Mage
		["^buff%.arcane_charge%.stack$"] = function(simc, action)
				tinsert(simc.symbols, "arcane_charge_debuff")
				return "DebuffStacks(arcane_charge_debuff)"
			end,
		["^buff%.rune_of_power%.remains$"] = "RuneOfPowerRemains()",
		["^cooldown%.icy_veins%.remains$"] = "IcyVeinsCooldownRemains()",
		-- Monk
		["^dot%.zen_sphere%.ticking$"] = function(simc, action)
				tinsert(simc.symbols, "zen_sphere_buff")
				return "BuffPresent(zen_sphere_buff)"
			end,
		-- Priest
		["^buff%.surge_of_darkness%.react$"] = function(simc, action)
				tinsert(simc.symbols, "surge_of_darkness_buff")
				return "BuffStacks(surge_of_darkness_buff)"
			end,
		["^dot%.devouring_plague_tick%.ticks_remain$"] = function(simc, action)
				tinsert(simc.symbols, "devouring_plague_debuff")
				return "TicksRemain(devouring_plague_debuff)"
			end,
		-- Rogue
		["^buff%.stealth%.down$"] = "Stealthed(no)",
		["^buff%.stealth%.up$"] = "Stealthed()",
		-- Shaman
		["^active_flame_shock$"] = function(simc, action)
				tinsert(simc.symbols, "flame_shock_debuff")
				return "DebuffCountOnAny(flame_shock_debuff)"
			end,
		["^buff%.lightning_shield%.max_stack$"] = "7",
		["^buff%.lightning_shield%.react$"] = function(simc, action)
				tinsert(simc.symbols, "lightning_shield_buff")
				return "BuffStacks(lightning_shield_buff)"
			end,
		["^pet%.greater_fire_elemental%.active$"] = "TotemPresent(fire totem=fire_elemental_totem)",
		["^pet%.primal_fire_elemental%.active$"] = "TotemPresent(fire totem=fire_elemental_totem)",
		-- Warlock
		["^buff%.havoc%.remains$"] = function(simc, action)
				tinsert(simc.symbols, "havoc_debuff")
				return "DebuffRemainsOnAny(havoc_debuff)"
			end,
		["^buff%.havoc%.stack$"] = function(simc, action)
				tinsert(simc.symbols, "havoc_debuff")
				return "DebuffStacksOnAny(havoc_debuff)"
			end,
		["^debuff%.magic_vulnerability%.down$"] = "target.DebuffExpires(magic_vulnerability any=1)",
		["^debuff%.magic_vulnerability%.up$"] = "target.DebuffPresent(magic_vulnerability any=1)",
	}

	-- totem.<totem_name>.<totem_property>
	local TOTEM_TYPE = {
		["capacitor_totem"] = "air",
		["earth_elemental_totem"] = "earth",
		["earthbind_totem"] = "earth",
		["earthgrab_totem"] = "earth",
		["fire_elemental_totem"] = "fire",
		["grounding_totem"] = "air",
		["healing_stream_totem"] = "water",
		["healing_tide_totem"] = "water",
		["magma_totem"] = "fire",
		["mana_tide_totem"] = "water",
		["searing_totem"] = "fire",
		["stone_bulwark_totem"] = "earth",
		["stormlash_totem"] = "air",
		["tremor_totem"] = "earth",
		["windwalk_totem"] = "air",
	}
	local TOTEM_PROPERTY_PATTERN = "^totem%.([%w_]+)%.([%w_]+)$"
	local TOTEM_PROPERTY = {
		["^active$"] = function(simc, totemName)
				if TOTEM_TYPE[totemName] then
					return format("TotemPresent(%s totem=%s)", TOTEM_TYPE[totemName], totemName)
				else
					return format("TotemPresent(%s)", totemName)
				end
			end,
		["^remains$"] = function(simc, totemName)
				if TOTEM_TYPE[totemName] then
					return format("TotemRemains(%s totem=%s)", TOTEM_TYPE[totemName], totemName)
				else
					return format("TotemRemains(%s)", totemName)
				end
			end,
	}

	local ACTION_PROPERTY_PATTERN = "^action%.([%w_]+)%.([%w_]+)$"
	local ACTION_PROPERTY = {
		-- TODO: Buff?
		["^active$"] = function(simc, actionName)
				if strmatch(actionName, "_totem$") then
					return TOTEM_PROPERTY["^active$"](simc, actionName)
				else
					local symbol = format("%s_debuff", actionName)
					tinsert(simc.symbols, symbol)
					return format("target.DebuffPresent(%s)", symbol)
				end
			end,
		["^add_ticks$"] = function(simc, actionName)
				local symbol = format("%s_debuff", actionName)
				tinsert(simc.symbols, symbol)
				return format("TicksAdded(%s)", symbol)
			end,
		["^ember_react$"] = "BurningEmbers() >= 10",
		["^cast_delay$"] = "True(cast_delay)",
		["^cast_time$"] = function(simc, actionName) return format("CastTime(%s)", actionName) end,
		["^charges$"] = function(simc, actionName) return format("Charges(%s)", actionName) end,
		-- TODO: ItemCooldown?
		["^cooldown$"] = function(simc, actionName) return format("SpellCooldown(%s)", actionName) end,
		-- TODO: Item?
		["^cooldown_react$"] = function(simc, actionName) return format("Spell(%s)", actionName) end,
		["^crit_damage$"] = function(simc, actionName) return format("target.CritDamage(%s)", actionName) end,
		-- TODO: Melee/Ranged/Spell crit chance depending on type of attack, or at least class of player.
		["^crit_pct_current$"] = function(simc, actionName) return format("SpellCritChance()", actionName) end,
		["^crit_tick_damage$"] = function(simc, actionName)
				local symbol = format("%s_debuff", actionName)
				tinsert(simc.symbols, symbol)
				return format("target.CritDamage(%s)", symbol)
			end,
		["^duration$"] = function(simc, actionName)
				local symbol = format("%s_debuff", actionName)
				tinsert(simc.symbols, symbol)
				return format("SpellData(%s duration)", symbol)
			end,
		["^enabled$"] = function(simc, actionName)
				local symbol = format("%s_talent", actionName)
				tinsert(simc.symbols, symbol)
				return format("TalentPoints(%s)", symbol)
			end,
		["^gcd$"] = function(simc, actionName) return format("GCD()", actionName) end,
		["^hit_damage$"] = function(simc, actionName) return format("target.Damage(%s)", actionName) end,
		["^in_flight$"] = function(simc, actionName) return format("InFlightToTarget(%s)", actionName) end,
		["^in_flight_to_target$"] = function(simc, actionName) return format("InFlightToTarget(%s)", actionName) end,
		["^miss_react$"] = "True(miss_react)",
		-- TODO: Buff?
		["^n_ticks$"] = function(simc, actionName)
				local symbol = format("%s_debuff", actionName)
				tinsert(simc.symbols, symbol)
				return format("target.Ticks(%s)", symbol)
			end,
		["^recharge_time$"] = function(simc, actionName) return format("SpellChargeCooldown(%s)", actionName) end,
		-- TODO: Buff?
		["^remains$"] = function(simc, actionName)
				if strmatch(actionName, "_totem$") then
					return TOTEM_PROPERTY["^remains$"](simc, actionName)
				else
					local symbol = format("%s_debuff", actionName)
					tinsert(simc.symbols, symbol)
					return format("target.DebuffRemains(%s)", symbol)
				end
			end,
		["^shard_react$"] = "SoulShards() >= 1",
		["^spell_power$"] = function(simc, actionName)
				local symbol = format("%s_debuff", actionName)
				tinsert(simc.symbols, symbol)
				return format("target.DebuffSpellpower(%s)", symbol)
			end,
		-- TODO: Buff?
		["^tick_damage$"] = function(simc, actionName)
				local symbol = format("%s_debuff", actionName)
				tinsert(simc.symbols, symbol)
				return format("target.Damage(%s)", symbol)
			end,
		["^tick_multiplier$"] = function(simc, actionName) return format("target.DamageMultiplier(%s)", actionName) end,
		-- TODO: Buff?
		["^tick_time$"] = function(simc, actionName)
				local symbol = format("%s_debuff", actionName)
				tinsert(simc.symbols, symbol)
				return format("target.TickTime(%s)", symbol)
			end,
		-- TODO: Buff?
		["^ticking$"] = function(simc, actionName)
				local symbol = format("%s_debuff", actionName)
				tinsert(simc.symbols, symbol)
				return format("target.DebuffPresent(%s)", symbol)
			end,
		-- TODO: Buff?
		["^ticks_remain$"] = function(simc, actionName)
				local symbol = format("%s_debuff", actionName)
				tinsert(simc.symbols, symbol)
				return format("target.TicksRemain(%s)", symbol)
			end,
		-- TODO: Assume travel time of a spell is always 0.5s.
		["^travel_time$"] = function(simc, actionName) return "0.5" end,
	}

	local CHARACTER_PROPERTY = {
		["^anticipation_charges"] = function(simc, pattern, token)
				tinsert(simc.symbols, "anticipation_buff")
				return "BuffStacks(anticipation_buff)"
			end,
		["^burning_ember$"] = "BurningEmbers() / 10",
		["^chi$"] = "Chi()",
		["^chi%.max$"] = "MaxChi()",
		["^combo_points$"] = "ComboPoints()",
		["^demonic_fury$"] = "DemonicFury()",
		["^eclipse$"] = "Eclipse()",
		["^eclipse_dir$"] = "EclipseDir()",
		["^energy$"] = "Energy()",
		["^energy%.regen$"] = "EnergyRegen()",
		["^energy%.time_to_max$"] = "TimeToMaxEnergy()",
		["^focus$"] = "Focus()",
		["^focus%.regen$"] = "FocusRegen()",
		["^focus%.time_to_max$"] = "TimeToMaxFocus()",
		["^health$"] = "Health()",
		["^health%.deficit$"] = "HealthMissing()",
		["^health%.max$"] = "MaxHealth()",
		["^health%.pct$"] = "HealthPercent()",
		["^holy_power$"] = "HolyPower()",
		["^incoming_damage_([%d]+)(m?s)$"] = function(simc, pattern, token)
				local seconds, measure = strmatch(token, pattern)
				seconds = tonumber(seconds)
				if measure == "ms" then
					seconds = seconds / 1000
				end
				return format("IncomingDamage(%.3f)", seconds)
			end,
		["^in_combat$"] = "InCombat()",
		["^level$"] = "Level()",
		["^mana$"] = "Mana()",
		["^mana%.deficit$"] = "ManaDeficit()",
		["^mana%.max$"] = "MaxMana()",
		["^mana%.max_nonproc$"] = "MaxMana()",
		["^mana%.pct$"] = "ManaPercent()",
		["^mana%.pct_nonproc$"] = "ManaPercent()",
		["^mana_gem_charges$"] = function(simc, pattern, token)
				tinsert(simc.symbols, "mana_gem")
				return "ItemCharges(mana_gem)"
			end,
		["^mastery_value$"] = "MasteryEffect() / 100",
		["^multiplier$"] = "DamageMultiplier()",
		["^position_front$"] = "False(position_front)",	-- XXX
		["^rage$"] = "Rage()",
		["^rage%.max$"] = "MaxRage()",
		["^runic_power$"] = "RunicPower()",
		["^shadow_orb$"] = "ShadowOrbs()",
		["^soul_shards$"] = "SoulShards()",
		["^stat%.agility$"] = "Agility()",
		["^stat%.attack_power$"] = "AttackPower()",
		["^stat%.crit$"] = "CritRating()",
		["^stat%.crit_rating$"] = "CritRating()",
		["^stat%.energy$"] = "Energy()",
		["^stat%.focus$"] = "Focus()",
		["^stat%.haste_rating$"] = "HasteRating()",
		["^stat%.health$"] = "Health()",
		["^stat%.intellect$"] = "Intellect()",
		["^stat%.mana$"] = "Mana()",
		["^stat%.mastery_rating$"] = "MasteryRating()",
		["^stat%.maximum_energy$"] = "MaxEnergy()",
		["^stat%.maximum_focus$"] = "MaxFocus()",
		["^stat%.maximum_health$"] = "MaxHealth()",
		["^stat%.maximum_mana$"] = "MaxMana()",
		["^stat%.maximum_runic$"] = "MaxRunicPower()",
		["^stat%.rage$"] = "Rage()",
		["^stat%.runic$"] = "RunicPower()",
		["^stat%.spell_power$"] = "Spellpower()",
		["^stat%.spirit$"] = "Spirit()",
		["^stat%.stamina$"] = "Stamina()",
		["^stat%.strength$"] = "Strength()",
		["^time_to_die$"] = "TimeToDie()",
	}

	-- aura.<aura_name>.<aura_property>
	local AURA_PROPERTY_PATTERN = "^aura%.([%w_]+)%.([%w_]+)$"
	local AURA_PROPERTY = {
		["^down$"] = function(simc, name) return format("BuffExpires(%s any=1)", name) end,
		["^stack$"] = function(simc, name) return format("BuffStacks(%s any=1)", name) end,
		["^react$"] = function(simc, name) return format("BuffPresent(%s any=1)", name) end,
		["^remains$"] = function(simc, name) return format("BuffRemains(%s any=1)", name) end,
		["^up$"] = function(simc, name) return format("BuffPresent(%s any=1)", name) end,
	}

	-- (buff|debuff).<aura_name>.<aura_property>
	local function BuffType(buffType) return (buffType == "debuff") and "Debuff" or "Buff" end
	local BUFF_PROPERTY_PATTERN = "^(d?e?buff)%.([%w_]+)%.([%w_]+)$"
	local BUFF_PROPERTY = {
		-- XXX: Assume that the spell and the buff have the same name.
		["^cooldown_remains$"] = function(simc, buffType, name) return format("SpellCooldown(%s)", name) end,
		["^down$"] = function(simc, buffType, name) return format("%sExpires(%s_%s)", BuffType(buffType), name, buffType) end,
		["^duration$"] = function(simc, buffType, name) return format("SpellData(%s_%s duration)", name, buffType) end,
		["^stack$"] = function(simc, buffType, name) return format("%sStacks(%s_%s)", BuffType(buffType), name, buffType) end,
		-- "react" is supposed to be a stack count, but it's used in almost every script as "up".
		["^react$"] = function(simc, buffType, name) return format("%sPresent(%s_%s)", BuffType(buffType), name, buffType) end,
		["^remains$"] = function(simc, buffType, name) return format("%sRemains(%s_%s)", BuffType(buffType), name, buffType) end,
		["^up$"] = function(simc, buffType, name) return format("%sPresent(%s_%s)", BuffType(buffType), name, buffType) end,
		["^value$"] = function(simc, buffType, name) return format("%sAmount(%s_%s)", BuffType(buffType), name, buffType) end,
	}

	-- cooldown.<spell_name>.<cooldown_property>
	local COOLDOWN_PROPERTY_PATTERN = "^cooldown%.([%w_]+)%.([%w_]+)$"
	local COOLDOWN_PROPERTY = {
		-- TODO: ItemCooldown?
		["^remains$"] = function(simc, spellName) return format("SpellCooldown(%s)", spellName) end,
	}

	-- dot.<dot_name>.<dot_property>
	local DOT_PROPERTY_PATTERN = "^dot%.([%w_]+)%.([%w_]+)$"
	local DOT_HELPFUL = {
		["sacred_shield"] = true,
	}
	local function DotBuffName(dotName) return DOT_HELPFUL[dotName] and "Buff" or "Debuff" end
	local function DotBuffSuffix(dotName) return DOT_HELPFUL[dotName] and "buff" or "debuff" end
	local DOT_PROPERTY = {
		["^attack_power$"] = function(simc, dotName) return format("%sAttackPower(%s_%s)", DotBuffName(dotName), dotName, DotBuffSuffix(dotName)) end,
		["^crit_pct$"] = function(simc, dotName) return format("%sSpellCritChance(%s_%s)", DotBuffName(dotName), dotName, DotBuffSuffix(dotName)) end,
		["^duration$"] = function(simc, dotName) return format("%sDuration(%s_%s)", DotBuffName(dotName), dotName, DotBuffSuffix(dotName)) end,
		["^multiplier$"] = function(simc, dotName) return format("%sDamageMultiplier(%s_%s)", DotBuffName(dotName), dotName, DotBuffSuffix(dotName)) end,
		["^remains$"] = function(simc, dotName) return format("%sRemains(%s_%s)", DotBuffName(dotName), dotName, DotBuffSuffix(dotName)) end,
		["^spell_power$"] = function(simc, dotName) return format("%sSpellpower(%s_%s)", DotBuffName(dotName), dotName, DotBuffSuffix(dotName)) end,
		-- TODO: Should really implement BuffDamage() that's akin to Damage/LastEstimatedDamage.
		["^tick_dmg$"] = function(simc, dotName) return format("LastEstimatedDamage(%s_%s)", dotName, DotBuffSuffix(dotName)) end,
		["^ticking$"] = function(simc, dotName) return format("%sPresent(%s_%s)", DotBuffName(dotName), dotName, DotBuffSuffix(dotName)) end,
		["^ticks$"] = function(simc, dotName) return format("Ticks(%s_%s)", dotName, DotBuffSuffix(dotName)) end,
		["^ticks_remain$"] = function(simc, dotName) return format("TicksRemain(%s_%s)", dotName, DotBuffSuffix(dotName)) end,
	}

	-- talent.<talent_name>.<talent_property>
	local TALENT_PROPERTY_PATTERN = "^talent%.([%w_]+)%.([%w_]+)$"
	local TALENT_PROPERTY = {
		["^enabled$"] = function(simc, talentName) return format("TalentPoints(%s_talent)", talentName) end,
		["^disabled$"] = function(simc, talentName) return format("not TalentPoints(%s_talent)", talentName) end,
	}

	-- glyph.<glyph_name>.<glyph_property>
	local GLYPH_PROPERTY_PATTERN = "^glyph%.([%w_]+)%.([%w_]+)$"
	local GLYPH_PROPERTY = {
		["^enabled$"] = function(simc, glyphName) return format("Glyph(glyph_of_%s)", glyphName) end,
		["^disabled$"] = function(simc, glyphName) return format("not Glyph(glyph_of_%s)", glyphName) end,
	}

	-- trinket.<proc_type>.<stat>.<trinket_property>
	local TRINKET_PROPERTY_PATTERN = "^trinket%.([%w_]+)%.([%w_]+)%.([%w_]+)$"
	local TRINKET_PROPERTY = {
		["^cooldown_remains"] = function(simc, procType, statName) return ("{ ItemCooldown(Trinket0Slot) + ItemCooldown(Trinket1Slot) }") end,
		["^down$"] = function(simc, procType, statName) return format("BuffPresent(trinket_%s_%s_buff)", procType, statName) end,
		["^react$"] = function(simc, procType, statName)
				if strfind(procType, "stacking") then
					return format("BuffStacks(trinket_%s_%s_buff)", procType, statName)
				end
				return format("BuffPresent(trinket_%s_%s_buff)", procType, statName)
			end,
		["^remains$"] = function(simc, procType, statName) return format("BuffRemains(trinket_%s_%s_buff)", procType, statName) end,
		["^stack$"] = function(simc, procType, statName) return format("BuffStacks(trinket_%s_%s_buff)", procType, statName) end,
		["^up$"] = function(simc, procType, statName) return format("BuffPresent(trinket_%s_%s_buff)", procType, statName) end,
	}

	local GENERAL_PROPERTY = {
		["^active_enemies$"] = "Enemies()",
		["^adds$"] = "Enemies()",
		["^ptr$"] = "PTR()",
		["^time$"] = "TimeInCombat()",
		["^time_to_bloodlust$"] = "TimeToBloodlust()",
	}

	local TRANSLATED_TOKEN = {
		["^!$"] = "not",
		["^!=$"] = "!=",
		["^!~$"] = "!~",
		["^%%$"] = "/",
		["^%($"] = "{",
		["^%)$"] = "}",
		["^%*$"] = "*",
		["^%+$"] = "+",
		["^&$"] = "and",
		["^-$"] = "-",
		["^<$"] = "<",
		["^<=$"] = "<=",
		["^=$"] = "==",
		["^>$"] = ">",
		["^>=$"] = ">=",
		["^|$"] = "or",
		["^~$"] = "~",
	}

	function OvaleSimulationCraft:ParseExpression(action, expr, addActionSymbol)
		local translatedList = {}
		local tokenIterator = OvaleLexer.scan(expr, MATCHES)
		local tokenType, token = tokenIterator()
		while tokenType do
			local translated
			if tokenType == "iden" then
				-- Strip off "target." if present.
				local isTargetFound = strmatch(token, "^target%.([%w_%.]+)")
				if isTargetFound then
					token = isTargetFound
				end
				if not translated then
					-- Handle properties that have a special interpretation.
					for pattern, result in pairs(SPECIAL_PROPERTY) do
						if strmatch(token, pattern) then
							translated = (type(result) == "function") and result(self, action) or result
							break
						end
					end
				end
				if not translated then
					-- Bare action properties.
					if addActionSymbol then
						tinsert(self.symbols, action)
					end
					for pattern, result in pairs(ACTION_PROPERTY) do
						if strmatch(token, pattern) then
							translated = (type(result) == "function") and result(self, action) or result
							break
						end
					end
				end
				if not translated then
					-- Action properties for actions other than the one for this action line.
					local name, property = strmatch(token, ACTION_PROPERTY_PATTERN)
					if name then
						name = self:Name(name)
						tinsert(self.symbols, name)
						for pattern, result in pairs(ACTION_PROPERTY) do
							if strmatch(property, pattern) then
								translated = (type(result) == "function") and result(self, name) or result
								break
							end
						end
					end
				end
				if not translated then
					for pattern, result in pairs(CHARACTER_PROPERTY) do
						if strmatch(token, pattern) then
							translated = (type(result) == "function") and result(self, pattern, token) or result
							break
						end
					end
				end
				if not translated then
					local name, property = strmatch(token, AURA_PROPERTY_PATTERN)
					if name then
						name = self:Name(name)
						tinsert(self.symbols, name)
						for pattern, result in pairs(AURA_PROPERTY) do
							if strmatch(property, pattern) then
								translated = (type(result) == "function") and result(self, name) or result
								break
							end
						end
					end
				end
				if not translated then
					local buffType, name, property = strmatch(token, BUFF_PROPERTY_PATTERN)
					if buffType then
						if buffType == "debuff" then
							-- Debuffs default to checking on the target.
							isTargetFound = true
						end
						name = self:Name(name)
						tinsert(self.symbols, format("%s_%s", name, buffType))
						for pattern, result in pairs(BUFF_PROPERTY) do
							if strmatch(property, pattern) then
								translated = (type(result) == "function") and result(self, buffType, name) or result
								break
							end
						end
					end
				end
				if not translated then
					local name, property = strmatch(token, TOTEM_PROPERTY_PATTERN)
					if name then
						name = self:Name(name)
						if TOTEM_TYPE[name] then
							tinsert(self.symbols, name)
						end
						for pattern, result in pairs(TOTEM_PROPERTY) do
							if strmatch(property, pattern) then
								translated = (type(result) == "function") and result(self, name) or result
								break
							end
						end
					end
				end
				if not translated then
					local name, property = strmatch(token, COOLDOWN_PROPERTY_PATTERN)
					if name then
						name = self:Name(name)
						tinsert(self.symbols, name)
						for pattern, result in pairs(COOLDOWN_PROPERTY) do
							if strmatch(property, pattern) then
								translated = (type(result) == "function") and result(self, name) or result
								break
							end
						end
					end
				end
				if not translated then
					local name, property = strmatch(token, TALENT_PROPERTY_PATTERN)
					if name then
						tinsert(self.symbols, format("%s_talent", name))
						for pattern, result in pairs(TALENT_PROPERTY) do
							if strmatch(property, pattern) then
								translated = (type(result) == "function") and result(self, name) or result
								break
							end
						end
					end
				end
				if not translated then
					local name, property = strmatch(token, GLYPH_PROPERTY_PATTERN)
					if name then
						tinsert(self.symbols, format("glyph_of_%s", name))
						for pattern, result in pairs(GLYPH_PROPERTY) do
							if strmatch(property, pattern) then
								translated = (type(result) == "function") and result(self, name) or result
								break
							end
						end
					end
				end
				if not translated then
					local name, property = strmatch(token, DOT_PROPERTY_PATTERN)
					if name then
						-- DoTs default to checking on the target.
						isTargetFound = true
						name = self:Name(name)
						tinsert(self.symbols, format("%s_%s", name, DotBuffSuffix(name)))
						for pattern, result in pairs(DOT_PROPERTY) do
							if strmatch(property, pattern) then
								translated = (type(result) == "function") and result(self, name) or result
								break
							end
						end
					end
				end
				if not translated then
					local procType, name, property = strmatch(token, TRINKET_PROPERTY_PATTERN)
					if procType then
						tinsert(self.symbols, format("trinket_%s_%s_buff", procType, name))
						for pattern, result in pairs(TRINKET_PROPERTY) do
							if strmatch(property, pattern) then
								translated = (type(result) == "function") and result(self, procType, name) or result
								break
							end
						end
					end
				end
				if not translated then
					-- set_bonus.<set_name>_<N>pc_<role>
					local name, count, role = strmatch(token, "^set_bonus%.(%w+)_(%d+)pc_(%w+)$")
					if name and count and role then
						local tierLevel = strmatch(name, "^tier(%d+)")
						if tierLevel then
							name = format("T%s", tierLevel)
						end
						translated = format("ArmorSetBonus(%s_%s %s)", name, role, count)
					end
				end
				if not translated then
					for pattern, result in pairs(GENERAL_PROPERTY) do
						if strmatch(token, pattern) then
							translated = (type(result) == "function") and result(self, action) or result
							break
						end
					end
				end
				if not translated then
					translated = format("FIXME_%s", token)
				end
				if isTargetFound then
					translated = "target." .. translated
				end
			elseif tokenType == "number" then
				translated = token
			end
			if not translated then
				for pattern, result in pairs(TRANSLATED_TOKEN) do
					if strmatch(token, pattern) then
						translated = (type(result) == "function") and result(self, token) or result
						break
					end
				end
			end
			if not translated then
				translated = format("FIXME_%s", token)
			end
			tinsert(translatedList, translated)
			tokenType, token = tokenIterator()
		end
		local translation = tconcat(translatedList, " ")
		return translation
	end
end
--</public-static-methods>
