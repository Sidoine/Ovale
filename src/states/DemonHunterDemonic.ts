import { OvaleAuraClass } from "./Aura";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    GetSpecialization,
    GetSpecializationInfo,
    GetTime,
    GetTalentInfoByID,
    CombatLogGetCurrentEventInfo,
} from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { select } from "@wowts/lua";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import { OvaleDebugClass, Tracer } from "../engine/debug";

const INFINITY = huge;
const HAVOC_DEMONIC_TALENT_ID = 22547;
const HAVOC_SPEC_ID = 577;
const HAVOC_EYE_BEAM_SPELL_ID = 198013;
const HAVOC_META_BUFF_ID = 162264;
const HIDDEN_BUFF_ID = -HAVOC_DEMONIC_TALENT_ID;
const HIDDEN_BUFF_DURATION = INFINITY;
const HIDDEN_BUFF_EXTENDED_BY_DEMONIC = "Extended by Demonic";

export class OvaleDemonHunterDemonicClass {
    playerGUID: string;
    isDemonHunter = false;
    isHavoc: boolean;
    hasDemonic: boolean;

    private module: AceModule & AceEvent;
    private debug: Tracer;

    constructor(
        private ovaleAura: OvaleAuraClass,
        private ovale: OvaleClass,
        ovaleDebug: OvaleDebugClass
    ) {
        this.module = ovale.createModule(
            "OvaleDemonHunterDemonic",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
        this.debug = ovaleDebug.create(this.module.GetName());
        this.playerGUID = this.ovale.playerGUID;
        this.isHavoc = false;
        this.hasDemonic = false;
    }

    private OnInitialize = () => {
        this.isDemonHunter =
            (this.ovale.playerClass == "DEMONHUNTER" && true) || false;
        if (this.isDemonHunter) {
            this.debug.Debug("playerGUID: (%s)", this.ovale.playerGUID);
            this.module.RegisterMessage(
                "Ovale_TalentsChanged",
                this.Ovale_TalentsChanged
            );
        }
    };
    private OnDisable = () => {
        this.module.UnregisterMessage("Ovale_TalentsChanged");
    };
    private Ovale_TalentsChanged = (event: string) => {
        this.isHavoc =
            (this.isDemonHunter &&
                GetSpecializationInfo(GetSpecialization()) == HAVOC_SPEC_ID &&
                true) ||
            false;
        this.hasDemonic =
            (this.isHavoc &&
                select(
                    10,
                    GetTalentInfoByID(HAVOC_DEMONIC_TALENT_ID, HAVOC_SPEC_ID)
                ) &&
                true) ||
            false;
        if (this.isHavoc && this.hasDemonic) {
            this.debug.Debug("We are a havoc DH with Demonic.");
            this.module.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        } else {
            if (!this.isHavoc) {
                this.debug.Debug("We are not a havoc DH.");
            } else if (!this.hasDemonic) {
                this.debug.Debug("We don't have the Demonic talent.");
            }
            this.DropAura();
            this.module.UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED");
        }
    };
    COMBAT_LOG_EVENT_UNFILTERED(event: string, ...__args: any[]) {
        const [
            ,
            cleuEvent,
            ,
            sourceGUID,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            arg12,
            arg13,
        ] = CombatLogGetCurrentEventInfo();
        if (
            sourceGUID == this.playerGUID &&
            cleuEvent == "SPELL_CAST_SUCCESS"
        ) {
            const [spellId, spellName] = [arg12, arg13];
            if (HAVOC_EYE_BEAM_SPELL_ID == spellId) {
                this.debug.Debug(
                    "Spell %d (%s) has successfully been cast. Gaining Aura (only during meta).",
                    spellId,
                    spellName
                );
                this.GainAura();
            }
        }
        if (
            sourceGUID == this.playerGUID &&
            cleuEvent == "SPELL_AURA_REMOVED"
        ) {
            const [spellId, spellName] = [arg12, arg13];
            if (HAVOC_META_BUFF_ID == spellId) {
                this.debug.Debug(
                    "Aura %d (%s) is removed. Dropping Aura.",
                    spellId,
                    spellName
                );
                this.DropAura();
            }
        }
    }
    GainAura() {
        const now = GetTime();
        const aura_meta = this.ovaleAura.GetAura(
            "player",
            HAVOC_META_BUFF_ID,
            now,
            "HELPFUL",
            true
        );
        if (aura_meta && this.ovaleAura.IsActiveAura(aura_meta, now)) {
            this.debug.Debug(
                "Adding '%s' (%d) buff to player %s.",
                HIDDEN_BUFF_EXTENDED_BY_DEMONIC,
                HIDDEN_BUFF_ID,
                this.playerGUID
            );
            const duration = HIDDEN_BUFF_DURATION;
            const ending = now + HIDDEN_BUFF_DURATION;
            this.ovaleAura.GainedAuraOnGUID(
                this.playerGUID,
                now,
                HIDDEN_BUFF_ID,
                this.playerGUID,
                "HELPFUL",
                false,
                undefined,
                1,
                undefined,
                duration,
                ending,
                false,
                HIDDEN_BUFF_EXTENDED_BY_DEMONIC,
                undefined,
                undefined,
                undefined
            );
        } else {
            this.debug.Debug(
                "Aura 'Metamorphosis' (%d) is not present.",
                HAVOC_META_BUFF_ID
            );
        }
    }
    DropAura() {
        const now = GetTime();
        this.debug.Debug(
            "Removing '%s' (%d) buff on player %s.",
            HIDDEN_BUFF_EXTENDED_BY_DEMONIC,
            HIDDEN_BUFF_ID,
            this.playerGUID
        );
        this.ovaleAura.LostAuraOnGUID(
            this.playerGUID,
            now,
            HIDDEN_BUFF_ID,
            this.playerGUID
        );
    }
}
