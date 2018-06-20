import { Ovale } from "./Ovale";
import { OvaleDebug } from "./Debug";
import { OvaleFuture } from "./Future";
import aceEvent from "@wowts/ace_event-3.0";
import AceSerializer from "@wowts/ace_serializer-3.0";
import { pairs, type, LuaObj } from "@wowts/lua";
import { IsInGroup, SendAddonMessage, LE_PARTY_CATEGORY_INSTANCE, GetTime, UnitCastingInfo, UnitChannelInfo } from "@wowts/wow-mock";

let OvaleScoreBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleScore", aceEvent, AceSerializer));
export let OvaleScore: OvaleScoreClass;
let MSG_PREFIX = Ovale.MSG_PREFIX;
let self_playerGUID = undefined;

class OvaleScoreClass extends OvaleScoreBase {
    damageMeter = {
    }
    damageMeterMethod:LuaObj<string> = {}
    score = 0;
    maxScore = 0;
    scoredSpell = {}
    
    OnInitialize() {
        self_playerGUID = Ovale.playerGUID;
        this.RegisterEvent("CHAT_MSG_ADDON");
        this.RegisterEvent("PLAYER_REGEN_ENABLED");
        this.RegisterEvent("PLAYER_REGEN_DISABLED");
        this.RegisterEvent("UNIT_SPELLCAST_CHANNEL_START");
        this.RegisterEvent("UNIT_SPELLCAST_START");
    }
    OnDisable() {
        this.UnregisterEvent("CHAT_MSG_ADDON");
        this.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.UnregisterEvent("PLAYER_REGEN_DISABLED");
        this.UnregisterEvent("UNIT_SPELLCAST_START");
    }
    CHAT_MSG_ADDON(event, ...__args) {
        let [prefix, message, , sender] = __args;
        if (prefix == MSG_PREFIX) {
            let [ok, msgType, scored, scoreMax, guid] = this.Deserialize(message);
            if (ok && msgType == "S") {
                this.SendScore(sender, guid, scored, scoreMax);
            }
        }
    }
    PLAYER_REGEN_ENABLED() {
        if (this.maxScore > 0 && IsInGroup()) {
            let message = this.Serialize("score", this.score, this.maxScore, self_playerGUID);
            let channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) && "INSTANCE_CHAT" || "RAID";
            SendAddonMessage(MSG_PREFIX, message, channel);
        }
    }
    PLAYER_REGEN_DISABLED() {
        this.score = 0;
        this.maxScore = 0;
    }
    RegisterDamageMeter(moduleName, addon, func) {
        if (!func) {
            func = addon;
        } else if (addon) {
            this.damageMeter[moduleName] = addon;
        }
        this.damageMeterMethod[moduleName] = func;
    }
    UnregisterDamageMeter(moduleName) {
        this.damageMeter[moduleName] = undefined;
        this.damageMeterMethod[moduleName] = undefined;
    }
    AddSpell(spellId) {
        this.scoredSpell[spellId] = true;
    }
    ScoreSpell(spellId) {
        // TODO need to solve problem of circular dependencies
        // if (OvaleFuture.inCombat && this.scoredSpell[spellId]) {
        //     let scored = frame.GetScore(spellId)
        //     this.DebugTimestamp("Scored %s for %d.", scored, spellId);
        //     if (scored) {
        //         this.score = this.score + scored;
        //         this.maxScore = this.maxScore + 1;
        //         this.SendScore(self_name, self_playerGUID, scored, 1);
        //     }
        // }
    }
    SendScore(name, guid, scored, scoreMax) {
        for (const [moduleName, method] of pairs(this.damageMeterMethod)) {
            let addon = this.damageMeter[moduleName];
            if (addon) {
                addon[method](addon, name, guid, scored, scoreMax);
            } else if (type(method) == "function") {
             //   method(name, guid, scored, scoreMax);
            }
        }
    }

    UNIT_SPELLCAST_CHANNEL_START(event, unitId, spell, rank, lineId, spellId) {
        if (unitId == "player" || unitId == "pet") {
            let now = GetTime();
            let [spellcast] = OvaleFuture.GetSpellcast(spell, spellId, undefined, now);
            if (spellcast) {
                let [name] = UnitChannelInfo(unitId);
                if (name == spell) {
                    this.ScoreSpell(spellId);
                }
            }
        }
    }

    UNIT_SPELLCAST_START(event, unitId, spell, rank, lineId, spellId) {
        if (unitId == "player" || unitId == "pet") {
            let now = GetTime();
            let [spellcast] = OvaleFuture.GetSpellcast(spell, spellId, lineId, now);
            if (spellcast) {
                let [name, , , , , , castId] = UnitCastingInfo(unitId);
                if (lineId == castId && name == spell) {
                    this.ScoreSpell(spellId);
                } 
            } 
        }
    }

    UNIT_SPELLCAST_SUCCEEDED(event, unitId, spell, rank, lineId, spellId) {
        if (unitId == "player" || unitId == "pet") {
            let now = GetTime();
            let [spellcast] = OvaleFuture.GetSpellcast(spell, spellId, lineId, now);
            if (spellcast) {
                if (spellcast.success || (!spellcast.start) || (!spellcast.stop) || spellcast.channel) {
                    let name = UnitChannelInfo(unitId);
                    if (!name) {
                        OvaleScore.ScoreSpell(spellId);
                    }
                }
            } 
        }
    }
}

OvaleScore = new OvaleScoreClass();