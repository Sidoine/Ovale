local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Druid_Feral_T16H"
	local desc = "[5.4] SimulationCraft: Druid_Feral_T16H"
	local code = [[
# Based on SimulationCraft profile "Druid_Feral_T16H".
#	class=druid
#	spec=feral
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#UZ!...2.1
#	glyphs=savagery/cat_form

Include(ovale_common)
Include(ovale_druid_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction InterruptActions
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if Stance(druid_bear_form) and target.InRange(skull_bash_bear) Spell(skull_bash_bear)
		if Stance(druid_cat_form) and target.InRange(skull_bash_cat) Spell(skull_bash_cat)
		if target.Classification(worldboss no)
		{
			if Talent(mighty_bash_talent) and target.InRange(mighty_bash) Spell(mighty_bash)
			if Talent(typhoon_talent) and target.InRange(skull_bash_cat) Spell(typhoon)
			if Stance(druid_cat_form) and ComboPoints() > 0 and target.InRange(maim) Spell(maim)
		}
	}
}

AddFunction FaerieFire
{
	if Talent(faerie_swarm_talent) Spell(faerie_swarm)
	if Talent(faerie_swarm_talent no) Spell(faerie_fire)
}

AddFunction SavageRoar
{
	if Glyph(glyph_of_savagery) Spell(savage_roar_glyphed)
	if Glyph(glyph_of_savagery no) and ComboPoints() > 0 Spell(savage_roar)
}

AddFunction FeralBasicActions
{
	#swap_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FeralAoeActions()
	#auto_attack
	#skull_bash_cat
	InterruptActions()
	#force_of_nature,if=charges=3|trinket.proc.agility.react|(buff.rune_of_reorigination.react&buff.rune_of_reorigination.remains<1)|target.time_to_die<20
	if Charges(force_of_nature_melee) == 3 or BuffPresent(trinket_proc_agility_buff) or BuffPresent(rune_of_reorigination_buff) and BuffRemaining(rune_of_reorigination_buff) < 1 or target.TimeToDie() < 20 Spell(force_of_nature_melee)
	#ferocious_bite,if=dot.rip.ticking&dot.rip.remains<=3&target.health.pct<=25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) <= 3 and target.HealthPercent() <= 25 Spell(ferocious_bite)
	#faerie_fire,if=debuff.weakened_armor.stack<3
	if target.DebuffStacks(weakened_armor_debuff any=1) < 3 FaerieFire()
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if Talent(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemaining(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.remains<3
	if BuffRemaining(savage_roar_buff) < 3 SavageRoar()
	#virmens_bite_potion,if=(target.health.pct<30&buff.berserk.up)|target.time_to_die<=40
	if target.HealthPercent() < 30 and BuffPresent(berserk_cat_buff) or target.TimeToDie() <= 40 UsePotionAgility()
	#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
	if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
	#berserk,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) Spell(berserk_cat)
	#use_item,slot=hands,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) UseItemActions()
	#blood_fury,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) Spell(blood_fury_apsp)
	#berserking,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) Spell(berserking)
	#arcane_torrent,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) Spell(arcane_torrent_energy)
	#rip,if=combo_points>=5&target.health.pct<=25&action.rip.tick_damage%dot.rip.tick_dmg>=1.15
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 1.15 Spell(rip)
	#ferocious_bite,if=combo_points>=5&target.health.pct<=25&dot.rip.ticking
	if ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
	#rip,if=combo_points>=5&dot.rip.remains<2
	if ComboPoints() >= 5 and target.DebuffRemaining(rip_debuff) < 2 Spell(rip)
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemaining(thrash_cat_debuff) < 3 Spell(thrash_cat)
	#rake,cycle_targets=1,if=dot.rake.remains<3|action.rake.tick_damage>dot.rake.tick_dmg
	if target.DebuffRemaining(rake_debuff) < 3 or target.Damage(rake_debuff) > target.LastEstimatedDamage(rake_debuff) Spell(rake)
	#pool_resource,for_next=1
	#thrash_cat,if=dot.thrash_cat.remains<3&(dot.rip.remains>=8&buff.savage_roar.remains>=12|buff.berserk.up|combo_points>=5)
	if target.DebuffRemaining(thrash_cat_debuff) < 3 and { target.DebuffRemaining(rip_debuff) >= 8 and BuffRemaining(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } Spell(thrash_cat)
	unless target.DebuffRemaining(thrash_cat_debuff) < 3 and { target.DebuffRemaining(rip_debuff) >= 8 and BuffRemaining(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } and not SpellCooldown(thrash_cat) > 0
	{
		#pool_resource,if=combo_points>=5&!(energy.time_to_max<=1|(buff.berserk.up&energy>=25)|(buff.feral_rage.up&buff.feral_rage.remains<=1))&dot.rip.ticking
		unless ComboPoints() >= 5 and not { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) and Energy() >= 25 or BuffPresent(feral_rage_buff) and BuffRemaining(feral_rage_buff) <= 1 } and target.DebuffPresent(rip_debuff)
		{
			#ferocious_bite,if=combo_points>=5&dot.rip.ticking
			if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
			#run_action_list,name=filler,if=buff.omen_of_clarity.react
			if BuffPresent(omen_of_clarity_melee_buff) FeralFillerActions()
			#run_action_list,name=filler,if=buff.feral_fury.react
			if BuffPresent(feral_fury_buff) FeralFillerActions()
			#run_action_list,name=filler,if=(combo_points<5&dot.rip.remains<3.0)|(combo_points=0&buff.savage_roar.remains<2)
			if ComboPoints() < 5 and target.DebuffRemaining(rip_debuff) < 3 or ComboPoints() == 0 and BuffRemaining(savage_roar_buff) < 2 FeralFillerActions()
			#run_action_list,name=filler,if=target.time_to_die<=8.5
			if target.TimeToDie() <= 8.5 FeralFillerActions()
			#run_action_list,name=filler,if=buff.tigers_fury.up|buff.berserk.up
			if BuffPresent(tigers_fury_buff) or BuffPresent(berserk_cat_buff) FeralFillerActions()
			#run_action_list,name=filler,if=cooldown.tigers_fury.remains<=3
			if SpellCooldown(tigers_fury) <= 3 FeralFillerActions()
			#run_action_list,name=filler,if=energy.time_to_max<=1.0
			if TimeToMaxEnergy() <= 1 FeralFillerActions()
		}
	}
}

AddFunction FeralDefaultActions
{
	#swap_action_list,name=basic
	FeralBasicActions()
}

AddFunction FeralAdvancedActions
{
	#swap_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 FeralAoeActions()
	#auto_attack
	#skull_bash_cat
	InterruptActions()
	#force_of_nature,if=charges=3|(buff.rune_of_reorigination.react&buff.rune_of_reorigination.remains<1)|(buff.vicious.react&buff.vicious.remains<1)|target.time_to_die<20
	if Charges(force_of_nature_melee) == 3 or BuffPresent(rune_of_reorigination_buff) and BuffRemaining(rune_of_reorigination_buff) < 1 or BuffPresent(trinket_proc_agility_buff) and BuffRemaining(trinket_proc_agility_buff) < 1 or target.TimeToDie() < 20 Spell(force_of_nature_melee)
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_energy)
	#ravage,if=buff.stealthed.up
	if BuffPresent(stealthed_buff any=1) and BuffPresent(stealthed_buff any=1) Spell(ravage)
	#ferocious_bite,if=dot.rip.ticking&dot.rip.remains<=3&target.health.pct<=25
	if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) <= 3 and target.HealthPercent() <= 25 Spell(ferocious_bite)
	#faerie_fire,if=debuff.weakened_armor.stack<3
	if target.DebuffStacks(weakened_armor_debuff any=1) < 3 FaerieFire()
	#healing_touch,if=talent.dream_of_cenarius.enabled&buff.predatory_swiftness.up&buff.dream_of_cenarius.down&(buff.predatory_swiftness.remains<1.5|combo_points>=4)
	if Talent(dream_of_cenarius_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(dream_of_cenarius_melee_buff) and { BuffRemaining(predatory_swiftness_buff) < 1.5 or ComboPoints() >= 4 } Spell(healing_touch)
	#savage_roar,if=buff.savage_roar.down
	if BuffExpires(savage_roar_buff) SavageRoar()
	#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
	if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
	#berserk,if=buff.tigers_fury.up|(target.time_to_die<18&cooldown.tigers_fury.remains>6)
	if BuffPresent(tigers_fury_buff) or target.TimeToDie() < 18 and SpellCooldown(tigers_fury) > 6 Spell(berserk_cat)
	#use_item,slot=hands,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) UseItemActions()
	#thrash_cat,if=buff.omen_of_clarity.react&dot.thrash_cat.remains<3&target.time_to_die>=6
	if BuffPresent(omen_of_clarity_melee_buff) and target.DebuffRemaining(thrash_cat_debuff) < 3 and target.TimeToDie() >= 6 Spell(thrash_cat)
	#ferocious_bite,if=target.time_to_die<=1&combo_points>=3
	if target.TimeToDie() <= 1 and ComboPoints() >= 3 Spell(ferocious_bite)
	#savage_roar,if=buff.savage_roar.remains<=3&combo_points>0&target.health.pct<25
	if BuffRemaining(savage_roar_buff) <= 3 and ComboPoints() > 0 and target.HealthPercent() < 25 SavageRoar()
	#virmens_bite_potion,if=(combo_points>=5&(target.time_to_die*(target.health.pct-25)%target.health.pct)<15&buff.rune_of_reorigination.up)|target.time_to_die<=40
	if ComboPoints() >= 5 and target.TimeToDie() * { target.HealthPercent() - 25 } / target.HealthPercent() < 15 and BuffPresent(rune_of_reorigination_buff) or target.TimeToDie() <= 40 UsePotionAgility()
	#rip,if=combo_points>=5&action.rip.tick_damage%dot.rip.tick_dmg>=1.15&target.time_to_die>30
	if ComboPoints() >= 5 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 1.15 and target.TimeToDie() > 30 Spell(rip)
	#rip,if=combo_points>=4&action.rip.tick_damage%dot.rip.tick_dmg>=0.95&target.time_to_die>30&buff.rune_of_reorigination.up&buff.rune_of_reorigination.remains<=1.5
	if ComboPoints() >= 4 and target.Damage(rip_debuff) / target.LastEstimatedDamage(rip_debuff) >= 0.95 and target.TimeToDie() > 30 and BuffPresent(rune_of_reorigination_buff) and BuffRemaining(rune_of_reorigination_buff) <= 1.5 Spell(rip)
	#pool_resource,if=combo_points>=5&target.health.pct<=25&dot.rip.ticking&!(energy>=50|(buff.berserk.up&energy>=25))
	unless ComboPoints() >= 5 and target.HealthPercent() <= 25 and target.DebuffPresent(rip_debuff) and not { Energy() >= 50 or BuffPresent(berserk_cat_buff) and Energy() >= 25 }
	{
		#ferocious_bite,if=combo_points>=5&dot.rip.ticking&target.health.pct<=25
		if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) and target.HealthPercent() <= 25 Spell(ferocious_bite)
		#rip,if=combo_points>=5&target.time_to_die>=6&dot.rip.remains<2&(buff.berserk.up|dot.rip.remains+1.9<=cooldown.tigers_fury.remains)
		if ComboPoints() >= 5 and target.TimeToDie() >= 6 and target.DebuffRemaining(rip_debuff) < 2 and { BuffPresent(berserk_cat_buff) or target.DebuffRemaining(rip_debuff) + 1.9 <= SpellCooldown(tigers_fury) } Spell(rip)
		#savage_roar,if=buff.savage_roar.remains<=3&combo_points>0&buff.savage_roar.remains+2>dot.rip.remains
		if BuffRemaining(savage_roar_buff) <= 3 and ComboPoints() > 0 and BuffRemaining(savage_roar_buff) + 2 > target.DebuffRemaining(rip_debuff) SavageRoar()
		#savage_roar,if=buff.savage_roar.remains<=6&combo_points>=5&buff.savage_roar.remains+2<=dot.rip.remains&dot.rip.ticking
		if BuffRemaining(savage_roar_buff) <= 6 and ComboPoints() >= 5 and BuffRemaining(savage_roar_buff) + 2 <= target.DebuffRemaining(rip_debuff) and target.DebuffPresent(rip_debuff) SavageRoar()
		#savage_roar,if=buff.savage_roar.remains<=12&combo_points>=5&energy.time_to_max<=1&buff.savage_roar.remains<=dot.rip.remains+6&dot.rip.ticking
		if BuffRemaining(savage_roar_buff) <= 12 and ComboPoints() >= 5 and TimeToMaxEnergy() <= 1 and BuffRemaining(savage_roar_buff) <= target.DebuffRemaining(rip_debuff) + 6 and target.DebuffPresent(rip_debuff) SavageRoar()
		#rake,if=buff.rune_of_reorigination.up&dot.rake.remains<9&buff.rune_of_reorigination.remains<=1.5
		if BuffPresent(rune_of_reorigination_buff) and target.DebuffRemaining(rake_debuff) < 9 and BuffRemaining(rune_of_reorigination_buff) <= 1.5 Spell(rake)
		#rake,cycle_targets=1,if=target.time_to_die-dot.rake.remains>3&(action.rake.tick_damage>dot.rake.tick_dmg|(dot.rake.remains<3&action.rake.tick_damage%dot.rake.tick_dmg>=0.75))
		if target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 3 and { target.Damage(rake_debuff) > target.LastEstimatedDamage(rake_debuff) or target.DebuffRemaining(rake_debuff) < 3 and target.Damage(rake_debuff) / target.LastEstimatedDamage(rake_debuff) >= 0.75 } Spell(rake)
		#pool_resource,for_next=1
		#thrash_cat,if=target.time_to_die>=6&dot.thrash_cat.remains<3&(dot.rip.remains>=8&buff.savage_roar.remains>=12|buff.berserk.up|combo_points>=5)&dot.rip.ticking
		if target.TimeToDie() >= 6 and target.DebuffRemaining(thrash_cat_debuff) < 3 and { target.DebuffRemaining(rip_debuff) >= 8 and BuffRemaining(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } and target.DebuffPresent(rip_debuff) Spell(thrash_cat)
		unless target.TimeToDie() >= 6 and target.DebuffRemaining(thrash_cat_debuff) < 3 and { target.DebuffRemaining(rip_debuff) >= 8 and BuffRemaining(savage_roar_buff) >= 12 or BuffPresent(berserk_cat_buff) or ComboPoints() >= 5 } and target.DebuffPresent(rip_debuff) and not SpellCooldown(thrash_cat) > 0
		{
			#pool_resource,for_next=1
			#thrash_cat,if=target.time_to_die>=6&dot.thrash_cat.remains<9&buff.rune_of_reorigination.up&buff.rune_of_reorigination.remains<=1.5&dot.rip.ticking
			if target.TimeToDie() >= 6 and target.DebuffRemaining(thrash_cat_debuff) < 9 and BuffPresent(rune_of_reorigination_buff) and BuffRemaining(rune_of_reorigination_buff) <= 1.5 and target.DebuffPresent(rip_debuff) Spell(thrash_cat)
			unless target.TimeToDie() >= 6 and target.DebuffRemaining(thrash_cat_debuff) < 9 and BuffPresent(rune_of_reorigination_buff) and BuffRemaining(rune_of_reorigination_buff) <= 1.5 and target.DebuffPresent(rip_debuff) and not SpellCooldown(thrash_cat) > 0
			{
				#pool_resource,if=combo_points>=5&!(energy.time_to_max<=1|(buff.berserk.up&energy>=25)|(buff.feral_rage.up&buff.feral_rage.remains<=1))&dot.rip.ticking
				unless ComboPoints() >= 5 and not { TimeToMaxEnergy() <= 1 or BuffPresent(berserk_cat_buff) and Energy() >= 25 or BuffPresent(feral_rage_buff) and BuffRemaining(feral_rage_buff) <= 1 } and target.DebuffPresent(rip_debuff)
				{
					#ferocious_bite,if=combo_points>=5&dot.rip.ticking
					if ComboPoints() >= 5 and target.DebuffPresent(rip_debuff) Spell(ferocious_bite)
					#run_action_list,name=filler,if=buff.omen_of_clarity.react
					if BuffPresent(omen_of_clarity_melee_buff) FeralFillerActions()
					#run_action_list,name=filler,if=buff.feral_fury.react
					if BuffPresent(feral_fury_buff) FeralFillerActions()
					#run_action_list,name=filler,if=(combo_points<5&dot.rip.remains<3.0)|(combo_points=0&buff.savage_roar.remains<2)
					if ComboPoints() < 5 and target.DebuffRemaining(rip_debuff) < 3 or ComboPoints() == 0 and BuffRemaining(savage_roar_buff) < 2 FeralFillerActions()
					#run_action_list,name=filler,if=target.time_to_die<=8.5
					if target.TimeToDie() <= 8.5 FeralFillerActions()
					#run_action_list,name=filler,if=buff.tigers_fury.up|buff.berserk.up
					if BuffPresent(tigers_fury_buff) or BuffPresent(berserk_cat_buff) FeralFillerActions()
					#run_action_list,name=filler,if=cooldown.tigers_fury.remains<=3
					if SpellCooldown(tigers_fury) <= 3 FeralFillerActions()
					#run_action_list,name=filler,if=energy.time_to_max<=1.0
					if TimeToMaxEnergy() <= 1 FeralFillerActions()
				}
			}
		}
	}
}

AddFunction FeralPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#mark_of_the_wild,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
	#healing_touch,if=!buff.dream_of_cenarius.up&talent.dream_of_cenarius.enabled
	if not BuffPresent(dream_of_cenarius_melee_buff) and Talent(dream_of_cenarius_talent) Spell(healing_touch)
	#cat_form
	if not Stance(druid_cat_form) Spell(cat_form)
	#savage_roar
	SavageRoar()
	#stealth
	if BuffExpires(stealthed_buff any=1) Spell(prowl)
	#snapshot_stats
	#virmens_bite_potion
	UsePotionAgility()
}

AddFunction FeralAoeActions
{
	#swap_action_list,name=default,if=active_enemies<5
	if Enemies() < 5 FeralDefaultActions()
	#auto_attack
	#faerie_fire,cycle_targets=1,if=debuff.weakened_armor.stack<3
	if target.DebuffStacks(weakened_armor_debuff any=1) < 3 FaerieFire()
	#savage_roar,if=buff.savage_roar.down|(buff.savage_roar.remains<3&combo_points>0)
	if BuffExpires(savage_roar_buff) or BuffRemaining(savage_roar_buff) < 3 and ComboPoints() > 0 SavageRoar()
	#use_item,slot=hands,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) UseItemActions()
	#blood_fury,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) Spell(blood_fury_apsp)
	#berserking,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) Spell(berserking)
	#arcane_torrent,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) Spell(arcane_torrent_energy)
	#tigers_fury,if=energy<=35&!buff.omen_of_clarity.react
	if Energy() <= 35 and not BuffPresent(omen_of_clarity_melee_buff) Spell(tigers_fury)
	#berserk,if=buff.tigers_fury.up
	if BuffPresent(tigers_fury_buff) Spell(berserk_cat)
	#pool_resource,for_next=1
	#thrash_cat,if=buff.rune_of_reorigination.up
	if BuffPresent(rune_of_reorigination_buff) Spell(thrash_cat)
	unless BuffPresent(rune_of_reorigination_buff) and not SpellCooldown(thrash_cat) > 0
	{
		#pool_resource,wait=0.1,for_next=1
		#thrash_cat,if=dot.thrash_cat.remains<3|(buff.tigers_fury.up&dot.thrash_cat.remains<9)
		if target.DebuffRemaining(thrash_cat_debuff) < 3 or BuffPresent(tigers_fury_buff) and target.DebuffRemaining(thrash_cat_debuff) < 9 Spell(thrash_cat)
		unless { target.DebuffRemaining(thrash_cat_debuff) < 3 or BuffPresent(tigers_fury_buff) and target.DebuffRemaining(thrash_cat_debuff) < 9 } and not SpellCooldown(thrash_cat) > 0
		{
			#savage_roar,if=buff.savage_roar.remains<9&combo_points>=5
			if BuffRemaining(savage_roar_buff) < 9 and ComboPoints() >= 5 SavageRoar()
			#rip,if=combo_points>=5
			if ComboPoints() >= 5 Spell(rip)
			#rake,cycle_targets=1,if=(active_enemies<8|buff.rune_of_reorigination.up)&dot.rake.remains<3&target.time_to_die>=15
			if { Enemies() < 8 or BuffPresent(rune_of_reorigination_buff) } and target.DebuffRemaining(rake_debuff) < 3 and target.TimeToDie() >= 15 Spell(rake)
			#swipe_cat,if=buff.savage_roar.remains<=5
			if BuffRemaining(savage_roar_buff) <= 5 Spell(swipe_cat)
			#swipe_cat,if=buff.tigers_fury.up|buff.berserk.up
			if BuffPresent(tigers_fury_buff) or BuffPresent(berserk_cat_buff) Spell(swipe_cat)
			#swipe_cat,if=cooldown.tigers_fury.remains<3
			if SpellCooldown(tigers_fury) < 3 Spell(swipe_cat)
			#swipe_cat,if=buff.omen_of_clarity.react
			if BuffPresent(omen_of_clarity_melee_buff) Spell(swipe_cat)
			#swipe_cat,if=energy.time_to_max<=1
			if TimeToMaxEnergy() <= 1 Spell(swipe_cat)
		}
	}
}

AddFunction FeralFillerActions
{
	#ravage
	if BuffPresent(stealthed_buff any=1) Spell(ravage)
	#rake,if=target.time_to_die-dot.rake.remains>3&action.rake.tick_damage*(dot.rake.ticks_remain+1)-dot.rake.tick_dmg*dot.rake.ticks_remain>action.mangle_cat.hit_damage
	if target.TimeToDie() - target.DebuffRemaining(rake_debuff) > 3 and target.Damage(rake_debuff) * { target.TicksRemaining(rake_debuff) + 1 } - target.LastEstimatedDamage(rake_debuff) * target.TicksRemaining(rake_debuff) > Damage(mangle_cat) Spell(rake)
	#shred,if=(buff.omen_of_clarity.react|buff.berserk.up|energy.regen>=15)&buff.king_of_the_jungle.down
	if { BuffPresent(omen_of_clarity_melee_buff) or BuffPresent(berserk_cat_buff) or EnergyRegen() >= 15 } and BuffExpires(king_of_the_jungle_buff) Spell(shred)
	#mangle_cat,if=buff.king_of_the_jungle.down
	if BuffExpires(king_of_the_jungle_buff) Spell(mangle_cat)
}

AddIcon specialization=feral help=main enemies=1
{
	if InCombat(no) FeralPrecombatActions()
	FeralDefaultActions()
}

AddIcon specialization=feral help=aoe
{
	if InCombat(no) FeralPrecombatActions()
	FeralDefaultActions()
}

### Required symbols
# arcane_torrent_energy
# berserk_cat
# berserk_cat_buff
# berserking
# blood_fury_apsp
# cat_form
# dream_of_cenarius_melee_buff
# dream_of_cenarius_talent
# faerie_fire
# faerie_swarm
# faerie_swarm_talent
# feral_fury_buff
# feral_rage_buff
# ferocious_bite
# force_of_nature_melee
# glyph_of_savagery
# healing_touch
# king_of_the_jungle_buff
# maim
# mangle_cat
# mark_of_the_wild
# mighty_bash
# mighty_bash_talent
# omen_of_clarity_melee_buff
# predatory_swiftness_buff
# prowl
# rake
# rake_debuff
# ravage
# rip
# rip_debuff
# rune_of_reorigination_buff
# savage_roar
# savage_roar_buff
# savage_roar_glyphed
# shred
# skull_bash_bear
# skull_bash_cat
# swipe_cat
# thrash_cat
# thrash_cat_debuff
# tigers_fury
# tigers_fury_buff
# trinket_proc_agility_buff
# typhoon
# typhoon_talent
# virmens_bite_potion
]]
	OvaleScripts:RegisterScript("DRUID", name, desc, code, "reference")
end
