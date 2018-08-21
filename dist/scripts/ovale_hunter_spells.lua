local __exports = LibStub:NewLibrary("ovale/scripts/ovale_hunter_spells", 80000)
if not __exports then return end
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
__exports.register = function()
    local name = "ovale_hunter_spells"
    local desc = "[8.0] Ovale: Hunter spells"
    local code = [[Define(a_murder_of_crows 131900)
# Deals s1 physical damage.
  SpellInfo(a_murder_of_crows gcd=0 offgcd=1)
Define(aimed_shot 19434)
# A powerful aimed shot that deals s1*<mult> Physical damage. Damage increased by s2 against a target you have not yet damaged. ?!s19434&c1[rnrnReplaces Cobra Shot.][]
  SpellInfo(aimed_shot focus=30 cd=12)
Define(ancestral_call 274738)
# Invoke the spirits of your ancestors, granting you their power for 274739d.
  SpellInfo(ancestral_call cd=120 duration=15 gcd=0 offgcd=1)
  SpellAddBuff(ancestral_call ancestral_call=1)
Define(arcane_shot 185358)
# A quick shot that causes sw2*<mult> Arcane damage.
  SpellInfo(arcane_shot focus=15)
Define(aspect_of_the_eagle 186289)
# Increases the range of your ?s259387[Mongoose Bite][Raptor Strike] to 265189r yds for d.
  SpellInfo(aspect_of_the_eagle cd=90 duration=15 gcd=0 offgcd=1)
  # The range of ?s259387[Mongoose Bite][Raptor Strike] is increased to 265189r yds.
  SpellAddBuff(aspect_of_the_eagle aspect_of_the_eagle=1)
Define(aspect_of_the_wild 193530)
# Grants you and your pet s2 Focus per sec and s1 increased critical strike chance for d.
  SpellInfo(aspect_of_the_wild cd=120 duration=20 gcd=1.3 tick=1)
  # Gaining s2 Focus per sec.rnCritical Strike chance increased by s1.
  SpellAddBuff(aspect_of_the_wild aspect_of_the_wild=1)
Define(barbed_shot 217200)
# Fire a shot that tears through your enemy, causing them to bleed for s1*d/t1 damage over d.rnrnSends your pet into a frenzy, increasing attack speed by 272790s1 for 272790d, stacking up to 272790u times.rnrn|cFFFFFFFFGenerates 246152s1*246152d/246152t1 Focus over 246152d.|r
  SpellInfo(barbed_shot cd=12 duration=8 tick=2)
  # Suffering sw1 damage every t1 sec.
  SpellAddTargetDebuff(barbed_shot barbed_shot=1)
Define(barrage 120360)
# Rapidly fires a spray of shots for 120360d, dealing an average of <damageSec> Physical damage to all enemies in front of you. Usable while moving.
  SpellInfo(barrage focus=60 cd=20 duration=3 channel=3 talent=barrage_talent tick=0.2)
Define(berserking 26297)
# Increases your haste by s1 for d.
  SpellInfo(berserking cd=180 duration=10 gcd=0 offgcd=1)
  # Haste increased by s1.
  SpellAddBuff(berserking berserking=1)
Define(berserking_buff 200953)
# @spelldesc200845
  SpellInfo(berserking_buff duration=3 max_stacks=12 gcd=0 offgcd=1)
  # Attack speed and critical strike chance increased by s1.
  SpellAddBuff(berserking_buff berserking_buff=1)
Define(bestial_wrath 231548)
# Bestial Wrath's remaining cooldown is reduced by 19574s3 sec each time you use Barbed Shot.
  SpellInfo(bestial_wrath channel=0 gcd=0 offgcd=1)
  SpellAddBuff(bestial_wrath bestial_wrath=1)
Define(butchery 212436)
# Strike all nearby enemies in a flurry of strikes, inflicting s1 Physical damage to each.rnrnReduces the remaining cooldown on Wildfire Bomb by <cdr> sec for each target hit, up to s3.
  SpellInfo(butchery focus=30 cd=9 talent=butchery_talent)
Define(carve 187708)
# A sweeping attack that strikes all enemies in front of you for s1 Physical damage.rnrnReduces the remaining cooldown on Wildfire Bomb by <cdr> sec for each target hit, up to s3.
  SpellInfo(carve focus=35 cd=6)
Define(chakrams 267666)
# @spelldesc259381
  SpellInfo(chakrams gcd=0 offgcd=1)
Define(chimaera_shot 171457)
# @spelldesc53209
  SpellInfo(chimaera_shot gcd=0 offgcd=1)
Define(cobra_shot 193455)
# A quick shot causing s2*<mult> Physical damage.rnrnReduces the cooldown of Kill Command by s3 sec.
  SpellInfo(cobra_shot focus=45)
Define(coordinated_assault 266779)
# You and your pet attack as one, increasing all damage you both deal by s1 for d.?s263186[rnrnWhile Coordinated Assault is active, Kill Command's chance to reset is increased by s4.][]
  SpellInfo(coordinated_assault cd=120 duration=20)
  # Damage dealt increased by s1.?s263186[rnKill Command's chance to reset increased by s4.][]
  SpellAddBuff(coordinated_assault coordinated_assault=1)
Define(dire_beast 120679)
# Summons a powerful wild beast that attacks the target and roars, increasing your Haste by 281036s1 for d.
  SpellInfo(dire_beast focus=25 cd=20 duration=8 talent=dire_beast_talent)
  SpellAddTargetDebuff(dire_beast dire_beast=1)
Define(double_tap 260402)
# Your next Aimed Shot will fire a second time instantly at s4 power without consuming Focus, or your next Rapid Fire will shoot s3 additional shots during its channel.
  SpellInfo(double_tap cd=60 duration=15 talent=double_tap_talent)
  # Your next Aimed Shot will fire a second time instantly at s4 power and consume no Focus, or your next Rapid Fire will shoot s3 additional shots during its channel.
  SpellAddBuff(double_tap double_tap=1)
Define(explosive_shot 212431)
# Fires a slow-moving munition directly forward. Activating this ability a second time detonates the Shot, dealing up to 212680s1 Fire damage to all enemies within 212680A1 yds.rnrnIf you do not detonate Explosive Shot, 269850s1 Focus and some of the cooldown will be refunded.
  SpellInfo(explosive_shot focus=20 cd=30 duration=4 talent=explosive_shot_talent)
  SpellAddBuff(explosive_shot explosive_shot=1)
Define(fireblood 265226)
# Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by s1.
  SpellInfo(fireblood duration=8 max_stacks=6 gcd=0 offgcd=1)
  # Increases ?a162700[Agility]?a162702[Strength]?a162697[Agility]?a162698[Strength]?a162699[Intellect]?a162701[Intellect][primary stat] by w1.
  SpellAddBuff(fireblood fireblood=1)
Define(flanking_strike 269752)
# @spelldesc269751
  SpellInfo(flanking_strike gcd=0 offgcd=1 focus=-30)
Define(harpoon 190925)
# Hurls a harpoon at an enemy, rooting them in place for 190927d and pulling you to them.
  SpellInfo(harpoon cd=1 cd=30 gcd=0.5)
Define(hunters_mark 259558)
# @spelldesc257284
  SpellInfo(hunters_mark channel=0 gcd=0 offgcd=1 focus=-20)
Define(kill_command 263186)
# Kill Command has a 259489s2 chance to immediately reset its cooldown.rnrnCoordinated Assault increases this chance by another 266779s4.
  SpellInfo(kill_command channel=0 gcd=0 offgcd=1)
  SpellAddBuff(kill_command kill_command=1)
Define(lethal_shots_buff 260395)
# @spelldesc260393
  SpellInfo(lethal_shots_buff duration=15 gcd=0 offgcd=1)
  # Your next Aimed Shot will have s1 increased critical strike chance, or your next Rapid Fire will deal a critical strike with each shot.
  SpellAddBuff(lethal_shots_buff lethal_shots_buff=1)
Define(lights_judgment 255647)
# Call down a strike of Holy energy, dealing <damage> Holy damage to enemies within A1 yards after 3 sec.
  SpellInfo(lights_judgment cd=150)
Define(mongoose_bite 265888)
# A brutal attack that deals sw1 Physical damage and grants you Mongoose Fury.rnrn|cFFFFFFFFMongoose Fury|rrnIncreases the damage of Mongoose Bite by 259388s1 for 259388d, stacking up to 259388u times. Successive attacks do not increase duration.
  SpellInfo(mongoose_bite focus=30)
Define(piercing_shot 198670)
# A powerful shot which deals sw3 Physical damage to the target and up to sw3/(s1/10) Physical damage to all enemies between you and the target. 
  SpellInfo(piercing_shot focus=35 cd=30 talent=piercing_shot_talent)
Define(bursting_blood 252343)
# Chance to create multiple potions.
  SpellInfo(bursting_blood gcd=0 offgcd=1)
Define(rising_death 269853)
# Empowers you with shadow magic for d, giving your ranged attacks a chance to send out a death bolt that grows in intensity as it travels, dealing up to 271292s1 Shadow damage.
  SpellInfo(rising_death duration=25 channel=25 gcd=0 offgcd=1)
Define(rapid_fire 257044)
# Shoot a stream of s1 shots at your target over d, dealing a total of m1*257045sw1 Physical damage. rnrnEach shot generates 263585s1 Focus.rnrnUsable while moving.
  SpellInfo(rapid_fire cd=20 duration=3 channel=3 tick=0.33)
Define(raptor_strike 265189)
# A vicious slash dealing s1 Physical damage.
  SpellInfo(raptor_strike focus=30)
Define(revive_pet 982)
# Revives your pet, returning it to life with s1 of its base health.
  SpellInfo(revive_pet focus=35 duration=3 channel=3)
  SpellAddBuff(revive_pet revive_pet=1)
Define(shrapnel_bomb_debuff 270336)
# @spelldesc270335
  SpellInfo(shrapnel_bomb_debuff duration=0.5 channel=0.5 gcd=0 offgcd=1)
Define(spitting_cobra 194407)
# Summons a Spitting Cobra for d that attacks your target for 206685s1 Nature damage every 2 sec. rnrnWhile the Cobra is active you gain s2 Focus every sec.
  SpellInfo(spitting_cobra cd=90 duration=20 talent=spitting_cobra_talent tick=1)
  # Generating s2 additional Focus every sec.
  SpellAddBuff(spitting_cobra spitting_cobra=1)
Define(stampede 201594)
# @spelldesc201430
  SpellInfo(stampede gcd=0 offgcd=1)
Define(steady_shot 56641)
# A steady shot that causes s1 Physical damage.rnrnUsable while moving.rnrn|cFFFFFFFFGenerates s2 Focus.
  SpellInfo(steady_shot)
Define(steel_trap 162488)
# Hurls a Steel Trap to the target location that snaps shut on the first enemy that approaches, immobilizing them for 162480d and causing them to bleed for 162487o1 damage over 162487d. rnrnDamage other than Steel Trap may break the immobilization effect. Trap will exist for 162496d. Limit 1.
  SpellInfo(steel_trap cd=30 talent=steel_trap_talent)
Define(trueshot 193526)
# Immediately gain s2 charge of Aimed Shot, and gain s1 Haste for d.
  SpellInfo(trueshot cd=180 duration=15)
  # Haste increased by s1 for d.
  SpellAddBuff(trueshot trueshot=1)
Define(vipers_venom_buff 268552)
# @spelldesc268501
  SpellInfo(vipers_venom_buff duration=8 channel=8 gcd=0 offgcd=1)
  # Your next Serpent Sting costs no Focus, and will deal s1 increased initial damage.
  SpellAddBuff(vipers_venom_buff vipers_venom_buff=1)
Define(wildfire_bomb_debuff 265163)
# @spelldesc259495
  SpellInfo(wildfire_bomb_debuff duration=0.5 channel=0.5 gcd=0 offgcd=1)
Define(wildfire_bomb 269747)
# @spelldesc259495
  SpellInfo(wildfire_bomb duration=6 channel=6 gcd=0 offgcd=1 tick=1)
  # Suffering w1 Fire damage every t1 sec.
  SpellAddTargetDebuff(wildfire_bomb wildfire_bomb=1)
Define(barrage_talent 17)
# Rapidly fires a spray of shots for 120360d, dealing an average of <damageSec> Physical damage to all enemies in front of you. Usable while moving.
Define(lethal_shots_talent 16)
# Steady Shot has a h chance to cause your next Aimed Shot or Rapid Fire to be guaranteed critical strikes.
Define(steady_focus_talent 10)
# Using Steady Shot reduces the cast time of Steady Shot by 193534s1, stacking up to 193534u times.  Using any other shot removes this effect.
Define(birds_of_prey_talent 19)
# Attacking your pet's target with ?s259387[Mongoose Bite][Raptor Strike] or ?s212436[Butchery][Carve] extends the duration of Coordinated Assault by <duration> sec.
Define(guerrilla_tactics_talent 4)
# Wildfire Bomb now has s1+1 charges, and the initial explosion deals s2 increased damage.
Define(mongoose_bite_talent 17)
# A brutal attack that deals s1 Physical damage and grants you Mongoose Fury.rnrn|cFFFFFFFFMongoose Fury|rrnIncreases the damage of Mongoose Bite by 259388s1 for 259388d, stacking up to 259388u times. Successive attacks do not increase duration.
Define(terms_of_engagement_talent 2)
# Harpoon deals 271625s1 Physical damage and generates (265898s1/5)*265898d Focus over 265898d. Killing an enemy resets the cooldown of Harpoon.
Define(vipers_venom_talent 1)
# ?s259387[Mongoose Bite][Raptor Strike] has a chance to make your next Serpent Sting cost no Focus and deal an additional 268552s1 initial damage.
Define(wildfire_infusion_talent 20)
# Lace your Wildfire Bomb with extra reagents, randomly giving it one of the following enhancements each time you throw it:rnrn|cFFFFFFFFShrapnel Bomb: |rShrapnel pierces the targets, causing ?s259387[Mongoose Bite][Raptor Strike] and ?s212436[Butchery][Carve] to apply a bleed for 270343d that stacks up to 270343u times.rnrn|cFFFFFFFFPheromone Bomb: |rKill Command has a 270323s2 chance to reset against targets coated with Pheromones.rnrn|cFFFFFFFFVolatile Bomb: |rReacts violently with poison, causing an extra explosion against enemies suffering from your Serpent Sting and refreshes your Serpent Stings.
Define(barrage_talent 17)
# Rapidly fires a spray of shots for 120360d, dealing an average of <damageSec> Physical damage to all enemies in front of you. Usable while moving.
Define(butchery_talent 6)
# Strike all nearby enemies in a flurry of strikes, inflicting s1 Physical damage to each.rnrnReduces the remaining cooldown on Wildfire Bomb by <cdr> sec for each target hit, up to s3.
Define(dire_beast_talent 3)
# Summons a powerful wild beast that attacks the target and roars, increasing your Haste by 281036s1 for d.
Define(double_tap_talent 18)
# Your next Aimed Shot will fire a second time instantly at s4 power without consuming Focus, or your next Rapid Fire will shoot s3 additional shots during its channel.
Define(explosive_shot_talent 6)
# Fires a slow-moving munition directly forward. Activating this ability a second time detonates the Shot, dealing up to 212680s1 Fire damage to all enemies within 212680A1 yds.rnrnIf you do not detonate Explosive Shot, 269850s1 Focus and some of the cooldown will be refunded.
Define(piercing_shot_talent 21)
# A powerful shot which deals sw3 Physical damage to the target and up to sw3/(s1/10) Physical damage to all enemies between you and the target. 
Define(spitting_cobra_talent 21)
# Summons a Spitting Cobra for d that attacks your target for 206685s1 Nature damage every 2 sec. rnrnWhile the Cobra is active you gain s2 Focus every sec.
Define(steel_trap_talent 11)
# Hurls a Steel Trap to the target location that snaps shut on the first enemy that approaches, immobilizing them for 162480d and causing them to bleed for 162487o1 damage over 162487d. rnrnDamage other than Steel Trap may break the immobilization effect. Trap will exist for 162496d. Limit 1.
Define(focused_fire_trait 278531)
Define(in_the_rhythm_trait 264198)
Define(up_close_and_personal_trait 278533)
Define(venomous_fangs_trait 274590)
    ]]
    code = code .. [[
# Hunter spells and functions.

Define(a_murder_of_crows 131894)
	SpellInfo(a_murder_of_crows cd=60 focus=20)
Define(a_murder_of_crows_debuff 131894)
	SpellInfo(a_murder_of_crows_debuff duration=15)

	SpellInfo(aimed_shot focus=30 cd=12 charges=2 cd_haste=ranged unusable=1)
	SpellRequire(aimed_shot unusable 0=focus,30)
	SpellRequire(aimed_shot focus_percent 0=buff,lock_and_load_buff talent=lock_and_load_talent)
	SpellAddBuff(aimed_shot lock_and_load_buff=-1 talent=lock_and_load_talent)
	SpellAddBuff(aimed_shot precise_shots_buff=1)
	SpellAddBuff(aimed_shot double_tap_buff=-1)
	SpellAddBuff(aimed_shot trick_shots_buff=-1)
	SpellAddBuff(aimed_shot master_marksman_buff=1 talent=master_marksman_talent)
	SpellAddBuff(aimed_shot lethal_shots_buff=-1 talent=lethal_shots_talent)

	
	SpellAddBuff(arcane_shot precise_shots_buff=-1)
	SpellAddBuff(arcane_shot master_marksman_buff=-1 talent=master_marksman_talent)
Define(aspect_of_the_cheetah 186257)
	SpellInfo(aspect_of_the_cheetah cd=180)
	SpellInfo(aspect_of_the_cheetah cd=144 talent=born_to_be_wild_talent)
	SpellAddBuff(aspect_of_the_cheetah aspect_of_the_cheetah_buff=1)
Define(aspect_of_the_cheetah_buff 186257)
	SpellInfo(aspect_of_the_cheetah_buff duration=12)

	SpellInfo(aspect_of_the_eagle cd=90 gcd=0 offgcd=1)
	SpellAddBuff(aspect_of_the_eagle aspect_of_the_eagle_buff=1)
Define(aspect_of_the_eagle_buff 186289)
	SpellInfo(aspect_of_the_eagle_buff duration=15)
Define(aspect_of_the_turtle 186265)
	SpellInfo(aspect_of_the_turtle cd=180)
	SpellInfo(aspect_of_the_turtle cd=144 talent=born_to_be_wild_talent)
	SpellAddBuff(aspect_of_the_turtle aspect_of_the_turtle_buff=1)
Define(aspect_of_the_turtle_buff 186265)
	SpellInfo(aspect_of_the_turtle_buff duration=8)

	SpellInfo(aspect_of_the_wild cd=120)
Define(aspect_of_the_wild_buff 193530)
	SpellInfo(aspect_of_the_wild_buff duration=20)

	SpellInfo(barbed_shot cd=12 cd_haste=ranged charges=2)
	SpellAddBuff(barbed_shot barbed_shot_buff=1)
	SpellAddBuff(barbed_shot thrill_of_the_hunt_buff=1)
	SpellAddPetBuff(barbed_shot pet_frenzy_buff=1)
	SpellAddTargetDebuff(barbed_shot barbed_shot_debuff=1)
Define(barbed_shot_debuff 217200)
	SpellInfo(barbed_shot_debuff duration=8 tick=2)
Define(barbed_shot_buff 246152)
	SpellInfo(barbed_shot_buff duration=8)

	SpellInfo(barrage cd=20)
	SpellInfo(barrage focus=30 specialization=marksman)
	SpellInfo(barrage focus=60 specialization=beast_mastery)
Define(beast_cleave_buff 268877)
	SpellInfo(beast_cleave_buff duration=4)
Define(bestial_wrath 19574)
	SpellInfo(bestial_wrath cd=90)
	SpellAddBuff(bestial_wrath bestial_wrath_buff=1)
Define(bestial_wrath_buff 19574)
	SpellInfo(bestial_wrath_buff duration=15)
Define(binding_shot 109248)
	SpellInfo(binding_shot cd=45)
Define(bursting_shot 186387)
	SpellInfo(bursting_shot cd=30 focus=10)

	SpellInfo(butchery focus=30 cd=9 cd_haste=ranged charges=3)
	SpellAddTargetDebuff(butchery internal_bleeding_debuff=1 if_target_debuff=shrapnel_bomb_debuff)
Define(camouflage 199483)
	SpellInfo(camouflage cd=60)

	SpellInfo(carve focus=40 cd=6 cd_haste=melee)
	SpellInfo(carve replace=butchery talent=butchery_talent)
	SpellAddTargetDebuff(carve internal_bleeding_debuff=1 if_target_debuff=shrapnel_bomb_debuff)
Define(chakrams 259391)
	SpellInfo(chakrams focus=30 cd=20)
Define(chimaera_shot 53209)
	SpellInfo(chimaera_shot focus=-10 cd=15 cd_haste=ranged)

	SpellInfo(cobra_shot focus=35)
Define(concussive_shot 5116)
	SpellInfo(concussive_shot cd=5)
	SpellAddTargetDebuff(concussive_shot concussive_shot_debuff=1)
Define(concussive_shot_debuff 5116)
	SpellInfo(concussive_shot_debuff duration=6)

	SpellInfo(coordinated_assault cd=120)
	SpellAddBuff(coordinated_assault coordinated_assault_buff=1)
	SpellAddPetBuff(coordinated_assault pet_coordinated_assault_buff=1)
Define(coordinated_assault_buff 266779)
	SpellInfo(coordinated_assault_buff duration=20)
Define(counter_shot 147362)
	SpellInfo(counter_shot cd=24)

	SpellInfo(dire_beast cd=20 cd_haste=ranged)
	SpellAddPetBuff(dire_beast dire_beast_buff=1)
Define(dire_beast_buff 281036)
	SpellInfo(dire_beast_buff duration=8)
	# TODO: Regenerates 3 focus every 2 seconds, double for dire_stable_talent
Define(disengage 781)
	SpellInfo(disengage cd=20)
	SpellAddBuff(disengage posthaste_buff=1)

	SpellInfo(double_tap cd=60)
	SpellAddBuff(double_tap double_tap_buff=1)
Define(double_tap_buff 260402)
	SpellInfo(double_tap_buff duration=15)
Define(exhilaration 109304)
	SpellInfo(exhilaration cd=120)

	SpellInfo(explosive_shot cd=30 focus=20)
Define(explosive_shot_detonate 212679)
Define(feign_death 5384)
	SpellInfo(feign_death cd=30)
Define(flanking_strike 269751)
	SpellInfo(flanking_strike cd=40 focus=-30)
Define(flare 1543)
	SpellInfo(flare cd=20)
Define(freezing_trap 187650)
	SpellInfo(freezing_trap cd=30)

	SpellInfo(harpoon cd=20)
Define(hunters_mark 257284)
	SpellAddTargetDebuff(hunters_mark hunters_mark_debuff=1)
	SpellRequire(hunters_mark unusable 1=target_debuff,hunters_mark_debuff)
Define(hunters_mark_debuff 257284)
Define(internal_bleeding_debuff 270343)
    SpellInfo(internal_bleeding_debuff duration=8 max_stacks=3)
Define(intimidation 19577)
	SpellInfo(intimidation cd=60)
Define(kill_command 34026)
	SpellInfo(kill_command cd=7.5 cd_haste=ranged focus=30)
	# Unsure of right syntax for following line.  
	# cobra_shot resets kill_command upon impact with the target when bestial_wrath_buff is up
	# SpellRequire(kill_command cd_percent 0=spell,cobra_shot if_buff=bestial_wrath_buff)
Define(kill_command_sv 259489)
	SpellInfo(kill_command_sv cd=6 cd_haste=ranged focus=-15)
	SpellInfo(kill_command_sv charges=2 talent=alpha_predator_talent)
	SpellAddBuff(kill_command_sv tip_of_the_spear_buff=1 talent=tip_of_the_spear_talent)
	SpellRequire(kill_command_sv cd_percent 0=target_debuff,pheromone_bomb_debuff)

	SpellInfo(lethal_shots_buff duration=15)
Define(lock_and_load_buff 194594)
	SpellInfo(lock_and_load_buff duration=15)
Define(master_marksman_buff 269576)
    SpellInfo(master_marksman_buff duration=12)
Define(mend_pet 982)
	SpellInfo(mend_pet cd=10)
Define(misdirection 34477)
	SpellInfo(misdirection cd=30)
Define(mongoose_bite 259387)
	SpellInfo(mongoose_bite cd=12)
	SpellAddTargetDebuff(mongoose_bite internal_bleeding_debuff=1 if_target_debuff=shrapnel_bomb_debuff)
Define(mongoose_fury_buff 259388)
	SpellInfo(mongoose_fury_buff duration=14)
Define(multishot_bm 2643)
	SpellInfo(multishot_bm focus=40)
	SpellAddBuff(multishot_bm beast_cleave_buff=1)
	SpellAddPetBuff(multishot_bm pet_beast_cleave_buff=1)
Define(multishot_mm 257620)
	SpellInfo(multishot_mm focus=15 specialization=beast_mastery)
	SpellAddBuff(multishot_mm precise_shots_buff=-1)
	SpellAddBuff(multishot_mm trick_shots_buff=1)
	SpellAddBuff(multishot_mm master_marksman_buff=-1 talent=master_marksman_talent)
Define(muzzle 187707)
	SpellInfo(muzzle cd=15 interrupt=1)
Define(pheromone_bomb 270323)
	SpellInfo(pheromone_bomb cd=18 cd_haste=ranged)
	SpellInfo(pheromone_bomb charges=2 talent=guerrilla_tactics_talent)
Define(pheromone_bomb_debuff 270332)
    SpellInfo(pheromone_bomb_debuff duration=6)

	SpellInfo(piercing_shot cd=30 focus=35)
Define(posthaste_buff 118922)
	SpellInfo(posthaste_buff duration=4)
Define(precise_shots_buff 260242)
	SpellInfo(precise_shots_buff duration=15 max_stacks=2)

	SpellInfo(rapid_fire channel=3 haste=ranged cd=20)
	SpellInfo(rapid_fire channel=4 talent=streamline_talent)
	SpellAddBuff(rapid_fire precise_shots_buff=1)
	SpellAddBuff(rapid_fire trick_shots_buff=-1)
	SpellAddBuff(rapid_fire lethal_shots_buff=-1 talent=lethal_shots_talent)
Define(raptor_strike 186270)
	SpellInfo(raptor_strike focus=25)
	SpellInfo(raptor_strike replace=mongoose_bite talent=mongoose_bite_talent)
	SpellAddBuff(raptor_strike tip_of_the_spear_buff=0 talent=tip_of_the_spear_talent)
	SpellAddTargetDebuff(raptor_strike internal_bleeding_debuff=1 if_target_debuff=shrapnel_bomb_debuff)

	SpellInfo(revive_pet focus=35)
Define(serpent_sting_mm 271788)
	SpellInfo(serpent_sting_mm focus=10)
	SpellAddTargetDebuff(serpent_sting_mm serpent_sting_mm_debuff=1)
Define(serpent_sting_mm_debuff 271788)
	SpellInfo(serpent_sting_mm_debuff duration=12 tick=3 haste=ranged)
Define(serpent_sting_sv 259491)
	SpellInfo(serpent_sting_sv focus=20)
	SpellRequire(serpent_sting_sv focus_percent 0=buff,vipers_venom_buff)
	SpellAddTargetDebuff(serpent_sting_sv serpent_sting_sv_debuff=1)
Define(serpent_sting_sv_debuff 259491)
	SpellInfo(serpent_sting_sv_debuff duration=12 tick=3 haste=ranged)
Define(shrapnel_bomb 270335)
	SpellInfo(shrapnel_bomb cd=18 cd_haste=ranged)
	SpellInfo(shrapnel_bomb charges=2 talent=guerrilla_tactics_talent)
Define(shrapnel_bomb_debuff 270339)
	SpellInfo(shrapnel_bomb_debuff duration=6)

	SpellInfo(spitting_cobra cd=90)
	SpellAddBuff(spitting_cobra spitting_cobra_buff)
Define(spitting_cobra_buff 194407)
	SpellInfo(spitting_cobra_buff duration=20)
Define(stampede 201430)
	SpellInfo(stampede cd=180)
Define(steady_focus_buff 193534)
	SpellInfo(steady_focus_buff duration=12 max_stacks=2)

	SpellInfo(steady_shot focus=-10)
	SpellAddBuff(steady_shot steady_focus_buff=1 talent=steady_focus_talent)

	SpellInfo(steel_trap cd=60)
Define(tar_trap 187698)
	SpellInfo(tar_trap cd=30)
Define(thrill_of_the_hunt_buff 257946)
	SpellInfo(thrill_of_the_hunt_buff duration=8 max_stacks=3)
Define(tip_of_the_spear_buff 260286)
    SpellInfo(tip_of_the_spear_buff duration=10 max_stacks=3)
Define(trick_shots_buff 257622)
	SpellInfo(trick_shots_buff duration=20)

	SpellInfo(trueshot cd=180)
	SpellAddBuff(trueshot trueshot_buff=1)
Define(trueshot_buff 193526)
	SpellInfo(trueshot_buff duration=15)

    SpellInfo(vipers_venom_buff duration=8)
Define(volatile_bomb 271045)
	SpellInfo(volatile_bomb cd=18 cd_haste=ranged)
	SpellInfo(volatile_bomb charges=2 talent=guerrilla_tactics_talent)
Define(volatile_bomb_debuff 271049)
    SpellInfo(volatile_bomb_debuff duration=6)
    SpellAddTargetDebuff(volatile_bomb_debuff serpent_sting_sv_debuff=1 if_target_debuff=serpent_sting_sv_debuff)
Define(wildfire_bomb 259495)
	SpellInfo(wildfire_bomb cd=18 cd_haste=ranged)
	SpellInfo(wildfire_bomb charges=2 talent=guerrilla_tactics_talent)
Define(wildfire_bomb_debuff 269747)
	SpellInfo(wildfire_bomb_debuff duration=6)
Define(wing_clip 195645)
	SpellInfo(wing_clip focus=30)
	SpellAddTargetDebuff(wing_clip wing_clip_debuff=1)
Define(wing_clip_debuff 195645)
	SpellInfo(wing_clip_debuff duration=15)


#Pet Spells
Define(heart_of_the_phoenix 55709)
	SpellInfo(heart_of_the_phoenix cd=480)
Define(heart_of_the_phoenix_debuff 55711)
	SpellInfo(heart_of_the_phoenix_debuff duration=480)
Define(pet_beast_cleave_buff 118455)
	SpellInfo(pet_beast_cleave_buff duration=4)
Define(pet_coordinated_assault_buff 266779)
	SpellInfo(pet_coordinated_assault_buff duration=20)
Define(pet_frenzy_buff 272790)
	SpellInfo(pet_frenzy_buff duration=8 max_stacks=3)

# Azerite Traits



#Items
Define(frizzos_fingertrap_item 137043)
Define(the_mantle_of_command_item 144326)
Define(qapla_eredun_war_order_item 137227)
Define(call_of_the_wild_item 137101)
Define(parsels_tongue_item 151805)
Define(parsels_tongue_buff 248085)

# Talents
Define(a_murder_of_crows_talent 12)
Define(mm_a_murder_of_crows_talent 3)
Define(alpha_predator_talent 3)
Define(animal_companion_talent 2)
Define(aspect_of_the_beast_talent 19)

Define(binding_shot_talent 15)

Define(bloodseeker_talent 10)
Define(born_to_be_wild_talent 13)

Define(calling_the_shots_talent 19)
Define(camouflage_talent 9)
Define(careful_aim_talent 4)
Define(chakrams_talent 21)
Define(chimaera_shot_talent 6)



Define(flanking_strike_talent 18)

Define(hunters_mark_talent 12)
Define(hydras_bite_talent 5)
Define(killer_cobra_talent 20)
Define(killer_instinct_talent 1)

Define(lock_and_load_talent 20)
Define(master_marksman_talent 1)

Define(natural_mending_talent 8)
Define(one_with_the_pack_talent 5)

Define(posthaste_talent 14)
Define(scent_of_blood_talent 4)
Define(serpent_sting_talent 2)

Define(stampede_talent 18)


Define(stomp_talent 16)
Define(streamline_talent 11)

Define(thrill_of_the_hunt_talent 11)
Define(tip_of_the_spear_talent 16)
Define(trailblazer_talent 7)
Define(venomous_bite_talent 10)

Define(volley_talent 5)


# Item set
Define(t20_2p_critical_aimed_damage_buff 242242) # TODO

# Non-default tags for OvaleSimulationCraft.
SpellInfo(dire_beast tag=main)
SpellInfo(dire_frenzy tag=main)
SpellInfo(barrage tag=shortcd)

]]
    OvaleScripts:RegisterScript("HUNTER", nil, name, desc, code, "include")
end
