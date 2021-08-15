import { OvaleAuraClass } from "./Aura";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { GetTime } from "@wowts/wow-mock";
import { LuaArray } from "@wowts/lua";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { OvalePaperDollClass } from "./PaperDoll";
import { CombatLogEvent, SpellPayloadHeader } from "../engine/combat-log-event";

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
        private ovalePaperDoll: OvalePaperDollClass,
        private combatLogEvent: CombatLogEvent
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
            this.module.RegisterMessage(
                "Ovale_CombatLogEvent",
                this.handleOvaleCombatLogEvent
            );
            this.combatLogEvent.registerEvent("SPELL_CAST_SUCCESS", this);
        }
    };

    private handleDisable = () => {
        if (this.ovale.playerClass == "DEMONHUNTER") {
            this.module.UnregisterMessage("Ovale_CombatLogEvent");
            this.combatLogEvent.unregisterEvent("SPELL_CAST_SUCCESS", this);
        }
    };
    private handleOvaleCombatLogEvent = (event: string, cleuEvent: string) => {
        if (
            cleuEvent != "SPELL_CAST_SUCCESS" ||
            !this.ovalePaperDoll.isSpecialization("vengeance")
        ) {
            return;
        }
        const cleu = this.combatLogEvent;
        const sourceGUID = cleu.sourceGUID;
        const me = this.ovale.playerGUID;
        if (sourceGUID == me) {
            const header = cleu.header as SpellPayloadHeader;
            const spellId = header.spellId;
            if (soulFragmentSpells[spellId]) {
                const now = GetTime();
                let fragments = soulFragmentSpells[spellId];
                if (fragments > 0 && this.hasMetamorphosis(now)) {
                    fragments = fragments + 1;
                }
                this.addPredictedSoulFragments(now, fragments);
            } else if (soulFragmentFinishers[spellId]) {
                const now = GetTime();
                this.setPredictedSoulFragment(now, 0);
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
