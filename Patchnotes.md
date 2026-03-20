# **S.T.A.L.K.E.R. G.A.M.M.A. 0.9.4 Patch Notes**  

## **Engine update**
- STALKER-Anomaly-modded-exes_2025.7.12 by Demonized

## **Newly Added Addons or Updates**
- Free Zoom update 4.32 by Kute
- Workshop optimization by Serious
- Tasks QoL Pack by Serious
- Extended MovementSFX by oleh5230
- M60 Texture Improved by Kryiron
- Improved Pulses by Momopate, activation by default
- Updated github links for Sights and Optics retexture by Meowie
- Saiga12 Textures Improvements by Norfair
- Nullpath's KSG12 + 23x75 conversion by Grok, textures and model changes by Meowie, 3DSS compatibility by AndTheHeroIs, sounds by @oleh5230
- Screenspace shaders 23 update install instructions by Ascii
- Atmospherics 2.68 appdata files update by Hippobot
- New Knife Reanimation 
- FDDA Redone by Lizzardman, all animations are enabled by default.
- FDDA Redone fixes by Kute
- Quick Action Wheel by HarukaSai + balanced (1 tab, 10 slots, no weapons) - usage by long pressing F
- Mags Redux Madness update 1.7.25 by AndTheHeroIs
- New Player Experience by Strangerism (Tutorial framework)
- Updated 3DSS guns mods by AndTheHeroIs
- Dynamic Aspect Ratio Tweaks by bellyillish
- Lizzardman's Field Strip Colors + SaloEater edits (few issues right now, will fix later)
- yaaargle's Lost to the Zone Ending DX11 Crash Fix (GAMMA) 
- ilrathCXV fix for Thistle/Black Angel/Sandstone Crash with more than … 
- G_FLAT's Individualy Recruitable Companions
- G_FLAT's Msv Above Radiation Icon
- G_FLAT's Status Icons Always Shown
- G_FLAT's More Measurement Task Maps
- G_FLAT's Unusable Parts Handler (poor parts are automatically sold unless favorited)
- Spawning Shenanigans Prevention by Kute
- EFT RSH-12 by frostychun
- ilrathCXV's Meat Spoiling Timer in Tooltips
- Items Model Drop After Usage by Kute
- RETUNE Ambiant Sounds by Aphrodite_child
- Interaction Dot Marks by Catspaw


## **Gameplay Changes & Fixes**  
- **Health System Adjustments**  
  - Removed 1.25x multiplier for negative health regeneration in display.  
  - Changed health regeneration display magnitude to show as multiples.  
  - Increased bleeding chance by 5% + minimal bleed power.
  - Defensive boost drugs rebalance: 300s duration, dmg reduce of 4% > 8% > 12%, no dizziness / thirstiness / hungriness increments, instant life recovery of 5% > 10% > 15%.
- **Radiation Effects Rebalanced**: This should avoid the "I have 5% of my rad bar I need to smoke" syndrome:
  - Better scaling of DOTs: no damage with low rads, higher damage with high rads
  - No more coughs overlap
  - Coughs delayed > only 1 hit every 9 seconds max.
  - More rads needed to start coughing
  - Faster impact of rads on max stamina - keeping low level of rads won't be dangerous for your health, only for your stamina
  - Higher max stamina threshold (can run over a short distance when being cooked)
- **Anomalies fixes**
  - Fix for anomalous field damages over time: it was based on framerate, it's now hitting every 85ms (from 5 to 12 times less damage received from fields).
  - Anomalous Field Tick rate at 85ms
  - Correct handling of Shock anomalies not dealing damage
- **Tutorial System**
  - Started by @Serious, finished by yours truly.
  - GAMMA Tutorials with Strangerism's New Player Experience.
  - Appropriate tutorials are displayed in the correct context, with dynamic  pages and related images.
  - Available tutorials: Welcome to the Zone & Tasks, Gun repair, Armor repair, Healing system, Artefacts loot craft empower, Ammo & Damage system, Vehicles system. 
- **Vehicles Changes**
  - Vehicles added to Jupiter, Zaton and CNPP
  - Vehicles explosions don't send you to the moon anymore
  - More tanky vehicles
  - Improved vehicles lights (press L to activate)
- **Less empty Zaton**
- Replace Swamps Village Ruins rat spawn @oleh5230
- Removal of Sin in MM + MM spawns changes
- Few spawn changes in MM after it's cleared
- Remove falling over animation after disabling MM @oleh5230
- Remove Rostok mutant arena and Despawn mutant arena doors @oleh5230 (performance reason + new big hideout for the player).
- Teepo's Speed script fix for proper actor speed reset after loadings
- @oleh5230 Disable unlimited saves in underground levels
- Crows play at emission start + No crows sound after sleeping
- Increased stalker pop size (0.45 -> 0.55). Decreased Stalker Squad Size for a more lively Zone (more & smaller squads).


## **Economy & Progression**
- Drug-making Kit in Agroprom Underground test @oleh5230
- Added 7.62x39 and 12.7 Vodka trades in Yantar
- Blacklist ammo and attachments from specialised traders to avoid making a lot of money @oleh5230
- Monolith traders sell both WP and NATO stuff
- Fixed artefacts drop on NPC to avoid T3/T4 spawns on them
- Bit less Shotguns, More SMGs on NPCs 
- Bit more common vector and benelli 
- Bit more common Howa 20 
- Even more rare USP TAC 45
- Fix PPSh-41 stash drops (T2 -> T3) @oleh5230 
- Rebalanced Grenades spawn.
- Monolith Blade as rare monolith drop @oleh5230 
- Added RPG7 to more NPCs categories, but at a much more rare rate.
- **Artefact crafting rebalance**
  - Increased necessary mutant parts for artefacts crafting
  - Artefacts Tier 4 recipes are now drop only (same chance as exo repair kit)
  - Increased T3 artefacts recipes book price
- **Artefacts spawning rebalance**
  - Less delay between artefacts spawn 
  - higher regular spawn chance
  - lower dynamic field spawn chance
- **Staring loadouts rebalance**
  - Update starting loadouts weapon lists (no more unique weapons that can only be found within the starting loadouts).
  - TOZ106 replaced by 4 ammo mag variant in starting loadouts 
  - Mosin cost reduced to 800 points in starting loadouts
  - Pssh starting cost increase (650) + limited to WP factions
  - Removal of UDP9 for Mercs starting loadouts
  - reduced k98 start loadout cost (1050 -> 750)
  - TT-33 starting loadout cost to 200 @oleh5230 


## **Gunplay**
- **KSG23 new gun added**: 23x75 pump action shotgun with 11 ammo
- **RSH12 new gun added**: 12.7x55 revolver
- **Jam probability and weapons degradation rework by @oleh5230**
  - All guns have a base jamming probability
  - Streamlined weapon jam probabilities
  - Suppressors increase jam chance 
  - Streamlined weapon degradation parameters
- MP5SD has 40 bullets magazine by default
- Steyr scout 7.62x51 now has +5 AP boost
- Improved 5.45 recoil balance (higher on low tier, lower on higher tier)
- Rebalanced SVDS and SVDS PMC vs SVD and SVU
- Weapon Cover Tilt update @oleh5230
- reduce AUG recoil camera dispersion @oleh5230
- SVU/DVL-10 silencer status fix @oleh5230
- Disable trail light for UBGL grenades @oleh5230
- Disable weapon collision with phantoms (cover tilt) @oleh5230
- ShAK-12 SUP recoil profile fix @oleh5230 
- MP-433 Grach Cover Tilt fix @oleh5230 
- **Some ammunition rebalance**
  - Slightly nerfed Hydroshock damage (64 -> 60) + Slightly increased hydroshock price
  - Same bullet speed and fire distance for all 9x39 rifles
  - Increased 9x39 box size by x1.16667, increased price by ~1.03
  - Decreased 7.62x39 AP price (5900 -> 5450)
  - Bit slower 9x39 to be at more realistic speeds than other bullets (co… 
  - Increased 5.45HP and 5.56HP damage, reduced penetration
  - Reduced 5.45 HP and 5.56 HP prices
  - Slight increase of 5.56 FMJ pen (27 -> 29)


## **Combat**
- Fixed FMJ vs AP rounds distribution for NPC ranks and factions 
- Merc npc now uses slug instead of buckshot 
- Duty masters use 5.45 AP instead of HP 
- Bandit masters use 5.45 AP instead of HP 
- Reduce RPG-7 missile speed @oleh5230
- NPC don't use RPG at close quarters @oleh5230
- Removal of small caliber weapons on master/legend stalkers
- Higher chance of SMGs on low rank bandits
- Sin and Mutants are Allies (works for actor too). If actor in Sin and shoots a mutant he will attack actor
- Reduced UDP9 rpm so that NPCs don't full auto with it
- Lab zombies speed increase
- Phantoms "turn around player" fix
- Story NPCs are harder to kill for the player (avoiding killing them b… 


## **Audio**
- G.A.M.M.A. No Copyrighted Music disabled by default (sorry streamers)
- Weapon sounds tweaks 2.8.3 @oleh5230
- Overall improvements of all game sounds @oleh5230
- Suppressed gunfire sounds tweaks (Pistols, 5.45) @oleh5230
- FNP-45/vz.68 reload sounds @oleh5230
- Yet another suppressed AR gunfire sound rework @oleh5230
- 9x39 gunfire/AK reload sound tweaks @oleh5230
- AK Alfa missing NPC sounds fix @oleh5230
- Better dog, cat, boar and flesh step sounds @oleh5230 
- Replaced 5,45/9x39 suppressed gunfire sounds @oleh5230 
- Replaced SVD gunfire sound @oleh5230 
- Bolt Impact Sounds addon @oleh5230 
- Better melee hit sound effects @oleh5230 
- Mutant step sounds rework @oleh5230 
- Jump and Land sounds patch @oleh5230 
- Improved vehicle sounds @oleh5230 
- Enable helicopter sounds for "Skyfall" task @oleh5230 
- Sounds Update (RSh-12 fix) @oleh5230 
- No Tinnitus Sound Effect optional addon @oleh5230 


## **UI Changes and Fixes**
- New interaction UI by CatsPaw with Interaction Dot Marks, displaying interactable items from a distance with relevant actions. The looting is not done through holding F anymore.
- Holding F now spawns the Quick Action Wheel made by HarukaSai. This allows you to use consummables or certain items fast. In the inventory, just right click items and left click on "add to wheel". Up to 10 items can be stored this way. To use an item from the wheel > Hold F and left-click the hovered item. To remove an item from the wheel, hold F and right-click it.
- LeftCtrl full armor stat radiation display fix in inventory
- Removed 1.25 multiplier for negative health regen in display @bogdan318
- Fixed health regen display magnitude @bogdan318
- Actually Open Correct Crafting on tools double click @SaloEater
- Weapon parts in the same order @SaloEater
- Actualize & Update Russian translations @ynhhoJ
- HUD toggle MCM keybind for BHS @oleh5230
- GBO/ADB settings disclaimers @oleh5230
- Slightly higher jam chance precision @oleh5230
- World Rendring Distance setting disclaimer @oleh5230
- Update Fanatic Jellyfish quest description  @veerserif
- Improved russian translations @veerserif
- Lower bolt HUD position @oleh5230 
- Move "Found nothing useful" as a displayed message instead of PDA notification @oleh5230 
- Removed rogue and stitch repair and healing dialogues


## **Fixes**
- Re-fix "Ball" seeing Jumpers as Snorks @ilrathCXV
- Reload/Unjam keybind correct text in Options menu
- AK-105 tactical kits crash fix @oleh5230
- Saiga crash fix
- Fix for exchanges of the same faction armor @SaloEater
- Disabled ZCP should not crash game @SaloEater
- Add missing mutant parts to butcher for price changes @SaloEater
- Barrier defense no more spawning upon finished @SaloEater
- Update xr_effects.script for boxless rewards  @FoxEternal
- Update dialogs_agr_u.script @FoxEternal
- Overwrite vanilla anomaly tm_lostzone_ll.ltx  @FoxEternal
- Fix loadscreen freezes by forcing texture_lod 0 @oleh5230
- Update tm_lostzone_ms.ltx to replace vanilla anomaly one  @FoxEternal
- tm_lostzone_oa.ltx to update vanilla Anomaly's and remove arti-boxes  @FoxEternal
- Update tasks_pump_station_defense.script to replace Anomaly's, remove…  @FoxEternal
- Update dialogs_lostzone.script from UNISG Trader fix  @FoxEternal
- Update tm_mlr.ltx from Anomaly, replace arti-box  @FoxEternal
- Multiple toolkits in fetch tasks fix attempt
- Gun unjam animation interruption fix @oleh5230
- anim length hotfix @oleh5230
- Unjam anim fix: speed modifiers support @oleh5230
- Unjam anim fix: motion marks support @oleh5230
- Unjam anim fix: cancel unjam if gun is holstered @oleh5230
- RF packages permanent freezes fix @oleh5230
- BAS Saiga Reanimation installation fix 
- Once again hides the accept button for buggy tasks. @Serious
- Dark Valley Bandit Base FPS optimisation as an optionnal addon (the boost isn't tremendous and the base becomes very dark) @oleh5230
- Fixes Black Market crash @Serious
- Fixes Black Market exploit. @Serious
- Fixes crash when trying to use mechanic vice while ZCP is turned off. @Serious
- Fixed missing RPK-16 parts for DX9 @oleh5230
- Saiga Reanimation sprint anim patch @oleh5230
- Walther P99 sprint anim fix @oleh5230
- Better stats bar moved to disabled category
- Thicc russian reticles disabled by default because of certain conflicts
- Guns have their condition set properly to 83% when moved to player inventory
- @oleh5230 fixed RPG NPCs prioritizing pistols
- Fix for starting guns being damaged
- @oleh5230 TCWP for DX9 free zoom fix
- @oleh5230 Saiga-12 shell_bone fatal error fix
- @oleh5230 X-16 companion NPC fatal error fix by Longreed
- @oleh5230 OTs-4 knife stats fix
- Better Quickdraw spawn_antifreeze fix @Demonized
- @oleh5230 Include addon items in trade presets
- FDDAR Patches for DX9 and when not using Beef's NVGs
- @lulnope fix disguise issue where NPCs aggro after losing disguise even if the… 
- @MyNameIsAnon Spleen no longer asks for additional Expert Tools 
- @oleh5230 Saiga-12 TPP position fix
- Better GAMMA Disabled and End of Modlist Separators
- FDDAR No BNVG compatibility fix

_____________________________________


# **S.T.A.L.K.E.R. G.A.M.M.A. 0.9.3.1 Patch Notes**

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

_________________________________________

# **S.T.A.L.K.E.R. G.A.M.M.A. 0.9.3 Update - 3rd Anniversary Patch Notes**

## New addons
Thanks to all the modders and this wonderful modding community without which this project wouldn't exist.

 Guitar Position Fix	 - VodoXleb	https://www.moddb.com/mods/stalker-anomaly/addons/modded-exes-guitar-position-fix-v2

 Gunslinger Binoculars	 - vektacitys	https://www.moddb.com/mods/stalker-anomaly/addons/gunslinger-binoculars

 Stealth Kill Detection Fix	 - Catspaw	https://www.moddb.com/mods/stalker-anomaly/addons/stealth-kill-detection-fix

 THAP Re-work	 - Max_im16	https://www.moddb.com/mods/stalker-anomaly/addons/thap-re-rework

 Barbed Wire Shadow Fix	 - VodkaPivin	https://www.moddb.com/mods/stalker-anomaly/addons/barbwire-shadow-fix

 GAMMA Portugues Brasileiro Traducao	 - PedroAmaral89	 https://www.moddb.com/mods/stalker-anomaly/addons/gamma-ptbrv1-localisation-pedro

 FDDA Enhanced Animations	 - lizzardman	https://www.moddb.com/mods/stalker-anomaly/addons/fdda-enhanced-animations-enhanced

 Get out of my way you stupid NPC	 - NewbieRus	https://www.moddb.com/mods/stalker-anomaly/addons/get-out-of-my-way-you-stupid-npc

 Anomaly Subtitles	 - AntGlobes	https://www.moddb.com/mods/stalker-anomaly/addons/anomaly-subtitles

 Mugging Squads	 - Demonized	https://www.moddb.com/mods/stalker-anomaly/addons/modded-exes-mugging-squads

 Guitar Animation	 - Daiviey	https://www.moddb.com/mods/stalker-anomaly/addons/guitar-animation-for-full-enjoyment

 Headgear Animations	 - lizzardman	https://www.moddb.com/mods/stalker-anomaly/addons/headgear-animations

 Armsel Protecta Reanimation	 - NickolasNikova	https://www.moddb.com/mods/stalker-anomaly/addons/armsel-protecta

 Even More Hideout Furnitures	 - facelessez	https://www.moddb.com/mods/stalker-anomaly/addons/even-more-hideout-furniture

 PS6 Voin and Aztec NPCs Overhaul	 - Strogglet15	https://www.moddb.com/mods/stalker-anomaly/addons/fvm-ps6voinaztec-overhaul

 MK18 Mjlonir Reanimation	 - NickolasNikova	https://www.moddb.com/mods/stalker-anomaly/addons/mk-18-mjolnir-reanimation

 Aydins Grass Tweaks SSS Terrain LOD Compatibility	 - aytabag	https://www.moddb.com/mods/stalker-anomaly/addons/aydins-grass-tweaks-sss-terrain-lod-compatiblity

 Meadow Terrain Mask Fix	 - zorius	https://www.moddb.com/mods/stalker-anomaly/addons/meadow-terrain-material-mask-fix-by-zorius1

 Workshop Parts Inventory	 - strangerism	https://www.moddb.com/mods/stalker-anomaly/addons/workshops-parts-inventory

 Hideout Furniture Expansion Ammo Box Patch	 - pesta	https://www.moddb.com/mods/stalker-anomaly/addons/hideout-furniture-expansion-ammo-box-patch

 NPCs Don't Attack Boxes	 - OnTuMuCT	https://www.moddb.com/mods/stalker-anomaly/addons/npc-dont-attack-boxes

 Disassembly Item Tweaks	 - Asshall	https://www.moddb.com/mods/stalker-anomaly/addons/disassembly-item-tweaks

 Return Menu Music	 - Mirrowel	https://www.moddb.com/mods/stalker-anomaly/addons/return-menu-music

 Pripyat Department Store Open Doors	 - ComradeCatilina	https://www.moddb.com/mods/stalker-anomaly/addons/pripyat-department-store-open-doors

 Glowsticks Reanimated	 - lizzardman	https://www.moddb.com/mods/stalker-anomaly/addons/glowstick-reanimated-v11

 Outfits Animation	 - lizzardman	https://www.moddb.com/mods/stalker-anomaly/addons/outfit-animations-v099

 Parallax Reflex Sights	 - party_50	https://www.moddb.com/mods/stalker-anomaly/addons/parallax-reflex-sights

 Tosox Mini Mods Repo	 - Tosox	https://www.moddb.com/mods/stalker-anomaly/addons/tosox-mini-mods-repo

 Bar Map Edits	 - Karobeccary	https://www.moddb.com/mods/stalker-anomaly/addons/map-edits-bar

 Overheat Gunsmoke	 - party_50	https://www.moddb.com/mods/stalker-anomaly/addons/overheat-gunsmoke

 Radial Quickslots	 - NLTP_ASHES	https://www.moddb.com/mods/stalker-anomaly/addons/radial-quickslots

 New Tasks	 - iTheon	https://github.com/lTheon/iTheon-New-Tasks-Addon

 DesertTech MDR Pack	 - Andtheherois & Bert	https://www.moddb.com/mods/stalker-anomaly/addons/iwp-mp9-anomaly

 IWP Benelli	 - frostychun	https://www.moddb.com/mods/stalker-anomaly/addons/iwp-benelli-m1014-shotgun

 Random RPK Reanimation	 - Firebreath	https://www.moddb.com/mods/stalker-anomaly/addons/random-rpk

 IWP MP9	 - frostychun	https://www.moddb.com/mods/stalker-anomaly/addons/iwp-mp9-anomaly

 BAS Pistols Reanimation Pack	 - frostychun	https://www.moddb.com/mods/stalker-anomaly/addons/bas-pistols-reanimation-pack

 Mark Switch	 - party50 & meowie	https://github.com/andtheherois/Mark-Switch-10-GAMMA-ver.

 3DSS for GAMMA	 - Redotix99 & Andtheherois & party50	https://github.com/Redotix/3DSS-for-GAMMA

 Renegades Fixed Ports Collection	 - Cr3pis	https://www.moddb.com/mods/stalker-anomaly/addons/dltx-renegades-fixed-ports-collection

 Busyhands Detection and Blame	 - RavenAscendant	https://www.moddb.com/mods/stalker-anomaly/addons/watch-dog-script

 Milspec PDA	 - Catspaw	https://www.moddb.com/mods/stalker-anomaly/addons/milspec-pda-for-anomaly-151-152-and-gamma

 Alternative Pseudogiants	 - KynesPeace	https://www.moddb.com/mods/stalker-anomaly/addons/alternative-pseudogiants

 M98B Reanimation	 - frostychun	https://www.moddb.com/mods/stalker-anomaly/addons/m98b-reanimation-for-gamma

 Devices of Anomaly Redone	 - BarryBogs	https://www.moddb.com/mods/stalker-anomaly/addons/devices-of-anomaly-redone

 New Extensible RF Sources	 - Catspaw	https://www.moddb.com/mods/stalker-anomaly/addons/new-extensible-rf-sources

 Dynamic Icons Indicators	 - HarukaSai	https://www.moddb.com/mods/stalker-anomaly/addons/dynamic-icon-indicators

 Artefacts Belt Scroller	 - Demonized	https://www.moddb.com/mods/stalker-anomaly/addons/artefacts-belt-scroller-ui

 Tactical Compass	 -  explorerbee	https://www.moddb.com/mods/stalker-anomaly/addons/tactical-compass

 AK Family Reanimation	 - NickolasNikova	https://www.moddb.com/mods/stalker-anomaly/addons/ak-reanimation-moddb-release

 Desert Eagle Re-animated	 - TheShinyHaxorus	https://www.moddb.com/mods/stalker-anomaly/addons/desert-eagle-re-animated

 Mossberg 590 Reanimation	 - SoulCrystal	https://www.moddb.com/mods/stalker-anomaly/addons/mossberg-590

 Weapon Inertia Expanded	 - lizzardman	https://www.moddb.com/mods/stalker-anomaly/addons/weapon-inertia-expanded

 Dynamic News Manager Fixes and Tweaks	 - dEmergence	https://www.moddb.com/mods/stalker-anomaly/addons/dynamic-news-manager-fixes-and-tweaks/

 Dynamic Emission Cover	 - Utjan	https://www.moddb.com/mods/stalker-anomaly/addons/dynamic-emission-cover

 IWP SV98 3DSS	 - Andtheherois & IWP Team	https://github.com/andtheherois/3DSS-IWP-SV98-Port

 Authentic Reticle for 3DSS	 - Napolemon	https://www.moddb.com/mods/stalker-anomaly/addons/authentic-reticle-collection-for-3d-shader-scopes-for-gamma

 The Covenant Weapon Pack 3DSS	 - Andtheherois & TCWP Team	https://github.com/andtheherois/3DSS-The-Covenant-Weapon-Pack---ATHI-Edit

 M98B 3DSS Update	 - Andtheherois & frostychun	https://github.com/andtheherois/3DSS-M98B-Reanimation

 3DSS ISG AK Makeover & BAS Team	 - Andtheherois	 https://github.com/andtheherois/3DS-ISG-AK-Makeover

 BRN-180 Assault Rifle	 - JMerc75	https://www.moddb.com/mods/stalker-anomaly/addons/brn-180-assault-rifle

 UDP-9 Carbine	 - Pilliii	https://www.moddb.com/mods/stalker-anomaly/addons/pilliis-udp-9-carbine

 3DSS M4A1 Siber Reanimation	 - Andtheherois	https://github.com/andtheherois/3DSS-M4A1-Siber-Reanimation

 Fixed Artifact for Anomaly	 - Strogglet15	https://www.moddb.com/mods/stalker-anomaly/addons/fafa

 Alpha AKM Reanimation	 - SeDzhiMol	https://www.moddb.com/mods/stalker-anomaly/addons/alpha-akm-reanimation

 Weighted NPC Random Loadouts	 - SD	https://www.moddb.com/mods/stalker-anomaly/addons/weighted-npc-random-loadouts

 Sights and Optics Retexture	 - Meowie	https://github.com/andtheherois/Sights-and-Optics-retexture-by-Meowie

 The Covenant Weapon Pack for DX9	 - TCWP Team	https://www.moddb.com/mods/stalker-anomaly/addons/tfcwp-the-former-covenant-weapon-pack


***

## Gameplay Changes
### Gun Repair System Streamlining
- Guns do not have %-based conditions anymore.
- Gun parts can be repaired in the same manner outside and inside a given gun: parts above 60% can be cleaned using cleaning kits ; parts below 60% can be repaired using a gun repair kit.
- Gun parts can be repaired within guns with the right-click > maintenance > clean/repair part X like before.
- Gun lubes, gun sprays, ramrods and files are now used as crafting materials for gun cleaning and repair kits.
- Parts within a gun degrade when shooting.
- Guns now display the "Jam Chance Probability" stat which is based on the parts condition.

### Accurate %-based defense values
- The defense values are now displayed as % in the inventory screen instead of meaningless bars.
- Defense values caps are also displayed (maximum resistance).
- All the discrepencies between item cards and actual defense values used by the damage reduction formula are fixed - but for the radiation resistances (will fix later, radiation res is complex to display as it corresponds to a reduction in radiation levels per second).

### Belt Items 2.0
- Complete rework of all stats of all belt items: Artefacts, Pelts and Tech items.
- Only one pelt can be equipped at a time.
- Pelt conditions depend on the knives you have in your inventory. Pelts condition range is indicated in each knife stats. Upgrading your knife is now really important to get the best stats for your pelts.
- Pelts are x4 more common than before.
- Tech items upgrade recipes rebalance.
- Artefacts values are tiered in 5%, 10%, 15%, 20% etc increments. Negatives have been reworked to use new mechanics such as positive / negative bleed recovery, positive / negative radiation resistance, positive / negative carry weight, on top of the classic resistances. For more information see  the paragraph below and see the following Miro board: https://miro.com/app/board/uXjVKaB9zO4=/?share_link_id=535823804635

### Artefacts Remake
- Artefacts do not emit radiations anymore. Instead, some artefacts reduce radiation resistance, some others increase radiation resistances. This stat works the same way as helmet and armor radiation resistance.
- Artefacts now increase resistances cap: all defenses are capped at 65% maximum damage reduction. By using specific artefacts builds, the player can reach 95% resistance and caps in for certain damage types.
- Removal of the artefacts containers.
- Artefacts crafting remade: all recipes need mutant parts and artefacts. T0 > T1 and T1 > T2 artefacts crafting only require one artefact. T2 > T3 and T3 > T4 require two artefacts and mutant parts.
- Removed artefacts melter charges for crafting recipes.
- Artefacts South > North spawn gradient has been remade: T3 and T2 artefacts will be harder to find in general.
- Artefacts spawn logic brought back to vanilla behavior: artefacts type spawn in relation with the Anomalies type (fire in fire, etc).
- Artefacts take longer and longer to spawn while staying in a given map: artefacts spawn frequency is high when entering a map, and is progressively reduced while remaining in a given map. When moving to another map, the frequency is high again and gradually decreases...
- An equipped detector will passively indicate if nearby artefacts are detectable with a status icon. This can be disabled in MCM.

### Bleed System Rebalance
- Bleed power has been increased by a large margin: bleeds are now extremely dangerous and can kill you in seconds.
- Bleeds are much more random: each hit will not trigger a hit.
- Bleed power depends on your health after being hit: if you get hit and have only few HP left, the bleed damages will be low compared to surviving a hit with a lot of health.
- Bandages bleed reduction is happening over time instead of being instant: you need to upgrade bandages to tourniquets to properly heal strong bleeds. Sometimes it is better to use a red medkit and then a bandage to recover from a bleed.
- Positive bleeding recovery artefacts build will quickly remove bleeding without the need of medical items while positive passive healing artefacts will greatly help stabilizing the bleed damages and allow fast health recovery during combat. 

### Armor Rebalance - baby steps
- Slight armor rebalance to address the most broken armors.
- Generally reduced endgame ballistic resistances
- Increased radiation resistances of scientific armors
- More af slot for all armors
- Proto Exos now need Heavy Repair kits instead of Exo Repair kits.
- Altyn ballistic resistance has been improved, as well as its telepatic protection, but the rad res has been reduced

### Remade all NPCs Loadouts based on a new high-quality gun list of over 150+ guns
- Took advantage of the new npc loadouts weight system by TD to carefully set weapons rarity and differiante Factions identity even more.
- If you think some powerful guns are too common, tell me.
- Edited chances for scopes, gl and silencers to spawn on guns to be lower than before.

### Smaller changes
- Heavy Metal Magazines replace Porn mags
- Magazines, Cards and Journals allow to pass time
- Radiations cannot reduce your stamina to 0, only to 15% max (walk only)
- Bread Artefact is replaced by a bolt: this should allow a better on boarding for new players.
- Bolt packs only give bolts
- Axe to vision slot + Increased axe hit distance and splash radius
- Quick knife can't be used while being equipped with a melee item
- Display of Melee weapons damage and penetration stats
- NPCs detect disguised player more easily
- Removal of Electric Anomalies blue screen effect
- Doubled electric anomalies accumulation time (easier to throw bolt > runthrough)
- Increased electro mines radius

***

## Gunplay Changes
- 3DSS added for all guns thanks to the painstaking work of Andtheherois and the amazing code from Redotix.
- Snipers have +5 AP.
- Snipers aim down sight speed is much faster.
- Some heavy guns aim down sight speed is much slower.
- Exo armors reduce guns enhanced recoil effects.
- 7.62x39 damage increased from 40 to 45.
- Reduced 9x39 ammo box size from 15 to 12 (more expensive, harder to craft).
- Reduced Slugs damage to actor to avoid double shotgun one shot early on.
- MP5SD recoil reduce and accuracy increase: it is now one of the best 9x19 SMG.
- Reduced MP9 accuracy (was too high) increased RPM.
- Glock Hornet fixed and recoil reduced.
- Benelli and MP155 as C tier.
- BAS MP153/155 removed.
- Desert Eagle has a proper muzzle climb effect when shooting continuously.
- USP 45 Tactical added (9x19 top of the line guns are too crowded).
- SIG226 upgrade kit is now sold by T1 NATO traders.
- AN-94 initial hyperburst in full auto
- Weapon Cover Tilt offset update: short guns should be able to be moved closer to the walls without triggering the tilt.
- .338 federal as proper hunting round
- Deer hunter as 338 Federal

***

## Progression Changes
- Traders buy items above 5% condition instead of 50%.
- New repeatable and non-repeatable quests thanks to iTheon New Task addon. This includes some multi-step quests.
- The Brainscorcher and the Miracle Machine should both be disabled to be able to progress to the North. Artefacts and anti psi drugs will not be able to protect you against the scorcher Psi-barrier.
- The Radar map and the Brainscorcher have been made a bit easier (less monolithans, less powerful monolithans).
- Progressive toolkits: your first yellow stash will always spawn a basic toolkit if it spawns a toolkit. Then your next stashes will be able to spawn an advanced kit. Then your next stashes will be able to spawn an expert kit: you can't have an advanced toolkit super early. This will also address to some extent the North factions progression (monolith, sin etc).
- T3 and T4 artefacts recipes can only be bought from the North Ecologist traders.
- Lv 1 NVG is harder to craft and can't be bought
- Scientific Detector from Grizzly Detector, no more elite detector
- Marsh Scientist field task rewards random artefacts instead of Lead Box
- Jupiter task rewards a random artefact instead of a lead box
- Easier Swamp CS storyline military and renegades squads
- +8kg base weight to better manage early game
- removal of survival kit in starting loadouts
- PSUs recipes don't need AAMs anymore
- Knives influence mutant condition parts
- Added antibio chlor sulfad and antiemetic to NPCs lootpools
- Yellow stashes probability = 50% instead of 99%
- Number of tasks to complete for yellow stash 8 -> 7
- Removed the option to trade Groza for Groza Storm at Nimble
- Radar stashes doesn't drop expert toolkits (this is to prevent AW farming early and before completing the brainscorcher).
- ISG MP5SD start cost increase
- Enemies in Agroprom Underground should now respawn: this should trigger a new sakharov task.
- No more knot, seraphim and bat in RF packages

***

## Audio Changes
- Oleh's Weapon Sound Tweaks For GAMMA v2.7 (better guns sounds for actor and NPCs, better match between animation and sound timings, etc). Oleh is the GOAT.
- Bullet and Grenade Impact Sounds: the sounds will change based on the material bullets and grenades enter in colision with.
- GAMMA WPO Jam Player Voice FIX by MrShersh.
- Fixed melee on mutants hit sounds.
- Reduced chance for voiced actor kill confirm.
- Changed shotguns suppressed sounds.

***

## Graphics Changes
- Diolator Grizzly detector texture
- Pulse anomalies brightness fix

***

## Fixes
- 1087 crash for various languages (Russian, French, English). This was mostly due to `%` characters in the loadscreen XML file that should be `%%` to not crash.
- Auto r_3dfakescope to 1 if 3DSS is activated or 0
- Removed the random decrease of lucifer condition on level transition
- Animation scripts update
- Free Zoom fixes
- Free_Zoom pistol mult at 1 by default
- Removal of craft tooltip info for scrap wood and fasteners
- Fix of Squad size code in ZCP and changes since the code has been fixed
- grok_no_npc_friendly_fire mutant hit error fix
- Potentially reduced prefetcher memory footprint
- BAS unjam camera anims fixes
- vityaz position fix
- Old Blindside Reanimation - Temporary
- Remove redundant settings menu options
- Mechanic inventory upgrade fix for certain items
- Hide settings overwritten by ZCP/SSS
- M4 Butcher removal since it's bugged to the bone
- Covenant Weapon pack for DX9 compatibility
- Stashes should only spawn "legal" guns now (the same as the one spawned on the NPCs)

________________________________________

# **S.T.A.L.K.E.R. G.A.M.M.A. 0.9.1 Christmas 2023 update Patch Notes**

**Launcher**
- New v6.0.0.0 Launcher, check the discord announcement channel for more information: it now uses a portable git client to download and update GAMMA, GAMMA Large Files, and Gunslinger Guns in a much faster a reliable manner + many other fixes.
- Fixed modlist for new Launcher

**Engine**
- New EXE version by Demonized v2023.12.17

**New Addons**
- AS VAL Reanimation by Sedzhimol
- 9x39 Family Beautification by Blackgrowl
- Psysucker redone by Gergi2000
- Smooth Campfire Illumination by MrWhite
- Optimised World Models by Burn
- FDDA Enhanced Animations by Mirrowel & MFS Team & Gunslinger Team
- ylyxa's Alt Aim Views for guns with Lasers

**Performance**
- Optimised Guns World models by Burn, fixes many FPS issues in certain maps like Agroprom, Dead City and Rostok

**Gunplay**
- Added ADAR, PKP and PKM BAS 2022
- Added Retrogue's AMB17 in game
- RD-9x39 remade model and fixed animations: no canted sight, 30 rounders magazine model, fixed grenade launcher animations, fixed shoot animation clipping.
- Doubled PKM rounds per box (easier crafting)
- MP5 supports BAS scopes
- SV98 shoot cam animation
- Nimble trades PKM for PKM Zenit
- AMB17 = lowest 9x39 recoil
- Increased Thompson damage to match UMP
- Adjustable 1p59 scope for Vihr 9a91 and Val
- Stealth bonus for weapons shooting subsonic bullets by Oleh
- AK104 Alfa fixed cam anim shot
- ADAR Repair as B type

**Audio**
- Weapon Sounds Tweaks and Fixes v1.11.1 by Oleh

**Gameplay **
- Fentanyl exo animations
- Nerfed grenades spawn chance (/5)
- NPC Loadouts changed for 9x39 and less silencers on pistols
- Craftable Hideout Expansion items

**Fixes**
- Many FreeZoom fixes: Free Zoom aim toggle and no weapon scenarii fixes, Melee zoom fix, Free Zoom fire bug fixed in 95% of the cases, Fix for Free Zoom FOV not resetting properly when reloading, fix for aim toggle, weapon fire unzoom priority fix
- Gavrilenko task crash fix again
- Small bandwith and storage space gain by downloading a 2ko dummy addon for useless addons.
- Item pickup device pull bug fix
- Fixed artefacts conditions resetting when empowering them and for junk artefacts
- PU scope radius fix
- Mocked large github files coming from github
- SVU HUD FOV Fix
- Disabled Take item and Backpack animations because of busy hands
- Vityaz THAP Hands patch
- Alt Tab Scroll Issue fix by DPurple
- Vihr aim and sound fixes
- No Silencer upgrades for winchester
- Oleh's Scopes zoom patch + Weapon Cover Tilt offset values update 
- PSU Reactor description adjusted to remove the wrong info about power
- Loadout injector disabled + fort17 isg new game loadout removed by n0x
- Utils UI Icon offset fix thanks to RavenAscendant and Burn
- Built-in silencer compatibility for some weapons (to use stereo sounds)
- No Red Flavor text for GMTOP guns
- Fixed trade presets by n0x

___________________________________

# **S.T.A.L.K.E.R. G.A.M.M.A. 0.9.1 2nd Anniversary Update Patch Notes**

**New Engine version thanks to Mr.Demonized and team**
- Engine exe v2023.11.15


**New Addons**
- M249 Reanimation	by NickolasNikova	https://www.moddb.com/mods/stalker-anomaly/addons/m249-reanimation
- SV98 Reanimation	by NickolasNikova	https://www.moddb.com/mods/stalker-anomaly/addons/sv98-trg42-reanimation
- RPD Reanimation	by NickolasNikova	https://www.moddb.com/mods/stalker-anomaly/addons/rpd-reanimation
- AK12 Reanimation	by SeDzhiMol	https://www.moddb.com/mods/stalker-anomaly/addons/bas-ak-12-reanimation
- Steyr Scout	by JMerc75	https://www.moddb.com/mods/stalker-anomaly/addons/dltx-steyr-scout-dual-pack
- Lurker HD Remodel	by KeatonB_08 & KynesPeace	https://www.moddb.com/mods/stalker-anomaly/addons/hd-lurker
- Grey Tree Barks Begone	by Joe325	https://www.moddb.com/mods/stalker-anomaly/addons/grey-tree-barks-begone
- Global Map Rework	by DeadEnvoy	https://www.moddb.com/mods/stalker-anomaly/addons/global-map-rework
- Pretty Pistols Reanimated	by FIREBREATH	https://www.moddb.com/mods/stalker-anomaly/addons/pretty-reanimated-pistols
- GAMMA Reload Timing Fix	by aegis27	https://www.moddb.com/mods/stalker-anomaly/addons/gamma-reload-timing-fix
- BAS SR-2M Reanimated	by Synd1cate	https://www.moddb.com/mods/stalker-anomaly/addons/dltx-bas-sr-2m-reanimated
- No More Flashlights on BAS Weapons	by MotaRin	https://www.moddb.com/mods/stalker-anomaly/addons/no-more-flashlights-on-weapons-bas
- Winchester 1892	by billwa	https://www.moddb.com/mods/stalker-anomaly/addons/dtlx-winchester-1892
- Fixed BAS AK74 thumb by LilJma    https://www.moddb.com/addons/bas-aks-animation-tweak
- AlphaLion's Reworked Stash Quest and Map Markers
- Improved Quick Melee by Daimenex


**Progression**
- Self Made Upgrades do not require tools nor toolkits anymore. The crafting of upgrade kits is still locked behind toolkits however.
- Mechanics have a chance to sell upgrade kits of all 3 rarities once basic tools are delivered.
- Mechanics do not upgrade items anymore but explains instead how to repair your gear and craft items with the free workbench.
- Fixes the Loner and Merc Mechanics in Zaton by TheFlameTouched. They will now have tools quests like other mechanics.
- Change military to monolith patches for Duty Tasks by The3ase.
- Removed first rooms monolith in X10 to avoid the player to die just after the loading. Also removed the problematic NPC that could block the door.
- Hint that Miracle Machine Protects the Radar by emitting psy waves in�
- Nomad and Wastelander suits are back in stashes
- Bigger lurker squads and more random
- Smaller south lurker squads
- Starting helmet = Ranger Mask for Monolith and Sin
- New Starting guns: Loners = OC33 / Freedom = Auto Glock19 40rnds / Clear Sky = Winchester / Military = Bizon


**Gameplay**
- Reduced boars hitbox (95% speed perpendicular jump works)
- Artefacts now spawn with a random delay to be less predictable and avoid potential back to back spawning (can still happen very rarely)
- Reduced amount of guards
- Zombies now have proper guns loadouts
- Jupiter Underground is now properly blacklisted so that it doesn't spawn that many artefacts while visiting the level (artefacts will still respawn after emissions and psy storms, just like regular labs)


**Gunplay**
- Less spongy enemies
- Headshot eyes jaws stronger AP bonus
- No armored balaclava / base gas mask on NPCs
- Weapon Sway on by default. Moving while aiming should make the sight move based on your movement speed.
- Update lower_weapon_sprint.script for the newly added weapons. 
- Increased weapon running animations diversity
- Increased Buckshot and Slugs damages & Slugs AP +1
- Steyr Scout added (7.62x51 variant with 5.56 skin)
- Gunslinger FN57 added
- Gunslinger Full auto glock added with 40 rounders
- XM177 (XM4) added to the loadouts and stashes
- Rebalanced XM4 and M4 recoil
- Better XM4 Inspect animations
- Better XM4 Icons by Cr3pis
- Winchester 1873 added to the game.
- Removal of caliber switch upgrades of the Winchester
- Adjusted winchester damage, bullet speed and RPM 
- Winchester Better icons by Cr3pis
- Better actor fire sound for the Winchester by adding sound layers.
- Replaced AK105sp by AK12
- L96 7.62x51 removal + more common L96 .338 Lapua
- BAS USP Tac removal
- AR15 HERA removed
- FN F2000 Recoil Reduced, this is the new HERA, + it has a grenade launcher. FN F2000 was always a staple in the Stalker franchise, now it's the case also in GAMMA.
- AK12 recoil rebalances
- 7.62x51 recoil revamp + Ace52 enhanced recoil
- removed AK104Alfa aimed shot camera anim
- Restored some BAS anm_shots
- Nerfed K98 Mod scope zoom power
- Streyr Scout repair type = rifle kit
- Adjustable SV98 scope + better texture


**Balance**
- Less tanky hard and medium boars by Balathruin
- Less tanky fleshes
- Increased armors mutant damage res by x1.20
- Increased Rhino PSU power duration and made Noso speed at 98% instead of 100%
- Balance for purified psysucker meal by The3ase
- 7.92x33 craft abuse fix and price reduction
- 338 Federal craft recipe change
- increased plastic part from dynamic spawns
- rebalanced pistols HP stock of butcher
- Boosted most mutants pelts
- More common SPAS12 and Trenchgun
- More Common UMP45
- higher AP heads chance in the dynamic loot
- Small chance of powder cans spawn in the dynamic loot
- Increased giants loot
- small chance to redirect mutant hits from legs to arms or torso
- Bit more guns in stashes
- Some rare weapons are a bit more common
- More common FAL OSW


**Visuals**
- RPD Better textures by Cr3pis
- Winchester better textures by Cr3pis
- PP2000 better textures by Cr3pis
- Better FN F2000 Icons by Cr3pis <3
- More "GAMMA" map icons colors + better blend in
- Improved 7.62x51 particles for SR25 and FALs
- Improved SCAR casings particles
- Fixed SR25 ammo getting out of the gun during empty reload
- SR25 HUD FOV change


**Quality of Life**
- cleaned guns task lists
- Reduced thirst and hunger noises volume
- Better winchesterr icon by Cr3pis
- Customizable Pistol HUD FOV in Free Zoom
- New script-based per weapon HUD FOV


**Bugfixes**
- Climbing cannot kill you
- XCVB's More stable artefacts random condition. Empowered artefacts should not reset anymore.
- Item Drag and Drop doesn't work in trade mode to fix abuses
- Companions guns are always empty (no ammo cheese)
- No NPC friendly fire + relation reset if allies shoot each other
- Proper Gigant Jumper Loot
- Utjan's Item UI Improvements install fix
- syndicate saiga install fix
- Defended X10 Labs install fix
- Double item craft tooltip fix
- Add mags to weapons that are missing mags by TheDjinni
- Potential Fix for Steppe Eagle bugs by TheDjinni
- Gives a mag to the MP7's alt caliber by TheDjinni
- Adds the correct description for the MP7 mag by TheDjinni
- Uses the updated description for its mag by TheDjinni
- fixed aslan lottery patches number dialog
- Butcher sells 5.56 HP
- Removed L85 M3 from the game, might reintroduce it when stuttery walk animation is fixed
- Updated reshade shaders by Hippo
- NPC Loot claim better check and looted list proper reset, this should avoid the impossibility to interact with alive NPCs or stashes. This should also prevent certain instances of busy hands.
- Updated FDDA to moddb version, hopefully less busy hands with the updated code. This should speed up update processes as well when "forced github downloads" is ticked.
- Tactical fonts fixed install instructions
- XM4, Winchester and korth custom d0cter unsellable
- Fixed weapon parts dots colors indicators by properly setting the new Utjan's Item UI improvements MCM values.
- Free Zoom ADS fixes
- Gavrilenko crash fix by Oleh and veerserif
- ISG Mechanic inventory now properly scales depending on the quest thanks to gbrlallison.

___________________________________

# **S.T.A.L.K.E.R. G.A.M.M.A. 0.9.1 Patch Notes**

**New Engine version thanks to Mr.Demonized and team**
- New Exe v2023.9.6

**New Addons**
- G.A.M.M.A. Traduccion Espanola - vdltman: https://www.moddb.com/mods/stalker-anomaly/addons/gamma-spanish-translation
- Extra Level Transitions Rostok Garbage Yantar Facing Fix - Qball: <https://www.moddb.com/mods/stalker-anomaly/addons/extra-level-transitions-rostok-to-garbage-and-yantar-facing-fix>
- Black Market (Buyable Gear) - SalamanderAnder & nox: <https://github.com/iam-n0x/Black_Market/archive/refs/heads/main.zip>
- XM4 Rifle - KeatonB_08: <https://www.moddb.com/mods/stalker-anomaly/addons/xm4-black-ops-cold-war>
- Soulslike Gamemode - Jabbers: <https://www.moddb.com/mods/stalker-anomaly/addons/jabbers-soulslike-gamemode>
- QoL Bundle - Utjan: <https://www.moddb.com/mods/stalker-anomaly/addons/utjans-qol-bundle>
- Item UI Improvements - Utjan: <https://www.moddb.com/mods/stalker-anomaly/addons/utjans-item-ui-improvements>
- Auto-Stacking Items - Zatura: <https://www.moddb.com/mods/stalker-anomaly/addons/zas-zaturas-auto-stacking-items>
- Defended Lab X10 - Shen: <https://www.moddb.com/mods/stalker-anomaly/addons/defended-lab-x-10>
- Fixed Artefacts Colision and Visuals - KronQ and Longreed: https://www.moddb.com/mods/stalker-anomaly/addons/fixed-artefact-collision-and-visuals-152
- QoL Patch to Tweak_Breeki's RF Receiver Hidden Packages - Cookbook: <https://www.moddb.com/mods/stalker-anomaly/addons/rf-receiver-tasks-qol-update>
- Barrier Defense Task Emission Fix - Catspaw: <https://www.moddb.com/mods/stalker-anomaly/addons/barrier-defense-task-emission-fix>
- Personal Adjustable Waypoint - Catspaw: <https://www.moddb.com/mods/stalker-anomaly/addons/personal-adjustable-waypoint-for-anomaly-151-152-and-gamma>
- Fair Fast Travel - Catspaw: <https://www.moddb.com/mods/stalker-anomaly/addons/fair-fast-travel-duration-for-anomaly-151>
- Higher Rank NPCs Headlight Disabled - KraizerX: <https://www.moddb.com/mods/stalker-anomaly/addons/higher-rank-npc-headlight-disabled>
- Semi Radiant AI - xcvb: <https://www.moddb.com/mods/stalker-anomaly/addons/semi-radiant-ai-01-dltx-required>
- Miserable Axe and Sledgehammer Retexture - Reconboi: <https://www.moddb.com/mods/stalker-anomaly/addons/miserable-axe-and-sledgehammer-retetxure-for-barrys-axes>
- Alternative Cats - KynesPeace: <https://www.moddb.com/mods/stalker-anomaly/addons/alternative-cats>
- Alternative Fleshes - KynesPeace: <https://www.moddb.com/mods/stalker-anomaly/addons/alternative-fleshes>
- Alternative Boars - KynesPeace: <https://www.moddb.com/mods/stalker-anomaly/addons/alternative-boars>
- Tactical Torch Reanimation - Skywhyz: <https://www.moddb.com/mods/stalker-anomaly/addons/tactorchreanim>
- 9a91 Reanimation - SeDzhiMol: <https://www.moddb.com/mods/stalker-anomaly/addons/9a91-and-vsk-94-reanimation>
- PP2000 Remodel & Reanimation - SeDzhiMol: <https://www.moddb.com/mods/stalker-anomaly/addons/pp2000-reanimation-rework>
- Vihr Reanimation - SeDzhiMol: <https://www.moddb.com/mods/stalker-anomaly/addons/sr-3m-vihr-reanimation>
- BAS Saiga Reanimation - Synd1cate: <https://www.moddb.com/mods/stalker-anomaly/addons/dltx-bas-saiga-reanimated>
- SPAS12 Reanimation & Remodel - Firebreath: <https://www.moddb.com/mods/stalker-anomaly/addons/spas12-reanimation>
- SVU Reanimation & Remodel - BarryBogs: <https://www.moddb.com/mods/stalker-anomaly/addons/svu-reanimation-remodel>
- Gunslinger Desert Eagle Model and Animations Port by Dizmok and Improved by Pieuvre: <https://www.moddb.com/mods/stalker-anomaly/addons/desert-eagle-gunslinger>
- G_FLAT's Gavrilenko Tasks Fix: <https://discord.com/channels/912320241713958912/1134322406199140483/1141124090254589982>
- G_FLAT's Indirect Parts Favoriter: <https://discord.com/channels/912320241713958912/1138977050556895364/1140490734999441559>
- Bert's Vector Reanimation to GAMMA Large Files: <https://discord.com/channels/912320241713958912/1122219515728625686/1122219515728625686>
- Slugler's No Old Ammo in the Ammo Wheel: <https://discord.com/channels/912320241713958912/1035947361920364624/1035947361920364624>
- Andtheherois's Ammo Wheel Retexture: <https://discord.com/channels/912320241713958912/1036082642644369438/1036082642644369438>
- SixSloth's & Veerserif's Hideout Furnitures 2.2.1 GAMMA patch: <https://discord.com/channels/912320241713958912/1142851348187066418/1142851348187066418>
- Cr3pis textures and icons fixes to GAMMA Large Files

- New set of MCM values for the newly added addons.


**Progression**
- Stashes changes and new toolkits spawn logic:
    - Changed map tiers and stash content code.
    - Green stashes are now the main source of tools.
    - White stashes have a very very small chance of spawning Gunsmith or Drug tools (1%). 
    - White stashes will almost always spawn extra ammo crafting materials.
    - Stashes spawn in same map or directly connected maps, but not in connected of connected maps like it used to do. 
    - Stash item tiers have been adjusted for all maps. Map specific items tiers are now separated for Toolkits spawns vs Regular items spawns.
    - North maps regular item tiers have been more evenly spread through the 5 different tiers to ensure stashes being filed and to increase the item diversity spawning in north stashes.
    - Artefacts Melter has a chance to spawn in Green Stashes.
    - Green stashes are guaranteed every 8 tasks rewarding stashes.
- Recipes: Exo repair kit recipe is now a drop only item and cannot be bought from Mechanics. Legends and Master stalkers can drop it.
- The North Progression is now locked behind deactivating the Miracle Machine: North Psi field bypasses actor psi res and kills you in 3 hits.
- Clear Sky questline rewards: machine yard quest rewards a gunsmith kit now.
- No more starting knife with bugged durability, but the actor starts with Tier 2 knife, which should make melee more rewarding early on (you still need to upgrade it to field dress strong mutants).
- Sid doesn't scam you for medications to compensate for the lack of medic in Cordon, but has a slimer selection and amount of meds. 
- Fast Travel changes thanks to Fair Fast Travel addon:
    - Backpacks fast travel does not allow overweight, 
    - You must use the new and more expensive Guide Fast Travel Feature (available on right click) to fast travel while being overweighted. 
    - Fast travel to debug spots is now disabled. 
    - Fast travel is not time limited anymore but is generally more expensive and scales better with distance (meaning close fast travel are cheap but long fast travel are much more expensive).
- Starting Loadouts changes:
    - Rebalanced available Pistols, with NATO factions having the best available pistols.
    - Made PP2000 available to Duty and Monolith as a starting SMG.
    - Made the sawn off shotguns available only in Tourist and Scavenger difficulty.
    - Increased TOZ106 cost.
    - Reduced APS and PM costs.


**Gameplay**
- North repopulation:
    - A lot of the North spawns were locked behind story progression. These preconditions has been removed so the maps should be much more busy.
    - A lot of empty smart terrains have been repopulated.
    - North areas should be much less empty as respawn timers has been reduced.
    - North areas are *much more* dangerous than before. Be aware that Sin and ISG are now common enemies in the North. The mutants are also much stronger. Expect potential packs of controllers.
    - North bases should be much more busy with more tasks to do.
    - Very rarely, Sin has Rocket Launcher

- Radar and Brain Scorcher rework:
    - The Radar map has a bit more Monolith stalkers.
    - The Brain Scorcher lab is now *guarded when entering the map*. This means you will have to fight Monolithans *during the timer*.
    - Brain Scorcher guards tier has been reduced (easier enemies).
    - Brain Scorcher timer has been increased.

- South maps mutants populations rework:
    - Hopefully Meadows should spawn more diverse mutants more often.
    - Wild Territory mutants has been made more "urban": more snorks, less pigs.
    - Truck Cemetary should now be the "juicy south map": extremely dangerous but highly lucrative.
    - Rostok should spawn much less mutants.

- Psi System Rework:
    - New feedback upon receiving psi damages: the vision gets blurred and you hear your heartbeat during 0.40 seconds (very fast).
    - Psi damages and defense handler remade to be inline with the other fixed elemental defenses: much more consistent and more balanced.
    - Negative Psi resistances of artefacts do not nuke your psi defense anymore: it's additive like any other fixed elemental resistance.
    - Psi damages scale with difficulty and are overall a bit less strong.
    - There's no magical "psi res immunity threshold": you'll always take psi damages (max res is capped at 99% damage reduction).
    - Boosted psi res of drugs to match the new system (+20% psi res for the psy block).
    - Psi res consummables restore psi health much faster than before. Basically psi attacks will be harder to mitigate than before but psi consumables will help you much more. This should reduce the strict dependency of artefacts for psi related stuff. However there's a likeliness that some stuff simply one shots you if you don't have any psi res (unprotected controllers tube attack).
    - Fixed artefact and consummabels psi res display.
    - Artefacts do not regen psy health over time anymore (or very very little).
    - Faster phantoms.
    - Psi damages don't affect limb health.

- Mutants rebalance:
    - Some mutants can spawn in packs: chimera, bloodsucker, giants, fractures...
    - Karlik will always spawn in packs.
    - Jumper Giants are enabled should thus spawn north.
    - Removed the Big Bloodsuckers (with red spikes) because of the terrible model.
    - A bit less meat spawns on mutants.
    - More toxic uncooked and low tier cooked meats. This should promote the cooking of higher tier mutant meats.

- Artefacts spawning logic remade: 
    - Artefacts now tend to spawn faster in the map the actor is currently is, but the spawn chance is much more random. This means the artefacts spawning is still about the same as before but it's much less predictable and when entering a map the player should feel much less that all the anomalous fields are empty.

- Tasks rebalance
    - Lots of Dynamic tasks changes.
    - North factions rewards (Freedom...) are higher than south factions rewards (Duty, Loners...).
    - Rewards increased for fetch tasks requiring items with a condition by removing the cubed condition scaling, i.e. for a 70% condition item, the rewarded price is 0.70*price instead of the previous 0.70*0.70*0.70*price (one more Misery left over nuked, yaaaaay). This should affect artefacts fetch tasks *a lot*.
    - Artefacts fetch tasks reward multiplier increased.
    - Bounty Hunting tasks only target enemies in the same map or in connected maps only (no more Cordon rookie asking to kill a Monolith squad in Outskirts).
    - Increased medical items fetch task diversity.
    - Weapons Fetch tasks fixed > this should be bugless now and the asked guns should work.
    - Increased Rostok tasks delay > quests should be a bitless repeatable there.
    - Reduced Rostok Missions money rewards > no more 6k RU for checkpoint guards killing dogs.
    - Lukash Barrier Defense task does not reward ammo anymore.
    - Taskboard doesn't pull tasks from companions.

- New Tasks
    - New dynamic task asking for Drug Kit or Ammo Kit for all factions
    - Replaced Wolf buggy rescue stalker task by a new task asking to clear all the mutants from Cordon.
    - New Sakharov Task: clean mutants in Agroprom Udg.
    - New Sakharov Task: clean mutants in X16 Lab. Ecologists also now have a chance to spawn in x16 after the lab is done to make the map more lively.
    - Replaced Skinflint task for Bear Detectors for a new one asking for gear to infiltrate Duty. This is locked behind 1000 Goodwill with Freedom.
    - New dynamic task available for all Freedom to bring some drugs.
    - New Fanatic Task to clear mutant nest in Meadow.

- More dynamic faction relation to reduce the hobo murder player behavior (think before shooting):
    - Killing allies reduces reputation by 300 and the goodwill with the neutral victim faction by 140.
    - Killing enemies reduce enemies faction goodwill by 10.
    - Both these system take into account your "current" faction. Meaning you can still disguise as a Merc to kill Loners if you are a Loner to not suffer from the 140 goodwill penalty. However you'll still suffer from a -10 goodwill penalty.
    - Completing dynamic tasks for one faction decreases goodwill for enemy factions. Obvious tasks are affected only (killing others, giving guns, etc). 

- Improved AI responsiveness thanks to Dead Air devs and xcvb
    - NPCs are much more reactive when being shot at or shot around: they will try to seek a cover compared to where they think they got shot from.
    - NPCs should see the actor from farther away once alerted.
    - Monolith should see the actor from even farther away compared to other NPCs.
    - Once a NPC got it by a bullet shot from the actor, the whole squad associated to the victim should be alerted and try to seek the actor.

- Complete support of Perk Based Artefacts with the GAMMA damage systems thanks to etapomom / momopate!
    - Redesign and rebalance of some perk artefacts.
    - Artefacts description should actually match the math running behind.

- Teivaz's Exo Item Use Animations ported to Anomaly for medkits, injectors, defense boosters and glucose shots. This essentially makes exos able to use important healing items much faster.

- Once a body is looted by an NPC, it stays looted independently of the NPCs fate. 

- Wepl hit effects fixes and reduced aim punch.


**Gunplay**
- Increased base aim shake especially with scopes. Sniping should be a bit harder.

- Guns should be able to very very rarely jam/misfire at high condition.

- Ammo balances:
    - All ammo now have a bit more air resistance and should thus drop a bit more with the distance.
    - Subsonic rounds have been made significantly slower and drop more: flatness upgrades are thus important for 9x39 and 12.7x55.
    - Slugs are also slower and less efficient at range and should drop a bit more (23x75 and 12ga).
    - Sniper rounds damages have been reduced a little bit.
    - .45 ACP damage increased to 27 and AP increased to 20.
    - .45 Hydro is easier to crafte and a bit cheaper to buy.
    - 12ga buck and slugs are a bit more expensive.
    - 12ga buckshot is a bit harder to craft (everyone was buying them anyways).
    - 5.7 SS195 rounds AP increased to 22.
    - Increased .338 Lapua damages.

- New NPCs Armor System:
    - NPCs armor is now defined according to 3 body parts / groups of limns: head armor (head and neck), upper armor (body and arms) and lower armor (legs).
    - Each bullet decreases the armor value of one group based on the bullet Armor Penetration Power.
    - Once a body part armor is defeated, full damages are dealt to the NPCs.
    - Concussion damages (when ammo didn't penetrate the armor) have been slightly increased and made a bit more random.
    - Concussion damages for HP rounds have been reduced to match their FMJ counter part.
    - Concussion damages of Slugs and Buckshots have been reduced. Slugs still stagger in the head, thus making headshot spam still easy.
    - Slightly reduced damages to NPCs extremities.
    - Removed the melee hit redirection to torso: aim for the head! Axes dunk is thus much more powerful.
    - The head AP boost system is still in: hitting the eyes, the neck or the jaw boosts the ammo Penetration by +3.5 (flat, 21 AP becomes 24.5).
    - Reduced the Head and Eyes headshot bonus from 4 to 3.65
    - Reduced the Jaw damage bonus from 4 to 3.00
    - Reduced the Neck damage bonus from 4 to 2.70
    - The new headshot values ensure that certain calibers don't always one shot headshot at long ranges bu do at close ranges (9x18 vs .45 vs 9x19).
    - A dilemma is set between aiming for the neck to guarantee the AP boost at the cost of damage, or aim for the head and have both the AP boost and Damage or just the Damage boost if the top, back or lateral parts of the head are hit (where the helmet protection works).

- Guns balance:
    - Saigas mag size increase.
    - Reduced endgame 5.45 guns recoil.
    - Reduced AKM Alfa recoil significantly.
    - Reduced AKM ISG recoil a little bit.
    - Reduced AK104 Alfa recoil a little bit.
    - Replaced AK104 by AK103 (grenade launcher compatible).
    - Firebreath Spas12 Salvo suppressor instead of NATO.
    - PP2000 - mags have 45 rounds.
    - PP2000 - 600rpm as IRL.
    - PP2000 - now has high accuracy.
    - Vihr reduced recoil, it's now a very strong 9x39 gun.
    - HOWA20 and RU556 normal 5.56 damages.
    - Coonan increased recoil and added a silencer model. Coonan also uses .357 caliber barrel part.


**Balance**
- Easier bandits, tankier Sin, ISG and Monolith.
- Slightly increased end game NPCs head armor to actor levels.
- ISG teleporting should now avoid the bullet (bullet dodge system).
- Reduced exo outfit and exo helmet drop chance to match new north population.
- Some Scopes were moved at higher Trader Supply Level.
- Removed SVT from stashes.
- Removed SVT from NPCs loadouts.
- Reduced Bullet res cap, increased strike res cap.
- Reduced exo armors AP res.
- Bit more common saiga isg , bit more rare raptr.
- More rare Desert Eagle.
- Increased toz 106 20ga conversion price.
- Reduced dynamic fields artefacts spawn.
- Reduced chance of dynamic artefacts spawn.
- Slightly Increased ammo parts salvaging coefficient (80% to 90%).
- Phantom Star duration divided by 4.
- Vihr and SVU increased spawn chance on NPCs.
- SVU repair type to advanced.
- bit rarer SVD.
- More common basic P90.
- Bit more rare RPK16.
- More rare Nosorog and Spartan Helm armor spawn chance.
- Rebalanced Exo PSUs: No regen, but lower consumptions and higher storage capacities.
- Multiplied artefacts explosition resistance by 1.5.
- Heavy armors artefacts slots increased (Skat9, Exosuits) to make them more interesting to use.
- Reduced Drug kit and ammo kit prices.


**Visuals**
- Updated Reshade to 5.9.2 with addon support: Reshade effects don't mess with the UI anymore thanks to Demonized EXE.
- Sun quality to medium and shadows scanlines fixes: no more parallel evenly spaced bugged shadow lines on surfaces.
- New SSS and atmospherics versions.
- Actor shadow on by default.
- Beef NVGs MCM values have been tweaked to allow the NVGs various levels of illumination to be more useful (no need to use NVG + Flashlight anymore). This also makes the red dots, collimators and tritium sights useable with ease while using NVGs.
- Default Aydin's Flora set to Autumn.


**Audio**
- New day/night cycle map-specific soundtracks by SanctusSynth for many new maps, almost all maps are covered now!
- New Sound Tracks by Apocryphos.


**Quality of Life**
- Workshop UI Tooltips do not get in the way of the crafting UI anymore: no more annoying reloads during your crafting sessions!
- Free Zoom properly resets when dying.
- Sound volume proper reset after dying with volume effects down (hopefully).
- All Vices are now free by default and use the tools given to the associated mechanic.
- Removal of Vice dialog since they are now free.
- Hideout Furniture 2.2.1 thanks to Veerserif and Hatexsi and Aoldri.
- Improved placeable campfires: Fixed placeable firecamps not staying lit upon reloading a save. Also the fire start animation is much better. Campfires don't enflame the actor anymore. Campfire placeable are cheaper and lighter.
- Minimap showed by default.
- Cr3pis fixes to icons and textures.
- Removed useless ammo parts from various sources.
- Removed the drop of bad upgrade packs from various sources.
- Bandana, Cloth mask, bala and resp are repaired by field repair kit.
- Tourist jacket can equip a backpack.
- Updated Aoldri anim core scripts with old WPO unjam checks.
- Halved length of Headshot Post Process Effect.
- Item Animations Enabling button unbound by default.
- Proper flashlight light position by hibaruza DLTXed: no more "illuminated hand".
- Fixed the font colors errors for the Spanish translation so disabling Tactical Fonts is not needed anymore.
- WPO "bad guns parts" will always be bad, and not 59% anymore.
- Restored proper armor exchange dialogue in English.
- Small compatibility fix for people disabling BHS so the game doesn't crash when being shot at.



**Bugfixes**
- Spreaded timed scripts execution over time to avoid stutters.
- BHS limbs damages aren't random anymore.
- BHS health gating: you can't be one shotted because your head or torso went from 11 to 0 in one shot.
- Parts fix for P90 GS.
- Full Empty charges Melter properly.
- Fixed K98 condition decrease that was too high.
- Zombies don't claim loot.
- Fixed blood sucker food rad res typo.
- MP5SD Acog potential fix.
- Sell items to dead traders bug abuse fix.
- Fixed artefacts random double spawns.
- Fixed double toolkits spawn in green stashes.
- Fixed R thigh L thigh damage multiplier to NPCs.
- Fix treasure manager crash fix.
- 7.62x25 p rounds damage boost fix to mutants.
- potential bug fix for sim_board.script:140 crash.
- tan5050 fix for displayed max carry weight with artefacts.
- Inventory slow scroll fix after alt tabbing (hopefully).
- Fair Fast Travel compatibility fix.
- Starter loadouts special ammo fix by MotaRin.
- Removed Knife fixed FOV.
- Fixed mags HUD position.
- Added an edge case to avoid CSky exos being deleted in the south, which could affect the Clear the Pump Station Task.
- Fixed helmet armor for stalker_soldier_hired_lc_17 and 20.
- PP2000 hud fov fix and specter dynamic zoom fix.
- Chimera hunter sight position fix on icon.
- M4s inspect animations camera fixes.
- Saiga 12s idle camera anim bugfix for area transitions.
- SVU sound fix for NPC shooting.
- removed Tomahawk from shops.
- NïS fix for workshop UI.
- Fixed Eidolon particles display.
- Fixed SVU "infinite reload" when mashing R key.
- Removed the Melter Details option to avoid the crash.
- Doom Gun Inspection sound fix and busy hands chance reduced.