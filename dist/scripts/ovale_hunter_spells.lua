local __exports = LibStub:NewLibrary("ovale/scripts/ovale_hunter_spells", 80300)
if not __exports then return end
__exports.registerHunterSpells = function(OvaleScripts)
    local name = "ovale_hunter_spells"
    local desc = "[9.0] Ovale: Hunter spells"
    local code = [[Define(a_murder_of_crows 131894)
# Summons a flock of crows to attack your target, dealing 131900s1*16 Physical damage over 15 seconds. If the target dies while under attack, A Murder of Crows' cooldown is reset.
  SpellInfo(a_murder_of_crows focus=30 cd=60 duration=15 tick=1 talent=a_murder_of_crows_talent_survival)
  # Under attack by a flock of crows.
  SpellAddTargetDebuff(a_murder_of_crows a_murder_of_crows=1)
Define(aimed_shot 19434)
# A powerful aimed shot that deals s1 Physical damage.
  SpellInfo(aimed_shot focus=35 cd=12)
Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
Define(arcane_shot 185358)
# A quick shot that causes sw2 Arcane damage.
# Rank 2: Arcane Shot Focus cost reduced by s1.
  SpellInfo(arcane_shot focus=30)
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
# Remove s1 beneficial effect from all enemies within A1 yards and restore ?s137027[s2 Holy Power][s3 of your mana].
  SpellInfo(arcane_torrent_6 cd=120 holypower=-1)
Define(arcane_torrent_7 202719)
# Remove s1 beneficial effect from all enemies within A1 yards and generate ?s203513[m3/10 Pain][m2 Fury].
  SpellInfo(arcane_torrent_7 cd=120 fury=-15 pain=-15)
Define(arcane_torrent_8 232633)
# Remove s1 beneficial effect from all enemies within A1 yards and restore ?s137033[s3/100 Insanity][s2 of your mana].
  SpellInfo(arcane_torrent_8 cd=120 insanity=-1500)
Define(aspect_of_the_eagle 186289)
# Increases the range of your ?s259387[Mongoose Bite][Raptor Strike] to 265189r yds for 15 seconds.
  SpellInfo(aspect_of_the_eagle cd=90 duration=15 gcd=0 offgcd=1)
  # The range of ?s259387[Mongoose Bite][Raptor Strike] is increased to 265189r yds.
  SpellAddBuff(aspect_of_the_eagle aspect_of_the_eagle=1)
Define(aspect_of_the_wild 193530)
# Grants you and your pet s2 Focus per sec and s1 increased critical strike chance for 20 seconds.
  SpellInfo(aspect_of_the_wild cd=120 duration=20 channel=20 gcd=0 offgcd=1 tick=1)
  # Gaining s2 Focus per sec.rnCritical Strike chance increased by s1.
  SpellAddBuff(aspect_of_the_wild aspect_of_the_wild=1)
Define(bag_of_tricks 312411)
# Pull your chosen trick from the bag and use it on target enemy or ally. Enemies take <damage> damage, while allies are healed for <healing>. 
  SpellInfo(bag_of_tricks cd=90)
Define(barbed_shot 217200)
# Fire a shot that tears through your enemy, causing them to bleed for s1*s2 damage over 8 seconds.rnrnSends your pet into a frenzy, increasing attack speed by 272790s1 for 8 seconds, stacking up to 272790u times.rnrn|cFFFFFFFFGenerates 246152s1*8 seconds/246152t1 Focus over 8 seconds.|r
  SpellInfo(barbed_shot cd=12 duration=8 tick=2)
  # Suffering sw1 damage every t1 sec.
  SpellAddTargetDebuff(barbed_shot barbed_shot=1)
Define(barrage 120360)
# Rapidly fires a spray of shots for 3 seconds, dealing an average of <damageSec> Physical damage to up to 120361I enemies in front of you. Usable while moving.
  SpellInfo(barrage focus=60 cd=20 duration=3 channel=3 tick=0.2 talent=barrage_talent_marksmanship)

Define(berserking 59621)
# Permanently enchant a melee weapon to sometimes increase your attack power by 59620s1, but at the cost of reduced armor. Cannot be applied to items higher than level ecix
  SpellInfo(berserking gcd=0 offgcd=1)
Define(berserking_buff 200953)
# Rampage and Execute have a chance to activate Berserking, increasing your attack speed and critical strike chance by 200953s1 every 200951t1 sec for 12 seconds.
  SpellInfo(berserking_buff duration=3 max_stacks=12 gcd=0 offgcd=1)
  # Attack speed and critical strike chance increased by s1.
  SpellAddBuff(berserking_buff berserking_buff=1)
Define(bestial_wrath 19574)
# Sends you and your pet into a rage, increasing all damage you both deal by s1 for 15 seconds. ?s231548&s217200[rnrnBestial Wrath's remaining cooldown is reduced by s3 sec each time you use Barbed Shot.][]
# Rank 2: Bestial Wrath's remaining cooldown is reduced by 19574s3 sec each time you use Barbed Shot.
  SpellInfo(bestial_wrath cd=90 duration=15 channel=15)
  # Damage dealt increased by w1.
  SpellAddBuff(bestial_wrath bestial_wrath=1)
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
Define(bloodshed 321530)
# Command your pet to tear into your target, causing your target to bleed for <damage> over 18 seconds and increase all damage taken from your pet by 321538s2 for 18 seconds.
  SpellInfo(bloodshed cd=60 channel=0 talent=bloodshed_talent)
Define(blur_of_talons_buff 277966)
# During Coordinated Assault, ?s259387[Mongoose Bite][Raptor Strike] increases your Agility by s1 and your Speed by s2 for 6 seconds. Stacks up to 277969u times.
  SpellInfo(blur_of_talons_buff channel=-0.001 gcd=0 offgcd=1)

Define(butchery 212436)
# Attack up to I nearby enemies in a flurry of strikes, inflicting s1 Physical damage to each.?s294029[rnrnReduces the remaining cooldown on Wildfire Bomb by <cdr> sec for each target hit.][]
  SpellInfo(butchery focus=30 cd=9 talent=butchery_talent)
Define(carve 187708)
# A sweeping attack that strikes up to I enemies in front of you for s1 Physical damage.?s294029[rnrnReduces the remaining cooldown on Wildfire Bomb by <cdr> sec for each target hit, up to s3.][]
# Rank 2: Carve reduces the remaining cooldown on Wildfire Bomb by 187708s2/1000 sec for each target hit, up to 187708s3.
  SpellInfo(carve focus=35 cd=6)
Define(chakrams 259391)
# Throw a pair of chakrams at your target, slicing all enemies in the chakrams' path for <damage> Physical damage. The chakrams will return to you, damaging enemies again.rnrnYour primary target takes 259398s2 increased damage.
  SpellInfo(chakrams focus=15 cd=20 talent=chakrams_talent)


Define(chimaera_shot 53209)
# A two-headed shot that hits your primary target and another nearby target, dealing 171457sw2 Nature damage to one and 171454sw2 Frost damage to the other.?s137015[rnrn|cFFFFFFFFGenerates 204304s1 Focus for each target hit.|r][]
  SpellInfo(chimaera_shot cd=15 talent=chimaera_shot_talent_beast_mastery)
Define(chimaera_shot_marksmanship 342049)
# A two-headed shot that hits your primary target and another nearby target, dealing 344120sw1 Nature damage to one and 344121sw1 Frost damage to the other.
  SpellInfo(chimaera_shot_marksmanship focus=20 talent=chimaera_shot_talent)
Define(cobra_shot 193455)
# A quick shot causing s2*<mult> Physical damage.rnrnReduces the cooldown of Kill Command by s3 sec.
# Rank 2: Cobra Shot deals s1 increased damage.
  SpellInfo(cobra_shot focus=45)
  SpellInfo(steady_shot replaced_by=cobra_shot)
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
Define(coordinated_assault 266779)
# You and your pet attack as one, increasing all damage you both deal by s1 for 20 seconds.?s263186[rnrnWhile Coordinated Assault is active, Kill Command's chance to reset is increased by s4.][]
  SpellInfo(coordinated_assault cd=120 duration=20 gcd=0 offgcd=1)
  # Damage dealt increased by s1.?s263186[rnKill Command's chance to reset increased by s4.][]
  SpellAddBuff(coordinated_assault coordinated_assault=1)
Define(counter_shot 147362)
# Interrupts spellcasting, preventing any spell in that school from being cast for 3 seconds.
  SpellInfo(counter_shot cd=24 duration=3 gcd=0 offgcd=1 interrupt=1)
Define(cyclotronic_blast 293491)
# Channel a cyclotronic blast, dealing a total of o1 Fire damage over D.
  SpellInfo(cyclotronic_blast cd=120 duration=2.5 channel=2.5 tick=0.5)
  # Burning for o1 Fire damage.
  SpellAddTargetDebuff(cyclotronic_blast cyclotronic_blast=1)
Define(dance_of_death_buff 274442)
# Barbed Shot has a chance equal to your critical strike chance to grant you s1 Agility for 8 seconds.
  SpellInfo(dance_of_death_buff channel=-0.001 gcd=0 offgcd=1)

Define(dire_beast 120679)
# Summons a powerful wild beast that attacks the target and roars, increasing your Haste by 281036s1 for 8 seconds.
  SpellInfo(dire_beast cd=20 duration=8 talent=dire_beast_talent)

  SpellAddTargetDebuff(dire_beast dire_beast=1)
Define(double_tap 260402)
# Your next Aimed Shot will fire a second time instantly at s4 power without consuming Focus, or your next Rapid Fire will shoot s3 additional shots during its channel.
  SpellInfo(double_tap cd=60 duration=15 talent=double_tap_talent)
  # Your next Aimed Shot will fire a second time instantly at s4 power and consume no Focus, or your next Rapid Fire will shoot s3 additional shots during its channel.
  SpellAddBuff(double_tap double_tap=1)
Define(explosive_shot 212431)
# Fires an explosive shot at your target. After t1 sec, the shot will explode, dealing 212680s1 Fire damage to up to 212680I enemies within 212680A1 yards.
  SpellInfo(explosive_shot focus=20 cd=30 duration=3 tick=3 talent=explosive_shot_talent)
  # Exploding for 212680s1 Fire damage after t1 sec.
  SpellAddTargetDebuff(explosive_shot explosive_shot=1)
Define(fireblood_0 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. ?s195710[This effect shares a 30 sec cooldown with other similar effects.][]
  SpellInfo(fireblood_0 cd=120 gcd=0 offgcd=1)
Define(fireblood_1 265226)
# Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by s1.
  SpellInfo(fireblood_1 duration=8 max_stacks=6 gcd=0 offgcd=1)
  # Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by w1.
  SpellAddBuff(fireblood_1 fireblood_1=1)
Define(flanking_strike 269751)
# You and your pet leap to the target and strike it as one, dealing a total of <damage> Physical damage.rnrn|cFFFFFFFFGenerates 269752s2 Focus for you and your pet.|r
  SpellInfo(flanking_strike cd=30 channel=0 talent=flanking_strike_talent)
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
  SpellAddBuff(guardian_of_azeroth_5 guardian_of_azeroth_buff=1)
Define(guardian_of_azeroth_buff 303349)
  SpellInfo(guardian_of_azeroth_buff gcd=0 offgcd=1)

Define(harpoon 190925)
# Hurls a harpoon at an enemy, rooting them in place for 3 seconds and pulling you to them.
# Rank 2: The cooldown of Harpoon is reduced by m1/-1000 sec.
  SpellInfo(harpoon cd=1 charge_cd=30 gcd=0 offgcd=1)

Define(hunters_mark 257284)
# Apply Hunter's Mark to the target, increasing all damage you deal to the marked target by s1. The target can always be seen and tracked by the Hunter.rnrnOnly one Hunter's Mark can be applied at a time.rnrnThe cooldown of Hunter's Mark is reset if the target dies.
  SpellInfo(hunters_mark cd=20 gcd=1)
  # Damage taken from @auracaster increased by s1?a339264[ and damage dealt to @auracaster is reduced by 339264s1][].rnrnCan always be seen and tracked by the Hunter.
  SpellAddTargetDebuff(hunters_mark hunters_mark=1)
Define(in_the_rhythm 272733)
# When Rapid Fire finishes fully channeling, your Haste is increased by s1 for 8 seconds.
  SpellInfo(in_the_rhythm duration=8 gcd=0 offgcd=1)
  # Haste increased by w1.
  SpellAddBuff(in_the_rhythm in_the_rhythm=1)

Define(kill_command_0 34026)
# Give the command to kill, causing your pet to savagely deal <damage> Physical damage to the enemy.
# Rank 2: Kill Command has a 259489s2 chance to immediately reset its cooldown.rnrnCoordinated Assault increases this chance by another 266779s4.
  SpellInfo(kill_command_0 focus=30 cd=7.5 channel=0)
Define(kill_command_1 259489)
# Give the command to kill, causing your pet to savagely deal <damage> Physical damage to the enemy.?s263186[rnrnHas a s2 chance to immediately reset its cooldown.][]rnrn|cFFFFFFFFGenerates s3 Focus.|r
  SpellInfo(kill_command_1 cd=6 channel=0 focus=-15)

Define(kill_shot 53351)
# You attempt to finish off a wounded target, dealing s1 Physical damage. Only usable on enemies with less than s2 health.
# Rank 2: Kill Shot's critical damage is increased by s1.
  SpellInfo(kill_shot focus=10 cd=10)
Define(latent_poison_0 273286)
# Serpent Sting damage applies Latent Poison, stacking up to 273286u times. Your ?s259387[Mongoose Bite][Raptor Strike] consumes all applications of Latent Poison to deal s1 Nature damage per stack.
  SpellInfo(latent_poison_0 duration=20 max_stacks=10 gcd=0 offgcd=1)
  # The Hunter's next Raptor Strike or Mongoose Bite will consume all stacks of Latent Poison to deal additional Nature damage.
  SpellAddTargetDebuff(latent_poison_0 latent_poison_0=1)
Define(latent_poison_1 273289)
# Serpent Sting damage applies Latent Poison, stacking up to 273286u times. Your ?s259387[Mongoose Bite][Raptor Strike] consumes all applications of Latent Poison to deal s1 Nature damage per stack.
  SpellInfo(latent_poison_1 gcd=0 offgcd=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)

Define(memory_of_lucid_dreams_0 299300)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams_0)
Define(memory_of_lucid_dreams_1 299302)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams_1)
Define(memory_of_lucid_dreams_2 299304)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams_2)
Define(mongoose_bite 259387)
# A brutal attack that deals s1 Physical damage and grants you Mongoose Fury.rnrn|cFFFFFFFFMongoose Fury|rrnIncreases the damage of Mongoose Bite by 259388s1 for 14 seconds, stacking up to 259388u times. Successive attacks do not increase duration.
  SpellInfo(mongoose_bite focus=30 talent=mongoose_bite_talent)
Define(mongoose_fury 259388)
# A brutal attack that deals s1 Physical damage and grants you Mongoose Fury.rnrn|cFFFFFFFFMongoose Fury|rrnIncreases the damage of Mongoose Bite by 259388s1 for 14 seconds, stacking up to 259388u times. Successive attacks do not increase duration.
  SpellInfo(mongoose_fury duration=14 max_stacks=5 gcd=0 offgcd=1)
  # Mongoose Bite damage increased by s1.
  SpellAddBuff(mongoose_fury mongoose_fury=1)
Define(muzzle 187707)
# Interrupts spellcasting, preventing any spell in that school from being cast for 3 seconds.
  SpellInfo(muzzle cd=15 duration=3 gcd=0 offgcd=1 interrupt=1)
Define(precise_shots 260240)
# Aimed Shot causes your next 1-260242u ?s342049[Chimaera Shots][Arcane Shots] or Multi-Shots to deal 260242s1 more damage.
  SpellInfo(precise_shots channel=0 gcd=0 offgcd=1)
  SpellAddBuff(precise_shots precise_shots=1)
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
Define(rapid_fire 257044)
# Shoot a stream of s1 shots at your target over 2 seconds, dealing a total of m1*257045sw1 Physical damage. ?s321281[rnrnEach shot generates 263585s1 Focus.][]rnrnUsable while moving.
# Rank 2: Each shot of Rapid Fire now generates 263585s1 Focus.
  SpellInfo(rapid_fire cd=20 duration=2 channel=2 tick=0.33)
  # Being targeted by Rapid Fire.
  SpellAddTargetDebuff(rapid_fire rapid_fire=1)
Define(raptor_strike 186270)
# A vicious slash dealing s1 Physical damage.
  SpellInfo(raptor_strike focus=30)
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
Define(revive_pet 982)
# Revives your pet, returning it to life with s1 of its base health.
  SpellInfo(revive_pet focus=35 duration=3 channel=3)
  SpellAddBuff(revive_pet revive_pet=1)
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
Define(serpent_sting_0 259491)
# Fire a poison-tipped arrow at an enemy, dealing s1 Nature damage instantly and an additional o2 damage over 12 seconds.
  SpellInfo(serpent_sting_0 focus=20 duration=12 tick=3)
  # Suffering w2 Nature damage every t2 sec.?a265428[ The Hunter's pet deals w3 increased damage to you.][]
  SpellAddTargetDebuff(serpent_sting_0 serpent_sting_0=1)
Define(serpent_sting_1 271788)
# Fire a shot that poisons your target, causing them to take s1 Nature damage instantly and an additional o2 Nature damage over 18 seconds.
  SpellInfo(serpent_sting_1 focus=10 duration=18 tick=3 talent=serpent_sting_talent)
  # Suffering s2 Nature damage every t2 sec.
  SpellAddTargetDebuff(serpent_sting_1 serpent_sting_1=1)
Define(shrapnel_bomb_debuff 270336)
# Hurl a bomb at the target, exploding for 270338s1 Fire damage in a cone and impaling enemies with burning shrapnel, scorching them for 270339o1 Fire damage over 6 seconds.rnrn?s259387[Mongoose Bite][Raptor Strike] and ?s212436[Butchery][Carve] apply Internal Bleeding, causing 270343o1 damage over 9 seconds. Internal Bleeding stacks up to 270343u times.
  SpellInfo(shrapnel_bomb_debuff duration=0.5 channel=0.5 gcd=0 offgcd=1)
Define(stampede 201430)
# Summon a herd of stampeding animals from the wilds around you that deal damage to your enemies for 12 seconds.
  SpellInfo(stampede cd=120 duration=12 channel=12 talent=stampede_talent)
  SpellAddBuff(stampede stampede=1)
Define(steady_shot 56641)
# A steady shot that causes s1 Physical damage.rnrnUsable while moving.?s321018[rnrn|cFFFFFFFFGenerates s2 Focus.][]
# Rank 2: Steady Shot now generates s1 Focus.
  SpellInfo(steady_shot)
Define(steel_trap 162488)
# Hurls a Steel Trap to the target location that snaps shut on the first enemy that approaches, immobilizing them for 20 seconds and causing them to bleed for 162487o1 damage over 20 seconds. rnrnDamage other than Steel Trap may break the immobilization effect. Trap will exist for 60 seconds. Limit 1.
  SpellInfo(steel_trap cd=30 talent=steel_trap_talent)

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
Define(tip_of_the_spear 260285)
# Kill Command increases the damage of your next Raptor Strike by 260286s1, stacking up to 260286u times.
  SpellInfo(tip_of_the_spear channel=0 gcd=0 offgcd=1 talent=tip_of_the_spear_talent)
  SpellAddBuff(tip_of_the_spear tip_of_the_spear=1)
Define(trick_shots 257621)
# When Multi-Shot hits s2 or more targets, your next Aimed Shot or Rapid Fire will ricochet and hit up to s1 additional targets for s4 of normal damage.
  SpellInfo(trick_shots channel=0 gcd=0 offgcd=1)
  SpellAddBuff(trick_shots trick_shots=1)
Define(trueshot 288613)
# Reduces the cooldown of your Aimed Shot and Rapid Fire by m1/4, and causes Aimed Shot to cast s4 faster for 15 seconds.
  SpellInfo(trueshot cd=120 duration=15 gcd=0 offgcd=1)
  # The cooldown of Aimed Shot and Rapid Fire is reduced by m1/4, and Aimed Shot casts s4 faster.
  SpellAddBuff(trueshot trueshot=1)
Define(unbridled_fury 300714)
# Fill yourself with unbridled energy, giving your offensive spells and attacks a chance to do an additional 300717s1 Fire damage to your target. Lasts 60 seconds.
  SpellInfo(unbridled_fury duration=60 gcd=0 offgcd=1)
  # Chance to deal an extra 300717s1 Fire damage to your current target.
  SpellAddBuff(unbridled_fury unbridled_fury=1)
Define(unerring_vision_buff_0 274445)
# While Trueshot is active you gain s1 Critical Strike rating every sec, stacking up to 10 times.
  SpellInfo(unerring_vision_buff_0 channel=-0.001 gcd=0 offgcd=1)

Define(unerring_vision_buff_1 274447)
# While Trueshot is active you gain s1 Critical Strike rating every sec, stacking up to 10 times.
  SpellInfo(unerring_vision_buff_1 duration=5 max_stacks=10 gcd=0 offgcd=1)
  # Critical Strike increased by w1.
  SpellAddBuff(unerring_vision_buff_1 unerring_vision_buff_1=1)

Define(vipers_venom_buff 268552)
# ?s259387[Mongoose Bite][Raptor Strike] has a chance to make your next Serpent Sting cost no Focus and deal an additional 268552s1 initial damage.
  SpellInfo(vipers_venom_buff duration=8 channel=8 gcd=0 offgcd=1)
  # Your next Serpent Sting costs no Focus, and will deal s1 increased initial damage.
  SpellAddBuff(vipers_venom_buff vipers_venom_buff=1)
Define(volley 260243)
# Rain a volley of arrows down over 6 seconds, dealing up to 260247s1*12 Physical damage to any enemy in the area, and gain the effects of Trick Shots for as long as Volley is active.
  SpellInfo(volley cd=45 duration=6 tick=0.5 talent=volley_talent)
  # Raining arrows down in the target area.
  SpellAddBuff(volley volley=1)
Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp=1)
Define(wildfire_bomb 259495)
# Hurl a bomb at the target, exploding for 265157s1 Fire damage in a cone and coating enemies in wildfire, scorching them for 269747o1 Fire damage over 6 seconds.
  SpellInfo(wildfire_bomb cd=18)
  SpellAddTargetDebuff(wildfire_bomb wildfire_bomb_debuff=1)
Define(wildfire_bomb_debuff 265163)
# Hurl a bomb at the target, exploding for 265157s1 Fire damage in a cone and coating enemies in wildfire, scorching them for 269747o1 Fire damage over 6 seconds.
  SpellInfo(wildfire_bomb_debuff duration=0.5 channel=0.5 gcd=0 offgcd=1)
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
Define(worldvein_resonance_buff 295206)
  SpellInfo(worldvein_resonance_buff channel=0 gcd=0 offgcd=1)

SpellList(blood_fury blood_fury_0 blood_fury_1 blood_fury_2 blood_fury_3)
SpellList(blood_of_the_enemy blood_of_the_enemy_0 blood_of_the_enemy_1 blood_of_the_enemy_2 blood_of_the_enemy_3)
SpellList(concentrated_flame concentrated_flame_0 concentrated_flame_1 concentrated_flame_2 concentrated_flame_3 concentrated_flame_4 concentrated_flame_5 concentrated_flame_6)
SpellList(fireblood fireblood_0 fireblood_1)
SpellList(focused_azerite_beam focused_azerite_beam_0 focused_azerite_beam_1 focused_azerite_beam_2 focused_azerite_beam_3)
SpellList(guardian_of_azeroth guardian_of_azeroth_0 guardian_of_azeroth_1 guardian_of_azeroth_2 guardian_of_azeroth_3 guardian_of_azeroth_4 guardian_of_azeroth_5)
SpellList(kill_command kill_command_0 kill_command_1)
SpellList(memory_of_lucid_dreams memory_of_lucid_dreams_0 memory_of_lucid_dreams_1 memory_of_lucid_dreams_2)
SpellList(purifying_blast purifying_blast_0 purifying_blast_1 purifying_blast_2 purifying_blast_3 purifying_blast_4 purifying_blast_5)
SpellList(razor_coral razor_coral_0 razor_coral_1 razor_coral_2 razor_coral_3 razor_coral_4)
SpellList(reaping_flames reaping_flames_0 reaping_flames_1 reaping_flames_2 reaping_flames_3 reaping_flames_4)
SpellList(reckless_force_buff reckless_force_buff_0 reckless_force_buff_1)
SpellList(ripple_in_space ripple_in_space_0 ripple_in_space_1 ripple_in_space_2 ripple_in_space_3)
SpellList(the_unbound_force the_unbound_force_0 the_unbound_force_1 the_unbound_force_2 the_unbound_force_3)
SpellList(worldvein_resonance worldvein_resonance_0 worldvein_resonance_1 worldvein_resonance_2 worldvein_resonance_3)
SpellList(serpent_sting serpent_sting_0 serpent_sting_1)
SpellList(unerring_vision_buff unerring_vision_buff_0 unerring_vision_buff_1)
SpellList(arcane_torrent arcane_torrent_0 arcane_torrent_1 arcane_torrent_2 arcane_torrent_3 arcane_torrent_4 arcane_torrent_5 arcane_torrent_6 arcane_torrent_7 arcane_torrent_8)
SpellList(latent_poison latent_poison_0 latent_poison_1)
Define(a_murder_of_crows_talent_survival 12) #22299
# Summons a flock of crows to attack your target, dealing 131900s1*16 Physical damage over 15 seconds. If the target dies while under attack, A Murder of Crows' cooldown is reset.
Define(alpha_predator_talent 3) #22296
# Kill Command now has s1+1 charges, and deals s2 increased damage.
Define(barrage_talent_marksmanship 5) #22497
# Rapidly fires a spray of shots for 3 seconds, dealing an average of <damageSec> Physical damage to up to 120361I enemies in front of you. Usable while moving.
Define(birds_of_prey_talent 19) #22272
# Attacking your pet's target with ?s259387[Mongoose Bite][Raptor Strike] or ?s212436[Butchery][Carve] extends the duration of Coordinated Assault by <duration> sec.
Define(bloodshed_talent 21) #22295
# Command your pet to tear into your target, causing your target to bleed for <damage> over 18 seconds and increase all damage taken from your pet by 321538s2 for 18 seconds.
Define(butchery_talent 6) #22297
# Attack up to I nearby enemies in a flurry of strikes, inflicting s1 Physical damage to each.?s294029[rnrnReduces the remaining cooldown on Wildfire Bomb by <cdr> sec for each target hit.][]
Define(calling_the_shots_talent 19) #22274
# Casting ?s342049[Chimaera Shot][Arcane Shot] or Multi-Shot reduces the cooldown of Trueshot by m1/1000.1 sec.
Define(careful_aim_talent 4) #22495
# Aimed Shot deals s3 bonus damage to targets who are above s1 health.
Define(chakrams_talent 21) #23105
# Throw a pair of chakrams at your target, slicing all enemies in the chakrams' path for <damage> Physical damage. The chakrams will return to you, damaging enemies again.rnrnYour primary target takes 259398s2 increased damage.
Define(chimaera_shot_talent 12) #21998
# A two-headed shot that hits your primary target and another nearby target, dealing 344120sw1 Nature damage to one and 344121sw1 Frost damage to the other.
Define(chimaera_shot_talent_beast_mastery 6) #22290
# A two-headed shot that hits your primary target and another nearby target, dealing 171457sw2 Nature damage to one and 171454sw2 Frost damage to the other.?s137015[rnrn|cFFFFFFFFGenerates 204304s1 Focus for each target hit.|r][]
Define(dire_beast_talent 3) #22282
# Summons a powerful wild beast that attacks the target and roars, increasing your Haste by 281036s1 for 8 seconds.
Define(double_tap_talent 18) #22287
# Your next Aimed Shot will fire a second time instantly at s4 power without consuming Focus, or your next Rapid Fire will shoot s3 additional shots during its channel.
Define(explosive_shot_talent 6) #22498
# Fires an explosive shot at your target. After t1 sec, the shot will explode, dealing 212680s1 Fire damage to up to 212680I enemies within 212680A1 yards.
Define(flanking_strike_talent 18) #22271
# You and your pet leap to the target and strike it as one, dealing a total of <damage> Physical damage.rnrn|cFFFFFFFFGenerates 269752s2 Focus for you and your pet.|r
Define(guerrilla_tactics_talent 4) #21997
# Wildfire Bomb now has s1+1 charges, and the initial explosion deals s2 increased damage.
Define(hydras_bite_talent 5) #22769
# Serpent Sting fires arrows at s1 additional enemies near your target, and its damage over time is increased by s2.
Define(killer_instinct_talent 1) #22291
# Kill Command deals s1 increased damage against enemies below s2 health.
Define(lethal_shots_talent 16) #23063
# ?s342049[Chimaera Shot][Arcane Shot] and Multi-Shot have a h chance to reduce the cooldown of Rapid Fire by m1/10.1 sec.
Define(mongoose_bite_talent 17) #22278
# A brutal attack that deals s1 Physical damage and grants you Mongoose Fury.rnrn|cFFFFFFFFMongoose Fury|rrnIncreases the damage of Mongoose Bite by 259388s1 for 14 seconds, stacking up to 259388u times. Successive attacks do not increase duration.
Define(one_with_the_pack_talent 5) #22266
# Wild Call has a s1 increased chance to reset the cooldown of Barbed Shot.
Define(serpent_sting_talent 2) #22501
# Fire a shot that poisons your target, causing them to take s1 Nature damage instantly and an additional o2 Nature damage over 18 seconds.
Define(stampede_talent 18) #23044
# Summon a herd of stampeding animals from the wilds around you that deal damage to your enemies for 12 seconds.
Define(steel_trap_talent 11) #19361
# Hurls a Steel Trap to the target location that snaps shut on the first enemy that approaches, immobilizing them for 20 seconds and causing them to bleed for 162487o1 damage over 20 seconds. rnrnDamage other than Steel Trap may break the immobilization effect. Trap will exist for 60 seconds. Limit 1.
Define(streamline_talent 11) #22286
# Rapid Fire's damage is increased by s1, and Rapid Fire also causes your next Aimed Shot to cast 342076s1 faster.
Define(terms_of_engagement_talent 2) #22283
# Harpoon deals 271625s1 Physical damage and generates (265898s1/5)*10 seconds Focus over 10 seconds. Killing an enemy resets the cooldown of Harpoon.
Define(tip_of_the_spear_talent 16) #22300
# Kill Command increases the damage of your next Raptor Strike by 260286s1, stacking up to 260286u times.
Define(vipers_venom_talent 1) #22275
# ?s259387[Mongoose Bite][Raptor Strike] has a chance to make your next Serpent Sting cost no Focus and deal an additional 268552s1 initial damage.
Define(volley_talent 21) #22288
# Rain a volley of arrows down over 6 seconds, dealing up to 260247s1*12 Physical damage to any enemy in the area, and gain the effects of Trick Shots for as long as Volley is active.
Define(wildfire_infusion_talent 20) #22301
# Lace your Wildfire Bomb with extra reagents, randomly giving it one of the following enhancements each time you throw it:rnrn|cFFFFFFFFShrapnel Bomb: |rShrapnel pierces the targets, causing ?s259387[Mongoose Bite][Raptor Strike] and ?s212436[Butchery][Carve] to apply a bleed for 9 seconds that stacks up to 270343u times.rnrn|cFFFFFFFFPheromone Bomb: |rKill Command has a 270323s2 chance to reset against targets coated with Pheromones.rnrn|cFFFFFFFFVolatile Bomb: |rReacts violently with poison, causing an extra explosion against enemies suffering from your Serpent Sting and refreshes your Serpent Stings.
Define(azsharas_font_of_power_item 169314)
Define(cyclotronic_blast_item 167672)
Define(variable_intensity_gigavolt_oscillating_reactor_item 165572)
Define(dance_of_death_trait 274441)
Define(primal_instincts_trait 279806)
Define(rapid_reload_trait 278530)
Define(focused_fire_trait 278531)
Define(in_the_rhythm_trait 264198)
Define(surging_shots_trait 287707)
Define(unerring_vision_trait 274444)
Define(blur_of_talons_trait 277653)
Define(latent_poison_trait 273283)
Define(wilderness_survival_trait 278532)
Define(blood_of_the_enemy_essence_id 23)
Define(essence_of_the_focusing_iris_essence_id 5)
Define(vision_of_perfection_essence_id 22)
Define(memory_of_lucid_dreams_essence_id 27)
    ]]
    OvaleScripts:RegisterScript("HUNTER", nil, name, desc, code, "include")
end
