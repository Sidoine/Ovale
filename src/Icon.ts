import { L } from "./Localization";
import { format, find, sub } from "@wowts/string";
import { next, tostring, _G, kpairs } from "@wowts/lua";
import { GetTime, PlaySoundFile, UIFrame, UIFontString, UITexture, UICooldown, UICheckButton, CreateFrame, GameTooltip, UIPosition } from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { NamedParameters, PositionalParameters, AstNode } from "./AST";
import { OvaleOptionsClass } from "./Options";
import { OvaleSpellBookClass } from "./SpellBook";
let INFINITY = huge;
let COOLDOWN_THRESHOLD = 0.1;

interface IconParent {
    checkBoxWidget: any;
    listWidget: any;
    frame: UIFrame;
    ToggleOptions(): void; 
}

export class OvaleIcon {
    actionHelp: string | undefined;
    actionId: any;
    actionType: any;
    actionButton: boolean = false;
    namedParams: any;
    positionalParams: any;
    texture: string | undefined;
    cooldownStart: any;
    cooldownEnd: any;
    lastSound: any;
    fontScale: any;
    value: any;
    help: string | undefined;
    shouldClick: boolean = false;
    cdShown: boolean = false;
    focusText: UIFontString;
    fontFlags: any;
    fontHeight: any;
    fontName: any;
    normalTexture: UITexture;
    cd: UICooldown;
    rangeIndicator: UIFontString;
    remains: UIFontString;
    shortcut: UIFontString;
    icone: UITexture;
    frame: UICheckButton;

    HasScriptControls() {
        return (next(this.parent.checkBoxWidget) != undefined || next(this.parent.listWidget) != undefined);
    }

    constructor(name: string, private parent: IconParent, secure: boolean, private ovaleOptions: OvaleOptionsClass, private ovaleSpellBook: OvaleSpellBookClass) {
        if (!secure) {
            this.frame = CreateFrame("CheckButton", name, parent.frame, "ActionButtonTemplate");
        }        
        else{
            this.frame = CreateFrame("CheckButton", name, parent.frame, "SecureActionButtonTemplate, ActionButtonTemplate");
        }
        const profile = this.ovaleOptions.db.profile;
        this.icone = _G[`${name}Icon`];
        this.shortcut = _G[`${name}HotKey`];
        this.remains = _G[`${name}Name`];
        this.rangeIndicator = _G[`${name}Count`];
        this.rangeIndicator.SetText(profile.apparence.targetText);
        this.cd = _G[`${name}Cooldown`];
        this.normalTexture = _G[`${name}NormalTexture`];
        let [fontName, fontHeight, fontFlags] = this.shortcut.GetFont();
        this.fontName = fontName;
        this.fontHeight = fontHeight;
        this.fontFlags = fontFlags;
        this.focusText = this.frame.CreateFontString(undefined, "OVERLAY");
        this.cdShown = true;
        this.shouldClick = false;
        this.help = undefined;
        this.value = undefined;
        this.fontScale = undefined;
        this.lastSound = undefined;
        this.cooldownEnd = undefined;
        this.cooldownStart = undefined;
        this.texture = undefined;
        this.positionalParams = undefined;
        this.namedParams = undefined;
        this.actionButton = false;
        this.actionType = undefined;
        this.actionId = undefined;
        this.actionHelp = undefined;
        this.frame.SetScript("OnMouseUp", () => this.OvaleIcon_OnMouseUp());
        this.frame.SetScript("OnEnter", () => this.OvaleIcon_OnEnter());
        this.frame.SetScript("OnLeave", () => this.OvaleIcon_OnLeave());
        this.focusText.SetFontObject("GameFontNormalSmall");
        this.focusText.SetAllPoints(this.frame);
        this.focusText.SetTextColor(1, 1, 1);
        this.focusText.SetText(L["Focus"]);
        this.frame.RegisterForClicks("AnyUp");
        if (profile.apparence.clickThru) {
            this.frame.EnableMouse(false);
        }
    }

    SetValue(value: number | undefined, actionTexture: string | undefined) {
        this.icone.Show();
        this.icone.SetTexture(actionTexture);
        this.icone.SetAlpha(this.ovaleOptions.db.profile.apparence.alpha);
        this.cd.Hide();
        this.focusText.Hide();
        this.rangeIndicator.Hide();
        this.shortcut.Hide();
        if (value) {
            this.actionType = "value";
            this.actionHelp = undefined;
            this.value = value;
            if (value < 10) {
                this.remains.SetFormattedText("%.1f", value);
            } else if (value == INFINITY) {
                this.remains.SetFormattedText("inf");
            } else {
                this.remains.SetFormattedText("%d", value);
            }
            this.remains.Show();
        } else {
            this.remains.Hide();
        }
        this.frame.Show();
    }
    Update(element?: AstNode, startTime?: number, actionTexture?: string, actionInRange?: boolean, actionCooldownStart?: number, actionCooldownDuration?: number, actionUsable?: boolean, actionShortcut?: string, actionIsCurrent?: boolean, actionEnable?: boolean, actionType?: string, actionId?: string | number, actionTarget?: string, actionResourceExtend?: number) {
        this.actionType = actionType;
        this.actionId = actionId;
        this.value = undefined;
        let now = GetTime();
        const profile = this.ovaleOptions.db.profile;
        if (startTime && actionTexture) {
            let cd = this.cd;
            let resetCooldown = false;
            if (startTime > now) {
                let duration = cd.GetCooldownDuration();
                if (duration == 0 && this.texture == actionTexture && this.cooldownStart && this.cooldownEnd) {
                    resetCooldown = true;
                }
                if (this.texture != actionTexture || !this.cooldownStart || !this.cooldownEnd) {
                    this.cooldownStart = now;
                    this.cooldownEnd = startTime;
                    resetCooldown = true;
                } else if (startTime < this.cooldownEnd - COOLDOWN_THRESHOLD || startTime > this.cooldownEnd + COOLDOWN_THRESHOLD) {
                    if (startTime - this.cooldownEnd > 0.25 || startTime - this.cooldownEnd < -0.25) {
                        this.cooldownStart = now;
                    } else {
                        let oldCooldownProgressPercent = (now - this.cooldownStart) / (this.cooldownEnd - this.cooldownStart);
                        this.cooldownStart = (now - oldCooldownProgressPercent * startTime) / (1 - oldCooldownProgressPercent);
                    }
                    this.cooldownEnd = startTime;
                    resetCooldown = true;
                }
                this.texture = actionTexture;
            } else {
                this.cooldownStart = undefined;
                this.cooldownEnd = undefined;
            }
            if (this.cdShown && profile.apparence.flashIcon && this.cooldownStart && this.cooldownEnd) {
                let [start, ending] = [this.cooldownStart, this.cooldownEnd];
                let duration = ending - start;
                if (resetCooldown && duration > COOLDOWN_THRESHOLD) {
                    cd.SetDrawEdge(false);
                    cd.SetSwipeColor(0, 0, 0, 0.8);
                    cd.SetCooldown(start, duration);
                    cd.Show();
                }
            } else {
                this.cd.Hide();
            }
            this.icone.Show();
            this.icone.SetTexture(actionTexture);
            if (actionUsable) {
                this.icone.SetAlpha(1);
            } else {
                this.icone.SetAlpha(0.5);
            }

            if (element) {
                if (element.namedParams.nored != 1 && actionResourceExtend && actionResourceExtend > 0) {
                    this.icone.SetVertexColor(0.75, 0.2, 0.2);
                } else {
                    this.icone.SetVertexColor(1, 1, 1);
                }
                this.actionHelp = element.namedParams.help;
                if (!(this.cooldownStart && this.cooldownEnd)) {
                    this.lastSound = undefined;
                }
                if (element.namedParams.sound && !this.lastSound) {
                    let delay = element.namedParams.soundtime || 0.5;
                    if (now >= startTime - delay) {
                        this.lastSound = element.namedParams.sound;
                        PlaySoundFile(this.lastSound);
                    }
                }
            }

            let red = false; // TODO This value is not set anymore, find why
            if (!red && startTime > now && profile.apparence.highlightIcon) {
                let lag = 0.6;
                let newShouldClick = (startTime < now + lag);
                if (this.shouldClick != newShouldClick) {
                    if (newShouldClick) {
                        this.frame.SetChecked(true);
                    } else {
                        this.frame.SetChecked(false);
                    }
                    this.shouldClick = newShouldClick;
                }
            } else if (this.shouldClick) {
                this.shouldClick = false;
                this.frame.SetChecked(false);
            }
            if ((profile.apparence.numeric || this.namedParams.text == "always") && startTime > now) {
                this.remains.SetFormattedText("%.1f", startTime - now);
                this.remains.Show();
            } else {
                this.remains.Hide();
            }
            if (profile.apparence.raccourcis) {
                this.shortcut.Show();
                this.shortcut.SetText(actionShortcut);
            } else {
                this.shortcut.Hide();
            }
            if (actionInRange === undefined) {
                this.rangeIndicator.Hide();   
            } else if (actionInRange) {
                this.rangeIndicator.SetVertexColor(0.6, 0.6, 0.6);
                this.rangeIndicator.Show();
            } else {
                this.rangeIndicator.SetVertexColor(1.0, 0.1, 0.1);
                this.rangeIndicator.Show();
            } 
            if (element && element.namedParams.text) {
                this.focusText.SetText(tostring(element.namedParams.text));
                this.focusText.Show();
            } else if (actionTarget && actionTarget != "target") {
                this.focusText.SetText(actionTarget);
                this.focusText.Show();
            } else {
                this.focusText.Hide();
            }
            this.frame.Show();
        } else {
            this.icone.Hide();
            this.rangeIndicator.Hide();
            this.shortcut.Hide();
            this.remains.Hide();
            this.focusText.Hide();
            if (profile.apparence.hideEmpty) {
                this.frame.Hide();
            } else {
                this.frame.Show();
            }
            if (this.shouldClick) {
                this.frame.SetChecked(false);
                this.shouldClick = false;
            }
        }
        return [startTime, element];
    }
    SetHelp(help: string | undefined) {
        this.help = help;
    }
    SetParams(positionalParams: PositionalParameters, namedParams: NamedParameters, secure?: boolean) {
        this.positionalParams = positionalParams;
        this.namedParams = namedParams;
        this.actionButton = false;
        if (secure) {
            for (const [k, v] of kpairs(namedParams)) {
                let [index] = find(k, "spell");
                if (index) {
                    let prefix = sub(k, 1, index - 1);
                    let suffix = sub(k, index + 5);
                    this.frame.SetAttribute(`${prefix}type${suffix}`, "spell");
                    this.frame.SetAttribute("unit", this.namedParams.target || "target");
                    this.frame.SetAttribute(k, this.ovaleSpellBook.GetSpellName(<number>v) || "Unknown spell");
                    this.actionButton = true;
                }
            }
        }
    }
    SetRemainsFont(color: {r: number, g: number; b: number }) {
        this.remains.SetTextColor(color.r, color.g, color.b, 1.0);
        this.remains.SetJustifyH("left");
        this.remains.SetPoint("BOTTOMLEFT", 2, 2);
    }
    SetFontScale(scale: number) {
        this.fontScale = scale;
        this.remains.SetFont(this.fontName, this.fontHeight * this.fontScale, this.fontFlags);
        this.shortcut.SetFont(this.fontName, this.fontHeight * this.fontScale, this.fontFlags);
        this.rangeIndicator.SetFont(this.fontName, this.fontHeight * this.fontScale, this.fontFlags);
        this.focusText.SetFont(this.fontName, this.fontHeight * this.fontScale, this.fontFlags);
    }
    SetRangeIndicator(text: string) {
        this.rangeIndicator.SetText(text);
    }
    OvaleIcon_OnMouseUp() {
        if (!this.actionButton) {
            this.parent.ToggleOptions();
        }
        this.frame.SetChecked(true);
    }
    OvaleIcon_OnEnter() {
        if (this.help || this.actionType || this.HasScriptControls()) {
            GameTooltip.SetOwner(this.frame, "ANCHOR_BOTTOMLEFT");
            if (this.help) {
                GameTooltip.SetText(L[this.help]);
            }
            if (this.actionType) {
                let actionHelp: string;
                if (this.actionHelp) {
                    actionHelp = this.actionHelp
                }
                else {
                    if (this.actionType == "spell") {
                        actionHelp = this.ovaleSpellBook.GetSpellName(this.actionId) || "Unknown spell";
                    } else if (this.actionType == "value") {
                        actionHelp = (this.value < INFINITY) && tostring(this.value) || "infinity";
                    } else {
                        actionHelp = format("%s %s", this.actionType, tostring(this.actionId));
                    }
                }
                GameTooltip.AddLine(actionHelp, 0.5, 1, 0.75);
            }
            if (this.HasScriptControls()) {
                GameTooltip.AddLine(L["Cliquer pour afficher/cacher les options"], 1, 1, 1);
            }
            GameTooltip.Show();
        }
    }
    OvaleIcon_OnLeave() {
        if (this.help || this.HasScriptControls()) {
            GameTooltip.Hide();
        }
    }
    SetPoint(anchor: UIPosition, reference: UIFrame, refAnchor: UIPosition, x:number, y: number) {
        this.frame.SetPoint(anchor, reference, refAnchor, x, y);
    }

    Show(){
        this.frame.Show();
    }

    Hide() {
        this.frame.Hide();
    }

    SetScale(scale: number) {
        this.frame.SetScale(scale);
    }

    EnableMouse(enabled: boolean){
        this.frame.EnableMouse(enabled);
    }
}
