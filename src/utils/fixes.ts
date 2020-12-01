import { getSpellData } from "./importspells";

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
    addSpellList("eclipse_any", "eclipse_lunar", "eclipse_solar");
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

    // Fix identifiers
    function fixIdentifier(identifier: string, spellId: number) {
        const spell = spellData.spellDataById.get(spellId);
        if (spell) {
            delete spellData.identifiers[spell.identifier];
            spell.identifier = identifier;
            spellData.identifiers[identifier] = spellId;
        }
    }
    fixIdentifier("shining_light_free_buff", 327510);
    fixIdentifier("sun_kings_blessing_ready_buff", 333315);
    fixIdentifier("clearcasting_channel_buff", 277726);
    fixIdentifier("balance_of_all_things_arcane_buff", 339946);
    fixIdentifier("balance_of_all_things_nature_buff", 339943);
    fixIdentifier("adaptive_swarm_damage", 325733);
    fixIdentifier("adaptive_swarm_heal", 325748);
    fixIdentifier("kindred_empowerment_energize", 327139);

    // TODO add _cat/_bear using required stance
    fixIdentifier("wild_charge_bear", 16979);
    fixIdentifier("wild_charge_cat", 49376);
    fixIdentifier("thrash_cat", 106830);
    fixIdentifier("swipe_cat", 106785);
    fixIdentifier("moonfire_cat", 155625);
    fixIdentifier("berserk_cat", 106951);
    fixIdentifier("berserk_bear", 50334);

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
