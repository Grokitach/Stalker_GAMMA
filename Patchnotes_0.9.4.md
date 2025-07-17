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
- LeftCtrl full armor stat radiation display fix
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

