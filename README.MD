# Cooldown Highlighter

![Cooldown Highlighter preview](https://i.imgur.com/VlMkyUM.gif)

A small World of Warcraft Addon that translates the spell highlight from the action bars to the new Cooldown Manager.

- Works with spells and simple /cast or /use macros
- Works with default action bar, Bartender, Dominos and ElvUI
- It is possible to detect trinket or item usage but i will implement that in the future if Blizzard decides to implement items into the CDM
- Can be used with the default CDM or the popular CDM skinning addons like Cooldown Manager Centered, NephUI: Cooldown Manager, ArcUI or BetterCooldownManager.

## Releasing

Run the **Release addon** workflow from GitHub's Actions tab on the `main` branch. Enter the addon version without a leading `v` and one or more six-digit WoW interface IDs separated by commas. The workflow updates the TOC, commits directly to `main`, creates an annotated `v<version>` tag, builds a ZIP with `CooldownHighlighter/` at its root, and publishes the ZIP in a GitHub release.
