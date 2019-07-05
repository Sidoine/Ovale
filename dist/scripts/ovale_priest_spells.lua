local __exports = LibStub:NewLibrary("ovale/scripts/ovale_priest_spells", 80000)
if not __exports then return end
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
__exports.register = function()
    local name = "ovale_priest_spells"
    local desc = "[8.1] Ovale: Priest spells"
    local code = [[Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
Define(apotheosis 200183)
# Enter a pure Holy form for 20 seconds, increasing the cooldown reductions to your Holy Words by s1 and reducing their cost by s2.
  SpellInfo(apotheosis cd=120 duration=20 talent=apotheosis_talent)
  # Effects that reduce Holy Word cooldowns increased by s1. Cost of Holy Words reduced by s2.
  SpellAddBuff(apotheosis apotheosis=1)
Define(arcane_pulse 260364)
# Deals <damage> Arcane damage to nearby enemies and reduces their movement speed by 260369s1. Lasts 12 seconds.
  SpellInfo(arcane_pulse cd=180 gcd=1)

Define(berserking 26297)
# Increases your haste by s1 for 12 seconds.
  SpellInfo(berserking cd=180 duration=12 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking=1)
Define(blood_of_the_enemy 297108)
# The Heart of Azeroth erupts violently, dealing s1 Shadow damage to enemies within A1 yds. You gain m2 critical strike chance against the targets for 10 seconds?a297122[, and increases your critical hit damage by 297126m for 5 seconds][].
  SpellInfo(blood_of_the_enemy cd=120 duration=10 channel=10)
  # You have a w2 increased chance to be Critically Hit by the caster.
  SpellAddTargetDebuff(blood_of_the_enemy blood_of_the_enemy=1)
Define(dark_ascension 280711)
# Immediately activates a new Voidform, then releases an explosive blast of pure void energy, causing (95 of Spell Power)*2 Shadow damage to all enemies within a1 yds of your target.rnrn|cFFFFFFFFGenerates s2/100 Insanity.|r
  SpellInfo(dark_ascension cd=60 talent=dark_ascension_talent)
Define(dark_void 263346)
# Unleashes an explosion of dark energy around the target, dealing (100 of Spell Power) Shadow damage and applying Shadow Word: Pain to all nearby enemies.rnrn|cFFFFFFFFGenerates s2/100 Insanity.|r
  SpellInfo(dark_void cd=30 insanity=-3000 talent=dark_void_talent)
Define(divine_star 110744)
# Throw a Divine Star forward 24 yds, healing allies in its path for (50 of Spell Power) and dealing (40 of Spell Power) Holy damage to enemies. After reaching its destination, the Divine Star returns to you, healing allies and damaging enemies in its path again.
  SpellInfo(divine_star cd=15 duration=15 talent=divine_star_talent)
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
Define(halo 120517)
# Creates a ring of Holy energy around you that quickly expands to a 30 yd radius, healing allies for (103 of Spell Power) and dealing (103 of Spell Power) Holy damage to enemies.
  SpellInfo(halo cd=40 duration=3.2 talent=halo_talent)
Define(holy_fire 14914)
# Consumes the enemy in Holy flames that cause (50 of Spell Power) Holy damage and an additional o2 Holy damage over 7 seconds.?a231687[ Stacks up to u times.][]
# Rank 2: Smite and Holy Nova have a s1 chance to reset the cooldown of Holy Fire, and Holy Fire's damage over time effect can stack up to s2+1 times.
  SpellInfo(holy_fire cd=10 duration=7 max_stacks=1 tick=1)
  # w2 Holy damage every t2 seconds.
  SpellAddTargetDebuff(holy_fire holy_fire=1)
Define(holy_nova 132157)
# Causes an explosion of holy light around you, dealing (24 of Spell Power) Holy damage to all enemies and (10 of Spell Power) healing to all allies within A1 yds.?a231687[ Has a 231687s1 chance to reset the cooldown of Holy Fire if any targets are hit.][]
  SpellInfo(holy_nova)

Define(holy_word_chastise 88625)
# Chastises the target for (112.5 of Spell Power) Holy damage and ?s200199[stuns][incapacitates] them for ?s200199[4 seconds][4 seconds].?s63733[rnrn|cFFFFFFFFCooldown reduced by s2 sec when you cast Smite.|r][]
  SpellInfo(holy_word_chastise cd=60)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)

Define(mind_blast 8092)
# Blasts the target's mind for (120 of Spell Power) Shadow damage.?a185916[rnrn|cFFFFFFFFGenerates /100;s2 Insanity.|r][]
  SpellInfo(mind_blast cd=7.5 insanity=-1200)
Define(mind_bomb 205369)
# Inflicts the target with a Mind Bomb.rnrnAfter 2 seconds or if the target dies, it unleashes a psychic explosion, disorienting all enemies within 226943A1 yds of the target for 6 seconds.
  SpellInfo(mind_bomb cd=30 duration=2 talent=mind_bomb_talent)
  # About to unleash a psychic explosion, disorienting all nearby enemies.
  SpellAddTargetDebuff(mind_bomb mind_bomb=1)
Define(mind_flay 15407)
# Assaults the target's mind with Shadow energy, causing o1 Shadow damage over 3 seconds and slowing their movement speed by s2.?a185916[rnrn|cFFFFFFFFGenerates s4*m3/100 Insanity over the duration.|r][]
  SpellInfo(mind_flay duration=3 channel=3 tick=0.75)
  SpellInfo(smite replaced_by=mind_flay)
  # Movement speed slowed by s2 and taking Shadow damage every t1 sec.
  SpellAddBuff(mind_flay mind_flay=1)
  # Movement speed slowed by s2 and taking Shadow damage every t1 sec.
  SpellAddTargetDebuff(mind_flay mind_flay=1)
Define(mind_sear 48045)
# Corrosive shadow energy radiates from the target, dealing 49821m2*s2 Shadow damage over 3 seconds to all enemies within 49821a2 yards of the target.rnrn|cFFFFFFFFGenerates s2*208232m1/100 Insanity over the duration per target hit.|r
  SpellInfo(mind_sear duration=3 channel=3 tick=0.75)

Define(purifying_blast 295337)
# Call down a purifying beam upon the target area, dealing 295293s3*(1+@versadmg)*s2 Fire damage over 6 seconds.?a295364[ Has a low chance to immediately annihilate any specimen deemed unworthy by MOTHER.][]?a295352[rnrnWhen an enemy dies within the beam, your damage is increased by 295354s1 for 8 seconds.][]rnrnAny Aberration struck by the beam is stunned for 3 seconds.
  SpellInfo(purifying_blast cd=60 duration=6)
Define(quaking_palm 107079)
# Strikes the target with lightning speed, incapacitating them for 4 seconds, and turns off your attack.
  SpellInfo(quaking_palm cd=120 duration=4 gcd=1)
  # Incapacitated.
  SpellAddTargetDebuff(quaking_palm quaking_palm=1)
Define(shadow_crash 205385)
# Hurl a bolt of slow-moving Shadow energy at the destination, dealing (125 of Spell Power) Shadow damage to all targets within 205386A1 yards.rnrn|cFFFFFFFFGenerates /100;s2 Insanity.|r
  SpellInfo(shadow_crash cd=20 insanity=-2000 talent=shadow_crash_talent)

Define(shadow_word_death 32379)
# A word of dark binding that inflicts (187.5 of Spell Power) Shadow damage to the target. Only usable on enemies that have less than s2 health.rnrn|cFFFFFFFFGenerates s3 Insanity, or s4 Insanity if the target dies.|r
  SpellInfo(shadow_word_death cd=9 talent=shadow_word_death_talent)
Define(shadow_word_pain 589)
# A word of darkness that causes (18 of Spell Power) Shadow damage instantly, and an additional o2 Shadow damage over 16 seconds.?a185916[rnrn|cFFFFFFFFGenerates m3/100 Insanity.|r][]
  SpellInfo(shadow_word_pain duration=16 insanity=-400 tick=2)
  # Suffering w2 Shadow damage every t2 sec.
  SpellAddTargetDebuff(shadow_word_pain shadow_word_pain=1)
Define(shadowform 232698)
# Assume a Shadowform, increasing your spell damage dealt by s1.
  SpellInfo(shadowform)
  # Spell damage dealt increased by s1.
  SpellAddBuff(shadowform shadowform=1)
  # Spell damage dealt increased by s1.
  SpellAddTargetDebuff(shadowform shadowform=1)
Define(silence 15487)
# Silences the target, preventing them from casting spells for 4 seconds. Against non-players, also interrupts spellcasting and prevents any spell in that school from being cast for 4 seconds.
# Rank 1: Silences an enemy preventing it from casting spells for 6 seconds.
  SpellInfo(silence cd=45 duration=4 gcd=0 offgcd=1)
  # Silenced.
  SpellAddTargetDebuff(silence silence=1)
Define(smite 585)
# Smites an enemy for (47 of Spell Power) Holy damage?s231682[ and absorbs the next <shield> damage dealt by the enemy]?s231687[ and has a 231687s1 chance to reset the cooldown of Holy Fire][].
# Rank 2: Smite deals s1 increased damage.
  SpellInfo(smite)
Define(surrender_to_madness 193223)
# All your Insanity-generating abilities generate s1 more Insanity and you can cast while moving for 60 seconds.rnrnThen, you take damage equal to s3 of your maximum health and cannot generate Insanity for 15 seconds.
  SpellInfo(surrender_to_madness cd=180 duration=60 talent=surrender_to_madness_talent)
  # Generating s1 more Insanity.
  SpellAddBuff(surrender_to_madness surrender_to_madness=1)
Define(the_unbound_force 298452)
# Unleash the forces within the Heart of Azeroth, causing shards of Azerite to strike your target for (298407s3*((2 seconds/t)+1)+298407s3) Fire damage over 2 seconds. This damage is increased by s2 if it critically strikes.?a298456[rnrnEach time The Unbound Force causes a critical strike, it immediately strikes the target with an additional Azerite shard, up to a maximum of 298456m2.][]
  SpellInfo(the_unbound_force cd=60 duration=2 channel=2 tick=0.33)
  SpellAddBuff(the_unbound_force the_unbound_force=1)
  SpellAddTargetDebuff(the_unbound_force the_unbound_force=1)
Define(vampiric_touch 34914)
# A touch of darkness that causes 34914o2 Shadow damage over 21 seconds, and heals you for e2*100 of damage dealt.rnrnIf Vampiric Touch is dispelled, the dispeller flees in Horror for 3 seconds.rnrn|cFFFFFFFFGenerates m3/100 Insanity.|r
  SpellInfo(vampiric_touch duration=21 insanity=-600 tick=3)
  # Suffering w2 Shadow damage every t2 sec.
  SpellAddTargetDebuff(vampiric_touch vampiric_touch=1)
Define(void_bolt 228266)
# For the duration of Voidform, your Void Eruption ability is replaced by Void Bolt:rnrn@spelltooltip205448
# Rank 2: Void Bolt extends the duration of your Shadow Word: Pain and Vampiric Touch on all nearby targets by @switch<s2>[s1/1000][s1/1000.1] sec.
  SpellInfo(void_bolt channel=0 gcd=0 offgcd=1)
  SpellAddBuff(void_bolt void_bolt=1)
Define(void_eruption 228260)
# Releases an explosive blast of pure void energy, activating Voidform and causing (95 of Spell Power)*2 Shadow damage to all enemies within a1 yds of your target.rnrnDuring Voidform, this ability is replaced by Void Bolt.rnrn|cFFFFFFFFRequires C/100 Insanity to activate.|r
  SpellInfo(void_eruption insanity=9000)
Define(void_torrent 263165)
# Channel a torrent of void energy into the target, dealing o Shadow damage over 4 seconds.rnrnInsanity does not drain during this channel.rnrn|cFFFFFFFFGenerates 289577s1*289577s2/100 Insanity over the duration.|r
  SpellInfo(void_torrent cd=45 duration=4 channel=4 tick=1 talent=void_torrent_talent)
  # Dealing s1 Shadow damage to the target every t1 sec.rnrnInsanity drain temporarily stopped.
  SpellAddBuff(void_torrent void_torrent=1)
  # Dealing s1 Shadow damage to the target every t1 sec.rnrnInsanity drain temporarily stopped.
  SpellAddTargetDebuff(void_torrent void_torrent=1)
Define(voidform_shadow 228264)
# Activated by casting Void Eruption. Twists your Shadowform with the powers of the Void, increasing spell damage you deal by 194249s1?s8092[, reducing the cooldown on Mind Blast by 194249m6/-1000.1 sec,][] and granting an additional s2/10.1 Haste every 194249t5 sec.rnrnYour Insanity will drain increasingly fast until it reaches 0 and Voidform ends.
  SpellInfo(voidform_shadow channel=0 gcd=0 offgcd=1)
  SpellAddBuff(voidform_shadow voidform_shadow=1)
Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp=1)
Define(apotheosis_talent 20) #21644
# Enter a pure Holy form for 20 seconds, increasing the cooldown reductions to your Holy Words by s1 and reducing their cost by s2.
Define(dark_ascension_talent 20) #21978
# Immediately activates a new Voidform, then releases an explosive blast of pure void energy, causing (95 of Spell Power)*2 Shadow damage to all enemies within a1 yds of your target.rnrn|cFFFFFFFFGenerates s2/100 Insanity.|r
Define(dark_void_talent 9) #23127
# Unleashes an explosion of dark energy around the target, dealing (100 of Spell Power) Shadow damage and applying Shadow Word: Pain to all nearby enemies.rnrn|cFFFFFFFFGenerates s2/100 Insanity.|r
Define(divine_star_talent 17) #19760
# Throw a Divine Star forward 24 yds, healing allies in its path for (50 of Spell Power) and dealing (40 of Spell Power) Holy damage to enemies. After reaching its destination, the Divine Star returns to you, healing allies and damaging enemies in its path again.
Define(halo_talent 18) #19763
# Creates a ring of Holy energy around you that quickly expands to a 30 yd radius, healing allies for (103 of Spell Power) and dealing (103 of Spell Power) Holy damage to enemies.
Define(mind_bomb_talent 11) #23375
# Inflicts the target with a Mind Bomb.rnrnAfter 2 seconds or if the target dies, it unleashes a psychic explosion, disorienting all enemies within 226943A1 yds of the target for 6 seconds.
Define(mindbender_talent 17) #21719
# Summons a Mindbender to attack the target for 15 seconds.rnrn|cFFFFFFFFGenerates 200010s1/100 Insanity each time the Mindbender attacks.|r
Define(misery_talent 8) #23126
# Vampiric Touch also applies Shadow Word: Pain to the target.
Define(shadow_crash_talent 15) #21755
# Hurl a bolt of slow-moving Shadow energy at the destination, dealing (125 of Spell Power) Shadow damage to all targets within 205386A1 yards.rnrn|cFFFFFFFFGenerates /100;s2 Insanity.|r
Define(shadow_word_death_talent 14) #22311
# A word of dark binding that inflicts (187.5 of Spell Power) Shadow damage to the target. Only usable on enemies that have less than s2 health.rnrn|cFFFFFFFFGenerates s3 Insanity, or s4 Insanity if the target dies.|r
Define(shadow_word_void_talent 3) #22314
# Blasts the target with a word of void for (130 of Spell Power) Shadow damage.?a185916[rnrn|cFFFFFFFFGenerates /100;s2 Insanity.|r][]
Define(surrender_to_madness_talent 21) #21979
# All your Insanity-generating abilities generate s1 more Insanity and you can cast while moving for 60 seconds.rnrnThen, you take damage equal to s3 of your maximum health and cannot generate Insanity for 15 seconds.
Define(void_torrent_talent 18) #21720
# Channel a torrent of void energy into the target, dealing o Shadow damage over 4 seconds.rnrnInsanity does not drain during this channel.rnrn|cFFFFFFFFGenerates 289577s1*289577s2/100 Insanity over the duration.|r
Define(death_throes_trait 278659)
Define(searing_dialogue_trait 272788)
Define(spiteful_apparitions_trait 277682)
Define(thought_harvester_trait 288340)
Define(whispers_of_the_damned_trait 275722)
    ]]
    code = code .. [[
# Priest spells and functions.

# Spells

	SpellInfo(dark_ascension insanity=-50 cd=60)
	SpellAddBuff(dark_ascension voidform_buff=1)

	SpellInfo(dark_void cd=30 insanity=-30)
	SpellAddTargetDebuff(dark_void shadow_word_pain_debuff=1)
Define(dispel_magic 528)
Define(dispersion 47585)
	SpellInfo(dispersion cd=120)
	SpellAddBuff(dispersion dispersion_buff=1)
Define(dispersion_buff 47585)
	SpellInfo(dispersion_buff duration=6)

	SpellInfo(divine_star cd=15)
Define(fade 586)
	SpellInfo(fade cd=30)
Define(insanity_drain_stacks_buff 194249)
Define(leap_of_faith 73325)
	SpellInfo(leap_of_faith cd=90)
Define(levitate 1706)
Define(mass_dispel 32375)
	SpellInfo(mass_dispel cd=45)

	SpellInfo(mind_blast cd=7.5 cd_haste=spell insanity=-12 charges=1)
	SpellInfo(mind_blast replaced_by=shadow_word_void talent=shadow_word_void_talent)
	SpellInfo(mind_blast insanity_percent=120 talent=fortress_of_the_mind_talent)
	SpellRequire(mind_blast insanity_percent 200=buff,surrender_to_madness_buff)
	SpellRequire(mind_blast cd 6=buff,voidform_buff)
	SpellAddBuff(mind_blast shadowy_insight_buff=0 talent=shadowy_insight_talent)

	SpellInfo(mind_bomb cd=30)
Define(mind_bomb_debuff 205369)
	SpellInfo(mind_bomb_debuff duration=2)
Define(mind_control 605)

	SpellInfo(mind_flay channel=3 insanity=-4 haste=spell)
	SpellInfo(mind_flay insanity_percent=120 talent=fortress_of_the_mind_talent)
	SpellRequire(mind_flay insanity_percent 200=buff,surrender_to_madness_buff)

	SpellInfo(mind_sear channel=3 haste=spell)
Define(mind_vision 2096)

Define(mindbender_discipline 123040)
	SpellInfo(mindbender_discipline cd=60 tag=main)
Define(mindbender_shadow 200174)
    SpellInfo(mindbender_shadow cd=60 tag=main)
Define(penance 47540)
	SpellInfo(penance cd=9 channel=2)
Define(power_word_fortitude 21562)
Define(power_word_shield 17)
	SpellInfo(power_word_shield cd=6 cd_haste=spell)
	SpellInfo(power_word_shield cd=0 specialization=discipline)
Define(power_word_solace 129250)	
	SpellInfo(power_word_solace cd=12 cd_haste=spell)
Define(psychic_horror 64044)
	SpellInfo(psychic_horror cd=45)
Define(psychic_scream 8122)
	SpellInfo(psychic_scream cd=60)
	SpellInfo(psychic_scream replaced_by=mind_bomb talent=mind_bomb_talent)
Define(purify_disease 213634)
	SpellInfo(purify_disease cd=8)
Define(purge_the_wicked 204197)
	SpellInfo(purge_the_wicked replaced_by=shadow_word_pain talent=purge_the_wicked_talent specialization=discipline)
	SpellAddTargetDebuff(purge_the_wicked purge_the_wicked_debuff=1)
Define(purge_the_wicked_debuff 204197)
	SpellInfo(purge_the_wicked_debuff duration=20 haste=spell tick=2)
Define(rapture 47536)
	SpellInfo(rapture cd=90)
Define(rapture_buff 47536)
	SpellInfo(rapture_buff duration=10)
Define(resurrection 2006)
Define(schism 214621)
	SpellInfo(schism cd=24)
	SpellAddTargetDebuff(schism schism_debuff=1)
Define(schism_debuff 214621)
	SpellInfo(schism_debuff duration=9)
Define(shackle_undead 9484)

	SpellInfo(shadow_crash cd=20 insanity=-20 tag=shortcd)
	SpellRequire(shadow_crash insanity_percent 200=buff,surrender_to_madness_buff)
Define(shadow_mend 186263)

	SpellInfo(shadow_word_death target_health_pct=20 insanity=-15 cd=9 charges=2)
	SpellRequire(shadow_word_death insanity_percent 200=buff,surrender_to_madness_buff)

	SpellInfo(shadow_word_pain insanity=-4)
	SpellInfo(shadow_word_pain replaced_by=purge_the_wicked talent=!purge_the_wicked_talent specialization=discipline)
	SpellAddTargetDebuff(shadow_word_pain shadow_word_pain_debuff=1)
	SpellRequire(shadow_word_pain insanity_percent 200=buff,surrender_to_madness_buff)
Define(shadow_word_pain_debuff 589)
	SpellInfo(shadow_word_pain_debuff duration=16 haste=spell tick=2)
Define(shadow_word_void 205351)
    SpellInfo(shadow_word_void cd=9 insanity=-15 talent=shadow_word_void_talent)
	SpellInfo(shadow_word_void cd=9 charges=2 insanity=-15 tag=main)
	SpellInfo(shadow_word_void replaced_by=mind_blast talent=!shadow_word_void_talent)
	SpellRequire(shadow_word_void cd 7.5=buff,voidform_buff)
	SpellRequire(shadow_word_void insanity_percent 200=buff,surrender_to_madness_buff)
Define(shadowfiend 34433)
	SpellInfo(shadowfiend cd=180)
	SpellInfo(shadowfiend replaced_by=mindbender_discipline talent=disc_mindbender_talent specialization=discipline)
    SpellInfo(shadowfiend replaced_by=mindbender_shadow talent=shadow_mindbender_talent specialization=shadow)
    
    SpellRequire(shadowform unusable 1=buff,voidform_buff)
Define(shadowform_buff 232698)
Define(shadowy_insight_buff 124430)
	SpellInfo(shadowy_insight_buff duration=12)

	SpellInfo(silence cd=45 gcd=0 interrupt=1)


	SpellInfo(surrender_to_madness cd=240)
	SpellAddBuff(surrender_to_madness surrender_to_madness_buff=1)
Define(surrender_to_madness_buff 193223)
	SpellInfo(surrender_to_madness_buff duration=60)
Define(vampiric_embrace 15286)
	SpellInfo(vampiric_embrace cd=120)
	SpellAddBuff(vampiric_embrace vampiric_embrace_buff=1)
Define(vampiric_embrace_buff 15286)
	SpellInfo(vampiric_embrace_buff duration=15)

	SpellInfo(vampiric_touch insanity=-6)
	SpellRequire(vampiric_touch insanity_percent 200=buff,surrender_to_madness_buff)
	SpellAddTargetDebuff(vampiric_touch vampiric_touch_debuff=1)
	SpellAddTargetDebuff(vampiric_touch shadow_word_pain_debuff=1 talent=misery_talent)
Define(vampiric_touch_debuff 34914)
	SpellInfo(vampiric_touch_debuff duration=21 haste=spell tick=3)
Define(void_bolt 205448)
	SpellInfo(void_bolt cd=4.5 insanity=-16 cd_haste=spell)
	SpellRequire(void_bolt unusable 1=buff,!voidform_buff)
	SpellRequire(void_bolt insanity_percent 200=buff,surrender_to_madness_buff)
	SpellAddTargetDebuff(void_bolt shadow_word_pain_debuff=refresh)
	SpellAddTargetDebuff(void_bolt vampiric_touch_debuff=refresh)

	SpellInfo(void_eruption insanity=90 tag=main)
	SpellInfo(void_eruption insanity=60 talent=legacy_of_the_void_talent)
	SpellAddBuff(void_eruption voidform_buff=1)
	SpellRequire(void_eruption unusable 1=buff,voidform_buff)
	SpellRequire(void_eruption replace void_bolt=buff,voidform_buff)

	SpellInfo(void_torrent cd=60 tag=main unusable=1)
	SpellRequire(void_torrent unusable 0=buff,voidform_buff)
Define(void_torrent_buff 263165) # TODO Insanity does not drain during this buff
	SpellInfo(void_torrent_buff duration=4) 
Define(voidform 228264)
Define(voidform_buff 194249)

AddFunction CurrentInsanityDrain {
	if BuffPresent(dispersion_buff) 0 
	if BuffPresent(void_torrent_buff) 0 # for some reason, this does not work as expected
	if BuffPresent(voidform_buff) BuffStacks(voidform_buff)/2 + 9
	0
}

# Azerite Traits
Define(thought_harvester_trait 273319)
	Define(harvested_thoughts_buff 273321)

#Talents
Define(apotheosis_talent 20)
Define(dark_ascension_talent 20)
Define(dark_void_talent 9)
Define(disc_mindbender_talent 8)
Define(divine_star_talent 17)
Define(fortress_of_the_mind_talent 1)
Define(halo_talent 18)
Define(legacy_of_the_void_talent 19)
Define(mind_bomb_talent 11)
Define(misery_talent 8)
Define(purge_the_wicked_talent 16)
Define(shadow_crash_talent 15)
Define(shadow_mindbender_talent 17)
Define(shadow_word_death_talent 14)
Define(shadow_word_void_talent 3)
Define(shadowy_insight_talent 2)
Define(surrender_to_madness_talent 21)
Define(void_torrent_talent 18)
]]
    OvaleScripts:RegisterScript("PRIEST", nil, name, desc, code, "include")
end
