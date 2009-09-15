Ovale.defaut["WARRIOR"] =
[[
Define(THUNDERCLAP 6343)
Define(SHOCKWAVE 46968)
Define(DEMOSHOUT 1160)
Define(COMMANDSHOUT 469)
Define(BATTLESHOUT 2048)
Define(REVENGE 6572)
Define(SHIELDSLAM 23922)
Define(DEVASTATE 20243)
Define(VICTORY 34428)
Define(EXECUTE 5308)
Define(BLOODTHIRST 23881)
Define(WHIRLWIND 1680)
Define(SLAMBUFF 46916)
Define(SLAM 1464)
Define(MORTALSTRIKE 12294)
Define(SLAMTALENT 2233)
Define(CLEAVE 845)
Define(HEROICSTRIKE 78)
Define(SUNDER 7386)
Define(CONCUSSIONBLOW 12809)
Define(REND 772)
Define(OVERPOWER 7384)
Define(SHIELDBLOCK 2565)
Define(SHIELDWALL 871)
Define(LASTSTAND 12975)
Define(DEATHWISH 12292)
Define(RECKLESSNESS 1719)
Define(BLADESTORM 46924)
Define(SUDDENDEATH 52437)
Define(RETALIATION 20230)

Define(DEMORALIZINGROAR 48560)
Define(CURSEOFWEAKNESS 50511)

AddCheckBox(multi L(AOE))
AddCheckBox(demo SpellName(DEMOSHOUT))
AddCheckBox(whirlwind SpellName(WHIRLWIND))
AddCheckBox(sunder SpellName(SUNDER))
AddListItem(shout none L(None))
AddListItem(shout battle SpellName(BATTLESHOUT))
AddListItem(shout command SpellName(COMMANDSHOUT))

AddIcon
{
     if List(shout command) and
       BuffExpires(COMMANDSHOUT 3)
          Spell(COMMANDSHOUT)
        
     if List(shout battle) and BuffExpires(BATTLESHOUT 3)
          Spell(BATTLESHOUT)
      
     if TargetClassification(worldboss) 
            and CheckBoxOn(demo)
            and TargetDebuffExpires(DEMOSHOUT 2)
            and TargetDebuffExpires(DEMORALIZINGROAR 0)
            and TargetDebuffExpires(CURSEOFWEAKNESS 0)
          Spell(DEMOSHOUT)
         
     if Stance(2) #Defense
     {
        if TargetClassification(worldboss) 
              and TargetDebuffExpires(THUNDERCLAP 2)
            Spell(THUNDERCLAP)
        
        if CheckBoxOn(multi)
        {
               Spell(THUNDERCLAP)
               Spell(SHOCKWAVE)
        }
        
        Spell(REVENGE usable=1)
        Spell(SHIELDSLAM)
        Spell(BLOODTHIRST)
        
        if Mana(more 10) Spell(DEVASTATE priority=2)
     }

     if Stance(3) #berserker
     {
        Spell(VICTORY usable=1)
        
		if TargetLifePercent(less 20)
		{
			Spell(WHIRLWIND)
			Spell(BLOODTHIRST)
			Spell(EXECUTE)
        }
        
        if HasShield() Spell(SHIELDSLAM)
        Spell(SHOCKWAVE)
        Spell(CONCUSSIONBLOW)
    
        if CheckBoxOn(whirlwind) Spell(WHIRLWIND)
        Spell(BLOODTHIRST)
        if BuffPresent(SLAMBUFF) Spell(SLAM)
     
        Spell(MORTALSTRIKE)
   
        if TalentPoints(SLAMTALENT more 1)
		    Spell(SLAM priority=2)

        Spell(DEVASTATE)
    }

     if Stance(1) #combat
     {
        Spell(VICTORY usable=1)
        if TargetDebuffExpires(REND 0 mine=1) Spell(REND)
        if BuffPresent(SUDDENDEATH) or TargetLifePercent(less 20) Spell(EXECUTE)
        Spell(MORTALSTRIKE)
        Spell(OVERPOWER usable=1)
     
         if TalentPoints(SLAMTALENT more 1)
		    Spell(SLAM priority=2)
 
		#Some other specs stuff, just in case
		Spell(BLOODTHIRST)
        if HasShield() Spell(SHIELDSLAM)
        Spell(SHOCKWAVE)
        Spell(CONCUSSIONBLOW)
        Spell(DEVASTATE)
     }

     if CheckBoxOn(sunder) and TargetDebuffExpires(SUNDER 5 stacks=5)
        Spell(SUNDER)
}

AddIcon
{
	if CheckBoxOff(multi)
	{
		if Stance(2)
		{
			if Mana(more 66) 
				Spell(HEROICSTRIKE doNotRepeat=1)
		}
		unless Stance(2)
		{
			if Mana(more 66) and TargetLifePercent(more 20)
				Spell(HEROICSTRIKE doNotRepeat=1)
		}
	}
    if Mana(more 50) and CheckBoxOn(multi)
		Spell(CLEAVE doNotRepeat=1)
 }

AddIcon
{
    if Stance(2) #Defense
    {
        Spell(SHIELDBLOCK)
		Spell(LASTSTAND)
		Spell(SHIELDWALL)
    }
    if Stance(3) #berserker
    {
		Spell(DEATHWISH)
		Spell(RECKLESSNESS)
    }
    if Stance(1) #combat
    {
		Spell(BLADESTORM)
		Spell(RETALIATION)
    }
    Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

]]
