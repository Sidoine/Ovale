local __exports = LibStub:NewLibrary("ovale/scripts/ovale_demonhunter_spells", 80300)
if not __exports then return end
__exports.registerDemonHunterSpells = function(OvaleScripts)
    local name = "ovale_demonhunter_spells"
    local desc = "[9.0] Ovale: DemonHunter spells"
    local code = [[Define(annihilation 201427)
# Slice your target for 227518s1+201428s1 Chaos damage. Annihilation has a 197125h chance to refund 193840s1 Fury.
  SpellInfo(annihilation fury=40)

Define(blade_dance 188499)
# Strike ?a206416[your primary target for <firstbloodDmg> Physical damage and ][]199552s1 nearby enemies for <baseDmg> Physical damage?s320398[, and increase your chance to dodge by 193311s1 for 193311d.][.]
# Rank 2: Reduces the cooldown of Blade Dance by abs(s0/1000) sec.
  SpellInfo(blade_dance fury=35 cd=15 duration=1)
  # Dodge chance increased by s2.
  SpellAddBuff(blade_dance blade_dance=1)
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
Define(bulk_extraction 320341)
# Demolish the spirit of all those around you, dealing s1 Fire damage to nearby enemies and extracting up to s2 Lesser Soul Fragments, drawing them to you for immediate consumption.
  SpellInfo(bulk_extraction cd=90 talent=bulk_extraction_talent)
Define(chaos_nova_0 179057)
# Unleash an eruption of fel energy, dealing s2 Chaos damage and stunning all nearby enemies for 2 seconds.?s320412[rnrnEach enemy stunned by Chaos Nova has a s3 chance to generate a Lesser Soul Fragment.][]
  SpellInfo(chaos_nova_0 fury=30 cd=60 duration=2)
  # Stunned.
  SpellAddTargetDebuff(chaos_nova_0 chaos_nova_0=1)
Define(chaos_nova_1 320412)
# Each enemy stunned by Chaos Nova has a 179057s3 chance to generate a Lesser Soul Fragment.
  SpellInfo(chaos_nova_1 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(chaos_nova_1 chaos_nova_1=1)
Define(chaos_strike 162794)
# Slice your target for 222031s1+199547s1 Chaos damage. Chaos Strike has a 197125h chance to refund 193840s1 Fury.
# Rank 3: Chaos Strike damage increased by s1.
  SpellInfo(chaos_strike fury=40)

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

Define(consume_magic 278326)
# Consume m1 beneficial Magic effect removing it from the target?s320313[ and granting you s2 Fury][].
# Rank 2: Consume Magic generates 278326s2 Fury when a beneficial Magic effect is successfully removed from the target.
  SpellInfo(consume_magic cd=10 fury=-20 pain=-20)
Define(death_sweep 210152)
# Strike ?a206416[your primary target for <firstbloodDmg> Physical damage and ][]199552s1 nearby enemies for <baseDmg> Physical damage?s320398[, and increase your chance to dodge by 193311s1 for 193311d.][.]
  SpellInfo(death_sweep fury=35 cd=9)
  # Dodge chance increased by s3.
  SpellAddBuff(death_sweep death_sweep=1)
Define(demon_spikes 203720)
# Surge with fel power, increasing your Armor by 203819s2*AGI/100?s321028[, and your Parry chance by 203819s1, for 6 seconds][].
# Rank 2: Demon Spikes also increases your Parry chance by 203819s1 for 6 seconds.
  SpellInfo(demon_spikes cd=1.5 charge_cd=20 gcd=0 offgcd=1)
  SpellInfo(vengeful_retreat replaced_by=demon_spikes)
Define(demons_bite 344859)
# Quickly attack for s2 Physical damage.rnrn|cFFFFFFFFGenerates ?a258876[m3+258876s3 to M3+258876s4][m3 to M3] Fury.|r
  SpellInfo(demons_bite)

Define(disrupt 183752)
# Interrupts the enemy's spellcasting and locks them from that school of magic for 3 seconds.|cFFFFFFFF?s183782[rnrnGenerates 218903s1 Fury on a successful interrupt.][]|r
# Rank 3: Increases the range of Disrupt to s+183752r yards.
  SpellInfo(disrupt cd=15 duration=3 gcd=0 offgcd=1 interrupt=1)
Define(elysian_decree_0 306830)
# Place a Kyrian Sigil at the target location that activates after 2 seconds.rnrnDetonates to deal 307046s1 Arcane damage and shatter up to s3 Lesser Soul Fragments from enemies affected by the sigil.
  SpellInfo(elysian_decree_0 cd=60 duration=2)
Define(elysian_decree_1 307046)
# Place a Kyrian Sigil at the target location that activates after 2 seconds.rnrnDetonates to deal 307046s1 Arcane damage and shatter up to s3 Lesser Soul Fragments from enemies affected by the sigil.
  SpellInfo(elysian_decree_1 channel=0 gcd=0 offgcd=1)

Define(elysian_decree_2 327839)
# Place a Kyrian Sigil at your location that activates after 2 seconds.rnrnDetonates to deal 307046s1 Arcane damage and shatter up to s3 Lesser Soul Fragments from enemies affected by the sigil.
  SpellInfo(elysian_decree_2 cd=60 duration=2)
Define(elysian_decree_3 339894)
# Place a Kyrian Sigil at the target location that activates after 2 seconds.rnrnDetonates to deal 307046s1 Arcane damage and shatter up to s3 Lesser Soul Fragments from enemies affected by the sigil.
  SpellInfo(elysian_decree_3 channel=0 gcd=0 offgcd=1)
Define(essence_break 258860)
# Slash all enemies in front of you for s1 Chaos damage, and increase the damage your Chaos Strike and Blade Dance deal to them by 320338s1 for 8 seconds.
  SpellInfo(essence_break cd=20 talent=essence_break_talent)
Define(exposed_wound 339229)
  SpellInfo(exposed_wound duration=10 gcd=0 offgcd=1)
  # Damage taken from Eye Beam  increased by w1.
  SpellAddTargetDebuff(exposed_wound exposed_wound=1)
Define(eye_beam 198013)
# Blasts all enemies in front of you, ?s320415[dealing guaranteed critical strikes][] for up to <dmg> Chaos damage over 2 seconds. Deals reduced damage to secondary targets.?s343311[rnrnWhen Eye Beam finishes fully channeling, your Haste is increased by an additional 343312s1 for 12 seconds.][]
# Rank 3: When Eye Beam finishes fully channeling, your Haste is increased by an additional 343312s1 for 12 seconds.
  SpellInfo(eye_beam fury=30 cd=30 duration=2 channel=2 tick=0.2)
  SpellAddBuff(eye_beam eye_beam=1)
Define(fel_barrage 258925)
# Unleash a torrent of Fel energy over 3 seconds, inflicting ((3 seconds/t1)+1)*258926s1 Chaos damage to 258926s2 enemies within 258926A1 yds.
  SpellInfo(fel_barrage cd=60 duration=3 channel=3 tick=0.25 talent=fel_barrage_talent)
  # Unleashing Fel.
  SpellAddBuff(fel_barrage fel_barrage=1)
Define(fel_bombardment 337849)
# Immolation Aura damage has a chance to grant you a stack of Fel Bombardment, increasing the damage that your next Throw Glaive deals to your primary target by 337849s1 and launching an additional glaive at a nearby target. This effect stacks up to 337849u times.
  SpellInfo(fel_bombardment max_stacks=5 gcd=0 offgcd=1)
  # Throw Glaive damage to your primary target increased by w1 and s2 additional Lglaive:glaives; Lis:are; thrown at La:; nearby Lenemy:enemies;.
  SpellAddBuff(fel_bombardment fel_bombardment=1)
Define(fel_eruption 211881)
# Impales the target for s1 Chaos damage and stuns them for 4 seconds.
  SpellInfo(fel_eruption fury=10 pain=10 cd=30 duration=4 talent=fel_eruption_talent)
  # Stunned.
  SpellAddTargetDebuff(fel_eruption fel_eruption=1)
Define(fel_rush_0 320416)
# Fel Rush gains an additional charge.
  SpellInfo(fel_rush_0 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(fel_rush_0 fel_rush_0=1)
Define(fel_rush_1 343017)
# Fel Rush damage increased by s1.
  SpellInfo(fel_rush_1 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(fel_rush_1 fel_rush_1=1)
Define(felblade 232893)
# Charge to your target and deal 213243sw2 Fire damage.rnrn?s203513[Shear has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r]?a203555[Demon Blades has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r][Demon's Bite has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r]
  SpellInfo(felblade cd=15 talent=felblade_talent_vengeance)
Define(fiery_brand 204021)
# Brand an enemy with a demonic symbol, instantly dealing sw2 Fire damage?s320962[ and 207771s3*8 seconds Fire damage over 8 seconds][]. The enemy's damage done to you is reduced by s1 for 8 seconds.
# Rank 3: The duration of Fiery Brand is increased by s1/1000 sec.
  SpellInfo(fiery_brand cd=60)
  # Dealing s1 less damage to the branding Demon Hunter.
  SpellAddBuff(fiery_brand fiery_brand=1)
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
Define(fodder_to_the_flame_0 329554)
# Commission a duel to the death against a Condemned Demon from the Theater of Pain. Vanquishing your foe releases its demon soul and creates a pool of demon blood that lasts for 30 seconds. Fighting within the pool increases your Haste by 330910s1 and reduces the damage that enemies deal to you by 330874s1.rnrnFleshcraft treats the Condemned Demon as a powerful enemy.
  SpellInfo(fodder_to_the_flame_0 cd=120)

Define(fodder_to_the_flame_1 330846)
  SpellInfo(fodder_to_the_flame_1 duration=30 gcd=0 offgcd=1)
Define(fodder_to_the_flame_2 330874)
# A pool of demon blood reduces the damage done to the victiorious Demon Hunter by s1.
  SpellInfo(fodder_to_the_flame_2 gcd=0 offgcd=1)
  # Damage to the victiorious Demon Hunter reduced by s1.
  SpellAddTargetDebuff(fodder_to_the_flame_2 fodder_to_the_flame_2=1)
Define(fodder_to_the_flame_3 330910)
# The pool of demon blood increases the Demon Hunter's haste by s1.
  SpellInfo(fodder_to_the_flame_3 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(fodder_to_the_flame_3 fodder_to_the_flame_3=1)
Define(fracture 263642)
# Rapidly slash your target for 225919sw1+225921sw1 Physical damage, and shatter s1 Lesser Soul Fragments from them.rnrn|cFFFFFFFFGenerates s4 Fury.|r
  SpellInfo(fracture cd=4.5 fury=-25 talent=fracture_talent)

Define(glaive_tempest 342817)
# Launch two demonic glaives in a whirlwind of energy, causing 14*342857s1 Chaos damage over 3 seconds to 342857i nearby enemies.
  SpellInfo(glaive_tempest fury=30 cd=20 duration=3 talent=glaive_tempest_talent)
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

Define(immolation_aura_0 320377)
# Increases the duration of Immolation Aura by s0.
  SpellInfo(immolation_aura_0 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(immolation_aura_0 immolation_aura_0=1)
Define(immolation_aura_1 320378)
# Reduces the cooldown of Immolation Aura by abs(s0/1000) sec.
  SpellInfo(immolation_aura_1 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(immolation_aura_1 immolation_aura_1=1)
Define(imprison 217832)
# Imprisons a demon, beast, or humanoid, incapacitating them for 60 seconds. Damage will cancel the effect. Limit 1.
  SpellInfo(imprison cd=45 duration=60)
  # Incapacitated.
  SpellAddTargetDebuff(imprison imprison=1)
Define(infernal_strike_0 189110)
# Leap through the air toward a targeted location, dealing 189112s1 Fire damage to all enemies within 189112a1 yards.
  SpellInfo(infernal_strike_0 cd=0.8 charge_cd=20 gcd=0 offgcd=1)
Define(infernal_strike_1 320791)
# Infernal Strike gains an additional charge.
  SpellInfo(infernal_strike_1 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(infernal_strike_1 infernal_strike_1=1)
Define(infernal_strike_2 343016)
# Infernal Strike damage increased by s1.
  SpellInfo(infernal_strike_2 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(infernal_strike_2 infernal_strike_2=1)
Define(lifeblood_buff 274419)
# When you use a Healthstone, gain s1 Leech for 20 seconds.
  SpellInfo(lifeblood_buff channel=-0.001 gcd=0 offgcd=1)

Define(memory_of_lucid_dreams_0 299300)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams_0)
Define(memory_of_lucid_dreams_1 299302)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams_1)
Define(memory_of_lucid_dreams_2 299304)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams_2)
Define(metamorphosis_0 187827)
# Transform to demon form for 15 seconds, increasing current and maximum health by s2 and Armor by s7.?s321067[ While transformed, Shear and Fracture generate one additional Lesser Soul Fragment][]?s321068[ and s4 additional Fury][].
  SpellInfo(metamorphosis_0 cd=300 duration=15 gcd=0 offgcd=1 tick=2)
  # Maximum health increased by w2.rnArmor increased by w7.rn?s263642[Fracture][Shear] generates w4 additional Fury and one additional Lesser Soul Fragment.
  SpellAddBuff(metamorphosis_0 metamorphosis_0=1)
  # Maximum health increased by w2.rnArmor increased by w7.rn?s263642[Fracture][Shear] generates w4 additional Fury and one additional Lesser Soul Fragment.
  SpellAddTargetDebuff(metamorphosis_0 metamorphosis_0=1)
Define(metamorphosis_1 320421)
# Reduces the cooldown of Metamorphosis by abs(s0/1000) sec.
  SpellInfo(metamorphosis_1 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(metamorphosis_1 metamorphosis_1=1)
Define(metamorphosis_2 320422)
# The Demon Hunter gains an additional s0 Haste during Metamorphosis.
  SpellInfo(metamorphosis_2 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(metamorphosis_2 metamorphosis_2=1)
Define(metamorphosis_3 320645)
# When you activate Metamorphosis, the cooldown of Eye Beam and Blade Dance is immediately reset.
  SpellInfo(metamorphosis_3 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(metamorphosis_3 metamorphosis_3=1)
Define(metamorphosis_4 321067)
# Reduces the cooldown of Metamorphosis by abs(s0/1000) sec.
  SpellInfo(metamorphosis_4 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(metamorphosis_4 metamorphosis_4=1)
Define(metamorphosis_5 321068)
# While transformed, Shear and Fracture generate 187827s4 additional Fury.rnrnThe cooldown of Metamorphosis is reduced by abs(s0/1000) sec.
  SpellInfo(metamorphosis_5 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(metamorphosis_5 metamorphosis_5=1)
Define(metamorphosis_buff_0 162264)
# Leap into the air and land with explosive force, dealing 200166s2 Chaos damage to enemies within 8 yds, and stunning them for 3 seconds. Players are Dazed for 3 seconds instead.rnrnUpon landing, you are transformed into a hellish demon for 30 seconds, ?s320645[immediately resetting the cooldown of your Eye Beam and Blade Dance abilities, ][]greatly empowering your Chaos Strike and Blade Dance abilities?s320422[ and gaining 320422s1 Haste][]?s204909[ and 162264s3 Leech][].
  SpellInfo(metamorphosis_buff_0 duration=30 gcd=0 offgcd=1 tick=1)
  # Chaos Strike and Blade Dance upgraded to @spellname201427 and @spellname210152.rnHaste increased by 320422s1.?s204909[rnLeech increased by w3.][]
  SpellAddBuff(metamorphosis_buff_0 metamorphosis_buff_0=1)
  # Chaos Strike and Blade Dance upgraded to @spellname201427 and @spellname210152.rnHaste increased by 320422s1.?s204909[rnLeech increased by w3.][]
  SpellAddTargetDebuff(metamorphosis_buff_0 metamorphosis_buff_0=1)
Define(metamorphosis_buff_1 201453)
  SpellInfo(metamorphosis_buff_1 duration=1 channel=1 gcd=0 offgcd=1)
  SpellAddBuff(metamorphosis_buff_1 metamorphosis_buff_1=1)
Define(momentum 206476)
# Fel Rush increases your damage done by 208628s1 for 6 seconds.rnrnVengeful Retreat's cooldown is reduced by s1/-1000 sec, and it generates (203650s1/5)*10 seconds Fury over 10 seconds if it damages at least one enemy.
  SpellInfo(momentum channel=0 gcd=0 offgcd=1 talent=momentum_talent)
  SpellAddBuff(momentum momentum=1)
Define(prepared_buff 203650)
# Reduces the cooldown of Vengeful Retreat by 10 sec, and generates (203650s1/5)*10 seconds Fury over 10 seconds if you damage at least one enemy with Vengeful Retreat.
  SpellInfo(prepared_buff duration=10 gcd=0 offgcd=1)
  # Generating m1/5 Fury every sec.
  SpellAddBuff(prepared_buff prepared_buff=1)
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
Define(shear 203782)
# Shears an enemy for s1 Physical damage, and shatters ?a187827[two Lesser Soul Fragments][a Lesser Soul Fragment] from your target.rnrn|cFFFFFFFFGenerates m2 Fury.|r
  SpellInfo(shear fury=-10)
  SpellInfo(demons_bite replaced_by=shear)
Define(sigil_of_chains 202138)
# Place a Sigil of Chains at the target location that activates after 2 seconds.rnrnAll enemies affected by the sigil are pulled to its center and are snared, reducing movement speed by 204843s1 for 6 seconds.
  SpellInfo(sigil_of_chains cd=90 duration=2 talent=sigil_of_chains_talent)
Define(sigil_of_flame 204596)
# Place a Sigil of Flame at the target location that activates after 2 seconds.rnrnDeals 204598s1 Fire damage?s320794[, and an additional 204598o3 Fire damage over 6 seconds,][] to all enemies affected by the sigil.
# Rank 2: Sigil of Flame deals an additional 204598o3 Fire damage over 6 seconds, to all enemies affected by the sigil.
  SpellInfo(sigil_of_flame cd=30 duration=2)
  # Sigil of Flame is active.
  SpellAddBuff(sigil_of_flame sigil_of_flame=1)
Define(sigil_of_misery 207684)
# Place a Sigil of Misery at the target location that activates after 2 seconds.rnrnCauses all enemies affected by the sigil to cower in fear, disorienting them for 20 seconds.
# Rank 2: Reduces the cooldown of Sigil of Misery by abs(s0/1000) sec.
  SpellInfo(sigil_of_misery cd=180 duration=2)
Define(sigil_of_silence 202137)
# Place a Sigil of Silence at the target location that activates after 2 seconds.rnrnSilences all enemies affected by the sigil for 6 seconds.
# Rank 2: Reduces the cooldown of Sigil of Silence by abs(s0/1000) sec.
  SpellInfo(sigil_of_silence cd=120 duration=2)
Define(sinful_brand 317009)
# Brand an enemy with the mark of the Venthyr, reducing their melee attack speed by s3, their casting speed by s2, and inflicting o1 Shadow damage over 8 seconds.rnrnActivating Metamorphosis applies Sinful Brand to all nearby enemies.
  SpellInfo(sinful_brand cd=60 duration=8 tick=2)
  # Suffering w1 Shadow damage every t1 sec. Casting speed slowed by w2. Melee attack speed slowed by w3.
  SpellAddTargetDebuff(sinful_brand sinful_brand=1)
Define(soul_cleave 228477)
# Viciously strike 228478s2 enemies in front of you for 228478s1 Physical damage and heal yourself for s4.rnrnConsumes up to s3 Soul Fragments within s1 yds?s321021[ and heals you for an additional s5 for each Soul Fragment consumed][].
# Rank 3: Soul Cleave damage increased by s1.
  SpellInfo(soul_cleave fury=30)

Define(spirit_bomb 247454)
# Consume up to s2 Soul Fragments within s1 yds and then explode, afflicting nearby enemies with Frailty for 20 seconds and damaging them for 247455s1 Fire per fragment.rnrnYou heal for 247456s1 of all damage you deal to enemies with Frailty.
  SpellInfo(spirit_bomb fury=30 duration=1.5 talent=spirit_bomb_talent)
  SpellAddBuff(spirit_bomb spirit_bomb=1)
Define(the_hunt 323639)
# Charge to your target, striking them for 323802s1 Nature damage, rooting them in place for 1.5 seconds and inflicting 345335s1*6 seconds Nature damage over 6 seconds to up to 345396s2 enemies in your path. rnrnThe pursuit invigorates your soul, healing you for 345422s1 of the damage you deal to your Hunt target for 30 seconds.
  SpellInfo(the_hunt cd=90)


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
Define(throw_glaive 204157)
# Throw a demonic glaive at the target, dealing 346665s1 Physical damage. The glaive can ricochet to ?s320386[346665x1-1 additional enemies][an additional enemy] within 10 yards. Generates high threat.
# Rank 3: Reduces the cooldown of Throw Glaive by abs(s0/1000) sec.
  SpellInfo(throw_glaive cd=9)

Define(unbound_chaos_0 275147)
# Activating Immolation Aura will cause your inner demon to slam into nearby enemies at the end of your next Fel Rush, dealing 275148s1 Chaos damage.
  SpellInfo(unbound_chaos_0 duration=1 gcd=0 offgcd=1)
Define(unbound_chaos_1 275148)
# Activating Immolation Aura will cause your inner demon to slam into nearby enemies at the end of your next Fel Rush, dealing 275148s1 Chaos damage.
  SpellInfo(unbound_chaos_1 gcd=0 offgcd=1)

Define(vengeful_retreat 344866)
# Remove all snares and vault away. Nearby enemies take 198813s2 Physical damage?s320635[ and have their movement speed reduced by 198813s1 for 3 seconds][].?a203551[rnrn|cFFFFFFFFGenerates (203650s1/5)*10 seconds Fury over 10 seconds if you damage an enemy.|r][]
# Rank 2: Vengeful Retreat reduces the movement speed of all nearby enemies by 198813s1 for 3 seconds.
  SpellInfo(vengeful_retreat cd=25 gcd=0 offgcd=1)

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
SpellList(blood_of_the_enemy blood_of_the_enemy_0 blood_of_the_enemy_1 blood_of_the_enemy_2 blood_of_the_enemy_3)
SpellList(chaos_nova chaos_nova_0 chaos_nova_1)
SpellList(concentrated_flame concentrated_flame_0 concentrated_flame_1 concentrated_flame_2 concentrated_flame_3 concentrated_flame_4 concentrated_flame_5 concentrated_flame_6)
SpellList(elysian_decree elysian_decree_0 elysian_decree_1 elysian_decree_2 elysian_decree_3)
SpellList(fel_rush fel_rush_0 fel_rush_1)
SpellList(focused_azerite_beam focused_azerite_beam_0 focused_azerite_beam_1 focused_azerite_beam_2 focused_azerite_beam_3)
SpellList(fodder_to_the_flame fodder_to_the_flame_0 fodder_to_the_flame_1 fodder_to_the_flame_2 fodder_to_the_flame_3)
SpellList(guardian_of_azeroth guardian_of_azeroth_0 guardian_of_azeroth_1 guardian_of_azeroth_2 guardian_of_azeroth_3 guardian_of_azeroth_4 guardian_of_azeroth_5)
SpellList(immolation_aura immolation_aura_0 immolation_aura_1)
SpellList(memory_of_lucid_dreams memory_of_lucid_dreams_0 memory_of_lucid_dreams_1 memory_of_lucid_dreams_2)
SpellList(metamorphosis metamorphosis_0 metamorphosis_1 metamorphosis_2 metamorphosis_3 metamorphosis_4 metamorphosis_5)
SpellList(metamorphosis_buff metamorphosis_buff_0 metamorphosis_buff_1)
SpellList(purifying_blast purifying_blast_0 purifying_blast_1 purifying_blast_2 purifying_blast_3 purifying_blast_4 purifying_blast_5)
SpellList(razor_coral razor_coral_0 razor_coral_1 razor_coral_2 razor_coral_3 razor_coral_4)
SpellList(reaping_flames reaping_flames_0 reaping_flames_1 reaping_flames_2 reaping_flames_3 reaping_flames_4)
SpellList(reckless_force_buff reckless_force_buff_0 reckless_force_buff_1)
SpellList(ripple_in_space ripple_in_space_0 ripple_in_space_1 ripple_in_space_2 ripple_in_space_3)
SpellList(the_unbound_force the_unbound_force_0 the_unbound_force_1 the_unbound_force_2 the_unbound_force_3)
SpellList(unbound_chaos unbound_chaos_0 unbound_chaos_1)
SpellList(worldvein_resonance worldvein_resonance_0 worldvein_resonance_1 worldvein_resonance_2 worldvein_resonance_3)
SpellList(infernal_strike infernal_strike_0 infernal_strike_1 infernal_strike_2)
Define(blind_fury_talent 1) #21854
# Eye Beam generates s3/5 Fury every sec. and its duration is increased by s1.
Define(bulk_extraction_talent 21) #21902
# Demolish the spirit of all those around you, dealing s1 Fire damage to nearby enemies and extracting up to s2 Lesser Soul Fragments, drawing them to you for immediate consumption.
Define(demon_blades_talent 6) #22799
# Your auto attacks have a s1 chance to deal additional Shadow damage and generate Fury.
Define(demonic_talent 19) #21900
# Eye Beam causes you to enter demon form for s1/1000 sec after it finishes dealing damage.
Define(essence_break_talent 15) #21868
# Slash all enemies in front of you for s1 Chaos damage, and increase the damage your Chaos Strike and Blade Dance deal to them by 320338s1 for 8 seconds.
Define(fel_barrage_talent 21) #22547
# Unleash a torrent of Fel energy over 3 seconds, inflicting ((3 seconds/t1)+1)*258926s1 Chaos damage to 258926s2 enemies within 258926A1 yds.
Define(fel_eruption_talent 18) #22767
# Impales the target for s1 Chaos damage and stuns them for 4 seconds.
Define(felblade_talent_vengeance 3) #22504
# Charge to your target and deal 213243sw2 Fire damage.rnrn?s203513[Shear has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r]?a203555[Demon Blades has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r][Demon's Bite has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r]
Define(first_blood_talent 14) #21867
# Reduces the Fury cost of Blade Dance by s2 and increases its damage to <firstbloodDmg> against the first target struck.
Define(fracture_talent 12) #22770
# Rapidly slash your target for 225919sw1+225921sw1 Physical damage, and shatter s1 Lesser Soul Fragments from them.rnrn|cFFFFFFFFGenerates s4 Fury.|r
Define(glaive_tempest_talent 9) #21862
# Launch two demonic glaives in a whirlwind of energy, causing 14*342857s1 Chaos damage over 3 seconds to 342857i nearby enemies.
Define(momentum_talent 20) #21901
# Fel Rush increases your damage done by 208628s1 for 6 seconds.rnrnVengeful Retreat's cooldown is reduced by s1/-1000 sec, and it generates (203650s1/5)*10 seconds Fury over 10 seconds if it damages at least one enemy.
Define(sigil_of_chains_talent 15) #22511
# Place a Sigil of Chains at the target location that activates after 2 seconds.rnrnAll enemies affected by the sigil are pulled to its center and are snared, reducing movement speed by 204843s1 for 6 seconds.
Define(spirit_bomb_talent 9) #22540
# Consume up to s2 Soul Fragments within s1 yds and then explode, afflicting nearby enemies with Frailty for 20 seconds and damaging them for 247455s1 Fire per fragment.rnrnYou heal for 247456s1 of all damage you deal to enemies with Frailty.
Define(trail_of_ruin_talent 7) #22909
# The final slash of Blade Dance inflicts an additional 258883o1 Chaos damage over 4 seconds.
Define(unbound_chaos_talent 8) #22494
# Activating Immolation Aura will cause your inner demon to slam into nearby enemies at the end of your next Fel Rush, dealing 275148s1 Chaos damage.
Define(unbridled_fury_item 169299)
Define(chaotic_transformation_trait 288754)
Define(eyes_of_rage_trait 278500)
Define(revolving_blades_trait 279581)
Define(breath_of_the_dying_essence_id 35)
    ]]
    OvaleScripts:RegisterScript("DEMONHUNTER", nil, name, desc, code, "include")
end
