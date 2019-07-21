local __exports = LibStub:NewLibrary("ovale/scripts/ovale_warlock_spells", 80201)
if not __exports then return end
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
__exports.register = function()
    local name = "ovale_warlock_spells"
    local desc = "[8.2] Ovale: Warlock spells"
    local code = [[Define(agony 980)
# Inflicts increasing agony on the target, causing up to o1*u Shadow damage over 18 seconds. Damage starts low and increases over the duration. Refreshing Agony maintains its current damage level.rnrn|cFFFFFFFFAgony damage sometimes generates 1 Soul Shard.|r
# Rank 2: Agony may now ramp up to s1+6 stacks.
  SpellInfo(agony duration=18 max_stacks=6 tick=2)
  # Suffering w1 Shadow damage every t1 sec. Damage increases over time.
  SpellAddTargetDebuff(agony agony=1)
Define(berserking 26297)
# Increases your haste by s1 for 12 seconds.
  SpellInfo(berserking cd=180 duration=12 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking=1)
Define(bilescourge_bombers 267211)
# Tear open a portal to the nether above the target location, from which several Bilescourge will pour out of and crash into the ground over 6 seconds, dealing (21 of Spell Power) Shadow damage to all enemies within 267213A1 yards.
  SpellInfo(bilescourge_bombers soulshards=2 cd=30 duration=6 talent=bilescourge_bombers_talent)
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
Define(call_dreadstalkers 104316)
# Summons s1 ferocious Dreadstalkers to attack the target for 12 seconds.
  SpellInfo(call_dreadstalkers soulshards=2 cd=20)
Define(cascading_calamity_buff 275376)
# Casting Unstable Affliction on a target affected by your Unstable Affliction increases your Haste by s1 for 15 seconds
  SpellInfo(cascading_calamity_buff channel=-0.001 gcd=0 offgcd=1)

Define(cataclysm 152108)
# Calls forth a cataclysm at the target location, dealing (180 of Spell Power) Shadowflame damage to all enemies within A1 yards and afflicting them with ?s980[Agony and Unstable Affliction][]?s104315[Corruption][]?s348[Immolate][]?!s980&!s104315&!s348[Agony, Unstable Affliction, Corruption, or Immolate][].
  SpellInfo(cataclysm cd=30 talent=cataclysm_talent)
Define(channel_demonfire 196447)
# Launches s1 bolts of felfire over 3 seconds at random targets afflicted by your Immolate within 196449A1 yds. Each bolt deals (16 of Spell Power) Fire damage to the target and (7.000000000000001 of Spell Power) Fire damage to nearby enemies.
  SpellInfo(channel_demonfire cd=25 duration=3 channel=3 tick=0.2 talent=channel_demonfire_talent)
  SpellAddBuff(channel_demonfire channel_demonfire=1)
Define(chaos_bolt 116858)
# Unleashes a devastating blast of chaos, dealing a critical strike for 2*(120 of Spell Power) Chaos damage. Damage is further increased by your critical strike chance.
  SpellInfo(chaos_bolt soulshards=2)
Define(conflagrate 17962)
# Triggers an explosion on the target, dealing (100 of Spell Power) Fire damage.?s196406[rnrnReduces the cast time of your next Incinerate or Chaos Bolt by 117828s1 for 10 seconds.][]rnrn|cFFFFFFFFGenerates 245330s1 Soul Shard Fragments.|r
# Rank 2: Conflagrate has s1+1 charges.
  SpellInfo(conflagrate cd=12.96)
Define(corruption 172)
# Corrupts the target, causing 146739o1 Shadow damage over 14 seconds.
  SpellInfo(corruption)
  # Suffering w1 Shadow damage every t1 sec.
  SpellAddTargetDebuff(corruption corruption_debuff=1)
Define(corruption_debuff 146739)
# Corrupts the target, causing 146739o1 Shadow damage over 14 seconds.
  SpellInfo(corruption_debuff duration=14 channel=14 gcd=0 offgcd=1 tick=2)
  # Suffering w1 Shadow damage every t1 sec.
  SpellAddTargetDebuff(corruption_debuff corruption_debuff=1)
Define(crashing_chaos_buff 277705)
# Your Summon Infernal's cooldown is reduced by s3 sec, and summoning your Infernal increases the damage of your next s2 Chaos Bolts by s1.
  SpellInfo(crashing_chaos_buff channel=-0.001 gcd=0 offgcd=1)
  SpellAddBuff(crashing_chaos_buff crashing_chaos_buff=1)
Define(dark_soul_instability 113858)
# Infuses your soul with unstable power, increasing your critical strike chance by 113858s1 for 20 seconds.?s56228[rnrn|cFFFFFFFFPassive:|rrnIncreases your critical strike chance by 113858m1/56228m1. This effect is disabled while on cooldown.][]
  SpellInfo(dark_soul_instability cd=120 charge_cd=120 duration=20 talent=dark_soul_instability_talent)
  # Critical strike chance increased by w1.
  SpellAddBuff(dark_soul_instability dark_soul_instability=1)
Define(dark_soul_misery 113860)
# Infuses your soul with the misery of fallen foes, increasing haste by (25 of Spell Power) for 20 seconds.
  SpellInfo(dark_soul_misery cd=120 duration=20 talent=dark_soul_misery_talent)
  # Haste increased by s1.
  SpellAddBuff(dark_soul_misery dark_soul_misery=1)
Define(deathbolt 264106)
# Launches a bolt of death at the target, dealing s2 of the total remaining damage of your damage over time effects on the target.?s196103[rnrnCounts up to s3 sec of your Corruption's damage.][]
  SpellInfo(deathbolt cd=30 talent=deathbolt_talent)
Define(demonbolt 264178)
# Send the fiery soul of a fallen demon at the enemy, causing (66.7 of Spell Power) Shadowflame damage.?c2[rnrn|cFFFFFFFFGenerates 2 Soul Shards.|r][]
  SpellInfo(demonbolt)
Define(demonic_calling_buff 205146)
# Shadow Bolt?s264178[ and Demonbolt have][ has] a h chance to make your next Call Dreadstalkers cost s1 less Soul Shard and have no cast time.
  SpellInfo(demonic_calling_buff duration=20 gcd=0 offgcd=1)
  # Your next Call Dreadstalkers costs 205145s1 less Soul Shard and has no cast time.
  SpellAddBuff(demonic_calling_buff demonic_calling_buff=1)
Define(demonic_power 265273)
# Summon a Demonic Tyrant to increase the duration of all of your current lesser demons by 265273m3/1000.1 sec, and increase the damage of all of your other demons by 265273s2, while damaging your target.
  SpellInfo(demonic_power duration=15 gcd=0 offgcd=1)
  # Damage dealt by your demons increased by s2.
  SpellAddBuff(demonic_power demonic_power=1)
Define(demonic_strength 267171)
# Infuse your Felguard with demonic strength and command it to charge your target and unleash a Felstorm that will deal s2 increased damage.
  SpellInfo(demonic_strength cd=60 duration=20 talent=demonic_strength_talent)
  # Your next Felstorm will deal s2 increased damage.
  SpellAddBuff(demonic_strength demonic_strength=1)
Define(doom 265412)
# Inflicts impending doom upon the target, causing (160 of Spell Power) Shadow damage after 30 seconds. rnrnIf Doom kills the target, there is a s2 chance to summon a Doomguard to fight for you for 25 seconds.rnrn|cFFFFFFFFGenerates 1 Soul Shard when dealing damage.|r
  SpellInfo(doom duration=30 tick=30 talent=doom_talent)
  # Doomed to take 265469s1 Shadow damage.
  SpellAddTargetDebuff(doom doom=1)
Define(drain_life 234153)
# Drains life from the target, causing o1 Shadow damage over 5 seconds, and healing you for e1*100 of the damage done.
  SpellInfo(drain_life duration=5 channel=5 tick=1)
  # Suffering s1 Shadow damage every t1 seconds.rnRestoring health to the Warlock.
  SpellAddTargetDebuff(drain_life drain_life=1)
Define(drain_soul 198590)
# Drains the target's soul, causing o1 Shadow damage over 5 seconds.rnrnDamage is increased by s2 against enemies below s3 health.rnrn|cFFFFFFFFGenerates 1 Soul Shard if the target dies during this effect.|r
  SpellInfo(drain_soul duration=5 channel=5 tick=1 talent=drain_soul_talent)
  # Suffering w1 Shadow damage every t1 seconds.
  SpellAddTargetDebuff(drain_soul drain_soul=1)
Define(explosive_potential 275398)
# When your Implosion consumes 3 or more Imps, gain s1 Haste for 15 seconds.
  SpellInfo(explosive_potential duration=15 channel=15 gcd=0 offgcd=1)
  # Haste increased by w1.
  SpellAddBuff(explosive_potential explosive_potential=1)

Define(fireblood 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. ?s195710[This effect shares a 30 sec cooldown with other similar effects.][]
  SpellInfo(fireblood cd=120 gcd=0 offgcd=1)
Define(focused_azerite_beam 299336)
# Focus excess Azerite energy into the Heart of Azeroth, then expel that energy outward, dealing m1*10 Fire damage to all enemies in front of you over 3 seconds.
  SpellInfo(focused_azerite_beam cd=90 duration=3 channel=3 tick=0.33)

Define(grimoire_felguard 111898)
# Summons a Felguard who attacks the target for s1 sec that deals 216187s1 increased damage.rnrnThis Felguard will stun their target when summoned.
  SpellInfo(grimoire_felguard soulshards=1 cd=120 duration=17 talent=grimoire_felguard_talent)
Define(grimoire_of_sacrifice 108503)
# Sacrifices your demon pet for power, gaining its command demon ability, and causing your spells to sometimes also deal (35 of Spell Power) additional Shadow damage.rnrnLasts 3600 seconds or until you summon a demon pet.
  SpellInfo(grimoire_of_sacrifice cd=30 talent=grimoire_of_sacrifice_talent)

Define(guardian_of_azeroth 295840)
# Call upon Azeroth to summon a Guardian of Azeroth for 30 seconds who impales your target with spikes of Azerite every 2 sec that deal 295834m1*(1+@versadmg) Fire damage.?a295841[ Every 303347t1 sec, the Guardian launches a volley of Azerite Spikes at its target, dealing 295841s1 Fire damage to all nearby enemies.][]?a295843[rnrnEach time the Guardian of Azeroth casts a spell, you gain 295855s1 Haste, stacking up to 295855u times. This effect ends when the Guardian of Azeroth despawns.][]rn
  SpellInfo(guardian_of_azeroth cd=180 duration=30)
  SpellAddBuff(guardian_of_azeroth guardian_of_azeroth=1)
Define(hand_of_guldan 105174)
# Calls down a demonic meteor full of Wild Imps which burst forth to attack the target.rnrnDeals up to m1*86040m1 Shadowflame damage on impact to all enemies within 86040A1 yds of the target?s196283[, applies Doom to each target,][] and summons up to m1*104317m2 Wild Imps, based on Soul Shards consumed.
  SpellInfo(hand_of_guldan soulshards=1)
Define(haunt 48181)
# A ghostly soul haunts the target, dealing (55.00000000000001 of Spell Power) Shadow damage and increasing your damage dealt to the target by s2 for 15 seconds.rnrnIf the target dies, Haunt's cooldown is reset.
  SpellInfo(haunt cd=15 duration=15 talent=haunt_talent)
  # Taking s2 increased damage from the Warlock. Haunt's cooldown will be reset on death.
  SpellAddTargetDebuff(haunt haunt=1)
Define(havoc 80240)
# Marks a target with Havoc for 10 seconds, causing your single target spells to also strike the Havoc victim for s1 of normal initial damage.
  SpellInfo(havoc cd=30 duration=10 channel=10 max_stacks=1)
  # Spells cast by the Warlock also hit this target for s1 of normal initial damage.
  SpellAddTargetDebuff(havoc havoc=1)
Define(immolate 348)
# Burns the enemy, causing (40 of Spell Power) Fire damage immediately and an additional 157736o1 Fire damage over 18 seconds.rnrn|cFFFFFFFFPeriodic damage generates 1 Soul Shard Fragment and has a s2 chance to generate an additional 1 on critical strikes.|r
  SpellInfo(immolate)
Define(implosion 196277)
# Demonic forces suck all of your Wild Imps toward the target, and then cause them to violently explode, dealing 196278s2 Shadowflame damage to all enemies within 196278A3 yards.
  SpellInfo(implosion)
Define(incinerate 29722)
# Draws fire toward the enemy, dealing (64.1 of Spell Power) Fire damage.rnrn|cFFFFFFFFGenerates 244670s1 Soul Shard Fragments and an additional 1 on critical strikes.|r
  SpellInfo(incinerate max_stacks=5)
  SpellInfo(shadow_bolt replaced_by=incinerate)
Define(inevitable_demise_buff 273522)
# Damaging an enemy with Agony increases the damage of your next Drain Life by s1. This effect stacks up to 273525u times.
  SpellInfo(inevitable_demise_buff channel=-0.001 gcd=0 offgcd=1)
  SpellAddBuff(inevitable_demise_buff inevitable_demise_buff=1)
Define(inner_demons 267216)
# You passively summon a Wild Imp to fight for you every t1 sec, and have a s1 chance to also summon an additional Demon to fight for you for s2 sec.
  SpellInfo(inner_demons channel=0 gcd=0 offgcd=1 tick=12 talent=inner_demons_talent)
  SpellAddBuff(inner_demons inner_demons=1)
Define(lifeblood_buff 274419)
# When you use a Healthstone, gain s1 Leech for 20 seconds.
  SpellInfo(lifeblood_buff channel=-0.001 gcd=0 offgcd=1)

Define(nether_portal 267217)
# Tear open a portal to the Twisting Nether for 15 seconds. Every time you spend Soul Shards, you will also command demons from the Nether to come out and fight for you.
  SpellInfo(nether_portal soulshards=1 cd=180 duration=15 talent=nether_portal_talent)
Define(nightfall_buff 213784)
# Your damaging spells have a chance to pull a nightmare star from the sky, creating a pool of corruption that deals 10*213786s1 Shadow damage to all enemies in the area over 10 seconds.
  SpellInfo(nightfall_buff channel=0 gcd=0 offgcd=1)

Define(phantom_singularity 205179)
# Places a phantom singularity above the target, which consumes the life of all enemies within 205246A2 yards, dealing 8*(18 of Spell Power) damage over 16 seconds, healing you for 205246e2*100 of the damage done.
  SpellInfo(phantom_singularity cd=45 duration=16 tick=2 talent=phantom_singularity_talent)
  # Dealing damage to all nearby targets every t1 sec and healing the casting Warlock.
  SpellAddTargetDebuff(phantom_singularity phantom_singularity=1)
Define(power_siphon 264130)
# Instantly sacrifice up to s1 Wild Imps to generate s1 charges of Demonic Core.
  SpellInfo(power_siphon cd=30 channel=0 talent=power_siphon_talent)
Define(purifying_blast 295337)
# Call down a purifying beam upon the target area, dealing 295293s3*(1+@versadmg)*s2 Fire damage over 6 seconds.?a295364[ Has a low chance to immediately annihilate any specimen deemed unworthy by MOTHER.][]?a295352[rnrnWhen an enemy dies within the beam, your damage is increased by 295354s1 for 8 seconds.][]rnrnAny Aberration struck by the beam is stunned for 3 seconds.
  SpellInfo(purifying_blast cd=60 duration=6)
Define(rain_of_fire 5740)
# Calls down a rain of hellfire, dealing 42223m1*8 Fire damage over 8 seconds to enemies in the area.
  SpellInfo(rain_of_fire soulshards=3 duration=8 tick=1)
  # 42223s1 Fire damage every 5740t2 sec.
  SpellAddBuff(rain_of_fire rain_of_fire=1)
Define(reckless_force_buff 298409)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 3 seconds.
  SpellInfo(reckless_force_buff max_stacks=5 gcd=0 offgcd=1 tick=10)
  # Gaining unstable Azerite energy.
  SpellAddBuff(reckless_force_buff reckless_force_buff=1)
Define(seed_of_corruption 27243)
# Embeds a demon seed in the enemy target that will explode after 12 seconds, dealing (24 of Spell Power) Shadow damage to all enemies within 27285A1 yards and applying Corruption to them.rnrnThe seed will detonate early if the target is hit by other detonations, or takes SPS*s1/100 damage from your spells.
  SpellInfo(seed_of_corruption soulshards=1 duration=12 tick=12)
  # Embeded with a demon seed that will soon explode, dealing Shadow damage to the caster's enemies within 27285A1 yards, and applying Corruption to them.rnrnThe seed will detonate early if the target is hit by other detonations, or takes w3 damage from your spells.
  SpellAddTargetDebuff(seed_of_corruption seed_of_corruption=1)
Define(shadow_bolt 686)
# Sends a shadowy bolt at the enemy, causing (34.5 of Spell Power) Shadow damage.?c2[rnrn|cFFFFFFFFGenerates 1 Soul Shard.|r][]
  SpellInfo(shadow_bolt)
Define(shadowburn 17877)
# Blasts a target for (60 of Spell Power) Shadowflame damage. rnrnIf the target dies within 5 seconds and yields experience or honor, Shadowburn's cooldown is reset.rnrn|cFFFFFFFFGenerates 245731s1 Soul Shard Fragments.|r
  SpellInfo(shadowburn cd=12 duration=5 talent=shadowburn_talent)
  # If the target dies and yields experience or honor, Shadowburn's cooldown is reset.
  SpellAddTargetDebuff(shadowburn shadowburn=1)
Define(shadows_bite 272945)
# When your summoned Dreadstalkers fade away, they increase the damage of your Demonbolt by s1 for 8 seconds.
  SpellInfo(shadows_bite duration=8 channel=8 gcd=0 offgcd=1)
  # Demonbolt damage increased by w1.
  SpellAddBuff(shadows_bite shadows_bite=1)

Define(siphon_life 63106)
# Siphons the target's life essence, dealing o1 Shadow damage over 15 seconds and healing you for e1*100 of the damage done.
  SpellInfo(siphon_life duration=15 tick=3 talent=siphon_life_talent)
  # Suffering w1 Shadow damage every t1 sec and siphoning life to the casting Warlock.
  SpellAddTargetDebuff(siphon_life siphon_life=1)
Define(soul_fire 6353)
# Burns the enemy's soul, dealing (100 of Spell Power) Fire damage.rnrnCooldown is reduced by <cdr> sec for every Soul Shard you spend.rnrn|cFFFFFFFFGenerates 281490s1 Soul Shard Fragments.|r
  SpellInfo(soul_fire cd=20 talent=soul_fire_talent)
Define(soul_strike 264057)
# Command your Felguard to strike into the soul of its enemy, dealing <damage> Shadow damage.?c2[rnrn|cFFFFFFFFGenerates 1 Soul Shard.|r][]
  SpellInfo(soul_strike cd=10 talent=soul_strike_talent)
Define(summon_darkglare 205180)
# Summons a Darkglare from the Twisting Nether that extends the duration of your damage over time effects on all enemies by s2 sec.rnrnThe Darkglare will serve you for 20 seconds, blasting its target for (32 of Spell Power) Shadow damage, increased by s3 for every damage over time effect you have active on any target.
  SpellInfo(summon_darkglare cd=180 duration=20)
  # Summons a Darkglare from the Twisting Nether that blasts its target for Shadow damage, dealing increased damage for every damage over time effect you have active on any target.
  SpellAddBuff(summon_darkglare summon_darkglare=1)
Define(summon_demonic_tyrant 265187)
# Summon a Demonic Tyrant to increase the duration of all of your current lesser demons by 265273m3/1000.1 sec, and increase the damage of all of your other demons by 265273s2, while damaging your target.
  SpellInfo(summon_demonic_tyrant cd=90 duration=15)
Define(summon_felguard 30146)
# Summons a Felguard under your command as a powerful melee combatant.
  SpellInfo(summon_felguard soulshards=1)
Define(summon_imp 688)
# Summons an Imp under your command that casts ranged Firebolts.
  SpellInfo(summon_imp soulshards=1)
Define(summon_infernal 1122)
# Summons an Infernal from the Twisting Nether, impacting for (60 of Spell Power) Fire damage and stunning all enemies in the area for 2 seconds.rnrnThe Infernal will serve you for 30 seconds, dealing (50 of Spell Power)*(100+137046s3)/100 damage to all nearby enemies every 19483t1 sec and generating 264365s1 Soul Shard Fragment every 264364t1 sec.
  SpellInfo(summon_infernal cd=180 duration=0.25 channel=0.25)

Define(summon_vilefiend 264119)
# Summon a Vilefiend to fight for you for the next 15 seconds.
  SpellInfo(summon_vilefiend soulshards=1 cd=45 duration=15 talent=summon_vilefiend_talent)
Define(the_unbound_force 298452)
# Unleash the forces within the Heart of Azeroth, causing shards of Azerite to strike your target for (298407s3*((2 seconds/t)+1)+298407s3) Fire damage over 2 seconds. This damage is increased by s2 if it critically strikes.?a298456[rnrnEach time The Unbound Force causes a critical strike, it immediately strikes the target with an additional Azerite shard, up to a maximum of 298456m2.][]
  SpellInfo(the_unbound_force cd=60 duration=2 channel=2 tick=0.33)
  SpellAddBuff(the_unbound_force the_unbound_force=1)
  SpellAddTargetDebuff(the_unbound_force the_unbound_force=1)
Define(unstable_affliction 30108)
# Afflicts the target with 233490o1 Shadow damage over 8 seconds. You may afflict a target with up to s2 Unstable Afflictions at once.rnrnYou deal s3 increased damage to targets affected by your Unstable Affliction.rnrnIf dispelled, deals (14.499999999999998 of Spell Power)*s1/100 damage to the dispeller and silences them for 4 seconds.?a231791[rnrn|cFFFFFFFFRefunds 231791m1 Soul LShard:Shards; if the target dies while afflicted.|r][]
# Rank 2: Unstable Affliction refunds m1 Soul LShard:Shards; if the target dies.
  SpellInfo(unstable_affliction soulshards=1 max_stacks=10)
Define(vile_taint 278350)
# Unleashes a vile explosion at the target location, dealing o1 Shadow damage over 10 seconds to all enemies within a1 yds and reducing their movement speed by s2.
  SpellInfo(vile_taint soulshards=1 cd=20 duration=10 tick=2 talent=vile_taint_talent)
  # Suffering w1 Shadow damage every t1 sec.rnMovement slowed by s2.
  SpellAddTargetDebuff(vile_taint vile_taint=1)
Define(wild_imp 279910)
# Calls down a demonic meteor full of Wild Imps which burst forth to attack the target.rnrnDeals up to m1*86040m1 Shadowflame damage on impact to all enemies within 86040A1 yds of the target?s196283[, applies Doom to each target,][] and summons up to m1*104317m2 Wild Imps, based on Soul Shards consumed.
  SpellInfo(wild_imp duration=20 gcd=0 offgcd=1)
Define(absolute_corruption_talent 5) #21180
# Corruption is now permanent and deals s2 increased damage.rnrnDuration reduced to s1 sec against players.
Define(bilescourge_bombers_talent 3) #23138
# Tear open a portal to the nether above the target location, from which several Bilescourge will pour out of and crash into the ground over 6 seconds, dealing (21 of Spell Power) Shadow damage to all enemies within 267213A1 yards.
Define(cataclysm_talent 12) #23143
# Calls forth a cataclysm at the target location, dealing (180 of Spell Power) Shadowflame damage to all enemies within A1 yards and afflicting them with ?s980[Agony and Unstable Affliction][]?s104315[Corruption][]?s348[Immolate][]?!s980&!s104315&!s348[Agony, Unstable Affliction, Corruption, or Immolate][].
Define(channel_demonfire_talent 20) #23144
# Launches s1 bolts of felfire over 3 seconds at random targets afflicted by your Immolate within 196449A1 yds. Each bolt deals (16 of Spell Power) Fire damage to the target and (7.000000000000001 of Spell Power) Fire damage to nearby enemies.
Define(creeping_death_talent 20) #19281
# Your Agony, Corruption, Siphon Life, and Unstable Affliction deal their full damage s1 faster.
Define(dark_soul_instability_talent 21) #23092
# Infuses your soul with unstable power, increasing your critical strike chance by 113858s1 for 20 seconds.?s56228[rnrn|cFFFFFFFFPassive:|rrnIncreases your critical strike chance by 113858m1/56228m1. This effect is disabled while on cooldown.][]
Define(dark_soul_misery_talent 21) #19293
# Infuses your soul with the misery of fallen foes, increasing haste by (25 of Spell Power) for 20 seconds.
Define(deathbolt_talent 3) #23141
# Launches a bolt of death at the target, dealing s2 of the total remaining damage of your damage over time effects on the target.?s196103[rnrnCounts up to s3 sec of your Corruption's damage.][]
Define(demonic_calling_talent 4) #22045
# Shadow Bolt?s264178[ and Demonbolt have][ has] a h chance to make your next Call Dreadstalkers cost s1 less Soul Shard and have no cast time.
Define(demonic_consumption_talent 20) #22479
# Your Demonic Tyrant now destroys and absorbs the remaining power of all of your Wild Imps to empower himself.
Define(demonic_strength_talent 2) #22048
# Infuse your Felguard with demonic strength and command it to charge your target and unleash a Felstorm that will deal s2 increased damage.
Define(doom_talent 6) #23158
# Inflicts impending doom upon the target, causing (160 of Spell Power) Shadow damage after 30 seconds. rnrnIf Doom kills the target, there is a s2 chance to summon a Doomguard to fight for you for 25 seconds.rnrn|cFFFFFFFFGenerates 1 Soul Shard when dealing damage.|r
Define(drain_soul_talent 2) #23140
# Drains the target's soul, causing o1 Shadow damage over 5 seconds.rnrnDamage is increased by s2 against enemies below s3 health.rnrn|cFFFFFFFFGenerates 1 Soul Shard if the target dies during this effect.|r
Define(eradication_talent 2) #22090
# Chaos Bolt increases the damage you deal to the target by 196414s1 for 7 seconds.
Define(fire_and_brimstone_talent 11) #22043
# Incinerate now also hits all enemies near your target for s1 damage and generates s2 Soul Shard Fragment for each additional enemy hit.
Define(flashover_talent 1) #22038
# Conflagrate deals s3 increased damage and grants an additional charge of Backdraft.
Define(grimoire_of_sacrifice_talent 18) #19295
# Sacrifices your demon pet for power, gaining its command demon ability, and causing your spells to sometimes also deal (35 of Spell Power) additional Shadow damage.rnrnLasts 3600 seconds or until you summon a demon pet.
Define(grimoire_of_supremacy_talent 17) #23156
# While you have an Infernal active, every Soul Shard you spend increases the damage of your Chaos Bolt by 266091s1.
Define(grimoire_felguard_talent 18) #21717
# Summons a Felguard who attacks the target for s1 sec that deals 216187s1 increased damage.rnrnThis Felguard will stun their target when summoned.
Define(haunt_talent 17) #23159
# A ghostly soul haunts the target, dealing (55.00000000000001 of Spell Power) Shadow damage and increasing your damage dealt to the target by s2 for 15 seconds.rnrnIf the target dies, Haunt's cooldown is reset.
Define(inferno_talent 10) #22480
# Rain of Fire damage has a s1 chance to generate a Soul Shard Fragment.
Define(inner_demons_talent 17) #23146
# You passively summon a Wild Imp to fight for you every t1 sec, and have a s1 chance to also summon an additional Demon to fight for you for s2 sec.
Define(internal_combustion_talent 5) #21695
# Chaos Bolt consumes up to s1 sec of Immolate's damage over time effect on your target, instantly dealing that much damage.
Define(nether_portal_talent 21) #23091
# Tear open a portal to the Twisting Nether for 15 seconds. Every time you spend Soul Shards, you will also command demons from the Nether to come out and fight for you.
Define(phantom_singularity_talent 11) #19292
# Places a phantom singularity above the target, which consumes the life of all enemies within 205246A2 yards, dealing 8*(18 of Spell Power) damage over 16 seconds, healing you for 205246e2*100 of the damage done.
Define(power_siphon_talent 5) #21694
# Instantly sacrifice up to s1 Wild Imps to generate s1 charges of Demonic Core.
Define(shadow_embrace_talent 16) #23139
# ?s198590[Drain Soul][Shadow Bolt] applies Shadow Embrace, increasing your damage dealt to the target by 32390s1 for 10 seconds. Stacks up to 32390u times.
Define(shadowburn_talent 6) #23157
# Blasts a target for (60 of Spell Power) Shadowflame damage. rnrnIf the target dies within 5 seconds and yields experience or honor, Shadowburn's cooldown is reset.rnrn|cFFFFFFFFGenerates 245731s1 Soul Shard Fragments.|r
Define(siphon_life_talent 6) #22089
# Siphons the target's life essence, dealing o1 Shadow damage over 15 seconds and healing you for e1*100 of the damage done.
Define(soul_fire_talent 3) #22040
# Burns the enemy's soul, dealing (100 of Spell Power) Fire damage.rnrnCooldown is reduced by <cdr> sec for every Soul Shard you spend.rnrn|cFFFFFFFFGenerates 281490s1 Soul Shard Fragments.|r
Define(soul_strike_talent 11) #22042
# Command your Felguard to strike into the soul of its enemy, dealing <damage> Shadow damage.?c2[rnrn|cFFFFFFFFGenerates 1 Soul Shard.|r][]
Define(sow_the_seeds_talent 10) #19279
# Seed of Corruption now @switch<s2>[][consumes a Soul Shard, if available, to ]embeds a demon seed into s1 additional nearby enemy.
Define(summon_vilefiend_talent 12) #23160
# Summon a Vilefiend to fight for you for the next 15 seconds.
Define(vile_taint_talent 12) #22046
# Unleashes a vile explosion at the target location, dealing o1 Shadow damage over 10 seconds to all enemies within a1 yds and reducing their movement speed by s2.
Define(writhe_in_agony_talent 4) #22044
# Agony's damage may now ramp up to s2 stacks.
Define(cascading_calamity_trait 275372)
Define(dreadful_calling_trait 278727)
Define(pandemic_invocation_trait 289364)
Define(baleful_invocation_trait 287059)
Define(explosive_potential_trait 275395)
Define(shadows_bite_trait 272944)
Define(crashing_chaos_trait 277644)
    ]]
    code = code .. [[
# Aliases
SpellList(unstable_affliction_debuff unstable_affliction_1_debuff unstable_affliction_2_debuff unstable_affliction_3_debuff unstable_affliction_4_debuff unstable_affliction_5_debuff)

# Dummy buff
# Warlock.ts
Define(active_havoc_buff -80240)
	SpellInfo(active_havoc_buff duration=10)

# Warlock spells and functions.
Define(agony 980)
	SpellAddTargetDebuff(agony agony_debuff=1)
Define(agony_debuff 980)
	SpellInfo(agony_debuff duration=18 haste=spell max_stacks=10 tick=2)
	SpellInfo(agony_debuff duration=15.3 tick=1.7 talent=creeping_death_talent)
	SpellInfo(agony_debuff max_stacks=15 talent=writhe_in_agony_talent)
Define(backdraft_buff 117828)
	SpellInfo(backdraft_buff duration=10 max_stacks=4)
Define(banish 710)

	SpellInfo(bilescourge_bombers soulshards=2 cd=30)
Define(burning_rush 111400)
	SpellAddBuff(burning_rush burning_rush_buff=1)
Define(burning_rush_buff 111400)

	
	SpellRequire(call_dreadstalkers soulshards 1=buff,demonic_calling_buff)
	SpellAddTargetDebuff(call_dreadstalkers from_the_shadows_debuff talent=from_the_shadows_talent)

	SpellInfo(cataclysm cd=30)
	SpellAddTargetDebuff(cataclysm immolate_debuff=1)

	SpellInfo(channel_demonfire cd=25 channel=3 unusable=1)
	SpellRequire(channel_demonfire unusable 0=target_debuff,immolate_debuff)

	SpellInfo(chaos_bolt soulshards=2 travel_time=1)
	SpellAddBuff(chaos_bolt backdraft_buff=-1)
	SpellAddTargetDebuff(chaos_bolt eradication_debuff=1 talent=eradication_talent)
Define(command_demon 119898)

	SpellInfo(conflagrate soulshards=-0.5)
	SpellAddBuff(conflagrate backdraft_buff=1)
	SpellAddBuff(conflagrate backdraft_buff=2 talent=flashover_talent)

	

	SpellInfo(corruption_debuff duration=14 haste=spell tick=2)
	SpellInfo(corruption_debuff duration=11.9 tick=1.7 talent=creeping_death_talent)
	#SpellInfo(corruption_debuff duration=3600 talent=absolute_corruption_talent)
Define(create_healthstone 6201)
Define(create_soulwell 29893)
Define(dark_pact 108416)

	SpellInfo(dark_soul_instability cd=120)
	SpellAddBuff(dark_soul_instability dark_soul_instability_buff=1)
Define(dark_soul_instability_buff 113858)
	SpellInfo(dark_soul_instability_buff duration=20)

	SpellInfo(dark_soul_misery cd=120)
	SpellAddBuff(dark_soul_misery dark_soul_misery_buff=1)
Define(dark_soul_misery_buff 113860)
	SpellInfo(dark_soul_misery_buff duration=20)

	SpellInfo(deathbolt cd=30)

	SpellInfo(demonbolt soulshards=-2)
	SpellAddBuff(demonbolt demonic_core_buff=-1)

	SpellInfo(demonic_calling_buff duration=20)
Define(demonic_circle 48018)
Define(demonic_circle_teleport 48020)
Define(demonic_core_buff 264173)
	SpellInfo(demonic_core_buff duration=20 max_stacks=4)
Define(demonic_gateway 111771)

	SpellInfo(demonic_power duration=15)

	SpellInfo(demonic_strength cd=60)
	SpellAddPetBuff(demonic_strength demonic_strength_buff=1)
Define(demonic_strength_buff 267171)

	SpellAddTargetDebuff(doom doom_debuff=1)
Define(doom_debuff 265412)
	SpellInfo(doom_debuff duration=30)


	SpellInfo(drain_soul channel=4 haste=spell)
	SpellInfo(drain_soul replaced_by=shadow_bolt_affliction talent=!drain_soul_talent)
	SpellAddBuff(drain_soul shadow_embrace_debuff=1 talent=shadow_embrace_talent)
Define(enslave_demon 1098)
Define(eradication_debuff 196414)
	SpellInfo(eradication_debuff duration=7)
Define(eye_of_kilrogg 126)
Define(fear 5782)
Define(felguard_felstorm 89751)
	SpellInfo(felguard_felstorm cd=30 gcd=0 offgcd=1)
Define(from_the_shadows_debuff 270569)
	SpellInfo(from_the_shadows_debuff duration=12)

	SpellInfo(grimoire_felguard soulshards=1 cd=120)

	SpellInfo(grimoire_of_sacrifice cd=30 gcd=0)
	
Define(grimoire_of_sacrifice_buff 196099)
	SpellInfo(grimoire_of_sacrifice_buff duration=3600)
Define(grimoire_of_supremacy_buff 266091)

	SpellInfo(hand_of_guldan max_travel_time=1.5 soulshards=1 max_soulshards=3) # maximum observed travel time with a bit of padding

	SpellInfo(haunt cd=15 travel_time=2.3) # maximum observed travel time with a bit of padding
	SpellAddTargetDebuff(haunt haunt_debuff=1)
Define(haunt_debuff 48181)
	SpellInfo(haunt_debuff duration=15)

	SpellInfo(havoc cd=30)
	SpellAddTargetDebuff(havoc havoc_debuff=1)
Define(havoc_debuff 80240)
	SpellInfo(havoc_debuff duration=10)
Define(health_funnel 755)

	SpellAddTargetDebuff(immolate immolate_debuff=1)
Define(immolate_debuff 157736)
	SpellInfo(immolate_debuff duration=18 haste=spell tick=3)


	SpellInfo(incinerate travel_time=1 soulshards=-0.2)
	SpellAddBuff(incinerate backdraft_buff=-1)

	SpellInfo(inner_demons unusable=1)
Define(mortal_coil 6789)

	SpellInfo(nether_portal cd=180 soulshards=3)
	SpellAddBuff(nether_portal nether_portal_buff=1)
Define(nether_portal_buff 267218)
	SpellInfo(nether_portal_buff duration=20)
Define(nightfall_buff 264571)
	SpellInfo(nightfall_buff duration=1)

	SpellInfo(phantom_singularity cd=45)
 # TODO usabe with 2+ wilds imps
	SpellAddBuff(power_siphon demonic_core_buff=2)

	SpellInfo(rain_of_fire soulshards=3)
Define(reverse_entropy_buff 266030)
	SpellInfo(reverse_entropy_buff duration=8)
Define(ritual_of_summoning 698)
Define(roaring_blaze_debuff 265931)
	SpellInfo(roaring_blaze_debuff duration=6 tick=2 haste=spell)

	SpellInfo(seed_of_corruption soulshards=1)
	SpellAddTargetDebuff(seed_of_corruption seed_of_corruption_debuff=1)
Define(seed_of_corruption_debuff 27243)
	SpellInfo(seed_of_corruption_debuff duration=12)

	SpellInfo(shadow_bolt soulshards=-1 travel_time=2.2)
Define(shadow_bolt_affliction 232670)
	SpellInfo(shadow_bolt_affliction travel_time=2.2)
	SpellInfo(shadow_bolt_affliction replaced_by=drain_soul talent=drain_soul_talent)
	SpellAddBuff(shadow_bolt_affliction nightfall_buff=-1)
	SpellAddBuff(shadow_bolt_affliction shadow_embrace_debuff=1 talent=shadow_embrace_talent)
Define(shadow_embrace_debuff 32390)
	SpellInfo(shadow_embrace_debuff duration=10 max_stacks=3)

	SpellInfo(shadowburn soulshards=-0.3 charges=2 cd=12)

	SpellAddTargetDebuff(siphon_life siphon_life_debuff=1)
Define(siphon_life_debuff 63106)
	SpellInfo(siphon_life_debuff duration=15 tick=3 haste=spell)
	SpellInfo(siphon_life_debuff duration=12.8 tick=2.5 haste=spell talent=creeping_death_talent)

	SpellInfo(soul_fire soulshards=-0.4 cd=20 travel_time=1)
Define(soul_leech 108370)
Define(soul_link 108415)
Define(soul_shards 246985)

	SpellInfo(soul_strike soulshards=-1 cd=10)
Define(soulstone 20707)

	SpellInfo(summon_darkglare cd=180)

	SpellInfo(summon_demonic_tyrant cd=90)

	
Define(summon_felhunter 691)
	SpellInfo(summon_felhunter soulshards=1)

	

	SpellInfo(summon_infernal cd=180)
Define(summon_succubus 712)
	SpellInfo(summon_succubus soulshards=1)

	SpellInfo(summon_vilefiend soulshards=1 cd=45)
Define(summon_voidwalker 697)
	SpellInfo(summon_voidwalker soulshards=1)
Define(unending_breath 5697)
Define(unending_resolve 104773)
	SpellInfo(unending_resolve cd=180)
	SpellAddBuff(unending_resolve unending_resolve_buff=1)
Define(unending_resolve_buff 104773)
	SpellInfo(unending_resolve_buff duration=8)

	SpellInfo(unstable_affliction soulshards=1)
	# TODO apply affliction debuff
Define(unstable_affliction_1_debuff 233940)
	SpellInfo(unstable_affliction_1_debuff duration=8 tick=2)
	SpellInfo(unstable_affliction_1_debuff duration=6.8 tick=1.7 talent=creeping_death_talent)
Define(unstable_affliction_2_debuff 233946)
	SpellInfo(unstable_affliction_2_debuff duration=8 tick=2)
	SpellInfo(unstable_affliction_2_debuff duration=6.8 tick=1.7 talent=creeping_death_talent)
Define(unstable_affliction_3_debuff 233947)
	SpellInfo(unstable_affliction_3_debuff duration=8 tick=2)
	SpellInfo(unstable_affliction_3_debuff duration=6.8 tick=1.7 talent=creeping_death_talent)
Define(unstable_affliction_4_debuff 233948)
	SpellInfo(unstable_affliction_4_debuff duration=8 tick=2)
	SpellInfo(unstable_affliction_4_debuff duration=6.8 tick=1.7 talent=creeping_death_talent)
Define(unstable_affliction_5_debuff 233949)
	SpellInfo(unstable_affliction_5_debuff duration=8 tick=2)
	SpellInfo(unstable_affliction_5_debuff duration=6.8 tick=1.7 talent=creeping_death_talent)

	SpellInfo(vile_taint soulshards=1 cd=20)
Define(vile_taint_debuff 278350)
	SpellInfo(vile_taint_debuff duration=10)

# Azerite Traits
Define(cascading_calamity_trait 275376)
 #TODO verify buff id

Define(forbidden_knowledge_buff 278738) #TODO verify buff id
Define(inevitable_demise_trait 273521)
Define(inevitable_demise_buff 273521) #TODO verify buff id

# Talents


Define(burning_rush_talent 8)



Define(dark_pact_talent 9)


Define(darkfury_talent 13)

Define(demon_skin_talent 7)

Define(demonic_circle_talent 15)
Define(demonic_consumption_talent 20)



Define(dreadlash_talent 1)



Define(from_the_shadows_talent 10)







Define(mortal_coil_talent 14)

Define(nightfall_talent 1)


Define(reverse_entropy_talent 4)

Define(sacrificed_souls_talent 19)



Define(demo_soul_conduit_talent 16)
Define(soul_conduit_talent 19)







# Legendary items
Define(deadwind_harvester_buff 216708)
Define(sindorei_spite_icd 208871) # TODO should be the internal cooldown of the spell
Define(tormented_souls_buff 216695)


# Pets
Define(demonic_tyrant 135002)
Define(wild_imp 55659)
Define(wild_imp_inner_demons 143622)
Define(dreadstalker 98035)
Define(darkglare 103673)
Define(infernal 89)
Define(felguard 17252)

# Non-default tags for OvaleSimulationCraft.
	SpellInfo(dark_soul_instability tag=cd)
	SpellInfo(dark_soul_knowledge tag=cd)
	SpellInfo(dark_soul_misery tag=cd)
	SpellInfo(grimoire_of_sacrifice tag=main)
	SpellInfo(havoc tag=shortcd)
	SpellInfo(metamorphosis tag=main)
	SpellInfo(service_doomguard tag=shortcd)
	SpellInfo(service_felguard tag=shortcd)
	SpellInfo(service_felhunter tag=shortcd)
	SpellInfo(service_imp tag=shortcd)
	SpellInfo(service_infernal tag=shortcd)
	SpellInfo(service_succubus tag=shortcd)
	SpellInfo(service_voidwalker tag=shortcd)
	SpellInfo(summon_felguard tag=shortcd)
	SpellInfo(summon_felhunter tag=shortcd)
	SpellInfo(summon_imp tag=shortcd)
	SpellInfo(summon_succubus tag=shortcd)
	SpellInfo(summon_voidwalker tag=shortcd)
]]
    OvaleScripts:RegisterScript("WARLOCK", nil, name, desc, code, "include")
end
