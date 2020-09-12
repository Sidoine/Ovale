import { OvaleScriptsClass } from "../Scripts";

export function registerCommon(OvaleScripts: OvaleScriptsClass) {
    let name = "ovale_common";
    let desc = "[9.0] Ovale: Common spell definitions";
    let code = `

# Essences
Define(concentrated_flame_essence 295373)
    SpellInfo(concentrated_flame_essence cd=30 tag=main)
    Define(concentrated_flame_burn_debuff 295368)
    SpellInfo(concentrated_flame_burn_debuff duration=6)
    SpellAddTargetDebuff(concentrated_flame_essence concentrated_flame_burn_debuff=1)

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
