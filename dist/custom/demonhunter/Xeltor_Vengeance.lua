local __exports = LibStub:GetLibrary("ovale/scripts/ovale_demonhunter")
if not __exports then return end
__exports.registerDemonHunterVengeanceXeltor = function(OvaleScripts)
do
	local name = "xeltor_vengeance"
	local desc = "[Xel][8.2] Demon Hunter: Vengeance"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_demonhunter_spells)

AddIcon specialization=2 help=main
{
	# Interrupt
	if InCombat() InterruptActions()
	
    if target.InRange(shear) and HasFullControl()
    {
		# Cooldown
		VengeanceDefaultCdActions()
		
		# Short Cooldown
		VengeanceDefaultShortCdActions()
		
		# Main rotation
		VengeanceDefaultMainActions()
    }
	
	if InCombat() and not target.InRange(shear) and { target.HealthPercent() < 100 or targettarget.Present() } and not target.IsFriend() and target.Present() and not target.DebuffPresent(imprison)
	{
		#throw_glaive
		Spell(throw_glaive_veng)
	}
}

AddFunction InterruptActions
{
 if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
 {
  if target.InRange(disrupt) and not SigilCharging(silence misery chains) and target.IsInterruptible() Spell(disrupt)
  if target.IsInterruptible() and target.Distance(less 6) and not target.Classification(worldboss) and not SigilCharging(silence misery chains) and target.RemainingCastTime() >= 2 - Talent(quickened_sigils_talent) + GCDRemaining() Spell(sigil_of_silence)
  if not target.Classification(worldboss) and target.Distance(less 6) and not SigilCharging(silence misery chains) and target.RemainingCastTime() >= 2 - Talent(quickened_sigils_talent) + GCDRemaining() Spell(sigil_of_chains)
  if not target.Classification(worldboss) and target.Distance(less 6) and not SigilCharging(silence misery chains) and target.RemainingCastTime() >= 2 - Talent(quickened_sigils_talent) + GCDRemaining() Spell(sigil_of_misery)
  if target.InRange(imprison) and not target.Classification(worldboss) and not SigilCharging(silence misery chains) and target.CreatureType(Demon Humanoid Beast) and Spell(imprison usable=1) and not PreviousGCDSpell(imprison) Texture(spell_fire_felflamering)
 }
}

AddFunction VengeanceUseItemActions
{
	if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
	if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

### actions.default

AddFunction VengeanceDefaultMainActions
{
 #consume_magic
 if target.HasDebuffType(magic) and PainDeficit() > 20 Spell(consume_magic)
 #call_action_list,name=brand,if=talent.charred_flesh.enabled
 if Talent(charred_flesh_talent) VengeanceBrandMainActions()

 unless Talent(charred_flesh_talent) and VengeanceBrandMainPostConditions()
 {
  #call_action_list,name=defensives
  VengeanceDefensivesMainActions()

  unless VengeanceDefensivesMainPostConditions()
  {
   #call_action_list,name=normal
   VengeanceNormalMainActions()
  }
 }
}

AddFunction VengeanceDefaultMainPostConditions
{
 Talent(charred_flesh_talent) and VengeanceBrandMainPostConditions() or VengeanceDefensivesMainPostConditions() or VengeanceNormalMainPostConditions()
}

AddFunction VengeanceDefaultShortCdActions
{
 #auto_attack
 # VengeanceGetInMeleeRange()

 unless target.HasDebuffType(magic) and PainDeficit() > 20 and Spell(consume_magic)
 {
  #call_action_list,name=brand,if=talent.charred_flesh.enabled
  if Talent(charred_flesh_talent) VengeanceBrandShortCdActions()

  unless Talent(charred_flesh_talent) and VengeanceBrandShortCdPostConditions()
  {
   #call_action_list,name=defensives
   VengeanceDefensivesShortCdActions()

   unless VengeanceDefensivesShortCdPostConditions()
   {
    #call_action_list,name=normal
    VengeanceNormalShortCdActions()
   }
  }
 }
}

AddFunction VengeanceDefaultShortCdPostConditions
{
 target.HasDebuffType(magic) and PainDeficit() > 20 and Spell(consume_magic) or Talent(charred_flesh_talent) and VengeanceBrandShortCdPostConditions() or VengeanceDefensivesShortCdPostConditions() or VengeanceNormalShortCdPostConditions()
}

AddFunction VengeanceDefaultCdActions
{
 # VengeanceInterruptActions()
 if target.HasDebuffType(magic) and PainDeficit() > 15 Spell(arcane_torrent_dh)

 unless target.HasDebuffType(magic) and PainDeficit() > 20 and Spell(consume_magic)
 {
  #call_action_list,name=brand,if=talent.charred_flesh.enabled
  if Talent(charred_flesh_talent) VengeanceBrandCdActions()

  unless Talent(charred_flesh_talent) and VengeanceBrandCdPostConditions()
  {
   #call_action_list,name=defensives
   VengeanceDefensivesCdActions()

   unless VengeanceDefensivesCdPostConditions()
   {
    #call_action_list,name=normal
    VengeanceNormalCdActions()
   }
  }
 }
}

AddFunction VengeanceDefaultCdPostConditions
{
 target.HasDebuffType(magic) and PainDeficit() > 20 and Spell(consume_magic) or Talent(charred_flesh_talent) and VengeanceBrandCdPostConditions() or VengeanceDefensivesCdPostConditions() or VengeanceNormalCdPostConditions()
}

### actions.brand

AddFunction VengeanceBrandMainActions
{
 #sigil_of_flame,if=cooldown.fiery_brand.remains<2
 if SpellCooldown(fiery_brand) < 2 and not SigilCharging(flame) and target.DebuffRemaining(sigil_of_flame_debuff) <= 2 - Talent(quickened_sigils_talent) + GCDRemaining() Spell(sigil_of_flame)
 #immolation_aura,if=dot.fiery_brand.ticking
 if target.DebuffPresent(fiery_brand_debuff) Spell(immolation_aura)
 #sigil_of_flame,if=dot.fiery_brand.ticking
 if target.DebuffPresent(fiery_brand_debuff) and not SigilCharging(flame) and target.DebuffRemaining(sigil_of_flame_debuff) <= 2 - Talent(quickened_sigils_talent) + GCDRemaining() Spell(sigil_of_flame)
}

AddFunction VengeanceBrandMainPostConditions
{
}

AddFunction VengeanceBrandShortCdActions
{
 unless SpellCooldown(fiery_brand) < 2 and Spell(sigil_of_flame)
 {
  #infernal_strike,if=cooldown.fiery_brand.remains=0
  if not SpellCooldown(fiery_brand) > 0 Spell(infernal_strike)
  #fiery_brand
  Spell(fiery_brand)

  unless target.DebuffPresent(fiery_brand_debuff) and Spell(immolation_aura)
  {
   #fel_devastation,if=dot.fiery_brand.ticking
   if target.DebuffPresent(fiery_brand_debuff) Spell(fel_devastation)
   #infernal_strike,if=dot.fiery_brand.ticking
   if target.DebuffPresent(fiery_brand_debuff) Spell(infernal_strike)
  }
 }
}

AddFunction VengeanceBrandShortCdPostConditions
{
 SpellCooldown(fiery_brand) < 2 and Spell(sigil_of_flame) or target.DebuffPresent(fiery_brand_debuff) and Spell(immolation_aura) or target.DebuffPresent(fiery_brand_debuff) and Spell(sigil_of_flame)
}

AddFunction VengeanceBrandCdActions
{
}

AddFunction VengeanceBrandCdPostConditions
{
 SpellCooldown(fiery_brand) < 2 and Spell(sigil_of_flame) or target.DebuffPresent(fiery_brand_debuff) and Spell(immolation_aura) or target.DebuffPresent(fiery_brand_debuff) and Spell(fel_devastation) or target.DebuffPresent(fiery_brand_debuff) and Spell(sigil_of_flame)
}

### actions.defensives

AddFunction VengeanceDefensivesMainActions
{
}

AddFunction VengeanceDefensivesMainPostConditions
{
}

AddFunction VengeanceDefensivesShortCdActions
{
 #demon_spikes,if=charges=2|buff.demon_spikes.down&!dot.fiery_brand.ticking&buff.metamorphosis.down
 if Charges(demon_spikes) == 2 or not BuffPresent(demon_spikes_buff) and not target.DebuffPresent(fiery_brand_debuff) and not BuffPresent(metamorphosis_veng_buff) Spell(demon_spikes)
 #fiery_brand,if=buff.demon_spikes.down&buff.metamorphosis.down
 if not BuffPresent(demon_spikes_buff) and not BuffPresent(metamorphosis_veng_buff) Spell(fiery_brand)
 #use_items,if=buff.demon_spikes.down&buff.metamorphosis.down
 if not BuffPresent(demon_spikes_buff) and not BuffPresent(metamorphosis_veng_buff) VengeanceUseItemActions()
}

AddFunction VengeanceDefensivesShortCdPostConditions
{
}

AddFunction VengeanceDefensivesCdActions
{
 #metamorphosis,if=buff.demon_spikes.down&!dot.fiery_brand.ticking&buff.metamorphosis.down&incoming_damage_5s>health.max*0.70
 if not BuffPresent(demon_spikes_buff) and not target.DebuffPresent(fiery_brand_debuff) and not BuffPresent(metamorphosis_veng_buff) and IncomingDamage(5) > MaxHealth() * 0.7 Spell(metamorphosis_veng)
}

AddFunction VengeanceDefensivesCdPostConditions
{
}

### actions.normal

AddFunction VengeanceNormalMainActions
{
 #spirit_bomb,if=soul_fragments>=4
 if SoulFragments() >= 4 Spell(spirit_bomb)
 #soul_cleave,if=!talent.spirit_bomb.enabled
 if not Talent(spirit_bomb_talent) Spell(soul_cleave)
 #soul_cleave,if=talent.spirit_bomb.enabled&soul_fragments=0
 if Talent(spirit_bomb_talent) and SoulFragments() == 0 Spell(soul_cleave)
 #immolation_aura,if=pain<=90
 if Pain() <= 90 Spell(immolation_aura)
 #felblade,if=pain<=70
 if Pain() <= 70 Spell(felblade)
 #fracture,if=soul_fragments<=3
 if SoulFragments() <= 3 Spell(fracture)
 #sigil_of_flame
 if not SigilCharging(flame) and target.DebuffRemaining(sigil_of_flame_debuff) <= 2 - Talent(quickened_sigils_talent) + GCDRemaining() Spell(sigil_of_flame)
 #shear
 Spell(shear)
}

AddFunction VengeanceNormalMainPostConditions
{
}

AddFunction VengeanceNormalShortCdActions
{
 #infernal_strike
 Spell(infernal_strike)

 unless SoulFragments() >= 4 and Spell(spirit_bomb) or not Talent(spirit_bomb_talent) and Spell(soul_cleave) or Talent(spirit_bomb_talent) and SoulFragments() == 0 and Spell(soul_cleave) or Pain() <= 90 and Spell(immolation_aura) or Pain() <= 70 and Spell(felblade) or SoulFragments() <= 3 and Spell(fracture)
 {
  #fel_devastation
  Spell(fel_devastation)
 }
}

AddFunction VengeanceNormalShortCdPostConditions
{
 SoulFragments() >= 4 and Spell(spirit_bomb) or not Talent(spirit_bomb_talent) and Spell(soul_cleave) or Talent(spirit_bomb_talent) and SoulFragments() == 0 and Spell(soul_cleave) or Pain() <= 90 and Spell(immolation_aura) or Pain() <= 70 and Spell(felblade) or SoulFragments() <= 3 and Spell(fracture) or Spell(sigil_of_flame) or Spell(shear) or Spell(throw_glaive_veng)
}

AddFunction VengeanceNormalCdActions
{
}

AddFunction VengeanceNormalCdPostConditions
{
 SoulFragments() >= 4 and Spell(spirit_bomb) or not Talent(spirit_bomb_talent) and Spell(soul_cleave) or Talent(spirit_bomb_talent) and SoulFragments() == 0 and Spell(soul_cleave) or Pain() <= 90 and Spell(immolation_aura) or Pain() <= 70 and Spell(felblade) or SoulFragments() <= 3 and Spell(fracture) or Spell(fel_devastation) or Spell(sigil_of_flame) or Spell(shear) or Spell(throw_glaive_veng)
}

### actions.precombat

AddFunction VengeancePrecombatMainActions
{
}

AddFunction VengeancePrecombatMainPostConditions
{
}

AddFunction VengeancePrecombatShortCdActions
{
}

AddFunction VengeancePrecombatShortCdPostConditions
{
}

AddFunction VengeancePrecombatCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_steelskin_potion usable=1)
}

AddFunction VengeancePrecombatCdPostConditions
{
}
]]

		OvaleScripts:RegisterScript("DEMONHUNTER", "vengeance", name, desc, code, "script")
	end
end