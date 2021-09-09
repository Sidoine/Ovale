import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import aceTimer, { AceTimer } from "@wowts/ace_timer-3.0";
import { LuaArray, ipairs, pairs, unpack } from "@wowts/lua";
import { concat, insert, sort } from "@wowts/table";
import { AceModule } from "@wowts/tsaddon";
import { C_Soulbinds, Enum, GetSpellInfo } from "@wowts/wow-mock";
import { OvaleClass } from "../Ovale";
import {
    ConditionFunction,
    ConditionResult,
    OvaleConditionClass,
    returnBoolean,
    returnConstant,
} from "../engine/condition";
import { conduits } from "../engine/dbc";
import { DebugTools, Tracer } from "../engine/debug";
import { OptionUiGroup } from "../ui/acegui-helpers";

export class Soulbind {
    private module: AceModule & AceEvent & AceTimer;
    private tracer: Tracer;

    private conduitSpellIdById: LuaArray<number> = {};
    // The following arrays are indexed by spell ID.
    private conduitId: LuaArray<number> = {};
    private conduitRank: LuaArray<number> = {};
    private isActiveConduit: LuaArray<boolean> = {};
    private isActiveTrait: LuaArray<boolean> = {};

    private debugConduitOptions: OptionUiGroup = {
        type: "group",
        name: "Conduits",
        args: {
            conduits: {
                type: "input",
                name: "Conduits",
                multiline: 25,
                width: "full",
                get: () => {
                    return this.debugConduits();
                },
            },
        },
    };

    private debugSoulbindTraitsOptions: OptionUiGroup = {
        type: "group",
        name: "Soulbind Traits",
        args: {
            soulbindTraits: {
                type: "input",
                name: "Soulbind Traits",
                multiline: 25,
                width: "full",
                get: () => {
                    return this.debugSoulbindTraits();
                },
            },
        },
    };

    constructor(ovale: OvaleClass, debug: DebugTools) {
        debug.defaultOptions.args["conduit"] = this.debugConduitOptions;
        debug.defaultOptions.args["soulbindTraits"] =
            this.debugSoulbindTraitsOptions;

        this.module = ovale.createModule(
            "Soulbind",
            this.onEnable,
            this.onDisable,
            aceEvent,
            aceTimer
        );
        this.tracer = debug.create(this.module.GetName());
    }

    private onEnable = () => {
        this.module.RegisterEvent(
            "COVENANT_CHOSEN",
            this.onSoulbindDataUpdated
        );
        this.module.RegisterEvent(
            "PLAYER_ENTERING_WORLD",
            this.onSoulbindDataUpdated
        );
        this.module.RegisterEvent("PLAYER_LOGIN", this.onPlayerLogin);
        this.module.RegisterEvent(
            "SOULBIND_ACTIVATED",
            this.onSoulbindDataUpdated
        );
        this.module.RegisterEvent(
            "SOULBIND_CONDUIT_COLLECTION_CLEARED",
            this.onSoulbindConduitCollectionUpdated
        );
        this.module.RegisterEvent(
            "SOULBIND_CONDUIT_COLLECTION_REMOVED",
            this.onSoulbindConduitCollectionUpdated
        );
        this.module.RegisterEvent(
            "SOULBIND_CONDUIT_COLLECTION_UPDATED",
            this.onSoulbindConduitCollectionUpdated
        );
        this.module.RegisterEvent(
            "SOULBIND_CONDUIT_INSTALLED",
            this.onSoulbindDataUpdated
        );
        this.module.RegisterEvent(
            "SOULBIND_CONDUIT_UNINSTALLED",
            this.onSoulbindDataUpdated
        );
        this.module.RegisterEvent(
            "SOULBIND_NODE_LEARNED",
            this.onSoulbindDataUpdated
        );
        this.module.RegisterEvent(
            "SOULBIND_NODE_UNLEARNED",
            this.onSoulbindDataUpdated
        );
        this.module.RegisterEvent(
            "SOULBIND_NODE_UPDATED",
            this.onSoulbindDataUpdated
        );
        this.module.RegisterEvent(
            "SOULBIND_PATH_CHANGED",
            this.onSoulbindDataUpdated
        );
        this.onSoulbindConduitCollectionUpdated("onEnable");
    };

    private onDisable = () => {
        this.module.UnregisterEvent("COVENANT_CHOSEN");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_LOGIN");
        this.module.UnregisterEvent("SOULBIND_ACTIVATED");
        this.module.UnregisterEvent("SOULBIND_CONDUIT_COLLECTION_CLEARED");
        this.module.UnregisterEvent("SOULBIND_CONDUIT_COLLECTION_REMOVED");
        this.module.UnregisterEvent("SOULBIND_CONDUIT_COLLECTION_UPDATED");
        this.module.UnregisterEvent("SOULBIND_CONDUIT_INSTALLED");
        this.module.UnregisterEvent("SOULBIND_CONDUIT_UNINSTALLED");
        this.module.UnregisterEvent("SOULBIND_NODE_LEARNED");
        this.module.UnregisterEvent("SOULBIND_NODE_UNLEARNED");
        this.module.UnregisterEvent("SOULBIND_NODE_UPDATED");
        this.module.UnregisterEvent("SOULBIND_PATH_CHANGED");
    };

    private onPlayerLogin = (event: string) => {
        /**
         * Update soulbind and conduit data at 3 seconds after player
         * login to workaround a delay in the information being available
         * to be queried from the game server.
         */
        this.module.ScheduleTimer(this.onPlayerLoginDelayed, 3);
    };

    private onPlayerLoginDelayed = () => {
        const event = "PLAYER_LOGIN";
        this.tracer.debug(event);
        this.onSoulbindConduitCollectionUpdated(event);
        this.onSoulbindDataUpdated(event);
    };

    private onSoulbindConduitCollectionUpdated = (event: string) => {
        this.tracer.debug(`${event}: Updating conduit collection.`);
        for (
            let conduitType = 0;
            conduitType <= Enum.SoulbindConduitType.Flex;
            conduitType++
        ) {
            const collectionData =
                C_Soulbinds.GetConduitCollection(conduitType);
            for (const [, data] of ipairs(collectionData)) {
                this.updateConduitData(data.conduitID);
            }
        }
    };

    private onSoulbindDataUpdated = (event: string) => {
        this.tracer.debug(`${event}: Updating soulbind data.`);
        this.isActiveConduit = {};
        this.isActiveTrait = {};
        const soulbindId = C_Soulbinds.GetActiveSoulbindID() || 0;
        this.tracer.debug(`${event}: active soulbind = ${soulbindId}`);
        if (soulbindId != 0) {
            const data = C_Soulbinds.GetSoulbindData(soulbindId);
            for (const [, node] of pairs(data.tree.nodes)) {
                //this.tracer.debug(`id=${node.conduitID}, spellId=${node.spellID}, state=${node.state}`);
                const isSelected =
                    node.state == Enum.SoulbindNodeState.Selected;
                // spellID is 0 for conduits; conduitID is 0 for traits
                const isTrait = node.spellID && node.spellID != 0;
                const isConduit = node.conduitID && node.conduitID != 0;
                if (isTrait) {
                    this.isActiveTrait[node.spellID] = isSelected;
                }
                if (isConduit) {
                    const id = node.conduitID;
                    this.updateConduitData(id);
                    if (isSelected) {
                        const spellId = this.conduitSpellIdById[id];
                        if (spellId) {
                            this.isActiveConduit[spellId] = true;
                        }
                    }
                }
            }
        }
    };

    private updateConduitData = (id: number) => {
        const rank = C_Soulbinds.GetConduitRank(id) || 0;
        const spellId = C_Soulbinds.GetConduitSpellID(id, rank);
        if (spellId != 0) {
            this.conduitSpellIdById[id] = spellId;
            this.conduitId[spellId] = id;
            this.conduitRank[spellId] = rank;
        }
    };

    private debugConduits = () => {
        const output: LuaArray<string> = {};
        for (const [spellId, id] of pairs(this.conduitId)) {
            const rank = this.conduitRank[spellId];
            const [name] = GetSpellInfo(spellId);
            if (this.isActiveConduit[spellId]) {
                insert(
                    output,
                    `${name}: ${spellId}, id=${id}, rank=${rank} (active)`
                );
            } else {
                insert(output, `${name}: ${spellId}, id=${id}, rank=${rank}`);
            }
        }
        sort(output);
        return concat(output, "\n");
    };

    private debugSoulbindTraits = () => {
        const output: LuaArray<string> = {};
        for (const [spellId, isActive] of pairs(this.isActiveTrait)) {
            const [name] = GetSpellInfo(spellId);
            if (isActive) {
                insert(output, `${name}: ${spellId} (active)`);
            } else {
                insert(output, `${name}: ${spellId}`);
            }
        }
        sort(output);
        return concat(output, "\n");
    };

    registerConditions(condition: OvaleConditionClass) {
        condition.registerCondition("conduit", false, this.conduitCondition);
        condition.registerCondition(
            "conduitrank",
            false,
            this.conduitRankCondition
        );
        condition.registerCondition(
            "enabledsoulbind",
            false,
            this.soulbindCondition
        );
        condition.registerCondition("soulbind", false, this.soulbindCondition);
        condition.register(
            "conduitvalue",
            this.conduitValue,
            { type: "number" },
            { name: "conduit", type: "number", optional: false }
        );
    }

    private conduitCondition: ConditionFunction = (positionalParameters) => {
        // Accept either a conduit ID or a spell ID for the parameter.
        const [id] = unpack(positionalParameters);
        const conduitId = this.conduitId[id as number] || (id as number);
        const spellId = this.conduitSpellIdById[conduitId];
        return returnBoolean(this.isActiveConduit[spellId]);
    };

    private conduitRankCondition: ConditionFunction = (
        positionalParameters
    ) => {
        // Accept either a conduit ID or a spell ID for the parameter.
        const [id] = unpack(positionalParameters);
        const conduitId = this.conduitId[id as number] || (id as number);
        const spellId = this.conduitSpellIdById[conduitId];
        const rank = this.conduitRank[spellId];
        if (rank) {
            return returnConstant(rank);
        } else {
            return [];
        }
    };

    private soulbindCondition: ConditionFunction = (positionalParameters) => {
        const [spellId] = unpack(positionalParameters);
        return returnBoolean(this.isActiveTrait[spellId as number]);
    };

    private conduitValue = (atTime: number, id: number): ConditionResult => {
        // Accept either a conduit ID or a spell ID for the parameter.
        const conduitId = this.conduitId[id] || id;
        const spellId = this.conduitSpellIdById[conduitId];
        const rank = this.conduitRank[spellId];
        if (rank) {
            const value = conduits[conduitId].ranks[rank];
            return returnConstant(value);
        } else {
            return [];
        }
    };
}
