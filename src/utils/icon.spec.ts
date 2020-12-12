import { test } from "@jest/globals";
import { assertDefined, assertIs } from "../tests/helpers";
import { executeDump } from "./icon";

const dump = `{ "atTime": 186219.176, "serial": 1166, "index": 3, "script": "sc_t25_priest_shadow", "nodes": {
    "213": {"type": "none","serial": 1166,"timeSpan": [186291.153,inf]}
    ,"213": {"type": "none","serial": 1166,"timeSpan": [186291.153,inf]}
    ,"57": {"type": "value","timeSpan": [0,inf],"value": 14914,"rate": 0,"serial": 1166,"origin": 0}
    ,"58": {"type": "value","timeSpan": [0,inf],"value": "holy","rate": 0,"serial": 1166,"origin": 0}
    ,"59": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"104": {"type": "value","timeSpan": [0,inf],"value": 23127,"rate": 0,"serial": 1166,"origin": 0}
    ,"105": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"213": {"type": "none","serial": 1166,"timeSpan": [186291.153,inf]}
    ,"220": {"type": "value","timeSpan": [0,inf],"value": 50,"rate": 0,"serial": 1166,"origin": 0}
    ,"216": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"219": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"220": {"type": "value","timeSpan": [0,inf],"value": 50,"rate": 0,"serial": 1166,"origin": 0}
    ,"222": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"223": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"228": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"240": {"type": "value","timeSpan": [0,inf],"value": 228260,"rate": 0,"serial": 1166,"origin": 0}
    ,"231": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"239": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"240": {"type": "value","timeSpan": [0,inf],"value": 228260,"rate": 0,"serial": 1166,"origin": 0}
    ,"241": {"type": "value","timeSpan": [0,186291.153],"value": 0,"rate": -1,"serial": 1166,"origin": 186291.153}
    ,"242": {"type": "none","serial": 1166,"timeSpan": [0,186291.153]}
    ,"243": {"type": "none","serial": 1166,"timeSpan": [186291.153,inf]}
    ,"244": {"type": "none","serial": 1166,"timeSpan": [186291.153,inf]}
    ,"245": {"type": "none","serial": 1166,"timeSpan": [186291.153,inf]}
    ,"247": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"248": {"type": "value","timeSpan": [0,inf],"value": 1,"rate": 0,"serial": 1166,"origin": 0}
    ,"249": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"252": {"type": "value","timeSpan": [0,inf],"value": 589,"rate": 0,"serial": 1166,"origin": 0}
    ,"258": {"type": "none","serial": 1166,"timeSpan": [186209.743,186215.83]}
    ,"259": {"type": "value","timeSpan": [0,inf],"value": 34914,"rate": 0,"serial": 1166,"origin": 0}
    ,"265": {"type": "none","serial": 1166,"timeSpan": [186209.743,186220.83]}
    ,"276": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"291": {"type": "none","serial": 1166,"timeSpan": [186209.743,186215.83]}
    ,"397": {"type": "value","timeSpan": [0,inf],"value": 34914,"rate": 0,"serial": 1166,"origin": 0}
    ,"398": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": [0,inf],"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.324,"actionCharges": 0,"actionId": 34914,"actionEnable": 1,"actionShortcut": "A","actionTexture": 135978,"actionInRange": true,"actionType": "spell","serial": 1166,"actionUsable": true}
    ,"473": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": {},"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "none","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionShortcut": "3","actionTexture": 1035040,"actionEnable": 1,"actionInRange": true,"actionType": "spell","serial": 1166,"actionUsable": true}
    ,"474": {"type": "value","timeSpan": [0,inf],"value": 327661,"rate": 0,"serial": 1166,"origin": 0}
    ,"480": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"489": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"490": {"type": "value","timeSpan": [0,inf],"value": 589,"rate": 0,"serial": 1166,"origin": 0}
    ,"491": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": [0,inf],"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 589,"actionEnable": 1,"actionShortcut": "B4","actionTexture": 136207,"actionInRange": true,"actionType": "spell","serial": 1166,"actionUsable": true}
    ,"492": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"493": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"494": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"495": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": {},"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionShortcut": "3","actionTexture": 1035040,"actionCooldownDuration": 0,"actionInRange": true,"actionType": "spell","serial": 1166,"actionUsable": true}
    ,"502": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"511": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"518": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"521": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"522": {"type": "value","timeSpan": [186219.176,inf],"value": 99,"rate": 0.0010000000474975,"serial": 1166,"origin": 186219.176}
    ,"524": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"534": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"534": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"537": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 1035040,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionUsable": true,"actionShortcut": "3","timeSpan": {},"actionInRange": true,"actionType": "spell","serial": 1166,"actionCooldownDuration": 0}
    ,"546": {"type": "none","serial": 1166,"timeSpan": [186291.153,inf]}
    ,"539": {"type": "value","timeSpan": [0,inf],"value": 335467,"rate": 0,"serial": 1166,"origin": 0}
    ,"541": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"545": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"546": {"type": "none","serial": 1166,"timeSpan": [186291.153,inf]}
    ,"547": {"type": "none","serial": 1166,"timeSpan": [0,186291.153]}
    ,"548": {"type": "none","serial": 1166,"timeSpan": [0,186291.153]}
    ,"559": {"type": "none","serial": 1166,"timeSpan": [0,186291.153]}
    ,"552": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"555": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"558": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"559": {"type": "none","serial": 1166,"timeSpan": [0,186291.153]}
    ,"560": {"type": "value","timeSpan": [0,inf],"value": 335467,"rate": 0,"serial": 1166,"origin": 0}
    ,"561": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": [0,inf],"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 335467,"actionUsable": false,"actionTexture": 252997,"actionEnable": 1,"actionInRange": true,"actionType": "spell","serial": 1166,"actionShortcut": "Y"}
    ,"562": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 252997,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 335467,"actionUsable": false,"actionShortcut": "Y","timeSpan": [0,186291.153],"actionInRange": true,"actionType": "spell","serial": 1166,"actionCooldownDuration": 0}
    ,"564": {"type": "value","timeSpan": [0,inf],"value": 115,"rate": 0,"serial": 1166,"origin": 0}
    ,"565": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"566": {"type": "value","timeSpan": [0,inf],"value": 4,"rate": 0,"serial": 1166,"origin": 186219.176}
    ,"567": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"569": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"570": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"573": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 1035040,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionUsable": true,"actionShortcut": "3","timeSpan": {},"actionInRange": true,"actionType": "spell","serial": 1166,"actionCooldownDuration": 0}
    ,"576": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"577": {"type": "value","timeSpan": [0,inf],"value": 341207,"rate": 0,"serial": 1166,"origin": 0}
    ,"583": {"type": "none","serial": 1166,"timeSpan": [186205.337,186205.472]}
    ,"584": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"587": {"actionCooldownStart": 186206.46,"actionIsCurrent": false,"actionTexture": 237565,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 48045,"actionUsable": true,"actionShortcut": "SE","timeSpan": {},"actionInRange": true,"actionType": "spell","serial": 1166,"actionCooldownDuration": 0}
    ,"595": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"596": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"597": {"type": "value","timeSpan": [0,inf],"value": 15407,"rate": 0,"serial": 1166,"origin": 0}
    ,"598": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": [0,inf],"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 15407,"actionEnable": 1,"actionShortcut": "R","actionTexture": 136208,"actionInRange": true,"actionType": "spell","serial": 1166,"actionUsable": true}
    ,"599": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 136208,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 15407,"actionShortcut": "R","actionUsable": true,"timeSpan": {},"actionInRange": true,"actionType": "spell","serial": 1166,"actionCooldownDuration": 0}
    ,"602": {"type": "value","timeSpan": [0,inf],"value": 8092,"rate": 0,"serial": 1166,"origin": 0}
    ,"603": {"type": "value","timeSpan": [0,inf],"value": 1.324,"rate": 0,"serial": 1166,"origin": 0}
    ,"605": {"type": "value","timeSpan": [0,inf],"value": 1.824,"rate": 0,"serial": 1166,"origin": 186219.176}
    ,"606": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"607": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"610": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"611": {"type": "value","timeSpan": [0,inf],"value": 8092,"rate": 0,"serial": 1166,"origin": 0}
    ,"612": {"actionCooldownStart": 186214.467,"actionIsCurrent": false,"timeSpan": [186221.085,inf],"actionCooldownDuration": 6.618,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.324,"actionCharges": 0,"actionId": 8092,"actionEnable": 1,"actionShortcut": "E","actionTexture": 136224,"actionInRange": true,"actionType": "spell","serial": 1166,"actionUsable": true}
    ,"613": {"actionCooldownStart": 186215.909,"actionIsCurrent": true,"actionTexture": 136224,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.324,"actionCharges": 1,"actionId": 8092,"actionShortcut": "E","actionUsable": true,"timeSpan": {},"actionInRange": true,"actionType": "spell","serial": 1166,"actionCooldownDuration": 0}
    ,"614": {"type": "value","timeSpan": [0,inf],"value": 34914,"rate": 0,"serial": 1166,"origin": 0}
    ,"616": {"type": "none","serial": 1166,"timeSpan": [186214.53,inf]}
    ,"618": {"type": "value","timeSpan": [186219.176,inf],"value": 714.58241400989,"rate": -1,"serial": 1166,"origin": 186219.176}
    ,"619": {"type": "none","serial": 1166,"timeSpan": [186219.176,186927.75841401]}
    ,"620": {"type": "none","serial": 1166,"timeSpan": [186219.176,186927.75841401]}
    ,"621": {"type": "value","timeSpan": [0,inf],"value": 23126,"rate": 0,"serial": 1166,"origin": 0}
    ,"622": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"623": {"type": "value","timeSpan": [0,inf],"value": 589,"rate": 0,"serial": 1166,"origin": 0}
    ,"626": {"type": "none","serial": 1166,"timeSpan": [186212.23,inf]}
    ,"627": {"type": "none","serial": 1166,"timeSpan": [186212.23,inf]}
    ,"628": {"type": "none","serial": 1166,"timeSpan": [186212.23,inf]}
    ,"629": {"type": "value","timeSpan": [0,inf],"value": 341291,"rate": 0,"serial": 1166,"origin": 0}
    ,"635": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"636": {"type": "none","serial": 1166,"timeSpan": [186212.23,inf]}
    ,"639": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 135978,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.324,"actionCharges": 0,"actionId": 34914,"actionShortcut": "A","timeSpan": [186212.23,inf],"actionUsable": true,"actionInRange": true,"actionType": "spell","serial": 1166,"actionCooldownDuration": 0}
    ,"640": {"type": "value","timeSpan": [0,inf],"value": 589,"rate": 0,"serial": 1166,"origin": 0}
    ,"642": {"type": "none","serial": 1166,"timeSpan": [186212.23,inf]}
    ,"645": {"type": "none","serial": 1166,"timeSpan": [186219.176,186929.75841401]}
    ,"646": {"type": "none","serial": 1166,"timeSpan": [186219.176,186929.75841401]}
    ,"649": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"650": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"653": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"656": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"659": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"665": {"type": "none","serial": 1166,"timeSpan": [186219.176,186929.75841401]}
    ,"666": {"type": "none","serial": 1166,"timeSpan": [186219.176,186929.75841401]}
    ,"669": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"670": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"680": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"691": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"691": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"694": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"697": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"700": {"actionCooldownStart": 186206.46,"actionIsCurrent": false,"actionTexture": 237565,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 48045,"actionUsable": true,"actionShortcut": "SE","timeSpan": {},"actionInRange": true,"actionType": "spell","serial": 1166,"actionCooldownDuration": 0}
    ,"705": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 1035040,"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionShortcut": "3","timeSpan": {},"actionUsable": true,"actionInRange": true,"actionType": "spell","serial": 1166,"actionEnable": 1}
    ,"905": {"type": "value","timeSpan": [0,inf],"value": 1.3237008280469,"rate": 0,"serial": 1166,"origin": 0}
    ,"1754": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1755": {"type": "value","timeSpan": [0,inf],"value": 299300,"rate": 0,"serial": 1166,"origin": 0}
    ,"1756": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1757": {"type": "value","timeSpan": [0,inf],"value": 297969,"rate": 0,"serial": 1166,"origin": 0}
    ,"1758": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1759": {"type": "value","timeSpan": [0,inf],"value": 295368,"rate": 0,"serial": 1166,"origin": 0}
    ,"1760": {"type": "value","timeSpan": [0,inf],"value": 0,"rate": 1,"serial": 1166,"origin": 0}
    ,"1761": {"type": "none","serial": 1166,"timeSpan": [6,inf]}
    ,"1774": {"type": "none","serial": 1166,"timeSpan": [6,inf]}
    ,"1763": {"type": "value","timeSpan": [186196.778,inf],"value": 0,"rate": 1,"serial": 1166,"origin": 186196.778}
    ,"1764": {"type": "none","serial": 1166,"timeSpan": [186196.778,186206.778]}
    ,"1765": {"type": "value","timeSpan": [0,inf],"value": 295368,"rate": 0,"serial": 1166,"origin": 0}
    ,"1766": {"type": "value","timeSpan": [0,inf],"value": 0,"rate": 0,"serial": 1166,"origin": 0}
    ,"1768": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"1769": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"1773": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"1774": {"type": "none","serial": 1166,"timeSpan": [6,inf]}
    ,"1775": {"type": "value","timeSpan": [0,inf],"value": 295368,"rate": 0,"serial": 1166,"origin": 0}
    ,"1776": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1777": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1778": {"type": "value","timeSpan": [0,inf],"value": 299306,"rate": 0,"serial": 1166,"origin": 0}
    ,"1779": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1780": {"type": "value","timeSpan": [0,inf],"value": 298606,"rate": 0,"serial": 1166,"origin": 0}
    ,"1781": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1782": {"type": "value","timeSpan": [0,inf],"value": 299321,"rate": 0,"serial": 1166,"origin": 0}
    ,"1783": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1785": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1940": {"actionCooldownStart": 186214.467,"actionIsCurrent": false,"actionTexture": 136224,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.324,"actionCharges": 0,"actionId": 8092,"actionShortcut": "E","timeSpan": [186221.085,inf],"actionUsable": true,"actionInRange": true,"actionType": "spell","serial": 1166,"actionCooldownDuration": 6.618}
    ,"1944": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1950": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1951": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1952": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1955": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1962": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1965": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1968": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"1972": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"2048": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"2049": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"2051": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"2052": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"2083": {"actionCooldownStart": 186214.467,"actionIsCurrent": false,"actionTexture": 136224,"actionCooldownDuration": 6.618,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.324,"actionCharges": 0,"actionId": 8092,"actionShortcut": "E","timeSpan": [186221.085,inf],"actionUsable": true,"actionInRange": true,"actionType": "spell","serial": 1166,"actionEnable": 1}
    ,"2084": {"actionCooldownStart": 186214.467,"actionIsCurrent": false,"timeSpan": [186221.085,inf],"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.324,"actionCharges": 0,"actionId": 8092,"actionShortcut": "E","actionTexture": 136224,"actionCooldownDuration": 6.618,"actionInRange": true,"actionType": "spell","serial": 1166,"actionUsable": true}
    ,"2085": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"2088": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": {},"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "none","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionShortcut": "3","actionTexture": 1035040,"actionCooldownDuration": 0,"actionInRange": true,"actionType": "spell","serial": 1166,"actionUsable": true}
    ,"2087": {"actionCooldownStart": 0,"actionIsCurrent": false,"actionTexture": 1035040,"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "none","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionShortcut": "3","timeSpan": {},"actionUsable": true,"actionInRange": true,"actionType": "spell","serial": 1166,"actionCooldownDuration": 0}
    ,"2088": {"actionCooldownStart": 0,"actionIsCurrent": false,"timeSpan": {},"actionEnable": 1,"actionTarget": "target","actionResourceExtend": 0,"type": "none","options": {},"castTime": 0,"actionCharges": 0,"actionId": 205448,"actionShortcut": "3","actionTexture": 1035040,"actionCooldownDuration": 0,"actionInRange": true,"actionType": "spell","serial": 1166,"actionUsable": true}
    ,"2162": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"2181": {"type": "value","timeSpan": [0,inf],"value": "shadow","rate": 0,"serial": 1166,"origin": 0}
    ,"2182": {"type": "none","serial": 1166,"timeSpan": [0,inf]}
    ,"2183": {"type": "value","timeSpan": [0,inf],"value": "main","rate": 0,"serial": 1166,"origin": 0}
    ,"2184": {"actionCooldownStart": 186214.467,"actionIsCurrent": false,"timeSpan": [186221.085,inf],"actionCooldownDuration": 6.618,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.324,"actionCharges": 0,"actionId": 8092,"actionShortcut": "E","actionTexture": 136224,"actionEnable": 1,"actionInRange": true,"actionType": "spell","serial": 1166,"actionUsable": true}
    ,"2186": {"type": "none","serial": 1166,"timeSpan": {}}
    ,"2188": {"actionCooldownStart": 186196.509,"actionIsCurrent": true,"actionTexture": 135978,"actionCooldownDuration": 0,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.324,"actionCharges": 0,"actionId": 34914,"actionShortcut": "A","timeSpan": {},"actionUsable": true,"actionInRange": true,"actionType": "spell","serial": 1166,"actionEnable": 1}
    ,"2189": {"actionCooldownStart": 186214.467,"actionIsCurrent": false,"timeSpan": [186221.085,inf],"actionCooldownDuration": 6.618,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.324,"actionCharges": 0,"actionId": 8092,"actionShortcut": "E","actionTexture": 136224,"actionEnable": 1,"actionInRange": true,"actionType": "spell","serial": 1166,"actionUsable": true}
    }, "result": {"actionCooldownStart": 186214.467,"actionIsCurrent": false,"timeSpan": [186221.085,inf],"actionCooldownDuration": 6.618,"actionTarget": "target","actionResourceExtend": 0,"type": "action","options": {},"castTime": 1.324,"actionCharges": 0,"actionId": 8092,"actionShortcut": "E","actionTexture": 136224,"actionEnable": 1,"actionInRange": true,"actionType": "spell","serial": 1166,"actionUsable": true} }`;

test.skip("test icon tool", () => {
    const [result, iconDump, nodeList] = executeDump(dump);
    assertDefined(result);
    assertIs(result.type, "action");
    for (const [k, v] of Object.entries(iconDump.nodes)) {
        const node = nodeList[parseInt(k)];
        if (node.result.serial === iconDump.serial) {
            expect(node.result).toEqual(v);
        }
    }
    for (const [k, v] of Object.entries(iconDump.nodes)) {
        const node = nodeList[parseInt(k)];
        expect(node.result).toEqual(v);
    }
    expect(result).toEqual(iconDump.result);
});
