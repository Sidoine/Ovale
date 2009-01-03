Ovale.defaut["PRIEST"] =
[[AddCheckBox(etreinte "Étreinte vampirique")
AddCheckBox(mort "Mot de l'ombre : Mort")

# Mot de pouvoir : Robustesse
if BuffExpires(1243 5) and BuffExpires(21562 5) Spell(1243)
# Forme d'ombre
if BuffExpires(15473 0) Spell(15473)

if CheckBoxOn(etreinte) and TargetDebuffExpires(15286 0 mine=1) 
   Spell(15286 doNotRepeat=1)

#toucher vampirique
if TargetDebuffExpires(34914 1 mine=1)
   Spell(34914 doNotRepeat=1)

#mot de l'ombre : douleur
if TargetDebuffExpires(589 0 mine=1)
   Spell(589)
   
if TalentPoints(1181 less 1) # Fureur divine
   Spell(8092) # Attaque mentale
   		
if CheckBoxOn(mort) and LifePercent(more 95) Spell(32379)

Spell(15407) #Fouet mental

if TargetDebuffExpires(14914 0 mine=1)
    Spell(14914) #Flammes sacrées

Spell(585) # châtiment
]]
