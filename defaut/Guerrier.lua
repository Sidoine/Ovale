Ovale.defaut["WARRIOR"] =
[[AddCheckBox(multi "Multicible")
AddCheckBox(demo "Cri démoralisant")
AddCheckBox(tourbillon "Tourbillon")
AddListItem(cri aucun "Aucun cri")
AddListItem(cri guerre "Cri de guerre")
AddListItem(cri commandement "Cri de commandement")

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

AddIcon
{
     if List(cri commandement) and
       BuffExpires(COMMANDSHOUT 3)
          Spell(COMMANDSHOUT)
        
     if List(cri guerre) and BuffExpires(BATTLESHOUT 3)
          Spell(BATTLESHOUT)
      
     if TargetClassification(worldboss) 
            and CheckBoxOn(demo)
            and TargetDebuffExpires(DEMOSHOUT 2)
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
        
        if Mana(more 10) Spell(DEVASTATE priority=2)
     }

     if Stance(3) #berserker
     {
        Spell(VICTORY usable=1)
        
       # if TargetLifePercent(less 20) Spell(EXECUTE)
        Spell(EXECUTE usable=1)
        
        Spell(SHIELDSLAM usable=1)
        Spell(SHOCKWAVE)
        Spell(CONCUSSIONBLOW)
        
        Spell(BLOODTHIRST)
        if CheckBoxOn(tourbillon) Spell(WHIRLWIND)
        if BuffPresent(SLAMBUFF) Spell(SLAM)
        Spell(MORTALSTRIKE)
        Spell(DEVASTATE)
        
        if TalentPoints(SLAMTALENT more 1)
           and AfterWhiteHit(0.2)
          Spell(SLAM)      
     }

     if Stance(1) #combat
     {
        Spell(VICTORY usable=1)
        Spell(OVERPOWER usable=1)
        Spell(MORTALSTRIKE)
        
        Spell(REND)
        
        Spell(SHIELDSLAM usable=1)
        Spell(SHOCKWAVE)
        Spell(CONCUSSIONBLOW)
        
        Spell(DEVASTATE)
     }


     if TargetDebuffExpires(SUNDER 5 stacks=5)
        Spell(SUNDER)
}

AddIcon
{
     if Mana(more 50)
     {
        if CheckBoxOn(multi)
           Spell(CLEAVE doNotRepeat=1)
        if CheckBoxOff(multi)
          Spell(HEROICSTRIKE doNotRepeat=1)
     }
}

]]
