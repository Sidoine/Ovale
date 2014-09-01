[Ovale Spell Priority][ovale] is a rotation-helper addon that shows you what spell or ability you should use in order to maximize your damage.

  [ovale]: http://www.curse.com/addons/wow/ovale

It displays one or more icons that show the cooldown of an action.  The action is conditionally defined through a user-defined script, e.g. you may display either [Corruption][] if the DoT is not on your target or [Shadow Bolt][] if the [Corruption][] DoT is already on your target.

  [Corruption]: http://www.wowhead.com/spell=172
  [Shadow Bolt]: http://www.wowhead.com/spell=686

Default scripts are available for all dps classes and specializations, based on [SimulationCraft][].  You may also customize the default script to suit your needs (see [Documentation][]) or use scripts made by other users.

  [SimulationCraft]: http://code.google.com/p/simulationcraft/
  [Documentation]: http://wow.curseforge.com/projects/ovale/pages/documentation/

See the [video of a survival hunter][ovale-video] using [Ovale][ovale] during Wrath of the Lich King.

  [ovale-video]: http://www.youtube.com/watch?v=rNHvk9GpyiM	"Ovale WotLK video"

**Please use the [forums][ovale-forums] to submit scripts or discuss them. If you want to report bugs, use the [ticket manager][ovale-tickets].**

  [ovale-forums]: http://wow.curseforge.com/addons/ovale/forum/
  [ovale-tickets]: http://wow.curseforge.com/addons/ovale/tickets/

Features
========

- Default scripts for every DPS class and talent specialization.
- Tracks DoTs, buffs, debuffs, cooldowns, combo points, runes, mana, everything that a player would need to choose what to do.
- Adapts to your talent points and glyphs.
- Change quickly the configuration at any time with configurable checkboxes and drop-down lists that can be shown/hidden by clicking on the icons, e.g. switching between single and multi-target damage, setting the curse to cast.
- Multi-target DoT tracking: remember which target had a DoT and when the DoT will expire, allowing the script author to support multi-target dotting.
- Compatible with the action icon skinning library [Masque][].
- 100% configurable: everything is in an easy-to-understand script that you can modify and test in real-time without reloading your UI.
- Can be used to track crowd-control spells on your focus.
- Scoring system: evaluate how well you followed the script.  Add a new Ovale panel in [Recount][] and [Skada][], with a score between 0 (very bad) and 1000 (perfect).
- Up to two-spells-ahead accuracy with some classes.

  [Masque]: http://www.curse.com/addons/wow/masque
  [Recount]: http://www.curse.com/addons/wow/recount
  [Skada]: http://www.curse.com/addons/wow/skada

FAQ
===

##### Why does it not work for me?
Try to reset your Profile in the [Ovale][ovale] settings.  Most problems come from faulty scripts.

##### Why is the key binding displayed for an action wrong?
The action may be in several action bars, e.g., the bars that you can cycle through or the bars that appear in special cases like [Shadowform][] or [Cat Form][].

  [Shadowform]: http://www.wowhead.com/spell=15473
  [Cat Form]: http://www.wowhead.com/spell=768

##### Why is the key binding not displayed at all?
The action must be in your standard Blizzard action bar in order for [Ovale][ovale] to know which key binding is used.

##### Why is the icon sometimes red?
The cooldown that is displayed in an icon is not always the true action cooldown.  If this cooldown is longer than the action cooldown, then the icon is red.  In most cases, it means that if you use this action too soon, then you will overwrite or clip a DoT, which may not be what you want.

##### Why can't I click on the icon to cast the spell?
Blizzard does not allow this.  Only a predefined sequence of spells can be bound to an action icon and this sequence can not change in combat.

##### On my low-level character, there is nothing at all.
You need to reach level 10 and choose a specialization.
