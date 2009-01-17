Ovale.defaut["PRIEST"] =
[[AddCheckBox(etreinte "Étreinte vampirique")
AddCheckBox(mort "Mot de l'ombre : Mort")

Define(DEATH 32379)
Define(FORTITUDE 1243)
Define(PRAYERFORTITUDE 21562)
Define(SHADOWFORM 15473)
Define(VAMPIRICEMBRACE 15286)
Define(VAMPIRICTOUCH 34914)
Define(PAIN 589)
Define(TALENTDIVINEFURY 1181)
Define(MINDBLAST 8092)
Define(MINDFLAY 15407)
Define(HOLYFIRE 14914)
Define(SMITE 585)
Define(DEVOURINGPLAGUE 2944)
Define(SHADOWWEAVE 15332)

CanStopChannelling(MINDFLAY)

AddIcon
{
     # Mot de pouvoir : Robustesse
     if BuffExpires(FORTITUDE 5) and BuffExpires(PRAYERFORTITUDE 5) Spell(FORTITUDE)
     # Forme d'ombre
     if BuffExpires(SHADOWFORM 0) Spell(SHADOWFORM)

     if CheckBoxOn(etreinte) and TargetDebuffExpires(VAMPIRICEMBRACE 0 mine=1) 
        Spell(VAMPIRICEMBRACE doNotRepeat=1)

     if BuffPresent(SHADOWWEAVE stacks=5) and TargetDebuffExpires(PAIN 0 mine=1)
        Spell(PAIN)

     if TargetDebuffExpires(VAMPIRICTOUCH 1 mine=1)
        Spell(VAMPIRICTOUCH doNotRepeat=1)
        
     if TalentPoints(TALENTDIVINEFURY less 1) # Fureur divine
        Spell(MINDBLAST) # Attaque mentale
                  
     if TargetDebuffExpires(DEVOURINGPLAGUE 0 mine=1)
	    Spell(DEVOURINGPLAGUE doNotRepeat=1)
	
     if CheckBoxOn(mort) and LifePercent(more 95) Spell(DEATH)

     Spell(MINDFLAY priority=2)
     
     if TargetDebuffExpires(HOLYFIRE 0 mine=1)
        Spell(HOLYFIRE)
     
     Spell(SMITE)
}
]]
