import { OvaleScriptsClass } from "../engine/scripts";

export function registerMonkSpells(OvaleScripts: OvaleScriptsClass) {
    const name = "ovale_monk_spells";
    const desc = "[9.0] Ovale: Monk spells";
    // THIS PART OF THIS FILE IS AUTOMATICALLY GENERATED
    let code = `Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
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
  SpellInfo(black_ox_brew cd=120 gcd=0 offgcd=1 energy=-200)
  SpellRequire(black_ox_brew unusable set=1 enabled=(not hastalent(black_ox_brew_talent)))
Define(blackout_combo_buff 228563)
# Blackout Kick also empowers your next ability:rnrnTiger Palm: Damage increased by s1.rnBreath of Fire: Cooldown reduced by s2 sec.rnKeg Smash: Reduces the remaining cooldown on your Brews by s3 additional sec.rnCelestial Brew: Pauses Stagger damage for s4 sec.
  SpellInfo(blackout_combo_buff duration=15 gcd=0 offgcd=1)
Define(blackout_kick 100784)
# Kick with a blast of Chi energy, dealing ?s137025[s1*<CAP>/AP][s1] Physical damage.?s261917[rnrnReduces the cooldown of Rising Sun Kick and Fists of Fury by m3/1000.1 sec when used.][]
  SpellInfo(blackout_kick chi=3 cd=3)
  SpellRequire(blackout_kick replaced_by set=blackout_kick_brewmaster enabled=(specialization("brewmaster")))
Define(blackout_kick_aura 116768)
# You have a m1 chance when you Tiger Palm to cause your next Blackout Kick to cost no Chi within 15 seconds.
  SpellInfo(blackout_kick_aura duration=15 gcd=0 offgcd=1)
Define(blackout_kick_brewmaster 205523)
# Strike with a blast of Chi energy, dealing s1 Physical damage?s117906[ and granting Shuffle for s2 sec][].
  SpellInfo(blackout_kick_brewmaster cd=4)
Define(blood_fury_ap_int 33697)
# Increases your attack power and Intellect by s1 for 15 seconds.
  SpellInfo(blood_fury_ap_int cd=120 duration=15 gcd=0 offgcd=1)
  # Attack power and Intellect increased by w1.
  SpellAddBuff(blood_fury_ap_int blood_fury_ap_int add=1)
Define(bloodlust 2825)
# Increases haste by (25 of Spell Power) for all party and raid members for 40 seconds.rnrnAllies receiving this effect will become Sated and unable to benefit from Bloodlust or Time Warp again for 600 seconds.
  SpellInfo(bloodlust cd=300 duration=40 gcd=0 offgcd=1)
  # Haste increased by w1.
  SpellAddBuff(bloodlust bloodlust add=1)
Define(bonedust_brew 325216)
# Hurl a brew created from the bones of your enemies at the ground, coating all targets struck for 10 seconds.  Your abilities have a h chance to affect the target a second time at s1 effectiveness as Shadow damage or healing.rnrn?s137024[Gust of Mists heals targets with your Bonedust Brew active for an additional 328748s1.]?s137023[Tiger Palm and Keg Smash reduces the cooldown of your brews by an additional s3 sec when striking enemies with your Bonedust Brew active.]?s137025[Spinning Crane Kick refunds 1 Chi when striking enemies with your Bonedust Brew active.][]
  SpellInfo(bonedust_brew cd=60 duration=10 gcd=1)
  # The Monk's abilities have a h chance to affect the target a second time at s1 effectiveness as Shadow damage or healing.
  SpellAddTargetDebuff(bonedust_brew bonedust_brew add=1)
Define(breath_of_fire 115181)
# Breathe fire on targets in front of you, causing s1 Fire damage.rnrnTargets affected by Keg Smash will also burn, taking 123725o1 Fire damage and dealing 123725s2 reduced damage to you for 12 seconds.
  SpellInfo(breath_of_fire cd=15 gcd=1)
Define(breath_of_fire_debuff 123725)
# Breathe fire on targets in front of you, causing s1 Fire damage.rnrnTargets affected by Keg Smash will also burn, taking 123725o1 Fire damage and dealing 123725s2 reduced damage to you for 12 seconds.
  SpellInfo(breath_of_fire_debuff duration=12 gcd=1 tick=2)
  # Burning for w1 Fire damage every t1 sec.  Dealing w2 reduced damage to the Monk.
  SpellAddTargetDebuff(breath_of_fire_debuff breath_of_fire_debuff add=1)
Define(celestial_brew 322507)
# A swig of strong brew that coalesces purified chi escaping your body into a celestial guard, absorbing <absorb> damage.?s322510[rnrnPurifying Stagger damage increases absorption by up to 322510s1.][]
  SpellInfo(celestial_brew cd=60 duration=8 gcd=1)
  # Absorbs w1 damage.?w2>0[rnYour self-healing increased by w2.][]
  SpellAddBuff(celestial_brew celestial_brew add=1)
Define(charred_passions_buff 338140)
# Your Breath of Fire ignites your right leg in flame for 8 seconds, causing your Blackout Kick and Spinning Crane Kick to deal m1 additional damage as Fire damage and refresh the duration of your Breath of Fire on the target.
  SpellInfo(charred_passions_buff duration=8 gcd=0 offgcd=1)
Define(chi_burst 123986)
# Hurls a torrent of Chi energy up to 40 yds forward, dealing 148135s1 Nature damage to all enemies, and 130654s1 healing to the Monk and all allies in its path.?c1[rnrnCasting Chi Burst does not prevent avoiding attacks.][]?c3[rnrnChi Burst generates 1 Chi per enemy target damaged, up to a maximum of s3.][]
  SpellInfo(chi_burst cd=30 duration=1)
  SpellRequire(chi_burst unusable set=1 enabled=(not hastalent(chi_burst_talent)))
Define(chi_energy 337571)
# Whenever you deal damage to a target with Fists of Fury, you gain a stack of Chi Energy up to a maximum of m2 stacks.rnrnUsing Spinning Crane Kick will cause the energy to detonate in a Chi Explosion, dealing 337342s1 damage to all enemies within 337342A1 yards. The damage is increased by 337571m1 for each stack of Chi Energy.
  SpellInfo(chi_energy duration=45 max_stacks=30 gcd=0 offgcd=1)
Define(chi_wave 115098)
# A wave of Chi energy flows through friends and foes, dealing 132467s1 Nature damage or 132463s1 healing. Bounces up to s1 times to targets within 132466a2 yards.
  SpellInfo(chi_wave cd=15)
  SpellRequire(chi_wave unusable set=1 enabled=(not hastalent(chi_wave_talent)))
Define(crackling_jade_lightning 117952)
# Channel Jade lightning, causing o1 Nature damage over 4 seconds to the target?a154436[, generating 1 Chi each time it deals damage,][] and sometimes knocking back melee attackers.
  SpellInfo(crackling_jade_lightning energy=20 duration=4 channel=4 tick=1)
  # Taking w1 damage every t1 sec.
  SpellAddTargetDebuff(crackling_jade_lightning crackling_jade_lightning add=1)
Define(dampen_harm 122278)
# Reduces all damage you take by m2 to m3 for 10 seconds, with larger attacks being reduced by more.
  SpellInfo(dampen_harm cd=120 duration=10 gcd=0 offgcd=1)
  SpellRequire(dampen_harm unusable set=1 enabled=(not hastalent(dampen_harm_talent)))
  # Damage taken reduced by m2 to m3 for d, with larger attacks being reduced by more.
  SpellAddBuff(dampen_harm dampen_harm add=1)
Define(dance_of_chiji_buff 325202)
# Spending Chi has a chance to make your next Spinning Crane Kick free and deal s1 additional damage.
  SpellInfo(dance_of_chiji_buff duration=15 gcd=0 offgcd=1)
Define(dance_of_chiji_windwalker 325201)
# Spending Chi has a chance to make your next Spinning Crane Kick free and deal an additional s1 damage.
  SpellInfo(dance_of_chiji_windwalker gcd=0 offgcd=1 unusable=1)
  SpellRequire(dance_of_chiji_windwalker unusable set=1 enabled=(not hastalent(dance_of_chiji_talent)))
  # Your next Spinning Crane Kick is free and deals w1 additional damage.
  SpellAddBuff(dance_of_chiji_windwalker dance_of_chiji_buff add=1)
Define(diffuse_magic 122783)
# Reduces magic damage you take by m1 for 6 seconds, and transfers all currently active harmful magical effects on you back to their original caster if possible.
  SpellInfo(diffuse_magic cd=90 duration=6 gcd=0 offgcd=1)
  SpellRequire(diffuse_magic unusable set=1 enabled=(not hastalent(diffuse_magic_talent)))
  # Spell damage taken reduced by m1.
  SpellAddBuff(diffuse_magic diffuse_magic add=1)
Define(elusive_brawler 195630)
# Each time you are hit by a melee attack, or hit with Blackout Kick, you gain stacking (100 of Spell Power).1 increased Dodge chance until your next successful Dodge.rnrnAlso increases your attack power by (100 of Spell Power).1.
  SpellInfo(elusive_brawler duration=10 max_stacks=100 gcd=0 offgcd=1)
Define(energizing_elixir 115288)
# Chug an Energizing Elixir, granting s2 Chi and generating s1/5*5 Energy over 5 seconds.
  SpellInfo(energizing_elixir cd=60 duration=5 max_stacks=3 gcd=0 offgcd=1 chi=-2)
  SpellRequire(energizing_elixir unusable set=1 enabled=(not hastalent(energizing_elixir_talent)))
  # Generating w1/5 extra Energy per sec.
  SpellAddBuff(energizing_elixir energizing_elixir add=1)
Define(expel_harm 322101)
# Expel negative chi from your body, healing for (120 of Spell Power) and dealing s2 of the amount healed as Nature damage to an enemy within 115129A1 yards.?s322102[rnrnDraws in the positive chi of all your Healing Spheres to increase the healing of Expel Harm.][]?s325214[rnrnMay be cast during Soothing Mist, and will additionally heal the Soothing Mist target.][]?s322106[rnrn|cFFFFFFFFGenerates s3 Chi.]?s342928[rnrn|cFFFFFFFFGenerates s3+342928s2 Chi.][]
  SpellInfo(expel_harm energy=15 cd=15 gcd=1 chi=0)
Define(faeline_stomp 327104)
# Strike the ground fiercely to expose a faeline for 30 seconds, dealing 345727s1 Nature damage to up to 5 enemies, and restores (91 of Spell Power) health to up to 5 allies within 345727a1 yds caught in the faeline. ?a137024[Up to 5 allies]?a137025[Up to 5 enemies][Stagger is s3 more effective for 8 seconds against enemies] caught in the faeline?a137023[]?a137024[ are healed with an Essence Font bolt][ suffer an additional 327264s1 damage].rnrnYour abilities have a s2 chance of resetting the cooldown of Faeline Stomp while fighting on a faeline.
  SpellInfo(faeline_stomp cd=30 duration=30 gcd=1)
  # Fighting on a faeline has a s2 chance of resetting the cooldown of Faeline Stomp.
  SpellAddBuff(faeline_stomp faeline_stomp add=1)
Define(fallen_order 326860)
# Opens a mystic portal for 24 seconds. Every t1*3 sec, it summons a spirit of your order's fallen Ox, Crane, or Tiger adepts for s4 sec.rnrnFallen ?C1[Ox]?C2[Crane][Tiger] adepts assist for an additional s3 sec, and will also ?C1[attack your enemies with Breath of Fire]?C2[heal with Enveloping Mist][assault with Fists of Fury].
  SpellInfo(fallen_order cd=180 duration=24 gcd=1 tick=1)
  # Summoning Ox, Crane, and Tiger adepts through the mirror.
  SpellAddBuff(fallen_order fallen_order add=1)
Define(fireblood 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. ?s195710[This effect shares a 30 sec cooldown with other similar effects.][]
  SpellInfo(fireblood cd=120 gcd=0 offgcd=1)
Define(fist_of_the_white_tiger 261947)
# Strike with the technique of the White Tiger, dealing s1+261977s1 Physical damage.rnrn|cFFFFFFFFGenerates 261978s1 Chi.
  SpellInfo(fist_of_the_white_tiger energy=40 cd=30 gcd=1)
  SpellRequire(fist_of_the_white_tiger unusable set=1 enabled=(not hastalent(fist_of_the_white_tiger_talent)))
Define(fists_of_fury 113656)
# Pummels all targets in front of you, dealing 5*s5 damage over 4 seconds to your primary target and 5*s5*s6/100 damage over 4 seconds to up to s1 other targets. Can be channeled while moving.
  SpellInfo(fists_of_fury chi=3 cd=24 duration=4 channel=4 gcd=1 tick=0.166)
Define(flying_serpent_kick 101545)
# Soar forward through the air at high speed for 1.5 seconds.rn rnIf used again while active, you will land, dealing 123586m1 damage to all enemies within 123586A1 yards and reducing movement speed by 123586m2 for 4 seconds.
  SpellInfo(flying_serpent_kick cd=25 duration=1.5 gcd=1)
Define(fortifying_brew 115203)
# Turns your skin to stone for 15 seconds, increasing your current and maximum health by <health>?s322960[, increasing the effectiveness of Stagger by s1,][] and reducing all damage you take by <damage>.
  SpellInfo(fortifying_brew cd=360 gcd=0 offgcd=1)
  SpellRequire(fortifying_brew replaced_by set=fortifying_brew_mistweaver enabled=(specialization("mistweaver") or specialization("windwalker")))
  SpellRequire(fortifying_brew replaced_by set=fortifying_brew_mistweaver enabled=(specialization("mistweaver") or specialization("windwalker")))
Define(fortifying_brew_buff 120954)
# Turns your skin to stone for 15 seconds, increasing your current and maximum health by <health>?s322960[, increasing the effectiveness of Stagger by s1,][] and reducing all damage you take by <damage>.
  SpellInfo(fortifying_brew_buff duration=15 gcd=0 offgcd=1)
  # Health increased by <health>, damage taken reduced by <damage>, and effectiveness of Stagger increased by 115203s1.
  SpellAddBuff(fortifying_brew_buff fortifying_brew_buff add=1)
Define(fortifying_brew_mistweaver 243435)
# Turns your skin to stone, increasing your current and maximum health by s1 and reducing damage taken by s2 for 15 seconds.
  SpellInfo(fortifying_brew_mistweaver cd=420 duration=15 gcd=0 offgcd=1)
  # Maximum health increased by w1.rnDamage taken reduced by w2.?w4>1[rnAbsorbs w4 damage.][]
  SpellAddBuff(fortifying_brew_mistweaver fortifying_brew_mistweaver add=1)
Define(gift_of_the_ox 124503)
# When you take damage, you have a chance to summon a Healing Sphere visible only to you. Moving through this Healing Sphere heals you for 124507s1.
  SpellInfo(gift_of_the_ox duration=30 gcd=0 offgcd=1)
Define(invoke_niuzao_the_black_ox 132578)
# Summons an effigy of Niuzao, the Black Ox for 25 seconds. Niuzao attacks your primary target, and frequently Stomps, damaging all nearby enemies?s322740[ for 227291s1 plus 322740s1 of Stagger damage you have recently purified.][.]rnrnWhile active, s2 of damage delayed by Stagger is instead Staggered by Niuzao.
  SpellInfo(invoke_niuzao_the_black_ox cd=180 duration=25 gcd=1)
  # Niuzao is staggering s2 of the Monk's Stagger damage.
  SpellAddBuff(invoke_niuzao_the_black_ox invoke_niuzao_the_black_ox add=1)
Define(invoke_xuen_the_white_tiger 123904)
# Summons an effigy of Xuen, the White Tiger for 24 seconds. Xuen attacks your primary target, and strikes 3 enemies within 123996A1 yards every 123999t1 sec with Tiger Lightning for 123996s1 Nature damage.?s323999[rnrnEvery 323999s1 sec, Xuen strikes your enemies with Empowered Tiger Lightning dealing 323999s2 of the damage you have dealt to those targets in the last 323999s1 sec.][]
  SpellInfo(invoke_xuen_the_white_tiger cd=120 duration=24 gcd=1 tick=4)
Define(keg_smash 121253)
# Smash a keg of brew on the target, dealing s2 damage to all enemies within A2 yds and reducing their movement speed by m3 for 15 seconds. Deals reduced damage beyond s7 targets.rnrnGrants Shuffle for s6 sec and reduces the remaining cooldown on your Brews by s4 sec.
  SpellInfo(keg_smash energy=40 cd=8 duration=15 gcd=1)
  # ?w3!=0[Movement speed reduced by w3.rn][]Drenched in brew, vulnerable to Breath of Fire.
  SpellAddTargetDebuff(keg_smash keg_smash add=1)
Define(leg_sweep 119381)
# Knocks down all enemies within A1 yards, stunning them for 3 seconds.
  SpellInfo(leg_sweep cd=60 duration=3)
  # Stunned.
  SpellAddTargetDebuff(leg_sweep leg_sweep add=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)
Define(paralysis 115078)
# Incapacitates the target for 60 seconds. Limit 1. Damage will cancel the effect.
  SpellInfo(paralysis energy=20 cd=45 duration=60)
  # Incapacitated.
  SpellAddTargetDebuff(paralysis paralysis add=1)
Define(phantom_fire 321937)
# Deal s1 Shadow Fire damage to your current target.
  SpellInfo(phantom_fire gcd=0 offgcd=1)
Define(purifying_brew 119582)
# Clears s1 of your damage delayed with Stagger.?s322510[rnrnIncreases the absorption of your next Celestial Brew by up to 322510s1, based on your current level of Stagger][]
  SpellInfo(purifying_brew cd=20 gcd=0 offgcd=1)
Define(quaking_palm 107079)
# Strikes the target with lightning speed, incapacitating them for 4 seconds, and turns off your attack.
  SpellInfo(quaking_palm cd=120 duration=4 gcd=1)
  # Incapacitated.
  SpellAddTargetDebuff(quaking_palm quaking_palm add=1)
Define(rising_sun_kick 107428)
# Kick upwards, dealing ?s137025[185099s1*<CAP>/AP][185099s1] Physical damage?s128595[, and reducing the effectiveness of healing on the target for 10 seconds][].
  SpellInfo(rising_sun_kick chi=2 cd=10)
Define(rushing_jade_wind 116847)
# Summons a whirling tornado around you, causing (1+6 seconds/t1)*148187s1 damage over 6 seconds to up to s1 enemies within 107270A1 yards.
  SpellInfo(rushing_jade_wind chi=1 cd=6 duration=6 tick=0.75)
  SpellRequire(rushing_jade_wind unusable set=1 enabled=(not {hastalent(rushing_jade_wind_talent) or hastalent(rushing_jade_wind_talent_windwalker)}))
  # Dealing physical damage to nearby enemies every 116847t1 sec.
  SpellAddBuff(rushing_jade_wind rushing_jade_wind add=1)
Define(serenity 152173)
# Enter an elevated state of mental and physical serenity for ?s115069[s1 sec][12 seconds]. While in this state, you deal s2 increased damage and healing, and all Chi consumers are free and cool down s4 more quickly.
  SpellInfo(serenity cd=90 duration=12 gcd=0 offgcd=1)
  SpellRequire(serenity unusable set=1 enabled=(not hastalent(serenity_talent)))
  # Damage and healing increased by w2.rnAll Chi consumers are free and cool down w4 more quickly.
  SpellAddBuff(serenity serenity add=1)
Define(spear_hand_strike 116705)
# Jabs the target in the throat, interrupting spellcasting and preventing any spell from that school of magic from being cast for 4 seconds.
  SpellInfo(spear_hand_strike cd=15 duration=4 gcd=0 offgcd=1 interrupt=1)
Define(spinning_crane_kick 101546)
# Spin while kicking in the air, dealing ?s137025[4*107270s1*<CAP>/AP][4*107270s1] Physical damage over 1.5 seconds to up to s1 enemies within 107270A1 yds.?c3[rnrnSpinning Crane Kick's damage is increased by 220358s1 for each unique target you've struck in the last 15 seconds with Tiger Palm, Blackout Kick, or Rising Sun Kick.][]
  SpellInfo(spinning_crane_kick chi=2 energy=40 duration=1.5 channel=1.5 tick=0.5)
  SpellRequire(spinning_crane_kick replaced_by set=spinning_crane_kick_brewmaster enabled=(specialization("brewmaster")))
Define(spinning_crane_kick_brewmaster 322729)
# Spin while kicking in the air, dealing ?s137025[4*107270s1*<CAP>/AP][4*107270s1] Physical damage over 1.5 seconds to enemies within 107270A1 yds.?c3[rnrnSpinning Crane Kick's damage is increased by 220358s1 for each unique target you've struck in the last 15 seconds with Tiger Palm, Blackout Kick, or Rising Sun Kick.][]
  SpellInfo(spinning_crane_kick_brewmaster energy=25 duration=1.5 channel=1.5 tick=0.5)
  # Attacking all nearby enemies for Physical damage every 101546t1 sec.rnrnMovement speed reduced by s2.
  SpellAddBuff(spinning_crane_kick_brewmaster spinning_crane_kick_buff add=1)
  # Attacking all nearby enemies for Physical damage every 101546t1 sec.
  SpellAddBuff(spinning_crane_kick_brewmaster spinning_crane_kick_brewmaster add=1)
Define(spinning_crane_kick_buff 107270)
# Spin while kicking in the air, dealing ?s137025[4*107270s1*<CAP>/AP][4*107270s1] Physical damage over 1.5 seconds to up to s1 enemies within 107270A1 yds.?c3[rnrnSpinning Crane Kick's damage is increased by 220358s1 for each unique target you've struck in the last 15 seconds with Tiger Palm, Blackout Kick, or Rising Sun Kick.][]
  SpellInfo(spinning_crane_kick_buff gcd=0 offgcd=1)
Define(storm_earth_and_fire 137639)
# Split into 3 elemental spirits for 15 seconds, each spirit dealing 100+m1 of normal damage and healing.rnrnYou directly control the Storm spirit, while Earth and Fire spirits mimic your attacks on nearby enemies.rnrnWhile active, casting Storm, Earth, and Fire again will cause the spirits to fixate on your target.
  SpellInfo(storm_earth_and_fire cd=90 duration=15 max_stacks=2 gcd=0 offgcd=1)
  SpellRequire(storm_earth_and_fire replaced_by set=serenity enabled=(hastalent(serenity_talent)))
  # Elemental spirits summoned, mirroring all of the Monk's attacks.rnThe Monk and spirits each do 100+m1 of normal damage and healing.
  SpellAddBuff(storm_earth_and_fire storm_earth_and_fire add=1)
Define(storm_earth_and_fire_fixate 221771)
# Direct your Earth and Fire spirits to focus their attacks only on the target.
  SpellInfo(storm_earth_and_fire_fixate cd=1 gcd=0 offgcd=1)
  # Elemental spirits summoned, mirroring all of the Monk's attacks.rnThe Monk and spirits each do 100+m1 of normal damage and healing.
  SpellAddBuff(storm_earth_and_fire_fixate storm_earth_and_fire_fixate add=1)
Define(the_emperors_capacitor_buff 235054)
# Chi spenders increase the damage of your next Crackling Jade Lightning by 235054s1 and reduce its cost by 235054s2, stacking up to 235054u times.
  SpellInfo(the_emperors_capacitor_buff max_stacks=20 gcd=0 offgcd=1)
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
  SpellAddBuff(touch_of_karma touch_of_karma add=1)
  # Damage dealt to the Monk is redirected to you as Nature damage over 124280d.
  SpellAddTargetDebuff(touch_of_karma touch_of_karma add=1)
Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp add=1)
Define(weapons_of_order 311123)
# For the next 30 seconds, your Mastery is increased by ?c1[117906bc1*s1]?c2[117907bc1*s1][115636bc1*s1.1]. Additionally, ?a137025[Rising Sun Kick reduces Chi costs by 311054s1 for 5 seconds, and Blackout Kick reduces the cooldown of affected abilities by an additional s8/1000 sec.][]?a137023 [Keg Smash cooldown is reset instantly and enemies hit by Keg Smash take 312106s1 increased damage from you for 10 seconds, stacking up to 312106u times.][]?a137024[Essence Font cooldown is reset instantly and heals up to 311123s2 nearby allies for (40 of Spell Power) health on channel start and end.][]
  SpellInfo(weapons_of_order gcd=0 offgcd=1)
Define(weapons_of_order_buff 310454)
# For the next 30 seconds, your Mastery is increased by ?c1[117906bc1*s1]?c2[117907bc1*s1][115636bc1*s1.1]. Additionally, ?a137025[Rising Sun Kick reduces Chi costs by 311054s1 for 5 seconds, and Blackout Kick reduces the cooldown of affected abilities by an additional s8/1000 sec.][]?a137023 [Keg Smash cooldown is reset instantly and enemies hit by Keg Smash take 312106s1 increased damage from you for 10 seconds, stacking up to 312106u times.][]?a137024[Essence Font cooldown is reset instantly and heals up to 311123s2 nearby allies for (40 of Spell Power) health on channel start and end.][]
  SpellInfo(weapons_of_order_buff cd=120 duration=30 max_stacks=1)
  # Increases your Mastery by ?c1[117906bc1*w1]?c2[117907bc1*w1][115636bc1*w1]?a137025[, Rising Sun Kick reduces Chi costs by 311054s1 for 311054d, and Blackout Kick reduces the cooldown of affected abilities by an additional s8/1000 sec.]?a137023 [ and your Keg Smash increases the damage you deal to those enemies by 312106s1, up to 312106s1*312106u for 312106d.]?a137024[ and your Essence Font heals nearby allies for 311123s1 health on channel start and end.][ and your abilities are enhanced.]
  SpellAddBuff(weapons_of_order_buff weapons_of_order_buff add=1)
Define(weapons_of_order_ww 311054)
# For the next 30 seconds, your Mastery is increased by ?c1[117906bc1*s1]?c2[117907bc1*s1][115636bc1*s1.1]. Additionally, ?a137025[Rising Sun Kick reduces Chi costs by 311054s1 for 5 seconds, and Blackout Kick reduces the cooldown of affected abilities by an additional s8/1000 sec.][]?a137023 [Keg Smash cooldown is reset instantly and enemies hit by Keg Smash take 312106s1 increased damage from you for 10 seconds, stacking up to 312106u times.][]?a137024[Essence Font cooldown is reset instantly and heals up to 311123s2 nearby allies for (40 of Spell Power) health on channel start and end.][]
  SpellInfo(weapons_of_order_ww duration=5 gcd=0 offgcd=1)
  # Reduces the Chi Cost of your abilities by s1.
  SpellAddBuff(weapons_of_order_ww weapons_of_order_ww add=1)
Define(whirling_dragon_punch 152175)
# Performs a devastating whirling upward strike, dealing 3*158221s1 damage to all nearby enemies. Only usable while both Fists of Fury and Rising Sun Kick are on cooldown.
  SpellInfo(whirling_dragon_punch cd=24 duration=1 gcd=1 tick=0.25)
  SpellRequire(whirling_dragon_punch unusable set=1 enabled=(not hastalent(whirling_dragon_punch_talent)))
Define(black_ox_brew_talent 19992)
# Chug some Black Ox Brew, which instantly refills your Energy, Purifying Brew charges, and resets the cooldown of Celestial Brew.
Define(blackout_combo_talent 22108)
# Blackout Kick also empowers your next ability:rnrnTiger Palm: Damage increased by s1.rnBreath of Fire: Cooldown reduced by s2 sec.rnKeg Smash: Reduces the remaining cooldown on your Brews by s3 additional sec.rnCelestial Brew: Pauses Stagger damage for s4 sec.
Define(chi_burst_talent 20185)
# Hurls a torrent of Chi energy up to 40 yds forward, dealing 148135s1 Nature damage to all enemies, and 130654s1 healing to the Monk and all allies in its path.?c1[rnrnCasting Chi Burst does not prevent avoiding attacks.][]?c3[rnrnChi Burst generates 1 Chi per enemy target damaged, up to a maximum of s3.][]
Define(chi_wave_talent 19820)
# A wave of Chi energy flows through friends and foes, dealing 132467s1 Nature damage or 132463s1 healing. Bounces up to s1 times to targets within 132466a2 yards.
Define(dampen_harm_talent 20175)
# Reduces all damage you take by m2 to m3 for 10 seconds, with larger attacks being reduced by more.
Define(dance_of_chiji_talent 22102)
# Spending Chi has a chance to make your next Spinning Crane Kick free and deal an additional s1 damage.
Define(diffuse_magic_talent 20173)
# Reduces magic damage you take by m1 for 6 seconds, and transfers all currently active harmful magical effects on you back to their original caster if possible.
Define(energizing_elixir_talent 22096)
# Chug an Energizing Elixir, granting s2 Chi and generating s1/5*5 Energy over 5 seconds.
Define(fist_of_the_white_tiger_talent 19771)
# Strike with the technique of the White Tiger, dealing s1+261977s1 Physical damage.rnrn|cFFFFFFFFGenerates 261978s1 Chi.
Define(hit_combo_talent 22093)
# Each successive attack that triggers Combo Strikes in a row grants 196741s1 increased damage, stacking up to 196741u times.
Define(rushing_jade_wind_talent_windwalker 23122)
# Summons a whirling tornado around you, causing (1+6 seconds/t1)*148187s1 damage over 6 seconds to up to s1 enemies within 107270A1 yards.
Define(rushing_jade_wind_talent 20184)
# Summons a whirling tornado around you, causing (1+6 seconds/t1)*148187s1 damage over 6 seconds to up to s1 enemies within 107270A1 yards.
Define(serenity_talent 21191)
# Enter an elevated state of mental and physical serenity for ?s115069[s1 sec][12 seconds]. While in this state, you deal s2 increased damage and healing, and all Chi consumers are free and cool down s4 more quickly.
Define(spitfire_talent 22097)
# Tiger Palm has a h chance to reset the cooldown of Breath of Fire.
Define(whirling_dragon_punch_talent 22105)
# Performs a devastating whirling upward strike, dealing 3*158221s1 damage to all nearby enemies. Only usable while both Fists of Fury and Rising Sun Kick are on cooldown.
Define(potion_of_spectral_agility_item 171270)
    ItemInfo(potion_of_spectral_agility_item cd=1 shared_cd="item_cd_4" proc=307159)
Define(charred_passions_runeforge 7076)
Define(coordinated_offensive_conduit 22)
    `;
    // END
    code += `
Define(detox 218164)
    SpellInfo(detox cd=8)
Define(healing_elixir 122281)
    SpellInfo(healing_elixir charge_cd=30 gcd=0 offgcd=1)
#rising_sun_kick
    SpellRequire(rising_sun_kick chi set=0 enabled=(not specialization(windwalker)))
    SpellRequire(rushing_jade_wind chi set=0 enabled=(not specialization(windwalker)))
#storm_earth_and_fire
    SpellRequire(storm_earth_and_fire unusable set=1 enabled=(buffpresent(storm_earth_and_fire)))
#touch_of_death
    SpellInfo(touch_of_death unusable=1)
    SpellRequire(touch_of_death unusable set=0 enabled=(target.Health() < player.Health() or (Level() >= 44 and target.HealthPercent() < 15)))
#whirling_dragon_punch
    SpellRequire(whirling_dragon_punch unusable set=1 enabled=(not spellcooldown(fists_of_fury) > 0 or not spellcooldown(rising_sun_kick) > 0))

## Stagger
Define(stagger 115069)
Define(heavy_stagger_debuff 124273)
	SpellInfo(heavy_stagger_debuff duration=10 tick=1)
	SpellRequire(heavy_stagger_debuff duration add=3 enabled=(talent(bob_and_weave_talent)))
Define(light_stagger_debuff 124275)
	SpellInfo(light_stagger_debuff duration=10 tick=1)
	SpellRequire(light_stagger_debuff duration add=3 enabled=(talent(bob_and_weave_talent)))
Define(moderate_stagger_debuff 124274)
	SpellInfo(moderate_stagger_debuff duration=10 tick=1)
	SpellRequire(moderate_stagger_debuff duration add=3 enabled=(talent(bob_and_weave_talent)))
SpellList(any_stagger_debuff light_stagger_debuff moderate_stagger_debuff heavy_stagger_debuff)
SpellRequire(purifying_brew unusable set=1 enabled=(not debuffpresent(any_stagger_debuff)))

Define(bob_and_weave_talent 13)
    `;
    OvaleScripts.RegisterScript("MONK", undefined, name, desc, code, "include");
}
