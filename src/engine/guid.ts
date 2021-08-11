import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    ipairs,
    setmetatable,
    unpack,
    LuaArray,
    lualength,
    LuaObj,
} from "@wowts/lua";
import { insert } from "@wowts/table";
import { GetTime, UnitGUID, UnitName } from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { Tracer, DebugTools } from "./debug";
import {
    ConditionFunction,
    OvaleConditionClass,
    returnConstant,
} from "./condition";
import { isString } from "../tools/tools";
import { binaryInsertUnique, binaryRemove } from "../tools/array";

const petUnits: LuaObj<string> = {};
{
    petUnits["player"] = "pet";
    for (let i = 1; i <= 5; i += 1) {
        petUnits[`arena${i}`] = `arenapet${i}`;
    }
    for (let i = 1; i <= 4; i += 1) {
        petUnits[`party${i}`] = `partypet${i}`;
    }
    for (let i = 1; i <= 40; i += 1) {
        petUnits[`raid${i}`] = `raidpet${i}`;
    }
    setmetatable(petUnits, {
        // eslint-disable-next-line @typescript-eslint/naming-convention
        __index: function (t, unitId) {
            return `${unitId}pet`;
        },
    });
}

const eventfulUnits: LuaArray<string> = {};
{
    insert(eventfulUnits, "player");
    insert(eventfulUnits, "pet");
    insert(eventfulUnits, "vehicle");
    insert(eventfulUnits, "target");
    insert(eventfulUnits, "focus");
    for (let i = 1; i <= 40; i += 1) {
        const unitId = `raid${i}`;
        const petUnitId = petUnits[unitId];
        insert(eventfulUnits, unitId);
        insert(eventfulUnits, petUnitId);
    }
    for (let i = 1; i <= 4; i += 1) {
        const unitId = `party${i}`;
        const petUnitId = petUnits[unitId];
        insert(eventfulUnits, unitId);
        insert(eventfulUnits, petUnitId);
    }
    for (let i = 1; i <= 4; i += 1) {
        const unitId = `boss{i}`;
        insert(eventfulUnits, unitId);
    }
    for (let i = 1; i <= 5; i += 1) {
        const unitId = `arena${i}`;
        const petUnitId = petUnits[unitId];
        insert(eventfulUnits, unitId);
        insert(eventfulUnits, petUnitId);
    }
    insert(eventfulUnits, "npc");
}

// eventfulUnit is table whose keys are unit IDs that receive unit events.
const eventfulUnit: LuaObj<boolean> = {};
const unitPriority: LuaObj<number> = {};
{
    for (const [i, unitId] of ipairs(eventfulUnits)) {
        eventfulUnit[unitId] = true;
        unitPriority[unitId] = i;
    }
}

const getUnitPriority = function (unitId: string) {
    let priority = unitPriority[unitId];
    if (!priority) {
        priority = lualength(unitPriority) + 1;
        unitPriority[unitId] = priority;
    }
    return priority;
};

const compareUnit = function (a: string, b: string) {
    return getUnitPriority(a) < getUnitPriority(b);
};

export class Guids {
    unitGUID: LuaObj<string> = {};
    guidUnit: LuaObj<LuaArray<string>> = {};
    unitName: LuaObj<string> = {};
    nameUnit: LuaObj<LuaArray<string>> = {};
    guidName: LuaObj<string> = {};
    nameGUID: LuaObj<LuaArray<string>> = {};
    petGUID: LuaObj<number> = {};
    unitAuraUnits = eventfulUnit;
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    constructor(
        private ovale: OvaleClass,
        ovaleDebug: DebugTools,
        condition: OvaleConditionClass
    ) {
        this.module = ovale.createModule(
            "OvaleGUID",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
        condition.registerCondition("guid", false, this.getGuid);
        condition.registerCondition("targetguid", false, this.getTargetGuid);
    }

    private getGuid: ConditionFunction = (_, namedParameters) => {
        const target =
            (isString(namedParameters.target) && namedParameters.target) ||
            "target";
        return returnConstant(this.getUnitGUID(target));
    };

    private getTargetGuid: ConditionFunction = (_, namedParameters) => {
        const target =
            (isString(namedParameters.target) && namedParameters.target) ||
            "target";
        return returnConstant(this.getUnitGUID(target + "target"));
    };

    private handleInitialize = () => {
        this.module.RegisterEvent(
            "ARENA_OPPONENT_UPDATE",
            this.handleArenaOpponentUpdated
        );
        this.module.RegisterEvent(
            "GROUP_ROSTER_UPDATE",
            this.handleGroupRosterUpdated
        );
        this.module.RegisterEvent(
            "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
            this.handleInstanceEncounterEngageUnit
        );
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", (event) =>
            this.updateAllUnits()
        );
        this.module.RegisterEvent(
            "PLAYER_FOCUS_CHANGED",
            this.handlePlayerFocusChanged
        );
        this.module.RegisterEvent(
            "PLAYER_TARGET_CHANGED",
            this.handlePlayerTargetChanged
        );
        this.module.RegisterEvent(
            "UNIT_NAME_UPDATE",
            this.handleUnitNameUpdate
        );
        this.module.RegisterEvent("UNIT_PET", this.handleUnitPet);
        this.module.RegisterEvent("UNIT_TARGET", this.handleUnitTarget);
    };
    private handleDisable = () => {
        this.module.UnregisterEvent("ARENA_OPPONENT_UPDATE");
        this.module.UnregisterEvent("GROUP_ROSTER_UPDATE");
        this.module.UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_FOCUS_CHANGED");
        this.module.UnregisterEvent("PLAYER_TARGET_CHANGED");
        this.module.UnregisterEvent("UNIT_NAME_UPDATE");
        this.module.UnregisterEvent("UNIT_PET");
        this.module.UnregisterEvent("UNIT_TARGET");
    };
    private handleArenaOpponentUpdated = (
        event: string,
        unitId: string,
        eventType: string
    ) => {
        if (eventType != "cleared" || this.unitGUID[unitId]) {
            this.tracer.debug(event, unitId, eventType);
            this.updateUnitWithTarget(unitId);
        }
    };
    private handleGroupRosterUpdated = (event: string) => {
        this.tracer.debug(event);
        this.updateAllUnits();
        this.module.SendMessage("Ovale_GroupChanged");
    };
    private handleInstanceEncounterEngageUnit = (event: string) => {
        this.tracer.debug(event);
        for (let i = 1; i <= 4; i += 1) {
            this.updateUnitWithTarget(`boss${i}`);
        }
    };
    private handlePlayerFocusChanged = (event: string) => {
        this.tracer.debug(event);
        this.updateUnitWithTarget("focus");
    };
    private handlePlayerTargetChanged = (event: string, cause: string) => {
        this.tracer.debug(event, cause);
        this.updateUnit("target");
    };
    private handleUnitNameUpdate = (event: string, unitId: string) => {
        this.tracer.debug(event, unitId);
        this.updateUnit(unitId);
    };
    private handleUnitPet = (event: string, unitId: string) => {
        this.tracer.debug(event, unitId);
        const pet = petUnits[unitId];
        this.updateUnitWithTarget(pet);
        if (unitId == "player") {
            const guid = this.getUnitGUID("pet");
            if (guid) {
                this.petGUID[guid] = GetTime();
            }
            this.module.SendMessage("Ovale_PetChanged", guid);
        }
        this.module.SendMessage("Ovale_GroupChanged");
    };
    private handleUnitTarget = (event: string, unitId: string) => {
        if (unitId != "player") {
            this.tracer.debug(event, unitId);
            const target = `${unitId}target`;
            this.updateUnit(target);
        }
    };
    updateAllUnits() {
        for (const [, unitId] of ipairs(eventfulUnits)) {
            this.updateUnitWithTarget(unitId);
        }
    }
    updateUnit(unitId: string) {
        const guid = UnitGUID(unitId);
        const [name] = UnitName(unitId);
        const previousGUID = this.unitGUID[unitId];
        const previousName = this.unitName[unitId];
        if (!guid || guid != previousGUID) {
            delete this.unitGUID[unitId];
            if (previousGUID) {
                if (this.guidUnit[previousGUID]) {
                    binaryRemove(
                        this.guidUnit[previousGUID],
                        unitId,
                        compareUnit
                    );
                }
                this.ovale.refreshNeeded[previousGUID] = true;
            }
        }
        if (!name || name != previousName) {
            delete this.unitName[unitId];
            if (previousName && this.nameUnit[previousName]) {
                binaryRemove(this.nameUnit[previousName], unitId, compareUnit);
            }
        }
        if (guid && guid == previousGUID && name && name != previousName) {
            delete this.guidName[guid];
            if (previousName && this.nameGUID[previousName]) {
                binaryRemove(this.nameGUID[previousName], guid, compareUnit);
            }
        }
        if (guid && guid != previousGUID) {
            this.unitGUID[unitId] = guid;
            {
                const list = this.guidUnit[guid] || {};
                binaryInsertUnique(list, unitId, compareUnit);
                this.guidUnit[guid] = list;
            }
            this.tracer.debug("'%s' is '%s'.", unitId, guid);
            this.ovale.refreshNeeded[guid] = true;
        }
        if (name && name != previousName) {
            this.unitName[unitId] = name;
            {
                const list = this.nameUnit[name] || {};
                binaryInsertUnique(list, unitId, compareUnit);
                this.nameUnit[name] = list;
            }
            this.tracer.debug("'%s' is '%s'.", unitId, name);
        }
        if (guid && name) {
            const previousNameFromGUID = this.guidName[guid];
            this.guidName[guid] = name;
            if (name != previousNameFromGUID) {
                const list = this.nameGUID[name] || {};
                binaryInsertUnique(list, guid);
                this.nameGUID[name] = list;
                if (guid == previousGUID) {
                    this.tracer.debug(
                        "'%s' changed names to '%s'.",
                        guid,
                        name
                    );
                } else {
                    this.tracer.debug("'%s' is '%s'.", guid, name);
                }
            }
        }
        if (guid && guid != previousGUID) {
            this.module.SendMessage("Ovale_UnitChanged", unitId, guid);
        }
    }
    updateUnitWithTarget(unitId: string) {
        this.updateUnit(unitId);
        this.updateUnit(`${unitId}target`);
    }
    isPlayerPet(guid: string): [boolean, number] {
        const atTime = this.petGUID[guid];
        return [!!atTime, atTime];
    }
    getUnitGUID(unitId: string): string | undefined {
        return this.unitGUID[unitId] || UnitGUID(unitId);
    }
    getUnitByGuid(guid: string) {
        if (guid && this.guidUnit[guid]) {
            return unpack(this.guidUnit[guid]);
        }
        return [undefined];
    }
    getUnitName(unitId: string) {
        if (unitId) {
            if (this.unitName[unitId]) {
                return this.unitName[unitId];
            } else {
                const [name] = UnitName(unitId);
                return name;
            }
        }
        return undefined;
    }
    getUnitByName(name: string) {
        if (name && this.nameUnit[name]) {
            return unpack(this.nameUnit[name]);
        }
        return undefined;
    }
    getNameByGuid(guid: string) {
        if (guid) {
            return this.guidName[guid];
        }
        return undefined;
    }
    getGuidByName(name: string) {
        if (name && this.nameGUID[name]) {
            return unpack(this.nameGUID[name]);
        }
        return [];
    }
}
