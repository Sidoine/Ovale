local __exports = LibStub:NewLibrary("ovale/scripts/ovale_warrior_spells", 80300)
if not __exports then return end
__exports.registerWarriorSpells = function(OvaleScripts)
    local name = "ovale_warrior_spells"
    local desc = "[8.2] Ovale: Warrior spells"
    local code = [[
Define(ancestral_call 274738)
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
Define(avatar 107574)
# Transform into a colossus for 20 seconds, causing you to deal s1 increased damage and removing all roots and snares.rnrn|cFFFFFFFFGenerates s5/10 Rage.|r
  SpellInfo(avatar cd=90 duration=20 rage=-20 talent=avatar_talent)
  # Damage done increased by s1.
  SpellAddBuff(avatar avatar=1)
Define(bag_of_tricks 312411)
# Pull your chosen trick from the bag and use it on target enemy or ally. Enemies take <damage> damage, while allies are healed for <healing>.
  SpellInfo(bag_of_tricks cd=90)
Define(berserking 26297)
# Increases your haste by s1 for 12 seconds.
  SpellInfo(berserking cd=180 duration=12 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking=1)
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
Define(bloodthirst 23881)
# Assault the target in a bloodthirsty craze, dealing s*<mult> Physical damage and restoring 117313s1 of your health.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(bloodthirst cd=4.5 rage=-8)
Define(charge 100)
# Charge to an enemy, dealing 126664s2 Physical damage, rooting it for 1 second?s103828[, and stunning it for 0 second][].rnrn|cFFFFFFFFGenerates /10;s2 Rage.|r
  SpellInfo(charge cd=1.5 charge_cd=20 gcd=0 offgcd=1 rage=-20)
Define(cleave 845)
# Strikes all enemies in front of you with a sweeping attack for s1 Physical damage. Hitting s2 or more targets inflicts Deep Wounds.
  SpellInfo(cleave rage=20 cd=9 talent=cleave_talent)
Define(colossus_smash 167105)
# Smashes the enemy's armor, dealing s1 Physical damage, and increasing damage you deal to them by 208086s1 for 10 seconds.
  SpellInfo(colossus_smash cd=45)
Define(conductive_ink_0 302491)
# Your damaging abilities against enemies above M3 health have a very high chance to apply Conductive Ink. When an enemy falls below M3 health, Conductive Ink inflicts s1*(1+@versadmg) Nature damage per stack.
  SpellInfo(conductive_ink_0 channel=0 gcd=0 offgcd=1)

Define(conductive_ink_1 302597)
# Your damaging abilities against enemies above M3 health have a very high chance to apply Conductive Ink. When an enemy falls below M3 health, Conductive Ink inflicts s1*(1+@versadmg) Nature damage per stack.
  SpellInfo(conductive_ink_1 channel=0 gcd=0 offgcd=1)

Define(crushing_assault_buff 278824)
# Your melee abilities have a chance to increase the damage of your next Slam by s1 and reduce its Rage cost by s2/10.
  SpellInfo(crushing_assault_buff channel=-0.001 gcd=0 offgcd=1)

Define(deadly_calm 262228)
# Reduces the Rage cost of your abilities by s1 for 6 seconds.
  SpellInfo(deadly_calm cd=60 duration=6 gcd=0 offgcd=1 talent=deadly_calm_talent)
  # Your abilities cost s1 less Rage.
  SpellAddBuff(deadly_calm deadly_calm=1)
Define(demoralizing_shout 1160)
# ?s199023[Demoralizes all enemies within A2 yards, reducing the damage they do by s2 for 8 seconds.][Demoralizes all enemies within A2 yards, reducing the damage they deal to you by s1 for 8 seconds.]?s202743[rnrn|cFFFFFFFFGenerates m5/10 Rage.|r][]
  SpellInfo(demoralizing_shout cd=45 duration=8 rage=0)
  # ?s199023[Demoralized, dealing s2 less damage.][Demoralized, dealing s1 less damage to the shouting Warrior.]
  SpellAddTargetDebuff(demoralizing_shout demoralizing_shout=1)
Define(devastate 20243)
# A direct strike, dealing s1*<mult> Physical damage.
  SpellInfo(devastate max_stacks=3)
Define(dragon_roar 118000)
# Roar explosively, dealing m1 Physical damage to all enemies within A1 yds and reducing their movement speed by s3 for 6 seconds.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(dragon_roar cd=35 duration=6 rage=-10 talent=dragon_roar_talent_protection)
  # Movement slowed by s3.
  SpellAddTargetDebuff(dragon_roar dragon_roar=1)
Define(execute 5308)
# Attempt to finish off a wounded foe, causing 280849sw1+163558sw1 Physical damage. Only usable on enemies that have less than 20 health.rnrn|cFFFFFFFFGenerates m3/10 Rage.|r
# Rank 2: If your foe survives your Execute, 163201s2 of the Rage spent is refunded.
  SpellInfo(execute cd=6 rage=-20)

Define(execute_arms 163201)
# Attempts to finish off a foe, causing up to <damage> Physical damage based on Rage spent. Only usable on enemies that have less than 20 health.?s231830[rnrnIf your foe survives, s2 of the Rage spent is refunded.][]
  SpellInfo(execute_arms rage=20)

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
Define(furious_slash 100130)
# Aggressively strike with your off-hand weapon for s1*<mult> Physical damage, and increases your Haste by 202539s3 for 15 seconds, stacking up to 202539u times.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(furious_slash rage=-4 talent=furious_slash_talent)
  # Haste increased by s2.
  SpellAddBuff(furious_slash furious_slash_buff=1)
Define(furious_slash_buff 202539)
# Aggressively strike with your off-hand weapon for s1*<mult> Physical damage, and increases your Haste by 202539s3 for 15 seconds, stacking up to 202539u times.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(furious_slash_buff duration=15 max_stacks=3 gcd=0 offgcd=1)
  # Haste increased by s2.
  SpellAddBuff(furious_slash_buff furious_slash_buff=1)
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

Define(heroic_leap 6544)
# Leap through the air toward a target location, slamming down with destructive force to deal 52174s1 Physical damage to all enemies within 52174a1 yards?s23922[, and resetting the remaining cooldown on Taunt][].
  SpellInfo(heroic_leap cd=0.8 charge_cd=45 gcd=0 offgcd=1)
Define(ignore_pain 190456)
# Fight through the pain, ignoring s2 of damage taken, up to <absorb> total damage prevented.
  SpellInfo(ignore_pain rage=40 cd=1 duration=12 gcd=0 offgcd=1)
  # Ignoring s2 of damage taken, preventing w1 total damage.
  SpellAddBuff(ignore_pain ignore_pain=1)
Define(intercept 198304)
# Run at high speed toward an enemy or ally.rnrnWhen targeting an enemy, deals 126664s2 Physical damage and roots the target for 1 second.rnrnWhen targeting an ally, intercepts the next melee or ranged attack against them within 10 seconds while the ally remains within 147833A2 yards.rnrn|cFFFFFFFFGenerates /10;s2 Rage.|r
  SpellInfo(intercept cd=1.5 charge_cd=20 gcd=0 offgcd=1 rage=-15)
  SpellInfo(charge replaced_by=intercept)
Define(intimidating_shout 5246)
# ?s275338[Causes the targeted enemy and up to s1 additional enemies within 5246A3 yards to cower in fear.][Causes the targeted enemy to cower in fear, and up to s1 additional enemies within 5246A3 yards to flee.] Targets are disoriented for 8 seconds.
  SpellInfo(intimidating_shout cd=90 duration=8)
  # Disoriented.
  SpellAddTargetDebuff(intimidating_shout intimidating_shout=1)
Define(last_stand 12975)
# Increases maximum health by s1 for 15 seconds, and instantly heals you for that amount.
  SpellInfo(last_stand cd=180 duration=15 gcd=0 offgcd=1)
  # Maximum health increased by s1.
  SpellAddBuff(last_stand last_stand=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)

Define(mortal_strike 12294)
# A vicious strike that deals s1 Physical damage and reduces the effectiveness of healing on the target by 115804s1 for 10 seconds.
  SpellInfo(mortal_strike rage=30 cd=6)
Define(overpower 7384)
# Overpower the enemy, dealing s1 Physical damage. Cannot be blocked, dodged, or parried.rnrnIncreases the damage of your next Mortal Strike by s2, stacking up to u times.
  SpellInfo(overpower cd=12 duration=15 max_stacks=2)
  # Your next Mortal Strike will deal w2 increased damage.
  SpellAddBuff(overpower overpower=1)
Define(pummel 6552)
# Pummels the target, interrupting spellcasting and preventing any spell in that school from being cast for 4 seconds.
# Rank 1: Pummel the target for s2 damage and interrupt the spell being cast for 5 seconds.
  SpellInfo(pummel cd=15 duration=4 gcd=0 offgcd=1 interrupt=1)
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
Define(raging_blow 85288)
# A mighty blow with both weapons that deals a total of (96103sw1+85384sw1)*<mult> Physical damage.rnrnRaging Blow has a s1 chance to instantly reset its own cooldown.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(raging_blow cd=8 rage=-12)

Define(rampage 184367)
# Enrages you and unleashes a series of s1 brutal strikes for a total of <damage> Physical damage.
  SpellInfo(rampage rage=85)

Define(ravager 152277)
# Throws a whirling weapon at the target location that inflicts 7*156287s1 damage to all enemies within 156287A1 yards over 7 seconds. ?a137048[rnrnAlso increases your Parry chance by 227744s1 for 12 seconds.][rnrn|cFFFFFFFFGenerates 248439s1/10 Rage each time it deals damage.|r]
  SpellInfo(ravager cd=60 duration=7 tick=1 talent=ravager_talent)
  # ?s23922[Chance to Parry increased by s1.][Ravager is currently active.]
  SpellAddBuff(ravager ravager=1)
Define(ravager_protection 228920)
# Throws a whirling weapon at the target location that inflicts 7*156287s1 damage to all enemies within 156287A1 yards over 7 seconds. ?s23922[rnrnAlso increases your Parry chance by 227744s1 for 12 seconds.][]
  SpellInfo(ravager_protection cd=60 duration=7 tick=1 talent=ravager_talent_protection)
  # ?s23922[Chance to Parry increased by s1.][Ravager is currently active.]
  SpellAddBuff(ravager_protection ravager_protection=1)
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
Define(recklessness 1719)
# Go berserk, increasing all Rage generation by s4 and granting your abilities s1 increased critical strike chance for 10 seconds.?a202751[rnrn|cFFFFFFFFGenerates 202751s2/10 Rage.|r][]
  SpellInfo(recklessness cd=90 duration=10 rage=0)
  # Rage generation increased by s5.rnCritical strike chance of all abilities increased by w1.
  SpellAddBuff(recklessness recklessness=1)
Define(rend 772)
# Wounds the target, causing s1 Physical damage instantly and an additional o2 Bleed damage over 12 seconds.
  SpellInfo(rend rage=30 duration=12 tick=3 talent=rend_talent)
  # Bleeding for w2 damage every t2 sec.
  SpellAddTargetDebuff(rend rend=1)
Define(revenge 6572)
# Swing in a wide arc, dealing s1 damage to all enemies in front of you.rnrnYour successful dodges and parries cause your next Revenge to become free.
  SpellInfo(revenge rage=30 cd=3)
Define(shield_block 2565)
# Raise your shield, blocking all melee attacks against you for 6 seconds.?s76857[ These blocks can be critical blocks.][] Increases Shield Slam damage by 132404s2 while active.
# Rank 2: Shield Block has s1+1 charges.
  SpellInfo(shield_block rage=30 cd=1 charge_cd=16 gcd=0 offgcd=1)
Define(shield_slam 23922)
# Slams the target with your shield, causing s1 Physical damage.?a231834[rnrnDevastate, Thunder Clap, and Revenge have a 231834s1 chance to reset the cooldown of Shield Slam.][]rnrn|cFFFFFFFFGenerates s3/10 Rage.|r
# Rank 2: Devastate, Thunder Clap, and Revenge have a s1 chance to reset the remaining cooldown on Shield Slam.rn
  SpellInfo(shield_slam cd=9 rage=-15)
Define(shockwave 46968)
# Sends a wave of force in a frontal cone, causing m2 damage and stunning all enemies within a1 yards for 2 seconds.
  SpellInfo(shockwave cd=40)
  # Stunned.
  SpellAddBuff(shockwave shockwave=1)
Define(siegebreaker 280772)
# Break the enemy's defenses, dealing s1 Physical damage, and increasing your damage done to the target by 280773s1 for 10 seconds.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(siegebreaker cd=30 rage=-10 talent=siegebreaker_talent)
Define(skullsplitter 260643)
# Bash an enemy's skull, dealing s1 Physical damage.rnrn|cFFFFFFFFGenerates s2/10 Rage.|r
  SpellInfo(skullsplitter cd=21 rage=-20 talent=skullsplitter_talent)
Define(slam 1464)
# Slams an opponent, causing s1 Physical damage.
  SpellInfo(slam rage=20)
Define(stone_heart 225947)
# Your attacks have a chance to make your next Execute cost no ?s12712[initial ][]Rage?s12712[, consume no extra Rage,][] and be usable on any target, regardless of health level.
  SpellInfo(stone_heart duration=10 channel=10 gcd=0 offgcd=1)
  # Execute costs no Rage and can be used on any target.
  SpellAddBuff(stone_heart stone_heart=1)
Define(storm_bolt 107570)
# Hurls your weapon at an enemy, causing s1 Physical damage and stunning for 4 seconds.
  SpellInfo(storm_bolt cd=30 talent=storm_bolt_talent_fury)
  # Stunned.
  SpellAddBuff(storm_bolt storm_bolt=1)
Define(sweeping_strikes 260708)
# For 12 seconds your single-target damaging abilities hit s1 additional Ltarget:targets; within 8 yds for s2 damage.
  SpellInfo(sweeping_strikes cd=30 duration=12)
  # Your single-target damaging abilities hit s1 additional Ltarget:targets; within 8 yds for s2 damage.
  SpellAddBuff(sweeping_strikes sweeping_strikes=1)
Define(test_of_might_buff 275531)
# When ?s262161[Warbreaker][Colossus Smash] expires, your Strength is increased by s1 for every s2 Rage you spent during ?s262161[Warbreaker][Colossus Smash]. Lasts 12 seconds.
  SpellInfo(test_of_might_buff channel=-0.001 gcd=0 offgcd=1)

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
Define(thunder_clap 6343)
# Blasts all enemies within 6343A1 yards for ?s12712[6343m1*1.2][6343m1] damage?s199045[, rooting them for 1 second and reducing their movement speed by s2 for 10 seconds.][ and reduces their movement speed by s2 for 10 seconds.]rnrn|cFFFFFFFFGenerates s4/10 Rage.|r
  SpellInfo(thunder_clap cd=6 duration=10 rage=-5)
  # Movement speed reduced by s2.
  SpellAddTargetDebuff(thunder_clap thunder_clap=1)
Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp=1)
Define(warbreaker 262161)
# Smash the ground and shatter the armor of all enemies within A1 yds, dealing s1 Physical damage and increasing damage you deal to them by 208086s1 for 10 seconds.
  SpellInfo(warbreaker cd=45 talent=warbreaker_talent)
Define(whirlwind_buff_0 199658)
# Unleashes a whirlwind of steel, ?s202316[hitting your primary target with Slam and ][]striking all enemies within 199658A1 yards for <baseDmg> Physical damage.
  SpellInfo(whirlwind_buff_0 duration=20)
Define(whirlwind_buff_1 199667)
# Unleashes a whirlwind of steel, striking all enemies within 199658A1 yards for 3*(199667sw2+44949sw2) Physical damage.?a12950[rnrnCauses your next s7 single-target lattack:attacks; to strike up to 85739s1 additional targets for 85739s3 damage.][]rnrn|cFFFFFFFFGenerates m8 Rage, plus an additional m9 per target hit. Maximum m10 Rage.|r
  SpellInfo(whirlwind_buff_1 duration=20)
Define(whirlwind_buff_2 199850)
# Unleashes a whirlwind of steel, ?s202316[hitting your primary target with Slam and ][]striking all enemies within 199658A1 yards for <baseDmg> Physical damage.
  SpellInfo(whirlwind_buff_2 duration=20)
Define(whirlwind_buff_3 85739)
  	SpellInfo(whirlwind_buff_3 duration=20)
Define(whirlwind_fury 190411)
SpellList(blood_of_the_enemy blood_of_the_enemy_0 blood_of_the_enemy_1 blood_of_the_enemy_2 blood_of_the_enemy_3 blood_of_the_enemy_4 blood_of_the_enemy_5 blood_of_the_enemy_6)
SpellList(conductive_ink conductive_ink_0 conductive_ink_1)
SpellList(fireblood fireblood_0 fireblood_1)
SpellList(focused_azerite_beam focused_azerite_beam_0 focused_azerite_beam_1 focused_azerite_beam_2 focused_azerite_beam_3)
SpellList(guardian_of_azeroth guardian_of_azeroth_0 guardian_of_azeroth_1 guardian_of_azeroth_2 guardian_of_azeroth_3 guardian_of_azeroth_4 guardian_of_azeroth_5)
SpellList(purifying_blast purifying_blast_0 purifying_blast_1 purifying_blast_2 purifying_blast_3 purifying_blast_4 purifying_blast_5)
SpellList(razor_coral razor_coral_0 razor_coral_1 razor_coral_2 razor_coral_3 razor_coral_4)
SpellList(reaping_flames reaping_flames_0 reaping_flames_1 reaping_flames_2 reaping_flames_3)
SpellList(reckless_force_buff reckless_force_buff_0 reckless_force_buff_1)
SpellList(the_unbound_force the_unbound_force_0 the_unbound_force_1 the_unbound_force_2 the_unbound_force_3 the_unbound_force_4 the_unbound_force_5 the_unbound_force_6 the_unbound_force_7)
SpellList(whirlwind_buff whirlwind_buff_0 whirlwind_buff_1 whirlwind_buff_2 whirlwind_buff_3)
SpellList(anima_of_death anima_of_death_0 anima_of_death_1 anima_of_death_2 anima_of_death_3)
Define(anger_management_talent 19) #21204
# Every ?c1[s1]?c2[s3][s2] Rage you spend reduces the remaining cooldown on ?c1&s262161[Warbreaker and Bladestorm]?c1[Colossus Smash and Bladestorm]?c2[Recklessness][Avatar, Last Stand, Shield Wall, and Demoralizing Shout] by 1 sec.
Define(avatar_talent 17) #22397
# Transform into a colossus for 20 seconds, causing you to deal s1 increased damage and removing all roots and snares.rnrn|cFFFFFFFFGenerates s5/10 Rage.|r
Define(booming_voice_talent 16) #22395
# Demoralizing Shout also generates m1/10 Rage, and increases damage you deal to affected targets by s2.
Define(carnage_talent 13) #22383
# Rampage costs s1/-10 less Rage and deals s4 increased damage.
Define(cleave_talent 15) #22362
# Strikes all enemies in front of you with a sweeping attack for s1 Physical damage. Hitting s2 or more targets inflicts Deep Wounds.
Define(deadly_calm_talent 18) #22399
# Reduces the Rage cost of your abilities by s1 for 6 seconds.
Define(dragon_roar_talent_protection 9) #23260
# Roar explosively, dealing m1 Physical damage to all enemies within A1 yds and reducing their movement speed by s3 for 6 seconds.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
Define(dreadnaught_talent 20) #22407
# Overpower has 1+s1 charges, and it increases the damage of your next Mortal Strike by an additional s2.
Define(fervor_of_battle_talent 8) #22489
# Whirlwind deals s1 increased damage, and Slams your primary target.
Define(frothing_berserker_talent 15) #19140
# Rampage now costs s1/10 Rage and increases your damage done by 215572s1 and Haste by 215572s2 for 6 seconds.
Define(furious_slash_talent 9) #23372
# Aggressively strike with your off-hand weapon for s1*<mult> Physical damage, and increases your Haste by 202539s3 for 15 seconds, stacking up to 202539u times.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
Define(massacre_talent_fury 14) #22393
# Execute is now usable on targets below s2 health.
Define(massacre_talent 7) #22380
# Execute is now usable on targets below s2 health.
Define(ravager_talent 21) #21667
# Throws a whirling weapon at the target location that inflicts 7*156287s1 damage to all enemies within 156287A1 yards over 7 seconds. ?a137048[rnrnAlso increases your Parry chance by 227744s1 for 12 seconds.][rnrn|cFFFFFFFFGenerates 248439s1/10 Rage each time it deals damage.|r]
Define(ravager_talent_protection 21) #23099
# Throws a whirling weapon at the target location that inflicts 7*156287s1 damage to all enemies within 156287A1 yards over 7 seconds. ?s23922[rnrnAlso increases your Parry chance by 227744s1 for 12 seconds.][]
Define(rend_talent 9) #19138
# Wounds the target, causing s1 Physical damage instantly and an additional o2 Bleed damage over 12 seconds.
Define(siegebreaker_talent 21) #16037
# Break the enemy's defenses, dealing s1 Physical damage, and increasing your damage done to the target by 280773s1 for 10 seconds.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
Define(skullsplitter_talent 3) #22371
# Bash an enemy's skull, dealing s1 Physical damage.rnrn|cFFFFFFFFGenerates s2/10 Rage.|r
Define(storm_bolt_talent_fury 6) #23093
# Hurls your weapon at an enemy, causing s1 Physical damage and stunning for 4 seconds.
Define(unstoppable_force_talent 8) #22626
# Avatar increases the damage of Thunder Clap by s1, and reduces its cooldown by s2.
Define(warbreaker_talent 14) #22391
# Smash the ground and shatter the armor of all enemies within A1 yds, dealing s1 Physical damage and increasing damage you deal to them by 208086s1 for 10 seconds.
Define(focused_resolve_item 168506)
Define(unbridled_fury_item 169299)
Define(superior_battle_potion_of_strength_item 168500)
Define(seismic_wave_trait 277639)
Define(test_of_might_trait 275529)
Define(cold_steel_hot_blood_trait 288080)
Define(memory_of_lucid_dreams_essence_id 27)
Define(blood_of_the_enemy_essence_id 23)
Define(condensed_life_force_essence_id 14)
Define(the_crucible_of_flame_essence_id 12)
    ]]
    code = code .. [[
ItemRequire(shifting_cosmic_sliver unusable 1=oncooldown,!shield_wall,buff,!shield_wall_buff)

# Warrior spells and functions.

# Learned spells.

Define(battle_shout 6673)
	SpellAddBuff(battle_shout battle_shout_buff=1)
Define(battle_shout_buff 6673)
Define(berserker_rage 18499)
	SpellInfo(berserker_rage cd=60 gcd=0)
	SpellInfo(berserker_rage rage=-20 itemset=T20 itemcount=2 specialization=protection)
	SpellAddBuff(berserker_rage berserker_rage_buff=1)
Define(berserker_rage_buff 18499)
	SpellInfo(berserker_rage_buff duration=6)
Define(bladestorm_arms 227847)
	SpellInfo(bladestorm_arms cd=90 channel=6 haste=melee replaced_by=ravager)
Define(bladestorm_fury 46924)
	SpellInfo(bladestorm_fury cd=60 channel=4 haste=melee)

	SpellInfo(bloodthirst cd=4.5 rage=-8 cd_haste=melee)
	SpellAddBuff(bloodthirst whirlwind_buff=-1)

	SpellInfo(charge cd=20 gcd=0 offgcd=1 rage=-25 travel_time=1 charges=1)
	SpellInfo(charge add_cd=-3 charges=2 talent=double_time_talent)
	SpellAddTargetDebuff(charge charge_debuff=1)
	SpellRequire(charge unusable 1=lossofcontrol,root)
Define(charge_debuff 105771)

	SpellInfo(cleave cd=9 cd_haste=melee rage=20)
	SpellRequire(cleave rage_percent 0=buff,deadly_calm_buff talent=deadly_calm_talent specialization=arms)

	SpellInfo(deadly_calm cd=60)
    SpellAddBuff(deadly_calm deadly_calm_buff=1)
Define(deadly_calm_buff 262228)
    SpellInfo(deadly_calm_buff duration=6)
Define(deep_wounds_prot_debuff 115767)
	SpellInfo(deep_wounds_prot_debuff duration=15 tick=3 haste=meleen)
Define(deep_wounds_arms_debuff 262115)
	SpellInfo(deep_wounds_arms_debuff duration=6 tick=2 haste=meleen)
Define(defensive_stance 197690)
	SpellInfo(defensive_stance cd=6)
	SpellAddBuff(defensive_stance defensive_stance_buff=1)
Define(defensive_stance_buff 197690)


	SpellInfo(demoralizing_shout cd=45)
	SpellInfo(demoralizing_shout add_rage=-40 talent=booming_voice_talent)
	SpellAddTargetDebuff(demoralizing_shout demoralizing_shout_debuff=1)
Define(demoralizing_shout_debuff 1160)
	SpellInfo(demoralizing_shout_debuff duration=8)

Define(die_by_the_sword 118038)
	SpellInfo(die_by_the_sword cd=180 gcd=0 offgcd=1)
	SpellAddBuff(die_by_the_sword die_by_the_sword_buff=1)
Define(die_by_the_sword_buff 118038)
	SpellInfo(die_by_the_sword_buff duration=8)

	SpellInfo(dragon_roar cd=35 rage=-10 tag=main)
	SpellAddBuff(dragon_roar dragon_roar_buff=1)
Define(dragon_roar_buff 118000)
	SpellInfo(dragon_roar_buff duration=6)
Define(enrage_buff 184362)
	SpellInfo(enrage_buff duration=4 enrage=1)
Define(enraged_regeneration 184364)
	SpellInfo(enraged_regeneration cd=120 gcd=0 offgcd=1)
	SpellAddBuff(enraged_regeneration enraged_regeneration_buff=1)
Define(enraged_regeneration_buff 184364)
	SpellInfo(enraged_regeneration_buff duration=8)

	SpellInfo(execute target_health_pct=35 talent=arms_massacre_talent)
	SpellRequire(execute rage_percent 0=buff,sudden_death_buff_arms)
	SpellRequire(execute target_health_pct 100=buff,sudden_death_buff_arms)
	SpellAddBuff(execute sudden_death_buff_arms=0)
    SpellAddTargetDebuff(execute executioners_precision_debuff=0)

	SpellInfo(execute rage=-20 target_health_pct=20)
	SpellInfo(execute target_health_pct=35 talent=massacre_talent_fury)
	SpellRequire(execute target_health_pct 100=buff,execute_free)
	SpellRequire(execute cd_percent 0=buff,execute_free)
SpellList(execute_free sudden_death_buff_fury)
Define(executioners_precision_debuff 272870)
    SpellInfo(executioners_precision_debuff duration=30 max_stacks=2)
    SpellAddTargetDebuff(execute executioners_precision_debuff=1 trait=executioners_precision_trait)
Define(frothing_berserker_buff 215572)
	SpellInfo(frothing_berserker_buff duration=6)
Define(frenzy_buff 202539)
	SpellInfo(frenzy_buff duration=15 max_stacks=3)

	SpellAddBuff(furious_slash frenzy_buff=1)
Define(hamstring 1715)
	SpellInfo(hamstring cd=1 rage=10)
	SpellAddTargetDebuff(hamstring hamstring_debuff=1)
Define(hamstring_debuff 1715)
	SpellInfo(hamstring_debuff duration=15)

	SpellInfo(heroic_leap cd=45 gcd=0 offgcd=1 travel_time=1)
	SpellInfo(heroic_leap add_cd=-15 talent=bounding_stride_talent specialization=!protection)
	SpellInfo(heroic_leap add_cd=-15 talent=prot_bounding_stride_talent specialization=protection)
	SpellAddBuff(heroic_leap heroic_leap_buff=1 talent=bounding_stride_talent specialization=!protection)
	SpellAddBuff(heroic_leap heroic_leap_buff=1 talent=prot_bounding_stride_talent specialization=protection)
	SpellRequire(heroic_leap unusable 1=lossofcontrol,root)
Define(heroic_leap_buff 202164)
Define(heroic_throw 57755)
	SpellInfo(heroic_throw cd=6 travel_time=1)
	SpellInfo(heroic_throw add_cd=-6 specialization=protection)

	SpellInfo(ignore_pain rage=40)
	SpellAddBuff(ignore_pain ignore_pain_buff=1)
	SpellAddBuff(ignore_pain vengeance_ignore_pain_buff=0 talent=vengeance_talent)
	SpellAddBuff(ignore_pain vengeance_revenge_buff=1 talent=vengeance_talent)
Define(ignore_pain_buff 190456)
	SpellInfo(ignore_pain duration=12)
Define(impending_victory 202168)
	SpellInfo(impending_victory rage=10 cd=30)
	SpellRequire(impending_victory cd_percent 0=victorious_buff)
	SpellAddBuff(impending_victory victorious_buff=0)
Define(in_for_the_kill_buff 248622)
	SpellInfo(in_for_the_kill_buff duration=8)

	SpellInfo(intercept cd=15 rage=-20 charges=2)
	SpellAddTargetDebuff(intercept charge_debuff=1)
	SpellAddTargetBuff(intercept safeguard_buff=1)
	SpellRequire(intercept unusable 1=lossofcontrol,root)
Define(into_the_fray_buff 202602)

	SpellInfo(last_stand cd=180)
	SpellInfo(last_stand add_cd=-60 talent=bolster_talent)
	SpellAddBuff(last_stand last_stand_buff=1)
Define(last_stand_buff 12975)
	SpellInfo(last_stand_buff duration=15)

	SpellInfo(mortal_strike cd=6 cd_haste=melee rage=30)
	SpellRequire(mortal_strike rage_percent 0=buff,deadly_calm_buff talent=deadly_calm_talent specialization=arms)
	SpellAddTargetDebuff(mortal_strike mortal_wounds_debuff=1)
    SpellAddTargetDebuff(mortal_strike executioners_precision_debuff=0)
	SpellAddBuff(mortal_strike overpower_buff=0)
Define(mortal_wounds_debuff 115804)
	SpellInfo(mortal_wounds_debuff duration=10)

	SpellInfo(overpower cd=12)
	SpellInfo(overpower charges=2 talent=dreadnaught_talent)
	SpellAddBuff(overpower overpower_buff=1)
Define(overpower_buff 7384)
	SpellInfo(overpower_buff duration=15 max_stacks=2)
Define(piercing_howl 12323)
	SpellInfo(piercing_howl rag=10)
	SpellAddBuff(piercing_howl piercing_howl_debuff=1)
Define(piercing_howl_debuff 12323)
	SpellInfo(piercing_howl_debuff duration=15)

	SpellInfo(pummel cd=15 gcd=0 interrupt=1 offgcd=1)
Define(punish_debuff 275335)
	SpellInfo(punish_debuff duration=9)

	SpellInfo(raging_blow rage=-12 cd=7 charges=2 cd_haste=melee)
	SpellInfo(raging_blow add_cd=-1 talent=inner_rage_talent)
Define(rallying_cry 97462)
	SpellInfo(rallying_cry cd=180)
	SpellAddBuff(rallying_cry rallying_cry_buff=1)
Define(rallying_cry_buff 97462)
	SpellInfo(rallying_cry_buff duration=10)

	SpellInfo(rampage gcd=1.5 cd_haste=none rage=85)
	SpellInfo(rampage add_rage=-10 talent=carnage_talent)
	SpellInfo(rampage add_rage=10 talent=frothing_berserker_talent)
	SpellAddBuff(rampage enrage_buff=1)
	SpellAddBuff(rampage frothing_berserker_buff=1 talent=frothing_berserker_talent)
	SpellAddBuff(rampage whirlwind_buff=-1)

	SpellInfo(ravager cd=60)
	SpellInfo(ravager ravager_buff=1)
	SpellAddTargetDebuff(ravager deep_wounds_arms_debuff=1)
Define(ravager_prot 228920)
	SpellInfo(ravager_prot cd=60)
	SpellAddBuff(ravager_prot ravager_prot_buff=1)
Define(ravager_prot_buff 227744)
	SpellInfo(ravager_prot_buff duration=12)

	SpellInfo(recklessness cd=90 tag=cd)
	SpellAddBuff(recklessness recklessness_buff=1)
Define(recklessness_buff 1719)
	SpellInfo(recklessness_buff duration=10)
	SpellInfo(recklessness_buff add_rage=-100 add_duration=4 talent=reckless_abandon_talent)

	SpellInfo(rend rage=30)
	SpellRequire(rend rage_percent 0=buff,deadly_calm_buff talent=deadly_calm_talent specialization=arms)
Define(rend_debuff 772)
	SpellInfo(rend_debuff duration=12 tick=3)

	SpellInfo(revenge cd=3 rage=30 cd_haste=melee)
	SpellRequire(revenge rage_percent 0=buff,revenge_buff)
	SpellAddTargetDebuff(revenge deep_wounds_prot_debuff=1)
	SpellAddBuff(revenge revenge_buff=0)
	SpellAddBuff(revenge vengeance_ignore_pain_buff=1 talent=vengeance_talent)
	SpellAddBuff(revenge vengeance_revenge_buff=0 talent=vengeance_talent)
Define(revenge_buff 5302)
	SpellInfo(revenge_buff duration=6)
Define(safeguard_buff 223658)
	SpellInfo(safeguard_buff duration=6)

	SpellInfo(shield_block cd=18 cd_haste=melee gcd=0 offgcd=1 rage=30)
	SpellAddBuff(shield_block shield_block_buff=1)
Define(shield_block_buff 132404)
	SpellInfo(shield_block_buff duration=6)

	SpellInfo(shield_slam cd=9 cd_haste=melee rage=-15)
	SpellAddTargetDebuff(shield_slam punish_debuff=1 talent=punish_talent)
Define(shield_wall 871)
	SpellInfo(shield_wall cd=240 gcd=0 offgcd=1)
	SpellAddBuff(shield_wall shield_wall_buff=1)
Define(shield_wall_buff 871)
	SpellInfo(shield_wall duration=8)



	SpellInfo(siegebreaker cd=30 rage=-10)
	SpellAddTargetDebuff(siegebreaker siegebreaker_debuff=1)
Define(siegebreaker_debuff 280773)
	SpellInfo(siegebreaker_debuff duration=10)

	SpellInfo(skullsplitter cd=21 rage=-20 cd_haste=melee)


	SpellRequire(slam rage_percent 0=buff,deadly_calm_buff talent=deadly_calm_talent specialization=arms)
Define(spell_reflection 23920)
	SpellInfo(spell_reflection cd=25)
	SpellAddBuff(spell_reflection spell_reflection_buff=1)
Define(spell_reflection_buff 23920)

	SpellInfo(storm_bolt cd=30)
Define(sudden_death_buff_arms 52437)
	SpellInfo(sudden_death_buff_arms duration=10)
Define(sudden_death_buff_fury 280776)
	SpellInfo(sudden_death_buff_fury duration=10)

	SpellInfo(sweeping_strikes cd=25)
	SpellAddBuff(sweeping_strikes sweeping_strikes_buff=1)
Define(sweeping_strikes_buff 260708)
	SpellInfo(sweeping_strikes_buff duration=12)
Define(taunt 355)
	SpellInfo(taunt cd=8)

	SpellInfo(thunder_clap cd=6 rage=-5 cd_haste=melee)
Define(vengeance_ignore_pain_buff 202574)
	SpellInfo(vengeance_ignore_pain_buff duration=15)
Define(vengeance_revenge_buff 202573)
	SpellInfo(vengeance_revenge_buff duration=15)
Define(victorious_buff 32216)
	SpellInfo(victorious_buff duration=20)
Define(victory_rush 34428)
	SpellRequire(victory_rush unusable 1=buff,!victorious_buff)
	SpellAddBuff(victory_rush victorious_buff=0)

	SpellInfo(warbreaker cd=45 tag=main)
	SpellAddBuff(warbreaker in_for_the_kill_buff=1 talent=in_for_the_kill_talent)

	SpellAddBuff(whirlwind_fury whirlwind_buff=2)
Define(whirlwind_arms 1680)
	SpellInfo(whirlwind_arms rage=30)

# Legion legendary items

Define(archavons_heavy_hand_spell 205144)
	# TODO Mortal strike refunds 15 rage

	SpellAddBuff(bloodthirst fujiedas_fury_buff=1 if_spell=fujiedas_fury_buff)

Define(ayalas_stone_heart_item 137052)
Define(the_great_storms_eye_item 151823)


# Talents
Define(anger_management_talent 19)
Define(arms_massacre_talent 7)
Define(best_served_cold_talent 7)
Define(bladestorm_talent 18)
Define(bolster_talent 12)
Define(booming_voice_talent 16)
Define(bounding_stride_talent 11)
Define(collateral_damage_talent 13)
Define(crackling_thunder_talent 4)
Define(defensive_stance_talent 12)
Define(devastator_talent 18)
Define(double_time_talent 4)
Define(dragon_roar_talent 17)
Define(endless_rage_talent 2)
Define(fresh_meat_talent 3)
Define(furious_charge_talent 10)
Define(fury_anger_management_talent 20)
Define(fury_sudden_death_talent 8)
Define(heavy_repercussions_talent 20)
Define(impending_victory_talent 3)
Define(impending_victory_talent 5)
Define(in_for_the_kill_talent 16)
Define(indomitable_talent 10)
Define(inner_rage_talent 7)
Define(into_the_fray_talent 1)
Define(meat_cleaver_talent 16)
Define(menace_talent 13)
Define(never_surrender_talent 11)
Define(prot_bounding_stride_talent 5)
Define(prot_dragon_roar_talent 9)
Define(prot_storm_bolt_talent 15)
Define(punish_talent 2)
Define(reckless_abandon_talent 19)
Define(rumbling_earth_talent 14)
Define(safeguard_talent 6)
Define(second_wind_talent 10)
Define(storm_bolt_talent 6)
Define(sudden_death_talent 2)
Define(unstoppable_force_talent 8)
Define(vengeance_talent 17)
Define(war_machine_talent 1)
Define(warpaint_talent 12)

# Azerite Traits
Define(executioners_precision_trait 272866)

# Non-default tags for OvaleSimulationCraft.
	SpellInfo(heroic_throw tag=main)
	SpellInfo(impending_victory tag=main)
	SpellInfo(hamstring tag=shortcd)
	SpellInfo(intercept tag=misc)
]]
    OvaleScripts:RegisterScript("WARRIOR", nil, name, desc, code, "include")
end
