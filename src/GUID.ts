import { OvaleDebug } from "./Debug";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { floor } from "@wowts/math";
import { ipairs, setmetatable, type, unpack, LuaArray, lualength, LuaObj } from "@wowts/lua";
import { insert, remove } from "@wowts/table";
import { GetTime, UnitGUID, UnitName } from "@wowts/wow-mock";

let OvaleGUIDBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleGUID", aceEvent));
let PET_UNIT = {
}
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

let UNIT_AURA_UNIT = {}

for (const [i, unitId] of ipairs(UNIT_AURA_UNITS)) {
    UNIT_AURA_UNIT[unitId] = i;
}
setmetatable(UNIT_AURA_UNIT, {
    __index: function (t, unitId) {
        return lualength(UNIT_AURA_UNITS) + 1;
    }
});

const compareDefault = function(a, b) {
    return a < b;
}
function BinaryInsert<T>(t: LuaArray<T>, value:T, unique, compare?) {
    if (type(unique) == "function") {
        [unique, compare] = [undefined, unique];
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
function BinarySearch<T>(t: LuaArray<T>, value:T, compare) {
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

function BinaryRemove<T>(t: LuaArray<T>, value:T, compare) {
    let index = BinarySearch(t, value, compare);
    if (index) {
        remove(t, index);
    }
    return index;
}
const CompareUnit = function(a, b) {
    return UNIT_AURA_UNIT[a] < UNIT_AURA_UNIT[b];
}
class OvaleGUIDClass extends OvaleGUIDBase {

    unitGUID: LuaObj<string> = {}
    guidUnit: LuaObj<LuaArray<string>> = {}
    unitName: LuaObj<string> = {}
    nameUnit: LuaObj<LuaArray<string>> = {}
    guidName: LuaObj<string> = {}
    nameGUID: LuaObj<LuaArray<string>> = {}
    petGUID: LuaObj<number> = {}
    UNIT_AURA_UNIT = UNIT_AURA_UNIT;
    
    constructor() {
        super();
        this.RegisterEvent("ARENA_OPPONENT_UPDATE");
        this.RegisterEvent("GROUP_ROSTER_UPDATE");
        this.RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT");
        this.RegisterEvent("PLAYER_ENTERING_WORLD", event => this.UpdateAllUnits());
        this.RegisterEvent("PLAYER_FOCUS_CHANGED");
        this.RegisterEvent("PLAYER_TARGET_CHANGED");
        this.RegisterEvent("UNIT_NAME_UPDATE");
        this.RegisterEvent("UNIT_PET");
        this.RegisterEvent("UNIT_TARGET");
    }
    OnDisable() {
        this.UnregisterEvent("ARENA_OPPONENT_UPDATE");
        this.UnregisterEvent("GROUP_ROSTER_UPDATE");
        this.UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT");
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("PLAYER_FOCUS_CHANGED");
        this.UnregisterEvent("PLAYER_TARGET_CHANGED");
        this.UnregisterEvent("UNIT_NAME_UPDATE");
        this.UnregisterEvent("UNIT_PET");
        this.UnregisterEvent("UNIT_TARGET");
    }
    ARENA_OPPONENT_UPDATE(event, unitId, eventType) {
        if (eventType != "cleared" || this.unitGUID[unitId]) {
            this.Debug(event, unitId, eventType);
            this.UpdateUnitWithTarget(unitId);
        }
    }
    GROUP_ROSTER_UPDATE(event) {
        this.Debug(event);
        this.UpdateAllUnits();
        this.SendMessage("Ovale_GroupChanged");
    }
    INSTANCE_ENCOUNTER_ENGAGE_UNIT(event) {
        this.Debug(event);
        for (let i = 1; i <= 4; i += 1) {
            this.UpdateUnitWithTarget(`boss${i}`);
        }
    }
    PLAYER_FOCUS_CHANGED(event) {
        this.Debug(event);
        this.UpdateUnitWithTarget("focus");
    }
    PLAYER_TARGET_CHANGED(event, cause) {
        this.Debug(event, cause);
        this.UpdateUnit("target");
    }
    UNIT_NAME_UPDATE(event, unitId) {
        this.Debug(event, unitId);
        this.UpdateUnit(unitId);
    }
    UNIT_PET(event, unitId) {
        this.Debug(event, unitId);
        let pet = PET_UNIT[unitId];
        this.UpdateUnitWithTarget(pet);
        if (unitId == "player") {
            let guid = this.UnitGUID("pet");
            if (guid) {
                this.petGUID[guid] = GetTime();
            }
            this.SendMessage("Ovale_PetChanged", guid);
        }
        this.SendMessage("Ovale_GroupChanged");
    }
    UNIT_TARGET(event, unitId) {
        if (unitId != "player") {
            this.Debug(event, unitId);
            let target = `${unitId}target`;
            this.UpdateUnit(target);
        }
    }
    UpdateAllUnits() {
        for (const [, unitId] of ipairs(UNIT_AURA_UNITS)) {
            this.UpdateUnitWithTarget(unitId);
        }
    }
    UpdateUnit(unitId) {
        let guid = UnitGUID(unitId);
        let name = UnitName(unitId);
        let previousGUID = this.unitGUID[unitId];
        let previousName = this.unitName[unitId];
        if (!guid || guid != previousGUID) {
            this.unitGUID[unitId] = undefined;
            if (previousGUID) {
                if (this.guidUnit[previousGUID]) {
                    BinaryRemove(this.guidUnit[previousGUID], unitId, CompareUnit);
                }
                Ovale.refreshNeeded[previousGUID] = true;
            }
        }
        if (!name || name != previousName) {
            this.unitName[unitId] = undefined;
            if (previousName && this.nameUnit[previousName]) {
                BinaryRemove(this.nameUnit[previousName], unitId, CompareUnit);
            }
        }
        if (guid && guid == previousGUID && name && name != previousName) {
            this.guidName[guid] = undefined;
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
            this.Debug("'%s' is '%s'.", unitId, guid);
            Ovale.refreshNeeded[guid] = true;
        }
        if (name && name != previousName) {
            this.unitName[unitId] = name;
            {
                let list = this.nameUnit[name] || {}
                BinaryInsert(list, unitId, true, CompareUnit);
                this.nameUnit[name] = list;
            }
            this.Debug("'%s' is '%s'.", unitId, name);
        }
        if (guid && name) {
            let previousNameFromGUID = this.guidName[guid];
            this.guidName[guid] = name;
            if (name != previousNameFromGUID) {
                let list = this.nameGUID[name] || {}
                BinaryInsert(list, guid, true);
                this.nameGUID[name] = list;
                if (guid == previousGUID) {
                    this.Debug("'%s' changed names to '%s'.", guid, name);
                } else {
                    this.Debug("'%s' is '%s'.", guid, name);
                }
            }
        }
        if (guid && guid != previousGUID) {
            this.SendMessage("Ovale_UnitChanged", unitId, guid);
        }
    }
    UpdateUnitWithTarget(unitId) {
        this.UpdateUnit(unitId);
        this.UpdateUnit(`${unitId}target`);
    }
    IsPlayerPet(guid) {
        let atTime = this.petGUID[guid];
        return [(!!atTime), atTime];
    }
    UnitGUID(unitId) {
        if (unitId) {
            return this.unitGUID[unitId] || UnitGUID(unitId);
        }
        return undefined;
    }
    GUIDUnit(guid) {
        if (guid && this.guidUnit[guid]) {
            return unpack(this.guidUnit[guid]);
        }
        return undefined;
    }
    UnitName(unitId) {
        if (unitId) {
            return this.unitName[unitId] || UnitName(unitId);
        }
        return undefined;
    }
    NameUnit(name) {
        if (name && this.nameUnit[name]) {
            return unpack(this.nameUnit[name]);
        }
        return undefined;
    }
    GUIDName(guid) {
        if (guid) {
            return this.guidName[guid];
        }
        return undefined;
    }
    NameGUID(name) {
        if (name && this.nameGUID[name]) {
            return unpack(this.nameGUID[name]);
        }
        return undefined;
    }
}

export const OvaleGUID = new OvaleGUIDClass();