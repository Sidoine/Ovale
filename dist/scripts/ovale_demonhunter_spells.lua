local __exports = LibStub:NewLibrary("ovale/scripts/ovale_demonhunter_spells", 80201)
if not __exports then return end
__exports.registerDemonHunterSpells = function(OvaleScripts)
    local name = "ovale_demonhunter_spells"
    local desc = "[8.2] Ovale: DemonHunter spells"
    local code = [[Define(annihilation 201427)
# Slice your target for 227518s1+201428s1 Chaos damage. Annihilation has a 197125h chance to refund 193840s1 Fury.
  SpellInfo(annihilation fury=40)

Define(blade_dance 188499)
# Strike ?a206416[your primary target for <firstbloodDmg> Physical damage, ][]all nearby enemies for <baseDmg> Physical damage, and increase your chance to dodge by s2 for 1 second.
  SpellInfo(blade_dance fury=35 cd=9 duration=1)
  # Dodge chance increased by s2.
  SpellAddBuff(blade_dance blade_dance=1)
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
Define(chaos_nova 179057)
# Unleash an eruption of fel energy, dealing s2 Chaos damage and stunning all nearby enemies for 2 seconds.rnrnEach enemy stunned by Chaos Nova has a s3 chance to generate a Lesser Soul Fragment.
  SpellInfo(chaos_nova fury=30 cd=60 duration=2)
  # Stunned.
  SpellAddTargetDebuff(chaos_nova chaos_nova=1)
Define(chaos_strike 162794)
# Slice your target for 222031s1+199547s1 Chaos damage. Chaos Strike has a 197125h chance to refund 193840s1 Fury.
  SpellInfo(chaos_strike fury=40)

Define(conductive_ink_0 302491)
# Your damaging abilities against enemies above 30 health have a very high chance to apply Conductive Ink. When an enemy falls below M3 health, Conductive Ink inflicts s1*(1+@versadmg) Nature damage per stack.
  SpellInfo(conductive_ink_0 channel=0 gcd=0 offgcd=1)

Define(conductive_ink_1 302597)
# Your damaging abilities against enemies above 30 health have a very high chance to apply Conductive Ink. When an enemy falls below M3 health, Conductive Ink inflicts s1*(1+@versadmg) Nature damage per stack.
  SpellInfo(conductive_ink_1 channel=0 gcd=0 offgcd=1)

Define(consume_magic 278326)
# Consume m1 beneficial Magic effect from the target, removing it and granting you ?c1[s2 Fury][s3/10 Pain].
  SpellInfo(consume_magic cd=10 fury=-20 pain=-20)
Define(dark_slash 258860)
# Slash an enemy for s2 Physical damage, and increase the damage your Chaos Strike deals to them by s3 for 8 seconds.
  SpellInfo(dark_slash cd=20 duration=8 talent=dark_slash_talent)
  # The Demon Hunter's Chaos Strike deals s3 additional damage.
  SpellAddTargetDebuff(dark_slash dark_slash=1)
Define(death_sweep 210152)
# Strike all nearby enemies for 3*210153sw2+210155sw2 Physical damage, and increase your Dodge chance by s2 for 1 second.
  SpellInfo(death_sweep fury=35 cd=9 duration=1)
  # Dodge chance increased by s3.
  SpellAddBuff(death_sweep death_sweep=1)
Define(demon_spikes 203720)
# Surge with fel power, increasing your Armor by 203819s2*AGI/100, and your Parry chance by 203819s1, for 6 seconds.
  SpellInfo(demon_spikes cd=1.5 charge_cd=20 gcd=0 offgcd=1)
  SpellInfo(vengeful_retreat replaced_by=demon_spikes)
Define(demons_bite 162243)
# Quickly attack for s2 Physical damage.rnrn|cFFFFFFFFGenerates m3 to ?a258876[M3+258876s1][M3] Fury.|r
  SpellInfo(demons_bite fury=-25)
Define(disrupt 183752)
# Interrupts the enemy's spellcasting and locks them from that school of magic for 3 seconds.|cFFFFFFFF?s178940[rnrnGenerates 218903s1 Fury on a successful interrupt.][rnrnGenerates 218903s2/10 Pain on a successful interrupt.]|r
  SpellInfo(disrupt cd=15 duration=3 gcd=0 offgcd=1 interrupt=1)
Define(eye_beam 198013)
# Blasts all enemies in front of you, dealing guaranteed critical strikes for a total of <dmg> Chaos damage over 2 seconds. Your primary target takes s3 increased damage.
  SpellInfo(eye_beam fury=30 cd=30 duration=2 channel=2 tick=0.2)
  SpellAddBuff(eye_beam eye_beam=1)
Define(fel_barrage 258925)
# Unleash a torrent of Fel energy over 3 seconds, inflicting ((3 seconds/t1)+1)*258926s1 Chaos damage to all enemies within 258926A1 yds.
  SpellInfo(fel_barrage cd=60 duration=3 channel=3 tick=0.25 talent=fel_barrage_talent)
  # Unleashing Fel.
  SpellAddBuff(fel_barrage fel_barrage=1)
Define(fel_devastation 212084)
# Unleash the fel within you, damaging enemies directly in front of you for 212105s1*(2/t1) Fire damage over 2 seconds. Causing damage also heals you for up to 212106s1*(2/t1) health.
  SpellInfo(fel_devastation cd=60 duration=2 channel=2 tick=0.2 talent=fel_devastation_talent)
  SpellAddBuff(fel_devastation fel_devastation=1)
Define(fel_eruption 211881)
# Impales the target for s1 Chaos damage and stuns them for 4 seconds.
  SpellInfo(fel_eruption fury=10 pain=10 cd=30 duration=4 talent=fel_eruption_talent)
  # Stunned.
  SpellAddTargetDebuff(fel_eruption fel_eruption=1)
Define(fel_rush 195072)
# Rush forward, incinerating anything in your path for 192611s1 Chaos damage.
  SpellInfo(fel_rush cd=1 charge_cd=10 gcd=0.25)
Define(felblade 232893)
# Charge to your target and deal 213243sw2 Fire damage.rnrn?s203513[Shear has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3/10 Pain.|r]?a203555[Demon Blades has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s4 Fury.|r][Demon's Bite has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s4 Fury.|r]
  SpellInfo(felblade cd=15 talent=felblade_talent_vengeance)
Define(fiery_brand 204021)
# Brand an enemy with a demonic symbol, instantly dealing sw2 Fire damage and reducing the damage they deal to you by s1 for 8 seconds.
  SpellInfo(fiery_brand cd=60)
  SpellInfo(chaos_nova replaced_by=fiery_brand)
  # Dealing s1 less damage to the branding Demon Hunter.
  SpellAddBuff(fiery_brand fiery_brand=1)
Define(focused_azerite_beam_0 299336)
# Focus excess Azerite energy into the Heart of Azeroth, then expel that energy outward, dealing m1*10 Fire damage to all enemies in front of you over 3 seconds.
  SpellInfo(focused_azerite_beam_0 cd=90 duration=3 channel=3 tick=0.33)

Define(focused_azerite_beam_1 299338)
# Focus excess Azerite energy into the Heart of Azeroth, then expel that energy outward, dealing m1*10 Fire damage to all enemies in front of you over 3 seconds. Castable while moving.
  SpellInfo(focused_azerite_beam_1 cd=90 duration=3 channel=3 tick=0.33)

Define(fracture 263642)
# Rapidly slash your target for 225919sw1+225921sw1 Physical damage, and shatter s1 Lesser Soul Fragments from them.rnrn|cFFFFFFFFGenerates s4/10 Pain.|r
  SpellInfo(fracture cd=4.5 pain=-25 talent=fracture_talent)

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

Define(immolation_aura 178740)
# Engulf yourself in flames, instantly causing 187727s1 Fire damage to enemies within 187727A1 yards and radiating 178741s1 Fire damage every sec for 6 seconds.rnrn|cFFFFFFFFGenerates s3/10+178741s2/10*6 seconds Pain over 6 seconds.|r
  SpellInfo(immolation_aura cd=15 duration=6 pain=-8 tick=1)
  SpellInfo(eye_beam replaced_by=immolation_aura)
  # Burns nearby enemies for 178741s1 Fire damage every 178740t1 sec.?a207548[rnrnMovement speed increased by w4.][]
  SpellAddBuff(immolation_aura immolation_aura=1)
Define(imprison 217832)
# Imprisons a demon, beast, or humanoid, incapacitating them for 60 seconds. Damage will cancel the effect. Limit 1.
  SpellInfo(imprison cd=45 duration=60)
  # Incapacitated.
  SpellAddTargetDebuff(imprison imprison=1)
Define(infernal_strike 189110)
# Leap through the air toward a targeted location, dealing 189112s1 Fire damage to all enemies within 189112a1 yards.
  SpellInfo(infernal_strike cd=0.8 charge_cd=20 gcd=0 offgcd=1)
  SpellInfo(fel_rush replaced_by=infernal_strike)
Define(lifeblood_buff 274419)
# When you use a Healthstone, gain s1 Leech for 20 seconds.
  SpellInfo(lifeblood_buff channel=-0.001 gcd=0 offgcd=1)

Define(nemesis 206491)
# Increases damage you inflict against the target by s1 for 60 seconds. rnrnWhen the target is slain, you will inflict s1 additional damage against all creature types matching the original target (Humanoid, Dragonkin, etc.) for the remaining duration.
  SpellInfo(nemesis cd=120 duration=60 talent=nemesis_talent)
  # Damage taken increased by s1.
  SpellAddTargetDebuff(nemesis nemesis=1)
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
Define(reckless_force_buff_0 298409)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 3 seconds.
  SpellInfo(reckless_force_buff_0 max_stacks=5 gcd=0 offgcd=1 tick=10)
  # Gaining unstable Azerite energy.
  SpellAddBuff(reckless_force_buff_0 reckless_force_buff_0=1)
Define(reckless_force_buff_1 304038)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 3 seconds.
  SpellInfo(reckless_force_buff_1 channel=-0.001 gcd=0 offgcd=1)
  SpellAddBuff(reckless_force_buff_1 reckless_force_buff_1=1)
Define(reckless_force_counter 302917)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 3 seconds.
  SpellInfo(reckless_force_counter duration=60 channel=60 max_stacks=20 gcd=0 offgcd=1)
  # Upon reaching u stacks, you gain 302932s~1 Critical Strike for 302932d.
  SpellAddBuff(reckless_force_counter reckless_force_counter=1)
Define(shear 203782)
# Shears an enemy for s1 Physical damage, and shatters ?a187827[two Lesser Soul Fragments][a Lesser Soul Fragment] from your target.rnrn|cFFFFFFFFGenerates m2/10 Pain.|r
  SpellInfo(shear pain=-10)
Define(sigil_of_chains 202138)
# Place a Sigil of Chains at the target location that activates after 2 seconds.rnrnAll enemies affected by the sigil are pulled to its center and are snared, reducing movement speed by 204843s1 for 6 seconds.
  SpellInfo(sigil_of_chains cd=90 duration=2 talent=sigil_of_chains_talent)
Define(sigil_of_flame 204596)
# Place a Sigil of Flame at the target location that activates after 2 seconds.rnrnDeals 204598s1 Fire damage, and an additional 204598o3 Fire damage over 6 seconds, to all enemies affected by the sigil.
  SpellInfo(sigil_of_flame cd=30 duration=2)
  SpellInfo(blade_dance replaced_by=sigil_of_flame)
  # Sigil of Flame is active.
  SpellAddBuff(sigil_of_flame sigil_of_flame=1)
Define(sigil_of_misery 207684)
# Place a Sigil of Misery at the target location that activates after 2 seconds.rnrnCauses all enemies affected by the sigil to cower in fear, disorienting them for 20 seconds.
  SpellInfo(sigil_of_misery cd=90 duration=2)
Define(sigil_of_silence 202137)
# Place a Sigil of Silence at the target location that activates after 2 seconds.rnrnSilences all enemies affected by the sigil for 6 seconds.
  SpellInfo(sigil_of_silence cd=60 duration=2)
Define(soul_cleave 228477)
# Viciously strike all enemies in front of you for 228478s1 Physical damage and heal yourself for s4.rnrnConsumes up to s3 Soul Fragments within s1 yds.
  SpellInfo(soul_cleave pain=30)
  SpellInfo(chaos_strike replaced_by=soul_cleave)

Define(spirit_bomb 247454)
# Consume up to s2 Soul Fragments within s1 yds and then explode, afflicting nearby enemies with Frailty for 20 seconds and damaging them for 247455s1 Fire per fragment.rnrnYou heal for 247456s1 of all damage you deal to enemies with Frailty.
  SpellInfo(spirit_bomb pain=30 duration=1.5 talent=spirit_bomb_talent)
  SpellAddBuff(spirit_bomb spirit_bomb=1)
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
Define(vengeful_retreat 198793)
# Remove all snares and vault away. Nearby enemies take 198813s2 Physical damage and have their movement speed reduced by 198813s1 for 3 seconds.?a203551[rnrn|cFFFFFFFFGenerates (203650s1/5)*10 seconds Fury over 10 seconds if you damage an enemy.|r][]
  SpellInfo(vengeful_retreat cd=25 duration=1 channel=1 gcd=0 offgcd=1)
  SpellAddBuff(vengeful_retreat vengeful_retreat=1)
SpellList(blood_of_the_enemy blood_of_the_enemy_0 blood_of_the_enemy_1 blood_of_the_enemy_2 blood_of_the_enemy_3 blood_of_the_enemy_4 blood_of_the_enemy_5 blood_of_the_enemy_6)
SpellList(conductive_ink conductive_ink_0 conductive_ink_1)
SpellList(focused_azerite_beam focused_azerite_beam_0 focused_azerite_beam_1)
SpellList(guardian_of_azeroth guardian_of_azeroth_0 guardian_of_azeroth_1 guardian_of_azeroth_2 guardian_of_azeroth_3 guardian_of_azeroth_4 guardian_of_azeroth_5)
SpellList(purifying_blast purifying_blast_0 purifying_blast_1 purifying_blast_2 purifying_blast_3 purifying_blast_4 purifying_blast_5)
SpellList(razor_coral razor_coral_0 razor_coral_1 razor_coral_2 razor_coral_3 razor_coral_4)
SpellList(reckless_force_buff reckless_force_buff_0 reckless_force_buff_1)
SpellList(the_unbound_force the_unbound_force_0 the_unbound_force_1 the_unbound_force_2 the_unbound_force_3 the_unbound_force_4 the_unbound_force_5 the_unbound_force_6 the_unbound_force_7)
Define(blind_fury_talent 1) #21854
# Eye Beam generates s3/5 Fury every sec. and its duration is increased by s1.
Define(charred_flesh_talent 8) #22541
# Fiery Brand increases the Fire damage your abilities deal to the target by s1.
Define(dark_slash_talent 15) #21868
# Slash an enemy for s2 Physical damage, and increase the damage your Chaos Strike deals to them by s3 for 8 seconds.
Define(demon_blades_talent 5) #22765
# Your auto attacks have a s1 chance to deal additional Shadow damage and generate Fury.
Define(demonic_talent 19) #21900
# Eye Beam causes you to enter demon form for 8 sec after it finishes dealing damage.
Define(fel_barrage_talent 9) #21862
# Unleash a torrent of Fel energy over 3 seconds, inflicting ((3 seconds/t1)+1)*258926s1 Chaos damage to all enemies within 258926A1 yds.
Define(fel_devastation_talent 18) #22768
# Unleash the fel within you, damaging enemies directly in front of you for 212105s1*(2/t1) Fire damage over 2 seconds. Causing damage also heals you for up to 212106s1*(2/t1) health.
Define(fel_eruption_talent 18) #22767
# Impales the target for s1 Chaos damage and stuns them for 4 seconds.
Define(fel_mastery_talent 8) #22494
# Increases Fel Rush damage by s1.
Define(felblade_talent_vengeance 9) #22540
# Charge to your target and deal 213243sw2 Fire damage.rnrn?s203513[Shear has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3/10 Pain.|r]?a203555[Demon Blades has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s4 Fury.|r][Demon's Bite has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s4 Fury.|r]
Define(first_blood_talent 14) #21867
# Reduces the Fury cost of Blade Dance by s2 and increases its damage to <firstbloodDmg> against the first target struck.
Define(fracture_talent 12) #22770
# Rapidly slash your target for 225919sw1+225921sw1 Physical damage, and shatter s1 Lesser Soul Fragments from them.rnrn|cFFFFFFFFGenerates s4/10 Pain.|r
Define(momentum_talent 20) #21901
# Fel Rush increases your damage done by 208628s1 for 6 seconds.rnrnVengeful Retreat's cooldown is reduced by s1/-1000 sec, and it generates (203650s1/5)*10 seconds Fury over 10 seconds if it damages at least one enemy.
Define(nemesis_talent 21) #22547
# Increases damage you inflict against the target by s1 for 60 seconds. rnrnWhen the target is slain, you will inflict s1 additional damage against all creature types matching the original target (Humanoid, Dragonkin, etc.) for the remaining duration.
Define(sigil_of_chains_talent 15) #22511
# Place a Sigil of Chains at the target location that activates after 2 seconds.rnrnAll enemies affected by the sigil are pulled to its center and are snared, reducing movement speed by 204843s1 for 6 seconds.
Define(spirit_bomb_talent 17) #22513
# Consume up to s2 Soul Fragments within s1 yds and then explode, afflicting nearby enemies with Frailty for 20 seconds and damaging them for 247455s1 Fire per fragment.rnrnYou heal for 247456s1 of all damage you deal to enemies with Frailty.
Define(trail_of_ruin_talent 7) #22909
# The final slash of Blade Dance inflicts an additional 258883o1 Chaos damage over 4 seconds.
Define(chaotic_transformation_trait 288754)
Define(revolving_blades_trait 279581)
    ]]
    code = code .. [[

ItemRequire(shifting_cosmic_sliver unusable 1=oncooldown,!metamorphosis_veng,buff,!metamorphosis_veng_buff)	

Define(annihilation 201427)
    SpellRequire(annihilation add_fury_from_aura -1=buff,thirsting_blades_buff)

	SpellInfo(blade_dance replace death_sweep=buff,metamorphosis_havoc_buff)
	SpellInfo(blade_dance fury=35 cd=9 cd_haste=melee)
	SpellInfo(blade_dance add_fury=-20 talent=first_blood_talent)
    SpellRequire(blade_dance add_fury_from_aura -3=buff,revolving_blades_buff)
	SpellAddTargetDebuff(blade_dance blade_dance_debuff)
Define(blade_dance_debuff 258883)
	SpellInfo(blade_dance_debuff duration=4 tick=1)
Define(blur 198589)
	SpellInfo(blur cd=60 gcd=0 offgcd=1)
Define(chaos_brand_debuff 1490)

	SpellInfo(chaos_nova cd=60 fury=30)
	SpellInfo(chaos_nova cd=40 fury=0 talent=unleashed_power_talent)
	SpellAddBuff(chaos_nova chaos_nova_debuff=1)
Define(chaos_nova_debuff 179057)
	SpellInfo(chaos_nova_debuff duration=2)

	SpellInfo(chaos_strike replace annihilation=buff,metamorphosis_havoc_buff)
	SpellRequire(chaos_strike add_fury_from_aura -1=buff,thirsting_blades_buff)

	SpellInfo(consume_magic cd=10)

	SpellInfo(dark_slash cd=20)
	SpellAddTargetDebuff(dark_slash dark_slash_debuff=1)
Define(dark_slash_debuff 258860)
	SpellInfo(dark_slash_debuff duration=8)
Define(darkness 196718)
	SpellInfo(darkness cd=180)

	SpellInfo(death_sweep fury=35 cd=9 cd_haste=melee)
	SpellInfo(death_sweep add_fury=-20 talent=first_blood_talent)
    SpellRequire(death_sweep add_fury_from_aura -3=buff,revolving_blades_buff)

	SpellInfo(demon_spikes cd_haste=melee haste=melee specialization=vengeance cd=20 gcd=0 offgcd=1 charges=2)
	SpellAddBuff(demon_spikes demon_spikes_buff=1)
Define(demon_spikes_buff 203819)
	SpellInfo(demon_spikes_buff duration=6)

	SpellInfo(demons_bite fury=-20)
	SpellInfo(demons_bite unusable=1 talent=demon_blades_talent)

	SpellInfo(disrupt cd=15 gcd=0 interrupt=1 offgcd=1)

	SpellInfo(eye_beam fury=30 cd=30 channel=1.8)
	SpellInfo(eye_beam channel=2.8 talent=blind_fury_talent)
Define(extended_by_demonic_buff -22547) # OvaleDemonHunterDemonic
Define(feast_of_souls_buff 207693)
	SpellInfo(feast_of_souls_buff duration=6)

	SpellInfo(fel_barrage cd=60 channel=3)

	SpellInfo(fel_devastation cd=60 channel=2)

	SpellInfo(fel_eruption pain=0 specialization=!vengeance)
    SpellInfo(fel_eruption fury=0 specialization=!havoc)

	SpellInfo(fel_rush cd=10 charges=2)
	SpellAddBuff(fel_rush momentum_buff=1 talent=momentum_talent specialization=havoc)
	SpellRequire(fel_rush unusable 1=lossofcontrol,root)

	SpellInfo(felblade cd=15 cd_haste=melee fury=-40 pain=-30)
	SpellRequire(felblade unusable 1=lossofcontrol,root)

	SpellInfo(fiery_brand cd=60 gcd=0)
	SpellAddTargetDebuff(fiery_brand fiery_brand_debuff=1 talent=!burning_alive_talent)
    SpellAddTargetDebuff(fiery_brand fiery_demise_debuff=1 talent=burning_alive_talent)
Define(fiery_brand_debuff 207744)
	SpellInfo(fiery_brand_debuff duration=8)
Define(fiery_demise_debuff 207771)
    SpellInfo(fiery_demise_debuff duration=8)
Define(frailty_debuff 247456)
	SpellInfo(frailty_debuff duration=20)

    SpellAddBuff(fracture soul_fragments=2)
    SpellRequire(fracture add_pain_from_aura -20=buff,metamorphosis_veng_buff)
    SpellAddBuff(fracture soul_fragments 3=buff,metamorphosis_veng_buff)
    
	SpellInfo(immolation_aura cd=15 cd_haste=melee)
	SpellAddBuff(immolation_aura immolation_aura_buff=1)
Define(immolation_aura_buff 178740)
	SpellInfo(immolation_aura_buff duration=6)
Define(immolation_aura_havoc 258920)
	SpellInfo(immolation_aura_havoc cd=30 cd_haste=melee)
	SpellAddBuff(immolation_aura_havoc immolation_aura_havoc_buff=1)
Define(immolation_aura_havoc_buff 258920)
	SpellInfo(immolation_aura_buff duration=10)

	SpellInfo(imprison cd=45 interrupt=1)

	SpellInfo(infernal_strike cd=20 charges=2 offgcd=1)
	SpellInfo(infernal_strike add_cd=8 talent=abyssal_strike_talent)
	SpellRequire(infernal_strike unusable 1=lossofcontrol,root)
Define(metamorphosis_havoc 191427)
	SpellInfo(metamorphosis_havoc cd=240)
	SpellAddBuff(metamorphosis_havoc metamorphosis_havoc_buff=1)
	SpellRequire(metamorphosis_havoc unusable 1=lossofcontrol,root)
Define(metamorphosis_havoc_buff 162264)
	SpellInfo(metamorphosis_havoc_buff duration=30)
Define(metamorphosis_veng 187827)
	SpellInfo(metamorphosis_veng cd=180 gcd=0 offgcd=1)
	SpellAddBuff(metamorphosis_veng metamorphosis_veng_buff=1)
Define(metamorphosis_veng_buff 187827)
	SpellInfo(metamorphosis_veng_buff duration=15)
Define(momentum_buff 208628)
	SpellInfo(momentum_buff duration=6)

	SpellInfo(nemesis cd=120)
	SpellAddTargetDebuff(nemesis nemesis_debuff=1)
Define(nemesis_debuff 206491)
	SpellInfo(nemesis_debuff duration=60)
Define(netherwalk 196555)
	SpellInfo(netherwalk cd=120)
	SpellAddBuff(netherwalk netherwalk_buff=1)
Define(netherwalk_buff 196555)
	SpellInfo(netherwalk_buff duration=5)
Define(pick_up_fragment 210788)

	SpellInfo(prepared_buff duration=10)
Define(razor_spikes_debuff 210003)
	SpellInfo(razor_spikes_debuff duration=6)
Define(revolving_blades_buff 279584)
    SpellInfo(revolving_blades_buff duration=15)

    SpellAddBuff(shear soul_fragments=1)
    SpellRequire(shear add_pain_from_aura -20=buff,metamorphosis_veng_buff)
    SpellAddBuff(shear soul_fragments 2=buff,metamorphosis_veng_buff)
    
	SpellInfo(sigil_of_chains cd=90)

	SpellInfo(sigil_of_flame cd=30)
	SpellInfo(sigil_of_flame cd=24 talent=quickened_sigils_talent)
Define(sigil_of_flame_concentrated 204513)
    SpellInfo(sigil_of_flame replaced_by=sigil_of_flame_concentrated talent=concentrated_sigils_talent)
Define(sigil_of_flame_debuff 204598)
	SpellInfo(sigil_of_flame_debuff duration=6)
	SpellInfo(sigil_of_flame_debuff duration=8 talent=concentrated_sigils_talent)

	SpellInfo(sigil_of_misery cd=90)
	SpellInfo(sigil_of_misery cd=72 talent=quickened_sigils_talent)
Define(sigil_of_misery_debuff 207685)
	SpellInfo(sigil_of_misery_debuff duration=20)
	SpellInfo(sigil_of_misery_debuff duration=22 talent=concentrated_sigils_talent)

	SpellInfo(sigil_of_silence cd=60)
	SpellInfo(sigil_of_silence cd=48 talent=quickened_sigils_talent)
Define(sigil_of_silence_debuff 204490)
	SpellInfo(sigil_of_silence_debuff duration=6)
	SpellInfo(sigil_of_silence_debuff duration=8 talent=concentrated_sigils_talent)
Define(soul_barrier 263648)
	SpellInfo(soul_barrier cd=30)
	SpellAddBuff(soul_barrier soul_fragments=0)
Define(soul_barrier_buff 263648)
	SpellInfo(soul_barrier_buff duration=12)
	
	SpellAddBuff(soul_cleave soul_fragments=-2)
	SpellAddBuff(soul_cleave feast_of_souls_buff=1 talent=feast_of_souls_talent)
    SpellAddTargetDebuff(soul_cleave void_reaver_debuff=1 talent=void_reaver_talent)
Define(soul_fragments 203981)
Define(spectral_sight 188501)
	SpellInfo(spectral_sight cd=30)

	SpellRequire(spirit_bomb unusable 1=buff,!soul_fragments)
	SpellAddBuff(spirit_bomb soul_fragments=0)
	SpellAddTargetDebuff(spirit_bomb frailty_debuff=1)
Define(thirsting_blades_buff 278736)
    SpellInfo(thirsting_blades_buff max_stacks=40)
Define(throw_glaive_veng 204157)
	SpellInfo(throw_glaive_veng cd=3 cd_haste=melee)
Define(throw_glaive_havoc 185123)
	SpellInfo(throw_glaive_havoc charges=1 cd=9 cd_haste=melee)
	SpellInfo(throw_glaive_havoc charges=2 talent=master_of_the_glaive_talent)
	SpellAddTargetDebuff(throw_glaive_havoc throw_glaive_havoc_debuff=1)
Define(throw_glaive_havoc_debuff 213405)
	SpellInfo(throw_glaive_havoc_debuff duration=6)

	SpellInfo(vengeful_retreat cd=20)
	
	SpellAddTargetDebuff(vengeful_retreat vengeful_retreat_debuff=1)
Define(vengeful_retreat_debuff 198813)
	SpellInfo(vengeful_retreat_debuff duration=3)
	SpellRequire(vengeful_retreat unusable 1=lossofcontrol,root)
Define(void_reaver_debuff 268178)
    SpellInfo(void_reaver_debuff duration=12)
	
#items
Define(oblivions_embrace_item 151799)
	SpellInfo(demon_spikes charges=3 if_equipped=oblivions_embrace)

# Tier set
SpellInfo(demons_bite fury_percent=110 itemset=T19 itemcount=2)
SpellInfo(felblade fury_percent=110 itemset=T19 itemcount=2)

#Talents
Define(abyssal_strike_talent 1)
Define(agonizing_flames_talent 2)

Define(burning_alive_talent 6)

Define(concentrated_sigils_talent 13)
Define(cycle_of_hatred_talent 13)


Define(demonic_appetite_talent 2)

Define(desperate_instincts_talent 11)
Define(fallout_talent 5)
Define(feast_of_souls_talent 4)
Define(feed_the_demon_talent 11)




Define(felblade_talent_havoc 3)
Define(felblade_talent 9)

Define(flame_crash_talent 7)

Define(gluttony_talent 16)

Define(insatiable_hunger_talent 4)
Define(last_resort_talent 19)
Define(master_of_the_glaive_talent 17)


Define(netherwalk_talent 12)
Define(quickened_sigils_talent 14)
Define(razor_spikes_talent 3)
Define(sigil_of_chains_talent 15)
Define(soul_barrier_talent 21)
Define(soul_rending_talent 10)


Define(unleashed_power_talent 16)
Define(void_reaver_talent 20)

# Tags
SpellInfo(dark_slash tag=main)
SpellInfo(demon_spikes tag=shortcd)
SpellInfo(immolation_aura_havoc tag=main)
SpellInfo(fel_barrage tag=shortcd)
SpellInfo(fel_eruption tag=main)
SpellInfo(fel_rush tag=main)
SpellInfo(felblade tag=main)
SpellInfo(sigil_of_flame tag=main)
SpellInfo(vengeful_retreat tag=main)

]]
    OvaleScripts:RegisterScript("DEMONHUNTER", nil, name, desc, code, "include")
end
