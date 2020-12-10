import { OvaleScriptsClass } from "../engine/scripts";

export function registerPriestSpells(OvaleScripts: OvaleScriptsClass) {
    const name = "ovale_priest_spells";
    const desc = "[9.0] Ovale: Priest spells";
    // THIS PART OF THIS FILE IS AUTOMATICALLY GENERATED
    // ANY CHANGES MADE BELOW THIS POINT WILL BE LOST
    let code = `Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
Define(arcane_torrent 25046)
# Remove s1 beneficial effect from all enemies within A1 yards and restore m2 Energy.
  SpellInfo(arcane_torrent cd=120 gcd=1 energy=-15)
Define(ascended_blast 325283)
# Blasts the enemy with pure Anima, causing (179 of Spell Power) Arcane damage and healing a nearby ally for s2 of the damage done.rnrnGrants s3 lstack:stacks; of Boon of the Ascended.
  SpellInfo(ascended_blast cd=3 gcd=1)
Define(ascended_nova 325020)
# Release a powerful burst of anima, dealing up to (74 of Spell Power) Arcane damage, based on the number of enemies, and (24 of Spell Power) healing to up to 325041s2 allies within A1 yds.rnrnGrants s3 lstack:stacks; of Boon of the Ascended for each target damaged.
  SpellInfo(ascended_nova gcd=1)
Define(bag_of_tricks 312411)
# Pull your chosen trick from the bag and use it on target enemy or ally. Enemies take <damage> damage, while allies are healed for <healing>. 
  SpellInfo(bag_of_tricks cd=90)
Define(berserking 59621)
# Permanently enchant a melee weapon to sometimes increase your attack power by 59620s1, but at the cost of reduced armor. Cannot be applied to items higher than level ecix
  SpellInfo(berserking gcd=0 offgcd=1)
Define(blood_fury 20572)
# Increases your attack power by s1 for 15 seconds.
  SpellInfo(blood_fury cd=120 duration=15 gcd=0 offgcd=1)
  # Attack power increased by w1.
  SpellAddBuff(blood_fury blood_fury add=1)
Define(blood_of_the_enemy 297969)
# Infuse your Heart of Azeroth with Blood of the Enemy.
  SpellInfo(blood_of_the_enemy)
Define(bloodlust 2825)
# Increases haste by (25 of Spell Power) for all party and raid members for 40 seconds.rnrnAllies receiving this effect will become Sated and unable to benefit from Bloodlust or Time Warp again for 600 seconds.
  SpellInfo(bloodlust cd=300 duration=40 gcd=0 offgcd=1)
  # Haste increased by w1.
  SpellAddBuff(bloodlust bloodlust add=1)
Define(concentrated_flame 295368)
# Blast your target with a ball of concentrated flame, dealing 295365s2*(1+@versadmg) Fire damage to an enemy or healing an ally for 295365s2*(1+@versadmg)?a295377[, then burn the target for an additional 295377m1 of the damage or healing done over 6 seconds][]. rnrnEach cast of Concentrated Flame deals s3 increased damage or healing. This bonus resets after every third cast.
  SpellInfo(concentrated_flame duration=6 gcd=0 offgcd=1 tick=2)
  # Suffering w1 damage every t1 sec.
  SpellAddTargetDebuff(concentrated_flame concentrated_flame add=1)
Define(damnation 341374)
# Instantly afflicts the target with Shadow Word: Pain, Vampiric Touch and Devouring Plague.
  SpellInfo(damnation cd=45)
  SpellRequire(damnation unusable set=1 enabled=(not hastalent(damnation_talent)))
Define(dark_thought 341207)
# For each damage over time effects on the target, your Mind Flay and Mind Sear have a m1 chance to trigger a Dark Thought. rnrnDark ThoughtrnIncreases the number of charges of Mind Blast by 1, Mind Blast has no cooldown and can be cast instantly, and can be cast while channelling Mind Flay or Mind Sear.
  SpellInfo(dark_thought duration=10 max_stacks=1 gcd=0 offgcd=1)
  # Maximum number of charges of Mind Blast increased by w1.rnrnMind Blast no longer has a  cooldown, can be cast instantly, and while channelling Mind Flay or Mind Sear.
  SpellAddBuff(dark_thought dark_thought add=1)
Define(devouring_plague 335467)
# Afflicts the target with a disease that instantly causes (65 of Spell Power) Shadow damage plus an additional o2 Shadow damage over 6 seconds. Heals you for e2*100 of damage dealt.rnrnIf this effect is reapplied, any remaining damage will be added to the new Devouring Plague.
  SpellInfo(devouring_plague insanity=5000 duration=6 tick=3)
  # Suffering s2 damage every t2 sec.
  SpellAddTargetDebuff(devouring_plague devouring_plague add=1)
Define(divine_star 110744)
# Throw a Divine Star forward 24 yds, healing allies in its path for (70 of Spell Power) and dealing (40 of Spell Power) Holy damage to enemies. After reaching its destination, the Divine Star returns to you, healing allies and damaging enemies in its path again.
  SpellInfo(divine_star cd=15 duration=15)
  SpellRequire(divine_star unusable set=1 enabled=(not hastalent(divine_star_talent)))
Define(fae_guardians 327661)
# Call forth three faerie guardians to attend your targets for 20 seconds.rnrn@spellname342132: Direct attacks against the target restore 327703s1/100.1 Mana or 327703s2/100 Insanity. Follows your Shadow Word: Pain.rnrn@spellname327694: Reduces damage taken by 327694s1. Follows your Power Word: Shield.rnrn@spellname327710: Increases the cooldown recovery rate of a major ability by 327710s1. Follows your ?c2[Flash Heal][Shadow Mend].
  SpellInfo(fae_guardians cd=90 duration=20 max_stacks=1)
  # Commanding faerie guardians.
  SpellAddBuff(fae_guardians fae_guardians add=1)
Define(fireblood 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. ?s195710[This effect shares a 30 sec cooldown with other similar effects.][]
  SpellInfo(fireblood cd=120 gcd=0 offgcd=1)
Define(focused_azerite_beam 295258)
# Focus excess Azerite energy into the Heart of Azeroth, then expel that energy outward, dealing m1*10 Fire damage to all enemies in front of you over 3 seconds.?a295263[ Castable while moving.][]
  SpellInfo(focused_azerite_beam cd=90 duration=3 channel=3 tick=0.33)
Define(guardian_of_azeroth 295840)
# Call upon Azeroth to summon a Guardian of Azeroth for 30 seconds who impales your target with spikes of Azerite every s1/10.1 sec that deal 295834m1*(1+@versadmg) Fire damage.?a295841[ Every 303347t1 sec, the Guardian launches a volley of Azerite Spikes at its target, dealing 295841s1 Fire damage to all nearby enemies.][]?a295843[rnrnEach time the Guardian of Azeroth casts a spell, you gain 295855s1 Haste, stacking up to 295855u times. This effect ends when the Guardian of Azeroth despawns.][]rn
  SpellInfo(guardian_of_azeroth cd=180 duration=30)
Define(holy_fire 14914)
# Consumes the enemy in Holy flames that cause (150 of Spell Power) Holy damage and an additional o2 Holy damage over 7 seconds.?a231687[ Stacks up to u times.][]
  SpellInfo(holy_fire cd=10 duration=7 max_stacks=1 tick=1)
  # w2 Holy damage every t2 seconds.
  SpellAddTargetDebuff(holy_fire holy_fire add=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)
Define(memory_of_lucid_dreams 299300)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams)
Define(mind_blast 8092)
# Blasts the target's mind for (97.92 of Spell Power) Shadow damage?s231682[, preventing the next <shield> damage they deal][].?a185916[rnrn|cFFFFFFFFGenerates /100;s2 Insanity.|r][]
  SpellInfo(mind_blast cd=15 insanity=0)
  SpellRequire(mind_blast replaced_by set=holy_fire enabled=(specialization(holy)))
Define(mind_bomb 205369)
# Inflicts the target with a Mind Bomb.rnrnAfter 2 seconds or if the target dies, it unleashes a psychic explosion, disorienting all enemies within 226943A1 yds of the target for 6 seconds.
  SpellInfo(mind_bomb cd=30 duration=2)
  SpellRequire(mind_bomb unusable set=1 enabled=(not hastalent(mind_bomb_talent)))
  # About to unleash a psychic explosion, disorienting all nearby enemies.
  SpellAddTargetDebuff(mind_bomb mind_bomb add=1)
Define(mind_flay 15407)
# Assaults the target's mind with Shadow energy, causing o1 Shadow damage over 4.5 seconds and slowing their movement speed by s2.?a185916[rnrn|cFFFFFFFFGenerates s4*s3/100 Insanity over the duration.|r][]
  SpellInfo(mind_flay duration=4.5 channel=4.5 tick=0.75)
  # Movement speed slowed by s2 and taking Shadow damage every t1 sec.
  SpellAddBuff(mind_flay mind_flay add=1)
  # Movement speed slowed by s2 and taking Shadow damage every t1 sec.
  SpellAddTargetDebuff(mind_flay mind_flay add=1)
Define(mind_sear 48045)
# Corrosive shadow energy radiates from the target, dealing (12.6 of Spell Power)*s2 Shadow damage over 4.5 seconds to all enemies within 49821a2 yards of the target.?s137033[rnrn|cFFFFFFFFGenerates s2*208232s1/100 Insanity over the duration per target hit.|r][]
  SpellInfo(mind_sear duration=4.5 channel=4.5 tick=0.75)
  # Causing Shadow damage to all targets within 49821a2 yards every t1 sec.
  SpellAddBuff(mind_sear mind_sear add=1)
  # Causing shadow damage to all targets within a2 yards.
  SpellAddTargetDebuff(mind_sear mind_sear_debuff add=1)
Define(mind_sear_debuff 49821)
# Corrosive shadow energy radiates from the target, dealing (12.6 of Spell Power)*s2 Shadow damage over 4.5 seconds to all enemies within 49821a2 yards of the target.?s137033[rnrn|cFFFFFFFFGenerates s2*208232s1/100 Insanity over the duration per target hit.|r][]
  SpellInfo(mind_sear_debuff gcd=0 offgcd=1)
Define(mindbender 200174)
# Summons a Mindbender to attack the target for 15 seconds.rnrn|cFFFFFFFFGenerates 200010s1/100 Insanity each time the Mindbender attacks.|r
  SpellInfo(mindbender cd=60 duration=15)
  SpellRequire(mindbender unusable set=1 enabled=(not hastalent(mindbender_talent)))
Define(penance 47540)
# Launches a volley of holy light at the target, causing ?s193134[(40 of Spell Power)*4][(40 of Spell Power)*3] Holy damage to an enemy or ?s193134[(125 of Spell Power)*4][(125 of Spell Power)*3] healing to an ally over 2 seconds. Castable while moving.
  SpellInfo(penance cd=9 channel=0)
Define(power_infusion 10060)
# Infuses the target with power for 20 seconds, increasing haste by (25 of Spell Power).
  SpellInfo(power_infusion cd=120 duration=20 gcd=0 offgcd=1)
  # Haste increased by w1.
  SpellAddBuff(power_infusion power_infusion add=1)
Define(power_word_solace 129250)
# Strikes an enemy with heavenly power, dealing (80 of Spell Power) Holy damage and restoring <mana> of your maximum mana.
  SpellInfo(power_word_solace cd=15)
  SpellRequire(power_word_solace unusable set=1 enabled=(not hastalent(power_word_solace_talent)))
Define(purge_the_wicked 204197)
# Cleanses the target with fire, causing (24.8 of Spell Power) Fire damage and an additional 204213o1 Fire damage over 20 seconds. Spreads to an additional nearby enemy when you cast Penance on the target.
  SpellInfo(purge_the_wicked)
  SpellRequire(purge_the_wicked unusable set=1 enabled=(not hastalent(purge_the_wicked_talent)))
  # w1 Fire damage every t1 seconds.
  SpellAddTargetDebuff(purge_the_wicked purge_the_wicked_debuff add=1)
Define(purge_the_wicked_debuff 204213)
# Cleanses the target with fire, causing (24.8 of Spell Power) Fire damage and an additional 204213o1 Fire damage over 20 seconds. Spreads to an additional nearby enemy when you cast Penance on the target.
  SpellInfo(purge_the_wicked_debuff duration=20 gcd=0 offgcd=1 tick=2)
Define(purifying_blast 295337)
# Call down a purifying beam upon the target area, dealing 295293s3*(1+@versadmg)*s2 Fire damage over 6 seconds.?a295364[ Has a low chance to immediately annihilate any specimen deemed unworthy by MOTHER.][]?a295352[rnrnWhen an enemy dies within the beam, your damage is increased by 295354s1 for 8 seconds.][]rnrnAny Aberration struck by the beam is stunned for 3 seconds.
  SpellInfo(purifying_blast cd=60 duration=6)
Define(quaking_palm 107079)
# Strikes the target with lightning speed, incapacitating them for 4 seconds, and turns off your attack.
  SpellInfo(quaking_palm cd=120 duration=4 gcd=1)
  # Incapacitated.
  SpellAddTargetDebuff(quaking_palm quaking_palm add=1)
Define(reaping_flames 310690)
# Burn your target with a bolt of Azerite, dealing 310712s3 Fire damage. If the target has less than s2 health?a310705[ or more than 310705s1 health][], the cooldown is reduced by s3 sec.?a310710[rnrnIf Reaping Flames kills an enemy, its cooldown is lowered to 310710s2 sec and it will deal 310710s1 increased damage on its next use.][]
  SpellInfo(reaping_flames cd=45)
Define(ripple_in_space 299306)
# Infuse your Heart of Azeroth with Ripple in Space.
  SpellInfo(ripple_in_space)
Define(schism 214621)
# Attack the enemy's soul with a surge of Shadow energy, dealing (150 of Spell Power) Shadow damage and increasing your spell damage to the target by s2 for 9 seconds.
  SpellInfo(schism cd=24 duration=9)
  SpellRequire(schism unusable set=1 enabled=(not hastalent(schism_talent)))
  # Taking s2 increased damage from the Priest.
  SpellAddTargetDebuff(schism schism add=1)
Define(searing_nightmare 341385)
# Instantly deals (43 of Spell Power) Shadow damage to enemies around the target and afflicts them with Shadow Word: Pain. If the enemy is already afflicted by your Shadow Word: Pain, Searing Nightmare's damage is increased by m1.rnrnOnly usable while channeling Mind Sear.
  SpellInfo(searing_nightmare insanity=3000)
  SpellRequire(searing_nightmare unusable set=1 enabled=(not hastalent(searing_nightmare_talent)))
Define(shadow_covenant 314867)
# Make a shadowy pact, healing the target and s3-1 other injured allies within A2 yds for (150 of Spell Power). For 9 seconds, your Shadow spells deal 322105m2 increased damage and healing, but you cannot cast Holy spells.
  SpellInfo(shadow_covenant cd=30)
  SpellRequire(shadow_covenant unusable set=1 enabled=(not hastalent(shadow_covenant_talent)))
  # Shadow spells deal w2 increased damage and healing, but cannot cast Holy spells.
  SpellAddBuff(shadow_covenant shadow_covenant_buff add=1)
Define(shadow_covenant_buff 322105)
# Make a shadowy pact, healing the target and s3-1 other injured allies within A2 yds for (150 of Spell Power). For 9 seconds, your Shadow spells deal 322105m2 increased damage and healing, but you cannot cast Holy spells.
  SpellInfo(shadow_covenant_buff duration=9 gcd=0 offgcd=1)
Define(shadow_crash 342834)
# Hurl a bolt of slow-moving Shadow energy at the destination, dealing (85 of Spell Power) Shadow damage to all targets within 205386A1 yards.rnrnIf Shadow Crash hits a lone target, they suffer 342835m2 increased damage from your next Shadow Crash within 15 seconds. Stacks up to 342835u.rnrn|cFFFFFFFFGenerates /100;s2 Insanity.|r
  SpellInfo(shadow_crash cd=45 insanity=-800)
  SpellRequire(shadow_crash unusable set=1 enabled=(not hastalent(shadow_crash_talent)))
  # Damage taken from the Priests' Shadow Crash increased by w2.
  SpellAddTargetDebuff(shadow_crash shadow_crash_debuff add=1)
Define(shadow_crash_debuff 342835)
# Hurl a bolt of slow-moving Shadow energy at the destination, dealing (85 of Spell Power) Shadow damage to all targets within 205386A1 yards.rnrnIf Shadow Crash hits a lone target, they suffer 342835m2 increased damage from your next Shadow Crash within 15 seconds. Stacks up to 342835u.rnrn|cFFFFFFFFGenerates /100;s2 Insanity.|r
  SpellInfo(shadow_crash_debuff duration=15 max_stacks=2 gcd=0 offgcd=1)
Define(shadow_word_death 32379)
# A word of dark binding that inflicts (85 of Spell Power) Shadow damage to the target. If the target is not killed by Shadow Word: Death, the caster takes damage equal to the damage inflicted upon the target.rnrnDamage increased by s3 to targets below s2 health.?c3[][]?s81749[rnrnDoes not trigger Atonement.][]
  SpellInfo(shadow_word_death cd=30)
Define(shadow_word_pain 589)
# A word of darkness that causes (12.920000000000002 of Spell Power) Shadow damage instantly, and an additional o2 Shadow damage over 12 seconds.?a185916[rnrn|cFFFFFFFFGenerates m3/100 Insanity.|r][]
  SpellInfo(shadow_word_pain duration=12 insanity=-400 tick=2)
  # Suffering w2 Shadow damage every t2 sec.
  SpellAddTargetDebuff(shadow_word_pain shadow_word_pain add=1)
Define(shadowfiend 34433)
# Summons a shadowy fiend to attack the target for 15 seconds.?s319904[rnrn|cFFFFFFFFGenerates 262485s1/100 Insanity each time the Shadowfiend attacks.|r][]?s343726[rnrn|cFFFFFFFFGenerates 343726s1 Mana each time the Shadowfiend attacks.|r][]
  SpellInfo(shadowfiend cd=180 duration=15)
  # 343726
  SpellAddBuff(shadowfiend shadowfiend add=1)
Define(shadowform 232698)
# Assume a Shadowform, increasing your spell damage dealt by s1.
  SpellInfo(shadowform)
  # Spell damage dealt increased by s1.
  SpellAddBuff(shadowform shadowform add=1)
Define(silence 15487)
# Silences the target, preventing them from casting spells for 4 seconds. Against non-players, also interrupts spellcasting and prevents any spell in that school from being cast for 4 seconds.
  SpellInfo(silence cd=45 duration=4 gcd=0 offgcd=1)
  # Silenced.
  SpellAddTargetDebuff(silence silence add=1)
Define(smite 262861)
# Smite deals s1 increased damage.
  SpellInfo(smite gcd=0 offgcd=1)
Define(surrender_to_madness 319952)
# Deals (64.60000000000001 of Spell Power)*2 Shadow damage to the target and activates Voidform.rnrnFor the next 25 seconds, your Insanity-generating abilities generate s2 more Insanity and you can cast while moving.rnrnIf the target does not die within 25 seconds of using Surrender to Madness, you die.
  SpellInfo(surrender_to_madness cd=90 duration=25)
  SpellRequire(surrender_to_madness unusable set=1 enabled=(not hastalent(surrender_to_madness_talent)))
  # The Priest has surrendered to madness, sharing its fate with its target. If the target doesn't die within d, the Priest dies.rnrnCan cast while moving, and  Insanity-generating abilities generate w2 more Insanity.
  SpellAddBuff(surrender_to_madness surrender_to_madness add=1)
  # Mind Blast has an additional charge.rn?s193225[Spell damage dealt increased by w16.][Spell damage dealt increased by w1.]rn?s341240[Critical strike chance increased by w4.][]?s193225[ Losing w3/500 Insanity every sec.][]
  SpellAddBuff(surrender_to_madness voidform_buff add=1)
  # The Priest has surrendered to madness, sharing its fate with its target. If the target doesn't die within d, the Priest dies.rnrnCan cast while moving, and  Insanity-generating abilities generate w2 more Insanity.
  SpellAddTargetDebuff(surrender_to_madness surrender_to_madness add=1)
Define(the_unbound_force 299321)
# Infuse your Heart of Azeroth with The Unbound Force.
  SpellInfo(the_unbound_force)
Define(unfurling_darkness_buff 341291)
# After casting Vampiric Touch on a target, your next Vampiric Touch within 8 seconds is instant cast and deals (105.4 of Spell Power) Shadow damage immediately.rnrnThis effect cannot occur more than once every 15 seconds.
  SpellInfo(unfurling_darkness_buff duration=15 gcd=0 offgcd=1)
Define(vampiric_touch 34914)
# A touch of darkness that causes 34914o2 Shadow damage over 21 seconds, and heals you for e2*100 of damage dealt.rn?s322116[rnIf Vampiric Touch is dispelled, the dispeller flees in Horror for 3 seconds.rn][]rn|cFFFFFFFFGenerates m3/100 Insanity.|r
  SpellInfo(vampiric_touch duration=21 insanity=-500 tick=3)
  # Suffering w2 Shadow damage every t2 sec.
  SpellAddTargetDebuff(vampiric_touch vampiric_touch add=1)
Define(void_bolt_shadow 231688)
# Void Bolt extends the duration of your Shadow Word: Pain and Vampiric Touch on all nearby targets by @switch<s2>[s1/1000][s1/1000.1] sec.
  SpellInfo(void_bolt_shadow gcd=0 offgcd=1)
Define(void_eruption 228260)
# Releases an explosive blast of pure void energy, activating Voidform and causing (64.60000000000001 of Spell Power)*2 Shadow damage to all enemies within a1 yds of your target.rnrnDuring Voidform, this ability is replaced by Void Bolt.
  SpellInfo(void_eruption cd=90)
Define(void_torrent 263165)
# Channel a torrent of void energy into the target, dealing o Shadow damage over 3 seconds.rnrn|cFFFFFFFFGenerates 289577s1*289577s2/100 Insanity over the duration.|r
  SpellInfo(void_torrent cd=30 duration=3 channel=3 tick=1)
  SpellRequire(void_torrent unusable set=1 enabled=(not hastalent(void_torrent_talent)))
  # Dealing s1 Shadow damage to the target every t1 sec.
  SpellAddBuff(void_torrent void_torrent add=1)
  # |cFFFFFFFFGenerates s1*s2/100 Insanity over d.|r
  SpellAddBuff(void_torrent void_torrent_buff add=1)
  # Dealing s1 Shadow damage to the target every t1 sec.
  SpellAddTargetDebuff(void_torrent void_torrent add=1)
Define(void_torrent_buff 289577)
# Channel a torrent of void energy into the target, dealing o Shadow damage over 3 seconds.rnrn|cFFFFFFFFGenerates 289577s1*289577s2/100 Insanity over the duration.|r
  SpellInfo(void_torrent_buff duration=3.9 gcd=0 offgcd=1 tick=0.975)
Define(voidform_buff 194249)
# Activated by casting Void Eruption. Twists your Shadowform with the powers of the Void, increasing spell damage you deal by 194249s1?s8092[, granting an additional charge of Mind Blast, and refreshing Mind Blast's cooldown.][.]rnrn?a193225[Your Insanity will drain increasingly fast until it reaches 0 and Voidform ends.][Lasts 15 seconds.]
  SpellInfo(voidform_buff duration=15 gcd=0 offgcd=1 tick=1)
Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp add=1)
Define(worldvein_resonance 298606)
# Infuse your Heart of Azeroth with Worldvein Resonance.
  SpellInfo(worldvein_resonance)
Define(wrathful_faerie_debuff 342132)
# Call forth three faerie guardians to attend your targets for 20 seconds.rnrn@spellname342132: Direct attacks against the target restore 327703s1/100.1 Mana or 327703s2/100 Insanity. Follows your Shadow Word: Pain.rnrn@spellname327694: Reduces damage taken by 327694s1. Follows your Power Word: Shield.rnrn@spellname327710: Increases the cooldown recovery rate of a major ability by 327710s1. Follows your ?c2[Flash Heal][Shadow Mend].rn
  SpellInfo(wrathful_faerie_debuff duration=20 gcd=0 offgcd=1)
  # Direct damage on this target restores 327703s1/100.1 Mana or 327703s2/100 Insanity to @auracaster.rnrnFollows your Shadow Word: Pain.
  SpellAddTargetDebuff(wrathful_faerie_debuff wrathful_faerie_debuff add=1)
Define(damnation_talent 21718)
# Instantly afflicts the target with Shadow Word: Pain, Vampiric Touch and Devouring Plague.
Define(divine_star_talent 19760)
# Throw a Divine Star forward 24 yds, healing allies in its path for (70 of Spell Power) and dealing (40 of Spell Power) Holy damage to enemies. After reaching its destination, the Divine Star returns to you, healing allies and damaging enemies in its path again.
Define(hungering_void_talent 21978)
# Void Bolt causes the target to become vulnerable to the void, increasing their damage taken from you by 345219m2 for 6 seconds. This effect may only be active on one target at a time.rnrnCasting Void Bolt on an enemy that is already vulnerable extends the duration of your Voidform by m3 sec, or m4 sec if Void Bolt critically strikes.
Define(mind_bomb_talent 23375)
# Inflicts the target with a Mind Bomb.rnrnAfter 2 seconds or if the target dies, it unleashes a psychic explosion, disorienting all enemies within 226943A1 yds of the target for 6 seconds.
Define(mindbender_talent 21719)
# Summons a Mindbender to attack the target for 15 seconds.rnrn|cFFFFFFFFGenerates 200010s1/100 Insanity each time the Mindbender attacks.|r
Define(mindbender_talent 21719)
# Summons a Mindbender to attack the target for 15 seconds.rnrn|cFFFFFFFFGenerates 200010s1/100 Insanity each time the Mindbender attacks.|r
Define(misery_talent 23126)
# Vampiric Touch also applies Shadow Word: Pain to the target.
Define(power_word_solace_talent 19755)
# Strikes an enemy with heavenly power, dealing (80 of Spell Power) Holy damage and restoring <mana> of your maximum mana.
Define(psychic_link_talent 22311)
# ?s205351[Shadow Word: Void][Mind Blast] deals s1 of its damage to all other targets afflicted by your Vampiric Touch within 199486A2 yards.
Define(purge_the_wicked_talent 22161)
# Cleanses the target with fire, causing (24.8 of Spell Power) Fire damage and an additional 204213o1 Fire damage over 20 seconds. Spreads to an additional nearby enemy when you cast Penance on the target.
Define(purge_the_wicked_talent 22161)
# Cleanses the target with fire, causing (24.8 of Spell Power) Fire damage and an additional 204213o1 Fire damage over 20 seconds. Spreads to an additional nearby enemy when you cast Penance on the target.
Define(schism_talent 22329)
# Attack the enemy's soul with a surge of Shadow energy, dealing (150 of Spell Power) Shadow damage and increasing your spell damage to the target by s2 for 9 seconds.
Define(searing_nightmare_talent 23127)
# Instantly deals (43 of Spell Power) Shadow damage to enemies around the target and afflicts them with Shadow Word: Pain. If the enemy is already afflicted by your Shadow Word: Pain, Searing Nightmare's damage is increased by m1.rnrnOnly usable while channeling Mind Sear.
Define(searing_nightmare_talent 23127)
# Instantly deals (43 of Spell Power) Shadow damage to enemies around the target and afflicts them with Shadow Word: Pain. If the enemy is already afflicted by your Shadow Word: Pain, Searing Nightmare's damage is increased by m1.rnrnOnly usable while channeling Mind Sear.
Define(shadow_covenant_talent 19766)
# Make a shadowy pact, healing the target and s3-1 other injured allies within A2 yds for (150 of Spell Power). For 9 seconds, your Shadow spells deal 322105m2 increased damage and healing, but you cannot cast Holy spells.
Define(shadow_crash_talent 21755)
# Hurl a bolt of slow-moving Shadow energy at the destination, dealing (85 of Spell Power) Shadow damage to all targets within 205386A1 yards.rnrnIf Shadow Crash hits a lone target, they suffer 342835m2 increased damage from your next Shadow Crash within 15 seconds. Stacks up to 342835u.rnrn|cFFFFFFFFGenerates /100;s2 Insanity.|r
Define(surrender_to_madness_talent 21979)
# Deals (64.60000000000001 of Spell Power)*2 Shadow damage to the target and activates Voidform.rnrnFor the next 25 seconds, your Insanity-generating abilities generate s2 more Insanity and you can cast while moving.rnrnIf the target does not die within 25 seconds of using Surrender to Madness, you die.
Define(twist_of_fate_talent_shadow 23125)
# After damaging a target below s1 health, you gain 123254s2 increased damage and healing for 8 seconds.
Define(void_torrent_talent 21720)
# Channel a torrent of void energy into the target, dealing o Shadow damage over 3 seconds.rnrn|cFFFFFFFFGenerates 289577s1*289577s2/100 Insanity over the duration.|r
Define(unbridled_fury_item 139327)
Define(painbreaker_psalm_runeforge 6981)
Define(sephuzs_proclamation_runeforge 7103)
Define(shadowflame_prism_runeforge 6982)
Define(twins_of_the_sun_priestess_runeforge 7002)
Define(dissonant_echoes_conduit 115)
    `;
    // END

    code += `
SpellRequire(void_bolt_shadow unusable set=1 enabled=(not buffpresent(voidform_buff)))
  `;

    OvaleScripts.RegisterScript(
        "PRIEST",
        undefined,
        name,
        desc,
        code,
        "include"
    );
}
