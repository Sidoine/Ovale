local __exports = LibStub:NewLibrary("ovale/scripts/ovale_druid_spells", 80000)
if not __exports then return end
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
local registerBase = function()
    local name = "ovale_druid_base_spells"
    local desc = "[8.0] Ovale: Druid baseline spells"
    local code = [[Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you their power for 274739d.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
Define(barkskin 22812)
# Your skin becomes as tough as bark, reducing all damage you take by s2 and preventing damage from delaying your spellcasts. Lasts d.rnrnUsable while stunned, frozen, incapacitated, feared, or asleep, and in all shapeshift forms.
  SpellInfo(barkskin cd=60 duration=12 gcd=0 offgcd=1 tick=1)
  # All damage taken reduced by s2.
  SpellAddBuff(barkskin barkskin=1)
Define(battle_potion_of_agility 279161)
# Chance to create multiple potions.
  SpellInfo(battle_potion_of_agility gcd=0 offgcd=1)
Define(bear_form 270100)
# Bear Form gives an additional s1 Stamina.rn
  SpellInfo(bear_form channel=0 gcd=0 offgcd=1)
  SpellAddBuff(bear_form bear_form=1)
Define(berserk 279526)
# Reduces the energy cost of all Cat Form abilities by s1 and increases maximum Energy by s3 for d.
  SpellInfo(berserk cd=180 duration=5 gcd=1)
  # Reduces the energy cost of all Cat Form abilities by s1 and increases maximum Energy by s3.
  SpellAddBuff(berserk berserk=1)
Define(berserking 26297)
# Increases your haste by s1 for d.
  SpellInfo(berserking cd=180 duration=10 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking=1)
Define(blood_fury 33702)
# Increases your Intellect by s1 for d.
  SpellInfo(blood_fury cd=120 duration=15 gcd=0 offgcd=1)
  # Intellect increased by w1.
  SpellAddBuff(blood_fury blood_fury=1)
Define(bristling_fur 155835)
# Bristle your fur, causing you to generate Rage based on damage taken for d.
  SpellInfo(bristling_fur cd=40 duration=8 talent=bristling_fur_talent)
  # Generating Rage from taking damage.
  SpellAddBuff(bristling_fur bristling_fur=1)
Define(brutal_slash 202028)
# Strikes all nearby enemies with a massive slash, inflicting s1 Physical damage.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
  SpellInfo(brutal_slash energy=30 cd=8 talent=brutal_slash_talent gcd=1)
Define(cat_form 768)
# Shapeshift into Cat Form, increasing auto-attack damage by s3, movement speed by 113636s1, granting protection from Polymorph effects, and reducing falling damage.rnrnThe act of shapeshifting frees you from movement impairing effects.
  SpellInfo(cat_form)
  # Autoattack damage increased by w3.rnImmune to Polymorph effects.rnMovement speed increased by 113636s1 and falling damage reduced.
  SpellAddBuff(cat_form cat_form=1)
Define(celestial_alignment 194223)
# Celestial bodies align, increasing the damage of all your spells by s1 and granting you s3 Haste for d.
  SpellInfo(celestial_alignment cd=180 duration=20)
  # Spell damage increased by s1.rnHaste increased by s3.
  SpellAddBuff(celestial_alignment celestial_alignment=1)
Define(dash 61684)
# Increases your pet's movement speed by s1 for d.
  SpellInfo(dash cd=20 duration=10 gcd=0 offgcd=1)
  # Increases movement speed by s1.
  SpellAddBuff(dash dash=1)
Define(feral_frenzy 274838)
# @spelldesc274837
  SpellInfo(feral_frenzy duration=6 gcd=0 offgcd=1 combo_points=-1 tick=2)
  # Bleeding for w2 damage every t2 sec.
  SpellAddTargetDebuff(feral_frenzy feral_frenzy=1)
Define(ferocious_bite 231056)
# When used on a target below 25 health, Ferocious Bite will refresh the duration of your Rip on your target.
  SpellInfo(ferocious_bite channel=0 gcd=0 offgcd=1)
  SpellAddBuff(ferocious_bite ferocious_bite=1)
Define(fireblood 265226)
# Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by s1.
  SpellInfo(fireblood duration=8 max_stacks=6 gcd=0 offgcd=1)
  # Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by w1.
  SpellAddBuff(fireblood fireblood=1)
Define(force_of_nature 205636)
# Summons a stand of s1 Treants for 248280d which immediately taunt and attack enemies in the targeted area.rnrn|cFFFFFFFFGenerates m5/10 Astral Power.|r
  SpellInfo(force_of_nature cd=60 talent=force_of_nature_talent astral_power=-20)
Define(full_moon 274283)
# Deals m1 Arcane damage to the target and reduced damage to all other nearby enemies, and resets Full Moon to become New Moon.rnrn|cFFFFFFFFGenerates m2/10 Astral Power.|r
  SpellInfo(full_moon cd=25 astral_power=-40)
Define(fury_of_elune 211547)
# @spelldesc202770
  SpellInfo(fury_of_elune cd=0.5 gcd=0 offgcd=1)
Define(half_moon 274282)
# Deals m1 Arcane damage to the target and empowers Half Moon to become Full Moon.rnrn|cFFFFFFFFGenerates m3/10 Astral Power.|r
  SpellInfo(half_moon cd=25 astral_power=-20)
Define(incarnation 117679)
# Activates a superior shapeshifting form appropriate to your specialization for d.  You may freely shapeshift in and out of this form for its duration.
  SpellInfo(incarnation duration=30 gcd=0 offgcd=1)
  # Incarnation: Tree of Life activated.
  SpellAddBuff(incarnation incarnation=1)
Define(innervate 29166)
# Infuse a friendly healer with energy, allowing them to cast spells without spending mana for d.
  SpellInfo(innervate cd=180 duration=12)
  # Your spells cost no mana.
  SpellAddBuff(innervate innervate=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)
Define(lively_spirit_buff 279646)
# @spelldesc279642
  SpellInfo(lively_spirit_buff channel=-0.001 gcd=0 offgcd=1)
Define(lunar_beam 204069)
# @spelldesc204066
  SpellInfo(lunar_beam gcd=0 offgcd=1)
Define(lunar_strike 197628)
# Call down a strike of lunar energy, causing s1 Arcane damage to the target, and m1*m2/100 Arcane damage to all other enemies within A1 yards.
  SpellInfo(lunar_strike)
Define(mangle 231064)
# Mangle deals 33917s3 additional damage against bleeding targets.
  SpellInfo(mangle channel=0 gcd=0 offgcd=1)
  SpellAddBuff(mangle mangle=1)
Define(maul 6807)
# Maul the target for s2 Physical damage.
  SpellInfo(maul rage=45)
Define(moonfire 164812)
# @spelldesc8921
  SpellInfo(moonfire duration=16 gcd=0 offgcd=1 tick=2)
  # Suffering w2 Arcane damage every t2 seconds.
  SpellAddTargetDebuff(moonfire moonfire=1)
Define(moonkin_form 231042)
# While in Moonkin Form, single-target attacks against you have a s1 chance make your next Lunar Strike instant.rn
  SpellInfo(moonkin_form channel=0 gcd=0 offgcd=1)
  SpellAddBuff(moonkin_form moonkin_form=1)
Define(new_moon 274281)
# Deals m1 Arcane damage to the target and empowers New Moon to become Half Moon. rnrn|cFFFFFFFFGenerates m3/10 Astral Power.|r
  SpellInfo(new_moon cd=25 talent=new_moon_talent gcd=1 astral_power=-10)
Define(prolonged_power 229220)
# Chance to create more than s1 potions.
  SpellInfo(prolonged_power gcd=0 offgcd=1)
Define(rising_death 269853)
# Empowers you with shadow magic for d, giving your ranged attacks a chance to send out a death bolt that grows in intensity as it travels, dealing up to 271292s1 Shadow damage.
  SpellInfo(rising_death duration=25 channel=25 gcd=0 offgcd=1)
Define(old_war 188330)
# Chance to create multiple potions.
  SpellInfo(old_war gcd=0 offgcd=1)
Define(prowl 102547)
# Allows the Druid to vanish from sight, entering an improved stealth mode.  Lasts until cancelled.
  SpellInfo(prowl cd=6 gcd=0 offgcd=1)
  # Stealthed.
  SpellAddBuff(prowl prowl=1)
Define(pulverize 158792)
# @spelldesc80313
  SpellInfo(pulverize duration=20 gcd=0 offgcd=1 tick=2)
  # Damage taken reduced by s4.
  SpellAddBuff(pulverize pulverize=1)
Define(rake 231052)
# While stealthed, Rake will also stun the target for 163505d, and deal 1822s4 increased damage.
  SpellInfo(rake channel=0 gcd=0 offgcd=1)
  SpellAddBuff(rake rake=1)
Define(rake_debuff 155722)
# @spelldesc1822
  SpellInfo(rake_debuff duration=15 gcd=0 offgcd=1 tick=3)
  # Bleeding for w1 damage every t1 seconds.
  SpellAddTargetDebuff(rake_debuff rake_debuff=1)
Define(regrowth 8936)
# Heals a friendly target for s1 and another o2*<mult> over d.?s231032[ Regrowth's initial heal has a 231032s1 increased chance for a critical effect.][]?s24858|s197625[ Usable while in Moonkin Form.][]?s33891[rnrn|C0033AA11Tree of Life: Instant cast.|R][]
  SpellInfo(regrowth duration=12 tick=2)
  # Heals w2 every t2 seconds.
  SpellAddBuff(regrowth regrowth=1)
Define(rip 1079)
# Finishing move that causes Bleed damage over d. Damage increases per combo point:rnrn   1 point : floor(1*<rip>*12) damagern   2 points: floor(2*<rip>*12) damagern   3 points: floor(3*<rip>*12) damagern   4 points: floor(4*<rip>*12) damagern   5 points: floor(5*<rip>*12) damage
  SpellInfo(rip energy=30 combo_points=1 duration=24 gcd=1 tick=2)
  # Bleeding for w1 damage every t1 sec.
  SpellAddTargetDebuff(rip rip=1)
Define(savage_roar 62071)
# @spelldesc52610
  SpellInfo(savage_roar gcd=0 offgcd=1)
  # Damage increased w1.
  SpellAddBuff(savage_roar savage_roar=1)
Define(shadowmeld 58984)
# Activate to slip into the shadows, reducing the chance for enemies to detect your presence. Lasts until cancelled or upon moving. Any threat is restored versus enemies still in combat upon cancellation of this effect.
  SpellInfo(shadowmeld cd=120 channel=-0.001 gcd=0 offgcd=1)
  # Shadowmelded.
  SpellAddBuff(shadowmeld shadowmeld=1)
Define(shred 231063)
# Shred deals 5221s5 increased damage against bleeding targets.
  SpellInfo(shred channel=0 gcd=0 offgcd=1)
  SpellAddBuff(shred shred=1)
Define(solar_wrath 197629)
# Causes s1 Nature damage to the target.
  SpellInfo(solar_wrath)
Define(starfall 191037)
# @spelldesc191034
  SpellInfo(starfall channel=0 gcd=0 offgcd=1)
Define(starsurge 231021)
# The Lunar and Solar Empowerments granted by Starsurge now stack up to s1+1 times.
  SpellInfo(starsurge channel=0 gcd=0 offgcd=1)
  SpellAddBuff(starsurge starsurge=1)
Define(stellar_flare 202347)
# Burns the target for s1 Astral damage, and then an additional o2 damage over d.rnrn|cFFFFFFFFGenerates m3/10 Astral Power.|r
  SpellInfo(stellar_flare duration=24 talent=stellar_flare_talent astral_power=-8 tick=2)
  # Suffering w2 Astral damage every t2 sec.
  SpellAddTargetDebuff(stellar_flare stellar_flare=1)
Define(sunfire 231050)
# Sunfire now applies its damage over time effect to all enemies within 164815A2 yards.
  SpellInfo(sunfire channel=0 gcd=0 offgcd=1)
  SpellAddBuff(sunfire sunfire=1)
Define(swipe 231283)
# Swipe deals 106785s2 increased damage against bleeding targets.
  SpellInfo(swipe channel=0 gcd=0 offgcd=1)
  SpellAddBuff(swipe swipe=1)
Define(the_emerald_dreamcatcher_buff 224706)
# Reduces the Astral Power cost of Starsurge by s1/-10. Stacks up to u times.
  SpellInfo(the_emerald_dreamcatcher_buff duration=5 max_stacks=2 gcd=0 offgcd=1)
  # Reduces the Astral Power cost of Starsurge by s1/-10.
  SpellAddBuff(the_emerald_dreamcatcher_buff the_emerald_dreamcatcher_buff=1)
Define(thrash 211141)
# @spelldesc106830
  SpellInfo(thrash channel=0 max_stacks=3 gcd=0 offgcd=1 combo_points=-1)
Define(tigers_fury 231055)
# Tiger's Fury generates an additional s1 energy.
  SpellInfo(tigers_fury channel=0 gcd=0 offgcd=1)
  SpellAddBuff(tigers_fury tigers_fury=1)
Define(warrior_of_elune 202425)
# Your next u Lunar Strikes are instant cast and generate s2 additional Astral Power.
  SpellInfo(warrior_of_elune cd=45 channel=-0.001 max_stacks=3 talent=warrior_of_elune_talent gcd=0 offgcd=1)
  # Your Lunar Strikes are instant cast and generate s2 additional Astral Power.
  SpellAddBuff(warrior_of_elune warrior_of_elune=1)
Define(wild_charge 102401)
# Fly to a nearby ally's position.
  SpellInfo(wild_charge cd=15 duration=0.5 talent=wild_charge_talent gcd=0.5)
  # Flying to an ally's position.
  SpellAddBuff(wild_charge wild_charge=1)
Define(bloodtalons_talent 20)
# Casting Regrowth or Entangling Roots causes your next two melee abilities to deal 145152s1 increased damage for their full duration.
Define(brutal_slash_talent 17)
# Strikes all nearby enemies with a massive slash, inflicting s1 Physical damage.rnrn|cFFFFFFFFAwards s2 combo lpoint:points;.|r
Define(lunar_inspiration_talent 3)
# Moonfire is now usable while in Cat Form, generates 1 combo point, deals damage based on attack power, and costs 30 energy.
Define(moment_of_clarity_talent 19)
# Omen of Clarity now triggers s2 more often, can accumulate up to s135700u+s1 charges, and increases the damage of your next Shred, Thrash, or ?s202028[Brutal Slash][Swipe] by s4.rnrnYour maximum Energy is increased by s3.
Define(sabertooth_talent 16)
# Ferocious Bite deals s1 increased damage and always refreshes the duration of Rip.
Define(bristling_fur_talent 3)
# Bristle your fur, causing you to generate Rage based on damage taken for d.
Define(force_of_nature_talent 3)
# Summons a stand of s1 Treants for 248280d which immediately taunt and attack enemies in the targeted area.rnrn|cFFFFFFFFGenerates m5/10 Astral Power.|r
Define(new_moon_talent 21)
# Deals m1 Arcane damage to the target and empowers New Moon to become Half Moon. rnrn|cFFFFFFFFGenerates m3/10 Astral Power.|r
Define(stellar_flare_talent 18)
# Burns the target for s1 Astral damage, and then an additional o2 damage over d.rnrn|cFFFFFFFFGenerates m3/10 Astral Power.|r
Define(warrior_of_elune_talent 2)
# Your next u Lunar Strikes are instant cast and generate s2 additional Astral Power.
Define(wild_charge_talent 6)
# Fly to a nearby ally's position.
Define(the_emerald_dreamcatcher_item 137062)
Define(ailuro_pouncers_item 137024)
Define(luffa_wrappings_item 137056)
Define(lively_spirit_trait 279642)
    ]]
    code = code .. [[
Define(astralpower "lunarpower") # Astral Power is named LunarPower in Enum.PowerType

# Baseline spells common to all Druid specs
Define(bear_form 5487)
	SpellInfo(bear_form to_stance=druid_bear_form)
	SpellInfo(bear_form unusable=1 if_stance=druid_bear_form)

	SpellInfo(cat_form to_stance=druid_cat_form)
	SpellInfo(cat_form unusable=1 if_stance=druid_cat_form)
	SpellAddBuff(cat_form cat_form_buff=1)
Define(cat_form_buff 768)
Define(dash 1850)
	SpellInfo(dash cd=120)
	SpellInfo(dash gcd=0 offgcd=1 if_stance=druid_cat_form)
	SpellInfo(dash to_stance=druid_cat_form if_stance=!druid_cat_form)
Define(entangling_roots 339)
Define(growl 6795)
	SpellInfo(growl cd=8)
Define(hibernate 2637)
Define(shred 5221)
	SpellInfo(shred energy=40 combopoints=-1)
	SpellInfo(shred physical=1)
Define(mangle 33917)
	SpellInfo(mangle rage=-8 cd=6 cd_haste=melee)
Define(moonfire 8921)
	SpellInfo(moonfire mana=6)
	SpellInfo(moonfire unusable=1 if_stance=druid_cat_form)
	SpellAddBuff(moonfire moonfire_debuff=1)
Define(moonfire_debuff 164812)
	SpellInfo(moonfire_debuff duration=16)
Define(prowl 5215)
	SpellInfo(prowl cd=10 gcd=0 offgcd=1 to_stance=druid_cat_form)
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
Define(skull_bash 106839)
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
	SpellInfo(dash replace=tigers_dash talent=tigers_dash_talent)
Define(renewal 108238)
	SpellInfo(renewal cd=120 gcd=0 offgcd=1 specialization=!guardian)

	SpellInfo(wild_charge cd=15 gcd=0 offgcd=1)
	SpellInfo(wild_charge replace=wild_charge_bear if_stance=druid_bear_form)
	SpellInfo(wild_charge replace=wild_charge_cat if_stance=druid_cat_form)
Define(wild_charge_bear 16979)
	SpellInfo(wild_charge_bear cd=15 stance=druid_bear_form)
Define(wild_charge_cat 49376)
	SpellInfo(wild_charge_cat cd=15 stance=druid_cat_form)
	

Define(mass_entanglement 102359)
	SpellInfo(mass_entanglement cd=30)
Define(mighty_bash 5211)
	SpellInfo(mighty_bash cd=50 interrupt=1)
Define(typhoon 132469)
	SpellInfo(typhoon cd=30 interrupt=1)


# Balance Affinity
Define(moonkin_form 197625)
	SpellInfo(moonkin_form to_stance=druid_moonkin_form)
	SpellInfo(moonkin_form unusable=1 if_stance=druid_moonkin_form)

	SpellAddBuff(lunar_strike lunar_empowerment_buff=0)
Define(solar_wrath 190984)
Define(starsurge 197626)
	SpellInfo(starsurge cd=10 specialization=!balance)
Define(sunfire 197630)
	SpellAddTargetDebuff(sunfire sunfire_debuff=1)
Define(sunfire_debuff 164815)
	SpellInfo(sunfire_debuff duration=12)

# Feral Affinity
Define(ferocious_bite 22568)
	SpellInfo(ferocious_bite energy=25 max_energy=50 combopoints=1 max_combopoints=5)
	SpellInfo(ferocious_bite physical=1)
Define(rake 1822)
	SpellAddTargetDebuff(rake rake_debuff=1)


	SpellInfo(rip energy=30 combopoints=1 max_combopoints=5)
	SpellAddTargetDebuff(rip rip_debuff=1)
Define(rip_debuff 1079)

# Guardian Affinity
Define(frenzied_regeneration 22842)
	SpellInfo(frenzied_regeneration rage=10 cd=36 cd_haste=melee)
	SpellAddBuff(frenzied_regeneration frenzied_regeneration_buff=1)
	SpellRequire(frenzied_regeneration unusable 1=debuff,healing_immunity_debuff)
Define(frenzied_regeneration_buff 22842)
	SpellInfo(frenzied_regeneration_buff duration=3)
Define(ironfur 192081)
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
    local desc = "[8.0] Ovale: Druid Balance spells"
    local code = [[
# NOT fully updated for 8.0
# Balance spells

	SpellInfo(celestial_alignment cd=180 shared_cd=celestial_alignment_cd)
	SpellInfo(celestial_alignment replace=incarnation_chosen_of_elune talent=incarnation_talent specialization=balance)
	SpellAddBuff(celestial_alignment celestial_alignment_buff=1)
Define(celestial_alignment_buff 194223)

Define(fury_of_elune 202770)
	SpellInfo(fury_of_elune cd=90 astralpower=6)
	SpellAddBuff(fury_of_elune fury_of_elune_up_buff=1)
Define(fury_of_elune_up_buff 202770)
	#TODO 12 astralpower per s
Define(full_moon 202771)	
	SpellInfo(full_moon cd=15 charges=3 astralpower=-40 shared_cd=new_moon)
Define(half_moon 202768)
	SpellInfo(half_moon cd=15 charges=3 astralpower=-20 shared_cd=new_moon)
Define(incarnation_chosen_of_elune 102560)
	SpellInfo(incarnation replace=incarnation_chosen_of_elune specialization=balance)
	SpellInfo(incarnation_chosen_of_elune cd=180 shared_cd=celestial_alignment_cd)
	SpellInfo(incarnation_chosen_of_elune unusable=1)
	SpellInfo(incarnation_chosen_of_elune unusable=0 talent=incarnation_talent)
	SpellAddBuff(incarnation_chosen_of_elune incarnation_chosen_of_elune_buff=1)
Define(incarnation_chosen_of_elune_buff 102560)
	SpellInfo(incarnation_chosen_of_elune_buff duration=30)
Define(lunar_beam 204066)
	SpellInfo(lunar_beam cd=90)
Define(lunar_empowerment_buff 164547)
Define(lunar_strike_balance 194153)
	SpellInfo(lunar_strike replace=lunar_strike_balance specialization=balance)
	SpellInfo(lunar_strike_balance astralpower=-12)
	SpellRequire(lunar_strike_balance astralpower_percent 150=buff,celestial_alignment_buff)
	SpellRequire(lunar_strike_balance astralpower_percent 125=buff,blessing_of_elune_buff)
	SpellAddBuff(lunar_strike_balance lunar_empowerment_buff=0)
#Define(moonfire )
	SpellInfo(moonfire astralpower=-3 specialization=balance)
#Define(moonfire_debuff)
	SpellInfo(moonfire_debuff add_duration=6 specialization=balance)
Define(moonkin_form_balance 24858)
	SpellInfo(moonkin_form replace=moonkin_form_balance specialization=balance)
	SpellInfo(moonkin_form_balance to_stance=druid_moonkin_form)
	SpellInfo(moonkin_form_balance unusable=1 if_stance=druid_moonkin_form)
	#TODO affinity moonkin form has a different spellId
Define(new_moon 202767)
	SpellInfo(new_moon cd=15 charges=3 astralpower=-10)
Define(solar_empowerment_buff 164545)
Define(solar_beam 78675)
	SpellInfo(solar_beam cd=60 gcd=0 offgcd=1 interrupt=1)
#Define(solar_wrath 190984)
	SpellInfo(solar_wrath travel_time=1 astralpower=-8)
	SpellRequire(solar_wrath astralpower_percent 125=buff,blessing_of_elune_buff)
	SpellRequire(solar_wrath astralpower_percent 150=buff,celestial_alignment_buff)
	SpellAddBuff(solar_wrath solar_empowerment_buff=-1)
Define(starfall 191034)
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
Define(sunfire_balance 93402)
	SpellInfo(sunfire replace=sunfire_balance specialization=balance)
	SpellAddTargetDebuff(sunfire_balance sunfire_debuff=1)
#Define(sunfire_debuff 164815)
	SpellInfo(sunfire_debuff add_duration=6 specialization=balance)

	SpellInfo(warrior_of_elune gcd=0 cd=45 offgcd=1)
Define(warrior_of_elune_buff 202425)
	#TODO 2 Lunar strikes are instant	
	SpellInfo(sunfire_debuff add_duration=6 specialization=balance)

# Balance Legendaries
Define(the_emerald_dreamcatcher 137062)

	SpellAddBuff(starsurge the_emerald_dreamcatcher_buff=-1)
Define(oneths_intuition_buff 209406)
Define(oneths_overconfidence_buff 209407)
	SpellRequire(starfall astralpower_percent 0=buff,oneths_overconfidence_buff)
	SpellAddBuff(starfall oneths_overconfidence_buff=-1)
	]]
    OvaleScripts:RegisterScript("DRUID", nil, name, desc, code, "include")
end

local registerSpec2 = function()
    local name = "ovale_druid_guardian_spells"
    local desc = "[8.0] Ovale: Druid Guardian spells"
    local code = [[
	Include(ovale_druid_base_spells)
# NOT updated for 8.0
# Guardian spells
#Define(barkskin )
	SpellInfo(barkskin add_cd=30 specialization=guardian talent=!survival_of_the_fittest_talent)

	SpellInfo(bristling_fur cd=40 gcd=0 offgcd=1)
	SpellAddBuff(bristling_fur bristling_fur_buff=1)
Define(bristling_fur_buff 155835)
	SpellInfo(bristling_fur_buff duration=8)
#Define(frenzied_regeneration 22842)
	SpellInfo(frenzied_regeneration charges=2 specialization=guardian)
	SpellAddBuff(frenzied_regeneration guardian_of_elune_buff=0)
Define(frenzied_regeneration_buff 22842)
Define(galactic_guardian_buff 213708)
Define(guardian_of_elune_buff 213680)
	SpellInfo(guardian_of_elune_buff duration=15)
Define(incapacitating_roar 99)
	SpellInfo(incapacitating_roar cd=30)
	SpellInfo(incapacitating_roar replace=intimidating_roar talent=intimidating_roar_talent)
Define(incarnation_guardian_of_ursoc 102558)
	SpellInfo(incarnation replace=incarnation_guardian_of_ursoc specialization=guardian)
	SpellInfo(incarnation_guardian_of_ursoc cd=180 unusable=1)
	SpellInfo(incarnation_guardian_of_ursoc unusable=0 talent=incarnation_talent specialization=guardian)
	SpellAddBuff(incarnation_guardian_of_ursoc incarnation_guardian_of_ursoc_buff=1)
Define(incarnation_guardian_of_ursoc_buff 102558)
	SpellInfo(incarnation_guardian_of_ursoc_buff duration=30)
Define(intimidating_roar 236748)
	SpellInfo(intimidating_roar cd=30)
#Define(ironfur 192081)
	SpellAddBuff(ironfur guardian_of_elune_buff=0)
#Define(ironfur_buff 192081)
#Define(mangle 33917)
	SpellInfo(mangle addrage=-4 talent=soul_of_the_forest_talent specialization=guardian)
	SpellAddBuff(mangle guardian_of_elune_buff=1 talent=guardian_of_elune_talent)

	SpellInfo(maul rage=45 stance=druid_bear_form)
Define(pulverize 80313)
	SpellRequire(pulverize unusable 1=target_debuff,!thrash_bear_debuff,2)
	SpellAddBuff(pulverize pulverize_buff=1)
	SpellAddTargetDebuff(pulverize thrash_bear_debuff=-2)
Define(pulverize_buff 158792)
	SpellInfo(pulverize_buff duration=20)
Define(swipe_bear 213771)
#Define(survival_instincts 61336)
	SpellInfo(survival_instincts add_cd=120 specialization=guardian)
	SpellInfo(survival_instincts add_cd=-80 specialization=guardian talent=survival_of_the_fittest_talent) 
#Define(thrash_bear 77758)
#Define(thrash_bear_debuff 192090)
	SpellInfo(thrash_bear_debuff max_stacks=5 if_equipped=elizes_everlasting_encasement)

# Guardian Legendaries
Define(elizes_everlasting_encasement 137067)
Define(skysecs_hold 137025)

# Guardian Talents
Define(intimidating_roar_talent 5)
Define(galactic_guardian_talent 14)
Define(survival_of_the_fittest_talent 17)
Define(guardian_of_elune_talent 18)
	]]
    OvaleScripts:RegisterScript("DRUID", nil, name, desc, code, "include")
end

local registerSpec3 = function()
    local name = "ovale_druid_feral_spells"
    local desc = "[8.0] Ovale: Druid Feral spells"
    local code = [[
Include(ovale_druid_base_spells)

# Constants
Define(berserk_percent_value 60)
Define(bloodtalons_value 1.25)
Define(tigers_fury_buff_value 1.15)

# Feral spells
Define(berserk 106951)
	SpellInfo(berserk cd=180)
	SpellInfo(berserk replace=incarnation_king_of_the_jungle talent=incarnation_talent specialization=feral)
	SpellAddBuff(berserk berserk_buff=1)
Define(berserk_buff 106951)
	SpellInfo(berserk_buff duration=15)
Define(incarnation_king_of_the_jungle 102543)
	SpellInfo(incarnation replace=incarnation_king_of_the_jungle specialization=feral)
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
Define(feral_frenzy 274837)
	SpellInfo(feral_frenzy energy=25 combopoints=-5 cd=45)
#Define(ferocious_bite 22568)
	SpellAddTargetDebuff(ferocious_bite rip_debuff=refresh_keep_snapshot,target_health_pct,25)
	SpellAddTargetDebuff(ferocious_bite rip_debuff=refresh_keep_snapshot talent=sabertooth_talent)
Define(maim 22570)
	SpellInfo(maim energy=35 combopoints=1 max_combopoints=5 cd=20)
Define(moonfire_cat 155625)
	SpellInfo(moonfire_cat energy=30 combopoints=-1)
	SpellInfo(moonfire_cat unusable=1 if_stance=!druid_cat_form specialization=feral talent=lunar_inspiration_talent)
	SpellAddTargetDebuff(moonfire_cat moonfire_cat_debuff=1)
Define(moonfire_cat_debuff 155625)
	SpellInfo(moonfire_cat_debuff duration=14 haste=melee tick=2 specialization=feral talent=lunar_inspiration_talent)
Define(predatory_swiftness_buff 69369)
	SpellInfo(predatory_swiftness_buff duration=12)
SpellList(improved_rake prowl_buff shadowmeld_buff incarnation_king_of_the_jungle_buff)
#Define(rake 1822)
	SpellInfo(rake energy=35 combopoints=-1)
	SpellAddBuff(rake prowl_buff=0)
	SpellAddBuff(rake shadowmeld_buff=0)
	SpellDamageBuff(rake improved_rake=2)
#
	SpellInfo(rake_debuff duration=15 haste=melee tick=3 talent=!jagged_wounds_talent)
	SpellInfo(rake_debuff duration=12 haste=melee tick=2.4 talent=jagged_wounds_talent)
	SpellDamageBuff(rake_debuff improved_rake=2)
#
#Define(rip_debuff 1079)
	SpellInfo(rip_debuff duration=24 haste=melee tick=2 talent=!jagged_wounds_talent)
	SpellInfo(rip_debuff duration=19.2 haste=melee tick=1.6 talent=jagged_wounds_talent)
Define(savage_roar 52610)
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
Define(tigers_fury 5217)
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
    local desc = "[7.3] Ovale: Druid spells"
    local code = [[
Include(ovale_druid_base_spells)
Include(ovale_druid_balance_spells)
Include(ovale_druid_guardian_spells)
Include(ovale_druid_feral_spells)
]]
    OvaleScripts:RegisterScript("DRUID", nil, name, desc, code, "include")
end
