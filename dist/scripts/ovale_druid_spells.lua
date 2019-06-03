local __exports = LibStub:NewLibrary("ovale/scripts/ovale_druid_spells", 80000)
if not __exports then return end
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
local registerBase = function()
    local name = "ovale_druid_base_spells"
    local desc = "[8.1] Ovale: Druid baseline spells"
    local code = [[Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
Define(arcanic_pulsar_buff 287784)
# Starsurge's damage is increased by s2. Every s4 Starsurges, gain Celestial Alignment for s3 sec.
  SpellInfo(arcanic_pulsar_buff channel=-0.001 gcd=0 offgcd=1)

Define(barkskin 22812)
# Your skin becomes as tough as bark, reducing all damage you take by s2 and preventing damage from delaying your spellcasts. Lasts 12 seconds.rnrnUsable while stunned, frozen, incapacitated, feared, or asleep, and in all shapeshift forms.
  SpellInfo(barkskin cd=60 duration=12 gcd=0 offgcd=1 tick=1)
  # All damage taken reduced by s2.
  SpellAddBuff(barkskin barkskin=1)
Define(bear_form 5487)
# Shapeshift into Bear Form, increasing armor by m3 and Stamina by 1178s2, granting protection from Polymorph effects, and increasing threat generation.rnrnThe act of shapeshifting frees you from movement impairing effects.
# Rank 2: Bear Form gives an additional s1 Stamina.rn
  SpellInfo(bear_form)
  # Armor increased by w3.rnStamina increased by 1178s2.rnImmune to Polymorph effects.
  SpellAddBuff(bear_form bear_form=1)
  # Armor increased by w3.rnStamina increased by 1178s2.rnImmune to Polymorph effects.
  SpellAddTargetDebuff(bear_form bear_form=1)
Define(berserk 106951)
# Reduces the energy cost of all Cat Form abilities by s1 and increases maximum Energy by s3 for 20 seconds.
  SpellInfo(berserk cd=180 duration=20 gcd=1)
  # Reduces the energy cost of all Cat Form abilities by s1 and increases maximum Energy by s3.
  SpellAddBuff(berserk berserk=1)
Define(berserking 26297)
# Increases your haste by s1 for 12 seconds.
  SpellInfo(berserking cd=180 duration=12 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking=1)
Define(blood_fury 20572)
# Increases your attack power by s1 for 15 seconds.
  SpellInfo(blood_fury cd=120 duration=15 gcd=0 offgcd=1)
  # Attack power increased by w1.
  SpellAddBuff(blood_fury blood_fury=1)
Define(bristling_fur 155835)
# Bristle your fur, causing you to generate Rage based on damage taken for 8 seconds.
  SpellInfo(bristling_fur cd=40 duration=8 talent=bristling_fur_talent)
  # Generating Rage from taking damage.
  SpellAddBuff(bristling_fur bristling_fur=1)
Define(brutal_slash 202028)
# Strikes all nearby enemies with a massive slash, inflicting s1 Physical damage.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(brutal_slash energy=25 cd=8 gcd=1 talent=brutal_slash_talent)
Define(cat_form 768)
# Shapeshift into Cat Form, increasing auto-attack damage by (25 of Spell Power), movement speed by 113636s1, granting protection from Polymorph effects, and reducing falling damage.rnrnThe act of shapeshifting frees you from movement impairing effects.
  SpellInfo(cat_form)
  # Autoattack damage increased by w3.rnImmune to Polymorph effects.rnMovement speed increased by 113636s1 and falling damage reduced.
  SpellAddBuff(cat_form cat_form=1)
Define(celestial_alignment 194223)
# Celestial bodies align, granting s5/10 Astral Power, and increasing spell damage by s1 and Haste by s3 for 20 seconds.
  SpellInfo(celestial_alignment cd=180 duration=20 lunarpower=-40)
  # Spell damage increased by s1.rnHaste increased by s3.
  SpellAddBuff(celestial_alignment celestial_alignment=1)
Define(feral_frenzy 274837)
# Unleash a furious frenzy, clawing your target m2 times for 274838s1*m2 Physical damage and an additional m2*274838s3*6 seconds/274838t3 Bleed damage over 6 seconds.rnrn|cFFFFFFFFAwards s1 combo points.|r
  SpellInfo(feral_frenzy energy=25 cd=45 duration=1 gcd=1 tick=0.2 talent=feral_frenzy_talent)
  SpellAddBuff(feral_frenzy feral_frenzy=1)
Define(ferocious_bite 22568)
# Finishing move that causes Physical damage per combo point and consumes up to ?a106951[25*106951s1/-100.1]?a102543[25*(25 of Spell Power)/-100.1][25] additional Energy to increase damage by up to 100.rnrn?s202031[Ferocious Bite will also refresh the duration of your Rip on your target.rnrn][]   1 point  : m1*1/5 damagern   2 points: m1*2/5 damagern   3 points: m1*3/5 damagern   4 points: m1*4/5 damagern   5 points: m1*5/5 damage
  SpellInfo(ferocious_bite energy=25 combopoints=1 gcd=1)
Define(fireblood 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. 
  SpellInfo(fireblood cd=120 gcd=0 offgcd=1)
Define(force_of_nature 205636)
# Summons a stand of s1 Treants for 10 seconds which immediately taunt and attack enemies in the targeted area.rnrn|cFFFFFFFFGenerates m5/10 Astral Power.|r
  SpellInfo(force_of_nature cd=60 lunarpower=-20 talent=force_of_nature_talent)

Define(full_moon 274283)
# Deals m1 Arcane damage to the target and reduced damage to all other nearby enemies, and resets Full Moon to become New Moon.rnrn|cFFFFFFFFGenerates m2/10 Astral Power.|r
  SpellInfo(full_moon cd=25 lunarpower=-40)
Define(fury_of_elune 202770)
# Calls down a beam of pure celestial energy that follows the enemy, dealing <dmg> Astral damage over 8 seconds to all nearby targets.rnrn|cFFFFFFFFGenerates m3/10/t3*8 seconds Astral Power over its duration.|r
  SpellInfo(fury_of_elune cd=60 duration=8 tick=0.5 talent=fury_of_elune_talent)
  # Generating m3/10/t3*d Astral Power over d.
  SpellAddBuff(fury_of_elune fury_of_elune=1)
Define(half_moon 274282)
# Deals m1 Arcane damage to the target and empowers Half Moon to become Full Moon.rnrn|cFFFFFFFFGenerates m3/10 Astral Power.|r
  SpellInfo(half_moon cd=25 lunarpower=-20)
Define(incapacitating_roar 99)
# Invokes the spirit of Ursol to let loose a deafening roar, incapacitating all enemies within A1 yards for 3 seconds. Damage will cancel the effect. Usable in all shapeshift forms.
  SpellInfo(incapacitating_roar cd=30 duration=3)
  # Incapacitated.
  SpellAddTargetDebuff(incapacitating_roar incapacitating_roar=1)
Define(incarnation_chosen_of_elune 102560)
# An improved Moonkin Form that increases the damage of all your spells by s1 and grants you s3 Haste.rnrnLasts 30 seconds. You may shapeshift in and out of this improved Moonkin Form for its duration.
  SpellInfo(incarnation_chosen_of_elune cd=180 duration=30 lunarpower=-40 talent=incarnation_chosen_of_elune_talent)
  # Spell damage increased by s1.rnHaste increased by s3.
  SpellAddBuff(incarnation_chosen_of_elune incarnation_chosen_of_elune=1)
Define(incarnation_guardian_of_ursoc 102558)
# An improved Bear Form that reduces the cooldown on all melee damage abilities and Growl to 1.5 sec, causes Mangle to hit up to (25 of Spell Power) targets, and increases armor by (25 of Spell Power).rnrnLasts 30 seconds. You may freely shapeshift in and out of this improved Bear Form for its duration.
  SpellInfo(incarnation_guardian_of_ursoc cd=180 duration=30 talent=incarnation_guardian_of_ursoc_talent)
  # Incarnation: Guardian of Ursoc activated.
  SpellAddBuff(incarnation_guardian_of_ursoc incarnation_guardian_of_ursoc=1)
Define(incarnation_king_of_the_jungle 102543)
# An improved Cat Form that allows the use of Prowl once while in combat, causes Shred and Rake to deal damage as if stealth were active, reduces the cost of all Cat Form abilities by (25 of Spell Power), and increases maximum Energy by (25 of Spell Power).rnrnLasts 30 seconds. You may shapeshift in and out of this improved Cat Form for its duration.
  SpellInfo(incarnation_king_of_the_jungle cd=180 duration=30 gcd=1 talent=incarnation_king_of_the_jungle_talent)
  # Reduces the energy cost of all Cat Form abilities by s1 and increases maximum Energy by s2.
  SpellAddBuff(incarnation_king_of_the_jungle incarnation_king_of_the_jungle=1)
Define(innervate 29166)
# Infuse a friendly healer with energy, allowing them to cast spells without spending mana for 12 seconds.
  SpellInfo(innervate cd=180 duration=12)
  # Your spells cost no mana.
  SpellAddBuff(innervate innervate=1)
Define(iron_jaws 276026)
# Ferocious Bite has a s2 chance per combo point to increase the damage of your next Maim by s1 per combo point.
  SpellInfo(iron_jaws duration=30 channel=30 gcd=0 offgcd=1)
  # Your next Maim will deal an additional w1 damage per combo point.
  SpellAddBuff(iron_jaws iron_jaws=1)

Define(ironfur 192081)
# Increases armor by s1*AGI/100 for 7 seconds.?a231070[ Multiple uses of this ability may overlap.][]
# Rank 2: Multiple uses of Ironfur may overlap.rn
  SpellInfo(ironfur rage=45 cd=0.5 duration=7 max_stacks=1 gcd=0 offgcd=1)
  # Armor increased by w1*AGI/100.
  SpellAddBuff(ironfur ironfur=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)

Define(lively_spirit_buff 279646)
# When Innervate expires, for each spell the target cast using Innervate, you gain s1 Intellect for 20 seconds and 289335s1/100.1 mana.
  SpellInfo(lively_spirit_buff channel=-0.001 gcd=0 offgcd=1)

Define(lunar_beam 204066)
# Summons a beam of lunar light at your location, dealing 204069s2*8 Arcane damage and healing you for 204069s1*8 over m1 sec.
  SpellInfo(lunar_beam cd=75 duration=8.5 talent=lunar_beam_talent)
Define(lunar_strike 194153)
# Call down a strike of lunar energy, causing (76.5 of Spell Power) Arcane damage to the target, and m1*m3/100 Arcane damage to all other enemies within A1 yards.rnrn|cFFFFFFFFGenerates m2/10 Astral Power.|r
  SpellInfo(lunar_strike lunarpower=-12)
Define(maim 22570)
# Finishing move that causes Physical damage and stuns the target. Damage and duration increased per combo point:rnrn   1 point  : s2*1 damage, 1 secrn   2 points: s2*2 damage, 2 secrn   3 points: s2*3 damage, 3 secrn   4 points: s2*4 damage, 4 secrn   5 points: s2*5 damage, 5 sec
  SpellInfo(maim energy=30 combopoints=1 cd=20 gcd=1)
Define(mangle 33917)
# Mangle the target for s2 Physical damage.?a231064[ Deals s3 additional damage against bleeding targets.][]rnrn|cFFFFFFFFGenerates m4/10 Rage.|r
# Rank 2: Mangle deals 33917s3 additional damage against bleeding targets.
  SpellInfo(mangle cd=6 rage=-8)
Define(maul 6807)
# Maul the target for s2 Physical damage.
  SpellInfo(maul rage=45)
Define(mighty_bash 5211)
# Invokes the spirit of Ursoc to stun the target for 5 seconds. Usable in all shapeshift forms.
  SpellInfo(mighty_bash cd=50 duration=5 talent=mighty_bash_talent)
  # Stunned.
  SpellAddTargetDebuff(mighty_bash mighty_bash=1)
Define(moonfire 8921)
# A quick beam of lunar light burns the enemy for (14.499999999999998 of Spell Power) Arcane damage and then an additional 164812o2 Arcane damage over 16 seconds.?s5487[ Usable while in Bear Form.][]?s197911[rnrn|cFFFFFFFFGenerates m3/10 Astral Power.|r][]
  SpellInfo(moonfire rage=0 lunarpower=0)
Define(new_moon 274281)
# Deals m1 Arcane damage to the target and empowers New Moon to become Half Moon. rnrn|cFFFFFFFFGenerates m3/10 Astral Power.|r
  SpellInfo(new_moon cd=25 gcd=1 lunarpower=-10 talent=new_moon_talent)
Define(primal_wrath 285381)
# Finishing move that deals instant damage and applies Rip to all enemies within A1 yards. Lasts longer per combo point.rnrn   1 point  : s1*2 plus Rip for 4 secrn   2 points: s1*3 plus Rip for 6 secrn   3 points: s3*4 plus Rip for 8 secrn   4 points: s4*5 plus Rip for 10 secrn   5 points: s5*6 plus Rip for 12 sec
  SpellInfo(primal_wrath energy=20 combopoints=1 gcd=1 talent=primal_wrath_talent)
Define(prowl 5215)
# Activates Cat Form and places you into stealth until cancelled.
  SpellInfo(prowl cd=6 gcd=0 offgcd=1)
  # Stealthed.
  SpellAddBuff(prowl prowl=1)
  # Stealthed.
  SpellAddTargetDebuff(prowl prowl=1)
Define(pulverize 80313)
# A devastating blow that consumes s3 stacks of your Thrash on the target to deal s1 Physical damage, and reduces all damage you take by 158792s1 for 20 seconds.
  SpellInfo(pulverize talent=pulverize_talent)
Define(rake 1822)
# Rake the target for s1 Bleed damage and an additional 155722o1 Bleed damage over 15 seconds.?s48484[ Reduces the target's movement speed by 58180s1 for 12 seconds.][]?a231052[ rnrnWhile stealthed, Rake will also stun the target for 4 seconds, and deal s4 increased damage.][]rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
# Rank 2: While stealthed, Rake will also stun the target for 4 seconds, and deal 1822s4 increased damage.
  SpellInfo(rake energy=35 gcd=1 combopoints=-1)
  # Bleeding for w1 damage every t1 seconds.
  SpellAddTargetDebuff(rake rake_debuff=1)
Define(rake_debuff 155722)
# Rake the target for s1 Bleed damage and an additional 155722o1 Bleed damage over 15 seconds.?s48484[ Reduces the target's movement speed by 58180s1 for 12 seconds.][]?a231052[ rnrnWhile stealthed, Rake will also stun the target for 4 seconds, and deal s4 increased damage.][]rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(rake_debuff duration=15 gcd=0 offgcd=1 tick=3)
  # Bleeding for w1 damage every t1 seconds.
  SpellAddTargetDebuff(rake_debuff rake_debuff=1)
Define(regrowth 8936)
# Heals a friendly target for (120 of Spell Power) and another o2*<mult> over 12 seconds.?s231032[ Regrowth's initial heal has a 231032s1 increased chance for a critical effect.][]?s24858|s197625[ Usable while in Moonkin Form.][]?s33891[rnrn|C0033AA11Tree of Life: Instant cast.|R][]
  SpellInfo(regrowth duration=12 tick=2)
  # Heals w2 every t2 sec.
  SpellAddBuff(regrowth regrowth=1)
Define(rip 1079)
# Finishing move that causes Bleed damage over time. Lasts longer per combo point.rnrn   1 point  : o1*2 over 8 secrn   2 points: o1*3 over 12 secrn   3 points: o1*4 over 16 secrn   4 points: o1*5 over 20 secrn   5 points: o1*6 over 24 sec
  SpellInfo(rip energy=20 combopoints=1 duration=4 gcd=1 tick=2)
  # Bleeding for w1 damage every t1 sec.
  SpellAddTargetDebuff(rip rip=1)
Define(savage_roar 52610)
# Finishing move that increases damage by 62071s1 and energy regeneration rate by (25 of Spell Power) while in Cat Form. Lasts longer per combo point:rnrn   1 point  : 12 secondsrn   2 points: 18 secondsrn   3 points: 24 secondsrn   4 points: 30 secondsrn   5 points: 36 seconds
  SpellInfo(savage_roar energy=25 combopoints=1 duration=6 channel=6 gcd=1 tick=2 talent=savage_roar_talent)
  # Damage increased 62071s1 while in Cat Form.rnEnergy regeneration increased by 62071s3.
  SpellAddBuff(savage_roar savage_roar=1)
Define(scent_of_blood_buff 213888)
# Increases your movement speed by 213888s1 for 10 seconds when you kill a target that gives experience or honor.
  SpellInfo(scent_of_blood_buff duration=10 channel=10 gcd=0 offgcd=1)
  # Movement speed increased by s1.
  SpellAddBuff(scent_of_blood_buff scent_of_blood_buff=1)
Define(shadowmeld 58984)
# Activate to slip into the shadows, reducing the chance for enemies to detect your presence. Lasts until cancelled or upon moving. Any threat is restored versus enemies still in combat upon cancellation of this effect.
  SpellInfo(shadowmeld cd=120 channel=-0.001 gcd=0 offgcd=1)
  # Shadowmelded.
  SpellAddBuff(shadowmeld shadowmeld=1)
Define(shred 5221)
# Shred the target, causing s1*<mult> Physical damage to the target.?a231063[ Deals s4 increased damage against bleeding targets.][]?a231057[rnrnWhile stealthed, Shred deals m3 increased damage, and has double the chance to critically strike.][]?c2[rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r]?s202155[rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.][]
# Rank 2: Shred deals 5221s5 increased damage against bleeding targets.
  SpellInfo(shred energy=40 gcd=1 combopoints=0)
Define(skull_bash 106839)
# You charge and bash the target's skull, interrupting spellcasting and preventing any spell in that school from being cast for 4 seconds.
  SpellInfo(skull_bash cd=15 gcd=0 offgcd=1)
Define(solar_beam 78675)
# Summons a beam of solar light over an enemy target's location, interrupting the target and silencing all enemies within the beam.  Lasts 8 seconds.
  SpellInfo(solar_beam cd=60 duration=8 gcd=0 offgcd=1)

Define(solar_wrath 5176)
# Causes (57.75 of Spell Power) Nature damage to the target.
  SpellInfo(solar_wrath)
Define(solar_wrath_balance 190984)
# Hurl a ball of solar energy at the target, dealing (60 of Spell Power) Nature damage.?a197911[rnrn|cFFFFFFFFGenerates m2/10 Astral Power.|r][]
  SpellInfo(solar_wrath_balance lunarpower=0)
Define(starfall 191034)
# Calls down waves of falling stars at the targeted area, dealing 9*191037m1 Astral damage over 8 seconds.
  SpellInfo(starfall lunarpower=50 duration=8 channel=8)
  # Calling down falling stars at the targeted area.
  SpellAddBuff(starfall starfall=1)
Define(starlord 202345)
# Starsurge and Starfall grant you 279709s1 Haste for 20 seconds.rnrnStacks up to 279709u times. Gaining a stack does not refresh the duration.
  SpellInfo(starlord channel=0 gcd=0 offgcd=1 talent=starlord_talent)
  SpellAddBuff(starlord starlord=1)
Define(stellar_flare 202347)
# Burns the target for (12.5 of Spell Power) Astral damage, and then an additional o2 damage over 24 seconds.rnrn|cFFFFFFFFGenerates m3/10 Astral Power.|r
  SpellInfo(stellar_flare duration=24 lunarpower=-8 tick=2 talent=stellar_flare_talent)
  # Suffering w2 Astral damage every t2 sec.
  SpellAddTargetDebuff(stellar_flare stellar_flare=1)
Define(sunfire 93402)
# A quick beam of solar light burns the enemy for (20 of Spell Power) Nature damage and then an additional 164815o2 Nature damage over 12 seconds?s231050[ to the primary target and all enemies within 164815A2 yards][].?s137013[rnrn|cFFFFFFFFGenerates m3/10 Astral Power.|r][]
# Rank 2: Sunfire now applies its damage over time effect to all enemies within 164815A2 yards.
  SpellInfo(sunfire lunarpower=0)
Define(swipe 213764)
# Swipe nearby enemies, inflicting Physical damage. Damage varies by shapeshift form.
# Rank 2: Swipe deals 106785s2 increased damage against bleeding targets.
  SpellInfo(swipe gcd=1)
Define(thrash 106832)
# Thrash all nearby enemies, dealing immediate physical damage and periodic bleed damage. Damage varies by shapeshift form.
  SpellInfo(thrash gcd=0 offgcd=1)
Define(tigers_fury 5217)
# Instantly restores s2 Energy, and increases the damage of all your attacks by s1 for their full duration. Lasts 10 seconds.
# Rank 2: Tiger's Fury generates an additional s1 energy.
  SpellInfo(tigers_fury cd=30 duration=10 gcd=0 offgcd=1 energy=-20)
  # Attacks deal s1 additional damage for their full duration.
  SpellAddBuff(tigers_fury tigers_fury=1)
Define(typhoon 132469)
# Blasts targets within 61391a1 yards in front of you with a violent Typhoon, knocking them back and dazing them for 6 seconds. Usable in all shapeshift forms.
  SpellInfo(typhoon cd=30 talent=typhoon_talent)

Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp=1)
Define(warrior_of_elune 202425)
# Your next u Lunar Strikes are instant cast and generate s2 additional Astral Power.
  SpellInfo(warrior_of_elune cd=45 channel=-0.001 max_stacks=3 gcd=0 offgcd=1 talent=warrior_of_elune_talent)
  # Your Lunar Strikes are instant cast and generate s2 additional Astral Power.
  SpellAddBuff(warrior_of_elune warrior_of_elune=1)
Define(wild_charge 102401)
# Fly to a nearby ally's position.
  SpellInfo(wild_charge cd=15 duration=0.5 gcd=0 offgcd=1 talent=wild_charge_talent)
  # Flying to an ally's position.
  SpellAddBuff(wild_charge wild_charge=1)
Define(bloodtalons_talent 20) #21649
# Casting Regrowth or Entangling Roots causes your next two melee abilities to deal 145152s1 increased damage for their full duration.
Define(bristling_fur_talent 3) #22420
# Bristle your fur, causing you to generate Rage based on damage taken for 8 seconds.
Define(brutal_slash_talent 17) #21711
# Strikes all nearby enemies with a massive slash, inflicting s1 Physical damage.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
Define(feral_frenzy_talent 21) #21653
# Unleash a furious frenzy, clawing your target m2 times for 274838s1*m2 Physical damage and an additional m2*274838s3*6 seconds/274838t3 Bleed damage over 6 seconds.rnrn|cFFFFFFFFAwards s1 combo points.|r
Define(force_of_nature_talent 3) #22387
# Summons a stand of s1 Treants for 10 seconds which immediately taunt and attack enemies in the targeted area.rnrn|cFFFFFFFFGenerates m5/10 Astral Power.|r
Define(fury_of_elune_talent 20) #21193
# Calls down a beam of pure celestial energy that follows the enemy, dealing <dmg> Astral damage over 8 seconds to all nearby targets.rnrn|cFFFFFFFFGenerates m3/10/t3*8 seconds Astral Power over its duration.|r
Define(incarnation_chosen_of_elune_talent 15) #21702
# An improved Moonkin Form that increases the damage of all your spells by s1 and grants you s3 Haste.rnrnLasts 30 seconds. You may shapeshift in and out of this improved Moonkin Form for its duration.
Define(incarnation_guardian_of_ursoc_talent 15) #22388
# An improved Bear Form that reduces the cooldown on all melee damage abilities and Growl to 1.5 sec, causes Mangle to hit up to (25 of Spell Power) targets, and increases armor by (25 of Spell Power).rnrnLasts 30 seconds. You may freely shapeshift in and out of this improved Bear Form for its duration.
Define(incarnation_king_of_the_jungle_talent 15) #21704
# An improved Cat Form that allows the use of Prowl once while in combat, causes Shred and Rake to deal damage as if stealth were active, reduces the cost of all Cat Form abilities by (25 of Spell Power), and increases maximum Energy by (25 of Spell Power).rnrnLasts 30 seconds. You may shapeshift in and out of this improved Cat Form for its duration.
Define(lunar_beam_talent 20) #22427
# Summons a beam of lunar light at your location, dealing 204069s2*8 Arcane damage and healing you for 204069s1*8 over m1 sec.
Define(lunar_inspiration_talent 3) #22365
# Moonfire is now usable while in Cat Form, generates 1 combo point, deals damage based on attack power, and costs 30 energy.
Define(mighty_bash_talent 10) #21778
# Invokes the spirit of Ursoc to stun the target for 5 seconds. Usable in all shapeshift forms.
Define(new_moon_talent 21) #21655
# Deals m1 Arcane damage to the target and empowers New Moon to become Half Moon. rnrn|cFFFFFFFFGenerates m3/10 Astral Power.|r
Define(primal_wrath_talent 18) #22370
# Finishing move that deals instant damage and applies Rip to all enemies within A1 yards. Lasts longer per combo point.rnrn   1 point  : s1*2 plus Rip for 4 secrn   2 points: s1*3 plus Rip for 6 secrn   3 points: s3*4 plus Rip for 8 secrn   4 points: s4*5 plus Rip for 10 secrn   5 points: s5*6 plus Rip for 12 sec
Define(pulverize_talent 21) #22425
# A devastating blow that consumes s3 stacks of your Thrash on the target to deal s1 Physical damage, and reduces all damage you take by 158792s1 for 20 seconds.
Define(sabertooth_talent 2) #22364
# Ferocious Bite deals s1 increased damage and increases the duration of Rip on your target by s2 sec per combo point spent.
Define(savage_roar_talent 14) #18579
# Finishing move that increases damage by 62071s1 and energy regeneration rate by (25 of Spell Power) while in Cat Form. Lasts longer per combo point:rnrn   1 point  : 12 secondsrn   2 points: 18 secondsrn   3 points: 24 secondsrn   4 points: 30 secondsrn   5 points: 36 seconds
Define(scent_of_blood_talent 16) #21714
# Each enemy hit by Thrash reduces the cost of Swipe by s1 Energy for the next 6 seconds.
Define(starlord_talent 14) #21706
# Starsurge and Starfall grant you 279709s1 Haste for 20 seconds.rnrnStacks up to 279709u times. Gaining a stack does not refresh the duration.
Define(stellar_flare_talent 18) #22165
# Burns the target for (12.5 of Spell Power) Astral damage, and then an additional o2 damage over 24 seconds.rnrn|cFFFFFFFFGenerates m3/10 Astral Power.|r
Define(twin_moons_talent 17) #21712
# Moonfire deals s2 increased damage and also hits another nearby enemy within 279621A1 yds of the target.
Define(typhoon_talent 12) #18577
# Blasts targets within 61391a1 yards in front of you with a violent Typhoon, knocking them back and dazing them for 6 seconds. Usable in all shapeshift forms.
Define(warrior_of_elune_talent 2) #22386
# Your next u Lunar Strikes are instant cast and generate s2 additional Astral Power.
Define(wild_charge_talent 6) #18571
# Fly to a nearby ally's position.
Define(arcanic_pulsar_trait 287773)
Define(lively_spirit_trait 279642)
Define(streaking_stars_trait 272871)
Define(wild_fleshrending_trait 279527)
Define(layered_mane_trait 279552)
Define(power_of_the_moon_trait 273367)
    ]]
    code = code .. [[
Define(astralpower "lunarpower") # Astral Power is named LunarPower in Enum.PowerType

# Baseline spells common to all Druid specs

	SpellInfo(bear_form to_stance=druid_bear_form)
	SpellInfo(bear_form unusable=1 if_stance=druid_bear_form)

	SpellInfo(cat_form to_stance=druid_cat_form)
	SpellInfo(cat_form unusable=1 if_stance=druid_cat_form)
	SpellAddBuff(cat_form cat_form_buff=1)
Define(cat_form_buff 768)

	SpellInfo(dash cd=120)
	SpellInfo(dash gcd=0 offgcd=1 if_stance=druid_cat_form)
	SpellInfo(dash to_stance=druid_cat_form if_stance=!druid_cat_form)
Define(entangling_roots 339)
Define(growl 6795)
	SpellInfo(growl cd=8)
Define(hibernate 2637)

	SpellInfo(shred energy=40 combopoints=-1)
	SpellInfo(shred physical=1)

	SpellInfo(mangle rage=-8 cd=6 cd_haste=melee)

	SpellInfo(moonfire mana=6)
	SpellInfo(moonfire unusable=1 if_stance=druid_cat_form)
	SpellAddBuff(moonfire moonfire_debuff=1)
Define(moonfire_debuff 164812)
	SpellInfo(moonfire_debuff duration=16)

	SpellInfo(prowl cd=10 gcd=0 offgcd=1 to_stance=druid_cat_form)
    SpellRequire(prowl unusable 1=stealthed,1)
	SpellAddBuff(prowl prowl_buff=1)
Define(prowl_buff 5215)
Define(remove_corruption 2782)
Define(rebirth 20484) 

	SpellInfo(regrowth mana=14)
	SpellInfo(regrowth spellpower=120)
Define(revive 50769)
Define(soothe 2908)
	SpellInfo(soothe cd=10)
Define(travel_form 783)

# Feral and Guardian shared

	SpellInfo(skull_bash cd=15 gcd=0 offgcd=1 interrupt=1)
Define(survival_instincts 61336)
	SpellInfo(survival_instincts cd=120 gcd=0 offgcd=1)
Define(survival_instincts_buff 61336)
	SpellInfo(survival_instincts_buff duration=6)
Define(stampeding_roar 77761)
	SpellInfo(stampeding_roar cd=120)

# Balance and Restoration shared
 # Also Guardian
	SpellInfo(barkskin cd=60 gcd=0 offgcd=1 specialization=!feral)
Define(barkskin_buff 22812)
	SpellInfo(barkskin_buff duration=12)

	SpellInfo(innervate cd=180)
	SpellAddBuff(innervate innervate_buff=1)
Define(innervate_buff 29166)

# Shared talents
Define(tigers_dash_talent 4)
Define(soul_of_the_forest_talent 13)
Define(incarnation_talent 15)

# Shared talent spells
Define(tigers_dash 252216)
	SpellInfo(tigers_dash cd=45)
	SpellInfo(tigers_dash gcd=0 offgcd=1 if_stance=druid_cat_form)
	SpellInfo(tigers_dash to_stance=druid_cat_form if_stance=!druid_cat_form)
	SpellInfo(dash replaced_by=tigers_dash talent=tigers_dash_talent)
Define(renewal 108238)
	SpellInfo(renewal cd=120 gcd=0 offgcd=1 specialization=!guardian)

	SpellInfo(wild_charge cd=15 gcd=0 offgcd=1)
	SpellInfo(wild_charge replaced_by=wild_charge_bear if_stance=druid_bear_form)
	SpellInfo(wild_charge replaced_by=wild_charge_cat if_stance=druid_cat_form)
Define(wild_charge_bear 16979)
	SpellInfo(wild_charge_bear cd=15 stance=druid_bear_form)
Define(wild_charge_cat 49376)
	SpellInfo(wild_charge_cat cd=15 stance=druid_cat_form)
	

Define(mass_entanglement 102359)
	SpellInfo(mass_entanglement cd=30)

	SpellInfo(mighty_bash cd=50 interrupt=1)

	SpellInfo(typhoon cd=30 interrupt=1)


# Balance Affinity
Define(moonkin_form 197625)
	SpellInfo(moonkin_form to_stance=druid_moonkin_form)
	SpellInfo(moonkin_form unusable=1 if_stance=druid_moonkin_form)

Define(solar_wrath 190984)
Define(starsurge 197626)
	SpellInfo(starsurge cd=10 specialization=!balance)
Define(sunfire_debuff 164815)
    SpellAddTargetDebuff(sunfire sunfire_debuff=1)
    SpellInfo(sunfire_debuff duration=12)
    SpellInfo(sunfire_debuff add_duration=6 specialization=balance)

# Feral Affinity
	SpellInfo(ferocious_bite energy=25 max_energy=50 combopoints=1 max_combopoints=5)
	SpellInfo(ferocious_bite physical=1)

	SpellInfo(rip energy=30 combopoints=1 max_combopoints=5)
	SpellAddTargetDebuff(rip rip_debuff=1)
Define(rip_debuff 1079)

# Guardian Affinity
Define(frenzied_regeneration 22842)
	SpellInfo(frenzied_regeneration rage=10 cd=36 cd_haste=melee)
	SpellAddBuff(frenzied_regeneration frenzied_regeneration_buff=1)
	SpellRequire(frenzied_regeneration unusable 1=debuff,healing_immunity_debuff)
    SpellRequire(frenzied_regeneration unusable 1=stance,!druid_bear_form)
Define(frenzied_regeneration_buff 22842)
	SpellInfo(frenzied_regeneration_buff duration=3)

	SpellInfo(ironfur rage=45 cd=0.5 offgcd=1)
	SpellAddBuff(ironfur ironfur_buff=1)
Define(ironfur_buff 192081)
	SpellInfo(ironfur_buff duration=7)
	SpellRequire(ironfur_buff add_duration 2=buff,guardian_of_elune_buff)
Define(thrash_bear 77758)
	SpellInfo(thrash_bear rage=-5 cd=6 cd_haste=melee)
	SpellAddTargetDebuff(thrash_bear thrash_bear_debuff=1)
Define(thrash_bear_debuff 192090)
	SpellInfo(thrash_bear_debuff duration=15 max_stacks=3 tick=3)

# Restoration Affinity
Define(healing_touch 5185)
	SpellInfo(healing_touch mana=9)
Define(rejuvenation 774)
	SpellInfo(rejuvenation mana=11)
	SpellAddTargetBuff(rejuvenation rejuvenation_buff=1)
Define(rejuvenation_buff 774)
	SpellInfo(rejuvenation_buff duration=12)
Define(swiftmend 18562)
	SpellInfo(swiftmend mana=14 cd=25)
]]
    OvaleScripts:RegisterScript("DRUID", nil, name, desc, code, "include")
end

local registerSpec1 = function()
    local name = "ovale_druid_balance_spells"
    local desc = "[8.1] Ovale: Druid Balance spells"
    local code = [[
# NOT fully updated for 8.0
# Balance spells

	SpellInfo(celestial_alignment cd=180 shared_cd=celestial_alignment_cd)
	SpellInfo(celestial_alignment replaced_by=incarnation_chosen_of_elune talent=incarnation_talent specialization=balance)
	SpellAddBuff(celestial_alignment celestial_alignment_buff=1)
    
Define(celestial_alignment_buff 194223)

	SpellInfo(fury_of_elune cd=90 astralpower=6)
	SpellAddBuff(fury_of_elune fury_of_elune_up_buff=1)
Define(fury_of_elune_up_buff 202770)
	#TODO 12 astralpower per s
	
	SpellInfo(full_moon cd=15 charges=3 astralpower=-40 shared_cd=new_moon)

	SpellInfo(half_moon cd=15 charges=3 astralpower=-20 shared_cd=new_moon)

	SpellInfo(incarnation replaced_by=incarnation_chosen_of_elune specialization=balance)
	SpellInfo(incarnation_chosen_of_elune cd=180 shared_cd=celestial_alignment_cd)
	SpellInfo(incarnation_chosen_of_elune unusable=1)
	SpellInfo(incarnation_chosen_of_elune unusable=0 talent=incarnation_talent)
	SpellAddBuff(incarnation_chosen_of_elune incarnation_chosen_of_elune_buff=1)
Define(incarnation_chosen_of_elune_buff 102560)
	SpellInfo(incarnation_chosen_of_elune_buff duration=30)

	SpellInfo(lunar_beam cd=90)
Define(lunar_empowerment_buff 164547)
    SpellRequire(lunar_strike astralpower_percent 140=buff,warrior_of_elune)
	SpellAddBuff(lunar_strike lunar_empowerment_buff=0)
    SpellAddBuff(lunar_strike warrior_of_elune=-1)

	SpellInfo(moonfire astralpower=-3 specialization=balance)

	SpellInfo(moonfire_debuff add_duration=6 specialization=balance)
Define(moonkin_form_balance 24858)
	SpellInfo(moonkin_form replaced_by=moonkin_form_balance specialization=balance)
	SpellInfo(moonkin_form_balance to_stance=druid_moonkin_form)
	SpellInfo(moonkin_form_balance unusable=1 if_stance=druid_moonkin_form)
	#TODO affinity moonkin form has a different spellId

	SpellInfo(new_moon cd=15 charges=3 astralpower=-10)
Define(solar_empowerment_buff 164545)

	SpellInfo(solar_beam cd=60 gcd=0 offgcd=1 interrupt=1)

	SpellInfo(solar_wrath travel_time=1 astralpower=-8)
	SpellAddBuff(solar_wrath solar_empowerment_buff=-1)

	SpellInfo(starfall astralpower=60)
	SpellInfo(starfall astralpower=40 talent=soul_of_the_forest_talent)
	SpellAddBuff(starfall starfall_buff=1)
	SpellAddTargetDebuff(starfall stellar_empowerment_debuff=1)
Define(starfall_buff 191034)
	SpellInfo(starfall_buff duration=8)
Define(starlord_buff 279709)
Define(starsurge 197626)
Define(starsurge_balance 78674)
	SpellInfo(starsurge_balance astralpower=40)
	SpellAddBuff(starsurge_balance lunar_empowerment_buff=1)
	SpellAddBuff(starsurge_balance solar_empowerment_buff=1)
Define(stellar_empowerment_debuff 197637)

	SpellInfo(stellar_flare astralpower=15)
	SpellAddTargetDebuff(stellar_flare stellar_flare_debuff=1)
Define(stellar_flare_debuff 202347)
	SpellInfo(stellar_flare_debuff duration=24 haste=spell tick=2)

    SpellRequire(warrior_of_elune unusable 1=buff,warrior_of_elune_buff)
Define(warrior_of_elune_buff 202425)
    
Define(ca_inc 194223)
SpellList(ca_inc_buff celestial_alignment_buff incarnation_chosen_of_elune_buff)	

# Balance Legendaries
Define(oneths_intuition_buff 209406)
Define(oneths_overconfidence_buff 209407)
	SpellRequire(starfall astralpower_percent 0=buff,oneths_overconfidence_buff)
	SpellAddBuff(starfall oneths_overconfidence_buff=-1)
	]]
    OvaleScripts:RegisterScript("DRUID", nil, name, desc, code, "include")
end

local registerSpec2 = function()
    local name = "ovale_druid_guardian_spells"
    local desc = "[8.1] Ovale: Druid Guardian spells"
    local code = [[
	Include(ovale_druid_base_spells)
# NOT updated for 8.0
# Guardian spells
	SpellInfo(barkskin add_cd=30 specialization=guardian talent=!survival_of_the_fittest_talent)

	SpellInfo(bristling_fur cd=40 gcd=0 offgcd=1)
	SpellAddBuff(bristling_fur bristling_fur_buff=1)
Define(bristling_fur_buff 155835)
	SpellInfo(bristling_fur_buff duration=8)
Define(earthwarden_buff 203975)
    SpellInfo(earthwarden_buff max_stacks=3)

	SpellInfo(frenzied_regeneration charges=2 specialization=guardian)
	SpellAddBuff(frenzied_regeneration guardian_of_elune_buff=0)

Define(galactic_guardian_buff 213708)
Define(guardian_of_elune_buff 213680)
	SpellInfo(guardian_of_elune_buff duration=15)
Define(guardians_wrath_buff 279541)

	SpellInfo(incapacitating_roar cd=30)
	SpellInfo(incapacitating_roar replaced_by=intimidating_roar talent=intimidating_roar_talent)

	SpellInfo(incarnation replaced_by=incarnation_guardian_of_ursoc specialization=guardian)
	SpellInfo(incarnation_guardian_of_ursoc cd=180 unusable=1)
	SpellInfo(incarnation_guardian_of_ursoc unusable=0 talent=incarnation_talent specialization=guardian)
	SpellAddBuff(incarnation_guardian_of_ursoc incarnation_guardian_of_ursoc_buff=1)
Define(incarnation_guardian_of_ursoc_buff 102558)
	SpellInfo(incarnation_guardian_of_ursoc_buff duration=30)
Define(intimidating_roar 236748)
	SpellInfo(intimidating_roar cd=30)

	SpellAddBuff(ironfur guardian_of_elune_buff=0)
	SpellRequire(ironfur add_rage_from_aura -15=buff,guardians_wrath_buff)

	SpellInfo(mangle addrage=-4 talent=soul_of_the_forest_talent specialization=guardian)
	SpellAddBuff(mangle guardian_of_elune_buff=1 talent=guardian_of_elune_talent)

	SpellInfo(maul rage=45 stance=druid_bear_form)

	SpellRequire(pulverize unusable 1=target_debuff,!thrash_bear_debuff,2)
	SpellAddBuff(pulverize pulverize_buff=1)
	SpellAddTargetDebuff(pulverize thrash_bear_debuff=-2)
Define(pulverize_buff 158792)
	SpellInfo(pulverize_buff duration=20)

	SpellInfo(survival_instincts add_cd=120 specialization=guardian)
	SpellInfo(survival_instincts add_cd=-80 specialization=guardian talent=survival_of_the_fittest_talent) 

	SpellInfo(thrash_bear_debuff max_stacks=5 if_equipped=elizes_everlasting_encasement)

# Guardian Legendaries
Define(elizes_everlasting_encasement 137067)
Define(skysecs_hold 137025)

# Guardian Talents
Define(earthwarden_talent 16)
Define(intimidating_roar_talent 5)
Define(galactic_guardian_talent 14)
Define(survival_of_the_fittest_talent 17)
Define(guardian_of_elune_talent 18)
	]]
    OvaleScripts:RegisterScript("DRUID", nil, name, desc, code, "include")
end

local registerSpec3 = function()
    local name = "ovale_druid_feral_spells"
    local desc = "[8.1] Ovale: Druid Feral spells"
    local code = [[
Include(ovale_druid_base_spells)

# Constants
Define(berserk_percent_value 60)
Define(bloodtalons_value 1.25)
Define(tigers_fury_buff_value 1.15)

# Feral spells

	SpellInfo(berserk cd=180)
	SpellInfo(berserk replaced_by=incarnation_king_of_the_jungle talent=incarnation_talent specialization=feral)
	SpellAddBuff(berserk berserk_buff=1)
Define(berserk_buff 106951)
	SpellInfo(berserk_buff duration=15)

	SpellInfo(incarnation replaced_by=incarnation_king_of_the_jungle specialization=feral)
	SpellInfo(incarnation_king_of_the_jungle cd=180)
	SpellAddBuff(incarnation_king_of_the_jungle incarnation_king_of_the_jungle_buff=1)
	SpellAddBuff(incarnation_king_of_the_jungle jungle_stalker_buff=1)
Define(incarnation_king_of_the_jungle_buff 102543)
	SpellInfo(incarnation_king_of_the_jungle_buff duration=30)
Define(jungle_stalker_buff 252071)
SpellList(berserk_spell_list berserk_buff incarnation_king_of_the_jungle_buff)
	SpellRequire(feral_frenzy energy_percent berserk_percent_value=buff,berserk_spell_list)
	SpellRequire(shred energy_percent berserk_percent_value=buff,berserk_spell_list)
	SpellRequire(swipe_cat energy_percent berserk_percent_value=buff,berserk_spell_list)
	SpellRequire(brutal_slash energy_percent berserk_percent_value=buff,berserk_spell_list)
	SpellRequire(thrash_cat energy_percent berserk_percent_value=buff,berserk_spell_list)
	SpellRequire(rake energy_percent berserk_percent_value=buff,berserk_spell_list)
	SpellRequire(rip energy_percent berserk_percent_value=buff,berserk_spell_list)
	SpellRequire(ferocious_bite energy_percent berserk_percent_value=buff,berserk_spell_list)
	SpellRequire(maim energy_percent berserk_percent_value=buff,berserk_spell_list)
	SpellRequire(savage_roar energy_percent berserk_percent_value=buff,berserk_spell_list)
Define(bloodtalons_buff 145152)
	SpellInfo(bloodtalons_buff duration=30 max_stacks=2)
	SpellAddBuff(regrowth bloodtalons_buff=2 talent=bloodtalons_talent specialization=feral)
	SpellAddBuff(shred bloodtalons_buff=-1 talent=bloodtalons_talent)
	SpellAddBuff(thrash_cat bloodtalons_buff=-1 talent=bloodtalons_talent)
	SpellAddBuff(shred bloodtalons_buff=-1 talent=bloodtalons_talent)
	SpellAddBuff(brutal_slash bloodtalons_buff=-1 talent=bloodtalons_talent)
	SpellAddBuff(maim bloodtalons_buff=-1 talent=bloodtalons_talent)
	SpellAddBuff(rip bloodtalons_buff=-1 talent=bloodtalons_talent)
	SpellAddBuff(ferocious_bite bloodtalons_buff=-1 talent=bloodtalons_talent)
	SpellAddBuff(rake bloodtalons_buff=-1 talent=bloodtalons_talent)	 
	SpellDamageBuff(rip bloodtalons_buff=bloodtalons_value talent=bloodtalons_talent)
	SpellDamageBuff(rip_debuff bloodtalons_buff=bloodtalons_value talent=bloodtalons_talent)
	SpellDamageBuff(rake bloodtalons_buff=bloodtalons_value talent=bloodtalons_talent)	
	SpellDamageBuff(rake_debuff bloodtalons_buff=bloodtalons_value talent=bloodtalons_talent)	
	SpellDamageBuff(thrash_cat bloodtalons_buff=bloodtalons_value talent=bloodtalons_talent)
	SpellDamageBuff(thrash_cat_debuff bloodtalons_buff=bloodtalons_value talent=bloodtalons_talent)

	SpellInfo(brutal_slash energy=30 combopoints=-1 cd=8 cd_haste=melee charges=3)
	SpellInfo(brutal_slash physical=1)
Define(omen_of_clarity 16864)
Define(clearcasting 135700)
Define(clearcasting_buff 135700)
	SpellInfo(clearcasting_buff duration=15)
	SpellRequire(shred energy_percent 0=buff,clearcasting_buff if_spell=omen_of_clarity)
	SpellRequire(swipe_cat energy_percent 0=buff,clearcasting_buff if_spell=omen_of_clarity)
	SpellRequire(brutal_slash energy_percent 0=buff,clearcasting_buff if_spell=omen_of_clarity)
	SpellRequire(thrash_cat energy_percent 0=buff,clearcasting_buff if_spell=omen_of_clarity)

	SpellInfo(feral_frenzy energy=25 combopoints=-5 cd=45)
#
	SpellAddTargetDebuff(ferocious_bite rip_debuff=refresh_keep_snapshot,target_health_pct,25)
	SpellAddTargetDebuff(ferocious_bite rip_debuff=refresh_keep_snapshot talent=sabertooth_talent)

	SpellInfo(maim energy=35 combopoints=1 max_combopoints=5 cd=20)
Define(moonfire_cat 155625)
	SpellInfo(moonfire_cat energy=30 combopoints=-1 unusable=1)
	SpellInfo(moonfire_cat unusable=0 if_stance=druid_cat_form specialization=feral talent=lunar_inspiration_talent)
	SpellAddTargetDebuff(moonfire_cat moonfire_cat_debuff=1)
Define(moonfire_cat_debuff 155625)
	SpellInfo(moonfire_cat_debuff duration=14 haste=melee tick=2 specialization=feral talent=lunar_inspiration_talent)
Define(predatory_swiftness_buff 69369)
	SpellInfo(predatory_swiftness_buff duration=12)
SpellList(improved_rake prowl_buff shadowmeld_buff incarnation_king_of_the_jungle_buff)

	SpellInfo(rake energy=35 combopoints=-1)
	SpellAddBuff(rake prowl_buff=0)
	SpellAddBuff(rake shadowmeld_buff=0)
	SpellDamageBuff(rake improved_rake=2)

	SpellInfo(rake_debuff duration=15 haste=melee tick=3 talent=!jagged_wounds_talent)
	SpellInfo(rake_debuff duration=12 haste=melee tick=2.4 talent=jagged_wounds_talent)
	SpellDamageBuff(rake_debuff improved_rake=2)

	SpellInfo(rip_debuff duration=24 haste=melee tick=2 talent=!jagged_wounds_talent)
	SpellInfo(rip_debuff duration=19.2 haste=melee tick=1.6 talent=jagged_wounds_talent)

	SpellInfo(savage_roar energy=30 combopoints=1 max_combopoints=5)
	SpellAddBuff(savage_roar savage_roar_buff=1)
Define(savage_roar_buff 52610)
	SpellInfo(savage_roar_buff duration=6 add_durationcp=6)
Define(swipe_cat 106785) 
	SpellInfo(swipe_cat energy=40 combopoints=-1)
Define(thrash_cat 106830)
	SpellInfo(thrash_cat energy=45 combopoints=-1)
	SpellAddTargetDebuff(thrash_cat thrash_cat_debuff=1)
Define(thrash_cat_debuff 106830)

	SpellInfo(tigers_fury energy=-50 cd=30 gcd=0 offgcd=1)
	SpellAddBuff(tigers_fury tigers_fury_buff=1)
Define(tigers_fury_buff 5217)
	SpellInfo(tigers_fury duration=10)
	SpellDamageBuff(thrash_cat tigers_fury_buff=tigers_fury_buff_value if_spell=tigers_fury)
	SpellDamageBuff(thrash_cat_debuff tigers_fury_buff=tigers_fury_buff_value if_spell=tigers_fury)
	SpellDamageBuff(moonfire_cat tigers_fury_buff=tigers_fury_buff_value if_spell=tigers_fury)
	SpellDamageBuff(moonfire_cat_debuff tigers_fury_buff=tigers_fury_buff_value if_spell=tigers_fury)
	SpellDamageBuff(rake tigers_fury_buff=tigers_fury_buff_value if_spell=tigers_fury)
	SpellDamageBuff(rake_debuff tigers_fury_buff=tigers_fury_buff_value if_spell=tigers_fury)
	SpellDamageBuff(rip tigers_fury_buff=tigers_fury_buff_value if_spell=tigers_fury)
	SpellDamageBuff(rip_debuff tigers_fury_buff=tigers_fury_buff_value if_spell=tigers_fury)

# Talents

Define(jagged_wounds_talent 14)
Define(incarnation_king_of_the_jungle_talent 15)

# Tier 21
Define(apex_predator_buff 252752)
SpellRequire(ferocious_bite energy_percent 0=buff,apex_predator_buff)
SpellRequire(ferocious_bite refund_combopoints cost=buff,apex_predator_buff)

# Legendaries
Define(luffa_wrappings 137056)
	]]
    OvaleScripts:RegisterScript("DRUID", nil, name, desc, code, "include")
end

__exports.register = function()
    registerBase()
    registerSpec1()
    registerSpec2()
    registerSpec3()
    local name = "ovale_druid_spells"
    local desc = "[8.1] Ovale: Druid spells"
    local code = [[
Include(ovale_druid_base_spells)
Include(ovale_druid_balance_spells)
Include(ovale_druid_guardian_spells)
Include(ovale_druid_feral_spells)
]]
    OvaleScripts:RegisterScript("DRUID", nil, name, desc, code, "include")
end
