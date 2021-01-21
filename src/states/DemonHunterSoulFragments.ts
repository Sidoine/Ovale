import { OvaleAuraClass } from "./Aura";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { GetTime, CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { LuaArray } from "@wowts/lua";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { OvalePaperDollClass } from "./PaperDoll";

const soulFragmentsBuffId = 203981;
const metamorphosisBuffId = 187827;
const soulFragmentSpells: LuaArray<number> = {
    [225919]: 2, // Fracture
    [203782]: 1, // Shear
    [228477]: -2, // Soul Cleave
};
const soulFragmentFinishers: LuaArray<boolean> = {
    [247454]: true, // Spirit Bomb
    [263648]: true, // Soul Barrier
};

export class OvaleDemonHunterSoulFragmentsClass {
    estimatedCount = 0;
    atTime?: number;
    estimated?: boolean;
    private module: AceModule & AceEvent;

    constructor(
        private ovaleAura: OvaleAuraClass,
        private ovale: OvaleClass,
        private ovalePaperDoll: OvalePaperDollClass
    ) {
        this.module = ovale.createModule(
            "OvaleDemonHunterSoulFragments",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
    }

    private handleInitialize = () => {
        if (this.ovale.playerClass == "DEMONHUNTER") {
            this.module.RegisterEvent(
                "COMBAT_LOG_EVENT_UNFILTERED",
                this.handleCombatLogEventUnfiltered
            );
        }
    };

    private handleDisable = () => {
        if (this.ovale.playerClass == "DEMONHUNTER") {
            this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    };
    private handleCombatLogEventUnfiltered = (
        event: string,
        ...parameters: any[]
    ) => {
        if (!this.ovalePaperDoll.isSpecialization("vengeance")) {
            return;
        }
        const [
            ,
            subtype,
            ,
            sourceGUID,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            spellID,
        ] = CombatLogGetCurrentEventInfo();
        const me = this.ovale.playerGUID;
        if (sourceGUID == me) {
            if (
                subtype == "SPELL_CAST_SUCCESS" &&
                soulFragmentSpells[spellID]
            ) {
                const getTime = GetTime();
                let fragments = soulFragmentSpells[spellID];
                if (fragments > 0 && this.hasMetamorphosis(getTime)) {
                    fragments = fragments + 1;
                }
                this.addPredictedSoulFragments(getTime, fragments);
            }
            if (
                subtype == "SPELL_CAST_SUCCESS" &&
                soulFragmentFinishers[spellID]
            ) {
                this.setPredictedSoulFragment(GetTime(), 0);
            }
        }
    };
    addPredictedSoulFragments(atTime: number, added: number) {
        const currentCount = this.getSoulFragmentsBuffStacks(atTime) || 0;
        this.setPredictedSoulFragment(atTime, currentCount + added);
    }
    setPredictedSoulFragment(atTime: number, count: number) {
        this.estimatedCount = (count < 0 && 0) || (count > 5 && 5) || count;
        this.atTime = atTime;
        this.estimated = true;
    }
    soulFragments(atTime: number) {
        // TODO Need to add parameters greater and demon
        let stacks = this.getSoulFragmentsBuffStacks(atTime);
        if (this.estimated) {
            if (atTime - (this.atTime || 0) < 1.2) {
                stacks = this.estimatedCount;
            } else {
                this.estimated = false;
            }
        }
        return stacks;
    }
    getSoulFragmentsBuffStacks(atTime: number) {
        const aura = this.ovaleAura.getAura(
            "player",
            soulFragmentsBuffId,
            atTime,
            "HELPFUL",
            true
        );
        const stacks =
            (aura &&
                this.ovaleAura.isActiveAura(aura, atTime) &&
                aura.stacks) ||
            0;
        return stacks;
    }
    hasMetamorphosis(atTime: number) {
        const aura = this.ovaleAura.getAura(
            "player",
            metamorphosisBuffId,
            atTime,
            "HELPFUL",
            true
        );
        return (aura && this.ovaleAura.isActiveAura(aura, atTime)) || false;
    }
}
