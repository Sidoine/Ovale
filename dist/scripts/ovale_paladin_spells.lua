local __exports = LibStub:NewLibrary("ovale/scripts/ovale_paladin_spells", 80300)
if not __exports then return end
__exports.registerPaladinSpells = function(OvaleScripts)
    local name = "ovale_paladin_spells"
    local desc = "[9.0] Ovale: Paladin spells"
    local code = [[Define(arcane_torrent_0 25046)
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
Define(avenging_wrath 31884)
# Call upon the Light to become an avatar of retribution, increasing your damage, healing, and critical strike chance by s1 for 20 seconds.
# Rank 3: Effects increased s1.
  SpellInfo(avenging_wrath cd=180 duration=20 gcd=0 offgcd=1)
  # Damage, healing, and critical strike chance increased by w1.
  SpellAddBuff(avenging_wrath avenging_wrath=1)
Define(blade_of_justice 184575)
# Pierces an enemy with a blade of light, dealing s1 Physical damage.rnrn|cFFFFFFFFGenerates s2 Holy Power.|r
# Rank 2: Generates s1 additional Holy Power.
  SpellInfo(blade_of_justice cd=12 holypower=-1)
Define(consecration_0 327980)
# Cooldown reduced by s1.
  SpellInfo(consecration_0 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(consecration_0 consecration_0=1)
Define(consecration_1 344172)
# Damage taken is reduced by s1 while inside your Consecration.
  SpellInfo(consecration_1 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(consecration_1 consecration_1=1)
Define(crusade 231895)
# Call upon the Light and begin a crusade, increasing your damage done and haste by <damage> for 25 seconds.rnrnEach Holy Power spent during Crusade increases damage done and haste by an additional <damage>.rnrnMaximum u stacks.
  SpellInfo(crusade cd=20 charge_cd=120 duration=25 max_stacks=10 gcd=0 offgcd=1 talent=crusade_talent)
  # ?a206338[Damage done increased by w1.rnHaste increased by w3.][Damage done and haste increased by <damage>.]
  SpellAddBuff(crusade crusade=1)
Define(crusader_strike_0 231667)
# Crusader Strike now has s1+1 charges.
  SpellInfo(crusader_strike_0 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(crusader_strike_0 crusader_strike_0=1)
Define(crusader_strike_1 342348)
# Crusader Strike mana cost reduced by s1.
  SpellInfo(crusader_strike_1 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(crusader_strike_1 crusader_strike_1=1)
Define(divine_purpose 223819)
# Holy Power abilities have a s1 chance to make your next Holy Power ability free and deal 223819s2 increased damage and healing.
  SpellInfo(divine_purpose duration=12 channel=12 gcd=0 offgcd=1)
  # Your next Holy Power ability is free and deals s2 increased damage and healing.
  SpellAddBuff(divine_purpose divine_purpose=1)
Define(divine_storm 53385)
# Unleashes a whirl of divine energy, dealing s1 Holy damage to up to s2 nearby enemies.
  SpellInfo(divine_storm holypower=3)
Define(divine_toll 304971)
# Instantly cast Holy Shock, Avenger's Shield, or Judgment on up to s1 targets within A2 yds (based on your current specialization).
  SpellInfo(divine_toll cd=60)
Define(empyrean_power_buff_0 286392)
# Your attacks have a chance to make your next Divine Storm free and deal s1 additional damage.
  SpellInfo(empyrean_power_buff_0 channel=-0.001 gcd=0 offgcd=1)

Define(empyrean_power_buff_1 326733)
# Crusader Strike has a s1 chance to make your next Divine Storm free and deal 326733s1 additional damage.
  SpellInfo(empyrean_power_buff_1 duration=15 channel=15 gcd=0 offgcd=1)
  # Your next Divine Storm is free and deals w1 additional damage.
  SpellAddBuff(empyrean_power_buff_1 empyrean_power_buff_1=1)
Define(execution_sentence 343527)
# A hammer slowly falls from the sky upon the target. After 8 seconds, they suffer s1*<mult> Holy damage, plus s2 of damage taken from your abilities in that time.
  SpellInfo(execution_sentence holypower=3 cd=60 duration=8 tick=8 talent=execution_sentence_talent)
  # Sentenced to suffer w1 Holy damage.
  SpellAddTargetDebuff(execution_sentence execution_sentence=1)
Define(final_reckoning 343721)
# Call down a blast of heavenly energy, dealing s2 Holy damage to all targets in the target area and causing them to take s3 increased damage from your Holy Power abilities for 8 seconds.rnrn|cFFFFFFFFPassive:|r While off cooldown, your attacks have a high chance to call down a bolt that deals 343724s1 Holy damage and causes the target to take 343724s2 increased damage from your next Holy Power ability.
  SpellInfo(final_reckoning cd=60 duration=8 talent=final_reckoning_talent)
  # Taking w3 increased damage from @auracaster's Holy Power abilities.
  SpellAddTargetDebuff(final_reckoning final_reckoning=1)
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

Define(hammer_of_justice 853)
# Stuns the target for 6 seconds.
  SpellInfo(hammer_of_justice cd=60 duration=6)
  # Stunned.
  SpellAddTargetDebuff(hammer_of_justice hammer_of_justice=1)
Define(hammer_of_wrath 24275)
# Hurls a divine hammer that strikes an enemy for s1 Holy damage. Only usable on enemies that have less than 20 health?s326730[, or during Avenging Wrath][].rnrn|cFFFFFFFFGenerates s2 Holy Power.
# Rank 2: Hammer of Wrath may be used on any target during Avenging Wrath.
  SpellInfo(hammer_of_wrath cd=7.5 holypower=-1)
Define(holy_avenger 105809)
# Your Holy Power generation is tripled for 20 seconds.
  SpellInfo(holy_avenger cd=180 duration=20 gcd=0 offgcd=1 talent=holy_avenger_talent)
  # Your Holy Power generation is tripled.
  SpellAddBuff(holy_avenger holy_avenger=1)
Define(judgment_0 231663)
# Judgment causes the target to take s1 increased damage from your next Holy Power ability.
  SpellInfo(judgment_0 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(judgment_0 judgment_0=1)
Define(judgment_1 315867)
# Judgment generates 220637s1 Holy Power.
  SpellInfo(judgment_1 channel=0 gcd=0 offgcd=1)
  SpellAddBuff(judgment_1 judgment_1=1)
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
Define(rebuke 96231)
# Interrupts spellcasting and prevents any spell in that school from being cast for 4 seconds.
  SpellInfo(rebuke cd=15 duration=4 gcd=0 offgcd=1 interrupt=1)
Define(reckless_force_buff_0 298409)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 4 seconds.
  SpellInfo(reckless_force_buff_0 max_stacks=5 gcd=0 offgcd=1 tick=10)
  # Gaining unstable Azerite energy.
  SpellAddBuff(reckless_force_buff_0 reckless_force_buff_0=1)
Define(reckless_force_buff_1 304038)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 4 seconds.
  SpellInfo(reckless_force_buff_1 channel=-0.001 gcd=0 offgcd=1)
  SpellAddBuff(reckless_force_buff_1 reckless_force_buff_1=1)
Define(seething_rage 297126)
# Increases your critical hit damage by 297126m for 5 seconds.
  SpellInfo(seething_rage duration=5 gcd=0 offgcd=1)
  # Critical strike damage increased by w1.
  SpellAddBuff(seething_rage seething_rage=1)
Define(seraphim 152262)
# The Light magnifies your power for 15 seconds, granting s1 Haste, Critical Strike, and Versatility, and ?c1[s4*183997bc1]?c2[s4*76671bc1][s4*267316bc1] Mastery.
  SpellInfo(seraphim holypower=3 cd=45 duration=15 talent=seraphim_talent)
  # Haste, Critical Strike, and Versatility increased by s1, and Mastery increased by ?c1[s4*183997bc1]?c2[s4*76671bc1][s4*267316bc1].
  SpellAddBuff(seraphim seraphim=1)
Define(shield_of_vengeance 184662)
# Creates a barrier of holy light that absorbs <shield> damage for 15 seconds.rnrnWhen the shield expires, it bursts to inflict Holy damage equal to the total amount absorbed, divided among all nearby enemies.
  SpellInfo(shield_of_vengeance cd=120 duration=15)
  # Absorbs w1 damage and deals damage when the barrier fades or is fully consumed.
  SpellAddBuff(shield_of_vengeance shield_of_vengeance=1)
Define(templars_verdict 85256)
# Unleashes a powerful weapon strike that deals 224266s1 Holy damage to an enemy target.
  SpellInfo(templars_verdict holypower=3)
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
Define(vanquishers_hammer 328204)
# Throws a hammer at your target dealing (170 of Spell Power) Shadow damage, and empowering your next ?c3[Templar's Verdict to automatically trigger Divine Storm]?c1[Word of Glory to automatically trigger Light of Dawn][Word of Glory to automatically trigger Shield of the Righteous].
  SpellInfo(vanquishers_hammer holypower=1 cd=30 duration=15)
  # Your next ?c3[Templar's Verdict automatically triggers Divine Storm]?c1[Word of Glory automatically triggers Light of Dawn][Word of Glory automatically triggers Shield of the Righteous].
  SpellAddBuff(vanquishers_hammer vanquishers_hammer=1)
Define(wake_of_ashes 255937)
# Lash out at your enemies, dealing s1 Radiant damage to all enemies within a1 yd in front of you and reducing their movement speed by s2 for 5 seconds. Damage reduced on secondary targets.rnrnDemon and Undead enemies are also stunned for 5 seconds.rnrn|cFFFFFFFFGenerates s3 Holy Power.
  SpellInfo(wake_of_ashes cd=45 duration=5 holypower=-3)
  # Movement speed reduced by s2.
  SpellAddTargetDebuff(wake_of_ashes wake_of_ashes=1)
Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp=1)
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
SpellList(arcane_torrent arcane_torrent_0 arcane_torrent_1 arcane_torrent_2 arcane_torrent_3 arcane_torrent_4 arcane_torrent_5 arcane_torrent_6 arcane_torrent_7 arcane_torrent_8)
SpellList(consecration consecration_0 consecration_1)
SpellList(crusader_strike crusader_strike_0 crusader_strike_1)
SpellList(empyrean_power_buff empyrean_power_buff_0 empyrean_power_buff_1)
SpellList(fireblood fireblood_0 fireblood_1)
SpellList(focused_azerite_beam focused_azerite_beam_0 focused_azerite_beam_1 focused_azerite_beam_2 focused_azerite_beam_3)
SpellList(guardian_of_azeroth guardian_of_azeroth_0 guardian_of_azeroth_1 guardian_of_azeroth_2 guardian_of_azeroth_3 guardian_of_azeroth_4 guardian_of_azeroth_5)
SpellList(judgment judgment_0 judgment_1)
SpellList(memory_of_lucid_dreams memory_of_lucid_dreams_0 memory_of_lucid_dreams_1 memory_of_lucid_dreams_2)
SpellList(purifying_blast purifying_blast_0 purifying_blast_1 purifying_blast_2 purifying_blast_3 purifying_blast_4 purifying_blast_5)
SpellList(razor_coral razor_coral_0 razor_coral_1 razor_coral_2 razor_coral_3 razor_coral_4)
SpellList(reckless_force_buff reckless_force_buff_0 reckless_force_buff_1)
SpellList(the_unbound_force the_unbound_force_0 the_unbound_force_1 the_unbound_force_2 the_unbound_force_3)
SpellList(worldvein_resonance worldvein_resonance_0 worldvein_resonance_1 worldvein_resonance_2 worldvein_resonance_3)
Define(crusade_talent 20) #22215
# Call upon the Light and begin a crusade, increasing your damage done and haste by <damage> for 25 seconds.rnrnEach Holy Power spent during Crusade increases damage done and haste by an additional <damage>.rnrnMaximum u stacks.
Define(execution_sentence_talent 3) #23467
# A hammer slowly falls from the sky upon the target. After 8 seconds, they suffer s1*<mult> Holy damage, plus s2 of damage taken from your abilities in that time.
Define(final_reckoning_talent 21) #22634
# Call down a blast of heavenly energy, dealing s2 Holy damage to all targets in the target area and causing them to take s3 increased damage from your Holy Power abilities for 8 seconds.rnrn|cFFFFFFFFPassive:|r While off cooldown, your attacks have a high chance to call down a bolt that deals 343724s1 Holy damage and causes the target to take 343724s2 increased damage from your next Holy Power ability.
Define(holy_avenger_talent 14) #17599
# Your Holy Power generation is tripled for 20 seconds.
Define(seraphim_talent 15) #17601
# The Light magnifies your power for 15 seconds, granting s1 Haste, Critical Strike, and Versatility, and ?c1[s4*183997bc1]?c2[s4*76671bc1][s4*267316bc1] Mastery.
    ]]
    OvaleScripts:RegisterScript("PALADIN", nil, name, desc, code, "include")
end
