import { L } from "./Localization";
import { OvaleDebug } from "./Debug";
import { OvaleOptions } from "./Options";
import { Ovale } from "./Ovale";
import AceComm from "@wowts/ace_comm-3.0";
import AceSerializer from "@wowts/ace_serializer-3.0";
import AceTimer from "@wowts/ace_timer-3.0";
import { format } from "@wowts/string";
import { ipairs, next, pairs, wipe } from "@wowts/lua";
import { insert, sort } from "@wowts/table";
import { IsInGroup, IsInGuild, IsInRaid, LE_PARTY_CATEGORY_INSTANCE } from "@wowts/wow-mock";

let OvaleVersionBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleVersion", AceComm, AceSerializer, AceTimer));
export let OvaleVersion: OvaleVersionClass;
let self_printTable = {
}
let self_userVersion = {
}
let self_timer;
let MSG_PREFIX = Ovale.MSG_PREFIX;
let OVALE_VERSION = "@project-version@";
let REPOSITORY_KEYWORD = `@${"project-version"}@`;
{
    let actions = {
        ping: {
            name: L["Ping for Ovale users in group"],
            type: "execute",
            func: function () {
                OvaleVersion.VersionCheck();
            }
        },
        version: {
            name: L["Show version number"],
            type: "execute",
            func: function () {
                OvaleVersion.Print(OvaleVersion.version);
            }
        }
    }
    for (const [k, v] of pairs(actions)) {
        OvaleOptions.options.args.actions.args[k] = v;
    }
    OvaleOptions.RegisterOptions(OvaleVersion);
}
class OvaleVersionClass extends OvaleVersionBase {
    version = (OVALE_VERSION == REPOSITORY_KEYWORD) && "development version" || OVALE_VERSION;
    warned = false;
    
    constructor() {
        super();
        this.RegisterComm(MSG_PREFIX);
    }
    OnCommReceived(prefix, message, channel, sender) {
        if (prefix == MSG_PREFIX) {
            let [ok, msgType, version] = this.Deserialize(message);
            if (ok) {
                this.Debug(msgType, version, channel, sender);
                if (msgType == "V") {
                    let msg = this.Serialize("VR", this.version);
                    this.SendCommMessage(MSG_PREFIX, msg, channel);
                } else if (msgType == "VR") {
                    self_userVersion[sender] = version;
                }
            }
        }
    }
    VersionCheck() {
        if (!self_timer) {
            wipe(self_userVersion);
            let message = this.Serialize("V", this.version);
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
                this.SendCommMessage(MSG_PREFIX, message, channel);
            }
            self_timer = this.ScheduleTimer("PrintVersionCheck", 3);
        }
    }
    PrintVersionCheck() {
        if (next(self_userVersion)) {
            wipe(self_printTable);
            for (const [sender, version] of pairs(self_userVersion)) {
                insert(self_printTable, format(">>> %s is using Ovale %s", sender, version));
            }
            sort(self_printTable);
            for (const [, v] of ipairs(self_printTable)) {
                this.Print(v);
            }
        } else {
            this.Print(">>> No other Ovale users present.");
        }
        self_timer = undefined;
    }
}

OvaleVersion =new OvaleVersionClass();