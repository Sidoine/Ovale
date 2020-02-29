local __exports = LibStub:NewLibrary("ovale/Frame", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local AceGUI = LibStub:GetLibrary("AceGUI-3.0", true)
local Masque = LibStub:GetLibrary("Masque", true)
local __Icon = LibStub:GetLibrary("ovale/Icon")
local OvaleIcon = __Icon.OvaleIcon
local __Controls = LibStub:GetLibrary("ovale/Controls")
local lists = __Controls.lists
local checkBoxes = __Controls.checkBoxes
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ipairs = ipairs
local next = next
local pairs = pairs
local wipe = wipe
local type = type
local match = string.match
local CreateFrame = CreateFrame
local GetItemInfo = GetItemInfo
local GetTime = GetTime
local RegisterStateDriver = RegisterStateDriver
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitExists = UnitExists
local UnitIsDead = UnitIsDead
local UnitCanAttack = UnitCanAttack
local UIParent = UIParent
local huge = math.huge
local __aceguihelpers = LibStub:GetLibrary("ovale/acegui-helpers")
local AceGUIRegisterAsContainer = __aceguihelpers.AceGUIRegisterAsContainer
local strmatch = match
local INFINITY = huge
local OvaleFrame = __class(AceGUI.WidgetContainerBase, {
    ToggleOptions = function(self)
        if (self.content:IsShown()) then
            self.content:Hide()
        else
            self.content:Show()
        end
    end,
    Hide = function(self)
        self.frame:Hide()
    end,
    Show = function(self)
        self.frame:Show()
    end,
    OnAcquire = function(self)
        self.frame:SetParent(UIParent)
    end,
    OnRelease = function(self)
    end,
    OnWidthSet = function(self, width)
        local content = self.content
        local contentwidth = width - 34
        if contentwidth < 0 then
            contentwidth = 0
        end
        content:SetWidth(contentwidth)
    end,
    OnHeightSet = function(self, height)
        local content = self.content
        local contentheight = height - 57
        if contentheight < 0 then
            contentheight = 0
        end
        content:SetHeight(contentheight)
    end,
    OnLayoutFinished = function(self, width, height)
        if ( not width) then
            width = self.content:GetWidth()
        end
        self.content:SetWidth(width)
        self.content:SetHeight(height + 50)
    end,
    GetScore = function(self, spellId)
        for _, action in pairs(self.actions) do
            if action.spellId == spellId then
                if  not action.waitStart then
                    return 1
                else
                    local now = self.baseState.current.currentTime
                    local lag = now - action.waitStart
                    if lag > 5 then
                        return nil
                    elseif lag > 1.5 then
                        return 0
                    elseif lag > 0 then
                        return 1 - lag / 1.5
                    else
                        return 1
                    end
                end
            end
        end
        return 0
    end,
    UpdateVisibility = function(self)
        self.visible = true
        local profile = self.ovaleOptions.db.profile
        if  not profile.apparence.enableIcons then
            self.visible = false
        elseif  not self.hider:IsVisible() then
            self.visible = false
        else
            if profile.apparence.hideVehicule and UnitHasVehicleUI("player") then
                self.visible = false
            end
            if profile.apparence.avecCible and  not UnitExists("target") then
                self.visible = false
            end
            if profile.apparence.enCombat and  not self.ovaleFuture:IsInCombat(nil) then
                self.visible = false
            end
            if profile.apparence.targetHostileOnly and (UnitIsDead("target") or  not UnitCanAttack("player", "target")) then
                self.visible = false
            end
        end
        if self.visible then
            self:Show()
        else
            self:Hide()
        end
    end,
    OnUpdate = function(self, elapsed)
        self.ovaleFrameModule.module:SendMessage("Ovale_OnUpdate")
        self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
        local refresh = self.ovaleDebug.trace or (self.visible or self.ovaleSpellFlash:IsSpellFlashEnabled()) and (self.timeSinceLastUpdate > self.ovaleOptions.db.profile.apparence.minFrameRefresh / 1000 and next(self.ovale.refreshNeeded) or self.timeSinceLastUpdate > self.ovaleOptions.db.profile.apparence.maxFrameRefresh / 1000)
        if refresh then
            self.ovale:AddRefreshInterval(self.timeSinceLastUpdate * 1000)
            self.ovaleState:InitializeState()
            if self.ovaleCompile:EvaluateScript() then
                self:UpdateFrame()
            end
            local profile = self.ovaleOptions.db.profile
            local iconNodes = self.ovaleCompile:GetIconNodes()
            for k, node in ipairs(iconNodes) do
                if node.namedParams and node.namedParams.target then
                    self.baseState.current.defaultTarget = node.namedParams.target
                else
                    self.baseState.current.defaultTarget = "target"
                end
                if node.namedParams and node.namedParams.enemies then
                    self.ovaleEnemies.next.enemies = node.namedParams.enemies
                else
                    self.ovaleEnemies.next.enemies = nil
                end
                self.tracer:Log("+++ Icon %d", k)
                self.ovaleBestAction:StartNewAction()
                local atTime = self.ovaleFuture.next.nextCast
                if self.ovaleFuture.next.currentCast.spellId == nil or self.ovaleFuture.next.currentCast.spellId ~= self.ovaleFuture.next.lastGCDSpellId then
                    atTime = self.baseState.next.currentTime
                end
                local timeSpan, element = self.ovaleBestAction:GetAction(node, atTime)
                local start
                if element and element.offgcd then
                    start = timeSpan:NextTime(self.baseState.next.currentTime)
                else
                    start = timeSpan:NextTime(atTime)
                end
                if profile.apparence.enableIcons then
                    self:UpdateActionIcon(node, self.actions[k], element, start or 0)
                end
                if profile.apparence.spellFlash.enabled then
                    self.ovaleSpellFlash:Flash(node, element, start or 0)
                end
            end
            wipe(self.ovale.refreshNeeded)
            self.ovaleDebug:UpdateTrace()
            self.ovale:PrintOneTimeMessages()
            self.timeSinceLastUpdate = 0
        end
    end,
    UpdateActionIcon = function(self, node, action, element, start, now)
        local profile = self.ovaleOptions.db.profile
        local icons = action.secure and action.secureIcons or action.icons
        now = now or GetTime()
        if element and element.type == "value" then
            local value
            if element.value and element.origin and element.rate then
                value = element.value + (now - element.origin) * element.rate
            end
            self.tracer:Log("GetAction: start=%s, value=%f", start, value)
            local actionTexture
            if node.namedParams and node.namedParams.texture then
                actionTexture = node.namedParams.texture
            end
            icons[1]:SetValue(value, actionTexture)
            if #icons > 1 then
                icons[2]:Update(element, nil)
            end
        else
            local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend = self.ovaleBestAction:GetActionInfo(element, now)
            if actionResourceExtend and actionResourceExtend > 0 then
                if actionCooldownDuration and actionCooldownDuration > 0 then
                    self.tracer:Log("Extending cooldown of spell ID '%s' for primary resource by %fs.", actionId, actionResourceExtend)
                    actionCooldownDuration = actionCooldownDuration + actionResourceExtend
                elseif element and element.namedParams.pool_resource and element.namedParams.pool_resource == 1 then
                    self.tracer:Log("Delaying spell ID '%s' for primary resource by %fs.", actionId, actionResourceExtend)
                    start = start + actionResourceExtend
                end
            end
            self.tracer:Log("GetAction: start=%s, id=%s", start, actionId)
            if actionType == "spell" and actionId == self.ovaleFuture.next.currentCast.spellId and start and self.ovaleFuture.next.nextCast and start < self.ovaleFuture.next.nextCast then
                start = self.ovaleFuture.next.nextCast
            end
            if start and node.namedParams.nocd and now < start - node.namedParams.nocd then
                icons[1]:Update(element, nil)
            else
                icons[1]:Update(element, start, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend)
            end
            if actionType == "spell" then
                action.spellId = actionId
            else
                action.spellId = nil
            end
            if start and start <= now and actionUsable then
                action.waitStart = action.waitStart or now
            else
                action.waitStart = nil
            end
            if profile.apparence.moving and icons[1].cooldownStart and icons[1].cooldownEnd then
                local top = 1 - (now - icons[1].cooldownStart) / (icons[1].cooldownEnd - icons[1].cooldownStart)
                if top < 0 then
                    top = 0
                elseif top > 1 then
                    top = 1
                end
                icons[1]:SetPoint("TOPLEFT", self.frame, "TOPLEFT", (action.left + top * action.dx) / action.scale, (action.top - top * action.dy) / action.scale)
                if icons[2] then
                    icons[2]:SetPoint("TOPLEFT", self.frame, "TOPLEFT", (action.left + (top + 1) * action.dx) / action.scale, (action.top - (top + 1) * action.dy) / action.scale)
                end
            end
            if (node.namedParams.size ~= "small" and  not node.namedParams.nocd and profile.apparence.predictif) then
                if start then
                    self.tracer:Log("****Second icon %s", start)
                    local target = self.ovaleGuid:UnitGUID(actionTarget or "target")
                    if target then
                        self.ovaleFuture:ApplySpell(actionId, target, start)
                    end
                    local atTime = self.ovaleFuture.next.nextCast
                    if actionId ~= self.ovaleFuture.next.lastGCDSpellId then
                        atTime = self.baseState.next.currentTime
                    end
                    local timeSpan, nextElement = self.ovaleBestAction:GetAction(node, atTime)
                    if nextElement and nextElement.offgcd then
                        start = timeSpan:NextTime(self.baseState.next.currentTime) or huge
                    else
                        start = timeSpan:NextTime(atTime) or huge
                    end
                    local actionTexture2, actionInRange2, actionCooldownStart2, actionCooldownDuration2, actionUsable2, actionShortcut2, actionIsCurrent2, actionEnable2, actionType2, actionId2, actionTarget2, actionResourceExtend2 = self.ovaleBestAction:GetActionInfo(nextElement, start)
                    icons[2]:Update(nextElement, start, actionTexture2, actionInRange2, actionCooldownStart2, actionCooldownDuration2, actionUsable2, actionShortcut2, actionIsCurrent2, actionEnable2, actionType2, actionId2, actionTarget2, actionResourceExtend2)
                else
                    icons[2]:Update(element, nil)
                end
            end
        end
    end,
    UpdateFrame = function(self)
        local profile = self.ovaleOptions.db.profile
        if self.hider:IsVisible() then
            self.frame:ClearAllPoints()
            self.frame:SetPoint("CENTER", self.hider, "CENTER", profile.apparence.offsetX, profile.apparence.offsetY)
            self.frame:EnableMouse( not profile.apparence.clickThru)
        end
        self:ReleaseChildren()
        self:UpdateIcons()
        self:UpdateControls()
        self:UpdateVisibility()
    end,
    GetCheckBox = function(self, name)
        local widget
        if type(name) == "string" then
            widget = self.checkBoxWidget[name]
        elseif type(name) == "number" then
            local k = 0
            for _, frame in pairs(self.checkBoxWidget) do
                if k == name then
                    widget = frame
                    break
                end
                k = k + 1
            end
        end
        return widget
    end,
    IsChecked = function(self, name)
        local widget = self:GetCheckBox(name)
        return widget and widget:GetValue()
    end,
    GetListValue = function(self, name)
        local widget = self.listWidget[name]
        return widget and widget:GetValue()
    end,
    SetCheckBox = function(self, name, on)
        local widget = self:GetCheckBox(name)
        if widget then
            local oldValue = widget:GetValue()
            if oldValue ~= on then
                widget:SetValue(on)
                self.OnCheckBoxValueChanged(widget)
            end
        end
    end,
    ToggleCheckBox = function(self, name)
        local widget = self:GetCheckBox(name)
        if widget then
            local on =  not widget:GetValue()
            widget:SetValue(on)
            self.OnCheckBoxValueChanged(widget)
        end
    end,
    FinalizeString = function(self, s)
        local item, id = strmatch(s, "^(item:)(.+)")
        if item then
            s = GetItemInfo(id)
        end
        return s
    end,
    UpdateControls = function(self)
        local profile = self.ovaleOptions.db.profile
        wipe(self.checkBoxWidget)
        for name, checkBox in pairs(checkBoxes) do
            if checkBox.text then
                local widget = AceGUI:Create("CheckBox")
                local text = self:FinalizeString(checkBox.text)
                widget:SetLabel(text)
                if profile.check[name] == nil then
                    profile.check[name] = checkBox.checked
                end
                if profile.check[name] then
                    widget:SetValue(profile.check[name])
                end
                widget:SetUserData("name", name)
                widget:SetCallback("OnValueChanged", self.OnCheckBoxValueChanged)
                self:AddChild(widget)
                self.checkBoxWidget[name] = widget
            else
                self.ovale:OneTimeMessage("Warning: checkbox '%s' is used but not defined.", name)
            end
        end
        wipe(self.listWidget)
        for name, list in pairs(lists) do
            if next(list.items) then
                local widget = AceGUI:Create("Dropdown")
                widget:SetList(list.items)
                if  not profile.list[name] then
                    profile.list[name] = list.default
                end
                if profile.list[name] then
                    widget:SetValue(profile.list[name])
                end
                widget:SetUserData("name", name)
                widget:SetCallback("OnValueChanged", self.OnDropDownValueChanged)
                self:AddChild(widget)
                self.listWidget[name] = widget
            else
                self.ovale:OneTimeMessage("Warning: list '%s' is used but has no items.", name)
            end
        end
    end,
    UpdateIcons = function(self)
        for _, action in pairs(self.actions) do
            for _, icon in pairs(action.icons) do
                icon:Hide()
            end
            for _, icon in pairs(action.secureIcons) do
                icon:Hide()
            end
        end
        local profile = self.ovaleOptions.db.profile
        self.frame:EnableMouse( not profile.apparence.clickThru)
        local left = 0
        local maxHeight = 0
        local maxWidth = 0
        local top = 0
        local BARRE = 8
        local margin = profile.apparence.margin
        local iconNodes = self.ovaleCompile:GetIconNodes()
        for k, node in ipairs(iconNodes) do
            if  not self.actions[k] then
                self.actions[k] = {
                    icons = {},
                    secureIcons = {},
                    dx = 0,
                    dy = 0,
                    left = 0,
                    scale = 1,
                    top = 0
                }
            end
            local action = self.actions[k]
            local width, height, newScale
            local nbIcons
            if (node.namedParams ~= nil and node.namedParams.size == "small") then
                newScale = profile.apparence.smallIconScale
                width = newScale * 36 + margin
                height = newScale * 36 + margin
                nbIcons = 1
            else
                newScale = profile.apparence.iconScale
                width = newScale * 36 + margin
                height = newScale * 36 + margin
                if profile.apparence.predictif and node.namedParams.type ~= "value" then
                    nbIcons = 2
                else
                    nbIcons = 1
                end
            end
            if (top + height > profile.apparence.iconScale * 36 + margin) then
                top = 0
                left = maxWidth
            end
            action.scale = newScale
            if (profile.apparence.vertical) then
                action.left = top
                action.top = -left - BARRE - margin
                action.dx = width
                action.dy = 0
            else
                action.left = left
                action.top = -top - BARRE - margin
                action.dx = 0
                action.dy = height
            end
            action.secure = node.secure
            for l = 1, nbIcons, 1 do
                local icon
                if  not node.secure then
                    if  not action.icons[l] then
                        action.icons[l] = OvaleIcon("Icon" .. k .. "n" .. l, self, false, self.ovaleOptions, self.ovaleSpellBook)
                    end
                    icon = action.icons[l]
                else
                    if  not action.secureIcons[l] then
                        action.secureIcons[l] = OvaleIcon("SecureIcon" .. k .. "n" .. l, self, true, self.ovaleOptions, self.ovaleSpellBook)
                    end
                    icon = action.secureIcons[l]
                end
                local scale = action.scale
                if l > 1 then
                    scale = scale * profile.apparence.secondIconScale
                end
                icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", (action.left + (l - 1) * action.dx) / scale, (action.top - (l - 1) * action.dy) / scale)
                icon:SetScale(scale)
                icon:SetRemainsFont(profile.apparence.remainsFontColor)
                icon:SetFontScale(profile.apparence.fontScale)
                icon:SetParams(node.positionalParams, node.namedParams)
                icon:SetHelp((node.namedParams ~= nil and node.namedParams.help) or nil)
                icon:SetRangeIndicator(profile.apparence.targetText)
                icon:EnableMouse( not profile.apparence.clickThru)
                icon.frame:SetAlpha(profile.apparence.alpha)
                icon.cdShown = (l == 1)
                if self.skinGroup then
                    self.skinGroup:AddButton(icon.frame)
                end
                if l == 1 then
                    icon:Show()
                end
            end
            top = top + height
            if (top > maxHeight) then
                maxHeight = top
            end
            if (left + width > maxWidth) then
                maxWidth = left + width
            end
        end
        self.content:SetAlpha(profile.apparence.optionsAlpha)
        if (profile.apparence.vertical) then
            self.barre:SetWidth(maxHeight - margin)
            self.barre:SetHeight(BARRE)
            self.frame:SetWidth(maxHeight + profile.apparence.iconShiftY)
            self.frame:SetHeight(maxWidth + BARRE + margin + profile.apparence.iconShiftX)
            self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", maxHeight + profile.apparence.iconShiftX, profile.apparence.iconShiftY)
        else
            self.barre:SetWidth(maxWidth - margin)
            self.barre:SetHeight(BARRE)
            self.frame:SetWidth(maxWidth)
            self.frame:SetHeight(maxHeight + BARRE + margin)
            self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", maxWidth + profile.apparence.iconShiftX, profile.apparence.iconShiftY)
        end
    end,
    constructor = function(self, ovaleState, ovaleFrameModule, ovaleCompile, ovaleFuture, baseState, ovaleEnemies, ovale, ovaleOptions, ovaleDebug, ovaleGuid, ovaleSpellFlash, ovaleSpellBook, ovaleBestAction)
        self.ovaleState = ovaleState
        self.ovaleFrameModule = ovaleFrameModule
        self.ovaleCompile = ovaleCompile
        self.ovaleFuture = ovaleFuture
        self.baseState = baseState
        self.ovaleEnemies = ovaleEnemies
        self.ovale = ovale
        self.ovaleOptions = ovaleOptions
        self.ovaleDebug = ovaleDebug
        self.ovaleGuid = ovaleGuid
        self.ovaleSpellFlash = ovaleSpellFlash
        self.ovaleSpellBook = ovaleSpellBook
        self.ovaleBestAction = ovaleBestAction
        self.checkBoxWidget = {}
        self.listWidget = {}
        self.visible = true
        self.OnCheckBoxValueChanged = function(widget)
            local name = widget:GetUserData("name")
            self.ovaleOptions.db.profile.check[name] = widget:GetValue()
            self.ovaleFrameModule.module:SendMessage("Ovale_CheckBoxValueChanged", name)
        end
        self.OnDropDownValueChanged = function(widget)
            local name = widget:GetUserData("name")
            self.ovaleOptions.db.profile.list[name] = widget:GetValue()
            self.ovaleFrameModule.module:SendMessage("Ovale_ListValueChanged", name)
        end
        self.type = "Frame"
        self.localstatus = {}
        self.actions = {}
        AceGUI.WidgetContainerBase.constructor(self)
        local hider = CreateFrame("Frame", ovale:GetName() .. "PetBattleFrameHider", UIParent, "SecureHandlerStateTemplate")
        local newFrame = CreateFrame("Frame", nil, hider)
        hider:SetAllPoints(UIParent)
        RegisterStateDriver(hider, "visibility", "[petbattle] hide; show")
        self.tracer = ovaleDebug:create("OvaleFrame")
        self.frame = newFrame
        self.hider = hider
        self.updateFrame = CreateFrame("Frame", ovale:GetName() .. "UpdateFrame")
        self.barre = self.frame:CreateTexture()
        self.content = CreateFrame("Frame", nil, self.updateFrame)
        if Masque then
            self.skinGroup = Masque:Group(ovale:GetName())
        end
        self.timeSinceLastUpdate = INFINITY
        newFrame:SetWidth(100)
        newFrame:SetHeight(100)
        newFrame:SetMovable(true)
        newFrame:SetFrameStrata("MEDIUM")
        newFrame:SetScript("OnMouseDown", function()
            if ( not ovaleOptions.db.profile.apparence.verrouille) then
                newFrame:StartMoving()
                AceGUI:ClearFocus()
            end
        end)
        newFrame:SetScript("OnMouseUp", function()
            newFrame:StopMovingOrSizing()
            local x, y = newFrame:GetCenter()
            local parent = newFrame:GetParent()
            if parent then
                local profile = ovaleOptions.db.profile
                local parentX, parentY = parent:GetCenter()
                profile.apparence.offsetX = x - parentX
                profile.apparence.offsetY = y - parentY
            end
        end)
        newFrame:SetScript("OnEnter", function()
            local profile = ovaleOptions.db.profile
            if  not (profile.apparence.enableIcons and profile.apparence.verrouille) then
                self.barre:Show()
            end
        end)
        newFrame:SetScript("OnLeave", function()
            self.barre:Hide()
        end)
        newFrame:SetScript("OnHide", function()
            return self:Hide()
        end)
        self.updateFrame:SetScript("OnUpdate", function(updateFrame, elapsed)
            return self:OnUpdate(elapsed)
        end)
        self.barre:SetColorTexture(0.8, 0.8, 0.8, 0.5)
        self.barre:SetPoint("TOPLEFT", 0, 0)
        self.barre:Hide()
        local content = self.content
        content:SetWidth(200)
        content:SetHeight(100)
        content:Hide()
        AceGUIRegisterAsContainer(self)
    end,
})
__exports.OvaleFrameModuleClass = __class(nil, {
    constructor = function(self, ovaleState, ovaleCompile, ovaleFuture, baseState, ovaleEnemies, ovale, ovaleOptions, ovaleDebug, ovaleGuid, ovaleSpellFlash, ovaleSpellBook, ovaleBestAction)
        self.ovaleState = ovaleState
        self.ovaleCompile = ovaleCompile
        self.ovaleFuture = ovaleFuture
        self.baseState = baseState
        self.ovaleEnemies = ovaleEnemies
        self.ovale = ovale
        self.ovaleOptions = ovaleOptions
        self.ovaleDebug = ovaleDebug
        self.ovaleGuid = ovaleGuid
        self.ovaleSpellFlash = ovaleSpellFlash
        self.ovaleSpellBook = ovaleSpellBook
        self.ovaleBestAction = ovaleBestAction
        self.OnInitialize = function()
            self.module:RegisterMessage("Ovale_OptionChanged", self.Ovale_OptionChanged)
            self.module:RegisterMessage("Ovale_CombatStarted", self.Ovale_CombatStarted)
            self.module:RegisterMessage("Ovale_CombatEnded", self.Ovale_CombatEnded)
            self.module:RegisterEvent("PLAYER_TARGET_CHANGED", self.PLAYER_TARGET_CHANGED)
            self.frame:UpdateFrame()
        end
        self.handleDisable = function()
            self.module:UnregisterMessage("Ovale_OptionChanged")
            self.module:UnregisterMessage("Ovale_CombatStarted")
            self.module:UnregisterMessage("Ovale_CombatEnded")
            self.module:UnregisterEvent("PLAYER_TARGET_CHANGED")
        end
        self.Ovale_OptionChanged = function(event, eventType)
            if  not self.frame then
                return 
            end
            if eventType == "visibility" then
                self.frame:UpdateVisibility()
            else
                self.frame:UpdateFrame()
            end
        end
        self.PLAYER_TARGET_CHANGED = function()
            self.frame:UpdateVisibility()
        end
        self.Ovale_CombatStarted = function(event, atTime)
            self.frame:UpdateVisibility()
        end
        self.Ovale_CombatEnded = function(event, atTime)
            self.frame:UpdateVisibility()
        end
        self.module = ovale:createModule("OvaleFrame", self.OnInitialize, self.handleDisable, aceEvent)
        self.frame = OvaleFrame(self.ovaleState, self, self.ovaleCompile, self.ovaleFuture, self.baseState, self.ovaleEnemies, self.ovale, self.ovaleOptions, self.ovaleDebug, self.ovaleGuid, self.ovaleSpellFlash, self.ovaleSpellBook, self.ovaleBestAction)
    end,
})
