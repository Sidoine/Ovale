local __exports = LibStub:NewLibrary("ovale/scripts/ovale_rogue_spells", 80300)
if not __exports then return end
__exports.registerRogueSpells = function(OvaleScripts)
    local name = "ovale_rogue_spells"
    local desc = "[8.2] Ovale: Rogue spells"
    local code = [[
Define(adrenaline_rush 13750)
# Increases your Energy regeneration rate by (25 of Spell Power), your maximum Energy by (25 of Spell Power), and your attack speed by s2 for 20 seconds.
  SpellInfo(adrenaline_rush cd=180 duration=20 gcd=0.8)
  # Energy regeneration increased by w1 and maximum Energy increased by w4.rnAttack speed increased by w2.
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

Define(backstab 53)
# Stab the target, causing s2*<mult> Physical damage. Damage increased by s4 when you are behind your target.rnrn|cFFFFFFFFAwards s3 combo lpoint:points;.|r
  SpellInfo(backstab energy=35 gcd=1 combopoints=-1)
Define(bag_of_tricks 312411)
# Pull your chosen trick from the bag and use it on target enemy or ally. Enemies take <damage> damage, while allies are healed for <healing>. 
  SpellInfo(bag_of_tricks cd=90)
Define(berserking 26297)
# Increases your haste by s1 for 12 seconds.
  SpellInfo(berserking cd=180 duration=12 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking=1)
Define(between_the_eyes 199804)
# Finishing move that deals damage with your pistol and stuns the target.?a235484[ Critical strikes with this ability deal four times normal damage.][]rn   1 point : <damage>*1 damage, 1 secrn   2 points: <damage>*2 damage, 2 secrn   3 points: <damage>*3 damage, 3 secrn   4 points: <damage>*4 damage, 4 secrn   5 points: <damage>*5 damage, 5 sec?s193531[rn   6 points: <damage>*6 damage, 6 sec][]
# Rank 2: Critical strikes with Between the Eyes deal four times normal damage.rn
  SpellInfo(between_the_eyes energy=25 combopoints=1 cd=30 gcd=1)
  # Stunned.
  SpellAddTargetDebuff(between_the_eyes between_the_eyes=1)
Define(blade_flurry 13877)
# Causes your single target attacks to also strike all nearby enemies for s2 of normal damage for 12 seconds.
  SpellInfo(blade_flurry energy=15 cd=12 charge_cd=25 duration=12 gcd=1)
  # Attacks striking nearby enemies.
  SpellAddBuff(blade_flurry blade_flurry=1)
Define(blade_rush 271877)
# Charge to your target with your blades out, dealing 271881sw1*271881s2/100 Physical damage to the target and 271881sw1 to all other nearby enemies.rnrnWhile Blade Flurry is active, damage to non-primary targets is increased by s1.rnrn|cFFFFFFFFGenerates 271896s1*5 seconds/271896t1 Energy over 5 seconds.
  SpellInfo(blade_rush cd=45 gcd=1 talent=blade_rush_talent)
Define(blindside 111240)
# Exploits the vulnerability of foes with less than s4 health, dealing s2 Physical damage to the target.rnrnMutilate has a s5 chance to make your next Blindside free and usable on any target, regardless of their health.rnrn|cFFFFFFFFAwards s3 combo lpoint:points;.|r
  SpellInfo(blindside energy=30 gcd=1 combopoints=-1 talent=blindside_talent)
Define(blood_of_the_enemy_0 297108)
# The Heart of Azeroth erupts violently, dealing s1 Shadow damage to enemies within A1 yds. You gain m2 critical strike chance against the targets for 10 seconds?a297122[, and increases your critical hit damage by 297126m for 5 seconds][].
  SpellInfo(blood_of_the_enemy_0 cd=120 duration=10 channel=10)
  # You have a w2 increased chance to be Critically Hit by the caster.
  SpellAddTargetDebuff(blood_of_the_enemy_0 blood_of_the_enemy_0=1)
Define(blood_of_the_enemy_1 297969)
# Infuse your Heart of Azeroth with Blood of the Enemy.
  SpellInfo(blood_of_the_enemy_1)
Define(blood_of_the_enemy_2 297970)
# Infuse your Heart of Azeroth with Blood of the Enemy.
  SpellInfo(blood_of_the_enemy_2)
Define(blood_of_the_enemy_3 297971)
# Infuse your Heart of Azeroth with Blood of the Enemy.
  SpellInfo(blood_of_the_enemy_3)
Define(blood_of_the_enemy_4 298273)
# The Heart of Azeroth erupts violently, dealing 297108s1 Shadow damage to enemies within 297108A1 yds. You gain 297108m2 critical strike chance against the targets for 10 seconds.
  SpellInfo(blood_of_the_enemy_4 cd=90 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(blood_of_the_enemy_4 blood_of_the_enemy_4=1)
Define(blood_of_the_enemy_5 298277)
# The Heart of Azeroth erupts violently, dealing 297108s1 Shadow damage to enemies within 297108A1 yds. You gain 297108m2 critical strike chance against the targets for 10 seconds, and increases your critical hit damage by 297126m for 5 seconds.
  SpellInfo(blood_of_the_enemy_5 cd=90 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(blood_of_the_enemy_5 blood_of_the_enemy_5=1)
Define(blood_of_the_enemy_6 299039)
# Infuse your Heart of Azeroth with Blood of the Enemy.
  SpellInfo(blood_of_the_enemy_6)
Define(bloodlust 2825)
# Increases Haste by (25 of Spell Power) for all party and raid members for 40 seconds.rnrnAllies receiving this effect will become Sated and unable to benefit from Bloodlust or Time Warp again for 600 seconds.
  SpellInfo(bloodlust cd=300 duration=40 channel=40 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(bloodlust bloodlust=1)
Define(cheap_shot 1833)
# Stuns the target for 4 seconds.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(cheap_shot energy=40 duration=4 gcd=1 combopoints=-2)
  # Stunned.
  SpellAddTargetDebuff(cheap_shot cheap_shot=1)
Define(conductive_ink_0 302491)
# Your damaging abilities against enemies above M3 health have a very high chance to apply Conductive Ink. When an enemy falls below M3 health, Conductive Ink inflicts s1*(1+@versadmg) Nature damage per stack.
  SpellInfo(conductive_ink_0 channel=0 gcd=0 offgcd=1)

Define(conductive_ink_1 302597)
# Your damaging abilities against enemies above M3 health have a very high chance to apply Conductive Ink. When an enemy falls below M3 health, Conductive Ink inflicts s1*(1+@versadmg) Nature damage per stack.
  SpellInfo(conductive_ink_1 channel=0 gcd=0 offgcd=1)

Define(crimson_tempest 121411)
# Finishing move that slashes at all enemies within A1 yards, dealing instant damage and causing victims to bleed for additional damage. Lasts longer per combo point.rnrn   1 point  : s2*2 plus o1*2 over 4 secrn   2 points: s2*3 plus o1*3 over 6 secrn   3 points: s2*4 plus o1*4 over 8 secrn   4 points: s2*5 plus o1*5 over 10 secrn   5 points: s2*6 plus o1*6 over 12 sec?s193531[rn   6 points: s2*7 plus o1*7 over 14 sec][]
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

Define(dispatch 2098)
# Finishing move that dispatches the enemy, dealing damage per combo point:rn   1 point  : m1*1 damagern   2 points: m1*2 damagern   3 points: m1*3 damagern   4 points: m1*4 damagern   5 points: m1*5 damage?s193531[rn   6 points: m1*6 damage][]
  SpellInfo(dispatch energy=35 combopoints=1 gcd=1)
Define(envenom 32645)
# Finishing move that drives your poisoned blades in deep, dealing instant Nature damage and increasing your poison application chance by s2. Damage and duration increased per combo point.rnrn   1 point  : m1*1 damage, 2 secrn   2 points: m1*2 damage, 3 secrn   3 points: m1*3 damage, 4 secrn   4 points: m1*4 damage, 5 secrn   5 points: m1*5 damage, 6 sec?s193531[rn   6 points: m1*6 damage, 7 sec][]
  SpellInfo(envenom energy=35 combopoints=1 duration=1 gcd=1 tick=1)
  SpellInfo(eviscerate replaced_by=envenom)
  # Poison application chance increased by s2.
  SpellAddBuff(envenom envenom=1)
Define(eviscerate 196819)
# Finishing move that disembowels the target, causing damage per combo point.rn   1 point  : m1*1 damagern   2 points: m1*2 damagern   3 points: m1*3 damagern   4 points: m1*4 damagern   5 points: m1*5 damage?s193531[rn   6 points: m1*6 damage][]
# Rank 2: Eviscerate's damage is increased by s1.
  SpellInfo(eviscerate energy=35 combopoints=1 gcd=1)
Define(exsanguinate 200806)
# Twist your blades into the target's wounds, causing your Bleed effects on them to bleed out s1 faster.
  SpellInfo(exsanguinate energy=25 cd=45 gcd=1 talent=exsanguinate_talent)
Define(fan_of_knives 51723)
# Sprays knives at all targets within A1 yards, dealing s1 Physical damage and applying your active poisons at their normal rate.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(fan_of_knives energy=35 gcd=1)
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
# Punctures your target with your shadow-infused blade for s1 Shadow damage, bypassing armor.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(gloomblade energy=35 gcd=1 combopoints=-1 talent=gloomblade_talent)
Define(gouge 1776)
# Gouges the eyes of an enemy target, incapacitating for 4 seconds. Damage will interrupt the effect.rnrnMust be in front of your target.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(gouge energy=25 cd=15 duration=4 gcd=1 combopoints=-1)
  # Incapacitated.
  SpellAddTargetDebuff(gouge gouge=1)
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

Define(keep_your_wits_about_you_buff 288985)
# When an attack Blade Flurries, increase the chance for Sinister Strike to strike again by s1. Additional strikes of Sinister Strike deal s2 more damage.
  SpellInfo(keep_your_wits_about_you_buff channel=-0.001 gcd=0 offgcd=1)

Define(kick 1766)
# A quick kick that interrupts spellcasting and prevents any spell in that school from being cast for 5 seconds.?s56805[ If you successfully interrupt a spell, Kick's cooldown is reduced by 56805m2/1000 sec.][]
  SpellInfo(kick cd=15 duration=5 gcd=0 offgcd=1 interrupt=1)
Define(kidney_shot 408)
# Finishing move that stuns the target. Lasts longer per combo point:rn   1 point  : 2 secondsrn   2 points: 3 secondsrn   3 points: 4 secondsrn   4 points: 5 secondsrn   5 points: 6 seconds?s193531[rn   6 points: 7 seconds][]
  SpellInfo(kidney_shot energy=25 combopoints=1 cd=20 duration=1 gcd=1)
  # Stunned.
  SpellAddTargetDebuff(kidney_shot kidney_shot=1)
Define(killing_spree 51690)
# Teleport to an enemy within 10 yards, attacking with both weapons for a total of <dmg> Physical damage over 2 seconds.rnrnWhile Blade Flurry is active, also hits all nearby enemies for s2 damage.
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

Define(loaded_dice_buff 256171)
# Activating Adrenaline Rush causes your next Roll the Bones to grant at least two matches.
  SpellInfo(loaded_dice_buff duration=45 gcd=0 offgcd=1)
  # Your next ?s5171[Slice and Dice will be w1 more effective][Roll the Bones will grant at least two matches].
  SpellAddBuff(loaded_dice_buff loaded_dice_buff=1)
Define(marked_for_death 137619)
# Marks the target, instantly generating s1 combo points. Cooldown reset if the target dies within 60 seconds.
  SpellInfo(marked_for_death cd=60 duration=60 channel=60 gcd=0 offgcd=1 combopoints=-5 talent=marked_for_death_talent)

  # Marked for Death will reset upon death.
  SpellAddTargetDebuff(marked_for_death marked_for_death=1)
Define(mutilate 1329)
# Attack with both weapons, dealing a total of <dmg> Physical damage.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(mutilate energy=50 gcd=1 combopoints=-2)

Define(nightblade 195452)
# Finishing move that infects the target with shadowy energy, dealing Shadow damage over time and reduces the effectiveness of healing on the target by s7. Lasts longer per combo point.rn   1 point  : <damage>*8/6 over 8 secrn   2 points: <damage>*10/6 over 10 secrn   3 points: <damage>*12/6 over 12 secrn   4 points: <damage>*14/6 over 14 secrn   5 points: <damage>*16/6 over 16 sec?s193531[rn   6 points: <damage>*18/6 over 18 sec][]rnrnYou deal s6 increased damage to enemies afflicted by your Nightblade.
  SpellInfo(nightblade energy=25 combopoints=1 duration=6 gcd=1 tick=2)
  # Suffering w1 Shadow damage every t1 sec.rnHealing effects reduced by s7.rnTaking s6 increased damage from the Rogue.
  SpellAddTargetDebuff(nightblade nightblade=1)
Define(nights_vengeance_buff 273419)
# Nightblade increases the damage of your next Eviscerate within 8 sec by s1 per combo point.
  SpellInfo(nights_vengeance_buff channel=-0.001 gcd=0 offgcd=1)

Define(pistol_shot 185763)
# Draw a concealed pistol and fire a quick shot at an enemy, dealing s1*<CAP>/AP Physical damage and reducing movement speed by s3 for 6 seconds.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(pistol_shot energy=40 duration=6 gcd=1 combopoints=-1)
  # Movement speed reduced by s3.
  SpellAddBuff(pistol_shot pistol_shot=1)
  # Movement speed reduced by s3.
  SpellAddTargetDebuff(pistol_shot pistol_shot=1)
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
Define(reckless_force_buff_0 298409)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 4 seconds.
  SpellInfo(reckless_force_buff_0 max_stacks=5 gcd=0 offgcd=1 tick=10)
  # Gaining unstable Azerite energy.
  SpellAddBuff(reckless_force_buff_0 reckless_force_buff_0=1)
Define(reckless_force_buff_1 304038)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 4 seconds.
  SpellInfo(reckless_force_buff_1 channel=-0.001 gcd=0 offgcd=1)
  SpellAddBuff(reckless_force_buff_1 reckless_force_buff_1=1)
Define(roll_the_bones 193316)
# Finishing move that rolls the dice of fate, providing a random combat enhancement. Lasts longer per combo point:rn   1 point  : 12 secondsrn   2 points: 18 secondsrn   3 points: 24 secondsrn   4 points: 30 secondsrn   5 points: 36 seconds?s193531[rn   6 points: 42 seconds][]
  SpellInfo(roll_the_bones energy=25 combopoints=1 duration=6 channel=6 gcd=1 tick=2)
  # Gained a random combat enhancement.
  SpellAddBuff(roll_the_bones roll_the_bones=1)
Define(rupture 1943)
# Finishing move that tears open the target, dealing Bleed damage over time. Lasts longer per combo point.rnrn   1 point  : o1*2 over 8 secrn   2 points: o1*3 over 12 secrn   3 points: o1*4 over 16 secrn   4 points: o1*5 over 20 secrn   5 points: o1*6 over 24 sec?s193531[rn   6 points: o1*7 over 28 sec][]
  SpellInfo(rupture energy=25 combopoints=1 duration=4 gcd=1 tick=2)
  # Bleeding for w1 damage every t1 sec.
  SpellAddTargetDebuff(rupture rupture=1)
Define(secret_technique 280719)
# Finishing move that creates shadow clones of yourself. You and your shadow clones each perform a piercing attack on all enemies near your target, dealing Physical damage to the primary target and reduced damage to other targets.rn   1 point  : 280720m1*1*<mult> total damagern   2 points: 280720m1*2*<mult> total damagern   3 points: 280720m1*3*<mult> total damagern   4 points: 280720m1*4*<mult> total damagern   5 points: 280720m1*5*<mult> total damage?s193531[rn   6 points: 280720m1*6*<mult> total damage][]rnrnCooldown is reduced by by s5 sec for every combo point you spend.
  SpellInfo(secret_technique energy=30 combopoints=1 cd=45 gcd=1 talent=secret_technique_talent)
Define(seething_rage 297126)
# Increases your critical hit damage by 297126m for 5 seconds.
  SpellInfo(seething_rage duration=5 gcd=0 offgcd=1)
  # Critical strike damage increased by w1.
  SpellAddBuff(seething_rage seething_rage=1)
Define(shadow_blades 121471)
# Draws upon surrounding shadows to empower your weapons, causing your combo point generating abilities to generate s2 additional combo point and deal s1 additional damage as Shadow for 20 seconds.
  SpellInfo(shadow_blades cd=180 duration=20 gcd=1)
  # Combo point generating abilities generate s2 additional combo point and deal s1 additional damage as Shadow.
  SpellAddBuff(shadow_blades shadow_blades=1)
Define(shadow_blades_buff 255857)
# Your damaging spells have a chance to conjure s3 Shadow Blades. After 2 seconds, the swords begin launching forward, each dealing 257702s1 Shadow damage to the first enemy in their path and increasing damage taken from your subsequent Shadow Blades by 253265s2 for 3 seconds, up to 253265s2*253265u.
  SpellInfo(shadow_blades_buff gcd=0 offgcd=1)


Define(shadow_dance 185313)
# Allows use of all Stealth abilities and grants all the combat benefits of Stealth for 5 seconds. Effect not broken from taking damage or attacking. ?s14062[Movement speed while active is increased by 1784s3 and damage dealt is increased by 1784s4. ]?s108209[Abilities cost 112942s1 less while active. ][]?s31223[Attacks from Shadow Dance and for 31223s1 sec after deal 31665s1 more damage.  ][]
  SpellInfo(shadow_dance cd=1 charge_cd=60 duration=5 gcd=0 offgcd=1 tick=1)
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
# Strike the target, dealing s1 Physical damage.?a231718[rnrnWhile Stealthed, you strike through the shadows and appear behind your target up to 5+245623s1 yds away, dealing 245623s2 additional damage.][]rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
# Rank 2: Shadowstrike deals 245623s2 increased damage and will now teleport you to a target up to 245623s1+5 yards away when used while Stealth is active.
  SpellInfo(shadowstrike energy=40 gcd=1 combopoints=-2)
Define(shuriken_storm 197835)
# Sprays shurikens at all targets within A1 yards, dealing s1*<CAP>/AP Physical damage.rnrnDamage increased by s3 while Stealth or Shadow Dance is active.rnrn|cFFFFFFFFAwards s2 combo lpoint:points; per target hit?a121471[ plus an additional 121471s2][].|r
  SpellInfo(shuriken_storm energy=35 gcd=1)
Define(shuriken_tornado 277925)
# Focus intently, then release a Shuriken Storm every sec for the next 4 seconds.
  SpellInfo(shuriken_tornado energy=60 cd=60 duration=4 gcd=1 tick=1 talent=shuriken_tornado_talent)
  # Releasing a Shuriken Storm every sec.
  SpellAddBuff(shuriken_tornado shuriken_tornado=1)
Define(sinister_strike_outlaw 193315)
# Viciously strike an enemy, causing s1*<mult> Physical damage.?s279876[rnrnHas a s3 chance to hit an additional time, making your next Pistol Shot half cost and double damage.][]rnrn|cFFFFFFFFAwards s2 combo lpoint:points; each time it strikes.|r
  SpellInfo(sinister_strike_outlaw energy=45 gcd=1 combopoints=-1)
Define(slice_and_dice 5171)
# Finishing move that consumes combo points to increase attack speed by s1 and Energy regeneration rate by (25 of Spell Power). Lasts longer per combo point.rn   1 point  : 12 secondsrn   2 points: 18 secondsrn   3 points: 24 secondsrn   4 points: 30 secondsrn   5 points: 36 seconds?s193531[rn   6 points: 42 seconds][]
  SpellInfo(slice_and_dice energy=25 combopoints=1 duration=6 channel=6 gcd=1 tick=2 talent=slice_and_dice_talent)
  # Attack speed increased by w1.rnEnergy regeneration increased by w3.?w2!=0[rnRegaining w2 Energy every t2 sec.][]
  SpellAddBuff(slice_and_dice slice_and_dice=1)
Define(stealth 1784)
# Conceals you in the shadows until cancelled, allowing you to stalk enemies without being seen. ?s14062[Movement speed while stealthed is increased by s3 and damage dealt is increased by s4.]?s108209[ Abilities cost 112942s1 less while stealthed. ][]?s31223[ Attacks from Stealth and for 31223s1 sec after deal 31665s1 more damage.][]
  SpellInfo(stealth cd=2 gcd=0 offgcd=1)
  # Stealthed.?w3!=0[rnMovement speed increased by w3.][]?w4!=0[rnDamage increased by w4.][]
  SpellAddBuff(stealth stealth=1)
Define(symbols_of_death 212283)
# Invoke ancient symbols of power, generating s5 Energy and increasing your damage done by s1 for 10 seconds.
  SpellInfo(symbols_of_death cd=30 duration=10 gcd=0 offgcd=1 energy=-40 tick=1)
  # Damage done increased by s1.
  SpellAddBuff(symbols_of_death symbols_of_death=1)
Define(the_unbound_force_0 298452)
# Unleash the forces within the Heart of Azeroth, causing shards of Azerite to strike your target for (298407s3*((2 seconds/t)+1)+298407s3) Fire damage over 2 seconds. This damage is increased by s2 if it critically strikes.?a298456[rnrnEach time The Unbound Force causes a critical strike, it immediately strikes the target with an additional Azerite shard, up to a maximum of 298456m2.][]
  SpellInfo(the_unbound_force_0 cd=60 duration=2 channel=2 tick=0.33)
  SpellAddBuff(the_unbound_force_0 the_unbound_force_0=1)
  SpellAddTargetDebuff(the_unbound_force_0 the_unbound_force_0=1)
Define(the_unbound_force_1 298453)
# Unleash the forces within the Heart of Azeroth, causing shards of Azerite to strike your target for (298407s3*((2 seconds/t)+1)+298407s3) Fire damage over 2 seconds. This damage is increased by s2 if it critically strikes.?a298456[rnrnEach time The Unbound Force causes a critical strike, it immediately strikes the target with an additional Azerite shard, up to a maximum of 298456m2.][]
  SpellInfo(the_unbound_force_1 gcd=0 offgcd=1)
Define(the_unbound_force_2 299321)
# Infuse your Heart of Azeroth with The Unbound Force.
  SpellInfo(the_unbound_force_2)
Define(the_unbound_force_3 299322)
# Infuse your Heart of Azeroth with The Unbound Force.
  SpellInfo(the_unbound_force_3)
Define(the_unbound_force_4 299323)
# Infuse your Heart of Azeroth with The Unbound Force.
  SpellInfo(the_unbound_force_4)
Define(the_unbound_force_5 299324)
# Infuse your Heart of Azeroth with The Unbound Force.
  SpellInfo(the_unbound_force_5)
Define(the_unbound_force_6 299376)
# Unleash the forces within the Heart of Azeroth, causing shards of Azerite to strike your target for (298407s3*((2 seconds/298452t)+1)+298407s3) Fire damage over 2 seconds. This damage is increased by s2 if it critically strikes.
  SpellInfo(the_unbound_force_6 cd=45 duration=2 channel=2 gcd=1 tick=0.33)
  SpellAddBuff(the_unbound_force_6 the_unbound_force_6=1)
  SpellAddTargetDebuff(the_unbound_force_6 the_unbound_force_6=1)
Define(the_unbound_force_7 299378)
# Unleash the forces within the Heart of Azeroth, causing shards of Azerite to strike your target for (298407s3*((2 seconds/298452t)+1)+298407s3) Fire damage over 2 seconds. This damage is increased by s2 if it critically strikes.rnrnEach time The Unbound Force causes a critical strike, it immediately strikes the target with an additional Azerite shard, up to a maximum of 298456m2.
  SpellInfo(the_unbound_force_7 cd=45 duration=2 channel=2 gcd=1 tick=0.33)
  SpellAddBuff(the_unbound_force_7 the_unbound_force_7=1)
  SpellAddTargetDebuff(the_unbound_force_7 the_unbound_force_7=1)
Define(toxic_blade 245388)
# Stab your enemy with a toxic poisoned blade, dealing s2 Nature damage.rnrnYour Nature damage done against the target is increased by 245389s1 for 9 seconds.rnrn|cFFFFFFFFAwards s3 combo lpoint:points;.|r
  SpellInfo(toxic_blade energy=20 cd=25 gcd=1 combopoints=-1 talent=toxic_blade_talent)
  # s1 increased damage taken from poisons from the casting Rogue.
  SpellAddTargetDebuff(toxic_blade toxic_blade_debuff=1)
Define(toxic_blade_debuff 245389)
# Stab your enemy with a toxic poisoned blade, dealing s2 Nature damage.rnrnYour Nature damage done against the target is increased by 245389s1 for 9 seconds.rnrn|cFFFFFFFFAwards s3 combo lpoint:points;.|r
  SpellInfo(toxic_blade_debuff duration=9 channel=9 gcd=0 offgcd=1)
  # s1 increased damage taken from poisons from the casting Rogue.
  SpellAddTargetDebuff(toxic_blade_debuff toxic_blade_debuff=1)
Define(vanish 1856)
# Allows you to vanish from sight, entering stealth while in combat. For the first 3 seconds after vanishing, damage and harmful effects received will not break stealth. Also breaks movement impairing effects.
  SpellInfo(vanish cd=120 channel=0 gcd=0 offgcd=1 combopoints=0)
  # Improved stealth.
  SpellAddBuff(vanish vanish=1)
Define(vendetta 79140)
# Marks an enemy for death for 20 seconds, increasing the damage your abilities and auto attacks deal to the target by s1, and making the target visible to you even through concealments such as stealth and invisibility.rnrnGenerates 256495s1*3 seconds/5 Energy over 3 seconds.
  SpellInfo(vendetta cd=120 duration=20 gcd=1)

  # Marked for death, increasing damage taken from the Rogue's attacks, and always visible to the Rogue.
  SpellAddTargetDebuff(vendetta vendetta=1)
SpellList(blood_of_the_enemy blood_of_the_enemy_0 blood_of_the_enemy_1 blood_of_the_enemy_2 blood_of_the_enemy_3 blood_of_the_enemy_4 blood_of_the_enemy_5 blood_of_the_enemy_6)
SpellList(fireblood fireblood_0 fireblood_1)
SpellList(focused_azerite_beam focused_azerite_beam_0 focused_azerite_beam_1 focused_azerite_beam_2 focused_azerite_beam_3)
SpellList(guardian_of_azeroth guardian_of_azeroth_0 guardian_of_azeroth_1 guardian_of_azeroth_2 guardian_of_azeroth_3 guardian_of_azeroth_4 guardian_of_azeroth_5)
SpellList(purifying_blast purifying_blast_0 purifying_blast_1 purifying_blast_2 purifying_blast_3 purifying_blast_4 purifying_blast_5)
SpellList(razor_coral razor_coral_0 razor_coral_1 razor_coral_2 razor_coral_3 razor_coral_4)
SpellList(reaping_flames reaping_flames_0 reaping_flames_1 reaping_flames_2 reaping_flames_3)
SpellList(reckless_force_buff reckless_force_buff_0 reckless_force_buff_1)
SpellList(the_unbound_force the_unbound_force_0 the_unbound_force_1 the_unbound_force_2 the_unbound_force_3 the_unbound_force_4 the_unbound_force_5 the_unbound_force_6 the_unbound_force_7)
SpellList(conductive_ink conductive_ink_0 conductive_ink_1)
Define(alacrity_talent 17) #19249
# Your finishing moves have a s2 chance per combo point to grant 193538s1 Haste for 20 seconds, stacking up to 193538u times.
Define(blade_rush_talent 20) #23075
# Charge to your target with your blades out, dealing 271881sw1*271881s2/100 Physical damage to the target and 271881sw1 to all other nearby enemies.rnrnWhile Blade Flurry is active, damage to non-primary targets is increased by s1.rnrn|cFFFFFFFFGenerates 271896s1*5 seconds/271896t1 Energy over 5 seconds.
Define(blindside_talent 3) #22339
# Exploits the vulnerability of foes with less than s4 health, dealing s2 Physical damage to the target.rnrnMutilate has a s5 chance to make your next Blindside free and usable on any target, regardless of their health.rnrn|cFFFFFFFFAwards s3 combo lpoint:points;.|r
Define(crimson_tempest_talent 21) #23174
# Finishing move that slashes at all enemies within A1 yards, dealing instant damage and causing victims to bleed for additional damage. Lasts longer per combo point.rnrn   1 point  : s2*2 plus o1*2 over 4 secrn   2 points: s2*3 plus o1*3 over 6 secrn   3 points: s2*4 plus o1*4 over 8 secrn   4 points: s2*5 plus o1*5 over 10 secrn   5 points: s2*6 plus o1*6 over 12 sec?s193531[rn   6 points: s2*7 plus o1*7 over 14 sec][]
Define(dark_shadow_talent 16) #22335
# While Shadow Dance is active, all damage you deal is increased by s1.
Define(deeper_stratagem_talent 8) #19240
# You may have a maximum of s3 combo points, your finishing moves consume up to s3 combo points, and your finishing moves deal s4 increased damage.
Define(exsanguinate_talent 18) #22344
# Twist your blades into the target's wounds, causing your Bleed effects on them to bleed out s1 faster.
Define(find_weakness_talent 2) #19234
# Your Shadowstrike and Cheap Shot reveal a flaw in your target's defenses, causing all your attacks to bypass 91021s1 of that enemy's armor for 10 seconds.
Define(ghostly_strike_talent 3) #22120
# Strikes an enemy, dealing s1 Physical damage and causing the target to take s3 increased damage from your abilities for 10 seconds.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
Define(gloomblade_talent 3) #19235
# Punctures your target with your shadow-infused blade for s1 Shadow damage, bypassing armor.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
Define(internal_bleeding_talent 13) #19245
# Kidney Shot also deals up to ?s193531[6*154953o1][5*154953o1] Bleed damage over 6 seconds, based on combo points spent.
Define(killing_spree_talent 21) #23175
# Teleport to an enemy within 10 yards, attacking with both weapons for a total of <dmg> Physical damage over 2 seconds.rnrnWhile Blade Flurry is active, also hits all nearby enemies for s2 damage.
Define(marked_for_death_talent 9) #19241
# Marks the target, instantly generating s1 combo points. Cooldown reset if the target dies within 60 seconds.
Define(master_assassin_talent 6) #23022
# While Stealth is active and for s1 sec after breaking Stealth, your critical strike chance is increased by 256735s1.
Define(master_of_shadows_talent 19) #22132
# Gain 196980s1*3 seconds/196980t1+196980s2 Energy over 3 seconds when you enter Stealth or activate Shadow Dance.
Define(nightstalker_talent 4) #22331
# While Stealth?c3[ or Shadow Dance][] is active, you move s1 faster and your abilities deal s2 more damage.
Define(quick_draw_talent 2) #22119
# Half-cost uses of Pistol Shot granted by Sinister Strike now generate (25 of Spell Power) additional combo point, and deal s1 additional damage.
Define(secret_technique_talent 20) #23183
# Finishing move that creates shadow clones of yourself. You and your shadow clones each perform a piercing attack on all enemies near your target, dealing Physical damage to the primary target and reduced damage to other targets.rn   1 point  : 280720m1*1*<mult> total damagern   2 points: 280720m1*2*<mult> total damagern   3 points: 280720m1*3*<mult> total damagern   4 points: 280720m1*4*<mult> total damagern   5 points: 280720m1*5*<mult> total damage?s193531[rn   6 points: 280720m1*6*<mult> total damage][]rnrnCooldown is reduced by by s5 sec for every combo point you spend.
Define(shadow_focus_talent 6) #22333
# ?c3[Abilities cost 112942m1 less Energy while Stealth or Shadow Dance is active.][Abilities cost 112942s1 less Energy while Stealth is active.]
Define(shuriken_tornado_talent 21) #21188
# Focus intently, then release a Shuriken Storm every sec for the next 4 seconds.
Define(slice_and_dice_talent 18) #19250
# Finishing move that consumes combo points to increase attack speed by s1 and Energy regeneration rate by (25 of Spell Power). Lasts longer per combo point.rn   1 point  : 12 secondsrn   2 points: 18 secondsrn   3 points: 24 secondsrn   4 points: 30 secondsrn   5 points: 36 seconds?s193531[rn   6 points: 42 seconds][]
Define(subterfuge_talent 5) #22332
# Your abilities requiring Stealth can still be used for 3 seconds after Stealth breaks.?c3[rnrnAlso increases the duration of Shadow Dance by m2/1000 sec.][rnrnAlso causes Garrote to deal 115192s2 increased damage and have no cooldown when used from Stealth and for 3 seconds after breaking Stealth.]
Define(toxic_blade_talent 17) #23015
# Stab your enemy with a toxic poisoned blade, dealing s2 Nature damage.rnrnYour Nature damage done against the target is increased by 245389s1 for 9 seconds.rnrn|cFFFFFFFFAwards s3 combo lpoint:points;.|r
Define(venom_rush_talent 16) #22343
# Mutilate refunds s1 Energy when used against a poisoned target.
Define(vigor_talent 7) #19239
# Increases your maximum Energy by (25 of Spell Power) and your Energy regeneration by (25 of Spell Power).
Define(weaponmaster_talent 1) #19233
# Shadowstrike and Backstab have a s1 chance to hit the target twice each time they deal damage.
Define(ashvanes_razor_coral_item 169311)
Define(azsharas_font_of_power_item 169314)
Define(focused_resolve_item 168506)
Define(pocket_sized_computation_device_item 167555)
Define(unbridled_fury_item 169299)
Define(double_dose_trait 273007)
Define(echoing_blades_trait 287649)
Define(scent_of_blood_trait 277679)
Define(shrouded_suffocation_trait 278666)
Define(ace_up_your_sleeve_trait 278676)
Define(deadshot_trait 272935)
Define(snake_eyes_trait 275846)
Define(blade_in_the_shadows_trait 275896)
Define(inevitability_trait 278683)
Define(nights_vengeance_trait 273418)
Define(perforate_trait 277673)
Define(replicating_shadows_trait 286121)
Define(the_first_dance_trait 278681)
Define(blood_of_the_enemy_essence_id 23)
    ]]
    code = code .. [[
# Rogue spells and functions.

# Aliases
SpellList(lethal_poison_buff deadly_poison_buff wound_poison_buff)
SpellList(non_lethal_poison_buff crippling_poison_buff leeching_poison_buff)
SpellList(roll_the_bones_buff broadside_buff buried_treasure_buff grand_melee_buff ruthless_precision_buff skull_and_crossbones_buff true_bearing_buff)
SpellList(exsanguinated rupture_debuff_exsanguinated garrote_debuff_exsanguinated)

# Learned spells.
Define(adrenaline_rush 13750)
	SpellInfo(adrenaline_rush cd=180)
	SpellAddBuff(adrenaline_rush adrenaline_rush_buff=1)
Define(adrenaline_rush_buff 13750)
	SpellInfo(adrenaline_rush_buff duration=20)
Define(alacrity_buff 193538)
	SpellInfo(alacrity_buff duration=20 max_stacks=5)

	SpellInfo(ambush combopoints=-2 energy=50 stealthed=1)

	SpellInfo(backstab combopoints=-1 energy=35)
	SpellInfo(backstab replaced_by=gloomblade talent=gloomblade_talent)
	SpellRequire(backstab combopoints -2=buff,shadow_blades_buff)

	SpellInfo(between_the_eyes combopoints=1 max_combopoints=5 energy=25 cd=30)
	SpellInfo(between_the_eyes max_combopoints=6 talent=deeper_stratagem_talent)
	SpellAddBuff(between_the_eyes deadshot_buff=1 trait=deadshot_trait)

	SpellInfo(blade_flurry cd=25 energy=15 charges=2)
	SpellAddBuff(blade_flurry blade_flurry_buff=toggle)
	SpellRequire(blade_flurry unusable 1=buff,blade_flurry_buff)
Define(blade_flurry_buff 13877)
	SpellInfo(blade_flurry_buff duration=12)
	SpellInfo(blade_flurry_buff duration=15 talent=dancing_steel_talent)

	SpellInfo(blade_rush cd=45)
	SpellAddBuff(blade_rush blade_rush_buff=1)
Define(blade_rush_buff 271896)
	SpellInfo(blade_rush_buff duration=5)
Define(blind 2094)
	SpellInfo(blind cd=120 interrupt=1)
	SpellInfo(blind add_cd=30 talent=blinding_powder_talent)
	SpellAddTargetDebuff(blind blind_debuff=1)
Define(blind_debuff 2094)
	SpellInfo(blind_debuff duration=60)

	SpellInfo(blindside energy=30 combopoints=-1 target_health_pct=30)
	SpellRequire(blindside target_health_pct 100=buff,blindside_buff)
	SpellRequire(blindside energy_percent 0=buff,blindside_buff)
	SpellAddBuff(blindside blindside_buff=-1)
Define(blindside_buff 121153)
	SpellInfo(blindside_buff duration=10)

	SpellInfo(cheap_shot combopoints=-2 energy=40 interrupt=1 stealthed=1)
	SpellInfo(cheap_shot energy=0 talent=dirty_tricks_talent)
	SpellRequire(cheap_shot energy_percent 0=buff,shot_in_the_dark_buff specialization=subtlety)
	SpellAddTargetDebuff(cheap_shot find_weakness_debuff=1 talent=find_weakness_talent specialization=subtlety)
Define(cloak_of_shadows 31224)
	SpellInfo(cloak_of_shadows cd=120)
Define(cloak_of_shadows_buff 31224)
	SpellInfo(cloak_of_shadows_buff duration=5)

	SpellInfo(crimson_tempest energy=35 combopoints=1 max_combopoints=5)
	SpellInfo(crimson_tempest max_combopoints=6 talent=deeper_stratagem_talent)
	SpellAddTargetDebuff(crimson_tempest crimson_tempest_debuff=1)
Define(crimson_tempest_debuff 121411)
	SpellInfo(crimson_tempest_debuff duration=2 add_duration_combopoints=2 tick=2 haste=melee)
Define(crimson_vial 185311)
	SpellInfo(crimson_vial energy=30 cd=30)
	SpellAddBuff(crimson_vial crimson_vial_buff=1)
Define(crimson_vial_buff 185311)
	SpellInfo(crimson_vial_buff duration=6)
Define(crippling_poison 3408)
	SpellAddBuff(crippling_poison crippling_poison_buff=1)
Define(crippling_poison_buff 3408)
	SpellInfo(crippling_poison_buff duration=3600)
Define(crippling_poison_debuff 3409)
	SpellInfo(crippling_poison_debuff duration=12)
Define(deadly_poison 2823)
	SpellAddBuff(deadly_poison deadly_poison_buff=1)
	SpellAddBuff(deadly_poison leeching_poison_buff talent=leeching_poison_talent)
Define(deadly_poison_buff 2823)
	SpellInfo(deadly_poison_buff duration=3600)
Define(deadly_poison_debuff 2818)
	SpellInfo(deadly_poison_debuff duration=12 tick=2 haste=melee)
Define(deadshot_buff 272940)

Define(elaborate_planning_buff 193640)
	SpellInfo(elaborate_planning_buff duration=5)

	SpellInfo(dispatch energy=35 combopoints=1 max_combopoints=5)
	SpellInfo(dispatch max_combopoints=6 talent=deeper_stratagem_talent)
Define(distract 1725)
	SpellInfo(distract energy=30 cd=30)

	SpellInfo(envenom combopoints=1 max_combopoints=5)
	SpellInfo(envenom max_combopoints=6 talent=deeper_stratagem_talent)
	SpellAddBuff(envenom envenom_buff=1)
Define(envenom_buff 32645)
	SpellInfo(envenom_buff duration=1 add_duration_combopoints=1)
Define(evasion 5277)
	SpellInfo(evasion cd=120)
	SpellAddBuff(evasion evasion_buff=1)
Define(evasion_buff 5277)
	SpellInfo(evasion_buff duration=10)

	SpellInfo(eviscerate combopoints=1 max_combopoints=5 energy=35)
	SpellInfo(eviscerate max_combopoints=6 talent=deeper_stratagem_talent)
	SpellRequire(eviscerate energy_percent 80=stealthed,1 talent=shadow_focus_talent)
	SpellAddBuff(eviscerate shuriken_combo_buff=0)

	SpellInfo(exsanguinate energy=25 cd=45 tag=main)
	SpellAddTargetDebuff(exsanguinate rupture_debuff_exsanguinated=1 if_target_debuff=rupture_debuff) #TODO if_target_debuff is not implemented here
	SpellAddTargetDebuff(exsanguinate garrote_debuff_exsanguinated=1 if_target_debuff=garrote_debuff)

	SpellInfo(fan_of_knives combopoints=-1 energy=35)
	SpellAddBuff(fan_of_knives hidden_blades_buff=0 talent=hidden_blades_talent)
Define(feint 1966)
	SpellInfo(feint energy=35 cd=15)
Define(find_weakness_debuff 91021)
	SpellInfo(find_weakness_debuff duration=10)

	SpellInfo(garrote cd=15 combopoints=-1 energy=45)
	SpellAddTargetDebuff(garrote garrote_debuff=1)
Define(garrote_debuff 703)
	SpellInfo(garrote_debuff duration=18 tick=2 haste=melee)
Define(garrote_debuff_exsanguinated -703) #TODO negative number for hidden auras?
	SpellInfo(garrote_debuff_exsanguinated duration=garrote_debuff) #TODO use an aura as a duration to mirror the duration

	SpellInfo(ghostly_strike combopoints=-1 energy=35)
	SpellAddTargetDebuff(ghostly_strike ghostly_strike_debuff=1)
Define(ghostly_strike_debuff 196937)
	SpellInfo(ghostly_strike_debuff duration=10)

	SpellInfo(gloomblade combopoints=-1 energy=35)
	SpellInfo(gloomblade replaced_by=backstab talent=gloomblade_talent)
	SpellRequire(gloomblade combopoints -2=buff,shadow_blades_buff)

	SpellInfo(gouge combopoints=-1 cd=15 energy=25 tag=main)
	SpellInfo(gouge energy=0 talent=dirty_tricks_talent)
Define(grappling_hook 195457)
	SpellInfo(grappling_hook cd=60)
	SpellInfo(grappling_hook add_cd=-30 talent=retractable_hook_talent)
Define(hidden_blades_buff 270070)
	SpellInfo(hidden_blades_buff max_stacks=20)
Define(internal_bleeding_debuff 154953)
	SpellInfo(internal_bleeding_debuff duration=6 tick=1 haste=melee)

	SpellInfo(kick cd=15 gcd=0 interrupt=1 offgcd=1)

	SpellInfo(kidney_shot cd=20 combopoints=1 max_combopoints=5 energy=25 interrupt=1)
	SpellInfo(kidney_shot max_combopoints=6 talent=deeper_stratagem_talent)
	SpellRequire(kidney_shot energy_percent 80=stealthed,1 talent=shadow_focus_talent)
	SpellAddTargetDebuff(kidney_shot internal_bleeding_debuff=1 talent=internal_bleeding_talent)

	SpellInfo(killing_spree cd=120)
	SpellAddBuff(killing_spree killing_spree_buff=1)
Define(killing_spree_buff 51690)
	SpellInfo(killing_spree_buff duration=2)
Define(leeching_poison_buff 108211)
	SpellInfo(leeching_poison_buff duration=3600)

	SpellInfo(loaded_dice_buff duration=45)

	SpellInfo(marked_for_death cd=30 combopoints=-6 gcd=0 offgcd=1)
Define(master_assassin_buff 256735)
	SpellInfo(master_assassin_buff duration=3)
Define(master_of_shadows 196980)
	SpellInfo(master_of_shadows duration=3)

	SpellInfo(mutilate combopoints=-2 energy=50)
	SpellRequire(mutilate add_energy_from_aura -5=buff,lethal_poison_buff talent=venom_rush_talent)

	SpellInfo(nightblade energy=25 combopoints=1 max_combopoints=5)
	SpellInfo(nightblade max_combopoints=6 talent=deeper_stratagem_talent)
	SpellRequire(nightblade energy_percent 80=stealthed,1 talent=shadow_focus_talent)
	SpellAddTargetDebuff(nightblade nightblade_debuff=1)
Define(nightblade_debuff 195452)
	SpellInfo(nightblade_debuff duration=6 add_duration_combopoints=2 tick=2 haste=melee)
Define(opportunity_buff 195627)
	SpellInfo(opportunity_buff duration=10)
Define(pick_lock 1804)
Define(pick_pocket 921)

	SpellInfo(pistol_shot combopoints=-1 energy=40)
	SpellAddBuff(pistol_shot opportunity_buff=-1)
	SpellRequire(pistol_shot energy_percent 50=buff,opportunity_buff)
	SpellRequire(pistol_shot combopionts -2=buff,opportunity_buff talent=quick_draw_talent)
Define(poisoned_knife 185565)
	SpellInfo(poisoned_knife energy=40 combopoints=-1)
Define(prey_on_the_weak_debuff 255909)
	SpellInfo(prey_on_the_weak_debuff duration=6)
Define(riposte 199754)
	SpellInfo(riposte cd=120)
Define(riposte_buff 199754)
	SpellInfo(riposte_buff duration=10)

	SpellInfo(roll_the_bones energy=25 combopoints=1 max_combopoints=5)
	SpellInfo(roll_the_bones max_combopoints=6 talent=deeper_stratagem_talent)
	SpellInfo(roll_the_bones unusable=1 talent=slice_and_dice_talent)
	SpellAddBuff(roll_the_bones loaded_dice_buff=0 talent=loaded_dice_talent)

	SpellInfo(rupture combopoints=1 max_combopoints=5 energy=25)
	SpellInfo(rupture max_combopoints=6 talent=deeper_stratagem_talent)
	SpellAddTargetDebuff(rupture rupture_debuff=1)
Define(rupture_debuff 1943)
	SpellInfo(rupture_debuff add_duration_combopoints=4 duration=4 tick=2)
Define(rupture_debuff_exsanguinated -1943)
	SpellInfo(rupture_debuff_exsanguinated duration=rupture_debuff)
Define(sap 6770)
	SpellInfo(sap energy=35 stealthed=1)
	SpellInfo(sap energy=0 talent=dirty_tricks_talent)

	SpellInfo(secret_technique energy=30 cd=45 combopoints=1 max_combopoints=5)
	SpellInfo(secret_technique max_combopoints=6 talent=deeper_stratagem_talent)
	SpellRequire(secret_technique energy_percent 80=stealthed,1 talent=shadow_focus_talent)

	SpellInfo(shadow_blades cd=180)
	SpellAddBuff(shadow_blades shadow_blades_buff=1)
Define(shadow_blades_buff 121471)
	SpellInfo(shadow_blades_buff duration=20)

	SpellInfo(shadow_dance cd=60 gcd=0 charges=2)
	SpellInfo(shadow_dance charges=3 talent=enveloping_shadows_talent)
	SpellAddBuff(shadow_dance shadow_dance_buff=1)
	SpellAddBuff(shadow_dance master_of_shadows=1 talent=master_of_shadows_talent)
Define(shadow_dance_buff 185422)
	SpellInfo(shadow_dance_buff duration=5)

	SpellInfo(shadowstep cd=30 gcd=0 offgcd=1 charges=2)

	SpellInfo(shadowstrike combopoints=-2 energy=40 stealthed=1)
	SpellRequire(shadowstrike combopoints -3=buff,shadow_blades_buff)
	SpellAddTargetDebuff(shadowstrike find_weakness_debuff=1 talent=find_weakness_talent)
Define(shroud_of_concealment 114018)
	SpellInfo(shroud_of_concealment cd=360 stealthed=1)
Define(shuriken_combo_buff 245640)
	SpellInfo(shuriken_combo_buff duration=15 max_stacks=5)

	SpellInfo(shuriken_storm energy=35 combopoints=-1)
	SpellAddBuff(shuriken_storm shuriken_combo_buff=1)

	SpellInfo(shuriken_tornado energy=60 cd=60)

	SpellInfo(shuriken_toss combopoints=-1 energy=40 travel_time=1)

	SpellInfo(sinister_strike combopoints=-1 energy=45)

	SpellInfo(slice_and_dice combopoints=1 max_combopoints=5 energy=25)
	SpellInfo(slice_and_dice max_combopoints=6 talent=deeper_stratagem_talent)
	SpellAddBuff(slice_and_dice slice_and_dice_buff=1)
Define(slice_and_dice_buff 5171)
	SpellInfo(slice_and_dice add_duration_combopoints=6 duration=6)
Define(shot_in_the_dark_buff 257506)
Define(sprint 2983)
	SpellInfo(sprint cd=60)
	SpellAddBuff(sprint sprint_buff=1)
Define(sprint_buff 2983)
	SpellInfo(sprint_buff duration=8)

	SpellInfo(stealth cd=2 to_stance=rogue_stealth)
	SpellRequire(stealth unusable 1=stealthed,1)
	SpellRequire(stealth unusable 1=combat,1)
	SpellAddBuff(stealth stealth_buff=1)
	SpellAddBuff(stealth master_of_shadows=1 talent=master_of_shadows_talent specialization=subtlety)

	SpellInfo(stealth replaced_by=subterfuge_stealth talent=subterfuge_talent specialization=assassination)
	SpellInfo(stealth replaced_by=subterfuge_stealth talent=subterfuge_talent specialization=subtlety)
Define(stealth_buff 1784)
Define(subterfuge_stealth 115191)
	SpellRequire(subterfuge_stealth unusable 1=stealthed,1)
	SpellRequire(subterfuge_stealth unusable 1=combat,1)
	SpellAddBuff(subterfuge_stealth subterfuge_stealth_buff=1)
Define(subterfuge_stealth_buff 115191)
Define(subterfuge_buff 115192)
	SpellInfo(subterfuge_buff duration=3)

	SpellInfo(symbols_of_death cd=30 energy=-40 tag=shortcd)
	SpellAddBuff(symbols_of_death symbols_of_death_buff=1)
Define(symbols_of_death_buff 212283)
	SpellInfo(symbols_of_death_buff duration=10)

	SpellInfo(toxic_blade energy=20 cd=25 combopoints=-1 tag=main)


	SpellInfo(toxic_blade_debuff duration=9)
Define(tricks_of_the_trade 57934)
	SpellInfo(tricks_of_the_trade cd=30)

	SpellInfo(vanish cd=120 gcd=0)
	SpellAddBuff(vanish vanish_buff=1)
	SpellRequire(vanish unusable 1=stealthed,1)
	SpellAddBuff(vanish master_of_shadows=1 talent=master_of_shadows_talent specialization=subtlety)
Define(vanish_buff 11327)
	SpellInfo(vanish_aura duration=3)

	SpellInfo(vendetta cd=120)
	SpellAddTargetDebuff(vendetta vendetta_debuff=1)
Define(vendetta_debuff 79140)
	SpellInfo(vendetta_debuff duration=20)
Define(wound_poison 8679)
	SpellAddBuff(wound_poison wound_poison_buff=1)
	SpellAddBuff(wound_poison leeching_poison_buff talent=leeching_poison_talent)
Define(wound_poison_buff 8679)
	SpellInfo(wound_poison_buff duration=3600)
Define(wound_poison_debuff 8679)
	SpellInfo(wound_poison_debuff duration=12)


# Roll the Bones buffs
Define(broadside_buff 193356)
	SpellInfo(broadside_buff duration=12 add_duration_combopoints=6)
Define(buried_treasure_buff 199600)
	SpellInfo(buried_treasure_buff duration=12 add_duration_combopoints=6)
Define(grand_melee_buff 193358)
	SpellInfo(grand_melee_buff duration=12 add_duration_combopoints=6)
Define(ruthless_precision_buff 193357)
	SpellInfo(ruthless_precision_buff duration=12 add_duration_combopoints=6)
Define(skull_and_crossbones_buff 199603)
	SpellInfo(skull_and_crossbones_buff duration=12 add_duration_combopoints=6)
Define(true_bearing_buff 193359)
	SpellInfo(true_bearing_buff duration=12 add_duration_combopoints=6)

# Pvp talents
Define(cold_blood 213981)
	SpellInfo(cold_blood cd=60)

# Azerite Traits
Define(deadshot_buff 272935)
Define(keep_your_wits_about_you_buff 288985)



# Leegendary items
Define(the_dreadlords_deceit_item 137021)
Define(the_dreadlords_deceit_assassination_buff 208693)
Define(the_dreadlords_deceit_outlaw_buff 208692)
Define(the_dreadlords_deceit_subtlety_buff 228224)

# Talents
Define(acrobatic_strikes_talent 4)


Define(blinding_powder_talent 14)

Define(cheat_death_talent 11)

Define(dancing_steel_talent 19)


Define(dirty_tricks_talent 13)
Define(elaborate_planning_talent 2)
Define(elusiveness_talent 12)
Define(enveloping_shadows_talent 18)




Define(hidden_blades_talent 20)
Define(hit_and_run_talent 6)

Define(iron_stomach_talent 10)
Define(iron_wire_talent 14)

Define(leeching_poison_talent 10)
Define(loaded_dice_talent 16)



Define(master_poisoner_talent 1)
Define(night_terrors_talent 14)

Define(poison_bomb_talent 19)
Define(prey_on_the_weak_talent 15)

Define(retractable_hook_talent 5)


Define(shot_in_the_dark_talent 13)


Define(soothing_darkness_talent 10)




Define(weaponmaster_talent 1)

# Non-default tags for OvaleSimulationCraft.
	SpellInfo(between_the_eyes tag=main)
	SpellInfo(vanish tag=shortcd)
	SpellInfo(goremaws_bite tag=main)
]]
    OvaleScripts:RegisterScript("ROGUE", nil, name, desc, code, "include")
end
