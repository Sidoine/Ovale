[Ovale Spell Priority][ovale] is a rotation-helper addon that shows you what spell or ability you should use in order to maximize your damage.

It displays one or more icons that show the cooldown of an action. The action is conditionally defined through a user-defined script, e.g. you may display either [Corruption][] if the DoT is not on your target or [Shadow Bolt][] if the [Corruption][] DoT is already on your target.

Default scripts are based on [SimulationCraft][]. You may also customize the default script to suit your needs (see [Documentation][]) or use scripts made by other users.
Tank scripts based on guides from icy-veins.com are maintained by the [Ovale_TankScripts][] addon.

**Please use the [Discord Server][ovale-discord] to submit scripts or discuss them. If you want to report bugs, use the [ticket manager][ovale-tickets]. You may contribute code on our [Github][] project or help with [translation][].**

See the [video of a survival hunter][ovale-video] using [Ovale][] during _Wrath of the Lich King_.

# Features

-   Tracks DoTs, buffs, debuffs, cooldowns, combo points, runes, mana -- everything that a player would need to decide what to do.
-   Adapts to your talents.
-   100% configurable: everything is in an easy-to-understand script that you can modify and test in real-time without reloading your UI.
-   Compatible with the action icon skinning library [Masque][].
-   Use [SpellFlashCore][] to flash abilities on action bars in addition, or as an alternative, to displaying the ability icons.

# FAQ

### How closely are the default scripts based on [SimulationCraft][]?

The [SimulationCraft][] APL language and the [Ovale][] script language are functionally very similar and concepts from one can be translated into the other in a very direct and mechanical way. For all intents and purposes, the default scripts **are** the [SimulationCraft][] APLs imported into the game and displayed visually.

### Why is the key binding displayed for an action wrong?

You may be running an action bar addon, e.g., Bartender4, etc., that does not use the Blizzard action bar frames.

### Why is the icon sometimes red?

The cooldown that is displayed in an icon is not always the true action cooldown. If this cooldown is longer than the action cooldown, then the icon is red. In most cases, it means that if you use this action too soon, then you will overwrite or clip a DoT, which may not be what you want.

### How do I make the spells flash on the action bar?

Simply install [SpellFlashCore][] (included if you install [SpellFlash][]) and [Ovale][] will use it to flash the spell to cast on the action bar in addition to displaying the spell in the Ovale icon bar.

### Why can't I click on the icon to cast the spell?

Blizzard does not allow this. Only a predefined sequence of spells can be bound to an action icon and this sequence can not change in combat.

### On my low-level character, there is nothing at all.

You need to reach level 10 and choose a specialization. However, be aware that the default [Ovale][] scripts are tuned for max-level characters and you may be missing key abilities at low levels that are assumed to exist. If the default script is not working for you, you will need to find or write a script more appropriate for your character's level.

[corruption]: http://www.wowhead.com/spell=172
[documentation]: http://wow.curseforge.com/projects/ovale/pages/documentation/
[masque]: https://www.curseforge.com/wow/addons/masque
[ovale]: https://www.curseforge.com/wow/addons/ovale
[ovale_tankscripts]: https://www.curseforge.com/wow/addons/ovale_tankscripts
[recount]: http://www.curse.com/addons/wow/recount
[shadow bolt]: http://www.wowhead.com/spell=686
[simulationcraft]: http://code.google.com/p/simulationcraft/
[skada]: https://www.curseforge.com/wow/addons/skada
[spellflashcore]: https://www.curseforge.com/wow/addons/spellflashcore
[spellflash]: https://www.curseforge.com/wow/addons/spellflash
[ovale-discord]: https://discord.gg/PYPpCdc
[ovale-tickets]: https://github.com/Sidoine/Ovale/issues
[ovale-video]: http://www.youtube.com/watch?v=rNHvk9GpyiM "Ovale WotLK video"
[github]: https://github.com/Sidoine/Ovale
[translation]: https://crwd.in/ovale
