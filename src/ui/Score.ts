import { OvaleClass, messagePrefix } from "../Ovale";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import aceSerializer, { AceSerializer } from "@wowts/ace_serializer-3.0";
import { pairs, LuaObj, LuaArray } from "@wowts/lua";
import {
    IsInGroup,
    SendAddonMessage,
    LE_PARTY_CATEGORY_INSTANCE,
    GetTime,
    UnitCastingInfo,
    UnitChannelInfo,
} from "@wowts/wow-mock";
import { OvaleSpellBookClass } from "../states/SpellBook";
import { AceModule } from "@wowts/tsaddon";
import { OvaleFutureClass } from "../states/Future";
import { Tracer, DebugTools } from "../engine/debug";
import { OvaleCombatClass } from "../states/combat";

export type ScoreCallback = (
    name: string,
    guid: string,
    scored: number,
    scoreMax: number
) => void;

export class OvaleScoreClass {
    damageMeterMethod: LuaObj<ScoreCallback> = {};
    score = 0;
    maxScore = 0;
    scoredSpell: LuaArray<boolean> = {};
    private module: AceModule & AceEvent & AceSerializer;
    private tracer: Tracer;

    constructor(
        private ovale: OvaleClass,
        private ovaleFuture: OvaleFutureClass,
        ovaleDebug: DebugTools,
        private ovaleSpellBook: OvaleSpellBookClass,
        private combat: OvaleCombatClass
    ) {
        this.module = ovale.createModule(
            "OvaleScore",
            this.handleInitialize,
            this.handleDisable,
            aceEvent,
            aceSerializer
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
    }

    private handleInitialize = () => {
        this.module.RegisterEvent("CHAT_MSG_ADDON", this.handleChatMsgAddon);
        this.module.RegisterEvent(
            "PLAYER_REGEN_ENABLED",
            this.handlePlayerRegenEnabled
        );
        this.module.RegisterEvent(
            "PLAYER_REGEN_DISABLED",
            this.handlePlayerRegenDisabled
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_CHANNEL_START",
            this.handleUnitSpellCastChannelStart
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_START",
            this.handleUnitSpellCastStart
        );
    };
    private handleDisable = () => {
        this.module.UnregisterEvent("CHAT_MSG_ADDON");
        this.module.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.module.UnregisterEvent("PLAYER_REGEN_DISABLED");
        this.module.UnregisterEvent("UNIT_SPELLCAST_START");
    };
    private handleChatMsgAddon = (
        event: string,
        prefix: string,
        message: string,
        _: unknown,
        sender: string
    ) => {
        if (prefix == messagePrefix) {
            const [ok, msgType, scored, scoreMax, guid] =
                this.module.Deserialize(message);
            if (ok && msgType == "S") {
                this.sendScore(sender, guid, scored, scoreMax);
            }
        }
    };
    private handlePlayerRegenEnabled = () => {
        if (this.maxScore > 0 && IsInGroup()) {
            const message = this.module.Serialize(
                "score",
                this.score,
                this.maxScore,
                this.ovale.playerGUID
            );
            const channel =
                (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) && "INSTANCE_CHAT") ||
                "RAID";
            SendAddonMessage(messagePrefix, message, channel);
        }
    };
    private handlePlayerRegenDisabled = () => {
        this.score = 0;
        this.maxScore = 0;
    };
    registerDamageMeter(moduleName: string, func: ScoreCallback) {
        this.damageMeterMethod[moduleName] = func;
    }
    unregisterDamageMeter(moduleName: string) {
        delete this.damageMeterMethod[moduleName];
    }
    addSpell(spellId: number) {
        this.scoredSpell[spellId] = true;
    }
    scoreSpell(spellId: number) {
        if (this.combat.isInCombat(undefined) && this.scoredSpell[spellId]) {
            const scored = 0; // this.frame.GetScore(spellId)
            this.tracer.debugTimestamp("Scored %s for %d.", scored, spellId);
            if (scored) {
                this.score = this.score + scored;
                this.maxScore = this.maxScore + 1;
                this.sendScore(
                    this.module.GetName(),
                    this.ovale.playerGUID,
                    scored,
                    1
                );
            }
        }
    }
    sendScore(name: string, guid: string, scored: number, scoreMax: number) {
        for (const [, method] of pairs(this.damageMeterMethod)) {
            method(name, guid, scored, scoreMax);
        }
    }

    handleUnitSpellCastChannelStart = (
        event: string,
        unitId: string,
        lineId: number,
        spellId: number
    ) => {
        if (unitId == "player" || unitId == "pet") {
            const now = GetTime();
            const spell = this.ovaleSpellBook.getSpellName(spellId);
            if (spell) {
                const [spellcast] = this.ovaleFuture.getSpellcast(
                    spell,
                    spellId,
                    undefined,
                    now
                );
                if (spellcast) {
                    const [name] = UnitChannelInfo(unitId);
                    if (name == spell) {
                        this.scoreSpell(spellId);
                    }
                }
            }
        }
    };

    handleUnitSpellCastStart = (
        event: string,
        unitId: string,
        lineId: string,
        spellId: number
    ) => {
        if (unitId == "player" || unitId == "pet") {
            const spell = this.ovaleSpellBook.getSpellName(spellId);
            if (spell) {
                const now = GetTime();
                const [spellcast] = this.ovaleFuture.getSpellcast(
                    spell,
                    spellId,
                    lineId,
                    now
                );
                if (spellcast) {
                    const [name, , , , , , castId] = UnitCastingInfo(unitId);
                    if (lineId == castId && name == spell) {
                        this.scoreSpell(spellId);
                    }
                }
            }
        }
    };

    // UNIT_SPELLCAST_SUCCEEDED = (
    //     event: string,
    //     unitId: string,
    //     lineId: string,
    //     spellId: number
    // ) => {
    //     if (unitId == "player" || unitId == "pet") {
    //         const spell = this.ovaleSpellBook.GetSpellName(spellId);
    //         if (spell) {
    //             const now = GetTime();
    //             const [spellcast] = this.ovaleFuture.getSpellcast(
    //                 spell,
    //                 spellId,
    //                 lineId,
    //                 now
    //             );
    //             if (spellcast) {
    //                 if (
    //                     spellcast.success ||
    //                     !spellcast.start ||
    //                     !spellcast.stop ||
    //                     spellcast.channel
    //                 ) {
    //                     const name = UnitChannelInfo(unitId);
    //                     if (!name) {
    //                         this.scoreSpell(spellId);
    //                     }
    //                 }
    //             }
    //         }
    //     }
    // };
}
