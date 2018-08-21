local __exports = LibStub:NewLibrary("ovale/scripts/ovale_mage_spells", 80000)
if not __exports then return end
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
__exports.register = function()
    local name = "ovale_mage_spells"
    local desc = "[8.0] Ovale: Mage spells"
    local code = [[Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you their power for 274739d.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
Define(arcane_barrage 231564)
# Arcane Barrage hits s1 additional Ltarget:targets; within 44425s3 yds per Arcane Charge for 44425s2 damage.
  SpellInfo(arcane_barrage channel=0 gcd=0 offgcd=1)
  SpellAddBuff(arcane_barrage arcane_barrage=1)
Define(arcane_blast 222321)
# Deal s1 Arcane damage.
  SpellInfo(arcane_blast channel=0 gcd=0 offgcd=1)
Define(arcane_explosion 1449)
# Causes an explosion of magic around the caster, dealing s2 Arcane damage to all enemies within A2 yards.rnrn|cFFFFFFFFGenerates s1 Arcane Charge if any targets are hit.|r
  SpellInfo(arcane_explosion undefined=-1 undefined=-1)
Define(arcane_familiar 205022)
# Summon a Familiar that attacks your enemies and increases your maximum mana by 210126s1 for d.
  SpellInfo(arcane_familiar cd=10 duration=3600 talent=arcane_familiar_talent)
  SpellAddTargetDebuff(arcane_familiar arcane_familiar=1)
Define(arcane_intellect 1459)
# Infuses the target with brilliance, increasing their Intellect by s1 for d.  rnrnIf target is in your party or raid, all party and raid members will be affected.
  SpellInfo(arcane_intellect duration=3600)
  # Intellect increased by w1.
  SpellAddTargetDebuff(arcane_intellect arcane_intellect=1)
Define(arcane_missiles 5143)
# Launches five waves of Arcane Missiles at the enemy over 5143d, causing a total of 5*7268s1 Arcane damage.
  SpellInfo(arcane_missiles duration=2.5 channel=2.5 tick=0.625)
  SpellAddTargetDebuff(arcane_missiles arcane_missiles=1)
  SpellAddBuff(arcane_missiles arcane_missiles=1)
Define(arcane_orb 153640)
# @spelldesc153626
  SpellInfo(arcane_orb channel=0 gcd=0 offgcd=1 undefined=-1)
Define(arcane_power 12042)
# For d, you deal s1 more spell damage and your spells cost s2 less mana.
  SpellInfo(arcane_power cd=90 duration=10)
  # Spell damage increased by w1.rnMana costs of your damaging spells reduced by w2.
  SpellAddBuff(arcane_power arcane_power=1)
Define(battle_potion_of_intellect 279164)
# Chance to create multiple potions.
  SpellInfo(battle_potion_of_intellect gcd=0 offgcd=1)
Define(berserking 26297)
# Increases your haste by s1 for d.
  SpellInfo(berserking cd=180 duration=10 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking=1)
Define(blast_wave 157981)
# Causes an explosion around yourself, dealing s1 Fire damage to all enemies within A1 yards, knocking them back, and reducing movement speed by s2 for d.
  SpellInfo(blast_wave cd=25 duration=4 talent=blast_wave_talent)
  # Movement speed reduced by s2.
  SpellAddTargetDebuff(blast_wave blast_wave=1)
Define(blink 1953)
# Teleports you forward A1 yds or until reaching an obstacle, and frees you from all stuns and bonds.
  SpellInfo(blink cd=0.5 cd=15 duration=0.3 channel=0.3)
  # Blinking.
  SpellAddBuff(blink blink=1)
Define(blizzard 236662)
# Each time Blizzard deals damage, the cooldown of Frozen Orb is reduced by s1/100.1 sec.
  SpellInfo(blizzard channel=0 gcd=0 offgcd=1)
  SpellAddBuff(blizzard blizzard=1)
Define(charged_up 205032)
# Immediately grants s1 Arcane Charges.
  SpellInfo(charged_up cd=40 duration=10 talent=charged_up_talent undefined=-4)
  SpellAddBuff(charged_up charged_up=1)
Define(clearcasting 277726)
# @spelldesc236628
  SpellInfo(clearcasting duration=15 gcd=0 offgcd=1)
  # Arcane Missiles fires 236628s1 additional lmissile:missiles;.
  SpellAddBuff(clearcasting clearcasting=1)
Define(combustion 190319)
# Engulfs you in flames for d, increasing your spells' critical strike chance by s1 and granting you Mastery equal to s3 your Critical Strike stat. Castable while casting other spells.
  SpellInfo(combustion cd=120 duration=10 gcd=0 offgcd=1 tick=0.5)
  # Critical Strike chance of your spells increased by w1.?a231630[rnMastery increased by w2.][]
  SpellAddBuff(combustion combustion=1)
Define(comet_storm 228601)
# @spelldesc153595
  SpellInfo(comet_storm gcd=0 offgcd=1)
Define(cone_of_cold 212792)
# Slowed by s1 for d.
  SpellInfo(cone_of_cold duration=5 gcd=0 offgcd=1)
  # Slowed by s1 for d.
  SpellAddTargetDebuff(cone_of_cold cone_of_cold=1)
Define(counterspell 2139)
# Counters the enemy's spellcast, preventing any spell from that school of magic from being cast for d?s12598[ and silencing the target for 55021d][].
  SpellInfo(counterspell cd=24 duration=6 gcd=0 offgcd=1 interrupt=1)
Define(dragons_breath 31661)
# Enemies in a cone in front of you take s2 Fire damage and are disoriented for d. Damage will cancel the effect.
  SpellInfo(dragons_breath cd=20 duration=4)
  # Disoriented.
  SpellAddTargetDebuff(dragons_breath dragons_breath=1)
Define(ebonbolt 257538)
# @spelldesc214634
  SpellInfo(ebonbolt channel=0 gcd=0 offgcd=1)
Define(evocation 231565)
# Evocation's cooldown is reduced by s1.
  SpellInfo(evocation channel=0 gcd=0 offgcd=1)
  SpellAddBuff(evocation evocation=1)
Define(fire_blast 231568)
# Fire Blast always deals a critical strike.
  SpellInfo(fire_blast channel=0 gcd=0 offgcd=1)
  SpellAddBuff(fire_blast fire_blast=1)
Define(fireball 222305)
# Deal sw1 Fire damage and an additional sw2 Fire damage over d.
  SpellInfo(fireball duration=5 channel=5 gcd=0 offgcd=1 tick=1)
  # Taking sw2 Fire damage every t2 sec.
  SpellAddTargetDebuff(fireball fireball=1)
Define(fireblood 265226)
# Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by s1.
  SpellInfo(fireblood duration=8 max_stacks=6 gcd=0 offgcd=1)
  # Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by w1.
  SpellAddBuff(fireblood fireblood=1)
Define(flamestrike 2120)
# Calls down a pillar of fire, burning all enemies within the area for s1 Fire damage and reducing their movement speed by s2 for d.
  SpellInfo(flamestrike duration=8)
  # Movement speed slowed by s2.
  SpellAddTargetDebuff(flamestrike flamestrike=1)
Define(flurry 44614)
# Unleash a flurry of ice, striking the target s1 times for a total of 228354s2*m1 Frost damage. Each hit reduces the target's movement speed by 228354s1 for 228354d.rnrnWhile Brain Freeze is active, Flurry applies Winter's Chill, causing your target to take damage from your spells as if it were frozen.
  SpellInfo(flurry)
Define(frostbolt 222320)
# Deal s1 Frost damage and reduces the target's movement speed by s2 for d.
  SpellInfo(frostbolt duration=5 channel=5 gcd=0 offgcd=1)
  # Movement speed reduced by s2 for d.
  SpellAddTargetDebuff(frostbolt frostbolt=1)
Define(frozen_orb 84714)
# Launches an orb of swirling ice up to s1 yards forward which deals up to 20*84721s2 Frost damage to all enemies it passes through. Grants 1 charge of Fingers of Frost when it first damages an enemy.rnrnEnemies damaged by the Frozen Orb are slowed by 205708s1 for 205708d.
  SpellInfo(frozen_orb cd=60 duration=15 channel=15)
Define(glacial_spike 228600)
# @spelldesc199786
  SpellInfo(glacial_spike duration=4 channel=4 gcd=0 offgcd=1)
  # Frozen in place.
  SpellAddTargetDebuff(glacial_spike glacial_spike=1)
Define(ice_floes 108839)
# Makes your next Mage spell with a cast time shorter than s2 sec castable while moving. Unaffected by the global cooldown and castable while casting.
  SpellInfo(ice_floes cd=20 duration=15 max_stacks=3 talent=ice_floes_talent gcd=0 offgcd=1)
  # Able to move while casting spells.
  SpellAddBuff(ice_floes ice_floes=1)
Define(ice_lance 228598)
# @spelldesc30455
  SpellInfo(ice_lance channel=0)
Define(ice_nova 157997)
# Causes a whirl of icy wind around the enemy, dealing s1*s3/100 Frost damage to the target and s1 Frost damage to all other enemies within a2 yards, and freezing them in place for d.
  SpellInfo(ice_nova cd=25 duration=2 talent=ice_nova_talent)
  # Frozen.
  SpellAddTargetDebuff(ice_nova ice_nova=1)
Define(icy_veins 12472)
# Accelerates your spellcasting for d, granting m1 haste and preventing damage from delaying your spellcasts.
  SpellInfo(icy_veins cd=180 duration=20)
  # Haste increased by w1 and immune to pushback.
  SpellAddBuff(icy_veins icy_veins=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)
Define(living_bomb 217694)
# @spelldesc44457
  SpellInfo(living_bomb duration=4 gcd=0 offgcd=1 tick=1)
  # Causes w1 Fire damage every t1 sec. After d, the target explodes, causing w2 Fire damage to the target and all other enemies within 44461A2 yards, and spreading Living Bomb.
  SpellAddTargetDebuff(living_bomb living_bomb=1)
Define(meteor 245728)
# Blasts a target for s1 Fire damage.
  SpellInfo(meteor channel=0 gcd=0 offgcd=1)
Define(mirror_image 55342)
# Creates s2 copies of you nearby for 55342d, which cast spells and attack your enemies.
  SpellInfo(mirror_image cd=120 duration=40 talent=mirror_image_talent)
  SpellAddBuff(mirror_image mirror_image=1)
Define(nether_tempest 114954)
# @spelldesc114923
  SpellInfo(nether_tempest channel=0 gcd=0 offgcd=1)
Define(phoenix_flames 257542)
# @spelldesc257541
  SpellInfo(phoenix_flames gcd=0 offgcd=1)
Define(rising_death 269853)
# Empowers you with shadow magic for d, giving your ranged attacks a chance to send out a death bolt that grows in intensity as it travels, dealing up to 271292s1 Shadow damage.
  SpellInfo(rising_death duration=25 channel=25 gcd=0 offgcd=1)
Define(preheat 273333)
# @spelldesc273331
  SpellInfo(preheat duration=30 channel=30 gcd=0 offgcd=1)
  # The Mage's Fire Blast will deal increased damage to you.
  SpellAddTargetDebuff(preheat preheat=1)
Define(presence_of_mind 205025)
# Causes your next n Arcane Blasts to be instant cast.
  SpellInfo(presence_of_mind cd=60 gcd=0 offgcd=1)
  # Arcane Blast is instant cast.
  SpellAddBuff(presence_of_mind presence_of_mind=1)
Define(pyroblast 11366)
# Hurls an immense fiery boulder that causes s1 Fire damage.
  SpellInfo(pyroblast)
Define(pyroclasm 269651)
# @spelldesc269650
  SpellInfo(pyroclasm duration=15 max_stacks=2 gcd=0 offgcd=1)
  # Damage done by your next non-instant Pyroblast increased by s1.
  SpellAddBuff(pyroclasm pyroclasm=1)
Define(quaking_palm 107079)
# Strikes the target with lightning speed, incapacitating them for d, and turns off your attack.
  SpellInfo(quaking_palm cd=120 duration=4 gcd=1)
  # Incapacitated.
  SpellAddTargetDebuff(quaking_palm quaking_palm=1)
Define(ray_of_frost 208141)
# @spelldesc205021
  SpellInfo(ray_of_frost duration=10 max_stacks=6 gcd=0 offgcd=1)
  # Ray of Frost's damage increased by s1.rnRay of Frost's snare increased by s2.
  SpellAddBuff(ray_of_frost ray_of_frost=1)
Define(rule_of_threes 264774)
# @spelldesc264354
  SpellInfo(rule_of_threes duration=15 gcd=0 offgcd=1)
  # The cost of your next Arcane Blast or Arcane Missiles is reduced by s1.
  SpellAddBuff(rule_of_threes rule_of_threes=1)
Define(rune_of_power 116011)
# Places a Rune of Power on the ground for 116011d which increases your spell damage by 116014s1 while you stand within 8 yds.
  SpellInfo(rune_of_power cd=10 cd=40 duration=10 talent=rune_of_power_talent)
Define(scorch 2948)
# Scorches an enemy for s1 Fire damage. Castable while moving.
  SpellInfo(scorch)
Define(shimmer 212653)
# Teleports you A1 yards forward, unless something is in the way. Unaffected by the global cooldown and castable while casting.
  SpellInfo(shimmer cd=0.5 cd=20 duration=0.65 channel=0.65 talent=shimmer_talent gcd=0 offgcd=1)
  # Shimmering.
  SpellAddBuff(shimmer shimmer=1)
Define(summon_water_elemental 31687)
# Summons a Water Elemental to follow and fight for you.
  SpellInfo(summon_water_elemental cd=30)
Define(supernova 157980)
# Pulses arcane energy around the target enemy or ally, dealing s2 Arcane damage to all enemies within A2 yards, and knocking them upward. A primary enemy target will take s1 increased damage.
  SpellInfo(supernova cd=25 talent=supernova_talent)
Define(time_warp 80353)
# Warp the flow of time, increasing haste by s1 for all party and raid members for d.rnrnAllies will be unable to benefit from Bloodlust, Heroism, or Time Warp again for 57724d.
  SpellInfo(time_warp cd=300 duration=40 channel=40 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(time_warp time_warp=1)
Define(winters_reach 273347)
# @spelldesc273346
  SpellInfo(winters_reach duration=15 channel=15 gcd=0 offgcd=1)
  # Damage of your next non-instant Flurry increased by w1 per hit.
  SpellAddBuff(winters_reach winters_reach=1)
Define(arcane_orb_talent 21)
# Launches an Arcane Orb forward from your position, traveling up to 40 yards, dealing 153640s1 Arcane damage to enemies it passes through.rnrn|cFFFFFFFFGrants 1 Arcane Charge when cast and every time it deals damage.|r
Define(charged_up_talent 11)
# Immediately grants s1 Arcane Charges.
Define(overpowered_talent 19)
# Arcane Power now increases damage by 30+s1 and reduces mana costs by 30-s2.
Define(resonance_talent 10)
# Arcane Barrage deals s1 increased damage per target it hits.
Define(alexstraszas_fury_talent 11)
# Dragon's Breath always critically strikes and contributes to Hot Streak.
Define(firestarter_talent 1)
# Your Fireball and Pyroblast spells always deal a critical strike when the target is above s1 health.
Define(flame_patch_talent 16)
# Flamestrike leaves behind a patch of flames which burns enemies within it for 8*205472s1 Fire damage over 205470d. 
Define(kindling_talent 19)
# Your Fireball, Pyroblast, Fire Blast, and Phoenix Flames critical strikes reduce the remaining cooldown on Combustion by s1 sec.
Define(mirror_image_talent 8)
# Creates s2 copies of you nearby for 55342d, which cast spells and attack your enemies.
Define(rune_of_power_talent 9)
# Places a Rune of Power on the ground for 116011d which increases your spell damage by 116014s1 while you stand within 8 yds.
Define(searing_touch_talent 3)
# Scorch deals s2 increased damage and is a guaranteed Critical Strike when the target is below s1 health.
Define(comet_storm_talent 18)
# Calls down a series of 7 icy comets on and around the target, that deals up to 7*153596s1 Frost damage to all enemies within 228601A1 yds of its impacts.
Define(ebonbolt_talent 12)
# Launch a bolt of ice at the enemy, dealing 257538s1 Frost damage and granting you Brain Freeze.
Define(freezing_rain_talent 16)
# Frozen Orb makes Blizzard instant cast and increases its damage done by 270232s2 for 270232d.
Define(glacial_spike_talent 21)
# Conjures a massive spike of ice, and merges your current Icicles into it. It impales your target, dealing 228600s1 damage plus all of the damage stored in your Icicles, and freezes the target in place for 228600d. Damage may interrupt the freeze effect.rnrnRequires 5 Icicles to cast.rnrn|cFFFFFFFFPassive:|r Ice Lance no longer launches Icicles.
Define(ray_of_frost_talent 20)
# Channel an icy beam at the enemy for d, dealing s2 Frost damage every t2 sec and slowing movement by s4. Each time Ray of Frost deals damage, its damage and snare increases by 208141s1.rnrnGenerates s3 charges of Fingers of Frost over its duration.
Define(splitting_ice_talent 17)
# Your Ice Lance and Icicles now deal s3 increased damage, and hit a second nearby target for s2 of their damage.rnrnYour Ebonbolt and Glacial Spike also hit a second nearby target for s2 of its damage.
Define(arcane_familiar_talent 3)
# Summon a Familiar that attacks your enemies and increases your maximum mana by 210126s1 for d.
Define(blast_wave_talent 6)
# Causes an explosion around yourself, dealing s1 Fire damage to all enemies within A1 yards, knocking them back, and reducing movement speed by s2 for d.
Define(ice_floes_talent 6)
# Makes your next Mage spell with a cast time shorter than s2 sec castable while moving. Unaffected by the global cooldown and castable while casting.
Define(ice_nova_talent 3)
# Causes a whirl of icy wind around the enemy, dealing s1*s3/100 Frost damage to the target and s1 Frost damage to all other enemies within a2 yards, and freezing them in place for d.
Define(shimmer_talent 5)
# Teleports you A1 yards forward, unless something is in the way. Unaffected by the global cooldown and castable while casting.
Define(supernova_talent 12)
# Pulses arcane energy around the target enemy or ally, dealing s2 Arcane damage to all enemies within A2 yards, and knocking them upward. A primary enemy target will take s1 increased damage.
Define(arcane_pressure_trait 274594)
Define(preheat_trait 273331)
Define(winters_reach_trait 273346)
    ]]
    code = code .. [[
# Mage spells and functions.
SpellRequire(arcane_intellect unusable 1=buff,arcane_intellect)


Define(arcane_affinity 166871)
	SpellInfo(arcane_affinity duration=15)
Define(arcane_barrage 44425)
	SpellInfo(arcane_barrage cd=3 travel_time=1 arcanecharges=finisher)
Define(arcane_blast 30451)
	SpellAddBuff(arcane_blast presence_of_mind_buff=0 if_spell=presence_of_mind arcanecharges=-1)
	SpellAddBuff(arcane_blast profound_magic_buff=0 itemset=T16_caster itemcount=2 specialization=arcane)
	SpellAddBuff(arcane_blast ice_floes_buff=0 if_spell=ice_floes)
Define(arcane_brilliance 1459)
	SpellAddBuff(arcane_brilliance arcane_brilliance_buff=1)
Define(arcane_brilliance_buff 1459)
	SpellInfo(arcane_brilliance_buff duration=3600)
Define(arcane_charge 114664)
Define(arcane_charge_debuff 36032)
	SpellInfo(arcane_charge_debuff duration=15 max_stacks=4)

	SpellInfo(arcane_explosion arcanecharges=-1)
Define(arcane_instability_buff 166872)
	SpellInfo(arcane_instability_buff duration=15)

	SpellInfo(arcane_missiles duration=2 travel_time=1 arcanecharges=-1)
	SpellRequire(arcane_missiles unusable 1=buff,!arcane_missiles_buff)
	SpellAddBuff(arcane_missiles arcane_instability_buff=0 itemset=T17 itemcount=4 specialization=arcane)
	SpellAddBuff(arcane_missiles arcane_missiles_buff=-1)
	SpellAddBuff(arcane_missiles arcane_power_buff=extend,2 if_spell=overpowered)
Define(arcane_missiles_buff 79683)
	SpellInfo(arcane_missiles_buff duration=20 max_stacks=3)
Define(arcane_orb 153626)
	SpellInfo(arcane_orb cd=15)

	SpellInfo(arcane_power cd=90 gcd=0)
	SpellAddBuff(arcane_power arcane_power_buff=1)
Define(arcane_power_buff 12042)
	SpellInfo(arcane_power_buff duration=15)

Define(blazing_speed 108843)
	SpellInfo(blazing_speed cd=25 gcd=0 offgcd=1)

	SpellInfo(blink cd=15)
Define(blizzard 190356)
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
Define(comet_storm 153595)
	SpellInfo(comet_storm cd=30 travel_time=1)
Define(cone_of_cold 120)
	SpellInfo(cone_of_cold cd=12)

	SpellInfo(counterspell cd=24 gcd=0 interrupt=1)
Define(deep_freeze 44572)
	SpellInfo(deep_freeze cd=30 interrupt=1)
	SpellAddBuff(deep_freeze fingers_of_frost_buff=-1 if_spell=fingers_of_frost)

	SpellInfo(dragons_breath cd=20)
Define(ebonbolt 214634)
	SpellInfo(ebonbolt cd=45 tag=main)
	SpellAddBuff(ebonbolt brain_freeze_buff=1)
Define(erupting_infernal_core_buff 248147)
	SpellInfo(erupting_infernal_core_buff duration=30)
Define(evocation 12051)
	SpellInfo(evocation cd=120 channel=3 haste=spell)
	SpellInfo(evocation add_cd=-30 if_spell=improved_evocation)
	SpellAddBuff(evocation ice_floes_buff=0 if_spell=ice_floes)
Define(fingers_of_frost 112965)
Define(fingers_of_frost_buff 44544)
	SpellInfo(fingers_of_frost_buff duration=15 max_stacks=2)
	SpellInfo(fingers_of_frost_buff max_stacks=4 itemset=T18 itemcount=4)
Define(fire_blast 108853)
	SpellInfo(fire_blast gcd=0 offgcd=1 cd=12 charges=1)
	SpellInfo(fire_blast cd=10 charges=2 talent=flame_on_talent)
Define(fireball 133)
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
Define(frostbolt 116)
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
Define(glacial_spike 199786)
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
Define(ice_lance 30455)
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
Define(incanters_flow 1463)
Define(incanters_flow_buff 116267)
	SpellInfo(incanters_flow_buff duration=25 max_stacks=5)
Define(inferno_blast 108853)
	SpellInfo(inferno_blast cd=8)
	SpellInfo(inferno_blast add_cd=-2 itemset=T17 itemcount=2)
Define(kaelthas_ultimate_ability_buff 209455)
Define(living_bomb 44457)
	SpellInfo(living_bomb gcd=1)
	SpellAddTargetDebuff(living_bomb living_bomb_debuff=1)
Define(living_bomb_debuff 44457)
	SpellInfo(living_bomb duration=12 haste=spell tick=3)
Define(mark_of_doom_debuff 184073)
	SpellInfo(mark_of_doom_debuff duration=10)
Define(meteor 153561)
	SpellInfo(meteor cd=45 travel_time=1)

	SpellInfo(mirror_image cd=120)
Define(nether_tempest 114923)
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
Define(ray_of_frost 205021)
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

Define(living_bomb_talent 18)
Define(lonely_winter_talent 2)
Define(mana_shield_talent 4)
Define(meteor_talent 21)

Define(nether_tempest_talent 18)

Define(phoenix_flames_talent 12)
Define(pyroclasm_talent 20)
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
