import AceLocale from "@wowts/ace_locale-3.0";
import Recount from "@wowts/recount";
import { setmetatable, LuaObj } from "@wowts/lua";
import { GameTooltip } from "@wowts/wow-mock";
import { OvaleClass } from "./Ovale";
import { OvaleScoreClass } from "./Score";

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
export class OvaleRecountClass {
    constructor(private ovale: OvaleClass, private ovaleScore: OvaleScoreClass) {
        ovale.createModule("OvaleRecount", this.OnInitialize, this.OnDisable);
    }

    private OnInitialize = () => {
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
            Recount.AddModeTooltip(this.ovale.GetName(), DataModes, TooltipFuncs, undefined, undefined, undefined, undefined);

            this.ovaleScore.RegisterDamageMeter("OvaleRecount", this, this.ReceiveScore);
        }
    }
    private OnDisable = () => {
        this.ovaleScore.UnregisterDamageMeter("OvaleRecount");
    }
    private ReceiveScore = (name: string, guid: string, scored: number, scoreMax: number) => {
        if (Recount) {
            let source = Recount.db2.combatants[name];
            if (source) {
                Recount.AddAmount(source, this.ovale.GetName(), scored);
                Recount.AddAmount(source, `${this.ovale.GetName()}Max`, scoreMax);
            }
        }
    }
}
