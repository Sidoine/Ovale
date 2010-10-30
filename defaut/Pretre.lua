Ovale.defaut["PRIEST"] =
[[
### defines ###

#Buff
Define(ORB 77487)
Define(MSEFFECT 87178)
Define(EVANGELISM 87118)
Define(DA 87153)
Define(MM 81292)

#Spells
Define(DP 2944) # Devouring Plague
	SpellInfo(DP duration=24 durationhaste=spell)
	SpellAddTargetDebuff(DP DP=24)
	
Define(DISPERSION 47585)
	SpellInfo(DISPERSION cd=120)
	SpellInfo(DISPERSION addcd=-45 glyph=63229)
	
Define(INNERFIRE 48168) # Inner Fire
	SpellAddBuff(INNERFIRE INNERFIRE=1800)
	
Define(MB 8092) # Mind Blast
	SpellInfo(MB cd=5.5)
	SpellAddBuff(MB ORB=0)
	
Define(MF 15407) # Mind Flay
	
Define(FIEND 34433)
	SpellInfo(FIEND cd=300)
	
Define(SHADOWFORM 15473) # Shadowform

Define(SWP 589) # Shadow Word: Pain
	SpellInfo(SWP duration=18)	
	SpellAddTargetDebuff(SWP SWP=18)
	
Define(VE 15286) # Vampiric Embrace

Define(VT 34914) # Vampiric Touch
	SpellInfo(VT duration=15 durationhaste=spell)
	SpellAddTargetDebuff(VT VT=15)
	
Define(MS 73510) # Mind Spike
	# TODO : add talent condition for MM
	SpellAddBuff(MS MSEFFECT=12 MM=6)
	
Define(SWD 32379) # Shadow Word : Death

Define(ARCHANGEL 87151) #Archangel
	SpellInfo(ARCHANGEL cd=90)
	SpellAddBuff(ARCHANGEL DA=18)

### end defines ###

ScoreSpells(MB SWP VT DP MF SWD MS)

# Add main monitor
AddIcon help=main mastery=3
{
	#Check shadowform is up
	unless BuffPresent(SHADOWFORM) Spell(SHADOWFORM)
			
	unless InCombat()
	{
		# Refresh inner fire  and vampiric embrace 10 minutes before it drops when out of combat
		if BuffExpires(INNERFIRE 600) Spell(INNERFIRE)			
		if BuffExpires(VE 600) Spell(VE)
	}
	
	# Refresh inner fire and vampiric embrace if they drop during the fight
	if BuffExpires(INNERFIRE 0) Spell(INNERFIRE)
		
	if BuffExpires(VE 0) Spell(VE)
		
	#if your rotation isn't set up and the target has few seconds to live, use MS instead of normal rotation	
	#TODO : adapt the target life
	if TargetDebuffExpires(SWP 0 mine=1) and TargetDeadIn(less 10)
	{
		if BuffPresent(MS stacks=3) or BuffPresent(MM stacks=2) Spell(MB)
		Spell(MS)
	}
 
	if BuffPresent(DA) #specific DD-based rotation when under Dark Archangel
	{
		#Use SWD if we have enough life left
		if TargetLifePercent(less 25) and LifePercent(more 20) Spell(SWD)
		
		#Use MB on CD
		if BuffPresent(ORB stacks=3) Spell(MB)
		
		#Fill with MF
		Spell(MF priority=2)
		
	}

	#Set up / refresh the dots
	if TargetDebuffExpires(SWP 0 mine=1) and TargetDeadIn(more 6) Spell(SWP)
	if TargetDebuffExpires(SWP 2 mine=1) and TargetDeadIn(more 6) Spell(MF)
	if TargetDebuffExpires(VT 3 mine=1 haste=spell) and TargetDeadIn(more 8) Spell(VT)
		
	# refresh DP only if it is not ticking on another mob
	unless OtherDebuffPresent(DP)
	{
		if TargetDebuffExpires(DP 2 mine=1) and TargetDeadIn(more 8) Spell(DP)
	}
		
	# Launch the fiend
	Spell(FIEND)
		
	#Use SWD if we have enough life left and it is more useful than MB
	if TargetLifePercent(less 25) and LifePercent(more 20) Spell(SWD)
		
        #Use MB when orbs are at 3 stacks
	if BuffPresent(ORB stacks=3) Spell(MB)
				
	#Fill with MF
	Spell(MF priority=2)
}

AddIcon help=cd
{
	if BuffPresent(EVANGELISM stacks=5) Spell(ARCHANGEL)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}
        
# Add mana monitor
AddIcon help=mana mastery=3
{
	if LifePercent(less 10) 
	{
		Spell(DISPERSION)
		Item(36892) #Health stone
		Item(36893)
		Item(36894)
		Item(33447) #Life potion (lvl 80)

	}
	if ManaPercent(less 5) 
	{
		Spell(DISPERSION)
		Item(33448) #Mana potion (lvl 80)
	}
}


]]
