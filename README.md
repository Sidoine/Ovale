[Ovale Spell Priority][ovale] is a rotation-helper addon that shows you what spell or ability you should use in order to maximize your damage.

  [ovale]: http://www.curse.com/addons/wow/ovale

It displays one or more icons that show the cooldown of an action.  The action is conditionally defined through a user-defined script, e.g. you may display either [Corruption][] if the DoT is not on your target or [Shadow Bolt][] if the [Corruption][] DoT is already on your target.

  [Corruption]: http://www.wowhead.com/spell=172
  [Shadow Bolt]: http://www.wowhead.com/spell=686

The [current release] of Ovale provides default scripts for the following classes for *Warlords of Draenor*:

- Death Knight: Blood, Frost, Unholy
- Druid: Feral, Guardian **(Balance is NOT currently supported)**
- Hunter: Beast Mastery, Marksmanship, Survival
- Mage: Arcane, Fire, Frost
- Monk: Brewmaster, Windwalker
- Paladin: Protection, Retribution
- Priest: Shadow
- Rogue: Assassination, Combat, Subtlety
- Shaman: Elemental, Enhancement
- Warlock: Affliction, Demonology, Destruction
- Warrior: Arms, Fury, Protection

Default scripts are based on [SimulationCraft][].  You may also customize the default script to suit your needs (see [Documentation][]) or use scripts made by other users.

  [SimulationCraft]: http://code.google.com/p/simulationcraft/
  [Documentation]: http://wow.curseforge.com/projects/ovale/pages/documentation/

See the [video of a survival hunter][ovale-video] using [Ovale][ovale] during *Wrath of the Lich King*.

  [ovale-video]: http://www.youtube.com/watch?v=rNHvk9GpyiM	"Ovale WotLK video"

**Please use the [forums][ovale-forums] to submit scripts or discuss them. If you want to report bugs, use the [ticket manager][ovale-tickets].**

  [ovale-forums]: http://wow.curseforge.com/addons/ovale/forum/
  [ovale-tickets]: http://wow.curseforge.com/addons/ovale/tickets/

Features
========

- Tracks DoTs, buffs, debuffs, cooldowns, combo points, runes, mana -- everything that a player would need to decide what to do.
- Adapts to your talent points and glyphs.
- 100% configurable: everything is in an easy-to-understand script that you can modify and test in real-time without reloading your UI.
- Compatible with the action icon skinning library [Masque][].
- Use [SpellFlashCore][] to flash abilities on action bars in addition, or as an alternative, to displaying the ability icons.

  [Masque]: http://www.curse.com/addons/wow/masque
  [Recount]: http://www.curse.com/addons/wow/recount
  [Skada]: http://www.curse.com/addons/wow/skada
  [SpellFlashCore]: http://www.curse.com/addons/wow/spellflashcore

FAQ
===

##### Why does it not work for me?
Try to reset your Profile in the [Ovale][ovale] settings.

##### Why is the key binding displayed for an action wrong?
You may be running an action bar addon, e.g., Bartender4, etc., that does not use the Blizzard action bar frames.

##### Why is the icon sometimes red?
The cooldown that is displayed in an icon is not always the true action cooldown.  If this cooldown is longer than the action cooldown, then the icon is red.  In most cases, it means that if you use this action too soon, then you will overwrite or clip a DoT, which may not be what you want.

##### Why can't I click on the icon to cast the spell?
Blizzard does not allow this.  Only a predefined sequence of spells can be bound to an action icon and this sequence can not change in combat.

##### On my low-level character, there is nothing at all.
You need to reach level 10 and choose a specialization.
