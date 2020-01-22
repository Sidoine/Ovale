import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { floor } from "@wowts/math";
import { ipairs, setmetatable, type, unpack, LuaArray, lualength, LuaObj } from "@wowts/lua";
import { insert, remove } from "@wowts/table";
import { GetTime, UnitGUID, UnitName } from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "./Ovale";
import { Tracer, OvaleDebugClass } from "./Debug";

let PET_UNIT:LuaObj<string> = {}
{
    PET_UNIT["player"] = "pet";
    for (let i = 1; i <= 5; i += 1) {
        PET_UNIT[`arena${i}`] = `arenapet${i}`;
    }
    for (let i = 1; i <= 4; i += 1) {
        PET_UNIT[`party${i}`] = `partypet${i}`;
    }
    for (let i = 1; i <= 40; i += 1) {
        PET_UNIT[`raid${i}`] = `raidpet${i}`;
    }
    setmetatable(PET_UNIT, {
        __index: function (t, unitId) {
            return `${unitId}pet`;
        }
    });
}
let UNIT_AURA_UNITS: LuaArray<string> = {
}
{
    insert(UNIT_AURA_UNITS, "player");
    insert(UNIT_AURA_UNITS, "pet");
    insert(UNIT_AURA_UNITS, "vehicle");
    insert(UNIT_AURA_UNITS, "target");
    insert(UNIT_AURA_UNITS, "focus");
    for (let i = 1; i <= 40; i += 1) {
        let unitId = `raid${i}`;
        insert(UNIT_AURA_UNITS, unitId);
        insert(UNIT_AURA_UNITS, PET_UNIT[unitId]);
    }
    for (let i = 1; i <= 4; i += 1) {
        let unitId = `party${i}`;
        insert(UNIT_AURA_UNITS, unitId);
        insert(UNIT_AURA_UNITS, PET_UNIT[unitId]);
    }
    for (let i = 1; i <= 4; i += 1) {
        insert(UNIT_AURA_UNITS, `boss${i}`);
    }
    for (let i = 1; i <= 5; i += 1) {
        let unitId = `arena${i}`;
        insert(UNIT_AURA_UNITS, unitId);
        insert(UNIT_AURA_UNITS, PET_UNIT[unitId]);
    }
    insert(UNIT_AURA_UNITS, "npc");
}

let UNIT_AURA_UNIT: LuaObj<number> = {}

for (const [i, unitId] of ipairs(UNIT_AURA_UNITS)) {
    UNIT_AURA_UNIT[unitId] = i;
}
setmetatable(UNIT_AURA_UNIT, {
    __index: function (t, unitId) {
        return lualength(UNIT_AURA_UNITS) + 1;
    }
});

type CompareFunction<T> = (a:T, b:T) => boolean;

function compareDefault<T>(a: T, b: T) {
    return a < b;
}

function isCompareFunction<T>(a: any): a is CompareFunction<T> {
    return type(a) === "function";
}

function BinaryInsert<T>(t: LuaArray<T>, value:T, unique: boolean | CompareFunction<T>, compare?: CompareFunction<T>) {
    if (isCompareFunction<T>(unique)) {
        [unique, compare] = [false, unique];
    }
    compare = compare || compareDefault;
    let [low, high] = [1, lualength(t)];
    while (low <= high) {
        let mid = floor((low + high) / 2);
        if (compare(value, t[mid])) {
            high = mid - 1;
        } else if (!unique || compare(t[mid], value)) {
            low = mid + 1;
        } else {
            return mid;
        }
    }
    insert(t, low, value);
    return low;
}
function BinarySearch<T>(t: LuaArray<T>, value:T, compare: CompareFunction<T>) {
    compare = compare || compareDefault;
    let [low, high] = [1, lualength(t)];
    while (low <= high) {
        let mid = floor((low + high) / 2);
        if (compare(value, t[mid])) {
            high = mid - 1;
        } else if (compare(t[mid], value)) {
            low = mid + 1;
        } else {
            return mid;
        }
    }
    return undefined;
}

function BinaryRemove<T>(t: LuaArray<T>, value:T, compare: CompareFunction<T>) {
    let index = BinarySearch(t, value, compare);
    if (index) {
        remove(t, index);
    }
    return index;
}
const CompareUnit = function(a: string, b: string) {
    return UNIT_AURA_UNIT[a] < UNIT_AURA_UNIT[b];
}
export class OvaleGUIDClass {

    unitGUID: LuaObj<string> = {}
    guidUnit: LuaObj<LuaArray<string>> = {}
    unitName: LuaObj<string> = {}
    nameUnit: LuaObj<LuaArray<string>> = {}
    guidName: LuaObj<string> = {}
    nameGUID: LuaObj<LuaArray<string>> = {}
    petGUID: LuaObj<number> = {}
    UNIT_AURA_UNIT = UNIT_AURA_UNIT;
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    constructor(private ovale: OvaleClass, ovaleDebug: OvaleDebugClass) {
        this.module = ovale.createModule("OvaleGUID", this.OnInitialize, this.OnDisable, aceEvent)
        this.tracer = ovaleDebug.create(this.module.GetName());
    }

    private OnInitialize = () => {
        this.module.RegisterEvent("ARENA_OPPONENT_UPDATE", this.ARENA_OPPONENT_UPDATE);
        this.module.RegisterEvent("GROUP_ROSTER_UPDATE", this.GROUP_ROSTER_UPDATE);
        this.module.RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", this.INSTANCE_ENCOUNTER_ENGAGE_UNIT);
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", event => this.UpdateAllUnits());
        this.module.RegisterEvent("PLAYER_FOCUS_CHANGED", this.PLAYER_FOCUS_CHANGED);
        this.module.RegisterEvent("PLAYER_TARGET_CHANGED", this.PLAYER_TARGET_CHANGED);
        this.module.RegisterEvent("UNIT_NAME_UPDATE", this.UNIT_NAME_UPDATE);
        this.module.RegisterEvent("UNIT_PET", this.UNIT_PET);
        this.module.RegisterEvent("UNIT_TARGET", this.UNIT_TARGET);
    }
    private OnDisable = () => {
        this.module.UnregisterEvent("ARENA_OPPONENT_UPDATE");
        this.module.UnregisterEvent("GROUP_ROSTER_UPDATE");
        this.module.UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_FOCUS_CHANGED");
        this.module.UnregisterEvent("PLAYER_TARGET_CHANGED");
        this.module.UnregisterEvent("UNIT_NAME_UPDATE");
        this.module.UnregisterEvent("UNIT_PET");
        this.module.UnregisterEvent("UNIT_TARGET");
    }
    private ARENA_OPPONENT_UPDATE = (event: string, unitId: string, eventType: string) => {
        if (eventType != "cleared" || this.unitGUID[unitId]) {
            this.tracer.Debug(event, unitId, eventType);
            this.UpdateUnitWithTarget(unitId);
        }
    }
    private GROUP_ROSTER_UPDATE = (event: string) => {
        this.tracer.Debug(event);
        this.UpdateAllUnits();
        this.module.SendMessage("Ovale_GroupChanged");
    }
    private INSTANCE_ENCOUNTER_ENGAGE_UNIT = (event: string) => {
        this.tracer.Debug(event);
        for (let i = 1; i <= 4; i += 1) {
            this.UpdateUnitWithTarget(`boss${i}`);
        }
    }
    private PLAYER_FOCUS_CHANGED = (event: string) => {
        this.tracer.Debug(event);
        this.UpdateUnitWithTarget("focus");
    }
    private PLAYER_TARGET_CHANGED = (event: string, cause: string) => {
        this.tracer.Debug(event, cause);
        this.UpdateUnit("target");
    }
    private UNIT_NAME_UPDATE = (event: string, unitId: string) => {
        this.tracer.Debug(event, unitId);
        this.UpdateUnit(unitId);
    }
    private UNIT_PET = (event: string, unitId: string) => {
        this.tracer.Debug(event, unitId);
        let pet = PET_UNIT[unitId];
        this.UpdateUnitWithTarget(pet);
        if (unitId == "player") {
            let guid = this.UnitGUID("pet");
            if (guid) {
                this.petGUID[guid] = GetTime();
            }
            this.module.SendMessage("Ovale_PetChanged", guid);
        }
        this.module.SendMessage("Ovale_GroupChanged");
    }
    private UNIT_TARGET = (event: string, unitId: string) => {
        if (unitId != "player") {
            this.tracer.Debug(event, unitId);
            let target = `${unitId}target`;
            this.UpdateUnit(target);
        }
    }
    UpdateAllUnits() {
        for (const [, unitId] of ipairs(UNIT_AURA_UNITS)) {
            this.UpdateUnitWithTarget(unitId);
        }
    }
    UpdateUnit(unitId: string) {
        let guid = UnitGUID(unitId);
        let name = UnitName(unitId);
        let previousGUID = this.unitGUID[unitId];
        let previousName = this.unitName[unitId];
        if (!guid || guid != previousGUID) {
            delete this.unitGUID[unitId];
            if (previousGUID) {
                if (this.guidUnit[previousGUID]) {
                    BinaryRemove(this.guidUnit[previousGUID], unitId, CompareUnit);
                }
                this.ovale.refreshNeeded[previousGUID] = true;
            }
        }
        if (!name || name != previousName) {
            delete this.unitName[unitId];
            if (previousName && this.nameUnit[previousName]) {
                BinaryRemove(this.nameUnit[previousName], unitId, CompareUnit);
            }
        }
        if (guid && guid == previousGUID && name && name != previousName) {
            delete this.guidName[guid];
            if (previousName && this.nameGUID[previousName]) {
                BinaryRemove(this.nameGUID[previousName], guid, CompareUnit);
            }
        }
        if (guid && guid != previousGUID) {
            this.unitGUID[unitId] = guid;
            {
                let list = this.guidUnit[guid] || {}
                BinaryInsert(list, unitId, true, CompareUnit);
                this.guidUnit[guid] = list;
            }
            this.tracer.Debug("'%s' is '%s'.", unitId, guid);
            this.ovale.refreshNeeded[guid] = true;
        }
        if (name && name != previousName) {
            this.unitName[unitId] = name;
            {
                let list = this.nameUnit[name] || {}
                BinaryInsert(list, unitId, true, CompareUnit);
                this.nameUnit[name] = list;
            }
            this.tracer.Debug("'%s' is '%s'.", unitId, name);
        }
        if (guid && name) {
            let previousNameFromGUID = this.guidName[guid];
            this.guidName[guid] = name;
            if (name != previousNameFromGUID) {
                let list = this.nameGUID[name] || {}
                BinaryInsert(list, guid, true);
                this.nameGUID[name] = list;
                if (guid == previousGUID) {
                    this.tracer.Debug("'%s' changed names to '%s'.", guid, name);
                } else {
                    this.tracer.Debug("'%s' is '%s'.", guid, name);
                }
            }
        }
        if (guid && guid != previousGUID) {
            this.module.SendMessage("Ovale_UnitChanged", unitId, guid);
        }
    }
    UpdateUnitWithTarget(unitId: string) {
        this.UpdateUnit(unitId);
        this.UpdateUnit(`${unitId}target`);
    }
    IsPlayerPet(guid: string): [boolean, number] {
        let atTime = this.petGUID[guid];
        return [(!!atTime), atTime];
    }
    UnitGUID(unitId: string): string | undefined {
        return this.unitGUID[unitId] || UnitGUID(unitId);
    }
    GUIDUnit(guid: string) {
        if (guid && this.guidUnit[guid]) {
            return unpack(this.guidUnit[guid]);
        }
        return [undefined];
    }
    UnitName(unitId: string) {
        if (unitId) {
            return this.unitName[unitId] || UnitName(unitId);
        }
        return undefined;
    }
    NameUnit(name: string) {
        if (name && this.nameUnit[name]) {
            return unpack(this.nameUnit[name]);
        }
        return undefined;
    }
    GUIDName(guid: string) {
        if (guid) {
            return this.guidName[guid];
        }
        return undefined;
    }
    NameGUID(name: string) {
        if (name && this.nameGUID[name]) {
            return unpack(this.nameGUID[name]);
        }
        return [];
    }
}
