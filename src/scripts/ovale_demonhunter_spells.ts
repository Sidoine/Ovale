import { OvaleScriptsClass } from "../engine/scripts";

export function registerDemonHunterSpells(scripts: OvaleScriptsClass) {
    const name = "ovale_demonhunter_spells";
    const desc = "[9.1] Ovale: DemonHunter spells";
    // THIS PART OF THIS FILE IS AUTOMATICALLY GENERATED
    let code = `Define(annihilation 201427)
# Slice your target for 227518s1+201428s1 Chaos damage. Annihilation has a 197125h chance to refund 193840s1 Fury.
  SpellInfo(annihilation fury=40)
Define(arcane_torrent 25046)
# Remove s1 beneficial effect from all enemies within A1 yards and restore m2 Energy.
  SpellInfo(arcane_torrent cd=120 gcd=1 energy=-15)
Define(blade_dance 188499)
# Strike ?a206416[your primary target for <firstbloodDmg> Physical damage and ][]all nearby enemies for <baseDmg> Physical damage?s320398[, and increase your chance to dodge by 193311s1 for 193311d.][. Deals reduced damage beyond 199552s1 targets.]
  SpellInfo(blade_dance fury=35 cd=15 duration=1)
  # Dodge chance increased by s2.
  SpellAddBuff(blade_dance blade_dance add=1)
Define(blind_faith_buff 355894)
# Elysian Decree shatters s1 additional Lesser Soul Fragments and grants you Blind Faith for 20 seconds. For each Lesser Soul Fragment you consume while Blind Faith is active you gain s2 Versatility and 356070s1 Fury.
  SpellInfo(blind_faith_buff duration=20 gcd=0 offgcd=1)
  # Versatility increased by w1.
  SpellAddBuff(blind_faith_buff blind_faith_buff add=1)
Define(bulk_extraction 320341)
# Demolish the spirit of all those around you, dealing s1 Fire damage to nearby enemies and extracting up to s2 Lesser Soul Fragments, drawing them to you for immediate consumption.
  SpellInfo(bulk_extraction cd=90)
  SpellRequire(bulk_extraction unusable set=1 enabled=(not hastalent(bulk_extraction_talent)))
Define(burning_wound_debuff 346278)
# Demon's Bite leaves an open wound on your enemy dealing 346278o1 Chaos damage over 15 seconds and increasing damage taken from your Immolation Aura by 346278s2.
  SpellInfo(burning_wound_debuff duration=15 gcd=0 offgcd=1 tick=3)
Define(chaos_blades 247938)
# Increases all damage done by s2 for 18 seconds.rnrnWhile active, your auto attack deals s1 increased damage, and causes Chaos damage.
  SpellInfo(chaos_blades cd=120 duration=18 gcd=0 offgcd=1)
  # Damage done increased by w2.rnrnAuto attack damage increased by s1, and deal Chaos damage.
  SpellAddBuff(chaos_blades chaos_blades add=1)
Define(chaos_nova 344867)
# Unleash an eruption of fel energy, dealing s2 Chaos damage and stunning all nearby enemies for 2 seconds.?s320412[rnrnEach enemy stunned by Chaos Nova has a s3 chance to generate a Lesser Soul Fragment.][]
  SpellInfo(chaos_nova fury=30 cd=60)
  SpellRequire(chaos_nova replaced_by set=chaos_nova_havoc enabled=(specialization("havoc")))
  SpellRequire(chaos_nova replaced_by set=fiery_brand enabled=(specialization("vengeance")))
  # @spellaura179057
  SpellAddBuff(chaos_nova chaos_nova add=1)
Define(chaos_nova_havoc 179057)
# Unleash an eruption of fel energy, dealing s2 Chaos damage and stunning all nearby enemies for 2 seconds.?s320412[rnrnEach enemy stunned by Chaos Nova has a s3 chance to generate a Lesser Soul Fragment.][]
  SpellInfo(chaos_nova_havoc fury=30 cd=60 duration=2)
  # Stunned.
  SpellAddTargetDebuff(chaos_nova_havoc chaos_nova_havoc add=1)
Define(chaos_strike 344862)
# Slice your target for 222031s1+199547s1 Chaos damage. Chaos Strike has a 197125h chance to refund 193840s1 Fury.
  SpellInfo(chaos_strike fury=40)
  SpellRequire(chaos_strike replaced_by set=chaos_strike_havoc enabled=(specialization("havoc")))
  SpellRequire(chaos_strike replaced_by set=soul_cleave enabled=(specialization("vengeance")))
Define(chaos_strike_havoc 162794)
# Slice your target for 222031s1+199547s1 Chaos damage. Chaos Strike has a 197125h chance to refund 193840s1 Fury.
  SpellInfo(chaos_strike_havoc fury=40)
Define(consume_magic 278326)
# Consume m1 beneficial Magic effect removing it from the target?s320313[ and granting you s2 Fury][].
  SpellInfo(consume_magic cd=10 fury=-20)
Define(death_sweep 210152)
# Strike ?a206416[your primary target for <firstbloodDmg> Physical damage and ][]199552s1 nearby enemies for <baseDmg> Physical damage?s320398[, and increase your chance to dodge by 193311s1 for 193311d.][.]
  SpellInfo(death_sweep fury=35 cd=9)
  # Dodge chance increased by s3.
  SpellAddBuff(death_sweep death_sweep add=1)
Define(demon_blades_unused_0 203555)
# Your auto attacks have a s1 chance to deal additional Shadow damage and generate Fury.
  SpellInfo(demon_blades_unused_0 gcd=0 offgcd=1 unusable=1)
  SpellRequire(demon_blades_unused_0 unusable set=1 enabled=(not hastalent(demon_blades_talent)))
Define(demon_spikes 203720)
# Surge with fel power, increasing your Armor by 203819s2*AGI/100?s321028[, and your Parry chance by 203819s1, for 6 seconds][].
  SpellInfo(demon_spikes cd=20 gcd=0 offgcd=1)
Define(demons_bite 344859)
# Quickly attack for s2 Physical damage.rnrn|cFFFFFFFFGenerates ?a258876[m3+258876s3 to M3+258876s4][m3 to M3] Fury.|r
  SpellInfo(demons_bite)
  SpellRequire(demons_bite replaced_by set=demons_bite_unused_0 enabled=(specialization("havoc")))
  SpellRequire(demons_bite replaced_by set=shear enabled=(specialization("vengeance")))
Define(demons_bite_unused_0 162243)
# Quickly attack for s2 Physical damage.rnrn|cFFFFFFFFGenerates ?a258876[m3+258876s3 to M3+258876s4][m3 to M3] Fury.|r
  SpellInfo(demons_bite_unused_0 fury=-25)
  SpellRequire(demons_bite_unused_0 replaced_by set=demon_blades_unused_0 enabled=(hastalent(demon_blades_talent)))
Define(disrupt 183752)
# Interrupts the enemy's spellcasting and locks them from that school of magic for 3 seconds.|cFFFFFFFF?s183782[rnrnGenerates 218903s1 Fury on a successful interrupt.][]|r
  SpellInfo(disrupt cd=15 duration=3 gcd=0 offgcd=1 interrupt=1)
Define(elysian_decree 306830)
# Place a Kyrian Sigil at the target location that activates after 2 seconds.rnrnDetonates to deal 307046s1 Arcane damage and shatter up to s3 Lesser Soul Fragments from enemies affected by the sigil. Deals reduced damage beyond s1 targets.
  SpellInfo(elysian_decree cd=60 duration=2)
Define(essence_break 258860)
# Slash all enemies in front of you for s1 Chaos damage, and increase the damage your Chaos Strike and Blade Dance deal to them by 320338s1 for 8 seconds.
  SpellInfo(essence_break cd=20)
  SpellRequire(essence_break unusable set=1 enabled=(not hastalent(essence_break_talent)))
Define(essence_break_debuff 320338)
# Slash all enemies in front of you for s1 Chaos damage, and increase the damage your Chaos Strike and Blade Dance deal to them by 320338s1 for 8 seconds.
  SpellInfo(essence_break_debuff duration=8 gcd=0 offgcd=1)
  # The Demon Hunter's Chaos Strike and Blade Dance inflict s2 additional damage.
  SpellAddTargetDebuff(essence_break_debuff essence_break_debuff add=1)
Define(exposed_wound_debuff 339229)
  SpellInfo(exposed_wound_debuff duration=10 gcd=0 offgcd=1)
Define(eye_beam 198013)
# Blasts all enemies in front of you, ?s320415[dealing guaranteed critical strikes][] for up to <dmg> Chaos damage over 2 seconds. Deals reduced damage to secondary targets.?s343311[rnrnWhen Eye Beam finishes fully channeling, your Haste is increased by an additional 343312s1 for 12 seconds.][]
  SpellInfo(eye_beam fury=30 cd=30 duration=2 channel=2 tick=0.2)
Define(fel_barrage 258925)
# Unleash a torrent of Fel energy over 3 seconds, inflicting ((3 seconds/t1)+1)*258926s1 Chaos damage to all enemies within 258926A1 yds. Deals reduced damage beyond 258926s2 targets.
  SpellInfo(fel_barrage cd=60 duration=3 channel=3 tick=0.25)
  SpellRequire(fel_barrage unusable set=1 enabled=(not hastalent(fel_barrage_talent)))
  # Unleashing Fel.
  SpellAddBuff(fel_barrage fel_barrage add=1)
Define(fel_bombardment_buff 337775)
# Immolation Aura damage has a chance to grant you a stack of Fel Bombardment, increasing the damage that your next Throw Glaive deals to your primary target by 337849s1 and launching an additional glaive at a nearby target. This effect stacks up to 337849u times.
  SpellInfo(fel_bombardment_buff gcd=0 offgcd=1)
  # Immolation Aura damage has a chance to grant you a stack of Fel Bombardment, increasing the damage that your next Throw Glaive deals to your primary target by 337849s1 and launching an additional glaive at a nearby target. This effect stacks up to 337849u times.
  SpellAddBuff(fel_bombardment_buff fel_bombardment_buff add=1)
Define(fel_devastation 212084)
# Unleash the fel within you, damaging enemies directly in front of you for 212105s1*(2/t1) Fire damage over 2 seconds.?s320639[ Causing damage also heals you for up to 212106s1*(2/t1) health.][]
  SpellInfo(fel_devastation fury=50 cd=60 duration=2 channel=2 tick=0.2)
Define(fel_eruption 211881)
# Impales the target for s1 Chaos damage and stuns them for 4 seconds.
  SpellInfo(fel_eruption fury=10 pain=10 cd=30 duration=4)
  SpellRequire(fel_eruption unusable set=1 enabled=(not hastalent(fel_eruption_talent)))
  # Stunned.
  SpellAddTargetDebuff(fel_eruption fel_eruption add=1)
Define(fel_rush 344865)
# Rush forward, incinerating anything in your path for 192611s1 Chaos damage.
  SpellInfo(fel_rush cd=10 gcd=0.25)
  SpellRequire(fel_rush replaced_by set=fel_rush_unused_1 enabled=(specialization("havoc")))
  SpellRequire(fel_rush replaced_by set=infernal_strike enabled=(specialization("vengeance")))
Define(fel_rush_unused_1 195072)
# Rush forward, incinerating anything in your path for 192611s1 Chaos damage.
  SpellInfo(fel_rush_unused_1 cd=10 gcd=0.25)
Define(felblade 232893)
# Charge to your target and deal 213243sw2 Fire damage.rnrn?s203513[Shear has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r]?a203555[Demon Blades has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r][Demon's Bite has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r]
  SpellInfo(felblade cd=15)
  SpellRequire(felblade unusable set=1 enabled=(not {hastalent(felblade_talent) or hastalent(felblade_talent_vengeance)}))
Define(fiery_brand 204021)
# Brand an enemy with a demonic symbol, instantly dealing sw2 Fire damage?s320962[ and 207771s3*8 seconds Fire damage over 8 seconds][]. The enemy's damage done to you is reduced by s1 for 8 seconds.
  SpellInfo(fiery_brand cd=60)
  # Dealing s1 less damage to the branding Demon Hunter.
  SpellAddBuff(fiery_brand fiery_brand add=1)
Define(fiery_brand_debuff 207744)
# Brand an enemy with a demonic symbol, instantly dealing sw2 Fire damage?s320962[ and 207771s3*8 seconds Fire damage over 8 seconds][]. The enemy's damage done to you is reduced by s1 for 8 seconds.
  SpellInfo(fiery_brand_debuff duration=8 gcd=0 offgcd=1)
  # Branded, dealing 204021s1 less damage to @auracaster?s264002[ and taking s2 more Fire damage from them][].
  SpellAddTargetDebuff(fiery_brand_debuff fiery_brand_debuff add=1)
Define(fracture 263642)
# Rapidly slash your target for 225919sw1+225921sw1 Physical damage, and shatter s1 Lesser Soul Fragments from them.rnrn|cFFFFFFFFGenerates s4 Fury.|r
  SpellInfo(fracture cd=4.5 fury=-25)
  SpellRequire(fracture unusable set=1 enabled=(not hastalent(fracture_talent)))
Define(furious_gaze_buff 273232)
# When Eye Beam finishes fully channeling, your Haste is increased by s1 for 12 seconds.
  SpellInfo(furious_gaze_buff duration=12 gcd=0 offgcd=1)
  # Haste increased by w1.
  SpellAddBuff(furious_gaze_buff furious_gaze_buff add=1)
Define(glaive_tempest 342817)
# Launch two demonic glaives in a whirlwind of energy, causing 14*342857s1 Chaos damage over 3 seconds to all nearby enemies. Deals reduced damage beyond s2 targets.
  SpellInfo(glaive_tempest fury=30 cd=20 duration=3)
  SpellRequire(glaive_tempest unusable set=1 enabled=(not hastalent(glaive_tempest_talent)))
Define(immolation_aura 258920)
# Engulf yourself in flames, ?a320364 [instantly causing 258921s1 Fire damage to enemies within 258921A1 yards and ][]radiating 258922s1*6 seconds Fire damage over 6 seconds.?s320374[rnrn|cFFFFFFFFGenerates <havocTalentFury> Fury over 6 seconds.|r][]?(s212612 & !s320374)[rnrn|cFFFFFFFFGenerates <havocFury> Fury.|r][]?s212613[rnrn|cFFFFFFFFGenerates <vengeFury> Fury over 6 seconds.|r][]
  SpellInfo(immolation_aura cd=30 duration=6 fury=-8 tick=1)
  # Burning nearby enemies for 258922s1 Fire damage every t1 sec.?a207548[rnrnMovement speed increased by w4.][]?a320331[rnrnArmor increased by w5. Attackers suffer Fire damage.][]
  SpellAddBuff(immolation_aura immolation_aura add=1)
Define(imprison 217832)
# Imprisons a demon, beast, or humanoid, incapacitating them for 60 seconds. Damage will cancel the effect. Limit 1.
  SpellInfo(imprison cd=45 duration=60)
  # Incapacitated.
  SpellAddTargetDebuff(imprison imprison add=1)
Define(infernal_strike 189110)
# Leap through the air toward a targeted location, dealing 189112s1 Fire damage to all enemies within 189112a1 yards.
  SpellInfo(infernal_strike cd=20 gcd=0 offgcd=1)
Define(metamorphosis 191427)
# Leap into the air and land with explosive force, dealing 200166s2 Chaos damage to enemies within 8 yds, and stunning them for 3 seconds. Players are Dazed for 3 seconds instead.rnrnUpon landing, you are transformed into a hellish demon for 30 seconds, ?s320645[immediately resetting the cooldown of your Eye Beam and Blade Dance abilities, ][]greatly empowering your Chaos Strike and Blade Dance abilities?s320422[ and gaining 320422s1 Haste][]?s204909[ and 162264s3 Leech][].
  SpellInfo(metamorphosis cd=300)
  SpellRequire(metamorphosis replaced_by set=metamorphosis_vengeance enabled=(specialization("vengeance")))
  # Chaos Strike and Blade Dance upgraded to @spellname201427 and @spellname210152.rnHaste increased by 320422s1.?s204909[rnLeech increased by w3.][]
  SpellAddBuff(metamorphosis metamorphosis_buff add=1)
Define(metamorphosis_buff 162264)
# Leap into the air and land with explosive force, dealing 200166s2 Chaos damage to enemies within 8 yds, and stunning them for 3 seconds. Players are Dazed for 3 seconds instead.rnrnUpon landing, you are transformed into a hellish demon for 30 seconds, ?s320645[immediately resetting the cooldown of your Eye Beam and Blade Dance abilities, ][]greatly empowering your Chaos Strike and Blade Dance abilities?s320422[ and gaining 320422s1 Haste][]?s204909[ and 162264s3 Leech][].
  SpellInfo(metamorphosis_buff duration=30 gcd=0 offgcd=1 tick=1)
Define(metamorphosis_vengeance 187827)
# Transform to demon form for 15 seconds, increasing current and maximum health by s2 and Armor by s7?s321067[. While transformed, Shear and Fracture generate one additional Lesser Soul Fragment][]?s321068[ and s4 additional Fury][].
  SpellInfo(metamorphosis_vengeance cd=300 duration=15 gcd=0 offgcd=1 tick=2)
  # Maximum health increased by w2.rnArmor increased by w7.rn?s263642[Fracture][Shear] generates w4 additional Fury and one additional Lesser Soul Fragment.
  SpellAddBuff(metamorphosis_vengeance metamorphosis_vengeance add=1)
  # Maximum health increased by w2.rnArmor increased by w7.rn?s263642[Fracture][Shear] generates w4 additional Fury and one additional Lesser Soul Fragment.
  SpellAddTargetDebuff(metamorphosis_vengeance metamorphosis_vengeance add=1)
Define(momentum_buff 208628)
# Increases all damage done by s1.
  SpellInfo(momentum_buff duration=6 gcd=0 offgcd=1)
  # Damage done increased by s1.
  SpellAddBuff(momentum_buff momentum_buff add=1)
Define(prepared_buff 203650)
# Reduces the cooldown of Vengeful Retreat by 10 sec, and generates (203650s1/5)*10 seconds Fury over 10 seconds if you damage at least one enemy with Vengeful Retreat.
  SpellInfo(prepared_buff duration=10 gcd=0 offgcd=1)
Define(shear 203782)
# Shears an enemy for s1 Physical damage, and shatters ?a187827[two Lesser Soul Fragments][a Lesser Soul Fragment] from your target.rnrn|cFFFFFFFFGenerates m2 Fury.|r
  SpellInfo(shear fury=-10)
  SpellRequire(shear replaced_by set=fracture enabled=(hastalent(fracture_talent)))
Define(sigil_of_chains 202138)
# Place a Sigil of Chains at the target location that activates after 2 seconds.rnrnAll enemies affected by the sigil are pulled to its center and are snared, reducing movement speed by 204843s1 for 6 seconds.
  SpellInfo(sigil_of_chains cd=90 duration=2)
  SpellRequire(sigil_of_chains unusable set=1 enabled=(not hastalent(sigil_of_chains_talent)))
Define(sigil_of_flame 204596)
# Place a Sigil of Flame at the target location that activates after 2 seconds.rnrnDeals 204598s1 Fire damage?s320794[, and an additional 204598o3 Fire damage over 6 seconds,][] to all enemies affected by the sigil.
  SpellInfo(sigil_of_flame cd=30 duration=2)
  # Sigil of Flame is active.
  SpellAddBuff(sigil_of_flame sigil_of_flame add=1)
Define(sigil_of_misery 207684)
# Place a Sigil of Misery at the target location that activates after 2 seconds.rnrnCauses all enemies affected by the sigil to cower in fear, disorienting them for 20 seconds.
  SpellInfo(sigil_of_misery cd=180 duration=2)
Define(sigil_of_silence 202137)
# Place a Sigil of Silence at the target location that activates after 2 seconds.rnrnSilences all enemies affected by the sigil for 6 seconds.
  SpellInfo(sigil_of_silence cd=120 duration=2)
Define(sinful_brand 317009)
# Brand an enemy with the mark of the Venthyr, reducing their melee attack speed by s3, their casting speed by s2, and inflicting o1 Shadow damage over 8 seconds.rnrnActivating Metamorphosis applies Sinful Brand to all nearby enemies.
  SpellInfo(sinful_brand cd=45 duration=8 tick=2)
  # Suffering w1 Shadow damage every t1 sec. Casting speed slowed by w2. Melee attack speed slowed by w3.
  SpellAddTargetDebuff(sinful_brand sinful_brand add=1)
Define(soul_cleave 228477)
# Viciously strike all enemies in front of you for 228478s1 Physical damage and heal yourself for s4. Deals reduced damage beyond 228478s2 targets.rnrnConsumes up to s3 Soul Fragments within s1 yds?s321021[ and heals you for an additional s5 for each Soul Fragment consumed][].
  SpellInfo(soul_cleave fury=30)
Define(spirit_bomb 247454)
# Consume up to s2 Soul Fragments within s1 yds and then explode, afflicting nearby enemies with Frailty for 20 seconds and damaging them for 247455s1 Fire per fragment. Deals reduced damage beyond s2 targets.rnrnYou heal for 247456s1 of all damage you deal to enemies with Frailty.
  SpellInfo(spirit_bomb fury=30 duration=1.5)
  SpellRequire(spirit_bomb unusable set=1 enabled=(not hastalent(spirit_bomb_talent)))
Define(the_hunt 323639)
# Charge to your target, striking them for 323802s1 Nature damage, rooting them in place for 1.5 seconds and inflicting 345335o1 Nature damage over 6 seconds to up to 345396s2 enemies in your path. rnrnThe pursuit invigorates your soul, healing you for ?c1[345422s1][345422s2] of the damage you deal to your Hunt target for 30 seconds.
  SpellInfo(the_hunt cd=90)
  # Marked by the Demon Hunter, converting ?c1[345422s1][345422s2] of the damage done to healing.
  SpellAddTargetDebuff(the_hunt the_hunt_debuff add=1)
  # Suffering w1 Nature damage every t1 sec.
  SpellAddTargetDebuff(the_hunt the_hunt_unused_2 add=1)
Define(the_hunt_debuff 323802)
# Charge to your target, striking them for 323802s1 Nature damage, rooting them in place for 1.5 seconds and inflicting 345335o1 Nature damage over 6 seconds to up to 345396s2 enemies in your path. rnrnThe pursuit invigorates your soul, healing you for ?c1[345422s1][345422s2] of the damage you deal to your Hunt target for 30 seconds.
  SpellInfo(the_hunt_debuff duration=30 gcd=0 offgcd=1)
Define(the_hunt_unused_2 345335)
# Charge to your target, striking them for 323802s1 Nature damage, rooting them in place for 1.5 seconds and inflicting 345335o1 Nature damage over 6 seconds to up to 345396s2 enemies in your path. rnrnThe pursuit invigorates your soul, healing you for ?c1[345422s1][345422s2] of the damage you deal to your Hunt target for 30 seconds.
  SpellInfo(the_hunt_unused_2 duration=6 gcd=0 offgcd=1 tick=2)
Define(throw_glaive 185123)
# Throw a demonic glaive at the target, dealing 337819s1 Physical damage. The glaive can ricochet to ?s320386[337819x1-1 additional enemies][an additional enemy] within 10 yards. 
  SpellInfo(throw_glaive cd=9)
  SpellRequire(throw_glaive replaced_by set=throw_glaive_vengeance enabled=(specialization("vengeance")))
Define(throw_glaive_vengeance 204157)
# Throw a demonic glaive at the target, dealing 346665s1 Physical damage. The glaive can ricochet to ?s320386[346665x1-1 additional enemies][an additional enemy] within 10 yards. Generates high threat.
  SpellInfo(throw_glaive_vengeance cd=9)
Define(unbound_chaos_buff 347462)
  SpellInfo(unbound_chaos_buff duration=20 max_stacks=1 gcd=0 offgcd=1)
  # Damage of your next Fel Rush increased by s1.
  SpellAddBuff(unbound_chaos_buff unbound_chaos_buff add=1)
Define(vengeful_retreat 344866)
# Remove all snares and vault away. Nearby enemies take 198813s2 Physical damage?s320635[ and have their movement speed reduced by 198813s1 for 3 seconds][].?a203551[rnrn|cFFFFFFFFGenerates (203650s1/5)*10 seconds Fury over 10 seconds if you damage an enemy.|r][]
  SpellInfo(vengeful_retreat cd=25 gcd=0 offgcd=1)
  SpellRequire(vengeful_retreat replaced_by set=vengeful_retreat_unused_0 enabled=(specialization("havoc")))
  SpellRequire(vengeful_retreat replaced_by set=demon_spikes enabled=(specialization("vengeance")))
Define(vengeful_retreat_unused_0 198793)
# Remove all snares and vault away. Nearby enemies take 198813s2 Physical damage?s320635[ and have their movement speed reduced by 198813s1 for 3 seconds][].?a203551[rnrn|cFFFFFFFFGenerates (203650s1/5)*10 seconds Fury over 10 seconds if you damage an enemy.|r][]
  SpellInfo(vengeful_retreat_unused_0 cd=25 duration=1 gcd=0 offgcd=1)
Define(agonizing_flames_talent 22503)
# Immolation Aura increases your movement speed by s1 and its duration is increased by s2.
Define(blind_fury_talent 21854)
# Eye Beam generates s3/5 Fury every sec. and its duration is increased by s1.
Define(bulk_extraction_talent 21902)
# Demolish the spirit of all those around you, dealing s1 Fire damage to nearby enemies and extracting up to s2 Lesser Soul Fragments, drawing them to you for immediate consumption.
Define(burning_alive_talent 22507)
# Every 207771t3 sec, Fiery Brand spreads to one nearby enemy.
Define(charred_flesh_talent 22541)
# Immolation Aura damage increases the duration of your Fiery Brand by s1/1000.2 sec.
Define(cycle_of_hatred_talent 21866)
# When Chaos Strike refunds Fury, it also reduces the cooldown of Eye Beam by s1 sec.
Define(demon_blades_talent 22799)
# Your auto attacks have a s1 chance to deal additional Shadow damage and generate Fury.
Define(demonic_talent 21900)
# Eye Beam causes you to enter demon form for s1/1000 sec after it finishes dealing damage.
Define(demonic_appetite_talent 22493)
# Chaos Strike has a chance to spawn a Lesser Soul Fragment. Consuming any Soul Fragment grants 210041s1 Fury.
Define(essence_break_talent 21868)
# Slash all enemies in front of you for s1 Chaos damage, and increase the damage your Chaos Strike and Blade Dance deal to them by 320338s1 for 8 seconds.
Define(fel_barrage_talent 22547)
# Unleash a torrent of Fel energy over 3 seconds, inflicting ((3 seconds/t1)+1)*258926s1 Chaos damage to all enemies within 258926A1 yds. Deals reduced damage beyond 258926s2 targets.
Define(fel_eruption_talent 22767)
# Impales the target for s1 Chaos damage and stuns them for 4 seconds.
Define(felblade_talent_vengeance 22504)
# Charge to your target and deal 213243sw2 Fire damage.rnrn?s203513[Shear has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r]?a203555[Demon Blades has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r][Demon's Bite has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r]
Define(felblade_talent 22416)
# Charge to your target and deal 213243sw2 Fire damage.rnrn?s203513[Shear has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r]?a203555[Demon Blades has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r][Demon's Bite has a chance to reset the cooldown of Felblade.rnrn|cFFFFFFFFGenerates 213243s3 Fury.|r]
Define(first_blood_talent 21867)
# Reduces the Fury cost of Blade Dance by s2 and increases its damage to <firstbloodDmg> against the first target struck.
Define(fracture_talent 22770)
# Rapidly slash your target for 225919sw1+225921sw1 Physical damage, and shatter s1 Lesser Soul Fragments from them.rnrn|cFFFFFFFFGenerates s4 Fury.|r
Define(glaive_tempest_talent 21862)
# Launch two demonic glaives in a whirlwind of energy, causing 14*342857s1 Chaos damage over 3 seconds to all nearby enemies. Deals reduced damage beyond s2 targets.
Define(momentum_talent 21901)
# Fel Rush increases your damage done by 208628s1 for 6 seconds.rnrnVengeful Retreat's cooldown is reduced by s1/-1000 sec, and it generates (203650s1/5)*10 seconds Fury over 10 seconds if it damages at least one enemy.
Define(sigil_of_chains_talent 22511)
# Place a Sigil of Chains at the target location that activates after 2 seconds.rnrnAll enemies affected by the sigil are pulled to its center and are snared, reducing movement speed by 204843s1 for 6 seconds.
Define(spirit_bomb_talent 22540)
# Consume up to s2 Soul Fragments within s1 yds and then explode, afflicting nearby enemies with Frailty for 20 seconds and damaging them for 247455s1 Fire per fragment. Deals reduced damage beyond s2 targets.rnrnYou heal for 247456s1 of all damage you deal to enemies with Frailty.
Define(trail_of_ruin_talent 22909)
# The final slash of Blade Dance inflicts an additional 258883o1 Chaos damage over 4 seconds.
Define(unbound_chaos_talent 22494)
# Activating Immolation Aura increases the damage of your next Fel Rush by 347462s1. Lasts 20 seconds.
Define(potion_of_phantom_fire_item 171349)
    ItemInfo(potion_of_phantom_fire_item cd=300 shared_cd="item_cd_4" rppm=12 proc=307495)
Define(agony_gaze_runeforge 7681)
Define(blind_faith_runeforge 7699)
Define(burning_wound_runeforge 7219)
Define(chaos_theory_runeforge 7050)
Define(darkglare_medallion_runeforge 7043)
Define(razelikhs_defilement_runeforge 7046)
Define(serrated_glaive_conduit 152)
    `;
    // END
    code += `
Define(arcane_torrent 202719)
    SpellInfo(arcane_torrent cd=120 fury=-15)
#blade_dance
    SpellRequire(blade_dance fury add=-20 enabled=(hastalent(first_blood_talent)))
    SpellRequire(blade_dance replaced_by set=death_sweep enabled=(buffpresent(metamorphosis_buff)))
#chaos_strike_havoc
    SpellRequire(chaos_strike_havoc replaced_by set=annihilation enabled=(buffpresent(metamorphosis_buff)))
#death_sweep
    SpellRequire(death_sweep fury add=-20 enabled=(hastalent(first_blood_talent)))
Define(frailty_debuff 247456)
    SpellInfo(frailty_debuff duration=20)
#infernal_strike
    SpellRequire(infernal_strike unusable set=1 enabled=(isrooted()))
#metamorphosis
    SpellRequire(metamorphosis unusable set=1 enabled=(isrooted()))
#spirit_bomb
    SpellRequire(spirit_bomb unusable set=1 enabled=(soulfragments() == 0))
	SpellAddTargetDebuff(spirit_bomb frailty_debuff add=1)
    `;
    scripts.registerScript(
        "DEMONHUNTER",
        undefined,
        name,
        desc,
        code,
        "include"
    );
}
