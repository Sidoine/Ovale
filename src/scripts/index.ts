import { register as scommon } from "./ovale_common";
import { register as sdk } from "./ovale_deathknight_spells";
import { register as sdh } from "./ovale_demonhunter_spells";
import { register as sdr } from "./ovale_druid_spells";
import { register as sh } from "./ovale_hunter_spells";
import { register as sm } from "./ovale_mage_spells";
import { register as smk } from "./ovale_monk_spells";
import { register as sp } from "./ovale_paladin_spells";
import { register as spr } from "./ovale_priest_spells";
import { register as sr } from "./ovale_rogue_spells";
import { register as ss } from "./ovale_shaman_spells";
import { register as swl } from "./ovale_warlock_spells";
import { register as swr } from "./ovale_warrior_spells";
import { register as tm } from "./ovale_trinkets_mop";
import { register as tw } from "./ovale_trinkets_wod";

export function registerScripts(){
    scommon();
    sdk();
    sdh();
    sdr();
    sh();
    sm();
    smk();
    sp();
    spr();
    sr();
    ss();
    swl();
    swr();

    tm();
    tw();
}
