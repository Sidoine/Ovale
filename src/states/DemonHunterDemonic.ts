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
import { DebugTools, Tracer } from "../engine/debug";

const infinity = huge;
const havocDemonicTalentId = 22547;
const havocSpecId = 577;
const havocEyeBeamSpellId = 198013;
const havocMetaBuffId = 162264;
const hiddenBuffId = -havocDemonicTalentId;
const hiddenBuffDuration = infinity;
const hiddenBuffExtendedByDemonic = "Extended by Demonic";

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
        ovaleDebug: DebugTools
    ) {
        this.module = ovale.createModule(
            "OvaleDemonHunterDemonic",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.debug = ovaleDebug.create(this.module.GetName());
        this.playerGUID = this.ovale.playerGUID;
        this.isHavoc = false;
        this.hasDemonic = false;
    }

    private handleInitialize = () => {
        this.isDemonHunter =
            (this.ovale.playerClass == "DEMONHUNTER" && true) || false;
        if (this.isDemonHunter) {
            this.debug.debug("playerGUID: (%s)", this.ovale.playerGUID);
            this.module.RegisterMessage(
                "Ovale_TalentsChanged",
                this.handleTalentsChanged
            );
        }
    };
    private handleDisable = () => {
        this.module.UnregisterMessage("Ovale_TalentsChanged");
    };
    private handleTalentsChanged = (event: string) => {
        this.isHavoc =
            (this.isDemonHunter &&
                GetSpecializationInfo(GetSpecialization()) == havocSpecId &&
                true) ||
            false;
        this.hasDemonic =
            (this.isHavoc &&
                select(
                    10,
                    GetTalentInfoByID(havocDemonicTalentId, havocSpecId)
                ) &&
                true) ||
            false;
        if (this.isHavoc && this.hasDemonic) {
            this.debug.debug("We are a havoc DH with Demonic.");
            this.module.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        } else {
            if (!this.isHavoc) {
                this.debug.debug("We are not a havoc DH.");
            } else if (!this.hasDemonic) {
                this.debug.debug("We don't have the Demonic talent.");
            }
            this.dropAura();
            this.module.UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED");
        }
    };
    handleCombatLogEventUnfiltered(event: string, ...parameters: any[]) {
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
            if (havocEyeBeamSpellId == spellId) {
                this.debug.debug(
                    "Spell %d (%s) has successfully been cast. Gaining Aura (only during meta).",
                    spellId,
                    spellName
                );
                this.gainAura();
            }
        }
        if (
            sourceGUID == this.playerGUID &&
            cleuEvent == "SPELL_AURA_REMOVED"
        ) {
            const [spellId, spellName] = [arg12, arg13];
            if (havocMetaBuffId == spellId) {
                this.debug.debug(
                    "Aura %d (%s) is removed. Dropping Aura.",
                    spellId,
                    spellName
                );
                this.dropAura();
            }
        }
    }
    gainAura() {
        const now = GetTime();
        const auraMeta = this.ovaleAura.getAura(
            "player",
            havocMetaBuffId,
            now,
            "HELPFUL",
            true
        );
        if (auraMeta && this.ovaleAura.isActiveAura(auraMeta, now)) {
            this.debug.debug(
                "Adding '%s' (%d) buff to player %s.",
                hiddenBuffExtendedByDemonic,
                hiddenBuffId,
                this.playerGUID
            );
            const duration = hiddenBuffDuration;
            const ending = now + hiddenBuffDuration;
            this.ovaleAura.gainedAuraOnGUID(
                this.playerGUID,
                now,
                hiddenBuffId,
                this.playerGUID,
                "HELPFUL",
                false,
                undefined,
                1,
                undefined,
                duration,
                ending,
                false,
                hiddenBuffExtendedByDemonic,
                undefined,
                undefined,
                undefined
            );
        } else {
            this.debug.debug(
                "Aura 'Metamorphosis' (%d) is not present.",
                havocMetaBuffId
            );
        }
    }
    dropAura() {
        const now = GetTime();
        this.debug.debug(
            "Removing '%s' (%d) buff on player %s.",
            hiddenBuffExtendedByDemonic,
            hiddenBuffId,
            this.playerGUID
        );
        this.ovaleAura.lostAuraOnGUID(
            this.playerGUID,
            now,
            hiddenBuffId,
            this.playerGUID
        );
    }
}
