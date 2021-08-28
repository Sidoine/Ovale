import { EffectType, getSpellData } from "./importspells";

export function getFixes(spellData: ReturnType<typeof getSpellData>) {
    const customIdentifiers = new Map<string, number>();

    // Pets and demons
    customIdentifiers.set("wild_imp_inner_demons", 143622);
    customIdentifiers.set("vilefiend", 135816);
    customIdentifiers.set("demonic_tyrant", 135002);
    customIdentifiers.set("wild_imp", 55659);
    customIdentifiers.set("dreadstalker", 98035);
    customIdentifiers.set("darkglare", 103673);
    customIdentifiers.set("infernal", 89);
    customIdentifiers.set("felguard", 17252);

    // Enchantments
    customIdentifiers.set("fallen_crusader_enchant", 3368);
    customIdentifiers.set("razorice_enchant", 3370);

    // Spells missing in the database
    customIdentifiers.set("hex", 51514);
    customIdentifiers.set("lunar_empowerment", 292664);
    customIdentifiers.set("solar_empowerment", 292663);
    customIdentifiers.set("sudden_death_buff", 280776);

    // Invisible auras
    customIdentifiers.set("garrote_exsanguinated", -703);
    customIdentifiers.set("rupture_exsanguinated", -1943);
    customIdentifiers.set("bt_swipe_buff", -106785);
    customIdentifiers.set("bt_thrash_buff", -106830);
    customIdentifiers.set("bt_rake_buff", -1822);
    customIdentifiers.set("bt_shred_buff", -5221);
    customIdentifiers.set("bt_brutal_slash_buff", -202028);
    customIdentifiers.set("bt_moonfire_buff", -155625);

    // Custom spell lists
    function addSpellList(name: string, ...identifiers: string[]) {
        spellData.spellLists.set(
            name,
            identifiers.map((identifier) => ({
                identifier,
                id:
                    spellData.identifiers[identifier] ??
                    customIdentifiers.get(identifier) ??
                    0,
            }))
        );
    }
    addSpellList(
        "exsanguinated",
        "garrote_exsanguinated",
        "rupture_exsanguinated"
    );
    addSpellList(
        "starsurge_empowerment_buff",
        "lunar_empowerment",
        "solar_empowerment"
    );
    addSpellList(
        "incarnation",
        "incarnation_tree_of_life",
        "incarnation_king_of_the_jungle",
        "incarnation_guardian_of_ursoc",
        "incarnation_chosen_of_elune"
    );
    addSpellList(
        "blessing_of_the_seasons",
        "blessing_of_spring",
        "blessing_of_summer",
        "blessing_of_autumn",
        "blessing_of_winter"
    );
    addSpellList(
        "bt_buffs",
        "bt_swipe_buff",
        "bt_thrash_buff",
        "bt_shred_buff",
        "bt_brutal_slash_buff",
        "bt_moonfire_buff",
        "bt_rake_buff"
    );
    addSpellList(
        "bs_inc_buff",
        "incarnation_king_of_the_jungle",
        "incarnation_guardian_of_ursoc",
        "berserk_bear",
        "berserk_cat"
    );
    addSpellList(
        "gladiators_badge_item",
        "dread_gladiators_badge_item",
        "sinister_gladiators_badge_item",
        "notorious_gladiators_badge_item",
        "corrupted_gladiators_badge_item"
    );

    // Fix identifiers
    function fixIdentifier(identifier: string, spellId: number) {
        const spell = spellData.spellDataById.get(spellId);
        if (spell) {
            if (spell.identifier !== identifier) {
                delete spellData.identifiers[spell.identifier];
                spell.identifier = identifier;
                spellData.identifiers[identifier] = spellId;
            } else {
                console.log(`Info: ${spell.identifier} fix not necessary`);
            }
        }
    }

    function fixAddAura(identifier: string, buffIdentifier: string) {
        const spellId = spellData.identifiers[identifier];
        const spell = spellData.spellDataById.get(spellId);
        const buffId = spellData.identifiers[buffIdentifier];
        const buff = spellData.spellDataById.get(buffId);
        if (spell && buff) {
            spell.spellEffects ??= [];
            spell.spellEffects.push({
                type: EffectType.E_APPLY_AURA,
                trigger_spell_id: buffId,
                amplitude: 0,
                ap_coeff: 0,
                base_value: 0,
                chain_target: 0,
                class_flags: [],
                id: 0,
                index: 0,
                m_chain: 0,
                m_coeff: 0,
                m_delta: 0,
                m_unk: 0,
                m_value: 0,
                mechanic: 0,
                misc_value: 0,
                misc_value_2: 0,
                pp_combo_points: 0,
                pvp_coeff: 0,
                radius: 0,
                radius_max: 0,
                real_ppl: 0,
                sp_coeff: 0,
                spell_id: spellId,
                subtype: 0,
                targeting_1: 0,
                targeting_2: 0,
                scaling_type: 0,
            });
        }
    }

    fixIdentifier("adaptive_swarm_damage", 325733);
    fixIdentifier("adaptive_swarm_heal", 325748);
    fixIdentifier("balance_of_all_things_arcane_buff", 339946);
    fixIdentifier("balance_of_all_things_nature_buff", 339943);
    fixIdentifier("clearcasting_channel_buff", 277726);
    fixIdentifier("condemn_fury", 317485);
    fixIdentifier("corruption_affliction_debuff", 146739);
    fixIdentifier("devastator_passive", 236279);
    fixIdentifier("festering_wound_unholy_debuff", 194310);
    fixIdentifier("frenzy_pet_buff", 272790);
    fixIdentifier("kindred_empowerment_energize", 327139);
    fixIdentifier("radiant_spark_vulnerability_debuff", 307454);
    fixIdentifier("serrated_bone_spike_debuff", 324073);
    fixIdentifier("serrated_bone_spike", 328547);
    fixIdentifier("shining_light_free_buff", 327510);
    fixIdentifier("steady_focus", 193533);
    fixIdentifier("sun_kings_blessing_ready_buff", 333315);
    fixIdentifier("symbols_of_death_autocrit", 227151);
    fixIdentifier("unstable_affliction_silence_debuff", 196364);
    fixIdentifier("weapons_of_order_ww", 311054);

    // Blood fury
    fixIdentifier("blood_fury_ap", 20572);
    fixIdentifier("blood_fury_ap_int", 33697);
    fixIdentifier("blood_fury_int", 33702);

    // TODO add _cat/_bear using required stance
    fixIdentifier("berserk_bear", 50334);
    fixIdentifier("berserk_cat", 106951);
    fixIdentifier("moonfire_cat", 155625);
    fixIdentifier("swipe_cat", 106785);
    fixIdentifier("thrash_cat", 106830);
    fixIdentifier("wild_charge_bear", 16979);
    fixIdentifier("wild_charge_cat", 49376);

    fixAddAura("serrated_bone_spike", "serrated_bone_spike_debuff");
    fixAddAura("sunfire", "sunfire_debuff");

    addSpellList("wild_charge", "wild_charge_bear", "wild_charge_cat");
    addSpellList(
        "adaptive_swarm",
        "adaptive_swarm_damage",
        "adaptive_swarm_heal"
    );
    addSpellList("berserk", "berserk_cat", "berserk_bear");

    const customIdentifierById = new Map<
        number,
        { id: number; identifier: string }
    >();

    for (const [key, value] of customIdentifiers.entries()) {
        spellData.identifiers[key] = value;
        customIdentifierById.set(value, { identifier: key, id: value });
    }

    return { customIdentifierById, customIdentifiers };
}
