import { OvaleScriptsClass } from "../engine/scripts";

export function registerShamanSpells(scripts: OvaleScriptsClass) {
    const name = "ovale_shaman_spells";
    const desc = "[9.1] Ovale: Shaman spells";
    // THIS PART OF THIS FILE IS AUTOMATICALLY GENERATED
    let code = `Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
Define(ascendance 114050)
# Transform into a Flame Ascendant for 15 seconds, replacing Chain Lightning with Lava Beam, removing the cooldown on Lava Burst, and increasing the damage of Lava Burst by an amount equal to your critical strike chance.rnrnWhen you transform into the Flame Ascendant, instantly cast a Lava Burst at all enemies affected by your Flame Shock, and refresh your Flame Shock durations to 18 seconds.
  SpellInfo(ascendance cd=180 duration=15)
  SpellRequire(ascendance unusable set=1 enabled=(not hastalent(ascendance_talent)))
  # Transformed into a powerful Fire ascendant. Chain Lightning is transformed into Lava Beam.
  SpellAddBuff(ascendance ascendance add=1)
Define(ascendance_enhancement 114051)
# Transform into an Air Ascendant for 15 seconds, immediately dealing 344548s1 Nature damage to any enemy within 344548A1 yds, reducing the cooldown and cost of Stormstrike by s4, and transforming your auto attack and Stormstrike into Wind attacks which bypass armor and have a s1 yd range.
  SpellInfo(ascendance_enhancement cd=180 duration=15)
  SpellRequire(ascendance_enhancement unusable set=1 enabled=(not hastalent(ascendance_talent_enhancement)))
  # Transformed into a powerful Air ascendant. Auto attacks have a 114089r yard range. Stormstrike is empowered and has a 114089r yard range.
  SpellAddBuff(ascendance_enhancement ascendance_enhancement add=1)
Define(bag_of_tricks 312411)
# Pull your chosen trick from the bag and use it on target enemy or ally. Enemies take <damage> damage, while allies are healed for <healing>. 
  SpellInfo(bag_of_tricks cd=90)
Define(berserking 26297)
# Increases your haste by s1 for 12 seconds.
  SpellInfo(berserking cd=180 duration=12 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking add=1)
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
Define(capacitor_totem 192058)
# Summons a totem at the target location that gathers electrical energy from the surrounding air and explodes after s2 sec, stunning all enemies within 118905A1 yards for 3 seconds.
  SpellInfo(capacitor_totem cd=60 duration=3 gcd=1)
Define(chain_harvest 320674)
# Send a wave of anima at the target, which then jumps to additional nearby targets. Deals (204.99999999999997 of Spell Power) Shadow damage to up to 5 enemies, and restores (315 of Spell Power) health to up to 5 allies.rnrnFor each target critically struck, the cooldown of Chain Harvest is reduced by 5 sec.
  SpellInfo(chain_harvest cd=90)
Define(chain_lightning 188443)
# Hurls a lightning bolt at the enemy, dealing (63.5 of Spell Power) Nature damage and then jumping to additional nearby enemies. Affects x1 total targets.?s187874[rnrnIf Chain Lightning hits more than 1 target, each target hit by your Chain Lightning increases the damage of your next Crash Lightning by 333964s1.][]?a343725[rnrn|cFFFFFFFFGenerates 343725s5 Maelstrom per target hit.|r][]
  SpellInfo(chain_lightning)
Define(crash_lightning 187874)
# Electrocutes all enemies in front of you, dealing s1*<CAP>/AP Nature damage. Hitting 2 or more targets enhances your weapons for 10 seconds, causing Stormstrike and Lava Lash to also deal 195592s1*<CAP>/AP Nature damage to all targets in front of you.  rnrnEach target hit by Crash Lightning increases the damage of your next Stormstrike by s2.
  SpellInfo(crash_lightning cd=9)
  # Stormstrike and Lava Lash deal an additional 195592s1 damage to all targets in front of you.
  SpellAddBuff(crash_lightning crash_lightning add=1)
Define(doom_winds 204945)
# Unleashes the inner power of the |cFFFFCC99Doomhammer|r, causing all auto attacks to trigger Windfury, and increasing damage dealt by Windfury by s2 for 6 seconds.
  SpellInfo(doom_winds cd=60 duration=6 gcd=0 offgcd=1)
  # Chance to proc Windfury weapon on auto attacks increased by 100.rnWindfury damage increased by s2.
  SpellAddBuff(doom_winds doom_winds add=1)
Define(doom_winds_buff 335903)
# Dropping Windfury Totem grants you 335903s1 chance to gain Windfury Weapon and increases Windfury Weapon damage by 335903s3 for 12 seconds. rnrnThis can only occur once every 60 seconds.
  SpellInfo(doom_winds_buff duration=12 gcd=0 offgcd=1)
Define(earth_elemental 198103)
# Calls forth a Greater Earth Elemental to protect you and your allies for 60 seconds.
  SpellInfo(earth_elemental cd=300)
Define(earth_shock 8042)
# Instantly shocks the target with concussive force, causing (273 of Spell Power) Nature damage.?a190493[rnrnEarth Shock will consume all stacks of Fulmination to deal extra Nature damage to your target.][]
  SpellInfo(earth_shock maelstrom=60)
Define(earthen_spike 188089)
# Summons an Earthen Spike under an enemy, dealing s1 Physical damage and increasing Physical and Nature damage you deal to the target by s2 for 10 seconds.
  SpellInfo(earthen_spike cd=20 duration=10)
  SpellRequire(earthen_spike unusable set=1 enabled=(not hastalent(earthen_spike_talent)))
  # Suffering s2 increased Nature and Physical damage from the Shaman.
  SpellAddTargetDebuff(earthen_spike earthen_spike add=1)
Define(earthquake 61882)
# Causes the earth within a1 yards of the target location to tremble and break, dealing <damage> Physical damage over 6 seconds and sometimes knocking down enemies.
  SpellInfo(earthquake maelstrom=60 duration=6 tick=1)
Define(echoes_of_great_sundering_buff 336217)
# When you cast Earth Shock, your next Earthquake will deal 336217s2 additional damage.
  SpellInfo(echoes_of_great_sundering_buff duration=25 gcd=0 offgcd=1)
Define(echoing_shock 320125)
# Shock the target for (65 of Spell Power) Elemental damage and create an ancestral echo, causing your next damage or healing spell to be cast a second time s2/1000.1 sec later for free.
  SpellInfo(echoing_shock cd=30 duration=8)
  SpellRequire(echoing_shock unusable set=1 enabled=(not hastalent(echoing_shock_talent)))
  # Your next damage or healing spell will be cast a second time s2/1000.1 sec later for free.
  SpellAddBuff(echoing_shock echoing_shock add=1)
Define(elemental_blast 117014)
# Harnesses the raw power of the elements, dealing (140 of Spell Power) Elemental damage and increasing your Critical Strike or Haste by 118522s1 or Mastery by 173184s1*168534bc1 for 10 seconds.?a343725[rnrn|cFFFFFFFFGenerates 343725s10 Maelstrom.|r][]
  SpellInfo(elemental_blast cd=12)
  SpellRequire(elemental_blast unusable set=1 enabled=(not {hastalent(elemental_blast_talent) or hastalent(elemental_blast_talent_elemental)}))
Define(elemental_equilibrium_buff 347348)
# Dealing direct Fire, Frost, and Nature damage within 10 seconds will increase all damage dealt by 347348s1 for 10 seconds. This can only occur once every 30 seconds.
  SpellInfo(elemental_equilibrium_buff duration=10 gcd=0 offgcd=1)
  # Damage dealt increased by s1.
  SpellAddBuff(elemental_equilibrium_buff elemental_equilibrium_buff add=1)
Define(fae_transfusion 328923)
# Transfer the life force of up to 328928I enemies in the targeted area, dealing (117.5 of Spell Power)*3 seconds/t2 Nature damage evenly split to each enemy target over 3 seconds. ?a137041[rnrnFully channeling Fae Transfusion generates s4 Lstack:stacks; of Maelstrom Weapon.][]rnrnPressing Fae Transfusion again within 20 seconds will release s1 of all damage from Fae Transfusion, healing up to 328930s2 allies within 328930A1 yds.
  SpellInfo(fae_transfusion cd=120 duration=3 channel=3 tick=0.5)
  # Fae Transfusion will heal up to 328930s2 nearby allies for w1.
  SpellAddBuff(fae_transfusion fae_transfusion_buff add=1)
Define(fae_transfusion_buff 328933)
# Transfer the life force of up to 328928I enemies in the targeted area, dealing (117.5 of Spell Power)*3 seconds/t2 Nature damage evenly split to each enemy target over 3 seconds. ?a137041[rnrnFully channeling Fae Transfusion generates s4 Lstack:stacks; of Maelstrom Weapon.][]rnrnPressing Fae Transfusion again within 20 seconds will release s1 of all damage from Fae Transfusion, healing up to 328930s2 allies within 328930A1 yds.
  SpellInfo(fae_transfusion_buff duration=20 gcd=0 offgcd=1 tick=0.5)
Define(feral_lunge 196884)
# Lunge at your enemy as a ghostly wolf, biting them to deal 215802s1 Physical damage.
  SpellInfo(feral_lunge cd=30 gcd=0.5)
  SpellRequire(feral_lunge unusable set=1 enabled=(not hastalent(feral_lunge_talent)))
Define(feral_spirit 51533)
# Summons two Spirit ?s147783[Raptors][Wolves] that aid you in battle for 15 seconds. They are immune to movement-impairing effects.rnrnFeral Spirit generates one stack of Maelstrom Weapon immediately, and one stack every 333957t1 sec for 15 seconds.
  SpellInfo(feral_spirit cd=120)
Define(fire_elemental 198067)
# Calls forth a Greater Fire Elemental to rain destruction on your enemies for 30 seconds. rnrnWhile the Fire Elemental is active, Flame Shock deals damage 188592s2 faster?a343226[, and newly applied Flame Shocks last 343226s1 longer][].
  SpellInfo(fire_elemental cd=150)
  SpellRequire(fire_elemental replaced_by set=storm_elemental enabled=(hastalent(storm_elemental_talent)))
Define(fire_nova 333974)
# Erupt a burst of fiery damage from all targets affected by your Flame Shock, dealing 333977s1 Fire damage to up to 333977I targets within 333977A1 yds of your Flame Shock targets.
  SpellInfo(fire_nova cd=15)
  SpellRequire(fire_nova unusable set=1 enabled=(not hastalent(fire_nova_talent)))
Define(fireblood 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. ?s195710[This effect shares a 30 sec cooldown with other similar effects.][]
  SpellInfo(fireblood cd=120 gcd=0 offgcd=1)
Define(flame_shock 188389)
# Sears the target with fire, causing (19.5 of Spell Power) Fire damage and then an additional o2 Fire damage over 18 seconds.
  SpellInfo(flame_shock cd=6 duration=18 tick=2)
  # Suffering w2 Fire damage every t2 sec.
  SpellAddTargetDebuff(flame_shock flame_shock add=1)
Define(flametongue_weapon 318038)
# Imbue your ?s33757[off-hand ][]weapon with the element of Fire for 3600 seconds, causing each of your attacks to deal max((<coeff>*AP),1) additional Fire damage.
  SpellInfo(flametongue_weapon)
  # Each of your weapon attacks causes up to max((<coeff>*AP),1) additional Fire damage.
  SpellAddBuff(flametongue_weapon flametongue_weapon add=1)
Define(fleshcraft 324631)
# Form a shield of flesh and bone over 3 seconds that absorbs damage equal to s1 of your maximum health for 120 seconds.rnrnWhile channeling, your damage taken is reduced by s2.rnrn|cFFFFFFFFPassive:|r Moving near an enemy's corpse consumes their essence to reduce Fleshcraft's cooldown by <cdr> sec.
  SpellInfo(fleshcraft cd=120 duration=3 channel=3 tick=0.5)
  # Damage taken reduced by w2.
  SpellAddBuff(fleshcraft fleshcraft add=1)
  # Immune to crowd control effects.rnHealing s17 health every t17 sec.
  SpellAddBuff(fleshcraft ultimate_form_buff add=1)
Define(frost_shock 196840)
# Chills the target with frost, causing (45 of Spell Power) Frost damage and reducing the target's movement speed by s2 for 6 seconds.?s33757[rnrnFrost Shock shares a cooldown with Flame Shock.][]
  SpellInfo(frost_shock duration=6)
  # Movement speed reduced by s2.
  SpellAddTargetDebuff(frost_shock frost_shock add=1)
Define(hailstorm_buff 334196)
# Each stack of Maelstrom Weapon consumed increases the damage of your next Frost Shock by 334196s1, and causes your next Frost Shock to hit 334196m2 additional target per Maelstrom Weapon stack consumed.
  SpellInfo(hailstorm_buff duration=20 max_stacks=5 gcd=0 offgcd=1)
  # Your next Frost Shock will deal s1 additional damage, and hit m2 additional Ltarget:targets;.
  SpellAddBuff(hailstorm_buff hailstorm_buff add=1)
Define(heroism 32182)
# Increases haste by (25 of Spell Power) for all party and raid members for 40 seconds.rnrnAllies receiving this effect will become Exhausted and unable to benefit from Heroism or Time Warp again for 600 seconds.
  SpellInfo(heroism cd=300 duration=40 gcd=0 offgcd=1)
  # Haste increased by w1.
  SpellAddBuff(heroism heroism add=1)
Define(hot_hand_buff 215785)
# Melee auto-attacks with Flametongue Weapon active have a h chance to reduce the cooldown of Lava Lash by 215785m2/4 and increase the damage of Lava Lash by 215785m1 for 8 seconds.
  SpellInfo(hot_hand_buff duration=8 gcd=0 offgcd=1)
Define(ice_strike 342240)
# Strike your target with an icy blade, dealing s1 Frost damage and snaring them by s2 for 6 seconds.rnrnSuccessful Ice Strikes reset the cooldown of your Flame Shock and Frost Shock spells.
  SpellInfo(ice_strike cd=15 duration=6)
  SpellRequire(ice_strike unusable set=1 enabled=(not hastalent(ice_strike_talent)))
  # Movement speed reduced by s2.
  SpellAddTargetDebuff(ice_strike ice_strike add=1)
Define(icefury 210714)
# Hurls frigid ice at the target, dealing (82.5 of Spell Power) Frost damage and causing your next n Frost Shocks to deal s2 increased damage and generate 343725s7 Maelstrom.rnrn|cFFFFFFFFGenerates 343725s8 Maelstrom.|r
  SpellInfo(icefury cd=30 duration=15 maelstrom=0)
  SpellRequire(icefury unusable set=1 enabled=(not hastalent(icefury_talent)))
  # Frost Shock damage increased by s2.
  SpellAddBuff(icefury icefury add=1)
Define(lava_beam 114074)
# Unleashes a blast of superheated flame at the enemy, dealing (63.5 of Spell Power) Fire damage and then jumping to additional nearby enemies. Damage is increased by s2 after each jump. Affects x1 total targets.  rnrn|cFFFFFFFFGenerates 343725s6 Maelstrom per target hit.|r 
  SpellInfo(lava_beam)
Define(lava_burst 51505)
# Hurls molten lava at the target, dealing (97.2 of Spell Power) Fire damage.?a231721[ Lava Burst will always critically strike if the target is affected by Flame Shock.][]?a343725[rnrn|cFFFFFFFFGenerates 343725s3 Maelstrom.|r][]
  SpellInfo(lava_burst cd=8 maelstrom=0)
Define(lava_lash 60103)
# Charges your off-hand weapon with lava and burns your target, dealing s1 Fire damage.rnrnDamage is increased by s2 if your offhand weapon is imbued with Flametongue Weapon.
  SpellInfo(lava_lash cd=18)
Define(lava_surge_buff 77762)
# The Shaman's next Lava Burst casts instantly.
  SpellInfo(lava_surge_buff duration=10 gcd=0 offgcd=1)
Define(lightning_bolt 188196)
# Hurls a bolt of lightning at the target, dealing (95 of Spell Power) Nature damage.?a343725[rnrn|cFFFFFFFFGenerates 343725s1 Maelstrom.|r][]
  SpellInfo(lightning_bolt)
Define(lightning_shield 192106)
# Surround yourself with a shield of lightning for 1800 seconds.rnrnMelee attackers have a h chance to suffer (15 of Spell Power) Nature damage?a137041[ and have a s3 chance to generate a stack of Maelstrom Weapon]?a137040[ and have a s4 chance to generate s5 Maelstrom][].rnrnOnly one Elemental Shield can be active on the Shaman at a time.
  SpellInfo(lightning_shield duration=1800)
  # Chance to deal 192109s1 Nature damage when you take melee damage.
  SpellAddBuff(lightning_shield lightning_shield add=1)
Define(liquid_magma_totem 192222)
# Summons a totem at the target location for 15 seconds that hurls liquid magma at a random nearby target every 192226t1 sec, dealing (15 of Spell Power)*(1+(137040s3/100)) Fire damage to all enemies within 192223A1 yards.
  SpellInfo(liquid_magma_totem cd=60 duration=15 gcd=1)
  SpellRequire(liquid_magma_totem unusable set=1 enabled=(not hastalent(liquid_magma_totem_talent)))
Define(maelstrom_weapon_buff 344179)
# When you deal damage with a melee weapon, you have a chance to gain Maelstrom Weapon, stacking up to 344179u times. Each stack of Maelstrom Weapon reduces the cast time of your next damage or healing spell by 187881s1 and increase the damage or healing of your next spell by 187881s3. A maximum of s2 stacks of Maelstrom Weapon can be consumed at a time.
  SpellInfo(maelstrom_weapon_buff duration=30 max_stacks=10 gcd=0 offgcd=1)
  # Your next damage or healing spell has its cast time reduced by max(187881s1, -100)*-1 and damage or healing increased by min(187881s2, 5*s~2).
  SpellAddBuff(maelstrom_weapon_buff maelstrom_weapon_buff add=1)
Define(master_of_the_elements_buff 260734)
# Casting Lava Burst increases the damage of your next Nature, Physical, or Frost spell by 260734s1.
  SpellInfo(master_of_the_elements_buff duration=15 gcd=0 offgcd=1)
Define(primal_lava_actuators_buff 335896)
# Each time Flame Shock deals Periodic damage, increase the damage of your next Lava Lash by 335896s1 and reduce the cooldown of Lava Lash by m1/10.1 sec.
  SpellInfo(primal_lava_actuators_buff duration=15 max_stacks=8 gcd=0 offgcd=1)
Define(primordial_wave 326059)
# Blast your target with a Primordial Wave, dealing (65 of Spell Power) Shadow damage and apply Flame Shock to an enemy, or ?a137039[heal an ally for (65 of Spell Power) and apply Riptide to them][heal an ally for (65 of Spell Power)].rnrnYour next ?a137040[Lava Burst]?a137041[Lightning Bolt][Healing Wave] will also hit all targets affected by your ?a137040|a137041[Flame Shock][Riptide] for ?a137039[s2]?a137040[s3][s4] of normal ?a137039[healing][damage].
  SpellInfo(primordial_wave cd=45)
Define(primordial_wave_buff 327164)
# Blast your target with a Primordial Wave, dealing (65 of Spell Power) Shadow damage and apply Flame Shock to an enemy, or ?a137039[heal an ally for (65 of Spell Power) and apply Riptide to them][heal an ally for (65 of Spell Power)].rnrnYour next ?a137040[Lava Burst]?a137041[Lightning Bolt][Healing Wave] will also hit all targets affected by your ?a137040|a137041[Flame Shock][Riptide] for ?a137039[s2]?a137040[s3][s4] of normal ?a137039[healing][damage].
  SpellInfo(primordial_wave_buff duration=15 gcd=0 offgcd=1)
  # Your next ?a137040[Lava Burst]?a137041[Lightning Bolt][Healing Wave] will also hit all targets affected by your ?a137040|a137041[Flame Shock][Riptide].
  SpellAddBuff(primordial_wave_buff primordial_wave_buff add=1)
Define(quaking_palm 107079)
# Strikes the target with lightning speed, incapacitating them for 4 seconds, and turns off your attack.
  SpellInfo(quaking_palm cd=120 duration=4 gcd=1)
  # Incapacitated.
  SpellAddTargetDebuff(quaking_palm quaking_palm add=1)
Define(spiritwalkers_grace 79206)
# Calls upon the guidance of the spirits for 15 seconds, permitting movement while casting Shaman spells. Castable while casting.?a192088[ Increases movement speed by 192088s2.][]
  SpellInfo(spiritwalkers_grace cd=120 duration=15 gcd=0 offgcd=1)
  # Able to move while casting all Shaman spells.
  SpellAddBuff(spiritwalkers_grace spiritwalkers_grace add=1)
Define(static_discharge 342243)
# Discharge excess energy from your Lightning Shield, dealing (23 of Spell Power) Nature damage to an enemy within 342244A1 yds every t1 sec for 3 seconds.rnrnTargets with your Flame Shock on them are preferred.
  SpellInfo(static_discharge cd=30 duration=3 tick=0.5)
  SpellRequire(static_discharge unusable set=1 enabled=(not hastalent(static_discharge_talent)))
  # Discharging excess Lightning Shield energy at your enemies.
  SpellAddBuff(static_discharge static_discharge add=1)
Define(storm_elemental 192249)
# Calls forth a Greater Storm Elemental to hurl gusts of wind that damage the Shaman's enemies for 30 seconds.rnrnWhile the Storm Elemental is active, each time you cast Lightning Bolt or Chain Lightning, the cast time of Lightning Bolt and Chain Lightning is reduced by 263806s1, stacking up to 263806u times.
  SpellInfo(storm_elemental cd=150)
  SpellRequire(storm_elemental unusable set=1 enabled=(not hastalent(storm_elemental_talent)))
Define(stormkeeper 191634)
# Charge yourself with lightning, causing your next n Lightning Bolts to deal s2 more damage, and also causes your next n Lightning Bolts or Chain Lightnings to be instant cast and trigger an Elemental Overload on every target.
  SpellInfo(stormkeeper cd=60 duration=15)
  SpellRequire(stormkeeper unusable set=1 enabled=(not hastalent(stormkeeper_talent)))
  # Your next Lightning Bolt will deal s2 increased damage, and your next Lightning Bolt or Chain Lightning will be instant cast and cause an Elemental Overload to trigger on every target hit.
  SpellAddBuff(stormkeeper stormkeeper add=1)
Define(stormkeeper_enhancement 320137)
# Charge yourself with lightning, causing your next n Chain Lightnings to deal s2 more damage and be instant cast.
  SpellInfo(stormkeeper_enhancement cd=60 duration=15)
  SpellRequire(stormkeeper_enhancement unusable set=1 enabled=(not hastalent(stormkeeper_talent_enhancement)))
  # Your next Chain Lightning will deal s2 increased damage and be instant cast.
  SpellAddBuff(stormkeeper_enhancement stormkeeper_enhancement add=1)
Define(stormstrike 17364)
# Energizes both your weapons with lightning and delivers a massive blow to your target, dealing a total of 32175sw1+32176sw1 Physical damage.
  SpellInfo(stormstrike cd=7.5)
Define(sundering 197214)
# Shatters a line of earth in front of you with your main hand weapon, causing s1 Flamestrike damage and Incapacitating any enemy hit for 2 seconds.
  SpellInfo(sundering cd=40 duration=2)
  SpellRequire(sundering unusable set=1 enabled=(not hastalent(sundering_talent)))
  # Incapacitated.
  SpellAddTargetDebuff(sundering sundering add=1)
Define(ultimate_form_buff 323524)
# While channeling Fleshcraft, you are immune to crowd control and you regenerate 323524s17 health every 323524t17 sec. rnrnIf you finish the full channel, you gain 3 seconds of crowd control immunity, during which you regenerate 323524s17 health every 323524t17 sec.
  SpellInfo(ultimate_form_buff duration=3 gcd=0 offgcd=1 tick=1)
Define(vesper_totem 324386)
# Summon a totem at the target location for 30 seconds. Your next s2 damage spells or abilities will cause the totem to radiate (80 of Spell Power) Arcane damage to up to 324520I enemies near the totem, and your next s4 healing spells will heal up to s6 allies near the totem for (91 of Spell Power) health.rnrnCasting this ability again while the totem is active will relocate the totem.
  SpellInfo(vesper_totem cd=60 duration=30 gcd=1)
Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp add=1)
Define(wind_gust_buff 263806)
# Calls forth a Greater Storm Elemental to hurl gusts of wind that damage the Shaman's enemies for 30 seconds.rnrnWhile the Storm Elemental is active, each time you cast Lightning Bolt or Chain Lightning, the cast time of Lightning Bolt and Chain Lightning is reduced by 263806s1, stacking up to 263806u times.
  SpellInfo(wind_gust_buff duration=30 max_stacks=20 gcd=0 offgcd=1)
Define(wind_shear 57994)
# Disrupts the target's concentration with a burst of wind, interrupting spellcasting and preventing any spell in that school from being cast for 3 seconds.
  SpellInfo(wind_shear cd=12 duration=3 gcd=0 offgcd=1 interrupt=1)
Define(windfury_totem 8512)
# Summons a Windfury Totem with s1 health at the feet of the caster for 120 seconds.  Party members within s2 yds have a ?a343211[327942h][327942h-343211m1] chance when they auto-attack to swing an extra time.
  SpellInfo(windfury_totem duration=120 gcd=1)
Define(windfury_weapon 33757)
# Imbue your main-hand weapon with the element of Wind for 3600 seconds. Each main-hand attack has a 319773h chance to trigger two extra attacks, dealing 25504sw1 Physical damage each.
  SpellInfo(windfury_weapon)
Define(windstrike 115356)
# Hurl a staggering blast of wind at an enemy, dealing a total of 115357sw1+115360sw1 Physical damage, bypassing armor.
  SpellInfo(windstrike cd=9)
Define(ascendance_talent_enhancement 21972)
# Transform into an Air Ascendant for 15 seconds, immediately dealing 344548s1 Nature damage to any enemy within 344548A1 yds, reducing the cooldown and cost of Stormstrike by s4, and transforming your auto attack and Stormstrike into Wind attacks which bypass armor and have a s1 yd range.
Define(ascendance_talent 21675)
# Transform into a Flame Ascendant for 15 seconds, replacing Chain Lightning with Lava Beam, removing the cooldown on Lava Burst, and increasing the damage of Lava Burst by an amount equal to your critical strike chance.rnrnWhen you transform into the Flame Ascendant, instantly cast a Lava Burst at all enemies affected by your Flame Shock, and refresh your Flame Shock durations to 18 seconds.
Define(crashing_storm_talent 21973)
# Crash Lightning also electrifies the ground, leaving an electrical field behind which damages enemies within it for 7*210801s1 Nature damage over 6 seconds. 
Define(earthen_spike_talent 22977)
# Summons an Earthen Spike under an enemy, dealing s1 Physical damage and increasing Physical and Nature damage you deal to the target by s2 for 10 seconds.
Define(echo_of_the_elements_talent_elemental 22357)
# ?c1[Lava Burst now has s2+1][Riptide, Healing Stream Totem, and Lava Burst now have s2+1] charges. Effects that reset ?c1[its][their] remaining cooldown will instead grant 1 charge.
Define(echoing_shock_talent 23460)
# Shock the target for (65 of Spell Power) Elemental damage and create an ancestral echo, causing your next damage or healing spell to be cast a second time s2/1000.1 sec later for free.
Define(elemental_blast_talent 22353)
# Harnesses the raw power of the elements, dealing (140 of Spell Power) Elemental damage and increasing your Critical Strike or Haste by 118522s1 or Mastery by 173184s1*168534bc1 for 10 seconds.?a343725[rnrn|cFFFFFFFFGenerates 343725s10 Maelstrom.|r][]
Define(elemental_blast_talent_elemental 23190)
# Harnesses the raw power of the elements, dealing (140 of Spell Power) Elemental damage and increasing your Critical Strike or Haste by 118522s1 or Mastery by 173184s1*168534bc1 for 10 seconds.?a343725[rnrn|cFFFFFFFFGenerates 343725s10 Maelstrom.|r][]
Define(feral_lunge_talent 22149)
# Lunge at your enemy as a ghostly wolf, biting them to deal 215802s1 Physical damage.
Define(fire_nova_talent 22171)
# Erupt a burst of fiery damage from all targets affected by your Flame Shock, dealing 333977s1 Fire damage to up to 333977I targets within 333977A1 yds of your Flame Shock targets.
Define(ice_strike_talent 23109)
# Strike your target with an icy blade, dealing s1 Frost damage and snaring them by s2 for 6 seconds.rnrnSuccessful Ice Strikes reset the cooldown of your Flame Shock and Frost Shock spells.
Define(icefury_talent 23111)
# Hurls frigid ice at the target, dealing (82.5 of Spell Power) Frost damage and causing your next n Frost Shocks to deal s2 increased damage and generate 343725s7 Maelstrom.rnrn|cFFFFFFFFGenerates 343725s8 Maelstrom.|r
Define(lashing_flames_talent 22354)
# Lava Lash now increases the damage of Flame Shock on its target by 334168s1 for 20 seconds.
Define(liquid_magma_totem_talent 19273)
# Summons a totem at the target location for 15 seconds that hurls liquid magma at a random nearby target every 192226t1 sec, dealing (15 of Spell Power)*(1+(137040s3/100)) Fire damage to all enemies within 192223A1 yards.
Define(master_of_the_elements_talent 19271)
# Casting Lava Burst increases the damage of your next Nature, Physical, or Frost spell by 260734s1.
Define(primal_elementalist_talent 19266)
# Your Earth, Fire, and Storm Elementals are drawn from primal elementals s1 more powerful than regular elementals, with additional abilities, and you gain direct control over them.
Define(static_discharge_talent 22358)
# Discharge excess energy from your Lightning Shield, dealing (23 of Spell Power) Nature damage to an enemy within 342244A1 yds every t1 sec for 3 seconds.rnrnTargets with your Flame Shock on them are preferred.
Define(storm_elemental_talent 19272)
# Calls forth a Greater Storm Elemental to hurl gusts of wind that damage the Shaman's enemies for 30 seconds.rnrnWhile the Storm Elemental is active, each time you cast Lightning Bolt or Chain Lightning, the cast time of Lightning Bolt and Chain Lightning is reduced by 263806s1, stacking up to 263806u times.
Define(stormkeeper_talent_enhancement 22352)
# Charge yourself with lightning, causing your next n Chain Lightnings to deal s2 more damage and be instant cast.
Define(stormkeeper_talent 22153)
# Charge yourself with lightning, causing your next n Lightning Bolts to deal s2 more damage, and also causes your next n Lightning Bolts or Chain Lightnings to be instant cast and trigger an Elemental Overload on every target.
Define(sundering_talent 22351)
# Shatters a line of earth in front of you with your main hand weapon, causing s1 Flamestrike damage and Incapacitating any enemy hit for 2 seconds.
Define(hex 51514)
Define(potion_of_spectral_intellect_item 171273)
    ItemInfo(potion_of_spectral_intellect_item cd=1 shared_cd="item_cd_4" proc=307162)
Define(potion_of_spectral_agility_item 171270)
    ItemInfo(potion_of_spectral_agility_item cd=1 shared_cd="item_cd_4" proc=307159)
Define(echoes_of_great_sundering_runeforge 6991)
Define(elemental_equilibrium_runeforge 6990)
Define(seeds_of_rampant_growth_runeforge 7708)
Define(skybreakers_fiery_demise_runeforge 6989)
Define(windspeakers_lava_resurgence_runeforge 6992)
Define(doom_winds_runeforge 6993)
Define(primal_lava_actuators_runeforge 6996)
Define(lead_by_example_soulbind 342156)
Define(pustule_eruption_soulbind 351094)
Define(volatile_solvent_soulbind 323074)
Define(field_of_blossoms_soulbind 319191)
Define(grove_invigoration_soulbind 322721)
    `;
    // END
    scripts.registerScript("SHAMAN", undefined, name, desc, code, "include");
}
