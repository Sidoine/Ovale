Ovale.defaut["PRIEST"] =
[[
### defines ###

#Buff
Define(SHADOWORBS 77487)
Define(MINDSPIKEEFFECT 87178)
Define(EVANGELISM 87118)
Define(DARKARCHANGEL 87153)
Define(MINDMELT 81292)
Define(EMPOWEREDSHADOW 95799)

#Spells
Define(DEVOURINGPLAGUE 2944) # Devouring Plague
	SpellInfo(DEVOURINGPLAGUE duration=24 durationhaste=spell)
	SpellAddTargetDebuff(DEVOURINGPLAGUE DEVOURINGPLAGUE=24)
	
Define(DISPERSION 47585)
	SpellInfo(DISPERSION cd=120)
	SpellInfo(DISPERSION addcd=-45 glyph=63229)
	
Define(INNERFIRE 588) # Inner Fire
	SpellAddBuff(INNERFIRE INNERFIRE=1800)
	
Define(INNERWILL 73413) # Inner Will
	SpellAddBuff(INNERWILL INNERWILL=1800)
	
Define(MINDBLAST 8092) # Mind Blast
	SpellInfo(MINDBLAST cd=5.5)
	SpellAddBuff(MINDBLAST SHADOW_ORBS=0)
	SpellAddBuff(MINDBLAST EMPOWEREDSHADOW=15)
	
Define(MINDFLAY 15407) # Mind Flay
	
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
	
Define(MINDSPIKE 73510) # Mind Spike
	# TODO : add talent condition for MIND_MELT
	SpellAddBuff(MINDSPIKE MINDSPIKEEFFECT=12 MINDMELT=6)
	
Define(SHADOWWORDDEATH 32379) # Shadow Word : Death

Define(ARCHANGEL 87151) #Archangel
	SpellInfo(ARCHANGEL cd=90)
	SpellAddBuff(ARCHANGEL DARKARCHANGEL=18)

### end defines ###

ScoreSpells(MINDBLAST SHADOWWORDPAIN VAMPIRICTOUCH DEVOURINGPLAGUE MINDFLAY SHADOWWORDDEATH MINDSPIKE)

# Add main monitor
AddIcon help=main mastery=3
{
	#Check shadowform is up
	unless BuffPresent(SHADOWFORM) Spell(SHADOWFORM)
			
	unless InCombat()
	{
		# Refresh inner fire  and vampiric embrace 5 minutes before it drops when out of combat
		if BuffExpires(INNERFIRE 300) unless BuffPresent(INNERWILL) Spell(INNERFIRE)
		if BuffExpires(INNERWILL 300) unless BuffPresent(INNERFIRE) Spell(INNERWILL)
		if BuffExpires(VAMPIRICEMBRACE 300) Spell(VAMPIRICEMBRACE)
	}
	
	# Refresh inner fire and vampiric embrace if they drop during the fight
	if BuffExpires(INNERFIRE 5) unless BuffPresent(INNERWILL) Spell(INNERFIRE)
	if BuffExpires(INNERWILL 5) unless BuffPresent(INNERFIRE) Spell(INNERWILL)
		
	if BuffExpires(VAMPIRICEMBRACE 5) Spell(VAMPIRICEMBRACE)
		
	#if your rotation isn't set up and the target has few seconds to live, use MIND_SPIKE instead of normal rotation	
	if TargetDebuffExpires(SHADOWWORDPAIN 0 mine=1) and TargetDeadIn(less 10)
	{
		if BuffPresent(MINDSPIKE stacks=3) or BuffPresent(MINDMELT stacks=2) Spell(MINDBLAST)
		Spell(MINDSPIKE)
	}
 
	if BuffPresent(DARKARCHANGEL) #specific DD-based rotation when under Dark Archangel
	{
		#Use SHADOWWORDDEATH if we have enough life left
		if TargetLifePercent(less 25) and LifePercent(more 20) Spell(SHADOWWORDDEATH)
		
		#Use MIND_BLAST on CD
		if BuffPresent(SHADOWORBS stacks=1) Spell(MINDBLAST)
		
		#Fill with MIND_FLAY
		Spell(MINDFLAY priority=2)
	}
	
	#Refresh empowered shadows
	if BuffPresent(SHADOWORBS stacks=1) and BuffExpires(EMPOWEREDSHADOW 2) Spell(MINDBLAST)

	#Set up / refresh the dots
	if TargetDebuffExpires(SHADOWWORDPAIN 0 mine=1) and TargetDeadIn(more 10) Spell(SHADOWWORDPAIN)
	if TargetDebuffExpires(SHADOWWORDPAIN 2 mine=1) and TargetDeadIn(more 6) Spell(MINDFLAY)
	if TargetDebuffExpires(VAMPIRICTOUCH 3 mine=1 haste=spell) and TargetDeadIn(more 8) Spell(VAMPIRICTOUCH)
		
	# refresh DEVOURING_PLAGUE only if it is not ticking on another mob
	unless OtherDebuffPresent(DEVOURINGPLAGUE)
	{
		if TargetDebuffExpires(DEVOURINGPLAGUE 2 mine=1) and TargetDeadIn(more 8) Spell(DEVOURINGPLAGUE)
	}
	
	#Use SHADOW_WORD_DEATH if we have enough life left and it is more useful than MIND_BLAST
	if TargetLifePercent(less 25) and LifePercent(more 20) Spell(SHADOWWORDDEATH)
		
	# Launch the fiend
	if TargetDeadIn(more 15) and ManaPercent(less 75) Spell(SHADOWFIEND)
		
	#Use MIND_BLAST when orbs are at 1 or more stack
	if BuffPresent(SHADOWORBS stacks=1) Spell(MINDBLAST)
				
	#Fill with MIND_FLAY
	Spell(MINDFLAY priority=2)
}

AddIcon help=cd
{
        #Check that you won't have to reapply dots during DA
	if BuffPresent(EVANGELISM stacks=5) and TargetDebuffPresent(DEVOURINGPLAGUE 18 mine=1) and TargetDebuffPresent(VAMPIRICTOUCH 13 mine=1) Spell(ARCHANGEL)
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
	if ManaPercent(less 80) Spell(SHADOWWORDDEATH)
	if ManaPercent(less 5) 
	{
		Spell(DISPERSION)
		Item(33448) #Mana potion (lvl 80)
	}
}


]]
