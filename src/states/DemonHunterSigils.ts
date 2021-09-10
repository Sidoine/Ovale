import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray, pairs } from "@wowts/lua";
import { AceModule } from "@wowts/tsaddon";
import { GetTime, SpellId, TalentId } from "@wowts/wow-mock";
import { OvaleClass } from "../Ovale";
import { DebugTools, Tracer } from "../engine/debug";
import { SpellCastEventHandler, States, StateModule } from "../engine/state";
import { Queue } from "../tools/Queue";
import { KeyCheck } from "../tools/tools";
import { OvalePaperDollClass } from "./PaperDoll";
import { OvaleSpellBookClass } from "./SpellBook";

class SigilData {
    chains: Queue<number>;
    flame: Queue<number>;
    kyrian: Queue<number>;
    misery: Queue<number>;
    silence: Queue<number>;

    constructor() {
        this.chains = new Queue<number>();
        this.flame = new Queue<number>();
        this.kyrian = new Queue<number>();
        this.misery = new Queue<number>();
        this.silence = new Queue<number>();
    }
}

type SigilType = keyof SigilData;

const checkSigilType: KeyCheck<SigilType> = {
    chains: true,
    flame: true,
    kyrian: true,
    misery: true,
    silence: true,
};

interface SigilInfo {
    type: SigilType;
    talent?: number;
}

const sigilTrigger: LuaArray<SigilInfo> = {
    [SpellId.elysian_decree]: {
        type: "kyrian",
    },
    [SpellId.infernal_strike]: {
        type: "flame",
        talent: TalentId.abyssal_strike_talent,
    },
    [SpellId.sigil_of_chains]: {
        type: "chains",
    },
    [SpellId.sigil_of_flame]: {
        type: "flame",
    },
    [SpellId.sigil_of_misery]: {
        type: "misery",
    },
    [SpellId.sigil_of_silence]: {
        type: "silence",
    },
};

export class OvaleSigilClass extends States<SigilData> implements StateModule {
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    // number of seconds a sigil charges before activation
    private chargeDuration = 2;

    constructor(
        private ovale: OvaleClass,
        debug: DebugTools,
        private paperDoll: OvalePaperDollClass,
        private spellBook: OvaleSpellBookClass
    ) {
        super(SigilData);
        this.module = ovale.createModule(
            "OvaleSigil",
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
            this.module.RegisterEvent(
                "UNIT_SPELLCAST_SUCCEEDED",
                this.onUnitSpellCastSucceeded
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
            this.module.UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
        }
    };

    private onOvaleSpecializationChanged = (
        event: string,
        newSpecialization: string,
        oldSpecialization: string
    ) => {
        if (newSpecialization === "vengeance") {
            this.module.RegisterMessage(
                "Ovale_TalentsChanged",
                this.onOvaleTalentsChanged
            );
            this.onOvaleTalentsChanged(event);
        }
    };

    private onOvaleTalentsChanged = (event: string) => {
        const talent = TalentId.quickened_sigils_talent;
        const hasQuickenedSigils = this.spellBook.getTalentPoints(talent) > 0;
        this.chargeDuration = 2;
        if (hasQuickenedSigils) {
            // Quickened Sigils talent reduces activation time by 1 second.
            this.chargeDuration -= 1;
        }
    };

    private onUnitSpellCastSucceeded = (
        event: string,
        unitId: string,
        guid: string,
        spellId: number
    ) => {
        if (unitId == "player") {
            if (sigilTrigger[spellId]) {
                const info = sigilTrigger[spellId];
                const sigilType = info.type;
                const talent = info.talent;
                if (!talent || this.spellBook.getTalentPoints(talent) > 0) {
                    const now = GetTime();
                    const state = this.current;
                    this.triggerSigil(state, sigilType, now);
                    const count = state[sigilType].length;
                    this.tracer.debug(
                        `"${sigilType}" (${count}) placed at ${now}`
                    );
                }
            }
        }
    };

    private triggerSigil = (
        state: SigilData,
        sigilType: SigilType,
        atTime: number
    ) => {
        const queue = state[sigilType];
        let activationTime = queue.front();
        while (activationTime && activationTime < atTime) {
            queue.shift();
            activationTime = queue.front();
        }
        activationTime = atTime + this.chargeDuration;
        queue.push(activationTime);
    };

    initializeState(): void {}

    resetState() {
        if (this.ovale.playerClass == "DEMONHUNTER") {
            for (const [sigilType] of pairs(checkSigilType)) {
                const current = this.current[sigilType as SigilType];
                const next = this.next[sigilType as SigilType];
                {
                    // TODO replace with next.clear() when available.
                    next.first = 0;
                    next.last = 0;
                    next.length = 0;
                }
                for (let i = 1; i <= current.length; i++) {
                    const activationTime = current.at(i);
                    if (activationTime) {
                        next.push(activationTime);
                    }
                }
            }
        }
    }

    cleanState(): void {}

    applySpellAfterCast: SpellCastEventHandler = (
        spellId,
        targetGUID,
        startCast,
        endCast,
        channel,
        spellcast
    ) => {
        if (this.ovale.playerClass == "DEMONHUNTER") {
            if (sigilTrigger[spellId]) {
                const info = sigilTrigger[spellId];
                const sigilType = info.type;
                const talent = info.talent;
                if (!talent || this.spellBook.getTalentPoints(talent) > 0) {
                    const state = this.next;
                    this.triggerSigil(state, sigilType, endCast);
                    const count = state[sigilType].length;
                    this.tracer.log(
                        `"${sigilType}" (${count}) placed at ${endCast}`
                    );
                }
            }
        }
    };

    isSigilCharging(sigilType: SigilType, atTime: number) {
        const queue = this.next[sigilType];
        for (let i = 1; i <= queue.length; i++) {
            const activationTime = queue.at(i);
            if (activationTime) {
                const start = activationTime - this.chargeDuration;
                if (start <= atTime && atTime < activationTime) {
                    return true;
                }
            }
        }
        return false;
    }
}
