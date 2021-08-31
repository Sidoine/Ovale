import { l } from "./Localization";
import { Tracer, DebugTools } from "../engine/debug";
import { OvaleOptionsClass } from "./Options";
import { OvaleClass, messagePrefix } from "../Ovale";
import aceComm, { AceComm } from "@wowts/ace_comm-3.0";
import aceSerializer, { AceSerializer } from "@wowts/ace_serializer-3.0";
import aceTimer, { Timer, AceTimer } from "@wowts/ace_timer-3.0";
import { format } from "@wowts/string";
import { ipairs, next, pairs, wipe, LuaObj, version } from "@wowts/lua";
import { insert, sort } from "@wowts/table";
import {
    IsInGroup,
    IsInGuild,
    IsInRaid,
    LE_PARTY_CATEGORY_INSTANCE,
} from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
import { OptionUiAll } from "./acegui-helpers";

const printTable: LuaObj<string> = {};
const userVersions: LuaObj<string> = {};
let timer: Timer | undefined;

export class OvaleVersionClass {
    warned = false;
    private module: AceModule & AceComm & AceTimer & AceSerializer;
    private tracer: Tracer;

    constructor(
        ovale: OvaleClass,
        ovaleOptions: OvaleOptionsClass,
        ovaleDebug: DebugTools
    ) {
        this.module = ovale.createModule(
            "OvaleVersion",
            this.handleInitialize,
            this.handleDisable,
            aceComm,
            aceSerializer,
            aceTimer
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
        const actions: LuaObj<OptionUiAll> = {
            ping: {
                name: l["ping_users"],
                type: "execute",
                func: () => {
                    this.versionCheck();
                },
            },
            version: {
                name: l["show_version_number"],
                type: "execute",
                func: () => {
                    this.tracer.print(version);
                },
            },
        };
        for (const [k, v] of pairs(actions)) {
            ovaleOptions.actions.args[k] = v;
        }
        ovaleOptions.registerOptions();
    }

    private handleInitialize = () => {
        this.module.RegisterComm(messagePrefix, this.handleCommReceived);
    };

    private handleDisable = () => {};

    private handleCommReceived = (
        prefix: string,
        message: string,
        channel: string,
        sender: string
    ) => {
        if (prefix == messagePrefix) {
            const [ok, msgType, senderVersion] =
                this.module.Deserialize(message);
            if (ok) {
                this.tracer.debug(msgType, senderVersion, channel, sender);
                if (msgType == "V") {
                    const msg = this.module.Serialize("VR", version);
                    this.module.SendCommMessage(messagePrefix, msg, channel);
                } else if (msgType == "VR") {
                    userVersions[sender] = senderVersion;
                }
            }
        }
    };
    versionCheck() {
        if (!timer) {
            wipe(userVersions);
            const message = this.module.Serialize("V", version);
            let channel;
            if (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) {
                channel = "INSTANCE_CHAT";
            } else if (IsInRaid()) {
                channel = "RAID";
            } else if (IsInGroup()) {
                channel = "PARTY";
            } else if (IsInGuild()) {
                channel = "GUILD";
            }
            if (channel) {
                this.module.SendCommMessage(messagePrefix, message, channel);
            }
            timer = this.module.ScheduleTimer(this.printVersionCheck, 3);
        }
    }

    private printVersionCheck = () => {
        if (next(userVersions)) {
            wipe(printTable);
            for (const [sender, userVersion] of pairs(userVersions)) {
                insert(
                    printTable,
                    format(">>> %s is using Ovale %s", sender, userVersion)
                );
            }
            sort(printTable);
            for (const [, v] of ipairs(printTable)) {
                this.tracer.print(v);
            }
        } else {
            this.tracer.print(">>> No other Ovale users present.");
        }
        timer = undefined;
    };
}
