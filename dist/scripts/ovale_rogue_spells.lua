local __exports = LibStub:NewLibrary("ovale/scripts/ovale_rogue_spells", 80300)
if not __exports then return end
__exports.registerRogueSpells = function(OvaleScripts)
    local name = "ovale_rogue_spells"
    local desc = "[9.0] Ovale: Rogue spells"
    local code = [[Define(adrenaline_rush 13750)
# Increases your Energy regeneration rate by s1, your maximum Energy by s4, and your attack speed by s2 for 20 seconds.
  SpellInfo(adrenaline_rush cd=180 duration=20 gcd=0 offgcd=1)
  # Energy regeneration increased by w1.rnMaximum Energy increased by w4.rnAttack speed increased by w2.rn?w5>0[Damage increased by w5.][]
  SpellAddBuff(adrenaline_rush adrenaline_rush=1)
Define(ambush 8676)
# Ambush the target, causing s1 Physical damage.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(ambush energy=50 gcd=1 combopoints=-2)
Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
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
Define(backstab 53)
# Stab the target, causing s2*<mult> Physical damage. Damage increased by s4 when you are behind your target?s319949[, and critical strikes apply Find Weakness for 319949s1 sec][].rnrn|cFFFFFFFFAwards s3 combo lpoint:points;.|r
# Rank 2: When you are behind your target, Backstab critical strikes now also expose a flaw in their defenses, applying Find Weakness for s1 sec.
  SpellInfo(backstab energy=35 gcd=1 combopoints=-1)
Define(bag_of_tricks 312411)
# Pull your chosen trick from the bag and use it on target enemy or ally. Enemies take <damage> damage, while allies are healed for <healing>. 
  SpellInfo(bag_of_tricks cd=90)
Define(berserking 59621)
# Permanently enchant a melee weapon to sometimes increase your attack power by 59620s1, but at the cost of reduced armor. Cannot be applied to items higher than level ecix
  SpellInfo(berserking gcd=0 offgcd=1)
Define(between_the_eyes 315341)
# Finishing move that deals damage with your pistol, increasing your critical strike chance against the target by s2.?a235484[ Critical strikes with this ability deal four times normal damage.][]rn   1 point : <damage>*1 damage, 3 secrn   2 points: <damage>*2 damage, 6 secrn   3 points: <damage>*3 damage, 9 secrn   4 points: <damage>*4 damage, 12 secrn   5 points: <damage>*5 damage, 15 sec?s193531[rn   6 points: <damage>*6 damage, 18 sec][]
# Rank 2: Critical strikes with Between the Eyes deal four times normal damage.rn
  SpellInfo(between_the_eyes energy=25 combopoints=1 cd=45 gcd=1)
  # Critical strike chance taken from the Rogue increased by s2.
  SpellAddTargetDebuff(between_the_eyes between_the_eyes=1)
Define(blade_flurry 13877)
# ?s331851[Strikes up to nearby 331850i targets for 331850s1 Physical damage, and causes][Causes] your single target attacks to also strike up to s3 nearby enemies for s2 of normal damage for 12 seconds.
# Rank 2: Blade Flurry now instantly strikes up to nearby 331850i targets for 331850s1 Physical damage.
  SpellInfo(blade_flurry energy=15 cd=30 duration=12 gcd=1)
  # Attacks striking nearby enemies.
  SpellAddBuff(blade_flurry blade_flurry=1)
Define(blade_rush 271877)
# Charge to your target with your blades out, dealing 271881sw1*271881s2/100 Physical damage to the target and 271881sw1 to all other nearby enemies.rnrnWhile Blade Flurry is active, damage to non-primary targets is increased by s1.rnrn|cFFFFFFFFGenerates 271896s1*5 seconds/271896t1 Energy over 5 seconds.
  SpellInfo(blade_rush cd=45 gcd=1 talent=blade_rush_talent)
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
Define(bloodlust 2825)
# Increases haste by (25 of Spell Power) for all party and raid members for 40 seconds.rnrnAllies receiving this effect will become Sated and unable to benefit from Bloodlust or Time Warp again for 600 seconds.
  SpellInfo(bloodlust cd=300 duration=40 channel=40 gcd=0 offgcd=1)
  # Haste increased by w1.
  SpellAddBuff(bloodlust bloodlust=1)
Define(broadside 193356)
# Your combo-point generating abilities generate s1 additional combo point and deal s4 increased damage for the duration of Roll the Bones.
  SpellInfo(broadside channel=-0.001 gcd=0 offgcd=1)
  # Your combo-point generating abilities generate s1 additional combo point and deal s4 increased damage.
  SpellAddBuff(broadside broadside=1)
Define(cheap_shot 1833)
# Stuns the target for 4 seconds.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(cheap_shot energy=40 duration=4 gcd=1 combopoints=-1)
  # Stunned.
  SpellAddTargetDebuff(cheap_shot cheap_shot=1)
Define(concealed_blunderbuss 340587)
# When Sinister Strike hits an additional time, there is a s1 chance that your next Pistol Shot will fire s2 additional times.
  SpellInfo(concealed_blunderbuss duration=10 gcd=0 offgcd=1)
  # Your next Pistol Shot fires 340088s2 additional times.
  SpellAddBuff(concealed_blunderbuss concealed_blunderbuss=1)
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
Define(conductive_ink_debuff 302597)
# Your damaging abilities against enemies above M3 health have a very high chance to apply Conductive Ink. When an enemy falls below M3 health, Conductive Ink inflicts s1*(1+@versadmg) Nature damage per stack.
  SpellInfo(conductive_ink_debuff channel=0 gcd=0 offgcd=1)

Define(crimson_tempest 121411)
# Finishing move that slashes at up to s3 enemies within A1 yards, dealing instant damage and causing victims to bleed for additional damage. Lasts longer per combo point.rnrn   1 point  : s2*2 plus o1*2 over 4 secrn   2 points: s2*3 plus o1*3 over 6 secrn   3 points: s2*4 plus o1*4 over 8 secrn   4 points: s2*5 plus o1*5 over 10 secrn   5 points: s2*6 plus o1*6 over 12 sec?s193531[rn   6 points: s2*7 plus o1*7 over 14 sec][]
  SpellInfo(crimson_tempest energy=35 combopoints=1 duration=2 gcd=1 tick=2 talent=crimson_tempest_talent)
  # Bleeding for w1 damage every t1 sec.
  SpellAddTargetDebuff(crimson_tempest crimson_tempest=1)
Define(cyclotronic_blast 293491)
# Channel a cyclotronic blast, dealing a total of o1 Fire damage over D.
  SpellInfo(cyclotronic_blast cd=120 duration=2.5 channel=2.5 tick=0.5)
  # Burning for o1 Fire damage.
  SpellAddTargetDebuff(cyclotronic_blast cyclotronic_blast=1)
Define(deadshot_buff 272936)
# Mutilate has a s1 chance to apply additional Deadly Poison, and does s2*2 additional damage.rnrn|C000FFF00Assassination|R
  SpellInfo(deadshot_buff channel=-0.001 gcd=0 offgcd=1)

Define(deathly_shadows_buff 341202)
# Vanish grants 341202s3 combo points and increases all damage dealt by 341202s1 for 12 seconds.
  SpellInfo(deathly_shadows_buff duration=12 gcd=0 offgcd=1 combopoints=-5)
  # Damage increased by w1.
  SpellAddBuff(deathly_shadows_buff deathly_shadows_buff=1)
Define(dispatch 2098)
# Finishing move that dispatches the enemy, dealing damage per combo point:rn   1 point  : m1*1 damagern   2 points: m1*2 damagern   3 points: m1*3 damagern   4 points: m1*4 damagern   5 points: m1*5 damage?s193531[rn   6 points: m1*6 damage][]
  SpellInfo(dispatch energy=35 combopoints=1 gcd=1)
  SpellInfo(eviscerate replaced_by=dispatch)
Define(dreadblades 343142)
# Strike at an enemy, dealing s1 Physical damage and empowering your weapons for 10 seconds, causing your Sinister Strike,?s196937[ Ghostly Strike,][]?s323654[ Slaughter,][]?s323547[ Echoing Reprimand,][]?s328547[ Serrated Bone Spike,][] Ambush, and Pistol Shot to fill your combo points, but your finishing moves consume 343145s1 of your current health.
  SpellInfo(dreadblades energy=30 cd=90 duration=10 gcd=1 talent=dreadblades_talent)
  # Sinister Strike, ?s196937[Ghostly Strike, ][]Ambush, and Pistol Shot will refill all of your combo points when used.
  SpellAddBuff(dreadblades dreadblades=1)
Define(echoing_reprimand 323547)
# Deal s1 Arcane damage to an enemy, extracting their anima to Animacharge a combo point for 45 seconds.rnrnDamaging finishing moves that consume the same number of combo points as your Animacharge function as if they consumed s2 combo points.rnrn|cFFFFFFFFAwards s3 combo lpoint:points;.|rrn
  SpellInfo(echoing_reprimand energy=0 cd=45 gcd=1 combopoints=-2)
Define(envenom 32645)
# Finishing move that drives your poisoned blades in deep, dealing instant Nature damage and increasing your poison application chance by s2. Damage and duration increased per combo point.rnrn   1 point  : m1*1 damage, 2 secrn   2 points: m1*2 damage, 3 secrn   3 points: m1*3 damage, 4 secrn   4 points: m1*4 damage, 5 secrn   5 points: m1*5 damage, 6 sec?s193531[rn   6 points: m1*6 damage, 7 sec][]
  SpellInfo(envenom energy=35 combopoints=1 duration=1 gcd=1)
  SpellInfo(eviscerate replaced_by=envenom)
  # Poison application chance increased by s2.?s340081[rnPoison critical strikes generate 340426s1 Energy.][]
  SpellAddBuff(envenom envenom=1)
Define(eviscerate 196819)
# Finishing move that disembowels the target, causing damage per combo point.?s231716[ Targets with Find Weakness suffer an additional 231716s1 damage as Shadow.][]rn   1 point  : m1*1 damagern   2 points: m1*2 damagern   3 points: m1*3 damagern   4 points: m1*4 damagern   5 points: m1*5 damage?s193531[rn   6 points: m1*6 damage][]
# Rank 2: Eviscerate deals an additional s1 damage as Shadow to targets with your Find Weakness active.
  SpellInfo(eviscerate energy=35 combopoints=1 gcd=1)
Define(exsanguinate 200806)
# Twist your blades into the target's wounds, causing your Bleed effects on them to bleed out s1 faster.
  SpellInfo(exsanguinate energy=25 cd=45 gcd=1 talent=exsanguinate_talent)
Define(fan_of_knives 51723)
# Sprays knives at up to s3 targets within A1 yards, dealing s1 Physical damage and applying your active poisons at their normal rate.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(fan_of_knives energy=35 gcd=1)
Define(find_weakness 316219)
# Cheap Shot and Shadowstrike reveal a flaw in your target's defenses, causing all of your attacks to bypass 316220s1 of that enemy's armor for 18 seconds.
  SpellInfo(find_weakness channel=0 gcd=0 offgcd=1)

Define(fireblood_0 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. ?s195710[This effect shares a 30 sec cooldown with other similar effects.][]
  SpellInfo(fireblood_0 cd=120 gcd=0 offgcd=1)
Define(fireblood_1 265226)
# Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by s1.
  SpellInfo(fireblood_1 duration=8 max_stacks=6 gcd=0 offgcd=1)
  # Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by w1.
  SpellAddBuff(fireblood_1 fireblood_1=1)
Define(flagellation_0 323654)
# Lash the target s2 times, dealing s1 Shadow damage and adding a stack of Flagellation for each lash. The target remains tormented for 20 seconds, receiving an additional lash for each combo point you spend.rnrnReactivating Flagellation cleanses their torment, increasing your Haste by 345569s2/10.1 per stack, up to a maximum of 345569s2/10*345569u Haste for 20 seconds.
  SpellInfo(flagellation_0 energy=20 cd=90 duration=20 max_stacks=30 gcd=1)
  # ?W2>0[Nearby Rogue is tormenting the target, dealing s1 Shadow damage for each combo point spent.][Combo points spent deal s1 Shadow damage to the Rogue's tormented target.]
  SpellAddBuff(flagellation_0 flagellation_0=1)
  # ?W2>0[Nearby Rogue is tormenting the target, dealing s1 Shadow damage for each combo point spent.][Combo points spent deal s1 Shadow damage to the Rogue's tormented target.]
  SpellAddTargetDebuff(flagellation_0 flagellation_0=1)
Define(flagellation_1 345316)
# Lash the target s2 times, dealing s1 Shadow damage and adding a stack of Flagellation for each lash. The target remains tormented for 20 seconds, receiving an additional lash for each combo point you spend.rnrnReactivating Flagellation cleanses their torment, increasing your Haste by 345569s2/10.1 per stack, up to a maximum of 345569s2/10*345569u Haste for 20 seconds.
  SpellInfo(flagellation_1 channel=0 gcd=0 offgcd=1)
Define(flagellation_2 345390)
# Lash the target s2 times, dealing s1 Shadow damage and adding a stack of Flagellation for each lash. The target remains tormented for 20 seconds, receiving an additional lash for each combo point you spend.rnrnReactivating Flagellation cleanses their torment, increasing your Haste by 345569s2/10.1 per stack, up to a maximum of 345569s2/10*345569u Haste for 20 seconds.
  SpellInfo(flagellation_2 channel=0 gcd=0 offgcd=1)
Define(flagellation_3 345569)
# Lash the target s2 times, dealing s1 Shadow damage and adding a stack of Flagellation for each lash. The target remains tormented for 20 seconds, receiving an additional lash for each combo point you spend.rnrnReactivating Flagellation cleanses their torment, increasing your Haste by 345569s2/10.1 per stack, up to a maximum of 345569s2/10*345569u Haste for 20 seconds.
  SpellInfo(flagellation_3 cd=5 duration=20 max_stacks=30 gcd=0 offgcd=1)
  # Haste increased by s1/10.1.
  SpellAddBuff(flagellation_3 flagellation_3=1)
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
Define(garrote 703)
# Garrote the enemy, causing o1 Bleed damage over 18 seconds.?a231719[ Silences the target for 3 seconds when used from Stealth.][]rnrn|cFFFFFFFFAwards s3 combo lpoint:points;.|r
# Rank 2: Garrote silences the target for 3 seconds when used from Stealth.rn
  SpellInfo(garrote energy=45 cd=6 duration=18 gcd=1 combopoints=-1 tick=2)
  # Suffering w1 damage every t1 seconds.
  SpellAddTargetDebuff(garrote garrote=1)
Define(ghostly_strike 196937)
# Strikes an enemy, dealing s1 Physical damage and causing the target to take s3 increased damage from your abilities for 10 seconds.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(ghostly_strike energy=30 cd=35 duration=10 gcd=1 combopoints=-1 tick=3 talent=ghostly_strike_talent)
  # Taking s3 increased damage from the Rogue's abilities.
  SpellAddTargetDebuff(ghostly_strike ghostly_strike=1)
Define(gloomblade 200758)
# Punctures your target with your shadow-infused blade for s1 Shadow damage, bypassing armor.?s319949[ Critical strikes apply Find Weakness for 319949s1 sec.][]rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(gloomblade energy=35 gcd=1 combopoints=-1 talent=gloomblade_talent)
Define(gouge 1776)
# Gouges the eyes of an enemy target, incapacitating for 4 seconds. Damage will interrupt the effect.rnrnMust be in front of your target.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(gouge energy=25 cd=15 duration=4 gcd=1 combopoints=-1)
  # Incapacitated.
  SpellAddTargetDebuff(gouge gouge=1)
Define(greenskins_wickers 340573)
# Between the Eyes has a s1 chance per Combo Point to increase the damage of your next Pistol Shot by 340573s1.
  SpellInfo(greenskins_wickers duration=15 gcd=0 offgcd=1)
  # Your next Pistol Shot deals s2 increased damage.
  SpellAddBuff(greenskins_wickers greenskins_wickers=1)
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

Define(hidden_blades 270061)
# Every t1 sec, gain 270070s1 increased damage for your next Fan of Knives, stacking up to 270070u times.
  SpellInfo(hidden_blades channel=0 gcd=0 offgcd=1 tick=2 talent=hidden_blades_talent)
  SpellAddBuff(hidden_blades hidden_blades=1)
Define(keep_your_wits_about_you_buff 288985)
# When an attack Blade Flurries, increase the chance for Sinister Strike to strike again by s1. Additional strikes of Sinister Strike deal s2 more damage.
  SpellInfo(keep_your_wits_about_you_buff channel=-0.001 gcd=0 offgcd=1)

Define(kick 1766)
# A quick kick that interrupts spellcasting and prevents any spell in that school from being cast for 5 seconds.
  SpellInfo(kick cd=15 duration=5 gcd=0 offgcd=1 interrupt=1)
Define(kidney_shot 408)
# Finishing move that stuns the target. Lasts longer per combo point:rn   1 point  : 2 secondsrn   2 points: 3 secondsrn   3 points: 4 secondsrn   4 points: 5 secondsrn   5 points: 6 seconds?s193531[rn   6 points: 7 seconds][]
  SpellInfo(kidney_shot energy=25 combopoints=1 cd=20 duration=1 gcd=1)
  # Stunned.
  SpellAddTargetDebuff(kidney_shot kidney_shot=1)
Define(killing_spree 51690)
# Teleport to an enemy within 10 yards, attacking with both weapons for a total of <dmg> Physical damage over 2 seconds.rnrnWhile Blade Flurry is active, also hits up to s5 nearby enemies for s2 damage.
  SpellInfo(killing_spree cd=120 duration=2 gcd=1 tick=0.4 talent=killing_spree_talent)
  # Attacking an enemy every t1 sec.
  SpellAddBuff(killing_spree killing_spree=1)
Define(latent_arcana 296971)
# Channel latent magic for up to 4 seconds, increasing your primary stat by s1. The duration is extended for each second spent channeling, up to M4 sec.
  SpellInfo(latent_arcana cd=120 duration=4 channel=4 tick=1)
  # Infusing your body with arcane energies.
  SpellAddBuff(latent_arcana latent_arcana=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)

Define(marked_for_death 137619)
# Marks the target, instantly generating s1 combo points. Cooldown reset if the target dies within 60 seconds.
  SpellInfo(marked_for_death cd=60 duration=60 channel=60 gcd=0 offgcd=1 combopoints=-5 talent=marked_for_death_talent)

  # Marked for Death will reset upon death.
  SpellAddTargetDebuff(marked_for_death marked_for_death=1)
Define(memory_of_lucid_dreams_0 299300)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams_0)
Define(memory_of_lucid_dreams_1 299302)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams_1)
Define(memory_of_lucid_dreams_2 299304)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams_2)
Define(mutilate 1329)
# Attack with both weapons, dealing a total of <dmg> Physical damage.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(mutilate energy=50 gcd=1 combopoints=-2)

Define(opportunity 195627)
# Viciously strike an enemy, causing s1*<mult> Physical damage.?s279876[rnrnHas a s3 chance to hit an additional time, making your next Pistol Shot half cost and double damage.][]rnrn|cFFFFFFFFAwards s2 combo lpoint:points; each time it strikes.|r
  SpellInfo(opportunity duration=10 gcd=0 offgcd=1)
  # Your next Pistol Shot costs s1 less Energy and deals s3 increased damage.
  SpellAddBuff(opportunity opportunity=1)
Define(perforated_veins_buff 341572)
# Shadowstrike increases the damage of your next ?s200758[Gloomblade][Backstab] by |cFFFFFFFFs1|r, stacking up to 341572u times.
  SpellInfo(perforated_veins_buff duration=12 max_stacks=6 gcd=0 offgcd=1)
  # Damage of your next ?s200758[Gloomblade][Backstab] increased by w1.
  SpellAddBuff(perforated_veins_buff perforated_veins_buff=1)
Define(pistol_shot 185763)
# Draw a concealed pistol and fire a quick shot at an enemy, dealing s1*<CAP>/AP Physical damage and reducing movement speed by s3 for 6 seconds.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(pistol_shot energy=40 duration=6 gcd=1 combopoints=-1)
  # Movement speed reduced by s3.
  SpellAddTargetDebuff(pistol_shot pistol_shot=1)
Define(premeditation 343160)
# After entering Stealth, your next Shadowstrike grants up to s1 sec of Slice and Dice, and generates s2 additional combo points if Slice and Dice is active.
  SpellInfo(premeditation channel=0 gcd=0 offgcd=1 talent=premeditation_talent)
  SpellAddTargetDebuff(premeditation premeditation=1)
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
Define(quaking_palm 107079)
# Strikes the target with lightning speed, incapacitating them for 4 seconds, and turns off your attack.
  SpellInfo(quaking_palm cd=120 duration=4 gcd=1)
  # Incapacitated.
  SpellAddTargetDebuff(quaking_palm quaking_palm=1)
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
Define(roll_the_bones 315508)
# Roll the dice of fate, providing a random combat enhancement for 30 seconds.
  SpellInfo(roll_the_bones energy=25 cd=45 duration=30 channel=30 gcd=1)
  # Gained a random combat enhancement.
  SpellAddBuff(roll_the_bones roll_the_bones=1)
Define(rupture 1943)
# Finishing move that tears open the target, dealing Bleed damage over time. Lasts longer per combo point.rnrn   1 point  : o1*2 over 8 secrn   2 points: o1*3 over 12 secrn   3 points: o1*4 over 16 secrn   4 points: o1*5 over 20 secrn   5 points: o1*6 over 24 sec?s193531[rn   6 points: o1*7 over 28 sec][]
  SpellInfo(rupture energy=25 combopoints=1 duration=4 gcd=1 tick=2)
  # Bleeding for w1 damage every t1 sec.
  SpellAddTargetDebuff(rupture rupture=1)
Define(secret_technique 280719)
# Finishing move that creates shadow clones of yourself. You and your shadow clones each perform a piercing attack on up to s6 enemies near your target, dealing Physical damage to the primary target and reduced damage to other targets.rn   1 point  : 280720m1*1*<mult> total damagern   2 points: 280720m1*2*<mult> total damagern   3 points: 280720m1*3*<mult> total damagern   4 points: 280720m1*4*<mult> total damagern   5 points: 280720m1*5*<mult> total damage?s193531[rn   6 points: 280720m1*6*<mult> total damage][]rnrnCooldown is reduced by s5 sec for every combo point you spend.
  SpellInfo(secret_technique energy=30 combopoints=1 cd=45 gcd=1 talent=secret_technique_talent)
Define(sepsis 328306)
# Infect the target's blood, dealing o1 Nature damage over 10 seconds. If the target survives its full duration, they suffer an additional 328306s1 damage and you gain s6 use of any Stealth ability for 5 seconds.rnrnCooldown reduced by s3 sec if Sepsis does not last its full duration.rnrn|cFFFFFFFFAwards s7 combo lpoint:points;.|r
  SpellInfo(sepsis gcd=0 offgcd=1)
Define(serrated_bone_spike_0 324074)
# Embed a bone spike in the target, dealing s1 Physical damage every t2 sec until they die.rnrnAttacking with Serrated Bone Spike causes all of your active bone spikes to fracture and strike your current target, increasing initial damage by s3 per spike.
  SpellInfo(serrated_bone_spike_0 gcd=1)
  # Bleeding for w2 every t sec.
  SpellAddBuff(serrated_bone_spike_0 serrated_bone_spike_0=1)
Define(serrated_bone_spike_1 328547)
# Embed a bone spike in the target, dealing s1 damage and 324073s1 Bleed damage every 324073t1 sec until they die. rnrnRefunds a charge when target dies or is healed to full.rnrn|cFFFFFFFFAwards 1 combo point per active bone spike.|r
  SpellInfo(serrated_bone_spike_1 energy=15 cd=30 gcd=1)
  SpellAddTargetDebuff(serrated_bone_spike_1 serrated_bone_spike_1=1)
Define(shadow_blades 121471)
# Draws upon surrounding shadows to empower your weapons, causing your combo point generating abilities to generate s2 additional combo point and deal s1 additional damage as Shadow for 20 seconds.
  SpellInfo(shadow_blades cd=180 duration=20 gcd=0 offgcd=1)
  # Combo point generating abilities generate s2 additional combo point and deal s1 additional damage as Shadow.
  SpellAddBuff(shadow_blades shadow_blades=1)
Define(shadow_blades_buff 255857)
# Your damaging spells have a chance to conjure s3 Shadow Blades. After 2 seconds, the swords begin launching forward, each dealing 257702s1 Shadow damage to the first enemy in their path and increasing damage taken from your subsequent Shadow Blades by 253265s2 for 3 seconds, up to 253265s2*253265u.
  SpellInfo(shadow_blades_buff gcd=0 offgcd=1)


Define(shadow_dance 185313)
# Allows use of all Stealth abilities and grants all the combat benefits of Stealth for 8 seconds, and increases damage by s2. Effect not broken from taking damage or attacking. ?s14062[Movement speed while active is increased by 1784s3 and damage dealt is increased by 1784s4. ]?s108209[Abilities cost 112942s1 less while active. ][]?s31223[Attacks from Shadow Dance and for 31223s1 sec after deal 31665s1 more damage.  ][]
  SpellInfo(shadow_dance cd=8 charge_cd=60 duration=8 gcd=0 offgcd=1 tick=1)
  SpellAddBuff(shadow_dance shadow_dance=1)
Define(shadowmeld 58984)
# Activate to slip into the shadows, reducing the chance for enemies to detect your presence. Lasts until cancelled or upon moving. Any threat is restored versus enemies still in combat upon cancellation of this effect.
  SpellInfo(shadowmeld cd=120 channel=-0.001 gcd=0 offgcd=1)
  # Shadowmelded.
  SpellAddBuff(shadowmeld shadowmeld=1)
Define(shadowstep 36554)
# Step through the shadows to appear behind your target and gain s2 increased movement speed for 2 seconds.
  SpellInfo(shadowstep cd=1 charge_cd=30 duration=2 channel=2 gcd=0 offgcd=1)
  # Movement speed increased by s2.
  SpellAddBuff(shadowstep shadowstep=1)

Define(shadowstrike 185438)
# Strike the target, dealing s1 Physical damage.rnrnWhile Stealthed, you strike through the shadows and appear behind your target up to 5+245623s1 yds away, dealing 245623s2 additional damage.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
# Rank 2: Shadowstrike deals 245623s2 increased damage and will now teleport you to a target up to 245623s1+5 yards away when used while Stealth is active.
  SpellInfo(shadowstrike energy=40 gcd=1 combopoints=-2)
  SpellInfo(ambush replaced_by=shadowstrike)
Define(shiv 5938)
# Attack with your ?s319032[your poisoned blades][off-hand], dealing sw1 Physical damage, and applying a concentrated form of your ?a3408[Crippling Poison, reducing movement speed by 115196s1 for 5 seconds.]?a5761[Numbing Poison, dispelling all enrage effects.][]?(!a3408&!a5761)[active Non-Lethal poison.][]rn?s319032[rnYour Nature damage done against the target is increased by 319504s1 for 9 seconds.rn][]rn|cFFFFFFFFAwards s3 combo lpoint:points;.|r
# Rank 2: Shiv now also increases your Nature damage done against the target by 319033s1 for 9 seconds.
  SpellInfo(shiv energy=20 cd=25 gcd=1 combopoints=-1)
Define(shuriken_storm 197835)
# Sprays shurikens at up to s4 targets within A1 yards, dealing s1*<CAP>/AP Physical damage.?s319951[rnrnCritical strikes with Shuriken Storm apply Find Weakness for 319949s1 sec.][]rnrn|cFFFFFFFFAwards s2 combo lpoint:points; per target hit?a121471[ plus an additional 121471s2][].|r
# Rank 2: Shuriken Storm critical strikes apply Find Weakness for s1 sec.
  SpellInfo(shuriken_storm energy=35 gcd=1)
Define(shuriken_tornado 277925)
# Focus intently, then release a Shuriken Storm every sec for the next 4 seconds. 
  SpellInfo(shuriken_tornado energy=60 cd=60 duration=4 gcd=1 tick=1 talent=shuriken_tornado_talent)
  # Releasing a Shuriken Storm every sec.
  SpellAddBuff(shuriken_tornado shuriken_tornado=1)
Define(sinister_strike 193315)
# Viciously strike an enemy, causing s1*<mult> Physical damage.?s279876[rnrnHas a s3 chance to hit an additional time, making your next Pistol Shot half cost and double damage.][]rnrn|cFFFFFFFFAwards s2 combo lpoint:points; each time it strikes.|r
# Rank 2: Sinister Strike's energy cost is reduced by s1.
  SpellInfo(sinister_strike energy=45 gcd=1 combopoints=-1)
Define(skull_and_crossbones 199603)
# Causes Sinister Strike to have an additional s1 chance of striking an additional time for the duration of Roll the Bones.
  SpellInfo(skull_and_crossbones channel=-0.001 gcd=0 offgcd=1)
  # Sinister Strike has an additional s1 chance of striking an additional time.
  SpellAddBuff(skull_and_crossbones skull_and_crossbones=1)
Define(slice_and_dice 5171)
# Finishing move that consumes combo points to increase attack speed by s1 and Energy regeneration rate by (25 of Spell Power). Lasts longer per combo point.rn   1 point  : 12 secondsrn   2 points: 18 secondsrn   3 points: 24 secondsrn   4 points: 30 secondsrn   5 points: 36 seconds?s193531[rn   6 points: 42 seconds][]
# Rank 2: Slice and Dice increases Energy regeneration by s1.
  SpellInfo(slice_and_dice energy=25 combopoints=1 duration=6 channel=6 gcd=1 tick=2)
  # Attack speed increased by w1.rnEnergy regeneration increased by w3.?w2!=0[rnRegaining w2 Energy every t2 sec.][]
  SpellAddBuff(slice_and_dice slice_and_dice=1)
Define(stealth 25083)
# Permanently enchant a cloak to increase Agility and dodge by ec1. Cannot be applied to items higher than level ecix
  SpellInfo(stealth gcd=0 offgcd=1)
Define(subterfuge 115192)
# Your abilities requiring Stealth can still be used for 3 seconds after Stealth breaks.?c3[rnrnAlso increases the duration of Shadow Dance by m2/1000 sec.][rnrnAlso causes Garrote to deal 115192s2 increased damage and have no cooldown when used from Stealth and for 3 seconds after breaking Stealth.]
  SpellInfo(subterfuge duration=3 gcd=0 offgcd=1)
  # Temporarily concealed in the shadows.
  SpellAddBuff(subterfuge subterfuge=1)
Define(symbols_of_death 212283)
# Invoke ancient symbols of power, generating s5 Energy and increasing your damage done by s1 for 10 seconds. ?s328077[Your next combo point generator will critically strike.][]
# Rank 2: Symbols of Death causes your next combo point generator to critically strike.
  SpellInfo(symbols_of_death cd=30 duration=10 gcd=0 offgcd=1 energy=-40)
  # Damage done increased by s1.
  SpellAddBuff(symbols_of_death symbols_of_death=1)
Define(the_rotten_buff 341134)
# After activating Symbols of Death, your next Shadowstrike or ?s200758[Gloomblade][Backstab] deals 341134s3 increased damage and generates 341134s1 additional combo points.
  SpellInfo(the_rotten_buff duration=30 gcd=0 offgcd=1)
  # Your next Shadowstrike or ?s200758[Gloomblade][Backstab] deals s3 increased damage and generates s1 additional combo points.
  SpellAddBuff(the_rotten_buff the_rotten_buff=1)
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
Define(vanish_0 1856)
# Allows you to vanish from sight, entering stealth while in combat. For the first 3 seconds after vanishing, damage and harmful effects received will not break stealth. Also breaks movement impairing effects.
  SpellInfo(vanish_0 cd=120 channel=0 gcd=0 offgcd=1 combopoints=0)
  # Improved stealth.
  SpellAddBuff(vanish_0 vanish_0=1)
Define(vanish_1 11327)
# Allows you to vanish from sight, entering stealth while in combat. For the first 3 seconds after vanishing, damage and harmful effects received will not break stealth. Also breaks movement impairing effects.
  SpellInfo(vanish_1 duration=3 gcd=0 offgcd=1)
  # Improved stealth.?w3!=0[rnMovement speed increased by w3.][]?w4!=0[rnDamage increased by w4.][]
  SpellAddBuff(vanish_1 vanish_1=1)
Define(vendetta 79140)
# Marks an enemy for death for 20 seconds, increasing the damage your abilities and auto attacks deal to the target by s1, and making the target visible to you even through concealments such as stealth and invisibility.rnrnGenerates 256495s1*3 seconds/5 Energy over 3 seconds.
  SpellInfo(vendetta cd=120 duration=20 gcd=0 offgcd=1)

  # Marked for death, increasing damage taken from the Rogue's attacks, and always visible to the Rogue.
  SpellAddTargetDebuff(vendetta vendetta=1)
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
SpellList(arcane_torrent arcane_torrent_0 arcane_torrent_1 arcane_torrent_2 arcane_torrent_3 arcane_torrent_4 arcane_torrent_5 arcane_torrent_6 arcane_torrent_7 arcane_torrent_8)
SpellList(blood_fury blood_fury_0 blood_fury_1 blood_fury_2 blood_fury_3)
SpellList(blood_of_the_enemy blood_of_the_enemy_0 blood_of_the_enemy_1 blood_of_the_enemy_2 blood_of_the_enemy_3)
SpellList(concentrated_flame concentrated_flame_0 concentrated_flame_1 concentrated_flame_2 concentrated_flame_3 concentrated_flame_4 concentrated_flame_5 concentrated_flame_6)
SpellList(fireblood fireblood_0 fireblood_1)
SpellList(flagellation flagellation_0 flagellation_1 flagellation_2 flagellation_3)
SpellList(focused_azerite_beam focused_azerite_beam_0 focused_azerite_beam_1 focused_azerite_beam_2 focused_azerite_beam_3)
SpellList(guardian_of_azeroth guardian_of_azeroth_0 guardian_of_azeroth_1 guardian_of_azeroth_2 guardian_of_azeroth_3 guardian_of_azeroth_4 guardian_of_azeroth_5)
SpellList(memory_of_lucid_dreams memory_of_lucid_dreams_0 memory_of_lucid_dreams_1 memory_of_lucid_dreams_2)
SpellList(purifying_blast purifying_blast_0 purifying_blast_1 purifying_blast_2 purifying_blast_3 purifying_blast_4 purifying_blast_5)
SpellList(razor_coral razor_coral_0 razor_coral_1 razor_coral_2 razor_coral_3 razor_coral_4)
SpellList(reaping_flames reaping_flames_0 reaping_flames_1 reaping_flames_2 reaping_flames_3 reaping_flames_4)
SpellList(reckless_force_buff reckless_force_buff_0 reckless_force_buff_1)
SpellList(ripple_in_space ripple_in_space_0 ripple_in_space_1 ripple_in_space_2 ripple_in_space_3)
SpellList(serrated_bone_spike serrated_bone_spike_0 serrated_bone_spike_1)
SpellList(the_unbound_force the_unbound_force_0 the_unbound_force_1 the_unbound_force_2 the_unbound_force_3)
SpellList(vanish vanish_0 vanish_1)
SpellList(worldvein_resonance worldvein_resonance_0 worldvein_resonance_1 worldvein_resonance_2 worldvein_resonance_3)
Define(alacrity_talent 17) #19249
# Your finishing moves have a s2 chance per combo point to grant 193538s1 Haste for 20 seconds, stacking up to 193538u times.
Define(blade_rush_talent 20) #23075
# Charge to your target with your blades out, dealing 271881sw1*271881s2/100 Physical damage to the target and 271881sw1 to all other nearby enemies.rnrnWhile Blade Flurry is active, damage to non-primary targets is increased by s1.rnrn|cFFFFFFFFGenerates 271896s1*5 seconds/271896t1 Energy over 5 seconds.
Define(crimson_tempest_talent 21) #23174
# Finishing move that slashes at up to s3 enemies within A1 yards, dealing instant damage and causing victims to bleed for additional damage. Lasts longer per combo point.rnrn   1 point  : s2*2 plus o1*2 over 4 secrn   2 points: s2*3 plus o1*3 over 6 secrn   3 points: s2*4 plus o1*4 over 8 secrn   4 points: s2*5 plus o1*5 over 10 secrn   5 points: s2*6 plus o1*6 over 12 sec?s193531[rn   6 points: s2*7 plus o1*7 over 14 sec][]
Define(dark_shadow_talent 16) #22335
# Shadow Dance now increases damage by s1+15.
Define(deeper_stratagem_talent 8) #19240
# You may have a maximum of s3 combo points, your finishing moves consume up to s3 combo points, and your finishing moves deal s4 increased damage.
Define(dreadblades_talent 18) #19250
# Strike at an enemy, dealing s1 Physical damage and empowering your weapons for 10 seconds, causing your Sinister Strike,?s196937[ Ghostly Strike,][]?s323654[ Slaughter,][]?s323547[ Echoing Reprimand,][]?s328547[ Serrated Bone Spike,][] Ambush, and Pistol Shot to fill your combo points, but your finishing moves consume 343145s1 of your current health.
Define(enveloping_shadows_talent 18) #22336
# Deepening Shadows reduces the remaining cooldown of Shadow Dance by an additional @switch<s3>[s1/10][s1/10.1] sec per combo point spent.rnrnShadow Dance gains s2 additional charge.
Define(exsanguinate_talent 18) #22344
# Twist your blades into the target's wounds, causing your Bleed effects on them to bleed out s1 faster.
Define(ghostly_strike_talent 3) #22120
# Strikes an enemy, dealing s1 Physical damage and causing the target to take s3 increased damage from your abilities for 10 seconds.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
Define(gloomblade_talent 3) #19235
# Punctures your target with your shadow-infused blade for s1 Shadow damage, bypassing armor.?s319949[ Critical strikes apply Find Weakness for 319949s1 sec.][]rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
Define(hidden_blades_talent 20) #22133
# Every t1 sec, gain 270070s1 increased damage for your next Fan of Knives, stacking up to 270070u times.
Define(internal_bleeding_talent 13) #19245
# Kidney Shot also deals up to ?s193531[6*154953o1][5*154953o1] Bleed damage over 6 seconds, based on combo points spent.
Define(killing_spree_talent 21) #23175
# Teleport to an enemy within 10 yards, attacking with both weapons for a total of <dmg> Physical damage over 2 seconds.rnrnWhile Blade Flurry is active, also hits up to s5 nearby enemies for s2 damage.
Define(marked_for_death_talent 9) #19241
# Marks the target, instantly generating s1 combo points. Cooldown reset if the target dies within 60 seconds.
Define(master_assassin_talent 6) #23022
# While Stealth is active and for s1 sec after breaking Stealth, your critical strike chance is increased by 256735s1.
Define(master_of_shadows_talent 19) #22132
# Gain 196980s1*3 seconds/196980t1+196980s2 Energy over 3 seconds when you enter Stealth or activate Shadow Dance.
Define(nightstalker_talent 4) #22331
# While Stealth?c3[ or Shadow Dance][] is active, you move s1 faster and your abilities deal s2 more damage.
Define(premeditation_talent 2) #19234
# After entering Stealth, your next Shadowstrike grants up to s1 sec of Slice and Dice, and generates s2 additional combo points if Slice and Dice is active.
Define(prey_on_the_weak_talent 15) #22115
# Enemies disabled by your Cheap Shot?s207777[, Dismantle, ][] or ?s199804[Between the Eyes][Kidney Shot] take s1 increased damage from all sources for 6 seconds.
Define(quick_draw_talent 2) #22119
# Half-cost uses of Pistol Shot granted by Sinister Strike now generate (25 of Spell Power) additional combo point, and deal s1 additional damage.
Define(secret_technique_talent 20) #23183
# Finishing move that creates shadow clones of yourself. You and your shadow clones each perform a piercing attack on up to s6 enemies near your target, dealing Physical damage to the primary target and reduced damage to other targets.rn   1 point  : 280720m1*1*<mult> total damagern   2 points: 280720m1*2*<mult> total damagern   3 points: 280720m1*3*<mult> total damagern   4 points: 280720m1*4*<mult> total damagern   5 points: 280720m1*5*<mult> total damage?s193531[rn   6 points: 280720m1*6*<mult> total damage][]rnrnCooldown is reduced by s5 sec for every combo point you spend.
Define(shadow_focus_talent 6) #22333
# ?c3[Abilities cost 112942m1 less Energy while Stealth or Shadow Dance is active.][Abilities cost 112942s1 less Energy while Stealth is active.]
Define(shuriken_tornado_talent 21) #21188
# Focus intently, then release a Shuriken Storm every sec for the next 4 seconds. 
Define(subterfuge_talent 5) #22332
# Your abilities requiring Stealth can still be used for 3 seconds after Stealth breaks.?c3[rnrnAlso increases the duration of Shadow Dance by m2/1000 sec.][rnrnAlso causes Garrote to deal 115192s2 increased damage and have no cooldown when used from Stealth and for 3 seconds after breaking Stealth.]
Define(vigor_talent 7) #19239
# Increases your maximum Energy by (25 of Spell Power) and your Energy regeneration by (25 of Spell Power).
Define(weaponmaster_talent 1) #19233
# Shadowstrike and Backstab have a s1 chance to hit the target twice each time they deal damage.
Define(double_dose_trait 273007)
Define(echoing_blades_trait 287649)
Define(scent_of_blood_trait 277679)
Define(shrouded_suffocation_trait 278666)
Define(twist_the_knife_trait 273488)
Define(ace_up_your_sleeve_trait 278676)
Define(blade_in_the_shadows_trait 275896)
Define(inevitability_trait 278683)
Define(perforate_trait 277673)
Define(blood_of_the_enemy_essence_id 23)
Define(breath_of_the_dying_essence_id 35)
Define(vision_of_perfection_essence_id 22)
Define(dashing_scoundrel_runeforge 7115)
Define(mark_of_the_master_assassin_runeforge_subtlety 7111)
Define(akaaris_soul_fragment_runeforge 7124)
Define(deathly_shadows_runeforge 7126)
Define(ambidexterity_conduit 242)
Define(deeper_daggers_conduit 245)
Define(perforated_veins_conduit 248)
    ]]
    OvaleScripts:RegisterScript("ROGUE", nil, name, desc, code, "include")
end
