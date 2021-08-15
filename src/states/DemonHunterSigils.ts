import { OvalePaperDollClass } from "./PaperDoll";
import { OvaleSpellBookClass } from "./SpellBook";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { ipairs, LuaObj, LuaArray, tonumber, lualength } from "@wowts/lua";
import { insert, remove } from "@wowts/table";
import { GetTime, TalentId } from "@wowts/wow-mock";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import { CombatLogEvent, SpellPayloadHeader } from "../engine/combat-log-event";
import { StateModule } from "../engine/state";

const updateDelay = 0.5;
const sigilActivationTime = 2;
type SigilType = "flame" | "silence" | "misery" | "chains";
const activatedSigils: LuaObj<LuaArray<number>> = {};

interface Sigil {
    type: SigilType;
    talent?: number;
}

const sigilStart: LuaArray<Sigil> = {
    [204513]: {
        type: "flame",
    },
    [204596]: {
        type: "flame",
    },
    [189110]: {
        type: "flame",
        talent: TalentId.abyssal_strike_talent,
    },
    [202137]: {
        type: "silence",
    },
    [207684]: {
        type: "misery",
    },
    [202138]: {
        type: "chains",
    },
};
const sigilEnd: LuaArray<Sigil> = {
    [204598]: {
        type: "flame",
    },
    [204490]: {
        type: "silence",
    },
    [207685]: {
        type: "misery",
    },
    [204834]: {
        type: "chains",
    },
};

export class OvaleSigilClass implements StateModule {
    private module: AceModule & AceEvent;

    constructor(
        private ovalePaperDoll: OvalePaperDollClass,
        private ovale: OvaleClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private combatLogEvent: CombatLogEvent
    ) {
        this.module = ovale.createModule(
            "OvaleSigil",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        activatedSigils["flame"] = {};
        activatedSigils["silence"] = {};
        activatedSigils["misery"] = {};
        activatedSigils["chains"] = {};
    }

    private handleInitialize = () => {
        if (this.ovale.playerClass == "DEMONHUNTER") {
            this.module.RegisterEvent(
                "UNIT_SPELLCAST_SUCCEEDED",
                this.handleUnitSpellCastSucceeded
            );
            this.module.RegisterMessage(
                "Ovale_CombatLogEvent",
                this.handleOvaleCombatLogEvent
            );
            this.combatLogEvent.registerEvent("SPELL_AURA_APPLIED", this);
        }
    };
    private handleDisable = () => {
        if (this.ovale.playerClass == "DEMONHUNTER") {
            this.module.UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
            this.module.UnregisterMessage("Ovale_CombatLogEvent");
            this.combatLogEvent.unregisterEvent("SPELL_AURA_APPLIED", this);
        }
    };

    private handleOvaleCombatLogEvent = (event: string, cleuEvent: string) => {
        if (
            cleuEvent != "SPELL_AURA_APPLIED" ||
            !this.ovalePaperDoll.isSpecialization("vengeance")
        ) {
            return;
        }
        const cleu = this.combatLogEvent;
        const sourceGUID = cleu.sourceGUID;
        if (sourceGUID == this.ovale.playerGUID) {
            const header = cleu.header as SpellPayloadHeader;
            const spellId = header.spellId;
            if (sigilEnd[spellId] != undefined) {
                const s = sigilEnd[spellId];
                const t = s.type;
                remove(activatedSigils[t], 1);
            }
        }
    };

    private handleUnitSpellCastSucceeded = (
        event: string,
        unitId: string,
        guid: string,
        spellId: number,
        ...parameters: any[]
    ) => {
        if (!this.ovalePaperDoll.isSpecialization("vengeance")) {
            return;
        }
        if (unitId == undefined || unitId != "player") {
            return;
        }
        const id = tonumber(spellId);
        if (sigilStart[id] != undefined) {
            const s = sigilStart[id];
            const t = s.type;
            const tal = s.talent || undefined;
            if (
                tal == undefined ||
                this.ovaleSpellBook.getTalentPoints(tal) > 0
            ) {
                insert(activatedSigils[t], GetTime());
            }
        }
    };

    isSigilCharging(type: SigilType, atTime: number) {
        if (lualength(activatedSigils[type]) == 0) {
            return false;
        }
        let charging = false;
        for (const [, v] of ipairs(activatedSigils[type])) {
            let activationTime = sigilActivationTime + updateDelay;
            if (
                this.ovaleSpellBook.getTalentPoints(
                    TalentId.quickened_sigils_talent
                ) > 0
            ) {
                activationTime = activationTime - 1;
            }
            charging = charging || atTime < v + activationTime;
        }
        return charging;
    }
    cleanState(): void {}
    initializeState(): void {}
    resetState(): void {}
}
