import { Ovale } from "./Ovale";
import { OvaleDebug } from "./Debug";
import { OvaleFuture } from "./Future";
import aceEvent from "@wowts/ace_event-3.0";
import AceSerializer from "@wowts/ace_serializer-3.0";
import { pairs, type, LuaObj, LuaArray } from "@wowts/lua";
import { IsInGroup, SendAddonMessage, LE_PARTY_CATEGORY_INSTANCE, GetTime, UnitCastingInfo, UnitChannelInfo } from "@wowts/wow-mock";
import { OvaleSpellBook } from "./SpellBook";

let OvaleScoreBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleScore", aceEvent, AceSerializer));
export let OvaleScore: OvaleScoreClass;
let MSG_PREFIX = Ovale.MSG_PREFIX;
let self_playerGUID: string = undefined;

class OvaleScoreClass extends OvaleScoreBase {
    damageMeter: LuaObj<any> = {}
    damageMeterMethod:LuaObj<string> = {}
    score = 0;
    maxScore = 0;
    scoredSpell: LuaArray<boolean> = {}
    
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
    CHAT_MSG_ADDON(event: string, ...__args: any[]) {
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
    RegisterDamageMeter(moduleName: string, addon: any, func: string) {
        if (!func) {
            func = addon;
        } else if (addon) {
            this.damageMeter[moduleName] = addon;
        }
        this.damageMeterMethod[moduleName] = func;
    }
    UnregisterDamageMeter(moduleName: string) {
        this.damageMeter[moduleName] = undefined;
        this.damageMeterMethod[moduleName] = undefined;
    }
    AddSpell(spellId: number) {
        this.scoredSpell[spellId] = true;
    }
    ScoreSpell(spellId: number) {
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
    SendScore(name: string, guid: string, scored: number, scoreMax: number) {
        for (const [moduleName, method] of pairs(this.damageMeterMethod)) {
            let addon = this.damageMeter[moduleName];
            if (addon) {
                addon[method](addon, name, guid, scored, scoreMax);
            } else if (type(method) == "function") {
             //   method(name, guid, scored, scoreMax);
            }
        }
    }

    UNIT_SPELLCAST_CHANNEL_START(event: string, unitId: string, lineId: number, spellId: number) {
        if (unitId == "player" || unitId == "pet") {
            let now = GetTime();
            let spell = OvaleSpellBook.GetSpellName(spellId);
            let [spellcast] = OvaleFuture.GetSpellcast(spell, spellId, undefined, now);
            if (spellcast) {
                let [name] = UnitChannelInfo(unitId);
                if (name == spell) {
                    this.ScoreSpell(spellId);
                }
            }
        }
    }

    UNIT_SPELLCAST_START(event: string, unitId: string, lineId: number, spellId: number) {
        if (unitId == "player" || unitId == "pet") {
            let now = GetTime();
            let spell = OvaleSpellBook.GetSpellName(spellId);
            let [spellcast] = OvaleFuture.GetSpellcast(spell, spellId, lineId, now);
            if (spellcast) {
                let [name, , , , , , castId] = UnitCastingInfo(unitId);
                if (lineId == castId && name == spell) {
                    this.ScoreSpell(spellId);
                } 
            } 
        }
    }

    UNIT_SPELLCAST_SUCCEEDED(event: string, unitId: string, lineId: number, spellId: number) {
        if (unitId == "player" || unitId == "pet") {
            let now = GetTime();
            let spell = OvaleSpellBook.GetSpellName(spellId);
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