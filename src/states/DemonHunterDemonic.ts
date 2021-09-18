import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray, LuaObj } from "@wowts/lua";
import { SpellId, TalentId } from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
import { DebugTools, Tracer } from "../engine/debug";
import { SpellCastEventHandler, StateModule } from "../engine/state";
import { OvaleClass } from "../Ovale";
import { OvaleAuraClass } from "./Aura";
import { OvalePaperDollClass } from "./PaperDoll";
import { OvaleSpellBookClass } from "./SpellBook";

const demonicTriggerId: LuaObj<LuaArray<boolean>> = {
    havoc: {
        [SpellId.eye_beam]: true,
    },
    vengeance: {
        [SpellId.fel_devastation]: true,
    },
};

const metamorphosisId: LuaObj<number> = {
    havoc: SpellId.metamorphosis,
    vengeance: SpellId.metamorphosis_vengeance,
};

export class OvaleDemonHunterDemonicClass implements StateModule {
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    private specialization = "havoc";
    private hasDemonicTalent = false;

    constructor(
        private aura: OvaleAuraClass,
        private paperDoll: OvalePaperDollClass,
        private spellBook: OvaleSpellBookClass,
        private ovale: OvaleClass,
        debug: DebugTools
    ) {
        this.module = ovale.createModule(
            "OvaleDemonHunterDemonic",
            this.onEnable,
            this.onDisable,
            aceEvent
        );
        this.tracer = debug.create(this.module.GetName());
    }

    private onEnable = () => {
        if (this.ovale.playerClass == "DEMONHUNTER") {
            this.module.RegisterMessage(
                "Ovale_SpecializationChanged",
                this.onOvaleSpecializationChanged
            );
            const specialization = this.paperDoll.getSpecialization();
            this.onOvaleSpecializationChanged(
                "onEnable",
                specialization,
                specialization
            );
        }
    };

    private onDisable = () => {
        if (this.ovale.playerClass == "DEMONHUNTER") {
            this.module.UnregisterMessage("Ovale_SpecializationChanged");
            this.module.UnregisterMessage("Ovale_TalentsChanged");
            this.hasDemonicTalent = false;
        }
    };

    private onOvaleSpecializationChanged = (
        event: string,
        newSpecialization: string,
        oldSpecialization: string
    ) => {
        this.specialization = newSpecialization;
        if (newSpecialization == "havoc" || newSpecialization == "vengeance") {
            this.tracer.debug("Installing Demonic event handlers.");
            this.module.RegisterMessage(
                "Ovale_TalentsChanged",
                this.onOvaleTalentsChanged
            );
            this.onOvaleTalentsChanged(event);
        } else {
            this.tracer.debug("Removing Demonic event handlers.");
            this.module.UnregisterMessage("Ovale_TalentsChanged");
            this.hasDemonicTalent = false;
        }
    };

    private onOvaleTalentsChanged = (event: string) => {
        const hasDemonicTalent = this.hasDemonicTalent;
        if (this.specialization == "havoc") {
            this.hasDemonicTalent =
                this.spellBook.getTalentPoints(TalentId.demonic_talent) > 0;
        } else if (this.specialization == "vengeance") {
            this.hasDemonicTalent =
                this.spellBook.getTalentPoints(
                    TalentId.demonic_talent_vengeance
                ) > 0;
        } else {
            this.hasDemonicTalent = false;
        }
        if (hasDemonicTalent != this.hasDemonicTalent) {
            if (this.hasDemonicTalent) {
                this.tracer.debug("Gained Demonic talent.");
            } else {
                this.tracer.debug("Lost Demonic talent.");
            }
        }
    };

    initializeState() {}
    resetState() {}
    cleanState() {}

    applySpellAfterCast: SpellCastEventHandler = (
        spellId,
        targetGUID,
        startCast,
        endCast,
        channel,
        spellcast
    ) => {
        if (
            this.hasDemonicTalent &&
            demonicTriggerId[this.specialization][spellId]
        ) {
            /*
             * Demonic grants 6 seconds of Metamorphosis, plus the
             * duration of the channeled spell.
             */
            const duration = 6 + ((channel && endCast - startCast) || 0);
            const atTime = (channel && startCast) || endCast;
            this.triggerMetamorphosis(atTime, duration);
        }
    };

    private triggerMetamorphosis = (atTime: number, duration: number) => {
        const auraId = metamorphosisId[this.specialization];
        this.tracer.log(`Triggering Demonic Metamorphosis (${auraId}).`);
        this.aura.addAuraToGUID(
            this.ovale.playerGUID,
            auraId,
            this.ovale.playerGUID,
            "HELPFUL",
            undefined,
            atTime,
            atTime + duration,
            atTime
        );
    };
}
