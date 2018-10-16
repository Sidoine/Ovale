import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { UnitExists, UnitClassification } from "@wowts/wow-mock";
import { _G, hooksecurefunc } from "@wowts/lua";
import { OvaleFuture } from "./Future";
let OvaleBossModBase = OvaleProfiler.RegisterProfiling(OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleBossMod")));
let _BigWigsLoader: { RegisterMessage: any } = _G["BigWigsLoader"];
let _DBM = _G["DBM"];
class OvaleBossModClass extends OvaleBossModBase {
    EngagedDBM: any = undefined;
    EngagedBigWigs: any = undefined;

    OnInitialize() {
        if (_DBM) {
            this.Debug("DBM is loaded");
            hooksecurefunc(_DBM, "StartCombat", (_DBM, mod, delay, event, ...__args) => {
                if (event != "TIMER_RECOVERY") {
                    this.EngagedDBM = mod;
                }
            });
            hooksecurefunc(_DBM, "EndCombat", (_DBM, mod) => {
                this.EngagedDBM = undefined;
            });
        }
        if (_BigWigsLoader) {
            this.Debug("BigWigs is loaded");
            _BigWigsLoader.RegisterMessage(OvaleBossMod, "BigWigs_OnBossEngage", (_: any, mod: any, diff: any) => {
                this.EngagedBigWigs = mod;
            });
            _BigWigsLoader.RegisterMessage(OvaleBossMod, "BigWigs_OnBossDisable", (_: any, mod: any) => {
                this.EngagedBigWigs = undefined;
            });
        }
    }
    OnDisable() {
    }
    IsBossEngaged(atTime: number) {
        if (!OvaleFuture.IsInCombat(atTime)) {
            return false;
        }
        let dbmEngaged = (_DBM != undefined && this.EngagedDBM != undefined && this.EngagedDBM.inCombat);
        let bigWigsEngaged = (_BigWigsLoader != undefined && this.EngagedBigWigs != undefined && this.EngagedBigWigs.isEngaged);
        let neitherEngaged = (_DBM == undefined && _BigWigsLoader == undefined && this.ScanTargets());
        if (dbmEngaged) {
            this.Debug("DBM Engaged: [name=%s]", this.EngagedDBM.localization.general.name);
        }
        if (bigWigsEngaged) {
            this.Debug("BigWigs Engaged: [name=%s]", this.EngagedBigWigs.displayName);
        }
        return dbmEngaged || bigWigsEngaged || neitherEngaged;
    }
    ScanTargets() {
        this.StartProfiling("OvaleBossMod:ScanTargets");
        let bossEngaged = false; 
        if(UnitExists("target")){
            bossEngaged = (UnitClassification("target") == "worldboss") || false
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
        this.StopProfiling("OvaleBossMod:ScanTargets");
        return bossEngaged;
    }
}

export const OvaleBossMod = new OvaleBossModClass();