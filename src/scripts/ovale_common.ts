import { OvaleScriptsClass } from "../Scripts";

export function registerCommon(OvaleScripts: OvaleScriptsClass) {
    let name = "ovale_common";
    let desc = "[9.0] Ovale: Common spell definitions";
    let code = `

# Essences
Define(concentrated_flame_burn_debuff 295368)
SpellInfo(concentrated_flame_burn_debuff duration=6)

# Covenants
Define(kyrian 1)
Define(venthyr 2)
Define(night_fae 3)
Define(necrolord 4)

`;
    OvaleScripts.RegisterScript(
        undefined,
        undefined,
        name,
        desc,
        code,
        "include"
    );
}
