--[[--------------------------------------------------------------------
    Copyright (C) 2011, 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleEquipment = Ovale:NewModule("OvaleEquipment", "AceEvent-3.0")
Ovale.OvaleEquipment = OvaleEquipment

--<private-static-properties>
local OvaleProfiler = Ovale.OvaleProfiler

local pairs = pairs
local select = select
local strgsub = string.gsub
local strmatch = string.match
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack
local wipe = wipe

local API_CreateFrame = CreateFrame
local API_GetAuctionItemSubClasses = GetAuctionItemSubClasses
local API_GetInventoryItemID = GetInventoryItemID
local API_GetInventoryItemGems = GetInventoryItemGems
local API_GetItemInfo = GetItemInfo
local INVSLOT_AMMO = INVSLOT_AMMO
local INVSLOT_BACK = INVSLOT_BACK
local INVSLOT_BODY = INVSLOT_BODY
local INVSLOT_CHEST = INVSLOT_CHEST
local INVSLOT_FEET = INVSLOT_FEET
local INVSLOT_FINGER1 = INVSLOT_FINGER1
local INVSLOT_FINGER2 = INVSLOT_FINGER2
local INVSLOT_FIRST_EQUIPPED = INVSLOT_FIRST_EQUIPPED
local INVSLOT_HAND = INVSLOT_HAND
local INVSLOT_HEAD = INVSLOT_HEAD
local INVSLOT_LAST_EQUIPPED = INVSLOT_LAST_EQUIPPED
local INVSLOT_LEGS = INVSLOT_LEGS
local INVSLOT_MAINHAND = INVSLOT_MAINHAND
local INVSLOT_NECK = INVSLOT_NECK
local INVSLOT_OFFHAND = INVSLOT_OFFHAND
local INVSLOT_RANGED = INVSLOT_RANGED
local INVSLOT_SHOULDER = INVSLOT_SHOULDER
local INVSLOT_TABARD = INVSLOT_TABARD
local INVSLOT_TRINKET1 = INVSLOT_TRINKET1
local INVSLOT_TRINKET2 = INVSLOT_TRINKET2
local INVSLOT_WAIST = INVSLOT_WAIST
local INVSLOT_WRIST = INVSLOT_WRIST
-- GLOBALS: _G
-- GLOBALS: UIParent

-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleEquipment)

-- Frame for tooltip-scanning.
local self_tooltip = nil
local OVALE_ITEM_LEVEL_PATTERN = "^" .. strgsub(ITEM_LEVEL, "%%d", "(%%d+)")

-- equipment slot names
local OVALE_SLOTNAME = {
	AmmoSlot = INVSLOT_AMMO,
	BackSlot = INVSLOT_BACK,
	ChestSlot = INVSLOT_CHEST,
	FeetSlot = INVSLOT_FEET,
	Finger0Slot = INVSLOT_FINGER1,
	Finger1Slot = INVSLOT_FINGER2,
	HandsSlot = INVSLOT_HAND,
	HeadSlot = INVSLOT_HEAD,
	LegsSlot = INVSLOT_LEGS,
	MainHandSlot = INVSLOT_MAINHAND,
	NeckSlot = INVSLOT_NECK,
	SecondaryHandSlot = INVSLOT_OFFHAND,
	ShirtSlot = INVSLOT_BODY,
	ShoulderSlot = INVSLOT_SHOULDER,
	TabardSlot = INVSLOT_TABARD,
	Trinket0Slot = INVSLOT_TRINKET1,
	Trinket1Slot = INVSLOT_TRINKET2,
	WaistSlot = INVSLOT_WAIST,
	WristSlot = INVSLOT_WRIST,
}
-- slots that can contain pieces from armor sets
local OVALE_ARMORSET_SLOT_IDS = { INVSLOT_CHEST, INVSLOT_HAND, INVSLOT_HEAD, INVSLOT_LEGS, INVSLOT_SHOULDER, INVSLOT_BACK }
-- database of armor set items: OVALE_ARMORSET[itemId] = armorSetName
local OVALE_ARMORSET = {
	-- Death Knight
	[ 85314] = "T14_tank",	[ 85315] = "T14_tank",	[ 85316] = "T14_tank",	[ 85317] = "T14_tank",	[ 85318] = "T14_tank",
	[ 86654] = "T14_tank",	[ 86655] = "T14_tank",	[ 86656] = "T14_tank",	[ 86657] = "T14_tank",	[ 86658] = "T14_tank",
	[ 86918] = "T14_tank",	[ 86919] = "T14_tank",	[ 86920] = "T14_tank",	[ 86921] = "T14_tank",	[ 86922] = "T14_tank",
	[ 95225] = "T15_melee",	[ 95226] = "T15_melee",	[ 95227] = "T15_melee",	[ 95228] = "T15_melee",	[ 95229] = "T15_melee",
	[ 95230] = "T15_tank",	[ 95231] = "T15_tank",	[ 95232] = "T15_tank",	[ 95233] = "T15_tank",	[ 95234] = "T15_tank",
	[ 95825] = "T15_melee",	[ 95826] = "T15_melee",	[ 95827] = "T15_melee",	[ 95828] = "T15_melee",	[ 95829] = "T15_melee",
	[ 95830] = "T15_tank",	[ 95831] = "T15_tank",	[ 95832] = "T15_tank",	[ 95833] = "T15_tank",	[ 95834] = "T15_tank",
	[ 96569] = "T15_melee",	[ 96570] = "T15_melee",	[ 96571] = "T15_melee",	[ 96572] = "T15_melee",	[ 96573] = "T15_melee",
	[ 96574] = "T15_tank",	[ 96575] = "T15_tank",	[ 96576] = "T15_tank",	[ 96577] = "T15_tank",	[ 96578] = "T15_tank",
	[ 99039] = "T16_tank",	[ 99040] = "T16_tank",	[ 99048] = "T16_tank",	[ 99049] = "T16_tank",	[ 99060] = "T16_tank",
	[ 99057] = "T16_melee",	[ 99058] = "T16_melee",	[ 99059] = "T16_melee",	[ 99066] = "T16_melee",	[ 99067] = "T16_melee",
	[ 99179] = "T16_tank",	[ 99188] = "T16_tank",	[ 99189] = "T16_tank",	[ 99190] = "T16_tank",	[ 99191] = "T16_tank",
	[ 99186] = "T16_melee",	[ 99187] = "T16_melee",	[ 99192] = "T16_melee",	[ 99193] = "T16_melee",	[ 99194] = "T16_melee",
	[ 99323] = "T16_tank",	[ 99324] = "T16_tank",	[ 99325] = "T16_tank",	[ 99330] = "T16_tank",	[ 99331] = "T16_tank",
	[ 99335] = "T16_melee",	[ 99336] = "T16_melee",	[ 99337] = "T16_melee",	[ 99338] = "T16_melee",	[ 99339] = "T16_melee",
	[ 99564] = "T16_tank",	[ 99604] = "T16_tank",	[ 99605] = "T16_tank",	[ 99640] = "T16_tank",	[ 99652] = "T16_tank",
	[ 99571] = "T16_melee",	[ 99572] = "T16_melee",	[ 99608] = "T16_melee",	[ 99609] = "T16_melee",	[ 99639] = "T16_melee",
	[115535] = "T17",		[115536] = "T17",		[115537] = "T17",		[115538] = "T17",		[115539] = "T17",
	[124317] = "T18",		[124327] = "T18",		[124332] = "T18",		[124338] = "T18",		[124344] = "T18",
	[138349] = "T19",		[138352] = "T19",		[138355] = "T19",		[138358] = "T19",		[138361] = "T19",		[138364] = "T19",
	-- Demon Huner
	[138376] = "T19",		[138377] = "T19",		[138378] = "T19",		[138379] = "T19",		[138380] = "T19",		[138375] = "T19",
	-- Druid
	[ 85304] = "T14_caster",[ 85305] = "T14_caster",[ 85306] = "T14_caster",[ 85307] = "T14_caster",[ 85308] = "T14_caster",
	[ 85309] = "T14_melee",	[ 85310] = "T14_melee",	[ 85311] = "T14_melee",	[ 85312] = "T14_melee",	[ 85313] = "T14_melee",
	[ 85354] = "T14_heal",	[ 85355] = "T14_heal",	[ 85356] = "T14_heal",	[ 85357] = "T14_heal",	[ 85358] = "T14_heal",
	[ 85379] = "T14_tank",	[ 85380] = "T14_tank",	[ 85381] = "T14_tank",	[ 85382] = "T14_tank",	[ 85383] = "T14_tank",
	[ 86644] = "T14_caster",[ 86645] = "T14_caster",[ 86646] = "T14_caster",[ 86647] = "T14_caster",[ 86648] = "T14_caster",
	[ 86649] = "T14_melee",	[ 86650] = "T14_melee",	[ 86651] = "T14_melee",	[ 86652] = "T14_melee",	[ 86653] = "T14_melee",
	[ 86694] = "T14_heal",	[ 86695] = "T14_heal",	[ 86696] = "T14_heal",	[ 86697] = "T14_heal",	[ 86698] = "T14_heal",
	[ 86719] = "T14_tank",	[ 86720] = "T14_tank",	[ 86721] = "T14_tank",	[ 86722] = "T14_tank",	[ 86723] = "T14_tank",
	[ 86923] = "T14_melee",	[ 86924] = "T14_melee",	[ 86925] = "T14_melee",	[ 86926] = "T14_melee",	[ 86927] = "T14_melee",
	[ 86928] = "T14_heal",	[ 86929] = "T14_heal",	[ 86930] = "T14_heal",	[ 86931] = "T14_heal",	[ 86932] = "T14_heal",
	[ 86933] = "T14_caster",[ 86934] = "T14_caster",[ 86935] = "T14_caster",[ 86936] = "T14_caster",[ 86937] = "T14_caster",
	[ 86938] = "T14_tank",	[ 86939] = "T14_tank",	[ 86940] = "T14_tank",	[ 86941] = "T14_tank",	[ 86942] = "T14_tank",
	[ 95235] = "T15_melee",	[ 95236] = "T15_melee",	[ 95237] = "T15_melee",	[ 95238] = "T15_melee",	[ 95239] = "T15_melee",
	[ 95245] = "T15_caster",[ 95246] = "T15_caster",[ 95247] = "T15_caster",[ 95248] = "T15_caster",[ 95249] = "T15_caster",
	[ 95250] = "T15_tank",	[ 95251] = "T15_tank",	[ 95252] = "T15_tank",	[ 95253] = "T15_tank",	[ 95254] = "T15_tank",
	[ 95835] = "T15_melee",	[ 95836] = "T15_melee",	[ 95837] = "T15_melee",	[ 95838] = "T15_melee",	[ 95839] = "T15_melee",
	[ 95845] = "T15_caster",[ 95846] = "T15_caster",[ 95847] = "T15_caster",[ 95848] = "T15_caster",[ 95849] = "T15_caster",
	[ 95850] = "T15_tank",	[ 95851] = "T15_tank",	[ 95852] = "T15_tank",	[ 95853] = "T15_tank",	[ 95854] = "T15_tank",
	[ 96579] = "T15_melee",	[ 96580] = "T15_melee",	[ 96581] = "T15_melee",	[ 96582] = "T15_melee",	[ 96583] = "T15_melee",
	[ 96589] = "T15_caster",[ 96590] = "T15_caster",[ 96591] = "T15_caster",[ 96592] = "T15_caster",[ 96593] = "T15_caster",
	[ 96594] = "T15_tank",	[ 96595] = "T15_tank",	[ 96596] = "T15_tank",	[ 96597] = "T15_tank",	[ 96598] = "T15_tank",
	[ 98978] = "T16_tank",	[ 98981] = "T16_tank",	[ 98999] = "T16_tank",	[ 99000] = "T16_tank",	[ 99001] = "T16_tank",
	[ 98994] = "T16_caster",[ 98995] = "T16_caster",[ 98996] = "T16_caster",[ 98997] = "T16_caster",[ 98998] = "T16_caster",
	[ 99012] = "T16_heal",	[ 99013] = "T16_heal",	[ 99014] = "T16_heal",	[ 99015] = "T16_heal",	[ 99016] = "T16_heal",
	[ 99022] = "T16_melee",	[ 99041] = "T16_melee",	[ 99042] = "T16_melee",	[ 99043] = "T16_melee",	[ 99044] = "T16_melee",
	[ 99163] = "T16_tank",	[ 99164] = "T16_tank",	[ 99165] = "T16_tank",	[ 99166] = "T16_tank",	[ 99170] = "T16_tank",
	[ 99169] = "T16_caster",[ 99174] = "T16_caster",[ 99175] = "T16_caster",[ 99176] = "T16_caster",[ 99177] = "T16_caster",
	[ 99171] = "T16_heal",	[ 99172] = "T16_heal",	[ 99173] = "T16_heal",	[ 99178] = "T16_heal",	[ 99185] = "T16_heal",
	[ 99180] = "T16_melee",	[ 99181] = "T16_melee",	[ 99182] = "T16_melee",	[ 99183] = "T16_melee",	[ 99184] = "T16_melee",
	[ 99322] = "T16_melee",	[ 99326] = "T16_melee",	[ 99327] = "T16_melee",	[ 99328] = "T16_melee",	[ 99329] = "T16_melee",
	[ 99419] = "T16_tank",	[ 99420] = "T16_tank",	[ 99421] = "T16_tank",	[ 99422] = "T16_tank",	[ 99423] = "T16_tank",
	[ 99427] = "T16_caster",[ 99428] = "T16_caster",[ 99432] = "T16_caster",[ 99433] = "T16_caster",[ 99434] = "T16_caster",
	[ 99429] = "T16_heal",	[ 99430] = "T16_heal",	[ 99431] = "T16_heal",	[ 99435] = "T16_heal",	[ 99436] = "T16_heal",
	[ 99581] = "T16_heal",	[ 99582] = "T16_heal",	[ 99583] = "T16_heal",	[ 99637] = "T16_heal",	[ 99638] = "T16_heal",
	[ 99589] = "T16_melee",	[ 99599] = "T16_melee",	[ 99600] = "T16_melee",	[ 99632] = "T16_melee",	[ 99633] = "T16_melee",
	[ 99610] = "T16_tank",	[ 99622] = "T16_tank",	[ 99623] = "T16_tank",	[ 99624] = "T16_tank",	[ 99664] = "T16_tank",
	[ 99617] = "T16_caster",[ 99618] = "T16_caster",[ 99619] = "T16_caster",[ 99620] = "T16_caster",[ 99621] = "T16_caster",
	[115540] = "T17",		[115541] = "T17",		[115542] = "T17",		[115543] = "T17",		[115544] = "T17",
	[124246] = "T18",		[124255] = "T18",		[124261] = "T18",		[124267] = "T18",		[124272] = "T18",
	[138324] = "T19",		[138327] = "T19",		[138330] = "T19",		[138333] = "T19",		[138336] = "T19",		[138366] = "T19",
	-- Hunter
	[ 85294] = "T14_melee",	[ 85295] = "T14_melee",	[ 85296] = "T14_melee",	[ 85297] = "T14_melee",	[ 85298] = "T14_melee",
	[ 86634] = "T14_melee",	[ 86635] = "T14_melee",	[ 86636] = "T14_melee",	[ 86637] = "T14_melee",	[ 86638] = "T14_melee",
	[ 87002] = "T14_melee",	[ 87003] = "T14_melee",	[ 87004] = "T14_melee",	[ 87005] = "T14_melee",	[ 87006] = "T14_melee",
	[ 95255] = "T15_melee",	[ 95256] = "T15_melee",	[ 95257] = "T15_melee",	[ 95258] = "T15_melee",	[ 95259] = "T15_melee",
	[ 95882] = "T15_melee",	[ 95883] = "T15_melee",	[ 95884] = "T15_melee",	[ 95885] = "T15_melee",	[ 95886] = "T15_melee",
	[ 96626] = "T15_melee",	[ 96627] = "T15_melee",	[ 96628] = "T15_melee",	[ 96629] = "T15_melee",	[ 96630] = "T15_melee",
	[ 99080] = "T16_melee",	[ 99081] = "T16_melee",	[ 99082] = "T16_melee",	[ 99085] = "T16_melee",	[ 99086] = "T16_melee",
	[ 99157] = "T16_melee",	[ 99158] = "T16_melee",	[ 99159] = "T16_melee",	[ 99167] = "T16_melee",	[ 99168] = "T16_melee",
	[ 99402] = "T16_melee",	[ 99403] = "T16_melee",	[ 99404] = "T16_melee",	[ 99405] = "T16_melee",	[ 99406] = "T16_melee",
	[ 99573] = "T16_melee",	[ 99574] = "T16_melee",	[ 99577] = "T16_melee",	[ 99578] = "T16_melee",	[ 99660] = "T16_melee",
	[115545] = "T17",		[115546] = "T17",		[115547] = "T17",		[115548] = "T17",		[115549] = "T17",
	[124284] = "T18",		[124292] = "T18",		[124296] = "T18",		[124301] = "T18",		[124307] = "T18",
	[138339] = "T19",		[138340] = "T19",		[138342] = "T19",		[138344] = "T19",		[138347] = "T19",		[138368] = "T19",
	-- Mage
	[ 85374] = "T14_caster",[ 85375] = "T14_caster",[ 85376] = "T14_caster",[ 85377] = "T14_caster",[ 85378] = "T14_caster",
	[ 86714] = "T14_caster",[ 86715] = "T14_caster",[ 86716] = "T14_caster",[ 86717] = "T14_caster",[ 86718] = "T14_caster",
	[ 87007] = "T14_caster",[ 87008] = "T14_caster",[ 87009] = "T14_caster",[ 87010] = "T14_caster",[ 87011] = "T14_caster",
	[ 95260] = "T15_caster",[ 95261] = "T15_caster",[ 95262] = "T15_caster",[ 95263] = "T15_caster",[ 95264] = "T15_caster",
	[ 95890] = "T15_caster",[ 95891] = "T15_caster",[ 95892] = "T15_caster",[ 95893] = "T15_caster",[ 95894] = "T15_caster",
	[ 96634] = "T15_caster",[ 96635] = "T15_caster",[ 96636] = "T15_caster",[ 96637] = "T15_caster",[ 96638] = "T15_caster",
	[ 99077] = "T16_caster",[ 99078] = "T16_caster",[ 99079] = "T16_caster",[ 99083] = "T16_caster",[ 99084] = "T16_caster",
	[ 99152] = "T16_caster",[ 99153] = "T16_caster",[ 99160] = "T16_caster",[ 99161] = "T16_caster",[ 99162] = "T16_caster",
	[ 99397] = "T16_caster",[ 99398] = "T16_caster",[ 99399] = "T16_caster",[ 99400] = "T16_caster",[ 99401] = "T16_caster",
	[ 99575] = "T16_caster",[ 99576] = "T16_caster",[ 99657] = "T16_caster",[ 99658] = "T16_caster",[ 99659] = "T16_caster",
	[115550] = "T17",		[115551] = "T17",		[115552] = "T17",		[115553] = "T17",		[115554] = "T17",
	[124154] = "T18",		[124160] = "T18",		[124165] = "T18",		[124171] = "T18",		[124177] = "T18",
	[138318] = "T19",		[138309] = "T19",		[138312] = "T19",		[138315] = "T19",		[138321] = "T19",		[138365] = "T19",
	-- Monk
	[ 85394] = "T14_melee",	[ 85395] = "T14_melee",	[ 85396] = "T14_melee",	[ 85397] = "T14_melee",	[ 85398] = "T14_melee",
	[ 86734] = "T14_melee",	[ 86735] = "T14_melee",	[ 86736] = "T14_melee",	[ 86737] = "T14_melee",	[ 86738] = "T14_melee",
	[ 87084] = "T14_melee",	[ 87085] = "T14_melee",	[ 87086] = "T14_melee",	[ 87087] = "T14_melee",	[ 87088] = "T14_melee",
	[ 95270] = "T15_heal",	[ 95271] = "T15_heal",	[ 95272] = "T15_heal",	[ 95273] = "T15_heal",	[ 95274] = "T15_heal",
	[ 95275] = "T15_tank",	[ 95276] = "T15_tank",	[ 95277] = "T15_tank",	[ 95278] = "T15_tank",	[ 95279] = "T15_tank",
	[ 95900] = "T15_heal",	[ 95901] = "T15_heal",	[ 95902] = "T15_heal",	[ 95903] = "T15_heal",	[ 95904] = "T15_heal",
	[ 95905] = "T15_tank",	[ 95906] = "T15_tank",	[ 95907] = "T15_tank",	[ 95908] = "T15_tank",	[ 95909] = "T15_tank",
	[ 96644] = "T15_heal",	[ 96645] = "T15_heal",	[ 96646] = "T15_heal",	[ 96647] = "T15_heal",	[ 96648] = "T15_heal",
	[ 96649] = "T15_tank",	[ 96650] = "T15_tank",	[ 96651] = "T15_tank",	[ 96652] = "T15_tank",	[ 96653] = "T15_tank",
	[ 99050] = "T16_tank",	[ 99051] = "T16_tank",	[ 99063] = "T16_tank",	[ 99064] = "T16_tank",	[ 99065] = "T16_tank",
	[ 99061] = "T16_heal",	[ 99062] = "T16_heal",	[ 99068] = "T16_heal",	[ 99069] = "T16_heal",	[ 99070] = "T16_heal",
	[ 99071] = "T16_melee",	[ 99072] = "T16_melee",	[ 99073] = "T16_melee",	[ 99074] = "T16_melee",	[ 99075] = "T16_melee",
	[ 99140] = "T16_tank",	[ 99141] = "T16_tank",	[ 99142] = "T16_tank",	[ 99143] = "T16_tank",	[ 99144] = "T16_tank",
	[ 99145] = "T16_melee",	[ 99146] = "T16_melee",	[ 99154] = "T16_melee",	[ 99155] = "T16_melee",	[ 99156] = "T16_melee",
	[ 99147] = "T16_heal",	[ 99148] = "T16_heal",	[ 99149] = "T16_heal",	[ 99150] = "T16_heal",	[ 99151] = "T16_heal",
	[ 99381] = "T16_heal",	[ 99388] = "T16_heal",	[ 99389] = "T16_heal",	[ 99390] = "T16_heal",	[ 99391] = "T16_heal",
	[ 99382] = "T16_tank",	[ 99383] = "T16_tank",	[ 99384] = "T16_tank",	[ 99385] = "T16_tank",	[ 99386] = "T16_tank",
	[ 99392] = "T16_melee",	[ 99393] = "T16_melee",	[ 99394] = "T16_melee",	[ 99395] = "T16_melee",	[ 99396] = "T16_melee",
	[ 99552] = "T16_heal",	[ 99553] = "T16_heal",	[ 99554] = "T16_heal",	[ 99641] = "T16_heal",	[ 99642] = "T16_heal",
	[ 99555] = "T16_melee",	[ 99556] = "T16_melee",	[ 99653] = "T16_melee",	[ 99654] = "T16_melee",	[ 99655] = "T16_melee",
	[ 99565] = "T16_tank",	[ 99606] = "T16_tank",	[ 99607] = "T16_tank",	[ 99643] = "T16_tank",	[ 99644] = "T16_tank",
	[115555] = "T17",		[115556] = "T17",		[115557] = "T17",		[115558] = "T17",		[115559] = "T17",
	[124247] = "T18",		[124256] = "T18",		[124262] = "T18",		[124268] = "T18",		[124276] = "T18",
	[138325] = "T19",		[138328] = "T19",		[138331] = "T19",		[138334] = "T19",		[138337] = "T19",		[138367] = "T19",
	-- Paladin
	[ 85319] = "T14_tank",	[ 85320] = "T14_tank",	[ 85321] = "T14_tank",	[ 85322] = "T14_tank",	[ 85323] = "T14_tank",
	[ 85339] = "T14_melee",	[ 85340] = "T14_melee",	[ 85341] = "T14_melee",	[ 85342] = "T14_melee",	[ 85343] = "T14_melee",
	[ 85344] = "T14_heal",	[ 85345] = "T14_heal",	[ 85346] = "T14_heal",	[ 85347] = "T14_heal",	[ 85348] = "T14_heal",
	[ 86659] = "T14_tank",	[ 86660] = "T14_tank",	[ 86661] = "T14_tank",	[ 86662] = "T14_tank",	[ 86663] = "T14_tank",
	[ 86679] = "T14_melee",	[ 86680] = "T14_melee",	[ 86681] = "T14_melee",	[ 86682] = "T14_melee",	[ 86683] = "T14_melee",
	[ 86684] = "T14_heal",	[ 86685] = "T14_heal",	[ 86686] = "T14_heal",	[ 86687] = "T14_heal",	[ 86688] = "T14_heal",
	[ 87099] = "T14_melee",	[ 87100] = "T14_melee",	[ 87101] = "T14_melee",	[ 87102] = "T14_melee",	[ 87103] = "T14_melee",
	[ 87104] = "T14_heal",	[ 87105] = "T14_heal",	[ 87106] = "T14_heal",	[ 87107] = "T14_heal",	[ 87108] = "T14_heal",
	[ 87109] = "T14_tank",	[ 87110] = "T14_tank",	[ 87111] = "T14_tank",	[ 87112] = "T14_tank",	[ 87113] = "T14_tank",
	[ 95280] = "T15_melee",	[ 95281] = "T15_melee",	[ 95282] = "T15_melee",	[ 95283] = "T15_melee",	[ 95284] = "T15_melee",
	[ 95290] = "T15_tank",	[ 95291] = "T15_tank",	[ 95292] = "T15_tank",	[ 95293] = "T15_tank",	[ 95294] = "T15_tank",
	[ 95910] = "T15_melee",	[ 95911] = "T15_melee",	[ 95912] = "T15_melee",	[ 95913] = "T15_melee",	[ 95914] = "T15_melee",
	[ 95920] = "T15_tank",	[ 95921] = "T15_tank",	[ 95922] = "T15_tank",	[ 95923] = "T15_tank",	[ 95924] = "T15_tank",
	[ 96654] = "T15_melee",	[ 96655] = "T15_melee",	[ 96656] = "T15_melee",	[ 96657] = "T15_melee",	[ 96658] = "T15_melee",
	[ 96664] = "T15_tank",	[ 96665] = "T15_tank",	[ 96666] = "T15_tank",	[ 96667] = "T15_tank",	[ 96668] = "T15_tank",
	[ 98979] = "T16_heal",	[ 98980] = "T16_heal",	[ 98982] = "T16_heal",	[ 99003] = "T16_heal",	[ 99076] = "T16_heal",
	[ 98985] = "T16_melee",	[ 98986] = "T16_melee",	[ 98987] = "T16_melee",	[ 99002] = "T16_melee",	[ 99052] = "T16_melee",
	[ 99026] = "T16_tank",	[ 99027] = "T16_tank",	[ 99028] = "T16_tank",	[ 99029] = "T16_tank",	[ 99031] = "T16_tank",
	[ 99124] = "T16_heal",	[ 99125] = "T16_heal",	[ 99133] = "T16_heal",	[ 99134] = "T16_heal",	[ 99135] = "T16_heal",
	[ 99126] = "T16_tank",	[ 99127] = "T16_tank",	[ 99128] = "T16_tank",	[ 99129] = "T16_tank",	[ 99130] = "T16_tank",
	[ 99132] = "T16_melee",	[ 99136] = "T16_melee",	[ 99137] = "T16_melee",	[ 99138] = "T16_melee",	[ 99139] = "T16_melee",
	[ 99364] = "T16_tank",	[ 99368] = "T16_tank",	[ 99369] = "T16_tank",	[ 99370] = "T16_tank",	[ 99371] = "T16_tank",
	[ 99372] = "T16_melee",	[ 99373] = "T16_melee",	[ 99379] = "T16_melee",	[ 99380] = "T16_melee",	[ 99387] = "T16_melee",
	[ 99374] = "T16_heal",	[ 99375] = "T16_heal",	[ 99376] = "T16_heal",	[ 99377] = "T16_heal",	[ 99378] = "T16_heal",
	[ 99566] = "T16_melee",	[ 99625] = "T16_melee",	[ 99651] = "T16_melee",	[ 99661] = "T16_melee",	[ 99662] = "T16_melee",
	[ 99593] = "T16_tank",	[ 99594] = "T16_tank",	[ 99595] = "T16_tank",	[ 99596] = "T16_tank",	[ 99598] = "T16_tank",
	[ 99626] = "T16_heal",	[ 99648] = "T16_heal",	[ 99656] = "T16_heal",	[ 99665] = "T16_heal",	[ 99666] = "T16_heal",
	[115565] = "T17",		[115566] = "T17",		[115567] = "T17",		[115568] = "T17",		[115569] = "T17",
	[124318] = "T18",		[124328] = "T18",		[124333] = "T18",		[124339] = "T18",		[124345] = "T18",
	[138350] = "T19",		[138353] = "T19",		[138356] = "T19",		[138359] = "T19",		[138362] = "T19",		[138369] = "T19",
	-- Priest
	[ 85359] = "T14_heal",	[ 85360] = "T14_heal",	[ 85361] = "T14_heal",	[ 85362] = "T14_heal",	[ 85363] = "T14_heal",
	[ 85364] = "T14_caster",[ 85365] = "T14_caster",[ 85366] = "T14_caster",[ 85367] = "T14_caster",[ 85368] = "T14_caster",
	[ 86699] = "T14_heal",	[ 86700] = "T14_heal",	[ 86701] = "T14_heal",	[ 86702] = "T14_heal",	[ 86703] = "T14_heal",
	[ 86704] = "T14_caster",[ 86705] = "T14_caster",[ 86706] = "T14_caster",[ 86707] = "T14_caster",[ 86708] = "T14_caster",
	[ 87114] = "T14_heal",	[ 87115] = "T14_heal",	[ 87116] = "T14_heal",	[ 87117] = "T14_heal",	[ 87118] = "T14_heal",
	[ 87119] = "T14_caster",[ 87120] = "T14_caster",[ 87121] = "T14_caster",[ 87122] = "T14_caster",[ 87123] = "T14_caster",
	[ 99004] = "T16_caster",[ 99005] = "T16_caster",[ 99019] = "T16_caster",[ 99020] = "T16_caster",[ 99021] = "T16_caster",
	[ 99017] = "T16_heal",	[ 99018] = "T16_heal",	[ 99023] = "T16_heal",	[ 99024] = "T16_heal",	[ 99025] = "T16_heal",
	[ 99110] = "T16_caster",[ 99111] = "T16_caster",[ 99121] = "T16_caster",[ 99122] = "T16_caster",[ 99123] = "T16_caster",
	[ 99117] = "T16_heal",	[ 99118] = "T16_heal",	[ 99119] = "T16_heal",	[ 99120] = "T16_heal",	[ 99131] = "T16_heal",
	[ 99357] = "T16_heal",	[ 99358] = "T16_heal",	[ 99365] = "T16_heal",	[ 99366] = "T16_heal",	[ 99367] = "T16_heal",
	[ 99359] = "T16_caster",[ 99360] = "T16_caster",[ 99361] = "T16_caster",[ 99362] = "T16_caster",[ 99363] = "T16_caster",
	[ 99584] = "T16_heal",	[ 99585] = "T16_heal",	[ 99590] = "T16_heal",	[ 99591] = "T16_heal",	[ 99592] = "T16_heal",
	[ 99586] = "T16_caster",[ 99587] = "T16_caster",[ 99588] = "T16_caster",[ 99627] = "T16_caster",[ 99628] = "T16_caster",
	[115560] = "T17",		[115561] = "T17",		[115562] = "T17",		[115563] = "T17",		[115564] = "T17",
	[124155] = "T18",		[124161] = "T18",		[124166] = "T18",		[124172] = "T18",		[124178] = "T18",
	[138319] = "T19",		[138310] = "T19",		[138313] = "T19",		[138316] = "T19",		[138322] = "T19",		[138370] = "T19",
	-- Rogue
	[ 85299] = "T14_melee",	[ 85300] = "T14_melee",	[ 85301] = "T14_melee",	[ 85302] = "T14_melee",	[ 85303] = "T14_melee",
	[ 86639] = "T14_melee",	[ 86640] = "T14_melee",	[ 86641] = "T14_melee",	[ 86642] = "T14_melee",	[ 86643] = "T14_melee",
	[ 87124] = "T14_melee",	[ 87125] = "T14_melee",	[ 87126] = "T14_melee",	[ 87127] = "T14_melee",	[ 87128] = "T14_melee",
	[ 95305] = "T15_melee",	[ 95306] = "T15_melee",	[ 95307] = "T15_melee",	[ 95308] = "T15_melee",	[ 95309] = "T15_melee",
	[ 95935] = "T15_melee",	[ 95936] = "T15_melee",	[ 95937] = "T15_melee",	[ 95938] = "T15_melee",	[ 95939] = "T15_melee",
	[ 96679] = "T15_melee",	[ 96680] = "T15_melee",	[ 96681] = "T15_melee",	[ 96682] = "T15_melee",	[ 96683] = "T15_melee",
	[ 99006] = "T16_melee",	[ 99007] = "T16_melee",	[ 99008] = "T16_melee",	[ 99009] = "T16_melee",	[ 99010] = "T16_melee",
	[ 99112] = "T16_melee",	[ 99113] = "T16_melee",	[ 99114] = "T16_melee",	[ 99115] = "T16_melee",	[ 99116] = "T16_melee",
	[ 99348] = "T16_melee",	[ 99349] = "T16_melee",	[ 99350] = "T16_melee",	[ 99355] = "T16_melee",	[ 99356] = "T16_melee",
	[ 99629] = "T16_melee",	[ 99630] = "T16_melee",	[ 99631] = "T16_melee",	[ 99634] = "T16_melee",	[ 99635] = "T16_melee",
	[115570] = "T17",		[115571] = "T17",		[115572] = "T17",		[115573] = "T17",		[115574] = "T17",
	[124248] = "T18",		[124257] = "T18",		[124263] = "T18",		[124269] = "T18",		[124274] = "T18",
	[138326] = "T19",		[138329] = "T19",		[138332] = "T19",		[138335] = "T19",		[138338] = "T19",		[138371] = "T19",
	-- Shaman
	[ 95315] = "T15_melee",	[ 95316] = "T15_melee",	[ 95317] = "T15_melee",	[ 95318] = "T15_melee",	[ 95319] = "T15_melee",
	[ 95320] = "T15_caster",[ 95321] = "T15_caster",[ 95322] = "T15_caster",[ 95323] = "T15_caster",[ 95324] = "T15_caster",
	[ 95945] = "T15_melee",	[ 95946] = "T15_melee",	[ 95947] = "T15_melee",	[ 95948] = "T15_melee",	[ 95949] = "T15_melee",
	[ 95950] = "T15_caster",[ 95951] = "T15_caster",[ 95952] = "T15_caster",[ 95953] = "T15_caster",[ 95954] = "T15_caster",
	[ 96689] = "T15_melee",	[ 96690] = "T15_melee",	[ 96691] = "T15_melee",	[ 96692] = "T15_melee",	[ 96693] = "T15_melee",
	[ 96694] = "T15_caster",[ 96695] = "T15_caster",[ 96696] = "T15_caster",[ 96697] = "T15_caster",[ 96698] = "T15_caster",
	[ 98922] = "T16_melee",	[ 98977] = "T16_melee",	[ 98983] = "T16_melee",	[ 98984] = "T16_melee",	[ 98993] = "T16_melee",
	[ 98988] = "T16_heal",	[ 98989] = "T16_heal",	[ 98990] = "T16_heal",	[ 98991] = "T16_heal",	[ 99011] = "T16_heal",
	[ 99087] = "T16_caster",[ 99088] = "T16_caster",[ 99089] = "T16_caster",[ 99090] = "T16_caster",[ 99091] = "T16_caster",
	[ 99092] = "T16_caster",[ 99093] = "T16_caster",[ 99094] = "T16_caster",[ 99095] = "T16_caster",[ 99106] = "T16_caster",
	[ 99099] = "T16_heal",	[ 99100] = "T16_heal",	[ 99107] = "T16_heal",	[ 99108] = "T16_heal",	[ 99109] = "T16_heal",
	[ 99101] = "T16_melee",	[ 99102] = "T16_melee",	[ 99103] = "T16_melee",	[ 99104] = "T16_melee",	[ 99105] = "T16_melee",
	[ 99332] = "T16_caster",[ 99333] = "T16_caster",[ 99334] = "T16_caster",[ 99344] = "T16_caster",[ 99345] = "T16_caster",
	[ 99340] = "T16_melee",	[ 99341] = "T16_melee",	[ 99342] = "T16_melee",	[ 99343] = "T16_melee",	[ 99347] = "T16_melee",
	[ 99346] = "T16_heal",	[ 99351] = "T16_heal",	[ 99352] = "T16_heal",	[ 99353] = "T16_heal",	[ 99354] = "T16_heal",
	[ 99579] = "T16_caster",[ 99580] = "T16_caster",[ 99645] = "T16_caster",[ 99646] = "T16_caster",[ 99647] = "T16_caster",
	[ 99611] = "T16_heal",	[ 99612] = "T16_heal",	[ 99613] = "T16_heal",	[ 99614] = "T16_heal",	[ 99636] = "T16_heal",
	[ 99615] = "T16_melee",	[ 99616] = "T16_melee",	[ 99649] = "T16_melee",	[ 99650] = "T16_melee",	[ 99663] = "T16_melee",
	[115575] = "T17",		[115576] = "T17",		[115577] = "T17",		[115578] = "T17",		[115579] = "T17",
	[124293] = "T18",		[124297] = "T18",		[124302] = "T18",		[124303] = "T18",		[124308] = "T18",
	[138346] = "T19",		[138341] = "T19",		[138343] = "T19",		[138345] = "T19",		[138348] = "T19",		[138372] = "T19",
	--Warlock
	[ 85369] = "T14_caster",[ 85370] = "T14_caster",[ 85371] = "T14_caster",[ 85372] = "T14_caster",[ 85373] = "T14_caster",
	[ 86709] = "T14_caster",[ 86710] = "T14_caster",[ 86711] = "T14_caster",[ 86712] = "T14_caster",[ 86713] = "T14_caster",
	[ 87187] = "T14_caster",[ 87188] = "T14_caster",[ 87189] = "T14_caster",[ 87190] = "T14_caster",[ 87191] = "T14_caster",
	[ 95325] = "T15_caster",[ 95326] = "T15_caster",[ 95327] = "T15_caster",[ 95328] = "T15_caster",[ 95329] = "T15_caster",
	[ 95981] = "T15_caster",[ 95982] = "T15_caster",[ 95983] = "T15_caster",[ 95984] = "T15_caster",[ 95985] = "T15_caster",
	[ 96725] = "T15_caster",[ 96726] = "T15_caster",[ 96727] = "T15_caster",[ 96728] = "T15_caster",[ 96729] = "T15_caster",
	[ 99045] = "T16_caster",[ 99053] = "T16_caster",[ 99054] = "T16_caster",[ 99055] = "T16_caster",[ 99056] = "T16_caster",
	[ 99096] = "T16_caster",[ 99097] = "T16_caster",[ 99098] = "T16_caster",[ 99204] = "T16_caster",[ 99205] = "T16_caster",
	[ 99416] = "T16_caster",[ 99417] = "T16_caster",[ 99424] = "T16_caster",[ 99425] = "T16_caster",[ 99426] = "T16_caster",
	[ 99567] = "T16_caster",[ 99568] = "T16_caster",[ 99569] = "T16_caster",[ 99570] = "T16_caster",[ 99601] = "T16_caster",
	[115585] = "T17",		[115586] = "T17",		[115587] = "T17",		[115588] = "T17",		[115589] = "T17",
	[124156] = "T18",		[124162] = "T18",		[124167] = "T18",		[124173] = "T18",		[124179] = "T18",
	[138320] = "T19",		[138311] = "T19",		[138314] = "T19",		[138317] = "T19",		[138323] = "T19",		[138373] = "T19",
	-- Warrior
	[ 85324] = "T14_tank",	[ 85325] = "T14_tank",	[ 85326] = "T14_tank",	[ 85327] = "T14_tank",	[ 85328] = "T14_tank",
	[ 85329] = "T14_melee",	[ 85330] = "T14_melee",	[ 85331] = "T14_melee",	[ 85332] = "T14_melee",	[ 85333] = "T14_melee",
	[ 86664] = "T14_tank",	[ 86665] = "T14_tank",	[ 86666] = "T14_tank",	[ 86667] = "T14_tank",	[ 86668] = "T14_tank",
	[ 86669] = "T14_melee",	[ 86670] = "T14_melee",	[ 86671] = "T14_melee",	[ 86672] = "T14_melee",	[ 86673] = "T14_melee",
	[ 87192] = "T14_melee",	[ 87193] = "T14_melee",	[ 87194] = "T14_melee",	[ 87195] = "T14_melee",	[ 87196] = "T14_melee",
	[ 87197] = "T14_tank",	[ 87198] = "T14_tank",	[ 87199] = "T14_tank",	[ 87200] = "T14_tank",	[ 87201] = "T14_tank",
	[ 95330] = "T15_melee",	[ 95331] = "T15_melee",	[ 95332] = "T15_melee",	[ 95333] = "T15_melee",	[ 95334] = "T15_melee",
	[ 95986] = "T15_melee",	[ 95987] = "T15_melee",	[ 95988] = "T15_melee",	[ 95989] = "T15_melee",	[ 95990] = "T15_melee",
	[ 96730] = "T15_melee",	[ 96731] = "T15_melee",	[ 96732] = "T15_melee",	[ 96733] = "T15_melee",	[ 96734] = "T15_melee",
	[ 99030] = "T16_tank",	[ 99032] = "T16_tank",	[ 99033] = "T16_tank",	[ 99037] = "T16_tank",	[ 99038] = "T16_tank",
	[ 99034] = "T16_melee",	[ 99035] = "T16_melee",	[ 99036] = "T16_melee",	[ 99046] = "T16_melee",	[ 99047] = "T16_melee",
	[ 99195] = "T16_tank",	[ 99196] = "T16_tank",	[ 99201] = "T16_tank",	[ 99202] = "T16_tank",	[ 99203] = "T16_tank",
	[ 99197] = "T16_melee",	[ 99198] = "T16_melee",	[ 99199] = "T16_melee",	[ 99200] = "T16_melee",	[ 99206] = "T16_melee",
	[ 99407] = "T16_tank",	[ 99408] = "T16_tank",	[ 99409] = "T16_tank",	[ 99410] = "T16_tank",	[ 99415] = "T16_tank",
	[ 99411] = "T16_melee",	[ 99412] = "T16_melee",	[ 99413] = "T16_melee",	[ 99414] = "T16_melee",	[ 99418] = "T16_melee",
	[ 99557] = "T16_tank",	[ 99558] = "T16_tank",	[ 99562] = "T16_tank",	[ 99563] = "T16_tank",	[ 99597] = "T16_tank",
	[ 99559] = "T16_melee",	[ 99560] = "T16_melee",	[ 99561] = "T16_melee",	[ 99602] = "T16_melee",	[ 99603] = "T16_melee",
	[115580] = "T17",		[115581] = "T17",		[115582] = "T17",		[115583] = "T17",		[115584] = "T17",
	[124319] = "T18",		[124329] = "T18",		[124334] = "T18",		[124340] = "T18",		[124346] = "T18",
	[138351] = "T19",		[138354] = "T19",		[138357] = "T19",		[138360] = "T19",		[138363] = "T19",		[138374] = "T19",
}

local OVALE_WEAPON_CLASS = {}
do
	OVALE_WEAPON_CLASS[1],	-- "One-Handed Axes"
	OVALE_WEAPON_CLASS[2],	-- "Two-Handed Axes"
	OVALE_WEAPON_CLASS[3],	-- "Bows"
	OVALE_WEAPON_CLASS[4],	-- "Guns"
	OVALE_WEAPON_CLASS[5],	-- "One-Handed Maces"
	OVALE_WEAPON_CLASS[6],	-- "Two-Handed Maces"
	OVALE_WEAPON_CLASS[7],	-- "Polearms"
	OVALE_WEAPON_CLASS[8],	-- "One-Handed Swords"
	OVALE_WEAPON_CLASS[9],	-- "Two-Handed Swords"
	OVALE_WEAPON_CLASS[10],	-- "Staves"
	OVALE_WEAPON_CLASS[11],	-- "Fist Weapons"
	OVALE_WEAPON_CLASS[12],	-- "Miscellaneous"
	OVALE_WEAPON_CLASS[13],	-- "Daggers"
	OVALE_WEAPON_CLASS[14],	-- "Thrown"
	OVALE_WEAPON_CLASS[15],	-- "Crossbows"
	OVALE_WEAPON_CLASS[16],	-- "Wands"
	OVALE_WEAPON_CLASS[17] = API_GetAuctionItemSubClasses(1)	-- "Fishing Poles"
end

local OVALE_META_GEM = nil
do
	local _, _, _, _, _, _, name = API_GetAuctionItemSubClasses(8)	-- "8" is "Gem"
	OVALE_META_GEM = name
end

-- Normalized weapon attack speeds (http://www.wowpedia.org/Normalization)
local OVALE_NORMALIZED_WEAPON_SPEED = {
	-- [OVALE_WEAPON_CLASS[1]]  = 2.4,
	-- [OVALE_WEAPON_CLASS[2]]  = 3.3,
	-- [OVALE_WEAPON_CLASS[3]]  = 2.8,
	-- [OVALE_WEAPON_CLASS[4]]  = 2.8,
	-- [OVALE_WEAPON_CLASS[5]]  = 2.4,
	-- [OVALE_WEAPON_CLASS[6]]  = 3.3,
	-- [OVALE_WEAPON_CLASS[7]]  = 3.3,
	-- [OVALE_WEAPON_CLASS[8]]  = 2.4,
	-- [OVALE_WEAPON_CLASS[9]]  = 3.3,
	-- [OVALE_WEAPON_CLASS[10]] = 3.3,
	-- [OVALE_WEAPON_CLASS[11]] = 2.4,
	-- [OVALE_WEAPON_CLASS[12]] = 2.4, -- ??
	-- [OVALE_WEAPON_CLASS[13]] = 1.7,
	-- [OVALE_WEAPON_CLASS[14]] = 1.7, -- ??
	-- [OVALE_WEAPON_CLASS[15]] = 2.8,
	-- [OVALE_WEAPON_CLASS[16]] = 2.4,
	-- [OVALE_WEAPON_CLASS[17]] = 3.3,
}
--</private-static-properties>

--<public-static-properties>
-- Whether the equipment information is ready for use by other modules.
OvaleEquipment.ready = false
-- Item IDs of equipped items, indexed by slot ID.
OvaleEquipment.equippedItems = {}
-- Item levels of equipped items, indexed by slot ID.
OvaleEquipment.equippedItemLevels = {}
-- Type of main-hand item equipped.
OvaleEquipment.mainHandItemType = nil
-- Type of off-hand item equipped.
OvaleEquipment.offHandItemType = nil
-- Count of equipped pieces of an armor set: armorSetCount[armorSetName] = equippedCount
OvaleEquipment.armorSetCount = {}
-- Item ID of meta gem if equipped.
OvaleEquipment.metaGem = nil

-- Normalized weapon speeds for equipped mainhand and offhand weapons.
OvaleEquipment.mainHandWeaponSpeed = nil
OvaleEquipment.offHandWeaponSpeed = nil
--</public-static-properties>

--<private-static-methods>
local function GetEquippedItemType(slotId)
	OvaleEquipment:StartProfiling("OvaleEquipment_GetEquippedItemType")
	local itemId = OvaleEquipment:GetEquippedItem(slotId)
	local itemType
	if itemId then
		local _, _, _, _, _, _, _, _, inventoryType = API_GetItemInfo(itemId)
		itemType = inventoryType
	end
	OvaleEquipment:StopProfiling("OvaleEquipment_GetEquippedItemType")
	return itemType
end

local function GetItemLevel(slotId)
	OvaleEquipment:StartProfiling("OvaleEquipment_GetItemLevel")
	self_tooltip:SetInventoryItem("player", slotId)
	local itemLevel
	for i = 2, self_tooltip:NumLines() do
		local text = _G["OvaleEquipment_ScanningTooltipTextLeft" .. i]:GetText()
		if text then
			itemLevel = strmatch(text, OVALE_ITEM_LEVEL_PATTERN)
			if itemLevel then
				itemLevel = tonumber(itemLevel)
				break
			end
		end
	end
	OvaleEquipment:StopProfiling("OvaleEquipment_GetItemLevel")
	return itemLevel
end

local function GetNormalizedWeaponSpeed(slotId)
	OvaleEquipment:StartProfiling("OvaleEquipment_GetNormalizedWeaponSpeed")
	local weaponSpeed
	if slotId == INVSLOT_MAINHAND or slotId == INVSLOT_OFFHAND then
		local itemId = OvaleEquipment:GetEquippedItem(slotId)
		if itemId then
			local _, _, _, _, _, _, weaponClass = API_GetItemInfo(itemId)
			-- weaponSpeed = OVALE_NORMALIZED_WEAPON_SPEED[weaponClass]
		end
	end
	OvaleEquipment:StopProfiling("OvaleEquipment_GetNormalizedWeaponSpeed")
	return weaponSpeed
end
--</private-static-methods>

--<public-static-methods>
function OvaleEquipment:OnInitialize()
	-- Create the tooltip used for scanning.
	self_tooltip = API_CreateFrame("GameTooltip", "OvaleEquipment_ScanningTooltip", nil, "GameTooltipTemplate")
	self_tooltip:SetOwner(UIParent, "ANCHOR_NONE")
end

function OvaleEquipment:OnEnable()
	self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateEquippedItems")
	self:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE", "UpdateEquippedItemLevels")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

function OvaleEquipment:OnDisable()
	self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

function OvaleEquipment:GET_ITEM_INFO_RECEIVED(event)
	self:StartProfiling("OvaleEquipment_GET_ITEM_INFO_RECEIVED")
	self.mainHandItemType = GetEquippedItemType(INVSLOT_MAINHAND)
	self.offHandItemType = GetEquippedItemType(INVSLOT_OFFHAND)
	self.mainHandWeaponSpeed = self:HasMainHandWeapon() and GetNormalizedWeaponSpeed(INVSLOT_MAINHAND)
	self.offHandWeaponSpeed = self:HasOffHandWeapon() and GetNormalizedWeaponSpeed(INVSLOT_OFFHAND)
	local changed = false
	if changed then
		Ovale.refreshNeeded[Ovale.playerGUID] = true
		self:SendMessage("Ovale_EquipmentChanged")
	end
	self:StopProfiling("OvaleEquipment_GET_ITEM_INFO_RECEIVED")
end

function OvaleEquipment:PLAYER_EQUIPMENT_CHANGED(event, slotId, hasItem)
	self:StartProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED")
	if hasItem then
		self.equippedItems[slotId] = API_GetInventoryItemID("player", slotId)
		self.equippedItemLevels[slotId] = GetItemLevel(slotId)
		if slotId == INVSLOT_MAINHAND then
			self.mainHandItemType = GetEquippedItemType(slotId)
			self.mainHandWeaponSpeed = self:HasMainHandWeapon() and GetNormalizedWeaponSpeed(INVSLOT_MAINHAND)
		elseif slotId == INVSLOT_OFFHAND then
			self.offHandItemType = GetEquippedItemType(slotId)
			self.offHandWeaponSpeed = self:HasOffHandWeapon() and GetNormalizedWeaponSpeed(INVSLOT_OFFHAND)
		end
	else
		self.equippedItems[slotId] = nil
		self.equippedItemLevels[slotId] = nil
		if slotId == INVSLOT_MAINHAND then
			self.mainHandItemType = nil
		elseif slotId == INVSLOT_OFFHAND then
			self.offHandItemType = nil
		end
	end

	self:UpdateArmorSetCount()
	Ovale.refreshNeeded[Ovale.playerGUID] = true
	self:SendMessage("Ovale_EquipmentChanged")
	self:StopProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED")
end

do
	-- Legacy armor set names; no longer documented.
	local armorSetName = {
		HUNTER = { ["T14"] = "T14_melee", ["T15"] = "T15_melee", ["T16"] = "T16_melee" },
		MAGE = { ["T14"] = "T14_caster", ["T15"] = "T15_caster", ["T16"] = "T16_caster" },
		ROGUE = { ["T14"] = "T14_melee", ["T15"] = "T15_melee", ["T16"] = "T16_melee" },
		WARLOCK = { ["T14"] = "T14_caster", ["T15"] = "T15_caster" },
	}

	function OvaleEquipment:GetArmorSetCount(name)
		local count = self.armorSetCount[name]
		if not count then
			local class = Ovale.playerClass
			if armorSetName[class] and armorSetName[class][name] then
				name = armorSetName[class][name]
				count = self.armorSetCount[name]
			end
		end
		return count or 0
	end
end

do
	-- Static table to hold return values for GetEquippedItem().
	local result = {}
	local count = 0

	function OvaleEquipment:GetEquippedItem(...)
		count = select("#", ...)
		for n = 1, count do
			local slotId = select(n, ...)
			if slotId and type(slotId) ~= "number" then
				slotId = OVALE_SLOTNAME[slotId]
			end
			if slotId then
				result[n] = self.equippedItems[slotId]
			else
				result[n] = nil
			end
		end
		if count > 0 then
			return unpack(result, 1, count)
		else
			return nil
		end
	end
end

do
	-- Static table to hold return values for GetEquippedItemLevel().
	local result = {}
	local count = 0

	function OvaleEquipment:GetEquippedItemLevel(...)
		count = select("#", ...)
		for n = 1, count do
			local slotId = select(n, ...)
			if slotId and type(slotId) ~= "number" then
				slotId = OVALE_SLOTNAME[slotId]
			end
			if slotId then
				result[n] = self.equippedItemLevels[slotId]
			else
				result[n] = nil
			end
		end
		if count > 0 then
			return unpack(result, 1, count)
		else
			return nil
		end
	end
end

-- Return the equipped trinkets as a pair of return values.
function OvaleEquipment:GetEquippedTrinkets()
	return self.equippedItems[INVSLOT_TRINKET1], self.equippedItems[INVSLOT_TRINKET2]
end

-- ... check for additional slots
function OvaleEquipment:HasEquippedItem(itemId, slot, ...)
	if (slot ~= nil) then
		local slotId = slot
		if type(slotId) ~= "number" then
			slotId = OVALE_SLOTNAME[slotId]
		end
		if slotId and self.equippedItems[slotId] == itemId then
			return slotId
		end
		
		local additionalSlotsCount = select("#", ...)
		if additionalSlotsCount > 0 then
			for n = 1, additionalSlotsCount do
				slotId = select(n, ...)
				if slotId and type(slotId) ~= "number" then
					slotId = OVALE_SLOTNAME[slotId]
				end
				if slotId and self.equippedItems[slotId] == itemId then
					return slotId
				end
			end
		end
	else
		for slotId, equippedItemId in pairs(self.equippedItems) do
			if equippedItemId == itemId then
				return slotId
			end
		end
	end
	return nil
end

function OvaleEquipment:HasMainHandWeapon(handedness)
	if handedness then
		if handedness == 1 then
			return self.mainHandItemType == "INVTYPE_WEAPON"
				or self.mainHandItemType == "INVTYPE_WEAPONMAINHAND"
		elseif handedness == 2 then
			return self.mainHandItemType == "INVTYPE_2HWEAPON"
		end
	else
		return self.mainHandItemType == "INVTYPE_WEAPON"
			or self.mainHandItemType == "INVTYPE_WEAPONMAINHAND"
			or self.mainHandItemType == "INVTYPE_2HWEAPON"
	end
	return false
end

function OvaleEquipment:HasOffHandWeapon(handedness)
	if handedness then
		if handedness == 1 then
			return self.offHandItemType == "INVTYPE_WEAPON"
				or self.offHandItemType == "INVTYPE_WEAPONOFFHAND"
				or self.offHandItemType == "INVTYPE_WEAPONMAINHAND"
		elseif handedness == 2 then
			return self.offHandItemType == "INVTYPE_2HWEAPON"
		end
	else
		return self.offHandItemType == "INVTYPE_WEAPON"
			or self.offHandItemType == "INVTYPE_WEAPONOFFHAND"
			or self.offHandItemType == "INVTYPE_WEAPONMAINHAND"
			or self.offHandItemType == "INVTYPE_2HWEAPON"
	end
	return false
end

function OvaleEquipment:HasShield()
	return self.offHandItemType == "INVTYPE_SHIELD"
end

function OvaleEquipment:HasTrinket(itemId)
	return self:HasEquippedItem(itemId, INVSLOT_TRINKET1)
		or self:HasEquippedItem(itemId, INVSLOT_TRINKET2)
end

function OvaleEquipment:HasTwoHandedWeapon(slotId)
	if slotId and type(slotId) ~= "number" then
		slotId = OVALE_SLOTNAME[slotId]
	end
	if slotId then
		if slotId == INVSLOT_MAINHAND then
			return self.mainHandItemType == "INVTYPE_2HWEAPON"
		elseif slotId == INVSLOT_OFFHAND then
			return self.offHandItemType == "INVTYPE_2HWEAPON"
		end
	else
		return self.mainHandItemType == "INVTYPE_2HWEAPON" or self.offHandItemType == "INVTYPE_2HWEAPON"
	end
	return false
end

function OvaleEquipment:HasOneHandedWeapon(slotId)
	if slotId and type(slotId) ~= "number" then
		slotId = OVALE_SLOTNAME[slotId]
	end
	if slotId then
		if slotId == INVSLOT_MAINHAND then
			return self.mainHandItemType == "INVTYPE_WEAPON" or self.mainHandItemType == "INVTYPE_WEAPONMAINHAND"
		elseif slotId == INVSLOT_OFFHAND then
			return self.offHandItemType == "INVTYPE_WEAPON" or self.offHandItemType == "INVTYPE_WEAPONMAINHAND"
		end
	else
		return self.mainHandItemType == "INVTYPE_WEAPON" or self.mainHandItemType == "INVTYPE_WEAPONMAINHAND"
			or self.offHandItemType == "INVTYPE_WEAPON" or self.offHandItemType == "INVTYPE_WEAPONMAINHAND"
	end
	return false
end

function OvaleEquipment:UpdateArmorSetCount()
	self:StartProfiling("OvaleEquipment_UpdateArmorSetCount")
	wipe(self.armorSetCount)
	for i = 1, #OVALE_ARMORSET_SLOT_IDS do
		local itemId = self:GetEquippedItem(OVALE_ARMORSET_SLOT_IDS[i])
		if itemId then
			local name = OVALE_ARMORSET[itemId]
			if name then
				if not self.armorSetCount[name] then
					self.armorSetCount[name] = 1
				else
					self.armorSetCount[name] = self.armorSetCount[name] + 1
				end
			end
		end
	end	
	self:StopProfiling("OvaleEquipment_UpdateArmorSetCount")
end

function OvaleEquipment:UpdateEquippedItems()
	self:StartProfiling("OvaleEquipment_UpdateEquippedItems")
	local changed = false
	local item
	for slotId = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		item = API_GetInventoryItemID("player", slotId)
		if item ~= self.equippedItems[slotId] then
			self.equippedItems[slotId] = item
			changed = true
		end
	end
	local changedItemLevels = self:UpdateEquippedItemLevels()
	changed = changed or changedItemLevels

	self.mainHandItemType = GetEquippedItemType(INVSLOT_MAINHAND)
	self.offHandItemType = GetEquippedItemType(INVSLOT_OFFHAND)
	self.mainHandWeaponSpeed = self:HasMainHandWeapon() and GetNormalizedWeaponSpeed(INVSLOT_MAINHAND)
	self.offHandWeaponSpeed = self:HasOffHandWeapon() and GetNormalizedWeaponSpeed(INVSLOT_OFFHAND)

	if changed then
		self:UpdateArmorSetCount()
		Ovale.refreshNeeded[Ovale.playerGUID] = true
		self:SendMessage("Ovale_EquipmentChanged")
	end
	self.ready = true
	self:StopProfiling("OvaleEquipment_UpdateEquippedItems")
end

function OvaleEquipment:UpdateEquippedItemLevels()
	self:StartProfiling("OvaleEquipment_UpdateEquippedItemLevels")
	local changed = false
	local itemLevel
	for slotId = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		itemLevel = GetItemLevel(slotId)
		if itemLevel ~= self.equippedItemLevels[slotId] then
			self.equippedItemLevels[slotId] = itemLevel
			changed = true
		end
	end
	if changed then
		Ovale.refreshNeeded[Ovale.playerGUID] = true
		self:SendMessage("Ovale_EquipmentChanged")
	end
	self:StopProfiling("OvaleEquipment_UpdateEquippedItemLevels")
	return changed
end

function OvaleEquipment:DebugEquipment()
	for slotId = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		self:Print("Slot %d = %s (%d)", slotId, self:GetEquippedItem(slotId), self:GetEquippedItemLevel(slotId))
	end
	self:Print("Main-hand item type: %s", self.mainHandItemType)
	self:Print("Off-hand item type: %s", self.offHandItemType)
	for k, v in pairs(self.armorSetCount) do
		self:Print("Player has %d piece(s) of %s armor set.", v, k)
	end
end
--</public-static-methods>
