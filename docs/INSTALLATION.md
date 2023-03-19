EN | [RU](./INSTALLATION.ru.md)

# Installation

## Windows

### Prerequisites 

1. 70 GB free.
2. You'll need to use 7Zip, not WINRAR. 7Zip: https://www.7-zip.org/download.html
3. Anomaly 1.5.1, don't use an already installed and modded Anomaly: https://www.moddb.com/mods/stalker-anomaly/downloads/stalker-anomaly-151

   Please prefer pasting this magnet link in your favorite torrent downloader instead of ModDB direct download for faster speed:
   ```
   magnet:?xt=urn:btih:c307c208636d1fd98ca4fe70ca0c692035659855&dn=Anomaly-1.5.1.7z&tr=udp://tracker.opentrackr.org:1337/announce&tr=udp://bt1.archive.org:6969/announce&tr=udp://bt2.archive.org:6969/announce&tr=udp://tracker.torrent.eu.org:451/announce
   ```
4. Update 1.5.2 for Anomaly: https://www.moddb.com/mods/stalker-anomaly/downloads/stalker-anomaly-151-to-152
   
   Please prefer pasting this magnet link in your favorite torrent downloader instead of ModDB direct download for faster speed:
   ```
   magnet:?xt=urn:btih:06580e9c871086d5b847a84940bd89b6d97c975f&dn=Anomaly-1.5.1-to-1.5.2-Update.7z&tr=udp://tracker.opentrackr.org:1337/announce&tr=udp://bt1.archive.org:6969/announce&tr=udp://bt2.archive.org:6969/announce&tr=udp://tracker.torrent.eu.org:451/announce
   ```
   
5. G.A.M.M.A. client GAMMA RC3.7z:
   - Mirror 1: https://file141.gofile.io/download/796281d3-801b-4035-b57f-6fe163f9b7ec/GAMMA%20RC3.7z
   - Mirror 2: https://file141.gofile.io/download/8fc0e50c-77de-47d6-8612-e62e4e00713a/GAMMA%20RC3.7z
   - Mirror 3: https://file141.gofile.io/download/85787791-0aa6-4b46-8311-fe5112c195ef/GAMMA%20RC3.7z
   - Mirror 4: https://mega.nz/file/TY1jzJbK#wV7ANyQFAUOXKGbGZXEuVhMyUjaX0NzRdcXueGyR2B8

   Also get the addons archive downloads.7z from here: https://gofile.io/d/mpDnsO
6. It's highly recommended to disable your antivirus or, otherwise, to add exceptions for Anomaly and GAMMA folders before starting. BitDefender will 100% crash the game randomly because it doesn't like MO2 Virtual File System.
7. Make 2 different folders at the root of your drives (C:/, D:/): one will contain GAMMA, and the other will contain Anomaly. Don't make these folders in Downloads, Program Files, Documents, Desktop. For instance use: C:/GAMMA and C:/Anomaly. Do not use special characters in any of the folders ([-, etc)

In case of mirrors being at max capacity, you can grab new mirrors here: https://gofile.io/d/WlndL7

### Installation

1. Extract S.T.A.L.K.E.R. Anomaly 1.5.1 using 7Zip (not winrar) in a new folder ( C:\Anomaly).
2. - Move the 1.5.2 Anomaly Patch zip to the Anomaly folder C:\Anomaly (next to bin, gamedata...), right click the archive, extract here using 7zip, accept files replacement.
   - You should see changes151to152.txt next to the bin folder in your Anomaly folder if the patching is successful.
3. Launch Anomaly 1.5.2 once and reach the main in-game menu. Exit the game.
4. Extract GAMMA RC3.7z using 7Zip to a new folder. 
5. - Go to the C:\GAMMA RC3\ folder and extract downloads.7z in it. This should create a C:\GAMMA RC3\ downloads folder containing many addons zip.

   - Go to the C:\GAMMA RC3\.Grok's Modpack Installer folder.
6. Be sure to right click and "Launch as Admin" G.A.M.M.A. Installer.exe and click “Allow Powershell scripts”.
7. Click “Launch MO2”. Ignore the error message. Click Browse and show the C:\Anomaly folder. Exit MO2.
8. Click “Download G.A.M.M.A. data” and wait until it is done.
9. Click "Full G.A.M.M.A. Installation”. 
   - You can launch a new desktop by pressing Windows Key + Tab, then click New Desktop at the top and move the installer window and the black window there. You'll thus be able to use your computer normally during the long installation. 
   - If you need to close the installer during the process, it will resume where it was left next time you launch it.
10. When the process is finished, close the installer, go to your Desktop and double click the G.A.M.M.A. shortcut. An error message should appear, click OK, you should have 358 mods in mo2. If not, you'll crash on game start.

    Can’t find the icon? Simply create a shortcut of C:\GAMMA RC3\modorganizer.exe, then paste it on your desktop.
11. STALKER GAMMA is now ready to run. Select Anomaly (DX11) in MO2 and click Run. DX9 doesn't work. AVX generally has worst performances unless you have a 12900k or 5950x CPU.
    
    If you crash on startup be sure you have 358 mods in mo2. Make sure you updated the game to 1.5.2 properly (1.5.1to1.5.2changes.txt in Anomaly folder). Launch the installer and click Download GAMMA data (big middle button) and then Full GAMMA installation. Doing it more than 2 times within 1 hour will get you flagged as a bot by moddb.

## Linux

See https://github.com/DravenusRex/stalker-gamma-linux-guide

## Steam Deck

See https://github.com/maxastyler/S.T.A.L.K.E.R.-Gamma-Steam-Deck-Install-Guide/blob/master/README.org

# How to update 

## Fast way

1. Launch installer in Admin mode.
2. Download GAMMA data
3. Only install GAMMA addons

## Complete way

That checks moddb add-ons and install their latest version + gamma updates.

Also use If you have issues/bugs with the pack (guns not showing, crashes at startup, etc):

1. Launch the Installer
2. Download GAMMA data
3. Full GAMMA installation

This will reset your keybinds and graphics parameters if you didn’t set a custom profile and addons (See [FAQ.md#backup](./FAQ.md#backup))

Doing so will scan moddb and updates all the addons of the pack to the latest version. Using this method multiple times a day will flag you as a bot by moddb for more than 1 hour and will break your install. 

# Useful tips

- NEVER remove the GAMMA RC3/downloads folder
- When starting a new game, don't use Campfire Saves since the YACS add-on is doing it for you but better (configurable in the MCM menu).
- Warfare is unstable.
- NEVER TOUCH "sleep deprivation" OR "water deprivation" IN THE GAME OPTIONS 
- if you have stutters, disable core 0 for Anomaly.exe. check the guide in [FRAMERATE_OPTIMISATION.md](./FRAMERATE_OPTIMISATION.md)
- If you have a bad framerate [FRAMERATE_OPTIMISATION.md](./FRAMERATE_OPTIMISATION.md)
- If you want to avoid some UI elements to glow because of the reshade (really minor glowing) you can resize the following image to your screen resolution (base res is at 2k) : in your Anomaly folder: bin/reshade-shaders/Textures/UIMask.png
- Check [KEYBINDS.md](./KEYBINDS.md)
- Read the [MANUAL.md](./MANUAL.md) (although most of the manual is now available in loading screens).
- Read [How to update](#how-to-update) to know how to keep STALKER GAMMA up-to-date

# Extra Links

Install instructions available in Czech: https://youtu.be/xEwR110I6nE
