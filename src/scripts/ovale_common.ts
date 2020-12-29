import { OvaleScriptsClass } from "../engine/scripts";

export function registerCommon(OvaleScripts: OvaleScriptsClass) {
    const name = "ovale_common";
    const desc = "[9.0] Ovale: Common spell definitions";
    // THIS PART OF THIS FILE IS AUTOMATICALLY GENERATED
    let code = `
ItemInfo(171323 rppm=1 proc=17619)
ItemInfo(173069 cd=90 proc=333885)
ItemInfo(173078 cd=90 proc=333721)
ItemInfo(173087 cd=90 proc=329446)
ItemInfo(173096 cd=90 proc=328741)
ItemInfo(175728 rppm=2 proc=336606)
ItemInfo(175884 cd=60 proc=345228)
ItemInfo(175921 cd=60 proc=345228)
ItemInfo(175941 rppm=1 proc=17619)
ItemInfo(175942 rppm=1 proc=17619)
ItemInfo(175943 rppm=1 proc=17619)
ItemInfo(178298 rppm=1.5 proc=345229)
ItemInfo(178334 cd=90 proc=345231)
ItemInfo(178386 rppm=1.5 proc=345229)
ItemInfo(178447 cd=90 proc=345231)
ItemInfo(178708 proc=330747)
ItemInfo(178742 cd=1 rppm=4 proc=345547)
ItemInfo(178751 cd=120 proc=345548)
ItemInfo(178769 rppm=2 proc=345490)
ItemInfo(178770 rppm=9 proc=345595 cd=20)
ItemInfo(178771 proc=345465)
ItemInfo(178772 rppm=1.5 proc=345567)
ItemInfo(178783 cd=30 proc=345551)
ItemInfo(178808 rppm=5 proc=345697)
ItemInfo(178809 cd=120 proc=345807)
ItemInfo(178810 cd=90 proc=345695)
ItemInfo(178811 cd=90 proc=345877)
ItemInfo(178825 cd=75 proc=343401)
ItemInfo(178826 cd=90 proc=343397)
ItemInfo(178849 cd=150 proc=343387)
ItemInfo(178850 cd=120 proc=342433)
ItemInfo(178861 rppm=2 proc=342427)
ItemInfo(178862 cd=300 proc=342423)
ItemInfo(179331 cd=120 proc=329852)
ItemInfo(179342 cd=90 proc=329831)
ItemInfo(179350 cd=180 proc=348098)
ItemInfo(179356 cd=120 proc=329878)
ItemInfo(180116 cd=90 proc=345530)
ItemInfo(180117 cd=180 proc=345543)
ItemInfo(180118 rppm=3 proc=345533)
ItemInfo(180119 rppm=1 proc=345502)
ItemInfo(181333 cd=120 proc=336126)
ItemInfo(181334 rppm=2.5 proc=345981)
ItemInfo(181335 proc=336128)
ItemInfo(181357 cd=120 proc=336182)
ItemInfo(181358 rppm=3 proc=336219)
ItemInfo(181359 cd=150 proc=336465)
ItemInfo(181360 cd=90 proc=343538)
ItemInfo(181457 cd=120 proc=336588)
ItemInfo(181458 rppm=2 proc=336592)
ItemInfo(181459 rppm=2 proc=336586)
ItemInfo(181501 cd=90 proc=346746)
ItemInfo(181502 rppm=2 proc=326376)
ItemInfo(181503 rppm=1 proc=329756)
ItemInfo(181507 rppm=1.25 proc=336865)
ItemInfo(181816 proc=336135)
ItemInfo(184016 cd=90 proc=345113)
ItemInfo(184017 cd=120 proc=344400)
ItemInfo(184018 proc=344900)
ItemInfo(184019 cd=0.5 proc=345214)
ItemInfo(184020 cd=120 proc=344915)
ItemInfo(184021 cd=90 proc=345500)
ItemInfo(184022 proc=344221)
ItemInfo(184023 rppm=10 proc=344063)
ItemInfo(184024 cd=90 proc=345431)
ItemInfo(184025 cd=120 proc=344662)
ItemInfo(184026 rppm=10 proc=345357)
ItemInfo(184027 proc=344686)
ItemInfo(184028 proc=344806)
ItemInfo(184029 proc=344245 cd=60)
ItemInfo(184030 cd=90 proc=344732)
ItemInfo(184031 cd=60 proc=344231)
ItemInfo(184052 cd=120 proc=336126)
ItemInfo(184053 proc=336128)
ItemInfo(184054 proc=336135)
ItemInfo(184807 proc=347760)
ItemInfo(184839 rppm=1.5 proc=344117)
ItemInfo(184840 rppm=2 proc=348135)
ItemInfo(184841 proc=348136 cd=90)
ItemInfo(184842 proc=348139 cd=90)
`;
    // END

    OvaleScripts.RegisterScript(
        undefined,
        undefined,
        name,
        desc,
        code,
        "include"
    );
}
