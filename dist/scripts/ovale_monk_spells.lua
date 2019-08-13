local __exports = LibStub:NewLibrary("ovale/scripts/ovale_monk_spells", 80201)
if not __exports then return end
__exports.registerMonkSpells = function(OvaleScripts)
    local name = "ovale_monk_spells"
    local desc = "[8.2] Ovale: Monk spells"
    local code = [[Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
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
Define(chi_burst 123986)
# Hurls a torrent of Chi energy up to 40 yds forward, dealing 148135s1 Nature damage to all enemies, and 130654s1 healing to the Monk and all allies in its path.?c1[rnrnCasting Chi Burst does not prevent avoiding attacks.][]?c3[rnrnChi Burst generates 1 Chi per enemy target damaged, up to a maximum of s3.][]
  SpellInfo(chi_burst cd=30 duration=1 talent=chi_burst_talent)
Define(chi_wave 115098)
# A wave of Chi energy flows through friends and foes, dealing 132467s1 Nature damage or 132463s1 healing. Bounces up to s1 times to targets within 132466a2 yards.
  SpellInfo(chi_wave cd=15 talent=chi_wave_talent)
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
Define(focused_azerite_beam_0 299336)
# Focus excess Azerite energy into the Heart of Azeroth, then expel that energy outward, dealing m1*10 Fire damage to all enemies in front of you over 3 seconds.
  SpellInfo(focused_azerite_beam_0 cd=90 duration=3 channel=3 tick=0.33)

Define(focused_azerite_beam_1 299338)
# Focus excess Azerite energy into the Heart of Azeroth, then expel that energy outward, dealing m1*10 Fire damage to all enemies in front of you over 3 seconds. Castable while moving.
  SpellInfo(focused_azerite_beam_1 cd=90 duration=3 channel=3 tick=0.33)

Define(fortifying_brew 115203)
# Turns your skin to stone for 15 seconds, increasing your current and maximum health by <health>, increasing the effectiveness of Stagger by s1, and reducing all damage you take by <damage>.
  SpellInfo(fortifying_brew cd=420 gcd=0 offgcd=1)
Define(gift_of_the_ox 124502)
# When you take damage, you have a chance to summon a Healing Sphere visible only to you. Moving through this Healing Sphere heals you for 124507s1.
  SpellInfo(gift_of_the_ox channel=0 gcd=0 offgcd=1)
  SpellAddBuff(gift_of_the_ox gift_of_the_ox=1)
Define(guardian_of_azeroth_0 295840)
# Call upon Azeroth to summon a Guardian of Azeroth for 30 seconds who impales your target with spikes of Azerite every 2 sec that deal 295834m1*(1+@versadmg) Fire damage.?a295841[ Every 303347t1 sec, the Guardian launches a volley of Azerite Spikes at its target, dealing 295841s1 Fire damage to all nearby enemies.][]?a295843[rnrnEach time the Guardian of Azeroth casts a spell, you gain 295855s1 Haste, stacking up to 295855u times. This effect ends when the Guardian of Azeroth despawns.][]rn
  SpellInfo(guardian_of_azeroth_0 cd=180 duration=30)
  SpellAddBuff(guardian_of_azeroth_0 guardian_of_azeroth_0=1)
Define(guardian_of_azeroth_1 295855)
# Each time the Guardian of Azeroth casts a spell, you gain 295855s1 Haste, stacking up to 295855u times. This effect ends when the Guardian of Azeroth despawns.
  SpellInfo(guardian_of_azeroth_1 duration=60 max_stacks=5 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(guardian_of_azeroth_1 guardian_of_azeroth_1=1)
Define(guardian_of_azeroth_2 299355)
# Call upon Azeroth to summon a Guardian of Azeroth for 30 seconds who impales your target with spikes of Azerite every 2 sec that deal 295834m1*(1+@versadmg)*(1+(295836m1/100)) Fire damage. Every 303347t1 sec, the Guardian launches a volley of Azerite Spikes at its target, dealing 295841s1 Fire damage to all nearby enemies.
  SpellInfo(guardian_of_azeroth_2 cd=180 duration=30 gcd=1)
  SpellAddBuff(guardian_of_azeroth_2 guardian_of_azeroth_2=1)
Define(guardian_of_azeroth_3 299358)
# Call upon Azeroth to summon a Guardian of Azeroth for 30 seconds who impales your target with spikes of Azerite every 2 sec that deal 295834m1*(1+@versadmg)*(1+(295836m1/100)) Fire damage. Every 303347t1 sec, the Guardian launches a volley of Azerite Spikes at its target, dealing 295841s1 Fire damage to all nearby enemies.rnrnEach time the Guardian of Azeroth casts a spell, you gain 295855s1 Haste, stacking up to 295855u times. This effect ends when the Guardian of Azeroth despawns.
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
Define(swift_roundhouse_buff 278707)
# Blackout Kick increases the damage of your next Rising Sun Kick by s1, stacking up to 278710u times.
  SpellInfo(swift_roundhouse_buff channel=-0.001 gcd=0 offgcd=1)

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
SpellList(fireblood fireblood_0 fireblood_1)
SpellList(blood_of_the_enemy blood_of_the_enemy_0 blood_of_the_enemy_1 blood_of_the_enemy_2 blood_of_the_enemy_3 blood_of_the_enemy_4 blood_of_the_enemy_5 blood_of_the_enemy_6)
SpellList(focused_azerite_beam focused_azerite_beam_0 focused_azerite_beam_1)
SpellList(guardian_of_azeroth guardian_of_azeroth_0 guardian_of_azeroth_1 guardian_of_azeroth_2 guardian_of_azeroth_3 guardian_of_azeroth_4 guardian_of_azeroth_5)
SpellList(purifying_blast purifying_blast_0 purifying_blast_1 purifying_blast_2 purifying_blast_3 purifying_blast_4 purifying_blast_5)
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
    ]]
    code = code .. [[
ItemRequire(shifting_cosmic_sliver unusable 1=oncooldown,!fortifying_brew,buff,!fortifying_brew_buff)

## Spells
Define(blackout_kick_windwalker 100784) ## Added for now untill it is fixed in importspells
SpellInfo(blackout_kick_windwalker cd=3 specialization=mistweaver)
SpellInfo(blackout_kick_windwalker chi=1 specialization=windwalker)
SpellRequire(blackout_kick_windwalker chi_percent 0=buff,blackout_kick_free specialization=windwalker)
SpellAddBuff(blackout_kick_windwalker blackout_kick_buff=0 specialization=windwalker)
SpellAddBuff(blackout_kick_windwalker teachings_of_the_monastery_buff=0 specialization=mistweaver)
SpellAddTargetDebuff(blackout_kick_windwalker mark_of_the_crane_debuff=1 specialization=windwalker)
SpellAddBuff(blackout_kick_windwalker swift_roundhouse_buff=1)

Define(blackout_kick_buff 116768)
SpellInfo(blackout_kick_buff duration=15)

SpellList(blackout_kick_free blackout_kick_buff serenity)

SpellAddBuff(blackout_strike blackout_combo_buff=1 talent=blackout_combo_talent)

SpellAddTargetDebuff(breath_of_fire breath_of_fire_debuff=1 if_target_debuff=keg_smash)
SpellAddBuff(breath_of_fire blackout_combo_buff=0)

Define(breath_of_fire_debuff 123725)
	SpellInfo(breath_of_fire_debuff duration=12 tick=2)

SpellInfo(chi_burst chi=-1 max_chi=-2 specialization=windwalker)

Define(chi_torpedo 115008)
	SpellInfo(chi_torpedo charges=2 cd=20)
	SpellAddBuff(chi_torpedo chi_torpedo_buff=1)
	SpellRequire(chi_torpedo unusable 1=lossofcontrol,root)
Define(chi_torpedo_buff 119085)
	SpellInfo(chi_torpedo_buff duration=10)

# SpellInfo(crackling_jade_lightning haste=melee specialization=!mistweaver)
# SpellInfo(crackling_jade_lightning haste=spell specialization=mistweaver)
Define(dance_of_chiji_buff 286587)
    SpellInfo(dance_of_chiji_buff duration=15)
    
Define(detox_mistweaver 115450)
	SpellInfo(detox_mistweaver cd=8)

Define(detox 218164)
	SpellInfo(detox energy=20 cd=8)

Define(disable 116095)
	SpellInfo(disable energy=15 duration=15)
	SpellAddTargetDebuff(disable disable=1)
	SpellAddTargetDebuff(disable disable_root=1 if_target_debuff=disable)

Define(disable_root 116706)
	SpellInfo(disable_root duration=8)

Define(elusive_brew_stacks_buff 128939)
	SpellInfo(elusive_brew_stacks_buff duration=30 max_stacks=15)

Define(elusive_dance_buff 196739)
	SpellInfo(elusive_dance_buff duration=6)

Define(enveloping_mist 124682)
	SpellAddBuff(enveloping_mist thunder_focus_tea_buff=-1 if_spell=thunder_focus_tea)
	SpellAddTargetBuff(enveloping_mist enveloping_mist_buff=1)

Define(enveloping_mist_buff 132120)
	SpellInfo(enveloping_mist_buff duration=6 tick=1 haste=spell)

Define(essence_font 191837)
	SpellInfo(essence_font cd=12 channel=3 haste=spell)

Define(essence_font_buff 191837)
	SpellInfo(essence_font_buff duration=8 tick=2 haste=spell)


	SpellInfo(expel_harm energy=15 specialization=brewmaster unusable=1)
	SpellRequire(expel_harm unusable 0=spellcount_min,1,debuff,!healing_immunity_debuff)

Define(eye_of_the_tiger_debuff 196608)
	SpellInfo(eye_of_the_tiger_debuff duration=8)

SpellInfo(fist_of_the_white_tiger chi=-3)
SpellAddTargetDebuff(fist_of_the_white_tiger mark_of_the_crane_debuff=1 specialization=windwalker)

SpellInfo(fists_of_fury cd_haste=melee haste=melee)
SpellRequire(fists_of_fury chi_percent 0=buff,serenity)


	SpellInfo(flying_serpent_kick cd=25)
	SpellRequire(flying_serpent_kick unusable 1=lossofcontrol,root)

SpellAddBuff(fortifying_brew fortifying_brew_buff=1)

Define(fortifying_brew_buff 120954)
	SpellInfo(fortifying_brew_buff duration=15)

Define(fortifying_brew_mistweaver 243435)
	SpellInfo(fortifying_brew_mistweaver cd=90 gcd=0 offgcd=1 duration=15)
	SpellAddBuff(fortifying_brew_mistweaver fortifying_brew_mistweaver=1)

Define(guard 115295)
	SpellInfo(guard cd=30 duration=8)
	SpellAddBuff(guard guard=1)

Define(healing_elixir 122281)
	SpellInfo(healing_elixir charges=2 cd=30 unusable=1)
	SpellInfo(healing_elixir unusable=0 talent=healing_elixir_talent specialization=brewmaster)
	SpellInfo(healing_elixir unusable=0 talent=healing_elixir_talent_mistweaver specialization=mistweaver)
	SpellRequire(healing_elixir unusable 1=debuff,healing_immunity_debuff)

Define(invoke_chiji_the_red_crane 198664)
	SpellInfo(invoke_chiji_the_red_crane cd=180 totem=1)


	SpellInfo(invoke_niuzao_the_black_ox cd=180 totem=1)

	SpellInfo(invoke_xuen_the_white_tiger cd=180 totem=1)

SpellInfo(ironskin_brew cd=15 charges=3 cd_haste=melee)
SpellInfo(ironskin_brew add_cd=-3 charges=4 talent=light_brewing_talent)
SpellAddBuff(ironskin_brew ironskin_brew_buff=1)
SpellAddBuff(ironskin_brew blackout_combo_buff=0)

Define(ironskin_brew_buff 215479)
	SpellInfo(ironskin_brew_buff duration=7)

SpellInfo(keg_smash cd_haste=melee)
SpellAddBuff(keg_smash blackout_combo_buff=0)

SpellInfo(leg_sweep interrupt=1)
SpellInfo(leg_sweep add_cd=-10 talent=tiger_tail_sweep_talent)

Define(life_cocoon 116849)
	SpellInfo(life_cocoon cd=120 duration=12)
	SpellAddTargetBuff(life_cocoon life_cocoon=1)

Define(mana_tea 197908)
	SpellInfo(mana_tea cd=90 duration=12)
	SpellAddBuff(mana_tea mana_tea=1)

Define(mark_of_the_crane_debuff 228287)
		SpellInfo(mark_of_the_crane_debuff duration=15)
		
Define(mystic_touch 8647)
Define(mystic_touch_debuff 113746)

SpellInfo(paralysis interrupt=1)

Define(provoke 115546)
	SpellInfo(provoke cd=8)

SpellInfo(purifying_brew charges=3 cd_haste=melee)
SpellInfo(purifying_brew add_cd=-3 charges=4 talent=light_brewing_talent)
SpellInfo(purifying_brew unusable=1)
SpellAddBuff(purifying_brew blackout_combo_buff=0)
SpellRequire(purifying_brew unusable 0=debuff,any_stagger_debuff)

Define(reawaken 212051)

Define(refreshing_jade_wind 196725)
	SpellInfo(refreshing_jade_wind cd=9 mana=700 cd_haste=spell duration=9 tick=0.8 haste=spell)
	SpellAddTargetBuff(refreshing_jade_wind refreshing_jade_wind=1)

Define(renewing_mist 115151)
	SpellInfo(renewing_mist cd=9)
	SpellAddBuff(renewing_mist thunder_focus_tea_buff=-1 if_spell=thunder_focus_tea)
	SpellAddTargetBuff(renewing_mist renewing_mist_buff=1)

Define(renewing_mist_buff 119611)
	SpellInfo(renewing_mist_buff duration=18 haste=spell tick=2)
	SpellInfo(renewing_mist_buff add_duration=1 talent=mist_wrap_talent)

Define(resuscitate 115178)

Define(revival 115310)
	SpellInfo(revival cd=180)

Define(ring_of_peace 116844)
	SpellInfo(ring_of_peace cd=45)

SpellInfo(rising_sun_kick cd_haste=melee specialization=windwalker)
SpellInfo(rising_sun_kick cd_haste=spell cd=12 chi=0 specialization=mistweaver)
SpellRequire(rising_sun_kick chi_percent 0=buff,serenity)
SpellAddBuff(rising_sun_kick thunder_focus_tea_buff=-1 if_spell=thunder_focus_tea specialization=mistweaver)
SpellAddTargetDebuff(rising_sun_kick mark_of_the_crane_debuff=1 specialization=windwalker)
SpellAddBuff(rising_sun_kick swift_roundhouse_buff=0)

Define(roll 109132)
	SpellInfo(roll cd=20 charges=2)
	SpellInfo(roll charges=3 talent=celerity_talent)
	SpellInfo(roll replaced_by=chi_torpedo talent=chi_torpedo_talent)
	SpellRequire(roll unusable 1=lossofcontrol,root)

    SpellInfo(rushing_jade_wind chi=0 specialization=!windwalker)
Define(rushing_jade_wind_buff 116847)
    SpellInfo(rushing_jade_wind_buff duration=9 haste=melee)
    SpellAddBuff(rushing_jade_wind rushing_jade_wind_buff=1 specialization=brewmaster)
Define(rushing_jade_wind_windwalker_buff 261715)
    SpellInfo(rushing_jade_wind_windwalker_buff tick=0.8 haste=melee)
    SpellAddBuff(rushing_jade_wind rushing_jade_wind_windwalker_buff=1 specialization=windwalker)
    
Define(song_of_chiji 198898)
	SpellInfo(song_of_chiji cd=30)
	SpellAddTargetDebuff(song_of_chiji song_of_chiji_debuff=1)
Define(song_of_chiji_debuff 198909)
	SpellInfo(song_of_chiji_debuff duration=20)
Define(soothing_mist 115175)
	SpellInfo(soothing_mist cd=1 channel=8 duration=8 haste=spell tick=1)
	SpellAddTargetBuff(soothing_mist soothing_mist=1)

SpellInfo(spinning_crane_kick chi=2 haste=melee specialization=windwalker)
SpellInfo(spinning_crane_kick chi=0 haste=spell specialization=mistweaver)
SpellRequire(spinning_crane_kick chi_percent 0=buff,serenity)

    SpellRequire(storm_earth_and_fire unusable 1=buff,storm_earth_and_fire)
	SpellInfo(storm_earth_and_fire replaced_by=serenity talent=serenity_talent)

Define(summon_black_ox_statue 115315)
	SpellInfo(summon_black_ox_statue cd=10 duration=900 totem=1 max_totems=1)

Define(summon_jade_serpent_statue 115313)
    SpellInfo(summon_jade_serpent_statue cd=10 duration=900 totem=1 max_totems=1)

SpellInfo(swift_roundhouse_buff max_stacks=2)

Define(teachings_of_the_monastery 116645)
Define(teachings_of_the_monastery_buff 202090)
	SpellInfo(teachings_of_the_monastery_buff duration=12 max_stacks=3)

Define(thunder_focus_tea 116680)
	SpellInfo(thunder_focus_tea cd=30 gcd=0 offgcd=1 duration=3)
	SpellAddBuff(thunder_focus_tea thunder_focus_tea=1)
	SpellAddBuff(thunder_focus_tea thunder_focus_tea=2 talent=focused_thunder_talent)

SpellInfo(tiger_palm energy=50 specialization=windwalker)
SpellInfo(tiger_palm energy=25 specialization=brewmaster)
SpellAddBuff(tiger_palm teachings_of_the_monastery_buff=1 specialization=mistweaver)
SpellAddBuff(tiger_palm blackout_combo_buff=0 specialization=windwalker)
SpellAddTargetDebuff(tiger_palm eye_of_the_tiger_debuff=1 specialization=!mistweaver talent=eye_of_the_tiger_talent)
SpellAddTargetDebuff(tiger_palm mark_of_the_crane_debuff=1 specialization=windwalker)

Define(tigers_lust 116841)
	SpellInfo(tigers_lust cd=30 duration=6)
	SpellAddBuff(tigers_lust tigers_lust=1)

SpellRequire(touch_of_death unusable 1=target_debuff,touch_of_death_debuff)

Define(transcendence 101643)
Define(transcendence_transfer 119996)

Define(vivify 116670)
	SpellAddBuff(vivify thunder_focus_tea_buff=-1 if_spell=thunder_focus_tea)

SpellInfo(whirling_dragon_punch unusable=1 cd_haste=melee)
SpellRequire(whirling_dragon_punch unusable 0=oncooldown,rising_sun_kick)
SpellRequire(whirling_dragon_punch unusable 0=oncooldown,fists_of_fury)

Define(zen_meditation 115176)
	SpellInfo(zen_meditation cd=300 gcd=0 offgcd=1)
	SpellAddBuff(zen_meditation zen_meditation_buff=1)
Define(zen_meditation_buff 115176)
	SpellInfo(zen_meditation_buff duration=8)
	
## Stagger
Define(stagger 115069)
Define(heavy_stagger_debuff 124273)
	SpellInfo(heavy_stagger_debuff duration=10 tick=1)
	SpellInfo(heavy_stagger_debuff add_duration=3 talent=bob_and_weave_talent)
Define(light_stagger_debuff 124275)
	SpellInfo(light_stagger_debuff duration=10 tick=1)
	SpellInfo(light_stagger_debuff add_duration=3 talent=bob_and_weave_talent)
Define(moderate_stagger_debuff 124274)
	SpellInfo(moderate_stagger_debuff duration=10 tick=1)
	SpellInfo(moderate_stagger_debuff add_duration=3 talent=bob_and_weave_talent)
SpellList(any_stagger_debuff light_stagger_debuff moderate_stagger_debuff heavy_stagger_debuff)

## Items
Define(hidden_masters_forbidden_touch_buff 213114)
	SpellInfo(hidden_masters_forbidden_touch_buff duration=5)
# SpellAddBuff(crackling_jade_lightning the_emperors_capacitor_buff=0)


## Talents
Define(ascension_talent 7)
Define(bob_and_weave_talent 13)
Define(celerity_talent 4)
Define(chi_torpedo_talent 5)
Define(eye_of_the_tiger_talent 1)
Define(focused_thunder_talent 19)
Define(guard_talent 20)
Define(healing_elixir_talent 14)
Define(healing_elixir_talent_mistweaver 13)
Define(high_tolerance_talent 19)
Define(hit_combo_talent 16)
Define(inner_strength_talent 13)
Define(invoke_chiji_the_red_crane_talent 18)
Define(lifecycles_talent 7)
Define(light_brewing_talent 7)
Define(mana_tea_talent 9)
Define(mist_wrap_talent 1)
Define(refreshing_jade_wind_talent 17)
Define(ring_of_peace_talent 12)
Define(rising_mist_talent 21)
Define(song_of_chiji_talent 11)
Define(special_delivery_talent 16)
Define(spirit_of_the_crane_talent 8)
Define(spiritual_focus_talent 19)
Define(spitfire_talent 8)
Define(summon_black_ox_statue_talent 11)
Define(summon_jade_serpent_statue_talent 16)
Define(tiger_tail_sweep_talent 10)
Define(tigers_lust_talent 6)
Define(upwelling_talent 20)

# Non-default tags for OvaleSimulationCraft.
SpellInfo(chi_burst tag=main)
SpellInfo(chi_torpedo tag=shortcd)
SpellInfo(dampen_harm tag=cd)
SpellInfo(diffuse_magic tag=cd)
SpellInfo(fist_of_the_white_tiger tag=main)
SpellInfo(ironskin_brew tag=shortcd)
SpellInfo(purifying_brew tag=shortcd)
SpellInfo(storm_earth_and_fire tag=cd)
]]
    OvaleScripts:RegisterScript("MONK", nil, name, desc, code, "include")
end
