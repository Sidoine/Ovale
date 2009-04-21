Ovale.defaut["PRIEST"] =
[[
# Define constants for easier addressing of spells
Define(SWP 589) # Shadow Word: Pain
Define(VT 34916) # Vampiric Touch
Define(VE 15286) # Vampiric Embrace
Define(SF 15473) # Shadowform
Define(MF 15407) # Mind Flay
Define(MB 8092) # Mind Blast
Define(DP 2944) # Devouring Plague
Define(SW 15257) # Shadow Weaving
Define(IF 48168) # Inner Fire
Define(Focus 14751) # Inner Focus
Define(Dispersion 47585)
Define(Shadowfiend 34433)
CanStopChannelling(MF) # Mind Flay's channeling can be interrupted if needed

# Add main monitor
AddIcon {

#Check shadowform is up
if BuffExpires(SF 0)
    Spell(SF)
    
# Refresh inner fire
if BuffExpires(IF 60)
    Spell(IF)

#if inner focus is active, cast mind blast
if BuffPresent(Focus) 
    Spell(MB doNotRepeat=1)
    
# Check if Shadow Weave is stacked 5 times
# before suggesting Shadow Word: Pain
if BuffPresent(SW stacks=5) and TargetDebuffExpires(SWP 0 mine=1)
{
   Spell(SWP doNotRepeat=1)
}

#Refresh VT
if TargetDebuffExpires(VT 1.4 mine=1 haste=spell)
   Spell(VT doNotRepeat=1)
  
#cast MB if up
Spell(MB doNotRepeat=1)
  
#Refresh devouring plague  
if TargetDebuffExpires(DP 0 mine=1)
    Spell(DP doNotRepeat=1)

#cast Mind flay if nothing else can be done
Spell(MF priority=2)

} # End of main monitor    
        
# Add mana monitor
AddIcon {

#if up, launch focus (and then MB since it's the first priority)
Spell(Focus doNotRepeat=1 usable=1)

#Regain mana if needed and if shadowfiend is not already out
if Mana(less 4000) and PetPresent(no)
{
    Spell(Shadowfiend usable=1)
    unless TargetDebuffExpires(VT 6 mine=1 haste=spell) Spell(Dispersion usable=1)
}
}

# Add icons to monitor debuffs (will show up 5 secs before elapsed)
AddIcon size=small nocd=1 {if TargetDebuffExpires(VE 1 mine=1) Spell(VE) } # Vampiric Embrace
AddIcon size=small nocd=1 {if TargetDebuffExpires(VT 1.4 mine=1 haste=spell) Spell(VT) } # Vampiric Touch
AddIcon size=small nocd=1 {if TargetDebuffExpires(SWP 1 mine=1) Spell(SWP) } # Shadow Word: Pain
AddIcon size=small nocd=1 {if TargetDebuffExpires(DP 1 mine=1) Spell(DP) } 
]]
