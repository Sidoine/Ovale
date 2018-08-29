import { Ovale } from "./Ovale";
import { OvaleScore } from "./Score";
import AceLocale from "@wowts/ace_locale-3.0";
import Recount from "@wowts/recount";
import { setmetatable, LuaObj } from "@wowts/lua";
import { GameTooltip } from "@wowts/wow-mock";

let OvaleRecountBase = Ovale.NewModule("OvaleRecount");
export let OvaleRecount: OvaleRecountClass;
const DataModes = function(self: never, data: any, num: number) {
    if (!data) {
        return [0, 0];
    }
    let fight = data.Fights[Recount.db.profile.CurDataSet];
    let score;
    if (fight && fight.Ovale && fight.OvaleMax) {
        score = fight.Ovale * 1000 / fight.OvaleMax;
    } else {
        score = 0;
    }
    if (num == 1) {
        return score;
    }
    return [score, undefined];
}
const TooltipFuncs = function(self: never, name: string) {
    GameTooltip.ClearLines();
    GameTooltip.AddLine(name);
}
class OvaleRecountClass extends OvaleRecountBase {
    OnInitialize() {
        if (Recount) {
            let aceLocale = AceLocale && AceLocale.GetLocale("Recount", true);
            if (!aceLocale) {
                aceLocale = setmetatable<LuaObj<string>>({}, {
                    __index: function (t, k) {
                        t[k] = k;
                        return k;
                    }
                });
            }
            Recount.AddModeTooltip(Ovale.GetName(), DataModes, TooltipFuncs, undefined, undefined, undefined, undefined);

            OvaleScore.RegisterDamageMeter("OvaleRecount", this, "ReceiveScore");
        }
    }
    OnDisable() {
        OvaleScore.UnregisterDamageMeter("OvaleRecount");
    }
    ReceiveScore(name: string, guid: string, scored: number, scoreMax: number) {
        if (Recount) {
            let source = Recount.db2.combatants[name];
            if (source) {
                Recount.AddAmount(source, Ovale.GetName(), scored);
                Recount.AddAmount(source, `${Ovale.GetName()}Max`, scoreMax);
            }
        }
    }
}
