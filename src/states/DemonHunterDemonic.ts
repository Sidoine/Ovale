import { OvaleAuraClass } from "./Aura";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    GetSpecialization,
    GetSpecializationInfo,
    GetTime,
    GetTalentInfoByID,
} from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { select } from "@wowts/lua";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import { CombatLogEvent, SpellPayloadHeader } from "../engine/combat-log-event";
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
        private combatLogEvent: CombatLogEvent,
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
            this.combatLogEvent.registerEvent(
                "SPELL_CAST_SUCCESS",
                this,
                this.handleCombatLogEvent
            );
            this.combatLogEvent.registerEvent(
                "SPELL_AURA_REMOVED",
                this,
                this.handleCombatLogEvent
            );
        } else {
            if (!this.isHavoc) {
                this.debug.debug("We are not a havoc DH.");
            } else if (!this.hasDemonic) {
                this.debug.debug("We don't have the Demonic talent.");
            }
            this.dropAura();
            this.combatLogEvent.unregisterAllEvents(this);
        }
    };
    private handleCombatLogEvent(cleuEvent: string) {
        const cleu = this.combatLogEvent;
        if (cleu.sourceGUID == this.playerGUID) {
            if (cleuEvent == "SPELL_CAST_SUCCESS") {
                const header = cleu.header as SpellPayloadHeader;
                const spellId = header.spellId;
                const spellName = header.spellName;
                if (havocEyeBeamSpellId == spellId) {
                    this.debug.debug(
                        "Spell %d (%s) has successfully been cast. Gaining Aura (only during meta).",
                        spellId,
                        spellName
                    );
                    this.gainAura();
                }
            } else if (cleuEvent == "SPELL_AURA_REMOVED") {
                const header = cleu.header as SpellPayloadHeader;
                const spellId = header.spellId;
                const spellName = header.spellName;
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
