import AceGUI, {
    AceGUIWidgetCheckBox,
    AceGUIWidgetDropDown,
} from "@wowts/ace_gui-3.0";
import Masque, { MasqueSkinGroup } from "@wowts/masque";
import { OvaleBestActionClass } from "../engine/BestAction";
import { OvaleCompileClass } from "../engine/Compile";
import { OvaleSpellFlashClass } from "./SpellFlash";
import { OvaleStateClass } from "../engine/State";
import { OvaleIcon } from "./Icon";
import { OvaleEnemiesClass } from "../states/Enemies";
import { lists, checkBoxes } from "../engine/Controls";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray, ipairs, next, pairs, wipe, type, LuaObj } from "@wowts/lua";
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
import { OvaleFutureClass } from "../states/Future";
import { BaseState } from "../states/BaseState";
import { AstNodeSnapshot } from "../engine/AST";
import { OvaleClass } from "../Ovale";
import { OvaleOptionsClass } from "./Options";
import { AceModule } from "@wowts/tsaddon";
import { OvaleDebugClass, Tracer } from "../engine/Debug";
import { OvaleSpellBookClass } from "../states/SpellBook";
import { OvaleCombatClass } from "../states/combat";
import { isNumber, OneTimeMessage, PrintOneTimeMessages } from "../tools/tools";
import { Runner } from "../engine/runner";

const strmatch = match;
const INFINITY = huge;
const BARRE = 8;

interface Action {
    secure?: boolean;
    secureIcons: LuaArray<OvaleIcon>;
    icons: LuaArray<OvaleIcon>;
    spellId?: number | string;
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
    visible = true;

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
        const content = this.content;
        let contentwidth = width - 34;
        if (contentwidth < 0) {
            contentwidth = 0;
        }
        content.SetWidth(contentwidth);
    }

    OnHeightSet(height: number) {
        const content = this.content;
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
                    const now = this.baseState.current.currentTime;
                    const lag = now - action.waitStart;
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

    private goNextIcon(
        action: Action,
        left: number,
        top: number
    ): [left: number, top: number] {
        const BARRE = 8;
        const profile = this.ovaleOptions.db.profile;
        const margin = profile.apparence.margin;
        const width = action.scale * 36 + margin;
        const height = action.scale * 36 + margin;
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
        // top = top + height;
        left = left + width;
        return [left, top];
    }

    UpdateVisibility() {
        this.visible = true;
        const profile = this.ovaleOptions.db.profile;
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
        const refresh =
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
            let left = 0;
            let top = 0;
            const maxHeight = 0;

            for (const [k, node] of ipairs(iconNodes)) {
                const action = this.actions[k];
                if (
                    node.rawNamedParams.target &&
                    node.rawNamedParams.target.type === "string"
                ) {
                    this.tracer.Debug(
                        `Default target is ${node.rawNamedParams.target.value}`
                    );
                    this.baseState.current.defaultTarget =
                        node.rawNamedParams.target.value;
                } else {
                    this.baseState.current.defaultTarget = "target";
                }
                if (
                    node.rawNamedParams.enemies &&
                    node.rawNamedParams.enemies.type === "value"
                ) {
                    this.ovaleEnemies.next.enemies =
                        node.rawNamedParams.enemies.value;
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
                const [, namedParameters] = this.runner.computeParameters(
                    node,
                    atTime
                );
                if (
                    namedParameters.enabled === undefined ||
                    namedParameters.enabled
                ) {
                    [left, top] = this.goNextIcon(action, left, top);
                    action.icons[1].Show();
                    const element = this.ovaleBestAction.GetAction(
                        node,
                        atTime
                    );
                    let start;
                    if (element.type === "action" && element.offgcd) {
                        start = element.timeSpan.NextTime(
                            this.baseState.next.currentTime
                        );
                    } else {
                        start = element.timeSpan.NextTime(atTime);
                    }
                    if (profile.apparence.enableIcons) {
                        this.UpdateActionIcon(action, element, start || 0);
                    }
                    if (profile.apparence.spellFlash.enabled) {
                        this.ovaleSpellFlash.Flash(
                            node.cachedParams.named.flash as string | undefined,
                            node.cachedParams.named.help as string | undefined,
                            element,
                            start || 0
                        );
                    }
                } else {
                    action.icons[1].Hide();
                }
            }
            this.updateBarSize(left, maxHeight);
            wipe(this.ovale.refreshNeeded);
            this.ovaleDebug.UpdateTrace();
            PrintOneTimeMessages();
            this.timeSinceLastUpdate = 0;
        }
    }

    UpdateActionIcon(
        action: Action,
        element: AstNodeSnapshot,
        start: number,
        now?: number
    ) {
        const profile = this.ovaleOptions.db.profile;
        const icons = (action.secure && action.secureIcons) || action.icons;
        now = now || GetTime();
        if (element.type == "value") {
            let value;
            if (isNumber(element.value) && element.origin && element.rate) {
                value = element.value + (now - element.origin) * element.rate;
            }
            this.tracer.Log("GetAction: start=%s, value=%f", start, value);
            // let actionTexture;
            // if (node.texture) {
            //     actionTexture = node.namedParams.texture;
            // }
            icons[1].SetValue(value, undefined);
            // if (lualength(icons) > 1) {
            //     icons[2].Update(element, undefined);
            // }
        } else if (element.type === "none") {
            icons[1].SetValue(undefined, undefined);
        } else if (element.type === "action") {
            if (
                element.actionResourceExtend &&
                element.actionResourceExtend > 0
            ) {
                if (
                    element.actionCooldownDuration &&
                    element.actionCooldownDuration > 0
                ) {
                    this.tracer.Log(
                        "Extending cooldown of spell ID '%s' for primary resource by %fs.",
                        element.actionId,
                        element.actionResourceExtend
                    );
                    element.actionCooldownDuration =
                        element.actionCooldownDuration +
                        element.actionResourceExtend;
                } else if (
                    element.options &&
                    element.options.pool_resource == 1
                ) {
                    this.tracer.Log(
                        "Delaying spell ID '%s' for primary resource by %fs.",
                        element.actionId,
                        element.actionResourceExtend
                    );
                    start = start + element.actionResourceExtend;
                }
            }

            this.tracer.Log(
                "GetAction: start=%s, id=%s",
                start,
                element.actionId
            );
            if (
                element.actionType == "spell" &&
                element.actionId == this.ovaleFuture.next.currentCast.spellId &&
                start &&
                this.ovaleFuture.next.nextCast &&
                start < this.ovaleFuture.next.nextCast
            ) {
                start = this.ovaleFuture.next.nextCast;
            }
            if (
                start &&
                element.options &&
                isNumber(element.options.nocd) &&
                now < start - element.options.nocd
            ) {
                icons[1].Update(element, undefined);
            } else {
                icons[1].Update(element, start);
            }
            if (element.actionType == "spell") {
                action.spellId = element.actionId;
            } else {
                action.spellId = undefined;
            }
            if (start && start <= now && element.actionUsable) {
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
            // if (
            //     node.namedParams.size != "small" &&
            //     !node.namedParams.nocd &&
            //     profile.apparence.predictif
            // ) {
            //     if (start) {
            //         this.tracer.Log("****Second icon %s", start);
            //         const target = this.ovaleGuid.UnitGUID(
            //             actionTarget || "target"
            //         );
            //         if (target)
            //             this.ovaleFuture.ApplySpell(
            //                 <number>actionId,
            //                 target,
            //                 start
            //             );
            //         let atTime = this.ovaleFuture.next.nextCast;
            //         if (actionId != this.ovaleFuture.next.lastGCDSpellId) {
            //             atTime = this.baseState.next.currentTime;
            //         }
            //         let [
            //             timeSpan,
            //             nextElement,
            //         ] = this.ovaleBestAction.GetAction(node, atTime);
            //         if (nextElement && nextElement.offgcd) {
            //             start =
            //                 timeSpan.NextTime(
            //                     this.baseState.next.currentTime
            //                 ) || huge;
            //         } else {
            //             start = timeSpan.NextTime(atTime) || huge;
            //         }
            //         const [
            //             actionTexture2,
            //             actionInRange2,
            //             actionCooldownStart2,
            //             actionCooldownDuration2,
            //             actionUsable2,
            //             actionShortcut2,
            //             actionIsCurrent2,
            //             actionEnable2,
            //             actionType2,
            //             actionId2,
            //             actionTarget2,
            //             actionResourceExtend2,
            //         ] = this.ovaleBestAction.GetActionInfo(nextElement, start);
            //         icons[2].Update(
            //             nextElement,
            //             start,
            //             actionTexture2,
            //             actionInRange2,
            //             actionCooldownStart2,
            //             actionCooldownDuration2,
            //             actionUsable2,
            //             actionShortcut2,
            //             actionIsCurrent2,
            //             actionEnable2,
            //             actionType2,
            //             actionId2,
            //             actionTarget2,
            //             actionResourceExtend2
            //         );
            //     } else {
            //         icons[2].Update(element, undefined);
            //     }
            // }
        }

        if (!profile.apparence.moving) {
            icons[1].SetPoint(
                "TOPLEFT",
                this.frame,
                "TOPLEFT",
                action.left / action.scale,
                action.top / action.scale
            );
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
        const widget = this.GetCheckBox(name);
        return widget && widget.GetValue();
    }
    GetListValue(name: string) {
        const widget = this.listWidget[name];
        return widget && widget.GetValue();
    }
    SetCheckBox(name: string, on: boolean) {
        const widget = this.GetCheckBox(name);
        if (widget) {
            const oldValue = widget.GetValue();
            if (oldValue != on) {
                widget.SetValue(on);
                this.OnCheckBoxValueChanged(widget);
            }
        }
    }
    ToggleCheckBox(name: string) {
        const widget = this.GetCheckBox(name);
        if (widget) {
            const on = !widget.GetValue();
            widget.SetValue(on);
            this.OnCheckBoxValueChanged(widget);
        }
    }

    OnCheckBoxValueChanged = (widget: AceGUIWidgetCheckBox) => {
        const name = widget.GetUserData<string>("name");
        this.ovaleOptions.db.profile.check[name] = widget.GetValue();
        this.ovaleFrameModule.module.SendMessage(
            "Ovale_CheckBoxValueChanged",
            name
        );
    };

    OnDropDownValueChanged = (widget: AceGUIWidgetDropDown) => {
        const name = widget.GetUserData<string>("name");
        this.ovaleOptions.db.profile.list[name] = widget.GetValue();
        this.ovaleFrameModule.module.SendMessage(
            "Ovale_ListValueChanged",
            name
        );
    };
    FinalizeString(s: string) {
        const [item, id] = strmatch(s, "^(item:)(.+)");
        if (item) {
            [s] = GetItemInfo(id);
        }
        return s;
    }

    UpdateControls() {
        const profile = this.ovaleOptions.db.profile;
        wipe(this.checkBoxWidget);
        for (const [name, checkBox] of pairs(checkBoxes)) {
            if (checkBox.text) {
                const widget = AceGUI.Create("CheckBox");
                const text = this.FinalizeString(checkBox.text);
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
                const widget = AceGUI.Create("Dropdown");
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
        const margin = profile.apparence.margin;
        const iconNodes = this.ovaleCompile.GetIconNodes();
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
            const action = this.actions[k];
            let width, height, newScale;
            let nbIcons;
            if (
                node.rawNamedParams.size != undefined &&
                node.rawNamedParams.size.type === "string" &&
                node.rawNamedParams.size.value === "small"
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
                    node.rawNamedParams.type !== undefined &&
                    node.rawNamedParams.type.type === "string" &&
                    node.rawNamedParams.type.value !== "value"
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
            action.secure =
                node.rawNamedParams.secure &&
                node.rawNamedParams.secure.type === "value";
            for (let l = 1; l <= nbIcons; l += 1) {
                let icon: OvaleIcon;
                if (!action.secure) {
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
                icon.SetScale(scale);
                icon.SetRemainsFont(profile.apparence.remainsFontColor);
                icon.SetFontScale(profile.apparence.fontScale);
                icon.SetParams(node.rawPositionalParams, node.rawNamedParams);
                icon.SetHelp(
                    (node.rawNamedParams.help != undefined &&
                        node.rawNamedParams.help.type === "string" &&
                        node.rawNamedParams.help.value) ||
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
        this.updateBarSize(maxWidth, maxHeight);
    }

    private updateBarSize(maxWidth: number, maxHeight: number) {
        const profile = this.ovaleOptions.db.profile;
        const margin = profile.apparence.margin;
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
        private ovaleSpellFlash: OvaleSpellFlashClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private ovaleBestAction: OvaleBestActionClass,
        private combat: OvaleCombatClass,
        private runner: Runner
    ) {
        super();
        const hider = CreateFrame(
            "Frame",
            `${ovale.GetName()}PetBattleFrameHider`,
            UIParent,
            "SecureHandlerStateTemplate"
        );
        const newFrame = CreateFrame("Frame", undefined, hider);
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
            const [x, y] = newFrame.GetCenter();
            const parent = newFrame.GetParent();
            if (parent) {
                const profile = ovaleOptions.db.profile;
                const [parentX, parentY] = parent.GetCenter();
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
        const content = this.content;
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
    private Ovale_CombatStarted = () => {
        this.frame.UpdateVisibility();
    };
    private Ovale_CombatEnded = () => {
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
        private ovaleSpellFlash: OvaleSpellFlashClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private ovaleBestAction: OvaleBestActionClass,
        combat: OvaleCombatClass,
        runner: Runner
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
            this.ovaleSpellFlash,
            this.ovaleSpellBook,
            this.ovaleBestAction,
            combat,
            runner
        );
    }
}
