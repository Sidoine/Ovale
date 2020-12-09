import { OvaleScriptsClass } from "../engine/scripts";

export function registerCommon(OvaleScripts: OvaleScriptsClass) {
    const name = "ovale_common";
    const desc = "[9.0] Ovale: Common spell definitions";
    const code = `

# Essences
Define(concentrated_flame_burn_debuff 295368)
SpellInfo(concentrated_flame_burn_debuff duration=6)

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
