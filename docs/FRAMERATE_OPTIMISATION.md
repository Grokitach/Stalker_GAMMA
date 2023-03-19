First things first,  be sure to disable the reshade effects in game. Press the Home key on your keyboard and untick everything.

1. Turn off core 0 for Anomaly (see [FAQ.md#how-to-disable-core-0](./FAQ.md#how-to-disable-core-0)). For a "one timer", CTRL+Shift+ESC while in game. Right click Anomaly process > Details > Set Affinity > Untick core 0. Also, click Priority > High. You can also  check this guide: https://www.makeuseof.com/how-to-manually-allocate-cpu-cores-windows-10/ . Try playing this way already.

2. Make sure the game runs on your dedicated GPU, not on the CPU integrated one.

   If you need a better framerate:

3. Disable the following addons:
  - Screen Space Shaders - Ascii1457
  - Shaders Cumulative Pack for GAMMA
  - Jaku's Improved Shaders
  - R3zy's Detectors Enhanced Shaders Pack
  \
  Right click Beef's NVG addon, click "reinstall mod" and tick the following options:
  - Beef's NVG
  - Beef’s NVG - Patch ES
  \
  Delete Anomaly/appdata/shaders_cache folder
4. Be sure to copy paste the GAMMA RC3/.Grok's Modpack Installer/modpack_patches/appdata/user.ltx to the Anomaly/appdata folder. Delete Anomaly/appdata/shader_cache folder.

5. In the Anomaly/bin folder, right click DX11-AVX.exe > Properties > Disable Fullscreen optimization.

6. disable ANY overlay (steam, nvidia etc).

7. Boot the game, load your save.

8. in the game options menu use Fullscreen and disable Vsync in the game options with a resolution fitting your screen. You can also set the maximum Framerate to 60.

9. remove anti aliasing, and put all the grass sliders to the minimum. Turn down dynamic and static objects render to around 60-70%. Disable masks effects (reflections etc) in the player option in the Anomaly options menu.

10. Try playing with AVX, or without AVX, in DX10 or in DX11 and see what gives you the best framerate.

For even more performance saving:

- DON'T PLAY IN WARFARE

- Use the classic textures in [CUSTOM_TEXTURES.md#classic-textures](./CUSTOM_TEXTURES.md#classic-textures)

- Use the no grass add-on in [CUSTOM_TEXTURES.md#no-graass-or-lods](./CUSTOM_TEXTURES.md#no-grass-or-lods)

- Playing in DX8 can help, but try this as a last resort. Although some lightnings will be fucked up and the game can be rather dark. If you play DX8, disable Beef's NVG addon and clear Anomaly/appdata/shaders_cache folder. DX10 can also help.
