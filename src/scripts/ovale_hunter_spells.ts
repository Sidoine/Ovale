import { OvaleScriptsClass } from "../engine/scripts";

export function registerHunterSpells(OvaleScripts: OvaleScriptsClass) {
    const name = "ovale_hunter_spells";
    const desc = "[9.0] Ovale: Hunter spells";
    // THIS PART OF THIS FILE IS AUTOMATICALLY GENERATED
    // ANY CHANGES MADE BELOW THIS POINT WILL BE LOST
    const code = `Define(a_murder_of_crows 131894)
# Summons a flock of crows to attack your target, dealing 131900s1*16 Physical damage over 15 seconds. If the target dies while under attack, A Murder of Crows' cooldown is reset.
  SpellInfo(a_murder_of_crows focus=30 cd=60 duration=15 tick=1)
  SpellRequire(a_murder_of_crows unusable set=1 enabled=(not hastalent(a_murder_of_crows_talent_survival)))
  # Under attack by a flock of crows.
  SpellAddTargetDebuff(a_murder_of_crows a_murder_of_crows add=1)
Define(aimed_shot 19434)
# A powerful aimed shot that deals s1 Physical damage.
  SpellInfo(aimed_shot focus=35 cd=12)
Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
Define(arcane_shot 185358)
# A quick shot that causes sw2 Arcane damage.
  SpellInfo(arcane_shot focus=40)
Define(arcane_torrent 25046)
# Remove s1 beneficial effect from all enemies within A1 yards and restore m2 Energy.
  SpellInfo(arcane_torrent cd=120 gcd=1 energy=-15)
Define(aspect_of_the_eagle 186289)
# Increases the range of your ?s259387[Mongoose Bite][Raptor Strike] to 265189r yds for 15 seconds.
  SpellInfo(aspect_of_the_eagle cd=90 duration=15 gcd=0 offgcd=1)
  # The range of ?s259387[Mongoose Bite][Raptor Strike] is increased to 265189r yds.
  SpellAddBuff(aspect_of_the_eagle aspect_of_the_eagle add=1)
Define(aspect_of_the_wild 193530)
# Grants you and your pet s2 Focus per sec and s1 increased critical strike chance for 20 seconds.
  SpellInfo(aspect_of_the_wild cd=120 duration=20 gcd=0 offgcd=1 tick=1)
  # Gaining s2 Focus per sec.rnCritical Strike chance increased by s1.
  SpellAddBuff(aspect_of_the_wild aspect_of_the_wild add=1)
Define(bag_of_tricks 312411)
# Pull your chosen trick from the bag and use it on target enemy or ally. Enemies take <damage> damage, while allies are healed for <healing>. 
  SpellInfo(bag_of_tricks cd=90)
Define(barbed_shot 217200)
# Fire a shot that tears through your enemy, causing them to bleed for s1*s2 damage over 8 seconds.rnrnSends your pet into a frenzy, increasing attack speed by 272790s1 for 8 seconds, stacking up to 272790u times.rnrn|cFFFFFFFFGenerates 246152s1*8 seconds/246152t1 Focus over 8 seconds.|r
  SpellInfo(barbed_shot cd=12 duration=8 tick=2)
  # Suffering sw1 damage every t1 sec.
  SpellAddTargetDebuff(barbed_shot barbed_shot add=1)
Define(barrage 120360)
# Rapidly fires a spray of shots for 3 seconds, dealing an average of <damageSec> Physical damage to up to 120361I enemies in front of you. Usable while moving.
  SpellInfo(barrage focus=60 cd=20 duration=3 channel=3 tick=0.2)
  SpellRequire(barrage unusable set=1 enabled=(not hastalent(barrage_talent_marksmanship)))
  SpellAddBuff(barrage barrage_buff add=1)
Define(barrage_buff 120361)
# Rapidly fires a spray of shots for 3 seconds, dealing an average of <damageSec> Physical damage to up to 120361I enemies in front of you. Usable while moving.
  SpellInfo(barrage_buff gcd=0 offgcd=1)
Define(beast_cleave_buff 118455)
# After you Multi-Shot, your pet's melee attacks also strike up to 118459I other nearby enemy targets for s1 as much for the next 4 seconds.
  SpellInfo(beast_cleave_buff duration=4 gcd=0 offgcd=1)
  # Melee attacks also strike all other nearby enemy targets.
  SpellAddBuff(beast_cleave_buff beast_cleave_buff add=1)
Define(berserking 59621)
# Permanently enchant a melee weapon to sometimes increase your attack power by 59620s1, but at the cost of reduced armor. Cannot be applied to items higher than level ecix
  SpellInfo(berserking gcd=0 offgcd=1)
Define(berserking_buff 26297)
# Increases your haste by s1 for 12 seconds.
  SpellInfo(berserking_buff cd=180 duration=12 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking_buff berserking_buff add=1)
Define(bestial_wrath 19574)
# Sends you and your pet into a rage, instantly dealing <damage> Physical damage to its target, and increasing all damage you both deal by s1 for 15 seconds. ?s231548&s217200[rnrnBestial Wrath's remaining cooldown is reduced by s3 sec each time you use Barbed Shot.][]
  SpellInfo(bestial_wrath cd=90 duration=15)
  # Damage dealt increased by w1.
  SpellAddBuff(bestial_wrath bestial_wrath add=1)
Define(blood_fury 20572)
# Increases your attack power by s1 for 15 seconds.
  SpellInfo(blood_fury cd=120 duration=15 gcd=0 offgcd=1)
  # Attack power increased by w1.
  SpellAddBuff(blood_fury blood_fury add=1)
Define(blood_of_the_enemy 297969)
# Infuse your Heart of Azeroth with Blood of the Enemy.
  SpellInfo(blood_of_the_enemy)
Define(blood_of_the_enemy_debuff 297108)
# The Heart of Azeroth erupts violently, dealing s1 Shadow damage to enemies within A1 yds. You gain m2 critical strike chance against the targets for 10 seconds?a297122[, and increases your critical hit damage by 297126m for 5 seconds][].
  SpellInfo(blood_of_the_enemy_debuff cd=120 duration=10)
  # You have a w2 increased chance to be Critically Hit by the caster.
  SpellAddTargetDebuff(blood_of_the_enemy_debuff blood_of_the_enemy_debuff add=1)
Define(bloodlust 2825)
# Increases haste by (25 of Spell Power) for all party and raid members for 40 seconds.rnrnAllies receiving this effect will become Sated and unable to benefit from Bloodlust or Time Warp again for 600 seconds.
  SpellInfo(bloodlust cd=300 duration=40 gcd=0 offgcd=1)
  # Haste increased by w1.
  SpellAddBuff(bloodlust bloodlust add=1)
Define(bloodshed 321530)
# Command your pet to tear into your target, causing your target to bleed for <damage> over 18 seconds and increase all damage taken from your pet by 321538s2 for 18 seconds.
  SpellInfo(bloodshed cd=60)
  SpellRequire(bloodshed unusable set=1 enabled=(not hastalent(bloodshed_talent)))
Define(blur_of_talons 277969)
# During Coordinated Assault, ?s259387[Mongoose Bite][Raptor Strike] increases your Agility by s1 and your Speed by s2 for 6 seconds. Stacks up to 277969u times.
  SpellInfo(blur_of_talons duration=6 max_stacks=5 gcd=0 offgcd=1)
Define(butchery 212436)
# Attack up to I nearby enemies in a flurry of strikes, inflicting s1 Physical damage to each.?s294029[rnrnReduces the remaining cooldown on Wildfire Bomb by <cdr> sec for each target hit.][]
  SpellInfo(butchery focus=30 cd=9)
  SpellRequire(butchery unusable set=1 enabled=(not hastalent(butchery_talent)))
Define(carve 187708)
# A sweeping attack that strikes up to I enemies in front of you for s1 Physical damage.?s294029[rnrnReduces the remaining cooldown on Wildfire Bomb by <cdr> sec for each target hit.][]
  SpellInfo(carve focus=35 cd=6)
Define(chakrams 259391)
# Throw a pair of chakrams at your target, slicing all enemies in the chakrams' path for <damage> Physical damage. The chakrams will return to you, damaging enemies again.rnrnYour primary target takes 259398s2 increased damage.
  SpellInfo(chakrams focus=15 cd=20)
  SpellRequire(chakrams unusable set=1 enabled=(not hastalent(chakrams_talent)))
  SpellAddBuff(chakrams chakrams_buff add=1)
  SpellAddTargetDebuff(chakrams chakrams_debuff add=1)
Define(chakrams_buff 267605)
# Throw a pair of chakrams at your target, slicing all enemies in the chakrams' path for 259396s1 Physical damage. The chakrams will return to you, damaging enemies again.rnrnYour primary target takes 259398s2 increased damage.
  SpellInfo(chakrams_buff cd=20 duration=5)
Define(chakrams_debuff 259398)
# @spelldesc259381
  SpellInfo(chakrams_debuff gcd=0 offgcd=1)
Define(chimaera_shot 53209)
# A two-headed shot that hits your primary target and another nearby target, dealing 171457sw2 Nature damage to one and 171454sw2 Frost damage to the other.?s137015[rnrn|cFFFFFFFFGenerates 204304s1 Focus for each target hit.|r][]
  SpellInfo(chimaera_shot cd=15)
  SpellRequire(chimaera_shot unusable set=1 enabled=(not hastalent(chimaera_shot_talent_beast_mastery)))
Define(chimaera_shot_marksmanship 342049)
# A two-headed shot that hits your primary target for 344120sw1 Nature damage and another nearby target for  344121sw1*(s1/100) Frost damage.
  SpellInfo(chimaera_shot_marksmanship focus=20)
  SpellRequire(chimaera_shot_marksmanship unusable set=1 enabled=(not hastalent(chimaera_shot_talent)))
Define(cobra_shot 193455)
# A quick shot causing s2*<mult> Physical damage.rnrnReduces the cooldown of Kill Command by s3 sec.
  SpellInfo(cobra_shot focus=35)
Define(concentrated_flame 295368)
# Blast your target with a ball of concentrated flame, dealing 295365s2*(1+@versadmg) Fire damage to an enemy or healing an ally for 295365s2*(1+@versadmg)?a295377[, then burn the target for an additional 295377m1 of the damage or healing done over 6 seconds][]. rnrnEach cast of Concentrated Flame deals s3 increased damage or healing. This bonus resets after every third cast.
  SpellInfo(concentrated_flame duration=6 gcd=0 offgcd=1 tick=2)
  # Suffering w1 damage every t1 sec.
  SpellAddTargetDebuff(concentrated_flame concentrated_flame add=1)
Define(coordinated_assault 266779)
# You and your pet attack as one, increasing all damage you both deal by s1 for 20 seconds.?s263186[rnrnWhile Coordinated Assault is active, Kill Command's chance to reset is increased by s4.][]
  SpellInfo(coordinated_assault cd=120 duration=20 gcd=0 offgcd=1)
  # Damage dealt increased by s1.?s263186[rnKill Command's chance to reset increased by s4.][]
  SpellAddBuff(coordinated_assault coordinated_assault add=1)
Define(counter_shot 147362)
# Interrupts spellcasting, preventing any spell in that school from being cast for 3 seconds.
  SpellInfo(counter_shot cd=24 duration=3 gcd=0 offgcd=1 interrupt=1)
Define(cyclotronic_blast 293491)
# Channel a cyclotronic blast, dealing a total of o1 Fire damage over D.
  SpellInfo(cyclotronic_blast cd=120 duration=2.5 channel=2.5 tick=0.5)
  # Burning for o1 Fire damage.
  SpellAddTargetDebuff(cyclotronic_blast cyclotronic_blast add=1)
Define(dance_of_death_buff 274441)
# Barbed Shot has a chance equal to your critical strike chance to grant you s1 Agility for 8 seconds.
  SpellInfo(dance_of_death_buff gcd=0 offgcd=1)
Define(dire_beast 120679)
# Summons a powerful wild beast that attacks the target and roars, increasing your Haste by 281036s1 for 8 seconds.
  SpellInfo(dire_beast cd=20 duration=8)
  SpellRequire(dire_beast unusable set=1 enabled=(not hastalent(dire_beast_talent)))
  # Haste increased by s1.
  SpellAddBuff(dire_beast dire_beast_buff add=1)
Define(dire_beast_buff 281036)
# Summons a powerful wild beast that attacks the target and roars, increasing your Haste by 281036s1 for 8 seconds.
  SpellInfo(dire_beast_buff duration=8 gcd=0 offgcd=1)
Define(double_tap 260402)
# Your next Aimed Shot will fire a second time instantly at s4 power without consuming Focus, or your next Rapid Fire will shoot s3 additional shots during its channel.
  SpellInfo(double_tap cd=60 duration=15)
  SpellRequire(double_tap unusable set=1 enabled=(not hastalent(double_tap_talent)))
  # Your next Aimed Shot will fire a second time instantly at s4 power and consume no Focus, or your next Rapid Fire will shoot s3 additional shots during its channel.
  SpellAddBuff(double_tap double_tap add=1)
Define(explosive_shot 212431)
# Fires an explosive shot at your target. After t1 sec, the shot will explode, dealing 212680s1 Fire damage to up to 212680I enemies within 212680A1 yards.
  SpellInfo(explosive_shot focus=20 cd=30 duration=3 tick=3)
  SpellRequire(explosive_shot unusable set=1 enabled=(not hastalent(explosive_shot_talent)))
  # Exploding for 212680s1 Fire damage after t1 sec.
  SpellAddTargetDebuff(explosive_shot explosive_shot add=1)
Define(fireblood 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. ?s195710[This effect shares a 30 sec cooldown with other similar effects.][]
  SpellInfo(fireblood cd=120 gcd=0 offgcd=1)
Define(flanking_strike 269751)
# You and your pet leap to the target and strike it as one, dealing a total of <damage> Physical damage.rnrn|cFFFFFFFFGenerates 269752s2 Focus for you and your pet.|r
  SpellInfo(flanking_strike cd=30)
  SpellRequire(flanking_strike unusable set=1 enabled=(not hastalent(flanking_strike_talent)))
Define(focused_azerite_beam 295258)
# Focus excess Azerite energy into the Heart of Azeroth, then expel that energy outward, dealing m1*10 Fire damage to all enemies in front of you over 3 seconds.?a295263[ Castable while moving.][]
  SpellInfo(focused_azerite_beam cd=90 duration=3 channel=3 tick=0.33)
  SpellAddBuff(focused_azerite_beam focused_azerite_beam add=1)
  SpellAddBuff(focused_azerite_beam focused_azerite_beam_unused_0 add=1)
Define(focused_azerite_beam_unused_0 295261)
# Focus excess Azerite energy into the Heart of Azeroth, then expel that energy outward, dealing m1*10 Fire damage to all enemies in front of you over 3 seconds.?a295263[ Castable while moving.][]
  SpellInfo(focused_azerite_beam_unused_0 cd=90)
Define(frenzy_buff 138895)
# Haste increased by s1 for 10 seconds.
  SpellInfo(frenzy_buff duration=10 max_stacks=5 gcd=0 offgcd=1)
Define(guardian_of_azeroth 295840)
# Call upon Azeroth to summon a Guardian of Azeroth for 30 seconds who impales your target with spikes of Azerite every s1/10.1 sec that deal 295834m1*(1+@versadmg) Fire damage.?a295841[ Every 303347t1 sec, the Guardian launches a volley of Azerite Spikes at its target, dealing 295841s1 Fire damage to all nearby enemies.][]?a295843[rnrnEach time the Guardian of Azeroth casts a spell, you gain 295855s1 Haste, stacking up to 295855u times. This effect ends when the Guardian of Azeroth despawns.][]rn
  SpellInfo(guardian_of_azeroth cd=180 duration=30)
Define(guardian_of_azeroth_buff 295855)
# Each time the Guardian of Azeroth casts a spell, you gain 295855s1 Haste, stacking up to 295855u times. This effect ends when the Guardian of Azeroth despawns.
  SpellInfo(guardian_of_azeroth_buff duration=60 max_stacks=5 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(guardian_of_azeroth_buff guardian_of_azeroth_buff add=1)
Define(harpoon 190925)
# Hurls a harpoon at an enemy, rooting them in place for 3 seconds and pulling you to them.
  SpellInfo(harpoon cd=1 charge_cd=30 duration=3 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(harpoon harpoon_debuff add=1)
  # Rooted.
  SpellAddTargetDebuff(harpoon harpoon add=1)
Define(harpoon_debuff 186260)
# Hurls a harpoon at an enemy, rooting them in place for 3 seconds and pulling you to them.
  SpellInfo(harpoon_debuff gcd=0 offgcd=1)
Define(in_the_rhythm 272733)
# When Rapid Fire finishes fully channeling, your Haste is increased by s1 for 8 seconds.
  SpellInfo(in_the_rhythm duration=8 gcd=0 offgcd=1)
  # Haste increased by w1.
  SpellAddBuff(in_the_rhythm in_the_rhythm add=1)
  SpellAddTargetDebuff(in_the_rhythm in_the_rhythm_debuff add=1)
Define(in_the_rhythm_debuff 264198)
# When Rapid Fire finishes fully channeling, your Haste is increased by s1 for 8 seconds.
  SpellInfo(in_the_rhythm_debuff gcd=0 offgcd=1)
Define(kill_command 34026)
# Give the command to kill, causing your pet to savagely deal <damage> Physical damage to the enemy.
  SpellInfo(kill_command focus=30 cd=7.5)
Define(kill_command_survival 259489)
# Give the command to kill, causing your pet to savagely deal <damage> Physical damage to the enemy.?s263186[rnrnHas a s2 chance to immediately reset its cooldown.][]rnrn|cFFFFFFFFGenerates s3 Focus.|r
  SpellInfo(kill_command_survival cd=6 focus=-15)
  # Your next ?s259387[Mongoose Bite][Raptor Strike] deals s1 increased damage.
  SpellAddBuff(kill_command_survival tip_of_the_spear_buff add=1)
Define(kill_shot 320976)
# You attempt to finish off a wounded target, dealing s1 Physical damage. Only usable on enemies with less than s2 health.
  SpellInfo(kill_shot focus=10 cd=10)
Define(latent_poison 273286)
# Serpent Sting damage applies Latent Poison, stacking up to 273286u times. Your ?s259387[Mongoose Bite][Raptor Strike] consumes all applications of Latent Poison to deal s1 Nature damage per stack.
  SpellInfo(latent_poison duration=20 max_stacks=10 gcd=0 offgcd=1)
  # The Hunter's next Raptor Strike or Mongoose Bite will consume all stacks of Latent Poison to deal additional Nature damage.
  SpellAddTargetDebuff(latent_poison latent_poison add=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)
  SpellAddTargetDebuff(lights_judgment lights_judgment_debuff add=1)
Define(lights_judgment_debuff 256893)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards.
  SpellInfo(lights_judgment_debuff cd=150)
Define(memory_of_lucid_dreams 299300)
# Infuse your Heart of Azeroth with Memory of Lucid Dreams.
  SpellInfo(memory_of_lucid_dreams)
Define(memory_of_lucid_dreams_buff 298357)
# Clear your mind and attune yourself with the Heart of Azeroth, ?a137020[causing Frostbolt and Flurry to generate an additional Icicle]?a137019[increasing your Fire Blast recharge rate by 303399s1*-2][increasing your ?a137033[Insanity]?(a137032|a137031|a137021|a137020|a137019|a137012|a137029|a137024|a137041|a137039)[Mana]?a137027|a137028[Holy Power]?(a137050|a137049|a137048|a137010)[Rage]?(a137017|a137015|a137016)[Focus]?(a137011|a137025|a137023|a137037|a137036|a137035)[Energy]?a212613[Pain]?a212612[Fury]?(a137046|a137044|a137043)[Soul Shard]?(a137008|a137007|a137006)[Rune]?a137040[Maelstrom]?a137013[Astral Power][] generation rate by s1]?a298377[ and ][]?a137020&a298377[increases ][]?a298377[your Leech by 298268s6][] for 12 seconds.
  SpellInfo(memory_of_lucid_dreams_buff cd=120 duration=12)
  # ?a303412[Frostbolt and Flurry will generate an additional Icicle]?a303399[Fire Blast recharge rate increased by 303399s1*-2][@spelldesc304633 generation increased by s1].?w2>0[rnLeech increased by w2.][]
  SpellAddBuff(memory_of_lucid_dreams_buff memory_of_lucid_dreams_buff add=1)
Define(mongoose_bite 259387)
# A brutal attack that deals s1 Physical damage and grants you Mongoose Fury.rnrn|cFFFFFFFFMongoose Fury|rrnIncreases the damage of Mongoose Bite by 259388s1 for 14 seconds, stacking up to 259388u times. Successive attacks do not increase duration.
  SpellInfo(mongoose_bite focus=30)
  SpellRequire(mongoose_bite unusable set=1 enabled=(not hastalent(mongoose_bite_talent)))
Define(mongoose_fury 259388)
# A brutal attack that deals s1 Physical damage and grants you Mongoose Fury.rnrn|cFFFFFFFFMongoose Fury|rrnIncreases the damage of Mongoose Bite by 259388s1 for 14 seconds, stacking up to 259388u times. Successive attacks do not increase duration.
  SpellInfo(mongoose_fury duration=14 max_stacks=5 gcd=0 offgcd=1)
  # Mongoose Bite damage increased by s1.
  SpellAddBuff(mongoose_fury mongoose_fury add=1)
Define(multishot 2643)
# Fires several missiles, hitting up to I targets within A2 yards of your current target for s2 Physical damage?s115939[ and triggering Beast Cleave][].?s19434[rnrn|cFFFFFFFFGenerates 213363s1 Focus per target hit.|r][]
  SpellInfo(multishot focus=40)
Define(multishot_marksmanship 257620)
# Fires several missiles, hitting your current target and up to I enemies within A1 yards for s1 Physical damage.
  SpellInfo(multishot_marksmanship focus=20)
Define(muzzle 187707)
# Interrupts spellcasting, preventing any spell in that school from being cast for 3 seconds.
  SpellInfo(muzzle cd=15 duration=3 gcd=0 offgcd=1 interrupt=1)
Define(pheromone_bomb 270332)
# Hurl a bomb at the target, exploding for 270329s1 Fire damage in a cone and coating enemies in pheromones, causing them to suffer 270332o1 Fire damage over 6 seconds.rnrnKill Command has a s2 chance to reset against targets coated with Pheromone Bomb.
  SpellInfo(pheromone_bomb duration=6 gcd=0 offgcd=1 tick=1)
  # Suffering w1 Fire damage every t1 sec.
  SpellAddTargetDebuff(pheromone_bomb pheromone_bomb add=1)
Define(potion_of_unbridled_fury_buff 300717)
# Deal s1 Fire damage to your current target.
  SpellInfo(potion_of_unbridled_fury_buff gcd=0 offgcd=1)
Define(precise_shots 260240)
# Aimed Shot causes your next 1-260242u ?s342049[Chimaera Shots][Arcane Shots] or Multi-Shots to deal 260242s1 more damage.
  SpellInfo(precise_shots gcd=0 offgcd=1)
Define(purifying_blast 295337)
# Call down a purifying beam upon the target area, dealing 295293s3*(1+@versadmg)*s2 Fire damage over 6 seconds.?a295364[ Has a low chance to immediately annihilate any specimen deemed unworthy by MOTHER.][]?a295352[rnrnWhen an enemy dies within the beam, your damage is increased by 295354s1 for 8 seconds.][]rnrnAny Aberration struck by the beam is stunned for 3 seconds.
  SpellInfo(purifying_blast cd=60 duration=6)
Define(quaking_palm 107079)
# Strikes the target with lightning speed, incapacitating them for 4 seconds, and turns off your attack.
  SpellInfo(quaking_palm cd=120 duration=4 gcd=1)
  # Incapacitated.
  SpellAddTargetDebuff(quaking_palm quaking_palm add=1)
Define(rapid_fire 257044)
# Shoot a stream of s1 shots at your target over 2 seconds, dealing a total of m1*257045sw1 Physical damage. ?s321281[rnrnEach shot generates 263585s1 Focus.][]rnrnUsable while moving.
  SpellInfo(rapid_fire cd=20 duration=2 channel=2 tick=0.33)
  # Being targeted by Rapid Fire.
  SpellAddTargetDebuff(rapid_fire rapid_fire add=1)
Define(raptor_strike 186270)
# A vicious slash dealing s1 Physical damage.
  SpellInfo(raptor_strike focus=30)
Define(razor_coral_debuff 303568)
# ?a303565[Remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.][Deal 304877s1*(1+@versadmg) Physical damage and apply Razor Coral to your target, giving your damaging abilities against the target a high chance to deal 304877s1*(1+@versadmg) Physical damage and add a stack of Razor Coral.rnrnReactivating this ability will remove Razor Coral from your target, granting you 303573s1 Critical Strike per stack for 20 seconds.]rn
  SpellInfo(razor_coral_debuff duration=120 max_stacks=100 gcd=0 offgcd=1)
  # Withdrawing the Razor Coral will grant w1 Critical Strike.
  SpellAddTargetDebuff(razor_coral_debuff razor_coral_debuff add=1)
Define(reaping_flames 310690)
# Burn your target with a bolt of Azerite, dealing 310712s3 Fire damage. If the target has less than s2 health?a310705[ or more than 310705s1 health][], the cooldown is reduced by s3 sec.?a310710[rnrnIf Reaping Flames kills an enemy, its cooldown is lowered to 310710s2 sec and it will deal 310710s1 increased damage on its next use.][]
  SpellInfo(reaping_flames cd=45)
Define(reckless_force_buff 298409)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 4 seconds.
  SpellInfo(reckless_force_buff max_stacks=5 gcd=0 offgcd=1 tick=10)
Define(reckless_force_counter 302917)
# When an ability fails to critically strike, you have a high chance to gain Reckless Force. When Reckless Force reaches 302917u stacks, your critical strike is increased by 302932s1 for 4 seconds.
  SpellInfo(reckless_force_counter duration=60 max_stacks=20 gcd=0 offgcd=1)
  # Upon reaching u stacks, you gain 302932s~1 Critical Strike for 302932d.
  SpellAddBuff(reckless_force_counter reckless_force_counter add=1)
Define(revive_pet 982)
# Revives your pet, returning it to life with s1 of its base health.
  SpellInfo(revive_pet focus=35 duration=3)
Define(ripple_in_space 299306)
# Infuse your Heart of Azeroth with Ripple in Space.
  SpellInfo(ripple_in_space)
Define(serpent_sting 259491)
# Fire a poison-tipped arrow at an enemy, dealing s1 Nature damage instantly and an additional o2 damage over 12 seconds.
  SpellInfo(serpent_sting focus=20 duration=12 tick=3)
  # Suffering w2 Nature damage every t2 sec.?a265428[ The Hunter's pet deals w3 increased damage to you.][]
  SpellAddTargetDebuff(serpent_sting serpent_sting add=1)
Define(shrapnel_bomb 270339)
# Hurl a bomb at the target, exploding for 270338s1 Fire damage in a cone and impaling enemies with burning shrapnel, scorching them for 270339o1 Fire damage over 6 seconds.rnrn?s259387[Mongoose Bite][Raptor Strike] and ?s212436[Butchery][Carve] apply Internal Bleeding, causing 270343o1 damage over 9 seconds. Internal Bleeding stacks up to 270343u times.
  SpellInfo(shrapnel_bomb duration=6 gcd=0 offgcd=1 tick=1)
  # Suffering w1 Fire damage every t1 sec.rn?s259387[Mongoose Bite][Raptor Strike] and Butchery apply a stack of Internal Bleeding.
  SpellAddTargetDebuff(shrapnel_bomb shrapnel_bomb add=1)
Define(shrapnel_bomb_debuff 270336)
# Hurl a bomb at the target, exploding for 270338s1 Fire damage in a cone and impaling enemies with burning shrapnel, scorching them for 270339o1 Fire damage over 6 seconds.rnrn?s259387[Mongoose Bite][Raptor Strike] and ?s212436[Butchery][Carve] apply Internal Bleeding, causing 270343o1 damage over 9 seconds. Internal Bleeding stacks up to 270343u times.
  SpellInfo(shrapnel_bomb_debuff duration=0.5 gcd=0 offgcd=1)
Define(stampede 201430)
# Summon a herd of stampeding animals from the wilds around you that deal damage to your enemies for 12 seconds.
  SpellInfo(stampede cd=120 duration=12)
  SpellRequire(stampede unusable set=1 enabled=(not hastalent(stampede_talent)))
Define(steady_focus_buff 193534)
# Using Steady Shot twice in a row increases your Haste by 193534s1 for 15 seconds.
  SpellInfo(steady_focus_buff duration=15 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(steady_focus_buff steady_focus_buff add=1)
Define(steady_shot 56641)
# A steady shot that causes s1 Physical damage.rnrnUsable while moving.?s321018[rnrn|cFFFFFFFFGenerates s2 Focus.][]
  SpellInfo(steady_shot)
  SpellRequire(steady_shot replaced_by set=cobra_shot enabled=(specialization(beast_mastery)))
Define(steel_trap 162488)
# Hurls a Steel Trap to the target location that snaps shut on the first enemy that approaches, immobilizing them for 20 seconds and causing them to bleed for 162487o1 damage over 20 seconds. rnrnDamage other than Steel Trap may break the immobilization effect. Trap will exist for 60 seconds. Limit 1.
  SpellInfo(steel_trap cd=30)
  SpellRequire(steel_trap unusable set=1 enabled=(not hastalent(steel_trap_talent)))
  SpellAddTargetDebuff(steel_trap steel_trap_debuff_unused_0 add=1)
Define(steel_trap_debuff_unused_0 162496)
# Hurls a Steel Trap to the target location that snaps shut on the first enemy that approaches, immobilizing them for 20 seconds and causing them to bleed for 162487o1 damage over 20 seconds. rnrnDamage other than Steel Trap may break the immobilization effect. Trap will exist for 60 seconds. Limit 1.
  SpellInfo(steel_trap_debuff_unused_0 duration=60 gcd=0 offgcd=1)
Define(the_unbound_force 299321)
# Infuse your Heart of Azeroth with The Unbound Force.
  SpellInfo(the_unbound_force)
Define(tip_of_the_spear_buff 260286)
# Kill Command increases the damage of your next ?s259387[Mongoose Bite][Raptor Strike] by 260286s1, stacking up to 260286u times.
  SpellInfo(tip_of_the_spear_buff duration=10 max_stacks=3 gcd=0 offgcd=1)
Define(trick_shots_buff 257622)
# When Multi-Shot hits s2 or more targets, your next Aimed Shot or Rapid Fire will ricochet and hit up to s1 additional targets for s4 of normal damage.
  SpellInfo(trick_shots_buff duration=20 gcd=0 offgcd=1)
  # Your next Aimed Shot or Rapid Fire will ricochet and hit 257621s1 additional targets for 257621s4 of normal damage.
  SpellAddBuff(trick_shots_buff trick_shots_buff add=1)
Define(trueshot 288613)
# Reduces the cooldown of your Aimed Shot and Rapid Fire by m1/4, and causes Aimed Shot to cast s4 faster for 15 seconds.
  SpellInfo(trueshot cd=120 duration=15 gcd=0 offgcd=1)
  # The cooldown of Aimed Shot and Rapid Fire is reduced by m1/4, and Aimed Shot casts s4 faster.
  SpellAddBuff(trueshot trueshot add=1)
Define(unerring_vision 274446)
# While Trueshot is active you gain s1 Critical Strike rating every sec, stacking up to 10 times.
  SpellInfo(unerring_vision duration=10 max_stacks=2 gcd=0 offgcd=1 tick=1)
Define(vipers_venom_buff 268552)
# ?s259387[Mongoose Bite][Raptor Strike] has a chance to make your next Serpent Sting cost no Focus and deal an additional 268552s1 initial damage.
  SpellInfo(vipers_venom_buff duration=8 gcd=0 offgcd=1)
Define(volatile_bomb 271045)
# Hurl a bomb at the target, exploding for 271048s1 Fire damage in a cone and coating enemies in volatile wildfire, scorching them for 271049o1 Fire damage over 6 seconds.rnrnVolatile Bomb causes an extra explosion for 260231s1 Fire damage against targets affected by Serpent Sting, and refreshes your Serpent Stings when it explodes.
  SpellInfo(volatile_bomb cd=18)
  SpellAddTargetDebuff(volatile_bomb volatile_bomb_debuff add=1)
Define(volatile_bomb_debuff 271047)
# Hurl a bomb at the target, exploding for 271048s1 Fire damage in a cone and coating enemies in volatile wildfire, scorching them for 271049o1 Fire damage over 6 seconds.rnrnVolatile Bomb causes an extra explosion for 260231s1 Fire damage against targets affected by Serpent Sting, and refreshes your Serpent Stings when it explodes.
  SpellInfo(volatile_bomb_debuff duration=0.5 gcd=0 offgcd=1)
Define(volley 260243)
# Rain a volley of arrows down over 6 seconds, dealing up to 260247s1*12 Physical damage to any enemy in the area, and gain the effects of Trick Shots for as long as Volley is active.
  SpellInfo(volley cd=45 duration=6 tick=0.5)
  SpellRequire(volley unusable set=1 enabled=(not hastalent(volley_talent)))
  # Raining arrows down in the target area.
  SpellAddBuff(volley volley add=1)
Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp add=1)
Define(wildfire_bomb 259495)
# Hurl a bomb at the target, exploding for 265157s1 Fire damage in a cone and coating enemies in wildfire, scorching them for 269747o1 Fire damage over 6 seconds.
  SpellInfo(wildfire_bomb cd=18)
  SpellAddTargetDebuff(wildfire_bomb wildfire_bomb_debuff add=1)
Define(wildfire_bomb_debuff 265163)
# Hurl a bomb at the target, exploding for 265157s1 Fire damage in a cone and coating enemies in wildfire, scorching them for 269747o1 Fire damage over 6 seconds.
  SpellInfo(wildfire_bomb_debuff duration=0.5 gcd=0 offgcd=1)
Define(worldvein_resonance 298606)
# Infuse your Heart of Azeroth with Worldvein Resonance.
  SpellInfo(worldvein_resonance)
Define(worldvein_resonance_buff 295206)
  SpellInfo(worldvein_resonance_buff gcd=0 offgcd=1)
Define(a_murder_of_crows_talent_survival 12) #22299
# Summons a flock of crows to attack your target, dealing 131900s1*16 Physical damage over 15 seconds. If the target dies while under attack, A Murder of Crows' cooldown is reset.
Define(alpha_predator_talent 3) #22296
# Kill Command now has s1+1 charges, and deals s2 increased damage.
Define(barrage_talent_marksmanship 5) #22497
# Rapidly fires a spray of shots for 3 seconds, dealing an average of <damageSec> Physical damage to up to 120361I enemies in front of you. Usable while moving.
Define(birds_of_prey_talent 19) #22272
# Attacking your pet's target with ?s259387[Mongoose Bite][Raptor Strike] or ?s212436[Butchery][Carve] extends the duration of Coordinated Assault by <duration> sec.
Define(bloodshed_talent 21) #22295
# Command your pet to tear into your target, causing your target to bleed for <damage> over 18 seconds and increase all damage taken from your pet by 321538s2 for 18 seconds.
Define(butchery_talent 6) #22297
# Attack up to I nearby enemies in a flurry of strikes, inflicting s1 Physical damage to each.?s294029[rnrnReduces the remaining cooldown on Wildfire Bomb by <cdr> sec for each target hit.][]
Define(calling_the_shots_talent 19) #22274
# Casting ?s342049[Chimaera Shot][Arcane Shot] or Multi-Shot reduces the cooldown of Trueshot by m1/1000.1 sec.
Define(careful_aim_talent 4) #22495
# Aimed Shot deals s3 bonus damage to targets who are above s1 health.
Define(chakrams_talent 21) #23105
# Throw a pair of chakrams at your target, slicing all enemies in the chakrams' path for <damage> Physical damage. The chakrams will return to you, damaging enemies again.rnrnYour primary target takes 259398s2 increased damage.
Define(chakrams_talent 21) #23105
# Throw a pair of chakrams at your target, slicing all enemies in the chakrams' path for <damage> Physical damage. The chakrams will return to you, damaging enemies again.rnrnYour primary target takes 259398s2 increased damage.
Define(chimaera_shot_talent 12) #21998
# A two-headed shot that hits your primary target for 344120sw1 Nature damage and another nearby target for  344121sw1*(s1/100) Frost damage.
Define(chimaera_shot_talent_beast_mastery 6) #22290
# A two-headed shot that hits your primary target and another nearby target, dealing 171457sw2 Nature damage to one and 171454sw2 Frost damage to the other.?s137015[rnrn|cFFFFFFFFGenerates 204304s1 Focus for each target hit.|r][]
Define(dire_beast_talent 3) #22282
# Summons a powerful wild beast that attacks the target and roars, increasing your Haste by 281036s1 for 8 seconds.
Define(double_tap_talent 18) #22287
# Your next Aimed Shot will fire a second time instantly at s4 power without consuming Focus, or your next Rapid Fire will shoot s3 additional shots during its channel.
Define(explosive_shot_talent 6) #22498
# Fires an explosive shot at your target. After t1 sec, the shot will explode, dealing 212680s1 Fire damage to up to 212680I enemies within 212680A1 yards.
Define(flanking_strike_talent 18) #22271
# You and your pet leap to the target and strike it as one, dealing a total of <damage> Physical damage.rnrn|cFFFFFFFFGenerates 269752s2 Focus for you and your pet.|r
Define(guerrilla_tactics_talent 4) #21997
# Wildfire Bomb now has s1+1 charges, and the initial explosion deals s2 increased damage.
Define(hydras_bite_talent 5) #22769
# Serpent Sting fires arrows at s1 additional enemies near your target, and its damage over time is increased by s2.
Define(killer_instinct_talent 1) #22291
# Kill Command deals s1 increased damage against enemies below s2 health.
Define(lethal_shots_talent 16) #23063
# ?s342049[Chimaera Shot][Arcane Shot] and Multi-Shot have a h chance to reduce the cooldown of Rapid Fire by m1/10.1 sec.
Define(mongoose_bite_talent 17) #22278
# A brutal attack that deals s1 Physical damage and grants you Mongoose Fury.rnrn|cFFFFFFFFMongoose Fury|rrnIncreases the damage of Mongoose Bite by 259388s1 for 14 seconds, stacking up to 259388u times. Successive attacks do not increase duration.
Define(one_with_the_pack_talent 5) #22266
# Wild Call has a s1 increased chance to reset the cooldown of Barbed Shot.
Define(scent_of_blood_talent_beast_mastery 4) #22500
# Activating Bestial Wrath grants s1 charges of Barbed Shot.
Define(stampede_talent 18) #23044
# Summon a herd of stampeding animals from the wilds around you that deal damage to your enemies for 12 seconds.
Define(steady_focus_talent 10) #22267
# Using Steady Shot twice in a row increases your Haste by 193534s1 for 15 seconds.
Define(steel_trap_talent 11) #19361
# Hurls a Steel Trap to the target location that snaps shut on the first enemy that approaches, immobilizing them for 20 seconds and causing them to bleed for 162487o1 damage over 20 seconds. rnrnDamage other than Steel Trap may break the immobilization effect. Trap will exist for 60 seconds. Limit 1.
Define(streamline_talent 11) #22286
# Rapid Fire's damage is increased by s1, and Rapid Fire also causes your next Aimed Shot to cast 342076s1 faster.
Define(terms_of_engagement_talent 2) #22283
# Harpoon deals 271625s1 Physical damage and generates (265898s1/5)*10 seconds Focus over 10 seconds. Killing an enemy resets the cooldown of Harpoon.
Define(vipers_venom_talent 1) #22275
# ?s259387[Mongoose Bite][Raptor Strike] has a chance to make your next Serpent Sting cost no Focus and deal an additional 268552s1 initial damage.
Define(volley_talent 21) #22288
# Rain a volley of arrows down over 6 seconds, dealing up to 260247s1*12 Physical damage to any enemy in the area, and gain the effects of Trick Shots for as long as Volley is active.
Define(volley_talent 21) #22288
# Rain a volley of arrows down over 6 seconds, dealing up to 260247s1*12 Physical damage to any enemy in the area, and gain the effects of Trick Shots for as long as Volley is active.
Define(wildfire_infusion_talent 20) #22301
# Lace your Wildfire Bomb with extra reagents, randomly giving it one of the following enhancements each time you throw it:rnrn|cFFFFFFFFShrapnel Bomb: |rShrapnel pierces the targets, causing ?s259387[Mongoose Bite][Raptor Strike] and ?s212436[Butchery][Carve] to apply a bleed for 9 seconds that stacks up to 270343u times.rnrn|cFFFFFFFFPheromone Bomb: |rKill Command has a 270323s2 chance to reset against targets coated with Pheromones.rnrn|cFFFFFFFFVolatile Bomb: |rReacts violently with poison, causing an extra explosion against enemies suffering from your Serpent Sting and refreshes your Serpent Stings.
Define(azsharas_font_of_power_item 169314)
Define(cyclotronic_blast_item 167672)
Define(unbridled_fury_item 139327)
Define(variable_intensity_gigavolt_oscillating_reactor_item 165572)
Define(dance_of_death_trait 274441)
Define(primal_instincts_trait 279806)
Define(rapid_reload_trait 278530)
Define(focused_fire_trait 278531)
Define(in_the_rhythm_trait 264198)
Define(surging_shots_trait 287707)
Define(unerring_vision_trait 274444)
Define(blur_of_talons_trait 277653)
Define(latent_poison_trait 273283)
Define(wilderness_survival_trait 278532)
Define(blood_of_the_enemy_essence_id 23)
Define(condensed_lifeforce_essence_id 14)
Define(essence_of_the_focusing_iris_essence_id 5)
Define(vision_of_perfection_essence_id 22)
Define(memory_of_lucid_dreams_essence_id 27)
    `;
    // END
    OvaleScripts.RegisterScript(
        "HUNTER",
        undefined,
        name,
        desc,
        code,
        "include"
    );
}
