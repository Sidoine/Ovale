local __exports = LibStub:NewLibrary("ovale/scripts/ovale_mage_spells", 80000)
if not __exports then return end
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
__exports.register = function()
    local name = "ovale_mage_spells"
    local desc = "[8.0] Ovale: Mage spells"
    local code = [[Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you their power for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
Define(arcane_barrage 44425)
# Launches bolts of arcane energy at the enemy target, causing (80 of Spell Power) Arcane damage. rnrnFor each Arcane Charge, deals 36032s2 additional damage?a231564[ and hits 36032s3 additional nearby Ltarget:targets; for s2 of its damage][].rnrn|cFFFFFFFFConsumes all Arcane Charges.|r
# Rank 2: Arcane Barrage hits s1 additional Ltarget:targets; within 44425s3 yds per Arcane Charge for 44425s2 damage.
  SpellInfo(arcane_barrage cd=3)
Define(arcane_blast 30451)
# Blasts the target with energy, dealing (55.00000000000001 of Spell Power) Arcane damage.rnrnEach Arcane Charge increases damage by 36032s1 and mana cost by 36032s5, and reduces cast time by 36032s4.rnrn|cFFFFFFFFGenerates 1 Arcane Charge.|r
  SpellInfo(arcane_blast arcanecharges=-1)
Define(arcane_explosion 1449)
# Causes an explosion of magic around the caster, dealing (60 of Spell Power) Arcane damage to all enemies within A2 yards.rnrn|cFFFFFFFFGenerates s1 Arcane Charge if any targets are hit.|r
  SpellInfo(arcane_explosion arcanecharges=-1)
Define(arcane_familiar 205022)
# Summon a Familiar that attacks your enemies and increases your maximum mana by 210126s1 for 3600 seconds.
  SpellInfo(arcane_familiar cd=10 duration=3600 talent=arcane_familiar_talent)

  SpellAddTargetDebuff(arcane_familiar arcane_familiar=1)
Define(arcane_intellect 1459)
# Infuses the target with brilliance, increasing their Intellect by s1 for 3600 seconds.  rnrnIf target is in your party or raid, all party and raid members will be affected.
  SpellInfo(arcane_intellect duration=3600)
  # Intellect increased by w1.
  SpellAddTargetDebuff(arcane_intellect arcane_intellect=1)
Define(arcane_missiles 5143)
# Launches five waves of Arcane Missiles at the enemy over 2.5 seconds, causing a total of 5*(50 of Spell Power) Arcane damage.
  SpellInfo(arcane_missiles duration=2.5 channel=2.5 tick=0.625)
  SpellAddBuff(arcane_missiles arcane_missiles=1)
  SpellAddTargetDebuff(arcane_missiles arcane_missiles=1)
Define(arcane_orb 153626)
# Launches an Arcane Orb forward from your position, traveling up to 40 yards, dealing (120 of Spell Power) Arcane damage to enemies it passes through.rnrn|cFFFFFFFFGrants 1 Arcane Charge when cast and every time it deals damage.|r
  SpellInfo(arcane_orb cd=20 duration=2.5 arcanecharges=-1 talent=arcane_orb_talent)
Define(arcane_power 12042)
# For 10 seconds, you deal s1 more spell damage and your spells cost s2 less mana.
  SpellInfo(arcane_power cd=90 duration=10)
  # Spell damage increased by w1.rnMana costs of your damaging spells reduced by w2.
  SpellAddBuff(arcane_power arcane_power=1)
Define(battle_potion_of_intellect 279151)
# Increases your Intellect by s1 for 25 seconds.
  SpellInfo(battle_potion_of_intellect cd=1 duration=25 gcd=0 offgcd=1)
  # Intellect increased by w1.
  SpellAddBuff(battle_potion_of_intellect battle_potion_of_intellect=1)
Define(berserking 26297)
# Increases your haste by s1 for 10 seconds.
  SpellInfo(berserking cd=180 duration=10 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking=1)
Define(berserking_buff 200953)
# Rampage and Execute have a chance to activate Berserking, increasing your attack speed and critical strike chance by 200953s1 every 200951t1 sec for 12 seconds.
  SpellInfo(berserking_buff duration=3 max_stacks=12 gcd=0 offgcd=1)
  # Attack speed and critical strike chance increased by s1.
  SpellAddBuff(berserking_buff berserking_buff=1)
Define(blast_wave 157981)
# Causes an explosion around yourself, dealing (45 of Spell Power) Fire damage to all enemies within A1 yards, knocking them back, and reducing movement speed by s2 for 4 seconds.
  SpellInfo(blast_wave cd=25 duration=4 talent=blast_wave_talent)
  # Movement speed reduced by s2.
  SpellAddTargetDebuff(blast_wave blast_wave=1)
Define(blink 1953)
# Teleports you forward A1 yds or until reaching an obstacle, and frees you from all stuns and bonds.
  SpellInfo(blink cd=0.5 charge_cd=15 duration=0.3 channel=0.3)
  # Blinking.
  SpellAddBuff(blink blink=1)
Define(blizzard 190356)
# Ice shards pelt the target area, dealing 190357m1*8 Frost damage over 8 seconds and reducing movement speed by 205708s1 for 15 seconds.?a236662[rnrnEach time Blizzard deals damage, the cooldown of Frozen Orb is reduced by 236662s1/100.1 sec.][]
# Rank 2: Each time Blizzard deals damage, the cooldown of Frozen Orb is reduced by s1/100.1 sec.
  SpellInfo(blizzard cd=8 duration=8)
Define(charged_up 205032)
# Immediately grants s1 Arcane Charges.
  SpellInfo(charged_up cd=40 duration=10 arcanecharges=-4 talent=charged_up_talent)
  SpellAddBuff(charged_up charged_up=1)
Define(clearcasting 79684)
# For each c*100/s1 mana you spend, you have a 1 chance to gain Clearcasting, making your next Arcane Missiles or Arcane Explosion free and channel 277726s1 faster.
  SpellInfo(clearcasting channel=0 gcd=0 offgcd=1)
  SpellAddBuff(clearcasting clearcasting=1)
Define(combustion 190319)
# Engulfs you in flames for 10 seconds, increasing your spells' critical strike chance by s1 and granting you Mastery equal to s3 your Critical Strike stat. Castable while casting other spells.
  SpellInfo(combustion cd=120 duration=10 gcd=0 offgcd=1 tick=0.5)
  # Critical Strike chance of your spells increased by w1.?a231630[rnMastery increased by w2.][]
  SpellAddBuff(combustion combustion=1)
Define(comet_storm 153595)
# Calls down a series of 7 icy comets on and around the target, that deals up to 7*(45 of Spell Power) Frost damage to all enemies within 228601A1 yds of its impacts.
  SpellInfo(comet_storm cd=30 talent=comet_storm_talent)
Define(cone_of_cold 120)
# Targets in a cone in front of you take (37.5 of Spell Power) Frost damage and have movement slowed by 212792m1 for 5 seconds.
  SpellInfo(cone_of_cold cd=12)
Define(counterspell 2139)
# Counters the enemy's spellcast, preventing any spell from that school of magic from being cast for 6 seconds?s12598[ and silencing the target for 55021d][].
  SpellInfo(counterspell cd=24 duration=6 gcd=0 offgcd=1 interrupt=1)
Define(dragons_breath 31661)
# Enemies in a cone in front of you take (58.25 of Spell Power) Fire damage and are disoriented for 4 seconds. Damage will cancel the effect.
  SpellInfo(dragons_breath cd=20 duration=4)
  # Disoriented.
  SpellAddTargetDebuff(dragons_breath dragons_breath=1)
Define(ebonbolt 257537)
# Launch a bolt of ice at the enemy, dealing (200 of Spell Power) Frost damage and granting you Brain Freeze.
  SpellInfo(ebonbolt cd=45 talent=ebonbolt_talent)
Define(evocation 12051)
# Increases your mana regeneration by s1 for 6 seconds.
# Rank 2: Evocation's cooldown is reduced by s1.
  SpellInfo(evocation cd=180 duration=6 channel=6)
  # Mana regeneration increased by s1.
  SpellAddBuff(evocation evocation=1)
Define(fire_blast 108853)
# Blasts the enemy for (72 of Spell Power) Fire damage. Castable while casting other spells.?a231568[ Always deals a critical strike.][]
# Rank 2: Fire Blast always deals a critical strike.
  SpellInfo(fire_blast cd=0.5 charge_cd=12 gcd=0 offgcd=1)
Define(fireball 133)
# Throws a fiery ball that causes (59 of Spell Power) Fire damage.
  SpellInfo(fireball)
Define(fireblood 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. 
  SpellInfo(fireblood cd=120 gcd=0 offgcd=1)
Define(flamestrike 2120)
# Calls down a pillar of fire, burning all enemies within the area for s1 Fire damage and reducing their movement speed by (50 of Spell Power) for 8 seconds.
  SpellInfo(flamestrike duration=8)
  # Movement speed slowed by s2.
  SpellAddTargetDebuff(flamestrike flamestrike=1)
Define(flurry 44614)
# Unleash a flurry of ice, striking the target s1 times for a total of (31.6 of Spell Power)*m1 Frost damage. Each hit reduces the target's movement speed by 228354s1 for 1 second.rnrnWhile Brain Freeze is active, Flurry applies Winter's Chill, causing your target to take damage from your spells as if it were frozen.
  SpellInfo(flurry)

Define(frostbolt 116)
# Launches a bolt of frost at the enemy, causing (51.1 of Spell Power) Frost damage and slowing movement speed by 205708s1 for 15 seconds.
  SpellInfo(frostbolt)

Define(frozen_orb 84714)
# Launches an orb of swirling ice up to s1 yards forward which deals up to 20*84721s2 Frost damage to all enemies it passes through. Grants 1 charge of Fingers of Frost when it first damages an enemy.rnrnEnemies damaged by the Frozen Orb are slowed by 205708s1 for 15 seconds.
  SpellInfo(frozen_orb cd=60 duration=15 channel=15)
Define(glacial_spike 199786)
# Conjures a massive spike of ice, and merges your current Icicles into it. It impales your target, dealing (320 of Spell Power) damage plus all of the damage stored in your Icicles, and freezes the target in place for 4 seconds. Damage may interrupt the freeze effect.rnrnRequires 5 Icicles to cast.rnrn|cFFFFFFFFPassive:|r Ice Lance no longer launches Icicles.
  SpellInfo(glacial_spike talent=glacial_spike_talent)
Define(ice_floes 108839)
# Makes your next Mage spell with a cast time shorter than s2 sec castable while moving. Unaffected by the global cooldown and castable while casting.
  SpellInfo(ice_floes cd=20 duration=15 max_stacks=3 gcd=0 offgcd=1 talent=ice_floes_talent)
  # Able to move while casting spells.
  SpellAddBuff(ice_floes ice_floes=1)
Define(ice_lance 30455)
# Quickly fling a shard of ice at the target, dealing (35 of Spell Power) Frost damage?s56377[, and (35 of Spell Power)*56377m2/100 Frost damage to a second nearby target][].rnrnIce Lance damage is tripled against frozen targets.
  SpellInfo(ice_lance)
  SpellInfo(fire_blast replaced_by=ice_lance)
Define(ice_nova 157997)
# Causes a whirl of icy wind around the enemy, dealing (45 of Spell Power)*s3/100 Frost damage to the target and (45 of Spell Power) Frost damage to all other enemies within a2 yards, and freezing them in place for 2 seconds.
  SpellInfo(ice_nova cd=25 duration=2 talent=ice_nova_talent)
  # Frozen.
  SpellAddTargetDebuff(ice_nova ice_nova=1)
Define(icy_veins 12472)
# Accelerates your spellcasting for 20 seconds, granting m1 haste and preventing damage from delaying your spellcasts.
  SpellInfo(icy_veins cd=180 duration=20)
  # Haste increased by w1 and immune to pushback.
  SpellAddBuff(icy_veins icy_veins=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)

Define(living_bomb 44457)
# The target becomes a Living Bomb, taking 217694o1 Fire damage over 4 seconds, and then exploding to deal an additional (14.000000000000002 of Spell Power) Fire damage to the target and all other enemies within 44461A2 yards.rnrnOther enemies hit by this explosion also become a Living Bomb, but this effect cannot spread further.
  SpellInfo(living_bomb cd=12 talent=living_bomb_talent)
Define(meteor 117588)
# Call down a molten meteor on your target, dealing (75 of Spell Power) damage to all enemies within A1 yards of your target.
  SpellInfo(meteor cd=60 gcd=0 offgcd=1)
Define(mirror_image 55342)
# Creates s2 copies of you nearby for 40 seconds, which cast spells and attack your enemies.
  SpellInfo(mirror_image cd=120 duration=40 talent=mirror_image_talent)
  SpellAddBuff(mirror_image mirror_image=1)
Define(nether_tempest 114923)
# Places a Nether Tempest on the target which deals 114923o1 Arcane damage over 12 seconds to the target and 114954m1*12/t1 to all enemies within 10 yards. Limit 1 target.rnrnDamage increased by 36032s1 per Arcane Charge.
  SpellInfo(nether_tempest duration=12 tick=1 talent=nether_tempest_talent)
  # Deals w1 Arcane damage and an additional w1 Arcane damage to all enemies within 114954A1 yards every t sec.
  SpellAddTargetDebuff(nether_tempest nether_tempest=1)
Define(phoenix_flames 257541)
# Hurls a Phoenix that deals (75 of Spell Power) Fire damage to the target and splashes (20 of Spell Power) Fire damage to other nearby enemies. Always deals a critical strike.
  SpellInfo(phoenix_flames cd=30 talent=phoenix_flames_talent)
Define(preheat 273331)
# Scorch increases the damage the target takes from your Fire Blast by s1 for 30 seconds.
  SpellInfo(preheat channel=0 gcd=0 offgcd=1)

Define(presence_of_mind 205025)
# Causes your next n Arcane Blasts to be instant cast.
  SpellInfo(presence_of_mind cd=60 gcd=0 offgcd=1)
  # Arcane Blast is instant cast.
  SpellAddBuff(presence_of_mind presence_of_mind=1)
Define(pyroblast 11366)
# Hurls an immense fiery boulder that causes (123.9 of Spell Power) Fire damage.
  SpellInfo(pyroblast)
Define(pyroclasm 269650)
# Consuming Hot Streak has a s1 chance to make your next non-instant Pyroblast cast within 15 seconds deal 269651s1 additional damage.rnrnMaximum 2 charges.
  SpellInfo(pyroclasm channel=0 gcd=0 offgcd=1 talent=pyroclasm_talent)
  SpellAddBuff(pyroclasm pyroclasm=1)
Define(quaking_palm 107079)
# Strikes the target with lightning speed, incapacitating them for 4 seconds, and turns off your attack.
  SpellInfo(quaking_palm cd=120 duration=4 gcd=1)
  # Incapacitated.
  SpellAddTargetDebuff(quaking_palm quaking_palm=1)
Define(ray_of_frost 205021)
# Channel an icy beam at the enemy for 5 seconds, dealing (120 of Spell Power) Frost damage every t2 sec and slowing movement by s4. Each time Ray of Frost deals damage, its damage and snare increases by 208141s1.rnrnGenerates s3 charges of Fingers of Frost over its duration.
  SpellInfo(ray_of_frost cd=75 duration=5 channel=5 tick=1 talent=ray_of_frost_talent)
  # Movement slowed by w1.rnTaking w2 Frost damage every t2 sec.
  SpellAddTargetDebuff(ray_of_frost ray_of_frost=1)
Define(rising_death 252346)
# Chance to create multiple potions.
  SpellInfo(rising_death gcd=0 offgcd=1)
Define(rule_of_threes 264354)
# When you gain your third Arcane Charge, the cost of your next Arcane Blast or Arcane Missiles is reduced by 264774s1.
  SpellInfo(rule_of_threes channel=0 gcd=0 offgcd=1 talent=rule_of_threes_talent)
  SpellAddBuff(rule_of_threes rule_of_threes=1)
Define(rune_of_power 116011)
# Places a Rune of Power on the ground for 10 seconds which increases your spell damage by 116014s1 while you stand within 8 yds.
  SpellInfo(rune_of_power cd=10 charge_cd=40 duration=10 talent=rune_of_power_talent)
Define(scorch 2948)
# Scorches an enemy for (17.7 of Spell Power) Fire damage. Castable while moving.
  SpellInfo(scorch)
Define(shimmer 212653)
# Teleports you A1 yards forward, unless something is in the way. Unaffected by the global cooldown and castable while casting.
  SpellInfo(shimmer cd=0.5 charge_cd=20 duration=0.65 channel=0.65 gcd=0 offgcd=1 talent=shimmer_talent)
  # Shimmering.
  SpellAddBuff(shimmer shimmer=1)
Define(summon_water_elemental 31687)
# Summons a Water Elemental to follow and fight for you.
  SpellInfo(summon_water_elemental cd=30)
Define(supernova 157980)
# Pulses arcane energy around the target enemy or ally, dealing (30 of Spell Power) Arcane damage to all enemies within A2 yards, and knocking them upward. A primary enemy target will take s1 increased damage.
  SpellInfo(supernova cd=25 talent=supernova_talent)
Define(time_warp 80353)
# Warp the flow of time, increasing haste by (25 of Spell Power) for all party and raid members for 40 seconds.rnrnAllies will be unable to benefit from Bloodlust, Heroism, or Time Warp again for 600 seconds.
  SpellInfo(time_warp cd=300 duration=40 channel=40 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(time_warp time_warp=1)
Define(winters_reach 273347)
# Consuming Brain Freeze has a s2 chance to make your next non-instant Flurry cast within 15 seconds deal an additional s1 damage per hit.
  SpellInfo(winters_reach duration=15 channel=15 gcd=0 offgcd=1)
  # Damage of your next non-instant Flurry increased by w1 per hit.
  SpellAddBuff(winters_reach winters_reach=1)

Define(alexstraszas_fury_talent 11) #22465
# Dragon's Breath always critically strikes and contributes to Hot Streak.
Define(amplification_talent 1) #22458
# When Clearcast, Arcane Missiles fires s2 additional lmissile:missiles;.
Define(arcane_familiar_talent 3) #22464
# Summon a Familiar that attacks your enemies and increases your maximum mana by 210126s1 for 3600 seconds.
Define(arcane_orb_talent 21) #21145
# Launches an Arcane Orb forward from your position, traveling up to 40 yards, dealing (120 of Spell Power) Arcane damage to enemies it passes through.rnrn|cFFFFFFFFGrants 1 Arcane Charge when cast and every time it deals damage.|r
Define(blast_wave_talent 6) #23074
# Causes an explosion around yourself, dealing (45 of Spell Power) Fire damage to all enemies within A1 yards, knocking them back, and reducing movement speed by s2 for 4 seconds.
Define(charged_up_talent 11) #22467
# Immediately grants s1 Arcane Charges.
Define(comet_storm_talent 18) #22473
# Calls down a series of 7 icy comets on and around the target, that deals up to 7*(45 of Spell Power) Frost damage to all enemies within 228601A1 yds of its impacts.
Define(ebonbolt_talent 12) #22469
# Launch a bolt of ice at the enemy, dealing (200 of Spell Power) Frost damage and granting you Brain Freeze.
Define(firestarter_talent 1) #22456
# Your Fireball and Pyroblast spells always deal a critical strike when the target is above s1 health.
Define(flame_patch_talent 16) #22451
# Flamestrike leaves behind a patch of flames which burns enemies within it for 8*(6 of Spell Power) Fire damage over 8 seconds. 
Define(freezing_rain_talent 16) #22454
# Frozen Orb makes Blizzard instant cast and increases its damage done by 270232s2 for 12 seconds.
Define(glacial_spike_talent 21) #21634
# Conjures a massive spike of ice, and merges your current Icicles into it. It impales your target, dealing (320 of Spell Power) damage plus all of the damage stored in your Icicles, and freezes the target in place for 4 seconds. Damage may interrupt the freeze effect.rnrnRequires 5 Icicles to cast.rnrn|cFFFFFFFFPassive:|r Ice Lance no longer launches Icicles.
Define(ice_floes_talent 6) #23073
# Makes your next Mage spell with a cast time shorter than s2 sec castable while moving. Unaffected by the global cooldown and castable while casting.
Define(ice_nova_talent 3) #22463
# Causes a whirl of icy wind around the enemy, dealing (45 of Spell Power)*s3/100 Frost damage to the target and (45 of Spell Power) Frost damage to all other enemies within a2 yards, and freezing them in place for 2 seconds.
Define(kindling_talent 19) #21631
# Your Fireball, Pyroblast, Fire Blast, and Phoenix Flames critical strikes reduce the remaining cooldown on Combustion by s1 sec.
Define(living_bomb_talent 18) #22472
# The target becomes a Living Bomb, taking 217694o1 Fire damage over 4 seconds, and then exploding to deal an additional (14.000000000000002 of Spell Power) Fire damage to the target and all other enemies within 44461A2 yards.rnrnOther enemies hit by this explosion also become a Living Bomb, but this effect cannot spread further.
Define(mirror_image_talent 8) #22445
# Creates s2 copies of you nearby for 40 seconds, which cast spells and attack your enemies.
Define(nether_tempest_talent 18) #22474
# Places a Nether Tempest on the target which deals 114923o1 Arcane damage over 12 seconds to the target and 114954m1*12/t1 to all enemies within 10 yards. Limit 1 target.rnrnDamage increased by 36032s1 per Arcane Charge.
Define(overpowered_talent 19) #21630
# Arcane Power now increases damage by 30+s1 and reduces mana costs by 30-s2.
Define(phoenix_flames_talent 12) #22468
# Hurls a Phoenix that deals (75 of Spell Power) Fire damage to the target and splashes (20 of Spell Power) Fire damage to other nearby enemies. Always deals a critical strike.
Define(pyroclasm_talent 20) #22220
# Consuming Hot Streak has a s1 chance to make your next non-instant Pyroblast cast within 15 seconds deal 269651s1 additional damage.rnrnMaximum 2 charges.
Define(ray_of_frost_talent 20) #22309
# Channel an icy beam at the enemy for 5 seconds, dealing (120 of Spell Power) Frost damage every t2 sec and slowing movement by s4. Each time Ray of Frost deals damage, its damage and snare increases by 208141s1.rnrnGenerates s3 charges of Fingers of Frost over its duration.
Define(resonance_talent 10) #22453
# Arcane Barrage deals s1 increased damage per target it hits.
Define(rule_of_threes_talent 2) #22461
# When you gain your third Arcane Charge, the cost of your next Arcane Blast or Arcane Missiles is reduced by 264774s1.
Define(rune_of_power_talent 9) #22447
# Places a Rune of Power on the ground for 10 seconds which increases your spell damage by 116014s1 while you stand within 8 yds.
Define(searing_touch_talent 3) #22462
# Scorch deals s2 increased damage and is a guaranteed Critical Strike when the target is below s1 health.
Define(shimmer_talent 5) #22443
# Teleports you A1 yards forward, unless something is in the way. Unaffected by the global cooldown and castable while casting.
Define(splitting_ice_talent 17) #23176
# Your Ice Lance and Icicles now deal s3 increased damage, and hit a second nearby target for s2 of their damage.rnrnYour Ebonbolt and Glacial Spike also hit a second nearby target for s2 of its damage.
Define(supernova_talent 12) #22470
# Pulses arcane energy around the target enemy or ally, dealing (30 of Spell Power) Arcane damage to all enemies within A2 yards, and knocking them upward. A primary enemy target will take s1 increased damage.
Define(arcane_pummeling_trait 270669)
Define(preheat_trait 273331)
Define(winters_reach_trait 273346)
    ]]
    code = code .. [[
# Mage spells and functions.
SpellRequire(arcane_intellect unusable 1=buff,arcane_intellect)


Define(arcane_affinity 166871)
	SpellInfo(arcane_affinity duration=15)

	SpellAddBuff(arcane_blast presence_of_mind_buff=0 if_spell=presence_of_mind)
	SpellAddBuff(arcane_blast profound_magic_buff=0 itemset=T16_caster itemcount=2 specialization=arcane)
	SpellAddBuff(arcane_blast ice_floes_buff=0 if_spell=ice_floes)
Define(arcane_brilliance 1459)
	SpellAddBuff(arcane_brilliance arcane_brilliance_buff=1)
Define(arcane_brilliance_buff 1459)
	SpellInfo(arcane_brilliance_buff duration=3600)
Define(arcane_charge 114664)
Define(arcane_charge_debuff 36032)
	SpellInfo(arcane_charge_debuff duration=15 max_stacks=4)

	
Define(arcane_instability_buff 166872)
	SpellInfo(arcane_instability_buff duration=15)

	SpellInfo(arcane_missiles duration=2 travel_time=1 arcanecharges=-1)
	SpellRequire(arcane_missiles unusable 1=buff,!arcane_missiles_buff)
	SpellAddBuff(arcane_missiles arcane_instability_buff=0 itemset=T17 itemcount=4 specialization=arcane)
	SpellAddBuff(arcane_missiles arcane_missiles_buff=-1)
	SpellAddBuff(arcane_missiles arcane_power_buff=extend,2 if_spell=overpowered)
Define(arcane_missiles_buff 79683)
	SpellInfo(arcane_missiles_buff duration=20 max_stacks=3)

	SpellInfo(arcane_orb cd=15)

	SpellInfo(arcane_power cd=90 gcd=0)
	SpellAddBuff(arcane_power arcane_power_buff=1)
Define(arcane_power_buff 12042)
	SpellInfo(arcane_power_buff duration=15)

Define(blazing_speed 108843)
	SpellInfo(blazing_speed cd=25 gcd=0 offgcd=1)

	SpellInfo(blink cd=15)

	SpellInfo(blizzard cd=8 haste=spell)
	SpellAddBuff(blizzard ice_floes_buff=0 if_spell=ice_floes)
Define(brain_freeze 44549)
Define(brain_freeze_buff 190446)
	SpellInfo(brain_freeze_buff duration=15)

	SpellInfo(charged_up arcanecharges=-4)
Define(cinderstorm 198929)
	SpellInfo(cinderstorm cd=9)
Define(cold_snap 11958)
	SpellInfo(cold_snap cd=180 gcd=0 offgcd=1)

	SpellInfo(combustion cd=120 gcd=0)
	SpellAddBuff(combustion combustion_buff=1)
Define(combustion_buff 190319)
	SpellInfo(combustion_buff duration=10)

	SpellInfo(comet_storm cd=30 travel_time=1)

	

	SpellInfo(counterspell cd=24 gcd=0 interrupt=1)
Define(deep_freeze 44572)
	SpellInfo(deep_freeze cd=30 interrupt=1)
	SpellAddBuff(deep_freeze fingers_of_frost_buff=-1 if_spell=fingers_of_frost)

	SpellInfo(dragons_breath cd=20)

	SpellInfo(ebonbolt cd=45 tag=main)
	SpellAddBuff(ebonbolt brain_freeze_buff=1)
Define(erupting_infernal_core_buff 248147)
	SpellInfo(erupting_infernal_core_buff duration=30)

	SpellInfo(evocation cd=120 channel=3 haste=spell)
	SpellInfo(evocation add_cd=-30 if_spell=improved_evocation)
	SpellAddBuff(evocation ice_floes_buff=0 if_spell=ice_floes)

Define(fingers_of_frost_buff 44544)
	SpellInfo(fingers_of_frost_buff duration=15 max_stacks=2)
	SpellInfo(fingers_of_frost_buff max_stacks=4 itemset=T18 itemcount=4)

	SpellInfo(fire_blast gcd=0 offgcd=1 cd=12 charges=1)
	SpellInfo(fire_blast cd=10 charges=2 talent=flame_on_talent)

	SpellAddBuff(fireball erupting_infernal_core_buff=0)

	SpellInfo(flamestrike cd=12)
	SpellInfo(flamestrike cd=0 if_spell=improved_flamestrike)
	SpellAddBuff(flamestrike ice_floes_buff=0 if_spell=ice_floes)
	SpellAddTargetDebuff(flamestrike flamestrike_debuff=1)
	SpellAddBuff(flamestrike hot_streak_buff=0)
Define(flamestrike_debuff 2120)
	SpellInfo(flamestrike_debuff duration=8 haste=spell tick=2)

	SpellInfo(flurry mana=4)
Define(freeze 33395)
Define(frost_bomb 112948)
	SpellAddTargetDebuff(frost_bomb frost_bomb_debuff=1)
Define(frost_bomb_debuff 112948)
	SpellInfo(frost_bomb_debuff duration=12)
Define(frost_nova 122)

	SpellInfo(frostbolt travel_time=1)
	SpellAddBuff(frostbolt ice_floes_buff=0 if_spell=ice_floes)
Define(frostfire_bolt 44614)
	SpellInfo(frostfire_bolt travel_time=1)
	SpellAddBuff(frostfire_bolt brain_freeze_buff=0 if_spell=brain_freeze)
	SpellAddBuff(frostfire_bolt ice_floes_buff=0 if_spell=ice_floes)

	SpellInfo(frozen_orb cd=60)
	SpellAddBuff(frozen_orb frozen_mass_buff=1 itemset=T20 itemcount=2)
Define(frozen_orb_debuff 84721)
	SpellInfo(frozen_orb_debuff duration=2)
Define(frozen_mass_buff 242253)
	SpellInfo(frozen_mass_buff duration=10)
Define(frozen_touch 205030)
	SpellInfo(frozen_touch cd=30)
	SpellAddBuff(frozen_touch fingers_of_frost_buff=2)

	SpellInfo(glacial_spike mana=1 unusable=1)
	SpellRequire(glacial_spike unusable 0=buff,icicles_buff,5)
	SpellAddBuff(glacial_spike icicles_buff=0)
Define(heating_up_buff 48107)
	SpellInfo(heating_up_buff duration=10)
Define(hot_streak_buff 48108)
Define(ice_barrier 11426)
	SpellInfo(ice_barrier cd=25)

	SpellAddBuff(ice_floes ice_floes_buff=1)
Define(ice_floes_buff 108839)
	SpellInfo(ice_floes_buff duration=15)

	SpellInfo(ice_lance travel_time=1.3) # maximum observed travel time with a bit of padding
	SpellAddBuff(ice_lance fingers_of_frost_buff=-1 if_spell=fingers_of_frost)
	SpellAddBuff(ice_lance icy_veins_buff=extend,2 if_spell=thermal_void)

Define(ice_shard_buff 166869)
	SpellInfo(ice_shard_buff duration=10 max_stacks=10)
Define(icicles_buff 205473)
	SpellInfo(icicles_buff duration=60)
Define(icy_hand 220817)

	SpellInfo(icy_veins cd=180)
	SpellInfo(icy_veins add_cd=-90 itemset=T14 itemcount=4)
	SpellAddBuff(icy_veins icy_veins_buff=1)
Define(icy_veins_buff 12472)
	SpellInfo(icy_veins_buff duration=20)
Define(ignite_debuff 12654)
	SpellInfo(ignite_debuff duration=5 tick=1)
Define(improved_evocation 157614)
Define(improved_flamestrike 157621)

Define(incanters_flow_buff 116267)
	SpellInfo(incanters_flow_buff duration=25 max_stacks=5)
Define(inferno_blast 108853)
	SpellInfo(inferno_blast cd=8)
	SpellInfo(inferno_blast add_cd=-2 itemset=T17 itemcount=2)
Define(kaelthas_ultimate_ability_buff 209455)

	SpellInfo(living_bomb gcd=1)
	SpellAddTargetDebuff(living_bomb living_bomb_debuff=1)
Define(living_bomb_debuff 44457)
	SpellInfo(living_bomb duration=12 haste=spell tick=3)
Define(mark_of_doom_debuff 184073)
	SpellInfo(mark_of_doom_debuff duration=10)
Define(meteor 153561)
	SpellInfo(meteor cd=45 travel_time=1)

	SpellInfo(mirror_image cd=120)

	SpellAddTargetDebuff(nether_tempest nether_tempest_debuff=1)
Define(nether_tempest_debuff 114923)
	SpellInfo(nether_tempest_debuff duration=12 haste=spell tick=1)
Define(overpowered 155147)
Define(pet_freeze 33395)
Define(pet_water_jet 135029)
Define(pet_water_jet_debuff 135029)
Define(phoenixs_flames 194466)
Define(polymorph 118)
	SpellAddBuff(polymorph presence_of_mind_buff=0)
	SpellAddTargetDebuff(polymorph polymorph_debuff=1)
Define(polymorph_debuff 118)
	SpellInfo(polymorph_debuff duration=50)
Define(potent_flames_buff 145254)
	SpellInfo(potent_flames_buff duration=5 max_stacks=5)

	SpellInfo(presence_of_mind cd=90 gcd=0)
	SpellAddBuff(presence_of_mind presence_of_mind_buff=1)
Define(presence_of_mind_buff 205025)
Define(profound_magic_buff 145252)
	SpellInfo(profound_magic_buff duration=10 max_stacks=4)
Define(prismatic_crystal 152087)
	SpellInfo(prismatic_crystal cd=90 duration=12 totem=1)

	SpellInfo(pyroblast travel_time=1)
	SpellInfo(pyroblast damage=FirePyroblastHitDamage specialization=fire)
	SpellAddBuff(pyroblast ice_floes_buff=0 if_spell=ice_floes)
	SpellAddBuff(pyroblast pyroblast_buff=0)
	SpellAddTargetDebuff(pyroblast pyroblast_debuff=1)
	SpellAddBuff(pyroblast hot_streak_buff=0)
	SpellAddBuff(pyroblast erupting_infernal_core_buff=0)
Define(pyroblast_buff 48108)
	SpellInfo(pyroblast_buff duration=15)
Define(pyroblast_debuff 11366)
	SpellInfo(pyroblast_debuff duration=18 haste=spell tick=3)
Define(pyromaniac_buff 166868)
	SpellInfo(pyromaniac_buff duration=4)
Define(quickening_buff 198924)
	SpellAddBuff(arcane_barrage quickening_buff=0)

	SpellInfo(ray_of_frost cd=60 channel=10 tag=main)

	SpellInfo(rune_of_power buff_totem=rune_of_power_buff duration=180 max_totems=2 totem=1)
	SpellAddBuff(rune_of_power ice_floes_buff=0 if_spell=ice_floes)
	SpellAddBuff(rune_of_power presence_of_mind_buff=0 if_spell=presence_of_mind)
Define(rune_of_power_buff 116014)

	SpellInfo(scorch travel_time=1)
Define(shard_of_the_exodar_warp 207970)
Define(spellsteal 30449)
Define(summon_arcane_familiar 205022)
	SpellInfo(summon_arcane_familiar cd=10)

Define(t18_class_trinket 124516)
Define(temporal_displacement_debuff 80354)
	SpellInfo(temporal_displacement_debuff duration=600)
Define(thermal_void 155149)

	SpellInfo(time_warp cd=300 gcd=0)
	SpellAddBuff(time_warp time_warp_buff=1)
	SpellAddDebuff(time_warp temporal_displacement_debuff=1)
Define(time_warp_buff 80353)
	SpellInfo(time_warp_buff duration=40)
Define(water_elemental 31687)
	SpellInfo(water_elemental cd=60)
	SpellInfo(water_elemental unusable=1 talent=lonely_winter_talent)
Define(water_elemental_freeze 33395)
	SpellInfo(water_elemental_freeze cd=25 gcd=0 shared_cd=water_elemental_fingers_of_frost)
	SpellInfo(water_elemental_freeze unusable=1 talent=lonely_winter_talent)
	SpellAddBuff(water_elemental_freeze fingers_of_frost_buff=1 if_spell=fingers_of_frost)
Define(water_elemental_water_jet 135029)
	SpellInfo(water_elemental_water_jet cd=25 gcd=0 shared_cd=water_elemental_fingers_of_frost)
	SpellInfo(water_elemental_water_jet unusable=1 talent=lonely_winter_talent)
	SpellAddBuff(water_elemental_water_jet brain_freeze_buff=1 itemset=T18 itemcount=2)
	SpellAddTargetDebuff(water_elemental_water_jet water_elemental_water_jet_debuff=1)
Define(water_elemental_water_jet_debuff 135029)
	SpellInfo(water_elemental_water_jet_debuff duration=4)
	SpellInfo(water_elemental_water_jet_debuff add_duration=10 itemset=T18 itemcount=4)
Define(winters_chill_debuff 157997) # TODO ???

# Talents





Define(blazing_soul_talent 4)
Define(bone_chilling_talent 1)
Define(chain_reaction_talent 11)

Define(chrono_shift_talent 13)

Define(conflagration_talent 17)


Define(flame_on_talent 10)


Define(frenetic_speed_talent 13)
Define(frigid_winds_talent 13)
Define(frozen_touch_talent 10)
Define(glacial_insulation_talent 4)



Define(ice_ward_talent 14)
Define(incanters_flow_talent 7)


Define(lonely_winter_talent 2)
Define(mana_shield_talent 4)
Define(meteor_talent 21)





Define(pyromaniac_talent 2)


Define(reverberate_talent 16)
Define(ring_of_frost_talent 15)
Define(rule_of_threes_talent 2)



Define(slipstream_talent 6)


Define(thermal_void_talent 19)
Define(time_anomaly_talent 20)
Define(touch_of_the_magi_talent 17)
	
# Artifacts
Define(mark_of_aluneth 210726)
	SpellInfo(mark_of_aluneth cd=60)
Define(mark_of_aluneth_debuff 210726) # ???
Define(phoenix_reborn 215773)

# Legendary items
Define(lady_vashjs_grasp 132411)
Define(rhonins_assaulting_armwraps_buff 208081)
Define(shard_of_the_exodar 132410)
Define(zannesu_journey_buff 226852)
	SpellAddBuff(blizzard zannesu_journey_buff=-1)

# Non-default tags for OvaleSimulationCraft.
	SpellInfo(arcane_orb tag=shortcd)
	SpellInfo(arcane_power tag=cd)
	SpellInfo(blink tag=shortcd)
	SpellInfo(cone_of_cold tag=shortcd)
	SpellInfo(dragons_breath tag=shortcd)
	SpellInfo(frost_bomb tag=shortcd)
	SpellInfo(ice_floes tag=shortcd)
	SpellInfo(rune_of_power tag=shortcd)

### Pyroblast
AddFunction FirePyroblastHitDamage asValue=1 { 2.423 * Spellpower() * { BuffPresent(pyroblast_buff asValue=1) * 1.25 } }
]]
    OvaleScripts:RegisterScript("MAGE", nil, name, desc, code, "include")
end
