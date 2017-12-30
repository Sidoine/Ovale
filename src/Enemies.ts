import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleGUID } from "./GUID";
import { OvaleState } from "./State";
import aceEvent from "@wowts/ace_event-3.0";
import AceTimer from "@wowts/ace_timer-3.0";
import { band, bor } from "@wowts/bit";
import { ipairs, pairs, wipe, truthy } from "@wowts/lua";
import { find } from "@wowts/string";
import { GetTime, COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID, COMBATLOG_OBJECT_REACTION_FRIENDLY } from "@wowts/wow-mock";

export let OvaleEnemies: OvaleEnemiesClass;
let GROUP_MEMBER = bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID);
let CLEU_TAG_SUFFIXES = {
    1: "_DAMAGE",
    2: "_MISSED",
    3: "_AURA_APPLIED",
    4: "_AURA_APPLIED_DOSE",
    5: "_AURA_REFRESH",
    6: "_CAST_START",
    7: "_INTERRUPT",
    8: "_DISPEL",
    9: "_DISPEL_FAILED",
    10: "_STOLEN",
    11: "_DRAIN",
    12: "_LEECH"
}
let CLEU_AUTOATTACK = {
    RANGED_DAMAGE: true,
    RANGED_MISSED: true,
    SWING_DAMAGE: true,
    SWING_MISSED: true
}
let CLEU_UNIT_REMOVED = {
    UNIT_DESTROYED: true,
    UNIT_DIED: true,
    UNIT_DISSIPATES: true
}
let self_enemyName = {
}
let self_enemyLastSeen = {
}
let self_taggedEnemyLastSeen = {
}
let self_reaperTimer = undefined;
let REAP_INTERVAL = 3;
const IsTagEvent = function(cleuEvent) {
    let isTagEvent = false;
    if (CLEU_AUTOATTACK[cleuEvent]) {
        isTagEvent = true;
    } else {
        for (const [, suffix] of ipairs(CLEU_TAG_SUFFIXES)) {
            if (truthy(find(cleuEvent, `${suffix}$`))) {
                isTagEvent = true;
                break;
            }
        }
    }
    return isTagEvent;
}
const IsFriendly = function(unitFlags, isGroupMember?) {
    return band(unitFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 && (!isGroupMember || band(unitFlags, GROUP_MEMBER) > 0);
}

class EnemiesData {
    activeEnemies = 0;
    taggedEnemies = 0;
    enemies = undefined;
}
let OvaleEnemiesBase = OvaleState.RegisterHasState(OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvaleEnemies", aceEvent, AceTimer))), EnemiesData);

class OvaleEnemiesClass extends OvaleEnemiesBase {
    
    OnInitialize() {
        if (!self_reaperTimer) {
            self_reaperTimer = this.ScheduleRepeatingTimer("RemoveInactiveEnemies", REAP_INTERVAL);
        }
        this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.RegisterEvent("PLAYER_REGEN_DISABLED");
    }
    OnDisable() {
        if (!self_reaperTimer) {
            this.CancelTimer(self_reaperTimer);
            self_reaperTimer = undefined;
        }
        this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.UnregisterEvent("PLAYER_REGEN_DISABLED");
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        if (CLEU_UNIT_REMOVED[cleuEvent]) {
            let now = GetTime();
            this.RemoveEnemy(cleuEvent, destGUID, now, true);
        } else if (sourceGUID && sourceGUID != "" && sourceName && sourceFlags && destGUID && destGUID != "" && destName && destFlags) {
            if (!IsFriendly(sourceFlags) && IsFriendly(destFlags, true)) {
                if (!(cleuEvent == "SPELL_PERIODIC_DAMAGE" && IsTagEvent(cleuEvent))) {
                    let now = GetTime();
                    this.AddEnemy(cleuEvent, sourceGUID, sourceName, now);
                }
            } else if (IsFriendly(sourceFlags, true) && !IsFriendly(destFlags) && IsTagEvent(cleuEvent)) {
                let now = GetTime();
                let isPlayerTag = (sourceGUID == Ovale.playerGUID) || OvaleGUID.IsPlayerPet(sourceGUID);
                this.AddEnemy(cleuEvent, destGUID, destName, now, isPlayerTag);
            }
        }
    }
    PLAYER_REGEN_DISABLED() {
        wipe(self_enemyName);
        wipe(self_enemyLastSeen);
        wipe(self_taggedEnemyLastSeen);
        this.current.activeEnemies = 0;
        this.current.taggedEnemies = 0;
    }
    RemoveInactiveEnemies() {
        this.StartProfiling("OvaleEnemies_RemoveInactiveEnemies");
        let now = GetTime();
        for (const [guid, timestamp] of pairs(self_enemyLastSeen)) {
            if (now - timestamp > REAP_INTERVAL) {
                this.RemoveEnemy("REAPED", guid, now);
            }
        }
        for (const [guid, timestamp] of pairs(self_taggedEnemyLastSeen)) {
            if (now - timestamp > REAP_INTERVAL) {
                this.RemoveTaggedEnemy("REAPED", guid, now);
            }
        }
        this.StopProfiling("OvaleEnemies_RemoveInactiveEnemies");
    }
    private AddEnemy(cleuEvent, guid, name, timestamp, isTagged?) {
        this.StartProfiling("OvaleEnemies_AddEnemy");
        if (guid) {
            self_enemyName[guid] = name;
            let changed = false;
            {
                if (!self_enemyLastSeen[guid]) {
                    this.current.activeEnemies = this.current.activeEnemies + 1;
                    changed = true;
                }
                self_enemyLastSeen[guid] = timestamp;
            }
            if (isTagged) {
                if (!self_taggedEnemyLastSeen[guid]) {
                    this.current.taggedEnemies = this.current.taggedEnemies + 1;
                    changed = true;
                }
                self_taggedEnemyLastSeen[guid] = timestamp;
            }
            if (changed) {
                this.DebugTimestamp("%s: %d/%d enemy seen: %s (%s)", cleuEvent, this.current.taggedEnemies, this.current.activeEnemies, guid, name);
                Ovale.needRefresh();
            }
        }
        this.StopProfiling("OvaleEnemies_AddEnemy");
    }
    private RemoveEnemy(cleuEvent, guid, timestamp, isDead?) {
        this.StartProfiling("OvaleEnemies_RemoveEnemy");
        if (guid) {
            let name = self_enemyName[guid];
            let changed = false;
            if (self_enemyLastSeen[guid]) {
                self_enemyLastSeen[guid] = undefined;
                if (this.current.activeEnemies > 0) {
                    this.current.activeEnemies = this.current.activeEnemies - 1;
                    changed = true;
                }
            }
            if (self_taggedEnemyLastSeen[guid]) {
                self_taggedEnemyLastSeen[guid] = undefined;
                if (this.current.taggedEnemies > 0) {
                    this.current.taggedEnemies = this.current.taggedEnemies - 1;
                    changed = true;
                }
            }
            if (changed) {
                this.DebugTimestamp("%s: %d/%d enemy %s: %s (%s)", cleuEvent, this.current.taggedEnemies, this.current.activeEnemies, isDead && "died" || "removed", guid, name);
                Ovale.needRefresh();
                this.SendMessage("Ovale_InactiveUnit", guid, isDead);
            }
        }
        this.StopProfiling("OvaleEnemies_RemoveEnemy");
    }
    private RemoveTaggedEnemy(cleuEvent, guid, timestamp) {
        this.StartProfiling("OvaleEnemies_RemoveTaggedEnemy");
        if (guid) {
            let name = self_enemyName[guid];
            let tagged = self_taggedEnemyLastSeen[guid];
            if (tagged) {
                self_taggedEnemyLastSeen[guid] = undefined;
                if (this.current.taggedEnemies > 0) {
                    this.current.taggedEnemies = this.current.taggedEnemies - 1;
                }
                this.DebugTimestamp("%s: %d/%d enemy removed: %s (%s), last tagged at %f", cleuEvent, this.current.taggedEnemies, this.current.activeEnemies, guid, name, tagged);
                Ovale.needRefresh();
            }
        }
        this.StopProfiling("OvaleEnemies_RemoveEnemy");
    }
    DebugEnemies() {
        for (const [guid, seen] of pairs(self_enemyLastSeen)) {
            let name = self_enemyName[guid];
            let tagged = self_taggedEnemyLastSeen[guid];
            if (tagged) {
                this.Print("Tagged enemy %s (%s) last seen at %f", guid, name, tagged);
            } else {
                this.Print("Enemy %s (%s) last seen at %f", guid, name, seen);
            }
        }
        this.Print("Total enemies: %d", this.current.activeEnemies);
        this.Print("Total tagged enemies: %d", this.current.taggedEnemies);
    }
    
    InitializeState() {
        this.next.enemies = undefined;
    }
    ResetState() {
        this.StartProfiling("OvaleEnemies_ResetState");
        this.next.activeEnemies = this.current.activeEnemies;
        this.next.taggedEnemies = this.current.taggedEnemies;
        this.StopProfiling("OvaleEnemies_ResetState");
    }
    CleanState() {
        this.next.activeEnemies = undefined;
        this.next.taggedEnemies = undefined;
        this.next.enemies = undefined;
    }
}

OvaleEnemies = new OvaleEnemiesClass();
OvaleState.RegisterState(OvaleEnemies);
