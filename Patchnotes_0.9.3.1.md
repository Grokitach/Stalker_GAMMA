# STALKER GAMMA 0.9.3.1 Patch

Okay okay okay, I already see the sad moods of having a fourth number to the game version. "But when is 1.0 gonna come???!". When it's ready. The goal of 1.0 will be the story rewrite. But before that, many things must be done still (although we are almost there).

This substantial, yet not major, patch contains a lot of fixes and QoLs as well as some slightest adjustments and very few new gameplay mechanics / systems / game loops.

On top of the changes below, what's coming next is converting all hideout items to craft only to clean up the traders inventories (and promote hideout crafting instead of dragging stuff from the traders to your hideout).

## Engine version
Demonized's engine update v2025.1.19

## Add-ons
- Updated 3DSS to 2.25.
- Simpington's Cocaine Animation for GAMMA. New animations for the usage of cocaine.
- Rotting meat from Hideout Furniture Expansion : Raw = 4d decay, Cooked = 10d decay. A fridge stops the decay.
- Razfarg's Scroll Fix. This should fix the "slow scrolling".
- MagsRedux updated to 2024.04.16 and deathammo set to 0 by default.
- ATHI's Mags Redux Mod Madness. It should fix all the issues and problems related to mags.
- G_FLAT's Inventory Anti-Closing. Animations now play without closing the inventory (you can eat and still manage your inventory during that the animation time).
- Momopate's proper jam chance added. Original jam probabily calculations where missing the base anomaly jam calculation (only WPO probability was accounted).
- HOWA20 Makeover from ATHI & Phant0m. HOWA can now equip a variety of scopes.
- SaloEater's Replace Shows Parts Health. Parts condition is now displayed on when replacing a part.
- Replacement of GAMMA Free Zoom by Kute's Free Zoom rewrite. Hopefully it will fix some issues related to Free Zoom.

## Audio
- Disable sound mute in X10 lab by oleh5230
- WSTFG 2.6.2 by oleh5230
- Fixed bullet to stalker impact sounds by oleh5230
- SFX Volume setting description by oleh5230
- wpn_colt1911_n sound fixes by oleh5230
- Fixed SVD suppressed NPC gunfire by oleh5230
- Weapon sprint rattle hotfix by oleh5230
- Helicopter missile sounds by oleh5230
- AK Reanimation reload sounds by oleh5230
- Tweaked greanade launcher sounds by oleh5230

## Graphics
- Disabled all instances of Depth of Field (DOF) but when the player aims with a gun.
- Mostly disabled Bloom by default (just tick "Use Weather preset" in MCM if you want to use it).
- Disable SSS Force Volumetric by default in MCM (removes unnecessary lightings washing out).

## Progression & Balance
- Removed trading and repair options and inventory for Kruglov
- Remove Kruglov inventory on death
- Removed Knot, Bat and Seraphim from stash spawns by @bogdan318
- Mostly T2 items in garbage stashes
- Slight rebalance of low tier NPC gun loadouts (less full auto rifles)
- 5% elemental resist cap to all T1 artefacts that provided elemental resistance thanks (ltx implementation by bogdan318)
- Resist cap added to surge controller. 5% for T1 10% for T2 (ltx implementation by bogdan318)
- Reduced Ballistic max res cap through artefacts caps edits
- Increased lurker tail drop chance
- Removed some too rare items of the tasks fetch list
- Ammo kit and drug kit added to certain task fetch lists
- More factions available for utility fetch tasks
- Remove Universal Weapon Kit from quest packages by veerserif
- Reduced 9x21 ammo drop quantity
- Make repair kit give +100% instead of +60% for parts by bogdan318 (slight oversight from the new gun repair system)
- Reduced some of the armors previous rad res buffs

## Gunplay
- FN F2000 has 3 rounds hyperburst (and small fix from CookBook & bogdan318)
- Reduced 5.56 AP rounds price
- Nimble weapon upgrade fix by bogdan318 
- 3DSS PKM SpecterDR scope fix by bogdan318 
- Fixed sprint animations for Saiga "Nerd" and "Merc" by bogdan318 
- BRN180 as D type
- BRN180 increased recoil to be inline with other 7.62x39
- Increased udp9 recoil
- Fixed MP155 sprint transition by bogdan318
- AK-105 tactical kits for DX8/DX9 by oleh5230 
- AK Alfa HUD FOV fix by oleh5230
- Desert Eagle sprint animation fix by oleh5230
- G36 Nimble sprint animation fix by bogdan318
- VZ61 no longer in vision/knife slot by bogdan318
- Mossberg 590 aim sway removed by oleh5230

## QoL
- Items visible in main inventory are the best condition in stack lulnope
- Satiety, Thirst and Sleepiness increments for all items are now displayed in actual % with nice icons by bogdan318
- Made belt item +carry weight UI dependent on the item condition and changed units to kg instead of grams by bogdan318
- Workshop resets rather than close on weapon repair by lulnope
- Pick lowest condition supportive material by default when repairing items by lulnope
- Magazines addons are now grouped in MO2 for an easier activation.

## Fixes
- Performance fix for Body Health System thanks to .TIHan
- Ultra wide crash fix
- Crash fix when clicking "Details" on certain items
- DX9 rpk16 crash fix
- Quick and dirty armor rad res display fix
- Setting menu tweaks by oleh5230: some bad options have been removed.
- wpn_trg_hud crash fix by oleh5230
- Fixed Hammer text typo by bogdan318 
- Grass tweaks LOD load order fix
- Restore ShAK-12/VSSK fixes by oleh5230 
- Replaced GMTOP artefacts xml by the gamma artecafts one
- Remove Thompson SMG loadouts injection by oleh5230 
- "Fetch item" task weapon list update.
- Update tasks_fetch.script by epidemicz: Fixed reward for gun fetch quest by calculating condition by average condition of all parts.
- MP-133 removed from remaining sources by oleh5230
- Fixed some artefacts values (Volat) by SD61997
- Item drop on shift transfer fix by HubertJN oleh5230
- Typo fix for .45 HP by bogdan318
- Fixed USP Match weapon parts by bogdan318
- Removed "milspec PDA information collection" by default
- Fixed strike and explosion protection stat display for armors by SaloEater
- Fixed Remington 700 crash courtesy of DIS by bogdan318
- Busyhands detection and blame disabled for performance
- Fix trade_monolith_basic supply level goodwill that used bandit faction instead of monolith by SD61997
- Remove mono_kit from WP traders by veerserif since the ak12 monolith has been removed
- Fix expert and professional ecologists using novice loadouts by SD61997
- Fix some misassigned exo armours to dick death_outfits entries by SD61997
- Fix some misassigned exo armours in death_outfits by SD61997
- ShAK-12 SUP cover tilt patch by oleh5230
- Removed mutant part and hide repair bonus text display by bogdan318
- Pseudogiant doesn't damage objects on stomp
- Fixed 9mm AUG barrel by bogdan318
- head_damage_20 section added