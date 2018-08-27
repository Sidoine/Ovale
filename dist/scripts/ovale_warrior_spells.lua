local __exports = LibStub:NewLibrary("ovale/scripts/ovale_warrior_spells", 80000)
if not __exports then return end
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
__exports.register = function()
    local name = "ovale_warrior_spells"
    local desc = "[8.0.1] Ovale: Warrior spells"
    local code = [[Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you their power for 15 seconds.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
Define(avatar 107574)
# Transform into a colossus for 20 seconds, causing you to deal s1 increased damage and removing all roots and snares.rnrn|cFFFFFFFFGenerates s5/10 Rage.|r
  SpellInfo(avatar cd=90 duration=20 rage=-20 talent=avatar_talent)
  # Damage done increased by s1.
  SpellAddBuff(avatar avatar=1)
Define(berserking 26297)
# Increases your haste by s1 for 10 seconds.
  SpellInfo(berserking cd=180 duration=10 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking=1)
Define(bloodthirst 23881)
# Assault the target in a bloodthirsty craze, dealing s*<mult> Physical damage and restoring 117313s1 of your health.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(bloodthirst cd=4.5 rage=-8)
Define(bursting_blood 251316)
# Imbues your blood with heat for 25 seconds, giving your melee attacks a chance to create a burst of blood, dealing 265514s1 Physical damage split evenly amongst all nearby enemies.
  SpellInfo(bursting_blood duration=25 channel=25 gcd=0 offgcd=1)

Define(charge 100)
# Charge to an enemy, dealing 126664s2 Physical damage, rooting it for 1 second?s103828[, and stunning it for 0 second][].rnrn|cFFFFFFFFGenerates /10;s2 Rage.|r
  SpellInfo(charge cd=1.5 charge_cd=20 gcd=0.5 rage=-20)
Define(cleave 845)
# Strikes all enemies in front of you with a sweeping attack for s1 Physical damage. Hitting s2 or more targets inflicts Deep Wounds.
  SpellInfo(cleave rage=20 cd=9 talent=cleave_talent)
Define(colossus_smash 167105)
# Smashes the enemy's armor, dealing s1 Physical damage, and increasing damage you deal to them by 208086s1 for 10 seconds.
  SpellInfo(colossus_smash cd=45)
Define(crushing_assault_buff 278824)
# Your melee abilities have a chance to increase the damage of your next Slam by s1 and reduce its Rage cost by s2/10.
  SpellInfo(crushing_assault_buff channel=-0.001 gcd=0 offgcd=1)

Define(deadly_calm 262228)
# Reduces the Rage cost of your abilities by s1 for 6 seconds.
  SpellInfo(deadly_calm cd=60 duration=6 gcd=0 offgcd=1 talent=deadly_calm_talent)
  # Your abilities cost s1 less Rage.
  SpellAddBuff(deadly_calm deadly_calm=1)
Define(dragon_roar 118000)
# Roar explosively, dealing m1 Physical damage to all enemies within A1 yds and reducing their movement speed by s3 for 6 seconds.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(dragon_roar cd=35 duration=6 rage=-10 talent=dragon_roar_talent_protection)
  # Movement slowed by s3.
  SpellAddTargetDebuff(dragon_roar dragon_roar=1)
Define(execute 5308)
# Attempt to finish off a wounded foe, causing 280849sw1+163558sw1 Physical damage. Only usable on enemies that have less than 20 health.rnrn|cFFFFFFFFGenerates m3/10 Rage.|r
# Rank 2: If your foe survives your Execute, 163201s2 of the Rage spent is refunded.
  SpellInfo(execute cd=6 rage=-20)

Define(execute_arms 163201)
# Attempts to finish off a foe, causing up to <damage> Physical damage based on Rage spent. Only usable on enemies that have less than 20 health.?s231830[rnrnIf your foe survives, s2 of the Rage spent is refunded.][]
  SpellInfo(execute_arms rage=20)

Define(executioners_precision_buff 272867)
# Execute increases the damage of your next Mortal Strike against the target by s1, stacking up to 272870u times.
  SpellInfo(executioners_precision_buff channel=-0.001 gcd=0 offgcd=1)

Define(fireblood 265221)
# Removes all poison, disease, curse, magic, and bleed effects and increases your ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by 265226s1*3 and an additional 265226s1 for each effect removed. Lasts 8 seconds. 
  SpellInfo(fireblood cd=120 gcd=0 offgcd=1)
Define(fujiedas_fury_buff 207776)
# Bloodthirst increases all damage you deal and all healing you take by 207776s1 for 10 seconds, stacking up to 207776u times.
  SpellInfo(fujiedas_fury_buff duration=10 max_stacks=4 gcd=0 offgcd=1)
  # All damage done increased by s1.rnAll healing taken increased by s2.
  SpellAddBuff(fujiedas_fury_buff fujiedas_fury_buff=1)
Define(furious_slash 100130)
# Aggressively strike with your off-hand weapon for s1*<mult> Physical damage, and increases your Haste by 202539s3 for 15 seconds, stacking up to 202539u times.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(furious_slash rage=-4 talent=furious_slash_talent)
  # Haste increased by s2.
  SpellAddBuff(furious_slash furious_slash_buff=1)
Define(furious_slash_buff 202539)
# Aggressively strike with your off-hand weapon for s1*<mult> Physical damage, and increases your Haste by 202539s3 for 15 seconds, stacking up to 202539u times.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(furious_slash_buff duration=15 max_stacks=3 gcd=0 offgcd=1)
  # Haste increased by s2.
  SpellAddBuff(furious_slash_buff furious_slash_buff=1)
Define(heroic_leap 6544)
# Leap through the air toward a target location, slamming down with destructive force to deal 52174s1 Physical damage to all enemies within 52174a1 yards?s23922[, and resetting the remaining cooldown on Taunt][].
  SpellInfo(heroic_leap cd=0.8 charge_cd=45 gcd=0 offgcd=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)

Define(mortal_strike 12294)
# A vicious strike that deals s1 Physical damage and reduces the effectiveness of healing on the target by 115804s1 for 10 seconds.
  SpellInfo(mortal_strike rage=30 cd=6)
Define(overpower 7384)
# Overpower the enemy, dealing s1 Physical damage. Cannot be blocked, dodged, or parried.rnrnIncreases the damage of your next Mortal Strike by s2, stacking up to u times.
  SpellInfo(overpower cd=12 duration=15 max_stacks=2)
  # Your next Mortal Strike will deal w2 increased damage.
  SpellAddBuff(overpower overpower=1)
Define(pummel 6552)
# Pummels the target, interrupting spellcasting and preventing any spell in that school from being cast for 4 seconds.
# Rank 1: Pummel the target for s2 damage and interrupt the spell being cast for 5 seconds.
  SpellInfo(pummel cd=15 duration=4 gcd=0 offgcd=1 interrupt=1)
Define(raging_blow 85288)
# A mighty blow with both weapons that deals a total of (96103sw1+85384sw1)*<mult> Physical damage.rnrnRaging Blow has a s1 chance to instantly reset its own cooldown.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(raging_blow cd=8 rage=-12)

Define(rampage 184367)
# Enrages you and unleashes a series of s1 brutal strikes for a total of <damage> Physical damage.
  SpellInfo(rampage rage=85)

Define(ravager 152277)
# Throws a whirling weapon at the target location that inflicts 7*156287s1 damage to all enemies within 156287A1 yards over 7 seconds. ?a137048[rnrnAlso increases your Parry chance by 227744s1 for 12 seconds.][rnrn|cFFFFFFFFGenerates 248439s1/10 Rage each time it deals damage.|r]
  SpellInfo(ravager cd=60 duration=7 tick=1 talent=ravager_talent)
  # ?s23922[Chance to Parry increased by s1.][Ravager is currently active.]
  SpellAddBuff(ravager ravager=1)
Define(recklessness 1719)
# Go berserk, increasing all Rage generation by s4 and granting your abilities s1 increased critical strike chance for 10 seconds.?a202751[rnrn|cFFFFFFFFGenerates 202751s2/10 Rage.|r][]
  SpellInfo(recklessness cd=90 duration=10 rage=0)
  # Rage generation increased by s5.rnCritical strike chance of all abilities increased by w1.
  SpellAddBuff(recklessness recklessness=1)
Define(rend 772)
# Wounds the target, causing s1 Physical damage instantly and an additional o2 Bleed damage over 12 seconds.
  SpellInfo(rend rage=30 duration=12 tick=3 talent=rend_talent)
  # Bleeding for w2 damage every t2 sec.
  SpellAddTargetDebuff(rend rend=1)
Define(siegebreaker 280772)
# Break the enemy's defenses, dealing s1 Physical damage, and increasing your damage done to the target by 280773s1 for 10 seconds.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
  SpellInfo(siegebreaker cd=30 rage=-10 talent=siegebreaker_talent)
Define(skullsplitter 260643)
# Bash an enemy's skull, dealing s1 Physical damage.rnrn|cFFFFFFFFGenerates s2/10 Rage.|r
  SpellInfo(skullsplitter cd=21 rage=-20 talent=skullsplitter_talent)
Define(slam 1464)
# Slams an opponent, causing s1 Physical damage.
  SpellInfo(slam rage=20)
Define(sweeping_strikes 260708)
# For 12 seconds your single-target damaging abilities hit s1 additional Ltarget:targets; within 8 yds for s2 damage.
  SpellInfo(sweeping_strikes cd=30 duration=12)
  # Your single-target damaging abilities hit s1 additional Ltarget:targets; within 8 yds for s2 damage.
  SpellAddBuff(sweeping_strikes sweeping_strikes=1)
Define(test_of_might_buff 275531)
# When ?s262161[Warbreaker][Colossus Smash] expires, your Strength is increased by s1 for every s2 Rage you spent during ?s262161[Warbreaker][Colossus Smash]. Lasts 12 seconds.
  SpellInfo(test_of_might_buff channel=-0.001 gcd=0 offgcd=1)

Define(warbreaker 209577)
# Stomp the ground, causing a ring of corrupted spikes to erupt upwards, dealing sw1 Shadow damage and applying the Colossus Smash effect to all nearby enemies.
  SpellInfo(warbreaker cd=60)
Define(whirlwind_buff 199658)
# Unleashes a whirlwind of steel, ?s202316[hitting your primary target with Slam and ][]striking all enemies within 199658A1 yards for <baseDmg> Physical damage.
  SpellInfo(whirlwind_buff gcd=0 offgcd=1)
Define(whirlwind_fury 190411)
# Unleashes a whirlwind of steel, striking all enemies within 199658A1 yards for 3*(199667sw2+44949sw2) Physical damage.?a12950[rnrnCauses your next s7 single-target lattack:attacks; to strike up to 85739s1 additional targets for 85739s3 damage.][]rnrn|cFFFFFFFFGenerates m8 Rage, plus an additional m9 per target hit. Maximum m10 Rage.|r
  SpellInfo(whirlwind_fury)

Define(avatar_talent 17) #22397
# Transform into a colossus for 20 seconds, causing you to deal s1 increased damage and removing all roots and snares.rnrn|cFFFFFFFFGenerates s5/10 Rage.|r
Define(carnage_talent 13) #22383
# Rampage costs s1/-10 less Rage and deals s4 increased damage.
Define(cleave_talent 15) #22362
# Strikes all enemies in front of you with a sweeping attack for s1 Physical damage. Hitting s2 or more targets inflicts Deep Wounds.
Define(deadly_calm_talent 18) #22399
# Reduces the Rage cost of your abilities by s1 for 6 seconds.
Define(dragon_roar_talent_protection 9) #23260
# Roar explosively, dealing m1 Physical damage to all enemies within A1 yds and reducing their movement speed by s3 for 6 seconds.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
Define(dreadnaught_talent 20) #22407
# Overpower has 1+s1 charges, and it increases the damage of your next Mortal Strike by an additional s2.
Define(fervor_of_battle_talent 8) #22489
# Whirlwind deals s1 increased damage, and Slams your primary target.
Define(frothing_berserker_talent 15) #19140
# Rampage now costs s1/10 Rage and increases your damage done by 215572s1 and Haste by 215572s2 for 6 seconds.
Define(furious_slash_talent 9) #23372
# Aggressively strike with your off-hand weapon for s1*<mult> Physical damage, and increases your Haste by 202539s3 for 15 seconds, stacking up to 202539u times.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
Define(massacre_talent_fury 14) #22393
# Execute is now usable on targets below s2 health.
Define(ravager_talent 21) #21667
# Throws a whirling weapon at the target location that inflicts 7*156287s1 damage to all enemies within 156287A1 yards over 7 seconds. ?a137048[rnrnAlso increases your Parry chance by 227744s1 for 12 seconds.][rnrn|cFFFFFFFFGenerates 248439s1/10 Rage each time it deals damage.|r]
Define(rend_talent 9) #19138
# Wounds the target, causing s1 Physical damage instantly and an additional o2 Bleed damage over 12 seconds.
Define(siegebreaker_talent 21) #16037
# Break the enemy's defenses, dealing s1 Physical damage, and increasing your damage done to the target by 280773s1 for 10 seconds.rnrn|cFFFFFFFFGenerates m2/10 Rage.|r
Define(skullsplitter_talent 3) #22371
# Bash an enemy's skull, dealing s1 Physical damage.rnrn|cFFFFFFFFGenerates s2/10 Rage.|r
Define(warbreaker_talent 14) #22391
# Smash the ground and shatter the armor of all enemies within A1 yds, dealing s1 Physical damage and increasing damage you deal to them by 208086s1 for 10 seconds.
Define(kazzalax_fujiedas_fury_item 137053)
Define(test_of_might_trait 275529)
    ]]
    code = code .. [[
ItemRequire(shifting_cosmic_sliver unusable 1=oncooldown,!shield_wall,buff,!shield_wall_buff)	
	
# Warrior spells and functions.

# Learned spells.

	SpellInfo(avatar rage=-20 cd=90)
	SpellAddBuff(avatar avatar_buff=1)
Define(avatar_buff 107574)
	SpellInfo(avatar_buff duration=20)
Define(battle_shout 6673)
	SpellAddBuff(battle_shout battle_shout_buff=1)
Define(battle_shout_buff 6673)
Define(berserker_rage 18499)
	SpellInfo(berserker_rage cd=60 gcd=0)
	SpellInfo(berserker_rage rage=-20 itemset=T20 itemcount=2 specialization=protection)
	SpellAddBuff(berserker_rage berserker_rage_buff=1)
Define(berserker_rage_buff 18499)
	SpellInfo(berserker_rage_buff duration=6)
Define(bladestorm_arms 227847)
	SpellInfo(bladestorm_arms cd=90 channel=6 haste=melee replace=ravager)
Define(bladestorm_fury 46924)
	SpellInfo(bladestorm_fury cd=60 channel=4 haste=melee)

	SpellInfo(bloodthirst cd=4.5 rage=-8 cd_haste=melee)
	SpellAddBuff(bloodthirst whirlwind_buff=-1)
 
	SpellInfo(charge cd=20 gcd=0 offgcd=1 rage=-25 travel_time=1 charges=1)
	SpellInfo(charge add_cd=-3 charges=2 talent=double_time_talent)
	SpellAddTargetDebuff(charge charge_debuff=1)
Define(charge_debuff 105771)

	SpellInfo(cleave cd=9 cd_haste=melee rage=20)
	SpellRequire(cleave rage_percent 0=buff,deadly_calm_buff talent=deadly_calm_talent specialization=arms)

	
	SpellInfo(colossus_smash replace=warbreaker talent=warbreaker_talent)
	SpellAddTargetDebuff(colossus_smash colossus_smash_debuff=1)
	SpellAddBuff(colossus_smash in_for_the_kill_buff=1 talent=in_for_the_kill_talent)
Define(colossus_smash_debuff 208086)
	SpellInfo(colossus_smash_debuff duration=10)

	SpellInfo(deadly_calm cd=60)
    SpellAddBuff(deadly_calm deadly_calm_buff=1)
Define(deadly_calm_buff 262228)
    SpellInfo(deadly_calm_buff duration=6)
Define(deep_wounds_prot_debuff 115767)
	SpellInfo(deep_wounds_prot_debuff duration=15 tick=3 haste=meleen)
Define(deep_wounds_arms_debuff 262115)
	SpellInfo(deep_wounds_arms_debuff duration=6 tick=2 haste=meleen)
Define(defensive_stance 197690)
	SpellInfo(defensive_stance cd=6)
	SpellAddBuff(defensive_stance defensive_stance_buff=1)
Define(defensive_stance_buff 197690)
Define(demoralizing_shout 1160)
	SpellInfo(demoralizing_shout cd=45)
	SpellInfo(demoralizing_shout add_rage=-40 talent=booming_voice_talent)
	SpellAddTargetDebuff(demoralizing_shout demoralizing_shout_debuff=1)
Define(demoralizing_shout_debuff 1160)
	SpellInfo(demoralizing_shout_debuff duration=8)
Define(devastate 20243)
	SpellInfo(devastate unusable=1 talent=devastator_talent)
	SpellAddTargetDebuff(devastate deep_wounds_prot_debuff=1 specialization=protection)
Define(die_by_the_sword 118038)
	SpellInfo(die_by_the_sword cd=180 gcd=0 offgcd=1)
	SpellAddBuff(die_by_the_sword die_by_the_sword_buff=1)
Define(die_by_the_sword_buff 118038)
	SpellInfo(die_by_the_sword_buff duration=8)

	SpellInfo(dragon_roar cd=35 rage=-10)
	SpellAddBuff(dragon_roar dragon_roar_buff=1)
Define(dragon_roar_buff 118000)
	SpellInfo(dragon_roar_buff duration=6)
Define(enrage_buff 184362)
	SpellInfo(enrage_buff duration=4 enrage=1)
Define(enraged_regeneration 184364)
	SpellInfo(enraged_regeneration cd=120 gcd=0 offgcd=1)
	SpellAddBuff(enraged_regeneration enraged_regeneration_buff=1)
Define(enraged_regeneration_buff 184364)
	SpellInfo(enraged_regeneration_buff duration=8)

	SpellInfo(execute_arms rage=20 max_rage=40 target_health_pct=20)
	SpellInfo(execute_arms target_health_pct=35 talent=arms_massacre_talent)
	SpellRequire(execute_arms rage_percent 0=buff,execute_arms_norage)
	SpellRequire(execute_arms target_health_pct 100=buff,execute_arms_nohp)
SpellList(execute_arms_norage sudden_death_arms_buff stone_heart_buff deadly_calm_buff)
SpellList(execute_arms_nohp sudden_death_arms_buff stone_heart_buff)

	SpellInfo(execute rage=-20 target_health_pct=20)
	SpellInfo(execute target_health_pct=35 talent=massacre_talent_fury)
	SpellRequire(execute target_health_pct 100=buff,execute_free)
	SpellRequire(execute cd_percent 0=buff,execute_free)
SpellList(execute_free sudden_death_fury_buff stone_heart_buff)
Define(frothing_berserker_buff 215572)
	SpellInfo(frothing_berserker_buff duration=6)
Define(frenzy_buff 202539)
	SpellInfo(frenzy_buff duration=15 max_stacks=3)

	SpellAddBuff(furious_slash frenzy_buff=1)
Define(hamstring 1715)
	SpellInfo(hamstring cd=1 rage=10)
	SpellAddTargetDebuff(hamstring hamstring_debuff=1)
Define(hamstring_debuff 1715)
	SpellInfo(hamstring_debuff duration=15)

	SpellInfo(heroic_leap cd=45 gcd=0 offgcd=1 travel_time=1)
	SpellInfo(heroic_leap add_cd=-15 talent=bounding_stride_talent specialization=!protection)
	SpellInfo(heroic_leap add_cd=-15 talent=prot_bounding_stride_talent specialization=protection)
	SpellAddBuff(heroic_leap heroic_leap_buff=1 talent=bounding_stride_talent specialization=!protection)
	SpellAddBuff(heroic_leap heroic_leap_buff=1 talent=prot_bounding_stride_talent specialization=protection)
Define(heroic_leap_buff 202164)
Define(heroic_throw 57755)
	SpellInfo(heroic_throw cd=6 travel_time=1)
	SpellInfo(heroic_throw add_cd=-6 specialization=protection)
Define(ignore_pain 190456)
	SpellInfo(ignore_pain rage=40)
	SpellAddBuff(ignore_pain ignore_pain_buff=1)
	SpellAddBuff(ignore_pain vengeance_ignore_pain_buff=0 talent=vengeance_talent)
	SpellAddBuff(ignore_pain vengeance_revenge_buff=1 talent=vengeance_talent)
Define(ignore_pain_buff 190456)
	SpellInfo(ignore_pain duration=12)
Define(impending_victory 202168)
	SpellInfo(impending_victory rage=10 cd=30)
	SpellRequire(impending_victory cd_percent 0=victorious_buff)
	SpellAddBuff(impending_victory victorious_buff=0)
Define(in_for_the_kill_buff 248622)
	SpellInfo(in_for_the_kill_buff duration=8)
Define(intercept 198304)
	SpellInfo(intercept cd=15 rage=-20 charges=2)
	SpellAddTargetDebuff(intercept charge_debuff=1)
	SpellAddTargetBuff(intercept safeguard_buff=1)
Define(intimidating_shout 5246)
Define(into_the_fray_buff 202602)
Define(last_stand 12975)
	SpellInfo(last_stand cd=180)
	SpellInfo(last_stand add_cd=-60 talent=bolster_talent)
	SpellAddBuff(last_stand last_stand_buff=1)
Define(last_stand_buff 12975)
	SpellInfo(last_stand_buff duration=15)

	SpellInfo(mortal_strike cd=6 cd_haste=melee rage=30)
	SpellRequire(mortal_strike rage_percent 0=buff,deadly_calm_buff talent=deadly_calm_talent specialization=arms)
	SpellAddTargetDebuff(mortal_strike mortal_wounds_debuff=1)
	SpellAddBuff(mortal_strike overpower_buff=0)
Define(mortal_wounds_debuff 115804)
	SpellInfo(mortal_wounds_debuff duration=10)

	SpellInfo(overpower cd=12)
	SpellInfo(overpower charges=2 talent=dreadnaught_talent)
	SpellAddBuff(overpower overpower_buff=1)
Define(overpower_buff 7384)
	SpellInfo(overpower_buff duration=15 max_stacks=2)
Define(piercing_howl 12323)
	SpellInfo(piercing_howl rag=10)
	SpellAddBuff(piercing_howl piercing_howl_debuff=1)
Define(piercing_howl_debuff 12323)
	SpellInfo(piercing_howl_debuff duration=15)

	SpellInfo(pummel cd=15 gcd=0 interrupt=1 offgcd=1)
Define(punish_debuff 275335)
	SpellInfo(punish_debuff duration=9)

	SpellInfo(raging_blow rage=-12 cd=7 charges=2 cd_haste=melee)
	SpellInfo(raging_blow add_cd=-1 talent=inner_rage_talent)
Define(rallying_cry 97462)
	SpellInfo(rallying_cry cd=180)
	SpellAddBuff(rallying_cry rallying_cry_buff=1)
Define(rallying_cry_buff 97462)
	SpellInfo(rallying_cry_buff duration=10)

	SpellInfo(rampage gcd=1.5 cd_haste=none rage=85)
	SpellInfo(rampage add_rage=-10 talent=carnage_talent)
	SpellInfo(rampage add_rage=10 talent=frothing_berserker_talent)
	SpellAddBuff(rampage enrage_buff=1)
	SpellAddBuff(rampage frothing_berserker_buff=1 talent=frothing_berserker_talent)
	SpellAddBuff(rampage whirlwind_buff=-1)

	SpellInfo(ravager cd=60)
	SpellInfo(ravager ravager_buff=1)
	SpellAddTargetDebuff(ravager deep_wounds_arms_debuff=1)
Define(ravager_prot 228920)
	SpellInfo(ravager_prot cd=60)
	SpellAddBuff(ravager_prot ravager_prot_buff=1)
Define(ravager_prot_buff 227744)
	SpellInfo(ravager_prot_buff duration=12)

	SpellInfo(recklessness cd=90 tag=cd)
	SpellAddBuff(recklessness recklessness_buff=1)
Define(recklessness_buff 1719)
	SpellInfo(recklessness_buff duration=10)
	SpellInfo(recklessness_buff add_rage=-100 add_duration=4 talent=reckless_abandon_talent)

	SpellInfo(rend rage=30)
	SpellRequire(rend rage_percent 0=buff,deadly_calm_buff talent=deadly_calm_talent specialization=arms)
Define(rend_debuff 772)
	SpellInfo(rend_debuff duration=12 tick=3)
Define(revenge 6572)
	SpellInfo(revenge cd=3 rage=30 cd_haste=melee)
	SpellRequire(revenge rage_percent 0=buff,revenge_buff)
	SpellAddTargetDebuff(revenge deep_wounds_prot_debuff=1)
	SpellAddBuff(revenge revenge_buff=0)
	SpellAddBuff(revenge vengeance_ignore_pain_buff=1 talent=vengeance_talent)
	SpellAddBuff(revenge vengeance_revenge_buff=0 talent=vengeance_talent)
Define(revenge_buff 5302)
	SpellInfo(revenge_buff duration=6)
Define(safeguard_buff 223658)
	SpellInfo(safeguard_buff duration=6)
Define(shield_block 2565)
	SpellInfo(shield_block cd=18 cd_haste=melee gcd=0 offgcd=1 rage=30)
	SpellAddBuff(shield_block shield_block_buff=1)
Define(shield_block_buff 132404)
	SpellInfo(shield_block_buff duration=6)
Define(shield_slam 23922)
	SpellInfo(shield_slam cd=9 cd_haste=melee rage=-15)
	SpellAddTargetDebuff(shield_slam punish_debuff=1 talent=punish_talent)
Define(shield_wall 871)
	SpellInfo(shield_wall cd=240 gcd=0 offgcd=1)
	SpellAddBuff(shield_wall shield_wall_buff=1)
Define(shield_wall_buff 871)
	SpellInfo(shield_wall duration=8)
Define(shockwave 46968)
	SpellInfo(shockwave cd=40)

	SpellInfo(siegebreaker cd=30 rage=-10)
	SpellAddTargetDebuff(siegebreaker siegebreaker_debuff=1)
Define(siegebreaker_debuff 280773)
	SpellInfo(siegebreaker_debuff duration=10)

	SpellInfo(skullsplitter cd=21 rage=-20 cd_haste=melee)

	
	SpellRequire(slam rage_percent 0=buff,deadly_calm_buff talent=deadly_calm_talent specialization=arms)
Define(spell_reflection 23920)
	SpellInfo(spell_reflection cd=25)
	SpellAddBuff(spell_reflection spell_reflection_buff=1)
Define(spell_reflection_buff 23920)
Define(storm_bolt 107570)
	SpellInfo(storm_bolt cd=30)
Define(sudden_death_arms_buff 52437)
	SpellInfo(sudden_death_arms_buff duration=10)
Define(sudden_death_fury_buff 280776)
	SpellInfo(sudden_death_fury_buff duration=10)

	SpellInfo(sweeping_strikes cd=25)
	SpellAddBuff(sweeping_strikes sweeping_strikes_buff=1)
Define(sweeping_strikes_buff 260708)
	SpellInfo(sweeping_strikes_buff duration=12)
Define(taunt 355)
	SpellInfo(taunt cd=8)
Define(thunder_clap 6343)
	SpellInfo(thunder_clap cd=6 rage=-5 cd_haste=melee)
	SpellRequire(thunder_clap cd_percent 50=buff,avatar_buff)
Define(vengeance_ignore_pain_buff 202574)
	SpellInfo(vengeance_ignore_pain_buff duration=15)
Define(vengeance_revenge_buff 202573)
	SpellInfo(vengeance_revenge_buff duration=15)
Define(victorious_buff 32216)
	SpellInfo(victorious_buff duration=20)
Define(victory_rush 34428)
	SpellRequire(victory_rush unusable 1=buff,!victorious_buff)
	SpellAddBuff(victory_rush victorious_buff=0)

	SpellInfo(warbreaker cd=45 tag=main)
	SpellAddTargetDebuff(warbreaker colossus_smash_debuff=1)
	SpellAddBuff(warbreaker in_for_the_kill_buff=1 talent=in_for_the_kill_talent)

	SpellAddBuff(whirlwind_fury whirlwind_buff=2)
Define(whirlwind_arms 1680)
	SpellInfo(whirlwind_arms rage=30)
Define(whirlwind_buff 85739)
	SpellInfo(whirlwind_buff duration=20)

# Legion legendary items

Define(archavons_heavy_hand_spell 205144)
	# TODO Mortal strike refunds 15 rage

	SpellAddBuff(bloodthirst fujiedas_fury_buff=1 if_spell=fujiedas_fury_buff)

Define(ayalas_stone_heart_item 137052)
Define(stone_heart_buff 225947)
	SpellAddBuff(execute_arms stone_heart_buff=0)
	SpellAddBuff(execute stone_heart_buff=0)
Define(the_great_storms_eye_item 151823)


# Talents
Define(anger_management_talent 19)
Define(arms_massacre_talent 7)

Define(best_served_cold_talent 7)
Define(bladestorm_talent 18)
Define(bolster_talent 12)
Define(booming_voice_talent 16)
Define(bounding_stride_talent 11)


Define(collateral_damage_talent 13)
Define(crackling_thunder_talent 4)

Define(defensive_stance_talent 12)
Define(devastator_talent 18)
Define(double_time_talent 4)
Define(dragon_roar_talent 17)

Define(endless_rage_talent 2)

Define(fresh_meat_talent 3)

Define(furious_charge_talent 10)

Define(fury_anger_management_talent 20)
Define(fury_sudden_death_talent 8)
Define(heavy_repercussions_talent 20)
Define(impending_victory_talent 3)
Define(impending_victory_talent 5)
Define(in_for_the_kill_talent 16)
Define(indomitable_talent 10)
Define(inner_rage_talent 7)
Define(into_the_fray_talent 1)

Define(meat_cleaver_talent 16)
Define(menace_talent 13)
Define(never_surrender_talent 11)
Define(prot_bounding_stride_talent 5)
Define(prot_dragon_roar_talent 9)
Define(prot_storm_bolt_talent 15)
Define(punish_talent 2)

Define(reckless_abandon_talent 19)

Define(rumbling_earth_talent 14)
Define(safeguard_talent 6)
Define(second_wind_talent 10)


Define(storm_bolt_talent 6)
Define(sudden_death_talent 2)
Define(unstoppable_force_talent 8)
Define(vengeance_talent 17)
Define(war_machine_talent 1)

Define(warpaint_talent 12)

# Non-default tags for OvaleSimulationCraft.
	SpellInfo(heroic_throw tag=main)
	SpellInfo(impending_victory tag=main)
	SpellInfo(colossus_smash tag=main)
	SpellInfo(hamstring tag=shortcd)
	SpellInfo(avatar tag=cd)
	SpellInfo(intercept tag=misc)
]]
    OvaleScripts:RegisterScript("WARRIOR", nil, name, desc, code, "include")
end
