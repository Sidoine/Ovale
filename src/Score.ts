import { OvaleClass, MSG_PREFIX } from "./Ovale";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import aceSerializer, { AceSerializer } from "@wowts/ace_serializer-3.0";
import { pairs, type, LuaObj, LuaArray } from "@wowts/lua";
import {
    IsInGroup,
    SendAddonMessage,
    LE_PARTY_CATEGORY_INSTANCE,
    GetTime,
    UnitCastingInfo,
    UnitChannelInfo,
} from "@wowts/wow-mock";
import { OvaleSpellBookClass } from "./SpellBook";
import { AceModule } from "@wowts/tsaddon";
import { OvaleFutureClass } from "./Future";
import { Tracer, OvaleDebugClass } from "./Debug";
import { OvaleCombatClass } from "./combat";

export type ScoreCallback = (
    name: string,
    guid: string,
    scored: number,
    scoreMax: number
) => void;

export class OvaleScoreClass {
    damageMeter: LuaObj<any> = {};
    damageMeterMethod: LuaObj<ScoreCallback> = {};
    score = 0;
    maxScore = 0;
    scoredSpell: LuaArray<boolean> = {};
    private module: AceModule & AceEvent & AceSerializer;
    private tracer: Tracer;

    constructor(
        private ovale: OvaleClass,
        private ovaleFuture: OvaleFutureClass,
        ovaleDebug: OvaleDebugClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private combat: OvaleCombatClass
    ) {
        this.module = ovale.createModule(
            "OvaleScore",
            this.OnInitialize,
            this.OnDisable,
            aceEvent,
            aceSerializer
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
    }

    private OnInitialize = () => {
        this.module.RegisterEvent("CHAT_MSG_ADDON", this.CHAT_MSG_ADDON);
        this.module.RegisterEvent(
            "PLAYER_REGEN_ENABLED",
            this.PLAYER_REGEN_ENABLED
        );
        this.module.RegisterEvent(
            "PLAYER_REGEN_DISABLED",
            this.PLAYER_REGEN_DISABLED
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_CHANNEL_START",
            this.UNIT_SPELLCAST_CHANNEL_START
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_START",
            this.UNIT_SPELLCAST_START
        );
    };
    private OnDisable = () => {
        this.module.UnregisterEvent("CHAT_MSG_ADDON");
        this.module.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.module.UnregisterEvent("PLAYER_REGEN_DISABLED");
        this.module.UnregisterEvent("UNIT_SPELLCAST_START");
    };
    private CHAT_MSG_ADDON = (event: string, ...__args: any[]) => {
        let [prefix, message, , sender] = __args;
        if (prefix == MSG_PREFIX) {
            let [ok, msgType, scored, scoreMax, guid] = this.module.Deserialize(
                message
            );
            if (ok && msgType == "S") {
                this.SendScore(sender, guid, scored, scoreMax);
            }
        }
    };
    private PLAYER_REGEN_ENABLED = () => {
        if (this.maxScore > 0 && IsInGroup()) {
            let message = this.module.Serialize(
                "score",
                this.score,
                this.maxScore,
                this.ovale.playerGUID
            );
            let channel =
                (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) && "INSTANCE_CHAT") ||
                "RAID";
            SendAddonMessage(MSG_PREFIX, message, channel);
        }
    };
    private PLAYER_REGEN_DISABLED = () => {
        this.score = 0;
        this.maxScore = 0;
    };
    RegisterDamageMeter(moduleName: string, addon: any, func: ScoreCallback) {
        if (!func) {
            func = addon;
        } else if (addon) {
            this.damageMeter[moduleName] = addon;
        }
        this.damageMeterMethod[moduleName] = func;
    }
    UnregisterDamageMeter(moduleName: string) {
        delete this.damageMeter[moduleName];
        delete this.damageMeterMethod[moduleName];
    }
    AddSpell(spellId: number) {
        this.scoredSpell[spellId] = true;
    }
    ScoreSpell(spellId: number) {
        if (this.combat.isInCombat(undefined) && this.scoredSpell[spellId]) {
            let scored = 0; // this.frame.GetScore(spellId)
            this.tracer.DebugTimestamp("Scored %s for %d.", scored, spellId);
            if (scored) {
                this.score = this.score + scored;
                this.maxScore = this.maxScore + 1;
                this.SendScore(
                    this.module.GetName(),
                    this.ovale.playerGUID,
                    scored,
                    1
                );
            }
        }
    }
    SendScore(name: string, guid: string, scored: number, scoreMax: number) {
        for (const [moduleName, method] of pairs(this.damageMeterMethod)) {
            let addon = this.damageMeter[moduleName];
            if (addon) {
                method(name, guid, scored, scoreMax);
            } else if (type(method) == "function") {
                //   method(name, guid, scored, scoreMax);
            }
        }
    }

    UNIT_SPELLCAST_CHANNEL_START = (
        event: string,
        unitId: string,
        lineId: number,
        spellId: number
    ) => {
        if (unitId == "player" || unitId == "pet") {
            let now = GetTime();
            let spell = this.ovaleSpellBook.GetSpellName(spellId);
            if (spell) {
                let [spellcast] = this.ovaleFuture.GetSpellcast(
                    spell,
                    spellId,
                    undefined,
                    now
                );
                if (spellcast) {
                    let [name] = UnitChannelInfo(unitId);
                    if (name == spell) {
                        this.ScoreSpell(spellId);
                    }
                }
            }
        }
    };

    UNIT_SPELLCAST_START = (
        event: string,
        unitId: string,
        lineId: string,
        spellId: number
    ) => {
        if (unitId == "player" || unitId == "pet") {
            let spell = this.ovaleSpellBook.GetSpellName(spellId);
            if (spell) {
                let now = GetTime();
                let [spellcast] = this.ovaleFuture.GetSpellcast(
                    spell,
                    spellId,
                    lineId,
                    now
                );
                if (spellcast) {
                    let [name, , , , , , castId] = UnitCastingInfo(unitId);
                    if (lineId == castId && name == spell) {
                        this.ScoreSpell(spellId);
                    }
                }
            }
        }
    };

    UNIT_SPELLCAST_SUCCEEDED = (
        event: string,
        unitId: string,
        lineId: number,
        spellId: number
    ) => {
        if (unitId == "player" || unitId == "pet") {
            let spell = this.ovaleSpellBook.GetSpellName(spellId);
            if (spell) {
                let now = GetTime();
                let [spellcast] = this.ovaleFuture.GetSpellcast(
                    spell,
                    spellId,
                    lineId,
                    now
                );
                if (spellcast) {
                    if (
                        spellcast.success ||
                        !spellcast.start ||
                        !spellcast.stop ||
                        spellcast.channel
                    ) {
                        let name = UnitChannelInfo(unitId);
                        if (!name) {
                            this.ScoreSpell(spellId);
                        }
                    }
                }
            }
        }
    };
}
