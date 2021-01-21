import { Tracer, DebugTools } from "../engine/debug";
import { Profiler, OvaleProfilerClass } from "../engine/profiler";
import { OvaleClass } from "../Ovale";
import { UnitExists, UnitClassification } from "@wowts/wow-mock";
import { _G, hooksecurefunc } from "@wowts/lua";
import { AceModule } from "@wowts/tsaddon";
import { OvaleCombatClass } from "./combat";
// eslint-disable-next-line @typescript-eslint/naming-convention
const bigWigsLoader: { RegisterMessage: any } = _G["BigWigsLoader"];
const dbmClass = _G["DBM"];
export class OvaleBossModClass {
    engagedDBM: any = undefined;
    engagedBigWigs: any = undefined;

    private module: AceModule;
    private tracer: Tracer;
    private profiler: Profiler;

    constructor(
        ovale: OvaleClass,
        ovaleDebug: DebugTools,
        ovaleProfiler: OvaleProfilerClass,
        private combat: OvaleCombatClass
    ) {
        this.module = ovale.createModule(
            "BossMod",
            this.handleInitialize,
            this.handleDisable
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
        this.profiler = ovaleProfiler.create(this.module.GetName());
    }

    private handleInitialize = () => {
        if (dbmClass) {
            this.tracer.debug("DBM is loaded");
            hooksecurefunc(
                dbmClass,
                "StartCombat",
                (dbm, mod, delay, event, ...parameters) => {
                    if (event != "TIMER_RECOVERY") {
                        this.engagedDBM = mod;
                    }
                }
            );
            hooksecurefunc(dbmClass, "EndCombat", (dbm, mod) => {
                this.engagedDBM = undefined;
            });
        }
        if (bigWigsLoader) {
            this.tracer.debug("BigWigs is loaded");
            bigWigsLoader.RegisterMessage(
                this,
                "BigWigs_OnBossEngage",
                (_: any, mod: any, diff: any) => {
                    this.engagedBigWigs = mod;
                }
            );
            bigWigsLoader.RegisterMessage(
                this,
                "BigWigs_OnBossDisable",
                (_: any, mod: any) => {
                    this.engagedBigWigs = undefined;
                }
            );
        }
    };
    handleDisable() {}
    isBossEngaged(atTime: number) {
        if (!this.combat.isInCombat(atTime)) {
            return false;
        }
        const dbmEngaged =
            dbmClass != undefined &&
            this.engagedDBM != undefined &&
            this.engagedDBM.inCombat;
        const bigWigsEngaged =
            bigWigsLoader != undefined &&
            this.engagedBigWigs != undefined &&
            this.engagedBigWigs.isEngaged;
        const neitherEngaged =
            dbmClass == undefined &&
            bigWigsLoader == undefined &&
            this.scanTargets();
        if (dbmEngaged) {
            this.tracer.debug(
                "DBM Engaged: [name=%s]",
                this.engagedDBM.localization.general.name
            );
        }
        if (bigWigsEngaged) {
            this.tracer.debug(
                "BigWigs Engaged: [name=%s]",
                this.engagedBigWigs.displayName
            );
        }
        return dbmEngaged || bigWigsEngaged || neitherEngaged;
    }
    scanTargets() {
        this.profiler.startProfiling("OvaleBossMod:ScanTargets");
        let bossEngaged = false;
        if (UnitExists("target")) {
            bossEngaged = UnitClassification("target") == "worldboss" || false;
        }
        // const RecursiveScanTargets = (target: string, depth?: number):boolean => {
        //     let isWorldBoss = false;
        //     let dep = depth || 1;
        //     isWorldBoss = target != undefined && UnitExists(target) && UnitLevel(target) < 0;
        //     if (isWorldBoss) {
        //         this.Debug("%s is worldboss (%s)", target, UnitName(target));
        //     }
        //     return isWorldBoss || (dep <= 3 && RecursiveScanTargets(`${target}target`, dep + 1));
        // }
        // let bossEngaged = false;
        // bossEngaged = bossEngaged || UnitExists("boss1") || UnitExists("boss2") || UnitExists("boss3") || UnitExists("boss4");
        // bossEngaged = bossEngaged || RecursiveScanTargets("target") || RecursiveScanTargets("pet") || RecursiveScanTargets("focus") || RecursiveScanTargets("focuspet") || RecursiveScanTargets("mouseover") || RecursiveScanTargets("mouseoverpet");
        // if (!bossEngaged) {
        //     if ((IsInInstance() && IsInGroup(LE_PARTY_CATEGORY_INSTANCE) && GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 1)) {
        //         for (let i = 1; i <= GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE); i += 1) {
        //             bossEngaged = bossEngaged || RecursiveScanTargets(`party${i}`) || RecursiveScanTargets(`party${i}pet`);
        //         }
        //     }
        //     if ((!IsInInstance() && IsInGroup(LE_PARTY_CATEGORY_HOME) && GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1)) {
        //         for (let i = 1; i <= GetNumGroupMembers(LE_PARTY_CATEGORY_HOME); i += 1) {
        //             bossEngaged = bossEngaged || RecursiveScanTargets(`party${i}`) || RecursiveScanTargets(`party${i}pet`);
        //         }
        //     }
        //     if ((IsInInstance() && IsInRaid(LE_PARTY_CATEGORY_INSTANCE) && GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 1)) {
        //         for (let i = 1; i <= GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE); i += 1) {
        //             bossEngaged = bossEngaged || RecursiveScanTargets(`raid${i}`) || RecursiveScanTargets(`raid${i}pet`);
        //         }
        //     }
        //     if ((!IsInInstance() && IsInRaid(LE_PARTY_CATEGORY_HOME) && GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1)) {
        //         for (let i = 1; i <= GetNumGroupMembers(LE_PARTY_CATEGORY_HOME); i += 1) {
        //             bossEngaged = bossEngaged || RecursiveScanTargets(`raid${i}`) || RecursiveScanTargets(`raid${i}pet`);
        //         }
        //     }
        // }
        this.profiler.stopProfiling("OvaleBossMod:ScanTargets");
        return bossEngaged;
    }
}
