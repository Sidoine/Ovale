import { OvaleGUIDClass } from "../GUID";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import aceTimer, { AceTimer, Timer } from "@wowts/ace_timer-3.0";
import { band, bor } from "@wowts/bit";
import { ipairs, pairs, wipe, truthy, LuaObj } from "@wowts/lua";
import { find } from "@wowts/string";
import {
    GetTime,
    COMBATLOG_OBJECT_AFFILIATION_MINE,
    COMBATLOG_OBJECT_AFFILIATION_PARTY,
    COMBATLOG_OBJECT_AFFILIATION_RAID,
    COMBATLOG_OBJECT_REACTION_FRIENDLY,
    CombatLogGetCurrentEventInfo,
} from "@wowts/wow-mock";
import { States } from "../State";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { Profiler, OvaleProfilerClass } from "../Profiler";
import { Tracer, OvaleDebugClass } from "../Debug";

let GROUP_MEMBER = bor(
    COMBATLOG_OBJECT_AFFILIATION_MINE,
    COMBATLOG_OBJECT_AFFILIATION_PARTY,
    COMBATLOG_OBJECT_AFFILIATION_RAID
);
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
    12: "_LEECH",
};
let CLEU_AUTOATTACK: LuaObj<boolean> = {
    RANGED_DAMAGE: true,
    RANGED_MISSED: true,
    SWING_DAMAGE: true,
    SWING_MISSED: true,
};
let CLEU_UNIT_REMOVED: LuaObj<boolean> = {
    UNIT_DESTROYED: true,
    UNIT_DIED: true,
    UNIT_DISSIPATES: true,
};
let self_enemyName: LuaObj<string> = {};
let self_enemyLastSeen: LuaObj<number> = {};
let self_taggedEnemyLastSeen: LuaObj<number> = {};
let self_reaperTimer: Timer | undefined = undefined;
let REAP_INTERVAL = 3;
const IsTagEvent = function (cleuEvent: string) {
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
};
const IsFriendly = function (unitFlags: number, isGroupMember?: boolean) {
    return (
        band(unitFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 &&
        (!isGroupMember || band(unitFlags, GROUP_MEMBER) > 0)
    );
};

class EnemiesData {
    activeEnemies = 0;
    taggedEnemies = 0;
    enemies: number | undefined = undefined;
}

export class OvaleEnemiesClass extends States<EnemiesData> {
    private module: AceModule & AceEvent & AceTimer;
    private profiler: Profiler;
    private tracer: Tracer;

    constructor(
        private ovaleGuid: OvaleGUIDClass,
        private ovale: OvaleClass,
        ovaleProfiler: OvaleProfilerClass,
        ovaleDebug: OvaleDebugClass
    ) {
        super(EnemiesData);
        this.module = ovale.createModule(
            "OvaleEnemies",
            this.OnInitialize,
            this.OnDisable,
            aceEvent,
            aceTimer
        );
        this.profiler = ovaleProfiler.create(this.module.GetName());
        this.tracer = ovaleDebug.create(this.module.GetName());
    }

    private OnInitialize = () => {
        if (!self_reaperTimer) {
            self_reaperTimer = this.module.ScheduleRepeatingTimer(
                this.RemoveInactiveEnemies,
                REAP_INTERVAL
            );
        }
        this.module.RegisterEvent(
            "COMBAT_LOG_EVENT_UNFILTERED",
            this.COMBAT_LOG_EVENT_UNFILTERED
        );
        this.module.RegisterEvent(
            "PLAYER_REGEN_DISABLED",
            this.PLAYER_REGEN_DISABLED
        );
    };

    private OnDisable = () => {
        if (self_reaperTimer) {
            this.module.CancelTimer(self_reaperTimer);
            self_reaperTimer = undefined;
        }
        this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.module.UnregisterEvent("PLAYER_REGEN_DISABLED");
    };

    private COMBAT_LOG_EVENT_UNFILTERED = (event: string, ...__args: any[]) => {
        let [
            ,
            cleuEvent,
            ,
            sourceGUID,
            sourceName,
            sourceFlags,
            ,
            destGUID,
            destName,
            destFlags,
        ] = CombatLogGetCurrentEventInfo();
        if (CLEU_UNIT_REMOVED[cleuEvent]) {
            let now = GetTime();
            this.RemoveEnemy(cleuEvent, destGUID, now, true);
        } else if (
            sourceGUID &&
            sourceGUID != "" &&
            sourceName &&
            sourceFlags &&
            destGUID &&
            destGUID != "" &&
            destName &&
            destFlags
        ) {
            if (!IsFriendly(sourceFlags) && IsFriendly(destFlags, true)) {
                if (
                    !(
                        cleuEvent == "SPELL_PERIODIC_DAMAGE" &&
                        IsTagEvent(cleuEvent)
                    )
                ) {
                    let now = GetTime();
                    this.AddEnemy(cleuEvent, sourceGUID, sourceName, now);
                }
            } else if (
                IsFriendly(sourceFlags, true) &&
                !IsFriendly(destFlags) &&
                IsTagEvent(cleuEvent)
            ) {
                let now = GetTime();
                let isPlayerTag;
                if (sourceGUID == this.ovale.playerGUID) {
                    isPlayerTag = true;
                } else {
                    [isPlayerTag] = this.ovaleGuid.IsPlayerPet(sourceGUID);
                }
                this.AddEnemy(cleuEvent, destGUID, destName, now, isPlayerTag);
            }
        }
    };
    private PLAYER_REGEN_DISABLED = () => {
        wipe(self_enemyName);
        wipe(self_enemyLastSeen);
        wipe(self_taggedEnemyLastSeen);
        this.current.activeEnemies = 0;
        this.current.taggedEnemies = 0;
    };
    private RemoveInactiveEnemies = () => {
        this.profiler.StartProfiling("OvaleEnemies_RemoveInactiveEnemies");
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
        this.profiler.StopProfiling("OvaleEnemies_RemoveInactiveEnemies");
    };
    private AddEnemy(
        cleuEvent: string,
        guid: string,
        name: string,
        timestamp: number,
        isTagged?: boolean
    ) {
        this.profiler.StartProfiling("OvaleEnemies_AddEnemy");
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
                this.tracer.DebugTimestamp(
                    "%s: %d/%d enemy seen: %s (%s)",
                    cleuEvent,
                    this.current.taggedEnemies,
                    this.current.activeEnemies,
                    guid,
                    name
                );
                this.ovale.needRefresh();
            }
        }
        this.profiler.StopProfiling("OvaleEnemies_AddEnemy");
    }
    private RemoveEnemy(
        cleuEvent: string,
        guid: string,
        timestamp: number,
        isDead?: boolean
    ) {
        this.profiler.StartProfiling("OvaleEnemies_RemoveEnemy");
        if (guid) {
            let name = self_enemyName[guid];
            let changed = false;
            if (self_enemyLastSeen[guid]) {
                delete self_enemyLastSeen[guid];
                if (this.current.activeEnemies > 0) {
                    this.current.activeEnemies = this.current.activeEnemies - 1;
                    changed = true;
                }
            }
            if (self_taggedEnemyLastSeen[guid]) {
                delete self_taggedEnemyLastSeen[guid];
                if (this.current.taggedEnemies > 0) {
                    this.current.taggedEnemies = this.current.taggedEnemies - 1;
                    changed = true;
                }
            }
            if (changed) {
                this.tracer.DebugTimestamp(
                    "%s: %d/%d enemy %s: %s (%s)",
                    cleuEvent,
                    this.current.taggedEnemies,
                    this.current.activeEnemies,
                    (isDead && "died") || "removed",
                    guid,
                    name
                );
                this.ovale.needRefresh();
                this.module.SendMessage("Ovale_InactiveUnit", guid, isDead);
            }
        }
        this.profiler.StopProfiling("OvaleEnemies_RemoveEnemy");
    }
    private RemoveTaggedEnemy(
        cleuEvent: string,
        guid: string,
        timestamp: number
    ) {
        this.profiler.StartProfiling("OvaleEnemies_RemoveTaggedEnemy");
        if (guid) {
            let name = self_enemyName[guid];
            let tagged = self_taggedEnemyLastSeen[guid];
            if (tagged) {
                delete self_taggedEnemyLastSeen[guid];
                if (this.current.taggedEnemies > 0) {
                    this.current.taggedEnemies = this.current.taggedEnemies - 1;
                }
                this.tracer.DebugTimestamp(
                    "%s: %d/%d enemy removed: %s (%s), last tagged at %f",
                    cleuEvent,
                    this.current.taggedEnemies,
                    this.current.activeEnemies,
                    guid,
                    name,
                    tagged
                );
                this.ovale.needRefresh();
            }
        }
        this.profiler.StopProfiling("OvaleEnemies_RemoveTaggedEnemy");
    }
    DebugEnemies() {
        for (const [guid, seen] of pairs(self_enemyLastSeen)) {
            let name = self_enemyName[guid];
            let tagged = self_taggedEnemyLastSeen[guid];
            if (tagged) {
                this.tracer.Print(
                    "Tagged enemy %s (%s) last seen at %f",
                    guid,
                    name,
                    tagged
                );
            } else {
                this.tracer.Print(
                    "Enemy %s (%s) last seen at %f",
                    guid,
                    name,
                    seen
                );
            }
        }
        this.tracer.Print("Total enemies: %d", this.current.activeEnemies);
        this.tracer.Print(
            "Total tagged enemies: %d",
            this.current.taggedEnemies
        );
    }

    InitializeState() {
        this.next.enemies = undefined;
    }
    ResetState() {
        this.profiler.StartProfiling("OvaleEnemies_ResetState");
        this.next.activeEnemies = this.current.activeEnemies;
        this.next.taggedEnemies = this.current.taggedEnemies;
        this.profiler.StopProfiling("OvaleEnemies_ResetState");
    }
    CleanState() {
        this.next.activeEnemies = 0;
        this.next.taggedEnemies = 0;
        this.next.enemies = undefined;
    }
}
