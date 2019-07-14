import test from "ava";
import { OvaleScripts } from "../Scripts";
import { registerScripts } from "../scripts/index";
import "../scripts/ovale_deathknight";
import "../scripts/ovale_demonhunter";
import "../scripts/ovale_druid";
import "../scripts/ovale_mage";
import "../scripts/ovale_monk";
import "../scripts/ovale_paladin";
import "../scripts/ovale_priest";
import "../scripts/ovale_rogue";
import "../scripts/ovale_shaman";
import "../scripts/ovale_warlock";
import "../scripts/ovale_warrior";
import "../Options";
import { OvaleCompile } from "../Compile";
import { pairs } from "@wowts/lua";
import { Ovale, oneTimeMessages } from "../Ovale";
import { eventDispatcher } from "@wowts/wow-mock";
import { OvaleCondition } from "../Condition";
import "../conditions";
import { OvaleDebug } from "../Debug";
import { OvaleSpellBook } from "../SpellBook";
import { OvaleStance } from "../Stance";
import { OvaleEquipment } from "../Equipment";

registerScripts();

for (const [name, script] of pairs(OvaleScripts.script)) {
    if (!script.className || script.type !== "script") continue;

    test(`Test ${name} script`, t => {
        OvaleDebug.warning = undefined;
        OvaleDebug.bug = undefined;
        Ovale.playerGUID = "player";
        Ovale.playerClass = script.className;
        eventDispatcher.DispatchEvent("ADDON_LOADED", "Ovale");
        OvaleEquipment.UpdateEquippedItems();
        OvaleSpellBook.Update();
        OvaleStance.UpdateStances();
        t.truthy(OvaleCondition.HasAny());
        OvaleCompile.CompileScript(name);
        t.is(OvaleDebug.bug, undefined);
        t.truthy(OvaleCompile.ast);
        OvaleCompile.EvaluateScript(OvaleCompile.ast, true);
        t.is(OvaleDebug.bug, undefined);
        t.is(OvaleDebug.warning, undefined);
        t.truthy(OvaleCompile.GetIconNodes());
        for (const k in oneTimeMessages) {
            t.falsy(k);
        }
    });
}
