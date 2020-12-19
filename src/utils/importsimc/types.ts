export interface ArmorLocation {
    id: number;
    v_1: number;
    v_2: number;
    v_3: number;
    v_4: number;
    v_5: number;
}

export interface Artifact {
    f1: string;
    id: number;
    f2: number;
    f3: number;
    unk_1: number;
    f5: number;
    id_spec: number;
    f7: unknown;
    f8: unknown;
    f9: number;
    f10: number;
}

export interface ArtifactPower {
    coord_1: number;
    coord_2: number;
    id: number;
    id_artifact: unknown;
    max_rank: unknown;
    index: number;
    type: unknown;
    unk: unknown;
    parent_id: number;
}

export interface ArtifactPowerLink {
    id: number;
    f1: number;
    f2: number;
}

export interface ArtifactPowerRank {
    id: number;
    index: unknown;
    id_spell: number;
    f5: number;
    value: number;
    parent_id: number;
}

export interface AzeriteEmpoweredItem {
    id: number;
    id_item: number;
    id_azerite_tier_unlock: number;
    id_power_set: number;
}

export interface AzeriteEssence {
    name: string;
    desc: string;
    id: number;
    category: number;
}

export interface AzeriteEssencePower {
    id: number;
    desc_alliance: string;
    desc_horde: string;
    id_essence: number;
    rank: unknown;
    id_spell_major_upgrade: number;
    id_spell_minor_upgrade: number;
    id_spell_major_base: number;
    id_spell_minor_base: number;
}

export interface AzeriteItem {
    id: number;
    id_item: number;
}

export interface AzeriteItemMilestonePower {
    id: number;
    req_level: number;
    id_power: number;
    power_type: number;
    essence_type: number;
}

export interface AzeritePower {
    id: number;
    id_spell: number;
    id_bonus: number;
    id_spec_set_member: number;
    unk_4: number;
}

export interface AzeritePowerSetMember {
    id: number;
    unk_28366: number;
    id_power: number;
    class_id: unknown;
    tier: unknown;
    index: unknown;
}

export interface AzeriteTierUnlock {
    id: number;
    item_creation_context: unknown;
    tier: unknown;
    azerite_level: unknown;
}

export interface ChatChannels {
    id: number;
    name: string;
    shortcut: string;
    flags: number;
    faction: unknown;
}

export interface ChrClasses {
    name_lang: string;
    filename: string;
    name_male_lang: string;
    name_female_lang: string;
    pet_name_token: string;
    desc: string;
    roles_lang: string;
    requirements_fail_lang: string;
    id: number;
    create_screen_file_data_id: number;
    select_screen_file_data_id: number;
    icon_file_data_id: number;
    low_res_screen_file_data_id: number;
    flags: number;
    spell_texture_blob_file_data_id: number;
    role_mask: number;
    armor_type_mask: number;
    unk_1: number;
    char_start_kit_spell_visual_kit_id_fallback: number;
    char_start_kit_9_0_1_34615_004_fallback: number;
    char_start_kit_spell_visual_kit_id_female_fallback: number;
    char_start_kit_9_0_1_34615_004_female_fallback: number;
    unk_2: number;
    char_start_kit_ground_spell_visual_kit_id_fallback: number;
    unk_3: number;
    unk_4: number;
    cinematic_sequence_id: number;
    default_spec: number;
    primary_stat_priority: unknown;
    display_power: unknown;
    ranged_attack_power_per_agility: unknown;
    attack_power_per_agility: unknown;
    attack_power_per_strength: unknown;
    spell_class_set: unknown;
    chat_color_r: unknown;
    chat_color_g: unknown;
    chat_color_b: unknown;
}

export interface ChrSpecialization {
    unk_4: string;
    name: string;
    desc: string;
    id: number;
    class_id: unknown;
    index: unknown;
    f9: unknown;
    spec_type: unknown;
    flags: number;
    id_icon: number;
    unk_6: unknown;
    unk_3: number;
    id_mastery_1: number;
    id_mastery_2: number;
}

export interface ContentTuning {
    id: number;
    flags: number;
    unk_3: number;
    min_level: number;
    max_level: number;
    unk_6: number;
    unk_7: number;
    unk_8: number;
}

export interface Covenant {
    name: string;
    desc: string;
    id: number;
    id_bounty_set: number;
    unk_1: number;
    unk_2: number;
    unk_3: number;
    unk_4: number;
}

export interface CurrencyCategory {
    id: number;
    name: string;
    flags: unknown;
    id_expansion: unknown;
}

export interface CurrencyContainer {
    id: number;
    name: string;
    description: string;
    min_amount: number;
    max_amount: number;
    id_container_icon: number;
    containter_quality: number;
    unk_1: number;
}

export interface CurrencyTypes {
    id: number;
    name: string;
    description: string;
    id_category: unknown;
    id_inventory_icon_file: number;
    spell_weight: number;
    spell_category: unknown;
    max_quantity: number;
    max_earnable_per_week: number;
    flags: number;
    quality: unknown;
    unk_1: number;
    unk_2: number;
    unk_3: number;
    unk_4: number;
    unk_5: number;
}

export interface Curve {
    id: number;
    type: unknown;
    flags: unknown;
}

export interface CurvePoint {
    id: number;
    val_1: number;
    val_2: number;
    level_1: number;
    level_2: number;
    id_distribution: number;
    curve_index: unknown;
}

export interface Difficulty {
    id: number;
    name: string;
    instance_type: unknown;
    index: unknown;
    unk_4: unknown;
    id_fallback_difficulty: unknown;
    min_players: unknown;
    max_players: unknown;
    flags: number;
    item_context: unknown;
    id_toggle_difficulty: unknown;
    unk_11: number;
    unk_12: number;
    unk_13: number;
}

export interface ExpectedStat {
    id: number;
    id_expansion: number;
    creature_health: number;
    player_health: number;
    creature_auto_attack_dps: number;
    creature_armor: number;
    player_mana: number;
    player_primary_stat: number;
    player_secondary_stat: number;
    armor_constant: number;
    creature_spell_damage: number;
}

export interface ExpectedStatMod {
    id: number;
    mod_creature_health: number;
    mod_player_health: number;
    mod_creature_auto_attack_dps: number;
    mod_creature_armor: number;
    mod_player_mana: number;
    mod_player_primary_stat: number;
    mod_player_secondary_stat: number;
    mod_armor_constant: number;
    mod_creature_spell_damage: number;
}

export interface GarrTalent {
    name: string;
    desc: string;
    id: number;
    id_garr_talent_tree: number;
    tier: unknown;
    ui_order: unknown;
    id_icon_file_data: number;
    unk_2: number;
    id_garr_ability: number;
    unk_3: unknown;
    unk_4: number;
    id_garr_talent_prereq: number;
    unk_6: number;
    unk_7: number;
    conduit_type: unknown;
}

export interface GarrTalentTree {
    title: string;
    id: number;
    id_garr_type: number;
    id_class: number;
    max_tiers: unknown;
    unk_0: unknown;
    flags: unknown;
    unk_1: number;
    garr_talent_tree_type: number;
    unk_2: number;
    feature_type: number;
    feature_rank: number;
}

export interface GarrTalentRank {
    id: number;
    rank: number;
    id_spell: number;
    unk_0: number;
    unk_1: number;
    unk_2: number;
    unk_3: number;
    unk_4: number;
    unk_5: number;
    unk_6: number;
    unk_7: number;
    unk_8: number;
    parent_id: number;
}

export interface GemProperties {
    id: number;
    id_enchant: number;
    color: number;
}

export interface GlyphProperties {
    id: number;
    id_spell: number;
    type: unknown;
    id_exclusive_category: unknown;
    id_icon: number;
}

export interface Item {
    id: number;
    classs: unknown;
    subclass: unknown;
    material: unknown;
    type_inv: unknown;
    sheath: unknown;
    unk_2: unknown;
    unk_1: number;
    unk_3: unknown;
    unk_4: number;
}

export interface ItemSparse {
    id: number;
    race_mask: undefined;
    desc: string;
    pad2: string;
    pad1: string;
    pad0: string;
    name: string;
    dmg_range: number;
    duration: number;
    item_damage_modifier: number;
    bag_family: number;
    ranged_mod_range: number;
    stat_socket_mul_1: number;
    stat_socket_mul_2: number;
    stat_socket_mul_3: number;
    stat_socket_mul_4: number;
    stat_socket_mul_5: number;
    stat_socket_mul_6: number;
    stat_socket_mul_7: number;
    stat_socket_mul_8: number;
    stat_socket_mul_9: number;
    stat_socket_mul_10: number;
    stat_alloc_1: number;
    stat_alloc_2: number;
    stat_alloc_3: number;
    stat_alloc_4: number;
    stat_alloc_5: number;
    stat_alloc_6: number;
    stat_alloc_7: number;
    stat_alloc_8: number;
    stat_alloc_9: number;
    stat_alloc_10: number;
    stackable: number;
    max_count: number;
    req_spell: number;
    sell_price: number;
    buy_price: number;
    unk_3: number;
    unk_2: number;
    unk_1: number;
    flags_1: number;
    flags_2: number;
    flags_3: number;
    flags_4: number;
    faction_conv_id: number;
    unk_901_1: number;
    unk_901_2: number;
    id_curve: number;
    id_name_desc: number;
    unk_l72_1: number;
    id_holiday: number;
    item_limit_category: number;
    gem_props: number;
    socket_bonus: number;
    totem_category: number;
    map: number;
    area_1: number;
    area_2: number;
    item_set: number;
    id_lock: number;
    start_quest: number;
    page_text: number;
    delay: number;
    req_rep_faction: number;
    req_skill_rank: number;
    req_skill: number;
    ilevel: number;
    class_mask: number;
    id_expansion: unknown;
    id_artifact: unknown;
    unk_6: unknown;
    unk_7: unknown;
    socket_color_1: unknown;
    socket_color_2: unknown;
    socket_color_3: unknown;
    sheath: unknown;
    material: unknown;
    page_mat: unknown;
    id_lang: unknown;
    bonding: unknown;
    damage_type: unknown;
    stat_type_1: unknown;
    stat_type_2: unknown;
    stat_type_3: unknown;
    stat_type_4: unknown;
    stat_type_5: unknown;
    stat_type_6: unknown;
    stat_type_7: unknown;
    stat_type_8: unknown;
    stat_type_9: unknown;
    stat_type_10: unknown;
    container_slots: unknown;
    req_rep_rank: unknown;
    unk_5: unknown;
    unk_4: unknown;
    req_level: unknown;
    inv_type: unknown;
    quality: unknown;
}

export interface ItemAppearance {
    id: number;
    f4: unknown;
    id_display_info: number;
    id_icon: number;
    f3: number;
    f5: number;
}

export interface ItemArmorQuality {
    id: number;
    v_1: number;
    v_2: number;
    v_3: number;
    v_4: number;
    v_5: number;
    v_6: number;
    v_7: number;
}

export interface ItemArmorShield {
    id: number;
    v_1: number;
    v_2: number;
    v_3: number;
    v_4: number;
    v_5: number;
    v_6: number;
    v_7: number;
    ilevel: number;
}

export interface ItemArmorTotal {
    id: number;
    ilevel: number;
    v_1: number;
    v_2: number;
    v_3: number;
    v_4: number;
}

export interface ItemBonus {
    id: number;
    val_1: number;
    val_2: number;
    val_3: number;
    val_4: number;
    id_node: number;
    type: unknown;
    index: unknown;
}

export interface ItemBonusTreeNode {
    id: number;
    index: unknown;
    id_child: number;
    id_node: number;
    unk: number;
}

export interface ItemChildEquipment {
    id: number;
    id_item: number;
    id_child: number;
    unk_2: unknown;
    parent_id: number;
}

export interface ItemDamageOneHand {
    id: number;
    ilevel: number;
    v_1: number;
    v_2: number;
    v_3: number;
    v_4: number;
    v_5: number;
    v_6: number;
    v_7: number;
}

export interface ItemDamageOneHandCaster {
    id: number;
    ilevel: number;
    v_1: number;
    v_2: number;
    v_3: number;
    v_4: number;
    v_5: number;
    v_6: number;
    v_7: number;
}

export interface ItemDamageTwoHand {
    id: number;
    ilevel: number;
    v_1: number;
    v_2: number;
    v_3: number;
    v_4: number;
    v_5: number;
    v_6: number;
    v_7: number;
}

export interface ItemDamageTwoHandCaster {
    id: number;
    ilevel: number;
    v_1: number;
    v_2: number;
    v_3: number;
    v_4: number;
    v_5: number;
    v_6: number;
    v_7: number;
}

export interface ItemEffect {
    id: number;
    index: unknown;
    trigger_type: unknown;
    cooldown_charges: number;
    cooldown_duration: number;
    cooldown_group_duration: number;
    cooldown_group: number;
    id_spell: number;
    id_specialization: number;
    parent_id: number;
}

export interface ItemExtendedCost {
    id: number;
    required_arena_rating: number;
    arena_bracket: unknown;
    flags: unknown;
    id_min_faction: unknown;
    min_reputation: unknown;
    required_achievement: unknown;
    id_item_1: number;
    id_item_2: number;
    id_item_3: number;
    id_item_4: number;
    id_item_5: number;
    item_count_1: number;
    item_count_2: number;
    item_count_3: number;
    item_count_4: number;
    item_count_5: number;
    id_currency_1: number;
    id_currency_2: number;
    id_currency_3: number;
    id_currency_4: number;
    id_currency_5: number;
    currency_count_1: number;
    currency_count_2: number;
    currency_count_3: number;
    currency_count_4: number;
    currency_count_5: number;
}

export interface ItemLimitCategory {
    id: number;
    name: string;
    quantity: unknown;
    flags: unknown;
}

export interface ItemModifiedAppearance {
    id: number;
    id_item: number;
    f3: unknown;
    id_appearance: number;
    f5: unknown;
    f6: unknown;
}

export interface ItemNameDescription {
    id: number;
    desc: string;
    flags: number;
}

export interface ItemNameSlotOverride {
    id: number;
    name: string;
    inventory_type_mask: number;
}

export interface ItemSet {
    id: number;
    name: string;
    unk_1: number;
    id_req_skill: number;
    val_req_skill: number;
    id_item_1: number;
    id_item_2: number;
    id_item_3: number;
    id_item_4: number;
    id_item_5: number;
    id_item_6: number;
    id_item_7: number;
    id_item_8: number;
    id_item_9: number;
    id_item_10: number;
    id_item_11: number;
    id_item_12: number;
    id_item_13: number;
    id_item_14: number;
    id_item_15: number;
    id_item_16: number;
    id_item_17: number;
}

export interface ItemSetSpell {
    id: number;
    id_spec: number;
    id_spell: number;
    n_req_items: unknown;
    parent_id: number;
}

export interface ItemSpec {
    id: number;
    min_level: unknown;
    max_level: unknown;
    item_type: unknown;
    primary_stat: unknown;
    secondary_stat: unknown;
    id_spec: number;
}

export interface ItemSpecOverride {
    id: number;
    id_spec: number;
}

export interface ItemClass {
    id: number;
    name: string;
    id_class: unknown;
    price_modifier: number;
    flags: unknown;
}

export interface ItemSubClass {
    id: number;
    display_name: string;
    verbose_name: string;
    id_class: unknown;
    id_sub_class: unknown;
    auction_house_sort_order: unknown;
    prerequisite_proficiency: unknown;
    flags: number;
    display_flags: unknown;
    weapon_swing_size: unknown;
    postrequisite_proficiency: unknown;
}

export interface ItemCurrencyCost {
    id: number;
    id_item: number;
}

export interface ItemXBonusTree {
    id: number;
    id_tree: number;
}

export interface JournalEncounter {
    id: number;
    name: string;
    desc: string;
    coord_1: number;
    coord_2: number;
    id_journal_instance: number;
    unk_1: number;
    order_index: number;
    first_section_id: number;
    ui_map_id: number;
    map_display_condition_id: number;
    flags: unknown;
    difficulty_mask: unknown;
}

export interface JournalEncounterCreature {
    name: string;
    desc: string;
    id: number;
    id_journal_encounter: number;
    id_creature_display_info: number;
    id_data_file: number;
    order_index: number;
    id_ui_model_scene: number;
    parent_id: number;
}

export interface JournalEncounterItem {
    id: number;
    id_encounter: number;
    id_item: number;
    flags_2: unknown;
    unk_1: unknown;
    flags_1: unknown;
    parent_id: number;
}

export interface JournalEncounterSection {
    id: number;
    title: string;
    body_text: string;
    id_journal_encounter: number;
    order_index: unknown;
    id_parent_section: number;
    id_first_child_section: number;
    id_next_sibling_section: number;
    type: unknown;
    id_icon_creature_display_info: number;
    id_ui_model_scene: number;
    id_spell: number;
    id_icon_file_data: number;
    flags: number;
    icon_flags: number;
    difficulty_mask: unknown;
}

export interface JournalEncounterXDifficulty {
    id: number;
    id_difficulty: unknown;
}

export interface JournalInstance {
    name: string;
    desc: string;
    id: number;
    map: number;
    id_background_file_data: number;
    id_button_file_data: number;
    id_button_small_file_data: number;
    id_lore_file_data: number;
    order_index: unknown;
    flags: unknown;
    area_id: number;
}

export interface JournalItemXDifficulty {
    id: number;
    id_difficulty: unknown;
    parent_id: number;
}

export interface JournalTier {
    id: number;
    name: string;
    player_condition_id: number;
}

export interface JournalTierXInstance {
    id: number;
    id_journal_tier: number;
    id_journal_instance: number;
}

export interface ManifestInterfaceData {
    id: number;
    unk: string;
    name: string;
}

export interface Map {
    id: number;
    directory: string;
    name: string;
    name_901: string;
    description_1: string;
    description_2: string;
    pvp_short_description: string;
    pvp_long_description: string;
    corpse_1: number;
    corpse_2: number;
    map_type: unknown;
    instance_type: unknown;
    id_expansion: unknown;
    id_area_table: number;
    id_loading_screen: number;
    time_of_day_override: number;
    id_parent_map: number;
    id_cosmetic_parent_map: number;
    time_offset: unknown;
    minimap_icon_scale: number;
    id_corpse_map: number;
    max_players: unknown;
    id_wind_settings: number;
    id_zmp_file_data: number;
    unk_1: number;
    flags_1: number;
    flags_2: number;
}

export interface MinorTalent {
    id: number;
    id_spell: number;
    index: number;
}

export interface RandPropPoints {
    id: number;
    damage_replace_stat: number;
    damage_secondary: number;
    epic_points_1: number;
    epic_points_2: number;
    epic_points_3: number;
    epic_points_4: number;
    epic_points_5: number;
    rare_points_1: number;
    rare_points_2: number;
    rare_points_3: number;
    rare_points_4: number;
    rare_points_5: number;
    uncm_points_1: number;
    uncm_points_2: number;
    uncm_points_3: number;
    uncm_points_4: number;
    uncm_points_5: number;
}

export interface RelicTalent {
    id: number;
    row: number;
    id_power: number;
    power_index: unknown;
    unk_3: number;
    unk_4: number;
}

export interface RewardPack {
    id: number;
    id_char_title: number;
    money: number;
    artifact_xp_difficulty: unknown;
    artifact_xp_multiplier: number;
    id_artifact_xp_category: unknown;
    id_treasure_picker: number;
}

export interface RewardPackXCurrencyType {
    id: number;
    id_currency_type: number;
    quantity: number;
}

export interface RewardPackXItem {
    id: number;
    id_item: number;
    quantity: number;
}

export interface RuneforgeLegendaryAbility {
    name: string;
    id: number;
    id_spec_set: number;
    mask_inv_type: number;
    id_spell: number;
    id_bonus: number;
    id_player_cond: number;
    unk_8: number;
    id_item: number;
}

export interface SkillLine {
    name: string;
    unk_2: string;
    unk_3: string;
    unk_4: string;
    unk_5: string;
    id: number;
    unk_8: unknown;
    unk_9: number;
    unk_10: unknown;
    unk_11: number;
    unk_12: number;
    unk_7: number;
    unk_13: number;
}

export interface SkillLineAbility {
    mask_race: undefined;
    id: number;
    id_skill: number;
    id_spell: number;
    req_skill_level: number;
    mask_class: number;
    id_replace: number;
    unk_13: unknown;
    max_learn_skill: number;
    unk_7: number;
    unk_14: unknown;
    reward_skill_points: unknown;
    index: number;
    id_filter: number;
    unk_15: number;
    parent_id: number;
}

export interface Soulbind {
    name: string;
    id: number;
    id_covenant: number;
    id_garr_talent_tree: number;
    id_creature: number;
    id_garr_follower: number;
    unk_0: number;
}

export interface SoulbindConduit {
    id: number;
    type: number;
    id_covenant: number;
    id_spec_set: number;
}

export interface SoulbindConduitItem {
    id: number;
    id_item: number;
    id_soulbind: number;
}

export interface SoulbindConduitRank {
    id: number;
    rank: number;
    id_spell: number;
    spell_mod: number;
    parent_id: number;
}

export interface SpecializationSpells {
    unk_1: string;
    id: number;
    spec_id: number;
    spell_id: number;
    replace_spell_id: number;
    unk_2: unknown;
    parent_id: number;
}

export interface SpecSetMember {
    id: number;
    id_spec: number;
}

export interface Spell {
    id: number;
    rank: string;
    desc: string;
    tt: string;
}

export interface SpellAuraOptions {
    id: number;
    unk_1: unknown;
    stack_amount: number;
    internal_cooldown: number;
    proc_chance: unknown;
    proc_charges: number;
    id_ppm: number;
    proc_flags_1: number;
    proc_flags_2: number;
    parent_id: number;
}

export interface SpellCastTimes {
    id: number;
    cast_time: number;
    min_cast_time: number;
}

export interface SpellCastingRequirements {
    id: number;
    id_spell: number;
    facing_flags: unknown;
    unk_2: number;
    unk_6: unknown;
    unk_3: number;
    unk_8: unknown;
    unk_4: number;
}

export interface SpellCategories {
    id: number;
    unk_1: unknown;
    id_cooldown_category: number;
    dmg_class: unknown;
    dispel: unknown;
    id_mechanic: unknown;
    type_prevention: unknown;
    start_recovery_category: number;
    id_charge_category: number;
    parent_id: number;
}

export interface SpellCategory {
    id: number;
    category: string;
    unk_1: unknown;
    unk_2: unknown;
    charges: unknown;
    charge_cooldown: number;
    unk_3: number;
}

export interface SpellClassOptions {
    id: number;
    id_spell: number;
    modal_next_spell: number;
    family: unknown;
    flags_1: number;
    flags_2: number;
    flags_3: number;
    flags_4: number;
}

export interface SpellCooldowns {
    id: number;
    unk_1: unknown;
    category_cooldown: number;
    cooldown: number;
    gcd_cooldown: number;
    parent_id: number;
}

export interface SpellDescriptionVariables {
    id: number;
    desc: string;
}

export interface SpellDuration {
    id: number;
    duration_1: number;
    duration_2: number;
}

export interface SpellEffect {
    id: number;
    sub_type: number;
    unk_3: number;
    index: number;
    type: number;
    val_mul: number;
    unk_2: number;
    amplitude: number;
    sp_coefficient: number;
    dmg_multiplier: number;
    chain_target: number;
    item_type: number;
    id_mechanic: number;
    points_per_combo_points: number;
    unk_1: number;
    real_ppl: number;
    trigger_spell: number;
    ap_coefficient: number;
    pvp_coefficient: number;
    coefficient: number;
    delta: number;
    bonus: number;
    unk_24: number;
    base_value: number;
    misc_value_1: number;
    misc_value_2: number;
    id_radius_1: number;
    id_radius_2: number;
    class_mask_1: number;
    class_mask_2: number;
    class_mask_3: number;
    class_mask_4: number;
    implicit_target_1: number;
    implicit_target_2: number;
    parent_id: number;
}

export interface SpellEffectAutoDescription {
    id: number;
    desc: string;
    tt: string;
    unk_3: number;
    unk_4: number;
    unk_5: unknown;
    unk_6: unknown;
    school: unknown;
    type: number;
    sub_type: number;
}

export interface SpellEquippedItems {
    id: number;
    id_spell: number;
    item_class: unknown;
    mask_inv_type: number;
    mask_sub_class: number;
}

export interface SpellItemEnchantment {
    desc: string;
    desc_2: string;
    id: number;
    id_property_1: number;
    id_property_2: number;
    id_property_3: number;
    coeff_1: number;
    coeff_2: number;
    coeff_3: number;
    unk_20: number;
    unk_901_1: number;
    unk_901_2: number;
    unk_5: number;
    unk_6: number;
    amount_1: number;
    amount_2: number;
    amount_3: number;
    id_aura: number;
    slot: number;
    req_skill: number;
    req_skill_value: number;
    min_scaling_level: number;
    charges: unknown;
    type_1: unknown;
    type_2: unknown;
    type_3: unknown;
    scaling_type: unknown;
    unk_19: unknown;
    unk_15: unknown;
    req_player_level: unknown;
    max_scaling_level: unknown;
}

export interface SpellLabel {
    id: number;
    label: number;
    parent_id: number;
}

export interface SpellLevels {
    id: number;
    unk_1: unknown;
    max_level: number;
    req_max_level: unknown;
    base_level: number;
    spell_level: number;
    parent_id: number;
}

export interface SpellMechanic {
    id: number;
    mechanic: number;
}

export interface SpellName {
    id: number;
    name: string;
}

export interface SpellMisc {
    id: number;
    flags_1: number;
    flags_2: number;
    flags_3: number;
    flags_4: number;
    flags_5: number;
    flags_6: number;
    flags_7: number;
    flags_8: number;
    flags_9: number;
    flags_10: number;
    flags_11: number;
    flags_12: number;
    flags_13: number;
    flags_14: number;
    flags_15: number;
    unk_2: unknown;
    id_cast_time: number;
    id_duration: number;
    id_range: number;
    school: unknown;
    proj_speed: number;
    unk_3: number;
    unk_1: number;
    id_icon: number;
    id_active_icon: number;
    unk_4: number;
    unk_901_1: number;
    unk_901_2: number;
    unk_901_3: number;
    parent_id: number;
}

export interface SpellPower {
    id: number;
    unk_5: unknown;
    cost: number;
    unk_6: number;
    cost_per_second: number;
    unk_4: number;
    unk_3: number;
    pct_cost: number;
    pct_cost_max: number;
    pct_cost_per_second: number;
    type_power: unknown;
    aura_id: number;
    cost_max: number;
    parent_id: number;
}

export interface SpellProcsPerMinute {
    id: number;
    ppm: number;
    flags: unknown;
}

export interface SpellProcsPerMinuteMod {
    id: number;
    unk_1: unknown;
    id_chr_spec: number;
    coefficient: number;
    parent_id: number;
}

export interface SpellRadius {
    id: number;
    radius_1: number;
    unk_1: number;
    radius_2: number;
    radius_3: number;
}

export interface SpellRange {
    id: number;
    display_name: string;
    display_name_short: string;
    flag: unknown;
    min_range_1: number;
    min_range_2: number;
    max_range_1: number;
    max_range_2: number;
}

export interface SpellScaling {
    id: number;
    id_spell: number;
    id_class: number;
    min_scaling_level: number;
    max_scaling_level: number;
    max_scaling_ilevel: number;
}

export interface SpellShapeshift {
    id: number;
    id_spell: number;
    unk: unknown;
    flags_not_1: number;
    flags_not_2: number;
    flags_1: number;
    flags_2: number;
}

export interface SpellTargetRestrictions {
    id: number;
    unk_5: unknown;
    cone: number;
    max_affected_targets: unknown;
    max_target_level: number;
    unk_4: number;
    flags: number;
    width: number;
    parent_id: number;
}

export interface SpellXDescriptionVariables {
    id: number;
    id_spell: number;
    id_desc_var: number;
}

export interface TactKey {
    id: number;
    key_1: unknown;
    key_2: unknown;
    key_3: unknown;
    key_4: unknown;
    key_5: unknown;
    key_6: unknown;
    key_7: unknown;
    key_8: unknown;
    key_9: unknown;
    key_10: unknown;
    key_11: unknown;
    key_12: unknown;
    key_13: unknown;
    key_14: unknown;
    key_15: unknown;
    key_16: unknown;
}

export interface TactKeyLookup {
    id: number;
    key_name_1: unknown;
    key_name_2: unknown;
    key_name_3: unknown;
    key_name_4: unknown;
    key_name_5: unknown;
    key_name_6: unknown;
    key_name_7: unknown;
    key_name_8: unknown;
}

export interface Talent {
    id: number;
    desc: string;
    row: unknown;
    pet: unknown;
    col: unknown;
    class_id: unknown;
    spec_id: number;
    id_spell: number;
    id_replace: number;
    unk_1: unknown;
    unk_2: unknown;
}

export interface UICovenantAbility {
    id: number;
    id_covenant_preview: number;
    id_spell: number;
    ability_type: unknown;
    unk: number;
}

export interface UICovenantPreview {
    unk_0: string;
    unk_1: string;
    id: number;
    id_covenant: number;
    id_ui_map: number;
    crest: number;
    id_transmog_set_0: number;
    texture_kit: number;
    id_mount: number;
    id_player_choice_response: number;
    unk_8: number;
    unk_9: number;
    id_transmog_set_1: number;
    id_transmog_set_2: number;
    id_transmog_set_3: number;
    unk_2: number;
}
