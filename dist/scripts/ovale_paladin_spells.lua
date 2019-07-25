local __exports = LibStub:NewLibrary("ovale/scripts/ovale_paladin_spells", 80201)
if not __exports then return end
__exports.registerPaladinSpells = function(OvaleScripts)
    local name = "ovale_paladin_spells"
    local desc = "[8.2] Ovale: Paladin spells"
    local code = [[Define(avengers_shield 31935)
# Hurls your shield at an enemy target, dealing s1 Holy damage?a231665[, interrupting and silencing the non-Player target for 3 seconds][], and then jumping to x1-1 additional nearby enemies.rnrnIncreases the effects of your next Shield of the Righteous by 197561s2.
# Rank 2: Avenger's Shield interrupts and silences the main target for 3 seconds if it is not a player.
  SpellInfo(avengers_shield cd=15 duration=3 interrupt=1)

  # Silenced.
  SpellAddTargetDebuff(avengers_shield avengers_shield=1)
Define(avenging_wrath 31884)
# Call upon the Light to become an avatar of retribution, increasing your damage, healing, and critical strike chance by s1 for 20 seconds. Your first ?c1[Holy Shock]?c3[Templar's Verdict or Divine Storm][Light of the Protector] will critically strike.
  SpellInfo(avenging_wrath cd=120 duration=20)
  # Damage, healing, and critical strike chance increased by w1.
  SpellAddBuff(avenging_wrath avenging_wrath=1)
Define(bastion_of_light 204035)
# Immediately grants s1 charges of Shield of the Righteous.
  SpellInfo(bastion_of_light cd=120 gcd=0 offgcd=1 talent=bastion_of_light_talent)
Define(blade_of_justice 184575)
# Pierces an enemy with a blade of light, dealing s2*<mult> Physical damage.rnrn|cFFFFFFFFGenerates s3 Holy Power.|r
  SpellInfo(blade_of_justice cd=10.5 holypower=-2)
Define(blessed_hammer 229976)
# Throws a Blessed Hammer that spirals outward, dealing 204301s1 Holy damage to enemies and weakening them, reducing the damage you take from their next auto attack by 204301s2.
  SpellInfo(blessed_hammer channel=0 gcd=0 offgcd=1)
  SpellAddBuff(blessed_hammer blessed_hammer=1)
Define(blinding_light 115750)
# Emits dazzling light in all directions, blinding enemies within 105421A1 yards, causing them to wander disoriented for 105421d. Non-Holy damage will break the disorient effect.
  SpellInfo(blinding_light cd=90 duration=6 talent=blinding_light_talent)
  SpellAddBuff(blinding_light blinding_light=1)
Define(blood_of_the_enemy 297108)
# The Heart of Azeroth erupts violently, dealing s1 Shadow damage to enemies within A1 yds. You gain m2 critical strike chance against the targets for 10 seconds?a297122[, and increases your critical hit damage by 297126m for 5 seconds][].
  SpellInfo(blood_of_the_enemy cd=120 duration=10 channel=10)
  # You have a w2 increased chance to be Critically Hit by the caster.
  SpellAddTargetDebuff(blood_of_the_enemy blood_of_the_enemy=1)
Define(bloodlust 2825)
# Increases Haste by (25 of Spell Power) for all party and raid members for 40 seconds.rnrnAllies receiving this effect will become Sated and unable to benefit from Bloodlust or Time Warp again for 600 seconds.
  SpellInfo(bloodlust cd=300 duration=40 channel=40 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(bloodlust bloodlust=1)
Define(consecration 26573)
# Consecrates the land beneath you, causing 81297s1*9 Holy damage over 12 seconds to enemies who enter the area. Limit s2.
  SpellInfo(consecration cd=4.5 duration=12 tick=1)
  # Damage every t1 sec.
  SpellAddBuff(consecration consecration=1)
Define(crusade 231895)
# Call upon the Light and begin a crusade, increasing your damage done and Haste by <damage> for 25 seconds.rnrnEach Holy Power spent during Crusade increases damage done and Haste by an additional <damage>.rnrnMaximum u stacks.
  SpellInfo(crusade cd=20 charge_cd=120 duration=25 max_stacks=10 talent=crusade_talent)
  # ?a206338[Damage done increased by w1.rnHaste increased by w3.][Damage done and Haste increased by <damage>.]
  SpellAddBuff(crusade crusade=1)
Define(crusader_strike 35395)
# Strike the target for s1 Physical damage.?s137027[rnrn|cFFFFFFFFGenerates s2 Holy Power.][]
# Rank 2: Crusader Strike now has s1+1 charges.
  SpellInfo(crusader_strike cd=6 holypower=0)
Define(divine_storm 53385)
# Unleashes a whirl of divine energy, dealing 224239sw1 Holy damage to all nearby enemies.
  SpellInfo(divine_storm holypower=3)
Define(empyrean_power_buff 286392)
# Your attacks have a chance to make your next Divine Storm free and deal s1 additional damage.
  SpellInfo(empyrean_power_buff channel=-0.001 gcd=0 offgcd=1)

Define(execution_sentence 267798)
# Calls down the Light's punishment upon an enemy target, dealing s1 Holy damage and increasing the target's Holy damage taken from your attacks by 267799s1 for 12 seconds.
  SpellInfo(execution_sentence holypower=3 cd=30 talent=execution_sentence_talent)

Define(fireblood 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. ?s195710[This effect shares a 30 sec cooldown with other similar effects.][]
  SpellInfo(fireblood cd=120 gcd=0 offgcd=1)
Define(focused_azerite_beam 295262)
# Reduces the cast time of Focused Azerite Beam by s1.
  SpellInfo(focused_azerite_beam channel=0 gcd=0 offgcd=1)
  SpellAddBuff(focused_azerite_beam focused_azerite_beam=1)
Define(guardian_of_azeroth 295840)
# Call upon Azeroth to summon a Guardian of Azeroth for 30 seconds who impales your target with spikes of Azerite every 2 sec that deal 295834m1*(1+@versadmg) Fire damage.?a295841[ Every 303347t1 sec, the Guardian launches a volley of Azerite Spikes at its target, dealing 295841s1 Fire damage to all nearby enemies.][]?a295843[rnrnEach time the Guardian of Azeroth casts a spell, you gain 295855s1 Haste, stacking up to 295855u times. This effect ends when the Guardian of Azeroth despawns.][]rn
  SpellInfo(guardian_of_azeroth cd=180 duration=30)
  SpellAddBuff(guardian_of_azeroth guardian_of_azeroth=1)
Define(hammer_of_justice 853)
# Stuns the target for 6 seconds.
  SpellInfo(hammer_of_justice cd=60 duration=6)
  # Stunned.
  SpellAddTargetDebuff(hammer_of_justice hammer_of_justice=1)
Define(hammer_of_the_righteous 53595)
# Hammers the current target for 53595sw1 Physical damage.?s26573&s203785[rnrnHammer of the Righteous also causes a wave of light that hits all other targets within 88263A1 yds for 88263sw1 Holy damage.]?s26573[rnrnWhile you are standing in your Consecration, Hammer of the Righteous also causes a wave of light that hits all other targets within 88263A1 yds for 88263sw1 Holy damage.][]
  SpellInfo(hammer_of_the_righteous cd=4.5)
  SpellInfo(crusader_strike replaced_by=hammer_of_the_righteous)
Define(hammer_of_wrath 24275)
# Hurls a divine hammer that strikes an enemy for s1 Holy damage. Only usable on enemies that have less than 20 health, or while you are empowered by ?s231895[Crusade][Avenging Wrath].rnrn|cFFFFFFFFGenerates s2 Holy Power.
  SpellInfo(hammer_of_wrath cd=7.5 holypower=-1 talent=hammer_of_wrath_talent)
Define(inquisition 84963)
# Consumes up to 3 Holy Power to increase your damage done and Haste by s1.rnrnLasts 15 seconds per Holy Power consumed.
  SpellInfo(inquisition holypower=1 duration=15 tick=15 talent=inquisition_talent)
  # Damage done increased by w1.rnHaste increased by w3.
  SpellAddBuff(inquisition inquisition=1)
Define(judgment 20271)
# Judges the target, dealing (95 of Spell Power) Holy damage?s231663[, and causing them to take 197277s1 increased damage from your next ability that costs Holy Power.][]?s137027[rnrn|cFFFFFFFFGenerates 220637s1 Holy Power.][]
# Rank 2: Judgment causes the target to take s1 increased damage from your next Holy Power spender.
  SpellInfo(judgment cd=12)
Define(judgment_protection 275779)
# Judges the target, dealing (112.5 of Spell Power) Holy damage?a231657[, and reducing the remaining cooldown on Shield of the Righteous by 231657s1 sec, or 231657s1*2 sec on a critical strike][].
  SpellInfo(judgment_protection cd=12)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)

Define(purifying_blast 295337)
# Call down a purifying beam upon the target area, dealing 295293s3*(1+@versadmg)*s2 Fire damage over 6 seconds.?a295364[ Has a low chance to immediately annihilate any specimen deemed unworthy by MOTHER.][]?a295352[rnrnWhen an enemy dies within the beam, your damage is increased by 295354s1 for 8 seconds.][]rnrnAny Aberration struck by the beam is stunned for 3 seconds.
  SpellInfo(purifying_blast cd=60 duration=6)
Define(rebuke 96231)
# Interrupts spellcasting and prevents any spell in that school from being cast for 4 seconds.
  SpellInfo(rebuke cd=15 duration=4 gcd=0 offgcd=1 interrupt=1)
Define(reckless_force_buff 298409)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 3 seconds.
  SpellInfo(reckless_force_buff max_stacks=5 gcd=0 offgcd=1 tick=10)
  # Gaining unstable Azerite energy.
  SpellAddBuff(reckless_force_buff reckless_force_buff=1)
Define(seething_rage 297126)
# Increases your critical hit damage by 297126m for 5 seconds.
  SpellInfo(seething_rage duration=5 gcd=0 offgcd=1)
  # Critical strike damage increased by w1.
  SpellAddBuff(seething_rage seething_rage=1)
Define(seraphim 152262)
# The Light temporarily magnifies your power, increasing your Haste, Critical Strike, Mastery, and Versatility by s1.rnrnConsumes up to s2 charges of Shield of the Righteous, and lasts 8 seconds per charge.
  SpellInfo(seraphim cd=45 duration=8 talent=seraphim_talent)
  # Haste, Critical Strike, Mastery, and Versatility increased by s1.
  SpellAddBuff(seraphim seraphim=1)
Define(shield_of_the_righteous 53600)
# Slams enemies in front of you with your shield, causing s1 Holy damage, and increasing your Armor by 132403s1*STR/100 for 4.5 seconds.
  SpellInfo(shield_of_the_righteous cd=1 charge_cd=18 gcd=0 offgcd=1)
Define(shield_of_vengeance 184662)
# Creates a barrier of holy light that absorbs s2/100*MHP damage for 15 seconds.rnrnWhen the shield expires, it bursts to inflict Holy damage equal to the total amount absorbed, divided among all nearby enemies.
  SpellInfo(shield_of_vengeance cd=120 duration=15)
  # Absorbs w1 damage and deals damage when the barrier fades or is fully consumed.
  SpellAddBuff(shield_of_vengeance shield_of_vengeance=1)
Define(templars_verdict 85256)
# Unleashes a powerful weapon strike that deals 224266sw1*<mult> Holy damage to an enemy target.
  SpellInfo(templars_verdict holypower=3)
Define(the_unbound_force 298452)
# Unleash the forces within the Heart of Azeroth, causing shards of Azerite to strike your target for (298407s3*((2 seconds/t)+1)+298407s3) Fire damage over 2 seconds. This damage is increased by s2 if it critically strikes.?a298456[rnrnEach time The Unbound Force causes a critical strike, it immediately strikes the target with an additional Azerite shard, up to a maximum of 298456m2.][]
  SpellInfo(the_unbound_force cd=60 duration=2 channel=2 tick=0.33)
  SpellAddBuff(the_unbound_force the_unbound_force=1)
  SpellAddTargetDebuff(the_unbound_force the_unbound_force=1)
Define(wake_of_ashes 255937)
# Lash out at your enemies, dealing sw1 Radiant damage to all enemies within a1 yd in front of you and reducing their movement speed by s2 for 5 seconds.rnrnDemon and Undead enemies are also stunned for 5 seconds.rnrn|cFFFFFFFFGenerates s3 Holy Power.
  SpellInfo(wake_of_ashes cd=45 duration=5 holypower=-5 talent=wake_of_ashes_talent)
  # Movement speed reduced by s2.
  SpellAddTargetDebuff(wake_of_ashes wake_of_ashes=1)
Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp=1)
Define(bastion_of_light_talent 6) #22594
# Immediately grants s1 charges of Shield of the Righteous.
Define(blinding_light_talent 9) #21811
# Emits dazzling light in all directions, blinding enemies within 105421A1 yards, causing them to wander disoriented for 105421d. Non-Holy damage will break the disorient effect.
Define(crusade_talent 20) #22215
# Call upon the Light and begin a crusade, increasing your damage done and Haste by <damage> for 25 seconds.rnrnEach Holy Power spent during Crusade increases damage done and Haste by an additional <damage>.rnrnMaximum u stacks.
Define(crusaders_judgment_talent 5) #22604
# Judgment now has 1+s1 charges, and Grand Crusader now also grants a charge of Judgment.
Define(execution_sentence_talent 3) #22175
# Calls down the Light's punishment upon an enemy target, dealing s1 Holy damage and increasing the target's Holy damage taken from your attacks by 267799s1 for 12 seconds.
Define(hammer_of_wrath_talent 6) #22593
# Hurls a divine hammer that strikes an enemy for s1 Holy damage. Only usable on enemies that have less than 20 health, or while you are empowered by ?s231895[Crusade][Avenging Wrath].rnrn|cFFFFFFFFGenerates s2 Holy Power.
Define(inquisition_talent 21) #22634
# Consumes up to 3 Holy Power to increase your damage done and Haste by s1.rnrnLasts 15 seconds per Holy Power consumed.
Define(righteous_verdict_talent 2) #22557
# Templar's Verdict increases the damage of your next Templar's Verdict by 267611s1 for 6 seconds.
Define(seraphim_talent 21) #22645
# The Light temporarily magnifies your power, increasing your Haste, Critical Strike, Mastery, and Versatility by s1.rnrnConsumes up to s2 charges of Shield of the Righteous, and lasts 8 seconds per charge.
Define(wake_of_ashes_talent 12) #22183
# Lash out at your enemies, dealing sw1 Radiant damage to all enemies within a1 yd in front of you and reducing their movement speed by s2 for 5 seconds.rnrnDemon and Undead enemies are also stunned for 5 seconds.rnrn|cFFFFFFFFGenerates s3 Holy Power.
    ]]
    code = code .. [[
# Items
Define(heathcliffs_immortality 137047)
Define(pillars_of_inmost_light 151812)

Define(liadrins_fury_unleashed_buff 208410)
Define(scarlet_inquisitors_expurgation_buff 248289)

ItemRequire(shifting_cosmic_sliver unusable 1=oncooldown,!guardian_of_ancient_kings,buff,!guardian_of_ancient_kings_buff)	
	
# Paladin spells and functions.

# Learned spells.
Define(aegis_of_light 204150)
	SpellInfo(aegis_of_light cd=180)
	SpellAddBuff(aegis_of_light aegis_of_light_buff=1)
Define(aegis_of_light_buff 204150)
	SpellInfo(aegis_of_light_buff duration=6)
Define(ardent_defender 31850)
	SpellInfo(ardent_defender cd=120 gcd=0 offgcd=1)
	SpellInfo(ardent_defender add_cd=-36 talent=unbreakable_spirit_talent)
	SpellAddBuff(ardent_defender ardent_defender_buff=1)
Define(ardent_defender_buff 31850)
	SpellInfo(ardent_defender_buff duration=8)
Define(aura_mastery 31821)
	SpellInfo(aura_mastery cd=180)
Define(avengers_reprieve_buff 185676)
	SpellInfo(avengers_reprieve_buff duration=10)

	SpellInfo(avengers_shield cd=15 cd_haste=melee travel_time=1)
	SpellAddBuff(avengers_shield avengers_valor_buff=1)
	SpellAddBuff(avengers_shield avengers_reprieve_buff=1 itemset=T18 itemcount=2 specialization=protection)
	SpellAddBuff(avengers_shield grand_crusader_buff=0 if_spell=grand_crusader)
	SpellAddBuff(avengers_shield faith_barricade_buff=1 itemset=T17 itemcount=2 specialization=protection)
Define(avengers_valor_buff 197561)
	SpellInfo(avengers_valor_buff duration=15)
Define(avenging_crusader 216331)
	SpellInfo(avenging_crusader cd=120)
Define(avenging_crusader_buff 216331)
	SpellInfo(avenging_crusader_buff duration=20)
	SpellAddBuff(avenging_crusader avenging_crusader_buff=1)

	SpellInfo(avenging_wrath cd=120)
	SpellInfo(avenging_wrath replaced_by=crusade talent=crusade_talent specialization=retribution)
	SpellInfo(avenging_wrath replaced_by=avenging_crusader talent=avenging_crusader_talent specialization=holy)
	SpellAddBuff(avenging_wrath avenging_wrath_buff=1)
Define(avenging_wrath_autocrit_buff 294027)
	SpellAddBuff(avenging_wrath avenging_wrath_autocrit_buff=1)
	SpellAddBuff(templars_verdict avenging_wrath_autocrit_buff=-1)
	SpellAddBuff(divine_storm avenging_wrath_autocrit_buff=-1)
	SpellAddBuff(holy_shock avenging_wrath_autocrit_buff=-1)
	SpellAddBuff(light_of_the_protector avenging_wrath_autocrit_buff=-1)
Define(avenging_wrath_buff 31884)
	SpellInfo(avenging_wrath_buff duration=20)
	SpellInfo(avenging_wrath_buff add_duration=5 talent=sanctified_wrath_talent specialization=holy)

	SpellInfo(bastion_of_light cd=120 gcd=0 offgcd=1)
Define(bastion_of_power_buff 144569)
	SpellInfo(bastion_of_power_buff duration=20)
Define(beacon_of_faith 53563)
	SpellInfo(beacon_of_faith gcd=1)
	SpellAddTargetBuff(beacon_of_faith beacon_of_faith_buff=1)
Define(beacon_of_faith_buff 53563)
Define(beacon_of_light 53563)
	SpellInfo(beacon_of_light cd=3)
	SpellAddTargetBuff(beacon_of_light beacon_of_light_buff=1)
Define(beacon_of_light_buff 53563)
Define(beacon_of_virtue 200025)
	SpellInfo(beacon_of_virtue cd=15)
Define(bestow_faith 223306)
	SpellInfo(bestow_faith cd=12)

	SpellInfo(blade_of_justice holypower=-2 cd=11 cd_haste=melee)
	SpellInfo(blade_of_justice add_holypower=-1 itemset=T20 itemcount=4)
	SpellRequire(blade_of_justice cd 0=buff,blade_of_wrath_buff)
	SpellAddBuff(blade_of_justice blade_of_wrath_buff=0)
Define(blade_of_wrath_buff 281178)
	SpellInfo(blade_of_wrath_buff duration=10)
Define(blazing_contempt_buff 166831)
	SpellInfo(blazing_contempt_buff duration=20)
Define(blessed_hammer 204019)
	SpellInfo(blessed_hammer cd=4.5 cd_haste=melee max_charges=3)
Define(blessed_hammer_debuff 204301)
	SpellInfo(blessed_hammer_debuff duration=10)
Define(blessing_of_freedom 1044)
	SpellInfo(blessing_of_freedom cd=25)
	SpellAddBuff(blessing_of_freedom blessing_of_freedom_buff=1)
Define(blessing_of_freedom_buff 1044)
	SpellInfo(blessing_of_freedom_buff duration=8)
Define(blessing_of_protection 1022)
	SpellInfo(blessing_of_protection cd=300)
	SpellRequire(blessing_of_protection unusable 1=debuff,forbearance_debuff)
Define(blessing_of_protection_buff 1022)
	SpellInfo(blessing_of_protection_buff duration=10)
Define(blessing_of_sacrifice 6940)
	SpellInfo(blessing_of_sacrifice cd=120)
Define(blessing_of_spellwarding 204018)
	SpellInfo(blessing_of_spellwarding cd=180)
	SpellRequire(blessing_of_spellwarding unusable 1=debuff,forbearance_debuff)
Define(blessing_of_spellwarding_buff 204018)
	SpellInfo(blessing_of_spellwarding_buff duration=10)

	SpellInfo(blinding_light cd=90 interrupt=1 tag=cd)
Define(cleanse 4987)
	SpellInfo(cleanse cd=8)
Define(cleanse_toxins 213644)
	SpellInfo(cleanse_toxins cd=8)

	SpellInfo(consecration cd=4.5 tag=main cd_haste=melee specialization=protection)
	SpellInfo(consecration cd=4.5 tag=main cd_haste=spell specialization=holy)
	SpellAddTargetDebuff(consecration consecration_debuff=1)
Define(consecration_buff 188370)
Define(consecration_debuff 204242)
	SpellInfo(consecration_debuff duration=12)
Define(consecration_retribution 205228)
	SpellInfo(crusade cd=120)
	SpellAddBuff(crusade crusade_buff=1)
Define(crusade_buff 231895)
	SpellInfo(crusade_buff duration=30 max_stacks=15)

	SpellInfo(crusader_strike cd=6 max_charges=2)
	SpellInfo(crusader_strike cd_haste=melee specialization=retribution)
	SpellInfo(crusader_strike cd_haste=spell specialization=holy)
	SpellInfo(crusader_strike cd=5.1 talent=fires_of_justice_talent specialization=retribution)
	SpellRequire(crusader_strike cd 4.2=buff,avenging_crusader_buff talent=avenging_crusader_talent)
Define(crusaders_fury_buff 165442)
	SpellInfo(crusaders_fury_buff duration=10)
Define(defender_of_the_light_buff 167742)
	SpellInfo(defender_of_the_light_buff duration=8)
Define(divine_crusader_buff 144595)
	SpellInfo(divine_crusader_buff duration=12)
Define(divine_judgment_buff 271851)
	SpellInfo(divine_judgment_buff duration=15 max_stacks=15)
Define(divine_protection 498)
	SpellInfo(divine_protection cd=60 gcd=0 offgcd=1 tag=cd)
	SpellInfo(divine_protection add_cd=-18 talent=unbreakable_spirit_talent_holy)
	SpellInfo(divine_protection replaced_by=ardent_defender level=50)
	SpellAddBuff(divine_protection divine_protection_buff=1)
Define(divine_protection_buff 498)
	SpellInfo(divine_protection_buff duration=8)
Define(divine_purpose 223817)
Define(divine_purpose_buff 223819)
	SpellInfo(divine_purpose_buff duration=12)
Define(divine_purpose_buff_holy 216411)
	SpellInfo(divine_purpose_buff_holy duration=10)
Define(divine_shield 642)
	SpellInfo(divine_shield cd=300)
	SpellInfo(divine_shield add_cd=-90 talent=unbreakable_spirit_talent specialization=!holy)
	SpellInfo(divine_shield add_cd=-90 talent=unbreakable_spirit_talent_holy specialization=holy)
	SpellAddBuff(divine_shield divine_shield_buff=1)
	SpellRequire(divine_shield unusable 1=debuff,forbearance_debuff)
Define(divine_shield_buff 642)
	SpellInfo(divine_shield_buff duration=8)
Define(divine_steed 190784)
	SpellInfo(divine_steed cd=45 tag=cd)
	SpellInfo(divine_steed max_charges=2 talent=cavalier_talent specialization=!holy)
	SpellInfo(divine_steed max_charges=2 talent=cavalier_talent_holy specialization=holy)
	SpellAddBuff(divine_steed divine_steed_buff=1)
Define(divine_steed_buff 221886)
	SpellInfo(divine_steed_buff duration=3)

	
	SpellRequire(divine_storm holypower_percent 0=buff,divine_storm_no_holy_buff)
	SpellInfo(divine_storm add_holypower -1=buff,hp_cost_reductino_buff)
	SpellAddBuff(divine_storm divine_crusader_buff=0)
	SpellAddBuff(divine_storm divine_purpose_buff=0 if_spell=divine_purpose)
	SpellAddBuff(divine_storm final_verdict_buff=0 if_spell=final_verdict)
	SpellAddBuff(divine_storm divine_judgment_buff=1 talent=divine_judgment_talent)
SpellList(divine_storm_no_holy_buff divine_crusader_buff divine_purpose_buff)

	SpellInfo(execution_sentence cd=30 holypower=3 tag=main)
	SpellInfo(execution_sentence add_holypower -1=buff,hp_cost_reductino_buff)
	SpellAddBuff(execution_sentence selfless_healer_buff=1 talent=selfless_healer_talent)
	
	SpellAddBuff(execution_sentence divine_judgment_buff=1 talent=divine_judgment_talent)
Define(execution_sentence_debuff 267798)
	SpellInfo(execution_sentence_debuff duration=7)
Define(eye_for_an_eye 205191)
	SpellInfo(eye_for_an_eye cd=60)
Define(eye_for_an_eye_buff 205191)
	SpellInfo(eye_for_an_eye duration=10)
Define(eye_of_tyr 209202)
	SpellInfo(eye_of_tyr cd=60 tag=cd)
	SpellInfo(eye_of_tyr cd=45 if_equipped=pillars_of_inmost_light)
	SpellAddTargetDebuff(eye_of_tyr eye_of_tyr_debuff=1)
Define(eye_of_tyr_debuff 209202)
	SpellInfo(eye_of_tyr_debuff duration=9)
Define(faith_barricade_buff 165447)
	SpellInfo(faith_barricade_buff duration=5)
Define(final_verdict 157048)
	SpellInfo(final_verdict holypower=3)
	SpellRequire(final_verdict holypower_percent 0=buff,divine_purpose_buff if_spell=divine_purpose)
	SpellAddBuff(final_verdict divine_purpose_buff=0 if_spell=divine_purpose)
	SpellAddBuff(final_verdict final_verdict_buff=1)
	SpellAddBuff(final_verdict divine_judgment_buff=1 talent=divine_judgment_talent)
Define(final_verdict_buff 157048)
	SpellInfo(final_verdict_buff duration=30)
Define(flash_of_light 19750)
	SpellAddBuff(flash_of_light infusion_of_light_buff=-1)
	SpellAddBuff(flash_of_light selfless_healer_buff=0)
Define(forbearance_debuff 25771)
	SpellInfo(forbearance_debuff duration=30)
Define(grand_crusader 85043)
Define(grand_crusader_buff 85416)
	SpellInfo(grand_crusader_buff duration=6)
Define(greater_blessing_of_kings 203538)
	SpellAddBuff(greater_blessing_of_kings greater_blessing_of_kings_buff=1)
	SpellRequire(greater_blessing_of_kings unusable 1=buff,greater_blessing_of_kings_buff)
Define(greater_blessing_of_kings_buff 203538)
Define(greater_blessing_of_wisdom 203539)
	SpellAddBuff(greater_blessing_of_wisdom greater_blessing_of_kings_buff=1)
	SpellRequire(greater_blessing_of_wisdom unusable 1=buff,greater_blessing_of_wisdom_buff)
Define(greater_blessing_of_wisdom_buff 203539)
Define(guardian_of_ancient_kings 86659)
	SpellInfo(guardian_of_ancient_kings cd=300 gcd=0 offgcd=1)
	SpellAddBuff(guardian_of_ancient_kings guardian_of_ancient_kings_buff=1)
Define(guardian_of_ancient_kings_buff 86659)
	SpellInfo(guardian_of_ancient_kings_buff duration=8)

	SpellInfo(hammer_of_justice cd=60 interrupt=1)

	SpellInfo(hammer_of_the_righteous max_charges=2 cd=4.5 cd_haste=melee)
	SpellInfo(hammer_of_the_righteous replaced_by=blessed_hammer talent=blessed_hammer_talent)

	SpellInfo(hammer_of_wrath holypower=-1 cd=7.5 target_health_pct=20)
	SpellRequire(hammer_of_wrath target_health_pct 100=buff,hammer_of_wrath_usable_buff)
SpellList(hammer_of_wrath_usable_buff avenging_wrath crusade)
Define(hand_of_freedom 1044)
	SpellInfo(hand_of_freedom cd=25)
Define(hand_of_hindrance 183218)
	SpellInfo(hand_of_hindrance cd=30)
	SpellAddTargetDebuff(hand_of_hindrance hand_of_hindrance_debuff=1)
Define(hand_of_hindrance_debuff 183218)
	SpellInfo(hand_of_hindrance_debuff duration=10)
Define(hand_of_protection 1022)
	SpellInfo(hand_of_protection cd=300 gcd=0 offgcd=1)
	SpellAddBuff(hand_of_protection hand_of_protection_buff=1)
Define(hand_of_protection_buff 1022)
	SpellInfo(hand_of_protection_buff duration=10)
Define(hand_of_reckoning 62124)
	SpellInfo(hand_of_reckoning cd=8)
Define(hand_of_sacrifice 6940)
	SpellInfo(hand_of_sacrifice cd=120 gcd=0 offgcd=1)
	SpellAddTargetBuff(hand_of_sacrifice hand_of_sacrifice_buff=1)
Define(hand_of_sacrifice_buff 6940)
	SpellInfo(hand_of_sacrifice_buff duration=10)
Define(hand_of_the_protector 213652)
	SpellInfo(hand_of_the_protector cd=15 cd_haste=melee tag=shortcd)
	SpellInfo(hand_of_the_protector charges=2 if_equipped=saruans_resolve)
Define(harsh_word 136494)
	SpellInfo(harsh_word tag=shortcd)
Define(holy_avenger 105809)
	SpellInfo(holy_avenger cd=90)
	SpellAddBuff(holy_avenger holy_avenger_buff=1)
Define(holy_avenger_buff 105809)
	SpellInfo(holy_avenger_buff duration=20)
Define(holy_light 82326)
	SpellAddBuff(holy_light infusion_of_light_buff=-1)
Define(holy_prism 114165)
	SpellInfo(holy_prism cd=20)
Define(holy_shock 20473)
	SpellInfo(holy_shock cd=9 cd_haste=spell)
	SpellRequire(holy_shock cd 4.5=buff,avenging_wrath_buff talent=sanctified_wrath_talent)
	SpellRequire(holy_shock cd 0=buff,divine_purpose_buff_holy talent=divine_purpose_talent)
	SpellAddBuff(holy_shock divine_purpose_buff_holy=0 if_spell=divine_purpose_buff_holy)
Define(holy_wrath 210220)
	SpellInfo(holy_wrath cd=180)
Define(improved_forbearance 157482)
Define(infusion_of_light_buff 54149)
	SpellInfo(infusion_of_light_buff duration=15)

	SpellInfo(inquisition holypower=1 max_holypower=3)
Define(inquisition_buff 84963)
	SpellInfo(inquisition_buff duration=15)

	SpellInfo(judgment cd=12 cd_haste=melee holypower=-1)
	SpellAddTargetDebuff(judgment judgment_ret_debuff=1)
	SpellAddTargetDebuff(judgment zeal_debuff=3)
	SpellAddBuff(judgment sacred_judgment_buff=1 itemset=T21 itemcount=4)
Define(judgment_holy 275773)
	SpellInfo(judgment_holy cd=12 cd_haste=spell)
	SpellRequire(judgment_holy cd 8.4=buff,avenging_crusader_buff talent=avenging_crusader_talent)
	SpellAddTargetDebuff(judgment judgment_holy_debuff=1)
	SpellAddTargetDebuff(judgment judgement_of_light_debuff=25 if_spell=judgment_of_light)
Define(judgment_prot 275779)
	SpellInfo(judgment_prot cd=6 cd_haste=melee)
	SpellInfo(judgment_prot charges=2 talent=crusaders_judgment_talent)
	SpellAddTargetDebuff(judgment judgement_of_light_debuff=25 if_spell=judgment_of_light)
Define(judgment_holy_debuff 214222)
	SpellInfo(judgment_holy_debuff duration=6)
Define(judgment_of_light 183778)
Define(judgement_of_light_debuff 196941)
	SpellInfo(judgement_of_light_debuff duration=30)
Define(judgment_ret_debuff 197277)
	SpellInfo(judgment_ret_debuff duration=8)
Define(justicars_vengeance 215661)
	SpellInfo(justicars_vengeance holypower=5)
	SpellInfo(justicars_vengeance add_holypower -1=buff,hp_cost_reductino_buff)
	SpellRequire(justicars_vengeance holypower_percent 0=buff,divine_purpose_buff)
	SpellAddBuff(justicars_vengeance divine_judgment_buff=1 talent=divine_judgment_talent)
	SpellAddBuff(justicars_vengeance divine_purpose_buff=0 if_spell=divine_purpose_buff)
Define(lawful_words_buff 166780)
	SpellInfo(lawful_words_buff duration=10)
Define(lay_on_hands 633)
	SpellInfo(lay_on_hands cd=600)
	SpellInfo(lay_on_hands add_cd=-180 talent=unbreakable_spirit_talent specialization=!holy)
	SpellInfo(lay_on_hands add_cd=-180 talent=unbreakable_spirit_talent_holy specialization=holy)
	SpellRequire(lay_on_hands unusable 1=target_debuff,forbearance_debuff)
	SpellAddTargetDebuff(lay_on_hands forbearance_debuff=1)
Define(liadrins_righteousness_buff 156989)
	SpellInfo(liadrins_righteousness_buff duration=20)
Define(light_of_dawn 85222)
	SpellInfo(light_of_dawn cd=12 cd_haste=spell)
SpellList(light_of_dawn_no_holy_buff divine_purpose_buff lights_favor_buff)
Define(light_of_the_martyr 183998)
Define(light_of_the_protector 184092)
	SpellInfo(light_of_the_protector cd=15 cd_haste=melee tag=shortcd gcd=0 offgcd=1)
	SpellInfo(light_of_the_protector charges=2 if_equipped=saruans_resolve)
	SpellInfo(light_of_the_protector replaced_by=hand_of_the_protector talent=hand_of_the_protector_talent)
Define(lights_favor_buff 166781)
	SpellInfo(lights_favor_buff duration=10)
Define(lights_hammer 114158)
	SpellInfo(lights_hammer cd=60)
Define(maraads_truth_buff 156990)
	SpellInfo(maraads_truth_buff duration=20)

	SpellInfo(rebuke cd=15 gcd=0 interrupt=1 offgcd=1)
Define(redemption 7328)
Define(repentance 20066)
	SpellInfo(repentance cd=15)
Define(righteous_verdict 267610)
Define(righteous_verdict_buff 267611)
	SpellInfo(righteous_verdict_buff duration=6)
Define(rule_of_law 214202)
	SpellInfo(rule_of_law cd=30 max_charges=2)
Define(rule_of_law_buff 214202)
	SpellInfo(rule_of_law duration=10)
Define(sacred_shield 20925)
	SpellInfo(sacred_shield cd=6)
	SpellAddBuff(sacred_shield sacred_shield_buff=1)
Define(sacred_shield_buff 20925)
	SpellInfo(sacred_shield duration=30 haste=spell tick=6)
Define(saruans_resolve 144275)
Define(selfless_healer 85804)
Define(selfless_healer_buff 114250)
	SpellInfo(selfless_healer_buff duration=15 max_stacks=3)

	SpellInfo(seraphim cd=45)
Define(seraphim_buff 152262)
	SpellInfo(seraphim_buff duration=16)

	SpellInfo(shield_of_the_righteous cd=18 max_charges=3 cd_haste=melee gcd=0 offgcd=1)
	SpellAddBuff(shield_of_the_righteous shield_of_the_righteous_buff=1)
Define(shield_of_the_righteous_buff 132403)
	SpellInfo(shield_of_the_righteous_buff duration=4.5)

	SpellInfo(shield_of_vengeance cd=120 tag=shortcd)
Define(speed_of_light 85499)
	SpellInfo(speed_of_light cd=45 gcd=0 offgcd=1)
Define(t18_class_trinket 124518)

	
	SpellRequire(templars_verdict add_holypower -1=buff,hp_cost_reductino_buff)
	SpellRequire(templars_verdict holypower_percent 0=buff,divine_purpose_buff talent=divine_purpose_talent)
	#SpellAddBuff(templars_verdict divine_purpose_buff=0)
	SpellAddBuff(templars_verdict sacred_judgment_buff=0)
	SpellAddBuff(templars_verdict righteous_verdict_buff=1 if_buff=!righteous_verdict_buff)
	SpellAddBuff(templars_verdict righteous_verdict_buff=0 if_buff=righteous_verdict_buff)
	SpellAddBuff(templars_verdict divine_judgment_buff=1 talent=divine_judgment_talent)
Define(fires_of_justice_buff 209785)
	SpellInfo(fires_of_justice_buff duration=15)
Define(tyrs_deliverance 200652)
	SpellInfo(tyrs_deliverance cd=90)
Define(uthers_insight_buff 156988)
	SpellInfo(uthers_insight_buff duration=21 haste=spell tick=3)

	SpellInfo(wake_of_ashes cd=45 holypower=-5 tag=main)
	SpellAddTargetDebuff(wake_of_ashes wake_of_ashes_debuff=1)
Define(wake_of_ashes_debuff 255937)
	SpellInfo(wake_of_ashes_debuff duration=5)
Define(whisper_of_the_nathrezim 137020)
Define(whisper_of_the_nathrezim_buff 207633)
Define(wings_of_liberty_buff 185647)
	SpellInfo(wings_of_liberty_buff duration=10 max_stacks=10)
Define(word_of_glory 85673)
	SpellInfo(word_of_glory cd=1 holypower=3)
	SpellRequire(word_of_glory holypower_percent 0=buff,word_of_glory_no_holy_buff)
	SpellAddBuff(word_of_glory divine_purpose_buff=0 if_spell=divine_purpose)
	SpellAddBuff(word_of_glory lawful_words_buff=0 itemset=T17 itemcount=4 specialization=holy)
SpellList(word_of_glory_no_holy_buff bastion_of_power_buff divine_purpose_buff lawful_words_buff)
Define(zeal 217020)
	SpellInfo(zeal cd=4.5 holypower=-1)
Define(zeal_debuff 269571)
	SpellInfo(zeal_debuff duration=25 max_stacks=9)

#Artifact traits
#Define(ashes_to_ashes 179546)

#Legendaries
Define(sacred_judgment_item 253806)
Define(sacred_judgment_buff 253806)
	SpellInfo(sacred_judgment_buff duration=15)
	

#Azerite Traits
Define(divine_right_trait 278519)
Define(divine_right_buff 277678)
	SpellInfo(divine_right_buff duration=15)
Define(inner_light_trait 275477)

#Hack
#Seems like we can't define multiple add_holypower -1=buff
SpellList(hp_cost_reductino_buff sacred_judgment_buff fires_of_justice_buff)

#Talents
Define(aegis_of_light_talent 18)
Define(aura_of_mercy_talent 12)
Define(aura_of_sacrifice_talent 11)
Define(avenging_crusader_talent 17)
Define(awakening_talent 18)
Define(bastion_of_light_talent 6)
Define(beacon_of_faith_talent 20)
Define(beacon_of_virtue_talent 21)
Define(bestow_faith_talent 2)
Define(blade_of_wrath_talent 5)
Define(blessed_hammer_talent 3)
Define(blessing_of_spellwarding_talent 12)
Define(blinding_light_talent 9)
Define(cavalier_talent_holy 4)
Define(cavalier_talent 13)
Define(consecrated_ground_talent 17)



Define(crusaders_might_talent 1)
Define(devotion_aura_talent 10)
Define(divine_judgment_talent 10)
Define(divine_purpose_talent 19)

Define(eye_for_an_eye_talent 15)
Define(final_stand_talent 14)
Define(fires_of_justice_talent 4)
Define(first_avenger_talent 4)
Define(fist_of_justice_talent 7)

Define(hand_of_the_protector_talent 15)
Define(holy_avenger_talent 15)
Define(holy_prism_talent 14)
Define(holy_shield_talent 1)

Define(judgment_of_light_talent_holy 13)
Define(judgment_of_light_talent 16)
Define(justicars_vengeance_talent 17)
Define(last_defender_talent 19)
Define(lights_hammer_talent 3)
Define(redoubt_talent 2)
Define(repentance_talent 8)
Define(retribution_aura_talent 10)
Define(righteous_protector_talent 20)

Define(rule_of_law_talent 6)
Define(sanctified_wrath_talent 16)
Define(selfless_healer_talent 16)

Define(unbreakable_spirit_talent_holy 5)
Define(unbreakable_spirit_talent 14)

Define(word_of_glory_talent 18)
Define(zeal_talent 1)

]]
    OvaleScripts:RegisterScript("PALADIN", nil, name, desc, code, "include")
end
