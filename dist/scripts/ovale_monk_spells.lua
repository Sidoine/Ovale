local __exports = LibStub:NewLibrary("ovale/scripts/ovale_monk_spells", 80300)
if not __exports then return end
__exports.registerMonkSpells = function(OvaleScripts)
    local name = "ovale_monk_spells"
    local desc = "[9.0] Ovale: Monk spells"
    local code = [[Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
Define(bag_of_tricks 312411)
# Pull your chosen trick from the bag and use it on target enemy or ally. Enemies take <damage> damage, while allies are healed for <healing>. 
  SpellInfo(bag_of_tricks cd=90)
Define(berserking 26297)
# Increases your haste by s1 for 12 seconds.
  SpellInfo(berserking cd=180 duration=12 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking=1)
Define(black_ox_brew 115399)
# Chug some Black Ox Brew, which instantly refills your Energy, and your Ironskin Brew and Purifying Brew charges.
  SpellInfo(black_ox_brew cd=120 gcd=0 offgcd=1 energy=-200 talent=black_ox_brew_talent)
Define(blackout_combo_buff 228563)
# Blackout Strike also empowers your next ability:rnrnTiger Palm: Damage increased by s1.rnBreath of Fire: Cooldown reduced by s2 sec.rnKeg Smash: Reduces the remaining cooldown on your Brews by s3 additional sec.rnIronskin Brew: Pauses Stagger damage for s4 sec.
  SpellInfo(blackout_combo_buff duration=15 gcd=0 offgcd=1)
  # Your next ability is empowered.
  SpellAddBuff(blackout_combo_buff blackout_combo_buff=1)
Define(blackout_strike 205523)
# Strike with a blast of Chi energy, dealing s1 Physical damage?s117906[ and generating a stack of Elusive Brawler][].
  SpellInfo(blackout_strike cd=3)
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
Define(breath_of_fire 115181)
# Breathe fire on targets in front of you, causing s1 Fire damage.rnrnTargets affected by Keg Smash will also burn, taking 123725o1 Fire damage and dealing 123725s2 reduced damage to you for 12 seconds.
  SpellInfo(breath_of_fire cd=15 gcd=1)
Define(chi_burst_0 123986)
# Hurls a torrent of Chi energy up to 40 yds forward, dealing 148135s1 Nature damage to all enemies, and 130654s1 healing to the Monk and all allies in its path.?c1[rnrnCasting Chi Burst does not prevent avoiding attacks.][]?c3[rnrnChi Burst generates 1 Chi per enemy target damaged, up to a maximum of s3.][]
  SpellInfo(chi_burst_0 cd=30 duration=1 talent=chi_burst_talent)
Define(chi_burst_1 130654)
# Hurls a torrent of Chi energy up to 40 yds forward, dealing 148135s1 Nature damage to all enemies, and 130654s1 healing to the Monk and all allies in its path.?c1[rnrnCasting Chi Burst does not prevent avoiding attacks.][]?c3[rnrnChi Burst generates 1 Chi per enemy target damaged, up to a maximum of s3.][]
  SpellInfo(chi_burst_1 gcd=0 offgcd=1)
Define(chi_burst_2 148135)
# Hurls a torrent of Chi energy up to 40 yds forward, dealing 148135s1 Nature damage to all enemies, and 130654s1 healing to the Monk and all allies in its path.?c1[rnrnCasting Chi Burst does not prevent avoiding attacks.][]?c3[rnrnChi Burst generates 1 Chi per enemy target damaged, up to a maximum of s3.][]
  SpellInfo(chi_burst_2 gcd=0 offgcd=1)
Define(chi_burst_3 261682)
# Hurls a torrent of Chi energy up to 40 yds forward, dealing 148135s1 Nature damage to all enemies, and 130654s1 healing to the Monk and all allies in its path.?c1[rnrnCasting Chi Burst does not prevent avoiding attacks.][]?c3[rnrnChi Burst generates 1 Chi per enemy target damaged, up to a maximum of s3.][]
  SpellInfo(chi_burst_3 gcd=0 offgcd=1 chi=-1)
Define(chi_wave_0 115098)
# A wave of Chi energy flows through friends and foes, dealing 132467s1 Nature damage or 132463s1 healing. Bounces up to s1 times to targets within 132466a2 yards.
  SpellInfo(chi_wave_0 cd=15 talent=chi_wave_talent)
Define(chi_wave_1 132463)
# A wave of Chi energy flows through friends and foes, dealing 132467s1 Nature damage or 132463s1 healing. Bounces up to s1 times to targets within 132466a2 yards.
  SpellInfo(chi_wave_1 channel=0 gcd=0 offgcd=1)
Define(chi_wave_2 132466)
# A wave of Chi energy flows through friends and foes, dealing 132467s1 Nature damage or 132463s1 healing. Bounces up to s1 times to targets within 132466a2 yards.
  SpellInfo(chi_wave_2 channel=0 gcd=0 offgcd=1)
Define(chi_wave_3 132467)
# A wave of Chi energy flows through friends and foes, dealing 132467s1 Nature damage or 132463s1 healing. Bounces up to s1 times to targets within 132466a2 yards.
  SpellInfo(chi_wave_3 duration=0.1 channel=0.1 gcd=0 offgcd=1)
  SpellAddTargetDebuff(chi_wave_3 chi_wave_3=1)
Define(conductive_ink_0 302491)
# Your damaging abilities against enemies above M3 health have a very high chance to apply Conductive Ink. When an enemy falls below M3 health, Conductive Ink inflicts s1*(1+@versadmg) Nature damage per stack.
  SpellInfo(conductive_ink_0 channel=0 gcd=0 offgcd=1)

Define(conductive_ink_1 302597)
# Your damaging abilities against enemies above M3 health have a very high chance to apply Conductive Ink. When an enemy falls below M3 health, Conductive Ink inflicts s1*(1+@versadmg) Nature damage per stack.
  SpellInfo(conductive_ink_1 channel=0 gcd=0 offgcd=1)

Define(cyclotronic_blast 293491)
# Channel a cyclotronic blast, dealing a total of o1 Fire damage over D.
  SpellInfo(cyclotronic_blast cd=120 duration=2.5 channel=2.5 tick=0.5)
  # Burning for o1 Fire damage.
  SpellAddTargetDebuff(cyclotronic_blast cyclotronic_blast=1)
Define(dampen_harm 122278)
# Reduces all damage you take by m2 to m3 for 10 seconds, with larger attacks being reduced by more.
  SpellInfo(dampen_harm cd=120 duration=10 gcd=0 offgcd=1 talent=dampen_harm_talent)
  # Damage taken reduced by m2 to m3 for d, with larger attacks being reduced by more.
  SpellAddBuff(dampen_harm dampen_harm=1)
Define(diffuse_magic 122783)
# Reduces magic damage you take by m1 for 6 seconds, and transfers all currently active harmful magical effects on you back to their original caster if possible.
  SpellInfo(diffuse_magic cd=90 duration=6 gcd=0 offgcd=1 talent=diffuse_magic_talent)
  # Spell damage taken reduced by m1.
  SpellAddBuff(diffuse_magic diffuse_magic=1)
Define(elusive_brawler 195630)
# Each time you are hit by a melee attack, or hit with Blackout Strike, you gain stacking (100 of Spell Power).1 increased Dodge chance until your next successful Dodge.rnrnAlso increases your attack power by (100 of Spell Power).1.
  SpellInfo(elusive_brawler duration=10 max_stacks=100 gcd=0 offgcd=1)
  # Dodge chance increased by w1.
  SpellAddBuff(elusive_brawler elusive_brawler=1)
Define(energizing_elixir 115288)
# Chug an Energizing Elixir, granting s2 Chi and generating s1/5*5 Energy over 5 seconds.
  SpellInfo(energizing_elixir cd=60 duration=5 max_stacks=3 gcd=1 chi=-2 talent=energizing_elixir_talent)
  # Generating w1/5 extra Energy per sec.
  SpellAddBuff(energizing_elixir energizing_elixir=1)
Define(expel_harm 115072)
# Draw in the positive chi of all your Healing Spheres, and expel negative chi, damaging the nearest enemy for s2 of the amount healed.
  SpellInfo(expel_harm energy=15 gcd=1)
Define(fireblood_0 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. ?s195710[This effect shares a 30 sec cooldown with other similar effects.][]
  SpellInfo(fireblood_0 cd=120 gcd=0 offgcd=1)
Define(fireblood_1 265226)
# Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by s1.
  SpellInfo(fireblood_1 duration=8 max_stacks=6 gcd=0 offgcd=1)
  # Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by w1.
  SpellAddBuff(fireblood_1 fireblood_1=1)
Define(fist_of_the_white_tiger 261947)
# Strike with the technique of the White Tiger, dealing s1+261977s1 Physical damage.rnrn|cFFFFFFFFGenerates 261978s1 Chi.
  SpellInfo(fist_of_the_white_tiger energy=40 cd=30 gcd=1 talent=fist_of_the_white_tiger_talent)

Define(fists_of_fury 113656)
# Pummels all targets in front of you, dealing 5*s5 damage over 4 seconds to your primary target and 5*s5*s6/100 damage over 4 seconds to other targets. Can be channeled while moving.
  SpellInfo(fists_of_fury chi=3 cd=24 duration=4 channel=4 gcd=1 tick=0.166)
  # w3 damage every t3 sec. ?s125671[Parrying all attacks.][]
  SpellAddBuff(fists_of_fury fists_of_fury=1)
Define(flying_serpent_kick 101545)
# Soar forward through the air at high speed for 1.5 seconds.rn rnIf used again while active, you will land, dealing 123586m1 damage to all enemies within 123586A1 yards and reducing movement speed by 123586m2 for 4 seconds.
  SpellInfo(flying_serpent_kick cd=25 duration=1.5 gcd=1)
  SpellAddBuff(flying_serpent_kick flying_serpent_kick=1)
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
Define(fortifying_brew 115203)
# Turns your skin to stone for 15 seconds, increasing your current and maximum health by <health>, increasing the effectiveness of Stagger by s1, and reducing all damage you take by <damage>.
  SpellInfo(fortifying_brew cd=420 gcd=0 offgcd=1)
Define(gift_of_the_ox 124502)
# When you take damage, you have a chance to summon a Healing Sphere visible only to you. Moving through this Healing Sphere heals you for 124507s1.
  SpellInfo(gift_of_the_ox channel=0 gcd=0 offgcd=1)
  SpellAddBuff(gift_of_the_ox gift_of_the_ox=1)
Define(gladiators_badge 277185)
# Increases primary stat by s1 for 15 seconds.rn
  SpellInfo(gladiators_badge cd=120 duration=15 channel=15 gcd=0 offgcd=1)
  # Primary stat increased by s4.
  SpellAddBuff(gladiators_badge gladiators_badge=1)
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

Define(invoke_niuzao_the_black_ox 132578)
# Summons an effigy of Niuzao, the Black Ox for 45 seconds. Niuzao attacks your primary target and taunts it. He also frequently Stomps, damaging all nearby enemies.
  SpellInfo(invoke_niuzao_the_black_ox cd=180 duration=45 talent=invoke_niuzao_the_black_ox_talent)
Define(invoke_xuen_the_white_tiger 123904)
# Summons an effigy of Xuen, the White Tiger for 20 seconds. Xuen attacks your primary target, and strikes 3 enemies within 123996A1 yards every 123999t1 sec with Tiger Lightning for 123996s1 Nature damage.
  SpellInfo(invoke_xuen_the_white_tiger cd=120 duration=20 gcd=1 talent=invoke_xuen_the_white_tiger_talent)
Define(ironskin_brew 115308)
# A swig of strong brew allows you to Stagger substantially more damage for 7 seconds. rnrnShares charges with Purifying Brew.
  SpellInfo(ironskin_brew cd=1 charge_cd=15 gcd=0 offgcd=1)
Define(keg_smash 121253)
# Smash a keg of brew on the target, dealing s2 damage to all enemies within A2 yds and reducing their movement speed by m3 for 15 seconds.rnrnReduces the remaining cooldown on your Brews by s4 sec.
  SpellInfo(keg_smash energy=40 cd=1 charge_cd=8 duration=15 gcd=1)
  # ?w3!=0[Movement speed reduced by w3.rn][]Drenched in brew, vulnerable to Breath of Fire.
  SpellAddTargetDebuff(keg_smash keg_smash=1)
Define(leg_sweep 119381)
# Knocks down all enemies within A1 yards, stunning them for 3 seconds.
  SpellInfo(leg_sweep cd=60 duration=3)
  # Stunned.
  SpellAddTargetDebuff(leg_sweep leg_sweep=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)

Define(paralysis 115078)
# Incapacitates the target for 60 seconds. Limit 1. Damage will cancel the effect.
  SpellInfo(paralysis energy=20 cd=45 duration=60)
  # Incapacitated.
  SpellAddTargetDebuff(paralysis paralysis=1)
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
Define(purifying_brew 119582)
# Clears s1 of your damage delayed with Stagger.rnrnShares charges with Ironskin Brew.
  SpellInfo(purifying_brew cd=1 charge_cd=15 gcd=0 offgcd=1)
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
Define(reverse_harm 290461)
# Heals a friendly target for m1 of their maximum health, and causes m2 of the amount healed to instantly be dealt to the nearest enemy as Nature damage within 5 yards. rnrn|cFFFFFFFFGenerates s3 Chi.
  SpellInfo(reverse_harm gcd=0 offgcd=1)
Define(rising_sun_kick 107428)
# Kick upwards, dealing ?s137025[185099s1*<CAP>/AP][185099s1] Physical damage?s128595[, and reducing the effectiveness of healing on the target for 10 seconds][].
# Rank 2: Rising Sun Kick deals s1 increased damage.rn
  SpellInfo(rising_sun_kick chi=2 cd=10)

Define(rushing_jade_wind 116847)
# Summons a whirling tornado around you, causing (1+6 seconds/t1)*148187s1 damage over 6 seconds to enemies within 107270A1 yards.
  SpellInfo(rushing_jade_wind chi=1 cd=6 duration=6 tick=0.75 talent=rushing_jade_wind_talent_windwalker)
  # Dealing physical damage to nearby enemies every 116847t1 sec.
  SpellAddBuff(rushing_jade_wind rushing_jade_wind=1)
Define(serenity 152173)
# Enter an elevated state of mental and physical serenity for ?s115069[s1 sec][12 seconds]. While in this state, you deal s2 increased damage and healing, and all Chi consumers are free and cool down s4 more quickly.
  SpellInfo(serenity cd=90 duration=12 gcd=1 talent=serenity_talent)
  # Damage and healing increased by w2.rnAll Chi consumers are free and cool down w4 more quickly.
  SpellAddBuff(serenity serenity=1)
Define(spear_hand_strike 116705)
# Jabs the target in the throat, interrupting spellcasting and preventing any spell from that school of magic from being cast for 4 seconds.
  SpellInfo(spear_hand_strike cd=15 duration=4 gcd=0 offgcd=1 interrupt=1)
Define(spinning_crane_kick 101546)
# Spin while kicking in the air, dealing ?s137025[4*107270s1*<CAP>/AP][4*107270s1] Physical damage over 1.5 seconds to enemies within 107270A1 yds.?c3[rnrnSpinning Crane Kick's damage is increased by 220358s1 for each unique target you've struck in the last 15 seconds with Tiger Palm, Blackout Kick, or Rising Sun Kick.][]
  SpellInfo(spinning_crane_kick chi=3 duration=1.5 channel=1.5 tick=0.5)
  # Attacking all nearby enemies for Physical damage every 101546t1 sec.
  SpellAddBuff(spinning_crane_kick spinning_crane_kick=1)
Define(storm_earth_and_fire 137639)
# Split into 3 elemental spirits for 15 seconds, each spirit dealing 100+m1 of normal damage and healing.rnrnYou directly control the Storm spirit, while Earth and Fire spirits mimic your attacks on nearby enemies.rnrnWhile active, casting Storm, Earth, and Fire again will cause the spirits to fixate on your target.
# Rank 2: Storm, Earth, and Fire has s1+1 charges.
  SpellInfo(storm_earth_and_fire cd=16 charge_cd=90 duration=15 max_stacks=2 gcd=1)
  # Elemental spirits summoned, mirroring all of the Monk's attacks.rnThe Monk and spirits each do 100+m1 of normal damage and healing.
  SpellAddBuff(storm_earth_and_fire storm_earth_and_fire=1)
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
Define(tiger_palm 100780)
# Attack with the palm of your hand, dealing s1 damage.?a137384[rnrnTiger Palm has an 137384m1 chance to make your next Blackout Kick cost no Chi.][]?a137023[rnrnReduces the remaining cooldown on your Brews by s3 sec.][]?a137025[rnrn|cFFFFFFFFGenerates s2 Chi.][]
  SpellInfo(tiger_palm energy=50 chi=0)
Define(touch_of_death 115080)
# Inflict mortal damage on an enemy, causing the target to take damage equal to s2 of your maximum health after 8 seconds, reduced against players.rnrnDuring the 8 seconds duration, 271232s1 of all other damage you deal to the target will be added to the final damage dealt.
  SpellInfo(touch_of_death cd=120 duration=8 tick=8)
  # Taking w1 damage when this effect expires.
  SpellAddTargetDebuff(touch_of_death touch_of_death=1)
Define(touch_of_karma 122470)
# Absorbs all damage taken for 10 seconds, up to s3 of your maximum health, and redirects s4 of that amount to the enemy target as Nature damage over 6 seconds.
  SpellInfo(touch_of_karma cd=90 duration=10 gcd=0 offgcd=1)
  # Damage dealt to the Monk is redirected to you as Nature damage over 124280d.
  SpellAddBuff(touch_of_karma touch_of_karma=1)
  # Damage dealt to the Monk is redirected to you as Nature damage over 124280d.
  SpellAddTargetDebuff(touch_of_karma touch_of_karma=1)
Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp=1)
Define(whirling_dragon_punch 152175)
# Performs a devastating whirling upward strike, dealing 3*158221s1 damage to all nearby enemies. Only usable while both Fists of Fury and Rising Sun Kick are on cooldown.
  SpellInfo(whirling_dragon_punch cd=24 duration=1 gcd=1 tick=0.25 talent=whirling_dragon_punch_talent)
  SpellAddBuff(whirling_dragon_punch whirling_dragon_punch=1)
SpellList(chi_burst chi_burst_0 chi_burst_1 chi_burst_2 chi_burst_3)
SpellList(chi_wave chi_wave_0 chi_wave_1 chi_wave_2 chi_wave_3)
SpellList(conductive_ink conductive_ink_0 conductive_ink_1)
SpellList(fireblood fireblood_0 fireblood_1)
SpellList(razor_coral razor_coral_0 razor_coral_1 razor_coral_2 razor_coral_3 razor_coral_4)
SpellList(blood_of_the_enemy blood_of_the_enemy_0 blood_of_the_enemy_1 blood_of_the_enemy_2 blood_of_the_enemy_3 blood_of_the_enemy_4 blood_of_the_enemy_5 blood_of_the_enemy_6)
SpellList(focused_azerite_beam focused_azerite_beam_0 focused_azerite_beam_1 focused_azerite_beam_2 focused_azerite_beam_3)
SpellList(guardian_of_azeroth guardian_of_azeroth_0 guardian_of_azeroth_1 guardian_of_azeroth_2 guardian_of_azeroth_3 guardian_of_azeroth_4 guardian_of_azeroth_5)
SpellList(purifying_blast purifying_blast_0 purifying_blast_1 purifying_blast_2 purifying_blast_3 purifying_blast_4 purifying_blast_5)
SpellList(reaping_flames reaping_flames_0 reaping_flames_1 reaping_flames_2 reaping_flames_3)
SpellList(the_unbound_force the_unbound_force_0 the_unbound_force_1 the_unbound_force_2 the_unbound_force_3 the_unbound_force_4 the_unbound_force_5 the_unbound_force_6 the_unbound_force_7)
Define(black_ox_brew_talent 9) #19992
# Chug some Black Ox Brew, which instantly refills your Energy, and your Ironskin Brew and Purifying Brew charges.
Define(blackout_combo_talent 21) #22108
# Blackout Strike also empowers your next ability:rnrnTiger Palm: Damage increased by s1.rnBreath of Fire: Cooldown reduced by s2 sec.rnKeg Smash: Reduces the remaining cooldown on your Brews by s3 additional sec.rnIronskin Brew: Pauses Stagger damage for s4 sec.
Define(chi_burst_talent 3) #20185
# Hurls a torrent of Chi energy up to 40 yds forward, dealing 148135s1 Nature damage to all enemies, and 130654s1 healing to the Monk and all allies in its path.?c1[rnrnCasting Chi Burst does not prevent avoiding attacks.][]?c3[rnrnChi Burst generates 1 Chi per enemy target damaged, up to a maximum of s3.][]
Define(chi_wave_talent 2) #19820
# A wave of Chi energy flows through friends and foes, dealing 132467s1 Nature damage or 132463s1 healing. Bounces up to s1 times to targets within 132466a2 yards.
Define(dampen_harm_talent 15) #20175
# Reduces all damage you take by m2 to m3 for 10 seconds, with larger attacks being reduced by more.
Define(diffuse_magic_talent 14) #20173
# Reduces magic damage you take by m1 for 6 seconds, and transfers all currently active harmful magical effects on you back to their original caster if possible.
Define(energizing_elixir_talent 9) #22096
# Chug an Energizing Elixir, granting s2 Chi and generating s1/5*5 Energy over 5 seconds.
Define(fist_of_the_white_tiger_talent 8) #19771
# Strike with the technique of the White Tiger, dealing s1+261977s1 Physical damage.rnrn|cFFFFFFFFGenerates 261978s1 Chi.
Define(hit_combo_talent 16) #22093
# Each successive attack that triggers Combo Strikes in a row grants 196741s1 increased damage, stacking up to 196741u times.
Define(invoke_niuzao_the_black_ox_talent 18) #22103
# Summons an effigy of Niuzao, the Black Ox for 45 seconds. Niuzao attacks your primary target and taunts it. He also frequently Stomps, damaging all nearby enemies.
Define(invoke_xuen_the_white_tiger_talent 18) #22102
# Summons an effigy of Xuen, the White Tiger for 20 seconds. Xuen attacks your primary target, and strikes 3 enemies within 123996A1 yards every 123999t1 sec with Tiger Lightning for 123996s1 Nature damage.
Define(rushing_jade_wind_talent 17) #20184
# Summons a whirling tornado around you, causing (1+6 seconds/t1)*148187s1 damage over 6 seconds to enemies within 107270A1 yards.
Define(rushing_jade_wind_talent_windwalker 17) #23122
# Summons a whirling tornado around you, causing (1+6 seconds/t1)*148187s1 damage over 6 seconds to enemies within 107270A1 yards.
Define(serenity_talent 21) #21191
# Enter an elevated state of mental and physical serenity for ?s115069[s1 sec][12 seconds]. While in this state, you deal s2 increased damage and healing, and all Chi consumers are free and cool down s4 more quickly.
Define(special_delivery_talent 16) #19819
# Drinking Ironskin or Purifying Brew has a h chance to toss a keg high into the air that lands nearby after s1 sec, dealing 196733s1 damage to all enemies within 196733A1 yards and reducing their movement speed by 196733m2 for 15 seconds.
Define(whirling_dragon_punch_talent 20) #22105
# Performs a devastating whirling upward strike, dealing 3*158221s1 damage to all nearby enemies. Only usable while both Fists of Fury and Rising Sun Kick are on cooldown.
Define(superior_battle_potion_of_agility_item 168489)
Define(ashvanes_razor_coral_item 169311)
Define(cyclotronic_blast_item 167672)
Define(dribbling_inkpod_item 169319)
Define(gladiators_medallion_item 111306)
Define(lustrous_golden_plumage_item 159617)
Define(unbridled_fury_item 169299)
Define(the_crucible_of_flame_essence_id 12)
Define(worldvein_resonance_essence_id 4)
    ]]
    OvaleScripts:RegisterScript("MONK", nil, name, desc, code, "include")
end
