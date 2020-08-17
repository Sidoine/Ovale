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
# A powerful aimed shot that deals s1*<mult> Physical damage. ?!s19434&c1[rnrnReplaces Cobra Shot.][]
  SpellInfo(aimed_shot focus=30 cd=12)
Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
Define(arcane_shot 185358)
# A quick shot that causes sw2*<mult> Arcane damage.
  SpellInfo(arcane_shot focus=15)
Define(aspect_of_the_eagle 186289)
# Increases the range of your ?s259387[Mongoose Bite][Raptor Strike] to 265189r yds for 15 seconds.
  SpellInfo(aspect_of_the_eagle cd=90 duration=15 gcd=0 offgcd=1)
  # The range of ?s259387[Mongoose Bite][Raptor Strike] is increased to 265189r yds.
  SpellAddBuff(aspect_of_the_eagle aspect_of_the_eagle=1)
Define(aspect_of_the_wild 193530)
# Grants you and your pet s2 Focus per sec and s1 increased critical strike chance for 20 seconds.
  SpellInfo(aspect_of_the_wild cd=120 duration=20 channel=20 gcd=1.3 tick=1)
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
# Rapidly fires a spray of shots for 3 seconds, dealing an average of <damageSec> Physical damage to all enemies in front of you. Usable while moving.
  SpellInfo(barrage focus=60 cd=20 duration=3 channel=3 tick=0.2 talent=barrage_talent_marksmanship)

Define(berserking 26297)
# Increases your haste by s1 for 12 seconds.
  SpellInfo(berserking cd=180 duration=12 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking=1)
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
Define(blur_of_talons_buff 277966)
# During Coordinated Assault, ?s259387[Mongoose Bite][Raptor Strike] increases your Agility by s1 and your Speed by s2 for 6 seconds. Stacks up to 277969u times.
  SpellInfo(blur_of_talons_buff channel=-0.001 gcd=0 offgcd=1)

Define(butchery 212436)
# Attack all nearby enemies in a flurry of strikes, inflicting s1 Physical damage to each.?s294029[rnrnReduces the remaining cooldown on Wildfire Bomb by <cdr> sec for each target hit, up to s3.][]
  SpellInfo(butchery focus=30 cd=9 talent=butchery_talent)
Define(carve 187708)
# A sweeping attack that strikes all enemies in front of you for s1 Physical damage.?s294029[rnrnReduces the remaining cooldown on Wildfire Bomb by <cdr> sec for each target hit, up to s3.][]
# Rank 2: Carve reduces the remaining cooldown on Wildfire Bomb by 187708s2/1000 sec for each target hit, up to 187708s3.
  SpellInfo(carve focus=35 cd=6)
Define(chakrams 259391)
# Throw a pair of chakrams at your target, slicing all enemies in the chakrams' path for <damage> Physical damage. The chakrams will return to you, damaging enemies again.rnrnYour primary target takes 259398s2 increased damage.
  SpellInfo(chakrams focus=30 cd=20 talent=chakrams_talent)


Define(chimaera_shot 171457)
# A two-headed shot that hits your primary target and another nearby target, dealing 171457sw2 Nature damage to one and 171454sw2 Frost damage to the other.rnrn|cFFFFFFFFGenerates 204304s1 Focus for each target hit.|r
  SpellInfo(chimaera_shot gcd=0 offgcd=1)
Define(cobra_shot 193455)
# A quick shot causing s2*<mult> Physical damage.rnrnReduces the cooldown of Kill Command by s3 sec.
# Rank 3: Cobra Shot deals s1 increased damage.
  SpellInfo(cobra_shot focus=45)
Define(coordinated_assault 266779)
# You and your pet attack as one, increasing all damage you both deal by s1 for 20 seconds.?s263186[rnrnWhile Coordinated Assault is active, Kill Command's chance to reset is increased by s4.][]
  SpellInfo(coordinated_assault cd=120 duration=20)
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
  SpellInfo(dire_beast focus=25 cd=20 duration=8 talent=dire_beast_talent)

  SpellAddTargetDebuff(dire_beast dire_beast=1)
Define(double_tap 260402)
# Your next Aimed Shot will fire a second time instantly at s4 power without consuming Focus, or your next Rapid Fire will shoot s3 additional shots during its channel.
  SpellInfo(double_tap cd=60 duration=15 talent=double_tap_talent)
  # Your next Aimed Shot will fire a second time instantly at s4 power and consume no Focus, or your next Rapid Fire will shoot s3 additional shots during its channel.
  SpellAddBuff(double_tap double_tap=1)
Define(explosive_shot 212431)
# Fires an explosive shot at your target. After t1 sec, the shot will explode, dealing 212680s1 Fire damage to all enemies within 212680A1 yards.
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
Define(flanking_strike 259516)
# You and your pet leap to the target and strike it as one, dealing a total of <damage> Physical damage.rnrn|cFFFFFFFFGenerates 269752s2 Focus for you and your pet.|r
  SpellInfo(flanking_strike gcd=0 offgcd=1 focus=-30)
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
# Apply Hunter's Mark to the target, increasing all damage you deal to the marked target by s1.  If the target dies while affected by Hunter's Mark, you instantly gain 259558s1 Focus. The target can always be seen and tracked by the Hunter.rnrnOnly one Hunter's Mark can be applied at a time.
  SpellInfo(hunters_mark talent=hunters_mark_talent)
  # Damage taken from the Hunter increased by s1.rnrnCan always be seen and tracked by the Hunter.
  SpellAddTargetDebuff(hunters_mark hunters_mark=1)
Define(kill_command 34026)
# Give the command to kill, causing your pet to savagely deal <damage> Physical damage to the enemy.
# Rank 2: Kill Command has a 259489s2 chance to immediately reset its cooldown.rnrnCoordinated Assault increases this chance by another 266779s4.
  SpellInfo(kill_command focus=30 cd=7.5 channel=0)
Define(kill_command_survival 259489)
# Give the command to kill, causing your pet to savagely deal <damage> Physical damage to the enemy.?s263186[rnrnHas a s2 chance to immediately reset its cooldown.][]rnrn|cFFFFFFFFGenerates s3 Focus.|r
  SpellInfo(kill_command_survival cd=6 channel=0 focus=-15)

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

Define(master_marksman_buff 269576)
# Aimed Shot has a h chance to reduce the focus cost of your next Arcane Shot or Multi-Shot by 269576s1.
  SpellInfo(master_marksman_buff duration=12 gcd=0 offgcd=1)
  # Focus cost of your next Arcane Shot or Multi-Shot reduced by s1.
  SpellAddBuff(master_marksman_buff master_marksman_buff=1)
Define(mongoose_bite 259387)
# A brutal attack that deals s1 Physical damage and grants you Mongoose Fury.rnrn|cFFFFFFFFMongoose Fury|rrnIncreases the damage of Mongoose Bite by 259388s1 for 14 seconds, stacking up to 259388u times. Successive attacks do not increase duration.
  SpellInfo(mongoose_bite focus=30 talent=mongoose_bite_talent)
Define(muzzle 187707)
# Interrupts spellcasting, preventing any spell in that school from being cast for 3 seconds.
  SpellInfo(muzzle cd=15 duration=3 gcd=0 offgcd=1 interrupt=1)
Define(piercing_shot 198670)
# A powerful shot which deals sw3 Physical damage to the target and up to sw3/(s1/10) Physical damage to all enemies between you and the target. rnrnPiercing Shot ignores the target's armor.
  SpellInfo(piercing_shot focus=35 cd=30 talent=piercing_shot_talent)
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
# Shoot a stream of s1 shots at your target over 3 seconds, dealing a total of m1*257045sw1 Physical damage. rnrnEach shot generates 263585s1 Focus.rnrnUsable while moving.
  SpellInfo(rapid_fire cd=20 duration=3 channel=3 tick=0.33)
  # Being targeted by Rapid Fire.
  SpellAddTargetDebuff(rapid_fire rapid_fire=1)
Define(raptor_strike 186270)
# A vicious slash dealing s1 Physical damage.
# Rank 2: Raptor Strike deals s1 increased damage.
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
Define(reckless_force_buff_0 298409)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 4 seconds.
  SpellInfo(reckless_force_buff_0 max_stacks=5 gcd=0 offgcd=1 tick=10)
  # Gaining unstable Azerite energy.
  SpellAddBuff(reckless_force_buff_0 reckless_force_buff_0=1)
Define(reckless_force_buff_1 304038)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 4 seconds.
  SpellInfo(reckless_force_buff_1 channel=-0.001 gcd=0 offgcd=1)
  SpellAddBuff(reckless_force_buff_1 reckless_force_buff_1=1)
Define(revive_pet 982)
# Revives your pet, returning it to life with s1 of its base health.
  SpellInfo(revive_pet focus=35 duration=3 channel=3)
  SpellAddBuff(revive_pet revive_pet=1)
Define(shrapnel_bomb_debuff 270336)
# Hurl a bomb at the target, exploding for 270338s1 Fire damage in a cone and impaling enemies with burning shrapnel, scorching them for 270339o1 Fire damage over 6 seconds.rnrn?s259387[Mongoose Bite][Raptor Strike] and ?s212436[Butchery][Carve] apply Internal Bleeding, causing 270343o1 damage over 9 seconds. Internal Bleeding stacks up to 270343u times.
  SpellInfo(shrapnel_bomb_debuff duration=0.5 channel=0.5 gcd=0 offgcd=1)
Define(spitting_cobra 194407)
# Summons a Spitting Cobra for 20 seconds that attacks your target for 206685s1 Nature damage every 2 sec. rnrnWhile the Cobra is active you gain s2 Focus every sec.
  SpellInfo(spitting_cobra cd=90 duration=20 tick=1 talent=spitting_cobra_talent)
  # Generating s2 additional Focus every sec.
  SpellAddBuff(spitting_cobra spitting_cobra=1)
Define(stampede 201430)
# Summon a herd of stampeding animals from the wilds around you that deal damage to your enemies for 12 seconds.
  SpellInfo(stampede cd=180 duration=12 channel=12 talent=stampede_talent)
  SpellAddBuff(stampede stampede=1)
Define(steady_shot 56641)
# A steady shot that causes s1 Physical damage and increases the duration of Concussive Shot on the target by m3/10.1 sec.rnrnUsable while moving.rnrn|cFFFFFFFFGenerates s2 Focus.
  SpellInfo(steady_shot)
Define(steel_trap 162488)
# Hurls a Steel Trap to the target location that snaps shut on the first enemy that approaches, immobilizing them for 20 seconds and causing them to bleed for 162487o1 damage over 20 seconds. rnrnDamage other than Steel Trap may break the immobilization effect. Trap will exist for 60 seconds. Limit 1.
  SpellInfo(steel_trap cd=30 talent=steel_trap_talent)

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
Define(trueshot 288613)
# Reduces the cooldown of your Aimed Shot and Rapid Fire by m1/4, and causes Aimed Shot to cast s4 faster for 15 seconds.
  SpellInfo(trueshot cd=120 duration=15)
  # The cooldown of Aimed Shot and Rapid Fire is reduced by m1/4, and Aimed Shot casts s4 faster.
  SpellAddBuff(trueshot trueshot=1)
Define(unbridled_fury_0 300714)
# Fill yourself with unbridled energy, giving your offensive spells and attacks a chance to do an additional 300717s1 Fire damage to your target. Lasts 60 seconds.
  SpellInfo(unbridled_fury_0 duration=60 gcd=0 offgcd=1)
  # Chance to deal an extra 300717s1 Fire damage to your current target.
  SpellAddBuff(unbridled_fury_0 unbridled_fury_0=1)
Define(unbridled_fury_1 300751)
# Chance to create multiple potions.
  SpellInfo(unbridled_fury_1 gcd=0 offgcd=1)
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
SpellList(blood_of_the_enemy blood_of_the_enemy_0 blood_of_the_enemy_1 blood_of_the_enemy_2 blood_of_the_enemy_3 blood_of_the_enemy_4 blood_of_the_enemy_5 blood_of_the_enemy_6)
SpellList(fireblood fireblood_0 fireblood_1)
SpellList(focused_azerite_beam focused_azerite_beam_0 focused_azerite_beam_1 focused_azerite_beam_2 focused_azerite_beam_3)
SpellList(guardian_of_azeroth guardian_of_azeroth_0 guardian_of_azeroth_1 guardian_of_azeroth_2 guardian_of_azeroth_3 guardian_of_azeroth_4 guardian_of_azeroth_5)
SpellList(purifying_blast purifying_blast_0 purifying_blast_1 purifying_blast_2 purifying_blast_3 purifying_blast_4 purifying_blast_5)
SpellList(razor_coral razor_coral_0 razor_coral_1 razor_coral_2 razor_coral_3 razor_coral_4)
SpellList(reaping_flames reaping_flames_0 reaping_flames_1 reaping_flames_2 reaping_flames_3)
SpellList(reckless_force_buff reckless_force_buff_0 reckless_force_buff_1)
SpellList(the_unbound_force the_unbound_force_0 the_unbound_force_1 the_unbound_force_2 the_unbound_force_3 the_unbound_force_4 the_unbound_force_5 the_unbound_force_6 the_unbound_force_7)
SpellList(unbridled_fury unbridled_fury_0 unbridled_fury_1)
SpellList(unerring_vision_buff unerring_vision_buff_0 unerring_vision_buff_1)
SpellList(latent_poison latent_poison_0 latent_poison_1)
Define(a_murder_of_crows_talent_survival 12) #22299
# Summons a flock of crows to attack your target, dealing 131900s1*16 Physical damage over 15 seconds. If the target dies while under attack, A Murder of Crows' cooldown is reset.
Define(alpha_predator_talent 3) #22296
# Kill Command now has s1+1 charges, and deals s2 increased damage.
Define(barrage_talent_marksmanship 17) #23104
# Rapidly fires a spray of shots for 3 seconds, dealing an average of <damageSec> Physical damage to all enemies in front of you. Usable while moving.
Define(birds_of_prey_talent 19) #22272
# Attacking your pet's target with ?s259387[Mongoose Bite][Raptor Strike] or ?s212436[Butchery][Carve] extends the duration of Coordinated Assault by <duration> sec.
Define(butchery_talent 6) #22297
# Attack all nearby enemies in a flurry of strikes, inflicting s1 Physical damage to each.?s294029[rnrnReduces the remaining cooldown on Wildfire Bomb by <cdr> sec for each target hit, up to s3.][]
Define(calling_the_shots_talent 19) #22274
# Casting Arcane Shot or Multi-Shot reduces the cooldown of Trueshot by m1/1000.1 sec.
Define(careful_aim_talent 4) #22495
# Aimed Shot deals s3 bonus damage to targets who are above s1 health or below s2 health.
Define(chakrams_talent 21) #23105
# Throw a pair of chakrams at your target, slicing all enemies in the chakrams' path for <damage> Physical damage. The chakrams will return to you, damaging enemies again.rnrnYour primary target takes 259398s2 increased damage.
Define(dire_beast_talent 3) #22282
# Summons a powerful wild beast that attacks the target and roars, increasing your Haste by 281036s1 for 8 seconds.
Define(double_tap_talent 18) #22287
# Your next Aimed Shot will fire a second time instantly at s4 power without consuming Focus, or your next Rapid Fire will shoot s3 additional shots during its channel.
Define(explosive_shot_talent 6) #22498
# Fires an explosive shot at your target. After t1 sec, the shot will explode, dealing 212680s1 Fire damage to all enemies within 212680A1 yards.
Define(guerrilla_tactics_talent 4) #21997
# Wildfire Bomb now has s1+1 charges, and the initial explosion deals s2 increased damage.
Define(hunters_mark_talent 12) #21998
# Apply Hunter's Mark to the target, increasing all damage you deal to the marked target by s1.  If the target dies while affected by Hunter's Mark, you instantly gain 259558s1 Focus. The target can always be seen and tracked by the Hunter.rnrnOnly one Hunter's Mark can be applied at a time.
Define(killer_instinct_talent 1) #22291
# Kill Command deals s1 increased damage against enemies below s2 health.
Define(mongoose_bite_talent 17) #22278
# A brutal attack that deals s1 Physical damage and grants you Mongoose Fury.rnrn|cFFFFFFFFMongoose Fury|rrnIncreases the damage of Mongoose Bite by 259388s1 for 14 seconds, stacking up to 259388u times. Successive attacks do not increase duration.
Define(one_with_the_pack_talent 5) #22266
# Wild Call has a s1 increased chance to reset the cooldown of Barbed Shot.
Define(piercing_shot_talent 21) #22288
# A powerful shot which deals sw3 Physical damage to the target and up to sw3/(s1/10) Physical damage to all enemies between you and the target. rnrnPiercing Shot ignores the target's armor.
Define(spitting_cobra_talent 21) #22295
# Summons a Spitting Cobra for 20 seconds that attacks your target for 206685s1 Nature damage every 2 sec. rnrnWhile the Cobra is active you gain s2 Focus every sec.
Define(stampede_talent 18) #23044
# Summon a herd of stampeding animals from the wilds around you that deal damage to your enemies for 12 seconds.
Define(steel_trap_talent 11) #19361
# Hurls a Steel Trap to the target location that snaps shut on the first enemy that approaches, immobilizing them for 20 seconds and causing them to bleed for 162487o1 damage over 20 seconds. rnrnDamage other than Steel Trap may break the immobilization effect. Trap will exist for 60 seconds. Limit 1.
Define(streamline_talent 11) #22286
# Rapid Fire now lasts s3 longer.
Define(terms_of_engagement_talent 2) #22283
# Harpoon deals 271625s1 Physical damage and generates (265898s1/5)*10 seconds Focus over 10 seconds. Killing an enemy resets the cooldown of Harpoon.
Define(vipers_venom_talent 1) #22275
# ?s259387[Mongoose Bite][Raptor Strike] has a chance to make your next Serpent Sting cost no Focus and deal an additional 268552s1 initial damage.
Define(wildfire_infusion_talent 20) #22301
# Lace your Wildfire Bomb with extra reagents, randomly giving it one of the following enhancements each time you throw it:rnrn|cFFFFFFFFShrapnel Bomb: |rShrapnel pierces the targets, causing ?s259387[Mongoose Bite][Raptor Strike] and ?s212436[Butchery][Carve] to apply a bleed for 9 seconds that stacks up to 270343u times.rnrn|cFFFFFFFFPheromone Bomb: |rKill Command has a 270323s2 chance to reset against targets coated with Pheromones.rnrn|cFFFFFFFFVolatile Bomb: |rReacts violently with poison, causing an extra explosion against enemies suffering from your Serpent Sting and refreshes your Serpent Stings.
Define(azsharas_font_of_power_item 169314)
Define(cyclotronic_blast_item 167672)
Define(unbridled_fury_item 169299)
Define(variable_intensity_gigavolt_oscillating_reactor_item 165572)
Define(dribbling_inkpod_item 169319)
Define(dance_of_death_trait 274441)
Define(primal_instincts_trait 279806)
Define(rapid_reload_trait 278530)
Define(focused_fire_trait 278531)
Define(in_the_rhythm_trait 264198)
Define(surging_shots_trait 287707)
Define(unerring_vision_trait 274444)
Define(condensed_life_force_essence_id 14)
Define(essence_of_the_focusing_iris_essence_id 5)
Define(blood_of_the_enemy_essence_id 23)
Define(spark_of_inspiration_essence_id 36)
Define(memory_of_lucid_dreams_essence_id 27)
    ]]
    OvaleScripts:RegisterScript("HUNTER", nil, name, desc, code, "include")
end
