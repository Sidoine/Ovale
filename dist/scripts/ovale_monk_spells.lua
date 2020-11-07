local __exports = LibStub:NewLibrary("ovale/scripts/ovale_monk_spells", 80300)
if not __exports then return end
__exports.registerMonkSpells = function(OvaleScripts)
    local name = "ovale_monk_spells"
    local desc = "[9.0] Ovale: Monk spells"
    local code = [[Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
Define(arcane_torrent 25046)
# Remove s1 beneficial effect from all enemies within A1 yards and restore m2 Energy.
  SpellInfo(arcane_torrent cd=120 gcd=1 energy=-15)
Define(bag_of_tricks 312411)
# Pull your chosen trick from the bag and use it on target enemy or ally. Enemies take <damage> damage, while allies are healed for <healing>. 
  SpellInfo(bag_of_tricks cd=90)
Define(berserking 59621)
# Permanently enchant a melee weapon to sometimes increase your attack power by 59620s1, but at the cost of reduced armor. Cannot be applied to items higher than level ecix
  SpellInfo(berserking gcd=0 offgcd=1)
Define(black_ox_brew 115399)
# Chug some Black Ox Brew, which instantly refills your Energy, Purifying Brew charges, and resets the cooldown of Celestial Brew.
  SpellInfo(black_ox_brew cd=120 gcd=0 offgcd=1 energy=-200 talent=black_ox_brew_talent)
Define(blackout_combo_buff 228563)
# Blackout Kick also empowers your next ability:rnrnTiger Palm: Damage increased by s1.rnBreath of Fire: Cooldown reduced by s2 sec.rnKeg Smash: Reduces the remaining cooldown on your Brews by s3 additional sec.rnCelestial Brew: Pauses Stagger damage for s4 sec.
  SpellInfo(blackout_combo_buff duration=15 gcd=0 offgcd=1)
  # Your next ability is empowered.
  SpellAddBuff(blackout_combo_buff blackout_combo_buff=1)
Define(blackout_kick 205523)
# Strike with a blast of Chi energy, dealing s1 Physical damage?s117906[ and granting Shuffle for s2 sec][].
  SpellInfo(blackout_kick cd=4)
Define(blackout_kick_aura 116768)
# You have a m1 chance when you Tiger Palm to cause your next Blackout Kick to cost no Chi within 15 seconds.
  SpellInfo(blackout_kick_aura duration=15 gcd=0 offgcd=1)
  # Your next Blackout Kick costs no Chi.
  SpellAddBuff(blackout_kick_aura blackout_kick_aura=1)
Define(blood_fury 20572)
# Increases your attack power by s1 for 15 seconds.
  SpellInfo(blood_fury cd=120 duration=15 gcd=0 offgcd=1)
  # Attack power increased by w1.
  SpellAddBuff(blood_fury blood_fury=1)
Define(blood_of_the_enemy 297969)
# Infuse your Heart of Azeroth with Blood of the Enemy.
  SpellInfo(blood_of_the_enemy)
Define(bloodlust 2825)
# Increases haste by (25 of Spell Power) for all party and raid members for 40 seconds.rnrnAllies receiving this effect will become Sated and unable to benefit from Bloodlust or Time Warp again for 600 seconds.
  SpellInfo(bloodlust cd=300 duration=40 gcd=0 offgcd=1)
  # Haste increased by w1.
  SpellAddBuff(bloodlust bloodlust=1)
Define(breath_of_fire 115181)
# Breathe fire on targets in front of you, causing s1 Fire damage.rnrnTargets affected by Keg Smash will also burn, taking 123725o1 Fire damage and dealing 123725s2 reduced damage to you for 12 seconds.
  SpellInfo(breath_of_fire cd=15 gcd=1)
Define(breath_of_fire_debuff 123725)
# Breathe fire on targets in front of you, causing s1 Fire damage.rnrnTargets affected by Keg Smash will also burn, taking 123725o1 Fire damage and dealing 123725s2 reduced damage to you for 12 seconds.
  SpellInfo(breath_of_fire_debuff duration=12 gcd=1 tick=2)
  # Burning for w1 Fire damage every t1 sec.  Dealing w2 reduced damage to the Monk.
  SpellAddTargetDebuff(breath_of_fire_debuff breath_of_fire_debuff=1)
Define(celestial_brew 322507)
# A swig of strong brew that coalesces purified chi escaping your body into a celestial guard, absorbing <absorb> damage.?s322510[rnrnPurifying Stagger damage increases absorption by up to 322510s1.][]
  SpellInfo(celestial_brew cd=60 duration=8 gcd=1)
  # Absorbs w1 damage.?w2>0[rnYour self-healing increased by w2.][]
  SpellAddBuff(celestial_brew celestial_brew=1)
Define(chi_burst 123986)
# Hurls a torrent of Chi energy up to 40 yds forward, dealing 148135s1 Nature damage to all enemies, and 130654s1 healing to the Monk and all allies in its path.?c1[rnrnCasting Chi Burst does not prevent avoiding attacks.][]?c3[rnrnChi Burst generates 1 Chi per enemy target damaged, up to a maximum of s3.][]
  SpellInfo(chi_burst cd=30 duration=1 talent=chi_burst_talent)
Define(chi_energy 337571)
# Whenever you deal damage to a target with Fists of Fury, you gain a stack of Chi Energy up to a maximum of m2 stacks.rnrnUsing Spinning Crane Kick will cause the energy to detonate in a Chi Explosion, dealing 337342s1 damage to all enemies within 337342A1 yards. The damage is increased by 337571m1 for each stack of Chi Energy.
  SpellInfo(chi_energy duration=45 max_stacks=30 gcd=0 offgcd=1)
  # Increases the damage done by your next Chi Explosion by s1.rnrnChi Explosion is triggered whenever you use Spinning Crane Kick.
  SpellAddBuff(chi_energy chi_energy=1)
Define(chi_wave 115098)
# A wave of Chi energy flows through friends and foes, dealing 132467s1 Nature damage or 132463s1 healing. Bounces up to s1 times to targets within 132466a2 yards.
  SpellInfo(chi_wave cd=15 talent=chi_wave_talent)
Define(concentrated_flame 295368)
# Blast your target with a ball of concentrated flame, dealing 295365s2*(1+@versadmg) Fire damage to an enemy or healing an ally for 295365s2*(1+@versadmg)?a295377[, then burn the target for an additional 295377m1 of the damage or healing done over 6 seconds][]. rnrnEach cast of Concentrated Flame deals s3 increased damage or healing. This bonus resets after every third cast.
  SpellInfo(concentrated_flame duration=6 gcd=0 offgcd=1 tick=2)
  # Suffering w1 damage every t1 sec.
  SpellAddTargetDebuff(concentrated_flame concentrated_flame=1)
Define(conductive_ink 302491)
# Your damaging abilities against enemies above M3 health have a very high chance to apply Conductive Ink. When an enemy falls below M3 health, Conductive Ink inflicts s1*(1+@versadmg) Nature damage per stack.
  SpellInfo(conductive_ink gcd=0 offgcd=1)

Define(dampen_harm 122278)
# Reduces all damage you take by m2 to m3 for 10 seconds, with larger attacks being reduced by more.
  SpellInfo(dampen_harm cd=120 duration=10 gcd=0 offgcd=1 talent=dampen_harm_talent)
  # Damage taken reduced by m2 to m3 for d, with larger attacks being reduced by more.
  SpellAddBuff(dampen_harm dampen_harm=1)
Define(dance_of_chiji_buff 286587)
# Spending Chi has a chance to make your next Spinning Crane Kick free and deal s1 additional damage.
  SpellInfo(dance_of_chiji_buff duration=15 gcd=0 offgcd=1)
  # Your next Spinning Crane Kick is free and deals w1 additional damage.
  SpellAddBuff(dance_of_chiji_buff dance_of_chiji_buff=1)

Define(diffuse_magic 122783)
# Reduces magic damage you take by m1 for 6 seconds, and transfers all currently active harmful magical effects on you back to their original caster if possible.
  SpellInfo(diffuse_magic cd=90 duration=6 gcd=0 offgcd=1 talent=diffuse_magic_talent)
  # Spell damage taken reduced by m1.
  SpellAddBuff(diffuse_magic diffuse_magic=1)
Define(elusive_brawler 195630)
# Each time you are hit by a melee attack, or hit with Blackout Kick, you gain stacking (100 of Spell Power).1 increased Dodge chance until your next successful Dodge.rnrnAlso increases your attack power by (100 of Spell Power).1.
  SpellInfo(elusive_brawler duration=10 max_stacks=100 gcd=0 offgcd=1)
  # Dodge chance increased by w1.
  SpellAddBuff(elusive_brawler elusive_brawler=1)
Define(energizing_elixir 115288)
# Chug an Energizing Elixir, granting s2 Chi and generating s1/5*5 Energy over 5 seconds.
  SpellInfo(energizing_elixir cd=60 duration=5 max_stacks=3 gcd=0 offgcd=1 chi=-2 talent=energizing_elixir_talent)
  # Generating w1/5 extra Energy per sec.
  SpellAddBuff(energizing_elixir energizing_elixir=1)
Define(expel_harm 322101)
# Expel negative chi from your body, healing for (120 of Spell Power) and dealing s2 of the amount healed as Nature damage to an enemy within 115129A1 yards.?s322102[rnrnDraws in the positive chi of all your Healing Spheres to increase the healing of Expel Harm.][]?s325214[rnrnMay be cast during Soothing Mist, and will additionally heal the Soothing Mist target.][]?s322106[rnrn|cFFFFFFFFGenerates s3 Chi.]?s342928[rnrn|cFFFFFFFFGenerates s3+342928s2 Chi.][]
  SpellInfo(expel_harm energy=15 cd=15 gcd=1 chi=0)
Define(fireblood 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. ?s195710[This effect shares a 30 sec cooldown with other similar effects.][]
  SpellInfo(fireblood cd=120 gcd=0 offgcd=1)
Define(fist_of_the_white_tiger 261947)
# Strike with the technique of the White Tiger, dealing s1+261977s1 Physical damage.rnrn|cFFFFFFFFGenerates 261978s1 Chi.
  SpellInfo(fist_of_the_white_tiger energy=40 cd=30 gcd=1 talent=fist_of_the_white_tiger_talent)

Define(fists_of_fury 113656)
# Pummels all targets in front of you, dealing 5*s5 damage over 4 seconds to your primary target and 5*s5*s6/100 damage over 4 seconds to up to s1 other targets. Can be channeled while moving.
  SpellInfo(fists_of_fury chi=3 cd=24 duration=4 channel=4 gcd=1 tick=0.166)
  # w3 damage every t3 sec. ?s125671[Parrying all attacks.][]
  SpellAddBuff(fists_of_fury fists_of_fury=1)
Define(flying_serpent_kick 101545)
# Soar forward through the air at high speed for 1.5 seconds.rn rnIf used again while active, you will land, dealing 123586m1 damage to all enemies within 123586A1 yards and reducing movement speed by 123586m2 for 4 seconds.
  SpellInfo(flying_serpent_kick cd=25 duration=1.5 gcd=1)
  SpellAddBuff(flying_serpent_kick flying_serpent_kick=1)
Define(focused_azerite_beam 295258)
# Focus excess Azerite energy into the Heart of Azeroth, then expel that energy outward, dealing m1*10 Fire damage to all enemies in front of you over 3 seconds.?a295263[ Castable while moving.][]
  SpellInfo(focused_azerite_beam cd=90 duration=3 channel=3 tick=0.33)
  SpellAddBuff(focused_azerite_beam focused_azerite_beam=1)
Define(fortifying_brew 243435)
# Turns your skin to stone, increasing your current and maximum health by s1 and reducing damage taken by s2 for 15 seconds.
  SpellInfo(fortifying_brew cd=420 duration=15 gcd=0 offgcd=1)
  # Maximum health increased by w1.rnDamage taken reduced by w2.?w4>1[rnAbsorbs w4 damage.][]
  SpellAddBuff(fortifying_brew fortifying_brew=1)
Define(fortifying_brew_buff 120954)
# Turns your skin to stone for 15 seconds, increasing your current and maximum health by <health>?s322960[, increasing the effectiveness of Stagger by s1,][] and reducing all damage you take by <damage>.
  SpellInfo(fortifying_brew_buff duration=15 gcd=0 offgcd=1)
  # Health increased by <health>, damage taken reduced by <damage>, and effectiveness of Stagger increased by 115203s1.
  SpellAddBuff(fortifying_brew_buff fortifying_brew_buff=1)
Define(gift_of_the_ox 124502)
# When you take damage, you have a chance to summon a Healing Sphere visible only to you. Moving through this Healing Sphere heals you for 124507s1.
  SpellInfo(gift_of_the_ox gcd=0 offgcd=1)
  SpellAddBuff(gift_of_the_ox gift_of_the_ox=1)
Define(guardian_of_azeroth 295840)
# Call upon Azeroth to summon a Guardian of Azeroth for 30 seconds who impales your target with spikes of Azerite every s1/10.1 sec that deal 295834m1*(1+@versadmg) Fire damage.?a295841[ Every 303347t1 sec, the Guardian launches a volley of Azerite Spikes at its target, dealing 295841s1 Fire damage to all nearby enemies.][]?a295843[rnrnEach time the Guardian of Azeroth casts a spell, you gain 295855s1 Haste, stacking up to 295855u times. This effect ends when the Guardian of Azeroth despawns.][]rn
  SpellInfo(guardian_of_azeroth cd=180 duration=30)
  SpellAddBuff(guardian_of_azeroth guardian_of_azeroth=1)
Define(invoke_niuzao_the_black_ox 132578)
# Summons an effigy of Niuzao, the Black Ox for 25 seconds. Niuzao attacks your primary target, and frequently Stomps, damaging all nearby enemies?s322740[ for 227291s1 plus 322740s1 of Stagger damage you have recently purified.][.]rnrnWhile active, s2 of damage delayed by Stagger is instead Staggered by Niuzao.
  SpellInfo(invoke_niuzao_the_black_ox cd=180 duration=25)
  # Niuzao is staggering s2 of the Monk's Stagger damage.
  SpellAddBuff(invoke_niuzao_the_black_ox invoke_niuzao_the_black_ox=1)
Define(invoke_xuen_the_white_tiger 123904)
# Summons an effigy of Xuen, the White Tiger for 24 seconds. Xuen attacks your primary target, and strikes 3 enemies within 123996A1 yards every 123999t1 sec with Tiger Lightning for 123996s1 Nature damage.?s323999[rnrnEvery 323999s1 sec, Xuen strikes your enemies with Empowered Tiger Lightning dealing 323999s2 of the damage you have dealt to those targets in the last 323999s1 sec.][]
  SpellInfo(invoke_xuen_the_white_tiger cd=120 duration=24 gcd=1 tick=4)
  SpellAddBuff(invoke_xuen_the_white_tiger invoke_xuen_the_white_tiger=1)
Define(keg_smash 121253)
# Smash a keg of brew on the target, dealing s2 damage to all enemies within A2 yds and reducing their movement speed by m3 for 15 seconds. Deals reduced damage beyond s7 targets.rnrnGrants Shuffle for s6 sec and reduces the remaining cooldown on your Brews by s4 sec.
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

Define(memory_of_lucid_dreams 299300)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams)
Define(paralysis 115078)
# Incapacitates the target for 60 seconds. Limit 1. Damage will cancel the effect.
  SpellInfo(paralysis energy=20 cd=45 duration=60)
  # Incapacitated.
  SpellAddTargetDebuff(paralysis paralysis=1)
Define(purifying_blast 295337)
# Call down a purifying beam upon the target area, dealing 295293s3*(1+@versadmg)*s2 Fire damage over 6 seconds.?a295364[ Has a low chance to immediately annihilate any specimen deemed unworthy by MOTHER.][]?a295352[rnrnWhen an enemy dies within the beam, your damage is increased by 295354s1 for 8 seconds.][]rnrnAny Aberration struck by the beam is stunned for 3 seconds.
  SpellInfo(purifying_blast cd=60 duration=6)
Define(purifying_brew 119582)
# Clears s1 of your damage delayed with Stagger.?s322510[rnrnIncreases the absorption of your next Celestial Brew by up to 322510s1, based on your current level of Stagger][]
  SpellInfo(purifying_brew cd=1 charge_cd=20 gcd=0 offgcd=1)
Define(quaking_palm 107079)
# Strikes the target with lightning speed, incapacitating them for 4 seconds, and turns off your attack.
  SpellInfo(quaking_palm cd=120 duration=4 gcd=1)
  # Incapacitated.
  SpellAddTargetDebuff(quaking_palm quaking_palm=1)
Define(razor_coral_debuff 303568)
# ?a303565[Remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.][Deal 304877s1*(1+@versadmg) Physical damage and apply Razor Coral to your target, giving your damaging abilities against the target a high chance to deal 304877s1*(1+@versadmg) Physical damage and add a stack of Razor Coral.rnrnReactivating this ability will remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.]rn
  SpellInfo(razor_coral_debuff duration=120 max_stacks=100 gcd=0 offgcd=1)
  # Withdrawing the Razor Coral will grant w1 Critical Strike.
  SpellAddTargetDebuff(razor_coral_debuff razor_coral_debuff=1)
Define(reaping_flames 310690)
# Burn your target with a bolt of Azerite, dealing 310712s3 Fire damage. If the target has less than s2 health?a310705[ or more than 310705s1 health][], the cooldown is reduced by s3 sec.?a310710[rnrnIf Reaping Flames kills an enemy, its cooldown is lowered to 310710s2 sec and it will deal 310710s1 increased damage on its next use.][]
  SpellInfo(reaping_flames cd=45)
Define(ripple_in_space 299306)
# Infuse your Heart of Azeroth with Ripple in Space.
  SpellInfo(ripple_in_space)
Define(rising_sun_kick 107428)
# Kick upwards, dealing ?s137025[185099s1*<CAP>/AP][185099s1] Physical damage?s128595[, and reducing the effectiveness of healing on the target for 10 seconds][].
  SpellInfo(rising_sun_kick chi=2 cd=10)

Define(rushing_jade_wind 116847)
# Summons a whirling tornado around you, causing (1+6 seconds/t1)*148187s1 damage over 6 seconds to up to s1 enemies within 107270A1 yards.
  SpellInfo(rushing_jade_wind chi=1 cd=6 duration=6 tick=0.75 talent=rushing_jade_wind_talent_windwalker)
  SpellAddBuff(rushing_jade_wind rushing_jade_wind_buff=1)
  # Dealing physical damage to nearby enemies every 116847t1 sec.
  SpellAddBuff(rushing_jade_wind rushing_jade_wind=1)
Define(rushing_jade_wind_buff 148187)
# Summons a whirling tornado around you, causing (1+6 seconds/t1)*148187s1 damage over 6 seconds to up to s1 enemies within 107270A1 yards.
  SpellInfo(rushing_jade_wind_buff gcd=0 offgcd=1)
Define(seething_rage 297126)
# Increases your critical hit damage by 297126m for 5 seconds.
  SpellInfo(seething_rage duration=5 gcd=0 offgcd=1)
  # Critical strike damage increased by w1.
  SpellAddBuff(seething_rage seething_rage=1)
Define(serenity 152173)
# Enter an elevated state of mental and physical serenity for ?s115069[s1 sec][12 seconds]. While in this state, you deal s2 increased damage and healing, and all Chi consumers are free and cool down s4 more quickly.
  SpellInfo(serenity cd=90 duration=12 gcd=0 offgcd=1 talent=serenity_talent)
  # Damage and healing increased by w2.rnAll Chi consumers are free and cool down w4 more quickly.
  SpellAddBuff(serenity serenity=1)
Define(spear_hand_strike 116705)
# Jabs the target in the throat, interrupting spellcasting and preventing any spell from that school of magic from being cast for 4 seconds.
  SpellInfo(spear_hand_strike cd=15 duration=4 gcd=0 offgcd=1 interrupt=1)
Define(spinning_crane_kick 322729)
# Spin while kicking in the air, dealing ?s137025[4*107270s1*<CAP>/AP][4*107270s1] Physical damage over 1.5 seconds to enemies within 107270A1 yds.?c3[rnrnSpinning Crane Kick's damage is increased by 220358s1 for each unique target you've struck in the last 15 seconds with Tiger Palm, Blackout Kick, or Rising Sun Kick.][]
  SpellInfo(spinning_crane_kick energy=25 duration=1.5 channel=1.5 tick=0.5)
  # Attacking all nearby enemies for Physical damage every 101546t1 sec.
  SpellAddBuff(spinning_crane_kick spinning_crane_kick=1)
Define(storm_earth_and_fire 137639)
# Split into 3 elemental spirits for 15 seconds, each spirit dealing 100+m1 of normal damage and healing.rnrnYou directly control the Storm spirit, while Earth and Fire spirits mimic your attacks on nearby enemies.rnrnWhile active, casting Storm, Earth, and Fire again will cause the spirits to fixate on your target.
  SpellInfo(storm_earth_and_fire cd=16 charge_cd=90 duration=15 max_stacks=2 gcd=0 offgcd=1)
  # Elemental spirits summoned, mirroring all of the Monk's attacks.rnThe Monk and spirits each do 100+m1 of normal damage and healing.
  SpellAddBuff(storm_earth_and_fire storm_earth_and_fire=1)
Define(the_unbound_force 299321)
# Infuse your Heart of Azeroth with The Unbound Force.
  SpellInfo(the_unbound_force)
Define(tiger_palm 100780)
# Strike with the palm of your hand, dealing s1 Physical damage.?a137384[rnrnTiger Palm has an 137384m1 chance to make your next Blackout Kick cost no Chi.][]?a137023[rnrnReduces the remaining cooldown on your Brews by s3 sec.][]?a137025[rnrn|cFFFFFFFFGenerates s2 Chi.][]
  SpellInfo(tiger_palm energy=50 chi=0)
Define(touch_of_death 322109)
# You exploit the enemy target's weakest point, instantly killing ?s322113[creatures if they have less health than you.][them.rnrnOnly usable on creatures that have less health than you]?s322113[ Deals damage equal to s3 of your maximum health against players and stronger creatures under s2 health.][.]?s325095[rnrnReduces delayed Stagger damage by 325095s1 of damage dealt.]?s325215[rnrnSpawns 325215s1 Chi Spheres, granting 1 Chi when you walk through them.]?s344360[rnrnIncreases the Monk's Physical damage by 344361s1 for 10 seconds.][]
  SpellInfo(touch_of_death cd=180)
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
Define(worldvein_resonance 298606)
# Infuse your Heart of Azeroth with Worldvein Resonance.
  SpellInfo(worldvein_resonance)
Define(black_ox_brew_talent 9) #19992
# Chug some Black Ox Brew, which instantly refills your Energy, Purifying Brew charges, and resets the cooldown of Celestial Brew.
Define(blackout_combo_talent 21) #22108
# Blackout Kick also empowers your next ability:rnrnTiger Palm: Damage increased by s1.rnBreath of Fire: Cooldown reduced by s2 sec.rnKeg Smash: Reduces the remaining cooldown on your Brews by s3 additional sec.rnCelestial Brew: Pauses Stagger damage for s4 sec.
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
Define(rushing_jade_wind_talent_windwalker 17) #23122
# Summons a whirling tornado around you, causing (1+6 seconds/t1)*148187s1 damage over 6 seconds to up to s1 enemies within 107270A1 yards.
Define(rushing_jade_wind_talent 17) #20184
# Summons a whirling tornado around you, causing (1+6 seconds/t1)*148187s1 damage over 6 seconds to up to s1 enemies within 107270A1 yards.
Define(serenity_talent 21) #21191
# Enter an elevated state of mental and physical serenity for ?s115069[s1 sec][12 seconds]. While in this state, you deal s2 increased damage and healing, and all Chi consumers are free and cool down s4 more quickly.
Define(special_delivery_talent 16) #19819
# Drinking from your Brews has a h chance to toss a keg high into the air that lands nearby after s1 sec, dealing 196733s1 damage to all enemies within 196733A1 yards and reducing their movement speed by 196733m2 for 15 seconds.
Define(whirling_dragon_punch_talent 20) #22105
# Performs a devastating whirling upward strike, dealing 3*158221s1 damage to all nearby enemies. Only usable while both Fists of Fury and Rising Sun Kick are on cooldown.
Define(unbridled_fury_item 139327)
Define(the_crucible_of_flame_essence_id 12)
Define(blood_of_the_enemy_essence_id 23)
Define(conflict_and_strife_essence_id 32)
    ]]
    code = code .. [[
Define(detox 218164)
    SpellInfo(detox cd=8)
Define(healing_elixir 122281)
    SpellInfo(healing_elixir charge_cd=30 gcd=0 offgcd=1)

    SpellInfo(rising_sun_kick chi=0 spec=!windwalker)
    SpellInfo(rushing_jade_wind chi=0 spec=!windwalker)
    
    SpellRequire(storm_earth_and_fire unusable 1=buff,storm_earth_and_fire)

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
SpellInfo(purifying_brew unusable=1)
SpellRequire(purifying_brew unusable 0=debuff,any_stagger_debuff)

Define(bob_and_weave_talent 13)
    ]]
    OvaleScripts:RegisterScript("MONK", nil, name, desc, code, "include")
end
