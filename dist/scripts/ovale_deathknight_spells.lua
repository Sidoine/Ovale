local __exports = LibStub:NewLibrary("ovale/scripts/ovale_deathknight_spells", 80300)
if not __exports then return end
__exports.registerDeathKnightSpells = function(OvaleScripts)
    local name = "ovale_deathknight_spells"
    local desc = "[9.0] Ovale: Death Knight spells"
    local code = [[Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
Define(anima_of_death_0 294926)
# Draw upon your vitality to sear your foes, dealing s2 of your maximum health in Fire damage to all nearby enemies and heal for 294946s1 of your maximum health per enemy hit, up to ?a294945[294945s1*2][294945s1] of your maximum health.
  SpellInfo(anima_of_death_0 cd=150)
Define(anima_of_death_1 294946)
# Heal for s1 of your maximum health.
  SpellInfo(anima_of_death_1 gcd=0 offgcd=1)
Define(anima_of_death_2 300002)
# Draw upon your vitality to sear your foes, dealing s2 of your maximum health in Fire damage to all nearby enemies and heal for 294946s1 of your maximum health per enemy hit, up to 294945s1 of your maximum health.
  SpellInfo(anima_of_death_2 cd=120 gcd=1)
Define(anima_of_death_3 300003)
# Draw upon your vitality to sear your foes, dealing s2 of your maximum health in Fire damage to all nearby enemies and heal for 294946s1+294945s2 of your maximum health per enemy hit, up to 294945s1*2 of your maximum health.
  SpellInfo(anima_of_death_3 cd=120 gcd=1)
Define(apocalypse 275699)
# Bring doom upon the enemy, dealing sw1 Shadow damage and bursting up to s2 Festering Wounds on the target.rnrnSummons an Army of the Dead ghoul for 15 seconds for each burst Festering Wound.?a343755[rnrn|cFFFFFFFFGenerates 343758s3 Runes.|r][]
# Rank 3: Apocalypse generates 343758s1 Runes.
  SpellInfo(apocalypse cd=90)
Define(arcane_pulse 260364)
# Deals <damage> Arcane damage to nearby enemies and reduces their movement speed by 260369s1. Lasts 12 seconds.
  SpellInfo(arcane_pulse cd=180 gcd=1)

Define(arcane_torrent_0 25046)
# Remove s1 beneficial effect from all enemies within A1 yards and restore m2 Energy.
  SpellInfo(arcane_torrent_0 cd=120 gcd=1 energy=-15)
Define(arcane_torrent_1 28730)
# Remove s1 beneficial effect from all enemies within A1 yards and restore s2 of your Mana.
  SpellInfo(arcane_torrent_1 cd=120)
Define(arcane_torrent_2 50613)
# Remove s1 beneficial effect from all enemies within A1 yards and restore m2/10 Runic Power.
  SpellInfo(arcane_torrent_2 cd=120 runicpower=-20)
Define(arcane_torrent_3 69179)
# Remove s1 beneficial effect from all enemies within A1 yards and increase your Rage by m2/10.rn
  SpellInfo(arcane_torrent_3 cd=120 rage=-15)
Define(arcane_torrent_4 80483)
# Remove s1 beneficial effect from all enemies within A1 yards and restore s2 of your Focus.
  SpellInfo(arcane_torrent_4 cd=120 focus=-15)
Define(arcane_torrent_5 129597)
# Remove s1 beneficial effect from all enemies within A1 yards and restore ?s137025[s2 Chi][]?s137024[s3 of your mana][]?s137023[s4 Energy][].
  SpellInfo(arcane_torrent_5 cd=120 gcd=1 chi=-1 energy=-15)
Define(arcane_torrent_6 155145)
# Remove s1 beneficial effect from all enemies within A1 yards and restore s2 Holy Power.
  SpellInfo(arcane_torrent_6 cd=120 holypower=-1)
Define(arcane_torrent_7 202719)
# Remove s1 beneficial effect from all enemies within A1 yards and generate ?s203513[m3/10 Pain][m2 Fury].
  SpellInfo(arcane_torrent_7 cd=120 fury=-15 pain=-15)
Define(arcane_torrent_8 232633)
# Remove s1 beneficial effect from all enemies within A1 yards and restore ?s137033[s3/100 Insanity][s2 of your mana].
  SpellInfo(arcane_torrent_8 cd=120 insanity=-1500)
Define(army_of_the_dead 42650)
# Summons a legion of ghouls who swarms your enemies, fighting anything they can for 30 seconds.
  SpellInfo(army_of_the_dead runes=1 runicpower=-10 cd=480 duration=4 tick=0.5)
  # Summoning ghouls.
  SpellAddBuff(army_of_the_dead army_of_the_dead=1)
Define(asphyxiate 108194)
# Lifts the enemy target off the ground, crushing their throat with dark energy and stunning them for 4 seconds.
  SpellInfo(asphyxiate cd=45 duration=4 talent=asphyxiate_talent_unholy)
  # Stunned.
  SpellAddTargetDebuff(asphyxiate asphyxiate=1)
Define(bag_of_tricks 312411)
# Pull your chosen trick from the bag and use it on target enemy or ally. Enemies take <damage> damage, while allies are healed for <healing>. 
  SpellInfo(bag_of_tricks cd=90)
Define(berserking 59621)
# Permanently enchant a melee weapon to sometimes increase your attack power by 59620s1, but at the cost of reduced armor. Cannot be applied to items higher than level ecix
  SpellInfo(berserking gcd=0 offgcd=1)
Define(blinding_sleet 207167)
# Targets in a cone in front of you are blinded, causing them to wander disoriented for 5 seconds. Damage may cancel the effect.rnrnWhen Blinding Sleet ends, enemies are slowed by 317898s1 for 6 seconds.
  SpellInfo(blinding_sleet cd=60 duration=5 talent=blinding_sleet_talent)
  # Disoriented.
  SpellAddTargetDebuff(blinding_sleet blinding_sleet=1)
Define(blood_boil 50842)
# Deals s1 Shadow damage?s212744[ to all enemies within A1 yds.][ and infects all enemies within A1 yds with Blood Plague.rnrn|Tinterfaceiconsspell_deathknight_bloodplague.blp:24|t |cFFFFFFFFBlood Plague|rrnA shadowy disease that drains o1 health from the target over 24 seconds.  ]
# Rank 2: Increases the maximum number of charges by s1.
  SpellInfo(blood_boil cd=7.5)
Define(blood_fury_0 20572)
# Increases your attack power by s1 for 15 seconds.
  SpellInfo(blood_fury_0 cd=120 duration=15 gcd=0 offgcd=1)
  # Attack power increased by w1.
  SpellAddBuff(blood_fury_0 blood_fury_0=1)
Define(blood_fury_1 24571)
# Instantly increases your rage by 300/10.
  SpellInfo(blood_fury_1 gcd=0 offgcd=1 rage=-30)
Define(blood_fury_2 33697)
# Increases your attack power and Intellect by s1 for 15 seconds.
  SpellInfo(blood_fury_2 cd=120 duration=15 gcd=0 offgcd=1)
  # Attack power and Intellect increased by w1.
  SpellAddBuff(blood_fury_2 blood_fury_2=1)
Define(blood_fury_3 33702)
# Increases your Intellect by s1 for 15 seconds.
  SpellInfo(blood_fury_3 cd=120 duration=15 gcd=0 offgcd=1)
  # Intellect increased by w1.
  SpellAddBuff(blood_fury_3 blood_fury_3=1)
Define(blood_of_the_enemy_0 297969)
# Infuse your Heart of Azeroth with Blood of the Enemy.
  SpellInfo(blood_of_the_enemy_0)
Define(blood_of_the_enemy_1 297970)
# Infuse your Heart of Azeroth with Blood of the Enemy.
  SpellInfo(blood_of_the_enemy_1)
Define(blood_of_the_enemy_2 297971)
# Infuse your Heart of Azeroth with Blood of the Enemy.
  SpellInfo(blood_of_the_enemy_2)
Define(blood_of_the_enemy_3 299039)
# Infuse your Heart of Azeroth with Blood of the Enemy.
  SpellInfo(blood_of_the_enemy_3)
Define(blooddrinker 206931)
# Drains o1 health from the target over 3 seconds.rnrnYou can move, parry, dodge, and use defensive abilities while channeling this ability.
  SpellInfo(blooddrinker runes=1 runicpower=-10 cd=30 duration=3 channel=3 tick=1 talent=blooddrinker_talent)
  # Draining s1 health from the target every t1 sec.
  SpellAddTargetDebuff(blooddrinker blooddrinker=1)
Define(bone_shield 195181)
# Surrounds you with a barrier of whirling bones, increasing Armor by s1*STR/100?s316746[, and your Haste by s4][]. Each melee attack against you consumes a charge. Lasts 30 seconds or until all charges are consumed.
  SpellInfo(bone_shield duration=30 channel=30 max_stacks=10 gcd=0 offgcd=1)
  # Armor increased by w1*STR/100.rnHaste increased by w4.
  SpellAddBuff(bone_shield bone_shield=1)
  SpellAddBuff(bone_shield marrowrend=1)
Define(bonestorm 194844)
# A whirl of bone and gore batters up to 196528s2 nearby enemies, dealing 196528s1 Shadow damage every t3 sec, and healing you for 196545s1 of your maximum health every time it deals damage (up to s1*s4). Lasts t3 sec per s3 Runic Power spent.
  SpellInfo(bonestorm runicpower=10 cd=60 duration=1 tick=1 talent=bonestorm_talent)
  # Dealing 196528s1 Shadow damage to nearby enemies every t3 sec, and healing for 196545s1 of maximum health for each target hit (up to s1*s4).
  SpellAddBuff(bonestorm bonestorm=1)
Define(breath_of_sindragosa 152279)
# Continuously deal 155166s2*<CAP>/AP Frost damage every t1 sec to enemies in a cone in front of you, until your Runic Power is exhausted. Deals reduced damage to secondary targets.rnrn|cFFFFFFFFGenerates 303753s1 lRune:Runes; at the start and end.|r
  SpellInfo(breath_of_sindragosa cd=120 gcd=0 offgcd=1 tick=1 talent=breath_of_sindragosa_talent)
  # Continuously dealing Frost damage every t1 sec to enemies in a cone in front of you.
  SpellAddBuff(breath_of_sindragosa breath_of_sindragosa=1)
Define(chains_of_ice 45524)
# Shackles the target with frozen chains, reducing movement speed by s1 for 8 seconds.
  SpellInfo(chains_of_ice runes=1 runicpower=-10 duration=8)
  # Movement slowed s1 by frozen chains.
  SpellAddTargetDebuff(chains_of_ice chains_of_ice=1)
Define(chill_streak_0 204160)
# Deals up to 204167s2 of the target's total health in Frost damage and reduces their movement speed by 204206m2 for 4 seconds.rnrnChill Streak bounces up to m1 times between closest targets within 204165A1 yards.
  SpellInfo(chill_streak_0 cd=45)
Define(chill_streak_1 204165)
  SpellInfo(chill_streak_1 channel=0 gcd=0 offgcd=1)
Define(clawing_shadows 207311)
# Deals s2 Shadow damage and causes 1 Festering Wound to burst.
  SpellInfo(clawing_shadows runes=1 runicpower=-10 talent=clawing_shadows_talent)
Define(cold_heart_buff 281209)
# Every t1 sec, gain a stack of Cold Heart, causing your next Chains of Ice to deal 281210s1 Frost damage. Stacks up to 281209u times.
  SpellInfo(cold_heart_buff max_stacks=20 gcd=0 offgcd=1)
  # Your next Chains of Ice will deal 281210s1 Frost damage.
  SpellAddBuff(cold_heart_buff cold_heart_buff=1)
Define(concentrated_flame_0 295368)
# Blast your target with a ball of concentrated flame, dealing 295365s2*(1+@versadmg) Fire damage to an enemy or healing an ally for 295365s2*(1+@versadmg)?a295377[, then burn the target for an additional 295377m1 of the damage or healing done over 6 seconds][]. rnrnEach cast of Concentrated Flame deals s3 increased damage or healing. This bonus resets after every third cast.
  SpellInfo(concentrated_flame_0 duration=6 channel=6 gcd=0 offgcd=1 tick=2)
  # Suffering w1 damage every t1 sec.
  SpellAddTargetDebuff(concentrated_flame_0 concentrated_flame_0=1)
Define(concentrated_flame_1 295373)
# Blast your target with a ball of concentrated flame, dealing 295365s2*(1+@versadmg) Fire damage to an enemy or healing an ally for 295365s2*(1+@versadmg)?a295377[, then burn the target for an additional 295377m1 of the damage or healing done over 6 seconds][]. rnrnEach cast of Concentrated Flame deals s3 increased damage or healing. This bonus resets after every third cast.
  SpellInfo(concentrated_flame_1 cd=30 channel=0)
  SpellAddTargetDebuff(concentrated_flame_1 concentrated_flame_3=1)
Define(concentrated_flame_2 295374)
# Blast your target with a ball of concentrated flame, dealing 295365s2*(1+@versadmg) Fire damage to an enemy or healing an ally for 295365s2*(1+@versadmg)?a295377[, then burn the target for an additional 295377m1 of the damage or healing done over 6 seconds][]. rnrnEach cast of Concentrated Flame deals s3 increased damage or healing. This bonus resets after every third cast.
  SpellInfo(concentrated_flame_2 channel=0 gcd=0 offgcd=1)
Define(concentrated_flame_3 295376)
# Blast your target with a ball of concentrated flame, dealing 295365s2*(1+@versadmg) Fire damage to an enemy or healing an ally for 295365s2*(1+@versadmg)?a295377[, then burn the target for an additional 295377m1 of the damage or healing done over 6 seconds][]. rnrnEach cast of Concentrated Flame deals s3 increased damage or healing. This bonus resets after every third cast.
  SpellInfo(concentrated_flame_3 channel=0 gcd=0 offgcd=1)
Define(concentrated_flame_4 295380)
# Concentrated Flame gains an enhanced appearance.
  SpellInfo(concentrated_flame_4 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(concentrated_flame_4 concentrated_flame_4=1)
Define(concentrated_flame_5 299349)
# Blast your target with a ball of concentrated flame, dealing 295365s2*(1+@versadmg) Fire damage to an enemy or healing an ally for 295365s2*(1+@versadmg), then burn the target for an additional 295377m1 of the damage or healing done over 6 seconds.rnrnEach cast of Concentrated Flame deals s3 increased damage or healing. This bonus resets after every third cast.
  SpellInfo(concentrated_flame_5 cd=30 channel=0 gcd=1)
  SpellAddTargetDebuff(concentrated_flame_5 concentrated_flame_3=1)
Define(concentrated_flame_6 299353)
# Blast your target with a ball of concentrated flame, dealing 295365s2*(1+@versadmg) Fire damage to an enemy or healing an ally for 295365s2*(1+@versadmg), then burn the target for an additional 295377m1 of the damage or healing done over 6 seconds.rnrnEach cast of Concentrated Flame deals s3 increased damage or healing. This bonus resets after every third cast.rn|cFFFFFFFFMax s1 Charges.|r
  SpellInfo(concentrated_flame_6 cd=30 channel=0 gcd=1)
  SpellAddTargetDebuff(concentrated_flame_6 concentrated_flame_3=1)
Define(consumption 274156)
# Strikes up to s3 enemies in front of you with a hungering attack that deals sw1 Physical damage and heals you for e1*100 of that damage.
  SpellInfo(consumption cd=30 talent=consumption_talent)

Define(crimson_scourge 81136)
# Your auto attacks on targets infected with your Blood Plague have a chance to make your next Death and Decay cost no runes and reset its cooldown.
  SpellInfo(crimson_scourge channel=0 gcd=0 offgcd=1)
  SpellAddBuff(crimson_scourge crimson_scourge=1)
Define(dancing_rune_weapon 49028)
# Summons a rune weapon for 8 seconds that mirrors your melee attacks and bolsters your defenses.rnrnWhile active, you gain 81256s1 parry chance.
  SpellInfo(dancing_rune_weapon cd=120 duration=13)

  SpellAddTargetDebuff(dancing_rune_weapon dancing_rune_weapon=1)
Define(dark_transformation 63560)
# Your ?s207313[abomination]?s58640[geist][ghoul] deals 344955s1 Shadow damage to 344955s2 nearby enemies and transforms into a powerful undead monstrosity for 15 seconds. ?s325554[Granting them 325554s1 energy and the][The] ?s207313[abomination]?s58640[geist][ghoul]'s abilities are empowered and take on new functions while the transformation is active.
# Rank 2: Your ?s207313[abomination]?s58640[geist][ghoul] deals 344955s1 Shadow damage to 344955s2 nearby enemies and transforms into a powerful undead monstrosity for 15 seconds. ?s325554[Granting them 325554s1 energy and the][The] ?s207313[abomination]?s58640[geist][ghoul]'s abilities are empowered and take on new functions while the transformation is active.
  SpellInfo(dark_transformation cd=60 duration=15 channel=15)
  # ?w2>0[Transformed into an undead monstrosity.][Gassy.]rnDamage dealt increased by w1.
  SpellAddBuff(dark_transformation dark_transformation=1)
Define(death_and_decay_0 316664)
# Heart Strike hits up to s1 additional enemies while you remain in Death and Decay.
  SpellInfo(death_and_decay_0 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(death_and_decay_0 death_and_decay_0=1)
Define(death_and_decay_1 316916)
# Scourge Strike hits all enemies near the target while you remain in Death and Decay.
  SpellInfo(death_and_decay_1 channel=0 gcd=0 offgcd=1)
Define(death_coil 47541)
# Fires a blast of unholy energy at the target, causing 47632s1 Shadow damage to an enemy or healing an Undead ally for 47633s1 health.?s316941[rnrnReduces the cooldown of Dark Transformation by s2/1000 sec.][]
# Rank 2: Damage dealt reduces the cooldown of Dark Transformation by 47541s2/1000 sec.
  SpellInfo(death_coil runicpower=40)
Define(death_strike 49998)
# Focuses dark power into a strike?s137006[ with both weapons, that deals a total of s1+66188s1][ that deals s1] Physical damage and heals you for s2 of all damage taken in the last s4 sec, minimum s3 of maximum health.
# Rank 2: Death Strike's cost is reduced by s3/-10, and its healing is increased by s1.
  SpellInfo(death_strike runicpower=45)
Define(defile 152280)
# Defile the targeted ground, dealing (156000s1*(10 seconds+1)/t3) Shadow damage to all enemies over 10 seconds.rnrnWhile you remain within your Defile, your ?s207311[Clawing Shadows][Scourge Strike] will hit 55090s4-1 enemies near the target?a315442|a331119[ and inflict Death's Due for 12 seconds.rnrnDeath's Due reduces damage enemies deal to you by 324164s1, up to a maximum of 324164s1*-324164u and their power is transferred to you as an equal amount of Strength.][].rnrnIf any enemies are standing in the Defile, it grows in size and deals increasing damage every sec.
  SpellInfo(defile runes=1 runicpower=-10 cd=20 duration=10 tick=1 talent=defile_talent)
  SpellAddBuff(defile defile=1)
Define(empower_rune_weapon 47568)
# Empower your rune weapon, gaining s3 Haste and generating s1 LRune:Runes; and m2/10 Runic Power instantly and every t1 sec for 20 seconds.
# Rank 2: Reduces the cooldown by s1/-1000 sec.
  SpellInfo(empower_rune_weapon cd=120 duration=20 gcd=0 offgcd=1 tick=5)
  # Haste increased by s3.rnGenerating s1 LRune:Runes; and m2/10 Runic Power every t1 sec.
  SpellAddBuff(empower_rune_weapon empower_rune_weapon=1)
Define(epidemic 207317)
# Causes each of your Virulent Plagues to flare up, dealing 212739s1 Shadow damage to the infected enemy, and an additional 215969s2 Shadow damage to all other enemies near them.
  SpellInfo(epidemic runicpower=30 channel=0)
Define(festering_strike 85948)
# Strikes for s1 Physical damage and infects the target with m2-M2 Festering Wounds.rnrn|Tinterfaceiconsspell_yorsahj_bloodboil_purpleoil.blp:24|t |cFFFFFFFFFestering Wound|rrnA pustulent lesion that will burst on death or when damaged by Scourge Strike, dealing 194311s1 Shadow damage and generating 195757s1 Runic Power.
# Rank 2: Increases damage done by s1.
  SpellInfo(festering_strike runes=2 runicpower=-20)
Define(festering_wound 197147)
# Festering Strike applies a pustulent lesion that will burst on death or when damaged by Scourge Strike, dealing 194311s1 Shadow damage and generating 195757s1 Runic Power.rnrnStacks up to 194310u times on any target.
  SpellInfo(festering_wound channel=0 gcd=0 offgcd=1)

Define(festermight 274373)
# Bursting a Festering Wound grants you s1 Strength for 20 seconds, stacking. Stacking this effect does not extend its duration.
  SpellInfo(festermight duration=20 channel=20 max_stacks=30 gcd=0 offgcd=1)
  # Strength increased by w1.
  SpellAddBuff(festermight festermight=1)
Define(fireblood_0 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. ?s195710[This effect shares a 30 sec cooldown with other similar effects.][]
  SpellInfo(fireblood_0 cd=120 gcd=0 offgcd=1)
Define(fireblood_1 265226)
# Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by s1.
  SpellInfo(fireblood_1 duration=8 max_stacks=6 gcd=0 offgcd=1)
  # Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by w1.
  SpellAddBuff(fireblood_1 fireblood_1=1)
Define(focused_azerite_beam_0 295258)
# Focus excess Azerite energy into the Heart of Azeroth, then expel that energy outward, dealing m1*10 Fire damage to all enemies in front of you over 3 seconds.?a295263[ Castable while moving.][]
  SpellInfo(focused_azerite_beam_0 cd=90 duration=3 channel=3 tick=0.33)
  SpellAddBuff(focused_azerite_beam_0 focused_azerite_beam_0=1)
  SpellAddBuff(focused_azerite_beam_0 focused_azerite_beam_1=1)
Define(focused_azerite_beam_1 295261)
# Focus excess Azerite energy into the Heart of Azeroth, then expel that energy outward, dealing m1*10 Fire damage to all enemies in front of you over 3 seconds.?a295263[ Castable while moving.][]
  SpellInfo(focused_azerite_beam_1 cd=90)
Define(focused_azerite_beam_2 299336)
# Focus excess Azerite energy into the Heart of Azeroth, then expel that energy outward, dealing m1*10 Fire damage to all enemies in front of you over 3 seconds.
  SpellInfo(focused_azerite_beam_2 cd=90 duration=3 channel=3 tick=0.33)
  SpellAddBuff(focused_azerite_beam_2 focused_azerite_beam_0=1)
  SpellAddBuff(focused_azerite_beam_2 focused_azerite_beam_1=1)
Define(focused_azerite_beam_3 299338)
# Focus excess Azerite energy into the Heart of Azeroth, then expel that energy outward, dealing m1*10 Fire damage to all enemies in front of you over 3 seconds. Castable while moving.
  SpellInfo(focused_azerite_beam_3 cd=90 duration=3 channel=3 tick=0.33)
  SpellAddBuff(focused_azerite_beam_3 focused_azerite_beam_0=1)
  SpellAddBuff(focused_azerite_beam_3 focused_azerite_beam_1=1)
Define(frost_fever 195621)
# Grants the Death Knight s2 runic power.
  SpellInfo(frost_fever channel=0 gcd=0 offgcd=1)

Define(frost_strike 49143)
# Chill your ?owb==0[weapon with icy power and quickly strike the enemy, dealing <2hDamage> Frost damage.][weapons with icy power and quickly strike the enemy with both, dealing a total of <dualWieldDamage> Frost damage.]
# Rank 2: Increases damage done by s1.
  SpellInfo(frost_strike runicpower=25)

Define(frostscythe 207230)
# A sweeping attack that strikes up to s5 enemies in front of you for s2 Frost damage. This attack benefits from Killing Machine. Critical strikes with Frostscythe deal s3 times normal damage.
  SpellInfo(frostscythe runes=1 runicpower=-10 talent=frostscythe_talent)
Define(frostwyrms_fury 279302)
# Summons a frostwyrm who breathes on all enemies within s1 yd in front of you, dealing 279303s1 Frost damage and slowing movement speed by (25 of Spell Power) for 10 seconds.
  SpellInfo(frostwyrms_fury cd=180 duration=10)
Define(frozen_pulse_buff 195750)
# While you have fewer than m2 full LRune:Runes;, your auto attacks radiate intense cold, inflicting 195750s1 Frost damage on all nearby enemies.
  SpellInfo(frozen_pulse_buff gcd=0 offgcd=1)
Define(glacial_advance 194913)
# Summon glacial spikes from the ground that advance forward, each dealing 195975s1*<CAP>/AP Frost damage and applying Razorice to enemies near their eruption point.
  SpellInfo(glacial_advance runicpower=30 cd=6 talent=glacial_advance_talent)
Define(guardian_of_azeroth_0 295840)
# Call upon Azeroth to summon a Guardian of Azeroth for 30 seconds who impales your target with spikes of Azerite every s1/10.1 sec that deal 295834m1*(1+@versadmg) Fire damage.?a295841[ Every 303347t1 sec, the Guardian launches a volley of Azerite Spikes at its target, dealing 295841s1 Fire damage to all nearby enemies.][]?a295843[rnrnEach time the Guardian of Azeroth casts a spell, you gain 295855s1 Haste, stacking up to 295855u times. This effect ends when the Guardian of Azeroth despawns.][]rn
  SpellInfo(guardian_of_azeroth_0 cd=180 duration=30)
  SpellAddBuff(guardian_of_azeroth_0 guardian_of_azeroth_0=1)
Define(guardian_of_azeroth_1 295855)
# Each time the Guardian of Azeroth casts a spell, you gain 295855s1 Haste, stacking up to 295855u times. This effect ends when the Guardian of Azeroth despawns.
  SpellInfo(guardian_of_azeroth_1 duration=60 max_stacks=5 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(guardian_of_azeroth_1 guardian_of_azeroth_1=1)
Define(guardian_of_azeroth_2 299355)
# Call upon Azeroth to summon a Guardian of Azeroth for 30 seconds who impales your target with spikes of Azerite every 295840s1/10.1 sec that deal 295834m1*(1+@versadmg)*(1+(295836m1/100)) Fire damage. Every 303347t1 sec, the Guardian launches a volley of Azerite Spikes at its target, dealing 295841s1 Fire damage to all nearby enemies.
  SpellInfo(guardian_of_azeroth_2 cd=180 duration=30 gcd=1)
  SpellAddBuff(guardian_of_azeroth_2 guardian_of_azeroth_2=1)
Define(guardian_of_azeroth_3 299358)
# Call upon Azeroth to summon a Guardian of Azeroth for 30 seconds who impales your target with spikes of Azerite every 295840s1/10.1 sec that deal 295834m1*(1+@versadmg)*(1+(295836m1/100)) Fire damage. Every 303347t1 sec, the Guardian launches a volley of Azerite Spikes at its target, dealing 295841s1 Fire damage to all nearby enemies.rnrnEach time the Guardian of Azeroth casts a spell, you gain 295855s1 Haste, stacking up to 295855u times. This effect ends when the Guardian of Azeroth despawns.
  SpellInfo(guardian_of_azeroth_3 cd=180 duration=20 gcd=1)
  SpellAddBuff(guardian_of_azeroth_3 guardian_of_azeroth_3=1)
Define(guardian_of_azeroth_4 300091)
# Call upon Azeroth to summon a Guardian of Azeroth to aid you in combat for 30 seconds.
  SpellInfo(guardian_of_azeroth_4 cd=300 duration=30 gcd=1)
Define(guardian_of_azeroth_5 303347)
  SpellInfo(guardian_of_azeroth_5 gcd=0 offgcd=1 tick=8)

Define(heart_strike 206930)
# Instantly strike the target and 1 other nearby enemy, causing s2 Physical damage, and reducing enemies' movement speed by s5 for 8 seconds?s316575[rnrn|cFFFFFFFFGenerates s3 bonus Runic Power][]?s221536[, plus 210738s1/10 Runic Power per additional enemy struck][].|r
# Rank 3: Increases damage done by s1.
  SpellInfo(heart_strike runes=1 runicpower=-10 duration=8)
  # Movement speed reduced by s5.
  SpellAddTargetDebuff(heart_strike heart_strike=1)
Define(hemostasis_buff 273947)
# Each enemy hit by Blood Boil increases the damage and healing done by your next Death Strike by 273947s1, stacking up to 273947u times.
  SpellInfo(hemostasis_buff duration=15 max_stacks=5 gcd=0 offgcd=1)
  # Damage and healing done by your next Death Strike increased by s1.
  SpellAddBuff(hemostasis_buff hemostasis_buff=1)
Define(horn_of_winter 57330)
# Blow the Horn of Winter, gaining s1 LRune:Runes; and generating s2/10 Runic Power.
  SpellInfo(horn_of_winter cd=45 runes=-2 runicpower=-25 talent=horn_of_winter_talent)
Define(howling_blast 49184)
# Blast the target with a frigid wind, dealing s1*<CAP>/AP ?s204088[Frost damage and applying Frost Fever to the target.][Frost damage to that foe, and reduced damage to all other enemies within 237680A1 yards, infecting all targets with Frost Fever.]rnrn|Tinterfaceiconsspell_deathknight_frostfever.blp:24|t |cFFFFFFFFFrost Fever|rrnA disease that deals o1*<CAP>/AP Frost damage over 24 seconds and has a chance to grant the Death Knight 195617m1/10 Runic Power each time it deals damage.
  SpellInfo(howling_blast runes=1 runicpower=-10)
Define(icy_citadel_buff 272719)
# When Pillar of Frost expires, your Strength is increased by s1 for 6 seconds. This effect lasts s2/1000 sec longer for each Obliterate and Frostscythe critical strike during Pillar of Frost.
  SpellInfo(icy_citadel_buff channel=-0.001 gcd=0 offgcd=1)

Define(icy_talons_buff 194879)
# Your Runic Power spending abilities increase your melee attack speed by 194879s1 for 6 seconds, stacking up to 194879u times.
  SpellInfo(icy_talons_buff duration=6 max_stacks=3 gcd=0 offgcd=1)
  # Attack speed increased s1.
  SpellAddBuff(icy_talons_buff icy_talons_buff=1)
Define(killing_machine_buff 51124)
# Your auto attack has a chance to cause your next Obliterate ?s207230[or Frostscythe ][]to be a guaranteed critical strike.
  SpellInfo(killing_machine_buff duration=10 max_stacks=1 gcd=0 offgcd=1)
  # Guaranteed critical strike on your next Obliterate?s207230[ or Frostscythe][].
  SpellAddBuff(killing_machine_buff killing_machine_buff=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)

Define(marrowrend 195182)
# Smash the target, dealing s2 Physical damage and generating s3 charges of Bone Shield.rnrn|Tinterfaceiconsability_deathknight_boneshield.blp:24|t |cFFFFFFFFBone Shield|rrnSurrounds you with a barrier of whirling bones, increasing Armor by s1*STR/100?s316746[, and your Haste by s4][]. Each melee attack against you consumes a charge. Lasts 30 seconds or until all charges are consumed.
# Rank 2: Bone Shield increases your Haste by s1.
  SpellInfo(marrowrend runes=2 runicpower=-20)
Define(memory_of_lucid_dreams_0 299300)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams_0)
Define(memory_of_lucid_dreams_1 299302)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams_1)
Define(memory_of_lucid_dreams_2 299304)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams_2)
Define(mind_freeze 47528)
# Smash the target's mind with cold, interrupting spellcasting and preventing any spell in that school from being cast for 3 seconds.
  SpellInfo(mind_freeze cd=15 duration=3 gcd=0 offgcd=1 interrupt=1)
Define(obliterate 49020)
# A brutal attack ?owb==0[that deals <2hDamage> Physical damage.][with both weapons that deals a total of <dualWieldDamage> Physical damage.]
# Rank 2: Increases damage done by s1.
  SpellInfo(obliterate runes=2 runicpower=-20)

Define(outbreak 77575)
# Deals s1 Shadow damage to the target and infects all nearby enemies with Virulent Plague.rnrn|Tinterfaceiconsability_creature_disease_02.blp:24|t |cFFFFFFFFVirulent Plague|rrnA disease that deals o Shadow damage over 27 seconds. It erupts when the infected target dies, dealing 191685s1 Shadow damage to nearby enemies.
  SpellInfo(outbreak runes=1 runicpower=-10)
  # Suffering w1 Shadow damage every t1 sec.rnErupts for 191685s1 damage split among all nearby enemies when the infected dies.
  SpellAddTargetDebuff(outbreak virulent_plague=1)
Define(pillar_of_frost 51271)
# The power of frost increases your Strength by s1 for 12 seconds.rnrnEach Rune spent while active increases your Strength by an additional s2.
# Rank 2: Increases Strength by s1.
  SpellInfo(pillar_of_frost cd=60 duration=12 gcd=0 offgcd=1)
  # Strength increased by w1.
  SpellAddBuff(pillar_of_frost pillar_of_frost=1)
Define(purifying_blast_0 295337)
# Call down a purifying beam upon the target area, dealing 295293s3*(1+@versadmg)*s2 Fire damage over 6 seconds.?a295364[ Has a low chance to immediately annihilate any specimen deemed unworthy by MOTHER.][]?a295352[rnrnWhen an enemy dies within the beam, your damage is increased by 295354s1 for 8 seconds.][]rnrnAny Aberration struck by the beam is stunned for 3 seconds.
  SpellInfo(purifying_blast_0 cd=60 duration=6)
Define(purifying_blast_1 295338)
# Call down a purifying beam upon the target area, dealing 295293s3*(1+@versadmg)*s2 Fire damage over 6 seconds.?a295364[ Has a low chance to immediately annihilate any specimen deemed unworthy by MOTHER.][]?a295352[rnrnWhen an enemy dies within the beam, your damage is increased by 295354s1 for 8 seconds.][]rnrnAny Aberration struck by the beam is stunned for 3 seconds.
  SpellInfo(purifying_blast_1 channel=0 gcd=0 offgcd=1)
Define(purifying_blast_2 295354)
# When an enemy dies within the beam, your damage is increased by 295354s1 for 8 seconds.
  SpellInfo(purifying_blast_2 duration=8 gcd=0 offgcd=1)
  # Damage dealt increased by s1.
  SpellAddBuff(purifying_blast_2 purifying_blast_2=1)
Define(purifying_blast_3 295366)
# Call down a purifying beam upon the target area, dealing 295293s3*(1+@versadmg)*s2 Fire damage over 6 seconds.?a295364[ Has a low chance to immediately annihilate any specimen deemed unworthy by MOTHER.][]?a295352[rnrnWhen an enemy dies within the beam, your damage is increased by 295354s1 for 8 seconds.][]rnrnAny Aberration struck by the beam is stunned for 3 seconds.
  SpellInfo(purifying_blast_3 duration=3 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(purifying_blast_3 purifying_blast_3=1)
Define(purifying_blast_4 299345)
# Call down a purifying beam upon the target area, dealing 295293s3*(1+@versadmg)*s2 Fire damage over 6 seconds. Has a low chance to immediately annihilate any specimen deemed unworthy by MOTHER.?a295352[rnrnWhen an enemy dies within the beam, your damage is increased by 295354s1 for 8 seconds.][]rnrnAny Aberration struck by the beam is stunned for 3 seconds.
  SpellInfo(purifying_blast_4 cd=60 duration=6 channel=6 gcd=1)
Define(purifying_blast_5 299347)
# Call down a purifying beam upon the target area, dealing 295293s3*(1+@versadmg)*s2 Fire damage over 6 seconds. Has a low chance to immediately annihilate any specimen deemed unworthy by MOTHER.rnrnWhen an enemy dies within the beam, your damage is increased by 295354s1 for 8 seconds.rnrnAny Aberration struck by the beam is stunned for 3 seconds.
  SpellInfo(purifying_blast_5 cd=60 duration=6 gcd=1)
Define(raise_dead 46585)
# Raises a ?s58640[geist][ghoul] to fight by your side.  You can have a maximum of one ?s58640[geist][ghoul] at a time.  Lasts 60 seconds.
# Rank 2: Raises ?s207313[an abomination]?s58640[a geist][a ghoul] to fight by your side. You can have a maximum of one ?s207313[abomination]?s58640[geist][ghoul] at a time.
  SpellInfo(raise_dead cd=120 duration=60 gcd=0 offgcd=1)
Define(razor_coral_0 303564)
# ?a303565[Remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.][Deal 304877s1*(1+@versadmg) Physical damage and apply Razor Coral to your target, giving your damaging abilities against the target a high chance to deal 304877s1*(1+@versadmg) Physical damage and add a stack of Razor Coral.rnrnReactivating this ability will remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.]
  SpellInfo(razor_coral_0 cd=20 channel=0 gcd=0 offgcd=1)
Define(razor_coral_1 303565)
# ?a303565[Remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.][Deal 304877s1*(1+@versadmg) Physical damage and apply Razor Coral to your target, giving your damaging abilities against the target a high chance to deal 304877s1*(1+@versadmg) Physical damage and add a stack of Razor Coral.rnrnReactivating this ability will remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.]rn
  SpellInfo(razor_coral_1 duration=120 max_stacks=100 gcd=0 offgcd=1)
  SpellAddBuff(razor_coral_1 razor_coral_1=1)
Define(razor_coral_2 303568)
# ?a303565[Remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.][Deal 304877s1*(1+@versadmg) Physical damage and apply Razor Coral to your target, giving your damaging abilities against the target a high chance to deal 304877s1*(1+@versadmg) Physical damage and add a stack of Razor Coral.rnrnReactivating this ability will remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.]rn
  SpellInfo(razor_coral_2 duration=120 max_stacks=100 gcd=0 offgcd=1)
  # Withdrawing the Razor Coral will grant w1 Critical Strike.
  SpellAddTargetDebuff(razor_coral_2 razor_coral_2=1)
Define(razor_coral_3 303570)
# ?a303565[Remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.][Deal 304877s1*(1+@versadmg) Physical damage and apply Razor Coral to your target, giving your damaging abilities against the target a high chance to deal 304877s1*(1+@versadmg) Physical damage and add a stack of Razor Coral.rnrnReactivating this ability will remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.]rn
  SpellInfo(razor_coral_3 duration=20 channel=20 max_stacks=100 gcd=0 offgcd=1)
  # Critical Strike increased by w1.
  SpellAddBuff(razor_coral_3 razor_coral_3=1)
Define(razor_coral_4 303572)
# ?a303565[Remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.][Deal 304877s1*(1+@versadmg) Physical damage and apply Razor Coral to your target, giving your damaging abilities against the target a high chance to deal 304877s1*(1+@versadmg) Physical damage and add a stack of Razor Coral.rnrnReactivating this ability will remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.]rn
  SpellInfo(razor_coral_4 channel=0 gcd=0 offgcd=1)
Define(razorice 51714)
# Engrave your weapon with a rune that causes 50401s1 extra weapon damage as Frost damage and increases enemies' vulnerability to your Frost attacks by 51714s1, stacking up to 51714u times. ?a332944[][rnrnModifying your rune requires a Runeforge in Ebon Hold.]
  SpellInfo(razorice duration=20 max_stacks=5 gcd=0 offgcd=1 tick=1)
  # Frost damage taken from the Death Knight's abilities increased by s1.
  SpellAddTargetDebuff(razorice razorice=1)
Define(reaping_flames_0 310690)
# Burn your target with a bolt of Azerite, dealing 310712s3 Fire damage. If the target has less than s2 health?a310705[ or more than 310705s1 health][], the cooldown is reduced by s3 sec.?a310710[rnrnIf Reaping Flames kills an enemy, its cooldown is lowered to 310710s2 sec and it will deal 310710s1 increased damage on its next use.][]
  SpellInfo(reaping_flames_0 cd=45 channel=0)
Define(reaping_flames_1 311194)
# Burn your target with a bolt of Azerite, dealing 310712s3 Fire damage. If the target has less than s2 health or more than 310705s1 health, the cooldown is reduced by m3 sec.
  SpellInfo(reaping_flames_1 cd=45 channel=0)
Define(reaping_flames_2 311195)
# Burn your target with a bolt of Azerite, dealing 310712s3 Fire damage. If the target has less than s2 health or more than 310705s1 health, the cooldown is reduced by m3 sec.rnrnIf Reaping Flames kills an enemy, its cooldown is lowered to 310710s2 sec and it will deal 310710s1 increased damage on its next use. 
  SpellInfo(reaping_flames_2 cd=45 channel=0)
Define(reaping_flames_3 311202)
# Burn your target with a bolt of Azerite, dealing 310712s3 Fire damage. If the target has less than s2 health?a310705[ or more than 310705s1 health][], the cooldown is reduced by s3 sec.?a310710[rnrnIf Reaping Flames kills an enemy, its cooldown is lowered to 310710s2 sec and it will deal 310710s1 increased damage on its next use.][]
  SpellInfo(reaping_flames_3 duration=30 gcd=0 offgcd=1)
  # Damage of next Reaping Flames increased by w1.
  SpellAddBuff(reaping_flames_3 reaping_flames_3=1)
Define(reaping_flames_4 311947)
  SpellInfo(reaping_flames_4 duration=2 gcd=0 offgcd=1)
  SpellAddTargetDebuff(reaping_flames_4 reaping_flames_4=1)
Define(reckless_force_buff_0 298409)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 4 seconds.
  SpellInfo(reckless_force_buff_0 max_stacks=5 gcd=0 offgcd=1 tick=10)
  # Gaining unstable Azerite energy.
  SpellAddBuff(reckless_force_buff_0 reckless_force_buff_0=1)
Define(reckless_force_buff_1 304038)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 4 seconds.
  SpellInfo(reckless_force_buff_1 channel=-0.001 gcd=0 offgcd=1)
  SpellAddBuff(reckless_force_buff_1 reckless_force_buff_1=1)
Define(reckless_force_counter 302917)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 4 seconds.
  SpellInfo(reckless_force_counter duration=60 channel=60 max_stacks=20 gcd=0 offgcd=1)
  # Upon reaching u stacks, you gain 302932s~1 Critical Strike for 302932d.
  SpellAddBuff(reckless_force_counter reckless_force_counter=1)
Define(remorseless_winter 196770)
# Drain the warmth of life from all nearby enemies within 196771A1 yards, dealing 9*196771s1*<CAP>/AP Frost damage over 8 seconds and reducing their movement speed by 211793s1.
# Rank 2: Increases damage done by s1.
  SpellInfo(remorseless_winter runes=1 runicpower=-10 cd=20 duration=8 tick=1)
  # Dealing 196771s1 Frost damage to enemies within 196771A1 yards each second.
  SpellAddBuff(remorseless_winter remorseless_winter=1)
Define(rime_buff 59052)
# Your next Howling Blast will consume no Runes, generate no Runic Power, and deal s2 additional damage.
  SpellInfo(rime_buff duration=15 max_stacks=1 gcd=0 offgcd=1)
  # Your next Howling Blast will consume no Runes, generate no Runic Power, and deals s2 additional damage.
  SpellAddBuff(rime_buff rime_buff=1)
Define(ripple_in_space_0 299306)
# Infuse your Heart of Azeroth with Ripple in Space.
  SpellInfo(ripple_in_space_0)
Define(ripple_in_space_1 299307)
# Infuse your Heart of Azeroth with Ripple in Space.
  SpellInfo(ripple_in_space_1)
Define(ripple_in_space_2 299309)
# Infuse your Heart of Azeroth with Ripple in Space.
  SpellInfo(ripple_in_space_2)
Define(ripple_in_space_3 299310)
# Infuse your Heart of Azeroth with Ripple in Space.
  SpellInfo(ripple_in_space_3)
Define(scourge_strike 55090)
# An unholy strike that deals s2 Physical damage and 70890sw2 Shadow damage, and causes 1 Festering Wound to burst.
# Rank 2: Increases damage done by s1.
  SpellInfo(scourge_strike runes=1 runicpower=-10)

Define(seething_rage 297126)
# Increases your critical hit damage by 297126m for 5 seconds.
  SpellInfo(seething_rage duration=5 gcd=0 offgcd=1)
  # Critical strike damage increased by w1.
  SpellAddBuff(seething_rage seething_rage=1)
Define(soul_reaper 343294)
# Strike an enemy for s1 Shadow damage and afflict the enemy with Soul Reaper. rnrnAfter 5 seconds, if the target is below s3 health this effect will explode dealing an additional 343295s1 Shadow damage to the target. If the enemy that yields experience or honor dies while afflicted by Soul Reaper, gain Runic Corruption.
  SpellInfo(soul_reaper runes=1 runicpower=-10 cd=6 duration=5 tick=5 talent=soul_reaper_talent)
  # Afflicted by Soul Reaper, if the target is below s3 health this effect will explode dealing an additional 343295s1 Shadow damage.
  SpellAddTargetDebuff(soul_reaper soul_reaper=1)
Define(sudden_doom_buff 81340)
# Your auto attacks have a chance to make your next Death Coil?s207317[ or Epidemic][] cost no Runic Power.
  SpellInfo(sudden_doom_buff duration=10 max_stacks=1 gcd=0 offgcd=1)
  # Your next Death Coil?s207317[ or Epidemic][] consumes no Runic Power.
  SpellAddBuff(sudden_doom_buff sudden_doom_buff=1)
Define(summon_gargoyle 49206)
# Summon a Gargoyle into the area to bombard the target for 30 seconds.rnrnThe Gargoyle gains 211947s1 increased damage for every s4 Runic Power you spend.
  SpellInfo(summon_gargoyle cd=180 duration=35 talent=summon_gargoyle_talent)

Define(the_unbound_force_0 299321)
# Infuse your Heart of Azeroth with The Unbound Force.
  SpellInfo(the_unbound_force_0)
Define(the_unbound_force_1 299322)
# Infuse your Heart of Azeroth with The Unbound Force.
  SpellInfo(the_unbound_force_1)
Define(the_unbound_force_2 299323)
# Infuse your Heart of Azeroth with The Unbound Force.
  SpellInfo(the_unbound_force_2)
Define(the_unbound_force_3 299324)
# Infuse your Heart of Azeroth with The Unbound Force.
  SpellInfo(the_unbound_force_3)
Define(tombstone 219809)
# Consume up to s5 Bone Shield charges. For each charge consumed, you gain s3 Runic Power and absorb damage equal to s4 of your maximum health for 8 seconds.
  SpellInfo(tombstone cd=60 duration=8 runicpower=0 talent=tombstone_talent)
  # Absorbing w1 damage.
  SpellAddBuff(tombstone tombstone=1)
Define(unholy_assault 207289)
# Strike your target dealing s2 Shadow damage, infecting the target with s3 Festering Wounds and sending you into an Unholy Frenzy increasing haste by s1 for 12 seconds.
  SpellInfo(unholy_assault cd=75 duration=12 talent=unholy_assault_talent)
  # Haste increased by s1.
  SpellAddBuff(unholy_assault unholy_assault=1)
Define(unholy_blight 115989)
# Surrounds yourself with a vile swarm of insects for 6 seconds, stinging all nearby enemies and infecting them with Virulent Plague and an unholy disease that deals 115994o1 damage over 14 seconds, stacking up to 115994u times.rnrnYour minions deal 115994s2 increased damage per stack to enemies infected by Unholy Blight.
  SpellInfo(unholy_blight runes=1 runicpower=-10 cd=45 duration=6 tick=1 talent=unholy_blight_talent)
  # Surrounded by a vile swarm of insects, infecting enemies within 115994a1 yds with Virulent Plauge and an unholy disease that increases the damage your minions deal to them.
  SpellAddBuff(unholy_blight unholy_blight=1)
Define(unholy_strength 53365)
# Affixes your rune weapon with a rune that has a chance to heal you for 53365s2 and increase total Strength by 53365s1 for 15 seconds.
  SpellInfo(unholy_strength duration=15 max_stacks=1 gcd=0 offgcd=1)
  # Strength increased by s1.
  SpellAddBuff(unholy_strength unholy_strength=1)
Define(vampiric_blood 55233)
# Embrace your undeath, increasing your maximum health by s4 and increasing all healing and absorbs received by s1 for 10 seconds.
# Rank 2: Increases all healing and absorbs by s1 and duration by s3/1000 sec.
  SpellInfo(vampiric_blood cd=90 duration=10 gcd=0 offgcd=1)
  # Maximum health increased by s4. Healing and absorbs received increased by s1.
  SpellAddBuff(vampiric_blood vampiric_blood=1)
Define(virulent_plague 191587)
# A disease that deals o Shadow damage over 27 seconds. It erupts when the infected target dies, dealing 191685s1 Shadow damage to nearby enemies.
  SpellInfo(virulent_plague duration=27 channel=27 gcd=0 offgcd=1 tick=3)
  # Suffering w1 Shadow damage every t1 sec.rnErupts for 191685s1 damage split among all nearby enemies when the infected dies.
  SpellAddTargetDebuff(virulent_plague virulent_plague=1)
Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp=1)
Define(worldvein_resonance_0 298606)
# Infuse your Heart of Azeroth with Worldvein Resonance.
  SpellInfo(worldvein_resonance_0)
Define(worldvein_resonance_1 298607)
# Infuse your Heart of Azeroth with Worldvein Resonance.
  SpellInfo(worldvein_resonance_1)
Define(worldvein_resonance_2 298609)
# Infuse your Heart of Azeroth with Worldvein Resonance.
  SpellInfo(worldvein_resonance_2)
Define(worldvein_resonance_3 298611)
# Infuse your Heart of Azeroth with Worldvein Resonance.
  SpellInfo(worldvein_resonance_3)
SpellList(anima_of_death anima_of_death_0 anima_of_death_1 anima_of_death_2 anima_of_death_3)
SpellList(arcane_torrent arcane_torrent_0 arcane_torrent_1 arcane_torrent_2 arcane_torrent_3 arcane_torrent_4 arcane_torrent_5 arcane_torrent_6 arcane_torrent_7 arcane_torrent_8)
SpellList(blood_fury blood_fury_0 blood_fury_1 blood_fury_2 blood_fury_3)
SpellList(concentrated_flame concentrated_flame_0 concentrated_flame_1 concentrated_flame_2 concentrated_flame_3 concentrated_flame_4 concentrated_flame_5 concentrated_flame_6)
SpellList(death_and_decay death_and_decay_0 death_and_decay_1)
SpellList(fireblood fireblood_0 fireblood_1)
SpellList(memory_of_lucid_dreams memory_of_lucid_dreams_0 memory_of_lucid_dreams_1 memory_of_lucid_dreams_2)
SpellList(razor_coral razor_coral_0 razor_coral_1 razor_coral_2 razor_coral_3 razor_coral_4)
SpellList(ripple_in_space ripple_in_space_0 ripple_in_space_1 ripple_in_space_2 ripple_in_space_3)
SpellList(worldvein_resonance worldvein_resonance_0 worldvein_resonance_1 worldvein_resonance_2 worldvein_resonance_3)
SpellList(blood_of_the_enemy blood_of_the_enemy_0 blood_of_the_enemy_1 blood_of_the_enemy_2 blood_of_the_enemy_3)
SpellList(chill_streak chill_streak_0 chill_streak_1)
SpellList(focused_azerite_beam focused_azerite_beam_0 focused_azerite_beam_1 focused_azerite_beam_2 focused_azerite_beam_3)
SpellList(guardian_of_azeroth guardian_of_azeroth_0 guardian_of_azeroth_1 guardian_of_azeroth_2 guardian_of_azeroth_3 guardian_of_azeroth_4 guardian_of_azeroth_5)
SpellList(ineffable_truth )
SpellList(purifying_blast purifying_blast_0 purifying_blast_1 purifying_blast_2 purifying_blast_3 purifying_blast_4 purifying_blast_5)
SpellList(reaping_flames reaping_flames_0 reaping_flames_1 reaping_flames_2 reaping_flames_3 reaping_flames_4)
SpellList(reckless_force_buff reckless_force_buff_0 reckless_force_buff_1)
SpellList(the_unbound_force the_unbound_force_0 the_unbound_force_1 the_unbound_force_2 the_unbound_force_3)
Define(army_of_the_damned_talent 19) #22030
# ?s207317[Death Coil and Epidemic reduce][Death Coil reduces] the cooldown of Apocalypse by <cd1> sec and Army of the Dead by <cd2> sec. rnrnAdditionally Apocalypse and Army of the Dead summon a Magus of the Dead for 15 seconds who hurls Frostbolts and Shadow Bolts at your foes.rn
Define(asphyxiate_talent_unholy 9) #22520
# Lifts the enemy target off the ground, crushing their throat with dark energy and stunning them for 4 seconds.
Define(blinding_sleet_talent 9) #22519
# Targets in a cone in front of you are blinded, causing them to wander disoriented for 5 seconds. Damage may cancel the effect.rnrnWhen Blinding Sleet ends, enemies are slowed by 317898s1 for 6 seconds.
Define(blooddrinker_talent 2) #19166
# Drains o1 health from the target over 3 seconds.rnrnYou can move, parry, dodge, and use defensive abilities while channeling this ability.
Define(bonestorm_talent 21) #21209
# A whirl of bone and gore batters up to 196528s2 nearby enemies, dealing 196528s1 Shadow damage every t3 sec, and healing you for 196545s1 of your maximum health every time it deals damage (up to s1*s4). Lasts t3 sec per s3 Runic Power spent.
Define(breath_of_sindragosa_talent 21) #22537
# Continuously deal 155166s2*<CAP>/AP Frost damage every t1 sec to enemies in a cone in front of you, until your Runic Power is exhausted. Deals reduced damage to secondary targets.rnrn|cFFFFFFFFGenerates 303753s1 lRune:Runes; at the start and end.|r
Define(bursting_sores_talent 4) #22027
# Bursting a Festering Wound deals s1 more damage, and deals 207267s1 Shadow damage to 207267s3-1 nearby targets.
Define(clawing_shadows_talent 3) #22026
# Deals s2 Shadow damage and causes 1 Festering Wound to burst.
Define(cold_heart_talent 3) #22018
# Every t1 sec, gain a stack of Cold Heart, causing your next Chains of Ice to deal 281210s1 Frost damage. Stacks up to 281209u times.
Define(consumption_talent 6) #19220
# Strikes up to s3 enemies in front of you with a hungering attack that deals sw1 Physical damage and heals you for e1*100 of that damage.
Define(defile_talent 18) #22536
# Defile the targeted ground, dealing (156000s1*(10 seconds+1)/t3) Shadow damage to all enemies over 10 seconds.rnrnWhile you remain within your Defile, your ?s207311[Clawing Shadows][Scourge Strike] will hit 55090s4-1 enemies near the target?a315442|a331119[ and inflict Death's Due for 12 seconds.rnrnDeath's Due reduces damage enemies deal to you by 324164s1, up to a maximum of 324164s1*-324164u and their power is transferred to you as an equal amount of Strength.][].rnrnIf any enemies are standing in the Defile, it grows in size and deals increasing damage every sec.
Define(frostscythe_talent 12) #22525
# A sweeping attack that strikes up to s5 enemies in front of you for s2 Frost damage. This attack benefits from Killing Machine. Critical strikes with Frostscythe deal s3 times normal damage.
Define(frozen_pulse_talent 11) #22523
# While you have fewer than m2 full LRune:Runes;, your auto attacks radiate intense cold, inflicting 195750s1 Frost damage on all nearby enemies.
Define(gathering_storm_talent 16) #22531
# Each Rune spent during Remorseless Winter increases its damage by 211805s1, and extends its duration by m1/10.1 sec.
Define(glacial_advance_talent 18) #22535
# Summon glacial spikes from the ground that advance forward, each dealing 195975s1*<CAP>/AP Frost damage and applying Razorice to enemies near their eruption point.
Define(heartbreaker_talent 1) #19165
# Heart Strike generates 210738s1/10 additional Runic Power per target hit.
Define(horn_of_winter_talent 6) #22021
# Blow the Horn of Winter, gaining s1 LRune:Runes; and generating s2/10 Runic Power.
Define(icecap_talent 19) #22023
# Your Frost Strike?s207230[, Frostscythe,][] and Obliterate critical strikes reduce the remaining cooldown of Pillar of Frost by <cd> sec.
Define(obliteration_talent 20) #22109
# While Pillar of Frost is active, Frost Strike?s194913[, Glacial Advance,][] and Howling Blast always grant Killing Machine and have a s2 chance to generate a Rune.
Define(rapid_decomposition_talent 4) #19218
# Your Blood Plague and Death and Decay deal damage s2 more often.rnrnAdditionally, your Blood Plague leeches s3 more Health.
Define(runic_attenuation_talent 4) #22019
# Auto attacks have a chance to generate 221322s1/10 Runic Power.
Define(soul_reaper_talent 12) #22526
# Strike an enemy for s1 Shadow damage and afflict the enemy with Soul Reaper. rnrnAfter 5 seconds, if the target is below s3 health this effect will explode dealing an additional 343295s1 Shadow damage to the target. If the enemy that yields experience or honor dies while afflicted by Soul Reaper, gain Runic Corruption.
Define(summon_gargoyle_talent 20) #22110
# Summon a Gargoyle into the area to bombard the target for 30 seconds.rnrnThe Gargoyle gains 211947s1 increased damage for every s4 Runic Power you spend.
Define(tombstone_talent 3) #23454
# Consume up to s5 Bone Shield charges. For each charge consumed, you gain s3 Runic Power and absorb damage equal to s4 of your maximum health for 8 seconds.
Define(unholy_assault_talent 21) #22538
# Strike your target dealing s2 Shadow damage, infecting the target with s3 Festering Wounds and sending you into an Unholy Frenzy increasing haste by s1 for 12 seconds.
Define(unholy_blight_talent 6) #22029
# Surrounds yourself with a vile swarm of insects for 6 seconds, stinging all nearby enemies and infecting them with Virulent Plague and an unholy disease that deals 115994o1 damage over 14 seconds, stacking up to 115994u times.rnrnYour minions deal 115994s2 increased damage per stack to enemies infected by Unholy Blight.
Define(dribbling_inkpod_item 169319)
Define(unbridled_fury_item 169299)
Define(ashvanes_razor_coral_item 169311)
Define(corrupted_gladiators_badge_item 172669)
Define(corrupted_gladiators_medallion_item 184055)
Define(first_mates_spyglass_item 158163)
Define(jes_howler_item 159627)
Define(lurkers_insidious_gift_item 167866)
Define(notorious_gladiators_badge_item 167380)
Define(notorious_gladiators_medallion_item 167377)
Define(vial_of_animated_blood_item 159625)
Define(ramping_amplitude_gigavolt_engine_item 165580)
Define(vision_of_demise_item 169307)
Define(frozen_tempest_trait 278487)
Define(icy_citadel_trait 272718)
Define(magus_of_the_dead_trait 288417)
Define(condensed_lifeforce_essence_id 14)
Define(vision_of_perfection_essence_id 22)
    ]]
    OvaleScripts:RegisterScript("DEATHKNIGHT", nil, name, desc, code, "include")
end
