import { AceModule } from "@wowts/tsaddon";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { DebugTools, Tracer } from "../engine/debug";
import { OvaleClass } from "../Ovale";
import { LuaArray } from "@wowts/lua";
import {
    ConditionFunction,
    OvaleConditionClass,
    returnBoolean,
} from "../engine/condition";
import { AstFunctionNode, NamedParametersOf } from "../engine/ast";
import { GetSpellInfo } from "@wowts/wow-mock";

export class SpellActivationGlow {
    private module: AceModule & AceEvent;
    private debug: Tracer;
    private spellActivationSpellsShown: LuaArray<boolean> = {};

    constructor(ovale: OvaleClass, ovaleDebug: DebugTools) {
        this.module = ovale.createModule(
            "SpellActivation",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.debug = ovaleDebug.create("SpellActivationGlow");
    }

    private handleInitialize = () => {
        this.module.RegisterEvent(
            "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW",
            this.handleSpellActivationOverlayGlow
        );
        this.module.RegisterEvent(
            "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE",
            this.handleSpellActivationOverlayGlow
        );
    };

    private handleDisable = () => {
        this.module.UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW");
        this.module.UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE");
    };

    private handleSpellActivationOverlayGlow = (
        event: string,
        spellId: number
    ) => {
        const spellName = GetSpellInfo(spellId);
        this.debug.debug(
            "Event %s with spellId %d (%s)",
            event,
            spellId,
            spellName
        );
        this.spellActivationSpellsShown[spellId] =
            event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" || false;
    };

    hasSpellActivationGlow(spellId: number) {
        return this.spellActivationSpellsShown[spellId] || false;
    }

    public registerConditions(ovaleCondition: OvaleConditionClass) {
        ovaleCondition.registerCondition(
            "spellactivationglowactive",
            false,
            this.spellActivationGlowActive
        );
        ovaleCondition.registerAlias(
            "spellactivationglowactive",
            "spellactivationglowshown"
        );
    }

    private spellActivationGlowActive: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const retValue = this.hasSpellActivationGlow(spellId) || false;
        return returnBoolean(retValue);
    };
}
