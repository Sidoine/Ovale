import { OvaleScriptsClass } from "../Scripts";

export function registerCommon(OvaleScripts: OvaleScriptsClass) {
    let name = "ovale_common";
    let desc = "[9.0] Ovale: Common spell definitions";
    let code = `

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
