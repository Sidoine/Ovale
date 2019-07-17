local __exports = LibStub:NewLibrary("ovale/scripts/ovale_deathknight_spells", 80201)
if not __exports then return end
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
__exports.register = function()
    local name = "ovale_deathknight_spells"
    local desc = "[8.2] Ovale: Death Knight spells"
    local code = [[Define(apocalypse 275699)
# Bring doom upon the enemy, dealing sw1 Shadow damage and bursting up to s2 Festering Wounds on the target.rnrnSummons an Army of the Dead ghoul for 15 seconds for each burst Festering Wound.
  SpellInfo(apocalypse cd=90)
Define(army_of_the_dead 42650)
# Summons a legion of ghouls who swarms your enemies, fighting anything they can for 30 seconds.
  SpellInfo(army_of_the_dead runes=3 runicpower=-30 cd=480 duration=4 tick=0.5)
  # Summoning ghouls.
  SpellAddBuff(army_of_the_dead army_of_the_dead=1)
Define(asphyxiate 108194)
# Lifts the enemy target off the ground, crushing their throat with dark energy and stunning them for 4 seconds.
  SpellInfo(asphyxiate cd=45 duration=4 talent=asphyxiate_talent_unholy)
  # Stunned.
  SpellAddTargetDebuff(asphyxiate asphyxiate=1)
Define(berserking 26297)
# Increases your haste by s1 for 12 seconds.
  SpellInfo(berserking cd=180 duration=12 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking=1)
Define(blinding_sleet 207167)
# Targets in a cone in front of you are blinded, causing them to wander disoriented for 5 seconds. Damage may cancel the effect.
  SpellInfo(blinding_sleet cd=60 duration=5 talent=blinding_sleet_talent)
  # Disoriented.
  SpellAddTargetDebuff(blinding_sleet blinding_sleet=1)
Define(blood_boil 50842)
# Deals s1 Shadow damage?s212744[ to all enemies within A1 yds.][ and infects all enemies within A1 yds with Blood Plague.rnrn|Tinterfaceiconsspell_deathknight_bloodplague.blp:24|t |cFFFFFFFFBlood Plague|rrnA shadowy disease that drains o1 health from the target over 24 seconds.  ]
  SpellInfo(blood_boil cd=7.5)
Define(blood_of_the_enemy 297108)
# The Heart of Azeroth erupts violently, dealing s1 Shadow damage to enemies within A1 yds. You gain m2 critical strike chance against the targets for 10 seconds?a297122[, and increases your critical hit damage by 297126m for 5 seconds][].
  SpellInfo(blood_of_the_enemy cd=120 duration=10 channel=10)
  # You have a w2 increased chance to be Critically Hit by the caster.
  SpellAddTargetDebuff(blood_of_the_enemy blood_of_the_enemy=1)
Define(blooddrinker 206931)
# Drains o1 health from the target over 3 seconds.rnrnYou can move, parry, dodge, and use defensive abilities while channeling this ability.
  SpellInfo(blooddrinker runes=1 runicpower=-10 cd=30 duration=3 channel=3 tick=1 talent=blooddrinker_talent)
  # Draining s1 health from the target every t1 sec.
  SpellAddTargetDebuff(blooddrinker blooddrinker=1)
Define(bonestorm 194844)
# A whirl of bone and gore batters nearby enemies, dealing 196528s1 Shadow damage every t3 sec, and healing you for 196545s1 of your maximum health every time it deals damage (up to s1*s4). Lasts t3 sec per s3 Runic Power spent.
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
Define(clawing_shadows 207311)
# Deals s2 Shadow damage and causes 1 Festering Wound to burst.
  SpellInfo(clawing_shadows runes=1 runicpower=-10 talent=clawing_shadows_talent)
Define(cold_heart_buff 281209)
# Every t1 sec, gain a stack of Cold Heart, causing your next Chains of Ice to deal 281210s1 Frost damage. Stacks up to 281209u times.
  SpellInfo(cold_heart_buff max_stacks=20 gcd=0 offgcd=1)
  # Your next Chains of Ice will deal 281210s1 Frost damage.
  SpellAddBuff(cold_heart_buff cold_heart_buff=1)
Define(consumption 274156)
# Strikes all enemies in front of you with a hungering attack that deals sw1 Physical damage and heals you for e1*100 of that damage.
  SpellInfo(consumption cd=45 talent=consumption_talent)

Define(dancing_rune_weapon 49028)
# Summons a rune weapon for s4 sec that mirrors your melee attacks and bolsters your defenses.rnrnWhile active, you gain 81256s1 parry chance.
  SpellInfo(dancing_rune_weapon cd=120 duration=13)

  SpellAddTargetDebuff(dancing_rune_weapon dancing_rune_weapon=1)
Define(dark_transformation 63560)
# Transform your ?s207313[abomination]?s58640[geist][ghoul] into a powerful undead monstrosity for 15 seconds. The ?s207313[abomination]?s58640[geist][ghoul]'s abilities are empowered and take on new functions while the transformation is active.
  SpellInfo(dark_transformation cd=60 duration=15 channel=15)
  # ?w2>0[Transformed into an undead monstrosity.][Gassy.]rnDamage dealt increased by w1.
  SpellAddBuff(dark_transformation dark_transformation=1)
Define(death_and_decay 43265)
# Corrupts the targeted ground, causing 52212m1*11 Shadow damage over 10 seconds to targets within the area.rnrnWhile you remain within the area, your ?s223829[Necrotic Strike and ][]?c1[Heart Strike will hit up to 188290m3 additional targets.]?s207311[Clawing Shadows will hit all enemies near the target.][Scourge Strike will hit all enemies near the target.]
  SpellInfo(death_and_decay runes=1 runicpower=-10 cd=30 duration=10 tick=1)
  SpellAddBuff(death_and_decay death_and_decay=1)
Define(death_coil 47541)
# Fires a blast of unholy energy at the target, causing 47632s1 Shadow damage to an enemy.?s137007[rnrnReduces the cooldown of Dark Transformation by s2 sec][].
  SpellInfo(death_coil runicpower=40)
Define(death_strike 49998)
# Focuses dark power into a strike?s137006[ with both weapons, that deals a total of s1+66188s1][ that deals s1] Physical damage and heals you for s2 of all damage taken in the last s4 sec, minimum s3 of maximum health.
# Rank 2: Death Strike's cost is reduced by s3/-10, and its healing is increased by s1.
  SpellInfo(death_strike runicpower=45)
Define(defile 152280)
# Defile the targeted ground, dealing (156000s1*(10 seconds+1)/t3) Shadow damage to all enemies over 10 seconds.rnrnWhile you remain within your Defile, your ?s207311[Clawing Shadows][Scourge Strike] will hit all enemies near the target.rnrnIf any enemies are standing in the Defile, it grows in size every sec.
  SpellInfo(defile runes=1 runicpower=-10 cd=20 duration=10 tick=1 talent=defile_talent)
  SpellAddBuff(defile defile=1)
Define(empower_rune_weapon 47568)
# Empower your rune weapon, gaining s3 Haste and generating s1 LRune:Runes; and m2/10 Runic Power instantly and every t1 sec for 20 seconds.
  SpellInfo(empower_rune_weapon cd=120 duration=20 tick=5)
  # Haste increased by s3.rnGenerating s1 LRune:Runes; and m2/10 Runic Power every t1 sec.
  SpellAddBuff(empower_rune_weapon empower_rune_weapon=1)
Define(epidemic 207317)
# Causes each of your Virulent Plagues to flare up, dealing 212739s1 Shadow damage to the infected enemy, and an additional 215969s2 Shadow damage to all other enemies near them.
  SpellInfo(epidemic runicpower=30 channel=0 talent=epidemic_talent)
Define(festering_strike 85948)
# Strikes for s1 Physical damage and infects the target with m2-M2 Festering Wounds.rnrn|Tinterfaceiconsspell_yorsahj_bloodboil_purpleoil.blp:24|t |cFFFFFFFFFestering Wound|rrnA pustulent lesion that will burst on death or when damaged by Scourge Strike, dealing 194311s1 Shadow damage and generating 195757s1 Runic Power.
  SpellInfo(festering_strike runes=2 runicpower=-20)
Define(frost_strike 49143)
# Chill your weapons with icy power, and quickly strike the enemy with both weapons, dealing a total of 222026s1+66196s1 Frost damage.
  SpellInfo(frost_strike runicpower=25)

Define(frostscythe 207230)
# A sweeping attack that strikes all enemies in front of you for s2 Frost damage. This attack benefits from Killing Machine. Critical strikes with Frostscythe deal s3 times normal damage.
  SpellInfo(frostscythe runes=1 runicpower=-10 talent=frostscythe_talent)
Define(frostwyrms_fury 279302)
# Summons a frostwyrm who breathes on all enemies within s1 yd in front of you, dealing 279303s1 Frost damage and slowing movement speed by (25 of Spell Power) for 10 seconds.
  SpellInfo(frostwyrms_fury cd=180 duration=10 talent=frostwyrms_fury_talent)
Define(frozen_pulse_buff 195750)
# While you have fewer than m2 full LRune:Runes;, your auto attacks radiate intense cold, inflicting 195750s1 Frost damage on all nearby enemies.
  SpellInfo(frozen_pulse_buff gcd=0 offgcd=1)
Define(glacial_advance 194913)
# Summon glacial spikes from the ground that advance forward, each dealing 195975s1*<CAP>/AP Frost damage and applying Razorice to enemies near their eruption point.
  SpellInfo(glacial_advance runicpower=30 cd=6 talent=glacial_advance_talent)
Define(guardian_of_azeroth 295840)
# Call upon Azeroth to summon a Guardian of Azeroth for 30 seconds who impales your target with spikes of Azerite every 2 sec that deal 295834m1*(1+@versadmg) Fire damage.?a295841[ Every 303347t1 sec, the Guardian launches a volley of Azerite Spikes at its target, dealing 295841s1 Fire damage to all nearby enemies.][]?a295843[rnrnEach time the Guardian of Azeroth casts a spell, you gain 295855s1 Haste, stacking up to 295855u times. This effect ends when the Guardian of Azeroth despawns.][]rn
  SpellInfo(guardian_of_azeroth cd=180 duration=30)
  SpellAddBuff(guardian_of_azeroth guardian_of_azeroth=1)
Define(heart_strike 206930)
# Instantly strike the target and 1 other nearby enemy, causing s2 Physical damage, and reducing enemies' movement speed by s5 for 8 seconds.rnrn|cFFFFFFFFGenerates ?s221536[s3+221536s1][s3] bonus Runic Power?s221536[, plus 210738s1/10 Runic Power per additional enemy struck][].|r
  SpellInfo(heart_strike runes=1 runicpower=-15 duration=8)
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
# Blast the target with a frigid wind, dealing s1*<CAP>/AP ?s204088[Frost damage and applying Frost Fever to the target.][Frost damage to that foe, and 237680s1*<CAP>/AP Frost damage to all other enemies within 237680A1 yards, infecting all targets with Frost Fever.]rnrn|Tinterfaceiconsspell_deathknight_frostfever.blp:24|t |cFFFFFFFFFrost Fever|rrnA disease that deals o1*<CAP>/AP Frost damage over 24 seconds and has a chance to grant the Death Knight 195617m1/10 Runic Power each time it deals damage.
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
Define(marrowrend 195182)
# Smash the target, dealing s2 Physical damage and generating s3 charges of Bone Shield.rnrn|Tinterfaceiconsability_deathknight_boneshield.blp:24|t |cFFFFFFFFBone Shield|rrnSurrounds you with a barrier of whirling bones, increasing Armor by s1*STR/100, and your Haste by s4. Each melee attack against you consumes a charge. Lasts 30 seconds or until all charges are consumed.
  SpellInfo(marrowrend runes=2 runicpower=-20)
Define(mind_freeze 47528)
# Smash the target's mind with cold, interrupting spellcasting and preventing any spell in that school from being cast for 3 seconds.
  SpellInfo(mind_freeze cd=15 duration=3 gcd=0 offgcd=1 interrupt=1)
Define(obliterate 49020)
# A brutal attack with both weapons that deals a total of 222024s1+66198s1 Physical damage.
  SpellInfo(obliterate runes=2 runicpower=-20)

Define(outbreak 77575)
# Deals s1 Shadow damage and surrounds the target in a miasma for 6 seconds that infects nearby enemies with Virulent Plague.rnrn|Tinterfaceiconsability_creature_disease_02.blp:24|t |cFFFFFFFFVirulent Plague|rrnA disease that deals 7*s1 Shadow damage over 21 seconds. It erupts when the infected target dies, dealing 191685s1 Shadow damage divided among nearby enemies, and has a s2 chance to erupt each time it deals damage.
  SpellInfo(outbreak runes=1 runicpower=-10)
Define(pillar_of_frost 51271)
# The power of frost increases your Strength by s1 for 15 seconds.rnrnEach Rune spent while active increases your Strength by an additional s2.
  SpellInfo(pillar_of_frost cd=45 duration=15)
  # Strength increased by w1.
  SpellAddBuff(pillar_of_frost pillar_of_frost=1)
Define(purifying_blast 295337)
# Call down a purifying beam upon the target area, dealing 295293s3*(1+@versadmg)*s2 Fire damage over 6 seconds.?a295364[ Has a low chance to immediately annihilate any specimen deemed unworthy by MOTHER.][]?a295352[rnrnWhen an enemy dies within the beam, your damage is increased by 295354s1 for 8 seconds.][]rnrnAny Aberration struck by the beam is stunned for 3 seconds.
  SpellInfo(purifying_blast cd=60 duration=6)
Define(raise_dead 46584)
# Raises ?s207313[an abomination]?s58640[a geist][a ghoul] to fight by your side. You can have a maximum of one ?s207313[abomination]?s58640[geist][ghoul] at a time.
  SpellInfo(raise_dead cd=30)
  # A Risen Ally is in your service.
  SpellAddBuff(raise_dead raise_dead=1)
Define(remorseless_winter 196770)
# Drain the warmth of life from all nearby enemies within 196771A1 yards, dealing 9*196771s1*<CAP>/AP Frost damage over 8 seconds and reducing their movement speed by 211793s1.
  SpellInfo(remorseless_winter runes=1 runicpower=-10 cd=20 duration=8 tick=1)
  # Dealing 196771s1 Frost damage to enemies within 196771A1 yards each second.
  SpellAddBuff(remorseless_winter remorseless_winter=1)
Define(rime_buff 59052)
# Your next Howling Blast will consume no Runes, generate no Runic Power, and deal s2 additional damage.
  SpellInfo(rime_buff duration=15 max_stacks=1 gcd=0 offgcd=1)
  # Your next Howling Blast will consume no Runes, generate no Runic Power, and deals s2 additional damage.
  SpellAddBuff(rime_buff rime_buff=1)
Define(rune_strike 210764)
# Strike the target for s1 Physical damage.rnrnCooldown reduced by s2 sec for every Rune you spend.rnrn|cFFFFFFFFGenerates s2 Rune.|r
  SpellInfo(rune_strike cd=60 runes=-1 talent=rune_strike_talent)
Define(scourge_strike 55090)
# An unholy strike that deals s2 Physical damage and 70890sw2 Shadow damage, and causes 1 Festering Wound to burst.
  SpellInfo(scourge_strike runes=1 runicpower=-10)

Define(soul_reaper 130736)
# Rip out an enemy's soul, dealing <dmg> Shadow damage over 8 seconds.rnrnIf the enemy that yields experience or honor dies while afflicted by Soul Reaper, you gain 215711s1 Haste for 8 seconds.rnrn|cFFFFFFFFGenerates s2 lRune:Runes;.|r
  SpellInfo(soul_reaper cd=45 duration=8 runes=-2 tick=1 talent=soul_reaper_talent)
  # Suffering sw1 damage every t1 sec.
  SpellAddTargetDebuff(soul_reaper soul_reaper=1)
Define(sudden_doom_buff 81340)
# Your auto attacks have a chance to make your next Death Coil cost no Runic Power.
  SpellInfo(sudden_doom_buff duration=10 max_stacks=1 gcd=0 offgcd=1)
  # Your next Death Coil consumes no Runic Power.
  SpellAddBuff(sudden_doom_buff sudden_doom_buff=1)
Define(summon_gargoyle 49206)
# Summon a Gargoyle into the area to bombard the target for 30 seconds.rnrnThe Gargoyle gains 211947s1 increased damage for every s4 Runic Power you spend.
  SpellInfo(summon_gargoyle cd=180 duration=35 talent=summon_gargoyle_talent)

Define(tombstone 219809)
# Consume up to s5 Bone Shield charges. For each charge consumed, you gain s3 Runic Power and absorb damage equal to s4 of your maximum health for 8 seconds.
  SpellInfo(tombstone cd=60 duration=8 runicpower=0 talent=tombstone_talent)
  # Absorbing w1 damage.
  SpellAddBuff(tombstone tombstone=1)
Define(unholy_blight 115989)
# Surrounds yourself with a vile swarm of insects for 6 seconds, stinging all nearby enemies and infecting them with an unholy disease that deals 115994o1 damage over 14 seconds.
  SpellInfo(unholy_blight runes=1 runicpower=-10 cd=45 duration=6 tick=1 talent=unholy_blight_talent)
  # Surrounded by a vile swarm of insects, infecting enemies within 115994a1 yds with an unholy disease.
  SpellAddBuff(unholy_blight unholy_blight=1)
Define(unholy_frenzy 207289)
# Incites you into a killing frenzy for 12 seconds, increasing Haste by s1 and causing your auto attacks to infect the target with a Festering Wound.
  SpellInfo(unholy_frenzy cd=75 duration=12 talent=unholy_frenzy_talent)
  # Haste increased by s1.rnAuto attacks infect the target with a Festering Wound.
  SpellAddBuff(unholy_frenzy unholy_frenzy=1)
Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp=1)
Define(army_of_the_damned_talent 19) #22030
# ?s207317[Death Coil and Epidemic reduce][Death Coil reduces] the cooldown of Apocalypse by <cd1> sec and Army of the Dead by <cd2> sec.
Define(asphyxiate_talent_unholy 9) #22520
# Lifts the enemy target off the ground, crushing their throat with dark energy and stunning them for 4 seconds.
Define(blinding_sleet_talent 9) #22519
# Targets in a cone in front of you are blinded, causing them to wander disoriented for 5 seconds. Damage may cancel the effect.
Define(blooddrinker_talent 2) #19166
# Drains o1 health from the target over 3 seconds.rnrnYou can move, parry, dodge, and use defensive abilities while channeling this ability.
Define(bonestorm_talent 21) #21209
# A whirl of bone and gore batters nearby enemies, dealing 196528s1 Shadow damage every t3 sec, and healing you for 196545s1 of your maximum health every time it deals damage (up to s1*s4). Lasts t3 sec per s3 Runic Power spent.
Define(breath_of_sindragosa_talent 21) #22537
# Continuously deal 155166s2*<CAP>/AP Frost damage every t1 sec to enemies in a cone in front of you, until your Runic Power is exhausted. Deals reduced damage to secondary targets.rnrn|cFFFFFFFFGenerates 303753s1 lRune:Runes; at the start and end.|r
Define(bursting_sores_talent 4) #22027
# Bursting a Festering Wound deals s1 more damage, and deals 207267s1 Shadow damage to all nearby targets.
Define(clawing_shadows_talent 3) #22026
# Deals s2 Shadow damage and causes 1 Festering Wound to burst.
Define(cold_heart_talent 3) #22018
# Every t1 sec, gain a stack of Cold Heart, causing your next Chains of Ice to deal 281210s1 Frost damage. Stacks up to 281209u times.
Define(consumption_talent 6) #19220
# Strikes all enemies in front of you with a hungering attack that deals sw1 Physical damage and heals you for e1*100 of that damage.
Define(defile_talent 17) #22534
# Defile the targeted ground, dealing (156000s1*(10 seconds+1)/t3) Shadow damage to all enemies over 10 seconds.rnrnWhile you remain within your Defile, your ?s207311[Clawing Shadows][Scourge Strike] will hit all enemies near the target.rnrnIf any enemies are standing in the Defile, it grows in size every sec.
Define(epidemic_talent 18) #22536
# Causes each of your Virulent Plagues to flare up, dealing 212739s1 Shadow damage to the infected enemy, and an additional 215969s2 Shadow damage to all other enemies near them.
Define(frostscythe_talent 12) #22525
# A sweeping attack that strikes all enemies in front of you for s2 Frost damage. This attack benefits from Killing Machine. Critical strikes with Frostscythe deal s3 times normal damage.
Define(frostwyrms_fury_talent 18) #22535
# Summons a frostwyrm who breathes on all enemies within s1 yd in front of you, dealing 279303s1 Frost damage and slowing movement speed by (25 of Spell Power) for 10 seconds.
Define(frozen_pulse_talent 11) #22523
# While you have fewer than m2 full LRune:Runes;, your auto attacks radiate intense cold, inflicting 195750s1 Frost damage on all nearby enemies.
Define(gathering_storm_talent 16) #22531
# Each Rune spent during Remorseless Winter increases its damage by 211805s1, and extends its duration by m1/10.1 sec.
Define(glacial_advance_talent 17) #22533
# Summon glacial spikes from the ground that advance forward, each dealing 195975s1*<CAP>/AP Frost damage and applying Razorice to enemies near their eruption point.
Define(heartbreaker_talent 1) #19165
# Heart Strike generates 210738s1/10 additional Runic Power per target hit.
Define(horn_of_winter_talent 6) #22021
# Blow the Horn of Winter, gaining s1 LRune:Runes; and generating s2/10 Runic Power.
Define(obliteration_talent 20) #22109
# While Pillar of Frost is active, Frost Strike?s194913[, Glacial Advance,][] and Howling Blast always grant Killing Machine and have a s2 chance to generate a Rune.
Define(ossuary_talent 8) #22134
# While you have at least s1 Bone Shield charges, the cost of Death Strike is reduced by 219788m1/-10 Runic Power.rnrnAdditionally, your maximum Runic Power is increased by m2/10.
Define(pestilence_talent 16) #22532
# Death and Decay damage has a s1 chance to apply a Festering Wound to the enemy.
Define(rapid_decomposition_talent 4) #19218
# Your Blood Plague and Death and Decay deal damage s2 more often.
Define(rune_strike_talent 3) #19217
# Strike the target for s1 Physical damage.rnrnCooldown reduced by s2 sec for every Rune you spend.rnrn|cFFFFFFFFGenerates s2 Rune.|r
Define(runic_attenuation_talent 4) #22019
# Auto attacks have a chance to generate s1 Runic Power.
Define(soul_reaper_talent 12) #22526
# Rip out an enemy's soul, dealing <dmg> Shadow damage over 8 seconds.rnrnIf the enemy that yields experience or honor dies while afflicted by Soul Reaper, you gain 215711s1 Haste for 8 seconds.rnrn|cFFFFFFFFGenerates s2 lRune:Runes;.|r
Define(summon_gargoyle_talent 21) #22538
# Summon a Gargoyle into the area to bombard the target for 30 seconds.rnrnThe Gargoyle gains 211947s1 increased damage for every s4 Runic Power you spend.
Define(tombstone_talent 9) #22135
# Consume up to s5 Bone Shield charges. For each charge consumed, you gain s3 Runic Power and absorb damage equal to s4 of your maximum health for 8 seconds.
Define(unholy_blight_talent 6) #22029
# Surrounds yourself with a vile swarm of insects for 6 seconds, stinging all nearby enemies and infecting them with an unholy disease that deals 115994o1 damage over 14 seconds.
Define(unholy_frenzy_talent 20) #22110
# Incites you into a killing frenzy for 12 seconds, increasing Haste by s1 and causing your auto attacks to infect the target with a Festering Wound.
Define(dread_aspirants_medallion_item 162897)
Define(dread_gladiators_badge_item 161902)
Define(first_mates_spyglass_item 158163)
Define(jes_howler_item 159627)
Define(lurkers_insidious_gift_item 167866)
Define(sinister_gladiators_badge_item 165058)
Define(sinister_gladiators_medallion_item 165055)
Define(vial_of_animated_blood_item 159625)
Define(ramping_amplitude_gigavolt_engine_item 165580)
Define(frozen_tempest_trait 278487)
Define(icy_citadel_trait 272718)
Define(magus_of_the_dead_trait 288417)
    ]]
    code = code .. [[

ItemRequire(shifting_cosmic_sliver unusable 1=oncooldown,!icebound_fortitude,buff,!icebound_fortitude_buff)
	
# Death Knight spells and functions.

# Learned spells.
Define(antimagic_shell 48707)
	SpellInfo(antimagic_shell cd=60 gcd=0 offgcd=1)
	SpellInfo(antimagic_shell add_cd=-15 talent=antimagic_barrier_talent specialization=blood)
Define(antimagic_shell_buff 48707)
	SpellInfo(antimagic_shell_buff duration=5)
	SpellInfo(antimagic_shell_buff add_duration=5 talent=spell_eater_talent specialization=unholy)

	SpellInfo(asphyxiate cd=45 interrupt=1)
	SpellAddTargetDebuff(asphyxiate asphyxiate_debuff=1)
Define(asphyxiate_debuff 108194)
	SpellInfo(asphyxiate_debuff duration=4)
Define(asphyxiate_blood 221562)
	SpellInfo(asphyxiate_blood cd=45 interrupt=1)
	SpellAddTargetDebuff(asphyxiate_blood asphyxiate_blood_debuff=1)
Define(asphyxiate_blood_debuff 221562)
	SpellInfo(asphyxiate_debuff duration=5)
	SpellInfo(blood_boil cd=7.5 cd_haste=melee)
	SpellAddTargetDebuff(blood_boil blood_plague_debuff=1)
	SpellAddBuff(blood_boil hemostasis_buff=1 talent=hemostasis_talent)
Define(blood_plague_debuff 55078)
	SpellInfo(blood_plague_debuff duration=24 tick=3)
Define(blood_shield_buff 77535)
	SpellInfo(blood_shield_buff duration=10)

	SpellInfo(blooddrinker haste=melee)
Define(blooddrinker_debuff 206931)
	SpellInfo(blooddrinker_debuff duration=3 tick=1 haste=melee)

	SpellInfo(bonestorm cd=60)
	SpellAddBuff(bonestorm bonestorm_buff=1)
Define(bonestorm_buff 194844)
Define(bone_shield_buff 195181)
	SpellInfo(bone_shield_buff duration=30 max_stacks=10)

	SpellInfo(breath_of_sindragosa runicpower=15 cd=120 gcd=0)
	SpellAddBuff(breath_of_sindragosa breath_of_sindragosa_buff=1)
Define(breath_of_sindragosa_buff 152279)

	SpellInfo(chains_of_ice runes=1 runicpower=-10)
	SpellAddBuff(chains_of_ice cold_heart_buff=0 talent=cold_heart_talent)
Define(chains_of_ice_debuff 45524)
	SpellInfo(chains_of_ice_debuff duration=8)

	SpellInfo(clawing_shadows runes=1 runicpower=-10)
	SpellAddTargetDebuff(clawing_shadows festering_wound_debuff=-1)

	SpellInfo(cold_heart_buff max_stacks=20)

	
Define(control_undead 111673)
	SpellInfo(control_undead runes=1 runicpower=-10)
Define(crimson_scourge_buff 81141)
	SpellInfo(crimson_scourge_buff duration=15 specialization=blood)

	SpellInfo(dancing_rune_weapon cd=120 gcd=0)
	SpellAddBuff(dancing_rune_weapon dancing_rune_weapon_buff=1)
Define(dancing_rune_weapon_buff 81256)
	SpellInfo(dancing_rune_weapon_buff duration=8)
Define(dark_command 56222)
	SpellInfo(dark_command cd=8)
Define(dark_succor_buff 101568)
	SpellInfo(dark_succor_buff duration=15)

	SpellInfo(dark_transformation cd=60)
	SpellAddPetBuff(dark_transformation dark_transformation_buff=1)
Define(dark_transformation_buff 63560)
	SpellInfo(dark_transformation_buff duration=15)

	SpellInfo(death_and_decay runes=1 runicpower=-10 cd=30 specialization=unholy)
	SpellInfo(death_and_decay runes=1 runicpower=-10 cd=15 specialization=blood)
	SpellInfo(death_and_decay replaced_by=defile talent=defile_talent specialization=unholy)
	SpellRequire(death_and_decay runes 0=buff,crimson_scourge_buff)
	SpellRequire(death_and_decay cd_percent 0=buff,crimson_scourge_buff)
	SpellAddTargetDebuff(death_and_decay death_and_decay_debuff=1)
	SpellAddBuff(death_and_decay death_and_decay_buff=1)
Define(death_and_decay_buff 188290)
Define(death_and_decay_debuff 43265)

	SpellInfo(death_coil runicpower=40 travel_time=1)
	SpellRequire(death_coil runicpower_percent 0=buff,sudden_doom_buff if_spell=sudden_doom)
Define(death_gate 50977)
Define(death_grip 49576)
	SpellInfo(death_grip cd=25)
	SpellInfo(death_grip cd=15 specialization=blood)
Define(death_pact 48743)
	SpellInfo(death_pact cd=120)
	SpellAddBuff(death_pact death_pact_debuff=1)
Define(death_pact_debuff 48743)
	SpellInfo(death_pact_debuff duration=15)

	
	SpellRequire(death_strike add_runicpower_from_aura -5=buff,death_strike_cost)
	SpellAddBuff(death_strike blood_shield_buff=1 specialization=blood)
	SpellAddBuff(death_strike voracius_buff=1 talent=voracious_talent specialization=blood)
SpellList(death_strike_cost ossuary_buff gravewarden_buff)
Define(deaths_advance 48265)
	SpellInfo(deaths_advance cd=45 gcd=0 offgcd=1)
	SpellAddBuff(deaths_advance deaths_advance_buff=1)
Define(deaths_advance_buff 48265)
	SpellInfo(deaths_advance_buff duration=8)
Define(deaths_caress 195292)
	SpellInfo(deaths_caress runes=1 runicpower=-10)
	SpellAddTargetDebuff(deaths_caress blood_plague_debuff=1)

	SpellInfo(defile runes=1 runicpower=-10 cd=20)
	SpellAddBuff(defile death_and_decay_buff=1)
	SpellAddTargetDebuff(defile death_and_decay_debuff=1)
Define(defile_debuff 156004)

	SpellInfo(empower_rune_weapon cd=120 runicpower=-5 runes=-1 tag=cd)
	SpellAddBuff(empower_rune_weapon empower_rune_weapon_buff=1)
Define(empower_rune_weapon_buff 47568)
	SpellInfo(empower_rune_weapon_buff duration=20)

	SpellInfo(epidemic runicpower=30)

	
	SpellAddTargetDebuff(festering_strike festering_wound_debuff=3)
Define(festering_wound_debuff 194310)
	SpellInfo(festering_wound_debuff duration=30 max_stacks=6)
Define(frost_fever_debuff 55095)
	SpellInfo(frost_fever_debuff duration=30 tick=3)
Define(frost_shield_buff 207203)
	SpellInfo(frost_shield_buff duration=10)

	
	SpellAddBuff(frost_strike icy_talons_buff=1 talent=icy_talons_talent)
	SpellAddBuff(frost_strike killing_machine_buff 1=buff,pillar_of_frost_buff talent=obliteration_talent)

	SpellInfo(frostscythe runes=1 runicpower=-10)

	SpellInfo(frostwyrms_fury cd=180)
	SpellAddTargetDebuff(frostwyrms_fury frostwyrms_fury_debuff=1)
Define(frostwyrms_fury_debuff 279303)
	SpellInfo(frostwyrms_fury_debuff duration=10)
Define(frozen_pulse_buff 194909)
Define(gathering_storm_buff 194912)

	SpellInfo(glacial_advance runicpower=30 cd=6 cd_haste=melee)
	SpellAddBuff(glacial_advance killing_machine_buff 1=buff,pillar_of_frost_buff talent=obliteration_talent)
Define(gorefiends_grasp 108199)
	SpellInfo(gorefiends_grasp cd=120)
	SpellInfo(gorefiends_grasp add_cd=-30 talent=tightening_grasp_talent)

	SpellInfo(heart_strike runes=1 runicpower=-10)
	SpellInfo(heart_strike add_runicpower=-2 talent=heartbreaker_talent)

	SpellInfo(haemostasis_buff duration=14 max_stacks=5)

	SpellInfo(horn_of_winter cd=45 runes=-2 runicpower=-20 tag=main)

	
	SpellRequire(howling_blast runes 0=buff,rime_buff)
	SpellRequire(howling_blast runicpower_percent 0=buff,rime_buff)
	SpellAddBuff(howling_blast rime_buff=0)
	SpellAddBuff(howling_blast killing_machine_buff 1=buff,pillar_of_frost_buff talent=obliteration_talent)
	SpellAddTargetDebuff(howling_blast frost_fever_debuff=1)
Define(icebound_fortitude 48792)
	SpellInfo(icebound_fortitude cd=180 gcd=0 offgcd=1)
	SpellAddBuff(icebound_fortitude icebound_fortitude_buff=1)
Define(icebound_fortitude_buff 48792)
	SpellInfo(icebound_fortitude_buff duration=8)

	SpellInfo(icy_talons_buff duration=6 max_stacks=3)
Define(inexorable_assault 253595)
	SpellInfo(inexorable_assault max_stacks=5)
Define(killing_machine 51128)

	SpellInfo(killing_machine_buff duration=10)
Define(mark_of_blood 206940)
	SpellInfo(mark_of_blood runicpower=30 cd=6)
Define(mark_of_blood_debuff 206940)
	SpellInfo(mark_of_blood_debuff duration=15)

	
	SpellAddBuff(marrowrend bone_shield_buff=1)

	SpellInfo(mind_freeze cd=15 gcd=0 interrupt=1 offgcd=1)

	
	SpellAddBuff(obliterate killing_machine_buff=0)
	SpellAddBuff(obliterate inexorable_assault=0 talent=inexorable_assault_talent)

	SpellInfo(outbreak runicpower=-10 runes=1)
	SpellAddTargetDebuff(outbreak virulent_plague_debuff=1)
	SpellAddTargetDebuff(outbreak outbreak_debuff=1)
Define(outbreak_debuff 196782)
	SpellInfo(outbreak_debuff duration=6)
Define(ossuary_buff 219788)
Define(path_of_frost 3714)

	SpellInfo(pillar_of_frost cd=45)
	SpellAddBuff(pillar_of_frost pillar_of_frost_buff=1)
Define(pillar_of_frost_buff 51271)
	SpellInfo(pillar_of_frost duration=15)
Define(raise_ally 61999)

    SpellRequire(raise_dead unusable 1=pet_health_pct,!0)
Define(razorice_debuff 51714)

	SpellInfo(remorseless_winter cd=20 runes=1 runicpower=-10)
Define(remorseless_winter_buff 196770)
	SpellInfo(remorseless_winter_buff duration=8)
Define(remorseless_winter_debuff 211793)

	SpellInfo(rime_buff duration=15)

	SpellInfo(rune_strike cd=60 max_charges=2 rune=-1)
Define(rune_tap 194679)
	SpellInfo(rune_tap cd=25 max_charges=2)
	SpellAddBuff(rune_tap rune_tap_buff=1)
Define(rune_tap_buff 194679)
	SpellInfo(rune_tap_buff duration=4)
Define(runic_corruption_buff 51460)
	SpellInfo(runic_corruption_buff duration=3) #TODO Increase rune generation rate

	
	SpellInfo(scourge_strike replaced_by=clawing_shadows talent=clawing_shadows_talent)

	SpellInfo(soul_reaper runes=-2 cd=45)
	SpellAddTargetDebuff(soul_reaper soul_reaper_debuff=1)
Define(soul_reaper_debuff 130736)
	SpellInfo(soul_reaper_debuff duration=5)
Define(sudden_doom 49530)

	SpellInfo(sudden_doom_buff duration=10)
	SpellInfo(sudden_doom_buff max_stacks=2 talent=harbinger_of_doom_talent)

	SpellInfo(summon_gargoyle cd=180)

	SpellInfo(tombstone cd=60)
	SpellAddBuff(tombstone bone_shield_buff=-5)

	SpellInfo(unholy_blight rune=1 runicpower=-10 cd=45)
	SpellAddBuff(unholy_blight unholy_blight_buff=1)
Define(unholy_blight_buff 115989)
	SpellInfo(unholy_blight duration=6)
Define(unholy_blight_debuff 115989)
	SpellInfo(unholy_blight_debuff duration=14 tick=2)

	SpellInfo(unholy_frenzy cd=78)
	SpellAddBuff(unholy_frenzy unholy_frenzy_buff)
Define(unholy_frenzy_buff 207289)
	SpellInfo(unholy_frenzy_buff duration=12)
Define(vampiric_blood 55233)
	SpellInfo(vampiric_blood cd=90 gcd=0 offgcd=1)
	SpellAddBuff(vampiric_blood vampiric_blood_buff=1)
Define(vampiric_blood_buff 55233)
	SpellInfo(vampiric_blood_buff duration=10)
Define(virulent_plague_debuff 191587)
	SpellInfo(virulent_plague_debuff duration=30 tick=3)
	SpellInfo(virulent_plague_debuff duration=15 tick=1.5 talent=ebon_fever_talent)
Define(voracius_buff 274009)
	SpellInfo(voracius_buff duration=6)
Define(wraith_walk 212552)
	SpellInfo(wraith_walk cd=60 unusable=1)
	SpellInfo(wraith_walk unusable=0 talent=wraith_walk_talent specialization=!blood)
	SpellInfo(wraith_walk unusable=0 talent=wraith_walk_talent_blood specialization=blood)
	SpellAddBuff(wraith_walk wraith_walk_buff=1)
Define(wraith_walk_buff 212552)
	SpellInfo(wraith_walk_buff duration=4)

# Weapon Enchant
Define(unholy_strength_buff 53365)
	SpellInfo(unholy_strength_buff duration=15)

## Items
Define(consorts_cold_core 144293)
Define(koltiras_newfound_will 132366)
Define(lanathels_lament_item 133974)
Define(lanathels_lament_buff 212975)
	SpellAddBuff(defile lanathels_lament_buff=1 if_equipped=lanathels_lament)
	SpellAddBuff(death_and_decay lanathels_lament_buff=1 if_equipped=lanathels_lament)
Define(perseverance_of_the_ebon_martyr_item 132459)
Define(perseverance_of_the_ebon_martyr_debuff 216059)


## Tier Items
# T20
SpellAddBuff(blood_boil gravewarden_buff=1 itemset=T20 itemcount=2)
Define(gravewarden_buff 242010) 
	SpellInfo(gravewarden_buff duration=10)
Define(master_of_ghouls_buff 246995)

# Talents
Define(all_will_serve_talent 2)
Define(antimagic_barrier_talent 11)
Define(army_of_the_damned_talent 19)
Define(asphyxiate_talent 8)
Define(asphyxiate_talent_unholy 9)
Define(avalanche_talent 10)


Define(bloodworms_talent 17)






Define(death_pact_talent 15)
Define(deaths_reach_talent 7)
Define(deaths_reach_talent_unholy 8)

Define(ebon_fever_talent 5)
Define(epidemic_talent 18)
Define(foul_bulwark_talent 7)





Define(grip_of_the_dead_talent 13)
Define(grip_of_the_dead_talent_unholy 7)
Define(harbinger_of_doom_talent 11)

Define(hemostasis_talent 5)

Define(icecap_talent 19)
Define(icy_talons_talent 2)
Define(inexorable_assault_talent 1)
Define(infected_claws_talent 1)
Define(mark_of_blood_talent 18)
Define(murderous_efficiency_talent 5)


Define(permafrost_talent 13)

Define(pestilent_pustules_talent 10)
Define(purgatory_talent 19)

Define(red_thirst_talent 20)

Define(rune_tap_talent 12)


Define(spell_eater_talent 13)

Define(tightening_grasp_talent 14)



Define(voracious_talent 16)
Define(will_of_the_necropolis_talent 10)
Define(wraith_walk_talent_blood 15)
Define(wraith_walk_talent 14)

# Non-default tags for OvaleSimulationCraft.
	SpellInfo(outbreak tag=main)
]]
    OvaleScripts:RegisterScript("DEATHKNIGHT", nil, name, desc, code, "include")
end
