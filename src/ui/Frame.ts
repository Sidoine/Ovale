import AceGUI, {
    AceGUIWidgetCheckBox,
    AceGUIWidgetDropDown,
} from "@wowts/ace_gui-3.0";
import Masque, { MasqueSkinGroup } from "@wowts/masque";
import { OvaleBestActionClass } from "../engine/best-action";
import { OvaleCompileClass } from "../engine/compile";
import { OvaleSpellFlashClass } from "./SpellFlash";
import { OvaleStateClass } from "../engine/state";
import { IconParent, OvaleIcon } from "./Icon";
import { OvaleEnemiesClass } from "../states/Enemies";
import { Controls } from "../engine/controls";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    LuaArray,
    ipairs,
    next,
    pairs,
    wipe,
    type,
    LuaObj,
    lualength,
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
import { WidgetContainer } from "./acegui-helpers";
import { OvaleFutureClass } from "../states/Future";
import { BaseState } from "../states/BaseState";
import { AstIconNode, AstNodeSnapshot } from "../engine/ast";
import { OvaleClass } from "../Ovale";
import { OvaleOptionsClass } from "./Options";
import { AceModule } from "@wowts/tsaddon";
import { DebugTools, Tracer } from "../engine/debug";
import { OvaleSpellBookClass } from "../states/SpellBook";
import { OvaleCombatClass } from "../states/combat";
import {
    isNumber,
    oneTimeMessage,
    printOneTimeMessages,
    stringify,
} from "../tools/tools";
import { Runner } from "../engine/runner";
import { insert } from "@wowts/table";
import LibTextDump, { TextDump } from "@wowts/lib_text_dump-1.0";
import { l } from "./Localization";
import { OvaleScriptsClass } from "../engine/scripts";
import { OvaleActionBarClass } from "../engine/action-bar";
import { Guids } from "../engine/guid";

const infinity = huge;
const dragHandlerHeight = 8;

interface Action {
    icons: LuaArray<OvaleIcon>;
    spellId?: number | string;
    waitStart?: number;
    left: number;
    top: number;
    scale: number;
    dx: number;
    dy: number;
}

class OvaleFrame extends WidgetContainer<UIFrame> implements IconParent {
    checkBoxWidget: LuaObj<AceGUIWidgetCheckBox> = {};
    listWidget: LuaObj<AceGUIWidgetDropDown> = {};
    visible = true;
    private traceLog: TextDump;

    toggleOptions() {
        if (this.content.IsShown()) {
            this.content.Hide();
        } else {
            this.content.Show();
        }
    }

    // eslint-disable-next-line @typescript-eslint/naming-convention
    Hide() {
        this.frame.Hide();
    }

    // eslint-disable-next-line @typescript-eslint/naming-convention
    Show() {
        this.frame.Show();
    }

    // eslint-disable-next-line @typescript-eslint/naming-convention
    OnAcquire() {
        this.frame.SetParent(UIParent);
    }

    // eslint-disable-next-line @typescript-eslint/naming-convention
    OnRelease() {}

    // eslint-disable-next-line @typescript-eslint/naming-convention
    OnWidthSet = (width: number) => {
        const content = this.content;
        let contentwidth = width;
        if (contentwidth < 0) {
            contentwidth = 0;
        }
        content.SetWidth(contentwidth);
    };

    // eslint-disable-next-line @typescript-eslint/naming-convention
    OnHeightSet = (height: number) => {
        const content = this.content;
        let contentheight = height;
        if (contentheight < 0) {
            contentheight = 0;
        }
        content.SetHeight(contentheight);
    };

    // OnLayoutFinished(width: number, height: number) {
    //     if (!width) {
    //         width = this.content.GetWidth();
    //     }
    //     this.content.SetWidth(width);
    //     this.content.SetHeight(height + 50);
    // }

    // TODO need to be moved elsewhere
    public getScore(spellId: number) {
        for (const [, action] of pairs(this.actions)) {
            if (action.spellId == spellId) {
                if (!action.waitStart) {
                    return 1;
                } else {
                    const now = this.baseState.currentTime;
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
        top: number,
        maxWidth: number,
        maxHeight: number
    ): [left: number, top: number, maxWidth: number, maxHeight: number] {
        const profile = this.ovaleOptions.db.profile;
        const margin = profile.apparence.margin;
        const width = action.scale * 36 + margin;
        const height = action.scale * 36 + margin;
        action.left = left;
        action.top = top;
        if (profile.apparence.vertical) {
            action.dx = 0;
            action.dy = -height;
        } else {
            action.dx = width;
            action.dy = 0;
        }
        if (left + width > maxWidth) maxWidth = left + width;
        if (height - top > maxHeight) maxHeight = height - top;
        left = left + action.dx;
        top = top + action.dy;
        return [left, top, maxWidth, maxHeight];
    }

    updateVisibility() {
        this.visible = true;
        const profile = this.ovaleOptions.db.profile;
        if (!profile.apparence.enableIcons) {
            this.visible = false;
        } else if (!this.petFrame.IsVisible()) {
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

    handleUpdate(elapsed: number) {
        this.ovaleFrameModule.module.SendMessage("Ovale_OnUpdate");
        this.timeSinceLastUpdate = this.timeSinceLastUpdate + elapsed;
        let refresh = false;
        if (this.ovaleDebug.trace) {
            // Always refresh if we are tracing the execution.
            refresh = true;
        } else if (this.visible || this.ovaleSpellFlash.isSpellFlashEnabled()) {
            /* Require that the Ovale frame be visible or that SpellFlash is
               enabled so Ovale is still triggering flashing buttons on the
               action bar. */
            const minSeconds =
                this.ovaleOptions.db.profile.apparence.minFrameRefresh / 1000;
            const maxSeconds =
                this.ovaleOptions.db.profile.apparence.maxFrameRefresh / 1000;
            if (
                this.timeSinceLastUpdate > minSeconds &&
                next(this.ovale.refreshNeeded)
            ) {
                // Throttle refreshes at every minSeconds.
                refresh = true;
            } else if (this.timeSinceLastUpdate > maxSeconds) {
                // Always refresh if more than maxSeconds have elapsed.
                refresh = true;
            }
        }
        if (refresh) {
            this.ovale.addRefreshInterval(this.timeSinceLastUpdate * 1000);
            this.ovaleState.initializeState();
            if (this.ovaleCompile.evaluateScript()) {
                this.updateFrame();
            }
            this.ovaleState.resetState();
            this.ovaleFuture.applyInFlightSpells();

            const profile = this.ovaleOptions.db.profile;
            const iconNodes = this.ovaleCompile.getIconNodes();
            let left = 0;
            let top = 0;
            let maxHeight = 0;
            let maxWidth = 0;
            const now = GetTime();

            for (const [k, node] of ipairs(iconNodes)) {
                const icon = this.actions[k];

                this.tracer.log("+++ Icon %d", k);
                const [element, atTime] = this.getIconAction(node);

                if (element && atTime) {
                    [left, top, maxWidth, maxHeight] = this.goNextIcon(
                        icon,
                        left,
                        top,
                        maxWidth,
                        maxHeight
                    );
                    for (const [, v] of ipairs(icon.icons)) {
                        v.Show();
                    }
                    let start;
                    if (element.type === "action" && element.offgcd) {
                        start = element.timeSpan.nextTime(
                            this.baseState.currentTime
                        );
                    } else {
                        start = element.timeSpan.nextTime(atTime);
                    }
                    if (profile.apparence.enableIcons) {
                        this.updateActionIcon(
                            icon,
                            element,
                            start || 0,
                            now,
                            node
                        );
                    }
                    if (profile.apparence.spellFlash.enabled) {
                        this.ovaleSpellFlash.flash(
                            node.cachedParams.named.flash as string | undefined,
                            node.cachedParams.named.help as string | undefined,
                            element,
                            start || 0,
                            k
                        );
                    }
                } else {
                    this.ovaleSpellFlash.hideFlash(k);
                    for (const [, v] of ipairs(icon.icons)) {
                        v.Hide();
                    }
                }
            }
            this.updateDragHandle(maxWidth, maxHeight);
            wipe(this.ovale.refreshNeeded);
            this.ovaleDebug.updateTrace();
            printOneTimeMessages();
            this.timeSinceLastUpdate = 0;
        }
    }

    private updateActionIcon(
        action: Action,
        element: AstNodeSnapshot,
        start: number,
        now: number,
        node: AstIconNode
    ) {
        const profile = this.ovaleOptions.db.profile;
        const icons = action.icons;
        for (let i = 1; i <= profile.apparence.numberOfIcons; i++) {
            if (i > 1) {
                if (element.type === "action") {
                    if (
                        element.actionType === "spell" &&
                        isNumber(element.actionId)
                    ) {
                        const atTime = this.ovaleFuture.next.nextCast;
                        start = element.timeSpan.nextTime(atTime) || huge;
                        this.ovaleFuture.applySpell(
                            element.actionId,
                            this.guids.getUnitGUID(
                                element.actionTarget || "target"
                            ),
                            start
                        );
                        this.ovaleBestAction.startNewAction();
                        element = this.ovaleBestAction.getAction(node, atTime);
                    }
                }
            }
            const icon = icons[i];
            if (element.type == "value") {
                let value;
                if (isNumber(element.value) && element.origin && element.rate) {
                    value =
                        element.value + (now - element.origin) * element.rate;
                }
                this.tracer.log("GetAction: start=%s, value=%f", start, value);
                icon.setValue(value, undefined);
            } else if (element.type === "none") {
                icon.setValue(undefined, undefined);
            } else if (element.type === "action") {
                if (
                    element.actionResourceExtend &&
                    element.actionResourceExtend > 0
                ) {
                    if (
                        element.actionCooldownDuration &&
                        element.actionCooldownDuration > 0
                    ) {
                        this.tracer.log(
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
                        this.tracer.log(
                            "Delaying spell ID '%s' for primary resource by %fs.",
                            element.actionId,
                            element.actionResourceExtend
                        );
                        start = start + element.actionResourceExtend;
                    }
                }

                this.tracer.log(
                    "GetAction: start=%s, id=%s",
                    start,
                    element.actionId
                );
                if (
                    element.actionType == "spell" &&
                    element.actionId ==
                        this.ovaleFuture.next.currentCast.spellId &&
                    start &&
                    this.ovaleFuture.next.nextCast &&
                    start < this.ovaleFuture.next.nextCast
                ) {
                    start = this.ovaleFuture.next.nextCast;
                }
                icon.update(element, start);
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
                    icon.cooldownStart &&
                    icon.cooldownEnd
                ) {
                    let ratio =
                        1 -
                        (now - icon.cooldownStart) /
                            (icon.cooldownEnd - icon.cooldownStart);
                    if (ratio < 0) {
                        ratio = 0;
                    } else if (ratio > 1) {
                        ratio = 1;
                    }
                    icon.setPoint(
                        "TOPLEFT",
                        this.iconsFrame,
                        "TOPLEFT",
                        (action.left + ratio * action.dx) / action.scale,
                        (action.top + ratio * action.dy) / action.scale
                    );
                }
            }

            if (!profile.apparence.moving) {
                icon.setPoint(
                    "TOPLEFT",
                    this.iconsFrame,
                    "TOPLEFT",
                    (action.left + action.dy * (i - 1)) / action.scale,
                    (action.top - action.dx * (i - 1)) / action.scale -
                        dragHandlerHeight -
                        profile.apparence.margin
                );
            }
        }
    }

    updateFrame() {
        const profile = this.ovaleOptions.db.profile;
        if (this.petFrame.IsVisible()) {
            this.frame.ClearAllPoints();
            this.frame.SetPoint(
                "CENTER",
                this.petFrame,
                "CENTER",
                profile.apparence.offsetX,
                profile.apparence.offsetY
            );
            this.frame.EnableMouse(!profile.apparence.clickThru);
        }
        this.ReleaseChildren();
        this.updateIcons();
        this.updateControls();
        this.updateVisibility();
    }

    getCheckBox(name: number | string) {
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
    isChecked(name: string) {
        const widget = this.getCheckBox(name);
        return widget && widget.GetValue();
    }
    getListValue(name: string) {
        const widget = this.listWidget[name];
        return widget && widget.GetValue();
    }
    setCheckBox(name: string, on: boolean) {
        const widget = this.getCheckBox(name);
        if (widget) {
            const oldValue = widget.GetValue();
            if (oldValue != on) {
                widget.SetValue(on);
                this.handleCheckBoxValueChanged(widget);
            }
        }
    }
    toggleCheckBox(name: string) {
        const widget = this.getCheckBox(name);
        if (widget) {
            const on = !widget.GetValue();
            widget.SetValue(on);
            this.handleCheckBoxValueChanged(widget);
        }
    }

    handleCheckBoxValueChanged = (widget: AceGUIWidgetCheckBox) => {
        const name = widget.GetUserData<string>("name");
        this.ovaleOptions.db.profile.check[name] = widget.GetValue();
        this.ovaleFrameModule.module.SendMessage(
            "Ovale_CheckBoxValueChanged",
            name
        );
    };

    handleDropDownValueChanged = (widget: AceGUIWidgetDropDown) => {
        const name = widget.GetUserData<string>("name");
        this.ovaleOptions.db.profile.list[name] = widget.GetValue();
        this.ovaleFrameModule.module.SendMessage(
            "Ovale_ListValueChanged",
            name
        );
    };
    finalizeString(s: string) {
        const [item, id] = match(s, "^(item:)(.+)");
        if (item) {
            [s] = GetItemInfo(id);
        }
        return s;
    }

    updateControls() {
        const profile = this.ovaleOptions.db.profile;
        wipe(this.checkBoxWidget);
        const atTime = this.ovaleFuture.next.nextCast;
        for (const [, checkBox] of ipairs(this.controls.checkBoxes)) {
            if (
                checkBox.text &&
                (!checkBox.enabled ||
                    this.runner.computeAsBoolean(checkBox.enabled, atTime))
            ) {
                const name = checkBox.name;
                const widget = AceGUI.Create("CheckBox");
                const text = this.finalizeString(checkBox.text);
                widget.SetLabel(text);
                if (profile.check[name] == undefined) {
                    profile.check[name] = checkBox.defaultValue;
                }
                if (profile.check[name]) {
                    widget.SetValue(profile.check[name]);
                }
                widget.SetUserData("name", name);
                widget.SetCallback(
                    "OnValueChanged",
                    this.handleCheckBoxValueChanged
                );
                this.AddChild(widget);
                this.checkBoxWidget[name] = widget;
            }
        }
        wipe(this.listWidget);
        for (const [, list] of ipairs(this.controls.lists)) {
            if (next(list.items)) {
                const widget = AceGUI.Create("Dropdown");
                const items: LuaObj<string> = {};
                const order: LuaArray<string> = {};
                for (const [, v] of ipairs(list.items)) {
                    if (
                        !v.enabled ||
                        this.runner.computeAsBoolean(v.enabled, atTime)
                    ) {
                        items[v.name] = v.text;
                        insert(order, v.name);
                    }
                }
                widget.SetList(items, order);
                const name = list.name;
                if (!profile.list[name]) {
                    profile.list[name] = list.defaultValue;
                }
                if (profile.list[name]) {
                    widget.SetValue(profile.list[name]);
                }
                widget.SetUserData("name", name);
                widget.SetCallback(
                    "OnValueChanged",
                    this.handleDropDownValueChanged
                );
                this.AddChild(widget);
                this.listWidget[name] = widget;
            } else {
                oneTimeMessage(
                    "Warning: list '%s' is used but has no items.",
                    list.name
                );
            }
        }
    }

    updateIcons() {
        for (const [, action] of pairs(this.actions)) {
            for (const [, icon] of ipairs(action.icons)) icon.Hide();
        }
        const profile = this.ovaleOptions.db.profile;
        this.frame.EnableMouse(!profile.apparence.clickThru);

        const iconNodes = this.ovaleCompile.getIconNodes();
        for (const [k, node] of ipairs(iconNodes)) {
            if (!this.actions[k]) {
                this.actions[k] = {
                    icons: {},
                    dx: 0,
                    dy: 0,
                    left: 0,
                    scale: 1,
                    top: 0,
                };
            }
            const action = this.actions[k];

            for (let i = 1; i <= profile.apparence.numberOfIcons; i++) {
                let icon = action.icons[i];
                if (icon === undefined) {
                    icon = new OvaleIcon(
                        k,
                        `Icon${k}${i}`,
                        this,
                        false,
                        this.ovaleOptions,
                        this.ovaleSpellBook,
                        this.actionBar
                    );
                    action.icons[i] = icon;
                }

                let newScale;
                if (
                    node.rawNamedParams.size != undefined &&
                    node.rawNamedParams.size.type === "string" &&
                    node.rawNamedParams.size.value === "small"
                ) {
                    newScale = profile.apparence.smallIconScale;
                } else {
                    newScale = profile.apparence.iconScale;
                }

                action.scale = newScale;

                let scale = action.scale;
                icon.setScale(scale);
                icon.setRemainsFont(profile.apparence.remainsFontColor);
                icon.setFontScale(profile.apparence.fontScale);
                icon.setParams(node.rawPositionalParams, node.rawNamedParams);
                icon.setHelp(
                    (node.rawNamedParams.help != undefined &&
                        node.rawNamedParams.help.type === "string" &&
                        node.rawNamedParams.help.value) ||
                        undefined
                );
                icon.setRangeIndicator(profile.apparence.targetText);
                icon.enableMouse(!profile.apparence.clickThru);
                icon.frame.SetAlpha(profile.apparence.alpha);
                icon.cdShown = true;
                if (this.skinGroup) {
                    this.skinGroup.AddButton(icon.frame);
                }
                icon.Show();
            }

            for (
                let i = profile.apparence.numberOfIcons + 1;
                i <= lualength(action.icons);
                i++
            ) {
                action.icons[i].Hide();
            }
        }

        this.content.SetAlpha(profile.apparence.optionsAlpha);
    }

    private updateDragHandle(maxWidth: number, maxHeight: number) {
        const profile = this.ovaleOptions.db.profile;
        const margin = profile.apparence.margin;
        this.dragHandleTexture.SetWidth(maxWidth - margin);
        this.dragHandleTexture.SetHeight(dragHandlerHeight);
        this.frame.SetWidth(maxWidth);
        this.frame.SetHeight(maxHeight + dragHandlerHeight + margin);
        this.content.SetPoint(
            "TOPLEFT",
            maxWidth + profile.apparence.iconShiftX,
            profile.apparence.iconShiftY - dragHandlerHeight
        );
    }

    type = "Frame";
    //   frame: UIFrame;
    localstatus = {};
    actions: LuaArray<Action> = {};

    iconsFrame: UIFrame;

    /** Only used to know the update interval, must be visible */
    updateIntervalFrame: UIFrame;

    timeSinceLastUpdate: number;

    /** Used to drag the frame */
    dragHandleTexture: UITexture;
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
        private ovaleDebug: DebugTools,
        private ovaleSpellFlash: OvaleSpellFlashClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private ovaleBestAction: OvaleBestActionClass,
        private combat: OvaleCombatClass,
        private runner: Runner,
        private controls: Controls,
        private scripts: OvaleScriptsClass,
        private actionBar: OvaleActionBarClass,
        private petFrame: UIFrame,
        private guids: Guids
    ) {
        super(CreateFrame("Frame", "OvaleIcons", petFrame));

        this.traceLog = LibTextDump.New(`Ovale - ${l.icon_snapshot}`, 750, 500);

        this.tracer = ovaleDebug.create("OvaleFrame");

        this.updateIntervalFrame = CreateFrame(
            "Frame",
            `${ovale.GetName()}UpdateFrame`
        );
        this.updateIntervalFrame.SetAllPoints(this.frame);
        this.updateIntervalFrame.Show();
        this.iconsFrame = CreateFrame("Frame", undefined, this.frame);
        this.iconsFrame.SetAllPoints(this.frame);
        this.dragHandleTexture = this.frame.CreateTexture();
        if (Masque) {
            this.skinGroup = Masque.Group(ovale.GetName());
        }
        this.timeSinceLastUpdate = infinity;
        const frame = this.frame;
        frame.SetWidth(100);
        frame.SetHeight(100);
        frame.SetMovable(true);
        frame.SetFrameStrata("MEDIUM");
        frame.SetScript("OnMouseDown", () => {
            if (!ovaleOptions.db.profile.apparence.verrouille) {
                frame.StartMoving();
                AceGUI.ClearFocus();
            }
        });
        frame.SetScript("OnMouseUp", () => {
            frame.StopMovingOrSizing();
            const [x, y] = frame.GetCenter();
            const parent = frame.GetParent();
            if (parent) {
                const profile = ovaleOptions.db.profile;
                const [parentX, parentY] = parent.GetCenter();
                profile.apparence.offsetX = x - parentX;
                profile.apparence.offsetY = y - parentY;
            }
        });
        frame.SetScript("OnEnter", () => {
            const profile = ovaleOptions.db.profile;
            if (
                !(profile.apparence.enableIcons && profile.apparence.verrouille)
            ) {
                this.dragHandleTexture.Show();
            }
        });
        frame.SetScript("OnLeave", () => {
            this.dragHandleTexture.Hide();
        });
        frame.SetScript("OnHide", () => this.Hide());
        this.updateIntervalFrame.SetScript("OnUpdate", (updateFrame, elapsed) =>
            this.handleUpdate(elapsed)
        );
        this.dragHandleTexture.SetColorTexture(0.8, 0.8, 0.8, 0.5);
        this.dragHandleTexture.SetPoint("TOPLEFT", 0, 0);
        this.dragHandleTexture.Hide();
        this.content.Hide();
    }

    debugIcon(index: number): void {
        const iconNodes = this.ovaleCompile.getIconNodes();
        this.tracer.print("%d", index);
        const [result, atTime] = this.getIconAction(iconNodes[index]);
        if (result && atTime) {
            const traceLog = this.traceLog;
            traceLog.Clear();
            const serial = result.serial;
            traceLog.AddLine(
                `{ "atTime": ${atTime}, "serial": ${serial}, "index": ${index}, "script": "${this.scripts.getScriptName(
                    this.scripts.getCurrentSpecScriptName()
                )}", "nodes": {`
            );
            let first = true;
            for (const [, node] of ipairs(
                iconNodes[index].annotation.nodeList
            )) {
                if (!node.result.constant) {
                    const nodeResult = node.result;
                    if (nodeResult.serial === serial) {
                        let serialized;
                        if (first) {
                            first = false;
                            serialized = "";
                        } else {
                            serialized = ",";
                        }
                        serialized += `"${node.nodeId}": {"result": ${stringify(
                            node.result
                        )}, "type": "${node.type}", "asString": ${stringify(
                            node.asString
                        )} }`;
                        traceLog.AddLine(serialized);
                    }
                }
            }
            traceLog.AddLine(`}, "result": ${stringify(result)} }`);
            traceLog.Display();

            this.ovaleDebug.trace = true;
            this.ovaleDebug.traceLog.Clear();
            this.ovaleState.resetState();
            this.ovaleFuture.applyInFlightSpells();
            this.getIconAction(iconNodes[index]);
            this.ovaleDebug.trace = false;
            this.ovaleDebug.displayTraceLog();
        }
    }

    public getIconAction(node: AstIconNode): [] | [AstNodeSnapshot, number] {
        if (
            node.rawNamedParams.target &&
            node.rawNamedParams.target.type === "string"
        ) {
            this.tracer.debug(
                `Default target is ${node.rawNamedParams.target.value}`
            );
            this.baseState.defaultTarget = node.rawNamedParams.target.value;
        } else {
            this.baseState.defaultTarget = "target";
        }
        if (
            node.rawNamedParams.enemies &&
            node.rawNamedParams.enemies.type === "value"
        ) {
            this.ovaleEnemies.next.enemies = node.rawNamedParams.enemies.value;
        } else {
            this.ovaleEnemies.next.enemies = undefined;
        }

        // This needs to be done here for each icon because
        // some node values depends on the defaultTarget and enemies values
        this.ovaleBestAction.startNewAction();
        let atTime = this.ovaleFuture.next.nextCast;
        if (
            this.ovaleFuture.next.currentCast.spellId == undefined ||
            this.ovaleFuture.next.currentCast.spellId !==
                this.ovaleFuture.next.lastGCDSpellId ||
            this.ovaleFuture.isChannelingAtTime(this.baseState.currentTime)
        ) {
            atTime = this.baseState.currentTime;
        }

        const [, namedParameters] = this.runner.computeParameters(node, atTime);

        if (namedParameters.enabled === undefined || namedParameters.enabled) {
            return [this.ovaleBestAction.getAction(node, atTime), atTime];
        }
        return [];
    }
}

export class OvaleFrameModuleClass {
    frame: OvaleFrame;

    private handleInitialize = () => {
        this.module.RegisterMessage(
            "Ovale_OptionChanged",
            this.handleOptionChanged
        );
        this.module.RegisterMessage(
            "Ovale_CombatStarted",
            this.handleCombatStarted
        );
        this.module.RegisterMessage(
            "Ovale_CombatEnded",
            this.handleCombatEnded
        );
        this.module.RegisterEvent(
            "PLAYER_TARGET_CHANGED",
            this.handlePlayerTargetChanged
        );
        this.frame.updateFrame();
    };

    private handleDisable = () => {
        this.module.UnregisterMessage("Ovale_OptionChanged");
        this.module.UnregisterMessage("Ovale_CombatStarted");
        this.module.UnregisterMessage("Ovale_CombatEnded");
        this.module.UnregisterEvent("PLAYER_TARGET_CHANGED");
    };

    private handleOptionChanged = (event: string, eventType: string) => {
        if (!this.frame) return;
        if (eventType == "visibility") {
            this.frame.updateVisibility();
        } else {
            // if (eventType == "layout") {
            //     this.frame.UpdateFrame(); // TODO
            // }
            this.frame.updateFrame();
        }
    };

    private handlePlayerTargetChanged = () => {
        this.frame.updateVisibility();
    };
    private handleCombatStarted = () => {
        this.frame.updateVisibility();
    };
    private handleCombatEnded = () => {
        this.frame.updateVisibility();
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
        private ovaleDebug: DebugTools,
        private ovaleSpellFlash: OvaleSpellFlashClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private ovaleBestAction: OvaleBestActionClass,
        combat: OvaleCombatClass,
        runner: Runner,
        controls: Controls,
        scripts: OvaleScriptsClass,
        actionBar: OvaleActionBarClass,
        guids: Guids
    ) {
        const petFrame = CreateFrame(
            "Frame",
            undefined,
            UIParent,
            "SecureHandlerStateTemplate"
        );
        RegisterStateDriver(petFrame, "visibility", "[petbattle] hide; show");
        petFrame.SetAllPoints(UIParent);
        this.module = ovale.createModule(
            "OvaleFrame",
            this.handleInitialize,
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
            runner,
            controls,
            scripts,
            actionBar,
            petFrame,
            guids
        );
    }
}
