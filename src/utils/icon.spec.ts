import { test } from "@jest/globals";
import { assertDefined, assertIs } from "../tests/helpers";
import { executeDump } from "./icon";

const dump = `{ "atTime": 317520.842, "serial": 175, "index": 1, "script": "sc_t25_priest_shadow", "nodes": {
    "291": {"result": {"type": "none","serial": 175,"timeSpan": [317593.896,inf]}, "type": "group", "asString": null }
    ,"291": {"result": {"type": "none","serial": 175,"timeSpan": [317593.896,inf]}, "type": "group", "asString": null }
    ,"85": {"result": {"type": "value","timeSpan": [0,inf],"value": 14914,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": null }
    ,"86": {"result": {"type": "value","timeSpan": [0,inf],"value": "holy","rate": 0,"serial": 175,"origin": 0}, "type": "string", "asString": "holy" }
    ,"87": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "function", "asString": "specialization(holy)" }
    ,"157": {"result": {"type": "value","timeSpan": [0,inf],"value": 23127,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "searing_nightmare_talent" }
    ,"158": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "function", "asString": "hastalent(searing_nightmare_talent)" }
    ,"291": {"result": {"type": "none","serial": 175,"timeSpan": [317593.896,inf]}, "type": "group", "asString": null }
    ,"298": {"result": {"type": "value","timeSpan": [0,inf],"value": 50,"rate": 0,"serial": 175,"origin": 0}, "type": "function", "asString": "level()" }
    ,"294": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "function", "asString": "checkboxon(\\"self_power_infusion\\")" }
    ,"297": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "logical", "asString": null }
    ,"298": {"result": {"type": "value","timeSpan": [0,inf],"value": 50,"rate": 0,"serial": 175,"origin": 0}, "type": "function", "asString": "level()" }
    ,"300": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "compare", "asString": null }
    ,"301": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"306": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"318": {"result": {"type": "value","timeSpan": [0,inf],"value": 228260,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "void_eruption" }
    ,"309": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "compare", "asString": null }
    ,"317": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "logical", "asString": null }
    ,"318": {"result": {"type": "value","timeSpan": [0,inf],"value": 228260,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "void_eruption" }
    ,"319": {"result": {"type": "value","timeSpan": [0,inf],"value": 0,"rate": -1,"serial": 175,"origin": 317593.896}, "type": "function", "asString": "spellcooldown(void_eruption)" }
    ,"320": {"result": {"type": "none","serial": 175,"timeSpan": [0,317593.896]}, "type": "compare", "asString": null }
    ,"321": {"result": {"type": "none","serial": 175,"timeSpan": [317593.896,inf]}, "type": "logical", "asString": null }
    ,"322": {"result": {"type": "none","serial": 175,"timeSpan": [317593.896,inf]}, "type": "logical", "asString": null }
    ,"323": {"result": {"type": "none","serial": 175,"timeSpan": [317593.896,inf]}, "type": "logical", "asString": null }
    ,"325": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "group", "asString": null }
    ,"326": {"result": {"type": "value","timeSpan": [0,inf],"value": 1,"rate": 0,"serial": 175,"origin": 0}, "type": "function", "asString": "enemies()" }
    ,"327": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "compare", "asString": null }
    ,"330": {"result": {"type": "value","timeSpan": [0,inf],"value": 589,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "shadow_word_pain" }
    ,"336": {"result": {"type": "none","serial": 175,"timeSpan": [317506.906,317511.768]}, "type": "typed_function", "asString": "target.debuffpresent(shadow_word_pain)" }
    ,"337": {"result": {"type": "value","timeSpan": [0,inf],"value": 34914,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "vampiric_touch" }
    ,"343": {"result": {"type": "none","serial": 175,"timeSpan": [317516.591,317516.741]}, "type": "typed_function", "asString": "target.debuffpresent(vampiric_touch)" }
    ,"354": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "group", "asString": null }
    ,"369": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"475": {"result": {"type": "value","timeSpan": [0,inf],"value": 34914,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "vampiric_touch" }
    ,"476": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": [0,inf],"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.317,"actionCharges": 0,"actionId": 34914,"actionEnable": 1,"actionShortcut": "A","actionTexture": 135978,"actionInRange": true,"actionType": "spell","serial": 175,"actionUsable": true}, "type": "action", "asString": "spell(vampiric_touch)" }
    ,"551": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": {},"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "none","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionShortcut": "3","actionTexture": 1035040,"actionEnable": 1,"actionInRange": true,"actionType": "spell","serial": 175,"actionUsable": true}, "type": "group", "asString": null }
    ,"552": {"result": {"type": "value","timeSpan": [0,inf],"value": 327661,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "fae_guardians" }
    ,"558": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "typed_function", "asString": "buffpresent(fae_guardians)" }
    ,"567": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"568": {"result": {"type": "value","timeSpan": [0,inf],"value": 589,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "shadow_word_pain" }
    ,"569": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": [0,inf],"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 589,"actionEnable": 1,"actionShortcut": "B4","actionTexture": 136207,"actionInRange": true,"actionType": "spell","serial": 175,"actionUsable": true}, "type": "action", "asString": "spell(shadow_word_pain)" }
    ,"570": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "if", "asString": null }
    ,"571": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "custom_function", "asString": "shadowcdsmainactions()" }
    ,"572": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "custom_function", "asString": "shadowcdsmainpostconditions()" }
    ,"573": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": {},"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionShortcut": "3","actionTexture": 1035040,"actionCooldownDuration": 0,"actionInRange": true,"actionType": "spell","serial": 175,"actionUsable": true}, "type": "group", "asString": null }
    ,"580": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"589": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"596": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"599": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "if", "asString": null }
    ,"600": {"result": {"type": "value","timeSpan": [317520.842,inf],"value": 100,"rate": 0.0010000000474975,"serial": 175,"origin": 317520.842}, "type": "function", "asString": "insanity()" }
    ,"602": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "compare", "asString": null }
    ,"612": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"612": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"615": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 1035040,"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionUsable": true,"timeSpan": {},"actionShortcut": "3","actionInRange": true,"actionType": "spell","serial": 175,"actionEnable": 1}, "type": "if", "asString": null }
    ,"624": {"result": {"type": "none","serial": 175,"timeSpan": [317593.896,inf]}, "type": "custom_function", "asString": "pi_or_vf_sync_condition()" }
    ,"617": {"result": {"type": "value","timeSpan": [0,inf],"value": 335467,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "devouring_plague" }
    ,"619": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "function", "asString": "target.refreshable(devouring_plague)" }
    ,"623": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "logical", "asString": null }
    ,"624": {"result": {"type": "none","serial": 175,"timeSpan": [317593.896,inf]}, "type": "custom_function", "asString": "pi_or_vf_sync_condition()" }
    ,"625": {"result": {"type": "none","serial": 175,"timeSpan": [0,317593.896]}, "type": "logical", "asString": null }
    ,"626": {"result": {"type": "none","serial": 175,"timeSpan": [0,317593.896]}, "type": "logical", "asString": null }
    ,"637": {"result": {"type": "none","serial": 175,"timeSpan": [0,317593.896]}, "type": "logical", "asString": null }
    ,"630": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "logical", "asString": null }
    ,"633": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "custom_function", "asString": "searing_nightmare_cutoff()" }
    ,"636": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "logical", "asString": null }
    ,"637": {"result": {"type": "none","serial": 175,"timeSpan": [0,317593.896]}, "type": "logical", "asString": null }
    ,"638": {"result": {"type": "value","timeSpan": [0,inf],"value": 335467,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "devouring_plague" }
    ,"639": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": [0,inf],"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 335467,"actionUsable": false,"actionTexture": 252997,"actionEnable": 1,"actionInRange": true,"actionType": "spell","serial": 175,"actionShortcut": "Y"}, "type": "action", "asString": "spell(devouring_plague)" }
    ,"640": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 252997,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 335467,"actionUsable": false,"actionShortcut": "Y","timeSpan": [0,317593.896],"actionInRange": true,"actionType": "spell","serial": 175,"actionCooldownDuration": 0}, "type": "if", "asString": null }
    ,"642": {"result": {"type": "value","timeSpan": [0,inf],"value": 115,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "dissonant_echoes_conduit" }
    ,"643": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "function", "asString": "conduit(dissonant_echoes_conduit)" }
    ,"644": {"result": {"type": "value","timeSpan": [0,inf],"value": 4,"rate": 0,"serial": 175,"origin": 317520.842}, "type": "arithmetic", "asString": null }
    ,"645": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "compare", "asString": null }
    ,"647": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "compare", "asString": null }
    ,"648": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"651": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 1035040,"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionUsable": true,"timeSpan": {},"actionShortcut": "3","actionInRange": true,"actionType": "spell","serial": 175,"actionEnable": 1}, "type": "if", "asString": null }
    ,"654": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "compare", "asString": null }
    ,"655": {"result": {"type": "value","timeSpan": [0,inf],"value": 341207,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "dark_thought" }
    ,"661": {"result": {"type": "none","serial": 175,"timeSpan": [317511.389,317512.11]}, "type": "typed_function", "asString": "buffpresent(dark_thought)" }
    ,"662": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"665": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "if", "asString": null }
    ,"673": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "custom_function", "asString": "dots_up()" }
    ,"674": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"675": {"result": {"type": "value","timeSpan": [0,inf],"value": 15407,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "mind_flay" }
    ,"676": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": [0,inf],"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 15407,"actionEnable": 1,"actionShortcut": "R","actionTexture": 136208,"actionInRange": true,"actionType": "spell","serial": 175,"actionUsable": true}, "type": "action", "asString": "spell(mind_flay)" }
    ,"677": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 136208,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 15407,"actionShortcut": "R","actionUsable": true,"timeSpan": {},"actionInRange": true,"actionType": "spell","serial": 175,"actionCooldownDuration": 0}, "type": "if", "asString": null }
    ,"680": {"result": {"type": "value","timeSpan": [0,inf],"value": 8092,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "mind_blast" }
    ,"681": {"result": {"type": "value","timeSpan": [0,inf],"value": 1.317,"rate": 0,"serial": 175,"origin": 0}, "type": "function", "asString": "casttime(mind_blast)" }
    ,"683": {"result": {"type": "value","timeSpan": [0,inf],"value": 1.817,"rate": 0,"serial": 175,"origin": 317520.842}, "type": "arithmetic", "asString": null }
    ,"684": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "compare", "asString": null }
    ,"685": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"688": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"689": {"result": {"type": "value","timeSpan": [0,inf],"value": 8092,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "mind_blast" }
    ,"690": {"result": {"actionCooldownStart": 317518.425,"actionIsCurrent": false,"timeSpan": [317525.008,inf],"actionCooldownDuration": 6.583,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.317,"actionCharges": 0,"actionId": 8092,"actionEnable": 1,"actionShortcut": "E","actionTexture": 136224,"actionInRange": true,"actionType": "spell","serial": 175,"actionUsable": true}, "type": "action", "asString": "spell(mind_blast)" }
    ,"691": {"result": {"actionCooldownStart": 317505.191,"actionIsCurrent": false,"actionTexture": 136224,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.32,"actionCharges": 0,"actionId": 8092,"actionShortcut": "E","actionUsable": true,"timeSpan": {},"actionInRange": true,"actionType": "spell","serial": 175,"actionCooldownDuration": 6.601}, "type": "if", "asString": null }
    ,"692": {"result": {"type": "value","timeSpan": [0,inf],"value": 34914,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "vampiric_touch" }
    ,"694": {"result": {"type": "none","serial": 175,"timeSpan": [317510.441,inf]}, "type": "function", "asString": "target.refreshable(vampiric_touch)" }
    ,"696": {"result": {"type": "value","timeSpan": [317520.842,inf],"value": 1011.4330997943,"rate": -1,"serial": 175,"origin": 317520.842}, "type": "function", "asString": "target.timetodie()" }
    ,"697": {"result": {"type": "none","serial": 175,"timeSpan": [317520.842,318526.27509979]}, "type": "compare", "asString": null }
    ,"698": {"result": {"type": "none","serial": 175,"timeSpan": [317520.842,318526.27509979]}, "type": "logical", "asString": null }
    ,"699": {"result": {"type": "value","timeSpan": [0,inf],"value": 23126,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "misery_talent" }
    ,"700": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "function", "asString": "hastalent(misery_talent)" }
    ,"701": {"result": {"type": "value","timeSpan": [0,inf],"value": 589,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "shadow_word_pain" }
    ,"704": {"result": {"type": "none","serial": 175,"timeSpan": [317508.168,inf]}, "type": "function", "asString": "target.debuffrefreshable(shadow_word_pain)" }
    ,"705": {"result": {"type": "none","serial": 175,"timeSpan": [317508.168,inf]}, "type": "logical", "asString": null }
    ,"706": {"result": {"type": "none","serial": 175,"timeSpan": [317508.168,inf]}, "type": "logical", "asString": null }
    ,"707": {"result": {"type": "value","timeSpan": [0,inf],"value": 341291,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "unfurling_darkness" }
    ,"713": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "typed_function", "asString": "buffpresent(unfurling_darkness)" }
    ,"714": {"result": {"type": "none","serial": 175,"timeSpan": [317508.168,inf]}, "type": "logical", "asString": null }
    ,"717": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 135978,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.317,"actionCharges": 0,"actionId": 34914,"actionShortcut": "A","timeSpan": [317508.168,inf],"actionUsable": true,"actionInRange": true,"actionType": "spell","serial": 175,"actionCooldownDuration": 0}, "type": "if", "asString": null }
    ,"718": {"result": {"type": "value","timeSpan": [0,inf],"value": 589,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "shadow_word_pain" }
    ,"720": {"result": {"type": "none","serial": 175,"timeSpan": [317508.168,inf]}, "type": "function", "asString": "target.refreshable(shadow_word_pain)" }
    ,"723": {"result": {"type": "none","serial": 175,"timeSpan": [317520.842,318528.27509979]}, "type": "compare", "asString": null }
    ,"724": {"result": {"type": "none","serial": 175,"timeSpan": [317520.842,318528.27509979]}, "type": "logical", "asString": null }
    ,"727": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"728": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"731": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"734": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"737": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "if", "asString": null }
    ,"743": {"result": {"type": "none","serial": 175,"timeSpan": [317520.842,318528.27509979]}, "type": "compare", "asString": null }
    ,"744": {"result": {"type": "none","serial": 175,"timeSpan": [317520.842,318528.27509979]}, "type": "logical", "asString": null }
    ,"747": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"748": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"758": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"769": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"769": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"772": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "if", "asString": null }
    ,"775": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "compare", "asString": null }
    ,"778": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "if", "asString": null }
    ,"783": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 1035040,"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionShortcut": "3","timeSpan": {},"actionUsable": true,"actionInRange": true,"actionType": "spell","serial": 175,"actionEnable": 1}, "type": "unless", "asString": null }
    ,"983": {"result": {"type": "value","timeSpan": [0,inf],"value": 1.3167711780564,"rate": 0,"serial": 175,"origin": 0}, "type": "function", "asString": "gcd()" }
    ,"1832": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "group", "asString": null }
    ,"1833": {"result": {"type": "value","timeSpan": [0,inf],"value": 299300,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "memory_of_lucid_dreams" }
    ,"1834": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "action", "asString": "spell(memory_of_lucid_dreams)" }
    ,"1835": {"result": {"type": "value","timeSpan": [0,inf],"value": 297969,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "blood_of_the_enemy" }
    ,"1836": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "action", "asString": "spell(blood_of_the_enemy)" }
    ,"1837": {"result": {"type": "value","timeSpan": [0,inf],"value": 295368,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "concentrated_flame" }
    ,"1838": {"result": {"type": "value","timeSpan": [0,inf],"value": 0,"rate": 1,"serial": 175,"origin": 0}, "type": "function", "asString": "timesincepreviousspell(concentrated_flame)" }
    ,"1839": {"result": {"type": "none","serial": 175,"timeSpan": [6,inf]}, "type": "compare", "asString": null }
    ,"1852": {"result": {"type": "none","serial": 175,"timeSpan": [6,inf]}, "type": "logical", "asString": null }
    ,"1841": {"result": {"type": "value","timeSpan": [317506.76,inf],"value": 0,"rate": 1,"serial": 175,"origin": 317506.76}, "type": "function", "asString": "timeincombat()" }
    ,"1842": {"result": {"type": "none","serial": 175,"timeSpan": [317506.76,317516.76]}, "type": "compare", "asString": null }
    ,"1843": {"result": {"type": "value","timeSpan": [0,inf],"value": 295368,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "concentrated_flame" }
    ,"1844": {"result": {"type": "value","timeSpan": [0,inf],"value": 0,"rate": 0,"serial": 175,"origin": 0}, "type": "function", "asString": "spellfullrecharge(concentrated_flame)" }
    ,"1846": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "compare", "asString": null }
    ,"1847": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "logical", "asString": null }
    ,"1851": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "logical", "asString": null }
    ,"1852": {"result": {"type": "none","serial": 175,"timeSpan": [6,inf]}, "type": "logical", "asString": null }
    ,"1853": {"result": {"type": "value","timeSpan": [0,inf],"value": 295368,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "concentrated_flame" }
    ,"1854": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "action", "asString": "spell(concentrated_flame)" }
    ,"1855": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "if", "asString": null }
    ,"1856": {"result": {"type": "value","timeSpan": [0,inf],"value": 299306,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "ripple_in_space" }
    ,"1857": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "action", "asString": "spell(ripple_in_space)" }
    ,"1858": {"result": {"type": "value","timeSpan": [0,inf],"value": 298606,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "worldvein_resonance" }
    ,"1859": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "action", "asString": "spell(worldvein_resonance)" }
    ,"1860": {"result": {"type": "value","timeSpan": [0,inf],"value": 299321,"rate": 0,"serial": 175,"origin": 0}, "type": "value", "asString": "the_unbound_force" }
    ,"1861": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "action", "asString": "spell(the_unbound_force)" }
    ,"1863": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "group", "asString": null }
    ,"2018": {"result": {"actionCooldownStart": 317518.425,"actionIsCurrent": false,"actionTexture": 136224,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.317,"actionCharges": 0,"actionId": 8092,"actionShortcut": "E","timeSpan": [317525.008,inf],"actionUsable": true,"actionInRange": true,"actionType": "spell","serial": 175,"actionCooldownDuration": 6.583}, "type": "group", "asString": null }
    ,"2022": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"2028": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "compare", "asString": null }
    ,"2029": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"2030": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"2033": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "if", "asString": null }
    ,"2040": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"2043": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"2046": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "if", "asString": null }
    ,"2050": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "group", "asString": null }
    ,"2126": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "group", "asString": null }
    ,"2127": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "custom_function", "asString": "shadowessencesmainactions()" }
    ,"2129": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "group", "asString": null }
    ,"2130": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "custom_function", "asString": "shadowessencesmainpostconditions()" }
    ,"2161": {"result": {"actionCooldownStart": 317518.425,"actionIsCurrent": false,"actionTexture": 136224,"actionCooldownDuration": 6.583,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.317,"actionCharges": 0,"actionId": 8092,"actionShortcut": "E","timeSpan": [317525.008,inf],"actionUsable": true,"actionInRange": true,"actionType": "spell","serial": 175,"actionEnable": 1}, "type": "group", "asString": null }
    ,"2162": {"result": {"actionCooldownStart": 317518.425,"actionIsCurrent": false,"timeSpan": [317525.008,inf],"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.317,"actionCharges": 0,"actionId": 8092,"actionShortcut": "E","actionTexture": 136224,"actionCooldownDuration": 6.583,"actionInRange": true,"actionType": "spell","serial": 175,"actionUsable": true}, "type": "custom_function", "asString": "shadowcwcmainactions()" }
    ,"2163": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "custom_function", "asString": "shadowcwcmainpostconditions()" }
    ,"2166": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": {},"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "none","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionShortcut": "3","actionTexture": 1035040,"actionCooldownDuration": 0,"actionInRange": true,"actionType": "spell","serial": 175,"actionUsable": true}, "type": "unless", "asString": null }
    ,"2165": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 1035040,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "none","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionShortcut": "3","timeSpan": {},"actionUsable": true,"actionInRange": true,"actionType": "spell","serial": 175,"actionCooldownDuration": 0}, "type": "custom_function", "asString": "shadowmainmainactions()" }
    ,"2166": {"result": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": {},"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "none","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionShortcut": "3","actionTexture": 1035040,"actionCooldownDuration": 0,"actionInRange": true,"actionType": "spell","serial": 175,"actionUsable": true}, "type": "unless", "asString": null }
    ,"2232": {"result": {"type": "value","timeSpan": [0,inf],"value": "shadow","rate": 0,"serial": 175,"origin": 0}, "type": "string", "asString": "shadow" }
    ,"2233": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "function", "asString": "specialization(shadow)" }
    ,"2234": {"result": {"type": "value","timeSpan": [0,inf],"value": "main","rate": 0,"serial": 175,"origin": 0}, "type": "string", "asString": null }
    ,"2235": {"result": {"actionCooldownStart": 317518.425,"actionIsCurrent": false,"timeSpan": [317525.008,inf],"actionCooldownDuration": 6.583,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.317,"actionCharges": 0,"actionId": 8092,"actionShortcut": "E","actionTexture": 136224,"actionEnable": 1,"actionInRange": true,"actionType": "spell","serial": 175,"actionUsable": true}, "type": "group", "asString": null }
    ,"2236": {"result": {"type": "none","serial": 175,"timeSpan": [0,inf]}, "type": "function", "asString": "incombat()" }
    ,"2237": {"result": {"type": "none","serial": 175,"timeSpan": {}}, "type": "logical", "asString": null }
    ,"2239": {"result": {"actionCooldownStart": 317492.486,"actionIsCurrent": true,"actionTexture": 135978,"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.324,"actionCharges": 0,"actionId": 34914,"actionShortcut": "A","timeSpan": {},"actionUsable": true,"actionInRange": true,"actionType": "spell","serial": 175,"actionEnable": 1}, "type": "if", "asString": null }
    ,"2240": {"result": {"actionCooldownStart": 317518.425,"actionIsCurrent": false,"timeSpan": [317525.008,inf],"actionCooldownDuration": 6.583,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.317,"actionCharges": 0,"actionId": 8092,"actionShortcut": "E","actionTexture": 136224,"actionEnable": 1,"actionInRange": true,"actionType": "spell","serial": 175,"actionUsable": true}, "type": "custom_function", "asString": "shadow_defaultmainactions()" }
    }, "result": {"actionCooldownStart": 317518.425,"actionIsCurrent": false,"timeSpan": [317525.008,inf],"actionCooldownDuration": 6.583,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.317,"actionCharges": 0,"actionId": 8092,"actionShortcut": "E","actionTexture": 136224,"actionEnable": 1,"actionInRange": true,"actionType": "spell","serial": 175,"actionUsable": true} }`;

const expectedLogs = `Reset state with current time = 317520.842000
nextCast = 317520.842000
[2233] >>> Computing 'specialization(shadow)' at time=317520.842000
[2232] >>> Computing 'shadow' at time=317520.842000
[2232]    value is shadow
[2232] <<< 'shadow' returns (0, inf) with value = value "shadow"
[2233]    condition 'specialization' returns 0, inf, nil, nil, nil
[2233] <<< 'specialization(shadow)' returns (0, inf) with value = none
[2234] >>> Computing 'string' at time=317520.842000
[2234]    value is main
[2234] <<< 'string' returns (0, inf) with value = value "main"
[2236] >>> Computing 'incombat()' at time=317520.842000
[2236]    condition 'incombat' returns 0, inf, nil, nil, nil
[2236] <<< 'incombat()' returns (0, inf) with value = none
[2237] >>> Computing 'logical' at time=317520.842000
[2236] >>> Returning for 'incombat()' cached value none at (0, inf)
[2237]    logical 'not' returns empty set
[2237] <<< 'logical' returns empty set with value = none
[2235]    'logical' will trigger short-circuit evaluation of parent node [2239] with zero-measure time span.
[2239] >>> Computing 'if' at time=317520.842000
[2237] >>> Returning for 'logical' cached value none at empty set
[2239]    'if' returns empty set with zero measure
[2239] <<< 'if' returns empty set with value = action spell 34914
[2240] >>> Computing 'shadow_defaultmainactions()' at time=317520.842000
[2240]: calling custom function [2161] shadow_defaultmainactions
[2162] >>> Computing 'shadowcwcmainactions()' at time=317520.842000
[2162]: calling custom function [2018] shadowcwcmainactions
[633] >>> Computing 'searing_nightmare_cutoff()' at time=317520.842000
[633]: calling custom function [325] searing_nightmare_cutoff
[326] >>> Computing 'enemies()' at time=317520.842000
[326]    condition 'enemies' returns 0, inf, 1, 0, 0
[326] <<< 'enemies()' returns (0, inf) with value = value 1 + (t - 0) * 0
[327] >>> Computing 'compare' at time=317520.842000
[326] >>> Returning for 'enemies()' cached value value 1 + (t - 0) * 0 at (0, inf)
[327]    1+(t-0)*0 > 3+(t-0)*0
[327]    compare '>' returns empty set
[327] <<< 'compare' returns empty set with value = none
[325] >>> Computing 'group' at time=317520.842000
[325]    group checking child [327-[compare]]
[327] >>> Returning for 'compare' cached value none at empty set
[325]    group checking child [327-[compare]] result: empty set
[325]   child [327] measure is 0, skipping
[325]    group no best action returns none at empty set
[325] <<< 'group' returns empty set with value = none
[633]: [325] searing_nightmare_cutoff is returning none
[633] <<< 'searing_nightmare_cutoff()' returns empty set with value = none
[2018]    'custom_function' will trigger short-circuit evaluation of parent node [2022] with zero measure.
[2022] >>> Computing 'logical' at time=317520.842000
[633] >>> Returning for 'searing_nightmare_cutoff()' cached value none at empty set
[2022]    logical 'and' short-circuits with zero measure left argument
[2022]    logical 'and' returns empty set
[2022] <<< 'logical' returns empty set with value = none
[704] >>> Computing 'target.debuffrefreshable(shadow_word_pain)' at time=317520.842000
[701] >>> Computing 'shadow_word_pain' at time=317520.842000
[701]    value is 589
[701] <<< 'shadow_word_pain' returns (0, inf) with value = value 589 + (t - 0) * 0
Found aura with stack = 1
Aura 589 found on Creature-0-3770-0-5276-153292-0000548E1B with (317492.77, 317511.768) [stacks=1]
[704]    condition 'debuffrefreshable' returns 317508.168, inf, nil, nil, nil
[704] <<< 'target.debuffrefreshable(shadow_word_pain)' returns (317508.168, inf) with value = none
[326] >>> Returning for 'enemies()' cached value value 1 + (t - 0) * 0 at (0, inf)
[2028] >>> Computing 'compare' at time=317520.842000
[326] >>> Returning for 'enemies()' cached value value 1 + (t - 0) * 0 at (0, inf)
[2028]    1+(t-0)*0 > 1+(t-0)*0
[2028]    compare '>' returns empty set
[2028] <<< 'compare' returns empty set with value = none
[2029] >>> Computing 'logical' at time=317520.842000
[704] >>> Returning for 'target.debuffrefreshable(shadow_word_pain)' cached value none at (317508.168, inf)
[2028] >>> Returning for 'compare' cached value none at empty set
[2029]    logical 'and' returns empty set
[2029] <<< 'logical' returns empty set with value = none
[2030] >>> Computing 'logical' at time=317520.842000
[2022] >>> Returning for 'logical' cached value none at empty set
[2029] >>> Returning for 'logical' cached value none at empty set
[2030]    logical 'or' returns empty set
[2030] <<< 'logical' returns empty set with value = none
[2018]    'logical' will trigger short-circuit evaluation of parent node [2033] with zero-measure time span.
[2033] >>> Computing 'if' at time=317520.842000
[2030] >>> Returning for 'logical' cached value none at empty set
[2033]    'if' returns empty set with zero measure
[2033] <<< 'if' returns empty set with value = none
[158] >>> Computing 'hastalent(searing_nightmare_talent)' at time=317520.842000
[157] >>> Computing 'searing_nightmare_talent' at time=317520.842000
[157]    value is 23127
[157] <<< 'searing_nightmare_talent' returns (0, inf) with value = value 23127 + (t - 0) * 0
[158]    condition 'hastalent' returns nil, nil, nil, nil, nil
[158] <<< 'hastalent(searing_nightmare_talent)' returns empty set with value = none
[2018]    'function' will trigger short-circuit evaluation of parent node [2040] with zero measure.
[2040] >>> Computing 'logical' at time=317520.842000
[158] >>> Returning for 'hastalent(searing_nightmare_talent)' cached value none at empty set
[2040]    logical 'and' short-circuits with zero measure left argument
[2040]    logical 'and' returns empty set
[2040] <<< 'logical' returns empty set with value = none
[2018]    'logical' will trigger short-circuit evaluation of parent node [2043] with zero measure.
[2043] >>> Computing 'logical' at time=317520.842000
[2040] >>> Returning for 'logical' cached value none at empty set
[2043]    logical 'and' short-circuits with zero measure left argument
[2043]    logical 'and' returns empty set
[2043] <<< 'logical' returns empty set with value = none
[2018]    'logical' will trigger short-circuit evaluation of parent node [2046] with zero-measure time span.
[2046] >>> Computing 'if' at time=317520.842000
[2043] >>> Returning for 'logical' cached value none at empty set
[2046]    'if' returns empty set with zero measure
[2046] <<< 'if' returns empty set with value = none
[690] >>> Computing 'spell(mind_blast)' at time=317520.842000
[690]    evaluating action: spell()
[689] >>> Computing 'mind_blast' at time=317520.842000
[689]    value is 8092
[689] <<< 'mind_blast' returns (0, inf) with value = value 8092 + (t - 0) * 0
[87] >>> Computing 'specialization(holy)' at time=317520.842000
[86] >>> Computing 'holy' at time=317520.842000
[86]    value is holy
[86] <<< 'holy' returns (0, inf) with value = value "holy"
[87]    condition 'specialization' returns nil, nil, nil, nil, nil
[87] <<< 'specialization(holy)' returns empty set with value = none
[85] >>> Computing 'value' at time=317520.842000
[85]    value is 14914
[85] <<< 'value' returns (0, inf) with value = value 14914 + (t - 0) * 0
Found spell info about 8092 (isKnown = true)
Spell has cost of %d for %s
Spell has cost of 0 for insanity
Spell has cost of 0 for insanity
Spell has cost of %d for %s
Spell ID '8092' passed power requirements.
OvaleSpells:IsUsableSpell(8092, 317520.842000, Creature-0-3770-0-5276-153292-0000548E1B) returned true, false
Didn't find an existing cd in next, look for one in current
Call GetSpellCooldown which returned 317518.625000, 6.583000, 1
GlobalCooldown is 0, 0
It returned 317518.525000, 6.583000
Cooldown of spell 8092 is 317518.425000 + 6.583000
GetSpellCooldown returned 317518.425000, 6.583000
Cooldown of spell 8092 is 317518.425000 + 6.583000
[690]    Action spell (actionCharges=0)
[690]    Action spell is on cooldown (start=317518.425000, duration=6.583000).
[690]    start=317525.008000 atTime=317520.842000
[690]    Action spell can start at 317525.008000.
[690] <<< 'spell(mind_blast)' returns (317525.008, inf) with value = action spell 8092
[2018] >>> Computing 'group' at time=317520.842000
[2018]    group checking child [2033-[if]]
[2033] >>> Returning for 'if' cached value none at empty set
[2018]    group checking child [2033-[if]] result: empty set
[2018]   child [2033] measure is 0, skipping
[2018]    group checking child [2046-[if]]
[2046] >>> Returning for 'if' cached value none at empty set
[2018]    group checking child [2046-[if]] result: empty set
[2018]   child [2046] measure is 0, skipping
[2018]    group checking child [690-spell(mind_blast)]
[690] >>> Returning for 'spell(mind_blast)' cached value action spell 8092 at (317525.008, inf)
[2018]    group checking child [690-spell(mind_blast)] result: (317525.008, inf)
[2018]    group first best is [690-spell(mind_blast)]: (317525.008, inf)
[2018]    group best action remains action spell 8092 at (317525.008, inf)
[2018] <<< 'group' returns (317525.008, inf) with value = action spell 8092
[2162]: [2018] shadowcwcmainactions is returning action spell 8092
[2162] <<< 'shadowcwcmainactions()' returns (317525.008, inf) with value = action spell 8092
[2163] >>> Computing 'shadowcwcmainpostconditions()' at time=317520.842000
[2163]: calling custom function [2050] shadowcwcmainpostconditions
[2050] >>> Computing 'group' at time=317520.842000
[2050]    group no best action returns none at empty set
[2050] <<< 'group' returns empty set with value = none
[2163]: [2050] shadowcwcmainpostconditions is returning none
[2163] <<< 'shadowcwcmainpostconditions()' returns empty set with value = none
[2165] >>> Computing 'shadowmainmainactions()' at time=317520.842000
[2165]: calling custom function [551] shadowmainmainactions
[558] >>> Computing 'buffpresent(fae_guardians)' at time=317520.842000
computing positional parameters
[552] >>> Computing 'fae_guardians' at time=317520.842000
[552]    value is 327661
[552] <<< 'fae_guardians' returns (0, inf) with value = value 327661 + (t - 0) * 0
Aura 327661 is missing on Player-1315-05C8DCE1 (mine=true).
[558]    condition 'buffpresent' returns nil, nil, nil, nil, nil
[558] <<< 'buffpresent(fae_guardians)' returns empty set with value = none
[551]    'typed_function' will trigger short-circuit evaluation of parent node [567] with zero measure.
[567] >>> Computing 'logical' at time=317520.842000
[558] >>> Returning for 'buffpresent(fae_guardians)' cached value none at empty set
[567]    logical 'and' short-circuits with zero measure left argument
[567]    logical 'and' returns empty set
[567] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [570] with zero-measure time span.
[570] >>> Computing 'if' at time=317520.842000
[567] >>> Returning for 'logical' cached value none at empty set
[570]    'if' returns empty set with zero measure
[570] <<< 'if' returns empty set with value = none
[571] >>> Computing 'shadowcdsmainactions()' at time=317520.842000
[571]: calling custom function [2126] shadowcdsmainactions
[2127] >>> Computing 'shadowessencesmainactions()' at time=317520.842000
[2127]: calling custom function [1832] shadowessencesmainactions
[1834] >>> Computing 'spell(memory_of_lucid_dreams)' at time=317520.842000
[1834]    evaluating action: spell()
[1833] >>> Computing 'memory_of_lucid_dreams' at time=317520.842000
[1833]    value is 299300
[1833] <<< 'memory_of_lucid_dreams' returns (0, inf) with value = value 299300 + (t - 0) * 0
Unknown spell ID '299300'.
[1834] <<< 'spell(memory_of_lucid_dreams)' returns empty set with value = none
[1836] >>> Computing 'spell(blood_of_the_enemy)' at time=317520.842000
[1836]    evaluating action: spell()
[1835] >>> Computing 'blood_of_the_enemy' at time=317520.842000
[1835]    value is 297969
[1835] <<< 'blood_of_the_enemy' returns (0, inf) with value = value 297969 + (t - 0) * 0
Unknown spell ID '297969'.
[1836] <<< 'spell(blood_of_the_enemy)' returns empty set with value = none
[1838] >>> Computing 'timesincepreviousspell(concentrated_flame)' at time=317520.842000
[1837] >>> Computing 'concentrated_flame' at time=317520.842000
[1837]    value is 295368
[1837] <<< 'concentrated_flame' returns (0, inf) with value = value 295368 + (t - 0) * 0
[1838]    condition 'timesincepreviousspell' returns 0, inf, 0, 0, 1
[1838] <<< 'timesincepreviousspell(concentrated_flame)' returns (0, inf) with value = value 0 + (t - 0) * 1
[1839] >>> Computing 'compare' at time=317520.842000
[1838] >>> Returning for 'timesincepreviousspell(concentrated_flame)' cached value value 0 + (t - 0) * 1 at (0, inf)
[1839]    0+(t-0)*1 > 6+(t-0)*0
[1839]    intersection at t = 6
[1839]    compare '>' returns (6, inf)
[1839] <<< 'compare' returns (6, inf) with value = none
[1841] >>> Computing 'timeincombat()' at time=317520.842000
[1841]    condition 'timeincombat' returns 317506.76, inf, 0, 317506.76, 1
[1841] <<< 'timeincombat()' returns (317506.76, inf) with value = value 0 + (t - 317506.76) * 1
[1842] >>> Computing 'compare' at time=317520.842000
[1841] >>> Returning for 'timeincombat()' cached value value 0 + (t - 317506.76) * 1 at (317506.76, inf)
[1842]    0+(t-317506.76)*1 <= 10+(t-0)*0
[1842]    intersection at t = 317516.76
[1842]    compare '<=' returns (317506.76, 317516.76)
[1842] <<< 'compare' returns (317506.76, 317516.76) with value = none
[1844] >>> Computing 'spellfullrecharge(concentrated_flame)' at time=317520.842000
[1843] >>> Computing 'concentrated_flame' at time=317520.842000
[1843]    value is 295368
[1843] <<< 'concentrated_flame' returns (0, inf) with value = value 295368 + (t - 0) * 0
Didn't find an existing cd in next, look for one in current
Call GetSpellCooldown which returned 0.000000, 0.000000, 1
It returned -0.100000, 0.000000
Spell cooldown is in the past
Cooldown of spell 295368 is 0.000000 + 0.000000
[1844]    condition 'spellfullrecharge' returns 0, inf, 0, 0, 0
[1844] <<< 'spellfullrecharge(concentrated_flame)' returns (0, inf) with value = value 0 + (t - 0) * 0
[983] >>> Computing 'gcd()' at time=317520.842000
[983]    condition 'gcd' returns 0, inf, 1.3167711780564, 0, 0
[983] <<< 'gcd()' returns (0, inf) with value = value 1.3167711780564 + (t - 0) * 0
[1846] >>> Computing 'compare' at time=317520.842000
[1844] >>> Returning for 'spellfullrecharge(concentrated_flame)' cached value value 0 + (t - 0) * 0 at (0, inf)
[983] >>> Returning for 'gcd()' cached value value 1.3167711780564 + (t - 0) * 0 at (0, inf)
[1846]    0+(t-0)*0 < 1.3167711780564+(t-0)*0
[1846]    compare '<' returns (0, inf)
[1846] <<< 'compare' returns (0, inf) with value = none
[1847] >>> Computing 'logical' at time=317520.842000
[1842] >>> Returning for 'compare' cached value none at (317506.76, 317516.76)
[1846] >>> Returning for 'compare' cached value none at (0, inf)
[1847]    logical 'or' returns (0, inf)
[1847] <<< 'logical' returns (0, inf) with value = none
[1832]    'logical' will trigger short-circuit evaluation of parent node [1851] with universe as time span.
[1851] >>> Computing 'logical' at time=317520.842000
[1847] >>> Returning for 'logical' cached value none at (0, inf)
[1851]    logical 'or' short-circuits with universe as left argument
[1851]    logical 'or' returns (0, inf)
[1851] <<< 'logical' returns (0, inf) with value = none
[1852] >>> Computing 'logical' at time=317520.842000
[1839] >>> Returning for 'compare' cached value none at (6, inf)
[1851] >>> Returning for 'logical' cached value none at (0, inf)
[1852]    logical 'and' returns (6, inf)
[1852] <<< 'logical' returns (6, inf) with value = none
[1854] >>> Computing 'spell(concentrated_flame)' at time=317520.842000
[1854]    evaluating action: spell()
[1853] >>> Computing 'concentrated_flame' at time=317520.842000
[1853]    value is 295368
[1853] <<< 'concentrated_flame' returns (0, inf) with value = value 295368 + (t - 0) * 0
Unknown spell ID '295368'.
[1854] <<< 'spell(concentrated_flame)' returns empty set with value = none
[1855] >>> Computing 'if' at time=317520.842000
[1852] >>> Returning for 'logical' cached value none at (6, inf)
[1854] >>> Returning for 'spell(concentrated_flame)' cached value none at empty set
[1855]    'if' returns empty set (intersection of (6, inf) and empty set)
[1855] <<< 'if' returns empty set with value = none
[1857] >>> Computing 'spell(ripple_in_space)' at time=317520.842000
[1857]    evaluating action: spell()
[1856] >>> Computing 'ripple_in_space' at time=317520.842000
[1856]    value is 299306
[1856] <<< 'ripple_in_space' returns (0, inf) with value = value 299306 + (t - 0) * 0
Unknown spell ID '299306'.
[1857] <<< 'spell(ripple_in_space)' returns empty set with value = none
[1859] >>> Computing 'spell(worldvein_resonance)' at time=317520.842000
[1859]    evaluating action: spell()
[1858] >>> Computing 'worldvein_resonance' at time=317520.842000
[1858]    value is 298606
[1858] <<< 'worldvein_resonance' returns (0, inf) with value = value 298606 + (t - 0) * 0
Unknown spell ID '298606'.
[1859] <<< 'spell(worldvein_resonance)' returns empty set with value = none
[1861] >>> Computing 'spell(the_unbound_force)' at time=317520.842000
[1861]    evaluating action: spell()
[1860] >>> Computing 'the_unbound_force' at time=317520.842000
[1860]    value is 299321
[1860] <<< 'the_unbound_force' returns (0, inf) with value = value 299321 + (t - 0) * 0
Unknown spell ID '299321'.
[1861] <<< 'spell(the_unbound_force)' returns empty set with value = none
[1832] >>> Computing 'group' at time=317520.842000
[1832]    group checking child [1834-spell(memory_of_lucid_dreams)]
[1834] >>> Returning for 'spell(memory_of_lucid_dreams)' cached value none at empty set
[1832]    group checking child [1834-spell(memory_of_lucid_dreams)] result: empty set
[1832]   child [1834] measure is 0, skipping
[1832]    group checking child [1836-spell(blood_of_the_enemy)]
[1836] >>> Returning for 'spell(blood_of_the_enemy)' cached value none at empty set
[1832]    group checking child [1836-spell(blood_of_the_enemy)] result: empty set
[1832]   child [1836] measure is 0, skipping
[1832]    group checking child [1855-[if]]
[1855] >>> Returning for 'if' cached value none at empty set
[1832]    group checking child [1855-[if]] result: empty set
[1832]   child [1855] measure is 0, skipping
[1832]    group checking child [1857-spell(ripple_in_space)]
[1857] >>> Returning for 'spell(ripple_in_space)' cached value none at empty set
[1832]    group checking child [1857-spell(ripple_in_space)] result: empty set
[1832]   child [1857] measure is 0, skipping
[1832]    group checking child [1859-spell(worldvein_resonance)]
[1859] >>> Returning for 'spell(worldvein_resonance)' cached value none at empty set
[1832]    group checking child [1859-spell(worldvein_resonance)] result: empty set
[1832]   child [1859] measure is 0, skipping
[1832]    group checking child [1861-spell(the_unbound_force)]
[1861] >>> Returning for 'spell(the_unbound_force)' cached value none at empty set
[1832]    group checking child [1861-spell(the_unbound_force)] result: empty set
[1832]   child [1861] measure is 0, skipping
[1832]    group no best action returns none at empty set
[1832] <<< 'group' returns empty set with value = none
[2127]: [1832] shadowessencesmainactions is returning none
[2127] <<< 'shadowessencesmainactions()' returns empty set with value = none
[2126] >>> Computing 'group' at time=317520.842000
[2126]    group checking child [2127-shadowessencesmainactions()]
[2127] >>> Returning for 'shadowessencesmainactions()' cached value none at empty set
[2126]    group checking child [2127-shadowessencesmainactions()] result: empty set
[2126]   child [2127] measure is 0, skipping
[2126]    group no best action returns none at empty set
[2126] <<< 'group' returns empty set with value = none
[571]: [2126] shadowcdsmainactions is returning none
[571] <<< 'shadowcdsmainactions()' returns empty set with value = none
[572] >>> Computing 'shadowcdsmainpostconditions()' at time=317520.842000
[572]: calling custom function [2129] shadowcdsmainpostconditions
[2130] >>> Computing 'shadowessencesmainpostconditions()' at time=317520.842000
[2130]: calling custom function [1863] shadowessencesmainpostconditions
[1863] >>> Computing 'group' at time=317520.842000
[1863]    group no best action returns none at empty set
[1863] <<< 'group' returns empty set with value = none
[2130]: [1863] shadowessencesmainpostconditions is returning none
[2130] <<< 'shadowessencesmainpostconditions()' returns empty set with value = none
[2129] >>> Computing 'group' at time=317520.842000
[2129]    group checking child [2130-shadowessencesmainpostconditions()]
[2130] >>> Returning for 'shadowessencesmainpostconditions()' cached value none at empty set
[2129]    group checking child [2130-shadowessencesmainpostconditions()] result: empty set
[2129]   child [2130] measure is 0, skipping
[2129]    group no best action returns none at empty set
[2129] <<< 'group' returns empty set with value = none
[572]: [2129] shadowcdsmainpostconditions is returning none
[572] <<< 'shadowcdsmainpostconditions()' returns empty set with value = none
[158] >>> Returning for 'hastalent(searing_nightmare_talent)' cached value none at empty set
[551]    'function' will trigger short-circuit evaluation of parent node [580] with zero measure.
[580] >>> Computing 'logical' at time=317520.842000
[158] >>> Returning for 'hastalent(searing_nightmare_talent)' cached value none at empty set
[580]    logical 'and' short-circuits with zero measure left argument
[580]    logical 'and' returns empty set
[580] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [589] with zero measure.
[589] >>> Computing 'logical' at time=317520.842000
[580] >>> Returning for 'logical' cached value none at empty set
[589]    logical 'and' short-circuits with zero measure left argument
[589]    logical 'and' returns empty set
[589] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [596] with zero measure.
[596] >>> Computing 'logical' at time=317520.842000
[589] >>> Returning for 'logical' cached value none at empty set
[596]    logical 'and' short-circuits with zero measure left argument
[596]    logical 'and' returns empty set
[596] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [599] with zero-measure time span.
[599] >>> Computing 'if' at time=317520.842000
[596] >>> Returning for 'logical' cached value none at empty set
[599]    'if' returns empty set with zero measure
[599] <<< 'if' returns empty set with value = none
[600] >>> Computing 'insanity()' at time=317520.842000
[600]    condition 'insanity' returns 317520.842, inf, 100, 317520.842, 0.0010000000474975
[600] <<< 'insanity()' returns (317520.842, inf) with value = value 100 + (t - 317520.842) * 0.0010000000474975
[602] >>> Computing 'compare' at time=317520.842000
[600] >>> Returning for 'insanity()' cached value value 100 + (t - 317520.842) * 0.0010000000474975 at (317520.842, inf)
[602]    100+(t-317520.842)*0.0010000000474975 <= 85+(t-0)*0
[602]    intersection at t = 302520.84271246
[602]    compare '<=' returns empty set
[602] <<< 'compare' returns empty set with value = none
[551]    'compare' will trigger short-circuit evaluation of parent node [612] with zero measure.
[612] >>> Computing 'logical' at time=317520.842000
[602] >>> Returning for 'compare' cached value none at empty set
[612]    logical 'and' short-circuits with zero measure left argument
[612]    logical 'and' returns empty set
[612] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [615] with zero-measure time span.
[615] >>> Computing 'if' at time=317520.842000
[612] >>> Returning for 'logical' cached value none at empty set
[615]    'if' returns empty set with zero measure
[615] <<< 'if' returns empty set with value = action spell 205448
[619] >>> Computing 'target.refreshable(devouring_plague)' at time=317520.842000
[617] >>> Computing 'devouring_plague' at time=317520.842000
[617]    value is 335467
[617] <<< 'devouring_plague' returns (0, inf) with value = value 335467 + (t - 0) * 0
Aura 335467 is missing on Creature-0-3770-0-5276-153292-0000548E1B (mine=true).
[619]    condition 'refreshable' returns 0, inf, nil, nil, nil
[619] <<< 'target.refreshable(devouring_plague)' returns (0, inf) with value = none
[551]    'function' will trigger short-circuit evaluation of parent node [623] with universe as time span.
[623] >>> Computing 'logical' at time=317520.842000
[619] >>> Returning for 'target.refreshable(devouring_plague)' cached value none at (0, inf)
[623]    logical 'or' short-circuits with universe as left argument
[623]    logical 'or' returns (0, inf)
[623] <<< 'logical' returns (0, inf) with value = none
[624] >>> Computing 'pi_or_vf_sync_condition()' at time=317520.842000
[624]: calling custom function [291] pi_or_vf_sync_condition
[294] >>> Computing 'checkboxon("self_power_infusion")' at time=317520.842000
[294]    condition 'checkboxon' returns 0, inf, nil, nil, nil
[294] <<< 'checkboxon("self_power_infusion")' returns (0, inf) with value = none
[291]    'function' will trigger short-circuit evaluation of parent node [297] with universe as time span.
[297] >>> Computing 'logical' at time=317520.842000
[294] >>> Returning for 'checkboxon("self_power_infusion")' cached value none at (0, inf)
[297]    logical 'or' short-circuits with universe as left argument
[297]    logical 'or' returns (0, inf)
[297] <<< 'logical' returns (0, inf) with value = none
[298] >>> Computing 'level()' at time=317520.842000
[298]    condition 'level' returns 0, inf, 50, 0, 0
[298] <<< 'level()' returns (0, inf) with value = value 50 + (t - 0) * 0
[300] >>> Computing 'compare' at time=317520.842000
[298] >>> Returning for 'level()' cached value value 50 + (t - 0) * 0 at (0, inf)
[300]    50+(t-0)*0 >= 58+(t-0)*0
[300]    compare '>=' returns empty set
[300] <<< 'compare' returns empty set with value = none
[301] >>> Computing 'logical' at time=317520.842000
[297] >>> Returning for 'logical' cached value none at (0, inf)
[300] >>> Returning for 'compare' cached value none at empty set
[301]    logical 'and' returns empty set
[301] <<< 'logical' returns empty set with value = none
[291]    'logical' will trigger short-circuit evaluation of parent node [306] with zero measure.
[306] >>> Computing 'logical' at time=317520.842000
[301] >>> Returning for 'logical' cached value none at empty set
[306]    logical 'and' short-circuits with zero measure left argument
[306]    logical 'and' returns empty set
[306] <<< 'logical' returns empty set with value = none
[309] >>> Computing 'compare' at time=317520.842000
[298] >>> Returning for 'level()' cached value value 50 + (t - 0) * 0 at (0, inf)
[309]    50+(t-0)*0 < 58+(t-0)*0
[309]    compare '<' returns (0, inf)
[309] <<< 'compare' returns (0, inf) with value = none
[291]    'compare' will trigger short-circuit evaluation of parent node [317] with universe as time span.
[317] >>> Computing 'logical' at time=317520.842000
[309] >>> Returning for 'compare' cached value none at (0, inf)
[317]    logical 'or' short-circuits with universe as left argument
[317]    logical 'or' returns (0, inf)
[317] <<< 'logical' returns (0, inf) with value = none
[319] >>> Computing 'spellcooldown(void_eruption)' at time=317520.842000
[318] >>> Computing 'void_eruption' at time=317520.842000
[318]    value is 228260
[318] <<< 'void_eruption' returns (0, inf) with value = value 228260 + (t - 0) * 0
Didn't find an existing cd in next, look for one in current
Call GetSpellCooldown which returned 317504.096000, 90.000000, 1
GlobalCooldown is 0, 0
It returned 317503.996000, 90.000000
Cooldown of spell 228260 is 317503.896000 + 90.000000
[319]    condition 'spellcooldown' returns 0, inf, 0, 317593.896, -1
[319] <<< 'spellcooldown(void_eruption)' returns (0, inf) with value = value 0 + (t - 317593.896) * -1
[320] >>> Computing 'compare' at time=317520.842000
[319] >>> Returning for 'spellcooldown(void_eruption)' cached value value 0 + (t - 317593.896) * -1 at (0, inf)
[320]    0+(t-317593.896)*-1 > 0+(t-0)*0
[320]    intersection at t = 317593.896
[320]    compare '>' returns (0, 317593.896)
[320] <<< 'compare' returns (0, 317593.896) with value = none
[321] >>> Computing 'logical' at time=317520.842000
[320] >>> Returning for 'compare' cached value none at (0, 317593.896)
[321]    logical 'not' returns (317593.896, inf)
[321] <<< 'logical' returns (317593.896, inf) with value = none
[322] >>> Computing 'logical' at time=317520.842000
[317] >>> Returning for 'logical' cached value none at (0, inf)
[321] >>> Returning for 'logical' cached value none at (317593.896, inf)
[322]    logical 'and' returns (317593.896, inf)
[322] <<< 'logical' returns (317593.896, inf) with value = none
[323] >>> Computing 'logical' at time=317520.842000
[306] >>> Returning for 'logical' cached value none at empty set
[322] >>> Returning for 'logical' cached value none at (317593.896, inf)
[323]    logical 'or' returns (317593.896, inf)
[323] <<< 'logical' returns (317593.896, inf) with value = none
[291] >>> Computing 'group' at time=317520.842000
[291]    group checking child [323-[logical]]
[323] >>> Returning for 'logical' cached value none at (317593.896, inf)
[291]    group checking child [323-[logical]] result: (317593.896, inf)
[291]    group first best is [323-[logical]]: (317593.896, inf)
[291]    group best action remains none at (317593.896, inf)
[291] <<< 'group' returns (317593.896, inf) with value = none
[624]: [291] pi_or_vf_sync_condition is returning none
[624] <<< 'pi_or_vf_sync_condition()' returns (317593.896, inf) with value = none
[625] >>> Computing 'logical' at time=317520.842000
[624] >>> Returning for 'pi_or_vf_sync_condition()' cached value none at (317593.896, inf)
[625]    logical 'not' returns (0, 317593.896)
[625] <<< 'logical' returns (0, 317593.896) with value = none
[626] >>> Computing 'logical' at time=317520.842000
[623] >>> Returning for 'logical' cached value none at (0, inf)
[625] >>> Returning for 'logical' cached value none at (0, 317593.896)
[626]    logical 'and' returns (0, 317593.896)
[626] <<< 'logical' returns (0, 317593.896) with value = none
[630] >>> Computing 'logical' at time=317520.842000
[158] >>> Returning for 'hastalent(searing_nightmare_talent)' cached value none at empty set
[630]    logical 'not' returns (0, inf)
[630] <<< 'logical' returns (0, inf) with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [636] with universe as time span.
[636] >>> Computing 'logical' at time=317520.842000
[630] >>> Returning for 'logical' cached value none at (0, inf)
[636]    logical 'or' short-circuits with universe as left argument
[636]    logical 'or' returns (0, inf)
[636] <<< 'logical' returns (0, inf) with value = none
[637] >>> Computing 'logical' at time=317520.842000
[626] >>> Returning for 'logical' cached value none at (0, 317593.896)
[636] >>> Returning for 'logical' cached value none at (0, inf)
[637]    logical 'and' returns (0, 317593.896)
[637] <<< 'logical' returns (0, 317593.896) with value = none
[639] >>> Computing 'spell(devouring_plague)' at time=317520.842000
[639]    evaluating action: spell()
[638] >>> Computing 'devouring_plague' at time=317520.842000
[638]    value is 335467
[638] <<< 'devouring_plague' returns (0, inf) with value = value 335467 + (t - 0) * 0
Found spell info about 335467 (isKnown = true)
Spell has cost of %d for %s
Spell has cost of 5000 for insanity
Spell ID '335467' does not have enough power.
OvaleSpells:IsUsableSpell(335467, 317520.842000, Creature-0-3770-0-5276-153292-0000548E1B) returned false, true
Didn't find an existing cd in next, look for one in current
Call GetSpellCooldown which returned 0.000000, 0.000000, 1
It returned -0.100000, 0.000000
Spell cooldown is in the past
Cooldown of spell 335467 is 0.000000 + 0.000000
GetSpellCooldown returned 0.000000, 0.000000
Spell cooldown is in the past
Cooldown of spell 335467 is 0.000000 + 0.000000
[639]    Action spell still has 0.000000 charges but is on GCD (start=0.000000).
[639]    start=0.000000 atTime=317520.842000
[639]    Action spell is waiting for the global cooldown.
[639]    Action spell can start at 0.000000.
[639] <<< 'spell(devouring_plague)' returns (0, inf) with value = action spell 335467
[640] >>> Computing 'if' at time=317520.842000
[637] >>> Returning for 'logical' cached value none at (0, 317593.896)
[639] >>> Returning for 'spell(devouring_plague)' cached value action spell 335467 at (0, inf)
[640]    'if' returns (0, 317593.896) (intersection of (0, 317593.896) and (0, inf))
[640] <<< 'if' returns (0, 317593.896) with value = action spell 335467
[643] >>> Computing 'conduit(dissonant_echoes_conduit)' at time=317520.842000
[642] >>> Computing 'dissonant_echoes_conduit' at time=317520.842000
[642]    value is 115
[642] <<< 'dissonant_echoes_conduit' returns (0, inf) with value = value 115 + (t - 0) * 0
[643]    condition 'conduit' returns nil, nil, nil, nil, nil
[643] <<< 'conduit(dissonant_echoes_conduit)' returns empty set with value = none
[644] >>> Computing 'arithmetic' at time=317520.842000
[643] >>> Returning for 'conduit(dissonant_echoes_conduit)' cached value none at empty set
[644]    4+(t-0)*0 + 0+(t-0)*0
[644]    arithmetic '+' returns 4+(t-317520.842)*0
[644] <<< 'arithmetic' returns (0, inf) with value = value 4 + (t - 317520.842) * 0
[645] >>> Computing 'compare' at time=317520.842000
[326] >>> Returning for 'enemies()' cached value value 1 + (t - 0) * 0 at (0, inf)
[644] >>> Returning for 'arithmetic' cached value value 4 + (t - 317520.842) * 0 at (0, inf)
[645]    1+(t-0)*0 < 4+(t-317520.842)*0
[645]    compare '<' returns (0, inf)
[645] <<< 'compare' returns (0, inf) with value = none
[647] >>> Computing 'compare' at time=317520.842000
[600] >>> Returning for 'insanity()' cached value value 100 + (t - 317520.842) * 0.0010000000474975 at (317520.842, inf)
[647]    100+(t-317520.842)*0.0010000000474975 <= 85+(t-0)*0
[647]    intersection at t = 302520.84271246
[647]    compare '<=' returns empty set
[647] <<< 'compare' returns empty set with value = none
[648] >>> Computing 'logical' at time=317520.842000
[645] >>> Returning for 'compare' cached value none at (0, inf)
[647] >>> Returning for 'compare' cached value none at empty set
[648]    logical 'and' returns empty set
[648] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [651] with zero-measure time span.
[651] >>> Computing 'if' at time=317520.842000
[648] >>> Returning for 'logical' cached value none at empty set
[651]    'if' returns empty set with zero measure
[651] <<< 'if' returns empty set with value = action spell 205448
[654] >>> Computing 'compare' at time=317520.842000
[326] >>> Returning for 'enemies()' cached value value 1 + (t - 0) * 0 at (0, inf)
[654]    1+(t-0)*0 > 1+(t-0)*0
[654]    compare '>' returns empty set
[654] <<< 'compare' returns empty set with value = none
[551]    'compare' will trigger short-circuit evaluation of parent node [662] with zero measure.
[662] >>> Computing 'logical' at time=317520.842000
[654] >>> Returning for 'compare' cached value none at empty set
[662]    logical 'and' short-circuits with zero measure left argument
[662]    logical 'and' returns empty set
[662] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [665] with zero-measure time span.
[665] >>> Computing 'if' at time=317520.842000
[662] >>> Returning for 'logical' cached value none at empty set
[665]    'if' returns empty set with zero measure
[665] <<< 'if' returns empty set with value = none
[673] >>> Computing 'dots_up()' at time=317520.842000
[673]: calling custom function [354] dots_up
[336] >>> Computing 'target.debuffpresent(shadow_word_pain)' at time=317520.842000
computing positional parameters
[330] >>> Computing 'shadow_word_pain' at time=317520.842000
[330]    value is 589
[330] <<< 'shadow_word_pain' returns (0, inf) with value = value 589 + (t - 0) * 0
Found aura with stack = 1
Aura 589 found on Creature-0-3770-0-5276-153292-0000548E1B with (317492.77, 317511.768) [stacks=1]
[336]    condition 'debuffpresent' returns 317506.906, 317511.768, nil, nil, nil
[336] <<< 'target.debuffpresent(shadow_word_pain)' returns (317506.906, 317511.768) with value = none
[343] >>> Computing 'target.debuffpresent(vampiric_touch)' at time=317520.842000
computing positional parameters
[337] >>> Computing 'vampiric_touch' at time=317520.842000
[337]    value is 34914
[337] <<< 'vampiric_touch' returns (0, inf) with value = value 34914 + (t - 0) * 0
Found aura with stack = 1
Aura 34914 found on Creature-0-3770-0-5276-153292-0000548E1B with (317492.823, 317516.741) [stacks=1]
[343]    condition 'debuffpresent' returns 317516.591, 317516.741, nil, nil, nil
[343] <<< 'target.debuffpresent(vampiric_touch)' returns (317516.591, 317516.741) with value = none
[369] >>> Computing 'logical' at time=317520.842000
[336] >>> Returning for 'target.debuffpresent(shadow_word_pain)' cached value none at (317506.906, 317511.768)
[343] >>> Returning for 'target.debuffpresent(vampiric_touch)' cached value none at (317516.591, 317516.741)
[369]    logical 'and' returns empty set
[369] <<< 'logical' returns empty set with value = none
[354] >>> Computing 'group' at time=317520.842000
[354]    group checking child [369-[logical]]
[369] >>> Returning for 'logical' cached value none at empty set
[354]    group checking child [369-[logical]] result: empty set
[354]   child [369] measure is 0, skipping
[354]    group no best action returns none at empty set
[354] <<< 'group' returns empty set with value = none
[673]: [354] dots_up is returning none
[673] <<< 'dots_up()' returns empty set with value = none
[674] >>> Computing 'logical' at time=317520.842000
[661] >>> Computing 'buffpresent(dark_thought)' at time=317520.842000
computing positional parameters
[655] >>> Computing 'dark_thought' at time=317520.842000
[655]    value is 341207
[655] <<< 'dark_thought' returns (0, inf) with value = value 341207 + (t - 0) * 0
Found aura with stack = 1
Aura 341207 found on Player-1315-05C8DCE1 with (317511.389, 317512.11) [stacks=1]
[661]    condition 'buffpresent' returns 317511.389, 317512.11, nil, nil, nil
[661] <<< 'buffpresent(dark_thought)' returns (317511.389, 317512.11) with value = none
[673] >>> Returning for 'dots_up()' cached value none at empty set
[674]    logical 'and' returns empty set
[674] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [677] with zero-measure time span.
[677] >>> Computing 'if' at time=317520.842000
[674] >>> Returning for 'logical' cached value none at empty set
[677]    'if' returns empty set with zero measure
[677] <<< 'if' returns empty set with value = action spell 15407
[681] >>> Computing 'casttime(mind_blast)' at time=317520.842000
[680] >>> Computing 'mind_blast' at time=317520.842000
[680]    value is 8092
[680] <<< 'mind_blast' returns (0, inf) with value = value 8092 + (t - 0) * 0
[681]    condition 'casttime' returns 0, inf, 1.317, 0, 0
[681] <<< 'casttime(mind_blast)' returns (0, inf) with value = value 1.317 + (t - 0) * 0
[683] >>> Computing 'arithmetic' at time=317520.842000
[681] >>> Returning for 'casttime(mind_blast)' cached value value 1.317 + (t - 0) * 0 at (0, inf)
[683]    1.317+(t-0)*0 + 0.5+(t-0)*0
[683]    arithmetic '+' returns 1.817+(t-317520.842)*0
[683] <<< 'arithmetic' returns (0, inf) with value = value 1.817 + (t - 317520.842) * 0
[684] >>> Computing 'compare' at time=317520.842000
[683] >>> Returning for 'arithmetic' cached value value 1.817 + (t - 317520.842) * 0 at (0, inf)
[684]    600+(t-0)*0 > 1.817+(t-317520.842)*0
[684]    compare '>' returns (0, inf)
[684] <<< 'compare' returns (0, inf) with value = none
[685] >>> Computing 'logical' at time=317520.842000
[673] >>> Returning for 'dots_up()' cached value none at empty set
[685]    logical 'and' short-circuits with zero measure left argument
[685]    logical 'and' returns empty set
[685] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [688] with zero measure.
[688] >>> Computing 'logical' at time=317520.842000
[685] >>> Returning for 'logical' cached value none at empty set
[688]    logical 'and' short-circuits with zero measure left argument
[688]    logical 'and' returns empty set
[688] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [691] with zero-measure time span.
[691] >>> Computing 'if' at time=317520.842000
[688] >>> Returning for 'logical' cached value none at empty set
[691]    'if' returns empty set with zero measure
[691] <<< 'if' returns empty set with value = action spell 8092
[694] >>> Computing 'target.refreshable(vampiric_touch)' at time=317520.842000
[692] >>> Computing 'vampiric_touch' at time=317520.842000
[692]    value is 34914
[692] <<< 'vampiric_touch' returns (0, inf) with value = value 34914 + (t - 0) * 0
Found aura with stack = 1
Aura 34914 found on Creature-0-3770-0-5276-153292-0000548E1B with (317492.823, 317516.741) [stacks=1]
[694]    condition 'refreshable' returns 317510.441, inf, nil, nil, nil
[694] <<< 'target.refreshable(vampiric_touch)' returns (317510.441, inf) with value = none
[696] >>> Computing 'target.timetodie()' at time=317520.842000
[696]    condition 'timetodie' returns 317520.842, inf, 1011.4330997943, 317520.842, -1
[696] <<< 'target.timetodie()' returns (317520.842, inf) with value = value 1011.4330997943 + (t - 317520.842) * -1
[697] >>> Computing 'compare' at time=317520.842000
[696] >>> Returning for 'target.timetodie()' cached value value 1011.4330997943 + (t - 317520.842) * -1 at (317520.842, inf)
[697]    1011.4330997943+(t-317520.842)*-1 > 6+(t-0)*0
[697]    intersection at t = 318526.27509979
[697]    compare '>' returns (317520.842, 318526.27509979)
[697] <<< 'compare' returns (317520.842, 318526.27509979) with value = none
[698] >>> Computing 'logical' at time=317520.842000
[694] >>> Returning for 'target.refreshable(vampiric_touch)' cached value none at (317510.441, inf)
[697] >>> Returning for 'compare' cached value none at (317520.842, 318526.27509979)
[698]    logical 'and' returns (317520.842, 318526.27509979)
[698] <<< 'logical' returns (317520.842, 318526.27509979) with value = none
[700] >>> Computing 'hastalent(misery_talent)' at time=317520.842000
[699] >>> Computing 'misery_talent' at time=317520.842000
[699]    value is 23126
[699] <<< 'misery_talent' returns (0, inf) with value = value 23126 + (t - 0) * 0
[700]    condition 'hastalent' returns 0, inf, nil, nil, nil
[700] <<< 'hastalent(misery_talent)' returns (0, inf) with value = none
[704] >>> Returning for 'target.debuffrefreshable(shadow_word_pain)' cached value none at (317508.168, inf)
[705] >>> Computing 'logical' at time=317520.842000
[700] >>> Returning for 'hastalent(misery_talent)' cached value none at (0, inf)
[704] >>> Returning for 'target.debuffrefreshable(shadow_word_pain)' cached value none at (317508.168, inf)
[705]    logical 'and' returns (317508.168, inf)
[705] <<< 'logical' returns (317508.168, inf) with value = none
[706] >>> Computing 'logical' at time=317520.842000
[698] >>> Returning for 'logical' cached value none at (317520.842, 318526.27509979)
[705] >>> Returning for 'logical' cached value none at (317508.168, inf)
[706]    logical 'or' returns (317508.168, inf)
[706] <<< 'logical' returns (317508.168, inf) with value = none
[713] >>> Computing 'buffpresent(unfurling_darkness)' at time=317520.842000
computing positional parameters
[707] >>> Computing 'unfurling_darkness' at time=317520.842000
[707]    value is 341291
[707] <<< 'unfurling_darkness' returns (0, inf) with value = value 341291 + (t - 0) * 0
Aura 341291 is missing on Player-1315-05C8DCE1 (mine=true).
[713]    condition 'buffpresent' returns nil, nil, nil, nil, nil
[713] <<< 'buffpresent(unfurling_darkness)' returns empty set with value = none
[714] >>> Computing 'logical' at time=317520.842000
[706] >>> Returning for 'logical' cached value none at (317508.168, inf)
[713] >>> Returning for 'buffpresent(unfurling_darkness)' cached value none at empty set
[714]    logical 'or' returns (317508.168, inf)
[714] <<< 'logical' returns (317508.168, inf) with value = none
[476] >>> Computing 'spell(vampiric_touch)' at time=317520.842000
[476]    evaluating action: spell()
[475] >>> Computing 'vampiric_touch' at time=317520.842000
[475]    value is 34914
[475] <<< 'vampiric_touch' returns (0, inf) with value = value 34914 + (t - 0) * 0
Found spell info about 34914 (isKnown = true)
Spell has cost of %d for %s
Spell has cost of -500 for insanity
Spell has cost of -500 for insanity
Spell has cost of %d for %s
Spell ID '34914' passed power requirements.
OvaleSpells:IsUsableSpell(34914, 317520.842000, Creature-0-3770-0-5276-153292-0000548E1B) returned true, false
Didn't find an existing cd in next, look for one in current
Call GetSpellCooldown which returned 0.000000, 0.000000, 1
It returned -0.100000, 0.000000
Spell cooldown is in the past
Cooldown of spell 34914 is 0.000000 + 0.000000
GetSpellCooldown returned 0.000000, 0.000000
Spell cooldown is in the past
Cooldown of spell 34914 is 0.000000 + 0.000000
[476]    Action spell still has 0.000000 charges but is on GCD (start=0.000000).
[476]    start=0.000000 atTime=317520.842000
[476]    Action spell is waiting for the global cooldown.
[476]    Action spell can start at 0.000000.
[476] <<< 'spell(vampiric_touch)' returns (0, inf) with value = action spell 34914
[717] >>> Computing 'if' at time=317520.842000
[714] >>> Returning for 'logical' cached value none at (317508.168, inf)
[476] >>> Returning for 'spell(vampiric_touch)' cached value action spell 34914 at (0, inf)
[717]    'if' returns (317508.168, inf) (intersection of (317508.168, inf) and (0, inf))
[717] <<< 'if' returns (317508.168, inf) with value = action spell 34914
[720] >>> Computing 'target.refreshable(shadow_word_pain)' at time=317520.842000
[718] >>> Computing 'shadow_word_pain' at time=317520.842000
[718]    value is 589
[718] <<< 'shadow_word_pain' returns (0, inf) with value = value 589 + (t - 0) * 0
Found aura with stack = 1
Aura 589 found on Creature-0-3770-0-5276-153292-0000548E1B with (317492.77, 317511.768) [stacks=1]
[720]    condition 'refreshable' returns 317508.168, inf, nil, nil, nil
[720] <<< 'target.refreshable(shadow_word_pain)' returns (317508.168, inf) with value = none
[723] >>> Computing 'compare' at time=317520.842000
[696] >>> Returning for 'target.timetodie()' cached value value 1011.4330997943 + (t - 317520.842) * -1 at (317520.842, inf)
[723]    1011.4330997943+(t-317520.842)*-1 > 4+(t-0)*0
[723]    intersection at t = 318528.27509979
[723]    compare '>' returns (317520.842, 318528.27509979)
[723] <<< 'compare' returns (317520.842, 318528.27509979) with value = none
[724] >>> Computing 'logical' at time=317520.842000
[720] >>> Returning for 'target.refreshable(shadow_word_pain)' cached value none at (317508.168, inf)
[723] >>> Returning for 'compare' cached value none at (317520.842, 318528.27509979)
[724]    logical 'and' returns (317520.842, 318528.27509979)
[724] <<< 'logical' returns (317520.842, 318528.27509979) with value = none
[727] >>> Computing 'logical' at time=317520.842000
[700] >>> Returning for 'hastalent(misery_talent)' cached value none at (0, inf)
[727]    logical 'not' returns empty set
[727] <<< 'logical' returns empty set with value = none
[728] >>> Computing 'logical' at time=317520.842000
[724] >>> Returning for 'logical' cached value none at (317520.842, 318528.27509979)
[727] >>> Returning for 'logical' cached value none at empty set
[728]    logical 'and' returns empty set
[728] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [731] with zero measure.
[731] >>> Computing 'logical' at time=317520.842000
[728] >>> Returning for 'logical' cached value none at empty set
[731]    logical 'and' short-circuits with zero measure left argument
[731]    logical 'and' returns empty set
[731] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [734] with zero measure.
[734] >>> Computing 'logical' at time=317520.842000
[731] >>> Returning for 'logical' cached value none at empty set
[734]    logical 'and' short-circuits with zero measure left argument
[734]    logical 'and' returns empty set
[734] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [737] with zero-measure time span.
[737] >>> Computing 'if' at time=317520.842000
[734] >>> Returning for 'logical' cached value none at empty set
[737]    'if' returns empty set with zero measure
[737] <<< 'if' returns empty set with value = none
[743] >>> Computing 'compare' at time=317520.842000
[696] >>> Returning for 'target.timetodie()' cached value value 1011.4330997943 + (t - 317520.842) * -1 at (317520.842, inf)
[743]    1011.4330997943+(t-317520.842)*-1 > 4+(t-0)*0
[743]    intersection at t = 318528.27509979
[743]    compare '>' returns (317520.842, 318528.27509979)
[743] <<< 'compare' returns (317520.842, 318528.27509979) with value = none
[744] >>> Computing 'logical' at time=317520.842000
[720] >>> Returning for 'target.refreshable(shadow_word_pain)' cached value none at (317508.168, inf)
[743] >>> Returning for 'compare' cached value none at (317520.842, 318528.27509979)
[744]    logical 'and' returns (317520.842, 318528.27509979)
[744] <<< 'logical' returns (317520.842, 318528.27509979) with value = none
[747] >>> Computing 'logical' at time=317520.842000
[700] >>> Returning for 'hastalent(misery_talent)' cached value none at (0, inf)
[747]    logical 'not' returns empty set
[747] <<< 'logical' returns empty set with value = none
[748] >>> Computing 'logical' at time=317520.842000
[744] >>> Returning for 'logical' cached value none at (317520.842, 318528.27509979)
[747] >>> Returning for 'logical' cached value none at empty set
[748]    logical 'and' returns empty set
[748] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [758] with zero measure.
[758] >>> Computing 'logical' at time=317520.842000
[748] >>> Returning for 'logical' cached value none at empty set
[758]    logical 'and' short-circuits with zero measure left argument
[758]    logical 'and' returns empty set
[758] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [769] with zero measure.
[769] >>> Computing 'logical' at time=317520.842000
[758] >>> Returning for 'logical' cached value none at empty set
[769]    logical 'and' short-circuits with zero measure left argument
[769]    logical 'and' returns empty set
[769] <<< 'logical' returns empty set with value = none
[551]    'logical' will trigger short-circuit evaluation of parent node [772] with zero-measure time span.
[772] >>> Computing 'if' at time=317520.842000
[769] >>> Returning for 'logical' cached value none at empty set
[772]    'if' returns empty set with zero measure
[772] <<< 'if' returns empty set with value = none
[775] >>> Computing 'compare' at time=317520.842000
[326] >>> Returning for 'enemies()' cached value value 1 + (t - 0) * 0 at (0, inf)
[775]    1+(t-0)*0 > 1+(t-0)*0
[775]    compare '>' returns empty set
[775] <<< 'compare' returns empty set with value = none
[551]    'compare' will trigger short-circuit evaluation of parent node [778] with zero-measure time span.
[778] >>> Computing 'if' at time=317520.842000
[775] >>> Returning for 'compare' cached value none at empty set
[778]    'if' returns empty set with zero measure
[778] <<< 'if' returns empty set with value = none
[573] >>> Computing 'group' at time=317520.842000
[573]    group checking child [599-[if]]
[599] >>> Returning for 'if' cached value none at empty set
[573]    group checking child [599-[if]] result: empty set
[573]   child [599] measure is 0, skipping
[573]    group checking child [615-[if]]
[615] >>> Returning for 'if' cached value action spell 205448 at empty set
[573]    group checking child [615-[if]] result: empty set
[573]   child [615] measure is 0, skipping
[573]    group checking child [640-[if]]
[640] >>> Returning for 'if' cached value action spell 335467 at (0, 317593.896)
[573]    group checking child [640-[if]] result: (317520.842, 317593.896)
[573]    group first best is [640-[if]]: (317520.842, 317593.896)
[573]    group checking child [651-[if]]
[651] >>> Returning for 'if' cached value action spell 205448 at empty set
[573]    group checking child [651-[if]] result: (317520.842, 317593.896)
[573]    group new best is [651-[if]]: empty set
[573]    group checking child [665-[if]]
[665] >>> Returning for 'if' cached value none at empty set
[573]    group checking child [665-[if]] result: (317520.842, 317593.896)
[573] group best is still action spell 205448: (317520.842, 317593.896)
[573]    group checking child [677-[if]]
[677] >>> Returning for 'if' cached value action spell 15407 at empty set
[573]    group checking child [677-[if]] result: (317520.842, 317593.896)
[573] group best is still action spell 205448: (317520.842, 317593.896)
[573]    group checking child [691-[if]]
[691] >>> Returning for 'if' cached value action spell 8092 at empty set
[573]    group checking child [691-[if]] result: (317520.842, 317593.896)
[573] group best is still action spell 205448: (317520.842, 317593.896)
[573]    group checking child [717-[if]]
[717] >>> Returning for 'if' cached value action spell 34914 at (317508.168, inf)
[573]    group checking child [717-[if]] result: (317520.842, inf)
[573] group best is still action spell 205448: (317520.842, 317593.896)
[573]    group checking child [737-[if]]
[737] >>> Returning for 'if' cached value none at empty set
[573]    group checking child [737-[if]] result: (317520.842, inf)
[573] group best is still action spell 205448: (317520.842, 317593.896)
[573]    group checking child [772-[if]]
[772] >>> Returning for 'if' cached value none at empty set
[573]    group checking child [772-[if]] result: (317520.842, inf)
[573] group best is still action spell 205448: (317520.842, 317593.896)
[573]    group checking child [778-[if]]
[778] >>> Returning for 'if' cached value none at empty set
[573]    group checking child [778-[if]] result: (317520.842, inf)
[573] group best is still action spell 205448: (317520.842, 317593.896)
[573]    group checking child [676-spell(mind_flay)]
[676] >>> Computing 'spell(mind_flay)' at time=317520.842000
[676]    evaluating action: spell()
[675] >>> Computing 'mind_flay' at time=317520.842000
[675]    value is 15407
[675] <<< 'mind_flay' returns (0, inf) with value = value 15407 + (t - 0) * 0
Found spell info about 15407 (isKnown = true)
Spell has cost of %d for %s
Spell has cost of %d for %s
Spell has cost of %d for %s
Spell has cost of %d for %s
Spell ID '15407' passed power requirements.
OvaleSpells:IsUsableSpell(15407, 317520.842000, Creature-0-3770-0-5276-153292-0000548E1B) returned true, false
Didn't find an existing cd in next, look for one in current
Call GetSpellCooldown which returned 0.000000, 0.000000, 1
It returned -0.100000, 0.000000
Spell cooldown is in the past
Cooldown of spell 15407 is 0.000000 + 0.000000
GetSpellCooldown returned 0.000000, 0.000000
Spell cooldown is in the past
Cooldown of spell 15407 is 0.000000 + 0.000000
[676]    Action spell still has 0.000000 charges but is on GCD (start=0.000000).
[676]    start=0.000000 atTime=317520.842000
[676]    Action spell is waiting for the global cooldown.
[676]    Action spell can start at 0.000000.
[676] <<< 'spell(mind_flay)' returns (0, inf) with value = action spell 15407
[573]    group checking child [676-spell(mind_flay)] result: (317520.842, inf)
[573] group best is still action spell 205448: (317520.842, 317593.896)
[573]    group checking child [569-spell(shadow_word_pain)]
[569] >>> Computing 'spell(shadow_word_pain)' at time=317520.842000
[569]    evaluating action: spell()
[568] >>> Computing 'shadow_word_pain' at time=317520.842000
[568]    value is 589
[568] <<< 'shadow_word_pain' returns (0, inf) with value = value 589 + (t - 0) * 0
Found spell info about 589 (isKnown = true)
Spell has cost of %d for %s
Spell has cost of -400 for insanity
Spell has cost of -400 for insanity
Spell has cost of %d for %s
Spell ID '589' passed power requirements.
OvaleSpells:IsUsableSpell(589, 317520.842000, Creature-0-3770-0-5276-153292-0000548E1B) returned true, false
Didn't find an existing cd in next, look for one in current
Call GetSpellCooldown which returned 0.000000, 0.000000, 1
It returned -0.100000, 0.000000
Spell cooldown is in the past
Cooldown of spell 589 is 0.000000 + 0.000000
GetSpellCooldown returned 0.000000, 0.000000
Spell cooldown is in the past
Cooldown of spell 589 is 0.000000 + 0.000000
[569]    Action spell still has 0.000000 charges but is on GCD (start=0.000000).
[569]    start=0.000000 atTime=317520.842000
[569]    Action spell is waiting for the global cooldown.
[569]    Action spell can start at 0.000000.
[569] <<< 'spell(shadow_word_pain)' returns (0, inf) with value = action spell 589
[573]    group checking child [569-spell(shadow_word_pain)] result: (317520.842, inf)
[573] group best is still action spell 205448: (317520.842, 317593.896)
[573]    group best action remains action spell 205448 at empty set
[573] <<< 'group' returns empty set with value = action spell 205448
[783] >>> Computing 'unless' at time=317520.842000
[572] >>> Returning for 'shadowcdsmainpostconditions()' cached value none at empty set
[573] >>> Returning for 'group' cached value action spell 205448 at empty set
[783]    'unless' returns empty set (intersection of (0, inf) and empty set)
[783] <<< 'unless' returns empty set with value = action spell 205448
[551] >>> Computing 'group' at time=317520.842000
[551]    group checking child [570-[if]]
[570] >>> Returning for 'if' cached value none at empty set
[551]    group checking child [570-[if]] result: empty set
[551]   child [570] measure is 0, skipping
[551]    group checking child [571-shadowcdsmainactions()]
[571] >>> Returning for 'shadowcdsmainactions()' cached value none at empty set
[551]    group checking child [571-shadowcdsmainactions()] result: empty set
[551]   child [571] measure is 0, skipping
[551]    group checking child [783-[unless]]
[783] >>> Returning for 'unless' cached value action spell 205448 at empty set
[551]    group checking child [783-[unless]] result: empty set
[551]   child [783] measure is 0, skipping
[551]    group no best action returns none at empty set
[551] <<< 'group' returns empty set with value = none
[2165]: [551] shadowmainmainactions is returning none
[2165] <<< 'shadowmainmainactions()' returns empty set with value = none
[2166] >>> Computing 'unless' at time=317520.842000
[2163] >>> Returning for 'shadowcwcmainpostconditions()' cached value none at empty set
[2165] >>> Returning for 'shadowmainmainactions()' cached value none at empty set
[2166]    'unless' returns empty set (intersection of (0, inf) and empty set)
[2166] <<< 'unless' returns empty set with value = none
[2161] >>> Computing 'group' at time=317520.842000
[2161]    group checking child [2162-shadowcwcmainactions()]
[2162] >>> Returning for 'shadowcwcmainactions()' cached value action spell 8092 at (317525.008, inf)
[2161]    group checking child [2162-shadowcwcmainactions()] result: (317525.008, inf)
[2161]    group first best is [2162-shadowcwcmainactions()]: (317525.008, inf)
[2161]    group checking child [2166-[unless]]
[2166] >>> Returning for 'unless' cached value none at empty set
[2161]    group checking child [2166-[unless]] result: (317525.008, inf)
[2161] group best is still action spell 8092: (317525.008, inf)
[2161]    group best action remains action spell 8092 at (317525.008, inf)
[2161] <<< 'group' returns (317525.008, inf) with value = action spell 8092
[2240]: [2161] shadow_defaultmainactions is returning action spell 8092
[2240] <<< 'shadow_defaultmainactions()' returns (317525.008, inf) with value = action spell 8092
[2235] >>> Computing 'group' at time=317520.842000
[2235]    group checking child [2239-[if]]
[2239] >>> Returning for 'if' cached value action spell 34914 at empty set
[2235]    group checking child [2239-[if]] result: empty set
[2235]   child [2239] measure is 0, skipping
[2235]    group checking child [2240-shadow_defaultmainactions()]
[2240] >>> Returning for 'shadow_defaultmainactions()' cached value action spell 8092 at (317525.008, inf)
[2235]    group checking child [2240-shadow_defaultmainactions()] result: (317525.008, inf)
[2235]    group first best is [2240-shadow_defaultmainactions()]: (317525.008, inf)
[2235]    group best action remains action spell 8092 at (317525.008, inf)
[2235] <<< 'group' returns (317525.008, inf) with value = action spell 8092`;

test.skip("test icon tool", () => {
    const [result, iconDump, nodeList, logs] = executeDump(dump);
    assertDefined(result);
    expect(logs).toBe(expectedLogs);
    assertIs(result.type, "action");
    for (const [k, v] of Object.entries(iconDump.nodes)) {
        const node = nodeList[parseInt(k)];
        if (v.asString === null) expect(node.asString).toBeUndefined();
        else expect(node.asString).toBe(v.asString);
        expect(node.type).toBe(v.type);
    }
    for (const [k, v] of Object.entries(iconDump.nodes)) {
        const node = nodeList[parseInt(k)];
        expect(node.result).toEqual(v);
    }
    expect(result).toEqual(iconDump.result);
});
