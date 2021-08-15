import { Guids } from "../engine/guid";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import aceTimer, { AceTimer, Timer } from "@wowts/ace_timer-3.0";
import { band, bor } from "@wowts/bit";
import { LuaObj, pairs, wipe } from "@wowts/lua";
import { GetTime } from "@wowts/wow-mock";
import { States } from "../engine/state";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { CombatLogEvent, unitFlag } from "../engine/combat-log-event";
import { Tracer, DebugTools } from "../engine/debug";

const groupMembers = bor(
    unitFlag.affiliation.mine,
    unitFlag.affiliation.party,
    unitFlag.affiliation.raid
);
const friendlyReaction = unitFlag.reaction.friendly;
const tagEvent: LuaObj<boolean> = {
    DAMAGE_SHIELD: true,
    DAMAGE_SHIELD_MISSED: true,
    RANGE_DAMAGE: true,
    RANGE_MISSED: true,
    SPELL_AURA_APPLIED: true,
    SPELL_AURA_APPLIED_DOSE: true,
    SPELL_AURA_REFRESH: true,
    SPELL_CAST_START: true,
    SPELL_DAMAGE: true,
    SPELL_DISPEL: true,
    SPELL_DISPEL_FAILED: true,
    SPELL_DRAIN: true,
    SPELL_INTERRUPT: true,
    SPELL_LEECH: true,
    SPELL_MISSED: true,
    SPELL_STOLEN: true,
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
const isFriendly = function (unitFlags: number, isGroupMember?: boolean) {
    return (
        band(unitFlags, friendlyReaction) > 0 &&
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
    private tracer: Tracer;

    constructor(
        private ovaleGuid: Guids,
        private combatLogEvent: CombatLogEvent,
        private ovale: OvaleClass,
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
            "PLAYER_REGEN_DISABLED",
            this.handlePlayerRegenDisabled
        );
        this.module.RegisterMessage(
            "Ovale_CombatLogEvent",
            this.handleOvaleCombatLogEvent
        );
        for (const [event] of pairs(tagEvent)) {
            this.combatLogEvent.registerEvent(event, this);
        }
    };

    private handleDisable = () => {
        if (reaperTimer) {
            this.module.CancelTimer(reaperTimer);
            reaperTimer = undefined;
        }
        this.module.UnregisterEvent("PLAYER_REGEN_DISABLED");
        this.module.UnregisterMessage("Ovale_CombatLogEvent");
        for (const [event] of pairs(tagEvent)) {
            this.combatLogEvent.unregisterEvent(event, this);
        }
    };

    private handleOvaleCombatLogEvent = (event: string, cleuEvent: string) => {
        if (!unitRemovedEvents[cleuEvent] && !tagEvent[cleuEvent]) {
            return;
        }
        const cleu = this.combatLogEvent;
        const sourceGUID = cleu.sourceGUID;
        const sourceName = cleu.sourceName;
        const sourceFlags = cleu.sourceFlags;
        const destGUID = cleu.destGUID;
        const destName = cleu.destName;
        const destFlags = cleu.destFlags;
        if (unitRemovedEvents[cleuEvent]) {
            const now = GetTime();
            this.removeEnemy(cleuEvent, destGUID, now, true);
        } else if (sourceGUID != "" && destGUID != "" && tagEvent[cleuEvent]) {
            if (!isFriendly(sourceFlags) && isFriendly(destFlags, true)) {
                // Hostile enemy attacks group member.
                const now = GetTime();
                this.addEnemy(cleuEvent, sourceGUID, sourceName, now);
            } else if (
                isFriendly(sourceFlags, true) &&
                !isFriendly(destFlags)
            ) {
                // Group member attacks neutral/hostile enemy.
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
    };
    private addEnemy(
        cleuEvent: string,
        guid: string,
        name: string,
        timestamp: number,
        isTagged?: boolean
    ) {
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
    }
    private removeEnemy(
        cleuEvent: string,
        guid: string,
        timestamp: number,
        isDead?: boolean
    ) {
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
    }
    private removeTaggedEnemy(
        cleuEvent: string,
        guid: string,
        timestamp: number
    ) {
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
        this.next.activeEnemies = this.current.activeEnemies;
        this.next.taggedEnemies = this.current.taggedEnemies;
    }
    cleanState() {
        this.next.activeEnemies = 0;
        this.next.taggedEnemies = 0;
        this.next.enemies = undefined;
    }
}
