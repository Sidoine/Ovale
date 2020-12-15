import { L } from "./Localization";
import { Tracer, OvaleDebugClass } from "../engine/debug";
import { OvaleOptionsClass } from "./Options";
import { OvaleClass, MSG_PREFIX } from "../Ovale";
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

const self_printTable: LuaObj<string> = {};
const self_userVersion: LuaObj<string> = {};
let self_timer: Timer | undefined;

export class OvaleVersionClass {
    warned = false;
    private module: AceModule & AceComm & AceTimer & AceSerializer;
    private tracer: Tracer;

    constructor(
        ovale: OvaleClass,
        ovaleOptions: OvaleOptionsClass,
        ovaleDebug: OvaleDebugClass
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
                name: L["ping_users"],
                type: "execute",
                func: () => {
                    this.VersionCheck();
                },
            },
            version: {
                name: L["show_version_number"],
                type: "execute",
                func: () => {
                    this.tracer.Print(version);
                },
            },
        };
        for (const [k, v] of pairs(actions)) {
            ovaleOptions.actions.args[k] = v;
        }
        ovaleOptions.RegisterOptions();
    }

    private handleInitialize = () => {
        this.module.RegisterComm(MSG_PREFIX, this.OnCommReceived);
    };

    private handleDisable = () => {};

    private OnCommReceived = (
        prefix: string,
        message: string,
        channel: string,
        sender: string
    ) => {
        if (prefix == MSG_PREFIX) {
            const [ok, msgType, senderVersion] = this.module.Deserialize(
                message
            );
            if (ok) {
                this.tracer.Debug(msgType, senderVersion, channel, sender);
                if (msgType == "V") {
                    const msg = this.module.Serialize("VR", version);
                    this.module.SendCommMessage(MSG_PREFIX, msg, channel);
                } else if (msgType == "VR") {
                    self_userVersion[sender] = senderVersion;
                }
            }
        }
    };
    VersionCheck() {
        if (!self_timer) {
            wipe(self_userVersion);
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
                this.module.SendCommMessage(MSG_PREFIX, message, channel);
            }
            self_timer = this.module.ScheduleTimer(this.PrintVersionCheck, 3, this);
        }
    }
    PrintVersionCheck() {
        if (next(self_userVersion)) {
            wipe(self_printTable);
            for (const [sender, userVersion] of pairs(self_userVersion)) {
                insert(
                    self_printTable,
                    format(">>> %s is using Ovale %s", sender, userVersion)
                );
            }
            sort(self_printTable);
            for (const [, v] of ipairs(self_printTable)) {
                this.tracer.Print(v);
            }
        } else {
            this.tracer.Print(">>> No other Ovale users present.");
        }
        self_timer = undefined;
    }
}
