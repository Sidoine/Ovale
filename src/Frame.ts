import AceGUI, {
    AceGUIWidgetCheckBox,
    AceGUIWidgetDropDown,
} from "@wowts/ace_gui-3.0";
import Masque, { MasqueSkinGroup } from "@wowts/masque";
import { Element, OvaleBestActionClass } from "./BestAction";
import { OvaleCompileClass } from "./Compile";
import { OvaleSpellFlashClass } from "./SpellFlash";
import { OvaleStateClass } from "./State";
import { OvaleIcon } from "./Icon";
import { OvaleEnemiesClass } from "./Enemies";
import { lists, checkBoxes } from "./Controls";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    lualength,
    LuaArray,
    ipairs,
    next,
    pairs,
    wipe,
    type,
    LuaObj,
} from "@wowts/lua";
import { match } from "@wowts/string";
import {
    CreateFrame,
    GetItemInfo,
    GetTime,
    RegisterStateDriver,
    UnitHasVehicleUI,
    UnitExists,
    UnitIsDead,
    UnitCanAttack,
    UIParent,
    UIFrame,
    UITexture,
} from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { AceGUIRegisterAsContainer } from "./acegui-helpers";
import { OvaleFutureClass } from "./Future";
import { BaseState } from "./BaseState";
import { AstNode } from "./AST";
import { OvaleClass } from "./Ovale";
import { OvaleOptionsClass } from "./Options";
import { AceModule } from "@wowts/tsaddon";
import { OvaleDebugClass, Tracer } from "./Debug";
import { OvaleGUIDClass } from "./GUID";
import { OvaleSpellBookClass } from "./SpellBook";
import { OvaleCombatClass } from "./combat";
import { OneTimeMessage, PrintOneTimeMessages } from "./tools";

let strmatch = match;
let INFINITY = huge;

interface Action {
    secure?: boolean;
    secureIcons: LuaArray<OvaleIcon>;
    icons: LuaArray<OvaleIcon>;
    spellId?: number;
    waitStart?: number;
    left: number;
    top: number;
    scale: number;
    dx: number;
    dy: number;
}

class OvaleFrame extends AceGUI.WidgetContainerBase {
    checkBoxWidget: LuaObj<AceGUIWidgetCheckBox> = {};
    listWidget: LuaObj<AceGUIWidgetDropDown> = {};
    visible: boolean = true;

    ToggleOptions() {
        if (this.content.IsShown()) {
            this.content.Hide();
        } else {
            this.content.Show();
        }
    }

    Hide() {
        this.frame.Hide();
    }

    Show() {
        this.frame.Show();
    }

    OnAcquire() {
        this.frame.SetParent(UIParent);
    }

    OnRelease() {}

    OnWidthSet(width: number) {
        let content = this.content;
        let contentwidth = width - 34;
        if (contentwidth < 0) {
            contentwidth = 0;
        }
        content.SetWidth(contentwidth);
    }

    OnHeightSet(height: number) {
        let content = this.content;
        let contentheight = height - 57;
        if (contentheight < 0) {
            contentheight = 0;
        }
        content.SetHeight(contentheight);
    }

    OnLayoutFinished(width: number, height: number) {
        if (!width) {
            width = this.content.GetWidth();
        }
        this.content.SetWidth(width);
        this.content.SetHeight(height + 50);
    }

    // TODO need to be moved elsewhere
    public GetScore(spellId: number) {
        for (const [, action] of pairs(this.actions)) {
            if (action.spellId == spellId) {
                if (!action.waitStart) {
                    return 1;
                } else {
                    let now = this.baseState.current.currentTime;
                    let lag = now - action.waitStart;
                    if (lag > 5) {
                        return undefined;
                    } else if (lag > 1.5) {
                        return 0;
                    } else if (lag > 0) {
                        return 1 - lag / 1.5;
                    } else {
                        return 1;
                    }
                }
            }
        }
        return 0;
    }

    UpdateVisibility() {
        this.visible = true;
        let profile = this.ovaleOptions.db.profile;
        if (!profile.apparence.enableIcons) {
            this.visible = false;
        } else if (!this.hider.IsVisible()) {
            this.visible = false;
        } else {
            if (profile.apparence.hideVehicule && UnitHasVehicleUI("player")) {
                this.visible = false;
            }
            if (profile.apparence.avecCible && !UnitExists("target")) {
                this.visible = false;
            }
            if (
                profile.apparence.enCombat &&
                !this.combat.isInCombat(undefined)
            ) {
                this.visible = false;
            }
            if (
                profile.apparence.targetHostileOnly &&
                (UnitIsDead("target") || !UnitCanAttack("player", "target"))
            ) {
                this.visible = false;
            }
        }
        if (this.visible) {
            this.Show();
        } else {
            this.Hide();
        }
    }

    OnUpdate(elapsed: number) {
        this.ovaleFrameModule.module.SendMessage("Ovale_OnUpdate");
        this.timeSinceLastUpdate = this.timeSinceLastUpdate + elapsed;
        let refresh =
            this.ovaleDebug.trace ||
            ((this.visible || this.ovaleSpellFlash.IsSpellFlashEnabled()) &&
                ((this.timeSinceLastUpdate >
                    this.ovaleOptions.db.profile.apparence.minFrameRefresh /
                        1000 &&
                    next(this.ovale.refreshNeeded)) ||
                    this.timeSinceLastUpdate >
                        this.ovaleOptions.db.profile.apparence.maxFrameRefresh /
                            1000));
        if (refresh) {
            this.ovale.AddRefreshInterval(this.timeSinceLastUpdate * 1000);
            this.ovaleState.InitializeState();
            if (this.ovaleCompile.EvaluateScript()) {
                this.UpdateFrame();
            }
            const profile = this.ovaleOptions.db.profile;
            const iconNodes = this.ovaleCompile.GetIconNodes();
            for (const [k, node] of ipairs(iconNodes)) {
                if (node.namedParams && node.namedParams.target) {
                    this.baseState.current.defaultTarget = <string>(
                        node.namedParams.target
                    );
                } else {
                    this.baseState.current.defaultTarget = "target";
                }
                if (node.namedParams && node.namedParams.enemies) {
                    this.ovaleEnemies.next.enemies = node.namedParams.enemies;
                } else {
                    this.ovaleEnemies.next.enemies = undefined;
                }
                this.tracer.Log("+++ Icon %d", k);
                this.ovaleBestAction.StartNewAction();
                let atTime = this.ovaleFuture.next.nextCast;
                if (
                    this.ovaleFuture.next.currentCast.spellId == undefined ||
                    this.ovaleFuture.next.currentCast.spellId !=
                        this.ovaleFuture.next.lastGCDSpellId
                ) {
                    atTime = this.baseState.next.currentTime;
                }
                let [timeSpan, element] = this.ovaleBestAction.GetAction(
                    node,
                    atTime
                );
                let start;
                if (element && element.offgcd) {
                    start = timeSpan.NextTime(this.baseState.next.currentTime);
                } else {
                    start = timeSpan.NextTime(atTime);
                }
                if (profile.apparence.enableIcons) {
                    this.UpdateActionIcon(
                        node,
                        this.actions[k],
                        element,
                        start || 0
                    );
                }
                if (profile.apparence.spellFlash.enabled) {
                    this.ovaleSpellFlash.Flash(node, element, start || 0);
                }
            }
            wipe(this.ovale.refreshNeeded);
            this.ovaleDebug.UpdateTrace();
            PrintOneTimeMessages();
            this.timeSinceLastUpdate = 0;
        }
    }
    UpdateActionIcon(
        node: AstNode,
        action: Action,
        element: Element | undefined,
        start: number,
        now?: number
    ) {
        const profile = this.ovaleOptions.db.profile;
        let icons = (action.secure && action.secureIcons) || action.icons;
        now = now || GetTime();
        if (element && element.type == "value") {
            let value;
            if (element.value && element.origin && element.rate) {
                value =
                    <number>element.value +
                    (now - element.origin) * element.rate;
            }
            this.tracer.Log("GetAction: start=%s, value=%f", start, value);
            let actionTexture;
            if (node.namedParams && node.namedParams.texture) {
                actionTexture = node.namedParams.texture;
            }
            icons[1].SetValue(value, actionTexture);
            if (lualength(icons) > 1) {
                icons[2].Update(element, undefined);
            }
        } else {
            let [
                actionTexture,
                actionInRange,
                actionCooldownStart,
                actionCooldownDuration,
                actionUsable,
                actionShortcut,
                actionIsCurrent,
                actionEnable,
                actionType,
                actionId,
                actionTarget,
                actionResourceExtend,
            ] = this.ovaleBestAction.GetActionInfo(element, now);
            if (actionResourceExtend && actionResourceExtend > 0) {
                if (actionCooldownDuration && actionCooldownDuration > 0) {
                    this.tracer.Log(
                        "Extending cooldown of spell ID '%s' for primary resource by %fs.",
                        actionId,
                        actionResourceExtend
                    );
                    actionCooldownDuration =
                        actionCooldownDuration + actionResourceExtend;
                } else if (
                    element &&
                    element.namedParams.pool_resource &&
                    element.namedParams.pool_resource == 1
                ) {
                    this.tracer.Log(
                        "Delaying spell ID '%s' for primary resource by %fs.",
                        actionId,
                        actionResourceExtend
                    );
                    start = start + actionResourceExtend;
                }
            }

            this.tracer.Log("GetAction: start=%s, id=%s", start, actionId);
            if (
                actionType == "spell" &&
                actionId == this.ovaleFuture.next.currentCast.spellId &&
                start &&
                this.ovaleFuture.next.nextCast &&
                start < this.ovaleFuture.next.nextCast
            ) {
                start = this.ovaleFuture.next.nextCast;
            }
            if (
                start &&
                node.namedParams.nocd &&
                now < start - node.namedParams.nocd
            ) {
                icons[1].Update(element, undefined);
            } else {
                icons[1].Update(
                    element,
                    start,
                    actionTexture,
                    actionInRange,
                    actionCooldownStart,
                    actionCooldownDuration,
                    actionUsable,
                    actionShortcut,
                    actionIsCurrent,
                    actionEnable,
                    actionType,
                    actionId,
                    actionTarget,
                    actionResourceExtend
                );
            }
            if (actionType == "spell") {
                action.spellId = <number>actionId;
            } else {
                action.spellId = undefined;
            }
            if (start && start <= now && actionUsable) {
                action.waitStart = action.waitStart || now;
            } else {
                action.waitStart = undefined;
            }
            if (
                profile.apparence.moving &&
                icons[1].cooldownStart &&
                icons[1].cooldownEnd
            ) {
                let top =
                    1 -
                    (now - icons[1].cooldownStart) /
                        (icons[1].cooldownEnd - icons[1].cooldownStart);
                if (top < 0) {
                    top = 0;
                } else if (top > 1) {
                    top = 1;
                }
                icons[1].SetPoint(
                    "TOPLEFT",
                    this.frame,
                    "TOPLEFT",
                    (action.left + top * action.dx) / action.scale,
                    (action.top - top * action.dy) / action.scale
                );
                if (icons[2]) {
                    icons[2].SetPoint(
                        "TOPLEFT",
                        this.frame,
                        "TOPLEFT",
                        (action.left + (top + 1) * action.dx) / action.scale,
                        (action.top - (top + 1) * action.dy) / action.scale
                    );
                }
            }
            if (
                node.namedParams.size != "small" &&
                !node.namedParams.nocd &&
                profile.apparence.predictif
            ) {
                if (start) {
                    this.tracer.Log("****Second icon %s", start);
                    const target = this.ovaleGuid.UnitGUID(
                        actionTarget || "target"
                    );
                    if (target)
                        this.ovaleFuture.ApplySpell(
                            <number>actionId,
                            target,
                            start
                        );
                    let atTime = this.ovaleFuture.next.nextCast;
                    if (actionId != this.ovaleFuture.next.lastGCDSpellId) {
                        atTime = this.baseState.next.currentTime;
                    }
                    let [
                        timeSpan,
                        nextElement,
                    ] = this.ovaleBestAction.GetAction(node, atTime);
                    if (nextElement && nextElement.offgcd) {
                        start =
                            timeSpan.NextTime(
                                this.baseState.next.currentTime
                            ) || huge;
                    } else {
                        start = timeSpan.NextTime(atTime) || huge;
                    }
                    const [
                        actionTexture2,
                        actionInRange2,
                        actionCooldownStart2,
                        actionCooldownDuration2,
                        actionUsable2,
                        actionShortcut2,
                        actionIsCurrent2,
                        actionEnable2,
                        actionType2,
                        actionId2,
                        actionTarget2,
                        actionResourceExtend2,
                    ] = this.ovaleBestAction.GetActionInfo(nextElement, start);
                    icons[2].Update(
                        nextElement,
                        start,
                        actionTexture2,
                        actionInRange2,
                        actionCooldownStart2,
                        actionCooldownDuration2,
                        actionUsable2,
                        actionShortcut2,
                        actionIsCurrent2,
                        actionEnable2,
                        actionType2,
                        actionId2,
                        actionTarget2,
                        actionResourceExtend2
                    );
                } else {
                    icons[2].Update(element, undefined);
                }
            }
        }
    }

    UpdateFrame() {
        const profile = this.ovaleOptions.db.profile;
        if (this.hider.IsVisible()) {
            this.frame.ClearAllPoints();
            this.frame.SetPoint(
                "CENTER",
                this.hider,
                "CENTER",
                profile.apparence.offsetX,
                profile.apparence.offsetY
            );
            this.frame.EnableMouse(!profile.apparence.clickThru);
        }
        this.ReleaseChildren();
        this.UpdateIcons();
        this.UpdateControls();
        this.UpdateVisibility();
    }

    GetCheckBox(name: number | string) {
        let widget;
        if (type(name) == "string") {
            widget = this.checkBoxWidget[name];
        } else if (type(name) == "number") {
            let k = 0;
            for (const [, frame] of pairs(this.checkBoxWidget)) {
                if (k == name) {
                    widget = frame;
                    break;
                }
                k = k + 1;
            }
        }
        return widget;
    }
    IsChecked(name: string) {
        let widget = this.GetCheckBox(name);
        return widget && widget.GetValue();
    }
    GetListValue(name: string) {
        let widget = this.listWidget[name];
        return widget && widget.GetValue();
    }
    SetCheckBox(name: string, on: boolean) {
        let widget = this.GetCheckBox(name);
        if (widget) {
            let oldValue = widget.GetValue();
            if (oldValue != on) {
                widget.SetValue(on);
                this.OnCheckBoxValueChanged(widget);
            }
        }
    }
    ToggleCheckBox(name: string) {
        let widget = this.GetCheckBox(name);
        if (widget) {
            let on = !widget.GetValue();
            widget.SetValue(on);
            this.OnCheckBoxValueChanged(widget);
        }
    }

    OnCheckBoxValueChanged = (widget: AceGUIWidgetCheckBox) => {
        let name = widget.GetUserData<string>("name");
        this.ovaleOptions.db.profile.check[name] = widget.GetValue();
        this.ovaleFrameModule.module.SendMessage(
            "Ovale_CheckBoxValueChanged",
            name
        );
    };

    OnDropDownValueChanged = (widget: AceGUIWidgetDropDown) => {
        let name = widget.GetUserData<string>("name");
        this.ovaleOptions.db.profile.list[name] = widget.GetValue();
        this.ovaleFrameModule.module.SendMessage(
            "Ovale_ListValueChanged",
            name
        );
    };
    FinalizeString(s: string) {
        let [item, id] = strmatch(s, "^(item:)(.+)");
        if (item) {
            [s] = GetItemInfo(id);
        }
        return s;
    }

    UpdateControls() {
        let profile = this.ovaleOptions.db.profile;
        wipe(this.checkBoxWidget);
        for (const [name, checkBox] of pairs(checkBoxes)) {
            if (checkBox.text) {
                let widget = AceGUI.Create("CheckBox");
                let text = this.FinalizeString(checkBox.text);
                widget.SetLabel(text);
                if (profile.check[name] == undefined) {
                    profile.check[name] = checkBox.checked;
                }
                if (profile.check[name]) {
                    widget.SetValue(profile.check[name]);
                }
                widget.SetUserData("name", name);
                widget.SetCallback(
                    "OnValueChanged",
                    this.OnCheckBoxValueChanged
                );
                this.AddChild(widget);
                this.checkBoxWidget[name] = widget;
            } else {
                OneTimeMessage(
                    "Warning: checkbox '%s' is used but not defined.",
                    name
                );
            }
        }
        wipe(this.listWidget);
        for (const [name, list] of pairs(lists)) {
            if (next(list.items)) {
                let widget = AceGUI.Create("Dropdown");
                widget.SetList(list.items);
                if (!profile.list[name]) {
                    profile.list[name] = list.default;
                }
                if (profile.list[name]) {
                    widget.SetValue(profile.list[name]);
                }
                widget.SetUserData("name", name);
                widget.SetCallback(
                    "OnValueChanged",
                    this.OnDropDownValueChanged
                );
                this.AddChild(widget);
                this.listWidget[name] = widget;
            } else {
                OneTimeMessage(
                    "Warning: list '%s' is used but has no items.",
                    name
                );
            }
        }
    }

    UpdateIcons() {
        for (const [, action] of pairs(this.actions)) {
            for (const [, icon] of pairs(action.icons)) {
                icon.Hide();
            }
            for (const [, icon] of pairs(action.secureIcons)) {
                icon.Hide();
            }
        }
        const profile = this.ovaleOptions.db.profile;
        this.frame.EnableMouse(!profile.apparence.clickThru);
        let left = 0;
        let maxHeight = 0;
        let maxWidth = 0;
        let top = 0;
        let BARRE = 8;
        let margin = profile.apparence.margin;
        let iconNodes = this.ovaleCompile.GetIconNodes();
        for (const [k, node] of ipairs(iconNodes)) {
            if (!this.actions[k]) {
                this.actions[k] = {
                    icons: {},
                    secureIcons: {},
                    dx: 0,
                    dy: 0,
                    left: 0,
                    scale: 1,
                    top: 0,
                };
            }
            let action = this.actions[k];
            let width, height, newScale;
            let nbIcons;
            if (
                node.namedParams != undefined &&
                node.namedParams.size == "small"
            ) {
                newScale = profile.apparence.smallIconScale;
                width = newScale * 36 + margin;
                height = newScale * 36 + margin;
                nbIcons = 1;
            } else {
                newScale = profile.apparence.iconScale;
                width = newScale * 36 + margin;
                height = newScale * 36 + margin;
                if (
                    profile.apparence.predictif &&
                    node.namedParams.type != "value"
                ) {
                    nbIcons = 2;
                } else {
                    nbIcons = 1;
                }
            }
            if (top + height > profile.apparence.iconScale * 36 + margin) {
                top = 0;
                left = maxWidth;
            }
            action.scale = newScale;
            if (profile.apparence.vertical) {
                action.left = top;
                action.top = -left - BARRE - margin;
                action.dx = width;
                action.dy = 0;
            } else {
                action.left = left;
                action.top = -top - BARRE - margin;
                action.dx = 0;
                action.dy = height;
            }
            action.secure = node.secure;
            for (let l = 1; l <= nbIcons; l += 1) {
                let icon: OvaleIcon;
                if (!node.secure) {
                    if (!action.icons[l]) {
                        action.icons[l] = new OvaleIcon(
                            `Icon${k}n${l}`,
                            this,
                            false,
                            this.ovaleOptions,
                            this.ovaleSpellBook
                        );
                    }
                    icon = action.icons[l];
                } else {
                    if (!action.secureIcons[l]) {
                        action.secureIcons[l] = new OvaleIcon(
                            `SecureIcon${k}n${l}`,
                            this,
                            true,
                            this.ovaleOptions,
                            this.ovaleSpellBook
                        );
                    }
                    icon = action.secureIcons[l];
                }
                let scale = action.scale;
                if (l > 1) {
                    scale = scale * profile.apparence.secondIconScale;
                }
                icon.SetPoint(
                    "TOPLEFT",
                    this.frame,
                    "TOPLEFT",
                    (action.left + (l - 1) * action.dx) / scale,
                    (action.top - (l - 1) * action.dy) / scale
                );
                icon.SetScale(scale);
                icon.SetRemainsFont(profile.apparence.remainsFontColor);
                icon.SetFontScale(profile.apparence.fontScale);
                icon.SetParams(node.positionalParams, node.namedParams);
                icon.SetHelp(
                    (node.namedParams != undefined && node.namedParams.help) ||
                        undefined
                );
                icon.SetRangeIndicator(profile.apparence.targetText);
                icon.EnableMouse(!profile.apparence.clickThru);
                icon.frame.SetAlpha(profile.apparence.alpha);
                icon.cdShown = l == 1;
                if (this.skinGroup) {
                    this.skinGroup.AddButton(icon.frame);
                }
                if (l == 1) {
                    icon.Show();
                }
            }
            top = top + height;
            if (top > maxHeight) {
                maxHeight = top;
            }
            if (left + width > maxWidth) {
                maxWidth = left + width;
            }
        }

        this.content.SetAlpha(profile.apparence.optionsAlpha);

        if (profile.apparence.vertical) {
            this.barre.SetWidth(maxHeight - margin);
            this.barre.SetHeight(BARRE);
            this.frame.SetWidth(maxHeight + profile.apparence.iconShiftY);
            this.frame.SetHeight(
                maxWidth + BARRE + margin + profile.apparence.iconShiftX
            );
            this.content.SetPoint(
                "TOPLEFT",
                this.frame,
                "TOPLEFT",
                maxHeight + profile.apparence.iconShiftX,
                profile.apparence.iconShiftY
            );
        } else {
            this.barre.SetWidth(maxWidth - margin);
            this.barre.SetHeight(BARRE);
            this.frame.SetWidth(maxWidth);
            this.frame.SetHeight(maxHeight + BARRE + margin);
            this.content.SetPoint(
                "TOPLEFT",
                this.frame,
                "TOPLEFT",
                maxWidth + profile.apparence.iconShiftX,
                profile.apparence.iconShiftY
            );
        }
    }

    type = "Frame";
    //   frame: UIFrame;
    localstatus = {};
    actions: LuaArray<Action> = {};
    hider: UIFrame;
    updateFrame: UIFrame;
    // content: UIFrame;
    timeSinceLastUpdate: number;
    barre: UITexture;
    skinGroup?: MasqueSkinGroup;

    private tracer: Tracer;

    constructor(
        private ovaleState: OvaleStateClass,
        private ovaleFrameModule: OvaleFrameModuleClass,
        private ovaleCompile: OvaleCompileClass,
        private ovaleFuture: OvaleFutureClass,
        private baseState: BaseState,
        private ovaleEnemies: OvaleEnemiesClass,
        private ovale: OvaleClass,
        private ovaleOptions: OvaleOptionsClass,
        private ovaleDebug: OvaleDebugClass,
        private ovaleGuid: OvaleGUIDClass,
        private ovaleSpellFlash: OvaleSpellFlashClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private ovaleBestAction: OvaleBestActionClass,
        private combat: OvaleCombatClass
    ) {
        super();
        let hider = CreateFrame(
            "Frame",
            `${ovale.GetName()}PetBattleFrameHider`,
            UIParent,
            "SecureHandlerStateTemplate"
        );
        let newFrame = CreateFrame("Frame", undefined, hider);
        hider.SetAllPoints(UIParent);
        RegisterStateDriver(hider, "visibility", "[petbattle] hide; show");
        this.tracer = ovaleDebug.create("OvaleFrame");
        this.frame = newFrame;
        this.hider = hider;
        this.updateFrame = CreateFrame(
            "Frame",
            `${ovale.GetName()}UpdateFrame`
        );
        this.barre = this.frame.CreateTexture();
        this.content = CreateFrame("Frame", undefined, this.updateFrame);
        if (Masque) {
            this.skinGroup = Masque.Group(ovale.GetName());
        }
        this.timeSinceLastUpdate = INFINITY;
        newFrame.SetWidth(100);
        newFrame.SetHeight(100);
        newFrame.SetMovable(true);
        newFrame.SetFrameStrata("MEDIUM");
        newFrame.SetScript("OnMouseDown", () => {
            if (!ovaleOptions.db.profile.apparence.verrouille) {
                newFrame.StartMoving();
                AceGUI.ClearFocus();
            }
        });
        newFrame.SetScript("OnMouseUp", () => {
            newFrame.StopMovingOrSizing();
            let [x, y] = newFrame.GetCenter();
            const parent = newFrame.GetParent();
            if (parent) {
                const profile = ovaleOptions.db.profile;
                let [parentX, parentY] = parent.GetCenter();
                profile.apparence.offsetX = x - parentX;
                profile.apparence.offsetY = y - parentY;
            }
        });
        newFrame.SetScript("OnEnter", () => {
            const profile = ovaleOptions.db.profile;
            if (
                !(profile.apparence.enableIcons && profile.apparence.verrouille)
            ) {
                this.barre.Show();
            }
        });
        newFrame.SetScript("OnLeave", () => {
            this.barre.Hide();
        });
        newFrame.SetScript("OnHide", () => this.Hide());
        this.updateFrame.SetScript("OnUpdate", (updateFrame, elapsed) =>
            this.OnUpdate(elapsed)
        );
        this.barre.SetColorTexture(0.8, 0.8, 0.8, 0.5);
        this.barre.SetPoint("TOPLEFT", 0, 0);
        this.barre.Hide();
        let content = this.content;
        content.SetWidth(200);
        content.SetHeight(100);
        content.Hide();
        AceGUIRegisterAsContainer(this);
    }
}

export class OvaleFrameModuleClass {
    frame: OvaleFrame;

    private OnInitialize = () => {
        this.module.RegisterMessage(
            "Ovale_OptionChanged",
            this.Ovale_OptionChanged
        );
        this.module.RegisterMessage(
            "Ovale_CombatStarted",
            this.Ovale_CombatStarted
        );
        this.module.RegisterMessage(
            "Ovale_CombatEnded",
            this.Ovale_CombatEnded
        );
        this.module.RegisterEvent(
            "PLAYER_TARGET_CHANGED",
            this.PLAYER_TARGET_CHANGED
        );
        this.frame.UpdateFrame();
    };

    private handleDisable = () => {
        this.module.UnregisterMessage("Ovale_OptionChanged");
        this.module.UnregisterMessage("Ovale_CombatStarted");
        this.module.UnregisterMessage("Ovale_CombatEnded");
        this.module.UnregisterEvent("PLAYER_TARGET_CHANGED");
    };

    private Ovale_OptionChanged = (event: string, eventType: string) => {
        if (!this.frame) return;
        if (eventType == "visibility") {
            this.frame.UpdateVisibility();
        } else {
            // if (eventType == "layout") {
            //     this.frame.UpdateFrame(); // TODO
            // }
            this.frame.UpdateFrame();
        }
    };

    private PLAYER_TARGET_CHANGED = () => {
        this.frame.UpdateVisibility();
    };
    private Ovale_CombatStarted = (event: string, atTime: number) => {
        this.frame.UpdateVisibility();
    };
    private Ovale_CombatEnded = (event: string, atTime: number) => {
        this.frame.UpdateVisibility();
    };

    public module: AceModule & AceEvent;

    constructor(
        private ovaleState: OvaleStateClass,
        private ovaleCompile: OvaleCompileClass,
        private ovaleFuture: OvaleFutureClass,
        private baseState: BaseState,
        private ovaleEnemies: OvaleEnemiesClass,
        private ovale: OvaleClass,
        private ovaleOptions: OvaleOptionsClass,
        private ovaleDebug: OvaleDebugClass,
        private ovaleGuid: OvaleGUIDClass,
        private ovaleSpellFlash: OvaleSpellFlashClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private ovaleBestAction: OvaleBestActionClass,
        combat: OvaleCombatClass
    ) {
        this.module = ovale.createModule(
            "OvaleFrame",
            this.OnInitialize,
            this.handleDisable,
            aceEvent
        );
        this.frame = new OvaleFrame(
            this.ovaleState,
            this,
            this.ovaleCompile,
            this.ovaleFuture,
            this.baseState,
            this.ovaleEnemies,
            this.ovale,
            this.ovaleOptions,
            this.ovaleDebug,
            this.ovaleGuid,
            this.ovaleSpellFlash,
            this.ovaleSpellBook,
            this.ovaleBestAction,
            combat
        );
    }
}
