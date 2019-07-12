import test from "ava";
import { SpellData, SpellEffectData, EffectSubtype, EffectType } from "../../utils/importspells";
import { parseDescription } from "../../utils/spellstringparser";

function createFakeSpell(options: {[k in keyof SpellData]?: SpellData[k]}): SpellData {
    return {
        id: options.id || 18,
        name: options.name || "Fakename",
        attributes: [],
        c_scaling: 0,
        c_scaling_level: 0,
        cast_div: 0,
        cast_max: 0,
        cast_min: 0,
        category: 0,
        category_cooldown: 0,
        charge_cooldown: 0,
        charges: 0,
        class_flags: [],
        class_flags_family: 0,
        class_mask: 0,
        cooldown: 0,
        desc: options.desc || "",
        desc_vars: "",
        duration: options.duration || 0,
        equipped_class: 0,
        equipped_invtype_mask: 0,
        equipped_subclass_mask: 0,
        gcd: 0,
        hotfix: 0,
        internal_cooldown: 0,
        max_level: 0,
        max_range: 0,
        max_scaling_level: 0,
        max_stack: 0,
        mechanic: 0,
        min_range: 0,
        power_id: 0,
        prj_speed: 0,
        proc_chance: 0,
        proc_charges: 0,
        proc_flags: 0,
        race_mask: 0,
        rank_str: "",
        replace_spell_id: 0,
        req_max_level: 0,
        scaling_type: 0,
        rppm: 0,
        school: 0,
        spell_level: 0,
        stance_mask: 0,
        tooltip: "",
        essence_id: 0,
        dmg_class: 0
    };
}

function createFakeSpellEffect(options: {[key in keyof SpellEffectData]?: SpellEffectData[key]}): SpellEffectData {
    return {
        amplitude: options.amplitude || 0,
        ap_coeff: options.ap_coeff || 0,
        base_value: options.base_value || 0,
        chain_target: options.base_value ||0,
        class_flags: options.class_flags || [],
        hotfix: options.hotfix || 0,
        id: options.id ||10,
        index: options.index || 0,
        m_avg: options.m_avg || 0,
        m_chain: options.m_chain || 0,
        m_delta: options.m_delta ||0,
        m_unk: options.m_unk || 0,
        m_value: options.m_value ||0,
        mechanic: options.mechanic || 0,
        misc_value: options.misc_value || 0,
        misc_value_2: options.misc_value_2 ||0,
        pp_combo_points: options.pp_combo_points ||0,
        radius: options.radius ||0,
        radius_max: options.radius_max || 0,
        real_ppl: options.real_ppl ||0,
        sp_coeff: options.sp_coeff || 0,
        spell_id: options.spell_id || 0,
        subtype: options.subtype ||EffectSubtype.A_119,
        targeting_1: options.targeting_1 ||0,
        targeting_2: options.targeting_2 || 0,
        trigger_spell_id: options.trigger_spell_id||0,
        type: options.type || EffectType.E_112
    }
}

test("parseDescription with no placeholder", t => {
    t.is(parseDescription("Stunned.", createFakeSpell({}), new Map<number, SpellData>()), "Stunned.");
});

test("parseDescription with duration in same spell", t => {
    const spell = createFakeSpell({ duration: 18000 });
    t.is(parseDescription("Stuns target for $d.", spell, new Map<number, SpellData>()), "Stuns target for 18 seconds.");
})

test("parseDescription with reference to a spell effect", t => {
    const spell = createFakeSpell({});
    spell.spellEffects = [createFakeSpellEffect({sp_coeff: 0.3})];

    t.is(parseDescription("Stuns target for $s1.", spell, new Map<number, SpellData>()), "Stuns target for (30% of Spell Power).");
})

test("parseDescription with reference to another spell", t => {
    const spell = createFakeSpell({ });
    const otherSpell = createFakeSpell({ duration: 18000, id: 4998 });
    const spells = new Map<number, SpellData>();
    spells.set(otherSpell.id, otherSpell);
    t.is(parseDescription("Stuns target for $4998d.", spell, spells), "Stuns target for 18 seconds.");
})

test("parseDescription where description is the description of another spell", t => {
    const spell = createFakeSpell({ });
    const otherSpell = createFakeSpell({ duration: 18000, id: 4998, desc: "Stuns target for $d." });
    const spells = new Map<number, SpellData>();
    spells.set(otherSpell.id, otherSpell);
    t.is(parseDescription("$@spelldesc4998", spell, spells), "Stuns target for 18 seconds.");
})