Ovale.defaut["PRIEST"] =
[[
#Spells
Define(ARCHANGEL 87151) #Archangel
    SpellInfo(ARCHANGEL cd=90)
    SpellAddBuff(ARCHANGEL DARKARCHANGEL=18)
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
    SpellInfo(MINDBLAST cd=6.5)
    SpellAddBuff(MINDBLAST SHADOW_ORBS=0)
    SpellAddBuff(MINDBLAST EMPOWEREDSHADOW=15)
Define(MINDFLAY 15407) # Mind Flay
Define(MINDSPIKE 73510) # Mind Spike
    # TODO : add talent condition for MIND_MELT
    SpellAddBuff(MINDSPIKE MINDSPIKEEFFECT=12 MINDMELT=6)
Define(SHADOWFIEND 34433)
    SpellInfo(SHADOWFIEND cd=300)
Define(SHADOWFORM 15473) # Shadowform
Define(SHADOWWORDDEATH 32379) # Shadow Word : Death
Define(SHADOWWORDPAIN 589) # Shadow Word: Pain
    SpellInfo(SHADOWWORDPAIN duration=18)    
    SpellAddTargetDebuff(SHADOWWORDPAIN SHADOWWORDPAIN=18)
Define(VAMPIRICEMBRACE 15286) # Vampiric Embrace
Define(VAMPIRICTOUCH 34914) # Vampiric Touch
    SpellInfo(VAMPIRICTOUCH duration=15 durationhaste=spell)
    SpellAddTargetDebuff(VAMPIRICTOUCH VAMPIRICTOUCH=15)

#Buff
Define(SHADOWORBS 77487)
Define(MINDSPIKEEFFECT 87178)
Define(EVANGELISM 87118)
Define(DARKARCHANGEL 87153)
Define(MINDMELT 81292)
Define(EMPOWEREDSHADOW 95799)

ScoreSpells(MINDBLAST SHADOWWORDPAIN VAMPIRICTOUCH DEVOURINGPLAGUE MINDFLAY SHADOWWORDDEATH MINDSPIKE)

# Add main monitor
AddIcon help=main mastery=3
{
    #shadow_form
    unless BuffPresent(SHADOWFORM) Spell(SHADOWFORM)
            
    unless InCombat()
    {
        #inner_fire
        if BuffExpires(INNERFIRE 300) unless BuffPresent(INNERWILL) Spell(INNERFIRE)
        if BuffExpires(INNERWILL 300) unless BuffPresent(INNERFIRE) Spell(INNERWILL)
		#vampiric_embrace
        if BuffExpires(VAMPIRICEMBRACE 300) Spell(VAMPIRICEMBRACE)
    }
    
    # Refresh inner fire and vampiric embrace if they drop during the fight
    if BuffExpires(INNERFIRE 5) unless BuffPresent(INNERWILL) Spell(INNERFIRE)
    if BuffExpires(INNERWILL 5) unless BuffPresent(INNERFIRE) Spell(INNERWILL)
     
	#if your rotation isn't set up and the target has few seconds to live, use MIND_SPIKE instead of normal rotation    
	if TargetDebuffExpires(SHADOWWORDPAIN 0 mine=1) and TargetDeadIn(less 10)
	{
		if BuffPresent(MINDSPIKEEFFECT stacks=3) or BuffPresent(MINDMELT stacks=2) Spell(MINDBLAST)
		Spell(MINDSPIKE)
	}
    
	#mind_blast
	Spell(MINDBLAST)
	#shadow_word_pain,if=(!ticking|dot.shadow_word_pain.remains<gcd+0.5)&miss_react	
	if TargetDebuffExpires(SHADOWWORDPAIN 2 haste=spell mine=1) and TargetDeadIn(more 10)
		Spell(SHADOWWORDPAIN)

	#devouring_plague,if=(!ticking|dot.devouring_plague.remains<gcd+1.0)&miss_react
	if OtherDebuffExpires(DEVOURINGPLAGUE) and TargetDebuffExpires(DEVOURINGPLAGUE 2.5 haste=spell mine=1) and TargetDeadIn(more 8) 
		Spell(DEVOURINGPLAGUE)
	
	#vampiric_touch,if=(!ticking|dot.vampiric_touch.remains<cast_time+2.5)&miss_react
	if TargetDebuffExpires(VAMPIRICTOUCH 3 mine=1 haste=spell) and TargetDeadIn(more 8)
		Spell(VAMPIRICTOUCH)
	
	#shadow_word_death,health_percentage<=25
	if TargetLifePercent(less 25) and LifePercent(more 20) Spell(SHADOWWORDDEATH)
	
	#shadow_word_death,if=mana_pct<10
	if ManaPercent(less 10) Spell(SHADOWWORDDEATH)

	#mind_flay
	Spell(MINDFLAY)
}

AddIcon help=cd
{
    #archangel,if=buff.dark_evangelism.stack>=5&dot.vampiric_touch.remains>5&dot.devouring_plague.remains>5
    if BuffPresent(EVANGELISM stacks=5) and TargetDebuffPresent(VAMPIRICTOUCH 5 mine=1) and TargetDebuffPresent(DEVOURINGPLAGUE 5 mine=1)
		Spell(ARCHANGEL)
	#shadow_fiend
 	Spell(SHADOWFIEND)
    Item(Trinket0Slot usable=1)
    Item(Trinket1Slot usable=1)
}

# Add mana monitor
AddIcon help=mana mastery=3
{
    if LifePercent(less 10) 
    {
        Item(36892) #Health stone
        Spell(DISPERSION)
    }
    if ManaPercent(less 25) 
    {
        Spell(DISPERSION)
    }
}

#    Add Focus Target Monitor for Multi Dotting
AddIcon mastery=3 target=focus
{
        if TargetDebuffExpires(SHADOWWORDPAIN 1.5 mine=1) and TargetDeadIn(more 10) Spell(SHADOWWORDPAIN)
        if TargetDebuffExpires(VAMPIRICTOUCH 3 mine=1 haste=spell) and TargetDeadIn(more 8) Spell(VAMPIRICTOUCH)
}

]]
