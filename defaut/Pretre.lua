Ovale.defaut["PRIEST"] =
[[
#Spells
Define(DEVOURINGPLAGUE 2944) # Devouring Plague
	SpellInfo(DEVOURINGPLAGUE duration=24 durationhaste=spell)
	SpellAddTargetDebuff(DEVOURINGPLAGUE DEVOURINGPLAGUE=24)
Define(DISPERSION 47585)
	SpellInfo(DISPERSION cd=120)
Define(INNERFIRE 48168) # Inner Fire
	SpellAddBuff(INNERFIRE INNERFIRE=1800)
Define(MINDBLAST 8092) # Mind Blast
	SpellInfo(MINDBLAST cd=5.5)
	SpellAddBuff(MINDBLAST SHADOWORB=0)
Define(MINDLFAY 15407) # Mind Flay
	SpellInfo(MINDLFAY canStopChannelling=3)
Define(SHADOWFIEND 34433)
	SpellInfo(SHADOWFIEND cd=300)
Define(SHADOWFORM 15473) # Shadowform
Define(SHADOWWORDPAIN 589) # Shadow Word: Pain
	SpellInfo(SHADOWWORDPAIN duration=18)
	SpellAddTargetDebuff(SHADOWWORDPAIN SHADOWWORDPAIN=18)
Define(VAMPIRICEMBRACE 15286) # Vampiric Embrace
Define(VAMPIRICTOUCH 34914) # Vampiric Touch
	SpellInfo(VAMPIRICTOUCH duration=15 durationhaste=spell)
	SpellAddTargetDebuff(VAMPIRICTOUCH VAMPIRICTOUCH=15)

#Buff
Define(SHADOWORB 77487)
	
AddCheckBox(multidot L(multidot))

ScoreSpells(MINDBLAST SHADOWWORDPAIN VAMPIRICTOUCH DEVOURINGPLAGUE MINDLFAY)

# Add main monitor
AddIcon help=main mastery=3
{
	unless InCombat()
	{
		#Check shadowform is up
		unless BuffPresent(SHADOWFORM)
			Spell(SHADOWFORM)
			
		# Refresh inner fire
		if BuffExpires(INNERFIRE 400)
			Spell(INNERFIRE)
			
		if BuffExpires(VAMPIRICEMBRACE 400) 
			Spell(VAMPIRICEMBRACE)
	}

 
	if TargetDebuffExpires(SHADOWWORDPAIN 2 mine=1) and TargetDeadIn(more 6) Spell(SHADOWWORDPAIN)
	if TargetDebuffExpires(VAMPIRICTOUCH 3 mine=1 haste=spell) and TargetDeadIn(more 8) Spell(VAMPIRICTOUCH)
	if BuffPresent(SHADOWORB stacks=3) Spell(MINDBLAST)
  
	unless CheckBoxOn(multidot) and OtherDebuffPresent(DEVOURINGPLAGUE)
	{
		if TargetDebuffExpires(DEVOURINGPLAGUE 2 mine=1) and TargetDeadIn(more 8)
			Spell(DEVOURINGPLAGUE)
	}

	if CheckBoxOn(multidot) and OtherDebuffExpires(SHADOWWORDPAIN)
		Texture(INV_Misc_Coin_01) 

	Spell(MINDLFAY priority=2)
}

AddIcon help=cd
{
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}
        
# Add mana monitor
AddIcon help=mana mastery=3
{
	#Regain mana if needed and if shadowfiend is not already out
	if Mana(less 4000) and PetPresent(no)
	{
		Spell(SHADOWFIEND usable=1)
		unless TargetDebuffExpires(VAMPIRICTOUCH 6 mine=1 haste=spell) Spell(DISPERSION usable=1)
	}
}

# Add icons to monitor debuffs
AddIcon size=small nocd=1 {if TargetDebuffExpires(VAMPIRICTOUCH 1.4 mine=1 haste=spell) Spell(VAMPIRICTOUCH) } # Vampiric Touch
AddIcon size=small nocd=1 {if TargetDebuffExpires(SHADOWWORDPAIN 1 mine=1) Spell(SHADOWWORDPAIN) } # Shadow Word: Pain
AddIcon size=small nocd=1 {if TargetDebuffExpires(DEVOURINGPLAGUE 1 mine=1) Spell(DEVOURINGPLAGUE) } 
]]
