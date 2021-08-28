import { OvaleScriptsClass } from "../engine/scripts";

export function registerWarriorSpells(scripts: OvaleScriptsClass) {
    const name = "ovale_warrior_spells";
    const desc = "[9.1] Ovale: Warrior spells";
    // THIS PART OF THIS FILE IS AUTOMATICALLY GENERATED
    let code = `Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you a random secondary stat for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
Define(ancient_aftershock 325886)
# Unleash a wave of anima, dealing s1 Nature damage to up to s2 enemies and knocking them down for 1.5 seconds.rnrnThe ground will continue to expel anima, dealing <areaDmg> Nature damage to up to s2 enemies and generating <rage> Rage per enemy over 12 seconds. Every <period> sec, targets are briefly knocked down.
  SpellInfo(ancient_aftershock cd=90 duration=1.5)
  # Stunned.
  SpellAddTargetDebuff(ancient_aftershock ancient_aftershock add=1)
Define(arcane_torrent 25046)
# Remove s1 beneficial effect from all enemies within A1 yards and restore m2 Energy.
  SpellInfo(arcane_torrent cd=120 gcd=1 energy=-15)
Define(avatar 107574)
# Transform into a colossus for 20 seconds, causing you to deal s1 increased damage and removing all roots and snares.rnrn|cFFFFFFFFGenerates s5/10 Rage.|r
  SpellInfo(avatar cd=90 duration=20 gcd=0 offgcd=1 rage=-20)
  SpellRequire(avatar unusable set=1 enabled=(not {hastalent(avatar_talent) or specialization("protection")}))
  # Damage done increased by s1.
  SpellAddBuff(avatar avatar add=1)
Define(bag_of_tricks 312411)
# Pull your chosen trick from the bag and use it on target enemy or ally. Enemies take <damage> damage, while allies are healed for <healing>. 
  SpellInfo(bag_of_tricks cd=90)
Define(berserking 26297)
# Increases your haste by s1 for 12 seconds.
  SpellInfo(berserking cd=180 duration=12 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking add=1)
Define(bladestorm 46924)
# Become an unstoppable storm of destructive force, striking up to s1 nearby targets for <dmg> Physical damage over 4 seconds.rnrnYou are immune to movement impairing and loss of control effects, but can use defensive abilities and avoid attacks.rnrn|cFFFFFFFFGenerates o4/10 Rage over the duration.|r
  SpellInfo(bladestorm cd=60 duration=4 tick=1)
  SpellRequire(bladestorm unusable set=1 enabled=(not hastalent(bladestorm_talent)))
  # Dealing damage to all nearby enemies every t1 sec.rnImmune to crowd control.
  SpellAddBuff(bladestorm bladestorm add=1)
Define(bladestorm_arms 227847)
# Become an unstoppable storm of destructive force, striking up to s1 nearby targets for (1+6 seconds)*50622s1 Physical damage over 6 seconds.rnrnYou are immune to movement impairing and loss of control effects, but can use defensive abilities and can avoid attacks.
  SpellInfo(bladestorm_arms cd=90 duration=6 tick=1)
  SpellRequire(bladestorm_arms replaced_by set=ravager enabled=(hastalent(ravager_talent)))
  # Dealing damage to all nearby enemies every t1 sec.rnImmune to crowd control.
  SpellAddBuff(bladestorm_arms bladestorm_arms add=1)
Define(blood_fury_ap 20572)
# Increases your attack power by s1 for 15 seconds.
  SpellInfo(blood_fury_ap cd=120 duration=15 gcd=0 offgcd=1)
  # Attack power increased by w1.
  SpellAddBuff(blood_fury_ap blood_fury_ap add=1)
Define(bloodbath 335096)
# Assault the target in a bloodthirsty craze, dealing s1 Physical damage and restoring 117313s1 of your health.rnrn|cFFFFFFFFGenerates s2/10 Rage.|r
  SpellInfo(bloodbath cd=3 rage=-8)
Define(bloodlust 2825)
# Increases haste by (25 of Spell Power) for all party and raid members for 40 seconds.rnrnAllies receiving this effect will become Sated and unable to benefit from Bloodlust or Time Warp again for 600 seconds.
  SpellInfo(bloodlust cd=300 duration=40 gcd=0 offgcd=1)
  # Haste increased by w1.
  SpellAddBuff(bloodlust bloodlust add=1)
Define(bloodthirst 23881)
# Assault the target in a bloodthirsty craze, dealing s1 Physical damage and restoring 117313s1 of your health.rnrn|cFFFFFFFFGenerates s2/10 Rage.|r
  SpellInfo(bloodthirst cd=4.5 rage=-8)
Define(charge 100)
# Charge to an enemy, dealing 126664s2 Physical damage, rooting it for 1 second?s103828[, and stunning it for 7922d][].rnrn|cFFFFFFFFGenerates /10;s2 Rage.|r
  SpellInfo(charge cd=20 gcd=0 offgcd=1 rage=-10)
Define(cleave 845)
# Strikes up to s2 enemies in front of you for s1 Physical damage, inflicting Deep Wounds. Cleave will consume your Overpower effect to deal increased damage.
  SpellInfo(cleave rage=20 cd=6)
  SpellRequire(cleave unusable set=1 enabled=(not hastalent(cleave_talent)))
Define(colossus_smash 167105)
# Smashes the enemy's armor, dealing s1 Physical damage, and increasing damage you deal to them by 208086s1 for 10 seconds.
  SpellInfo(colossus_smash cd=90)
  SpellRequire(colossus_smash replaced_by set=warbreaker enabled=(hastalent(warbreaker_talent)))
Define(colossus_smash_debuff 208086)
# Smashes the enemy's armor, dealing s1 Physical damage, and increasing damage you deal to them by 208086s1 for 10 seconds.
  SpellInfo(colossus_smash_debuff duration=10 gcd=0 offgcd=1)
  # Taking w1 additional damage from @auracaster.
  SpellAddTargetDebuff(colossus_smash_debuff colossus_smash_debuff add=1)
Define(condemn 317349)
# Condemn a foe to suffer for their sins, causing up to <damage> Shadow damage. Only usable on enemies who are above 80 health or below 20 health.rnrnThe primary target is weakened, preventing up to <absorb> damage they would deal to you.?s231830[rnrnIf your foe survives, s2 of the Rage spent is refunded.][]
  SpellInfo(condemn rage=20 max_rage=20 cd=6)
Define(condemn_fury 317485)
# Condemn a foe to suffer for their sins, causing 317488sw1+317489sw1 Shadow damage. Only usable on enemies who are above 80 health or below 20 health.rnrnThe primary target is weakened, preventing <absorb> damage they would deal to you.?s316403[rnrn|cFFFFFFFFGenerates m3/10 Rage.|r][]
  SpellInfo(condemn_fury rage=0 max_rage=20 cd=6)
Define(conquerors_banner 324143)
# Plant the Conqueror's Banner in the ground, granting 325862s1 maximum health and 325862s2 critical strike chance to you and 325862i allies within s1 yds of the banner for 20 seconds.rnrnWhile active, spending ?c1[<armsRage>]?c2[<furyRage>][<protRage>] Rage and killing enemies grants you Glory. Glory increases your critical strike damage by 325787s1 per stack, up to 325787s1*325787u, for 30 seconds.
  SpellInfo(conquerors_banner cd=180 duration=20)
Define(crushing_blow 335097)
# Charge to an enemy and strike a mighty blow with both weapons that deals a total of 335098s1+335100s1 Physical damage.?s316452[rnrnCrushing Blow has a s1 chance to instantly reset its own cooldown.][]rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(crushing_blow cd=8 rage=-12)
Define(deadly_calm 262228)
# Reduces the Rage cost of your next n abilities by s1.rnrn|cFFFFFFFFPassive:|r Your maximum Rage is increased by 314522s1/10.
  SpellInfo(deadly_calm cd=60 duration=20 gcd=0 offgcd=1)
  SpellRequire(deadly_calm unusable set=1 enabled=(not hastalent(deadly_calm_talent)))
  # Your abilities cost s1 less Rage.
  SpellAddBuff(deadly_calm deadly_calm add=1)
Define(deep_wounds_arms_debuff 262115)
# Mortal Strike, ?s262161[Warbreaker][Colossus Smash], ?s845[Cleave, ][]and ?s152277[Ravager][Bladestorm] inflict Deep Wounds, dealing 262115o1 Bleed damage over 12 seconds and increasing the damage the enemy takes from you by (110.00000000000001 of Spell Power).1.
  SpellInfo(deep_wounds_arms_debuff duration=12 gcd=0 offgcd=1 tick=3)
Define(demoralizing_shout 1160)
# ?s199023[Demoralizes all enemies within A2 yards, reducing the damage they do by s2 for 8 seconds.][Demoralizes all enemies within A2 yards, reducing the damage they deal to you by s1 for 8 seconds.]?s202743[rnrn|cFFFFFFFFGenerates m5/10 Rage.|r][]
  SpellInfo(demoralizing_shout cd=45 duration=8 rage=0)
  # ?s199023[Demoralized, dealing w2 less damage.][Demoralized, dealing w1 less damage to @auracaster.]
  SpellAddTargetDebuff(demoralizing_shout demoralizing_shout add=1)
Define(devastate 20243)
# A direct strike, dealing s1 Physical damage.
  SpellInfo(devastate max_stacks=3)
  SpellRequire(devastate replaced_by set=devastator_passive enabled=(hastalent(devastator_talent)))
Define(devastator_passive 236279)
# Your auto attacks deal an additional 236282s1 Physical damage and have a s2 chance to reset the remaining cooldown on Shield Slam.
  SpellInfo(devastator_passive gcd=0 offgcd=1 unusable=1)
  SpellRequire(devastator_passive unusable set=1 enabled=(not hastalent(devastator_talent)))
Define(dragon_roar 118000)
# Roar explosively, dealing s1 Physical damage to enemies within A1 yds. Deals reduced damage to secondary targets. Dragon Roar critically strikes for <critMult> times normal damage.rnrn|cFFFFFFFFGenerates s2/10 Rage.|r
  SpellInfo(dragon_roar cd=30 rage=-10)
  SpellRequire(dragon_roar unusable set=1 enabled=(not {hastalent(dragon_roar_talent) or hastalent(dragon_roar_talent_protection)}))
Define(execute 163201)
# Attempts to finish off a foe, causing up to <damage> Physical damage based on Rage spent. Only usable on enemies that have less than 20 health.?s231830[rnrnIf your foe survives, s2 of the Rage spent is refunded.][]
  SpellInfo(execute rage=20 max_rage=20 cd=6)
  SpellRequire(execute replaced_by set=execute_fury enabled=(specialization("fury")))
Define(execute_fury 5308)
# Attempt to finish off a wounded foe, causing 280849s1+163558s1 Physical damage. Only usable on enemies that have less than 20 health.?s316403[rnrn|cFFFFFFFFGenerates m3/10 Rage.|r][]
  SpellInfo(execute_fury rage=0 max_rage=20 cd=6)
Define(fireblood 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. ?s195710[This effect shares a 30 sec cooldown with other similar effects.][]
  SpellInfo(fireblood cd=120 gcd=0 offgcd=1)
Define(frenzy_warrior_buff 335082)
# Rampage increases your Haste by 335082s1 for 12 seconds, stacking up to 335082u times. This effect is reset if you Rampage a different primary target.
  SpellInfo(frenzy_warrior_buff duration=12 max_stacks=4 gcd=0 offgcd=1)
  # Haste increased by w1.
  SpellAddBuff(frenzy_warrior_buff frenzy_warrior_buff add=1)
Define(heroic_leap 6544)
# Leap through the air toward a target location, slamming down with destructive force to deal 52174s1 Physical damage to all enemies within 52174a1 yards?c3[, and resetting the remaining cooldown on Taunt][].
  SpellInfo(heroic_leap cd=45 gcd=0 offgcd=1)
Define(ignore_pain 190456)
# Fight through the pain, ignoring s2 of damage taken, up to <absorb> total damage prevented.
  SpellInfo(ignore_pain rage=40 cd=12 duration=12 gcd=0 offgcd=1)
  # Ignoring s2 of damage taken, preventing w1 total damage.
  SpellAddBuff(ignore_pain ignore_pain add=1)
Define(intercept 198304)
# Run at high speed toward an enemy or ally.rnrnWhen targeting an enemy, deals 126664s2 Physical damage and roots the target for 1 second.rnrnWhen targeting an ally, intercepts the next melee or ranged attack against them within 6 seconds while the ally remains within 147833A2 yards.rnrn|cFFFFFFFFGenerates /10;s2 Rage.|r
  SpellInfo(intercept cd=20 gcd=0 offgcd=1 rage=-15)
Define(intimidating_shout 5246)
# ?s275338[Causes the targeted enemy and up to s1 additional enemies within 5246A3 yards to cower in fear.][Causes the targeted enemy to cower in fear, and up to s1 additional enemies within 5246A3 yards to flee.] Targets are disoriented for 8 seconds.
  SpellInfo(intimidating_shout cd=90 duration=8)
  # Disoriented.
  SpellAddTargetDebuff(intimidating_shout intimidating_shout add=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)
Define(mortal_strike 12294)
# A vicious strike that deals s1 Physical damage and reduces the effectiveness of healing on the target by 115804s1 for 10 seconds.
  SpellInfo(mortal_strike rage=30 cd=6)
Define(onslaught 315720)
# Brutally attack an enemy for s1 Physical damage. Requires Enrage.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(onslaught cd=12 rage=-15)
  SpellRequire(onslaught unusable set=1 enabled=(not hastalent(onslaught_talent)))
Define(overpower 7384)
# Overpower the enemy, dealing s1 Physical damage. Cannot be blocked, dodged, or parried.?s316440&s845[rnrnIncreases the damage of your next Mortal Strike or Cleave by s2]?s316440[rnrnIncreases the damage of your next Mortal Strike by s2][]?(s316440&!s316441)[.][]?s316441[, stacking up to u times.][]
  SpellInfo(overpower cd=12 duration=15 max_stacks=1)
  # Your next Mortal Strike ?s845[or Cleave ][]will deal w2 increased damage.
  SpellAddBuff(overpower overpower add=1)
Define(pummel 6552)
# Pummels the target, interrupting spellcasting and preventing any spell in that school from being cast for 4 seconds.
  SpellInfo(pummel cd=15 duration=4 gcd=0 offgcd=1 interrupt=1)
Define(quaking_palm 107079)
# Strikes the target with lightning speed, incapacitating them for 4 seconds, and turns off your attack.
  SpellInfo(quaking_palm cd=120 duration=4 gcd=1)
  # Incapacitated.
  SpellAddTargetDebuff(quaking_palm quaking_palm add=1)
Define(raging_blow 85288)
# A mighty blow with both weapons that deals a total of <damage> Physical damage.?s316452[rnrnRaging Blow has a s1 chance to instantly reset its own cooldown.][]rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(raging_blow cd=8 rage=-12)
Define(rampage 184367)
# ?s316412[Enrages you and unleashes][Unleashes] a series of s1 brutal strikes for a total of <damage> Physical damage.
  SpellInfo(rampage rage=80)
Define(ravager 152277)
# Throws a whirling weapon at the target location that chases nearby enemies, inflicting <damage> Physical damage and applying Deep Wounds to up to 156287s2 enemies over 12 seconds.rnrn|cFFFFFFFFGenerates 248439s1/10 Rage each time it deals damage.|r
  SpellInfo(ravager cd=45 duration=12 tick=2)
  SpellRequire(ravager unusable set=1 enabled=(not hastalent(ravager_talent)))
  # Ravager is currently active.
  SpellAddBuff(ravager ravager add=1)
Define(ravager_protection 228920)
# Throws a whirling weapon at the target location that chases nearby enemies, inflicting <damage> Physical damage to up to 156287s2 enemies over 12 seconds.rnrn|cFFFFFFFFGenerates 334934s1/10 Rage each time it deals damage.|r
  SpellInfo(ravager_protection cd=45 duration=12 tick=2)
  SpellRequire(ravager_protection unusable set=1 enabled=(not hastalent(ravager_talent_protection)))
  # Ravager is currently active.
  SpellAddBuff(ravager_protection ravager_protection add=1)
Define(recklessness 1719)
# Go berserk, increasing all Rage generation by s4?a202751[, greatly empowering Bloodthirst and Raging Blow,][] and granting your abilities s1 increased critical strike chance for 10 seconds.?a202751[rnrn|cFFFFFFFFGenerates s3/10 Rage.|r][]
  SpellInfo(recklessness cd=90 duration=10 gcd=0 offgcd=1 rage=0)
  # Rage generation increased by s5.rnCritical strike chance of all abilities increased by w1.?a202751[rnBloodthirst and Raging Blow upgraded to @spellname335096 and @spellname335097.][]
  SpellAddBuff(recklessness recklessness add=1)
Define(rend 772)
# Wounds the target, causing s1 Physical damage instantly and an additional o2 Bleed damage over 15 seconds.rnrnIncreases critical damage you deal to the enemy by s3.
  SpellInfo(rend rage=30 duration=15 tick=3)
  SpellRequire(rend unusable set=1 enabled=(not hastalent(rend_talent)))
  # Bleeding for w2 damage every t2 sec. Taking w3 increased critical damage from @auracaster.
  SpellAddTargetDebuff(rend rend add=1)
Define(revenge 6572)
# Swing in a wide arc, dealing s1 Physical damage to all enemies in front of you. Deals reduced damage beyond <cap> targets.rnrnYour successful dodges and parries have a chance to make your next Revenge cost no Rage.
  SpellInfo(revenge rage=20)
Define(shield_block 2565)
# Raise your shield, blocking all melee attacks against you for 6 seconds.?s76857[ These blocks can be critical blocks.][]?c3[ Increases Shield Slam damage by 132404s2 while active.][]
  SpellInfo(shield_block rage=30 cd=16 gcd=0 offgcd=1)
Define(shield_block_buff 132404)
# Raise your shield, blocking all melee attacks against you for 6 seconds.?s76857[ These blocks can be critical blocks.][]?c3[ Increases Shield Slam damage by 132404s2 while active.][]
  SpellInfo(shield_block_buff duration=6 gcd=0 offgcd=1)
  # Block chance increased by s1.
  SpellAddBuff(shield_block_buff shield_block_buff add=1)
Define(shield_slam 23922)
# Slams the target with your shield, causing s1 Physical damage.?s231834[rnrnDevastate, Thunder Clap, Revenge, and Execute have a 231834s1 chance to reset the cooldown of Shield Slam.][]?s316523[rnrn|cFFFFFFFFGenerates s2/10 Rage.|r][]
  SpellInfo(shield_slam cd=9 rage=0)
Define(shockwave 46968)
# Sends a wave of force in a frontal cone, causing s2 damage and stunning all enemies within a1 yards for 2 seconds.
  SpellInfo(shockwave cd=40)
  # Stunned.
  SpellAddBuff(shockwave shockwave add=1)
Define(siegebreaker 280772)
# Break the enemy's defenses, dealing s1 Physical damage, and increasing your damage done to the target by 280773s1 for 10 seconds.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(siegebreaker cd=30 rage=-10)
  SpellRequire(siegebreaker unusable set=1 enabled=(not hastalent(siegebreaker_talent)))
Define(siegebreaker_debuff 280773)
# Break the enemy's defenses, dealing s1 Physical damage, and increasing your damage done to the target by 280773s1 for 10 seconds.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(siegebreaker_debuff duration=10 gcd=0 offgcd=1)
  # Taking w1 increased damage from @auracaster.
  SpellAddTargetDebuff(siegebreaker_debuff siegebreaker_debuff add=1)
Define(skullsplitter 260643)
# Bash an enemy's skull, dealing s1 Physical damage.rnrn|cFFFFFFFFGenerates s2/10 Rage.|r
  SpellInfo(skullsplitter cd=21 rage=-20)
  SpellRequire(skullsplitter unusable set=1 enabled=(not hastalent(skullsplitter_talent)))
Define(slam 1464)
# Slams an opponent, causing s1 Physical damage.
  SpellInfo(slam rage=20)
  SpellRequire(slam replaced_by set=revenge enabled=(specialization("protection")))
Define(spear_of_bastion 307865)
# Throw a Kyrian spear at the target location, dealing 307871s1 Arcane damage instantly and an additional 307871o4 damage over 4 seconds. Deals reduced damage beyond <cap> targets.rnrnEnemies hit are tethered to Spear of Bastion's location for the duration.rnrn|cFFFFFFFFGenerates /10;307871s3 Rage.|r
  SpellInfo(spear_of_bastion cd=60)
  # Tethered by the Spear of Bastion and taking w4 Arcane damage every t4 sec.
  SpellAddTargetDebuff(spear_of_bastion spear_of_bastion_debuff add=1)
Define(spear_of_bastion_debuff 307871)
# Throw a Kyrian spear at the target location, dealing 307871s1 Arcane damage instantly and an additional 307871o4 damage over 4 seconds. Deals reduced damage beyond <cap> targets.rnrnEnemies hit are tethered to Spear of Bastion's location for the duration.rnrn|cFFFFFFFFGenerates /10;307871s3 Rage.|r
  SpellInfo(spear_of_bastion_debuff duration=4 gcd=0 offgcd=1 rage=-25 tick=1)
Define(storm_bolt 107570)
# Hurls your weapon at an enemy, causing s1 Physical damage and stunning for 4 seconds.
  SpellInfo(storm_bolt cd=30)
  SpellRequire(storm_bolt unusable set=1 enabled=(not {hastalent(storm_bolt_talent) or hastalent(storm_bolt_talent_arms) or hastalent(storm_bolt_talent_fury)}))
  # Stunned.
  SpellAddBuff(storm_bolt storm_bolt add=1)
Define(sweeping_strikes 260708)
# For 12 seconds your single-target damaging abilities hit s1 additional Ltarget:targets; within 8 yds for s2 damage.
  SpellInfo(sweeping_strikes cd=45 duration=12 gcd=0.75)
  # Your single-target damaging abilities hit s1 additional Ltarget:targets; within 8 yds for s2 damage.
  SpellAddBuff(sweeping_strikes sweeping_strikes add=1)
Define(thunder_clap 6343)
# Blasts all enemies within 6343A1 yards for s1 Physical damage?(s316414&s199045)[, rooting them for 1 second and reducing their movement speed by s2 for 10 seconds.]?s199045[ and roots them for 1 second.]?s316414[ and reduces their movement speed by s2 for 10 seconds.][.] Deals reduced damage beyond s5 targets.rnrn|cFFFFFFFFGenerates s4/10 Rage.|r
  SpellInfo(thunder_clap cd=6 duration=10 rage=-5)
  # Movement speed reduced by s2.
  SpellAddTargetDebuff(thunder_clap thunder_clap add=1)
Define(war_stomp 20549)
# Stuns up to i enemies within A1 yds for 2 seconds.
  SpellInfo(war_stomp cd=90 duration=2 gcd=0 offgcd=1)
  # Stunned.
  SpellAddTargetDebuff(war_stomp war_stomp add=1)
Define(warbreaker 262161)
# Smash the ground and shatter the armor of all enemies within A1 yds, dealing s1 Physical damage and increasing damage you deal to them by 208086s1 for 10 seconds.
  SpellInfo(warbreaker cd=45)
  SpellRequire(warbreaker unusable set=1 enabled=(not hastalent(warbreaker_talent)))
Define(whirlwind 1680)
# Unleashes a whirlwind of steel, ?s202316[hitting your primary target with Slam and ][]striking up to s1 nearby targets for <baseDmg> Physical damage.
  SpellInfo(whirlwind rage=30)
  SpellRequire(whirlwind replaced_by set=whirlwind_fury enabled=(specialization("fury")))
Define(whirlwind_buff 85739)
# Causes your next single-target attack to strike up to s1 additional targets for s3 damage.
  SpellInfo(whirlwind_buff duration=20 max_stacks=2 gcd=0 offgcd=1)
  # Your next single-target attack strikes up to w1 additional targets for w3 damage.
  SpellAddBuff(whirlwind_buff whirlwind_buff add=1)
Define(whirlwind_fury 190411)
# Unleashes a whirlwind of steel, striking up to s3 nearby enemies for <damage> Physical damage.?s12950[rnrnCauses your next 85739u single-target melee lattack:attacks; to strike up to 85739s1 additional targets for 85739s3 damage.][]?s316435[rnrn|cFFFFFFFFGenerates s1 Rage, plus an additional s2 per target hit.|r][]
  SpellInfo(whirlwind_fury rage=30)
Define(will_of_the_berserker_buff 335597)
# When Recklessness expires, your Critical Strike is increased by 335597s1 for 8 seconds. Your Raging Blow will refresh the duration of this effect.
  SpellInfo(will_of_the_berserker_buff duration=8 gcd=0 offgcd=1)
  # Critical Strike increased by w1. Raging Blow refreshes this duration.
  SpellAddBuff(will_of_the_berserker_buff will_of_the_berserker_buff add=1)
Define(anger_management_talent_fury 22405)
# Every ?c1[s1]?c2[s3][s2] Rage you spend reduces the remaining cooldown on ?c1&s262161[Warbreaker and Bladestorm]?c1[Colossus Smash and Bladestorm]?c2[Recklessness][Avatar and Shield Wall] by 1 sec.
Define(avatar_talent 22397)
# Transform into a colossus for 20 seconds, causing you to deal s1 increased damage and removing all roots and snares.rnrn|cFFFFFFFFGenerates s5/10 Rage.|r
Define(bladestorm_talent 22400)
# Become an unstoppable storm of destructive force, striking up to s1 nearby targets for <dmg> Physical damage over 4 seconds.rnrnYou are immune to movement impairing and loss of control effects, but can use defensive abilities and avoid attacks.rnrn|cFFFFFFFFGenerates o4/10 Rage over the duration.|r
Define(booming_voice_talent 22626)
# Demoralizing Shout also generates m1/10 Rage, and increases damage you deal to affected targets by s2.
Define(cleave_talent 22362)
# Strikes up to s2 enemies in front of you for s1 Physical damage, inflicting Deep Wounds. Cleave will consume your Overpower effect to deal increased damage.
Define(cruelty_talent 19140)
# While Enraged, Raging Blow deals s1 more damage and has a s2 chance to instantly reset its own cooldown.
Define(deadly_calm_talent 22399)
# Reduces the Rage cost of your next n abilities by s1.rnrn|cFFFFFFFFPassive:|r Your maximum Rage is increased by 314522s1/10.
Define(devastator_talent 15774)
# Your auto attacks deal an additional 236282s1 Physical damage and have a s2 chance to reset the remaining cooldown on Shield Slam.
Define(dragon_roar_talent_protection 23260)
# Roar explosively, dealing s1 Physical damage to enemies within A1 yds. Deals reduced damage to secondary targets. Dragon Roar critically strikes for <critMult> times normal damage.rnrn|cFFFFFFFFGenerates s2/10 Rage.|r
Define(dragon_roar_talent 22398)
# Roar explosively, dealing s1 Physical damage to enemies within A1 yds. Deals reduced damage to secondary targets. Dragon Roar critically strikes for <critMult> times normal damage.rnrn|cFFFFFFFFGenerates s2/10 Rage.|r
Define(dreadnaught_talent 22407)
# Overpower has 1+s1 charges and causes a seismic wave, dealing 315961s1 damage to up to 315961s2 enemies in a 315961A1 yd line.
Define(fervor_of_battle_talent 22489)
# Whirlwind also Slams your primary target.
Define(massacre_talent 22379)
# ?a317320[Condemn][Execute] is now usable on targets below s2 health, and its cooldown is reduced by s3/1000.1 sec.
Define(massacre_talent_arms 22380)
# ?a317320[Condemn][Execute] is now usable on targets below s2 health.
Define(onslaught_talent 23372)
# Brutally attack an enemy for s1 Physical damage. Requires Enrage.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
Define(ravager_talent_protection 22401)
# Throws a whirling weapon at the target location that chases nearby enemies, inflicting <damage> Physical damage to up to 156287s2 enemies over 12 seconds.rnrn|cFFFFFFFFGenerates 334934s1/10 Rage each time it deals damage.|r
Define(ravager_talent 21667)
# Throws a whirling weapon at the target location that chases nearby enemies, inflicting <damage> Physical damage and applying Deep Wounds to up to 156287s2 enemies over 12 seconds.rnrn|cFFFFFFFFGenerates 248439s1/10 Rage each time it deals damage.|r
Define(reckless_abandon_talent 22402)
# Recklessness generates s1/10 Rage and greatly empowers Bloodthirst and Raging Blow.
Define(rend_talent 19138)
# Wounds the target, causing s1 Physical damage instantly and an additional o2 Bleed damage over 15 seconds.rnrnIncreases critical damage you deal to the enemy by s3.
Define(siegebreaker_talent 16037)
# Break the enemy's defenses, dealing s1 Physical damage, and increasing your damage done to the target by 280773s1 for 10 seconds.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
Define(skullsplitter_talent 22371)
# Bash an enemy's skull, dealing s1 Physical damage.rnrn|cFFFFFFFFGenerates s2/10 Rage.|r
Define(storm_bolt_talent_fury 23093)
# Hurls your weapon at an enemy, causing s1 Physical damage and stunning for 4 seconds.
Define(storm_bolt_talent_arms 22789)
# Hurls your weapon at an enemy, causing s1 Physical damage and stunning for 4 seconds.
Define(storm_bolt_talent 22409)
# Hurls your weapon at an enemy, causing s1 Physical damage and stunning for 4 seconds.
Define(unstoppable_force_talent 22544)
# Avatar increases the damage of Thunder Clap by s1, and reduces its cooldown by s2.
Define(warbreaker_talent 22391)
# Smash the ground and shatter the armor of all enemies within A1 yds, dealing s1 Physical damage and increasing damage you deal to them by 208086s1 for 10 seconds.
Define(sudden_death_buff 280776)
Define(potion_of_spectral_strength_item 171275)
    ItemInfo(potion_of_spectral_strength_item cd=1 shared_cd="item_cd_4" proc=307164)
Define(potion_of_phantom_fire_item 171349)
    ItemInfo(potion_of_phantom_fire_item cd=300 shared_cd="item_cd_4" rppm=6 proc=307495)
Define(will_of_the_berserker_runeforge 6966)
Define(vicious_contempt_conduit 64)
    `;
    // END

    code += `
Define(merciless_bonegrinder_soulbind 335260)
Define(merciless_bonegrinder_buff 346574)
    SpellInfo(merciless_bonegrinder_buff duration=9)
    SpellAddBuff(bladestorm merciless_bonegrinder_buff add=1 enabled=(soulbind(merciless_bonegrinder_soulbind)))
    SpellAddBuff(bladestorm_arms merciless_bonegrinder_buff add=1 enabled=(soulbind(merciless_bonegrinder_soulbind)))
    SpellAddBuff(ravager merciless_bonegrinder_buff add=1 enabled=(soulbind(merciless_bonegrinder_soulbind)))
    SpellAddBuff(ravager_protection merciless_bonegrinder_buff add=1 enabled=(soulbind(merciless_bonegrinder_soulbind)))
SpellRequire(execute unusable set=1 enabled=(target.healthpercent() > 20))
SpellRequire(execute_fury unusable set=1 enabled=(target.healthpercent() > 20 and buffexpires(sudden_death_buff)))
SpellRequire(condemn unusable set=1 enabled=(not iscovenant("venthyr")))
SpellRequire(condemn unusable set=1 enabled=(target.healthpercent() > 20 and target.healthpercent() < 80))
SpellRequire(condemn_fury unusable set=1 enabled=(not iscovenant("venthyr")))
SpellRequire(condemn_fury unusable set=1 enabled=(target.healthpercent() > 20 and target.healthpercent() < 80 and buffexpires(sudden_death_buff)))
  `;

    scripts.registerScript("WARRIOR", undefined, name, desc, code, "include");
}
