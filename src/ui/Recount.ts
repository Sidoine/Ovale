import AceLocale from "@wowts/ace_locale-3.0";
import Recount from "@wowts/recount";
import { setmetatable, LuaObj } from "@wowts/lua";
import { GameTooltip } from "@wowts/wow-mock";
import { OvaleClass } from "../Ovale";
import { OvaleScoreClass } from "./Score";

interface FightData {
    ovale?: number;
    ovaleMax?: number;
}

interface Data {
    // eslint-disable-next-line @typescript-eslint/naming-convention
    Fights: LuaObj<FightData>;
}

const dataModes = function (self: never, data: Data, num: number) {
    if (!data) {
        return [0, 0];
    }
    const fight = data.Fights[Recount.db.profile.CurDataSet];
    let score;
    if (fight && fight.ovale && fight.ovaleMax) {
        score = (fight.ovale * 1000) / fight.ovaleMax;
    } else {
        score = 0;
    }
    if (num == 1) {
        return score;
    }
    return [score, undefined];
};
const tooltipFuncs = function (self: never, name: string) {
    GameTooltip.ClearLines();
    GameTooltip.AddLine(name);
};
export class OvaleRecountClass {
    constructor(
        private ovale: OvaleClass,
        private ovaleScore: OvaleScoreClass
    ) {
        ovale.createModule(
            "OvaleRecount",
            this.handleInitialize,
            this.handleDisable
        );
    }

    private handleInitialize = () => {
        if (Recount) {
            let aceLocale = AceLocale && AceLocale.GetLocale("Recount", true);
            if (!aceLocale) {
                aceLocale = setmetatable<LuaObj<string>>(
                    {},
                    {
                        // eslint-disable-next-line @typescript-eslint/naming-convention
                        __index: function (t, k) {
                            t[k] = k;
                            return k;
                        },
                    }
                );
            }
            Recount.AddModeTooltip(
                this.ovale.GetName(),
                dataModes,
                tooltipFuncs,
                undefined,
                undefined,
                undefined,
                undefined
            );

            this.ovaleScore.registerDamageMeter(
                "OvaleRecount",
                this.receiveScore
            );
        }
    };
    private handleDisable = () => {
        this.ovaleScore.unregisterDamageMeter("OvaleRecount");
    };
    private receiveScore = (
        name: string,
        guid: string,
        scored: number,
        scoreMax: number
    ) => {
        if (Recount) {
            const source = Recount.db2.combatants[name];
            if (source) {
                Recount.AddAmount(source, "ovale", scored);
                Recount.AddAmount(source, "ovaleMax", scoreMax);
            }
        }
    };
}
