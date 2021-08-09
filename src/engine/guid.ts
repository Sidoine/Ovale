import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray, LuaObj, ipairs, lualength, pairs, unpack } from "@wowts/lua";
import { concat, insert } from "@wowts/table";
import { GetUnitName, UnitGUID, UnitIsUnit } from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { Tracer, DebugTools } from "./debug";
import { binaryInsertUnique, binaryRemove } from "../tools/array";
import { OptionUiGroup } from "../ui/acegui-helpers";

function dumpMapping(t: LuaObj<LuaArray<string>>, output: LuaArray<string>) {
    for (const [key, array] of pairs(t)) {
        const size = lualength(array);
        if (size > 1) {
            insert(output, `    ${key}: {`);
            for (const [, value] of ipairs(array)) {
                insert(output, `        ${value},`);
            }
            insert(output, `    },`);
        } else if (size == 1) {
            insert(output, `    ${key}: ${array[1]},`);
        }
    }
}

export class Guids {
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    private guidByUnit: LuaObj<string> = {};
    private unitByGUID: LuaObj<LuaArray<string>> = {};
    private nameByUnit: LuaObj<string> = {};
    private unitByName: LuaObj<LuaArray<string>> = {};
    private nameByGUID: LuaObj<string> = {};
    private guidByName: LuaObj<LuaArray<string>> = {};
    private ownerGUIDByGUID: LuaObj<string> = {};

    private childUnitByUnit: LuaObj<LuaObj<boolean>> = {};
    private petUnitByUnit: LuaObj<string> = {};

    // eventfulUnits is an ordered array of unit IDs that receive unit events.
    private eventfulUnits: LuaArray<string> = {};
    private unitPriority: LuaObj<number> = {};
    unitAuraUnits: LuaObj<boolean> = {};

    petGUID: LuaObj<boolean> = {};

    private debugGUIDs: OptionUiGroup = {
        type: "group",
        name: "GUID",
        args: {
            guid: {
                type: "input",
                name: "GUID",
                multiline: 25,
                width: "full",
                get: () => {
                    const output: LuaArray<string> = {};
                    insert(output, "Unit by GUID = {");
                    dumpMapping(this.unitByGUID, output);
                    insert(output, "}\n");
                    insert(output, "Unit by Name = {");
                    dumpMapping(this.unitByName, output);
                    insert(output, "}\n");
                    insert(output, "GUID by Name = {");
                    dumpMapping(this.guidByName, output);
                    insert(output, "}");
                    return concat(output, "\n");
                },
            },
        },
    };

    constructor(private ovale: OvaleClass, debug: DebugTools) {
        debug.defaultOptions.args["guid"] = this.debugGUIDs;

        this.module = ovale.createModule(
            "OvaleGUID",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.tracer = debug.create(this.module.GetName());

        this.petUnitByUnit["player"] = "pet";
        insert(this.eventfulUnits, "player");
        insert(this.eventfulUnits, "vehicle");
        insert(this.eventfulUnits, "pet");
        for (let i = 1; i <= 40; i += 1) {
            const unit = `raid${i}`;
            const petUnit = `raidpet${i}`;
            this.petUnitByUnit[unit] = petUnit;
            insert(this.eventfulUnits, unit);
            insert(this.eventfulUnits, petUnit);
        }
        for (let i = 1; i <= 4; i += 1) {
            const unit = `party${i}`;
            const petUnit = `partypet${i}`;
            this.petUnitByUnit[unit] = petUnit;
            insert(this.eventfulUnits, unit);
            insert(this.eventfulUnits, petUnit);
        }
        for (let i = 1; i <= 3; i += 1) {
            const unit = `arena${i}`;
            const petUnit = `arenapet${i}`;
            this.petUnitByUnit[unit] = petUnit;
            insert(this.eventfulUnits, unit);
            insert(this.eventfulUnits, petUnit);
        }
        for (let i = 1; i <= 5; i += 1) {
            insert(this.eventfulUnits, `boss{i}`);
        }
        insert(this.eventfulUnits, "target");
        insert(this.eventfulUnits, "focus");
        for (const [priority, unit] of ipairs(this.eventfulUnits)) {
            this.unitAuraUnits[unit] = true;
            this.unitPriority[unit] = priority;
        }
    }

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
        if (eventType != "cleared" || this.guidByUnit[unitId]) {
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
        for (let i = 1; i <= 5; i += 1) {
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
    private handleUnitPet = (event: string, unit: string) => {
        this.tracer.debug(event, unit);
        const petUnit = this.getPetUnitByUnit(unit);
        this.addChildUnit(unit, petUnit);
        this.updateUnitWithTarget(petUnit);
        const petGUID = this.guidByUnit[petUnit];
        if (petGUID) {
            const guid = this.guidByUnit[unit];
            this.tracer.debug("Ovale_PetChanged", guid, unit, petGUID, petUnit);
            this.mapOwnerGUIDToGUID(guid, petGUID);
            this.module.SendMessage(
                "Ovale_PetChanged",
                guid,
                unit,
                petGUID,
                petUnit
            );
        }
        this.module.SendMessage("Ovale_GroupChanged");
    };
    private handleUnitTarget = (event: string, unit: string) => {
        if (unit != "player" && !UnitIsUnit(unit, "player")) {
            this.tracer.debug(event, unit);
            const targetUnit = this.getTargetUnitByUnit(unit);
            this.addChildUnit(unit, targetUnit);
            this.updateUnit(targetUnit);
        }
    };
    private updateAllUnits = () => {
        for (const [, unitId] of ipairs(this.eventfulUnits)) {
            this.updateUnitWithTarget(unitId);
        }
    };

    getUnitGUID(unitId: string): string | undefined {
        return this.guidByUnit[unitId] || UnitGUID(unitId);
    }
    getUnitByGUID(guid: string) {
        if (guid && this.unitByGUID[guid]) {
            return unpack(this.unitByGUID[guid]);
        }
        return [undefined];
    }
    getUnitName(unitId: string) {
        if (unitId) {
            return this.nameByUnit[unitId] || GetUnitName(unitId, true);
        }
        return undefined;
    }
    getUnitByName(name: string) {
        if (name && this.unitByName[name]) {
            return unpack(this.unitByName[name]);
        }
        return undefined;
    }
    getNameByGUID(guid: string) {
        if (guid) {
            return this.nameByGUID[guid];
        }
        return undefined;
    }
    getGUIDByName(name: string) {
        if (name && this.guidByName[name]) {
            return unpack(this.guidByName[name]);
        }
        return [];
    }

    getOwnerGUIDByGUID = (guid: string) => {
        return this.ownerGUIDByGUID[guid];
    };

    getPetUnitByUnit = (unit: string) => {
        return this.petUnitByUnit[unit] || `${unit}pet`;
    };

    getTargetUnitByUnit = (unit: string) => {
        return (unit == "player" && "target") || `${unit}target`;
    };

    private addChildUnit = (unit: string, childUnit: string) => {
        const t = this.childUnitByUnit[unit] || {};
        if (!t[childUnit]) {
            t[childUnit] = true;
            this.childUnitByUnit[unit] = t;
        }
    };

    private getUnitPriority = (unit: string) => {
        const t = this.unitPriority;
        let priority = t[unit];
        if (!priority) {
            priority = lualength(t) + 1;
            t[unit] = priority;
        }
        return priority;
    };

    private compareUnit = (a: string, b: string) => {
        return this.getUnitPriority(a) < this.getUnitPriority(b);
    };

    private mapOwnerGUIDToGUID = (ownerGUID: string, guid: string) => {
        this.ownerGUIDByGUID[guid] = ownerGUID;
        if (ownerGUID == this.ovale.playerGUID) {
            this.petGUID[guid] = true;
        }
    };

    private mapNameToUnit = (name: string, unit: string) => {
        this.nameByUnit[unit] = name;
        const t = this.unitByName[name] || {};
        binaryInsertUnique(t, unit, this.compareUnit);
        this.unitByName[name] = t;
    };

    private unmapNameToUnit = (name: string, unit: string) => {
        delete this.nameByUnit[unit];
        const t = this.unitByName[name] || {};
        if (t) {
            binaryRemove(t, unit, this.compareUnit);
            if (lualength(t) == 0) {
                delete this.unitByName[name];
            }
        }
    };

    private mapNameToGUID = (name: string, guid: string) => {
        this.nameByGUID[guid] = name;
        const t = this.guidByName[name] || {};
        binaryInsertUnique(t, guid);
        this.guidByName[name] = t;
    };

    private unmapNameToGUID = (name: string, guid: string) => {
        delete this.nameByGUID[guid];
        const t = this.guidByName[name] || {};
        if (t) {
            binaryRemove(t, guid);
            if (lualength(t) == 0) {
                delete this.guidByName[name];
            }
        }
    };

    private mapGUIDToUnit = (guid: string, unit: string) => {
        this.guidByUnit[unit] = guid;
        const t = this.unitByGUID[guid] || {};
        binaryInsertUnique(t, unit, this.compareUnit);
        this.unitByGUID[guid] = t;
    };

    private unmapGUIDToUnit = (guid: string, unit: string) => {
        delete this.guidByUnit[unit];
        const t = this.unitByGUID[guid] || {};
        if (t) {
            binaryRemove(t, unit, this.compareUnit);
            if (lualength(t) == 0) {
                delete this.unitByGUID[unit];
            }
        }
    };

    private unmapUnit = (unit: string) => {
        const children = this.childUnitByUnit[unit];
        if (children) {
            for (const [childUnit] of pairs(children)) {
                delete children[childUnit];
                // recursively remove child units
                this.unmapUnit(childUnit);
            }
        }
        const guid = this.guidByUnit[unit];
        if (guid) {
            this.unmapGUIDToUnit(guid, unit);
        }
        const name = this.nameByUnit[unit];
        if (name) {
            this.unmapNameToUnit(name, unit);
        }
    };

    private updateUnit = (
        unit: string,
        guid?: string | undefined,
        changed?: LuaObj<string>
    ) => {
        guid = guid || UnitGUID(unit);
        const name = GetUnitName(unit, true);

        if (guid && name) {
            let updated = false;
            const oldGUID = this.guidByUnit[unit];
            const oldName = this.nameByUnit[unit];
            if (guid != oldGUID) {
                if (oldGUID) {
                    this.unmapGUIDToUnit(oldGUID, unit);
                }
                this.tracer.debug(`'${unit}' is '${guid}'`);
                this.mapGUIDToUnit(guid, unit);
                updated = true;
                this.ovale.refreshNeeded[guid] = true;
            }
            if (name != oldName) {
                if (oldName) {
                    this.unmapNameToUnit(oldName, unit);
                    if (guid == oldGUID) {
                        // unit has same GUID, but the name changed
                        this.unmapNameToGUID(oldName, guid);
                    }
                }
                this.tracer.debug(`'${unit}' is '${name}'`);
                this.mapNameToUnit(name, unit);
                updated = true;
            }
            if (updated) {
                const nameByGUID = this.nameByGUID[guid];
                if (!nameByGUID) {
                    this.tracer.debug(`'${guid}' is '${name}'`);
                    this.mapNameToGUID(name, guid);
                } else if (name != nameByGUID) {
                    this.tracer.debug(`'${guid}' changed names to '${name}'`);
                    this.mapNameToGUID(name, guid);
                }
                if (changed) {
                    changed[guid] = unit;
                } else {
                    this.tracer.debug("Ovale_UnitChanged", unit, guid, name);
                    this.module.SendMessage(
                        "Ovale_UnitChanged",
                        unit,
                        guid,
                        name
                    );
                }
            }
        } else {
            // unit is gone
            this.unmapUnit(unit);
        }
    };

    private updateUnitWithTarget = (
        unit: string,
        guid?: string,
        changed?: LuaObj<string>
    ) => {
        this.updateUnit(unit, guid, changed);
        const targetUnit = this.getTargetUnitByUnit(unit);
        const targetGUID = this.getUnitGUID(targetUnit);
        if (targetGUID) {
            this.addChildUnit(unit, targetUnit);
            this.updateUnit(targetUnit, targetGUID, changed);
        }
    };
}
