import { Guids } from "../engine/guid";
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
import { States } from "../engine/state";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { Profiler, OvaleProfilerClass } from "../engine/profiler";
import { Tracer, DebugTools } from "../engine/debug";

const groupMembers = bor(
    COMBATLOG_OBJECT_AFFILIATION_MINE,
    COMBATLOG_OBJECT_AFFILIATION_PARTY,
    COMBATLOG_OBJECT_AFFILIATION_RAID
);
const eventTagSuffixes = {
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
const autoAttackEvents: LuaObj<boolean> = {
    RANGED_DAMAGE: true,
    RANGED_MISSED: true,
    SWING_DAMAGE: true,
    SWING_MISSED: true,
};
const unitRemovedEvents: LuaObj<boolean> = {
    UNIT_DESTROYED: true,
    UNIT_DIED: true,
    UNIT_DISSIPATES: true,
};
const enemyNames: LuaObj<string> = {};
const lastSeenEnemies: LuaObj<number> = {};
const taggedEnemyLastSeens: LuaObj<number> = {};
let reaperTimer: Timer | undefined = undefined;
const reapInterval = 3;
const isTagEvent = function (cleuEvent: string) {
    let isTagEvent = false;
    if (autoAttackEvents[cleuEvent]) {
        isTagEvent = true;
    } else {
        for (const [, suffix] of ipairs(eventTagSuffixes)) {
            if (truthy(find(cleuEvent, `${suffix}$`))) {
                isTagEvent = true;
                break;
            }
        }
    }
    return isTagEvent;
};
const isFriendly = function (unitFlags: number, isGroupMember?: boolean) {
    return (
        band(unitFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 &&
        (!isGroupMember || band(unitFlags, groupMembers) > 0)
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
        private ovaleGuid: Guids,
        private ovale: OvaleClass,
        ovaleProfiler: OvaleProfilerClass,
        ovaleDebug: DebugTools
    ) {
        super(EnemiesData);
        this.module = ovale.createModule(
            "OvaleEnemies",
            this.handleInitialize,
            this.handleDisable,
            aceEvent,
            aceTimer
        );
        this.profiler = ovaleProfiler.create(this.module.GetName());
        this.tracer = ovaleDebug.create(this.module.GetName());
    }

    private handleInitialize = () => {
        if (!reaperTimer) {
            reaperTimer = this.module.ScheduleRepeatingTimer(
                this.removeInactiveEnemies,
                reapInterval
            );
        }
        this.module.RegisterEvent(
            "COMBAT_LOG_EVENT_UNFILTERED",
            this.handleCombatLogEventUnfiltered
        );
        this.module.RegisterEvent(
            "PLAYER_REGEN_DISABLED",
            this.handlePlayerRegenDisabled
        );
    };

    private handleDisable = () => {
        if (reaperTimer) {
            this.module.CancelTimer(reaperTimer);
            reaperTimer = undefined;
        }
        this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.module.UnregisterEvent("PLAYER_REGEN_DISABLED");
    };

    private handleCombatLogEventUnfiltered = (
        event: string,
        ...parameters: any[]
    ) => {
        const [
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
        if (unitRemovedEvents[cleuEvent]) {
            const now = GetTime();
            this.removeEnemy(cleuEvent, destGUID, now, true);
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
            if (!isFriendly(sourceFlags) && isFriendly(destFlags, true)) {
                if (
                    !(
                        cleuEvent == "SPELL_PERIODIC_DAMAGE" &&
                        isTagEvent(cleuEvent)
                    )
                ) {
                    const now = GetTime();
                    this.addEnemy(cleuEvent, sourceGUID, sourceName, now);
                }
            } else if (
                isFriendly(sourceFlags, true) &&
                !isFriendly(destFlags) &&
                isTagEvent(cleuEvent)
            ) {
                const now = GetTime();
                const isPlayerTag =
                    sourceGUID == this.ovale.playerGUID ||
                    this.ovaleGuid.getOwnerGUIDByGUID(sourceGUID) ==
                        this.ovale.playerGUID;
                this.addEnemy(cleuEvent, destGUID, destName, now, isPlayerTag);
            }
        }
    };
    private handlePlayerRegenDisabled = () => {
        wipe(enemyNames);
        wipe(lastSeenEnemies);
        wipe(taggedEnemyLastSeens);
        this.current.activeEnemies = 0;
        this.current.taggedEnemies = 0;
    };
    private removeInactiveEnemies = () => {
        this.profiler.startProfiling("OvaleEnemies_RemoveInactiveEnemies");
        const now = GetTime();
        for (const [guid, timestamp] of pairs(lastSeenEnemies)) {
            if (now - timestamp > reapInterval) {
                this.removeEnemy("REAPED", guid, now);
            }
        }
        for (const [guid, timestamp] of pairs(taggedEnemyLastSeens)) {
            if (now - timestamp > reapInterval) {
                this.removeTaggedEnemy("REAPED", guid, now);
            }
        }
        this.profiler.stopProfiling("OvaleEnemies_RemoveInactiveEnemies");
    };
    private addEnemy(
        cleuEvent: string,
        guid: string,
        name: string,
        timestamp: number,
        isTagged?: boolean
    ) {
        this.profiler.startProfiling("OvaleEnemies_AddEnemy");
        if (guid) {
            enemyNames[guid] = name;
            let changed = false;
            {
                if (!lastSeenEnemies[guid]) {
                    this.current.activeEnemies = this.current.activeEnemies + 1;
                    changed = true;
                }
                lastSeenEnemies[guid] = timestamp;
            }
            if (isTagged) {
                if (!taggedEnemyLastSeens[guid]) {
                    this.current.taggedEnemies = this.current.taggedEnemies + 1;
                    changed = true;
                }
                taggedEnemyLastSeens[guid] = timestamp;
            }
            if (changed) {
                this.tracer.debugTimestamp(
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
        this.profiler.stopProfiling("OvaleEnemies_AddEnemy");
    }
    private removeEnemy(
        cleuEvent: string,
        guid: string,
        timestamp: number,
        isDead?: boolean
    ) {
        this.profiler.startProfiling("OvaleEnemies_RemoveEnemy");
        if (guid) {
            const name = enemyNames[guid];
            let changed = false;
            if (lastSeenEnemies[guid]) {
                delete lastSeenEnemies[guid];
                if (this.current.activeEnemies > 0) {
                    this.current.activeEnemies = this.current.activeEnemies - 1;
                    changed = true;
                }
            }
            if (taggedEnemyLastSeens[guid]) {
                delete taggedEnemyLastSeens[guid];
                if (this.current.taggedEnemies > 0) {
                    this.current.taggedEnemies = this.current.taggedEnemies - 1;
                    changed = true;
                }
            }
            if (changed) {
                this.tracer.debugTimestamp(
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
        this.profiler.stopProfiling("OvaleEnemies_RemoveEnemy");
    }
    private removeTaggedEnemy(
        cleuEvent: string,
        guid: string,
        timestamp: number
    ) {
        this.profiler.startProfiling("OvaleEnemies_RemoveTaggedEnemy");
        if (guid) {
            const name = enemyNames[guid];
            const tagged = taggedEnemyLastSeens[guid];
            if (tagged) {
                delete taggedEnemyLastSeens[guid];
                if (this.current.taggedEnemies > 0) {
                    this.current.taggedEnemies = this.current.taggedEnemies - 1;
                }
                this.tracer.debugTimestamp(
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
        this.profiler.stopProfiling("OvaleEnemies_RemoveTaggedEnemy");
    }
    debugEnemies() {
        for (const [guid, seen] of pairs(lastSeenEnemies)) {
            const name = enemyNames[guid];
            const tagged = taggedEnemyLastSeens[guid];
            if (tagged) {
                this.tracer.print(
                    "Tagged enemy %s (%s) last seen at %f",
                    guid,
                    name,
                    tagged
                );
            } else {
                this.tracer.print(
                    "Enemy %s (%s) last seen at %f",
                    guid,
                    name,
                    seen
                );
            }
        }
        this.tracer.print("Total enemies: %d", this.current.activeEnemies);
        this.tracer.print(
            "Total tagged enemies: %d",
            this.current.taggedEnemies
        );
    }

    initializeState() {
        this.next.enemies = undefined;
    }
    resetState() {
        this.profiler.startProfiling("OvaleEnemies_ResetState");
        this.next.activeEnemies = this.current.activeEnemies;
        this.next.taggedEnemies = this.current.taggedEnemies;
        this.profiler.stopProfiling("OvaleEnemies_ResetState");
    }
    cleanState() {
        this.next.activeEnemies = 0;
        this.next.taggedEnemies = 0;
        this.next.enemies = undefined;
    }
}
